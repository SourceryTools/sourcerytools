Index: ChangeLog
===================================================================
--- ChangeLog	(revision 156850)
+++ ChangeLog	(working copy)
@@ -1,3 +1,30 @@
+2006-12-11  Jules Bergmann  <jules@codesourcery.com>
+
+	C-VSIP reduction BE.
+	* src/vsip/core/cvsip/eval_reductions.hpp: New file.  Evaluators for
+	  performing reductions with C-VSIP.
+	* src/vsip/core/cvsip/eval_reductions_idx.hpp: New file.  Evaluators
+	  for performing index returning reductions with C-VSIP.
+	* src/vsip/core/reductions/reductions.hpp: Use C-VSIP reduction BE.
+	* src/vsip/core/reductions/reductions_idx.hpp: Use C-VSIP reduction
+	  BE.  Extend maxmgval and minmgval to work with non-complex
+	  views.
+	* src/vsip/core/cvsip/block.hpp (Block_traits): Add specializations
+	  for bool and int.
+	* src/vsip/core/cvsip/view.hpp (View_traits): Add specializations
+	  for <1,bool>, <1, int>, <2,bool>, <2, int>.
+	  (View): Add specializations for <1,bool> and <2,bool> that
+	  emulate admit/release by copy.
+	  (View_from_ext): New class, constructs View directly from
+	  Ext_data object.
+	* src/vsip/core/cvsip/convert_value.hpp: New file, conversions
+	  between C++ and C-VSIP types.
+	* src/vsip/opt/general_dispatch.hpp (operation tags, wrapper classes,
+	  Evaluator): Move decls that need to be visible in core to ...
+	* src/vsip/core/general_evaluator.hpp: New file, ... here.
+	* src/vsip/opt/extdata_local.hpp: Add support for auto-allocation
+	  of temporary storage.
+	
 2006-12-07  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/fft/workspace.hpp: Move to ...
Index: src/vsip/core/reductions/reductions.hpp
===================================================================
--- src/vsip/core/reductions/reductions.hpp	(revision 156744)
+++ src/vsip/core/reductions/reductions.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/core/reductions/reductions.hpp
     @author  Jules Bergmann
@@ -19,13 +19,19 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
-#include <vsip/opt/general_dispatch.hpp>
 #include <vsip/core/reductions/functors.hpp>
 #include <vsip/core/parallel/services.hpp>
-
-#ifdef VSIP_IMPL_HAVE_SAL
-#  include <vsip/opt/sal/eval_reductions.hpp>
+#include <vsip/core/general_evaluator.hpp>
+#include <vsip/core/impl_tags.hpp>
+#if VSIP_IMPL_HAVE_CVSIP
+#  include <vsip/core/cvsip/eval_reductions.hpp>
 #endif
+#if !VSIP_IMPL_REF_IMPL
+#  include <vsip/opt/general_dispatch.hpp>
+#  ifdef VSIP_IMPL_HAVE_SAL
+#    include <vsip/opt/sal/eval_reductions.hpp>
+#  endif
+#endif
 
 
 
@@ -348,6 +354,7 @@
   Parallel evaluators.
 ***********************************************************************/
 
+#if !VSIP_IMPL_REF_IMPL
 template <template <typename> class ReduceT,
           typename                  T,
 	  typename                  Block,
@@ -474,6 +481,7 @@
       r = l_r;
   }
 };
+#endif
 
 
 
@@ -489,15 +497,25 @@
 		order_type;
   typedef Int_type<ViewT::dim>                   dim_type;
 
+#if VSIP_IMPL_REF_IMPL
+  Evaluator<    Op_reduce<ReduceT>,
+                typename ReduceT<T>::result_type,
+		impl::Op_list_3<typename ViewT::block_type const&,
+		                order_type,
+                                Int_type<ViewT::dim> >,
+                Cvsip_tag>
+        ::exec(r, v.block(), order_type(), dim_type());
+#else
   impl::General_dispatch<
 		impl::Op_reduce<ReduceT>,
 		typename ReduceT<T>::result_type,
 		impl::Op_list_3<typename ViewT::block_type const&,
 		                order_type,
                                 Int_type<ViewT::dim> >,
-                typename Make_type_list<Parallel_tag, Mercury_sal_tag,
-                                        Generic_tag>::type>
+                typename Make_type_list<Parallel_tag, Cvsip_tag,
+		                        Mercury_sal_tag, Generic_tag>::type>
         ::exec(r, v.block(), order_type(), dim_type());
+#endif
 
   return r;
 }
Index: src/vsip/core/reductions/reductions_idx.hpp
===================================================================
--- src/vsip/core/reductions/reductions_idx.hpp	(revision 156744)
+++ src/vsip/core/reductions/reductions_idx.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/core/reductions/reductions_idx.hpp
     @author  Jules Bergmann
@@ -20,10 +20,14 @@
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
 #include <vsip/core/reductions/functors.hpp>
-
-#ifdef VSIP_IMPL_HAVE_SAL
-#  include <vsip/opt/sal/eval_reductions.hpp>
+#if VSIP_IMPL_HAVE_CVSIP
+#  include <vsip/core/cvsip/eval_reductions_idx.hpp>
 #endif
+#if !VSIP_IMPL_REF_IMPL
+#  ifdef VSIP_IMPL_HAVE_SAL
+#    include <vsip/opt/sal/eval_reductions.hpp>
+#  endif
+#endif
 
 
 
@@ -394,14 +398,25 @@
   typedef typename Block_layout<typename ViewT::block_type>::order_type
 		order_type;
 
+#if VSIP_IMPL_REF_IMPL
+  Evaluator<    Op_reduce_idx<ReduceT>,
+		typename ReduceT<T>::result_type,
+		impl::Op_list_3<typename ViewT::block_type const&,
+                                Index<ViewT::dim>&,
+                                order_type>,
+                Cvsip_tag>
+        ::exec(r, v.block(), idx, order_type());
+#else
   impl::General_dispatch<
 		impl::Op_reduce_idx<ReduceT>,
 		typename ReduceT<T>::result_type,
 		impl::Op_list_3<typename ViewT::block_type const&,
                                 Index<ViewT::dim>&,
                                 order_type>,
