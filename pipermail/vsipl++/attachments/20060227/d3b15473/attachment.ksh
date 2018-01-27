Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.398
diff -u -r1.398 ChangeLog
--- ChangeLog	23 Feb 2006 08:21:17 -0000	1.398
+++ ChangeLog	27 Feb 2006 15:05:24 -0000
@@ -1,3 +1,17 @@
+2006-02-27  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* tests/fft.cpp: Add tests for complex split format.
+	* src/vsip/impl/allocation.hpp: Make alloc_align type-safe.
+	* src/vsip/impl/aligned_allocator.hpp: Adjust accordingly.
+	* apps/sarsim/sarsim.hpp: Likewise.
+	* apps/sarsim/mit-sarsim.cpp: Likewise.
+	* apps/sarsim/chk-simd-48-4: Fix path.
+	* apps/sarsim/chk-simd-8-4: Likewise.
+	* apps/sarsim/chk-sims-48-4: Likewise.
+	* apps/sarsim/chk-sims-8-4: Likewise.
+	* src/vsip/impl/signal-fft.hpp: Use temporary buffer in SAL backend.
+	* src/vsip/impl/sal/fft.hpp: Likewise.
+
 2006-02-23  Don McCoy  <don@codesourcery.com>
 
         * src/vsip/profile.cpp: corrected cases where 'stamp_type'
Index: apps/sarsim/chk-simd-48-4
===================================================================
RCS file: /home/cvs/Repository/vpp/apps/sarsim/chk-simd-48-4,v
retrieving revision 1.1
diff -u -r1.1 chk-simd-48-4
--- apps/sarsim/chk-simd-48-4	10 Aug 2005 18:26:36 -0000	1.1
+++ apps/sarsim/chk-simd-48-4	27 Feb 2006 15:05:24 -0000
@@ -2,6 +2,8 @@
 
 # Check result of single-precision run
 
+DIR="."
+
 NRANGE=2048
 NPULSE=512
 NTAPS=48
@@ -12,22 +14,22 @@
 PREC=d
 
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   $TDIR/hh-$PREC-$NTAPS-$NFRAME.bin		\
 	-ref $TDIR/ref-$ATTR/hh-$PREC-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   $TDIR/hv-$PREC-$NTAPS-$NFRAME.bin		\
 	-ref $TDIR/ref-$ATTR/hv-$PREC-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   $TDIR/vh-$PREC-$NTAPS-$NFRAME.bin		\
 	-ref $TDIR/ref-$ATTR/vh-$PREC-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   $TDIR/vv-$PREC-$NTAPS-$NFRAME.bin		\
 	-ref $TDIR/ref-$ATTR/vv-$PREC-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
Index: apps/sarsim/chk-simd-8-4
===================================================================
RCS file: /home/cvs/Repository/vpp/apps/sarsim/chk-simd-8-4,v
retrieving revision 1.1
diff -u -r1.1 chk-simd-8-4
--- apps/sarsim/chk-simd-8-4	16 Jun 2005 18:01:20 -0000	1.1
+++ apps/sarsim/chk-simd-8-4	27 Feb 2006 15:05:24 -0000
@@ -2,6 +2,8 @@
 
 # Check result of single-precision run
 
+DIR="."
+
 NRANGE=256
 NPULSE=64
 NTAPS=8
@@ -9,22 +11,22 @@
 THRESH=-190
 
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   test-8/hh-d-$NTAPS-$NFRAME.bin		\
 	-ref test-8/ref-plain/hh-d-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   test-8/hv-d-$NTAPS-$NFRAME.bin		\
 	-ref test-8/ref-plain/hv-d-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   test-8/vh-d-$NTAPS-$NFRAME.bin		\
 	-ref test-8/ref-plain/vh-d-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   test-8/vv-d-$NTAPS-$NFRAME.bin		\
 	-ref test-8/ref-plain/vv-d-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
Index: apps/sarsim/chk-sims-48-4
===================================================================
RCS file: /home/cvs/Repository/vpp/apps/sarsim/chk-sims-48-4,v
retrieving revision 1.1
diff -u -r1.1 chk-sims-48-4
--- apps/sarsim/chk-sims-48-4	10 Aug 2005 18:26:36 -0000	1.1
+++ apps/sarsim/chk-sims-48-4	27 Feb 2006 15:05:24 -0000
@@ -2,6 +2,8 @@
 
 # Check result of single-precision run
 
