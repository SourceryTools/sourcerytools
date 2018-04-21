Index: m4/cvsip.m4
===================================================================
--- m4/cvsip.m4	(revision 191866)
+++ m4/cvsip.m4	(working copy)
@@ -13,7 +13,7 @@
 # Find the C-VSIPL library, if enabled.
 #
 
-if test "$enable_cvsip" != "no"; then
+if test "$with_cvsip" != "no"; then
   if test -n "$with_cvsip_prefix"; then
     CVSIP_CPPFLAGS="-I$with_cvsip_prefix/include"
     CVSIP_LDFLAGS="-L$with_cvsip_prefix/lib"
Index: m4/ipp.m4
===================================================================
--- m4/ipp.m4	(revision 191866)
+++ m4/ipp.m4	(working copy)
@@ -10,18 +10,18 @@
 AC_DEFUN([SVXX_CHECK_IPP],
 [
 # If the user specified an IPP prefix, they definitely want IPP.
-# However, we need to avoid overwriting the value of $enable_ipp
+# However, we need to avoid overwriting the value of $with_ipp
 # if the user set it (i.e. '--enable-ipp=win').
 
 if test -n "$with_ipp_prefix" -o -n "$with_ipp_suffix"; then
-  if test $enable_ipp != "win"; then
-    enable_ipp="yes"
+  if test $with_ipp != "win"; then
+    with_ipp="yes"
   fi
 fi
 
 
 if test "$enable_ipp_fft" == "yes"; then
-  if test "$enable_ipp" == "no"; then
+  if test "$with_ipp" == "no"; then
     AC_MSG_ERROR([IPP FFT requires IPP])
   fi 
 fi
@@ -30,7 +30,7 @@
 # Find the IPP library, if enabled.
 #
 
-if test "$enable_ipp" = "win"; then
+if test "$with_ipp" = "win"; then
   AC_MSG_RESULT([Using IPP for Windows.])
   if test -n "$with_ipp_prefix"; then
     IPP_CPPFLAGS="-I$with_ipp_prefix/include"
@@ -66,7 +66,7 @@
     fi
   fi
 
-elif test "$enable_ipp" != "no"; then
+elif test "$with_ipp" != "no"; then
 
   if test -n "$with_ipp_prefix"; then
     IPP_CPPFLAGS="-I$with_ipp_prefix/include"
@@ -79,7 +79,7 @@
   vsipl_ipps_h_name="not found"
   AC_CHECK_HEADER([ipps.h], [vsipl_ipps_h_name='<ipps.h>'],, [// no prerequisites])
   if test "$vsipl_ipps_h_name" == "not found"; then
-    if test "$enable_ipp" != "probe" -o "$enable_ipp_fft" == "yes"; then
+    if test "$with_ipp" != "probe" -o "$enable_ipp_fft" == "yes"; then
       AC_MSG_ERROR([IPP enabled, but no ipps.h detected])
     else
       CPPFLAGS="$save_CPPFLAGS"
Index: m4/lapack.m4
===================================================================
--- m4/lapack.m4	(revision 191866)
+++ m4/lapack.m4	(working copy)
@@ -20,6 +20,10 @@
             [CLAPACK_CFLAGS=$withval],
             [CLAPACK_CFLAGS=no])
 
+AC_ARG_ENABLE([lapack],,  
+  AC_MSG_ERROR([The option --enable-lapack is not supported; use 
+    --with-lapack instead.  (Run 'configure --help' for details)]),)
+
 AC_ARG_WITH([lapack],
   AS_HELP_STRING([--with-lapack\[=PKG\]],
                  [Select one or more LAPACK libraries to search for
@@ -81,10 +85,14 @@
                   must be in PATH/include; libraries in PATH/lib
 	          (Enables LAPACK).]))
 
-AC_ARG_ENABLE([cblas],
-  AS_HELP_STRING([--disable-cblas],
+AC_ARG_ENABLE([cblas],,  
+  AC_MSG_ERROR([The option --disable-cblas is not supported; use 
+    --without-cblas instead.  (Run 'configure --help' for details)]),)
+
+AC_ARG_WITH([cblas],
+  AS_HELP_STRING([--without-cblas],
                  [Disable C BLAS API (default is to use it if possible)]),,
-  [enable_cblas=yes])
+  [with_cblas=yes])
 
 AC_ARG_WITH([g2c-path],
   AS_HELP_STRING([--with-g2c-path=PATH],
@@ -199,7 +207,7 @@
 fi
 
 # Disable lapack if building ref-impl
-if test "$ref_impl" = "1"; then
+if test "$only_ref_impl" = "1"; then
   if test "$with_lapack" == "probe"; then
     with_lapack="no"
   fi
@@ -266,7 +274,7 @@
         # Can't cross-compile builtin atlas
         lapack_packages="atlas generic_wo_blas generic_with_blas generic_v3_wo_blas generic_v3_with_blas simple-builtin"
       else
-        lapack_packages="atlas generic_wo_blas generic_with_blas generic_v3_wo_blas generic_v3_with_blas builtin"
+        lapack_packages="atlas generic_wo_blas generic_with_blas generic_v3_wo_blas generic_v3_with_blas"
       fi
     ;;
     generic)
@@ -671,15 +679,15 @@
       [Define to set whether or not LAPACK is present.])
     AC_DEFINE_UNQUOTED(VSIP_IMPL_USE_LAPACK_ILAENV, $lapack_use_ilaenv,
       [Use LAPACK ILAENV (0 == do not use, 1 = use).])
-    if test $enable_cblas == "yes"; then
-      enable_cblas=$cblas_style
+    if test $with_cblas == "yes"; then
+      with_cblas=$cblas_style
     else
-      enable_cblas="0"
+      with_cblas="0"
     fi
     if test "$neutral_acconfig" = 'y'; then
-      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_USE_CBLAS=$enable_cblas"
+      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_USE_CBLAS=$with_cblas"
     else
-      AC_DEFINE_UNQUOTED(VSIP_IMPL_USE_CBLAS, $enable_cblas,
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_USE_CBLAS, $with_cblas,
         [CBLAS style (0 == no CBLAS, 1 = ATLAS CBLAS, 2 = MKL CBLAS).])
     fi
   fi
Index: m4/fft.m4
===================================================================
--- m4/fft.m4	(revision 191866)
+++ m4/fft.m4	(working copy)
@@ -66,7 +66,7 @@
   vsip_impl_fft_use_long_double=1
 fi
 
-if test "$ref_impl" = "1"; then
+if test "$only_ref_impl" = "1"; then
   enable_fft="cvsip"
 fi
 
@@ -93,8 +93,8 @@
       fftw3) enable_fftw3="yes";;
       builtin) enable_builtin_fft="yes";;
       cbe_sdk)
-        if test "enable_cbe_sdk" == "no" ; then
-          AC_MSG_ERROR([The cbe_sdk FFT backend requires --enable-cbe-sdk.])
+        if test "with_cbe_sdk" == "no" ; then
+          AC_MSG_ERROR([The cbe_sdk FFT backend requires --with-cbe-sdk.])
         fi
         AC_SUBST(VSIP_IMPL_CBE_SDK_FFT, 1)
         AC_DEFINE_UNQUOTED(VSIP_IMPL_CBE_SDK_FFT, 1,
Index: m4/sal.m4
===================================================================
--- m4/sal.m4	(revision 191866)
+++ m4/sal.m4	(working copy)
@@ -13,14 +13,14 @@
 # Find the Mercury SAL library, if enabled.
 #
 if test "$enable_sal_fft" == "yes"; then
-  if test "$enable_sal" == "no"; then
+  if test "$with_sal" == "no"; then
     AC_MSG_ERROR([SAL FFT requires SAL])
   else
-    enable_sal="yes"
+    with_sal="yes"
   fi 
 fi
 
-if test "$enable_sal" != "no"; then
+if test "$with_sal" != "no"; then
 
   if test -n "$with_sal_include"; then
     SAL_CPPFLAGS="-I$with_sal_include"
@@ -32,7 +32,7 @@
   vsipl_sal_h_name="not found"
   AC_CHECK_HEADER([sal.h], [vsipl_sal_h_name='<sal.h>'],, [// no prerequisites])
   if test "$vsipl_sal_h_name" == "not found"; then
-    if test "$enable_sal" = "yes"
+    if test "$with_sal" = "yes"
     then AC_MSG_ERROR([SAL enabled, but no sal.h detected])
     else CPPFLAGS="$save_CPPFLAGS"
     fi
Index: configure.ac
===================================================================
--- configure.ac	(revision 191866)
+++ configure.ac	(working copy)
@@ -89,15 +89,15 @@
 		  --with-obj-ext, no "." is implied.]),
   [exe_ext=$withval])
 
-AC_ARG_ENABLE([ref-impl],
-  AS_HELP_STRING([--enable-ref-impl],
+AC_ARG_ENABLE([only-ref-impl],
+  AS_HELP_STRING([--enable-only-ref-impl],
                  [Use reference implementation.]),
     [case x"$enableval" in
-       xyes) ref_impl=1 ;;
-       xno)  ref_impl=0 ;;
-       *)   AC_MSG_ERROR([Invalid argument to --enable-ref-impl.])
+       xyes) only_ref_impl=1 ;;
+       xno)  only_ref_impl=0 ;;
+       *)   AC_MSG_ERROR([Invalid argument to --enable-only-ref-impl.])
      esac],
