Index: ChangeLog
===================================================================
--- ChangeLog	(revision 157172)
+++ ChangeLog	(working copy)
@@ -1,3 +1,36 @@
+2006-12-12  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/domain_utils.hpp (intersect): Extend to handle
+	  non-unit-stride in 1 arg.
+	  (apply_intr): New function to apply an intersection to another dom.
+	  (subset_from_intr): New function to convert an intersection into
+	  a subset.
+	  (domain): New overloads to create a domain from a length.
+	* src/vsip/core/subblock.hpp (Subset_block_map): Fix usage of 'type'
+	  to work when subset map type differs from parent map type.
+	  (Subset_block): Add asserts on get().
+	  (get_local_view): Extend to work with Subset_map.
+	* src/vsip/core/parallel/subset_map.hpp: New file, map for
+	  distributed subsets.
+	* src/vsip/core/parallel/expr.hpp: Don't use assumption that
+	  local subblock is element conformant with union of patches.
+	* src/vsip/core/parallel/assign_block_vector.hpp
+	  (VSIP_IMPL_ABV_VERBOSE): Rename macro.
+	* src/vsip/core/parallel/assign_chain.hpp: Use apply_intr to
+	  determine send and receive domains.
+	* src/vsip/core/map_fwd.hpp (Subset_map): Forward decl.
+	* src/vsip/map.hpp: Include subset_map. 
+	  (impl_local_from_global_domain): Update to work with subsets
+	  supported by Subset_map.
+	* src/vsip_csl/matlab_utils.hpp: Qualify names used from vsip
+	  namespace.
+	* tests/fftshift.cpp: New file, tests for fftshit function,
+	  including distributed cases.
+	* tests/domain_utils.cpp: New file, unit tests for intersect,
+	  apply_intr, and subset_from_intr functions.
+	* tests/parallel/subset_map.cpp: New file, coverge tests for
+	  distributed subsets.
+	
 2006-12-11  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/vector.hpp: Assert index is valid for get/put.
Index: src/vsip/core/domain_utils.hpp
===================================================================
--- src/vsip/core/domain_utils.hpp	(revision 156744)
+++ src/vsip/core/domain_utils.hpp	(working copy)
@@ -179,7 +179,7 @@
 
 // Requires:
 //   DOM1 is a Domain<1> with stride 1,
-//   DOM2 is a Domain<1> with stride 1,
+//   DOM2 is a Domain<1>
 //   RES is a Domain<1>.
 // Effects:
 //   If DOM1 and DOM2 intersect,
@@ -193,17 +193,50 @@
   Domain<1> const& dom2,
   Domain<1>&       res)
 {
-  assert(dom1.stride() == 1 && dom2.stride() == 1);
+  assert(dom1.stride() == 1);
 
-  index_type first = std::max(dom1.first(),     dom2.first());
-  index_type last  = std::min(dom1.impl_last(), dom2.impl_last());
+  if (dom2.stride() == 1)
+  {
+    index_type first   = std::max(dom1.first(),     dom2.first());
+    index_type last    = std::min(dom1.impl_last(), dom2.impl_last());
 
-  if (first <= last) 
+    if (first <= last) 
+    {
+      res = Domain<1>(first, 1, last-first+1);
+      return true;
+    }
+    else return false;
+  }
+  else
   {
-    res = Domain<1>(first, 1, last-first+1);
-    return true;
+    index_type first1  = dom1.first();
+    index_type first2  = dom2.first();
+    index_type last1   = dom1.impl_last();
+    index_type last2   = dom2.impl_last();
+    if (first2 < first1)
+    {
+      index_type diff = first1 - first2;
+      first2 += diff;
+      if (diff % dom2.stride())
+	first2 += (dom2.stride() - (diff % dom2.stride()));
+    }
+    if (last2 > last1)
+    {
+      index_type diff = last2 - last1;
+      if (diff % dom2.stride())
+	last2 -= (dom2.stride() - (diff % dom2.stride()));
+    }
+
+    index_type first   = std::max(first1, first2);
+    index_type last    = std::min(last1,  last2);
+
+    if (first <= last) 
+    {
+      res = Domain<1>(first, dom2.stride(), (last-first)/dom2.stride()+1);
+      return true;
+    }
+    else return false;
   }
-  else return false;
 }
 
 
@@ -244,8 +277,7 @@
       intersect(dom1[2], dom2[2], res_dim[2]))
   {
     res = Domain<3>(res_dim[0], res_dim[1], res_dim[2]);
-
-    return true;;
+    return true;
   }
   else return false;
 }
@@ -272,6 +304,80 @@
 
 
 
+// Apply offset implied by intersection to another domain.
+
+Domain<1>
+apply_intr(
+  Domain<1> const& x,
+  Domain<1> const& y,
+  Domain<1> const& intr)
+{
+  return Domain<1>(x.first() + (intr.first() - y.first()) * x.stride(),
+		   x.stride() * intr.stride(),
+		   intr.size());
+}
+
+Domain<2>
+apply_intr(
+  Domain<2> const& x,
+  Domain<2> const& y,
+  Domain<2> const& intr)
+{
+  return Domain<2>(apply_intr(x[0], y[0], intr[0]),
+		   apply_intr(x[1], y[1], intr[1]));
+}
+
+Domain<3>
+apply_intr(
+  Domain<3> const& x,
+  Domain<3> const& y,
+  Domain<3> const& intr)
+{
+  return Domain<3>(apply_intr(x[0], y[0], intr[0]),
+		   apply_intr(x[1], y[1], intr[1]),
+		   apply_intr(x[2], y[2], intr[2]));
+}
+
+
+
+/// Convert an intersection into a subset
+///
+/// Subdomain's
+///   offset is adjusted relative to parent domain
+///   stride is 1 (since parent encodes stride)
+///   size is unchanged.
+
+Domain<1>
+subset_from_intr(
+  Domain<1> const& dom,
+  Domain<1> const& intr)
+{
+  return Domain<1>((intr.first() - dom.first()) / dom.stride(),
+		   1,
+		   intr.size());
+}
+
+Domain<2>
+subset_from_intr(
+  Domain<2> const& dom,
+  Domain<2> const& intr)
+{
+  return Domain<2>(subset_from_intr(dom[0], intr[0]),
+		   subset_from_intr(dom[1], intr[1]));
+}
+
+Domain<3>
+subset_from_intr(
+  Domain<3> const& dom,
+  Domain<3> const& intr)
+{
+  return Domain<3>(subset_from_intr(dom[0], intr[0]),
+		   subset_from_intr(dom[1], intr[1]),
+		   subset_from_intr(dom[2], intr[2]));
+}
+
+
+
 /// Return the total size of a domain.
 
 template <dimension_type Dim>
@@ -382,7 +488,39 @@
 
 
 
+/// Construct a 1-dim domain with a size (implicit offset of 0 and
+/// stride of 1)
 
+inline Domain<1>
+domain(Length<1> const& size)
+{
+  return Domain<1>(size[0]);
+}
+
+
+
+/// Construct a 2-dim domain with a size (implicit offset of 0 and
+/// stride of 1)
+
+inline Domain<2>
+domain(Length<2> const& size)
+{
+  return Domain<2>(size[0], size[1]);
+}
+
+
+
+/// Construct a 3-dim domain with a size (implicit offset of 0 and
+/// stride of 1)
+
+inline Domain<3>
+domain(Length<3> const& size)
+{
+  return Domain<3>(size[0], size[1], size[2]);
+}
+
+
+
 /// Construct a 1-dim domain with an offset and a size (implicit
 /// stride of 1)
 
Index: src/vsip/core/subblock.hpp
===================================================================
--- src/vsip/core/subblock.hpp	(revision 156744)
+++ src/vsip/core/subblock.hpp	(working copy)
@@ -243,19 +243,20 @@
           typename       Dist2>
 struct Subset_block_map<Dim, Map<Dist0, Dist1, Dist2> >
 {
-  typedef Map<Dist0, Dist1, Dist2> type;
+  typedef typename Map_subdomain<Dim, Map<Dist0, Dist1, Dist2> >::type type;
 
-  static type convert_map(type const&        map,
-			  Domain<Dim> const& dom)
+  static type convert_map(Map<Dist0, Dist1, Dist2> const& map,
+			  Domain<Dim> const&              dom)
   {
-    return Map_subdomain<Dim, type>::project(map, dom);
+    return Map_subdomain<Dim, Map<Dist0, Dist1, Dist2> >::project(map, dom);
   }
 
-  static index_type parent_subblock(type const&        map,
-				    Domain<Dim> const& dom,
-				    index_type         sb)
+  static index_type parent_subblock(Map<Dist0, Dist1, Dist2> const& map,
+				    Domain<Dim> const&              dom,
+				    index_type                      sb)
   {
-    return Map_subdomain<Dim, type>::parent_subblock(map, dom, sb);
+    return Map_subdomain<Dim, Map<Dist0, Dist1, Dist2> >
+      ::parent_subblock(map, dom, sb);
   }
 };
 
