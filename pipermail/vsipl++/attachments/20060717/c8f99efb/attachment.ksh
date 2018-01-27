Index: doc/tutorial/tutorial.xml
===================================================================
--- doc/tutorial/tutorial.xml	(revision 145047)
+++ doc/tutorial/tutorial.xml	(working copy)
@@ -31,6 +31,7 @@
   </bookinfo>
   <xi:include href="overview.xml" parse="xml"/>
   <xi:include href="api.xml" parse="xml"/>
+  <xi:include href="parallel.xml" parse="xml"/>
   <xi:include href="optimization.xml" parse="xml">
     <xi:fallback><chapter><title>Optimizations...TBD</title></chapter></xi:fallback>
   </xi:include>
Index: doc/tutorial/src/par/fc3-io.cpp
===================================================================
--- doc/tutorial/src/par/fc3-io.cpp	(revision 0)
+++ doc/tutorial/src/par/fc3-io.cpp	(revision 0)
@@ -0,0 +1,210 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    fc-with-io.cpp
+    @author  Jules Bergmann
+    @date    2005-10-31
+    @brief   VSIPL++ Library: Fast convolution example with IO.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/math.hpp>
+#include <vsip/map.hpp>
+#include <vsip/parallel.hpp>
+#include <vsip/impl/global_map.hpp>
+
+using namespace vsip;
+using namespace std;
+
+
+
+/***********************************************************************
+  Main Program
+***********************************************************************/
+
+template <typename       View,
+	  dimension_type Dim>
+View
+create_view_wstorage(
+  Domain<Dim> const&                         dom,
+  typename View::block_type::map_type const& map)
+{
+  typedef typename View::block_type block_type;
+  typedef typename View::value_type value_type;
+
+  block_type* block = new block_type(dom, (value_type*)0, map);
+  View view(*block);
+  // block->decrement_count();
+
+  if (map.subblock() != no_subblock)
+  {
+    size_t size = subblock_domain(view).size(); // * sizeof(value_type);
+    value_type* buffer =
+      static_cast<value_type*>(
+	vsip::impl::alloc_align(128, size*sizeof(value_type)));
+    block->rebind(buffer);
+  }
+
+  block->admit(false);
+
+  return view;
+}
+
+
+
+template <typename View>
+void
+cleanup_view_wstorage(View view)
+{
+  typedef typename View::value_type value_type;
+  value_type* ptr;
+
+  view.block().release(false, ptr);
+  view.block().rebind((value_type*)0);
+
+  if (ptr) vsip::impl::free_align((void*)ptr);
+}
+
+
+
+template <typename View>
+View
+create_view_wstorage(
+  length_type                                rows,
+  length_type                                cols,
+  typename View::block_type::map_type const& map)
+{
+  return create_view_wstorage<View>( Domain<2>(rows, cols), map);
+}
+
+
+
+template <typename View>
+View
+create_view_wstorage(
+  length_type                                size,
+  typename View::block_type::map_type const& map)
+{
+  return create_view_wstorage<View>( Domain<1>(size), map);
+}
+
+
+
+
+int
+main(int argc, char** argv)
+{
+  // Initialize the library.
+  vsipl vpp(argc, argv);
+
+  typedef complex<float> value_type;
+
+  typedef Map<Block_dist, Block_dist>               map_type;
+  typedef Dense<2, value_type, row2_type, map_type> block_type;
+  typedef Matrix<value_type, block_type>            view_type;
+
+  typedef Dense<1, value_type, row1_type, Global_map<1> > replica_block_type;
+  typedef Vector<value_type, replica_block_type>          replica_view_type;
+
+  typedef Dense<1, value_type, row1_type, Map<> >   replica_io_block_type;
+  typedef Vector<value_type, replica_io_block_type> replica_io_view_type;
+
+
+
+  // Data cube parameters.
+  length_type npulse = 64;	// number of pulses
+  length_type nrange = 256;	// number of range cells
+
+  processor_type np = num_processors();
+
+  Vector<processor_type> pvec_in(1);  pvec_in(0)  = 0;
+  Vector<processor_type> pvec_out(1); pvec_out(0) = np-1;
+
+  map_type map_in (pvec0, 1, 1);
+  map_type map_out(pvecN, 1, 1);
+  map_type row_map(np, 1);
+
+  // Create the data cube.
+  view_type data(npulse, nrange, row_map);
+  view_type tmp (npulse, nrange, row_map);
+
+  // Create the I/O data cubes.
+  view_type data_in (create_view_wstorage<view_type>(npulse, nrange, map_in));
+  view_type data_out(create_view_wstorage<view_type>(npulse, nrange, map_out));
+
+  // Create the pulse replica
+  replica_view_type    replica(nrange);
+  replica_io_view_type replica_in(
+    create_view_wstorage<replica_io_view_type>(nrange, map_in));
+
+  // Define the FFT typedefs.
+  typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
+		for_fft_type;
+  typedef Fftm<value_type, value_type, row, fft_fwd, by_reference>
+	  	for_fftm_type;
+  typedef Fftm<value_type, value_type, row, fft_inv, by_reference>
+	  	inv_fftm_type;
+
+  // Create the FFT objects.
+  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
+  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+  inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange*npulse));
+
+  // Perform input IO
+  if (map_in.subblock() != no_subblock)
+  {
+    data_in.block().release(false);
+    // ... perform IO ...
+    data_in.block().admit(true);
+
+    replica_in.block().release(false);
+    // ... perform IO ...
+    replica_in.block().admit(true);
+
+    data_in    = value_type();
+    replica_in = value_type();
+
+    // Before fast convolution, convert the replica into the
+    // frequency domain
+    for_fft(replica_in.local());
+  }
+
+  // Scatter data
+  data    = data_in;
+  replica = replica_in;
+
+
+  // Perform fast convolution:
+
+  // 1) convert cube into frequency domain
+  for_fftm(data, tmp);
+
+  // 2) perform element-wise multiply
+  tmp = vmmul<0>(replica, tmp);
+
+  // 3) convert cube back into time domain
+  inv_fftm(tmp, data);
+
+
+  // Scatter data
+  data_out = data;
+
+
+  // Perform output IO
+  if (map_out.subblock() != no_subblock)
+  {
+    data_out.block().release(true);
+    // ... perform IO ...
+    data_out.block().admit(false);
+  }
+
+  // Cleanup
+  cleanup_view_wstorage(data_in);
+  cleanup_view_wstorage(data_out);
+  cleanup_view_wstorage(replica_in);
+}
Index: doc/tutorial/src/par/fc2-fastconv-fragment.hpp
===================================================================
--- doc/tutorial/src/par/fc2-fastconv-fragment.hpp	(revision 0)
+++ doc/tutorial/src/par/fc2-fastconv-fragment.hpp	(revision 0)
@@ -0,0 +1,38 @@
+template <typename T>
+class Fast_convolution
+{
+  typedef Fft<const_Vector, T, T, fft_fwd, by_reference> for_fft_type;
+  typedef Fft<const_Vector, T, T, fft_inv, by_reference> inv_fft_type;
+
+public:
+  template <typename Block>
+  Fast_convolution(
+    Vector<T, Block> replica)
+    : replica_(replica.size()),
+      tmp_    (replica.size()),
+      for_fft_(Domain<1>(replica.size()), 1.0),
+      inv_fft_(Domain<1>(replica.size()), 1.0/replica.size())
+  {
+    replica_ = replica;
+  }
+
+  template <typename       Block1,
+	    typename       Block2,
+	    dimnesion_type Dim>
+  void operator()(
+    Vector<T, Block1> in,
+    Vector<T, Block2> out,
+    Index<Dim>        /*idx*/)
+  {
+    for_fft_(in, tmp_);
+    tmp_ *= replica_;
+    inv_fft_(tmp_, out);
+  }
+
+  // Member data.
+private:
+  Vector<T>    replica_;
+  Vector<T>    tmp_;
+  for_fft_type for_fft_;
+  inv_fft_type inv_fft_;
+};
Index: doc/tutorial/src/par/fc1-parallel.cpp
===================================================================
--- doc/tutorial/src/par/fc1-parallel.cpp	(revision 0)
+++ doc/tutorial/src/par/fc1-parallel.cpp	(revision 0)
@@ -0,0 +1,93 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    fc1-parallel.cpp
+    @author  Jules Bergmann
+    @date    2005-10-31
+    @brief   VSIPL++ Library: ...
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/math.hpp>
+#include <vsip/map.hpp>
+#include <vsip/impl/global_map.hpp>
+
+using namespace vsip;
+using namespace std;
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
+  typedef Map<Block_dist, Whole_dist>               map_type;
+  typedef Dense<2, value_type, row2_type, map_type> block_type;
+  typedef Matrix<value_type, block_type>            view_type;
+
+  typedef Dense<1, value_type, row1_type, Global_map<1> > replica_block_type;
+  typedef Vector<value_type, replica_block_type>          replica_view_type;
+
+
+  // Data cube parameters.
+  length_type npulse = 64;	// number of pulses
+  length_type nrange = 256;	// number of range cells
+
+  processor_type np = num_processors();
+
+  map_type map = map_type(Block_dist(np), Whole_dist());
+
+  // Create the data cube.
+  view_type data(npulse, nrange, map);
+  view_type tmp (npulse, nrange, map);
+
+  // Create the pulse replica
+  replica_view_type replica(nrange);
+
+  // Define the FFT typedefs.
+  typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
+		for_fft_type;
+  typedef Fftm<value_type, value_type, row, fft_fwd, by_reference>
+	  	for_fftm_type;
+  typedef Fftm<value_type, value_type, row, fft_inv, by_reference>
+	  	inv_fftm_type;
+
+  // Create the FFT objects.
+  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
+  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+  inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange*npulse));
+
+  // Initialize
+  data    = value_type();
+  replica = value_type();
+
+
+  // Before fast convolution, convert the replica into the
+  // frequency domain
+  // TODO // for_fft(replica);
+
+
+  // Perform fast convolution:
+
+  // 1) convert cube into frequency domain
+  for_fftm(data, tmp);
+
+  // 2) perform element-wise multiply
+  tmp = vmmul<0>(replica, tmp);
+
+  // 3) convert cube back into time domain
+  inv_fftm(tmp, data);
+}
Index: doc/tutorial/src/par/fc1-serial.cpp
===================================================================
--- doc/tutorial/src/par/fc1-serial.cpp	(revision 0)
+++ doc/tutorial/src/par/fc1-serial.cpp	(revision 0)
@@ -0,0 +1,80 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    fce-serial.cpp
+    @author  Jules Bergmann
+    @date    2005-10-25
+    @brief   VSIPL++ Library:
+    Parallel Howto: fast convolution example (serial version).
+*/
+
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
+using namespace std;
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
+  // Data cube parameters.
+  length_type npulse = 64;	// number of pulses
+  length_type nrange = 256;	// number of range cells
+
+  // Create the data cube.
+  Matrix<value_type> data(npulse, nrange);
+  Matrix<value_type> tmp(npulse, nrange);
+
+  // Create the pulse replica
+  Vector<value_type> replica(nrange);
+
+  // Define the FFT typedefs.
+  typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
+		for_fft_type;
+  typedef Fftm<value_type, value_type, row, fft_fwd, by_reference>
+	  	for_fftm_type;
+  typedef Fftm<value_type, value_type, row, fft_inv, by_reference>
+	  	inv_fftm_type;
+
+  // Create the FFT objects.
+  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
+  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+  inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange));
+
+  // Initialize data to zero
+  data    = value_type();
+  replica = value_type();
+
+
+  // Before fast convolution, convert the replica into the
+  // frequency domain
+  for_fft(replica);
+
+
+  // Perform fast convolution:
+
+  // 1) convert cube into frequency domain
+  for_fftm(data, tmp);
+
+  // 2) perform element-wise multiply
+  tmp = vmmul<0>(replica, tmp);
+
+  // 3) convert cube back into time domain
+  inv_fftm(tmp, data);
+}
Index: doc/tutorial/parallel.xml
===================================================================
--- doc/tutorial/parallel.xml	(revision 0)
+++ doc/tutorial/parallel.xml	(revision 0)
@@ -0,0 +1,723 @@
+<chapter id="chap-parallel-tutorial"
+         xmlns:xi="http://www.w3.org/2003/XInclude">
+ <title>Parallel Tutorial</title>
+
+ <chapterinfo>
+  <abstract>
+   <para>
+    This chapter describes how to create and run a parallel VSIPL++
+    program with Sourcery VSIPL++.  You can modify this program to
+    develop your own parallel applications.
+   </para>
+  </abstract>
+ </chapterinfo>
+
+ <para>
+  This chapter describes how to use VSIPL++ for data-parallel
+  computation.  Starting with a serial implementation of fast
+  convolution, a common signal processing kernel, we will show how
+  to parallelize the serial version, how to deal with explicit data
+  parallelism, and how to deal with I/O.
+ </para>
+
+ <para>
+  <emphasis>Fast convolution</emphasis> refers to the technique of
+  performing convolution in the frequency domain using the the relation
+  f * g = F . G, where F and G are the frequency domain representations
+  of signals f and g.  Because translation between the time and frequency
+  domains can be don in O(n log n) complex with the Fast Fourier
+  transform (FFT), for large kernel sizes frequency domain convolution
+  requires fewer operations than time domain convolution.  Moreover,
+  highly optimized FFT routines are available for many architectures.
+ </para>
+
+ <para>
+  One use of fast convolution in practice is the pulse compression
+  step in radar signal processing.  To increase the effective bandwidth of a
+  system, radars will transmit a frequency modulated "chirp".  By
+  convolving the received signal with the time-inverse of the chirp
+  (called the "replica"), the total energy returned from an object can be
+  collapsed into a single range cell.  Other uses of fast convolution
+  are be found in sonar processing, software radio, and so on.
+ </para>
+
+ <section>
+  <title>Serial Fast Convolution</title>
+
+  <para>
+   Let's start with a simple program that performs fast convolution
+   on a set of pulses stored in a data cube.
+  </para>
+
+  <para>
+   First, we need to initialize the library:
+  </para>
+
+  <programlisting>  vsipl vpp(argc, argv);</programlisting>
+
+  <para>
+   Next, we need to create data structures to hold our data cube
+   and the pulse replica:
+  </para>
+
+  <programlisting><![CDATA[  typedef complex<float> value_type;
+
+  // Data cube parameters.
+  length_type npulse = 64;	// number of pulses
+  length_type nrange = 256;	// number of range cells
+
+  // Create the data cube.
+  Matrix<value_type> data(npulse, nrange);
+  Matrix<value_type> tmp (npulse, nrange);
+
+  // Create the pulse replica
+  Vector<value_type> replica(nrange);]]></programlisting>
+
+  <para>
+   For now, we'll ignore how this data is initialized by setting
+   it to zero (but in later sections we will look at parallel IO).
+  </para>
+
+  <programlisting>  // Initialize data to zero
+  data    = value_type();
+  replica = value_type();</programlisting>
+
+  <para>
+   To process the data cube, we need to create signal processing objects
+   for the FFTs.
+  </para>
+
+  <programlisting><![CDATA[  // Define the FFT typedefs.
+  typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
+		for_fft_type;
+  typedef Fftm<value_type, value_type, row, fft_fwd, by_reference>
+	  	for_fftm_type;
+  typedef Fftm<value_type, value_type, row, fft_inv, by_reference>
+	  	inv_fftm_type;
+
+  // Create the FFT objects.
+  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
+  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+  inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange));]]></programlisting>
+
+  <para>
+   The final setup step before performing fast convolution is to
+   transform the replica into the frequency domain.  This is done
+   once outside of the main computation:
+  </para>
+
+  <programlisting>  for_fft(replica);</programlisting>
+
+  <para>
+   Now we can perform fast convolution by:
+    (1) transforming all pulses in <code>data</code> into the frequency
+        domain,
+    (2) performing an element-wise multiply against the frequency-domain
+        replica, and
+    (3) transforming all pulses back into the time domain.
+  </para>
+
+  <programlisting><![CDATA[  // 1) convert cube into frequency domain
+  for_fftm(data, tmp);
+
+  // 2) perform element-wise multiply
+  tmp = vmmul<0>(replica, tmp);
+
+  // 3) convert cube back into time domain
+  inv_fftm(tmp, data);]]></programlisting>
+
+  <para>
+   Putting this altogether, we have:
+  </para>
+
+  <programlisting><xi:include href="src/par/fc1-serial.cpp" parse="text"/> </programlisting>
+
+  <para>
+  </para>
+
+ </section>
+
+ <section>
+  <title>Parallel Fast Convolution</title>
+
+  <para>
+   The example fast convolution program has <emphasis>implicit</emphasis>.
+   parallelism.  The <code>Fftm</code> and <code>vmmul</code> operators
+   express multiple, independent operations that can be performed in
+   parallel on the data.  In this section we will use maps
+   to distributed data so these operations can be performed
+   in parallel.  Because there is no explicit <code>for</code>
+   loop, VSIPL++ will automatically execute the program in parallel.
+  </para>
+
+ <para>
+  The general recipe for parallelizing a VSIPL++ program is:
+
+   <itemizedlist>
+    <listitem>
+     <para>
+      Analyze the program to find available data parallelism,
+     </para>
+    </listitem>
+
+    <listitem>
+     <para>
+      Apply mappings to the program's data structures to distribute
+      data so that (a) these data parallel operations can be performed
+      in parallel and (b) communication overheads between successive
+      operations are minimized.
+     </para>
+    </listitem>
+
+    <listitem>
+     <para>
+      Finally, convert explicit data parallelism to either be
+      implicit, or use explicit local views.
+     </para>
+    </listitem>
+   </itemizedlist>
+  </para>
+
+  <para>
+   Applying this recipe to our program, first we see that both the
+   <code>Fftm</code> and <code>vmmul</code> operations are data
+   parallel.  The <code>Fftm</code>'s perform an FFT
+   operation each row of the matrix <code>data</code>.  The vector
+   matrix multiply performs a multiply on each element of
+   <code>data</code>.
+  </para>
+
+  <para>
+   Of the two operations, <code>Fftm</code> is coarser grain: for data
+   sizes that we'll be working with, it is efficient to keep
+   data within a row on the same processor so that one processor can
+   perform the entire FFT without communication.
+  </para>
+
+  <para>
+   Based on these requirements, a good mapping for <code>data</code>
+   distributes dimension 0 (rows) while keeping dimension 1 (columns)
+   together.  This places one or more row on each processor, allowing
+   multiple processors to compute in parallel.
+  </para>
+
+  <para>
+   We separate the map definition into two parts.  First, we create
+   a typedef for the type of the map.  This is used later when
+   modifying the block type of our data structures.  Second, we
+   create a map object of this type, passing as arguments the
+   number of subblocks to create in each dimension.  Since dimension
+   0 is distributed, we pass <code>num_processors()</code> so that
+   each processor has some portion:
+  </para>
+
+  <programlisting><![CDATA[  typedef Map<Block_dist, Whole_dist>               map_type;
+  map_type map = map_type(num_processors(), 1);]]></programlisting>
+
+  <para>
+   By distributing <code>data</code> in this way, we need a complete
+   copy of <code>replica</code> on each processor to perform the
+   <code>vmmul</code>. This is done with a <code>Replicated_map</code>.
+  </para>
+
+  <programlisting><![CDATA[  Replicated_map<1> replica_map;]]></programlisting>
+
+  <para>
+   To apply these maps to our data structures, we need to modify
+   the block type to reflect the map type:
+  </para>
+
+  <programlisting><![CDATA[  typedef Dense<2, value_type, row2_type, map_type> block_type;
+  typedef Matrix<value_type, block_type>            view_type;
+  view_type data(npulse, nrange, map);
+
+  typedef Dense<1, value_type, row1_type, Replicated_map<1> >
+                                                    replica_block_type;
+  typedef Vector<value_type, replica_block_type>    replica_view_type;
+  replica_view_type replica(nrange, replica_map);]]></programlisting>
+
+  <para>
+   The final step is to reformulate any explicit data parallelism.
+   Since all of the operations (<code>Fftm</code> and
+   <code>vmmul</code>) are implicitly data parallel, no action is necessary.
+   However, in the next section we will see how to deal with explicit
+   data parallelism.
+  </para>
+
+  <para>
+   Applying these maps, the program now looks like:
+  </para>
+
+  <programlisting><xi:include href="src/par/fc1-parallel.cpp" parse="text"/> </programlisting>
+
+  <para>FIXME: show parallel speedup</para>
+
+ </section>
+
+ <section> <title>Explicit Parallelism: Inner Loops Optimization</title>
+
+  <para>
+   In the previous example, we were able to perform fast convolution
+   using implicit data parallel operations <code>Fftm</code> and
+   <code>vmmul</code>.  However, in many situations it is necessary
+   to use explicit data parallel operations.  For example, if our
+   system had multiple channels, giving the data cube a third dimension,
+   we could no longer use <code>Fftm</code> and <code>vmmul</code>
+   because the VSIPL++ API does not provide versions for tensors.
+   Likewise, if we wanted to interleave the forward FFT, vector-multiply,
+   and inverse FFT operations on a row-by-row basis to improve
+   cache locality, we can no longer use the implicitly parallel
+   <code>Fftm</code> and <code>vmmul</code> operators.
+  </para>
+   
+  <para>
+   To illustrate how to parallelize programs with explicit loops,
+   let us start by modifying the example fast convolution to
+   improve cache locality.  We'll do this by replacing the
+   <code>Fftm</code> and <code>vmmul</code> operators with an
+   explicit loop that performs <code>Fft</code> and <code>*</code>
+   operations on a row-by-row basis:
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
+   This new formulation trades the potential efficiency advantage
+   of performing multiple FFTs at once for improved cache temporal
+   locality of processing each row at once.  In cases where
+   <code>data</code> is too large to fit into the cache, this can 
+   improve performance.  The following diagram shows
+   the performance of the original "phased" approach versus the new
+   "interleaved" approach.
+  </para>
+
+  <para>FIXME: graph fastconv -1 vs fastconv -5</para>
+
+  <para>
+   This formulation improves serial performance, but it is no
+   longer implicitly data parallel.  If we applied our mappings from
+   the previous section, the program would still produce the correct
+   output, but would not deliver the expected parallel speedup.
+   This happens because the <code>tmp</code> vector would be
+   owned by each processor.  Each processor would execute every
+   loop iteration, performing the first two operations.  Only
+   the processor owning row <code>i</code> would perform the
+   third operation. This results in unnecessary work and unnecessary
+   communications.
+  </para>
+
+  <section> <title>Explicit Local Views</title>
+
+   <para>
+    To handle explicit data parallelism is to use
+    local views.  This converts an explicit loop over distributed objects
+    into an explicit loop over local objects.
+   </para>
+
+   <para>
+    We start by converting the bounds of explicit loops from
+    global bounds to local bounds.  This is done by accessing the
+    local view of the global view:
+   </para>
+
+   <programlisting><![CDATA[  for (index_type l_r=0; l_r < data.local().size(0); ++l_r)
+  {
+    ..
+  }]]</programlisting>
+
+   <para>
+    Next we convert the computation to work on local views instead
+    of global views:
+   </para>
+
+   <programlisting><![CDATA[  for (index_type l_r=0; l_r < data.local().size(0); ++l_r)
+  {
+    for_fft(data.local().row(l_r), tmp);
+    tmp *= replica.local();
+    inv_fft(tmp, data.local().row(l_r));
+  }]]></programlisting>
+
+   <para>
+    Alternatively, if using the <code>local()</code> operator inline
+    is inconvenient, it is possible to create a variable holding the
+    local view:
+   </para>
+
+   <programlisting><![CDATA[  view_type::local_type     l_data    = data.local();
+  rep_view_type::local_type l_replica = replica.local();
+
+  for (index_type l_r=0; l_r < l_data.size(0); ++l_r)
+  {
+    for_fft(l_data.row(l_r), tmp);
+    tmp *= l_replica;
+    inv_fft(tmp, l_data.row(l_r));
+  }]]></programlisting>
+
+   <para>
+    Depending on the operations performed, these two formulations have
+    nearly identical performance.  In some cases the second
+    formulation may be slightly faster because it does not have
+    to check the maps to determine if a communication is necessary.
+   </para>
+
+   <para>
+    FIXME: compare performance
+   </para>
+
+  </section>
+
+  <section>
+   <title>Mapping between Local and Global Indices</title>
+
+   <para>
+    The transformation from explicit loops over global data to
+    explicit loops over local data also changes the loop indices
+    from global to local indices.  For the fast convolution example
+    this is not an issue since computation is not dependent on
+    the global row index.  However, in some cases the computation
+    is dependent on the global row index.  Let us consider a
+    modified pulse convolution that uses multiple convolution kernels.
+   </para>
+
+   <para>
+    Instead of a single kernel that is used for all pulses, let
+    us assume that we have <code>P</code> kernels (with <code>P</code>
+    less than the number of pulses in <code>cube</code>).  To
+    store these, we chance <code>replica</code> from a
+    <code>Vector</code> to a <code>Matrix</code>:
+   </para>
+
+   <programlisting><![CDATA[  Matrix<value_type> replica(P, nrange);]]></programlisting>
+
+   <para>
+    When performing fast convolution, we choose the <code>r % P</code>
+    kernel::
+   </para>
+
+   <programlisting><![CDATA[  // Perform fast convolution:
+  for (index_type r=0; r < nrange; ++r)
+  {
+    for_fft(data.row(r), tmp);
+    tmp *= replica.row(r % P);
+    inv_fft(tmp, data.row(r));
+  }]]></programlisting>
+
+   <para>
+    We convert this to use explicit local views as before.  We use
+    the <code>global_from_local_index</code> function to convert
+    a local index to a global index:
+   </para>
+
+   <programlisting><![CDATA[  // Perform fast convolution:
+  for (index_type l_r=0; l_r < data.local().size(0); ++l_r)
+  {
+    index_type g_r = global_from_local_index(data, 0, l_r);
+    for_fft(data.local().row(l_r), tmp);
+    tmp *= replica.row(g_r % P);
+    inv_fft(tmp, data.local().row(l_r));
+  }]]></programlisting>
+
+   <para>
+    <code>global_from_local_index()</code> takes three arguments.
+    First, the global view the conversion is being done for 
+    (<code>data</code> in our case).  Second, the dimension of the index
+    (<code>0</code> to indicate rows).  Finally, the local index
+    to be converted.
+   </para>
+
+   <para>
+    In this form, <code>global_from_local_index()</code> assumes that
+    the conversion is being done for the subblock owned by the local
+    processor.  Other forms exist that take a subblock argument so
+    that global indices on other processors can be determined.
+   </para>
+
+  </section>
+ </section>
+
+ <section> <title>Implicit Parallelism: Parallel Foreach</title>
+
+  <para>
+   An implicitly parallel alternative exists for  describing
+   the interleaved computation of forward FFT, vector-multiply, and 
+   inverse FFT necessary to get good temporal cache locality.
+  </para>
+
+  <para>
+   Since VSIPL++ cannot provide an infinite variety of data
+   parallel operators to anticipate every need (such as
+   Tensor Fftm or Fast_convolution_m operators), Sourcery VSIPL++
+   provides a parallel foreach operator that allows user
+   computations to be implicitly parallelized.
+  </para>
+
+  <para>
+   To use the parallel foreach operator, first we need to encapsulate
+   our computation as a <emphasis>Functor</emphasis>, or function
+   object.  A functor is an object that can be invoked like a
+   function (using the <code>operator()</code> method).  Because it
+   is an object, it can capture arguments necessary to customize its
+   operation.  This ability to capture arguments is used to pass
+   the replica.
+  </para>
+
+  <para>
+   Let's step through a functor for fast convolution.  First, we
+   declare a <code>Fast_convolution</code> template class.  The
+   template parameter <code>T</code> is used to indicate the value
+   type of the fast convolution computation (such as
+   <code><![CDATA[complex<float>]]></code>):
+  </para>
+
+  <programlisting><![CDATA[template <typename T>
+class Fast_convolution
+{]]></programlisting>
+
+  <para>
+   Next, we declare convenience typedefs for <code>Fast_convolution</code>'s
+   forward and inverse FFTs:
+  </para>
+
+  <programlisting><![CDATA[  typedef Fft<const_Vector, T, T, fft_fwd, by_reference> for_fft_type;
+  typedef Fft<const_Vector, T, T, fft_inv, by_reference> inv_fft_type;]]></programlisting>
+
+  <para>
+   Next, we define the constructor.  It takes the replica as an
+   argument, which is used to determine the length of the fast
+   convolution.  This is used to allocate storage for a copy of
+   the replica, a temporary vector, and the forward and inverse
+   FFTs:
+  </para>
+
+  <programlisting><![CDATA[public:
+  template <typename Block>
+  Fast_convolution(
+    Vector<T, Block> replica)
+    : replica_(replica.size()),
+      tmp_    (replica.size()),
+      for_fft_(Domain<1>(replica.size()), 1.0),
+      inv_fft_(Domain<1>(replica.size()), 1.0/replica.size())
+  {
+    replica_ = replica;
+  }]]></programlisting>
+
+  <para>
+   Next, we define the functor's <code>operator()</code> method.  This
+   will be invoked by the parallel foreach operator once for each row
+   of the data cube.  It performs a fast convolution on a single row:
+  </para>
+
+  <programlisting><![CDATA[  template <typename       Block1,
+            typename       Block2,
+            dimension_type Dim>
+  void operator()(
+    Vector<T, Block1> in,
+    Vector<T, Block2> out,
+    Index<Dim>        /*idx*/)
+  {
+    for_fft_(in, tmp_);
+    tmp_ *= replica_;
+    inv_fft_(tmp_, out);
+  }]]></programlisting>
+
+  <para>
+   Finally, we finish up the class definition with the member data.  We
+   need to store the replica, a temporary vector, and the FFT objects:
+  </para>
+
+  <programlisting><![CDATA[  // Member data.
+private:
+  Vector<T>    replica_;
+  Vector<T>    tmp_;
+  for_fft_type for_fft_;
+  inv_fft_type inv_fft_;
+};]]></programlisting>
+
+  <!-- <programlisting><xi:include href="src/par/fc2-fastconv-fragment.hpp" parse="text"/></programlisting> -->
+
+  <para>
+   To use the <code>Fast_convolution</code>class, we first instantiate an
+   object, passing it a copy of our replica.
+  </para>
+
+  <programlisting><![CDATA[  Fast_convolution<value_type> fconv(replica.local());]]></programlisting>
+
+  <para>
+   To perform fast convolution, we use <code>foreach_vector</code>
+   to apply the fast convolution functor to each row of <code>data</code>:
+  </para>
+
+  <programlisting><![CDATA[  foreach_vector<tuple<0, 1> >(fconv, data);]]></programlisting>
+
+  <para>
+   The resulting program is implicitly parallel.  Moreover, it
+   maintains the cache locality of the explicit version.
+  </para>
+
+  <para>
+   FIXME: Measure serial performance between fastconv -5 and -8.
+  </para>
+ </section>
+
+ <section>
+  <title>Performing I/O</title>
+
+  <para>
+   Up to now we have ignored the initialization of our data cube by
+   setting it to zero.  Now let us tackle IO by considering how
+   <code>data</code> is initialized before computation, and how
+   it used after computation.  We'll assume that IO is necessary
+   both to initialize <code>data</code> before computation, and
+   to send <code>data</code> onto the subsequent processing
+   step after.
+  </para>
+
+  <section> <title>Input I/O</title>
+
+  <para>
+   Let's start with the input half of the problem: performing
+   I/O on a single processor, then distributing the result to
+   other processors for computation.  First, we need to create
+   maps for the input IO processor <code>map_in</code> and 
+   the compute processors <code>map</code>.  We use
+  </para>
+
+  <para>
+   First we create maps for our input and output processors.
+   These will be used to create input and output views suitable for
+   IO.  Because we want to control the processors which these views
+   are mapped onto, we will use <code>Map</code>'s processor set argument
+   to control the processors for the input map.  We'll assume input IO is
+   done on processor 0 and computation is done on all processors:
+  </para>
+
+  <programlisting><![CDATA[  typedef Map<> map_type;
+
+  Vector<processor_type> pvec_in(1);  pvec_in(0)  = 0;
+
+  // Distribute input data by row across input processors (pvec_in.size())
+  map_type map_in (pvec_in,  pvec_in.size(),  1);
+
+  // Distribute computation across all processors:
+  map_type map    (np, 1);]]></programlisting>
+
+  <para>
+   Next, we use these maps to create input and compute views,
+   <code>data_in</code> and <code>data</code> respectively:
+  </para>
+
+  <programlisting><![CDATA[  view_type data_in(npulse, nrange, NULL, map);
+  view_type data   (npulse, nrange, map);]]></programlisting>
+
+  <para>
+   Note we've created <code>data_in</code> as a user-defined storage
+   block.  However, instead of allocating data first, we've created
+   the block with a <code>NULL</code> pointer.  This allows us to
+   query <code>data_in</code> 's size to determine how much memory to
+   allocate instead of trying to figure it out manually.  When
+   <code>data_in</code> is distributed across a single processor, this
+   size is easy to compute (it is <code>npulse * nrange</code>).
+   However, when <code>data_in</code> is distributed over multiple
+   processors, figuring out the size of the subblock on each processor
+   is more complicated.
+  </para>
+
+  <para>
+   The actual query to determine the size is to use the
+   <code>subblock_domain()</code> parallel support function to
+   determine the size of the subblock held by the local processor:
+  </para>
+
+  <programlisting><![CDATA[  size_t size = subblock_domain(data_in).size();
+  auto_ptr<value_type> buffer(new value_type[size]);
+  data_in.block()->rebind(buffer);]]></programlisting>
+
+  <para>
+   With the views in place, the next step is to perform the input I/O.
+   Since we only want to perform this I/O on the processors in the
+   input map <code>map_in</code>, we guard the I/O region
+   appropriately:
+  </para>
+
+  <programlisting><![CDATA[  if (subblock(data_in) != no_subblock)
+   {
+     data_in.block().release(false);
+     // ... perform IO into data_in ...
+     data_in.block().admit(true);
+   }]]></programlisting>
+
+  <para>
+   Once the I/O is completed, next we scatter the data from
+   <code>data_in</code> to <code>data</code> and process it:
+  </para>
+
+  <programlisting><![CDATA[  data = data_in;
+
+  // ... process data ...]]></programlisting>
+
+  </section>
+
+  <section> <title>Parallel Input I/O</title>
+
+  <para>
+   This fragment easily extends to handle parallel I/O.  To
+   distribute the I/O across multiple processors, we just add
+   them to <code>pvec_in</code>:
+  </para>
+
+  <programlisting><![CDATA[  Vector<processor_type> pvec_in(num_io_proc);
+  pvec_in(0)              = 0;
+  ...
+  pvec_in(num_io_proc-1)  = ...;]]></programlisting>
+
+  <para>
+   Of course, the actual I/O needs to be cognizant of the multiple
+   processors as well.
+  </para>
+
+  </section>
+
+  <section> <title>Applying I/O to Fast Convolution</title>
+
+  <para>
+   Applying this technique to fast convolution:
+  </para>
+
+  <programlisting><xi:include href="src/par/fc3-io.cpp" parse="text"/></programlisting>
+
+  </section>
+
+ </section>
+
+</chapter>
