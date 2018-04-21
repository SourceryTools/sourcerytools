Index: ChangeLog
===================================================================
--- ChangeLog	(revision 147999)
+++ ChangeLog	(working copy)
@@ -1,3 +1,109 @@
+2006-08-30  Jules Bergmann  <jules@codesourcery.com>
+
+	Support for using PAS for parallel services.
+	* src/vsip/par-services.cpp (global_tag): Counter to generate
+	  unique tags for PAS pbuffer allocations.
+	* src/vsip/dense.hpp: Move Dense forward decl into dense_fwd.
+	  Use Choose_dist_block to choose distributed block type.
+	  Define get_local_proxy() function and Is_pas_block trait.
+	* src/vsip/impl/expr_generator_block.hpp (Distributed_local_block):
+	  Define proxy_type.
+	* src/vsip/impl/expr_binary_block.hpp: Likewise.
+	* src/vsip/impl/expr_unary_block.hpp: Likewise.
+	* src/vsip/impl/expr_scalar_block.hpp: Likewise.
+	* src/vsip/impl/working-view.hpp: Remove unnecessary include.
+	* src/vsip/impl/par-util.hpp: Likewise.
+	* src/vsip/impl/par-support.hpp: Likewise.
+	* src/vsip/impl/dense_fwd.hpp: New file, forward declaration of
+	  Dense block.
+	* src/vsip/impl/replicated_map.hpp: Store data in ref-counted
+	  Data member.  Add PAS support.
+	* src/vsip/impl/distributed-block.hpp: Move get_local_view bits
+	  to get_local_view.hpp.
+	* src/vsip/impl/pas/block.hpp: New file, distributed block for
+	  PAS.
+	* src/vsip/impl/pas/util.hpp: New file, utility functions for PAS.
+	* src/vsip/impl/pas/param.hpp: New file, parameters for PAS
+	  configuration.
+	* src/vsip/impl/pas/par_assign_direct.hpp: New file, PAS
+	  assignment using direct low-level point-to-point messaging.
+	* src/vsip/impl/pas/par_assign.hpp: New file, PAS assignment using
+	  high-level collective messaging.
+	* src/vsip/impl/pas/broadcast.hpp: New file, broadcast utility
+	  for PAS.
+	* src/vsip/impl/pas/services.hpp: New file, parallel services
+	  for PAS.
+	* src/vsip/impl/par_assign_common.hpp: New file, common routines
+	  for Par_assign.
+	* src/vsip/impl/par-services.hpp: Add include to pas/services.hpp.
+	* src/vsip/impl/config.hpp: Add parallel configuration section.
+	* src/vsip/impl/choose_par_assign_impl.hpp: New file, trait
+	  class to choose appropriate parallel assignment implementation.
+	* src/vsip/impl/par_assign_blkvec.hpp: Add missing include.
+	* src/vsip/impl/par-chain-assign.hpp: Move processor_has_block
+	  to par_assign_common.hpp.
+	* src/vsip/impl/par-services-mpi.hpp: Add dummy typedefs/functions
+	  for par_ll_pset_type.
+	* src/vsip/impl/dist.hpp: Add support for using PAS' segment
+	  size algorithm.
+	* src/vsip/impl/choose_dist_block.hpp: New file, trait class to
+	  choose the correct distributed block for the parallel impl.
+	* src/vsip/impl/get_local_view.hpp: New file, common get_local_view
+	  routines from distributed-block.hpp.
+	* src/vsip/impl/block-traits.hpp (Distributed_local_block): Add
+	  proxy_type typedef.
+	  (Is_pas_block): New trait to indicate if block has a valid
+	  PAS distribution.
+	* src/vsip/impl/sv_block.hpp (impl_vector): Return reference.
+	* src/vsip/impl/proxy_local_block.hpp: New file, proxy class
+	  for local blocks on remote processors.  Used to query layout
+	  parameters such as stride.
+	* src/vsip/impl/dispatch-assign.hpp: Move par_assign impl tag
+	  choice into Choose_par_assign_impl.
+	* src/vsip/impl/par_assign.hpp: Remove forward decl to
+	  par_assign_fwd.  Wrapper header for all par_assign files.
+	* src/vsip/impl/par-expr.hpp: Use Choose_par_assign_impl
+	  to determine appropriate Par_assign implementation.
+	* src/vsip/impl/subblock.hpp: Add PAS support (impl_ll_pbuf
+	  forwarding, proxy local block forwarding).
+	* src/vsip/impl/par_assign_fwd.hpp: New file, foward decl of
+	  Par_assign class.
+	* src/vsip/impl/global_map.hpp: Add PAS support.
+	* src/vsip/support.hpp (Dim_of): New traits class to extract
+	  dimension ordering from tuple.  Add PAS support.
+	* src/vsip/map.hpp: Add PAS support.
+	* src/vsip/random.hpp: Add missing header.
+	* src/vsip_csl/test.hpp (VSIP_IMPL_TEST_DOUBLE): New macro to control
+	  testing of double precision.
+	  VSIP_IMPL_TEST_LONG_DOUBLE): Likewise, for long double.
+	* tests/reductions-idx.cpp (VSIP_IMPL_TEST_DOUBLE): Use it. 
+	* tests/histogram.cpp: Likewise.
+	* tests/solver-toepsol.cpp: Likewise.
+	* tests/freqswap.cpp: Likewise.
+	* tests/corr-2d.cpp: Likewise.
+	* tests/conv-2d.cpp: Likewise.
+	* tests/correlation.cpp: Likewise.
+	* tests/reductions.cpp: Likewise.
+	* tests/convolution.cpp: Likewise.
+	* tests/solver-cholesky.cpp: Likewise.
+	* tests/domain.cpp: Add command line processing.
+	* tests/dense.cpp: Likewise.
+	* tests/parallel/expr.cpp: Updates for PAS (pass COmmunicator by
+	  reference, use VSIP_DIST_LEVEL).
+	* tests/parallel/user-storage.cpp: Likewise.
+	* tests/parallel/subviews.cpp: Likewise.
+	* tests/parallel/block.cpp: Updates for PAS, refactor to have
+	  more commonality between explicit and implicit parallel
+	  assignment tests.
+	* tests/appmap.cpp: Add tests for empty subblocks.
+	* tests/segment_size.cpp: New file, unit test for segment_size().
+	* benchmarks/loop.hpp: Pass communicators by reference.
+	* benchmarks/main.cpp: Likewise.
+	* examples/mercury/mcoe-setup.sh: Add configure flags for pas.
+	* configure.ac (--enable-pas): New configuration option to
+	  enable PAS.
+	* autogen.sh: Include aclocal.
+
 2006-08-30  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/impl/par-foreach.hpp: Added missing header.