-                typename Make_type_list<Mercury_sal_tag, Generic_tag>::type>
+		typename Make_type_list<Cvsip_tag, Mercury_sal_tag,
+                                        Generic_tag>::type>
         ::exec(r, v.block(), idx, order_type());
+#endif
 
   return r;
 }
@@ -447,10 +462,10 @@
 template <typename                            T,
 	  template <typename, typename> class ViewT,
 	  typename                            BlockT>
-T
+typename impl::Scalar_of<T>::type
 maxmgval(
-   ViewT<complex<T>, BlockT>              v,
-   Index<ViewT<complex<T>, BlockT>::dim>& idx)
+   ViewT<T, BlockT>              v,
+   Index<ViewT<T, BlockT>::dim>& idx)
 VSIP_NOTHROW
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
@@ -462,10 +477,10 @@
 template <typename                            T,
 	  template <typename, typename> class ViewT,
 	  typename                            BlockT>
-T
+typename impl::Scalar_of<T>::type
 minmgval(
-   ViewT<complex<T>, BlockT>              v,
-   Index<ViewT<complex<T>, BlockT>::dim>& idx)
+   ViewT<T, BlockT>              v,
+   Index<ViewT<T, BlockT>::dim>& idx)
 VSIP_NOTHROW
 {
   typedef typename impl::Block_layout<BlockT>::order_type order_type;
Index: src/vsip/core/cvsip/eval_reductions_idx.hpp
===================================================================
--- src/vsip/core/cvsip/eval_reductions_idx.hpp	(revision 0)
+++ src/vsip/core/cvsip/eval_reductions_idx.hpp	(revision 0)
@@ -0,0 +1,175 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/cvsip/eval_reductions_idx.hpp
+    @author  Jules Bergmann
+    @date    2006-12-08
+    @brief   VSIPL++ Library: Reduction_idx functions using C-VSIP BE.
+	     [math.fns.reductidx].
+
+*/
+
+#ifndef VSIP_CORE_CVSIP_REDUCTIONS_IDX_HPP
+#define VSIP_CORE_CVSIP_REDUCTIONS_IDX_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+extern "C" {
+#include <vsip.h>
+}
+
+#include <vsip/core/general_evaluator.hpp>
+#include <vsip/core/impl_tags.hpp>
+#include <vsip/core/coverage.hpp>
+#include <vsip/core/static_assert.hpp>
+#include <vsip/opt/extdata_local.hpp>
+#include <vsip/core/cvsip/view.hpp>
+#include <vsip/core/cvsip/convert_value.hpp>
+
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
+namespace cvsip
+{
+
+template <template <typename> class ReduceT,
+	  dimension_type            Dim,
+	  typename                  T>
+struct Reduction_not_implemented_by_cvsip_backend;
+
+template <template <typename> class ReduceT,
+	  dimension_type            Dim,
+          typename                  T>
+struct Reduce_idx_class
+{
+  static bool const valid = false;
+
+  // Provide a dummy exec() function that generates a compile-time error.
+  //
+  // When used by the optimized implementation, checking of ct_valid
+  // will prevent this function from being called.
+  //
+  // When used by the reference implementation, since ct_valid is not
+  // used, this function will be instantiated if none of the specializations
+  // below apply.
+
+  template <typename CvsipViewT>
+  // static T exec(typename cvsip::View_traits<Dim, T>::view_type*, Index<Dim>&)
+  static T exec(CvsipViewT*, Index<Dim>&)
+  {
+    Compile_time_assert_msg<false,
+      Reduction_not_implemented_by_cvsip_backend<ReduceT, Dim, T> >::test();
+  }
+};
+
+
+
+#define VSIP_IMPL_CVSIP_RDX_IDX_RT(REDUCET, DIM, T, RT, CVSIP_FCN)	\
+template <>								\
+struct Reduce_idx_class<REDUCET, DIM, T>				\
+{									\
+  static bool const valid = true;					\
+  static RT exec(cvsip::View_traits<DIM, T>::view_type* view,		\
+		 Index<DIM>& idx)					\
+  {									\
+    VSIP_IMPL_COVER_FCN("cvsip_reduce_idx", CVSIP_FCN);			\
+    Convert_value<Index<DIM> >::cvsip_type v_idx;			\
+    RT rv = Convert_value<RT>::to_cpp(CVSIP_FCN(view, &v_idx));		\
+    idx = Convert_value<Index<DIM> >::to_cpp(v_idx);			\
+    return rv;								\
+  }									\
+};
+
+#define VSIP_IMPL_CVSIP_RDX_IDX(REDUCET, DIM, T, CVSIP_FCN)		\
+  VSIP_IMPL_CVSIP_RDX_IDX_RT(REDUCET, DIM, T, T, CVSIP_FCN)
+
+// Reductions marked by [*] are not implemented in TVCPP.
+
+VSIP_IMPL_CVSIP_RDX_IDX(Max_value, 1,  float, vsip_vmaxval_f)
+VSIP_IMPL_CVSIP_RDX_IDX(Max_value, 1, double, vsip_vmaxval_d)
+
+VSIP_IMPL_CVSIP_RDX_IDX(Max_value, 2,  float, vsip_mmaxval_f)
+VSIP_IMPL_CVSIP_RDX_IDX(Max_value, 2, double, vsip_mmaxval_d)
+
+VSIP_IMPL_CVSIP_RDX_IDX(Min_value, 1,  float, vsip_vminval_f)
+VSIP_IMPL_CVSIP_RDX_IDX(Min_value, 1, double, vsip_vminval_d)
+
+VSIP_IMPL_CVSIP_RDX_IDX(Min_value, 2,  float, vsip_mminval_f)
+VSIP_IMPL_CVSIP_RDX_IDX(Min_value, 2, double, vsip_mminval_d)
+
+VSIP_IMPL_CVSIP_RDX_IDX(Max_mag_value, 1,  float, vsip_vmaxmgval_f)
+VSIP_IMPL_CVSIP_RDX_IDX(Max_mag_value, 1, double, vsip_vmaxmgval_d)
+
+VSIP_IMPL_CVSIP_RDX_IDX(Max_mag_value, 2,  float, vsip_mmaxmgval_f)
+VSIP_IMPL_CVSIP_RDX_IDX(Max_mag_value, 2, double, vsip_mmaxmgval_d)
+
+VSIP_IMPL_CVSIP_RDX_IDX(Min_mag_value, 1,  float, vsip_vminmgval_f)
+VSIP_IMPL_CVSIP_RDX_IDX(Min_mag_value, 1, double, vsip_vminmgval_d)
+
+VSIP_IMPL_CVSIP_RDX_IDX(Min_mag_value, 2,  float, vsip_mminmgval_f)
+VSIP_IMPL_CVSIP_RDX_IDX(Min_mag_value, 2, double, vsip_mminmgval_d)
+
+
+VSIP_IMPL_CVSIP_RDX_IDX_RT(Min_magsq_value,1, complex<float>,float,vsip_vcminmgsqval_f)
+VSIP_IMPL_CVSIP_RDX_IDX_RT(Min_magsq_value,1, complex<double>,double,vsip_vcminmgsqval_d)
+
+VSIP_IMPL_CVSIP_RDX_IDX_RT(Min_magsq_value,2, complex<float>,float,vsip_mcminmgsqval_f)
+VSIP_IMPL_CVSIP_RDX_IDX_RT(Min_magsq_value,2, complex<double>,double,vsip_mcminmgsqval_d)
+
+
+VSIP_IMPL_CVSIP_RDX_IDX_RT(Max_magsq_value,1, complex<float>,float,vsip_vcmaxmgsqval_f)
+VSIP_IMPL_CVSIP_RDX_IDX_RT(Max_magsq_value,1, complex<double>,double,vsip_vcmaxmgsqval_d)
+
+VSIP_IMPL_CVSIP_RDX_IDX_RT(Max_magsq_value,2, complex<float>,float,vsip_mcmaxmgsqval_f)
+VSIP_IMPL_CVSIP_RDX_IDX_RT(Max_magsq_value,2, complex<double>,double,vsip_mcmaxmgsqval_d)
+
+} // namespace vsip::impl::cvsip
+
+
+
+/***********************************************************************
+  Evaluators.
+***********************************************************************/
+
+template <template <typename> class ReduceT,
+          typename                  T,
+	  typename                  Block,
+	  typename                  OrderT,
+	  dimension_type            Dim>
+struct Evaluator<Op_reduce_idx<ReduceT>, T,
+		 Op_list_3<Block const&, Index<Dim>&, OrderT>,
+		 Cvsip_tag>
+{
+  typedef typename Block::value_type value_type;
+
+  static bool const ct_valid =
+    cvsip::Reduce_idx_class<ReduceT, Dim, value_type>::valid;
+
+  static bool rt_valid(T&, Block const&, Index<Dim>&, OrderT)
+  { return true; }
+
+  static void exec(T& r, Block const& blk, Index<Dim>& idx, OrderT)
+  {
+    Ext_data_local<Block> ext(blk, SYNC_IN);
+    cvsip::View_from_ext<Dim, value_type> view(ext);
+    
+    r = cvsip::Reduce_idx_class<ReduceT, Dim, value_type>::exec(
+		view.view_.ptr(),
+		idx);
+  }
+};
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif
Index: src/vsip/core/cvsip/block.hpp
===================================================================
--- src/vsip/core/cvsip/block.hpp	(revision 156837)
+++ src/vsip/core/cvsip/block.hpp	(working copy)
@@ -33,6 +33,53 @@
 
 template <typename T> struct Block_traits;
 
