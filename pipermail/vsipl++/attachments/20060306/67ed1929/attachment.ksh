Index: doc/quickstart/quickstart.xml
===================================================================
RCS file: /home/cvs/Repository/vpp/doc/quickstart/quickstart.xml,v
retrieving revision 1.25
diff -u -r1.25 quickstart.xml
--- doc/quickstart/quickstart.xml	31 Jan 2006 23:38:14 -0000	1.25
+++ doc/quickstart/quickstart.xml	6 Mar 2006 16:13:50 -0000
@@ -16,7 +16,7 @@
  <!ENTITY specification
   "<ulink url=&#34;http://www.codesourcery.com/public/vsiplplusplus/specification-1.0.pdf&#34;
     >VSIPL++ API specification</ulink>">
- <!ENTITY version "1.0">
+ <!ENTITY version "1.1 (prerelease)">
 ]>
 
 <book>
@@ -280,7 +280,8 @@
     <para>
      Sourcery VSIPL++ can be built and installed on any UNIX-like system
      that has a satisfactory C++ compiler.  CodeSourcery's reference
-     platform is Red Hat Enterprise Linux 4.0.
+     GNU/Linux platform is Red Hat Enterprise Linux 4.0.  CodeSourcery's
+     reference MCOE platform is 6.3.0
     </para>
 
     <para>
@@ -290,7 +291,11 @@
      been tested by CodeSourcery to work with Sourcery VSIPL++:
      <itemizedlist>
       <listitem> <para>GCC 3.4 (IA32 GNU/Linux)</para> </listitem>
+      <listitem> <para>GCC 3.4 (AMD64 GNU/Linux)</para> </listitem>
       <listitem> <para>GCC 4.0 (IA32 GNU/Linux)</para> </listitem>
+      <listitem> <para>GCC 4.0 (AMD64 GNU/Linux)</para> </listitem>
+      <listitem> <para>GCC 4.1 (IA32 GNU/Linux)</para> </listitem>
+      <listitem> <para>GreenHills C++ 4.0.6 (PowerPC MCOE 6.3.0)</para> </listitem>
      </itemizedlist>
     </para>
 
@@ -299,7 +304,7 @@
      Sourcery VSIPL++:
      <itemizedlist>
       <listitem> <para>GCC 3.3</para> </listitem>
-      <listitem> <para>Intel C++ 8.x</para> </listitem>
+      <listitem> <para>Intel C++ 8.1</para> </listitem>
      </itemizedlist>
     </para>
    </section>
@@ -405,15 +410,29 @@
        </itemizedlist>
       </para>
      </section>
+
+     <section>
+      <title>Mercury SAL</title>
+      <para>
+       The Mercury Scientific Algorithm Library (SAL) can be used by
+       Sourcery VSIPL++ to accelerate many functions, including
+       elementwise view operations, linear algebra, solvers, and signal
+       processing objects (including FFT).  SAL is a propreitary library,
+       so you cannot distribute a Sourcery VSIPL++ application using
+       SAL under the terms of the GPL.
+      </para>
+     </section>
+
     </section>
 
     <section>
      <title>Message Passing Interface (MPI)</title>
      <para>
       If you install MPI, you can run Sourcery VSIPL++ programs on multiple
-      cluster nodes simultaneously.  Sourcery VSIPL++ works with both  
-      the LAM and MPICH implementations of MPI, and will likely work
-      with other MPI implementations as well.
+      cluster nodes simultaneously.  On GNU/Linux platforms, Sourcery
+      VSIPL++ works with both the LAM and MPICH implementations of MPI,
+      and will likely work with other MPI implementations as well.
+      On MCOE platforms, Sourcery VSIPL++ works with MPI/Pro.
      </para> 
 
      <section>
@@ -471,6 +490,17 @@
        operating system for information about obtaining MPICH.
       </para>
      </section>
+
+     <section>
+      <title>MPI/Pro</title>
+      <para>
+       The following release of MPI/Pro has been tested by CodeSourcery
+       to work with Sourcery VSIPL++:
+       <itemizedlist>
+        <listitem> <para>MPI/Pro 2.1.0</para> </listitem>
+       </itemizedlist>
+      </para>
+     </section>
     </section>
    </section>
   </section>
@@ -561,6 +591,20 @@
      </varlistentry>
 
      <varlistentry>
+      <term><option>--host=<replaceable>architecture</replaceable></option></term>
+      <listitem>
+       <para>
+        Specify the host-architecture that Sourcery VSIPL++
+        will be built for.
+
+        The default is to build Sourcery VSIPL++ to run native on
+        build machine.  This option is useful when cross-compiling
+        Sourcery VSIPL++.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><option>--disable-mpi</option></term>
       <listitem>
        <para>
