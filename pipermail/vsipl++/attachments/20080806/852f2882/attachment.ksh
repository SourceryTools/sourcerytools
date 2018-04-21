Index: doc/manual/div.xml
===================================================================
--- doc/manual/div.xml	(revision 0)
+++ doc/manual/div.xml	(revision 0)
@@ -0,0 +1,213 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_div">
+ <title><literal>div</literal></title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise division.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>div</function>
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
+     <type>Vector&lt;T&gt;</type> <function>div</function>
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
+     <type>Vector&lt;T&gt;</type> <function>div</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>div</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>div</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>div</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>div</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>div</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>div</function>
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
+   Division can also be written in operator form.  <literal>div(A,
+   B)</literal> is equivalent to <literal>A / B</literal>.
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
+   Each element of the result value is equal to the fraction of the
+   corresponding elements of the two arguments.  For instance, if the
+   arguments are vectors, <literal>Z = div(A, B)</literal> produces a
+   result equivalent to <literal>Z(i) = A(i) / B(i)</literal> for all
+   of the elements of the vector.  If either of the arguments is a
+   scalar, it either divides or is divided by all of the elements of
+   the other argument; for example, <literal>Z = div(A, b)</literal>
+   produces <literal>Z(i) = A(i) / b</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = div(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>add</function> 
+       <xref linkend="functionref_add" role="template:(section %n)"/>
+   <function>mul</function> 
+       <xref linkend="functionref_mul" role="template:(section %n)"/>
+   <function>sub</function>
+       <xref linkend="functionref_sub" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/operations.xml
===================================================================
--- doc/manual/operations.xml	(revision 216979)
+++ doc/manual/operations.xml	(working copy)
@@ -348,6 +348,7 @@
       <term><literal>Z = div(A, B)</literal></term>
       <listitem>
        Division, <literal>Z(n) = A(n) / B(n)</literal>
+       <xref linkend="functionref_div" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
       
@@ -369,6 +370,7 @@
       <term><literal>Z = mul(A, B)</literal></term>
       <listitem>
        Multiplication, <literal>Z(n) = A(n) * B(n)</literal>
+       <xref linkend="functionref_mul" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
       
@@ -376,6 +378,7 @@
       <term><literal>Z = sub(A, B)</literal></term>
       <listitem>
        Subtraction, <literal>Z(n) = A(n) - B(n)</literal>
+       <xref linkend="functionref_sub" role="template:(section %n)"/>
       </listitem>
      </varlistentry>
     </variablelist>
Index: doc/manual/add.xml
===================================================================
--- doc/manual/add.xml	(revision 216979)
+++ doc/manual/add.xml	(working copy)
@@ -3,13 +3,12 @@
                        "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
 
 <section id="functionref_add">
- <title><literal>add(A, B)</literal></title>
+ <title><literal>add</literal></title>
 
  <formalpara>
   <title>Description:</title>
   <para>
-   Elementwise addition of the elements of <literal>A</literal> and
-   <literal>B</literal>.
+   Elementwise addition.
   </para>
  </formalpara>
 
@@ -162,6 +161,14 @@
  </formalpara>
 
  <formalpara>
+  <title>Operator Syntax:</title>
+  <para>
+   Addition can also be written in operator form.  <literal>add(A,
+   B)</literal> is equivalent to <literal>A + B</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
   <title>Requirements:</title>
   <para>
    If both arguments are non-scalar, they must be the same size in each
@@ -194,7 +201,12 @@
  <formalpara>
   <title>See Also:</title>
   <para>
-   <function>sub</function> (section 2.1.X)
+   <function>div</function> 
+       <xref linkend="functionref_div" role="template:(section %n)"/>
+   <function>mul</function> 
+       <xref linkend="functionref_mul" role="template:(section %n)"/>
+   <function>sub</function> 
+       <xref linkend="functionref_sub" role="template:(section %n)"/>
   </para>
  </formalpara>
 
Index: doc/manual/functions.xml
===================================================================
--- doc/manual/functions.xml	(revision 216979)
+++ doc/manual/functions.xml	(working copy)
@@ -27,13 +27,19 @@
  </section>
 
  <section>
-  <title>FIXME Man pages</title>
-  
+  <title>Elementwise Functions</title>
   <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="add.xml" />
+  <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="div.xml" />
+  <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="mul.xml" />
+  <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="sub.xml" />
+ </section>
+
+ <section>
+  <title>Signal Processing Functions</title>
   <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="blackman.xml" />
   <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="cheby.xml" />
   <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="hanning.xml" />
   <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="kaiser.xml" />
+ </section>
 
- </section>
 </chapter>
Index: doc/manual/sub.xml
===================================================================
--- doc/manual/sub.xml	(revision 0)
+++ doc/manual/sub.xml	(revision 0)
@@ -0,0 +1,213 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_sub">
+ <title><literal>sub</literal></title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise subtraction.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>sub</function>
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
+     <type>Vector&lt;T&gt;</type> <function>sub</function>
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
+     <type>Vector&lt;T&gt;</type> <function>sub</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>sub</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>sub</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>sub</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>sub</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>sub</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>sub</function>
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
+   Subtraction can also be written in operator form.  <literal>sub(A,
+   B)</literal> is equivalent to <literal>A - B</literal>.
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
+   Each element of the result value is equal to the difference of the
+   corresponding elements of the two arguments.  For instance, if the
+   arguments are vectors, <literal>Z = sub(A, B)</literal> produces a
+   result equivalent to <literal>Z(i) = A(i) - B(i)</literal> for all
+   of the elements of the vector.  If either of the arguments is a
+   scalar, it's difference with all of the elements of the other
+   argument is computed; for example, <literal>Z = sub(A, b)</literal>
+   produces <literal>Z(i) = A(i) - b</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = sub(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>add</function> 
+       <xref linkend="functionref_add" role="template:(section %n)"/>
+   <function>div</function> 
+       <xref linkend="functionref_div" role="template:(section %n)"/>
+   <function>mul</function> 
+       <xref linkend="functionref_mul" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
Index: doc/manual/mul.xml
===================================================================
--- doc/manual/mul.xml	(revision 0)
+++ doc/manual/mul.xml	(revision 0)
@@ -0,0 +1,214 @@
+<?xml version="1.0"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+
+<section id="functionref_mul">
+ <title><literal>mul</literal></title>
+
+ <formalpara>
+  <title>Description:</title>
+  <para>
+   Elementwise multiplication.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Syntax:</title>
+  <funcsynopsis>
+   <funcprototype>
+    <funcdef>
+     <type>Vector&lt;T&gt;</type> <function>mul</function>
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
+     <type>Vector&lt;T&gt;</type> <function>mul</function>
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
+     <type>Vector&lt;T&gt;</type> <function>mul</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>mul</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>mul</function>
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
+     <type>Matrix&lt;T&gt;</type> <function>mul</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>mul</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>mul</function>
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
+     <type>Tensor&lt;T&gt;</type> <function>mul</function>
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
+   Multiplication can also be written in operator form.
+   <literal>mul(A, B)</literal> is equivalent to <literal>A *
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
+   Each element of the result value is equal to the product of the
+   corresponding elements of the two arguments.  For instance, if the
+   arguments are vectors, <literal>Z = mul(A, B)</literal> produces a
+   result equivalent to <literal>Z(i) = A(i) * B(i)</literal> for all
+   of the elements of the vector.  If either of the arguments is a
+   scalar, it is scales all of the elements of the other argument;
+   for example, <literal>Z = mul(A, b)</literal> produces
+   <literal>Z(i) = A(i) * b</literal>.
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>Example:</title>
+  <para>
+<screen>Vector&lt;float&gt; Z, A, B;
+Z = mul(A, B);</screen>
+  </para>
+ </formalpara>
+
+ <formalpara>
+  <title>See Also:</title>
+  <para>
+   <function>add</function> 
+       <xref linkend="functionref_add" role="template:(section %n)"/>
+   <function>div</function> 
+       <xref linkend="functionref_div" role="template:(section %n)"/>
+   <function>sub</function> 
+       <xref linkend="functionref_sub" role="template:(section %n)"/>
+  </para>
+ </formalpara>
+
+</section>
