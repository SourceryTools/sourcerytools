Index: ChangeLog
===================================================================
--- ChangeLog	(revision 164966)
+++ ChangeLog	(working copy)
@@ -1,3 +1,66 @@
+2007-03-13  Jules Bergmann  <jules@codesourcery.com>
+
+	General RBO functionality.
+	* src/vsip/core/impl_tags.hpp (Fc_expr_tag, Rbo_expr_tag): New
+	  impl tags for fastconv RBO eval, and general RBO eval.
+	* src/vsip/opt/rt_extdata.hpp (is_alias): New function to determine
+	  if two blocks alias.  Add calls to loop_fusion init/fini.
+	* src/vsip/opt/expr/return_block.hpp: New file, return expression
+	  block.
+	* src/vsip/opt/expr/lf_initfini.hpp: New file, loop fusion
+	  init/fini routines.  Used to evaluator return expr blocks.
+	* src/vsip/opt/expr/serial_dispatch.hpp: Include RBO bits.
+	* src/vsip/opt/expr/serial_dispatch_fwd.hpp: Include RBO tags
+	* src/vsip/opt/expr/eval_return_block.hpp: New file, evaluate
+	  simple RBO expression (A = fft(B)) without temporary.
+	* src/vsip/opt/expr/serial_evaluator.hpp: Call loop fusion
+	  init/fini.
+
+	FFT RBO support.
+	* src/vsip/core/fft/util.hpp: (Result_rbo, Result_fftm_rbo) traits
+	  classes for Fft/Fftm to return Return_expr_blocks.
+	* src/vsip/opt/fft/return_functor.hpp: New file, implements
+	  Fft_return_functor to be used by Return_expr_block.
+	* src/vsip/core/fft.hpp: Use Return_expr_block for Fft/Fftm result. 
+	* src/vsip/opt/fft/workspace.hpp: Add block versions of by_reference
+	  processing routines.
+
+	Optimized Fastconv using RBO.
+	* src/vsip/opt/cbe/ppu/eval_fastconv.hpp: New file, Cbe RBO fastconv
+	  evaluator using Fastconv.
+	* src/vsip/opt/cbe/ppu/fastconv.hpp: Remove unnecessary include
+	  which creates loop when this file included by eval_fastconv.hpp.
+	* src/vsip/opt/expr/eval_fastconv.hpp: New file, general RBO
+	  fastconv evaluator using Fftm objects a row at a time.
+
+	Diagnostic Updates (support for Ext_data and distr expressions).
+	* src/vsip/opt/choose_access.hpp: Track reason behind access
+	  type choice.
+	* src/vsip/opt/extdata.hpp: Update for Choose_access changes.
+	* src/vsip/opt/diag/extdata.hpp: New file, help diagnose Ext_data.
+	* src/vsip/opt/diag/eval.hpp: Add diagnostics for distributed
+	  expressions.  Rename diagnose_eval to diagnose_eval_tag.
+	* tests/diag_eval.cpp: Update to exercise distributed diag
+	  and use new name for diagnose_eval_tag.
+
+	Additional Fastconv benchmark cases.
+	* benchmarks/cell/fastconv.cpp: Add case for recreating Fastconv
+	  object before each convolution.  Renumber cases.
+	* benchmarks/fastconv.cpp: Add single-line fastconv case (9, 19).
+	  Add mixed phased/interleaved case.  Add error checking.
+	
+	Benchmark Updates.
+	* benchmarks/vma.cpp: Disable use of SIMD routines.
+	* benchmarks/main.cpp: Add size parameter to -steady option.
+	* benchmarks/sal/fft.cpp: Update to use benchmark base.
+	* benchmarks/sal/vma.cpp: Likewise.
+	* benchmarks/sal/vmul.cpp: Likewise.
+	* benchmarks/sal/memwrite.cpp: Likewise.
+	* benchmarks/sal/fastconv.cpp: Likewise.  Use common fastconv.hpp.
+
+	* src/vsip/core/vmmul.hpp: Split Vmmul_block definition into ...
+	* src/vsip/core/expr/vmmul_block.hpp: New file, ... here.
+
 2007-03-06  Jules Bergmann  <jules@codesourcery.com>
 
 	* benchmarks/alloc_block.hpp: Remove access to private class member,
Index: src/vsip/core/fft/util.hpp
===================================================================
--- src/vsip/core/fft/util.hpp	(revision 164922)
+++ src/vsip/core/fft/util.hpp	(working copy)
@@ -18,6 +18,10 @@
 #include <vsip/core/fft/backend.hpp>
 #include <vsip/core/fast_block.hpp>
 #include <vsip/core/view_traits.hpp>
+#ifndef VSIP_IMPL_REF_IMPL
+#  include <vsip/opt/fft/return_functor.hpp>
+#  include <vsip/opt/expr/return_block.hpp>
+#endif
 
 /***********************************************************************
   Declarations
@@ -161,6 +165,60 @@
   { return new_view<view_type>(dom);}
 };
 
+
+
+#ifndef VSIP_IMPL_REF_IMPL
+
+/// Traits class to determine view type returned by Fft for
+/// by_value operators with return-block optimization.
+
+template <dimension_type Dim,
+	  typename       InT,
+	  typename       OutT,
+	  typename       ViewT,
+	  typename       WorkspaceT,
+	  int            AxisV,
+	  int            ExponentV>
+struct Result_rbo
+{
+  typedef Fft_return_functor<Dim, OutT, typename ViewT::block_type,
+                      fft::backend<Dim, InT, OutT, AxisV, ExponentV>,
+		      WorkspaceT>
+		functor_type;
+
+  typedef Return_expr_block<Dim, OutT, functor_type>
+		block_type;
+
+  typedef typename View_of_dim<Dim, OutT, block_type const>::type
+		view_type;
+};
+
+
+
+template <typename       InT,
+	  typename       OutT,
+	  typename       BlockT,
+	  typename       WorkspaceT,
+	  int            AxisV,
+	  int            ExponentV>
+struct Result_fftm_rbo
+{
+  static dimension_type const dim = 2;
+  typedef const_Matrix<InT, BlockT> in_view_type;
+  typedef Fft_return_functor<dim, OutT, BlockT,
+                      fft::fftm<InT, OutT, AxisV, ExponentV>,
+		      WorkspaceT>
+		functor_type;
+
+  typedef Return_expr_block<dim, OutT, functor_type>
+		block_type;
+
+  typedef typename View_of_dim<dim, OutT, block_type const>::type
+		view_type;
+};
+
+#endif
+
 } // namespace vsip::impl::fft
 } // namespace vsip::impl
 } // namespace vsip
Index: src/vsip/core/expr/vmmul_block.hpp
===================================================================
--- src/vsip/core/expr/vmmul_block.hpp	(revision 0)
+++ src/vsip/core/expr/vmmul_block.hpp	(revision 0)
@@ -0,0 +1,276 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/expr/vmmul_block.hpp
+    @author  Jules Bergmann
+    @date    2007-02-02
+    @brief   VSIPL++ Library: Expression block for vector-matrix multiply
+
+*/
+
+#ifndef VSIP_CORE_EXPR_VMMUL_BLOCK_HPP
+#define VSIP_CORE_EXPR_VMMUL_BLOCK_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/block_traits.hpp>
+#include <vsip/core/promote.hpp>
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
+/// Expression template block for vector-matrix multiply.
+/// Requires:
+///   VECDIM to be a dimension of vector (0 or 1)
+///   BLOCK0 to be a 1-Dim Block.
+///   BLOCK1 to be a 2-Dim Block.
+
+template <dimension_type VecDim,
+	  typename       Block0,
+	  typename       Block1>
+class Vmmul_expr_block : public Non_assignable
+{
+public:
+  static dimension_type const dim = 2;
+
+  typedef typename Block0::value_type value0_type;
+  typedef typename Block1::value_type value1_type;
+
+  typedef typename Promotion<value0_type, value1_type>::type value_type;
+
+  typedef value_type&               reference_type;
+  typedef value_type const&         const_reference_type;
+  typedef typename Block1::map_type map_type;
+
+  Vmmul_expr_block(Block0 const& vblk, Block1 const& mblk)
+    : vblk_(vblk), mblk_(mblk)
+  {}
+
+  length_type size() const VSIP_NOTHROW { return mblk_.size(); }
+  length_type size(dimension_type Dim, dimension_type d) const VSIP_NOTHROW
+    { return mblk_.size(Dim, d); }
+
+
+  void increment_count() const VSIP_NOTHROW {}
+  void decrement_count() const VSIP_NOTHROW {}
+  map_type const& map() const VSIP_NOTHROW { return mblk_.map();}
+
+  value_type get(index_type i, index_type j) const
+  {
+    if (VecDim == 0)
+      return vblk_.get(j) * mblk_.get(i, j);
+    else
+      return vblk_.get(i) * mblk_.get(i, j);
+  }
+
+  Block0 const& get_vblk() const VSIP_NOTHROW { return vblk_; }
+  Block1 const& get_mblk() const VSIP_NOTHROW { return mblk_; }
+
+  // copy-constructor: default is OK.
+
+private:
+  typename View_block_storage<Block0>::expr_type vblk_;
+  typename View_block_storage<Block1>::expr_type mblk_;
+};
+
+
+
+/// Specialize traits for Vmmul_expr_block.
+
+template <dimension_type VecDim,
+	  typename       Block0,
+	  typename       Block1>
+struct Is_expr_block<Vmmul_expr_block<VecDim, Block0, Block1> >
+{ static bool const value = true; };
+
+template <dimension_type VecDim,
+	  typename       Block0,
+	  typename       Block1>
+struct View_block_storage<Vmmul_expr_block<VecDim, Block0, Block1> const>
+  : By_value_block_storage<Vmmul_expr_block<VecDim, Block0, Block1> const>
+{};
+
+template <dimension_type VecDim,
+	  typename       Block0,
+	  typename       Block1>
+struct Distributed_local_block<Vmmul_expr_block<VecDim, Block0, Block1> const>
+{
+  typedef Vmmul_expr_block<VecDim,
+			   typename Distributed_local_block<Block0>::type,
+			   typename Distributed_local_block<Block1>::type>
+		const type;
+  typedef Vmmul_expr_block<VecDim,
+			 typename Distributed_local_block<Block0>::proxy_type,
+			 typename Distributed_local_block<Block1>::proxy_type>
+		const proxy_type;
+};
+
+
+
+template <typename       CombineT,
+	  dimension_type VecDim,
+	  typename       Block0,
+	  typename       Block1>
+struct Combine_return_type<CombineT,
+                           Vmmul_expr_block<VecDim, Block0, Block1> const>
+{
+  typedef Vmmul_expr_block<VecDim,
+    typename Combine_return_type<CombineT, Block0>::tree_type,
+    typename Combine_return_type<CombineT, Block1>::tree_type>
+		const tree_type;
+  typedef tree_type type;
+};
+
+
+
+template <typename       CombineT,
+	  dimension_type VecDim,
+	  typename       Block0,
+	  typename       Block1>
+struct Combine_return_type<CombineT,
+                           Vmmul_expr_block<VecDim, Block0, Block1> >
+{
+  typedef Vmmul_expr_block<VecDim,
+    typename Combine_return_type<CombineT, Block0>::tree_type,
+    typename Combine_return_type<CombineT, Block1>::tree_type>
+		const tree_type;
+  typedef tree_type type;
+};
+
+
+  
+template <dimension_type VecDim,
+	  typename       Block0,
+	  typename       Block1>
+Vmmul_expr_block<VecDim, 
+		 typename Distributed_local_block<Block0>::type,
+		 typename Distributed_local_block<Block1>::type>
+get_local_block(
+  Vmmul_expr_block<VecDim, Block0, Block1> const& block)
+{
+  typedef Vmmul_expr_block<VecDim,
+                           typename Distributed_local_block<Block0>::type,
+                           typename Distributed_local_block<Block1>::type>
+		block_type;
+
+  return block_type(get_local_block(block.get_vblk()),
+		    get_local_block(block.get_mblk()));
+}
+
+
+
+template <typename       CombineT,
+	  dimension_type VecDim,
+	  typename       Block0,
+	  typename       Block1>
+typename Combine_return_type<CombineT,
+			     Vmmul_expr_block<VecDim, Block0, Block1> const>
+		::type
+apply_combine(
+  CombineT const&                                 combine,
+  Vmmul_expr_block<VecDim, Block0, Block1> const& block)
+{
+  typedef typename Combine_return_type<
+    CombineT,
+    Vmmul_expr_block<VecDim, Block0, Block1> const>::type
+		block_type;
+
+  return block_type(apply_combine(combine, block.get_vblk()),
+		    apply_combine(combine, block.get_mblk()));
+}
+
+
+
+template <typename       VisitorT,
+	  dimension_type VecDim,
+	  typename       Block0,
+	  typename       Block1>
+void
+apply_leaf(
+  VisitorT const&                                 visitor,
+  Vmmul_expr_block<VecDim, Block0, Block1> const& block)
+{
+  apply_leaf(visitor, block.get_vblk());
+  apply_leaf(visitor, block.get_mblk());
+}
+
+
+
+// Check vmmul parallel support conditions
+//
+// vector-matrix multiply works with the following mappings:
+// case 0:
+//  - All data mapped locally (Local_map) (*)
+// case 1:
+//  - vector data mapped global
+//    matrix data mapped without distribution only vector direction
+// case 2:
+//  - vector data mapped distributed,
+//    matrix data mapped with same distribution along vector direction,
+//       and no distribution perpendicular to vector.
+//  - vector and matrix mapped to single, single processor
+//
+
+template <dimension_type MapDim,
+	  typename       MapT,
+	  dimension_type VecDim,
+	  typename       Block0,
+	  typename       Block1>
+struct Is_par_same_map<MapDim, MapT,
+                       Vmmul_expr_block<VecDim, Block0, Block1> const>
+{
+  typedef Vmmul_expr_block<VecDim, Block0, Block1> const block_type;
+
+  static bool value(MapT const& map, block_type& block)
+  {
+    // Dispatch_assign only calls Is_par_same_map for distributed
+    // expressions.
+    assert(!Is_local_only<MapT>::value);
+
+    return 
+      // Case 1a: vector is global
+      (Is_par_same_map<1, Global_map<1>, Block0>::value(
+			Global_map<1>(), block.get_vblk()) &&
+       map.num_subblocks(1-VecDim) == 1 &&
+       Is_par_same_map<MapDim, MapT, Block1>::value(map, block.get_mblk())) ||
+
+      // Case 1b: vector is replicated
+      (Is_par_same_map<1, Replicated_map<1>, Block0>::value(
+			Replicated_map<1>(), block.get_vblk()) &&
+       map.num_subblocks(1-VecDim) == 1 &&
+       Is_par_same_map<MapDim, MapT, Block1>::value(map, block.get_mblk())) ||
+
+      // Case 2:
+      (map.num_subblocks(VecDim) == 1 &&
+       Is_par_same_map<1, typename Map_project_1<VecDim, MapT>::type, Block0>
+	    ::value(Map_project_1<VecDim, MapT>::project(map, 0),
+		    block.get_vblk()) &&
+       Is_par_same_map<MapDim, MapT, Block1>::value(map, block.get_mblk()));
+  }
+};
+
+
+
+template <dimension_type VecDim,
+	  typename       Block0,
+	  typename       Block1>
+struct Is_par_reorg_ok<Vmmul_expr_block<VecDim, Block0, Block1> const>
+{
+  static bool const value = false;
+};
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_CORE_EXPR_VMMUL_BLOCK_HPP
Index: src/vsip/core/vmmul.hpp
===================================================================
--- src/vsip/core/vmmul.hpp	(revision 164922)
+++ src/vsip/core/vmmul.hpp	(working copy)
@@ -18,6 +18,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/core/promote.hpp>
+#include <vsip/core/expr/vmmul_block.hpp>
 #if !VSIP_IMPL_REF_IMPL
 #  include <vsip/opt/expr/serial_evaluator.hpp>
 #endif
