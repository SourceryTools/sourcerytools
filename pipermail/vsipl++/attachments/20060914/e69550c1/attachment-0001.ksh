Index: doc/tutorial/performance.xml
===================================================================
--- doc/tutorial/performance.xml	(revision 149092)
+++ doc/tutorial/performance.xml	(working copy)
@@ -13,7 +13,9 @@
 <chapter id="chap-performance"
          xmlns:xi="http://www.w3.org/2003/XInclude">
   <title>Performance</title>
-  <section id="library-profiling"><title>Library Profiling</title>
+
+
+  <section><title>Library Profiling</title>
     <para>
       Sourcery VSIPL++ provides library profiling features that speed
       application development by locating and quantifying the expensive
@@ -21,143 +23,351 @@
       These profiling capabilities provide timing data for signal processing
       functions (such as FFTs), linear algebra computations (such as matrix
       multiply), and elementwise expressions (such as vector addition).
-      When not required, profiling can be disabled at configure time, resulting
-      in no application overhead.
-      A full listing of functions covered is shown in the table below.
     </para>
     <para>
-      The profiler operates in two modes.  In 'trace' mode, the time spent in
-      each function is stored separately and presented in chronological order.
-      This mode is preferred when a highly detailed view of program execution
-      is desired.
-      In 'accumulate' mode, the times and opcounts are summed so that an 
-      average runtime and MFLOP/s for the function can be computed.  
-      This is desirable when investigating a specific function's performance.
+      Profiling is enabled by defining a macro when compiling and linking
+      your application.  For complete instructions, see 
+      <xref linkend="enabling"/> below.
+      A full listing of functions covered is shown in 
+      <xref linkend="supported_ops"/>.
     </para>
-<table frame="none" rowsep="0"><title>Areas Profiled</title>
+    <para>
+      The profiler operates in two modes.  If you want to know how  
+      particular types of computations (such as all FFTs of a given size) 
+      are performing, then you can use the "accumulate" mode.  In this 
+      mode, Sourcery VSIPL++ will keep track of the total amount of time 
+      spent performing the computation of interest and will report 
+      the average runtime and average MFLOP/s for that computation.  
+      In contrast, if you want complete information about all of the 
+      individual computations performed by your application, you can use 
+      "trace" mode.  In this mode, Sourcery VSIPL++ will produce a log 
+      showing the time used and MFLOP/s for each individual computation.
+    </para>
+    <para>
+      In addition to the accumulate and trace modes, which have pre-defined 
+      output formats, Sourcery VSIPL++ exposes a profiling API that you can 
+      use to gather data directly on individual objects, such as FFTs.  
+      If you need finer control of what operations are profiled, or if you 
+      want to record the profiling data in a custom format, you may wish to 
+      use this API directly.  See <xref linkend="performance_api"/> for
+      more details.
+    </para>
+<table xml:id="supported_ops" frame="none" rowsep="0">
+  <title>Operations Supporting Profiling</title>
 <tgroup cols="2">
 <thead>
 <row>
   <entry>Section</entry>
-  <entry>Objects/Functions</entry>
+  <entry>Operations</entry>
 </row>
 </thead>
 <tbody>
 <row>
   <entry>signal</entry>
-  <entry><code>Convolution, Correlation, Fft, Fir and Iir</code></entry>
+  <entry>Convolution, Correlation, Fft, Fir and Iir</entry>
 </row>
 <row>
   <entry>math.matvec</entry>
-  <entry><code>dot, dotcvj, trans, herm, kron, outer and gemp</code></entry>
+  <entry>dot, dotcvj, trans, herm, kron, outer, gemp, gems, cumsum and modulate</entry>
 </row>
+<row>
+  <entry>fns</entry>
+  <entry>1-D, 2-D and 3-D Loop Fusion, Copy, Transpose, Dense Block, SIMD and vendor libraries</entry>
+</row>
 </tbody>
 </tgroup>
 </table>
     <para>
+      See <xref linkend="profiler-output"/> for a detailed 
+      explanation of the profiler output for each of the functions above.
       See the file <filename>profiling.txt</filename> for a detailed 
       explanation of the profiler output for each of the functions above.
+      For information about how to configure the library for profiling, 
+      see the Quickstart also.
     </para>
-    <section id="configuration"><title>Configuration Options</title>
+
+    <section xml:id="enabling"><title>Enabling Profiling</title>
     <para>
-      Before using profiling, you need to configure the library with 
-      profiling enabled.
-      A high resolution and low overhead timer is also needed, 
-      such as the Pentium and x86_64 time-stamp counters.
-      When building the library from source, you should enable a timer 
-      suitable for your particular platform along with the profiler 
-      itself.  These may be subsequently disabled for the production
-      version of the code without altering the source code.
-      For 64-bit Intel and AMD processors, use:
-      <screen>--enable-timer=x86_64_tsc</screen>
-      <screen>--enable-profiler</screen>
-      If you are using a binary package on either of these platforms, then
-      you need take no special steps, as the timer and profiler are already 
-      enabled for you.
+      To enable profiling, define 
+      <option>-DVSIP_IMPL_PROFILER=<replaceable>mask</replaceable></option>
+      on the command line when compiling your program.  
+      On many systems, this option may be added to the CXXFLAGS variable 
+      in the project makefile.  
     </para>
+    <para>
+      Since profiling can introduce overhead, especially for element-wise
+      expressions, this macro allows you to choose which operations in the
+      library are profiled.  To profile all operations, use 
+      <option>-DVSIP_IMPL_PROFILER=15</option>.  
+      See <xref linkend="mask-values"/> for other possible values.
+    </para>
+    <note>
+      <para>
+	Profiling requires that the library be configured with a 
+	high-resolution timer.  Binary distributions of Sourcery 
+	VSIPL++ from CodeSourcery have an appropriate timer enabled.
+	If you are building Sourcery VSIPL++ from source, see the
+	Quickstart guide for more information about configuring 
+	high-resolution	timers.
+      </para>
+    </note>
     </section>
-    <section id="accumulating-profile-data">
-      <title>Accumulating Profile Data</title>
+
+    <section><title>Accumulating Profile Data</title>
     <para>
