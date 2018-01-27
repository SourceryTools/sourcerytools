Index: src/vsip_csl/matlab.hpp
===================================================================
--- src/vsip_csl/matlab.hpp	(revision 212999)
+++ src/vsip_csl/matlab.hpp	(working copy)
@@ -66,14 +66,15 @@
 
   template <typename T = char,
 	    bool to_swap_or_not_to_swap = false,
-	    size_t type_size = sizeof(T)>
+            size_t type_size = sizeof(T),
+            bool IsComplex = vsip::impl::Is_complex<T>::value>
   struct Swap_value 
   { 
     static void swap(T *d) {d=d;} 
   };
 
   template <typename T>
-  struct Swap_value<T,true,2>
+  struct Swap_value<T,true,2,false>
   {
     static void swap(T* d)
     {
@@ -83,7 +84,7 @@
   };
 
   template <typename T>
-  struct Swap_value<T,true,4>
+  struct Swap_value<T,true,4,false>
   {
     static void swap(T* d)
     {
@@ -94,7 +95,7 @@
   };
 
   template <typename T>
-  struct Swap_value<T,true,8>
+  struct Swap_value<T,true,8,false>
   {
     static void swap(T* d)
     {
@@ -106,6 +107,37 @@
     }
   };
 
+  template <typename T>
+  struct Swap_value<T,true,8,true>   // complex
+  {
+    static void swap(T* d)
+    {
+      char *p = reinterpret_cast<char*>(d);
+      std::swap(p[0],p[3]);
+      std::swap(p[1],p[2]);
+      std::swap(p[4],p[7]);
+      std::swap(p[5],p[6]);
+    }
+  };
+
+  template <typename T>
+  struct Swap_value<T,true,16,true>  // complex
+  {
+    static void swap(T* d)
+    {
+      char *p = reinterpret_cast<char*>(d);
+      std::swap(p[0],p[7]);
+      std::swap(p[1],p[6]);
+      std::swap(p[2],p[5]);
+      std::swap(p[3],p[4]);
+      std::swap(p[8],p[15]);
+      std::swap(p[9],p[14]);
+      std::swap(p[10],p[13]);
+      std::swap(p[11],p[12]);
+    }
+  };
+
+
   // a swap wrapper function
   template <typename T>
   void swap(T *data, bool swap_bytes)
Index: src/vsip_csl/save_view.hpp
===================================================================
--- src/vsip_csl/save_view.hpp	(revision 213008)
+++ src/vsip_csl/save_view.hpp	(working copy)
@@ -17,12 +17,15 @@
   Included Files
 ***********************************************************************/
 
+#include <vsip/map.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
 #include <vsip/core/adjust_layout.hpp>
+#include <vsip/core/working_view.hpp>
 #include <vsip/core/view_cast.hpp>
 
+#include <vsip_csl/matlab.hpp>
 
 namespace vsip_csl
 {
@@ -103,19 +106,11 @@
     typedef typename Adjust_layout_complex<Cmplx_inter_fmt, layout_type>::type
       use_layout_type;
 
-    l_view_type l_view = view.local();
-
     vsip::Domain<Dim> g_dom = global_domain(view);
     vsip::Domain<Dim> l_dom = subblock_domain(view);
 
     assert(is_subdomain_contiguous<order_type>(g_dom, extent(view)));
 
-    Ext_data<l_block_type, use_layout_type> ext(l_view.block());
-
-
-    // Check that subblock is dense.
-    assert(vsip::impl::is_ext_dense<order_type>(Dim, ext));
-
     long l_pos = 0;
 
     if (Dim >= 1)
@@ -145,19 +140,40 @@
       exit(1);
     }
 
-    // Swap from either big- to little-endian, or vice versa.  We can do this
-    // as if it were a 1-D view because it is guaranteed to be dense.
     if ( swap_bytes )
     {
+      // Make a copy in order to swap the bytes prior to writing to disk
+      l_view_type l_view = vsip::impl::clone_view<l_view_type>(view.local());
+      l_view = view.local();
+      
+      Ext_data<l_block_type, use_layout_type> ext(l_view.block());
+
+      // Swap from either big- to little-endian, or vice versa.  We can do this
+      // as if it were a 1-D view because it is guaranteed to be dense.
       value_type* p_data = ext.data();
       for (size_t i = 0; i < l_size; ++i)
         matlab::Swap_value<value_type,true>::swap(p_data++);
+
+      if (fwrite(ext.data(), sizeof(value_type), l_size, fd) != l_size)
+      {
+        fprintf(stderr, "save_view: error reading file.\n");
+        exit(1);
+      }
     }
+    else
+    {
+      l_view_type l_view = view.local();
 
-    if (fwrite(ext.data(), sizeof(value_type), l_size, fd) != l_size)
-    {
-      fprintf(stderr, "save_view: error reading file.\n");
-      exit(1);
+      Ext_data<l_block_type, use_layout_type> ext(l_view.block());
+
+      // Check that subblock is dense.
+      assert(vsip::impl::is_ext_dense<order_type>(Dim, ext));
+
+      if (fwrite(ext.data(), sizeof(value_type), l_size, fd) != l_size)
+      {
+        fprintf(stderr, "save_view: error reading file.\n");
+        exit(1);
+      }
     }
   }
 }
@@ -205,9 +221,9 @@
           typename ViewT>
 void
 save_view_as(
-  char* filename,
-  ViewT view,
-  bool  swap_bytes = false)
+  char const* filename,
+  ViewT       view,
+  bool        swap_bytes = false)
 {
   using vsip::impl::View_of_dim;
 
Index: tests/vsip_csl/load_view_cplx.cpp
===================================================================
--- tests/vsip_csl/load_view_cplx.cpp	(revision 212999)
+++ tests/vsip_csl/load_view_cplx.cpp	(working copy)
@@ -1,10 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006-2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    tests/vsip_csl/load_view.hpp
+/** @file    tests/vsip_csl/load_view_cplx.cpp
     @author  Jules Bergmann
     @date    2006-09-28
     @brief   VSIPL++ Library: Unit-tests for vsip_csl/load_view.hpp
@@ -31,132 +31,55 @@
 #include <vsip_csl/load_view.hpp>
 #include <vsip_csl/save_view.hpp>
 
+#include "load_save.hpp"
 #include "test_common.hpp"
-#include "util.hpp"
 
 using namespace std;
 using namespace vsip;
 using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
 
-// Test a round-trip through a file:
-//  - create data in view
-//  - save to disk using 'save_view'
-//  - load from disk using 'Load_view'
-//  - check result.
 
-template <typename       T,
-	  typename       OrderT,
-	  dimension_type Dim,
-	  typename       SaveMapT,
-	  typename       LoadMapT>
+template <typename T>
 void
-test_ls(
-  Domain<Dim> const& dom,
-  SaveMapT const&    save_map,
-  LoadMapT const&    load_map,
-  int                k,
-  bool               do_barrier = false,
-  bool               swap_bytes = false)
+test_complex_ls(
+  length_type size)
 {
-  using vsip::impl::View_of_dim;
-
   char const* filename = "test.load_view.tmpfile";
 
-  typedef Dense<Dim, T, OrderT, SaveMapT>                     save_block_type;
-  typedef typename View_of_dim<Dim, T, save_block_type>::type save_view_type;
+  typedef Vector<complex<T> > view_type;
+  view_type s_view(size);
+  setup(s_view, 1);
 
-  typedef Dense<Dim, T, OrderT, LoadMapT>                     load_block_type;
-  typedef typename View_of_dim<Dim, T, load_block_type>::type load_view_type;
-
-  save_view_type s_view(create_view<save_view_type>(dom, save_map));
-
-  setup(s_view, k);
-
-  // Because the same file is shared for all tests, Wait for any
-  // processors still doing an earlier test.
-  if (do_barrier) impl::default_communicator().barrier();
-
+  bool swap_bytes = true;
   save_view(filename, s_view, swap_bytes);
 
-  // Wait for all writers to complete before starting to read.
-  if (do_barrier) impl::default_communicator().barrier();
 
-  // Test load_view function.
-  load_view_type l_view(create_view<load_view_type>(dom, load_map));
-  load_view(filename, l_view, swap_bytes);
-  check(l_view, k);
+  // Make sure the view didn't change (this is a regression test
+  // against the view being swapped in place prior to being written
+  // to a file).
+  view_type ref_view(size);
+  setup(ref_view, 1);
+  test_assert(view_equal(ref_view, s_view));
 
-  // Test Load_view class.
-  Load_view<Dim, T, OrderT, LoadMapT> l_view_obj(filename, dom, load_map, swap_bytes);
-  check(l_view_obj.view(), k);
-}
 
+  // Now read the data back in scalar form and ensure that the real
+  // and imaginary parts were not swapped (also a regression test)
+  typedef Vector<T> scalar_view_type;
+  scalar_view_type l_view(size * 2, T());
+  load_view(filename, l_view, !swap_bytes);
 
+  T real = l_view.get(2); // second real value
+  T imag = l_view.get(3); // second imaginary value
+  matlab::Swap_value<T,true>::swap(&real);
+  matlab::Swap_value<T,true>::swap(&imag);
 
-template <typename T>
-void
-test_type()
-{
-  Local_map l_map;
-
-  Map<> map_0(1, 1);				// Root map
-  Map<> map_r(vsip::num_processors(), 1);
-  Map<> map_c(1, vsip::num_processors());
-
-  // Local_map tests
-  if (vsip::local_processor() == 0)
-  {
-    test_ls<T, row1_type>      (Domain<1>(16),      l_map, l_map, 1, false);
-
-    test_ls<T, row2_type>      (Domain<2>(7, 5),    l_map, l_map, 1, false);
-    test_ls<T, col2_type>      (Domain<2>(4, 7),    l_map, l_map, 1, false);
-
-    test_ls<T, row3_type>      (Domain<3>(5, 3, 6), l_map, l_map, 1, false);
-    test_ls<T, col3_type>      (Domain<3>(4, 7, 3), l_map, l_map, 1, false);
-    test_ls<T, tuple<0, 2, 1> >(Domain<3>(5, 3, 6), l_map, l_map, 1, false);
-  }
-
-  // Because the same file name is used for all invocations of test_ls,
-  // it is possible that processors other than 0 can race ahead and
-  // corrupt the file being used by processor 0.  To avoid this, we
-  // use a barrier here.
-  impl::default_communicator().barrier();
-
-  // 1D tests
-  test_ls<T, row1_type>      (Domain<1>(16),      map_0, map_0, 1, true);
-  test_ls<T, row2_type>      (Domain<2>(7, 5),    map_0, map_0, 1, true);
-  test_ls<T, col2_type>      (Domain<2>(4, 7),    map_0, map_0, 1, true);
-  test_ls<T, row3_type>      (Domain<3>(5, 3, 6), map_0, map_0, 1, true);
-  test_ls<T, tuple<1, 0, 2> >(Domain<3>(4, 7, 3), map_0, map_0, 1, true);
-  test_ls<T, tuple<0, 2, 1> >(Domain<3>(5, 3, 6), map_0, map_0, 1, true);
-
-
-  // 1D tests
-  test_ls<T, row1_type>      (Domain<1>(16),      map_0, map_r, 1, true);
-
-  // 2D tests
-  test_ls<T, row2_type>      (Domain<2>(7, 5),    map_0, map_r, 1, true);
-  test_ls<T, col2_type>      (Domain<2>(4, 7),    map_0, map_c, 1, true);
-
-  // 3D tests
-  test_ls<T, row3_type>      (Domain<3>(5, 3, 6), map_0, map_r, 1, true);
-  test_ls<T, tuple<1, 0, 2> >(Domain<3>(4, 7, 3), map_0, map_c, 1, true);
-  test_ls<T, tuple<0, 2, 1> >(Domain<3>(5, 3, 6), map_0, map_r, 1, true);
-
-  // Big-endian tests
-  test_ls<T, row1_type>      (Domain<1>(16),      map_0, map_0, 1, true, true);
-  test_ls<T, row2_type>      (Domain<2>(7, 5),    map_0, map_r, 1, true, true);
-  test_ls<T, row3_type>      (Domain<3>(5, 3, 6), map_0, map_r, 1, true, true);
-
-  // As above, prevent processors from going on to the next set of
-  // local tests before all the others are done reading.
-  impl::default_communicator().barrier();
+  test_assert(equal(real, ref_view.real().get(1)));
+  test_assert(equal(imag, ref_view.imag().get(1)));
 }
 
 
@@ -182,10 +105,15 @@
   cout << "start\n";
 #endif
 
-  test_type<int>();
-  test_type<float>();
-  test_type<double>();
+  // Note: Complex versions of these tests are found in the module
+  // 'load_view_cplx.cpp'.  The tests were split to improve compile time.
   test_type<complex<float> >();
+  test_type<complex<double> >();
+
+  // The tests below handle additional checks for particular bug fixes
+  // (regressions).
+  test_complex_ls<float>(10);
+  test_complex_ls<double>(10);
 }
 
 
Index: tests/vsip_csl/load_save.hpp
===================================================================
--- tests/vsip_csl/load_save.hpp	(revision 212999)
+++ tests/vsip_csl/load_save.hpp	(working copy)
@@ -1,45 +1,25 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006-2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    tests/vsip_csl/load_view.hpp
+/** @file    tests/vsip_csl/load_save.hpp
     @author  Jules Bergmann
     @date    2006-09-28
-    @brief   VSIPL++ Library: Unit-tests for vsip_csl/load_view.hpp
+    @brief   VSIPL++ Library: Common code for load/save_view unit-tests.
 */
 
 /***********************************************************************
   Included Files
 ***********************************************************************/
 
-#define DEBUG 0
-
-#include <iostream>
-#if DEBUG
-#include <unistd.h>
-#endif
-#include <vsip/support.hpp>
-#include <vsip/initfin.hpp>
-#include <vsip/vector.hpp>
-#include <vsip/math.hpp>
-#include <vsip/random.hpp>
-
-#include <vsip_csl/test.hpp>
-#include <vsip_csl/test-storage.hpp>
 #include <vsip_csl/load_view.hpp>
 #include <vsip_csl/save_view.hpp>
 
-#include "test_common.hpp"
 #include "util.hpp"
 
-using namespace std;
-using namespace vsip;
-using namespace vsip_csl;
 
-
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -52,18 +32,19 @@
 
 template <typename       T,
 	  typename       OrderT,
-	  dimension_type Dim,
+          vsip::dimension_type Dim,
 	  typename       SaveMapT,
 	  typename       LoadMapT>
 void
 test_ls(
-  Domain<Dim> const& dom,
+  vsip::Domain<Dim> const& dom,
   SaveMapT const&    save_map,
   LoadMapT const&    load_map,
   int                k,
   bool               do_barrier = false,
   bool               swap_bytes = false)
 {
+  using vsip::Dense;
   using vsip::impl::View_of_dim;
 
   char const* filename = "test.load_view.tmpfile";
@@ -80,20 +61,21 @@
 
   // Because the same file is shared for all tests, Wait for any
   // processors still doing an earlier test.
-  if (do_barrier) impl::default_communicator().barrier();
+  if (do_barrier) vsip::impl::default_communicator().barrier();
 
-  save_view(filename, s_view, swap_bytes);
+  vsip_csl::save_view(filename, s_view, swap_bytes);
 
   // Wait for all writers to complete before starting to read.
-  if (do_barrier) impl::default_communicator().barrier();
+  if (do_barrier) vsip::impl::default_communicator().barrier();
 
   // Test load_view function.
   load_view_type l_view(create_view<load_view_type>(dom, load_map));
-  load_view(filename, l_view, swap_bytes);
+  vsip_csl::load_view(filename, l_view, swap_bytes);
   check(l_view, k);
 
   // Test Load_view class.
-  Load_view<Dim, T, OrderT, LoadMapT> l_view_obj(filename, dom, load_map, swap_bytes);
+  vsip_csl::Load_view<Dim, T, OrderT, LoadMapT> 
+    l_view_obj(filename, dom, load_map, swap_bytes);
   check(l_view_obj.view(), k);
 }
 
@@ -103,6 +85,7 @@
 void
 test_type()
 {
+  using namespace vsip;
   Local_map l_map;
 
   Map<> map_0(1, 1);				// Root map
@@ -160,32 +143,3 @@
 }
 
 
-
-int
-main(int argc, char** argv)
-{
-  vsipl init(argc, argv);
-
-#if DEBUG
-  // Enable this section for easier debugging.
-  impl::Communicator& comm = impl::default_communicator();
-  pid_t pid = getpid();
-
-  cout << "rank: "   << comm.rank()
-       << "  size: " << comm.size()
-       << "  pid: "  << pid
-       << endl;
-
-  // Stop each process, allow debugger to be attached.
-  if (comm.rank() == 0) fgetc(stdin);
-  comm.barrier();
-  cout << "start\n";
-#endif
-
-  test_type<int>();
-  test_type<float>();
-  test_type<double>();
-  test_type<complex<float> >();
-}
-
-
Index: tests/vsip_csl/load_view.cpp
===================================================================
--- tests/vsip_csl/load_view.cpp	(revision 213008)
+++ tests/vsip_csl/load_view.cpp	(working copy)
@@ -31,136 +31,19 @@
 #include <vsip_csl/load_view.hpp>
 #include <vsip_csl/save_view.hpp>
 
+#include "load_save.hpp"
 #include "test_common.hpp"
-#include "util.hpp"
 
 using namespace std;
 using namespace vsip;
 using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
 
-// Test a round-trip through a file:
-//  - create data in view
-//  - save to disk using 'save_view'
-//  - load from disk using 'Load_view'
-//  - check result.
 
-template <typename       T,
-	  typename       OrderT,
-	  dimension_type Dim,
-	  typename       SaveMapT,
-	  typename       LoadMapT>
-void
-test_ls(
-  Domain<Dim> const& dom,
-  SaveMapT const&    save_map,
-  LoadMapT const&    load_map,
-  int                k,
-  bool               do_barrier = false,
-  bool               swap_bytes = false)
-{
-  using vsip::impl::View_of_dim;
-
-  char const* filename = "test.load_view.tmpfile";
-
-  typedef Dense<Dim, T, OrderT, SaveMapT>                     save_block_type;
-  typedef typename View_of_dim<Dim, T, save_block_type>::type save_view_type;
-
-  typedef Dense<Dim, T, OrderT, LoadMapT>                     load_block_type;
-  typedef typename View_of_dim<Dim, T, load_block_type>::type load_view_type;
-
-  save_view_type s_view(create_view<save_view_type>(dom, save_map));
-
-  setup(s_view, k);
-
-  // Because the same file is shared for all tests, Wait for any
-  // processors still doing an earlier test.
-  if (do_barrier) impl::default_communicator().barrier();
-
-  save_view(filename, s_view, swap_bytes);
-
-  // Wait for all writers to complete before starting to read.
-  if (do_barrier) impl::default_communicator().barrier();
-
-  // Test load_view function.
-  load_view_type l_view(create_view<load_view_type>(dom, load_map));
-  load_view(filename, l_view, swap_bytes);
-  check(l_view, k);
-
-  // Test Load_view class.
-  Load_view<Dim, T, OrderT, LoadMapT> l_view_obj(filename, dom, load_map, swap_bytes);
-  check(l_view_obj.view(), k);
-}
-
-
-
-template <typename T>
-void
-test_type()
-{
-  Local_map l_map;
-
-  Map<> map_0(1, 1);				// Root map
-  Map<> map_r(vsip::num_processors(), 1);
-  Map<> map_c(1, vsip::num_processors());
-
-  // Local_map tests
-  if (vsip::local_processor() == 0)
-  {
-    test_ls<T, row1_type>      (Domain<1>(16),      l_map, l_map, 1, false);
-
-    test_ls<T, row2_type>      (Domain<2>(7, 5),    l_map, l_map, 1, false);
-    test_ls<T, col2_type>      (Domain<2>(4, 7),    l_map, l_map, 1, false);
-
-    test_ls<T, row3_type>      (Domain<3>(5, 3, 6), l_map, l_map, 1, false);
-    test_ls<T, col3_type>      (Domain<3>(4, 7, 3), l_map, l_map, 1, false);
-    test_ls<T, tuple<0, 2, 1> >(Domain<3>(5, 3, 6), l_map, l_map, 1, false);
-  }
-
-  // Because the same file name is used for all invocations of test_ls,
-  // it is possible that processors other than 0 can race ahead and
-  // corrupt the file being used by processor 0.  To avoid this, we
-  // use a barrier here.
-  impl::default_communicator().barrier();
-
-  // 1D tests
-  test_ls<T, row1_type>      (Domain<1>(16),      map_0, map_0, 1, true);
-  test_ls<T, row2_type>      (Domain<2>(7, 5),    map_0, map_0, 1, true);
-  test_ls<T, col2_type>      (Domain<2>(4, 7),    map_0, map_0, 1, true);
-  test_ls<T, row3_type>      (Domain<3>(5, 3, 6), map_0, map_0, 1, true);
-  test_ls<T, tuple<1, 0, 2> >(Domain<3>(4, 7, 3), map_0, map_0, 1, true);
-  test_ls<T, tuple<0, 2, 1> >(Domain<3>(5, 3, 6), map_0, map_0, 1, true);
-
-
-  // 1D tests
-  test_ls<T, row1_type>      (Domain<1>(16),      map_0, map_r, 1, true);
-
-  // 2D tests
-  test_ls<T, row2_type>      (Domain<2>(7, 5),    map_0, map_r, 1, true);
-  test_ls<T, col2_type>      (Domain<2>(4, 7),    map_0, map_c, 1, true);
-
-  // 3D tests
-  test_ls<T, row3_type>      (Domain<3>(5, 3, 6), map_0, map_r, 1, true);
-  test_ls<T, tuple<1, 0, 2> >(Domain<3>(4, 7, 3), map_0, map_c, 1, true);
-  test_ls<T, tuple<0, 2, 1> >(Domain<3>(5, 3, 6), map_0, map_r, 1, true);
-
-  // Big-endian tests
-  test_ls<T, row1_type>      (Domain<1>(16),      map_0, map_0, 1, true, true);
-  test_ls<T, row2_type>      (Domain<2>(7, 5),    map_0, map_r, 1, true, true);
-  test_ls<T, row3_type>      (Domain<3>(5, 3, 6), map_0, map_r, 1, true, true);
-
-  // As above, prevent processors from going on to the next set of
-  // local tests before all the others are done reading.
-  impl::default_communicator().barrier();
-}
-
-
-
 int
 main(int argc, char** argv)
 {
@@ -182,10 +65,11 @@
   cout << "start\n";
 #endif
 
+  // Note: Complex versions of these tests are found in the module
+  // 'load_view_cplx.cpp'.  The tests were split to improve compile time.
   test_type<int>();
   test_type<float>();
   test_type<double>();
-  test_type<complex<float> >();
 }
 
 