@@ -34,249 +35,6 @@
 namespace impl
 {
 
-/// Expression template block for vector-matrix multiply.
-/// Requires:
-///   VECDIM to be a dimension of vector (0 or 1)
-///   BLOCK0 to be a 1-Dim Block.
-///   BLOCK1 to be a 2-Dim Block.
-
-template <dimension_type VecDim,
-	  typename       Block0,
-	  typename       Block1>
-class Vmmul_expr_block : public Non_assignable
-{
-public:
-  static dimension_type const dim = 2;
-
-  typedef typename Block0::value_type value0_type;
-  typedef typename Block1::value_type value1_type;
-
-  typedef typename Promotion<value0_type, value1_type>::type value_type;
-
-  typedef value_type&               reference_type;
-  typedef value_type const&         const_reference_type;
-  typedef typename Block1::map_type map_type;
-
-  Vmmul_expr_block(Block0 const& vblk, Block1 const& mblk)
-    : vblk_(vblk), mblk_(mblk)
-  {}
-
-  length_type size() const VSIP_NOTHROW { return mblk_.size(); }
-  length_type size(dimension_type Dim, dimension_type d) const VSIP_NOTHROW
-    { return mblk_.size(Dim, d); }
-
-
-  void increment_count() const VSIP_NOTHROW {}
-  void decrement_count() const VSIP_NOTHROW {}
-  map_type const& map() const VSIP_NOTHROW { return mblk_.map();}
-
-  value_type get(index_type i, index_type j) const
-  {
-    if (VecDim == 0)
-      return vblk_.get(j) * mblk_.get(i, j);
-    else
-      return vblk_.get(i) * mblk_.get(i, j);
-  }
-
-  Block0 const& get_vblk() const VSIP_NOTHROW { return vblk_; }
-  Block1 const& get_mblk() const VSIP_NOTHROW { return mblk_; }
-
-  // copy-constructor: default is OK.
-
-private:
-  typename View_block_storage<Block0>::expr_type vblk_;
-  typename View_block_storage<Block1>::expr_type mblk_;
-};
-
-
-
-/// Specialize traits for Vmmul_expr_block.
-
-template <dimension_type VecDim,
-	  typename       Block0,
-	  typename       Block1>
-struct Is_expr_block<Vmmul_expr_block<VecDim, Block0, Block1> >
-{ static bool const value = true; };
-
-template <dimension_type VecDim,
-	  typename       Block0,
-	  typename       Block1>
-struct View_block_storage<Vmmul_expr_block<VecDim, Block0, Block1> const>
-  : By_value_block_storage<Vmmul_expr_block<VecDim, Block0, Block1> const>
-{};
-
-template <dimension_type VecDim,
-	  typename       Block0,
-	  typename       Block1>
-struct Distributed_local_block<Vmmul_expr_block<VecDim, Block0, Block1> const>
-{
-  typedef Vmmul_expr_block<VecDim,
-			   typename Distributed_local_block<Block0>::type,
-			   typename Distributed_local_block<Block1>::type>
-		const type;
-  typedef Vmmul_expr_block<VecDim,
-			 typename Distributed_local_block<Block0>::proxy_type,
-			 typename Distributed_local_block<Block1>::proxy_type>
-		const proxy_type;
-};
-
-
-
-template <typename       CombineT,
-	  dimension_type VecDim,
-	  typename       Block0,
-	  typename       Block1>
-struct Combine_return_type<CombineT,
-                           Vmmul_expr_block<VecDim, Block0, Block1> const>
-{
-  typedef Vmmul_expr_block<VecDim,
-    typename Combine_return_type<CombineT, Block0>::tree_type,
-    typename Combine_return_type<CombineT, Block1>::tree_type>
-		const tree_type;
-  typedef tree_type type;
-};
-
-
-
-template <typename       CombineT,
-	  dimension_type VecDim,
-	  typename       Block0,
-	  typename       Block1>
-struct Combine_return_type<CombineT,
-                           Vmmul_expr_block<VecDim, Block0, Block1> >
-{
-  typedef Vmmul_expr_block<VecDim,
-    typename Combine_return_type<CombineT, Block0>::tree_type,
-    typename Combine_return_type<CombineT, Block1>::tree_type>
-		const tree_type;
-  typedef tree_type type;
-};
-
-
-  
-template <dimension_type VecDim,
-	  typename       Block0,
-	  typename       Block1>
-Vmmul_expr_block<VecDim, 
-		 typename Distributed_local_block<Block0>::type,
-		 typename Distributed_local_block<Block1>::type>
-get_local_block(
-  Vmmul_expr_block<VecDim, Block0, Block1> const& block)
-{
-  typedef Vmmul_expr_block<VecDim,
-                           typename Distributed_local_block<Block0>::type,
-                           typename Distributed_local_block<Block1>::type>
-		block_type;
-
-  return block_type(get_local_block(block.get_vblk()),
-		    get_local_block(block.get_mblk()));
-}
-
-
-
-template <typename       CombineT,
-	  dimension_type VecDim,
-	  typename       Block0,
-	  typename       Block1>
-typename Combine_return_type<CombineT,
-			     Vmmul_expr_block<VecDim, Block0, Block1> const>
-		::type
-apply_combine(
-  CombineT const&                                 combine,
-  Vmmul_expr_block<VecDim, Block0, Block1> const& block)
-{
-  typedef typename Combine_return_type<
-    CombineT,
-    Vmmul_expr_block<VecDim, Block0, Block1> const>::type
-		block_type;
-
-  return block_type(apply_combine(combine, block.get_vblk()),
-		    apply_combine(combine, block.get_mblk()));
-}
-
-
-
-template <typename       VisitorT,
-	  dimension_type VecDim,
-	  typename       Block0,
-	  typename       Block1>
-void
-apply_leaf(
-  VisitorT const&                                 visitor,
-  Vmmul_expr_block<VecDim, Block0, Block1> const& block)
-{
-  apply_leaf(visitor, block.get_vblk());
-  apply_leaf(visitor, block.get_mblk());
-}
-
-
-
-// Check vmmul parallel support conditions
-//
-// vector-matrix multiply works with the following mappings:
-// case 0:
-//  - All data mapped locally (Local_map) (*)
-// case 1:
-//  - vector data mapped global
-//    matrix data mapped without distribution only vector direction
-// case 2:
-//  - vector data mapped distributed,
-//    matrix data mapped with same distribution along vector direction,
-//       and no distribution perpendicular to vector.
-//  - vector and matrix mapped to single, single processor
-//
-
-template <dimension_type MapDim,
-	  typename       MapT,
-	  dimension_type VecDim,
-	  typename       Block0,
-	  typename       Block1>
-struct Is_par_same_map<MapDim, MapT,
-                       Vmmul_expr_block<VecDim, Block0, Block1> const>
-{
-  typedef Vmmul_expr_block<VecDim, Block0, Block1> const block_type;
-
-  static bool value(MapT const& map, block_type& block)
-  {
-    // Dispatch_assign only calls Is_par_same_map for distributed
-    // expressions.
-    assert(!Is_local_only<MapT>::value);
-
-    return 
-      // Case 1a: vector is global
-      (Is_par_same_map<1, Global_map<1>, Block0>::value(
-			Global_map<1>(), block.get_vblk()) &&
-       map.num_subblocks(1-VecDim) == 1 &&
-       Is_par_same_map<MapDim, MapT, Block1>::value(map, block.get_mblk())) ||
-
-      // Case 1b: vector is replicated
-      (Is_par_same_map<1, Replicated_map<1>, Block0>::value(
-			Replicated_map<1>(), block.get_vblk()) &&
-       map.num_subblocks(1-VecDim) == 1 &&
-       Is_par_same_map<MapDim, MapT, Block1>::value(map, block.get_mblk())) ||
-
-      // Case 2:
-      (map.num_subblocks(VecDim) == 1 &&
-       Is_par_same_map<1, typename Map_project_1<VecDim, MapT>::type, Block0>
-	    ::value(Map_project_1<VecDim, MapT>::project(map, 0),
-		    block.get_vblk()) &&
-       Is_par_same_map<MapDim, MapT, Block1>::value(map, block.get_mblk()));
-  }
-};
-
-
-
-template <dimension_type VecDim,
-	  typename       Block0,
-	  typename       Block1>
-struct Is_par_reorg_ok<Vmmul_expr_block<VecDim, Block0, Block1> const>
-{
-  static bool const value = false;
-};
-
-
-
-
 /// Traits class to determines return type for vmmul.
 
 template <dimension_type Dim,
Index: src/vsip/core/fft.hpp
===================================================================
--- src/vsip/core/fft.hpp	(revision 164922)
+++ src/vsip/core/fft.hpp	(working copy)
@@ -25,6 +25,7 @@
 #  include <vsip/opt/fft/workspace.hpp>
 #endif
 #include <vsip/core/metaprogramming.hpp>
+#include <vsip/opt/expr/return_block.hpp>
 #include <vsip/core/profile.hpp>
 
 #ifndef VSIP_IMPL_REF_IMPL
@@ -198,18 +199,39 @@
       workspace_(backend_.get(), this->input_size(), this->output_size(), scale)
   {}
 
+#ifdef VSIP_IMPL_REF_IMPL
   template <typename ViewT>
-  typename fft::result<O, typename ViewT::block_type>::view_type
+  typename fft::result<), typename ViewT::block_type>::view_type
   operator()(ViewT in) VSIP_THROW((std::bad_alloc))
   {
     typename base::Scope scope(*this);
     assert(extent(in) == extent(this->input_size()));
     typedef fft::result<O, typename ViewT::block_type> traits;
     typename traits::view_type out(traits::create(this->output_size(),
-						  in.block().map()));
+                                                 in.block().map()));
     workspace_.by_reference(this->backend_.get(), in, out);
     return out;
   }
+#else
+  template <typename ViewT>
+  typename fft::Result_rbo<D, I, O, ViewT, workspace, axis, exponent>
+                          ::view_type
+  operator()(ViewT in) VSIP_THROW((std::bad_alloc))
+  {
+    typename base::Scope scope(*this);
+    assert(extent(in) == extent(this->input_size()));
+    typedef fft::Result_rbo<D, I, O, ViewT, workspace, axis, exponent>
+      traits;
+    typedef typename traits::functor_type functor_type;
+    typedef typename traits::block_type   block_type;
+    typedef typename traits::view_type    view_type;
+
+    functor_type rf(in, this->output_size(), *(this->backend_.get()),
+		    workspace_);
+    block_type block(rf);
+    return view_type(block);
+  }
+#endif
 private:
   std::auto_ptr<fft::backend<D, I, O, axis, exponent> > backend_;
   workspace workspace_;
@@ -321,24 +343,55 @@
 #endif
       workspace_(backend_.get(), this->input_size(), this->output_size(), scale)
   {}
-  template <typename BlockT>  
+
+#ifdef VSIP_IMPL_REF_IMPL
+  template <typename BlockT>
   typename fft::result<O,BlockT>::view_type
   operator()(const_Matrix<I,BlockT> in)
-    VSIP_THROW((std::bad_alloc))
+     VSIP_THROW((std::bad_alloc))
   {
     typename base::Scope scope(*this);
     typedef fft::result<O,BlockT> traits;
     typename traits::view_type out(traits::create(this->output_size(),
-						  in.block().map()));
+                                                 in.block().map()));
     assert(extent(in) == extent(this->input_size()));
     if (Is_global_map<typename BlockT::map_type>::value &&
-	in.block().map().num_subblocks(A) != 1)
+        in.block().map().num_subblocks(A) != 1)
       VSIP_IMPL_THROW(unimplemented(
-	"Fftm requires dimension along FFT to not be distributed"));
+        "Fftm requires dimension along FFT to not be distributed"));
     workspace_.by_reference(this->backend_.get(), in.local(), out.local());
     return out;
   }
+#else
+  template <typename BlockT>  
+  typename fft::Result_fftm_rbo<I, O, BlockT, workspace, axis, exponent>
+                          ::view_type
+  operator()(const_Matrix<I,BlockT> in)
+    VSIP_THROW((std::bad_alloc))
+  {
+    typename base::Scope scope(*this);
+    assert(extent(in) == extent(this->input_size()));
 
+    /* TODO: Return_blocks don't have a valid map() yet
+    if (Is_global_map<typename BlockT::map_type>::value &&
+	in.block().map().num_subblocks(A) != 1)
+      VSIP_IMPL_THROW(unimplemented(
+	"Fftm requires dimension along FFT to not be distributed"));
+    */
+
+    typedef fft::Result_fftm_rbo<I, O, BlockT, workspace, axis, exponent>
+      traits;
+    typedef typename traits::functor_type functor_type;
+    typedef typename traits::block_type   block_type;
+    typedef typename traits::view_type    view_type;
+
+    functor_type rf(in, this->output_size(), *(this->backend_.get()),
+		    workspace_);
+    block_type block(rf);
+    return view_type(block);
+ }
+#endif
+
 private:
   std::auto_ptr<typename fft::fftm<I, O, axis, exponent> > backend_;
   workspace workspace_;
Index: src/vsip/core/impl_tags.hpp
===================================================================
--- src/vsip/core/impl_tags.hpp	(revision 164922)
+++ src/vsip/core/impl_tags.hpp	(working copy)
@@ -41,6 +41,8 @@
 struct Copy_tag {};		// Optimized Copy
 struct Op_expr_tag {};		// Special expr handling (vmmul, etc)
 struct Simd_loop_fusion_tag {};	// SIMD Loop Fusion.
+struct Fc_expr_tag {};		// Fused Fastconv RBO evaluator.
+struct Rbo_expr_tag {};		// Return-block expression evaluator.
 struct Loop_fusion_tag {};	// Generic Loop Fusion (base case).
 
 struct Blas_tag {};		// BLAS implementation (ATLAS, MKL, etc)
Index: src/vsip/opt/fft/workspace.hpp
===================================================================
--- src/vsip/opt/fft/workspace.hpp	(revision 164922)
+++ src/vsip/opt/fft/workspace.hpp	(working copy)
@@ -29,6 +29,7 @@
 #include <vsip/core/allocation.hpp>
 #include <vsip/core/equal.hpp>
 #include <vsip/opt/rt_extdata.hpp>
