Index: ChangeLog
===================================================================
--- ChangeLog	(revision 218278)
+++ ChangeLog	(working copy)
@@ -1,5 +1,9 @@
 2008-08-21  Jules Bergmann  <jules@codesourcery.com>
 
+	* GNUmakefile.in: Always include csldocbookdir/GNUmakefile.inc
+
+2008-08-21  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/ukernel.hpp: Guard iostream include, generalize
 	  align_shift computation for split.
 	* src/vsip/opt/ukernel/cbe_accel/buffer_resource.hpp: Minor
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 218238)
+++ GNUmakefile.in	(working copy)
@@ -408,9 +408,7 @@
 # them. 
 -include $(patsubst %, %/GNUmakefile.inc, $(subdirs))
 
-ifdef maintainer_mode
 include $(csldocbookdir)/GNUmakefile.inc
-endif
 
 ########################################################################
 # Functions
