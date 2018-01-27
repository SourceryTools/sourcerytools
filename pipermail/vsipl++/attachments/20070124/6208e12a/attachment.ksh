Index: ChangeLog
===================================================================
--- ChangeLog	(revision 161053)
+++ ChangeLog	(working copy)
@@ -1,3 +1,21 @@
+2007-01-24  Jules Bergmann  <jules@codesourcery.com>
+
+	Fix bug when taking subset view of a subset view.
+	* src/vsip/core/view_traits.hpp: Move forward declarations of views
+	  to ...
+	* src/vsip/core/view_fwd.hpp: ... here (New file).
+	* src/vsip/core/subblock.hpp (Subset_block_map): Pass map subset
+	  logic down to Map_subdomain for all map types.
+	* src/vsip/core/parallel/subset_map.hpp: Move class decl into ...
+	* src/vsip/core/parallel/subset_map_decl.hpp: ... here (New file) 
+	  (Map_subdomain): Provide general defn, and specialization for
+	  Subset_map.
+	* tests/regressions/subset.cpp: New file, regression test for
+	  subset of a subset.
+
+	* src/vsip/opt/ipp/fir.hpp: Fix bug when mirroring kernels
+	  with symmetry.
+	
 2007-01-24  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* src/vsip/core/vsip.hpp: New 'include all' header.
Index: src/vsip/core/view_traits.hpp
===================================================================
--- src/vsip/core/view_traits.hpp	(revision 161053)
+++ src/vsip/core/view_traits.hpp	(working copy)
@@ -15,7 +15,7 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
-#include <vsip/dense.hpp>
+#include <vsip/core/view_fwd.hpp>
 #include <vsip/core/subblock.hpp>
 #include <complex>
 
@@ -64,19 +64,6 @@
 
 } // impl
 
