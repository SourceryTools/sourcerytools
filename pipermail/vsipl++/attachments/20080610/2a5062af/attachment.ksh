Index: ChangeLog
===================================================================
--- ChangeLog	(revision 211341)
+++ ChangeLog	(working copy)
@@ -1,5 +1,14 @@
 2008-06-10  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/core/block_traits.hpp (is_same_block): New function to
+	  compare block pointers.
+	* src/vsip/core/signal/freqswap.hpp: Use is_same_block to compare
+	  block pointers.
+	* tests/freqswap.cpp: Add coverage for mixed-type freqswap
+	  assignments.
+
+2008-06-10  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/core/signal/window.cpp: Use out-of-place freqswap to
 	  reduce number of copies.
 	* src/vsip/core/signal/freqswap.hpp: Store referee block type using
Index: src/vsip/core/signal/freqswap.hpp
===================================================================
--- src/vsip/core/signal/freqswap.hpp	(revision 211341)
+++ src/vsip/core/signal/freqswap.hpp	(working copy)
@@ -17,6 +17,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/core/domain_utils.hpp>
+#include <vsip/core/block_traits.hpp>
 #ifndef VSIP_IMPL_REF_IMPL
 # include <vsip/opt/expr/return_block.hpp>
 #endif
@@ -113,7 +114,7 @@
     index_type const ia = M % 2;  // adjustment to get source index
     index_type const ja = N % 2;
 
-    if (&in_ == &out)
+    if (is_same_block(in_, out))
     {
       // If in-place, use algorithm that trades O(1) temporary storage
       // for extra copies.
Index: src/vsip/core/block_traits.hpp
===================================================================
--- src/vsip/core/block_traits.hpp	(revision 211341)
+++ src/vsip/core/block_traits.hpp	(working copy)
@@ -483,6 +483,33 @@
   static bool const value = detail::Has_put<BlockT>::value;
 };
 
+
+
+// Compare two blocks for equality.
+
+template <typename Block1,
+	  typename Block2>
+struct Is_same_block
+{
+  static bool compare(Block1 const&, Block2 const&) { return false; }
+};
+
+template <typename BlockT>
+struct Is_same_block<BlockT, BlockT>
+{
+  static bool compare(BlockT const& a, BlockT const& b) { return &a == &b; }
+};
+
+template <typename Block1,
+	  typename Block2>
+bool
+is_same_block(
+  Block1 const& a,
+  Block2 const& b)
+{
+  return Is_same_block<Block1, Block2>::compare(a, b);
+}
+
 } // namespace impl
 
 } // namespace vsip
Index: tests/freqswap.cpp
===================================================================
--- tests/freqswap.cpp	(revision 211341)
+++ tests/freqswap.cpp	(working copy)
@@ -73,6 +73,26 @@
 }
 
 
+
+template <typename T1,
+	  typename T2>
+void
+test_diff_type_vector_freqswap( length_type m )
+{
+  Vector<T1> a(m);
+
+  a = ramp<T1>(0, 1, m);
+
+  Vector<T2> b(m);
+  b = vsip::freqswap(a);
+
+  for ( index_type i = 0; i < m; i++ )
+  {
+    test_assert(equal( b.get(i), (T2)a.get(((m+1)/2 + i) % m ) ));
+  }
+}
+
+
 template <typename T>
 void
 test_matrix_freqswap( length_type m, length_type n )
@@ -99,6 +119,29 @@
 
 
 
+template <typename T1,
+	  typename T2>
+void
+test_diff_type_matrix_freqswap( length_type m, length_type n )
+{
+  Matrix<T1> a(m, n);
+
+  Rand<T1> rgen(0);
+  a = rgen.randu(m, n);
+
+  Matrix<T2> b(m, n);
+  b = vsip::freqswap(a);
+
+  for ( index_type i = 0; i < m; i++ )
+    for ( index_type j = 0; j < n; j++ )
+    {
+      test_assert(equal( b.get(i, j),
+			 (T2)a.get(((m+1)/2 + i) % m, ((n+1)/2 + j) % n ) ));
+    }
+}
+
+
+
 template <typename T>
 void
 cases_by_type()
@@ -125,6 +168,9 @@
 {
   vsipl init(argc, argv);
 
+  test_diff_type_vector_freqswap<float, double>(8);
+  test_diff_type_matrix_freqswap<float, double>(4, 4);
+
   cases_by_type<float>();
 #if VSIP_IMPL_TEST_DOUBLE
   cases_by_type<double>();
