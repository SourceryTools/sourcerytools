Index: ChangeLog
===================================================================
--- ChangeLog	(revision 147489)
+++ ChangeLog	(working copy)
@@ -1,3 +1,18 @@
+2006-08-24  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/parallel.hpp: Include par-foreach.
+	* src/vsip/impl/expr_serial_dispatch.hpp: Add missing include.
+	* doc/tutorial/parallel.xml: Apply Mark's 7/31 edits.
+	* doc/tutorial/src/par/Makefile: New file, makefile for tutorial
+	  programs.
+	* doc/tutorial/src/par/fc2-foreach.cpp: New file, complete
+	  parallel foreach example program.
+	* doc/tutorial/src/par/fc2-local-views.cpp: New file, complete
+	  parallel local views example program.
+	* doc/tutorial/src/par/fc3-io.cpp: Update to match tutorial text.
+	* doc/tutorial/src/par/fc1-parallel.cpp: Likewise.
+	* doc/tutorial/src/par/fc1-serial.cpp: Likewise.
+	
 2006-08-21  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/complex.hpp: Added functions to provide names for 
Index: src/vsip/parallel.hpp
===================================================================
--- src/vsip/parallel.hpp	(revision 147489)
+++ src/vsip/parallel.hpp	(working copy)
@@ -20,6 +20,7 @@
 #include <vsip/impl/working-view.hpp>
 #include <vsip/impl/par-support.hpp>
 #include <vsip/impl/par-util.hpp>
+#include <vsip/impl/par-foreach.hpp>
 
 
 
Index: src/vsip/impl/expr_serial_dispatch.hpp
===================================================================
--- src/vsip/impl/expr_serial_dispatch.hpp	(revision 147489)
+++ src/vsip/impl/expr_serial_dispatch.hpp	(working copy)
@@ -20,6 +20,7 @@
 #include <vsip/impl/expr_serial_dispatch_fwd.hpp>
 #include <vsip/impl/eval_dense_expr.hpp>
 #include <vsip/impl/expr_ops_info.hpp>
+#include <vsip/impl/profile.hpp>
 
 #ifdef VSIP_IMPL_HAVE_IPP
 #include <vsip/impl/ipp.hpp>
Index: doc/tutorial/src/par/fc2-foreach.cpp
===================================================================
--- doc/tutorial/src/par/fc2-foreach.cpp	(revision 0)
+++ doc/tutorial/src/par/fc2-foreach.cpp	(revision 0)
@@ -0,0 +1,108 @@
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
+
+using namespace vsip;
+
+
+
+/***********************************************************************
+  Main Program
+***********************************************************************/
+
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
+	    dimension_type Dim>
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
+  typedef Map<Block_dist, Whole_dist>               map_type;
+  typedef Dense<2, value_type, row2_type, map_type> block_type;
+  typedef Matrix<value_type, block_type>            view_type;
+
+  typedef Dense<1, value_type, row1_type, Replicated_map<1> >
+                                                    replica_block_type;
+  typedef Vector<value_type, replica_block_type>    replica_view_type;
+
+  // Parameters.
+  length_type npulse = 64;	// number of pulses
+  length_type nrange = 256;	// number of range cells
+
+  // Maps.
+  map_type          map = map_type(num_processors(), 1);
+  Replicated_map<1> replica_map;
+
+  // Views.
+  replica_view_type replica(nrange, replica_map);
+  view_type         data(npulse, nrange, map);
+  view_type         tmp (npulse, nrange, map);
+
+  // A forward Fft for computing the frequency-domain version of
+  // the replica.
+  typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
+		for_fft_type;
+  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
+
+  Fast_convolution<value_type> fconv(replica.local());
+
+  // Initialize data to zero.
+  data    = value_type();
+  replica = value_type();
+
+  // Before fast convolution, convert the replica into the
+  // frequency domain
+  for_fft(replica.local());
+
+  // Perform fast convolution.
+  foreach_vector<tuple<0, 1> >(fconv, data);
+}
Index: doc/tutorial/src/par/fc3-io.cpp
===================================================================
--- doc/tutorial/src/par/fc3-io.cpp	(revision 147489)
+++ doc/tutorial/src/par/fc3-io.cpp	(working copy)
@@ -1,11 +1,3 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    fc-with-io.cpp
-    @author  Jules Bergmann
-    @date    2005-10-31
-    @brief   VSIPL++ Library: Fast convolution example with IO.
-*/
-
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -16,10 +8,8 @@
 #include <vsip/math.hpp>
 #include <vsip/map.hpp>
 #include <vsip/parallel.hpp>
-#include <vsip/impl/global_map.hpp>
 
 using namespace vsip;
-using namespace std;
 
 
 
@@ -27,26 +17,24 @@
   Main Program
 ***********************************************************************/
 
-template <typename       View,
+template <typename       ViewT,
 	  dimension_type Dim>
-View
+ViewT
 create_view_wstorage(
-  Domain<Dim> const&                         dom,
-  typename View::block_type::map_type const& map)
+  Domain<Dim> const&                          dom,
+  typename ViewT::block_type::map_type const& map)
 {
-  typedef typename View::block_type block_type;
-  typedef typename View::value_type value_type;
+  typedef typename ViewT::block_type block_type;
+  typedef typename ViewT::value_type value_type;
 
   block_type* block = new block_type(dom, (value_type*)0, map);
-  View view(*block);
-  // block->decrement_count();
+  ViewT view(*block);
+  block->decrement_count();
 
-  if (map.subblock() != no_subblock)
+  if (subblock(view) != no_subblock)
   {
-    size_t size = subblock_domain(view).size(); // * sizeof(value_type);
-    value_type* buffer =
-      static_cast<value_type*>(
-	vsip::impl::alloc_align(128, size*sizeof(value_type)));
+    size_t size = subblock_domain(view).size();
+    value_type* buffer = vsip::impl::alloc_align<value_type>(128, size);
     block->rebind(buffer);
   }
 
@@ -57,11 +45,11 @@
 
 
 
-template <typename View>
+template <typename ViewT>
 void
-cleanup_view_wstorage(View view)
+cleanup_view_wstorage(ViewT view)
 {
-  typedef typename View::value_type value_type;
+  typedef typename ViewT::value_type value_type;
   value_type* ptr;
 
   view.block().release(false, ptr);
@@ -72,25 +60,25 @@
 
 
 
-template <typename View>
-View
+template <typename ViewT>
+ViewT
 create_view_wstorage(
-  length_type                                rows,
-  length_type                                cols,
-  typename View::block_type::map_type const& map)
+  length_type                                 rows,
+  length_type                                 cols,
+  typename ViewT::block_type::map_type const& map)
 {
-  return create_view_wstorage<View>( Domain<2>(rows, cols), map);
+  return create_view_wstorage<ViewT>(Domain<2>(rows, cols), map);
 }
 
 
 
-template <typename View>
-View
+template <typename ViewT>
+ViewT
 create_view_wstorage(
-  length_type                                size,
-  typename View::block_type::map_type const& map)
+  length_type                                 size,
+  typename ViewT::block_type::map_type const& map)
 {
-  return create_view_wstorage<View>( Domain<1>(size), map);
+  return create_view_wstorage<ViewT>(Domain<1>(size), map);
 }
 
 
@@ -108,55 +96,58 @@
   typedef Dense<2, value_type, row2_type, map_type> block_type;
   typedef Matrix<value_type, block_type>            view_type;
 
-  typedef Dense<1, value_type, row1_type, Global_map<1> > replica_block_type;
-  typedef Vector<value_type, replica_block_type>          replica_view_type;
+  typedef Dense<1, value_type, row1_type, Replicated_map<1> >
+                                                    replica_block_type;
+  typedef Vector<value_type, replica_block_type>    replica_view_type;
 
   typedef Dense<1, value_type, row1_type, Map<> >   replica_io_block_type;
   typedef Vector<value_type, replica_io_block_type> replica_io_view_type;
 