@@ -578,8 +622,11 @@
        <para>
 	Search for MPI installation in
 	<replaceable>directory</replaceable> first.  MPI headers should
-        be in <replaceable>directory/include</replaceable> and MPI
-	libraries in <replaceable>director/lib</replaceable>.  This option is
+        be in <replaceable>directory/include</replaceable>, MPI
+	libraries in <replaceable>directory/lib</replaceable>, and
+        MPI compilation commands (either <filename>mpicxx</filename> or
+        <filename>mpiCC</filename>) should be in
+        <replaceable>directory/bin</replaceable>.  This option is
 	useful if MPI is installed in a non-standard location, or if
 	multiple MPI versions are installed.
        </para>
@@ -587,6 +634,16 @@
      </varlistentry>
 
      <varlistentry>
+      <term><option>--enable-mpi=mpipro</option></term>
+      <listitem>
+       <para>
+        Use MPI/Pro flavor of MPI.  This option is necessary
+        when using MPI/Pro on the Mercury platform.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><option>--disable-exceptions</option></term>
       <listitem>
        <para>
@@ -644,14 +701,58 @@
      </varlistentry>
 
      <varlistentry>
+      <term><option>--enable-sal</option></term>
+      <listitem>
+       <para>
+        Enable the use of the Mercury Scientific Algorithm Library (SAL)
+	if found.  Enabling SAL will accelerate the performance of
+	view element-wise operations, linear algebra, solvers, and
+        signal processing operations.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><option>--with-sal-include=<replaceable>directory</replaceable></option></term>
+      <listitem>
+       <para>
+        Search for SAL header files in <replaceable>directory</replaceable>
+        first.  This option has the effect of enabling SAL
+	(i.e. <option>--enable-sal</option>).  This option is useful
+	if SAL headers is installed in a non-standard location, such
+        as when using the CSAL library.  However, it should not be
+        necessary when building native on Mercury system.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><option>--with-sal-lib=<replaceable>directory</replaceable></option></term>
+      <listitem>
+       <para>
+        Search for SAL library files in <replaceable>directory</replaceable>
+        first.  This option has the effect of enabling SAL
+	(i.e. <option>--enable-sal</option>).  This option is useful
+	if SAL libraries is installed in a non-standard location, such
+        as when using the CSAL library.  However, it should not be
+        necessary when building native on Mercury system.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><option>--with-fft=<replaceable>lib</replaceable></option></term>
       <listitem>
        <para>
         Search for and use the FFT library indicated by
         <replaceable>lib</replaceable> to perform FFTs.  Valid
 	choices for <replaceable>lib</replaceable> include
