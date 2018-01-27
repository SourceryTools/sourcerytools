Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 153966)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -12,7 +12,7 @@
 #include <vsip_csl/save_view.hpp>
 #include <vsip_csl/load_view.hpp>
 
-#if 1
+#if 0
 #define VERBOSE
 #define SAVE_VIEW(a, b)    vsip_csl::save_view_as<complex<float> >(a, b)
 #else
@@ -29,107 +29,71 @@
 char const* SLOW_TIME_SPATIAL_FREQUENCY =            "ku.view";
 
 template <typename T>
-class Kernel1
+class Kernel1_base
 {
-public:
+protected:
   typedef Matrix<complex<T> > complex_matrix_type;
   typedef Vector<complex<T> > complex_vector_type;
   typedef Matrix<T> real_matrix_type;
   typedef Vector<T> real_vector_type;
-  typedef Fftm<complex<T>, complex<T>, col> col_fftm_type;
-  typedef Fftm<complex<T>, complex<T>, row> row_fftm_type;
-  typedef Fftm<complex<T>, complex<T>, row, fft_inv> ifftm_type;
 
-  Kernel1(length_type scale, length_type n, length_type mc, length_type m);
-  ~Kernel1() {}
+  Kernel1_base(length_type scale, length_type n, length_type mc, 
+    length_type m);
+  ~Kernel1_base() {}
 
-  void process_image();
-
-private:
-  void
-  digital_spotlighting(void);
-
-  real_matrix_type
-  interpolation(void);
-
-private:
   length_type scale_;
   length_type n_;
   length_type mc_;
   length_type m_;
   length_type nx_;
   length_type interp_sidelobes_;
+  length_type I_;
   T range_factor_;
   T aspect_ratio_;
   T L_;
   T Y0_;
   T X0_;
   T Xc_;
+  T dkx_;
+  T kx_min_;
+  T kxs_;
 
-  complex_matrix_type s_raw_;
   complex_vector_type fast_time_filter_;
-
+  complex_matrix_type fs_ref_;
   real_vector_type k_;
   real_vector_type uc_;
   real_vector_type u_;
   real_vector_type ku0_;
-  complex_matrix_type s_filt_;
-  complex_matrix_type fs_spotlit_;
   real_vector_type ks_;
   real_vector_type ucs_;
-  complex_matrix_type s_compr_;
-  complex_matrix_type fs_;
-  complex_matrix_type fs_padded_;
-  complex_matrix_type s_padded_;
   real_vector_type us_;
-  complex_matrix_type s_decompr_;
   real_matrix_type ku_;
   real_matrix_type k1_;
   real_matrix_type kx0_;
   real_matrix_type kx_;
-  complex_matrix_type fs_ref_;
-  complex_matrix_type fsm_;
-  Vector<index_type> icKX_;
-
-  col_fftm_type col_fftm_;
-  row_fftm_type row_fftm_;
-  row_fftm_type row_fftm2_;
-  ifftm_type ifftm_;
 };
 
-
 template <typename T>
-Kernel1<T>::Kernel1(length_type scale, length_type n, length_type mc, 
-  length_type m)
-  : scale_(scale), n_(n), mc_(mc), m_(m), nx_(0),
-    s_raw_(n, mc),
+Kernel1_base<T>::Kernel1_base(length_type scale, length_type n, 
+  length_type mc, length_type m)
+  : scale_(scale), n_(n), mc_(mc), m_(m),
     fast_time_filter_(n),
-    s_filt_(n, mc),
+    fs_ref_(n, m, T(0)),
     k_(n),
     uc_(mc),
     u_(m),
     ku0_(m),
