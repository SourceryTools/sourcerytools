Index: ChangeLog
===================================================================
--- ChangeLog	(revision 220851)
+++ ChangeLog	(working copy)
@@ -1,3 +1,41 @@
+2008-09-10  Jules Bergmann  <jules@codesourcery.com>
+
+	Document binary elementwise functions
+	* doc/manual/bor.xml: New file.
+	* doc/manual/min.xml: New file.
+	* doc/manual/lxor.xml: New file.
+	* doc/manual/max.xml: New file.
+	* doc/manual/ge.xml: New file.
+	* doc/manual/lor.xml: New file.
+	* doc/manual/pow.xml: New file.
+	* doc/manual/gt.xml: New file.
+	* doc/manual/le.xml: New file.
+	* doc/manual/band.xml: New file.
+	* doc/manual/atan2.xml: New file.
+	* doc/manual/jmul.xml: New file.
+	* doc/manual/bxor.xml: New file.
+	* doc/manual/minmgsq.xml: New file.
+	* doc/manual/maxmgsq.xml: New file.
+	* doc/manual/lt.xml: New file.
+	* doc/manual/hypot.xml: New file.
+	* doc/manual/eq.xml: New file.
+	* doc/manual/fmod.xml: New file.
+	* doc/manual/ne.xml: New file.
+	* doc/manual/minmg.xml: New file.
+	* doc/manual/maxmg.xml: New file.
+	* doc/manual/land.xml: New file.
+	
+	Document ternary elementwise functions
+	* doc/manual/sbm.xml: New file.
+	* doc/manual/expoavg.xml: New file.
+	* doc/manual/msb.xml: New file.
+	* doc/manual/ma.xml: New file.
+	* doc/manual/am.xml: New file.
+	* doc/manual/ite.xml: New file.
+	
+	* doc/manual/functions.xml: Include new files.
+	* doc/manual/operations.xml: List binary and ternary functions.
+
 2008-09-10  Mike LeBlanc  <mike@codesourcery.com>
 
 	* doc/manual/fir.xml: Remove " = VSIP_DEFAULT_VALUE_TYPE" from class synopsis;