-    [ref_impl=0]) 
+    [only_ref_impl=0]) 
 
 # VSIP_IMPL_REF_IMPL is defined to 1 when building the reference
 # implementation.  The reference implementation uses only the core
@@ -111,7 +111,7 @@
 # vsip_csl library.  The vsip_csl library is not built with the
 # reference implementation.
 
-if test "$ref_impl" = "1"; then
+if test "$only_ref_impl" = "1"; then
   AC_DEFINE_UNQUOTED(VSIP_IMPL_REF_IMPL, 1,
         [Set to 1 to compile the reference implementation.])
   AC_SUBST(VSIP_IMPL_REF_IMPL, 1)
@@ -126,26 +126,34 @@
   [enable_exceptions=probe])
 
 ### Mercury Scientific Algorithm (SAL)
-AC_ARG_ENABLE([sal],
-  AS_HELP_STRING([--enable-sal],
+AC_ARG_ENABLE([sal],,  
+  AC_MSG_ERROR([The option --enable-sal is not supported; use 
+    --with-sal instead.  (Run 'configure --help' for details)]),)
+
+AC_ARG_WITH([sal],
+  AS_HELP_STRING([--with-sal],
                  [Use SAL if found (default is to not search for it).]),,
-  [enable_sal=no])
+  [with_sal=no])
 AC_ARG_WITH(sal_include,
   AS_HELP_STRING([--with-sal-include=PATH],
                  [Specify the path to the SAL include directory.]),
   dnl If the user specified --with-sal-include, they mean to use SAL for sure.
-  [enable_sal=yes])
+  [with_sal=yes])
 AC_ARG_WITH(sal_lib,
   AS_HELP_STRING([--with-sal-lib=PATH],
                  [Specify the installation path of the SAL library.]),
   dnl If the user specified --with-sal-lib, they mean to use SAL for sure.
-  [enable_sal=yes])
+  [with_sal=yes])
 
 ### Intel Performance Primitives (IPP)
