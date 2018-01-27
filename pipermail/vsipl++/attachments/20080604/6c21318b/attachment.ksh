Index: ChangeLog
===================================================================
--- ChangeLog	(revision 210528)
+++ ChangeLog	(working copy)
@@ -1,3 +1,19 @@
+2008-06-04  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/subblock.hpp: Support distributed Transposed_blocks
+	  and Component_blocks.
+	* src/vsip/core/setup_assign.hpp: Fix bug finding map_type.
+	* src/vsip/core/parallel/transpose_map_decl.hpp: New file,
+	  Transpose_map class defn.
+	* src/vsip/core/parallel/transpose_map.hpp: New file, Transpose_map
+	  function definition requiring view headers.
+	* src/vsip/core/parallel/subset_map_decl.hpp: Comment Map_subdomain.
+	* src/vsip/core/map_fwd.hpp: Foward decl for Whole_dist.
+	* tests/regressions/par_transpose.cpp: New file, regression test
+	  for distributed transpose cases.
+	* tests/util-par.hpp (dump_view): Synchronize between processors
+	  so output is not intermixed.
+
 2008-06-03  Mike LeBlanc  <mike@codesourcery.com>
 
 	* src/vsip/opt/cbe/cml/conv.hpp: Use aligned_array<> and array_cast().
@@ -17,6 +33,14 @@
 	* src/vsip/opt/cbe/cml/corr.hpp: New file.  Implement the CML backend
 	  for 1D correlation.
 
+2008-06-02  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/core/matvec.hpp: Added include for cml matvec functions.
+	* src/vsip/opt/cbe/cml/matvec.hpp: New evaluators for dot and outer
+	  products.
+	* src/vsip/opt/cbe/cml/prod.hpp: New bindings for dot and outer
+	  product calls into CML.
+
 2008-05-30  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/opt/cbe/cml/matvec.hpp: Added evaluators for matrix-vector
Index: src/vsip/core/subblock.hpp
===================================================================
--- src/vsip/core/subblock.hpp	(revision 210528)
+++ src/vsip/core/subblock.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/core/subblock.hpp
     @author  Zack Weinberg
@@ -43,6 +43,7 @@
 #include <vsip/core/storage.hpp>
 #include <vsip/core/parallel/local_map.hpp>
 #include <vsip/core/parallel/subset_map_decl.hpp>