+template <>
+struct Block_traits<bool>
+{
+  typedef bool value_type;
+  typedef vsip_block_bl block_type;
+
+  static block_type* create(size_t s)
+  {
+    block_type* b = vsip_blockcreate_bl(s, VSIP_MEM_NONE);
+    if (!b) VSIP_THROW(std::bad_alloc());
+    return b;
+  }
+  static void destroy(block_type* b)
+  { vsip_blockdestroy_bl(b);}
+
+  // C-VSIPL and C++ do not agree on the bool type, so we're forced
+  // to manually copy data.  Hence, we don't need bind, admit, or release.
+};
+
+template <>
+struct Block_traits<int>
+{
+  typedef int value_type;
+  typedef vsip_block_i block_type;
+
+  static block_type* create(size_t s)
+  {
+    block_type* b = vsip_blockcreate_i(s, VSIP_MEM_NONE);
+    if (!b) VSIP_THROW(std::bad_alloc());
+    return b;
+  }
+  static void destroy(block_type* b)
+  { vsip_blockdestroy_i(b);}
+  static block_type* bind(value_type* d, size_t s)
+  {
+    block_type* b = vsip_blockbind_i(d, s, VSIP_MEM_NONE);
+    if (!b) VSIP_THROW(std::bad_alloc());
+    return b;
+  }
+  static void rebind(block_type* b, value_type* d)
+  { (void) vsip_blockrebind_i(b, d);}
+  static void admit(block_type* b, vsip_scalar_bl s)
+  { (void) vsip_blockadmit_i(b, s);}
+  static void release(block_type* b, vsip_scalar_bl s)
+  { (void) vsip_blockrelease_i(b, s);}  
+};
+
 #if VSIP_IMPL_CVSIP_HAVE_FLOAT
 template <>
 struct Block_traits<float>