-template <typename T = VSIP_DEFAULT_VALUE_TYPE,
-	  typename B = Dense<1, T> > struct Vector;
-template <typename T = VSIP_DEFAULT_VALUE_TYPE,
-	  typename B = Dense<2, T> > struct Matrix;
-template <typename T = VSIP_DEFAULT_VALUE_TYPE,
-	  typename B = Dense<3, T> > struct Tensor;
-template <typename T = VSIP_DEFAULT_VALUE_TYPE,
-	  typename B = Dense<1, T> > struct const_Vector;
-template <typename T = VSIP_DEFAULT_VALUE_TYPE,
-	  typename B = Dense<2, T> > struct const_Matrix;
-template <typename T = VSIP_DEFAULT_VALUE_TYPE,
-	  typename B = Dense<3, T> > struct const_Tensor;
-
 namespace impl
 {
 
Index: src/vsip/core/view_fwd.hpp
===================================================================
--- src/vsip/core/view_fwd.hpp	(revision 0)
+++ src/vsip/core/view_fwd.hpp	(revision 0)
@@ -0,0 +1,37 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/view_fwd.hpp
+    @author  Jules Bergmann
+    @date    2007-01-14
+    @brief   VSIPL++ Library: Forward declarations for Views.
+
+*/
+
+#ifndef VSIP_CORE_VIEW_FWD_HPP
+#define VSIP_CORE_VIEW_FWD_HPP
+
+#include <vsip/core/dense_fwd.hpp>
+
+/***********************************************************************
+  Forward Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+template <typename T = VSIP_DEFAULT_VALUE_TYPE,
+	  typename B = Dense<1, T> > struct Vector;
+template <typename T = VSIP_DEFAULT_VALUE_TYPE,
+	  typename B = Dense<2, T> > struct Matrix;
+template <typename T = VSIP_DEFAULT_VALUE_TYPE,
+	  typename B = Dense<3, T> > struct Tensor;
+template <typename T = VSIP_DEFAULT_VALUE_TYPE,
+	  typename B = Dense<1, T> > struct const_Vector;
+template <typename T = VSIP_DEFAULT_VALUE_TYPE,
+	  typename B = Dense<2, T> > struct const_Matrix;
+template <typename T = VSIP_DEFAULT_VALUE_TYPE,
+	  typename B = Dense<3, T> > struct const_Tensor;
+
+} // namespace vsip
+
+#endif // VSIP_CORE_VIEW_FWD_HPP
Index: src/vsip/core/subblock.hpp
===================================================================
--- src/vsip/core/subblock.hpp	(revision 161053)
+++ src/vsip/core/subblock.hpp	(working copy)
@@ -41,6 +41,7 @@
 #include <vsip/core/noncopyable.hpp>
 #include <vsip/core/domain_utils.hpp>
 #include <vsip/core/parallel/local_map.hpp>
+#include <vsip/core/parallel/subset_map_decl.hpp>
 #include <complex>
 
 /***********************************************************************
@@ -227,36 +228,19 @@
 	  typename       MapT>
 struct Subset_block_map
 {
-  typedef MapT type;
-  static type convert_map(MapT const& map, Domain<Dim> const&) { return map; }
-};
+  typedef typename Map_subdomain<Dim, MapT>::type type;
 
-// Subset_block_map primary definition works for:
-//  - Global_map<Dim>
-//  - Local_map
-
-
-
-template <dimension_type Dim,
-	  typename       Dist0,
-          typename       Dist1,
-          typename       Dist2>
-struct Subset_block_map<Dim, Map<Dist0, Dist1, Dist2> >
-{
-  typedef typename Map_subdomain<Dim, Map<Dist0, Dist1, Dist2> >::type type;
-
-  static type convert_map(Map<Dist0, Dist1, Dist2> const& map,
-			  Domain<Dim> const&              dom)
+  static type convert_map(MapT const&        map,
+			  Domain<Dim> const& dom)
   {
-    return Map_subdomain<Dim, Map<Dist0, Dist1, Dist2> >::project(map, dom);
+    return Map_subdomain<Dim, MapT>::project(map, dom);
   }
 
-  static index_type parent_subblock(Map<Dist0, Dist1, Dist2> const& map,
-				    Domain<Dim> const&              dom,
-				    index_type                      sb)
+  static index_type parent_subblock(MapT const&        map,
+				    Domain<Dim> const& dom,
+				    index_type         sb)
   {
-    return Map_subdomain<Dim, Map<Dist0, Dist1, Dist2> >
-      ::parent_subblock(map, dom, sb);
+    return Map_subdomain<Dim, MapT>::parent_subblock(map, dom, sb);
   }
 };
 
Index: src/vsip/core/parallel/subset_map_decl.hpp
===================================================================
--- src/vsip/core/parallel/subset_map_decl.hpp	(revision 0)
+++ src/vsip/core/parallel/subset_map_decl.hpp	(revision 0)
@@ -0,0 +1,368 @@
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/parallel/subset_map_decl.hpp
+    @author  Jules Bergmann
+    @date    2006-12-10
+    @brief   VSIPL++ Library: Map class for distributed subsets.
+
+*/
+
+#ifndef VSIP_CORE_PARALLEL_SUBSET_MAP_DECL_HPP
+#define VSIP_CORE_PARALLEL_SUBSET_MAP_DECL_HPP
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
+  const_Vector<processor_type> processor_set() const;
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
+	  typename       MapT>
+struct Map_subdomain
+{
+  typedef MapT type;
+
+  static type project(
+    MapT const&        map,
+    Domain<Dim> const& /*dom*/)
+  {
+    return map;
+  }
+
+  // Return the parent subblock corresponding to a child subblock.
+  static index_type parent_subblock(
+    MapT const&        map,
+    Domain<Dim> const& /*dom*/,
+    index_type         sb)
+  {
+    assert(0);
+    return sb;
+  }
+};
+
+
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
+
+template <dimension_type Dim>
+struct Map_subdomain<Dim, Subset_map<Dim> >
+{
+  typedef Subset_map<Dim> type;
+
+  static type project(
+    Subset_map<Dim> const& map,
+    Domain<Dim> const&     dom)
+  {
+    return type(map, dom);
+  }
+
+  // Return the parent subblock corresponding to a child subblock.
+  static index_type parent_subblock(
+    Subset_map<Dim> const& map,
+    Domain<Dim> const&     /*dom*/,
+    index_type             sb)
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
+#endif // VSIP_CORE_PARALLEL_SUBSET_MAP_DECL_HPP
Index: src/vsip/core/parallel/subset_map.hpp
===================================================================
--- src/vsip/core/parallel/subset_map.hpp	(revision 161053)
+++ src/vsip/core/parallel/subset_map.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/core/parallel/subset_map.hpp
     @author  Jules Bergmann
@@ -14,8 +14,11 @@
   Included Files
 ***********************************************************************/
 
+#include <vsip/core/parallel/subset_map_decl.hpp>
+#include <vsip/vector.hpp>
 
 
+
 /***********************************************************************
   Declarations & Class Definitions
 ***********************************************************************/
@@ -26,297 +29,17 @@
 {
 
 template <dimension_type Dim>
-class Subset_map
+const_Vector<processor_type>
+Subset_map<Dim>::processor_set() const
 {
-  // Compile-time typedefs.
-public:
-  typedef impl::Value_iterator<processor_type, unsigned> processor_iterator;
-  typedef std::vector<processor_type> impl_pvec_type;
+  Vector<processor_type> pset(this->num_processors());
 
-  // Constructor.
-public:
-  template <typename MapT>
-  Subset_map(MapT const&, Domain<Dim> const&);
+  for (index_type i=0; i<this->num_processors(); ++i)
+    pset.put(i, this->pvec_[i]);
 
-  ~Subset_map()
-    {}
-
-
-  // Accessors.
-public:
-  // Information on individual distributions.
-  distribution_type distribution     (dimension_type) const VSIP_NOTHROW
-    { return other; }
-  length_type       num_subblocks    (dimension_type) const VSIP_NOTHROW
-    { return 1; }
-  length_type       cyclic_contiguity(dimension_type) const VSIP_NOTHROW
-    { return 0; }
-
-  length_type num_subblocks()  const VSIP_NOTHROW
-    { return sb_patch_gd_.size(); }
-
-  length_type num_processors() const VSIP_NOTHROW
-    { return pvec_.size(); }
-
-  index_type subblock(processor_type pr) const VSIP_NOTHROW
-  {
-    index_type pi = impl_rank_from_proc(pr);
-
-    if (pi != no_rank && pi < this->num_subblocks())
-      return pi;
-    else
-      return no_subblock;
-  }
-
-  index_type subblock() const VSIP_NOTHROW
-  {
-    processor_type pr = local_processor();
-    return this->subblock(pr);
-  }
-
-  processor_iterator processor_begin(index_type sb) const VSIP_NOTHROW
-  {
-    assert(sb < this->num_subblocks());
-    return processor_iterator(this->pvec_[sb], 1);
-  }
-
-  processor_iterator processor_end  (index_type sb) const VSIP_NOTHROW
-  {
-    assert(sb < this->num_subblocks());
-    return processor_iterator(this->pvec_[sb]+1, 1);
-  }
-
-  const_Vector<processor_type> processor_set() const
-  {
-    Vector<processor_type> pset(this->num_processors());
-
-    for (index_type i=0; i<this->num_processors(); ++i)
-      pset.put(i, this->pvec_[i]);
-
-    return pset;
-  }
-
-  // Applied map functions.
-public:
-  length_type impl_num_patches(index_type sb) const VSIP_NOTHROW
-  {
-    assert(sb < this->num_subblocks());
-    return sb_patch_gd_[sb].size();
-  }
-
-  void impl_apply(Domain<Dim> const& dom) VSIP_NOTHROW
-  {
-    assert(extent(dom_) == extent(dom));
-    impl::create_ll_pset(pvec_, ll_pset_);
-  }
-
-  template <dimension_type Dim2>
-  Domain<Dim2> impl_subblock_domain(index_type sb) const VSIP_NOTHROW
-    { assert(sb < this->num_subblocks()); return domain(sb_ext_[sb]); }
-
-  template <dimension_type Dim2>
-  impl::Length<Dim2> impl_subblock_extent(index_type sb) const VSIP_NOTHROW
-    { assert(sb < this->num_subblocks()); return sb_ext_[sb]; }
-
-  template <dimension_type Dim2>
-  Domain<Dim2> impl_global_domain(index_type sb, index_type p)
-    const VSIP_NOTHROW
-  {
-    assert(sb < this->num_subblocks());
-    assert(p  < this->impl_num_patches(sb));
-    return sb_patch_gd_[sb][p];
-  }
-
-  template <dimension_type Dim2>
-  Domain<Dim2> impl_local_domain (index_type sb, index_type p)
-    const VSIP_NOTHROW
-  {
-    assert(sb < this->num_subblocks());
-    assert(p  < this->impl_num_patches(sb));
-    return sb_patch_ld_[sb][p];
-  }
-
-  template <dimension_type Dim2>
-  Domain<Dim2> impl_parent_local_domain(index_type sb) const VSIP_NOTHROW
-  { return parent_sdom_[sb]; }
-
-  index_type impl_global_from_local_index(dimension_type /*d*/, index_type sb,
-				     index_type idx)
-    const VSIP_NOTHROW
-  {
-    VSIP_IMPL_THROW(impl::unimplemented(
-	      "Subset_map::impl_global_from_local_index not implemented."));
-    return 0;
-  }
-
-  index_type impl_local_from_global_index(dimension_type /*d*/, index_type idx)
-    const VSIP_NOTHROW
-  {
-    VSIP_IMPL_THROW(impl::unimplemented(
-	      "Subset_map::impl_local_from_global_index not implemented."));
-    return 0;
-  }
-
-  template <dimension_type Dim2>
-  index_type impl_subblock_from_global_index(Index<Dim2> const& /*idx*/)
-    const VSIP_NOTHROW
-  {
-    VSIP_IMPL_THROW(impl::unimplemented(
-	      "Subset_map::impl_subblock_from_global_index not implemented."));
-    return 0;
-  }
-
-  template <dimension_type Dim2>
-  Domain<Dim> impl_local_from_global_domain(index_type /*sb*/,
-					    Domain<Dim2> const& dom)
-    const VSIP_NOTHROW
-  {
-    VSIP_IMPL_STATIC_ASSERT(Dim == Dim2);
-    VSIP_IMPL_THROW(impl::unimplemented(
-	      "Subset_map::impl_local_from_global_domain not implemented."));
-    return Domain<Dim>();
-  }
-
-  // Extensions.
-public:
-  impl::par_ll_pset_type impl_ll_pset() const VSIP_NOTHROW
-    { return ll_pset_; }
-  impl::Communicator&    impl_comm() const
-    { return impl::default_communicator(); }
-  impl_pvec_type const&  impl_pvec() const
-    { return pvec_; }
-
-  length_type            impl_working_size() const
-    { return this->num_processors(); }
-
-  processor_type         impl_proc_from_rank(index_type idx) const
-    { return this->impl_pvec()[idx]; }
-
-  index_type impl_rank_from_proc(processor_type pr) const
-  {
-    for (index_type i=0; i<this->num_processors(); ++i)
-      if (this->impl_pvec()[i] == pr) return i;
-    return no_rank;
-  }
-
-  // Determine parent map subblock corresponding to this map's subblock
-  index_type impl_parent_subblock(index_type sb) const
-    { return parent_sb_[sb]; }
-
-public:
-  typedef std::vector<Domain<Dim> >   p_vector_type;
-  typedef std::vector<p_vector_type>  sb_vector_type;
-
-
-  // Member data.
-private:
-  std::vector<index_type>   parent_sb_; // map: local sb -> parent sb
-  std::vector<Length<Dim> > sb_ext_;
-  std::vector<Domain<Dim> > parent_sdom_;	// parent subblock dom.
-  sb_vector_type            sb_patch_gd_;	// subblock-patch global dom
-  sb_vector_type            sb_patch_ld_;	// subblock-patch local dom
-
-  impl_pvec_type            pvec_;		// Grid function.
-  Domain<Dim>               dom_;		// Applied domain.
-  impl::par_ll_pset_type    ll_pset_;
-};
-
-
-
-template <dimension_type Dim>
-template <typename MapT>
-Subset_map<Dim>::Subset_map(
-  MapT const&        map,
-  Domain<Dim> const& dom)
-  : dom_(dom)
-{
-  // Check that map is only block distributed
-  for (dimension_type d = 0; d<Dim; ++d)
-  {
-    if (map.distribution(d) == cyclic)
-      VSIP_IMPL_THROW(impl::unimplemented(
-	      "Subset_map: Subviews of cyclic maps not supported."));
-  }
-
-  for (index_type sb=0; sb<map.num_subblocks(); ++sb)
-  {
-    p_vector_type g_vec;
-    p_vector_type l_vec;
-    
-    for (index_type p=0; p<map.impl_num_patches(sb); ++p)
-    {
-      // parent global/local subdomains for sb-p.
-      Domain<Dim> pg_dom = map.template impl_global_domain<Dim>(sb, p);
-      Domain<Dim> pl_dom = map.template impl_local_domain<Dim>(sb, p);
-
-      Domain<Dim> intr;
-      if (intersect(pg_dom, dom, intr))
-      {
-	// my global/local subdomains for sb-p.
-	Domain<Dim> ml_dom = apply_intr(pl_dom, pg_dom, intr);
-	Domain<Dim> mg_dom = subset_from_intr(dom, intr);
-
-	g_vec.push_back(mg_dom);
-	l_vec.push_back(ml_dom);
-      }
-    }
-
-    if (g_vec.size() > 0)
-    {
-      sb_patch_gd_.push_back(g_vec);
-      sb_patch_ld_.push_back(l_vec);
-      pvec_.push_back(map.impl_proc_from_rank(sb));
-
-      Length<Dim> par_sb_ext = map.template impl_subblock_extent<Dim>(sb);
-      Length<Dim> sb_ext     = par_sb_ext;
-      parent_sdom_.push_back(domain(par_sb_ext));
-      sb_ext_.push_back(sb_ext);
-      parent_sb_.push_back(sb);
-    }
-  }
+  return pset;
 }
 
-
-
-/// Specialize global traits for Global_map.
-
-template <dimension_type Dim>
-struct Is_global_map<Subset_map<Dim> >
-{ static bool const value = true; };
-
-
-
-/***********************************************************************
-  Map subdomain
-***********************************************************************/
-
-template <dimension_type Dim,
-	  typename       Dist0,
-	  typename       Dist1,
-	  typename       Dist2>
-struct Map_subdomain<Dim, Map<Dist0, Dist1, Dist2> >
-{
-  typedef Subset_map<Dim> type;
-
-  static type project(
-    Map<Dist0, Dist1, Dist2> const& map,
-    Domain<Dim> const&              dom)
-  {
-    return type(map, dom);
-  }
-
-  // Return the parent subblock corresponding to a child subblock.
-  static index_type parent_subblock(
-    Map<Dist0, Dist1, Dist2> const& map,
-    Domain<Dim> const&              /*dom*/,
-    index_type                      sb)
-  {
-    assert(0);
-    return sb;
-  }
-};
-
-
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/opt/ipp/fir.hpp
===================================================================
--- src/vsip/opt/ipp/fir.hpp	(revision 161053)
+++ src/vsip/opt/ipp/fir.hpp	(working copy)
@@ -98,7 +98,7 @@
     Vector<T> tmp(kernel_block);
     this->kernel_(Domain<1>(k)) = tmp;
     if (S != nonsym)
-      this->kernel_(Domain<1>(k - 1, -1, k)) = tmp;
+      this->kernel_(Domain<1>(this->order_, -1, k)) = tmp;
     kernel_block.release(false);
   }
 
Index: tests/regressions/subset.cpp
===================================================================
--- tests/regressions/subset.cpp	(revision 0)
+++ tests/regressions/subset.cpp	(revision 0)
@@ -0,0 +1,84 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    regressions/subset.cpp
+    @author  Jules Bergmann
+    @date    2007-01-13
+    @brief   VSIPL++ Library: Test subset of a subset.
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
+#include <vsip/vector.hpp>
+#include <vsip/parallel.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+using vsip_csl::equal;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+
+template <typename MapT,
+	  typename T>
+void
+test_subset()
+{
+
+  typedef Dense<1, T, row1_type, MapT> block_type;
+  typedef Vector<T, block_type> view_type;
+
+  typedef typename view_type::subview_type    subset1_type;
+  typedef typename subset1_type::subview_type subset2_type;
+
+  length_type size = 16;
+
+  view_type view(size);
+  for (index_type i=0; i<size; ++i)
+    view.put(i, T(i));
+
+  subset1_type sub1 = view(Domain<1>(4, 1, 8));
+  subset2_type sub2 = sub1(Domain<1>(2, 1, 4));
+
+  for (index_type i=0; i<4; ++i)
+    test_assert(equal(sub2.get(i), T(4+2+i)));
+}
+
+
+
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
+  // [1] Subset of a Subset_map was erroneously using the parent map
+  //     for the subset.
+
+  test_subset<Local_map, float>(); // OK
+  test_subset<Map<>, float>(); // [1]
+  test_subset<Global_map<1>, float>(); // OK
+
+  return 0;
+}
