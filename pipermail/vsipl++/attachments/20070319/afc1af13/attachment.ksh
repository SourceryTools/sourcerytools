Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 166212)
+++ GNUmakefile.in	(working copy)
@@ -344,6 +344,10 @@
              $(wildcard $(srcdir)/src/vsip/opt/cbe/alf/include/arch/cell/*.h))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/cbe/alf/src/inc/*.h))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/opt/cbe/ppu/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/opt/cbe/*.h))
 endif
 endif
 ########################################################################
Index: configure.ac
===================================================================
--- configure.ac	(revision 166212)
+++ configure.ac	(working copy)
@@ -917,6 +917,7 @@
 	                 fftw3_d_simd="--enable-sse2" 
 	                 ;;
       ppc*)             fftw3_f_simd="--enable-altivec" ;;
+      powerpc*)         fftw3_f_simd="--enable-altivec" ;;
     esac
     AC_MSG_NOTICE([fftw3 config options: $fftw3_opts $fftw3_simd.])
 
Index: doc/quickstart/quickstart.xml
===================================================================
--- doc/quickstart/quickstart.xml	(revision 166212)
+++ doc/quickstart/quickstart.xml	(working copy)
@@ -17,7 +17,7 @@
  <!ENTITY specification
   "<ulink url=&#34;http://www.codesourcery.com/public/vsiplplusplus/specification-1.0.pdf&#34;
     >VSIPL++ API specification</ulink>">
- <!ENTITY version "1.3">
+ <!ENTITY version "1.3 beta">
 ]>
 
 <book>
@@ -25,7 +25,7 @@
   <title>Sourcery VSIPL++</title>
   <subtitle>Getting Started</subtitle>
   <corpauthor>CodeSourcery, Inc</corpauthor>
-  <copyright><year>2005, 2006</year><holder>CodeSourcery, Inc</holder></copyright>
+  <copyright><year>2005, 2006, 2007</year><holder>CodeSourcery, Inc</holder></copyright>
   <legalnotice>&opl.xml;</legalnotice>
   <releaseinfo>Version &version;</releaseinfo>
  </bookinfo>
@@ -1063,6 +1063,54 @@
      </varlistentry>
 
      <varlistentry>
+      <term><option>--enable-cbe-sdk</option></term>
+      <listitem>
+       <para>
+        Enable the use of the IBM Cell BE Software Development Kit
+        (SDK) if found.  Enabling the Cell BE SDK will accelerate the
+        performance of FFTs, vector-multiplication, vector-matrix
+	multiplication, and fast convolution.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><option>--with-cbe-sdk-prefix=<replaceable>directory</replaceable></option></term>
+      <listitem>
+       <para>
+	Search for Cell BE SDK installation in
+	<replaceable>directory</replaceable> first.  This option has
+	the effect of enabling use of the Cell BE SDK (i.e.
+	<option>--enable-cbe-sdk</option>).  This option is useful if the
+	SDK is installed in a non-standard location, or if multiple
+	SDK versions are installed.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><option>--enable-cbe-sdk-embedded-images</option></term>
+      <listitem>
+       <para>
+        Enable the embedding of SPE images into the application.
+	If disabled, SPE images are loaded from individual object
+	files.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><option>--enable-numa</option></term>
+      <listitem>
+       <para>
+        Enable the use of libnuma.  This is useful on Cell BE systems
+        to insure that SPE resources allocated for accelertion are
+        local to the PPE running VSIPL++.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><option>--enable-cvsip</option></term>
       <listitem>
        <para>
@@ -1656,6 +1704,48 @@
 
    </section> <!-- Configuration Notes for Windows Systems -->
 
+   <section id="cfg-cell-be">
+    <title>Configuration Notes for Cell BE Systems</title>
+
+    <para>
+     When configuring Sourcery VSIPL++ for a Cell BE system, the
+     following environment variables and configuration flags are
+     recommended:
+     <itemizedlist>
+
+      <listitem>
+       <para><option>--enable-cbe-sdk</option></para>
+       <para>
+        Enable use of the Cell BE SDK.  This is necessary to use the
+        Cell BE's SPE processors to accelerate VSIPL++ functionaity.
+        If the SDK is not installed in the standard location, the
+        <option>--with-cbe-sdk-prefix</option> should be used to
+        specify the location.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>--enable-numa</option></para>
+       <para>
+        Enable use of libnuma for SPE/PPE affinity control.  This
+	may improve program performance by allocating SPEs close to
+	the PPEs running VSIPL++.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>--enable-timer=power_tb</option></para>
+       <para>
+        Enable the Power Timebase high-resolution timer.  This option
+	is useful when using profiling or running library benchmarks.
+       </para>
+      </listitem>
+
+     </itemizedlist>
+    </para>
+
+   </section> <!-- Configuration Notes for Cell BE Systems -->
+
    <section id="cfg-ref-impl">
     <title>Configuration Notes for the Reference Implementation</title>
 
Index: autogen.sh
===================================================================
--- autogen.sh	(revision 166212)
+++ autogen.sh	(working copy)
@@ -18,3 +18,9 @@
   ./autogen.sh
   cd ../..
 fi
+
+if test -f "vendor/fftw/configure.ac"; then
+  cd vendor/fftw
+  autoconf
+  cd ../..
+fi
