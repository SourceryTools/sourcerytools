Index: ChangeLog
===================================================================
--- ChangeLog	(revision 170216)
+++ ChangeLog	(working copy)
@@ -1,3 +1,21 @@
+2007-05-08  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/fns_elementwise.hpp (is_finite, is_nan, is_normal):
+	  change from UNARY_VIEW_FUNC_RETN to UNARY_FUNC_RETN.
+	* src/vsip/core/fns_scalar.hpp (HAVE_STD_IS{FINITE,NAN,NORMAL}):
+	  Use them.
+	  (hypot): Work around mising ::hypot.
+	* vendor/GNUmakefile.inc.in: Only build FFTW libraries, not benchmarks
+	  and tests.
+	* tests/coverage_common.hpp (TEST_UNARY): Document.
+	* tests/coverage_unary_impl.cpp: New file, tests for impl unary
+	  operators, such as is_nan, is_normal, and is_finite.
+	* configure.ac: Check for std::is_{nan, finite, normal}.
+	  Check for hypot.
+	* examples/mercury/mcoe-setup.sh: Update to allow toolset
+	  selection.  Change defaults (split complex format, ppc7447
+	  architecture, 
+
 2007-04-27  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac (PAS_HEAP_SIZE, PAS_SHARE_DYNAMIC_XFER): Alway define.
Index: src/vsip/core/fns_elementwise.hpp
===================================================================
--- src/vsip/core/fns_elementwise.hpp	(revision 170216)
+++ src/vsip/core/fns_elementwise.hpp	(working copy)
@@ -313,9 +313,9 @@
 VSIP_IMPL_UNARY_DISPATCH(imag)
 VSIP_IMPL_UNARY_FUNCTION(imag)
 
-VSIP_IMPL_UNARY_VIEW_FUNC_RETN(is_finite, bool)
-VSIP_IMPL_UNARY_VIEW_FUNC_RETN(is_nan, bool)
-VSIP_IMPL_UNARY_VIEW_FUNC_RETN(is_normal, bool)
+VSIP_IMPL_UNARY_FUNC_RETN(is_finite, bool)
+VSIP_IMPL_UNARY_FUNC_RETN(is_nan, bool)
+VSIP_IMPL_UNARY_FUNC_RETN(is_normal, bool)
 
 VSIP_IMPL_UNARY_FUNC_RETN(lnot, bool)
 VSIP_IMPL_UNARY_FUNC(log)
Index: src/vsip/core/fns_scalar.hpp
===================================================================
--- src/vsip/core/fns_scalar.hpp	(revision 170216)
+++ src/vsip/core/fns_scalar.hpp	(working copy)
@@ -123,12 +123,18 @@
 // functions std::isfinite, std::isnan, and std::isnormal.
 //
 // GreenHills on MCOE only provides macros.
+//
+// 070502: MCOE GCC 3.4.4 does not capture them.
 
-#if __GNUC__ >= 2
 // Pull isfinite, isnan, and isnormal into fn namespace so Fp_traits
 // can see them.
+#if HAVE_STD_ISFINITE
 using std::isfinite;
+#endif
+#if HAVE_STD_ISNAN
 using std::isnan;
+#endif
+#if HAVE_STD_ISNORMAL
 using std::isnormal;
 #endif
 
@@ -277,7 +283,13 @@
 gt(T1 t1, T2 t2) VSIP_NOTHROW { return t1 > t2;}
 
 inline double
-hypot(double t1, double t2) VSIP_NOTHROW { return ::hypot(t1, t2);}
+hypot(double t1, double t2) VSIP_NOTHROW {
+#if HAVE_HYPOT
+  return ::hypot(t1, t2);
+#else
+  return sqrt(sq(t1) + sq(t2));
+#endif
+}
 
 inline float
 hypot(float t1, float t2) VSIP_NOTHROW 
@@ -285,7 +297,7 @@
 #if HAVE_HYPOTF
   return ::hypotf(t1, t2);
 #else
-  return ::hypot((double)t1, (double)t2);
+  return hypot((double)t1, (double)t2);
 #endif
 }
 