-    fs_spotlit_(n, m),
-    ks_(n_),
-    ucs_(mc_),
-    s_compr_(n_, mc_),
-    fs_(n_, mc_),
-    fs_padded_(n_, m_, T()),
-    s_padded_(n_, m_),
-    us_(m_),
-    s_decompr_(n_, m_),
-    ku_(n_, m_),
-    k1_(n_, m_),
-    kx0_(n_, m_),
-    kx_(n_, m_),
-    fs_ref_(n_, m_, T(0)),
-    fsm_(n_, m_),
-    icKX_(m_),
-    col_fftm_(Domain<2>(n, mc), T(1)),
-    row_fftm_(Domain<2>(n, mc), T(1)),
-    row_fftm2_(Domain<2>(n, m), T(1)),
-    ifftm_(Domain<2>(n, m), T(1.f/m))
+    ks_(n),
+    ucs_(mc),
+    us_(m),
+    ku_(n, m),
+    k1_(n, m),
+    kx0_(n, m),
+    kx_(n, m)
 {
+  using vsip_csl::matlab::fftshift;
+  using vsip_csl::load_view_as;
+
   interp_sidelobes_ = 8;     // 2. (scalar, integer) number of 
                              //    neighboring sidelobes used in sinc interp.
                              //    WARNING: Changing 'nInterpSidelobes' 
@@ -161,32 +125,240 @@
   Xc_ = range_factor_ * Y0_; // 8. (scalar, real) swath's range
                              //    center point (m)
 
+  // Load scale-dependent processing parameters.
+  load_view_as<complex<float>, complex_vector_type>
+    (FAST_TIME_FILTER, fast_time_filter_);
+  load_view_as<float, real_vector_type>(SLOW_TIME_WAVENUMBER, k_);
+  load_view_as<float, real_vector_type>
+    (SLOW_TIME_COMPRESSED_APERTURE_POSITION, uc_);
+  load_view_as<float, real_vector_type>(SLOW_TIME_APERTURE_POSITION, u_);
+  load_view_as<float, real_vector_type>(SLOW_TIME_SPATIAL_FREQUENCY, ku0_);
+
+  // 60. (1 by n array of reals) fftshifted slow-time wavenumber
+  fftshift(k_, ks_);
+
+  // 61. (1 by mc array of reals) fftshifted slow-time synthetic aperture
+  fftshift(uc_, ucs_);
+
+  // 67. (1 by m array of reals) shifted u
+  fftshift(u_, us_);
+
+  // 70. (1 by m array of reals) ku0 is transformed into the intermediate 
+  //     (n by m array of reals) kx0 (wn)
+  ku_ = vmmul<row>(ku0_, real_matrix_type(n_, m_, T(1)));
+
+  k1_ = vmmul<col>(k_, real_matrix_type(n_, m_, T(1)));
+
+  kx0_ = 4 * sq(k1_) - sq(ku_);
+
+  // 71. (n by m array of reals) kx is the Doppler domain range 
+  //     wavenumber (wn)    
+  kx_ = sqrt(max(T(0), kx0_));
+
+  // 72. (scalar, real) minimum wavenum (wn)
+  Index<2> idx;
+  kx_min_ = minval(kx_, idx);
+
+  // 73. (scalar, real) maximum wavenum (wn)
+  T kx_max = maxval(kx_, idx);
+
+  // 74. (scalar, real) Nyquist sample spacing in kx domain (wn)
+  dkx_ = M_PI / X0_;
+
+  // 75. (scalar, integer) nx0 is the min number of required kx samples 
+  //     (pixels);  (later it will be increased slightly to avoid 
+  //     negative array indexing)
+  index_type nx0 = static_cast<index_type>
+    (2 * ceil((kx_max - kx_min_) / (2 * dkx_)));   
+
+  // generate the Doppler domain representation the reference signal's 
+  // complex conjugate
+
+  // 76. (n by m array of complex nums) reference signal's complex conjugate
+  for (index_type i = 0; i < n_; ++i)
+    for (index_type j = 0; j < m_; ++j)
+    {
+      if (kx_(i, j) > 0)
+        fs_ref_(i, j) = exp(complex<T>(0, 1) * 
+          (Xc_ * (kx_(i, j) - T(2) * k_(i)) + T(0.25*M_PI) + ku_(i, j)));
+    }
+
+  SAVE_VIEW("p76_fs_ref.view", fs_ref_);
+
+  // 78. (scalar, int) interpolation processing sliver size
+  I_ = 2 * this->interp_sidelobes_ + 1;
+                            
+  // 79. (scalar, real) +/- interpolation neighborhood size in KX domain
+  kxs_ = this->interp_sidelobes_ * this->dkx_;  
+
+  // 80. (scalar, int) total number of kx samples required in the SAR 
+  //     image's col (in pixels; increased to avoid negative array 
+  //     indexing in interpolation loop)
+  nx_ = nx0 + 2 * interp_sidelobes_ + 4;
+
+  // 81. (scalar, real) range sample spacing 
+  T dx = 2 * M_PI / (this->nx_ * this->dkx_);             
+
+  // 82. (1 by nx array of reals) range array
+//  for (index_type i = 0; i < this->nx_; ++i)
+//    x_.put(i, dx * (i - this->nx_/2));
+
+
 #ifdef VERBOSE
+  std::cout << "kx_min = " << kx_min_ << std::endl;
+  std::cout << "kx_max = " << kx_max << std::endl;
+  std::cout << "dkx = " << dkx_ << std::endl;
   std::cout << "n = " << n_ << std::endl;
   std::cout << "mc = " << mc_ << std::endl;
   std::cout << "m = " << m_ << std::endl;
+  std::cout << "nx0 = " << nx0 << std::endl;
+  std::cout << "nx = " << nx_ << std::endl;
+  std::cout << "dx = " << dx << std::endl;
 #endif
 }
 
 