+#include <vsip/core/parallel/transpose_map_decl.hpp>
 #include <complex>
 
 /***********************************************************************
@@ -143,6 +144,10 @@
       return 2*blk_->impl_stride(dim, d);
   }
 
+  // Implementation specific.
+public:
+  Block const& impl_block() const { return *this->blk_; }
+
 private:
   // Data members.
   typename View_block_storage<Block>::type blk_;
@@ -230,6 +235,9 @@
 
 
 
+// Functor to create map for a subset block from its parent block's map.
+// (not a map class)
+
 template <dimension_type Dim,
 	  typename       MapT>
 struct Subset_block_map
@@ -502,21 +510,29 @@
     : public impl::Compile_time_assert<Block::dim == 2>,
       public impl::Non_assignable
 {
+  // Compile-time values and types (implementation detail).
+private:
+  typedef Transpose_map_of<2, typename Block::map_type> map_functor;
+
+  // Compile-time values and types (part of block interface).
 public:
-  // Compile-time values and types.
   static dimension_type const dim = Block::dim;
   typedef typename Block::value_type value_type;
-  typedef value_type&       reference_type;
-  typedef value_type const& const_reference_type;
-  typedef typename Block::map_type map_type;
+  typedef value_type&                reference_type;
+  typedef value_type const&          const_reference_type;
+  typedef typename map_functor::type map_type;
 
   // Constructors and destructors.
   Transposed_block(Block &blk) VSIP_NOTHROW
     : blk_ (&blk)
-    {}
+    , map_ (map_functor::project(blk.map()))
+  { map_.impl_apply(block_domain<dim>(*this)); }
+
   Transposed_block(Transposed_block const& b)
     : blk_ (&*b.blk_)        // &* work's around holder's lack of copy-cons.
-    {} 
+    , map_ (b.map_)
+  { map_.impl_apply(block_domain<dim>(*this)); }
+
   ~Transposed_block() VSIP_NOTHROW
     {}
 
@@ -532,7 +548,7 @@
   // These are noops as Transposed_block is held by-value.
   void increment_count() const VSIP_NOTHROW {}
   void decrement_count() const VSIP_NOTHROW {}
-  map_type const& map() const { return blk_->map(); }
+  map_type const& map() const { return map_; }
 
   // Data accessors.
   value_type get(index_type i, index_type j) const VSIP_NOTHROW
@@ -564,9 +580,13 @@
     return blk_->impl_stride(dim, 1 - d);
   }
 
+public:
+  Block const& impl_block() const { return *this->blk_; }
+
  private:
   // Data members.
   typename View_block_storage<Block>::type blk_;
+  map_type                                 map_;
 };
 
 // Transposed_block impl_ref if the underlying block has impl_ref.
@@ -1412,6 +1432,28 @@
 
 
 
+template <typename Block>
+struct Distributed_local_block<Transposed_block<Block> >
+{
+  typedef Transposed_block<typename Distributed_local_block<Block>::type> type;
+  typedef Transposed_block<typename Distributed_local_block<Block>::proxy_type>
+		proxy_type;
+};
+
+
+
+template <typename Block,
+          template <typename> class Extractor>
+struct Distributed_local_block<Component_block<Block, Extractor> >
+{
+  typedef Component_block<typename Distributed_local_block<Block>::type,
+			  Extractor> type;
+  typedef Component_block<typename Distributed_local_block<Block>::proxy_type,
+			  Extractor> proxy_type;
+};
+
+
+
 // Helper class to translate a distributed subset into a local subset.
 //
 // In general case, ask the parent block what the local subset should be.
@@ -1456,7 +1498,6 @@
 
 
 
-
 template <typename Block>
 Subset_block<typename Distributed_local_block<Block>::type>
 get_local_block(
@@ -1606,6 +1647,77 @@
 
 
 template <typename Block>
+Transposed_block<typename Distributed_local_block<Block>::type>
+get_local_block(
+  Transposed_block<Block> const& block)
+{
+  typedef typename Distributed_local_block<Block>::type super_type;
+  typedef Transposed_block<super_type>                  local_block_type;
+
+  typename View_block_storage<super_type>::plain_type
+    super_block = get_local_block(block.impl_block());
+
+  return local_block_type(super_block);
+}
+
+
+
+template <typename Block>
+Transposed_block<typename Distributed_local_block<Block>::proxy_type>
+get_local_proxy(
+  Transposed_block<Block> const& block,
+  index_type                     sb)
+{
+  typedef typename Distributed_local_block<Block>::proxy_type super_type;
+  typedef Transposed_block<super_type>                        local_proxy_type;
+
+  typename View_block_storage<super_type>::plain_type
+    super_block = get_local_proxy(block.impl_block(), sb);
+
+  return local_proxy_type(super_block);
+}
+
+
+
+template <typename Block,
+          template <typename> class Extractor>
+Component_block<typename Distributed_local_block<Block>::type, Extractor>
+get_local_block(
+  Component_block<Block, Extractor> const& block)
+{
+  typedef typename Distributed_local_block<Block>::type super_type;
+  typedef Component_block<super_type, Extractor>        local_block_type;
+
+  typename View_block_storage<super_type>::plain_type
+    super_block = get_local_block(block.impl_block());
+
+  return local_block_type(super_block);
+}
+
+
+
+template <typename Block,
+          template <typename> class Extractor>
+Component_block<typename Distributed_local_block<Block>::proxy_type, Extractor>
+get_local_proxy(
+  Component_block<Block, Extractor> const& block,
+  index_type                               sb)
+{
+  typedef typename Distributed_local_block<Block>::proxy_type super_type;
+  typedef Component_block<super_type, Extractor>              local_proxy_type;
+
+  typename View_block_storage<super_type>::plain_type
+    super_block = get_local_proxy(block.impl_block(), sb);
+
+  return local_proxy_type(super_block);
+}
+
+
+
+
+
+
+template <typename Block>
 void
 assert_local(
   Subset_block<Block> const& /*block*/,
@@ -1638,6 +1750,17 @@
 
 
 
+template <typename Block>
+void
+assert_local(
+  Transposed_block<Block> const& block,
+  index_type                     sb)
+{
+  assert_local(block.impl_block(), sb);
+}
+
+
+
 #if VSIP_IMPL_USE_GENERIC_VISITOR_TEMPLATES==0
 
 /// Specialize Combine_return_type for Subset_block leaves.