+DIR="."
+
 NRANGE=2048
 NPULSE=512
 NTAPS=48
@@ -12,22 +14,22 @@
 PREC=s
 
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   $TDIR/hh-$PREC-$NTAPS-$NFRAME.bin		\
 	-ref $TDIR/ref-$ATTR/hh-$PREC-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   $TDIR/hv-$PREC-$NTAPS-$NFRAME.bin		\
 	-ref $TDIR/ref-$ATTR/hv-$PREC-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   $TDIR/vh-$PREC-$NTAPS-$NFRAME.bin		\
 	-ref $TDIR/ref-$ATTR/vh-$PREC-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   $TDIR/vv-$PREC-$NTAPS-$NFRAME.bin		\
 	-ref $TDIR/ref-$ATTR/vv-$PREC-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
Index: apps/sarsim/chk-sims-8-4
===================================================================
RCS file: /home/cvs/Repository/vpp/apps/sarsim/chk-sims-8-4,v
retrieving revision 1.2
diff -u -r1.2 chk-sims-8-4
--- apps/sarsim/chk-sims-8-4	5 Aug 2005 20:20:42 -0000	1.2
+++ apps/sarsim/chk-sims-8-4	27 Feb 2006 15:05:24 -0000
@@ -2,6 +2,8 @@
 
 # Check result of single-precision run
 
+DIR="."
+
 TDIR=test-8
 NRANGE=256
 NPULSE=64
@@ -10,22 +12,22 @@
 THRESH=-190
 
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   $TDIR/hh-s-$NTAPS-$NFRAME.bin		\
 	-ref $TDIR/ref-plain/hh-s-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   $TDIR/hv-s-$NTAPS-$NFRAME.bin		\
 	-ref $TDIR/ref-plain/hv-s-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   $TDIR/vh-s-$NTAPS-$NFRAME.bin		\
 	-ref $TDIR/ref-plain/vh-s-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
 
-histcmp -nrange $NRANGE -npulse $NPULSE			\
+$DIR/histcmp -nrange $NRANGE -npulse $NPULSE			\
 	-i   $TDIR/vv-s-$NTAPS-$NFRAME.bin		\
 	-ref $TDIR/ref-plain/vv-s-$NTAPS-$NFRAME.bin	\
 	-chk $THRESH
Index: apps/sarsim/mit-sarsim.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/apps/sarsim/mit-sarsim.cpp,v
retrieving revision 1.5
diff -u -r1.5 mit-sarsim.cpp
--- apps/sarsim/mit-sarsim.cpp	10 Sep 2005 17:59:24 -0000	1.5
+++ apps/sarsim/mit-sarsim.cpp	27 Feb 2006 15:05:24 -0000
@@ -116,8 +116,7 @@
     Vector<cval_type> v(npulse);
     v = this->azbuf_ (Domain<1>(npulse, 1, npulse));
 
-    io_type* io_buf = 
-      (io_type *)vsip::impl::alloc_align(32, 2 * npulse * sizeof (io_type));
+    io_type* io_buf =  vsip::impl::alloc_align<io_type>(32, 2 * npulse);
     vsip::Dense<1, vsip::complex<io_type> > io_block(Domain<1>(npulse), io_buf);
     vsip::Vector<vsip::complex<io_type> > io_vec(io_block);
     
Index: apps/sarsim/sarsim.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/apps/sarsim/sarsim.hpp,v
retrieving revision 1.9
diff -u -r1.9 sarsim.hpp
--- apps/sarsim/sarsim.hpp	26 Sep 2005 20:11:05 -0000	1.9
+++ apps/sarsim/sarsim.hpp	27 Feb 2006 15:05:24 -0000
@@ -251,10 +251,10 @@
 
   assert(cube_in_.block().admitted() == false);
 
-  for (index_type frame = 0; frame < nframe; ++frame) {
+  for (index_type frame = 0; frame < nframe; ++frame) 
+  {
     input_frame_buffer_[frame] =
-      static_cast<cval_type*>(alloc_align(align,
-				cube_in_.size() * sizeof(cval_type)));
+      alloc_align<cval_type>(align, cube_in_.size());
 
     cube_in_.block().rebind(input_frame_buffer_[frame]);
     cube_in_.block().admit(false);
@@ -262,8 +262,7 @@
     cube_in_.block().release(true);
 
     output_frame_buffer_[frame] =
-      static_cast<cval_type*>(alloc_align(align,
-				cube_out_.size() * sizeof(cval_type)));
+      alloc_align<cval_type>(align, cube_out_.size());
   }
 }
 