+#include <vsip/opt/expr/serial_dispatch.hpp>
 
 /***********************************************************************
   Declarations
@@ -41,6 +42,75 @@
 namespace fft
 {
 
+/// Utility for scaling values in a block.
+
+template <dimension_type Dim,
+	  typename       T>
+struct Create_scalar_block;
+
+template <typename       T>
+struct Create_scalar_block<1, T>
+{
+  typedef Scalar_block<1, T> type;
+
+  template <typename BlockT>
+  static type create(T scalar, BlockT const& block)
+  {
+    return type(scalar, block.size(1, 0));
+  }
+};
+
+template <typename       T>
+struct Create_scalar_block<2, T>
+{
+  typedef Scalar_block<2, T> type;
+
+  template <typename BlockT>
+  static type create(T scalar, BlockT const& block)
+  {
+    return type(scalar, block.size(2, 0), block.size(2, 1));
+  }
+};
+
+template <typename       T>
+struct Create_scalar_block<3, T>
+{
+  typedef Scalar_block<3, T> type;
+
+  template <typename BlockT>
+  static type create(T scalar, BlockT const& block)
+  {
+    return type(scalar, block.size(3, 0), block.size(3, 1), block.size(3, 2));
+  }
+};
+
+
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       BlockT>
+void
+scale_block(
+  T       scalar,
+  BlockT& block)
+{
+  typedef Scalar_block<Dim, T> scalar_block_type;
+
+  typedef Binary_expr_block<Dim, op::Mult,
+	                BlockT, typename BlockT::value_type,
+	                scalar_block_type, T>
+          expr_block_type;
+
+  scalar_block_type scalar_block(Create_scalar_block<Dim, T>
+				   ::create(scalar, block));
+  expr_block_type   expr_block(block, scalar_block);
+      
+  Serial_dispatch<Dim, BlockT, expr_block_type, vsip::impl::LibraryTagList>
+	::exec(block, expr_block);
+}
+
+
+
 /// This provides the temporary data as well as the
 /// conversion logic from blocks to arrays as expected
 /// by fft backends.
@@ -63,6 +133,7 @@
       ref.pack    = stride_unit_dense;
       ref.order   = Rt_tuple(row1_type());
       ref.complex = cmplx_inter_fmt;
+      ref.align   = 0;
       Rt_layout<1> rtl_in(ref);
       Rt_layout<1> rtl_out(ref);
       backend->query_layout(rtl_in, rtl_out);
@@ -78,6 +149,7 @@
       ref.pack    = stride_unit_dense;
       ref.order   = Rt_tuple(row1_type());
       ref.complex = cmplx_split_fmt;
+      ref.align   = 0;
       Rt_layout<1> rtl_in(ref);
       Rt_layout<1> rtl_out(ref);
       backend->query_layout(rtl_in, rtl_out);
@@ -90,10 +162,72 @@
   }
   
   template <typename BE, typename Block0, typename Block1>
+  void by_reference_blk(
+    BE*           backend,
+    Block0 const& in,
+    Block1&       out)
+    const
+  {
+    typedef typename Proper_type_of<Block0>::type proper_block0_type;
+
+    // Find out about the blocks's actual layout.
+    Rt_layout<1> rtl_in  = block_layout<1>(in);
+    Rt_layout<1> rtl_out = block_layout<1>(out);
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+
+    // Check whether the input buffer will be destroyed (and hence
+    // should be a copy), or whether the input block aliases the
+    // output (and hence should be a copy).
+    //
+    // The input and output may alias when using return-block
+    // optimization for by-value Fft: 'A = fft(A)'.
+    sync_action_type in_sync =
+      (backend->requires_copy(rtl_in) || is_alias(in, out))
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN; 
+
+    {
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<proper_block0_type> in_ext(in, rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out, rtl_out, SYNC_OUT,
+				  output_buffer_.get());
+    
+      // Call the backend.
+      assert(rtl_in.complex == rtl_out.complex);
+      if (rtl_in.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_inter(), in_ext.stride(0),
+			      out_ext.data().as_inter(), out_ext.stride(0),
+			      in_ext.size(0));
+      else
+	backend->by_reference(in_ext.data().as_split(), in_ext.stride(0),
+			      out_ext.data().as_split(), out_ext.stride(0),
+			      in_ext.size(0));
+    }
+
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      scale_block<1>(scale_, out);
+  }
+
+  template <typename BE, typename Block0, typename Block1>
   void by_reference(BE *backend,
 		    const_Vector<std::complex<T>, Block0>& in,
 		    Vector<std::complex<T>, Block1>& out)
+    const
   {
+#if 0
+    // Unfortunately, calling by_reference_blk adds performance
+    // overhead for small FFT sizes.
+    //
+    // 0703012: On a 2 GHz PPC 970FX, with FFTW 3.1.2, using 'fft -1'
+    //  - implement inline.      16-point FFT: 1751 MFLOP/s (baseline)
+    //  - call by_reference_blk. 16-point FFT: 1186 MFLOP/s (-32.2%)
+
+    by_reference_blk<BE, Block0, Block1>(backend, in.block(), out.block());
+#else
     typedef typename Block_layout<Block0>::complex_type complex_type;
     typedef Layout<1, row1_type, Stride_unit, complex_type> LP;
 
@@ -148,8 +282,10 @@
       }
     }
     // Scale the data if not already done by the backend.
+
     if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
       out *= scale_;
+#endif
   }
 
   template <typename BE, typename BlockT>
@@ -178,6 +314,8 @@
       inout *= scale_;
   }
 
+  T scale() const { return scale_; }
+
 private:
   T scale_;
   aligned_array<std::complex<T> > input_buffer_;
@@ -202,6 +340,7 @@
   void by_reference(BE *backend,
 		    const_Vector<T, Block0> in,
 		    Vector<std::complex<T>, Block1> out)
+    const
   {
     // Find out about the blocks's actual layout.
     Rt_layout<1> rtl_in = block_layout<1>(in.block()); 
@@ -236,6 +375,50 @@
       out *= scale_;
   }
 
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference_blk(
+    BE*           backend,
+    Block0 const& in,
+    Block1&       out)
+    const
+  {
+    typedef typename Proper_type_of<Block0>::type block0_type;
+
+    // Find out about the blocks's actual layout.
+    Rt_layout<1> rtl_in = block_layout<1>(in); 
+    Rt_layout<1> rtl_out = block_layout<1>(out); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN; 
+    {
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<block0_type> in_ext(in, rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out, rtl_out, SYNC_OUT,
+				  output_buffer_.get());
+    
+      // Call the backend.
+      if (rtl_out.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_real(), in_ext.stride(0),
+			      out_ext.data().as_inter(), out_ext.stride(0),
+			      in_ext.size(0));
+      else
+	backend->by_reference(in_ext.data().as_real(), in_ext.stride(0),
+			      out_ext.data().as_split(), out_ext.stride(0),
+			      in_ext.size(0));
+    }
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      scale_block<1>(scale_, out);
+  }
+
+  T scale() const { return scale_; }
+
 private:
   T scale_;
   aligned_array<T> input_buffer_;
@@ -257,6 +440,7 @@
   void by_reference(BE *backend,
 		    const_Vector<std::complex<T>, Block0> in,
 		    Vector<T, Block1> out)
+    const
   {
     // Find out about the blocks's actual layout.
     Rt_layout<1> rtl_in = block_layout<1>(in.block()); 
@@ -291,6 +475,48 @@
       out *= scale_;
   }
 
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference_blk(
+    BE*           backend,
+    Block0 const& in,
+    Block1&       out)
+    const
+  {
+    // Find out about the blocks's actual layout.
+    Rt_layout<1> rtl_in = block_layout<1>(in); 
+    Rt_layout<1> rtl_out = block_layout<1>(out); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN;
+    { 
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in, rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out, rtl_out, SYNC_OUT,
+				  output_buffer_.get());
+    
+      // Call the backend.
+      if (rtl_in.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_inter(), in_ext.stride(0),
+			      out_ext.data().as_real(), out_ext.stride(0),
+			      out_ext.size(0));
+      else
+	backend->by_reference(in_ext.data().as_split(), in_ext.stride(0),
+			      out_ext.data().as_real(), out_ext.stride(0),
+			      out_ext.size(0));
+    }
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      scale_block<1>(scale_, out);
+  }
+
+  T scale() const { return scale_; }
+
 private:
   T scale_;
   aligned_array<std::complex<T> > input_buffer_;
@@ -312,6 +538,7 @@
   void by_reference(BE *backend,
 		    const_Matrix<std::complex<T>, Block0> in,
 		    Matrix<std::complex<T>, Block1> out)
+    const
   {
     // Find out about the blocks's actual layout.
     Rt_layout<2> rtl_in = block_layout<2>(in.block()); 
@@ -351,6 +578,60 @@
       out *= scale_;
   }
 
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference_blk(
+    BE*           backend,
+    Block0 const& in,
+    Block1&       out)
+    const
+  {
+    typedef typename Proper_type_of<Block0>::type proper_block0_type;
+
+    // Find out about the blocks's actual layout.
+    Rt_layout<2> rtl_in  = block_layout<2>(in);
+    Rt_layout<2> rtl_out = block_layout<2>(out);
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+
+    // Check whether the input buffer will be destroyed (and hence
+    // should be a copy), or whether the input block aliases the
+    // output (and hence should be a copy).
+    //
+    // The input and output may alias when using return-block
+    // optimization for by-value Fft: 'A = fft(A)'.
+    sync_action_type in_sync =
+      (backend->requires_copy(rtl_in) || is_alias(in, out))
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN; 
+    {
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<proper_block0_type> in_ext(in, rtl_in, in_sync,
+					     input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out, rtl_out, SYNC_OUT,
+				  output_buffer_.get());
+    
+      // Call the backend.
+      assert(rtl_in.complex == rtl_out.complex);
+      if (rtl_in.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_inter(),
+			      in_ext.stride(0), in_ext.stride(1),
+			      out_ext.data().as_inter(),
+			      out_ext.stride(0), out_ext.stride(1),
+			      in_ext.size(0), in_ext.size(1));
+      else
+	backend->by_reference(in_ext.data().as_split(),
+			      in_ext.stride(0), in_ext.stride(1),
+			      out_ext.data().as_split(),
+			      out_ext.stride(0), out_ext.stride(1),
+			      in_ext.size(0), in_ext.size(1));
+    }
+
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      scale_block<2>(scale_, out);
+  }
+
   template <typename BE, typename BlockT>
   void in_place(BE *backend, Matrix<std::complex<T>,BlockT> inout)
   {
@@ -379,6 +660,8 @@
       inout *= scale_;
   }
 
+  T scale() const { return scale_; }
+
 private:
   T scale_;
   aligned_array<std::complex<T> > input_buffer_;
@@ -400,6 +683,7 @@
   void by_reference(BE *backend,
 		    const_Matrix<T, Block0> in,
 		    Matrix<std::complex<T>, Block1> out)
+    const
   {
     // Find out about the blocks's actual layout.
     Rt_layout<2> rtl_in = block_layout<2>(in.block()); 
@@ -437,6 +721,51 @@
       out *= scale_;
   }
 
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference_blk(
+    BE*           backend,
+    Block0 const& in,
+    Block1&       out)
+    const
+  {
+    // Find out about the blocks's actual layout.
+    Rt_layout<2> rtl_in = block_layout<2>(in);
+    Rt_layout<2> rtl_out = block_layout<2>(out);
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN; 
+    {
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in, rtl_in, in_sync, 
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out, rtl_out, SYNC_OUT,
+				  output_buffer_.get());
+    
+      // Call the backend.
+      if (rtl_out.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_real(),
+			      in_ext.stride(0), in_ext.stride(1),
+			      out_ext.data().as_inter(),
+			      out_ext.stride(0), out_ext.stride(1),
+			      in_ext.size(0), in_ext.size(1));
+      else
+	backend->by_reference(in_ext.data().as_real(),
+			      in_ext.stride(0), in_ext.stride(1),
+			      out_ext.data().as_split(),
+			      out_ext.stride(0), out_ext.stride(1),
+			      in_ext.size(0), in_ext.size(1));
+    }
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      scale_block<2>(scale_, out);
+  }
+
+  T scale() const { return scale_; }
+
 private:
   T scale_;
   aligned_array<T> input_buffer_;
@@ -458,6 +787,7 @@
   void by_reference(BE *backend,
 		    const_Matrix<std::complex<T>, Block0> in,
 		    Matrix<T, Block1> out)
+    const
   {
     // Find out about the blocks's actual layout.
     Rt_layout<2> rtl_in = block_layout<2>(in.block()); 
@@ -495,6 +825,51 @@
       out *= scale_;
   }
 
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference_blk(
+    BE*           backend,
+    Block0 const& in,
+    Block1&       out)
+    const
+  {
+    // Find out about the blocks's actual layout.
+    Rt_layout<2> rtl_in = block_layout<2>(in); 
+    Rt_layout<2> rtl_out = block_layout<2>(out); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN;
+    { 
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in, rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out, rtl_out, SYNC_OUT,
+				  output_buffer_.get());
+    
+      // Call the backend.
+      if (rtl_in.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_inter(),
+			      in_ext.stride(0), in_ext.stride(1),
+			      out_ext.data().as_real(),
+			      out_ext.stride(0), out_ext.stride(1),
+			      out_ext.size(0), out_ext.size(1));
+      else
+	backend->by_reference(in_ext.data().as_split(),
+			      in_ext.stride(0), in_ext.stride(1),
+			      out_ext.data().as_real(),
+			      out_ext.stride(0), out_ext.stride(1),
+			      out_ext.size(0), out_ext.size(1));
+    }
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      scale_block<2>(scale_, out);
+  }
+
+  T scale() const { return scale_; }
+
 private:
   T scale_;
   aligned_array<std::complex<T> > input_buffer_;
@@ -513,9 +888,67 @@
   {}
   
   template <typename BE, typename Block0, typename Block1>
+  void by_reference_blk(
+    BE*           backend,
+    Block0 const& in,
+    Block1&       out)
+    const
+  {
+    // Find out about the blocks's actual layout.
+    Rt_layout<3> rtl_in = block_layout<3>(in); 
+    Rt_layout<3> rtl_out = block_layout<3>(out); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN; 
+    {
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in, rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out, rtl_out, SYNC_OUT,
+				  output_buffer_.get());
+    
+      // Call the backend.
+      assert(rtl_in.complex == rtl_out.complex);
+      if (rtl_in.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_inter(),
+			      in_ext.stride(0),
+			      in_ext.stride(1),
+			      in_ext.stride(2),
+			      out_ext.data().as_inter(),
+			      out_ext.stride(0),
+			      out_ext.stride(1),
+			      out_ext.stride(2),
+			      in_ext.size(0),
+			      in_ext.size(1),
+			      in_ext.size(2));
+      else
+	backend->by_reference(in_ext.data().as_split(),
+			      in_ext.stride(0),
+			      in_ext.stride(1),
+			      in_ext.stride(2),
+			      out_ext.data().as_split(),
+			      out_ext.stride(0),
+			      out_ext.stride(1),
+			      out_ext.stride(2),
+			      in_ext.size(0),
+			      in_ext.size(1),
+			      in_ext.size(2));
+    }
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      scale_block<3>(scale_, out);
+  }
+
+  template <typename BE, typename Block0, typename Block1>
   void by_reference(BE *backend,
 		    const_Tensor<std::complex<T>, Block0> in,
 		    Tensor<std::complex<T>, Block1> out)
+    const
   {
     // Find out about the blocks's actual layout.
     Rt_layout<3> rtl_in = block_layout<3>(in.block()); 
@@ -603,6 +1036,8 @@
       inout *= scale_;
   }
 
+  T scale() const { return scale_; }
+
 private:
   T scale_;
   aligned_array<std::complex<T> > input_buffer_;
@@ -621,9 +1056,65 @@
   {}
   
   template <typename BE, typename Block0, typename Block1>
+  void by_reference_blk(
+    BE*           backend,
+    Block0 const& in,
+    Block1&       out)
+    const
+  {
+    // Find out about the blocks's actual layout.
+    Rt_layout<3> rtl_in = block_layout<3>(in); 
+    Rt_layout<3> rtl_out = block_layout<3>(out); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN; 
+    {
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in, rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out, rtl_out, SYNC_OUT,
+				  output_buffer_.get());
+    
+      // Call the backend.
+      if (rtl_out.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_real(),
+			      in_ext.stride(0),
+			      in_ext.stride(1),
+			      in_ext.stride(2),
+			      out_ext.data().as_inter(),
+			      out_ext.stride(0),
+			      out_ext.stride(1),
+			      out_ext.stride(2),
+			      in_ext.size(0),
+			      in_ext.size(1),
+			      in_ext.size(2));
+      else
+	backend->by_reference(in_ext.data().as_real(),
+			      in_ext.stride(0),
+			      in_ext.stride(1),
+			      in_ext.stride(2),
+			      out_ext.data().as_split(),
+			      out_ext.stride(0),
+			      out_ext.stride(1),
+			      out_ext.stride(2),
+			      in_ext.size(0),
+			      in_ext.size(1),
+			      in_ext.size(2));
+    }
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      scale_block<3>(scale_, out);
+  }
+
+  template <typename BE, typename Block0, typename Block1>
   void by_reference(BE *backend,
 		    const_Tensor<T, Block0> in,
 		    Tensor<std::complex<T>, Block1> out)
+    const
   {
     // Find out about the blocks's actual layout.
     Rt_layout<3> rtl_in = block_layout<3>(in.block()); 
@@ -673,6 +1164,8 @@
       out *= scale_;
   }
 
+  T scale() const { return scale_; }
+
 private:
   T scale_;
   aligned_array<T> input_buffer_;
@@ -691,9 +1184,65 @@
   {}
   
   template <typename BE, typename Block0, typename Block1>
+  void by_reference_blk(
+    BE*           backend,
+    Block0 const& in,
+    Block1&       out)
+    const
+  {
+    // Find out about the blocks's actual layout.
+    Rt_layout<3> rtl_in = block_layout<3>(in); 
+    Rt_layout<3> rtl_out = block_layout<3>(out); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN;
+    { 
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in, rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out, rtl_out, SYNC_OUT,
+				  output_buffer_.get());
+    
+      // Call the backend.
+      if (rtl_in.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_inter(),
+			      in_ext.stride(0),
+			      in_ext.stride(1),
+			      in_ext.stride(2),
+			      out_ext.data().as_real(),
+			      out_ext.stride(0),
+			      out_ext.stride(1),
+			      out_ext.stride(2),
+			      out_ext.size(0),
+			      out_ext.size(1),
+			      out_ext.size(2));
+      else
+	backend->by_reference(in_ext.data().as_split(),
+			      in_ext.stride(0),
+			      in_ext.stride(1),
+			      in_ext.stride(2),
+			      out_ext.data().as_real(),
+			      out_ext.stride(0),
+			      out_ext.stride(1),
+			      out_ext.stride(2),
+			      out_ext.size(0),
+			      out_ext.size(1),
+			      out_ext.size(2));
+    }
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      scale_block<3>(scale_, out);
+  }
+
+  template <typename BE, typename Block0, typename Block1>
   void by_reference(BE *backend,
 		    const_Tensor<std::complex<T>, Block0> in,
 		    Tensor<T, Block1> out)
+    const
   {
     // Find out about the blocks's actual layout.
     Rt_layout<3> rtl_in = block_layout<3>(in.block()); 
@@ -743,6 +1292,8 @@
       out *= scale_;
   }
 
+  T scale() const { return scale_; }
+
 private:
   T scale_;
   aligned_array<std::complex<T> > input_buffer_;
Index: src/vsip/opt/fft/return_functor.hpp
===================================================================
--- src/vsip/opt/fft/return_functor.hpp	(revision 0)
+++ src/vsip/opt/fft/return_functor.hpp	(revision 0)
@@ -0,0 +1,234 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/fft/return_functor.cpp
+    @author  Jules Bergmann
+    @date    2007-03-09
+    @brief   VSIPL++ Library: FFT functor for Return_expr_blocks.
+*/
+
+#ifndef VSIP_OPT_FFT_RETURN_FUNCTOR_HPP
+#define VSIP_OPT_FFT_RETURN_FUNCTOR_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <vsip/core/block_traits.hpp>
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
+namespace fft
+{
+
+/// Return functor class for Fft.
+
+/// Captures invocation of Fft object on an input block for later
+/// evaluation, once the destination block is known.
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       BlockT,
+	  typename       BackendT,
+	  typename       WorkspaceT>
+class Fft_return_functor
+{
+  // Compile-time typedefs.
+public:
+  typedef BlockT                                              block_type;
+  typedef typename block_type::map_type                       map_type;
+  typedef typename View_block_storage<block_type>::plain_type block_ref_type;
+
+  typedef Fft_return_functor<Dim, T, 
+			     typename Distributed_local_block<BlockT>::type,
+			     BackendT, WorkspaceT> local_type;
+
+  // Constructors.
+public:
+  template <typename GivenViewT>
+  Fft_return_functor(
+    GivenViewT         in_view,
+    Domain<Dim> const& output_size,
+    BackendT&          backend,
+    WorkspaceT&        workspace)
+  : in_block_   (in_view.block()),
+    output_size_(output_size),
+    backend_    (backend),
+    workspace_  (workspace)
+  {}
+
+  Fft_return_functor(
+    block_ref_type     in_block,
+    Domain<Dim> const& output_size,
+    BackendT&          backend,
+    WorkspaceT&        workspace)
+  : in_block_   (in_block),
+    output_size_(output_size),
+    backend_    (backend),
+    workspace_  (workspace)
+  {}
+
+  Fft_return_functor(Fft_return_functor const& rhs)
+    : in_block_   (rhs.in_block_),
+      output_size_(rhs.output_size_),
+      backend_    (rhs.backend_),
+      workspace_  (rhs.workspace_)
+  {}
+
+  // Accessors
+public:
+  template <typename ResBlockT>
+  void apply(ResBlockT& result) const
+  {
+    workspace_.by_reference_blk(&backend_, in_block_, result);
+  }
+
+  length_type size() const
+  {
+    return output_size_.size();
+  }
+
+  length_type size(dimension_type block_dim, dimension_type d) const
+  {
+    assert(block_dim == Dim);
+    return output_size_[d].size();
+  }
+
+  local_type local() const
+  {
+    return local_type(get_local_block(in_block_),
+		      output_size_, // TODO FIX
+		      backend_,
+		      workspace_);
+  }
+
+  map_type   const& map()       const { return in_block_.map(); }
+  block_type const& block()     const { return in_block_; }
+  BackendT   const& backend()   const { return backend_; }
+  WorkspaceT const& workspace() const { return workspace_; }
+
+// Member data.
+private:
+  block_ref_type in_block_;
+  Domain<Dim>    output_size_;
+  BackendT&      backend_;
+  WorkspaceT&    workspace_;
+};
+
+} // namespace vsip::impl::fft
+
+
+
+// Specliaze parallel block traits for Fft_return_functor.
+
+template <typename       CombineT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       BlockT,
+	  typename       BackendT,
+	  typename       WorkspaceT>
+struct Combine_return_type<CombineT,
+	fft::Fft_return_functor<Dim, T, BlockT, BackendT, WorkspaceT> const>
+{
+  typedef fft::Fft_return_functor<Dim, T,
+		typename Combine_return_type<CombineT, BlockT>::tree_type,
+		BackendT, WorkspaceT> const
+          tree_type;
+  typedef tree_type type;
+};
+
+
+
+template <typename       CombineT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       BlockT,
+	  typename       BackendT,
+	  typename       WorkspaceT>
+struct Combine_return_type<CombineT,
+	fft::Fft_return_functor<Dim, T, BlockT, BackendT, WorkspaceT> >
+{
+  typedef fft::Fft_return_functor<Dim, T,
+		typename Combine_return_type<CombineT, BlockT>::tree_type,
+		BackendT, WorkspaceT> const
+          tree_type;
+  typedef tree_type type;
+};
+
+
+
+template <typename       CombineT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       BlockT,
+	  typename       BackendT,
+	  typename       WorkspaceT>
+typename Combine_return_type<CombineT,
+	fft::Fft_return_functor<Dim, T, BlockT, BackendT, WorkspaceT> >::type
+apply_combine(
+  CombineT const&                                                      combine,
+  fft::Fft_return_functor<Dim, T, BlockT, BackendT, WorkspaceT> const& rf)
+{
+  typedef typename
+    Combine_return_type<
+		CombineT,
+		fft::Fft_return_functor<Dim, T, BlockT, BackendT, WorkspaceT>
+	>::type rf_type;
+
+  return rf_type(apply_combine(combine, rf.in_block()),
+		 rf.backend(), rf.workspace());
+}
+
+
+
+template <typename       VisitorT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       BlockT,
+	  typename       BackendT,
+	  typename       WorkspaceT>
+void
+apply_leaf(
+  VisitorT const&                                                      visitor,
+  fft::Fft_return_functor<Dim, T, BlockT, BackendT, WorkspaceT> const& rf)
+{
+  apply_leaf(visitor, rf.in_block());
+}
+
+
+
+template <dimension_type MapDim,
+	  typename       MapT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       BlockT,
+	  typename       BackendT,
+	  typename       WorkspaceT>
+struct Is_par_same_map<MapDim, MapT,
+	fft::Fft_return_functor<Dim, T, BlockT, BackendT, WorkspaceT> const>
+{
+  typedef fft::Fft_return_functor<Dim, T, BlockT, BackendT, WorkspaceT> const
+          rf_type;
+
+  static bool value(MapT const& map, rf_type& rf)
+  {
+    return Is_par_same_map<MapDim, MapT, BlockT>::value(map, rf.in_block());
+  }
+};
+
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_FFT_RETURN_FUNCTOR_HPP
Index: src/vsip/opt/extdata.hpp
===================================================================
--- src/vsip/opt/extdata.hpp	(revision 164922)
+++ src/vsip/opt/extdata.hpp	(working copy)
@@ -386,14 +386,17 @@
   typedef typename Block_layout<Block>::access_type access_type;
   typedef Access_demotion<access_type>              demotion_type;
 