@@ -324,15 +325,21 @@
 
   value_type get(index_type i) const VSIP_NOTHROW
   {
+    assert(i < this->size(1, 0));
     return blk_->get(dom_[0].impl_nth(i));
   }
   value_type get(index_type i, index_type j) const VSIP_NOTHROW
   {
+    assert(i < this->size(2, 0));
+    assert(j < this->size(2, 1));
     return blk_->get(dom_[0].impl_nth(i),
 		     dom_[1].impl_nth(j));
   }
   value_type get(index_type i, index_type j, index_type k) const VSIP_NOTHROW
   {
+    assert(i < this->size(3, 0));
+    assert(j < this->size(3, 1));
+    assert(k < this->size(3, 2));
     return blk_->get(dom_[0].impl_nth(i),
 		     dom_[1].impl_nth(j),
 		     dom_[2].impl_nth(k));
@@ -1372,6 +1379,43 @@
 
 
 
+// Helper class to translate a distributed subset into a local subset.
+//
+// In general case, ask the parent block what the local subset should be.
+
+template <typename BlockT,
+	  typename MapT = typename BlockT::map_type>
+struct Subset_parent_local_domain
+{
+  static dimension_type const dim = BlockT::dim;
+
+  static Domain<dim> parent_local_domain(BlockT const& block, index_type sb)
+  {
+    return block.impl_block().map().impl_local_from_global_domain(sb,
+					block.impl_domain());
+  }
+};
+
+
+
+// Specialize for Subset_map, where the local subset is currently larger than
+// what the parent thinks it should be.
+
+template <typename       BlockT,
+	  dimension_type Dim>
+struct Subset_parent_local_domain<BlockT, Subset_map<Dim> >
+{
+  static dimension_type const dim = BlockT::dim;
+
+  static Domain<dim> parent_local_domain(BlockT const& block, index_type sb)
+  {
+    return block.map().template impl_parent_local_domain<dim>(sb);
+  }
+};
+
+
+
+
 template <typename Block>
 Subset_block<typename Distributed_local_block<Block>::type>
 get_local_block(
@@ -1386,8 +1430,8 @@
   Domain<dim> dom;
 
   if (sb != no_subblock)
-    dom = block.impl_block().map().impl_local_from_global_domain(sb,
-					block.impl_domain());
+    dom = Subset_parent_local_domain<Subset_block<Block> >::
+      parent_local_domain(block, sb);
   else
     dom = empty_domain<dim>();
 
Index: src/vsip/core/parallel/subset_map.hpp
===================================================================
--- src/vsip/core/parallel/subset_map.hpp	(revision 0)
+++ src/vsip/core/parallel/subset_map.hpp	(revision 0)
@@ -0,0 +1,323 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/parallel/subset_map.hpp
+    @author  Jules Bergmann
+    @date    2006-12-10
+    @brief   VSIPL++ Library: Map class for distributed subsets.
+
+*/
+
+#ifndef VSIP_CORE_PARALLEL_SUBSET_MAP_HPP
+#define VSIP_CORE_PARALLEL_SUBSET_MAP_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
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
+template <dimension_type Dim>
+class Subset_map
+{
+  // Compile-time typedefs.
+public:
+  typedef impl::Value_iterator<processor_type, unsigned> processor_iterator;
+  typedef std::vector<processor_type> impl_pvec_type;
+
+  // Constructor.
+public:
+  template <typename MapT>
+  Subset_map(MapT const&, Domain<Dim> const&);
+
+  ~Subset_map()
+    {}
+
+
+  // Accessors.
+public:
+  // Information on individual distributions.
+  distribution_type distribution     (dimension_type) const VSIP_NOTHROW
+    { return other; }
+  length_type       num_subblocks    (dimension_type) const VSIP_NOTHROW
+    { return 1; }
+  length_type       cyclic_contiguity(dimension_type) const VSIP_NOTHROW
+    { return 0; }
+
+  length_type num_subblocks()  const VSIP_NOTHROW
+    { return sb_patch_gd_.size(); }
+
+  length_type num_processors() const VSIP_NOTHROW
+    { return pvec_.size(); }
+
+  index_type subblock(processor_type pr) const VSIP_NOTHROW
+  {
+    index_type pi = impl_rank_from_proc(pr);
+
+    if (pi != no_rank && pi < this->num_subblocks())
+      return pi;
+    else
+      return no_subblock;
+  }
+
+  index_type subblock() const VSIP_NOTHROW
+  {
+    processor_type pr = local_processor();
+    return this->subblock(pr);
+  }
+
+  processor_iterator processor_begin(index_type sb) const VSIP_NOTHROW
+  {
+    assert(sb < this->num_subblocks());
+    return processor_iterator(this->pvec_[sb], 1);
+  }
+
+  processor_iterator processor_end  (index_type sb) const VSIP_NOTHROW
+  {
+    assert(sb < this->num_subblocks());
+    return processor_iterator(this->pvec_[sb]+1, 1);
+  }
+
+  const_Vector<processor_type> processor_set() const
+  {
+    Vector<processor_type> pset(this->num_processors());
+
+    for (index_type i=0; i<this->num_processors(); ++i)
+      pset.put(i, this->pvec_[i]);
+
+    return pset;
+  }
+
+  // Applied map functions.
+public:
+  length_type impl_num_patches(index_type sb) const VSIP_NOTHROW
+  {
+    assert(sb < this->num_subblocks());
+    return sb_patch_gd_[sb].size();
+  }
+
+  void impl_apply(Domain<Dim> const& dom) VSIP_NOTHROW
+  {
+    assert(extent(dom_) == extent(dom));
+    impl::create_ll_pset(pvec_, ll_pset_);
+  }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_subblock_domain(index_type sb) const VSIP_NOTHROW
+    { assert(sb < this->num_subblocks()); return domain(sb_ext_[sb]); }
+
+  template <dimension_type Dim2>
+  impl::Length<Dim2> impl_subblock_extent(index_type sb) const VSIP_NOTHROW
+    { assert(sb < this->num_subblocks()); return sb_ext_[sb]; }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_global_domain(index_type sb, index_type p)
+    const VSIP_NOTHROW
+  {
+    assert(sb < this->num_subblocks());
+    assert(p  < this->impl_num_patches(sb));
+    return sb_patch_gd_[sb][p];
+  }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_local_domain (index_type sb, index_type p)
+    const VSIP_NOTHROW
+  {
+    assert(sb < this->num_subblocks());
+    assert(p  < this->impl_num_patches(sb));
+    return sb_patch_ld_[sb][p];
+  }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_parent_local_domain(index_type sb) const VSIP_NOTHROW
+  { return parent_sdom_[sb]; }
+
+  index_type impl_global_from_local_index(dimension_type /*d*/, index_type sb,
+				     index_type idx)
+    const VSIP_NOTHROW
+  {
+    VSIP_IMPL_THROW(impl::unimplemented(
+	      "Subset_map::impl_global_from_local_index not implemented."));
+    return 0;
+  }
+
+  index_type impl_local_from_global_index(dimension_type /*d*/, index_type idx)
+    const VSIP_NOTHROW
+  {
+    VSIP_IMPL_THROW(impl::unimplemented(
+	      "Subset_map::impl_local_from_global_index not implemented."));
+    return 0;
+  }
+
+  template <dimension_type Dim2>
+  index_type impl_subblock_from_global_index(Index<Dim2> const& /*idx*/)
+    const VSIP_NOTHROW
+  {
+    VSIP_IMPL_THROW(impl::unimplemented(
+	      "Subset_map::impl_subblock_from_global_index not implemented."));
+    return 0;
+  }
+
+  template <dimension_type Dim2>
+  Domain<Dim> impl_local_from_global_domain(index_type /*sb*/,
+					    Domain<Dim2> const& dom)
+    const VSIP_NOTHROW
+  {
+    VSIP_IMPL_STATIC_ASSERT(Dim == Dim2);
+    VSIP_IMPL_THROW(impl::unimplemented(
+	      "Subset_map::impl_local_from_global_domain not implemented."));
+    return Domain<Dim>();
+  }
+
+  // Extensions.
+public:
+  impl::par_ll_pset_type impl_ll_pset() const VSIP_NOTHROW
+    { return ll_pset_; }
+  impl::Communicator&    impl_comm() const
+    { return impl::default_communicator(); }
+  impl_pvec_type const&  impl_pvec() const
+    { return pvec_; }
+
+  length_type            impl_working_size() const
+    { return this->num_processors(); }
+
+  processor_type         impl_proc_from_rank(index_type idx) const
+    { return this->impl_pvec()[idx]; }
+
+  index_type impl_rank_from_proc(processor_type pr) const
+  {
+    for (index_type i=0; i<this->num_processors(); ++i)
+      if (this->impl_pvec()[i] == pr) return i;
+    return no_rank;
+  }
+
+  // Determine parent map subblock corresponding to this map's subblock
+  index_type impl_parent_subblock(index_type sb) const
+    { return parent_sb_[sb]; }
+
+public:
+  typedef std::vector<Domain<Dim> >   p_vector_type;
+  typedef std::vector<p_vector_type>  sb_vector_type;
+
+
+  // Member data.
+private:
+  std::vector<index_type>   parent_sb_; // map: local sb -> parent sb
+  std::vector<Length<Dim> > sb_ext_;
+  std::vector<Domain<Dim> > parent_sdom_;	// parent subblock dom.
+  sb_vector_type            sb_patch_gd_;	// subblock-patch global dom
+  sb_vector_type            sb_patch_ld_;	// subblock-patch local dom
+
+  impl_pvec_type            pvec_;		// Grid function.
+  Domain<Dim>               dom_;		// Applied domain.
+  impl::par_ll_pset_type    ll_pset_;
+};
+
+
+
+template <dimension_type Dim>
+template <typename MapT>
+Subset_map<Dim>::Subset_map(
+  MapT const&        map,
+  Domain<Dim> const& dom)
+  : dom_(dom)
+{
+  // Check that map is only block distributed
+  for (dimension_type d = 0; d<Dim; ++d)
+  {
+    if (map.distribution(d) == cyclic)
+      VSIP_IMPL_THROW(impl::unimplemented(
+	      "Subset_map: Subviews of cyclic maps not supported."));
+  }
+
+  for (index_type sb=0; sb<map.num_subblocks(); ++sb)
+  {
+    p_vector_type g_vec;
+    p_vector_type l_vec;
+    
+    for (index_type p=0; p<map.impl_num_patches(sb); ++p)
+    {
+      // parent global/local subdomains for sb-p.
+      Domain<Dim> pg_dom = map.template impl_global_domain<Dim>(sb, p);
+      Domain<Dim> pl_dom = map.template impl_local_domain<Dim>(sb, p);
+
+      Domain<Dim> intr;
+      if (intersect(pg_dom, dom, intr))
+      {
+	// my global/local subdomains for sb-p.
+	Domain<Dim> ml_dom = apply_intr(pl_dom, pg_dom, intr);
+	Domain<Dim> mg_dom = subset_from_intr(dom, intr);
+
+	g_vec.push_back(mg_dom);
+	l_vec.push_back(ml_dom);
+      }
+    }
+
+    if (g_vec.size() > 0)
+    {
+      sb_patch_gd_.push_back(g_vec);
+      sb_patch_ld_.push_back(l_vec);
+      pvec_.push_back(map.impl_proc_from_rank(sb));
+
+      Length<Dim> par_sb_ext = map.template impl_subblock_extent<Dim>(sb);
+      Length<Dim> sb_ext     = par_sb_ext;
+      parent_sdom_.push_back(domain(par_sb_ext));
+      sb_ext_.push_back(sb_ext);
+      parent_sb_.push_back(sb);
+    }
+  }
+}
+
+
+
+/// Specialize global traits for Global_map.
+
+template <dimension_type Dim>
+struct Is_global_map<Subset_map<Dim> >
+{ static bool const value = true; };
+
+
+
+/***********************************************************************
+  Map subdomain
+***********************************************************************/
+
+template <dimension_type Dim,
+	  typename       Dist0,
+	  typename       Dist1,
+	  typename       Dist2>
+struct Map_subdomain<Dim, Map<Dist0, Dist1, Dist2> >
+{
+  typedef Subset_map<Dim> type;
+
+  static type project(
+    Map<Dist0, Dist1, Dist2> const& map,
+    Domain<Dim> const&              dom)
+  {
+    return type(map, dom);
+  }
+
+  // Return the parent subblock corresponding to a child subblock.
+  static index_type parent_subblock(
+    Map<Dist0, Dist1, Dist2> const& map,
+    Domain<Dim> const&              /*dom*/,
+    index_type                      sb)
+  {
+    assert(0);
+    return sb;
+  }
+};
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_CORE_PARALLEL_SUBSET_MAP_HPP
Index: src/vsip/core/parallel/expr.hpp
===================================================================
--- src/vsip/core/parallel/expr.hpp	(revision 156744)
+++ src/vsip/core/parallel/expr.hpp	(working copy)
@@ -316,7 +316,25 @@
       dst_lview_type dst_lview = get_local_view(dst_);
       src_lview_type src_lview = get_local_view(src_remap_);
       
+#if 0
+      // This is valid if the local view is element conformant to the
+      // union of patches in corresponding subblock.
+      //
+      // Subset_maps do not meet this requirement currently.
+      // (061212).
       dst_lview = src_lview;
+#else
+      typedef typename DstBlock::map_type map_type;
+      map_type const& map = dst_block.map();
+
+      index_type sb = map.subblock();
+
+      for (index_type p=0; p<map.impl_num_patches(sb); ++p)
+      {
+	Domain<Dim> dom = map.template impl_local_domain<Dim>(sb, p);
+	dst_lview(dom) = src_lview(dom);
+      }
+#endif
     }
   }
 