Index: src/vsip/impl/aligned_allocator.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/aligned_allocator.hpp,v
retrieving revision 1.4
diff -u -r1.4 aligned_allocator.hpp
--- src/vsip/impl/aligned_allocator.hpp	16 Sep 2005 22:03:20 -0000	1.4
+++ src/vsip/impl/aligned_allocator.hpp	27 Feb 2006 15:05:24 -0000
@@ -89,7 +89,7 @@
   pointer allocate(size_type num, const void* = 0)
   {
     // allocate aligned memory
-    pointer p = static_cast<pointer>(alloc_align(align, num*sizeof(T)));
+    pointer p = alloc_align<value_type>(align, num);
     if (p == 0)
     {
       printf("failed to allocate(%lu)\n", static_cast<unsigned long>(num));
Index: src/vsip/impl/allocation.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/allocation.hpp,v
retrieving revision 1.5
diff -u -r1.5 allocation.hpp
--- src/vsip/impl/allocation.hpp	24 Jul 2005 04:58:29 -0000	1.5
+++ src/vsip/impl/allocation.hpp	27 Feb 2006 15:05:24 -0000
@@ -73,16 +73,19 @@
 
 /// Allocate aligned memory.
 
-inline void*
+template <typename T>
+inline T*
 alloc_align(size_t align, size_t size)
 {
 #if HAVE_POSIX_MEMALIGN && !VSIP_IMPL_AVOID_POSIX_MEMALIGN
   void* ptr;
-  return (posix_memalign(&ptr, align, size) == 0) ? ptr : 0;
+  return (posix_memalign(&ptr, align, size*sizeof(T)) == 0)
+    ? static_cast<T*>(ptr)
+    : 0;
 #elif HAVE_MEMALIGN
-  return memalign(align, size);
+  return static_cast<T*>(memalign(align, size*sizeof(T)));
 #else
-  return alloc::impl_alloc_align(align, size);
+  return static_cast<T*>(alloc::impl_alloc_align(align, size*sizeof(T)));
 #endif
 }
 
Index: src/vsip/impl/signal-fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-fft.hpp,v
retrieving revision 1.30
diff -u -r1.30 signal-fft.hpp
--- src/vsip/impl/signal-fft.hpp	17 Feb 2006 20:23:44 -0000	1.30
+++ src/vsip/impl/signal-fft.hpp	27 Feb 2006 15:05:25 -0000
@@ -92,6 +92,7 @@
 
   int  stride_; // 1 for sd_ == 0, length of row for sd_ == 1.
   int  dist_;   // 1 for sd_ == 1, length of column for sd_ == 0.
+  void *buffer_;
   // used only for Fftm
   int  sd_;     // 0: compute FFTs of rows; 1: of columns
   int  runs_;   // number of 1D FFTs to perform; varies by map
Index: src/vsip/impl/sal/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/fft.hpp,v
retrieving revision 1.1
diff -u -r1.1 fft.hpp
--- src/vsip/impl/sal/fft.hpp	17 Feb 2006 20:23:44 -0000	1.1
+++ src/vsip/impl/sal/fft.hpp	27 Feb 2006 15:05:25 -0000
@@ -193,6 +193,7 @@
   VSIP_THROW((std::bad_alloc))
 {
   self.is_forward_ = (expn == -1);
+  self.buffer_ = alloc_align<typename Complex_of<inT>::type>(32, dom.size());
   unsigned long max = sal::log2n<D>::translate(dom, sd, self.size_);
   sal::fft_planner<D, inT, outT>::create(self.plan_, max);
 }
@@ -202,6 +203,7 @@
 destroy(Fft_core<D, inT, outT, doFftm>& self) VSIP_THROW((std::bad_alloc))
 {
   sal::fft_planner<D, inT, outT>::destroy(self.plan_);
+  free_align(self.buffer_);
 }
 
 inline void
@@ -266,8 +268,9 @@
 {
   FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
   float *out = reinterpret_cast<float*>(out_arg);
-  fft_ropx(&setup, const_cast<float*>(in), 1, out, 1,
-	   self.size_[0], FFT_FORWARD, sal::ESAL);
+  fft_roptx(&setup, const_cast<float*>(in), 1, out, 1,
+	    reinterpret_cast<float*>(self.buffer_),
+	    self.size_[0], FFT_FORWARD, sal::ESAL);
   // unpack the data (see SAL reference for details).
   int const N = (1 << self.size_[0]) + 2;
   out[N - 2] = out[1];
@@ -306,8 +309,9 @@
 {
   FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
   double *out = reinterpret_cast<double*>(out_arg);
-  fft_ropdx(&setup, const_cast<double*>(in), 1, out, 1,
-	    self.size_[0], FFT_FORWARD, sal::ESAL);
+  fft_ropdtx(&setup, const_cast<double*>(in), 1, out, 1,
+	     reinterpret_cast<double*>(self.buffer_),
+	     self.size_[0], FFT_FORWARD, sal::ESAL);
   // unpack the data (see SAL reference for details).
   int const N = (1 << self.size_[0]) + 2;
   out[N - 2] = out[1];
@@ -346,8 +350,9 @@
   COMPLEX *out = reinterpret_cast<COMPLEX *>(out_arg);
   long stride = 2;
   long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
-  fft_copx(&setup, in_, stride, out, stride, self.size_[0],
-	   direction, sal::ESAL);
+  fft_coptx(&setup, in_, stride, out, stride, 
+	    reinterpret_cast<COMPLEX*>(self.buffer_),
+	    self.size_[0], direction, sal::ESAL);
 }
 
 inline void
@@ -360,8 +365,9 @@
   DOUBLE_COMPLEX *out = reinterpret_cast<DOUBLE_COMPLEX *>(out_arg);
   long stride = 2;
   long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
-  fft_copdx(&setup, in_, stride, out, stride, self.size_[0],
-	    direction, sal::ESAL);
+  fft_copdtx(&setup, in_, stride, out, stride,
+	     reinterpret_cast<DOUBLE_COMPLEX*>(self.buffer_),
+	     self.size_[0], direction, sal::ESAL);
 }
 
 // 2D real -> complex forward fft
@@ -418,9 +424,10 @@
   // The size of the output array is (N/2) x M (if measured in std::complex<float>)
   unsigned long const N = (1 << self.size_[1]) + 2;
   unsigned long const M = (1 << self.size_[0]);
-  fft2d_ropx(&setup, const_cast<float*>(in), self.stride_, self.dist_,
-	     out, self.stride_, N,
-	     self.size_[1], self.size_[0], FFT_FORWARD, sal::ESAL);
+  fft2d_roptx(&setup, const_cast<float*>(in), self.stride_, self.dist_,
+	      out, self.stride_, N,
+	      reinterpret_cast<float*>(self.buffer_),
+	      self.size_[1], self.size_[0], FFT_FORWARD, sal::ESAL);
 
   // unpack the data (see SAL reference, figure 3.6, for details).
   unpack(out, N, M, self.stride_);
@@ -440,9 +447,10 @@
   // The size of the output array is (N/2) x M (if measured in std::complex<float>)
   unsigned long const N = (1 << self.size_[1]) + 2;
   unsigned long const M = (1 << self.size_[0]);
-  fft2d_ropdx(&setup, const_cast<double*>(in), self.stride_, self.dist_,
-	      out, self.stride_, N,
-	      self.size_[1], self.size_[0], FFT_FORWARD, sal::ESAL);
+  fft2d_ropdtx(&setup, const_cast<double*>(in), self.stride_, self.dist_,
+	       out, self.stride_, N,
+	       reinterpret_cast<double*>(self.buffer_),
+	       self.size_[1], self.size_[0], FFT_FORWARD, sal::ESAL);
 
   // unpack the data (see SAL reference, figure 3.6, for details).
   unpack(out, N, M, self.stride_);
@@ -527,10 +535,11 @@
   COMPLEX *out = reinterpret_cast<COMPLEX *>(out_arg);
   long stride = 2;
   long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
-  fft2d_copx(&setup, in_, stride, 2 << self.size_[1],
-	     out, stride, 2 << self.size_[1],
-	     self.size_[1], self.size_[0],
-	     direction, sal::ESAL);
+  fft2d_coptx(&setup, in_, stride, 2 << self.size_[1],
+	      out, stride, 2 << self.size_[1],
+	      reinterpret_cast<COMPLEX*>(self.buffer_),
+	      self.size_[1], self.size_[0],
+	      direction, sal::ESAL);
 }
 
 inline void
@@ -545,6 +554,7 @@
   long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
   fft2d_copdx(&setup, in_, stride, stride << self.size_[1],
 	      out, stride, stride << self.size_[1],
+	      reinterpret_cast<LONG_COMPLEX*>(self.buffer_),
 	      self.size_[1], self.size_[0],
 	      direction, sal::ESAL);
 }
