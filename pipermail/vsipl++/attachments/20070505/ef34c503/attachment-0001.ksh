Index: doc/tutorial/tutorial.xml
===================================================================
--- doc/tutorial/tutorial.xml	(revision 170271)
+++ doc/tutorial/tutorial.xml	(working copy)
@@ -71,12 +71,14 @@
       <literallayout>
         <xref linkend="chap-ref-api"/>
         <xref linkend="chap-profiling"/>
+        <xref linkend="chap-benchmarking"/>
         <xref linkend="glossary"/>
       </literallayout>
     </partintro>
 
     <xi:include href="api.xml" parse="xml"/>
     <xi:include href="profiling.xml" parse="xml"/>
+    <xi:include href="benchmarks.xml" parse="xml"/>
     <xi:include href="glossary.xml"/>
   </part>
 </book>
Index: doc/tutorial/benchmarks.xml
===================================================================
--- doc/tutorial/benchmarks.xml	(revision 0)
+++ doc/tutorial/benchmarks.xml	(revision 0)
@@ -0,0 +1,586 @@
+<chapter id="chap-benchmarking"
+	 xmlns:xi="http://www.w3.org/2003/XInclude">
+  <title>Benchmarking</title>
+
+  <chapterinfo>
+    <abstract>
+      <para>
+	This chapter describes how to build and run the Sourcery VSIPL++ 
+	benchmark suite in order to determine how the library performs
+	on a given platform.
+      </para>
+    </abstract>
+  </chapterinfo>
+
+  <para>
+    This chapter explains how to build and run the performance benchmarks
+    supplied with Sourcery VSIPL++.  It gives an overview of the 
+    benchmarks in the top-level directory, then goes into some detail
+    about the platform-specific and problem-specific benchmarks found
+    in the subdirectories therein.
+  </para>
+
+  <section id="sec-benchmarking-overview">
+    <title>Overview</title>
+
+    <para>
+      The following tables describe the different benchmarks
+      available currently.  They are organized by type of 
+      operation, to allow more easy cross-referencing with
+      the specification.
+
+<table xml:id="benchmark-descriptions" rowsep="0">
+  <title>Sourcery VSIPL++ Benchmark Descriptions</title>
+<tgroup cols="2">
+<thead>
+  <row>
+    <entry>Operation</entry>
+    <entry>Source File</entry>
+  </row>
+</thead>
+
+<tbody>
+  <row>
+    <entry>math, functions, elementwise - fused multiply add</entry>
+    <entry>vma.cpp</entry>
+  </row>
+  <row>
+    <entry>math, functions, elementwise - vector copy</entry>
+    <entry>copy.cpp</entry>
+  </row>
+  <row>
+    <entry>math, functions, elementwise - vector division</entry>
+    <entry>vdiv.cpp</entry>
+  </row>
+  <row>
+    <entry>math, functions, elementwise - vector magnitude squared</entry>
+    <entry>vmagsq.cpp</entry>
+  </row>
+  <row>
+    <entry>math, functions, elementwise - vector multiply</entry>
+    <entry>vmul.cpp</entry>
+  </row>
+  <row>
+    <entry>math, functions, elementwise - vector multiply, distributed</entry>
+    <entry>dist_vmul.cpp</entry>
+  </row>
+  <row>
+    <entry>math, functions, elementwise - vector multiply, parallel</entry>
+    <entry>vmul_par.cpp</entry>
+  </row>
+  <row>
+    <entry>math, functions, elementwise - vector multiply, using straight C code</entry>
+    <entry>vmul_c.cpp</entry>
+  </row>
+  <row>
+    <entry>math, functions, elementwise - vector-matrix multiply</entry>
+    <entry>vmmul.cpp</entry>
+  </row>
+
+  <row>
+    <entry>math, functions, reductions - maximum value</entry>
+    <entry>maxval.cpp</entry>
+  </row>
+  <row>
+    <entry>math, functions, reductions - sum of values</entry>
+    <entry>sumval.cpp</entry>
+  </row>
+  <row>
+    <entry>math, functions, reductions - sum of values, using SIMD</entry>
+    <entry>sumval_simd.cpp</entry>
+  </row>
+
+  <row>
+    <entry>math, matvec - matrix-matrix products</entry>
+    <entry>prod.cpp</entry>
+  </row>
+  <row>
+    <entry>math, matvec - matrix-matrix products, variations</entry>
+    <entry>prod_var.cpp</entry>
+  </row>
+  <row>
+    <entry>math, matvec - matrix copy, transpose</entry>
+    <entry>mcopy.cpp</entry>
+  </row>
+  <row>
+    <entry>math, matvec - vector dot product</entry>
+    <entry>dot.cpp</entry>
+  </row>
+
+  <row>
+    <entry>signal - convolution</entry>
+    <entry>conv.cpp</entry>
+  </row>
+  <row>
+    <entry>signal - correlation</entry>
+    <entry>corr.cpp</entry>
+  </row>
+  <row>
+    <entry>signal - fast convolution</entry>
+    <entry>fastconv.cpp</entry>
+  </row>
+  <row>
+    <entry>signal - Fast Fourier Transform</entry>
+    <entry>fft.cpp</entry>
+  </row>
+  <row>
+    <entry>signal - Fast Fourier Transform, multiple</entry>
+    <entry>fftm.cpp</entry>
+  </row>
+  <row>
+    <entry>signal - Finite Impulse Response filter</entry>
+    <entry>fir.cpp</entry>
+  </row>
+
+  <row>
+    <entry>view, vector, assign - memory write bandwidth</entry>
+    <entry>memwrite.cpp</entry>
+  </row>
+  <row>
+    <entry>view, vector, assign - memory write bandwidth, using SIMD</entry>
+    <entry>memwrite_simd.cpp</entry>
+  </row>
+</tbody>
+</tgroup>
+</table>
+    </para>
+
+    <para>
+      All of the above source files are located in 
+      <filename>share/benchmarks/</filename> in the top-level
+      install directory, or simply <filename>benchmarks/</filename>
+      if using the full source distribution.  Other system-specific
+      or library-specific benchmarks are contained in various
+      subdirectories of the main benchmarks directory.  Please
+      refer to the <filename>README</filename> files in those
+      subdirectories for more information.
+    </para>
+  </section>
+
+  <section id="sec-benchmarking-obtaining">
+    <title>Obtaining the Benchmarks</title>
+    
+    <para>
+      The performance benchmarks are built and are ready to 
+      run as soon as Sourcery VSIPL++ is installed.  However,
+      they may be rebuilt from source if desired.  This 
+      section explains what to do in either case.
+    </para>
+
+    <section>
+      <title>Binary Packages</title>
+      
+      <para>
+	If you installed Sourcery VSIPL++ from a binary package
+	(the most common case), then no additional steps are 
+	necessary -- the executable images may be found in the
+	<filename>benchmarks/</filename> subdirectory in
+	the top-level install directory.
+      </para>
+    </section>
+
+    <section>
+      <title>Source Packages</title>
+      
+      <para>
+	If you are using the full source package for Sourcery
+	VSIPL++, the benchmarks may be built simply by typing
+<screen>> make benchmarks
+</screen>
+        from the top-level
+	source directory (the one containing GNUMakefile and the 
+	<filename>benchmarks</filename> subdirectory).   
+      </para>
+
+      <para>
+	The makefile 
+	contains instructions to build only those benchmarks which 
+	are appropriate for a given system.  For example, on a 
+	system with Mercury SAL installed, it will build the ones 
+	under <filename>benchmarks/sal/</filename> as well as 
+	the ones in <filename>benchmarks/</filename>.
+      </para>
+
+      <para>
+	If you are making changes to one particular benchmark
+	and would like to rebuild just it, then provide the
+	executable name as the make target.  For example,
+	to rebuild the elementwise vector multiply benchmark
+	<filename>vmul</filename>, enter
+<screen>> make benchmarks/vmul
+</screen>
+      </para>
+    </section>
+
+    <section>
+      <title>Standalone</title>
+
+      <para>
+	If you wish to build only the benchmarks themselves, without
+	rebuilding the entire library, then you may use a stand-alone 
+	makefile provided for this purpose.  First, make a copy
+	of the benchmark sources from the 
+	<filename>share/benchmarks/</filename> subdirectory in
+	the top-level install directory, or simply copy the 
+	<filename>benchmarks/</filename> directory from the 
+	source tree.
+      </para>
+
+      <para>
+	To rebuild all benchmarks, enter the following command:
+<screen>> make -f make.standalone
+</screen>
+      </para>
+
+      <para>
+	To rebuild a certain benchmark, enter the target name
+	as well.  For example:
+<screen>> make -f make.standalone vmul
+</screen>
+      </para>
+
+      <section>
+	<title>Optmization Settings</title>
+	<para>
+	  In order to experiment with different optimization
+	  settings for the compiler when building the benchmarks,
+	  it may be helpful to know that the makefiles, 
+	  both in the source tree and stand-alone,
+	  use pkg-config to extract the appropriate build flags 
+	  for a given architecture and operating system.  
+	  As with most GNU Make projects, these are stored in 
+	  a variable named <literal>CXXFLAGS</literal>.  
+	  You may alter those values by editing the makefile 
+	  and specifying options after the ones extracted
+	  using pkg-config, or you may replace its value entirely
+	  with your own.  Before making changes, it may be 
+	  helpful to capture the output from a clean rebuild
+	  for later comparison.  Use this command or one
+	  similar to accomplish this:
+<screen>> make -f make.standalone clean
+> make -f make.standalone &amp;> build.log
+</screen>
+	</para>
+      </section>
+    </section>
+  </section>
+  
+  <section id="sec-benchmarking-running">
+    <title>Running Performance Tests</title>
+
+    <para> 
+      Benchmarks are invoked as follows:
+<screen>> <replaceable>benchmark</replaceable> <replaceable>-test-number</replaceable> <replaceable>[-option[ -option[ ...]]]</replaceable>
+</screen>
+      Test numbers are defined individually for each benchmark and 
+      represent various combinations of algorithms and parameters used
+      for a given performance measurement.  Valid test numbers begin
+      at one.  Most benchmarks utilize zero to display a list of 
+      valid tests numbers.  For example:
+<screen>> vmul -0
+vmul -- vector multiplication
+single-precision:
+Vector-Vector:
+-1 -- Vector&lt;        float &gt; * Vector&lt;        float &gt;
+-2 -- Vector&lt;complex&lt;float&gt;&gt; * Vector&lt;complex&lt;float&gt;&gt;
+-3 -- Vector&lt;complex&lt;float&gt;&gt; * Vector&lt;complex&lt;float&gt;&gt; (SPLIT)
+-4 -- Vector&lt;complex&lt;float&gt;&gt; * Vector&lt;complex&lt;float&gt;&gt; (INTER)
+-5 -- Vector&lt;        float &gt; * Vector&lt;complex&lt;float&gt;&gt;
+Scalar-Vector:
+-11 --                float   * Vector&lt;        float &gt;
+-12 --                float   * Vector&lt;complex&lt;float&gt;&gt;
+-13 --        complex&lt;float&gt;  * Vector&lt;complex&lt;float&gt;&gt;
+-14 -- t_svmul2
+-15 -- t_svmul2
+-15 -- t_svmul3
+-15 -- t_svmul4
+-21 -- t_vmul_dom1
+-22 -- t_vmul_dom1
+-31 -- t_vmul_ip1
+-32 -- t_vmul_ip1
+
+double-precision:
+(101-113)
+(131-132)
+> 
+</screen>   
+    </para>
+
+    <para>
+      While performance tests may be run simply by specifiying the 
+      test number, several options are provided making it possible
+      to control a variety of useful parameters.  These parameters
+      affect either the way the test is run or the type of output
+      provided in the results.  A summary of the most useful
+      options is provided below:
+    </para>
+
+    <para>
+      <variablelist>
+	<title>Controlling the range of problem sizes</title>
+
+	<varlistentry>
+	  <term><literal>-start <replaceable>M</replaceable></literal></term>
+	  <listitem> 
+	    <para>
+	      Sets the starting problem size to 2^<replaceable>M</replaceable>.
+	      Defaults to 2 (4 points).
+	    </para>
+	  </listitem> 
+	</varlistentry>
+	
+	<varlistentry>
+	  <term><literal>-stop <replaceable>M</replaceable></literal></term>
+	  <listitem> 
+	    <para>
+	      Sets the stopping problem size to 2^<replaceable>M</replaceable>.
+	      Defaults to 21 (2097152 points).
+	    </para>
+	  </listitem> 
+	</varlistentry>
+	
+      </variablelist>
+    </para>
+
+
+    <para>
+      <variablelist>
+	<title>Controlling the samples taken</title>
+
+	<varlistentry>
+	  <term><literal>-samples <replaceable>S</replaceable></literal></term>
+	  <listitem> 
+	    <para>
+	      Sets the number of samples taken to <replaceable>S</replaceable>.   
+	      Defaults to one.  When 
+	      <mathphrase>S <literal>&gt;</literal> 2</mathphrase>, the median value 
+	      is reported.
+	    </para>
+	  </listitem> 
+	</varlistentry>
+
+	<varlistentry>
+	  <term><literal>-ms <replaceable>time</replaceable></literal></term>
+	  <listitem> 
+	    <para>
+	      Sets the goal time that each measurement should take, 
+	      in hundredths-of-a-second.  Defaults to 25 (250 ms).
+	    </para>
+	  </listitem> 
+	</varlistentry>
+	
+      </variablelist>
+    </para>
+
+    <para>
+      <variablelist>
+	<title>Benchmark specific parameters</title>
+
+	<varlistentry>
+	  <term><literal>-param <replaceable>value</replaceable></literal></term>
+	  <listitem> 
+	    <para>
+	      Sets the user-specified parameter, where <replaceable>value</replaceable> 
+	      is used in some instances to override a default value of a
+	      parameter, such as the number of rows or columns in an input
+	      matrix for example.  The effect, if any, is dependent on 
+	      each individual benchmark.
+	    </para>
+	  </listitem> 
+	</varlistentry>
+	
+      </variablelist>
+    </para>
+
+    <para>
+      <variablelist>
+	<title>Reporting</title>
+
+	<varlistentry>
+	  <term><literal>-pts</literal></term>
+	  <listitem> 
+	    <para>
+	      Report millions of points per second (MPT/s).  This is the 
+	      default.
+	    </para>
+	  </listitem> 
+	</varlistentry>
+	
+	<varlistentry>
+	  <term><literal>-ops</literal></term>
+	  <listitem> 
+	    <para>
+	      Reports millions of operations per second (MOP/s).
+	    </para>
+	  </listitem> 
+	</varlistentry>
+	
+	<varlistentry>
+	  <term><literal>-iob</literal></term>
+	  <listitem> 
+	    <para>
+	      Reports millions of input/output operations per 
+	      second (MB/s) (by summing read and write iob_per_point).
+	    </para>
+	  </listitem> 
+	</varlistentry>
+	
+	<varlistentry>
+	  <term><literal>-all</literal></term>
+	  <listitem> 
+	    <para>
+	      Reports all three statistics: MPT/s, MOP/s, MB/s
+	    </para>
+	  </listitem> 
+	</varlistentry>
+	
+      </variablelist>
+    </para>
+  </section>
+
+  <section id="sec-benchmarking-output">
+    <title>Benchmark Output</title>
+    
+    <para>
+      The benchmark output depends on the command line options, but typically 
+      includes some meta information on the benchmark (name, ops/point, etc) 
+      and individual measurements for each problem size.
+    </para>
+    
+    <para>
+      The header information, denoted by lines begging with 
+      <quote><literal>#</literal></quote>, contains three important
+      factors that are used to convert timing data into other meaningful
+      units.  The number of floating point operations is shown as
+      <literal>ops_per_point</literal> and the number of reads or writes
+      to and from memory are shown as <literal>riob_per_point</literal>
+      and <literal>wiob_per_point</literal> respectively.
+    </para>
+
+    <para>
+      Following the header information are performance results.  Each 
+      line contains data for a certain problem size (number of points), 
+      which is given in the first column.
+    </para>
+
+    <para>
+      The second column contains the measured (or median) values calculated
+      from the timing measurements.  The default is in points-per-second
+      as indicated in the header under <quote>metric</quote>.  Alternatively,
+      the values are in units as requested with the -pts, -ops, -iob option.
+    </para>
+
+    <para>
+      In other cases, three columns of measurements follow the size given
+      in the first column.  The values listed vary depending on the options 
+      specified, as outlined below:
+
+      <variablelist>
+	<varlistentry>
+	  <term><literal>-all</literal></term>
+	  <listitem> 
+	    <para>
+	      Displays points per second, operations per second and 
+	      the sum of the memory reads and writes per second 
+	      (MPT/s, MOP/s, MB/s).
+	    </para>
+	  </listitem> 
+	</varlistentry>
+
+	<varlistentry>
+	  <term><literal>-pts</literal></term>
+	  <term><literal>-ops</literal></term>
+	  <term><literal>-iob</literal></term>
+	  <listitem> 
+	    <para>
+	      Displays one of points per second, operations per second and 
+	      the sum of the memory reads and writes per second, as requested.
+	    </para>
+	  </listitem> 
+	</varlistentry>
+
+	<varlistentry>
+	  <term><literal>-samples <replaceable>S</replaceable></literal></term>
+	  <listitem> 
+	    <para>
+	      With <literal>-all</literal>, three columns will be displayed,
+	      each containing the median value of the respective measurement.
+	      Without <literal>-all</literal>, the second column will contain 
+	      the median value and columns three and four will contain the 
+	      minimum and maximum value for the selected measurement.  Note: 
+	      <replaceable>S</replaceable> must be greater than two in order
+	      to display the minimum and maximum values for
+	      <literal>-pts</literal>, 
+	      <literal>-ops</literal> or 
+	      <literal>-iob</literal>.
+	    </para>
+	  </listitem> 
+	</varlistentry>
+      </variablelist>
+    </para>
+
+    <section>
+      <title>Examples</title>
+
+      <para>
+	This example shows a very simple benchmark for vector-vector 
+	multiplication using complex values, defaulting to units of
+	<quote>points-per-second</quote>:
+<screen>> vmul.exe -2
+# what             : t_vmul1
+# ops_per_point(1) : 6
+# riob_per_point(1): 16
+# wiob_per_point(1): 8
+# metric           : pts_per_sec
+# start_loop       : 2981969
+4 60.606903
+8 123.195221
+16 173.855408
+32 207.837997
+64 232.163071
+...
+</screen>
+        The output is truncated, but continues on up until 2^21 points
+	per vector.
+      </para>
+
+      <para>
+	To measure operations per second instead, use:
+<screen>> vmul.exe -2 -ops
+# what             : t_vmul1
+# ops_per_point(1) : 6
+# riob_per_point(1): 16
+# wiob_per_point(1): 8
+# metric           : ops_per_sec
+# start_loop       : 2973904
+4 377.566650
+8 765.744446
+16 1055.679321
+32 1261.269653
+64 1425.231567
+...
+</screen>
+      </para>
+
+      <para>
+	To measure ops/sec, with the median of 3 samples of 0.5 
+	seconds in duration each:
+<screen>> vmul.exe -2 -ops -samples 3 -ms 50
+# what             : t_vmul1
+# ops_per_point(1) : 6
+# riob_per_point(1): 16
+# wiob_per_point(1): 8
+# metric           : ops_per_sec
+# start_loop       : 5934442
+4 409.272583 398.208191 413.359711
+8 854.137939 811.087402 854.964539
+16 1132.262939 1087.544800 1137.489502
+32 1317.902710 1297.148560 1342.707886
+64 1483.941650 1453.872192 1501.823242
+</screen>
+        Note that this option is most often used when error
+        bars are desired for plotting the performance data.
+      </para>
+    </section>
+  </section>
+</chapter>