-
-
-  // Data cube parameters.
+  // Parameters.
   length_type npulse = 64;	// number of pulses
   length_type nrange = 256;	// number of range cells
 
-  processor_type np = num_processors();
+  length_type np = num_processors();
 
+  // Processor sets.
   Vector<processor_type> pvec_in(1);  pvec_in(0)  = 0;
   Vector<processor_type> pvec_out(1); pvec_out(0) = np-1;
 
-  map_type map_in (pvec0, 1, 1);
-  map_type map_out(pvecN, 1, 1);
-  map_type row_map(np, 1);
+  // Maps.
+  map_type          map_in (pvec_in,  1, 1);
+  map_type          map_out(pvec_out, 1, 1);
+  map_type          map_row(np, 1);
+  Replicated_map<1> replica_map;
 
-  // Create the data cube.
-  view_type data(npulse, nrange, row_map);
-  view_type tmp (npulse, nrange, row_map);
-
-  // Create the I/O data cubes.
+  // Views.
+  view_type data(npulse, nrange, map_row);
+  view_type tmp (npulse, nrange, map_row);
   view_type data_in (create_view_wstorage<view_type>(npulse, nrange, map_in));
   view_type data_out(create_view_wstorage<view_type>(npulse, nrange, map_out));
-
-  // Create the pulse replica
   replica_view_type    replica(nrange);
   replica_io_view_type replica_in(
     create_view_wstorage<replica_io_view_type>(nrange, map_in));
 
-  // Define the FFT typedefs.
+  // A forward Fft for computing the frequency-domain version of
+  // the replica.
   typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
 		for_fft_type;
+  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
+
+  // A forward Fftm for converting the time-domain data matrix to the
+  // frequency domain.
   typedef Fftm<value_type, value_type, row, fft_fwd, by_reference>
 	  	for_fftm_type;
+  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+
+  // An inverse Fftm for converting the frequency-domain data back to
+  // the time-domain.
   typedef Fftm<value_type, value_type, row, fft_inv, by_reference>
 	  	inv_fftm_type;
+  inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange));
 
-  // Create the FFT objects.
-  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
-  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
-  inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange*npulse));
-
   // Perform input IO
-  if (map_in.subblock() != no_subblock)
+  if (subblock(data_in) != no_subblock)
   {
     data_in.block().release(false);
     // ... perform IO ...
@@ -178,25 +169,16 @@
   data    = data_in;
   replica = replica_in;
 
+  // Perform fast convolution.
+  for_fftm(data, tmp);		// Convert to the frequency domain.
+  tmp = vmmul<0>(replica, tmp); // Perform element-wise multiply.
+  inv_fftm(tmp, data);		// Convert back to the time domain.
 
-  // Perform fast convolution:
-
-  // 1) convert cube into frequency domain
-  for_fftm(data, tmp);
-
-  // 2) perform element-wise multiply
-  tmp = vmmul<0>(replica, tmp);
-
-  // 3) convert cube back into time domain
-  inv_fftm(tmp, data);
-
-
-  // Scatter data
+  // Gather data
   data_out = data;
 
-
   // Perform output IO
-  if (map_out.subblock() != no_subblock)
+  if (subblock(data_out) != no_subblock)
   {
     data_out.block().release(true);
     // ... perform IO ...
Index: doc/tutorial/src/par/fc1-parallel.cpp
===================================================================
--- doc/tutorial/src/par/fc1-parallel.cpp	(revision 147489)
+++ doc/tutorial/src/par/fc1-parallel.cpp	(working copy)
@@ -1,11 +1,3 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    fc1-parallel.cpp
-    @author  Jules Bergmann
-    @date    2005-10-31
-    @brief   VSIPL++ Library: ...
-*/
-
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -15,10 +7,8 @@
 #include <vsip/signal.hpp>
 #include <vsip/math.hpp>
 #include <vsip/map.hpp>
-#include <vsip/impl/global_map.hpp>
 
 using namespace vsip;
-using namespace std;
 
 
 
@@ -38,56 +28,58 @@
   typedef Dense<2, value_type, row2_type, map_type> block_type;
   typedef Matrix<value_type, block_type>            view_type;
 
-  typedef Dense<1, value_type, row1_type, Global_map<1> > replica_block_type;
-  typedef Vector<value_type, replica_block_type>          replica_view_type;
+  typedef Dense<1, value_type, row1_type, Replicated_map<1> >
+                                                    replica_block_type;
+  typedef Vector<value_type, replica_block_type>    replica_view_type;
 
-
-  // Data cube parameters.
+  // Parameters.
   length_type npulse = 64;	// number of pulses
   length_type nrange = 256;	// number of range cells
 
-  processor_type np = num_processors();
+  // Maps.
+  map_type          map = map_type(num_processors(), 1);
+  Replicated_map<1> replica_map;
 
-  map_type map = map_type(Block_dist(np), Whole_dist());
+  // Views.
+  replica_view_type replica(nrange, replica_map);
+  view_type         data(npulse, nrange, map);
+  view_type         tmp (npulse, nrange, map);
 
-  // Create the data cube.
-  view_type data(npulse, nrange, map);
-  view_type tmp (npulse, nrange, map);
-
-  // Create the pulse replica
-  replica_view_type replica(nrange);
-
-  // Define the FFT typedefs.
+  // A forward Fft for computing the frequency-domain version of
+  // the replica.
   typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
 		for_fft_type;
+  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
+
+  // A forward Fftm for converting the time-domain data matrix to the
+  // frequency domain.
   typedef Fftm<value_type, value_type, row, fft_fwd, by_reference>
 	  	for_fftm_type;
+  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+
+  // An inverse Fftm for converting the frequency-domain data back to
+  // the time-domain.
   typedef Fftm<value_type, value_type, row, fft_inv, by_reference>
 	  	inv_fftm_type;
+  inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange));
 
-  // Create the FFT objects.
-  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
-  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
-  inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange*npulse));
-
-  // Initialize
+  // Initialize data to zero.
   data    = value_type();
   replica = value_type();
 
-
-  // Before fast convolution, convert the replica into the
+  // Before fast convolution, convert the replica to the the
   // frequency domain
-  // TODO // for_fft(replica);
+  for_fft(replica);
 
 
   // Perform fast convolution:
 
-  // 1) convert cube into frequency domain
+  // Convert to the frequency domain.
   for_fftm(data, tmp);
 
-  // 2) perform element-wise multiply
+  // Perform element-wise multiply for each pulse.
   tmp = vmmul<0>(replica, tmp);
 
-  // 3) convert cube back into time domain
+  // Convert back to the time domain.
   inv_fftm(tmp, data);
 }
Index: doc/tutorial/src/par/fc1-serial.cpp
===================================================================
--- doc/tutorial/src/par/fc1-serial.cpp	(revision 147489)
+++ doc/tutorial/src/par/fc1-serial.cpp	(working copy)
@@ -1,12 +1,3 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    fce-serial.cpp
-    @author  Jules Bergmann
-    @date    2005-10-25
-    @brief   VSIPL++ Library:
-    Parallel Howto: fast convolution example (serial version).
-*/
-
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -17,7 +8,6 @@
 #include <vsip/math.hpp>
 
 using namespace vsip;
-using namespace std;
 
 
 
@@ -33,48 +23,50 @@
 
   typedef complex<float> value_type;
 
-  // Data cube parameters.
+  // Parameters.
   length_type npulse = 64;	// number of pulses
   length_type nrange = 256;	// number of range cells
 
-  // Create the data cube.
+  // Views.
+  Vector<value_type> replica(nrange);
   Matrix<value_type> data(npulse, nrange);
   Matrix<value_type> tmp(npulse, nrange);
 
-  // Create the pulse replica
-  Vector<value_type> replica(nrange);
-
-  // Define the FFT typedefs.
+  // A forward Fft for computing the frequency-domain version of
+  // the replica.
   typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
 		for_fft_type;
