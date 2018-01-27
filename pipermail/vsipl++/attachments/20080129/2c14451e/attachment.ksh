Index: ChangeLog
===================================================================
--- ChangeLog	(revision 192236)
+++ ChangeLog	(working copy)
@@ -1,4 +1,13 @@
 2008-01-29  Jules Bergmann  <jules@codesourcery.com>
+
+	* scripts/package.py (prefix-not-in-tarball): New option to allow
+	  part of installation prefix to be excluded from the tarball path.
+	* scripts/release.sh: Adjust prefix to /opt/sourceryvsipl++-VERSION.
+	* scripts/config: Adjust configure parameters that have been
+	  renamed.  Adjust host names.  Add Power (powerpc-linux-gnu)
+	  binary package. 
+
+2008-01-29  Jules Bergmann  <jules@codesourcery.com>
 	
 	* doc/quickstart/quickstart.xml: Fix bogus PKG_CONFIG_PATH.
 
Index: scripts/package.py
===================================================================
--- scripts/package.py	(revision 191870)
+++ scripts/package.py	(working copy)
@@ -85,6 +85,7 @@
 parameters['builddir'] = 'vpp-build'
 parameters['distdir'] = 'vpp-dist'
 parameters['prefix'] = '/usr/local'
+parameters['prefix-not-in-tarball'] = ''
 parameters['configfile'] = ''
 parameters['suffix'] = ''
 parameters['maintainer_mode'] = True
@@ -161,7 +162,7 @@
             configure('--enable-maintainer-mode', '--enable-fft=')
             announce('build docs...')
             try:
-                spawn(['sh', '-c', 'make doc2src'])
+                spawn(['sh', '-c', 'make doc2src_noapi'])
             finally:
                 announce('done building docs.')
         else:
@@ -182,6 +183,7 @@
     builddir = parameters['builddir']
     abs_distdir = parameters['abs_distdir']
     prefix = parameters['prefix']
+    prefix_not_in_tarball = parameters['prefix-not-in-tarball']
     suffix = parameters['suffix']
     host = parameters['host']
     pkgconfig_dir = '%s/%s/lib/pkgconfig/'%(abs_distdir,prefix)
@@ -231,7 +233,7 @@
             os.chdir(cwd)
 
         os.chdir(builddir)
-        cmd = 'make bdist packagesuffix=%s DESTDIR=%s'%(suffix, abs_distdir)
+        cmd = 'make bdist packagesuffix=%s DESTDIR=%s/%s'%(suffix, abs_distdir, prefix_not_in_tarball)
         if host:
             cmd += ' host=%s'%host
         if parameters.get('version'):
@@ -254,6 +256,7 @@
     abs_builddir = parameters['abs_builddir']
     abs_distdir = parameters['abs_distdir']
     prefix = parameters['prefix']
+    prefix_not_in_tarball = parameters['prefix-not-in-tarball']
     host = parameters['host']
     if not os.path.exists(srcdir):
         print 'srcdir does not exist: %s'%srcdir
@@ -267,8 +270,8 @@
         # Dummy configuration to set up the test database
         configure('--enable-maintainer-mode', '--enable-fft=',
                   '--with-lapack=no')
-        os.makedirs(abs_distdir)
-        os.chdir(abs_distdir)
+        os.makedirs('%s/%s' % (abs_distdir, prefix_not_in_tarball))
+        os.chdir('%s/%s' % (abs_distdir, prefix_not_in_tarball))
         spawn(['tar', 'xvfj', abs_packagefile])
         os.chdir(abs_builddir)
         # Don't use 'os.path.join' here
@@ -345,6 +348,7 @@
                                 'builddir=',
                                 'distdir=',
                                 'prefix=',
+                                'prefix-not-in-tarball=',
                                 'config=',
                                 'configfile=',
                                 'configdir=',
@@ -364,6 +368,8 @@
             parameters['distdir'] = a
         elif o == '--prefix':
             parameters['prefix'] = a
+        elif o == '--prefix-not-in-tarball':
+            parameters['prefix-not-in-tarball'] = a
         elif o == '--package':
             parameters['package'] = a
         elif o == '--packagefile':
Index: scripts/release.sh
===================================================================
--- scripts/release.sh	(revision 191870)
+++ scripts/release.sh	(working copy)
@@ -46,7 +46,7 @@
 distdir="vpp-dist"
 debug="yes"
 pkg_opts=""
-version="1.3"
+version="1.4"
 host=`hostname`
 
 while getopts "w:c:d:p:C:t:D:T:sS:v:" arg; do
@@ -87,7 +87,12 @@
 
 srcdir="sourceryvsipl++-$version"
 srcpkg="$srcdir.tar.bz2"
+prefix="/opt/sourceryvsipl++-$version"
+prefix_not_in_tarball="/opt"
 