Index: src/vsip/par-services.cpp
===================================================================
--- src/vsip/par-services.cpp	(revision 147999)
+++ src/vsip/par-services.cpp	(working copy)
@@ -32,6 +32,18 @@
 namespace vsip
 {
 
+namespace impl
+{
+
+namespace pas
+{
+
+/// Counter to generate a unique tag for global PAS pbuffer allocations.
+long             global_tag = 1;
+
+} // namespace vspi::impl::pas
+} // namespace vspi::impl
+
 /// Return the number of processors in the data parallel clique.
 
 length_type
Index: src/vsip/dense.hpp
===================================================================
--- src/vsip/dense.hpp	(revision 147999)
+++ src/vsip/dense.hpp	(working copy)
@@ -18,11 +18,13 @@
 
 #include <vsip/support.hpp>
 #include <vsip/domain.hpp>
+#include <vsip/impl/dense_fwd.hpp>
 #include <vsip/impl/refcount.hpp>
 #include <vsip/impl/local_map.hpp>
 #include <vsip/impl/layout.hpp>
 #include <vsip/impl/extdata.hpp>
 #include <vsip/impl/block-traits.hpp>
+#include <vsip/impl/choose_dist_block.hpp>
 #include <vsip/domain.hpp>
 
 /// Complex storage format for dense blocks.
@@ -50,29 +52,11 @@
 
 
 
-/// Dense block, as defined in standard [view.dense].
-
-/// "A Dense block is a modifiable, allocatable 1-dimensional block
-/// or 1,x-dimensional block, for a fixed x, that explicitly stores
-/// one value for each Index in its domain."
-
-template <dimension_type Dim      = 1,
-	  typename       T        = VSIP_DEFAULT_VALUE_TYPE,
-	  typename       Order    = typename impl::Row_major<Dim>::type,
-	  typename       Map      = Local_map>
-class Dense;
-
-
-
 namespace impl
 { 
 
 typedef VSIP_IMPL_DENSE_CMPLX_FMT dense_complex_type;
 
-/// Forward Declaration
-template <typename Block,
-	  typename Map>
-class Distributed_block;
 
 
 /// If provided type is complex, extract the component type,
@@ -595,6 +579,8 @@
   // const_data_type impl_data() const VSIP_NOTHROW { return storage_.data(); }
   stride_type impl_stride(dimension_type D, dimension_type d)
     const VSIP_NOTHROW;
+  long impl_offset() VSIP_NOTHROW
+  { return 0; }
 
   // Hidden copy constructor and assignment.
 private:
@@ -674,10 +660,9 @@
 	  typename OrderT,
 	  typename MapT>
 class Dense<1, T, OrderT, MapT>
-  : public impl::Distributed_block<Dense<1, T, OrderT, Local_map>, MapT>
+  : public impl::Choose_dist_block<1, T, OrderT, MapT>::type
 {
-  typedef impl::Distributed_block<Dense<1, T, OrderT, Local_map>, MapT>
-		base_type;
+  typedef typename impl::Choose_dist_block<1, T, OrderT, MapT>::type base_type;
   enum private_type {};
   typedef typename impl::Complex_value_type<T, private_type>::type uT;
 
@@ -793,10 +778,9 @@
 	  typename OrderT,
 	  typename MapT>
 class Dense<2, T, OrderT, MapT>
-  : public impl::Distributed_block<Dense<2, T, OrderT, Local_map>, MapT>
+  : public impl::Choose_dist_block<2, T, OrderT, MapT>::type
 {
-  typedef impl::Distributed_block<Dense<2, T, OrderT, Local_map>, MapT>
-		base_type;
+  typedef typename impl::Choose_dist_block<2, T, OrderT, MapT>::type base_type;
   enum private_type {};
   typedef typename impl::Complex_value_type<T, private_type>::type uT;
 
@@ -916,10 +900,9 @@
 	  typename OrderT,
 	  typename MapT>
 class Dense<3, T, OrderT, MapT>
-  : public impl::Distributed_block<Dense<3, T, OrderT, Local_map>, MapT>
+  : public impl::Choose_dist_block<3, T, OrderT, MapT>::type
 {
-  typedef impl::Distributed_block<Dense<3, T, OrderT, Local_map>, MapT>
-		base_type;
+  typedef typename impl::Choose_dist_block<3, T, OrderT, MapT>::type base_type;
   enum private_type {};
   typedef typename impl::Complex_value_type<T, private_type>::type uT;
 
@@ -1012,7 +995,7 @@
 
 
 
-/// Specialize Distributed_local_block traits class for Distributed_block.
+/// Specialize Distributed_local_block traits class for Dense.
 
 /// For a serial map, distributed block and local block are the same.
 
@@ -1022,6 +1005,7 @@
 struct Distributed_local_block<Dense<Dim, T, OrderT, Local_map> >
 {
   typedef Dense<Dim, T, OrderT, Local_map> type;
+  typedef Dense<Dim, T, OrderT, Local_map> proxy_type;
 };
 
 
@@ -1041,6 +1025,8 @@
   // However, to be safe, we'll extract it from the block itself:
   // (local_block is set in the base class Distributed_block.)
   typedef typename Dense<Dim, T, OrderT, MapT>::local_block_type type;
+  typedef typename Dense<Dim, T, OrderT, MapT>::proxy_local_block_type
+    proxy_type;
 };
 
 
@@ -1084,6 +1070,20 @@
 
 
 
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+inline typename Dense<Dim, T, OrderT, MapT>::proxy_local_block_type
+get_local_proxy(
+  Dense<Dim, T, OrderT, MapT> const& block,
+  index_type                         sb)
+{
+  return block.impl_proxy_block(sb);
+}
+
+
+
 /// Assert that subblock is local to block (overload).
 
 template <dimension_type Dim,
@@ -1166,6 +1166,24 @@
 
 
 
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT>
+struct Is_pas_block<Dense<Dim, T, OrderT, Local_map> >
+{
+  static bool const value = false;
+};
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+struct Is_pas_block<Dense<Dim, T, OrderT, MapT> >
+  : Is_pas_block<typename impl::Choose_dist_block<Dim, T, OrderT, MapT>::type>
+{};
+
+
+
 /***********************************************************************
   Definitions - Dense_storage
 ***********************************************************************/
Index: src/vsip/impl/expr_generator_block.hpp
===================================================================
--- src/vsip/impl/expr_generator_block.hpp	(revision 147999)
+++ src/vsip/impl/expr_generator_block.hpp	(working copy)
@@ -132,6 +132,7 @@
 struct Distributed_local_block<Generator_expr_block<Dim, Generator> const>
 {
   typedef Generator_expr_block<Dim, Generator> const type;
+  typedef Generator_expr_block<Dim, Generator> const proxy_type;
 };
 
 
Index: src/vsip/impl/working-view.hpp
===================================================================
--- src/vsip/impl/working-view.hpp	(revision 147999)
+++ src/vsip/impl/working-view.hpp	(working copy)
@@ -24,7 +24,6 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/impl/par-services.hpp>
-#include <vsip/impl/distributed-block.hpp>
 #include <vsip/impl/static_assert.hpp>
 #include <vsip/impl/metaprogramming.hpp>
 
Index: src/vsip/impl/dense_fwd.hpp
===================================================================
--- src/vsip/impl/dense_fwd.hpp	(revision 0)
+++ src/vsip/impl/dense_fwd.hpp	(revision 0)
@@ -0,0 +1,42 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/dense_fwd.hpp
+    @author  Jules Bergmann
+    @date    2006-08-29
+    @brief   VSIPL++ Library: Dense block class foward decl.
+
+*/
+
+#ifndef VSIP_IMPL_DENSE_FWD_HPP
+#define VSIP_IMPL_DENSE_FWD_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
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
+/// Dense block, as defined in standard [view.dense].
+
+/// "A Dense block is a modifiable, allocatable 1-dimensional block
+/// or 1,x-dimensional block, for a fixed x, that explicitly stores
+/// one value for each Index in its domain."
+
+template <dimension_type Dim      = 1,
+	  typename       T        = VSIP_DEFAULT_VALUE_TYPE,
+	  typename       Order    = typename impl::Row_major<Dim>::type,
+	  typename       Map      = Local_map>
+class Dense;
+
+} // namespace vsip
+
+#endif // VSIP_IMPL_DENSE_FWD_HPP
Index: src/vsip/impl/expr_binary_block.hpp
===================================================================
--- src/vsip/impl/expr_binary_block.hpp	(revision 147999)
+++ src/vsip/impl/expr_binary_block.hpp	(working copy)
@@ -140,6 +140,12 @@
 			    typename Distributed_local_block<RBlock>::type,
 			    RType> const
 		type;
+  typedef Binary_expr_block<D, Operator,
+			typename Distributed_local_block<LBlock>::proxy_type,
+			LType,
+			typename Distributed_local_block<RBlock>::proxy_type,
+			RType> const
+		proxy_type;
 };
 
 
@@ -159,6 +165,12 @@
 			    typename Distributed_local_block<RBlock>::type,
 			    RType>
 		type;
+  typedef Binary_expr_block<D, Operator,
+			typename Distributed_local_block<LBlock>::proxy_type,
+			LType,
+			typename Distributed_local_block<RBlock>::proxy_type,
+			RType>
+		proxy_type;
 };
 
 
Index: src/vsip/impl/replicated_map.hpp
===================================================================
--- src/vsip/impl/replicated_map.hpp	(revision 147999)
+++ src/vsip/impl/replicated_map.hpp	(working copy)
@@ -39,6 +39,33 @@
   typedef std::vector<processor_type> impl_pvec_type;
   typedef impl::Sv_local_block<processor_type> pset_block_type;
 
+  // Replicated_map_data
+private:
+  struct Data : public impl::Ref_count<Data>, impl::Non_copyable
+  {
+
+    Data(length_type np)
+      : pset_(np)
+    {}
+
+    ~Data()
+    {
+      impl::destroy_ll_pset(ll_pset_);
+    }
+
+    void init_ll_pset()
+    {
+      impl::create_ll_pset(pset_.impl_vector_ref(), ll_pset_);
+    }
+
+    // Member data.
+  public:
+    pset_block_type        pset_;
+    impl::par_ll_pset_type ll_pset_;
+  };
+
+
+
   // Constructor.
 public:
   Replicated_map()
@@ -48,13 +75,27 @@
   Replicated_map(const_Vector<processor_type, Block> pset)
     VSIP_THROW((std::bad_alloc));
 
+  ~Replicated_map()
+  {
+  }
+
+  // Default copy constructor and assignment operator are correct.
+
   // Accessors.
 public:
+  // Information on individual distributions.
+  distribution_type distribution     (dimension_type) const VSIP_NOTHROW
+    { return whole; }
+  length_type       num_subblocks    (dimension_type) const VSIP_NOTHROW
+    { return 1; }
+  length_type       cyclic_contiguity(dimension_type) const VSIP_NOTHROW
+    { return 0; }
+
   length_type num_subblocks() const VSIP_NOTHROW { return 1; }
 
   index_type subblock(processor_type pr) const VSIP_NOTHROW
   {
-    if (this->impl_rank_from_proc(pr) != no_processor)
+    if (this->impl_rank_from_proc(pr) != no_rank)
       return 0;
     else
       return no_subblock;
@@ -63,7 +104,7 @@
   { return this->subblock(local_processor()); }
 
   length_type num_processors() const VSIP_NOTHROW
-    { return this->pset_->size(); }
+    { return this->data_->pset_.size(); }
 
   processor_iterator processor_begin(index_type sb) const VSIP_NOTHROW
   {
@@ -79,8 +120,7 @@
 
   const_Vector<processor_type, pset_block_type> processor_set() const
   {
-    return const_Vector<processor_type, pset_block_type>(
-      const_cast<pset_block_type&>(*pset_));
+    return const_Vector<processor_type, pset_block_type>(data_->pset_);
   }
 
   // Applied map functions.
@@ -96,6 +136,10 @@
     { assert(sb == 0); return dom_; }
 
   template <dimension_type Dim2>
+  impl::Length<Dim2> impl_subblock_extent(index_type sb) const VSIP_NOTHROW
+    { assert(sb == 0); return extent(dom_); }
+
+  template <dimension_type Dim2>
   Domain<Dim2> impl_global_domain(index_type sb, index_type patch)
     const VSIP_NOTHROW
     { assert(sb == 0 && patch == 0); return dom_; }
@@ -121,9 +165,13 @@
 
   // Extensions.
 public:
+  impl::par_ll_pset_type impl_ll_pset() const VSIP_NOTHROW
+    { return data_->ll_pset_; }
   impl::Communicator& impl_comm() const { return impl::default_communicator();}
   impl_pvec_type      impl_pvec() const
-    { return this->pset_->impl_vector(); }
+    { return data_->pset_.impl_vector(); }
+  impl_pvec_type const&      impl_pvec_ref() const
+    { return data_->pset_.impl_vector_ref(); }
 
   length_type        impl_working_size() const
     { return this->num_processors(); }
@@ -134,15 +182,15 @@
   index_type impl_rank_from_proc(processor_type pr) const
   {
     for (index_type i=0; i<this->num_processors(); ++i)
-      if (pset_->get(i) == pr) return i;
+      if (data_->pset_.get(i) == pr) return i;
     return no_processor;
   }
 
+
   // Member data.
 private:
-  impl::Ref_counted_ptr<pset_block_type> pset_;
-  // impl_pvec_type pset_;		// Processor set.
-  Domain<Dim>    dom_;		// Applied domain.
+  Domain<Dim>                 dom_;		// Applied domain.
+  impl::Ref_counted_ptr<Data> data_;
 };
 
 
@@ -150,10 +198,12 @@
 template <dimension_type Dim>
 Replicated_map<Dim>::Replicated_map()
   VSIP_THROW((std::bad_alloc))
-    : pset_(new pset_block_type(vsip::num_processors()), impl::noincrement)
+    : data_(new Data(vsip::num_processors()))
 {
   for (index_type i=0; i<vsip::num_processors(); ++i)
-    pset_->put(i, vsip::processor_set().get(i));
+    data_->pset_.put(i, vsip::processor_set().get(i));
+
+  data_->init_ll_pset();
 }
 
 
@@ -167,11 +217,13 @@
 Replicated_map<Dim>::Replicated_map(
   const_Vector<processor_type, Block> pset)
   VSIP_THROW((std::bad_alloc))
-: pset_(new pset_block_type(pset.size()), impl::noincrement)
+    : data_(new Data(pset.size()))
 {
   assert(pset.size() > 0);
   for (index_type i=0; i<pset.size(); ++i)
-    pset_->put(i, pset.get(i));
+    data_->pset_.put(i, pset.get(i));
+
+  data_->init_ll_pset();
 }
 
 
Index: src/vsip/impl/distributed-block.hpp
===================================================================
--- src/vsip/impl/distributed-block.hpp	(revision 147999)
+++ src/vsip/impl/distributed-block.hpp	(working copy)
@@ -18,6 +18,8 @@
 #include <vsip/map_fwd.hpp>
 #include <vsip/impl/block-traits.hpp>
 #include <vsip/impl/domain-utils.hpp>
+#include <vsip/impl/get_local_view.hpp>
+#include <vsip/impl/proxy_local_block.hpp>
 
 
 
@@ -52,6 +54,9 @@
 
   // Non-standard typedefs:
   typedef Block                                local_block_type;
+  typedef typename Block_layout<local_block_type>::layout_type
+                                               local_LP;
+  typedef Proxy_local_block<dim, value_type, local_LP>  proxy_local_block_type;
 
   // Private compile-time values and types.
 private:
@@ -514,71 +519,6 @@
 
 
 
-
-/// Get a local view of a subblock.
-
-template <template <typename, typename> class View,
-	  typename                            T,
-	  typename                            Block,
-	  typename                            MapT = typename Block::map_type>
-struct Get_local_view_class
-{
-  static
-  View<T, typename Distributed_local_block<Block>::type>
-  exec(
-    View<T, Block> v)
-  {
-    typedef typename Distributed_local_block<Block>::type block_t;
-    typedef typename View_block_storage<block_t>::type::equiv_type storage_t;
-
-    storage_t blk = get_local_block(v.block());
-    return View<T, block_t>(blk);
-  }
-};
-
-template <template <typename, typename> class View,
-	  typename                            T,
-	  typename                            Block>
-struct Get_local_view_class<View, T, Block, Local_map>
-{
-  static
-  View<T, typename Distributed_local_block<Block>::type>
-  exec(
-    View<T, Block> v)
-  {
-    typedef typename Distributed_local_block<Block>::type block_t;
-    assert((Type_equal<Block, block_t>::value));
-    return v;
-  }
-};
-	  
-
-
-template <template <typename, typename> class View,
-	  typename                            T,
-	  typename                            Block>
-View<T, typename Distributed_local_block<Block>::type>
-get_local_view(
-  View<T, Block> v)
-{
-  return Get_local_view_class<View, T, Block>::exec(v);
-}
-
-
-
-template <template <typename, typename> class View,
-	  typename                            T,
-	  typename                            Block>
-void
-view_assert_local(
-  View<T, Block> v,
-  index_type     sb)
-{
-  assert_local(v.block(), sb);
-}
-
-
-
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/impl/pas/block.hpp
===================================================================
--- src/vsip/impl/pas/block.hpp	(revision 0)
+++ src/vsip/impl/pas/block.hpp	(revision 0)
@@ -0,0 +1,958 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/pas-block.hpp
+    @author  Jules Bergmann
+    @date    2006-06-22
+    @brief   VSIPL++ Library: Distributed block class.
+
+*/
+
+#ifndef VSIP_IMPL_PAS_BLOCK_HPP
+#define VSIP_IMPL_PAS_BLOCK_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+extern "C" {
+#include <pas.h>
+}
+
+#include <vsip/support.hpp>
+#include <vsip/impl/block-traits.hpp>
+#include <vsip/impl/domain-utils.hpp>
+#include <vsip/impl/dist.hpp>
+#include <vsip/impl/get_local_view.hpp>
+#include <vsip/impl/proxy_local_block.hpp>
+
+#define VSIP_IMPL_PAS_BLOCK_VERBOSE 0
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
+namespace pas
+{
+
+template <typename       T,
+	  typename       OrderT,
+	  dimension_type Dim,
+	  typename       MapT>
+void
+pbuf_create(
+  long                     tag,
+  Domain<Dim> const&       dom,
+  MapT const&              map,
+  PAS_global_data_handle&  gdo_handle,
+  PAS_distribution_handle& dist_handle,
+  PAS_pbuf_handle&         pbuf_handle,
+  PAS_buffer**             buffer)
+{
+  PAS_data_spec        data_spec = pas::Pas_datatype<T>::value();
+  unsigned long const  alignment = 0; // indicates PAS default alignment
+  long                 rc;
+
+  long const           no_flag = 0;
+
+  // gdo_dim can either be Dim, the actual dimension of the block,
+  // or VSIP_MAX_DIMENSION.  When gdo_dim is VSIP_MAX_DIMENSION,
+  // dimensions beyound Dim are given size 1.
+  const dimension_type gdo_dim = Dim;
+
+  long                 dim_sizes[gdo_dim];
+  long                 layout[gdo_dim];
+  long                 group_dims[gdo_dim];
+  long                 prod_group_dims = 1;
+  PAS_layout_handle    layout_handle[gdo_dim];
+  PAS_partition_handle partition[gdo_dim];
+  PAS_overlap_handle   zero_overlap;
+
+  pas_overlap_create(
+    PAS_OVERLAP_PAD_ZEROS, 
+    0,				// num_positions
+    0,				// flags: reserved, set to 0
+    &zero_overlap);
+
+  for (dimension_type d=0; d<gdo_dim; ++d)
+  {
+    dimension_type dim_order = (d == 0) ? Dim_of<OrderT, 0>::value :
+                               (d == 1) ? Dim_of<OrderT, 1>::value
+                                        : Dim_of<OrderT, 2>::value;
+    if (d < Dim)
+    {
+      dim_sizes[d]   = static_cast<long>(dom[d].length());
+      layout[d]      = Dim-dim_order-1;
+      group_dims[d]  = map.num_subblocks(d);
+    }
+    else
+    {
+      dim_sizes[d]   = 1;
+      layout[d]      = d;
+      group_dims[d]  = 1;
+    }
+
+    if (d >= Dim || map.distribution(d) == whole)
+    {
+      assert(group_dims[d] == 1);
+      rc = pas_partition_whole_create(
+	0,			// flags: reserved, set to 0
+	&partition[d]);		// returned partition handle
+      VSIP_IMPL_CHECK_RC(rc,"pas_partition_block_create");
+    }
+    else if (map.distribution(d) == block)
+    {
+      rc = pas_partition_block_create(
+	1,			// minimum number of elements in partition
+	1,			// modulo
+	zero_overlap,		// before:
+	zero_overlap,		// after :
+	0,			// flags: reserved, set to 0
+	&partition[d]);		// returned partition handle
+      VSIP_IMPL_CHECK_RC(rc,"pas_partition_block_create");
+
+      // Adjust group_dims if the last block would be size 0.
+      // PAS wants to replicate the first block onto the last
+      // processor in this case.
+      if (dim_sizes[d] < group_dims[d])
+	group_dims[d] = dim_sizes[d];
+      else if (segment_size(dim_sizes[d], group_dims[d], group_dims[d]-1) == 0)
+	group_dims[d] -= 1;
+
+
+      assert(group_dims[d] > 0);
+    }
+    else
+      VSIP_IMPL_THROW(unimplemented("block-cyclic not implemented for PAS"));
+
+    rc = pas_layout_packed_create(
+      layout[d], // number of dimensions more packed than this one
+      0, 0, 0, 0, no_flag,
+      &layout_handle[d]);
+
+    prod_group_dims *= group_dims[d];
+  }
+
+  long real_num_procs;
+  rc = pas_pset_get_npnums(map.impl_ll_pset(), &real_num_procs);
+  assert(rc == CE_SUCCESS);
+
+  // Check that we've dropped the same number of processors
+  // from both the pset and the group dims.
+  assert(real_num_procs == prod_group_dims ||
+	 prod_group_dims == 1 && map.num_subblocks() == 1
+	 && map.num_processors() == static_cast<length_type>(real_num_procs));
+
+  rc = pas_global_data_create(
+    static_cast<long>(gdo_dim),	// number of dimensions
+    dim_sizes,			// array of dimension sizes
+    0,				// flags: reserved, set to 0
+    &gdo_handle);		// returnd GDO handle
+  VSIP_IMPL_CHECK_RC(rc,"pas_global_data_create");
+
+  rc = pas_distribution_create(
+    gdo_handle,			// global data object handle
+    real_num_procs,		// number of processors
+    group_dims,			// array of num of procs per dim
+    partition,			// array of partition spec per dim
+    layout_handle,		// layout spec
+    0,				// buffer_offset
+    PAS_ATOMIC,			// flags
+    &dist_handle);		// returned distribution handle
+  VSIP_IMPL_CHECK_RC(rc,"pas_distribution_create");
+
+  long local_nbytes;
+  rc = pas_distribution_calc_local_nbytes(
+    dist_handle,		// distribution handle
+    data_spec,			// data type spec
+    no_flag,			// flags: reserved, set to 0
+    &local_nbytes);		// returned number of bytes for buffer
+  VSIP_IMPL_CHECK_RC(rc,"pas_distribution_calc_local_nbytes");
+
+  rc = pas_pbuf_create(
+    tag,			// buffer tag
+    map.impl_ll_pset(),		// process set
+    local_nbytes,		// allocation size
+    alignment,			// alignment
+    1,				// max split buffer components
+    PAS_ZERO,			// flags
+    &pbuf_handle);		// returned pbuf handle
+  VSIP_IMPL_CHECK_RC(rc,"pas_pbuf_create");
+
+
+  // Allocate the buffer.  If the local processor is not part of
+  // the pset, don't allocate a buffer.
+  if (pas_pset_is_member(map.impl_ll_pset()))
+  {
+    assert(map.subblock() != no_subblock);
+    rc = pas_buffer_alloc(
+      pbuf_handle,		// pbuf (partitioned buffer) handle
+      map.impl_ll_pset(),	// process set
+      dist_handle,		// distribution handle
+      data_spec,		// data type spec
+      PAS_MY_RANK,		// rank in pset
+      no_flag,			// flags: reserved, set to 0
+      0,			// channel for mapping
+      buffer);			// allocated buffer ptr
+    VSIP_IMPL_CHECK_RC(rc,"pas_buffer_alloc");
+  }
+  else
+    *buffer = NULL;
+
+
+  // Cleanup temporary handles. 
+  rc = pas_overlap_destroy(zero_overlap);
+  VSIP_IMPL_CHECK_RC(rc,"overlap_destroy");
+  for (dimension_type d=0; d<gdo_dim; ++d)
+  {
+    rc = pas_partition_destroy(partition[d]);
+    VSIP_IMPL_CHECK_RC(rc,"partition_destroy");
+    rc = pas_layout_destroy(layout_handle[d]);
+    VSIP_IMPL_CHECK_RC(rc,"layout_destroy");
+  }
+}
+
+extern long             global_tag;
+
+} // namespace vspi::impl::pas
+
+
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+class Pas_block
+  : public impl::Ref_count<Pas_block<Dim, T, OrderT, MapT> >
+{
+  // Compile-time values and types.
+public:
+  static dimension_type const dim = Dim;
+
+  typedef T        value_type;
+  typedef T&       reference_type;
+  typedef T const& const_reference_type;
+
+  typedef OrderT   order_type;
+  typedef MapT     map_type;
+
+  // Non-standard typedefs:
+  typedef Dense<Dim, T, OrderT, Local_map>           local_block_type;
+
+  typedef typename Block_layout<local_block_type>::complex_type
+                                                     impl_complex_type;
+  typedef Storage<impl_complex_type, value_type>     impl_storage_type;
+  typedef typename impl_storage_type::type           impl_data_type;
+  typedef typename impl_storage_type::const_type     impl_const_data_type;
+
+
+  typedef typename Block_layout<local_block_type>::layout_type local_LP;
+  typedef Proxy_local_block<Dim, T, local_LP>        proxy_local_block_type;
+
+  // Private compile-time values and types.
+private:
+  enum private_type {};
+  typedef typename impl::Complex_value_type<value_type, private_type>::type uT;
+
+  void init(Domain<dim> const& dom)
+  {
+    Domain<dim> sb_dom = 
+      (sb_ != no_subblock) ? map_.template impl_subblock_domain<dim>(sb_)
+                           : empty_domain<dim>();
+
+    pas::pbuf_create<T, OrderT>(
+      tag_,
+      dom,
+      map_,
+      gdo_handle_,
+      dist_handle_,
+      pbuf_handle_,
+      &pas_buffer_);
+
+    if (pas_buffer_)
+    {
+      for (dimension_type d=0; d<Dim; ++d)
+      {
+	dimension_type l_d = pas_buffer_->local_part->layout_order[d];
+#if VSIP_IMPL_PAS_BLOCK_VERBOSE
+	std::cout
+	  << "[" << local_processor() << "] - "
+	  << d << " (" << l_d << "):" 
+	  << " ssl=["
+	  << pas_buffer_->local_part->block_dim[l_d].global_start_index << ", "
+	  << pas_buffer_->local_part->block_dim[l_d].stride << ", "
+	  << pas_buffer_->local_part->block_dim[l_d].length << "]"
+	  << "  map:" << sb_dom[d].size()
+	  << "  total:" << dom[d].size()
+	  << "  dim_subblocks:" << map.num_subblocks(d)
+	  << "  addr: " << (ptrdiff_t)pas_buffer_->virt_addr_list[0]
+	  << std::endl;
+#endif
+	// Check that PAS and VSIPL++ agree.
+	assert(pas_buffer_->local_part->block_dim[l_d].length ==
+	       static_cast<int>(sb_dom[d].size()));
+      }
+
+      // Check that PAS allocation is Dense
+      if (Dim == 1)
+      {
+	dimension_type d   = OrderT::impl_dim0;
+	dimension_type l_d = pas_buffer_->local_part->layout_order[d];
+	assert(pas_buffer_->local_part->block_dim[l_d].stride == 1);
+      }
+      if (Dim == 2)
+      {
+	dimension_type d0   = OrderT::impl_dim0;
+	dimension_type d1   = OrderT::impl_dim1;
+	dimension_type l_d0 = pas_buffer_->local_part->layout_order[d0];
+	dimension_type l_d1 = pas_buffer_->local_part->layout_order[d1];
+
+	assert(pas_buffer_->local_part->block_dim[l_d0].stride == 
+	       static_cast<int>(sb_dom[d1].size()));
+	assert(pas_buffer_->local_part->block_dim[l_d1].stride == 1);
+      }
+      if (Dim >= 3)
+      {
+	dimension_type d0   = OrderT::impl_dim0;
+	dimension_type d1   = OrderT::impl_dim1;
+	dimension_type d2   = OrderT::impl_dim2;
+	dimension_type l_d0 = pas_buffer_->local_part->layout_order[d0];
+	dimension_type l_d1 = pas_buffer_->local_part->layout_order[d1];
+	dimension_type l_d2 = pas_buffer_->local_part->layout_order[d2];
+
+	assert(pas_buffer_->local_part->block_dim[l_d0].stride == 
+	       static_cast<int>(sb_dom[d1].size() * sb_dom[d2].size()));
+	assert(pas_buffer_->local_part->block_dim[l_d1].stride == 
+	       static_cast<int>(sb_dom[d2].size()));
+	assert(pas_buffer_->local_part->block_dim[l_d2].stride == 1);
+      }
+
+
+      subblock_ = new local_block_type(sb_dom,
+				       (T*)pas_buffer_->virt_addr_list[0]);
+      subblock_->admit(false);
+    }
+    else
+    {
+#if VSIP_IMPL_PAS_BLOCK_VERBOSE
+      std::cout << "[" << local_processor() << "] no subblock" << std::endl;
+#endif
+      subblock_ = new local_block_type(sb_dom);
+    }
+  }
+
+  // Constructors and destructor.
+public:
+  Pas_block(Domain<dim> const& dom,
+	    MapT const& map = MapT())
+  : map_           (map),
+    proc_          (local_processor()),
+    sb_            (map_.subblock(proc_)),
+    subblock_      (NULL),
+    admitted_      (true),
+    tag_           (pas::global_tag++)
+  {
+    map_.impl_apply(dom);
+    for (dimension_type d=0; d<dim; ++d)
+      size_[d] = dom[d].length();
+
+    this->init(dom);
+  }
+
+  Pas_block(
+    Domain<dim> const& dom,
+    value_type         value,
+    MapT const&        map = MapT())
+  : map_           (map),
+    proc_          (local_processor()),
+    sb_            (map_.subblock(proc_)),
+    subblock_      (NULL),
+    admitted_      (true),
+    tag_           (pas::global_tag++)
+  {
+    map_.impl_apply(dom);
+    for (dimension_type d=0; d<dim; ++d)
+      size_[d] = dom[d].length();
+
+    this->init(dom);
+
+    for (index_type i=0; i<subblock_->size(); ++i)
+      subblock_->put(i, value);
+  }
+
+  Pas_block(
+    Domain<dim> const& dom, 
+    value_type* const  ptr,
+    MapT const&        map = MapT())
+  : map_           (map),
+    proc_          (local_processor()),
+    sb_            (map_.subblock(proc_)),
+    subblock_      (NULL),
+    user_data_  (array_format, ptr),
+    admitted_      (false),
+    tag_           (pas::global_tag++)
+  {
+    map_.impl_apply(dom);
+    for (dimension_type d=0; d<dim; ++d)
+      size_[d] = dom[d].length();
+
+    this->init(dom);
+  }
+
+
+  ~Pas_block()
+  {
+    long rc;
+    
+    rc = pas_global_data_destroy(gdo_handle_);
+    VSIP_IMPL_CHECK_RC(rc,"global_data_destroy");
+    rc = pas_distribution_destroy(dist_handle_);
+    VSIP_IMPL_CHECK_RC(rc,"distribution_destroy");
+    rc = pas_pbuf_destroy(pbuf_handle_, 0);
+    VSIP_IMPL_CHECK_RC(rc,"pbuf_destroy");
+    if (pas_buffer_)
+    {
+      rc = pas_buffer_destroy(pas_buffer_);
+      VSIP_IMPL_CHECK_RC(rc,"buffer_destroy");
+    }
+
+    if (subblock_)
+    {
+      // PROFILE: issue a warning if subblock is captured.
+      subblock_->decrement_count();
+    }
+  }
+    
+  // Data accessors.
+public:
+  // get() on a distributed_block is a broadcast.  The processor
+  // owning the index broadcasts the value to the other processors in
+  // the data parallel group.
+  value_type get(index_type idx) const VSIP_NOTHROW
+  {
+    // Optimize uni-processor and replicated cases.
+    if (    Type_equal<MapT, Global_map<1> >::value
+        ||  vsip::num_processors() == 1
+	|| (   Type_equal<MapT, Replicated_map<1> >::value
+	    && map_.subblock() != no_subblock))
+      return subblock_->get(idx);
+
+    index_type     sb  = map_.impl_subblock_from_global_index(Index<1>(idx));
+    processor_type pr  = *(map_.processor_begin(sb));
+    value_type     val = value_type(); // avoid -Wall 'may not be initialized'
+
+    if (pr == proc_)
+    {
+      assert(map_.subblock() == sb);
+      index_type lidx = map_.impl_local_from_global_index(0, idx);
+      val = subblock_->get(lidx);
+    }
+
+    map_.impl_comm().broadcast(pr, &val, 1);
+
+    return val;
+  }
+
+  value_type get(index_type idx0, index_type idx1) const VSIP_NOTHROW
+  {
+    // Optimize uni-processor and replicated cases.
+    if (    Type_equal<MapT, Global_map<1> >::value
+        ||  vsip::num_processors() == 1
+	|| (   Type_equal<MapT, Replicated_map<1> >::value
+	    && map_.subblock() != no_subblock))
+      return subblock_->get(idx0, idx1);
+
+    index_type     sb = map_.impl_subblock_from_global_index(
+				Index<2>(idx0, idx1));
+    processor_type pr = *(map_.processor_begin(sb));
+    value_type     val = value_type(); // avoid -Wall 'may not be initialized'
+
+    if (pr == proc_)
+    {
+      assert(map_.subblock() == sb);
+      index_type l_idx0 = map_.impl_local_from_global_index(0, idx0);
+      index_type l_idx1 = map_.impl_local_from_global_index(1, idx1);
+      val = subblock_->get(l_idx0, l_idx1);
+    }
+
+    map_.impl_comm().broadcast(pr, &val, 1);
+
+    return val;
+  }
+
+  value_type get(index_type idx0, index_type idx1, index_type idx2)
+    const VSIP_NOTHROW
+  {
+    // Optimize uni-processor and replicated cases.
+    if (    Type_equal<MapT, Global_map<1> >::value
+        ||  vsip::num_processors() == 1
+	|| (   Type_equal<MapT, Replicated_map<1> >::value
+	    && map_.subblock() != no_subblock))
+      return subblock_->get(idx0, idx1, idx2);
+
+    index_type     sb = map_.impl_subblock_from_global_index(
+				Index<3>(idx0, idx1, idx2));
+    processor_type pr = *(map_.processor_begin(sb));
+    value_type     val = value_type(); // avoid -Wall 'may not be initialized'
+
+    if (pr == proc_)
+    {
+      assert(map_.subblock() == sb);
+      index_type l_idx0 = map_.impl_local_from_global_index(0, idx0);
+      index_type l_idx1 = map_.impl_local_from_global_index(1, idx1);
+      index_type l_idx2 = map_.impl_local_from_global_index(2, idx2);
+      val = subblock_->get(l_idx0, l_idx1, l_idx2);
+    }
+
+    map_.impl_comm().broadcast(pr, &val, 1);
+
+    return val;
+  }
+
+
+  // put() on a distributed_block is executed only on the processor
+  // owning the index.
+  void put(index_type idx, value_type val) VSIP_NOTHROW
+  {
+    index_type     sb = map_.impl_subblock_from_global_index(Index<1>(idx));
+
+    if (map_.subblock() == sb)
+    {
+      index_type lidx = map_.impl_local_from_global_index(0, idx);
+      subblock_->put(lidx, val);
+    }
+  }
+
+  void put(index_type idx0, index_type idx1, value_type val) VSIP_NOTHROW
+  {
+    index_type sb = map_.impl_subblock_from_global_index(Index<2>(idx0, idx1));
+
+    if (map_.subblock() == sb)
+    {
+      index_type l_idx0 = map_.impl_local_from_global_index(0, idx0);
+      index_type l_idx1 = map_.impl_local_from_global_index(1, idx1);
+      subblock_->put(l_idx0, l_idx1, val);
+    }
+  }
+
+  void put(index_type idx0, index_type idx1, index_type idx2, value_type val)
+    VSIP_NOTHROW
+  {
+    index_type     sb = map_.impl_subblock_from_global_index(
+				Index<3>(idx0, idx1, idx2));
+
+    if (map_.subblock() == sb)
+    {
+      index_type l_idx0 = map_.impl_local_from_global_index(0, idx0);
+      index_type l_idx1 = map_.impl_local_from_global_index(1, idx1);
+      index_type l_idx2 = map_.impl_local_from_global_index(2, idx2);
+      subblock_->put(l_idx0, l_idx1, l_idx2, val);
+    }
+  }
+
+
+  // Support Direct_data interface.
+public:
+  impl_data_type       impl_data()       VSIP_NOTHROW
+  { return subblock_->impl_data(); }
+
+  impl_const_data_type impl_data() const VSIP_NOTHROW
+  { return subblock_->impl_data(); }
+
+  stride_type impl_stride(dimension_type D, dimension_type d)
+    const VSIP_NOTHROW
+  { return subblock_->impl_stride(D, d); }
+
+
+  // Accessors.
+public:
+  length_type size() const VSIP_NOTHROW;
+  length_type size(dimension_type, dimension_type) const VSIP_NOTHROW;
+  map_type const& map() const VSIP_NOTHROW 
+    { return map_; }
+
+  // length_type num_local_blocks() const { return num_subblocks_; }
+
+  local_block_type& get_local_block() const
+  {
+    assert(subblock_ != NULL);
+    return *subblock_;
+  }
+
+
+  proxy_local_block_type impl_proxy_block(index_type sb) const
+  {
+    return proxy_local_block_type(
+		map_.template impl_subblock_extent<dim>(sb));
+  }
+
+  index_type subblock() const { return sb_; }
+
+  void assert_local(index_type sb) const
+    { assert(sb == sb_ && subblock_ != NULL); }
+
+  // User storage functions.
+public:
+  void admit(bool update = true) VSIP_NOTHROW
+  {
+    if (update && this->user_storage() != no_user_format)
+    {
+      for (index_type i=0; i<subblock_->size(); ++i)
+	subblock_->put(i, user_data_.get(i));
+    }
+    admitted_ = true;
+  }
+
+  void release(bool update = true) VSIP_NOTHROW
+  {
+    if (update && this->user_storage() != no_user_format)
+    {
+      for (index_type i=0; i<subblock_->size(); ++i)
+	user_data_.put(i, subblock_->get(i));
+    }
+    admitted_ = false;
+  }
+
+  void release(bool update, value_type*& pointer) VSIP_NOTHROW
+  {
+    assert(this->user_storage() == no_user_format ||
+	   this->user_storage() == array_format);
+    this->release(update);
+    this->user_data_.find(pointer);
+  }
+
+  void release(bool update, uT*& pointer) VSIP_NOTHROW
+  {
+    assert(this->user_storage() == no_user_format ||
+	   this->user_storage() == interleaved_format);
+    this->release(update);
+    this->user_data_.find(pointer);
+  }
+
+  void release(bool update, uT*& real_pointer, uT*& imag_pointer) VSIP_NOTHROW
+  {
+    assert(this->user_storage() == no_user_format ||
+	   this->user_storage() == split_format);
+    this->release(update);
+    this->user_data_.find(real_pointer, imag_pointer);
+  }
+
+  void find(value_type*& pointer) VSIP_NOTHROW
+  {
+    assert(this->user_storage() == no_user_format ||
+	   this->user_storage() == array_format);
+    this->user_data_.find(pointer);
+  }
+
+  void find(uT*& pointer) VSIP_NOTHROW
+  {
+    assert(this->user_storage() == no_user_format ||
+	   this->user_storage() == interleaved_format);
+    this->user_data_.find(pointer);
+  }
+
+  void find(uT*& real_pointer, uT*& imag_pointer) VSIP_NOTHROW
+  {
+    assert(this->user_storage() == no_user_format ||
+	   this->user_storage() == split_format);
+    this->user_data_.find(real_pointer, imag_pointer);
+  }
+
+  void rebind(value_type* pointer) VSIP_NOTHROW
+  {
+    assert(!this->admitted() && this->user_storage() == array_format);
+    this->user_data_.rebind(pointer);
+  }
+
+  void rebind(uT* pointer) VSIP_NOTHROW
+  {
+    assert(!this->admitted() &&
+	   (this->user_storage() == split_format ||
+	    this->user_storage() == interleaved_format));
+    this->user_data_.rebind(pointer);
+  }
+
+  void rebind(uT* real_pointer, uT* imag_pointer) VSIP_NOTHROW
+  {
+    assert(!this->admitted() &&
+	   (this->user_storage() == split_format ||
+	    this->user_storage() == interleaved_format));
+    this->user_data_.rebind(real_pointer, imag_pointer);
+  }
+
+  enum user_storage_type user_storage() const VSIP_NOTHROW
+    { return this->user_data_.format(); }
+
+  bool admitted() const VSIP_NOTHROW
+    { return admitted_; }
+
+  PAS_distribution_handle impl_ll_dist() VSIP_NOTHROW
+  { return dist_handle_; }
+
+  PAS_pbuf_handle impl_ll_pbuf() VSIP_NOTHROW
+  { return pbuf_handle_; }
+
+  long impl_offset() VSIP_NOTHROW
+  { return 0; }
+
+  // Member data.
+private:
+  map_type                 map_;
+  processor_type	   proc_;		// This processor in comm.
+  index_type   		   sb_;
+  local_block_type*	   subblock_;
+  length_type	           size_[dim];
+  User_storage<T>          user_data_;
+  bool                     admitted_;
+  
+  long                    tag_;
+public:
+  PAS_global_data_handle  gdo_handle_;
+  PAS_distribution_handle dist_handle_;
+private:
+  PAS_pbuf_handle         pbuf_handle_;
+  PAS_buffer*             pas_buffer_;
+};
+
+
+
+/// Specialize block layout trait for Pas_blocks.
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+struct Block_layout<Pas_block<Dim, T, OrderT, MapT> >
+{
+  typedef typename Pas_block<Dim, T, OrderT, MapT>::local_block_type lb_type;
+
+  static dimension_type const dim = Dim;
+
+  typedef typename Block_layout<lb_type>::access_type  access_type;
+  typedef typename Block_layout<lb_type>::order_type   order_type;
+  typedef typename Block_layout<lb_type>::pack_type    pack_type;
+  typedef typename Block_layout<lb_type>::complex_type complex_type;
+
+  typedef Layout<dim, order_type, pack_type, complex_type> layout_type;
+};
+
+
+
+/// Specialize Distributed_local_block traits class for Pas_block.
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+struct Distributed_local_block<Pas_block<Dim, T, OrderT, MapT> >
+{
+  typedef typename Pas_block<Dim, T, OrderT, MapT>::local_block_type type;
+  typedef typename Pas_block<Dim, T, OrderT, MapT>::proxy_local_block_type
+		proxy_type;
+};
+
+
+
+/// Specialize Is_simple_distributed_block traits class for Pas_block.
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+struct Is_simple_distributed_block<Pas_block<Dim, T, OrderT, MapT> >
+{
+  static bool const value = true;
+};
+
+
+
+#if VSIP_IMPL_USE_GENERIC_VISITOR_TEMPLATES==0
+
+/// Specialize Combine_return_type for Pas_block leaves.
+
+template <typename CombineT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+struct Combine_return_type<CombineT, Pas_block<Dim, T, OrderT, MapT> >
+{
+  typedef Pas_block<Dim, T, OrderT, MapT> block_type;
+  typedef typename CombineT::template return_type<block_type>::type
+		type;
+  typedef typename CombineT::template tree_type<block_type>::type
+		tree_type;
+};
+
+
+
+/// Specialize apply_combine for Pas_block leaves.
+
+template <typename CombineT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+typename Combine_return_type<CombineT, Pas_block<Dim, T, OrderT, MapT> >::type
+apply_combine(
+  CombineT const&                        combine,
+  Pas_block<Dim, T, OrderT, MapT> const& block)
+{
+  return combine.apply(block);
+}
+
+#endif
+
+
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+struct Is_pas_block<Pas_block<Dim, T, OrderT, MapT> >
+{
+  static bool const value = true;
+};
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+/// Return the total size of the block.
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+inline length_type
+Pas_block<Dim, T, OrderT, MapT>::size()
+  const VSIP_NOTHROW
+{
+  length_type size = 1;
+  for (dimension_type d=0; d<dim; ++d)
+    size *= size_[d];
+  return size;
+}
+
+
+
+/// Return the size of the block in a specific dimension.
+
+/// Requires:
+///   BLOCK_DIM selects which block-dimensionality
+///      (BLOCK_DIM == Block::dim).
+///   DIM is the dimension whose length to return (0 <= DIM < BLOCK_DIM).
+/// Returns:
+///   The size of dimension DIM.
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+inline
+length_type
+Pas_block<Dim, T, OrderT, MapT>::size(
+  dimension_type block_dim,
+  dimension_type d)
+  const VSIP_NOTHROW
+{
+  assert(block_dim == dim);
+  assert(d < dim);
+  return size_[d];
+}
+
+
+
+/// Return the local block for a given subblock.
+
+#if 0
+// For now, leave this undefined catches unhandled distributed cases at
+// compile-time.
+template <typename BlockT>
+typename Distributed_local_block<BlockT>::type&
+get_local_block(
+  BlockT const& /*block*/)
+{
+  // In general case, we should assume block is not distributed and
+  // just return it.
+  //
+  // For now, through exception to catch unhandled distributed cases.
+  VSIP_IMPL_THROW(impl::unimplemented("get_local_block()"));
+}
+#endif
+
+
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+typename Pas_block<Dim, T, OrderT, MapT>::local_block_type&
+get_local_block(
+  Pas_block<Dim, T, OrderT, MapT> const& block)
+{
+  return block.get_local_block();
+}
+
+
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+typename Pas_block<Dim, T, OrderT, MapT>::proxy_local_block_type
+get_local_proxy(
+  Pas_block<Dim, T, OrderT, MapT> const& block,
+  index_type                             sb)
+{
+  return block.impl_proxy_block(sb);
+}
+
+
+
+#if 0
+// For now, leave this undefined catches unhandled distributed cases at
+// compile-time.
+template <typename BlockT>
+void
+assert_local(
+  BlockT const& /*block*/,
+  index_type    sb)
+{
+  // In general case, we should assume block is not distributed and
+  // just return it.
+  //
+  // For now, through exception to catch unhandled distributed cases.
+  VSIP_IMPL_THROW(impl::unimplemented("assert_local()"));
+}
+#endif
+
+
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+void
+assert_local(
+  Pas_block<Dim, T, OrderT, MapT> const& block,
+  index_type                             sb)
+{
+  block.assert_local(sb);
+}
+
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#undef VSIP_IMPL_PAS_BLOCK_VERBOSE
+
+#endif // VSIP_IMPL_PAS_BLOCK_HPP
Index: src/vsip/impl/pas/util.hpp
===================================================================
--- src/vsip/impl/pas/util.hpp	(revision 0)
+++ src/vsip/impl/pas/util.hpp	(revision 0)
@@ -0,0 +1,62 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/pas/util.hpp
+    @author  Jules Bergmann
+    @date    2006-08-29
+    @brief   VSIPL++ Library: Parallel Services: PAS utilities
+*/
+
+#ifndef VSIP_IMPL_PAS_UTIL_HPP
+#define VSIP_IMPL_PAS_UTIL_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/pas/param.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+namespace pas
+{
+
+inline void
+semaphore_give(PAS_id pset, long index)
+{
+  long rc;
+#if VSIP_IMPL_PAS_USE_INTERRUPT()
+  rc = pas_semaphore_give_interrupt(pset, index, VSIP_IMPL_PAS_XFER_ENGINE); 
+#else
+  rc = pas_semaphore_give(pset, index, VSIP_IMPL_PAS_XFER_ENGINE); 
+#endif
+  assert(rc == CE_SUCCESS);
+}
+
+
+
+inline void
+semaphore_take(PAS_id pset, long index)
+{
+  long rc;
+#if VSIP_IMPL_PAS_USE_INTERRUPT()
+  rc = pas_semaphore_take_interrupt(pset, index, VSIP_IMPL_PAS_XFER_ENGINE); 
+#else
+  rc = pas_semaphore_take(pset, index, VSIP_IMPL_PAS_XFER_ENGINE); 
+#endif
+  assert(rc == CE_SUCCESS);
+}
+
+} // namespace vsip::impl::pas
+} // namespace vsip::impl
+} // namespace vsip
+#endif // VSIP_IMPL_PAS_UTIL_HPP
Index: src/vsip/impl/pas/param.hpp
===================================================================
--- src/vsip/impl/pas/param.hpp	(revision 0)
+++ src/vsip/impl/pas/param.hpp	(revision 0)
@@ -0,0 +1,46 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/pas/param.hpp
+    @author  Jules Bergmann
+    @date    2006-08-09
+    @brief   VSIPL++ Library: Parallel Services: PAS parameters
+
+*/
+
+#ifndef VSIP_IMPL_PAS_PARAM_HPP
+#define VSIP_IMPL_PAS_PARAM_HPP
+
+/***********************************************************************
+  Macros
+***********************************************************************/
+
+// Set VSIP_IMPL_PAS_XR to 1 when using PAS for Linux
+#define VSIP_IMPL_PAS_XR                        1
+#define VSIP_IMPL_PAS_XR_SET_PORTNUM            0
+#define VSIP_IMPL_PAS_XR_SET_ADAPTERNAME        1
+#define VSIP_IMPL_PAS_XR_SET_SHMKEY             1
+#define VSIP_IMPL_PAS_XR_SET_PIR                0
+#define VSIP_IMPL_PAS_XR_SET_RMD                0
+#define VSIP_IMPL_PAS_XR_SET_UDAPL_MAX_RECVS    0
+#define VSIP_IMPL_PAS_XR_SET_UDAPL_MAX_REQUESTS 0
+
+#define VSIP_IMPL_PAS_USE_INTERRUPT() 1
+#define VSIP_IMPL_PAS_XFER_ENGINE PAS_DMA
+#define VSIP_IMPL_PAS_XR_ADAPTERNAME "ib0" /* Commonly used with Mercury XR9 */
+#define VSIP_IMPL_PAS_XR_SHMKEY 1918
+
+#if VSIP_IMPL_PAS_USE_INTERRUPT()
+#  define VSIP_IMPL_PAS_SEM_GIVE_AFTER PAS_SEM_GIVE_INTERRUPT_AFTER
+#else
+#  define VSIP_IMPL_PAS_SEM_GIVE_AFTER PAS_SEM_GIVE_AFTER
+#endif
+
+#define VSIP_IMPL_CHECK_RC(rc, where)                                    \
+ if (rc !=  CE_SUCCESS) {                                      \
+     err_print(rc, ERR_GET_ALL);                               \
+     printf("CE%ld %s L%d\n", ce_getid(), where, __LINE__);    \
+     exit(1); }
+
+
+
+#endif // VSIP_IMPL_PAS_PARAM_HPP
Index: src/vsip/impl/pas/par_assign_direct.hpp
===================================================================
--- src/vsip/impl/pas/par_assign_direct.hpp	(revision 0)
+++ src/vsip/impl/pas/par_assign_direct.hpp	(revision 0)
@@ -0,0 +1,794 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/par_assign_direct_pas.hpp
+    @author  Jules Bergmann
+    @date    2005-08-21
+    @brief   VSIPL++ Library: Direct PAS parallel assignment algorithm.
+
+*/
+
+#ifndef VSIP_IMPL_PAR_ASSIGN_DIRECT_PAS_HPP
+#define VSIP_IMPL_PAR_ASSIGN_DIRECT_PAS_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vector>
+#include <algorithm>
+
+#include <vsip/support.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/impl/par-services.hpp>
+#include <vsip/impl/profile.hpp>
+#include <vsip/impl/par_assign.hpp>
+#include <vsip/impl/par_assign_common.hpp>
+
+#define VSIP_IMPL_PCA_VERBOSE 0
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
+namespace par_chain_assign
+{
+
+template <typename OrderT,
+	  typename MsgRecord,
+	  typename SrcExtDataT,
+	  typename DstExtDataT>
+inline void
+msg_add(
+  std::vector<MsgRecord>& list,
+  SrcExtDataT&            src_ext,
+  DstExtDataT&            dst_ext,
+  processor_type          proc,
+  Domain<1> const&        src_dom,
+  Domain<1> const&        dst_dom,
+  Domain<1> const&        intr,
+  long                    src_pbuf_offset,
+  long                    dst_pbuf_offset)
+{
+  dimension_type const dim  = 1;
+  dimension_type const dim0 = OrderT::impl_dim0;
+  assert(dim0 == 0);
+
+  stride_type src_stride = src_ext.stride(dim0);
+  stride_type dst_stride = dst_ext.stride(dim0);
+
+  Index<dim>  src_offset = first(intr) - first(src_dom);
+  Index<dim>  dst_offset = first(intr) - first(dst_dom);
+
+  index_type real_src_offset = src_offset[0] * src_stride + src_pbuf_offset;
+  index_type real_dst_offset = dst_offset[0] * dst_stride + dst_pbuf_offset;
+
+  length_type size = intr.length();
+
+  if (intr.stride() == 1 && src_stride == 1 && dst_stride == 1)
+  {
+    list.push_back(MsgRecord(proc, 
+			      real_src_offset,
+			      real_dst_offset,
+			      size));
+  }
+  else
+  {
+    for (index_type i=0; i<size; ++i)
+    {
+      list.push_back(MsgRecord(proc, 
+				real_src_offset + i*src_stride*intr.stride(),
+				real_dst_offset + i*dst_stride*intr.stride(),
+				1));
+    }
+  }
+}
+
+
+template <typename OrderT,
+	  typename MsgRecord,
+	  typename SrcExtDataT,
+	  typename DstExtDataT>
+inline void
+msg_add(
+  std::vector<MsgRecord>& list,
+  SrcExtDataT&            src_ext,
+  DstExtDataT&            dst_ext,
+  processor_type          proc,
+  Domain<2> const&        src_dom,
+  Domain<2> const&        dst_dom,
+  Domain<2> const&        intr,
+  long                    src_pbuf_offset,
+  long                    dst_pbuf_offset)
+{
+  dimension_type const dim = 2;
+
+  dimension_type const dim0 = OrderT::impl_dim0;
+  dimension_type const dim1 = OrderT::impl_dim1;
+
+  Index<dim>  src_offset = first(intr) - first(src_dom);
+  Index<dim>  dst_offset = first(intr) - first(dst_dom);
+
+  index_type real_src_offset = src_offset[dim0] * src_ext.stride(dim0) 
+                             + src_offset[dim1] * src_ext.stride(dim1)
+                             + src_pbuf_offset;
+  index_type real_dst_offset = dst_offset[dim0] * dst_ext.stride(dim0) 
+                             + dst_offset[dim1] * dst_ext.stride(dim1)
+                             + dst_pbuf_offset;
+
+  length_type size = intr[dim1].length();
+
+  for (index_type i=0; i<intr[dim0].size(); ++i)
+  {
+    if (intr[dim1].stride() == 1 && src_ext.stride(dim1) == 1 &&
+	dst_ext.stride(dim1) == 1)
+    {
+      list.push_back(MsgRecord(proc, 
+			       real_src_offset,
+			       real_dst_offset,
+			       size));
+    }
+    else
+    {
+      for (index_type j=0; j<size; ++j)
+      {
+	list.push_back(MsgRecord(proc, 
+		real_src_offset + j*src_ext.stride(dim1)*intr[dim1].stride(),
+		real_dst_offset + j*dst_ext.stride(dim1)*intr[dim1].stride(),
+		1));
+      }
+    }
+    
+    real_src_offset += intr[dim0].stride() * src_ext.stride(dim0);
+    real_dst_offset += intr[dim0].stride() * dst_ext.stride(dim0);
+  }
+}
+
+
+
+template <typename OrderT,
+	  typename MsgRecord,
+	  typename SrcExtDataT,
+	  typename DstExtDataT>
+inline void
+msg_add(
+  std::vector<MsgRecord>& list,
+  SrcExtDataT&            src_ext,
+  DstExtDataT&            dst_ext,
+  processor_type          proc,
+  Domain<3> const&        src_dom,
+  Domain<3> const&        dst_dom,
+  Domain<3> const&        intr,
+  long                    src_pbuf_offset,
+  long                    dst_pbuf_offset)
+{
+  dimension_type const dim = 3;
+
+  dimension_type const dim0 = OrderT::impl_dim0;
+  dimension_type const dim1 = OrderT::impl_dim1;
+  dimension_type const dim2 = OrderT::impl_dim2;
+
+  Index<dim>  src_offset = first(intr) - first(src_dom);
+  Index<dim>  dst_offset = first(intr) - first(dst_dom);
+
+  index_type real_src_offset = src_offset[dim0] * src_ext.stride(dim0) 
+                             + src_offset[dim1] * src_ext.stride(dim1)
+                             + src_offset[dim2] * src_ext.stride(dim2)
+                             + src_pbuf_offset;
+  index_type real_dst_offset = dst_offset[dim0] * dst_ext.stride(dim0) 
+                             + dst_offset[dim1] * dst_ext.stride(dim1)
+                             + dst_offset[dim2] * dst_ext.stride(dim2)
+                             + dst_pbuf_offset;
+
+  length_type size = intr[dim2].length();
+
+  for (index_type i=0; i<intr[dim0].size(); ++i)
+  {
+    index_type real_src_offset_1 = real_src_offset;
+    index_type real_dst_offset_1 = real_dst_offset;
+
+    for (index_type j=0; j<intr[dim1].size(); ++j)
+    {
+      if (intr[dim2].stride() == 1 && src_ext.stride(dim2) == 1 &&
+	  dst_ext.stride(dim2) == 1)
+      {
+	list.push_back(MsgRecord(proc, 
+				 real_src_offset_1,
+				 real_dst_offset_1,
+				 size));
+      }
+      else
+      {
+	for (index_type k=0; k<size; ++k)
+	{
+	  list.push_back(MsgRecord(proc, 
+		real_src_offset_1 + k*src_ext.stride(dim2)*intr[dim2].stride(),
+		real_dst_offset_1 + k*dst_ext.stride(dim2)*intr[dim2].stride(),
+		1));
+	}
+      }
+    
+      real_src_offset_1 += intr[dim1].stride() * src_ext.stride(dim1);
+      real_dst_offset_1 += intr[dim1].stride() * dst_ext.stride(dim1);
+    }
+    real_src_offset += intr[dim0].stride() * src_ext.stride(dim0);
+    real_dst_offset += intr[dim0].stride() * dst_ext.stride(dim0);
+  }
+}
+
+} // namespace par_chain_assign
+
+
+// Chained parallel assignment.
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+class Par_assign<Dim, T1, T2, Block1, Block2, Direct_pas_assign>
+  : Compile_time_assert<Is_split_block<Block1>::value ==
+                        Is_split_block<Block2>::value>
+{
+  static dimension_type const dim = Dim;
+
+  static long const ready_sem_index_ = 0;
+  static long const done_sem_index_  = 0;
+
+  // disable_copy should only be set to true for testing purposes.  It
+  // disables direct copy of data when source and destination are on
+  // the same processor, causing chains to be built on both sides.
+  // This is helps cover chain-to-chain copies for par-services-none.
+  static bool const disable_copy = false;
+
+  typedef typename Distributed_local_block<Block1>::type dst_local_block;
+  typedef typename Distributed_local_block<Block2>::type src_local_block;
+
+  typedef typename View_of_dim<dim, T1, dst_local_block>::type
+		dst_lview_type;
+
+  typedef typename View_of_dim<dim, T2, src_local_block>::const_type
+		src_lview_type;
+
+  typedef impl::Persistent_ext_data<src_local_block> src_ext_type;
+  typedef impl::Persistent_ext_data<dst_local_block> dst_ext_type;
+
+  typedef typename Block1::map_type dst_appmap_t;
+  typedef typename Block2::map_type src_appmap_t;
+
+  typedef typename Block_layout<Block1>::order_type dst_order_t;
+
+  typedef impl::Communicator::request_type request_type;
+  typedef impl::Communicator::chain_type   chain_type;
+
+  /// A Msg_record holds a piece of a data transfer that together
+  /// describe a complete communication.
+  ///
+  /// Members:
+  ///   PROC_ is the remote processor (to send to or receive from),
+  ///   SUBBLOCK_ is the local subblock to,
+  ///   DATA_ is the raw data pointer of the local subblock,
+  ///   CHAIN_ is the DMA chain representing the data from subblock_
+  ///      to send.
+  ///
+  /// Notes:
+  ///   [1] CHAIN_ completely describes the data to send/receive,
+  ///       but it is dependent on the distributed blocks storage
+  ///       location remaining unchanged from when the list is built
+  ///       to when it is executed.  SUBBLOCK_ and DATA_ are stored
+  ///       to check consistentcy and potentially update CHAIN_ if
+  ///       the storage location changes.
+
+  struct Msg_record
+  {
+    Msg_record(processor_type proc, index_type src_offset,
+	       index_type dst_offset, length_type size)
+      : proc_       (proc),
+        src_offset_ (src_offset),
+        dst_offset_ (dst_offset),
+        size_       (size)
+      {}
+
+  public:
+    processor_type proc_;    // destination processor
+    index_type     src_offset_;
+    index_type     dst_offset_;
+    length_type    size_;
+
+    // index_type     subblock_;
+    // chain_type     chain_;
+  };
+
+
+
+  /// A Copy_record holds part of a data transfer where the source
+  /// and destination processors are the same.
+  ///
+  /// Members:
+  ///   SRC_SB_ is the source local subblock,
+  ///   DST_SB_ is the destination local subblock,
+  ///   SRC_DOM_ is the local domain within the source subblock to transfer,
+  ///   DST_DOM_ is the local domain within the destination subblock to
+  ///      transfer.
+
+  struct Copy_record
+  {
+    Copy_record(index_type src_sb, index_type dst_sb,
+	       Domain<Dim> src_dom,
+	       Domain<Dim> dst_dom)
+      : src_sb_  (src_sb),
+        dst_sb_  (dst_sb),
+	src_dom_ (src_dom),
+	dst_dom_ (dst_dom)
+      {}
+
+  public:
+    index_type     src_sb_;    // destination processor
+    index_type     dst_sb_;
+    Domain<Dim>    src_dom_;
+    Domain<Dim>    dst_dom_;
+  };
+
+
+  // Constructor.
+public:
+  Par_assign(
+    typename View_of_dim<Dim, T1, Block1>::type       dst,
+    typename View_of_dim<Dim, T2, Block2>::const_type src)
+    : dst_      (dst),
+      src_      (src.block()),
+      dst_am_   (dst_.block().map()),
+      src_am_   (src_.block().map()),
+      comm_     (dst_am_.impl_comm()),
+      send_list (),
+      recv_list (),
+      copy_list (),
+      req_list  (),
+      msg_count (0),
+      src_ext_  (src_.local().block(), impl::SYNC_IN),
+      dst_ext_  (dst_.local().block(), impl::SYNC_OUT)
+  {
+    impl::profile::Scope_event ev("Par_assign<Direct_pas_assign>-cons");
+    assert(src_am_.impl_comm() == dst_am_.impl_comm());
+
+    build_send_list();
+    if (!disable_copy)
+      build_copy_list();
+    build_recv_list();
+  }
+
+  ~Par_assign()
+  {
+    // At destruction, the list of outstanding sends should be empty.
+    // This would be non-empty if:
+    //  - Par_assign did not to clear the lists after
+    //    processing it (library design error), or
+    //  - User executed send() without a corresponding wait().
+    assert(req_list.size() == 0);
+  }
+
+
+  // Implementation functions.
+private:
+
+  void build_send_list();
+  void build_recv_list();
+  void build_copy_list();
+
+  void exec_send_list();
+  void exec_recv_list();
+  void exec_copy_list();
+
+  void wait_send_list();
+
+  void cleanup() {}	// Cleanup send_list buffers.
+
+
+  // Invoke the parallel assignment
+public:
+  void operator()()
+  {
+    PAS_id src_pset = src_.block().map().impl_ll_pset();
+    PAS_id dst_pset = dst_.block().map().impl_ll_pset();
+
+    if (pas_pset_is_member(dst_pset))
+      pas::semaphore_give(src_pset, 0);
+
+    if (pas_pset_is_member(src_pset))
+    {
+      pas::semaphore_take(dst_pset, 0);
+      exec_send_list();
+    }
+
+    if (copy_list.size() > 0) exec_copy_list();
+    exec_recv_list();
+
+    if (req_list.size() > 0)  wait_send_list();
+
+    cleanup();
+
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+    std::cout << "[" << local_processor() << "] assignment -- DONE\n"
+	      << std::flush;
+#endif
+  }
+
+
+  // Private member data.
+private:
+  typename View_of_dim<Dim, T1, Block1>::type       dst_;
+  typename View_of_dim<Dim, T2, Block2>::const_type src_;
+
+  dst_appmap_t const& dst_am_;
+  src_appmap_t const& src_am_;
+  impl::Communicator& comm_;
+
+  std::vector<Msg_record>    send_list;
+  std::vector<Msg_record>    recv_list;
+  std::vector<Copy_record>   copy_list;
+
+  std::vector<request_type> req_list;
+
+  int                       msg_count;
+
+  src_ext_type              src_ext_;
+  dst_ext_type              dst_ext_;
+};
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Build the send_list, a list of processor-subblock-local_domain
+// records.  This can be done in advance of the actual assignment.
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Direct_pas_assign>::build_send_list()
+{
+  profile::Scope_event ev("Par_assign<Direct_pas_assign>-build_send_list");
+  processor_type rank = local_processor();
+
+  length_type dsize  = dst_am_.impl_working_size();
+  // std::min(dst_am_.num_subblocks(), dst_am_.impl_pvec().size());
+
+  long src_pbuf_offset = src_.local().block().impl_offset();
+
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+    std::cout << "[" << rank << "] "
+	      << "build_send_list(dsize: " << dsize
+	      << ") -------------------------------------\n"
+	      << std::flush;
+#endif
+
+  index_type src_sb = src_am_.subblock(rank);
+
+  // If multiple processors have the subblock, the first processor
+  // is responsible for sending it.
+
+  if (src_sb != no_subblock &&
+      *(src_am_.processor_begin(src_sb)) == rank)
+  {
+    // Iterate over all processors
+    for (index_type pi=0; pi<dsize; ++pi)
+    {
+      processor_type proc = dst_am_.impl_proc_from_rank(pi);
+
+      // Transfers that stay on this processor are handled by the copy_list.
+      if (!disable_copy && proc == rank)
+	continue;
+
+      index_type dst_sb = dst_am_.subblock(proc);
+
+      if (dst_sb != no_subblock)
+      {
+	// Check to see if destination processor already has block
+	if (!disable_copy && processor_has_block(src_am_, proc, src_sb))
+	  continue;
+
+	src_ext_.begin();
+
+	
+	typedef typename Distributed_local_block<Block1>::proxy_type
+	  proxy_local_block_type;
+
+	proxy_local_block_type proxy = get_local_proxy(dst_.block(), dst_sb);
+	Ext_data<proxy_local_block_type> proxy_ext(proxy);
+	long dst_pbuf_offset = proxy.impl_offset();
+
+	for (index_type dp=0; dp<num_patches(dst_, dst_sb); ++dp)
+	{
+	  Domain<dim> dst_dom = global_domain(dst_, dst_sb, dp);
+
+	  for (index_type sp=0; sp<num_patches(src_, src_sb); ++sp)
+	  {
+	    Domain<dim> src_dom  = global_domain(src_, src_sb, sp);
+	    Domain<dim> src_ldom = local_domain(src_, src_sb, sp);
+
+	    Domain<dim> intr;
+
+	    if (intersect(src_dom, dst_dom, intr))
+	    {
+	      par_chain_assign::msg_add<dst_order_t, Msg_record>(
+		send_list,
+		src_ext_,
+		proxy_ext,
+		proc,
+		src_dom, dst_dom, intr,
+		src_pbuf_offset,
+		dst_pbuf_offset);
+
+#if VSIP_IMPL_PCA_VERBOSE >= 2
+	      std::cout << "(" << rank << ") send "
+			<< rank << "/" << src_sb << "/" << sp
+			<< " -> "
+			<< proc << "/" << dst_sb << "/" << dp
+			<< " src: " << src_dom
+			<< " dst: " << dst_dom
+			<< " intr: " << intr
+			<< std::endl
+			<< std::flush;
+#endif
+	    }
+	  }
+	}
+	src_ext_.end();
+      }
+    }
+  }
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+    std::cout << "(" << rank << ") "
+	      << "build_send_list DONE "
+	      << " -------------------------------------\n"
+	      << std::flush;
+#endif
+}
+
+
+
+// Build the recv_list, a list of processor-subblock-local_domain
+// records.  This can be done in advance of the actual assignment.
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Direct_pas_assign>::build_recv_list()
+{
+  profile::Scope_event ev("Par_assign<Direct_pas_assign>-build_recv_list");
+}
+
+
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Direct_pas_assign>::build_copy_list()
+{
+  profile::Scope_event ev("Par_assign<Direct_pas_assign>-build_copy_list");
+  processor_type rank = local_processor();
+
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+  std::cout << "(" << rank << ") "
+	    << "build_copy_list(num_procs: " << src_am_.num_processors()
+	    << ") -------------------------------------\n"
+	    << std::flush;
+#endif
+
+  index_type dst_sb = dst_am_.subblock(rank);
+  if (dst_sb != no_subblock)
+  {
+
+    index_type src_sb = src_am_.subblock(rank);
+    if (src_sb != no_subblock)
+    {
+      for (index_type dp=0; dp<num_patches(dst_, dst_sb); ++dp)
+      {
+	Domain<dim> dst_dom  = global_domain(dst_, dst_sb, dp);
+	Domain<dim> dst_ldom = local_domain (dst_, dst_sb, dp);
+
+	for (index_type sp=0; sp<num_patches(src_, src_sb); ++sp)
+	{
+	  Domain<dim> src_dom  = global_domain(src_, src_sb, sp);
+	  Domain<dim> src_ldom = local_domain (src_, src_sb, sp);
+
+	  Domain<dim> intr;
+
+#if VSIP_IMPL_PCA_VERBOSE >= 2
+//	  std::cout << " - dst " << dst_sb << "/" << dp << std::endl
+//		    << "   src " << src_sb     << "/" << sp << std::endl
+//	    ;
+#endif
+
+	  if (intersect(src_dom, dst_dom, intr))
+	  {
+	    Index<dim>  send_offset = first(intr) - first(src_dom);
+	    Domain<dim> send_dom    = domain(first(src_ldom) + send_offset,
+					     extent(intr));
+	    Index<dim>  recv_offset = first(intr) - first(dst_dom);
+	    Domain<dim> recv_dom    = domain(first(dst_ldom) + recv_offset,
+					     extent(intr));
+
+	    copy_list.push_back(Copy_record(src_sb, dst_sb,
+					    send_dom, recv_dom));
+
+#if VSIP_IMPL_PCA_VERBOSE >= 2
+	    std::cout << "(" << rank << ")"
+		      << "copy src: " << src_sb << "/" << sp
+		      << " " << send_dom
+		      << "  dst: " << dst_sb << "/" << dp
+		      << " " << recv_dom
+		      << std::endl
+		      << std::flush;
+#endif
+	  }
+	}
+      }
+    }
+  }
+}
+
+
+
+// Execute the send_list.
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Direct_pas_assign>::exec_send_list()
+{
+  profile::Scope_event ev("Par_assign<Direct_pas_assign>-exec_send_list");
+
+  PAS_id src_pnum          = local_processor();
+  PAS_pbuf_handle src_pbuf = src_.block().impl_ll_pbuf();
+  PAS_pbuf_handle dst_pbuf = dst_.block().impl_ll_pbuf();
+  PAS_id dst_pset = dst_.block().map().impl_ll_pset();
+  long pull_flags = PAS_WAIT;
+  long rc;
+
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+  std::cout << "(" << local_processor() << ") "
+	    << "exec_send_list(size: " << send_list.size()
+	    << ") -------------------------------------\n"
+	    << std::flush;
+#endif
+  typedef typename std::vector<Msg_record>::iterator sl_iterator;
+
+  sl_iterator msg    = send_list.begin();
+  sl_iterator sl_end = send_list.end();
+  if (msg != sl_end)
+  {
+    for (; msg != sl_end; ++msg)
+    {
+      rc = pas_move_nbytes(
+	src_pnum,
+	src_pbuf,
+	sizeof(T1)*(*msg).src_offset_,
+	(*msg).proc_,		// dst_pnum
+	dst_pbuf,
+	sizeof(T1)*(*msg).dst_offset_,
+	sizeof(T1)*(*msg).size_,
+	0,
+	pull_flags | PAS_PUSH | VSIP_IMPL_PAS_XFER_ENGINE,
+	NULL);
+      assert(rc == CE_SUCCESS);
+    }
+  }
+  pas::semaphore_give(dst_pset, ready_sem_index_);
+}
+
+
+
+// Execute the recv_list.
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Direct_pas_assign>::exec_recv_list()
+{
+  profile::Scope_event ev("Par_assign<Direct_pas_assign>-exec_recv_list");
+  PAS_id dst_pset = dst_.block().map().impl_ll_pset();
+  PAS_id src_pset = src_.block().map().impl_ll_pset();
+
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+  processor_type rank = local_processor();
+  std::cout << "(" << rank << ") "
+	    << "exec_recv_list(size: " << recv_list.size()
+	    << ") -------------------------------------\n"
+	    << std::flush;
+#endif
+
+  if (pas_pset_is_member(dst_pset))
+    pas::semaphore_take(src_pset, ready_sem_index_);
+}
+
+
+
+// Execute the copy_list.
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Direct_pas_assign>::exec_copy_list()
+{
+  profile::Scope_event ev("Par_assign<Direct_pas_assign>-exec_copy_list");
+
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+  processor_type rank = local_processor();
+  std::cout << "(" << rank << ") "
+	    << "exec_copy_list(size: " << copy_list.size()
+	    << ") -------------------------------------\n"
+	    << std::flush;
+#endif
+
+  src_lview_type src_lview = get_local_view(src_);
+  dst_lview_type dst_lview = get_local_view(dst_);
+
+  typedef typename std::vector<Copy_record>::iterator cl_iterator;
+  for (cl_iterator cl_cur = copy_list.begin();
+       cl_cur != copy_list.end();
+       ++cl_cur)
+  {
+    view_assert_local(src_, (*cl_cur).src_sb_);
+    view_assert_local(dst_, (*cl_cur).dst_sb_);
+
+    dst_lview((*cl_cur).dst_dom_) = src_lview((*cl_cur).src_dom_);
+#if VSIP_IMPL_PCA_VERBOSE >= 2
+    std::cout << "(" << rank << ") "
+	      << "src subblock: " << (*cl_cur).src_sb_ << " -> "
+	      << "dst subblock: " << (*cl_cur).dst_sb_ << std::endl
+	      << dst_lview((*cl_cur).dst_dom_)
+	      << std::flush;
+#endif
+  }
+}
+
+
+
+// Wait for the send_list instructions to be completed.
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Direct_pas_assign>::wait_send_list()
+{
+}
+
+
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#undef VSIP_IMPL_PCA_VERBOSE
+
+#endif // VSIP_IMPL_PAR_ASSIGN_DIRECT_PAS_HPP
Index: src/vsip/impl/pas/broadcast.hpp
===================================================================
--- src/vsip/impl/pas/broadcast.hpp	(revision 0)
+++ src/vsip/impl/pas/broadcast.hpp	(revision 0)
@@ -0,0 +1,175 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/pas_broadcast.hpp
+    @author  Jules Bergmann
+    @date    2005-08-23
+    @brief   VSIPL++ Library: PAS Broadcast.
+
+*/
+
+#ifndef VSIP_IMPL_PAS_BROADCAST_HPP
+#define VSIP_IMPL_PAS_BROADCAST_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+extern "C" {
+#include <pas.h>
+}
+
+#include <vsip/support.hpp>
+#include <vsip/impl/pas/param.hpp>
+#include <vsip/impl/pas/util.hpp>
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
+namespace pas
+{
+
+// Forward Definition.
+template <typename T>
+struct Pas_datatype;
+
+
+
+extern long             global_tag;
+
+struct Broadcast
+{
+  typedef unsigned int data_type;
+  static long          const num_elems = 4;
+
+  Broadcast(PAS_id pset);
+  ~Broadcast();
+
+  template <typename T>
+  void operator()(processor_type proc, T& value);
+
+  long                    tag_;
+  PAS_id                  pset_;
+  PAS_data_spec           data_spec_;
+
+  PAS_distribution_handle local_dist_;
+  PAS_pbuf_handle         local_pbuf_;
+  PAS_buffer*             local_buffer_;
+
+  PAS_distribution_handle global_dist_;
+  PAS_pbuf_handle         global_pbuf_;
+  PAS_buffer*             global_buffer_;
+};
+
+inline
+Broadcast::Broadcast(PAS_id pset)
+  : pset_      (pset),
+    data_spec_ (PAS_DATA_REAL_U32)
+{
+  long rc;
+
+  tag_ = global_tag;
+  global_tag += 2;
+
+  // Create local buffer
+  rc = pas_pbuf_create_1D(
+      tag_,			// tag
+      local_processor(),	// procs
+      num_elems,		// num_elems
+      PAS_WHOLE,		// vector_flag
+      1,			// modulo
+      0,			// overlap
+      data_spec_,		// data_spec
+      0,			// alignment
+      PAS_ATOMIC,		// atomic/split flag
+      0,			// memory clearing flag
+      &local_dist_,		// dist handle
+      &local_pbuf_,		// pbuf handle
+      &local_buffer_);		// PAS buffer
+  VSIP_IMPL_CHECK_RC(rc,"pas_pbuf_create_1D");
+
+  // Create replicated buffer
+  rc = pas_pbuf_create_1D(
+      tag_+1,			// tag
+      pset_,			// procs
+      num_elems,		// num_elems
+      PAS_WHOLE,		// vector_flag
+      1,			// modulo
+      0,			// overlap
+      data_spec_,		// data_spec
+      0,			// alignment
+      PAS_ATOMIC,		// atomic/split flag
+      0,			// memory clearing flag
+      &global_dist_,		// dist handle
+      &global_pbuf_,		// pbuf handle
+      &global_buffer_);		// PAS buffer
+
+  VSIP_IMPL_CHECK_RC(rc,"pas_pbuf_create_1D");
+}
+
+
+
+inline
+Broadcast::~Broadcast()
+{
+  long rc;
+
+  rc = pas_distribution_destroy(local_dist_);  assert(rc == CE_SUCCESS);
+  rc = pas_pbuf_destroy(local_pbuf_, 0);       assert(rc == CE_SUCCESS);
+  rc = pas_buffer_destroy(local_buffer_);      assert(rc == CE_SUCCESS);
+  rc = pas_distribution_destroy(global_dist_); assert(rc == CE_SUCCESS);
+  rc = pas_pbuf_destroy(global_pbuf_, 0);      assert(rc == CE_SUCCESS);
+  rc = pas_buffer_destroy(global_buffer_);     assert(rc == CE_SUCCESS);
+}
+
+
+
+template <typename T>
+inline
+void
+Broadcast::operator()(
+  processor_type proc,
+  T&             value)
+{
+  long rc;
+  long sem_index = 0;
+  long pull_flags = 0;
+
+  assert(sizeof(T) < num_elems*sizeof(data_type));
+
+  pas::semaphore_give(proc, sem_index);
+
+  if (local_processor() == proc)
+  {
+    *((T*)local_buffer_->virt_addr_list[0]) = value;
+
+    pas::semaphore_take(pset_, sem_index);
+    rc = pas_push(NULL, NULL,
+		  local_pbuf_,
+		  local_dist_,
+		  global_pbuf_,
+		  global_dist_,
+		  data_spec_,
+		  sem_index,
+		  pull_flags | VSIP_IMPL_PAS_XFER_ENGINE |
+		  VSIP_IMPL_PAS_SEM_GIVE_AFTER,
+		  NULL); 
+    assert(rc == CE_SUCCESS);
+  }
+  pas::semaphore_take(proc, sem_index);
+  fflush(stdout);
+
+  value = *((T*)global_buffer_->virt_addr_list[0]);
+}
+
+} // namespace vsip::impl::pas
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_PAS_BROADCAST_HPP
Index: src/vsip/impl/pas/services.hpp
===================================================================
--- src/vsip/impl/pas/services.hpp	(revision 0)
+++ src/vsip/impl/pas/services.hpp	(revision 0)
@@ -0,0 +1,687 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/par-services-pas.hpp
+    @author  Jules Bergmann
+    @date    2006-06-21
+    @brief   VSIPL++ Library: Parallel Services: PAS
+
+*/
+
+#ifndef VSIP_IMPL_PAR_SERVICES_PAS_HPP
+#define VSIP_IMPL_PAR_SERVICES_PAS_HPP
+
+// Only par-services-xxx.hpp header should be included
+#ifdef VSIP_IMPL_PAR_SERVICES_UNIQUE
+#  error "Only one par-services-xxx.hpp should be included"
+#endif
+#define VSIP_IMPL_PAR_SERVICES_UNIQUE
+
+
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <deque>
+#include <vector>
+#include <complex>
+#include <memory>
+
+extern "C" {
+#include <pas.h>
+}
+
+#include <vsip/impl/refcount.hpp>
+#include <vsip/impl/noncopyable.hpp>
+#include <vsip/impl/copy_chain.hpp>
+#include <vsip/impl/reductions-types.hpp>
+#include <vsip/impl/par_assign_fwd.hpp>
+#include <vsip/impl/pas/param.hpp>
+#include <vsip/impl/pas/broadcast.hpp>
+
+
+
+/***********************************************************************
+  Macros
+***********************************************************************/
+
+#define NET_TAG 0
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
+typedef PAS_id          par_ll_pset_type;
+typedef PAS_pbuf_handle par_ll_pbuf_type;
+
+namespace pas
+{
+
+/// Traits class to determine MPI_DATATYPE from a C++ datatype
+
+template <typename T>
+struct Pas_datatype;
+
+#define VSIP_IMPL_PASDATATYPE(CTYPE, PASTYPE)				\
+template <>								\
+struct Pas_datatype<CTYPE>						\
+{									\
+  static PAS_data_spec value() { return PASTYPE; }			\
+};
+
+VSIP_IMPL_PASDATATYPE(bool,                 PAS_DATA_REAL_U8);
+VSIP_IMPL_PASDATATYPE(char,                 PAS_DATA_REAL_S8);
+VSIP_IMPL_PASDATATYPE(unsigned char,        PAS_DATA_REAL_U8);
+VSIP_IMPL_PASDATATYPE(short,                PAS_DATA_REAL_S16);
+VSIP_IMPL_PASDATATYPE(unsigned short,       PAS_DATA_REAL_U16);
+VSIP_IMPL_PASDATATYPE(int,                  PAS_DATA_REAL_S32);
+VSIP_IMPL_PASDATATYPE(unsigned int,         PAS_DATA_REAL_U32);
+VSIP_IMPL_PASDATATYPE(float,                PAS_DATA_REAL_F32);
+VSIP_IMPL_PASDATATYPE(double,               PAS_DATA_REAL_F64);
+VSIP_IMPL_PASDATATYPE(std::complex<float>,  PAS_DATA_COMPLEX_F32);
+VSIP_IMPL_PASDATATYPE(std::complex<double>, PAS_DATA_COMPLEX_F64);
+
+#undef VSIP_IMPL_PASDATATYPE
+
+
+/// DMA Chain builder.
+
+class Chain_builder
+{
+public:
+  Chain_builder()
+    : chain_ ()
+  {}
+
+  ~Chain_builder()
+  {}
+
+  template <typename T>
+  void add(ptrdiff_t start, int stride, unsigned length)
+  {
+    chain_.add(reinterpret_cast<void*>(start), sizeof(T), stride, length);
+  }
+
+  template <typename T>
+  void add(ptrdiff_t start,
+	   int stride0, unsigned length0,
+	   int stride1, unsigned length1)
+  {
+    for (unsigned i=0; i<length1; ++i)
+      chain_.add(reinterpret_cast<void*>(start + sizeof(T)*i*stride1),
+		 sizeof(T), stride0, length0);
+  }
+
+  void* base() { return 0; }
+
+  Copy_chain get_chain()
+  { return chain_; }
+
+  void stitch(void* base, Copy_chain chain)
+  { chain_.append_offset(base, chain); }
+
+  void stitch(std::pair<void*, void*> base, Copy_chain chain)
+  {
+    chain_.append_offset(base.first,  chain);
+    chain_.append_offset(base.second, chain);
+  }
+
+  bool is_empty() const { return (chain_.size() == 0); }
+
+  // Private member data.
+private:
+  Copy_chain                    chain_;
+};
+
+
+
+/// Communicator class.
+
+/// A VSIPL++ Communicator is essentially just an MPI Communicator at
+/// the moment.
+
+class Communicator : Non_copyable
+{
+
+  struct Req_entry : public impl::Ref_count<Req_entry>
+  {
+    bool       done;
+
+    Req_entry() : done(false) {}
+  };
+  class Req;
+  friend class Req;
+  class Req
+  {
+  public:
+    Req() : entry_(new Req_entry, impl::noincrement) {}
+
+    void set(bool val) { (*entry_).done = val; }
+    bool get() { return (*entry_).done; }
+
+  private:
+    impl::Ref_counted_ptr<Req_entry> entry_;
+  };
+  struct Msg;
+  friend struct Msg;
+  struct Msg
+  {
+    Copy_chain  chain_;
+    Req         req_;
+    void*       memory_;
+
+    Msg(Copy_chain chain, Req req, void* memory = 0)
+      : chain_  (chain),
+	req_    (req),
+	memory_ (memory)
+      {}
+  };
+
+  typedef std::deque<Msg> msg_list_type;
+  struct Msg_list;
+  friend struct Msg_list;
+  struct Msg_list : public impl::Ref_count<Msg_list>
+  {
+    msg_list_type list_;
+  };
+
+public:
+  typedef Req                         request_type;
+  typedef Copy_chain                  chain_type;
+  typedef std::vector<processor_type> pvec_type;
+
+public:
+  Communicator() : rank_(0), size_(0),
+      msgs_ (new Msg_list, impl::noincrement), pvec_(0), bcast_(0) {}
+
+  Communicator(long rank, long size)
+    : rank_ (rank),
+      size_ (size),
+      msgs_ (new Msg_list, impl::noincrement),
+      pvec_ (size_),
+      bcast_(0)
+  {
+    for (index_type i=0; i<size_; ++i)
+      pvec_[i] = static_cast<processor_type>(i);
+
+    long* pnums;
+    pnums = new long[size_+1];
+    for (index_type i=0; i<size_; ++i)
+      pnums[i] = pvec_[i];
+    pnums[size_] = PAS_PNUMS_TERM;
+    long rc = pas_pset_create(pnums, 0, &pset_);
+    assert(rc == CE_SUCCESS);
+    delete[] pnums;
+
+    bcast_ = std::auto_ptr<pas::Broadcast>(new pas::Broadcast(impl_ll_pset()));
+  }
+
+  void initialize(long rank, long size)
+  {
+    rank_ = rank;
+    size_ = size;
+    // msgs_ = new Msg_list, impl::noincrement;
+    pvec_.resize(size_);
+
+    for (index_type i=0; i<size_; ++i)
+      pvec_[i] = static_cast<processor_type>(i);
+
+    long* pnums;
+    pnums = new long[size_+1];
+    for (index_type i=0; i<size_; ++i)
+      pnums[i] = pvec_[i];
+    pnums[size_] = PAS_PNUMS_TERM;
+    long rc = pas_pset_create(pnums, 0, &pset_);
+    assert(rc == CE_SUCCESS);
+    delete[] pnums;
+
+    bcast_ = std::auto_ptr<pas::Broadcast>(new pas::Broadcast(impl_ll_pset()));
+  }
+
+  void cleanup()
+  {
+    bcast_.reset(0);
+    long rc = pas_pset_close(pset_, 0);
+    assert(rc == CE_SUCCESS);
+  }
+
+  ~Communicator()
+  {
+  }
+
+  processor_type rank() const { return rank_; }
+  length_type    size() const { return size_; }
+
+  pvec_type pvec() const
+    { return pvec_; }
+
+  pvec_type const& pvec_ref() const
+    { return pvec_; }
+
+  // barrier is no-op for serial execution.
+  void barrier() const
+  {
+    long rc = pas_barrier_sync(pset_, 0, PAS_YIELD | PAS_DMA);
+    assert(rc == CE_SUCCESS);
+  }
+
+  template <typename T>
+  void buf_send(processor_type dest_proc, T* data, length_type size);
+
+  template <typename T>
+  void send(processor_type dest_proc, T* data, length_type size,
+	    request_type& req);
+
+  void send(processor_type dest, chain_type const& chain, request_type& req);
+
+  template <typename T>
+  void recv(processor_type src_proc, T* data, length_type size);
+
+  void recv(processor_type dest, chain_type const& chain);
+
+  void wait(request_type& req);
+
+  template <typename T>
+  void broadcast(processor_type root_proc, T* data, length_type size);
+
+  template <typename T>
+  T allreduce(reduction_type rdx, T value);
+
+  friend bool operator==(Communicator const&, Communicator const&);
+
+  par_ll_pset_type impl_ll_pset() const VSIP_NOTHROW { return pset_; }
+
+private:
+  processor_type	        rank_;
+  length_type		        size_;
+  Ref_counted_ptr<Msg_list>     msgs_;
+  pvec_type                     pvec_;
+  par_ll_pset_type              pset_;
+  std::auto_ptr<pas::Broadcast> bcast_;
+};
+
+} // namespace vsip::impl::pas
+
+
+
+typedef pas::Communicator     Communicator;
+typedef pas::Chain_builder    Chain_builder;
+typedef Direct_pas_assign     par_assign_impl_type;
+
+
+inline void
+create_ll_pset(
+  std::vector<processor_type> const& pvec,
+  par_ll_pset_type&                  pset)
+{
+  std::vector<processor_type> copy(pvec.size() + 1);
+
+  length_type size = pvec.size();
+  for (index_type i=0; i<size; ++i)
+    copy[i] = pvec[i];
+  copy[pvec.size()] = PAS_PNUMS_TERM;
+
+  long rc = pas_pset_create(&copy[0], 0, &pset);
+  assert(rc == CE_SUCCESS);
+}
+
+
+
+inline void
+destroy_ll_pset(par_ll_pset_type& pset)
+{
+  long rc = pas_pset_close(pset, 0);
+  assert(rc == CE_SUCCESS);
+}
+
+
+
+inline void
+free_chain(Copy_chain const& /*chain*/)
+{
+}
+
+
+inline void
+shift_argv(int& argc, char**&argv, int pos, int shift)
+{
+  for (int i=pos; i<argc-shift; ++i)
+    argv[i] = argv[i+shift];
+  argc -= shift;
+}
+
+
+/// Par_service class for when no services are available.
+
+class Par_service
+{
+  // Compile-time values and typedefs.
+public:
+  typedef pas::Communicator communicator_type;
+
+  // Constructors.
+public:
+  Par_service(int& argc, char**& argv)
+    : valid_(1)
+    {
+      long rc;
+      assert(valid_);
+
+      long size = -1;
+      long rank = -1;
+
+      int i = 1;
+      while (i < argc)
+      {
+	if (!strcmp(argv[i], "-pas_size"))
+	{
+	  size = atoi(argv[i+1]);
+	  shift_argv(argc, argv, i, 2);
+	}
+	else if (!strcmp(argv[i], "-pas_rank"))
+	{
+	  rank = atoi(argv[i+1]);
+	  shift_argv(argc, argv, i, 2);
+	}
+	else
+	  i += 1;
+      }
+
+      if (rank == -1 || size == -1)
+      {
+	printf("Usage: runmc <ceid> %s -pas_size <size> -pas_rank <rank>\n", argv[0]);
+	exit(1);
+      }
+
+      printf("INIT: PAS rank/size %ld %ld\n", rank, size);
+      fflush(stdout);
+
+      rc = pas_net_create(NET_TAG, rank, size, &net_handle_);
+      VSIP_IMPL_CHECK_RC(rc,"pas_net_create");
+
+#if VSIP_IMPL_PAS_XR
+#  if VSIP_IMPL_PAS_USE_INTERRUPT()
+      rc = pas_net_enable_semaphore_interrupts (net_handle_);
+      VSIP_IMPL_CHECK_RC(rc, "pas_net_enable_semaphore_interrupts");
+#  endif
+#endif
+
+      /* override some PAS defaults */
+      rc = pas_net_set_heap_size(net_handle_, 0x100000);
+      VSIP_IMPL_CHECK_RC(rc,"pas_net_set_heap_size");
+      rc = pas_net_set_num_semaphores(net_handle_, 2);
+      VSIP_IMPL_CHECK_RC(rc,"pas_net_setnum_semaphores");
+
+
+#if VSIP_IMPL_PAS_XR
+#  if VSIP_IMPL_PAS_XR_SET_PORTNUM
+      rc = pas_net_set_tr_base_portnum(net_handle_, 3939);
+      VSIP_IMPL_CHECK_RC(rc, "pas_net_set_tr_base_portnum");
+#  endif
+
+#  if VSIP_IMPL_PAS_XR_SET_ADAPTERNAME
+      rc = pas_net_set_tr_adapter_name(net_handle_,
+				       VSIP_IMPL_PAS_XR_ADAPTERNAME);
+      VSIP_IMPL_CHECK_RC(rc, "pas_net_set_tr_adapter_name");
+#  endif
+
+#  if VSIP_IMPL_PAS_XR_SET_SHMKEY
+      rc = pas_net_set_tr_nodedb_shmkey (net_handle_, VSIP_IMPL_PAS_XR_SHMKEY);
+      VSIP_IMPL_CHECK_RC(rc, "pas_net_set_tr_nodedb_shmkey");
+#  endif
+
+#  if VSIP_IMPL_PAS_XR_SET_PIR
+      rc = pas_net_set_tr_num_prepost_intr_recvs (net_handle_, 32);
+      VSIP_IMPL_CHECK_RC(rc, "pas_net_set_tr_num_prepost_intr_recvs");
+#  endif
+
+#  if VSIP_IMPL_PAS_XR_SET_RMD
+      rc = pas_net_set_tr_rdma_multibuffer_depth (net_handle_, 32);
+      VSIP_IMPL_CHECK_RC(rc, "pas_net_set_tr_rdma_multibuffer_depth");
+#  endif
+
+#  if VSIP_IMPL_PAS_XR_SET_UDAPL_MAX_RECVS
+      rc = pas_net_set_tr_udapl_max_recvs (net_handle_, VSIP_IMPL_PAS_XR_PAS_UDAPL_MAX_RECVS);
+      VSIP_IMPL_CHECK_RC(rc, "pas_net_set_tr_udapl_max_recvs");
+#  endif
+
+#  if VSIP_IMPL_PAS_XR_SET_UDAPL_MAX_REQUESTS
+      rc = pas_net_set_tr_udapl_max_requests (net_handle_, 
+					      VSIP_IMPL_PAS_XR_PAS_UDAPL_MAX_REQUESTS);
+      VSIP_IMPL_CHECK_RC(rc, "pas_net_set_tr_udapl_max_requests");
+#  endif
+#endif
+
+#if 0 // Enable this to print debug info about the PAS net.
+      char  msg[80];
+      sprintf(msg, "CE%ld ", /*ce_getid(),*/ rank);
+      rc =  pas_net_print_info(net_handle_, msg, NULL, 0);
+      VSIP_IMPL_CHECK_RC(rc,"pas_net_print_info");
+#endif
+
+      /* now open the PAS network */
+      rc = pas_net_open(net_handle_);
+      VSIP_IMPL_CHECK_RC(rc,"pas_net_open");
+
+      default_communicator_.initialize(rank, size);
+    }
+
+  ~Par_service()
+    {
+      default_communicator_.cleanup();
+      long rc = pas_net_close(net_handle_);
+      VSIP_IMPL_CHECK_RC(rc, "pas_net_close");
+      valid_ = 0;
+    }
+
+  static communicator_type& default_communicator()
+    {
+      return default_communicator_;
+    }
+
+private:
+  static communicator_type default_communicator_;
+
+  int			   valid_;
+  PAS_net_handle           net_handle_;
+};
+
+
+
+template <reduction_type rtype,
+	  typename       T>
+struct Reduction_supported
+{ static bool const value = false; };
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace pas
+{
+
+inline bool
+operator==(Communicator const& comm1, Communicator const& comm2)
+{
+  return comm1.msgs_.get() == comm2.msgs_.get();
+}
+
+
+
+inline bool
+operator!=(Communicator const& comm1, Communicator const& comm2)
+{
+  return !operator==(comm1, comm2);
+}
+
+
+
+template <typename T>
+inline void
+Communicator::buf_send(
+  processor_type dest_proc,
+  T*             data,
+  length_type    size)
+{
+  assert(0);
+  assert(dest_proc == 0);
+
+  T* raw = new T[size];
+
+  for (index_type i=0; i<size; ++i)
+    raw[i] = data[i];
+
+  // printf("buf_send %d (val %d) %08x\n", size, *raw, (int)raw);
+  Copy_chain chain;
+  chain.add(reinterpret_cast<void*>(raw), sizeof(T), 1, size);
+
+  msgs_->list_.push_back(Msg(chain, Req(), reinterpret_cast<void*>(raw)));
+}
+
+
+
+template <typename T>
+inline void
+Communicator::send(
+  processor_type dest_proc,
+  T*             data,
+  length_type    size,
+  request_type&  req)
+{
+  assert(0);
+  assert(dest_proc == 0);
+
+  // printf("send %d (val %d)\n", size, *data);
+  Copy_chain chain;
+  chain.add(reinterpret_cast<void*>(data), sizeof(T), 1, size);
+
+  req.set(false);
+  msgs_->list_.push_back(Msg(chain, req));
+}
+
+
+
+inline void
+Communicator::send(
+  processor_type    dest_proc,
+  chain_type const& chain,
+  request_type&     req)
+{
+  assert(0);
+  assert(dest_proc == 0);
+
+  // printf("send chain\n");
+  req.set(false);
+  msgs_->list_.push_back(Msg(chain, req));
+}
+
+
+
+template <typename T>
+inline void
+Communicator::recv(
+  processor_type   src_proc,
+  T*               data,
+  length_type      size)
+{
+  assert(0);
+  assert(src_proc == 0);
+  assert(msgs_->list_.size() > 0);
+
+  Msg msg = msgs_->list_.front();
+  msgs_->list_.pop_front();
+
+  // assert(msg.type_size_ == sizeof(T));
+  assert(msg.chain_.data_size() == size * sizeof(T));
+
+  msg.chain_.copy_into(data, size * sizeof(T));
+
+  msg.req_.set(true);
+
+  if (msg.memory_) delete[] static_cast<char*>(msg.memory_);
+}
+
+
+
+inline void
+Communicator::recv(
+  processor_type    src_proc,
+  chain_type const& chain)
+{
+  assert(0);
+  assert(src_proc == 0);
+  assert(msgs_->list_.size() > 0);
+
+  Msg msg = msgs_->list_.front();
+  msgs_->list_.pop_front();
+
+  // assert(msg.type_size_ == sizeof(T));
+  assert(msg.chain_.data_size() == chain.data_size());
+
+  msg.chain_.copy_into(chain);
+
+  msg.req_.set(true);
+
+  if (msg.memory_) delete[] static_cast<char*>(msg.memory_);
+}
+
+
+
+/// Wait for a previous communication (send or receive) to complete.
+
+inline void
+Communicator::wait(
+  request_type& req)
+{
+  assert(0);
+  // Since there is only one processor, we really can't wait for the
+  // receive to post.  Either it has, or it hasn't, in which case
+  // we are deadlocked.
+  assert(req.get() == true);
+}
+
+
+
+/// Broadcast a value from root processor to other processors.
+
+template <typename T>
+inline void
+Communicator::broadcast(processor_type root_proc, T* value, length_type len)
+{
+  assert(bcast_.get() != 0);
+  for (index_type i=0; i<len; ++i)
+    bcast_->operator()(root_proc, value[i]);
+}
+
+
+
+/// Reduce a value from all processors to all processors.
+
+template <typename T>
+inline T
+Communicator::allreduce(reduction_type, T value)
+{
+  assert(0);
+  return value;
+}
+
+
+
+
+
+
+} // namespace vsip::impl::pas
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_PAR_SERVICES_PAS_HPP
Index: src/vsip/impl/pas/par_assign.hpp
===================================================================
--- src/vsip/impl/pas/par_assign.hpp	(revision 0)
+++ src/vsip/impl/pas/par_assign.hpp	(revision 0)
@@ -0,0 +1,250 @@
+/* Copyright (c)  2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/par_assign_pas.hpp
+    @author  Jules Bergmann
+    @date    2005-06-22
+    @brief   VSIPL++ Library: Parallel assignment algorithm for PAS.
+
+*/
+
+#ifndef VSIP_IMPL_PAR_ASSIGN_PAS_HPP
+#define VSIP_IMPL_PAR_ASSIGN_PAS_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/impl/par-services.hpp>
+#include <vsip/impl/profile.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/impl/view_traits.hpp>
+#include <vsip/impl/par_assign.hpp>
+#include <vsip/impl/pas/param.hpp>
+
+#define VERBOSE 0
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
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+class Par_assign<Dim, T1, T2, Block1, Block2, Pas_assign>
+  : Compile_time_assert<Is_split_block<Block1>::value ==
+                        Is_split_block<Block2>::value>
+{
+  static dimension_type const dim = Dim;
+
+  typedef typename Distributed_local_block<Block1>::type dst_local_block;
+  typedef typename Distributed_local_block<Block2>::type src_local_block;
+
+  typedef typename View_of_dim<dim, T1, dst_local_block>::type
+		dst_lview_type;
+
+  typedef typename View_of_dim<dim, T2, src_local_block>::const_type
+		src_lview_type;
+
+
+  // Constructor.
+public:
+  Par_assign(
+    typename View_of_dim<Dim, T1, Block1>::type       dst,
+    typename View_of_dim<Dim, T2, Block2>::const_type src)
+    : dst_      (dst),
+      src_      (src.block()),
+      ready_sem_index_(0),
+      done_sem_index_ (0)
+  {
+    long rc;
+    long const reserved_flags = 0;
+    impl::profile::Scope_event ev("Par_assign<Pas_assign>-cons");
+
+    PAS_id src_pset = src_.block().map().impl_ll_pset();
+    PAS_id dst_pset = dst_.block().map().impl_ll_pset();
+    PAS_id all_pset;
+
+    long* src_pnums;
+    long* dst_pnums;
+    long* all_pnums;
+    long  src_npnums;
+    long  dst_npnums;
+    unsigned long  all_npnums;
+
+    pas_pset_get_pnums_list(src_pset, &src_pnums, &src_npnums);
+    pas_pset_get_pnums_list(dst_pset, &dst_pnums, &dst_npnums);
+    all_pnums = pas_pset_combine(src_pnums, dst_pnums, PAS_PSET_UNION,
+				 &all_npnums);
+    pas_pset_create(all_pnums, 0, &all_pset);
+
+    free(src_pnums);
+    free(dst_pnums);
+    free(all_pnums);
+
+
+    // Set default values if temporary buffer is not necessary
+    // Either not in pset, or local_nbytes == 0
+    move_desc_ = NULL;
+    pull_flags_ = 0;
+
+
+    // Setup tmp buffer
+    if (pas_pset_is_member(all_pset))
+    {
+      long                 local_nbytes;
+
+      rc = pas_distribution_calc_tmp_local_nbytes(
+	src_.block().impl_ll_dist(),
+	dst_.block().impl_ll_dist(),
+	pas::Pas_datatype<T1>::value(),
+	0,
+	&local_nbytes);
+      assert(rc == CE_SUCCESS);
+#if VERBOSE
+      std::cout << "[" << local_processor() << "] "
+		<< "local_nbytes = " << local_nbytes << std::endl;
+#endif
+
+      if (local_nbytes > 0)
+      {
+	rc = pas_pbuf_create(
+	  0, 
+	  all_pset,
+	  local_nbytes,
+	  1,
+	  1,
+	  PAS_ZERO,
+	  &tmp_pbuf_);
+	assert(rc == CE_SUCCESS);
+	
+	rc = pas_move_desc_create(reserved_flags, &move_desc_);
+	assert(rc == CE_SUCCESS);
+
+	rc = pas_move_desc_set_tmp_pbuf(move_desc_, tmp_pbuf_, 0);
+	assert(rc == CE_SUCCESS);
+
+	pull_flags_ = PAS_WAIT;
+      }
+    }
+  }
+
+  ~Par_assign()
+  {
+    long const reserved_flags = 0;
+    long rc;
+
+    if (move_desc_ != NULL)
+    {
+      rc = pas_move_desc_destroy(move_desc_, reserved_flags);
+      assert(rc == CE_SUCCESS);
+      
+      rc = pas_pbuf_destroy(tmp_pbuf_, reserved_flags);
+      assert(rc == CE_SUCCESS);
+    }
+  }
+
+
+  // Invoke the parallel assignment
+public:
+  void operator()()
+  {
+    long rc;
+
+    PAS_id src_pset = src_.block().map().impl_ll_pset();
+    PAS_id dst_pset = dst_.block().map().impl_ll_pset();
+
+    PAS_dynamic_xfer_handle dynamic_xfer=NULL;
+    rc = pas_dynamic_xfer_create(num_processors(), 3, 0, &dynamic_xfer);
+    assert(rc == CE_SUCCESS);
+
+    // -------------------------------------------------------------------
+    // Tell source that dst is ready
+    if (pas_pset_is_member(dst_pset))
+    {
+      // assert that subblock is not emtpy
+#if VERBOSE
+      std::cout << "[" << local_processor() << "] "
+		<< "give start" << std::endl << std::flush;
+#endif
+
+      pas::semaphore_give(src_pset, ready_sem_index_);
+
+#if VERBOSE
+      std::cout << "[" << local_processor() << "] "
+		<< "give done" << std::endl << std::flush;
+#endif
+    }
+
+
+    // -------------------------------------------------------------------
+    // Push when dst is ready
+    if (pas_pset_is_member(src_pset))
+    {
+      pas::semaphore_take(dst_pset, ready_sem_index_);
+
+#if VERBOSE
+      std::cout << "[" << local_processor() << "] "
+		<< "push start" << std::endl << std::flush;
+#endif
+      rc = pas_push(dynamic_xfer, move_desc_,
+		    src_.block().impl_ll_pbuf(),
+		    src_.block().impl_ll_dist(),
+		    dst_.block().impl_ll_pbuf(),
+		    dst_.block().impl_ll_dist(),
+		    pas::Pas_datatype<T1>::value(),
+		    done_sem_index_,
+		    pull_flags_ | VSIP_IMPL_PAS_XFER_ENGINE |
+		    VSIP_IMPL_PAS_SEM_GIVE_AFTER,
+		    NULL); 
+      assert(rc == CE_SUCCESS);
+#if VERBOSE
+      std::cout << "[" << local_processor() << "] "
+		<< "push done" << std::endl << std::flush;
+#endif
+    }
+
+    // -------------------------------------------------------------------
+    // Wait for push to complete.
+    if (pas_pset_is_member(dst_pset))
+      pas::semaphore_take(src_pset, done_sem_index_);
+
+    rc = pas_dynamic_xfer_destroy(dynamic_xfer, 0);
+    assert(rc == CE_SUCCESS);
+  }
+
+
+  // Private member data.
+private:
+  typename View_of_dim<Dim, T1, Block1>::type       dst_;
+  typename View_of_dim<Dim, T2, Block2>::const_type src_;
+
+  PAS_move_desc_handle move_desc_;
+  PAS_pbuf_handle      tmp_pbuf_;
+  long                 pull_flags_;
+  long                 ready_sem_index_;
+  long                 done_sem_index_;
+};
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+
+#undef VERBOSE
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_IMPL_PAR_ASSIGN_PAS_HPP
Index: src/vsip/impl/par-util.hpp
===================================================================
--- src/vsip/impl/par-util.hpp	(revision 147999)
+++ src/vsip/impl/par-util.hpp	(working copy)
@@ -18,7 +18,6 @@
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
-#include <vsip/impl/distributed-block.hpp>
 #include <vsip/domain.hpp>
 
 
