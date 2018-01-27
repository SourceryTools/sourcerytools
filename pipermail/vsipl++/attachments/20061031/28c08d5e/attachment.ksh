Index: ChangeLog
===================================================================
--- ChangeLog	(revision 152563)
+++ ChangeLog	(working copy)
@@ -1,3 +1,11 @@
+2006-10-31  Jules Bergmann  <jules@codesourcery.com>
+
+	PAS for Linux binary package (for testing purposes).
+	* scripts/package.py: Update path to acconfig.hpp.
+	* scripts/config: Add binary package for PAS.  Update x86 test
+	  package.
+	* scripts/release.sh: Add paths for PAS.
+	
 2006-10-27  Jules Bergmann  <jules@codesourcery.com>
 
 	Add support for QMtest CommandHost target.
Index: scripts/package.py
===================================================================
--- scripts/package.py	(revision 152549)
+++ scripts/package.py	(working copy)
@@ -194,7 +194,7 @@
             spawn(['sh', '-c', 'make install DESTDIR=%s'%abs_distdir])
 
             # Make copy of acconfig for later perusal.
-            spawn(['sh', '-c', 'cp %s/usr/local/include/vsip/impl/acconfig.hpp ../acconfig%s%s.hpp'%(abs_distdir,suffix,s)])
+            spawn(['sh', '-c', 'cp %s/usr/local/include/vsip/core/acconfig.hpp ../acconfig%s%s.hpp'%(abs_distdir,suffix,s)])
 
             # Make symlink to variant' vsipl++.pc.
             os.chdir(pkgconfig_dir)
Index: scripts/config
===================================================================
--- scripts/config	(revision 152549)
+++ scripts/config	(working copy)
@@ -115,6 +115,8 @@
 ipp_dir = '/opt/intel/ipp'
 mkl_dir = '/opt/intel/mkl721'
 
+pas_dir = '/usr/local/tools/vpp-1.0/pas'
+
 mkl_32 = ['--with-mkl-prefix=%s'%mkl_dir, '--with-mkl-arch=32']
 mkl_64 = ['--with-mkl-prefix=%s'%mkl_dir, '--with-mkl-arch=em64t']
 
@@ -124,27 +126,50 @@
 
 class MondoTest(Package):
 
-    class Ser64IntelDebug(Configuration):
+    class Par64IntelRelease(Configuration):
 	builtin_libdir = 'em64t'
-	libdir         = 'em64t/ser-intel-debug'
-        suffix = '-ser-intel-64-debug'
+	libdir = 'em64t/par-intel'
+        suffix = '-par-intel-64'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic),
+                   '--with-g2c-copy=%s'%g2c64,
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir,
+	           '--enable-fft=ipp,builtin'
+		  ] + builtin_fft_em64t_opts + mkl_64 + mpi + common_64 + simd
+
+    class Par64IntelDebug(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/par-intel-debug'
+        suffix = '-par-intel-64-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
                    '--with-g2c-copy=%s'%g2c64,
                    '--with-ipp-prefix=%s/em64t'%ipp_dir,
 	           '--enable-fft=ipp,builtin'
-		  ] + builtin_fft_em64t_opts + mkl_64 + nompi + common_64 + simd
+		  ] + builtin_fft_em64t_opts + mkl_64 + mpi + common_64 + simd
 
-    class SerEM64TBuiltinDebug(Configuration):
+    class ParEM64TBuiltinRelease(Configuration):
 	builtin_libdir = 'em64t'
-	libdir         = 'em64t/ser-builtin-debug'
-        suffix = '-ser-builtin-em64t-debug'
+	libdir = 'em64t/par-builtin'
+        suffix = '-par-builtin-em64t'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_em64t),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_em64t + builtin_lapack_em64t + mpi + common_64 + simd
+
+    class ParEM64TBuiltinDebug(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/par-builtin-debug'
+        suffix = '-par-builtin-em64t-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
                    '--with-g2c-copy=%s'%g2c64,
-                  ] + builtin_fft_em64t + builtin_lapack_em64t + nompi + common_64 + simd
+                  ] + builtin_fft_em64t + builtin_lapack_em64t + mpi + common_64
 