-      Using profiler's accumulate mode is easy.  Simply construct a
-      <code>Profile</code> object with the name of a log file as follows:
-      <screen>Profile profile("/dev/stdout", pm_accum);</screen>
-      Or, as <code>pm_accum</code> is the default mode:
-      <screen>Profile profile("/dev/stdout");</screen>
-      Profiled library functions will store timing data in memory while this 
-      object is in scope.  The profile data is written to the log file when 
-      the object is destroyed.  Note that for this reason, only one object 
-      of this type may be created at any given time.
+      To use the accumulate mode, you must declare a <code>Profile</code>
+      object.  Sourcery VSIPL++ will collect profiling data throughout 
+      its lifetime.  When the object goes out of scope, the data 
+      collected by profiling will be written to a log file.  For 
+      example, to profile your entire program, with all data written 
+      to the file <filename>profile.txt</filename>, you would add 
+      this line:
+
+<screen>Profile profile("profile.txt", pm_accum);</screen>
+
+      to the beginning of your <code>main</code> function, after 
+      initializing Sourcery VSIPL++.  Then, when the program exits, 
+      this object will go out of scope and profiling data will be 
+      written to the output file.  For this reason, only one object 
+      of this type may be in scope at any given time.
     </para>
     <para>
-      The <filename>examples/</filename> subdirectory provided with the 
-      source distribution demonstrates this profiling mode using a 2048-point 
-      forward FFT followed by an inverse FFT scaled by the length.
-      The profiler uses the timer to measure each FFT call and uses the 
-      size to compute an estimate of the performance.
-      For each unique event, the profiler outputs an indentifying tag, 
-      the accumulated time spent 'in scope' (in "ticks"), the number of times 
-      called, the total number of floating point operations performed per 
-      call and the computed performance in millions of flops per second.
-      The time value may be converted to seconds by dividing it by the
-      'clocks_per_second' constant.  
+      If you are profiling your entire program, you may specify options
+      on the command line that perform the equivalent of the above two steps:
+
+<screen>--vsipl++-profile-mode=accum --vsipl++-profile-output=profile.txt</screen>
     </para>
-    <programlisting><xi:include href="src/profile_fft1.txt" parse="text"/>
-    </programlisting>
     <para>
-      This information is important in analyzing total processing requirements
-      for an algorithm.  However, care should be taken in interpreting the
-      results to ensure that they are representative of the intended 
-      application.
-      For example, in the above FFT the data will most likely not be 
-      resident in cache as it would be in some instances.  With a well
-      designed pipelined processing chain (typical of many embedded 
-      applications) the data will be in cache, yielding significantly 
-      better performance.  To obtain a good estimate of the in-cache 
-      peformance, place the FFT in a loop so that it is called many times.
+      Using this technique on the example program <filename>fce-serial.cpp
+      </filename> from <xref linkend="sec-serial-fastconv"/>, the 
+      profiler gives following output:
     </para>
-    <programlisting><xi:include href="src/profile_fft2.txt" parse="text"/>
+    <programlisting><xi:include href="src/profile_accum.txt" parse="text"/>
     </programlisting>
     <para>
-      This is only a portion of the analysis that would be necessary to 
-      predict the performance of a real-world application.  Once you are 
-      able to accurately measure library performance, you may then extend 
-      that to profile your own application code, using the same features 
-      used internal to the library.
+      The log file contains a line corresponding to each computation 
+      (or "event").  The first column gives a name for the event.  The 
+      second column is the total amount of time spent in this operation 
+      in "ticks". (You can convert ticks to seconds by dividing by the 
+      value given by the "clocks_per_sec" value in the profiling header.)  
+      The third column indicates the number of times this operation was 
+      performed.  The fourth column indicates the number of mathematical 
+      operations performed during the computation.  (This is the number of 
+      operations required to perform the computation once, not the total. 
+      Multiply by the third column to obtain the total.)  The last column 
+      gives the achieved throughput for the computation in Millions of 
+      Operations per Seconds (MOP/s).
     </para>
+
+    <section><title>Analyzing Profile Data</title>
+    <para>
+      Having collected the data, you can use it to see how efficiently 
+      the program is using the available hardware.  Although the lines 
+      in the profiling output are sorted alphabetically, it is often 
+      more useful to consider the events in the order they occur in your 
+      program.  The following sections use this methodology to analyze 
+      the performance in the four phases of the fast-convolution 
+      computation.
+    </para>
+    <section><title>Setup</title>
+    <para>
+      The only computation performed in the setup phase is a forward FFT
+      that maps the pulse replica into the frequency domain.  This 
+      computation corresponds to the following line of the profiling 
+      data: 
+
+<screen>Fft Fwd C-C by_ref 256 : 142119 : 1 : 10240 : 258.767</screen>
+
+      The "Fft Fwd C-C by_ref 256" tag indicates that this computation 
+      is a 256-element forward FFT with complex, single-precision inputs 
+      and outputs, returning its result by reference.  The notation used 
+      for data types (e.g., "C-C" in this example) is given in
+      <xref linkend="data-type-names"/>.
+    </para>
     </section>
-    <section id="trace-profile-data"><title>Trace Profile Data</title>
+    <section><title>Convert to frequency domain</title>
     <para>
-      This mode is used similarly to accumulate mode, except that an
-      extra parameter is passed to the creation of the <code>Profile</code>
-      object.
-      <screen>Profile profile("/dev/stdout", pm_trace);</screen>
-      This mode is useful for investigating the execution sequence
-      of your program.  
-      The profiler simply records each library call as a pair of events, 
-      allowing you to see where it entered and exited scope in each case.  
+      The next step of the computation is to convert from the time domain 
+      to the frequency domain.  In particular, a FFT is applied to each 
+      pulse of a data cube, which consists of 64 pulses each containing 
+      256 range cells:
+
+<screen>Fftm Fwd C-C by_ref 64x256 : 1188144 : 1 : 1146880 : 3466.65</screen>
+
+      For this operation, a Fftm object was used to perform 
+      multiple FFTs on each row of the data cube.
     </para>
     <para>
-      Long traces can result when profiling in this mode, so be sure to 
-      avoid taking more data than you have memory to store (and have time
-      to process later).  The output is very similar to the output in 
-      accumulate mode.
+      Since the operation count (1.1 million) of the FFT (and inverse
+      FFT) outweigh the rest of the computation, the overall performance
+      will be very close to the FFT performance.
+      The performance measured was 3.5 GFLOPS/s on a 3.6 GHz Xeon.  
+      As the theoretical peak performance on such 
+      a machine is about 14.4 GFLOP/s, the program has achieved an 
+      a very good 24% of peak.
+      Other example programs measure in-cache FFT perfomance on vectors 
+      of the same size at 4.9 GFLOP/s.  Therefore, considering that the
+      3.5 GFLOP/s includes cache overheads, the result is still good.
     </para>
