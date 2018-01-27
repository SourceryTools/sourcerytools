Index: doc/manual/datatypes.xml
===================================================================
--- doc/manual/datatypes.xml	(revision 221548)
+++ doc/manual/datatypes.xml	(working copy)
@@ -503,6 +503,67 @@
    </variablelist>
   </section>
 
+
+  <section id="classref_mat_op_type">
+   <title>mat_op_type</title>
+
+   <indexterm>
+    <primary>mat_op_type</primary>
+   </indexterm>
+
+   <para>Linear equation solvers use 
+   <emphasis role="bold"><type>mat_op_type</type></emphasis> to
+   indicate the matrix operation type.
+   </para>
+
+   <variablelist>
+    <varlistentry>
+     <term>mat_ntrans</term>
+
+     <listitem>
+      <para>Indicates the matrix should not be transposed.<indexterm>
+        <primary>mat_ntrans</primary>
+       </indexterm></para>
+     </listitem>
+    </varlistentry>
+
+    <varlistentry>
+     <term>mat_trans</term>
+
+     <listitem>
+      <para>Indicates the matrix should be transposed.<indexterm>
+        <primary>mat_trans</primary>
+       </indexterm></para>
+     </listitem>
+    </varlistentry>
+
+    <varlistentry>
+     <term>mat_herm</term>
+
+     <listitem>
+      <para>Indicates the Hermitian transpose or conjugate transpose
+      of the matrix should be taken.
+      <indexterm>
+        <primary>mat_herm</primary>
+       </indexterm></para>
+     </listitem>
+    </varlistentry>
+
+    <varlistentry>
+     <term>mat_conj</term>
+
+     <listitem>
+      <para>Indicates the conjugate of the matrix should be taken.
+      <indexterm>
+        <primary>mat_conj</primary>
+       </indexterm></para>
+     </listitem>
+    </varlistentry>
+
+   </variablelist>
+  </section>
+
+
   <section id="classref_obj_state">
    <title>obj_state</title>
 
@@ -540,6 +601,133 @@
    </variablelist>
   </section>
 