Index: src/vsip/core/parallel/assign_block_vector.hpp
===================================================================
--- src/vsip/core/parallel/assign_block_vector.hpp	(revision 156744)
+++ src/vsip/core/parallel/assign_block_vector.hpp	(working copy)
@@ -30,7 +30,7 @@
 //  2 - message size details
 //  3 - data values
 
-#define VSIP_IMPL_PCA_VERBOSE 0
+#define VSIP_IMPL_ABV_VERBOSE 0
 
 
 
@@ -338,7 +338,7 @@
   length_type dsize  = dst_am_.impl_working_size();
   // std::min(dst_am_.num_subblocks(), dst_am_.impl_pvec().size());
 
-#if VSIP_IMPL_PCA_VERBOSE >= 1
+#if VSIP_IMPL_ABV_VERBOSE >= 1
     std::cout << "(" << rank << ") "
 	      << "build_send_list(dsize: " << dsize
 	      << ") -------------------------------------\n";
@@ -392,7 +392,7 @@
 
 	  send_list.push_back(Msg_record(proc, src_sb, xoff, length));
 
-#if VSIP_IMPL_PCA_VERBOSE >= 2
+#if VSIP_IMPL_ABV_VERBOSE >= 2
 	      std::cout << "(" << rank << ") send "
 			<< rank << "/" << src_sb << "/" << 0
 			<< " -> "
@@ -432,7 +432,7 @@
 
   length_type ssize  = src_am_.impl_working_size();
 
-#if VSIP_IMPL_PCA_VERBOSE >= 1
+#if VSIP_IMPL_ABV_VERBOSE >= 1
     std::cout << "(" << rank << ") "
 	      << "build_recv_list(ssize: " << ssize
 	      << ") -------------------------------------\n";
@@ -492,7 +492,7 @@
 
 	  recv_list.push_back(Msg_record(proc, dst_sb, xoff, length));
 	      
-#if VSIP_IMPL_PCA_VERBOSE >= 2
+#if VSIP_IMPL_ABV_VERBOSE >= 2
 	      std::cout << "(" << rank << ") recv "
 			<< rank << "/" << dst_sb << "/" << 0
 			<< " <- "
@@ -525,7 +525,7 @@
     scope("Par_assign<Blkvec_assign>-build_copy_list");
   processor_type rank = local_processor();
 
-#if VSIP_IMPL_PCA_VERBOSE >= 1
+#if VSIP_IMPL_ABV_VERBOSE >= 1
   std::cout << "(" << rank << ") "
 	    << "build_copy_list(num_procs: " << src_am_.num_processors()
 	    << ") -------------------------------------\n";
@@ -558,7 +558,7 @@
 
 	copy_list.push_back(Copy_record(src_sb, dst_sb, send_dom, recv_dom));
 
-#if VSIP_IMPL_PCA_VERBOSE >= 2
+#if VSIP_IMPL_ABV_VERBOSE >= 2
 	std::cout << "(" << rank << ")"
 		  << "copy src: " << src_sb << "/" << sp
 		  << " " << send_dom
@@ -585,7 +585,7 @@
   profile::Scope<profile::par>
     scope("Par_assign<Blkvec_assign>-exec_send_list");
 
-#if VSIP_IMPL_PCA_VERBOSE >= 1
+#if VSIP_IMPL_ABV_VERBOSE >= 1
   processor_type rank = local_processor();
   std::cout << "(" << rank << ") "
 	    << "exec_send_list(size: " << send_list.size()
@@ -623,7 +623,7 @@
   profile::Scope<profile::par>
     scope("Par_assign<Blkvec_assign>-exec_recv_list");
 
-#if VSIP_IMPL_PCA_VERBOSE >= 1
+#if VSIP_IMPL_ABV_VERBOSE >= 1
   processor_type rank = local_processor();
   std::cout << "(" << rank << ") "
 	    << "exec_recv_list(size: " << recv_list.size()
