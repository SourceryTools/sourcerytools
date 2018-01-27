Index: ChangeLog
===================================================================
--- ChangeLog	(revision 186286)
+++ ChangeLog	(working copy)
@@ -1,4 +1,8 @@
 2007-11-01  Jules Bergmann  <jules@codesourcery.com>
+	
+	* scripts/trunk-gpl-snapshot.cfg: Use 'csl/fftw/trunk' for FFTW.
+	
+2007-11-01  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip_csl/matlab_bin_formatter.hpp: Fix Wall warnings.
 
Index: scripts/trunk-gpl-snapshot.cfg
===================================================================
--- scripts/trunk-gpl-snapshot.cfg	(revision 185668)
+++ scripts/trunk-gpl-snapshot.cfg	(working copy)
@@ -2,6 +2,6 @@
 
 class MySource(Source):
     svpp_dir='csl/vpp/trunk'
-    fftw_dir='csl/fftw/vendor/3.1.2'
+    fftw_dir='csl/fftw/trunk'
 
 include("config")
