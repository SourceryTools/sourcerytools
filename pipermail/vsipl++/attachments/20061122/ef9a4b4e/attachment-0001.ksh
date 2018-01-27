Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 155495)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -6,6 +6,8 @@
     @brief   VSIPL++ implementation of SSCA #3: Kernel 1, Image Formation
 */
 
+#include <vsip/selgen.hpp>
+
 #include <vsip/opt/profile.hpp>
 
 #include <vsip_csl/matlab_utils.hpp>
@@ -62,16 +64,9 @@
 
   complex_vector_type fast_time_filter_;
   complex_matrix_type fs_ref_;
-  real_vector_type k_;
-  real_vector_type uc_;
-  real_vector_type u_;
-  real_vector_type ku0_;
   real_vector_type ks_;
   real_vector_type ucs_;
   real_vector_type us_;
-  real_matrix_type ku_;
-  real_matrix_type k1_;
-  real_matrix_type kx0_;
   real_matrix_type kx_;
 };
 
@@ -80,17 +75,10 @@
   length_type mc, length_type m)
   : scale_(scale), n_(n), mc_(mc), m_(m),
     fast_time_filter_(n),
-    fs_ref_(n, m, T(0)),
-    k_(n),
-    uc_(mc),
-    u_(m),
-    ku0_(m),
+    fs_ref_(n, m),
     ks_(n),
     ucs_(mc),
     us_(m),