+  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
+
+  // A forward Fftm for converting the time-domain data matrix to the
+  // frequency domain.
   typedef Fftm<value_type, value_type, row, fft_fwd, by_reference>
 	  	for_fftm_type;
+  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+
+  // An inverse Fftm for converting the frequency-domain data back to
+  // the time-domain.
   typedef Fftm<value_type, value_type, row, fft_inv, by_reference>
 	  	inv_fftm_type;
-
-  // Create the FFT objects.
-  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
-  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
   inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange));
 
-  // Initialize data to zero
+  // Initialize data to zero.
   data    = value_type();
   replica = value_type();
 
-
-  // Before fast convolution, convert the replica into the
+  // Before fast convolution, convert the replica to the the
   // frequency domain
   for_fft(replica);
 
 
-  // Perform fast convolution:
+  // Perform fast convolution.
 
-  // 1) convert cube into frequency domain
+  // Convert to the frequency domain.
   for_fftm(data, tmp);
 
-  // 2) perform element-wise multiply
+  // Perform element-wise multiply for each pulse.
   tmp = vmmul<0>(replica, tmp);
 
-  // 3) convert cube back into time domain
+  // Convert back to the time domain.
   inv_fftm(tmp, data);
 }
Index: doc/tutorial/src/par/Makefile
===================================================================
--- doc/tutorial/src/par/Makefile	(revision 0)
+++ doc/tutorial/src/par/Makefile	(revision 0)
@@ -0,0 +1,54 @@
+########################################################################
+#
+# File:   doc/tutorial/src/par/Makefile
+# Author: Jules Bergmann
+# Date:   2006-08-24
+#
+# Contents: Makefile for tutorial example programs.
+#
+########################################################################
+
+########################################################################
+# Variables
+########################################################################
+
+# This optionally points to the directory where Sourcery VSIPL++ is
+# installed.  If not defined, the package found in PKG_CONFIG_PATH is
+# used.
+prefix =
+
+# This selects the desired library.  Use '-debug' for building a version 
+# suitable for debugging or leave blank to use the optimized version.
+suffix = 
+
+ifeq ($(prefix),)
+  pkgcommand := pkg-config vsipl++$(suffix)
+else
+  pkgcommand := PKG_CONFIG_PATH=$(prefix)/lib/pkgconfig 	\
+                     pkg-config vsipl++$(suffix) 	\
+                     --define-variable=prefix=$(prefix)
+endif
+
+CXX      = $(shell ${pkgcommand} --variable=cxx)
+CXXFLAGS = $(shell ${pkgcommand} --cflags) \
+	   $(shell ${pkgcommand} --variable=cxxflags)
+LIBS     = $(shell ${pkgcommand} --libs)
+ 
+
+########################################################################
+# Rules
+########################################################################
+
+all: fc1-serial fc1-parallel fc2-local-views fc2-foreach fc3-io
+
+%.o: %.cpp
+	$(CXX) -c $(CXXFLAGS) -o $@ $<
+
+%: %.o
+	$(CXX) $(CXXFLAGS) -o $@ $< $(LIBS)
+
+fc1-serial: fc1-serial.o
+fc1-parallel: fc1-parallel.o
+fc2-local-views: fc2-local-views.o
+fc2-foreach: fc2-foreach.o
+fc3-io: fc3-io.o
Index: doc/tutorial/src/par/fc2-local-views.cpp
===================================================================
--- doc/tutorial/src/par/fc2-local-views.cpp	(revision 0)
+++ doc/tutorial/src/par/fc2-local-views.cpp	(revision 0)
@@ -0,0 +1,77 @@
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/math.hpp>
+#include <vsip/map.hpp>
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
+  typedef Map<Block_dist, Whole_dist>               map_type;
+  typedef Dense<2, value_type, row2_type, map_type> block_type;
+  typedef Matrix<value_type, block_type>            view_type;
+
+  typedef Dense<1, value_type, row1_type, Replicated_map<1> >
+                                                    replica_block_type;
+  typedef Vector<value_type, replica_block_type>    replica_view_type;
+
+  // Parameters.
+  length_type npulse = 64;	// number of pulses
+  length_type nrange = 256;	// number of range cells
+
+  // Maps.
+  map_type          map = map_type(num_processors(), 1);
+  Replicated_map<1> replica_map;
+
+  // Views.
+  replica_view_type  replica(nrange, replica_map);
+  view_type          data(npulse, nrange, map);
+  Vector<value_type> tmp(nrange); 
+
+  // A forward Fft for converting the time-domain data to the
+  // frequency domain.
+  typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
+		for_fft_type;
+  for_fft_type  for_fft(Domain<1>(nrange), 1.0);
+
+  // An inverse Fft for converting the frequency-domain data back to
+  // the time-domain.
+  typedef Fft<const_Vector, value_type, value_type, fft_inv, by_reference>
+	  	inv_fft_type;
+  inv_fft_type  inv_fft(Domain<1>(nrange), 1.0/nrange);
+
+  // Initialize data to zero.
+  data    = value_type();
+  replica = value_type();
+
+  // Before fast convolution, convert the replica into the
+  // frequency domain
+  for_fft(replica.local());
+
+  view_type::local_type         l_data    = data.local();
+  replica_view_type::local_type l_replica = replica.local();
+
+  for (index_type l_r=0; l_r < l_data.size(0); ++l_r)
+  {
+    for_fft(l_data.row(l_r), tmp);
+    tmp *= l_replica;
+    inv_fft(tmp, l_data.row(l_r));
+  }
+}
Index: doc/tutorial/parallel.xml
===================================================================
--- doc/tutorial/parallel.xml	(revision 147489)
+++ doc/tutorial/parallel.xml	(working copy)
@@ -13,129 +13,191 @@
  </chapterinfo>
 
  <para>
-  This chapter describes how to use VSIPL++ for data-parallel
-  computation.  Starting with a serial implementation of fast
-  convolution, a common signal processing kernel, it will show how
-  to parallelize the serial version, how to deal with explicit data
-  parallelism, and how to deal with I/O.
+  This chapter explains how to use Sourcery VSIPL++ to perform
+  parallel computations.  First, you will see how to compute
+  <firstterm>fast convolution</firstterm> (a common signal-processing
+  kernel) using a single processor.  Next, you will see how to
+  convert the serial implementation to a parallel program so that you
+  can take advantage of multiple processors.  Then, you will learn
+  how to optimize the performance of the parallel implementation.
+  Finally, you will learn how to handle input and output when working
+  in parallel.
  </para>
 
- <para>
-  <emphasis>Fast convolution</emphasis> refers to the technique of
-  performing convolution in the frequency domain using the the relation
-  f * g = F . G, where F and G are the frequency domain representations
-  of signals f and g.  Because translation between the time and frequency
-  domains can be done in O(n log n) complexity with the fast Fourier
-  transform (FFT), for large kernel sizes frequency domain convolution
-  requires fewer operations than time domain convolution.  Moreover,
-  highly optimized FFT routines are available for many architectures.
- </para>
-
- <para>
-  One use of fast convolution in practice is the pulse compression
-  step in radar signal processing.  To increase the effective bandwidth of a
-  system, radars will transmit a frequency modulated "chirp".  By
-  convolving the received signal with the time-inverse of the chirp
-  (called the "replica"), the total energy returned from an object can be
-  collapsed into a single range cell.  Other uses of fast convolution
-  are be found in sonar processing, software radio, and so on.
- </para>
-
- <section>
+ <section id="sec-serial-fastconv">
   <title>Serial Fast Convolution</title>
 
   <para>
-   Let's start with a simple program that performs fast convolution
-   on a set of pulses stored in a data cube.
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
   </para>
 
   <para>
