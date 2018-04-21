Index: ChangeLog
===================================================================
--- ChangeLog	(revision 164966)
+++ ChangeLog	(working copy)
@@ -1,3 +1,52 @@
+2007-03-07  Jules Bergmann  <jules@codesourcery.com>
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
+	  (Fft_return_functor) functor to be used by Return_expr_block.
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
+	Diagnostic support for Ext_data.
+	* src/vsip/opt/choose_access.hpp: Track reason behind access
+	  type choice.
+	* src/vsip/opt/extdata.hpp: Update for Choose_access changes.
+	* src/vsip/opt/diag/extdata.hpp: New file, help diagnose Ext_data.
+
+	Additional Fastconv benchmark cases.
+	* benchmarks/cell/fastconv.cpp: Add case for recreating Fastconv
+	  object before each convolution.  Renumber cases.
+	* benchmarks/fastconv.cpp: Add single-line fastconv case (31, 32).
+	  Add mixed phased/interleaved case.
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
@@ -18,6 +18,7 @@
 #include <vsip/core/fft/backend.hpp>
 #include <vsip/core/fast_block.hpp>
 #include <vsip/core/view_traits.hpp>
+#include <vsip/opt/expr/return_block.hpp>
 
 /***********************************************************************
   Declarations
@@ -161,6 +162,111 @@
   { return new_view<view_type>(dom);}
 };
 
+
+
+/// Return functor class for Fft.
+
+/// Captures invocation of Fft object on an input block for later
+/// evaluation, once the destination block is known.
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ViewT,
+	  typename       BackendT,
+	  typename       WorkspaceT>
+struct Fft_return_functor
+{
+  typedef typename ViewT::block_type                          block_type;
+  typedef typename ViewT::block_type::map_type                map_type;
+  typedef typename View_block_storage<block_type>::plain_type block_ref_type;
+
+  Fft_return_functor(
+    ViewT       in,
+    BackendT&   backend,
+    WorkspaceT& workspace)
+  : in_block_  (in.block()),
+    backend_   (backend),
+    workspace_ (workspace)
+  {}
+
+  Fft_return_functor(Fft_return_functor const& rhs)
+    : in_block_(rhs.in_block_),
+      backend_(rhs.backend_),
+      workspace_(rhs.workspace_)
+  {}
+
+  template <typename BlockT>
+  void apply(BlockT& result) const
+  {
+    workspace_.by_reference_blk(&backend_, in_block_, result);
+  }
+
+  length_type size() const
+  {
+    return in_block_.size();
+  }
+
+  length_type size(dimension_type block_dim, dimension_type d) const
+  {
+    assert(block_dim == Dim);
+    return in_block_.size(block_dim, d);
+  }
+
+  block_ref_type in_block_;
+  BackendT&      backend_;
+  WorkspaceT&    workspace_;
+};
+
+
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
+  typedef Fft_return_functor<Dim, OutT, ViewT,
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
+  typedef Fft_return_functor<dim, OutT, in_view_type,
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
@@ -199,16 +200,21 @@
   {}
 
   template <typename ViewT>
-  typename fft::result<O, typename ViewT::block_type>::view_type
+  typename fft::Result_rbo<D, I, O, ViewT, workspace, axis, exponent>
+                          ::view_type
   operator()(ViewT in) VSIP_THROW((std::bad_alloc))
   {
     typename base::Scope scope(*this);
     assert(extent(in) == extent(this->input_size()));
-    typedef fft::result<O, typename ViewT::block_type> traits;
-    typename traits::view_type out(traits::create(this->output_size(),
-						  in.block().map()));
-    workspace_.by_reference(this->backend_.get(), in, out);
-    return out;
+    typedef fft::Result_rbo<D, I, O, ViewT, workspace, axis, exponent>
+      traits;
+    typedef typename traits::functor_type functor_type;
+    typedef typename traits::block_type   block_type;
+    typedef typename traits::view_type    view_type;
+
+    functor_type rf(in, *(this->backend_.get()), workspace_);
+    block_type block(rf);
+    return view_type(block);
   }
 private:
   std::auto_ptr<fft::backend<D, I, O, axis, exponent> > backend_;
@@ -321,24 +327,34 @@
 #endif
       workspace_(backend_.get(), this->input_size(), this->output_size(), scale)
   {}
+
   template <typename BlockT>  
-  typename fft::result<O,BlockT>::view_type
+  typename fft::Result_fftm_rbo<I, O, BlockT, workspace, axis, exponent>
+                          ::view_type
   operator()(const_Matrix<I,BlockT> in)
     VSIP_THROW((std::bad_alloc))
   {
     typename base::Scope scope(*this);
-    typedef fft::result<O,BlockT> traits;
-    typename traits::view_type out(traits::create(this->output_size(),
-						  in.block().map()));
     assert(extent(in) == extent(this->input_size()));
+
+    /* TODO: Return_blocks don't have a valid map() yet
     if (Is_global_map<typename BlockT::map_type>::value &&
 	in.block().map().num_subblocks(A) != 1)
       VSIP_IMPL_THROW(unimplemented(
 	"Fftm requires dimension along FFT to not be distributed"));
-    workspace_.by_reference(this->backend_.get(), in.local(), out.local());
-    return out;
-  }
+    */
 
