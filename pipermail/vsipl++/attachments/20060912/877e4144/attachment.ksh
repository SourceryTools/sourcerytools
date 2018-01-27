Index: ChangeLog
===================================================================
--- ChangeLog	(revision 149048)
+++ ChangeLog	(working copy)
@@ -1,3 +1,24 @@
+2006-09-12  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/config.hpp: Remove unused macros for SIZEOF_DOUBLE
+	  and SIZEOF_LONG_DOUBLE.  SIZEOF_LONG_DOUBLE differs between
+	  ia32 and em64t/amd64.
+	* scripts/package.py: Updates for merged packages: use libdir instead
+	  of suffixes to distinguish variants.
+	* scripts/config: Updates for merged packages, defines new
+	  Mondo package that contains all linux variants.
+	* scripts/release.sh: Remove -no-maintainer-mode option when
+	  building source.  This was accidentally commited.
+	* vsipl++.pc.in: Include vsip_csl library.
+	* vendor/GNUmakefile.inc.in: Add rules to clean atlas.
+	* tests/context.in: Use CPPFLAGS_NOQUOTES instead of CPPFLAGS.
+	  Include vsip_csl library.
+	* tests/fft.cpp: Add verbose macro to make failures easier to debug.
+	* tests/GNUmakefile.inc.in (installcheck): Pass libdir variable to
+	  pkg-config.  Remove quotes from CPPFLAGS.
+	* configure.ac: Move macros for parallel services, FFT, and ATLAS
+	  from acconfig.hpp to command line.
+	
 2006-09-12  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* configure.ac: Remove AC_CONFIG_MACRO_DIR and increment version string.
Index: configure.ac
===================================================================
--- configure.ac	(revision 149048)
+++ configure.ac	(working copy)
@@ -14,6 +14,8 @@
 AC_REVISION($Revision: 1.110 $)
 AC_INIT(Sourcery VSIPL++, 1.2, vsipl++@codesourcery.com, sourceryvsipl++)
 
+neutral_acconfig="y"
+
 ######################################################################
 # Configure command line arguments.
 ######################################################################
@@ -603,7 +605,11 @@
   fi
   if test "$enable_fftw3" != "no" -o "$enable_builtin_fft" != "no" ; then
     AC_SUBST(VSIP_IMPL_FFTW3, 1)
-    AC_DEFINE_UNQUOTED(VSIP_IMPL_FFTW3, 1, [Define to build using FFTW3 headers.])
+    if test "$neutral_acconfig" = 'y'; then
+      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_FFTW3=1"
+    else
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_FFTW3, 1, [Define to build using FFTW3 headers.])
+    fi
   fi
 fi
 
@@ -618,22 +624,19 @@
   libs=
   syms=
   if test "$enable_fft_float" = yes ; then
-    AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_FLOAT, 1,
-      [Define to build code for float-precision FFT.])
-      libs="$libs -lfftw3f"
-      syms="$syms const char* fftwf_version;"
+    vsip_impl_fft_use_float=1
+    libs="$libs -lfftw3f"
+    syms="$syms const char* fftwf_version;"
   fi
   if test "$enable_fft_double" = yes ; then
-    AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_DOUBLE, 1,
-      [Define to build code for double-precision FFT.])
-      libs="$libs -lfftw3"
-      syms="$syms const char* fftw_version;"
+    vsip_impl_fft_use_double=1
+    libs="$libs -lfftw3"
+    syms="$syms const char* fftw_version;"
   fi
   if test "$enable_fft_long_double" = yes; then
-    AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_LONG_DOUBLE, 1,
-      [Define to build code for long-double-precision FFT.])
-      libs="$libs -lfftw3l"
-      syms="$syms const char* fftwl_version;"
+    vsip_impl_fft_use_long_double=1
+    libs="$libs -lfftw3l"
+    syms="$syms const char* fftwl_version;"
   fi
 
   if test -n "$with_fftw3_prefix"; then
@@ -762,18 +765,15 @@
     # these don't refer to anything yet.
     if test "$enable_fft_float" = yes; then
       AC_SUBST(USE_BUILTIN_FFTW_FLOAT, 1)
-      AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_FLOAT, 1,
-        [Define to build code for float-precision FFT.])
+      vsip_impl_fft_use_float=1
     fi
     if test "$enable_fft_double" = yes; then
       AC_SUBST(USE_BUILTIN_FFTW_DOUBLE, 1)
-      AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_DOUBLE, 1,
-        [Define to build code for double-precision FFT.])
+      vsip_impl_fft_use_double=1
     fi
     if test "$enable_fft_long_double" = yes; then
       AC_SUBST(USE_BUILTIN_FFTW_LONG_DOUBLE, 1)
-      AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_LONG_DOUBLE, 1,
-        [Define to build code for long-double-precision FFT.])
+      vsip_impl_fft_use_long_double=1
     fi
     mkdir -p src
     cp $srcdir/vendor/fftw/api/fftw3.h src/fftw3.h
