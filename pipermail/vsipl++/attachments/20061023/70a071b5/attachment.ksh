Index: ChangeLog
===================================================================
--- ChangeLog	(revision 152226)
+++ ChangeLog	(working copy)
@@ -1,5 +1,23 @@
 2006-10-23  Jules Bergmann  <jules@codesourcery.com>
 
+	* GNUmakefile.in (hdr): Update to new location of src/vsip/core/fft.
+	* apps/sarsim/sarsim.cpp: Add support for parallel sarsim.
+	* apps/sarsim/sarsim.hpp: Add support for parallel sarsim (maps
+	  for data cubes), add timers.
+	* apps/sarsim/mit-sarsim.cpp: Add support for parallel sarsim.
+	* apps/sarsim/GNUmakefile (PKG): New variable, VSIPL++ pkg-config 
+	  name.
+	* apps/sarsim/histcmp.c: Fix Wall warnings.
+	* apps/sarsim/frm_hdr.c: Likewise.
+	* apps/sarsim/read_tbv.c: Likewise.
+	* apps/sarsim/util_io.c: Likewise.
+	* apps/sarsim/dat2xv.c: Likewise.
+	* apps/sarsim/sarx.h: Likewise.
+	* apps/sarsim/read_adts.c: Likewise.
+	* apps/sarsim/read_adts.h: Likewise.
+	
+2006-10-23  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/sal/eval_threshold.hpp: New file, dispatch for
 	  SAL vthres and vthr functions.
 	* src/vsip/opt/sal/bindings.hpp: Include eval_threshold.
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 152224)
+++ GNUmakefile.in	(working copy)
@@ -294,6 +294,8 @@
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/core/expr/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/core/fft/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/core/cvsip/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/core/mpi/*.hpp))
@@ -310,8 +312,6 @@
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/expr/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
-             $(wildcard $(srcdir)/src/vsip/opt/fft/*.hpp))
-hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/fftw3/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/ipp/*.hpp))
Index: apps/sarsim/sarsim.cpp
===================================================================
--- apps/sarsim/sarsim.cpp	(revision 152224)
+++ apps/sarsim/sarsim.cpp	(working copy)
@@ -6,6 +6,8 @@
     @brief   VSIPL++ implementation of RASSP benchmark 0.
 */
 
+#define PARALLEL 0
+
 #include <iostream>
 #include "sarsim.hpp"
 
@@ -31,7 +33,7 @@
 	       std::istream& in,
 	       std::ostream& out) : 
     SarSim<value_type>(nrange, npulse, ncsamples, niq, swath,
-		       w_eq, rcs, i_coef, q_coef, cphase),
+		       w_eq, rcs, i_coef, q_coef, cphase, 0),
     in_(in), out_(out) {}
 
 protected:
Index: apps/sarsim/sarsim.hpp
===================================================================
--- apps/sarsim/sarsim.hpp	(revision 152224)
+++ apps/sarsim/sarsim.hpp	(working copy)
@@ -6,6 +6,7 @@
     @brief   VSIPL++ implementation of RASSP benchmark 0.
 */
 
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
@@ -13,9 +14,14 @@
 #include <vsip/complex.hpp>
 #include <vsip/signal.hpp>
 #include <vsip/math.hpp>
+#include <vsip/map.hpp>
+#include <vsip/parallel.hpp>
 
 #include "cast-block.hpp"
 
+#define USE_SA PARALLEL
+#define VERBOSE 0
+
 /* Perform SAR processing.
 
    All input and output data is represented using single-precision
@@ -65,7 +71,15 @@
 	 io_vector_type rcs,
 	 io_vector_type i_coef,
 	 io_vector_type q_coef,
-	 cio_matrix_type cphase);
+	 cio_matrix_type cphase,
+#if PARALLEL
+	 vsip::Map<> map_in,
+	 vsip::Map<> map_rg,
+	 vsip::Map<> map_az,
+	 vsip::Map<> map_out,
+#endif
+         int /*pmode*/
+         );
   virtual ~SarSim() {}
 
   void process(index_type nframe, bool pol_on[pt_npols]);
@@ -101,6 +115,7 @@
 
   cval_split_vector_type vec_iq_;
   val_vector_type azbuf_;
+  val_vector_type azbuf2_;
 
 private:
 
@@ -129,30 +144,64 @@
     0, 
     vsip::alg_space> inv_fft_type;
 
-  typedef vsip::Dense<3, cval_type,
-		      vsip::tuple<0, 2, 1> > cube_block_type;
-  typedef vsip::Tensor<cval_type, cube_block_type> cube_type;
-  typedef typename cube_type::whole_domain_type whole_domain_type;
+  typedef vsip::whole_domain_type whole_domain_type;
 
-  typedef vsip::Dense<3, cval_type,
-		      vsip::tuple<0, 1, 2> > cube_in_block_type;
+#if PARALLEL
+  typedef vsip::Global_map<1> map_global_type;
+  typedef vsip::Map<> map_in_type;
+  typedef vsip::Map<> map_rg_type;
+  typedef vsip::Map<> map_az_type;
+  typedef vsip::Map<> map_out_type;
+#else
+  typedef vsip::Local_map map_global_type;
+  typedef vsip::Local_map map_in_type;
+  typedef vsip::Local_map map_rg_type;
+  typedef vsip::Local_map map_az_type;
+  typedef vsip::Local_map map_out_type;
+#endif
+
+  typedef vsip::Dense<1, io_type, vsip::row1_type, map_in_type>
+		 range_in_block_type;
+  typedef vsip::Vector<io_type, range_in_block_type> range_in_type;
+
+  typedef vsip::Dense<1, io_type, vsip::row1_type, map_global_type>
+		 range_global_block_type;
+  typedef vsip::Vector<io_type, range_global_block_type> range_global_type;
+
+
+  typedef vsip::Dense<3, cval_type, vsip::tuple<0, 1, 2>, map_in_type>
+		 cube_in_block_type;
   typedef vsip::Tensor<cval_type, cube_in_block_type> cube_in_type;
 