+
+  <section id="classref_product_side_type">
+   <title>product_side_type</title>
+
+   <indexterm>
+    <primary>product_side_type</primary>
+   </indexterm>
+
+   <para>Linear equation solvers, specifically 
+   <emphasis role="bold">QR</emphasis> and <emphasis role="bold">SVD</emphasis>, 
+   use <emphasis role="bold"><type>product_side_type</type></emphasis> to
+   indicate whether to use left or right multiplication in matrix products.
+   </para>
+
+   <variablelist>
+    <varlistentry>
+     <term>mat_lside</term>
+
+     <listitem>
+      <para>Indicates <code>prod(A, B)</code> yields the product 
+      <varname>A</varname> <varname>B</varname>.<indexterm>
+        <primary>mat_lside</primary>
+       </indexterm></para>
+     </listitem>
+    </varlistentry>
+
+    <varlistentry>
+     <term>mat_rside</term>
+
+     <listitem>
+      <para>Indicates <code>prod(A, B)</code> yields the product 
+      <varname>B</varname> <varname>A</varname>.<indexterm>
+        <primary>mat_rside</primary>
+       </indexterm></para>
+     </listitem>
+    </varlistentry>
+
+   </variablelist>
+  </section>
+
+
+  <section id="classref_return_mechanism_type">
+   <title>return_mechanism_type</title>
+
+   <indexterm>
+    <primary>return_mechanism_type</primary>
+   </indexterm>
+
+   <para>Fast Fourier Transforms and Linear equation solvers, specifically 
+   <emphasis role="bold">QR</emphasis> and <emphasis role="bold">SVD</emphasis>, 
+   use <emphasis role="bold"><type>return_mechanism_type</type></emphasis> to 
+   indicate the return mechanism format for matrices containing results.</para>
+
+   <variablelist>
+    <varlistentry>
+     <term>by_value</term>
+
+     <listitem>
+      <para>Indicates a function returns a computed value. <indexterm>
+        <primary>by_value</primary>
+       </indexterm></para>
+     </listitem>
+    </varlistentry>
+
+    <varlistentry>
+     <term>by_reference</term>
+
+     <listitem>
+      <para>Indicates a function requires a parameter where the computed 
+      value is saved <indexterm>
+        <primary>by_reference</primary>
+       </indexterm></para>
+     </listitem>
+    </varlistentry>
+
+   </variablelist>
+  </section>
+
+
+  <section id="classref_storage_type">
+   <title>storage_type</title>
+
+   <indexterm>
+    <primary>storage_type</primary>
+   </indexterm>
+
+   <para>Linear equation solvers, specifically <emphasis 
+   role="bold">QR</emphasis> and <emphasis role="bold">SVD</emphasis>, use
+   <emphasis role="bold"><type>storage_type</type></emphasis> to indicate 
+   the storage format for decomposed matrices.</para>
+
+   <variablelist>
+    <varlistentry>
+     <term>qrd_nosaveq</term>
+
+     <listitem>
+      <para>The object does not store Q. <indexterm>
+        <primary>qrd_nosaveq</primary>
+       </indexterm></para>
+     </listitem>
+    </varlistentry>
+
+    <varlistentry>
+     <term>qrd_saveq1</term>
+
+     <listitem>
+      <para>Q is stored using the same amount of space as
+      the matrix m given to the constructor. <indexterm>
+        <primary>qrd_saveq1</primary>
+       </indexterm></para>
+     </listitem>
+    </varlistentry>
+
+    <varlistentry>
+     <term>qrd_saveq</term>
+
+     <listitem>
+      <para>The square matrix Q is stored using the same 
+      number of rows as m.<indexterm>
+        <primary>qrd_saveq</primary>
+       </indexterm></para>
+     </listitem>
+    </varlistentry>
+   </variablelist>
+  </section>
+
+
   <section id="classref_support_region_type">
    <title>support_region_type</title>
 
@@ -646,5 +834,6 @@
     </varlistentry>
    </variablelist>
   </section>
+
  </section>
 </chapter>
Index: doc/manual/functions.xml
===================================================================
--- doc/manual/functions.xml	(revision 221548)
+++ doc/manual/functions.xml	(working copy)
@@ -111,4 +111,11 @@
   <xi:include href="corr.xml" />
   <xi:include href="histo.xml" />
  </section>
+
+ <section>
+  <title>Linear System Solvers</title>
+  <xi:include href="qr.xml" />
+ </section>
+
+
 </chapter>
