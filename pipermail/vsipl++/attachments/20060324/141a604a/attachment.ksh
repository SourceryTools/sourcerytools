Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.420
diff -u -r1.420 ChangeLog
--- ChangeLog	24 Mar 2006 12:36:05 -0000	1.420
+++ ChangeLog	24 Mar 2006 18:55:40 -0000
@@ -1,5 +1,62 @@
 2006-03-24  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/dense.hpp: Rename implementation par support functions
+	  with impl_ prefix.
+	* src/vsip/impl/distributed-block.hpp: Likewise.
+	* src/vsip/map.hpp: Rename implementation par support functions
+	  with impl_ prefix.
+	  (impl_patch_from_global_index, impl_dim_patch_from_index): New
+	  functions to compute patch from global index.
+	  (Is_global_map):  Specialize trait for Map class.
+	* src/vsip/parallel.hpp: Include par-support.hpp.
+	* src/vsip/support.hpp (no_index): New constant value.
+	* src/vsip/impl/block-copy.hpp: Fix handling of distributed blocks.
+	* src/vsip/impl/block-traits.hpp (Is_par_same_map): Describe what
+	  it means to be "same map".
+	* src/vsip/impl/dispatch-assign.hpp: Move map traits into
+	  map-traits.hpp.
+	* src/vsip/impl/dist.hpp: Consistent names for impl par support
+	  functions.
+	  (impl_subblock_from_index): Implement function for Cyclic_dist.
+	  (impl_local_from_global_index): Likewise.
+	* src/vsip/impl/global_map.hpp: Rename implementation par support
+	  functions with impl_ prefix.  Specialize map traits.
+	* src/vsip/impl/local_map.hpp: Likewise.
+	* src/vsip/impl/layout.hpp: Add assertions that indices are valid.
+	* src/vsip/impl/map-traits.hpp (Is_global_map, Is_local_only,
+	  Is_global_only): Define general traits for maps.
+	* src/vsip/impl/par-assign.hpp: Update use of implementation par
+	  support functions.  Remove unnecessary assertions.
+	* src/vsip/impl/par-chain-assign.hpp: Likewise.
+	* src/vsip/impl/par-util.hpp: Move parallel support functions
+	  [view.support.fcn] to ...
+	* src/vsip/impl/par-util.hpp: New file, ... here.
+	* src/vsip/impl/replicated_map.hpp: New file, implement
+	  Replicated_map class.
+	* src/vsip/impl/subblock.hpp: Rename implementation par support
+	  functions with impl_ prefix.
+	  (Sliced_block): Recognize special index 'no_index' to indicate
+	  empty slice.  Use this for get_local_block when local view is
+	  empty.
+	* src/vsip/impl/sv_block.hpp: New file, block with std::vector as
+	  storage.  Intended for distributed implementation use only.
+	* tests/appmap.cpp: Update test coverage for parallel support
+	  functions, including impl_{subblock,patch}_from_global_index.
+	* tests/replicated_map.cpp: New file, unit tests for Replicated_map.
+	* tests/util-par.hpp: Update use of parallel support functions.
+	* tests/parallel/block.cpp: Likewise.
+	* tests/parallel/expr.cpp: Likewise.
+	* tests/parallel/fftm.cpp: Likewise.
+	* tests/parallel/subviews.cpp: Likewise.
+	* tests/parallel/user-storage.cpp: Likewise.
+	* tests/parallel/corner-turn.cpp: New test, simple corner-turn.
+	* tests/parallel/replicated_data.cpp: New file, unit tests for 
+	  views distributed with Replicated_map.
+	* tests/regressions/localview_of_slice.cpp: New file, regression
+	  test for local view of a sliced block.
+	
+2006-03-24  Jules Bergmann  <jules@codesourcery.com>
+
 	* benchmarks/loop.hpp: Fix macro typo.  Fix Wall warnings.
 	  Use different loop variables for nested loops.
 
Index: src/vsip/dense.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/dense.hpp,v
retrieving revision 1.34
diff -u -r1.34 dense.hpp
--- src/vsip/dense.hpp	7 Mar 2006 02:15:22 -0000	1.34
+++ src/vsip/dense.hpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005,2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/dense.hpp
     @author  Jules Bergmann
@@ -1261,7 +1261,7 @@
     map_        (map),
     admitted_   (true)
 {
-  map_.apply(dom);
+  map_.impl_apply(dom);
 }
 
 
@@ -1281,7 +1281,7 @@
     map_        (map),
     admitted_   (true)
 {
-  map_.apply(dom);
+  map_.impl_apply(dom);
 }
 
 
Index: src/vsip/map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/map.hpp,v
retrieving revision 1.21
diff -u -r1.21 map.hpp
--- src/vsip/map.hpp	11 Jan 2006 16:22:43 -0000	1.21
+++ src/vsip/map.hpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/map.hpp
     @author  Jules Bergmann
@@ -27,6 +27,7 @@
 #include <vsip/impl/block-traits.hpp>
 
 #include <vsip/impl/global_map.hpp>
+#include <vsip/impl/replicated_map.hpp>
 
 
 
@@ -153,20 +154,20 @@
 
 
   // Applied map functions.
-  length_type num_patches     (index_type sb) const VSIP_NOTHROW;
+  length_type impl_num_patches     (index_type sb) const VSIP_NOTHROW;
 
   template <dimension_type Dim>
-  void apply(Domain<Dim> const& dom) VSIP_NOTHROW;
+  void impl_apply(Domain<Dim> const& dom) VSIP_NOTHROW;
 
   template <dimension_type Dim>
-  Domain<Dim> subblock_domain(index_type sb) const VSIP_NOTHROW;
+  Domain<Dim> impl_subblock_domain(index_type sb) const VSIP_NOTHROW;
 
   template <dimension_type Dim>
-  Domain<Dim> global_domain(index_type sb, index_type patch)
+  Domain<Dim> impl_global_domain(index_type sb, index_type patch)
     const VSIP_NOTHROW;
 
   template <dimension_type Dim>
-  Domain<Dim> local_domain (index_type sb, index_type patch)
+  Domain<Dim> impl_local_domain (index_type sb, index_type patch)
     const VSIP_NOTHROW;
 
   template <dimension_type Dim>
@@ -175,17 +176,14 @@
   // Implementation functions.
   impl_pvec_type     impl_pvec() const { return pvec_; }
   impl::Communicator impl_comm() const { return comm_; }
-  processor_type     impl_rank() const { return comm_.rank(); }
-  length_type        impl_size() const { return comm_.size(); }
   bool               impl_is_applied() const { return dim_ != 0; }
 
   length_type        impl_working_size() const
     { return std::min(this->num_subblocks(), this->pvec_.size()); }
 
 
-
-  // Private implementation functions.
-private:
+  // Implementation functions.
+public:
   length_type impl_subblock_patches(dimension_type d, index_type sb)
     const VSIP_NOTHROW;
   length_type impl_subblock_size(dimension_type d, index_type sb)
@@ -196,8 +194,10 @@
   Domain<1> impl_patch_local_dom(dimension_type d, index_type sb,
 				 index_type p)
     const VSIP_NOTHROW;
-public:
-  index_type impl_subblock_from_index(dimension_type d, index_type idx)
+
+  index_type impl_dim_subblock_from_index(dimension_type d, index_type idx)
+    const VSIP_NOTHROW;
+  index_type impl_dim_patch_from_index(dimension_type d, index_type idx)
     const VSIP_NOTHROW;
   index_type impl_local_from_global_index(dimension_type d, index_type idx)
     const VSIP_NOTHROW;
@@ -206,8 +206,12 @@
   index_type impl_subblock_from_global_index(Index<Dim> const& idx)
     const VSIP_NOTHROW;
 
-  index_type global_from_local_index(dimension_type d, index_type sb,
-				     index_type idx)
+  template <dimension_type Dim>
+  index_type impl_patch_from_global_index(Index<Dim> const& idx)
+    const VSIP_NOTHROW;
+
+  index_type impl_global_from_local_index(dimension_type d, index_type sb,
+					  index_type idx)
     const VSIP_NOTHROW;
 
   template <dimension_type Dim>
@@ -225,9 +229,9 @@
   friend bool map_equiv<>(Map const&, Map const&) VSIP_NOTHROW;
 
 public:
-  index_type     lookup_index(processor_type pr) const;
-  processor_type impl_proc(index_type idx) const { return pvec_[idx]; }
-  length_type    impl_num_procs() const { return num_procs_; }
+  index_type     impl_rank_from_proc(processor_type pr) const;
+  processor_type impl_proc_from_rank(index_type idx) const
+    { return pvec_[idx]; }
 
   // Members.
 private:
@@ -373,7 +377,7 @@
 	  typename       Dist2>
 template <dimension_type Dim>
 inline void
