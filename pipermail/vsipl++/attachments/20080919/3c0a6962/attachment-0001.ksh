Index: ../vpp/doc/quickstart/quickstart.xml
===================================================================
--- ../vpp/doc/quickstart/quickstart.xml	(revision 222100)
+++ ../vpp/doc/quickstart/quickstart.xml	(working copy)
@@ -138,7 +138,7 @@
      </varlistentry>
 
      <varlistentry>
-      <term><literal>literal</literal></term>g
+      <term><literal>literal</literal></term>
       <listitem>
        <para>
         Text provided to or received from a computer program.
@@ -167,14 +167,18 @@
     <varlistentry>
      <term>Sourcery VSIPL++ Website</term>
      <listitem>
-      <ulink url="http://www.codesourcery.com/vsiplplusplus/"/>
+       <para>
+	 <ulink url="http://www.codesourcery.com/vsiplplusplus/"></ulink>
+       </para>
      </listitem>
     </varlistentry>
 
     <varlistentry>
      <term>VSIPL++ API Specification</term>
      <listitem>
-      <ulink url="http://www.codesourcery.com/public/vsiplplusplus/specification-1.0.pdf"/>
+       <para>
+	 <ulink url="http://www.codesourcery.com/public/vsiplplusplus/specification-1.0.pdf"></ulink>
+       </para>
      </listitem>
     </varlistentry>
    </variablelist>
@@ -438,10 +442,14 @@
       </para>
 
       <para>
-       Here are URLs where you can find out more about IPP and MKL:
+       To find out more about IPP and MKL visit 
        <itemizedlist>
-        <listitem><ulink url="http://www.intel.com/cd/software/products/asmo-na/eng/perflib/ipp/index.htm"></ulink></listitem>
-        <listitem><ulink url="http://www.intel.com/cd/software/products/asmo-na/eng/perflib/mkl/index.htm"></ulink></listitem>
+        <listitem><para>
+	  <ulink url="http://www.intel.com/cd/software/products/asmo-na/eng/perflib/ipp/index.htm"></ulink>
+	</para></listitem>
+        <listitem><para>
+	  <ulink url="http://www.intel.com/cd/software/products/asmo-na/eng/perflib/mkl/index.htm"></ulink>
+	</para></listitem>
        </itemizedlist>
       </para>
      </section>
@@ -472,10 +480,7 @@
       </para>
 
       <para>
-       Visit
-       <ulink url="http://mc.com/products/view/index.cfm?id=5&amp;type=software">
-       http://mc.com/products/view/index.cfm?id=5&amp;type=software
-       </ulink>
+       Visit <ulink url="http://www.mc.com/products/software.aspx"></ulink>
        for more information about SAL.
       </para>
      </section>
@@ -489,8 +494,7 @@
       </para>
 
       <para>
-       Visit
-       <ulink url="http://www.vsipl.org/">http://www.vsipl.org </ulink>
+       Visit the <ulink url="http://www.vsipl.org/"></ulink>
        for more information about the VSIPL API and a list of implementations.
       </para>
      </section>
@@ -522,9 +526,8 @@
       </para>
       
       <para>
-       For more information on PAS, visit the following URL:
-       <ulink url="http://mc.com/products/view/index.cfm?id=16&amp;type=software">
-        http://mc.com/products/view/index.cfm?id=16&amp;type=software</ulink>.
+       For more information on PAS, visit 
+       <ulink url="http://www.mc.com/products/software.aspx"></ulink>.
       </para>
       <para>
        The following releases of Mercury PAS have been tested by CodeSourcery
@@ -540,8 +543,8 @@
       <title>LAM/MPI</title>
 
       <para>
-       You can download LAM/MPI as source code from <ulink
-       url="http://www.lam-mpi.org/">http://www.lam-mpi.org/</ulink>.
+       You can download LAM/MPI as source code from 
+       <ulink url="http://www.lam-mpi.org/"></ulink>.
       </para>
 
       <para>
@@ -583,8 +586,8 @@
      <section>
       <title>MPICH</title> 
       <para>
-       You can download MPICH as source code from <ulink
-       url="http://www-unix.mcs.anl.gov/mpi/mpich/">http://www-unix.mcs.anl.gov/mpi/mpich/</ulink>,
+       You can download MPICH as source code from 
+       <ulink url="http://www-unix.mcs.anl.gov/mpi/mpich/"></ulink>,
        but pre-built binaries for most popular operating systems are
        available from the system distributors.  If MPICH is not already
        installed on your system, see the documentation for your
@@ -593,6 +596,18 @@
      </section>
 
      <section>
+      <title>OpenMPI</title> 
+      <para>
+       You can download OpenMPI as source code from 
+       <ulink url="http://www.open-mpi.org/"></ulink>,
+       but pre-built binaries for most popular operating systems are
+       available from the system distributors.  If OpenMPI is not already
+       installed on your system, see the documentation for your
+       operating system for information about obtaining OpenMPI.
+      </para>
+     </section>
+
+     <section>
       <title>Verari MPI/Pro</title>
       <para>
        The following release of Verari MPI/Pro has been tested by CodeSourcery