+
+
+
+
 template <typename T>
-void
-Kernel1<T>::process_image()
+class Kernel1 : public Kernel1_base<T>
 {
-  using vsip_csl::load_view_as;
+public:
+  typedef typename Kernel1_base<T>::complex_matrix_type complex_matrix_type;
+  typedef typename Kernel1_base<T>::complex_vector_type complex_vector_type;
+  typedef typename Kernel1_base<T>::real_matrix_type real_matrix_type;
+  typedef typename Kernel1_base<T>::real_vector_type real_vector_type;
 
-  // Load the raw radar image data
-  load_view_as<complex<float>, complex_matrix_type>(RAW_SAR_DATA, s_raw_);
+  typedef Fftm<complex<T>, complex<T>, col> col_fftm_type;
+  typedef Fftm<complex<T>, complex<T>, row> row_fftm_type;
+  typedef Fftm<complex<T>, complex<T>, row, fft_inv> ifftmr_type;
+  typedef Fftm<complex<T>, complex<T>, col, fft_inv> ifftmc_type;
 
-  // Load scale-dependent processing parameters.
-  load_view_as<complex<float>, complex_vector_type>
-    (FAST_TIME_FILTER, fast_time_filter_);
-  load_view_as<float, real_vector_type>(SLOW_TIME_WAVENUMBER, k_);
-  load_view_as<float, real_vector_type>
-    (SLOW_TIME_COMPRESSED_APERTURE_POSITION, uc_);
-  load_view_as<float, real_vector_type>(SLOW_TIME_APERTURE_POSITION, u_);
-  load_view_as<float, real_vector_type>(SLOW_TIME_SPATIAL_FREQUENCY, ku0_);
+  Kernel1(length_type scale, length_type n, length_type mc, length_type m);
+  ~Kernel1() {}
 
+  void process_image(complex_matrix_type const input, 
+    real_matrix_type output);
+
+  length_type output_size(dimension_type dim) 
+    { 
+      assert(dim < 2);
+      return (dim ? this->nx_ : m_);
+    }
+
+private:
+  void
+  digital_spotlighting(complex_matrix_type s_raw);
+
+  void
+  interpolation(real_matrix_type image);
+
+private:
+  length_type scale_;
+  length_type n_;
+  length_type mc_;
+  length_type m_;
+
+  complex_matrix_type s_filt_;
+  complex_matrix_type s_compr_filt_;
+  complex_matrix_type fs_spotlit_;
+  complex_matrix_type s_compr_;
+  complex_matrix_type fs_;
+  complex_matrix_type fs_padded_;
+  complex_matrix_type s_padded_;
+  complex_matrix_type s_decompr_filt_;
+  complex_matrix_type s_decompr_;
+  complex_matrix_type fsm_;
+  Vector<index_type> icKX_;
+//  real_vector_type x_;
+  real_vector_type KX0_;
+  real_matrix_type KX_;
+  complex_matrix_type F_;
+  complex_matrix_type F_shifted_;
+  complex_matrix_type spatial_;
+
+  col_fftm_type col_fftm_;
+  row_fftm_type row_fftm_;
+  row_fftm_type row_fftm2_;
+  ifftmr_type ifftm_;
+  ifftmr_type ifftmr_;
+  ifftmc_type ifftmc_;
+};
+
+
+template <typename T>
+Kernel1<T>::Kernel1(length_type scale, length_type n, length_type mc, 
+  length_type m)
+  : Kernel1_base<T>(scale, n, mc, m),
+    scale_(scale), n_(n), mc_(mc), m_(m), 
+    s_filt_(n, mc),
+    s_compr_filt_(n, mc),
+    fs_spotlit_(n, m),
+    s_compr_(n, mc),
+    fs_(n, mc),
+    fs_padded_(n, m),
+    s_padded_(n, m),
+    s_decompr_filt_(n, m),
+    s_decompr_(n, m),
+    fsm_(n, m),
+    icKX_(m),
+//    x_(this->nx_),
+    KX0_(this->nx_),
+    KX_(this->nx_, m_),
+    F_(this->nx_, m_),
+    F_shifted_(this->nx_, m_),
+    spatial_(this->nx_, m_),
+    col_fftm_(Domain<2>(n, mc), T(1)),
+    row_fftm_(Domain<2>(n, mc), T(1)),
+    row_fftm2_(Domain<2>(n, m), T(1)),
+    ifftm_(Domain<2>(n, m), T(1.f/m)),
+    ifftmr_(Domain<2>(this->nx_, m_), T(1./m_)),
+    ifftmc_(Domain<2>(this->nx_, m_), T(1./this->nx_))
+{
+  // 83. (1 by nx array of reals) uniformly-spaced KX0 points where 
+  //     interpolation is done  
+  for (index_type i = 0; i < this->nx_; ++i)
+    KX0_.put(i, this->kx_min_ + (T(i) - this->interp_sidelobes_ - 2.f) * 
+      this->dkx_);
+
+  // 84. (scalar, real) carrier frequency in KX domain, where (nx/2+1) 
+  //     is its index number
+  T kxc = KX0_.get(this->nx_ / 2);
+
+  // 85. KX0 (1 by nx array of reals) is expanded to the SAR image's 
+  //     final dims of (nx by m array of reals).
+  KX_ = vmmul<col>(KX0_, real_matrix_type(this->nx_, m_, T(1)));
+
+
+  // Pre-computed values for eq. 62.
+  real_matrix_type nmc_ones(n_, mc_, T(1));
+  s_compr_filt_ = exp(complex<T>(0, 2) * vmmul<col>(this->ks_, nmc_ones) *
+    (sqrt(sq(this->Xc_) + sq(vmmul<row>(this->ucs_, nmc_ones))) - this->Xc_));
+
+  // Pre-computed values for eq. 68. 
+  real_matrix_type nm_ones(n_, m_, T(1));
+  s_decompr_filt_ = exp( complex<T>(0, 2) * vmmul<col>(this->ks_, nm_ones) *
+    (this->Xc_ - sqrt(sq(this->Xc_) + sq(vmmul<row>(this->us_, nm_ones)))) );
+
+
+#ifdef VERBOSE
+  std::cout << "kxc = " << kxc << std::endl;
+#endif
+}
+
+
+template <typename T>
+void
+Kernel1<T>::process_image(complex_matrix_type const input, 
+  real_matrix_type output)
+{
+  assert(input.size(0) == n_);
+  assert(input.size(1) == mc_);
+  assert(output.size(0) == m_);
+  assert(output.size(1) == this->nx_);
+
   // Time the remainder of this function, provided profiling is enabled 
   // (pass '--vsipl++-profile-mode=[accum|trace]' on the command line).  
   // If profiling is not enabled, then this statement has no effect.
@@ -196,51 +368,37 @@
   // Digital spotlighting and bandwidth-expansion using slow-time 
   // compression and decompression.  
   //   fs_spotlit_   stores the processed signal
-  this->digital_spotlighting();
+  this->digital_spotlighting(input);
 
 
   // Digital reconstruction via spatial frequency interpolation.
-  real_matrix_type image(this->interpolation());
-
-  // Store the image on disk for later processing.
-  vsip_csl::save_view_as<float>("image.view", image); 
+  //real_matrix_type image(this->interpolation());
+  this->interpolation(output);
 }
 
 
 
 template <typename T>
 void
