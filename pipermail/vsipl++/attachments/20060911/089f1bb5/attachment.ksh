Index: ChangeLog
===================================================================
--- ChangeLog	(revision 148502)
+++ ChangeLog	(working copy)
@@ -1,3 +1,16 @@
+2006-09-11  Jules Bergmann  <jules@codesourcery.com>
+
+	* doc/tutorial/tutorial.xml: Split into tutorial (part I) and
+	  reference (part II).
+	* doc/tutorial/src/ser/fc1-admit-release.cpp: New file, source
+	  code for serial IO example.
+	* doc/tutorial/serial.xml: New file, contains serial portions of
+	  fast convolution example ...
+	* doc/tutorial/parallel.xml: ... taken from here.
+	* doc/tutorial/performance.xml: Add chapter id.
+	* doc/tutorial/optimization.xml: Likewise.
+	* doc/tutorial/api.xml: Likewise.
+	
 2006-09-05  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/dense.hpp (Dense): Add implementation constructor
Index: doc/tutorial/performance.xml
===================================================================
--- doc/tutorial/performance.xml	(revision 148422)
+++ doc/tutorial/performance.xml	(working copy)
@@ -10,7 +10,8 @@
 [
  <!ENTITY vsiplxx "VSIPL++">
 ]>
-<chapter xmlns:xi="http://www.w3.org/2003/XInclude">
+<chapter id="chap-performance"
+         xmlns:xi="http://www.w3.org/2003/XInclude">
   <title>Performance</title>
   <section id="library-profiling"><title>Library Profiling</title>
     <para>
Index: doc/tutorial/tutorial.xml
===================================================================
--- doc/tutorial/tutorial.xml	(revision 148422)
+++ doc/tutorial/tutorial.xml	(working copy)
@@ -23,18 +23,54 @@
 <book xmlns:xi="http://www.w3.org/2003/XInclude">
   <bookinfo>
     <title>Sourcery VSIPL++</title>
-    <subtitle>Tutorial</subtitle>
+    <subtitle>User's Guide</subtitle>
     <corpauthor>CodeSourcery</corpauthor>
     <copyright><year>2005, 2006</year><holder>CodeSourcery</holder></copyright>
 <!--  <legalnotice>&opl.xml;</legalnotice>-->
     <releaseinfo>Version &version;</releaseinfo>
   </bookinfo>
-  <xi:include href="overview.xml" parse="xml"/>
-  <xi:include href="api.xml" parse="xml"/>
-  <xi:include href="parallel.xml" parse="xml"/>
-  <xi:include href="optimization.xml" parse="xml"/>
-  <xi:include href="performance.xml" parse="xml">
-    <xi:fallback><chapter><title>Optimizations...TBD</title></chapter></xi:fallback>
-  </xi:include>
-  <xi:include href="glossary.xml"/>
+
+  <part label="I">
+    <title>Tutorial</title>
+    <partintro>
+      <para>
+        The sections in Part I form a tutorial for using Sourcery VSIPL++,
+        covering serial programming, parallel programming, and
+        performance analysis.
+        You can follow along with the tutorial to learn how to
+        use VSIPL++, and you can adapt the examples for use in your
+        own programs.
+      </para>
+
+      <literallayout>
+        <xref linkend="chap-serial"/>
+        <xref linkend="chap-parallel"/>
+        <xref linkend="chap-performance"/>
+      </literallayout>
+    </partintro>
+
+    <xi:include href="serial.xml" parse="xml"/>
+    <xi:include href="parallel.xml" parse="xml"/>
+    <xi:include href="performance.xml" parse="xml"/>
+    <!-- SAR description
+       <xi:include href="overview.xml" parse="xml"/>
+     -->
+  </part>
+
+  <part label="II">
+    <title>Reference</title>
+    <partintro>
+      <para>
+        The sections in Part II form a reference manual for Sourcery VSIPL++.
+      </para>
+
+      <literallayout>
+        <xref linkend="chap-ref-api"/>
+        <xref linkend="glossary"/>
+      </literallayout>
+    </partintro>
+
+    <xi:include href="api.xml" parse="xml"/>
+    <xi:include href="glossary.xml"/>
+  </part>
 </book>
Index: doc/tutorial/optimization.xml
===================================================================
--- doc/tutorial/optimization.xml	(revision 148422)
+++ doc/tutorial/optimization.xml	(working copy)
@@ -14,7 +14,8 @@
     >VSIPL++ API specification</ulink>">
  <!ENTITY version "0.9">
 ]>
-<chapter xmlns:xi="http://www.w3.org/2003/XInclude">
+<chapter id="chap-ref-optimization"
+	 xmlns:xi="http://www.w3.org/2003/XInclude">
   <title>Optimizations</title>
   <section id="dimension-ordering"><title>Dimension ordering</title>
     <para>