Index: src/vsip/core/cvsip/view.hpp
===================================================================
--- src/vsip/core/cvsip/view.hpp	(revision 156837)
+++ src/vsip/core/cvsip/view.hpp	(working copy)
@@ -19,6 +19,9 @@
 #include <vsip/core/cvsip/block.hpp>
 extern "C" {
 #include <vsip.h>
+
+// TVCPP defines, but does not declare, the following:
+void vsip_vcopy_bl_bl(vsip_vview_bl const*, vsip_vview_bl const*); 
 }
 /***********************************************************************
   Declarations
@@ -30,8 +33,88 @@
 {
 namespace cvsip
 {
+
+// Traits for C-VSIP views.
+//
+// [1] C-VSIP implementations may not be orthogonal.  Functions
+//     below commented out with a '[1]' label are not implemented
+//     in TVCPP.
+
 template <dimension_type D, typename T> struct View_traits;
 
+template <>
+struct View_traits<1, bool>
+{
+  typedef bool value_type;
+  typedef vsip_block_bl block_type;
+  typedef vsip_vview_bl view_type;
+
+  static view_type* create(vsip_length l)
+  {
+    view_type* v = vsip_vcreate_bl(l, VSIP_MEM_NONE);
+    if (!v) VSIP_THROW(std::bad_alloc());
+    return v;
+  }
+  static view_type* bind(block_type const* b,
+                         vsip_offset o, vsip_stride s, vsip_length l)
+  {
+    view_type* v = vsip_vbind_bl(b, o, s, l);
+    if (!v) VSIP_THROW(std::bad_alloc());
+    return v;
+  }
+  static view_type* clone(view_type* v) 
+  {
+    view_type* c = vsip_vcloneview_bl(v);
+    if (!c) VSIP_THROW(std::bad_alloc());
+    return c;
+  }
+  static void destroy(view_type* v) { vsip_valldestroy_bl(v);}
+  static void copy(view_type* s, view_type* d) { vsip_vcopy_bl_bl(s, d);}
+  static block_type* block(view_type* v) { return vsip_vgetblock_bl(v);}
+  static vsip_offset offset(view_type* v) { return vsip_vgetoffset_bl(v);}
+  static vsip_stride stride(view_type* v) { return vsip_vgetstride_bl(v);}
+  static vsip_length length(view_type* v) { return vsip_vgetlength_bl(v);}
+
+  static bool get(view_type* v, index_type i)
+    { return (bool)vsip_vget_bl(v, i); }
+  static void put(view_type* v, index_type i, bool value)
+    { vsip_vput_bl(v, i, (vsip_scalar_bl)value); }
+};
+
+template <>
+struct View_traits<1, int>
+{
+  typedef int value_type;
+  typedef vsip_block_i block_type;
+  typedef vsip_vview_i view_type;
+
+  static view_type* create(vsip_length l)
+  {
+    view_type* v = vsip_vcreate_i(l, VSIP_MEM_NONE);
+    if (!v) VSIP_THROW(std::bad_alloc());
+    return v;
+  }
+  static view_type* bind(block_type const* b,
+                         vsip_offset o, vsip_stride s, vsip_length l)
+  {
+    view_type* v = vsip_vbind_i(b, o, s, l);
+    if (!v) VSIP_THROW(std::bad_alloc());
+    return v;
+  }
+  static view_type* clone(view_type* v) 
+  {
+    view_type* c = vsip_vcloneview_i(v);
+    if (!c) VSIP_THROW(std::bad_alloc());
+    return c;
+  }
+  static void destroy(view_type* v) { vsip_valldestroy_i(v);}
+  static void copy(view_type* s, view_type* d) { vsip_vcopy_i_i(s, d);}
+  static block_type* block(view_type* v) { return vsip_vgetblock_i(v);}
+  static vsip_offset offset(view_type* v) { return vsip_vgetoffset_i(v);}
+  static vsip_stride stride(view_type* v) { return vsip_vgetstride_i(v);}
+  static vsip_length length(view_type* v) { return vsip_vgetlength_i(v);}
+};
+
 #if VSIP_IMPL_CVSIP_HAVE_FLOAT
 
 template <>
@@ -173,7 +256,89 @@
   static vsip_length length(view_type *v) { return vsip_cvgetlength_d(v);}
 };
 
+
+
 template <>
+struct View_traits<2, bool>
+{
+  typedef bool value_type;
+  typedef vsip_block_bl block_type;
+  typedef vsip_mview_bl view_type;
+
+  static view_type* create(vsip_length r, vsip_length c, bool row_major)
+  {
+    view_type* v = vsip_mcreate_bl(r, c, row_major ? VSIP_ROW : VSIP_COL,
+                                  VSIP_MEM_NONE);
+    if (!v) VSIP_THROW(std::bad_alloc());
+    return v;
+  }
+  static view_type* bind(block_type const* b, vsip_offset o,
+                         vsip_stride s_r, vsip_length rows,
+                         vsip_stride s_c, vsip_length cols)
+  {
+    view_type* v = vsip_mbind_bl(b, o, s_r, rows, s_c, cols);
+    if (!v) VSIP_THROW(std::bad_alloc());
+    return v;
+  }
+  static view_type* clone(view_type* v)
+  {
+    view_type* c = vsip_mcloneview_bl(v);
+    if (!c) VSIP_THROW(std::bad_alloc());
+    return c;
+  }
+  static void destroy(view_type* v) { vsip_malldestroy_bl(v);}
+  static void copy(view_type* s, view_type* d) { vsip_mcopy_bl_bl(s, d);}
+  static block_type* block(view_type* v) { return vsip_mgetblock_bl(v);}
+  static vsip_offset offset(view_type* v) { return vsip_mgetoffset_bl(v);}
+  static vsip_stride row_stride(view_type* v) { return vsip_mgetrowstride_bl(v);}
+  static vsip_length row_length(view_type* v) { return vsip_mgetrowlength_bl(v);}
+  static vsip_stride col_stride(view_type* v) { return vsip_mgetcolstride_bl(v);}
+  static vsip_length col_length(view_type* v) { return vsip_mgetcollength_bl(v);}
+  static bool get(view_type* v, index_type r, index_type c)
+    { return (bool)vsip_mget_bl(v, r, c); }
+  static void put(view_type* v, index_type r, index_type c, bool value)
+    { vsip_mput_bl(v, r, c, (vsip_scalar_bl)value); }
+};
+
+template <>
+struct View_traits<2, int>
+{
+  typedef int value_type;
+  typedef vsip_block_i block_type;
+  typedef vsip_mview_i view_type;
+
+  static view_type* create(vsip_length r, vsip_length c, bool row_major)
+  {
+    view_type* v = vsip_mcreate_i(r, c, row_major ? VSIP_ROW : VSIP_COL,
+                                  VSIP_MEM_NONE);
+    if (!v) VSIP_THROW(std::bad_alloc());
+    return v;
+  }
+  static view_type* bind(block_type const* b, vsip_offset o,
+                         vsip_stride s_r, vsip_length rows,
+                         vsip_stride s_c, vsip_length cols)
+  {
+    view_type* v = vsip_mbind_i(b, o, s_r, rows, s_c, cols);
+    if (!v) VSIP_THROW(std::bad_alloc());
+    return v;
+  }
+  static view_type* clone(view_type* v)
+  {
+    view_type* c = vsip_mcloneview_i(v);
+    if (!c) VSIP_THROW(std::bad_alloc());
+    return c;
+  }
+  static void destroy(view_type* v) { vsip_malldestroy_i(v);}
+  // [1] static void copy(view_type* s, view_type* d) { vsip_mcopy_i_i(s, d);}
+  static block_type* block(view_type* v) { return vsip_mgetblock_i(v);}
+  static vsip_offset offset(view_type* v) { return vsip_mgetoffset_i(v);}
+  static vsip_stride row_stride(view_type* v) { return vsip_mgetrowstride_i(v);}
+  static vsip_length row_length(view_type* v) { return vsip_mgetrowlength_i(v);}
+  static vsip_stride col_stride(view_type* v) { return vsip_mgetcolstride_i(v);}
+  static vsip_length col_length(view_type* v) { return vsip_mgetcollength_i(v);}
+};
+
+template <>
 struct View_traits<2, float>
 {
   typedef float value_type;
@@ -412,6 +577,58 @@
   typename traits::view_type *impl_;
 };
 
+
+// Specialize View to avoid using admit/release for user-storage
+// bool vectors.  Perform copy instead.
+//
+// C-VSIP and C++ have different size bool types (C-VSIP
+// vsip_scalar_bl is usually an int (4 bytes), while C++ bool is 1
+// byte).
+//
+
+template <>
+class View<1, bool, true> : public View<1, bool, false>
+{
+  typedef bool T;
+  typedef View<1, bool, false>        base_type;
+  typedef View_traits<1, T>           traits;
+  typedef Us_block<T>                 block_type;
+  typedef block_type::traits          block_traits;
+  friend class View<1, T, false>; // Needed for operator=
+
+public:
+  View(T* data, length_type size)
+    : base_type(size),
+      data_    (data),
+      offset_  (0),
+      stride_  (1)
+  {
+    for (index_type i=0; i<size; ++i)
+      traits::put(this->ptr(), i, data[i]);
+  }
+
+  View(T* data, index_type offset, stride_type stride, length_type size)
+    : base_type(size),
+      data_    (data),
+      offset_  (offset),
+      stride_  (stride)
+  {
+    for (index_type i=0; i<size; ++i)
+      traits::put(this->ptr(), i, data[offset + i*stride]);
+  }
+
+  ~View()
+  {
+    for (index_type i=0; i<traits::length(this->ptr()); ++i)
+      data_[offset_ + i*stride_] = traits::get(this->ptr(), i);
+  }
+
+private:
+  T*          data_;
+  index_type  offset_;
+  stride_type stride_;
+};
+
 template <typename T>
 class View<2, T, false> : Non_copyable
 {
@@ -504,6 +721,97 @@
   typename traits::view_type *impl_;
 };
 
+
+// Specialize View to avoid using admit/release for user-storage
+// bool matrices.  Perform copy instead.
+//
+// See View<1, bool, true> specialization for details.
+//
+
+template <>
+class View<2, bool, true> : public View<2, bool, false>
+{
+  typedef bool T;
+  typedef View<2, bool, false>        base_type;
+  typedef View_traits<2, T>           traits;
+  typedef Us_block<T>                 block_type;
+  typedef block_type::traits          block_traits;
+  friend class View<2, T, false>; // Needed for operator=
+
+public:
+  View(T* data, length_type rows, length_type cols, bool row_major)
+    : base_type(rows, cols, row_major),
+      data_    (data),
+      offset_  (0),
+      stride0_ (row_major ? cols : 1),
+      stride1_ (row_major ? 1 : rows)
+  {
+    for (index_type r=0; r<rows; ++r)
+      for (index_type c=0; c<cols; ++c)
+	traits::put(this->ptr(), r, c, data[r*stride0_ + c*stride1_]);
+  }
+
+  View(T* data, index_type offset,
+       stride_type s_r, length_type rows,
+       stride_type s_c, length_type cols)
+    : base_type(rows, cols, s_r > s_c),
+      data_    (data),
+      offset_  (offset),
+      stride0_ (s_r),
+      stride1_ (s_c)
+  {
+    for (index_type r=0; r<rows; ++r)
+      for (index_type c=0; c<cols; ++c)
+	traits::put(this->ptr(), r, c, data[offset_+r*stride0_ + c*stride1_]);
+  }
+
+  ~View()
+  {
+    // Remember: number of rows == length of column (and visa versa)
+    for (index_type r=0; r<traits::col_length(this->ptr()); ++r)
+      for (index_type c=0; c<traits::row_length(this->ptr()); ++c)
+	data_[offset_+r*stride0_+c*stride1_] = traits::get(this->ptr(), r, c);
+  }
+
+private:
+  T*          data_;
+  index_type  offset_;
+  stride_type stride0_;
+  stride_type stride1_;
+};
+
+
+// Construct view directly from Ext_data API
+
+template <dimension_type Dim,
+	  typename       T>
+struct View_from_ext;
+
+template <typename T>
+struct View_from_ext<1, T>
+{
+  template <typename ExtT>
+  View_from_ext(ExtT& ext)
+    : view_(ext.data(), 0, ext.stride(0), ext.size(0))
+  {}
+
+  View<1, T, true> view_;
+};
+
+template <typename T>
+struct View_from_ext<2, T>
+{
+  template <typename ExtT>
+  View_from_ext(ExtT& ext)
+    : view_(ext.data(), 0, ext.stride(0), ext.size(0),
+	                   ext.stride(1), ext.size(1))
+  {}
+
+  View<2, T, true> view_;
+};
+
+
+
 } // namespace vsip::impl::cvsip
 } // namespace vsip::impl
 } // namespace vsip
Index: src/vsip/core/cvsip/convert_value.hpp
===================================================================
--- src/vsip/core/cvsip/convert_value.hpp	(revision 0)
+++ src/vsip/core/cvsip/convert_value.hpp	(revision 0)
@@ -0,0 +1,121 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/cvsip/convert_value.hpp
+    @author  Jules Bergmann
+    @date    2006-12-07
+    @brief   VSIPL++ Library: Convert between C-VSIP and C++ value types.
+
+*/
+
+#ifndef VSIP_CORE_CVSIP_CONVERT_VALUE_HPP
+#define VSIP_CORE_CVSIP_CONVERT_VALUE_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+extern "C" {
+#include <vsip.h>
+}
+
+
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
+namespace cvsip
+{
+
+template <typename T>
+struct Convert_value
+{
+  typedef T cpp_type;
+  typedef T cvsip_type;
+
+  static cpp_type to_cpp(cvsip_type value)
+  { return static_cast<cpp_type>(value); }
+
+  static cvsip_type to_cvsip(cpp_type value)
+  { return static_cast<cvsip_type>(value); }
+};
+
+template <>
+struct Convert_value<complex<float> >
+{
+  typedef complex<float> cpp_type;
+  typedef vsip_cscalar_f cvsip_type;
+
+  static cpp_type to_cpp(cvsip_type value)
+  { return cpp_type(value.r, value.i); }
+
+  static cvsip_type to_cvsip(cpp_type value)
+  {
+    cvsip_type v = { value.real(), value.imag() };
+    return v;
+  }
+};
+
+template <>
+struct Convert_value<complex<double> >
+{
+  typedef complex<double> cpp_type;
+  typedef vsip_cscalar_d cvsip_type;
+
+  static cpp_type to_cpp(cvsip_type value)
+  { return cpp_type(value.r, value.i); }
+
+  static cvsip_type to_cvsip(cpp_type value)
+  {
+    cvsip_type v = { value.real(), value.imag() };
+    return v;
+  }
+};
+
+
+
+template <>
+struct Convert_value<Index<1> >
+{
+  typedef Index<1> cpp_type;
+  typedef vsip_scalar_vi cvsip_type;
+
+  static cpp_type to_cpp(cvsip_type value)
+  { return cpp_type(value); }
+
+  static cvsip_type to_cvsip(cpp_type value)
+  {
+    return cvsip_type(value[0]);
+  }
+};
+
+
+
+template <>
+struct Convert_value<Index<2> >
+{
+  typedef Index<2> cpp_type;
+  typedef vsip_scalar_mi cvsip_type;
+
+  static cpp_type to_cpp(cvsip_type value)
+  { return cpp_type(value.r, value.c); }
+
+  static cvsip_type to_cvsip(cpp_type value)
+  {
+    cvsip_type v = { value[0], value[1] };
+    return v;
+  }
+};
+
+} // namespace vsip::impl::cvsip
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif
Index: src/vsip/core/cvsip/eval_reductions.hpp
===================================================================
--- src/vsip/core/cvsip/eval_reductions.hpp	(revision 0)
+++ src/vsip/core/cvsip/eval_reductions.hpp	(revision 0)
@@ -0,0 +1,183 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/cvsip/eval_reductions.hpp
+    @author  Jules Bergmann
+    @date    2006-12-07
+    @brief   VSIPL++ Library: Reduction functions using C-VSIP BE.
+	     [math.fns.reductions].
+
+*/
+
+#ifndef VSIP_CORE_CVSIP_EVAL_REDUCTIONS_HPP
+#define VSIP_CORE_CVSIP_EVAL_REDUCTIONS_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+extern "C" {
+#include <vsip.h>
+
+// TVCPP vsip.h does not include this decl:
+vsip_scalar_vi vsip_vsumval_bl(vsip_vview_bl const* a);
+}
+
+#include <vsip/core/general_evaluator.hpp>
+#include <vsip/core/impl_tags.hpp>
+#include <vsip/core/coverage.hpp>
+#include <vsip/core/static_assert.hpp>
+#include <vsip/opt/extdata_local.hpp>
+#include <vsip/core/cvsip/view.hpp>
+#include <vsip/core/cvsip/convert_value.hpp>
+
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
+namespace cvsip
+{
+
+template <template <typename> class ReduceT,
+	  dimension_type            Dim,
+	  typename                  T>
+struct Reduction_not_implemented_by_cvsip_backend;
+
+template <template <typename> class ReduceT,
+	  dimension_type            Dim,
+          typename                  T>
+struct Reduce_class
+{
+  static bool const valid = false;
+
+  // Provide a dummy exec() function that generates a compile-time error.
+  //
+  // When used by the optimized implementation, checking of ct_valid
+  // will prevent this function from being called.
+  //
+  // When used by the reference implementation, since ct_valid is not
+  // used, this function will be instantiated if none of the specializations
+  // below apply.
+
+  template <typename CvsipViewT>
+  static T exec(CvsipViewT* view)
+  {
+    Compile_time_assert_msg<false,
+      Reduction_not_implemented_by_cvsip_backend<ReduceT, Dim, T> >::test();
+  }
+};
+
+#define VSIP_IMPL_CVSIP_RDX_RT(REDUCET, DIM, T, RT, CVSIP_FCN)		\
+template <>								\
+struct Reduce_class<REDUCET, DIM, T>					\
+{									\
+  static bool const valid = true;					\
+  static RT exec(cvsip::View_traits<DIM, T>::view_type* view)		\
+  {									\
+    VSIP_IMPL_COVER_FCN("cvsip_reduce", CVSIP_FCN);			\
+    return Convert_value<RT>::to_cpp(CVSIP_FCN(view));			\
+  }									\
+};
+
+#define VSIP_IMPL_CVSIP_RDX(REDUCET, DIM, T, CVSIP_FCN)			\
+  VSIP_IMPL_CVSIP_RDX_RT(REDUCET, DIM, T, T, CVSIP_FCN)
+
+// Reductions marked by [*] are not implemented in TVCPP.
+
+VSIP_IMPL_CVSIP_RDX_RT(Sum_value, 1,   bool, length_type, vsip_vsumval_bl)
+VSIP_IMPL_CVSIP_RDX_RT(Sum_value, 2,   bool, length_type, vsip_msumval_bl)
+
+VSIP_IMPL_CVSIP_RDX(Sum_value, 1,    int, vsip_vsumval_i)
+VSIP_IMPL_CVSIP_RDX(Sum_value, 1,  float, vsip_vsumval_f)
+VSIP_IMPL_CVSIP_RDX(Sum_value, 1, double, vsip_vsumval_d)
+//[*] VSIP_IMPL_CVSIP_RDX(Sum_value, 1, complex<float>, vsip_cvsumval_f)
+
+//[*] VSIP_IMPL_CVSIP_RDX(Sum_value, 2, int, int, vsip_msumval_i)
+VSIP_IMPL_CVSIP_RDX(Sum_value, 2,  float, vsip_msumval_f)
+VSIP_IMPL_CVSIP_RDX(Sum_value, 2, double, vsip_msumval_d)
+
+VSIP_IMPL_CVSIP_RDX(Sum_sq_value, 1,  float, vsip_vsumsqval_f)
+VSIP_IMPL_CVSIP_RDX(Sum_sq_value, 1, double, vsip_vsumsqval_d)
+VSIP_IMPL_CVSIP_RDX(Sum_sq_value, 2,  float, vsip_msumsqval_f)
+VSIP_IMPL_CVSIP_RDX(Sum_sq_value, 2, double, vsip_msumsqval_d)
+
+VSIP_IMPL_CVSIP_RDX(Mean_value, 1, float,           vsip_vmeanval_f)
+VSIP_IMPL_CVSIP_RDX(Mean_value, 1, double,          vsip_vmeanval_d)
+VSIP_IMPL_CVSIP_RDX(Mean_value, 1, complex<float>,  vsip_cvmeanval_f)
+VSIP_IMPL_CVSIP_RDX(Mean_value, 1, complex<double>, vsip_cvmeanval_d)
+VSIP_IMPL_CVSIP_RDX(Mean_value, 2, float,           vsip_mmeanval_f)
+VSIP_IMPL_CVSIP_RDX(Mean_value, 2, double,          vsip_mmeanval_d)
+VSIP_IMPL_CVSIP_RDX(Mean_value, 2, complex<float>,  vsip_cmmeanval_f)
+VSIP_IMPL_CVSIP_RDX(Mean_value, 2, complex<double>, vsip_cmmeanval_d)
+
+VSIP_IMPL_CVSIP_RDX_RT(Mean_magsq_value, 1, float,           float,
+		       vsip_vmeansqval_f)
+VSIP_IMPL_CVSIP_RDX_RT(Mean_magsq_value, 1, double,         double,
+		       vsip_vmeansqval_d)
+VSIP_IMPL_CVSIP_RDX_RT(Mean_magsq_value, 1, complex<float>,  float,
+		       vsip_cvmeansqval_f)
+VSIP_IMPL_CVSIP_RDX_RT(Mean_magsq_value, 1, complex<double>,double,
+		       vsip_cvmeansqval_d)
+VSIP_IMPL_CVSIP_RDX_RT(Mean_magsq_value, 2, float,           float,
+		       vsip_mmeansqval_f)
+VSIP_IMPL_CVSIP_RDX_RT(Mean_magsq_value, 2, double,         double,
+		       vsip_mmeansqval_d)
+VSIP_IMPL_CVSIP_RDX_RT(Mean_magsq_value, 2, complex<float>,  float,
+		       vsip_cmmeansqval_f)
+VSIP_IMPL_CVSIP_RDX_RT(Mean_magsq_value, 2, complex<double>,double,
+		       vsip_cmmeansqval_d)
+
+VSIP_IMPL_CVSIP_RDX(All_true, 1, bool,  vsip_valltrue_bl)
+VSIP_IMPL_CVSIP_RDX(All_true, 2, bool,  vsip_malltrue_bl)
+
+VSIP_IMPL_CVSIP_RDX(Any_true, 1, bool,  vsip_vanytrue_bl)
+VSIP_IMPL_CVSIP_RDX(Any_true, 2, bool,  vsip_manytrue_bl)
+
+#undef VSIP_IMPL_CVSIP_RDX
+#undef VSIP_IMPL_CVSIP_RDX_RT
+
+} // namespace vsip::impl::cvsip
+
+
+
+/***********************************************************************
+  Evaluators.
+***********************************************************************/
+
+template <template <typename> class ReduceT,
+          typename                  T,
+	  typename                  Block,
+	  typename                  OrderT,
+	  int                       Dim>
+struct Evaluator<Op_reduce<ReduceT>, T,
+		 Op_list_3<Block const&, OrderT, Int_type<Dim> >,
+		 Cvsip_tag>
+{
+  typedef typename Block::value_type value_type;
+
+  static bool const ct_valid =
+    cvsip::Reduce_class<ReduceT, Dim, value_type>::valid;
+
+  static bool rt_valid(T&, Block const&, OrderT, Int_type<Dim>)
+  { return true; }
+
+  static void exec(T& r, Block const& blk, OrderT, Int_type<Dim>)
+  {
+    Ext_data_local<Block> ext(blk, SYNC_IN);
+    cvsip::View_from_ext<Dim, value_type> view(ext);
+    
+    r = cvsip::Reduce_class<ReduceT, Dim, value_type>::exec(view.view_.ptr());
+  }
+};
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif
Index: src/vsip/core/general_evaluator.hpp
===================================================================
--- src/vsip/core/general_evaluator.hpp	(revision 0)
+++ src/vsip/core/general_evaluator.hpp	(revision 0)
@@ -0,0 +1,66 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/opt/general_dispatch.hpp
+    @author  Jules Bergmann
+    @date    2006-12-07
+    @brief   VSIPL++ Library: Dispatch harness that allows various
+             implementations to be bound to a particular operation.
+*/
+
+#ifndef VSIP_CORE_GENERAL_EVALUATOR_HPP
+#define VSIP_CORE_GENERAL_EVALUATOR_HPP
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+
+// Operation Tags.
+//
+// Each operation (dot-product, matrix-matrix product, etc) has a 
+// unique operation tag.
+
+struct Op_prod_vv_dot;    // vector-vector dot-product
+struct Op_prod_vv_outer;  // vector-vector outer-product
+struct Op_prod_mm;        // matrix-matrix product
+struct Op_prod_mv;        // matrix-vector product
+struct Op_prod_vm;        // vector-matrix product
+struct Op_prod_gemp;      // generalized matrix-matrix product
+
+
+
+// Wrapper class to describe scalar return-type.
+
+template <typename T> struct Return_scalar {};
+
+
+
+// Wrapper classes to capture list of operand types.
+
+template <typename Block1>                  struct Op_list_1 {};
+template <typename Block1, typename Block2> struct Op_list_2 {};
+template <typename T0, typename T1, typename T2> struct Op_list_3 {};
+template <typename T0, typename Block1, 
+          typename Block2, typename T3>     struct Op_list_4 {};
+
+
+
+// General evaluator class.
+
+template <typename OpTag,
+	  typename DstType,
+	  typename SrcType,
+	  typename ImplTag>
+struct Evaluator
+{
+  static bool const ct_valid = false;
+};
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_CORE_GENERAL_EVALUATOR_HPP
Index: src/vsip/opt/general_dispatch.hpp
===================================================================
--- src/vsip/opt/general_dispatch.hpp	(revision 156847)
+++ src/vsip/opt/general_dispatch.hpp	(working copy)
@@ -10,6 +10,10 @@
 #ifndef VSIP_OPT_GENERAL_DISPATCH_HPP
 #define VSIP_OPT_GENERAL_DISPATCH_HPP
 
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -17,6 +21,7 @@
 #include <vsip/core/config.hpp>
 #include <vsip/core/type_list.hpp>
 #include <vsip/core/impl_tags.hpp>