+pkg_opts="$pkg_opts --prefix=$prefix"
+pkg_opts="$pkg_opts --prefix-not-in-tarball=$prefix_not_in_tarball"
+
 package=$dir/scripts/package.py
 if test "$cfgdir" = "default"; then
   cfgdir=$dir/scripts
@@ -152,7 +157,7 @@
   LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$GCCTOOL_DIR/lib/sparcv9
 fi
 
-if test `hostname` = "gillette"; then
+if test `hostname` = "gillette" -o `hostname` = "wesleysnipes"; then
   LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/tools/sdk/lib
   LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/scratch/jules/cell-sdk/sysroot/usr/lib
 fi
@@ -252,6 +257,7 @@
 	--configfile=$cfgfile					\
 	--configdir="$dir/scripts"				\
 	--builddir=$builddir					\
+	$pkg_opts						\
 	--package=$pkg 2>&1 > log-test-$pkg
   done
 fi
Index: scripts/config
===================================================================
--- scripts/config	(revision 191870)
+++ scripts/config	(working copy)
@@ -122,8 +122,8 @@
 	             '--with-atlas-cfg-opts="--with-mach=HAMMER64 --with-isa=SSE2 --with-int-type=int --with-string-convention=sun"']
 
 
-nompi = ['--disable-mpi']
-mpi = ['--enable-mpi']
+nompi = ['--disable-parallel']
+mpi = ['--enable-parallel']
 
 mkl_32 = ['--with-mkl-prefix=%s'%mkl_dir, '--with-mkl-arch=32']
 mkl_64 = ['--with-mkl-prefix=%s'%mkl_dir, '--with-mkl-arch=em64t']
@@ -131,14 +131,14 @@
 
 # Reference Implementation
 
-ref_impl = [ '--enable-ref-impl',
+ref_impl = [ '--enable-only-ref-impl',
              '--with-cvsip-prefix=%s'%cvsip_dir,
 	     '--with-lapack=no']
 
 
 # C-VSIP BE, non reference implementation
 
-cvsip_be = [ '--enable-cvsip',
+cvsip_be = [ '--with-cvsip',
              '--with-cvsip-prefix=%s'%cvsip_dir,
 	     '--with-lapack=no',
 	     '--enable-fft=cvsip,no_fft' ]
@@ -149,12 +149,45 @@
 # Mondo Packages
 ########################################################################
 
+class MondoQuickTest(Package):
+
+    class Par64IntelRelease(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/par-intel'
+        suffix = '-par-intel-64'
+        tests_ids = 'ref-impl'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic),
+                   '--with-g2c-copy=%s'%g2c64,
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir,
+	           '--enable-fft=ipp'
+		  ] + mkl_64 + mpi + common_64 + simd
+
+    class Par64IntelDebug(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/par-intel-debug'
+        suffix = '-par-intel-64-debug'
+        tests_ids = 'ref-impl'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   '--with-g2c-copy=%s'%g2c64,
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir,
+	           '--enable-fft=ipp'
+		  ] + mkl_64 + mpi + common_64 + simd
+
+    suffix = ''
+    host = 'i686-pc-linux-gnu'
+
+    par_64_intel_release      = Par64IntelRelease
+    par_64_intel_debug        = Par64IntelDebug
+
+
+
 class MondoTest(Package):
 
     class Par64IntelRelease(Configuration):
 	builtin_libdir = 'em64t'
 	libdir = 'em64t/par-intel'
         suffix = '-par-intel-64'
+        tests_ids = 'ref-impl'
         options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic),
                    '--with-g2c-copy=%s'%g2c64,
                    '--with-ipp-prefix=%s/em64t'%ipp_dir,
@@ -165,6 +198,7 @@
 	builtin_libdir = 'em64t'
 	libdir = 'em64t/par-intel-debug'
         suffix = '-par-intel-64-debug'
+        tests_ids = 'ref-impl'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
                    '--with-g2c-copy=%s'%g2c64,
                    '--with-ipp-prefix=%s/em64t'%ipp_dir,
@@ -175,6 +209,7 @@
 	builtin_libdir = 'em64t'
 	libdir = 'em64t/par-builtin'
         suffix = '-par-builtin-em64t'
+        tests_ids = 'ref-impl'
         options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_em64t),
                    '--with-g2c-copy=%s'%g2c64,
                   ] + builtin_fft_em64t + builtin_lapack_em64t + mpi + common_64 + simd
@@ -183,12 +218,13 @@
 	builtin_libdir = 'em64t'
 	libdir = 'em64t/par-builtin-debug'
         suffix = '-par-builtin-em64t-debug'
+        tests_ids = 'ref-impl'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
                    '--with-g2c-copy=%s'%g2c64,
                   ] + builtin_fft_em64t + builtin_lapack_em64t + mpi + common_64
 