-  typedef vsip::Dense<3, cval_type,
-		      vsip::tuple<0, 2, 1> > cube_out_block_type;
+  typedef vsip::Dense<3, cval_type, vsip::tuple<0, 1, 2>, map_rg_type>
+		 cube_rg_block_type;
+  typedef vsip::Tensor<cval_type, cube_rg_block_type> cube_rg_type;
+
+  typedef vsip::Dense<3, cval_type, vsip::tuple<0, 2, 1>, map_az_type>
+		 cube_az_block_type;
+  typedef vsip::Tensor<cval_type, cube_az_block_type> cube_az_type;
+
+  typedef vsip::Dense<3, cval_type, vsip::tuple<0, 2, 1>, map_out_type>
+		 cube_img_block_type;
+  typedef vsip::Tensor<cval_type, cube_img_block_type> cube_img_type;
+
+  typedef vsip::Dense<3, cval_type, vsip::tuple<0, 2, 1>, map_out_type>
+		 cube_out_block_type;
   typedef vsip::Tensor<cval_type, cube_out_block_type> cube_out_type;
 
   typedef vsip::impl::profile::Acc_timer timer_type;
 
-  template <typename Block>
-  void read_frame(vsip::Tensor<cval_type, Block> cube_in, bool is_first);
+  template <typename Block1, typename Block2>
+  void read_frame(vsip::Tensor<cval_type, Block1> cube_in,
+		  vsip::Vector<io_type, Block2>  current_range,
+		  index_type frame);
 
   template <typename Block>
   void write_frame(vsip::Tensor<cval_type, Block> cube_out);
 
   void io_process(index_type frame);
   void range_process();
-  void azimuth_process(bool is_last);
+  void azimuth_process(index_type frame, bool is_last);
  
   // The forward FFT applied during range processing.
   for_fft_type range_fft_;
@@ -167,25 +216,35 @@
 
   // These variables are re-used during each all to process().
   io_type initial_range_;
-  io_type current_range_;
+  range_global_type current_range_;
   bool pol_on_[pt_npols];
 
   // Range processing
-  val_vector_type line_;
+  val_vector_type line1_;
+  val_vector_type line2_;
 
+  map_in_type map_in_;
+  map_rg_type map_rg_;
+  map_az_type map_az_;
+  map_out_type map_out_;
+
   // The input cube is a NPOLARITY x NPULSE x NRANGE tensor.
   //   The raw cube from disk is NPOLARIRY x NPULSE x NCSAMPLES,
   //   Range processing produces NPOLARIRY x NPULSE x NRANGE,
   // (Note: NCSAMPLES < NRANGE)
-  cube_in_block_type block_in_;
-  cube_in_type cube_in_;
+//  cube_in_block_type block_in_;
+//  cube_in_type cube_in_;
 
-  // The data cube is a NPOLARITY x 2 * NPULSE x NRANGE tensor.
-  cube_type cube_;
+  // The range cube is a NPOLARITY x NPULSE x NRANGE tensor.
+  cube_rg_block_type block_rg_;
+  cube_rg_type cube_rg_;
 
+  // The az data cube is a NPOLARITY x 2 * NPULSE x NRANGE tensor.
+  cube_az_type cube_az_;
+
   // The output cube is a NPOLARITY x NPULSE x NRANGE tensor.
-  cube_out_block_type block_out_;
-  cube_out_type cube_out_;
+  cube_img_block_type block_img_;
+  cube_img_type cube_img_;
 
   cval_type** input_frame_buffer_;
   cval_type** output_frame_buffer_;
@@ -194,6 +253,11 @@
   timer_type ap_time_;	// azimuth processing time
   timer_type proc_time_;
   timer_type ct_time_;	// corner-turn time
+  timer_type rvm1_time_;
+  timer_type rvm2_time_;
+  timer_type avm_time_;
+  int        rg_line_cnt_;
+  int        az_line_cnt_;
 };
 
 template <typename T>
@@ -206,7 +270,14 @@
 		  io_vector_type rcs,
 		  io_vector_type i_coef,
 		  io_vector_type q_coef,
-		  cio_matrix_type cphase)
+		  cio_matrix_type cphase,
+#if PARALLEL
+		  vsip::Map<> map_in,
+		  vsip::Map<> map_rg,
+		  vsip::Map<> map_az,
+		  vsip::Map<> map_out,
+#endif
+                  int /*pmode*/)
   : nrange_(nrange),
     npulse_(npulse),
     ncsamples_(ncsamples),
@@ -219,6 +290,7 @@
     cphase_(cphase),
     vec_iq_(ncsamples_),
     azbuf_(2 * npulse),
+    azbuf2_(2 * npulse),
     // Because creating an FFT may require significant computation
     // (planning), we create the FFTs before beginning the main loop.
     range_fft_(vsip::Domain<1>(nrange_), 1.f),
@@ -228,14 +300,24 @@
 	   vsip::Domain<1>(ncsamples_), 1),
     qconv_(vsip::impl::cast_view<T>(q_coef_), 
 	   vsip::Domain<1>(ncsamples_), 1),
-    line_(nrange_),
-    block_in_(vsip::Domain<3>(pt_npols, npulse_, nrange_), 
-	      static_cast<cval_type*>(0)),
-    cube_in_(block_in_),
-    cube_(pt_npols, 2 * npulse_, nrange_, 0.f),
-    block_out_(vsip::Domain<3>(pt_npols, npulse_, nrange_), 
-	      static_cast<cval_type*>(0)),
-    cube_out_(block_out_)
+    current_range_(4),
+    line1_(nrange_),
+    line2_(nrange_),
+#if PARALLEL
+    map_in_(map_in),
+    map_rg_(map_rg),
+    map_az_(map_az),
+    map_out_(map_out),
+#endif
+    block_rg_(vsip::Domain<3>(pt_npols, npulse_, nrange_), 
+	      static_cast<cval_type*>(0), map_rg_),
+    cube_rg_(block_rg_),
+    cube_az_(pt_npols, 2 * npulse_, nrange_, 0.f, map_az_),
+    block_img_(vsip::Domain<3>(pt_npols, npulse_, nrange_), 
+	       static_cast<cval_type*>(0), map_az_),
+    cube_img_(block_img_),
+    rg_line_cnt_(0),
+    az_line_cnt_(0)
 {
 }
 
@@ -249,37 +331,53 @@
   input_frame_buffer_  = new cval_type*[nframe];
   output_frame_buffer_ = new cval_type*[nframe];
 