-  typedef typename
+  typedef
   choose_access::CA_General<demotion_type,
 	     typename Block_layout<Block>::order_type,
 	     typename Block_layout<Block>::pack_type,
 	     typename Block_layout<Block>::complex_type,
              typename LP::order_type,
              typename LP::pack_type,
-	     typename LP::complex_type>::type type;
+	     typename LP::complex_type> ca_type;
+
+  typedef typename ca_type::type type;
+  typedef typename ca_type::reason_type reason_type;
 };
 
 } // namespace vsip::impl
Index: src/vsip/opt/rt_extdata.hpp
===================================================================
--- src/vsip/opt/rt_extdata.hpp	(revision 164922)
+++ src/vsip/opt/rt_extdata.hpp	(working copy)
@@ -178,6 +178,56 @@
 
 
 
+template <typename Block1T,
+	  typename Block2T,
+	  bool Is_direct = 
+	     Type_equal<typename Block_layout<Block1T>::access_type,
+			Direct_access_tag>::value &&
+	     Type_equal<typename Block_layout<Block2T>::access_type,
+			Direct_access_tag>::value,
+	  bool Is_split1 = Is_split_block<Block1T>::value,
+	  bool Is_split2 = Is_split_block<Block2T>::value>
+struct Is_alias_helper
+{
+  static bool value(Block1T const&, Block2T const&) { return false; }
+};
+
+template <typename Block1T,
+	  typename Block2T>
+struct Is_alias_helper<Block1T, Block2T, true, false, false>
+{
+  static bool value(Block1T const& blk1, Block2T const& blk2)
+  { return blk1.impl_data() == blk2.impl_data(); }
+};
+
+template <typename Block1T,
+	  typename Block2T>
+struct Is_alias_helper<Block1T, Block2T, true, true, true>
+{
+  static bool value(Block1T const& blk1, Block2T const& blk2)
+  {
+    return blk1.impl_data().first == blk2.impl_data().first &&
+           blk1.impl_data().second == blk2.impl_data().second;
+  }
+};
+
+
+
+/// Check if two blocks may potentially alias each other when using
+/// Ext_data.
+
+template <typename Block1T,
+	  typename Block2T>
+bool
+is_alias(
+  Block1T const& blk1,
+  Block2T const& blk2)
+{
+  return Is_alias_helper<Block1T, Block2T>::value(blk1, blk2);
+}
+
+
+
 namespace data_access
 {
 
@@ -426,8 +476,12 @@
   void begin(Block* blk, bool sync)
   {
     if (sync)
+    {
+      do_loop_fusion_init(*blk);
       Rt_block_copy_to_ptr<Dim, Block>::copy(blk, app_layout_,
 					     storage_.data());
+      do_loop_fusion_fini(*blk);
+    }
   }
 
   void end(Block* blk, bool sync)
Index: src/vsip/opt/choose_access.hpp
===================================================================
--- src/vsip/opt/choose_access.hpp	(revision 164922)
+++ src/vsip/opt/choose_access.hpp	(working copy)
@@ -1,10 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    vsip/opt/choose-access.hpp
+/** @file    vsip/opt/choose_access.hpp
     @author  Jules Bergmann
     @date    2005-04-13
     @brief   VSIPL++ Library: Template mechanism to choose the appropriate
@@ -39,6 +39,46 @@
 namespace choose_access
 {
 
+
+
+/// Specialized If-Then-Else class for Choose_asses.  Chooses either
+/// IfType::type or ElseType::type based on boolean predicate.  Also
+/// track reason_type.
+
+template <bool     Predicate,
+	  typename IfType,
+	  typename ElseType>
+struct ITE_type_reason;
+
+template <typename IfType,
+	  typename ElseType>
+struct ITE_type_reason<true, IfType, ElseType>
+{
+  typedef typename IfType::type        type;
+  typedef typename IfType::reason_type reason_type;
+};
+
+template <typename IfType,
+	  typename ElseType>
+struct ITE_type_reason<false, IfType, ElseType>
+{
+  typedef typename ElseType::type        type;
+  typedef typename ElseType::reason_type reason_type;
+};
+
+
+
+/// Wrap a type so that it can be accessed via ::type.
+
+template <typename T, typename ReasonT>
+struct As_type_reason
+{
+  typedef T       type;
+  typedef ReasonT reason_type;
+};
+
+
+
 /// Check if two Pack_types are
 ///  (a) both Stride_unit_align, and
 ///  (b) have the same alignment.
@@ -58,23 +98,53 @@
 
 
 
+// Reason tags.
+
+struct CA_Eq_cmplx_eq_order_unknown_stride_ok;
+struct CA_Eq_cmplx_eq_order_unit_stride_ok;
+struct CA_Eq_cmplx_eq_order_unit_stride_dense_ok;
+struct CA_Eq_cmplx_eq_order_unit_stride_align_ok;
+struct CA_Eq_cmplx_eq_order_different_stride;
+struct CA_Eq_cmplx_different_dim_order_but_both_dense;
+struct CA_Eq_cmplx_different_dim_order;
+struct CA_General_different_complex_layout;
+
+
+
 template <typename       Demotion,
 	  typename       Pack1,
 	  typename       Pack2>
 struct CA_Eq_cmplx_eq_order
 {
+  typedef CA_Eq_cmplx_eq_order_unknown_stride_ok    reason1_type;
+  typedef CA_Eq_cmplx_eq_order_unit_stride_ok       reason2_type;
+  typedef CA_Eq_cmplx_eq_order_unit_stride_dense_ok reason3_type;
+  typedef CA_Eq_cmplx_eq_order_unit_stride_align_ok reason4_type;
+  typedef CA_Eq_cmplx_eq_order_different_stride     reason5_type;
+
   typedef typename Demotion::direct_type  direct_type;
   typedef typename Demotion::reorder_type reorder_type;
   typedef typename Demotion::flex_type    flex_type;
 
-  typedef typename
-  ITE_Type<Type_equal<Pack2, Stride_unknown>::value,   As_type<direct_type>,
-  ITE_Type< Type_equal<Pack2, Stride_unit>::value &&
-           !Type_equal<Pack1, Stride_unknown>::value,  As_type<direct_type>,
-  ITE_Type<Type_equal<Pack2, Stride_unit_dense>::value &&
-           Type_equal<Pack1, Stride_unit_dense>::value, As_type<direct_type>,
-  ITE_Type<CA_Equal_stride_unit_align<Pack1, Pack2>::value, As_type<direct_type>,
-	   As_type<flex_type> > > > >::type type;
+  typedef 
+  ITE_type_reason<Type_equal<Pack2, Stride_unknown>::value,
+	As_type_reason<direct_type, reason1_type>,
+
+  ITE_type_reason< Type_equal<Pack2, Stride_unit>::value &&
+                  !Type_equal<Pack1, Stride_unknown>::value,
+	As_type_reason<direct_type, reason2_type>,
+
+  ITE_type_reason<Type_equal<Pack2, Stride_unit_dense>::value &&
+                  Type_equal<Pack1, Stride_unit_dense>::value,
+	As_type_reason<direct_type, reason3_type>,
+
+  ITE_type_reason<CA_Equal_stride_unit_align<Pack1, Pack2>::value,
+	As_type_reason<direct_type, reason4_type>,
+
+	As_type_reason<flex_type, reason5_type> > > > > ite_type;
+
+  typedef typename ite_type::type        type;
+  typedef typename ite_type::reason_type reason_type;
 };
 
 
@@ -85,21 +155,27 @@
 	  typename       Pack2>
 struct CA_Eq_cmplx
 {
+  typedef CA_Eq_cmplx_different_dim_order_but_both_dense reason1_type;
+  typedef CA_Eq_cmplx_different_dim_order                reason2_type;
+
   typedef typename Demotion::reorder_type reorder_type;
   typedef typename Demotion::flex_type    flex_type;
 
   // If layouts have different dimension-ordering, then
   //   reorder access if they are both dense,
   //   copy access    otherwise
-  typedef typename
-          ITE_Type<Type_equal<Order1, Order2>::value,
-		   CA_Eq_cmplx_eq_order<Demotion, Pack1, Pack2>,
-		   ITE_Type<Type_equal<Pack1, Stride_unit_dense>::value &&
-                            Type_equal<Pack2, Stride_unit_dense>::value,
-                            As_type<reorder_type>, As_type<flex_type>
-                           >
-                  >::type
-		type;
+  typedef 
+          ITE_type_reason<Type_equal<Order1, Order2>::value,
+		CA_Eq_cmplx_eq_order<Demotion, Pack1, Pack2>,
+		ITE_type_reason<Type_equal<Pack1, Stride_unit_dense>::value &&
+                                Type_equal<Pack2, Stride_unit_dense>::value,
+                        As_type_reason<reorder_type, reason1_type>,
+			As_type_reason<flex_type, reason2_type>
+                        >
+                > ite_type;
+
+  typedef typename ite_type::type        type;
+  typedef typename ite_type::reason_type reason_type;
 };
 
 
@@ -113,12 +189,18 @@
 	  typename       Cmplx2>
 struct CA_General
 {
+  typedef CA_General_different_complex_layout my_reason_type;
+
   // If layouts do not have same complex layout, then copy access
-  typedef typename
-          ITE_Type<Type_equal<Cmplx1, Cmplx2>::value,
-		   CA_Eq_cmplx<Demotion, Order1, Pack1, Order2, Pack2>,
-		   As_type<typename Demotion::copy_type> >::type
-		type;
+  typedef
+          ITE_type_reason<Type_equal<Cmplx1, Cmplx2>::value,
+			  CA_Eq_cmplx<Demotion, Order1, Pack1, Order2, Pack2>,
+			  As_type_reason<typename Demotion::copy_type,
+					 my_reason_type> >
+		ite_type;
+
+  typedef typename ite_type::type        type;
+  typedef typename ite_type::reason_type reason_type;
 };
 
 } // namespace vsip::impl::choose_access
Index: src/vsip/opt/cbe/ppu/eval_fastconv.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/eval_fastconv.hpp	(revision 0)
+++ src/vsip/opt/cbe/ppu/eval_fastconv.hpp	(revision 0)
@@ -0,0 +1,116 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/cbe/ppu/eval_fastconv.hpp
+    @author  Jules Bergmann
+    @date    2007-03-05
+    @brief   VSIPL++ Library: General evaluator for fast convolution
+
+*/
+
+#ifndef VSIP_OPT_CBE_PPU_EVAL_FASTCONV_HPP
+#define VSIP_OPT_CBE_PPU_EVAL_FASTCONV_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <vsip/core/fft.hpp>
+#include <vsip/opt/expr/return_block.hpp>
+#include <vsip/opt/cbe/ppu/fastconv.hpp>
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
+/// Evaluator for return expression block.
+
+template <typename       DstBlock,
+	  typename       T,
+	  typename       VecBlockT,
+	  typename       MatBlockT,
+	  typename       Backend1T,
+	  typename       Workspace1T,
+	  typename       Backend2T,
+	  typename       Workspace2T>
+struct Serial_expr_evaluator<2, DstBlock,
+  const Return_expr_block<2, T,
+    fft::Fft_return_functor<2, T,
+      const_Matrix<T,
+        const Vmmul_expr_block<0,
+          VecBlockT,
+          const Return_expr_block<2, T,
+            fft::Fft_return_functor<2, T,
+              const_Matrix<T, MatBlockT>,
+              Backend2T, Workspace2T>
+            >
+          >
+        >,
+      Backend1T, Workspace1T>
+    >,
+  Cbe_sdk_tag
+  >
+{
+  static char const* name() { return "Cbe_sdk_tag"; }
+
+  typedef
+  Return_expr_block<2, T,
+    fft::Fft_return_functor<2, T,
+      const_Matrix<T,
+        const Vmmul_expr_block<0,
+          VecBlockT,
+          const Return_expr_block<2, T,
+            fft::Fft_return_functor<2, T,
+              const_Matrix<T, MatBlockT>,
+              Backend2T, Workspace2T>
+            >
+          >
+        >,
+      Backend1T, Workspace1T>
+    >
+    SrcBlock;
+
+  typedef typename DstBlock::value_type dst_type;
+  typedef typename SrcBlock::value_type src_type;
+
+  static bool const ct_valid = true;
+
+  static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
+  {
+    return true;
+  }
+  
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    // length_type rows = dst.size(2, 0);
+    length_type cols = dst.size(2, 1);
+    Matrix<T> tmp(1, cols);
+
+    Vector<T, VecBlockT> w  (
+      const_cast<VecBlockT&>(src.rf_.in_block_.get_vblk()));
+    Matrix<T, MatBlockT> in (
+      const_cast<MatBlockT&>(src.rf_.in_block_.get_mblk().rf_.in_block_));
+    Matrix<T, DstBlock>        out(dst);
+
+    typedef typename Block_layout<DstBlock>::complex_type complex_type;
+    typedef impl::cbe::Fastconv<T, complex_type>          fconv_type;
+
+    fconv_type fconv(w, cols);
+
+    fconv(in, out);
+  }
+};
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_OPT_CBE_PPU_EVAL_FASTCONV_HPP
Index: src/vsip/opt/cbe/ppu/fastconv.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.hpp	(revision 164924)
+++ src/vsip/opt/cbe/ppu/fastconv.hpp	(working copy)
@@ -20,7 +20,6 @@
 #include <vsip/core/allocation.hpp>
 #include <vsip/core/config.hpp>
 #include <vsip/core/extdata.hpp>