@@ -571,9 +581,11 @@
     reinterpret_cast<COMPLEX *>(const_cast<std::complex<float>*>(in));
   COMPLEX *out = reinterpret_cast<COMPLEX *>(out_arg);
   long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
-  fftm_copx(&setup, in_, self.stride_, self.dist_,
-	    out, 2, 2 << self.size_[1], self.size_[1], self.runs_,
-	    direction, sal::ESAL);
+  fftm_coptx(&setup, in_, self.stride_, self.dist_,
+	     out, 2, 2 << self.size_[1],
+	     reinterpret_cast<COMPLEX*>(self.buffer_),
+	     self.size_[1], self.runs_,
+	     direction, sal::ESAL);
 }
 
 inline void
@@ -583,10 +595,11 @@
   FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
   float *out = reinterpret_cast<float*>(out_arg);
   long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
-  fftm_ropx(&setup, const_cast<float *>(in), self.stride_, self.dist_,
- 	    out, self.stride_, self.dist_ + 2,
- 	    self.size_[1], self.runs_,
- 	    direction, sal::ESAL);
+  fftm_roptx(&setup, const_cast<float *>(in), self.stride_, self.dist_,
+	     out, self.stride_, self.dist_ + 2,
+	     reinterpret_cast<float*>(self.buffer_),
+	     self.size_[1], self.runs_,
+	     direction, sal::ESAL);
   // Unpack the data (see SAL reference for details), and scale back by 1/2.
   int const N = (1 << self.size_[1]) + 2;
   float scale = 0.5f;