Index: doc/tutorial/src/ser/fc1-admit-release.cpp
===================================================================
--- doc/tutorial/src/ser/fc1-admit-release.cpp	(revision 0)
+++ doc/tutorial/src/ser/fc1-admit-release.cpp	(revision 0)
@@ -0,0 +1,90 @@
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/math.hpp>
+
+using namespace vsip;
+
+
+
+/***********************************************************************
+  Main Program
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  // Initialize the library.
+  vsipl vpp(argc, argv);
+
+  typedef complex<float> value_type;
+
+  // Parameters.
+  length_type npulse = 64;	// number of pulses
+  length_type nrange = 256;	// number of range cells
+
+  // Allocate data.
+  auto_ptr<value_type> data_ptr(new value_type[npulse*nrange]);
+
+  // Blocks.
+  Dense<2, value_type> block(Domain<2>(npulse, nrange), data_ptr.get());
+
+  // Views.
+  Vector<value_type> replica(nrange);
+  Matrix<value_type> data(block);
+  Matrix<value_type> tmp(npulse, nrange);
+
+  // A forward Fft for computing the frequency-domain version of
+  // the replica.
+  typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
+		for_fft_type;
+  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
+
+  // A forward Fftm for converting the time-domain data matrix to the
+  // frequency domain.
+  typedef Fftm<value_type, value_type, row, fft_fwd, by_reference>
+	  	for_fftm_type;
+  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+
+  // An inverse Fftm for converting the frequency-domain data back to
+  // the time-domain.
+  typedef Fftm<value_type, value_type, row, fft_inv, by_reference>
+	  	inv_fftm_type;
+  inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange));
+
+  // Initialize data to zero.
+  data    = value_type();
+  replica = value_type();
+
+  // Before fast convolution, convert the replica to the the
+  // frequency domain
+  for_fft(replica);
+
+
+  // Perform input I/O.
+  view.block().release(false);
+  size_t size = read(0, data_ptr.get(), sizeof(value_type)*nrange*npulse);
+  assert(size == sizeof(value_type)*nrange*npulse));
+  view.block().admit(true);
+
+  // Perform fast convolution.
+
+  // Convert to the frequency domain.
+  for_fftm(data, tmp);
+
+  // Perform element-wise multiply for each pulse.
+  tmp = vmmul<0>(replica, tmp);
+
+  // Convert back to the time domain.
+  inv_fftm(tmp, data);
+
+  // Perform output I/O.
+  view.block().release(true);
+  size_t size = read(0, data_ptr.get(), sizeof(value_type)*nrange*npulse);
+  assert(size == sizeof(value_type)*nrange*npulse));
+  view.block().admit(false);
+}
Index: doc/tutorial/api.xml
===================================================================
--- doc/tutorial/api.xml	(revision 148422)
+++ doc/tutorial/api.xml	(working copy)
@@ -20,7 +20,8 @@
     >VSIPL++ API specification</ulink>">
  <!ENTITY version "0.9">
 ]>
-<chapter xmlns:xi="http://www.w3.org/2003/XInclude">
+<chapter id="chap-ref-api"
+	 xmlns:xi="http://www.w3.org/2003/XInclude">
   <title>API overview</title>
   <section id="views"><title>Views</title>
     <para>
Index: doc/tutorial/parallel.xml
===================================================================
--- doc/tutorial/parallel.xml	(revision 148422)
+++ doc/tutorial/parallel.xml	(working copy)
@@ -1,12 +1,12 @@
-<chapter id="chap-parallel-tutorial"
+<chapter id="chap-parallel"
          xmlns:xi="http://www.w3.org/2003/XInclude">
- <title>Parallel Tutorial</title>
+ <title>Parallel Fast Convolution</title>
 
  <chapterinfo>
   <abstract>
    <para>
-    This chapter describes how to create and run a parallel VSIPL++
-    program with Sourcery VSIPL++.  You can modify this program to
+    This chapter describes how to create and run parallel VSIPL++
+    programs with Sourcery VSIPL++.  You can modify the programs to
     develop your own parallel applications.
    </para>
   </abstract>
@@ -14,206 +14,20 @@
 
  <para>
   This chapter explains how to use Sourcery VSIPL++ to perform
-  parallel computations.  First, you will see how to compute
-  <firstterm>fast convolution</firstterm> (a common signal-processing
-  kernel) using a single processor.  Next, you will see how to
-  convert the serial implementation to a parallel program so that you
-  can take advantage of multiple processors.  Then, you will learn
-  how to optimize the performance of the parallel implementation.
-  Finally, you will learn how to handle input and output when working
-  in parallel.
+  parallel computations.  You will see how to transform the
+  fast convolution program from the previous chapter to run
+  in parallel.  First you will convert the <function>Fftm</function>
+  based version.  Then you will convert the improved cache
+  locality version.  Finally, you will learn how to handle
+  input and output when working in parallel.
  </para>
 
- <section id="sec-serial-fastconv">
-  <title>Serial Fast Convolution</title>
-
-  <para>
-   Fast convolution is the technique of performing convolution in the
-   frequency domain.  In particular, the time-domain convolution
-   <mathphrase>f * g</mathphrase> can be computed as <mathphrase>F
-   . G</mathphrase>, where <mathphrase>F</mathphrase> and
-   <mathphrase>G</mathphrase> are the frequency-domain representations
-   of the signals <mathphrase>f</mathphrase> and
-   <mathphrase>g</mathphrase>.  A time-domain signal consisting of
-   <mathphrase>n</mathphrase> samples can be converted to a
-   frequency-domain signal in <mathphrase>O(n log n)</mathphrase>
-   operations by using a Fast Fourier Transform (FFT).  Substantially
-   fewer operations are required to perform the frequency-domain
-   operation <mathphrase>F . G</mathphrase> than are required to perform
-   the time-domain operation <mathphrase>f * g</mathphrase>.  Therefore,
-   performing convolutions in the frequency domain can be substantially
-   faster than performing the equivalent computations in the time
-   domain, even taking into account the cost of converting from the
-   time domain to the frequency domain.
-  </para>
-
-  <para>
-   One practical use of fast convolution is to perform the pulse
-   compression step in radar signal processing.  To increase the
-   effective bandwidth of a system, radars will transmit a frequency
-   modulated &quot;chirp&quot;.  By convolving the received signal with
-   the time-inverse of the chirp (called the &quot;replica&quot;), the
-   total energy returned from an object can be collapsed into a single
-   range cell.  Fast convolution is also useful in many other contexts
-   including sonar processing and software radio.
-  </para>
-
-  <para>
-   In this section, you will construct a program that performs fast
-   convolution on a set of time-domain signals stored in a matrix.
-   Each row of the matrix corresponds to a single signal, or
-   &quot;pulse&quot;.  The columns correspond to points in time.  So,
-   the entry at position (i, j) in the matrix indicates the amplitude
-   and phase of the signal received at time j for the ith pulse.
-  </para>
-  
-  <para>
-   The first step is to declare the data matrix, the vector that will
-   contain the replica signal, and a temporary matrix that will 
-   hold the results of the computation:
-  </para>
-
-  <programlisting><![CDATA[  // Parameters.
-  length_type npulse = 64;	// number of pulses
-  length_type nrange = 256;	// number of range cells
-
-  // Views.
-  typedef complex<float> value_type;
-  Vector<value_type> replica(nrange);
-  Matrix<value_type> data(npulse, nrange);
-  Matrix<value_type> tmp (npulse, nrange);]]></programlisting>
-
-  <para>
-   For now, it is most convenient to initialize the input data
-   to zero.  (In <xref linkend="sec-parallel-io"/>, you will learn how
-   to perform I/O operations so that you can populate the matrix with
-   real data.)
-  </para>
-
-  <para> 
-   In C++, you can use the constructor syntax <code>T()</code> to
-   perform &quot;default initialization&quot; of a type
-   <code>T()</code>.  The default value for any numeric type
-   (including complex numbers) is zero.  Therefore, the expression
-   <code>value_type()</code> indicates the complex number with zero as
-   both its real and imaginary components.  In the VSIPL++ API, when
-   you assign a scalar value to a view (a vector, matrix, or tensor),
-   all elements of the view are assigned the scalar value.  So, the
-   code below sets the contents of both the data matrix and  replica
-   vector to zero:
-  </para>
-
-  <programlisting><![CDATA[  data    = value_type();
-  replica = value_type();]]></programlisting>
-
-  <para>
-   The next step is to define the FFTs that will be performed.
-   Typically (as in this example) an application performs multiple
-   FFTs on inputs with the same size.  Since performing an FFT
-   requires that some set-up be performed before performing the actual
-   FFT computation, it is more efficient to set up the FFT just once.
-   Therefore, in the VSIPL++ API, FFTs are objects, rather than
-   operators.  Constructing the FFT performs the necessary set-up
-   operations.
-  </para>
-
-  <para>
-   Because VSIPL++ supports a variety of different kinds of FFT, FFTs
-   are themselves template classes.  The parameters to the template
-   allow you to indicate whether to perform a forward (time-domain to
-   frequency-domain) or inverse (frequency-domain to time-domain) FFT,
-   the type of the input and output data (i.e., whether complex or
-   real data is in use), and so forth.  Then, when constructing the FFT
-   objects, you indicate the size of the FFT.  In this case, you will
-   need both an ordinary FFT (to convert the replica data
-   from the time domain to the frequency domain) and a &quot;multiple
-   FFT&quot; to perform the FFTs on the rows of the matrix.   (A
-   multiple FFT performs the same FFT on each row or column of a 
-   matrix.)  So, the FFTs required are:
-  </para>
-
-  <programlisting><![CDATA[  // A forward Fft for computing the frequency-domain version of 
-  // the replica.
-  typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
-		for_fft_type;
-  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
-
-  // A forward Fftm for converting the time-domain data matrix to the
-  // frequency domain.
-  typedef Fftm<value_type, value_type, row, fft_fwd, by_reference>
-	  	for_fftm_type;
-  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
-
-  // An inverse Fftm for converting the frequency-domain data back to
-  // the time-domain.
-  typedef Fftm<value_type, value_type, row, fft_inv, by_reference>
-	  	inv_fftm_type;
-  inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange));]]></programlisting>
-
-  <para>
-   Before performing the actual convolution, you must convert the 
-   replica to the frequency domain using the FFT created above.  Because
-   the replica data is a property of the chirp, we only need to do
-   this once; even if our radar system runs for a long time, the
-   converted replica will always be the same.  VSIPL++ FFT
-   objects behave like functions, so you can just &quot;call&quot; the
-   FFT object:
-  </para>
-
-  <programlisting>  for_fft(replica);</programlisting>
-
-  <para>
-   Now, you are ready to perform the actual fast convolution
-   operation!  You will use the forward and inverse multiple-FFT
-   objects you've already created to go into and out of the frequency
-   domain.  While in the frequency domain, you will use the
-   <function>vmmul</function> operator to perform a 
-   vector-matrix multiply.  In particular, you will multiply each row
-   (dimension zero) of the frequency-domain matrix by the replica.
-   The <function>vmmul</function> operator is a template taking a
-   single parameter which indicates whether the multiplication should
-   be performed on rows or on columns.  So, the heart of the fast
-   convolution algorithm is just:
-  </para>
-
-  <programlisting><![CDATA[  // Convert to the frequency domain.
-  for_fftm(data, tmp);
-
-  // Perform element-wise multiply for each pulse.
-  tmp = vmmul<0>(replica, tmp);
-
-  // Convert back to the time domain.
-  inv_fftm(tmp, data);]]></programlisting>
-
-  <para>
-   A complete program listing is show below.  You can copy this
-   program directly into your editor and build it.  (You may notice
-   that there are a few things in the complete listing not discussed
-   above, including in particular, initialization of the library.)
-  </para>
-
-  <programlisting><xi:include href="src/par/fc1-serial.cpp" parse="text"/> </programlisting>
-
-  <para>
-   The following figure shows the performance in MFLOP/s of fast
-   convolution on a 3.06 GHz Pentium Xeon processor as the number of
-   range cells varies from 16 to 65536.
-  </para>
-
-  <mediaobject>
-    <imageobject>
-      <imagedata fileref="images/par/fastconv-serial.png" format="PNG" align="center"/>
-    </imageobject>
-  </mediaobject>
-
- </section>
-
  <section id="sec-parallel-fastconv">
   <title>Parallel Fast Convolution</title>
 
   <para>
-   The fast convolution program in the previous section makes use of
-   two implicitly parallel operators: <function>Fftm</function> and
+   The first fast convolution program in the previous chapter makes
+   use of two implicitly parallel operators: <function>Fftm</function> and
    <function>vmmul</function>.  These operators are implicity parallel
    in the sense that they process each row of the matrix
    independently.  If you had enough processors, you could put each
@@ -336,107 +150,18 @@
 
  </section>
 
- <section id="sec-serial-temporal-locality"> 
-  <title>Serial Optimization: Temporal Locality</title>
+ <section> 
+  <title>Improving Parallel Temporal Locality</title>
 
   <para>
-   Having successfully built a parallel implementation of fast
-   convolution, let's return to the single-processor case.  The code in
-   <xref linkend="sec-serial-fastconv"/>, does not take full advantage
-   of the cache.  In this section, you will learn how to improve the
-   performance of the application by improving <firstterm>temporal
-   locality</firstterm>, i.e., by making accesses to the same memory
-   locations occur near the same time.
+   In the previous chapter, you improved the performance of
+   the fast convolution program by exploiting temporary
+   cache locality to process data while it was &quot;hot&quot;
+   in the cache.  In this section, you will convert that
+   program to run efficiently in parallel.
   </para>
 
   <para>
-   The code in <xref linkend="sec-serial-fastconv"/> performs a FFT on
-   each row of the matrix.  Then, after all the rows have been
-   processed, it multiplies each row of the matrix by the
-   <varname>replica</varname>.  Suppose that there are a large number
-   of rows, so that <varname>data</varname> is too large to fit in
-   cache.  In that case, while the results of the first FFT will be in
-   cache immediately after the FFT is complete, that data will likey
-   have been purged from the cache by the time the vector-matrix
-   multiply needs the data.
-  </para>
-
-  <para>
-   Explicitly iterating over the rows of the matrix (performing a
-   forward FFT, elementwise multiplication, and an inverse FFT on each
-   row before going on to the next one) will improve temporal
-   locality.  You can use this approach by using an explicit loop,
-   rather than the implicit parallelism of <function>Fftm</function>
-   and <function>vmmul</function>, to take better advantage of the
-   cache.
-  </para>
-
-  <para>
-   You must make a few changes to the application in order to
-   implement this approach.  Because the application will be operating
-   on only a single row at a time, <function>Fftm</function> must be
-   replaced with the simpler <function>Fft</function>.  Similarly,
-   <function>vmmul</function> must be replaced with
-   <function>*</function>, which performs element-wise multiplication
-   of its operands.  Finally, <varname>tmp</varname> can now be a
-   vector, rather than a matrix.  (As a consequence, in addition to
-   being faster, this new version of the application will require less
-   memory.)  Here is the revised program:
-  </para>
-
-  <programlisting><![CDATA[  // Create the data cube.
-  Matrix<value_type> data(npulse, nrange);
-  Vector<value_type> tmp(nrange);            // tmp is now a vector
-
-  // Create the pulse replica
-  Vector<value_type> replica(nrange);
-
-  // Define the FFT typedefs.
-  typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
-		for_fft_type;
-  typedef Fft<const_Vector, value_type, value_type, fft_inv, by_reference>
-		inv_fft_type;
-
-  // Create the FFT objects.
-  for_fft_type  for_fft(Domain<1>(nrange), 1.0);
-  inv_fft_type  inv_fft(Domain<1>(nrange), 1.0/(nrange));
-
-  // Initialize data to zero
-  data    = value_type();
-  replica = value_type();
-
-  // Before fast convolution, convert the replica into the
-  // frequency domain
-  for_fft(replica);
-
-  // Perform fast convolution:
-  for (index_type r=0; r < nrange; ++r)
-  {
-    for_fft(data.row(r), tmp);
-    tmp *= replica;
-    inv_fft(tmp, data.row(r));
-  }]]></programlisting>
-
-  <para>
-   The following graph shows that the new &quot;interleaves&quot;
-   formulation is faster than the original &quot;phased&quot; approach
-   for large data sets.  For smaller data sets (where all of the data
-   fits in the cache anyhow), the original method is faster because
-   performing all of the FFTs at once is faster than performing them
-   one by one.
-  </para>
-
-  <mediaobject>
-    <imageobject>
-      <imagedata fileref="images/par/fastconv-cache.png" format="PNG" align="center"/>
-    </imageobject>
-  </mediaobject>
- </section>
-
- <section> 
-  <title>Improving Parallel Temporal Locality</title>
-
-  <para>
    If we apply maps (as in <xref linkend="sec-parallel-fastconv"/>),
    but do not adjust the algorithm in use, the code in <xref
    linkend="sec-serial-temporal-locality"/> will not run
@@ -611,6 +336,7 @@
   <para>
    The previous sections have ignored the acquisition of actual sensor
    data by setting the input data to zero.  This section shows how to
+   extend the I/O techniques introduced in the previous chapter to
    initialize <code>data</code> before performing the fast convolution.
   </para>
 
Index: doc/tutorial/serial.xml
===================================================================
--- doc/tutorial/serial.xml	(revision 0)
+++ doc/tutorial/serial.xml	(revision 0)
@@ -0,0 +1,531 @@
+<chapter id="chap-serial"
+         xmlns:xi="http://www.w3.org/2003/XInclude">
+ <title>Fast Convolution</title>
+
+ <chapterinfo>
+  <abstract>
+   <para>
+    This chapter describes how to create and run a serial VSIPL++
+    program with Sourcery VSIPL++ that performs fast convolution.
+    You can modify this program to develop your own serial applications.
+   </para>
+  </abstract>
+ </chapterinfo>
+
+ <para>
+  This chapter explains how to use Sourcery VSIPL++ to perform
+  <firstterm>fast convolution</firstterm> (a common signal-processing
+  kernel).  First, you will see how to compute fast convolution using
+  VSIPL++'s multiple FFT (Fftm) and vector-matrix multiply operations.
+  Then, you will learn how to optimize the performance of the
+  implementation.
+ </para>
+
+ <section id="sec-serial-fastconv">
+  <title>Fast Convolution</title>
+
+  <para>
+   Fast convolution is the technique of performing convolution in the
+   frequency domain.  In particular, the time-domain convolution
+   <mathphrase>f * g</mathphrase> can be computed as <mathphrase>F
+   . G</mathphrase>, where <mathphrase>F</mathphrase> and
+   <mathphrase>G</mathphrase> are the frequency-domain representations
+   of the signals <mathphrase>f</mathphrase> and
+   <mathphrase>g</mathphrase>.  A time-domain signal consisting of
+   <mathphrase>n</mathphrase> samples can be converted to a
+   frequency-domain signal in <mathphrase>O(n log n)</mathphrase>
+   operations by using a Fast Fourier Transform (FFT).  Substantially
+   fewer operations are required to perform the frequency-domain
+   operation <mathphrase>F . G</mathphrase> than are required to perform
+   the time-domain operation <mathphrase>f * g</mathphrase>.  Therefore,
+   performing convolutions in the frequency domain can be substantially
+   faster than performing the equivalent computations in the time
+   domain, even taking into account the cost of converting from the
+   time domain to the frequency domain.
+  </para>
+
+  <para>
+   One practical use of fast convolution is to perform the pulse
+   compression step in radar signal processing.  To increase the
+   effective bandwidth of a system, radars will transmit a frequency
+   modulated &quot;chirp&quot;.  By convolving the received signal with
+   the time-inverse of the chirp (called the &quot;replica&quot;), the
+   total energy returned from an object can be collapsed into a single
+   range cell.  Fast convolution is also useful in many other contexts
+   including sonar processing and software radio.
+  </para>
+
+  <para>
+   In this section, you will construct a program that performs fast
+   convolution on a set of time-domain signals stored in a matrix.
+   Each row of the matrix corresponds to a single signal, or
+   &quot;pulse&quot;.  The columns correspond to points in time.  So,
+   the entry at position (i, j) in the matrix indicates the amplitude
+   and phase of the signal received at time j for the ith pulse.
+  </para>
+  
+  <para>
+   The first step is to declare the data matrix, the vector that will
+   contain the replica signal, and a temporary matrix that will 
+   hold the results of the computation:
+  </para>
+
+  <programlisting><![CDATA[  // Parameters.
+  length_type npulse = 64;	// number of pulses
+  length_type nrange = 256;	// number of range cells
+
+  // Views.
+  typedef complex<float> value_type;
+  Vector<value_type> replica(nrange);
+  Matrix<value_type> data(npulse, nrange);
+  Matrix<value_type> tmp (npulse, nrange);]]></programlisting>
+
+  <para>
+   For now, it is most convenient to initialize the input data
+   to zero.  (In <xref linkend="sec-io-user-spec-storage"/>, you will learn how
+   to perform I/O operations so that you can populate the matrix with
+   real data.)
+  </para>
+
+  <para> 
+   In C++, you can use the constructor syntax <code>T()</code> to
+   perform &quot;default initialization&quot; of a type
+   <code>T()</code>.  The default value for any numeric type
+   (including complex numbers) is zero.  Therefore, the expression
+   <code>value_type()</code> indicates the complex number with zero as
+   both its real and imaginary components.  In the VSIPL++ API, when
+   you assign a scalar value to a view (a vector, matrix, or tensor),
+   all elements of the view are assigned the scalar value.  So, the
+   code below sets the contents of both the data matrix and replica
+   vector to zero:
+  </para>
+
+  <programlisting><![CDATA[  data    = value_type();
+  replica = value_type();]]></programlisting>
+
+  <para>
+   The next step is to define the FFTs that will be performed.
+   Typically (as in this example) an application performs multiple
+   FFTs on inputs with the same size.  Since performing an FFT
+   requires that some set-up be performed before performing the actual
+   FFT computation, it is more efficient to set up the FFT just once.
+   Therefore, in the VSIPL++ API, FFTs are objects, rather than
+   operators.  Constructing the FFT performs the necessary set-up
+   operations.
+  </para>
+
+  <para>
+   Because VSIPL++ supports a variety of different kinds of FFT, FFTs
+   are themselves template classes.  The parameters to the template
+   allow you to indicate whether to perform a forward (time-domain to
+   frequency-domain) or inverse (frequency-domain to time-domain) FFT,
+   the type of the input and output data (i.e., whether complex or
+   real data is in use), and so forth.  Then, when constructing the FFT
+   objects, you indicate the size of the FFT.  In this case, you will
+   need both an ordinary FFT (to convert the replica data
+   from the time domain to the frequency domain) and a &quot;multiple
+   FFT&quot; to perform the FFTs on the rows of the matrix.   (A
+   multiple FFT performs the same FFT on each row or column of a 
+   matrix.)  So, the FFTs required are:
+  </para>
+
+  <programlisting><![CDATA[  // A forward Fft for computing the frequency-domain version of 
+  // the replica.
+  typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
+		for_fft_type;
+  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
+
+  // A forward Fftm for converting the time-domain data matrix to the
+  // frequency domain.
+  typedef Fftm<value_type, value_type, row, fft_fwd, by_reference>
+	  	for_fftm_type;
+  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+
+  // An inverse Fftm for converting the frequency-domain data back to
+  // the time-domain.
+  typedef Fftm<value_type, value_type, row, fft_inv, by_reference>
+	  	inv_fftm_type;
+  inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange));]]></programlisting>
+
+  <para>
+   Before performing the actual convolution, you must convert the 
+   replica to the frequency domain using the FFT created above.  Because
+   the replica data is a property of the chirp, we only need to do
+   this once; even if our radar system runs for a long time, the
+   converted replica will always be the same.  VSIPL++ FFT
+   objects behave like functions, so you can just &quot;call&quot; the
+   FFT object:
+  </para>
+
+  <programlisting>  for_fft(replica);</programlisting>
+
+  <para>
+   Now, you are ready to perform the actual fast convolution
+   operation!  You will use the forward and inverse multiple-FFT
+   objects you've already created to go into and out of the frequency
+   domain.  While in the frequency domain, you will use the
+   <function>vmmul</function> operator to perform a 
+   vector-matrix multiply.  This will multiply each row
+   (dimension zero) of the frequency-domain matrix by the replica.
+   The <function>vmmul</function> operator is a template taking a
+   single parameter which indicates whether the multiplication should
+   be performed on rows or on columns.  So, the heart of the fast
+   convolution algorithm is just:
+  </para>
+
+  <programlisting><![CDATA[  // Convert to the frequency domain.
+  for_fftm(data, tmp);
+
+  // Perform element-wise multiply for each pulse.
+  tmp = vmmul<0>(replica, tmp);
+
+  // Convert back to the time domain.
+  inv_fftm(tmp, data);]]></programlisting>
+
+  <para>
+   A complete program listing is show below.  You can copy this
+   program directly into your editor and build it.  (You may notice
+   that there are a few things in the complete listing not discussed
+   above, including in particular, initialization of the library.)
+  </para>
+
+  <programlisting><xi:include href="src/par/fc1-serial.cpp" parse="text"/> </programlisting>
+
+  <para>
+   The following figure shows the performance in MFLOP/s of fast
+   convolution on a 3.06 GHz Pentium Xeon processor as the number of
+   range cells varies from 16 to 65536.
+  </para>
+
+  <mediaobject>
+    <imageobject>
+      <imagedata fileref="images/par/fastconv-serial.png" format="PNG" align="center"/>
+    </imageobject>
+  </mediaobject>
+
+ </section>
+
+ <section id="sec-serial-temporal-locality"> 
+  <title>Serial Optimization: Temporal Locality</title>
+
+  <para>
+   In this section, you will learn how to improve the performance of
+   fast convolution by improving <firstterm>temporal locality</firstterm>,
+   i.e., by making accesses to the same memory locations occur near the
+   same time.
+  </para>
+
+  <para>
+   The code in <xref linkend="sec-serial-fastconv"/> performs a FFT on
+   each row of the matrix.  Then, after all the rows have been
+   processed, it multiplies each row of the matrix by the
+   <varname>replica</varname>.  Suppose that there are a large number
+   of rows, so that <varname>data</varname> is too large to fit in
+   cache.  In that case, while the results of the first FFT will be in
+   cache immediately after the FFT is complete, that data will likey
+   have been purged from the cache by the time the vector-matrix
+   multiply needs the data.
+  </para>
+
+  <para>
+   Explicitly iterating over the rows of the matrix (performing a
+   forward FFT, elementwise multiplication, and an inverse FFT on each
+   row before going on to the next one) will improve temporal
+   locality.  You can use this approach by using an explicit loop,
+   rather than the implicit parallelism of <function>Fftm</function>
+   and <function>vmmul</function>, to take better advantage of the
+   cache.
+  </para>
+
+  <para>
+   You must make a few changes to the application in order to
+   implement this approach.  Because the application will be operating
+   on only a single row at a time, <function>Fftm</function> must be
+   replaced with the simpler <function>Fft</function>.  Similarly,
+   <function>vmmul</function> must be replaced with
+   <function>*</function>, which performs element-wise multiplication
+   of its operands.  Finally, <varname>tmp</varname> can now be a
+   vector, rather than a matrix.  (As a consequence, in addition to
+   being faster, this new version of the application will require less
+   memory.)  Here is the revised program:
+  </para>
+
+  <programlisting><![CDATA[  // Create the data cube.
+  Matrix<value_type> data(npulse, nrange);
+  Vector<value_type> tmp(nrange);            // tmp is now a vector
+
+  // Create the pulse replica
+  Vector<value_type> replica(nrange);
+
+  // Define the FFT typedefs.
+  typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
+		for_fft_type;
+  typedef Fft<const_Vector, value_type, value_type, fft_inv, by_reference>
+		inv_fft_type;
+
+  // Create the FFT objects.
+  for_fft_type  for_fft(Domain<1>(nrange), 1.0);
+  inv_fft_type  inv_fft(Domain<1>(nrange), 1.0/(nrange));
+
+  // Initialize data to zero
+  data    = value_type();
+  replica = value_type();
+
+  // Before fast convolution, convert the replica into the
+  // frequency domain
+  for_fft(replica);
+
+  // Perform fast convolution:
+  for (index_type r=0; r < nrange; ++r)
+  {
+    for_fft(data.row(r), tmp);
+    tmp *= replica;
+    inv_fft(tmp, data.row(r));
+  }]]></programlisting>
+
+  <para>
+   The following graph shows that the new &quot;interleaves&quot;
+   formulation is faster than the original &quot;phased&quot; approach
+   for large data sets.  For smaller data sets (where all of the data
+   fits in the cache anyhow), the original method is faster because
+   performing all of the FFTs at once is faster than performing them
+   one by one.
+  </para>
+
+  <mediaobject>
+    <imageobject>
+      <imagedata fileref="images/par/fastconv-cache.png" format="PNG" align="center"/>
+    </imageobject>
+  </mediaobject>
+ </section>
+
+ <section id="sec-io-user-spec-storage">
+  <title>Performing I/O with User-Specified Storage</title>
+
+  <para>
+   The previous sections have ignored the acquisition of actual sensor
+   data by setting the input data to zero.  This section shows how to
+   initialize <code>data</code> before performing the fast convolution.
+  </para>
+
+  <para>
+   To perform I/O with external routines (such as posix
+   <function>read</function> and <function>write</function>
+   it is necessary to obtain a pointer to data.
+   Sourcery VSIPL++ provides multiple ways to do this:
+   using <firstterm>user-defined storage</firstterm>, and
+   using <firstterm>external data access</firstterm>.
+   In this section you will use user-defined storage to
+   perform I/O.  Later, in <xref linked="sec-io-extdata"/> you
+   will see how to use external data access for I/O.
+  </para>
+
+  <para>
+   VSIPL++ allows you to create a block with user-specified
+   storage by giving VSIPL++ a pointer to previously allocated
+   data when the block is created.   This block is
+   just like a normal block, except that it now has two
+   states: &quot;admitted&quot; and &quot;released&quot;.
+   When the block is admitted, the data is owned by VSIPL++
+   and the block can be used with any VSIPL++ functions.
+   When the block is released, the data is owned by you
+   allowing you to perform operations directly on the
+   data.  The states allow VSIPL++ to potentially reorganize
+   data for higher performance while it is admitted.
+   (Attempting to use the pointer while the block is
+   admitted, or use the block while it is released
+   will result in unspecified behavior!)
+  </para>
+
+  <para>
+   The first step is to allocate the data manually.
+  </para>
+
+  <programlisting><![CDATA[  auto_ptr<value_type> data_ptr(new value_type[npulse*nrange]);]]></programlisting>
+
+  <para>
+   Next, you create a VSIPL++ <function>Dense</function>
+   block, providing it with the pointer.
+  </para>
+
+  <programlisting><![CDATA[  Dense<value_type, 2> data_block(Domain<2>(nrange, npulse), data_ptr.get());]]></programlisting>
+
+  <para>
+   Since the pointer to data does not encode the data dimensions, it
+   is necessary to create the block with explicit dimensions.
+  </para>
+
+  <para>
+   Finally, you create a VSIPL++ view that uses this block.
+  </para>
+
+  <programlisting><![CDATA[  Matrix<value_type> data(block);]]></programlisting>
+  <para>
+   The view determines its size from the block, so there is no need
+   to specify the dimensions again.
+  </para>
+
+  <para>
+   Now you're ready to perform I/O.  When a user-specifed storage block
+   is first created, it is released.
+  </para>
+
+  <programlisting><![CDATA[  ... setup IO ...
+  read(..., data_ptr, sizeof(value_type)*nrange*npulse);
+  ... check for errors (of course!) ...]]></programlisting>
+
+  <para>
+   Finally, you need to admit the block so that it and the view can
+   be used by VSIPL++.
+  </para>
+
+  <programlisting><![CDATA[  data.block().admit(true);]]></programlisting>
+
+  <para>
+   The <varname>true</varname> argument indicates that the data
+   values sould be preserved by the admit.  In cases where the
+   values do not need to preserved (such as admitting a block
+   after outout I/O has been performed and before the block will be
+   overwritten by new values in VSIPL++) you can use
+   <varname>false</varname> instead.
+  </para>
+
+  <para>
+   After admitting the block, you can use <varname>data</varname>
+   as before to perform fast convolution.  Here is the complete
+   program, including I/O to output the result after the computation.
+  </para>
+
+  <programlisting><xi:include href="src/ser/fc1-admit-release.cpp" parse="text"/> </programlisting>
+
+  <para>
+   The program also includes extra <function>release()</function>
+   and <function>admit()</function> calls before and after the input
+   and output I/O sections.  For this example, they are not strictly
+   necessary.  However they are good practice because they make it
+   clear in the program where the block is admitted and released.
+   They also make it easier to modify the program to process data
+   repeatedly in a loop, and to use separate buffers for input and
+   output data.  Because the extra calls have a <varname>false</varname>
+   update argument, they incur no overhead.
+  </para>
+
+ </section>
+
+ <section id="sec-io-extdata">
+  <title>Performing I/O with External Data Access</title>
+
+  <para>
+   In this section, you will use <firstterm>External Data
+   Access</firstterm> to get pointer to a block's data.
+   External data access allows a pointer to any block's
+   data to be taken, even if the block was not created with
+   user-specified storage (or if the block is not a <varname>Dense</varname>
+   block at all!)  This capability is useful in context where you
+   cannot control how a block is created.  To illustrate
+   this, you will create a utility routine for I/O that works
+   with any view passed as a parameter.
+  </para>
+
+  <para>
+   To access a block's data with external data access, you
+   create an <function>Ext_data</function> object. 
+  </para>
+
+  <programlisting><![CDATA[  Ext_data<block_type, layout_type> ext(block, SYNC_INOUT);]]></programlisting>
+
+  <para>
+   <function>Ext_data</function> is a class template that takes
+   template parameters to indicate the block type
+   <varname>block_type</varname> and the requested layout
+   <varname>layout_type</varname>.  The constructor takes
+   two parameters: the block being accessed, and the type of
+   syncing necessary.
+  </para>
+
+  <para>
+   The <varname>layout_type</varname> parameter is an
+   specialized <varname>Layout</varname> class template that
+   determines the layout of data that <function>Ext_data</function>
+   provides.  If no type is given,
+   the natural layout of the block is used.  However, in some
+   cases it is necessary to access the data in a certain way,
+   such as dense or row-major.
+  </para>
+
+  <para>
+   <varname>Layout</varname> class template takes 4 parameters to
+   indicate dimensionality, dimension-ordering, packing format,
+   and complex storage format (if complex).  In the example below
+   you will use the layout_type to request the data access to be dense,
+   row-major, with interleaved real and imaginar values if complex.
+   This will allow you to read data sequentially from a file.
+  </para>
+
+  <para>
+   The sync type is analgous to the update flags for
+   <function>admit()</function> and <function>release()</function>.
+
+   <varname>SYNC_IN</varname> indicates that the block and pointer
+   should be synchronized when the <function>Ext_data</function> object
+   is created (like <function>admit(true)</function>)
+
+   <varname>SYNC_OUT</varname> indicates that the block and pointer
+   should be synchronized when the <function>Ext_data</function> object
+   is destroyed (like <function>release(true)</function>)
+
+   <varname>SYNC_INOUT</varname> indicates that the block and pointer
+   should be syncrhonized at both points.
+  </para>
+
+  <para>
+   Once the object has been created, the pointer can be accessed
+   with the <function>data</function> method.
+  </para>
+
+  <programlisting><![CDATA[  value_type* ptr = ext.data();]]></programlisting>
+
+  <para>
+   The pointer provided is valid only during the life of the object.
+   Moreover, the block being accessed should not be used during that time.
+  </para>
+
+
+  <para>
+   Putting this together, you can create a routine to perform
+   I/O into a block.  This routine will take two arguments:
+   a filename to read, and a view to put the data into.
+   The amount of data read from the file will be determined by
+   the view's size.
+  </para>
+
+  <programlisting><![CDATA[  template <typename ViewT>
+  void
+  read_file(ViewT view, char* filename)
+  {
+    using vsip::impl::Ext_data;
+    using vsip::impl::Layout;
+    using vsip::impl::Stride_unit_dense;
+    using vsip::impl::Cmplx_inter_fmt;
+    using vsip::impl::Row_major;
+
+    dimension_type const dim = ViewT::dim;
+    typedef typename ViewT::block_type block_type;
+    typedef typename ViewT::value_type value_type;
+
+    typedef Layout<dim, typename Row_major<dim>::type,
+                   Stride_unit_dense, Cmplx_inter_fmt>
+		layout_type;
+
+    Ext_data<block_type, layout_policy>
+      ext(view.block(), SYNC_OUT);
+
+    ifstream ifs(filename);
+
+    ifs.read(reinterpret_cast<char*>(ext.data()),
+             view.size() * sizeof(value_type));
+  }]]></programlisting>
+
+ </section>
+
+</chapter>
