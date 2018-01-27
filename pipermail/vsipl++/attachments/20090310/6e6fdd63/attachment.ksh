Index: ChangeLog
===================================================================
--- ChangeLog	(revision 238950)
+++ ChangeLog	(working copy)
@@ -1,3 +1,7 @@
+2009-03-10  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip_csl/save_view.hpp: Fix Wall warning.
+
 2009-03-06  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/ukernel.hpp: Add num_accel function to 
Index: src/vsip_csl/save_view.hpp
===================================================================
--- src/vsip_csl/save_view.hpp	(revision 236492)
+++ src/vsip_csl/save_view.hpp	(working copy)
@@ -64,13 +64,11 @@
   }
   else /*  if (Dim == 2) */
   {
-    return (sub_dom[dim2].stride() == 1) &&
-           (sub_dom[dim0].size() == 1 && sub_dom[dim1].size() == 1 ||
-	    (sub_dom[dim1].stride() == 1 &&
-	     sub_dom[dim2].size() == ext[dim2])) &&
-           (sub_dom[dim0].size() == 1 ||
-	    (sub_dom[dim0].stride() == 1 &&
-	     sub_dom[dim1].size() == ext[dim1]));
+    return (sub_dom[dim2].stride() == 1)
+      && ((sub_dom[dim0].size() == 1 && sub_dom[dim1].size() == 1) ||
+	  (sub_dom[dim1].stride() == 1 && sub_dom[dim2].size() == ext[dim2]))
+      && (sub_dom[dim0].size() == 1  ||
+	  (sub_dom[dim0].stride() == 1 && sub_dom[dim1].size() == ext[dim1]));
   }
 }
 