-#include <vsip/math.hpp>
 #include <vsip/opt/cbe/ppu/bindings.hpp>
 #include <vsip/opt/cbe/ppu/task_manager.hpp>
 extern "C"
Index: src/vsip/opt/diag/extdata.hpp
===================================================================
--- src/vsip/opt/diag/extdata.hpp	(revision 0)
+++ src/vsip/opt/diag/extdata.hpp	(revision 0)
@@ -0,0 +1,113 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/diag/eval_vcmp.hpp
+    @author  Jules Bergmann
+    @date    2007-03-06
+    @brief   VSIPL++ Library: Diagnostics for extdata.
+*/
+
+#ifndef VSIP_OPT_DIAG_EXTDATAL_HPP
+#define VSIP_OPT_DIAG_EXTDATAL_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <iomanip>
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
+
+
+namespace diag_detail
+{
+
+// Helper class to return the name corresponding to a dispatch tag.
+
+template <typename T> 
+struct Class_name
+{
+  static std::string name() { return "unknown"; }
+};
+
+#define VSIP_IMPL_CLASS_NAME(TYPE)				\
+  template <>							\
+  struct Class_name<TYPE> {					\
+    static std::string name() { return "" # TYPE; }		\
+  };
+
+VSIP_IMPL_CLASS_NAME(Direct_access_tag)
+VSIP_IMPL_CLASS_NAME(Reorder_access_tag)
+VSIP_IMPL_CLASS_NAME(Copy_access_tag)
+VSIP_IMPL_CLASS_NAME(Flexible_access_tag)
+VSIP_IMPL_CLASS_NAME(Bogus_access_tag)
+VSIP_IMPL_CLASS_NAME(Default_access_tag)
+
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_eq_order_unknown_stride_ok)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_eq_order_unit_stride_ok)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_eq_order_unit_stride_dense_ok)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_eq_order_unit_stride_align_ok)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_eq_order_different_stride)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_different_dim_order_but_both_dense)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_different_dim_order)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_General_different_complex_layout)
+
+VSIP_IMPL_CLASS_NAME(Cmplx_inter_fmt)
+VSIP_IMPL_CLASS_NAME(Cmplx_split_fmt)
+
+} // namespace vsip::impl::diag_detail
+
+
+
+template <typename BlockT,
+	  typename LP  = typename Desired_block_layout<BlockT>::layout_type>
+struct Diagnose_ext_data
+{
+  typedef Choose_access<BlockT, LP> ca_type;
+  typedef typename ca_type::type        access_type;
+  typedef typename ca_type::reason_type reason_type;
+
+  typedef typename Block_layout<BlockT>::complex_type blk_complex_type;
+  typedef typename LP::complex_type lp_complex_type;
+
+  static void diag(std::string name)
+  {
+    using diag_detail::Class_name;
+    using std::cout;
+    using std::endl;
+
+    cout << "diagnose_ext_data(" << name << ")" << endl
+	 << "  BlockT: " << typeid(BlockT).name() << endl
+	 << "  Block LP" << endl
+	 << "    complex_type: " << Class_name<blk_complex_type>::name() << endl
+	 << "  Req LP" << endl
+	 << "    complex_type: " << Class_name<lp_complex_type>::name() << endl
+	 << "  access_type: " << Class_name<access_type>::name() << endl
+	 << "  reason_type: " << Class_name<reason_type>::name() << endl
+	 << "  static-cost: " << data_access::Cost<access_type>::value << endl
+      ;
+  }
+};
+
+} // namespace vsip::impl::diag_detail
+} // namespace vsip
+
+#endif // VSIP_OPT_DIAG_EXTDATAL_HPP
Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 164922)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -63,10 +63,18 @@
 VSIP_IMPL_DISPATCH_NAME(Op_expr_tag)
 VSIP_IMPL_DISPATCH_NAME(Simd_builtin_tag)
 VSIP_IMPL_DISPATCH_NAME(Simd_loop_fusion_tag)
+VSIP_IMPL_DISPATCH_NAME(Fc_expr_tag)
+VSIP_IMPL_DISPATCH_NAME(Rbo_expr_tag)
 VSIP_IMPL_DISPATCH_NAME(Loop_fusion_tag)
 
+VSIP_IMPL_DISPATCH_NAME(Tag_illegal_mix_of_local_and_global_in_assign)
+VSIP_IMPL_DISPATCH_NAME(Tag_serial_expr)
+// VSIP_IMPL_DISPATCH_NAME(Tag_par_assign)
+VSIP_IMPL_DISPATCH_NAME(Tag_par_expr)
+VSIP_IMPL_DISPATCH_NAME(Tag_par_expr_noreorg)
 
 
+
 // Helper class to conditionally call to Serial_expr_evaluator's
 // rt_valid() method, when ct_valid is true.  If ct_valid is false,
 // the call may not be valid.
@@ -111,7 +119,7 @@
 
 
 // Summarize the evaluation of expression 'dst = src' for dispatch
-// tag Tag.  Single line form of diagnose_eval().
+// tag Tag.  Single line form of diagnose_eval_tag().
 
 template <dimension_type Dim,
 	  typename       Tag,
@@ -244,6 +252,68 @@
   }
 };
 
+
+template <dimension_type Dim,
+	  typename       DstBlock,
+	  typename       SrcBlock,
+	  typename       DaTag>
+struct Diag_eval_dispatch_helper
+{
+  static void info(
+    DstBlock&       /*dst*/,
+    SrcBlock const& /*src*/)
+  {}
+};
+
+
+
+template <dimension_type Dim,
+	  typename       Block1,
+	  typename       Block2>
+struct Diag_eval_dispatch_helper<Dim, Block1, Block2, Tag_par_expr_noreorg>
+{
+  typedef typename Block1::map_type map1_type;
+
+  typedef typename View_of_dim<Dim, typename Block1::value_type,
+			     Block1>::type dst_type;
+  typedef typename View_of_dim<Dim, typename Block2::value_type,
+			     Block2>::const_type src_type;
+
+  static void info(
+    Block1&       blk1,
+    Block2 const& blk2)
+  {
+    if (Is_par_same_map<Dim, map1_type, Block2>::value(blk1.map(), blk2))
+    {
+      // Maps are same, no communication required.
+      typedef typename Distributed_local_block<Block1>::type block1_t;
+      typedef typename Distributed_local_block<Block2>::type block2_t;
+      typedef typename View_block_storage<block1_t>::type::equiv_type stor1_t;
+      typedef typename View_block_storage<block2_t>::type::equiv_type stor2_t;
+
+      stor1_t l_blk1 = get_local_block(blk1);
+      stor2_t l_blk2 = get_local_block(blk2);
+
+      Dispatch_assign<Dim, block1_t, block2_t>::exec(l_blk1, l_blk2);
+      std::cout << "LHS and RHS have same map -- local assignment\n";
+
+      // Equivalent to:
+      //   diagnose_eval_list_std(dst, src);
+      std::cout << "diagnose_eval_list" << std::endl
+		<< "  dst expr: " << typeid(stor1_t).name() << std::endl
+		<< "  src expr: " << typeid(stor2_t).name() << std::endl;
+      Diag_eval_list_helper<Dim, block1_t, block2_t,
+	                    vsip::impl::LibraryTagList>
+	::exec(l_blk1, l_blk2);
+    }
+    else
+    {
+      std::cout << "LHS and RHS have different maps\n";
+      std::cout << "error: expr cannot be reorganized\n";
+    }
+  }
+};
+
 } // namespace vsip::impl::diag_detail
 
 
@@ -263,11 +333,11 @@
 // Example:
 //   To determine how the loop fusion evaluator would handle 'A = B + C':
 //
-//      diagnose_eval<vsip::impl::Loop_fusion_tag>(A, B + C)
+//      diagnose_eval_tag<vsip::impl::Loop_fusion_tag>(A, B + C)
 //
 //   This will produce output like so:
 //
-//      diagnose_eval:
+//      diagnose_eval_tag:
 //        name: Expr_Loop
 //        tag: Loop_fusion_tag
 //        DstBlockT: ...
@@ -280,7 +350,7 @@
 	  typename       DstViewT,
           typename       SrcViewT>
 void