-  assert(cube_in_.block().admitted() == false);
+  cube_in_type  cube_in(pt_npols, npulse_, ncsamples_, map_in_);
+  range_in_type current_range(nframe);
 
+  assert(cube_rg_.block().admitted() == false);
+
+  size_t in_size  = subblock_domain(cube_rg_).size()  * sizeof(cval_type);
+  size_t out_size = subblock_domain(cube_img_).size() * sizeof(cval_type);
+
   for (index_type frame = 0; frame < nframe; ++frame) 
   {
     input_frame_buffer_[frame] =
-      alloc_align<cval_type>(align, cube_in_.size());
+      alloc_align<cval_type>(align, in_size);
 
-    cube_in_.block().rebind(input_frame_buffer_[frame]);
-    cube_in_.block().admit(false);
-    read_frame<cube_in_block_type>(cube_in_, frame == 0);
-    cube_in_.block().release(true);
+    if (map_out_.subblock() != vsip::no_subblock)
+      read_frame(get_local_view(cube_in),
+		 vsip::impl::get_local_view(current_range), frame);
 
+    cube_rg_.block().rebind(input_frame_buffer_[frame]);
+    cube_rg_.block().admit(false);
+    cube_rg_(vsip::Domain<3>(pt_npols, npulse_, ncsamples_)) = cube_in;
+    cube_rg_.block().release(true);
+
     output_frame_buffer_[frame] =
-      alloc_align<cval_type>(align, cube_out_.size());
+      alloc_align<cval_type>(align, out_size);
   }
+
+  current_range_ = current_range;
 }
 
 template <typename T>
 void
 SarSim<T>::fini_io(index_type nframe) {
+  cube_out_type cube_out(pt_npols, npulse_, nrange_, map_out_);
 
   // Release the last frame of output data.
-  assert(cube_out_.block().admitted() == true);
-  cube_out_.block().release(true);
+  assert(cube_img_.block().admitted() == true);
+  cube_img_.block().release(true);
 
   // Write each frame of data to disk.
   for (index_type frame = 0; frame < nframe; ++frame) {
-    cube_out_.block().rebind(output_frame_buffer_[frame]);
-    cube_out_.block().admit(true);
-    write_frame<cube_out_block_type>(cube_out_);
-    cube_out_.block().release(false);
+    cube_img_.block().rebind(output_frame_buffer_[frame]);
+    cube_img_.block().admit(true);
+    cube_out = cube_img_;
+    cube_img_.block().release(false);
+
+    if (map_out_.subblock() != vsip::no_subblock)
+      write_frame(get_local_view(cube_out));
   }
 
   // Free up resources allocated in init_io.
@@ -293,9 +391,13 @@
 }
 
 template <typename T>
-template <typename Block>
+template <typename Block1,
+	  typename Block2>
 void 
-SarSim<T>::read_frame(vsip::Tensor<cval_type, Block> cube_in, bool is_first)
+SarSim<T>::read_frame(
+  vsip::Tensor<cval_type, Block1> cube_in,
+  vsip::Vector<io_type, Block2>  current_range,
+  index_type frame)
 {
   vsip::impl::profile::Scope_event evnt("read_frame");
 
@@ -314,9 +416,7 @@
 	// We remember the range of the first frame; during azimuth
 	// processing we use the difference from the current range to
 	// the initial range.
-	if (is_first)
-	  initial_range_ = range;
-	current_range_ = range;
+	current_range(frame) = range;
 	if (!pol_on_[pol]) 
 	    continue;
       }
@@ -335,8 +435,6 @@
   whole_domain_type whole = vsip::whole_domain;
 
   for (int pol = pt_first; pol < pt_npols; pol++) {
-    if (!pol_on_[pol]) 
-      continue;
     write_output_header(pol);
     for (index_type i=0; i < nrange_; i++) {
       azbuf_(vsip::Domain<1>(npulse_, 1, npulse_)) = cube_out(pol, whole, i);
@@ -355,9 +453,21 @@
   for (int pol = pt_first; pol < pt_npols; ++pol)
     pol_on_[pol] = pol_on[pol];
 
+#if USE_SA
+  vsip::Setup_assign corner_turn(cube_az_(second_dom), cube_rg_);
+  std::cout << "corner_turn: " << corner_turn.impl_type() << std::endl;
+#endif
+
   init_io(nframe);
 
+#if PARALLEL
   {
+    vsip::impl::profile::Scope_event evnt("start-barrier");
+    map_rg_.impl_comm().barrier();
+  }
+#endif
+
+  {
     vsip::impl::profile::Scope_timer time(proc_time_);
     vsip::impl::profile::Scope_event evnt("process");
     for (index_type frame = 0; frame < nframe; ++frame) {
@@ -365,8 +475,14 @@
       range_process();
       // FIXME: remove timer.
       { vsip::impl::profile::Scope_timer time(ct_time_);
-	cube_(second_dom) = cube_in_; }
-      azimuth_process(frame == nframe - 1);
+	vsip::impl::profile::Scope_event evnt("corner-turn");
+#if USE_SA
+	 corner_turn();
+#else
+	 cube_az_(second_dom) = cube_rg_;
+#endif
+      }
+      azimuth_process(frame, frame == nframe - 1);
     }
   }
 
@@ -380,16 +496,16 @@
   vsip::impl::profile::Scope_event evnt("input-process");
 
   // On first iteration, block will initially be released.
-  if (cube_in_.block().admitted())
-    cube_in_.block().release(false);
-  cube_in_.block().rebind(input_frame_buffer_[frame]);
-  cube_in_.block().admit(true);
+  if (cube_rg_.block().admitted())
+    cube_rg_.block().release(false);
+  cube_rg_.block().rebind(input_frame_buffer_[frame]);
+  cube_rg_.block().admit(true);
 
   // Save the last frame of output data, set up to collect next frame.
-  if (cube_out_.block().admitted())
-    cube_out_.block().release(true);
-  cube_out_.block().rebind(output_frame_buffer_[frame]);
-  cube_out_.block().admit(false);
+  if (cube_img_.block().admitted())
+    cube_img_.block().release(true);
+  cube_img_.block().rebind(output_frame_buffer_[frame]);
+  cube_img_.block().admit(false);
 }
 
 template <typename T>
