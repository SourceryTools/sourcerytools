? ChangeLog.new
? config.log
? src/vsip/impl/.point-fcn.hpp.swp
? src/vsip/impl/.point.hpp.swp
? tests/.output.hpp.swp
? tests/Makefile.in
? vendor/atlas/autom4te.cache
? vendor/atlas/configure
? vendor/atlas/CONFIG/acconfig.hpp.in
? vendor/atlas/bin/Makefile.in
? vendor/atlas/interfaces/blas/C/src/Makefile.in
? vendor/atlas/interfaces/blas/C/testing/Makefile.in
? vendor/atlas/interfaces/blas/F77/src/Makefile.in
? vendor/atlas/interfaces/blas/F77/testing/Makefile.in
? vendor/atlas/interfaces/lapack/C/src/Makefile.in
? vendor/atlas/interfaces/lapack/F77/src/Makefile.in
? vendor/atlas/lib/Makefile.in
? vendor/atlas/src/auxil/Makefile.in
? vendor/atlas/src/blas/gemm/Make.inc.in
? vendor/atlas/src/blas/gemm/Makefile.in
? vendor/atlas/src/blas/gemm/GOTO/Makefile.in
? vendor/atlas/src/blas/gemv/Make.inc.in
? vendor/atlas/src/blas/gemv/Makefile.in
? vendor/atlas/src/blas/ger/Make.inc.in
? vendor/atlas/src/blas/ger/Makefile.in
? vendor/atlas/src/blas/level1/Make.inc.in
? vendor/atlas/src/blas/level1/Makefile.in
? vendor/atlas/src/blas/level2/Makefile.in
? vendor/atlas/src/blas/level2/kernel/Makefile.in
? vendor/atlas/src/blas/level3/Makefile.in
? vendor/atlas/src/blas/level3/kernel/Makefile.in
? vendor/atlas/src/blas/level3/rblas/Makefile.in
? vendor/atlas/src/blas/pklevel3/Makefile.in
? vendor/atlas/src/blas/pklevel3/gpmm/Makefile.in
? vendor/atlas/src/blas/pklevel3/sprk/Makefile.in
? vendor/atlas/src/blas/reference/level1/Makefile.in
? vendor/atlas/src/blas/reference/level2/Makefile.in
? vendor/atlas/src/blas/reference/level3/Makefile.in
? vendor/atlas/src/lapack/Makefile.in
? vendor/atlas/src/pthreads/blas/level1/Makefile.in
? vendor/atlas/src/pthreads/blas/level2/Makefile.in
? vendor/atlas/src/pthreads/blas/level3/Makefile.in
? vendor/atlas/src/pthreads/misc/Makefile.in
? vendor/atlas/src/testing/Makefile.in
? vendor/atlas/tune/blas/gemm/Makefile.in
? vendor/atlas/tune/blas/gemv/Makefile.in
? vendor/atlas/tune/blas/ger/Makefile.in
? vendor/atlas/tune/blas/level1/Makefile.in
? vendor/atlas/tune/blas/level3/Makefile.in
? vendor/atlas/tune/sysinfo/Makefile.in
Index: src/vsip/impl/length.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/length.hpp,v
retrieving revision 1.3
diff -u -r1.3 length.hpp
--- src/vsip/impl/length.hpp	15 Sep 2005 14:49:25 -0000	1.3
+++ src/vsip/impl/length.hpp	30 Mar 2006 17:00:12 -0000
@@ -15,8 +15,10 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
+#include <vsip/domain.hpp>
 #include <vsip/impl/vertex.hpp>
 
+
 namespace vsip
 {
 namespace impl
@@ -47,6 +49,9 @@
   : Vertex<length_type, 3>(x, y, z) {}
 };
 
+// This function used to return a Point. Now it returns a Length. The use of
+// Point is depricated.
+
 template <dimension_type Dim,
 	  typename       B>
 inline Length<Dim>
@@ -69,7 +74,6 @@
   return size;
 }
 
