Index: ChangeLog
===================================================================
--- ChangeLog	(revision 239521)
+++ ChangeLog	(working copy)
@@ -1,5 +1,9 @@
 2009-03-10  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip_csl/matlab_utils.hpp: Make fd_fftshift distributed aware.
+
+2009-03-10  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip_csl/save_view.hpp: Fix Wall warning.
 
 2009-03-06  Jules Bergmann  <jules@codesourcery.com>
Index: src/vsip_csl/matlab_utils.hpp
===================================================================
--- src/vsip_csl/matlab_utils.hpp	(revision 236492)
+++ src/vsip_csl/matlab_utils.hpp	(working copy)
@@ -13,8 +13,11 @@
 #ifndef VSIP_CSL_MATLAB_UTILS_HPP
 #define VSIP_CSL_MATLAB_UTILS_HPP
 
+#include <cassert>
+
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
+#include <vsip/core/block_traits.hpp>
 
 
 namespace vsip_csl
@@ -238,17 +241,32 @@
 fd_fftshift(Matrix1T in, Matrix2T out)
 {
   using namespace vsip;
+
   typedef typename Matrix1T::value_type T;
-  length_type rows = in.size(0);
-  length_type cols = in.size(1);
+  typedef typename Matrix2T::block_type block2_type;
+  typedef typename Matrix1T::block_type::map_type map1_type;
 
+  length_type rows = in.local().size(0);
+  length_type cols = in.local().size(1);
+
   Matrix<T> w(rows, cols);
+
+  index_type g_offset0 = global_from_local_index(out, 0, 0);
+  index_type g_offset1 = global_from_local_index(out, 1, 0);
   
   w = T(+1);
-  w(Domain<2>(Domain<1>(0, 2, rows/2), Domain<1>(1, 2, cols/2))) = T(-1);
-  w(Domain<2>(Domain<1>(1, 2, rows/2), Domain<1>(0, 2, cols/2))) = T(-1);
+  if (g_offset0 % 2 == 0 && g_offset1 % 2 == 0)
+  {
+    w(Domain<2>(Domain<1>(0, 2, rows/2), Domain<1>(1, 2, cols/2))) = T(-1);
+    w(Domain<2>(Domain<1>(1, 2, rows/2), Domain<1>(0, 2, cols/2))) = T(-1);
+  }
+  else
+  {
+    w(Domain<2>(Domain<1>(0, 2, rows/2), Domain<1>(0, 2, cols/2))) = T(-1);
+    w(Domain<2>(Domain<1>(1, 2, rows/2), Domain<1>(1, 2, cols/2))) = T(-1);
+  }
 
-  out = in * w;
+  out.local() = in.local() * w;
 }
 
 
@@ -261,21 +279,33 @@
 fd_fftshift_col(Matrix1T in, Matrix2T out)
 {
   using namespace vsip;
+
   typedef typename Matrix1T::value_type T;
-  length_type rows = in.size(0);
-  length_type cols = in.size(1);
+  typedef typename Matrix2T::block_type block2_type;
+  typedef typename Matrix1T::block_type::map_type map1_type;
 
+  assert((vsip::impl::Is_par_same_map<2, map1_type, block2_type>
+	  ::value(in.block().map(), out.block())));
+
+  length_type rows = in.local().size(0);
+  length_type cols = in.local().size(1);
+
   Matrix<T> w(rows, cols);
+
+  index_type g_offset = global_from_local_index(out, 0, 0);
+  index_type start    = 1 - (g_offset % 2);
   
   w = T(+1);
-  w(Domain<2>(Domain<1>(1, 2, rows/2), Domain<1>(0, 1, cols))) = T(-1);
+  w(Domain<2>(Domain<1>(start, 2, rows/2), Domain<1>(0, 1, cols))) = T(-1);
 
-  out = in * w;
+  out.local() = in.local() * w;
 }
 
 
 
 // Partial frequency domain matrix fftshift across dimension 1 (along rows)
+// 
+// Input and output matrices must have same map.
 
 template <typename Matrix1T,
 	  typename Matrix2T>
@@ -283,16 +313,26 @@
 fd_fftshift_row(Matrix1T in, Matrix2T out)
 {
   using namespace vsip;
+
   typedef typename Matrix1T::value_type T;
-  length_type rows = in.size(0);
-  length_type cols = in.size(1);
+  typedef typename Matrix2T::block_type block2_type;
+  typedef typename Matrix1T::block_type::map_type map1_type;
 
+  assert((vsip::impl::Is_par_same_map<2, map1_type, block2_type>
+	  ::value(in.block().map(), out.block())));
+
+  length_type rows = in.local().size(0);
+  length_type cols = in.local().size(1);
+
   Matrix<T> w(rows, cols);
+
+  index_type g_offset = global_from_local_index(out, 1, 0);
+  index_type start    = 1 - (g_offset % 2);
   
   w = T(+1);
-  w(Domain<2>(Domain<1>(0, 1, rows), Domain<1>(1, 2, cols/2))) = T(-1);
+  w(Domain<2>(Domain<1>(0, 1, rows), Domain<1>(start, 2, cols/2))) = T(-1);
 
-  out = in * w;
+  out.local() = in.local() * w;
 }
 
 