@@ -869,19 +869,24 @@
       CPPFLAGS="$save_CPPFLAGS"
     fi
   else
-    AC_DEFINE_UNQUOTED([VSIP_IMPL_MPI_H], $vsipl_mpi_h_name,
-    [The name of the header to include for the MPI interface, with <> quotes.])
+    if test "$neutral_acconfig" = 'y'; then
+      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_MPI_H=\"$vsipl_mpi_h_name\""
+    else
+      AC_DEFINE_UNQUOTED([VSIP_IMPL_MPI_H], $vsipl_mpi_h_name,
+      [The name of the header to include for the MPI interface, with <>
+       quotes.])
+    fi
 
     # Find the library.
     PAR_SERVICE=unknown
     # Both MPICH 1 and 2 define MPICH_NAME.
     AC_CHECK_DECL([MPICH_NAME], [PAR_SERVICE=mpich],,
-                  [#include VSIP_IMPL_MPI_H])
+                  [#include $vsipl_mpi_h_name])
 
     # LAM/MPI defines LAM_MPI
     if test $PAR_SERVICE = unknown; then
       AC_CHECK_DECL([LAM_MPI], [PAR_SERVICE=lam],,
-      	   	    [#include VSIP_IMPL_MPI_H])
+      	   	    [#include $vsipl_mpi_h_name])
     fi
 
     # MPI/Pro does not have any identifying macros.
@@ -968,7 +973,7 @@
     save_LIBS="$LIBS"
     LIBS="$LIBS $MPI_LIBS"
     AC_LINK_IFELSE(
-     [AC_LANG_PROGRAM([[#include VSIP_IMPL_MPI_H]],
+     [AC_LANG_PROGRAM([[#include $vsipl_mpi_h_name]],
 	              [[MPI_Init(0, 0);]])],
      [],
      [AC_MSG_ERROR([Unable to compile / link test MPI application.])])
@@ -976,9 +981,13 @@
     AC_MSG_RESULT(found)
 
     if test -n "$vsip_impl_avoid_posix_memalign"; then
-      AC_DEFINE_UNQUOTED(VSIP_IMPL_AVOID_POSIX_MEMALIGN, 1,
-        [Set to 1 to avoid using posix_memalign (LAM defines its own malloc,
-         including memalign but not posix_memalign).])
+      if test "$neutral_acconfig" = 'y'; then
+        CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_AVOID_POSIX_MEMALIGN=1"
+      else
+        AC_DEFINE_UNQUOTED(VSIP_IMPL_AVOID_POSIX_MEMALIGN, 1,
+          [Set to 1 to avoid using posix_memalign (LAM defines its own malloc,
+           including memalign but not posix_memalign).])
+      fi
       AC_MSG_NOTICE(
         [Avoiding posix_memalign, may not be compatible with LAM-MPI malloc])
     fi
@@ -995,8 +1004,12 @@
   AC_SUBST(USE_PAR, 1)
 fi
 
-AC_DEFINE_UNQUOTED(VSIP_IMPL_PAR_SERVICE, $vsipl_par_service,
-  [Define to parallel service provided (0 == no service, 1 = MPI, 2 = PAS).])
+if test "$neutral_acconfig" = 'y'; then
+  CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_PAR_SERVICE=$vsipl_par_service"
+else
+  AC_DEFINE_UNQUOTED(VSIP_IMPL_PAR_SERVICE, $vsipl_par_service,
+    [Define to parallel service provided (0 == no service, 1 = MPI, 2 = PAS).])
+fi
 
 #
 # Find the Mercury SAL library, if enabled.
@@ -1067,20 +1080,26 @@
     LDFLAGS=$save_LDFLAGS
   else
     AC_SUBST(VSIP_IMPL_HAVE_SAL, 1)
-    AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SAL, 1,
-      [Define to set whether or not to use Mercury's SAL library.])
+    if test "$neutral_acconfig" = 'y'; then
+      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_HAVE_SAL=1"
+    else
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SAL, 1,
+        [Define to set whether or not to use Mercury's SAL library.])
+    fi
 
     if test "$enable_sal_fft" != "no"; then 
       AC_SUBST(VSIP_IMPL_SAL_FFT, 1)
-      AC_DEFINE_UNQUOTED(VSIP_IMPL_SAL_FFT, 1,
+      if test "$neutral_acconfig" = 'y'; then
+        CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_SAL_FFT=1"
+      else
+        AC_DEFINE_UNQUOTED(VSIP_IMPL_SAL_FFT, 1,
 	    [Define to use Mercury's SAL library to perform FFTs.])
+      fi
       if test "$enable_fft_float" = yes; then
-	AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_FLOAT, $vsip_impl_use_float,
-	      [Define to build code with support for FFT on float types.])
+	vsip_impl_fft_use_float=$vsip_impl_use_float
       fi
       if test "$enable_fft_double" = yes; then
-	AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_DOUBLE, $vsip_impl_use_double,
-	      [Define to build code with support for FFT on double types.])
+	vsip_impl_fft_use_double=$vsip_impl_use_double
       fi
     fi
 
@@ -1145,8 +1164,12 @@
     AC_SEARCH_LIBS(ippsMul_32f, [$ipps_search],
       [
         AC_SUBST(VSIP_IMPL_HAVE_IPP, 1)
-        AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_IPP, 1,
-          [Define to set whether or not to use Intel's IPP library.])
+        if test "$neutral_acconfig" = 'y'; then
+          CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_HAVE_IPP=1"
+        else
+          AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_IPP, 1,
+            [Define to set whether or not to use Intel's IPP library.])
+        fi
       ],
       [LD_FLAGS="$save_LDFLAGS"])
 
@@ -1187,20 +1210,49 @@
 
     if test "$enable_ipp_fft" != "no"; then 
       AC_SUBST(VSIP_IMPL_IPP_FFT, 1)
-      AC_DEFINE_UNQUOTED(VSIP_IMPL_IPP_FFT, 1,
-	    [Define to use Intel's IPP library to perform FFTs.])
+      if test "$neutral_acconfig" = 'y'; then
+        CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_IPP_FFT=1"
+      else
+        AC_DEFINE_UNQUOTED(VSIP_IMPL_IPP_FFT, 1,
+	      [Define to use Intel's IPP library to perform FFTs.])
+      fi
+
       if test "$enable_fft_float" = yes; then
-	AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_FLOAT, $vsip_impl_use_float,
-	      [Define to build code with support for FFT on float types.])
+	vsip_impl_fft_use_float=$vsip_impl_use_float
       fi
       if test "$enable_fft_double" = yes; then
-	AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_DOUBLE, $vsip_impl_use_double,
-	      [Define to build code with support for FFT on double types.])
+	vsip_impl_fft_use_double=$vsip_impl_use_double
       fi
     fi
   fi
 fi
 
+if test "$neutral_acconfig" = 'y'; then
+  if test "x$vsip_impl_fft_use_float" != "x"; then
+    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_FFT_USE_FLOAT=$vsip_impl_fft_use_float"
+  fi
+  if test "x$vsip_impl_fft_use_double" != "x"; then
+    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_FFT_USE_DOUBLE=$vsip_impl_fft_use_double"
+  fi
+  if test "x$vsip_impl_fft_use_long_double" != "x"; then
+    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_FFT_USE_LONG_DOUBLE=$vsip_impl_fft_use_long_double"
+  fi
+else
+  if test "x$vsip_impl_fft_use_float" != "x"; then
+    AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_FLOAT, $vsip_impl_fft_use_float,
+	      [Define to build code with support for FFT on float types.])
+  fi
+  if test "x$vsip_impl_fft_use_double" != "x"; then
+    AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_DOUBLE, $vsip_impl_fft_use_double,
+	      [Define to build code with support for FFT on double types.])
+  fi
+  if test "x$vsip_impl_fft_use_long_double" != "x"; then
+    AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_LONG_DOUBLE,
+	               $vsip_impl_fft_use_long_double,
+                       [Define to build code for long-double-precision FFT.])
+  fi
+fi
+
 #
 # Copy libg2c into libdir, if requested.
 #
@@ -1648,8 +1700,12 @@
     else
       enable_cblas="0"
     fi
-    AC_DEFINE_UNQUOTED(VSIP_IMPL_USE_CBLAS, $enable_cblas,
-      [CBLAS style (0 == no CBLAS, 1 = ATLAS CBLAS, 2 = MKL CBLAS).])
+    if test "$neutral_acconfig" = 'y'; then
+      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_USE_CBLAS=$enable_cblas"
+    else
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_USE_CBLAS, $enable_cblas,
+        [CBLAS style (0 == no CBLAS, 1 = ATLAS CBLAS, 2 = MKL CBLAS).])
+    fi
   fi
 fi
 
@@ -1856,6 +1912,9 @@
 AC_SUBST(INT_LDFLAGS)
 AC_SUBST(INT_CPPFLAGS)
 
+CPPFLAGS_NOQUOTES="`echo $CPPFLAGS | sed -e \"s|\\\"||g\"`"
+AC_SUBST(CPPFLAGS_NOQUOTES)
+
 #
 # Print summary.
 #
Index: src/vsip/impl/config.hpp
===================================================================
--- src/vsip/impl/config.hpp	(revision 149048)
+++ src/vsip/impl/config.hpp	(working copy)
@@ -35,8 +35,17 @@
 #undef PACKAGE_TARNAME
 #undef PACKAGE_VERSION
 
+// Remove macros that autoconf sometimes defines.
+#ifdef SIZEOF_DOUBLE
+#  undef SIZEOF_DOUBLE
+#endif
 
+#ifdef SIZEOF_LONG_DOUBLE
+#  undef SIZEOF_LONG_DOUBLE
+#endif
 
+
+
 /***********************************************************************
   Parallel Configuration
 ***********************************************************************/
Index: scripts/package.py
===================================================================
--- scripts/package.py	(revision 149048)
+++ scripts/package.py	(working copy)
@@ -49,7 +49,10 @@
     configs = {}
     for n, c in package.__dict__.iteritems():
         if type(c) is ClassType and issubclass(c, Configuration):
-            configs[c.suffix] = ' '.join(c.options)
+            configs[c.suffix] = {}
+            configs[c.suffix]['suffix']  = c.suffix
+            configs[c.suffix]['options'] = ' '.join(c.options)
+            configs[c.suffix]['libdir']  = c.libdir
 
     return package.suffix, package.host, configs
 
@@ -83,8 +86,8 @@
 def describe(**args):
 
     for s, c in parameters['config'].iteritems():
-        print 'prefix :', s
-        print 'options :', c
+        print 'suffix :', s
+        print 'options :', c['options']
 
 
 def checkout(**args):
@@ -152,27 +155,50 @@
     prefix = parameters['prefix']
     suffix = parameters['suffix']
     host = parameters['host']
+    pkgconfig_dir = '%s/%s/lib/pkgconfig/'%(abs_distdir,prefix)
     if not os.path.exists(srcdir):
         os.makedirs(srcdir)
         checkout()
     if not os.path.exists(builddir):
         os.makedirs(builddir)
+    # create a lib/pkgconfig director for .pc links.
+    if not os.path.exists(abs_distdir):
+        os.makedirs(abs_distdir)
+        os.makedirs(pkgconfig_dir)
     cwd = os.getcwd()
     try:
-        os.chdir(builddir)
-        if parameters['maintainer_mode']:
-            # Dummy configuration; just enough to build documentation.
-            configure('--enable-maintainer-mode', '--enable-fft=')
-            announce('build docs...')
-            spawn(['sh', '-c', 'make doc'])
-        # Now build all desired configurations
-        for s, c in parameters['config'].iteritems():
+        # Build all desired configurations
+        for s, x in parameters['config'].iteritems():
+            c      = x['options']
+            libdir = x['libdir']
+            # Make sure the builddir is empty to avoid accidently using
+            # any debris left behind there.
+            print 'Building suffix: %s in dir %s'%(s,builddir)
+            spawn(['sh', '-c', 'rm -rf %s'%builddir])
+            spawn(['sh', '-c', 'mkdir %s'%builddir])
+
+            os.chdir(builddir)
+            if parameters['maintainer_mode']:
+                # Dummy configuration; just enough to build documentation.
+                configure('--enable-maintainer-mode', '--enable-fft=')
+                announce('build docs...')
+                spawn(['sh', '-c', 'make doc'])
+
             announce('building %s...'%s)
-            configure('--prefix=%s'%prefix, '--with-suffix=%s'%s, c)
+            configure('--prefix=%s'%prefix,
+                      '--libdir=\${prefix}/lib/%s'%(libdir),
+                      c)
             spawn(['sh', '-c', 'make install DESTDIR=%s'%abs_distdir])
-            # Make sure all VSIPL++ code is recompiled
-            # with the actual compiler flags in the next iteration.
-            spawn(['sh', '-c', 'make mostlyclean'])
+
+            # Make copy of acconfig for later perusal.
+            spawn(['sh', '-c', 'cp %s/usr/local/include/vsip/impl/acconfig.hpp ../acconfig%s%s.hpp'%(abs_distdir,suffix,s)])
+
+            # Make symlink to variant' vsipl++.pc.
+            os.chdir(pkgconfig_dir)
+            spawn(['sh', '-c', 'ln -s ../%s/pkgconfig/vsipl++.pc vsipl++-%s.pc'%(libdir,s)])
+            os.chdir(cwd)
+
+        os.chdir(builddir)
         cmd = 'make bdist packagesuffix=%s DESTDIR=%s'%(suffix, abs_distdir)
         if host:
             cmd += ' host=%s'%host
@@ -196,7 +222,9 @@
     abs_builddir = parameters['abs_builddir']
     abs_distdir = parameters['abs_distdir']
     prefix = parameters['prefix']
+    host = parameters['host']
     if not os.path.exists(srcdir):
+        print 'srcdir does not exist: %s'%srcdir
         os.makedirs(srcdir)
         checkout()
     if not os.path.exists(abs_builddir):
@@ -215,9 +243,14 @@
         # since parameters['prefix'] may be absolute.
         prefix = abs_distdir + parameters['prefix']
         for s in parameters['config']: # keys are suffixes...
+            libdir      = parameters['config'][s]['libdir']
+            full_libdir = '%s/lib/%s'%(prefix,libdir)
             announce('testing suffix %s...'%s)
             spawn(['sh', '-c',
-                   'make installcheck prefix=%s suffix=%s'%(prefix, s)])
+                   'make installcheck prefix=%s libdir=%s'%(prefix, full_libdir)])
+            # Save results file for later investigation of failures.
+            spawn(['sh', '-c',
+                   'cp tests/results.qmr tests/results-%s.qmr'%s])
     finally:
         os.chdir(cwd)
     
Index: scripts/config
===================================================================
--- scripts/config	(revision 149048)
+++ scripts/config	(working copy)
@@ -70,7 +70,8 @@
 # Configure flags
 ########################################################################
 
-common_32 = ['--enable-timer=pentiumtsc']
+# The x86_64_tsc timer syntax works fine on 32-bit machines.
+common_32 = ['--enable-timer=x86_64_tsc']
 common_64 = ['--enable-timer=x86_64_tsc']
 
 cross = ['--host=i686-pc-linux-gnu',
@@ -91,6 +92,7 @@
 	             '--with-atlas-cfg-opts="--with-mach=P4 --with-isa=SSE2 --with-int-type=int --with-string-convention=sun"']
 
 builtin_lapack_em64t = ['--with-lapack=fortran-builtin',
+		        '--with-atlas-tarball=/home/jules/csl/atlas/atlas-3.7.16-Linux_P4E64SSE3.tar.gz',
 	             '--with-atlas-cfg-opts="--with-mach=P4E64 --with-isa=SSE3 --with-int-type=int --with-string-convention=sun"']
 
 builtin_lapack_amd64 = ['--with-lapack=fortran-builtin',
@@ -111,6 +113,191 @@
 mkl_32 = ['--with-mkl-prefix=%s'%mkl_dir, '--with-mkl-arch=32']
 mkl_64 = ['--with-mkl-prefix=%s'%mkl_dir, '--with-mkl-arch=em64t']
 
+########################################################################
+# Mondo Packages
+########################################################################
+
+class MondoTest(Package):
+
+    class Ser64IntelDebug(Configuration):
+	libdir = 'em64t/ser-intel-debug'
+        suffix = '-ser-intel-64-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   '--with-g2c-copy=%s'%g2c64,
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir, '--enable-fft=ipp'
+		  ] + mkl_64 + nompi + common_64 + simd
+
+    class SerEM64TBuiltinDebug(Configuration):
+	libdir = 'em64t/ser-builtin-debug'
+        suffix = '-ser-builtin-em64t-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_em64t + builtin_lapack_em64t + nompi + common_64 + simd
+
+    ser_64_intel_debug      = Ser64IntelDebug
+    ser_em64t_builtin_debug = SerEM64TBuiltinDebug
+
+class Mondo(Package):
+
+    class Ser32IntelRelease(Configuration):
+	libdir = 'ia32/ser-intel'
+        suffix = '-ser-intel-32'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_32_generic),
+                   'CFLAGS="%s"'%' '.join(flags_32_generic),
+                   'FFLAGS="%s"'%' '.join(flags_32_generic),
+                   'LDFLAGS="%s"'%' '.join(flags_32_generic),
+                   '--with-g2c-copy=%s'%g2c32,
+                   '--with-ipp-prefix=%s/ia32_itanium'%ipp_dir, '--enable-fft=ipp'
+                  ] + mkl_32 + nompi + common_32 + simd
+
+    class Ser32IntelDebug(Configuration):
+	libdir = 'ia32/ser-intel-debug'
+        suffix = '-ser-intel-32-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug + m32),
+                   'CFLAGS="%s"'%' '.join(m32),
+                   'FFLAGS="%s"'%' '.join(m32),
+                   'LDFLAGS="%s"'%' '.join(m32),
+                   '--with-g2c-copy=%s'%g2c32,
+                   '--with-ipp-prefix=%s/ia32_itanium'%ipp_dir, '--enable-fft=ipp'
+		  ] + mkl_32 + nompi + common_32 + simd
+
+    class Ser64IntelRelease(Configuration):
+	libdir = 'em64t/ser-intel'
+        suffix = '-ser-intel-64'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic),
+                   '--with-g2c-copy=%s'%g2c64,
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir, '--enable-fft=ipp'
+		  ] + mkl_64 + nompi + common_64 + simd
+
+    class Ser64IntelDebug(Configuration):
+	libdir = 'em64t/ser-intel-debug'
+        suffix = '-ser-intel-64-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   '--with-g2c-copy=%s'%g2c64,
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir, '--enable-fft=ipp'
+		  ] + mkl_64 + nompi + common_64 + simd
+
+    class Par64IntelRelease(Configuration):
+	libdir = 'em64t/par-intel'
+        suffix = '-par-intel-64'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic),
+                   '--with-g2c-copy=%s'%g2c64,
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir, '--enable-fft=ipp'
+		  ] + mkl_64 + mpi + common_64 + simd
+
+    class Par64IntelDebug(Configuration):
+	libdir = 'em64t/par-intel-debug'
+        suffix = '-par-intel-64-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   '--with-g2c-copy=%s'%g2c64,
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir, '--enable-fft=ipp'
+		  ] + mkl_64 + mpi + common_64 + simd
+
+    class Ser32BuiltinRelease(Configuration):
+	libdir = 'ia32/ser-builtin'
+        suffix = '-ser-builtin-32'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_32_p4sse2),
+                   'CFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   'FFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   'LDFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   '--with-g2c-copy=%s'%g2c32
+                  ] + builtin_fft_32 + builtin_lapack_32 + nompi + common_32 + simd
+
+    class Ser32BuiltinDebug(Configuration):
+	libdir = 'ia32/ser-builtin-debug'
+        suffix = '-ser-builtin-32-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug + m32),
+                   'CFLAGS="%s"'%' '.join(m32),
+                   'FFLAGS="%s"'%' '.join(m32),
+                   'LDFLAGS="%s"'%' '.join(m32),
+                   '--with-g2c-copy=%s'%g2c32,
+                  ] + builtin_fft_32 + builtin_lapack_32 + nompi + common_32 + simd
+
+    class SerEM64TBuiltinRelease(Configuration):
+	libdir = 'em64t/ser-builtin'
+        suffix = '-ser-builtin-em64t'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_em64t),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_em64t + builtin_lapack_em64t + nompi + common_64 + simd
+
+    class SerEM64TBuiltinDebug(Configuration):
+	libdir = 'em64t/ser-builtin-debug'
+        suffix = '-ser-builtin-em64t-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_em64t + builtin_lapack_em64t + nompi + common_64 + simd
+
+    suffix = '-builtin'
+    host = 'x86'
+
+    class ParEM64TBuiltinRelease(Configuration):
+	libdir = 'em64t/par-builtin'
+        suffix = '-par-builtin-em64t'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_em64t),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_em64t + builtin_lapack_em64t + mpi + common_64 + simd
+
+    class ParEM64TBuiltinDebug(Configuration):
+	libdir = 'em64t/par-builtin-debug'
+        suffix = '-par-builtin-em64t-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_em64t + builtin_lapack_em64t + mpi + common_64
+
+    class SerAMD64BuiltinRelease(Configuration):
+	libdir = 'amd64/ser-builtin'
+        suffix = '-ser-builtin-amd64'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_amd64),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_amd64 + builtin_lapack_amd64 + nompi + common_64 + simd
+
+    class SerAMD64BuiltinDebug(Configuration):
+	libdir = 'amd64/ser-builtin-debug'
+        suffix = '-ser-builtin-amd64-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_amd64 + builtin_lapack_amd64 + nompi + common_64
+
+    class ParAMD64BuiltinRelease(Configuration):
+	libdir = 'amd64/par-builtin'
+        suffix = '-par-builtin-amd64'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_amd64),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_amd64 + builtin_lapack_amd64 + mpi + common_64 + simd
+
+    class ParAMD64BuiltinDebug(Configuration):
+	libdir = 'amd64/par-builtin-debug'
+        suffix = '-par-builtin-amd64-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_amd64 + builtin_lapack_amd64 + mpi + common_64
+
+    suffix = '-intel'
+    host = 'x86'
+  
+    ser_32_intel_release      = Ser32IntelRelease
+    ser_32_intel_debug        = Ser32IntelDebug
+    ser_64_intel_release      = Ser64IntelRelease
+    ser_64_intel_debug        = Ser64IntelDebug
+    par_64_intel_release      = Par64IntelRelease
+    par_64_intel_debug        = Par64IntelDebug
+
+    ser_32_builtin_release    = Ser32BuiltinRelease
+    ser_32_builtin_debug      = Ser32BuiltinDebug
+    ser_em64t_builtin_release = SerEM64TBuiltinRelease
+    ser_em64t_builtin_debug   = SerEM64TBuiltinDebug
+    par_em64t_builtin_release = ParEM64TBuiltinRelease
+    par_em64t_builtin_debug   = ParEM64TBuiltinDebug
+    ser_amd64_builtin_release = SerAMD64BuiltinRelease
+    ser_amd64_builtin_debug   = SerAMD64BuiltinDebug
+    par_amd64_builtin_release = ParAMD64BuiltinRelease
+    par_amd64_builtin_debug   = ParAMD64BuiltinDebug
+
+
+########################################################################
+# Single Packages
+########################################################################
+
 class SerialBuiltin32(Package):
 
     class Release(Configuration):