-
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/impl/par-util.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-util.hpp,v
retrieving revision 1.8
diff -u -r1.8 par-util.hpp
--- src/vsip/impl/par-util.hpp	27 Mar 2006 23:19:34 -0000	1.8
+++ src/vsip/impl/par-util.hpp	30 Mar 2006 17:00:12 -0000
@@ -21,6 +21,7 @@
 #include <vsip/impl/distributed-block.hpp>
 #include <vsip/impl/point.hpp>
 #include <vsip/impl/point-fcn.hpp>
+#include <vsip/domain.hpp>
 
 
 
@@ -113,10 +114,11 @@
       Domain<dim> ldom = local_domain(view, sb, p);
       Domain<dim> gdom = global_domain(view, sb, p);
 
-      for (Point<dim> idx; valid(extent_old(ldom), idx); next(extent_old(ldom), idx))
+      Length<dim> ext = extent(ldom);
+      for (Index<dim> idx; valid(ext,idx); next(ext, idx))
       {
-	Point<dim> l_idx = domain_nth(ldom, idx);
-	Point<dim> g_idx = domain_nth(gdom, idx);
+	Index<dim> l_idx = domain_nth(ldom, idx);
+	Index<dim> g_idx = domain_nth(gdom, idx);
 
 	put(local_view, l_idx, fcn(get(local_view, l_idx), l_idx, g_idx));
       }
Index: src/vsip/impl/point-fcn.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/point-fcn.hpp,v
retrieving revision 1.3
diff -u -r1.3 point-fcn.hpp
--- src/vsip/impl/point-fcn.hpp	9 Sep 2005 11:55:00 -0000	1.3
+++ src/vsip/impl/point-fcn.hpp	30 Mar 2006 17:00:12 -0000
@@ -53,6 +53,24 @@
 }
 
 
+// This function is like domain_nth function above but returns an Index
+// instead of a point
+template <dimension_type Dim>
+Index<Dim>
+domain_nth(
+  Domain<Dim> const& dom,
+  Index<Dim> const&  idx)
+{
+  Index<Dim> res;
+
+  for (dimension_type d=0; d<Dim; ++d)
+    res[d] = dom[d].impl_nth(idx[d]);
+
+  return res;
+}
+
+
+
 
 /// Get the first index of a domain.
 
@@ -69,7 +87,8 @@
 
 
 
-/// Get the extent of a domain, as a point.
+/// Get the extent of a domain, as a point. This function is now depricated.
+/// We should use Length now instead.
 
 template <dimension_type Dim>
 Point<Dim>
@@ -84,9 +103,24 @@
   return res;
 }
 
+/// Get the extent of a domain as a Length.
 
+template <dimension_type Dim>
+Length<Dim>
+extent(
+  Domain<Dim> const& dom)
+{
+  Length<Dim> res;
 
-/// Get the extent of a vector view, as a point.
+  for (dimension_type d=0; d<Dim; ++d)
+    res[d] = dom[d].length();
+
+  return res;
+}
+
+
+/// Get the extent of a vector view, as a point. This function is depricated.
+/// We should use Length now instead.
 
 template <typename T,
 	  typename Block>
@@ -96,9 +130,21 @@
   return Point<1>(v.size(0));
 }
 
+/// Get the extent of a vector view, as a Length. 
+
+template <typename T,
+	  typename Block>
+Length<1>
+extent(const_Vector<T, Block> v)
+{
+  return Length<1>(v.size(0));
+}
+
+
 
 
-/// Get the extent of a matrix view, as a point.
+/// Get the extent of a matrix view, as a point. This function is depricated.
+/// We should use Length now instead of point.
 
 template <typename T,
 	  typename Block>
@@ -109,6 +155,16 @@
 }
 
 
+/// Get the extent of a matrix view, as a Length.
+
+template <typename T,
+	  typename Block>
+Length<2>
+extent(const_Matrix<T, Block> v)
+{
+  return Length<2>(v.size(0), v.size(1));
+}
+
 
 /// Construct a 1-dim domain with an offset and a size (implicit
 /// stride of 1)
