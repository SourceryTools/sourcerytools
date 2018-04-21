Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 170836)
+++ GNUmakefile.in	(working copy)
@@ -332,6 +332,8 @@
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/pas/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/opt/reductions/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/sal/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/signal/*.hpp))
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 170836)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -109,6 +109,7 @@
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/lapack
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/parallel
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/pas
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/reductions
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/sal
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/signal
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/simd
Index: benchmarks/makefile.standalone.in
===================================================================
--- benchmarks/makefile.standalone.in	(revision 170271)
+++ benchmarks/makefile.standalone.in	(working copy)
@@ -1,6 +1,6 @@
 ######################################################### -*-Makefile-*-
 #
-# File:   benchmarks/make.standalone
+# File:   benchmarks/Makefile
 # Author: Jules Bergmann
 # Date:   2006-01-19
 #
@@ -12,27 +12,32 @@
 
 # EXAMPLES:
 #
-# To compile the fft benchmark for an installed with .pc files visible in
+# To build all of the installed benchmarks with .pc files visible in
 # PKG_CONFIG_PATH:
 #
-#   make -f make.standalone fft
+#   make
 #
-# To compile the fft benchmark for a library that has been installed into
-# a non-standard prefix, or whose .pc files are not in PKG_CONFIG_PATH:
+# To build only the ones in the top-level directory:
 #
-#   make -f make.standalone PREFIX=/path/to/library fft
+#   make benchmarks
 #
+# To compile the fft benchmark only:
+#
+#   make fft
+#
 
-
-
 ########################################################################
 # Configuration Variables
 ########################################################################
 
 # Variables in this section can be set by the user on the command line.
 
-# Prefix of installed library.  Not necessary if your .pc files are in
-# PKG_CONFIG_PATH and if they have the correct prefix.
+# Prefix of installed library.  Set this if the library is installed
+# in a non-standard location, or if the .pc files are not stored
+# in PKG_CONFIG_PATH.
+#
+#  make PREFIX=/path/to/library
+#
 PREFIX   := 
 
 # Package to use.  For binary packages, this should either be 'vsipl++'
@@ -105,6 +110,8 @@
 # Targets
 ########################################################################
 
+all: $(all_targets) $(headers)
+
 benchmarks: $(targets) $(headers)
 
 hpec_kernel:  $(hpec_targets) $(headers)