+    </section>
+    <section><title>Convolution</title>
+    <para>
+      The actual convolution consists of a vector-matrix multiplication.  
+      The corresponding profiling output is:
+
+<screen>Expr_Loop_Vmmul 2D vmmul(C,C) 64x256 : 1539531 : 1 : 98304 : 229.321</screen> 
+
+      Sourcery VSIPL++ chose to evaluate this expression by performing a 
+      row-wise vector-vector multiplication on each of the rows of the 
+      matrix.  Therefore, there is a second line:
+
+<screen>Expr_SIMD_VV-simd::vmul 1D *(C,C) 256 : 316674 : 64 : 1536 : 1114.86</screen> 
+
+      The tick count for the vector-matrix multiplication (vmmul) 
+      includes the time spent in the multiple row-wise scalar-vector 
+      multiplications.  Therefore the total number of time used by the 
+      program is <emphasis>not</emphasis> the sum of the tick counts 
+      given for each line.
+    </para>
+    <para>
+      The profiler tags for these expressions are <code>vmmul(C,C)</code> 
+      and <code>*(C,C)</code>.  All operations profiled are shown using 
+      a prefix notation; the operation performed is followed by the types 
+      of the arguments.  The "simd" tag indicates that VSIPL++ used 
+      the Single Instruction Multiple Data (SIMD) facilities on the 
+      Xeon architecture for maximum performance.
+    </para>
+    <para>
+      You should notice the performance difference between the vmmul 
+      event and the individual scalar-vector multiplications.  Some of 
+      this is due to the extra work vmmul does to setup each individual 
+      multiplication: loop overhead and subview creation.  However, most 
+      of this is due to the overhead of profiling: the cost of accessing 
+      timers and the cost of maintaining profile data structures.
+    </para>
+    <para>
+      In general, profiling overhead only slows the program execution but
+      does not affect the measurements taken.  However, when an operation
+      being profiled (such as vmmul) consists of many invocations of other
+      profiled operations (such as scalar-vector multiplication), all 
+      measurements except for the inner-most set of operations are 
+      affected.
+    </para>
+    <para>
+      With profiling disabled, the performance of vmmul is very close 
+      to the performance measured for the individual scalar-vector 
+      multiplications.
+    </para>
+    </section>
+    <section><title>Convert back to time domain</title>
+    <para>
+      The last step of the algorithm is to convert back to the time 
+      domain by using an inverse FFT.  The inverse FFT is 
+      computationally equivalent to the forward FFT, except that an 
+      additional multiplication is performed to handle scaling.  The 
+      lines corresponding to the inverse FFT are: 
+
+<screen>Expr_Dense 2D *(C,s) 64x256 : 687285 : 1 : 32768 : 171.228
+Expr_Loop 1D *(C,s) 16384 : 653265 : 1 : 32768 : 180.145
+Fftm Inv C-C by_ref 64x256 : 1559304 : 1 : 1146880 : 2641.48</screen> 
+
+      The first line describes a evaluation of a "dense" two-
+      dimensional multiplication between a single-precision complex 
+      view (a matrix) and a single-precision scalar.  Note that
+      scalars are represented using lower-case equivalents for
+      the data types in the table above.
+    </para>
+    <para>
+      A "dense" matrix is one in which the values are packed
+      tightly in memory with no intervening space between the rows
+      or columns.  Therefore, the two-dimensional multiplication can 
+      be thought of as a 1-dimensional multiplication of a long vector.
+      The evaluation of the 2-D operation includes the time required for 
+      the 1-D operation, together with a small amount of overhead.  
+      You can tell that this is the case as the time shown on the 
+      first line is slightly greater than the time shown on the second.
+      Both show the same number of operations because they are 
+      referring to the same calculation.
+    </para>
+    <para>
+      Similarly, the time required for the inverse FFT includes both the 
+      time spent actually computing the FFT as well as the time required 
+      for the scaling multiplication.  Because the multiplication is not 
+      included in the theoretical operation count, the MOP/s count shown 
+      is somewhat smaller than than for the forward FFT.
+    </para>
+    <para>
+      For FFTs, Sourcery VSIPL++ uses the commonly accepted theoretical
+      operation count of 5 N log2(N).  This includes the cost of scaling,
+      which may be folded in with final twiddle factors.  However, as this
+      example illustrates, not all FFT backends have this capability, as
+      a result scaled FFTs often have a MOP/s rate lower than non-scaled
+      FFTs.
+    </para>
+    </section>
+  </section>
+  <para>
+    The analysis presented in this section is only a portion of what
+    one would do to verify an algorithm is performing as desired.
+    Core routines utilizing techniques such as the fast convolution 
+    method comprise only a portion of larger programs whose 
+    performance is also of interest.
+    The profiling capabilities utilized here can be extended to cover
+    those areas of the application as well.  
+    See <xref linkend="application_profiling"/> for more details.
+  </para>
+  </section>
+
+  <section><title>Trace Profile Data</title>
+    <para>
+      In trace mode, the profiler records each library call as a pair
+      of events, allowing you to see where each call was made and 
+      when it returned. This provides two time stamps per call, showing 
+      not only which functions were executed, but how they were nested 
+      with respect to one another.  This mode is useful for investigating 
+      the execution sequence of your program.
+    </para>
+    <para>
+      To enable trace mode, construct the 'Profile' object with a 'pm_trace'
+      flag, as in this line:
+
+<screen>Profile profile("profile.txt", pm_trace);</screen>
+
+      Long traces can result when profiling in this mode, so be sure to
+      avoid gathering more data than you have memory to store (and have
+      time to process later).  The output is very similar to the output 
+      in accumulate mode.
+    </para>
+    <para>
+      Here is a sample of the output obtained by running the fast 
+      convolution example in trace mode, which can also be run with 
+      the options
+
+<screen>--vsipl++-profile-mode=trace --vsipl++-profile-output=profile.txt</screen>
+    </para>
     <programlisting><xi:include href="src/profile_trace.txt" parse="text"/>
     </programlisting>
     <para>
-      For each event, the profiler outputs an event number, an indentifying
-      tag, and the current timestamp (in "ticks").  The next two fields 
-      differ depending on whether the event is coming into scope or out of 
-      scope.  When coming into scope, a zero is shown followed by the 
-      estimated count of floating point operations for that function.  
-      When exiting scope, the profiler displays the event number being 
-      closed followed by a zero.  In all cases, the timestamp (and 
-      intervals) may be converted to seconds by dividing by the 
-      'clocks_per_second' constant in the log file header.  
+      For brevity, events for some of the 64 scalar-vector multiplies 
+      performed in the vmmul operation have been replaced with an 
+      ellipses.
     </para>