@@ -404,13 +520,23 @@
   vsip::Domain<1> zero_dom(ncsamples_ - niq_, 1, 
 			   nrange_ - (ncsamples_ - niq_));
 
-  whole_domain_type whole = cube_type::whole_domain;
+  whole_domain_type whole = vsip::whole_domain;
 
+  vsip::Domain<3> g_dom = global_domain(cube_rg_);
+  typename cube_rg_type::local_type l_cube_rg = get_local_view(cube_rg_);
+
   // Read a frame of pulses.  Perform range-processing on each pulse
   // as it is read.
-  for (int pol = pt_first; pol < pt_npols; ++pol) {
-    for (index_type p=0; p < npulse_; p++) {
-      vec_iq_ = cube_in_(pol, p, vsip::Domain<1>(ncsamples_));
+  for (index_type lpol = 0; lpol<g_dom[0].size(); ++lpol) {
+    int pol = g_dom[0].impl_nth(lpol);
+#if VERBOSE
+    std::cout << "(" << map_rg_.impl_rank() << ") rg pol " << pol << "  "
+	      << get_local_view(cube_rg_(pol, 0, whole)).get(0)
+	      << std::endl;
+#endif
+    for (index_type lp = 0; lp<g_dom[1].size(); ++lp) {
+      rg_line_cnt_++;
+      vec_iq_ = l_cube_rg(lpol, lp, vsip::Domain<1>(ncsamples_));
 
       // Implement the FIR which is an upper sideband filter, and
       // zero-pad to the end (implicit because arrays are initialized to
@@ -418,29 +544,31 @@
       // main processing array, 'cbuf', as the first half holds the
       // previous frame.  (During the first frame, the first half of the
       // main processing array is 0.)
-      iconv_(vec_iq_.real(), line_(conv_dom).real());
-      qconv_(vec_iq_.imag(), line_(conv_dom).imag());
-      line_(keep_dom) *= vsip::impl::cast_view<cval_type>(w_eq_.row(pol)(keep_dom));
-      line_(zero_dom) = 0.f;
+      iconv_(vec_iq_.real(), line1_(conv_dom).real());
+      qconv_(vec_iq_.imag(), line1_(conv_dom).imag());
+      rvm1_time_.start();
+      line1_(keep_dom) *= vsip::impl::cast_view<cval_type>(w_eq_.row(pol)(keep_dom));
+      rvm1_time_.stop();
+      line1_(zero_dom) = 0.f;
       // Perform range processing on these I/Q pairs by taking their DFT.
-      range_fft_(line_);
+      range_fft_(line1_, line2_);
       // Apply RCS weighting.
-      line_ *= vsip::impl::cast_view<cval_type>(rcs_);
-      // FIXME: Why do we do a copy here?  We could just work directly
-      // on the row, couldn't we?
-      cube_in_(pol, p, whole) = line_;
+      rvm2_time_.start();
+      line2_ *= vsip::impl::cast_view<value_type>(rcs_);
+      rvm2_time_.stop();
+      l_cube_rg(lpol, lp, whole) = line2_;
     }
   }
 }
 
 template <typename T>
 void
-SarSim<T>::azimuth_process(bool is_last)
+SarSim<T>::azimuth_process(index_type frame, bool is_last)
 {
   vsip::impl::profile::Scope_timer time(ap_time_);
   vsip::impl::profile::Scope_event evnt("azimuth-process");
 
-  whole_domain_type whole = cube_type::whole_domain;
+  whole_domain_type whole = vsip::whole_domain;
 
   vsip::Domain<1> first_dom(npulse_);
   vsip::Domain<1> second_dom(npulse_, 1, npulse_);
@@ -449,31 +577,41 @@
   // azimuth processing loop.  There are 31 total kernels, a set of
   // 16 kernels covers all range gates, and kernel0 specifies which
   // subset will be used for this frame.
-  int k0 = 8 - int((initial_range_ - current_range_)/(swath_ / 16));
-  for (int pol = pt_first; pol < pt_npols; pol++) {
-    if (!pol_on_[pol]) 
-      continue;
-    for (index_type i=0; i < nrange_; i++) {
+  int k0 = 8 - int((get_local_view(current_range_)(0) -
+		    get_local_view(current_range_)(frame))/(swath_ / 16));
+  vsip::Domain<3> g_dom = global_domain(cube_az_);
+  typename cube_az_type::local_type l_cube_az   = get_local_view(cube_az_);
+  typename cube_img_type::local_type l_cube_img = get_local_view(cube_img_);
+  // for (int pol = pt_first; pol < pt_npols; ++pol) {
+  for (index_type lpol = 0; lpol<g_dom[0].size(); ++lpol) {
+#if VERBOSE
+    int pol = g_dom[0].impl_nth(lpol);
+    std::cout << "(" << map_az_.impl_rank() << ") az pol: " << pol
+	      << "  k0: " << k0
+	      << "  " << get_local_view(cube_az_(pol, whole, 0)).get(0)
+	      << std::endl;
+#endif
+    for (index_type li = 0; li<g_dom[2].size(); ++li) {
+      az_line_cnt_++;
+      int i = g_dom[2].impl_nth(li);
       // Perform DFT.
-      az_for_fft_(cube_(pol, whole, i), azbuf_);
+      az_for_fft_(l_cube_az(lpol, whole, li), azbuf_);
       // If this is not the last frame, make room for next PRI by
       // shifting the latest frame to the first half of the main
-      // processing array, and re-initializing the second half to
-      // zero.
-      if (!is_last) {
-	cube_(pol, first_dom, i) = cube_(pol, second_dom, i);
-	// unncessary to zero out second half, will be set next frame.
-      }
+      // processing array.
+      if (!is_last)
+	l_cube_az(lpol, first_dom, li) = l_cube_az(lpol, second_dom, li);
       // Multiply DFT result by appropriate convolution
       // kernel. (Kernels were already transformed during
       // initialization.) 
+      avm_time_.start();
       azbuf_ *= vsip::impl::cast_view<cval_type>
 	(cphase_.row(k0 + i * 16 / nrange_));
+      avm_time_.stop();
       // Perform IDFT.
-      az_inv_fft_(azbuf_);
+      az_inv_fft_(azbuf_, azbuf2_);
       // Write the second half of this range cell to file.
-      cube_out_(pol, whole, i) = azbuf_(vsip::Domain<1>(npulse_, 1, npulse_));
-
+      l_cube_img(lpol, whole, li) = azbuf2_(second_dom);
     }
   }
 }
@@ -487,37 +625,44 @@
   //     foreach pulse (npulse_)
   //       - 1 x FFT(nrange): 5 * nrange * log(nrange)
   //       - 2 x conv       : 2 * (ncsamples-niq) * niq
+  //       - 1 x vmul       : 6 * ncsamples_ - niq_ (*)
   //       - 1 x vmul       : 6 * nrange
-  //       - 1 x vmul       : 6 * ncsamples_ - niq_ (*)
 
-  float rp_ops_frame = 
-    pt_npols * npulse_ * (
-      1 * 5 * nrange_ * log(nrange_) / log(2.f) +
+  float rp_ops = 
+    rg_line_cnt_ * (
+      1 * 5 * nrange_ * log((float)nrange_) / log(2.f) +
       2 * 2 * (ncsamples_ - niq_) * niq_ +
-      1 * 6 * nrange_ );
+      1 * 6 * (nrange_ - niq_) +
+      1 * 6 * nrange_  );
 
+  float rvm1_ops = rg_line_cnt_ * ( 1 * 6 * (nrange_ - niq_) );
+  float rvm2_ops = rg_line_cnt_ * ( 1 * 6 * nrange_ );
+
   // On each azimuth processing frame, we do:
   //   foreach polariy (pt_npols)
   //     foreach range cell (nrange_)
   //       - 2 x FFT(2*npulse): 5 * 2*npulse * log(2*npulse)
   //       - 1 x vmul         : 6 * 2*npulse
 
-  float ap_ops_frame =
-    pt_npols * nrange_ * (
-      2 * 5 * 2*npulse_ * log(2*npulse_) / log(2.f) +
+  float ap_ops =
+    az_line_cnt_ * (
+      2 * 5 * 2*npulse_ * log(2.f*npulse_) / log(2.f) +
       1 * 6 * 2*npulse_);
 
+  float avm_ops = az_line_cnt_ * ( 1 * 6 * 2*npulse_ );
 
   // Compute mflops.
   // Timers rp_time_ and ap_time_ are triggered once per frame, so
   // rp_time_.count() == nframe.
 
-  float rp_mflops = rp_ops_frame * rp_time_.count() / (1e6 * rp_time_.total());
-  float ap_mflops = ap_ops_frame * ap_time_.count() / (1e6 * ap_time_.total());
-  float proc_mflops = 
-    (rp_ops_frame * rp_time_.count() + ap_ops_frame * ap_time_.count()) /
-    (1e6 * proc_time_.total());
+  float rp_mflops = rp_ops /* * rp_time_.count() */ / (1e6 * rp_time_.total());
+  float ap_mflops = ap_ops /* * ap_time_.count() */ / (1e6 * ap_time_.total());
+  float proc_mflops = (rp_ops + ap_ops) / (1e6 * proc_time_.total());
 
+  float rvm1_mflops = rvm1_ops / (1e6 * rvm1_time_.total());
+  float rvm2_mflops = rvm2_ops / (1e6 * rvm2_time_.total());
+  float avm_mflops  = avm_ops  / (1e6 * avm_time_.total());
+
   printf("Total Processing  : %7.2f mflops (%6.2f s)\n",
 	 proc_mflops, proc_time_.total());
   printf("  corner-turn     :                (%6.2f s)\n",
@@ -543,4 +688,9 @@
   printf("   az inv fft     : %7.2f mflops (%6.2f s)\n",
 	 az_inv_fft_.impl_performance("mops"),
 	 az_inv_fft_.impl_performance("time"));
+
+  printf("\n");
+  printf("  rvm1            : %7.2f mflops (%6.2f s)\n", rvm1_mflops, rvm1_time_.total());
+  printf("  rvm2            : %7.2f mflops (%6.2f s)\n", rvm2_mflops, rvm2_time_.total());
+  printf("  avm             : %7.2f mflops (%6.2f s)\n", avm_mflops, avm_time_.total());
 }
Index: apps/sarsim/histcmp.c
===================================================================
--- apps/sarsim/histcmp.c	(revision 152224)
+++ apps/sarsim/histcmp.c	(working copy)
@@ -30,12 +30,11 @@
 
 #define min(a,b) ((a)<(b)?(a):(b))
 
-main(argc,argv)
-int	argc;
-char	**argv;
+int
+main(int argc, char** argv)
 {
 	FILE		*fpin=NULL, *fpref=NULL;
-	int		i, j, k, frame_size, data_size, index, pol;
+	int		i, j, k, frame_size, index, pol;
 	int		frm_cmp1=1, frm_cmp2=1;
 	float		val, sum, sq_ang;
 	int		hist[201], x1[201];
Index: apps/sarsim/frm_hdr.c
===================================================================
--- apps/sarsim/frm_hdr.c	(revision 152224)
+++ apps/sarsim/frm_hdr.c	(working copy)
@@ -25,6 +25,7 @@
 #include <stdio.h>
 #include <math.h>
 #include "sarx.h"
+#include "read_adts.h"
 #include "util_io.h"
 
 int
@@ -34,9 +35,9 @@
    int		*pol,
    float	*sq_ang)
 {
-	float		rlos=0., heading=0., aty, dx, dy,
+	float		rlos=0., heading=0., dx, dy,
 				vnms, vems, pnms, pems, trgn, trge;
-	int		i, k, rval, word;
+	int		i, rval, word;
 	float		pi = 3.14159265358979323846;
 /**
 Perform barker code detection.
Index: apps/sarsim/mit-sarsim.cpp
===================================================================
--- apps/sarsim/mit-sarsim.cpp	(revision 152224)
+++ apps/sarsim/mit-sarsim.cpp	(working copy)
@@ -6,8 +6,11 @@
     @brief   VSIPL++ implementation of RASSP benchmark 0.
 */
 
+#define PARALLEL 1
+
 #include <cstdio>
 #include <cstring>
+#include <errno.h>
 
 extern "C" {
 #include "sarx.h"
@@ -27,7 +30,7 @@
 using vsip::complex;
 using vsip::impl::cast_view;
 
-#define ENABLE_DOUBLE 1
+#define ENABLE_DOUBLE 0
 
 template <typename T>
 class MITSarSim : public SarSim<T> {
@@ -47,11 +50,22 @@
 	    Vector<io_type> i_coef,
 	    Vector<io_type> q_coef,
 	    Matrix<cio_type> cphase,
+#if PARALLEL
+	    vsip::Map<> map_in,
+	    vsip::Map<> map_rg,
+	    vsip::Map<> map_az,
+	    vsip::Map<> map_out,
+#endif
+	    int pmode,
 	    unsigned itype,
 	    FILE *fpin,
 	    FILE **fpout) : 
     SarSim<T>(nrange, npulse, ncsamples, niq, swath,
-	      w_eq, rcs, i_coef, q_coef, cphase),
+	      w_eq, rcs, i_coef, q_coef, cphase, 
+#if PARALLEL
+	      map_in, map_rg, map_az, map_out,
+#endif
+	      pmode),
     itype_ (itype),
     fpin_ (fpin),
     fpout_ (fpout)
@@ -148,7 +162,9 @@
    int	argc,
    char	**argv)
 {
-  FILE		*fpin, *fpeq, *fpkrn, *fprcs, *fpiqe, *fpiqo;
+  vsip::vsipl init(argc, argv);
+
+  FILE		*fpin, *fpeq;
   FILE		*fpout[4];
   int		i, j;
   float		swath;
@@ -171,6 +187,7 @@
 
   int		use_single = 1; // using single floating-point precision.
   bool		profile = false;
+  int		pmode = 1;
 
   pol_on[HH] = 1;
   pol_on[HV] = 0;
@@ -240,12 +257,7 @@
     {
       if (++i < argc)
       {
-	if (!(fpout[HH]=fopen(argv[i],"w")))
-	{
-	  fprintf(stderr,"Can't create output file %s\n",argv[i]);
-	  exit(1);
-	}
-	else strcpy(fnouthh, argv[i]);
+	strcpy(fnouthh, argv[i]);
       }
       else fprintf(stderr, "Invalid value for option %s\n",argv[i-1]);
     }
@@ -253,12 +265,7 @@
     {
       if (++i < argc)
       {
-	if (!(fpout[HV]=fopen(argv[i],"w")))
-	{
-	  fprintf(stderr,"Can't create output file %s\n",argv[i]);
-	  exit(1);
-	}
-	else strcpy(fnouthv, argv[i]);
+	strcpy(fnouthv, argv[i]);
       }
       else fprintf(stderr, "Invalid value for option %s\n",argv[i-1]);
     }
@@ -266,12 +273,7 @@
     {
       if (++i < argc)
       {
-	if (!(fpout[VH]=fopen(argv[i],"w")))
-	{
-	  fprintf(stderr,"Can't create output file %s\n",argv[i]);
-	  exit(1);
-	}
-	else strcpy(fnoutvh, argv[i]);
+	strcpy(fnoutvh, argv[i]);
       }
       else fprintf(stderr, "Invalid value for option %s\n",argv[i-1]);
     }
@@ -279,12 +281,7 @@
     {
       if (++i < argc)
       {
-	if (!(fpout[VV]=fopen(argv[i],"w")))
-	{
-	  fprintf(stderr,"Can't create output file %s\n",argv[i]);
-	  exit(1);
-	}
-	else strcpy(fnoutvv, argv[i]);
+	strcpy(fnoutvv, argv[i]);
       }
       else fprintf(stderr, "Invalid value for option %s\n",argv[i-1]);
     }
@@ -308,12 +305,7 @@
     {
       if (++i < argc)
       {
-	if (!(fpiqe=fopen(argv[i],"r")))
-	{
-	  fprintf(stderr,"Can't find input file %s\n",argv[i]);
-	  exit(1);
-	}
-	else strcpy(fniqe, argv[i]);
+	strcpy(fniqe, argv[i]);
       }
       else fprintf(stderr, "Invalid value for option %s\n",argv[i-1]);
     }
@@ -321,12 +313,7 @@
     {
       if (++i < argc)
       {
-	if (!(fpiqo=fopen(argv[i],"r")))
-	{
-	  fprintf(stderr,"Can't find input file %s\n",argv[i]);
-	  exit(1);
-	}
-	else strcpy(fniqo, argv[i]);
+	strcpy(fniqo, argv[i]);
       }
       else fprintf(stderr, "Invalid value for option %s\n",argv[i-1]);
     }
@@ -334,12 +321,7 @@
     {
       if (++i < argc)
       {
-	if (!(fpkrn=fopen(argv[i],"r")))
-	{
-	  fprintf(stderr,"Can't find input file %s\n",argv[i]);
-	  exit(1);
-	}
-	else strcpy(fnkrn, argv[i]);
+	strcpy(fnkrn, argv[i]);
       }
       else fprintf(stderr, "Invalid value for option %s\n",argv[i-1]);
     }
@@ -347,12 +329,7 @@
     {
       if (++i < argc)
       {
-	if (!(fprcs=fopen(argv[i],"r")))
-	{
-	  fprintf(stderr,"Can't find input file %s\n",argv[i]);
-	  exit(1);
-	}
-	else strcpy(fnrcs, argv[i]);
+	strcpy(fnrcs, argv[i]);
       }
       else fprintf(stderr, "Invalid value for option %s\n",argv[i-1]);
     }
@@ -426,6 +403,7 @@
     else if (!strcmp(argv[i], "-double"))    use_single = 0;
     else if (!strcmp(argv[i], "-profile"))   profile    = true;
     else if (!strcmp(argv[i], "-noprofile")) profile    = false;
+    else if (!strcmp(argv[i], "-par"))       pmode      = atoi(argv[++i]);
     else
     {fprintf(stderr, "Invalid option: %s Do `sarsim -help' for option list\n",argv[i]);
       exit(1);
@@ -434,7 +412,7 @@
 
   ncsamples = nrange-16;
 
-  printf("VPP (%d, %d).\n", nrange, npulse);
+  printf("VPP (%d, %d) %d.\n", nrange, npulse, pmode);
 
 /**
 Define other parameters.
@@ -445,7 +423,7 @@
   {   
     if (!(fpout[HH] = fopen(fnouthh,"w")))
     {
-      fprintf(stderr,"Error opening HH output file.\n");
+      fprintf(stderr,"Error opening HH output file '%s'.\n", fnouthh);
       exit(1);
     }
   }
@@ -453,7 +431,7 @@
   {   
     if (!(fpout[HV] = fopen(fnouthv,"w")))
     {
-      fprintf(stderr,"Error opening HV output file.\n");
+      fprintf(stderr,"Error opening HV output file '%s'.\n", fnouthv);
       exit(1);
     }
   }
@@ -461,7 +439,7 @@
   {   
     if (!(fpout[VH] = fopen(fnoutvh,"w")))
     {
-      fprintf(stderr,"Error opening VH output file.\n");
+      fprintf(stderr,"Error opening VH output file '%s'.\n", fnoutvh);
       exit(1);
     }
   }
@@ -469,7 +447,8 @@
   {   
     if (!(fpout[VV] = fopen(fnoutvv,"w")))
     {
-      fprintf(stderr,"Error opening VV output file.\n");
+      fprintf(stderr, "Error opening VV output file '%s': %s\n",
+	      fnoutvv, strerror(errno));
       exit(1);
     }
   }
@@ -541,6 +520,100 @@
     exit(1);
   }
 
+#if PARALLEL
+  using vsip::Map;
+  using vsip::Block_dist;
+  using vsip::Vector;
+  using vsip::processor_type;
+
+  vsip::processor_type np = vsip::num_processors();
+
+  Map<> map_in;
+  Map<> map_rg;
+  Map<> map_az;
+  Map<> map_out;
+
+  Map<> root_map(Block_dist(1),  Block_dist(1),  Block_dist(1));
+  Map<> map_pols(Block_dist(np), Block_dist(1),  Block_dist(1));
+
+//  Map<> map_pols_core(pset_core, Block_dist(pset_core.size()), Block_dist(1),  Block_dist(1));
+//  Map<> map_pulse(Block_dist(1),  Block_dist(np), Block_dist(1));
+//  Map<> map_range(Block_dist(1),  Block_dist(1),  Block_dist(np));
+//  Map<> map_proc0(pset0, Block_dist(1),  Block_dist(1),  Block_dist(1));
+//  Map<> map_proc1(pset1, Block_dist(1),  Block_dist(1),  Block_dist(1));
+//  Map<> map_procN(psetN, Block_dist(1),  Block_dist(1),  Block_dist(1));
+
+  if (pmode == 1)
+  {
+    map_in  = root_map;
+    map_rg  = map_pols;
+    map_az  = map_pols;
+    map_out = root_map;
+  }
+  else if (pmode == 2)
+  {
+    Map<> map_pulse(Block_dist(1),  Block_dist(np), Block_dist(1));
+    Map<> map_range(Block_dist(1),  Block_dist(1),  Block_dist(np));
+
+    map_in  = root_map;
+    map_rg  = map_pulse;
+    map_az  = map_range;
+    map_out = root_map;
+  }
+  else if (pmode == 3)
+  {
+    assert(np > 1 && np % 2 == 0);
+
+    Vector<processor_type> pset_pulse(np/2);
+    Vector<processor_type> pset_range(np/2);
+
+    for (processor_type i=0; i<np/2; ++i)
+    {
+      pset_pulse(i) = i;
+      pset_range(i) = np/2 + i;
+    }
+
+    Map<> map_pulse(pset_pulse,
+		    Block_dist(1), Block_dist(np/2), Block_dist(1) );
+    Map<> map_range(pset_range,
+		    Block_dist(1), Block_dist(1), Block_dist(np/2));
+
+    map_in  = root_map;
+    map_rg  = map_pulse;
+    map_az  = map_range;
+    map_out = root_map;
+  }
+  else if (pmode == 4)
+  {
+    assert(np > 1 && np % 2 == 0);
+
+    Vector<processor_type> pset_pulse(np/2);
+    Vector<processor_type> pset_range(np/2);
+
+    for (processor_type i=0; i<np/2; ++i)
+    {
+      pset_pulse(i) = i;
+      pset_range(i) = np/2 + i;
+    }
+
+    Map<> map_rg(pset_pulse,
+		 Block_dist(np/2), Block_dist(1), Block_dist(1) );
+    Map<> map_az(pset_range,
+		 Block_dist(np/2), Block_dist(1), Block_dist(1));
+
+    map_in  = root_map;
+    map_rg  = map_rg;
+    map_az  = map_az;
+    map_out = root_map;
+  }
+  else { assert(0); }
+#else
+  vsip::Local_map map_in;
+  vsip::Local_map map_rg;
+  vsip::Local_map map_az;
+  vsip::Local_map map_out;
+#endif
+
   if (profile)
   {
     vsip::impl::profile::prof->set_mode(vsip::impl::profile::pm_trace);
@@ -552,6 +625,10 @@
 			 w_eq,
 			 rcs_file.view(), Icoef, Qcoef,
 			 cphase_file.view (),
+#if PARALLEL
+			 map_in, map_rg,map_az, map_out,
+#endif
+			 pmode,
 			 itype, fpin, fpout);
     
     mss.process(nframe, pol_on);
@@ -562,12 +639,13 @@
 			  w_eq,
 			  rcs_file.view(), Icoef, Qcoef,
 			  cphase_file.view (),
+			  map_in, map_rg,map_az, map_out, pmode,
 			  itype, fpin, fpout);
     
     mss.process(nframe, pol_on);
     mss.report_performance();
 #else
-    throw(vsip::impl::unimplemented(
+    VSIP_IMPL_THROW(vsip::impl::unimplemented(
 	     "Support for double precision not enabled"));
 #endif
   }
Index: apps/sarsim/read_tbv.c
===================================================================
--- apps/sarsim/read_tbv.c	(revision 152224)
+++ apps/sarsim/read_tbv.c	(working copy)
@@ -28,7 +28,9 @@
 #include "util_io.h"
 
 void	conv2adts();
+int find_fillcount(FILE* fp);
 
+
 #define LIMIT	15000	/* Max number of words before quitting search
 				for Barker Code */
 
@@ -152,8 +154,7 @@
 }
 
 int
-find_fillcount(fp)
-FILE	*fp;
+find_fillcount(FILE* fp)
 {
 	int	word, ncount=0;
 
Index: apps/sarsim/util_io.c
===================================================================
--- apps/sarsim/util_io.c	(revision 152224)
+++ apps/sarsim/util_io.c	(working copy)
@@ -13,7 +13,11 @@
 
 #include <stdio.h>
 #include <assert.h>
-#include <netinet/in.h>
+#ifdef _MC_EXEC
+#  include <sys/socket.h>
+#else
+#  include <netinet/in.h>
+#endif
 
 #include "util_io.h"
 
@@ -36,7 +40,6 @@
       }
    else if (size == 2) {
       uint16_t *sptr = (uint16_t*)ptr;
-      uint16_t *sbuf = (uint16_t*)bs_buf;
 
       // reorder data (in-place).
       for (i=0; i<nmemb; ++i)
@@ -68,6 +71,7 @@
    else {
       assert(0);
       }
+   return 0;
 }
 
 
@@ -121,6 +125,7 @@
    else {
       assert(0);
       }
+   return 0;
 }
 
 
@@ -157,6 +162,7 @@
       return rv;
       }
    else assert(0);
+   return 0;
 }
 
 
@@ -197,4 +203,5 @@
       return rv;
       }
    else assert(0);
+   return 0;
 }