Index: scripts/release.sh
===================================================================
--- scripts/release.sh	(revision 149048)
+++ scripts/release.sh	(working copy)
@@ -202,7 +202,6 @@
     # 1c. Build source package
     echo "Build SDist (from $svn_srcdir)"
     $package build_sdist --verbose --srcdir=$svn_srcdir	\
-        --no-maintainer-mode				\
 	--builddir=$src_builddir			\
 	--configfile=$cfgfile				\
 	$pkg_opts					\
Index: tests/context.in
===================================================================
--- tests/context.in	(revision 149048)
+++ tests/context.in	(working copy)
@@ -1,6 +1,6 @@
 CompilationTest.compiler_path=@CXX@
-CompilationTest.compiler_options= -I@abs_top_srcdir@/tests -I@abs_top_builddir@/src -I@abs_top_srcdir@/src @INT_CPPFLAGS@ @CPPFLAGS@ @CXXFLAGS@
-CompilationTest.compiler_ldflags= @INT_LDFLAGS@ @LDFLAGS@ -L@abs_top_builddir@/lib/ -l@svpp_library@ @LIBS@
+CompilationTest.compiler_options= -I@abs_top_srcdir@/tests -I@abs_top_builddir@/src -I@abs_top_srcdir@/src @INT_CPPFLAGS@ @CPPFLAGS_NOQUOTES@ @CXXFLAGS@
+CompilationTest.compiler_ldflags= @INT_LDFLAGS@ @LDFLAGS@ -L@abs_top_builddir@/lib/ -lvsip_csl -l@svpp_library@ @LIBS@
 CompilationTest.target=local_host.LocalHost
 ExecutableTest.host=local_host.LocalHost
 par_service=@PAR_SERVICE@