@@ -609,10 +622,11 @@
   DOUBLE_COMPLEX *out = reinterpret_cast<DOUBLE_COMPLEX *>(out_arg);
   long stride = 2;
   long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
-  fftm_copdx(&setup, in_, stride, stride << self.size_[1],
-	     out, stride, stride << self.size_[1],
-	     self.size_[1], 1 << self.size_[0],
-	     direction, sal::ESAL);
+  fftm_copdtx(&setup, in_, stride, stride << self.size_[1],
+	      out, stride, stride << self.size_[1],
+	      reinterpret_cast<DOUBLE_COMPLEX*>(self.buffer_),
+	      self.size_[1], 1 << self.size_[0],
+	      direction, sal::ESAL);
 }
 
 } // namespace vsip::impl
Index: tests/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft.cpp,v
retrieving revision 1.11
diff -u -r1.11 fft.cpp
--- tests/fft.cpp	17 Feb 2006 20:23:44 -0000	1.11
+++ tests/fft.cpp	27 Feb 2006 15:05:25 -0000
@@ -219,15 +219,16 @@
 
 
 
-/// Test by-reference Fft (out-of-place and in-place).
+/// Test complex by-reference Fft (out-of-place and in-place).
 
-template <typename T>
+template <typename T, typename Complex_format>
 void