@@ -663,7 +663,7 @@
   profile::Scope<profile::par>
     scope("Par_assign<Blkvec_assign>-exec_copy_list");
 
-#if VSIP_IMPL_PCA_VERBOSE >= 1
+#if VSIP_IMPL_ABV_VERBOSE >= 1
   processor_type rank = local_processor();
   std::cout << "(" << rank << ") "
 	    << "exec_copy_list(size: " << copy_list.size()
@@ -682,11 +682,11 @@
     view_assert_local(dst_, (*cl_cur).dst_sb_);
 
     dst_lview((*cl_cur).dst_dom_) = src_lview((*cl_cur).src_dom_);
-#if VSIP_IMPL_PCA_VERBOSE >= 2
+#if VSIP_IMPL_ABV_VERBOSE >= 2
     std::cout << "(" << rank << ") "
 	      << "src subblock: " << (*cl_cur).src_sb_ << " -> "
 	      << "dst subblock: " << (*cl_cur).dst_sb_ << std::endl
-#if VSIP_IMPL_PCA_VERBOSE >= 3
+#if VSIP_IMPL_ABV_VERBOSE >= 3
 	      << dst_lview((*cl_cur).dst_dom_)
 #endif
       ;
@@ -721,6 +721,6 @@
 
 } // namespace vsip
 
-#undef VSIP_IMPL_PCA_VERBOSE
+#undef VSIP_IMPL_ABV_VERBOSE
 
 #endif // VSIP_CORE_PARALLEL_ASSIGN_BLOCK_VECTOR_HPP
Index: src/vsip/core/parallel/assign_chain.hpp
===================================================================
--- src/vsip/core/parallel/assign_chain.hpp	(revision 156744)
+++ src/vsip/core/parallel/assign_chain.hpp	(working copy)
@@ -48,7 +48,7 @@
 chain_add(
   impl::Chain_builder& builder,
   ExtDataT&            ext,
-  Domain<1> const&    dom)
+  Domain<1> const&     dom)
 {
   typedef typename ExtDataT::element_type element_type;
 
@@ -68,7 +68,7 @@
 chain_add(
   impl::Chain_builder& builder,
   ExtDataT&            ext,
-  Domain<2> const&    dom)
+  Domain<2> const&     dom)
 {
   typedef typename ExtDataT::element_type element_type;
 
@@ -77,7 +77,7 @@
 
   builder.add<element_type>(
               sizeof(element_type) * (dom[dim0].first()*ext.stride(dim0) +
-				    dom[dim1].first()*ext.stride(dim1)),
+				      dom[dim1].first()*ext.stride(dim1)),
 	      dom[dim0].stride() * ext.stride(dim0), dom[dim0].length(),
 	      dom[dim1].stride() * ext.stride(dim1), dom[dim1].length());
 }
@@ -465,9 +465,7 @@
 
 	    if (intersect(src_dom, dst_dom, intr))
 	    {
-	      Index<dim>  offset   = first(intr) - first(src_dom);
-	      Domain<dim> send_dom = domain(first(src_ldom) + offset,
-					    extent(intr));
+	      Domain<dim> send_dom = apply_intr(src_ldom, src_dom, intr);
 
 	      par_chain_assign::chain_add<dst_order_t>(builder, *ext, send_dom);
 
@@ -568,9 +566,7 @@
 	    
 	    if (intersect(dst_dom, src_dom, intr))
 	    {
-	      Index<dim>  offset   = first(intr) - first(dst_dom);
-	      Domain<dim> recv_dom = domain(first(dst_ldom) + offset,
-					    extent(intr));
+	      Domain<dim> recv_dom = apply_intr(dst_ldom, dst_dom, intr);
 	      
 	      par_chain_assign::chain_add<dst_order_t>(builder, *ext, recv_dom);
 	      
@@ -643,14 +639,11 @@
 
 	  if (intersect(src_dom, dst_dom, intr))
 	  {
-	    Index<dim>  send_offset = first(intr) - first(src_dom);
-	    Domain<dim> send_dom    = domain(first(src_ldom) + send_offset,
-					     extent(intr));
-	    Index<dim>  recv_offset = first(intr) - first(dst_dom);
-	    Domain<dim> recv_dom    = domain(first(dst_ldom) + recv_offset,
-					     extent(intr));
+	    Domain<dim> send_dom = apply_intr(src_ldom, src_dom, intr);
+	    Domain<dim> recv_dom = apply_intr(dst_ldom, dst_dom, intr);
 
-	    copy_list.push_back(Copy_record(src_sb, dst_sb, send_dom, recv_dom));
+	    copy_list.push_back(Copy_record(src_sb, dst_sb,
+					    send_dom, recv_dom));
 
 #if VSIP_IMPL_PCA_VERBOSE >= 2
 	    std::cout << "(" << rank << ")"
Index: src/vsip/core/map_fwd.hpp
===================================================================
--- src/vsip/core/map_fwd.hpp	(revision 156744)
+++ src/vsip/core/map_fwd.hpp	(working copy)
@@ -39,6 +39,9 @@
 namespace impl
 {
 
+template <dimension_type Dim>
+class Subset_map;
+
 template <dimension_type Dim,
 	  typename       MapT>
 struct Map_project_1;
Index: src/vsip/map.hpp
===================================================================
--- src/vsip/map.hpp	(revision 156744)
+++ src/vsip/map.hpp	(working copy)
@@ -30,6 +30,7 @@
 
 #include <vsip/core/parallel/global_map.hpp>
 #include <vsip/core/parallel/replicated_map.hpp>
+#include <vsip/core/parallel/subset_map.hpp>
 
 #if VSIP_IMPL_PAR_SERVICE == 1
 #  include <vsip/core/parallel/distributed_block.hpp>
@@ -849,31 +850,22 @@
   assert(sb < data_->num_subblocks_);
   assert(dim_ == Dim);
 
-  Domain<1>  l_dom[VSIP_MAX_DIMENSION];
+  if (this->impl_num_patches(sb) != 1)
+      VSIP_IMPL_THROW(
+	impl::unimplemented(
+	  "Map<>::impl_local_from_global_domain: Subviews have a single patch"));
 
-  index_type dim_sb[VSIP_MAX_DIMENSION];
-  impl::split_tuple(sb, Dim, data_->subblocks_, dim_sb);
+  Domain<Dim> sb_g_dom = this->template impl_global_domain<Dim>(sb, 0);
+  Domain<Dim> sb_l_dom = this->template impl_local_domain<Dim>(sb, 0);
+  Domain<Dim> intr;
 
-  for (dimension_type d=0; d<Dim; ++d)
+  if (impl::intersect(sb_g_dom, g_dom, intr))
   {
-    if (this->num_subblocks(d) == 1)
-      l_dom[d] = g_dom[d];
-    else if (g_dom[d].size() == 1)
-    {
-      index_type g_idx = g_dom[d].first();
-      l_dom[d] = Domain<1>(this->impl_local_from_global_index(d, g_idx));
-    }
-    else if (g_dom[d].size() == dom_[d].size())
-    {
-      l_dom[d] = Domain<1>(impl_subblock_size(d, dim_sb[d]));
-    }
-    else
-      VSIP_IMPL_THROW(
-	impl::unimplemented(
-	  "Map<>: Subviews must not break up distributed dimensions"));
+    Domain<Dim> l_dom = impl::apply_intr(sb_l_dom, sb_g_dom, intr);
+    return l_dom;
   }
-
-  return impl::construct_domain<Dim>(l_dom);
+  else
+    return impl::empty_domain<Dim>();
 }
 
 
@@ -1756,6 +1748,9 @@
   Map subdomain
 ***********************************************************************/
 
+#if 0
+// This functionality is now provided by Subset_map.  Remove after
+// performance is characterized.
 template <dimension_type Dim,
 	  typename       Dist0,
 	  typename       Dist1,
@@ -1807,6 +1802,7 @@
     return sb;
   }
 };
+#endif
 
 
 } // namespace vsip::impl
Index: src/vsip_csl/matlab_utils.hpp
===================================================================
--- src/vsip_csl/matlab_utils.hpp	(revision 156744)
+++ src/vsip_csl/matlab_utils.hpp	(working copy)
@@ -24,10 +24,13 @@
           typename T2,
           typename Block1,
           typename Block2>
