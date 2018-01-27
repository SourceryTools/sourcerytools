Index: configure.ac
===================================================================
--- configure.ac	(revision 147666)
+++ configure.ac	(working copy)
@@ -49,18 +49,18 @@
 AC_ARG_WITH(obj_ext,
   AS_HELP_STRING([--with-obj-ext=EXT],
                  [Specify the file extension to be used for object files.
-                  Object files will be named file.$EXT]),
+                  Object files will be named file.$EXT.]),
   [obj_ext=$withval])
 AC_ARG_WITH(exe_ext,
   AS_HELP_STRING([--with-exe-ext=EXT],
                  [Specify the suffix to be used for executable files.
 		  Executable files will be named file$EXT.  (Note: unlike
-		  --with-obj-ext, no "." is implied]),
+		  --with-obj-ext, no "." is implied.]),
   [exe_ext=$withval])
 
 AC_ARG_ENABLE([exceptions],
   AS_HELP_STRING([--disable-exceptions],
-                 [don't use C++ exceptions]),,
+                 [Don't use C++ exceptions.]),,
   [enable_exceptions=yes])
 
 # By default we will probe for MPI and use it if it exists.  If it
@@ -75,7 +75,7 @@
 
 AC_ARG_ENABLE([mpi],
   AS_HELP_STRING([--disable-mpi],
-                 [don't use MPI (default is to use it if found)]),,
+                 [Don't use MPI (default is to use it if found).]),,
   [enable_mpi=probe])
 
 AC_ARG_WITH(mpi_prefix,
@@ -91,7 +91,7 @@
 ### Mercury Scientific Algorithm (SAL)
 AC_ARG_ENABLE([sal],
   AS_HELP_STRING([--enable-sal],
-                 [use SAL if found (default is to not search for it)]),,
+                 [Use SAL if found (default is to not search for it).]),,
   [enable_sal=no])
 AC_ARG_WITH(sal_include,
   AS_HELP_STRING([--with-sal-include=PATH],
@@ -107,7 +107,7 @@
 ### Intel Performance Primitives (IPP)
 AC_ARG_ENABLE([ipp],
   AS_HELP_STRING([--enable-ipp],
-                 [use IPP if found (default is to not search for it)]),,
+                 [Use IPP if found (default is to not search for it).]),,
   [enable_ipp=no])
 AC_ARG_WITH(ipp_prefix,
   AS_HELP_STRING([--with-ipp-prefix=PATH],
@@ -126,7 +126,7 @@
 AC_ARG_ENABLE(fft,
   AS_HELP_STRING([--enable-fft],
                  [Specify list of FFT engines. Available engines are:
-                  fftw3, ipp, sal, builtin, dft, or no_fft. Default is builtin.]),,
+                  fftw3, ipp, sal, builtin, dft, or no_fft [[builtin]].]),,
   [enable_fft=builtin])
   
 AC_ARG_WITH(fftw3_prefix,
@@ -136,22 +136,22 @@
 
 AC_ARG_ENABLE([fft-float],
   AS_HELP_STRING([--disable-fft-float],
-                 [Omit support for FFT applied to float elements]),,
+                 [Omit support for FFT applied to float elements.]),,
   [enable_fft_float=yes])
 
 AC_ARG_ENABLE([fft-double],
   AS_HELP_STRING([--disable-fft-double],
-                 [Omit support for FFT applied to double elements]),,
+                 [Omit support for FFT applied to double elements.]),,
   [enable_fft_double=yes])
 
 AC_ARG_ENABLE([fft-long-double],
   AS_HELP_STRING([--disable-fft-long-double],
-                 [Omit support for FFT applied to long double elements]),,
+                 [Omit support for FFT applied to long double elements.]),,
   [enable_fft_long_double=yes])
 
 AC_ARG_WITH(fftw3_cflags,
   AS_HELP_STRING([--with-fftw3-cflags=CFLAGS],
-                 [Specify CFLAGS to use when building built-inFFTW3.
+                 [Specify CFLAGS to use when building built-in FFTW3.
 		  Only used if --with-fft=builtin.]))
 
 # LAPACK and related libraries (Intel MKL)
@@ -169,7 +169,7 @@
 
 AC_ARG_WITH([lapack],
   AS_HELP_STRING([--with-lapack\[=PKG\]],
-                 [select one or more LAPACK libraries to search for
+                 [Select one or more LAPACK libraries to search for
                   (default is to probe for atlas, generic, and builtin,
 	          using the first one found).  Sourcery VSIPL++ understands the
 		  following LAPACK library selections: mkl (Intel Math Kernel
@@ -184,34 +184,34 @@
 
 AC_ARG_WITH(atlas_prefix,
   AS_HELP_STRING([--with-atlas-prefix=PATH],
-                 [specify the installation prefix of the ATLAS library.
+                 [Specify the installation prefix of the ATLAS library.
 	          Headers must be in PATH/include; libraries in PATH/lib.
 	          (Enables LAPACK).]))
 
 AC_ARG_WITH(atlas_libdir,
   AS_HELP_STRING([--with-atlas-libdir=PATH],
-                 [specify the directory containing ATLAS libraries.
+                 [Specify the directory containing ATLAS libraries.
 	          (Enables LAPACK).]))
 
 AC_ARG_WITH(atlas_cfg_opts,
   AS_HELP_STRING([--with-atlas-cfg-opts=OPTS],
-                 [specify additional options for ATLAS configure.]))
+                 [Specify additional options for ATLAS configure.]))
 
 AC_ARG_WITH(atlas_tarball,
   AS_HELP_STRING([--with-atlas-tarball=PATH],
-                 [specify an existing ATLAS tarball to be used as basis
+                 [Specify an existing ATLAS tarball to be used as basis
 	          for builtin LAPACK library. (Enables LAPACK).]))
 
 AC_ARG_WITH(mkl_prefix,
   AS_HELP_STRING([--with-mkl-prefix=PATH],
-                 [specify the installation prefix of the MKL library.  Headers
+                 [Specify the installation prefix of the MKL library.  Headers
                   must be in PATH/include; libraries in PATH/lib/ARCH (where
 		  ARCH is either deduced or set by the --with-mkl-arch option).
 	          (Enables LAPACK).]))
 
 AC_ARG_WITH(mkl_arch,
   AS_HELP_STRING([--with-mkl-arch=ARCH],
-                 [specify the MKL library architecture directory.  MKL
+                 [Specify the MKL library architecture directory.  MKL
 		  libraries from PATH/lib/ARCH will be used, where
 		  PATH is specified with '--with-mkl-prefix' option.
 		  (Default is to probe arch based on host cpu type).]),,
@@ -219,18 +219,18 @@
 
 AC_ARG_WITH(acml_prefix,
   AS_HELP_STRING([--with-acml-prefix=PATH],
-                 [specify the installation prefix of the ACML library.  Headers
+                 [Specify the installation prefix of the ACML library.  Headers
                   must be in PATH/include; libraries in PATH/lib
 	          (Enables LAPACK).]))
 
 AC_ARG_ENABLE([cblas],
   AS_HELP_STRING([--disable-cblas],
-                 [disable C BLAS API (default is to use it if possible)]),,
+                 [Disable C BLAS API (default is to use it if possible)]),,
   [enable_cblas=yes])
 
 AC_ARG_WITH([g2c-path],
   AS_HELP_STRING([--with-g2c-path=PATH],
-                 [path to libg2c.a library (libg2c.a) (default is to include
+                 [Path to libg2c.a library (libg2c.a) (default is to include
 		  g2c via -lg2c)]),
   [search_g2c="path"],
   [search_g2c="none lopt"])
@@ -261,36 +261,36 @@
 
 AC_ARG_ENABLE([timer],
   AS_HELP_STRING([--enable-timer=type],
-                 [set profile timer type.  Choices include none, posix, realtime, pentiumtsc, x86_64_tsc]),,
+                 [Set profile timer type.  Choices include none, posix, realtime, pentiumtsc, x86_64_tsc [[none]].]),,
   [enable_timer=none])
 
 AC_ARG_ENABLE([cpu_mhz],
   AS_HELP_STRING([--enable-cpu-mhz=speed],
-                 [set CPU speed in MHz.  Only necessary for TSC and if /proc/cpuinfo does not exist or is wrong]),,
+                 [Set CPU speed in MHz.  Only necessary for TSC and if /proc/cpuinfo does not exist or is wrong.]),,
   [enable_cpu_mhz=none])
 
 AC_ARG_ENABLE([profiler],
   AS_HELP_STRING([--enable-profiler=type],
                  [Specify list of areas to profile.  Choices include none, all
-		  or a combination of: signal, matvec, fns and user.  Default is none.]),,
+		  or a combination of: signal, matvec, fns and user [[none]].]),,
   [enable_profiler=none])
 
 AC_ARG_ENABLE([simd_loop_fusion],
   AS_HELP_STRING([--enable-simd-loop-fusion],
-                 [Enable SIMD loop-fusion]),,
+                 [Enable SIMD loop-fusion.]),,
   [enable_simd_loop_fusion=no])
 
 AC_ARG_WITH([builtin_simd_routines],
   AS_HELP_STRING([--with-builtin-simd-routines=WHAT],
-                 [Use builtin SIMD routines]),,
+                 [Use builtin SIMD routines.]),,
   [with_builtin_simd_routines=none])
 
 AC_ARG_WITH([test_level],
   AS_HELP_STRING([--with-test-level=WHAT],
-                 [set effort level for test-suite.  0 for low-level
+                 [Set effort level for test-suite.  0 for low-level
 		  (avoids long-running and long-compiling tests),
 		  1 for regular effort, 2 for high-level (enables
-		  long-running tests).  Default value is 1.]),,
+		  long-running tests) [[1]].]),,
   [with_test_level=1])
 
 AC_ARG_ENABLE(eval-dense-expr,
@@ -1897,6 +1897,7 @@
 else
   AC_MSG_RESULT([Complex storage format:                  interleaved])
 fi
+AC_MSG_RESULT([Timer:                                   ${enable_timer}])
 AC_MSG_RESULT([Profiling:                               ${profiler_options}])
 
 #