-	<option>fftw3</option> and <option>ipp</option>, which
-	select the FFTW3 and IPP libraries respectively.
+	<option>fftw3</option>, <option>ipp</option>, and
+        <option>sal</option>, which select the FFTW3, IPP, and SAL
+        libraries respectively.  If no FFT library is to be used
+        (disabling Sourcery VSIPL++'s FFT functionality),
+        <option>none</option> should be chosen for
+        <replaceable>lib</replaceable>.
        </para>
       </listitem>
      </varlistentry>
@@ -804,6 +905,25 @@
      </varlistentry>
 
      <varlistentry>
+      <term><option>--with-complex=<replaceable>format</replaceable></option></term>
+      <listitem>
+       <para>
+        Specify the <replaceable>format</replaceable> for storing
+        complex numbers.
+
+        Valid choices for <replaceable>format</replaceable> are
+        <option>inter</option> and <option>split</option>, which
+        select interleaved and split storage respectively.
+
+        This option is useful when a platform has better
+        performance using a particular complex storage format.
+
+        The default complex storage format is <option>inter</option>.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><option>--enable-profile-timer=<replaceable>timer</replaceable></option></term>
       <listitem>
        <para>
@@ -887,6 +1007,205 @@
 config.status: creating GNUmakefile
 config.status: creating src/vsip/impl/acconfig.hpp</screen>
    </example>
+
+   <section>
+    <title>Configuration Notes for Mercury Systems</title>
+
+    <para>
+     When configuring Sourcery VSIPL++ to for a Mercury
+     PowerPC system, the following environment variables
+     and configuration flags recommended:
+     <itemizedlist>
+
+      <listitem>
+       <para><option>CXX=ccmc++</option></para>
+       <para>
+	This selects the <option>ccmc++</option> cross compiler as the
+        C++ compiler.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>CXXFLAGS="--no_explicit_indluce -Ospeed -Onotailrecursion-t <replaceable>architecture</replaceable> --no_exceptions -DNDEBUG --diag_suppress 177,550</option></para>
+       <para>
+        These are the recommended flags for compiling Sourcery VSIPL++
+        with the Greenhills C++ compiler on the Mercury platform.
+        These flags fall into two categories: those necessary for
+        a correct build, and those optional for good performance.
+        The following are necessary to correctly build the library:
+        <itemizedlist>
+         <listitem>
+          <para><option>--no_implicit_include</option></para>
+          <para>
+           GreenHills enables implicit inclusion by default. This permits
+           the compiler to assume that if it needs to instantiate a
+           template entity defined in a .hpp file it can implicitly
+           include the corresponding .cpp file to get the source code for
+           the definition.
+          </para>
+
+          <para>
+           Sourcery VSIPL++ does not use this capability.  Leaving this
+           feature enabled will result in multiple symbol definition errors
+           at link-time.
+          </para>
+
+          <para>
+           Note: it is only necessary to disable implicit includes when
+           building the library.  After the library has been installed,
+           applications using it may enable implicit includes.
+          </para>
+         </listitem>
+
+         <listitem>
+          <para><option>-Onotailrecursion</option></para>
+          <para>
+           This disables optimization of tail-recursive functions.
+           This optimization has a defect which is triggered by
+           some of Sourcery VSIPL++'s algorithms.
+          </para>
+         </listitem>
+
+        </itemizedlist>
+       </para>
+
+       <para>
+        The following flags will improve the performance of the library
+        and applications.  These should be used for production.
+        <itemizedlist>
+
+         <listitem>
+          <para>
+           <option>-t <replaceable>architecture</replaceable></option>
+          </para>
+          <para>
+           This flag directs the compiler to generate code optimized
+           for processor variant and endian-ness specifed by
+           <replaceable>architecture</replaceable>.
+           Valid choices are listed in the <filename>ccmc++</filename>
+           documentation and include
+           <option>ppc7400</option>, <option>ppc7400_le</option>,
+           <option>ppc7445</option>, and <option>ppc7445_le</option>.
+          </para>
+         </listitem>
+
+        <listitem>
+          <para><option>--no_exceptions</option></para>
+          <para>
+           Disable exception handling, which can have a large
+           performance overhead with the GreenHills compiler.
+           This should be used in conjunction
+           with the configure flag <option>--disable-exceptions</option>.
+          </para>
+         </listitem>
+
+         <listitem>
+          <para><option>-Ospeed</option></para>
+          <para>
+           This option instructs the compiler to enable all optimizations
+           which improve speed.
+          </para>
+         </listitem>
+
+         <listitem>
+          <para><option>--max_inlining</option></para>
+          <para>
+           By default, GreenHills? will only consider functions composed
+           entirely of straightline code (no control flow) for inlining.
+           <option>--max_inlining</option> instructs the compiler
+           to consider all functions (whether containing control flow
+           statements or not) for inlining, subject to the usual
+           restraints in the case of excessively large or compilcated
+           functions.
+          </para>
+         </listitem>
+
+         <listitem>
+          <para><option>-DNDEBUG</option></para>
+          <para>
+           Disable assertions.  This option should be used when
+           configuring the library for performance.
+          </para>
+         </listitem>
+
+         <listitem>
+          <para><option>--diag_suppress 177,550</option></para>
+          <para>
+           This option suppresses compiler diagnostics warning
+           about unused variables.  When compiling with
+           <option>-DNDEBUG</option> assertions are removed that
+           may be the only reference to a variable.
+          </para>
+         </listitem>
+
+        </itemizedlist>
+       </para>
+       <para>
+        When compiling a development or debug version of the library,
+        replace <option>-Ospeed -DNDEBUG</option> with <option>-g</option>.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>--host=powerpc</option></para>
+       <para>
+        Cross compile for the PowerPC processor.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>--enable-sal</option></para>
+       <para>
+        Enable the SAL library.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>--with-fft=sal</option></para>
+       <para>
+        Use SAL to perform FFT operations.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>--with-complex=split</option></para>
+       <para>
+        Store complex data in split format by default.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>--disable-exceptions</option></para>
+       <para>
+        Disable the use of exceptions from within the library.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>--enable-mpi=mpipro</option></para>
+       <para>
+        Enable the use of MPI/Pro for communications.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>--enable-profile-timer=realtime</option></para>
+       <para>
+        Use the POSIX-realtime timer for profiling.
+       </para>
+      </listitem>
+
+     </itemizedlist>
+    </para>
+
+    <para>
+     The file <filename>examples/mercury/mcoe-setup.sh</filename> is
+     an example of how to configure Sourcery VSIPL++ for the Mercury
+     with these options.
+    </para>
+
+   </section>
+
   </section>
 
   <section>
