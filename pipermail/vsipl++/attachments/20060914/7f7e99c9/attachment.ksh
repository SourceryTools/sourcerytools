Index: ChangeLog
===================================================================
--- ChangeLog	(revision 149243)
+++ ChangeLog	(working copy)
@@ -1,5 +1,33 @@
 2006-09-14  Jules Bergmann  <jules@codesourcery.com>
 
+	* scripts/set-prefix.sh: Change #! to /bin/sh
+	* scripts/package.py: Add support for builtin_libdir to distinguish
+	  libdir of builtin libraries (which can be shared amonst
+	  variants) from libdir of libsvipp.
+	* scripts/config: Add builtin_libdir entries.
+	* GNUmakefile.in (builtin_libdir): New variable.  
+	  (bdist): Remove 'h' option to tar to preserve pkg-config symlinks.
+	* vendor/GNUmakefile.inc.in: Install atlas and fftw3 into
+	  builtin_libdir.
+	* configure.ac (--with-builtin-libdir): New option for setting
+	  builtin_libdir.
+	  (LDFLAGS): Remove old -L paths. 
+	  Define vsip_impl_fft_use_{float,double,long_double}
+	  properly when using SAL.
+	* lib/GNUmakefile.inc.in: Remove boiler-plate install
+	  of all libs in libs dir.  Conflicts with builtin_libdir.
+	  Only used for libg2c, which now has rule in vendor/GNUmakefile.inc.
+	
+	* src/vsip/impl/simd/simd.hpp (load_scalar): Fix defn for
+	  SSE char, short, and int.
+	* tests/test-random.hpp: Add option to use VSIPL++ Rand
+	  instead of system rand().
+	* tests/fft.cpp: Turn VERBOSE off.  Avoid testing 2D CC
+	  when only using IPP backend.
+	* tests/solver-lu.cpp: Improve debugging output.
+	
+2006-09-14  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/impl/fft.hpp: Pass backend to workspace constructor.
 	* src/vsip/impl/workspace.hpp: Fast path optimization for 1-dim
 	  CC unit-stride FFT to use compile-time Ext_data.
Index: scripts/set-prefix.sh
===================================================================
--- scripts/set-prefix.sh	(revision 149215)
+++ scripts/set-prefix.sh	(working copy)
@@ -1,4 +1,4 @@
-#! /usr/bin/env bash
+#! /bin/sh
 
 ########################################################################
 #
Index: scripts/package.py
===================================================================
--- scripts/package.py	(revision 149215)
+++ scripts/package.py	(working copy)
@@ -50,9 +50,10 @@
     for n, c in package.__dict__.iteritems():
         if type(c) is ClassType and issubclass(c, Configuration):
             configs[c.suffix] = {}
-            configs[c.suffix]['suffix']  = c.suffix
-            configs[c.suffix]['options'] = ' '.join(c.options)
-            configs[c.suffix]['libdir']  = c.libdir
+            configs[c.suffix]['suffix']         = c.suffix
+            configs[c.suffix]['options']        = ' '.join(c.options)
+            configs[c.suffix]['libdir']         = c.libdir
+            configs[c.suffix]['builtin_libdir'] = c.builtin_libdir
 
     return package.suffix, package.host, configs
 
@@ -169,8 +170,9 @@
     try:
         # Build all desired configurations
         for s, x in parameters['config'].iteritems():
-            c      = x['options']
-            libdir = x['libdir']
+            c              = x['options']
+            libdir         = x['libdir']
+            builtin_libdir = x['builtin_libdir']
             # Make sure the builddir is empty to avoid accidently using
             # any debris left behind there.
             print 'Building suffix: %s in dir %s'%(s,builddir)
@@ -186,8 +188,9 @@
 
             announce('building %s...'%s)
             configure('--prefix=%s'%prefix,
-                      '--libdir=\${prefix}/lib/%s'%(libdir),
-                      c)
+                    '--libdir=\${prefix}/lib/%s'%(libdir),
+                    '--with-builtin-libdir=\${prefix}/lib/%s'%(builtin_libdir),
+                    c)
             spawn(['sh', '-c', 'make install DESTDIR=%s'%abs_distdir])
 
             # Make copy of acconfig for later perusal.
