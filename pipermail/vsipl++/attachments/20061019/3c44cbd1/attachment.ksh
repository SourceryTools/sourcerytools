Index: ChangeLog
===================================================================
--- ChangeLog	(revision 151873)
+++ ChangeLog	(working copy)
@@ -1,3 +1,16 @@
+2006-10-19  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/sal/eval_threshold.hpp: New file, dispatch for
+	  SAL vthres and vthr functions.
+	* src/vsip/opt/sal/bindings.hpp: Include eval_threshold.
+	* src/vsip/opt/sal/elementwise.hpp: Add bindings for SAL vthresx
+	  and vthrx functions..
+	
+	* src/vsip/core/coverage.hpp: Update header and guard.
+	* src/vsip/core/parallel/global_map.hpp: Likewise.
+	* src/vsip/core/parallel/local_map.hpp: Likewise.
+	* src/vsip/opt/sal/eval_elementwise.hpp: Likewise.
+	
 2006-10-18  Jules Bergmann  <jules@codesourcery.com>
 
 	Use non-early-binding pas assignment algorithm for expressions.
Index: src/vsip/core/coverage.hpp
===================================================================
--- src/vsip/core/coverage.hpp	(revision 151867)
+++ src/vsip/core/coverage.hpp	(working copy)
@@ -1,13 +1,13 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/opt/coverage.hpp
+/** @file    vsip/core/coverage.hpp
     @author  Jules Bergmann
     @date    2006-05-31
     @brief   VSIPL++ Library: Coverage utilities.
 */
 
-#ifndef VSIP_OPT_COVERAGE_HPP
-#define VSIP_OPT_COVERAGE_HPP
+#ifndef VSIP_CORE_COVERAGE_HPP
+#define VSIP_CORE_COVERAGE_HPP
 
 /***********************************************************************
   Included Files
@@ -45,4 +45,4 @@
 #  define VSIP_IMPL_COVER_BLK(TYPE, BLK)
 #endif
 
-#endif // VSIP_IMPL_COVERAGE_HPP
+#endif // VSIP_CORE_COVERAGE_HPP
Index: src/vsip/core/parallel/global_map.hpp
===================================================================
--- src/vsip/core/parallel/global_map.hpp	(revision 151867)
+++ src/vsip/core/parallel/global_map.hpp	(working copy)
@@ -1,14 +1,14 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/opt/global_map.hpp
+/** @file    vsip/core/parallel/global_map.hpp
     @author  Jules Bergmann
     @date    2005-06-08
     @brief   VSIPL++ Library: Global_map class.
 
 */
 
-#ifndef VSIP_OPT_GLOBAL_MAP_HPP
-#define VSIP_OPT_GLOBAL_MAP_HPP
+#ifndef VSIP_CORE_PARALLEL_GLOBAL_MAP_HPP
+#define VSIP_CORE_PARALLEL_GLOBAL_MAP_HPP
 
 /***********************************************************************
   Included Files
@@ -201,4 +201,4 @@
 
 } // namespace vsip
 
-#endif // VSIP_OPT_GLOBAL_MAP_HPP
+#endif // VSIP_CORE_PARALLEL_GLOBAL_MAP_HPP
Index: src/vsip/core/parallel/local_map.hpp
===================================================================
--- src/vsip/core/parallel/local_map.hpp	(revision 151867)
+++ src/vsip/core/parallel/local_map.hpp	(working copy)
@@ -1,14 +1,14 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/core/local_map.hpp
+/** @file    vsip/core/parallel/local_map.hpp
     @author  Jules Bergmann
     @date    2005-06-08
     @brief   VSIPL++ Library: Local_map class.
 
 */
 