-    ku_(n, m),
-    k1_(n, m),
-    kx0_(n, m),
     kx_(n, m)
 {
   using vsip_csl::matlab::fftshift;
@@ -128,34 +116,42 @@
                              //    center point (m)
 
   // Load scale-dependent processing parameters.
+  real_vector_type k(n);
+  real_vector_type uc(mc);
+  real_vector_type u(m);
+  real_vector_type ku0(m);
+
   load_view_as<complex<float>, complex_vector_type>
     (FAST_TIME_FILTER, fast_time_filter_);
-  load_view_as<float, real_vector_type>(SLOW_TIME_WAVENUMBER, k_);
+  load_view_as<float, real_vector_type>(SLOW_TIME_WAVENUMBER, k);
   load_view_as<float, real_vector_type>
-    (SLOW_TIME_COMPRESSED_APERTURE_POSITION, uc_);
-  load_view_as<float, real_vector_type>(SLOW_TIME_APERTURE_POSITION, u_);
-  load_view_as<float, real_vector_type>(SLOW_TIME_SPATIAL_FREQUENCY, ku0_);
+    (SLOW_TIME_COMPRESSED_APERTURE_POSITION, uc);
+  load_view_as<float, real_vector_type>(SLOW_TIME_APERTURE_POSITION, u);
+  load_view_as<float, real_vector_type>(SLOW_TIME_SPATIAL_FREQUENCY, ku0);
 
   // 60. (1 by n array of reals) fftshifted slow-time wavenumber
-  fftshift(k_, ks_);
+  fftshift(k, ks_);
 
   // 61. (1 by mc array of reals) fftshifted slow-time synthetic aperture
-  fftshift(uc_, ucs_);
+  fftshift(uc, ucs_);
 
   // 67. (1 by m array of reals) shifted u
-  fftshift(u_, us_);
+  fftshift(u, us_);
 
   // 70. (1 by m array of reals) ku0 is transformed into the intermediate 
   //     (n by m array of reals) kx0 (wn)
-  ku_ = vmmul<row>(ku0_, real_matrix_type(n_, m_, T(1)));
+  real_matrix_type ku(n, m);
+  ku = vmmul<row>(ku0, real_matrix_type(n_, m_, T(1)));
 
-  k1_ = vmmul<col>(k_, real_matrix_type(n_, m_, T(1)));
+  real_matrix_type k1(n, m);
+  k1 = vmmul<col>(k, real_matrix_type(n_, m_, T(1)));
 
-  kx0_ = 4 * sq(k1_) - sq(ku_);
+  real_matrix_type kx0(n, m);
+  kx0 = 4 * sq(k1) - sq(ku);
 
   // 71. (n by m array of reals) kx is the Doppler domain range 
   //     wavenumber (wn)    
-  kx_ = sqrt(max(T(0), kx0_));
+  kx_ = sqrt(max(T(0), kx0));
 
   // 72. (scalar, real) minimum wavenum (wn)
   Index<2> idx;
@@ -177,35 +173,26 @@
   // complex conjugate
 
   // 76. (n by m array of complex nums) reference signal's complex conjugate
-  for (index_type i = 0; i < n_; ++i)
-    for (index_type j = 0; j < m_; ++j)
-    {
-      if (kx_(i, j) > 0)
-        fs_ref_(i, j) = exp(complex<T>(0, 1) * 
-          (Xc_ * (kx_(i, j) - T(2) * k_(i)) + T(0.25*M_PI) + ku_(i, j)));
-    }
+  //
+  // this is equivalent to the elementwise operation
+  //    fs_ref_.put(i, j, (kx_.get(i, j) > 0) ? exp(...) : complex<T>(0));
+  fs_ref_ = ite(kx_ > 0, exp(complex<T>(0, 1) * 
+    (Xc_ * (kx_ - 2 * k1) + T(0.25 * M_PI) + ku)), complex<T>(0));
 
   SAVE_VIEW("p76_fs_ref.view", fs_ref_);
 
   // 78. (scalar, int) interpolation processing sliver size
-  I_ = 2 * this->interp_sidelobes_ + 1;
+  I_ = 2 * interp_sidelobes_ + 1;
                             
   // 79. (scalar, real) +/- interpolation neighborhood size in KX domain
-  kxs_ = this->interp_sidelobes_ * this->dkx_;  
+  kxs_ = interp_sidelobes_ * dkx_;  
 
   // 80. (scalar, int) total number of kx samples required in the SAR 
   //     image's col (in pixels; increased to avoid negative array 
   //     indexing in interpolation loop)
   nx_ = nx0 + 2 * interp_sidelobes_ + 4;
 
-  // 81. (scalar, real) range sample spacing 
-  T dx = 2 * M_PI / (this->nx_ * this->dkx_);             
 
-  // 82. (1 by nx array of reals) range array
-//  for (index_type i = 0; i < this->nx_; ++i)
-//    x_.put(i, dx * (i - this->nx_/2));
-
-
 #ifdef VERBOSE
   std::cout << "kx_min = " << kx_min_ << std::endl;
   std::cout << "kx_max = " << kx_max << std::endl;
@@ -214,8 +201,9 @@
   std::cout << "mc = " << mc_ << std::endl;
   std::cout << "m = " << m_ << std::endl;
   std::cout << "nx0 = " << nx0 << std::endl;
+  std::cout << "I = " << I_ << std::endl;
+  std::cout << "kxs = " << kxs_ << std::endl;
   std::cout << "nx = " << nx_ << std::endl;
-  std::cout << "dx = " << dx << std::endl;
 #endif
 }
 
@@ -237,9 +225,9 @@
 
   typedef Fft<const_Vector, complex<T>, complex<T>, fft_fwd, by_reference> col_fft_type;
   typedef Fft<const_Vector, complex<T>, complex<T>, fft_fwd, by_reference> row_fft_type;
-  typedef Fft<const_Vector, complex<T>, complex<T>, fft_inv, by_reference> ifftr_type;
-  typedef Fftm<complex<T>, complex<T>, row, fft_inv, by_reference> ifftmr_type;
-  typedef Fftm<complex<T>, complex<T>, col, fft_inv, by_reference> ifftmc_type;
+  typedef Fft<const_Vector, complex<T>, complex<T>, fft_inv, by_reference> inv_fft_type;
+  typedef Fftm<complex<T>, complex<T>, row, fft_inv, by_reference> inv_row_fftm_type;
+  typedef Fftm<complex<T>, complex<T>, col, fft_inv, by_reference> inv_col_fftm_type;
 
   Kernel1(length_type scale, length_type n, length_type mc, length_type m);
   ~Kernel1() {}
