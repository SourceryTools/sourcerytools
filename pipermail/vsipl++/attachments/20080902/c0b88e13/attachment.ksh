Index: ChangeLog
===================================================================
--- ChangeLog	(revision 218977)
+++ ChangeLog	(working copy)
@@ -1,3 +1,67 @@
+2008-09-02  Jules Bergmann  <jules@codesourcery.com>
+
+	* doc/manual/log.xml: Remove newline after <title>.
+	* doc/manual/log10.xml: Likewise.
+	* doc/manual/div.xml: Likewise.
+	* doc/manual/tan.xml: Likewise.
+	* doc/manual/cos.xml: Likewise.
+	* doc/manual/add.xml: Likewise.
+	* doc/manual/sin.xml: Likewise.
+	* doc/manual/sub.xml: Likewise.
+	* doc/manual/sqrt.xml: Likewise.
+	* doc/manual/mul.xml: Likewise.
+	* doc/manual/sq.xml: Likewise.
+	* doc/manual/mag.xml: Likewise.
+	* doc/manual/magsq.xml: Likewise.
+	* doc/manual/exp.xml: Likewise.
+	* doc/manual/exp10.xml: Likewise.
+	
+	* doc/manual/atan.xml: New file, document arc tangent elementwise
+	  function.
+	* doc/manual/acos.xml: New file, document arc cosine elementwise
+	  function.
+	* doc/manual/tanh.xml: New file, document hypberbolic tangent
+	  elementwise function.
+	* doc/manual/asin.xml: New file, document arc sine elementwise
+	  function.
+	* doc/manual/cosh.xml: New file, document hyperbolic cosine
+	  elementwise function.
+	* doc/manual/arg.xml: New file, document complex arg elementwise
+	  function.
+	* doc/manual/floor.xml: New file, document floating-point floor
+	  elementwise function.
+	* doc/manual/real.xml: New file, document complex real elementwise
+	  function.
+	* doc/manual/is_normal.xml: New file, document floating-point
+	  is_normal elementwise function.
+	* doc/manual/conj.xml: New file, document complex conjugate
+	  elementwise function.
+	* doc/manual/sinh.xml: New file, document hyperbolic sine
+	  elementwise function.
+	* doc/manual/recip.xml: New file, document recipricol elementwise
+	  function.
+	* doc/manual/bnot.xml: New file, document bitwise not elementwise
+	  function.
+	* doc/manual/is_nan.xml: New file, document floating-point is_nan
+	  elementwise function.
+	* doc/manual/is_finite.xml: New file, document floating-point
+	  is_finite elementwise function.
+	* doc/manual/neg.xml: New file, document arithmetic negate
+	  elementwise function.
+	* doc/manual/rsqrt.xml: New file, document recipricol elementwise
+	  function.
+	* doc/manual/ceil.xml: New file, document floating-point ceiling
+	  elementwise function.
+	* doc/manual/lnot.xml: New file, document logical not elementwise
+	  function.
+	* doc/manual/euler.xml: New file, document euler elementwise
+	  function.
+	* doc/manual/imag.xml: New file, document complex imaginary part
+	  elementwise function.
+	
+	* doc/manual/functions.xml: Include new elementwise functions.
+	* doc/manual/operations.xml: Add xrefs to new elementwise functions.
+
 2008-08-27  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/impl_tags.hpp: Add Opt_tag.
Index: doc/manual/log.xml
===================================================================
--- doc/manual/log.xml	(revision 218956)
+++ doc/manual/log.xml	(working copy)
@@ -3,8 +3,7 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_log">
- <title>
-  <function>log</function>
+ <title><function>log</function>
   <indexterm><primary><function>log</function></primary></indexterm>
  </title>
 
Index: doc/manual/log10.xml
===================================================================
--- doc/manual/log10.xml	(revision 218956)
+++ doc/manual/log10.xml	(working copy)
@@ -3,8 +3,7 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_log10">
- <title>
-  <function>log10</function>
+ <title><function>log10</function>
   <indexterm><primary><function>log10</function></primary></indexterm>
  </title>
 