-    ser_64_intel_debug      = Ser64IntelDebug
-    ser_em64t_builtin_debug = SerEM64TBuiltinDebug
+    suffix = '-linux'
+    host = 'x86'
 
+    par_64_intel_release      = Par64IntelRelease
+    par_64_intel_debug        = Par64IntelDebug
+    par_em64t_builtin_release = ParEM64TBuiltinRelease
+    par_em64t_builtin_debug   = ParEM64TBuiltinDebug
+
 class Mondo(Package):
 
     class Ser32IntelRelease(Configuration):
@@ -251,8 +276,6 @@
                    '--with-g2c-copy=%s'%g2c64,
                   ] + builtin_fft_em64t + builtin_lapack_em64t + nompi + common_64 + simd
 
-    suffix = '-builtin'
-    host = 'x86'
 
     class ParEM64TBuiltinRelease(Configuration):
 	builtin_libdir = 'em64t'
@@ -324,7 +347,59 @@
     par_amd64_builtin_debug   = ParAMD64BuiltinDebug
 
 
+
 ########################################################################
+# Test Packages
+########################################################################
+
+class PasSplit32(Package):
+
+    class Release(Configuration):
+	builtin_libdir = 'x86-pas'
+	libdir = 'x86-pas/split'
+        suffix = '-pas-split-32'
+        options = ['PKG_CONFIG_PATH=%s/lib/pkgconfig'%pas_dir,
+		   'CXXFLAGS="%s"'%' '.join(debug + flags_32_p4sse2),
+                   'CFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   'FFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   'LDFLAGS="%s"'%' '.join(flags_32_p4sse2),
+		   '--enable-pas',
+		   '--enable-sal',
+		   '--with-sal-lib=%s/lib'%pas_dir,
+		   '--disable-mpi',
+		   '--with-lapack=no',
+		   '--enable-fft=sal,builtin',
+		   '--with-complex=split',
+		   '--with-qmtest-command=test-pas.sh',
+                  ] + common_32 + simd
+
+    class Debug(Configuration):
+	builtin_libdir = 'x86-pas'
+	libdir = 'x86-pas/split-debug'
+        suffix = '-pas-split-32-debug'
+        options = ['PKG_CONFIG_PATH=%s/lib/pkgconfig'%pas_dir,
+		   'CXXFLAGS="%s"'%' '.join(debug + flags_32_p4sse2),
+                   'CFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   'FFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   'LDFLAGS="%s"'%' '.join(flags_32_p4sse2),
+		   '--enable-pas',
+		   '--enable-sal',
+		   '--with-sal-lib=%s/lib'%pas_dir,
+		   '--disable-mpi',
+		   '--with-lapack=no',
+		   '--enable-fft=sal,builtin',
+		   '--with-complex=split',
+		   '--with-qmtest-command=test-pas.sh',
+                  ] + common_32 + simd
+
+    suffix = '-pas-split'
+    host = 'i686'
+    release = Release
+    debug = Debug
+
+
+
+########################################################################
 # Single Packages
 ########################################################################
 
Index: scripts/release.sh
===================================================================
--- scripts/release.sh	(revision 152549)
+++ scripts/release.sh	(working copy)
@@ -116,6 +116,7 @@
 
 ipp_dir=/opt/intel/ipp
 mkl_dir=/opt/intel/mkl
+pas_dir=$TOOL_DIR/pas
 
 PATH=$TOOL_DIR/sourceryg++/bin
 PATH=$PATH:$TOOL_DIR/bin
@@ -125,6 +126,7 @@
 PATH=$PATH:/usr/local/bin
 PATH=$PATH:$DOT_DIR/bin
 PATH=$PATH:/opt/renderx/xep
+PATH=$PATH:$pas_dir/bin
 if test `hostname` = "gannon.codesourcery.com"; then
   PATH=$PATH:/home/jules/local/sun4/bin
 fi
@@ -142,6 +144,7 @@
 LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ipp_dir/ia32_itanium/sharedlib/linux32
 LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$mkl_dir/lib/em64t
 LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$mkl_dir/lib/32
+LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$pas_dir/lib
 if test `hostname` = "gannon.codesourcery.com"; then
   LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$GCCTOOL_DIR/lib
   LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$GCCTOOL_DIR/lib/sparcv9
