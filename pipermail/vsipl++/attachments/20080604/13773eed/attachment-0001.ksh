Index: src/vsip/core/vmmul.hpp
===================================================================
--- src/vsip/core/vmmul.hpp	(revision 210310)
+++ src/vsip/core/vmmul.hpp	(working copy)
@@ -54,7 +54,7 @@
 #if !VSIP_IMPL_REF_IMPL
 /// Evaluator for vector-matrix multiply.
 
-/// Reduces vmmul into either vector element-wise multipy, or
+/// Reduces vmmul into either vector element-wise multiply, or
 /// scalar-vector multiply, depending on the dimension-ordering and
 /// requested orientation.  These reduced cases are then
 /// re-dispatched, allowing them to be handled by a vendor library,
Index: src/vsip/core/type_list.hpp
===================================================================
--- src/vsip/core/type_list.hpp	(revision 210310)
+++ src/vsip/core/type_list.hpp	(working copy)
@@ -37,12 +37,13 @@
 	  typename T11 = None_type,
 	  typename T12 = None_type,
 	  typename T13 = None_type,
-	  typename T14 = None_type>
+	  typename T14 = None_type,
+	  typename T15 = None_type>
 struct Make_type_list
 {
 private:
   typedef typename 
-  Make_type_list<T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14>::type Rest;
+  Make_type_list<T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15>::type Rest;
 public:
   typedef Type_list<T1, Rest> type;
 };
