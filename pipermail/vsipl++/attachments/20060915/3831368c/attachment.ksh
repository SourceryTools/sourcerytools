Index: ChangeLog
===================================================================
--- ChangeLog	(revision 149247)
+++ ChangeLog	(working copy)
@@ -1,3 +1,11 @@
+2006-09-15  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (--enable-ipp=win): New option to configure for
+	  IPP on windows.
+	  (--with-lapack=mkl_win): New option to configure for MKL on
+	  windows.
+	* benchmarks/main.cpp: Avoid calling getpid() on windows.
+	
 2006-09-14  Jules Bergmann  <jules@codesourcery.com>
 
 	* tests/regressions/transpose_assign.cpp: New file, regression
Index: configure.ac
===================================================================
--- configure.ac	(revision 149246)
+++ configure.ac	(working copy)
@@ -132,15 +132,13 @@
   AS_HELP_STRING([--with-ipp-prefix=PATH],
                  [Specify the installation prefix of the IPP library.  Headers
                   must be in PATH/include; libraries in PATH/lib.]),
-  dnl If the user specified --with-ipp-prefix, they mean to use IPP for sure.
-  [enable_ipp=yes])
+  )
 AC_ARG_WITH(ipp_suffix,
   AS_HELP_STRING([--with-ipp-suffix=TARGET],
                  [Specify the optimization target of IPP libraries, such as
 		  a6, em64t, i7, m7, mx, px, t7, w7.  E.g. a6 => -lippsa6.
                   TARGET may be the empty string.]),
-  dnl If the user specified --with-ipp-suffix, they mean to use IPP for sure.
-  [enable_ipp=yes])
+  )
 
 AC_ARG_ENABLE(fft,
   AS_HELP_STRING([--enable-fft],
@@ -1118,25 +1116,74 @@
 
 fi
 
+# If the user specified an IPP prefix, they definitely want IPP.
+# However, we need to avoid overwriting the value of $enable_ipp
+# if the user set it (i.e. '--enable-ipp=win').
 
-#
-# Find the IPP library, if enabled.
-#
+if test -n "$with_ipp_prefix" -o -n "$with_ipp_suffix"; then
+  if test $enable_ipp != "win"; then
+    enable_ipp="yes"
+  fi
+fi
 
+
 if test "$enable_ipp_fft" == "yes"; then
   if test "$enable_ipp" == "no"; then
     AC_MSG_ERROR([IPP FFT requires IPP])
-  else
-    enable_ipp="yes"
   fi 
 fi
 
-if test "$enable_ipp" != "no"; then
+#
+# Find the IPP library, if enabled.
+#
 
+if test "$enable_ipp" = "win"; then
+  AC_MSG_RESULT([Using IPP for Windows.])
   if test -n "$with_ipp_prefix"; then
     IPP_CPPFLAGS="-I$with_ipp_prefix/include"
     IPP_LDFLAGS="-L$with_ipp_prefix/sharedlib"
   fi
+
+  # Check for headers ipps.h.
+  vsipl_ipps_h_name="not found"
+  AC_CHECK_HEADER([ipps.h], [vsipl_ipps_h_name='<ipps.h>'],, [// no prerequisites])
+  if test "$vsipl_ipps_h_name" == "not found"; then
+    AC_MSG_ERROR([IPP for windows enabled, but no ipps.h detected])
+  fi
+
+  LIBS="$LIBS ipps.lib ippi.lib ippm.lib"
+
+  AC_MSG_CHECKING([for ippsMul_32f])
+  AC_LINK_IFELSE(
+    [AC_LANG_PROGRAM([[#include <ipps.h>]],
+		     [[Ipp32f const* A, B; Ipp32f* Z; int len;
+                       ippsMul_32f(A, B, Z, len);]])],
+    [AC_MSG_RESULT(yes)],
+    [AC_MSG_ERROR(not found.)] )
+
+  if test "$enable_ipp_fft" != "no"; then 
+    AC_SUBST(VSIP_IMPL_IPP_FFT, 1)
+    if test "$neutral_acconfig" = 'y'; then
+      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_IPP_FFT=1"
+    else
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_IPP_FFT, 1,
+	      [Define to use Intel's IPP library to perform FFTs.])
+    fi
+
+    if test "$enable_fft_float" = yes; then
+	vsip_impl_fft_use_float=$vsip_impl_use_float
+    fi
+    if test "$enable_fft_double" = yes; then
+	vsip_impl_fft_use_double=$vsip_impl_use_double
+    fi
+  fi
+
+elif test "$enable_ipp" != "no"; then
+
+  if test -n "$with_ipp_prefix"; then
+    IPP_CPPFLAGS="-I$with_ipp_prefix/include"
+    IPP_LDFLAGS="-L$with_ipp_prefix/sharedlib"
+  fi
   save_CPPFLAGS="$CPPFLAGS"
   CPPFLAGS="$CPPFLAGS $IPP_CPPFLAGS"
 
@@ -1149,7 +1196,6 @@
     else
       CPPFLAGS="$save_CPPFLAGS"
     fi
-
   else
 
     if test "${with_ipp_suffix-unset}" == "unset"; then
@@ -1200,9 +1246,9 @@
   value = static_assert<sizeof(Ipp32fc) == 2*sizeof(float)>::value;
   value = static_assert<sizeof(Ipp64fc) == 2*sizeof(double)>::value;
 }
-],
-[AC_MSG_RESULT(yes)],
-[AC_MSG_ERROR([std::complex-incompatible IPP-types detected!])])
+      ],
+      [AC_MSG_RESULT(yes)],
+      [AC_MSG_ERROR([std::complex-incompatible IPP-types detected!])])
 
     save_LDFLAGS="$LDFLAGS"
     LDFLAGS="$LDFLAGS $IPP_FFT_LDFLAGS"
@@ -1430,6 +1476,30 @@
       cblas_style="2"	# use mkl_cblas.h
 
       lapack_use_ilaenv=0
+    elif test "$trypkg" == "mkl_win"; then
+      AC_MSG_CHECKING([for LAPACK/MKL 8.x library for Windows])
+
+      if test "x$with_mkl_prefix" != x; then
+        CPPFLAGS="$keep_CPPFLAGS -I$with_mkl_prefix/include"
+        LDFLAGS="$keep_LDFLAGS -L$with_mkl_prefix/$with_mkl_arch/lib"
+      fi
+      LIBS="$keep_LIBS mkl_lapack.lib mkl_c.lib libguide.lib"
+      cblas_style="2"	# use mkl_cblas.h
+
+      lapack_use_ilaenv=0
+    elif test "$trypkg" == "mkl_win_nocheck"; then
+      AC_MSG_RESULT([Using LAPACK/MKL 8.x library for Windows (without check)])
+
+      if test "x$with_mkl_prefix" != x; then
+        CPPFLAGS="$keep_CPPFLAGS -I$with_mkl_prefix/include"
+        LDFLAGS="$keep_LDFLAGS -L$with_mkl_prefix/$with_mkl_arch/lib"
+      fi
+      LIBS="$keep_LIBS mkl_lapack.lib mkl_c.lib -lguide "
+      cblas_style="2"	# use mkl_cblas.h
+
+      lapack_use_ilaenv=0
+      lapack_found="mkl_nocheck"
+      break
     elif test "$trypkg" == "acml"; then
       AC_MSG_CHECKING([for LAPACK/ACML library])
 
Index: benchmarks/main.cpp
===================================================================
--- benchmarks/main.cpp	(revision 149244)
+++ benchmarks/main.cpp	(working copy)
@@ -128,11 +128,15 @@
   {
     // Enable this section for easier debugging.
     impl::Communicator& comm = impl::default_communicator();
+#if !_WIN32
     pid_t pid = getpid();
+#endif
 
     std::cout << "rank: "   << comm.rank()
 	      << "  size: " << comm.size()
+#if !_WIN32
 	      << "  pid: "  << pid
+#endif
 	      << std::endl;
 
     // Stop each process, allow debugger to be attached.
