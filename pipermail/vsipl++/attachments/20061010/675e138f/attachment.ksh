Index: ChangeLog
===================================================================
--- ChangeLog	(revision 150732)
+++ ChangeLog	(working copy)
@@ -1,3 +1,22 @@
+2006-10-10  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/replicated_map.hpp (impl_local_from_global_domain):
+	  New function to translate local to global domain for map.
+	* src/vsip/impl/global_map.hpp (impl_local_from_global_domain):
+	  likewise.
+	  (impl_rank_from_proc): New function to translate rank into
+	  processor.
+	* src/vsip/impl/subblock.hpp: Handle empty domain when checking
+	  that a subblock's domain is a subset of the parent's domain.
+	  Handle empty subblock case when creating local block for 
+	  distributed subblock (case exercised by matrix_subviews.cpp).
+	* src/vsip/impl/par-services-mpi.hpp: Add MPI_Datatype for char.
+	* tests/test_common.hpp: use separate macros to enable VERBOSE
+	  checking from show functions.
+	* tests/complex.cpp: Initialize library.
+	* tests/parallel/matrix_subviews.cpp: New file, tests
+	  distributed matrix matrix subview cases.
+	
 2006-10-05  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* configure.ac: Let configure only check for python if scripting is
Index: src/vsip/impl/replicated_map.hpp
===================================================================
--- src/vsip/impl/replicated_map.hpp	(revision 150719)
+++ src/vsip/impl/replicated_map.hpp	(working copy)
@@ -163,6 +163,15 @@
     const VSIP_NOTHROW
   { return 0; }
 
+  template <dimension_type Dim2>
+  Domain<Dim> impl_local_from_global_domain(index_type /*sb*/,
+					    Domain<Dim2> const& dom)
+    const VSIP_NOTHROW
+  {
+    VSIP_IMPL_STATIC_ASSERT(Dim == Dim2);
+    return dom;
+  }
+
   // Extensions.
 public:
   impl::par_ll_pset_type impl_ll_pset() const VSIP_NOTHROW
Index: src/vsip/impl/par-services-mpi.hpp
===================================================================
--- src/vsip/impl/par-services-mpi.hpp	(revision 150719)
+++ src/vsip/impl/par-services-mpi.hpp	(working copy)
@@ -70,6 +70,7 @@
   static MPI_Datatype value() { return MPITYPE; }			\
 };
 
+VSIP_IMPL_MPIDATATYPE(char,           MPI_CHAR)
 VSIP_IMPL_MPIDATATYPE(short,          MPI_SHORT)
 VSIP_IMPL_MPIDATATYPE(int,            MPI_INT)
 VSIP_IMPL_MPIDATATYPE(long,           MPI_LONG)
Index: src/vsip/impl/subblock.hpp
===================================================================
--- src/vsip/impl/subblock.hpp	(revision 150719)
+++ src/vsip/impl/subblock.hpp	(working copy)
@@ -287,11 +287,12 @@
       map_ (map_functor::convert_map(blk.map(), dom_))
   {
     // Sanity check that all of the Domain indices are within the
-    // underlying block's range.
+    // underlying block's range.  (If domain is empty, value
+    // returned by impl_last() is not valid.)
     for (dimension_type d = 0; d < dim; d++)
     {
-      assert(dom_[d].first() < blk_->size(dim, d));
-      assert(dom_[d].impl_last() < blk_->size(dim, d));
+      assert(dom_[d].size() == 0 || dom_[d].first() < blk_->size(dim, d));
+      assert(dom_[d].size() == 0 || dom_[d].impl_last() < blk_->size(dim, d));
     }
     map_.impl_apply(block_domain<dim>(*this));
   }
@@ -1383,10 +1384,13 @@
   dimension_type const dim = Subset_block<Block>::dim;
 
   index_type sb = block.map().impl_rank_from_proc(local_processor());
+  Domain<dim> dom;
 
-  Domain<dim> dom = block.impl_block().map().
-    impl_local_from_global_domain(sb,
-				  block.impl_domain());
+  if (sb != no_subblock)
+    dom = block.impl_block().map().impl_local_from_global_domain(sb,
+					block.impl_domain());
+  else
+    dom = empty_domain<dim>();
 
   typename View_block_storage<super_type>::plain_type
     super_block = get_local_block(block.impl_block());
Index: src/vsip/impl/global_map.hpp
===================================================================
--- src/vsip/impl/global_map.hpp	(revision 150719)
+++ src/vsip/impl/global_map.hpp	(working copy)
@@ -120,6 +120,15 @@
     const VSIP_NOTHROW
   { return 0; }
 
+  template <dimension_type Dim2>
+  Domain<Dim> impl_local_from_global_domain(index_type /*sb*/,
+					    Domain<Dim2> const& dom)
+    const VSIP_NOTHROW
+  {
+    VSIP_IMPL_STATIC_ASSERT(Dim == Dim2);
+    return dom;
+  }
+
   // Extensions.
 public:
   impl::par_ll_pset_type impl_ll_pset() const VSIP_NOTHROW
