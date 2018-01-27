Index: ChangeLog
===================================================================
--- ChangeLog	(revision 156837)
+++ ChangeLog	(working copy)
@@ -1,3 +1,35 @@
+2006-12-07  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/cvsip/solver_lu.hpp (Is_lud_impl_avail): Specialize
+	  for types supported by CVSIP BE.
+	* src/vsip/core/cvsip/solver_cholesky.hpp (Is_chold_immpl_avail):
+	  Specialize for types supported by CVSIP BE.
+	* src/vsip/core/cvsip/solver_qr.hpp (Is_qrd_immpl_avail):
+	  Specialize for types supported by CVSIP BE.
+	  Fix member initializer list order to match class decl.
+	* src/vsip/core/cvsip/cvsip.hpp: Revert back to VSIP_IMPL_CVSIP_HAVE
+	  macros.
+	
+	* src/vsip/core/coverage.hpp (VSIP_IMPL_COVER_TAG): New macro for
+	  coverage of ImplTags.
+	* src/vsip/core/solver/lu.hpp: Use VSIP_IMPL_COVER_TAG.
+	* src/vsip/core/solver/cholesky.hpp: Likewise.
+	* src/vsip/core/solver/qr.hpp: Likewise.
+	
+	* src/vsip/core/static_assert.hpp (Compile_time_assert_msg):
+	  Variant of Compile_time_assert that takes an error "message" in
+	  the form of a type.
+	* src/vsip/core/cvsip/conv.hpp: Use impl_tags.hpp.  Add compile-time
+	  checking for types not supported by BE.
+	
+	* src/vsip/core/impl_tags.hpp: New file, common decls for
+	  implementation tags.
+	* src/vsip/core/cvsip/corr.hpp: Use impl_tags.hpp.
+	* src/vsip/core/solver/common.hpp: Likewise.
+	* src/vsip/opt/general_dispatch.hpp: Likewise.
+	* src/vsip/opt/expr/serial_evaluator.hpp: Likewise.
+	  Change if logic so function always return.
+	
 2006-12-06  Jules Bergmann  <jules@codesourcery.com>
 
 	Reorganize extdata for ref-impl:
Index: src/vsip/core/coverage.hpp
===================================================================
--- src/vsip/core/coverage.hpp	(revision 156744)
+++ src/vsip/core/coverage.hpp	(working copy)
@@ -45,4 +45,11 @@
 #  define VSIP_IMPL_COVER_BLK(TYPE, BLK)
 #endif
 
+#if VSIP_IMPL_DO_COVERAGE
+#  define VSIP_IMPL_COVER_TAG(TYPE, TAG)				\
+     std::cout << "TAG," << TYPE << "," << typeid(TAG).name() << std::endl;
+#else
+#  define VSIP_IMPL_COVER_TAG(TYPE, TAG)
+#endif
+
 #endif // VSIP_CORE_COVERAGE_HPP
Index: src/vsip/core/cvsip/corr.hpp
===================================================================
--- src/vsip/core/cvsip/corr.hpp	(revision 156744)
+++ src/vsip/core/cvsip/corr.hpp	(working copy)
@@ -23,6 +23,7 @@
 #include <vsip/core/cvsip/block.hpp>
 #include <vsip/core/cvsip/view.hpp>
 #include <vsip/core/cvsip/common.hpp>
+#include <vsip/core/impl_tags.hpp>
 extern "C" {
 #include <vsip.h>
 }