-   First, initialize the library:
+   One practical use of fast convolution is to perform the pulse
+   compression step in radar signal processing.  To increase the
+   effective bandwidth of a system, radars will transmit a frequency
+   modulated &quot;chirp&quot;.  By convolving the received signal with
+   the time-inverse of the chirp (called the &quot;replica&quot;), the
+   total energy returned from an object can be collapsed into a single
+   range cell.  Fast convolution is also useful in many other contexts
+   including sonar processing and software radio.
   </para>
 
-  <programlisting>  vsipl vpp(argc, argv);</programlisting>
-
   <para>
-   Next, create data structures to hold the data cube and the pulse
-   replica:
+   In this section, you will construct a program that performs fast
+   convolution on a set of time-domain signals stored in a matrix.
+   Each row of the matrix corresponds to a single signal, or
+   &quot;pulse&quot;.  The columns correspond to points in time.  So,
+   the entry at position (i, j) in the matrix indicates the amplitude
+   and phase of the signal received at time j for the ith pulse.
   </para>
+  
+  <para>
+   The first step is to declare the data matrix, the vector that will
+   contain the replica signal, and a temporary matrix that will 
+   hold the results of the computation:
+  </para>
 
-  <programlisting><![CDATA[  typedef complex<float> value_type;
-
-  // Data cube parameters.
+  <programlisting><![CDATA[  // Parameters.
   length_type npulse = 64;	// number of pulses
   length_type nrange = 256;	// number of range cells
 
-  // Create the data cube.
+  // Views.
+  typedef complex<float> value_type;
+  Vector<value_type> replica(nrange);
   Matrix<value_type> data(npulse, nrange);
-  Matrix<value_type> tmp (npulse, nrange);
+  Matrix<value_type> tmp (npulse, nrange);]]></programlisting>
 
-  // Create the pulse replica
-  Vector<value_type> replica(nrange);]]></programlisting>
-
   <para>
-   For now, you should ignore the initialization of <code>data</code>
-   by setting it to zero (section XXX will discuss parallel IO):
+   For now, it is most convenient to initialize the input data
+   to zero.  (In <xref linkend="sec-parallel-io"/>, you will learn how
+   to perform I/O operations so that you can populate the matrix with
+   real data.)
   </para>
 
-  <programlisting>  // Initialize data to zero
-  data    = value_type();
-  replica = value_type();</programlisting>
+  <para> 
+   In C++, you can use the constructor syntax <code>T()</code> to
+   perform &quot;default initialization&quot; of a type
+   <code>T()</code>.  The default value for any numeric type
+   (including complex numbers) is zero.  Therefore, the expression
+   <code>value_type()</code> indicates the complex number with zero as
+   both its real and imaginary components.  In the VSIPL++ API, when
+   you assign a scalar value to a view (a vector, matrix, or tensor),
+   all elements of the view are assigned the scalar value.  So, the
+   code below sets the contents of both the data matrix and  replica
+   vector to zero:
+  </para>
 
+  <programlisting><![CDATA[  data    = value_type();
+  replica = value_type();]]></programlisting>
+
   <para>
-   To process the data cube, create signal processing objects for the
-   FFTs:
+   The next step is to define the FFTs that will be performed.
+   Typically (as in this example) an application performs multiple
+   FFTs on inputs with the same size.  Since performing an FFT
+   requires that some set-up be performed before performing the actual
+   FFT computation, it is more efficient to set up the FFT just once.
+   Therefore, in the VSIPL++ API, FFTs are objects, rather than
+   operators.  Constructing the FFT performs the necessary set-up
+   operations.
   </para>
 
-  <programlisting><![CDATA[  // Define the FFT typedefs.
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
   typedef Fft<const_Vector, value_type, value_type, fft_fwd, by_reference>
 		for_fft_type;
+  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
+
+  // A forward Fftm for converting the time-domain data matrix to the
+  // frequency domain.
   typedef Fftm<value_type, value_type, row, fft_fwd, by_reference>
 	  	for_fftm_type;
+  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+
+  // An inverse Fftm for converting the frequency-domain data back to
+  // the time-domain.
   typedef Fftm<value_type, value_type, row, fft_inv, by_reference>
 	  	inv_fftm_type;
-
-  // Create the FFT objects.
-  for_fft_type  for_fft (Domain<1>(nrange), 1.0);
-  for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
   inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange));]]></programlisting>
 
   <para>
-   The final setup step before performing fast convolution is to
-   transform the replica into the frequency domain.  This is done
-   once outside of the main computation:
+   Before performing the actual convolution, you must convert the 
+   replica to the frequency domain using the FFT created above.  Because
+   the replica data is a property of the chirp, we only need to do
+   this once; even if our radar system runs for a long time, the
+   converted replica will always be the same.  VSIPL++ FFT
+   objects behave like functions, so you can just &quot;call&quot; the
+   FFT object:
   </para>
 
   <programlisting>  for_fft(replica);</programlisting>
 
   <para>
-   Now perform fast convolution by:
-    (1) transforming all pulses in <code>data</code> into the frequency
-        domain,
-    (2) performing an element-wise multiply against the frequency-domain
-        replica, and
-    (3) transforming all pulses back into the time domain.
+   Now, you are ready to perform the actual fast convolution
+   operation!  You will use the forward and inverse multiple-FFT
+   objects you've already created to go into and out of the frequency
+   domain.  While in the frequency domain, you will use the
+   <function>vmmul</function> operator to perform a 
+   vector-matrix multiply.  In particular, you will multiply each row
+   (dimension zero) of the frequency-domain matrix by the replica.
+   The <function>vmmul</function> operator is a template taking a
+   single parameter which indicates whether the multiplication should
+   be performed on rows or on columns.  So, the heart of the fast
+   convolution algorithm is just:
   </para>
 