Index: tests/fft.cpp
===================================================================
--- tests/fft.cpp	(revision 149048)
+++ tests/fft.cpp	(working copy)
@@ -10,8 +10,11 @@
   Included Files
 ***********************************************************************/
 
-#include <vsip/impl/config.hpp>
-#include <iostream>
+// Set to 1 to enable verbose output.
+#define VERBOSE     1
+// Set to 0 to disble use of random values.
+#define FILL_RANDOM 1
+
 #include <cmath>
 
 #include <vsip/initfin.hpp>
@@ -20,17 +23,24 @@
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
 
+#include <vsip/impl/config.hpp>
 #include <vsip/impl/metaprogramming.hpp>
 
 #include <vsip_csl/test.hpp>
-#include <vsip_csl/output.hpp>
 #include <vsip_csl/error_db.hpp>
 #include <vsip_csl/ref_dft.hpp>
 
+#if VERBOSE
+#  include <iostream>
+#  include <vsip_csl/output.hpp>
+#  include "extdata-output.hpp"
+#endif
 
 
 #if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_SAL_FFT)
 #  define TEST_2D_CC 1
+#else
+#  define TEST_2D_CC 1
 #endif
 
 #if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_SAL_FFT)
@@ -59,6 +69,32 @@
 
 
 
+template <template <typename, typename> class View1,
+	  template <typename, typename> class View2,
+	  typename                            T1,
+	  typename                            T2,
+	  typename                            Block1,
+	  typename                            Block2>
+inline void
+check_error(
+  View1<T1, Block1> v1,
+  View2<T2, Block2> v2,
+  double            epsilon)
+{
+  double error = error_db(v1, v2);
+#if VERBOSE
+  if (error >= epsilon)
+  {
+    std::cout << "check_error: error >= epsilon" << std::endl;
+    std::cout << "  error   = " << error   << std::endl;
+    std::cout << "  epsilon = " << epsilon << std::endl;
+    std::cout << "  v1 =\n" << v1;
+    std::cout << "  v2 =\n" << v2;
+  }
+#endif
+  test_assert(error < epsilon);
+}
+
 // Setup input data for Fft.
 
 template <typename T,
