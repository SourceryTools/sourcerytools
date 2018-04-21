Index: ChangeLog
===================================================================
--- ChangeLog	(revision 157544)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
-2006-12-12  Jules Bergmann  <jules@codesourcery.com>
+2006-12-14  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip_csl/load_view.hpp (load_view_as): Extend to work
+	  with distributed views.
+
+2006-12-14  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/core/domain_utils.hpp (intersect): Extend to handle
 	  non-unit-stride in 1 arg.
 	  (apply_intr): New function to apply an intersection to another dom.
Index: src/vsip_csl/load_view.hpp
===================================================================
--- src/vsip_csl/load_view.hpp	(revision 157392)
+++ src/vsip_csl/load_view.hpp	(working copy)
@@ -141,12 +141,16 @@
 }
 
 
-/// Load a view from a file as another type
-///
+
+/// Load a view from a file with another value type.
+
 /// Requires:
 ///   T to be the type on disk.
 ///   FILENAME to be filename.
 ///   VIEW to be a VSIPL++ view.
+///
+/// All other layout parameters (dimension-ordering and parallel
+/// distribution) are preserved.
 
 template <typename T,
           typename ViewT>
@@ -156,12 +160,20 @@
   ViewT       view)
 {
   using vsip::impl::View_of_dim;
+  using vsip::impl::Block_layout;
+  using vsip::impl::clone_view;
 
+  typedef typename ViewT::block_type                    block_type;
+  typedef typename Block_layout<block_type>::order_type order_type;
+  typedef typename ViewT::block_type::map_type          map_type;
+
+  typedef vsip::Dense<ViewT::dim, T, order_type, map_type> new_block_type;
+
   typedef
-    typename View_of_dim<ViewT::dim, T, vsip::Dense<ViewT::dim, T> >::type
+    typename View_of_dim<ViewT::dim, T, new_block_type>::type
     view_type;
 
-  view_type disk_view = vsip::impl::clone_view<view_type>(view);
+  view_type disk_view = clone_view<view_type>(view, view.block().map());
 
   load_view(filename, disk_view);
 