@@ -243,14 +246,16 @@
         # since parameters['prefix'] may be absolute.
         prefix = abs_distdir + parameters['prefix']
         for s in parameters['config']: # keys are suffixes...
-            libdir      = parameters['config'][s]['libdir']
-            full_libdir = '%s/lib/%s'%(prefix,libdir)
+            libdir              = parameters['config'][s]['libdir']
+            builtin_libdir      = parameters['config'][s]['builtin_libdir']
+            full_libdir         = '%s/lib/%s'%(prefix,libdir)
+            full_builtin_libdir = '%s/lib/%s'%(prefix,builtin_libdir)
             announce('testing suffix %s...'%s)
             spawn(['sh', '-c',
-                   'make installcheck prefix=%s libdir=%s'%(prefix, full_libdir)])
+                   'make installcheck prefix=%s libdir=%s builtin_libdir=%s'%(prefix, full_libdir, full_builtin_libdir)])
             # Save results file for later investigation of failures.
             spawn(['sh', '-c',
-                   'cp tests/results.qmr tests/results-%s.qmr'%s])
+                   'cp tests/results.qmr tests/results%s.qmr'%s])
     finally:
         os.chdir(cwd)
     
Index: scripts/config
===================================================================
--- scripts/config	(revision 149215)
+++ scripts/config	(working copy)
@@ -81,6 +81,11 @@
 simd = ['--enable-simd-loop-fusion',
 	'--with-builtin-simd-routines=generic']
 
+builtin_fft_32_opts = ['--with-fftw3-cflags="-O3 -fomit-frame-pointer -fno-schedule-insns -malign-double -fstrict-aliasing -mpreferred-stack-boundary=4 -mcpu=pentiumpro"',
+		     'CODELET_OPTIM=-O']
+builtin_fft_em64t_opts = []
+builtin_fft_amd64_opts = []
+
 builtin_fft_32    = ['--enable-fft=builtin',
 	             '--with-fftw3-cflags="-O3 -fomit-frame-pointer -fno-schedule-insns -malign-double -fstrict-aliasing -mpreferred-stack-boundary=4 -mcpu=pentiumpro"',
 		     'CODELET_OPTIM=-O']
@@ -120,15 +125,18 @@
 class MondoTest(Package):
 
     class Ser64IntelDebug(Configuration):
-	libdir = 'em64t/ser-intel-debug'
+	builtin_libdir = 'em64t'
+	libdir         = 'em64t/ser-intel-debug'
         suffix = '-ser-intel-64-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
                    '--with-g2c-copy=%s'%g2c64,
-                   '--with-ipp-prefix=%s/em64t'%ipp_dir, '--enable-fft=ipp'
-		  ] + mkl_64 + nompi + common_64 + simd
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir,
+	           '--enable-fft=ipp,builtin'
+		  ] + builtin_fft_em64t_opts + mkl_64 + nompi + common_64 + simd
 
     class SerEM64TBuiltinDebug(Configuration):
-	libdir = 'em64t/ser-builtin-debug'
+	builtin_libdir = 'em64t'
+	libdir         = 'em64t/ser-builtin-debug'
         suffix = '-ser-builtin-em64t-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
                    '--with-g2c-copy=%s'%g2c64,
@@ -140,7 +148,8 @@
 class Mondo(Package):
 
     class Ser32IntelRelease(Configuration):
-	libdir = 'ia32/ser-intel'
+	builtin_libdir = 'ia32'
+	libdir         = 'ia32/ser-intel'
         suffix = '-ser-intel-32'
         options = ['CXXFLAGS="%s"'%' '.join(release + flags_32_generic),
                    'CFLAGS="%s"'%' '.join(flags_32_generic),
@@ -151,6 +160,7 @@
                   ] + mkl_32 + nompi + common_32 + simd
 
     class Ser32IntelDebug(Configuration):
+	builtin_libdir = 'ia32'
 	libdir = 'ia32/ser-intel-debug'
         suffix = '-ser-intel-32-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug + m32),
@@ -162,7 +172,8 @@
 		  ] + mkl_32 + nompi + common_32 + simd
 
     class Ser64IntelRelease(Configuration):
