Index: m4/fft.m4
===================================================================
--- m4/fft.m4	(revision 212863)
+++ m4/fft.m4	(working copy)
@@ -362,12 +362,18 @@
     CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE"
   fi
 else
-  AC_DEFINE_UNQUOTED(VSIP_IMPL_FFTW3_HAVE_FLOAT, $fftw_has_float,
-     [Define to 1 if -lfftw3f was found.])
-  AC_DEFINE_UNQUOTED(VSIP_IMPL_FFTW3_HAVE_DOUBLE, $fftw_has_double, 
-    [Define to 1 if -lfftw3d was found.])
-  AC_DEFINE_UNQUOTED(VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE, $fftw_has_long_double,
-     [Define to 1 if -lfftw3l was found.])
+  if test "$fftw_has_float" = 1; then
+    AC_DEFINE_UNQUOTED(VSIP_IMPL_FFTW3_HAVE_FLOAT, $fftw_has_float,
+      [Define to 1 if -lfftw3f was found.])
+  fi
+  if test "$fftw_has_double" = 1; then
+    AC_DEFINE_UNQUOTED(VSIP_IMPL_FFTW3_HAVE_DOUBLE, $fftw_has_double, 
+      [Define to 1 if -lfftw3d was found.])
+  fi
+  if test "$fftw_has_long_double" = 1; then
+    AC_DEFINE_UNQUOTED(VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE, $fftw_has_long_double,
+      [Define to 1 if -lfftw3l was found.])
+  fi
 fi
 
 ])