+    <para>
+      For each event, the Sourcery VSIPL++ outputs an event number, 
+      an indentifying tag, and the current timestamp (in "ticks").  
+      The next two fields differ depending on whether the event 
+      marks the entry point of a library function or its return.
+      At the start of a call, a zero is shown followed by the estimated 
+      count of floating point operations for that function.  When 
+      returning from a call, the profiler displays the event number 
+      created when the function was called, followed by a zero.
+      In all cases, the timestamp (and intervals) may be converted to 
+      seconds by dividing by the 'clocks_per_second' constant in the 
+      log file header.  
+    </para>
     </section>
-    <section id="performance-api"><title>Performance API</title>
+
+    <section xml:id="performance_api"><title>Performance API</title>
     <para>
       An additional interface is provided for getting run-time profile data.
       This allows you to selectively monitor the performance of a 
@@ -165,20 +375,23 @@
       Correlation.
     </para>
     <para>
-      Classes with the Performance API provide a function called
-      <code>impl_performance</code> that takes a string parameter and returns 
-      single-precision floating point number.
+      Classes instrumented the Performance API provide a function 
+      called <code>impl_performance</code> that takes a pointer to a 
+      constant character string and returns a single-precision floating 
+      point number.
     </para>
     <para>
       The following call shows how to obtain an estimate of the performance
       in number of operations per second:
 
-      <screen>float mops = fwd_fft.impl_performance("mops");</screen>
+<screen>float mops = fwd_fft.impl_performance("mops");</screen>
 
-      An "operation" will vary depending on the object and type of data
-      being processed.  For example, a single-precison Fft object will
-      return the number of single-precison floating-point operations
-      performed per second.
+      The definition of "operation" varies depending on the object 
+      and type of data being processed.  For example, a single-precison 
+      Fft object will return the number of single-precison 
+      floating-point operations performed per second while a complex 
+      double-precision FFT object will return the number of double-
+      precision floating-point operations performed per second.
     </para>
     <para>
       The table below lists the current types of information available.
@@ -219,37 +432,63 @@
 </table>
     </section>
   </section>
-  <section id="application-profiling"><title>Application Profiling</title>
+
+
+  <section xml:id="application_profiling">
+    <title>Application Profiling</title>
     <para>
-      The profiling mode provides an API that allows you to instrument
-      your own code.  Here we introduce a new object, the 
-      <code>Scope_event</code> class, and show you how to use it in your 
-      application.
+      Sourcery VSIPL++ provides an interface that allows you to 
+      instrument your own code with profiling events that will be 
+      included in the accumulate mode and trace mode output.
     </para>
     <para>
-      To create a <code>Scope_event</code>, simply call the constructor, passing 
-      it the string that will become the event tag and, optionally, an integer
-      value expressing the number of floating point operations that will
-      be performed by the time the <code>Scope_event</code> object is destroyed.  
-      For example, to  measure the time taken to compute a simple running sum 
-      of squares over a C array:
+      Profiling events are recorded by constructing a <code>Scope_event
+      </code>  object.  To create a <code>Scope_event</code>, call the 
+      constructor, passing it a <code>std::string</code> that will 
+      become the event tag and, optionally, an integer value expressing 
+      the number of floating point operations that will be performed by 
+      the time the object is destroyed.  
+      For example, to measure the time taken to compute the main portion 
+      in the fast convolution example, modify the source as follows:
     </para>
-    <programlisting><xi:include href="src/profile_example.cpp" parse="text"/>
-    </programlisting>
+<programlisting><xi:include href="src/profile_example.cpp" parse="text"/>
+</programlisting>
     <para>
+      The operation count passed as the second parameter is the 
+      sum of the two FFT's and the vector-matrix multiply.  
       This resulting profile data is identical in format to that used for
       profiling library functions.
     </para>
-    <programlisting><xi:include href="src/profile_output.txt" parse="text"/>
-    </programlisting>
+<programlisting><xi:include href="src/profile_output.txt" parse="text"/>
+</programlisting>
     <para>
+      Now the output has a new line that represents the time that
+      the <code>Scope_event</code> object exists, i.e. only while the
+      program executes the three main steps of the fast convolution.
+
+<screen>Fast Convolution : 4256109 : 1 : 2424832 : 2046.11</screen>
+    </para>
+    <para>
+      This technique can also be used to determine the overall 
+      performance of a critical piece of code, even if an accurate 
+      operation count is not known.  
+      By knowing the amount of time consumed when executing a section 
+      of code, you can quickly obtain the "latency" of the operation, 
+      and thereby determine the number of times the operation can be 
+      performed in a given unit of time.
+      This technique can be used to estimate the percent system 
+      utilization for single processor systems and/or determine the 
+      number of nodes needed in a multi-processor system.
+    </para>
+    <para>
       Combining both application and library profiling is possible in either 
       trace or accumulate modes.  
       Performance events can be nested to help identify points of interest
-      in your program.  Events can be used to label different regions, such as 
-      "range processing" and "azimuth processing" for SAR.  When examining 
-      the trace output, profile events for library functions, such as FFTs, 
-      will be nested within profile events for application regions.
+      in your program.  Events can be used to label different regions, 
+      such as the different steps in the fast convolution example.
+      When examining the trace output, profile events for library 
+      functions, such as FFTs, will be nested within profile events 
+      for application regions.
     </para>
   </section>
 </chapter>
Index: doc/tutorial/tutorial.xml
===================================================================
--- doc/tutorial/tutorial.xml	(revision 149092)
+++ doc/tutorial/tutorial.xml	(working copy)
@@ -66,11 +66,13 @@
 
       <literallayout>
         <xref linkend="chap-ref-api"/>
+        <xref linkend="chap-profiling"/>
         <xref linkend="glossary"/>
       </literallayout>
     </partintro>
 
     <xi:include href="api.xml" parse="xml"/>
+    <xi:include href="profiling.xml" parse="xml"/>
     <xi:include href="glossary.xml"/>
   </part>
 </book>