-	libdir = 'em64t/ser-intel'
+	builtin_libdir = 'em64t'
+	libdir         = 'em64t/ser-intel'
         suffix = '-ser-intel-64'
         options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic),
                    '--with-g2c-copy=%s'%g2c64,
@@ -170,6 +181,7 @@
 		  ] + mkl_64 + nompi + common_64 + simd
 
     class Ser64IntelDebug(Configuration):
+	builtin_libdir = 'em64t'
 	libdir = 'em64t/ser-intel-debug'
         suffix = '-ser-intel-64-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
@@ -178,6 +190,7 @@
 		  ] + mkl_64 + nompi + common_64 + simd
 
     class Par64IntelRelease(Configuration):
+	builtin_libdir = 'em64t'
 	libdir = 'em64t/par-intel'
         suffix = '-par-intel-64'
         options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic),
@@ -186,6 +199,7 @@
 		  ] + mkl_64 + mpi + common_64 + simd
 
     class Par64IntelDebug(Configuration):
+	builtin_libdir = 'em64t'
 	libdir = 'em64t/par-intel-debug'
         suffix = '-par-intel-64-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
@@ -194,6 +208,7 @@
 		  ] + mkl_64 + mpi + common_64 + simd
 
     class Ser32BuiltinRelease(Configuration):
+	builtin_libdir = 'ia32'
 	libdir = 'ia32/ser-builtin'
         suffix = '-ser-builtin-32'
         options = ['CXXFLAGS="%s"'%' '.join(release + flags_32_p4sse2),
@@ -204,6 +219,7 @@
                   ] + builtin_fft_32 + builtin_lapack_32 + nompi + common_32 + simd
 
     class Ser32BuiltinDebug(Configuration):
+	builtin_libdir = 'ia32'
 	libdir = 'ia32/ser-builtin-debug'
         suffix = '-ser-builtin-32-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug + m32),
@@ -214,13 +230,15 @@
                   ] + builtin_fft_32 + builtin_lapack_32 + nompi + common_32 + simd
 
     class SerEM64TBuiltinRelease(Configuration):
-	libdir = 'em64t/ser-builtin'
+	builtin_libdir = 'em64t'
+	libdir         = 'em64t/ser-builtin'
         suffix = '-ser-builtin-em64t'
         options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_em64t),
                    '--with-g2c-copy=%s'%g2c64,
                   ] + builtin_fft_em64t + builtin_lapack_em64t + nompi + common_64 + simd
 
     class SerEM64TBuiltinDebug(Configuration):
+	builtin_libdir = 'em64t'
 	libdir = 'em64t/ser-builtin-debug'
         suffix = '-ser-builtin-em64t-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
@@ -231,6 +249,7 @@
     host = 'x86'
 
     class ParEM64TBuiltinRelease(Configuration):
+	builtin_libdir = 'em64t'
 	libdir = 'em64t/par-builtin'
         suffix = '-par-builtin-em64t'
         options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_em64t),
@@ -238,6 +257,7 @@
                   ] + builtin_fft_em64t + builtin_lapack_em64t + mpi + common_64 + simd
 
     class ParEM64TBuiltinDebug(Configuration):
+	builtin_libdir = 'em64t'
 	libdir = 'em64t/par-builtin-debug'
         suffix = '-par-builtin-em64t-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
@@ -245,6 +265,7 @@
                   ] + builtin_fft_em64t + builtin_lapack_em64t + mpi + common_64
 
     class SerAMD64BuiltinRelease(Configuration):
+	builtin_libdir = 'amd64'
 	libdir = 'amd64/ser-builtin'
         suffix = '-ser-builtin-amd64'
         options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_amd64),
@@ -252,6 +273,7 @@
                   ] + builtin_fft_amd64 + builtin_lapack_amd64 + nompi + common_64 + simd
 
     class SerAMD64BuiltinDebug(Configuration):
+	builtin_libdir = 'amd64'
 	libdir = 'amd64/ser-builtin-debug'
         suffix = '-ser-builtin-amd64-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
@@ -259,6 +281,7 @@
                   ] + builtin_fft_amd64 + builtin_lapack_amd64 + nompi + common_64
 
     class ParAMD64BuiltinRelease(Configuration):