-diagnose_eval(
+diagnose_eval_tag(
   DstViewT dst,
   SrcViewT src)
 {
@@ -298,7 +368,7 @@
 
   typedef typename Block_layout<dst_block_type>::order_type dst_order_type;
 
-  std::cout << "diagnose_eval:" << std::endl;
+  std::cout << "diagnose_eval_tag:" << std::endl;
   std::cout << "  name: " << see_type::name() << std::endl;
   std::cout << "  tag: " << Dispatch_name<EvalTag>::name() << std::endl;
   std::cout << "  DstBlockT: " << typeid(dst_block_type).name() << std::endl;
@@ -313,6 +383,54 @@
 
 
 
+// Diagnose Dispatch_assign.
+
+template <typename       DstViewT,
+          typename       SrcViewT>
+void
+diagnose_eval_dispatch(
+  DstViewT dst,
+  SrcViewT src)
+{
+  using std::cout;
+  using std::endl;
+
+  using vsip::impl::diag_detail::Dispatch_name;
+
+  typedef typename DstViewT::block_type dst_block_type;
+  typedef typename SrcViewT::block_type src_block_type;
+  dimension_type const dim = SrcViewT::dim;
+
+  typedef Dispatch_assign_helper<dim, dst_block_type, src_block_type, false>
+    dah;
+
+  typedef typename dah::type dispatch_type;
+
+  cout << "--------------------------------------------------------\n";
+  cout << "diagnose_eval_dispatch:" << std::endl
+       << "  dim: " << dim << std::endl
+       << "  DstBlockT    : " << typeid(dst_block_type).name() << endl
+       << "  SrcBlockT    : " << typeid(src_block_type).name() << endl
+       << "  is_illegal   : " << (dah::is_illegal ? "true" : "false") << endl
+       << "  is_rhs_expr  : " << (dah::is_rhs_expr ? "true" : "false") << endl
+       << "  is_rhs_simple: " << (dah::is_rhs_simple ? "true" : "false") <<endl
+       << "  is_rhs_reorg : " << (dah::is_rhs_reorg ? "true" : "false") << endl
+       << "  is_lhs_split : " << (dah::is_lhs_split ? "true" : "false") << endl
+       << "  is_rhs_split : " << (dah::is_rhs_split ? "true" : "false") << endl
+       << "  lhs_cost     : " << dah::lhs_cost << endl
+       << "  rhs_cost     : " << dah::rhs_cost << endl
+       << "  TYPE         : " << Dispatch_name<dispatch_type>::name() << endl
+    ;
+  cout << "--------------------------------------------------------\n";
+
+  diag_detail::Diag_eval_dispatch_helper<dim, dst_block_type, src_block_type,
+    dispatch_type>::info(dst.block(), src.block());
+
+  cout << "--------------------------------------------------------\n";
+}
+
+
+
 // Diagnose evaluation of an expression 'dst = src' with a list of
 // dispatch tags.
 //
@@ -344,6 +462,27 @@
 //      -      Loop_fusion_tag  ct:  true  rt:  true
 //
 
+// Block argument version.
+
+template <typename       TagList,
+	  dimension_type Dim,
+	  typename       DstBlock,
+          typename       SrcBlock>
+void
+diagnose_eval_list_blk(
+  DstBlock&       dst,
+  SrcBlock const& src)
+{
+  using vsip::impl::diag_detail::Diag_eval_list_helper;
+
+  std::cout << "diagnose_eval_list" << std::endl
+	    << "  dst expr: " << typeid(DstBlock).name() << std::endl
+	    << "  src expr: " << typeid(SrcBlock).name() << std::endl;
+  Diag_eval_list_helper<Dim, DstBlock, SrcBlock, TagList>::exec(dst, src);
+}
+
+
+
 template <typename  TagList,
 	  typename  DstViewT,
           typename  SrcViewT>
Index: src/vsip/opt/expr/return_block.hpp
===================================================================
--- src/vsip/opt/expr/return_block.hpp	(revision 0)
+++ src/vsip/opt/expr/return_block.hpp	(revision 0)
@@ -0,0 +1,268 @@
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/expr/return_block.hpp
+    @author  Jules Bergmann
+    @date    2006-09-02
+    @brief   VSIPL++ Library: Expression return block.
+
+*/
+
+#ifndef VSIP_OPT_EXPR_RETURN_BLOCK_HPP
+#define VSIP_OPT_EXPR_RETURN_BLOCK_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <memory>
+
+#include <vsip/core/block_traits.hpp>
+#include <vsip/core/view_traits.hpp>
+#include <vsip/core/domain_utils.hpp>
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
+/// Expression template block for return block optimization.
+
+/// Requires:
+///   DIM to be a dimension.
+///   T to be a value type.
+///   RETURNFUNCTOR to be ...
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+class Return_expr_block : public Non_assignable
+{
+public:
+  static dimension_type const dim = Dim;
+
+  typedef T                                value_type;
+  typedef value_type&                      reference_type;
+  typedef value_type const&                const_reference_type;
+  typedef typename ReturnFunctor::map_type map_type;
+
+  typedef Dense<Dim, T> block_type;
+
+  Return_expr_block(ReturnFunctor& rf)
+    : rf_   (rf)
+    , block_()
+  {}
+
+  // Necessary to provide copy constructor, because auto_ptr cannot
+  // be copied.
+  Return_expr_block(Return_expr_block const& rhs)
+    : rf_   (rhs.rf_),
+      block_()
+  {}
+
+  length_type size() const VSIP_NOTHROW { return rf_.size(); }
+  length_type size(dimension_type block_dim, dimension_type d)
+    const VSIP_NOTHROW
+  { return rf_.size(block_dim, d); }
+
+
+  void increment_count() const VSIP_NOTHROW {}
+  void decrement_count() const VSIP_NOTHROW {}
+  map_type const& map() const VSIP_NOTHROW { return rf_.map(); }
+
+  value_type get(index_type i) const
+  { 
+    assert(block_.get());
+    return block_->get(i);
+  }
+
+  value_type get(index_type i, index_type j) const
+  { 
+    assert(block_.get());
+    return block_->get(i, j);
+  }
+
+  value_type get(index_type i, index_type j, index_type k) const
+  { 
+    assert(block_.get());
+    return block_->get(i, j, k);
+  }
+
+  template <typename DstBlock>
+  void apply(DstBlock& dst) const
+  {
+    rf_.apply(dst);
+  }
+
+  void loop_fusion_init()
+  {
+    block_.reset(new block_type(block_domain<Dim>(*this)));
+    rf_.apply(*(block_.get()));
+  }
+
+  void loop_fusion_fini()
+  {
+    block_.reset(0);
+  }
+
+  ReturnFunctor const& functor() const { return rf_; }
+
+private:
+  ReturnFunctor             rf_;
+  std::auto_ptr<block_type> block_;
+};
+
+
+
+/// Specialize traits for Return_expr_block.
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Is_expr_block<Return_expr_block<Dim, T, ReturnFunctor> >
+{ static bool const value = true; };
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct View_block_storage<Return_expr_block<Dim, T, ReturnFunctor> const>
+  : By_value_block_storage<Return_expr_block<Dim, T, ReturnFunctor> const>
+{};
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct View_block_storage<Return_expr_block<Dim, T, ReturnFunctor> >
+  : By_value_block_storage<Return_expr_block<Dim, T, ReturnFunctor> >
+{};
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Distributed_local_block<Return_expr_block<Dim, T, ReturnFunctor> const>
+{
+  typedef Return_expr_block<Dim, T, typename ReturnFunctor::local_type> const
+          type;
+  typedef Return_expr_block<Dim, T, typename ReturnFunctor::local_type> const
+          proxy_type;
+};
+
+
+
+template <typename       CombineT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Combine_return_type<CombineT,
+			   Return_expr_block<Dim, T, ReturnFunctor> const>
+{
+  typedef typename Combine_return_type<CombineT, ReturnFunctor>::tree_type
+          rf_type;
+  typedef Return_expr_block<Dim, T, rf_type> const tree_type;
+  typedef tree_type type;
+};
+
+
+
+template <typename       CombineT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Combine_return_type<CombineT,
+			   Return_expr_block<Dim, T, ReturnFunctor> >
+{
+  typedef typename Combine_return_type<CombineT, ReturnFunctor>::tree_type
+          rf_type;
+  typedef Return_expr_block<Dim, T, rf_type> const tree_type;
+  typedef tree_type type;
+};
+
+
+  
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+Return_expr_block<Dim, T, typename ReturnFunctor::local_type>
+get_local_block(
+  Return_expr_block<Dim, T, ReturnFunctor> const& g_blk)
+{
+  typedef Return_expr_block<Dim, T, typename ReturnFunctor::local_type>
+    block_type;
+  typename ReturnFunctor::local_type rf_local(g_blk.functor().local());
+  block_type l_blk(rf_local);
+  return l_blk;
+}
+
+
+
+template <typename       CombineT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+typename Combine_return_type<CombineT,
+			     Return_expr_block<Dim, T, ReturnFunctor> const>
+		::type
+apply_combine(
+  CombineT const&                                 combine,
+  Return_expr_block<Dim, T, ReturnFunctor> const& block)
+{
+  typedef typename Combine_return_type<
+    CombineT,
+    Return_expr_block<Dim, T, ReturnFunctor> const>::type
+		block_type;
+
+  return block_type(apply_combine(combine, block.functor()));
+}
+
+
+
+template <typename       VisitorT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+void
+apply_leaf(
+  VisitorT const&                                 visitor,
+  Return_expr_block<Dim, T, ReturnFunctor> const& block)
+{
+  apply_leaf(visitor, block.functor());
+}
+
+template <dimension_type MapDim,
+	  typename       MapT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Is_par_same_map<MapDim, MapT,
+		       Return_expr_block<Dim, T, ReturnFunctor> const>
+{
+  typedef Return_expr_block<Dim, T, ReturnFunctor> const block_type;
+
+  static bool value(MapT const& map, block_type& block)
+  {
+    return Is_par_same_map<MapDim, MapT, ReturnFunctor>
+      ::value(map, block.functor());
+  }
+};
+
+
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Is_par_reorg_ok<Return_expr_block<Dim, T, ReturnFunctor> const>
+{
+  static bool const value = false;
+};
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_OPT_EXPR_RETURN_BLOCK_HPP
Index: src/vsip/opt/expr/eval_fastconv.hpp
===================================================================
--- src/vsip/opt/expr/eval_fastconv.hpp	(revision 0)
+++ src/vsip/opt/expr/eval_fastconv.hpp	(revision 0)
@@ -0,0 +1,146 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/expr/eval_fastconv.hpp
+    @author  Jules Bergmann
+    @date    2007-02-02
+    @brief   VSIPL++ Library: General evaluator for fast convolution
+
+*/
+
+#ifndef VSIP_OPT_EXPR_EVAL_FASTCONV_HPP
+#define VSIP_OPT_EXPR_EVAL_FASTCONV_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/fft.hpp>
+#include <vsip/opt/expr/return_block.hpp>
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
+/// Evaluator for return expression block.
+
+template <typename       DstBlock,
+	  typename       T,
+	  typename       VecBlockT,
+	  typename       MatBlockT,
+	  typename       Backend1T,
+	  typename       Workspace1T,
+	  typename       Backend2T,
+	  typename       Workspace2T>
+struct Serial_expr_evaluator<2, DstBlock,
+  const Return_expr_block<2, T,
+    fft::Fft_return_functor<2, T,
+      const Vmmul_expr_block<0,
+        VecBlockT,
+        const Return_expr_block<2, T,
+          fft::Fft_return_functor<2, T,
+            MatBlockT,
+            Backend2T, Workspace2T>
+          >
+        >,
+      Backend1T, Workspace1T>
+    >,
+  Fc_expr_tag
+  >
+{
+  static char const* name() { return "Fc_expr_tag"; }
+
+  typedef
+  Return_expr_block<2, T,
+    fft::Fft_return_functor<2, T,
+      const Vmmul_expr_block<0,
+        VecBlockT,
+        const Return_expr_block<2, T,
+          fft::Fft_return_functor<2, T,
+            MatBlockT,
+            Backend2T, Workspace2T>
+          >
+        >,
+      Backend1T, Workspace1T>
+    >
+    SrcBlock;
+
+  typedef typename DstBlock::value_type dst_type;
+  typedef typename SrcBlock::value_type src_type;
+
+  static bool const ct_valid = true;
+
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    (void)dst;
+#if 0
+    // Check if the evaluator supports the scaling implied by
+    // the FFTs.
+    //
+    // This evaluator uses the FFTs directly, so it will implicitly
+    // follow the requested scaling.  However, if this evaluator is
+    // adapted to use other fast convolution implementations that
+    // have limited scaling (such as only unit), this check will
+    // be necessary.
+    
+    typedef typename Scalar_of<T>::type scalar_type;
+
+    Workspace2T const& fwd_workspace(
+      src.functor().block().get_mblk().functor().workspace());
+    Workspace1T const& inv_workspace(src.functor().workspace());
+
+    // Check FFT scaling totals 1
+    return almost_equal(fwd_workspace.scale() * inv_workspace.scale(),
+			scalar_type(1));
+#else
+    (void)src;
+    return true;
+#endif
+  }
+  
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    length_type rows = dst.size(2, 0);
+    length_type cols = dst.size(2, 1);
+    Matrix<T> tmp(1, cols);
+
+    Vector<T, VecBlockT> w  (
+      const_cast<VecBlockT&>(src.functor().block().get_vblk()));
+    Matrix<T, MatBlockT> in (
+      const_cast<MatBlockT&>(src.functor().block().get_mblk().functor().block()));
+    Matrix<T, DstBlock>        out(dst);
+
+    Workspace2T const& fwd_workspace(
+      src.functor().block().get_mblk().functor().workspace());
+
+    Backend2T&         fwd_backend  (const_cast<Backend2T&>(
+      src.functor().block().get_mblk().functor().backend()) );
+
+    Workspace1T const& inv_workspace(src.functor().workspace());
+    Backend1T&         inv_backend  (const_cast<Backend1T&>(src.functor().backend()));
+
+    for (index_type r=0; r<rows; ++r)
+    {
+      fwd_workspace.by_reference(&fwd_backend,
+				 in (Domain<2>(Domain<1>(r, 1, 1), cols)),
+				 tmp(Domain<2>(Domain<1>(0, 1, 1), cols)) );
+      tmp.row(0) *= w;
+      inv_workspace.by_reference(&inv_backend,
+				 tmp(Domain<2>(Domain<1>(0, 1, 1), cols)),
+				 out(Domain<2>(Domain<1>(r, 1, 1), cols)) );
+    }
+  }
+};
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_OPT_EXPR_EVAL_FASTCONV_HPP
Index: src/vsip/opt/expr/lf_initfini.hpp
===================================================================
--- src/vsip/opt/expr/lf_initfini.hpp	(revision 0)
+++ src/vsip/opt/expr/lf_initfini.hpp	(revision 0)
@@ -0,0 +1,208 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/expr/lf_initfini.hpp
+    @author  Jules Bergmann
+    @date    2006-08-04
+    @brief   VSIPL++ Library: Loop-fusion init/fini
+*/
+
+#ifndef VSIP_OPT_EXPR_LF_INITFINI_HPP
+#define VSIP_OPT_EXPR_LF_INITFINI_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/core/block_traits.hpp>
+#include <vsip/core/expr/operations.hpp>
+#include <vsip/core/expr/scalar_block.hpp>
+#include <vsip/core/expr/unary_block.hpp>
+#include <vsip/core/expr/binary_block.hpp>
+#include <vsip/core/expr/ternary_block.hpp>
+#include <vsip/core/expr/vmmul_block.hpp>
+#include <vsip/core/fns_elementwise.hpp>
+#include <vsip/core/coverage.hpp>
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
+// fwd decl
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+class Return_expr_block;
+
+
+
+/// Reduction to count the number operations per point of an expression.
+
+template <typename LeafT>
+struct Apply_leaf
+{
+public:
+  template <typename BlockT>
+  struct transform
+  {
+    static void apply(BlockT const& block)
+    {
+      LeafT::template leaf_node<BlockT>::apply(block);
+    }
+  };
+
+  template <typename BlockT>
+  struct transform<BlockT const> : public transform<BlockT> {};
+
+  template <dimension_type            Dim0,
+	    template <typename> class Op,
+	    typename                  BlockT,
+	    typename                  T>
+  struct transform<Unary_expr_block<Dim0, Op, BlockT, T> >
+  {
+    typedef Unary_expr_block<Dim0, Op, BlockT, T>
+		block_type;
+
+    static void apply(block_type const& block)
+    {
+      transform<BlockT>::apply(block.op());
+    }
+  };
+
+  template <dimension_type                Dim0,
+	    template <typename, typename> class Op,
+	    typename                      LBlock,
+	    typename                      LType,
+	    typename                      RBlock,
+	    typename                      RType>
+  struct transform<Binary_expr_block<Dim0, Op, LBlock, LType,
+				     RBlock, RType> >
+  {
+    typedef Binary_expr_block<Dim0, Op, LBlock, LType, RBlock, RType> 
+		block_type;
+
+    static void apply(block_type const& block)
+    {
+      transform<LBlock>::apply(block.left());
+      transform<RBlock>::apply(block.right());
+    }
+  };
+
+  template <dimension_type                Dim0,
+	    template <typename, typename, typename> class Op,
+	    typename                      Block1,
+	    typename                      Type1,
+	    typename                      Block2,
+	    typename                      Type2,
+	    typename                      Block3,
+	    typename                      Type3>
+  struct transform<Ternary_expr_block<Dim0, Op, Block1, Type1,
+				     Block2, Type2, Block3, Type3> >
+  {
+    typedef Ternary_expr_block<Dim0, Op, Block1, Type1,
+			       Block2, Type2, Block3, Type3> const
+		block_type;
+
+    static void apply(block_type const& block)
+    {
+      transform<Block1>::apply(block.first());
+      transform<Block2>::apply(block.second());
+      transform<Block3>::apply(block.third());
+    }
+  };
+
+  template <dimension_type VecDim,
+	    typename       Block0,
+	    typename       Block1>
+  struct transform<Vmmul_expr_block<VecDim, Block0, Block1> >
+  {
+    typedef Vmmul_expr_block<VecDim, Block0, Block1> const block_type;
+
+    static void apply(block_type const& block)
+    {
+      transform<Block0>::apply(block.get_vblk());
+      transform<Block1>::apply(block.get_mblk());
+    }
+  };
+};
+
+
+
+struct Do_loop_fusion_init : Apply_leaf<Do_loop_fusion_init>
+{
+  template <typename BlockT>
+  struct leaf_node
+  {
+    static void apply(BlockT const&) {} // no-op
+  };
+
+  template <dimension_type Dim,
+	    typename       T,
+	    typename       ReturnFunctor>
+  struct leaf_node<Return_expr_block<Dim, T, ReturnFunctor> >
+  {
+    typedef Return_expr_block<Dim, T, ReturnFunctor>
+		block_type;
+
+    static void apply(block_type const& block) 
+    {
+      const_cast<block_type&>(block).loop_fusion_init();
+    }
+  };
+};
+
+
+
+struct Do_loop_fusion_fini : Apply_leaf<Do_loop_fusion_fini>
+{
+  template <typename BlockT>
+  struct leaf_node
+  {
+    static void apply(BlockT const&) {} // no-op
+  };
+
+  template <dimension_type Dim,
+	    typename       T,
+	    typename       ReturnFunctor>
+  struct leaf_node<Return_expr_block<Dim, T, ReturnFunctor> >
+  {
+    typedef Return_expr_block<Dim, T, ReturnFunctor>
+		block_type;
+
+    static void apply(block_type const& block) 
+    {
+      const_cast<block_type&>(block).loop_fusion_fini();
+    }
+  };
+};
+
+
+template <typename BlockT>
+void
+do_loop_fusion_init(BlockT const& block)
+{
+  Do_loop_fusion_init::transform<BlockT>::apply(block);
+}
+
+
+
+template <typename BlockT>
+void
+do_loop_fusion_fini(BlockT const& block)
+{
+  Do_loop_fusion_fini::transform<BlockT>::apply(block);
+}
+
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_EXPR_LF_INITFINI_HPP
Index: src/vsip/opt/expr/serial_dispatch.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch.hpp	(revision 164922)
+++ src/vsip/opt/expr/serial_dispatch.hpp	(working copy)
@@ -27,6 +27,8 @@
 #include <vsip/opt/expr/serial_evaluator.hpp>
 #include <vsip/opt/expr/serial_dispatch_fwd.hpp>
 #include <vsip/opt/expr/eval_dense.hpp>
+#include <vsip/opt/expr/eval_return_block.hpp>
+#include <vsip/opt/expr/eval_fastconv.hpp>
 #include <vsip/opt/expr/ops_info.hpp>
 #include <vsip/core/profile.hpp>
 
@@ -38,6 +40,7 @@
 #endif
 #ifdef VSIP_IMPL_CBE_SDK
 #include <vsip/opt/cbe/ppu/bindings.hpp>
+#include <vsip/opt/cbe/ppu/eval_fastconv.hpp>
 #endif
 
 #ifdef VSIP_IMPL_HAVE_SIMD_LOOP_FUSION
Index: src/vsip/opt/expr/serial_dispatch_fwd.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch_fwd.hpp	(revision 164922)
+++ src/vsip/opt/expr/serial_dispatch_fwd.hpp	(working copy)
@@ -50,6 +50,8 @@
 		       Copy_tag,
 		       Op_expr_tag,
 		       Simd_loop_fusion_tag,
+		       Fc_expr_tag,
+		       Rbo_expr_tag,
 		       Loop_fusion_tag>::type LibraryTagList;
 
 
Index: src/vsip/opt/expr/eval_return_block.hpp
===================================================================
--- src/vsip/opt/expr/eval_return_block.hpp	(revision 0)
+++ src/vsip/opt/expr/eval_return_block.hpp	(revision 0)
@@ -0,0 +1,65 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/expr/eval_return_block.hpp
+    @author  Jules Bergmann
+    @date    2006-09-02
+    @brief   VSIPL++ Library: Evaluator for return-block optimization.
+
+*/
+
+#ifndef VSIP_OPT_EXPR_EVAL_RETURN_BLOCK_HPP
+#define VSIP_OPT_EXPR_EVAL_RETURN_BLOCK_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/expr/return_block.hpp>
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
+/// Evaluator for return expression block.
+
+template <dimension_type Dim,
+	  typename       DstBlock,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Serial_expr_evaluator<Dim, DstBlock,
+	const Return_expr_block<Dim, T, ReturnFunctor>,
+	Rbo_expr_tag>
+{
+  static char const* name() { return "Rbo_expr_tag"; }
+
+  typedef Return_expr_block<Dim, T, ReturnFunctor> SrcBlock;
+
+  typedef typename DstBlock::value_type dst_type;
+  typedef typename SrcBlock::value_type src_type;
+
+  static bool const ct_valid = true;
+
+  static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
+  {
+    return true;
+  }
+  
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    src.apply(dst);
+  }
+};
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_OPT_EXPR_EVAL_RETURN_BLOCK_HPP
Index: src/vsip/opt/expr/serial_evaluator.hpp
===================================================================
--- src/vsip/opt/expr/serial_evaluator.hpp	(revision 164922)
+++ src/vsip/opt/expr/serial_evaluator.hpp	(working copy)
@@ -28,6 +28,7 @@
 #include <vsip/core/adjust_layout.hpp>
 #include <vsip/core/coverage.hpp>
 #include <vsip/core/impl_tags.hpp>