Index: doc/manual/qr.xml
===================================================================
--- doc/manual/qr.xml	(revision 0)
+++ doc/manual/qr.xml	(revision 0)
@@ -0,0 +1,848 @@
+<?xml version="1.0" encoding="UTF-8"?>
+<!DOCTYPE section PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+"http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd">
+<section id="functionref_qr">
+ <title>QR Decomposition</title>
+
+ <para>This section describes the QR decomposition processing object
+ provided by VSIPL++.</para>
+
+ <section>
+  <title>Class template qrd&lt;&gt;</title>
+
+  <indexterm>
+   <primary>qrd</primary>
+  </indexterm>
+
+  <para>The template class <type>qrd</type> performs QR decomposition 
+  and solves linear systems.</para>
+
+  <synopsis>
+     template &lt;typename T,
+               return_mechanism_type ReturnMechanism = by_value&gt;
+     class qrd;</synopsis>
+
+  <variablelist>
+   <title>Template parameters</title>
+
+   <varlistentry>
+    <term>T</term>
+
+    <listitem>
+     <para>The value type used for decomposition object.  May be 
+     real or complex, single- or double-precision floating-point types.
+     </para>
+    </listitem>
+   </varlistentry>
+
+   <varlistentry>
+    <term>ReturnMechanism</term>
+
+    <listitem>
+     <para>The return mechanism type indicates whether to 
+     return the output view by-value or by-reference.  The former is
+     generally easier to code, though the latter is faster and preferred
+     for larger systems.  Must be a member of the enumeration type
+     <type>return_mechanism_type</type>.  See <xref 
+     linkend="classref_return_mechanism_type" role="template:(section %n)" />.
+     </para>
+    </listitem>
+   </varlistentry>
+
+  </variablelist>
+  </section>
+
+  <section>
+   <title>Constructor</title>
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::qrd()</secondary>
+   </indexterm>
+
+   <synopsis>
+     qrd(length_type rows, length_type columns, storage_type st);</synopsis>
+
+   <formalpara>
+    <title>Description:</title>
+
+    <para>Constructs a <type>qrd</type> object.  The parameters refer to the size 
+    of the <varname>Q</varname> and the manner in which it is stored in memory.
+    Note also that <type>qrd</type> objects may also be copied (constructed) 
+    from other <type>qrd</type> objects.</para>
+   </formalpara>
+
+   <formalpara>
+    <title>Requirements:</title>
+
+    <para> The number of rows must be greater than or equal 
+    to the number of columns.  The parameter <parameter>st</parameter> 
+    must be a member of the enumeration <type>storage_type</type>. See <xref
+   linkend="classref_storage_type" role="template:(section %n)" />.</para>
+   </formalpara>
+  </section>
+
+  <section>
+   <title>Accessor functions</title>
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::rows()</secondary>
+   </indexterm>
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::columns()</secondary>
+   </indexterm>
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::qstorage()</secondary>
+   </indexterm>
+
+   <synopsis>     length_type rows() const;
+     length_type columns() const;
+     storage_type qstorage() const;</synopsis>
+
+   <formalpara>
+    <title>Description:</title>
+
+    <para>Report the various attributes of this qrd object.  The
+    number of rows is returned by <function>rows()</function>, the number
+    of columns by <function>columns()</function> and <function>qstorage()</function> 
+    returns the storage type for the <varname>Q</varname> matrix, as 
+    speciﬁed in the constructor.</para>
+   </formalpara>
+
+  </section>
+
+
+  <section>
+   <title>Solve Systems</title>
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::decompose()</secondary>
+   </indexterm>
+
+   <synopsis>     template &lt;typename Block&gt;
+     bool 
+     decompose(Matrix&lt;T, Block&gt; A);</synopsis>
+   
+   <formalpara>
+     <title>Description:</title>
+     
+     <para>Performs a QR decomposition of the matrix <parameter>A</parameter> 
+     into matrices <varname>Q</varname> and <varname>R</varname>. 
+     The matrix <parameter>A</parameter> may be overwritten.</para>
+   </formalpara>
+   
+   <formalpara>
+     <title>Requirements:</title>
+     
+     <para><parameter>A</parameter> must be the same size as specified
+     in the constructor.</para>
+   </formalpara>
+   
+   <formalpara>
+     <title>Result:</title>
+     
+     <para>False is returned if the decomposition fails because 
+     <parameter>A</parameter> does not have full column rank.   The matrix 
+     <parameter>A</parameter> should not be modiﬁed as long as its decomposition
+     will still be used.  Note: If <type>T</type> is a specialization 
+     of complex, <varname>Q</varname> is unitary. Otherwise, <varname>Q</varname>
+     is orthogonal.  <varname>R</varname> is an upper triangular matrix.  If 
+     <parameter>A</parameter> has full rank, then <varname>R</varname> is a 
+     nonsingular matrix.  No column interchanges are performed.</para>
+   </formalpara>
+  </section>
+
+
+  <section>
+   <title>Solve Systems (by_value)</title>
+
+   <para>The following functions are available only if the constructor
+   is called with <code>ReturnMechanismType=by_value</code></para>
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::prodq()</secondary>
+   </indexterm>
+
+   <synopsis>     template &lt;mat_op_type       tr,
+               product_side_type ps,
+               typename          Block&gt;
+     const_Matrix&lt;T, <emphasis>unspecified</emphasis>&gt;
+     prodq(const_Matrix&lt;T, Block&gt; m);</synopsis>
+   
+   <formalpara>
+     <title>Description:</title>
+     
+     <para>Calculates the product of <varname>Q</varname> and 
+     <parameter>m</parameter>.  The value of 
+     <type>tr</type> must be of type <type>mat_op_type</type>
+     <xref linkend="classref_mat_op_type" 
+     role="template:(section %n)" /> and the value of <type>ps</type> 
+     must be of type <type>product_side_type</type> <xref 
+     linkend="classref_product_side_type" role="template:(section %n)" />.
+     The actual product and its number of rows and columns depends 
+     on the values of <type>tr</type>, <type>ps</type>, and 
+     <function>qstorage()</function> and whether <type>T</type> 
+     is not or is a specialization of complex.  
+     For <code>qstorage() == qrd_saveq1,</code></para>
+   </formalpara>
+
+     <informaltable pgwide="1">
+       <tgroup cols="3">
+	 <thead>
+	   <row>
+	     <entry></entry>
+	     <entry>ps == mat_lside</entry>
+	     <entry>ps == mat_rside</entry>
+	   </row>
+	 </thead>
+
+	 <tbody>
+	   <row>
+	     <entry>tr == mat_ntrans</entry>
+	     <entry>Qm, rows(), s</entry>
+	     <entry>mQ, s, columns()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_trans, T</entry>
+	     <entry>Q<superscript>T</superscript>m, columns(), s</entry>
+	     <entry>mQ<superscript>T</superscript>, s, rows()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_herm, complex&lt;T&gt;</entry>
+	     <entry>Q<superscript>H</superscript>m, columns(), s</entry>
+	     <entry>mQ<superscript>H</superscript>, s, rows()</entry>
+	   </row>
+
+	 </tbody>
+       </tgroup>
+     </informaltable>
+
+   <para>where <parameter>s</parameter> is an arbitrary positive <type>
+   length_type</type>.  For <code>qstorage() == qrd_saveq</code>,
+   </para>
+
+     <informaltable pgwide="1">
+       <tgroup cols="3">
+	 <thead>
+	   <row>
+	     <entry></entry>
+	     <entry>ps == mat_lside</entry>
+	     <entry>ps == mat_rside</entry>
+	   </row>
+	 </thead>
+
+	 <tbody>
+	   <row>
+	     <entry>tr == mat_ntrans</entry>
+	     <entry>Qm, rows(), s</entry>
+	     <entry>mQ, s, rows()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_trans, T</entry>
+	     <entry>Q<superscript>T</superscript>m, rows(), s</entry>
+	     <entry>mQ<superscript>T</superscript>, s, rows()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_herm, complex&lt;T&gt;</entry>
+	     <entry>Q<superscript>H</superscript>m, rows(), s</entry>
+	     <entry>mQ<superscript>H</superscript>, s, rows()</entry>
+	   </row>
+
+	 </tbody>
+       </tgroup>
+     </informaltable>
+
+   <formalpara>
+     <title>Requirements:</title>
+     
+     <para>A call to <code>decompose()</code> must have occurred for 
+     this object with <function>qstorage()</function> equaling either <type>qrd_saveq1
+     </type> or <type>qrd_saveq</type>.  Otherwise, the behavior is undeﬁned.  
+     The number of rows and columns of <parameter>m</parameter> depend on the 
+     values of <type>tr</type>, <type>ps</type>, and 
+     <function>qstorage()</function>. For <code>qstorage() == qrd_saveq1</code>,</para>
+   </formalpara>
+
+     <informaltable pgwide="1">
+       <tgroup cols="3">
+	 <thead>
+	   <row>
+	     <entry></entry>
+	     <entry>ps == mat_lside</entry>
+	     <entry>ps == mat_rside</entry>
+	   </row>
+	 </thead>
+
+	 <tbody>
+	   <row>
+	     <entry>tr == mat_ntrans</entry>
+	     <entry>columns(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_trans</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, columns()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_herm</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, columns()</entry>
+	   </row>
+	 </tbody>
+       </tgroup>
+     </informaltable>
+
+   <para>where <parameter>s</parameter> is the same variable as above.  
+   For <code>qstorage() == qrd_saveq</code>,
+   </para>
+
+     <informaltable pgwide="1">
+       <tgroup cols="3">
+	 <thead>
+	   <row>
+	     <entry></entry>
+	     <entry>ps == mat_lside</entry>
+	     <entry>ps == mat_rside</entry>
+	   </row>
+	 </thead>
+
+	 <tbody>
+	   <row>
+	     <entry>tr == mat_ntrans</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_trans</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_herm</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+	 </tbody>
+       </tgroup>
+     </informaltable>
+   
+   <formalpara>
+     <title>Result:</title>
+     
+     <para>Returns the product of <varname>Q</varname> and <parameter>m</parameter>.
+     Note that the returned matrix’s block type is not necessarily
+     equal to <type>Block</type>.
+     </para>
+   </formalpara>
+
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::rsol()</secondary>
+   </indexterm>
+
+   <synopsis>     template &lt;mat_op_type tr,
+               typename    Block&gt;
+     const_Matrix&lt;T, <emphasis>unspecified</emphasis>&gt;
+     rsol(
+       const_Matrix&lt;T, Block0&gt; b,
+       T const                 alpha);</synopsis>
+   
+   <formalpara>
+     <title>Description:</title>
+     
+     <para>Solves a linear system for <parameter>m</parameter>.
+     If <code>tr == mat_trans</code> and <type>T</type> is not a 
+     specialization of complex, then <code>R<superscript>T</superscript> 
+     <parameter>m</parameter> = <parameter>alpha</parameter> * <parameter>b
+     </parameter></code> is solved.
+     If <code>tr == mat_herm</code> and <type>T</type> is a 
+     specialization of complex, then <code>R<superscript>H</superscript> 
+     <parameter>m</parameter> = <parameter>alpha</parameter> * <parameter>b
+     </parameter></code> is solved.
+     Otherwise, <code>R <parameter>m</parameter> = <parameter>alpha
+     </parameter> * <parameter>b</parameter></code> is solved.</para>
+   </formalpara>
+
+   <formalpara>
+     <title>Requirements:</title>
+     
+     <para>The number of rows in <parameter>b</parameter> must be equal to
+     the value returned by <function>columns()</function>.  A call to <code>
+     decompose()</code> must have occurred.</para>
+   </formalpara>
+   
+   <formalpara>
+     <title>Result:</title>
+     
+     <para>Returns a constant matrix <parameter>m</parameter> containing
+     the solution.</para>
+   </formalpara>
+
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::covsol()</secondary>
+   </indexterm>
+
+   <synopsis>     template &lt;typename Block&gt;
+     const_Matrix&lt;T, <emphasis>unspecified</emphasis>&gt;
+     covsol(const_Matrix&lt;T, Block&gt; b);</synopsis>
+   
+   <formalpara>
+     <title>Description:</title>
+     
+     <para>Solves a covariance linear system for <parameter>m</parameter>.
+     If <type>T</type> is not a specialization of complex, then 
+     <code>A<superscript>T</superscript> A
+     <parameter>m</parameter> = <parameter>b</parameter></code> is solved,
+     where <varname>A</varname> is the matrix given to the most recent 
+     call to <code>decompose()</code>.
+     If <type>T</type> is a specialization of complex, then
+     <code>A<superscript>H</superscript> A
+     <parameter>m</parameter> = <parameter>b</parameter></code> is solved.
+     </para>
+   </formalpara>
+
+   <formalpara>
+     <title>Requirements:</title>
+     
+     <para>The number of rows in <parameter>b</parameter> must be equal to
+     the value returned by <function>columns()</function>.  Note also that 
+     <parameter>m</parameter> and <parameter>b</parameter> are 
+     element-conformant</para>
+   </formalpara>
+   
+   <formalpara>
+     <title>Result:</title>
+     
+     <para>Returns a matrix <parameter>m</parameter> containing the 
+     solution.</para>
+   </formalpara>
+
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::lsqsol()</secondary>
+   </indexterm>
+
+   <synopsis>     template &lt;typename Block&gt;
+     Matrix&lt;T, <emphasis>unspecified</emphasis>&gt;
+     lsqsol(const_Matrix&lt;T, Block&gt; b)</synopsis>
+   
+   <formalpara>
+     <title>Description:</title>
+     
+     <para>Solves the linear least squares problem 
+     <code>min<subscript>m</subscript> ||Am − b||<subscript>2</subscript></code>
+     for <parameter>m</parameter>, where <varname>A</varname> is the matrix 
+     given to the most recent call to <code>decompose()</code>.</para>
+   </formalpara>
+   
+   <formalpara>
+     <title>Requirements:</title>
+     
+     <para>The number of rows in <parameter>b</parameter> must be equal to
+     the value returned by <function>rows()</function>.  The number of rows in
+     <parameter>m</parameter> will equal the value returned by 
+     <function>columns()</function>.</para>
+   </formalpara>
+   
+   <formalpara>
+     <title>Result:</title>
+     
+     <para>Returns a constant matrix <parameter>m</parameter> containing
+     the solution.</para>
+   </formalpara>
+  </section>
+
+  <section>
+   <title>Solve Systems (by_reference)</title>
+
+   <para>The following functions are available only if the constructor
+   is called with <code>ReturnMechanismType=by_reference</code></para>
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::prodq()</secondary>
+   </indexterm>
+
+   <synopsis>     template &lt;mat_op_type       tr,
+               product_side_type ps,
+	       typename          Block0,
+	       typename          Block1&gt;
+     bool
+     prodq(
+       const_Matrix&lt;T, Block0&gt; m,
+       Matrix&lt;T, Block1&gt;       destination);</synopsis>
+   
+   <formalpara>
+     <title>Description:</title>
+     
+     <para>Calculates the product of <varname>Q</varname> and 
+     <parameter>m</parameter>.  The actual product depends on
+     the values of <type>tr</type>, and whether <type>T</type>
+     is not or is a specialization of complex:</para>
+   </formalpara>
+
+     <informaltable pgwide="1">
+       <tgroup cols="3">
+	 <thead>
+	   <row>
+	     <entry></entry>
+	     <entry>ps == mat_lside</entry>
+	     <entry>ps == mat_rside</entry>
+	   </row>
+	 </thead>
+
+	 <tbody>
+	   <row>
+	     <entry>tr == mat_ntrans</entry>
+	     <entry>Qm</entry>
+	     <entry>mQ</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_trans, T</entry>
+	     <entry>Q<superscript>T</superscript>m</entry>
+	     <entry>mQ<superscript>T</superscript></entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_herm, complex&lt;T&gt;</entry>
+	     <entry>Q<superscript>H</superscript>m</entry>
+	     <entry>mQ<superscript>H</superscript></entry>
+	   </row>
+
+	 </tbody>
+       </tgroup>
+     </informaltable>
+
+   <formalpara>
+     <title>Requirements:</title>
+     
+     <para>A call to <code>decompose()</code> must have occurred for 
+     this object with <function>qstorage()</function> equaling either 
+     <type>qrd_saveq1</type> or <type>qrd_saveq</type>.  Otherwise, the 
+     behavior is undeﬁned.  The number of rows and columns of 
+     <parameter>m</parameter> depends on the values of
+     <type>tr</type>, <type>ps</type>, and <function>qstorage()</function>. 
+     For <code>qstorage() == qrd_saveq1,</code></para>
+   </formalpara>
+
+     <informaltable pgwide="1">
+       <tgroup cols="3">
+	 <thead>
+	   <row>
+	     <entry></entry>
+	     <entry>ps == mat_lside</entry>
+	     <entry>ps == mat_rside</entry>
+	   </row>
+	 </thead>
+
+	 <tbody>
+	   <row>
+	     <entry>tr == mat_ntrans</entry>
+	     <entry>columns(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_trans</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, columns()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_herm</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, columns()</entry>
+	   </row>
+
+	 </tbody>
+       </tgroup>
+     </informaltable>
+
+   <para>where <parameter>s</parameter> is an arbitrary positive <type>
+   length_type</type>.  For <code>qstorage() == qrd_saveq</code>,
+   </para>
+
+     <informaltable pgwide="1">
+       <tgroup cols="3">
+	 <thead>
+	   <row>
+	     <entry></entry>
+	     <entry>ps == mat_lside</entry>
+	     <entry>ps == mat_rside</entry>
+	   </row>
+	 </thead>
+
+	 <tbody>
+	   <row>
+	     <entry>tr == mat_ntrans</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_trans</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_herm</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+	 </tbody>
+       </tgroup>
+     </informaltable>
+   
+   <para>The number of rows and columns of <parameter>destination</parameter> 
+   depends on the values of <type>tr</type>, <type>ps</type>, and 
+   <function>qstorage()</function>.  
+   For <code>qstorage() == qrd_saveq1,</code>
+   </para>
+
+     <informaltable pgwide="1">
+       <tgroup cols="3">
+	 <thead>
+	   <row>
+	     <entry></entry>
+	     <entry>ps == mat_lside</entry>
+	     <entry>ps == mat_rside</entry>
+	   </row>
+	 </thead>
+
+	 <tbody>
+	   <row>
+	     <entry>tr == mat_ntrans</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, columns()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_trans</entry>
+	     <entry>columns(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_herm</entry>
+	     <entry>columns(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+
+	 </tbody>
+       </tgroup>
+     </informaltable>
+
+   <para>where <parameter>s</parameter> is the same variable as above.  
+   For <code>qstorage() == qrd_saveq</code>,
+   </para>
+
+     <informaltable pgwide="1">
+       <tgroup cols="3">
+	 <thead>
+	   <row>
+	     <entry></entry>
+	     <entry>ps == mat_lside</entry>
+	     <entry>ps == mat_rside</entry>
+	   </row>
+	 </thead>
+
+	 <tbody>
+	   <row>
+	     <entry>tr == mat_ntrans</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_trans</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+
+	   <row>
+	     <entry>tr == mat_herm</entry>
+	     <entry>rows(), s</entry>
+	     <entry>s, rows()</entry>
+	   </row>
+	 </tbody>
+       </tgroup>
+     </informaltable>
+
+
+   <formalpara>
+     <title>Result:</title>
+     
+     <para>Calculates the product of <varname>Q</varname> and 
+     <parameter>m</parameter> stores it in <parameter>destination</parameter>.
+     </para>
+   </formalpara>
+
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::rsol()</secondary>
+   </indexterm>
+
+   <synopsis>     template &lt;mat_op_type tr,
+               typename    Block0,
+               typename    Block1&gt;
+     bool
+     rsol(
+       const_Matrix&lt;T, Block0&gt; b,
+       T const                 alpha,
+       Matrix&lt;T, Block1&gt;       destination);</synopsis>
+   
+   <formalpara>
+     <title>Description:</title>
+     
+     <para>Solves a linear system for <parameter>destination</parameter>.
+     If <code>tr == mat_trans</code> and <type>T</type> is not a 
+     specialization of complex, then <code>R<superscript>T</superscript> 
+     <parameter>destination</parameter> = <parameter>alpha</parameter> * 
+     <parameter>b</parameter></code> is solved.
+     If <code>tr == mat_herm</code> and <type>T</type> is a 
+     specialization of complex, then <code>R<superscript>H</superscript> 
+     <parameter>destination</parameter> = <parameter>alpha</parameter> * 
+     <parameter>b</parameter></code> is solved.
+     Otherwise, <code>R <parameter>destination</parameter> = <parameter>alpha
+     </parameter> * <parameter>b</parameter></code> is solved.</para>
+   </formalpara>
+   
+   <formalpara>
+     <title>Requirements:</title>
+     
+     <para>The number of rows in <parameter>b</parameter> must be equal to
+     the value returned by <function>columns()</function>.  A call to <code>
+     decompose()</code> must have occurred.</para>
+   </formalpara>
+   
+   <formalpara>
+     <title>Result:</title>
+     
+     <para>Stores the solution in <parameter>destination</parameter>.</para>
+   </formalpara>
+
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::covsol()</secondary>
+   </indexterm>
+
+   <synopsis>     template &lt;typename Block0,
+               typename Block1&gt;
+     bool
+     covsol(
+       const_Matrix&lt;T, Block0&gt; b,
+       Matrix&lt;T, Block1&gt;       destination);</synopsis>
+   
+   <formalpara>
+     <title>Description:</title>
+     
+     <para>Solves a covariance linear system for <parameter>destination</parameter>.
+     If <type>T</type> is not a specialization of complex, then 
+     <code><superscript>T</superscript> A
+     <parameter>destination</parameter> = <parameter>b</parameter></code> is solved,
+     where <varname>A</varname> is the matrix given to the most recent 
+     call to <code>decompose()</code>.
+     If <type>T</type> is a specialization of complex, then
+     <code>A<superscript>H</superscript> A
+     <parameter>destination</parameter> = <parameter>b</parameter></code> is solved.
+     </para>
+   </formalpara>
+   
+   <formalpara>
+     <title>Requirements:</title>
+     
+     <para>The number of rows in <parameter>b</parameter> must be equal to
+     the value returned by <function>columns()</function>.  Note also that 
+     <parameter>destination</parameter> is modifiable and element-conformant
+     with <parameter>b</parameter>.</para>
+   </formalpara>
+   
+   <formalpara>
+     <title>Result:</title>
+     
+     <para>The solution is stored in <parameter>destination</parameter></para>
+   </formalpara>
+
+
+   <indexterm>
+    <primary>qrd</primary>
+
+    <secondary>qrd::lsqsol()</secondary>
+   </indexterm>
+
+   <synopsis>     template &lt;typename Block0,
+               typename Block1&gt;
+     bool
+     lsqsol(
+       const_Matrix&lt;T, Block0&gt; b,
+       Matrix&lt;T, Block1&gt;       destination)   </synopsis>
+   
+   <formalpara>
+     <title>Description:</title>
+     
+     <para>Solves the linear least squares problem 
+     <code>min<subscript>destination</subscript> 
+     ||Am − b||<subscript>2</subscript></code>
+     for <parameter>destination</parameter>, where <varname>A</varname> 
+     is the matrix given to the most recent call to 
+     <code>decompose()</code>.</para>
+   </formalpara>
+   
+   <formalpara>
+     <title>Requirements:</title>
+     
+     <para>The number of rows in <parameter>b</parameter> must be equal to
+     the value returned by <function>rows()</function>.  The number of rows in
+     <parameter>destination</parameter> must equal the value returned by 
+     <function>columns()</function>.</para>
+   </formalpara>
+   
+   <formalpara>
+     <title>Result:</title>
+     
+     <para>Stores the solution in the matrix 
+     <parameter>destination</parameter>.</para>
+   </formalpara>
+  </section>
+
+</section>
+
+
+
+