-Kernel1<T>::digital_spotlighting()
+Kernel1<T>::digital_spotlighting(complex_matrix_type s_raw)
 {
-  assert(n_ == k_.size());
-  assert(mc_ == uc_.size());
-  assert(m_ == u_.size());
   using vsip_csl::matlab::fftshift;
+  assert(s_raw.size(0) == n_);
+  assert(s_raw.size(1) == mc_);
 
   // The baseband reference signal is first transformed into the Doppler 
   // (spatial frequency) domain.  
 
   // 59. (n by mc array of complex numbers) filtered echoed signal
-  s_filt_ = vmmul<col>(fast_time_filter_, 
-    col_fftm_(fftshift(s_raw_, s_filt_)));
+  s_filt_ = vmmul<col>(this->fast_time_filter_, 
+    col_fftm_(fftshift(s_raw, s_filt_)));
 
   SAVE_VIEW("p59_s_filt.view", vsip_csl::matlab::fftshift(s_filt_));
 
-  // 60. (1 by n array of reals) fftshifted slow-time wavenumber
-  fftshift(k_, ks_);
-
-  // 61. (1 by mc array of reals) fftshifted slow-time synthetic aperture
-  fftshift(uc_, ucs_);
-
   // 62. (n by mc array of complex numbers) signal compressed along 
   //     slow-time (note that to view 'sCompr' it will need to be 
   //     fftshifted first.)
-  for (index_type i = 0; i < n_; ++i)
-    for (index_type j = 0; j < mc_; ++j)
-    {
-      s_compr_.put(i, j, s_filt_.get(i, j) * 
-        exp(complex<T>(0, 2) * ks_(i) * (sqrt(sq(Xc_) + sq(ucs_(j))) - Xc_)));
-    }
+  s_compr_ = s_filt_ * s_compr_filt_;
 
   SAVE_VIEW("p62_s_compr.view", fftshift(s_compr_));
 
@@ -256,31 +414,24 @@
   //     domain's compressed signal along its slow-time (note that to view 
   //     'fsPadded' it will need to be fftshifted first)
   T m_scale = static_cast<T>(m_) / static_cast<T>(mc_);
-  for (index_type i = 0; i < n_; ++i)
-  {
-    for (index_type j = 0; j < mc_ / 2; ++j)
-        fs_padded_.put(i, j, m_scale * fs_.get(i, j));
+  Domain<2> left(Domain<1>(0, 1, n_), Domain<1>(0, 1, mc_/2));
+  Domain<2> center_dst(Domain<1>(0, 1, n_), Domain<1>(mc_/2, 1, mz));
+  Domain<2> right_dst(Domain<1>(0, 1, n_), Domain<1>(mz + mc_/2, 1, mc_/2));
+  Domain<2> right_src(Domain<1>(0, 1, n_), Domain<1>(mc_/2, 1, mc_/2));
 
-    for (index_type j = mc_ / 2; j < mc_; ++j)
-        fs_padded_.put(i, j + mz, m_scale * fs_.get(i, j));
-  }
+  fs_padded_(left) = m_scale * fs_(left);
+  fs_padded_(center_dst) = T();
+  fs_padded_(right_dst) = m_scale * fs_(right_src);
+
   SAVE_VIEW("p65_fs_padded.view", fftshift(fs_padded_));
 
   // 66. (n by m array of complex numbers) transform-back the zero 
   // padded spatial spectrum along its cross-range
   s_padded_ = ifftm_(fs_padded_);
 
-  // 67. (1 by m array of reals) shifted u
-  fftshift(u_, us_);
-
   // 68. (n by m array of complex numbers) slow-time decompression (note 
   //     that to view 'sDecompr' it will need to be fftshifted first.)
-  for (index_type i = 0; i < n_; ++i)
-    for (index_type j = 0; j < m_; ++j)
-    {
-      s_decompr_.put(i, j, s_padded_.get(i, j) * 
-        exp( complex<T>(0, 2) * ks_(i) * (Xc_ - sqrt(sq(Xc_) + sq(us_(j)))) ));
-    }
+  s_decompr_ = s_padded_ * s_decompr_filt_;
 
   SAVE_VIEW("p68_s_decompr.view", fftshift(s_decompr_));
 
@@ -298,98 +449,22 @@
 
 
 template <typename T>
-Matrix<T>
-Kernel1<T>::interpolation()
+void // Matrix<T>
+Kernel1<T>::interpolation(real_matrix_type image)
 {
-  assert(n_ == k_.size());
-  assert(m_ == ku0_.size(0));
   using vsip_csl::matlab::fftshift;
+  assert(image.size(0) == n_);
+  assert(image.size(1) == mc_);
 
-  // 70. (1 by m array of reals) ku0 is transformed into the intermediate 
-  //     (n by m array of reals) kx0 (wn)
-  ku_ = vmmul<row>(ku0_, real_matrix_type(n_, m_, T(1)));
-
-  k1_ = vmmul<col>(k_, real_matrix_type(n_, m_, T(1)));
-
-  kx0_ = 4 * sq(k1_) - sq(ku_);
-
-  // 71. (n by m array of reals) kx is the Doppler domain range 
-  //     wavenumber (wn)    
-  kx_ = sqrt(max(T(0), kx0_));
-
-  // 72. (scalar, real) minimum wavenum (wn)
-  Index<2> idx;
-  T kx_min = minval(kx_, idx);
-
-  // 73. (scalar, real) maximum wavenum (wn)
-  T kx_max = maxval(kx_, idx);
-
-  // 74. (scalar, real) Nyquist sample spacing in kx domain (wn)
-  T dkx = M_PI / X0_;
-
-  // 75. (scalar, integer) nx0 is the min number of required kx samples 
-  //     (pixels);  (later it will be increased slightly to avoid 
-  //     negative array indexing)
-  index_type nx0 = static_cast<index_type>
-    (2 * ceil((kx_max - kx_min) / (2 * dkx)));   
-
-  // generate the Doppler domain representation the reference signal's 
-  // complex conjugate
-
-  // 76. (n by m array of complex nums) reference signal's complex conjugate
-  for (index_type i = 0; i < n_; ++i)
-    for (index_type j = 0; j < m_; ++j)
-    {
-      if (kx_(i, j) > 0)
-        fs_ref_(i, j) = exp(complex<T>(0, 1) * 
-          (Xc_ * (kx_(i, j) - T(2) * k_(i)) + T(0.25*M_PI) + ku_(i, j)));
-    }
-
-  SAVE_VIEW("p76_fs_ref.view", fs_ref_);
-
   // match filter the spotlighted signal 'fsSpotLit' with the reference's 
   // complex conjugate 'fsRef' along fast-time and slow-time, to remove 
   // the reference signal's spectral components.
 
   // 77. (n by m array of complex nums) Doppler domain matched-filtered signal
-  fsm_ = fs_spotlit_ * fs_ref_;
+  fsm_ = fs_spotlit_ * this->fs_ref_;
 
-  // 78. (scalar, int) interpolation processing sliver size
-  length_type I = 2 * interp_sidelobes_ + 1;
-                            
-  // 79. (scalar, real) +/- interpolation neighborhood size in KX domain
-  T kxs = interp_sidelobes_ * dkx;  
-
-  // 80. (scalar, int) total number of kx samples required in the SAR 
-  //     image's col (in pixels; increased to avoid negative array 
-  //     indexing in interpolation loop)
-  nx_ = nx0 + 2 * interp_sidelobes_ + 4;
-
-  // 81. (scalar, real) range sample spacing 
-  T dx = 2 * M_PI / (nx_ * dkx);             
-
-  // 82. (1 by nx array of reals) range array
-  real_vector_type x(nx_);
-  for (index_type i = 0; i < nx_; ++i)
-    x.put(i, dx * (i - nx_/2));
-
-  // 83. (1 by nx array of reals) uniformly-spaced KX0 points where 
-  //     interpolation is done  
-  real_vector_type KX0(nx_);
-  for (index_type i = 0; i < nx_; ++i)
-    KX0.put(i, kx_min + (T(i) - interp_sidelobes_ - 2.f) * dkx);
-
-  // 84. (scalar, real) carrier frequency in KX domain, where (nx/2+1) 
-  //     is its index number
-  T kxc = KX0.get(nx_ / 2);
-
-  // 85. KX0 (1 by nx array of reals) is expanded to the SAR image's 
-  //     final dims of (nx by m array of reals).
-  real_matrix_type KX(nx_, m_);
-  KX = vmmul<col>(KX0, real_matrix_type(nx_, m_, T(1)));
-
   // 86a. initialize the F(kx,ku) array
-  complex_matrix_type F(nx_, m_, complex<T>(0));
+  F_ = complex<T>(0);
 
   // 86b. begin the range loop
   for (index_type i = 0; i < n_; ++i)
@@ -399,85 +474,58 @@
     //     cross-range sliver in the KX domain
     for (index_type j = 0; j < m_; ++j)
       icKX_(j) = static_cast<index_type>(
-        ((kx_.get(i, j) - KX.get(0, 0)) / dkx) + 0.5f);
+        ((this->kx_.get(i, j) - KX_.get(0, 0)) / this->dkx_) + 0.5f);
 
     // 88. (I by m array of ints) ikx are the indices of the slice that 
     //     include the cross-range sliver at its center
-    Matrix<index_type> ikxrows(I, m_);
-    Matrix<index_type> ikxcols(I, m_);
-    real_matrix_type nKX(I, m_);
-    real_matrix_type SINC(I, m_);
-    real_matrix_type HAM(I, m_);
+    index_type ikxrows;
+    index_type ikxcols;
 
-    for (index_type h = 0; h < I; ++h)
+    for (index_type h = 0; h < this->I_; ++h)
       for (index_type j = 0; j < m_; ++j)
       {
-        ikxrows.put(h, j, icKX_.get(j) + (h - interp_sidelobes_));
-        ikxcols.put(h, j, j);
+        ikxrows = icKX_.get(j) + h - this->interp_sidelobes_;
+        ikxcols = j;
 
         // 89. (I by m array of reals) nKX are the signal values 
         //     of the corresponding slice
-        nKX.put(h, j, KX.get(ikxrows.get(h, j), ikxcols.get(h, j)));
+        T nKX = KX_.get(ikxrows, ikxcols);
 
         // 90. (I by m array of reals) SINC is the interpolating window 
         //     (note not stand-alone sinc coefficients)
-        T sx = M_PI * (nKX.get(h, j) - kx_.get(i, j)) / dkx;
-        SINC.put(h, j, (sx ? sin(sx) / sx : 1));
+        T sx = M_PI * (nKX - this->kx_.get(i, j)) / this->dkx_;
+        T SINC = (sx ? sin(sx) / sx : 1);
 
         // reduce interpolation computational costs by using a tapered 
         // window
     
         // 91. (I by m array of reals) (not stand-alone Hamming 
         //     coefficients)
-        HAM.put(h, j, 0.54 + 0.46 * cos((M_PI / kxs) * 
-                  (nKX.get(h, j) - kx_.get(i, j))));
+        T HAM = 0.54 + 0.46 * cos((M_PI / this->kxs_) * 
+                  (nKX - this->kx_.get(i, j)));
 
         // sinc convolution interpolation of the signal's Doppler 
         // spectrum, from polar to rectangular coordinates 
     
         // 92. (nx by m array of complex nums) F is the rectangular signal 
         //     spectrum
-        F.put(ikxrows.get(h, j), ikxcols.get(h, j), 
-          F.get(ikxrows.get(h, j), ikxcols.get(h, j)) + 
-          (fsm_.get(i, j) * SINC.get(h, j) * HAM.get(h, j)));
+        F_.put(ikxrows, ikxcols, F_.get(ikxrows, ikxcols) + 
+          (fsm_.get(i, j) * SINC * HAM));
       }
 
   } // 93. end the range loop
 