Index: src/vsip/impl/par_assign_common.hpp
===================================================================
--- src/vsip/impl/par_assign_common.hpp	(revision 0)
+++ src/vsip/impl/par_assign_common.hpp	(revision 0)
@@ -0,0 +1,72 @@
+/* Copyright (c)  2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/par_assign_common.hpp
+    @author  Jules Bergmann
+    @date    2006-08-29
+    @brief   VSIPL++ Library: Parallel assignment common routines.
+
+*/
+
+#ifndef VSIP_IMPL_PAR_ASSIGN_COMMON_HPP
+#define VSIP_IMPL_PAR_ASSIGN_COMMON_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/map_fwd.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+template <typename MapT>
+bool
+processor_has_block(
+  MapT const&    map,
+  processor_type proc,
+  index_type     sb)
+{
+  typedef typename MapT::processor_iterator iterator;
+
+  for (iterator cur = map.processor_begin(sb);
+       cur != map.processor_end(sb);
+       ++cur)
+  {
+    if (*cur == proc)
+      return true;
+  }
+  return false;
+}
+
+
+
+// Special case for Global_map.  Since map is replicated, the answer
+// is always yes (if proc and sb are valid).
+
+template <dimension_type Dim>
+bool
+processor_has_block(
+  Global_map<Dim> const& /*map*/,
+  processor_type         /*proc*/,
+  index_type             sb)
+{
+  assert(sb == 0);
+  return true;
+}
+
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_IMPL_PAR_ASSIGN_COMMON_HPP
Index: src/vsip/impl/par-services.hpp
===================================================================
--- src/vsip/impl/par-services.hpp	(revision 147999)
+++ src/vsip/impl/par-services.hpp	(working copy)
@@ -20,6 +20,8 @@
 
 #if VSIP_IMPL_PAR_SERVICE == 1
 #  include <vsip/impl/par-services-mpi.hpp>