-AC_ARG_ENABLE([ipp],
-  AS_HELP_STRING([--enable-ipp],
+AC_ARG_ENABLE([ipp],,  
+  AC_MSG_ERROR([The option --enable-ipp is not supported; use 
+    --with-ipp instead.  (Run 'configure --help' for details)]),)
+
+AC_ARG_WITH([ipp],
+  AS_HELP_STRING([--with-ipp],
                  [Use IPP if found (default is to not search for it).]),,
-  [enable_ipp=no])
+  [with_ipp=no])
 AC_ARG_WITH(ipp_prefix,
   AS_HELP_STRING([--with-ipp-prefix=PATH],
                  [Specify the installation prefix of the IPP library.  Headers
@@ -159,15 +167,20 @@
   )
 
 ### Cell Broadband Engine
-AC_ARG_ENABLE([cbe_sdk],
-  AS_HELP_STRING([--enable-cbe-sdk],
+AC_ARG_ENABLE([cbe_sdk],,  
+  AC_MSG_ERROR([The option --enable-cbe-sdk is not supported; use 
+    --with-cbe-sdk instead.  (Run 'configure --help' for details)]),)
+
+AC_ARG_WITH([cbe_sdk],
+  AS_HELP_STRING([--with-cbe-sdk],
                  [Use CBE SDK.]),,
-  [enable_cbe_sdk="no"])
+  [with_cbe_sdk="no"])
 AC_ARG_WITH(cbe_sdk_sysroot,
   AS_HELP_STRING([--with-cbe-sdk-sysroot=PATH],
                  [Specify the installation sysroot of the CBE SDK.]),
-  [enable_cbe_sdk="yes"],
-  [with_cbe_sdk_sysroot="no"])
+  [if test "$with_cbe_sdk" == "no"; then
+     with_cbe_sdk="yes"
+   fi],  [with_cbe_sdk_sysroot="no"])
 AC_ARG_ENABLE(cbe_sdk_embedded_images,
   AS_HELP_STRING([--enable-cbe-sdk-embedded-images],
                  [Specify whether or not to embed SPE images into the application.]),,
@@ -178,14 +191,14 @@
   [],
   [with_cbe_default_num_spes=8])
 
-if test "$enable_cbe_sdk" != "no"; then
+if test "$with_cbe_sdk" != "no"; then
   AC_DEFINE_UNQUOTED(VSIP_IMPL_CBE_SDK, 1,
         [Set to 1 to support Cell Broadband Engine.])
   AC_DEFINE_UNQUOTED(VSIP_IMPL_CBE_NUM_SPES, $with_cbe_default_num_spes,
         [Define default number of SPEs.])
   AC_SUBST(VSIP_IMPL_HAVE_CBE_SDK, 1)
 
-  if test "$enable_cbe_sdk" == "2.1"; then
+  if test "$with_cbe_sdk" == "2.1"; then
     cbe_sdk_version=210
     if test "$with_cbe_sdk_sysroot" == "no"; then
       with_cbe_sdk_sysroot="/opt/ibm/cell-sdk/prototype/sysroot"
@@ -230,10 +243,14 @@
 fi
 
 ### C-VSIPL
-AC_ARG_ENABLE([cvsip],
-  AS_HELP_STRING([--enable-cvsip],
+AC_ARG_ENABLE([cvsip],,  
+  AC_MSG_ERROR([The option --enable-cvsip is not supported; use 
+    --with-cvsip instead.  (Run 'configure --help' for details)]),)
+
+AC_ARG_WITH([cvsip],
+  AS_HELP_STRING([--with-cvsip],
                  [Use C-VSIPL (default is to not use it).]),,
-  [enable_cvsip=no])
+  [with_cvsip=no])
 
 AC_ARG_WITH(cvsip_prefix,
   AS_HELP_STRING([--with-cvsip-prefix=PATH],
@@ -372,7 +389,7 @@
 #
 # Find the compiler.
 #
-if test "$enable_cbe_sdk" != "no"; then
+if test "$with_cbe_sdk" != "no"; then
   if test "`echo $CXXFLAGS | sed -n '/-maltivec/p'`" == ""; then
     CXXFLAGS="-maltivec $CXXFLAGS"
     CFLAGS="-maltivec $CFLAGS"
@@ -432,11 +449,15 @@
 ### Enable NUMA support
 # This must go after finding the compiler, due to the use of
 # AC_CHECK_HEADERS
-AC_ARG_ENABLE([numa],
-  AS_HELP_STRING([--enable-numa], [Enable support for libnuma]),,
-  [enable_numa="no"])
+AC_ARG_ENABLE([numa],,  
+  AC_MSG_ERROR([The option --enable-numa is not supported; use 
+    --with-numa instead.  (Run 'configure --help' for details)]),)
+
+AC_ARG_WITH([numa],
+  AS_HELP_STRING([--with-numa], [Enable support for libnuma]),,
+  [with_numa="no"])
 AC_CHECK_HEADERS([numa.h], [ have_numa_h="yes"], [], [])
-if test "$enable_numa" != "no" -a "$have_numa_h" == "yes"; then
+if test "$with_numa" != "no" -a "$have_numa_h" == "yes"; then
   AC_DEFINE_UNQUOTED(VSIP_IMPL_NUMA, 1, [Set to 1 to support libnuma.])
   AC_SUBST(VSIP_IMPL_HAVE_NUMA, 1)
   LIBS="$LIBS -lnuma"
@@ -485,7 +506,7 @@
 # Set ar
 #
 if test "x$AR" == "x"; then
-  if test "$enable_cbe_sdk" != "no"; then
+  if test "$with_cbe_sdk" != "no"; then
     AR="ppu-ar"
   else
     AR="ar"
@@ -726,11 +747,11 @@
 SVXX_CHECK_SAL
 SVXX_CHECK_IPP
 
-if test "$ref_impl" = "1" -o "x$with_cvsip_prefix" != x; then
-  enable_cvsip="yes"
+if test "$only_ref_impl" = "1" -o "x$with_cvsip_prefix" != x; then
+  with_cvsip="yes"
 fi
-if test "$enable_cvsip_fft" == "yes"; then
-  if test "$enable_cvsip" == "no"; then
+if test "$with_cvsip_fft" == "yes"; then
+  if test "$with_cvsip" == "no"; then
     AC_MSG_ERROR([C-VSIPL FFT requires C-VSIPL])
   fi 
 fi
@@ -1004,9 +1025,9 @@
 AC_MSG_RESULT([Exceptions enabled:                      $status_exceptions])
 AC_MSG_RESULT([With parallel service enabled:           $par_service])
 AC_MSG_RESULT([With LAPACK:                             $lapack_found])
-AC_MSG_RESULT([With SAL:                                $enable_sal])
-AC_MSG_RESULT([With IPP:                                $enable_ipp])
-AC_MSG_RESULT([With C-VSIPL:                            $enable_cvsip])
+AC_MSG_RESULT([With SAL:                                $with_sal])
+AC_MSG_RESULT([With IPP:                                $with_ipp])
+AC_MSG_RESULT([With C-VSIPL:                            $with_cvsip])
 AC_MSG_RESULT([Using FFT backends:                      ${enable_fft}])
 if test "$provide_fft_float" == "1"; then
   AC_MSG_RESULT([  Provides float FFTs])
@@ -1067,7 +1088,7 @@
 fix_pc="`(cd $srcdir/scripts; echo \"$PWD\")`"/fix-pkg-config-prefix.sh
 
 # Tidy up IPP
-if test "$enable_ipp" == "yes" -a "$with_ipp_prefix" != ""; then
+if test "$with_ipp" == "yes" -a "$with_ipp_prefix" != ""; then
   $fix_pc -p vsipl++.pc -d -k ipp_prefix -v $with_ipp_prefix
 fi
 
Index: doc/quickstart/quickstart.xml
===================================================================
--- doc/quickstart/quickstart.xml	(revision 191866)
+++ doc/quickstart/quickstart.xml	(working copy)
@@ -706,7 +706,7 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--disable-mpi</option></term>
+      <term><option>--disable-parallel</option></term>
       <listitem>
        <para>
 	Do not use MPI, even if an appropriate MPI library is
@@ -770,7 +770,7 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--enable-ipp</option></term>
+      <term><option>--with-ipp</option></term>
       <listitem>
        <para>
         Enable the use of the Intel Performance Primitives (IPP)
@@ -781,7 +781,7 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--enable-ipp=win</option></term>
+      <term><option>--with-ipp=win</option></term>
       <listitem>
        <para>
         Enable the use of the Intel Performance Primitives (IPP)
@@ -801,7 +801,7 @@
 	<replaceable>directory</replaceable> and IPP libraries should
 	be in the <filename>lib</filename> subdirectory.  This option
 	has the effect of enabling IPP
-	(i.e. <option>--enable-ipp</option>).  This option is useful
+	(i.e. <option>--with-ipp</option>).  This option is useful
 	if IPP is installed in a non-standard location, or if multiple
 	IPP versions are installed.
        </para>
@@ -825,7 +825,7 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--enable-sal</option></term>
+      <term><option>--with-sal</option></term>
       <listitem>
        <para>
         Enable the use of the Mercury Scientific Algorithm Library (SAL)
@@ -842,7 +842,7 @@
        <para>
         Search for SAL header files in <replaceable>directory</replaceable>
         first.  This option has the effect of enabling SAL
-	(i.e. <option>--enable-sal</option>).  This option is useful
+	(i.e. <option>--with-sal</option>).  This option is useful
 	if SAL headers is installed in a non-standard location, such
         as when using the CSAL library.  However, it should not be
         necessary when building native on Mercury system.
@@ -856,7 +856,7 @@
        <para>
         Search for SAL library files in <replaceable>directory</replaceable>
         first.  This option has the effect of enabling SAL
-	(i.e. <option>--enable-sal</option>).  This option is useful
+	(i.e. <option>--with-sal</option>).  This option is useful
 	if SAL libraries is installed in a non-standard location, such
         as when using the CSAL library.  However, it should not be
         necessary when building native on Mercury system.
@@ -1093,7 +1093,7 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--disable-cblas</option></term>
+      <term><option>--without-cblas</option></term>
       <listitem>
        <para>
         Disables the use of the C BLAS API, forcing the use of the
@@ -1104,14 +1104,14 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--enable-cbe-sdk</option></term>
+      <term><option>--with-cbe-sdk</option></term>
       <listitem>
        <para>
         Enable the use of the IBM Cell/B.E. Software Development Kit
         (SDK) if found.  Enabling the Cell/B.E. SDK will accelerate the
         performance of FFTs, vector-multiplication, vector-matrix
 	multiplication, and fast convolution.  Version 3.0 of the SDK
-	is assumed; the <option>--enable-cbe-sdk=2.1</option> form of
+	is assumed; the <option>--with-cbe-sdk=2.1</option> form of
 	the option can be used for compatibility with version 2.1
 	instead.
        </para>
@@ -1126,7 +1126,7 @@
 	<replaceable>directory</replaceable>, rather than in the system
 	root directory (or the default sysroot location, in the case of
 	SDK version 2.1).  This option has the effect of enabling use of
-	the Cell/B.E. SDK (i.e.	<option>--enable-cbe-sdk</option>).
+	the Cell/B.E. SDK (i.e.	<option>--with-cbe-sdk</option>).
 	This option is used for cross-compilation.
        </para>
       </listitem>
@@ -1144,7 +1144,7 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--enable-numa</option></term>
+      <term><option>--with-numa</option></term>
       <listitem>
        <para>
         Enable the use of libnuma.  This is useful on Cell/B.E. systems
@@ -1155,7 +1155,7 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--enable-cvsip</option></term>
+      <term><option>--with-cvsip</option></term>
       <listitem>
        <para>
         Enable Sourcery VSIPL++ to search for an appropriate C VSIPL
@@ -1179,7 +1179,7 @@
 	<replaceable>directory</replaceable> and libraries should be
 	in the <filename>lib</filename> subdirectory.  This option has
 	the effect of enabling the use of a VSIPL back end as if the
-	option <option>--enable-cvsip</option> had been given.  This
+	option <option>--with-cvsip</option> had been given.  This
 	option is useful if VSIPL is installed in a non-standard
 	location, or if multiple VSIPL versions are installed.
        </para>
@@ -1187,7 +1187,7 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--enable-ref-impl</option></term>
+      <term><option>--enable-only-ref-impl</option></term>
       <listitem>
        <para>
         Configure Sourcery VSIPL++ to be used as the VSIPL++ reference
@@ -1195,7 +1195,7 @@
         with this option, the result is the VSIPL++ reference
         implementation.  This option implies the
         <option>--enable-fft=cvsip</option> and
-        <option>--enable-cvsip</option> options. Refer to
+        <option>--with-cvsip</option> options. Refer to
         <xref linkend="cfg-ref-impl"/> for
         more information on configuring the reference implementation.
        </para>
@@ -1554,7 +1554,7 @@
       </listitem>
 
       <listitem>
-       <para><option>--enable-sal</option></para>
+       <para><option>--with-sal</option></para>
        <para>
         Enable the SAL library.
        </para>
@@ -1720,7 +1720,7 @@
       </listitem>
 
       <listitem>
-       <para><option>--enable-ipp=win</option></para>
+       <para><option>--with-ipp=win</option></para>
        <para>
         Enable the IPP library for Windows.
 	
@@ -1776,7 +1776,7 @@
      <itemizedlist>
 
       <listitem>
-       <para><option>--enable-cbe-sdk</option></para>
+       <para><option>--with-cbe-sdk</option></para>
        <para>
         Enable use of the Cell/B.E. SDK.  This is necessary to use the
         Cell/B.E.'s SPE processors to accelerate VSIPL++ functionaity.
@@ -1787,7 +1787,7 @@
       </listitem>
 
       <listitem>
-       <para><option>--enable-numa</option></para>
+       <para><option>--with-numa</option></para>
        <para>
         Enable use of libnuma for SPE/PPE affinity control.  This
 	may improve program performance by allocating SPEs close to
@@ -1827,7 +1827,7 @@
      <itemizedlist>
 
       <listitem>
-       <para><option>--enable-ref-impl</option></para>
+       <para><option>--enable-only-ref-impl</option></para>
        <para>
         Build only the reference-implementation subset of Sourcery
         VSIPL++.  If you do not use this option, the complete,