-    suffix = '-linux'
-    host = 'x86'
+    suffix = ''
+    host = 'i686-pc-linux-gnu'
 
     par_64_intel_release      = Par64IntelRelease
     par_64_intel_debug        = Par64IntelDebug
@@ -237,8 +273,8 @@
         options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic)
                   ] + ref_impl + nompi + common_64
 
-    suffix = '-linux'
-    host = 'x86'
+    suffix = ''
+    host = 'i686-pc-linux-gnu'
 
     par_64_refimpl_debug      = Par64RefImplDebug
     par_64_refimpl_release    = Par64RefImplRelease
@@ -307,8 +343,8 @@
                   ] + builtin_fft_em64t + builtin_lapack_em64t + nompi + common_64 + simd
 
 
-    suffix = '-linux'
-    host = 'x86'
+    suffix = ''
+    host = 'i686-pc-linux-gnu'
   
     ser_32_intel_debug        = Ser32IntelDebug
     ser_64_intel_release      = Ser64IntelRelease
@@ -356,8 +392,8 @@
         options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic)
 		  ] + cvsip_be + nompi + common_64
 
-    suffix = '-linux'
-    host = 'x86'
+    suffix = ''
+    host = 'i686-pc-linux-gnu'
 
 
 
@@ -518,8 +554,8 @@
                    '--with-g2c-copy=%s'%g2c64,
                   ] + builtin_fft_amd64 + builtin_lapack_amd64 + mpi + common_64
 
-    suffix = '-linux'
-    host = 'x86'
+    suffix = ''
+    host = 'i686-pc-linux-gnu'
   
     ser_32_intel_release      = Ser32IntelRelease
     ser_32_intel_debug        = Ser32IntelDebug
@@ -542,6 +578,95 @@
 
 
 ########################################################################
+# Power Package
+#
+# Distribution: Fedora 7
+#
+# Required Packages:
+#  - atlas
+#  - fftw3
+#  - openmpi
+########################################################################
+
+power_cc     = 'gcc'
+power_cxx    = 'g++'
+power_common = ['--enable-timer=power_tb',
+	        '--with-complex=split',
+		'--enable-fft=fftw3',
+		'--with-lapack=atlas',
+		'--with-atlas-include=/usr/include/atlas',
+		'--with-atlas-libdir=/usr/lib/altivec',
+	        '--disable-fft-long-double']
+
+
+power32_mpi_dir = '/usr/local/tools/sdk'
+power32_flags_generic = ['-m32', '-maltivec']
+power32_mpi = ['--enable-mpi=openmpi']
+
+class Power(Package):
+    class Ser32Release(Configuration):
+	builtin_libdir = 'ppc32'
+	libdir         = 'ppc32/ser'
+        suffix = '-32-ser'
+        tests_ids = 'ref-impl'
+        options = ['CC=%s'%power_cc,
+	           'CXX=%s'%power_cxx,
+	           'CXXFLAGS="%s"'%' '.join(release + power32_flags_generic),
+                   'CFLAGS="%s"'%' '.join(['-O2'] + power32_flags_generic),
+                   'FFLAGS="%s"'%' '.join(power32_flags_generic),
+                   'LDFLAGS="%s"'%' '.join(power32_flags_generic),
+                  ] + nompi + power_common + simd
+
+    class Ser32Debug(Configuration):
+	builtin_libdir = 'ppc32'
+	libdir         = 'ppc32/ser-debug'
+        suffix = '-32-ser-debug'
+        tests_ids = 'ref-impl'
+        options = ['CC=%s'%power_cc,
+	           'CXX=%s'%power_cxx,
+	           'CXXFLAGS="%s"'%' '.join(power32_flags_generic),
+                   'CFLAGS="%s"'%' '.join(power32_flags_generic),
+                   'FFLAGS="%s"'%' '.join(power32_flags_generic),
+                   'LDFLAGS="%s"'%' '.join(power32_flags_generic),
+                  ] + nompi + power_common + simd
+
+    class Par32Release(Configuration):
+	builtin_libdir = 'ppc32'
+	libdir         = 'ppc32/par'
+        suffix = '-32-par'
+        tests_ids = 'ref-impl'
+        options = ['CC=%s'%power_cc,
+	           'CXX=%s'%power_cxx,
+	           'CXXFLAGS="%s"'%' '.join(release + power32_flags_generic),
+                   'CFLAGS="%s"'%' '.join(['-O2'] + power32_flags_generic),
+                   'FFLAGS="%s"'%' '.join(power32_flags_generic),
+                   'LDFLAGS="%s"'%' '.join(power32_flags_generic),
+                  ] + power32_mpi + power_common + simd
+
+    class Par32Debug(Configuration):
+	builtin_libdir = 'ppc32'
+	libdir         = 'ppc32/par-debug'
+        suffix = '-32-par-debug'
+        tests_ids = 'ref-impl'
+        options = ['CC=%s'%power_cc,
+	           'CXX=%s'%power_cxx,
+	           'CXXFLAGS="%s"'%' '.join(power32_flags_generic),
+                   'CFLAGS="%s"'%' '.join(power32_flags_generic),
+                   'FFLAGS="%s"'%' '.join(power32_flags_generic),
+                   'LDFLAGS="%s"'%' '.join(power32_flags_generic),
+                  ] + power32_mpi + power_common + simd
+
+    suffix = ''
+    host = 'powerpc-linux-gnu'
+  
+    ser_32_relase     = Ser32Release
+    ser_32_debug      = Ser32Debug
+    par_32_relase     = Par32Release
+    par_32_debug      = Par32Debug
+
+
+
+########################################################################
 # Cell BE Package
 ########################################################################
 
