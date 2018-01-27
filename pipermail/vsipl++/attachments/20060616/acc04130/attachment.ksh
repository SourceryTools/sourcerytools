Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.507
diff -u -r1.507 ChangeLog
--- ChangeLog	16 Jun 2006 02:36:58 -0000	1.507
+++ ChangeLog	16 Jun 2006 12:17:39 -0000
@@ -1,5 +1,28 @@
 2006-06-15  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/impl/block-traits.hpp (Is_leaf_block): New trait
+	  to determine if block is a leaf in an expression
+	* src/vsip/impl/eval_dense_expr.hpp (Redim_block::impl_stride):
+	  Fix bug when original block is 3-dimensional.
+	* src/vsip/impl/ipp.cpp: Add wrappers for IPP abs, square, square-root,
+	  and exponent.
+	* src/vsip/impl/ipp.hpp: Add dispatch for square and square-root.
+	  Explicitly request 1-dim Ext_data access to handle multi-dim
+	  expressions from eval_dense_expr.
+	* src/vsip/impl/metaprogramming.hpp (Type_if): New struct,
+	  forwards type only if bool parameter is true.  Used for SFINAE.
+	* src/vsip/impl/sal/elementwise.hpp: Prefix coverage labels with
+	  "SAL_".
+	* src/vsip/impl/sal/eval_elementwise.hpp: Use Type_if and
+	  Is_leaf_block to enable evaluators.  This disambiguates the
+	  (VV)V and V(VV) evaluators for expressions like (VV)(VV).
+	  Explicitly request 1-dim Ext_data access to handle multi-dim
+	  expressions from eval_dense_expr.
+	* src/vsip/impl/sal/eval_util.hpp (Ext_wrapper): Add layout
+	  policy template parameter.
+	
+2006-06-15  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/impl/sal/elementwise.hpp: Fix bug with synthetic
 	  complex scalar-vector multiply.
 	* tests/coverage_binary.cpp: Extend coverage to catch bug.
Index: src/vsip/impl/block-traits.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/block-traits.hpp,v
retrieving revision 1.20
diff -u -r1.20 block-traits.hpp
--- src/vsip/impl/block-traits.hpp	2 Jun 2006 02:21:50 -0000	1.20
+++ src/vsip/impl/block-traits.hpp	16 Jun 2006 12:17:39 -0000
@@ -210,7 +210,7 @@
 
 
 
-/// Traits class to determine if block is an expression block.
+/// Traits class to determine if block is a scalar block.
 
 template <typename Block>
 struct Is_scalar_block
@@ -234,6 +234,19 @@
 
 
 
+/// Traits class to determine if a block is a leaf block in an
+/// expressions.
+
+template <typename BlockT>
+struct Is_leaf_block
+{
+  static bool const value =
+    !Is_expr_block<BlockT>::value ||
+     Is_scalar_block<BlockT>::value;
+};
+
+
+
 /// Check if lhs map is same as rhs block's map.
 
 /// Two blocks are the same if they distribute a view into subblocks
Index: src/vsip/impl/eval_dense_expr.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/eval_dense_expr.hpp,v
retrieving revision 1.1
diff -u -r1.1 eval_dense_expr.hpp
--- src/vsip/impl/eval_dense_expr.hpp	8 Jun 2006 18:50:51 -0000	1.1
+++ src/vsip/impl/eval_dense_expr.hpp	16 Jun 2006 12:17:39 -0000
@@ -153,6 +153,7 @@
 template <typename       BlockT,
 	  dimension_type OrigDim>
 class Redim_block
+  : Compile_time_assert<OrigDim == 2 || OrigDim == 3>
 {
   // Compile-time values and typedefs.
 public:
@@ -228,7 +229,8 @@
     // when it makes sense of course.
 
     assert(total_dim == 1 && d == 0);
-    return blk_->impl_stride(BlockT::dim, raw_order_type::impl_dim1);
+    return OrigDim == 2 ? blk_->impl_stride(2, raw_order_type::impl_dim1)
+                        : blk_->impl_stride(3, raw_order_type::impl_dim2);
   }
 
 
