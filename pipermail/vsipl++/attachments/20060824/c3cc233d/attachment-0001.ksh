Index: scripts/config
===================================================================
--- scripts/config	(revision 147601)
+++ scripts/config	(working copy)
@@ -29,17 +29,17 @@
 #
 # PACKAGE                 FLAGS
 # Serial   Builtin 32     32_p4sse2
-# Serial   Builtin em64t  64_em64t
-# Serial   Builtin amd64  64_amd64
+# Serial   Builtin EM64T  64_em64t
+# Serial   Builtin AMD64  64_amd64
 # Serial   Intel   32     32_generic
 # Serial   Intel   64     64_generic
 #
-# Parallel Builtin em64t  64_em64t
-# Parallel Builtin amd64  64_amd64
+# Parallel Builtin EM64T  64_em64t
+# Parallel Builtin AMD64  64_amd64
 # Parallel Intel   64     64_generic
 #
-# Serial   Builtin sparc  sparc
-# Parallel Builtin sparc  sparc
+# Serial   Builtin Sparc  sparc
+# Parallel Builtin Sparc  sparc
 
 
 ########################################################################
@@ -73,6 +73,8 @@
 common_32 = ['--enable-timer=pentiumtsc']
 common_64 = ['--enable-timer=x86_64_tsc']
 
+profile = ['--enable-profiler=all']
+
 cross = ['--host=i686-pc-linux-gnu',
          '--build=x86_64-unknown-linux-gnu',
          '--target=i686-pc-linux-gnu']
@@ -119,6 +121,15 @@
                    '--with-g2c-copy=%s'%g2c32
                   ] + builtin_fft_32 + builtin_lapack_32 + nompi + common_32
 
+    class Profile(Configuration):
+        suffix = '-profile'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_32_p4sse2),
+                   'CFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   'FFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   'LDFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   '--with-g2c-copy=%s'%g2c32
+                  ] + builtin_fft_32 + builtin_lapack_32 + nompi + common_32 + profile
+
     class Debug(Configuration):
         suffix = '-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug + m32),
@@ -141,6 +152,12 @@
                    '--with-g2c-copy=%s'%g2c64,
                   ] + builtin_fft_em64t + builtin_lapack_em64t + nompi + common_64
 
+    class Profile(Configuration):
+        suffix = '-profile'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_em64t),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_em64t + builtin_lapack_em64t + nompi + common_64 + profile
+
     class Debug(Configuration):
         suffix = '-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
@@ -160,6 +177,12 @@
                    '--with-g2c-copy=%s'%g2c64,
                   ] + builtin_fft_amd64 + builtin_lapack_amd64 + nompi + common_64
 
+    class Profile(Configuration):
+        suffix = '-profile'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_amd64),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_amd64 + builtin_lapack_amd64 + nompi + common_64 + profile
+
     class Debug(Configuration):
         suffix = '-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
@@ -183,6 +206,16 @@
                    '--with-ipp-prefix=%s/ia32_itanium'%ipp_dir, '--enable-fft=ipp'
                   ] + mkl_32 + nompi + common_32
 
+    class Profile(Configuration):
+        suffix = '-profile'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_32_generic),
+                   'CFLAGS="%s"'%' '.join(flags_32_generic),
+                   'FFLAGS="%s"'%' '.join(flags_32_generic),
+                   'LDFLAGS="%s"'%' '.join(flags_32_generic),
+                   '--with-g2c-copy=%s'%g2c32,
+                   '--with-ipp-prefix=%s/ia32_itanium'%ipp_dir, '--enable-fft=ipp'
+                  ] + mkl_32 + nompi + common_32 + profile
+
     class Debug(Configuration):
         suffix = '-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug + m32),
@@ -207,6 +240,13 @@
                    '--with-ipp-prefix=%s/em64t'%ipp_dir, '--enable-fft=ipp'
 		  ] + mkl_64 + nompi + common_64
 
+    class Profile(Configuration):
+        suffix = '-profile'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic),
+                   '--with-g2c-copy=%s'%g2c64,
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir, '--enable-fft=ipp'
+		  ] + mkl_64 + nompi + common_64 + profile
+
     class Debug(Configuration):
         suffix = '-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
@@ -230,6 +270,15 @@
                    '--with-g2c-copy=%s'%g2c32,
                   ] + builtin_fft_32 + builtin_lapack_32 + mpi + common_32
 
+    class Profile(Configuration):
+        suffix = '-profile'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_32_p4sse2),
+                   'CFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   'FFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   'LDFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   '--with-g2c-copy=%s'%g2c32,
+                  ] + builtin_fft_32 + builtin_lapack_32 + mpi + common_32 + profile
+
     class Debug(Configuration):
         suffix = '-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug + m32),
@@ -252,6 +301,12 @@
                    '--with-g2c-copy=%s'%g2c64,
                   ] + builtin_fft_em64t + builtin_lapack_em64t + mpi + common_64
 
+    class Profile(Configuration):
+        suffix = '-profile'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_em64t),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_em64t + builtin_lapack_em64t + mpi + common_64 + profile
+
     class Debug(Configuration):
         suffix = '-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