Index: apps/sarsim/GNUmakefile
===================================================================
--- apps/sarsim/GNUmakefile	(revision 152224)
+++ apps/sarsim/GNUmakefile	(working copy)
@@ -9,8 +9,9 @@
 ########################################################################
 
 PGM = sarsim
+PKG = vsipl++
 
-CXX      := $(shell pkg-config --variable=cxx vsipl++)
+CXX      := $(shell pkg-config --variable=cxx $(PKG))
 
 IOPT =  --param max-inline-insns-single=2000	\
 	--param large-function-insns=6000	\
@@ -21,7 +22,10 @@
 OPT2	:= -O2 -funswitch-loops -fgcse-after-reload -DNDEBUG
 OPT3	:= -O2 -funswitch-loops -fgcse-after-reload $(IOPT) -DNDEBUG
 
-OPT     := $(shell pkg-config --variable=cxxflags vsipl++)
+OPT     := $(shell pkg-config --variable=cxxflags $(PKG))
+ifeq ($(O),1)
+  OPT := $(OPT1)
+endif
 ifeq ($(O),2)
   OPT := $(OPT2)
 endif
@@ -29,10 +33,10 @@
   OPT := $(OPT3)
 endif
 
-CXXFLAGS := $(shell pkg-config --cflags vsipl++) $(OPT)
+CXXFLAGS := $(shell pkg-config --cflags $(PKG)) $(OPT)
 CFLAGS   := $(CXXFLAGS)
 
