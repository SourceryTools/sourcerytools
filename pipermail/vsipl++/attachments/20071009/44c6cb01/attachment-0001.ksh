Index: doc/quickstart/quickstart.xml
===================================================================
--- doc/quickstart/quickstart.xml	(revision 184409)
+++ doc/quickstart/quickstart.xml	(working copy)
@@ -941,8 +941,9 @@
         (matrix-vector products and solvers).  Valid choices for
         <replaceable>lib</replaceable> include <option>mkl</option>,
 	<option>acml</option>, <option>atlas</option>, 
-        <option>generic</option>, <option>builtin</option>, and
-	<option>fortran-builtin</option>.
+        <option>generic</option>, <option>builtin</option>,
+	<option>fortran-builtin</option>, <option>simple-builtin</option>, and
+        <option>no</option>.
        </para>
 
        <para>
@@ -982,17 +983,14 @@
         as well as the g2c library.  Use the <option>--with-g2c-path=</option> 
         option if this library is not installed in a standard location.
        </para>
-      </listitem>
-     </varlistentry>
-
-     <varlistentry>
-      <term><option>--disable-builtin-atlas</option></term>
-      <listitem>
        <para>
-        Disables the consideration of Sourcery VSIPL++'s builtin
-	ATLAS for performing linear algebra.  This option is useful
-	if building on a platform that is not supported by ATLAS.
+        <option>simple-builtin</option> selects a version of LAPACK 
+        that doesn't require ATLAS.
        </para>
+       <para>
+        <option>no</option> is used to disable searching for a LAPACK
+        library.
+       </para>
       </listitem>
      </varlistentry>
 