Index: src/vsip/impl/point.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/point.hpp,v
retrieving revision 1.8
diff -u -r1.8 point.hpp
--- src/vsip/impl/point.hpp	7 Mar 2006 02:15:22 -0000	1.8
+++ src/vsip/impl/point.hpp	30 Mar 2006 17:00:12 -0000
@@ -15,6 +15,7 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
+#include <vsip/impl/length.hpp>
 
 
 /***********************************************************************
@@ -193,6 +194,58 @@
   return idx;
 }
 
+/* Now let's make the "next" functions that work Index. This function is the
+ * same as the Point one but it operates on an Index
+ */
+inline
+Index<1>&
+next(
+  Length<1> const& /*extent*/,
+  Index<1>&        idx)
+{
+  ++idx[0];
+  return idx;
+}
+
+
+
+inline
+Index<2>&
+next(
+  Length<2> const& extent,
+  Index<2>&        idx)
+{
+  if (++idx[0] == extent[0])
+  {
+    if (++idx[1] != extent[1])
+      idx[0] = 0;
+  }
+  return idx;
+}
+
+
+
+inline
+Index<3>&
+next(
+  Length<3> const& extent,
+  Index<3>&        idx)
+{
+  if (++idx[0] == extent[0])
+  {
+    if (++idx[1] == extent[1])
+    {
+      if (++idx[2] == extent[2])
+	return idx;
+      idx[1] = 0;
+    }
+    idx[0] = 0;
+  }
+
+  return idx;
+}
+
+
 
 template <dimension_type Dim>
 inline bool
@@ -206,6 +259,21 @@
   return true;
 }
 
+// This function checks if the index is valid given a certain length. This
+// function works for multiple dimension spaces.
+template <dimension_type D>
+inline bool
+valid(
+  Length<D> const& extent,
+  Index<D>  const& idx)
+{
+  for(dimension_type d=0;d<D;++d)
+    if(idx[d] >= extent[d])
+      return false;
+  return true;
+}
+
+
 
 template <dimension_type Dim>
 inline
@@ -297,7 +365,6 @@
 }
 
 
-
 /// Put a value into a 2-dim block.
 
 template <typename Block>
@@ -325,6 +392,84 @@
 }
 
 
+// These functions use an Index instead of a Point.
+// The use Point is depricated
+
+/// Get a value from a 1-dim block.
+
+template <typename Block>
+inline typename Block::value_type
+get(
+  Block const&    block,
+  Index<1> const& idx)
+{
+  return block.get(idx[0]);
+}
+
+
+
+/// Get a value from a 2-dim block.
+
+template <typename Block>
+inline typename Block::value_type
+get(
+  Block const&    block,
+  Index<2> const& idx)
+{
+  return block.get(idx[0], idx[1]);
+}
+
+
+
+/// Get a value from a 3-dim block.
+
+template <typename Block>
+inline typename Block::value_type
+get(
+  Block const&    block,
+  Index<3> const& idx)
+{
+  return block.get(idx[0], idx[1], idx[2]);
+}
+
+
+
+/// Put a value into a 1-dim block.
+
+template <typename Block>
+inline void
+put(
+  Block&                            block,
+  Index<1> const&                   idx,
+  typename Block::value_type const& val)
+{
+  block.put(idx[0], val);
+}
+
+
+/// Put a value into a 2-dim block.
+
+template <typename Block>
+inline void
+put(
+  Block&                            block,
+  Index<2> const&                   idx,
+  typename Block::value_type const& val)
+{
+  block.put(idx[0], idx[1], val);
+}
+
+
+template <typename Block>
+inline void
+put(
+  Block&                            block,
+  Index<3> const&                   idx,
+  typename Block::value_type const& val)
+{
+  block.put(idx[0], idx[1], idx[2], val);
+}
+
 
 
 
Index: tests/appmap.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/appmap.cpp,v
retrieving revision 1.10
diff -u -r1.10 appmap.cpp
--- tests/appmap.cpp	27 Mar 2006 23:19:34 -0000	1.10
+++ tests/appmap.cpp	30 Mar 2006 17:00:12 -0000
@@ -13,14 +13,15 @@
 #include <vsip/support.hpp>
 #include <vsip/map.hpp>
 #include <vsip/matrix.hpp>