@@ -610,8 +625,8 @@
    <title>Obtaining the Source Code</title>
    <para>
     The Sourcery VSIPL++ Source Code is available from CodeSourcery's web
-    site.  Visit <ulink
-    url="http://www.codesourcery.com/vsiplplusplus/download.html">http://www.codesourcery.com/vsiplplusplus/download.html</ulink> 
+    site.  Visit 
+    <ulink url="http://www.codesourcery.com/vsiplplusplus/download.html"></ulink>
     for instructions on downloading VSIPL++.
     </para> 
 
@@ -710,15 +725,61 @@
       <term><option>--disable-parallel</option></term>
       <listitem>
        <para>
-	Do not use MPI, even if an appropriate MPI library is
-	detected.  This option is useful if you want to build
-	a uniprocessor version of Sourcery VSIPL++.  By default, MPI
+	Do not use a parallel communications library, even if an appropriate 
+	MPI library is detected.  This option is useful if you want to 
+	build a uniprocessor version of Sourcery VSIPL++.  By default, MPI 
 	support will be included if it is available.
        </para>
       </listitem>
      </varlistentry>
 
      <varlistentry>
+      <term><option>--enable-parallel</option></term>
+      <listitem>
+       <para>
+        Search for and use a communications library for support of
+	multi-processor systems for parallel computation.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><option>--enable-parallel=<replaceable>lib</replaceable></option>
+      </term><listitem>
+       <para>
+	Search for and use the parallel communications library 
+	indicated by <replaceable>lib</replaceable>.  Available
+	options are <option>lam</option>, <option>mpich2</option>, 
+	<option>intelmpi</option>, <option>openmpi</option>,
+	<option>mpipro</option>, and <option>pas</option>.
+       </para>
+
+       <para>
+        <option>lam</option> selects the LAM/MPI library.
+       </para>
+       <para>
+        <option>mpich2</option> selects the MPICH2 library.
+       </para>
+       <para>
+        <option>intelmpi</option> selects the Intel MPI Library.
+       </para>
+       <para>
+        <option>openmpi</option> selects then Open MPI library.
+       </para>
+       <para>
+        <option>mpipro</option> selects Verari's MPI/Pro.  This 
+	option is necessary when using MPI/Pro on the Mercury platform.
+       </para>
+       <para>
+        <option>pas</option> enables the use of Mercury Parallel 
+	Acceleration System (PAS) for parallel services if found.  
+	This option is necessary to use PAS on the Mercury platform, 
+	and when using PAS for Linux clusters.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><option>--with-mpi-prefix=<replaceable>directory</replaceable></option></term>
       <listitem>
        <para>
@@ -755,28 +816,6 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--enable-parallel=mpipro</option></term>
-      <listitem>
-       <para>
-        Use Verari's MPI/Pro.  This option is necessary
-        when using MPI/Pro on the Mercury platform.
-       </para>
-      </listitem>
-     </varlistentry>
-
-     <varlistentry>
-      <term><option>--enable-parallel=pas</option></term>
-      <listitem>
-       <para>
-        Enable the use of Mercury Parallel Acceleration System (PAS)
-	for parallel services if found.  This option is necessary to
-	use PAS on the Mercury platform, and when using PAS for Linux
-	clusters.  By default PAS support will not be included.
-       </para>
-      </listitem>
-     </varlistentry>
-
-     <varlistentry>
       <term><option>--disable-exceptions</option></term>
       <listitem>
        <para>
@@ -1659,7 +1698,7 @@
      Before configuring Sourcery VSIPL++ for a Microsoft Windows
      systems, the follow prerequisites are recommended:
      <itemizedlist>
-      <listitem>
+      <listitem><para>
        The Cygwin environment for Windows, including the GNU make and
        sed packages.
 
@@ -1669,19 +1708,20 @@
        applications.
 
        For more information on the Cygwin environment, visit
-       <ulink url="http://www.cygwin.com/"/>
+       <ulink url="http://www.cygwin.com/"></ulink></para>
       </listitem>
 
-      <listitem>
+      <listitem><para>
        Intel C++ for Windows, version 9.1 or later.  This may require
        installation of a Microsoft C++ compiler and Microsoft
        SDK for windows.  For more information on Intel C++ and its
        requirements:
        <ulink url="http://www.intel.com/cd/software/products/asmo-na/eng/compilers/279578.htm"></ulink>
+       </para>
       </listitem>
 
-      <listitem>
-       Intel IPP and MKL for Windows.
+      <listitem><para>
+       Intel IPP and MKL for Windows.</para>
       </listitem>
      </itemizedlist>
     </para>
@@ -1983,7 +2023,8 @@
      This section explains how to install and run Sourcery VSIPL++ from 
      a pre-built package.  Pre-built Sourcery VSIPL++ packages are available 
      from CodeSourcery's web site in the same location as the source release.
-     Visit <ulink url="http://www.codesourcery.com/vsiplplusplus/download.html">http://www.codesourcery.com/vsiplplusplus/download.html</ulink> 
+     Visit 
+     <ulink url="http://www.codesourcery.com/vsiplplusplus/download.html"></ulink>
      for instructions on downloading VSIPL++.
    </para> 
     <section>