+	builtin_libdir = 'amd64'
 	libdir = 'amd64/par-builtin'
         suffix = '-par-builtin-amd64'
         options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_amd64),
@@ -266,13 +289,14 @@
                   ] + builtin_fft_amd64 + builtin_lapack_amd64 + mpi + common_64 + simd
 
     class ParAMD64BuiltinDebug(Configuration):
+	builtin_libdir = 'amd64'
 	libdir = 'amd64/par-builtin-debug'
         suffix = '-par-builtin-amd64-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
                    '--with-g2c-copy=%s'%g2c64,
                   ] + builtin_fft_amd64 + builtin_lapack_amd64 + mpi + common_64
 
-    suffix = '-intel'
+    suffix = '-linux'
     host = 'x86'
   
     ser_32_intel_release      = Ser32IntelRelease
Index: src/vsip/impl/simd/simd.hpp
===================================================================
--- src/vsip/impl/simd/simd.hpp	(revision 149215)
+++ src/vsip/impl/simd/simd.hpp	(working copy)
@@ -462,8 +462,8 @@
   { return _mm_load_si128((simd_type*)addr); }
 
   static simd_type load_scalar(value_type value)
-  { return _mm_set_epi8(value, 0, 0, 0, 0, 0, 0, 0,
-			0, 0, 0, 0, 0, 0, 0, 0); }
+  { return _mm_set_epi8(0, 0, 0, 0, 0, 0, 0, 0,
+			0, 0, 0, 0, 0, 0, 0, value); }
 
   static simd_type load_scalar_all(value_type value)
   { return _mm_set1_epi8(value); }
@@ -518,7 +518,7 @@
   { return _mm_load_si128((simd_type*)addr); }
 
   static simd_type load_scalar(value_type value)
-  { return _mm_set1_epi16(value); }
+  { return _mm_set_epi16(0, 0, 0, 0, 0, 0, 0, value); }
 
   static simd_type load_scalar_all(value_type value)
   { return _mm_set1_epi16(value); }
@@ -600,7 +600,7 @@
   { return _mm_load_si128((simd_type*)addr); }
 
   static simd_type load_scalar(value_type value)
-  { return _mm_set1_epi32(value); }
+  { return _mm_set_epi32(0, 0, 0, value); }
 
   static simd_type load_scalar_all(value_type value)
   { return _mm_set1_epi32(value); }
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 149215)
+++ GNUmakefile.in	(working copy)
@@ -51,6 +51,7 @@
 datadir := @datadir@
 includedir := @includedir@
 libdir := @libdir@
+builtin_libdir := @builtin_libdir@
 sbindir := @sbindir@
 # The directory for putting data that is specific to this package.
 # This is not a standard variable name.
@@ -446,7 +447,7 @@
 	mkdir $(distname)
 	cp -pr $(distfiles) $(distname)
 	-chmod -R a+r $(distname)
-	tar cjhf $@ --owner=0 --group=0\
+	tar cjf $@ --owner=0 --group=0\
           --exclude CVS \
           --exclude _darcs \
           --exclude .cvsignore \
Index: vendor/GNUmakefile.inc.in
===================================================================
--- vendor/GNUmakefile.inc.in	(revision 149215)
+++ vendor/GNUmakefile.inc.in	(working copy)
@@ -110,7 +110,7 @@
 
 ifdef BUILD_LIBF77
 install:: lib/libF77.a
-	$(INSTALL_DATA) lib/libF77.a $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) lib/libF77.a $(DESTDIR)$(builtin_libdir)
 
 clean::
 	rm -f lib/libF77.a
@@ -119,7 +119,7 @@
 
 ifdef BUILD_REF_LAPACK
 install:: vendor/atlas/lib/libf77blas.a
-	$(INSTALL_DATA) vendor/atlas/lib/libf77blas.a $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) vendor/atlas/lib/libf77blas.a $(DESTDIR)$(builtin_libdir)
 
 
 libs += vendor/atlas/lib/libf77blas.a
