Index: ChangeLog
===================================================================
--- ChangeLog	(revision 214431)
+++ ChangeLog	(working copy)
@@ -1,5 +1,9 @@
 2008-07-10  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip_csl/save_view.hpp: Add missing include.
+
+2008-07-10  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/cbe/ppu/task_manager.hpp: Remove V++ level caching.
 	* src/vsip/opt/cbe/ppu/task_manager.cpp: Likewise.
 	* src/vsip/opt/cbe/ppu/alf.cpp: Use CML alf_chache routines.
Index: src/vsip_csl/save_view.hpp
===================================================================
--- src/vsip_csl/save_view.hpp	(revision 214423)
+++ src/vsip_csl/save_view.hpp	(working copy)
@@ -22,6 +22,7 @@
 #include <vsip/tensor.hpp>
 #include <vsip/core/adjust_layout.hpp>
 #include <vsip/core/view_cast.hpp>
+#include <vsip_csl/matlab.hpp>
 
 
 namespace vsip_csl