Index: doc/tutorial/src/profile_accum.txt
===================================================================
--- doc/tutorial/src/profile_accum.txt	(revision 0)
+++ doc/tutorial/src/profile_accum.txt	(revision 0)
@@ -0,0 +1,12 @@
+# mode: pm_accum
+# timer: x86_64_tsc_time
+# clocks_per_sec: 3591375104
+#
+# tag : total ticks : num calls : op count : mops
+Expr_Dense 2D *(C,s) 64x256 : 687285 : 1 : 32768 : 171.228
+Expr_Loop 1D *(C,s) 16384 : 653265 : 1 : 32768 : 180.145
+Expr_Loop_Vmmul 2D vmmul(C,C) 64x256 : 1539531 : 1 : 98304 : 229.321
+Expr_SIMD_VV-simd::vmul 1D *(C,C) 256 : 316674 : 64 : 1536 : 1114.86
+Fft Fwd C-C by_ref 256 : 142119 : 1 : 10240 : 258.767
+Fftm Fwd C-C by_ref 64x256 : 1188144 : 1 : 1146880 : 3466.65
+Fftm Inv C-C by_ref 64x256 : 1559304 : 1 : 1146880 : 2641.48
\ No newline at end of file
Index: doc/tutorial/src/profile_trace.txt
===================================================================
--- doc/tutorial/src/profile_trace.txt	(revision 149092)
+++ doc/tutorial/src/profile_trace.txt	(working copy)
@@ -1,9 +1,29 @@
 # mode: pm_trace
 # timer: x86_64_tsc_time
-# clocks_per_sec: 3591371008
-# 
+# clocks_per_sec: 3591375104
+#
 # index : tag : ticks : open id : op count
-1 : FFT Fwd 1D C-C by_val    2048x1 : 4688163420488244 : 0 : 112640
-2 : FFT Fwd 1D C-C by_val    2048x1 : 4688163420626385 : 1 : 0
-3 : FFT Inv 1D C-C by_val    2048x1 : 4688163420643116 : 0 : 112640
-4 : FFT Inv 1D C-C by_val    2048x1 : 4688163420830298 : 3 : 0
+1 : Fft Fwd C-C by_ref 256 : 2996724026993517 : 0 : 10240
+2 : Fft Fwd C-C by_ref 256 : 2996724027053115 : 1 : 0
+3 : Fast Convolution : 2996724027065535 : 0 : 2424832
+4 : Fftm Fwd C-C by_ref 64x256 : 2996724027068541 : 0 : 1146880
+5 : Fftm Fwd C-C by_ref 64x256 : 2996724028229361 : 4 : 0
+6 : Expr_Loop_Vmmul 2D vmmul(C,C) 64x256 : 2996724028324626 : 0 : 98304
+7 : Expr_SIMD_VV-simd::vmul 1D *(C,C) 256 : 2996724028378509 : 0 : 1536
+8 : Expr_SIMD_VV-simd::vmul 1D *(C,C) 256 : 2996724028384656 : 7 : 0
+9 : Expr_SIMD_VV-simd::vmul 1D *(C,C) 256 : 2996724028414761 : 0 : 1536
+10 : Expr_SIMD_VV-simd::vmul 1D *(C,C) 256 : 2996724028422465 : 9 : 0
+...
+130 : Expr_SIMD_VV-simd::vmul 1D *(C,C) 256 : 2996724029681025 : 129 : 0
+131 : Expr_SIMD_VV-simd::vmul 1D *(C,C) 256 : 2996724029698458 : 0 : 1536
+132 : Expr_SIMD_VV-simd::vmul 1D *(C,C) 256 : 2996724029701833 : 131 : 0
+133 : Expr_SIMD_VV-simd::vmul 1D *(C,C) 256 : 2996724029717412 : 0 : 1536
+134 : Expr_SIMD_VV-simd::vmul 1D *(C,C) 256 : 2996724029721111 : 133 : 0
+135 : Expr_Loop_Vmmul 2D vmmul(C,C) 64x256 : 2996724029722893 : 6 : 0
+136 : Fftm Inv C-C by_ref 64x256 : 2996724029724846 : 0 : 1146880
+137 : Expr_Dense 2D *(C,s) 64x256 : 2996724030603048 : 0 : 32768
+138 : Expr_Loop 1D *(C,s) 16384 : 2996724030622578 : 0 : 32768
+139 : Expr_Loop 1D *(C,s) 16384 : 2996724031260696 : 138 : 0
+140 : Expr_Dense 2D *(C,s) 64x256 : 2996724031262739 : 137 : 0
+141 : Fftm Inv C-C by_ref 64x256 : 2996724031264422 : 136 : 0
+142 : Fast Convolution : 2996724031265574 : 3 : 0
\ No newline at end of file
Index: doc/tutorial/src/profile_example.cpp
===================================================================
--- doc/tutorial/src/profile_example.cpp	(revision 149092)
+++ doc/tutorial/src/profile_example.cpp	(working copy)
@@ -1,30 +1,13 @@
-#include <vsip/initfin.hpp>
-#include <vsip/support.hpp>
-#include <vsip/impl/profile.hpp>
-
-using namespace vsip;
-using namespace impl;
-
-int
-main()
-{
-  vsipl init;
-
-  int data[1024];
-  for (int i = 0; i < 1024; ++i)
-    data[i] = i;
-
-  profile::Scope_enable scope("/dev/stdout" );
-
-  // This computation will be timed and included in the profiler output.
+  // Perform fast convolution:
   {
-    profile::Scope_event user_event("sum of squares", 2 * 1024);
+    impl::profile::Scope_event user_event("Fast Convolution", 2424832);
 
-    int sum = 0;
-    for (int i = 0; i < 1024; ++i)
-      sum += data[i] * data[i];
-  }
+    // 1) convert cube into frequency domain
+    for_fftm(data, tmp);
 
-  return 0;
-}
+    // 2) perform element-wise multiply
+    tmp = vmmul<0>(replica, tmp);
 
+    // 3) convert cube back into time domain
+    inv_fftm(tmp, data);
+  }
Index: doc/tutorial/src/profile_output.txt
===================================================================
--- doc/tutorial/src/profile_output.txt	(revision 149092)
+++ doc/tutorial/src/profile_output.txt	(working copy)
@@ -1,6 +1,13 @@
 # mode: pm_accum
 # timer: x86_64_tsc_time
-# clocks_per_sec: 3591371008
-# 
+# clocks_per_sec: 3591375104
+#
 # tag : total ticks : num calls : op count : mops
