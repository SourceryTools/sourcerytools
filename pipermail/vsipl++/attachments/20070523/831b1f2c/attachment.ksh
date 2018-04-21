Index: ChangeLog
===================================================================
--- ChangeLog	(revision 171934)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2007-05-23  Jules Bergmann  <jules@codesourcery.com>
+
+	* benchmark/hpec_kernel/GNUmakefile.inc.in (install): Depend on
+	  hpec_kernel.
+
 2007-05-22  Jules Bergmann  <jules@codesourcery.com>
 
 	* tests/ref-impl/test.hpp: Use vsip::mag instead of std::abs.
Index: benchmarks/hpec_kernel/GNUmakefile.inc.in
===================================================================
--- benchmarks/hpec_kernel/GNUmakefile.inc.in	(revision 171918)
+++ benchmarks/hpec_kernel/GNUmakefile.inc.in	(working copy)
@@ -45,7 +45,7 @@
 	rm -f $(hpec_targets)
 
 # Install benchmark source code and executables
-install::
+install:: hpec_kernel
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/hpec_kernel
 	for sourcefile in $(hpec_install_targets); do \