@@ -135,6 +144,13 @@
   processor_type         impl_proc_from_rank(index_type idx) const
     { return this->impl_pvec()[idx]; }
 
+  index_type impl_rank_from_proc(processor_type pr) const
+  {
+    for (index_type i=0; i<this->num_processors(); ++i)
+      if (this->impl_pvec()[i] == pr) return i;
+    return no_rank;
+  }
+
   // Member data.
 private:
   Domain<Dim> dom_;
Index: tests/test_common.hpp
===================================================================
--- tests/test_common.hpp	(revision 150719)
+++ tests/test_common.hpp	(working copy)
@@ -19,10 +19,11 @@
 #include <vsip/vector.hpp>
 #include <vsip/map.hpp>
 
-#define VERBOSE   0
-#define DO_ASSERT 1
+#define VERBOSE      0
+#define DO_ASSERT    1
+#define PROVIDE_SHOW 0
 
-#if VERBOSE
+#if VERBOSE || PROVIDE_SHOW
 #  include <iostream>
 #endif
 
@@ -228,6 +229,7 @@
 
 
 
+#if PROVIDE_SHOW
 template <typename T,
 	  typename BlockT>
 void
@@ -284,6 +286,7 @@
     std::cout << "[" << vsip::local_processor() << "] "
 	      << "show: no local subblock\n";
 }
+#endif
 
 #undef VERBOSE
 
Index: tests/complex.cpp
===================================================================
--- tests/complex.cpp	(revision 150719)
+++ tests/complex.cpp	(working copy)
@@ -13,6 +13,7 @@
   Included Files
 ***********************************************************************/
 
+#include <vsip/initfin.hpp>
 #include <vsip/complex.hpp>
 
 #include <vsip_csl/test.hpp>
@@ -328,8 +329,10 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   test_using_both::test();
   test_using_vsip::test();
   test_using_std::test();
Index: tests/parallel/matrix_subviews.cpp
===================================================================
--- tests/parallel/matrix_subviews.cpp	(revision 0)
+++ tests/parallel/matrix_subviews.cpp	(revision 0)
@@ -0,0 +1,105 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    tests/parallel/matrix_subviews.cpp
+    @author  Jules Bergmann
+    @date    2006-10-10
+    @brief   VSIPL++ Library: Unit tests for distributed matrix subviews.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/map.hpp>
+#include <vsip/math.hpp>
+#include <vsip/parallel.hpp>
+
+#include <vsip_csl/test.hpp>
+#include "util.hpp"
+#include "util-par.hpp"
+#include "test_common.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+
+/***********************************************************************
+  Test subviews of distributed matrix
+***********************************************************************/
+
+template <typename T,
+	  typename MapT,
+	  typename SubMapT>
+void
+test_matrix_subview(
+  Domain<2> const& dom,
+  Domain<2> const& sub_dom,
+  MapT const&      map,
+  SubMapT const&   sub_map)
+{
+  typedef Dense<2, T, row2_type, MapT>    block_t;
+  typedef Matrix<T, block_t>              view_t;
+
+  typedef Dense<2, T, row2_type, SubMapT> sub_block_t;
+  typedef Matrix<T, sub_block_t>          sub_view_t;
+
+  int k = 1;
+
+  // Setup.
+  view_t     view   (create_view<view_t>    (dom,     map));
+  sub_view_t subview(create_view<sub_view_t>(sub_dom, sub_map));
+
+  setup(view, k);
+
+  // Take subview.
+  subview = view(sub_dom);
+
+  // Check.
+  check(subview, k, sub_dom[0].first(), sub_dom[1].first());
+}
+
+
+
+void test1()
+{
+  length_type np, nr, nc;
+
+  get_np_square(np, nr, nc);
+
+  Map<> root_map;
+  Map<> rc_map(nr, nc);
+  Replicated_map<2> rep_map;
+  Global_map<2> global_map;
+
+  Domain<2> dom(10, 10);
+  Domain<2> sub_dom(Domain<1>(2, 1, 6), Domain<1>(4, 1, 5));
+
+  // 061010: SV++ does not support matrix subviews across a
+  // distributed dimension.  I.e. 'map' (the 1st map argument) must be
+  // either mapped to a single processor, or replicated.
+
+  test_matrix_subview<float>(dom, sub_dom, root_map, root_map);
+  test_matrix_subview<float>(dom, sub_dom, root_map, rc_map);
+
+  test_matrix_subview<float>(dom, sub_dom, rep_map, root_map);
+  test_matrix_subview<float>(dom, sub_dom, rep_map, rc_map);
+
+  test_matrix_subview<float>(dom, sub_dom, global_map, root_map);
+  test_matrix_subview<float>(dom, sub_dom, global_map, rc_map);
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl vpp(argc, argv);
+
+  test1();
+
+  return 0;
+}