@@ -127,13 +127,15 @@
 
 ifdef USE_ATLAS_LAPACK
 install:: $(vendor_ATLAS) vendor/atlas/lib/libcblas.a $(vendor_MERGED_LAPACK)
-	$(INSTALL_DATA) $(vendor_ATLAS)               $(DESTDIR)$(libdir)
-	$(INSTALL_DATA) vendor/atlas/lib/libcblas.a   $(DESTDIR)$(libdir)
-	$(INSTALL_DATA) $(vendor_MERGED_LAPACK)       $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) $(vendor_ATLAS)               $(DESTDIR)$(builtin_libdir)
+	$(INSTALL_DATA) vendor/atlas/lib/libcblas.a   $(DESTDIR)$(builtin_libdir)
+	$(INSTALL_DATA) $(vendor_MERGED_LAPACK)       $(DESTDIR)$(builtin_libdir)
 	$(INSTALL_DATA) $(srcdir)/vendor/atlas/include/cblas.h $(DESTDIR)$(includedir)
 
 clean::
-	@make -C vendor/atlas clean >& atlas.clean.log
+	@echo "Cleaning ATLAS (see atlas.clean.log)"
+	@# If installing atlas from a tarball, a Makefile won't be there.
+	-@make -C vendor/atlas clean >& atlas.clean.log
 	rm -f $(vendor_ATLAS)
 	rm -f vendor/atlas/lib/libcblas.a
 	rm -f $(vendor_MERGED_LAPACK)
@@ -144,8 +146,8 @@
 
 ifdef USE_SIMPLE_LAPACK
 install:: $(vendor_CLAPACK) $(vendor_CLAPACK_BLAS)
-	$(INSTALL_DATA) $(vendor_CLAPACK)      $(DESTDIR)$(libdir)
-	$(INSTALL_DATA) $(vendor_CLAPACK_BLAS) $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) $(vendor_CLAPACK)      $(DESTDIR)$(builtin_libdir)
+	$(INSTALL_DATA) $(vendor_CLAPACK_BLAS) $(DESTDIR)$(builtin_libdir)
 	$(INSTALL_DATA) $(srcdir)/vendor/clapack/SRC/cblas.h $(DESTDIR)$(includedir)
 
 libs += $(vendor_CLAPACK) $(vendor_CLAPACK_BLAS)
@@ -153,6 +155,17 @@
 
 
 
+# Install libg2c, if it is present (the --with-g2c-copy configure
+# option will place a copy in $objdir/lib).
+install::
+	$(INSTALL) -d $(DESTDIR)$(libdir)
+	if test -f lib/libg2c.a; then					\
+	  $(INSTALL_DATA) lib/libg2c.a $(DESTDIR)$(builtin_libdir);	\
+	fi
+
+
+
+
 ########################################################################
 # FFTW Rules
 ########################################################################
@@ -207,10 +220,10 @@
 
 install:: $(vendor_FFTW_LIBS)
 	@echo "Installing FFTW"
-	$(INSTALL) -d $(DESTDIR)$(libdir)
+	$(INSTALL) -d $(DESTDIR)$(builtin_libdir)
 	@for lib in $(vendor_FFTW_LIBS); do \
-	  echo "$(INSTALL_DATA) $$lib  $(DESTDIR)$(libdir)"; \
-	  $(INSTALL_DATA) $$lib  $(DESTDIR)$(libdir); done
+	  echo "$(INSTALL_DATA) $$lib  $(DESTDIR)$(builtin_libdir)"; \
+	  $(INSTALL_DATA) $$lib  $(DESTDIR)$(builtin_libdir); done
 	$(INSTALL) -d $(DESTDIR)$(includedir)
 	$(INSTALL_DATA) src/fftw3.h $(DESTDIR)$(includedir)
 endif
Index: tests/test-random.hpp
===================================================================
--- tests/test-random.hpp	(revision 149215)
+++ tests/test-random.hpp	(working copy)
@@ -13,18 +13,55 @@
   Included Files
 ***********************************************************************/
 
+#define USE_VPP_RANDOM 1
+
 #include <vsip/support.hpp>
 #include <vsip/complex.hpp>
 #include <vsip/matrix.hpp>
 
