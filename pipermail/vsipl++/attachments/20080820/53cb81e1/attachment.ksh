Index: ChangeLog
===================================================================
--- ChangeLog	(revision 217997)
+++ ChangeLog	(working copy)
@@ -1,5 +1,22 @@
 2008-08-19  Jules Bergmann  <jules@codesourcery.com>
 
+	* doc/manual/operations.xml: Expand list of unary elementwise
+	  fuctions.  Link to added man pages.
+	* doc/manual/functions.xml: Include new manage pages.
+	* doc/manual/log.xml: New file, log man page.
+	* doc/manual/log10.xml: New file, log man page.
+	* doc/manual/tan.xml: New file, log man page.
+	* doc/manual/sq.xml: New file, log man page.
+	* doc/manual/cos.xml: New file, log man page.
+	* doc/manual/sin.xml: New file, log man page.
+	* doc/manual/sqrt.xml: New file, log man page.
+	* doc/manual/exp.xml: New file, log man page.
+	* doc/manual/exp10.xml: New file, log man page.
+	* doc/manual/mag.xml: New file, log man page.
+	* doc/manual/magsq.xml: New file, log man page.
+
+2008-08-19  Jules Bergmann  <jules@codesourcery.com>
+
 	* tests/correlation.cpp: Adjust threshold on Cell.
 
 2008-08-19  Jules Bergmann  <jules@codesourcery.com>