@@ -270,26 +258,24 @@
   complex_matrix_type s_filt_t_;
   complex_matrix_type s_compr_filt_;
   Vector<complex<T> > fs_row_;
-  Vector<complex<T> > fs_padded_row_;
+  Vector<complex<T> > fs_spotlit_;
   complex_matrix_type s_decompr_filt_;
   complex_matrix_type fsm_;
   complex_col_matrix_type fsm_t_;
   Matrix<index_type, Dense<2, index_type, col2_type> > icKX_;
-//  real_vector_type x_;
   real_vector_type KX0_;
-//  real_matrix_type KX_;
   Tensor<T, Dense<3, T, tuple<1, 0, 2> > > SINC_HAM_;
   complex_col_matrix_type F_;
   complex_matrix_type F_shifted_;
   complex_col_matrix_type spatial_;
   real_col_matrix_type image_t_;
 
-  col_fft_type col_fft_;
-  row_fft_type row_fft_;
-  row_fft_type row_fft2_;
-  ifftr_type ifft_;
-  ifftmr_type ifftmr_;
-  ifftmc_type ifftmc_;
+  col_fft_type ft_fft_;
+  row_fft_type st_fft_;
+  row_fft_type compr_fft_;
+  inv_fft_type decompr_fft_;
+  inv_row_fftm_type ifftmr_;
+  inv_col_fftm_type ifftmc_;
 };
 
 
@@ -302,41 +288,30 @@
     s_filt_t_(n, mc),
     s_compr_filt_(n, mc),
     fs_row_(mc),
-    fs_padded_row_(m),
+    fs_spotlit_(m),
     s_decompr_filt_(n, m),
     fsm_(n, m),
     fsm_t_(n, m),
     icKX_(n, m),
-//    x_(this->nx_),
     KX0_(this->nx_),
-//    KX_(this->nx_, m_),
     SINC_HAM_(n_, m_, this->I_),
     F_(this->nx_, m_),
     F_shifted_(this->nx_, m_),
     spatial_(this->nx_, m_),
     image_t_(this->nx_, m_),
-    col_fft_(Domain<1>(n), T(1)),
-    row_fft_(Domain<1>(mc), static_cast<T>(m_) / mc_),
-    row_fft2_(Domain<1>(m), T(1)),
-    ifft_(Domain<1>(m), T(1.f/m)),
+    ft_fft_(Domain<1>(n), T(1)),
+    st_fft_(Domain<1>(m), T(1)),
+    compr_fft_(Domain<1>(mc), static_cast<T>(m_) / mc_),
+    decompr_fft_(Domain<1>(m), T(1.f/m)),
     ifftmr_(Domain<2>(this->nx_, m_), T(1./m_)),
     ifftmc_(Domain<2>(this->nx_, m_), T(1./this->nx_))
 {
   // 83. (1 by nx array of reals) uniformly-spaced KX0 points where 
   //     interpolation is done  
-  for (index_type i = 0; i < this->nx_; ++i)
-    KX0_.put(i, this->kx_min_ + (T(i) - this->interp_sidelobes_ - 2.f) * 
-      this->dkx_);
+  KX0_ = this->kx_min_ + 
+    (vsip::ramp(T(0),T(1), this->nx_) - this->interp_sidelobes_ - 2) *
+    this->dkx_;
 
-  // 84. (scalar, real) carrier frequency in KX domain, where (nx/2+1) 
-  //     is its index number
-//  T kxc = KX0_.get(this->nx_ / 2);
-
-  // 85. KX0 (1 by nx array of reals) is expanded to the SAR image's 
-  //     final dims of (nx by m array of reals).
-//  KX_ = vmmul<col>(KX0_, real_matrix_type(this->nx_, m_, T(1)));
-
-
   // Pre-computed values for eq. 62.
   real_matrix_type nmc_ones(n_, mc_, T(1));
   s_compr_filt_ = vmmul<col>(this->fast_time_filter_, 
@@ -354,8 +329,8 @@
     {
       // 87. (1 by m array of ints) icKX are the indices of the closest 
       //     cross-range sliver in the KX domain
-      icKX_(i, j) = static_cast<index_type>(
-        ((this->kx_.get(i, j) - KX0_.get(0)) / this->dkx_) + 0.5f);
+      icKX_.put(i, j, static_cast<index_type>(
+        ((this->kx_.get(i, j) - KX0_.get(0)) / this->dkx_) + 0.5f) );
 
       // 88. (I by m array of ints) ikx are the indices of the slice that 
       //     include the cross-range sliver at its center
@@ -382,10 +357,6 @@
       }
     }
 
-
-#ifdef VERBOSE
-  std::cout << "kxc = " << kxc << std::endl;
-#endif
 }
 
 