+#elif VSIP_IMPL_PAR_SERVICE == 2
+#  include <vsip/impl/pas/services.hpp>
 #else
 #  include <vsip/impl/par-services-none.hpp>
 #endif
Index: src/vsip/impl/config.hpp
===================================================================
--- src/vsip/impl/config.hpp	(revision 147999)
+++ src/vsip/impl/config.hpp	(working copy)
@@ -22,4 +22,47 @@
 #undef PACKAGE_TARNAME
 #undef PACKAGE_VERSION
 
+
+
+/***********************************************************************
+  Parallel Configuration
+***********************************************************************/
+
+// VSIP_DIST_LEVEL describes the implementations distribution support
+// level [dpp.distlevel]:
+//  0 - distribution of data is not support (not a parallel impl).
+//  1 - one dimension of data may be block distributed.
+//  2 - any and all dimensions of data may be block distributed.
+//  3 - any and all dimensions of data may be block-cyclic distributed.
+
+// VSIP_IMPL_USE_PAS_SEGMENT_SIZE indicates whether PAS or VSIPL++
+// algorithm for choosing segment sizes should be used.  When using
+// PAS, this must be 1 so that VSIPL++ and PAS agree on how data
+// is distributed.  When using MPI, this can be either 0 or 1, but
+// the PAS algorithm results in empty blocks in some cases.
+
+#if VSIP_IMPL_PAR_SERVICE == 1
+// MPI
+#  define VSIP_DIST_LEVEL                3
+#  define VSIP_IMPL_USE_PAS_SEGMENT_SIZE 0
+
+#elif VSIP_IMPL_PAR_SERVICE == 2
+// PAS
+#  define VSIP_DIST_LEVEL                2
+#  define VSIP_IMPL_USE_PAS_SEGMENT_SIZE 1
+
+#else
+// Other (serial)
+
+// In serial, Sourcery VSIPL++ supports block-cyclic distribution of data
+// (across 1 processor).  While this support provides no additional
+// functionality, it allows parallel programs to be compiled and run
+// unchanged in serial.
+#  define VSIP_DIST_LEVEL                3
+
+#  define VSIP_IMPL_USE_PAS_SEGMENT_SIZE 0
+
 #endif
