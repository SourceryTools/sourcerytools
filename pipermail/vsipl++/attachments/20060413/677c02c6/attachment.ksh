Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.432
diff -u -r1.432 ChangeLog
--- ChangeLog	12 Apr 2006 18:57:30 -0000	1.432
+++ ChangeLog	13 Apr 2006 18:14:55 -0000
@@ -1,3 +1,8 @@
+2006-04-13  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* GNUMakefile.in: Fix rule to allow 'sdist' to be run from 
+	within $srcdir.
+
 2006-04-12  Don McCoy  <don@codesourcery.com>
 
 	* benchmarks/loop.hpp: Added secs_per_pt metric calculation.
Index: GNUmakefile.in
===================================================================
RCS file: /home/cvs/Repository/vpp/GNUmakefile.in,v
retrieving revision 1.46
diff -u -r1.46 GNUmakefile.in
--- GNUmakefile.in	3 Apr 2006 20:39:29 -0000	1.46
+++ GNUmakefile.in	13 Apr 2006 18:14:55 -0000
@@ -349,7 +349,8 @@
 
 $(distname).tar.bz2:
 	-rm -rf $(distname)
-	cp -pr $(srcdir) $(distname)
+	mkdir $(distname)
+	cp -pr $(wildcard $(srcdir)/*) $(distname)
 	-chmod -R a+r $(distname)
 	tar cjhf $@ --owner=0 --group=0\
           --exclude CVS \
