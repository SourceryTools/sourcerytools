Index: configure.ac
===================================================================
--- configure.ac	(revision 209798)
+++ configure.ac	(working copy)
@@ -31,6 +31,12 @@
 #  the feature, the secondary purpose is specifying which
 #  external code to use to enable that feature.
 
+
+# These may get set from different backend checks.
+provide_fft_float=0
+provide_fft_double=0
+provide_fft_long_double=0
+
 # Set maintainer_mode to either "true" or the empty string.
 
 AC_ARG_ENABLE(maintainer-mode,
@@ -749,14 +755,14 @@
 fi
 
 if test "$neutral_acconfig" = 'y'; then
-  if test "x$provide_fft_float" != "x"; then
-    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_PROVIDE_FFT_FLOAT=$provide_fft_float"
+  if test $provide_fft_float != 0; then
+    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_PROVIDE_FFT_FLOAT=1"
   fi
-  if test "x$provide_fft_double" != "x"; then
-    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_PROVIDE_FFT_DOUBLE=$provide_fft_double"
+  if test $provide_fft_double != 0; then
+    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_PROVIDE_FFT_DOUBLE=1"
   fi
-  if test "x$provide_fft_long_double" != "x"; then
-    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_PROVIDE_FFT_LONG_DOUBLE=$provide_fft_long_double"
+  if test $provide_fft_long_double != 0; then
+    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_PROVIDE_FFT_LONG_DOUBLE=1"
   fi
 else
   if test "x$provide_fft_float" != "x"; then
Index: m4/fft.m4
===================================================================
--- m4/fft.m4	(revision 209798)
+++ m4/fft.m4	(working copy)
@@ -57,10 +57,6 @@
 # Find the FFT backends.
 # At present, SAL, IPP, and FFTW3 are supported.
 #
-provide_fft_float=0
-provide_fft_double=0
-provide_fft_long_double=0
-
 if test "$enable_fft_float" = yes; then
   vsip_impl_fft_use_float=1
 fi
@@ -153,7 +149,7 @@
     AC_LINK_IFELSE(
       [AC_LANG_PROGRAM([#include <fftw3.h>], [$syms])],
       [AC_MSG_RESULT([yes.])
-       provide_fft_float=1],
+       fftw_has_float=1],
       [AC_MSG_RESULT([no.])
        LIBS=$keep_LIBS])
   fi
@@ -166,7 +162,7 @@
     AC_LINK_IFELSE(
       [AC_LANG_PROGRAM([#include <fftw3.h>], [$syms])],
       [AC_MSG_RESULT([yes.])
-       provide_fft_double=1],
+       fftw_has_double=1],
       [AC_MSG_RESULT([no.])
        LIBS=$keep_LIBS])
   fi
@@ -179,12 +175,11 @@
     AC_LINK_IFELSE(
       [AC_LANG_PROGRAM([#include <fftw3.h>], [$syms])],
       [AC_MSG_RESULT([yes.])
-       provide_fft_long_double=1],
+       fftw_has_long_double=1],
       [AC_MSG_RESULT([no.])
        LIBS=$keep_LIBS])
   fi
 fi
-
 if test "$enable_builtin_fft" != "no"; then
 
   AC_MSG_NOTICE([Using built-in FFTW3 support.])
@@ -212,9 +207,11 @@
       enable_fft_long_double=no 
     else
       AC_MSG_RESULT([supported.])
+      fftw_has_long_double=1
     fi
+    fftw_has_float=1
+    fftw_has_double=1
 
-
     # if $srcdir is relative, correct for chdir into vendor/fftw3*.
     fftw3_configure="`(cd $srcdir/vendor/fftw; echo \"$PWD\")`"/configure
 
@@ -266,7 +263,7 @@
     echo "==============================================================="
 
     if test "$enable_fft_float" = yes; then
-      provide_fft_float=1
+      fftw_has_float=1
       mkdir -p vendor/fftw3f
       AC_MSG_NOTICE([Configuring fftw3f (float).])
       AC_MSG_NOTICE([extra config options: '$fftw3_f_simd'.])
@@ -274,7 +271,7 @@
       libs="$libs -lfftw3f"
     fi
     if test "$enable_fft_double" = yes; then
-      provide_fft_double=1
+      fftw_has_double=1
       mkdir -p vendor/fftw3
       AC_MSG_NOTICE([Configuring fftw3 (double).])
       AC_MSG_NOTICE([extra config options: '$fftw3_d_simd'.])
@@ -282,7 +279,7 @@
       libs="$libs -lfftw3"
     fi
     if test "$enable_fft_long_double" = yes; then
-      provide_fft_long_double=1
+      fftw_has_long_double=1
       # fftw3l config doesn't get SIMD option
       mkdir -p vendor/fftw3l
       AC_MSG_NOTICE([Configuring fftw3l (long double).])
@@ -341,6 +338,36 @@
 
   LATE_LIBS="$FFTW3_LIBS $LATE_LIBS"
   CPPFLAGS="-I$includedir/fftw3 $CPPFLAGS"
+
 fi
 
+if test provide_fft_float = 0
+then provide_fft_float=$fftw_has_float
+fi
+if test provide_fft_double = 0
+then provide_fft_double=$fftw_has_double
+fi
+if test provide_fft_long_double = 0
+then provide_fft_long_double=$fftw_has_long_double
+fi
+
+if test "$neutral_acconfig" = 'y'; then
+  if test $fftw_has_float = 1; then
+    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_FFTW3_HAVE_FLOAT"
+  fi
+  if test $fftw_has_double = 1; then
+    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_FFTW3_HAVE_DOUBLE"
+  fi
+  if test $fftw_has_long_double = 1; then
+    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE"
+  fi
+else
+  AC_DEFINE_UNQUOTED(VSIP_IMPL_FFTW3_HAVE_FLOAT, $fftw_has_float,
+     [Define to 1 if -lfftw3f was found.])
+  AC_DEFINE_UNQUOTED(VSIP_IMPL_FFTW3_HAVE_DOUBLE, $fftw_has_double, 
+    [Define to 1 if -lfftw3d was found.])
+  AC_DEFINE_UNQUOTED(VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE, $fftw_has_long_double,
+     [Define to 1 if -lfftw3l was found.])
+fi
+
 ])