Index: src/vsip/opt/cbe/cml/transpose.hpp
===================================================================
--- src/vsip/opt/cbe/cml/transpose.hpp	(revision 0)
+++ src/vsip/opt/cbe/cml/transpose.hpp	(revision 0)
@@ -0,0 +1,322 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/cml/transpose.hpp
+    @author  Don McCoy
+    @date    2008-06-04
+    @brief   VSIPL++ Library: Bindings for CML matrix transpose.
+*/
+
+#ifndef VSIP_OPT_CBE_CML_TRANSPOSE_HPP
+#define VSIP_OPT_CBE_CML_TRANSPOSE_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/core/block_traits.hpp>
+#include <vsip/core/extdata.hpp>
+#include <vsip/core/impl_tags.hpp>
+#include <vsip/opt/cbe/cml/traits.hpp>
+
+#include <cml/ppu/cml.h>
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+namespace cml
+{
+
+// These macros support scalar and interleaved complex types
+
+#define VSIP_IMPL_CML_TRANS(T, FCN, CML_FCN)    \
+  inline void                                   \
+  FCN(                                          \
+    T* a, ptrdiff_t rsa, ptrdiff_t csa,         \
+    T* z, ptrdiff_t rsz, ptrdiff_t csz,         \
+    size_t m, size_t n)                         \
+  {                                             \
+    typedef Scalar_of<T>::type CML_T;           \
+    CML_FCN(                                    \
+      reinterpret_cast<CML_T*>(a), rsa, csa,    \
+      reinterpret_cast<CML_T*>(z), rsz, csz,    \
+      m, n );                                   \
+  }
+
+VSIP_IMPL_CML_TRANS(float,               transpose, cml_mtrans_f)
+VSIP_IMPL_CML_TRANS(std::complex<float>, transpose, cml_cmtrans_f)
+#undef VSIP_IMPL_CML_TRANS
+
+
+#define VSIP_IMPL_CML_TRANS_UNIT(T, FCN, CML_FCN)  \
+  inline void                                      \
+  FCN(                                             \
+    T* a, ptrdiff_t rsa,                           \
+    T* z, ptrdiff_t rsz,                           \
+    size_t m, size_t n)                            \
+  {                                                \
+    typedef Scalar_of<T>::type CML_T;              \
+    CML_FCN(                                       \
+      reinterpret_cast<CML_T*>(a), rsa,            \
+      reinterpret_cast<CML_T*>(z), rsz,            \
+      m, n );                                      \
+  }
+
+VSIP_IMPL_CML_TRANS_UNIT(float,               transpose_unit, cml_mtrans1_f)
+VSIP_IMPL_CML_TRANS_UNIT(std::complex<float>, transpose_unit, cml_cmtrans1_f)
+#undef VSIP_IMPL_CML_TRANS_UNIT
+
+
+#define VSIP_IMPL_CML_COPY_UNIT(T, FCN, CML_FCN)   \
+  inline void                                      \
+  FCN(                                             \
+    T* a, ptrdiff_t rsa,                           \
+    T* z, ptrdiff_t rsz,                           \
+    size_t n)                                      \
+  {                                                \
+    typedef Scalar_of<T>::type CML_T;              \
+    CML_FCN(                                       \
+      reinterpret_cast<CML_T*>(a), rsa,            \
+      reinterpret_cast<CML_T*>(z), rsz,            \
+      n * (Is_complex<T>::value ? 2 : 1));         \
+  }
+
+VSIP_IMPL_CML_COPY_UNIT(float,          copy_unit, cml_vcopy_f)
+VSIP_IMPL_CML_COPY_UNIT(complex<float>, copy_unit, cml_vcopy_f)
+#undef VSIP_IMPL_CML_COPY_UNIT
+
+
+// These macros support split complex types only
+
+#define VSIP_IMPL_CML_TRANS_SPLIT(T, FCN, CML_FCN)     \
+  inline void                                          \
+  FCN(                                                 \
+    std::pair<T*, T*> a, ptrdiff_t rsa, ptrdiff_t csa, \
+    std::pair<T*, T*> z, ptrdiff_t rsz, ptrdiff_t csz, \
+    size_t m, size_t n)                                \
+  {                                                    \
+    CML_FCN(                                           \
+      a.first, a.second, rsa, csa,                     \
+      z.first, z.second, rsz, csz,                     \
+      m, n );                                          \
+  }
+
+VSIP_IMPL_CML_TRANS_SPLIT(float, transpose, cml_zmtrans_f)
+#undef VSIP_IMPL_CML_TRANS_SPLIT
+
+
+#define VSIP_IMPL_CML_TRANS_UNIT_SPLIT(T, FCN, CML_FCN) \
+  inline void                                           \
+  FCN(                                                  \
+    std::pair<T*, T*> a, ptrdiff_t rsa,                 \
+    std::pair<T*, T*> z, ptrdiff_t rsz,                 \
+    size_t m, size_t n)                                 \
+  {                                                     \
+    CML_FCN(                                            \
+      a.first, a.second, rsa,                           \
+      z.first, z.second, rsz,                           \
+      m, n );                                           \
+  }
+
+VSIP_IMPL_CML_TRANS_UNIT_SPLIT(float, transpose_unit, cml_zmtrans1_f)
+#undef VSIP_IMPL_CML_TRANS_UNIT_SPLIT
+
+
+#define VSIP_IMPL_CML_COPY_UNIT_SPLIT(T, FCN, CML_FCN)  \
+  inline void                                           \
+  FCN(                                                  \
+    std::pair<T*, T*> a, ptrdiff_t rsa,                 \
+    std::pair<T*, T*> z, ptrdiff_t rsz,                 \
+    size_t n)                                           \
+  {                                                     \
+    CML_FCN(                                            \
+      a.first, rsa,                                     \
+      z.first, rsz,                                     \
+      n);                                               \
+    CML_FCN(                                            \
+      a.second, rsa,                                    \
+      z.second, rsz,                                    \
+      n);                                               \
+  }
+
+VSIP_IMPL_CML_COPY_UNIT_SPLIT(float, copy_unit, cml_vcopy_f)
+#undef VSIP_IMPL_CML_COPY_UNIT_SPLIT
+
+
+} // namespace vsip::impl::cml
+
+
+
+template <typename DstBlock,
+          typename SrcBlock>
+struct Serial_expr_evaluator<2, DstBlock, SrcBlock, Cml_tag>
+{
+  static char const* name()
+  {
+    char s = Type_equal<src_order_type, row2_type>::value ? 'r' : 'c';
+    char d = Type_equal<dst_order_type, row2_type>::value ? 'r' : 'c';
+    if      (s == 'r' && d == 'r')    return "Expr_Trans (rr copy)";
+    else if (s == 'r' && d == 'c')    return "Expr_Trans (rc trans)";
+    else if (s == 'c' && d == 'r')    return "Expr_Trans (cr trans)";
+    else /* (s == 'c' && d == 'c') */ return "Expr_Trans (cc copy)";
+  }
+
+  typedef typename DstBlock::value_type dst_value_type;
+  typedef typename SrcBlock::value_type src_value_type;
+
+  static bool const is_rhs_expr   = Is_expr_block<SrcBlock>::value;
+
+  static bool const is_rhs_simple =
+    Is_simple_distributed_block<SrcBlock>::value;
+
+  static bool const is_lhs_split  = Is_split_block<DstBlock>::value;
+  static bool const is_rhs_split  = Is_split_block<SrcBlock>::value;
+
+  static int const  lhs_cost      = Ext_data_cost<DstBlock>::value;
+  static int const  rhs_cost      = Ext_data_cost<SrcBlock>::value;
+
+  typedef typename Block_layout<SrcBlock>::order_type src_order_type;
+  typedef typename Block_layout<DstBlock>::order_type dst_order_type;
+
+  static bool const ct_valid = 
+    // check that CML supports this data type and/or layout
+    cml::Cml_supports_block<SrcBlock>::valid &&
+    cml::Cml_supports_block<DstBlock>::valid &&
+    // check that types are equal
+    Type_equal<src_value_type, dst_value_type>::value &&
+    // check that the source block is not an expression
+    !is_rhs_expr &&
+    // check that direct access is supported
+    lhs_cost == 0 && rhs_cost == 0 &&
+    // check complex layout is consistent
+    is_lhs_split == is_rhs_split;
+
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  { 
+    bool rt = true;
+
+    // If performing a copy, both source and destination blocks
+    // must be unit stride.
+    if (Type_equal<src_order_type, dst_order_type>::value)
+    {
+      Ext_data<DstBlock> dst_ext(dst, SYNC_OUT);
+      Ext_data<SrcBlock> src_ext(src, SYNC_IN);
+
+      dimension_type const s_dim1 = src_order_type::impl_dim1;
+      dimension_type const d_dim1 = src_order_type::impl_dim1;
+
+      if (dst_ext.stride(d_dim1) != 1 || src_ext.stride(s_dim1) != 1)
+        rt = false;
+    }
+
+    return rt; 
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src, row2_type, row2_type)
+  {
+    vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
+    vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
+
+    if (dst_ext.stride(1) == 1 && src_ext.stride(1) == 1)
+    {
+      assert(dst_ext.stride(0) == dst.size(2, 1));
+      assert(src_ext.stride(0) == src.size(2, 1));
+
+      cml::copy_unit(
+        src_ext.data(), 1,
+        dst_ext.data(), 1,
+        dst.size(2, 0) * dst.size(2, 1) );
+    }
+    else
+      assert(0);
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src, col2_type, col2_type)
+  {
+    vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
+    vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
+
+    if (dst_ext.stride(0) == 1 && src_ext.stride(0) == 1)
+    {
+      assert(dst_ext.stride(1) == dst.size(2, 0));
+      assert(src_ext.stride(1) == src.size(2, 0));
+
+      cml::copy_unit(
+        src_ext.data(), 1,
+        dst_ext.data(), 1,
+        dst.size(2, 0) * dst.size(2, 1) );
+    }
+    else
+      assert(0);
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src, col2_type, row2_type)
+  {
+    vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
+    vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
+
+    if (dst_ext.stride(0) == 1 && src_ext.stride(1) == 1)
+    {
+      cml::transpose_unit(
+        src_ext.data(), src_ext.stride(0),
+        dst_ext.data(), dst_ext.stride(1),
+        dst.size(2, 1), dst.size(2, 0));
+    }
+    else
+    {
+      cml::transpose(
+        src_ext.data(), src_ext.stride(0), src_ext.stride(1),
+        dst_ext.data(), dst_ext.stride(1), dst_ext.stride(0),
+        dst.size(2, 0), dst.size(2, 1));
+    }
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src, row2_type, col2_type)
+  {
+    vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
+    vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
+
+    if (dst_ext.stride(1) == 1 && src_ext.stride(0) == 1)
+    {
+      cml::transpose_unit(
+        src_ext.data(), src_ext.stride(1),
+        dst_ext.data(), dst_ext.stride(0),
+        dst.size(2, 0), dst.size(2, 1));
+    }
+    else
+    {
+      cml::transpose(
+        src_ext.data(), src_ext.stride(1), src_ext.stride(0),
+        dst_ext.data(), dst_ext.stride(0), dst_ext.stride(1),
+        dst.size(2, 0), dst.size(2, 1));
+    }
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    exec(dst, src, dst_order_type(), src_order_type());
+  }
+  
+};
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_CBE_CML_TRANSPOSE_HPP
Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 210310)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -4,7 +4,7 @@
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    vsip/opt/diag/eval_vcmp.hpp
+/** @file    vsip/opt/diag/eval.hpp
     @author  Jules Bergmann
     @date    2006-10-26
     @brief   VSIPL++ Library: Diagnostics for evaluation.
@@ -82,6 +82,7 @@
 VSIP_IMPL_DISPATCH_NAME(Transpose_tag)
 VSIP_IMPL_DISPATCH_NAME(Mercury_sal_tag)
 VSIP_IMPL_DISPATCH_NAME(Cbe_sdk_tag)
+VSIP_IMPL_DISPATCH_NAME(Cml_tag)
 VSIP_IMPL_DISPATCH_NAME(Dense_expr_tag)
 VSIP_IMPL_DISPATCH_NAME(Copy_tag)
 VSIP_IMPL_DISPATCH_NAME(Op_expr_tag)
@@ -262,7 +263,52 @@
 };
 
 
+// Specialization for Cml_tag
 
+template <typename       DstBlockT,
+          typename       SrcBlockT>
+struct See_summary<2, Cml_tag, DstBlockT, SrcBlockT>
+{
+  typedef Cml_tag Tag;
+  static dimension_type const Dim = 2;
+
+  static void exec(
+    DstBlockT&       dst,
+    SrcBlockT const& src)
+  {
+    using std::cout;
+    using std::setw;
+    using std::endl;
+
+    typedef Serial_expr_evaluator<Dim, DstBlockT, SrcBlockT, Tag>
+      see_type;
+
+    bool rt_valid = Check_rt_valid<see_type, DstBlockT, SrcBlockT>
+      ::rt_valid(dst, src);
+
+    cout << "  - " << setw(20) << Dispatch_name<Tag>::name()
+	 << "  ct: " << setw(5) << (see_type::ct_valid ? "true" : "false")
+	 << "  rt: " << setw(5) << (rt_valid ? "true" : "false");
+
+    if (see_type::ct_valid)
+    {
+      char const* name = Check_rt_valid<see_type, DstBlockT, SrcBlockT>
+	::name();
+      cout << "  (" << name << ")";
+    }
+
+    cout << " ["
+	 << see_type::is_rhs_expr << ", "
+	 << see_type::lhs_cost << ", "
+	 << see_type::rhs_cost << ", "
+	 << see_type::is_rhs_split << ", "
+	 << see_type::is_rhs_split << "]";
+    cout << endl;
+  }
+};
+
+
+
 // See_summary specialization for Mdim_expr
 
 template <dimension_type Dim,
Index: src/vsip/opt/expr/serial_dispatch.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch.hpp	(revision 210310)
+++ src/vsip/opt/expr/serial_dispatch.hpp	(working copy)
@@ -40,6 +40,7 @@
 #include <vsip/opt/sal/bindings.hpp>
 #endif
 #ifdef VSIP_IMPL_CBE_SDK
+#include <vsip/opt/cbe/cml/transpose.hpp>
 #include <vsip/opt/cbe/ppu/bindings.hpp>
 #include <vsip/opt/cbe/ppu/eval_fastconv.hpp>
 #endif
Index: src/vsip/opt/expr/serial_dispatch_fwd.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch_fwd.hpp	(revision 210310)
+++ src/vsip/opt/expr/serial_dispatch_fwd.hpp	(working copy)
@@ -41,6 +41,7 @@
 /// Note that the VSIP_IMPL_TAG_LIST macro will include its own comma.
 
 typedef Make_type_list<Intel_ipp_tag,
+                       Cml_tag,
 		       Transpose_tag,
                        Mercury_sal_tag,
                        Cbe_sdk_tag,
