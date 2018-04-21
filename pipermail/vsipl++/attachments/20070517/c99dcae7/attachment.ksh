Index: ChangeLog
===================================================================
--- ChangeLog	(revision 171543)
+++ ChangeLog	(working copy)
@@ -1,5 +1,9 @@
 2007-05-17  Jules Bergmann  <jules@codesourcery.com>
 
+	* scripts/package.py (describe): Add missing parameter.
+
+2007-05-17  Jules Bergmann  <jules@codesourcery.com>
+
 	* scripts/1.3.1-com.cfg: New file, source config for 1.3.1 commercial
 	  release.
 	* scripts/1.3.1-gpl.cfg: New file, source config for 1.3.1 GPL
Index: scripts/package.py
===================================================================
--- scripts/package.py	(revision 171526)
+++ scripts/package.py	(working copy)
@@ -104,7 +104,7 @@
     usage()
     
 
-def describe(**args):
+def describe(cfg, **args):
 
     for s, c in parameters['config'].iteritems():
         print 'suffix :', s
