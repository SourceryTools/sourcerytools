Index: ChangeLog
===================================================================
--- ChangeLog	(revision 218281)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2008-08-22  Jules Bergmann  <jules@codesourcery.com>
+
+	* m4/fft.m4: Fix fftw_has_{float,double,long_double} logic when
+	  using builtin FFTW.
+
 2008-08-21  Jules Bergmann  <jules@codesourcery.com>
 
 	* GNUmakefile.in: Always include csldocbookdir/GNUmakefile.inc
Index: m4/fft.m4
===================================================================
--- m4/fft.m4	(revision 218238)
+++ m4/fft.m4	(working copy)
@@ -39,12 +39,12 @@
 AC_ARG_WITH(fftw3_cflags,
   AS_HELP_STRING([--with-fftw3-cflags=CFLAGS],
                  [Specify CFLAGS to use when building built-in FFTW3.
-		  Only used if --with-fft=builtin.]))
+		  Only used if --enable-fft=builtin.]))
 
 AC_ARG_WITH(fftw3_cfg_opts,
   AS_HELP_STRING([--with-fftw3-cfg-opts=OPTS],
                  [Specify additional options to use when configuring built-in
-                  FFTW3. Only used if --with-fft=builtin.]))
+                  FFTW3. Only used if --enable-fft=builtin.]))
 
 AC_ARG_ENABLE(fftw3_simd,
   AS_HELP_STRING([--disable-fftw3-simd],
@@ -196,21 +196,20 @@
     # Determine whether long double is supported.
     AC_CHECK_SIZEOF(double)
     AC_CHECK_SIZEOF(long double)
-    AC_MSG_CHECKING([for long double support])
-    if test $ac_cv_sizeof_long_double = 0; then
-      AC_MSG_RESULT([not a supported type.])
-      AC_MSG_NOTICE([Disabling FFT support (--disable-fft-long-double).])
-      enable_fft_long_double=no 
-    elif test $ac_cv_sizeof_long_double = $ac_cv_sizeof_double; then
-      AC_MSG_RESULT([same size as double.])
-      AC_MSG_NOTICE([Disabling FFT support (--disable-fft-long-double).])
-      enable_fft_long_double=no 
-    else
-      AC_MSG_RESULT([supported.])
-      fftw_has_long_double=1
+    if test "$enable_fft_long_double" = yes; then
+      AC_MSG_CHECKING([for long double support])
+      if test $ac_cv_sizeof_long_double = 0; then
+        AC_MSG_RESULT([not a supported type.])
+        AC_MSG_NOTICE([Disabling FFT support (--disable-fft-long-double).])
+        enable_fft_long_double=no 
+      elif test $ac_cv_sizeof_long_double = $ac_cv_sizeof_double; then
+        AC_MSG_RESULT([same size as double.])
+        AC_MSG_NOTICE([Disabling FFT support (--disable-fft-long-double).])
+        enable_fft_long_double=no 
+      else
+        AC_MSG_RESULT([supported.])
+      fi
     fi
-    fftw_has_float=1
-    fftw_has_double=1
 
     # if $srcdir is relative, correct for chdir into vendor/fftw3*.
     fftw3_configure="`(cd $srcdir/vendor/fftw; echo \"$PWD\")`"/configure
@@ -341,6 +340,9 @@
 
 fi
 
+echo "fftw_has_float: $fftw_has_float"
+echo "fftw_has_double: $fftw_has_double"
+echo "fftw_has_long_double: $fftw_has_long_double"
 if test "x$provide_fft_float" = "x"
 then provide_fft_float=$fftw_has_float
 fi
@@ -352,13 +354,13 @@
 fi
 
 if test "$neutral_acconfig" = 'y'; then
-  if test $fftw_has_float = 1; then
+  if test "$fftw_has_float" = 1; then
     CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_FFTW3_HAVE_FLOAT"
   fi
-  if test $fftw_has_double = 1; then
+  if test "$fftw_has_double" = 1; then
     CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_FFTW3_HAVE_DOUBLE"
   fi
-  if test $fftw_has_long_double = 1; then
+  if test "$fftw_has_long_double" = 1; then
     CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE"
   fi
 else
