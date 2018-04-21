Index: ChangeLog
===================================================================
--- ChangeLog	(revision 154623)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2006-11-14  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/ipp/bindings.hpp: Add dispatch for mag.
+	* src/vsip/opt/ipp/bindings.cpp: Add bindings for mag and magsq
+	  (magsq is real only).
+	
 2006-11-13  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/diag/eval.hpp: New file, diagnostics for
Index: src/vsip/opt/ipp/bindings.hpp
===================================================================
--- src/vsip/opt/ipp/bindings.hpp	(revision 154623)
+++ src/vsip/opt/ipp/bindings.hpp	(working copy)
@@ -70,20 +70,37 @@
 FCN(									\
   T const* A,								\
   T*       Z,								\
-  length_type len)
+  length_type len);
 
+#define VSIP_IMPL_IPP_DECL_V_CR(FCN, T, IPPFCN, IPPCT, IPPT)		\
+void									\
+FCN(									\
+  complex<T> const* A,							\
+  T*       Z,								\
+  length_type len);
+
 // Square
-VSIP_IMPL_IPP_DECL_V(vsq,  float,           ippsSqr_32f,  Ipp32f);
-VSIP_IMPL_IPP_DECL_V(vsq,  double,          ippsSqr_64f,  Ipp64f);
-VSIP_IMPL_IPP_DECL_V(vsq,  complex<float>,  ippsSqr_32fc, Ipp32fc);
-VSIP_IMPL_IPP_DECL_V(vsq,  complex<double>, ippsSqr_64fc, Ipp64fc);
+VSIP_IMPL_IPP_DECL_V(vsq,  float,           ippsSqr_32f,  Ipp32f)
+VSIP_IMPL_IPP_DECL_V(vsq,  double,          ippsSqr_64f,  Ipp64f)
+VSIP_IMPL_IPP_DECL_V(vsq,  complex<float>,  ippsSqr_32fc, Ipp32fc)
+VSIP_IMPL_IPP_DECL_V(vsq,  complex<double>, ippsSqr_64fc, Ipp64fc)
 
 // Square-root
-VSIP_IMPL_IPP_DECL_V(vsqrt, float,           ippsSqrt_32f,  Ipp32f);
-VSIP_IMPL_IPP_DECL_V(vsqrt, double,          ippsSqrt_64f,  Ipp64f);
-VSIP_IMPL_IPP_DECL_V(vsqrt, complex<float>,  ippsSqrt_32fc, Ipp32fc);
-VSIP_IMPL_IPP_DECL_V(vsqrt, complex<double>, ippsSqrt_64fc, Ipp64fc);
+VSIP_IMPL_IPP_DECL_V(vsqrt, float,           ippsSqrt_32f,  Ipp32f)
+VSIP_IMPL_IPP_DECL_V(vsqrt, double,          ippsSqrt_64f,  Ipp64f)
+VSIP_IMPL_IPP_DECL_V(vsqrt, complex<float>,  ippsSqrt_32fc, Ipp32fc)
+VSIP_IMPL_IPP_DECL_V(vsqrt, complex<double>, ippsSqrt_64fc, Ipp64fc)
 
+// Mag 
+VSIP_IMPL_IPP_DECL_V(vmag, float,           ippsAbs_32f,  Ipp32f)
+VSIP_IMPL_IPP_DECL_V(vmag, double,          ippsAbs_64f,  Ipp64f)
+VSIP_IMPL_IPP_DECL_V_CR(vmag, float,  ippsMagnitude_32f, Ipp32fc, Ipp32f)
+VSIP_IMPL_IPP_DECL_V_CR(vmag, double, ippsMagnitude_64f, Ipp64fc, Ipp64f)
+
+// Mag-sq
+VSIP_IMPL_IPP_DECL_V(vmagsq,    float,  ippsSqr_32f,  Ipp32f)
+VSIP_IMPL_IPP_DECL_V(vmagsq,    double, ippsSqr_64f,  Ipp64f)
+
 // functions for vector addition
 void vadd(float const* A, float const* B, float* Z, length_type len);
 void vadd(double const* A, double const* B, double* Z, length_type len);
@@ -334,8 +351,69 @@
   }									\
 };
 
