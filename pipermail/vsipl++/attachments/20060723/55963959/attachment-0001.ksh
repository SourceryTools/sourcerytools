Index: doc/tutorial/performance.xml
===================================================================
--- doc/tutorial/performance.xml	(revision 0)
+++ doc/tutorial/performance.xml	(revision 0)
@@ -0,0 +1,258 @@
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
+<chapter xmlns:xi="http://www.w3.org/2003/XInclude">
+  <title>Performance</title>
+  <section id="library-profiling"><title>Library Profiling</title>
+    <para>
+      Sourcery VSIPL++ provides some features that help speed application 
+      development by helping you locate and quantify the expensive 
+      computations in your algorithm.  Built-in profiling capabilities, 
+      when enabled, provide timing data for many signal processing functions, 
+      such as FFT's, as well as common linear algebra computations like 
+      matrix multiplication and addition.  A full listing of functions 
+      covered is shown in the table below.
+    </para>
+    <para>
+      The profiler operates in two modes.  In 'trace' mode, the time spent in
+      each function is stored separately and presented in chronological order.
+      This mode is preferred when a highly detailed view of program execution
+      is desired.
+      In 'accumulate' mode, the times and opcounts are summed so that an 
+      average runtime and MFLOP/s for the function can be computed.  
+      This is desirable when investigating a specific function's performance.
+    </para>
+<table frame="none" rowsep="0"><title>Functions Profiled</title>
+<tgroup cols="2">
+<thead>
+<row>
+  <entry>Section</entry>
+  <entry>Object/Function</entry>
+</row>
+</thead>
+<tbody>
+<row>
+  <entry><code>signal</code></entry>
+  <entry>Convolution</entry>
+</row>
+<row>
+  <entry><code>signal</code></entry>
+  <entry>Correlation</entry>
+</row>
+<row>
+  <entry><code>signal</code></entry>
+  <entry>Fft</entry>
+</row>
+<row>
+  <entry><code>signal</code></entry>
+  <entry>Fir</entry>
+</row>
+<row>
+  <entry><code>signal</code></entry>
+  <entry>Iir</entry>
+</row>
+</tbody>
+</tgroup>
+</table>
+    <para>
+      See the file "profiling.txt" for a detailed explanation of the profiler
+      output for each of the functions above.
+    </para>
+    <section id="configuration"><title>Configuration Options</title>
+    <para>
+      A timer is required to obtain the profile data.  For profiling to be
+      useful, the timer should have high resolution and low overhead, such
+      as the Pentium and x86_64 time-stamp counters.
+      When building the library from source, you should enable a timer 
+      suitable for your particular platform along with the profiler 
+      itself.  These may be subsequently disabled for the production
+      version of the code without altering the source code.
+      For 64-bit Intel and AMD processors, use:
+      <screen>--enable-timer=x86_64_tsc</screen>
+      <screen>--enable-profiler</screen>
+      If you are using a binary package on either of these platforms, then
+      you need take no special steps, as the timer and profiler are already 
+      enabled for you.
+    </para>
+    </section>
+    <section id="accumulating-profile-data">
+      <title>Accumulating Profile Data</title>
+    <para>
+      Using this feature is very easy.  Simply pass the path to a log file 
+      to the constructor of the Profile object as follows:
+      <screen>Profile profile("/dev/stdout");</screen>
+      Profiled library functions will store timing data in memory while this 
+      object is in scope.  The profile data is written to the log file when 
+      the object is destroyed.  Note that for this reason, only one object 
+      of this type may be created at any given time.
+    </para>
+    <para>
+      The examples/ subdirectory provided with the source distribution 
+      demonstrates this profiling mode using a 2048-point forward FFT 
+      followed by an inverse FFT scaled by the length.
+      The profiler uses the timer to measure each FFT call and uses the 
+      size to compute an estimate of the performance.
+      For each unique event, the profiler outputs an indentifying tag, 
+      the accumulated time spent 'in scope' (in "ticks"), the number of times 
+      called, the total number of floating point operations performed per 
+      call and the computed performance in millions of flops per second.
+      The time value may be converted to seconds by dividing it by the
+      'clocks_per_second' constant.  
+    </para>
+    <programlisting><xi:include href="src/profile_fft1.txt" parse="text"/>
+    </programlisting>
+    <para>
+      This information is important in analyzing total processing requirements
+      for an algorithm.  However, care should be taken in interpreting the
+      results to ensure that they are representative of the intended 
+      application.
+      For example, in the above FFT the data will most likely not be 
+      resident in cache as it would be in some instances.  With a well
+      designed pipelined processing chain (typical of many embedded 
+      applications) the data will be in cache, yielding significantly 
+      better performance.  To obtain a good estimate of the in-cache 
+      peformance, place the FFT in a loop so that it is called many times.
+    </para>
+    <programlisting><xi:include href="src/profile_fft2.txt" parse="text"/>
+    </programlisting>
+    <para>
+      This is only a portion of the analysis that would be necessary to 
+      predict the performance of a real-world application.  Once you are 
+      able to accurately measure library performance, you may then extend 
+      that to profile your own application code, using the same features 
+      used internal to the library.
+    </para>
+    </section>
+    <section id="trace-profile-data"><title>Trace Profile Data</title>
+    <para>
+      This mode is used similarly to accumulate mode, except that an
+      extra parameter is passed to the creation of the Profile object.
+      <screen>Profile profile("/dev/stdout", pm_trace);</screen>
+      This mode is more important when investigating the execution sequence
+      of your program.  The profiler simply records each library call as a 
+      pair of events, allowing you to see where it entered and exited scope
+      in each case.  
+    </para>
+    <para>
+      Long traces can result when profiling in this mode, so be sure to 
+      avoid taking more data than you have memory to store (and have time
+      to process later).  The output is very similar to the output in 
+      accumulate mode.
+    </para>
+    <programlisting><xi:include href="src/profile_trace.txt" parse="text"/>
+    </programlisting>
+    <para>
+      For each event, the profiler outputs an event number, an indentifying
+      tag, and the current timestamp (in "ticks").  The next two fields 
+      differ depending on whether the event is coming into scope or out of 
+      scope.  When coming into scope, a zero is shown followed by the 
+      estimated count of floating point operations for that function.  
+      When exiting scope, the profiler displays the event number being 
+      closed followed by a zero.  In all cases, the timestamp (and 
+      intervals) may be converted to seconds by dividing by the 
+      'clocks_per_second' constant.  
+    </para>
+    </section>
+    <section id="performance-api"><title>Performance API</title>
+    <para>
+      An additional interface is provided for getting run-time profile data.
+      This allows you to selectively monitor the performance of a 
+      particular instance of a VSIPL class such as Fft, Convolution or
+      Correlation.
+    </para>
+    <para>
+      Classes with the Performance API built in contain a function
+      that takes a string parameter and returns single-precision 
+      floating point number.
+      This flexible interface allows you to obtain a variety of useful 
+      values all through a single function.
+    </para>
+    <para>
+      For example, given an Fft object named "fwd_fft", the following 
+      call shows how to obtain an estimate of the number of floating 
+      point operations per second performed.
+      <screen>float mflops = fwd_fft.impl_performance("mflops");</screen>
+    </para>
+    <para>
+      The table below lists the current types of information available.
+    </para>
+<table frame="none" rowsep="0"><title>Performance API Metrics</title>
+<tgroup cols="2">
+<thead>
+<row>
+  <entry>Parameter</entry>
+  <entry>Description</entry>
+</row>
+</thead>
+<tbody>
+<row>
+  <entry><code>mflops</code></entry>
+  <entry>performance in millions of floating point operations per second
+  </entry>
+</row>
+<row>
+  <entry><code>count</code></entry>
+  <entry>number of times invoked</entry>
+</row>
+<row>
+  <entry><code>time</code></entry>
+  <entry>total time spent performing the operation, in seconds</entry>
+</row>
+<row>
+  <entry><code>op_count</code></entry>
+  <entry>number of floating point operations per invocation</entry>
+</row>
+<row>
+  <entry><code>mbs</code></entry>
+  <entry>data rate in millions of bytes per second (not applicable in 
+  for all operations)</entry>
+</row>
+</tbody>
+</tgroup>
+</table>
+    </section>
+  </section>
+  <section id="application-profiling"><title>Application Profiling</title>
+    <para>
+      When knowing detailed run-time information regarding the library
+      functions used by your algorithm is not enough, you may want to
+      add profiling capabilities to some of your own code.  Here, we
+      introduce a new object, the Scope_event class, and show you how 
+      to use it in your application.
+    </para>
+    <para>
+      To create a Scope_event, simply call the constructor, passing it
+      the string that will become the event tag and, optionally, an integer
+      value expressing the number of floating point operations that will
+      be performed by the time the Scope_event object is destroyed.  For
+      example, to  measure the time taken to compute a simple running sum 
+      of squares over a C array:
+    </para>
+    <programlisting><xi:include href="src/profile_example.cpp" parse="text"/>
+    </programlisting>
+    <para>
+      This resulting profile data is identical in format to that used for
+      profiling library functions.
+    </para>
+    <programlisting><xi:include href="src/profile_output.txt" parse="text"/>
+    </programlisting>
+    <para>
+      Combining both application and library profiling is possible in either 
+      trace or accumulate modes.  
+      Performance events can be nested to help identify points of interest
+      in your program.  Events can be used to label different regions, such as 
+      "range processing" and "azimuth processing" for SAR.  When examining 
+      the trace output, profile events for library functions, such as FFTs, 
+      will be nested within profile events for application regions.
+    </para>
+  </section>
+</chapter>
Index: doc/tutorial/tutorial.xml
===================================================================
--- doc/tutorial/tutorial.xml	(revision 145639)
+++ doc/tutorial/tutorial.xml	(working copy)
@@ -17,21 +17,22 @@
  <!ENTITY specification
   "<ulink url=&#34;http://www.codesourcery.com/public/vsiplplusplus/specification-1.0.pdf&#34;
     >VSIPL++ API specification</ulink>">