Index: src/vsip/impl/ipp.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp.cpp,v
retrieving revision 1.10
diff -u -r1.10 ipp.cpp
--- src/vsip/impl/ipp.cpp	18 Jan 2006 12:51:10 -0000	1.10
+++ src/vsip/impl/ipp.cpp	16 Jun 2006 12:17:39 -0000
@@ -27,116 +27,98 @@
 namespace ipp
 {
 
-// Addition
-
-void vadd(float const* A, float const* B, float* Z, length_type len)
-{
-  IppStatus status = ippsAdd_32f(A, B, Z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
 
-void vadd(double const* A, double const* B, double* Z, length_type len)
-{
-  IppStatus status = ippsAdd_64f(A, B, Z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
+#define VSIP_IMPL_IPP_V(FCN, T, IPPFCN, IPPT)				\
+void									\
+FCN(									\
+  T const* A,								\
+  T*       Z,								\
+  length_type len)							\
+{									\
+  VSIP_IMPL_COVER_FCN("IPP_V", IPPFCN)					\
+  IppStatus status = IPPFCN(						\
+    reinterpret_cast<IPPT const*>(A),					\
+    reinterpret_cast<IPPT*>(Z),						\
+    static_cast<int>(len));						\
+  assert(status == ippStsNoErr);					\
+}
+
+#define VSIP_IMPL_IPP_VV(FCN, T, IPPFCN, IPPT)				\
+void									\
+FCN(									\
+  T const* A,								\
+  T const* B,								\
+  T*       Z,								\
+  length_type len)							\
+{									\
+  IppStatus status = IPPFCN(						\
+    reinterpret_cast<IPPT const*>(A),					\
+    reinterpret_cast<IPPT const*>(B),					\
+    reinterpret_cast<IPPT*>(Z),						\
+    static_cast<int>(len));						\
+  assert(status == ippStsNoErr);					\
+}
+
+#define VSIP_IMPL_IPP_VV_R(FCN, T, IPPFCN, IPPT)			\
+void									\
+FCN(									\
+  T const* A,								\
+  T const* B,								\
+  T*       Z,								\
+  length_type len)							\
+{									\
+  IppStatus status = IPPFCN(						\
+    reinterpret_cast<IPPT const*>(B),					\
+    reinterpret_cast<IPPT const*>(A),					\
+    reinterpret_cast<IPPT*>(Z),						\
+    static_cast<int>(len));						\
+  assert(status == ippStsNoErr);					\
+}
+
+// Abs
+// VSIP_IMPL_IPP_V(vabs, int16,           ippsAbs_16s,  Ipp16s)
+// VSIP_IMPL_IPP_V(vabs, int32,           ippsAbs_32s,  Ipp32s)
+VSIP_IMPL_IPP_V(vabs, float,           ippsAbs_32f,  Ipp32f)
+VSIP_IMPL_IPP_V(vabs, double,          ippsAbs_64f,  Ipp64f)
+
+// Square
+VSIP_IMPL_IPP_V(vsq,  float,           ippsSqr_32f,  Ipp32f)
+VSIP_IMPL_IPP_V(vsq,  double,          ippsSqr_64f,  Ipp64f)
+VSIP_IMPL_IPP_V(vsq,  complex<float>,  ippsSqr_32fc, Ipp32fc)
+VSIP_IMPL_IPP_V(vsq,  complex<double>, ippsSqr_64fc, Ipp64fc)
+
+// Square-root
+VSIP_IMPL_IPP_V(vsqrt, float,           ippsSqrt_32f,  Ipp32f)
+VSIP_IMPL_IPP_V(vsqrt, double,          ippsSqrt_64f,  Ipp64f)
+VSIP_IMPL_IPP_V(vsqrt, complex<float>,  ippsSqrt_32fc, Ipp32fc)
+VSIP_IMPL_IPP_V(vsqrt, complex<double>, ippsSqrt_64fc, Ipp64fc)
+
+// Exponent
+VSIP_IMPL_IPP_V(vexp, float,           ippsExp_32f,  Ipp32f)
+VSIP_IMPL_IPP_V(vexp, double,          ippsExp_64f,  Ipp64f)
 
-void vadd(std::complex<float> const* A, std::complex<float> const* B,
-          std::complex<float>* Z, length_type len)
-{
-  Ipp32fc const *a = reinterpret_cast<Ipp32fc const *>(A);
-  Ipp32fc const *b = reinterpret_cast<Ipp32fc const *>(B);
-  Ipp32fc *z = reinterpret_cast<Ipp32fc *>(Z);
-  IppStatus status = ippsAdd_32fc(a, b, z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
+// Addition
+VSIP_IMPL_IPP_VV(vadd, float,           ippsAdd_32f,  Ipp32f)
+VSIP_IMPL_IPP_VV(vadd, double,          ippsAdd_64f,  Ipp64f)
+VSIP_IMPL_IPP_VV(vadd, complex<float>,  ippsAdd_32fc, Ipp32fc)
+VSIP_IMPL_IPP_VV(vadd, complex<double>, ippsAdd_64fc, Ipp64fc)
 
-void vadd(std::complex<double> const* A, std::complex<double> const* B,
-          std::complex<double>* Z, length_type len)
-{
-  Ipp64fc const *a = reinterpret_cast<Ipp64fc const *>(A);
-  Ipp64fc const *b = reinterpret_cast<Ipp64fc const *>(B);
-  Ipp64fc *z = reinterpret_cast<Ipp64fc *>(Z);
-  IppStatus status = ippsAdd_64fc(a, b, z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
 
 // Subtraction
-
 // Note: IPP subtract arguments are in reverse order:
-//
-//   ippsSub(X, Y, Z, ...);
-//
-// Computes: Z = Y - X.  (X is subtracted from Y).
-//
-// We swap arguments to IPP so that "A - B" corresponds to vsub(A, B).
-
-
-void vsub(float const* A, float const* B, float* Z, length_type len)
-{
-  IppStatus status = ippsSub_32f(B, A, Z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
 
-void vsub(double const* A, double const* B, double* Z, length_type len)
-{
-  IppStatus status = ippsSub_64f(B, A, Z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
-
-void vsub(std::complex<float> const* A, std::complex<float> const* B,
-          std::complex<float>* Z, length_type len)
-{
-  Ipp32fc const *a = reinterpret_cast<Ipp32fc const *>(A);
-  Ipp32fc const *b = reinterpret_cast<Ipp32fc const *>(B);
-  Ipp32fc *z = reinterpret_cast<Ipp32fc *>(Z);
-  IppStatus status = ippsSub_32fc(b, a, z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
+VSIP_IMPL_IPP_VV_R(vsub, float,           ippsSub_32f,  Ipp32f)
+VSIP_IMPL_IPP_VV_R(vsub, double,          ippsSub_64f,  Ipp64f)
+VSIP_IMPL_IPP_VV_R(vsub, complex<float>,  ippsSub_32fc, Ipp32fc)
+VSIP_IMPL_IPP_VV_R(vsub, complex<double>, ippsSub_64fc, Ipp64fc)
 
-void vsub(std::complex<double> const* A, std::complex<double> const* B,
-          std::complex<double>* Z, length_type len)
-{
-  Ipp64fc const *a = reinterpret_cast<Ipp64fc const *>(A);
-  Ipp64fc const *b = reinterpret_cast<Ipp64fc const *>(B);
-  Ipp64fc *z = reinterpret_cast<Ipp64fc *>(Z);
-  IppStatus status = ippsSub_64fc(b, a, z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
 
 // Multiplication
 
-void vmul(float const* A, float const* B, float* Z, length_type len)
-{
-  IppStatus status = ippsMul_32f(A, B, Z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
-
-void vmul(double const* A, double const* B, double* Z, length_type len)
-{
-  IppStatus status = ippsMul_64f(A, B, Z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
-
-void vmul(std::complex<float> const* A, std::complex<float> const* B,
-          std::complex<float>* Z, length_type len)
-{
-  Ipp32fc const *a = reinterpret_cast<Ipp32fc const *>(A);
-  Ipp32fc const *b = reinterpret_cast<Ipp32fc const *>(B);
-  Ipp32fc *z = reinterpret_cast<Ipp32fc *>(Z);
-  IppStatus status = ippsMul_32fc(a, b, z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
-
-void vmul(std::complex<double> const* A, std::complex<double> const* B,
-          std::complex<double>* Z, length_type len)
-{
-  Ipp64fc const *a = reinterpret_cast<Ipp64fc const *>(A);
-  Ipp64fc const *b = reinterpret_cast<Ipp64fc const *>(B);
-  Ipp64fc *z = reinterpret_cast<Ipp64fc *>(Z);
-  IppStatus status = ippsMul_64fc(a, b, z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
+VSIP_IMPL_IPP_VV(vmul, float,           ippsMul_32f,  Ipp32f)
+VSIP_IMPL_IPP_VV(vmul, double,          ippsMul_64f,  Ipp64f)
+VSIP_IMPL_IPP_VV(vmul, complex<float>,  ippsMul_32fc, Ipp32fc)
+VSIP_IMPL_IPP_VV(vmul, complex<double>, ippsMul_64fc, Ipp64fc)
 
 // Division
 
@@ -148,37 +130,10 @@
 //
 // We swap arguments to IPP so that "A / B" corresponds to vdiv(A, B).
 
-void vdiv(float const* A, float const* B, float* Z, length_type len)
-{
-  IppStatus status = ippsDiv_32f(B, A, Z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
-
-void vdiv(double const* A, double const* B, double* Z, length_type len)
-{
-  IppStatus status = ippsDiv_64f(B, A, Z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
-
-void vdiv(std::complex<float> const* A, std::complex<float> const* B,
-          std::complex<float>* Z, length_type len)
-{
-  Ipp32fc const *a = reinterpret_cast<Ipp32fc const *>(A);
-  Ipp32fc const *b = reinterpret_cast<Ipp32fc const *>(B);
-  Ipp32fc *z = reinterpret_cast<Ipp32fc *>(Z);
-  IppStatus status = ippsDiv_32fc(b, a, z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
-
-void vdiv(std::complex<double> const* A, std::complex<double> const* B,
-          std::complex<double>* Z, length_type len)
-{
-  Ipp64fc const *a = reinterpret_cast<Ipp64fc const *>(A);
-  Ipp64fc const *b = reinterpret_cast<Ipp64fc const *>(B);
-  Ipp64fc *z = reinterpret_cast<Ipp64fc *>(Z);
-  IppStatus status = ippsDiv_64fc(b, a, z, static_cast<int>(len));
-  assert(status == ippStsNoErr);
-}
+VSIP_IMPL_IPP_VV_R(vdiv, float,           ippsDiv_32f,  Ipp32f)
+VSIP_IMPL_IPP_VV_R(vdiv, double,          ippsDiv_64f,  Ipp64f)
+VSIP_IMPL_IPP_VV_R(vdiv, complex<float>,  ippsDiv_32fc, Ipp32fc)
+VSIP_IMPL_IPP_VV_R(vdiv, complex<double>, ippsDiv_64fc, Ipp64fc)
 
 
 
Index: src/vsip/impl/ipp.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp.hpp,v
retrieving revision 1.7
diff -u -r1.7 ipp.hpp
--- src/vsip/impl/ipp.hpp	22 Dec 2005 01:29:25 -0000	1.7
+++ src/vsip/impl/ipp.hpp	16 Jun 2006 12:17:39 -0000
@@ -17,9 +17,12 @@
 #include <vsip/impl/block-traits.hpp>
 #include <vsip/impl/expr_serial_evaluator.hpp>
 #include <vsip/impl/expr_scalar_block.hpp>
+#include <vsip/impl/expr_unary_block.hpp>
 #include <vsip/impl/expr_binary_block.hpp>
 #include <vsip/impl/expr_operations.hpp>
+#include <vsip/impl/fns_elementwise.hpp>
 #include <vsip/impl/extdata.hpp>
+#include <vsip/impl/adjust-layout.hpp>
 
 /***********************************************************************
   Declarations
@@ -62,6 +65,25 @@
   static bool const value = true;
 };
 
+#define VSIP_IMPL_IPP_DECL_V(FCN, T, IPPFCN, IPPT)			\
+void									\
+FCN(									\
+  T const* A,								\
+  T*       Z,								\
+  length_type len)
+
+// Square
+VSIP_IMPL_IPP_DECL_V(vsq,  float,           ippsSqr_32f,  Ipp32f);
+VSIP_IMPL_IPP_DECL_V(vsq,  double,          ippsSqr_64f,  Ipp64f);
+VSIP_IMPL_IPP_DECL_V(vsq,  complex<float>,  ippsSqr_32fc, Ipp32fc);
+VSIP_IMPL_IPP_DECL_V(vsq,  complex<double>, ippsSqr_64fc, Ipp64fc);
+
+// Square-root
+VSIP_IMPL_IPP_DECL_V(vsqrt, float,           ippsSqrt_32f,  Ipp32f);
+VSIP_IMPL_IPP_DECL_V(vsqrt, double,          ippsSqrt_64f,  Ipp64f);
+VSIP_IMPL_IPP_DECL_V(vsqrt, complex<float>,  ippsSqrt_32fc, Ipp32fc);
+VSIP_IMPL_IPP_DECL_V(vsqrt, complex<double>, ippsSqrt_64fc, Ipp64fc);
+
 // functions for vector addition
 void vadd(float const* A, float const* B, float* Z, length_type len);
 void vadd(double const* A, double const* B, double* Z, length_type len);
@@ -195,6 +217,8 @@
   short*      out,
   length_type out_row_stride);
 
+
+
 template <template <typename, typename> class Operator,
 	  typename DstBlock,
 	  typename LBlock,
@@ -206,6 +230,18 @@
   typedef Binary_expr_block<1, Operator, LBlock, LType, RBlock, RType>
     SrcBlock;
 
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<DstBlock>::layout_type>::type
+    dst_lp;
+
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<LBlock>::layout_type>::type
+    lblock_lp;
+
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<RBlock>::layout_type>::type
+    rblock_lp;
+
   static bool const ct_valid = 
     !Is_expr_block<LBlock>::value &&
     !Is_expr_block<RBlock>::value &&
@@ -218,21 +254,18 @@
      Ext_data_cost<DstBlock>::value == 0 &&
      Ext_data_cost<LBlock>::value == 0 &&
      Ext_data_cost<RBlock>::value == 0 &&
-     // Complex split format is not (yet) supported.
-     Type_equal<typename Block_layout<DstBlock>::complex_type,
-		Cmplx_inter_fmt>::value &&
-     Type_equal<typename Block_layout<LBlock>::complex_type,
-		Cmplx_inter_fmt>::value &&
-     Type_equal<typename Block_layout<RBlock>::complex_type,
-		Cmplx_inter_fmt>::value;
+     /* IPP does not support complex split */
+     !Is_split_block<DstBlock>::value &&
+     !Is_split_block<LBlock>::value &&
+     !Is_split_block<RBlock>::value;
 
   
   static bool rt_valid(DstBlock& dst, SrcBlock const& src)
   {
     // check if all data is unit stride
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<LBlock> ext_l(src.left(), SYNC_IN);
-    Ext_data<RBlock> ext_r(src.right(), SYNC_IN);
+    Ext_data<DstBlock, dst_lp>    ext_dst(dst,       SYNC_OUT);
+    Ext_data<LBlock,   lblock_lp> ext_l(src.left(),  SYNC_IN);
+    Ext_data<RBlock,   rblock_lp> ext_r(src.right(), SYNC_IN);
     return (ext_dst.stride(0) == 1 &&
 	    ext_l.stride(0) == 1 &&
 	    ext_r.stride(0) == 1);
@@ -241,102 +274,126 @@
 } // namespace vsip::impl::ipp
 
 
-template <typename DstBlock,
-	  typename LBlock,
-	  typename RBlock,
-	  typename LType,
-	  typename RType>
-struct Serial_expr_evaluator<
-  1, DstBlock, 
-  const Binary_expr_block<1, op::Add, LBlock, LType, RBlock, RType>,
-  Intel_ipp_tag>
-  : ipp::Serial_expr_evaluator_base<op::Add, DstBlock,
-				    LBlock, RBlock, LType, RType>
-{
-  typedef Binary_expr_block<1, op::Add, LBlock, LType, RBlock, RType>
-    SrcBlock;
-  
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<LBlock> ext_l(src.left(), SYNC_IN);
-    Ext_data<RBlock> ext_r(src.right(), SYNC_IN);
-    ipp::vadd(ext_l.data(), ext_r.data(), ext_dst.data(), dst.size());
-  }
-};
 
-template <typename DstBlock,
-	  typename LBlock,
-	  typename RBlock,
-	  typename LType,
-	  typename RType>
-struct Serial_expr_evaluator<
-  1, DstBlock, 
-  const Binary_expr_block<1, op::Sub, LBlock, LType, RBlock, RType>,
-  Intel_ipp_tag>
-  : ipp::Serial_expr_evaluator_base<op::Sub, DstBlock,
-				    LBlock, RBlock, LType, RType>
-{
-  typedef Binary_expr_block<1, op::Sub, LBlock, LType, RBlock, RType>
-    SrcBlock;
-  
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<LBlock> ext_l(src.left(), SYNC_IN);
-    Ext_data<RBlock> ext_r(src.right(), SYNC_IN);
-    ipp::vsub(ext_l.data(), ext_r.data(), ext_dst.data(), dst.size());
-  }
-};
+/***********************************************************************
+  Unary expression evaluators
+***********************************************************************/
 
-template <typename DstBlock,
-	  typename LBlock,
-	  typename RBlock,
-	  typename LType,
-	  typename RType>
-struct Serial_expr_evaluator<
-  1, DstBlock, 
-  const Binary_expr_block<1, op::Mult, LBlock, LType, RBlock, RType>,
-  Intel_ipp_tag>
-  : ipp::Serial_expr_evaluator_base<op::Mult, DstBlock,
-				    LBlock, RBlock, LType, RType>
-{
-  typedef Binary_expr_block<1, op::Mult, LBlock, LType, RBlock, RType>
-    SrcBlock;
-  
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<LBlock> ext_l(src.left(), SYNC_IN);
-    Ext_data<RBlock> ext_r(src.right(), SYNC_IN);
-    ipp::vmul(ext_l.data(), ext_r.data(), ext_dst.data(), dst.size());
-  }
+#define VSIP_IMPL_IPP_V_EXPR(OP, FUN)					\
+template <typename DstBlock,						\
+	  typename Block,						\
+	  typename Type>						\
+struct Serial_expr_evaluator<						\
+    1, DstBlock, 							\
+    Unary_expr_block<1, OP, Block, Type> const,				\
+    Intel_ipp_tag>							\
+{									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block>::layout_type>::type		\
+    blk_lp;								\
+									\
+  typedef Unary_expr_block<1, OP, Block, Type>				\
+    SrcBlock;								\
+									\
+  static bool const ct_valid =						\
+    !Is_expr_block<Block>::value &&					\
+     ipp::Is_type_supported<typename DstBlock::value_type>::value &&	\
+     Type_equal<typename DstBlock::value_type, Type>::value &&		\
+     /* check that direct access is supported */			\
+     Ext_data_cost<DstBlock>::value == 0 &&				\
+     Ext_data_cost<Block>::value == 0 &&				\
+     /* IPP does not support complex split */				\
+     !Is_split_block<DstBlock>::value &&				\
+     !Is_split_block<Block>::value;					\
+  									\
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)		\
+  {									\
+    /* check if all data is unit stride */				\
+    Ext_data<DstBlock, dst_lp> ext_dst(dst,      SYNC_OUT);		\
+    Ext_data<Block,    blk_lp> ext_src(src.op(), SYNC_IN);		\
+    return (ext_dst.stride(0) == 1 &&					\
+	    ext_src.stride(0) == 1);					\
+  }									\
+  									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    Ext_data<DstBlock, dst_lp> ext_dst(dst,      SYNC_OUT);		\
+    Ext_data<Block,    blk_lp> ext_src(src.op(), SYNC_IN);		\
+									\
+    VSIP_IMPL_COVER_FCN("eval_IPP_V", FUN);				\
+    FUN(								\
+      ext_src.data(),							\
+      ext_dst.data(),							\
+      dst.size()							\
+    );									\
+  }									\
 };
 
-template <typename DstBlock,
-	  typename LBlock,
-	  typename RBlock,
-	  typename LType,
-	  typename RType>
-struct Serial_expr_evaluator<
-  1, DstBlock, 
-  const Binary_expr_block<1, op::Div, LBlock, LType, RBlock, RType>,
-  Intel_ipp_tag>
-  : ipp::Serial_expr_evaluator_base<op::Div, DstBlock,
-				    LBlock, RBlock, LType, RType>
-{
-  typedef Binary_expr_block<1, op::Div, LBlock, LType, RBlock, RType>
-    SrcBlock;
-  
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<LBlock> ext_l(src.left(), SYNC_IN);
-    Ext_data<RBlock> ext_r(src.right(), SYNC_IN);
-    ipp::vdiv(ext_l.data(), ext_r.data(), ext_dst.data(), dst.size());
-  }
+VSIP_IMPL_IPP_V_EXPR(sq_functor,   ipp::vsq)
+VSIP_IMPL_IPP_V_EXPR(sqrt_functor, ipp::vsqrt)
+
+
+
+/***********************************************************************
+  Binary expression evaluators
+***********************************************************************/
+
+#define VSIP_IMPL_IPP_VV_EXPR(OP, FUN)					\
+template <typename DstBlock,						\
+	  typename LBlock,						\
+	  typename RBlock,						\
+	  typename LType,						\
+	  typename RType>						\
+struct Serial_expr_evaluator<						\
+    1, DstBlock, 							\
+    Binary_expr_block<1, OP, LBlock, LType, RBlock, RType> const,	\
+    Intel_ipp_tag>							\
+  : ipp::Serial_expr_evaluator_base<OP, DstBlock,			\
+				    LBlock, RBlock, LType, RType>	\
+{									\
+  typedef Binary_expr_block<1, OP, LBlock, LType, RBlock, RType>	\
+    SrcBlock;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<LBlock>::layout_type>::type		\
+    lblock_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<RBlock>::layout_type>::type		\
+    rblock_lp;								\
+  									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,       SYNC_OUT);		\
+    Ext_data<LBlock, lblock_lp> ext_l(src.left(),  SYNC_IN);		\
+    Ext_data<RBlock, rblock_lp> ext_r(src.right(), SYNC_IN);		\
+									\
+    VSIP_IMPL_COVER_FCN("eval_IPP_VV", FUN);				\
+    FUN(								\
+      ext_l.data(),							\
+      ext_r.data(),							\
+      ext_dst.data(),							\
+      dst.size()							\
+    );									\
+  } 									\
 };
 
+
+VSIP_IMPL_IPP_VV_EXPR(op::Add,  ipp::vadd)
+VSIP_IMPL_IPP_VV_EXPR(op::Sub,  ipp::vsub)
+VSIP_IMPL_IPP_VV_EXPR(op::Mult, ipp::vmul)
+VSIP_IMPL_IPP_VV_EXPR(op::Div,  ipp::vdiv)
+
+
+
 /***********************************************************************
   Scalar-view element-wise operations
 ***********************************************************************/
@@ -357,6 +414,14 @@
 			    VBlock, VType>
 	SrcBlock;
 
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<DstBlock>::layout_type>::type
+    dst_lp;
+
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<VBlock>::layout_type>::type
+    vblock_lp;
+
   static bool const ct_valid = 
     !Is_expr_block<VBlock>::value &&
      ipp::Is_type_supported<typename DstBlock::value_type>::value &&
@@ -372,8 +437,8 @@
   static bool rt_valid(DstBlock& dst, SrcBlock const& src)
   {
     // check if all data is unit stride
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,       SYNC_OUT);
+    Ext_data<VBlock, vblock_lp> ext_r(src.right(), SYNC_IN);
     return (ext_dst.stride(0) == 1 &&
 	    ext_r.stride(0) == 1);
   }
@@ -395,6 +460,14 @@
 			    Scalar_block<1, SType>, SType>
 	SrcBlock;
 
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<DstBlock>::layout_type>::type
+    dst_lp;
+
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<VBlock>::layout_type>::type
+    vblock_lp;
+
   static bool const ct_valid = 
     !Is_expr_block<VBlock>::value &&
      ipp::Is_type_supported<typename DstBlock::value_type>::value &&
@@ -410,8 +483,8 @@
   static bool rt_valid(DstBlock& dst, SrcBlock const& src)
   {
     // check if all data is unit stride
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst, SYNC_OUT);
+    Ext_data<VBlock, vblock_lp> ext_l(src.left(), SYNC_IN);
     return (ext_dst.stride(0) == 1 &&
 	    ext_l.stride(0) == 1);
   }
@@ -421,228 +494,167 @@
 } // namespace vsip::impl::ipp
 
 
+#define VSIP_IMPL_IPP_SV_EXPR(OP, FCN)					\
+template <typename DstBlock,						\
+	  typename SType,						\
+	  typename VBlock,						\
+	  typename VType>						\
+struct Serial_expr_evaluator<						\
+         1, DstBlock, 							\
+         const Binary_expr_block<1, OP,					\
+                                 Scalar_block<1, SType>, SType,		\
+                                 VBlock, VType>,			\
+         Intel_ipp_tag>							\
+  : ipp::Scalar_view_evaluator_base<OP, DstBlock, SType,		\
+                                    VBlock, VType, true>		\
+{									\
+  typedef Binary_expr_block<1, OP,					\
+			    Scalar_block<1, SType>, SType,		\
+			    VBlock, VType>				\
+	SrcBlock;							\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<VBlock>::layout_type>::type		\
+    vblock_lp;								\
+									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,       SYNC_OUT);		\
+    Ext_data<VBlock, vblock_lp> ext_r(src.right(), SYNC_IN);		\
+    VSIP_IMPL_COVER_FCN("eval_IPP_SV", FCN);				\
+    FCN(src.left().value(), ext_r.data(), ext_dst.data(), dst.size());	\
+  }									\
+};
+
+#define VSIP_IMPL_IPP_SV_EXPR_FO(OP, FCN)				\
+template <typename DstBlock,						\
+	  typename VBlock>						\
+struct Serial_expr_evaluator<						\
+         1, DstBlock, 							\
+         const Binary_expr_block<1, OP,					\
+                                 Scalar_block<1, float>, float,		\
+                                 VBlock, float>,			\
+         Intel_ipp_tag>							\
+  : ipp::Scalar_view_evaluator_base<OP, DstBlock, float,		\
+                                    VBlock, float, true>		\
+{									\
+  typedef float SType;							\
+  typedef float VType;							\
+									\
+  typedef Binary_expr_block<1, OP,					\
+			    Scalar_block<1, SType>, SType,		\
+			    VBlock, VType>				\
+	SrcBlock;							\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<VBlock>::layout_type>::type		\
+    vblock_lp;								\
+									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,       SYNC_OUT);		\
+    Ext_data<VBlock, vblock_lp> ext_r(src.right(), SYNC_IN);		\
+    VSIP_IMPL_COVER_FCN("eval_IPP_SV_FO", FCN);				\
+    FCN(src.left().value(), ext_r.data(), ext_dst.data(), dst.size());	\
+  }									\
+};
+
+
+
+#define VSIP_IMPL_IPP_VS_EXPR(OP, FCN)					\
+template <typename DstBlock,						\
+	  typename SType,						\
+	  typename VBlock,						\
+	  typename VType>						\
+struct Serial_expr_evaluator<						\
+         1, DstBlock, 							\
+         const Binary_expr_block<1, OP,					\
+                                 VBlock, VType,				\
+                                 Scalar_block<1, SType>, SType>,	\
+         Intel_ipp_tag>							\
+  : ipp::Scalar_view_evaluator_base<OP, DstBlock, SType,		\
+                                    VBlock, VType, false>		\
+{									\
+  typedef Binary_expr_block<1, OP,					\
+			    VBlock, VType,				\
+			    Scalar_block<1, SType>, SType>		\
+	SrcBlock;							\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<VBlock>::layout_type>::type		\
+    vblock_lp;								\
+									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,       SYNC_OUT);		\
+    Ext_data<VBlock, vblock_lp> ext_l(src.left(), SYNC_IN);		\
+    VSIP_IMPL_COVER_FCN("eval_IPP_VS", FCN);				\
+    FCN(ext_l.data(), src.right().value(), ext_dst.data(), dst.size());	\
+  }									\
+};
+
+#define VSIP_IMPL_IPP_VS_AS_SV_EXPR(OP, FCN)				\
+template <typename DstBlock,						\
+	  typename SType,						\
+	  typename VBlock,						\
+	  typename VType>						\
+struct Serial_expr_evaluator<						\
+         1, DstBlock, 							\
+         const Binary_expr_block<1, OP,					\
+                                 VBlock, VType,				\
+                                 Scalar_block<1, SType>, SType>,	\
+         Intel_ipp_tag>							\
+  : ipp::Scalar_view_evaluator_base<OP, DstBlock, SType,		\
+                                    VBlock, VType, false>		\
+{									\
+  typedef Binary_expr_block<1, OP,					\
+			    VBlock, VType,				\
+			    Scalar_block<1, SType>, SType>		\
+	SrcBlock;							\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<VBlock>::layout_type>::type		\
+    vblock_lp;								\
+									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,       SYNC_OUT);		\
+    Ext_data<VBlock, vblock_lp> ext_l(src.left(), SYNC_IN);		\
+    VSIP_IMPL_COVER_FCN("eval_IPP_VS_AS_SV", FCN);			\
+    FCN(src.right().value(), ext_l.data(), ext_dst.data(), dst.size());	\
+  }									\
+};
+
+VSIP_IMPL_IPP_SV_EXPR      (op::Add,  ipp::svadd)
+VSIP_IMPL_IPP_VS_AS_SV_EXPR(op::Add,  ipp::svadd)
+VSIP_IMPL_IPP_SV_EXPR      (op::Sub,  ipp::svsub)
+VSIP_IMPL_IPP_VS_EXPR      (op::Sub,  ipp::svsub)
+VSIP_IMPL_IPP_SV_EXPR      (op::Mult, ipp::svmul)
+VSIP_IMPL_IPP_VS_AS_SV_EXPR(op::Mult, ipp::svmul)
+VSIP_IMPL_IPP_SV_EXPR_FO   (op::Div,  ipp::svdiv)
+VSIP_IMPL_IPP_VS_EXPR      (op::Div,  ipp::svdiv)
+
+#undef VSIP_IMPL_IPP_SV_EXPR
+#undef VSIP_IMPL_IPP_SV_EXPR_FO
+#undef VSIP_IMPL_IPP_VS_EXPR
+#undef VSIP_IMPL_IPP_VS_AS_SV_EXPR
 
-template <typename DstBlock,
-	  typename SType,
-	  typename VBlock,
-	  typename VType>
-struct Serial_expr_evaluator<
-         1, DstBlock, 
-         const Binary_expr_block<1, op::Add,
-                                 Scalar_block<1, SType>, SType,
-                                 VBlock, VType>,
-         Intel_ipp_tag>
-  : ipp::Scalar_view_evaluator_base<op::Add, DstBlock, SType, VBlock, VType,
-				    true>
-{
-  typedef Binary_expr_block<1, op::Add,
-			    Scalar_block<1, SType>, SType,
-			    VBlock, VType>
-	SrcBlock;
-
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
-    ipp::svadd(src.left().value(), ext_r.data(), ext_dst.data(), dst.size());
-  }
-};
-
-
-
-template <typename DstBlock,
-	  typename SType,
-	  typename VBlock,
-	  typename VType>
-struct Serial_expr_evaluator<
-         1, DstBlock, 
-         const Binary_expr_block<1, op::Add,
-                                 VBlock, VType,
-                                 Scalar_block<1, SType>, SType>,
-         Intel_ipp_tag>
-  : ipp::Scalar_view_evaluator_base<op::Add, DstBlock, SType, VBlock, VType,
-				    false>
-{
-  typedef Binary_expr_block<1, op::Add,
-			    VBlock, VType,
-			    Scalar_block<1, SType>, SType>
-	SrcBlock;
-
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
-    ipp::svadd(src.right().value(), ext_l.data(), ext_dst.data(), dst.size());
-  }
-};
-
-
-
-template <typename DstBlock,
-	  typename SType,
-	  typename VBlock,
-	  typename VType>
-struct Serial_expr_evaluator<
-         1, DstBlock, 
-         const Binary_expr_block<1, op::Sub,
-                                 Scalar_block<1, SType>, SType,
-                                 VBlock, VType>,
-         Intel_ipp_tag>
-  : ipp::Scalar_view_evaluator_base<op::Sub, DstBlock, SType, VBlock, VType,
-				    true>
-{
-  typedef Binary_expr_block<1, op::Sub,
-			    Scalar_block<1, SType>, SType,
-			    VBlock, VType>
-	SrcBlock;
-
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
-    ipp::svsub(src.left().value(), ext_r.data(), ext_dst.data(), dst.size());
-  }
-};
-
-
-
-template <typename DstBlock,
-	  typename SType,
-	  typename VBlock,
-	  typename VType>
-struct Serial_expr_evaluator<
-         1, DstBlock, 
-         const Binary_expr_block<1, op::Sub,
-                                 VBlock, VType,
-                                 Scalar_block<1, SType>, SType>,
-         Intel_ipp_tag>
-  : ipp::Scalar_view_evaluator_base<op::Sub, DstBlock, SType, VBlock, VType,
-				    false>
-{
-  typedef Binary_expr_block<1, op::Sub,
-			    VBlock, VType,
-			    Scalar_block<1, SType>, SType>
-	SrcBlock;
-
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
-    ipp::svsub(ext_l.data(), src.right().value(), ext_dst.data(), dst.size());
-  }
-};
-
-
-
-template <typename DstBlock,
-	  typename SType,
-	  typename VBlock,
-	  typename VType>
-struct Serial_expr_evaluator<
-         1, DstBlock, 
-         const Binary_expr_block<1, op::Mult,
-                                 Scalar_block<1, SType>, SType,
-                                 VBlock, VType>,
-         Intel_ipp_tag>
-  : ipp::Scalar_view_evaluator_base<op::Mult, DstBlock, SType, VBlock, VType,
-				    true>
-{
-  typedef Binary_expr_block<1, op::Mult,
-			    Scalar_block<1, SType>, SType,
-			    VBlock, VType>
-	SrcBlock;
-
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
-    ipp::svmul(src.left().value(), ext_r.data(), ext_dst.data(), dst.size());
-  }
-};
-
-
-
-template <typename DstBlock,
-	  typename SType,
-	  typename VBlock,
-	  typename VType>
-struct Serial_expr_evaluator<
-         1, DstBlock, 
-         const Binary_expr_block<1, op::Mult,
-                                 VBlock, VType,
-                                 Scalar_block<1, SType>, SType>,
-         Intel_ipp_tag>
-  : ipp::Scalar_view_evaluator_base<op::Mult, DstBlock, SType, VBlock, VType,
-				    false>
-{
-  typedef Binary_expr_block<1, op::Mult,
-			    VBlock, VType,
-			    Scalar_block<1, SType>, SType>
-	SrcBlock;
-
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
-    ipp::svmul(src.right().value(), ext_l.data(), ext_dst.data(), dst.size());
-  }
-};
-
-
-
-template <typename DstBlock,
-	  typename VBlock>
-struct Serial_expr_evaluator<
-         1, DstBlock, 
-         const Binary_expr_block<1, op::Div,
-                                 Scalar_block<1, float>, float,
-                                 VBlock, float>,
-         Intel_ipp_tag>
-  : ipp::Scalar_view_evaluator_base<op::Div, DstBlock, float, VBlock, float,
-				    true>
-{
-  typedef float SType;
-  typedef float VType;
-  typedef Binary_expr_block<1, op::Div,
-			    Scalar_block<1, SType>, SType,
-			    VBlock, VType>
-	SrcBlock;
-
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
-    ipp::svdiv(src.left().value(), ext_r.data(), ext_dst.data(), dst.size());
-  }
-};
-
-
-
-template <typename DstBlock,
-	  typename SType,
-	  typename VBlock,
-	  typename VType>
-struct Serial_expr_evaluator<
-         1, DstBlock, 
-         const Binary_expr_block<1, op::Div,
-                                 VBlock, VType,
-                                 Scalar_block<1, SType>, SType>,
-         Intel_ipp_tag>
-  : ipp::Scalar_view_evaluator_base<op::Div, DstBlock, SType, VBlock, VType,
-				    false>
-{
-  typedef Binary_expr_block<1, op::Div,
-			    VBlock, VType,
-			    Scalar_block<1, SType>, SType>
-	SrcBlock;
-
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
-    ipp::svdiv(ext_l.data(), src.right().value(), ext_dst.data(), dst.size());
-  }
-};
 
 } // namespace vsip::impl
 } // namespace vsip
Index: src/vsip/impl/metaprogramming.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/metaprogramming.hpp,v
retrieving revision 1.13
diff -u -r1.13 metaprogramming.hpp
--- src/vsip/impl/metaprogramming.hpp	8 Jun 2006 18:50:51 -0000	1.13
+++ src/vsip/impl/metaprogramming.hpp	16 Jun 2006 12:17:39 -0000
@@ -73,6 +73,20 @@
 
 
 
+/// Pass type through if boolean value is true.  Used for SFINAE.
+
+template <typename T,
+	  bool     Bool>
+struct Type_if;
+
+template <typename T>
+struct Type_if<T, true>
+{
+  typedef T type;
+};
+
+
+
 /// Compare a compile-time value against a run-time value.
 
 /// Useful for avoiding '-W -Wall' warnings when comparing a compile-time
Index: src/vsip/impl/sal/elementwise.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/elementwise.hpp,v
retrieving revision 1.2
diff -u -r1.2 elementwise.hpp
--- src/vsip/impl/sal/elementwise.hpp	16 Jun 2006 02:36:58 -0000	1.2
+++ src/vsip/impl/sal/elementwise.hpp	16 Jun 2006 12:17:39 -0000
@@ -50,7 +50,7 @@
   Sal_vector<T> const& Z,						\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("V", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_V", SALFCN)					\
   SALFCN(A.ptr, A.stride, Z.ptr, Z.stride, len, 0);			\
 }
 
@@ -112,7 +112,7 @@
   Sal_vector<complex<T>, Cmplx_inter_fmt> const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("CV", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_CV", SALFCN)					\
   typedef Sal_inter<T>::type inter_type;				\
   SALFCN((inter_type*)A.ptr, 2*A.stride,				\
          (inter_type*)Z.ptr, 2*Z.stride, len, 0);			\
@@ -125,7 +125,7 @@
   Sal_vector<complex<T>, Cmplx_split_fmt > const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("ZV", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_ZV", SALFCN)					\
   typedef Sal_split<T>::type split_type;				\
   SALFCN((split_type*)&A.ptr, A.stride,					\
          (split_type*)&Z.ptr, Z.stride, len, 0);			\
@@ -157,7 +157,7 @@
   Sal_vector<T> const& Z,						\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("CVR", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_CVR", SALFCN)				\
   typedef Sal_inter<T>::type inter_type;				\
   SALFCN((inter_type*)A.ptr, 2*A.stride, Z.ptr, Z.stride, len, 0);	\
 }
@@ -169,7 +169,7 @@
   Sal_vector<T> const& Z,						\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("ZVR", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_ZVR", SALFCN)				\
   typedef Sal_split<T>::type split_type;				\
   SALFCN((split_type*)&A.ptr, A.stride, Z.ptr, Z.stride, len, 0);	\
 }
@@ -192,7 +192,7 @@
   Sal_vector<complex<T>, Cmplx_split_fmt > const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("CTOZ", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_CTOZ", SALFCN)				\
   typedef Sal_inter<T>::type inter_type;				\
   typedef Sal_split<T>::type split_type;				\
   SALFCN((inter_type*) A.ptr, 2*A.stride,				\
@@ -206,7 +206,7 @@
   Sal_vector<complex<T>, Cmplx_inter_fmt > const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("ZTOC", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_ZTOC", SALFCN)				\
   typedef Sal_inter<T>::type inter_type;				\
   typedef Sal_split<T>::type split_type;				\
   SALFCN((split_type*)&A.ptr,   A.stride,				\
@@ -244,7 +244,7 @@
   Sal_vector<T> const& Z,						\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("VV", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_VV", SALFCN)					\
   SALFCN(A.ptr, A.stride, B.ptr, B.stride, Z.ptr, Z.stride, len, 0);	\
 }
 
@@ -256,7 +256,7 @@
   Sal_vector<T> const& Z,						\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("VV_R", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_VV_R", SALFCN)				\
   SALFCN(B.ptr, B.stride, A.ptr, A.stride, Z.ptr, Z.stride, len, 0);	\
 }
 
@@ -299,7 +299,7 @@
   Sal_vector<complex<T>, Cmplx_inter_fmt> const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("CVV", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_CVV", SALFCN)				\
   typedef Sal_inter<T>::type inter_type;				\
   /* complex elements call for a stride of 2 and not 1 (when		\
    * dealing with dense data for example). this differs from		\ 
@@ -318,7 +318,7 @@
   Sal_vector<complex<T>, Cmplx_inter_fmt> const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("CVV_CF", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_CVV_CF", SALFCN)				\
   typedef Sal_inter<T>::type inter_type;				\
   /* complex elements call for a stride of 2 and not 1 (when		\
    * dealing with dense data for example). this differs from		\ 
@@ -334,7 +334,7 @@
   Sal_vector<complex<T>, Cmplx_inter_fmt> const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("CVV_R", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_CVV_R", SALFCN)				\
   typedef Sal_inter<T>::type inter_type;				\
   /* complex elements call for a stride of 2 and not 1 (when		\
    * dealing with dense data for example). this differs from		\ 
@@ -456,7 +456,7 @@
   Sal_vector<T> const& Z,						\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("VS", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_VS", SALFCN)					\
   SALFCN(A.ptr, A.stride, const_cast<T*>(&B.value),			\
          Z.ptr, Z.stride, len, 0);					\
 }
@@ -469,7 +469,7 @@
   Sal_vector<T> const& Z,						\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("SV", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_SV", SALFCN)					\
   SALFCN(const_cast<T*>(&A.value), B.ptr, B.stride, Z.ptr, Z.stride, len, 0);\
 }
 
@@ -481,7 +481,7 @@
   Sal_vector<T> const& Z,						\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("VS_COMM", SALFCN)				\
+  VSIP_IMPL_COVER_FCN("SAL_VS_COMM", SALFCN)				\
   SALFCN(B.ptr, B.stride, const_cast<T*>(&A.value),			\
          Z.ptr, Z.stride, len, 0);					\
 }
@@ -495,7 +495,7 @@
   length_type len)							\
 {									\
   T value = -B.value;							\
-  VSIP_IMPL_COVER_FCN("VS", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_VS", SALFCN)					\
   SALFCN(A.ptr, A.stride, const_cast<T*>(&value),			\
          Z.ptr, Z.stride, len, 0);					\
 }
@@ -689,7 +689,7 @@
     Sal_vector<T> const& Z,						\
     int len )								\
 {									\
-  VSIP_IMPL_COVER_FCN("VVV", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_VVV", SALFCN)				\
   SALFCN(A.ptr, A.stride, B.ptr, B.stride, C.ptr, C.stride,		\
          Z.ptr, Z.stride, len, 0);					\
 }
@@ -716,7 +716,7 @@
     Sal_vector<T> const& Z,						\
     int len )								\
 {									\
-  VSIP_IMPL_COVER_FCN("VSV", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_VSV", SALFCN)				\
   SALFCN(A.ptr, A.stride, 						\
 	 const_cast<T*>(&B.value), C.ptr, C.stride, Z.ptr,		\
          Z.stride, len, 0);						\
@@ -731,7 +731,7 @@
     Sal_vector<T> const& Z,						\
     int len )								\
 {									\
-  VSIP_IMPL_COVER_FCN("SVV_AS_VSV", SALFCN)				\
+  VSIP_IMPL_COVER_FCN("SAL_SVV_AS_VSV", SALFCN)				\
   SALFCN(B.ptr, B.stride, 						\
 	 const_cast<T*>(&A.value), C.ptr, C.stride, Z.ptr,		\
          Z.stride, len, 0);						\
@@ -761,7 +761,7 @@
   Sal_vector<T> const& Z,						\
   int len )								\
 {									\
-  VSIP_IMPL_COVER_FCN("VVS", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_VVS", SALFCN)				\
   SALFCN(A.ptr, A.stride, B.ptr, B.stride,				\
          const_cast<T*>(&C.value),					\
          Z.ptr, Z.stride, len, 0);					\
@@ -788,7 +788,7 @@
   Sal_vector<T> const& Z,						\
   int len )								\
 {									\
-  VSIP_IMPL_COVER_FCN("VSS", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_VSS", SALFCN)				\
   SALFCN(A.ptr, A.stride, const_cast<T*>(&B.value),			\
          const_cast<T*>(&C.value), Z.ptr, Z.stride, len, 0);		\
 }
@@ -811,7 +811,7 @@
 {									\
   typedef Sal_inter<T>::type inter_type;				\
   									\
-  VSIP_IMPL_COVER_FCN("CVSV", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_CVSV", SALFCN)				\
   SALFCN((inter_type*)A.ptr, 2*A.stride,				\
          (inter_type*)&B.value,						\
          (inter_type*)C.ptr, 2*C.stride,				\
@@ -829,7 +829,7 @@
 {									\
   typedef Sal_inter<T>::type inter_type;				\
   									\
-  VSIP_IMPL_COVER_FCN("CVSV", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_CVSV", SALFCN)				\
   SALFCN((inter_type*)B.ptr, 2*B.stride,				\
          (inter_type*)&A.value,						\
          (inter_type*)C.ptr, 2*C.stride,				\
@@ -861,7 +861,7 @@
   T imag = B.value.imag();						\
   split_type cB = { &real, &imag };					\
   									\
-  VSIP_IMPL_COVER_FCN("ZVSV", SALFCN)					\
+  VSIP_IMPL_COVER_FCN("SAL_ZVSV", SALFCN)				\
   SALFCN(cA, A.stride, &cB, cC, C.stride, cZ, Z.stride, len, 0);	\
 }
 
@@ -882,7 +882,7 @@
   T imag = A.value.imag();						\
   split_type cA = { &real, &imag };					\
   									\
-  VSIP_IMPL_COVER_FCN("ZSVV_AS_VSV", SALFCN)				\
+  VSIP_IMPL_COVER_FCN("SAL_ZSVV_AS_VSV", SALFCN)			\
   SALFCN(cB, B.stride, &cA, cC, C.stride, cZ, Z.stride, len, 0);	\
 }
 
@@ -1016,7 +1016,7 @@
   Sal_vector<complex<T>, Cmplx_inter_fmt> const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("CVS_SYN", SALFCN)				\
+  VSIP_IMPL_COVER_FCN("SAL_CVS_SYN", SALFCN)				\
 									\
   T real = SCALAR_OP B.value.real();					\
   T imag = SCALAR_OP B.value.imag();					\
@@ -1033,7 +1033,7 @@
   Sal_vector<complex<T>, Cmplx_inter_fmt> const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("CSV_SYN", SALFCN)				\
+  VSIP_IMPL_COVER_FCN("SAL_CSV_SYN", SALFCN)				\
 									\
   T real = A.value.real();						\
   T imag = A.value.imag();						\
@@ -1063,7 +1063,7 @@
   Sal_vector<complex<T>, Cmplx_inter_fmt> const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("CRVS_ADD_SYN", SALFCN)				\
+  VSIP_IMPL_COVER_FCN("SAL_CRVS_ADD_SYN", SALFCN)				\
 									\
   T real = SCALAR_OP B.value;						\
 									\
@@ -1079,7 +1079,7 @@
   Sal_vector<complex<T>, Cmplx_inter_fmt> const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("CRSV_ADD_SYN", SALFCN)				\
+  VSIP_IMPL_COVER_FCN("SAL_CRSV_ADD_SYN", SALFCN)				\
 									\
   T real = A.value;							\
 									\
@@ -1095,7 +1095,7 @@
   Sal_vector<complex<T>, Cmplx_inter_fmt> const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("CRVS_MUL_SYN", SALFCN)				\
+  VSIP_IMPL_COVER_FCN("SAL_CRVS_MUL_SYN", SALFCN)			\
 									\
   T real = B.value;							\
 									\
@@ -1116,7 +1116,7 @@
   Sal_vector<complex<T>, Cmplx_inter_fmt> const& Z,			\
   length_type len)							\
 {									\
-  VSIP_IMPL_COVER_FCN("CRSV_MUL_SYN", SALFCN)				\
+  VSIP_IMPL_COVER_FCN("SAL_CRSV_MUL_SYN", SALFCN)			\
 									\
   T real = A.value;							\
 									\
Index: src/vsip/impl/sal/eval_elementwise.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/eval_elementwise.hpp,v
retrieving revision 1.2
diff -u -r1.2 eval_elementwise.hpp
--- src/vsip/impl/sal/eval_elementwise.hpp	5 Jun 2006 21:53:18 -0000	1.2
+++ src/vsip/impl/sal/eval_elementwise.hpp	16 Jun 2006 12:17:39 -0000
@@ -21,7 +21,9 @@
 #include <vsip/impl/expr_operations.hpp>
 #include <vsip/impl/fns_elementwise.hpp>
 #include <vsip/impl/extdata.hpp>
+#include <vsip/impl/metaprogramming.hpp>
 #include <vsip/impl/sal/eval_util.hpp>
+#include <vsip/impl/adjust-layout.hpp>
 
 
 
@@ -447,13 +449,22 @@
 struct Serial_expr_evaluator<						\
          1, DstBlock, 							\
          SrcBlock,							\
-         Mercury_sal_tag>						\
+         typename Type_if<Mercury_sal_tag,				\
+                          Is_leaf_block<SrcBlock>::value>::type>	\
 {									\
   typedef typename DstBlock::value_type dst_type;			\
 									\
   typedef typename sal::Effective_value_type<DstBlock>::type eff_dst_t;	\
   typedef typename sal::Effective_value_type<SrcBlock>::type eff_src_t;	\
 									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<SrcBlock>::layout_type>::type		\
+    src_lp;								\
+  									\
   static bool const ct_valid = 						\
     (!Is_expr_block<SrcBlock>::value || Is_scalar_block<SrcBlock>::value) &&\
      sal::Is_op1_supported<OP, eff_src_t, eff_dst_t>::value&&		\
@@ -470,10 +481,10 @@
 									\
   static void exec(DstBlock& dst, SrcBlock const& src)			\
   {									\
-    sal::Ext_wrapper<DstBlock> ext_dst(dst, SYNC_OUT);			\
-    sal::Ext_wrapper<SrcBlock>   ext_src(src, SYNC_IN);			\
-    FUN(typename sal::Ext_wrapper<SrcBlock>::sal_type(ext_src),		\
-	typename sal::Ext_wrapper<DstBlock>::sal_type(ext_dst),		\
+    sal::Ext_wrapper<DstBlock, dst_lp> ext_dst(dst, SYNC_OUT);		\
+    sal::Ext_wrapper<SrcBlock, src_lp> ext_src(src, SYNC_IN);		\
+    FUN(typename sal::Ext_wrapper<SrcBlock, dst_lp>::sal_type(ext_src),	\
+	typename sal::Ext_wrapper<DstBlock, src_lp>::sal_type(ext_dst),	\
 	dst.size());							\
   }									\
 };
@@ -493,7 +504,8 @@
 struct Serial_expr_evaluator<						\
          1, DstBlock, 							\
          Unary_expr_block<1, OP, Block1, Type1> const,			\
-         Mercury_sal_tag>						\
+         typename Type_if<Mercury_sal_tag,				\
+                          Is_leaf_block<Block1>::value>::type>		\
 {									\
   typedef Unary_expr_block<1, OP, Block1, Type1> const			\
 	SrcBlock;							\
@@ -503,6 +515,14 @@
   typedef typename sal::Effective_value_type<DstBlock>::type eff_dst_t;	\
   typedef typename sal::Effective_value_type<Block1, Type1>::type eff_1_t;\
 									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block1>::layout_type>::type		\
+    block1_lp;								\
+  									\
   static bool const ct_valid = 						\
     (!Is_expr_block<Block1>::value || Is_scalar_block<Block1>::value) &&\
      sal::Is_op1_supported<OP, eff_1_t, eff_dst_t>::value&&		\
@@ -518,10 +538,10 @@
 									\
   static void exec(DstBlock& dst, SrcBlock const& src)			\
   {									\
-    sal::Ext_wrapper<DstBlock> ext_dst(dst,     SYNC_OUT);		\
-    sal::Ext_wrapper<Block1>   ext_1(src.op(),  SYNC_IN);		\
-    FUN(typename sal::Ext_wrapper<Block1>::sal_type(ext_1),		\
-	typename sal::Ext_wrapper<DstBlock>::sal_type(ext_dst),		\
+    sal::Ext_wrapper<DstBlock, dst_lp>  ext_dst(dst,     SYNC_OUT);	\
+    sal::Ext_wrapper<Block1, block1_lp> ext_1(src.op(),  SYNC_IN);	\
+    FUN(typename sal::Ext_wrapper<Block1, block1_lp>::sal_type(ext_1),	\
+	typename sal::Ext_wrapper<DstBlock, dst_lp>::sal_type(ext_dst),	\
 	dst.size());							\
   }									\
 };
@@ -557,22 +577,40 @@
 struct Serial_expr_evaluator<						\
     1, DstBlock, 							\
     const Binary_expr_block<1, OP, LBlock, LType, RBlock, RType>,	\
-    Mercury_sal_tag>							\
+    typename Type_if<Mercury_sal_tag,					\
+                     Is_leaf_block<LBlock>::value &&			\
+                     Is_leaf_block<RBlock>::value>::type>		\
   : sal::Serial_expr_evaluator_base_mixed<OP, DstBlock, LBlock, RBlock, LType, RType>		\
 {									\
   typedef Binary_expr_block<1, OP, LBlock, LType, RBlock, RType>	\
     SrcBlock;								\
   									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<LBlock>::layout_type>::type		\
+    lblock_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<RBlock>::layout_type>::type		\
+    rblock_lp;								\
+  									\
   static void exec(DstBlock& dst, SrcBlock const& src)			\
   {									\
-    sal::Ext_wrapper<DstBlock> ext_dst(dst,       SYNC_OUT);		\
-    sal::Ext_wrapper<LBlock>   ext_l(src.left(),  SYNC_IN);		\
-    sal::Ext_wrapper<RBlock>   ext_r(src.right(), SYNC_IN);		\
+    sal::Ext_wrapper<DstBlock, dst_lp>  ext_dst(dst,       SYNC_OUT);	\
+    sal::Ext_wrapper<LBlock, lblock_lp> ext_l(src.left(),  SYNC_IN);	\
+    sal::Ext_wrapper<RBlock, rblock_lp> ext_r(src.right(), SYNC_IN);	\
+									\
+    assert(dst.size() <= src.left().size());				\
+    assert(dst.size() <= src.right().size());				\
 									\
+    VSIP_IMPL_COVER_BLK("SAL_VV", SrcBlock);				\
     FUN(								\
-      typename sal::Ext_wrapper<LBlock>::sal_type(ext_l),		\
-      typename sal::Ext_wrapper<RBlock>::sal_type(ext_r),		\
-      typename sal::Ext_wrapper<DstBlock>::sal_type(ext_dst),		\
+      typename sal::Ext_wrapper<LBlock, lblock_lp>::sal_type(ext_l),	\
+      typename sal::Ext_wrapper<RBlock, lblock_lp>::sal_type(ext_r),	\
+      typename sal::Ext_wrapper<DstBlock, dst_lp>::sal_type(ext_dst),	\
       dst.size()							\
     );									\
   }									\
@@ -623,6 +661,22 @@
   typedef typename sal::Effective_value_type<Block2, Type2>::type eff_2_t;\
   typedef typename sal::Effective_value_type<Block3, Type3>::type eff_3_t;\
 									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block1>::layout_type>::type		\
+    block1_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block2>::layout_type>::type		\
+    block2_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block3>::layout_type>::type		\
+    block3_lp;								\
+  									\
   static bool const ct_valid = 						\
     (!Is_expr_block<Block1>::value || Is_scalar_block<Block1>::value) &&\
     (!Is_expr_block<Block2>::value || Is_scalar_block<Block2>::value) &&\
@@ -642,14 +696,14 @@
 									\
   static void exec(DstBlock& dst, SrcBlock const& src)			\
   {									\
-    sal::Ext_wrapper<DstBlock> ext_dst(dst,        SYNC_OUT);		\
-    sal::Ext_wrapper<Block1>   ext_1(src.first(),  SYNC_IN);		\
-    sal::Ext_wrapper<Block2>   ext_2(src.second(), SYNC_IN);		\
-    sal::Ext_wrapper<Block3>   ext_3(src.third(),  SYNC_IN);		\
-    FUN(typename sal::Ext_wrapper<Block1>::sal_type(ext_1),		\
-        typename sal::Ext_wrapper<Block2>::sal_type(ext_2),		\
-        typename sal::Ext_wrapper<Block3>::sal_type(ext_3),		\
-	typename sal::Ext_wrapper<DstBlock>::sal_type(ext_dst),		\
+    sal::Ext_wrapper<DstBlock, dst_lp>  ext_dst(dst,        SYNC_OUT);	\
+    sal::Ext_wrapper<Block1, block1_lp> ext_1(src.first(),  SYNC_IN);	\
+    sal::Ext_wrapper<Block2, block2_lp> ext_2(src.second(), SYNC_IN);	\
+    sal::Ext_wrapper<Block3, block3_lp> ext_3(src.third(),  SYNC_IN);	\
+    FUN(typename sal::Ext_wrapper<Block1, block1_lp>::sal_type(ext_1),	\
+        typename sal::Ext_wrapper<Block2, block1_lp>::sal_type(ext_2),	\
+        typename sal::Ext_wrapper<Block3, block1_lp>::sal_type(ext_3),	\
+	typename sal::Ext_wrapper<DstBlock, dst_lp>::sal_type(ext_dst),	\
 	dst.size());							\
   }									\
 };
@@ -692,6 +746,22 @@
   typedef typename sal::Effective_value_type<Block2, Type2>::type eff_2_t;\
   typedef typename sal::Effective_value_type<Block3, Type3>::type eff_3_t;\
 									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block1>::layout_type>::type		\
+    block1_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block2>::layout_type>::type		\
+    block2_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block3>::layout_type>::type		\
+    block3_lp;								\
+  									\
   static bool const ct_valid = 						\
     (!Is_expr_block<Block1>::value || Is_scalar_block<Block1>::value) &&\
     (!Is_expr_block<Block2>::value || Is_scalar_block<Block2>::value) &&\
@@ -712,14 +782,14 @@
 									\
   static void exec(DstBlock& dst, SrcBlock const& src)			\
   {									\
-    sal::Ext_wrapper<DstBlock> ext_dst(dst,            SYNC_OUT);	\
-    sal::Ext_wrapper<Block1>   ext_1(src.first().op(), SYNC_IN);	\
-    sal::Ext_wrapper<Block2>   ext_2(src.second(),     SYNC_IN);	\
-    sal::Ext_wrapper<Block3>   ext_3(src.third(),      SYNC_IN);	\
-    FUN(typename sal::Ext_wrapper<Block1>::sal_type(ext_1),		\
-        typename sal::Ext_wrapper<Block2>::sal_type(ext_2),		\
-        typename sal::Ext_wrapper<Block3>::sal_type(ext_3),		\
-	typename sal::Ext_wrapper<DstBlock>::sal_type(ext_dst),		\
+    sal::Ext_wrapper<DstBlock, dst_lp>  ext_dst(dst,            SYNC_OUT);\
+    sal::Ext_wrapper<Block1, block1_lp> ext_1(src.first().op(), SYNC_IN);\
+    sal::Ext_wrapper<Block2, block2_lp> ext_2(src.second(),     SYNC_IN);\
+    sal::Ext_wrapper<Block3, block3_lp> ext_3(src.third(),      SYNC_IN);\
+    FUN(typename sal::Ext_wrapper<Block1, block1_lp>::sal_type(ext_1),	\
+        typename sal::Ext_wrapper<Block2, block2_lp>::sal_type(ext_2),	\
+        typename sal::Ext_wrapper<Block3, block3_lp>::sal_type(ext_3),	\
+	typename sal::Ext_wrapper<DstBlock, dst_lp>::sal_type(ext_dst),	\
 	dst.size());							\
   }									\
 };
@@ -748,7 +818,10 @@
                          Block1, Type1,					\
                          Block2, Type2> const, TypeB,			\
                  Block3, Type3> const,					\
-         Mercury_sal_tag>						\
+         typename Type_if<Mercury_sal_tag,				\
+                     Is_leaf_block<Block1>::value &&			\
+                     Is_leaf_block<Block2>::value &&			\
+                     Is_leaf_block<Block3>::value>::type>		\
 {									\
   typedef Binary_expr_block<						\
                  1, OP2,						\
@@ -766,6 +839,22 @@
   typedef typename sal::Effective_value_type<Block2, Type2>::type eff_2_t;\
   typedef typename sal::Effective_value_type<Block3, Type3>::type eff_3_t;\
 									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block1>::layout_type>::type		\
+    block1_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block2>::layout_type>::type		\
+    block2_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block3>::layout_type>::type		\
+    block3_lp;								\
+  									\
   static bool const ct_valid = 						\
     (!Is_expr_block<Block1>::value || Is_scalar_block<Block1>::value) &&\
     (!Is_expr_block<Block2>::value || Is_scalar_block<Block2>::value) &&\
@@ -785,14 +874,14 @@
 									\
   static void exec(DstBlock& dst, SrcBlock const& src)			\
   {									\
-    sal::Ext_wrapper<DstBlock> ext_dst(dst,        SYNC_OUT);		\
-    sal::Ext_wrapper<Block1>   ext_1(src.left().left(),  SYNC_IN);	\
-    sal::Ext_wrapper<Block2>   ext_2(src.left().right(), SYNC_IN);	\
-    sal::Ext_wrapper<Block3>   ext_3(src.right(),  SYNC_IN);		\
-    FUN(typename sal::Ext_wrapper<Block1>::sal_type(ext_1),		\
-        typename sal::Ext_wrapper<Block2>::sal_type(ext_2),		\
-        typename sal::Ext_wrapper<Block3>::sal_type(ext_3),		\
-	typename sal::Ext_wrapper<DstBlock>::sal_type(ext_dst),		\
+    sal::Ext_wrapper<DstBlock, dst_lp> ext_dst(dst,        SYNC_OUT);	\
+    sal::Ext_wrapper<Block1, block1_lp>   ext_1(src.left().left(),  SYNC_IN);\
+    sal::Ext_wrapper<Block2, block2_lp>   ext_2(src.left().right(), SYNC_IN);\
+    sal::Ext_wrapper<Block3, block3_lp>   ext_3(src.right(),  SYNC_IN);	\
+    FUN(typename sal::Ext_wrapper<Block1, block1_lp>::sal_type(ext_1),	\
+        typename sal::Ext_wrapper<Block2, block2_lp>::sal_type(ext_2),	\
+        typename sal::Ext_wrapper<Block3, block3_lp>::sal_type(ext_3),	\
+	typename sal::Ext_wrapper<DstBlock, dst_lp>::sal_type(ext_dst),	\
 	dst.size());							\
   }									\
 };
@@ -817,7 +906,10 @@
                          1, OP1,					\
                          Block2, Type2,					\
                          Block3, Type3> const, TypeB> const,		\
-         Mercury_sal_tag>						\
+         typename Type_if<Mercury_sal_tag,				\
+                     Is_leaf_block<Block1>::value &&			\
+                     Is_leaf_block<Block2>::value &&			\
+                     Is_leaf_block<Block3>::value>::type>		\
 {									\
   typedef Binary_expr_block<						\
                  1, OP2,						\
@@ -835,6 +927,22 @@
   typedef typename sal::Effective_value_type<Block2, Type2>::type eff_2_t;\
   typedef typename sal::Effective_value_type<Block3, Type3>::type eff_3_t;\
 									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block1>::layout_type>::type		\
+    block1_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block2>::layout_type>::type		\
+    block2_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block3>::layout_type>::type		\
+    block3_lp;								\
+  									\
   static bool const ct_valid = 						\
     (!Is_expr_block<Block1>::value || Is_scalar_block<Block1>::value) &&\
     (!Is_expr_block<Block2>::value || Is_scalar_block<Block2>::value) &&\
@@ -854,14 +962,14 @@
 									\
   static void exec(DstBlock& dst, SrcBlock const& src)			\
   {									\
-    sal::Ext_wrapper<DstBlock> ext_dst(dst,               SYNC_OUT);	\
-    sal::Ext_wrapper<Block1>   ext_1(src.left(),          SYNC_IN);	\
-    sal::Ext_wrapper<Block2>   ext_2(src.right().left(),  SYNC_IN);	\
-    sal::Ext_wrapper<Block3>   ext_3(src.right().right(), SYNC_IN);	\
-    FUN(typename sal::Ext_wrapper<Block2>::sal_type(ext_2),		\
-        typename sal::Ext_wrapper<Block3>::sal_type(ext_3),		\
-        typename sal::Ext_wrapper<Block1>::sal_type(ext_1),		\
-	typename sal::Ext_wrapper<DstBlock>::sal_type(ext_dst),		\
+    sal::Ext_wrapper<DstBlock, dst_lp>  ext_dst(dst,               SYNC_OUT);\
+    sal::Ext_wrapper<Block1, block1_lp> ext_1(src.left(),          SYNC_IN);\
+    sal::Ext_wrapper<Block2, block2_lp> ext_2(src.right().left(),  SYNC_IN);\
+    sal::Ext_wrapper<Block3, block3_lp> ext_3(src.right().right(), SYNC_IN);\
+    FUN(typename sal::Ext_wrapper<Block2, block2_lp>::sal_type(ext_2),	\
+        typename sal::Ext_wrapper<Block3, block3_lp>::sal_type(ext_3),	\
+        typename sal::Ext_wrapper<Block1, block1_lp>::sal_type(ext_1),	\
+	typename sal::Ext_wrapper<DstBlock, dst_lp>::sal_type(ext_dst),	\
 	dst.size());							\
   }									\
 };
@@ -916,6 +1024,22 @@
   typedef typename sal::Effective_value_type<Block2, Type2>::type eff_2_t;\
   typedef typename sal::Effective_value_type<Block3, Type3>::type eff_3_t;\
 									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block1>::layout_type>::type		\
+    block1_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block2>::layout_type>::type		\
+    block2_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block3>::layout_type>::type		\
+    block3_lp;								\
+  									\
   static bool const ct_valid = 						\
     (!Is_expr_block<Block1>::value || Is_scalar_block<Block1>::value) &&\
     (!Is_expr_block<Block2>::value || Is_scalar_block<Block2>::value) &&\
@@ -935,14 +1059,14 @@
 									\
   static void exec(DstBlock& dst, SrcBlock const& src)			\
   {									\
-    sal::Ext_wrapper<DstBlock> ext_dst(dst,        SYNC_OUT);		\
-    sal::Ext_wrapper<Block1>   ext_1(src.left().left().op(),  SYNC_IN);	\
-    sal::Ext_wrapper<Block2>   ext_2(src.left().right(), SYNC_IN);	\
-    sal::Ext_wrapper<Block3>   ext_3(src.right(),  SYNC_IN);		\
-    FUN(typename sal::Ext_wrapper<Block1>::sal_type(ext_1),		\
-        typename sal::Ext_wrapper<Block2>::sal_type(ext_2),		\
-        typename sal::Ext_wrapper<Block3>::sal_type(ext_3),		\
-	typename sal::Ext_wrapper<DstBlock>::sal_type(ext_dst),		\
+    sal::Ext_wrapper<DstBlock, dst_lp>  ext_dst(dst,        SYNC_OUT);	\
+    sal::Ext_wrapper<Block1, block1_lp> ext_1(src.left().left().op(),SYNC_IN);\
+    sal::Ext_wrapper<Block2, block2_lp> ext_2(src.left().right(),    SYNC_IN);\
+    sal::Ext_wrapper<Block3, block3_lp> ext_3(src.right(),           SYNC_IN);\
+    FUN(typename sal::Ext_wrapper<Block1, block1_lp>::sal_type(ext_1),	\
+        typename sal::Ext_wrapper<Block2, block2_lp>::sal_type(ext_2),	\
+        typename sal::Ext_wrapper<Block3, block3_lp>::sal_type(ext_3),	\
+	typename sal::Ext_wrapper<DstBlock, dst_lp>::sal_type(ext_dst),	\
 	dst.size());							\
   }									\
 };
Index: src/vsip/impl/sal/eval_util.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/eval_util.hpp,v
retrieving revision 1.1
diff -u -r1.1 eval_util.hpp
--- src/vsip/impl/sal/eval_util.hpp	2 Jun 2006 02:21:51 -0000	1.1
+++ src/vsip/impl/sal/eval_util.hpp	16 Jun 2006 12:17:39 -0000
@@ -77,7 +77,8 @@
 
 
 
-template <typename BlockT>
+template <typename BlockT,
+	  typename LP = typename Block_layout<BlockT>::layout_type>
 struct Ext_wrapper
 {
   typedef typename Block_layout<BlockT>::complex_type complex_type;
@@ -97,14 +98,15 @@
 
   bool is_unit_stride() { return ext_.stride(0) == 1; }
 
-  Ext_data<BlockT> ext_;
+  Ext_data<BlockT, LP> ext_;
 };
 
 
 
 template <dimension_type Dim,
-	  typename       T>
-struct Ext_wrapper<Scalar_block<Dim, T> >
+	  typename       T,
+	  typename       LP>
+struct Ext_wrapper<Scalar_block<Dim, T>, LP>
 {
   typedef Scalar_block<Dim, T> block_type;
   typedef Sal_scalar<T>        sal_type;
@@ -125,8 +127,9 @@
 
 
 template <dimension_type Dim,
-	  typename       T>
-struct Ext_wrapper<Scalar_block<Dim, T> const>
+	  typename       T,
+	  typename       LP>
+struct Ext_wrapper<Scalar_block<Dim, T> const, LP>
 {
   typedef Scalar_block<Dim, T> block_type;
   typedef Sal_scalar<T>        sal_type;