+#include <vsip/impl/length.hpp>
 #include "test.hpp"
 #include "output.hpp"
 
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
-using vsip::impl::extent_old;
+using vsip::impl::Length;
+using vsip::impl::extent;
 using vsip::impl::valid;
 using vsip::impl::next;
 using vsip::impl::domain_nth;
@@ -95,12 +96,6 @@
 
 
 
-inline Index<1> as_index(Point<1> const& p) {return Index<1>(p[0]); }
-inline Index<2> as_index(Point<2> const& p) {return Index<2>(p[0],p[1]); }
-inline Index<3> as_index(Point<3> const& p) {return Index<3>(p[0],p[1],p[2]); }
-
-
-
 // Check that local and global indices within a patch are consistent.
 
 template <dimension_type Dim,
@@ -147,16 +142,20 @@
     }
   }
 
-  Point<Dim> ext = extent_old(gdom);
+  /* We can replace this segment of code with one that uses Length and Index.
+   * The use of Point is depricated and Length and Index should be used
+   * Instead
+   */
 
-  for (Point<Dim> idx; valid(ext, idx); next(ext, idx))
+  Length<Dim> ext = extent(gdom);
+  for(Index<Dim> idx; valid(ext,idx); next(ext,idx))
   {
-    Index<Dim> g_idx = as_index(domain_nth(gdom, idx));
-    Index<Dim> l_idx = as_index(domain_nth(ldom, idx));
-
+    Index<Dim> g_idx = domain_nth(gdom,idx);
+    Index<Dim> l_idx = domain_nth(ldom,idx);
     test_assert(map.impl_subblock_from_global_index(g_idx) == sb);
     test_assert(map.impl_patch_from_global_index(g_idx)    == p);
   }
+
 }
 
 
Index: tests/fast-block.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fast-block.cpp,v
retrieving revision 1.6
diff -u -r1.6 fast-block.cpp
--- tests/fast-block.cpp	20 Dec 2005 12:48:40 -0000	1.6
+++ tests/fast-block.cpp	30 Mar 2006 17:00:12 -0000
@@ -16,13 +16,16 @@
 #include <vsip/impl/point.hpp>
 #include <vsip/impl/point-fcn.hpp>
 #include <vsip/impl/fast-block.hpp>
+#include <vsip/impl/length.hpp>
 #include "test.hpp"
 
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
-using vsip::impl::extent_old;
+using vsip::impl::Length;
+using vsip::impl::extent;
+using vsip::impl::valid;
+using vsip::impl::next;
 
 
 
@@ -30,33 +33,35 @@
   Definitions
 ***********************************************************************/
 
+/* We no longer use Point. Instead we will use Index and Length. We need a
+ * different set of functions that operate on Index and Length instead of
+ * Point.
+ */
+
 template <typename T>
 inline T
 identity(
-  Point<1> /*extent*/,
-  Point<1> idx,
+  Length<1> /*extent*/,
+  Index<1> idx,
   int      k)
 {
   return static_cast<T>(k*idx[0] + 1);
 }
 
 
-
 template <typename T>
 inline T
 identity(
-  Point<2> extent,
-  Point<2> idx,
-  int      k)
+  Length<2> extent,
+  Index<2>  idx,
+  int       k)
 {
-  Point<2> offset;
+  Index<2> offset;
   index_type i = (idx[0]+offset[0])*extent[1] + (idx[1]+offset[1]);
   return static_cast<T>(k*i+1);
 }
 
 
-
-
 template <dimension_type Dim,
 	  typename       Block>
 void
@@ -64,15 +69,14 @@
 {
   typedef typename Block::value_type value_type;
 
-  Point<Dim> ex = extent_old<Dim>(blk);
-  for (Point<Dim> idx; idx != ex; next(ex, idx))
+  Length<Dim> ex = extent<Dim>(blk);
+  for (Index<Dim> idx; valid(ex,idx); next(ex, idx))
   {
     put(blk, idx, identity<value_type>(ex, idx, k));
   }
 }
 
 
-
 template <dimension_type Dim,
 	  typename       Block>
 void
