Index: configure.ac
===================================================================
--- configure.ac	(revision 206786)
+++ configure.ac	(working copy)
@@ -704,10 +704,8 @@
 #endif])
 
 AC_CHECK_HEADERS([png.h], 
-                 [AC_SUBST(HAVE_PNG_H, 1)], 
-                 [], [// no prerequisites])
+  [AC_CHECK_LIB(png, png_read_info,[AC_SUBST(VSIP_CSL_HAVE_PNG, 1)])])
 
-
 SVXX_CHECK_FFT
 SVXX_CHECK_PARALLEL
 SVXX_CHECK_SAL
Index: src/vsip_csl/GNUmakefile.inc.in
===================================================================
--- src/vsip_csl/GNUmakefile.inc.in	(revision 206767)
+++ src/vsip_csl/GNUmakefile.inc.in	(working copy)
@@ -17,7 +17,7 @@
 # Variables
 ########################################################################
 
-VSIP_CSL_HAVE_PNG	:= @HAVE_PNG_H@
+VSIP_CSL_HAVE_PNG	:= @VSIP_CSL_HAVE_PNG@
 
 src_vsip_csl_CXXINCLUDES := -I$(srcdir)/src
 src_vsip_csl_CXXFLAGS := $(src_vsip_csl_CXXINCLUDES)
