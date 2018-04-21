Index: ChangeLog
===================================================================
--- ChangeLog	(revision 192274)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2008-01-30  Jules Bergmann  <jules@codesourcery.com>
 
+	* m4/lapack.m4: Detect ATLAS with v3 lapack/blas, as found on
+	  Ubuntu 7.04.
+
+2008-01-30  Jules Bergmann  <jules@codesourcery.com>
+
 	* configure.ac (--enable-shared-acconfig): Make unshared
 	  acconfig.hpp the default.
 
Index: m4/lapack.m4
===================================================================
--- m4/lapack.m4	(revision 191870)
+++ m4/lapack.m4	(working copy)
@@ -272,9 +272,9 @@
     yes | probe)
       if test "$host" != "$build"; then
         # Can't cross-compile builtin atlas
-        lapack_packages="atlas generic_wo_blas generic_with_blas generic_v3_wo_blas generic_v3_with_blas simple-builtin"
+        lapack_packages="atlas atlas_blas_v3 generic_wo_blas generic_with_blas generic_v3_wo_blas generic_v3_with_blas simple-builtin"
       else
-        lapack_packages="atlas generic_wo_blas generic_with_blas generic_v3_wo_blas generic_v3_with_blas"
+        lapack_packages="atlas atlas_blas_v3 generic_wo_blas generic_with_blas generic_v3_wo_blas generic_v3_with_blas"
       fi
     ;;
     generic)
@@ -393,6 +393,41 @@
 
         lapack_use_ilaenv=0
       ;;
+      atlas_blas_v3)
+	# 080130: This configuration exists on Ubuntu 7.04 (ubuntu) 
+        AC_MSG_CHECKING([for LAPACK/ATLAS v3 library ($trypkg w/BLAS)])
+
+        if test "$with_atlas_libdir" != ""; then
+	  atlas_libdir=" -L$with_atlas_libdir"
+        elif test "$with_atlas_prefix" != ""; then
+	  atlas_libdir=" -L$with_atlas_prefix/lib"
+        else
+	  atlas_libdir=""
+        fi
+
+        if test "$with_atlas_include" != ""; then
+	  atlas_incdir=" -I$with_atlas_include"
+        elif test "$with_atlas_prefix" != ""; then
+	  atlas_incdir=" -I$with_atlas_prefix/include"
+        else
+	  atlas_incdir=""
+        fi
+
+        LDFLAGS="$keep_LDFLAGS$atlas_libdir"
+        CPPFLAGS="$keep_CPPFLAGS$atlas_incdir"
+
+        # Include the g2c library if we can, but do not require it; it
+        # may not be needed.
+        if test $use_g2c == "error"; then
+          LIBS="$keep_LIBS -llapack-3 -lblas-3 -latlas"
+        else
+          LIBS="$keep_LIBS -llapack-3 -lblas-3 -latlas $use_g2c"
+        fi
+
+        cblas_style="1"	# use cblas.h
+
+        lapack_use_ilaenv=0
+      ;;
       atlas_no_cblas)
         AC_MSG_CHECKING([for LAPACK/ATLAS library (w/o CBLAS)])
 