+#include <vsip/core/general_evaluator.hpp>
 
 
 
@@ -29,49 +34,6 @@
 namespace impl
 {
 
-// Operation Tags.
-//
-// Each operation (dot-product, matrix-matrix product, etc) has a 
-// unique operation tag.
-
-struct Op_prod_vv_dot;    // vector-vector dot-product
-struct Op_prod_vv_outer;  // vector-vector outer-product
-struct Op_prod_mm;        // matrix-matrix product
-struct Op_prod_mv;        // matrix-vector product
-struct Op_prod_vm;        // vector-matrix product
-struct Op_prod_gemp;      // generalized matrix-matrix product
-
-
-
-// Wrapper class to describe scalar return-type.
-
-template <typename T> struct Return_scalar {};
-
-
-
-// Wrapper classes to capture list of operand types.
-
-template <typename Block1>                  struct Op_list_1 {};
-template <typename Block1, typename Block2> struct Op_list_2 {};
-template <typename T0, typename T1, typename T2> struct Op_list_3 {};
-template <typename T0, typename Block1, 
-          typename Block2, typename T3>     struct Op_list_4 {};
-
-
-
-// General evaluator class.
-
-template <typename OpTag,
-	  typename DstType,
-	  typename SrcType,
-	  typename ImplTag>
-struct Evaluator
-{
-  static bool const ct_valid = false;
-};
-
-
-
 template <typename OpTag>
 struct Dispatch_order
 {
Index: src/vsip/opt/extdata_local.hpp
===================================================================
--- src/vsip/opt/extdata_local.hpp	(revision 156850)
+++ src/vsip/opt/extdata_local.hpp	(working copy)
@@ -72,9 +72,9 @@
   static bool const is_local = Type_equal<Local_map, map_type>::value;
 
   typedef typename
-    ITE_Type<is_local, As_type<Impl_use_direct>,
-	     ITE_Type<local_equiv, As_type<Impl_use_local>,
-		      As_type<Impl_remap> > >
+    ITE_Type<is_local,    As_type<Impl_use_direct>,
+    ITE_Type<local_equiv, As_type<Impl_use_local>,
+		          As_type<Impl_remap> > >
     ::type type;
 };
 
@@ -130,13 +130,13 @@
 public:
   Ext_data_local(BlockT&            block,
 		 sync_action_type   sync,
-		 raw_ptr_type       buffer)
+		 raw_ptr_type       buffer = raw_ptr_type())
     : base_type(block, sync, buffer)
   {}
 
   Ext_data_local(BlockT const&      block,
 		 sync_action_type   sync,
-		 raw_ptr_type       buffer)
+		 raw_ptr_type       buffer = raw_ptr_type())
     : base_type(block, sync, buffer)
   {}
 