+
+
+#endif // VSIP_IMPL_CONFIG_HPP
Index: src/vsip/impl/expr_unary_block.hpp
===================================================================
--- src/vsip/impl/expr_unary_block.hpp	(revision 147999)
+++ src/vsip/impl/expr_unary_block.hpp	(working copy)
@@ -123,6 +123,10 @@
 			   typename Distributed_local_block<Block>::type,
 			   Type> const
 		type;
+  typedef Unary_expr_block<Dim, Op,
+			   typename Distributed_local_block<Block>::proxy_type,
+			   Type> const
+		proxy_type;
 };
 
 template <dimension_type            Dim,
@@ -136,6 +140,10 @@
 			   typename Distributed_local_block<Block>::type,
 			   Type> 
 		type;
+  typedef Unary_expr_block<Dim, Op,
+			   typename Distributed_local_block<Block>::proxy_type,
+			   Type> 
+		proxy_type;
 };
 
 
Index: src/vsip/impl/choose_par_assign_impl.hpp
===================================================================
--- src/vsip/impl/choose_par_assign_impl.hpp	(revision 0)
+++ src/vsip/impl/choose_par_assign_impl.hpp	(revision 0)
@@ -0,0 +1,72 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/choose_par_assign_impl.hpp
+    @author  Jules Bergmann
+    @date    2006-08-29
+    @brief   VSIPL++ Library: Choose Par_assign impl tag.
+
+*/
+
+#ifndef VSIP_IMPL_CHOOSE_PAR_ASSIGN_IMPL_HPP
+#define VSIP_IMPL_CHOOSE_PAR_ASSIGN_IMPL_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/metaprogramming.hpp>
+#include <vsip/impl/block-traits.hpp>
+#include <vsip/impl/map-traits.hpp>
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
+// Only valid if Block1 and Block2 are simple distributed blocks.
+
+#if VSIP_IMPL_PAR_SERVICE == 0 || VSIP_IMPL_PAR_SERVICE == 1
+  // MPI
+template <dimension_type Dim,
+	  typename       Block1,
+	  typename       Block2>
+struct Choose_par_assign_impl
+{
+  typedef typename Block1::map_type map1_type;
+  typedef typename Block2::map_type map2_type;
+
+  static int const  is_blkvec     = (Dim == 1) &&
+                                    Is_block_dist<0, map1_type>::value &&
+                                    Is_block_dist<0, map2_type>::value;
+
+  typedef typename
+  ITE_Type<is_blkvec, As_type<Blkvec_assign>, As_type<Chained_assign> >
+	::type type;
+};
+#else
+template <dimension_type Dim,
+	  typename       Block1,
+	  typename       Block2>
+struct Choose_par_assign_impl
+{
+  static int const  is_pas_assign = Is_pas_block<Block1>::value &&
+                                    Is_pas_block<Block2>::value;
+
+  typedef typename
+  ITE_Type<is_pas_assign, As_type<Pas_assign>,
+                          As_type<Direct_pas_assign>
+          >::type type;
+};
+#endif
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_CHOOSE_PAR_ASSIGN_IMPL_HPP
Index: src/vsip/impl/par_assign_blkvec.hpp
===================================================================
--- src/vsip/impl/par_assign_blkvec.hpp	(revision 147999)
+++ src/vsip/impl/par_assign_blkvec.hpp	(working copy)
@@ -22,6 +22,7 @@
 #include <vsip/impl/par-services.hpp>
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/par_assign.hpp>
+#include <vsip/impl/adjust-layout.hpp>
 
 // Verbosity level:
 //  0 - no debug info
Index: src/vsip/impl/par-chain-assign.hpp
===================================================================
--- src/vsip/impl/par-chain-assign.hpp	(revision 147999)
+++ src/vsip/impl/par-chain-assign.hpp	(working copy)
@@ -22,6 +22,7 @@
 #include <vsip/impl/par-services.hpp>
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/par_assign.hpp>
+#include <vsip/impl/par_assign_common.hpp>
 
 #define VSIP_IMPL_PCA_ROTATE  0
 #define VSIP_IMPL_PCA_VERBOSE 0
@@ -389,44 +390,6 @@
   Definitions
 ***********************************************************************/
 
-template <typename MapT>
-bool
-processor_has_block(
-  MapT const&    map,
-  processor_type proc,
-  index_type     sb)
-{
-  typedef typename MapT::processor_iterator iterator;
-
-  for (iterator cur = map.processor_begin(sb);
-       cur != map.processor_end(sb);
-       ++cur)
-  {
-    if (*cur == proc)
-      return true;
-  }
-  return false;
-}
-
-
-
-// Special case for Serial_map.  Since map is replicated, the answer
-// is always yes (if proc and sb are valid).
-
-template <dimension_type Dim>
-bool
-processor_has_block(
-  Global_map<Dim> const& /*map*/,
-  processor_type         proc,
-  index_type             sb)
-{
-  assert(sb == 0);
-  assert(proc < num_processors());
-  return true;
-}
-
-
-
 // Build the send_list, a list of processor-subblock-local_domain
 // records.  This can be done in advance of the actual assignment.
 
@@ -854,6 +817,7 @@
 }
 
 
+
 } // namespace vsip::impl
 
 } // namespace vsip
Index: src/vsip/impl/par-services-mpi.hpp
===================================================================
--- src/vsip/impl/par-services-mpi.hpp	(revision 147999)
+++ src/vsip/impl/par-services-mpi.hpp	(working copy)
@@ -30,7 +30,7 @@
 #include <vsip/support.hpp>
 #include <vsip/impl/reductions-types.hpp>
 #include <vsip/impl/profile.hpp>
-#include <vsip/impl/par_assign.hpp>
+#include <vsip/impl/par_assign_fwd.hpp>
 
 
 
@@ -45,6 +45,9 @@
 namespace impl
 {
 
+typedef int par_ll_pbuf_type;
+typedef int par_ll_pset_type;
+
 namespace mpi
 {
 
@@ -278,8 +281,12 @@
   processor_type rank() const { return rank_; }
   length_type    size() const { return size_; }
 
-  pvec_type pvec() const { return pvec_; }
+  pvec_type pvec() const
+    { return pvec_; }
 
+  pvec_type const& pvec_ref() const
+    { return pvec_; }
+
   void barrier() const { MPI_Barrier(comm_); }
 
   template <typename T>
@@ -306,6 +313,9 @@
 
   friend bool operator==(Communicator const&, Communicator const&);
 
+  par_ll_pset_type impl_ll_pset() const VSIP_NOTHROW
+  { return par_ll_pset_type(); }
+
 private:
   MPI_Comm		 comm_;
   processor_type	 rank_;
@@ -322,6 +332,16 @@
 typedef Chained_assign par_assign_impl_type;
 
 inline void
+create_ll_pset(
+  std::vector<processor_type> const&,
+  par_ll_pset_type&)
+{}
+
+inline void
+destroy_ll_pset(par_ll_pset_type&)
+{}
+
+inline void
 free_chain(MPI_Datatype chain)
 {
   MPI_Type_free(&chain);
Index: src/vsip/impl/dist.hpp
===================================================================
--- src/vsip/impl/dist.hpp	(revision 147999)
+++ src/vsip/impl/dist.hpp	(working copy)
@@ -15,7 +15,10 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
+#include <vsip/impl/config.hpp>
 
+
+
 /***********************************************************************
   Declarations & Class Definitions
 ***********************************************************************/
@@ -42,7 +45,20 @@
 inline length_type
 segment_size(length_type size, length_type num, index_type pos)
 {
+#if VSIP_IMPL_USE_PAS_SEGMENT_SIZE
+  length_type segment = size / num;
+  if (size % num == 0)
+    return segment;
+  else if (size < num)
+    return (pos < size) ? 1 : 0;
+  // else if (pos < num-1) return segment + 1;
+  else if ((pos+1)*(segment+1) < size)
+    return segment + 1;
+  else
+    return (size < pos*(segment+1)) ? 0 : size - pos*(segment+1);
+#else
   return (size / num) + (pos < size % num ? 1 : 0);
+#endif
 }
 
 
@@ -189,7 +205,14 @@
   length_type num,
   index_type  pos)
 {
+#if VSIP_IMPL_USE_PAS_SEGMENT_SIZE
+  if (size % num == 0)
+    return pos * (size / num);
+  else
+    return pos * ((size / num) + 1);
+#else
   return pos * (size / num) + std::min(pos, size % num);
+#endif
 }
 
 } // namespace impl
@@ -499,6 +522,12 @@
 Block_dist::impl_subblock_from_index(Domain<1> const& dom, index_type i)
   const VSIP_NOTHROW
 {
+#if VSIP_IMPL_USE_PAS_SEGMENT_SIZE
+  length_type nominal_block_size = dom.length() / num_subblocks_
+    + (dom.length() % num_subblocks_ == 0 ? 0 : 1);
+
+  return i / nominal_block_size;
+#else
   length_type nominal_block_size = dom.length() / num_subblocks_;
   length_type spill_over         = dom.length() % num_subblocks_;
 
@@ -506,6 +535,7 @@
     return i / (nominal_block_size+1);
   else
     return (i - spill_over) / nominal_block_size;
+#endif
 }
 
 
@@ -514,13 +544,24 @@
 Block_dist::impl_local_from_global_index(Domain<1> const& dom, index_type i)
   const VSIP_NOTHROW
 {
+#if VSIP_IMPL_USE_PAS_SEGMENT_SIZE
   length_type nominal_block_size = dom.length() / num_subblocks_;
+
+  if (dom.length() % num_subblocks_ == 0)
+    // all blocks are same size
+    return i % (nominal_block_size);
+  else
+    // all blocks are same size, except last one
+    return i % (nominal_block_size+1);
+#else
+  length_type nominal_block_size = dom.length() / num_subblocks_;
   length_type spill_over         = dom.length() % num_subblocks_;
 
   if (i < (nominal_block_size+1)*spill_over)
     return i % (nominal_block_size+1);
   else
     return (i - spill_over) % nominal_block_size;
+#endif
 }
 
 
@@ -540,12 +581,20 @@
   index_type       i)
 const VSIP_NOTHROW
 {
+#if VSIP_IMPL_USE_PAS_SEGMENT_SIZE
   length_type nominal_block_size = dom.length() / num_subblocks_;
+  if (dom.length() % num_subblocks_ == 0)
+    return sb * nominal_block_size + i;
+  else
+    return sb * (nominal_block_size+1) + i;
+#else
+  length_type nominal_block_size = dom.length() / num_subblocks_;
   length_type spill_over         = dom.length() % num_subblocks_;
 
   return sb * nominal_block_size  +
          std::min(sb, spill_over) +
          i;
+#endif
 }
 
 
Index: src/vsip/impl/choose_dist_block.hpp
===================================================================
--- src/vsip/impl/choose_dist_block.hpp	(revision 0)
+++ src/vsip/impl/choose_dist_block.hpp	(revision 0)
@@ -0,0 +1,68 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/choose_dist_block.hpp
+    @author  Jules Bergmann
+    @date    2006-08-29
+    @brief   VSIPL++ Library: Choose distributed block implementation.
+
+*/
+
+#ifndef VSIP_IMPL_CHOOSE_DIST_BLOCK_HPP
+#define VSIP_IMPL_CHOOSE_DIST_BLOCK_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/config.hpp>
+#include <vsip/impl/metaprogramming.hpp>
+#include <vsip/impl/block-traits.hpp>
+#include <vsip/impl/map-traits.hpp>
+#include <vsip/impl/dense_fwd.hpp>
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
+/// Forward Declaration
+template <typename Block,
+	  typename Map>
+class Distributed_block;
+
+
+/// Forward Declaration
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+class Pas_block;
+
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+struct Choose_dist_block
+{
+#if VSIP_IMPL_PAR_SERVICE == 1
+  typedef Distributed_block<Dense<Dim, T, OrderT, Local_map>, MapT> type;
+#elif VSIP_IMPL_PAR_SERVICE == 2
+  typedef Pas_block<Dim, T, OrderT, MapT> type;
+#else
+  typedef Distributed_block<Dense<Dim, T, OrderT, Local_map>, MapT> type;
+#endif
+};
+	  
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_CHOOSE_DIST_BLOCK_HPP
Index: src/vsip/impl/get_local_view.hpp
===================================================================
--- src/vsip/impl/get_local_view.hpp	(revision 0)
+++ src/vsip/impl/get_local_view.hpp	(revision 0)
@@ -0,0 +1,100 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/get_local_view.hpp
+    @author  Jules Bergmann
+    @date    2005-03-22
+    @brief   VSIPL++ Library: Get_local_view function & helper class.
+
+*/
+
+#ifndef VSIP_IMPL_GET_LOCAL_VIEW_HPP
+#define VSIP_IMPL_GET_LOCAL_VIEW_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/impl/block-traits.hpp>
+#include <vsip/impl/domain-utils.hpp>
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
+/// Get a local view of a subblock.
+
+template <template <typename, typename> class View,
+	  typename                            T,
+	  typename                            Block,
+	  typename                            MapT = typename Block::map_type>
+struct Get_local_view_class
+{
+  static
+  View<T, typename Distributed_local_block<Block>::type>
+  exec(
+    View<T, Block> v)
+  {
+    typedef typename Distributed_local_block<Block>::type block_t;
+    typedef typename View_block_storage<block_t>::type::equiv_type storage_t;
+
+    storage_t blk = get_local_block(v.block());
+    return View<T, block_t>(blk);
+  }
+};
+
+template <template <typename, typename> class View,
+	  typename                            T,
+	  typename                            Block>
+struct Get_local_view_class<View, T, Block, Local_map>
+{
+  static
+  View<T, typename Distributed_local_block<Block>::type>
+  exec(
+    View<T, Block> v)
+  {
+    typedef typename Distributed_local_block<Block>::type block_t;
+    assert((Type_equal<Block, block_t>::value));
+    return v;
+  }
+};
+	  
+
+
+template <template <typename, typename> class View,
+	  typename                            T,
+	  typename                            Block>
+View<T, typename Distributed_local_block<Block>::type>
+get_local_view(
+  View<T, Block> v)
+{
+  return Get_local_view_class<View, T, Block>::exec(v);
+}
+
+
+
+template <template <typename, typename> class View,
+	  typename                            T,
+	  typename                            Block>
+void
+view_assert_local(
+  View<T, Block> v,
+  index_type     sb)
+{
+  assert_local(v.block(), sb);
+}
+
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+
+#endif // VSIP_IMPL_GET_LOCAL_VIEW_HPP
Index: src/vsip/impl/par-support.hpp
===================================================================
--- src/vsip/impl/par-support.hpp	(revision 147999)
+++ src/vsip/impl/par-support.hpp	(working copy)
@@ -18,7 +18,6 @@
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
-#include <vsip/impl/distributed-block.hpp>
 #include <vsip/impl/domain-utils.hpp>
 
 
Index: src/vsip/impl/block-traits.hpp
===================================================================
--- src/vsip/impl/block-traits.hpp	(revision 147999)
+++ src/vsip/impl/block-traits.hpp	(working copy)
@@ -114,11 +114,16 @@
 
 /// The primary definition works for non-distributed blocks were the
 /// local block is just the block type.
+///
+///   TYPE indicates the local block type.
+///   PROXY_TYPE indicates the proxy local block type, to be used for
+///     querying layout of local blocks on remote processors.
 
 template <typename Block>
 struct Distributed_local_block
 {
   typedef Block type;
+  typedef Block proxy_type;
 };
 
 
@@ -393,6 +398,19 @@
   };
 };
 
+
+
+/// Traits class to determine if a block has a valid PAS distribution
+/// handle (which allows collective assignment to be used).  Blocks
+/// without a valid PAS distribution must use the low-level direct
+/// assignment.
+
+template <typename BlockT>
+struct Is_pas_block
+{
+  static bool const value = false;
+};
+
 } // namespace impl
 
 } // namespace vsip
Index: src/vsip/impl/sv_block.hpp
===================================================================
--- src/vsip/impl/sv_block.hpp	(revision 147999)
+++ src/vsip/impl/sv_block.hpp	(working copy)
@@ -95,6 +95,7 @@
   map_type const& map() const VSIP_NOTHROW { return map_; }
 
   vector_type impl_vector() { return vector_; }
+  vector_type const& impl_vector_ref() { return vector_; }
 
   // Hidden copy constructor and assignment.
 private:
Index: src/vsip/impl/proxy_local_block.hpp
===================================================================
--- src/vsip/impl/proxy_local_block.hpp	(revision 0)
+++ src/vsip/impl/proxy_local_block.hpp	(revision 0)
@@ -0,0 +1,133 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/proxy_local_block.hpp
+    @author  Jules Bergmann
+    @date    2005-08-21
+    @brief   VSIPL++ Library: ...
+
+*/
+
+#ifndef VSIP_IMPL_PROXY_LOCAL_BLOCK_HPP
+#define VSIP_IMPL_PROXY_LOCAL_BLOCK_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/layout.hpp>
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
+template <dimension_type Dim,
+	  typename       T,
+	  typename       LP>
+class Proxy_local_block
+{
+  // Compile-time values and types.
+public:
+  static dimension_type const dim = Dim;
+
+  typedef T        value_type;
+  typedef T&       reference_type;
+  typedef T const& const_reference_type;
+
+  typedef Local_map map_type;
+
+  // Implementation types.
+public:
+  typedef LP                       layout_type;
+  typedef impl::Applied_layout<LP> applied_layout_type;
+
+  // Constructors and destructor.
+public:
+  Proxy_local_block(Length<Dim> const& size)
+    : layout_(size)
+  {}
+
+  // Data accessors.
+public:
+  // No get, put.
+
+  // Direct_data interface.
+public:
+  long impl_offset() VSIP_NOTHROW
+    { return 0; }
+
+  // NO // impl_data_type       impl_data()       VSIP_NOTHROW
+
+  // NO // impl_const_data_type impl_data() const VSIP_NOTHROW
+
+  stride_type impl_stride(dimension_type block_dim, dimension_type d)
+    const VSIP_NOTHROW
+  {
+    assert((block_dim == 1 || block_dim == Dim) && (d < block_dim));
+    return (block_dim == 1) ? 1 : layout_.stride(d);
+  }
+
+  // Accessors.
+public:
+  length_type size() const VSIP_NOTHROW
+  {
+    length_type retval = layout_.size(0);
+    for (dimension_type d=1; d<Dim; ++d)
+      retval *= layout_.size(d);
+    return retval;
+  }
+
+  length_type size(dimension_type block_dim, dimension_type d)
+    const VSIP_NOTHROW
+  {
+    assert((block_dim == 1 || block_dim == Dim) && (d < block_dim));
+    return (block_dim == 1) ? this->size() : this->layout_.size(d);
+  }
+
+  map_type const& map() const VSIP_NOTHROW { return map_; }
+
+
+  // Member data.
+private:
+  applied_layout_type layout_;
+  map_type            map_;
+};
+
+
+
+// Store Proxy_local_block by-value.
+template <dimension_type Dim,
+	  typename       T,
+	  typename       LP>
+struct View_block_storage<Proxy_local_block<Dim, T, LP> >
+  : By_value_block_storage<Proxy_local_block<Dim, T, LP> >
+{};
+
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       LP>
+struct Block_layout<Proxy_local_block<Dim, T, LP> >
+{
+  static dimension_type const dim = Dim;
+
+  typedef Direct_access_tag         access_type;
+  typedef typename LP::order_type   order_type;
+  typedef typename LP::pack_type    pack_type;
+  typedef typename LP::complex_type complex_type;
+
+  typedef Layout<dim, order_type, pack_type, complex_type> layout_type;
+};
+
+} // namespace vsip::impl
+} // namespace vsip
+
+
+
+#endif // VSIP_IMPL_PROXY_LOCAL_BLOCK_HPP
Index: src/vsip/impl/dispatch-assign.hpp
===================================================================
--- src/vsip/impl/dispatch-assign.hpp	(revision 147999)
+++ src/vsip/impl/dispatch-assign.hpp	(working copy)
@@ -20,8 +20,7 @@
 #include <vsip/impl/map-traits.hpp>
 #include <vsip/impl/par-expr.hpp>
 #include <vsip/impl/expr_serial_dispatch.hpp>
-#include <vsip/impl/par-chain-assign.hpp>
-#include <vsip/impl/par_assign_blkvec.hpp>
+#include <vsip/impl/par_assign.hpp>
 
 
 
@@ -82,20 +81,19 @@
   static int const  lhs_cost      = Ext_data_cost<Block1>::value;
   static int const  rhs_cost      = Ext_data_cost<Block2>::value;
 
-  static int const  is_blkvec     = is_rhs_simple && (Dim == 1) &&
-                                    Is_block_dist<0, map1_type>::value &&
-                                    Is_block_dist<0, map2_type>::value;
 
+  typedef typename Choose_par_assign_impl<Dim, Block1, Block2>::type
+    par_assign_type;
+
   typedef typename
   ITE_Type<is_illegal,          As_type<Tag_illegal_mix_of_local_and_global_in_assign>,
   ITE_Type<is_local && !is_rhs_expr && lhs_cost == 0 && rhs_cost == 0 &&
 	   !is_lhs_split && !is_rhs_split,
                                 As_type<Tag_serial_assign>,
   ITE_Type<is_local,            As_type<Tag_serial_expr>,
-  ITE_Type<is_blkvec,           As_type<Tag_par_assign<Blkvec_assign> >,
-  ITE_Type<is_rhs_simple,       As_type<Tag_par_assign<par_assign_impl_type> >,
+  ITE_Type<is_rhs_simple,       As_type<Tag_par_assign<par_assign_type> >,
   ITE_Type<is_rhs_reorg,        As_type<Tag_par_expr>,
-	                        As_type<Tag_par_expr_noreorg> > > > > > >
+	                        As_type<Tag_par_expr_noreorg> > > > > >
 		::type type;
 };
 
Index: src/vsip/impl/par_assign.hpp
===================================================================
--- src/vsip/impl/par_assign.hpp	(revision 147999)
+++ src/vsip/impl/par_assign.hpp	(working copy)
@@ -15,36 +15,19 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
+#include <vsip/impl/config.hpp>
+#include <vsip/impl/par_assign_fwd.hpp>
+#include <vsip/impl/choose_par_assign_impl.hpp>
 
+#if VSIP_IMPL_PAR_SERVICE == 1
+#  include <vsip/impl/par-chain-assign.hpp>
+#  include <vsip/impl/par_assign_blkvec.hpp>
+#elif VSIP_IMPL_PAR_SERVICE == 2
+#  include <vsip/impl/pas/par_assign.hpp>
+#  include <vsip/impl/pas/par_assign_direct.hpp>
+#else
+#endif
 
 
-/***********************************************************************
-  Declarations
-***********************************************************************/
 
-namespace vsip
-{
-
-namespace impl
-{
-
-struct Chained_assign;
-struct Blkvec_assign;
-struct Pas_assign;
-
-// Parallel assignment.
-template <dimension_type Dim,
-	  typename       T1,
-	  typename       T2,
-	  typename       Block1,
-	  typename       Block2,
-	  typename       ImplTag>
-class Par_assign;
-
-
-
-} // namespace vsip::impl
-
-} // namespace vsip
-
 #endif // VSIP_IMPL_PAR_ASSIGN_HPP
Index: src/vsip/impl/par-expr.hpp
===================================================================
--- src/vsip/impl/par-expr.hpp	(revision 147999)
+++ src/vsip/impl/par-expr.hpp	(working copy)
@@ -19,6 +19,7 @@
 #include <vsip/impl/distributed-block.hpp>
 #include <vsip/impl/block-traits.hpp>
 #include <vsip/impl/par_assign.hpp>
+#include <vsip/impl/choose_par_assign_impl.hpp>
 
 
 
@@ -71,15 +72,23 @@
   typedef typename Block_layout<BlockT>::complex_type      complex_type;
   typedef Layout<Dim, order_type, pack_type, complex_type> layout_type;
 
+#if VSIP_IMPL_PAR_SERVICE == 0 || VSIP_IMPL_PAR_SERVICE == 1
   typedef Fast_block<Dim, value_type, layout_type>  local_block_type;
   typedef Distributed_block<local_block_type, MapT> dst_block_type;
+#else
+  typedef Pas_block<Dim, value_type, order_type, MapT> dst_block_type;
+  typedef typename dst_block_type::local_block_type   local_block_type;
+#endif
 
   typedef typename View_of_dim<Dim, value_type, dst_block_type>::type
 		dst_view_type;
   typedef typename View_of_dim<Dim, value_type, BlockT>::const_type
 		src_view_type;
 
+  typedef typename Choose_par_assign_impl<Dim, dst_block_type, BlockT>::type
+    par_assign_type;
 
+
 public:
   Par_expr_block(MapT const& map, BlockT const& block);
   ~Par_expr_block() {}
@@ -106,7 +115,7 @@
   dst_view_type   dst_;
   src_view_type   src_;
   Par_assign<Dim, value_type, value_type, dst_block_type, BlockT,
-             par_assign_impl_type>
+             par_assign_type>
 		  assign_;
 };
 
@@ -323,6 +332,8 @@
 {
   typedef typename Par_expr_block<Dim, MapT, BlockT>::local_block_type
 		type;
+  typedef typename Par_expr_block<Dim, MapT, BlockT>::local_block_type
+		proxy_type;
 };
 
 
Index: src/vsip/impl/subblock.hpp
===================================================================
--- src/vsip/impl/subblock.hpp	(revision 147999)
+++ src/vsip/impl/subblock.hpp	(working copy)
@@ -246,11 +246,18 @@
 {
   typedef Map<Dist0, Dist1, Dist2> type;
 
-  static type convert_map(Map<Dist0, Dist1, Dist2> const& map,
-			  Domain<Dim> const&              dom)
+  static type convert_map(type const&        map,
+			  Domain<Dim> const& dom)
   {
-    return Map_subdomain<Dim, Map<Dist0, Dist1, Dist2> >::project(map, dom);
+    return Map_subdomain<Dim, type>::project(map, dom);
   }
+
+  static index_type parent_subblock(type const&        map,
+				    Domain<Dim> const& dom,
+				    index_type         sb)
+  {
+    return Map_subdomain<Dim, type>::parent_subblock(map, dom, sb);
+  }
 };
 
 
@@ -376,6 +383,17 @@
   typedef typename storage_type::type       data_type;
   typedef typename storage_type::const_type const_data_type;
 
+  par_ll_pbuf_type impl_ll_pbuf() VSIP_NOTHROW
+  { return blk_->impl_ll_pbuf(); }
+
+  long impl_offset() VSIP_NOTHROW
+  {
+    stride_type offset = blk_->impl_offset();
+    for (dimension_type d=0; d<dim; ++d)
+      offset += dom_[d].first() * blk_->impl_stride(dim, d);
+    return offset;
+  }
+
   data_type       impl_data()       VSIP_NOTHROW
   { 
     data_type ptr = blk_->impl_data();
@@ -740,6 +758,13 @@
   {
     return Map_project_1<D, Map<Dist0, Dist1, Dist2> >::project(map, i);
   }
+
+  static index_type parent_subblock(Map<Dist0, Dist1, Dist2> const& map,
+				    index_type i,
+				    index_type sb)
+  {
+    return Map_project_1<D, Map<Dist0, Dist1, Dist2> >::parent_subblock(map, i, sb);
+  }
 }; 
 
 template <dimension_type Dim,
@@ -773,6 +798,12 @@
 			  index_type idx0,
 			  index_type idx1)
     { return project_t::project(map, idx0, idx1); }
+
+  static index_type parent_subblock(Map<Dist0, Dist1, Dist2> const& map,
+				    index_type idx0,
+				    index_type idx1,
+				    index_type sb)
+    { return project_t::parent_subblock(map, idx0, idx1, sb); }
 }; 
 
 /// The Sliced_block class binds one of the indices of the underlying
@@ -851,6 +882,12 @@
   typedef typename storage_type::type       data_type;
   typedef typename storage_type::const_type const_data_type;
 