+
+
+#define VSIP_IMPL_IPP_V_CR_EXPR(OP, FUN)				\
+template <typename DstBlock,						\
+	  typename Block,						\
+	  typename Type>						\
+struct Serial_expr_evaluator<						\
+    1, DstBlock, 							\
+    Unary_expr_block<1, OP, Block, Type> const,				\
+    Intel_ipp_tag>							\
+{									\
+  static char const* name() { return "Expr_IPP_V_CR-" #FUN; }		\
+									\
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
+     ipp::Is_type_supported<Type>::value &&				\
+     /* Type_equal<typename DstBlock::value_type, Type>::value && */	\
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
+    FUN(								\
+      ext_src.data(),							\
+      ext_dst.data(),							\
+      dst.size()							\
+    );									\
+  }									\
+};
+
 VSIP_IMPL_IPP_V_EXPR(sq_functor,   ipp::vsq)
 VSIP_IMPL_IPP_V_EXPR(sqrt_functor, ipp::vsqrt)
+VSIP_IMPL_IPP_V_CR_EXPR(mag_functor,  ipp::vmag)
+// Don't dispatch for now since only real magsq is supported.
+// VSIP_IMPL_IPP_V_CR_EXPR(magsq_functor,  ipp::vmagsq)
 
 
 
Index: src/vsip/opt/ipp/bindings.cpp
===================================================================
--- src/vsip/opt/ipp/bindings.cpp	(revision 154623)
+++ src/vsip/opt/ipp/bindings.cpp	(working copy)
@@ -46,6 +46,26 @@
   }									\
 }
 
+// Complex->Real unary function.
+
+#define VSIP_IMPL_IPP_V_CR(FCN, T, IPPFCN, IPPCT, IPPT)			\
+void									\
+FCN(									\
+  complex<T> const* A,							\
+  T*                Z,							\
+  length_type len)							\
+{									\
+  VSIP_IMPL_COVER_FCN("IPP_V_CR", IPPFCN)				\
+  if (len > 0)								\
+  {									\
+    IppStatus status = IPPFCN(						\
+      reinterpret_cast<IPPCT const*>(A),				\
+      reinterpret_cast<IPPT*>(Z),					\
+      static_cast<int>(len));						\
+    assert(status == ippStsNoErr);					\
+  }									\
+}
+
 #define VSIP_IMPL_IPP_VV(FCN, T, IPPFCN, IPPT)				\
 void									\
 FCN(									\
@@ -84,12 +104,19 @@
   }									\
 }
 
-// Abs
-// VSIP_IMPL_IPP_V(vabs, int16,           ippsAbs_16s,  Ipp16s)
-// VSIP_IMPL_IPP_V(vabs, int32,           ippsAbs_32s,  Ipp32s)
-VSIP_IMPL_IPP_V(vabs, float,           ippsAbs_32f,  Ipp32f)
-VSIP_IMPL_IPP_V(vabs, double,          ippsAbs_64f,  Ipp64f)
+// Magnitude (aka abs)
+// VSIP_IMPL_IPP_V(vmag, int16,           ippsAbs_16s,  Ipp16s)
+// VSIP_IMPL_IPP_V(vmag, int32,           ippsAbs_32s,  Ipp32s)
+VSIP_IMPL_IPP_V(vmag, float,           ippsAbs_32f,  Ipp32f)
+VSIP_IMPL_IPP_V(vmag, double,          ippsAbs_64f,  Ipp64f)
+VSIP_IMPL_IPP_V_CR(vmag, float,  ippsMagnitude_32fc, Ipp32fc, Ipp32f)
+VSIP_IMPL_IPP_V_CR(vmag, double, ippsMagnitude_64fc, Ipp64fc, Ipp64f)
 
+// Mag-sq
+VSIP_IMPL_IPP_V(vmagsq,    float,  ippsSqr_32f,  Ipp32f)
+VSIP_IMPL_IPP_V(vmagsq,    double, ippsSqr_64f,  Ipp64f)
+// IPP 4.x does not have magsq for complex floating-point
+
 // Square
 VSIP_IMPL_IPP_V(vsq,  float,           ippsSqr_32f,  Ipp32f)
 VSIP_IMPL_IPP_V(vsq,  double,          ippsSqr_64f,  Ipp64f)
