Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.444
diff -u -r1.444 ChangeLog
--- ChangeLog	28 Apr 2006 21:25:04 -0000	1.444
+++ ChangeLog	28 Apr 2006 23:23:35 -0000
@@ -1,5 +1,13 @@
 2006-04-28  Jules Bergmann  <jules@codesourcery.com>
 
+	* configure.ac: Make sure src/vsip/impl subdirectories exist.
+	  Necessary to build synopsis documentation.
+	* doc/quickstart/quickstart.xml: Fix ending tag typo.
+	* scripts/config: Use --with-lapack=fortran-builtin for linux
+	  configurations.  Add configurations for sparc/solaris.
+	
+2006-04-28  Jules Bergmann  <jules@codesourcery.com>
+
 	* GNUmakefile.in (hdr): Include headers from fft, lapack, sal,
 	  ipp, fftw3 subdirectories of src/vsip/impl.
 	* configure.ac: Add tidying up MPI installation prefix in .pc file
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.94
diff -u -r1.94 configure.ac
--- configure.ac	28 Apr 2006 21:25:04 -0000	1.94
+++ configure.ac	28 Apr 2006 23:23:35 -0000
@@ -1682,7 +1682,14 @@
 AC_DEFINE_UNQUOTED(VSIP_IMPL_SIMD_TAG_LIST, $taglist,
           [Define to set whether or not to use Intel's IPP library.])
 
+# Make sure all src directories exist in the build tree, this is
+# necessary for synopsis document generation.
 mkdir -p src/vsip/impl/simd
+mkdir -p src/vsip/impl/lapack
+mkdir -p src/vsip/impl/sal
+mkdir -p src/vsip/impl/fft
+mkdir -p src/vsip/impl/fftw3
+mkdir -p src/vsip/impl/ipp
 
 
 #
Index: doc/quickstart/quickstart.xml
===================================================================
RCS file: /home/cvs/Repository/vpp/doc/quickstart/quickstart.xml,v
retrieving revision 1.28
diff -u -r1.28 quickstart.xml
--- doc/quickstart/quickstart.xml	28 Apr 2006 21:25:27 -0000	1.28
+++ doc/quickstart/quickstart.xml	28 Apr 2006 23:23:35 -0000
@@ -1346,13 +1346,13 @@
      parenthesis):
      <itemizedlist>
       <listitem><para>
-       Intel IPP (<filename>/opt/intel/ipp<filename>).
+       Intel IPP (<filename>/opt/intel/ipp</filename>).
       </para> </listitem>
       <listitem><para>
-       Intel MKL (<filename>/opt/intel/mkl<filename>).
+       Intel MKL (<filename>/opt/intel/mkl</filename>).
       </para> </listitem>
       <listitem><para>
-       MPICH (Solaris only) (<filename>/opt/intel/mkl<filename>).
+       MPICH (Solaris only) (<filename>/opt/intel/mkl</filename>).
       </para> </listitem>
      </itemizedlist>
     </para>
Index: scripts/config
===================================================================
RCS file: /home/cvs/Repository/vpp/scripts/config,v
retrieving revision 1.11
diff -u -r1.11 config
--- scripts/config	22 Jan 2006 09:02:24 -0000	1.11
+++ scripts/config	28 Apr 2006 23:23:35 -0000
@@ -37,6 +37,9 @@
 # Parallel Builtin em64t  64_em64t
 # Parallel Builtin amd64  64_amd64
 # Parallel Intel   64     64_generic
+#
+# Serial   Builtin sparc  sparc
+# Parallel Builtin sparc  sparc
 
 
 ########################################################################
@@ -80,14 +83,14 @@
 builtin_fft_em64t = ['--with-fft=builtin']
 builtin_fft_amd64 = ['--with-fft=builtin']
 
-builtin_lapack_32 = ['--with-lapack=builtin',
+builtin_lapack_32 = ['--with-lapack=fortran-builtin',
 		     '--with-atlas-tarball=/home/jules/csl/atlas/atlas3.6.0_Linux_P4SSE2.tar.gz',
 	             '--with-atlas-cfg-opts="--with-mach=P4 --with-isa=SSE2 --with-int-type=int --with-string-convention=sun"']
 
-builtin_lapack_em64t = ['--with-lapack=builtin',
+builtin_lapack_em64t = ['--with-lapack=fortran-builtin',
 	             '--with-atlas-cfg-opts="--with-mach=P4E64 --with-isa=SSE3 --with-int-type=int --with-string-convention=sun"']
 
-builtin_lapack_amd64 = ['--with-lapack=builtin',
+builtin_lapack_amd64 = ['--with-lapack=fortran-builtin',
 		        '--with-atlas-tarball=/home/jules/csl/atlas/atlas3.6.0_Linux_HAMMER64SSE2.tar.gz',
 	             '--with-atlas-cfg-opts="--with-mach=HAMMER64 --with-isa=SSE2 --with-int-type=int --with-string-convention=sun"']
 
@@ -326,3 +329,71 @@
     host = 'em64t'
     release = Release
     debug = Debug
+
+
+
+########################################################################
+# SPARC/Solaris Compiler flags
+########################################################################
+
+flags_sparc = ['-mcpu=ultrasparc']
+
+
+
+########################################################################
+# SPARC/Solaris Configure flags
+########################################################################
+
+common_sparc = ['--enable-profile-timer=posix']
+
+builtin_fft_sparc    = ['--with-fft=builtin']
+
+builtin_lapack_sparc = ['--with-lapack=builtin',
+		        '--with-atlas-cfg-opts="--with-mach=SunUS2 --with-int-type=int --with-string-convention=sun"']
+
+mpi_sparc = ['--enable-mpi --with-mpi-prefix=/usr/local/mpich']
+
+# Use builtin clapack on solaris.  We don't have 3.4 g77 installed (060428).
+
+class SerialBuiltinSparc(Package):
+
+    class Release(Configuration):
+        suffix = ''
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_sparc),
+                   'CFLAGS="%s"'%' '.join(flags_sparc),
+                   'LDFLAGS="%s"'%' '.join(flags_sparc)
+                  ] + builtin_fft_sparc + builtin_lapack_sparc + nompi + common_sparc
+
+    class Debug(Configuration):
+        suffix = '-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   'CFLAGS="%s"'%' '.join(debug),
+                   'LDFLAGS="%s"'%' '.join(debug),
+                  ] + builtin_fft_sparc + builtin_lapack_sparc + nompi + common_sparc
+
+    suffix = '-serial-builtin'
+    host = 'sparc'
+    release = Release
+    debug = Debug
+
+
+class ParallelBuiltinSparc(Package):
+
+    class Release(Configuration):
+        suffix = ''
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_sparc),
+                   'CFLAGS="%s"'%' '.join(flags_sparc),
+                   'LDFLAGS="%s"'%' '.join(flags_sparc)
+                  ] + builtin_fft_sparc + builtin_lapack_sparc + mpi_sparc + common_sparc
+
+    class Debug(Configuration):
+        suffix = '-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   'CFLAGS="%s"'%' '.join(debug),
+                   'LDFLAGS="%s"'%' '.join(debug),
+                  ] + builtin_fft_sparc + builtin_lapack_sparc + mpi_sparc + common_sparc
+
+    suffix = '-serial-builtin'
+    host = 'sparc'
+    release = Release
+    debug = Debug