@@ -165,13 +165,13 @@
 public:
   Ext_data_local(BlockT&            block,
 		 sync_action_type   sync,
-		 raw_ptr_type       buffer)
+		 raw_ptr_type       buffer = raw_ptr_type())
     : base_type(get_local_block(block), sync, buffer)
   {}
 
   Ext_data_local(BlockT const&      block,
 		 sync_action_type   sync,
-		 raw_ptr_type       buffer)
+		 raw_ptr_type       buffer = raw_ptr_type())
     : base_type(get_local_block(block), sync, buffer)
   {}
 
@@ -198,28 +198,31 @@
 
   typedef Ext_data<block_type, LP, RP, AT> ext_type;
 
-  typedef typename ext_type::storage_type storage_type;
+  typedef Allocated_storage<typename LP::complex_type,
+			    typename BlockT::value_type> storage_type;
   typedef typename ext_type::raw_ptr_type raw_ptr_type;
 
   // Constructor and destructor.
 public:
   Ext_data_local(BlockT&            block,
 		 sync_action_type   sync,
-		 raw_ptr_type       buffer)
-    : src_   (block),
-      block_ (block_domain<dim>(block), buffer),
-      view_  (block_),
-      ext_   (block_, sync, buffer),
-      sync_  (sync)
+		 raw_ptr_type       buffer = raw_ptr_type())
+    : src_     (block),
+      storage_ (block.size(), buffer),
+      block_   (block_domain<dim>(block), storage_.data()),
+      view_    (block_),
+      ext_     (block_, sync, buffer),
+      sync_    (sync)
   {
     assign_local(view_, src_);
   }
 
   Ext_data_local(BlockT const&      block,
 		 sync_action_type   sync,
-		 raw_ptr_type       buffer)
+		 raw_ptr_type       buffer = raw_ptr_type())
     : src_   (const_cast<BlockT&>(block)),
-      block_ (block_domain<dim>(block), buffer),
+      storage_ (block.size(), buffer),
+      block_ (block_domain<dim>(block), storage_.data()),
       view_  (block_),
       ext_   (block_, sync, buffer),
       sync_  (sync)
@@ -232,6 +235,7 @@
   {
     if (sync_ & SYNC_OUT)
       assign_local(src_, view_);
+    storage_.deallocate(block_.size());
   }
 
 
@@ -245,6 +249,7 @@
 
 private:
   src_view_type    src_;
+  storage_type     storage_;
   block_type       block_;
   view_type        view_;
   ext_type         ext_;
