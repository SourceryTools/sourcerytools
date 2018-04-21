? docs/reference/doxygen.log
? docs/reference/html
Index: docs/introduction.html
===================================================================
RCS file: /home/pooma/Repository/r2/docs/introduction.html,v
retrieving revision 1.1
diff -u -u -r1.1 introduction.html
--- docs/introduction.html	19 Mar 2001 16:11:13 -0000	1.1
+++ docs/introduction.html	19 Aug 2004 21:23:42 -0000
@@ -154,11 +154,11 @@
 before proceeding.
 
 <p>You may also wish to look at the <a
-href="http://www.acl.lanl.gov/pooma">POOMA</a> web site for updates,
+href="http://www.pooma.com/">POOMA</a> web site for updates,
 bug fixes, and discussion of the library and how it can be used. If
 you have any questions about POOMA or its terms of use, or if you need
 help downloading or installing POOMA, please send mail to <tt><a
-href="mailto:pooma-devel@lanl.gov">pooma-devel@lanl.gov</a></tt>.
+href="mailto:pooma-dev@pooma.codesourcery.com">pooma-dev@pooma.codesourcery.com</a></tt>.
 
 
 <br>
Index: docs/legal.html
===================================================================
RCS file: /home/pooma/Repository/r2/docs/legal.html,v
retrieving revision 1.2
diff -u -u -r1.2 legal.html
--- docs/legal.html	15 Oct 2001 17:34:29 -0000	1.2
+++ docs/legal.html	19 Aug 2004 21:23:42 -0000
@@ -33,9 +33,9 @@
 version available from LANL.
 
 <p>For more information about POOMA, send e-mail to
-<a href="mailto:pooma-devel@lanl.gov">pooma-devel@lanl.gov</a>,
+<a href="mailto:pooma-dev@pooma.codesourcery.com">pooma-dev@pooma.codesourcery.com</a>,
 or visit the POOMA web page at
-<a href="http://www.acl.lanl.gov/pooma/">http://www.acl.lanl.gov/pooma</a>.
+<a href="http://www.pooma.com/">http://www.pooma.com/</a>.
 
 <br>
 <br>
Index: docs/reading.html
===================================================================
RCS file: /home/pooma/Repository/r2/docs/reading.html,v
retrieving revision 1.1
diff -u -u -r1.1 reading.html
--- docs/reading.html	19 Mar 2001 16:11:13 -0000	1.1
+++ docs/reading.html	19 Aug 2004 21:23:42 -0000
@@ -64,12 +64,6 @@
 of these entities can serve as a model of a concept. Using these
 ideas, Austern also provides a complete reference for the STL.
 
-<p>Finally, see the POOMA web site for
-<a href="http://www.acl.lanl.gov/pooma/presentations.html">
-on-line presentations</a> and 
-<a href="http://www.acl.lanl.gov/pooma/papers.html">
-technical papers</a> describing the POOMA framework.
-
 
 <h2>Bibliography</h2>
 
Index: docs/tut-02.html
===================================================================
RCS file: /home/pooma/Repository/r2/docs/tut-02.html,v
retrieving revision 1.2
diff -u -u -r1.2 tut-02.html
--- docs/tut-02.html	26 Mar 2001 23:49:59 -0000	1.2
+++ docs/tut-02.html	19 Aug 2004 21:23:42 -0000
@@ -377,7 +377,7 @@
 <a name="expressions"><h2>A Note on Expressions</h2></a>
 
 <p>As you may have guessed from the preceding discussion,
-POOMA expressions are first-class <tt>ConstArray</tt>s
+POOMA expressions are first-class non-writable <tt>Array</tt>s
 with an expression engine.  As a consequence, expressions can be
 subscripted directly, as in:
 
@@ -419,7 +419,7 @@
 a = sin(iota(n1,n2).comp(0)) + iota(n1,n2).comp(1)*5;
 </pre></blockquote>
 
-<p>In general, <tt>iota(domain)</tt> returns a <tt>ConstArray</tt>
+<p>In general, <tt>iota(domain)</tt> returns an <tt>Array</tt>
 whose elements are vectors, such that <tt>iota(domain)(i,j)</tt> is
 <tt>Vector&lt;2,int&gt;(i,j)</tt>.  These values can be used in
 expressions, or stored in objects, as in:
Index: docs/tut-04.html
===================================================================
RCS file: /home/pooma/Repository/r2/docs/tut-04.html,v
retrieving revision 1.2
diff -u -u -r1.2 tut-04.html
--- docs/tut-04.html	26 Mar 2001 23:49:59 -0000	1.2
+++ docs/tut-04.html	19 Aug 2004 21:23:43 -0000
@@ -401,7 +401,7 @@
 arithmetic types like <tt>int</tt> or <tt>double</tt>.  In particular,
 <tt>Vector</tt>, <tt>Tensor</tt>, and <tt>complex</tt> are explicitly
 supported.  Please contact <a
-href="mailto:pooma-devel@lanl.gov">pooma-devel@lanl.gov</a> for
+href="mailto:pooma-dev@pooma.codesourcery.com">pooma-dev@pooma.codesourcery.com</a> for
 information on using other, more complicated types.
 
 <p>The <tt>Array::comp()</tt> method used on line&nbsp;16 does <a
@@ -1007,8 +1007,8 @@
 <tt>a.comp(2)</tt> does <em>not</em> copy values out of <tt>a</tt>
 into temporary storage.
 
-<p>If the source array of a component view is writable (i.e. not a
-<tt>ConstArray</tt>), then that component view can appear on
+<p>If the source array of a component view is writable,
+then that component view can appear on
 either side of the assignment operator. For example:
 
 <blockquote><pre>
@@ -1021,7 +1021,7 @@
 used to make an object to store the view, as in:
 
 <blockquote><pre>
-ComponentView&lt;Loc&lt;1&gt;, Array&lt;2, Vector&lt;3&gt; &gt; &gt; va = a.comp(1);
+typename ComponentView&lt;Loc&lt;1&gt;, Array&lt;2, Vector&lt;3&gt; &gt; &gt;::Type_t va = a.comp(1);
 </pre></blockquote>
 
 <p>Here, the argument "Loc&lt;1&gt;" indicates that the component is singly-indexed.
