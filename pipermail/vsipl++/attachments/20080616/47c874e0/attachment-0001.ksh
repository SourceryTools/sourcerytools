Index: src/vsip_csl/load_view.hpp
===================================================================
--- src/vsip_csl/load_view.hpp	(revision 211570)
+++ src/vsip_csl/load_view.hpp	(working copy)
@@ -29,6 +29,7 @@
 #include <vsip/core/working_view.hpp>
 #include <vsip/core/view_cast.hpp>
 
+#include <vsip_csl/matlab.hpp>
 
 
 namespace vsip_csl
@@ -46,7 +47,8 @@
 void
 load_view(
   FILE* fd,
-  ViewT view)
+  ViewT view,
+  bool  swap_bytes = false)
 {
   using vsip::impl::Block_layout;
   using vsip::impl::Ext_data;
@@ -115,6 +117,15 @@
       std::cout << "         : expecting " << l_size << std::endl;
       exit(1);
     }
+
+    // Swap from either big- to little-endian, or vice versa.  We can do this
+    // as if it were a 1-D view because it is guaranteed to be dense.
+    if ( swap_bytes )
+    {
+      value_type* p_data = ext.data();
+      for (size_t i = 0; i < l_size; ++i)
+        matlab::Swap_value<value_type,true>::swap(p_data++);
+    }
   }
 }
 
@@ -126,7 +137,8 @@
 void
 load_view(
   char const* filename,
-  ViewT       view)
+  ViewT       view,
+  bool        swap_bytes = false)
 {
   if (subblock(view) != vsip::no_subblock && subblock_domain(view).size() > 0)
   {
@@ -138,7 +150,7 @@
       exit(1);
     }
 
-    load_view(fd, view);
+    load_view(fd, view, swap_bytes);
 
     fclose(fd);
   }
@@ -161,7 +173,8 @@
 void
 load_view_as(
   char const* filename,
-  ViewT       view)
+  ViewT       view,
+  bool        swap_bytes = false)
 {
   using vsip::impl::View_of_dim;
   using vsip::impl::Block_layout;
@@ -179,7 +192,7 @@
 
   view_type disk_view = clone_view<view_type>(view, view.block().map());
 
-  load_view(filename, disk_view);
+  load_view(filename, disk_view, swap_bytes);
 
   view = vsip::impl::view_cast<typename ViewT::value_type>(disk_view);
 } 
@@ -211,22 +224,24 @@
 public:
   Load_view(char const*              filename,
 	    vsip::Domain<Dim> const& dom,
-	    MapT const&              map = MapT())
+            MapT const&              map = MapT(),
+            bool                     swap_bytes = false)
     : block_ (dom, map),
       view_  (block_)
   {
-    load_view(filename, view_);
+    load_view(filename, view_, swap_bytes);
   }
 
 
 
   Load_view(FILE*                    fd,
 	    vsip::Domain<Dim> const& dom,
-	    MapT const&              map = MapT())
+            MapT const&              map = MapT(),
+            bool                     swap_bytes = false)
     : block_ (dom, map),
       view_  (block_)
   {
-    load_view(fd, view_);
+    load_view(fd, view_, swap_bytes);
   }
 
   view_type view() { return view_; }
Index: src/vsip_csl/save_view.hpp
===================================================================
--- src/vsip_csl/save_view.hpp	(revision 211570)
+++ src/vsip_csl/save_view.hpp	(working copy)
@@ -82,7 +82,8 @@
 void
 save_view(
   FILE* fd,
-  ViewT view)
+  ViewT view,
+  bool  swap_bytes = false)
 {
   using vsip::impl::Block_layout;
   using vsip::impl::Ext_data;
@@ -144,6 +145,15 @@
       exit(1);
     }
 
+    // Swap from either big- to little-endian, or vice versa.  We can do this
+    // as if it were a 1-D view because it is guaranteed to be dense.
+    if ( swap_bytes )
+    {
+      value_type* p_data = ext.data();
+      for (size_t i = 0; i < l_size; ++i)
+        matlab::Swap_value<value_type,true>::swap(p_data++);
+    }
+
     if (fwrite(ext.data(), sizeof(value_type), l_size, fd) != l_size)
     {
       fprintf(stderr, "save_view: error reading file.\n");
@@ -164,7 +174,8 @@
 void
 save_view(
    char const* filename,
-   ViewT       view)
+   ViewT       view,
+   bool        swap_bytes = false)
 {
   if (subblock(view) != vsip::no_subblock)
   {
@@ -176,7 +187,7 @@
       exit(1);
     }
 
-    save_view(fd, view);
+    save_view(fd, view, swap_bytes);
 
     fclose(fd);
   }
@@ -195,7 +206,8 @@
 void
 save_view_as(
   char* filename,
-  ViewT view)
+  ViewT view,
+  bool  swap_bytes = false)
 {
   using vsip::impl::View_of_dim;
 
@@ -207,7 +219,7 @@
 
   disk_view = vsip::impl::view_cast<T>(view);
     
-  vsip_csl::save_view(filename, disk_view);
+  vsip_csl::save_view(filename, disk_view, swap_bytes);
 } 
 
 
Index: tests/vsip_csl/load_view.cpp
===================================================================
--- tests/vsip_csl/load_view.cpp	(revision 211570)
+++ tests/vsip_csl/load_view.cpp	(working copy)
@@ -61,7 +61,8 @@
   SaveMapT const&    save_map,
   LoadMapT const&    load_map,
   int                k,
-  bool               do_barrier = false)
+  bool               do_barrier = false,
+  bool               swap_bytes = false)
 {
   using vsip::impl::View_of_dim;
 
@@ -81,18 +82,18 @@
   // processors still doing an earlier test.
   if (do_barrier) impl::default_communicator().barrier();
 
-  save_view(filename, s_view);
+  save_view(filename, s_view, swap_bytes);
 
   // Wait for all writers to complete before starting to read.
   if (do_barrier) impl::default_communicator().barrier();
 
   // Test load_view function.
   load_view_type l_view(create_view<load_view_type>(dom, load_map));
-  load_view(filename, l_view);
+  load_view(filename, l_view, swap_bytes);
   check(l_view, k);
 
   // Test Load_view class.
-  Load_view<Dim, T, OrderT, LoadMapT> l_view_obj(filename, dom, load_map);
+  Load_view<Dim, T, OrderT, LoadMapT> l_view_obj(filename, dom, load_map, swap_bytes);
   check(l_view_obj.view(), k);
 }
 
@@ -148,6 +149,11 @@
   test_ls<T, tuple<1, 0, 2> >(Domain<3>(4, 7, 3), map_0, map_c, 1, true);
   test_ls<T, tuple<0, 2, 1> >(Domain<3>(5, 3, 6), map_0, map_r, 1, true);
 
+  // Big-endian tests
+  test_ls<T, row1_type>      (Domain<1>(16),      map_0, map_0, 1, true, true);
+  test_ls<T, row2_type>      (Domain<2>(7, 5),    map_0, map_r, 1, true, true);
+  test_ls<T, row3_type>      (Domain<3>(5, 3, 6), map_0, map_r, 1, true, true);
+
   // As above, prevent processors from going on to the next set of
   // local tests before all the others are done reading.
   impl::default_communicator().barrier();