@@ -80,8 +84,8 @@
 {
   typedef typename Block::value_type value_type;
 
-  Point<Dim> ex = extent_old<Dim>(blk);
-  for (Point<Dim> idx; idx != ex; next(ex, idx))
+  Length<Dim> ex = extent<Dim>(blk);
+  for (Index<Dim> idx; valid(ex,idx); next(ex, idx))
   {
     test_assert(equal( get(blk, idx),
 		  identity<value_type>(ex, idx, k)));
@@ -89,7 +93,6 @@
 }
 
 
-
 template <dimension_type Dim,
 	  typename       Block>
 void
Index: tests/us-block.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/us-block.cpp,v
retrieving revision 1.1
diff -u -r1.1 us-block.cpp
--- tests/us-block.cpp	10 Feb 2006 22:24:02 -0000	1.1
+++ tests/us-block.cpp	30 Mar 2006 17:00:12 -0000
@@ -16,14 +16,15 @@
 #include <vsip/impl/point.hpp>
 #include <vsip/impl/point-fcn.hpp>
 #include <vsip/impl/us-block.hpp>
+#include <vsip/impl/length.hpp>
 
 #include "test.hpp"
 
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
-using vsip::impl::extent_old;
+using vsip::impl::Length;
+using vsip::impl::extent;
 
 
 
@@ -31,32 +32,35 @@
   Definitions
 ***********************************************************************/
 
+/* We no longer use Point. Instead we will use Index and Length. We need a
+ * different set of functions that operate on Index and Length instead of
+ * Point.
+ */
+
 template <typename T>
 inline T
 identity(
-  Point<1> /*extent*/,
-  Point<1> idx,
+  Length<1> /*extent*/,
+  Index<1> idx,
   int      k)
 {
   return static_cast<T>(k*idx[0] + 1);
 }
 
 
-
 template <typename T>
 inline T
 identity(
-  Point<2> extent,
-  Point<2> idx,
-  int      k)
+  Length<2> extent,
+  Index<2>  idx,
+  int       k)
 {
-  Point<2> offset;
+  Index<2> offset;
   index_type i = (idx[0]+offset[0])*extent[1] + (idx[1]+offset[1]);
   return static_cast<T>(k*i+1);
 }
 
 
-
 template <dimension_type Dim,
 	  typename       Block>
 void
@@ -64,15 +68,14 @@
 {
   typedef typename Block::value_type value_type;
 
-  Point<Dim> ex = extent_old<Dim>(blk);
-  for (Point<Dim> idx; idx != ex; next(ex, idx))
+  Length<Dim> ex = extent<Dim>(blk);
+  for (Index<Dim> idx; valid(ex,idx); next(ex, idx))
   {
     put(blk, idx, identity<value_type>(ex, idx, k));
   }
 }
 
 
-
 template <dimension_type Dim,
 	  typename       Block>
 void
@@ -80,16 +83,17 @@
 {
   typedef typename Block::value_type value_type;
 
-  Point<Dim> ex = extent_old<Dim>(blk);
-  for (Point<Dim> idx; idx != ex; next(ex, idx))
+  Length<Dim> ex = extent<Dim>(blk);
+  for (Index<Dim> idx; valid(ex,idx); next(ex, idx))
   {
     test_assert(equal( get(blk, idx),
-		       identity<value_type>(ex, idx, k)));
+		  identity<value_type>(ex, idx, k)));
   }
 }
 
 
 
+
 template <dimension_type Dim,
 	  typename       BlockT>
 void
Index: tests/user_storage.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/user_storage.cpp,v
retrieving revision 1.6
diff -u -r1.6 user_storage.cpp
--- tests/user_storage.cpp	20 Dec 2005 12:48:41 -0000	1.6
+++ tests/user_storage.cpp	30 Mar 2006 17:00:12 -0000
@@ -17,24 +17,24 @@
 #include <vsip/impl/point.hpp>
 #include <vsip/impl/point-fcn.hpp>
 #include <vsip/impl/domain-utils.hpp>
+#include <vsip/impl/length.hpp>
 #include "test.hpp"
 
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
+using vsip::impl::Length;
 
 
 
 /***********************************************************************
   Definitions
 ***********************************************************************/
-
 template <typename       Order,
 	  dimension_type Dim>
 index_type