@@ -1730,6 +1853,35 @@
 {
   return combine.apply(block);
 }
+
+
+
+/// Specialize Combine_return_type for Transposed_block leaves.
+
+template <typename       CombineT,
+	  typename       Block>
+struct Combine_return_type<CombineT, Transposed_block<Block> >
+{
+  typedef Transposed_block<Block> block_type;
+  typedef typename CombineT::template return_type<block_type>::type
+		type;
+  typedef typename CombineT::template tree_type<block_type>::type
+		tree_type;
+};
+
+
+
+/// Specialize apply_combine for Transposed_block leaves.
+
+template <typename       CombineT,
+	  typename       Block>
+typename Combine_return_type<CombineT, Transposed_block<Block> >::type
+apply_combine(
+  CombineT const&                combine,
+  Transposed_block<Block> const& block)
+{
+  return combine.apply(block);
+}
 #endif
 
 
Index: src/vsip/core/setup_assign.hpp
===================================================================
--- src/vsip/core/setup_assign.hpp	(revision 210528)
+++ src/vsip/core/setup_assign.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2008 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/core/setup_assign.hpp
     @author  Jules Bergmann
@@ -221,12 +221,12 @@
   void
   create_holder(View1 dst, View2 src, impl::Tag_par_expr)
   {
-    typedef typename View1::value_type value1_type;
-    typedef typename View2::value_type value2_type;
-    typedef typename View1::block_type block1_type;
-    typedef typename View2::block_type block2_type;
-    typedef typename View1::map_type   map1_type;
-    typedef typename View2::map_type   map2_type;
+    typedef typename View1::value_type           value1_type;
+    typedef typename View2::value_type           value2_type;
+    typedef typename View1::block_type           block1_type;
+    typedef typename View2::block_type           block2_type;
+    typedef typename View1::block_type::map_type map1_type;
+    typedef typename View2::block_type::map_type map2_type;
 
     if (impl::Is_par_same_map<Dim, map1_type, block2_type>::value(
 					dst.block().map(),
Index: src/vsip/core/parallel/subset_map_decl.hpp
===================================================================
--- src/vsip/core/parallel/subset_map_decl.hpp	(revision 210528)
+++ src/vsip/core/parallel/subset_map_decl.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006, 2007, 2008 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/core/parallel/subset_map_decl.hpp
     @author  Jules Bergmann
@@ -299,6 +299,12 @@
   Map subdomain
 ***********************************************************************/
 
+// Map_subdomain is a map functor.  It creates a new map for a
+// subdomain of an existing map.
+
+// General case where subdomain map is identical to parent map.  This
+// applies to Local_map, Global_map, and Local_or_global_map.
+
 template <dimension_type Dim,
 	  typename       MapT>
 struct Map_subdomain
@@ -325,6 +331,8 @@
 
 
 
+// Special case for block-cyclic Maps.
+
 template <dimension_type Dim,
 	  typename       Dist0,
 	  typename       Dist1,
@@ -353,6 +361,8 @@
 
 
 
+// Special case for Subset_maps
+
 template <dimension_type Dim>
 struct Map_subdomain<Dim, Subset_map<Dim> >
 {
Index: src/vsip/core/parallel/transpose_map_decl.hpp
===================================================================
--- src/vsip/core/parallel/transpose_map_decl.hpp	(revision 0)
+++ src/vsip/core/parallel/transpose_map_decl.hpp	(revision 0)
@@ -0,0 +1,255 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/parallel/subset_map_decl.hpp
+    @author  Jules Bergmann
+    @date    2008-05-30
+    @brief   VSIPL++ Library: Map class for transposes.
+
+*/
+
+#ifndef VSIP_CORE_PARALLEL_TRANSPOSE_MAP_DECL_HPP
+#define VSIP_CORE_PARALLEL_TRANSPOSE_MAP_DECL_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/view_fwd.hpp>
+
+
+
+/***********************************************************************
+  Declarations & Class Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+
+template <typename MapT>
+class Transpose_map
+{
+  // Translate tranpose dimension to parent map dimension.
+  dimension_type parent_dim(dimension_type dim)
+  {
+    return (dim == 0) ? 1 : (dim == 1) ? 0 : dim;
+  }
+  // Compile-time typedefs.
+public:
+  static dimension_type const Dim = 2;
+  typedef typename MapT::processor_iterator processor_iterator;
+  typedef typename MapT::impl_pvec_type     impl_pvec_type;
+
+  // Constructor.
+public:
+  Transpose_map(MapT const& map)
+    : map_(map)
+  {}
+
+  ~Transpose_map()
+    {}
+
+
+  // Accessors.
+public:
+  // Information on individual distributions.
+  distribution_type distribution     (dimension_type dim) const VSIP_NOTHROW
+    { return map_.distribution(parent_dim(dim)); }
+
+  length_type       num_subblocks    (dimension_type dim) const VSIP_NOTHROW
+    { return map_.num_subblock(parent_dim(dim)); }
+
+  length_type       cyclic_contiguity(dimension_type dim) const VSIP_NOTHROW
+    { return map_.cyclic_contiguity(parent_dim(dim)); }
+
+  length_type num_subblocks()  const VSIP_NOTHROW
+    { return map_.num_subblocks(); }
+
+  length_type num_processors() const VSIP_NOTHROW
+    { return map_.num_processors(); }
+
+  index_type subblock(processor_type pr) const VSIP_NOTHROW
+    { return map_.subblock(pr); }
+
+  index_type subblock() const VSIP_NOTHROW
+    { return map_.subblock(); }
+
+  processor_iterator processor_begin(index_type sb) const VSIP_NOTHROW
+    { return map_.processor_begin(sb); }
+
+  processor_iterator processor_end  (index_type sb) const VSIP_NOTHROW
+    { return map_.processor_end(sb); }
+
+  const_Vector<processor_type> processor_set() const;
+
+  // Applied map functions.
+public:
+  length_type impl_num_patches(index_type sb) const VSIP_NOTHROW
+    { return map_.impl_num_patches(sb); }
+
+  void impl_apply(Domain<Dim> const& /*dom*/) VSIP_NOTHROW
+  {
+    // TODO assert(extent(dom_) == transpose(extent(dom)));
+  }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_subblock_domain(index_type sb) const VSIP_NOTHROW
+  {
+    assert(sb < this->num_subblocks());
+    Domain<Dim2> p_dom = map_.template impl_subblock_domain<Dim2>(sb);
+    return Domain<Dim2>(p_dom[1], p_dom[0]);
+  }
+
+  template <dimension_type Dim2>
+  impl::Length<Dim2> impl_subblock_extent(index_type sb) const VSIP_NOTHROW
+  {
+    assert(sb < this->num_subblocks());
+    impl::Length<Dim2> p_ext = map_.template impl_subblock_extent<Dim2>(sb);
+    return impl::Length<Dim2>(p_ext[1], p_ext[0]);
+  }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_global_domain(index_type sb, index_type p)
+    const VSIP_NOTHROW
+  {
+    assert(sb < this->num_subblocks());
+    assert(p  < this->impl_num_patches(sb));
+    Domain<Dim2> p_dom = map_.template impl_global_domain<Dim2>(sb, p);
+    return Domain<Dim2>(p_dom[1], p_dom[0]);
+  }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_local_domain (index_type sb, index_type p)
+    const VSIP_NOTHROW
+  {
+    assert(sb < this->num_subblocks());
+    assert(p  < this->impl_num_patches(sb));
+    Domain<Dim2> p_dom = map_.template impl_local_domain<Dim2>(sb, p);
+    return Domain<Dim2>(p_dom[1], p_dom[0]);
+  }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_parent_local_domain(index_type sb) const VSIP_NOTHROW
+  {
+    assert(sb < this->num_subblocks());
+    Domain<Dim2> p_dom = map_.template impl_parent_local_domain<Dim2>(sb);
+    return Domain<Dim2>(p_dom[1], p_dom[0]);
+  }
+
+  index_type impl_global_from_local_index(dimension_type /*d*/, index_type sb,
+				     index_type idx)
+    const VSIP_NOTHROW
+  {
+    VSIP_IMPL_THROW(impl::unimplemented(
+	      "Transpose_map::impl_global_from_local_index not implemented."));
+    return 0;
+  }
+
+  index_type impl_local_from_global_index(dimension_type dim, index_type idx)
+    const VSIP_NOTHROW
+  { return map_.impl_local_from_global_index(parent_dim(dim), idx); }
+
+  template <dimension_type Dim2>
+  index_type impl_subblock_from_global_index(Index<Dim2> const& /*idx*/)
+    const VSIP_NOTHROW
+  {
+    VSIP_IMPL_THROW(impl::unimplemented(
+	      "Transpose_map::impl_subblock_from_global_index not implemented."));
+    return 0;
+  }
+
+  template <dimension_type Dim2>
+  Domain<Dim> impl_local_from_global_domain(index_type sb,
+					    Domain<Dim2> const& dom)
+    const VSIP_NOTHROW
+  {
+    VSIP_IMPL_STATIC_ASSERT(Dim == Dim2);
+    Domain<Dim> p_gdom(dom[1], dom[0]);
+    Domain<Dim> p_ldom = map_.template impl_local_from_global_domain<Dim2>
+                                        (sb, p_gdom);
+    return Domain<Dim>(p_ldom[1], p_ldom[0]);
+  }
+
+  // Extensions.
+public:
+  impl::par_ll_pset_type impl_ll_pset() const VSIP_NOTHROW
+    { return map_.impl_ll_pset(); }
+
+  impl::Communicator&    impl_comm() const
+    { return map_.impl_comm(); }
+
+  impl_pvec_type const&  impl_pvec() const
+    { return map_.impl_pvec(); }
+
+  length_type            impl_working_size() const
+    { return map_.impl_working_size(); }
+
+  processor_type         impl_proc_from_rank(index_type idx) const
+    { return map_.impl_proc_from_rank(idx); }
+
+  index_type impl_rank_from_proc(processor_type pr) const
+    { return map_.impl_rank_from_proc(pr); }
+
+  // Determine parent map subblock corresponding to this map's subblock
+  index_type impl_parent_subblock(index_type sb) const
+    { return map_.impl_parent_subblock(sb); }
+
+public:
+  typedef std::vector<Domain<Dim> >   p_vector_type;
+  typedef std::vector<p_vector_type>  sb_vector_type;
+
+
+  // Member data.
+private:
+  MapT const& map_;
+};
+
+
+
+/// Specialize global traits for Global_map.
+
+template <typename MapT>
+struct Is_global_map<Transpose_map<MapT> >
+{ static bool const value = true; };
+
+
+
+/***********************************************************************
+  Transpose_map_of
+***********************************************************************/
+
+// Functor to transpose a map.
+//
+// Handles both the type conversion ('type') and the runtime
+// conversion ('project').
+
+template <dimension_type Dim,
+	  typename       MapT>
+struct Transpose_map_of
+{
+  typedef Transpose_map<MapT> type;
+
+  static type project(MapT const& map)
+    { return type(map); }
+};
+
+
+
+// Specialization for Local_map.
+
+template <dimension_type Dim>
+struct Transpose_map_of<Dim, Local_map>
+{
+  typedef Local_map type;
+
+  static type project(Local_map const& map)
+    { return map; }
+};
+
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_CORE_PARALLEL_TRANSPOSE_MAP_DECL_HPP
Index: src/vsip/core/parallel/transpose_map.hpp
===================================================================
--- src/vsip/core/parallel/transpose_map.hpp	(revision 0)
+++ src/vsip/core/parallel/transpose_map.hpp	(revision 0)
@@ -0,0 +1,42 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/parallel/transpose_map.hpp
+    @author  Jules Bergmann
+    @date    2008-05-30
+    @brief   VSIPL++ Library: Map class for transposes.
+
+*/
+
+#ifndef VSIP_CORE_PARALLEL_TRANSPOSE_MAP_HPP
+#define VSIP_CORE_PARALLEL_TRANSPOSE_MAP_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/parallel/transpose_map_decl.hpp>
+#include <vsip/vector.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+
+template <typename MapT>
+const_Vector<processor_type>
+Transpose_map<MapT>::processor_set()
+  const
+{
+  return map_.processor_set();
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_CORE_PARALLEL_TRANSPOSE_MAP_HPP
Index: src/vsip/core/map_fwd.hpp
===================================================================
--- src/vsip/core/map_fwd.hpp	(revision 210528)
+++ src/vsip/core/map_fwd.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2008 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/core/map-fwd.hpp
     @author  Jules Bergmann
@@ -18,6 +18,8 @@
 {
 
 // Forward Declarations
+class Whole_dist;
+
 class Block_dist;
 
 class Cyclic_dist;
Index: src/vsip/map.hpp
===================================================================
--- src/vsip/map.hpp	(revision 210528)
+++ src/vsip/map.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/map.hpp
     @author  Jules Bergmann
Index: tests/regressions/par_transpose.cpp
===================================================================
--- tests/regressions/par_transpose.cpp	(revision 0)
+++ tests/regressions/par_transpose.cpp	(revision 0)
@@ -0,0 +1,271 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    tests/regressions/par_transpose.cpp
+    @author  Jules Bergmann
+    @date    2008-05-30
+    @brief   VSIPL++ Library: Unit tests for parallel matrix transpose.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/random.hpp>
+#include <vsip/signal.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
+
+#include "util-par.hpp"
+
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Definitions - Utility Functions
+***********************************************************************/
+
+// Test, exercising subviews
+
+template <typename MapT>
+void
+test(
+  MapT&       map,
+  length_type rows,
+  length_type cols,
+  int         verbose)
+{
+  length_type row, col;
+
+  typedef complex<float> value_type;
+
+  typedef Dense<2, value_type, row2_type, MapT> block_type;
+  typedef Matrix<value_type, block_type>        view_type;
+
+  view_type in1(rows, cols, map);
+  view_type in2(rows, cols, map);
+  view_type tp1(cols, rows, map);
+  view_type tp2(cols, rows, map);
+  view_type tp3(cols, rows, map);
+  view_type tp4(cols, rows, map);
+  view_type tp5(cols, rows, map);
+  view_type tp6(cols, rows, map);
+
+  // Fill in the matrix with data
+  for (row = 0; row < rows; row++)
+  {
+    in1.row(row).real() = +(100.0*row + ramp<float>(0, 1, cols));
+    in1.row(row).imag() = -(100.0*row + ramp<float>(0, 1, cols));
+
+    in2.row(row).real() = +(1.0*row + ramp<float>(0, 100, cols));
+    in2.row(row).imag() = -(1.0*row + ramp<float>(0, 100, cols));
+  }
+
+  tp1 = in1.transpose();
+  tp2 = in1.transpose() + in2.transpose();
+  tp3 = tp1 + in1.transpose() + in2.transpose();
+  // Not supported:
+  // tp4 = in1(Domain<2>(rows, cols)).transpose();
+  tp4 = in1.transpose()(Domain<2>(cols, rows));
+  tp5(Domain<2>(cols, rows)) = in1.transpose()(Domain<2>(cols, rows));
+  tp6(Domain<2>(cols, rows)) = in1.transpose()(Domain<2>(cols, rows)) +
+                               in2.transpose();
+
+  if (verbose)
+  {
+    dump_view("in1", in1);
+    dump_view("in2", in2);
+    dump_view("tp2", tp2);
+  }
+
+  for (row = 0; row < rows; row++)
+    for (col = 0; col < cols; col++)
+    {
+      test_assert(in1.get(row, col).real() == +(100*row + 1*col));
+      test_assert(in1.get(row, col).imag() == -(100*row + 1*col));
+      test_assert(in2.get(row, col).real() == +(1*row + 100*col));
+      test_assert(in2.get(row, col).imag() == -(1*row + 100*col));
+
+      test_assert(tp1.get(col, row) == in1.get(row, col));
+      test_assert(tp2.get(col, row) == 
+		  (in1.get(row, col) + in2.get(row, col)));
+      test_assert(tp3.get(col, row) == 
+		  (tp1.get(col, row) + in1.get(row, col) + in2.get(row, col)));
+      test_assert(tp4.get(col, row) == in1.get(row, col));
+      test_assert(tp5.get(col, row) == in1.get(row, col));
+      test_assert(tp6.get(col, row) == 
+		  (in1.get(row, col) + in2.get(row, col)));
+    }
+}
+
+
+
+// Test, without exercising subviews
+
+template <typename MapT>
+void
+test_wo_subviews(
+  MapT&       map,
+  length_type rows,
+  length_type cols)
+{
+  length_type row, col;
+
+  typedef complex<float> value_type;
+
+  typedef Dense<2, value_type, row2_type, MapT> block_type;
+  typedef Matrix<value_type, block_type>        view_type;
+
+  view_type in1(rows, cols, map);
+  view_type in2(rows, cols, map);
+  view_type tp1(cols, rows, map);
+  view_type tp2(cols, rows, map);
+  view_type tp3(cols, rows, map);
+
+  // Fill in the matrix with data
+  for (row = 0; row < rows; row++)
+  {
+    in1.row(row).real() = +(2.0*row + ramp<float>(0, 1, cols));
+    in1.row(row).imag() = -(2.0*row + ramp<float>(0, 1, cols));
+
+    in2.row(row).real() = +(1.0*row + ramp<float>(0, 2, cols));
+    in2.row(row).imag() = -(1.0*row + ramp<float>(0, 2, cols));
+  }
+
+  tp1 = in1.transpose();
+  tp2 = in1.transpose() + in2.transpose();
+  tp3 = tp1 + in1.transpose() + in2.transpose();
+
+  for (row = 0; row < rows; row++)
+    for (col = 0; col < cols; col++)
+    {
+      test_assert(tp1.get(col, row) == in1.get(row, col));
+      test_assert(tp2.get(col, row) == 
+		  (in1.get(row, col) + in2.get(row, col)));
+      test_assert(tp3.get(col, row) == 
+		  (tp1.get(col, row) + in1.get(row, col) + in2.get(row, col)));
+    }
+}
+
+template <typename MapT>
+void
+test_x(
+  MapT&       map,
+  length_type rows,
+  length_type cols)
+{
+  length_type row, col;
+
+  typedef complex<float> value_type;
+
+  typedef Dense<2, value_type, row2_type, MapT> block_type;
+  typedef Matrix<value_type, block_type>        view_type;
+
+  view_type in1(rows, cols, map);
+  view_type in2(rows, cols, map);
+  view_type tp2(cols, rows, map);
+
+  // Fill in the matrix with data
+  for (row = 0; row < rows; row++)
+  {
+    in1.row(row).real() = +(2.0*row + ramp<float>(0, 1, cols));
+    in1.row(row).imag() = -(2.0*row + ramp<float>(0, 1, cols));
+
+    in2.row(row).real() = +(1.0*row + ramp<float>(0, 2, cols));
+    in2.row(row).imag() = -(1.0*row + ramp<float>(0, 2, cols));
+  }
+
+  tp2 = in1.transpose() + in2.transpose();
+
+  for (row = 0; row < rows; row++)
+    for (col = 0; col < cols; col++)
+    {
+      test_assert(tp2.get(col, row) == 
+		  (in1.get(row, col) + in2.get(row, col)));
+    }
+}
+
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+#if 0
+  // Enable this section for easier debugging.
+  impl::Communicator& comm = impl::default_communicator();
+  pid_t pid = getpid();
+
+  std::cout << "rank: "   << comm.rank()
+	    << "  size: " << comm.size()
+	    << "  pid: "  << pid
+	    << std::endl;
+
+  // Stop each process, allow debugger to be attached.
+  if (comm.rank() == 0) fgetc(stdin);
+  comm.barrier();
+  std::cout << "start\n";
+#endif
+
+  Map<> m;
+  // Block-cylic maps ---------------------------------------------------
+  {
+    msg(m, "block-cyclic - 1\n");
+    typedef Map<Block_dist, Whole_dist> map_type;
+    map_type map = map_type(num_processors(), 1);
+    test(map, 4, 8, 0);
+  }
+
+  {
+    msg(m, "block-cyclic - 2\n");
+    typedef Map<Whole_dist, Block_dist> map_type;
+    map_type map = map_type(1, num_processors());
+    test(map, 4, 8, 0);
+  }
+
+  {
+    msg(m, "block-cyclic - 3\n");
+    length_type np = num_processors();
+    length_type npr, npc;
+    get_np_square(np, npr, npc);
+    typedef Map<Block_dist, Block_dist> map_type;
+    map_type map = map_type(npr, npc);
+    test(map, 4, 8, 0);
+  }
+
+  {
+    msg(m, "block-cyclic - 4\n");
+    length_type np = num_processors();
+    length_type npr, npc;
+    get_np_square(np, npr, npc);
+    typedef Map<Cyclic_dist, Block_dist> map_type;
+    map_type map = map_type(npr, npc);
+    test_wo_subviews(map, 16, 32);
+  }
+
+  // Local map ----------------------------------------------------------
+  {
+    msg(m, "local\n");
+    typedef Local_map map_type;
+    map_type map;
+    test(map, 4, 8, 0);
+  }
+
+  // Global map ---------------------------------------------------------
+  {
+    msg(m, "global\n");
+    typedef Global_map<2> map_type;
+    map_type map;
+    test(map, 4, 8, 0);
+  }
+}
Index: tests/util-par.hpp
===================================================================
--- tests/util-par.hpp	(revision 210528)
+++ tests/util-par.hpp	(working copy)
@@ -207,6 +207,7 @@
 {
   using vsip::index_type;
   using vsip::dimension_type;
+  using vsip::processor_type;
   using vsip::no_subblock;
   using vsip::impl::Distributed_local_block;
 
@@ -215,50 +216,63 @@
   typedef typename Distributed_local_block<Block>::type local_block_t;
 
   map_t const& am    = view.block().map();
+  vsip::impl::Communicator comm = am.impl_comm();
+  vsip::Vector<processor_type> pset = vsip::processor_set();
 
   msg(am, std::string(name) + " ------------------------------------------\n");
-  std::cout << "(" << vsip::local_processor() << "): dump_view(Matrix "
-	    << name << ")\n";
 
-  index_type sb = am.subblock();
-  if (sb != no_subblock)
+  for (index_type i=0; i<pset.size(); i++)
   {
-    vsip::Matrix<T, local_block_t> local_view = view.local();
-
-    for (index_type p=0; p<am.num_patches(sb); ++p)
+    comm.barrier();
+    if (vsip::local_processor() == pset.get(i))
     {
-      char str[256];
-      sprintf(str, "  lblock: %08lx", (unsigned long)&(local_view.block()));
 
-      std::cout << "  subblock: " << sb
-	   << "  patch: " << p
-	   << str
-	   << std::endl;
-      vsip::Domain<dim> ldom = am.template local_domain<dim>(sb, p);
-      vsip::Domain<dim> gdom = am.template global_domain<dim>(sb, p);
+      index_type sb = am.subblock();
+      if (sb != no_subblock)
+      {
+	vsip::Matrix<T, local_block_t> local_view = view.local();
 
-      for (index_type r=0; r<ldom[0].length(); ++r) 
-	for (index_type c=0; c<ldom[1].length(); ++c) 
+	for (index_type p=0; p<num_patches(view, sb); ++p)
 	{
-	  index_type lr = ldom[0].impl_nth(r);
-	  index_type lc = ldom[1].impl_nth(c);
+	  char str[256];
+	  sprintf(str, "  lblock: %08lx",
+		  (unsigned long)&(local_view.block()));
 
-	  index_type gr = gdom[0].impl_nth(r);
-	  index_type gc = gdom[1].impl_nth(c);
+	  std::cout << "(" << vsip::local_processor() << "): dump_view(Matrix "
+		    << name << ") "
+		    << "  subblock: " << sb
+		    << "  patch: " << p
+		    << str
+		    << std::endl;
+	  vsip::Domain<dim> ldom = local_domain(view, sb, p);
+	  vsip::Domain<dim> gdom = global_domain(view, sb, p);
 
-	  std::cout << "(" << vsip::local_processor() << ") " << sb << "/" << p
-	       << "    ["
-	       << lr << "," << lc << ":"
-	       << gr << "," << gc << "] = "
-	       << local_view.get(lr, lc)
-	       << std::endl;
+	  for (index_type r=0; r<ldom[0].length(); ++r) 
+	    for (index_type c=0; c<ldom[1].length(); ++c) 
+	    {
+	      index_type lr = ldom[0].impl_nth(r);
+	      index_type lc = ldom[1].impl_nth(c);
+	      
+	      index_type gr = gdom[0].impl_nth(r);
+	      index_type gc = gdom[1].impl_nth(c);
+	      
+	      std::cout << "(" << vsip::local_processor() << ") "
+			<< sb << "/" << p
+			<< "    ["
+			<< lr << "," << lc << ":"
+			<< gr << "," << gc << "] = "
+			<< local_view.get(lr, lc)
+			<< std::endl;
+	    }
+	}
       }
+      else
+      {
+	std::cout << "(" << vsip::local_processor() << "): dump_view(Matrix "
+		  << name << ") no subblock\n";
+      }
     }
   }
-  else
-  {
-    std::cout << "  no_subblock" << std::endl;
-  }
 
   msg(am, " ------------------------------------------\n");
 }