-Vector<T2, Block2>
+vsip::Vector<T2, Block2>
 fftshift(
-  const_Vector<T1, Block1> in, Vector<T2, Block2> out)
+  vsip::const_Vector<T1, Block1> in, vsip::Vector<T2, Block2> out)
 {
+  using vsip::length_type;
+  using vsip::Domain;
+
   // This function swaps halves of a vector (dimension
   // must be even).
 
@@ -49,10 +52,13 @@
 	  typename T2,
 	  typename Block1,
 	  typename Block2>
-Matrix<T2, Block2>
+vsip::Matrix<T2, Block2>
 fftshift(
-  const_Matrix<T1, Block1> in, Matrix<T2, Block2> out)
+  vsip::const_Matrix<T1, Block1> in, vsip::Matrix<T2, Block2> out)
 {
+  using vsip::length_type;
+  using vsip::Domain;
+
   // This function swaps quadrants of a matrix (both dimensions
   // must be even) as follows:
   //
@@ -91,22 +97,22 @@
 
 template <typename T1,
           typename Block1>
-Vector<T1>
+vsip::Vector<T1>
 fftshift(
-  const_Vector<T1, Block1> in)
+  vsip::const_Vector<T1, Block1> in)
 {
-  Vector<T1> out(in.size(0));
+  vsip::Vector<T1> out(in.size(0));
   return fftshift(in, out);
 }
 
 
 template <typename T1,
 	  typename Block1>
-Matrix<T1>
+vsip::Matrix<T1>
 fftshift(
-  const_Matrix<T1, Block1> in)
+  vsip::const_Matrix<T1, Block1> in)
 {
-  Matrix<T1> out(in.size(0), in.size(1));
+  vsip::Matrix<T1> out(in.size(0), in.size(1));
   return fftshift(in, out);
 }
 
