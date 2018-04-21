Index: ChangeLog
===================================================================
--- ChangeLog	(revision 192095)
+++ ChangeLog	(working copy)
@@ -1,3 +1,15 @@
+2008-01-29  Jules Bergmann  <jules@codesourcery.com>
+
+	* doc/tutorial/performance.xml: Replace incorrect references to
+	  'Scope_event' with 'Scope'.
+	* doc/tutorial/profiling.xml: Likewise.  Move read_file example ...
+	* doc/tutorial/src/par/read_file.hpp: ... here, new file.
+	* doc/tutorial/src/par/write_file.hpp: New write file example.
+	* tests/tutorial/profile_example.cpp: New test for profile_example
+	  fragment.
+	* tests/tutorial/par_read_file.cpp: New test for {read,write}_file
+	  fragments.
+
 2008-01-28  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/fft.hpp (fftm_facade): Make friends with Diagnose_fftm.
Index: doc/tutorial/performance.xml
===================================================================
--- doc/tutorial/performance.xml	(revision 191870)
+++ doc/tutorial/performance.xml	(working copy)
@@ -467,9 +467,9 @@
       included in the accumulate mode and trace mode output.
     </para>
     <para>
-      Profiling events are recorded by constructing a <classname>Scope_event
+      Profiling events are recorded by constructing a <classname>Scope
       </classname> object.  To create a
-    <classname>Scope_event</classname>, call the 
+      <classname>Scope</classname>, call the 
       constructor, passing it a <classname>std::string</classname> that will 
       become the event tag and, optionally, an integer value expressing 
       the number of floating point operations that will be performed by 
@@ -488,7 +488,7 @@
 </programlisting>
     <para>
       Now the output has a new line that represents the time that
-      the <classname>Scope_event</classname> object exists, i.e. only while the
+      the <classname>Scope</classname> object exists, i.e. only while the
       program executes the three main steps of the fast convolution.
 
 <screen>Fast Convolution : 4256109 : 1 : 2424832 : 2046.11</screen>
Index: doc/tutorial/src/par/write_file.hpp
===================================================================
--- doc/tutorial/src/par/write_file.hpp	(revision 0)
+++ doc/tutorial/src/par/write_file.hpp	(revision 0)
@@ -0,0 +1,27 @@
+template <typename ViewT>
+void
+write_file(ViewT view, char const* filename)
+{
+  using vsip::impl::Ext_data;
+  using vsip::impl::Layout;
+  using vsip::impl::Stride_unit_dense;
+  using vsip::impl::Cmplx_inter_fmt;
+  using vsip::impl::Row_major;
+  using vsip::impl::SYNC_IN;
+
+  dimension_type const dim = ViewT::dim;
+  typedef typename ViewT::block_type block_type;
+  typedef typename ViewT::value_type value_type;
+
+  typedef Layout<dim, typename Row_major<dim>::type,
+                 Stride_unit_dense, Cmplx_inter_fmt>
+		layout_type;
+
+  Ext_data<block_type, layout_type>
+		ext(view.block(), SYNC_IN);
+
+  std::ofstream ofs(filename);
+
+  ofs.write(reinterpret_cast<char*>(ext.data()),
+	    view.size() * sizeof(value_type));
+}
Index: doc/tutorial/src/par/read_file.hpp
===================================================================
--- doc/tutorial/src/par/read_file.hpp	(revision 0)
+++ doc/tutorial/src/par/read_file.hpp	(revision 0)
@@ -0,0 +1,27 @@
+template <typename ViewT>
+void
+read_file(ViewT view, char const* filename)
+{
+  using vsip::impl::Ext_data;
+  using vsip::impl::Layout;
+  using vsip::impl::Stride_unit_dense;
+  using vsip::impl::Cmplx_inter_fmt;
+  using vsip::impl::Row_major;
+  using vsip::impl::SYNC_OUT;
+
+  dimension_type const dim = ViewT::dim;
+  typedef typename ViewT::block_type block_type;
+  typedef typename ViewT::value_type value_type;
+
+  typedef Layout<dim, typename Row_major<dim>::type,
+                 Stride_unit_dense, Cmplx_inter_fmt>
+		layout_type;
+
+  Ext_data<block_type, layout_type>
+		ext(view.block(), SYNC_OUT);
+
+  std::ifstream ifs(filename);
+
+  ifs.read(reinterpret_cast<char*>(ext.data()),
+	   view.size() * sizeof(value_type));
+}
Index: doc/tutorial/profiling.xml
===================================================================
--- doc/tutorial/profiling.xml	(revision 191870)
+++ doc/tutorial/profiling.xml	(working copy)
@@ -126,9 +126,9 @@
     <para>
       During the lifetime of the Profile object, timing data is
       stored through a simple interface provided by the 