+#if USE_VPP_RANDOM
+#  include <vsip/random.hpp>
+#endif
 
 
+
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
 
 /// Return a random value between -0.5 and +0.5
 
+#if USE_VPP_RANDOM
+
+/// Fill a matrix with random values.
+
+template <typename T,
+	  typename Block>
+void
+randm(vsip::Matrix<T, Block> m)
+{
+  vsip::Rand<T> rgen(1, true);
+
+  m = rgen.randu(m.size(0), m.size(1)) - T(0.5);
+}
+
+
+
+/// Fill a vector with random values.
+
+template <typename T,
+	  typename Block>
+void
+randv(vsip::Vector<T, Block> v)
+{
+  vsip::Rand<T> rgen(1, true);
+
+  v = rgen.randu(v.size()) - T(0.5);
+}
+
+#else // !USE_VPP_RANDOM
+
 template <typename T>
 struct Random
 {
@@ -71,5 +108,6 @@
   for (index_type i=0; i<v.size(0); ++i)
     v(i) = Random<T>::value();
 }
+#endif // USE_VPP_RANDOM
 
 #endif // VSIP_TESTS_TEST_RANDOM_HPP
Index: tests/fft.cpp
===================================================================
--- tests/fft.cpp	(revision 149215)
+++ tests/fft.cpp	(working copy)
@@ -11,7 +11,7 @@
 ***********************************************************************/
 
 // Set to 1 to enable verbose output.
-#define VERBOSE     1
+#define VERBOSE     0
 // Set to 0 to disble use of random values.
 #define FILL_RANDOM 1
 
@@ -39,8 +39,6 @@
 
 #if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_SAL_FFT)
 #  define TEST_2D_CC 1
-#else
-#  define TEST_2D_CC 1
 #endif
 
 #if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_SAL_FFT)
Index: tests/solver-lu.cpp
===================================================================
--- tests/solver-lu.cpp	(revision 149215)
+++ tests/solver-lu.cpp	(working copy)
@@ -27,13 +27,14 @@
 #include "solver-common.hpp"
 
 #define VERBOSE       0
+#define DO_ASSERT     1
 #define DO_SWEEP      0
 #define DO_BIG        1
 #define FILE_MATRIX_1 0
 
-#if VERBOSE
+#if VERBOSE > 0
 #  include <iostream>
-#  include <vsip/csl/output.hpp>
+#  include <vsip_csl/output.hpp>
 #  include "extdata-output.hpp"
 #endif
 
@@ -153,6 +154,17 @@
   scalar_type eps     = Precision_traits<scalar_type>::eps;
   scalar_type p_limit = scalar_type(20);
 
+#if VERBOSE >= 1
+  scalar_type cond = sv_s(0) / sv_s(n-1);
+  cout << "solve_lu<" << Type_name<T>::name() << ">("
+       << "rtm, "
+       << "a = (" << a.size(0) << ", " << a.size(1) << "), "
+       << "b = (" << b.size(0) << ", " << b.size(1) << ")):"
+       << endl
+       << "  a_norm_2 = " << a_norm_2 << endl
+       << "  cond     = " << cond << endl
+    ;
+#endif
   for (index_type i=0; i<p; ++i)
   {
     scalar_type residual_1 = norm_2((b - chk1).col(i));
@@ -162,24 +174,34 @@
     scalar_type residual_3 = norm_2((b - chk3).col(i));
     scalar_type err3       = residual_3 / (a_norm_2 * norm_2(x3.col(i)) * eps);
 
-#if VERBOSE
-    scalar_type cond = sv_s(0) / sv_s(n-1);
-    cout << "err " << i << " = "
+#if VERBOSE == 1
+    cout << "  " << i << ": err = "
 	 << err1 << ", " << err2 << ", " << err3
-	 << "  cond = " << cond
 	 << endl;
+#elif VERBOSE >= 2
+    cout << "  " << i << "-1: "
+	 << err1 << ", " << residual_1 << ", " << norm_2(x1.col(i)) 
+	 << endl;
+    cout << "  " << i << "-2: "
+	 << err2 << ", " << residual_2 << ", " << norm_2(x2.col(i)) 
+	 << endl;
+    cout << "  " << i << "-3: "
+	 << err3 << ", " << residual_3 << ", " << norm_2(x3.col(i)) 
+	 << endl;
 #endif
 
+#if DO_ASSERT
     test_assert(err1 < p_limit);
     test_assert(err2 < p_limit);
     test_assert(err3 < p_limit);
+#endif
 
     if (err1 > max_err1) max_err1 = err1;
     if (err2 > max_err2) max_err2 = err2;
     if (err3 > max_err3) max_err3 = err3;
   }
 