Index: tests/fftshift.cpp
===================================================================
--- tests/fftshift.cpp	(revision 0)
+++ tests/fftshift.cpp	(revision 0)
@@ -0,0 +1,276 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/fftshift.cpp
+    @author  Jules Bergmann
+    @date    2006-12-08
+    @brief   VSIPL++ Library: Test fftshift, including distributed cases.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <algorithm>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/parallel.hpp>
+#include <vsip/core/metaprogramming.hpp>
+
+#include <vsip_csl/matlab_utils.hpp>
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
+
+using namespace std;
+using namespace vsip;
+
+using vsip_csl::equal;
+using vsip::impl::Int_type;
+
+
+/***********************************************************************
+  Algorithms for fftshift
+***********************************************************************/
+
+// Algorithm #1 -- use stock fftshift from vsip_csl
+
+template <typename T1,
+          typename T2,
+          typename Block1,
+          typename Block2>
+void
+fftshift(
+  const_Matrix<T1, Block1> in,
+  Matrix<T2, Block2>       out,
+  Int_type<1>)
+{
+  vsip_csl::matlab::fftshift(in, out);
+}
+
+
+
+// Algorithm #2 -- process by row
+
+template <typename T1,
+          typename T2,
+          typename Block1,
+          typename Block2>
+void
+fftshift(
+  const_Matrix<T1, Block1> in,
+  Matrix<T2, Block2>       out,
+  Int_type<2>)
+{
+  length_type rows = in.size(0); test_assert(rows == out.size(0));
+  length_type cols = in.size(1); test_assert(cols == out.size(1));
+
+  Domain<1> ldom(0,      1, cols/2);
+  Domain<1> rdom(cols/2, 1, cols/2);
+
+  for (index_type r=0; r<rows; ++r)
+  {
+    index_type xr = (r < rows/2) ? (rows/2 + r) : (r - rows/2);
+    out.row(xr)(ldom) = in.row(r)(rdom);
+    out.row(xr)(rdom) = in.row(r)(ldom);
+  }
+}
+
+
+
+// Algorithm #3 -- process by row/col as guided by output
+
+template <typename T1,
+          typename T2,
+          typename Block1,
+          typename Block2>
+void
+fftshift(
+  const_Matrix<T1, Block1> in,
+  Matrix<T2, Block2>       out,
+  Int_type<3>)
+{
+  length_type rows = in.size(0); test_assert(rows == out.size(0));
+  length_type cols = in.size(1); test_assert(cols == out.size(1));
+
+  // if distributed by row
+  if (out.block().map().num_subblocks(1) == 1)
+  {
+    Domain<1> ldom(0,      1, cols/2);
+    Domain<1> rdom(cols/2, 1, cols/2);
+
+    for (index_type r=0; r<rows; ++r)
+    {
+      index_type xr = (r < rows/2) ? (rows/2 + r) : (r - rows/2);
+      out.row(xr)(ldom) = in.row(r)(rdom);
+      out.row(xr)(rdom) = in.row(r)(ldom);
+    }
+  }
+  else
+  {
+    Domain<1> ldom(0,      1, rows/2);
+    Domain<1> rdom(rows/2, 1, rows/2);
+
+    for (index_type c=0; c<cols; ++c)
+    {
+      index_type xc = (c < cols/2) ? (cols/2 + c) : (c - cols/2);
+      out.col(xc)(ldom) = in.col(c)(rdom);
+      out.col(xc)(rdom) = in.col(c)(ldom);
+    }
+  }
+}
+
+
+
+// Algorithm #4 -- fft shift on root.
+
+template <typename T1,
+          typename T2,
+          typename Block1,
+          typename Block2>
+void
+fftshift(
+  const_Matrix<T1, Block1> in,
+  Matrix<T2, Block2>       out,
+  Int_type<4>)
+{
+  Matrix<T2, Dense<2, T2, row2_type, Map<> > > rin (in.size(0), in.size(1));
+  Matrix<T2, Dense<2, T2, row2_type, Map<> > > rout(out.size(0), out.size(1));
+
+  rin = in;
+  vsip_csl::matlab::fftshift(rin, rout);
+  out = rout;
+}
+
+
+
+/***********************************************************************
+  Test driver
+***********************************************************************/
+
+template <typename T,
+	  int      Impl,
+	  typename MapInT,
+	  typename MapOutT>
+void
+test_fftshift(
+  MapInT&     map_in,
+  MapOutT&    map_out,
+  length_type rows,
+  length_type cols)
+{
+  typedef Dense<2, T, row2_type, MapInT>  in_block_type;
+  typedef Dense<2, T, row2_type, MapOutT> out_block_type;
+  typedef Matrix<T, in_block_type>        in_view_type;
+  typedef Matrix<T, in_block_type>        out_view_type;
+
+  in_view_type  in(rows, cols,  T(-1), map_in);
+  out_view_type out(rows, cols, T(-2), map_out);
+   
+  // setup input.
+  if (subblock(in) != no_subblock)
+  {
+    for (index_type lr=0; lr<in.local().size(0); ++lr)
+      for (index_type lc=0; lc<in.local().size(1); ++lc)
+      {
+	index_type gr = global_from_local_index(in, 0, lr); 
+	index_type gc = global_from_local_index(in, 1, lc); 
+	in.local().put(lr, lc, T(gr*cols + gc));
+      }
+  }
+
+  // shift it.
+  fftshift(in, out, Int_type<Impl>());
+
+  // checkout output.
+  if (subblock(out) != no_subblock)
+  {
+    for (index_type lr=0; lr<out.local().size(0); ++lr)
+      for (index_type lc=0; lc<out.local().size(1); ++lc)
+      {
+	index_type gr = global_from_local_index(out, 0, lr); 
+	index_type gc = global_from_local_index(out, 1, lc); 
+	index_type xr = (gr < rows/2) ? (rows/2 + gr) : (gr - rows/2);
+	index_type xc = (gc < cols/2) ? (cols/2 + gc) : (gc - cols/2);
+	test_assert(equal(out.local().get(lr, lc),
+			  T(xr*cols + xc)));
+      }
+  }
+}
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
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
+  cout << "rank: "   << comm.rank()
+       << "  size: " << comm.size()
+       << "  pid: "  << pid
+       << endl;
+
+  // Stop each process, allow debugger to be attached.
+  if (comm.rank() == 0) fgetc(stdin);
+  comm.barrier();
+  cout << "start\n";
+#endif
+
+  length_type np = num_processors();
+
+
+#if 0
+  // Simple case for debugging.
+  Map<> r_map(np, 1);
+  Map<> c_map(1, np);
+  test_fftshift<float, 1>(r_map, c_map, 256, 256);
+#endif
+
+  // fftshift local views. --------------------------------------------
+
+  Local_map l_map;
+
+  test_fftshift<float, 1>(l_map, l_map, 256, 256);
+  test_fftshift<float, 2>(l_map, l_map, 256, 256);
+  test_fftshift<float, 3>(l_map, l_map, 256, 256);
+
+  // Algorithm #4 only works on distributed views.
+  // test_fftshift<float, 4>(l_map, l_map, 256, 256);
+
+
+
+  // fftshift distributed views ---------------------------------------
+
+  Map<> r_map(np, 1);
+  Map<> c_map(1, np);
+
+  test_fftshift<float, 1>(r_map, r_map, 256, 256);
+  test_fftshift<float, 2>(r_map, r_map, 256, 256);
+  test_fftshift<float, 3>(r_map, r_map, 256, 256);
+  test_fftshift<float, 4>(r_map, r_map, 256, 256);
+
+  test_fftshift<float, 1>(c_map, c_map, 256, 256);
+  test_fftshift<float, 2>(c_map, c_map, 256, 256);
+  test_fftshift<float, 3>(c_map, c_map, 256, 256);
+  test_fftshift<float, 4>(c_map, c_map, 256, 256);
+
+  test_fftshift<float, 1>(r_map, c_map, 256, 256);
+  test_fftshift<float, 2>(r_map, c_map, 256, 256);
+  test_fftshift<float, 3>(r_map, c_map, 256, 256);
+  test_fftshift<float, 4>(r_map, c_map, 256, 256);
+
+  test_fftshift<float, 1>(c_map, r_map, 256, 256);
+  test_fftshift<float, 2>(c_map, r_map, 256, 256);
+  test_fftshift<float, 3>(c_map, r_map, 256, 256);
+  test_fftshift<float, 4>(c_map, r_map, 256, 256);
+}
Index: tests/domain_utils.cpp
===================================================================
--- tests/domain_utils.cpp	(revision 0)
+++ tests/domain_utils.cpp	(revision 0)
@@ -0,0 +1,147 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/domain_utils.cpp
+    @author  Jules Bergmann
+    @date    2006-12-12
+    @brief   VSIPL++ Library: Unit tests for domain utilities.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <algorithm>
+
+#include <vsip/initfin.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/core/domain_utils.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+void
+test_intersect()
+{
+  using vsip::impl::intersect;
+  Domain<1> intr;
+
+  {
+    Domain<1> dom1(0, 1, 10);
+    Domain<1> dom2(5, 1, 7);
+    test_assert(intersect(dom1, dom2, intr));
+    test_assert(intr.first()  == 5);
+    test_assert(intr.stride() == 1);
+    test_assert(intr.size()   == 5);
+  }
+
+  {
+    Domain<1> dom1(0, 1, 10);
+    Domain<1> dom2(10, 1, 8);
+    test_assert(!intersect(dom1, dom2, intr));
+  }
+
+  // test dom2 non-unit-stride cases
+  {
+    Domain<1> dom1(0, 1, 10);
+    Domain<1> dom2(5, 2, 10);
+    test_assert(intersect(dom1, dom2, intr));
+    test_assert(intr.first()  == 5);
+    test_assert(intr.stride() == 2);
+    test_assert(intr.size()   == 3);
+  }
+
+  { // Have to adjust first2 forward (fractional stride)
+    Domain<1> dom1(5, 1, 10); // [   5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
+    Domain<1> dom2(4, 2, 3);  // [4,    6,    8]
+    test_assert(intersect(dom1, dom2, intr));
+    test_assert(intr.first()  == 6);
+    test_assert(intr.stride() == 2);
+    test_assert(intr.size()   == 2);
+  }
+  { // Have to adjust last2 backwards
+    Domain<1> dom1(5, 1, 5);  // [   5, 6, 7, 8, 9]
+    Domain<1> dom2(4, 2, 4);  // [4,    6,    8,    10]
+    test_assert(intersect(dom1, dom2, intr));
+    test_assert(intr.first()  == 6);
+    test_assert(intr.stride() == 2);
+    test_assert(intr.size()   == 2);
+  }
+
+  { // Have to adjust first2 forward (whole stride)
+    Domain<1> dom1(4, 1, 4);  // (pg_dom)            [4, 5, 6, 7]
+    Domain<1> dom2(0, 2, 4);  // (dom)   [0,    2,    4,    6]
+    test_assert(intersect(dom1, dom2, intr));
+    test_assert(intr.first()  == 4);
+    test_assert(intr.stride() == 2);
+    test_assert(intr.size()   == 2);
+  }
+}
+
+
+
+void
+test_subset_from_intr()
+{
+  using vsip::impl::subset_from_intr;
+
+  {
+    Domain<1> dom (0, 1, 4); // [0, 1, 2, 3]
+    Domain<1> intr(2, 1, 2); // [      2, 3]
+    Domain<1> sub = subset_from_intr(dom, intr);
+    test_assert(sub.first()  == 2);
+    test_assert(sub.stride() == 1);
+    test_assert(sub.size()   == 2);
+  }
+
+  {
+    Domain<1> dom (0, 2, 4); // [0,    2,    4,    6]
+    Domain<1> intr(4, 2, 2); // [            4,    6]
+    Domain<1> sub = subset_from_intr(dom, intr);
+    test_assert(sub.first()  == 2);
+    test_assert(sub.stride() == 1);
+    test_assert(sub.size()   == 2);
+  }
+}
+
+
+
+void
+test_apply_intr()
+{
+  using vsip::impl::apply_intr;
+
+  {
+    Domain<1> x   (0, 2, 4);                // [0, 2, 4, 6]
+    Domain<1> y   (0, 1, 4);                // [0, 1, 2, 3]
+    Domain<1> intr(2, 1, 2);                // [      2, 3]
+    Domain<1> app = apply_intr(x, y, intr); // [      4, 6]
+    test_assert(app.first()  == 4);
+    test_assert(app.stride() == 2);
+    test_assert(app.size()   == 2);
+  }
+}
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_intersect();
+  test_subset_from_intr();
+  test_apply_intr();
+}
Index: tests/parallel/subset_map.cpp
===================================================================
--- tests/parallel/subset_map.cpp	(revision 0)
+++ tests/parallel/subset_map.cpp	(revision 0)
@@ -0,0 +1,653 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/parallel/subset_map.cpp
+    @author  Jules Bergmann
+    @date    2006-12-08
+    @brief   VSIPL++ Library: Test for arbitrary distributed subsets.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <algorithm>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/parallel.hpp>
+#include <vsip/core/metaprogramming.hpp>
+
+#include <vsip_csl/matlab_utils.hpp>
+#include <vsip_csl/test.hpp>
+
+#include "util-par.hpp"
+
+#define VERBOSE 1
+
+#if VERBOSE
+#  include <iostream>
+#  include <typeinfo>
+#  include <vsip_csl/output.hpp>
+
+// pull in operator<<'s
+using namespace vsip_csl;
+#endif
+
+
+
+using namespace std;
+using namespace vsip;
+
+using vsip_csl::equal;
+using vsip::impl::Int_type;
+
+
+
+/***********************************************************************
+  Assignment algorithms
+***********************************************************************/
+
+// 1: Standard dispatch
+
+template <typename DstViewT,
+	  typename SrcViewT>
+void
+assign(
+  DstViewT dst,
+  SrcViewT src,
+  Int_type<1>)
+{
+  dst = src;
+}
+
+
+
+// 2: Par_assign
+
+template <typename DstViewT,
+	  typename SrcViewT>
+void
+assign(
+  DstViewT dst,
+  SrcViewT src,
+  Int_type<2>)
+{
+  using vsip::impl::Choose_par_assign_impl;
+  using vsip::impl::Par_assign;
+
+  dimension_type const dim = DstViewT::dim;
+  typedef typename DstViewT::block_type dst_block_type;
+  typedef typename SrcViewT::block_type src_block_type;
+
+  typedef typename
+    Choose_par_assign_impl<dim, dst_block_type, src_block_type, false>::type
+    par_assign_type;
+
+  Par_assign<dim,
+    typename DstViewT::block_type::value_type,
+    typename SrcViewT::block_type::value_type,
+    typename DstViewT::block_type,
+    typename SrcViewT::block_type,
+    par_assign_type> pa(dst, src);
+
+  pa();
+}
+
+
+
+// 3: par_expr
+
+template <typename DstViewT,
+	  typename SrcViewT>
+void
+assign(
+  DstViewT dst,
+  SrcViewT src,
+  Int_type<3>)
+{
+  // The then and else cases are equivalent.
+#if 0
+  par_expr(dst, src);
+#else
+  dimension_type const dim = DstViewT::dim;
+  typedef typename DstViewT::block_type dst_block_type;
+  typedef typename SrcViewT::block_type src_block_type;
+
+  vsip::impl::Par_expr<dim, dst_block_type, src_block_type> pe(dst, src);
+
+  pe();
+#endif
+}
+
+
+
+/***********************************************************************
+  Utilities
+***********************************************************************/
+
+bool
+in_domain(
+  Index<1> const&  idx,
+  Domain<1> const& dom)
+{
+  return   (idx[0] >= dom.first())
+      &&  ((idx[0] - dom.first()) % dom.stride() == 0)
+      && (((idx[0] - dom.first()) / dom.stride()) < dom.length());
+}
+
+bool
+in_domain(
+  Index<2> const&  idx,
+  Domain<2> const& dom)
+{
+  return in_domain(idx[0], dom[0]) && in_domain(idx[1], dom[1]);
+}
+
+
+
+/***********************************************************************
+  Test driver
+***********************************************************************/
+
+template <typename T,
+	  int      Impl,
+	  typename SrcMapT,
+	  typename DstMapT>
+void
+test_src(
+  SrcMapT&         src_map,
+  DstMapT&         dst_map,
+  length_type      rows,
+  length_type      cols,
+  Domain<2> const& src_dom)
+{
+  typedef Dense<2, T, row2_type, SrcMapT> src_block_type;
+  typedef Dense<2, T, row2_type, DstMapT> dst_block_type;
+  typedef Matrix<T, src_block_type>       src_view_type;
+  typedef Matrix<T, dst_block_type>       dst_view_type;
+
+  src_view_type src(rows, cols, T(-1), src_map);
+  dst_view_type dst(src_dom[0].size(), src_dom[1].size(), T(-2), dst_map);
+   
+  // setup input.
+  if (subblock(src) != no_subblock)
+  {
+    for (index_type lr=0; lr<src.local().size(0); ++lr)
+      for (index_type lc=0; lc<src.local().size(1); ++lc)
+      {
+	index_type gr = global_from_local_index(src, 0, lr); 
+	index_type gc = global_from_local_index(src, 1, lc); 
+	src.local().put(lr, lc, T(gr*cols + gc));
+      }
+  }
+
+  assign(dst, src(src_dom), Int_type<Impl>());
+
+  // checkout output.
+  if (subblock(dst) != no_subblock)
+  {
+    for (index_type lr=0; lr<dst.local().size(0); ++lr)
+      for (index_type lc=0; lc<dst.local().size(1); ++lc)
+      {
+	index_type gr = global_from_local_index(dst, 0, lr); 
+	index_type gc = global_from_local_index(dst, 1, lc); 
+	index_type xr = src_dom[0].first() + gr * src_dom[0].stride();
+	index_type xc = src_dom[1].first() + gc * src_dom[1].stride();
+
+	T exp = T(xr*cols + xc);
+#if VERBOSE
+	if (!equal(dst.local().get(lr, lc), exp))
+	{
+	  std::cout << "test_src dst(" << gr << ", " << gc << "; "
+		    << lr << ", " << lc << ") = "
+		    << dst.local().get(lr, lc)
+		    << "  expected " << exp
+		    << std::endl;
+	  std::cout << "Impl: " << Impl << std::endl;
+	  std::cout << "src_dom: " << src_dom << std::endl;
+	  std::cout << "src_map: " << typeid(SrcMapT).name() << std::endl;
+	  std::cout << "dst_map: " << typeid(DstMapT).name() << std::endl;
+	  std::cout << "dst.local():\n" << dst.local() << std::endl;
+	  std::cout << "src.local():\n" << src.local() << std::endl;
+	}
+#endif
+	test_assert(equal(dst.local().get(lr, lc), exp));
+      }
+  }
+}
+
+
+
+template <typename T,
+	  int      Impl,
+	  typename SrcMapT,
+	  typename DstMapT>
+void
+test_dst(
+  SrcMapT&         src_map,
+  DstMapT&         dst_map,
+  length_type      rows,
+  length_type      cols,
+  Domain<2> const& dst_dom)
+{
+  typedef Dense<2, T, row2_type, SrcMapT> src_block_type;
+  typedef Dense<2, T, row2_type, DstMapT> dst_block_type;
+  typedef Matrix<T, src_block_type>       src_view_type;
+  typedef Matrix<T, dst_block_type>       dst_view_type;
+
+  src_view_type src(dst_dom[0].size(), dst_dom[1].size(), T(-1), src_map);
+  dst_view_type dst(rows, cols, T(-2), dst_map);
+   
+  // setup input.
+  if (subblock(src) != no_subblock)
+  {
+    for (index_type lr=0; lr<src.local().size(0); ++lr)
+      for (index_type lc=0; lc<src.local().size(1); ++lc)
+      {
+	index_type gr = global_from_local_index(src, 0, lr); 
+	index_type gc = global_from_local_index(src, 1, lc); 
+	src.local().put(lr, lc, T(gr*cols + gc));
+      }
+  }
+
+  assign(dst(dst_dom), src, Int_type<Impl>());
+
+  // checkout output.
+  if (subblock(dst) != no_subblock)
+  {
+    for (index_type lr=0; lr<dst.local().size(0); ++lr)
+      for (index_type lc=0; lc<dst.local().size(1); ++lc)
+      {
+	index_type gr = global_from_local_index(dst, 0, lr); 
+	index_type gc = global_from_local_index(dst, 1, lc); 
+
+	T exp;
+
+	if (in_domain(Index<2>(gr, gc), dst_dom))
+	{
+	  index_type xr = (gr - dst_dom[0].first()) / dst_dom[0].stride();
+	  index_type xc = (gc - dst_dom[1].first()) / dst_dom[1].stride();
+
+	  exp = T(xr*cols + xc);
+	}
+	else
+	  exp = T(-2);
+
+#if VERBOSE
+	if (!equal(dst.local().get(lr, lc), exp))
+	{
+	  std::cout << "test_dst: dst(" << gr << ", " << gc << ") = "
+		    << dst.local().get(lr, lc)
+		    << "  expected " << exp
+		    << std::endl;
+	}
+#endif
+	test_assert(equal(dst.local().get(lr, lc), exp));
+      }
+  }
+}
+
+
+
+// 1-Dim with subdomains on source and destination
+
+template <typename T,
+	  int      Impl,
+	  typename SrcMapT,
+	  typename DstMapT>
+void
+test_src_dst(
+  SrcMapT&         src_map,
+  DstMapT&         dst_map,
+  length_type      size,
+  Domain<1> const& src_dom,
+  Domain<1> const& dst_dom)
+{
+  typedef Dense<1, T, row1_type, SrcMapT> src_block_type;
+  typedef Dense<1, T, row1_type, DstMapT> dst_block_type;
+  typedef Vector<T, src_block_type>       src_view_type;
+  typedef Vector<T, dst_block_type>       dst_view_type;
+
+  src_view_type src(size, T(-1), src_map);
+  dst_view_type dst(size, T(-3), dst_map);
+
+  dst = T(-2);
+   
+  // setup input.
+  if (subblock(src) != no_subblock)
+  {
+    for (index_type lr=0; lr<src.local().size(0); ++lr)
+    {
+      index_type gr = global_from_local_index(src, 0, lr); 
+      src.local().put(lr, T(gr));
+    }
+  }
+
+  assign(dst(dst_dom), src(src_dom), Int_type<Impl>());
+
+  // checkout output.
+  if (subblock(dst) != no_subblock)
+  {
+    for (index_type lr=0; lr<dst.local().size(0); ++lr)
+    {
+      index_type gr = global_from_local_index(dst, 0, lr); 
+
+      T exp;
+
+      if (in_domain(Index<1>(gr), dst_dom))
+      {
+	index_type xr = (gr - dst_dom[0].first()) / dst_dom[0].stride();
+	
+	xr = xr * src_dom[0].stride() + src_dom[0].first();
+	
+	exp = T(xr);
+      }
+      else
+	exp = T(-2);
+
+#if VERBOSE
+      if (!equal(dst.local().get(lr), exp))
+      {
+	std::cout << "test_src_dst dst(" << gr << "; "
+		  << lr << ") = "
+		  << dst.local().get(lr)
+		  << "  expected " << exp
+		  << std::endl;
+      }
+#endif
+      test_assert(equal(dst.local().get(lr), exp));
+    }
+  }
+}
+
+
+
+// 2-Dim with subdomains on source and destination
+
+template <typename T,
+	  int      Impl,
+	  typename SrcMapT,
+	  typename DstMapT>
+void
+test_src_dst(
+  SrcMapT&         src_map,
+  DstMapT&         dst_map,
+  length_type      rows,
+  length_type      cols,
+  Domain<2> const& src_dom,
+  Domain<2> const& dst_dom)
+{
+  typedef Dense<2, T, row2_type, SrcMapT> src_block_type;
+  typedef Dense<2, T, row2_type, DstMapT> dst_block_type;
+  typedef Matrix<T, src_block_type>       src_view_type;
+  typedef Matrix<T, dst_block_type>       dst_view_type;
+
+  src_view_type src(rows, cols, T(-1), src_map);
+  dst_view_type dst(rows, cols, T(-3), dst_map);
+
+  dst = T(-2);
+   
+  // setup input.
+  if (subblock(src) != no_subblock)
+  {
+    for (index_type lr=0; lr<src.local().size(0); ++lr)
+      for (index_type lc=0; lc<src.local().size(1); ++lc)
+      {
+	index_type gr = global_from_local_index(src, 0, lr); 
+	index_type gc = global_from_local_index(src, 1, lc); 
+	src.local().put(lr, lc, T(gr*cols + gc));
+      }
+  }
+
+  assign(dst(dst_dom), src(src_dom), Int_type<Impl>());
+
+  // checkout output.
+  if (subblock(dst) != no_subblock)
+  {
+    for (index_type lr=0; lr<dst.local().size(0); ++lr)
+      for (index_type lc=0; lc<dst.local().size(1); ++lc)
+      {
+	index_type gr = global_from_local_index(dst, 0, lr); 
+	index_type gc = global_from_local_index(dst, 1, lc); 
+
+	T exp;
+
+	if (in_domain(Index<2>(gr, gc), dst_dom))
+	{
+	  index_type xr = (gr - dst_dom[0].first()) / dst_dom[0].stride();
+	  index_type xc = (gc - dst_dom[1].first()) / dst_dom[1].stride();
+
+	  xr = xr * src_dom[0].stride() + src_dom[0].first();
+	  xc = xc * src_dom[1].stride() + src_dom[1].first();
+
+	  exp = T(xr*cols + xc);
+	}
+	else
+	  exp = T(-2);
+
+#if VERBOSE
+	if (!equal(dst.local().get(lr, lc), exp))
+	{
+	  std::cout << "test_src_dst dst(" << gr << ", " << gc << "; "
+		    << lr << ", " << lc << ") = "
+		    << dst.local().get(lr, lc)
+		    << "  expected " << exp
+		    << std::endl;
+	}
+#endif
+	test_assert(equal(dst.local().get(lr, lc), exp));
+      }
+  }
+}
+
+
+
+struct SrcTag {};
+struct DstTag {};
+
+template <typename T,
+	  typename SrcMapT,
+	  typename DstMapT>
+void
+test_type(
+  SrcTag,
+  SrcMapT&         src_map,
+  DstMapT&         dst_map,
+  length_type      rows,
+  length_type      cols,
+  Domain<2> const& src_dom)
+{
+  test_src<T, 1>(src_map, dst_map, rows, cols, src_dom);
+  test_src<T, 2>(src_map, dst_map, rows, cols, src_dom);
+  test_src<T, 3>(src_map, dst_map, rows, cols, src_dom);
+}
+
+
+
+template <typename T,
+	  typename SrcMapT,
+	  typename DstMapT>
+void
+test_type(
+  DstTag,
+  SrcMapT&         src_map,
+  DstMapT&         dst_map,
+  length_type      rows,
+  length_type      cols,
+  Domain<2> const& dst_dom)
+{
+  test_dst<T, 1>(src_map, dst_map, rows, cols, dst_dom);
+  test_dst<T, 2>(src_map, dst_map, rows, cols, dst_dom);
+  test_dst<T, 3>(src_map, dst_map, rows, cols, dst_dom);
+}
+
+
+
+template <typename T,
+	  typename Tag>
+void
+test_map_combinations()
+{
+  length_type np, nr, nc;
+  get_np_square(np, nr, nc);
+
+  Map<>         root(1, 1);
+  Map<>         r_map(np, 1);
+  Map<>         c_map(1, np);
+  Map<>         x_map(nr, nc);
+  Global_map<2> g_map;
+
+  // coverage tests
+  length_type const n_dom = 8;
+  Domain<2> dom[n_dom];
+
+  dom[0] = Domain<2>(Domain<1>(0,  1, 128), Domain<1>(0, 1, 64));
+  dom[1] = Domain<2>(Domain<1>(64, 1, 128), Domain<1>(32, 1, 64));
+  dom[2] = Domain<2>(Domain<1>(0,  1, 32),  Domain<1>(0,  1, 16));
+  dom[3] = Domain<2>(Domain<1>(64, 1, 32),  Domain<1>(32, 1, 16));
+  dom[4] = Domain<2>(Domain<1>(0,  2, 32),  Domain<1>(0,  2, 16));
+  dom[5] = Domain<2>(Domain<1>(64, 2, 32),  Domain<1>(32, 2, 16));
+  dom[6] = Domain<2>(Domain<1>(0,  1, 32),  Domain<1>(0,  2, 16));
+  dom[7] = Domain<2>(Domain<1>(64, 2, 32),  Domain<1>(32, 1, 16));
+
+  for (index_type i=0; i<n_dom; ++i)
+  {
+    test_type<float>(Tag(), root,   root, 256, 128, dom[i]);
+    test_type<float>(Tag(), r_map,  root, 256, 128, dom[i]);
+    test_type<float>(Tag(), c_map,  root, 256, 128, dom[i]);
+    test_type<float>(Tag(), x_map,  root, 256, 128, dom[i]);
+    test_type<float>(Tag(), g_map,  root, 256, 128, dom[i]);
+    test_type<float>(Tag(), root,  r_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), r_map, r_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), c_map, r_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), x_map, r_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), g_map, r_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), root,  c_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), r_map, c_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), c_map, c_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), x_map, c_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), g_map, c_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), root,  x_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), r_map, x_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), c_map, x_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), x_map, x_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), g_map, x_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), root,  g_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), r_map, g_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), c_map, g_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), x_map, g_map, 256, 128, dom[i]);
+    test_type<float>(Tag(), g_map, g_map, 256, 128, dom[i]);
+  }
+}
+
+
+
+template <typename T,
+	  typename SrcMapT,
+	  typename DstMapT>
+void
+test_src_dst_type(
+  SrcMapT&         src_map,
+  DstMapT&         dst_map,
+  length_type      rows,
+  length_type      cols,
+  Domain<2> const& src_dom,
+  Domain<2> const& dst_dom)
+{
+  test_src_dst<T, 1>(src_map, dst_map, rows, cols, src_dom, dst_dom);
+  test_src_dst<T, 2>(src_map, dst_map, rows, cols, src_dom, dst_dom);
+  test_src_dst<T, 3>(src_map, dst_map, rows, cols, src_dom, dst_dom);
+
+  if (src_map.num_subblocks(1) == 1 && dst_map.num_subblocks(1) == 1)
+  {
+    test_src_dst<T, 1>(src_map, dst_map, rows, src_dom[0], dst_dom[0]);
+    test_src_dst<T, 2>(src_map, dst_map, rows, src_dom[0], dst_dom[0]);
+    test_src_dst<T, 3>(src_map, dst_map, rows, src_dom[0], dst_dom[0]);
+  }
+}
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
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
+  cout << "rank: "   << comm.rank()
+       << "  size: " << comm.size()
+       << "  pid: "  << pid
+       << endl;
+
+  // Stop each process, allow debugger to be attached.
+  if (comm.rank() == 0) fgetc(stdin);
+  comm.barrier();
+  cout << "start\n";
+#endif
+
+  length_type np, nr, nc;
+  get_np_square(np, nr, nc);
+
+  Map<> root(1, 1);
+  Map<> r_map(np, 1);
+  Map<> c_map(1, np);
+  Map<> x_map(nr, nc);
+
+
+#if 1
+  // examples of simple testcases -- easier to debug
+  test_src<float, 2>(root,  r_map, 8, 8,
+		     Domain<2>(Domain<1>(0, 2, 4), Domain<1>(0, 2, 4)));
+  test_src<float, 2>(root,  r_map, 8, 8,
+		     Domain<2>(Domain<1>(0, 1, 4), Domain<1>(0, 2, 4)));
+  test_src<float, 2>(root,  r_map, 8, 8,
+		     Domain<2>(Domain<1>(0, 1, 4), Domain<1>(0, 1, 4)));
+#endif
+
+#if 1
+  test_map_combinations<float, SrcTag>();
+  test_map_combinations<float, DstTag>();
+
+  // coverage tests
+  length_type const n_dom = 8;
+  Domain<2> dom[n_dom];
+
+  dom[0] = Domain<2>(Domain<1>(0,  1, 128), Domain<1>(0, 1, 64));
+  dom[1] = Domain<2>(Domain<1>(64, 1, 128), Domain<1>(32, 1, 64));
+  dom[2] = Domain<2>(Domain<1>(0,  1, 32),  Domain<1>(0,  1, 16));
+  dom[3] = Domain<2>(Domain<1>(64, 1, 32),  Domain<1>(32, 1, 16));
+  dom[4] = Domain<2>(Domain<1>(0,  2, 32),  Domain<1>(0,  2, 16));
+  dom[5] = Domain<2>(Domain<1>(64, 2, 32),  Domain<1>(32, 2, 16));
+  dom[6] = Domain<2>(Domain<1>(0,  1, 32),  Domain<1>(0,  2, 16));
+  dom[7] = Domain<2>(Domain<1>(64, 2, 32),  Domain<1>(32, 1, 16));
+
+  for (index_type i=0; i<n_dom; i+=2)
+  {
+    test_src_dst_type<float>(root,   root, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(r_map,  root, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(c_map,  root, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(x_map,  root, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(root,  r_map, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(r_map, r_map, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(c_map, r_map, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(x_map, r_map, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(root,  c_map, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(r_map, c_map, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(c_map, c_map, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(x_map, c_map, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(root,  x_map, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(r_map, x_map, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(c_map, x_map, 256, 128, dom[i], dom[i+1]);
+    test_src_dst_type<float>(x_map, x_map, 256, 128, dom[i], dom[i+1]);
+  }
+#endif
+}