-  <programlisting><![CDATA[  // 1) convert cube into frequency domain
+  <programlisting><![CDATA[  // Convert to the frequency domain.
   for_fftm(data, tmp);
 
-  // 2) perform element-wise multiply
+  // Perform element-wise multiply for each pulse.
   tmp = vmmul<0>(replica, tmp);
 
-  // 3) convert cube back into time domain
+  // Convert back to the time domain.
   inv_fftm(tmp, data);]]></programlisting>
 
   <para>
-   Putting this altogether:
+   A complete program listing is show below.  You can copy this
+   program directly into your editor and build it.  (You may notice
+   that there are a few things in the complete listing not discussed
+   above, including in particular, initialization of the library.)
   </para>
 
   <programlisting><xi:include href="src/par/fc1-serial.cpp" parse="text"/> </programlisting>
 
   <para>
    The following figure shows the performance in MFLOP/s of fast
-   convolution on a 3.06 GHz Pentium processor as the numbr of range
-   cells is swept from 16 to 65536.
+   convolution on a 3.06 GHz Pentium Xeon processor as the number of
+   range cells varies from 16 to 65536.
   </para>
 
   <mediaobject>
@@ -146,122 +208,124 @@
 
  </section>
 
- <section>
+ <section id="sec-parallel-fastconv">
   <title>Parallel Fast Convolution</title>
 
-
   <para>
-   The example fast convolution program has <emphasis>implicit
-   parellelism</emphasis>: the <code>Fftm</code> and
-   <code>vmmul</code> operators express multiple, independent
-   operations that can be performed in parallel on the data.  This
-   will show how to use maps to distributed data so these operations
-   can be automatically performed in parallel.
+   The fast convolution program in the previous section makes use of
+   two implicitly parallel operators: <function>Fftm</function> and
+   <function>vmmul</function>.  These operators are implicity parallel
+   in the sense that they process each row of the matrix
+   independently.  If you had enough processors, you could put each
+   row on a separate processor and then perform the entire
+   computation in parallel.
   </para>
 
- <para>
-  The general recipe for parallelizing a VSIPL++ program is:
-
-   <itemizedlist>
-    <listitem>
-     <para>
-      Analyze the program to find available data parallelism,
-     </para>
-    </listitem>
-
-    <listitem>
-     <para>
-      Apply mappings to the program's data structures to distribute
-      data so that (a) these data parallel operations can be performed
-      in parallel and (b) communication overheads between successive
-      operations are minimized.
-     </para>
-    </listitem>
-
-    <listitem>
-     <para>
-      Finally, convert explicit data parallelism to either be
-      implicit, or use explicit local views.
-     </para>
-    </listitem>
-   </itemizedlist>
-  </para>
-
   <para>
-   Applying this recipe to the program, you will see that both the
-   <code>Fftm</code> and <code>vmmul</code> operations are data
-   parallel.  The <code>Fftm</code>'s perform an FFT operation each
-   row of the matrix <code>data</code>.  The vector matrix multiply
-   performs a multiply on each element of <code>data</code>.
+   In the VSIPL++ API, you have explicit control of the number of
+   processors used for a computation.  Since the default is to use
+   just a single processor, the program above will not run in
+   parallel, even on a multi-processor system.  This section will show
+   you how to use <firstterm>maps</firstterm> to take advantage of
+   multiple processors.  Using a map tells Sourcery VSIPL++ to
+   distribute a single block of data across multiple processors.
+   Then, Sourcery VSIPL++ will automatically move data between
+   processors as necessary.
   </para>
 
   <para>
-   Of the two operations, <code>Fftm</code> is coarser grain: for the
-   data sizes being processed, it is efficient to perform a single
-   FFT on a single processor.  However, multiple processors can perform
-   multiple FFTs in parallel.
+   The VSIPL++ API uses the Single-Program Multiple-Data (SPMD) model
+   for parallelism.  In this model, every processor runs the same
+   program, but operates on different sets of data.  For instance, in
+   the fast convolution example, multiple processors perform FFTs at
+   the same time, but each processor handles different rows in the
+   matrix.
   </para>
 
   <para>
-   Based on these requirements, a good mapping for <code>data</code>
-   distributes dimension 0 (rows) while keeping dimension 1 (columns)
-   together.  This places one or more row on each processor, allowing
-   multiple processors to compute in parallel.
+   Every map has both compile-time and run-time properties.  At
+   compile-time, you specify the <firstterm>distribution</firstterm>
+   that will be applied to each dimension.  In this example, you will
+   use a <firstterm>block distribution</firstterm> to distribute the
+   rows of the matrix.  A block distribution divides a view into
+   continguous chunks.  For example, suppose that you have a
+   4-processor system.  Since there are 64 rows in the matrix
+   <varname>data</varname>, there will be 16 rows on each processor.
+   The block distribution will place the first 16 rows (rows 0 through
+   15) on processor 0, the next 16 rows (rows 16 through 31) on
+   processor 1, and so forth.  You do not want to distribute the
+   columns of the matrix at all, so you will use a <firstterm>whole
+   distribution</firstterm> for the columns.
   </para>
-
+  
   <para>
-   The map definition is separated into two parts.  First, create a
-   typedef for the type of the map.  This is used later when modifying
-   the block type of our data structures.  Second, create a map object
-   of this type, passing as arguments the number of subblocks to
-   create in each dimension.  Dimension 0 should be distributed over
-   all processors, so subblock = <code>num_processors()</code>).
-   Dimension 1 is not distributed, so subblocks = 1.
+   Although the distributions are selected at compile-time, the number
+   of processors to use in each dimension is not specified until
+   run-time.  By specifying the number of processors at run-time, you
+   can adapt your program to the configuration of the machine on which
+   your application is running.  The VSIPL++ API provides a
+   <function>num_processors</function> function to tell you the total
+   number of processors available.  Of course, since each row should
+   be kept on a single processor, the number of processors used in the
+   column dimension is just one.  So, here is the code required to
+   create the map:
   </para>
 
   <programlisting><![CDATA[  typedef Map<Block_dist, Whole_dist>               map_type;
-  map_type map = map_type(num_processors(), 1);]]></programlisting>
+  map_type map = map_type(/*rows=*/num_processors(), 
+                          /*columns=*/1);]]></programlisting>
 
   <para>
-   By distributing <code>data</code> in this way, a complete copy of
-   <code>replica</code> should be on each processor to perform the
-   <code>vmmul</code>. This is done with a <code>Replicated_map</code>.
+   Next, you have to tell Sourcery VSIPL++ to use this map for the relevant
+   views.  Every view has an underlying <firstterm>block</firstterm>.
+   The block indicates how the view's data is stored.  Until this
+   point, you have been using the default <classname>Dense</classname>
+   block, which stores data in a continguous array on a single
+   processor.  Now, you want to use a continguous array on
+   <emphasis>multiple</emphasis> processors, so you must explicitly
+   distribute the block.  Then, when declaring views, you must
+   explicitly indicate that the view should use the distributed block:
   </para>
 
-  <programlisting><![CDATA[  Replicated_map<1> replica_map;]]></programlisting>
-
-  <para>
-   To apply these maps to our data structures, modify the block type
-   to reflect the map type:
-  </para>
-
   <programlisting><![CDATA[  typedef Dense<2, value_type, row2_type, map_type> block_type;
   typedef Matrix<value_type, block_type>            view_type;
   view_type data(npulse, nrange, map);
+  view_type tmp(npulse, nrange, map);]]></programlisting>  
 
+  <para>
+   Performing the vector-matrix multiply requires a complete copy of
+   <varname>replica</varname> on each processor.  An ordinary map
+   divides data among processors, but, here, the goal is to copy the
+   same data to multiple processors.  Sourcery VSIPL++ provides a
+   special <classname>Replicated_map</classname> class to use in this
+   situation.  So, you should declare <varname>replica</varname> as
+   follows:
+  </para>
+
+  <programlisting><![CDATA[  Replicated_map<1> replica_map;
   typedef Dense<1, value_type, row1_type, Replicated_map<1> >
                                                     replica_block_type;
   typedef Vector<value_type, replica_block_type>    replica_view_type;
   replica_view_type replica(nrange, replica_map);]]></programlisting>
 
   <para>
-   The final step is to reformulate any explicit data parallelism.
-   Since all of the operations (<code>Fftm</code> and
-   <code>vmmul</code>) are implicitly data parallel, no action is
-   necessary.  However, the next section will show how to deal with
-   explicit data parallelism.
+   Because the application already uses implicitly parallel operators,
+   no further changes are required.  The entire algorithm (i.e., the
+   part of the code that performs FFTs and vector-matrix
+   multiplication) remains unchanged.
   </para>
 
   <para>
-   Applying these maps, the program now looks like:
+   The complete parallel program is:
   </para>
 
   <programlisting><xi:include href="src/par/fc1-parallel.cpp" parse="text"/> </programlisting>
 
   <para>
-   The following figure shows the parallel speedup of the fast convolution
-   program from 1 to 32 3.0 GHz Pentium processors.  On 32 nodes, XXX MFLOP/s
-   are sustained.
+   The following graph shows the parallel speedup of the fast
+   convolution program from 1 to 32 processors using a 3.0 GHz Pentium
+   cluster system.  As you can see, increasing the number of
+   processors also increases the performance of the program.
   </para>
 
   <mediaobject>
@@ -272,25 +336,54 @@
 
  </section>
 
- <section> <title>Explicit Parallelism: Inner Loops Optimization</title>
+ <section id="sec-serial-temporal-locality"> 
+  <title>Serial Optimization: Temporal Locality</title>
 
   <para>
-   In the previous example, fast convolution was performed using
-   implicit data parallel operations <code>Fftm</code> and
-   <code>vmmul</code>.  However, in many situations it is necessary to
-   use explicit data parallel operations.  For example, it is possible
-   to improve cache performance by interleaving the forward FFT,
-   vector-multiply, and inverse FFT operations on a row-by-row basis.
+   Having successfully built a parallel implementation of fast
+   convolution, let's return to the single-processor case.  The code in
+   <xref linkend="sec-serial-fastconv"/>, does not take full advantage
+   of the cache.  In this section, you will learn how to improve the
+   performance of the application by improving <firstterm>temporal
+   locality</firstterm>, i.e., by making accesses to the same memory
+   locations occur near the same time.
   </para>
