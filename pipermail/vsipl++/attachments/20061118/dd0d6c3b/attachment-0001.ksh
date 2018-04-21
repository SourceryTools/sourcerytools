Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 155042)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -268,7 +268,6 @@
   complex_col_matrix_type s_filt_;
   complex_matrix_type s_filt_t_;
   complex_matrix_type s_compr_filt_;
-  Vector<complex<T> > s_compr_row_;
   Vector<complex<T> > fs_row_;
   Vector<complex<T> > fs_padded_row_;
   complex_matrix_type s_decompr_filt_;
@@ -276,12 +275,10 @@
   Matrix<index_type> icKX_;
 //  real_vector_type x_;
   real_vector_type KX0_;
-  real_matrix_type KX_;
+//  real_matrix_type KX_;
   Tensor<T> SINC_HAM_;
   complex_matrix_type F_;
   complex_col_matrix_type F_shifted_;
-  complex_matrix_type tmp_;
-  Vector<complex<T> > tmp_col_;
   complex_matrix_type spatial_;
   real_matrix_type image_t_;
 
@@ -302,7 +299,6 @@
     s_filt_(n, mc),
     s_filt_t_(n, mc),
     s_compr_filt_(n, mc),
-    s_compr_row_(mc),
     fs_row_(mc),
     fs_padded_row_(m),
     s_decompr_filt_(n, m),
@@ -310,16 +306,14 @@
     icKX_(n, m),
 //    x_(this->nx_),
     KX0_(this->nx_),
-    KX_(this->nx_, m_),
+//    KX_(this->nx_, m_),
     SINC_HAM_(n_, m_, this->I_),
     F_(this->nx_, m_),
     F_shifted_(this->nx_, m_),
-    tmp_(this->nx_, m_),
-    tmp_col_(n_),
     spatial_(this->nx_, m_),
     image_t_(this->nx_, m_),
     col_fft_(Domain<1>(n), T(1)),
-    row_fft_(Domain<1>(mc), T(1)),
+    row_fft_(Domain<1>(mc), static_cast<T>(m_) / mc_),
     row_fft2_(Domain<1>(m), T(1)),
     ifft_(Domain<1>(m), T(1.f/m)),
     ifftmr_(Domain<2>(this->nx_, m_), T(1./m_)),
@@ -333,17 +327,18 @@
 
   // 84. (scalar, real) carrier frequency in KX domain, where (nx/2+1) 
   //     is its index number
-  T kxc = KX0_.get(this->nx_ / 2);
+//  T kxc = KX0_.get(this->nx_ / 2);
 
   // 85. KX0 (1 by nx array of reals) is expanded to the SAR image's 
   //     final dims of (nx by m array of reals).
-  KX_ = vmmul<col>(KX0_, real_matrix_type(this->nx_, m_, T(1)));
+//  KX_ = vmmul<col>(KX0_, real_matrix_type(this->nx_, m_, T(1)));
 
 
   // Pre-computed values for eq. 62.
   real_matrix_type nmc_ones(n_, mc_, T(1));
-  s_compr_filt_ = exp(complex<T>(0, 2) * vmmul<col>(this->ks_, nmc_ones) *
-    (sqrt(sq(this->Xc_) + sq(vmmul<row>(this->ucs_, nmc_ones))) - this->Xc_));
+  s_compr_filt_ = vmmul<col>(this->fast_time_filter_, 
+    exp(complex<T>(0, 2) * vmmul<col>(this->ks_, nmc_ones) *
+      (sqrt(sq(this->Xc_) + sq(vmmul<row>(this->ucs_, nmc_ones))) - this->Xc_)));
 
   // Pre-computed values for eq. 68. 
   real_matrix_type nm_ones(n_, m_, T(1));
@@ -361,8 +356,7 @@
 
       // 88. (I by m array of ints) ikx are the indices of the slice that 
       //     include the cross-range sliver at its center