Index: doc/manual/log.xml
===================================================================
--- doc/manual/log.xml	(revision 0)
+++ doc/manual/log.xml	(revision 0)
@@ -0,0 +1,100 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_log">
+ <title>
+  <function>log</function>
+  <indexterm><primary><function>log</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise natural logarithm.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>log</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>log</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>log</function>
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
+   Each element of the result view is set to natural logarithm of the
+   corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = log(A)</literal> produces a
+   result equivalent to <literal>Z(i) = log(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = log(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>exp</function> 
+       <xref linkend="functionref_exp" role="template:(section %n)"/>
+   <function>exp10</function> 
+       <xref linkend="functionref_exp10" role="template:(section %n)"/>
+   <function>log10</function> 
+       <xref linkend="functionref_log10" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/log10.xml
===================================================================
--- doc/manual/log10.xml	(revision 0)
+++ doc/manual/log10.xml	(revision 0)
@@ -0,0 +1,92 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_log10">
+ <title>
+  <function>log10</function>
+  <indexterm><primary><function>log10</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise base-10 logarithm.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>log10</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>log10</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>log10</function>
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
+   Each element of the result view is set to base-10 logarithm of the
+   corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = log10(A)</literal> produces a
+   result equivalent to <literal>Z(i) = log10(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = log10(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>exp</function> 
+       <xref linkend="functionref_exp" role="template:(section %n)"/>
+   <function>exp10</function> 
+       <xref linkend="functionref_exp10" role="template:(section %n)"/>
+   <function>log</function> 
+       <xref linkend="functionref_log" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/tan.xml
===================================================================
--- doc/manual/tan.xml	(revision 0)
+++ doc/manual/tan.xml	(revision 0)
@@ -0,0 +1,90 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_tan">
+ <title>
+  <function>tan</function>
+  <indexterm><primary><function>tan</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise trigonometric tangent.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>tan</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>tan</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>tan</function>
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
+   Each element of the result view is set to tangent of the corresponding
+   element of the argument.  For instance, if the argument is a vector,
+   <literal>Z = tan(A)</literal> produces a result equivalent to
+   <literal>Z(i) = tan(A(i))</literal> for all the elements of the
+   vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = tan(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>cos</function> 
+       <xref linkend="functionref_cos" role="template:(section %n)"/>
+   <function>sin</function> 
+       <xref linkend="functionref_sin" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/sq.xml
===================================================================
--- doc/manual/sq.xml	(revision 0)
+++ doc/manual/sq.xml	(revision 0)
@@ -0,0 +1,96 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_sq">
+ <title>
+  <function>sq</function>
+  <indexterm><primary><function>sq</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise square.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>sq</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>sq</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>sq</function>
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
+   Each element of the result view is set to the square of the
+   corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = sq(A)</literal> produces a
+   result equivalent to <literal>Z(i) = A(i) * A(i)</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = sq(A);</screen>
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
Index: doc/manual/operations.xml
===================================================================
--- doc/manual/operations.xml	(revision 217943)
+++ doc/manual/operations.xml	(working copy)
@@ -253,52 +253,216 @@
     vectors, producing a vector result:
 
     <variablelist>
+
      <varlistentry>
-      <term><literal>abs(A)</literal></term>
+      <term><literal>acos(A)</literal></term>
       <listitem>
-       Absolute value
+       Trigonometric arc cosine
       </listitem>
      </varlistentry>
-      
+
      <varlistentry>
+      <term><literal>arg(A)</literal></term>
+      <listitem>
+       Polar representation angle of complex
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>asin(A)</literal></term>
+      <listitem>
+       Trigonometric arc sine
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>atan(A)</literal></term>
+      <listitem>
+       Trigonometric arc tangent
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>bnot(A)</literal></term>
+      <listitem>
+       Boolean not
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>ceil(A)</literal></term>
+      <listitem>
+       Round floating-point value up to next integral value
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>conj(A)</literal></term>
+      <listitem>
+       Complex conjugate
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><literal>cos(A)</literal></term>
       <listitem>
        Trigonometric cosine
+       <xref linkend="functionref_cos" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
      
      <varlistentry>
+      <term><literal>cosh(A)</literal></term>
+      <listitem>
+       Hyperbolic cosine
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>euler(A)</literal></term>
+      <listitem>
+       Rotate complex unit vector by angle
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><literal>exp(A)</literal></term>
       <listitem>
        Natural exponential
+       <xref linkend="functionref_exp" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
+
+     <varlistentry>
+      <term><literal>exp10(A)</literal></term>
+      <listitem>
+       Base-10 exponential
+       <xref linkend="functionref_exp10" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
       
      <varlistentry>
+      <term><literal>floor(A)</literal></term>
+      <listitem>
+       Round floating-point value down to next integral value
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>imag(A)</literal></term>
+      <listitem>
+       Imaginary part of complex
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>is_finite(A)</literal></term>
+      <listitem>
+       Is floating-point value finite
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>is_nan(A)</literal></term>
+      <listitem>
+       Is floating-point value not a number (NaN)
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>is_normal(A)</literal></term>
+      <listitem>
+       Is floating-point value normal
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>lnot(A)</literal></term>
+      <listitem>
+       Logical not
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><literal>log(A)</literal></term>
       <listitem>
-       Base-10 logarithm
+       Base-e logarithm
+       <xref linkend="functionref_log" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
       
      <varlistentry>
-      <term><literal>ln(A)</literal></term>
+      <term><literal>log10(A)</literal></term>
       <listitem>
-       Base-e logarithm
+       Base-10 logarithm
+       <xref linkend="functionref_log10" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
+
+     <varlistentry>
+      <term><literal>mag(A)</literal></term>
+      <listitem>
+       Magnitude
+       <xref linkend="functionref_mag" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>magsq(A)</literal></term>
+      <listitem>
+       Magnitude squared
+       <xref linkend="functionref_magsq" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
       
      <varlistentry>
+      <term><literal>neg(A)</literal></term>
+      <listitem>
+       Negation
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>real(A)</literal></term>
+      <listitem>
+       Real part of complex
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>recip(A)</literal></term>
+      <listitem>
+       Recipricol
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>rsqrt(A)</literal></term>
+      <listitem>
+       Recipricol square root
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><literal>sin(A)</literal></term>
       <listitem>
        Trigonometric sine
+       <xref linkend="functionref_sin" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
       
      <varlistentry>
+      <term><literal>sinh(A)</literal></term>
+      <listitem>
+       Hyperbolic sine
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><literal>sq(A)</literal></term>
       <listitem>
        Square
+       <xref linkend="functionref_sq" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
       
@@ -306,8 +470,25 @@
       <term><literal>sqrt(A)</literal></term>
       <listitem>
        Square root
+       <xref linkend="functionref_sqrt" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
+
+     <varlistentry>
+      <term><literal>tan(A)</literal></term>
+      <listitem>
+       Trigonometric tangent
+       <xref linkend="functionref_tan" role="template:(section %n)"/>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><literal>tanh(A)</literal></term>
+      <listitem>
+       Hyperbolic tangent
+      </listitem>
+     </varlistentry>
+
     </variablelist>
    </para>
   </section>
Index: doc/manual/cos.xml
===================================================================
--- doc/manual/cos.xml	(revision 0)
+++ doc/manual/cos.xml	(revision 0)
@@ -0,0 +1,90 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_cos">
+ <title>
+  <function>cos</function>
+  <indexterm><primary><function>cos</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise trigonometric cosine.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>cos</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>cos</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>cos</function>
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
+   Each element of the result view is set to cosine of the corresponding
+   element of the argument.  For instance, if the argument is a vector,
+   <literal>Z = cos(A)</literal> produces a result equivalent to
+   <literal>Z(i) = cos(A(i))</literal> for all the elements of the
+   vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = cos(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>sin</function> 
+       <xref linkend="functionref_sin" role="template:(section %n)"/>
+   <function>tan</function> 
+       <xref linkend="functionref_tan" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/sin.xml
===================================================================
--- doc/manual/sin.xml	(revision 0)
+++ doc/manual/sin.xml	(revision 0)
@@ -0,0 +1,90 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_sin">
+ <title>
+  <function>sin</function>
+  <indexterm><primary><function>sin</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise trigonometric sine.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>sin</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>sin</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>sin</function>
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
+   Each element of the result view is set to sine of the corresponding
+   element of the argument.  For instance, if the argument is a vector,
+   <literal>Z = sin(A)</literal> produces a result equivalent to
+   <literal>Z(i) = sin(A(i))</literal> for all the elements of the
+   vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = sin(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>cos</function> 
+       <xref linkend="functionref_cos" role="template:(section %n)"/>
+   <function>tan</function> 
+       <xref linkend="functionref_tan" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/sqrt.xml
===================================================================
--- doc/manual/sqrt.xml	(revision 0)
+++ doc/manual/sqrt.xml	(revision 0)
@@ -0,0 +1,96 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_sqrt">
+ <title>
+  <function>sqrt</function>
+  <indexterm><primary><function>sqrt</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise square root.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>sqrt</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>sqrt</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>sqrt</function>
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
+   Each element of the result view is set to the square root of the
+   corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = sqrt(A)</literal> produces a
+   result equivalent to <literal>Z(i) = sqrt(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = sqrt(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>sq</function> 
+       <xref linkend="functionref_sq" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/exp.xml
===================================================================
--- doc/manual/exp.xml	(revision 0)
+++ doc/manual/exp.xml	(revision 0)
@@ -0,0 +1,92 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_exp">
+ <title>
+  <function>exp</function>
+  <indexterm><primary><function>exp</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise natural exponential.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>exp</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>exp</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>exp</function>
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
+   Each element of the result view is set to natural exponential of
+   the corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = exp(A)</literal> produces a
+   result equivalent to <literal>Z(i) = exp(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = exp(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>exp10</function> 
+       <xref linkend="functionref_exp10" role="template:(section %n)"/>
+   <function>log</function> 
+       <xref linkend="functionref_log" role="template:(section %n)"/>
+   <function>log10</function> 
+       <xref linkend="functionref_log10" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/exp10.xml
===================================================================
--- doc/manual/exp10.xml	(revision 0)
+++ doc/manual/exp10.xml	(revision 0)
@@ -0,0 +1,92 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_exp10">
+ <title>
+  <function>exp10</function>
+  <indexterm><primary><function>exp10</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise base-10 exponential.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>exp10</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>exp10</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>exp10</function>
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
+   Each element of the result view is set to base-10 exponential of
+   the corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = exp10(A)</literal> produces a
+   result equivalent to <literal>Z(i) = exp10(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = exp10(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>exp</function> 
+       <xref linkend="functionref_exp" role="template:(section %n)"/>
+   <function>log</function> 
+       <xref linkend="functionref_log" role="template:(section %n)"/>
+   <function>log10</function> 
+       <xref linkend="functionref_log10" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/mag.xml
===================================================================
--- doc/manual/mag.xml	(revision 0)
+++ doc/manual/mag.xml	(revision 0)
@@ -0,0 +1,134 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_mag">
+ <title>
+  <function>mag</function>
+  <indexterm><primary><function>mag</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise magnitude.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>mag</function>
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
+     <type>Vector&lt;T&gt;</type> <function>mag</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>mag</function>
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
+     <type>Vector&lt;T&gt;</type> <function>mag</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>mag</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>mag</function>
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
+   Each element of the result view is set to the magnitude
+   (equivalently the absolute value) of the corresponding element of
+   the argument.  For instance, if the argument is a vector,
+   <literal>Z = mag(A)</literal> produces a result equivalent to
+   <literal>Z(i) = mag(A(i))</literal> for all the elements of the
+   vector.
+  </para>
+  <para>
+   If argument is a view of scalars, return type is a view of scalars.
+  </para>
+  <para>
+   If argument is a view of complex, return type is a view of scalars.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = mag(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>magsq</function> 
+       <xref linkend="functionref_magsq" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/functions.xml
===================================================================
--- doc/manual/functions.xml	(revision 217943)
+++ doc/manual/functions.xml	(working copy)
@@ -29,9 +29,20 @@
  <section>
   <title>Elementwise Functions</title>
   <xi:include href="add.xml" />
+  <xi:include href="cos.xml" />
   <xi:include href="div.xml" />
+  <xi:include href="exp.xml" />
+  <xi:include href="exp10.xml" />
+  <xi:include href="log.xml" />
+  <xi:include href="log10.xml" />
+  <xi:include href="mag.xml" />
+  <xi:include href="magsq.xml" />
   <xi:include href="mul.xml" />
+  <xi:include href="sin.xml" />
+  <xi:include href="sq.xml" />
+  <xi:include href="sqrt.xml" />
   <xi:include href="sub.xml" />
+  <xi:include href="tan.xml" />
  </section>
 
  <section>
Index: doc/manual/magsq.xml
===================================================================
--- doc/manual/magsq.xml	(revision 0)
+++ doc/manual/magsq.xml	(revision 0)
@@ -0,0 +1,133 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_magsq">
+ <title>
+  <function>magsq</function>
+  <indexterm><primary><function>magsq</function></primary></indexterm>
+ </title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise magnitude squared.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>magsq</function>
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
+     <type>Vector&lt;T&gt;</type> <function>magsq</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>magsq</function>
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
+     <type>Vector&lt;T&gt;</type> <function>magsq</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>magsq</function>
+    </funcdef>
+    <paramdef>
+     <parameter>
+      <type>Tensor&lt;T&gt;</type> <function>A</function>
+     </parameter>
+    </paramdef>
+   </funcprototype>
+  </funcsynopsis>
+
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>magsq</function>
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
+   Each element of the result view is set to the magnitude squared of
+   the corresponding element of the argument.  For instance, if the
+   argument is a vector, <literal>Z = magsq(A)</literal> produces a
+   result equivalent to <literal>Z(i) = magsq(A(i))</literal> for all
+   the elements of the vector.
+  </para>
+  <para>
+   For views of scalars, return type is a view of scalars.
+  </para>
+  <para>
+   For views of complex, return type is a view of scalars.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A;
+Z = magsq(A);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>mag</function> 
+       <xref linkend="functionref_mag" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