-      <code>Scope_event</code> object.  These objects are used
+      <classname>Scope</classname> object.  These objects are used
       to profile library operations for the different areas mentioned in 
-      <xref linkend="mask-values"/> above.  Any <code>Scope_event</code>
+      <xref linkend="mask-values"/> above.  Any <classname>Scope</classname>
       objects defined in user programs fall into the 'user' category
       of events.
     </para>
@@ -137,7 +137,7 @@
       when it is destroyed, the timer is stopped.  The timing data is 
       subsequently reported when the <code>Profile</code> object is 
       destroyed.  For example:
-<screen>  impl::profile::Scope_event event("Event Tag", op_count);</screen>
+<screen>  impl::profile::Scope event("Event Tag", op_count);</screen>
       The first parameter is the tag that will be used to display the 
       event's performance data in the log file
       (<xref linkend="event-tags"/> describes the tags used 
@@ -150,13 +150,12 @@
       the average rate of computation will be shown as zero in the log.
     </para>
     <para>
-      Creating a Scope_event object on the stack is the easiest way
-      to control the region it will profile.  For example, from within
-      the body of a function (or as the entire function), use
-      this to define a region of interest:
-<programlisting><![CDATA[
-  {
-    impl::profile::Scope_event event("Main computation:");
+      Creating a <classname>Scope</classname> object on the stack is
+      the easiest way to control the region it will profile.  For
+      example, from within the body of a function (or as the entire
+      function), use this to define a region of interest:
+<programlisting><![CDATA[  {
+    impl::profile::Scope event("Main computation:");
 
     // perform main computation
     //
Index: tests/tutorial/profile_example.cpp
===================================================================
--- tests/tutorial/profile_example.cpp	(revision 0)
+++ tests/tutorial/profile_example.cpp	(revision 0)
@@ -0,0 +1,75 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/tutorial/profile_example.cpp
+    @author  Jules Bergmann
+    @date    2008-01-29
+    @brief   VSIPL++ Library: Test tutorial example for profile example.
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
+  // Views.
+  Vector<value_type> replica(nrange);
+  Matrix<value_type> data(npulse, nrange);
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
+  #include <../doc/tutorial/src/profile_example.cpp>
+}
Index: tests/tutorial/par_read_file.cpp
===================================================================
--- tests/tutorial/par_read_file.cpp	(revision 0)
+++ tests/tutorial/par_read_file.cpp	(revision 0)
@@ -0,0 +1,62 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/tutorial/par_read_file.cpp
+    @author  Jules Bergmann
+    @date    2008-01-29
+    @brief   VSIPL++ Library: Test tutorial example for read_file example.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <fstream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/selgen.hpp>
+#include <vsip/math.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/error_db.hpp>
+
+using namespace vsip;
+
+
+
+/***********************************************************************
+  Main Program
+***********************************************************************/
+
+#include <../doc/tutorial/src/par/read_file.hpp>
+#include <../doc/tutorial/src/par/write_file.hpp>
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
+  length_type size = 256;
+
+  // Views.
+  Vector<value_type> ref(size);
+  Vector<value_type> chk(size, value_type(-100));
+
+  ref = ramp<value_type>(0., 1., size);
+
+  write_file(ref, "read_file-view.raw");
+  read_file(chk, "read_file-view.raw");
+
+  float error = vsip_csl::error_db(ref, chk);
+
+  test_assert(error < -150);
+}