+    typedef fft::Result_fftm_rbo<I, O, BlockT, workspace, axis, exponent>
+      traits;
+    typedef typename traits::functor_type functor_type;
+    typedef typename traits::block_type   block_type;
+    typedef typename traits::view_type    view_type;
+
+    functor_type rf(in, *(this->backend_.get()), workspace_);
+    block_type block(rf);
+    return view_type(block);
+ }
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
@@ -152,6 +153,69 @@
       out *= scale_;
   }
 
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference_blk(
+    BE*           backend,
+    Block0 const& in,
+    Block1&       out)
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
+    {
+      typedef Scalar_block<1, typename Block1::value_type> scalar_block_type;
+      typedef Binary_expr_block<1, op::Mult,
+	                Block1, typename Block1::value_type,
+	                scalar_block_type, typename Block1::value_type>
+	      expr_block_type;
+
+      scalar_block_type scalar_block(scale_, out.size(1, 0));
+      expr_block_type   expr_block(out, scalar_block);
+      
+      Serial_dispatch<1, Block1, expr_block_type, LibraryTagList>
+	::exec(out, expr_block);
+      // assign<1>(out, expr_block);
+    }
+  }
+
   template <typename BE, typename BlockT>
   void in_place(BE *backend, Vector<std::complex<T>,BlockT> inout)
   {
@@ -351,6 +415,72 @@
       out *= scale_;
   }
 
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference_blk(
+    BE*           backend,
+    Block0 const& in,
+    Block1&       out)
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
+    {
+      typedef Scalar_block<2, typename Block1::value_type> scalar_block_type;
+      typedef Binary_expr_block<2, op::Mult,
+	                Block1, typename Block1::value_type,
+	                scalar_block_type, typename Block1::value_type>
+	      expr_block_type;
+
+      scalar_block_type scalar_block(scale_, out.size(2, 0), out.size(2, 1));
+      expr_block_type   expr_block(out, scalar_block);
+
+      Serial_dispatch<2, Block1, expr_block_type, LibraryTagList>
+	::exec(out, expr_block);
+      // assign<2>(out, expr_block);
+    }
+  }
+
   template <typename BE, typename BlockT>
   void in_place(BE *backend, Matrix<std::complex<T>,BlockT> inout)
   {
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
@@ -178,6 +178,43 @@
 
 
 
+template <typename Block1T,
+	  typename Block2T,
+	  bool Is_direct = 
+	  Type_equal<typename Block_layout<Block1T>::access_type,
+		     Direct_access_tag>::value &&
+	  Type_equal<typename Block_layout<Block2T>::access_type,
+		     Direct_access_tag>::value>
+struct Is_alias_helper
+{
+  static bool value(Block1T const&, Block2T const&) { return false; }
+};
+
+template <typename Block1T,
+	  typename Block2T>
+struct Is_alias_helper<Block1T, Block2T, true>
+{
+  static bool value(Block1T const& blk1, Block2T const& blk2)
+  { return blk1.impl_data() == blk2.impl_data(); }
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
 
@@ -426,8 +463,12 @@
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
Index: src/vsip/opt/expr/return_block.hpp
===================================================================
--- src/vsip/opt/expr/return_block.hpp	(revision 0)
+++ src/vsip/opt/expr/return_block.hpp	(revision 0)
@@ -0,0 +1,232 @@
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
+  map_type const& map() const VSIP_NOTHROW { return rf_.map();}
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
+public:
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
+#if 0 // DISTRIBUTED SUPPORT TO BE IMPLEMENTED
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Distributed_local_block<Return_expr_block<Dim, T, ReturnFunctor> >
+{
+  typedef ... type;
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
+  typedef ... tree_type;
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
+  typedef ... tree_type;
+  typedef tree_type type;
+};
+
+
+  
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+...
+get_local_block(
+  Return_expr_block<Dim, T, ReturnFunctor> const& block)
+{
+  typedef ... block_type;
+
+  return block_type(...);
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
+  return block_type(...);
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
+  apply_leaf(visitor, ...);
+}
+#endif
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
@@ -0,0 +1,125 @@
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
+  Fc_expr_tag
+  >
+{
+  static char const* name() { return "Fc_expr_tag"; }
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
+    // TODO: Check FFT scaling totals 1
+    return true;
+  }
+  
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    length_type rows = dst.size(2, 0);
+    length_type cols = dst.size(2, 1);
+    Matrix<T> tmp(1, cols);
+
+    Vector<T, VecBlockT> w  (
+      const_cast<VecBlockT&>(src.rf_.in_block_.get_vblk()));
+    Matrix<T, MatBlockT> in (
+      const_cast<MatBlockT&>(src.rf_.in_block_.get_mblk().rf_.in_block_));
+    Matrix<T, DstBlock>        out(dst);
+
+    Workspace2T& fwd_workspace(src.rf_.in_block_.get_mblk().rf_.workspace_);
+    Backend2T&   fwd_backend  (src.rf_.in_block_.get_mblk().rf_.backend_);
+    Workspace1T& inv_workspace(src.rf_.workspace_);
+    Backend1T&   inv_backend  (src.rf_.backend_);
+
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
 
@@ -735,6 +732,149 @@
 
 
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
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+#if 0 && PARALLEL_FASTCONV
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
+#else
+    typedef Matrix<T>  view_type;
+    typedef Vector<T>  replica_view_type;
+
+    view_type data(npulse, nrange);
+    view_type tmp(npulse, nrange);
+#endif
+    
+    // Create the pulse replica
+    replica_view_type replica(nrange);
+
+    // int const no_times = 0; // FFTW_PATIENT
+    int const no_times = 15; // not > 12 = FFT_MEASURE
+    
+    typedef Fftm<T, T, row, fft_fwd, by_value, no_times>
+	  	for_fftm_type;
+    typedef Fftm<T, T, row, fft_inv, by_value, no_times>
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
+      data = inv_fftm(vmmul<0>(replica, for_fftm(data)));
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
   Benchmark Driver
 ***********************************************************************/
 
@@ -783,6 +923,34 @@
   case 18: loop(t_fastconv_rf<complex<float>, Impl2fv>(param1)); break;
 #endif
 
+  case  31: loop(t_fastconv_pf<complex<float>, Impl4>(param1)); break;
+  case  32: loop(t_fastconv_rf<complex<float>, Impl4>(param1)); break;
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
+      << " Sweeping number of pulses:\n"
+      << "  -11 -- Out-of-place, phased\n"
+      << "  -12 -- In-place, phased\n"
+      << "  -13 -- Psuedo in-place Fftm (in-place Fft), phased\n"
+      << "  -14 -- Psuedo in-place Fftm (out-of-place Fft), phased\n"
+      << "  -15 -- Out-of-place, interleaved\n"
+      << "  -16 -- In-place, interleaved\n"
+      << "  -17 -- In-place (w/tmp), interleaved\n"
+      << "  -18 -- Foreach_vector, interleaved (2fv)\n"
+      ;
+
   default: return 0;
   }
   return 1;