+#include <vsip/opt/expr/lf_initfini.hpp>
 
 
 /***********************************************************************
@@ -62,9 +63,11 @@
   
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
+    do_loop_fusion_init(src);
     length_type const size = dst.size(1, 0);
     for (index_type i=0; i<size; ++i)
       dst.put(i, src.get(i));
+    do_loop_fusion_fini(src);
   }
 };
 
@@ -353,7 +356,9 @@
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
     typedef typename Block_layout<DstBlock>::order_type dst_order_type;
+    do_loop_fusion_init(src);
     exec(dst, src, dst_order_type());
+    do_loop_fusion_fini(src);
   }
 };
 
@@ -438,7 +443,9 @@
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
     typedef typename Block_layout<DstBlock>::order_type dst_order_type;
+    do_loop_fusion_init(src);
     exec(dst, src, dst_order_type());
+    do_loop_fusion_fini(src);
   }
 };
 
Index: tests/diag_eval.cpp
===================================================================
--- tests/diag_eval.cpp	(revision 164339)
+++ tests/diag_eval.cpp	(working copy)
@@ -41,12 +41,15 @@
   Vector<T> B(size, T(2));
   Vector<T> Z(size, T(0));
 
+  // Diagnose how dispatch will handle Z = A + B.
+  vsip::impl::diagnose_eval_dispatch(Z, A + B);
 
-  // Diagnose how entire dispatch list will handle Z = A + B.
+  // Diagnose how tags in standard list will handle Z = A + B.
+  // (assumes that Z = A + B is a local expression)
   vsip::impl::diagnose_eval_list_std(Z, A + B);
 
   // Zoom in on the Intel_ipp_tag evaluator.
-  vsip::impl::diagnose_eval<vsip::impl::Loop_fusion_tag>(Z, A + B);
+  vsip::impl::diagnose_eval_tag<vsip::impl::Loop_fusion_tag>(Z, A + B);
 }
 
 
Index: benchmarks/cell/fastconv.cpp
===================================================================
--- benchmarks/cell/fastconv.cpp	(revision 164963)
+++ benchmarks/cell/fastconv.cpp	(working copy)
@@ -42,10 +42,10 @@
 ***********************************************************************/
 
 struct ImplCbe;		// interleaved fast-convolution on Cell
+template <typename ComplexFmt, bool single_fc>
+struct ImplCbe_ip;	// interleaved fast-convolution on Cell, in-place
 template <typename ComplexFmt>
-struct ImplCbe_ip;	// interleaved fast-convolution on Cell
-template <typename ComplexFmt>
-struct ImplCbe_op;	// interleaved fast-convolution on Cell
+struct ImplCbe_op;	// interleaved fast-convolution on Cell, out-of-place
 
 
 
@@ -58,7 +58,10 @@
   ImplCbe: in-place, distributed, split/interleaved format fixed
            to be library's preferred format.
 
-  Impl
+  ImplCbe_ip: in-place, non-distributed, split/interleaved controllable.
+
+  ImplCbe_op: out-of-place, non-distributed, split/interleaved
+           controllable.
 ***********************************************************************/
 bool        use_huge_pages_ = true;
 
@@ -156,8 +159,9 @@
 
 
 template <typename T,
-	  typename ComplexFmt>
-struct t_fastconv_base<T, ImplCbe_ip<ComplexFmt> > : fastconv_ops
+	  typename ComplexFmt,
+	  bool     single_fc>
+struct t_fastconv_base<T, ImplCbe_ip<ComplexFmt, single_fc> > : fastconv_ops
 {
 
   static length_type const num_args = 1;
@@ -192,25 +196,46 @@
     // Create the pulse replica
     replica_view_type replica(*repl_block);
     
-    // Create Fast Convolution object
-    fconv_type fconv(replica, nrange);
-
     vsip::impl::profile::Timer t1;
 
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      fconv(data, data);
-    t1.stop();
+    if (single_fc)
+    {
+      // Reuse single fastconv object
 
-    time = t1.delta();
+      // Create Fast Convolution object
+      fconv_type fconv(replica, nrange);
+
+      t1.start();
+      for (index_type l=0; l<loop; ++l)
+	fconv(data, data);
+      t1.stop();
+
+      time = t1.delta();
     }
+    else
+    {
+      // Use multiple fastconv objects
+
+      t1.start();
+      for (index_type l=0; l<loop; ++l)
+      {
+	// Create Fast Convolution object
+	fconv_type fconv(replica, nrange);
+	fconv(data, data);
+      }
+      t1.stop();
+    }
+
+      time = t1.delta();
+    }
+
     delete repl_block;
     delete data_block;
   }
 
   t_fastconv_base()
-    : mem_addr_(0),
-      pages_   (9)
+    : mem_addr_ (0)
+    , pages_    (9)
   {
     char const* mem_file = "/huge/fastconv.bin";
 
@@ -220,6 +245,7 @@
       mem_addr_ = 0;
   }
 
+// Member data.
   char*        mem_addr_;
   unsigned int pages_;
 };
@@ -304,11 +330,11 @@
 void
 defaults(Loop1P& loop)
 {
-  loop.cal_        = 4;
-  loop.start_      = 4;
-  loop.stop_       = 16;
+  loop.cal_        = 0;
+  loop.start_      = 0;
+  loop.stop_       = 12;
   loop.loop_start_ = 10;
-  loop.user_param_ = 64;
+  loop.user_param_ = 2048;
 }
 
 
@@ -316,18 +342,39 @@
 int
 test(Loop1P& loop, int what)
 {
+  typedef complex<float> T;
+
   typedef vsip::impl::Cmplx_split_fmt Csf;
   typedef vsip::impl::Cmplx_inter_fmt Cif;
 
   length_type param1 = loop.user_param_;
   switch (what)
   {
-  case 20: loop(t_fastconv_rf<complex<float>, ImplCbe>(param1)); break;
-  case 21: loop(t_fastconv_rf<complex<float>, ImplCbe_op<Cif> >(param1));break;
-  case 22: loop(t_fastconv_rf<complex<float>, ImplCbe_ip<Cif> >(param1));break;
-  case 23: loop(t_fastconv_rf<complex<float>, ImplCbe_op<Csf> >(param1));break;
-  case 24: loop(t_fastconv_rf<complex<float>, ImplCbe_ip<Csf> >(param1));break;
+  case  1: loop(t_fastconv_rf<T, ImplCbe>(param1)); break;
 
+  case 11: loop(t_fastconv_rf<T, ImplCbe_op<Cif> >(param1));break;
+  case 12: loop(t_fastconv_rf<T, ImplCbe_ip<Cif, true> >(param1));break;
+  case 13: loop(t_fastconv_rf<T, ImplCbe_ip<Cif, false> >(param1));break;
+
+  case 21: loop(t_fastconv_rf<T, ImplCbe_op<Csf> >(param1));break;
+  case 22: loop(t_fastconv_rf<T, ImplCbe_ip<Csf, true> >(param1));break;
+  case 23: loop(t_fastconv_rf<T, ImplCbe_ip<Csf, false> >(param1));break;
+
+  case 0:
+    std::cout
+      << "fastconv -- fast convolution benchmark for Cell BE\n"
+      << " Sweeping pulse size:\n"
+      << "    -1 -- IP, native complex, distributed\n"
+      << "\n"
+      << "   -11 -- OP, inter complex,  non-dist\n"
+      << "   -12 -- IP, inter complex,  non-dist, single FC\n"
+      << "   -13 -- IP, inter complex,  non-dist, multi FC\n"
+      << "\n"
+      << "   -21 -- OP, split complex,  non-dist\n"
+      << "   -22 -- IP, split complex,  non-dist\n"
+      << "   -23 -- IP, split complex,  non-dist, multi FC\n"
+      ;
+
   default: return 0;
   }
   return 1;
Index: benchmarks/fastconv.cpp
===================================================================
--- benchmarks/fastconv.cpp	(revision 164963)
+++ benchmarks/fastconv.cpp	(working copy)
@@ -22,6 +22,7 @@
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
 #include <vsip/random.hpp>
+#include <vsip/opt/diag/eval.hpp>
 #include <vsip_csl/error_db.hpp>
 
 #include "benchmarks.hpp"
@@ -36,7 +37,6 @@
 #  define PARALLEL_FASTCONV 0
 #endif
 
-
 /***********************************************************************
   Common definitions
 ***********************************************************************/
@@ -49,11 +49,8 @@
 struct Impl2ip;		// in-place, interleaved fast-convolution
 struct Impl2ip_tmp;	// in-place (w/tmp), interleaved fast-convolution
 struct Impl2fv;		// foreach_vector, interleaved fast-convolution
-struct ImplCbe;		// interleaved fast-convolution on Cell
-template <typename ComplexFmt>
-struct ImplCbe_ip;	// interleaved fast-convolution on Cell
-template <typename ComplexFmt>
-struct ImplCbe_op;	// interleaved fast-convolution on Cell
+struct Impl3;		// Mixed fast-convolution
+struct Impl4;		// Single-line fast-convolution
 
 struct Impl1pip2_nopar;
 
@@ -428,11 +425,13 @@
 
     // Create the data cube.
     view_type data(npulse, nrange, map);
+    view_type chk(npulse, nrange, map);
 #else
     typedef Matrix<T>  view_type;
     typedef Vector<T>  replica_view_type;
 
     view_type data(npulse, nrange);
+    view_type chk(npulse, nrange);
 #endif
     Vector<T> tmp(nrange);
     
@@ -475,8 +474,26 @@
     }
     t1.stop();
 
+    time = t1.delta();
+
     // CHECK RESULT
-    time = t1.delta();
+    Rand<T> gen(0, 0);
+
+    data = gen.randu(npulse, nrange);
+    replica.put(0, T(1));
+    for_fft(replica);
+
+    length_type l_npulse  = LOCAL(data).size(0);
+    for (index_type p=0; p<l_npulse; ++p)
+    {
+      for_fft(LOCAL(data).row(p), tmp);
+      tmp *= LOCAL(replica);
+      inv_fft(tmp, LOCAL(chk).row(p));
+    }
+
+    double error = error_db(data, chk);
+
+    test_assert(error < -100);
   }
 };
 
@@ -507,12 +524,14 @@
 
     // Create the data cube.
     view_type data(npulse, nrange, map);
+    view_type chk(npulse, nrange, map);
     
 #else
     typedef Matrix<T>  view_type;
     typedef Vector<T>  replica_view_type;
 
     view_type data(npulse, nrange);
+    view_type chk(npulse, nrange);
 #endif
 
     // Create the pulse replica
@@ -554,8 +573,27 @@
     }
     t1.stop();
 
+    time = t1.delta();
+
     // CHECK RESULT
-    time = t1.delta();
+    Rand<T> gen(0, 0);
+
+    data = gen.randu(npulse, nrange);
+    chk  = data;
+    replica.put(0, T(1));
+    for_fft(replica);
+
+    length_type l_npulse  = LOCAL(data).size(0);
+    for (index_type p=0; p<l_npulse; ++p)
+    {
+      for_fft(LOCAL(data).row(p));
+      LOCAL(data).row(p) *= LOCAL(replica);
+      inv_fft(LOCAL(data).row(p));
+    }
+
+    double error = error_db(data, chk);
+
+    test_assert(error < -100);
   }
 };
 
@@ -735,6 +773,196 @@
 
 
 /***********************************************************************
+  Impl3: Mixed phase/interleave fast-convolution
+***********************************************************************/
+
+template <typename T>
+struct t_fastconv_base<T, Impl3> : fastconv_ops
+{
+  static length_type const num_args = 1;
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+    typedef Map<Block_dist, Whole_dist>      map_type;
+    typedef Dense<2, T, row2_type, map_type> block_type;
+    typedef Matrix<T, block_type>            view_type;
+
+    typedef Dense<1, T, row1_type, Global_map<1> > replica_block_type;
+    typedef Vector<T, replica_block_type>          replica_view_type;
+
+    processor_type np = num_processors();
+    map_type map = map_type(Block_dist(np), Whole_dist());
+
+    // Create the data cube.
+    view_type data(npulse, nrange, map);
+    view_type tmp(npulse, nrange, map);
+    
+    // Create the pulse replica
+    replica_view_type replica(nrange);
+
+    // int const no_times = 0; // FFTW_PATIENT
+    int const no_times = 15; // not > 12 = FFT_MEASURE
+    
+    typedef Fftm<T, T, row, fft_fwd, by_reference, no_times>
+	  	for_fftm_type;
+    typedef Fftm<T, T, row, fft_inv, by_reference, no_times>
+	  	inv_fftm_type;
+
+    // Create the FFT objects.
+    for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+    inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/nrange);
+
+    // Initialize
+    data    = T();
+    replica = T();
+
+
+    // Before fast convolution, convert the replica into the
+    // frequency domain
+    // for_fft(replica);
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      // Perform fast convolution:
+      for_fftm(data, tmp);
+      tmp = vmmul<0>(replica, tmp);
+      inv_fftm(tmp, data);
+    }
+    t1.stop();
+
+    // CHECK RESULT
+    time = t1.delta();
+  }
+};
+
+
+
+/***********************************************************************
+  Impl4: Single expression fast-convolution.
+***********************************************************************/
+
+template <typename T>
+struct t_fastconv_base<T, Impl4> : fastconv_ops
+{
+  static length_type const num_args = 1;
+
+#if PARALLEL_FASTCONV
+  typedef Map<Block_dist, Whole_dist>      map_type;
+  typedef Dense<2, T, row2_type, map_type> block_type;
+  typedef Matrix<T, block_type>            view_type;
+
+  typedef Dense<1, T, row1_type, Global_map<1> > replica_block_type;
+  typedef Vector<T, replica_block_type>          replica_view_type;
+#else
+  typedef Local_map  map_type;
+  typedef Matrix<T>  view_type;
+  typedef Vector<T>  replica_view_type;
+#endif
+
+  // static int const no_times = 0; // FFTW_PATIENT
+  static int const no_times = 15; // not > 12 = FFT_MEASURE
+    
+  typedef Fftm<T, T, row, fft_fwd, by_value, no_times>
+               for_fftm_type;
+  typedef Fftm<T, T, row, fft_inv, by_value, no_times>
+	       inv_fftm_type;
+
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+#if PARALLEL_FASTCONV
+    processor_type np = num_processors();
+    map_type map = map_type(Block_dist(np), Whole_dist());
+#else
+    map_type map;
+#endif
+
+    // Create the data cube.
+    view_type data(npulse, nrange, map);
+    view_type chk(npulse, nrange, map);
+    
+    // Create the pulse replica
+    replica_view_type replica(nrange);
+
+    // Create the FFT objects.
+    for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+    inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/nrange);
+
+    // Initialize
+    data    = T();
+    replica = T();
+
+
+    // Before fast convolution, convert the replica into the
+    // frequency domain
+    // for_fft(replica);
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      data = inv_fftm(vmmul<0>(replica, for_fftm(data)));
+    }
+    t1.stop();
+
+    // CHECK RESULT
+    typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times>
+	  	for_fft_type;
+
+    Rand<T> gen(0, 0);
+    for_fft_type for_fft(Domain<1>(nrange), 1.0);
+
+    data = gen.randu(npulse, nrange);
+    replica.put(0, T(1));
+    for_fft(replica);
+
+    chk = inv_fftm(vmmul<0>(replica, for_fftm(data)));
+
+    double error = error_db(data, chk);
+
+    test_assert(error < -100);
+
+    time = t1.delta();
+  }
+
+  void diag()
+  {
+#if PARALLEL_FASTCONV
+    processor_type np = num_processors();
+    map_type map = map_type(Block_dist(np), Whole_dist());
+#else
+    map_type map;
+#endif
+
+    length_type npulse = 16;
+    length_type nrange = 2048;
+
+    // Create the data cube.
+    view_type data(npulse, nrange, map);
+
+    // Create the pulse replica
+    replica_view_type replica(nrange);
+
+    // Create the FFT objects.
+    for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+    inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/nrange);
+
+    vsip::impl::diagnose_eval_dispatch(
+      data, inv_fftm(vmmul<0>(replica, for_fftm(data))) );
+    vsip::impl::diagnose_eval_list_std(
+      data, inv_fftm(vmmul<0>(replica, for_fftm(data))) );
+  }
+};
+
+
+
+/***********************************************************************
   Benchmark Driver
 ***********************************************************************/
 
@@ -766,11 +994,9 @@
   case  5: loop(t_fastconv_pf<complex<float>, Impl2op>(param1)); break;
   case  6: loop(t_fastconv_pf<complex<float>, Impl2ip>(param1)); break;
   case  7: loop(t_fastconv_pf<complex<float>, Impl2ip_tmp>(param1)); break;
-#if PARALLEL_FASTCONV
   case  8: loop(t_fastconv_pf<complex<float>, Impl2fv>(param1)); break;
-#endif
+  case  9: loop(t_fastconv_pf<complex<float>, Impl4>(param1)); break;
 
-  case  9: loop(t_fastconv_pf<complex<float>, Impl1pip2_nopar>(param1)); break;
 
   case 11: loop(t_fastconv_rf<complex<float>, Impl1op>(param1)); break;
   case 12: loop(t_fastconv_rf<complex<float>, Impl1ip>(param1)); break;