-   
+
   <para>
-   To illustrate how to parallelize programs with explicit loops,
-   modify the example fast convolution to improve cache locality.  Do
-   this by replacing the <code>Fftm</code> and <code>vmmul</code>
-   operators with an explicit loop that performs <code>Fft</code> and
-   <code>*</code> operations on a row-by-row basis:
+   The code in <xref linkend="sec-serial-fastconv"/> performs a FFT on
+   each row of the matrix.  Then, after all the rows have been
+   processed, it multiplies each row of the matrix by the
+   <varname>replica</varname>.  Suppose that there are a large number
+   of rows, so that <varname>data</varname> is too large to fit in
+   cache.  In that case, while the results of the first FFT will be in
+   cache immediately after the FFT is complete, that data will likey
+   have been purged from the cache by the time the vector-matrix
+   multiply needs the data.
   </para>
 
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
   <programlisting><![CDATA[  // Create the data cube.
   Matrix<value_type> data(npulse, nrange);
   Vector<value_type> tmp(nrange);            // tmp is now a vector
@@ -325,13 +418,12 @@
   }]]></programlisting>
 
   <para>
-   This new formulation trades the potential efficiency advantage
-   of performing multiple FFTs at once for improved cache temporal
-   locality of processing each row at once.  In cases where
-   <code>data</code> is too large to fit into the cache, this can 
-   improve performance.  The following figure shows
-   the performance of the original "phased" approach versus the new
-   "interleaved" approach.
+   The following graph shows that the new &quot;interleaves&quot;
+   formulation is faster than the original &quot;phased&quot; approach
+   for large data sets.  For smaller data sets (where all of the data
+   fits in the cache anyhow), the original method is faster because
+   performing all of the FFTs at once is faster than performing them
+   one by one.
   </para>
 
   <mediaobject>
@@ -339,347 +431,243 @@
       <imagedata fileref="images/par/fastconv-cache.png" format="PNG" align="center"/>
     </imageobject>
   </mediaobject>
+ </section>
 
+ <section> 
+  <title>Improving Parallel Temporal Locality</title>
+
   <para>
-   This formulation improves serial performance, but it is no longer
-   implicitly data parallel.  If the mappings from the previous
-   section are applied, the program would produce the correct output,
-   but would not deliver the expected parallel speedup.  This happens
-   because the <code>tmp</code> vector would be owned by each
-   processor.  Each processor would execute every loop iteration,
-   performing the first two operations.  Only the processor owning row
-   <code>i</code> would perform the third operation. This results in
-   unnecessary work and unnecessary communications.
+   If we apply maps (as in <xref linkend="sec-parallel-fastconv"/>),
+   but do not adjust the algorithm in use, the code in <xref
+   linkend="sec-serial-temporal-locality"/> will not run
+   faster when deployed on multiple processors.  In particular, every
+   processor will want to update <varname>tmp</varname> for every row.
+   Therefore, all processors will perform the forward FFT and
+   vector-multiply for each row of the matrix.
   </para>
 
-  <section> <title>Explicit Local Views</title>
+  <para>
+   VSIPL++ provides <firstterm>local subviews</firstterm> to solve
+   this problem.  For a given processor and view, the local subview
+   is that portion of the view located on the processor.  You can
+   obtain the local subview of any view by invoking its
+   <methodname>local</methodname> member function:
+  </para>
 
-   <para>
-    To handle explicit data parallelism it is necessary to use local
-    views.  This converts an explicit loop over distributed objects
-    into an explicit loop over local objects.
-   </para>
+  <programlisting><![CDATA[  view_type::local_type     l_data    = data.local();)]]></programlisting>
 
-   <para>
-    Start by converting the bounds of explicit loops from global
-    bounds to local bounds.  This is done by accessing the local view
-    of the global view:
-   </para>
+  <para>
+   Every view class defines a type
+   (<classname>local_type</classname>) which is the type of a local
+   subview.  The <classname>local_type</classname> is the same kind of
+   view as the view containing it, so, in this case,
+   <varname>l_data</varname> is a matrix.  There is virtually no
+   overhead in creating a local subview like
+   <varname>l_data</varname>.  In particular, no data is copied;
+   instead, <varname>l_data</varname> just refers to the local portion of
+   <varname>data</varname>.  We can now use the same cache-friendly
+   algorithm from <xref linkend="sec-serial-temporal-locality"/>on the
+   local subview: 
+  </para>
 
-   <programlisting><![CDATA[  for (index_type l_r=0; l_r < data.local().size(0); ++l_r)
-  {
-    ..
-  }]]</programlisting>
+  <programlisting><![CDATA[
+ rep_view_type::local_type l_replica = replica.local();
 
-   <para>
-    Next convert the computation to work on local views instead of
-    global views:
-   </para>
+ for (index_type l_r=0; l_r < l_data.size(0); ++l_r)
+ {
+   for_fft(l_data.row(l_r), tmp);
+   tmp *= l_replica;
+   inv_fft(tmp, l_data.row(l_r));
+ }]]></programlisting>
 
-   <programlisting><![CDATA[  for (index_type l_r=0; l_r < data.local().size(0); ++l_r)
-  {
-    for_fft(data.local().row(l_r), tmp);
-    tmp *= replica.local();
-    inv_fft(tmp, data.local().row(l_r));
-  }]]></programlisting>
+  <para>
+   Because each processor now iterates over only the rows of the
+   matrix that are local, there is no longer any duplicated effort.
+   Applying maps, as in <xref linkend="sec-parallel-fastconv"/> above,
+   results in the following complete program:
+  </para>
 
-   <para>
-    Alternatively, it is possible to create a variable holding the
-    local view:
-   </para>
+  <programlisting><xi:include href="src/par/fc2-local-views.cpp" parse="text"/> </programlisting>
 
-   <programlisting><![CDATA[  view_type::local_type     l_data    = data.local();
-  rep_view_type::local_type l_replica = replica.local();
+  <section> 
+   <title>Implicit Parallelism: Parallel Foreach</title>
 
-  for (index_type l_r=0; l_r < l_data.size(0); ++l_r)
-  {
-    for_fft(l_data.row(l_r), tmp);
-    tmp *= l_replica;
-    inv_fft(tmp, l_data.row(l_r));
-  }]]></programlisting>
-
    <para>
-    Depending on the operations performed, these two formulations have
-    nearly identical performance.  In some cases the second
-    formulation may be slightly faster because it does not have
-    to check the maps to determine if a communication is necessary.
+    You may feel that the original formulation was simpler and more
+    intuitive than the more-efficient variant using explicit loops.
+    Sourcery VSIPL++ provides an extension to the VSIPL++ API that
+    allows you to retain the elegance of that formulation while still
+    obtaining the temporal locality obtained with the style shown in
+    the previous two sections.
    </para>
 
-  </section>
-
-  <section>
-   <title>Mapping between Local and Global Indices</title>
-
    <para>
-    The transformation from explicit loops over global data to
-    explicit loops over local data also changes the loop indices from
-    global to local indices.  For the fast convolution example this is
-    not an issue since computation is not dependent on the global row
-    index.  However, in some cases the computation is dependent on the
-    global row index.  Consider a modified pulse convolution that uses
-    multiple convolution kernels.
+    In particular, Sourcery VSIPL++ provides a &quot;parallel
+    foreach&quot; operator.  This operator applies an arbitrary
+    user-defined function (or an object that behaves like a function) to
+    each of the rows or columns of a matrix.  In this section, you will
+    see how to use this approach.
    </para>
 
    <para>
-    Instead of a single kernel that is used for all pulses, assume
-    that <code>P</code> different kernels are used (with
-    <code>P</code> less than the number of pulses in
-    <code>cube</code>).  To store these, <code>replica</code> is
-    changed from a <code>Vector</code> to a <code>Matrix</code>:
+    First, declare a <classname>Fast_convolution</classname> template class.  The
+    template parameter <classname>T</classname> is used to indicate the value
+    type of the fast convolution computation (such as
+    <classname><![CDATA[complex<float>]]></classname>):
    </para>
 
