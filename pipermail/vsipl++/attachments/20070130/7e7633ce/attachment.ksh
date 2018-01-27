Index: ChangeLog
===================================================================
--- ChangeLog	(revision 161549)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2007-01-30  Jules Bergmann  <jules@codesourcery.com>
+
+	* doc/quickstart/quickstart.xml: Update to cover reference
+	  implementation.
+	* LICENSE.BSD: Add 2007 to copyright years.
+	
 2007-01-29  Jules Bergmann  <jules@codesourcery.com>
 
 	Add config support for ref-impl and C-VSIP binary packages.
Index: doc/quickstart/quickstart.xml
===================================================================
--- doc/quickstart/quickstart.xml	(revision 161463)
+++ doc/quickstart/quickstart.xml	(working copy)
@@ -9,6 +9,7 @@
 [
  <!ENTITY opl.xml SYSTEM "../csl-docbook/fragments/opl.xml">
  <!ENTITY gpl.xml SYSTEM "../csl-docbook/fragments/gpl.xml">
+ <!ENTITY bsd.xml SYSTEM "../csl-docbook/fragments/bsd.xml">
  <!ENTITY sales "<email>sales@codesourcery.com</email>">
  <!ENTITY homepage 
   "<ulink url=&#34;http://www.codesourcery.com/vsiplplusplus/&#34;
@@ -186,12 +187,14 @@
   <chapterinfo>
    <abstract>
     <para>
-     Sourcery VSIPL++ is available under two licenses.  CodeSourcery
-     customers may use Sourcery VSIPL++ under terms suitable for use
+     Sourcery VSIPL++ is available under three licenses.  CodeSourcery
+     customers may use the entire library under terms suitable for use
      in proprietary software, including software designed for use in
-     classified systems.  Other users may use Sourcery VSIPL++ under
-     the GNU General Public License, which requires that source code
-     for Sourcery VSIPL++ applications be provided to their users.
+     classified systems.  Other users may either use the entire
+     library under the GNU General Public License, which requires that
+     source code for Sourcery VSIPL++ applications be provided to
+     their users, or use they may use the core parts of the library
+     that make up the reference implementation under the BSD license.
     </para>
    </abstract>
   </chapterinfo>
@@ -234,6 +237,18 @@
     described in the appendix. 
    </para>
   </section>
+
+  <section>
+   <title>Reference Implementation</title>
+   <para>
+    If you are planning to use the VSIPL++ reference implementation,
+    you may use the core library parts of Sourcery VSIPL++ under the
+    terms of the BSD license.  The full text of the license is
+    included in <xref linkend="bsd"/>.  The exact files available under
+    the BSD license are documented in the file <filename>LICENSE</filename>
+    located in the top level directory of the source package.
+   </para>
+  </section>
  </chapter>
 
  <chapter id="chap-installation">
@@ -464,6 +479,21 @@
       </para>
      </section>
 
+     <section>
+      <title>C-VSIPL</title>
+      <para>
+       A C-VSIPL implementation can be used by Sourcery VSIPL++ to
+       to implement many functions, including linear algebra, solvers,
+       and signal processing objects (such as FFT).
+      </para>
+
+      <para>
+       Visit
+       <ulink url="http://www.vsipl.org/">http://www.vsipl.org </ulink>
+       for more information about C-VSIPL.
+      </para>
+     </section>
+
     </section>
 
     <section>
@@ -1031,6 +1061,50 @@
      </varlistentry>
 
      <varlistentry>
+      <term><option>--enable-cvsip</option></term>
+      <listitem>
+       <para>
+        Enable Sourcery VSIPL++ to search for an appropriate
+	C-VSIP implementation on the platform.  If found, it
+	will be used to perform linear algebra (matrix-vector
+	products and solvers) and signal processing (FFT, convolution,
+	correlation, and FIR).
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><option>--with-cvsip-prefix=<replaceable>directory</replaceable></option></term>
+      <listitem>
+       <para>
+	Search for C-VSIP installation in
+	<replaceable>directory</replaceable> first.  C-VSIP headers
+	should be in the <filename>include</filename> subdirectory of
+	<replaceable>directory</replaceable> and C-VSIP libraries
+	should be in the <filename>lib</filename> subdirectory.  This
+	option has the effect of enabling C-VSIP as if the option
+	<option>--enable-cvsip</option> had been given.  This option
+	is useful if C-VSIP is installed in a non-standard location,
+	or if multiple C-VSIP versions are installed.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><option>--enable-ref-impl</option></term>
+      <listitem>
+       <para>
+        Configure Sourcery VSIPL++ to be used as the VSIPL++ reference
+        implementation.  When the BSD licensed files are configured
+        with this option, the result is the VSIPL++ reference
+        implementation.  To be fully functional, use of a C-VSIP
+        library should also be enabled with
+        <option>-enable-cvsip</option>.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><option>--with-g2c-path=<replaceable>directory</replaceable></option></term>
       <listitem>
        <para>
@@ -1068,8 +1142,9 @@
         Use <replaceable>timer</replaceable> type of timer for
         profiling. Valid choices for <replaceable>timer</replaceable>
         include <option>none</option>, <option>posix</option>,
-        <option>realtime</option>, and <option>pentiumtsc</option>,
-        and <option>x86_64_tsc</option>.  By default no timer is used
+        <option>realtime</option>, <option>pentiumtsc</option>, and
+        <option>x86_64_tsc</option>, and <option>power_tb</option>.
+        By default no timer is used
         (<option><replaceable>timer</replaceable>=none</option>
 
 	This option is necessary when you intent to use the libary's
@@ -1095,6 +1170,10 @@
         <option>x86_64_tsc</option> selects the x86-64 (or em64t)
         time-stamp counter (TSC) timer if present on the system.
        </para>
+       <para>
+        <option>power_tb</option> selects the Power architecture
+	timebase counter timer if present on the system.
+       </para>
       </listitem>
      </varlistentry>
 
@@ -1231,7 +1310,7 @@
       </listitem>
 
       <listitem>
-       <para><option>CXXFLAGS="--no_implicit_include -Onotailrecursion -t <replaceable>architecture</replaceable> --no_exceptions -Ospeed --max_inlining -DNDEBUG --diag_suppress 177,550</option></para>
+       <para><option>CXXFLAGS="--no_implicit_include -Onotailrecursion -t <replaceable>architecture</replaceable> --no_exceptions -Ospeed --max_inlining -DNDEBUG --diag_suppress 177,550"</option></para>
        <para>
         These are the recommended flags for compiling Sourcery VSIPL++
         with the GreenHills C++ compiler on the Mercury platform.
@@ -1481,7 +1560,7 @@
       </listitem>
 
       <listitem>
-       <para><option>CXXFLAGS="/Qcxx-features /Qvc8</option></para>
+       <para><option>CXXFLAGS="/Qcxx-features /Qvc8"</option></para>
        <para>
         These are the recommended flags for compiling Sourcery VSIPL++
         with the Intel C++ compiler on Microsoft Windows platforms.
@@ -1571,6 +1650,39 @@
 
    </section> <!-- Configuration Notes for Windows Systems -->
 
+   <section>
+    <title>Configuration Notes for the Reference Implementation</title>
+
+    <para>
+     When configuring Sourcery VSIPL++ to be used as the reference
+     implementation under the BSD license, the following configuration
+     flags should be used:
+     <itemizedlist>
+
+      <listitem>
+       <para><option>--enable-ref-impl</option></para>
+       <para>
+        Configures Sourcery VSIPL++ to be used as the reference
+	implementation.  This is necessary, otherwise Sourcery VSIPL++
+	requires non-BSD files to operate.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>--enable-cvsip</option></para>
+       <para>
+        Configures Sourcery VSIPL++ to use a C-VSIP library for linear
+        algebra and signal processing.  This is necessary, otherwise
+        linear algebra and signal processing functionality will not be
+        available.
+       </para>
+      </listitem>
+
+     </itemizedlist>
+    </para>
+
+   </section> <!-- Configuration Notes for the Reference Implementation-->
+
   </section>
 
   <section>
@@ -2075,6 +2187,8 @@
 
  &gpl.xml;
 
+ &bsd.xml;
+
 </book>
 
 
Index: LICENSE.BSD
===================================================================
--- LICENSE.BSD	(revision 161463)
+++ LICENSE.BSD	(working copy)
@@ -1,4 +1,4 @@
-Copyright (c) 2006, CodeSourcery
+Copyright (c) 2006, 2007, CodeSourcery
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
Index: doc/csl-docbook/fragments/bsd.xml
===================================================================
--- doc/csl-docbook/fragments/bsd.xml	(revision 0)
+++ doc/csl-docbook/fragments/bsd.xml	(revision 0)
@@ -0,0 +1,55 @@
+<appendix id="bsd">
+  <appendixinfo>
+    <title> BSD License</title>
+  </appendixinfo>
+  <title>BSD License</title>
+
+   <para>
+Copyright (c) 2006, 2007, CodeSourcery
+   </para>
+   <para>
+All rights reserved.
+   </para>
+
+   <para>
+Redistribution and use in source and binary forms, with or without
+modification, are permitted provided that the following conditions are
+met:
+   </para>
+   
+   <para>
+    <itemizedlist>
+     <listitem>
+      Redistributions of source code must retain the above copyright
+      notice, this list of conditions and the following disclaimer.
+     </listitem>
+
+     <listitem>
+      Redistributions in binary form must reproduce the above
+      copyright notice, this list of conditions and the following
+      disclaimer in the documentation and/or other materials provided
+      with the distribution.
+     </listitem>
+
+     <listitem>
+      Neither the name of the CodeSourcery nor the names of its
+      contributors may be used to endorse or promote products derived
+      from this software without specific prior written permission.
+     </listitem>
+    </itemizedlist>
+   </para>
+
+   <para>
+THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
+"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
+LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
+A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
+OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
+SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
+LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
+DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
+THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
+(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
+OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
+   </para>
+  </appendix>
Index: doc/csl-docbook/ChangeLog
===================================================================
--- doc/csl-docbook/ChangeLog	(revision 161463)
+++ doc/csl-docbook/ChangeLog	(working copy)
@@ -1,3 +1,7 @@
+2007-01-30  Jules Bergmann  <jules@codesourcery.com>
+	
+	* fragments/bsd.xml: New file.
+	
 2007-01-24  Mark Mitchell  <mark@codesourcery.com>
 
 	* xsl/fo/csl.xsl (body.font.master): Set to 10-point.