-to_index(Point<Dim> const& ext,
-	 Point<Dim> const& idx)
+to_index(Length<Dim> const& ext,
+	 Index<Dim>  const& idx)
 {
   if (Dim == 1)
     return idx[0];
@@ -47,7 +47,6 @@
 }
 	  
 
-
 template <typename       Order,
 	  typename       T,
 	  dimension_type Dim,
@@ -58,8 +57,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     data[i] = fun(i);
@@ -67,7 +66,6 @@
 }
 
 
-
 template <typename       Order,
 	  typename       T,
 	  dimension_type Dim,
@@ -78,8 +76,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     if (!equal(data[i], fun(i)))
@@ -89,7 +87,6 @@
 }
 
 
-
 template <typename       Order,
 	  typename       T,
 	  dimension_type Dim,
@@ -100,8 +97,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     complex<T> val = fun(i);
@@ -111,7 +108,6 @@
 }
 
 
-
 template <typename       Order,
 	  typename       T,
 	  dimension_type Dim,
@@ -122,8 +118,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     complex<T> val = fun(i);
@@ -135,7 +131,6 @@
 }
 
 
-
 template <typename       Order,
 	  typename       T,
 	  dimension_type Dim,
@@ -147,8 +142,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     complex<T> val = fun(i);
@@ -158,7 +153,6 @@
 }
 
 
-
 template <typename       Order,
 	  typename       T,
 	  dimension_type Dim,
@@ -170,8 +164,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     complex<T> val = fun(i);
@@ -182,8 +176,6 @@
   return true;
 }
 
-
-
 template <typename       Order,
 	  typename       Block,
 	  dimension_type Dim,
@@ -194,16 +186,14 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     put(block, idx, fun(i));
   }
 }
 
-
-
 template <typename       Order,
 	  typename       Block,
 	  dimension_type Dim,
