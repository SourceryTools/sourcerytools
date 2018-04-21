Index: ChangeLog
===================================================================
--- ChangeLog	(revision 211954)
+++ ChangeLog	(working copy)
@@ -1,3 +1,10 @@
+2008-06-16  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/metaprogramming.hpp (is_same_ptr): New function (and
+	  helper class) to compare pointers for equality.
+	* src/vsip/opt/expr/serial_evaluator.hpp: Use is_same_ptr.
+	* tests/ip_transpose.cpp: New file, unit test for in-place transpose.
+
 2008-06-16  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* src/vsip/core/cvsip/fir.hpp: Fix for negative strides.
Index: src/vsip/core/metaprogramming.hpp
===================================================================
--- src/vsip/core/metaprogramming.hpp	(revision 211954)
+++ src/vsip/core/metaprogramming.hpp	(working copy)
@@ -153,6 +153,42 @@
 struct Non_const_of<T const>
 { typedef T type; };
 
+
+
+// Compare two pointers for equality
+
+template <typename Ptr1,
+	  typename Ptr2>
+struct Is_same_ptr
+{
+  static bool compare(Ptr1, Ptr2) { return false; }
+};
+
+template <typename PtrT>
+struct Is_same_ptr<PtrT, PtrT>
+{
+  static bool compare(PtrT ptr1, PtrT ptr2) { return ptr1 == ptr2; }
+};
+
+template <typename PtrT>
+struct Is_same_ptr<std::pair<PtrT, PtrT>, std::pair<PtrT, PtrT> >
+{
+  static bool compare(
+    std::pair<PtrT, PtrT> const& ptr1,
+    std::pair<PtrT, PtrT> const& ptr2)
+  { return ptr1.first == ptr2.first && ptr1.second == ptr2.second; }
+};
+
+template <typename Ptr1,
+	  typename Ptr2>
+inline bool
+is_same_ptr(
+  Ptr1 ptr1,
+  Ptr2 ptr2)
+{
+  return Is_same_ptr<Ptr1, Ptr2>::compare(ptr1, ptr2);
+}
+
 } // namespace impl
 } // namespace vsip
 
Index: src/vsip/opt/expr/serial_evaluator.hpp
===================================================================
--- src/vsip/opt/expr/serial_evaluator.hpp	(revision 211954)
+++ src/vsip/opt/expr/serial_evaluator.hpp	(working copy)
@@ -283,7 +283,7 @@
     vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
 
     // In-place transpose
-    if (dst_ext.data() == src_ext.data())
+    if (is_same_ptr(dst_ext.data(), src_ext.data()))
     {
       dst_value_type* d_ptr = dst_ext.data();
       // in-place transpose implies square matrix
@@ -321,7 +321,7 @@
     vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
 
     // In-place transpose
-    if (dst_ext.data() == src_ext.data())
+    if (is_same_ptr(dst_ext.data(), src_ext.data()))
     {
       dst_value_type* d_ptr = dst_ext.data();
       // in-place transpose implies square matrix
Index: tests/ip_transpose.cpp
===================================================================
--- tests/ip_transpose.cpp	(revision 0)
+++ tests/ip_transpose.cpp	(revision 0)
@@ -0,0 +1,53 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    tests/ip_transpose.cpp
+    @author  Jules Bergmann
+    @date    2008-06-16
+    @brief   VSIPL++ Library: Unit tests for in-place transpose.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Definitions - Utility Functions
+***********************************************************************/
+
+template <typename T>
+void
+ip_transpose(length_type size)
+{
+  Matrix<T> A(size, size);
+
+  for (index_type r=0; r<size; ++r)
+    for (index_type c=0; c<size; ++c)
+      A.put(r, c, T(r*size+c));
+
+  A = A.transpose();
+
+  for (index_type r=0; r<size; ++r)
+    for (index_type c=0; c<size; ++c)
+      test_assert(A.get(r, c) == T(c*size+r));
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  ip_transpose<float>(32);
+  ip_transpose<complex<float> >(32);
+}