@@ -346,7 +382,7 @@
   z2 = std::complex<T>(T(20), T(20));
 }
 
-#if 1
+#if FILL_RANDOM
 // In normal testing, fill_random fills a view with random values.
 
 // 2D 
@@ -387,17 +423,28 @@
 
 template <typename BlockT, typename T>
 void fill_random(
-  vsip::Matrix<T,BlockT> in, vsip::Rand<T>& rander)
+  vsip::Matrix<T,BlockT> in,
+  vsip::Rand<T>&         /*rander*/)
 {
   in = T(0);
   in.block().put(0, 0, T(1.0));
 }
 
+template <typename BlockT, typename T>
+void fill_random(
+  vsip::Matrix<std::complex<T>,BlockT> in,
+  vsip::Rand<std::complex<T> >&        /*rander*/)
+{
+  in = T(0);
+  in.block().put(0, 0, std::complex<T>(1.0, 1.0));
+}
+
 // 3D 
 
 template <typename BlockT, typename T>
 void fill_random(
-  vsip::Tensor<T,BlockT>& in, vsip::Rand<T>& rander)
+  vsip::Tensor<T,BlockT>& in,
+  vsip::Rand<T>&          /*rander*/)
 {
   in = T(0);
   in.block().put(0, 0, 0, T(1.0));
@@ -704,6 +751,16 @@
     vsip::Rand<in_elt_type> rander(
       sizes[i][0] * sizes[i][1] * sizes[i][2] * Dim * (sD+5));
 
+#if VERBOSE
+    std::cout << "test_fft Dim: " << Dim
+	      << "  Size: " << sizes[i][0] << ", "
+	                    << sizes[i][1] << ", "
+	                    << sizes[i][2] << "  "
+	      << Type_name<InT>::name() << " -> "
+	      << Type_name<OutT>::name()
+	      << std::endl;
+#endif
+
     Domain<Dim>  in_dom(make_dom<Dim>(sizes[i], false, sD, isReal)); 
     Domain<Dim>  out_dom(make_dom<Dim>(sizes[i], isReal, sD, isReal)); 
 
@@ -740,18 +797,18 @@
       in_block_type  in2_block(in_dom);
       in_type  in2(in2_block);
       inv_refN(out, in2);
-      test_assert(error_db(out, ref1) < -100);  // not clobbered
-      test_assert(error_db(in2, in) < -100); 
+      check_error(out, ref1, -100);  // not clobbered
+      check_error(in2, in,   -100); 
 
       check_in_place(fft_ref1, inv_refN, in, ref1, 1.0);
     }
     { fwd_by_ref_type  fft_ref4(in_dom, 0.25);
-      out_block_type  out_block(out_dom);
-      out_type  out(out_block);
-      out_type  other = fft_ref4(in, out);
+      out_block_type   out_block(out_dom);
+      out_type         out(out_block);
+      out_type         other = fft_ref4(in, out);
       test_assert(&out.block() == &other.block());
-      test_assert(error_db(in, in_copy) < -200);  // not clobbered
-      test_assert(error_db(out, ref4) < -100); 
+      check_error(in, in_copy, -200);  // not clobbered
+      check_error(out, ref4, -100); // XXXXX
 
       inv_by_ref_type  inv_ref8(in_dom, .125);
       in_block_type  in2_block(in_dom);
Index: tests/GNUmakefile.inc.in
===================================================================
--- tests/GNUmakefile.inc.in	(revision 149048)
+++ tests/GNUmakefile.inc.in	(working copy)
@@ -14,7 +14,8 @@
 
 tests_pkgconfig := PKG_CONFIG_PATH=$(libdir)/pkgconfig \
                      pkg-config vsipl++$(suffix) \
-                       --define-variable=prefix=$(prefix)
+                       --define-variable=prefix=$(prefix) \
+                       --define-variable=libdir=$(libdir)
 
 tests_qmtest_extensions := \
 	tests/QMTest/vpp_database.py \
@@ -46,7 +47,7 @@
 installcheck:: $(tests_qmtest_extensions)
 	cat tests/context-installed.pre | \
           sed -e "s|@CXX_@|`$(tests_pkgconfig) --variable=cxx`|" | \
-          sed -e "s|@CPPFLAGS_@|`$(tests_pkgconfig) --variable=cppflags`|" | \
+	  sed -e "s|@CPPFLAGS_@|`$(tests_pkgconfig) --variable=cppflags | sed -e 's|\"||g'`|" | \
           sed -e "s|@CXXFLAGS_@|`$(tests_pkgconfig) --variable=cxxflags`|" | \
           sed -e "s|@LIBS_@|`$(tests_pkgconfig) --libs`|" | \
           sed -e "s|@PAR_SERVICE_@|`$(tests_pkgconfig) --variable=par_service`|" \
Index: vendor/GNUmakefile.inc.in
===================================================================
--- vendor/GNUmakefile.inc.in	(revision 149048)
+++ vendor/GNUmakefile.inc.in	(working copy)
@@ -111,12 +111,17 @@
 ifdef BUILD_LIBF77
 install:: lib/libF77.a
 	$(INSTALL_DATA) lib/libF77.a $(DESTDIR)$(libdir)
+
+clean::
+	rm -f lib/libF77.a
+	@make -C vendor/clapack/F2CLIBS/libF77 clean >& libF77.blas.clean.log
 endif
 
 ifdef BUILD_REF_LAPACK
 install:: vendor/atlas/lib/libf77blas.a
 	$(INSTALL_DATA) vendor/atlas/lib/libf77blas.a $(DESTDIR)$(libdir)
 
+
 libs += vendor/atlas/lib/libf77blas.a
 endif
 
@@ -127,6 +132,13 @@
 	$(INSTALL_DATA) $(vendor_MERGED_LAPACK)       $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) $(srcdir)/vendor/atlas/include/cblas.h $(DESTDIR)$(includedir)
 
+clean::
+	@make -C vendor/atlas clean >& atlas.clean.log
+	rm -f $(vendor_ATLAS)
+	rm -f vendor/atlas/lib/libcblas.a
+	rm -f $(vendor_MERGED_LAPACK)
+	rm -f $(vendor_PRE_LAPACK)
+
 libs += $(vendor_ATLAS) vendor/atlas/lib/libcblas.a $(vendor_MERGED_LAPACK)
 endif
 
Index: vsipl++.pc.in
===================================================================
--- vsipl++.pc.in	(revision 149048)
+++ vsipl++.pc.in	(working copy)
@@ -12,5 +12,5 @@
 Name: Sourcery VSIPL++
 Description: CodeSourcery VSIPL++ library
 Version: @PACKAGE_VERSION@
-Libs: ${ldflags} -L${libdir} -l${svpp_library}@suffix_@ @LIBS@
+Libs: ${ldflags} -L${libdir} -lvsip_csl -l${svpp_library}@suffix_@ @LIBS@
 Cflags: ${cppflags}