@@ -214,8 +204,8 @@
   Domain<Dim> const& dom,
   Func               fun)
 {
-  Point<Dim> ext = impl::extent_old(dom);
-  for (Point<Dim> idx; idx != ext; next(ext, idx))
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
   {
     index_type i = to_index<Order>(ext, idx);
     if (!equal(get(block, idx), fun(i)))
@@ -224,7 +214,6 @@
   return true;
 }
 
-
 template <typename T>
 class Filler
 {
Index: tests/util-par.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/util-par.hpp,v
retrieving revision 1.8
diff -u -r1.8 util-par.hpp
--- tests/util-par.hpp	27 Mar 2006 23:19:34 -0000	1.8
+++ tests/util-par.hpp	30 Mar 2006 17:00:12 -0000
@@ -20,6 +20,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/parallel.hpp>
+#include <vsip/domain.hpp>
 
 #include "output.hpp"
 #include "extdata-output.hpp"
@@ -276,8 +277,8 @@
   Increment(T delta) : delta_(delta) {}
 
   T operator()(T value,
-	       vsip::impl::Point<Dim> const&,
-	       vsip::impl::Point<Dim> const&)
+	       vsip::Index<Dim> const&,
+	       vsip::Index<Dim> const&)
     { return value + delta_; }
 
   // Member Data
@@ -294,19 +295,22 @@
 class Set_identity
 {
 public:
+  // The Set_identity () operators used to take Point as their argument. The
+  // use of Point is depricated. We need to use Index instead.
+
   Set_identity(vsip::Domain<Dim> const& dom, int k = 1, int o = 0)
     : dom_(dom), k_(k), o_(o) {}
 
   template <typename T>
   T operator()(T /*value*/,
-	       vsip::impl::Point<1> const& /*local*/,
-	       vsip::impl::Point<1> const& global)
+	       vsip::Index<1> const& /*local*/,
+	       vsip::Index<1> const& global)
     { return T(k_*global[0] + o_); }
 
   template <typename T>
   T operator()(T /*value*/,
-	       vsip::impl::Point<2> const& /*local*/,
-	       vsip::impl::Point<2> const& global)
+	       vsip::Index<2> const& /*local*/,
+	       vsip::Index<2> const& global)
   {
     vsip::index_type i = global[0]*dom_[1].length()+global[1];
     return T(k_*i+o_);
@@ -314,8 +318,8 @@
 
   template <typename T>
   T operator()(T /*value*/,
-	       vsip::impl::Point<3> const& /*local*/,
-	       vsip::impl::Point<3> const& global)
+	       vsip::Index<3> const& /*local*/,
+	       vsip::Index<3> const& global)
   {
     vsip::index_type i = global[0]*dom_[1].length()*dom_[2].length()
                        + global[1]*dom_[2].length()
@@ -343,10 +347,14 @@
 
   bool good() { return good_; }
 
+  // The Check_identity () operators used to take Point as their argument. The
+  // use of Point is depricated. We need to use Index instead.
+
+
   template <typename T>
   T operator()(T value,
-	       vsip::impl::Point<1> const& /*local*/,
-	       vsip::impl::Point<1> const& global)
+	       vsip::Index<1> const& /*local*/,
+	       vsip::Index<1> const& global)
   {
     int i = global[0];
     T expected = T(k_*i + o_);
@@ -363,8 +371,8 @@
 
   template <typename T>
   T operator()(T value,
-	       vsip::impl::Point<2> const& /*local*/,
-	       vsip::impl::Point<2> const& global)
+	       vsip::Index<2> const& /*local*/,
+	       vsip::Index<2> const& global)
   {
     int i = global[0]*dom_[1].length()+global[1];
     T expected = T(k_*i+o_);
@@ -383,8 +391,8 @@
 
   template <typename T>
   T operator()(T value,
-	       vsip::impl::Point<3> const& /*local*/,
-	       vsip::impl::Point<3> const& global)
+	       vsip::Index<3> const& /*local*/,
+	       vsip::Index<3> const& global)
   {
     int i = global[0]*dom_[1].length()*dom_[2].length()
           + global[1]*dom_[2].length()
Index: tests/view.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/view.cpp,v
retrieving revision 1.10
diff -u -r1.10 view.cpp
--- tests/view.cpp	20 Dec 2005 12:48:41 -0000	1.10
+++ tests/view.cpp	30 Mar 2006 17:00:12 -0000
@@ -23,14 +23,14 @@
 #include <vsip/impl/point.hpp>
 #include <vsip/domain.hpp>
 #include <vsip/impl/point-fcn.hpp>
+#include <vsip/impl/length.hpp>
 #include "test.hpp"
 #include "test-storage.hpp"
 
 using namespace std;
 using namespace vsip;
 
-using vsip::impl::Point;
-using vsip::impl::extent_old;
+using vsip::impl::Length;
 
 
 
@@ -348,6 +348,9 @@
 
 // Check that all elements of a view have the same const values
 
+// The use of Point is depricated. This function was converted to use Length
+// and index instead.
+
 template <typename View>
 bool
 check_view_const(
@@ -355,7 +358,8 @@
   typename View::value_type scalar)
 {
   dimension_type const dim = View::dim;
-  for (Point<dim> idx; idx != extent_old(view); next(extent_old(view), idx))
+  Length<dim> ext = extent(view);
+  for (Index<dim> idx; valid(ext,idx); next(ext, idx))
   {
     if (!equal(get(view, idx), scalar))
       return false;
Index: tests/vmmul.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/vmmul.cpp,v
retrieving revision 1.4
diff -u -r1.4 vmmul.cpp
--- tests/vmmul.cpp	20 Dec 2005 12:48:41 -0000	1.4
+++ tests/vmmul.cpp	30 Mar 2006 17:00:12 -0000
@@ -19,6 +19,7 @@
 #include <vsip/map.hpp>
 #include <vsip/parallel.hpp>
 #include <vsip/math.hpp>
+#include <vsip/domain.hpp>
 
 #include "test.hpp"
 #include "util-par.hpp"
@@ -87,8 +88,8 @@
 
   template <typename T>
   T operator()(T value,
-	       vsip::impl::Point<2> const& /*local*/,
-	       vsip::impl::Point<2> const& global)
+	       vsip::Index<2> const& /*local*/,
+	       vsip::Index<2> const& global)
   {
     vsip::index_type i = global[0]*dom_[1].length()+global[1];
     T expected = (VecDim == 0) ? T(global[1] * i) : T(global[0] * i);