-LIBS     := $(shell pkg-config --libs   vsipl++)
+LIBS     := $(shell pkg-config --libs   $(PKG))
 
 OBJEXT   := o
 
Index: apps/sarsim/dat2xv.c
===================================================================
--- apps/sarsim/dat2xv.c	(revision 152224)
+++ apps/sarsim/dat2xv.c	(working copy)
@@ -44,14 +44,16 @@
 		range =		100.;	/** Range of all pixel values in dB **/
 
 
+int
 main(argc,argv)
 int	argc;
 char	**argv;
 {
 	FILE		*fpin=NULL, *fpout=stdout;
-	int		swidth, sheight, psize;
+	size_t		psize;
+	int		swidth, sheight;
 	int		i, j, k, l, m, i4, pol, frame=0, nstrip, tstrip, fsize, itmp1, itmp2;
-	float		*sum, mag, sq_ang, xf, yf, pi=3.14159265358979323846;
+	float		*sum, mag, sq_ang, xf, yf;
 	short int	aux[NAUX];		/* Aux info array	*/
 	Fcomplex	cbuf[MAXPULSE];		/* SAR frame holder	*/
 
Index: apps/sarsim/sarx.h
===================================================================
--- apps/sarsim/sarx.h	(revision 152224)
+++ apps/sarsim/sarx.h	(working copy)
@@ -26,7 +26,11 @@
 #ifndef __sarx_h
 #define __sarx_h
 
-#include <malloc.h>
+#if _MC_EXEC
+#  include <exec/sys/stdlib.h>
+#else
+#  include <malloc.h>
+#endif
 #include <stdlib.h>
 #include <math.h>
 
@@ -100,12 +104,6 @@
 #define array2i(m,n)		(int **) array2(m,n,sizeof(int))
 
 
-/**
-Minimum and maximum functions:
-**/
-#define min(a,b)	((a<b)?(a):(b))
-#define max(a,b)	((a>b)?(a):(b))
-
 /** Signal Processing **/
 
 void
Index: apps/sarsim/read_adts.c
===================================================================
--- apps/sarsim/read_adts.c	(revision 152224)
+++ apps/sarsim/read_adts.c	(working copy)
@@ -37,8 +37,11 @@
 #include "read_adts.h"
 #include "util_io.h"
 
+#define max(a,b) ((a)>(b)?(a):(b))
+
 #define LIMIT	15000	/* Max number of words before quitting search
 				for Barker Code */
+
 	
 /**
 Function to read one polarization of data.
@@ -140,7 +143,7 @@
 			    }
 			    else
 			    {   fprintf(stderr,
-				    "Cannot determine pole, id=%04x\n", header);
+					"Cannot determine pole, id=%04x\n", (unsigned)header);
 				fprintf(stderr,"Rechecking...\n");
 				id = idcheck(header);
 				if (id<0)
@@ -198,8 +201,7 @@
 allows the code to be compatible with older forms of input data.
 **/
 int
-cmp_barker(fp)
-FILE	*fp;
+cmp_barker(FILE* fp)
 {
 	int	word, ncount=0, wsize=sizeof(int), buf[2], state=0;
 /**
@@ -440,8 +442,7 @@
 }
 
 int
-idcheck(hdr)
-unsigned short	hdr;
+idcheck(unsigned short hdr)
 {
 	int	i, pol0, pol1, pol2, pol3, maxpol=-1;
 
Index: apps/sarsim/read_adts.h
===================================================================
--- apps/sarsim/read_adts.h	(revision 152224)
+++ apps/sarsim/read_adts.h	(working copy)
@@ -17,4 +17,7 @@
    int		pol,
    int		ncsamples);
 
+int cmp_barker(FILE* fp);
+int idcheck(unsigned short hdr);
+
 #endif // _SARSIM_READ_ADTS_H_