Index: vendor/GNUmakefile.inc.in
===================================================================
--- vendor/GNUmakefile.inc.in	(revision 170216)
+++ vendor/GNUmakefile.inc.in	(working copy)
@@ -175,6 +175,8 @@
 USE_BUILTIN_FFTW_DOUBLE := @USE_BUILTIN_FFTW_DOUBLE@
 USE_BUILTIN_FFTW_LONG_DOUBLE := @USE_BUILTIN_FFTW_LONG_DOUBLE@
 
+FFTW_SUBDIRS = support kernel simd dft rdft reodft threads api
+
 vpath %.h src:$(srcdir)
 
 lib/libfftw3f.a: vendor/fftw3f/.libs/libfftw3f.a
@@ -182,21 +184,33 @@
  
 vendor/fftw3f/.libs/libfftw3f.a:
 	@echo "Building FFTW float (see fftw-f.build.log)"
-	@$(MAKE) -C vendor/fftw3f > fftw-f.build.log 2>&1
+	@$(MAKE) -C vendor/fftw3f config.h > fftw-f.build.log 2>&1
+	@for dir in $(FFTW_SUBDIRS); do \
+	  $(MAKE) -C vendor/fftw3f/$$dir all >> fftw-f.build.log 2>&1; \
+	done
+	@$(MAKE) -C vendor/fftw3f all-am >> fftw-f.build.log 2>&1
 
 lib/libfftw3.a: vendor/fftw3/.libs/libfftw3.a
 	cp $< $@
 
 vendor/fftw3/.libs/libfftw3.a:
 	@echo "Building FFTW double (see fftw-d.build.log)"
-	@$(MAKE) -C vendor/fftw3 > fftw-d.build.log 2>&1
+	@$(MAKE) -C vendor/fftw3 config.h > fftw-d.build.log 2>&1
+	@for dir in $(FFTW_SUBDIRS); do \
+	  $(MAKE) -C vendor/fftw3/$$dir all >> fftw-d.build.log 2>&1; \
+	done
+	@$(MAKE) -C vendor/fftw3 all-am >> fftw-d.build.log 2>&1
 
 lib/libfftw3l.a: vendor/fftw3l/.libs/libfftw3l.a
 	cp $< $@
 
 vendor/fftw3l/.libs/libfftw3l.a:
 	@echo "Building FFTW long double (see fftw-l.build.log)"
-	@$(MAKE) -C vendor/fftw3l > fftw-l.build.log 2>&1
+	@$(MAKE) -C vendor/fftw3l config.h > fftw-l.build.log 2>&1
+	@for dir in $(FFTW_SUBDIRS); do \
+	  $(MAKE) -C vendor/fftw3l/$$dir all >> fftw-l.build.log 2>&1; \
+	done
+	@$(MAKE) -C vendor/fftw3l all-am >> fftw-l.build.log 2>&1
 
 ifdef USE_BUILTIN_FFTW
   ifdef USE_BUILTIN_FFTW_FLOAT
Index: tests/coverage_common.hpp
===================================================================
--- tests/coverage_common.hpp	(revision 170216)
+++ tests/coverage_common.hpp	(working copy)
@@ -86,6 +86,14 @@
   Unary Operator Tests
 ***********************************************************************/
 
+// Test structure for Unary operator
+//
+// Where
+//   NAME is the suffix of the test class (Test_NAME)
+//   OP is the unary operator for a view
+//   CHKOP is the unary operator for an element
+//   RT is the permissible range of values (nonzero, posval, anyval)
+
 #define TEST_UNARY(NAME, OP, CHKOP, RT)					\
 struct Test_##NAME							\
 {									\
Index: tests/coverage_unary_impl.cpp
===================================================================
--- tests/coverage_unary_impl.cpp	(revision 0)
+++ tests/coverage_unary_impl.cpp	(revision 0)
@@ -0,0 +1,58 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/coverage_unary_impl.hpp
+    @author  Jules Bergmann
+    @date    2005-09-13
+    @brief   VSIPL++ Library: Coverage tests for Sourcery VSIPL++
+             implementation specific unary expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include "coverage_common.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+TEST_UNARY(is_nan,    impl::is_nan,    isnan,    anyval)
+TEST_UNARY(is_finite, impl::is_finite, isfinite, anyval)
+TEST_UNARY(is_normal, impl::is_normal, isnormal, anyval)
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  // Unary operators
+  vector_cases2_rt<Test_is_nan,    float,  bool>();
+  vector_cases2_rt<Test_is_finite, float,  bool>();
+  vector_cases2_rt<Test_is_normal, float,  bool>();
+}
Index: configure.ac
===================================================================
--- configure.ac	(revision 170216)
+++ configure.ac	(working copy)
@@ -750,10 +750,56 @@
 # Solaris 2.8 does not declare hypotf, but g++'s runtime
 # library provides a replacement.
 #
