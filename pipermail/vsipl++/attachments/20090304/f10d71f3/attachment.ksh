Index: ChangeLog
===================================================================
--- ChangeLog	(revision 238503)
+++ ChangeLog	(working copy)
@@ -1,3 +1,7 @@
+2009-03-04  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/GNUmakefile.inc.in: Fix typo to install libsvpp.so.
+
 2009-03-03  Jules Bergmann  <jules@codesourcery.com>
 
 	* m4/ipp.m4: Add missing provide_fft_{float,double}.
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 238120)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -105,10 +105,10 @@
 lib/libsvpp.so: $(src_vsip_cxx_objects)
 	$(link_lib_dso)
 
-install-core:: lib/libsvpp.$(LIBEXT)
+install-core:: lib/libsvpp.so
 	$(INSTALL) -d $(DESTDIR)$(libdir)
-	$(INSTALL_DATA) lib/libsvpp.$(LIBEXT) \
-          $(DESTDIR)$(libdir)/libsvpp$(suffix).$(LIBEXT)
+	$(INSTALL_DATA) lib/libsvpp.so \
+          $(DESTDIR)$(libdir)/libsvpp$(suffix).so
 endif
 
 # Install the SV++ header files.  When building with
