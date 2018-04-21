Index: ChangeLog
===================================================================
--- ChangeLog	(revision 237121)
+++ ChangeLog	(working copy)
@@ -1,5 +1,11 @@
 2009-02-19  Jules Bergmann  <jules@codesourcery.com>
 
+	* doc/getting-started/getting-started.xml: Update documentation for
+	  --with-cbe-sdk option (2.1 no longer supported).
+	* examples/cell/setup.sh: Update --with-cbe-sdk option.
+
+2009-02-19  Jules Bergmann  <jules@codesourcery.com>
+
 	* examples/cell/setup.sh: Add recommended --enable-timer=power_tb.
 
 2009-02-13  Jules Bergmann  <jules@codesourcery.com>
Index: doc/getting-started/getting-started.xml
===================================================================
--- doc/getting-started/getting-started.xml	(revision 236550)
+++ doc/getting-started/getting-started.xml	(working copy)
@@ -1145,12 +1145,10 @@
       <listitem>
        <para>
         Enable the use of the IBM Cell/B.E. Software Development Kit
-        (SDK) if found.  Enabling the Cell/B.E. SDK will accelerate the
-        performance of FFTs, vector-multiplication, vector-matrix
-	multiplication, and fast convolution.  Version 3.0 of the SDK
-	is assumed; the <option>--with-cbe-sdk=2.1</option> form of
-	the option can be used for compatibility with version 2.1
-	instead.
+        (SDK) version 3.0 or 3.1 if found.  Enabling the Cell/B.E. SDK
+        will accelerate the performance of FFTs,
+        vector-multiplication, vector-matrix multiplication, and fast
+        convolution.
        </para>
       </listitem>
      </varlistentry>
Index: examples/cell/setup.sh
===================================================================
--- examples/cell/setup.sh	(revision 237121)
+++ examples/cell/setup.sh	(working copy)
@@ -38,7 +38,7 @@
 export LD=ppu-ld
 
 $src_dir/configure							\
-	--with-cbe-sdk=3.0						\
+	--with-cbe-sdk							\
 	--with-cbe-sdk-prefix=$sdk_dir					\
 	--disable-fft-long-double					\
 	--disable-parallel						\