@@ -624,8 +749,8 @@
 		   '--with-lapack=no',
                   ] + cbe32_mpi + cbe_common + simd
 
-    suffix = '-linux'
-    host = 'cbe'
+    suffix = ''
+    host = 'cbe-linux-gnu'
   
     ser_32_relase     = Ser32Release
     ser_32_debug      = Ser32Debug
@@ -693,9 +818,8 @@
 		   '--with-fftw3-cflags=-O2',
 		   '--with-complex=split',
 		   '--with-lapack=no',
-		   '--enable-sal',
-		   '--disable-mpi',
-		   '--disable-pas',
+		   '--with-sal',
+		   '--disable-parallel',
 		   '--disable-simd-loop-fusion',
 		   '--disable-exceptions',
 		   '--with-qmtest-commandhost=xrun.sh',
@@ -718,9 +842,8 @@
 		   '--with-fftw3-cflags=-O2',
 		   '--with-complex=split',
 		   '--with-lapack=no',
-		   '--enable-sal',
-		   '--disable-mpi',
-		   '--disable-pas',
+		   '--with-sal',
+		   '--disable-parallel',
 		   '--disable-simd-loop-fusion',
 		   '--disable-exceptions',
 		   '--with-qmtest-commandhost=xrun.sh',
@@ -743,9 +866,8 @@
 		   '--with-fftw3-cflags=-O2',
 		   '--with-complex=split',
 		   '--with-lapack=no',
-		   '--enable-sal',
-		   '--disable-mpi',
-		   '--enable-pas',
+		   '--with-sal',
+		   '--enable-parallel=pas',
 		   '--disable-simd-loop-fusion',
 		   '--disable-exceptions',
 		   '--with-qmtest-commandhost=xrun-pas.sh',
@@ -768,9 +890,8 @@
 		   '--with-fftw3-cflags=-O2',
 		   '--with-complex=split',
 		   '--with-lapack=no',
-		   '--enable-sal',
-		   '--disable-mpi',
-		   '--enable-pas',
+		   '--with-sal',
+		   '--enable-parallel=pas',
 		   '--disable-simd-loop-fusion',
 		   '--disable-exceptions',
 		   '--with-qmtest-commandhost=xrun.sh',
@@ -778,8 +899,8 @@
 		   '--with-builtin-simd-routines=generic',
                   ] + common_mcoe
 
-    suffix = '-mcoe'
-    host = 'ppc'
+    suffix = ''
+    host = 'powerpc-mcoe'
 
 
 
@@ -798,10 +919,9 @@
                    'CFLAGS="%s"'%' '.join(flags_32_p4sse2),
                    'FFLAGS="%s"'%' '.join(flags_32_p4sse2),
                    'LDFLAGS="%s"'%' '.join(flags_32_p4sse2),
-		   '--enable-pas',
-		   '--enable-sal',
+		   '--enable-parallel=pas',
+		   '--with-sal',
 		   '--with-sal-lib=%s/lib'%pas_dir,
-		   '--disable-mpi',
 		   '--with-lapack=no',
 		   '--enable-fft=sal,builtin',
 		   '--with-complex=split',
@@ -817,10 +937,9 @@
                    'CFLAGS="%s"'%' '.join(flags_32_p4sse2),
                    'FFLAGS="%s"'%' '.join(flags_32_p4sse2),
                    'LDFLAGS="%s"'%' '.join(flags_32_p4sse2),
-		   '--enable-pas',
-		   '--enable-sal',
+		   '--enable-parallel=pas',
+		   '--with-sal',
 		   '--with-sal-lib=%s/lib'%pas_dir,
-		   '--disable-mpi',
 		   '--with-lapack=no',
 		   '--enable-fft=sal,builtin',
 		   '--with-complex=split',
@@ -828,7 +947,7 @@
                   ] + common_32 + simd
 
     suffix = '-pas-split'
-    host = 'i686'
+    host = 'i686-pc-linux-gnu'
     release = Release
     debug = Debug
 