+  par_ll_pbuf_type impl_ll_pbuf() VSIP_NOTHROW
+  { return blk_->impl_ll_pbuf(); }
+
+  long impl_offset() VSIP_NOTHROW
+  { return blk_->impl_offset() + index_*blk_->impl_stride(Block::dim, D); }
+
   data_type       impl_data()       VSIP_NOTHROW
   {
     return storage_type::offset(blk_->impl_data(),
@@ -1036,6 +1073,16 @@
   typedef typename storage_type::type       data_type;
   typedef typename storage_type::const_type const_data_type;
 
+  par_ll_pbuf_type impl_ll_pbuf() VSIP_NOTHROW
+  { return blk_->impl_ll_pbuf(); }
+
+  long impl_offset() VSIP_NOTHROW
+  {
+    return + blk_->impl_offset()
+           + index1_*blk_->impl_stride(Block::dim, D1)
+           + index2_*blk_->impl_stride(Block::dim, D2);
+  }
+
   data_type       impl_data()       VSIP_NOTHROW
   {
     return storage_type::offset(blk_->impl_data(),
@@ -1243,6 +1290,7 @@
 struct Distributed_local_block<Subset_block<Block> >
 {
   typedef Subset_block<typename Distributed_local_block<Block>::type> type;
+  typedef Subset_block<typename Distributed_local_block<Block>::proxy_type> proxy_type;
 };
 
 
@@ -1252,6 +1300,7 @@
 struct Distributed_local_block<Sliced_block<Block, D> >
 {
   typedef Sliced_block<typename Distributed_local_block<Block>::type, D> type;
+  typedef Sliced_block<typename Distributed_local_block<Block>::proxy_type, D> proxy_type;
 };
 
 
@@ -1263,6 +1312,8 @@
 {
   typedef Sliced2_block<typename Distributed_local_block<Block>::type, D1, D2>
 		type;
+  typedef Sliced2_block<typename Distributed_local_block<Block>::proxy_type, D1, D2>
+		proxy_type;
 };
 
 
@@ -1272,8 +1323,8 @@
 get_local_block(
   Subset_block<Block> const& block)
 {
-  typedef typename Distributed_local_block<Block>::type local_subblock_type;
-  typedef Subset_block<local_subblock_type>             local_block_type;
+  typedef typename Distributed_local_block<Block>::type super_type;
+  typedef Subset_block<super_type>                      local_block_type;
 
   dimension_type const dim = Subset_block<Block>::dim;
 
@@ -1283,14 +1334,40 @@
     impl_local_from_global_domain(sb,
 				  block.impl_domain());
 
-  typename View_block_storage<local_subblock_type>::plain_type
-    sub_block = get_local_block(block.impl_block());
+  typename View_block_storage<super_type>::plain_type
+    super_block = get_local_block(block.impl_block());
 
-  return local_block_type(dom, sub_block);
+  return local_block_type(dom, super_block);
 }
 
 
 
+template <typename Block>
+Subset_block<typename Distributed_local_block<Block>::proxy_type>
+get_local_proxy(
+  Subset_block<Block> const& block,
+  index_type                    sb)
+{
+  static dimension_type const dim = Block::dim;
+
+  typedef typename Distributed_local_block<Block>::proxy_type super_type;
+  typedef Subset_block<super_type>                            local_proxy_type;
+
+  index_type super_sb = Subset_block_map<dim, typename Block::map_type>::
+    parent_subblock(block.impl_block().map(), block.impl_domain(), sb);
+
+  Domain<dim> l_dom = block.impl_block().map().
+    impl_local_from_global_domain(sb,
+				  block.impl_domain());
+
+  typename View_block_storage<super_type>::plain_type
+    super_block = get_local_proxy(block.impl_block(), super_sb);
+
+  return local_proxy_type(l_dom, super_block);
+}
+
+
+
 template <typename       Block,
 	  dimension_type D>
 Sliced_block<typename Distributed_local_block<Block>::type, D>
@@ -1316,6 +1393,29 @@
 
 
 template <typename       Block,
+	  dimension_type D>
+Sliced_block<typename Distributed_local_block<Block>::proxy_type, D>
+get_local_proxy(
+  Sliced_block<Block, D> const& block,
+  index_type                    sb)
+{
+  typedef typename Distributed_local_block<Block>::proxy_type super_type;
+  typedef Sliced_block<super_type, D>                         local_proxy_type;
+
+  index_type super_sb = Sliced_block_map<typename Block::map_type, D>::
+    parent_subblock(block.impl_block().map(), block.impl_index(), sb);
+
+  index_type l_idx = block.impl_block().map().
+      impl_local_from_global_index(D, block.impl_index());
+
+  typename View_block_storage<super_type>::plain_type
+    super_block = get_local_proxy(block.impl_block(), super_sb);
+  return local_proxy_type(super_block, l_idx);
+}
+
+
+
+template <typename       Block,
 	  dimension_type D1,
 	  dimension_type D2>
 Sliced2_block<typename Distributed_local_block<Block>::type, D1, D2>
@@ -1335,6 +1435,34 @@
 
 
 
+template <typename       Block,
+	  dimension_type D1,
+	  dimension_type D2>
+Sliced2_block<typename Distributed_local_block<Block>::proxy_type, D1, D2>
+get_local_proxy(
+  Sliced2_block<Block, D1, D2> const& block,
+  index_type                          sb)
+{
+  typedef typename Distributed_local_block<Block>::proxy_type super_type;
+  typedef Sliced2_block<super_type, D1, D2>                   local_block_type;
+
+  index_type l_idx1 = block.impl_block().map().
+    impl_local_from_global_index(D1, block.impl_index1());
+  index_type l_idx2 = block.impl_block().map().
+    impl_local_from_global_index(D2, block.impl_index2());
+
+  index_type super_sb = Sliced2_block_map<typename Block::map_type, D1, D2>::
+    parent_subblock(block.impl_block().map(),
+		    block.impl_index1(), block.impl_index2(), sb);
+
+  typename View_block_storage<super_type>::plain_type
+    super_block = get_local_proxy(block.impl_block(), super_sb);
+
+  return local_block_type(get_local_block(block.impl_block()), l_idx1, l_idx2);
+}
+
+
+
 template <typename Block>
 void
 assert_local(
Index: src/vsip/impl/expr_scalar_block.hpp
===================================================================
--- src/vsip/impl/expr_scalar_block.hpp	(revision 147999)
+++ src/vsip/impl/expr_scalar_block.hpp	(working copy)
@@ -159,6 +159,7 @@
 struct Distributed_local_block<Scalar_block<D, Scalar> const>
 {
   typedef Scalar_block<D, Scalar> const type;
+  typedef Scalar_block<D, Scalar> const proxy_type;
 };
 
 template <dimension_type D,
@@ -166,6 +167,7 @@
 struct Distributed_local_block<Scalar_block<D, Scalar> >
 {
   typedef Scalar_block<D, Scalar> type;
+  typedef Scalar_block<D, Scalar> proxy_type;
 };
 
 
Index: src/vsip/impl/par_assign_fwd.hpp
===================================================================
--- src/vsip/impl/par_assign_fwd.hpp	(revision 0)
+++ src/vsip/impl/par_assign_fwd.hpp	(revision 0)
@@ -0,0 +1,51 @@
+/* Copyright (c)  2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/par_assign_fwd.hpp
+    @author  Jules Bergmann
+    @date    2006-07-14
+    @brief   VSIPL++ Library: Parallel assignment class.
+
+*/
+
+#ifndef VSIP_IMPL_PAR_ASSIGN_FWD_HPP
+#define VSIP_IMPL_PAR_ASSIGN_FWD_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
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
+struct Chained_assign;
+struct Blkvec_assign;
+struct Pas_assign;
+struct Direct_pas_assign;
+
+// Parallel assignment.
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2,
+	  typename       ImplTag>
+class Par_assign;
+
+
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_IMPL_PAR_ASSIGN_FWD_HPP
Index: src/vsip/impl/global_map.hpp
===================================================================
--- src/vsip/impl/global_map.hpp	(revision 147999)
+++ src/vsip/impl/global_map.hpp	(working copy)
@@ -18,6 +18,7 @@
 #include <vsip/impl/par-services.hpp>
 #include <vsip/impl/map-traits.hpp>
 #include <vsip/impl/par-support.hpp>
+#include <vsip/impl/domain-utils.hpp>
 #include <vsip/map_fwd.hpp>
 
 
@@ -35,14 +36,26 @@
   // Compile-time typedefs.
 public:
   typedef impl::Vector_iterator<Vector<processor_type> > processor_iterator;
-  typedef impl::Communicator::pvec_type pvec_type;
+  typedef impl::Communicator::pvec_type impl_pvec_type;
 
   // Constructor.
 public:
-  Global_map() {}
+  Global_map()
+  {}
 
+  ~Global_map()
+  {}
+
   // Accessors.
 public:
+  // Information on individual distributions.
+  distribution_type distribution     (dimension_type) const VSIP_NOTHROW
+    { return whole; }
+  length_type       num_subblocks    (dimension_type) const VSIP_NOTHROW
+    { return 1; }
+  length_type       cyclic_contiguity(dimension_type) const VSIP_NOTHROW
+    { return 0; }
+
   length_type num_subblocks()  const VSIP_NOTHROW { return 1; }
   length_type num_processors() const VSIP_NOTHROW
     { return vsip::num_processors(); }
@@ -80,6 +93,10 @@
     { assert(sb == 0); return dom_; }
 
   template <dimension_type Dim2>
+  impl::Length<Dim2> impl_subblock_extent(index_type sb) const VSIP_NOTHROW
+    { assert(sb == 0); return impl::extent(dom_); }
+
+  template <dimension_type Dim2>
   Domain<Dim2> impl_global_domain(index_type sb, index_type patch)
     const VSIP_NOTHROW
     { assert(sb == 0 && patch == 0); return dom_; }
@@ -105,14 +122,19 @@
 
   // Extensions.
 public:
-  impl::Communicator& impl_comm() const { return impl::default_communicator();}
-  pvec_type           impl_pvec() const
+  impl::par_ll_pset_type impl_ll_pset() const VSIP_NOTHROW
+    { return impl::default_communicator().impl_ll_pset(); }
+  impl::Communicator&    impl_comm() const
+    { return impl::default_communicator(); }
+  impl_pvec_type         impl_pvec() const
     { return impl::default_communicator().pvec(); }
+  impl_pvec_type const&  impl_pvec_ref() const
+    { return impl::default_communicator().pvec_ref(); }
 
-  length_type        impl_working_size() const
+  length_type            impl_working_size() const
     { return this->num_processors(); }
 
-  processor_type impl_proc_from_rank(index_type idx) const
+  processor_type         impl_proc_from_rank(index_type idx) const
     { return this->impl_pvec()[idx]; }
 
   // Member data.
Index: src/vsip/support.hpp
===================================================================
--- src/vsip/support.hpp	(revision 147999)
+++ src/vsip/support.hpp	(working copy)
@@ -206,6 +206,32 @@
 template <> struct Col_major<2> { typedef col2_type type; };
 template <> struct Col_major<3> { typedef col3_type type; };
 
+
+// Define convenience trait Dim_of.  It extracts the n'th dimension
+// from a dimension ordering tuple.
+
+template <typename       OrderT,
+	  dimension_type Dim>
+struct Dim_of;
+
+template <dimension_type Dim0,
+	  dimension_type Dim1,
+	  dimension_type Dim2>
+struct Dim_of<tuple<Dim0, Dim1, Dim2>, 0>
+{ static dimension_type const value = Dim0; };
+
+template <dimension_type Dim0,
+	  dimension_type Dim1,
+	  dimension_type Dim2>
+struct Dim_of<tuple<Dim0, Dim1, Dim2>, 1>
+{ static dimension_type const value = Dim1; };
+
+template <dimension_type Dim0,
+	  dimension_type Dim1,
+	  dimension_type Dim2>
+struct Dim_of<tuple<Dim0, Dim1, Dim2>, 2>
+{ static dimension_type const value = Dim2; };
+
 } // namespace vsip::impl
 
    
@@ -217,11 +243,17 @@
 
 class Local_map;
 
+#if VSIP_IMPL_PAR_SERVICE == 2
+typedef long processor_type;
+typedef long processor_difference_type;
+#else
 typedef unsigned int processor_type;
 typedef signed int processor_difference_type;
+#endif
 
 index_type     const no_index     = static_cast<index_type>(-1);
 index_type     const no_subblock  = static_cast<index_type>(-1);
+index_type     const no_rank      = static_cast<index_type>(-1);
 processor_type const no_processor = static_cast<processor_type>(-1);
 
 
Index: src/vsip/map.hpp
===================================================================
--- src/vsip/map.hpp	(revision 147999)
+++ src/vsip/map.hpp	(working copy)
@@ -26,14 +26,21 @@
 #include <vsip/impl/dist.hpp>
 #include <vsip/impl/domain-utils.hpp>
 #include <vsip/impl/block-traits.hpp>
+#include <vsip/impl/length.hpp>
 
 #include <vsip/impl/global_map.hpp>
 #include <vsip/impl/replicated_map.hpp>
 
+#if VSIP_IMPL_PAR_SERVICE == 1
+#  include <vsip/impl/distributed-block.hpp>
+#elif VSIP_IMPL_PAR_SERVICE == 2
+#  include <vsip/impl/pas/block.hpp>
+#else
+// #  include <vsip/impl/distributed-block.hpp>
+#endif
 
 
 
-
 /***********************************************************************
   Declarations & Class Definitions
 ***********************************************************************/
@@ -54,7 +61,9 @@
 {
   index_type orig = value;
 
+  // We default to row-major because that is the natural way in C/C++.
 #if 0
+  // Column-major mapping of processors to subblocks.
   for (dimension_type i=0; i<dim; ++i)
   {
     pos[i] = value % size[i];
@@ -66,6 +75,7 @@
     (dim == 2 && pos[0] + pos[1]*size[0] == orig) ||
     (dim == 3 && pos[0] + pos[1]*size[0] + pos[2]*size[0]*size[1] == orig));
 #else
+  // Row-major mapping of processors to subblocks.
   for (dimension_type i=dim; i-->0; )
   {
     pos[i] = value % size[i];
@@ -109,7 +119,7 @@
   : public impl::Ref_count<Map_data<Dist0, Dist1, Dist2> >,
     impl::Non_copyable
 {
-  typedef std::vector<processor_type> impl_pvec_type;
+  typedef std::vector<processor_type>      impl_pvec_type;
 
   // Constructors.
 public:
@@ -122,12 +132,17 @@
     dist1_ (dist1),
     dist2_ (dist2),
     comm_  (impl::default_communicator()),
-    pvec_  (comm_.pvec()),
+    pvec_  (),
     num_subblocks_(dist0.num_subblocks() *
 		   dist1.num_subblocks() *
 		   dist2.num_subblocks()),
-    num_procs_ (pvec_.size())
+    num_procs_ (num_subblocks_)
   {
+    assert(num_subblocks_ <= comm_.pvec().size());
+
+    for (index_type i=0; i<num_subblocks_; ++i)
+      pvec_.push_back(comm_.pvec()[i]);
+
     subblocks_[0] = dist0_.num_subblocks();
     subblocks_[1] = dist1_.num_subblocks();
     subblocks_[2] = dist2_.num_subblocks();
@@ -152,9 +167,11 @@
     num_subblocks_(dist0.num_subblocks() *
 		   dist1.num_subblocks() *
 		   dist2.num_subblocks()),
-    num_procs_ (pvec.size())
+    num_procs_ (num_subblocks_)
   {
-    for (index_type i=0; i<pvec.size(); ++i)
+    assert(num_subblocks_ <= pvec.size());
+
+    for (index_type i=0; i<num_subblocks_; ++i)
       pvec_.push_back(pvec.get(i));
 
     subblocks_[0] = dist0_.num_subblocks();
@@ -162,6 +179,10 @@
     subblocks_[2] = dist2_.num_subblocks();
   }
 
+   ~Map_data()
+  {
+  }
+
   // Member data.
 public:
   Dist0               dist0_;
@@ -194,6 +215,7 @@
 
   typedef typename Map_data<Dist0, Dist1, Dist2>::impl_pvec_type
     impl_pvec_type;
+
   static bool const impl_local_only  = false;
   static bool const impl_global_only = true;
 
@@ -213,7 +235,11 @@
 
   Map& operator=(Map const&) VSIP_NOTHROW;
 
-  ~Map() VSIP_NOTHROW {}
+  ~Map() VSIP_NOTHROW
+  {
+    if (this->impl_is_applied())
+      impl::destroy_ll_pset(applied_pset_);
+  }
 
 
   // Accessors.
@@ -248,6 +274,9 @@
   Domain<Dim> impl_subblock_domain(index_type sb) const VSIP_NOTHROW;
 
   template <dimension_type Dim>
+  impl::Length<Dim> impl_subblock_extent(index_type sb) const VSIP_NOTHROW;
+
+  template <dimension_type Dim>
   Domain<Dim> impl_global_domain(index_type sb, index_type patch)
     const VSIP_NOTHROW;
 
@@ -259,7 +288,10 @@
   Domain<Dim> applied_domain () const VSIP_NOTHROW;
 
   // Implementation functions.
+  impl::par_ll_pset_type impl_ll_pset() const VSIP_NOTHROW
+    { return applied_pset_; }
   impl_pvec_type      impl_pvec() const { return data_->pvec_; }
+  impl_pvec_type const& impl_pvec_ref() const { return data_->pvec_; }
   impl::Communicator& impl_comm() const { return data_->comm_; }
   bool                impl_is_applied() const { return dim_ != 0; }
 
@@ -327,8 +359,9 @@
 private:
   impl::Ref_counted_ptr<Map_data<Dist0, Dist1, Dist2> > data_;
 
-  Domain<3>	     dom_;		  // Applied domain.
-  dimension_type     dim_;		  // Dimension of applied domain.
+  Domain<3>	         dom_;		  // Applied domain.
+  dimension_type         dim_;		  // Dimension of applied domain.
+  impl::par_ll_pset_type applied_pset_;
 
   // Base map that this map was created from (or this map if created
   // from scratch).  This is used to optimize a common case of
@@ -431,6 +464,26 @@
 
   dim_ = Dim;
   dom_ = impl::construct_domain<VSIP_MAX_DIMENSION>(arr);
+
+  impl_pvec_type const& pvec = this->impl_pvec_ref();
+  if (VSIP_IMPL_USE_PAS_SEGMENT_SIZE)
+  {
+    // Create the applied pset, which excludes processors with empty subblocks.
+    impl_pvec_type real_pvec;
+    real_pvec.reserve(pvec.size() + 1);
+
+    for (index_type i=0; i<pvec.size(); ++i)
+    {
+      processor_type pr = pvec[i];
+      index_type     sb = this->subblock(pr);
+      if (this->template impl_subblock_domain<Dim>(sb).size() > 0)
+	real_pvec.push_back(pr);
+    }
+
+    impl::create_ll_pset(real_pvec, applied_pset_);
+  }
+  else
+    impl::create_ll_pset(pvec, applied_pset_);
 }
 
 
@@ -844,7 +897,7 @@
     if (data_->pvec_[i] == pr)
       return i;
 
-  return no_processor;
+  return no_rank;
 }
 
 
@@ -866,7 +919,7 @@
 {
   index_type pi = impl_rank_from_proc(pr);
 
-  if (pi != no_processor && pi < data_->num_subblocks_)
+  if (pi != no_rank && pi < data_->num_subblocks_)
     return pi;
   else
     return no_subblock;
@@ -890,7 +943,7 @@
   processor_type pr = local_processor();
   index_type     pi = impl_rank_from_proc(pr);
 
-  if (pi != no_processor && pi < data_->num_subblocks_)
+  if (pi != no_rank && pi < data_->num_subblocks_)
     return pi;
   else
     return no_subblock;
@@ -1044,6 +1097,45 @@
 
 
 
+/// Get the size of a subblock (represented by a domain).
+
+/// Requires:
+///   SB is a valid subblock of THIS, or NO_SUBBLOCK.
+
+template <typename       Dist0,
+	  typename       Dist1,
+	  typename       Dist2>
+template <dimension_type Dim>
+inline
+impl::Length<Dim>
+Map<Dist0, Dist1, Dist2>::impl_subblock_extent(index_type sb)
+  const VSIP_NOTHROW
+{
+  assert(sb < data_->num_subblocks_ || sb == no_subblock);
+  assert(dim_ == Dim);
+
+  impl::Length<Dim> size;
+
+  if (sb == no_subblock)
+  {
+    for (dimension_type d=0; d<dim_; ++d)
+      size[d] = 0;
+  }
+  else
+  {
+    index_type dim_sb[VSIP_MAX_DIMENSION];
+
+    impl::split_tuple(sb, dim_, data_->subblocks_, dim_sb);
+
+    for (dimension_type d=0; d<dim_; ++d)
+      size[d] = impl_subblock_size(d, dim_sb[d]);
+  }
+
+  return size;
+}
+
+
+
 /// Return the global domain of a subblock's patch.
 
 /// Requires:
@@ -1382,6 +1474,21 @@
 {
   typedef Map<Dist1, Dist2> type;
 
+  // Return the parent subblock corresponding to a child subblock.
+  static index_type parent_subblock(
+    Map<Dist0, Dist1, Dist2> const& map,
+    index_type                      idx,
+    index_type                      sb)
+  {
+    // length_type num_sb_0 = map.num_subblocks(0);
+    length_type num_sb_1 = map.num_subblocks(1);
+    length_type num_sb_2 = map.num_subblocks(2);
+
+    index_type fix_sb_0 = map.impl_dim_subblock_from_index(0, idx);
+
+    return fix_sb_0*num_sb_1*num_sb_2+ sb;
+  }
+
   static type project(Map<Dist0, Dist1, Dist2> const& map, index_type idx)
   {
     // length_type num_sb_0 = map.num_subblocks(0);
@@ -1408,6 +1515,24 @@
 {
   typedef Map<Dist0, Dist2> type;
 
+  // Return the parent subblock corresponding to a child subblock.
+  static index_type parent_subblock(
+    Map<Dist0, Dist1, Dist2> const& map,
+    index_type                      idx,
+    index_type                      sb)
+  {
+    length_type num_sb_0 = map.num_subblocks(0);
+    length_type num_sb_1 = map.num_subblocks(1);
+    length_type num_sb_2 = map.num_subblocks(2);
+
+    index_type fix_sb_1 = map.impl_dim_subblock_from_index(1, idx);
+
+    index_type sb_0 = sb / num_sb_2;
+    index_type sb_2 = sb % num_sb_2;
+
+    return sb_0*num_sb_1*num_sb_2 + fix_sb_1*num_sb_2      + sb_2;
+  }
+
   static type project(Map<Dist0, Dist1, Dist2> const& map, index_type idx)
   {
     length_type num_sb_0 = map.num_subblocks(0);
@@ -1439,6 +1564,23 @@
 {
   typedef Map<Dist0, Dist1> type;
 
+  // Return the parent subblock corresponding to a child subblock.
+  static index_type parent_subblock(
+    Map<Dist0, Dist1, Dist2> const& map,
+    index_type                      idx,
+    index_type                      sb)
+  {
+    length_type num_sb_0 = map.num_subblocks(0);
+    length_type num_sb_1 = map.num_subblocks(1);
+    length_type num_sb_2 = map.num_subblocks(2);
+
+    index_type fix_sb_2 = map.impl_dim_subblock_from_index(2, idx);
+
+    index_type sb_0 = sb / num_sb_1;
+    index_type sb_1 = sb % num_sb_1;
+    return sb_0*num_sb_1*num_sb_2 + sb_1*num_sb_2          + fix_sb_2;
+  }
+
   static type project(Map<Dist0, Dist1, Dist2> const& map, index_type idx)
   {
     length_type num_sb_0 = map.num_subblocks(0);
@@ -1495,6 +1637,23 @@
 
     return type(pvec, copy_dist<Dist2>(map, 2));
   }
+
+  // Return the parent subblock corresponding to a child subblock.
+  static index_type parent_subblock(
+    Map<Dist0, Dist1, Dist2> const& map,
+    index_type                      idx0,
+    index_type                      idx1,
+    index_type                      sb)
+  {
+    // length_type num_sb_0 = map.num_subblocks(0);
+    length_type num_sb_1 = map.num_subblocks(1);
+    length_type num_sb_2 = map.num_subblocks(2);
+
+    index_type fix_sb_0 = map.impl_dim_subblock_from_index(0, idx0);
+    index_type fix_sb_1 = map.impl_dim_subblock_from_index(1, idx1);
+
+    return fix_sb_0*num_sb_1*num_sb_2 + fix_sb_1*num_sb_2 + sb;
+  }
 };
 
 template <typename       Dist0,
@@ -1524,6 +1683,23 @@
 
     return type(pvec, copy_dist<Dist1>(map, 1));
   }
+
+  // Return the parent subblock corresponding to a child subblock.
+  static index_type parent_subblock(
+    Map<Dist0, Dist1, Dist2> const& map,
+    index_type                      idx0,
+    index_type                      idx2,
+    index_type                      sb)
+  {
+    // length_type num_sb_0 = map.num_subblocks(0);
+    length_type num_sb_1 = map.num_subblocks(1);
+    length_type num_sb_2 = map.num_subblocks(2);
+
+    index_type fix_sb_0 = map.impl_dim_subblock_from_index(0, idx0);
+    index_type fix_sb_2 = map.impl_dim_subblock_from_index(2, idx2);
+
+    return fix_sb_0*num_sb_1*num_sb_2 + sb*num_sb_2 + fix_sb_2;
+  }
 };
 
 template <typename       Dist0,
@@ -1553,6 +1729,23 @@
 
     return type(pvec, copy_dist<Dist0>(map, 0));
   }
+
+  // Return the parent subblock corresponding to a child subblock.
+  static index_type parent_subblock(
+    Map<Dist0, Dist1, Dist2> const& map,
+    index_type                      idx1,
+    index_type                      idx2,
+    index_type                      sb)
+  {
+    length_type num_sb_0 = map.num_subblocks(0);
+    length_type num_sb_1 = map.num_subblocks(1);
+    length_type num_sb_2 = map.num_subblocks(2);
+
+    index_type fix_sb_1 = map.impl_dim_subblock_from_index(1, idx1);
+    index_type fix_sb_2 = map.impl_dim_subblock_from_index(2, idx2);
+
+    return sb*num_sb_1*num_sb_2 + fix_sb_1*num_sb_2 + fix_sb_2;
+  }
 };
 
 
@@ -1584,9 +1777,11 @@
 	// If this dimension is distributed, then subdomain must be full
 	if (dom[d].first() != 0 || dom[d].stride() != 1 ||
 	    dom[d].size() != map.template applied_domain<Dim>()[d].size())
+	{
 	  VSIP_IMPL_THROW(
 	    impl::unimplemented(
 	      "Map_subdomain: Subviews must not break up distributed dimensions"));
+	}
       }
     }
 
@@ -1600,6 +1795,15 @@
 		copy_dist<Dist1>(map, 1),
 		copy_dist<Dist2>(map, 2));
   }
+
+  // Return the parent subblock corresponding to a child subblock.
+  static index_type parent_subblock(
+    Map<Dist0, Dist1, Dist2> const& map,
+    Domain<Dim> const&              /*dom*/,
+    index_type                      sb)
+  {
+    return sb;
+  }
 };
 
 
Index: src/vsip/random.hpp
===================================================================
--- src/vsip/random.hpp	(revision 147999)
+++ src/vsip/random.hpp	(working copy)
@@ -21,6 +21,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/impl/global_map.hpp>
+#include <vsip/map.hpp>
 
 
 
Index: src/vsip_csl/test.hpp
===================================================================
--- src/vsip_csl/test.hpp	(revision 147999)
+++ src/vsip_csl/test.hpp	(working copy)
@@ -40,7 +40,27 @@
 #  define VSIP_IMPL_TEST_LEVEL 1
 #endif
 
+// Run tests for double precision
+#ifndef VSIP_IMPL_TEST_DOUBLE
+  // PAS doesn't support double
+#  if VSIP_IMPL_PAR_SERVICE == 2
+#    define VSIP_IMPL_TEST_DOUBLE 0
+#  else
+#    define VSIP_IMPL_TEST_DOUBLE 1
+#  endif
+#endif
 
+// Run tests for long-double precision
+#ifndef VSIP_IMPL_TEST_LONG_DOUBLE
+// PAS doesn't support long-double
+#  if VSIP_IMPL_PAR_SERVICE == 2
+#    define VSIP_IMPL_TEST_LONG_DOUBLE 0
+#  else
+#    define VSIP_IMPL_TEST_LONG_DOUBLE 1
+#  endif
+#endif
+
+
 /// Compare two floating-point values for equality.
 ///
 /// Algorithm from:
Index: tests/reductions-idx.cpp
===================================================================
--- tests/reductions-idx.cpp	(revision 147999)
+++ tests/reductions-idx.cpp	(working copy)
@@ -320,19 +320,22 @@
 
    cover_maxval<int>();
    cover_maxval<float>();
-   cover_maxval<double>();
 
    cover_minval<int>();
    cover_minval<float>();
-   cover_minval<double>();
 
    // cover_maxmgval<complex<int> >();
    cover_mgval<complex<float> >();
-   cover_mgval<complex<double> >();
 
    // cover_maxmgsqval<complex<int> >();
    cover_mgsqval<complex<float> >();
-   cover_mgsqval<complex<double> >();
 
    simple_mgval_c<float>();
+
+#if VSIP_IMPL_TEST_DOUBLE
+   cover_maxval<double>();
+   cover_minval<double>();
+   cover_mgval<complex<double> >();
+   cover_mgsqval<complex<double> >();
+#endif
 }
Index: tests/histogram.cpp
===================================================================
--- tests/histogram.cpp	(revision 147999)
+++ tests/histogram.cpp	(working copy)
@@ -28,8 +28,8 @@
 void
 test_vector_histogram( length_type size )
 {
-  Vector<double> tmp(size);
-  Rand<double> rgen(0);
+  Vector<float> tmp(size);
+  Rand<float> rgen(0);
   tmp = rgen.randu(size) * 8;
 
   Vector<T> v(size);
@@ -87,8 +87,8 @@
 void
 test_matrix_histogram( length_type rows, length_type cols )
 {
-  Matrix<double> tmp(rows, cols);
-  Rand<double> rgen(0);
+  Matrix<float> tmp(rows, cols);
+  Rand<float> rgen(0);
   tmp = rgen.randu(rows, cols) * 8.0;
 
   Matrix<T> m(rows, cols);
@@ -163,10 +163,15 @@
   vsipl init(argc, argv);
 
   cases_by_type<float>();
-  cases_by_type<double>();
-  cases_by_type<long double>();
   cases_by_type<int>();
   cases_by_type<long>();
 
+#if VSIP_IMPL_TEST_DOUBLE
+  cases_by_type<double>();
+#endif
+#if VSIP_IMPL_TEST_LONG_DOUBLE
+  cases_by_type<long double>();
+#endif
+
   return EXIT_SUCCESS;
 }
Index: tests/solver-toepsol.cpp
===================================================================
--- tests/solver-toepsol.cpp	(revision 147999)
+++ tests/solver-toepsol.cpp	(working copy)
@@ -272,14 +272,17 @@
 toepsol_cases(return_mechanism_type rtm)
 {
   test_toepsol_diag<float>           (rtm, 1.0, 5);
-  test_toepsol_diag<double>          (rtm, 2.0, 5);
   test_toepsol_diag<complex<float> > (rtm, complex<float>(2.0, 0.0), 5);
-  test_toepsol_diag<complex<double> >(rtm, complex<double>(3.0, 0.0), 5);
 
   test_toepsol_rand<float>           (rtm, 4, 5);
+  test_toepsol_rand<complex<float> > (rtm, 6, 5);
+
+#if VSIP_IMPL_TEST_DOUBLE
+  test_toepsol_diag<double>          (rtm, 2.0, 5);
+  test_toepsol_diag<complex<double> >(rtm, complex<double>(3.0, 0.0), 5);
   test_toepsol_rand<double>          (rtm, 5, 5);
-  test_toepsol_rand<complex<float> > (rtm, 6, 5);
   test_toepsol_rand<complex<double> >(rtm, 7, 5);
+#endif
 
 #if VSIP_HAS_EXCEPTIONS
   test_toepsol_illformed<float>      (rtm, 4);
Index: tests/domain.cpp
===================================================================
--- tests/domain.cpp	(revision 147999)
+++ tests/domain.cpp	(working copy)
@@ -14,6 +14,7 @@
 ***********************************************************************/
 
 #include <iostream>
+#include <vsip/initfin.hpp>
 #include <vsip/domain.hpp>
 
 #include <vsip_csl/test.hpp>
@@ -166,8 +167,10 @@
 }
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsipl init(argc, argv);
+
   test_domain_1();
   test_domain_2();
   test_domain_3();
Index: tests/freqswap.cpp
===================================================================
--- tests/freqswap.cpp	(revision 147999)
+++ tests/freqswap.cpp	(working copy)
@@ -83,8 +83,12 @@
   vsipl init(argc, argv);
 
   cases_by_type<float>();
+#if VSIP_IMPL_TEST_DOUBLE
   cases_by_type<double>();
+#endif // VSIP_IMPL_TEST_DOUBLE
+#if VSIP_IMPL_TEST_LONG_DOUBLE
   cases_by_type<long double>();
+#endif // VSIP_IMPL_TEST_LONG_DOUBLE
 
   return EXIT_SUCCESS;
 }
Index: tests/segment_size.cpp
===================================================================
--- tests/segment_size.cpp	(revision 0)
+++ tests/segment_size.cpp	(revision 0)
@@ -0,0 +1,131 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/segment_size.cpp
+    @author  Jules Bergmann
+    @date    2006-08-24
+    @brief   VSIPL++ Library: Test segment_size() for Block distributions.
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
+#include <vsip/map.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Test segment_size with PAS algorithm
+
+void
+test_pas()
+{
+  using vsip::impl::segment_size;
+
+  test_assert(segment_size(1, 4, 0) == 1);
+  test_assert(segment_size(1, 4, 1) == 0);
+  test_assert(segment_size(1, 4, 2) == 0);
+  test_assert(segment_size(1, 4, 3) == 0);
+
+  test_assert(segment_size(2, 4, 0) == 1);
+  test_assert(segment_size(2, 4, 1) == 1);
+  test_assert(segment_size(2, 4, 2) == 0);
+  test_assert(segment_size(2, 4, 3) == 0);
+
+  test_assert(segment_size(3, 4, 0) == 1);
+  test_assert(segment_size(3, 4, 1) == 1);
+  test_assert(segment_size(3, 4, 2) == 1);
+  test_assert(segment_size(3, 4, 3) == 0);
+
+  test_assert(segment_size(4, 3, 0) == 2);
+  test_assert(segment_size(4, 3, 1) == 2);
+  test_assert(segment_size(4, 3, 2) == 0);
+
+  test_assert(segment_size(4, 4, 0) == 1);
+  test_assert(segment_size(4, 4, 1) == 1);
+  test_assert(segment_size(4, 4, 2) == 1);
+  test_assert(segment_size(4, 4, 3) == 1);
+
+  test_assert(segment_size(5, 4, 0) == 2);
+  test_assert(segment_size(5, 4, 1) == 2);
+  test_assert(segment_size(5, 4, 2) == 1);
+  test_assert(segment_size(5, 4, 3) == 0);
+
+  test_assert(segment_size(16, 5, 0) == 4);
+  test_assert(segment_size(16, 5, 1) == 4);
+  test_assert(segment_size(16, 5, 2) == 4);
+  test_assert(segment_size(16, 5, 3) == 4);
+  test_assert(segment_size(16, 5, 4) == 0);
+}
+
+
+
+// Test segment_size with normal algorithm
+
+void
+test_normal()
+{
+  using vsip::impl::segment_size;
+
+  test_assert(segment_size(1, 4, 0) == 1);
+  test_assert(segment_size(1, 4, 1) == 0);
+  test_assert(segment_size(1, 4, 2) == 0);
+  test_assert(segment_size(1, 4, 3) == 0);
+
+  test_assert(segment_size(2, 4, 0) == 1);
+  test_assert(segment_size(2, 4, 1) == 1);
+  test_assert(segment_size(2, 4, 2) == 0);
+  test_assert(segment_size(2, 4, 3) == 0);
+
+  test_assert(segment_size(3, 4, 0) == 1);
+  test_assert(segment_size(3, 4, 1) == 1);
+  test_assert(segment_size(3, 4, 2) == 1);
+  test_assert(segment_size(3, 4, 3) == 0);
+
+  test_assert(segment_size(4, 3, 0) == 2);
+  test_assert(segment_size(4, 3, 1) == 1);
+  test_assert(segment_size(4, 3, 2) == 1);
+
+  test_assert(segment_size(4, 4, 0) == 1);
+  test_assert(segment_size(4, 4, 1) == 1);
+  test_assert(segment_size(4, 4, 2) == 1);
+  test_assert(segment_size(4, 4, 3) == 1);
+
+  test_assert(segment_size(5, 4, 0) == 2);
+  test_assert(segment_size(5, 4, 1) == 1);
+  test_assert(segment_size(5, 4, 2) == 1);
+  test_assert(segment_size(5, 4, 3) == 1);
+
+  test_assert(segment_size(16, 5, 0) == 4);
+  test_assert(segment_size(16, 5, 1) == 3);
+  test_assert(segment_size(16, 5, 2) == 3);
+  test_assert(segment_size(16, 5, 3) == 3);
+  test_assert(segment_size(16, 5, 4) == 3);
+}
+
+
+
+int
+main(int argc, char **argv)
+{
+  vsipl init(argc, argv);
+
+#if VSIP_IMPL_USE_PAS_SEGMENT_SIZE
+  test_pas();
+#else
+  test_normal();
+#endif
+}
Index: tests/dense.cpp
===================================================================
--- tests/dense.cpp	(revision 147999)
+++ tests/dense.cpp	(working copy)
@@ -12,6 +12,7 @@
 
 #include <iostream>
 
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/dense.hpp>
 
@@ -290,8 +291,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsipl init(argc, argv);
   test_stack_dense<1, int>            (Domain<1>(10));
   test_stack_dense<1, float>          (Domain<1>(10));
   test_stack_dense<1, complex<float> >(Domain<1>(10));
Index: tests/conv-2d.cpp
===================================================================
--- tests/conv-2d.cpp	(revision 147999)
+++ tests/conv-2d.cpp	(working copy)
@@ -529,14 +529,19 @@
   cases<short>(rand);
   cases<int>(rand);
   cases<float>(rand);
-  cases<double>(rand);
   // cases<complex<int> >(rand);
   cases<complex<float> >(rand);
-  // cases<complex<double> >(rand);
 
   cases_nonsym<complex<int> >(8, 8, 3, 3);
   cases_nonsym<complex<float> >(8, 8, 3, 3);
+
+#  if VSIP_IMPL_TEST_DOUBLE
+  cases<double>(rand);
+  // cases<complex<double> >(rand);
+
   cases_nonsym<complex<double> >(8, 8, 3, 3);
+#  endif // VSIP_IMPL_TEST_DOUBLE
+
 #endif
 
 #if 0
Index: tests/corr-2d.cpp
===================================================================
--- tests/corr-2d.cpp	(revision 147999)
+++ tests/corr-2d.cpp	(working copy)
@@ -174,6 +174,8 @@
   // Test user-visible correlation
   corr_cover<float>();
   corr_cover<complex<float> >();
+#if VSIP_IMPL_TEST_DOUBLE
   corr_cover<double>();
   corr_cover<complex<double> >();
+#endif // VSIP_IMPL_TEST_DOUBLE
 }