- <!ENTITY version "0.9">
+ <!ENTITY version "1.1">
 ]>
 
 <book xmlns:xi="http://www.w3.org/2003/XInclude">
   <bookinfo>
     <title>Sourcery VSIPL++</title>
     <subtitle>Tutorial</subtitle>
-    <corpauthor>CodeSourcery, LLC</corpauthor>
-    <copyright><year>2005</year><holder>CodeSourcery, LLC</holder></copyright>
+    <corpauthor>CodeSourcery</corpauthor>
+    <copyright><year>2005, 2006</year><holder>CodeSourcery, LLC</holder></copyright>
 <!--  <legalnotice>&opl.xml;</legalnotice>-->
     <releaseinfo>Version &version;</releaseinfo>
   </bookinfo>
   <xi:include href="overview.xml" parse="xml"/>
   <xi:include href="api.xml" parse="xml"/>
-  <xi:include href="optimization.xml" parse="xml">
+  <xi:include href="optimization.xml" parse="xml"/>
+  <xi:include href="performance.xml" parse="xml">
     <xi:fallback><chapter><title>Optimizations...TBD</title></chapter></xi:fallback>
   </xi:include>
   <xi:include href="glossary.xml"/>
Index: doc/tutorial/src/profile_trace.txt
===================================================================
--- doc/tutorial/src/profile_trace.txt	(revision 0)
+++ doc/tutorial/src/profile_trace.txt	(revision 0)
@@ -0,0 +1,9 @@
+# mode: pm_trace
+# timer: x86_64_tsc_time
+# clocks_per_sec: 3591371008
+# 
+# index : tag : ticks : open id : op count
+1 : FFT Fwd 1D C-C by_val    2048x1 : 4688163420488244 : 0 : 112640
+2 : FFT Fwd 1D C-C by_val    2048x1 : 4688163420626385 : 1 : 0
+3 : FFT Inv 1D C-C by_val    2048x1 : 4688163420643116 : 0 : 112640
+4 : FFT Inv 1D C-C by_val    2048x1 : 4688163420830298 : 3 : 0
Index: doc/tutorial/src/profile_example.cpp
===================================================================
--- doc/tutorial/src/profile_example.cpp	(revision 0)
+++ doc/tutorial/src/profile_example.cpp	(revision 0)
@@ -0,0 +1,30 @@
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/impl/profile.hpp>
+
+using namespace vsip;
+using namespace impl;
+
+int
+main()
+{
+  vsipl init;
+
+  int data[1024];
+  for (int i = 0; i < 1024; ++i)
+    data[i] = i;
+
+  profile::Scope_enable scope("/dev/stdout" );
+
+  // This computation will be timed and included in the profiler output.
+  {
+    profile::Scope_event user_event("sum of squares", 2 * 1024);
+
+    int sum = 0;
+    for (int i = 0; i < 1024; ++i)
+      sum += data[i] * data[i];
+  }
+
+  return 0;
+}
+
Index: doc/tutorial/src/profile_fft1.txt
===================================================================
--- doc/tutorial/src/profile_fft1.txt	(revision 0)
+++ doc/tutorial/src/profile_fft1.txt	(revision 0)
@@ -0,0 +1,7 @@
+# mode: pm_accum
+# timer: x86_64_tsc_time
+# clocks_per_sec: 3591371008
+# 
+# tag : total ticks : num calls : op count : mflops
+Fwd FFT C-C by_val 2048x1 : 208089 : 1 : 112640 : 1944.03
+Inv FFT C-C by_val 2048x1 : 209736 : 1 : 112640 : 1928.77
Index: doc/tutorial/src/profile_output.txt
===================================================================
--- doc/tutorial/src/profile_output.txt	(revision 0)
+++ doc/tutorial/src/profile_output.txt	(revision 0)
@@ -0,0 +1,6 @@
+# mode: pm_accum
+# timer: x86_64_tsc_time
+# clocks_per_sec: 3591371008
+# 
+# tag : total ticks : num calls : op count : mflops
+sum of squares : 18153 : 1 : 2048 : 405.174
Index: doc/tutorial/src/profile_fft2.txt
===================================================================
--- doc/tutorial/src/profile_fft2.txt	(revision 0)
+++ doc/tutorial/src/profile_fft2.txt	(revision 0)
@@ -0,0 +1,6 @@
+# mode: pm_accum
+# timer: x86_64_tsc_time
+# clocks_per_sec: 3591371008
+# 
+# tag : total ticks : num calls : op count : mflops
+Fwd FFT C-C by_val 2048x1 : 6212808 : 100 : 112640 : 6511.26