-   <programlisting><![CDATA[  Matrix<value_type> replica(P, nrange);]]></programlisting>
+   <programlisting><![CDATA[template <typename T>
+ class Fast_convolution
+ {]]></programlisting>
 
    <para>
-    When performing fast convolution, the <code>(r % P)</code>th kernel is
-    used for the <code>r</code>th pulse:
+    This class will perform the forward FFT and inverse FFTs on each
+    row, so you must declare the FFTs:
    </para>
 
-   <programlisting><![CDATA[  // Perform fast convolution:
-  for (index_type r=0; r < nrange; ++r)
-  {
-    for_fft(data.row(r), tmp);
-    tmp *= replica.row(r % P);
-    inv_fft(tmp, data.row(r));
-  }]]></programlisting>
+   <programlisting><![CDATA[  typedef Fft<const_Vector, T, T, fft_fwd, by_reference> for_fft_type;
+   typedef Fft<const_Vector, T, T, fft_inv, by_reference> inv_fft_type;
 
+   Vector<T>    replica_;
+   Vector<T>    tmp_;
+   for_fft_type for_fft_;
+   inv_fft_type inv_fft_;]]></programlisting>
+
    <para>
-    Convert this to use explicit local views as before.  Use the
-    <code>global_from_local_index</code> function to convert a local
-    index to a global index:
+    Next, define a constructor for
+    <classname>Fast_convolution</classname>.  The constructor stores a
+    copy of the replica, and also uses the replica to determine the
+    number of elements required for the FFTs and temporary vector.
    </para>
 
-   <programlisting><![CDATA[  // Perform fast convolution:
-  for (index_type l_r=0; l_r < data.local().size(0); ++l_r)
-  {
-    index_type g_r = global_from_local_index(data, 0, l_r);
-    for_fft(data.local().row(l_r), tmp);
-    tmp *= replica.row(g_r % P);
-    inv_fft(tmp, data.local().row(l_r));
-  }]]></programlisting>
+   <programlisting><![CDATA[template <typename Block>
+   Fast_convolution(
+     Vector<T, Block> replica)
+     : replica_(replica.size()),
+       tmp_    (replica.size()),
+       for_fft_(Domain<1>(replica.size()), 1.0),
+       inv_fft_(Domain<1>(replica.size()), 1.0/replica.size())
+   {
+     replica_ = replica;
+   }]]></programlisting>
 
    <para>
-    <code>global_from_local_index()</code> takes three arguments.
-    First, the global view the conversion is being done for 
-    (<code>data</code> in our case).  Second, the dimension of the index
-    (<code>0</code> to indicate rows).  Finally, the local index
-    to be converted.
+    The most important part of the
+    <classname>Fast_convolution</classname> class is the
+    <code>operator()</code> function.  This function performs a fast
+    convolution for a single row of the matrix: 
    </para>
 
+   <programlisting><![CDATA[  template <typename       Block1,
+	     typename       Block2,
+	     dimension_type Dim>
+   void operator()(
+     Vector<T, Block1> in,
+     Vector<T, Block2> out,
+     Index<Dim>        /*idx*/)
+   {
+     for_fft_(in, tmp_);
+     tmp_ *= replica_;
+     inv_fft_(tmp_, out);
+   }]]></programlisting>
+
    <para>
-    In this form, <code>global_from_local_index()</code> assumes that
-    the conversion is being done for the subblock owned by the local
-    processor.  Other forms exist that take a subblock argument so
-    that global indices on other processors can be determined.
+    The <function>foreach_vector</function> template will apply the new
+    class you have just defined to the rows of the matrix: 
    </para>
 
-  </section>
- </section>
+   <programlisting><![CDATA[  Fast_convolution<value_type> fconv(replica.local());
+   foreach_vector<tuple<0, 1> >(fconv, data);]]></programlisting>
 
- <section> <title>Implicit Parallelism: Parallel Foreach</title>
+   <para>
+    The resulting program contains no explicit loops, but still has
+    good temporal locality.  Here is the complete program, using the
+    parallel foreach operator: 
+   </para>
 
-  <para>
-   An implicitly parallel alternative exists for describing the
-   interleaved computation of forward FFT, vector-multiply, and
-   inverse FFT necessary to get good temporal cache locality.
-  </para>
+   <programlisting><xi:include href="src/par/fc2-foreach.cpp" parse="text"/> </programlisting>
 
-  <para>
-   Since VSIPL++ cannot provide an infinite variety of data
-   parallel operators to anticipate every need (such as
-   Tensor Fftm or Fast_convolution_m operators), Sourcery VSIPL++
-   provides a parallel foreach operator that allows user
-   computations to be implicitly parallelized.
-  </para>
 
-  <para>
-   To use the parallel foreach operator, first encapsulate the
-   computation as a <emphasis>Functor</emphasis>, or function object.
-   A functor is an object that can be invoked like a function (using
-   the <code>operator()</code> method).  Because it is an object, it
-   can capture arguments necessary to customize its operation.  This
-   ability to capture arguments is used to pass the replica.
-  </para>
+<!--
+   <para>
+    The following graph shows that the performance obtained using the
+    parallel foreach operator is approximately the same as that
+    obtained using explicit loops:
+   </para>
 
-  <para>
-   The remainder of this section shows how to use a functor for fast
-   convolution.  First, declare a <code>Fast_convolution</code>
-   template class.  The template parameter <code>T</code> is used to
-   indicate the value type of the fast convolution computation (such
-   as <code><![CDATA[complex<float>]]></code>):
-  </para>
+   <mediaobject>
+     <imageobject>
+       <imagedata fileref="images/par/fastconv-foreach.png" format="PNG" align="center"/>
+     </imageobject>
+   </mediaobject>
+-->
 
-  <programlisting><![CDATA[template <typename T>
-class Fast_convolution
-{]]></programlisting>
-
-  <para>
-   Next, declare convenience typedefs for
-   <code>Fast_convolution</code>'s forward and inverse FFTs:
-  </para>
-
-  <programlisting><![CDATA[  typedef Fft<const_Vector, T, T, fft_fwd, by_reference> for_fft_type;
-  typedef Fft<const_Vector, T, T, fft_inv, by_reference> inv_fft_type;]]></programlisting>
-
-  <para>
-   Next, define the constructor.  It takes the replica as an argument,
-   which is used to determine the length of the fast convolution.
-   This is used to allocate storage for a copy of the replica, a
-   temporary vector, and the forward and inverse FFTs:
-  </para>
-
-  <programlisting><![CDATA[public:
-  template <typename Block>
-  Fast_convolution(
-    Vector<T, Block> replica)
-    : replica_(replica.size()),
-      tmp_    (replica.size()),
-      for_fft_(Domain<1>(replica.size()), 1.0),
-      inv_fft_(Domain<1>(replica.size()), 1.0/replica.size())
-  {
-    replica_ = replica;
-  }]]></programlisting>
-
-  <para>
-   Next, define the functor's <code>operator()</code> method.  This
-   will be invoked by the parallel foreach operator once for each row
-   of the data cube.  It performs a fast convolution on a single row:
-  </para>
-
-  <programlisting><![CDATA[  template <typename       Block1,
-            typename       Block2,
-            dimension_type Dim>
-  void operator()(
-    Vector<T, Block1> in,
-    Vector<T, Block2> out,
-    Index<Dim>        /*idx*/)
-  {
-    for_fft_(in, tmp_);
-    tmp_ *= replica_;
-    inv_fft_(tmp_, out);
-  }]]></programlisting>
-
-  <para>
-   Finally, finish up the class definition with the member data.  The
-   class needs to store the replica, a temporary vector, and the FFT
-   objects:
-  </para>
-
-  <programlisting><![CDATA[  // Member data.
-private:
-  Vector<T>    replica_;
-  Vector<T>    tmp_;
-  for_fft_type for_fft_;
-  inv_fft_type inv_fft_;
-};]]></programlisting>
-
-  <!-- <programlisting><xi:include href="src/par/fc2-fastconv-fragment.hpp" parse="text"/></programlisting> -->
-
-  <para>
-   To use the <code>Fast_convolution</code>class, first instantiate an
-   object, passing it a copy of the replica.
-  </para>
-
-  <programlisting><![CDATA[  Fast_convolution<value_type> fconv(replica.local());]]></programlisting>
-
-  <para>
-   To perform fast convolution, use <code>foreach_vector</code> to
-   apply the fast convolution functor to each row of
-   <code>data</code>:
-  </para>
-
-  <programlisting><![CDATA[  foreach_vector<tuple<0, 1> >(fconv, data);]]></programlisting>
-
-  <para>
-   The resulting program is implicitly parallel.  Moreover, it
-   maintains the cache locality of the explicit version.
-  </para>
-
-  <para>
-   The following figure compares the performance between the explicit
-   for loop and the implicit parallel foreach versions.
-  </para>
-
-  <mediaobject>
-    <imageobject>
-      <imagedata fileref="images/par/fastconv-foreach.png" format="PNG" align="center"/>
-    </imageobject>
-  </mediaobject>
+  </section>
  </section>
 
- <section>
+ <section id="sec-parallel-io">
   <title>Performing I/O</title>
 
   <para>
-   The previous sections have ignored the initialization of the data
-   cube by setting it to zero.  This section considers how
-   <code>data</code> is initialized before computation, and how it
-   used after computation.  It assumes that IO is necessary both to
-   initialize <code>data</code> before computation, and to send
-   <code>data</code> onto the subsequent processing step after.
+   The previous sections have ignored the acquisition of actual sensor
+   data by setting the input data to zero.  This section shows how to
+   initialize <code>data</code> before performing the fast convolution.
   </para>
 
-  <section> <title>Input I/O</title>
-
   <para>
-   Let's start by looking at the input half of the problem: performing
-   I/O on a single processor, then distributing the result to other
-   processors for computation.
+   Let's assume that all of the input data arrives at a single
+   processor via DMA.  This data must be distributed to the other
+   processors to perform the fast convolution.  So, the input
+   processor is special, and is not involved in the computation
+   proper.
   </para>
 
   <para>
-   First create maps for the input IO processor <code>map_in</code>
-   and the compute processors <code>map</code>.  These will be used to
-   create input and output views suitable for IO.
+   To describe this situation in Sourcery VSIPL++, you need two maps: one 
+   for the input processor (<varname>map_in</varname>), and one for
+   the compute processors (<varname>map</varname>).  These two maps
+   will be used to define views that can be used to move the data from
+   the input processor to the compute processors.  Let's assume that
+   the input processor is processor zero.  Then, create
+   <varname>map_in</varname> as follows, mapping all data to the
+   single input processor:
   </para>
 
-  <para>
-   For the input IO, create a map with 1 subblock mapped
-   explicitly to the input IO processor:
-  </para>
-
   <programlisting><![CDATA[  typedef Map<> map_type;
-
   Vector<processor_type> pvec_in(1);  pvec_in(0)  = 0;
+  map_type map_in (pvec_in,  1,  1);]]></programlisting>
 
-  // Distribute input data by row across input processors (pvec_in.size())
-  map_type map_in (pvec_in,  pvec_in.size(),  1);]]></programlisting>
-
   <para>
