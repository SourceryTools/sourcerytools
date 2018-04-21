Index: ChangeLog
===================================================================
--- ChangeLog	(revision 192285)
+++ ChangeLog	(working copy)
@@ -1,3 +1,7 @@
+2008-01-31  Jules Bergmann  <jules@codesourcery.com>
+
+	* scripts/config: Add missing SIMD configure flags in Mondo package.
+
 2008-01-30  Jules Bergmann  <jules@codesourcery.com>
 
 	* m4/lapack.m4: Detect ATLAS with v3 lapack/blas, as found on
Index: scripts/config
===================================================================
--- scripts/config	(revision 192274)
+++ scripts/config	(working copy)
@@ -522,7 +522,7 @@
         suffix = '-par-builtin-em64t-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
                    '--with-g2c-copy=%s'%g2c64,
-                  ] + builtin_fft_em64t + builtin_lapack_em64t + mpi + common_64 + shared_acconfig
+                  ] + builtin_fft_em64t + builtin_lapack_em64t + mpi + common_64 + simd + shared_acconfig
 
     class SerAMD64BuiltinRelease(Configuration):
 	builtin_libdir = 'amd64'
@@ -538,7 +538,7 @@
         suffix = '-ser-builtin-amd64-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
                    '--with-g2c-copy=%s'%g2c64,
-                  ] + builtin_fft_amd64 + builtin_lapack_amd64 + nompi + common_64 + shared_acconfig
+                  ] + builtin_fft_amd64 + builtin_lapack_amd64 + nompi + common_64 + simd + shared_acconfig
 
     class ParAMD64BuiltinRelease(Configuration):
 	builtin_libdir = 'amd64'
@@ -554,7 +554,7 @@
         suffix = '-par-builtin-amd64-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
                    '--with-g2c-copy=%s'%g2c64,
-                  ] + builtin_fft_amd64 + builtin_lapack_amd64 + mpi + common_64 + shared_acconfig
+                  ] + builtin_fft_amd64 + builtin_lapack_amd64 + mpi + common_64 + simd + shared_acconfig
 
     suffix = ''
     host = 'i686-pc-linux-gnu'