Index: tests/correlation.cpp
===================================================================
--- tests/correlation.cpp	(revision 147999)
+++ tests/correlation.cpp	(working copy)
@@ -282,18 +282,26 @@
   // Test user-visible correlation
   corr_cover<float>();
   corr_cover<complex<float> >();
+
+  // Test optimized implementation
+  impl_corr_cover<impl::Opt_tag, float>();
+  impl_corr_cover<impl::Opt_tag, complex<float> >();
+
+  // Test generic implementation
+  impl_corr_cover<impl::Generic_tag, float>();
+  impl_corr_cover<impl::Generic_tag, complex<float> >();
+
+#if VSIP_IMPL_TEST_DOUBLE
+  // Test user-visible correlation
   corr_cover<double>();
   corr_cover<complex<double> >();
 
   // Test optimized implementation
-  impl_corr_cover<impl::Opt_tag, float>();
-  impl_corr_cover<impl::Opt_tag, complex<float> >();
   impl_corr_cover<impl::Opt_tag, double>();
   impl_corr_cover<impl::Opt_tag, complex<double> >();
 
   // Test generic implementation
-  impl_corr_cover<impl::Generic_tag, float>();
-  impl_corr_cover<impl::Generic_tag, complex<float> >();
   impl_corr_cover<impl::Generic_tag, double>();
   impl_corr_cover<impl::Generic_tag, complex<double> >();
+#endif // VSIP_IMPL_TEST_DOUBLE
 }
Index: tests/parallel/expr.cpp
===================================================================
--- tests/parallel/expr.cpp	(revision 147999)
+++ tests/parallel/expr.cpp	(working copy)
@@ -162,7 +162,7 @@
   view_op1_t A(create_view<view_op1_t>(dom, T(3), map_op1));
   view_op2_t B(create_view<view_op2_t>(dom, T(4), map_op2));
 
-  impl::Communicator comm = impl::default_communicator();
+  impl::Communicator& comm = impl::default_communicator();
 
   // cout << "(" << local_processor() << "): test_distributed_view\n";
 
@@ -195,7 +195,13 @@
   // Check results.
   comm.barrier();
 
+  Check_identity<Dim> checkerA(dom, 2, 1);
+  Check_identity<Dim> checkerB(dom, 3, 2);
+  foreach_point(A, checkerA);
+  foreach_point(B, checkerB);
+
   Check_identity<Dim> checker1(dom, 5, 3);
+  foreach_point(Z1, checker1);
   foreach_point(chk1, checker1);
   test_assert(checker1.good());
 
@@ -304,7 +310,7 @@
   view_op2_t B (create_view<view_op2_t>(dom, T(4), map_op2));
   view_op3_t C (create_view<view_op3_t>(dom, T(5), map_op3));
 
-  impl::Communicator comm = impl::default_communicator();
+  impl::Communicator& comm = impl::default_communicator();
 
   foreach_point(A, Set_identity<Dim>(dom, 2, 1));
   foreach_point(B, Set_identity<Dim>(dom, 3, 2));
@@ -417,7 +423,7 @@
   view_op2_t B(create_view<view_op2_t>(dom, T(4), map_op2));
   view_op3_t C(create_view<view_op3_t>(dom, T(5), map_op3));
 
-  impl::Communicator comm = impl::default_communicator();
+  impl::Communicator& comm = impl::default_communicator();
 
   foreach_point(A, Set_identity<Dim>(dom, 2, 1));
   foreach_point(B, Set_identity<Dim>(dom, 3, 2));