-sum of squares : 18153 : 1 : 2048 : 405.174
+Expr_Dense 2D *(C,s) 64x256 : 669627 : 1 : 32768 : 175.743
+Expr_Loop 1D *(C,s) 16384 : 637974 : 1 : 32768 : 184.462
+Expr_Loop_Vmmul 2D vmmul(C,C) 64x256 : 1470033 : 1 : 98304 : 240.162
+Expr_SIMD_VV-simd::vmul 1D *(C,C) 256 : 332109 : 64 : 1536 : 1063.04
+Fast Convolution : 4256109 : 1 : 2424832 : 2046.11
+Fft Fwd C-C 256 : 81261 : 1 : 10240 : 452.562
+Fftm Fwd C-C 64x256 : 1152891 : 1 : 1146880 : 3572.65
+Fftm Inv C-C 64x256 : 1535049 : 1 : 1146880 : 2683.22
\ No newline at end of file
Index: doc/tutorial/src/profile_fft1.txt
===================================================================
--- doc/tutorial/src/profile_fft1.txt	(revision 149092)
+++ doc/tutorial/src/profile_fft1.txt	(working copy)
@@ -1,7 +0,0 @@
-# mode: pm_accum
-# timer: x86_64_tsc_time
-# clocks_per_sec: 3591371008
-# 
-# tag : total ticks : num calls : op count : mops
-Fwd FFT C-C by_val 2048x1 : 208089 : 1 : 112640 : 1944.03
-Inv FFT C-C by_val 2048x1 : 209736 : 1 : 112640 : 1928.77
Index: doc/tutorial/src/profile_fft2.txt
===================================================================
--- doc/tutorial/src/profile_fft2.txt	(revision 149092)
+++ doc/tutorial/src/profile_fft2.txt	(working copy)
@@ -1,6 +0,0 @@
-# mode: pm_accum
-# timer: x86_64_tsc_time
-# clocks_per_sec: 3591371008
-# 
-# tag : total ticks : num calls : op count : mops
-Fwd FFT C-C by_val 2048x1 : 6212808 : 100 : 112640 : 6511.26
Index: doc/tutorial/profiling.xml
===================================================================
--- doc/tutorial/profiling.xml	(revision 0)
+++ doc/tutorial/profiling.xml	(revision 0)
@@ -0,0 +1,499 @@
+<?xml version="1.0"?>
+<!--
+
+ Tutorial for Sourcery VSIPL++.
+
+-->  
+
+<!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook XML V4.2//EN"
+                       "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd"
+[
+ <!ENTITY vsiplxx "VSIPL++">
+]>
+<chapter id="chap-profiling"
+         xmlns:xi="http://www.w3.org/2003/XInclude">
+  <title>Profiling</title>
+  <para>
+    This reference explains how to compile a program with profiling
+    statements enabled, how to use the profiling functions in order
+    to investigate the execution timing of a program and finally how
+    to interprete the resulting profile data.
+  </para>
+  <section id="Enabling Profiling"><title>Enabling Profiling</title>
+  <section id="compile-options">
+    <title>Configure and Compile Options</title>
+    <para>
+      There are no configure options for profiling, instead it is enabled
+      via compile-time options.  However, to use profiling it is necessary
+      to configure the library with a suitable high-resolution timer (refer
+      to the Quickstart for details on this and other configuration options).
+      For example,
+<screen>--enable-timer=x86_64_tsc</screen>
+      Pre-built versions of the library enable a suitable timer 
+      for your system.
+    </para>
+    <para>
+      To enable profiling, define <option>VSIP_IMPL_PROFILER=
+      <replaceable>mask</replaceable></option> on the command line 
+      when compiling your program.  On many systems, this option may 
+      be added to the CXXFLAGS variable in the project makefile.
+    </para>
+    <para>
+      This macro enables profiling operations in several different 
+      areas of the library, depending on the value of 
+      <replaceable>mask</replaceable>.
+    </para>
+<table xml:id="mask-values" frame="none" rowsep="0">
+  <title>Profiling Configuration Mask</title>
+<tgroup cols="3">
+<thead>
+<row>
+  <entry>Section</entry>
+  <entry>Description</entry>
+  <entry>Value</entry>
+</row>
+</thead>
+<tbody>
+<row>
+  <entry>signal</entry>
+  <entry>Signal Processing</entry>
+  <entry>1</entry>
+</row>
+<row>
+  <entry>matvec</entry>
+  <entry>Linear Algbra</entry>
+  <entry>2</entry>
+</row>
+<row>
+  <entry>fns</entry>
+  <entry>Elementwise Functions</entry>
+  <entry>4</entry>
+</row>
+<row>
+  <entry>user</entry>
+  <entry>User-defined Operations</entry>
+  <entry>8</entry>
+</row>
+</tbody>
+</tgroup>
+</table>
+    <para>
+      Determine the mask value by summing the values listed in the table
+      for the areas you wish to profile.  For example, if you wish to
+      gather performance data on your own code as well as for FFT's,
+      you would enable 'user' and 'signal' from the table above.  The
+      value you would choose would be 1 + 8 = 9.
+    </para>
+  </section>
+  <section><title>Command Line Options</title>
+    <para>
+      For programs that have been compiled with profiling enabled, 
+      the profiling mode and output file can be controlled from the 
+      command line.  You may profile programs without modifying your
+      source files using this method.  
+      Use this to choose the profiler mode:
+<screen>--vsipl++-profile-mode=<replaceable>mode</replaceable></screen>
+      where <replaceable>mode</replaceable> is either <code>accum</code> 
+      or <code>trace</code>.
+    </para>
+    <para>
+      Specify the path to the log file for profile output using:
+<screen>--vsipl++-profile-output=/path/to/logfile</screen>
+      The second option defaults to the standard output on most 
+      systems, so it may be omitted if that is desireable.
+    </para>
+    <para>
+      The profiling command line options control profiling for the entire
+      program execution.  For finer grain control, such as enabling profiling
+      during a specific portion of the program, or to mix different profiling
+      modes, explicit profiling objects can be created.
+    </para>
+  </section>
+  </section>
+
+  <section><title>Using the Profiler</title>
+  <section><title>Profiling Objects</title>
+    <para>
+      The <code>Profile</code> object is used to enable profiling during 
+      the lifetime of the object.  When created, it takes arguments to 
+      indicate the output file and the profiling mode (trace or accumulate).  
+      When destroyed (i.e. goes out of scope or is explicitly deleted),
+      the profile data is written to the specified output file.  
+      For example:
+<screen>  impl::profile::Profile profile("profile.txt", impl::profile::accum)
+</screen>
+    </para>
+    <para>
+      During the lifetime of the Profile object, timing data is
+      stored through a simple interface provided by the 
+      <code>Scope_event</code> object.  These objects are used
+      to profile library operations for the different areas mentioned in 
+      <xref linkend="mask-values"/> above.  Any <code>Scope_event</code>
+      objects defined in user programs fall into the 'user' category
+      of events.
+    </para>
+    <para>
+      The declaration of an instance of this object starts a timer and 
+      when it is destroyed, the timer is stopped.  The timing data is 
+      subsequently reported when the <code>Profile</code> object is 
+      destroyed.  For example:
+<screen>  impl::profile::Scope_event event("Event Tag", op_count);</screen>
+      The first parameter is the tag that will be used to display the 
+      event's performance data in the log file
+      (<xref linkend="event-tags"/> describes the tags used 
+      internally by the library.)
+      The second parameter, <code>op_count</code>, is an optional
+      unsigned integer specifying an estimate of the total number 
+      of operations (floating point or otherwise) performed.  This is 
+      used by the profiler to compute the rate of computation.  
+      Without it, the profiler will still yield useful timing data, but
+      the average rate of computation will be shown as zero in the log.
+    </para>
+    <para>
+      Creating a Scope_event object on the stack is the easiest way
+      to control the region it will profile.  For example, from within
+      the body of a function (or as the entire function), use
+      this to define a region of interest:
+<programlisting><![CDATA[
+  {
+    impl::profile::Scope_event event("Main computation:");
+
+    // perform main computation
+    //
+    ...
+  }]]></programlisting>
+      The closing brace causes 'event' to go out of scope, logging
+      the amount of time spent doing the computation.  
+    </para>
+  </section>
+
+  <section><title>Profiler Modes</title>
+    <para>
+      In <code>trace</code> mode, the start and stop times where events begin 
+      and end are stored as profile data.  The log will present these 
+      events in chronological order.  This mode is preferred when a 
+      highly detailed view of program execution is desired.
+    </para>
+    <para>
+      In <code>accum</code> (accumlate) mode, the start and stop times are 
+      subtracted to compute the duration of an event and the cumulative 
+      sum of these durations are stored as profile data.  The log will 
+      indicate the total amount of time spent in each event.  This mode 
+      is desirable when investigating a specific function's average 
+      performance.
+    </para>
+  </section>
+  </section>
+
+
+  <section id="profiler-output"><title>Profiler Output</title>
+  <section><title>Log File Format</title>
+    <para>
+      The profiler outputs a small header at the beginning of each log file
+      which is the same accumulate and trace modes.  The data that follows
+      the header is different depending on the mode.  The header describes
+      the profiling mode used, the low-level timer used to measure clock 
+      ticks and the number of clock ticks per second.
+    </para>
+
+    <section><title>Accumulate mode</title>
+<screen><code># mode: pm_accum
+# timer: x86_64_tsc_time
+# clocks_per_sec: 3591375104
+#
+# tag : total ticks : num calls : op count : mops</code>
+</screen>
+      <para>
+	The respective columns that follow the header are:
+	<variablelist>
+	  <varlistentry>
+	    <term>tag</term>
+	    <listitem>
+	      <para>
+		A descriptive name of the operation.  This is either
+		a name used internally or specified by the user.
+	      </para>
+	    </listitem>
+	  </varlistentry>
+
+	  <varlistentry>
+	    <term>total ticks</term>
+	    <listitem>
+	      <para>
+		The duration of the event in processor ticks.
+	      </para>
+	    </listitem>
+	  </varlistentry>
+
+	  <varlistentry>
+	    <term>num calls</term>
+	    <listitem>
+	      <para>
+		The number of times the event occurred.
+	      </para>
+	    </listitem>
+	  </varlistentry>
+
+	  <varlistentry>
+	    <term>op count</term>
+	    <listitem>
+	      <para>
+		The number of operations performed per event.
+	      </para>
+	    </listitem>
+	  </varlistentry>
+
+	  <varlistentry>
+	    <term>mops</term>
+	    <listitem>
+	      <para>
+		The calculated performance figure in millions
+		of operations per second.
+<inlineequation>
+  <mathphrase>
+    (num_calls * op_count * 10<superscript>-6</superscript>) / 
+    (total_ticks / clocks_per_sec)
+  </mathphrase>
+</inlineequation>
+    	      </para>
+	    </listitem>
+	  </varlistentry>
+
+	</variablelist>
+      </para>
+    </section>
+    <section><title>Trace mode</title>
+<screen># mode: pm_trace
+# timer: x86_64_tsc_time
+# clocks_per_sec: 3591375104
+#
+# index : tag : ticks : open id : op count
+</screen>
+      <para>
+	The respective columns that follow the header are:
+	<variablelist>
+	  <varlistentry>
+	    <term>index</term>
+	    <listitem>
+	      <para>
+		The entry number, beginning at one.
+	      </para>
+	    </listitem>
+	  </varlistentry>
+
+	  <varlistentry>
+	    <term>tag</term>
+	    <listitem>
+	      <para>
+  		A descriptive name of the operation.  This is either
+		a name used internally or specified by the user.
+	      </para>
+	    </listitem>
+	  </varlistentry>
+
+	  <varlistentry>
+	    <term>ticks</term>
+	    <listitem>
+	      <para>
+		The current reading from the processor clock.
+	      </para>
+	    </listitem>
+	  </varlistentry>
+
+	  <varlistentry>
+	    <term>open id</term>
+	    <listitem>
+	      <para>
+		If zero, indicates the start of an event.
+		If non-zero, this indicates the end of an event and
+		refers to the index of corresponding start of the
+		event.
+	      </para>
+	    </listitem>
+	  </varlistentry>
+
+	  <varlistentry>
+	    <term>op count</term>
+	    <listitem>
+	      <para>
+		The number of operations performed per event, or
+		zero to indicate the end of an event.
+	      </para>
+	    </listitem>
+	  </varlistentry>
+	</variablelist>
+      </para>
+      <para>
+	Note that the timings expressed in 'ticks' may be 
+	converted to seconds by dividing by the 'clocks_per_second' 
+	constant in the header.
+      </para>
+    </section>
+  </section>
+
+  <section xml:id="event-tags"><title>Event Tags</title>
+    <para>
+      Sourcery VSIPL++ uses the following tags for profiling objects
+      and functions within the library.  These tags are readable text 
+      containing information that varies depending on the event.
+    </para>
+    <section><title>Signal Processing and Matrix Vector Operations</title>
+    <para>
+      These operations follow this general format:
+
+<screen>OPERATION [DIM] DATATYPE SIZE</screen>
+
+      OPERATION gives the object or function name, including direction
+      for FFTs.
+    </para>
+    <para> 
+      DIM is the number of dimensions (when needed).
+    </para>
+    <para> 
+      DATATYPE describes the data types involved in the operation. 
+      FFTs have two listed, describing both the input type as well
+      as the output type, which may be different.
+      See <xref linkend="data-type-names"/> below.
+    </para>
+    <para>
+      SIZE is expressed by giving the number of elements in 
+      each dimension.
+    </para>
+    <para>
+      The specific operations profiled at this time are:
+<simplelist>
+<member><code>Convolution [1D|2D] T <replaceable>SIZE</replaceable>
+</code></member>
+<member><code>Correlation [1D|2D] <replaceable>T</replaceable> 
+                                  <replaceable>SIZE</replaceable>
+</code></member>
+<member><code>Fft 1D [Inv|Fwd] 
+   <replaceable>I</replaceable>-<replaceable>O</replaceable> 
+                [by_ref|by_val] <replaceable>SIZE</replaceable>
+</code></member>
+<member><code>Fftm 2D [Inv|Fwd] 
+   <replaceable>I</replaceable>-<replaceable>O</replaceable> 
+                [by_ref|by_val] <replaceable>SIZE</replaceable>
+</code></member>
+<member><code>Fir <replaceable>T</replaceable> 
+                  <replaceable>SIZE</replaceable></code></member>
+<member><code>Iir <replaceable>T</replaceable> 
+                  <replaceable>SIZE</replaceable></code></member>
+<member><code>dot <replaceable>T</replaceable> 
+                  <replaceable>SIZE</replaceable></code></member>
+<member><code>cvjdot <replaceable>T</replaceable> 
+                     <replaceable>SIZE</replaceable></code></member>
+<member><code>trans <replaceable>T</replaceable> 
+                    <replaceable>SIZE</replaceable></code></member>
+<member><code>herm <replaceable>T</replaceable> 
+                   <replaceable>SIZE</replaceable></code></member>
+<member><code>kron <replaceable>T</replaceable> 
+                   <replaceable>SIZE_A</replaceable> 
+                   <replaceable>SIZE_B</replaceable></code></member>
+<member><code>outer <replaceable>T</replaceable> 
+                    <replaceable>SIZE</replaceable></code></member>
+<member><code>gemp <replaceable>T</replaceable> 
+                   <replaceable>SIZE</replaceable></code></member>
+<member><code>gems <replaceable>T</replaceable> 
+                   <replaceable>SIZE</replaceable></code></member>
+<member><code>cumsum <replaceable>T</replaceable> 
+                     <replaceable>SIZE</replaceable></code></member>
+<member><code>modulate <replaceable>T</replaceable> 
+                       <replaceable>SIZE</replaceable></code></member>
+</simplelist>
+    </para>
+    <para>
+      In all cases, data types <code>T, I and O</code> 
+      above are expressed using a notation similar to the 
+      BLAS/LAPACK convention as in the following table:
+    </para>
+<table xml:id="data-type-names" frame="none" rowsep="0">
+  <title>Data Type Names</title>
+<tgroup cols="3">
+<thead>
+<row>
+  <entry></entry>
+  <entry>Views</entry>
+  <entry>Scalars</entry>
+</row>
+</thead>
+<tbody>
+<row>
+  <entry>single precision real</entry>
+  <entry><code>S</code></entry>
+  <entry><code>s</code></entry>
+</row>
+<row>
+  <entry>single precision complex</entry>
+  <entry><code>C</code></entry>
+  <entry><code>c</code></entry>
+</row>
+<row>
+  <entry>double precision real</entry>
+  <entry><code>D</code></entry>
+  <entry><code>d</code></entry>
+</row>
+<row>
+  <entry>double precision complex</entry>
+  <entry><code>Z</code></entry>
+  <entry><code>z</code></entry>
+</row>
+</tbody>
+</tgroup>
+</table>
+    </section>
+
+    <section><title>Elementwise Functions</title>
+    <para>
+      Element-wise expression tags use a slightly different
+      format:
+    </para>
+<screen>EVALUATOR DIM EXPR SIZE</screen>
+    <para>
+      The EVALUATOR indicates which VSIPL++ evaluator was dispatched to
+      compute the expression.
+    </para>
+    <para>
+      DIM indicates the dimensionality of the expression.
+    </para>
+    <para>
+      EXPR is mnemonic of the expression shown using prefix
+      notation, i.e.
+<screen>operator(operand, ...)</screen>
+      Each operand may be the result of another computation, so expressions
+      are nested, the parenthesis determining the order of evaluation. 
+    </para>
+    <para>
+      SIZE is expressed by giving the number of elements in 
+      each dimension.
+    </para>
+    <para>
+      At this time, these evaluators are profiled:
+<simplelist>
+  <member><code>Expr_Loop</code>      - generic loop-fusion evaluator.
+  </member>
+  <member><code>Expr_SIMD_Loop</code> - SIMD loop-fusion evaluator.
+  </member>
+  <member><code>Expr_Copy</code>      - optimized data-copy evaluator.
+  </member>
+  <member><code>Expr_Trans</code>     - optimized matrix transpose evaluator.
+  </member>
+  <member><code>Expr_Dense</code>     - evaluator for dense, multi-
+  dimensional expressions.  Converts them into corresponding 1-dim 
+  expressions that are re-dispatched.</member>
+  <member><code>Expr_SAL_*</code>     - evaluators for dispatch to the SAL 
+  vendor math library.</member>
+  <member><code>Expr_IPP_*</code>     - evaluators for dispatch to the SAL 
+  vendor math library.</member>
+  <member><code>Expr_SIMD_*</code>    - evaluators for dispatch to the 
+  builtin SIMD routines (with the exception of Expr_SIMD_Loop, see above). 
+  </member>
+</simplelist>
+      For SAL, IPP and SIMD, the asterisk (*) denotes the specific 
+      function invoked.
+    </para>
+    </section>
+  </section>
+
+  </section>
+</chapter>
Index: doc/tutorial/serial.xml
===================================================================
--- doc/tutorial/serial.xml	(revision 149092)
+++ doc/tutorial/serial.xml	(working copy)
@@ -316,7 +316,7 @@
    using <firstterm>user-defined storage</firstterm>, and
    using <firstterm>external data access</firstterm>.
    In this section you will use user-defined storage to
-   perform I/O.  Later, in <xref linked="sec-io-extdata"/> you
+   perform I/O.  Later, in <xref linkend="sec-io-extdata"/> you
    will see how to use external data access for I/O.
   </para>
 