-  SAVE_VIEW("p92_F.view", F);
+  SAVE_VIEW("p92_F.view", F_);
 
 
   // transform from the Doppler domain image into a spatial domain image
 
   // 94. (nx by m array of complex nums) spatial image (complex pixel 
   //     intensities) 
-  typedef Fftm<complex<T>, complex<T>, row, fft_inv> ifftmr_type;
-  ifftmr_type ifftmr(Domain<2>(nx_, m_), T(1./m_));
+  fftshift(F_, F_shifted_);
+  fftshift(ifftmr_(ifftmc_(F_shifted_)), spatial_);
 
-  typedef Fftm<complex<T>, complex<T>, col, fft_inv> ifftmc_type;
-  ifftmc_type ifftmc(Domain<2>(nx_, m_), T(1./nx_));
-      
-  complex_matrix_type F_shifted(nx_, m_);
-  fftshift(F, F_shifted);
-
-  complex_matrix_type spatial(nx_, m_);
-  fftshift(ifftmr(ifftmc(F_shifted)), spatial);
-
-#ifdef VERBOSE
-  std::cout << "kx_min = " << kx_min << std::endl;
-  std::cout << "kx_max = " << kx_max << std::endl;
-  std::cout << "kxc = " << kxc << std::endl;
-  std::cout << "dkx = " << dkx << std::endl;
-  std::cout << "nx0 = " << nx0 << std::endl;
-  std::cout << "nx = " << nx_ << std::endl;
-  std::cout << "dx = " << dx << std::endl;
-  std::cout << "kxc = " << kxc << std::endl;
-#endif
-
   // for viewing, transpose spatial's magnitude 
   // 95. (m by nx array of reals) image (pixel intensities)
