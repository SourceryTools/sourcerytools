Index: ChangeLog
===================================================================
--- ChangeLog	(revision 161566)
+++ ChangeLog	(working copy)
@@ -1,4 +1,8 @@
 2007-01-31  Jules Bergmann  <jules@codesourcery.com>
+	
+	* doc/quickstart/quickstart.xml: Revise section on ref-impl cfg.
+	
+2007-01-31  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac: Bump version to 1.3.
 	* doc/tutorial/tutorial.xml: Likewise.
Index: doc/quickstart/quickstart.xml
===================================================================
--- doc/quickstart/quickstart.xml	(revision 161566)
+++ doc/quickstart/quickstart.xml	(working copy)
@@ -480,17 +480,17 @@
      </section>
 
      <section>
-      <title>C-VSIPL</title>
+      <title>VSIPL Back End</title>
       <para>
-       A C-VSIPL implementation can be used by Sourcery VSIPL++ to
-       implement many functions, including linear algebra, solvers,
-       and signal processing objects (such as FFT).
+       An implementation of the C VSIPL API can be used by Sourcery
+       VSIPL++ to implement many functions, including linear algebra,
+       solvers, and signal processing objects (such as FFT).
       </para>
 
       <para>
        Visit
        <ulink url="http://www.vsipl.org/">http://www.vsipl.org </ulink>
-       for more information about C-VSIPL.
+       for more information about the VSIPL API and a list of implementations.
       </para>
      </section>
 
@@ -873,7 +873,7 @@
         for <replaceable>lib</replaceable> include
         <option>fftw3</option>, <option>ipp</option>,
         <option>sal</option>, and <option>cvsip</option> which select
-        FFTW3, IPP, SAL, and C-VSIP libraries respectively.  A fourth
+        FFTW3, IPP, SAL, and C VSIPL libraries respectively.  A fourth
         option, <option>builtin</option>, selects the FFTW3 library
         that comes with Sourcery VSIPL++ (default).  This option
         should be used if an existing FFTW3 library is not available.
@@ -1066,12 +1066,13 @@
       <term><option>--enable-cvsip</option></term>
       <listitem>
        <para>
-        Enable Sourcery VSIPL++ to search for an appropriate C-VSIP
+        Enable Sourcery VSIPL++ to search for an appropriate C VSIPL
         implementation on the platform.  If found, it will be used to
         perform linear algebra (matrix-vector products and solvers)
         and some signal processing (convolution, correlation, and
         FIR).  If the <option>--enable-fft=cvsip</option> option is
-        also given, C-VSIP will be used to perform FFTs.
+        also given, the VSIPL implementation will be used to perform
+        FFTs.
        </para>
       </listitem>
      </varlistentry>
@@ -1080,15 +1081,15 @@
       <term><option>--with-cvsip-prefix=<replaceable>directory</replaceable></option></term>
       <listitem>
        <para>
-	Search for C-VSIP installation in
-	<replaceable>directory</replaceable> first.  C-VSIP headers
-	should be in the <filename>include</filename> subdirectory of
-	<replaceable>directory</replaceable> and C-VSIP libraries
-	should be in the <filename>lib</filename> subdirectory.  This
-	option has the effect of enabling C-VSIP as if the option
-	<option>--enable-cvsip</option> had been given.  This option
-	is useful if C-VSIP is installed in a non-standard location,
-	or if multiple C-VSIP versions are installed.
+	Search for a C VSIPL installation in
+	<replaceable>directory</replaceable> first.  Headers should be
+	in the <filename>include</filename> subdirectory of
+	<replaceable>directory</replaceable> and libraries should be
+	in the <filename>lib</filename> subdirectory.  This option has
+	the effect of enabling the use of a VSIPL back end as if the
+	option <option>--enable-cvsip</option> had been given.  This
+	option is useful if VSIPL is installed in a non-standard
+	location, or if multiple VSIPL versions are installed.
        </para>
       </listitem>
      </varlistentry>
@@ -1659,17 +1660,17 @@
     <title>Configuration Notes for the Reference Implementation</title>
 
     <para>
-     When configuring Sourcery VSIPL++ to be used as the reference
-     implementation under the BSD license, the following configuration
-     flags should be used:
+     If you wish to use the BSD-licensed reference-implementation
+     subset of Sourcery VSIPL++, you must configure with the following
+     option:
      <itemizedlist>
 
       <listitem>
        <para><option>--enable-ref-impl</option></para>
        <para>
-        Configures Sourcery VSIPL++ to be used as the reference
-	implementation.  This is necessary, otherwise Sourcery VSIPL++
-	requires non-BSD files to operate.
+        Build only the reference-implementation subset of Sourcery
+        VSIPL++.  If you do not use this option, the complete,
+        optimized implementation of Sourcery VSIPL++ will be built.
        </para>
       </listitem>
 