-#ifndef VSIP_CORE_LOCAL_MAP_HPP
-#define VSIP_CORE_LOCAL_MAP_HPP
+#ifndef VSIP_CORE_PARALLEL_LOCAL_MAP_HPP
+#define VSIP_CORE_PARALLEL_LOCAL_MAP_HPP
 
 /***********************************************************************
   Included Files
@@ -134,4 +134,4 @@
 
 } // namespace vsip
 
-#endif // VSIP_CORE_LOCAL_MAP_HPP
+#endif // VSIP_CORE_PARALLEL_LOCAL_MAP_HPP
Index: src/vsip/opt/sal/bindings.hpp
===================================================================
--- src/vsip/opt/sal/bindings.hpp	(revision 151867)
+++ src/vsip/opt/sal/bindings.hpp	(working copy)
@@ -1,14 +1,14 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    vsip/opt/sal/misc.hpp
+/** @file    vsip/opt/sal/bindings.hpp
     @author  Don McCoy
     @date    2005-10-04
     @brief   VSIPL++ Library: Wrappers and traits to bridge with 
                Mercury SAL.
 */
 
-#ifndef VSIP_OPT_SAL_MISC_HPP
-#define VSIP_OPT_SAL_MISC_HPP
+#ifndef VSIP_OPT_SAL_BINDINGS_HPP
+#define VSIP_OPT_SAL_BINDINGS_HPP
 
 /***********************************************************************
   Included Files
@@ -22,6 +22,7 @@
 #include <vsip/core/block_traits.hpp>
 #include <vsip/opt/sal/elementwise.hpp>
 #include <vsip/opt/sal/eval_elementwise.hpp>
+#include <vsip/opt/sal/eval_threshold.hpp>
 
 /***********************************************************************
   Declarations
Index: src/vsip/opt/sal/eval_threshold.hpp
===================================================================
--- src/vsip/opt/sal/eval_threshold.hpp	(revision 0)
+++ src/vsip/opt/sal/eval_threshold.hpp	(revision 0)
@@ -0,0 +1,393 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/sal/eval_threshold.hpp
+    @author  Jules Bergmann
+    @date    2006-10-18
+    @brief   VSIPL++ Library: Dispatch for Mercury SAL -- threshold.
+*/
+
+#ifndef VSIP_OPT_SAL_EVAL_THRESHOLD_HPP
+#define VSIP_OPT_SAL_EVAL_THRESHOLD_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/expr/serial_evaluator.hpp>
+#include <vsip/core/expr/scalar_block.hpp>
+#include <vsip/core/expr/unary_block.hpp>
+#include <vsip/core/expr/binary_block.hpp>
+#include <vsip/core/expr/ternary_block.hpp>
+#include <vsip/core/expr/operations.hpp>
+#include <vsip/core/fns_elementwise.hpp>
+#include <vsip/opt/extdata.hpp>
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/opt/sal/eval_util.hpp>
+#include <vsip/core/adjust_layout.hpp>
+
+
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
+/***********************************************************************
+  Threshold Expressions
+***********************************************************************/
+
+// Optimize threshold expression: ite(A > b, A, c)
+#define VSIP_IMPL_SAL_GTE_THRESH_EXPR(T0, FUN, FUN0)			\
+template <typename DstBlock,						\
+	  typename T,							\
+	  typename Block1>						\
+struct Serial_expr_evaluator<						\
+         1, DstBlock, 							\
+									\
+         Ternary_expr_block<1, ite_functor,				\
+           Binary_expr_block<1u, ge_functor,				\
+			     Block1, T,					\
+			     Scalar_block<1, T>, T> const, bool,	\
+	   Block1, T,							\
+	   Scalar_block<1, T>, T> const,				\
+									\
+         Mercury_sal_tag>						\
+{									\
+  static char const* name() { return "Expr_SAL_thresh"; }		\
+									\
+  typedef Ternary_expr_block<1, ite_functor,				\
+            Binary_expr_block<1u, ge_functor,				\
+			      Block1, T,				\
+			      Scalar_block<1, T>, T> const, bool,	\
+	   Block1, T,							\
+	   Scalar_block<1, T>, T>					\
+	SrcBlock;							\
+									\
+  typedef typename DstBlock::value_type dst_type;			\
+									\
+  typedef typename sal::Effective_value_type<DstBlock>::type eff_dst_t;	\
+  typedef typename sal::Effective_value_type<Block1, T>::type eff_1_t;	\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block1>::layout_type>::type		\
+    block1_lp;								\
+  									\
+  static bool const ct_valid =						\
+     Type_equal<T, T0>::value &&					\
+     /* check that direct access is supported */			\
+     Ext_data_cost<DstBlock>::value == 0 &&				\
+     Ext_data_cost<Block1>::value == 0;					\
+									\
+  static bool rt_valid(DstBlock&, SrcBlock const& src)			\
+  {									\
+    return &(src.first().left()) == &(src.second()) &&			\
+           (src.first().right().value() == src.third().value() ||	\
+            src.third().value() == T(0));				\
+  }									\
+									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    typedef Scalar_block<1, T> sb_type;					\
+									\
+    sal::Ext_wrapper<DstBlock, dst_lp>  ext_dst(dst,        SYNC_OUT);	\
+    sal::Ext_wrapper<Block1, block1_lp> ext_A(src.second(), SYNC_IN);	\
+    sal::Ext_wrapper<sb_type>           ext_b(src.first().right(), SYNC_IN);\
+									\
+    if (src.third().value() == T(0))					\
+      FUN0(typename sal::Ext_wrapper<Block1, block1_lp>::sal_type(ext_A),\
+           typename sal::Ext_wrapper<sb_type>::sal_type(ext_b),		\
+	   typename sal::Ext_wrapper<DstBlock, dst_lp>::sal_type(ext_dst),\
+	   dst.size());							\
+    else								\
+      FUN(typename sal::Ext_wrapper<Block1, block1_lp>::sal_type(ext_A),\
+           typename sal::Ext_wrapper<sb_type>::sal_type(ext_b),		\
+	   typename sal::Ext_wrapper<DstBlock, dst_lp>::sal_type(ext_dst),\
+	   dst.size());							\
+  }									\
+};
+
+// This definition (and the above ifdef) will go away once the code
+// has benchmarked.
+// VSIP_IMPL_SAL_GTE_THRESH_EXPR(float, sal::vthresh, sal::vthresh0)
+
+
+
+// Common evaluator for a threshold expressions.
+
+template <typename DstBlock,
+	  typename T,
+	  typename Block1>
+struct Thresh_expr_evaluator
+{
+  static char const* name() { return "Expr_SAL_thresh"; }
+
+  typedef typename sal::Effective_value_type<DstBlock>::type eff_dst_t;
+  typedef typename sal::Effective_value_type<Block1, T>::type eff_1_t;
+
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<DstBlock>::layout_type>::type
+    dst_lp;
+  
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<Block1>::layout_type>::type
+    block1_lp;
+
+  static bool const ct_valid =
+     Type_equal<T, float>::value &&
+     /* check that direct access is supported */
+     Ext_data_cost<DstBlock>::value == 0 &&
+     Ext_data_cost<Block1>::value == 0;
+
+  static bool rt_valid(DstBlock&,
+		       Block1 const&             a1,
+		       Scalar_block<1, T> const& b,
+		       Block1 const&             a2,
+		       Scalar_block<1, T> const& c)
+  {
+    return &a1 == &a2 && (b.value() == c.value() || c.value() == T(0));
+  }
+
+  static void exec(
+    DstBlock&                 dst,
+    Block1 const&             a,
+    Scalar_block<1, T> const& b,
+    Block1 const&,
+    Scalar_block<1, T> const& c)
+  {
+    typedef Scalar_block<1, T> sb_type;
+
+    sal::Ext_wrapper<DstBlock, dst_lp>  ext_dst(dst, SYNC_OUT);
+    sal::Ext_wrapper<Block1, block1_lp> ext_A(a,     SYNC_IN);
+    sal::Ext_wrapper<sb_type>           ext_b(b,     SYNC_IN);
+
+    if (c.value() == T(0))
+      sal::vthresh0(
+	typename sal::Ext_wrapper<Block1, block1_lp>::sal_type(ext_A),
+        typename sal::Ext_wrapper<sb_type>::sal_type(ext_b),
+	typename sal::Ext_wrapper<DstBlock, dst_lp>::sal_type(ext_dst),
+	dst.size());
+    else
+      sal::vthresh(
+	typename sal::Ext_wrapper<Block1, block1_lp>::sal_type(ext_A),
+	typename sal::Ext_wrapper<sb_type>::sal_type(ext_b),
+	typename sal::Ext_wrapper<DstBlock, dst_lp>::sal_type(ext_dst),
+	dst.size());
+  }
+};
+
+
+
+/// Frontend for threshold expressions like:
+///
+///   ite(A >= b, A, c)
+
+template <typename DstBlock,
+	  typename T,
+	  typename Block1>
+struct Serial_expr_evaluator<
+         1, DstBlock, 
+
+         Ternary_expr_block<1, ite_functor,
+           Binary_expr_block<1u, ge_functor,
+			     Block1, T,
+			     Scalar_block<1, T>, T> const, bool,
+	   Block1, T,
+	   Scalar_block<1, T>, T> const,
+
+         Mercury_sal_tag>
+  : Thresh_expr_evaluator<DstBlock, T, Block1>
+{
+  typedef Thresh_expr_evaluator<DstBlock, T, Block1> base_type;
+
+  typedef Ternary_expr_block<1, ite_functor,
+            Binary_expr_block<1u, ge_functor,
+			      Block1, T,
+			      Scalar_block<1, T>, T> const, bool,
+	   Block1, T,
+	   Scalar_block<1, T>, T>
+	SrcBlock;
+
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    return base_type::rt_valid(dst,
+			src.first().left(),
+			src.first().right(),
+			src.second(),
+			src.third());
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    base_type::exec(dst,
+		    src.first().left(),
+		    src.first().right(),
+		    src.second(),
+		    src.third());
+  }
+};
+
+
+
+/// Frontend for threshold expressions like:
+///
+///   ite(A < b, c, A)
+
+template <typename DstBlock,
+	  typename T,
+	  typename Block1>
+struct Serial_expr_evaluator<
+         1, DstBlock, 
+
+         Ternary_expr_block<1, ite_functor,
+           Binary_expr_block<1u, lt_functor,
+			     Block1, T,
+			     Scalar_block<1, T>, T> const, bool,
+	   Scalar_block<1, T>, T,
+	   Block1, T> const,
+
+         Mercury_sal_tag>
+  : Thresh_expr_evaluator<DstBlock, T, Block1>
+{
+  typedef Thresh_expr_evaluator<DstBlock, T, Block1> base_type;
+
+  typedef Ternary_expr_block<1, ite_functor,
+            Binary_expr_block<1u, lt_functor,
+			      Block1, T,
+			      Scalar_block<1, T>, T> const, bool,
+	   Scalar_block<1, T>, T,
+	   Block1, T>
+	SrcBlock;
+
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    return base_type::rt_valid(dst,
+			src.first().left(),
+			src.first().right(),
+			src.third(),
+			src.second());
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    base_type::exec(dst,
+		    src.first().left(),
+		    src.first().right(),
+		    src.third(),
+		    src.second());
+  }
+};
+
+
+
+/// Frontend for threshold expressions like:
+///
+///   ite(b <= A, A, c)
+
+template <typename DstBlock,
+	  typename T,
+	  typename Block1>
+struct Serial_expr_evaluator<
+         1, DstBlock, 
+
+         Ternary_expr_block<1, ite_functor,
+           Binary_expr_block<1u, le_functor,
+			     Scalar_block<1, T>, T,
+			     Block1, T> const, bool,
+	   Block1, T,
+	   Scalar_block<1, T>, T> const,
+
+         Mercury_sal_tag>
+  : Thresh_expr_evaluator<DstBlock, T, Block1>
+{
+  typedef Thresh_expr_evaluator<DstBlock, T, Block1> base_type;
+
+  typedef Ternary_expr_block<1, ite_functor,
+            Binary_expr_block<1u, le_functor,
+			      Scalar_block<1, T>, T,
+			      Block1, T> const, bool,
+	   Block1, T,
+	   Scalar_block<1, T>, T>
+	SrcBlock;
+
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    return base_type::rt_valid(dst,
+			src.first().right(),
+			src.first().left(),
+			src.second(),
+			src.third());
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    base_type::exec(dst,
+		    src.first().right(),
+		    src.first().left(),
+		    src.second(),
+		    src.third());
+  }
+};
+
+
+
+/// Frontend for threshold expressions like:
+///
+///   ite(b > A, c, A)
+
+template <typename DstBlock,
+	  typename T,
+	  typename Block1>
+struct Serial_expr_evaluator<
+         1, DstBlock, 
+
+         Ternary_expr_block<1, ite_functor,
+           Binary_expr_block<1u, gt_functor,
+			     Scalar_block<1, T>, T,
+			     Block1, T> const, bool,
+	   Scalar_block<1, T>, T,
+	   Block1, T> const,
+
+         Mercury_sal_tag>
+  : Thresh_expr_evaluator<DstBlock, T, Block1>
+{
+  typedef Thresh_expr_evaluator<DstBlock, T, Block1> base_type;
+
+  typedef Ternary_expr_block<1, ite_functor,
+            Binary_expr_block<1u, gt_functor,
+			      Scalar_block<1, T>, T,
+			      Block1, T> const, bool,
+	   Scalar_block<1, T>, T,
+	   Block1, T>
+	SrcBlock;
+
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    return base_type::rt_valid(dst,
+			src.first().right(),
+			src.first().left(),
+			src.third(),
+			src.second());
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    base_type::exec(dst,
+		    src.first().right(),
+		    src.first().left(),
+		    src.third(),
+		    src.second());
+  }
+};
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_SAL_EVAL_THRESHOLD_HPP
Index: src/vsip/opt/sal/elementwise.hpp
===================================================================
--- src/vsip/opt/sal/elementwise.hpp	(revision 151867)
+++ src/vsip/opt/sal/elementwise.hpp	(working copy)
@@ -525,6 +525,7 @@
 
 
 
+
 #define VSIP_IMPL_SAL_CVS(FCN, T, SALFCN)				\
 VSIP_IMPL_SAL_INLINE							\
 void FCN(								\
@@ -797,9 +798,12 @@
 
 VSIP_IMPL_SAL_VSS(vma, double, vsmsadx)
 
+VSIP_IMPL_VS     (vthresh,  float, vthrx)
+VSIP_IMPL_VS     (vthresh0, float, vthresx)
 
 
 
+
 #define VSIP_IMPL_SAL_CVSV(FCN, T, SALFCN)				\
 VSIP_IMPL_SAL_INLINE void						\
 FCN(									\
Index: src/vsip/opt/sal/eval_elementwise.hpp
===================================================================
--- src/vsip/opt/sal/eval_elementwise.hpp	(revision 151867)
+++ src/vsip/opt/sal/eval_elementwise.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/opt/sal/eval_elementwise.hpp
     @author  Jules Bergmann
@@ -1122,4 +1122,4 @@
 } // namespace vsip::impl
 } // namespace vsip
 
-#endif // VSIP_IMPL_SAL_EVAL_HPP
+#endif // VSIP_OPT_SAL_EVAL_ELEMENTWISE_HPP