-  return mag(spatial.transpose());
+  image = mag(spatial_.transpose());
 }
-
-
-
Index: apps/ssar/ssar.cpp
===================================================================
--- apps/ssar/ssar.cpp	(revision 153966)
+++ apps/ssar/ssar.cpp	(working copy)
@@ -37,6 +37,9 @@
 int
 main(int argc, char** argv)
 {
+  using vsip_csl::load_view_as;
+  using vsip_csl::save_view_as;
+
   vsip::vsipl init(argc, argv);
 
   ssar_options opt;
@@ -46,12 +49,21 @@
   // Setup for Stage 1, Kernel 1 
   Kernel1<double> k1(opt.scale, opt.n, opt.mc, opt.m); 
 
-  // Process an image at a time.  
-  //
-  // This step includes a Data I/O component, where the raw data is 
-  // retrieved from disk, as well as a Computation component, where 
-  // the image is resolved from the incoming radar data.
-  k1.process_image();
+  // Retrieve the raw radar image data from disk.  This Data I/O 
+  // component is currently untimed.
+  Kernel1<double>::complex_matrix_type s_raw(opt.n, opt.mc);
+  load_view_as<complex<float>, 
+    Kernel1<double>::complex_matrix_type>(RAW_SAR_DATA, s_raw);
+
+
+  // Resolve the image.  This Computation component is timed.
+  Kernel1<double>::real_matrix_type 
+    image(k1.output_size(0), k1.output_size(1));
+  k1.process_image(s_raw, image);
+
+
+  // Store the image on disk for later processing (not timed).
+  save_view_as<float>("image.view", image); 
 }
 
 