-test_by_ref(int set, length_type N)
+test_complex_by_ref(int set, length_type N)
 {
-  typedef Fft<const_Vector, T, T, fft_fwd, by_reference, 1, alg_space>
+  typedef std::complex<T> CT;
+  typedef Fft<const_Vector, CT, CT, fft_fwd, by_reference, 1, alg_space>
 	f_fft_type;
-  typedef Fft<const_Vector, T, T, fft_inv, by_reference, 1, alg_space>
+  typedef Fft<const_Vector, CT, CT, fft_inv, by_reference, 1, alg_space>
 	i_fft_type;
 
   f_fft_type f_fft(Domain<1>(N), 1.0);
@@ -239,10 +240,14 @@
   test_assert(i_fft.input_size().size() == N);
   test_assert(i_fft.output_size().size() == N);
 
-  Vector<T> in(N, T());
-  Vector<T> out(N);
-  Vector<T> ref(N);
-  Vector<T> inv(N);
+  typedef impl::Fast_block<1, CT,
+    impl::Layout<1, row1_type, impl::Stride_unit_dense, Complex_format> >
+    block_type;
+
+  Vector<CT, block_type> in(N, CT());
+  Vector<CT, block_type> out(N);
+  Vector<CT, block_type> ref(N);
+  Vector<CT, block_type> inv(N);
 
   setup_data(set, in);
 
@@ -262,15 +267,16 @@
 
 
 
-/// Test by-value Fft.
+/// Test complex by-value Fft.
 
-template <typename T>
+template <typename T, typename Complex_format>
 void
-test_by_val(int set, length_type N)
+test_complex_by_val(int set, length_type N)
 {
-  typedef Fft<const_Vector, T, T, fft_fwd, by_value, 1, alg_space>
+  typedef std::complex<T> CT;
+  typedef Fft<const_Vector, CT, CT, fft_fwd, by_value, 1, alg_space>
 	f_fft_type;
-  typedef Fft<const_Vector, T, T, fft_inv, by_value, 1, alg_space>
+  typedef Fft<const_Vector, CT, CT, fft_inv, by_value, 1, alg_space>
 	i_fft_type;
 
   f_fft_type f_fft(Domain<1>(N), 1.0);
@@ -282,10 +288,14 @@
   test_assert(i_fft.input_size().size() == N);
   test_assert(i_fft.output_size().size() == N);
 
-  Vector<T> in(N, T());
-  Vector<T> out(N);
-  Vector<T> ref(N);
-  Vector<T> inv(N);
+  typedef impl::Fast_block<1, CT,
+    impl::Layout<1, row1_type, impl::Stride_unit_dense, Complex_format> >
+    block_type;
+
+  Vector<CT, block_type> in(N, CT());
+  Vector<CT, block_type> out(N);
+  Vector<CT, block_type> ref(N);
+  Vector<CT, block_type> inv(N);
 
   setup_data(set, in);
 
@@ -347,7 +357,6 @@
 
   ref = out;
   inv = i_fft(out);
-
   test_assert(error_db(inv, in) < -100);
 
   // make sure out has not been scribbled in during the conversion.
@@ -929,19 +938,27 @@
 //
 #if defined(VSIP_IMPL_FFT_USE_FLOAT)
 
-  test_by_ref<complex<float> >(2, 64);
+  test_complex_by_ref<float, impl::Cmplx_inter_fmt>(2, 64);
+  test_complex_by_ref<float, impl::Cmplx_split_fmt>(2, 64);
 #if !defined(VSIP_IMPL_SAL_FFT)
-  test_by_ref<complex<float> >(1, 68);
+  test_complex_by_ref<float, impl::Cmplx_inter_fmt>(1, 68);
+  test_complex_by_ref<float, impl::Cmplx_split_fmt>(1, 68);
 #endif
-  test_by_ref<complex<float> >(2, 256);
+  test_complex_by_ref<float, impl::Cmplx_inter_fmt>(2, 256);
+  test_complex_by_ref<float, impl::Cmplx_split_fmt>(2, 256);
 #if !defined(VSIP_IMPL_SAL_FFT)
-  test_by_ref<complex<float> >(2, 252);
-  test_by_ref<complex<float> >(3, 17);
-#endif
-
-  test_by_val<complex<float> >(1, 128);
-  test_by_val<complex<float> >(2, 256);
-  test_by_val<complex<float> >(3, 512);
+  test_complex_by_ref<float, impl::Cmplx_inter_fmt>(2, 252);
+  test_complex_by_ref<float, impl::Cmplx_split_fmt>(2, 252);
+  test_complex_by_ref<float, impl::Cmplx_inter_fmt>(3, 17);
+  test_complex_by_ref<float, impl::Cmplx_split_fmt>(3, 17);
+#endif
+
+  test_complex_by_val<float, impl::Cmplx_inter_fmt>(1, 128);
+  test_complex_by_val<float, impl::Cmplx_split_fmt>(1, 128);
+  test_complex_by_val<float, impl::Cmplx_inter_fmt>(2, 256);
+  test_complex_by_val<float, impl::Cmplx_split_fmt>(2, 256);
+  test_complex_by_val<float, impl::Cmplx_inter_fmt>(3, 512);
+  test_complex_by_val<float, impl::Cmplx_split_fmt>(3, 512);
 
   test_real<float>(1, 128);
 #if !defined(VSIP_IMPL_SAL_FFT)
@@ -953,19 +970,27 @@
 
 #if defined(VSIP_IMPL_FFT_USE_DOUBLE)
 
-  test_by_ref<complex<double> >(2, 64);
+  test_complex_by_ref<double, impl::Cmplx_inter_fmt>(2, 64);
+  test_complex_by_ref<double, impl::Cmplx_split_fmt>(2, 64);
 #if !defined(VSIP_IMPL_SAL_FFT)
-  test_by_ref<complex<double> >(1, 68);
+  test_complex_by_ref<double, impl::Cmplx_inter_fmt>(1, 68);
+  test_complex_by_ref<double, impl::Cmplx_split_fmt>(1, 68);
 #endif
-  test_by_ref<complex<double> >(2, 256);
+  test_complex_by_ref<double, impl::Cmplx_inter_fmt>(2, 256);
+  test_complex_by_ref<double, impl::Cmplx_split_fmt>(2, 256);
 #if !defined(VSIP_IMPL_SAL_FFT)
-  test_by_ref<complex<double> >(2, 252);
-  test_by_ref<complex<double> >(3, 17);
-#endif
-
-  test_by_val<complex<double> >(1, 128);
-  test_by_val<complex<double> >(2, 256);
-  test_by_val<complex<double> >(3, 512);
+  test_complex_by_ref<double, impl::Cmplx_inter_fmt>(2, 252);
+  test_complex_by_ref<double, impl::Cmplx_split_fmt>(2, 252);
+  test_complex_by_ref<double, impl::Cmplx_inter_fmt>(3, 17);
+  test_complex_by_ref<double, impl::Cmplx_split_fmt>(3, 17);
+#endif
+
+  test_complex_by_val<double, impl::Cmplx_inter_fmt>(1, 128);
+  test_complex_by_val<double, impl::Cmplx_split_fmt>(1, 128);
+  test_complex_by_val<double, impl::Cmplx_inter_fmt>(2, 256);
+  test_complex_by_val<double, impl::Cmplx_split_fmt>(2, 256);
+  test_complex_by_val<double, impl::Cmplx_inter_fmt>(3, 512);
+  test_complex_by_val<double, impl::Cmplx_split_fmt>(3, 512);
 
   test_real<double>(1, 128);
 #if !defined(VSIP_IMPL_SAL_FFT)
@@ -979,18 +1004,26 @@
 
 #if ! defined(VSIP_IMPL_IPP_FFT)
 #if !defined(VSIP_IMPL_SAL_FFT)
-  test_by_ref<complex<long double> >(2, 64);
+  test_complex_by_ref<long double, impl::Cmplx_inter_fmt>(2, 64);
+  test_complex_by_ref<long double, impl::Cmplx_split_fmt>(2, 64);
 #endif 
-  test_by_ref<complex<long double> >(1, 68);
-  test_by_ref<complex<long double> >(2, 256);
-#if !defined(VSIP_IMPL_SAL_FFT)
-  test_by_ref<complex<long double> >(2, 252);
-  test_by_ref<complex<long double> >(3, 17);
+  test_complex_by_ref<long double, impl::Cmplx_inter_fmt>(1, 68);
+  test_complex_by_ref<long double, impl::Cmplx_split_fmt>(1, 68);
+  test_complex_by_ref<long double, impl::Cmplx_inter_fmt>(2, 256);
+  test_complex_by_ref<long double, impl::Cmplx_split_fmt>(2, 256);
+#if !defined(VSIP_IMPL_SAL_FFT)
+  test_complex_by_ref<long double, impl::Cmplx_inter_fmt>(2, 252);
+  test_complex_by_ref<long double, impl::Cmplx_split_fmt>(2, 252);
+  test_complex_by_ref<long double, impl::Cmplx_inter_fmt>(3, 17);
+  test_complex_by_ref<long double, impl::Cmplx_split_fmt>(3, 17);
 #endif 
 
-  test_by_val<complex<long double> >(1, 128);
-  test_by_val<complex<long double> >(2, 256);
-  test_by_val<complex<long double> >(3, 512);
+  test_complex_by_val<long double, impl::Cmplx_inter_fmt>(1, 128);
+  test_complex_by_val<long double, impl::Cmplx_split_fmt>(1, 128);
+  test_complex_by_val<long double, impl::Cmplx_inter_fmt>(2, 256);
+  test_complex_by_val<long double, impl::Cmplx_split_fmt>(2, 256);
+  test_complex_by_val<long double, impl::Cmplx_inter_fmt>(3, 512);
+  test_complex_by_val<long double, impl::Cmplx_split_fmt>(3, 512);
 
   test_real<long double>(1, 128);
 #if !defined(VSIP_IMPL_SAL_FFT)
