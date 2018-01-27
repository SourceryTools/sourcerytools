Index: m4/fft.m4
===================================================================
--- m4/fft.m4	(revision 192398)
+++ m4/fft.m4	(working copy)
@@ -41,6 +41,11 @@
                  [Specify CFLAGS to use when building built-in FFTW3.
 		  Only used if --with-fft=builtin.]))
 
+AC_ARG_WITH(fftw3_cfg_opts,
+  AS_HELP_STRING([--with-fftw3-cfg-opts=OPTS],
+                 [Specify additional options to use when configuring built-in
+                  FFTW3. Only used if --with-fft=builtin.]))
+
 AC_ARG_ENABLE(fftw3_simd,
   AS_HELP_STRING([--disable-fftw3-simd],
                  [Disable use of SIMD instructions by FFTW3.  Useful
@@ -265,7 +270,7 @@
       mkdir -p vendor/fftw3f
       AC_MSG_NOTICE([Configuring fftw3f (float).])
       AC_MSG_NOTICE([extra config options: '$fftw3_f_simd'.])
-      (cd vendor/fftw3f; $fftw3_configure CC="$fftw_CC" $fftw3_f_simd $fftw3_opts --enable-float)
+      (cd vendor/fftw3f; $fftw3_configure CC="$fftw_CC" $fftw3_f_simd $fftw3_opts $with_fftw3_cfg_opts --enable-float)
       libs="$libs -lfftw3f"
     fi
     if test "$enable_fft_double" = yes; then
@@ -273,7 +278,7 @@
       mkdir -p vendor/fftw3
       AC_MSG_NOTICE([Configuring fftw3 (double).])
       AC_MSG_NOTICE([extra config options: '$fftw3_d_simd'.])
-      (cd vendor/fftw3; $fftw3_configure CC="$fftw_CC" $fftw3_d_simd $fftw3_opts )
+      (cd vendor/fftw3; $fftw3_configure CC="$fftw_CC" $fftw3_d_simd $fftw3_opts $with_fftw3_cfg_opts )
       libs="$libs -lfftw3"
     fi
     if test "$enable_fft_long_double" = yes; then
@@ -282,7 +287,7 @@
       mkdir -p vendor/fftw3l
       AC_MSG_NOTICE([Configuring fftw3l (long double).])
       AC_MSG_NOTICE([extra config options: '$fftw3_l_simd'.])
-      (cd vendor/fftw3l; $fftw3_configure CC="$fftw_CC" $fftw3_l_simd $fftw3_opts --enable-long-double)
+      (cd vendor/fftw3l; $fftw3_configure CC="$fftw_CC" $fftw3_l_simd $fftw3_opts $with_fftw3_cfg_opts --enable-long-double)
       libs="$libs -lfftw3l"
     fi
 
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 194614)
+++ ChangeLog	(working copy)
@@ -1,5 +1,21 @@
+2008-03-18  Jules Bergmann  <jules@codesourcery.com>
+
+	MCOE updates.
+	* configure.ac (CXXDEP): Update for ccmc++.
+	* m4/fft.m4 (--with-fftw3-cfg-opts): New option, passes options
+	  directly to FFTW3 configure.
+	* src/vsip/core/fns_scalar.hpp: Handle missing hypot decl.
+	* src/vsip/opt/sal/conv.hpp: Loosen threshold on SAL td convolution.
+	* vendor/GNUmakefile.inc.in: Use LIBEXT for FFTW3.
+	* tests/matvec.cpp: Fill in macros missing from MCOE GCC's cmath.
+	* examples/mercury/mcoe-setup.sh: Update.
+
 2008-02-26  Jules Bergmann  <jules@codesourcery.com>
 
+	Sourcery VSIPL++ 1.4 release.
+	
+2008-02-26  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/simd/expr_evaluator.hpp
 	* src/vsip/opt/simd/proxy_factory.hpp: New file, Proxy_factor from
 	  expr_evaluator.hpp.
Index: src/vsip/core/fns_scalar.hpp
===================================================================
--- src/vsip/core/fns_scalar.hpp	(revision 192398)
+++ src/vsip/core/fns_scalar.hpp	(working copy)
@@ -23,10 +23,15 @@
 #include <complex>
 
 #if !HAVE_DECL_HYPOTF
-#if HAVE_HYPOTF
+# if HAVE_HYPOTF
 extern "C" float hypotf(float, float);
 # endif
 #endif
+#if !HAVE_DECL_HYPOT
+# if HAVE_HYPOT
+extern "C" double hypot(double, double);
+# endif
+#endif
 
 namespace vsip
 {
Index: src/vsip/opt/sal/conv.hpp
===================================================================
--- src/vsip/opt/sal/conv.hpp	(revision 192398)
+++ src/vsip/opt/sal/conv.hpp	(working copy)
@@ -144,8 +144,11 @@
   Definitions
 ***********************************************************************/
 
-// These help enforce limits on the length of the kernel
-// when using SAL, which differ for complex values
+// 080313: These kernel sizes represent cross-over points where
+//   frequency domain convolution may be more efficient.  Currently
+//   we ignore them because we don't use SAL's frequency domain
+//   convolution, and SAL's time-domain convolution is faster than
+//   a generic time-domain convolution.
 template <typename T>
 struct Max_kernel_length
 {
@@ -297,7 +300,8 @@
   stride_type s_coeff = coeff_.block().impl_stride(1, 0);
 
   assert( Max_kernel_length<T>::value != 0 );
-  if ( (M <= Max_kernel_length<T>::value) && (decimation_ == 1) ) 
+  // See note above on Max_kernel_length defn.
+  if ( /*(M <= Max_kernel_length<T>::value) &&*/ (decimation_ == 1) ) 
   {
     // SAL only does the minimum convolution
     if (Supp == support_full)
Index: vendor/GNUmakefile.inc.in
===================================================================
--- vendor/GNUmakefile.inc.in	(revision 192398)
+++ vendor/GNUmakefile.inc.in	(working copy)
@@ -203,7 +203,7 @@
 
 vpath %.h src:$(srcdir)
 
-lib/libfftw3f.a: vendor/fftw3f/.libs/libfftw3f.a
+lib/libfftw3f.$(LIBEXT): vendor/fftw3f/.libs/libfftw3f.a
 	cp $< $@
 
 vendor/fftw3f/.libs/libfftw3f.a:
@@ -214,7 +214,7 @@
 	done
 	@$(MAKE) -C vendor/fftw3f all-am >> fftw-f.build.log 2>&1
 
-lib/libfftw3.a: vendor/fftw3/.libs/libfftw3.a
+lib/libfftw3.$(LIBEXT): vendor/fftw3/.libs/libfftw3.a
 	cp $< $@
 
 vendor/fftw3/.libs/libfftw3.a:
@@ -225,7 +225,7 @@
 	done
 	@$(MAKE) -C vendor/fftw3 all-am >> fftw-d.build.log 2>&1
 
-lib/libfftw3l.a: vendor/fftw3l/.libs/libfftw3l.a
+lib/libfftw3l.$(LIBEXT): vendor/fftw3l/.libs/libfftw3l.a
 	cp $< $@
 
 vendor/fftw3l/.libs/libfftw3l.a:
@@ -238,13 +238,13 @@
 
 ifdef USE_BUILTIN_FFTW
   ifdef USE_BUILTIN_FFTW_FLOAT
-    vendor_FFTW_LIBS += lib/libfftw3f.a
+    vendor_FFTW_LIBS += lib/libfftw3f.$(LIBEXT)
   endif
   ifdef USE_BUILTIN_FFTW_DOUBLE
-    vendor_FFTW_LIBS += lib/libfftw3.a
+    vendor_FFTW_LIBS += lib/libfftw3.$(LIBEXT)
   endif
   ifdef USE_BUILTIN_FFTW_LONG_DOUBLE
-    vendor_FFTW_LIBS += lib/libfftw3l.a
+    vendor_FFTW_LIBS += lib/libfftw3l.$(LIBEXT)
   endif
 
 libs += $(vendor_FFTW_LIBS) 
@@ -255,7 +255,7 @@
 	@for ldir in $(subst .a,,$(subst lib/lib,,$(vendor_FFTW_LIBS))); do \
 	  $(MAKE) -C vendor/$$ldir clean >> fftw.clean.log 2>&1; \
 	  echo "$(MAKE) -C vendor/$$ldir clean "; done
-	rm -f lib/libfftw3.a lib/libfftw3f.a lib/libfftw3l.a
+	rm -f lib/libfftw3.$(LIBEXT) lib/libfftw3f.$(LIBEXT) lib/libfftw3l.$(LIBEXT)
 
 install:: $(vendor_FFTW_LIBS)
 	@echo "Installing FFTW"
Index: tests/matvec.cpp
===================================================================
--- tests/matvec.cpp	(revision 192398)
+++ tests/matvec.cpp	(working copy)
@@ -15,6 +15,7 @@
 ***********************************************************************/
 
 #include <cassert>
+#include <math.h>
 
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
@@ -31,7 +32,25 @@
 using namespace vsip_csl;
 
 
+
 /***********************************************************************
+  Macros
+***********************************************************************/
+
+// 080314: For MCOE csr1610, these macros are not defined by GCC
+//         math.h/cmath (but are defined by GHS math.h/cmath).
+
+#if _MC_EXEC && __GNUC__
+#  define M_E        2.718281828459045235360
+#  define M_LN2      0.69314718055994530942
+#  define M_SQRT2    1.41421356237309504880
+#  define M_LN10     2.30258509299404568402
+#  define M_LOG2E    1.442695040888963407
+#endif
+
+
+
+/***********************************************************************
   Definitions
 ***********************************************************************/
 
Index: configure.ac
===================================================================
--- configure.ac	(revision 194614)
+++ configure.ac	(working copy)
@@ -453,6 +453,8 @@
   CXXDEP="$CXX /QM"
   INTEL_WIN=1
   cygwin_mount=`cygpath -w /`
+elif test "$CXX" == "ccmc++"; then
+  CXXDEP="$CXX -M"
 else
   CXXDEP="$CXX -M -x c++"
   cygwin_mount=
Index: examples/mercury/mcoe-setup.sh
===================================================================
--- examples/mercury/mcoe-setup.sh	(revision 192398)
+++ examples/mercury/mcoe-setup.sh	(working copy)
@@ -138,18 +138,18 @@
   ex_off_flags="--no_exceptions"
   ex_on_flags="--exceptions"
 
-  fftw3_cflags="-Ospeed $toolset_flag"
+  fftw3_cflags="-Ospeed $pflags $toolset_flag"
 else
-  toolset_flag="-compiler GCC"
+  toolset_flag="-compiler GNU"
   cxxflags="$pflags $toolset_flag"
 
-  opt_flags="-Ospeed -OI -DNDEBUG"
+  opt_flags="-Otime -DNDEBUG -w"
   dbg_flags="-g"
 
   ex_off_flags="-fno-exceptions"
   ex_o_flags=""				# exceptions enabled by default.
 
-  fftw3_cflags="-Ospeed $toolset_flag"
+  fftw3_cflags="-Otime $pflags $toolset_flag"
 fi
 
 if test $opt = "y"; then
@@ -169,7 +169,7 @@
 fi
 
 if test $sal = "y"; then
-  cfg_flags="$cfg_flags --enable-sal"
+  cfg_flags="$cfg_flags --with-sal"
 fi
 
 if test $exceptions = "n"; then
@@ -215,13 +215,14 @@
 # run configure
 
 echo "$dir/configure"
-$dir/configure					\
-	--prefix=$prefix			\
-	--host=powerpc				\
-	--enable-fft=$fft			\
-	--with-fftw3-cflags="$fftw3_cflags"	\
-	--with-complex=$fmt			\
-	--with-lapack=no			\
-	$cfg_flags				\
-	--with-test-level=$testlevel		\
+$dir/configure						\
+	--prefix=$prefix				\
+	--host=powerpc					\
+	--enable-fft=$fft				\
+	--with-fftw3-cflags="$fftw3_cflags"		\
+	--with-fftw3-cfg-opts="--with-our-malloc16"	\
+	--with-complex=$fmt				\
+	--with-lapack=no				\
+	$cfg_flags					\
+	--with-test-level=$testlevel			\
 	--enable-timer=$timer