-#if VERBOSE
+#if VERBOSE >= 3
   cout << "a = " << endl << a << endl;
   cout << "x1 = " << endl << x1 << endl;
   cout << "x2 = " << endl << x2 << endl;
@@ -279,6 +301,18 @@
   scalar_type eps     = Precision_traits<scalar_type>::eps;
   scalar_type p_limit = scalar_type(20);
 
+#if VERBOSE >= 1
+  scalar_type cond = sv_s(0) / sv_s(n-1);
+  cout << "solve_lu_dist<" << Type_name<T>::name() << ">("
+       << "rtm, "
+       << "a = (" << a.size(0) << ", " << a.size(1) << "), "
+       << "b = (" << b.size(0) << ", " << b.size(1) << ")):"
+       << endl
+       << "  a_norm_2 = " << a_norm_2 << endl
+       << "  cond     = " << cond << endl
+    ;
+#endif
+
   for (index_type i=0; i<p; ++i)
   {
     scalar_type residual_1 = norm_2((b - chk1).col(i));
@@ -288,12 +322,20 @@
     scalar_type residual_3 = norm_2((b - chk3).col(i));
     scalar_type err3       = residual_3 / (a_norm_2 * norm_2(x3.col(i)) * eps);
 
-#if VERBOSE
-    scalar_type cond = sv_s(0) / sv_s(n-1);
-    cout << "err " << i << " = "
+#if VERBOSE == 1
+    cout << "  " << i << ": err = "
 	 << err1 << ", " << err2 << ", " << err3
-	 << "  cond = " << cond
 	 << endl;
+#elif VERBOSE >= 2
+    cout << "  " << i << "-1: "
+	 << err1 << ", " << residual_1 << ", " << norm_2(x1.col(i)) 
+	 << endl;
+    cout << "  " << i << "-2: "
+	 << err2 << ", " << residual_2 << ", " << norm_2(x2.col(i)) 
+	 << endl;
+    cout << "  " << i << "-3: "
+	 << err3 << ", " << residual_3 << ", " << norm_2(x3.col(i)) 
+	 << endl;
 #endif
 
     test_assert(err1 < p_limit);
@@ -305,7 +347,7 @@
     if (err3 > max_err3) max_err3 = err3;
   }
 
-#if VERBOSE
+#if VERBOSE >= 3
   cout << "a = " << endl << a << endl;
   cout << "x1 = " << endl << x1 << endl;
   cout << "x2 = " << endl << x2 << endl;
@@ -526,6 +568,15 @@
   Precision_traits<float>::compute_eps();
   Precision_traits<double>::compute_eps();
 
+#if VERBOSE >= 1
+  std::cout << "Precision_traits<float>::eps = "
+	    << Precision_traits<float>::eps 
+	    << std::endl;
+  std::cout << "Precision_traits<double>::eps = "
+	    << Precision_traits<double>::eps 
+	    << std::endl;
+#endif
+
 #if FILE_MATRIX_1
   test_lud_file<complex<float>, complex<double> >(
     "lu-a-complex-float-99x99.dat", "lu-b-complex-float-99x7.dat", 99, 7);
@@ -533,6 +584,7 @@
     "lu-a-complex-float-99x99.dat", "lu-b-complex-float-99x7.dat", 99, 7);
 #endif
 
+  test_lud_diag<complex<float> >(by_reference, 17, 3);
 
   lud_cases<float>           (by_reference);
   lud_cases<double>          (by_reference);
Index: configure.ac
===================================================================
--- configure.ac	(revision 149215)
+++ configure.ac	(working copy)
@@ -47,6 +47,16 @@
 AC_SUBST(suffix)
 AC_SUBST(svpp_library, "svpp")
 