Index: doc/manual/div.xml
===================================================================
--- doc/manual/div.xml	(revision 218956)
+++ doc/manual/div.xml	(working copy)
@@ -3,7 +3,9 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_div">
- <title><function>div</function></title>
+ <title><function>div</function>
+  <indexterm><primary><function>div</function></primary></indexterm>
+ </title>
 
  <formalpara>
   <title>Description:</title>
Index: doc/manual/tan.xml
===================================================================
--- doc/manual/tan.xml	(revision 218956)
+++ doc/manual/tan.xml	(working copy)
@@ -3,8 +3,7 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_tan">
- <title>
-  <function>tan</function>
+ <title><function>tan</function>
   <indexterm><primary><function>tan</function></primary></indexterm>
  </title>
 
Index: doc/manual/atan.xml
===================================================================
--- doc/manual/atan.xml	(revision 0)
+++ doc/manual/atan.xml	(revision 0)
@@ -0,0 +1,95 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_atan">
+ <title><function>atan</function>
+  <indexterm><primary><function>atan</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise arc tangent (inverse tangent).
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>atan</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>atan</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>atan</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to arc or inverse tangent of
+   the corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = atan(A)</literal> produces a
+   result equivalent to <literal>Z(i) = atan(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = atan(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>acos</function> 
+       <xref linkend="functionref_acos" role="template:(section %n)"/>
+   <function>asin</function> 
+       <xref linkend="functionref_asin" role="template:(section %n)"/>
+   <function>cos</function> 
+       <xref linkend="functionref_cos" role="template:(section %n)"/>
+   <function>sin</function> 
+       <xref linkend="functionref_sin" role="template:(section %n)"/>
+   <function>tan</function> 
+       <xref linkend="functionref_tan" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/cos.xml
===================================================================
--- doc/manual/cos.xml	(revision 218956)
+++ doc/manual/cos.xml	(working copy)
@@ -3,8 +3,7 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_cos">
- <title>
-  <function>cos</function>
+ <title><function>cos</function>
   <indexterm><primary><function>cos</function></primary></indexterm>
  </title>
 
Index: doc/manual/acos.xml
===================================================================
--- doc/manual/acos.xml	(revision 0)
+++ doc/manual/acos.xml	(revision 0)
@@ -0,0 +1,95 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_acos">
+ <title><function>acos</function>
+  <indexterm><primary><function>acos</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise arc cosine (inverse cosine).
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>acos</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>acos</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>acos</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to arc or inverse cosine of
+   the corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = acos(A)</literal> produces a
+   result equivalent to <literal>Z(i) = acos(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = acos(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>asin</function> 
+       <xref linkend="functionref_asin" role="template:(section %n)"/>
+   <function>atan</function> 
+       <xref linkend="functionref_atan" role="template:(section %n)"/>
+   <function>cos</function> 
+       <xref linkend="functionref_cos" role="template:(section %n)"/>
+   <function>sin</function> 
+       <xref linkend="functionref_sin" role="template:(section %n)"/>
+   <function>tan</function> 
+       <xref linkend="functionref_tan" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/add.xml
===================================================================
--- doc/manual/add.xml	(revision 218956)
+++ doc/manual/add.xml	(working copy)
@@ -3,7 +3,9 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_add">
- <title><function>add</function></title>
+ <title><function>add</function>
+  <indexterm><primary><function>add</function></primary></indexterm>
+ </title>
 
  <formalpara>
   <title>Description:</title>
Index: doc/manual/sin.xml
===================================================================
--- doc/manual/sin.xml	(revision 218956)
+++ doc/manual/sin.xml	(working copy)
@@ -3,8 +3,7 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_sin">
- <title>
-  <function>sin</function>
+ <title><function>sin</function>
   <indexterm><primary><function>sin</function></primary></indexterm>
  </title>
 
Index: doc/manual/sub.xml
===================================================================
--- doc/manual/sub.xml	(revision 218956)
+++ doc/manual/sub.xml	(working copy)
@@ -3,7 +3,9 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_sub">
- <title><function>sub</function></title>
+ <title><function>sub</function>
+  <indexterm><primary><function>sub</function></primary></indexterm>
+ </title>
 
  <formalpara>
   <title>Description:</title>
Index: doc/manual/sqrt.xml
===================================================================
--- doc/manual/sqrt.xml	(revision 218956)
+++ doc/manual/sqrt.xml	(working copy)
@@ -3,8 +3,7 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_sqrt">
- <title>
-  <function>sqrt</function>
+ <title><function>sqrt</function>
   <indexterm><primary><function>sqrt</function></primary></indexterm>
  </title>
 
Index: doc/manual/tanh.xml
===================================================================
--- doc/manual/tanh.xml	(revision 0)
+++ doc/manual/tanh.xml	(revision 0)
@@ -0,0 +1,89 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_tanh">
+ <title><function>tanh</function>
+  <indexterm><primary><function>tanh</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise hyperbolic tangent.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>tanh</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>tanh</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>tanh</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to hyperbolic tangent of the
+   corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = tanh(A)</literal> produces a
+   result equivalent to <literal>Z(i) = tanh(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = tanh(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>cosh</function> 
+       <xref linkend="functionref_cosh" role="template:(section %n)"/>
+   <function>sinh</function> 
+       <xref linkend="functionref_sinh" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/asin.xml
===================================================================
--- doc/manual/asin.xml	(revision 0)
+++ doc/manual/asin.xml	(revision 0)
@@ -0,0 +1,95 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_asin">
+ <title><function>asin</function>
+  <indexterm><primary><function>asin</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise arc sine (inverse sine).
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>asin</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>asin</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>asin</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to arc or inverse sine of
+   the corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = asin(A)</literal> produces a
+   result equivalent to <literal>Z(i) = asin(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = asin(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>acos</function> 
+       <xref linkend="functionref_acos" role="template:(section %n)"/>
+   <function>atan</function> 
+       <xref linkend="functionref_atan" role="template:(section %n)"/>
+   <function>cos</function> 
+       <xref linkend="functionref_cos" role="template:(section %n)"/>
+   <function>sin</function> 
+       <xref linkend="functionref_sin" role="template:(section %n)"/>
+   <function>tan</function> 
+       <xref linkend="functionref_tan" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/cosh.xml
===================================================================
--- doc/manual/cosh.xml	(revision 0)
+++ doc/manual/cosh.xml	(revision 0)
@@ -0,0 +1,89 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_cosh">
+ <title><function>cosh</function>
+  <indexterm><primary><function>cosh</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise hyperbolic cosine.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>cosh</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>cosh</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>cosh</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to hyperbolic cosine of the
+   corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = cosh(A)</literal> produces a
+   result equivalent to <literal>Z(i) = cosh(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = cosh(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>sinh</function> 
+       <xref linkend="functionref_sinh" role="template:(section %n)"/>
+   <function>tanh</function> 
+       <xref linkend="functionref_tanh" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/mul.xml
===================================================================
--- doc/manual/mul.xml	(revision 218956)
+++ doc/manual/mul.xml	(working copy)
@@ -3,7 +3,9 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_mul">
- <title><function>mul</function></title>
+ <title><function>mul</function>
+  <indexterm><primary><function>mul</function></primary></indexterm>
+ </title>
 
  <formalpara>
   <title>Description:</title>
Index: doc/manual/functions.xml
===================================================================
--- doc/manual/functions.xml	(revision 218956)
+++ doc/manual/functions.xml	(working copy)
@@ -28,21 +28,42 @@
 
  <section>
   <title>Elementwise Functions</title>
+  <xi:include href="acos.xml" />
   <xi:include href="add.xml" />
+  <xi:include href="arg.xml" />
+  <xi:include href="asin.xml" />
+  <xi:include href="atan.xml" />
+  <xi:include href="bnot.xml" />
+  <xi:include href="ceil.xml" />
+  <xi:include href="conj.xml" />
   <xi:include href="cos.xml" />
+  <xi:include href="cosh.xml" />
   <xi:include href="div.xml" />
+  <xi:include href="euler.xml" />
   <xi:include href="exp.xml" />
   <xi:include href="exp10.xml" />
+  <xi:include href="floor.xml" />
+  <xi:include href="imag.xml" />
+  <xi:include href="is_finite.xml" />
+  <xi:include href="is_nan.xml" />
+  <xi:include href="is_normal.xml" />
+  <xi:include href="lnot.xml" />
   <xi:include href="log.xml" />
   <xi:include href="log10.xml" />
   <xi:include href="mag.xml" />
   <xi:include href="magsq.xml" />
   <xi:include href="mul.xml" />
+  <xi:include href="neg.xml" />
+  <xi:include href="real.xml" />
+  <xi:include href="recip.xml" />
+  <xi:include href="rsqrt.xml" />
   <xi:include href="sin.xml" />
+  <xi:include href="sinh.xml" />
   <xi:include href="sq.xml" />
   <xi:include href="sqrt.xml" />
   <xi:include href="sub.xml" />
   <xi:include href="tan.xml" />
+  <xi:include href="tanh.xml" />
  </section>
 
  <section>
Index: doc/manual/arg.xml
===================================================================
--- doc/manual/arg.xml	(revision 0)
+++ doc/manual/arg.xml	(revision 0)
@@ -0,0 +1,90 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_arg">
+ <title><function>arg</function>
+  <indexterm><primary><function>arg</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise phase angle of complex.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>arg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;complex&lt;T&gt; &gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>arg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;complex&lt;T&gt; &gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>arg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;complex&lt;T&gt; &gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to the phase angle of the
+   corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = arg(A)</literal> produces a
+   result equivalent to <literal>Z(i) = atan2(imag(A(i)),
+   real(A(i)))</literal> for all the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;complex&lt;float&gt; &gt; A;
+Vector&lt;float&gt; Z;
+Z = arg(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>imag</function> 
+       <xref linkend="functionref_imag" role="template:(section %n)"/>
+   <function>real</function> 
+       <xref linkend="functionref_real" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/floor.xml
===================================================================
--- doc/manual/floor.xml	(revision 0)
+++ doc/manual/floor.xml	(revision 0)
@@ -0,0 +1,87 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_floor">
+ <title><function>floor</function>
+  <indexterm><primary><function>floor</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise floating-point floor.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>floor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>floor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>floor</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to the floating-point value
+   of the argument view rounded down to the next integral value.  For
+   instance, if the argument is a vector, <literal>Z =
+   floor(A)</literal> produces a result equivalent to <literal>Z(i) =
+   floor(A(i))</literal> for all the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = floor(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>ceil</function> 
+       <xref linkend="functionref_ceil" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/real.xml
===================================================================
--- doc/manual/real.xml	(revision 0)
+++ doc/manual/real.xml	(revision 0)
@@ -0,0 +1,90 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_real">
+ <title><function>real</function>
+  <indexterm><primary><function>real</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise real part of complex.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>real</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;complex&lt;T&gt; &gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>real</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;complex&lt;T&gt; &gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>real</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;complex&lt;T&gt; &gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to the real component of the
+   corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = real(A)</literal> produces a
+   result equivalent to <literal>Z(i) = real(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;complex&lt;float&gt; &gt; A;
+Vector&lt;float&gt; Z;
+Z = real(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>arg</function> 
+       <xref linkend="functionref_arg" role="template:(section %n)"/>
+   <function>imag</function> 
+       <xref linkend="functionref_imag" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/sq.xml
===================================================================
--- doc/manual/sq.xml	(revision 218956)
+++ doc/manual/sq.xml	(working copy)
@@ -3,8 +3,7 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_sq">
- <title>
-  <function>sq</function>
+ <title><function>sq</function>
   <indexterm><primary><function>sq</function></primary></indexterm>
  </title>
 
Index: doc/manual/operations.xml
===================================================================
--- doc/manual/operations.xml	(revision 218956)
+++ doc/manual/operations.xml	(working copy)
@@ -258,13 +258,15 @@
       <term><literal>acos(A)</literal></term>
       <listitem>
        Trigonometric arc cosine
+       <xref linkend="functionref_acos" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
      <varlistentry>
       <term><literal>arg(A)</literal></term>
       <listitem>
-       Polar representation angle of complex
+       Phase angle of complex
+       <xref linkend="functionref_arg" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -272,6 +274,7 @@
       <term><literal>asin(A)</literal></term>
       <listitem>
        Trigonometric arc sine
+       <xref linkend="functionref_asin" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -279,6 +282,7 @@
       <term><literal>atan(A)</literal></term>
       <listitem>
        Trigonometric arc tangent
+       <xref linkend="functionref_atan" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -286,6 +290,7 @@
       <term><literal>bnot(A)</literal></term>
       <listitem>
        Boolean not
+       <xref linkend="functionref_lnot" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -293,6 +298,7 @@
       <term><literal>ceil(A)</literal></term>
       <listitem>
        Round floating-point value up to next integral value
+       <xref linkend="functionref_ceil" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -300,6 +306,7 @@
       <term><literal>conj(A)</literal></term>
       <listitem>
        Complex conjugate
+       <xref linkend="functionref_conj" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -315,6 +322,7 @@
       <term><literal>cosh(A)</literal></term>
       <listitem>
        Hyperbolic cosine
+       <xref linkend="functionref_cosh" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -322,6 +330,7 @@
       <term><literal>euler(A)</literal></term>
       <listitem>
        Rotate complex unit vector by angle
+       <xref linkend="functionref_euler" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -345,6 +354,7 @@
       <term><literal>floor(A)</literal></term>
       <listitem>
        Round floating-point value down to next integral value
+       <xref linkend="functionref_floor" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -352,6 +362,7 @@
       <term><literal>imag(A)</literal></term>
       <listitem>
        Imaginary part of complex
+       <xref linkend="functionref_imag" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -359,6 +370,7 @@
       <term><literal>is_finite(A)</literal></term>
       <listitem>
        Is floating-point value finite
+       <xref linkend="functionref_is_nan" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -366,6 +378,7 @@
       <term><literal>is_nan(A)</literal></term>
       <listitem>
        Is floating-point value not a number (NaN)
+       <xref linkend="functionref_is_nan" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -373,6 +386,7 @@
       <term><literal>is_normal(A)</literal></term>
       <listitem>
        Is floating-point value normal
+       <xref linkend="functionref_is_normal" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -380,6 +394,7 @@
       <term><literal>lnot(A)</literal></term>
       <listitem>
        Logical not
+       <xref linkend="functionref_lnot" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -419,6 +434,7 @@
       <term><literal>neg(A)</literal></term>
       <listitem>
        Negation
+       <xref linkend="functionref_neg" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -426,6 +442,7 @@
       <term><literal>real(A)</literal></term>
       <listitem>
        Real part of complex
+       <xref linkend="functionref_real" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -433,6 +450,7 @@
       <term><literal>recip(A)</literal></term>
       <listitem>
        Recipricol
+       <xref linkend="functionref_recip" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -440,6 +458,7 @@
       <term><literal>rsqrt(A)</literal></term>
       <listitem>
        Recipricol square root
+       <xref linkend="functionref_rsqrt" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -455,6 +474,7 @@
       <term><literal>sinh(A)</literal></term>
       <listitem>
        Hyperbolic sine
+       <xref linkend="functionref_sinh" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
@@ -486,6 +506,7 @@
       <term><literal>tanh(A)</literal></term>
       <listitem>
        Hyperbolic tangent
+       <xref linkend="functionref_tanh" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
 
Index: doc/manual/is_normal.xml
===================================================================
--- doc/manual/is_normal.xml	(revision 0)
+++ doc/manual/is_normal.xml	(revision 0)
@@ -0,0 +1,95 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_is_normal">
+ <title><function>is_normal</function>
+  <indexterm><primary><function>is_normal</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise check for floating-point normal value.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>is_normal</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>is_normal</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>is_normal</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to true of the corresponding
+   element of the argument is a normal floating-point value, false
+   otherwise.  For instance, if the argument is a vector, <literal>Z =
+   is_normal(A)</literal> produces a result equivalent to
+   <literal>Z(i) = is_normal(A(i))</literal> for all the elements of
+   the vector.
+  </para>
+  <para>
+   For arguments with complex value type, output is conjunction of
+   is_normal for real and imaginary components.  <literal>Z(i) =
+   is_normal(real(A(i))) &amp;&amp; is_normal(imag(A(i)))</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = is_normal(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>is_finite</function> 
+       <xref linkend="functionref_is_finite" role="template:(section %n)"/>
+   <function>is_nan</function> 
+       <xref linkend="functionref_is_nan" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/conj.xml
===================================================================
--- doc/manual/conj.xml	(revision 0)
+++ doc/manual/conj.xml	(revision 0)
@@ -0,0 +1,89 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_conj">
+ <title><function>conj</function>
+  <indexterm><primary><function>conj</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise complex conjugate.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>conj</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>conj</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>conj</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to the complex conjugate of
+   the corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = conj(A)</literal> produces a
+   result equivalent to <literal>Z(i) = conj(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = conj(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>real</function> 
+       <xref linkend="functionref_real" role="template:(section %n)"/>
+   <function>imag</function> 
+       <xref linkend="functionref_imag" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/exp.xml
===================================================================
--- doc/manual/exp.xml	(revision 218956)
+++ doc/manual/exp.xml	(working copy)
@@ -3,8 +3,7 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_exp">
- <title>
-  <function>exp</function>
+ <title><function>exp</function>
   <indexterm><primary><function>exp</function></primary></indexterm>
  </title>
 
Index: doc/manual/exp10.xml
===================================================================
--- doc/manual/exp10.xml	(revision 218956)
+++ doc/manual/exp10.xml	(working copy)
@@ -3,8 +3,7 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_exp10">
- <title>
-  <function>exp10</function>
+ <title><function>exp10</function>
   <indexterm><primary><function>exp10</function></primary></indexterm>
  </title>
 
Index: doc/manual/sinh.xml
===================================================================
--- doc/manual/sinh.xml	(revision 0)
+++ doc/manual/sinh.xml	(revision 0)
@@ -0,0 +1,89 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_sinh">
+ <title><function>sinh</function>
+  <indexterm><primary><function>sinh</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise hyberbolic sine.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>sinh</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>sinh</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>sinh</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to hyberbolic sine of the
+   corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = sinh(A)</literal> produces a
+   result equivalent to <literal>Z(i) = sinh(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = sinh(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>cosh</function> 
+       <xref linkend="functionref_cosh" role="template:(section %n)"/>
+   <function>tanh</function> 
+       <xref linkend="functionref_tanh" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/recip.xml
===================================================================
--- doc/manual/recip.xml	(revision 0)
+++ doc/manual/recip.xml	(revision 0)
@@ -0,0 +1,95 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_recip">
+ <title><function>recip</function>
+  <indexterm><primary><function>recip</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise recipricol.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>recip</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>recip</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>recip</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
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
+   Each element of the result view is set to the recipricol square
+   root of the corresponding element of the argument.  For instance,
+   if the argument is a vector, <literal>Z = recip(A)</literal>
+   produces a result equivalent to <literal>Z(i) = 1 /
+   A(i)</literal> for all the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = recip(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>rsqrt</function> 
+       <xref linkend="functionref_rsqrt" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/bnot.xml
===================================================================
--- doc/manual/bnot.xml	(revision 0)
+++ doc/manual/bnot.xml	(revision 0)
@@ -0,0 +1,93 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_bnot">
+ <title><function>bnot</function>
+  <indexterm><primary><function>bnot</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise bitwise negation.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>bnot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>bnot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>bnot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to bitwise negation of the
+   corresponding element of the argument.  For instance, if the
+   argument is a vector of int, <literal>Z = bnot(A)</literal>
+   produces a result equivalent to <literal>Z(i) = ~A(i)</literal> for
+   all the elements of the vector.
+  </para>
+  <para>
+   Valid only on value types supporting bitwise negation (bool, char,
+   int, and so on).
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;bool&gt; Z, A;
+Z = neg(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>lnot</function> 
+       <xref linkend="functionref_lnot" role="template:(section %n)"/>
+   <function>neg</function> 
+       <xref linkend="functionref_neg" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/mag.xml
===================================================================
--- doc/manual/mag.xml	(revision 218956)
+++ doc/manual/mag.xml	(working copy)
@@ -3,8 +3,7 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_mag">
- <title>
-  <function>mag</function>
+ <title><function>mag</function>
   <indexterm><primary><function>mag</function></primary></indexterm>
  </title>
 
Index: doc/manual/is_nan.xml
===================================================================
--- doc/manual/is_nan.xml	(revision 0)
+++ doc/manual/is_nan.xml	(revision 0)
@@ -0,0 +1,94 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_is_nan">
+ <title><function>is_nan</function>
+  <indexterm><primary><function>is_nan</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise check for floating-point NaN (not a number).
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>is_nan</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>is_nan</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>is_nan</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to true of the corresponding
+   element of the argument is a NaN (not a number), false otherwise.
+   For instance, if the argument is a vector, <literal>Z =
+   is_nan(A)</literal> produces a result equivalent to <literal>Z(i) =
+   is_nan(A(i))</literal> for all the elements of the vector.
+  </para>
+  <para>
+   For arguments with complex value type, output is conjunction of
+   is_nan for real and imaginary components.  <literal>Z(i) =
+   is_nan(real(A(i))) &amp;&amp; is_nan(imag(A(i)))</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = is_nan(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>is_finite</function> 
+       <xref linkend="functionref_is_finite" role="template:(section %n)"/>
+   <function>is_normal</function> 
+       <xref linkend="functionref_is_normal" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/magsq.xml
===================================================================
--- doc/manual/magsq.xml	(revision 218956)
+++ doc/manual/magsq.xml	(working copy)
@@ -3,8 +3,7 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_magsq">
- <title>
-  <function>magsq</function>
+ <title><function>magsq</function>
   <indexterm><primary><function>magsq</function></primary></indexterm>
  </title>
 
Index: doc/manual/is_finite.xml
===================================================================
--- doc/manual/is_finite.xml	(revision 0)
+++ doc/manual/is_finite.xml	(revision 0)
@@ -0,0 +1,95 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_is_finite">
+ <title><function>is_finite</function>
+  <indexterm><primary><function>is_finite</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise check for finite floating-point value.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;bool&gt;</type> <function>is_finite</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;bool&gt;</type> <function>is_finite</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;bool&gt;</type> <function>is_finite</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to true of the corresponding
+   element of the argument is a finite floating-point value, false
+   otherwise.  For instance, if the argument is a vector, <literal>Z =
+   is_finite(A)</literal> produces a result equivalent to
+   <literal>Z(i) = is_finite(A(i))</literal> for all the elements of
+   the vector.
+  </para>
+  <para>
+   For arguments with complex value type, output is conjunction of
+   is_finite for real and imaginary components.  <literal>Z(i) =
+   is_finite(real(A(i))) &amp;&amp; is_finite(imag(A(i)))</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = is_finite(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>is_nan</function> 
+       <xref linkend="functionref_is_nan" role="template:(section %n)"/>
+   <function>is_normal</function> 
+       <xref linkend="functionref_is_normal" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/neg.xml
===================================================================
--- doc/manual/neg.xml	(revision 0)
+++ doc/manual/neg.xml	(revision 0)
@@ -0,0 +1,89 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_neg">
+ <title><function>neg</function>
+  <indexterm><primary><function>neg</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise arithmetic negation.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>neg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>neg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>neg</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to arithmetic negation of the
+   corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = neg(A)</literal> produces a
+   result equivalent to <literal>Z(i) = -A(i)</literal> for all the
+   elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = neg(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>bnot</function> 
+       <xref linkend="functionref_bnot" role="template:(section %n)"/>
+   <function>lnot</function> 
+       <xref linkend="functionref_lnot" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/rsqrt.xml
===================================================================
--- doc/manual/rsqrt.xml	(revision 0)
+++ doc/manual/rsqrt.xml	(revision 0)
@@ -0,0 +1,95 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_rsqrt">
+ <title><function>rsqrt</function>
+  <indexterm><primary><function>rsqrt</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise recipricol square root.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>rsqrt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>rsqrt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>rsqrt</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
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
+   Each element of the result view is set to the recipricol square
+   root of the corresponding element of the argument.  For instance,
+   if the argument is a vector, <literal>Z = rsqrt(A)</literal>
+   produces a result equivalent to <literal>Z(i) = 1 /
+   sqrt(A(i))</literal> for all the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = rsqrt(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>sqrt</function> 
+       <xref linkend="functionref_sqrt" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/ceil.xml
===================================================================
--- doc/manual/ceil.xml	(revision 0)
+++ doc/manual/ceil.xml	(revision 0)
@@ -0,0 +1,87 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_ceil">
+ <title><function>ceil</function>
+  <indexterm><primary><function>ceil</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise floating-point ceiling.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>ceil</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>ceil</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>ceil</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to the floating-point value
+   of the argument view rounded up to the next integral value.  For
+   instance, if the argument is a vector, <literal>Z =
+   ceil(A)</literal> produces a result equivalent to <literal>Z(i) =
+   ceil(A(i))</literal> for all the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = ceil(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>floor</function> 
+       <xref linkend="functionref_floor" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/lnot.xml
===================================================================
--- doc/manual/lnot.xml	(revision 0)
+++ doc/manual/lnot.xml	(revision 0)
@@ -0,0 +1,93 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_lnot">
+ <title><function>lnot</function>
+  <indexterm><primary><function>lnot</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise logical negation.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>lnot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;T&gt;</type> <function>lnot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;T&gt;</type> <function>lnot</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to logical negation of the
+   corresponding element of the argument.  For instance, if the
+   argument is a vector of bool, <literal>Z = neg(A)</literal>
+   produces a result equivalent to <literal>Z(i) = !A(i)</literal> for
+   all the elements of the vector.
+  </para>
+  <para>
+   Valid only on value types supporting logical negation (bool, char,
+   int, and so on).
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;bool&gt; Z, A;
+Z = neg(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>bnot</function> 
+       <xref linkend="functionref_bnot" role="template:(section %n)"/>
+   <function>neg</function> 
+       <xref linkend="functionref_neg" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/euler.xml
===================================================================
--- doc/manual/euler.xml	(revision 0)
+++ doc/manual/euler.xml	(revision 0)
@@ -0,0 +1,88 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_euler">
+ <title><function>euler</function>
+  <indexterm><primary><function>euler</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise euler function.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;complex&lt;T&gt; &gt;</type> <function>euler</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Matrix&lt;complex&lt;T&gt; &gt;</type> <function>euler</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Tensor&lt;complex&lt;T&gt; &gt;</type> <function>euler</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is a complex unit vector rotated by
+   the angle given in the corresponding element of the argument.  For
+   instance, if the argument is a vector, <literal>Z =
+   euler(A)</literal> produces a result equivalent to <literal>Z(i) =
+   polar(1, A(i))</literal> for all the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; A;
+Vector&lt;complex&lt;float&gt; &gt; Z, A;
+Z = euler(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>arg</function> 
+       <xref linkend="functionref_arg" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/imag.xml
===================================================================
--- doc/manual/imag.xml	(revision 0)
+++ doc/manual/imag.xml	(revision 0)
@@ -0,0 +1,90 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_imag">
+ <title><function>imag</function>
+  <indexterm><primary><function>imag</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise imaginary part of complex.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>imag</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Vector&lt;complex&lt;T&gt; &gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>imag</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Matrix&lt;complex&lt;T&gt; &gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>imag</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;complex&lt;T&gt; &gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+ </formalpara>
+
+ <formalpara>
+  <title>Result:</title>
+  <para>
+   Each element of the result view is set to the imaginary component
+   of the corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = imag(A)</literal> produces a
+   result equivalent to <literal>Z(i) = imag(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;complex&lt;float&gt; &gt; A;
+Vector&lt;float&gt; Z;
+Z = imag(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>arg</function> 
+       <xref linkend="functionref_arg" role="template:(section %n)"/>
+   <function>real</function> 
+       <xref linkend="functionref_real" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