-Map<Dist0, Dist1, Dist2>::apply(Domain<Dim> const& dom)
+Map<Dist0, Dist1, Dist2>::impl_apply(Domain<Dim> const& dom)
   VSIP_NOTHROW
 {
   Domain<1> arr[VSIP_MAX_DIMENSION];
@@ -557,7 +561,7 @@
 	  typename       Dist1,
 	  typename       Dist2>
 inline index_type
-Map<Dist0, Dist1, Dist2>::impl_subblock_from_index(
+Map<Dist0, Dist1, Dist2>::impl_dim_subblock_from_index(
   dimension_type d,
   index_type     idx
   )
@@ -577,6 +581,32 @@
 
 
 
+// Get local patch for a given index.
+
+template <typename       Dist0,
+	  typename       Dist1,
+	  typename       Dist2>
+inline index_type
+Map<Dist0, Dist1, Dist2>::impl_dim_patch_from_index(
+  dimension_type d,
+  index_type     idx
+  )
+  const VSIP_NOTHROW
+{
+  assert(d < VSIP_MAX_DIMENSION);
+  assert(d < dim_);
+
+  switch (d)
+  {
+  default: assert(false);
+  case 0: return dist0_.impl_patch_from_index(dom_[0], idx);
+  case 1: return dist1_.impl_patch_from_index(dom_[1], idx);
+  case 2: return dist2_.impl_patch_from_index(dom_[2], idx);
+  }
+}
+
+
+
 template <typename       Dist0,
 	  typename       Dist1,
 	  typename       Dist2>
@@ -621,7 +651,7 @@
     assert(idx[d] < dom_[d].size());
     if (d != 0)
       sb *= subblocks_[d];
-    sb += impl_subblock_from_index(d, idx[d]);
+    sb += impl_dim_subblock_from_index(d, idx[d]);
   }
 
   assert(sb < num_subblocks_);
@@ -629,7 +659,7 @@
   impl::split_tuple(sb, dim_, subblocks_, dim_sb);
   for (dimension_type d=0; d<Dim; ++d)
   {
-    assert(dim_sb[d] == impl_subblock_from_index(d, idx[d]));
+    assert(dim_sb[d] == impl_dim_subblock_from_index(d, idx[d]));
   }
 
   return sb;
@@ -637,6 +667,40 @@
 
 
 
+/// Determine subblock/patch holding a global index.
+
+template <typename       Dist0,
+	  typename       Dist1,
+	  typename       Dist2>
+template <dimension_type Dim>
+inline index_type
+Map<Dist0, Dist1, Dist2>::impl_patch_from_global_index(
+  Index<Dim> const& idx
+  )
+  const VSIP_NOTHROW
+{
+  index_type p = 0;
+  index_type dim_sb[VSIP_MAX_DIMENSION];
+
+  assert(dim_ != 0 && dim_ == Dim);
+
+  index_type sb = this->impl_subblock_from_global_index(idx);
+  impl::split_tuple(sb, dim_, subblocks_, dim_sb);
+
+  for (dimension_type d=0; d<Dim; ++d)
+  {
+    assert(idx[d] < dom_[d].size());
+    if (d != 0)
+      p *= impl_subblock_patches(d, dim_sb[d]);
+    p += impl_dim_patch_from_index(d, idx[d]);
+  }
+
+  assert(p < this->impl_num_patches(sb));
+  return p;
+}
+
+
+
 /// Determine global index from local index for a single dimension
 
 /// Requires:
@@ -650,7 +714,7 @@
 	  typename       Dist1,
 	  typename       Dist2>
 inline index_type
-Map<Dist0, Dist1, Dist2>::global_from_local_index(
+Map<Dist0, Dist1, Dist2>::impl_global_from_local_index(
   dimension_type d,
   index_type     sb,
   index_type     idx
@@ -731,7 +795,7 @@
 	  typename       Dist1,
 	  typename       Dist2>
 inline index_type
-Map<Dist0, Dist1, Dist2>::lookup_index(processor_type pr)
+Map<Dist0, Dist1, Dist2>::impl_rank_from_proc(processor_type pr)
   const
 {
   for (index_type i=0; i<pvec_.size(); ++i)
@@ -758,7 +822,7 @@
 Map<Dist0, Dist1, Dist2>::subblock(processor_type pr)
   const VSIP_NOTHROW
 {
-  index_type pi = lookup_index(pr);
+  index_type pi = impl_rank_from_proc(pr);
 
   if (pi != no_processor && pi < num_subblocks_)
     return pi;
@@ -781,8 +845,8 @@
 Map<Dist0, Dist1, Dist2>::subblock()
   const VSIP_NOTHROW
 {
-  processor_type pr = impl_rank();
-  index_type     pi = lookup_index(pr);
+  processor_type pr = local_processor();
+  index_type     pi = impl_rank_from_proc(pr);
 
   if (pi != no_processor && pi < num_subblocks_)
     return pi;
@@ -879,7 +943,7 @@
 	  typename       Dist2>
 inline
 length_type
-Map<Dist0, Dist1, Dist2>::num_patches(index_type sb)
+Map<Dist0, Dist1, Dist2>::impl_num_patches(index_type sb)
   const VSIP_NOTHROW
 {
   assert(sb < num_subblocks_);
@@ -909,7 +973,7 @@
 template <dimension_type Dim>
 inline
 Domain<Dim>
-Map<Dist0, Dist1, Dist2>::subblock_domain(index_type sb)
+Map<Dist0, Dist1, Dist2>::impl_subblock_domain(index_type sb)
   const VSIP_NOTHROW
 {
   assert(sb < num_subblocks_);
@@ -940,7 +1004,7 @@
 template <dimension_type Dim>
 inline
 Domain<Dim>
-Map<Dist0, Dist1, Dist2>::global_domain(
+Map<Dist0, Dist1, Dist2>::impl_global_domain(
   index_type    sb,
   index_type    p)
 const VSIP_NOTHROW
@@ -960,7 +1024,7 @@
   }
 
   assert(sb < num_subblocks_);
-  assert(p  < num_patches(sb));
+  assert(p  < this->impl_num_patches(sb));
   assert(dim_ == Dim);
 
   impl::split_tuple(sb, Dim, subblocks_, dim_sb);
@@ -990,7 +1054,7 @@
 template <dimension_type Dim>
 inline
 Domain<Dim>
-Map<Dist0, Dist1, Dist2>::local_domain(
+Map<Dist0, Dist1, Dist2>::impl_local_domain(
   index_type    sb,
   index_type    p
   )
@@ -1011,7 +1075,7 @@
   }
 
   assert(sb < num_subblocks_);
-  assert(p  < num_patches(sb));
+  assert(p  < this->impl_num_patches(sb));
   assert(dim_ == Dim);
 
 
@@ -1136,6 +1200,14 @@
 namespace impl
 {
 
+template <typename Dist0,
+	  typename Dist1,
+	  typename Dist2>
+struct Is_global_map<Map<Dist0, Dist1, Dist2> >
+{ static bool const value = true; };
+
+
+
 template <typename Dim0,
 	  typename Dim1,
 	  typename Dim2>
@@ -1203,12 +1275,12 @@
     length_type num_sb_1 = map.num_subblocks(1);
     length_type num_sb_2 = map.num_subblocks(2);
 
-    index_type fix_sb_0 = map.impl_subblock_from_index(0, idx);
+    index_type fix_sb_0 = map.impl_dim_subblock_from_index(0, idx);
 
     Vector<processor_type> pvec(num_sb_1*num_sb_2);
 
     for (index_type pi=0; pi<num_sb_1*num_sb_2; ++pi)
-      pvec(pi) = map.impl_proc(fix_sb_0*num_sb_1*num_sb_2+pi);
+      pvec(pi) = map.impl_proc_from_rank(fix_sb_0*num_sb_1*num_sb_2+pi);
 
     return type(pvec, copy_dist<Dist1>(map, 1), copy_dist<Dist2>(map, 2));
   }
@@ -1229,7 +1301,7 @@
     length_type num_sb_1 = map.num_subblocks(1);
     length_type num_sb_2 = map.num_subblocks(2);
 
-    index_type fix_sb_1 = map.impl_subblock_from_index(1, idx);
+    index_type fix_sb_1 = map.impl_dim_subblock_from_index(1, idx);
 
     Vector<processor_type> pvec(num_sb_0*num_sb_2);
 
@@ -1237,7 +1309,8 @@
     {
       index_type sb_0 = pi / num_sb_2;
       index_type sb_2 = pi % num_sb_2;
-      pvec(pi) = map.impl_proc(sb_0*num_sb_1*num_sb_2+fix_sb_1*num_sb_2+sb_2);
+      pvec(pi) = map.impl_proc_from_rank(sb_0*num_sb_1*num_sb_2 +
+					 fix_sb_1*num_sb_2      + sb_2);
     }
 
     return type(pvec, copy_dist<Dist1>(map, 0), copy_dist<Dist2>(map, 2));
@@ -1259,7 +1332,7 @@
     length_type num_sb_1 = map.num_subblocks(1);
     length_type num_sb_2 = map.num_subblocks(2);
 
-    index_type fix_sb_2 = map.impl_subblock_from_index(2, idx);
+    index_type fix_sb_2 = map.impl_dim_subblock_from_index(2, idx);
 
     Vector<processor_type> pvec(num_sb_0*num_sb_1);
 
@@ -1267,9 +1340,9 @@
     {
       index_type sb_0 = pi / num_sb_1;
       index_type sb_1 = pi % num_sb_1;
-      pvec(pi) = map.impl_proc(sb_0*num_sb_1*num_sb_2 +
-			       sb_1*num_sb_2          +
-			       fix_sb_2);
+      pvec(pi) = map.impl_proc_from_rank(sb_0*num_sb_1*num_sb_2 +
+					 sb_1*num_sb_2          +
+					 fix_sb_2);
     }
 
     return type(pvec, copy_dist<Dist1>(map, 0), copy_dist<Dist2>(map, 1));
@@ -1298,14 +1371,14 @@
     length_type num_sb_1 = map.num_subblocks(1);
     length_type num_sb_2 = map.num_subblocks(2);
 
-    index_type fix_sb_0 = map.impl_subblock_from_index(0, idx0);
-    index_type fix_sb_1 = map.impl_subblock_from_index(1, idx1);
+    index_type fix_sb_0 = map.impl_dim_subblock_from_index(0, idx0);
+    index_type fix_sb_1 = map.impl_dim_subblock_from_index(1, idx1);
 
     Vector<processor_type> pvec(num_sb_2);
 
     for (index_type pi=0; pi<num_sb_2; ++pi)
-      pvec(pi) = map.impl_proc(fix_sb_0*num_sb_1*num_sb_2 +
-			       fix_sb_1*num_sb_2 + pi);
+      pvec(pi) = map.impl_proc_from_rank(fix_sb_0*num_sb_1*num_sb_2 +
+					 fix_sb_1*num_sb_2 + pi);
 
     return type(pvec, copy_dist<Dist2>(map, 2));
   }
@@ -1327,14 +1400,14 @@
     length_type num_sb_1 = map.num_subblocks(1);
     length_type num_sb_2 = map.num_subblocks(2);
 
-    index_type fix_sb_0 = map.impl_subblock_from_index(0, idx0);
-    index_type fix_sb_2 = map.impl_subblock_from_index(2, idx2);
+    index_type fix_sb_0 = map.impl_dim_subblock_from_index(0, idx0);
+    index_type fix_sb_2 = map.impl_dim_subblock_from_index(2, idx2);
 
     Vector<processor_type> pvec(num_sb_1);
 
     for (index_type pi=0; pi<num_sb_1; ++pi)
-      pvec(pi) = map.impl_proc(fix_sb_0*num_sb_1*num_sb_2 +
-			       pi*num_sb_2 + fix_sb_2);
+      pvec(pi) = map.impl_proc_from_rank(fix_sb_0*num_sb_1*num_sb_2 +
+					 pi*num_sb_2 + fix_sb_2);
 
     return type(pvec, copy_dist<Dist1>(map, 1));
   }
@@ -1356,14 +1429,14 @@
     length_type num_sb_1 = map.num_subblocks(1);
     length_type num_sb_2 = map.num_subblocks(2);
 
-    index_type fix_sb_1 = map.impl_subblock_from_index(1, idx1);
-    index_type fix_sb_2 = map.impl_subblock_from_index(2, idx2);
+    index_type fix_sb_1 = map.impl_dim_subblock_from_index(1, idx1);
+    index_type fix_sb_2 = map.impl_dim_subblock_from_index(2, idx2);
 
     Vector<processor_type> pvec(num_sb_0);
 
     for (index_type pi=0; pi<num_sb_0; ++pi)
-      pvec(pi) = map.impl_proc(pi*num_sb_1*num_sb_2 +
-			       fix_sb_1*num_sb_2 + fix_sb_2);
+      pvec(pi) = map.impl_proc_from_rank(pi*num_sb_1*num_sb_2 +
+					 fix_sb_1*num_sb_2 + fix_sb_2);
 
     return type(pvec, copy_dist<Dist0>(map, 0));
   }
@@ -1407,7 +1480,7 @@
     Vector<processor_type> pvec(map.num_subblocks());
 
     for (index_type pi=0; pi<map.num_subblocks(); ++pi)
-      pvec(pi) = map.impl_proc(pi);
+      pvec(pi) = map.impl_proc_from_rank(pi);
 	
     return type(pvec,
 		copy_dist<Dist0>(map, 0),
Index: src/vsip/parallel.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/parallel.hpp,v
retrieving revision 1.4
diff -u -r1.4 parallel.hpp
--- src/vsip/parallel.hpp	11 Jan 2006 16:22:44 -0000	1.4
+++ src/vsip/parallel.hpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/parallel.hpp
     @author  Jules Bergmann
@@ -18,6 +18,7 @@
 #include <vsip/map.hpp>
 #include <vsip/impl/setup-assign.hpp>
 #include <vsip/impl/working-view.hpp>
+#include <vsip/impl/par-support.hpp>
 #include <vsip/impl/par-util.hpp>
 
 
Index: src/vsip/support.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/support.hpp,v
retrieving revision 1.28
diff -u -r1.28 support.hpp
--- src/vsip/support.hpp	22 Mar 2006 20:48:58 -0000	1.28
+++ src/vsip/support.hpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    support.hpp
     @author  Jules Bergmann
@@ -220,6 +220,7 @@
 typedef unsigned int processor_type;
 typedef signed int processor_difference_type;
 
+index_type     const no_index     = static_cast<index_type>(-1);
 index_type     const no_subblock  = static_cast<index_type>(-1);
 processor_type const no_processor = static_cast<processor_type>(-1);
 
Index: src/vsip/impl/block-copy.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/block-copy.hpp,v
retrieving revision 1.10
diff -u -r1.10 block-copy.hpp
--- src/vsip/impl/block-copy.hpp	10 Feb 2006 22:24:01 -0000	1.10
+++ src/vsip/impl/block-copy.hpp	24 Mar 2006 18:55:40 -0000
@@ -87,7 +87,16 @@
   static void exec(BlockT& block, value_type const& val)
   {
     typedef typename Distributed_local_block<BlockT>::type local_block_type;
-    Block_fill<Dim, local_block_type>::exec(get_local_block(block), val);
+    typedef typename impl::View_block_storage<local_block_type>::plain_type
+		type;
+
+    if (block.map().subblock() != no_subblock)
+    {
+      // If get_local_block returns a temporary value, we need to copy it.
+      // Other (if it returns a reference), this captures it.
+      type l_block = get_local_block(block);
+      Block_fill<Dim, local_block_type>::exec(l_block, val);
+    }
   }
 };
 
Index: src/vsip/impl/block-traits.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/block-traits.hpp,v
retrieving revision 1.18
diff -u -r1.18 block-traits.hpp
--- src/vsip/impl/block-traits.hpp	10 Feb 2006 22:24:01 -0000	1.18
+++ src/vsip/impl/block-traits.hpp	24 Mar 2006 18:55:40 -0000
@@ -224,6 +224,9 @@
 
 /// Check if lhs map is same as rhs block's map.
 
+/// Two blocks are the same if they distribute a view into subblocks
+/// containing the same elements.
+
 template <typename MapT,
 	  typename BlockT>
 struct Is_par_same_map
Index: src/vsip/impl/dispatch-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/dispatch-assign.hpp,v
retrieving revision 1.15
diff -u -r1.15 dispatch-assign.hpp
--- src/vsip/impl/dispatch-assign.hpp	10 Feb 2006 22:24:01 -0000	1.15
+++ src/vsip/impl/dispatch-assign.hpp	24 Mar 2006 18:55:40 -0000
@@ -17,6 +17,7 @@
 #include <vsip/impl/static_assert.hpp>
 #include <vsip/impl/metaprogramming.hpp>
 #include <vsip/impl/block-traits.hpp>
+#include <vsip/impl/map-traits.hpp>
 #include <vsip/impl/par-expr.hpp>
 #include <vsip/impl/expr_serial_dispatch.hpp>
 
@@ -32,39 +33,6 @@
 namespace impl
 {
 
-/// Traits class to determine if a map is serial or not.
-template <typename Map>
-struct Is_local_map
-{ static bool const value = false; };
-
-template <>
-struct Is_local_map<Local_map>
-{ static bool const value = true; };
-
-template <dimension_type Dim>
-struct Is_local_map<Local_or_global_map<Dim> >
-{ static bool const value = true; };
-
-template <typename Map>
-struct Is_global_map
-{ static bool const value = false; };
-
-template <dimension_type Dim>
-struct Is_global_map<Global_map<Dim> >
-{ static bool const value = true; };
-
-template <dimension_type Dim>
-struct Is_global_map<Local_or_global_map<Dim> >
-{ static bool const value = true; };
-
-template <typename Dist0,
-	  typename Dist1,
-	  typename Dist2>
-struct Is_global_map<Map<Dist0, Dist1, Dist2> >
-{ static bool const value = true; };
-
-
-
 // Tags used by Dispatch_assign to select assignment implementation.
 
 struct Tag_illegal_mix_of_local_and_global_in_assign;
Index: src/vsip/impl/dist.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/dist.hpp,v
retrieving revision 1.12
diff -u -r1.12 dist.hpp
--- src/vsip/impl/dist.hpp	19 Dec 2005 16:08:55 -0000	1.12
+++ src/vsip/impl/dist.hpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/impl/dist.hpp
     @author  Jules Bergmann
@@ -273,6 +273,10 @@
     const VSIP_NOTHROW
   { assert(i < dom.size()); return 0; }
 
+  index_type impl_patch_from_index(Domain<1> const& dom, index_type i)
+    const VSIP_NOTHROW
+  { assert(i < dom.size()); return 0; }
+
   index_type impl_local_from_global_index(Domain<1> const& dom, index_type i)
     const VSIP_NOTHROW
   { assert(i < dom.size()); return i; }
@@ -329,6 +333,10 @@
   index_type impl_subblock_from_index(Domain<1> const& dom, index_type i)
     const VSIP_NOTHROW;
 
+  index_type impl_patch_from_index(Domain<1> const& dom, index_type i)
+    const VSIP_NOTHROW
+  { assert(i < dom.size()); return 0; }
+
   index_type impl_local_from_global_index(Domain<1> const& dom, index_type i)
     const VSIP_NOTHROW;
 
@@ -386,6 +394,9 @@
   index_type impl_subblock_from_index(Domain<1> const& dom, index_type i)
     const VSIP_NOTHROW;
 
+  index_type impl_patch_from_index(Domain<1> const& dom, index_type i)
+    const VSIP_NOTHROW;
+
   index_type impl_local_from_global_index(Domain<1> const& dom, index_type i)
     const VSIP_NOTHROW;
 
@@ -484,7 +495,7 @@
 // cleanly, then the remaining elements (called the "spill_over")
 // are distributed 1 each to first subblocks.
 
-inline index_type 
+inline index_type
 Block_dist::impl_subblock_from_index(Domain<1> const& dom, index_type i)
   const VSIP_NOTHROW
 {
@@ -499,7 +510,7 @@
 
 
 
-inline index_type 
+inline index_type
 Block_dist::impl_local_from_global_index(Domain<1> const& dom, index_type i)
   const VSIP_NOTHROW
 {
@@ -522,7 +533,7 @@
 ///   I  is an index into the subblock.
 /// Returns:
 
-inline index_type 
+inline index_type
 Block_dist::impl_global_from_local_index(
   Domain<1> const& dom,
   index_type       sb,
@@ -661,20 +672,56 @@
 
 
 
-inline index_type 
-Cyclic_dist::impl_subblock_from_index(Domain<1> const& /*dom*/, index_type /*i*/)
+inline index_type
+Cyclic_dist::impl_subblock_from_index(
+  Domain<1> const& /*dom*/,
+  index_type       i)
   const VSIP_NOTHROW
 {
-  VSIP_IMPL_THROW(impl::unimplemented("Cyclic_dist::impl_subblock_from_index()"));
+  // Determine global_patch containing index i.
+  index_type p_g      = i / contiguity_;
+
+  // Determine subblock holding this patch.
+  index_type sb  = p_g % num_subblocks_;
+
+  return sb;
 }
 
 
 
-inline index_type 
-Cyclic_dist::impl_local_from_global_index(Domain<1> const& /*dom*/, index_type /*i*/)
+inline index_type
+Cyclic_dist::impl_patch_from_index(
+  Domain<1> const& /*dom*/,
+  index_type       i)
   const VSIP_NOTHROW
 {
-  VSIP_IMPL_THROW(impl::unimplemented("Cyclic_dist::impl_local_from_global_index()"));
+  // Determine global_patch containing index i.
+  index_type p_g      = i / contiguity_;
+
+  // Determine subblock holding this patch.
+  index_type sb  = p_g % num_subblocks_;
+  index_type p_l = (p_g - sb) / num_subblocks_;
+
+  return p_l;
+}
+
+
+
+inline index_type
+Cyclic_dist::impl_local_from_global_index(
+  Domain<1> const& /*dom*/,
+  index_type       i)
+  const VSIP_NOTHROW
+{
+  // Determine global_patch containing index i at offset.
+  index_type p_g      = i / contiguity_;
+  index_type p_offset = i % contiguity_;
+
+  // Convert this global patch to a subblock-patch.
+  index_type sb  = p_g % num_subblocks_;
+  index_type p_l = (p_g - sb) / num_subblocks_;
+
+  return p_l * contiguity_ + p_offset;
 }
 
 
@@ -688,7 +735,7 @@
 /// Returns:
 ///   The global index corresponding to subblock SB index I.
 
-inline index_type 
+inline index_type
 Cyclic_dist::impl_global_from_local_index(
   Domain<1> const& /*dom*/,
   index_type       sb,
Index: src/vsip/impl/distributed-block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/distributed-block.hpp,v
retrieving revision 1.19
diff -u -r1.19 distributed-block.hpp
--- src/vsip/impl/distributed-block.hpp	22 Mar 2006 20:48:58 -0000	1.19
+++ src/vsip/impl/distributed-block.hpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/impl/distributed-block.hpp
     @author  Jules Bergmann
@@ -61,16 +61,16 @@
 public:
   Distributed_block(Domain<dim> const& dom, Map const& map = Map())
     : map_           (map),
-      proc_          (map_.impl_rank()),
+      proc_          (local_processor()),
       sb_            (map_.subblock(proc_)),
       subblock_      (NULL)
   {
-    map_.apply(dom);
+    map_.impl_apply(dom);
     for (dimension_type d=0; d<dim; ++d)
       size_[d] = dom[d].length();
 
     Domain<dim> sb_dom = 
-      (sb_ != no_subblock) ? map_.template subblock_domain<dim>(sb_)
+      (sb_ != no_subblock) ? map_.template impl_subblock_domain<dim>(sb_)
                            : empty_domain<dim>();
 
     subblock_ = new Block(sb_dom);
@@ -79,16 +79,16 @@
   Distributed_block(Domain<dim> const& dom, value_type value,
 		    Map const& map = Map())
     : map_           (map),
-      proc_          (map_.impl_rank()),
+      proc_          (local_processor()),
       sb_            (map_.subblock(proc_)),
       subblock_      (NULL)
   {
-    map_.apply(dom);
+    map_.impl_apply(dom);
     for (dimension_type d=0; d<dim; ++d)
       size_[d] = dom[d].length();
 
     Domain<dim> sb_dom = 
-      (sb_ != no_subblock) ? map_.template subblock_domain<dim>(sb_)
+      (sb_ != no_subblock) ? map_.template impl_subblock_domain<dim>(sb_)
                            : empty_domain<dim>();
 
     subblock_ = new Block(sb_dom, value);
@@ -99,16 +99,16 @@
     value_type* const  ptr,
     Map const&         map = Map())
     : map_           (map),
-      proc_          (map_.impl_rank()),
+      proc_          (local_processor()),
       sb_            (map_.subblock()),
       subblock_      (NULL)
   {
-    map_.apply(dom);
+    map_.impl_apply(dom);
     for (dimension_type d=0; d<dim; ++d)
       size_[d] = dom[d].length();
 
     Domain<dim> sb_dom = 
-      (sb_ != no_subblock) ? map_.template subblock_domain<dim>(sb_)
+      (sb_ != no_subblock) ? map_.template impl_subblock_domain<dim>(sb_)
                            : empty_domain<dim>();
 
     subblock_ = new Block(sb_dom, ptr);
Index: src/vsip/impl/global_map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/global_map.hpp,v
retrieving revision 1.9
diff -u -r1.9 global_map.hpp
--- src/vsip/impl/global_map.hpp	11 Jan 2006 16:22:44 -0000	1.9
+++ src/vsip/impl/global_map.hpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/global_map.hpp
     @author  Jules Bergmann
@@ -17,7 +17,7 @@
 #include <vsip/impl/vector-iterator.hpp>
 #include <vsip/impl/par-services.hpp>
 #include <vsip/impl/map-traits.hpp>
-#include <vsip/impl/par-util.hpp>
+#include <vsip/impl/par-support.hpp>
 #include <vsip/map_fwd.hpp>
 
 
@@ -43,7 +43,9 @@
 
   // Accessors.
 public:
-  length_type num_subblocks() const VSIP_NOTHROW { return 1; }
+  length_type num_subblocks()  const VSIP_NOTHROW { return 1; }
+  length_type num_processors() const VSIP_NOTHROW
+    { return vsip::num_processors(); }
 
   index_type subblock(processor_type /*pr*/) const VSIP_NOTHROW
     { return 0; }
@@ -67,26 +69,31 @@
 
   // Applied map functions.
 public:
-  length_type num_patches     (index_type sb) const VSIP_NOTHROW
+  length_type impl_num_patches(index_type sb) const VSIP_NOTHROW
     { assert(sb == 0); return 1; }
 
-  void apply(Domain<Dim> const& dom) VSIP_NOTHROW
+  void impl_apply(Domain<Dim> const& dom) VSIP_NOTHROW
     { dom_ = dom; }
 
   template <dimension_type Dim2>
-  Domain<Dim2> subblock_domain(index_type sb) const VSIP_NOTHROW
+  Domain<Dim2> impl_subblock_domain(index_type sb) const VSIP_NOTHROW
     { assert(sb == 0); return dom_; }
 
   template <dimension_type Dim2>
-  Domain<Dim2> global_domain(index_type sb, index_type patch)
+  Domain<Dim2> impl_global_domain(index_type sb, index_type patch)
     const VSIP_NOTHROW
     { assert(sb == 0 && patch == 0); return dom_; }
 
   template <dimension_type Dim2>
-  Domain<Dim2> local_domain (index_type sb, index_type patch)
+  Domain<Dim2> impl_local_domain (index_type sb, index_type patch)
     const VSIP_NOTHROW
     { assert(sb == 0 && patch == 0); return dom_; }
 
+  index_type impl_global_from_local_index(dimension_type /*d*/, index_type sb,
+				     index_type idx)
+    const VSIP_NOTHROW
+  { assert(sb == 0); return idx; }
+
   index_type impl_local_from_global_index(dimension_type /*d*/, index_type idx)
     const VSIP_NOTHROW
   { return idx; }
@@ -101,19 +108,13 @@
   impl::Communicator impl_comm() const { return impl::default_communicator(); }
   pvec_type          impl_pvec() const
     { return impl::default_communicator().pvec(); }
-  processor_type     impl_rank() const
-    { return impl::default_communicator().rank(); }
-  processor_type     impl_size() const
-    { return impl::default_communicator().size(); }
 
   length_type        impl_working_size() const
-    { return this->impl_size(); }
+    { return this->num_processors(); }
 
-  processor_type impl_proc(index_type idx) const
+  processor_type impl_proc_from_rank(index_type idx) const
     { return this->impl_pvec()[idx]; }
 
-  length_type impl_num_procs() const { return this->impl_size(); }
-
   // Member data.
 private:
   Domain<Dim> dom_;
@@ -139,8 +140,16 @@
 /// Specialize global traits for Local_or_global_map.
 
 template <dimension_type Dim>
-struct Is_global_only<Local_or_global_map<Dim> >
-{ static bool const value = false; };
+struct Is_global_map<Global_map<Dim> >
+{ static bool const value = true; };
+
+template <dimension_type Dim>
+struct Is_local_map<Local_or_global_map<Dim> >
+{ static bool const value = true; };
+
+template <dimension_type Dim>
+struct Is_global_map<Local_or_global_map<Dim> >
+{ static bool const value = true; };
 
 
 
Index: src/vsip/impl/layout.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/layout.hpp,v
retrieving revision 1.18
diff -u -r1.18 layout.hpp
--- src/vsip/impl/layout.hpp	7 Mar 2006 02:15:22 -0000	1.18
+++ src/vsip/impl/layout.hpp	24 Mar 2006 18:55:40 -0000
@@ -185,7 +185,10 @@
 
   index_type index(index_type idx0)
     const VSIP_NOTHROW
-    { return idx0; }
+  {
+    assert(idx0 < size_[0]);
+    return idx0;
+  }
 
   index_type index(Index<1> idx)
     const VSIP_NOTHROW
@@ -242,7 +245,10 @@
 
   index_type index(index_type idx0)
     const VSIP_NOTHROW
-    { return idx0; }
+  {
+    assert(idx0 < size_[0]);
+    return idx0;
+  }
 
   index_type index(Index<1> idx)
     const VSIP_NOTHROW
@@ -293,7 +299,10 @@
 
   index_type index(index_type idx0)
     const VSIP_NOTHROW
-    { return idx0; }
+  {
+    assert(idx0 < size_[0]);
+    return idx0;
+  }
 
   index_type index(Index<1> idx)
     const VSIP_NOTHROW
@@ -351,7 +360,10 @@
 
   index_type index(index_type idx0, index_type idx1)
     const VSIP_NOTHROW
-    { return idx0 * size_[1] + idx1; }
+  {
+    assert(idx0 < size_[0] && idx1 < size_[1]);
+    return idx0 * size_[1] + idx1;
+  }
 
   index_type index(Index<2> idx)
     const VSIP_NOTHROW
@@ -409,7 +421,10 @@
 
   index_type index(index_type idx0, index_type idx1)
     const VSIP_NOTHROW
-    { return idx0 + idx1 * size_[0]; }
+  {
+    assert(idx0 < size_[0] && idx1 < size_[1]);
+    return idx0 + idx1 * size_[0];
+  }
 
   index_type index(Index<2> idx)
     const VSIP_NOTHROW
@@ -484,7 +499,10 @@
 
   index_type index(index_type idx0, index_type idx1)
     const VSIP_NOTHROW
-    { return idx0 * stride_ + idx1; }
+  {
+    assert(idx0 < size_[0] && idx1 < size_[1]);
+    return idx0 * stride_ + idx1;
+  }
 
   index_type index(Index<2> idx)
     const VSIP_NOTHROW
@@ -560,7 +578,10 @@
 
   index_type index(index_type idx0, index_type idx1)
     const VSIP_NOTHROW
-    { return idx0 + idx1 * stride_; }
+  {
+    assert(idx0 < size_[0] && idx1 < size_[1]);
+    return idx0 + idx1 * stride_;
+  }
 
   index_type index(Index<2> idx)
     const VSIP_NOTHROW
@@ -620,6 +641,7 @@
   index_type index(Point<3> idx)
     const VSIP_NOTHROW
   {
+    assert(idx[0] < size_[0] && idx[1] < size_[1] && idx[2] < size_[2]);
     return idx[Dim0]*size_[Dim1]*size_[Dim2] +
            idx[Dim1]*size_[Dim2] + 
            idx[Dim2];
@@ -701,6 +723,7 @@
   index_type index(Point<3> idx)
     const VSIP_NOTHROW
   {
+    assert(idx[0] < size_[0] && idx[1] < size_[1] && idx[2] < size_[2]);
     return idx[Dim0]*stride_[Dim0] +
            idx[Dim1]*stride_[Dim1] + 
            idx[Dim2];
Index: src/vsip/impl/local_map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/local_map.hpp,v
retrieving revision 1.6
diff -u -r1.6 local_map.hpp
--- src/vsip/impl/local_map.hpp	5 Dec 2005 19:19:18 -0000	1.6
+++ src/vsip/impl/local_map.hpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/local_map.hpp
     @author  Jules Bergmann
@@ -71,11 +71,11 @@
 
   // Applied map functions.
 public:
-  length_type num_patches     (index_type sb) const VSIP_NOTHROW
+  length_type impl_num_patches(index_type sb) const VSIP_NOTHROW
     { assert(sb == 0); return 1; }
 
   template <dimension_type Dim>
-  void apply(Domain<Dim> const& /*dom*/) VSIP_NOTHROW
+  void impl_apply(Domain<Dim> const& /*dom*/) VSIP_NOTHROW
     {}
 
   template <dimension_type Dim2>
@@ -97,18 +97,12 @@
   impl::Communicator impl_comm() const { return impl::default_communicator(); }
   pvec_type          impl_pvec() const
     { return impl::default_communicator().pvec(); }
-  processor_type     impl_rank() const
-    { return impl::default_communicator().rank(); }
-  processor_type     impl_size() const
-    { return impl::default_communicator().size(); }
 
   length_type        impl_working_size() const
-    { return this->impl_size(); }
-
-  processor_type impl_proc(index_type idx) const
-    { return this->impl_pvec()[idx]; }
+    { return 1; }
 
-  length_type impl_num_procs() const { return this->impl_size(); }
+  processor_type impl_proc_from_rank(index_type idx) const
+    { assert(idx == 0); return local_processor(); }
 
   // No member data.
 };
@@ -119,13 +113,9 @@
 /// Specialize local/global traits for Local_map.
 
 template <>
-struct Is_local_only<Local_map>
+struct Is_local_map<Local_map>
 { static bool const value = true; };
 
-template <>
-struct Is_global_only<Local_map>
-{ static bool const value = false; };
-
 
 
 template < >
Index: src/vsip/impl/map-traits.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/map-traits.hpp,v
retrieving revision 1.1
diff -u -r1.1 map-traits.hpp
--- src/vsip/impl/map-traits.hpp	2 Nov 2005 18:44:04 -0000	1.1
+++ src/vsip/impl/map-traits.hpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/impl/block-traits.hpp
     @author  Jules Bergmann
@@ -29,12 +29,22 @@
 /// Traits class to determine if a map is serial or not.
 
 template <typename MapT>
-struct Is_local_only
+struct Is_local_map
 { static bool const value = false; };
 
 template <typename Map>
+struct Is_global_map
+{ static bool const value = false; };
+
+template <typename MapT>
+struct Is_local_only
+{ static bool const value = Is_local_map<MapT>::value &&
+                           !Is_global_map<MapT>::value; };
+
+template <typename MapT>
 struct Is_global_only
-{ static bool const value = true; };
+{ static bool const value = Is_global_map<MapT>::value &&
+                           !Is_local_map<MapT>::value; };
 
 
 } // namespace vsip::impl
Index: src/vsip/impl/par-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-assign.hpp,v
retrieving revision 1.10
diff -u -r1.10 par-assign.hpp
--- src/vsip/impl/par-assign.hpp	5 Dec 2005 19:19:18 -0000	1.10
+++ src/vsip/impl/par-assign.hpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/impl/par-assign.hpp
     @author  Jules Bergmann
@@ -76,9 +76,6 @@
     dst_appmap_t const& dst_am = dst_.block().map();
 
     assert(src_am.impl_comm() == dst_am.impl_comm());
-    // Implies:
-    assert(src_am.impl_rank() == dst_am.impl_rank());
-    assert(src_am.impl_size() == dst_am.impl_size());
   }
 
   void operator()()
@@ -89,7 +86,7 @@
     dst_appmap_t const& dst_am = dst_.block().map();
 
 
-    processor_type rank = src_am.impl_rank();
+    processor_type rank = local_processor();
 
     src_sb_iterator cur = src_am.subblocks_begin(rank);
     src_sb_iterator end = src_am.subblocks_end(rank);
@@ -249,9 +246,6 @@
     dst_appmap_t const& dst_am = dst_.block().map();
 
     assert(src_am.impl_comm() == dst_am.impl_comm());
-    // Implies:
-    assert(src_am.impl_rank() == dst_am.impl_rank());
-    assert(src_am.impl_size() == dst_am.impl_size());
   }
 
   void operator()()
@@ -261,9 +255,7 @@
     src_appmap_t const& src_am = src_.block().map();
     dst_appmap_t const& dst_am = dst_.block().map();
 
-    assert(src_am.impl_rank() == dst_am.impl_rank());
-
-    processor_type rank = src_am.impl_rank();
+    processor_type rank = local_processor();
 
     impl::Communicator comm = src_am.impl_comm();
 
@@ -485,9 +477,9 @@
     : dst_ (dst),
       src_ (src.block()),
       send_list (),
-      send_size (dst_.block().map().impl_size()), // reserve comm size
+      send_size (num_processors()), // reserve comm size
       recv_list (),
-      recv_size (src_.block().map().impl_size()), // reserve comm size
+      recv_size (num_processors()), // reserve comm size
       sbuf_list (),
       req_list  (),
       msg_count (0)
@@ -496,11 +488,6 @@
     dst_appmap_t const& dst_am = dst_.block().map();
 
     assert(src_am.impl_comm() == dst_am.impl_comm());
-    // Implies:
-    assert(src_am.impl_rank() == dst_am.impl_rank());
-    assert(src_am.impl_size() == dst_am.impl_size());
-
-    assert(src_am.impl_rank() == dst_am.impl_rank());
 
     build_send_list();
     build_recv_list();
@@ -518,9 +505,7 @@
     src_appmap_t const& src_am = src_.block().map();
     dst_appmap_t const& dst_am = dst_.block().map();
 
-    assert(src_am.impl_rank() == dst_am.impl_rank());
-
-    processor_type rank = src_am.impl_rank();
+    processor_type rank = local_processor();
 
     // Iterate over all processors
     for (index_type pi=0; pi<dst_am.impl_pvec().size(); ++pi)
@@ -595,9 +580,7 @@
     src_appmap_t const& src_am = src_.block().map();
     dst_appmap_t const& dst_am = dst_.block().map();
 
-    assert(src_am.impl_rank() == dst_am.impl_rank());
-
-    processor_type rank = src_am.impl_rank();
+    processor_type rank = local_processor();
 
     for (index_type pi=0; pi<src_am.impl_pvec().size(); ++pi)
       recv_size[pi] = 0;
@@ -668,8 +651,8 @@
     dst_appmap_t       dst_am)
   {
     impl::Communicator comm = dst_am.impl_comm();
-    processor_type     rank = dst_am.impl_rank();
-    length_type        size = dst_am.impl_size();
+    processor_type     rank = local_processor();
+    length_type        size = num_processors();
 
     for (index_type pi=0; pi<dst_am.impl_pvec().size(); ++pi)
     {
@@ -721,8 +704,8 @@
     src_appmap_t       src_am)
   {
     impl::Communicator comm = src_am.impl_comm();
-    processor_type     rank = src_am.impl_rank();
-    length_type        size = src_am.impl_size();
+    processor_type     rank = local_processor();
+    length_type        size = num_processors();
 
     // Iterate over all sending processors
     for (index_type pi=0; pi<src_am.impl_pvec().size(); ++pi)
Index: src/vsip/impl/par-chain-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-chain-assign.hpp,v
retrieving revision 1.17
diff -u -r1.17 par-chain-assign.hpp
--- src/vsip/impl/par-chain-assign.hpp	3 Mar 2006 14:30:53 -0000	1.17
+++ src/vsip/impl/par-chain-assign.hpp	24 Mar 2006 18:55:40 -0000
@@ -128,7 +128,7 @@
   typedef typename View_of_dim<Dim, T, local_block_type>::const_type
 		local_view_type;
 
-  processor_type rank   = am.impl_rank();
+  processor_type rank = local_processor();
 
   // First set all subblock ext pointers to NULL.
   length_type tot_sb = am.num_subblocks();
@@ -280,11 +280,6 @@
   {
     impl::profile::Scope_event ev("Chained_parallel_assign-cons");
     assert(src_am_.impl_comm() == dst_am_.impl_comm());
-    // Implies:
-    assert(src_am_.impl_rank() == dst_am_.impl_rank());
-    assert(src_am_.impl_size() == dst_am_.impl_size());
-
-    assert(src_am_.impl_rank() == dst_am_.impl_rank());
 
     par_chain_assign::build_ext_array<Dim, T2, Block2>(
       src_, src_am_, src_ext_, impl::SYNC_IN);
@@ -420,25 +415,27 @@
 Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::build_send_list()
 {
   impl::profile::Scope_event ev("Chained_parallel_assign-build_send_list");
-  processor_type rank = src_am_.impl_rank();
+  processor_type rank = local_processor();
 
 #if VSIPL_IMPL_PCA_ROTATE
-  index_type  offset = src_am_.lookup_index(rank);
+  index_type  offset = src_am_.impl_rank_from_proc(rank);
 #endif
   length_type dsize  = dst_am_.impl_working_size();
   // std::min(dst_am_.num_subblocks(), dst_am_.impl_pvec().size());
 
-#if VSIP_IMPL_PCA_VERBOSE
-    std::cout << "\n"
-	      << "(" << rank << ") "
-	      << "build_send_list() -------------------------------------\n"
-	      << "(" << rank << ") "
-	      << "   dsize = " << dsize << std::endl;
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+    std::cout << "(" << rank << ") "
+	      << "build_send_list(dsize: " << dsize
+	      << ") -------------------------------------\n";
 #endif
 
   index_type src_sb = src_am_.subblock(rank);
 
-  if (src_sb != no_subblock)
+  // If multiple processors have the subblock, the first processor
+  // is responsible for sending it.
+
+  if (src_sb != no_subblock &&
+      *(src_am_.processor_begin(src_sb)) == rank)
   {
     // Iterate over all processors
     for (index_type pi=0; pi<dsize; ++pi)
@@ -447,9 +444,9 @@
       // (Currently does not work, it needs to take into account the
       // number of subblocks).
 #if VSIPL_IMPL_PCA_ROTATE
-      processor_type proc = dst_am_.impl_proc((pi + offset) % dsize);
+      processor_type proc = dst_am_.impl_proc_from_rank((pi + offset) % dsize);
 #else
-      processor_type proc = dst_am_.impl_proc(pi);
+      processor_type proc = dst_am_.impl_proc_from_rank(pi);
 #endif
 
       // Transfers that stay on this processor is handled by the copy_list.
@@ -468,14 +465,14 @@
 	src_ext_type* ext = src_ext_[src_sb];
 	ext->begin();
 
-	for (index_type dp=0; dp<dst_am_.num_patches(dst_sb); ++dp)
+	for (index_type dp=0; dp<num_patches(dst_, dst_sb); ++dp)
 	{
-	  Domain<dim> dst_dom = dst_am_.template global_domain<dim>(dst_sb, dp);
+	  Domain<dim> dst_dom = global_domain(dst_, dst_sb, dp);
 
-	  for (index_type sp=0; sp<src_am_.num_patches(src_sb); ++sp)
+	  for (index_type sp=0; sp<num_patches(src_, src_sb); ++sp)
 	  {
-	    Domain<dim> src_dom  = src_am_.template global_domain<dim>(src_sb, sp);
-	    Domain<dim> src_ldom = src_am_.template local_domain<dim>(src_sb, sp);
+	    Domain<dim> src_dom  = global_domain(src_, src_sb, sp);
+	    Domain<dim> src_ldom = local_domain(src_, src_sb, sp);
 
 	    Domain<dim> intr;
 
@@ -487,7 +484,7 @@
 
 	      par_chain_assign::chain_add<dst_order_t>(builder, *ext, send_dom);
 
-#if VSIP_IMPL_PCA_VERBOSE
+#if VSIP_IMPL_PCA_VERBOSE >= 2
 	      std::cout << "(" << rank << ") send "
 			<< rank << "/" << src_sb << "/" << sp
 			<< " -> "
@@ -524,18 +521,17 @@
 Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::build_recv_list()
 {
   impl::profile::Scope_event ev("Chained_parallel_assign-build_recv_list");
-  processor_type rank = src_am_.impl_rank();
+  processor_type rank = local_processor();
 
 #if VSIPL_IMPL_PCA_ROTATE
-  index_type  offset = dst_am_.lookup_index(rank);
+  index_type  offset = dst_am_.impl_rank_from_proc(rank);
 #endif
   length_type ssize  = src_am_.impl_working_size();
 
-#if VSIP_IMPL_PCA_VERBOSE
-    std::cout << "\n"
-	      << "(" << rank << ")"
-	      << "build_recv_list() -------------------------------------\n"
-	      << "  ssize = " << ssize << std::endl;
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+    std::cout << "(" << rank << ") "
+	      << "build_recv_list(ssize: " << ssize
+	      << ") -------------------------------------\n";
 #endif
 
   index_type dst_sb = dst_am_.subblock(rank);
@@ -551,8 +547,8 @@
       // Rotate message order so processors don't all send to 0,
       // then 1, etc (Currently does not work, it needs to take into
       // account the number of subblocks).
-      // processor_type proc = (src_am_.impl_proc(pi) + rank) % size;
-      processor_type proc = src_am_.impl_proc(pi);
+      // processor_type proc = (src_am_.impl_proc_from_rank(pi) + rank) % size;
+      processor_type proc = src_am_.impl_proc_from_rank(pi);
 
       // Transfers that stay on this processor is handled by the copy_list.
       if (!disable_copy && proc == rank)
@@ -562,20 +558,24 @@
       
       index_type src_sb = src_am_.subblock(proc);
 
-      if (src_sb != no_subblock)
+      // If multiple processors have the subblock, the first processor
+      // is responsible for sending it to us.
+
+      if (src_sb != no_subblock &&
+	  *(src_am_.processor_begin(src_sb)) == proc)
       {
 	// Check to see if destination processor already has block
 	if (!disable_copy && processor_has_block(src_am_, rank, src_sb))
 	  continue;
 
-	for (index_type dp=0; dp<dst_am_.num_patches(dst_sb); ++dp)
+	for (index_type dp=0; dp<num_patches(dst_, dst_sb); ++dp)
 	{
-	  Domain<dim> dst_dom  = dst_am_.template global_domain<dim>(dst_sb, dp);
-	  Domain<dim> dst_ldom = dst_am_.template local_domain<dim>(dst_sb, dp);
+	  Domain<dim> dst_dom  = global_domain(dst_, dst_sb, dp);
+	  Domain<dim> dst_ldom = local_domain(dst_, dst_sb, dp);
 	  
-	  for (index_type sp=0; sp<src_am_.num_patches(src_sb); ++sp)
+	  for (index_type sp=0; sp<num_patches(src_, src_sb); ++sp)
 	  {
-	    Domain<dim> src_dom = src_am_.template global_domain<dim>(src_sb, sp);
+	    Domain<dim> src_dom = global_domain(src_, src_sb, sp);
 	    
 	    Domain<dim> intr;
 	    
@@ -587,7 +587,7 @@
 	      
 	      par_chain_assign::chain_add<dst_order_t>(builder, *ext, recv_dom);
 	      
-#if VSIP_IMPL_PCA_VERBOSE
+#if VSIP_IMPL_PCA_VERBOSE >= 1
 	      std::cout << "(" << rank << ") recv "
 			<< rank << "/" << dst_sb << "/" << dp
 			<< " <- "
@@ -621,13 +621,12 @@
 Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::build_copy_list()
 {
   impl::profile::Scope_event ev("Chained_parallel_assign-build_copy_list");
-  processor_type rank = src_am_.impl_rank();
+  processor_type rank = local_processor();
 
-#if VSIP_IMPL_PCA_VERBOSE
-  std::cout << "\n"
-	    << "(" << rank << ")"
-	    << "build_copy_list() -------------------------------------\n"
-	    << "   num_procs = " << src_am_.impl_num_procs() << std::endl;
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+  std::cout << "(" << rank << ") "
+	    << "build_copy_list(num_procs: " << src_am_.num_processors()
+	    << ") -------------------------------------\n";
 #endif
 
   index_type dst_sb = dst_am_.subblock(rank);
@@ -637,19 +636,19 @@
     index_type src_sb = src_am_.subblock(rank);
     if (src_sb != no_subblock)
     {
-      for (index_type dp=0; dp<dst_am_.num_patches(dst_sb); ++dp)
+      for (index_type dp=0; dp<num_patches(dst_, dst_sb); ++dp)
       {
-	Domain<dim> dst_dom  = dst_am_.template global_domain<dim>(dst_sb, dp);
-	Domain<dim> dst_ldom = dst_am_.template local_domain<dim> (dst_sb, dp);
+	Domain<dim> dst_dom  = global_domain(dst_, dst_sb, dp);
+	Domain<dim> dst_ldom = local_domain (dst_, dst_sb, dp);
 
-	for (index_type sp=0; sp<src_am_.num_patches(src_sb); ++sp)
+	for (index_type sp=0; sp<num_patches(src_, src_sb); ++sp)
 	{
-	  Domain<dim> src_dom  = src_am_.template global_domain<dim>(src_sb, sp);
-	  Domain<dim> src_ldom = src_am_.template local_domain<dim> (src_sb, sp);
+	  Domain<dim> src_dom  = global_domain(src_, src_sb, sp);
+	  Domain<dim> src_ldom = local_domain (src_, src_sb, sp);
 
 	  Domain<dim> intr;
 
-#if VSIP_IMPL_PCA_VERBOSE
+#if VSIP_IMPL_PCA_VERBOSE >= 2
 //	  std::cout << " - dst " << dst_sb << "/" << dp << std::endl
 //		    << "   src " << src_sb     << "/" << sp << std::endl
 //	    ;
@@ -666,8 +665,9 @@
 
 	    copy_list.push_back(Copy_record(src_sb, dst_sb, send_dom, recv_dom));
 
-#if VSIP_IMPL_PCA_VERBOSE
-	    std::cout << "copy src: " << src_sb << "/" << sp
+#if VSIP_IMPL_PCA_VERBOSE >= 2
+	    std::cout << "(" << rank << ")"
+		      << "copy src: " << src_sb << "/" << sp
 		      << " " << send_dom
 		      << "  dst: " << dst_sb << "/" << dp
 		      << " " << recv_dom
@@ -695,12 +695,11 @@
   impl::profile::Scope_event ev("Chained_parallel_assign-exec_send_list");
   impl::Communicator comm = dst_am_.impl_comm();
 
-#if VSIP_IMPL_PCA_VERBOSE
-  processor_type rank = dst_am_.impl_rank();
-  std::cout << "\n"
-	    << "(" << rank << ")"
-	    << "exec_send_list() -------------------------------------\n"
-	    << "   size = " << send_list.size() << std::endl;
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+  processor_type rank = local_processor();
+  std::cout << "(" << rank << ") "
+	    << "exec_send_list(size: " << send_list.size()
+	    << ") -------------------------------------\n";
 #endif
 
   length_type dsize = dst_am_.impl_working_size();
@@ -709,7 +708,7 @@
   for (index_type pi=0; pi<dsize; ++pi)
   {
     // TODO: Rotate
-    processor_type proc = dst_am_.impl_proc(pi);
+    processor_type proc = dst_am_.impl_proc_from_rank(pi);
 
     impl::Chain_builder builder;
 
@@ -754,12 +753,11 @@
   impl::profile::Scope_event ev("Chained_parallel_assign-exec_recv_list");
   impl::Communicator comm = src_am_.impl_comm();
 
-#if VSIP_IMPL_PCA_VERBOSE
-  processor_type rank = src_am_.impl_rank();
-  std::cout << "\n"
-	    << "(" << rank << ")"
-	    << "exec_recv_list() -------------------------------------\n"
-	    << "   size = " << recv_list.size() << std::endl;
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+  processor_type rank = local_processor();
+  std::cout << "(" << rank << ") "
+	    << "exec_recv_list(size: " << recv_list.size()
+	    << ") -------------------------------------\n";
 #endif
 
   length_type ssize = src_am_.impl_working_size();
@@ -767,8 +765,8 @@
   // Iterate over all sending processors
   for (index_type pi=0; pi<ssize; ++pi)
   {
-    // processor_type proc = (src_am_.impl_proc(pi) + rank) % size;
-    processor_type proc = src_am_.impl_proc(pi);
+    // processor_type proc = (src_am_.impl_proc_from_rank(pi) + rank) % size;
+    processor_type proc = src_am_.impl_proc_from_rank(pi);
 
     impl::Chain_builder builder;
 
@@ -813,12 +811,11 @@
   impl::profile::Scope_event ev("Chained_parallel_assign-exec_copy_list");
   impl::Communicator comm = dst_am_.impl_comm();
 
-#if VSIP_IMPL_PCA_VERBOSE
-  processor_type rank = dst_am_.impl_rank();
-  std::cout << "\n"
-	    << "(" << rank << ")"
-	    << "exec_copy_list() -------------------------------------\n"
-	    << "   size = " << copy_list.size() << std::endl;
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+  processor_type rank = local_processor();
+  std::cout << "(" << rank << ") "
+	    << "exec_copy_list(size: " << copy_list.size()
+	    << ") -------------------------------------\n";
 #endif
 
   typedef typename std::vector<Copy_record>::iterator cl_iterator;
@@ -832,8 +829,9 @@
     dst_lview_type dst_lview = get_local_view(dst_);
 
     dst_lview((*cl_cur).dst_dom_) = src_lview((*cl_cur).src_dom_);
-#if VSIP_IMPL_PCA_VERBOSE
-    std::cout << "src subblock: " << (*cl_cur).src_sb_ << " -> "
+#if VSIP_IMPL_PCA_VERBOSE >= 2
+    std::cout << "(" << rank << ") "
+	      << "src subblock: " << (*cl_cur).src_sb_ << " -> "
 	      << "dst subblock: " << (*cl_cur).dst_sb_ << std::endl
 	      << dst_lview((*cl_cur).dst_dom_);
 #endif
Index: src/vsip/impl/par-support.hpp
===================================================================
RCS file: src/vsip/impl/par-support.hpp
diff -N src/vsip/impl/par-support.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/par-support.hpp	24 Mar 2006 18:55:40 -0000
@@ -0,0 +1,515 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/par-support.hpp
+    @author  Jules Bergmann
+    @date    2006-03-14
+    @brief   VSIPL++ Library: Parallel support funcions [view.support.fcn].
+
+*/
+
+#ifndef VSIP_IMPL_PAR_SUPPORT_HPP
+#define VSIP_IMPL_PAR_SUPPORT_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/par-services.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/impl/distributed-block.hpp>
+#include <vsip/impl/domain-utils.hpp>
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
+const_Vector<processor_type> processor_set();
+
+namespace impl
+{
+
+namespace psf_detail
+{
+
+// Return the subdomain of a view/map pair for a subblock.
+
+template <typename ViewT>
+inline Domain<ViewT::dim>
+subblock_domain(
+  ViewT const&        view,
+  Local_map const&    /*map*/,
+  index_type          sb)
+{
+  assert(sb == 0 || sb == no_subblock);
+  return (sb == 0) ? block_domain<ViewT::dim>(view.block())
+                   : empty_domain<ViewT::dim>();
+}
+
+template <typename ViewT,
+	  typename MapT>
+inline Domain<ViewT::dim>
+subblock_domain(
+  ViewT const&     /*view*/,
+  MapT const&      map,
+  index_type       sb)
+{
+  return map.template impl_subblock_domain<ViewT::dim>(sb);
+}
+
+
+
+// Return the local domain of a view/map pair for a subblock/patch.
+
+template <typename ViewT>
+inline Domain<ViewT::dim>
+local_domain(
+  ViewT const& view,
+  Local_map const&    /*map*/,
+  index_type          sb,
+  index_type          p)
+{
+  assert((sb == 0 && p == 0) || sb == no_subblock);
+  return (sb == 0) ? block_domain<ViewT::dim>(view.block())
+                   : empty_domain<ViewT::dim>();
+}
+
+template <typename ViewT,
+	  typename MapT>
+inline Domain<ViewT::dim>
+local_domain(
+  ViewT const&     /*view*/,
+  MapT const&      map,
+  index_type       sb,
+  index_type       p)
+{
+  return map.template impl_local_domain<ViewT::dim>(sb, p);
+}
+
+
+
+// Return the global domain of a view/map pair for a subblock/patch.
+
+template <typename ViewT>
+inline Domain<ViewT::dim>
+global_domain(
+  ViewT const& view,
+  Local_map const&    /*map*/,
+  index_type          sb,
+  index_type          p)
+{
+  assert((sb == 0 && p == 0) || sb == no_subblock);
+  return (sb == 0) ? block_domain<ViewT::dim>(view.block())
+                   : empty_domain<ViewT::dim>();
+}
+
+template <typename ViewT,
+	  typename MapT>
+inline Domain<ViewT::dim>
+global_domain(
+  ViewT const&     /*view*/,
+  MapT const&      map,
+  index_type       sb,
+  index_type       p)
+{
+  return map.template impl_global_domain<ViewT::dim>(sb, p);
+}
+
+} // namespace vsip::impl::psf_detail
+} // namespace vsip::impl
+
+
+
+/***********************************************************************
+  Definitions - [view.support.fcn] parallel support functions
+***********************************************************************/
+
+/// Return the domain of VIEW's subblock SB.
+
+/// Requires
+///   VIEW to be a view
+///   SB to either be a valid subblock of VIEW, or the value no_subblock.
+///
+/// Returns
+///   The domain of VIEW's subblock SB if SB is valid, the empty
+///   domain if SB == no_subblock.
+
+template <typename ViewT>
+Domain<ViewT::dim>
+subblock_domain(
+  ViewT const&  view,
+  index_type    sb)
+{
+  return impl::psf_detail::subblock_domain(view, view.block().map(), sb);
+}
+
+
+
+/// Return the domain of VIEW's subblock held by the local processor.
+
+/// Requires
+///   VIEW to be a view
+///
+/// Returns
+///   The domain of VIEW's subblock held by the local processor.
+
+template <typename ViewT>
+Domain<ViewT::dim>
+subblock_domain(
+  ViewT const&  view)
+{
+  return impl::psf_detail::subblock_domain(view, view.block().map(),
+					   view.block().map().subblock());
+}
+
+
+
+/// Return the local domain of VIEW's subblock SB patch P
+
+/// Requires
+///   VIEW to be a view
+///   SB to either be a valid subblock of VIEW, or the value no_subblock.
+///   P to either be a valid patch of subblock SB.
+///
+/// Returns
+///   The local domain of VIEW's subblock SB patch P if SB is valid,
+///   the empty domain if SB == no_subblock.
+
+template <typename ViewT>
+Domain<ViewT::dim>
+local_domain(
+  ViewT const&  view,
+  index_type    sb,
+  index_type    p)
+{
+  return impl::psf_detail::local_domain(view, view.block().map(), sb, p);
+}
+
+
+
+/// Return the local domain of VIEW's patch P on the local processor's subblock
+
+/// Requires
+///   VIEW to be a view
+///   P to either be a valid patch of the local processor's subblock.
+///
+/// Returns
+///   The local domain of VIEW's patch P of the local processor's subblock
+///     if the local processor holds a subblock,
+///   The empty domain otherwise.
+
+template <typename ViewT>
+Domain<ViewT::dim>
+local_domain(
+  ViewT const&  view,
+  index_type    p=0)
+{
+  return impl::psf_detail::local_domain(view, view.block().map(),
+					view.block().map().subblock(),
+					p);
+}
+
+
+
+/// Return the global domain of VIEW's subblock SB patch P
+
+/// Requires
+///   VIEW to be a view
+///   SB to either be a valid subblock of VIEW, or the value no_subblock.
+///   P to either be a valid patch of subblock SB.
+///
+/// Returns
+///   The global domain of VIEW's subblock SB patch P if SB is valid,
+///   the empty domain if SB == no_subblock.
+
+template <typename ViewT>
+Domain<ViewT::dim>
+global_domain(
+  ViewT const&  view,
+  index_type    sb,
+  index_type    p)
+{
+  return impl::psf_detail::global_domain(view, view.block().map(), sb, p);
+}
+
+
+
+/// Return the global domain of VIEW's local subblock patch P
+
+/// Requires
+///   VIEW to be a view
+///   P to either be a valid patch of the local processor's subblock.
+///
+/// Returns
+///   The global domain of VIEW's patch P of the local processor's subblock
+///     if the local processor holds a subblock,
+///   The empty domain otherwise.
+
+template <typename ViewT>
+Domain<ViewT::dim>
+global_domain(
+  ViewT const&  view,
+  index_type    p=0)
+{
+  return impl::psf_detail::global_domain(view, view.block().map(), 
+					 view.block().map().subblock(),
+					 p);
+}
+
+
+/// Return the number of subblocks VIEW is distrubted over.
+
+/// Requires
+///   VIEW to be a view
+
+template <typename ViewT>
+length_type
+num_subblocks(
+  ViewT const&  view)
+{
+  return view.block().map().num_subblocks();
+}
+
+
+
+/// Return the number of patches in VIEW's subblock SB.
+
+/// Requires
+///   VIEW to be a view.
+///   SB to either be a valid subblock of VIEW, or the value no_subblock.
+
+template <typename ViewT>
+length_type
+num_patches(
+  ViewT const&  view,
+  index_type    sb)
+{
+  return view.block().map().impl_num_patches(sb);
+}
+
+
+
+/// Return the number of patches in VIEW's subblock held on the local
+/// processor.
+
+/// Requires
+///   VIEW to be a view.
+
+template <typename ViewT>
+length_type
+num_patches(
+  ViewT const&  view)
+{
+  return view.block().map().impl_num_patches(view.block().map().subblock());
+}
+
+
+
+/// Return the subblock rank held by processor PR.
+
+/// Requires
+///   VIEW to be a view.
+///   PR to be processor.
+///
+/// Returns
+///   The subblock rank of VIEW held by processor PR if it holds a subblock,
+///   NO_SUBBLOCK otherwise.
+
+template <typename ViewT>
+index_type
+subblock(
+  ViewT const&   view,
+  processor_type pr)
+{
+  return view.block().map().subblock(pr);
+}
+
+
+
+/// Return the subblock rank held by processor PR.
+
+/// Requires
+///   VIEW to be a view.
+///
+/// Returns
+///   The subblock rank of VIEW held by local processor,
+///   or NO_SUBBLOCK if it does not hold a subblock.
+
+template <typename ViewT>
+index_type
+subblock(
+  ViewT const&   view)
+{
+  return view.block().map().subblock();
+}
+
+
+
+/// Determine which subblock holds VIEW's global index IDX
+
+template <typename ViewT>
+index_type
+subblock_from_global_index(
+  ViewT const&             view,
+  Index<ViewT::dim> const& idx)
+{
+  for (dimension_type d=0; d<ViewT::dim; ++d)
+    assert(idx[d] < view.size(d));
+
+  return view.block().
+    map().template impl_subblock_from_global_index<ViewT::dim>(idx);
+}
+
+
+
+/// Determine which patch holds VIEW's global index IDX
+
+/// Notes:
+///   This patch is only valid in the subblock returned by
+///   subblock_from_global_index.
+
+template <typename ViewT>
+index_type
+patch_from_global_index(
+  ViewT const&             view,
+  Index<ViewT::dim> const& idx)
+{
+  for (dimension_type d=0; d<ViewT::dim; ++d)
+    assert(idx[d] < view.size(d));
+
+  return view.block().
+    map().template impl_subblock_from_global_index<ViewT::dim>(idx);
+}
+
+
+
+/***********************************************************************
+  local_from_global_index
+***********************************************************************/
+
+/// Determine the local index corresponding to VIEW's global index G_IDX.
+
+/// Notes:
+///   This local index is only valid in processors hold the subblock
+///   returned by subblock_from_global_index.
+
+template <typename ViewT>
+Index<ViewT::dim>
+local_from_global_index(
+  ViewT const&             view,
+  Index<ViewT::dim> const& g_idx)
+VSIP_NOTHROW
+{
+  Index<ViewT::dim> l_idx;
+
+  for (dimension_type d=0; d<ViewT::dim; ++d)
+    l_idx[d] = local_from_global_index(view, d, g_idx[d]);
+
+  return l_idx;
+}
+
+
+
+/// Determine the local index corresponding to VIEW's global index
+/// G_IDX for dimension DIM.
+
+template <typename ViewT>
+index_type
+local_from_global_index(
+  ViewT const&             view,
+  dimension_type           dim,
+  index_type               g_idx)
+VSIP_NOTHROW
+{
+  return view.block().map().impl_local_from_global_index(dim, g_idx);
+}
+
+
+
+/***********************************************************************
+  global_from_local_index
+***********************************************************************/
+
+/// Determine VIEW's global index corresponding to local index L_IDX
+/// of subblock SB.
+
+template <typename ViewT>
+inline
+Index<ViewT::dim>
+global_from_local_index(
+  ViewT const&             view,
+  index_type               sb,
+  Index<ViewT::dim> const& l_idx)
+{
+  Index<ViewT::dim> g_idx;
+
+  for (dimension_type d=0; d<ViewT::dim; ++d)
+    g_idx[d] = global_from_local_index(view, d, sb, l_idx[d]);
+
+  return g_idx;
+}
+
+
+
+/// Determine VIEW's global index corresponding to local index L_IDX
+/// of the subblock held on the local processor.
+
+template <typename ViewT>
+inline
+Index<ViewT::dim>
+global_from_local_index(
+  ViewT const&             view,
+  Index<ViewT::dim> const& l_idx)
+{
+  Index<ViewT::dim> g_idx;
+
+  for (dimension_type d=0; d<ViewT::dim; ++d)
+    g_idx[d] = global_from_local_index(view, d, l_idx[d]);
+
+  return g_idx;
+}
+
+
+
+/// Determine VIEW's global index corresponding to local index L_IDX
+/// for dimension DIM of subblock SB.
+
+template <typename ViewT>
+inline
+index_type
+global_from_local_index(
+  ViewT const&   view,
+  dimension_type dim,
+  index_type     sb,
+  index_type     l_idx)
+{
+  return view.block().map().impl_global_from_local_index(dim, sb, l_idx);
+}
+
+
+
+/// Determine VIEW's global index corresponding to local index L_IDX
+/// for dimension DIM of the subblock held on the local processor.
+
+template <typename ViewT>
+inline
+index_type
+global_from_local_index(
+  ViewT const&   view,
+  dimension_type dim,
+  index_type     l_idx)
+{
+  return view.block().map().impl_global_from_local_index(dim,
+						    view.block().subblock(),
+						    l_idx);
+}
+
+} // namespace vsip
+
+#endif // VSIP_IMPL_PAR_SUPPORT_HPP
Index: src/vsip/impl/par-util.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-util.hpp,v
retrieving revision 1.7
diff -u -r1.7 par-util.hpp
--- src/vsip/impl/par-util.hpp	11 Jan 2006 16:22:45 -0000	1.7
+++ src/vsip/impl/par-util.hpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/impl/par-util.hpp
     @author  Jules Bergmann
@@ -31,8 +31,6 @@
 namespace vsip
 {
 
-const_Vector<processor_type> processor_set();
-
 namespace impl
 {
 
@@ -55,25 +53,24 @@
   ViewT<T, BlockT> view,
   FuncT            fcn)
 {
-  typedef typename BlockT::map_type             map_t;
-  typedef typename BlockT::local_block_type     local_block_t;
-  typedef typename map_t::subblock_iterator subblock_iterator;
+  typedef typename BlockT::map_type         map_t;
+  typedef typename BlockT::local_block_type local_block_t;
 
   dimension_type const dim = ViewT<T, BlockT>::dim;
 
   BlockT&      block = view.block();
-  map_t const& am    = view.block().map();
+  map_t const& map   = view.block().map();
 
-  index_type sb = am.subblock();
+  index_type sb = map.subblock();
 
   if (sb != no_subblock)
   {
     ViewT<T, local_block_t> local_view = get_local_view(view, sb);
 
-    for (index_type p=0; p<am.num_patches(sb); ++p)
+    for (index_type p=0; p<num_patches(view, sb); ++p)
     {
-      Domain<dim> ldom = am.template local_domain<dim>(sb, p);
-      Domain<dim> gdom = am.template global_domain<dim>(sb, p);
+      Domain<dim> ldom = local_domain(view, sb, p);
+      Domain<dim> gdom = global_domain(view, sb, p);
 
       fcn(local_view.get(ldom), gdom);
     }
@@ -82,204 +79,6 @@
 
 
 
-namespace detail
-{
-
-// Return the subdomain of a view/map pair for a subblock.
-
-template <typename ViewT>
-inline Domain<ViewT::dim>
-subblock_domain(
-  ViewT const&        view,
-  Local_map const&    /*map*/,
-  index_type          /*sb*/)
-{
-  return block_domain<ViewT::dim>(view.block());
-}
-
-template <typename ViewT,
-	  typename MapT>
-inline Domain<ViewT::dim>
-subblock_domain(
-  ViewT const&     /*view*/,
-  MapT const&      map,
-  index_type       sb)
-{
-  return map.template subblock_domain<ViewT::dim>(sb);
-}
-
-
-
-// Return the local domain of a view/map pair for a subblock/patch.
-
-template <typename ViewT>
-inline Domain<ViewT::dim>
-local_domain(
-  ViewT const& view,
-  Local_map const&    /*map*/,
-  index_type          /*sb*/,
-  index_type          /*p*/)
-{
-  return block_domain<ViewT::dim>(view.block());
-}
-
-template <typename ViewT,
-	  typename MapT>
-inline Domain<ViewT::dim>
-local_domain(
-  ViewT const&     /*view*/,
-  MapT const&      map,
-  index_type       sb,
-  index_type       p)
-{
-  return map.template local_domain<ViewT::dim>(sb, p);
-}
-
-
-
-// Return the global domain of a view/map pair for a subblock/patch.
-
-template <typename ViewT>
-inline Domain<ViewT::dim>
-global_domain(
-  ViewT const& view,
-  Local_map const&    /*map*/,
-  index_type          /*sb*/,
-  index_type          /*p*/)
-{
-  return block_domain<ViewT::dim>(view.block());
-}
-
-template <typename ViewT,
-	  typename MapT>
-inline Domain<ViewT::dim>
-global_domain(
-  ViewT const&     /*view*/,
-  MapT const&      map,
-  index_type       sb,
-  index_type       p)
-{
-  return map.template global_domain<ViewT::dim>(sb, p);
-}
-
-} // namespace detail
-
-
-
-template <typename ViewT>
-Domain<ViewT::dim>
-subblock_domain(
-  ViewT const&  view,
-  index_type    sb)
-{
-  return detail::subblock_domain(view, view.block().map(), sb);
-}
-
-template <typename ViewT>
-Domain<ViewT::dim>
-subblock_domain(
-  ViewT const&  view)
-{
-  return detail::subblock_domain(view, view.block().map(),
-			      view.block().map().subblock());
-}
-
-
-
-template <typename ViewT>
-Domain<ViewT::dim>
-local_domain(
-  ViewT const&  view,
-  index_type    sb,
-  index_type    p)
-{
-  return detail::local_domain(view, view.block().map(), sb, p);
-}
-
-template <typename ViewT>
-Domain<ViewT::dim>
-local_domain(
-  ViewT const&  view,
-  index_type    p=0)
-{
-  return detail::local_domain(view, view.block().map(),
-			      view.block().map().subblock(),
-			      p);
-}
-
-
-
-template <typename ViewT>
-Domain<ViewT::dim>
-global_domain(
-  ViewT const&  view,
-  index_type    sb,
-  index_type    p)
-{
-  return detail::global_domain(view, view.block().map(), sb, p);
-}
-
-template <typename ViewT>
-Domain<ViewT::dim>
-global_domain(
-  ViewT const&  view,
-  index_type    p=0)
-{
-  return detail::global_domain(view, view.block().map(), 
-			       view.block().map().subblock(),
-			       p);
-}
-
-
-
-template <typename ViewT>
-length_type
-num_patches(
-  ViewT const&  view,
-  index_type    sb)
-{
-  return view.block().map().num_patches(sb);
-}
-
-
-
-template <typename ViewT>
-length_type
-num_patches(
-  ViewT const&  view)
-{
-  return view.block().map().num_patches(view.block().map().subblock());
-}
-
-
-
-template <typename ViewT>
-inline
-index_type
-global_from_local_index(
-  ViewT const&   view,
-  dimension_type dim,
-  index_type     sb,
-  index_type     idx)
-{
-  return view.block().map().global_from_local_index(dim, sb, idx);
-}
-
-template <typename ViewT>
-inline
-index_type
-global_from_local_index(
-  ViewT const&   view,
-  dimension_type dim,
-  index_type     idx)
-{
-  return view.block().map().global_from_local_index(dim,
-						    view.block().subblock(),
-						    idx);
-}
-
-
-
 // Evaluate a function object foreach local element of a distributed view.
 
 // Requires:
@@ -309,7 +108,7 @@
   {
     typename ViewT::local_type local_view = get_local_view(view);
 
-    for (index_type p=0; p<map.num_patches(sb); ++p)
+    for (index_type p=0; p<num_patches(view, sb); ++p)
     {
       Domain<dim> ldom = local_domain(view, sb, p);
       Domain<dim> gdom = global_domain(view, sb, p);
@@ -327,7 +126,6 @@
 
 
 
-
 template <typename T, typename Block>
 void
 buf_send(
Index: src/vsip/impl/replicated_map.hpp
===================================================================
RCS file: src/vsip/impl/replicated_map.hpp
diff -N src/vsip/impl/replicated_map.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/replicated_map.hpp	24 Mar 2006 18:55:40 -0000
@@ -0,0 +1,205 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/replicated_map.hpp
+    @author  Jules Bergmann
+    @date    2005-06-08
+    @brief   VSIPL++ Library: Replicated_map class.
+
+*/
+
+#ifndef VSIP_IMPL_REPLICATED_MAP_HPP
+#define VSIP_IMPL_REPLICATED_MAP_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/vector-iterator.hpp>
+#include <vsip/impl/par-services.hpp>
+#include <vsip/impl/map-traits.hpp>
+#include <vsip/impl/par-util.hpp>
+#include <vsip/impl/block-traits.hpp>
+#include <vsip/impl/sv_block.hpp>
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
+template <dimension_type Dim>
+class Replicated_map
+{
+  // Compile-time typedefs.
+public:
+  typedef impl::Vector_iterator<Vector<processor_type> > processor_iterator;
+  typedef std::vector<processor_type> impl_pvec_type;
+  typedef impl::Sv_local_block<processor_type> pset_block_type;
+
+  // Constructor.
+public:
+  Replicated_map()
+    VSIP_THROW((std::bad_alloc));
+
+  template <typename Block>
+  Replicated_map(const_Vector<processor_type, Block> pset)
+    VSIP_THROW((std::bad_alloc));
+
+  // Accessors.
+public:
+  length_type num_subblocks() const VSIP_NOTHROW { return 1; }
+
+  index_type subblock(processor_type pr) const VSIP_NOTHROW
+  {
+    if (this->impl_rank_from_proc(pr) != no_processor)
+      return 0;
+    else
+      return no_subblock;
+  }
+  index_type subblock() const VSIP_NOTHROW
+  { return this->subblock(local_processor()); }
+
+  length_type num_processors() const VSIP_NOTHROW
+    { return this->pset_->size(); }
+
+  processor_iterator processor_begin(index_type sb) const VSIP_NOTHROW
+  {
+    assert(sb == 0);
+    return processor_iterator(this->processor_set(), 0);
+  }
+
+  processor_iterator processor_end  (index_type sb) const VSIP_NOTHROW
+  {
+    assert(sb == 0);
+    return processor_iterator(this->processor_set(), this->num_processors());
+  }
+
+  const_Vector<processor_type, pset_block_type> processor_set() const
+  {
+    return const_Vector<processor_type, pset_block_type>(
+      const_cast<pset_block_type&>(*pset_));
+  }
+
+  // Applied map functions.
+public:
+  length_type impl_num_patches(index_type sb) const VSIP_NOTHROW
+    { assert(sb == 0); return 1; }
+
+  void impl_apply(Domain<Dim> const& dom) VSIP_NOTHROW
+    { dom_ = dom; }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_subblock_domain(index_type sb) const VSIP_NOTHROW
+    { assert(sb == 0); return dom_; }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_global_domain(index_type sb, index_type patch)
+    const VSIP_NOTHROW
+    { assert(sb == 0 && patch == 0); return dom_; }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_local_domain (index_type sb, index_type patch)
+    const VSIP_NOTHROW
+    { assert(sb == 0 && patch == 0); return dom_; }
+
+  index_type impl_global_from_local_index(dimension_type /*d*/, index_type sb,
+					  index_type idx)
+    const VSIP_NOTHROW
+  { assert(sb == 0); return idx; }
+
+  index_type impl_local_from_global_index(dimension_type /*d*/, index_type idx)
+    const VSIP_NOTHROW
+  { return idx; }
+
+  template <dimension_type Dim2>
+  index_type impl_subblock_from_global_index(Index<Dim2> const& /*idx*/)
+    const VSIP_NOTHROW
+  { return 0; }
+
+  // Extensions.
+public:
+  impl::Communicator impl_comm() const { return impl::default_communicator(); }
+  impl_pvec_type     impl_pvec() const
+    { return this->pset_->impl_vector(); }
+
+  length_type        impl_working_size() const
+    { return this->num_processors(); }
+
+  processor_type impl_proc_from_rank(index_type idx) const
+    { assert(idx < this->num_processors()); return this->impl_pvec()[idx]; }
+
+  index_type impl_rank_from_proc(processor_type pr) const
+  {
+    for (index_type i=0; i<this->num_processors(); ++i)
+      if (pset_->get(i) == pr) return i;
+    return no_processor;
+  }
+
+  // Member data.
+private:
+  impl::Ref_counted_ptr<pset_block_type> pset_;
+  // impl_pvec_type pset_;		// Processor set.
+  Domain<Dim>    dom_;		// Applied domain.
+};
+
+
+
+template <dimension_type Dim>
+Replicated_map<Dim>::Replicated_map()
+  VSIP_THROW((std::bad_alloc))
+    : pset_(new pset_block_type(vsip::num_processors()), impl::noincrement)
+{
+  for (index_type i=0; i<vsip::num_processors(); ++i)
+    pset_->put(i, vsip::processor_set().get(i));
+}
+
+
+
+// Create a replicated_map with a given processor_set
+//
+// Requires
+//   PSET to be a non-empty set of valid processors.
+template <dimension_type Dim>
+template <typename Block>
+Replicated_map<Dim>::Replicated_map(
+  const_Vector<processor_type, Block> pset)
+  VSIP_THROW((std::bad_alloc))
+: pset_(new pset_block_type(pset.size()), impl::noincrement)
+{
+  assert(pset.size() > 0);
+  for (index_type i=0; i<pset.size(); ++i)
+    pset_->put(i, pset.get(i));
+}
+
+
+
+namespace impl
+{
+
+template <dimension_type Dim>
+struct Is_global_map<Replicated_map<Dim> >
+{ static bool const value = true; };
+
+template <dimension_type Dim>
+struct Map_equal<Replicated_map<Dim>, Replicated_map<Dim> >
+{
+  static bool value(Replicated_map<Dim> const& a,
+		    Replicated_map<Dim> const& b)
+  {
+    if (a.num_processors() != b.num_processors())
+      return false;
+    for (index_type i=0; i<a.num_processors(); ++i)
+      if (a.impl_proc_from_rank(i) != b.impl_proc_from_rank(i))
+	return false;
+    return true;
+  }
+};
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_IMPL_REPLICATED_MAP_HPP
Index: src/vsip/impl/subblock.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/subblock.hpp,v
retrieving revision 1.38
diff -u -r1.38 subblock.hpp
--- src/vsip/impl/subblock.hpp	10 Feb 2006 22:24:02 -0000	1.38
+++ src/vsip/impl/subblock.hpp	24 Mar 2006 18:55:40 -0000
@@ -286,7 +286,7 @@
       assert(dom_[d].first() < blk_->size(dim, d));
       assert(dom_[d].impl_last() < blk_->size(dim, d));
     }
-    map_.apply(block_domain<dim>(*this));
+    map_.impl_apply(block_domain<dim>(*this));
   }
 
   Subset_block(Subset_block const& b)
@@ -294,7 +294,7 @@
       dom_ (b.dom_),
       map_ (b.map_)
   {
-    map_.apply(block_domain<dim>(*this));
+    map_.impl_apply(block_domain<dim>(*this));
   }
 
   ~Subset_block() VSIP_NOTHROW {}
@@ -817,13 +817,13 @@
   // Constructors and destructors.
   Sliced_block_base(Sliced_block_base const& sb) VSIP_NOTHROW
     : map_(sb.map_), blk_(&*sb.blk_), index_(sb.index_)
-  { map_.apply(block_domain<dim>(*this)); }
+  { map_.impl_apply(block_domain<dim>(*this)); }
   Sliced_block_base(Block &blk, index_type i) VSIP_NOTHROW
     : map_(Sliced_block_map<typename Block::map_type,
 	                    D>::convert_map(blk.map(), i)),
       blk_(&blk),
       index_(i)
-  { map_.apply(block_domain<dim>(*this)); }
+  { map_.impl_apply(block_domain<dim>(*this)); }
   ~Sliced_block_base() VSIP_NOTHROW {}
 
   map_type const& map() const { return map_;}
@@ -832,10 +832,10 @@
   // The total size of a sliced block is the total size of the underlying
   // block, divided by the size of the bound index.
   length_type size() const VSIP_NOTHROW
-  { return blk_->size() / blk_->size(Block::dim, D);}
+  { return index_ == no_index ? 0 : blk_->size() / blk_->size(Block::dim, D);}
   length_type size(dimension_type block_d, dimension_type d) const VSIP_NOTHROW
-  { return blk_->size(block_d + 1,
-		      Compare<dimension_type, D>() > d ? d : d + 1);
+  { return index_ == no_index ? 0 :
+      blk_->size(block_d + 1, Compare<dimension_type, D>() > d ? d : d + 1);
   }
   // These are noops as Sliced_block is helt by-value.
   void increment_count() const VSIP_NOTHROW {}
@@ -1000,13 +1000,13 @@
   // Constructors and destructors.
   Sliced2_block_base(Sliced2_block_base const& sb) VSIP_NOTHROW
     : map_(sb.map_), blk_(&*sb.blk_), index1_(sb.index1_), index2_(sb.index2_)
-  { map_.apply(block_domain<dim>(*this)); }
+  { map_.impl_apply(block_domain<dim>(*this)); }
   Sliced2_block_base(Block &blk, index_type i, index_type j) VSIP_NOTHROW
     : map_(Sliced2_block_map<typename Block::map_type,
 	                     D1,
 	                     D2>::convert_map(blk.map(), i, j)),
       blk_(&blk), index1_(i), index2_(j)
-  { map_.apply(block_domain<dim>(*this)); }
+  { map_.impl_apply(block_domain<dim>(*this)); }
   ~Sliced2_block_base() VSIP_NOTHROW {}
 
   map_type const& map() const { return map_;}
@@ -1277,7 +1277,7 @@
 
   dimension_type const dim = Subset_block<Block>::dim;
 
-  index_type sb = block.map().lookup_index(block.map().impl_rank());
+  index_type sb = block.map().impl_rank_from_proc(local_processor());
 
   Domain<dim> dom = block.impl_block().map().
     impl_local_from_global_domain(sb,
@@ -1300,8 +1300,15 @@
   typedef Sliced_block<typename Distributed_local_block<Block>::type, D>
 	local_block_type;
 
-  index_type idx = block.impl_block().map().
-    impl_local_from_global_index(D, block.impl_index());
+  // This conversion is only valid if the local processor holds
+  // the subblock containing the slice.
+
+  index_type idx;
+  if (block.map().subblock() != no_subblock)
+    idx = block.impl_block().map().
+      impl_local_from_global_index(D, block.impl_index());
+  else
+    idx = no_index;
 
   return local_block_type(get_local_block(block.impl_block()), idx);
 }
Index: src/vsip/impl/sv_block.hpp
===================================================================
RCS file: src/vsip/impl/sv_block.hpp
diff -N src/vsip/impl/sv_block.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/sv_block.hpp	24 Mar 2006 18:55:40 -0000
@@ -0,0 +1,114 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/sv_block.hpp
+    @author  Jules Bergmann
+    @date    2006-03-09
+    @brief   VSIPL++ Library: std::vector block class.
+
+*/
+
+#ifndef VSIP_IMPL_SV_BLOCK_HPP
+#define VSIP_IMPL_SV_BLOCK_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/domain.hpp>
+
+#include <vsip/impl/refcount.hpp>
+#include <vsip/impl/block-traits.hpp>
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
+
+
+template <typename T>
+class Sv_local_block
+  : public impl::Ref_count<Sv_local_block<T> >
+{
+  // Compile-time values and types.
+  typedef std::vector<T> vector_type;
+public:
+  static dimension_type const dim = 1;
+
+  typedef T        value_type;
+  typedef T&       reference_type;
+  typedef T const& const_reference_type;
+
+  typedef row1_type order_type;
+  typedef Local_map map_type;
+
+  // Implementation types.
+public:
+
+  // Constructors and destructor.
+public:
+  Sv_local_block(Domain<1> const& dom, map_type const& = map_type())
+    VSIP_THROW((std::bad_alloc))
+    : vector_(dom[0].size())
+  {}
+
+  Sv_local_block(Domain<1> const& dom, T value, map_type const& = map_type())
+    VSIP_THROW((std::bad_alloc))
+    : vector_(dom[0].size())
+  {
+    for (index_type i=0; i<dom[0].size(); ++i)
+      this->put(i, value);
+  }
+
+  ~Sv_local_block() VSIP_NOTHROW
+  {}
+
+  // Data accessors.
+public:
+  T get(index_type idx) const VSIP_NOTHROW
+  {
+    assert(idx < size());
+    return vector_[idx];
+  }
+
+  void put(index_type idx, T val) VSIP_NOTHROW
+  {
+    assert(idx < size());
+    vector_[idx] = val;
+  }
+
+  // Accessors.
+public:
+  length_type size() const VSIP_NOTHROW
+    { return vector_.size(); }
+  length_type size(dimension_type D, dimension_type d) const VSIP_NOTHROW
+    { assert(D == 1 && d == 0); return vector_.size(); }
+
+  map_type const& map() const VSIP_NOTHROW { return map_; }
+
+  vector_type impl_vector() { return vector_; }
+
+  // Hidden copy constructor and assignment.
+private:
+  Sv_local_block(Sv_local_block const&);
+  Sv_local_block& operator=(Sv_local_block const&);
+
+  // Member Data
+private:
+  vector_type vector_;
+  map_type    map_;
+};
+
+
+} // namespace impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_SV_BLOCK_HPP
Index: tests/appmap.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/appmap.cpp,v
retrieving revision 1.9
diff -u -r1.9 appmap.cpp
--- tests/appmap.cpp	20 Dec 2005 12:48:40 -0000	1.9
+++ tests/appmap.cpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    tests/appmap.cpp
     @author  Jules Bergmann
@@ -19,12 +19,22 @@
 using namespace std;
 using namespace vsip;
 
+using vsip::impl::Point;
+using vsip::impl::extent_old;
+using vsip::impl::valid;
+using vsip::impl::next;
+using vsip::impl::domain_nth;
+
 
 
 /***********************************************************************
   Definitions
 ***********************************************************************/
 
+
+/// Get the nth index in a domain.
+
+
 // Utility to create a processor vector of given size.
 
 // Requires:
@@ -70,10 +80,10 @@
     
     if (sb != no_subblock)
     {
-      for (index_type p=0; p<map.num_patches(sb); ++p)
+      for (index_type p=0; p<map.impl_num_patches(sb); ++p)
       {
-	Domain<3> gdom = map.template global_domain<3>(sb, p);
-	Domain<3> ldom = map.template local_domain<3>(sb, p);
+	Domain<3> gdom = map.template impl_global_domain<3>(sb, p);
+	Domain<3> ldom = map.template impl_local_domain<3>(sb, p);
 	out << "  pr=" << pr << "  sb=" << sb << " patch=" << p
 	    << "  gdom=" << gdom
 	    << "  ldom=" << ldom
@@ -85,6 +95,12 @@
 
 
 
+inline Index<1> as_index(Point<1> const& p) {return Index<1>(p[0]); }
+inline Index<2> as_index(Point<2> const& p) {return Index<2>(p[0],p[1]); }
+inline Index<3> as_index(Point<3> const& p) {return Index<3>(p[0],p[1],p[2]); }
+
+
+
 // Check that local and global indices within a patch are consistent.
 
 template <dimension_type Dim,
@@ -95,11 +111,26 @@
   index_type    sb,
   index_type    p)
 {
-  Domain<Dim> gdom = map.template global_domain<Dim>(sb, p);
-  Domain<Dim> ldom = map.template local_domain<Dim>(sb, p);
+  Domain<Dim> gdom = map.template impl_global_domain<Dim>(sb, p);
+  Domain<Dim> ldom = map.template impl_local_domain<Dim>(sb, p);
 
   test_assert(gdom.size() == ldom.size());
 
+  length_type dim_num_subblocks[Dim]; // number of subblocks in each dim
+  length_type dim_sb[Dim];            // local sb in each dim
+  length_type dim_num_patches[Dim];   // number of patches in each dim
+  length_type dim_p[Dim];             // local p in each dim
+
+  for (dimension_type d=0; d<Dim; ++d)
+    dim_num_subblocks[d] = map.num_subblocks(d);
+  
+  impl::split_tuple(sb, Dim, dim_num_subblocks, dim_sb);
+
+  for (dimension_type d=0; d<Dim; ++d)
+    dim_num_patches[d] = map.impl_subblock_patches(d, dim_sb[d]);
+
+  impl::split_tuple(p, Dim, dim_num_patches, dim_p);
+
   for (dimension_type d=0; d<Dim; ++d)
   {
     test_assert(gdom[d].length() == ldom[d].length());
@@ -109,17 +140,24 @@
       index_type gi = gdom[d].impl_nth(i);
       index_type li = ldom[d].impl_nth(i);
 
-      if (map.distribution(d) != cyclic)
-      {
-	test_assert(map.impl_local_from_global_index(d, gi) == li);
-	// only valid for 1-dim
-	// test_assert(map.impl_subblock_from_index(d, gi) == sb);
-      }
-      test_assert(map.global_from_local_index(d, sb, li) == gi);
+      test_assert(map.impl_local_from_global_index(d, gi) == li);
+      test_assert(map.impl_global_from_local_index(d, sb, li) == gi);
+      test_assert(map.impl_dim_subblock_from_index(d, gi) == dim_sb[d]);
+      test_assert(map.impl_dim_patch_from_index(d, gi) == dim_p[d]);
     }
   }
-}
 
+  Point<Dim> ext = extent_old(gdom);
+
+  for (Point<Dim> idx; valid(ext, idx); next(ext, idx))
+  {
+    Index<Dim> g_idx = as_index(domain_nth(gdom, idx));
+    Index<Dim> l_idx = as_index(domain_nth(ldom, idx));
+
+    test_assert(map.impl_subblock_from_global_index(g_idx) == sb);
+    test_assert(map.impl_patch_from_global_index(g_idx)    == p);
+  }
+}
 
 
 
@@ -142,7 +180,7 @@
   Vector<processor_type> pvec = create_pvec(num_proc);
 
   map_t map(pvec, dist0);
-  map.apply(Domain<dim>(dom.length()));
+  map.impl_apply(Domain<dim>(dom.length()));
 
   Vector<int> data(dom.length(), 0);
 
@@ -153,9 +191,9 @@
     
     if (sb != no_subblock)
     {
-      for (index_type p=0; p<map.num_patches(sb); ++p)
+      for (index_type p=0; p<map.impl_num_patches(sb); ++p)
       {
-	Domain<dim> gdom = map.template global_domain<dim>(sb, p);
+	Domain<dim> gdom = map.template impl_global_domain<dim>(sb, p);
 
 	if (gdom.size() > 0)
 	  data(gdom) += 1;
@@ -193,7 +231,7 @@
   Vector<processor_type> pvec = create_pvec(num_proc);
 
   map_t map(pvec, dist0, dist1);
-  map.apply(dom);
+  map.impl_apply(dom);
 
   Matrix<int> data(dom[0].length(), dom[1].length(), 0);
 
@@ -204,9 +242,9 @@
     
     if (sb != no_subblock)
     {
-      for (index_type p=0; p<map.num_patches(sb); ++p)
+      for (index_type p=0; p<map.impl_num_patches(sb); ++p)
       {
-	Domain<dim> gdom = map.template global_domain<dim>(sb, p);
+	Domain<dim> gdom = map.template impl_global_domain<dim>(sb, p);
 
 	data(gdom) += 1;
 
@@ -294,23 +332,26 @@
   Vector<processor_type> pvec = create_pvec(num_proc);
 
   map_t map(pvec, Block_dist(4), Block_dist(4));
-  map.apply(Domain<3>(16, 16, 1));
+  map.impl_apply(Domain<3>(16, 16, 1));
 
-  test_assert(map.num_patches(0) == 1);
-  test_assert(map.global_domain<3>(0, 0) == Domain<3>(Domain<1>(0, 1, 4),
-						      Domain<1>(0, 1, 4),
-						      Domain<1>(0, 1, 1)));
+  test_assert(map.impl_num_patches(0) == 1);
+  test_assert(map.impl_global_domain<3>(0, 0) ==
+	      Domain<3>(Domain<1>(0, 1, 4),
+			Domain<1>(0, 1, 4),
+			Domain<1>(0, 1, 1)));
 
   // subblocks are row-major
-  test_assert(map.num_patches(1) == 1);
-  test_assert(map.global_domain<3>(1, 0) == Domain<3>(Domain<1>(0, 1, 4),
-						      Domain<1>(4, 1, 4),
-						      Domain<1>(0, 1, 1)));
-
-  test_assert(map.num_patches(15) == 1);
-  test_assert(map.global_domain<3>(15, 0) == Domain<3>(Domain<1>(12, 1, 4),
-						       Domain<1>(12, 1, 4),
-						       Domain<1>(0, 1, 1)));
+  test_assert(map.impl_num_patches(1) == 1);
+  test_assert(map.impl_global_domain<3>(1, 0) ==
+	      Domain<3>(Domain<1>(0, 1, 4),
+			Domain<1>(4, 1, 4),
+			Domain<1>(0, 1, 1)));
+
+  test_assert(map.impl_num_patches(15) == 1);
+  test_assert(map.impl_global_domain<3>(15, 0) ==
+	      Domain<3>(Domain<1>(12, 1, 4),
+			Domain<1>(12, 1, 4),
+			Domain<1>(0, 1, 1)));
 }
 
 
Index: tests/replicated_map.cpp
===================================================================
RCS file: tests/replicated_map.cpp
diff -N tests/replicated_map.cpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ tests/replicated_map.cpp	24 Mar 2006 18:55:40 -0000
@@ -0,0 +1,124 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/replicated_map.cpp
+    @author  Jules Bergmann
+    @date    2006-03-09
+    @brief   VSIPL++ Library: Unit tests for Replicated_map.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/map.hpp>
+#include <vsip/initfin.hpp>
+
+#include "test.hpp"
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
+template <dimension_type Dim,
+	  typename       Block>
+void
+check_replicated_map(
+  Replicated_map<Dim> const&          map,
+  const_Vector<processor_type, Block> pset)
+{
+  typedef Replicated_map<Dim> map_type;
+  typedef typename map_type::processor_iterator iterator;
+
+  // Check num_processors()
+  test_assert(map.num_processors() == pset.size());
+
+  // Check processor_set()
+  Vector<processor_type> map_pset = map.processor_set();
+
+  test_assert(map_pset.size() == pset.size());
+  for (index_type i=0; i<map_pset.size(); ++i)
+    test_assert(map_pset(i) == pset(i));
+
+  // Check processor_begin(), processor_end()
+  iterator begin = map.processor_begin(0);
+  iterator end   = map.processor_end(0);
+
+  assert(static_cast<length_type>(end - begin) == pset.size());
+
+  iterator cur = begin;
+  while (cur != end)
+  {
+    index_type i = cur - begin;
+    test_assert(*cur == pset(i));
+    ++cur;
+  }
+}
+
+
+
+// Check that map can be constructed with a processor set.
+
+template <dimension_type Dim,
+	  typename       Block>
+void
+test_single_pset(const_Vector<processor_type, Block> pset)
+{
+  typedef Replicated_map<Dim> map_type;
+
+  map_type map(pset);
+  check_replicated_map(map, pset);
+}
+
+
+
+// Check that map can be constructed with default processor set.
+
+template <dimension_type Dim>
+void
+test_default_pset()
+{
+  typedef Replicated_map<Dim> map_type;
+
+  map_type map;
+  check_replicated_map(map, vsip::processor_set());
+}
+
+
+
+template <dimension_type Dim>
+void
+test_pset()
+{
+  Vector<processor_type> vec1(1);
+  Vector<processor_type> vec4(4);
+
+  vec1(0) = 1;
+
+  vec4(0) = 3;
+  vec4(1) = 2;
+  vec4(2) = 1;
+  vec4(3) = 0;
+
+  test_single_pset<Dim>(vec1);
+  test_single_pset<Dim>(vec4);
+
+  test_default_pset<Dim>();
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl vpp(argc, argv);
+
+  test_pset<1>();
+  test_pset<2>();
+  test_pset<3>();
+}
Index: tests/util-par.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/util-par.hpp,v
retrieving revision 1.7
diff -u -r1.7 util-par.hpp
--- tests/util-par.hpp	5 Dec 2005 19:19:19 -0000	1.7
+++ tests/util-par.hpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    tests/util-par.hpp
     @author  Jules Bergmann
@@ -19,6 +19,7 @@
 
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
+#include <vsip/parallel.hpp>
 
 #include "output.hpp"
 #include "extdata-output.hpp"
@@ -123,10 +124,11 @@
   map_t const& am     = view.block().map();
 
   msg(am, std::string(name) + " ------------------------------------------\n");
-  std::cout << "(" << am.impl_rank() << "): dump_view(" << name << ")\n";
-  std::cout << "(" << am.impl_rank() << "):    map   "
+  std::cout << "(" << vsip::local_processor() << "): dump_view(" << name
+	    << ")\n";
+  std::cout << "(" << vsip::local_processor() << "):    map   "
 	    << Type_name<map_t>::name() << "\n";
-  std::cout << "(" << am.impl_rank() << "):    block "
+  std::cout << "(" << vsip::local_processor() << "):    block "
 	    << Type_name<Block>::name() << "\n";
 
   index_type sb = am.subblock();
@@ -181,7 +183,8 @@
   map_t const& am    = view.block().map();
 
   msg(am, std::string(name) + " ------------------------------------------\n");
-  std::cout << "(" << am.impl_rank() << "): dump_view(Matrix " << name << ")\n";
+  std::cout << "(" << vsip::local_processor() << "): dump_view(Matrix "
+	    << name << ")\n";
 
   index_type sb = am.subblock();
   if (sb != no_subblock)
@@ -209,7 +212,7 @@
 	  index_type gr = gdom[0].impl_nth(r);
 	  index_type gc = gdom[1].impl_nth(c);
 
-	  std::cout << "(" << am.impl_rank() << ") " << sb << "/" << p
+	  std::cout << "(" << vsip::local_processor() << ") " << sb << "/" << p
 	       << "    ["
 	       << lr << "," << lc << ":"
 	       << gr << "," << gc << "] = "
@@ -234,12 +237,12 @@
 dump_map(MapT const& map)
 {
   typedef typename MapT::processor_iterator p_iter_t;
-  vsip::processor_type rank = map.impl_rank();
+  vsip::processor_type rank = vsip::local_processor();
 
   std::ostringstream s;
-  s << map.impl_proc(0);
-  for (vsip::index_type i=1; i<map.impl_num_procs(); ++i)
-    s << "," << map.impl_proc(i);
+  s << map.impl_proc_from_rank(0);
+  for (vsip::index_type i=1; i<map.num_processors(); ++i)
+    s << "," << map.impl_proc_from_rank(i);
 
   std::cout << rank << ": " << Type_name<MapT>::name()
 	    << " [" << s.str() << "]"
@@ -248,8 +251,8 @@
   for (vsip::index_type sb=0; sb<map.num_subblocks(); ++sb)
   {
     std::cout << "  sub " << sb << ": ";
-    if (map.impl_is_applied())
-      std::cout << map.template global_domain<Dim>(sb, 0);
+    // if (map.impl_is_applied())
+    std::cout << map.template impl_global_domain<Dim>(sb, 0);
     std::cout << " [";
 
     for (p_iter_t p=map.processor_begin(sb); p != map.processor_end(sb); ++p)
Index: tests/parallel/block.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/parallel/block.cpp,v
retrieving revision 1.1
diff -u -r1.1 block.cpp
--- tests/parallel/block.cpp	16 Mar 2006 03:27:10 -0000	1.1
+++ tests/parallel/block.cpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    tests/parallel/block.cpp
     @author  Jules Bergmann
@@ -58,17 +58,14 @@
   typename ViewT<T, BlockT>::local_type lview = view.local();
 
   index_type sb = map.subblock();
+
+  Domain<Dim> dom = subblock_domain(view, sb);
+  test_assert(lview.size() == impl::size(dom));
+  for (dimension_type d=0; d<Dim; ++d)
+    test_assert(lview.size(d) == dom[d].size());
+
   if (sb == no_subblock)
-  {
     test_assert(lview.size() == 0);
-  }
-  else
-  {
-    Domain<Dim> dom = map.template subblock_domain<Dim>(sb);
-    test_assert(lview.size() == impl::size(dom));
-    for (dimension_type d=0; d<Dim; ++d)
-      test_assert(lview.size(d) == dom[d].size());
-  }
 }
 
 
@@ -161,7 +158,7 @@
   Par_assign<Dim, T, T, dist_block0_t, dist_block2_t>
 		a3(view0, view2);
 
-  // cout << "(" << map1.impl_rank() << "): test_distributed_view\n";
+  // cout << "(" << local_processor() << "): test_distributed_view\n";
 
   for (int l=0; l<loop; ++l)
   {
@@ -183,7 +180,7 @@
 
   typename view0_t::local_type local_view = view0.local();
 
-  if (map1.impl_rank() == 0) 
+  if (local_processor() == 0) 
   {
     // On processor 0, local_view should be entire view.
     test_assert(extent_old(local_view) == extent_old(dom));
@@ -262,7 +259,7 @@
 
   impl::Communicator comm = impl::default_communicator();
 
-  // cout << "(" << map1.impl_rank() << "): test_distributed_view\n";
+  // cout << "(" << local_processor() << "): test_distributed_view\n";
 
   for (int l=0; l<loop; ++l)
   {
@@ -282,7 +279,7 @@
   // Check results.
   comm.barrier();
 
-  if (map1.impl_rank() == 0) 
+  if (local_processor() == 0) 
   {
     typename view0_t::local_type local_view = view0.local();
 
Index: tests/parallel/corner-turn.cpp
===================================================================
RCS file: tests/parallel/corner-turn.cpp
diff -N tests/parallel/corner-turn.cpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ tests/parallel/corner-turn.cpp	24 Mar 2006 18:55:40 -0000
@@ -0,0 +1,98 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/corner-turn.cpp
+    @author  Jules Bergmann
+    @date    2006-02-14
+    @brief   VSIPL++ Library: Functional test for corner-turns.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <unistd.h>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/map.hpp>
+#include <vsip/tensor.hpp>
+#include <vsip/parallel.hpp>
+
+#include "test.hpp"
+#include "output.hpp"
+#include "util.hpp"
+#include "util-par.hpp"
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
+int
+main(int argc, char** argv)
+{
+  vsipl vpp(argc, argv);
+
+#if 0
+  // Enable this section for easier debugging.
+  impl::Communicator comm = impl::default_communicator();
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
+  typedef float T;
+
+  typedef Map<Block_dist, Block_dist> map_type;
+  typedef Dense<2, T, row2_type, map_type> block_type;
+
+  processor_type np   = num_processors();
+
+  length_type rows = 32;
+  length_type cols = 64;
+
+  map_type root_map(1, 1);
+  map_type row_map (np, 1);
+  map_type col_map (1, np);
+
+  Matrix<T, block_type> src(rows, cols, root_map);
+  Matrix<T, block_type> A  (rows, cols, row_map);
+  Matrix<T, block_type> B  (rows, cols, col_map);
+  Matrix<T, block_type> dst(rows, cols, root_map);
+
+  if (root_map.subblock() != no_subblock)
+  {
+    // cout << local_processor() << "/" << np << ": initializing " << endl;
+    for (index_type r=0; r<rows; ++r)
+      for (index_type c=0; c<rows; ++c)
+	src.local().put(r, c, T(r*cols+c));
+  }
+
+  A   = src; // scatter
+  B   = A;   // corner-turn
+  dst = B;   // gather
+
+  if (root_map.subblock() != no_subblock)
+  {
+    // cout << local_processor() << "/" << np << ": checking " << endl;
+    for (index_type r=0; r<rows; ++r)
+      for (index_type c=0; c<rows; ++c)
+	test_assert(equal(src.local().get(r, c),
+			  dst.local().get(r, c)));
+  }
+
+  return 0;
+}
Index: tests/parallel/expr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/parallel/expr.cpp,v
retrieving revision 1.1
diff -u -r1.1 expr.cpp
--- tests/parallel/expr.cpp	16 Mar 2006 03:27:10 -0000	1.1
+++ tests/parallel/expr.cpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    tests/parallel/expr.cpp
     @author  Jules Bergmann
@@ -159,7 +159,7 @@
 
   impl::Communicator comm = impl::default_communicator();
 
-  // cout << "(" << map1.impl_rank() << "): test_distributed_view\n";
+  // cout << "(" << local_processor() << "): test_distributed_view\n";
 
   foreach_point(A, Set_identity<Dim>(dom, 2, 1));
   foreach_point(B, Set_identity<Dim>(dom, 3, 2));
@@ -213,7 +213,7 @@
   foreach_point(Z7, checker5);
   test_assert(checker5.good());
 
-  if (map_res.impl_rank() == 0) // rank(map_res) == 0
+  if (map_res.subblock() != no_subblock)
   {
     typename view0_t::local_type local_view = chk1.local();
 
@@ -325,7 +325,7 @@
   // Check results.
   comm.barrier();
 
-  if (map_res.impl_rank() == 0) 
+  if (map0.subblock() != no_subblock)
   {
     typename view0_t::local_type local_view = chk1.local();
 
@@ -434,7 +434,7 @@
   // Check results.
   comm.barrier();
 
-  if (map_res.impl_rank() == 0) 
+  if (map0.subblock() != no_subblock)
   {
     typename view0_t::local_type local_view = chk.local();
 
@@ -636,6 +636,13 @@
     Global_map<1>(),
     loop);
 
+  test_distributed_expr<float>(
+    Domain<1>(16),
+    Replicated_map<1>(),
+    Replicated_map<1>(),
+    Replicated_map<1>(),
+    loop);
+
   test_vector_assign<float>(loop);
   test_matrix_assign<float>(loop);
   
Index: tests/parallel/fftm.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/parallel/fftm.cpp,v
retrieving revision 1.1
diff -u -r1.1 fftm.cpp
--- tests/parallel/fftm.cpp	16 Mar 2006 03:27:10 -0000	1.1
+++ tests/parallel/fftm.cpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    tests/parallel/fftm.cpp
     @author  Nathan Myers
@@ -101,51 +101,23 @@
   test_assert(in.size(0) == 5);
   length_type const N = in.size(1);
 
-  Block& block = in.block();
-  Matrix<T,Dense<2,T,tuple<0,1,2>,Local_map> >  local_in(
-      block.get_local_block());
+  in.row(0)    = T();
 
-  if (block.subblock() == block.map().impl_subblock_from_index(0,0))
-  {
-    unsigned ix = block.map().impl_local_from_global_index(0,0);
-    local_in.row(ix)    = T();
-  }
-
-  if (block.subblock() == block.map().impl_subblock_from_index(0,1))
-  {
-    unsigned ix = block.map().impl_local_from_global_index(0,1);
-    local_in.row(ix)    = T();
-    local_in.row(ix)(0) = T(scale);
-  }
+  in.row(1)    = T();
+  in.row(1)(0) = T(scale);
 
-  if (block.subblock() == block.map().impl_subblock_from_index(0,2))
-  {
-    unsigned ix = block.map().impl_local_from_global_index(0,2);
-    local_in.row(ix)    = T();
-    local_in.row(ix)(0) = T(1);
-    local_in.row(ix)(Domain<1>(0, 1, N))    += T(3);
-    if (local_in.size(1) > 4)
-      local_in.row(ix)(Domain<1>(0, 4, N/4))  += T(-2);
-    if (local_in.size(1) > 13)
-      local_in.row(ix)(Domain<1>(0, 13, N/13)) += T(7);
-    if (local_in.size(1) > 27)
-      local_in.row(ix)(Domain<1>(0, 27, N/27)) += T(-15);
-    if (local_in.size(1) > 37)
-      local_in.row(ix)(Domain<1>(0, 37, N/37)) += T(31);
-  }
+  in.row(2)    = T();
+  in.row(2)(0) = T(1);
+  in.row(2)(Domain<1>(0, 1, N))    += T(3);
+  if (in.size(1) > 4)  in.row(2)(Domain<1>(0, 4, N/4))   += T(-2);
+  if (in.size(1) > 13) in.row(2)(Domain<1>(0, 13, N/13)) += T(7);
+  if (in.size(1) > 27) in.row(2)(Domain<1>(0, 27, N/27)) += T(-15);
+  if (in.size(1) > 37) in.row(2)(Domain<1>(0, 37, N/37)) += T(31);
 
-  if (block.subblock() == block.map().impl_subblock_from_index(0,3))
-  {
-    unsigned ix = block.map().impl_local_from_global_index(0,3);
-    local_in.row(ix)    = T(scale);
-  } 
+  in.row(3)    = T(scale);
 
-  if (block.subblock() == block.map().impl_subblock_from_index(0,4))
-  {
-    unsigned ix = block.map().impl_local_from_global_index(0,4);
-    for (unsigned i = 0; i < N; ++i)
-      local_in.row(ix)(i)    = T(std::sin(3.1415926535898*i*4/N));
-  }
+  for (unsigned i = 0; i < N; ++i)
+    in.row(4)(i) = T(std::sin(3.1415926535898*i*4/N));
 }
 
 
@@ -269,96 +241,23 @@
   test_assert(in.size(1) == 5);
   length_type const N = in.size(0);
 
-#if 0
-  typedef Map<Block_dist,Block_dist>  map_type;
-  map_type  map(Block_dist(1), Block_dist(1));
-
-  typedef Dense<2,T,tuple<0,1,2>,map_type>  here_block_type;
-  typedef Matrix<T,here_block_type>  here_matrix_type;
-
-  Domain<2>  domain(Domain<1>(N), Domain<1>(5));
-  here_block_type  in_block(domain, map);
-  here_matrix_type  in(in_block);
-#endif
-
-  Block& block = in.block();
-  Matrix<T,Dense<2,T,tuple<0,1,2>,Local_map> >  local_in(
-      block.get_local_block());
-
-#if 1
-  if (block.subblock() == block.map().impl_subblock_from_index(1,0))
-  {
-    unsigned ix = block.map().impl_local_from_global_index(1,0);
-    local_in.col(ix)    = T();
-  }
-
-  if (block.subblock() == block.map().impl_subblock_from_index(1,1))
-  {
-    unsigned ix = block.map().impl_local_from_global_index(1,1);
-    local_in.col(ix)    = T();
-    local_in.col(ix)(0) = T(scale);
-  }
-
-  if (block.subblock() == block.map().impl_subblock_from_index(1,2))
-  {
-    unsigned ix = block.map().impl_local_from_global_index(1,2);
-    local_in.col(ix)    = T();
-    local_in.col(ix)(0) = T(1);
-    local_in.col(ix)(Domain<1>(0, 1, N))    += T(3);
-    if (local_in.size(0) > 4)
-      local_in.col(ix)(Domain<1>(0, 4, N/4))  += T(-2);
-    if (local_in.size(0) > 13)
-      local_in.col(ix)(Domain<1>(0, 13, N/13)) += T(7);
-    if (local_in.size(0) > 27)
-      local_in.col(ix)(Domain<1>(0, 27, N/27)) += T(-15);
-    if (local_in.size(0) > 37)
-      local_in.col(ix)(Domain<1>(0, 37, N/37)) += T(31);
-  }
+  in.col(0)    = T();
 
-  if (block.subblock() == block.map().impl_subblock_from_index(1,3))
-  {
-    unsigned ix = block.map().impl_local_from_global_index(1,3);
-    local_in.col(ix)    = T(scale);
-  }
+  in.col(1)    = T();
+  in.col(1)(0) = T(scale);
 
-  if (block.subblock() == block.map().impl_subblock_from_index(1,4))
-  {
-    unsigned ix = block.map().impl_local_from_global_index(1,4);
-    for (unsigned i = 0; i < N; ++i)
-      local_in.col(ix)(i)    = T(std::sin(3.1415926535898*i*4/N));
-  }
-  
-#endif
+  in.col(2)    = T();
+  in.col(2)(0) = T(1);
+  in.col(2)(Domain<1>(0, 1, N))    += T(3);
+  if (in.size(0) > 4)  in.col(2)(Domain<1>(0, 4, N/4))  += T(-2);
+  if (in.size(0) > 13) in.col(2)(Domain<1>(0, 13, N/13)) += T(7);
+  if (in.size(0) > 27) in.col(2)(Domain<1>(0, 27, N/27)) += T(-15);
+  if (in.size(0) > 37) in.col(2)(Domain<1>(0, 37, N/37)) += T(31);
 
-#if 0
-  impl::Communicator comm = impl::default_communicator();
-  if (comm.rank() == 0)
-  {
-    local_in.col(0)    = T();
-
-    local_in.col(1)    = T();
-    local_in.col(1)(0) = T(scale);
-
-    local_in.col(2)    = T();
-    local_in.col(2)(0) = T(1);
-    local_in.col(2)(Domain<1>(0, 1, N))    += T(3);
-    local_in.col(2)(Domain<1>(0, 4, N/4))  += T(-2);
-    if (in.size(0) > 16)
-      local_in.col(2)(Domain<1>(0, 13, N/13)) += T(7);
-    if (in.size(0) > 27)
-      local_in.col(2)(Domain<1>(0, 27, N/27)) += T(-15);
-    if (in.size(0) > 37)
-      local_in.col(2)(Domain<1>(0, 37, N/37)) += T(31);
+  in.col(3)    = T(scale);
 
-    local_in.col(3)    = T(scale);
-
-    for (unsigned i = 0; i < N; ++i)
-      local_in.col(4)(i)    = T(std::sin(3.1415926535898*i*4/N));
-
-    inp = in;
-  }
-  comm.barrier();
-#endif
+  for (unsigned i = 0; i < N; ++i)
+    in.col(4)(i)    = T(std::sin(3.1415926535898*i*4/N));
 }
 
 
@@ -592,23 +491,11 @@
   
   vsipl init(argc, argv);
 
-  impl::Communicator comm = impl::default_communicator();
-  ::number_of_processors = comm.size();
+  ::number_of_processors = vsip::num_processors();
 
-#if 0
-  // Enable this section for easier debugging.
-  pid_t pid = getpid();
-
-  cout << "rank: "   << comm.rank()
-       << "  size: " << comm.size()
-       << "  pid: "  << pid
-       << endl;
-
-  // Stop each process, allow debugger to be attached.
-  char c;
-  if (comm.rank() == 0) read(0,&c,1);
-  comm.barrier();
-#endif
+  // include debug.hpp to use this function.  It waits for input
+  // to allow a debugger to be attached.
+  // debug_stub();
 
 #if defined(VSIP_IMPL_FFT_USE_FLOAT)
   test<float>();
Index: tests/parallel/replicated_data.cpp
===================================================================
RCS file: tests/parallel/replicated_data.cpp
diff -N tests/parallel/replicated_data.cpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ tests/parallel/replicated_data.cpp	24 Mar 2006 18:55:40 -0000
@@ -0,0 +1,338 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/parallel/replicated_data.cpp
+    @author  Jules Bergmann
+    @date    2006-03-10
+    @brief   VSIPL++ Library: Unit tests for using Replicated_map.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#define VERBOSE 0
+
+#if VERBOSE
+#  include <iostream>
+#endif
+#include <algorithm>
+
+#include <vsip/support.hpp>
+#include <vsip/map.hpp>
+#include <vsip/initfin.hpp>
+
+#include "test.hpp"
+#include "output.hpp"
+#include "debug.hpp"
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
+void msg(char* text)
+{
+  impl::default_communicator().barrier();
+  if (local_processor() == 0)
+    std::cout << text << std::endl;
+  impl::default_communicator().barrier();
+}
+
+
+
+// Test comm using replicated view as source (to non-replicated view)
+
+template <typename T>
+void
+test_src(int modulo)
+{
+  // rep_view will be replicated over a subset of processors.
+  // dst_view will dim 0 distributed so that each processor has a row.
+ 
+  length_type np = num_processors();
+
+  Vector<processor_type> full_pset = processor_set();
+  Vector<processor_type> pset(1+(np-1)/modulo);
+
+  for (index_type i=0; i<np; i+=modulo)
+    pset(i/modulo) = full_pset(i);
+
+  length_type size = 16;
+  length_type rows = np;
+
+  Replicated_map<1> rep_map(pset);
+  Map<>             dst_map(np, 1);
+
+  typedef Dense<1, T, row1_type, Replicated_map<1> > rep_block_type;
+  typedef Dense<2, T, row2_type, Map<> >             dst_block_type;
+
+  typedef Vector<T, rep_block_type> rep_view_type;
+  typedef Matrix<T, dst_block_type> dst_view_type;
+
+  rep_view_type rep_view(size, rep_map);
+  dst_view_type dst_view(rows, size, dst_map);
+
+  for (index_type i=0; i<size; ++i)
+    rep_view.put(i, T(i));
+
+  if (rep_map.subblock() != no_subblock)
+  {
+    rep_view.local().put(0, T(local_processor()));
+  }
+
+  for (index_type r=0; r<rows; ++r)
+    dst_view.row(r) = rep_view;
+
+  // Check the results
+  typename dst_view_type::local_type l_dst_view = dst_view.local();
+  test_assert(l_dst_view.size(0) == 1);
+
+  for (index_type i=1; i<size; ++i)
+    test_assert(l_dst_view.get(0, i) == T(i));
+
+#if VERBOSE
+  std::cout << "(" << local_processor() << "): " << l_dst_view.get(0, 0)
+	    << std::endl;
+#endif
+}
+
+
+
+// Test comm using replicated view as destination (from non-replicated view)
+
+template <typename T,
+	  typename SrcMapT,
+	  typename DstMapT>
+void
+test_msg(
+  length_type    size,
+  SrcMapT const& src_map,
+  DstMapT const& dst_map,
+  bool           mark_first_element = true)
+{
+  typedef Dense<1, T, row1_type, SrcMapT> src_block_type;
+  typedef Dense<1, T, row1_type, DstMapT> dst_block_type;
+
+  typedef Vector<T, src_block_type> src_view_type;
+  typedef Vector<T, dst_block_type> dst_view_type;
+
+  src_view_type src_view(size, src_map);
+  dst_view_type dst_view(size, dst_map);
+
+  for (index_type i=0; i<size; ++i)
+    src_view.put(i, T(i));
+
+  if (mark_first_element && src_map.subblock() != no_subblock)
+  {
+    src_view.local().put(0, T(local_processor()));
+  }
+
+  dst_view = src_view;
+
+  // Check the results
+  if (dst_map.subblock() != no_subblock)
+  {
+    typename dst_view_type::local_type l_dst_view = dst_view.local();
+
+    for (index_type li=1; li<l_dst_view.size(); ++li)
+    {
+      index_type gi = global_from_local_index(dst_view, 0, li);
+      test_assert(l_dst_view.get(li) == T(gi));
+    }
+
+#if VERBOSE
+    std::cout << "(" << local_processor() << "): " << l_dst_view.get(0)
+	      << std::endl;
+#endif
+  }
+}
+
+
+
+template <typename T>
+void
+test_global_to_repl(int modulo)
+{
+  length_type np = num_processors();
+
+  Vector<processor_type> full_pset = processor_set();
+  Vector<processor_type> pset(1+(np-1)/modulo);
+
+  for (index_type i=0; i<np; i+=modulo)
+    pset(i/modulo) = full_pset(i);
+
+  length_type size = 16;
+
+  Global_map<1>     src_map;
+  Replicated_map<1> dst_map(pset);
+
+  test_msg<T>(size, src_map, dst_map);
+}
+
+
+
+template <typename T>
+void
+test_repl_to_global(int modulo)
+{
+  length_type np = num_processors();
+
+  Vector<processor_type> full_pset = processor_set();
+  Vector<processor_type> pset(1+(np-1)/modulo);
+
+  for (index_type i=0; i<np; i+=modulo)
+    pset(i/modulo) = full_pset(i);
+
+  length_type size = 16;
+
+  Replicated_map<1> src_map(pset);
+  Global_map<1>     dst_map;
+
+  test_msg<T>(size, src_map, dst_map);
+}
+
+
+
+template <typename T>
+void
+test_repl_to_repl(int src_modulo, int dst_modulo)
+{
+  length_type np = num_processors();
+
+  Vector<processor_type> full_pset = processor_set();
+  Vector<processor_type> src_pset(1+(np-1)/src_modulo);
+  Vector<processor_type> dst_pset(1+(np-1)/dst_modulo);
+
+  for (index_type i=0; i<np; i+=src_modulo)
+    src_pset(i/src_modulo) = full_pset(i);
+
+  for (index_type i=0; i<np; i+=dst_modulo)
+    dst_pset(i/dst_modulo) = full_pset(i);
+
+  length_type size = 16;
+
+  Replicated_map<1> src_map(src_pset);
+  Replicated_map<1> dst_map(dst_pset);
+
+  test_msg<T>(size, src_map, dst_map);
+}
+
+
+
+template <typename T>
+void
+test_even_odd()
+{
+  length_type np = num_processors();
+
+  Vector<processor_type> full_pset = processor_set();
+  Vector<processor_type> src_pset(std::max<length_type>(np/2 + np%2, 1));
+  Vector<processor_type> dst_pset(std::max<length_type>(np/2, 1));
+
+  for (index_type i=0; i<np; ++i)
+    if (i%2 == 0)
+      src_pset(i/2) = full_pset(i);
+    else
+      dst_pset(i/2) = full_pset(i);
+
+  if (np == 1)
+    dst_pset(0) = full_pset(0);
+
+  length_type size = 16;
+
+  Replicated_map<1> src_map(src_pset);
+  Replicated_map<1> dst_map(dst_pset);
+
+  test_msg<T>(size, src_map, dst_map);
+}
+
+
+
+template <typename T>
+void
+test_block_to_repl(int modulo)
+{
+  length_type np = num_processors();
+
+  Vector<processor_type> full_pset = processor_set();
+  Vector<processor_type> pset(1+(np-1)/modulo);
+
+  for (index_type i=0; i<np; i+=modulo)
+    pset(i/modulo) = full_pset(i);
+
+  length_type size = 16;
+
+  Map<>             src_map(np);
+  Replicated_map<1> dst_map(pset);
+
+  test_msg<T>(size, src_map, dst_map, false);
+}
+
+
+
+template <typename T>
+void
+test_repl_to_block(int modulo)
+{
+  length_type np = num_processors();
+
+  Vector<processor_type> full_pset = processor_set();
+  Vector<processor_type> pset(1+(np-1)/modulo);
+
+  for (index_type i=0; i<np; i+=modulo)
+    pset(i/modulo) = full_pset(i);
+
+  length_type size = 16;
+
+  Replicated_map<1> src_map(pset);
+  Map<>             dst_map(np);
+
+  test_msg<T>(size, src_map, dst_map, false);
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl vpp(argc, argv);
+
+  // debug_stub();
+
+  test_src<float>(1);
+  test_src<float>(2);
+  test_src<float>(4);
+
+  test_global_to_repl<float>(1);
+  test_global_to_repl<float>(2);
+  test_global_to_repl<float>(4);
+
+  test_repl_to_global<float>(1);
+  test_repl_to_global<float>(2);
+  test_repl_to_global<float>(4);
+
+  test_repl_to_repl<float>(1, 1);
+  test_repl_to_repl<float>(1, 2);
+  test_repl_to_repl<float>(1, 4);
+
+  test_repl_to_repl<float>(2, 1);
+  test_repl_to_repl<float>(4, 1);
+
+  test_repl_to_repl<float>(2, 2);
+  test_repl_to_repl<float>(4, 2);
+  test_repl_to_repl<float>(2, 4);
+
+  test_even_odd<float>();
+
+  test_block_to_repl<float>(1);
+  test_block_to_repl<float>(2);
+  test_block_to_repl<float>(4);
+
+  test_repl_to_block<float>(1);
+  test_repl_to_block<float>(2);
+  test_repl_to_block<float>(4);
+}
Index: tests/parallel/subviews.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/parallel/subviews.cpp,v
retrieving revision 1.1
diff -u -r1.1 subviews.cpp
--- tests/parallel/subviews.cpp	16 Mar 2006 03:27:10 -0000	1.1
+++ tests/parallel/subviews.cpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    tests/parallel/subviews.cpp
     @author  Jules Bergmann
@@ -71,7 +71,7 @@
   root_view2_t root_view(create_view<root_view2_t>(dom, root_map));
   root_view1_t root_sum (sum_size, T(), root_map);
 
-  if (root_map.impl_rank() == 0)
+  if (root_map.subblock() != no_subblock)
   {
     typename root_view2_t::local_type local_view = root_view.local();
     typename root_view1_t::local_type local_sum  = root_sum.local();
@@ -143,6 +143,8 @@
   test_row_sum<float>(dom, Map<>(Block_dist(np), Block_dist(1)));
   test_row_sum<float>(dom, Map<>(Block_dist(1),  Block_dist(np)));
   test_row_sum<float>(dom, Map<>(Block_dist(nr), Block_dist(nc)));
+
+  test_row_sum<float>(dom, Global_map<2>());
 }
 
 
@@ -182,7 +184,7 @@
   root_view2_t root_view(create_view<root_view2_t>(dom, root_map));
   root_view1_t root_sum (sum_size, T(), root_map);
 
-  if (root_map.impl_rank() == 0)
+  if (root_map.subblock() != no_subblock)
   {
     typename root_view2_t::local_type local_view = root_view.local();
     typename root_view1_t::local_type local_sum  = root_sum.local();
@@ -343,7 +345,7 @@
   root_view3_t root_view(create_view<root_view3_t>(dom, root_map));
   root_view1_t root_sum (sum_size, T(), root_map);
 
-  if (root_map.impl_rank() == 0)
+  if (root_map.subblock() != no_subblock)
   {
     typename root_view3_t::local_type local_view = root_view.local();
     typename root_view1_t::local_type local_sum  = root_sum.local();
@@ -527,7 +529,7 @@
   root_view3_t root_view(create_view<root_view3_t>(dom, root_map));
   root_view2_t root_sum (sum_rows, sum_cols, T(), root_map);
 
-  if (root_map.impl_rank() == 0)
+  if (root_map.subblock() != no_subblock)
   {
     typename root_view3_t::local_type local_view = root_view.local();
     typename root_view2_t::local_type local_sum  = root_sum.local();
Index: tests/parallel/user-storage.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/parallel/user-storage.cpp,v
retrieving revision 1.1
diff -u -r1.1 user-storage.cpp
--- tests/parallel/user-storage.cpp	16 Mar 2006 03:27:10 -0000	1.1
+++ tests/parallel/user-storage.cpp	24 Mar 2006 18:55:40 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    tests/parallel/user-storage.cpp
     @author  Jules Bergmann
@@ -118,7 +118,7 @@
       root = dist;
 
     // On the root processor ...
-    if (root_map.impl_rank() == 0)
+    if (root_map.subblock() != no_subblock)
     {
       typename root_view_t::local_type l_root = root.local();
 
Index: tests/regressions/localview_of_slice.cpp
===================================================================
RCS file: tests/regressions/localview_of_slice.cpp
diff -N tests/regressions/localview_of_slice.cpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ tests/regressions/localview_of_slice.cpp	24 Mar 2006 18:55:40 -0000
@@ -0,0 +1,167 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/regressions/localview_of_slice.cpp
+    @author  Jules Bergmann
+    @date    2006-03-24
+    @brief   VSIPL++ Library: Regression tests for local view of
+             distributed sliced view.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#define VERBOSE 0
+
+#if VERBOSE
+#  include <iostream>
+#endif
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/map.hpp>
+
+#include "test.hpp"
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
+// Test that local view of a distributed matrix are empty on
+// processors with no local subblock.
+//
+// 060324:
+//  - Works correctly, test included for comparison.
+
+void
+test_localview()
+{
+  typedef float                            T;
+  typedef Map<>                            map_type;
+  typedef Dense<2, T, row2_type, map_type> block_type;
+
+  length_type np   = num_processors();
+  length_type rows = (np > 1) ? (np - 1) : 1;
+  length_type cols = 8;
+
+  map_type map(rows, 1);
+  Matrix<T, block_type> view(rows, cols, T(), map);
+
+
+  // If the local processor has a subblock, it should have exactly one row.
+  // Otherwise, it should have no rows.
+
+  length_type local_rows = (subblock(view) != no_subblock) ? 1 : 0;
+
+  test_assert(view.local().size(0) == local_rows);
+
+#if VERBOSE
+  cout << local_processor() << ": "
+       << "size: " << view.local().size(0) << "  "
+       << "lrows: " << local_rows << "  ";
+  if (subblock(view) == no_subblock)
+    cout << "sb: no_subblock";
+  else
+    cout << "sb: " << subblock(view);
+  cout << endl;
+#endif
+}
+
+
+
+// Test that local view of a slice of a distributed matrix are empty on
+// processors with no local subblock.
+// 
+// 060324
+//  - This test requires num_processors() > 1 to trigger error condition.
+//  - Error condition fixed.
+
+void
+test_localview_of_slice()
+{
+  typedef float                            T;
+  typedef Map<>                            map_type;
+  typedef Dense<2, T, row2_type, map_type> block_type;
+
+  length_type np   = num_processors();
+  length_type rows = np + 1;
+  length_type cols = 8;
+
+  map_type map(np, 1);
+  Matrix<T, block_type> view(rows, cols, T(), map);
+
+  for (index_type r = 0; r < rows; ++r)
+  {
+    length_type is_local = (subblock(view.row(r)) != no_subblock) ? 1 : 0;
+
+#if VERBOSE
+    cout << local_processor() << ": "
+	 << view.row(r).local().size() << ", "
+	 << is_local
+	 << endl;
+#endif
+
+    test_assert(view.row(r).local().size() == is_local * cols);
+  }
+}
+
+
+
+// Test that local view of a subset of a distributed matrix are empty on
+// processors with no local subblock.
+// 
+// 060324
+//  - This test does not trigger an error condition, since subviews 
+//    are not currently allowed to break up distributed dimensions.
+//    Attempting to run this test will throw 'unimplemented'.
+
+void
+test_localview_of_subset()
+{
+  typedef float                            T;
+  typedef Map<>                            map_type;
+  typedef Dense<2, T, row2_type, map_type> block_type;
+
+  length_type np   = num_processors();
+  length_type rows = np + 1;
+  length_type cols = 8;
+
+  map_type map(np, 1);
+  Matrix<T, block_type> view(rows, cols, T(), map);
+
+  for (index_type r = 0; r < rows; ++r)
+  {
+    Domain<2> dom(Domain<1>(r, 1, 1),
+		  Domain<1>(cols));
+    length_type is_local = (subblock(view(dom)) != no_subblock) ? 1 : 0;
+
+#if VERBOSE
+    cout << local_processor() << ": "
+	 << view(dom).local().size() << ", "
+	 << is_local
+	 << endl;
+#endif
+
+    test_assert(view(dom).local().size() == is_local * cols);
+  }
+}
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_localview();
+  test_localview_of_slice();
+
+  // See function comment.
+  // test_localview_of_subset();
+}