Index: doc/manual/bor.xml
===================================================================
--- doc/manual/bor.xml	(revision 0)
+++ doc/manual/bor.xml	(revision 0)
@@ -0,0 +1,211 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_bor">
+ <title><function>bor</function>
+  <indexterm><primary><function>bor</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise bitwise or.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>bor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>bor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>bor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>bor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>bor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>bor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>bor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>bor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>bor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+  <para>
+   Value type T must support bitwise negation (bool, char, int, and so
+   on).
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the bitwise or of the
+   corresponding elements of the arguments.  For instance, if the
+   arguments are vectors, <literal>Z = bor(A, B)</literal> produces a
+   result equivalent to <literal>Z(i) = bor(A(i), B(i))</literal> for
+   all of the elements of the vector.  If either of the arguments is a
+   scalar, it is bitwise ored to all all of the elements of the other
+   argument; for example, <literal>Z = bor(A, b)</literal> produces
+   <literal>Z(i) = bor(A(i), b)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;int&gt; Z, A, B;
+Z = bor(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>band</function> 
+       <xref linkend="functionref_band" role="template:(section %n)"/>
+   <function>bnot</function> 
+       <xref linkend="functionref_bnot" role="template:(section %n)"/>
+   <function>bxor</function> 
+       <xref linkend="functionref_bxor" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/min.xml
===================================================================
--- doc/manual/min.xml	(revision 0)
+++ doc/manual/min.xml	(revision 0)
@@ -0,0 +1,211 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_min">
+ <title><function>min</function>
+  <indexterm><primary><function>min</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise minima.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>min</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>min</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>min</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>min</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>min</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>min</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>min</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>min</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>min</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the minima of the
+   corresponding elements of the two arguments.  For instance, if the
+   arguments are vectors, <literal>Z = min(A, B)</literal> produces a
+   result equivalent to <literal>Z(i) = min(A(i), B(i))</literal> for
+   all of the elements of the vector.  If either of the arguments is a
+   scalar, it is compared with all of the elements of the other
+   argument; for example, <literal>Z = min(A, b)</literal> produces
+   <literal>Z(i) = min(A(i), b)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = min(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>max</function> 
+       <xref linkend="functionref_max" role="template:(section %n)"/>
+   <function>maxmg</function> 
+       <xref linkend="functionref_maxmg" role="template:(section %n)"/>
+   <function>maxmgsq</function> 
+       <xref linkend="functionref_maxmgsq" role="template:(section %n)"/>
+   <function>minmg</function> 
+       <xref linkend="functionref_minmg" role="template:(section %n)"/>
+   <function>minmgsq</function> 
+       <xref linkend="functionref_minmgsq" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/lxor.xml
===================================================================
--- doc/manual/lxor.xml	(revision 0)
+++ doc/manual/lxor.xml	(revision 0)
@@ -0,0 +1,212 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_lxor">
+ <title><function>lxor</function>
+  <indexterm><primary><function>lxor</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise bitwise exclusive or.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>lxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>lxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>lxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>lxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>lxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>lxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>lxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>lxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>lxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+  <para>
+   Value type T must support bitwise negation (bool, char, int, and so
+   on).
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the bitwise exclusive or
+   of the corresponding elements of the arguments.  For instance, if
+   the arguments are vectors, <literal>Z = lxor(A, B)</literal>
+   produces a result equivalent to <literal>Z(i) = lxor(A(i),
+   B(i))</literal> for all of the elements of the vector.  If either
+   of the arguments is a scalar, it is bitwise exclusive ored to all
+   all of the elements of the other argument; for example, <literal>Z
+   = lxor(A, b)</literal> produces <literal>Z(i) = lxor(A(i),
+   b)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;bool&gt; Z, A, B;
+Z = lxor(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>land</function> 
+       <xref linkend="functionref_land" role="template:(section %n)"/>
+   <function>lor</function> 
+       <xref linkend="functionref_lor" role="template:(section %n)"/>
+   <function>lnot</function> 
+       <xref linkend="functionref_lnot" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/max.xml
===================================================================
--- doc/manual/max.xml	(revision 0)
+++ doc/manual/max.xml	(revision 0)
@@ -0,0 +1,211 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_max">
+ <title><function>max</function>
+  <indexterm><primary><function>max</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise maxima.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>max</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>max</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>max</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>max</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>max</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>max</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>max</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>max</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>max</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the maxima of the
+   corresponding elements of the two arguments.  For instance, if the
+   arguments are vectors, <literal>Z = max(A, B)</literal> produces a
+   result equivalent to <literal>Z(i) = max(A(i), B(i))</literal> for
+   all of the elements of the vector.  If either of the arguments is a
+   scalar, it is compared with all of the elements of the other
+   argument; for example, <literal>Z = max(A, b)</literal> produces
+   <literal>Z(i) = max(A(i), b)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = max(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>maxmg</function> 
+       <xref linkend="functionref_maxmg" role="template:(section %n)"/>
+   <function>maxmgsq</function> 
+       <xref linkend="functionref_maxmgsq" role="template:(section %n)"/>
+   <function>min</function> 
+       <xref linkend="functionref_min" role="template:(section %n)"/>
+   <function>minmg</function> 
+       <xref linkend="functionref_minmg" role="template:(section %n)"/>
+   <function>minmgsq</function> 
+       <xref linkend="functionref_minmgsq" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/ge.xml
===================================================================
--- doc/manual/ge.xml	(revision 0)
+++ doc/manual/ge.xml	(revision 0)
@@ -0,0 +1,222 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_ge">
+ <title><function>ge</function>
+  <indexterm><primary><function>ge</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise greater-than or equal comparison.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>ge</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>ge</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>ge</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>ge</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>ge</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>ge</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>ge</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>ge</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>ge</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Operator Syntax:</title>
+  <para>
+   Greater-than or equal comparison can also be written in operator
+   form.  <literal>ge(A, B)</literal> is equivalent to <literal>A &gt;=
+   B</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to true if the
+   corresponding elements of the first argument is greater-than or
+   equal the second argument, false otherwise.  For instance, if the
+   arguments are vectors, <literal>Z = ge(A, B)</literal> produces a
+   result equivalent to <literal>Z(i) = A(i) &gt;= B(i)</literal> for all
+   of the elements of the vector.  If either of the arguments is a
+   scalar, it is compared to all of the elements of the other
+   argument; for example, <literal>Z = ge(A, b)</literal> produces
+   <literal>Z(i) = A(i) &gt;= b</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;bool&gt; Z;
+Vector&lt;float&gt; A, B;
+Z = ge(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>eq</function> 
+       <xref linkend="functionref_eq" role="template:(section %n)"/>
+   <function>gt</function> 
+       <xref linkend="functionref_gt" role="template:(section %n)"/>
+   <function>le</function> 
+       <xref linkend="functionref_le" role="template:(section %n)"/>
+   <function>lt</function> 
+       <xref linkend="functionref_lt" role="template:(section %n)"/>
+   <function>ne</function> 
+       <xref linkend="functionref_ne" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/lor.xml
===================================================================
--- doc/manual/lor.xml	(revision 0)
+++ doc/manual/lor.xml	(revision 0)
@@ -0,0 +1,211 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_lor">
+ <title><function>lor</function>
+  <indexterm><primary><function>lor</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise logical or.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>lor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>lor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>lor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>lor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>lor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>lor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>lor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>lor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>lor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+  <para>
+   Value type T must support logical negation (bool, char, int, and so
+   on).
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the logical or of the
+   corresponding elements of the arguments.  For instance, if the
+   arguments are vectors, <literal>Z = lor(A, B)</literal> produces a
+   result equivalent to <literal>Z(i) = lor(A(i), B(i))</literal> for
+   all of the elements of the vector.  If either of the arguments is a
+   scalar, it is logical ored to all all of the elements of the other
+   argument; for example, <literal>Z = lor(A, b)</literal> produces
+   <literal>Z(i) = lor(A(i), b)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;bool&gt; Z, A, B;
+Z = lor(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>land</function> 
+       <xref linkend="functionref_land" role="template:(section %n)"/>
+   <function>lnot</function> 
+       <xref linkend="functionref_lnot" role="template:(section %n)"/>
+   <function>lxor</function> 
+       <xref linkend="functionref_lxor" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/pow.xml
===================================================================
--- doc/manual/pow.xml	(revision 0)
+++ doc/manual/pow.xml	(revision 0)
@@ -0,0 +1,207 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_pow">
+ <title><function>pow</function>
+  <indexterm><primary><function>pow</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise raise to power.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>pow</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>pow</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>pow</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>pow</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>pow</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>pow</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>pow</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>pow</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>pow</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the power of the
+   corresponding elements of the first argument to the second
+   argument.  For instance, if the arguments are vectors, <literal>Z =
+   pow(A, B)</literal> produces a result equivalent to <literal>Z(i) =
+   pow(A(i) ** B(i))</literal> for all of the elements of the vector.
+   If either of the arguments is a scalar, it is used with all of the
+   elements of the other argument; for example, <literal>Z = pow(A,
+   b)</literal> produces <literal>Z(i) = A(i) ** b</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = pow(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>div</function> 
+       <xref linkend="functionref_div" role="template:(section %n)"/>
+   <function>mul</function> 
+       <xref linkend="functionref_mul" role="template:(section %n)"/>
+   <function>sub</function> 
+       <xref linkend="functionref_sub" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/gt.xml
===================================================================
--- doc/manual/gt.xml	(revision 0)
+++ doc/manual/gt.xml	(revision 0)
@@ -0,0 +1,221 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_gt">
+ <title><function>gt</function>
+  <indexterm><primary><function>gt</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise greater-than comparison.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>gt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>gt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>gt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>gt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>gt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>gt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>gt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>gt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>gt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Operator Syntax:</title>
+  <para>
+   Greater-than comparison can also be written in operator form.
+   <literal>gt(A, B)</literal> is equivalent to <literal>A &gt;
+   B</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to true if the
+   corresponding elements of the first argument is greater-than the
+   second argument, false otherwise.  For instance, if the arguments
+   are vectors, <literal>Z = gt(A, B)</literal> produces a result
+   equivalent to <literal>Z(i) = A(i) &gt; B(i)</literal> for all of
+   the elements of the vector.  If either of the arguments is a
+   scalar, it is compared to all of the elements of the other
+   argument; for example, <literal>Z = gt(A, b)</literal> produces
+   <literal>Z(i) = A(i) &gt; b</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = gt(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>eq</function> 
+       <xref linkend="functionref_eq" role="template:(section %n)"/>
+   <function>ge</function> 
+       <xref linkend="functionref_ge" role="template:(section %n)"/>
+   <function>le</function> 
+       <xref linkend="functionref_le" role="template:(section %n)"/>
+   <function>lt</function> 
+       <xref linkend="functionref_lt" role="template:(section %n)"/>
+   <function>ne</function> 
+       <xref linkend="functionref_ne" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/sbm.xml
===================================================================
--- doc/manual/sbm.xml	(revision 0)
+++ doc/manual/sbm.xml	(revision 0)
@@ -0,0 +1,131 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_sbm">
+ <title><function>sbm</function>
+  <indexterm><primary><function>sbm</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise subtraction-multiplication.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>sbm</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>sbm</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>sbm</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+ </formalpara>
+
+ <formalpara>
+  <title>Operator Syntax:</title>
+  <para>
+   Addition can also be written in operator form.  <literal>sbm(A, B,
+   C)</literal> is equivalent to <literal>(A + B) * C</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   It is permissible for arguments to be scalar instead of a view.
+   Scalars are treated a view with constant value.
+  </para>
+  <para>
+   If multiple arguments are non-scalar, they must be the same size in
+   each dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is equal to the difference-product
+   of the corresponding elements of the arguments.  For instance,
+   if the arguments are vectors, <literal>Z = sbm(A, B, C)</literal>
+   produces a result equivalent to <literal>Z(i) = (A(i) - B(i)) *
+   C(i)</literal> for all of the elements of the vector.  If any of
+   the arguments are scalar, they are processed with all of the elements
+   of the other arguments; for example, <literal>Z = sbm(A, b,
+   C)</literal> produces <literal>Z(i) = (A(i) - b) * C</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B, C;
+Z = sbm(A, B, C);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>am</function> 
+       <xref linkend="functionref_am" role="template:(section %n)"/>
+   <function>ma</function> 
+       <xref linkend="functionref_ma" role="template:(section %n)"/>
+   <function>msb</function> 
+       <xref linkend="functionref_msb" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/le.xml
===================================================================
--- doc/manual/le.xml	(revision 0)
+++ doc/manual/le.xml	(revision 0)
@@ -0,0 +1,221 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_le">
+ <title><function>le</function>
+  <indexterm><primary><function>le</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise less-than or equal comparison.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>le</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>le</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>le</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>le</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>le</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>le</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>le</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>le</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>le</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Operator Syntax:</title>
+  <para>
+   less-than or equal comparison can also be written in operator
+   form.  <literal>le(A, B)</literal> is equivalent to <literal>A &lt;=
+   B</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to true if the
+   corresponding elements of the first argument is less-than or
+   equal the second argument, false otherwise.  For instance, if the
+   arguments are vectors, <literal>Z = le(A, B)</literal> produces a
+   result equivalent to <literal>Z(i) = A(i) &lt;= B(i)</literal> for all
+   of the elements of the vector.  If either of the arguments is a
+   scalar, it is compared to all of the elements of the other
+   argument; for example, <literal>Z = le(A, b)</literal> produces
+   <literal>Z(i) = A(i) &lt;= b</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = le(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>eq</function> 
+       <xref linkend="functionref_eq" role="template:(section %n)"/>
+   <function>ge</function> 
+       <xref linkend="functionref_ge" role="template:(section %n)"/>
+   <function>gt</function> 
+       <xref linkend="functionref_gt" role="template:(section %n)"/>
+   <function>lt</function> 
+       <xref linkend="functionref_lt" role="template:(section %n)"/>
+   <function>ne</function> 
+       <xref linkend="functionref_ne" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/band.xml
===================================================================
--- doc/manual/band.xml	(revision 0)
+++ doc/manual/band.xml	(revision 0)
@@ -0,0 +1,211 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_band">
+ <title><function>band</function>
+  <indexterm><primary><function>band</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise bitwise and.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>band</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>band</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>band</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>band</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>band</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>band</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>band</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>band</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>band</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+  <para>
+   Value type T must support bitwise negation (bool, char, int, and so
+   on).
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the bitwise and of the
+   corresponding elements of the arguments.  For instance, if the
+   arguments are vectors, <literal>Z = band(A, B)</literal> produces a
+   result equivalent to <literal>Z(i) = band(A(i), B(i))</literal> for
+   all of the elements of the vector.  If either of the arguments is a
+   scalar, it is bitwise anded to all all of the elements of the other
+   argument; for example, <literal>Z = band(A, b)</literal> produces
+   <literal>Z(i) = band(A(i), b)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;int&gt; Z, A, B;
+Z = band(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>bnot</function> 
+       <xref linkend="functionref_bnot" role="template:(section %n)"/>
+   <function>bor</function> 
+       <xref linkend="functionref_bor" role="template:(section %n)"/>
+   <function>bxor</function> 
+       <xref linkend="functionref_bxor" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/atan2.xml
===================================================================
--- doc/manual/atan2.xml	(revision 0)
+++ doc/manual/atan2.xml	(revision 0)
@@ -0,0 +1,206 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_atan2">
+ <title><function>atan2</function>
+  <indexterm><primary><function>atan2</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise arc tangent of a quotient.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>atan2</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>atan2</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>atan2</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>atan2</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>atan2</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>atan2</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>atan2</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>atan2</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>atan2</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is equal to the arc tangent of the
+   quotient of the elements of the two arguments.  For instance, if
+   the arguments are vectors, <literal>Z = atan2(A, B)</literal>
+   produces a result equivalent to <literal>Z(i) = atan2(A(i),
+   B(i))</literal> for all of the elements of the vector.  If either
+   of the arguments is a scalar, it is used as part of the quotient
+   for all of the elements of the other argument; for example,
+   <literal>Z = atan2(A, b)</literal> produces <literal>Z(i) = atan2(A(i),
+   b)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = atan2(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>atan</function> 
+       <xref linkend="functionref_atan" role="template:(section %n)"/>
+   <function>tan</function> 
+       <xref linkend="functionref_tan" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/jmul.xml
===================================================================
--- doc/manual/jmul.xml	(revision 0)
+++ doc/manual/jmul.xml	(revision 0)
@@ -0,0 +1,208 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_jmul">
+ <title><function>jmul</function>
+  <indexterm><primary><function>jmul</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise multiplication by conjugate.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>jmul</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>jmul</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>jmul</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>jmul</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>jmul</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>jmul</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>jmul</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>jmul</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>jmul</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+
+  <para>
+   Value type must be complex.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the product of the
+   corresponding element of the first argument with the conjugate of
+   the second argument.  For instance, if the arguments are vectors,
+   <literal>Z = jmul(A, B)</literal> produces a result equivalent to
+   <literal>Z(i) = A(i) * conj(B(i))</literal> for all of the elements
+   of the vector.  If either of the arguments is a scalar, it is
+   scales all of the elements of the other argument; for example,
+   <literal>Z = jmul(A, b)</literal> produces <literal>Z(i) = A(i) *
+   conj(b)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;complex&lt;float&gt; &gt; Z, A, B;
+Z = jmul(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>mul</function> 
+       <xref linkend="functionref_mul" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/expoavg.xml
===================================================================
--- doc/manual/expoavg.xml	(revision 0)
+++ doc/manual/expoavg.xml	(revision 0)
@@ -0,0 +1,126 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_expoavg">
+ <title><function>expoavg</function>
+  <indexterm><primary><function>expoavg</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise exponential average.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>expoavg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>expoavg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>expoavg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+ </formalpara>
+
+ <formalpara>
+  <title>Operator Syntax:</title>
+  <para>
+   Addition can also be written in operator form.  <literal>expoavg(A, B,
+   C)</literal> is equivalent to <literal>A*B + (1-A)*C</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   It is permissible for arguments to be scalar instead of a view.
+   Scalars are treated a view with constant value.
+  </para>
+  <para>
+   If multiple arguments are non-scalar, they must be the same size in
+   each dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is equal to the exponential
+   average of the corresponding elements of the arguments.  For
+   instance, if the arguments are vectors, <literal>Z = expoavg(A, B,
+   C)</literal> produces a result equivalent to <literal>Z(i) = A(i) *
+   B(i)) + (1 - A(i)) * C(i)</literal> for all of the elements of the
+   vector.  If any of the arguments are scalar, they are processed
+   with all of the elements of the other arguments; for example,
+   <literal>Z = expoavg(A, b, C)</literal> produces <literal>Z(i) =
+   A(i) * b + (1 - A(i)) * C(i)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B, C;
+Z = expoavg(A, B, C);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/bxor.xml
===================================================================
--- doc/manual/bxor.xml	(revision 0)
+++ doc/manual/bxor.xml	(revision 0)
@@ -0,0 +1,212 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_bxor">
+ <title><function>bxor</function>
+  <indexterm><primary><function>bxor</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise bitwise exclusive or.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>bxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>bxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>bxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>bxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>bxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>bxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>bxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>bxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>bxor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+  <para>
+   Value type T must support bitwise negation (bool, char, int, and so
+   on).
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the bitwise exclusive or
+   of the corresponding elements of the arguments.  For instance, if
+   the arguments are vectors, <literal>Z = bxor(A, B)</literal>
+   produces a result equivalent to <literal>Z(i) = bxor(A(i),
+   B(i))</literal> for all of the elements of the vector.  If either
+   of the arguments is a scalar, it is bitwise exclusive ored to all
+   all of the elements of the other argument; for example, <literal>Z
+   = bxor(A, b)</literal> produces <literal>Z(i) = bxor(A(i),
+   b)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;int&gt; Z, A, B;
+Z = bxor(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>band</function> 
+       <xref linkend="functionref_band" role="template:(section %n)"/>
+   <function>bor</function> 
+       <xref linkend="functionref_bor" role="template:(section %n)"/>
+   <function>bnot</function> 
+       <xref linkend="functionref_bnot" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/minmgsq.xml
===================================================================
--- doc/manual/minmgsq.xml	(revision 0)
+++ doc/manual/minmgsq.xml	(revision 0)
@@ -0,0 +1,213 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_minmgsq">
+ <title><function>minmgsq</function>
+  <indexterm><primary><function>minmgsq</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise magnitude-squared minima.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>minmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>minmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>minmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>minmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>minmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>minmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>minmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>minmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>minmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the minima of the
+   magnitudes squared of the corresponding elements of the two
+   arguments.  For instance, if the arguments are vectors, <literal>Z
+   = minmgsq(A, B)</literal> produces a result equivalent to
+   <literal>Z(i) = min(mag(sq(A(i))), mag(sq(B(i))))</literal> for all
+   of the elements of the vector.  If either of the arguments is a
+   scalar, it is compared with all of the elements of the other
+   argument; for example, <literal>Z = minmgsq(A, b)</literal>
+   produces <literal>Z(i) = min(mag(sq(A(i))), mag(sq(b)))</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z;
+Vector&lt;complex&lt;float&gt; &gt; A, B;
+Z = minmgsq(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>max</function> 
+       <xref linkend="functionref_max" role="template:(section %n)"/>
+   <function>maxmg</function> 
+       <xref linkend="functionref_maxmg" role="template:(section %n)"/>
+   <function>maxmgsq</function> 
+       <xref linkend="functionref_maxmgsq" role="template:(section %n)"/>
+   <function>min</function> 
+       <xref linkend="functionref_min" role="template:(section %n)"/>
+   <function>minmg</function> 
+       <xref linkend="functionref_minmg" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/maxmgsq.xml
===================================================================
--- doc/manual/maxmgsq.xml	(revision 0)
+++ doc/manual/maxmgsq.xml	(revision 0)
@@ -0,0 +1,212 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_maxmgsq">
+ <title><function>maxmgsq</function>
+  <indexterm><primary><function>maxmgsq</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise magnitude-squared maxima.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>maxmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>maxmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>maxmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>maxmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>maxmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>maxmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>maxmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>maxmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>maxmgsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the maxima of the
+   magnitudes squared of the corresponding elements of the two
+   arguments.  For instance, if the arguments are vectors, <literal>Z
+   = maxmgsq(A, B)</literal> produces a result equivalent to
+   <literal>Z(i) = max(mag(sq(A(i))), mag(sq(B(i))))</literal> for all
+   of the elements of the vector.  If either of the arguments is a
+   scalar, it is compared with all of the elements of the other
+   argument; for example, <literal>Z = maxmgsq(A, b)</literal>
+   produces <literal>Z(i) = max(mag(sq(A(i))), mag(sq(b)))</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = maxmgsq(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>max</function> 
+       <xref linkend="functionref_max" role="template:(section %n)"/>
+   <function>maxmg</function> 
+       <xref linkend="functionref_maxmg" role="template:(section %n)"/>
+   <function>min</function> 
+       <xref linkend="functionref_min" role="template:(section %n)"/>
+   <function>minmg</function> 
+       <xref linkend="functionref_minmg" role="template:(section %n)"/>
+   <function>minmgsq</function> 
+       <xref linkend="functionref_minmgsq" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/lt.xml
===================================================================
--- doc/manual/lt.xml	(revision 0)
+++ doc/manual/lt.xml	(revision 0)
@@ -0,0 +1,221 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_lt">
+ <title><function>lt</function>
+  <indexterm><primary><function>lt</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise less-than comparison.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>lt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>lt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>lt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>lt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>lt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>lt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>lt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>lt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>lt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Operator Syntax:</title>
+  <para>
+   Less-than comparison can also be written in operator form.
+   <literal>lt(A, B)</literal> is equivalent to <literal>A &lt;
+   B</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to true if the
+   corresponding elements of the first argument is less-than the
+   second argument, false otherwise.  For instance, if the arguments
+   are vectors, <literal>Z = lt(A, B)</literal> produces a result
+   equivalent to <literal>Z(i) = A(i) &lt; B(i)</literal> for all of
+   the elements of the vector.  If either of the arguments is a
+   scalar, it is compared to all of the elements of the other
+   argument; for example, <literal>Z = lt(A, b)</literal> produces
+   <literal>Z(i) = A(i) &lt; b</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = lt(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>eq</function> 
+       <xref linkend="functionref_eq" role="template:(section %n)"/>
+   <function>ge</function> 
+       <xref linkend="functionref_ge" role="template:(section %n)"/>
+   <function>gt</function> 
+       <xref linkend="functionref_gt" role="template:(section %n)"/>
+   <function>le</function> 
+       <xref linkend="functionref_le" role="template:(section %n)"/>
+   <function>ne</function> 
+       <xref linkend="functionref_ne" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/msb.xml
===================================================================
--- doc/manual/msb.xml	(revision 0)
+++ doc/manual/msb.xml	(revision 0)
@@ -0,0 +1,131 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_msb">
+ <title><function>msb</function>
+  <indexterm><primary><function>msb</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise multiplication-addition.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>msb</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>msb</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>msb</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+ </formalpara>
+
+ <formalpara>
+  <title>Operator Syntax:</title>
+  <para>
+   Addition can also be written in operator form.  <literal>msb(A, B,
+   C)</literal> is equivalent to <literal>(A * B) - C</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   It is permissible for arguments to be scalar instead of a view.
+   Scalars are treated a view with constant value.
+  </para>
+  <para>
+   If multiple arguments are non-scalar, they must be the same size in
+   each dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is equal to the sum-product of the
+   corresponding elements of the arguments.  For instance, if the
+   arguments are vectors, <literal>Z = msb(A, B, C)</literal> produces
+   a result equivalent to <literal>Z(i) = (A(i) * B(i)) -
+   C(i)</literal> for all of the elements of the vector.  If any of
+   the arguments are scalar, they are processed with all of the
+   elements of the other arguments; for example, <literal>Z = msb(A, b,
+   C)</literal> produces <literal>Z(i) = (A(i) * b) - C(i)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B, C;
+Z = msb(A, B, C);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>am</function> 
+       <xref linkend="functionref_am" role="template:(section %n)"/>
+   <function>msb</function> 
+       <xref linkend="functionref_ma" role="template:(section %n)"/>
+   <function>sbm</function> 
+       <xref linkend="functionref_sbm" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/ma.xml
===================================================================
--- doc/manual/ma.xml	(revision 0)
+++ doc/manual/ma.xml	(revision 0)
@@ -0,0 +1,131 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_ma">
+ <title><function>ma</function>
+  <indexterm><primary><function>ma</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise multiplication-addition.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>ma</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>ma</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>ma</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+ </formalpara>
+
+ <formalpara>
+  <title>Operator Syntax:</title>
+  <para>
+   Addition can also be written in operator form.  <literal>ma(A, B,
+   C)</literal> is equivalent to <literal>(A * B) + C</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   It is permissible for arguments to be scalar instead of a view.
+   Scalars are treated a view with constant value.
+  </para>
+  <para>
+   If multiple arguments are non-scalar, they must be the same size in
+   each dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is equal to the sum-product of the
+   corresponding elements of the arguments.  For instance, if the
+   arguments are vectors, <literal>Z = ma(A, B, C)</literal> produces
+   a result equivalent to <literal>Z(i) = (A(i) * B(i)) +
+   C(i)</literal> for all of the elements of the vector.  If any of
+   the arguments are scalar, they are processed with all of the elements
+   of the other arguments; for example, <literal>Z = ma(A, b,
+   C)</literal> produces <literal>Z(i) = (A(i) * b) + C(i)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B, C;
+Z = ma(A, B, C);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>am</function> 
+       <xref linkend="functionref_am" role="template:(section %n)"/>
+   <function>msb</function> 
+       <xref linkend="functionref_msb" role="template:(section %n)"/>
+   <function>sbm</function> 
+       <xref linkend="functionref_sbm" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/am.xml
===================================================================
--- doc/manual/am.xml	(revision 0)
+++ doc/manual/am.xml	(revision 0)
@@ -0,0 +1,131 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_am">
+ <title><function>am</function>
+  <indexterm><primary><function>am</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise addition-multiplication.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>am</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>am</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>am</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+ </formalpara>
+
+ <formalpara>
+  <title>Operator Syntax:</title>
+  <para>
+   Addition can also be written in operator form.  <literal>am(A, B,
+   C)</literal> is equivalent to <literal>(A + B) * C</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   It is permissible for arguments to be scalar instead of a view.
+   Scalars are treated a view with constant value.
+  </para>
+  <para>
+   If multiple arguments are non-scalar, they must be the same size in
+   each dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is equal to the sum-product of the
+   corresponding elements of the arguments.  For instance, if the
+   arguments are vectors, <literal>Z = am(A, B, C)</literal> produces
+   a result equivalent to <literal>Z(i) = (A(i) + B(i)) *
+   C(i)</literal> for all of the elements of the vector.  If any of
+   the arguments are scalar, they are processed with all of the elements
+   of the other arguments; for example, <literal>Z = am(A, b,
+   C)</literal> produces <literal>Z(i) = (A(i) + b) * C</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B, C;
+Z = am(A, B, C);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>ma</function> 
+       <xref linkend="functionref_ma" role="template:(section %n)"/>
+   <function>msb</function> 
+       <xref linkend="functionref_msb" role="template:(section %n)"/>
+   <function>sbm</function> 
+       <xref linkend="functionref_sbm" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/hypot.xml
===================================================================
--- doc/manual/hypot.xml	(revision 0)
+++ doc/manual/hypot.xml	(revision 0)
@@ -0,0 +1,204 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_hypot">
+ <title><function>hypot</function>
+  <indexterm><primary><function>hypot</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Hypotenuse of right triangle.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>hypot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>hypot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>hypot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>hypot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>hypot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>hypot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>hypot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>hypot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>hypot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the square-root of the
+   sum of sqaures of the corresponding elements of the two arguments.
+   For instance, if the arguments are vectors, <literal>Z = hypot(A,
+   B)</literal> produces a result equivalent to <literal>Z(i) =
+   sqrt(sq(A(i)) + sq(B(i)))</literal> for all of the elements of the
+   vector.  If either of the arguments is a scalar, it is used with
+   all of the elements of the other argument; for example, <literal>Z
+   = hypot(A, b)</literal> produces <literal>Z(i) = sqrt(sq(A(i)) +
+   sq(b))</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = hypot(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>atan2</function> 
+       <xref linkend="functionref_atan2" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/eq.xml
===================================================================
--- doc/manual/eq.xml	(revision 0)
+++ doc/manual/eq.xml	(revision 0)
@@ -0,0 +1,221 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_eq">
+ <title><function>eq</function>
+  <indexterm><primary><function>eq</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise equality comparison.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>eq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>eq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>eq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>eq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>eq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>eq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>eq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>eq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>eq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Operator Syntax:</title>
+  <para>
+   Equality comparison can also be written in operator form.
+   <literal>eq(A, B)</literal> is equivalent to <literal>A ==
+   B</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to true if the corresponding
+   elements of the two arguments are equal, false otherwise.
+   For instance, if the arguments are
+   vectors, <literal>Z = eq(A, B)</literal> produces a result equivalent to
+   <literal>Z(i) = A(i) == B(i)</literal> for all of the elements of the
+   vector.  If either of the arguments is a scalar, it is compared to all of
+   the elements of the other argument; for example,
+   <literal>Z = eq(A, b)</literal> produces 
+   <literal>Z(i) = A(i) == b</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = eq(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>ge</function> 
+       <xref linkend="functionref_ge" role="template:(section %n)"/>
+   <function>gt</function> 
+       <xref linkend="functionref_gt" role="template:(section %n)"/>
+   <function>le</function> 
+       <xref linkend="functionref_le" role="template:(section %n)"/>
+   <function>lt</function> 
+       <xref linkend="functionref_lt" role="template:(section %n)"/>
+   <function>ne</function> 
+       <xref linkend="functionref_ne" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/functions.xml
===================================================================
--- doc/manual/functions.xml	(revision 220851)
+++ doc/manual/functions.xml	(working copy)
@@ -30,33 +30,62 @@
   <title>Elementwise Functions</title>
   <xi:include href="acos.xml" />
   <xi:include href="add.xml" />
+  <xi:include href="am.xml" />
   <xi:include href="arg.xml" />
   <xi:include href="asin.xml" />
   <xi:include href="atan.xml" />
+  <xi:include href="atan2.xml" />
+  <xi:include href="band.xml" />
+  <xi:include href="bor.xml" />
   <xi:include href="bnot.xml" />
+  <xi:include href="bxor.xml" />
   <xi:include href="ceil.xml" />
   <xi:include href="conj.xml" />
   <xi:include href="cos.xml" />
   <xi:include href="cosh.xml" />
   <xi:include href="div.xml" />
+  <xi:include href="eq.xml" />
   <xi:include href="euler.xml" />
   <xi:include href="exp.xml" />
   <xi:include href="exp10.xml" />
+  <xi:include href="expoavg.xml" />
   <xi:include href="floor.xml" />
+  <xi:include href="fmod.xml" />
+  <xi:include href="ge.xml" />
+  <xi:include href="gt.xml" />
+  <xi:include href="hypot.xml" />
   <xi:include href="imag.xml" />
   <xi:include href="is_finite.xml" />
   <xi:include href="is_nan.xml" />
   <xi:include href="is_normal.xml" />
+  <xi:include href="ite.xml" />
+  <xi:include href="jmul.xml" />
+  <xi:include href="land.xml" />
+  <xi:include href="le.xml" />
   <xi:include href="lnot.xml" />
   <xi:include href="log.xml" />
   <xi:include href="log10.xml" />
+  <xi:include href="lor.xml" />
+  <xi:include href="lt.xml" />
+  <xi:include href="lxor.xml" />
+  <xi:include href="ma.xml" />
   <xi:include href="mag.xml" />
   <xi:include href="magsq.xml" />
+  <xi:include href="max.xml" />
+  <xi:include href="maxmg.xml" />
+  <xi:include href="maxmgsq.xml" />
+  <xi:include href="min.xml" />
+  <xi:include href="minmg.xml" />
+  <xi:include href="minmgsq.xml" />
+  <xi:include href="msb.xml" />
   <xi:include href="mul.xml" />
+  <xi:include href="ne.xml" />
   <xi:include href="neg.xml" />
+  <xi:include href="pow.xml" />
   <xi:include href="real.xml" />
   <xi:include href="recip.xml" />
   <xi:include href="rsqrt.xml" />
+  <xi:include href="sbm.xml" />
   <xi:include href="sin.xml" />
   <xi:include href="sinh.xml" />
   <xi:include href="sq.xml" />
Index: doc/manual/ite.xml
===================================================================
--- doc/manual/ite.xml	(revision 0)
+++ doc/manual/ite.xml	(revision 0)
@@ -0,0 +1,118 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_ite">
+ <title><function>ite</function>
+  <indexterm><primary><function>ite</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise if-then-else.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>ite</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;bool&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>ite</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;bool&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>ite</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;bool&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>C</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   It is permissible for arguments to be scalar instead of a view.
+   Scalars are treated a view with constant value.
+  </para>
+  <para>
+   If multiple arguments are non-scalar, they must be the same size in
+   each dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is equal to the if-then-else
+   evaluation of the corresponding elements of the arguments.  For
+   instance, if the arguments are vectors, <literal>Z = ite(A, B,
+   C)</literal> produces a result equivalent to <literal>Z(i) = A(i) ?
+   B(i) : C(i)</literal> for all of the elements of the
+   vector.  If any of the arguments are scalar, they are processed
+   with all of the elements of the other arguments; for example,
+   <literal>Z = ite(A, b, C)</literal> produces <literal>Z(i) =
+   A(i) ? b : C(i)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B, C;
+Z = ite(A, B, C);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/operations.xml
===================================================================
--- doc/manual/operations.xml	(revision 220851)
+++ doc/manual/operations.xml	(working copy)
@@ -515,6 +515,295 @@
   </section>
 
   <section>
+   <title>Vector Arithmetic Elementwise Binary Operations and Functions</title>
+   <para>
+    The following elementwise binary operations can be performed on
+    vectors, producing a vector result:
+
+    <variablelist>
+
+     <varlistentry>
+      <term><literal>add(A)</literal></term>
+      <listitem>
+       Addition
+       <xref linkend="functionref_add" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>atan2(A)</literal></term>
+      <listitem>
+       Arc tangent of quotient
+       <xref linkend="functionref_atan2" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>band(A)</literal></term>
+      <listitem>
+       Bitwise and
+       <xref linkend="functionref_band" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>bor(A)</literal></term>
+      <listitem>
+       Bitwise or
+       <xref linkend="functionref_bor" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>bxor(A)</literal></term>
+      <listitem>
+       Bitwise exclusive or
+       <xref linkend="functionref_bxor" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>div(A)</literal></term>
+      <listitem>
+       Division
+       <xref linkend="functionref_div" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>eq(A)</literal></term>
+      <listitem>
+       Equality comparison
+       <xref linkend="functionref_eq" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>fmod(A)</literal></term>
+      <listitem>
+       Floating-point modulo (remainder after division)
+       <xref linkend="functionref_fmod" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>ge(A)</literal></term>
+      <listitem>
+       Greater-than or equal comparison
+       <xref linkend="functionref_ge" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>gt(A)</literal></term>
+      <listitem>
+       Greater-than comparison
+       <xref linkend="functionref_gt" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>hypot(A)</literal></term>
+      <listitem>
+       Hypotenuse of right triangle
+       <xref linkend="functionref_hypot" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>jmul(A)</literal></term>
+      <listitem>
+       Conjugate multiply
+       <xref linkend="functionref_jmul" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>land(A)</literal></term>
+      <listitem>
+       Logical and
+       <xref linkend="functionref_land" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>le(A)</literal></term>
+      <listitem>
+       Less-than or equal comparison
+       <xref linkend="functionref_le" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>lor(A)</literal></term>
+      <listitem>
+       Logical or
+       <xref linkend="functionref_lor" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>lt(A)</literal></term>
+      <listitem>
+       Less-than comparison
+       <xref linkend="functionref_lt" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>lxor(A)</literal></term>
+      <listitem>
+       Logical exclusive or
+       <xref linkend="functionref_lxor" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>max(A)</literal></term>
+      <listitem>
+       Maxima
+       <xref linkend="functionref_max" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>maxmg(A)</literal></term>
+      <listitem>
+       Magnitude maxima
+       <xref linkend="functionref_maxmg" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>maxmgsq(A)</literal></term>
+      <listitem>
+       Magnitude squared maxima
+       <xref linkend="functionref_maxmgsq" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>min(A)</literal></term>
+      <listitem>
+       Minima
+       <xref linkend="functionref_min" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>minmg(A)</literal></term>
+      <listitem>
+       Magnitude minima
+       <xref linkend="functionref_minmg" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>minmgsq(A)</literal></term>
+      <listitem>
+       Magnitude squared minima
+       <xref linkend="functionref_minmgsq" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>mul(A)</literal></term>
+      <listitem>
+       Multiplication
+       <xref linkend="functionref_mul" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+
+     <varlistentry>
+      <term><literal>ne(A)</literal></term>
+      <listitem>
+       Not equal comparison
+       <xref linkend="functionref_ne" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>pow(A)</literal></term>
+      <listitem>
+       Raise to power
+       <xref linkend="functionref_pow" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>sub(A)</literal></term>
+      <listitem>
+       Subtract
+       <xref linkend="functionref_sub" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+    </variablelist>
+   </para>
+  </section>
+
+  <section>
+   <title>Vector Arithmetic Elementwise Ternary Operations and Functions</title>
+   <para>
+    The following elementwise ternary operations can be performed on
+    vectors, producing a vector result:
+
+    <variablelist>
+
+     <varlistentry>
+      <term><literal>am(A)</literal></term>
+      <listitem>
+       Fused addition-multiplication
+       <xref linkend="functionref_am" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>expoavg(A)</literal></term>
+      <listitem>
+       Exponential average
+       <xref linkend="functionref_expoavg" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>ite(A)</literal></term>
+      <listitem>
+       Addition
+       <xref linkend="functionref_ite" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>ma(A)</literal></term>
+      <listitem>
+       Fused multiplication-addition
+       <xref linkend="functionref_ma" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>msb(A)</literal></term>
+      <listitem>
+       Fused multiplication-subtraction
+       <xref linkend="functionref_msb" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>sbm(A)</literal></term>
+      <listitem>
+       Fused subtraction-multiplication
+       <xref linkend="functionref_sbm" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+    </variablelist>
+   </para>
+  </section>
+
+  <section>
    <title>Vector Type Conversions</title>
    <para>
     A vector with one type of values can be converted a vector with
Index: doc/manual/fmod.xml
===================================================================
--- doc/manual/fmod.xml	(revision 0)
+++ doc/manual/fmod.xml	(revision 0)
@@ -0,0 +1,201 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_fmod">
+ <title><function>fmod</function>
+  <indexterm><primary><function>fmod</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Floating-point modulo (remainder after division).
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>fmod</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>fmod</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>fmod</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>fmod</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>fmod</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>fmod</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>fmod</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>fmod</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>fmod</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is equal to the sum of the corresponding
+   elements of the two arguments.  For instance, if the arguments are
+   vectors, <literal>Z = fmod(A, B)</literal> produces a result equivalent to
+   <literal>Z(i) = fmod(A(i), B(i))</literal> for all of the elements of the
+   vector.  If either of the arguments is a scalar, it is fmoded to all of
+   the elements of the other argument; for example,
+   <literal>Z = fmod(A, b)</literal> produces 
+   <literal>Z(i) = fmod(A(i), b)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = fmod(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/ne.xml
===================================================================
--- doc/manual/ne.xml	(revision 0)
+++ doc/manual/ne.xml	(revision 0)
@@ -0,0 +1,222 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_ne">
+ <title><function>ne</function>
+  <indexterm><primary><function>ne</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise not-equal comparison.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>ne</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>ne</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>ne</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>ne</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>ne</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>ne</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>ne</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>ne</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>ne</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Operator Syntax:</title>
+  <para>
+   Not-equal comparison can also be written in operator form.
+   <literal>ne(A, B)</literal> is equivalent to <literal>A !=
+   B</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to true if the corresponding
+   elements of the two arguments are not equal, false otherwise.
+   For instance, if the arguments are
+   vectors, <literal>Z = ne(A, B)</literal> produces a result equivalent to
+   <literal>Z(i) = A(i) != B(i)</literal> for all of the elements of the
+   vector.  If either of the arguments is a scalar, it is compared to all of
+   the elements of the other argument; for example,
+   <literal>Z = ne(A, b)</literal> produces 
+   <literal>Z(i) = A(i) != b</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;bool&gt; Z;
+Vector&lt;float&gt; A, B;
+Z = ne(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>ge</function> 
+       <xref linkend="functionref_ge" role="template:(section %n)"/>
+   <function>gt</function> 
+       <xref linkend="functionref_gt" role="template:(section %n)"/>
+   <function>le</function> 
+       <xref linkend="functionref_le" role="template:(section %n)"/>
+   <function>lt</function> 
+       <xref linkend="functionref_lt" role="template:(section %n)"/>
+   <function>ne</function> 
+       <xref linkend="functionref_ne" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/minmg.xml
===================================================================
--- doc/manual/minmg.xml	(revision 0)
+++ doc/manual/minmg.xml	(revision 0)
@@ -0,0 +1,213 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_minmg">
+ <title><function>minmg</function>
+  <indexterm><primary><function>minmg</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise magnitude minima.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>minmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>minmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>minmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>minmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>minmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>minmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>minmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>minmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>minmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is equal to the minima of the
+   magnitudes of the corresponding elements of the two arguments.  For
+   instance, if the arguments are vectors, <literal>Z = minmg(A,
+   B)</literal> produces a result equivalent to <literal>Z(i) =
+   min(mag(A(i)), mag(B(i)))</literal> for all of the elements of the vector.
+   If either of the arguments is a scalar, it is compared with all of
+   the elements of the other argument; for example, <literal>Z =
+   minmg(A, b)</literal> produces <literal>Z(i) = min(mag(A(i)),
+   mag(b))</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z;
+Vector&lt;complex&lt;float&gt; &gt; A, B;
+Z = minmg(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>max</function> 
+       <xref linkend="functionref_max" role="template:(section %n)"/>
+   <function>maxmg</function> 
+       <xref linkend="functionref_maxmg" role="template:(section %n)"/>
+   <function>maxmgsq</function> 
+       <xref linkend="functionref_maxmgsq" role="template:(section %n)"/>
+   <function>min</function> 
+       <xref linkend="functionref_min" role="template:(section %n)"/>
+   <function>minmgsq</function> 
+       <xref linkend="functionref_minmgsq" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/maxmg.xml
===================================================================
--- doc/manual/maxmg.xml	(revision 0)
+++ doc/manual/maxmg.xml	(revision 0)
@@ -0,0 +1,212 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_maxmg">
+ <title><function>maxmg</function>
+  <indexterm><primary><function>maxmg</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise magnitude maxima.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>maxmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>maxmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>maxmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>maxmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>maxmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>maxmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>maxmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>maxmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>maxmg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is equal to the maxima of the
+   magnitudes of the corresponding elements of the two arguments.  For
+   instance, if the arguments are vectors, <literal>Z = maxmg(A,
+   B)</literal> produces a result equivalent to <literal>Z(i) =
+   max(mag(A(i)), mag(B(i)))</literal> for all of the elements of the vector.
+   If either of the arguments is a scalar, it is compared with all of
+   the elements of the other argument; for example, <literal>Z =
+   maxmg(A, b)</literal> produces <literal>Z(i) = max(mag(A(i)),
+   mag(b))</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = maxmg(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>max</function> 
+       <xref linkend="functionref_max" role="template:(section %n)"/>
+   <function>maxmgsq</function> 
+       <xref linkend="functionref_maxmgsq" role="template:(section %n)"/>
+   <function>min</function> 
+       <xref linkend="functionref_min" role="template:(section %n)"/>
+   <function>minmg</function> 
+       <xref linkend="functionref_minmg" role="template:(section %n)"/>
+   <function>minmgsq</function> 
+       <xref linkend="functionref_minmgsq" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/land.xml
===================================================================
--- doc/manual/land.xml	(revision 0)
+++ doc/manual/land.xml	(revision 0)
@@ -0,0 +1,210 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_land">
+ <title><function>land</function>
+  <indexterm><primary><function>land</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise logical and.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>land</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>land</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>land</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>land</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>land</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>land</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>land</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>land</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>T</type> <function>a</function>
+     </parameter>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>B</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>land</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+     <parameter>
+      <type>T</type> <function>b</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Requirements:</title>
+  <para>
+   If both arguments are non-scalar, they must be the same size in each
+   dimension.
+  </para>
+  <para>
+   Value type T must be bool.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result value is set to the logical and of the
+   corresponding elements of the arguments.  For instance, if the
+   arguments are vectors, <literal>Z = land(A, B)</literal> produces a
+   result equivalent to <literal>Z(i) = land(A(i), B(i))</literal> for
+   all of the elements of the vector.  If either of the arguments is a
+   scalar, it is logical anded to all all of the elements of the other
+   argument; for example, <literal>Z = land(A, b)</literal> produces
+   <literal>Z(i) = land(A(i), b)</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;bool&gt; Z, A, B;
+Z = land(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>bnot</function> 
+       <xref linkend="functionref_lnot" role="template:(section %n)"/>
+   <function>bor</function> 
+       <xref linkend="functionref_lor" role="template:(section %n)"/>
+   <function>bxor</function> 
+       <xref linkend="functionref_lxor" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