-      index_type ikxrows;
-      ikxrows = icKX_.get(i, j) - this->interp_sidelobes_;
+      index_type ikxrows = icKX_.get(i, j) - this->interp_sidelobes_;
 
       for (index_type h = 0; h < this->I_; ++h)
       {
@@ -451,39 +445,31 @@
   fftshift(s_raw, s_filt_); 
 
   // 59. (n by mc array of complex numbers) filtered echoed signal
-  for (index_type c=0; c<mc_; ++c)
+  for (index_type j = 0; j < mc_; ++j)
   {
-    col_fft_(s_filt_.col(c), tmp_col_);
-    s_filt_.col(c) = tmp_col_ * this->fast_time_filter_;
+    col_fft_(s_filt_.col(j));
   }
 
-  SAVE_VIEW("p59_s_filt.view", vsip_csl::matlab::fftshift(s_filt_));
-
   // corner-turn: to row-major
   s_filt_t_ = s_filt_;
 
-  for (index_type r=0; r<n_; ++r)
+  for (index_type i = 0; i < n_; ++i)
   {
     // 62. (n by mc array of complex numbers) signal compressed along 
     //     slow-time (note that to view 'sCompr' it will need to be 
     //     fftshifted first.)
-    s_compr_row_ = s_filt_t_.row(r) * s_compr_filt_.row(r);
-
-    SAVE_VIEW("p62_s_compr.view", fftshift(s_compr_));
-
+    fs_row_ = s_filt_t_.row(i) * s_compr_filt_.row(i);
+    
     // 63. (n by mc array of complex numbers) narrow-bandwidth polar format
     //     reconstruction along slow-time
-    row_fft_(s_compr_row_, fs_row_);
+    row_fft_(fs_row_);
 
     // 65. (n by m array of complex numbers) zero pad the spatial frequency 
     //     domain's compressed signal along its slow-time (note that to view 
     //     'fsPadded' it will need to be fftshifted first)
-    // fs_row_ *= static_cast<T>(m_) / mc_;
-    T scale = static_cast<T>(m_) / mc_;
-
-    fs_padded_row_(left)       = scale * fs_row_(left);
+    fs_padded_row_(left)       = fs_row_(left);
     fs_padded_row_(center_dst) = T();
-    fs_padded_row_(right_dst)  = scale * fs_row_(right_src);
+    fs_padded_row_(right_dst)  = fs_row_(right_src);
 
     SAVE_VIEW("p65_fs_padded.view", fftshift(fs_padded_));
 
@@ -493,7 +479,7 @@
 
     // 68. (n by m array of complex numbers) slow-time decompression (note 
     //     that to view 'sDecompr' it will need to be fftshifted first.)
-    fs_padded_row_ *= s_decompr_filt_.row(r);
+    fs_padded_row_ *= s_decompr_filt_.row(i);
 
     SAVE_VIEW("p68_s_decompr.view", fftshift(fs_padded_));
 
@@ -501,7 +487,7 @@
     //     signal spectrum
     row_fft2_(fs_padded_row_);
 
-    index_type xr = (r < n_/2) ? (n_/2 + r) : (r - n_/2);
+    index_type xr = (i < n_/2) ? (n_/2 + i) : (i - n_/2);
 
     // 77. (n by m array of complex nums) Doppler domain matched-filtered
     //     signal
@@ -511,7 +497,6 @@
     //   fftshift(fs_padded_row_, fs_spotlit_row_);
     //   fsm_.row(xr) = fs_spotlit_row_ * this->fs_ref_.row(xr);
     //
-
     fsm_.row(xr)(ldom) = fs_padded_row_(rdom) * this->fs_ref_.row(xr)(ldom);
     fsm_.row(xr)(rdom) = fs_padded_row_(ldom) * this->fs_ref_.row(xr)(rdom);
 
@@ -574,12 +559,7 @@
 
   // 94. (nx by m array of complex nums) spatial image (complex pixel 
   //     intensities) 
-  // fftshift(ifftmr_(ifftmc_(fftshift(F_, F_shifted_))), spatial_);
-  fftshift(F_, F_shifted_);
-  ifftmc_(F_shifted_);
-  tmp_ = F_shifted_;
-  ifftmr_(tmp_);
-  fftshift(tmp_, spatial_);
+  fftshift(ifftmr_(F_ = ifftmc_(fftshift(F_, F_shifted_))), spatial_);
 
   // for viewing, transpose spatial's magnitude 
   // 95. (m by nx array of reals) image (pixel intensities)
Index: apps/ssar/ssar.cpp
===================================================================
--- apps/ssar/ssar.cpp	(revision 155042)
+++ apps/ssar/ssar.cpp	(working copy)
@@ -50,19 +50,19 @@
   ssar_options opt;
   process_ssar_options(argc, argv, opt);
 
+  typedef double T;
 
   // Setup for Stage 1, Kernel 1 
-  Kernel1<double> k1(opt.scale, opt.n, opt.mc, opt.m); 
+  Kernel1<T> k1(opt.scale, opt.n, opt.mc, opt.m); 
 
   // Retrieve the raw radar image data from disk.  This Data I/O 
   // component is currently untimed.
-  Kernel1<double>::complex_matrix_type s_raw(opt.n, opt.mc);
+  Kernel1<T>::complex_matrix_type s_raw(opt.n, opt.mc);
   load_view_as<complex<float>, 
-    Kernel1<double>::complex_matrix_type>(RAW_SAR_DATA, s_raw);
+    Kernel1<T>::complex_matrix_type>(RAW_SAR_DATA, s_raw);
 
-
   // Resolve the image.  This Computation component is timed.
-  Kernel1<double>::real_matrix_type 
+  Kernel1<T>::real_matrix_type 
     image(k1.output_size(0), k1.output_size(1));
 
   // Process the image.
