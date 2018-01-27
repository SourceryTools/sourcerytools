Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.502
diff -u -r1.502 ChangeLog
--- ChangeLog	9 Jun 2006 21:30:57 -0000	1.502
+++ ChangeLog	13 Jun 2006 03:20:19 -0000
@@ -1,3 +1,11 @@
+2006-06-12  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/domain-utils.hpp (next): Add dimension-order template
+	  parameter.  Add overload so that existing users of next() continue
+	  to work.
+	* tests/index_traversal.cpp: New file, tests for next() with
+	  different dimension orders.
+
 2006-06-09  Jules Bergmann  <jules@codesourcery.com>
 
 	* benchmarks/hpec_kernel/cfar.cpp: Fix cfar_verify to work in
Index: src/vsip/impl/domain-utils.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/domain-utils.hpp,v
retrieving revision 1.10
diff -u -r1.10 domain-utils.hpp
--- src/vsip/impl/domain-utils.hpp	3 Jun 2006 00:24:52 -0000	1.10
+++ src/vsip/impl/domain-utils.hpp	13 Jun 2006 03:20:19 -0000
@@ -15,6 +15,8 @@
 ***********************************************************************/
 
 #include <vsip/domain.hpp>
+#include <vsip/impl/length.hpp>
+#include <vsip/impl/static_assert.hpp>
 
 
 
@@ -421,57 +423,81 @@
 		   Domain<1>(first[2], 1, size[2]));
 }
 
-/* Now let's make the "next" functions that work Index. This function is the
- * same as the Point one but it operates on an Index
- */
+
+
+/// Return the next Index from 'idx' using OrderT to determine the
+/// dimension-ordering of the traversal.
+
+template <typename OrderT>
 inline
 Index<1>&
 next(
   Length<1> const& /*extent*/,
   Index<1>&        idx)
 {
-  ++idx[0];
+  VSIP_IMPL_STATIC_ASSERT(OrderT::impl_dim0 == 0);
+  ++idx[OrderT::impl_dim0];
   return idx;
 }
 
 
 
+template <typename OrderT>
 inline
 Index<2>&
 next(
   Length<2> const& extent,
   Index<2>&        idx)
 {
-  if (++idx[0] == extent[0])
+  VSIP_IMPL_STATIC_ASSERT(OrderT::impl_dim0 < 2);
+  VSIP_IMPL_STATIC_ASSERT(OrderT::impl_dim1 < 2);
+  if (++idx[OrderT::impl_dim1] == extent[OrderT::impl_dim1])
   {
-    if (++idx[1] != extent[1])
-      idx[0] = 0;
+    if (++idx[OrderT::impl_dim0] != extent[OrderT::impl_dim0])
+      idx[OrderT::impl_dim1] = 0;
   }
   return idx;
 }
 
 
 
+template <typename OrderT>
 inline
 Index<3>&
 next(
   Length<3> const& extent,
   Index<3>&        idx)
 {
-  if (++idx[0] == extent[0])
+  if (++idx[OrderT::impl_dim2] == extent[OrderT::impl_dim2])
   {
-    if (++idx[1] == extent[1])
+    if (++idx[OrderT::impl_dim1] == extent[OrderT::impl_dim1])
     {
-      if (++idx[2] == extent[2])
+      if (++idx[OrderT::impl_dim0] == extent[OrderT::impl_dim0])
 	return idx;
-      idx[1] = 0;
+      idx[OrderT::impl_dim1] = 0;
     }
-    idx[0] = 0;
+    idx[OrderT::impl_dim2] = 0;
   }
 
   return idx;
 }
 
+
+
+/// Overload of next that performs row-major traversal.
+
+template <dimension_type Dim>
+inline
+Index<Dim>&
+next(
+  Length<Dim> const& extent,
+  Index<Dim>&        idx)
+{
+  return next<typename Row_major<Dim>::type>(extent, idx);
+}
+
+
+
 // This function checks if the index is valid given a certain length. This
 // function works for multiple dimension spaces.
 template <dimension_type D>