@@ -271,6 +326,12 @@
                    '--with-g2c-copy=%s'%g2c64,
                   ] + builtin_fft_amd64 + builtin_lapack_amd64 + mpi + common_64
 
+    class Profile(Configuration):
+        suffix = '-profile'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_amd64),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_amd64 + builtin_lapack_amd64 + mpi + common_64 + profile
+
     class Debug(Configuration):
         suffix = '-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
@@ -294,6 +355,16 @@
                    '--with-ipp-prefix=%s/ia32_itanium'%ipp_dir, '--enable-fft=ipp'
 		  ] + mkl_32 + mpi + common_32
 
+    class Profile(Configuration):
+        suffix = '-profile'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_32_generic),
+                   'CFLAGS="%s"'%' '.join(flags_32_generic),
+                   'FFLAGS="%s"'%' '.join(flags_32_generic),
+                   'LDFLAGS="%s"'%' '.join(flags_32_generic),
+                   '--with-g2c-copy=%s'%g2c32,
+                   '--with-ipp-prefix=%s/ia32_itanium'%ipp_dir, '--enable-fft=ipp'
+		  ] + mkl_32 + mpi + common_32 + profile
+
     class Debug(Configuration):
         suffix = '-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug + m32),
@@ -318,6 +389,13 @@
                    '--with-ipp-prefix=%s/em64t'%ipp_dir, '--enable-fft=ipp'
 		  ] + mkl_64 + mpi + common_64
 
+    class Profile(Configuration):
+        suffix = '-profile'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic),
+                   '--with-g2c-copy=%s'%g2c64,
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir, '--enable-fft=ipp'
+		  ] + mkl_64 + mpi + common_64 + profile
+
     class Debug(Configuration):
         suffix = '-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
@@ -364,6 +442,13 @@
                    'LDFLAGS="%s"'%' '.join(flags_sparc)
                   ] + builtin_fft_sparc + builtin_lapack_sparc + nompi + common_sparc
 
+    class Profile(Configuration):
+        suffix = '-profile'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_sparc),
+                   'CFLAGS="%s"'%' '.join(flags_sparc),
+                   'LDFLAGS="%s"'%' '.join(flags_sparc)
+                  ] + builtin_fft_sparc + builtin_lapack_sparc + nompi + common_sparc + profile
+
     class Debug(Configuration):
         suffix = '-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
@@ -386,6 +471,13 @@
                    'LDFLAGS="%s"'%' '.join(flags_sparc)
                   ] + builtin_fft_sparc + builtin_lapack_sparc + mpi_sparc + common_sparc
 
+    class Profile(Configuration):
+        suffix = '-profile'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_sparc),
+                   'CFLAGS="%s"'%' '.join(flags_sparc),
+                   'LDFLAGS="%s"'%' '.join(flags_sparc)
+                  ] + builtin_fft_sparc + builtin_lapack_sparc + mpi_sparc + common_sparc + profile
+
     class Debug(Configuration):
         suffix = '-debug'
         options = ['CXXFLAGS="%s"'%' '.join(debug),
Index: doc/quickstart/quickstart.xml
===================================================================
--- doc/quickstart/quickstart.xml	(revision 147601)
+++ doc/quickstart/quickstart.xml	(working copy)
@@ -973,7 +973,7 @@
         include <option>none</option>, <option>posix</option>,
         <option>realtime</option>, and <option>pentiumtsc</option>,
         and <option>x86_64_tsc</option>.  By default no timer is used
-        (<option><replaceable>timer</replaceable>=none</option>
+        (<option><replaceable>timer</replaceable>=none</option>).
        </para>
 
        <para>
@@ -998,7 +998,51 @@
       </listitem>
      </varlistentry>
 
+  
+
+
      <varlistentry>
+      <term><option>--enable-profiler=<replaceable>regions</replaceable></option></term>
+      <listitem>
+       <para>
+        Profile <replaceable>regions</replaceable> of the library.
+        Choices include <option>none</option>, <option>all</option> 
+        or a combination of the values below.  A valid timer must
+        also be enabled in order for profiling to work.  Enabling
+        profiling inserts a very small amount of code in the 
+        selected areas of the library.   When the profiling mode 
+        set, detailed timing information is provided to the user 
+        when the program terminates.  
+        See the file <filename>profiling.txt</filename> and the
+        tutorial for details on how to use the profiler.
+        Default is none 
+        (<option><replaceable>regions</replaceable>=none</option>).
+       </para>
+
+       <para>
+        <option>none</option> disables profile timing.
+       </para>
+       <para>
+        <option>signal</option> profiles signal-processing functions.
+       </para>
+       <para>
+        <option>matvec</option> profiles linear algebra functions.
+       </para>
+       <para>
+        <option>fns</option> profiles elementwise functions (expressions
+        involving views).
+       </para>
+       <para>
+        <option>user</option> profiles user-defined events.
+       </para>
+       <para>
+        <option>all</option> equivalent to <option>signal</option>, 
+          <option>matvec</option>, <option>fns</option>, <option>user</option>.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><option>--enable-cpu-mhz=<replaceable>speed</replaceable></option></term>
       <listitem>
        <para>