@@ -435,7 +406,7 @@
   Domain<1> right_dst(mz + mc_/2, 1, mc_/2);
   Domain<1> right_src(mc_/2, 1, mc_/2);
 
-  // left/right domains for emulating fftshift of fs_padded_row_.
+  // left/right domains for emulating fftshift of fs_spotlit_.
   Domain<1> ldom(0, 1, m_/2);
   Domain<1> rdom(m_/2, 1, m_/2);
 
@@ -446,11 +417,17 @@
   fftshift(s_raw, s_filt_); 
 
   // 59. (n by mc array of complex numbers) filtered echoed signal
+  // 
+  // Note that the fast-time filter is combined with the compression
+  // along the slow-time axis below.  
   for (index_type j = 0; j < mc_; ++j)
   {
-    col_fft_(s_filt_.col(j));
+    ft_fft_(s_filt_.col(j));
   }
 
+  // Digital spotlighting and bandwidth expansion in the ku domain 
+  // via slow-time compression and decompression:
+
   // corner-turn: to row-major
   s_filt_t_ = s_filt_;
 
@@ -463,47 +440,51 @@
     
     // 63. (n by mc array of complex numbers) narrow-bandwidth polar format
     //     reconstruction along slow-time
-    row_fft_(fs_row_);
+    compr_fft_(fs_row_);
 
     // 65. (n by m array of complex numbers) zero pad the spatial frequency 
     //     domain's compressed signal along its slow-time (note that to view 
     //     'fsPadded' it will need to be fftshifted first)
-    fs_padded_row_(left)       = fs_row_(left);
-    fs_padded_row_(center_dst) = T();
-    fs_padded_row_(right_dst)  = fs_row_(right_src);
+    fs_spotlit_(left)       = fs_row_(left);
+    fs_spotlit_(center_dst) = T();
+    fs_spotlit_(right_dst)  = fs_row_(right_src);
 
-    SAVE_VIEW("p65_fs_padded.view", fftshift(fs_padded_));
+    SAVE_VIEW("p65_fs_padded.view", fftshift(fs_spotlit_));
 
     // 66. (n by m array of complex numbers) transform-back the zero 
-    // padded spatial spectrum along its cross-range
-    ifft_(fs_padded_row_);
+    //     padded spatial spectrum along its cross-range
+    decompr_fft_(fs_spotlit_);
 
     // 68. (n by m array of complex numbers) slow-time decompression (note 
     //     that to view 'sDecompr' it will need to be fftshifted first.)
-    fs_padded_row_ *= s_decompr_filt_.row(i);
+    fs_spotlit_ *= s_decompr_filt_.row(i);
 
-    SAVE_VIEW("p68_s_decompr.view", fftshift(fs_padded_));
+    SAVE_VIEW("p68_s_decompr.view", fftshift(fs_spotlit_));
 
     // 69. (n by m array of complex numbers) digitally-spotlighted SAR 
     //     signal spectrum
-    row_fft2_(fs_padded_row_);
+    st_fft_(fs_spotlit_);
 
-    index_type xr = (i < n_/2) ? (n_/2 + i) : (i - n_/2);
 