@@ -489,86 +495,88 @@
 {
   processor_type np = num_processors();
 
-  Map<Block_dist> map1(Block_dist(1));
-  Map<Block_dist> map2(Block_dist(2 <= np ? 2 : np));
-  Map<Block_dist> map3(Block_dist(4 <= np ? 4 : np));
-  Map<Cyclic_dist> map4(Cyclic_dist(np,1));
-  Map<Cyclic_dist> map5(Cyclic_dist(np,2));
-  Map<Cyclic_dist> map6(Cyclic_dist(np,3));
-  Map<Block_dist> map7 = Map<Block_dist>(Block_dist(np));
+  Map<Block_dist>  map_1(Block_dist(1));
+  Map<Block_dist>  map_2(Block_dist(2 <= np ? 2 : np));
+  Map<Block_dist>  map_4(Block_dist(4 <= np ? 4 : np));
+  Map<Block_dist>  map_np = Map<Block_dist>(Block_dist(np));
 
-
   test_distributed_expr<T>(
     Domain<1>(16),
-    map1, map1, map1,
+    map_1, map_1, map_1,
     loop);
 
   test_distributed_expr<T>(
     Domain<1>(16),
-    map7, map7, map7,
+    map_np, map_np, map_np,
     loop);
 
   test_distributed_expr<T>(
     Domain<1>(16),
-    map1, map1, map2,
+    map_1, map_1, map_2,
     loop);
 
   test_distributed_expr<T>(
     Domain<1>(16),
-    map3, map3, map3,
+    map_4, map_4, map_4,
     loop);
 
-  test_distributed_expr<T>(
+  test_distributed_expr3<T>(
     Domain<1>(16),
-    map3, map2, map4,
+    map_1,
+    map_1,
+    map_1,
+    map_1,
     loop);
 
-  test_distributed_expr<T>(
+  test_distributed_expr3_capture<T>(
     Domain<1>(16),
-    map4, map5, map6,
+    map_1,
+    map_1,
+    map_1,
+    map_1,
     loop);
 
-  test_distributed_expr3<T>(
+#if VSIP_DIST_LEVEL >= 3
+  Map<Cyclic_dist> map_c1(Cyclic_dist(np,1));
+  Map<Cyclic_dist> map_c2(Cyclic_dist(np,2));
+  Map<Cyclic_dist> map_c3(Cyclic_dist(np,3));
+
+  test_distributed_expr<T>(
     Domain<1>(16),
-    map2, map4, map5, map6,
+    map_4, map_2, map_c1,
     loop);
 
-  test_distributed_expr3<T>(
+  test_distributed_expr<T>(
     Domain<1>(16),
-    map1,
-    map1,
-    map1,
-    map1,
+    map_c1, map_c2, map_c3,
     loop);
 
   test_distributed_expr3<T>(
     Domain<1>(16),
-    map3,
-    map2,
-    map1,
-    map4,
+    map_2, map_c1, map_c2, map_c3,
     loop);
 
-  test_distributed_expr3_capture<T>(
+  test_distributed_expr3<T>(
     Domain<1>(16),
-    map2, map4, map5, map6,
+    map_4,
+    map_2,
+    map_1,
+    map_c1,
     loop);
 
   test_distributed_expr3_capture<T>(
     Domain<1>(16),
-    map1,
-    map1,
-    map1,
-    map1,
+    map_2, map_c1, map_c2, map_c3,
     loop);
 
   test_distributed_expr3_capture<T>(
     Domain<1>(16),
-    map3,
-    map2,
-    map1,
-    map4,
+    map_4,
+    map_2,
+    map_1,
+    map_c1,
     loop);
+#endif // VSIP_DIST_LEVEL >= 3
 }
 
 
@@ -581,17 +589,16 @@
   length_type nr = (processor_type)floor(sqrt((double)np));
   length_type nc = (processor_type)floor((double)np/nr);
 
-  Map<Block_dist, Block_dist> map1(Block_dist(1), Block_dist(1));
+  Map<Block_dist, Block_dist> map_1(Block_dist(1), Block_dist(1));
   Map<Block_dist, Block_dist> map_r(Block_dist(np), Block_dist(1));
   Map<Block_dist, Block_dist> map_c(Block_dist(1),  Block_dist(np));
   // Map<Block_dist, Block_dist> map_x(Block_dist(nr), Block_dist(nc));
   Map<Block_dist, Block_dist> map_x = Map<>(Block_dist(nr), Block_dist(nc));
 
-  Map<Cyclic_dist, Cyclic_dist> map_se(Cyclic_dist(nr, 1), Cyclic_dist(nc, 1));
 
   test_distributed_expr<T>(
     Domain<2>(16, 16),
-    map1, map1, map1,
+    map_1, map_1, map_1,
     loop);
 
   test_distributed_expr<T>(
@@ -604,10 +611,14 @@
     map_x, map_r, map_c,
     loop);
 
+#if VSIP_DIST_LEVEL >= 3
+  Map<Cyclic_dist, Cyclic_dist> map_se(Cyclic_dist(nr, 1), Cyclic_dist(nc, 1));
+
   test_distributed_expr<T>(
     Domain<2>(16, 16),
     map_x, map_se, map_c,
     loop);
+#endif // VSIP_DIST_LEVEL >= 3
 }
 
 
@@ -621,7 +632,7 @@
 
 #if 0
   // Enable this section for easier debugging.
-  impl::Communicator comm = impl::default_communicator();
+  impl::Communicator& comm = impl::default_communicator();
   pid_t pid = getpid();
 
   cout << "rank: "   << comm.rank()
Index: tests/parallel/user-storage.cpp
===================================================================
--- tests/parallel/user-storage.cpp	(revision 147999)
+++ tests/parallel/user-storage.cpp	(working copy)
@@ -190,8 +190,10 @@
   processor_type np = num_processors();
 
   Map<Block_dist>  map1 = Map<Block_dist>(Block_dist(np));
+  test1<float>(Domain<1>(10), map1, false);
+
+#if VSIP_DIST_LEVEL >= 3
   Map<Cyclic_dist> map2 = Map<Cyclic_dist>(Cyclic_dist(np));
-
-  test1<float>(Domain<1>(10), map1, false);
   test1<float>(Domain<1>(10), map2, false);
+#endif
 }
Index: tests/parallel/subviews.cpp
===================================================================
--- tests/parallel/subviews.cpp	(revision 147999)
+++ tests/parallel/subviews.cpp	(working copy)
@@ -58,7 +58,7 @@
 
   typedef Vector<T, Dense<1, T, row1_type, Global_map<1> > > global_view1_t;
 
-  impl::Communicator comm = impl::default_communicator();
+  impl::Communicator& comm = impl::default_communicator();
 
   length_type sum_size = dom[1].size();
 
@@ -171,7 +171,7 @@
 
   typedef Vector<T, Dense<1, T, row1_type, Global_map<1> > > global_view1_t;
 
-  impl::Communicator comm = impl::default_communicator();
+  impl::Communicator& comm = impl::default_communicator();
 
   length_type sum_size = dom[0].size();
 
@@ -331,7 +331,7 @@
 
   V_slice<Slice> slice;
 
-  impl::Communicator comm = impl::default_communicator();
+  impl::Communicator& comm = impl::default_communicator();
 
   length_type sum_size = slice.sum_size(dom);
 
@@ -515,7 +515,7 @@
 
   M_slice<Slice> slice;
 
-  impl::Communicator comm = impl::default_communicator();
+  impl::Communicator& comm = impl::default_communicator();
 
   length_type sum_rows = slice.sum_rows(dom);
   length_type sum_cols = slice.sum_cols(dom);
@@ -651,7 +651,7 @@
 
 #if 0
   // Enable this section for easier debugging.
-  impl::Communicator comm = impl::default_communicator();
+  impl::Communicator& comm = impl::default_communicator();
   pid_t pid = getpid();
 
   cout << "rank: "   << comm.rank()
@@ -671,7 +671,6 @@
   if (do_all || do_mrow)
     cases_row_sum<float>(Domain<2>(4, 15));
 
-#if 1
   if (do_all || do_mcol)
     cases_col_sum<float>(Domain<2>(15, 4));
 
@@ -679,6 +678,7 @@
   {
     // small cases
     cases_tensor_m_sum<float, 0>(Domain<3>(4, 6, 8));
+#if VSIP_IMPL_TEST_LEVEL >= 2
     cases_tensor_m_sum<float, 0>(Domain<3>(6, 4, 8));
     cases_tensor_m_sum<float, 0>(Domain<3>(8, 6, 4));
     cases_tensor_m_sum<float, 1>(Domain<3>(4, 6, 8));
@@ -687,19 +687,21 @@
     cases_tensor_m_sum<float, 2>(Domain<3>(4, 6, 8));
     cases_tensor_m_sum<float, 2>(Domain<3>(6, 4, 8));
     cases_tensor_m_sum<float, 2>(Domain<3>(8, 6, 4));
+#endif // VSIP_IMPL_TEST_LEVEL >= 2
   }
 
   if (do_all || do_tvec)
   {
     cases_tensor_v_sum<float, 0>(Domain<3>(4, 6, 8));
+#if VSIP_IMPL_TEST_LEVEL >= 2
     cases_tensor_v_sum<float, 1>(Domain<3>(4, 6, 8));
     cases_tensor_v_sum<float, 2>(Domain<3>(4, 6, 8));
 
     cases_tensor_v_sum<float, 0>(Domain<3>(32, 16, 64));
     cases_tensor_v_sum<float, 1>(Domain<3>(32, 16, 64));
     cases_tensor_v_sum<float, 2>(Domain<3>(32, 16, 64));
+#endif // VSIP_IMPL_TEST_LEVEL >= 2
   }
-#endif
 
   return 0;
 }
Index: tests/parallel/block.cpp
===================================================================
--- tests/parallel/block.cpp	(revision 147999)
+++ tests/parallel/block.cpp	(working copy)
@@ -31,6 +31,8 @@
 #include "util.hpp"
 #include "util-par.hpp"
 
+#define IMPL_TAG impl::par_assign_impl_type
+
 using namespace std;
 using namespace vsip;
 using namespace vsip_csl;
@@ -92,7 +94,7 @@
 
 
 
-// Test a distributed view.
+// Test a distributed view w/explicit parallel assign.
 
 // Requires:
 //   DOM is the extent of the distributed view (1 or 2 dimensional),
@@ -112,209 +114,244 @@
 //    data back onto processor 0.
 //  - Check data in view0.
 
+struct TestImplicit;
+template <typename ParAssignTag> struct TestExplicit;
+
+template <typename       TestImplTag,
+	  typename       T,
+	  dimension_type Dim,
+	  typename       Map1,
+	  typename       Map2>
+struct Test_distributed_view;
+
 template <typename       ParAssignTag,
 	  typename       T,
 	  dimension_type Dim,
 	  typename       Map1,
 	  typename       Map2>
-void
-test_distributed_view(
-  Domain<Dim> dom,
-  Map1        map1,
-  Map2        map2,
-  int         loop)
+struct Test_distributed_view<TestExplicit<ParAssignTag>,
+			     T, Dim, Map1, Map2>
 {
-  typedef Map<Block_dist, Block_dist> map0_t;
+  static void
+  exec(
+    Domain<Dim> dom,
+    Map1        map1,
+    Map2        map2,
+    int         loop)
+  {
+    typedef Map<Block_dist, Block_dist> map0_t;
+    
+    typedef typename impl::Row_major<Dim>::type order_type;
+  
+    typedef Dense<Dim, T, order_type, map0_t> dist_block0_t;
+    typedef Dense<Dim, T, order_type, Map1>   dist_block1_t;
+    typedef Dense<Dim, T, order_type, Map2>   dist_block2_t;
 
-  typedef typename impl::Row_major<Dim>::type order_type;
+    typedef typename View_of_dim<Dim, T, dist_block0_t>::type view0_t;
+    typedef typename View_of_dim<Dim, T, dist_block1_t>::type view1_t;
+    typedef typename View_of_dim<Dim, T, dist_block2_t>::type view2_t;
 
-  typedef Dense<Dim, T, order_type, map0_t> dist_block0_t;
-  typedef Dense<Dim, T, order_type, Map1>   dist_block1_t;
-  typedef Dense<Dim, T, order_type, Map2>   dist_block2_t;
+    // map0 is not distributed (effectively).
+    map0_t  map0(Block_dist(1), Block_dist(1));
 
-  typedef typename View_of_dim<Dim, T, dist_block0_t>::type view0_t;
-  typedef typename View_of_dim<Dim, T, dist_block1_t>::type view1_t;
-  typedef typename View_of_dim<Dim, T, dist_block2_t>::type view2_t;
+    view0_t view0(create_view<view0_t>(dom, T(), map0));
+    view1_t view1(create_view<view1_t>(dom, map1));
+    view2_t view2(create_view<view2_t>(dom, map2));
 
-  // map0 is not distributed (effectively).
-  map0_t  map0(Block_dist(1), Block_dist(1));
+    check_local_view<Dim>(view0);
+    check_local_view<Dim>(view1);
+    check_local_view<Dim>(view2);
 
-  view0_t view0(create_view<view0_t>(dom, T(), map0));
-  view1_t view1(create_view<view1_t>(dom, map1));
-  view2_t view2(create_view<view2_t>(dom, map2));
+    impl::Communicator& comm = impl::default_communicator();
 
-  check_local_view<Dim>(view0);
-  check_local_view<Dim>(view1);
-  check_local_view<Dim>(view2);
-
-  impl::Communicator comm = impl::default_communicator();
-
-  // Declare assignments, allows early binding to be done.
-  impl::Par_assign<Dim, T, T, dist_block1_t, dist_block0_t, ParAssignTag>
+    // Declare assignments, allows early binding to be done.
+    impl::Par_assign<Dim, T, T, dist_block1_t, dist_block0_t, ParAssignTag>
 		a1(view1, view0);
-  impl::Par_assign<Dim, T, T, dist_block2_t, dist_block1_t, ParAssignTag>
+    impl::Par_assign<Dim, T, T, dist_block2_t, dist_block1_t, ParAssignTag>
 		a2(view2, view1);
-  impl::Par_assign<Dim, T, T, dist_block0_t, dist_block2_t, ParAssignTag>
+    impl::Par_assign<Dim, T, T, dist_block0_t, dist_block2_t, ParAssignTag>
 		a3(view0, view2);
 
-  // cout << "(" << local_processor() << "): test_distributed_view\n";
+    for (int l=0; l<loop; ++l)
+    {
+      foreach_point(view0, Set_identity<Dim>(dom));
 
-  for (int l=0; l<loop; ++l)
-  {
-    foreach_point(view0, Set_identity<Dim>(dom));
+      a1(); // view1 = view0;
 
-    a1(); // view1 = view0;
+      foreach_point(view1, Increment<Dim, T>(T(100)));
 
-    foreach_point(view1, Increment<Dim, T>(T(100)));
-
-    a2(); // view2 = view1;
+      a2(); // view2 = view1;
     
-    foreach_point(view2, Increment<Dim, T>(T(1000)));
+      foreach_point(view2, Increment<Dim, T>(T(1000)));
     
-    a3(); // view0 = view2;
-  }
+      a3(); // view0 = view2;
+    }
 
-  // Check results.
-  comm.barrier();
+    // Check results.
+    comm.barrier();
 
-  typename view0_t::local_type local_view = view0.local();
+    typename view0_t::local_type local_view = view0.local();
 
-  if (local_processor() == 0) 
-  {
-    // On processor 0, local_view should be entire view.
-    test_assert(extent(local_view) == extent(dom));
+    if (local_processor() == 0) 
+    {
+      // On processor 0, local_view should be entire view.
+      test_assert(extent(local_view) == extent(dom));
 
-    // Check that each value is correct.
-    bool good = true;
-    Length<Dim> ext = extent(local_view);
-    for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
-    {
-      T expected_value = T();
-      for (dimension_type d=0; d<Dim; ++d)
+      // Check that each value is correct.
+      bool good = true;
+      Length<Dim> ext = extent(local_view);
+      for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
       {
-	expected_value *= local_view.size(d);
-	expected_value += idx[d];
+	T expected_value = T();
+	for (dimension_type d=0; d<Dim; ++d)
+	{
+	  expected_value *= local_view.size(d);
+	  expected_value += idx[d];
+	}
+	expected_value += T(1100);
+
+	if (get(local_view, idx) != expected_value)
+	{
+	  cout << "FAIL: index: " << idx
+	       << "  expected " << expected_value
+	       << "  got "      << get(local_view, idx)
+	       << endl;
+	  good = false;
+	}
       }
-      expected_value += T(1100);
 
-      if (get(local_view, idx) != expected_value)
-      {
-	cout << "FAIL: index: " << idx
-	     << "  expected " << expected_value
-	     << "  got "      << get(local_view, idx)
-	     << endl;
-	good = false;
-      }
+      // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
+      test_assert(good);
     }
-
-    // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
-    test_assert(good);
+    else
+    {
+      // Otherwise, local_view should be empty:
+      test_assert(local_view.size() == 0);
+    }
   }
-  else
-  {
-    // Otherwise, local_view should be empty:
-    test_assert(local_view.size() == 0);
-  }
-}
+};
 
 
 
-// Version using normal assignment operator.
+// Test a distributed view w/implicit parallel assign through assignment op.
 
-template <typename                  T,
-	  dimension_type            Dim,
-	  typename                  Map1,
-	  typename                  Map2>
-void
-test_distributed_view_assign(
-  Domain<Dim> dom,
-  Map1        map1,
-  Map2        map2,
-  int         loop)
-
+template <typename       T,
+	  dimension_type Dim,
+	  typename       Map1,
+	  typename       Map2>
+struct Test_distributed_view<TestImplicit, T, Dim, Map1, Map2>
 {
-  typedef Map<Block_dist, Block_dist> map0_t;
-
-  typedef typename impl::Row_major<Dim>::type order_type;
-
-  typedef Dense<Dim, T, order_type, map0_t> dist_block0_t;
-  typedef Dense<Dim, T, order_type, Map1>   dist_block1_t;
-  typedef Dense<Dim, T, order_type, Map2>   dist_block2_t;
-
-  typedef typename View_of_dim<Dim, T, dist_block0_t>::type view0_t;
-  typedef typename View_of_dim<Dim, T, dist_block1_t>::type view1_t;
-  typedef typename View_of_dim<Dim, T, dist_block2_t>::type view2_t;
-
-  // map0 is not distributed (effectively).
-  map0_t  map0(Block_dist(1), Block_dist(1));
-
-  view0_t view0(create_view<view0_t>(dom, T(), map0));
-  view1_t view1(create_view<view1_t>(dom, map1));
-  view2_t view2(create_view<view2_t>(dom, map2));
-
-  check_local_view<Dim>(view0);
-  check_local_view<Dim>(view1);
-  check_local_view<Dim>(view2);
-
-  impl::Communicator comm = impl::default_communicator();
-
-  // cout << "(" << local_processor() << "): test_distributed_view\n";
-
-  for (int l=0; l<loop; ++l)
+  static void
+  exec(
+    Domain<Dim> dom,
+    Map1        map1,
+    Map2        map2,
+    int         loop)
   {
-    foreach_point(view0, Set_identity<Dim>(dom));
+    typedef Map<Block_dist, Block_dist> map0_t;
 
-    view1 = view0;
-
-    foreach_point(view1, Increment<Dim, T>(T(100)));
-
-    view2 = view1;
+    typedef typename impl::Row_major<Dim>::type order_type;
     
-    foreach_point(view2, Increment<Dim, T>(T(1000)));
+    typedef Dense<Dim, T, order_type, map0_t> dist_block0_t;
+    typedef Dense<Dim, T, order_type, Map1>   dist_block1_t;
+    typedef Dense<Dim, T, order_type, Map2>   dist_block2_t;
     
-    view0 = view2;
-  }
+    typedef typename View_of_dim<Dim, T, dist_block0_t>::type view0_t;
+    typedef typename View_of_dim<Dim, T, dist_block1_t>::type view1_t;
+    typedef typename View_of_dim<Dim, T, dist_block2_t>::type view2_t;
+    
+    // map0 is not distributed (effectively).
+    map0_t  map0(Block_dist(1), Block_dist(1));
+    
+    view0_t view0(create_view<view0_t>(dom, T(), map0));
+    view1_t view1(create_view<view1_t>(dom, map1));
+    view2_t view2(create_view<view2_t>(dom, map2));
+    
+    check_local_view<Dim>(view0);
+    check_local_view<Dim>(view1);
+    check_local_view<Dim>(view2);
 
-  // Check results.
-  comm.barrier();
+    impl::Communicator& comm = impl::default_communicator();
 
-  if (local_processor() == 0) 
-  {
-    typename view0_t::local_type local_view = view0.local();
+    // cout << "(" << local_processor() << "): test_distributed_view\n";
 
-    // Check that local_view is in fact the entire view.
-    test_assert(extent(local_view) == extent(dom));
+    for (int l=0; l<loop; ++l)
+    {
+      foreach_point(view0, Set_identity<Dim>(dom));
+      
+      view1 = view0;
+      
+      foreach_point(view1, Increment<Dim, T>(T(100)));
+      
+      view2 = view1;
+      
+      foreach_point(view2, Increment<Dim, T>(T(1000)));
+      
+      view0 = view2;
+    }
+    
+    // Check results.
+    comm.barrier();
 
-    // Check that each value is correct.
-    bool good = true;
-    Length<Dim> ext = extent(local_view);
-    for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
+    if (local_processor() == 0) 
     {
-      T expected_value = T();
-      for (dimension_type d=0; d<Dim; ++d)
+      typename view0_t::local_type local_view = view0.local();
+
+      // Check that local_view is in fact the entire view.
+      test_assert(extent(local_view) == extent(dom));
+      
+      // Check that each value is correct.
+      bool good = true;
+      Length<Dim> ext = extent(local_view);
+      for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
       {
-	expected_value *= local_view.size(d);
-	expected_value += idx[d];
+	T expected_value = T();
+	for (dimension_type d=0; d<Dim; ++d)
+	{
+	  expected_value *= local_view.size(d);
+	  expected_value += idx[d];
+	}
+	expected_value += T(1100);
+
+	if (get(local_view, idx) != expected_value)
+	{
+	  cout << "FAIL: index: " << idx
+	       << "  expected " << expected_value
+	       << "  got "      << get(local_view, idx)
+	       << endl;
+	  good = false;
+	}
       }
-      expected_value += T(1100);
 
-      if (get(local_view, idx) != expected_value)
-      {
-	cout << "FAIL: index: " << idx
-	     << "  expected " << expected_value
-	     << "  got "      << get(local_view, idx)
-	     << endl;
-	good = false;
-      }
+      // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
+      test_assert(good);
     }
+  }
+};
 
-    // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
-    test_assert(good);
-  }
+
+
+// Wrapper for Test_distributed_view
+
+template <typename       TestImplTag,
+	  typename       T,
+	  dimension_type Dim,
+	  typename       Map1,
+	  typename       Map2>
+void
+test_distributed_view(
+  Domain<Dim> dom,
+  Map1        map1,
+  Map2        map2,
+  int         loop)
+{
+  Test_distributed_view<TestImplTag, T, Dim, Map1, Map2>
+    ::exec(dom, map1, map2, loop);
 }
 
 
 
+
 // Test a single parallel assignment.
 
 template <typename                  T,
@@ -343,8 +380,6 @@
   check_local_view<Dim>(view1);
   check_local_view<Dim>(view2);
 
-  impl::Communicator comm = impl::default_communicator();
-
   foreach_point(view1, Set_identity<Dim>(dom));
   for (int l=0; l<loop; ++l)
   {
@@ -358,30 +393,45 @@
 // Test several distributed vector cases for a given type and parallel
 // assignment implementation.
 
-template <typename ParAssignTag,
+template <typename TestImplTag,
 	  typename T>
 void
 test_vector(int loop)
 {
   processor_type np = num_processors();
 
-  test_distributed_view<ParAssignTag, T>(
+  test_distributed_view<TestImplTag, T>(
     Domain<1>(16),
+    Map<Block_dist>(np),
+    Map<Block_dist>(1),
+    loop);
+
+  if (np != 1)
+    test_distributed_view<TestImplTag, T>(
+      Domain<1>(16),
+      Map<Block_dist>(1),
+      Map<Block_dist>(np),
+      loop);
+
+#if VSIP_DIST_LEVEL >= 3
+  test_distributed_view<TestImplTag, T>(
+    Domain<1>(16),
     Map<Block_dist>(Block_dist(np)),
     Map<Cyclic_dist>(Cyclic_dist(np)),
     loop);
 
-  test_distributed_view<ParAssignTag, T>(
+  test_distributed_view<TestImplTag, T>(
     Domain<1>(16),
     Map<Cyclic_dist>(Cyclic_dist(np)),
     Map<Block_dist>(Block_dist(np)),
     loop);
 
-  test_distributed_view<ParAssignTag, T>(
+  test_distributed_view<TestImplTag, T>(
     Domain<1>(256),
     Map<Cyclic_dist>(Cyclic_dist(np, 4)),
     Map<Cyclic_dist>(Cyclic_dist(np, 3)),
     loop);
+#endif
 }
 
 
@@ -389,7 +439,7 @@
 // Test several distributed matrix cases for a given type and parallel
 // assignment implementation.
 
-template <typename ParAssignTag,
+template <typename TestImplTag,
 	  typename T>
 void
 test_matrix(int loop)
@@ -397,164 +447,115 @@
   processor_type np, nr, nc;
   get_np_half(np, nr, nc);
 
-  test_distributed_view<ParAssignTag, T>(
+  test_distributed_view<TestImplTag, T>(
     Domain<2>(4, 4),
     Map<>(Block_dist(np), Block_dist(1)),
     Map<>(Block_dist(1),  Block_dist(np)),
     loop);
 
-  test_distributed_view<ParAssignTag, T>(
+  test_distributed_view<TestImplTag, T>(
     Domain<2>(16, 16),
     Map<>(Block_dist(nr), Block_dist(nc)),
     Map<>(Block_dist(nc), Block_dist(nr)),
     loop);
 			  
-  test_distributed_view<ParAssignTag, T>(
+#if VSIP_DIST_LEVEL >= 3
+  test_distributed_view<TestImplTag, T>(
     Domain<2>(16, 16),
     Map<Cyclic_dist, Block_dist>(Cyclic_dist(nr, 2), Block_dist(nc)),
     Map<Block_dist, Cyclic_dist>(Block_dist(nc),    Cyclic_dist(nr, 2)),
     loop);
+#endif
 
-  test_distributed_view<ParAssignTag, T>(
+#if 0
+  test_distributed_view<TestImplTag, T>(
     Domain<2>(256, 256),
     Map<>(Block_dist(nr), Block_dist(nc)),
     Map<>(Block_dist(nc), Block_dist(nr)),
     loop);
+#endif
 }
 
 
 
-// Test several distributed vector cases for a given type and parallel
-// assignment implementation.
-
 template <typename T>
 void
-test_vector_assign(int loop)
-{
-  processor_type np = num_processors();
-
-  test_distributed_view_assign<T>(
-    Domain<1>(16),
-    Map<Block_dist>(Block_dist(np)),
-    Map<Cyclic_dist>(Cyclic_dist(np)),
-    loop);
-
-  test_distributed_view_assign<T>(
-    Domain<1>(16),
-    Map<Cyclic_dist>(Cyclic_dist(np)),
-    Map<Block_dist>(Block_dist(np)),
-    loop);
-
-  test_distributed_view_assign<T>(
-    Domain<1>(256),
-    Map<Cyclic_dist>(Cyclic_dist(np, 4)),
-    Map<Cyclic_dist>(Cyclic_dist(np, 3)),
-    loop);
-}
-
-
-
-template <typename                  T>
-void
-test_matrix_assign(int loop)
-{
-  processor_type np, nhr, nhc, nr, nc;
-  get_np_half(np, nhr, nhc);
-  get_np_square(np, nr, nc);
-
-  test_distributed_view_assign<T>(
-    Domain<2>(4, 4),
-    Map<>(Block_dist(np), Block_dist(1)),
-    Map<>(Block_dist(1), Block_dist(np)),
-    loop);
-
-  test_distributed_view_assign<T>(
-    Domain<2>(16, 16),
-    Map<>(Block_dist(nhr), Block_dist(nhc)),
-    Map<>(Block_dist(nhc), Block_dist(nhr)),
-    loop);
-			  
-  test_distributed_view_assign<T>(
-    Domain<2>(16, 16),
-    Map<Cyclic_dist, Block_dist>(Cyclic_dist(nhr, 2), Block_dist(nhc)),
-    Map<Block_dist, Cyclic_dist>(Block_dist(nhc),     Cyclic_dist(nhr, 2)),
-    loop);
-
-  test_distributed_view_assign<T>(
-    Domain<2>(256, 256),
-    Map<>(Block_dist(nhr), Block_dist(nhc)),
-    Map<>(Block_dist(nhc), Block_dist(nhr)),
-    loop);
-}
-
-
-
-template <typename T>
-void
 test_par_assign_cases(int loop)
 {
   processor_type np, nr, nc;
   get_np_square(np, nr, nc);
 
   // Vector Serial -> Serial
+  // std::cout << "Global_map<1> -> Global_map<1>\n" << std::flush;
   test_par_assign<float>(Domain<1>(16),
 			 Global_map<1>(),
 			 Global_map<1>(),
 			 loop);
 
   // Vector Serial -> Block_dist
+  // std::cout << "Global_map<1> -> Map<Block_dist>\n" << std::flush;
   test_par_assign<float>(Domain<1>(16),
 			 Global_map<1>(),
 			 Map<Block_dist>(Block_dist(np)),
 			 loop);
 
   // Vector Block_dist -> Serial
+  // std::cout << "Map<Block_dist> -> Global_map<1>\n" << std::flush;
   test_par_assign<float>(Domain<1>(16),
 			 Map<Block_dist>(Block_dist(np)),
 			 Global_map<1>(),
 			 loop);
 
   // Matrix Serial -> Serial
+  // std::cout << "Global_map<2> -> Global_map<2>\n" << std::flush;
   test_par_assign<float>(Domain<2>(16, 16),
 			 Global_map<2>(),
 			 Global_map<2>(),
 			 loop);
 
   // Matrix Serial -> Block_dist
+  // std::cout << "Global_map<2> -> Map<> (square)\n" << std::flush;
   test_par_assign<float>(Domain<2>(16, 16),
 			 Global_map<2>(),
 			 Map<Block_dist>(Block_dist(nr), Block_dist(nc)),
 			 loop);
+  // std::cout << "Global_map<2> -> Map<> (cols)\n" << std::flush;
   test_par_assign<float>(Domain<2>(16, 16),
 			 Global_map<2>(),
 			 Map<Block_dist>(Block_dist(1), Block_dist(np)),
 			 loop);
+  // std::cout << "Global_map<2> -> Map<> (rows)\n" << std::flush;
   test_par_assign<float>(Domain<2>(16, 16),
 			 Global_map<2>(),
 			 Map<Block_dist>(Block_dist(np), Block_dist(1)),
 			 loop);
 
   // Matrix Block_dist -> Serial
+  // std::cout << "Map<> (square) -> Global_map<2>\n" << std::flush;
   test_par_assign<float>(Domain<2>(16, 16),
 			 Map<Block_dist>(Block_dist(nr), Block_dist(nc)),
 			 Global_map<2>(),
 			 loop);
+  // std::cout << "Map<> (cols) -> Global_map<2>\n" << std::flush;
   test_par_assign<float>(Domain<2>(16, 16),
 			 Map<Block_dist>(Block_dist(1), Block_dist(np)),
 			 Global_map<2>(),
 			 loop);
+  // std::cout << "Map<> (rows) -> Global_map<2>\n" << std::flush;
   test_par_assign<float>(Domain<2>(16, 16),
 			 Map<Block_dist>(Block_dist(np), Block_dist(1)),
 			 Global_map<2>(),
 			 loop);
 
+  // std::cout << "Map<> (rows) -> Map<> (cols)\n" << std::flush;
   test_par_assign<float>(Domain<2>(16, 16),
 			 Map<Block_dist>(Block_dist(np), Block_dist(1)),
 			 Map<Block_dist>(Block_dist(1), Block_dist(np)),
 			 loop);
 
   // Tensor case.
-  test_par_assign<float>(Domain<3>(16, 18, 20),
+  // std::cout << "3D: Map<> (rows) -> Map<> (cols)\n" << std::flush;
+  test_par_assign<float>(Domain<3>(16, 8, 5),
 		Map<Block_dist>(Block_dist(np), Block_dist(1), Block_dist(1)),
 		Map<Block_dist>(Block_dist(1), Block_dist(np), Block_dist(1)),
 		loop);
@@ -571,7 +572,7 @@
 
 #if 0
   // Enable this section for easier debugging.
-  impl::Communicator comm = impl::default_communicator();
+  impl::Communicator& comm = impl::default_communicator();
   pid_t pid = getpid();
 
   cout << "rank: "   << comm.rank()
@@ -590,12 +591,13 @@
 
   test_par_assign_cases<float>(loop);
 
-  test_vector_assign<float>(loop);
-  test_matrix_assign<float>(loop);
+  test_vector<TestImplicit, float>(loop);
+  test_matrix<TestImplicit, float>(loop);
 
-  test_vector<impl::Chained_assign,   float>(loop);
-  test_matrix<impl::Chained_assign,   float>(loop);
 
+  test_vector<TestExplicit<IMPL_TAG>, float>(loop);
+  test_matrix<TestExplicit<IMPL_TAG>, float>(loop);
+
   test_local_view<float>(Domain<1>(2), Map<>(Block_dist(np)));
   test_local_view<float>(Domain<1>(2), Map<>(Block_dist(np > 1 ? np-1 : 1)));
 
@@ -603,31 +605,31 @@
 
   test_par_assign_cases<complex<float> >(loop);
 
-  test_vector_assign<complex<float> >(loop);
-  test_matrix_assign<complex<float> >(loop);
+  test_vector<TestImplicit, complex<float> >(loop);
+  test_matrix<TestImplicit, complex<float> >(loop);
 
-  test_vector<impl::Chained_assign,   complex<float> >(loop);
-  test_matrix<impl::Chained_assign,   complex<float> >(loop);
+  test_vector<TestExplicit<IMPL_TAG>, complex<float> >(loop);
+  test_matrix<TestExplicit<IMPL_TAG>, complex<float> >(loop);
 
   test_local_view<complex<float> >(Domain<1>(2), Map<>(Block_dist(np)));
-  test_local_view<complex<float> >(Domain<1>(2), Map<>(Block_dist(np > 1 ? np-1 : 1)));
+  test_local_view<complex<float> >(Domain<1>(2), Map<>(np > 1 ? np-1 : 1));
 
 #if TEST_OLD_PAR_ASSIGN
   // Enable this to test older assignments.
-  test_vector<impl::Packed_parallel_assign,   float>(loop);
-  test_matrix<impl::Packed_parallel_assign,   float>(loop);
+  test_vector<TestExplicit<impl::Packed_parallel_assign>,   float>(loop);
+  test_matrix<TestExplicit<impl::Packed_parallel_assign>,   float>(loop);
 
-  test_vector<impl::Simple_parallel_assign_SOL, float>(loop);
-  test_vector<impl::Simple_parallel_assign_DOL, float>(loop);
+  test_vector<TestExplicit<impl::Simple_parallel_assign_SOL>, float>(loop);
+  test_vector<TestExplicit<impl::Simple_parallel_assign_DOL>, float>(loop);
 
-  test_matrix<impl::Simple_parallel_assign_SOL, float>(loop);
-  test_matrix<impl::Simple_parallel_assign_DOL, float>(loop);
+  test_matrix<TestExplicit<impl::Simple_parallel_assign_SOL>, float>(loop);
+  test_matrix<TestExplicit<impl::Simple_parallel_assign_DOL>, float>(loop);
 
-  test_vector<impl::Simple_parallel_assign_SOL, int>(loop);
-  test_vector<impl::Simple_parallel_assign_DOL, int>(loop);
+  test_vector<TestExplicit<impl::Simple_parallel_assign_SOL>, int>(loop);
+  test_vector<TestExplicit<impl::Simple_parallel_assign_DOL>, int>(loop);
 
-  test_matrix<impl::Simple_parallel_assign_SOL, int>(loop);
-  test_matrix<impl::Simple_parallel_assign_DOL, int>(loop);
+  test_matrix<TestExplicit<impl::Simple_parallel_assign_SOL>, int>(loop);
+  test_matrix<TestExplicit<impl::Simple_parallel_assign_DOL>, int>(loop);
 #endif
 
   return 0;
Index: tests/appmap.cpp
===================================================================
--- tests/appmap.cpp	(revision 147999)
+++ tests/appmap.cpp	(working copy)
@@ -353,11 +353,42 @@
 
 
 
+// Test what happens when number of subblocks > elements, forcing
+// multiple subblocks to be empty.
+void
+test_empty_subblocks()
+{
+  typedef Map<Block_dist> map_t;
+
+  length_type const subblocks  = 6;
+  length_type const size       = 4;
+
+  Vector<processor_type> pvec = create_pvec(subblocks);
+
+  map_t map(pvec, Block_dist(subblocks));
+  map.impl_apply(Domain<1>(4));
+
+  length_type sum = 0;
+  for (index_type i=0; i<subblocks; ++i)
+  {
+    std::cout << " i = " << map.impl_subblock_domain<1>(i).size() << std::endl;
+    test_assert(map.impl_subblock_domain<1>(i).size() == 1 ||
+		map.impl_subblock_domain<1>(i).size() == 0);
+    sum += map.impl_subblock_domain<1>(i).size();
+  }
+  std::cout << "sum = " << sum << std::endl;
+  test_assert(sum == size);
+}
+
+
+
 int
 main()
 {
   test_appmap();
 
+  test_empty_subblocks();
+
   test_1d_appmap();
   test_2d_appmap();
 }
Index: tests/reductions.cpp
===================================================================
--- tests/reductions.cpp	(revision 147999)
+++ tests/reductions.cpp	(working copy)
@@ -416,26 +416,32 @@
 
   cover_sumval<int>();
   cover_sumval<float>();
-  cover_sumval<double>();
   cover_sumval<complex<float> >();
-  cover_sumval<complex<double> >();
 
   cover_sumval_bool();
 
   cover_sumsqval<int>();
   cover_sumsqval<float>();
-  cover_sumsqval<double>();
   cover_sumsqval<complex<float> >();
-  cover_sumsqval<complex<double> >();
 
   cover_meanval<int>();
   cover_meanval<float>();
-  cover_meanval<double>();
   cover_meanval<complex<float> >();
 
   cover_meansqval<int>();
   cover_meansqval<float>();
+  cover_meansqval<complex<float> >();
+
+#if VSIP_IMPL_TEST_DOUBLE
+  cover_sumval<double>();
+  cover_sumval<complex<double> >();
+
+  cover_sumsqval<double>();
+  cover_sumsqval<complex<double> >();
+
+  cover_meanval<double>();
+
   cover_meansqval<double>();
-  cover_meansqval<complex<float> >();
   cover_meansqval<complex<double> >();
+#endif
 }
Index: tests/convolution.cpp
===================================================================
--- tests/convolution.cpp	(revision 147999)
+++ tests/convolution.cpp	(working copy)
@@ -498,10 +498,12 @@
   bool rand = true;
   cases<int>(rand);
   cases<float>(rand);
-  cases<double>(rand);
   // cases<complex<int> >(rand);
   cases<complex<float> >(rand);
+#if VSIP_IMPL_TEST_DOUBLE
+  cases<double>(rand);
   cases<complex<double> >(rand);
+#endif
 
   // Test distributed arguments.
   cases_conv_dist<float>(32, 8, 1);
Index: tests/solver-cholesky.cpp
===================================================================
--- tests/solver-cholesky.cpp	(revision 147999)
+++ tests/solver-cholesky.cpp	(working copy)
@@ -441,12 +441,15 @@
 #endif
 
   chold_cases<float>           (upper);
-  chold_cases<double>          (upper);
   chold_cases<complex<float> > (upper);
-  chold_cases<complex<double> >(upper);
 
   chold_cases<float>           (lower);
+  chold_cases<complex<float> > (lower);
+
+#if VSIP_IMPL_TEST_DOUBLE
+  chold_cases<double>          (upper);
+  chold_cases<complex<double> >(upper);
   chold_cases<double>          (lower);
-  chold_cases<complex<float> > (lower);
   chold_cases<complex<double> >(lower);
+#endif // VSIP_IMPL_TEST_DOUBLE
 }
Index: configure.ac
===================================================================
--- configure.ac	(revision 147999)
+++ configure.ac	(working copy)
@@ -13,6 +13,7 @@
 AC_PREREQ(2.56)
 AC_REVISION($Revision: 1.110 $)
 AC_INIT(Sourcery VSIPL++, 1.1, vsipl++@codesourcery.com, sourceryvsipl++)
+AC_CONFIG_MACRO_DIR(/usr/share/aclocal)
 
 ######################################################################
 # Configure command line arguments.
@@ -88,6 +89,13 @@
                  [Specify the installation prefix of the MPI library.  Headers
                   must be in PATH/include64; libraries in PATH/lib64.]),)
 
+
+### Mercury PAS
+AC_ARG_ENABLE([pas],
+  AS_HELP_STRING([--enable-pas],
+                 [use PAS if found (default is to not search for it)]),,
+  [enable_pas=no])
+
 ### Mercury Scientific Algorithm (SAL)
 AC_ARG_ENABLE([sal],
   AS_HELP_STRING([--enable-sal],
@@ -804,7 +812,15 @@
   fi
 fi
 
-if test "$enable_mpi" != "no"; then
+if test "$enable_pas" = "yes"; then
+  vsipl_par_service=2
+
+  PKG_CHECK_MODULES(PAS, pas)
+  echo "PAS_CFLAGS: $PAS_CFLAGS"
+  echo "PAS_LIBS  : $PAS_LIBS"
+  CPPFLAGS="$CPPFLAGS $PAS_CFLAGS"
+  LIBS="$LIBS $PAS_LIBS"
+elif test "$enable_mpi" != "no"; then
   vsipl_par_service=1
 
   if test -n "$with_mpi_prefix" -a "$with_mpi_prefix" != "/usr"; then
@@ -961,7 +977,7 @@
 fi
 
 AC_DEFINE_UNQUOTED(VSIP_IMPL_PAR_SERVICE, $vsipl_par_service,
-  [Define to parallel service provided (0 == no service, 1 = MPI).])
+  [Define to parallel service provided (0 == no service, 1 = MPI, 2 = PAS).])
 
 #
 # Find the Mercury SAL library, if enabled.
Index: autogen.sh
===================================================================
--- autogen.sh	(revision 147999)
+++ autogen.sh	(working copy)
@@ -4,6 +4,7 @@
 # Generate 'src/vsip/impl/acconfig.hpp.in' by inspecting 'configure.ac'
 autoheader
 # Generate 'configure' from 'configure.ac'
+aclocal
 autoconf
 
 # Tell configure to ignore non-executable/object files generated by
Index: benchmarks/loop.hpp
===================================================================
--- benchmarks/loop.hpp	(revision 147999)
+++ benchmarks/loop.hpp	(working copy)
@@ -247,9 +247,9 @@
   double   growth;
   unsigned const n_time = samples_;
 
-  COMMUNICATOR_TYPE comm  = DEFAULT_COMMUNICATOR();
-  PROCESSOR_TYPE    rank  = RANK(comm);
-  PROCESSOR_TYPE    nproc = NUM_PROCESSORS();
+  COMMUNICATOR_TYPE& comm  = DEFAULT_COMMUNICATOR();
+  PROCESSOR_TYPE     rank  = RANK(comm);
+  PROCESSOR_TYPE     nproc = NUM_PROCESSORS();
 
   std::vector<float> mtime(n_time);
 
@@ -417,9 +417,9 @@
   size_t   loop, M;
   float    time;
 
-  COMMUNICATOR_TYPE comm  = DEFAULT_COMMUNICATOR();
-  PROCESSOR_TYPE    rank  = RANK(comm);
-  PROCESSOR_TYPE    nproc = NUM_PROCESSORS();
+  COMMUNICATOR_TYPE& comm  = DEFAULT_COMMUNICATOR();
+  PROCESSOR_TYPE     rank  = RANK(comm);
+  PROCESSOR_TYPE     nproc = NUM_PROCESSORS();
 
 #if PARALLEL_LOOP
   using vsip::Map;
@@ -519,7 +519,7 @@
   size_t loop = 1;
   size_t M = this->m_value(cal_);
 
-  COMMUNICATOR_TYPE comm  = DEFAULT_COMMUNICATOR();
+  COMMUNICATOR_TYPE& comm  = DEFAULT_COMMUNICATOR();
 
   BARRIER(comm);
   fcn(M, loop, time);
Index: benchmarks/main.cpp
===================================================================
--- benchmarks/main.cpp	(revision 147999)
+++ benchmarks/main.cpp	(working copy)
@@ -127,7 +127,7 @@
   if (pause)
   {
     // Enable this section for easier debugging.
-    impl::Communicator comm = impl::default_communicator();
+    impl::Communicator& comm = impl::default_communicator();
     pid_t pid = getpid();
 
     std::cout << "rank: "   << comm.rank()
Index: examples/mercury/mcoe-setup.sh
===================================================================
--- examples/mercury/mcoe-setup.sh	(revision 147999)
+++ examples/mercury/mcoe-setup.sh	(working copy)
@@ -98,7 +98,9 @@
 #########################################################################
 cfgflags=""
 
-if test $comm = "par"; then
+if test $comm = "pas"; then
+  cfg_flags="$cfg_flags --enable-pas"
+elif test $comm = "mpi" -o $comm = "par"; then
   cfg_flags="$cfg_flags --enable-mpi=mpipro"
 else
   cfg_flags="$cfg_flags --disable-mpi"
