Index: doc/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/doc/GNUmakefile.inc.in,v
retrieving revision 1.18
diff -u -r1.18 GNUmakefile.inc.in
--- doc/GNUmakefile.inc.in	20 Jan 2006 14:39:29 -0000	1.18
+++ doc/GNUmakefile.inc.in	8 Mar 2006 16:08:44 -0000
@@ -82,15 +82,17 @@
         $(patsubst $(srcdir)/doc/tutorial/%, doc/tutorial/%, \
           $(doc_tutorial_svg) $(doc_tutorial_png))
 
-ifneq '$(srcdir)' '.'
-doc/tutorial/images/%: $(srcdir)/doc/tutorial/images/%
+# These are used in the html version of the tutorial.
+doc/tutorial/tutorial/images/%.png: $(srcdir)/doc/tutorial/images/%.png
 	mkdir -p $(@D)
 	cp $< $@
+	touch doc/tutorial/tutorial
 
-doc/tutorial/tutorial/images/%.png: $(srcdir)/doc/tutorial/images/%.png
+ifneq '$(srcdir)' '.'
+# These are used during pdf generation of the tutorial.
+doc/tutorial/images/%: $(srcdir)/doc/tutorial/images/%
 	mkdir -p $(@D)
 	cp $< $@
-	touch doc/tutorial/tutorial
 
 # Call this target explicitly to copy documentation back into the 
 # source directory, if building in a separate build directory.