+    // Match filter the spotlighted signal 'fsSpotLit' with the reference's 
+    // complex conjugate 'fsRef' along fast-time and slow-time, to remove 
+    // the reference signal's spectral components.
+
     // 77. (n by m array of complex nums) Doppler domain matched-filtered
     //     signal
 
     // Merge fftshift and vmul:
     //
-    //   fftshift(fs_padded_row_, fs_spotlit_row_);
-    //   fsm_.row(xr) = fs_spotlit_row_ * this->fs_ref_.row(xr);
+    //   fftshift(fs_spotlit_, fsm_);
+    //   fsm_.row(xr) = fs_spotlit_ * this->fs_ref_.row(xr);
     //
-    fsm_.row(xr)(ldom) = fs_padded_row_(rdom) * this->fs_ref_.row(xr)(ldom);
-    fsm_.row(xr)(rdom) = fs_padded_row_(ldom) * this->fs_ref_.row(xr)(rdom);
-
-    SAVE_VIEW("p69_fs_spotlit.view", fs_spotlit_);
+    index_type xr = (i < n_/2) ? (n_/2 + i) : (i - n_/2);
+    fsm_.row(xr)(ldom) = fs_spotlit_(rdom) * this->fs_ref_.row(xr)(ldom);
+    fsm_.row(xr)(rdom) = fs_spotlit_(ldom) * this->fs_ref_.row(xr)(rdom);
   }
 
+  SAVE_VIEW("p77_fsm.view", fsm_);
+
 #ifdef VERBOSE
   std::cout << "mz = " << mz << std::endl;
 #endif
@@ -517,12 +498,10 @@
 {
   impl::profile::Scope_event kernel1_event("interpolation", 255530235);
   using vsip_csl::matlab::fftshift;
-  assert(image.size(0) == n_);
-  assert(image.size(1) == mc_);
+  assert(image.size(0) == m_);
+  assert(image.size(1) == this->nx_);
 
-  // match filter the spotlighted signal 'fsSpotLit' with the reference's 
-  // complex conjugate 'fsRef' along fast-time and slow-time, to remove 
-  // the reference signal's spectral components.
+  // Interpolate From Polar Coordinates to Rectangular Coordinates
 
   // corner-turn to col-major
   fsm_t_ = fsm_;
Index: apps/ssar/ssar.cpp
===================================================================
--- apps/ssar/ssar.cpp	(revision 155495)
+++ apps/ssar/ssar.cpp	(working copy)
@@ -53,7 +53,11 @@
   typedef float T;
 
   // Setup for Stage 1, Kernel 1 
+  vsip::impl::profile::Acc_timer t0;
+  t0.start();
   Kernel1<T> k1(opt.scale, opt.n, opt.mc, opt.m); 
+  t0.stop();
+  cout << "setup:   " << t0.delta() << " (s)" << endl;
 
   // Retrieve the raw radar image data from disk.  This Data I/O 
   // component is currently untimed.
@@ -65,18 +69,28 @@
   Kernel1<T>::real_matrix_type 
     image(k1.output_size(0), k1.output_size(1));
 
-  // Process the image.
   vsip::impl::profile::Acc_timer t1;
+  vsip::Vector<double> process_time(loop);
   for (int l=0; l<loop; ++l)
   {
     t1.start();
     k1.process_image(s_raw, image);
     t1.stop();
-    cout << t1.delta() << endl;
+    process_time.put(l, t1.delta());
   }
-  if (loop > 1)
-    cout << "average: "  << t1.total() / t1.count() << endl;
 
+  // Display statistics
+  if (loop > 0)
+  {
+    Index<1> idx;
+    double mean = vsip::meanval(process_time);
+    cout << "loops:   " << loop << endl;
+    cout << "mean:    " << mean << endl;
+    cout << "min:     " << vsip::minval(process_time, idx) << endl;
+    cout << "max:     " << vsip::maxval(process_time, idx) << endl;
+    cout << "std-dev: " << sqrt(vsip::meansqval(process_time - mean)) << endl;
+  }
+
   // Store the image on disk for later processing (not timed).
   save_view_as<float>("image.view", image); 
 }
