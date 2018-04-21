Index: doc/GNUmakefile.inc.in
===================================================================
--- doc/GNUmakefile.inc.in	(revision 145324)
+++ doc/GNUmakefile.inc.in	(working copy)
@@ -24,6 +24,7 @@
 html_manuals += doc/quickstart/quickstart doc/tutorial/tutorial
 doc_manuals := $(pdf_manuals) $(html_manuals)
 
+doc_tutorial_xml := $(wildcard $(srcdir)/doc/tutorial/*.xml)
 doc_tutorial_svg := $(wildcard $(srcdir)/doc/tutorial/images/*.svg)
 doc_tutorial_png := $(wildcard $(srcdir)/doc/tutorial/images/*.png)
 doc_tutorial_png += $(wildcard $(srcdir)/doc/tutorial/images/callouts/*.png)
@@ -64,11 +65,18 @@
 endif
 
 $(doc_manuals): $(patsubst %, doc/csl-docbook/fragments/%, opl.xml gpl.xml)
-
+doc_manuals: $(doc_manuals)
+html_manuals: $(html_manuals)
+pdf_manuals: $(pdf_manuals)
 doc/quickstart/quickstart: doc/quickstart/quickstart.html
-
 doc/tutorial/tutorial: doc/tutorial/tutorial.html
 
+# Make both the tutorial.html as well as the tutorial.fo dependent on all xml
+# files in the tutorial/ subdir, as they are probably included in the master 
+# file.
+doc/tutorial/tutorial.html: $(doc_tutorial_xml)
+doc/tutorial/tutorial.fo: $(doc_tutorial_xml)
+
 doc/tutorial/tutorial: \
         $(patsubst $(srcdir)/doc/tutorial/%, doc/tutorial/tutorial/%, \
           $(doc_tutorial_png))
