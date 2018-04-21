Index: src/vsip/impl/signal-fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-fft.hpp,v
retrieving revision 1.30
diff -u -r1.30 signal-fft.hpp
--- src/vsip/impl/signal-fft.hpp	17 Feb 2006 20:23:44 -0000	1.30
+++ src/vsip/impl/signal-fft.hpp	24 Feb 2006 22:24:26 -0000
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
+++ src/vsip/impl/sal/fft.hpp	24 Feb 2006 22:24:26 -0000
@@ -193,6 +193,7 @@
   VSIP_THROW((std::bad_alloc))
 {
   self.is_forward_ = (expn == -1);
+  self.buffer_ = new Complex_of<inT>::type[dom.size()];
   unsigned long max = sal::log2n<D>::translate(dom, sd, self.size_);
   sal::fft_planner<D, inT, outT>::create(self.plan_, max);
 }
@@ -202,6 +203,7 @@
 destroy(Fft_core<D, inT, outT, doFftm>& self) VSIP_THROW((std::bad_alloc))
 {
   sal::fft_planner<D, inT, outT>::destroy(self.plan_);
+  delete [] self.buffer_;
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
+++ tests/fft.cpp	24 Feb 2006 22:24:27 -0000
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