-   For the computation, create a map distributing rows across the
-   compute processors:
+   In contrast, <varname>map</varname> distributes rows across all of
+   the compute processors:
   </para>
 
   <programlisting><![CDATA[  // Distribute computation across all processors:
-  map_type map    (np, 1);]]></programlisting>
+  map_type map    (num_processors(), 1);]]></programlisting>
 
   <para>
-   Next, use these maps to create input and compute views,
-   <code>data_in</code> and <code>data</code> respectively:
+   Because the data will be arriving via DMA, you must explicitly
+   manage the memory used by Sourcery VSIPL++.  Each processor must allocate
+   the memory for its local portion of
+   <varname>data_in_block</varname>.  (All processors except the
+   actual input processor will allocate zero bytes, since the input
+   data is located on a single processor.)  The code required to
+   set up the views is:
   </para>
 
   <programlisting><![CDATA[  
   block_type data_in_block(npulse, nrange, NULL, map);
   view_type data_in(data_in_block);
-  view_type data   (npulse, nrange, map);]]></programlisting>
-
-  <para>
-   <code>data_in_block</code> is a user-defined storage block.  Since
-   the block is distributed, each processor should allocate and bind
-   enough memory for the subblock of the block on the local processor.
-   An easy way to determine the size of the local subblock is with the
-   <code>subblock_domain()</code> parallel support function:
-  </para>
-
-  <programlisting><![CDATA[  size_t size = subblock_domain(data_in).size();
+  view_type data   (npulse, nrange, map);
+  size_t size = subblock_domain(data_in).size();
   auto_ptr<value_type> buffer(new value_type[size]);
   data_in.block()->rebind(buffer);]]></programlisting>
 
   <para>
-   With the views in place, next perform the input I/O.  Since you
-   only want to perform this I/O on a sub-set of processors, guard the
-   I/O region with the <code>subblock()</code> parallel support
-   function:
+   Now, you can perform the actual I/O.  The I/O (including any calls
+   to low-level DMA routines) should only be performed on the input
+   processor.  The <function>subblock</function> function is used to
+   ensure that I/O is only performed on the appropriate processors:
   </para>
 
   <programlisting><![CDATA[  if (subblock(data_in) != no_subblock)
@@ -690,47 +678,34 @@
    }]]></programlisting>
 
   <para>
-   Once the I/O is completed, scatter the data from
-   <code>data_in</code> to <code>data</code> for processing:
+   Once the I/O completes, you can move the data from
+   <code>data_in</code> to <code>data</code> for processing.  In the
+   VSIPL++ API, ordinary assignment (using the <code>=</code>
+   operator) will perform all communication necessary to distribute
+   the data.  So, performing the &quot;scatter&quot; operation is
+   just:
   </para>
 
-  <programlisting><![CDATA[  data = data_in;
+  <programlisting><![CDATA[  data = data_in;]]></programlisting>
 
-  // ... process data ...]]></programlisting>
+  <para>
+   The complete program is:
+  </para>
 
-  </section>
+  <programlisting><xi:include href="src/par/fc3-io.cpp" parse="text"/></programlisting>
 
-  <section> <title>Parallel Input I/O</title>
-
   <para>
-   This fragment easily extends to handle parallel I/O.  To distribute
-   the I/O across multiple processors, add them to <code>map_in</code>'s
-   processor set <code>pvec_in</code>:
+   The technique demonstrated in this section extends easily to the
+   situation in which the sensor data is arriving at multiple
+   processors simultaneously.  To distribute the I/O across multiple
+   processors, just add them to <code>map_in</code>'s processor set
+   <code>pvec_in</code>:
   </para>
 
-  <programlisting><![CDATA[  // Create num_io_proc input processors.
-  Vector<processor_type> pvec_in(num_io_proc);
+  <programlisting><![CDATA[  Vector<processor_type> pvec_in(num_io_proc);
   pvec_in(0)              = 0;
   ...
   pvec_in(num_io_proc-1)  = ...;]]></programlisting>
 
-  <para>
-   Of course, the actual I/O needs to be cognizant of the multiple
-   processors as well.
-  </para>
-
-  </section>
-
-  <section> <title>Applying I/O to Fast Convolution</title>
-
-  <para>
-   Applying this technique to fast convolution:
-  </para>
-
-  <programlisting><xi:include href="src/par/fc3-io.cpp" parse="text"/></programlisting>
-
-  </section>
-
  </section>
-
 </chapter>