-AC_CHECK_FUNCS([acosh hypotf], [], [], [#include <cmath>])
+# On GCC 3.4.4/Mercury, hypot is not provided
+#
+AC_CHECK_FUNCS([acosh hypotf hypot], [], [], [#include <cmath>])
 AC_CHECK_DECLS([hypotf], [], [], [#include <cmath>])
 
 #
+# Check for std::isfinite, std::isnan, and std::isnormal
+#
+# isfinite, isnan, and isnormal are macros provided by C99 <math.h>
+# They are not part of C++ <cmath>.
+#
+# GCC's cmath captures them, removing the macros, and providing
+# functions std::isfinite, std::isnan, and std::isnormal.
+#
+
+# AC_CHECK_FUNCS doesn't find std::isfinite, even though it is there
+# for GCC 4.1 on Linux.  Fall back to AC_COMPILE_IFELSE
+#
+# AC_CHECK_FUNCS([std::isfinite std::isnan std::isnormal], [], [],
+#               [#include <cmath>])
+
+for fcn in std::isfinite std::isnan std::isnormal; do
+
+  AC_MSG_CHECKING([for $fcn])
+  AC_LINK_IFELSE([
+    #include <cmath>
+
+    int main(int, char **)
+    {
+      using $fcn;
+      float x = 1.f;
+      return $fcn(x) ? 1 : 0;
+    }
+    ],
+    [AC_MSG_RESULT(yes)
+     if test $fcn = "std::isfinite"; then
+       AC_DEFINE_UNQUOTED(HAVE_STD_ISFINITE, 1,
+		   [Define to 1 if you have the '$fcn' function.])
+     elif test $fcn = "std::isnan"; then
+       AC_DEFINE_UNQUOTED(HAVE_STD_ISNAN, 1,
+		   [Define to 1 if you have the '$fcn' function.])
+     elif test $fcn = "std::isnormal"; then
+       AC_DEFINE_UNQUOTED(HAVE_STD_ISNORMAL, 1,
+		   [Define to 1 if you have the '$fcn' function.])
+     fi],
+    [AC_MSG_ERROR([no])])
+done
+
+
+#
 # Check for posix_memalign, memalign
 #
 AC_CHECK_HEADERS([malloc.h], [], [], [// no prerequisites])
Index: examples/mercury/mcoe-setup.sh
===================================================================
--- examples/mercury/mcoe-setup.sh	(revision 170216)
+++ examples/mercury/mcoe-setup.sh	(working copy)
@@ -21,15 +21,20 @@
 #
 #   dir="."			# Sourcery VSIPL++ source directory.
 #   comm="ser"			# set to (ser)ial or (par)allel.
-#   fmt="inter"			# set to (inter)leaved or (split).
+#   fmt="split"			# set to (inter)leaved or (split).
 #   opt="y"			# (y) for optimized flags, (n) for debug flags.
+#   compiler="def"		# (def)ault, (GHS) - GreenHills, (GNU) - GNU
 #   simd_loop_fusion="y"	# (y) for SIMD loop fusion, (n) for not.
 #   builtin_simd="y"		# (y) for builtin SIMD routines, (n) for not.
-#   pflags="-t ppc7400_le"	# processor architecture
+#   pflags="-t ppc7447"		# processor architecture
 #   fft="sal,builtin"		# FFT backend(s)
 #   testlevel="0"		# Test level
 #   prefix="/opt/vsipl++"	# Installation prefix.
 #
+# Notes:
+#  - For compiler, if value is "def", GHS is assumed, but -compiler
+#    flag is not given.
+#
 #########################################################################
 
 # 'dir' is the directory containing SourceryVSIPL++
@@ -42,13 +47,17 @@
 fi
 
 if test "x$fmt" = x; then
-  fmt="inter"			# set to (inter)leaved or (split).
+  fmt="split"			# set to (inter)leaved or (split).
 fi
 
 if test "x$opt" = x; then
   opt="y"			# (y) for optimized flags, (n) for debug flags.
 fi
 
+if test "x$compiler" = x; then
+  compiler="def"		# (def), (GHS) for GreenHills, (GNU) for GNU
+fi
+
 if test "x$simd_loop_fusion" = x; then
   simd_loop_fusion="y"		# (y) for SIMD loop fusion, (n) for not.
 fi
@@ -66,7 +75,7 @@
 fi
 
 if test "x$pflags" = x; then
-  pflags="-t ppc7400_le"	# processor architecture
+  pflags="-t ppc7447"		# processor architecture
 fi
 
 
@@ -115,12 +124,38 @@
   cfg_flags="$cfg_flags --disable-mpi"
 fi
 
-cxxflags="$pflags --no_implicit_include"
+# If compiler = "def", assume GHS, but do not set '-compiler GHS' flag.
+if test $compiler = "GHS" -o $compiler = "def"; then
+  if test $compiler = "GHS"; then
+    toolset_flag="-compiler GHS"
+  fi
+  cxxflags="$pflags $toolset_flag --no_implicit_include"
+ 
+  opt_flags="-Ospeed -Onotailrecursion --max_inlining"
+  opt_flags="$opt_flags -DNDEBUG --diag_suppress 177,550"
+  dbg_flags="-g"
+
+  ex_off_flags="--no_exceptions"
+  ex_on_flags="--exceptions"
+
+  fftw3_cflags="-Ospeed $toolset_flag"
+else
+  toolset_flag="-compiler GCC"
+  cxxflags="$pflags $toolset_flag"
+
+  opt_flags="-Ospeed -OI -DNDEBUG"
+  dbg_flags="-g"
+
+  ex_off_flags="-fno-exceptions"
+  ex_o_flags=""				# exceptions enabled by default.
+
+  fftw3_cflags="-Ospeed $toolset_flag"
+fi
+
 if test $opt = "y"; then
-  cxxflags="$cxxflags -Ospeed -Onotailrecursion --max_inlining"
-  cxxflags="$cxxflags -DNDEBUG --diag_suppress 177,550"
+  cxxflags="$cxxflags $opt_flags"
 else
-  cxxflags="$cxxflags -g"
+  cxxflags="$cxxflags $dbg_flags"
 fi
 
 if test $builtin_simd = "y"; then
@@ -138,10 +173,17 @@
 fi
 
 if test $exceptions = "n"; then
-  cxxflags="$cxxflags --no_exceptions"
+  cxxflags="$cxxflags $ex_off_flags"
   cfg_flags="$cfg_flags --disable-exceptions"
+else
+  cxxflags="$cxxflags $ex_on_flags"
 fi
 
+if test "x$extra_args" != "x"; then
+  cfg_flags="$cfg_flags $extra_args"
+fi
+
+
 # select timer
 if test "x$timer" = "x"; then
   # timer=realtime
@@ -152,14 +194,16 @@
 # export environment variables
 
 CC=ccmc
+CFLAGS="$toolset_flag"
 CXX=ccmc++
 CXXFLAGS=$cxxflags
 AR=armc
-AR_FLAGS=cr		# armc doesn't support 'u'pdate
-LDFLAGS="$pflags"
+AR_FLAGS="$toolset_flag cr"	# armc doesn't support 'u'pdate
+LDFLAGS="$pflags $toolset_flag"
 
 export CC
 export CXX
+export CFLAGS
 export CXXFLAGS
 export AR
 export AR_FLAGS
@@ -174,7 +218,7 @@
 	--prefix=$prefix			\
 	--host=powerpc				\
 	--enable-fft=$fft			\
-	--with-fftw3-cflags="-O2"		\
+	--with-fftw3-cflags="$fftw3_cflags"	\
 	--with-complex=$fmt			\
 	--with-lapack=no			\
 	$cfg_flags				\
