Index: ChangeLog
===================================================================
--- ChangeLog	(revision 158202)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2006-12-20  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/core/working_view.hpp (clone_view): Add specializations
+	  to set map of new view.
+
+2006-12-20  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/view_cast.hpp: Move to ...
 	* src/vsip/core/view_cast.hpp: ... here.
 	* src/vsip/opt/sal/is_op_supported.hpp: Update is_op_supported
Index: src/vsip/core/working_view.hpp
===================================================================
--- src/vsip/core/working_view.hpp	(revision 157392)
+++ src/vsip/core/working_view.hpp	(working copy)
@@ -74,6 +74,41 @@
 
 
 
+template <typename ViewT,
+	  typename T,
+	  typename BlockT,
+	  typename MapT>
+ViewT
+clone_view(const_Vector<T, BlockT> view, MapT const& map)
+{
+  ViewT ret(view.size(0), map);
+  return ret;
+}
+
+template <typename ViewT,
+	  typename T,
+	  typename BlockT,
+	  typename MapT>
+ViewT
+clone_view(const_Matrix<T, BlockT> view, MapT const& map)
+{
+  ViewT ret(view.size(0), view.size(1), map);
+  return ret;
+}
+
+template <typename ViewT,
+	  typename T,
+	  typename BlockT,
+	  typename MapT>
+ViewT
+clone_view(const_Tensor<T, BlockT> view, MapT const& map)
+{
+  ViewT ret(view.size(0), view.size(1), view.size(2), map);
+  return ret;
+}
+
+
+
 // Helper class for assigning between local and distributed views.
 
 template <typename View1,