Index: tests/index_traversal.cpp
===================================================================
RCS file: tests/index_traversal.cpp
diff -N tests/index_traversal.cpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ tests/index_traversal.cpp	13 Jun 2006 03:20:19 -0000
@@ -0,0 +1,123 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/index_traversal.cpp
+    @author  Jules Bergmann
+    @date    2006-06-12
+    @brief   VSIPL++ Library: Unit tests for index traversal.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/impl/domain-utils.hpp>
+#include <vsip/impl/static_assert.hpp>
+
+#include "test.hpp"
+
+using namespace std;
+using namespace vsip;
+
+using vsip::impl::Length;
+using vsip::impl::extent;
+using vsip::impl::valid;
+using vsip::impl::next;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+/// Convert a multi-dimensional index into a linear index, using
+/// a specific dimension-order.
+
+template <typename OrderT>
+index_type
+linear_index(Length<1> const& /*ext*/, Index<1> const& idx)
+{
+  VSIP_IMPL_STATIC_ASSERT(OrderT::impl_dim0 == 0);
+  return idx[OrderT::impl_dim0];
+}
+
+template <typename OrderT>
+index_type
+linear_index(Length<2> const& ext, Index<2> const& idx)
+{
+  VSIP_IMPL_STATIC_ASSERT(OrderT::impl_dim0 < 2);
+  VSIP_IMPL_STATIC_ASSERT(OrderT::impl_dim1 < 2);
+
+  return (idx[OrderT::impl_dim1] + ext[OrderT::impl_dim1]*
+          idx[OrderT::impl_dim0]);
+}
+
+template <typename OrderT>
+index_type
+linear_index(Length<3> const& ext, Index<3> const& idx)
+{
+  VSIP_IMPL_STATIC_ASSERT(OrderT::impl_dim0 < 3);
+  VSIP_IMPL_STATIC_ASSERT(OrderT::impl_dim1 < 3);
+  VSIP_IMPL_STATIC_ASSERT(OrderT::impl_dim2 < 3);
+
+  return (idx[OrderT::impl_dim2] + ext[OrderT::impl_dim2]*
+         (idx[OrderT::impl_dim1] + ext[OrderT::impl_dim1]*
+          idx[OrderT::impl_dim0]));
+}
+
+
+
+/// Test that the arbitrary next() traversal.
+
+template <typename       OrderT,
+	  dimension_type Dim>
+void
+test_traversal(Domain<Dim> const& dom)
+{
+  Length<Dim> ext = extent(dom);
+
+  index_type count = 0;
+  for (Index<Dim> idx; valid(ext, idx); next<OrderT>(ext, idx))
+  {
+    test_assert(linear_index<OrderT>(ext, idx) == count);
+    count++;
+  }
+}
+
+
+
+/// Test that the default next() traversal is row-major.
+
+template <dimension_type Dim>
+void
+test_traversal_default(Domain<Dim> const& dom)
+{
+  typedef typename impl::Row_major<Dim>::type order_type;
+  Length<Dim> ext = extent(dom);
+
+  index_type count = 0;
+  for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
+  {
+    test_assert(linear_index<order_type>(ext, idx) == count);
+    count++;
+  }
+}
+
+
+
+int
+main()
+{
+  test_traversal<row1_type>(Domain<1>(5));
+
+  test_traversal<row2_type>(Domain<2>(5, 7));
+  test_traversal<col2_type>(Domain<2>(5, 7));
+
+  test_traversal<row3_type>(Domain<3>(5, 7, 3));
+  test_traversal<col3_type>(Domain<3>(5, 7, 3));
+  test_traversal<tuple<2, 0, 1> >(Domain<3>(5, 7, 3));
+
+  test_traversal_default(Domain<1>(5));
+  test_traversal_default(Domain<2>(5, 7));
+  test_traversal_default(Domain<3>(5, 7, 3));
+}