@@ -779,10 +1005,38 @@
   case 15: loop(t_fastconv_rf<complex<float>, Impl2op>(param1)); break;
   case 16: loop(t_fastconv_rf<complex<float>, Impl2ip>(param1)); break;
   case 17: loop(t_fastconv_rf<complex<float>, Impl2ip_tmp>(param1)); break;
-#if PARALLEL_FASTCONV
   case 18: loop(t_fastconv_rf<complex<float>, Impl2fv>(param1)); break;
-#endif
+  case 19: loop(t_fastconv_rf<complex<float>, Impl4>(param1)); break;
 
+  case 101: loop(t_fastconv_pf<complex<float>, Impl1pip2_nopar>(param1)); break;
+
+
+  // case 101: loop(t_fastconv_pf<complex<float>, Impl3>(param1)); break;
+
+  case 0:
+    std::cout
+      << "fastconv -- fast convolution benchmark\n"
+      << " Sweeping pulse size:\n"
+      << "   -1 -- Out-of-place, phased\n"
+      << "   -2 -- In-place, phased\n"
+      << "   -3 -- Psuedo in-place Fftm (in-place Fft), phased\n"
+      << "   -4 -- Psuedo in-place Fftm (out-of-place Fft), phased\n"
+      << "   -5 -- Out-of-place, interleaved\n"
+      << "   -6 -- In-place, interleaved\n"
+      << "   -7 -- In-place (w/tmp), interleaved\n"
+      << "   -8 -- Foreach_vector, interleaved (2fv)\n"
+      << "   -9 -- Fused expression (4)\n"
+      << " Sweeping number of pulses:\n"
+      << "  -11 -- Out-of-place, phased\n"
+      << "  -12 -- In-place, phased\n"
+      << "  -13 -- Psuedo in-place Fftm (in-place Fft), phased\n"
+      << "  -14 -- Psuedo in-place Fftm (out-of-place Fft), phased\n"
+      << "  -15 -- Out-of-place, interleaved\n"
+      << "  -16 -- In-place, interleaved\n"
+      << "  -17 -- In-place (w/tmp), interleaved\n"
+      << "  -19 -- Fused expression (4)\n"
+      ;
+
   default: return 0;
   }
   return 1;
Index: benchmarks/vma.cpp
===================================================================
--- benchmarks/vma.cpp	(revision 164339)
+++ benchmarks/vma.cpp	(working copy)
@@ -233,6 +233,7 @@
 
 
 
+#if DO_SIMD
 template <typename T>
 struct t_vma_cSC_simd : Benchmark_base
 {
@@ -296,6 +297,7 @@
 	      << std::endl;
   }
 };
+#endif
 
 
 
@@ -335,9 +337,13 @@
   case 141: loop(t_vma_ip<CD, SD, 0, 1>()); break;
 
   case 201: loop(t_vma_cSC<SF>()); break;
+#if DO_SIMD
   case 202: loop(t_vma_cSC_simd<SF>()); break;
+#endif
   case 203: loop(t_vma_cSC<SD>()); break;
+#if DO_SIMD
   case 204: loop(t_vma_cSC_simd<SD>()); break;
+#endif
 
   default:
     return 0;
Index: benchmarks/main.cpp
===================================================================
--- benchmarks/main.cpp	(revision 164339)
+++ benchmarks/main.cpp	(working copy)
@@ -137,7 +137,10 @@
     else if (!strcmp(argv[i], "-show_time"))
       loop.show_time_ = true;
     else if (!strcmp(argv[i], "-steady"))
-      loop.mode_ = steady_mode;
+    {
+      loop.mode_  = steady_mode;
+      loop.start_ = atoi(argv[++i]);
+    }
     else if (!strcmp(argv[i], "-diag"))
       loop.mode_ = diag_mode;
     else if (!strcmp(argv[i], "-nocal"))
Index: benchmarks/sal/fft.cpp
===================================================================
--- benchmarks/sal/fft.cpp	(revision 164339)
+++ benchmarks/sal/fft.cpp	(working copy)
@@ -170,7 +170,7 @@
 
 template <typename T,
 	  typename ComplexFmt>
-struct t_fft_op
+struct t_fft_op : Benchmark_base
 {
   typedef impl::Scalar_of<T>::type scalar_type;
 
@@ -254,7 +254,7 @@
 
 template <typename T,
 	  typename ComplexFmt>
-struct t_fft_ip
+struct t_fft_ip : Benchmark_base
 {
   typedef impl::Scalar_of<T>::type scalar_type;
 
Index: benchmarks/sal/fastconv.cpp
===================================================================
--- benchmarks/sal/fastconv.cpp	(revision 164339)
+++ benchmarks/sal/fastconv.cpp	(working copy)
@@ -25,6 +25,8 @@
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
+#include "benchmarks.hpp"
+#include "fastconv.hpp"
 
 using namespace vsip;
 using namespace vsip_csl;
@@ -49,35 +51,23 @@
 
 
 
-template <typename T,
-	  typename ImplTag,
-	  typename ComplexFormat>
-struct t_fastconv_base;
+template <typename ComplexFmt>
+struct Impl1ip;		// in-place, phased fast-convolution (fscm)
+template <typename ComplexFmt>
+struct Impl2ip;		// in-place, interleaved fast-convolution (fcs loop)
 
 
-struct Impl1ip;		// in-place, phased fast-convolution
-struct Impl2ip;		// out-of-place (tmp), interleaved fast-convolution
-struct Impl2fv;		// foreach_vector, interleaved fast-convolution
 
-struct fastconv_ops
-{
-  float ops(length_type npulse, length_type nrange) 
-  {
-    float fft_ops = 5 * nrange * std::log(float(nrange)) / std::log(float(2));
-    float tot_ops = 2 * npulse * fft_ops + 6 * npulse * nrange;
-    return tot_ops;
-  }
-};
-
-
-
 /***********************************************************************
   Impl1ip: in-place, phased fast-convolution
 ***********************************************************************/
 
 template <>
-struct t_fastconv_base<complex<float>, Impl1ip, Cmplx_inter_fmt> : fastconv_ops
+struct t_fastconv_base<complex<float>, Impl1ip<Cmplx_inter_fmt> >
+  : fastconv_ops
 {
+  static length_type const num_args = 1;
+
   typedef complex<float> T;
 
   void fastconv(length_type npulse, length_type nrange,
@@ -154,8 +144,11 @@
 ***********************************************************************/
 
 template <>
-struct t_fastconv_base<complex<float>, Impl1ip, Cmplx_split_fmt> : fastconv_ops
+struct t_fastconv_base<complex<float>, Impl1ip<Cmplx_split_fmt> >
+  : fastconv_ops
 {
+  static length_type const num_args = 1;
+
   typedef complex<float> T;
 
   void fastconv(length_type npulse, length_type nrange,
@@ -253,8 +246,11 @@
 ***********************************************************************/
 
 template <>
-struct t_fastconv_base<complex<float>, Impl2ip, Cmplx_inter_fmt> : fastconv_ops
+struct t_fastconv_base<complex<float>, Impl2ip<Cmplx_inter_fmt> >
+  : fastconv_ops
 {
+  static length_type const num_args = 1;
+
   typedef complex<float> T;
 
   void fastconv(length_type npulse, length_type nrange,
@@ -330,8 +326,11 @@
 ***********************************************************************/
 
 template <>
-struct t_fastconv_base<complex<float>, Impl2ip, Cmplx_split_fmt> : fastconv_ops
+struct t_fastconv_base<complex<float>, Impl2ip<Cmplx_split_fmt> >
+  : fastconv_ops
 {
+  static length_type const num_args = 1;
+
   typedef complex<float> T;
 
   void fastconv(length_type npulse, length_type nrange,
@@ -420,60 +419,6 @@
 
 
 
-/***********************************************************************
-  PF driver: (P)ulse (F)ixed
-***********************************************************************/
-
-template <typename T, typename ImplTag, typename ComplexFmt>
-struct t_fastconv_pf : public t_fastconv_base<T, ImplTag, ComplexFmt>
-{
-  char* what() { return "t_fastconv_pf"; }
-  int ops_per_point(length_type size)
-    { return (int)(this->ops(npulse_, size) / size); }
-  int riob_per_point(length_type) { return -1*static_cast<int>(sizeof(T)); }
-  int wiob_per_point(length_type) { return -1*static_cast<int>(sizeof(T)); }
-  int mem_per_point (length_type) { return -1*static_cast<int>(sizeof(T)); }
-
-  void operator()(length_type size, length_type loop, float& time)
-  {
-    this->fastconv(npulse_, size, loop, time);
-  }
-
-  t_fastconv_pf(length_type npulse) : npulse_(npulse) {}
-
-// Member data
-  length_type npulse_;
-};
-
-
-
-/***********************************************************************
-  RF driver: (R)ange cells (F)ixed
-***********************************************************************/
-
-template <typename T, typename ImplTag, typename ComplexFmt>
-struct t_fastconv_rf : public t_fastconv_base<T, ImplTag, ComplexFmt>
-{
-  char* what() { return "t_fastconv_rf"; }
-  int ops_per_point(length_type size)
-    { return (int)(this->ops(size, nrange_) / size); }
-  int riob_per_point(length_type) { return -1*static_cast<int>(sizeof(T)); }
-  int wiob_per_point(length_type) { return -1*static_cast<int>(sizeof(T)); }
-  int mem_per_point (length_type) { return -1*static_cast<int>(sizeof(T)); }
-
-  void operator()(length_type size, length_type loop, float& time)
-  {
-    this->fastconv(size, nrange_, loop, time);
-  }
-
-  t_fastconv_rf(length_type nrange) : nrange_(nrange) {}
-
-// Member data
-  length_type nrange_;
-};
-
-
-
 void
 defaults(Loop1P& loop)
 {
@@ -491,20 +436,23 @@
 {
   typedef complex<float> C;
 
+  typedef Cmplx_inter_fmt Cif;
+  typedef Cmplx_split_fmt Csf;
+
   length_type param1 = loop.user_param_;
   switch (what)
   {
-  case   2: loop(t_fastconv_pf<C, Impl1ip, Cmplx_inter_fmt>(param1)); break;
-  case   6: loop(t_fastconv_pf<C, Impl2ip, Cmplx_inter_fmt>(param1)); break;
+  case   2: loop(t_fastconv_pf<C, Impl1ip<Cif> >(param1)); break;
+  case   6: loop(t_fastconv_pf<C, Impl2ip<Cif> >(param1)); break;
 
-  case  12: loop(t_fastconv_rf<C, Impl1ip, Cmplx_inter_fmt>(param1)); break;
-  case  16: loop(t_fastconv_rf<C, Impl2ip, Cmplx_inter_fmt>(param1)); break;
+  case  12: loop(t_fastconv_rf<C, Impl1ip<Cif> >(param1)); break;
+  case  16: loop(t_fastconv_rf<C, Impl2ip<Cif> >(param1)); break;
 
-  case 102: loop(t_fastconv_pf<C, Impl1ip, Cmplx_split_fmt>(param1)); break;
-  case 106: loop(t_fastconv_pf<C, Impl2ip, Cmplx_split_fmt>(param1)); break;
+  case 102: loop(t_fastconv_pf<C, Impl1ip<Csf> >(param1)); break;
+  case 106: loop(t_fastconv_pf<C, Impl2ip<Csf> >(param1)); break;
    
-  case 112: loop(t_fastconv_rf<C, Impl1ip, Cmplx_split_fmt>(param1)); break;
-  case 116: loop(t_fastconv_rf<C, Impl2ip, Cmplx_split_fmt>(param1)); break;
+  case 112: loop(t_fastconv_rf<C, Impl1ip<Csf> >(param1)); break;
+  case 116: loop(t_fastconv_rf<C, Impl2ip<Csf> >(param1)); break;
 
   default: return 0;
   }
Index: benchmarks/sal/vma.cpp
===================================================================
--- benchmarks/sal/vma.cpp	(revision 164339)
+++ benchmarks/sal/vma.cpp	(working copy)
@@ -20,8 +20,8 @@
 
 #include <vsip/random.hpp>
 #include <vsip/opt/profile.hpp>
-#include <vsip/opt/extdata.hpp>
-#include <vsip/opt/ops_info.hpp>
+#include <vsip/core/extdata.hpp>
+#include <vsip/core/ops_info.hpp>
 #include <sal.h>
 
 #include "loop.hpp"
@@ -40,7 +40,7 @@
 struct t_vma_sal;
 
 template <typename ComplexFmt>
-struct t_vma_sal<float, ComplexFmt>
+struct t_vma_sal<float, ComplexFmt> : Benchmark_base
 {
   typedef float T;
 
@@ -101,7 +101,7 @@
 struct t_vsma_sal;
 
 template <typename ComplexFmt>
-struct t_vsma_sal<float, ComplexFmt>
+struct t_vsma_sal<float, ComplexFmt> : Benchmark_base
 {
   typedef float T;
 
@@ -156,7 +156,7 @@
 
 
 template <>
-struct t_vsma_sal<complex<float>, Cmplx_inter_fmt>
+struct t_vsma_sal<complex<float>, Cmplx_inter_fmt> : Benchmark_base
 {
   typedef complex<float> T;
 
@@ -215,7 +215,7 @@
 
 
 template <>
-struct t_vsma_sal<complex<float>, Cmplx_split_fmt>
+struct t_vsma_sal<complex<float>, Cmplx_split_fmt> : Benchmark_base
 {
   typedef complex<float> T;
 
Index: benchmarks/sal/vmul.cpp
===================================================================
--- benchmarks/sal/vmul.cpp	(revision 164339)
+++ benchmarks/sal/vmul.cpp	(working copy)
@@ -20,8 +20,8 @@
 
 #include <vsip/random.hpp>
 #include <vsip/opt/profile.hpp>
-#include <vsip/opt/extdata.hpp>
-#include <vsip/opt/ops_info.hpp>
+#include <vsip/core/extdata.hpp>
+#include <vsip/core/ops_info.hpp>
 #include <sal.h>
 
 #include "loop.hpp"
@@ -48,7 +48,7 @@
 struct t_vmul_sal_ip;
 
 template <typename ComplexFmt>
-struct t_vmul_sal<float, ComplexFmt>
+struct t_vmul_sal<float, ComplexFmt> : Benchmark_base
 {
   typedef float T;
 
@@ -98,7 +98,7 @@
 
 
 template <>
-struct t_vmul_sal<complex<float>, Cmplx_inter_fmt>
+struct t_vmul_sal<complex<float>, Cmplx_inter_fmt> : Benchmark_base
 {
   typedef complex<float> T;
 
@@ -150,7 +150,7 @@
 
 
 template <>
-struct t_vmul_sal<complex<float>, Cmplx_split_fmt>
+struct t_vmul_sal<complex<float>, Cmplx_split_fmt> : Benchmark_base
 {
   typedef complex<float> T;
 
@@ -204,7 +204,7 @@
 
 
 template <>
-struct t_vmul_sal_ip<1, complex<float> >
+struct t_vmul_sal_ip<1, complex<float> > : Benchmark_base
 {
   typedef complex<float> T;
 
@@ -253,7 +253,7 @@
 
 
 template <>
-struct t_vmul_sal_ip<2, complex<float> >
+struct t_vmul_sal_ip<2, complex<float> > : Benchmark_base
 {
   typedef complex<float> T;
 
@@ -311,7 +311,7 @@
 struct t_svmul_sal;
 
 template <typename ComplexFmt>
-struct t_svmul_sal<float, float, ComplexFmt>
+struct t_svmul_sal<float, float, ComplexFmt> : Benchmark_base
 {
   typedef float T;
 
@@ -362,6 +362,7 @@
 
 template <>
 struct t_svmul_sal<complex<float>, complex<float>, Cmplx_inter_fmt>
+  : Benchmark_base
 {
   typedef float T;
 
@@ -415,6 +416,7 @@
 
 template <>
 struct t_svmul_sal<complex<float>, complex<float>, Cmplx_split_fmt>
+  : Benchmark_base
 {
   typedef float T;
 
Index: benchmarks/sal/memwrite.cpp
===================================================================
--- benchmarks/sal/memwrite.cpp	(revision 164339)
+++ benchmarks/sal/memwrite.cpp	(working copy)
@@ -20,8 +20,8 @@
 
 #include <vsip/random.hpp>
 #include <vsip/opt/profile.hpp>
-#include <vsip/opt/extdata.hpp>
-#include <vsip/opt/ops_info.hpp>
+#include <vsip/core/extdata.hpp>
+#include <vsip/core/ops_info.hpp>
 #include <sal.h>
 
 #include "loop.hpp"
@@ -45,7 +45,7 @@
 struct t_memwrite_sal;
 
 template <typename ComplexFmt>
-struct t_memwrite_sal<float, ComplexFmt>
+struct t_memwrite_sal<float, ComplexFmt> : Benchmark_base
 {
   typedef float T;
 