@@ -36,8 +37,6 @@
 namespace impl
 {
 
-struct Cvsip_tag;
-
 namespace cvsip
 {
 
Index: src/vsip/core/cvsip/conv.hpp
===================================================================
--- src/vsip/core/cvsip/conv.hpp	(revision 156744)
+++ src/vsip/core/cvsip/conv.hpp	(working copy)
@@ -24,6 +24,7 @@
 #include <vsip/core/cvsip/block.hpp>
 #include <vsip/core/cvsip/view.hpp>
 #include <vsip/core/cvsip/common.hpp>
+#include <vsip/core/impl_tags.hpp>
 extern "C" {
 #include <vsip.h>
 }
@@ -36,16 +37,19 @@
 {
 namespace impl
 {
-struct Cvsip_tag;
 
 namespace cvsip
 {
-template <dimension_type D, typename T> struct Conv_traits;
 
+template <dimension_type D, typename T> struct Conv_traits
+{ static bool const valid = false; };
+
 #if HAVE_VSIP_CONV1D_CREATE_F == 1
 template <>
 struct Conv_traits<1, float>
 {
+  static bool const valid = true;
+
   typedef vsip_conv1d_f conv_type;
   typedef vsip_vview_f view_type;
 
@@ -71,6 +75,8 @@
 template <>
 struct Conv_traits<2, float>
 {
+  static bool const valid = true;
+
   typedef vsip_conv2d_f conv_type;
   typedef vsip_mview_f view_type;
 
@@ -96,6 +102,8 @@
 template <>
 struct Conv_traits<1, double>
 {
+  static bool const valid = true;
+
   typedef vsip_conv1d_d conv_type;
   typedef vsip_vview_d view_type;
 
@@ -121,6 +129,8 @@
 template <>
 struct Conv_traits<2, double>
 {
+  static bool const valid = true;
+
   typedef vsip_conv2d_d conv_type;
   typedef vsip_mview_d view_type;
 
@@ -177,7 +187,7 @@
   Domain<D> output_size_;
   length_type decimation_;
 };
-}
+} // namespace vsip::impl::cvsip
 
 #if HAVE_VSIP_CONV1D_CREATE_F == 1
 template <>
@@ -208,6 +218,13 @@
 };
 #endif
 
+// Bogus type name to encapsulate error message.
+
+template <typename T>
+struct Conv_cvsip_backend_does_not_support_type;
+
+
+
 template <symmetry_type       S,
 	  support_region_type R,
 	  typename            T,
@@ -215,6 +232,8 @@
           alg_hint_type       H>
 class Convolution_impl<const_Vector, S, R, T, N, H, Cvsip_tag>
   : public cvsip::Convolution_impl<1, T, S, R>
+  , Compile_time_assert_msg<cvsip::Conv_traits<1, T>::valid,
+			    Conv_cvsip_backend_does_not_support_type<T> >
 {
   typedef cvsip::Conv_traits<1, T> traits;
 
@@ -259,6 +278,8 @@
           alg_hint_type       H>
 class Convolution_impl<const_Matrix, S, R, T, N, H, Cvsip_tag>
   : public cvsip::Convolution_impl<2, T, S, R>
+  , Compile_time_assert_msg<cvsip::Conv_traits<2, T>::valid,
+			    Conv_cvsip_backend_does_not_support_type<T> >
 {
   typedef cvsip::Conv_traits<2, T> traits;
 public:
Index: src/vsip/core/cvsip/solver_lu.hpp
===================================================================
--- src/vsip/core/cvsip/solver_lu.hpp	(revision 156744)
+++ src/vsip/core/cvsip/solver_lu.hpp	(working copy)
@@ -79,16 +79,21 @@
   cvsip::Cvsip_lud<T>        cvsip_lud_;
 };
 
-} // namespace vsip::impl
 
 
+// The CVSIP LU solver supports all CVSIP types.
+template <typename T>
+struct Is_lud_impl_avail<Cvsip_tag, T>
+{
+  static bool const value = cvsip::Cvsip_traits<T>::valid;
+};
+
+
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
 
-namespace impl
-{
-
 template <typename T>
 Lud_impl<T, Cvsip_tag>::Lud_impl(
   length_type length
Index: src/vsip/core/cvsip/solver_cholesky.hpp
===================================================================
--- src/vsip/core/cvsip/solver_cholesky.hpp	(revision 156744)
+++ src/vsip/core/cvsip/solver_cholesky.hpp	(working copy)
@@ -83,9 +83,21 @@
   Matrix<T, data_block_type> data_;	// Factorized Cholesky matrix (A)
   cvsip::View<2,T,true>      cvsip_data_;
   cvsip::Cvsip_chol<T>       cvsip_chol_;
+};
 
+
+
+// The CVSIP Cholesky solver supports all CVSIP types.
+
+template <typename T>
+struct Is_chold_impl_avail<Cvsip_tag, T>
+{
+  static bool const value = cvsip::Cvsip_traits<T>::valid;
 };
 
+
+
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: src/vsip/core/cvsip/solver_qr.hpp
===================================================================
--- src/vsip/core/cvsip/solver_qr.hpp	(revision 156744)
+++ src/vsip/core/cvsip/solver_qr.hpp	(working copy)
@@ -109,6 +109,16 @@
 
 
 
+// The CVSIP QR solver supports all CVSIP types.
+
+template <typename T>
+struct Is_qrd_impl_avail<Cvsip_tag, T>
+{
+  static bool const value = cvsip::Cvsip_traits<T>::valid;
+};
+
+
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -125,8 +135,8 @@
     n_          (cols),
     st_         (st),
     data_       (m_, n_),
-    cvsip_qr_   (m_, n_, cvsip::get_vsip_st(st_)),
-    cvsip_data_ (data_.block().impl_data(), m_, n_,true) 
+    cvsip_data_ (data_.block().impl_data(), m_, n_,true),
+    cvsip_qr_   (m_, n_, cvsip::get_vsip_st(st_))
 {
   assert(m_ > 0 && n_ > 0 && m_ >= n_);
   assert(st_ == qrd_nosaveq || st_ == qrd_saveq || st_ == qrd_saveq1);
@@ -143,8 +153,8 @@
     n_          (qr.n_),
     st_         (qr.st_),
     data_       (m_, n_),
-    cvsip_qr_   (m_, n_, cvsip::get_vsip_st(st_)),
-    cvsip_data_ (data_.block().impl_data(), m_, n_,true) 
+    cvsip_data_ (data_.block().impl_data(), m_, n_,true),
+    cvsip_qr_   (m_, n_, cvsip::get_vsip_st(st_))
 {
   data_ = qr.data_;
 }
Index: src/vsip/core/cvsip/cvsip.hpp
===================================================================
--- src/vsip/core/cvsip/cvsip.hpp	(revision 156744)
+++ src/vsip/core/cvsip/cvsip.hpp	(working copy)
@@ -30,7 +30,7 @@
     static bool const valid = false;
   };
 
-#if VSIP_IMPL_CVSIP_HAS_FLOAT
+#ifdef VSIP_IMPL_CVSIP_HAVE_FLOAT
   template<> struct Cvsip_traits<float>
   {
     typedef vsip_mview_f        mview_type;
@@ -52,7 +52,7 @@
   };
 #endif
 
-#if VSIP_IMPL_CVSIP_HAS_DOUBLE
+#ifdef VSIP_IMPL_CVSIP_HAVE_DOUBLE
   template<> struct Cvsip_traits<double>
   {
     typedef vsip_mview_d        mview_type;
@@ -228,7 +228,7 @@
  * Function declarations
 ******************************************************************************/
 
-#if VSIP_IMPL_CVSIP_HAS_FLOAT
+#ifdef VSIP_IMPL_CVSIP_HAVE_FLOAT
 VSIP_IMPL_CVSIP_BLOCKBIND(vsip_block_f, float, vsip_scalar_f,  vsip_blockbind_f)
 VSIP_IMPL_CVSIP_CBLOCKBIND(vsip_cblock_f,float, vsip_scalar_f,vsip_cblockbind_f)
 VSIP_IMPL_CVSIP_MBIND(vsip_mview_f,  vsip_block_f,  vsip_mbind_f)
@@ -274,7 +274,7 @@
 VSIP_IMPL_CVSIP_CHOLD_DESTROY(vsip_cchol_f,vsip_cchold_destroy_f)
 #endif
 
-#if VSIP_IMPL_CVSIP_HAS_DOUBLE
+#ifdef VSIP_IMPL_CVSIP_HAVE_DOUBLE
 VSIP_IMPL_CVSIP_BLOCKBIND(vsip_block_d, double,vsip_scalar_d,  vsip_blockbind_d)
 VSIP_IMPL_CVSIP_CBLOCKBIND(vsip_cblock_d,double,vsip_scalar_d,vsip_cblockbind_d)
 VSIP_IMPL_CVSIP_MBIND(vsip_mview_d,  vsip_block_d,  vsip_mbind_d)
Index: src/vsip/core/static_assert.hpp
===================================================================
--- src/vsip/core/static_assert.hpp	(revision 156744)
+++ src/vsip/core/static_assert.hpp	(working copy)
@@ -64,6 +64,20 @@
 
 
 
+/// Compile_time_assert_msg
+
+template <bool B,
+	  typename MsgT>
+struct Compile_time_assert_msg;
+
+template <typename MsgT>
+struct Compile_time_assert_msg<true, MsgT>
+{
+  static void test() {}
+};
+
+
+
 /// Assert_unsigned<T> checks that type T is an unsigned at compile-time.
 
 template<class T> 
Index: src/vsip/core/solver/lu.hpp
===================================================================
--- src/vsip/core/solver/lu.hpp	(revision 156744)
+++ src/vsip/core/solver/lu.hpp	(working copy)
@@ -100,15 +100,15 @@
 class lud<T, by_reference>
   : public impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::use_type>
 {
-  typedef impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::use_type>
-	  base_type;
+  typedef typename impl::Choose_lud_impl<T>::use_type use_type;
+  typedef impl::Lud_impl<T, use_type> base_type;
 
   // Constructors, copies, assignments, and destructors.
 public:
   lud(length_type length)
     VSIP_THROW((std::bad_alloc))
       : base_type(length)
-    {}
+    { VSIP_IMPL_COVER_TAG("lud", use_type); }
 
   ~lud() VSIP_NOTHROW {}
 
Index: src/vsip/core/solver/cholesky.hpp
===================================================================
--- src/vsip/core/solver/cholesky.hpp	(revision 156837)
+++ src/vsip/core/solver/cholesky.hpp	(working copy)
@@ -95,15 +95,15 @@
 class chold<T, by_reference>
   : public impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::use_type>
 {
-  typedef impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::use_type>
-    base_type;
+  typedef typename impl::Choose_chold_impl<T>::use_type use_type;
+  typedef impl::Chold_impl<T, use_type> base_type;
 
   // Constructors, copies, assignments, and destructors.
 public:
   chold(mat_uplo uplo, length_type length)
     VSIP_THROW((std::bad_alloc))
       : base_type(uplo, length)
-    {}
+    { VSIP_IMPL_COVER_TAG("chold", use_type); }
 
   ~chold() VSIP_NOTHROW {}
 
Index: src/vsip/core/solver/qr.hpp
===================================================================
--- src/vsip/core/solver/qr.hpp	(revision 156837)
+++ src/vsip/core/solver/qr.hpp	(working copy)
@@ -101,15 +101,15 @@
 class qrd<T, by_reference>
   : public impl::Qrd_impl<T,true,typename impl::Choose_qrd_impl<T>::use_type>
 {
-  typedef impl::Qrd_impl<T,true,typename impl::Choose_qrd_impl<T>::use_type>
-    base_type;
+  typedef typename impl::Choose_qrd_impl<T>::use_type use_type;
+  typedef impl::Qrd_impl<T,true, use_type> base_type;
 
   // Constructors, copies, assignments, and destructors.
 public:
   qrd(length_type rows, length_type cols, storage_type st)
     VSIP_THROW((std::bad_alloc))
       : base_type(rows, cols, st)
-    {}
+    { VSIP_IMPL_COVER_TAG("qrd", use_type); }
 
   ~qrd() VSIP_NOTHROW {}
 
Index: src/vsip/core/solver/common.hpp
===================================================================
--- src/vsip/core/solver/common.hpp	(revision 156837)
+++ src/vsip/core/solver/common.hpp	(working copy)
@@ -10,6 +10,7 @@
 #ifndef VSIP_CORE_SOLVER_COMMON_HPP
 #define VSIP_CORE_SOLVER_COMMON_HPP
 
+#include <vsip/core/impl_tags.hpp>
 #include <vsip/core/type_list.hpp>
 
 namespace vsip
@@ -71,10 +72,6 @@
 
 
 
-// Implementation tags
-struct Lapack_tag;
-struct Cvsip_tag;
-
 // Error tags
 struct Error_no_solver_for_this_type;
 
Index: src/vsip/core/impl_tags.hpp
===================================================================
--- src/vsip/core/impl_tags.hpp	(revision 0)
+++ src/vsip/core/impl_tags.hpp	(revision 0)
@@ -0,0 +1,55 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/impl_tags.hpp
+    @author  Jules Bergmann
+    @date    2006-12-06
+    @brief   VSIPL++ Library: Implementation Tags.
+
+*/
+
+#ifndef VSIP_CORE_IMPL_TAGS_HPP
+#define VSIP_CORE_IMPL_TAGS_HPP
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
+// Implementation tags.
+//
+// Each implementation (generic, BLAS, IPP, etc) has a unique
+// implementation tag.
+//
+// Tags are shared by the different evaluators (Serial-expr_evaluator,
+// General_dispatch, and Dispatch).
+//
+// For the serial expression evaluator, these are placed in
+// LibraryTagList and determine the order in which expression
+// evaluators are tried.  (The order here approximates LibraryTagList)
+
+struct Simd_builtin_tag {};	// Builtin SIMD routines (non loop fusion)
+struct Intel_ipp_tag {};	// Intel IPP Library
+struct Transpose_tag {};	// Optimized Matrix Transpose
+struct Mercury_sal_tag {};	// Mercury SAL Library
+struct Dense_expr_tag {};	// Dense multi-dim expr reduction
+struct Copy_tag {};		// Optimized Copy
+struct Op_expr_tag {};		// Special expr handling (vmmul, etc)
+struct Simd_loop_fusion_tag {};	// SIMD Loop Fusion.
+struct Loop_fusion_tag {};	// Generic Loop Fusion (base case).
+
+struct Blas_tag {};		// BLAS implementation (ATLAS, MKL, etc)
+struct Lapack_tag {};		// LAPACK implementation (ATLAS, MKL, etc)
+struct Generic_tag {};		// Generic implementation.
+struct Parallel_tag {};		// Parallel implementation.
+struct Cvsip_tag {};		// C-VSIPL library.
+
+} // namespace vsip::impl
+} // namespace vsip
+
+
+#endif // VSIP_CORE_IMPL_TAGS_HPP
Index: src/vsip/opt/general_dispatch.hpp
===================================================================
--- src/vsip/opt/general_dispatch.hpp	(revision 156744)
+++ src/vsip/opt/general_dispatch.hpp	(working copy)
@@ -16,6 +16,7 @@
 
 #include <vsip/core/config.hpp>
 #include <vsip/core/type_list.hpp>
+#include <vsip/core/impl_tags.hpp>
 
 
 
@@ -42,20 +43,6 @@
 
 
 
-// Implementation Tags.
-//
-// Each implementation (generic, BLAS, IPP, etc) has a unique
-// implementation tag.
-
-struct Blas_tag;		// BLAS implementation (ATLAS, MKL, etc)
-struct Intel_ipp_tag;		// Intel IPP library.
-struct Generic_tag;		// Generic implementation.
-struct Parallel_tag;		// Parallel implementation.
-struct Mercury_sal_tag;		// Mercury SAL library.
-struct Cvsip_tag;		// C-VSIPL library.
-
-
-
 // Wrapper class to describe scalar return-type.
 
 template <typename T> struct Return_scalar {};
Index: src/vsip/opt/expr/serial_evaluator.hpp
===================================================================
--- src/vsip/opt/expr/serial_evaluator.hpp	(revision 156837)
+++ src/vsip/opt/expr/serial_evaluator.hpp	(working copy)
@@ -19,6 +19,7 @@
 #include <vsip/opt/fast_transpose.hpp>
 #include <vsip/core/adjust_layout.hpp>
 #include <vsip/core/coverage.hpp>
+#include <vsip/core/impl_tags.hpp>
 
 
 /***********************************************************************
@@ -30,20 +31,6 @@
 namespace impl
 {
 
-// Evaluator tags.  These are placed in LibraryTagList and
-// determine the order in which expression evaluators are tried.
-// (The order here approximates LibraryTagList)
-
-struct Simd_builtin_tag;	// Builtin SIMD routines (non loop fusion)
-struct Intel_ipp_tag;		// Intel IPP Library
-struct Transpose_tag;		// Optimized Matrix Transpose
-struct Mercury_sal_tag;		// Mercury SAL Library
-struct Dense_expr_tag;		// Dense multi-dim expr reduction
-struct Copy_tag;		// Optimized Copy
-struct Op_expr_tag;		// Special expr handling (vmmul, etc)
-struct Simd_loop_fusion_tag;	// SIMD Loop Fusion.
-struct Loop_fusion_tag;		// Generic Loop Fusion (base case).
-
 /// Serial_expr_evaluator template.
 /// This needs to be provided for each tag in the LibraryTagList.
 template <dimension_type Dim,
@@ -139,10 +126,10 @@
   {
     char s = Type_equal<src_order_type, row2_type>::value ? 'r' : 'c';
     char d = Type_equal<dst_order_type, row2_type>::value ? 'r' : 'c';
-    if      (s == 'r' && d == 'r') return "Expr_Trans (rr copy)";
-    else if (s == 'r' && d == 'c') return "Expr_Trans (rc trans)";
-    else if (s == 'c' && d == 'r') return "Expr_Trans (cr trans)";
-    else if (s == 'c' && d == 'c') return "Expr_Trans (cc copy)";
+    if      (s == 'r' && d == 'r')    return "Expr_Trans (rr copy)";
+    else if (s == 'r' && d == 'c')    return "Expr_Trans (rc trans)";
+    else if (s == 'c' && d == 'r')    return "Expr_Trans (cr trans)";
+    else /* (s == 'c' && d == 'c') */ return "Expr_Trans (cc copy)";
   }
 
   typedef typename DstBlock::value_type dst_value_type;