+AC_ARG_WITH(builtin-libdir,
+  AS_HELP_STRING([--with-builtin-libdir=PATH],
+                 [Specify a separate path to install builtin libraries,
+ 	          such as ATLAS and FFTW, that is different from libdir.
+		  Defaults to libdir.]),
+  [builtin_libdir=$withval
+   LDFLAGS="$LDFLAGS -L$builtin_libdir"],
+  [builtin_libdir="\${libdir}"])
+AC_SUBST(builtin_libdir)
+
 ### Filename extensions. 
 AC_ARG_WITH(obj_ext,
   AS_HELP_STRING([--with-obj-ext=EXT],
@@ -158,6 +168,7 @@
                  [Omit support for FFT applied to long double elements.]),,
   [enable_fft_long_double=yes])
 
+
 AC_ARG_WITH(fftw3_cflags,
   AS_HELP_STRING([--with-fftw3-cflags=CFLAGS],
                  [Specify CFLAGS to use when building built-in FFTW3.
@@ -811,7 +822,6 @@
 
   LATE_LIBS="$FFTW3_LIBS $LATE_LIBS"
   CPPFLAGS="-I$includedir/fftw3 $CPPFLAGS"
-  LDFLAGS="-L$libdir/fftw3 $LDFLAGS"
 fi
 
 PAR_SERVICE=none
@@ -1097,10 +1107,10 @@
 	    [Define to use Mercury's SAL library to perform FFTs.])
       fi
       if test "$enable_fft_float" = yes; then
-	vsip_impl_fft_use_float=$vsip_impl_use_float
+	vsip_impl_fft_use_float=1
       fi
       if test "$enable_fft_double" = yes; then
-	vsip_impl_fft_use_double=$vsip_impl_use_double
+	vsip_impl_fft_use_double=1
       fi
     fi
 
@@ -1219,10 +1229,10 @@
       fi
 
       if test "$enable_fft_float" = yes; then
-	vsip_impl_fft_use_float=$vsip_impl_use_float
+	vsip_impl_fft_use_float=1
       fi
       if test "$enable_fft_double" = yes; then
-	vsip_impl_fft_use_double=$vsip_impl_use_double
+	vsip_impl_fft_use_double=1
       fi
     fi
   fi
@@ -1600,7 +1610,7 @@
 	INT_CPPFLAGS="-I$my_abs_top_srcdir/vendor/atlas/include $INT_CPPFLAGS"
 	INT_LDFLAGS="-L$curdir/vendor/atlas/lib $INT_LDFLAGS"
         CPPFLAGS="-I$includedir/atlas $keep_CPPFLAGS"
-        LDFLAGS="-L$libdir/atlas $keep_LDFLAGS"
+        LDFLAGS="$keep_LDFLAGS"
         LIBS="$keep_LIBS"
         lapack_use_ilaenv=0
         cblas_style="1"	# use cblas.h
@@ -1642,7 +1652,7 @@
 
       # flags that are used after install
       CPPFLAGS="$keep_CPPFLAGS -I$incdir/lapack"
-      LDFLAGS="$keep_LDFLAGS -L$libdir/lapack"
+      LDFLAGS="$keep_LDFLAGS"
       LATE_LIBS="$LATE_LIBS -llapack -lblas -lF77"
 
       AC_SUBST(BUILD_REF_CLAPACK, 1)   # Build clapack in vendor/clapack/SRC
Index: lib/GNUmakefile.inc.in
===================================================================
--- lib/GNUmakefile.inc.in	(revision 149215)
+++ lib/GNUmakefile.inc.in	(working copy)
@@ -16,15 +16,4 @@
 
 clean::
 
-# Install libraries in lib directory.  However, lib may be empty and not
-# every /bin/sh can deal with 'for file in ; do ...', in particular
-# Solaris 8.  We use justincase as a bogus entry just in case 'lib/*.a'
-# comes up empty.
-
 install::
-	$(INSTALL) -d $(DESTDIR)$(libdir)
-	for file in $(wildcard lib/*.a) justincase; do		\
-	  if test $$file != "justincase"; then			\
-	    $(INSTALL_DATA) $$file $(DESTDIR)$(libdir);		\
-	  fi; 							\
-	done
