Index: ChangeLog
===================================================================
--- ChangeLog	(revision 154837)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2006-11-16  Jules Bergmann  <jules@codesourcery.com>
+
+	* apps/ssar/ssar.cpp: Add -loop option.
+	* apps/ssar/kernel1.hpp: Perform digital_spotlighting processing
+	  by row/column.  Use explicit corner-turn during inverse 2D FFT.
+	
 2006-11-15  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/fft.hpp (base_interface): Fix ops count for Fftms.
Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 154746)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -234,8 +234,9 @@
   typedef typename Kernel1_base<T>::real_matrix_type real_matrix_type;
   typedef typename Kernel1_base<T>::real_vector_type real_vector_type;
 
-  typedef Fftm<complex<T>, complex<T>, col, fft_fwd, by_reference> col_fftm_type;
-  typedef Fftm<complex<T>, complex<T>, row, fft_fwd, by_reference> row_fftm_type;
+  typedef Fft<const_Vector, complex<T>, complex<T>, fft_fwd, by_reference> col_fft_type;
+  typedef Fft<const_Vector, complex<T>, complex<T>, fft_fwd, by_reference> row_fft_type;
+  typedef Fft<const_Vector, complex<T>, complex<T>, fft_inv, by_reference> ifftr_type;
   typedef Fftm<complex<T>, complex<T>, row, fft_inv, by_reference> ifftmr_type;
   typedef Fftm<complex<T>, complex<T>, col, fft_inv, by_reference> ifftmc_type;
 
@@ -265,11 +266,11 @@
   length_type m_;
 
   complex_col_matrix_type s_filt_;
+  complex_matrix_type s_filt_t_;
   complex_matrix_type s_compr_filt_;
-  complex_matrix_type fs_spotlit_;
-  complex_matrix_type s_compr_;
-  complex_matrix_type fs_;
-  complex_matrix_type fs_padded_;
+  Vector<complex<T> > s_compr_row_;
+  Vector<complex<T> > fs_row_;
+  Vector<complex<T> > fs_padded_row_;
   complex_matrix_type s_decompr_filt_;
   complex_matrix_type fsm_;
   Matrix<index_type> icKX_;
@@ -278,13 +279,16 @@
   real_matrix_type KX_;
   Tensor<T> SINC_HAM_;
   complex_matrix_type F_;
-  complex_matrix_type F_shifted_;
+  complex_col_matrix_type F_shifted_;
+  complex_matrix_type tmp_;
+  Vector<complex<T> > tmp_col_;
   complex_matrix_type spatial_;
+  real_matrix_type image_t_;
 
-  col_fftm_type col_fftm_;
-  row_fftm_type row_fftm_;
-  row_fftm_type row_fftm2_;
-  ifftmr_type ifftm_;
+  col_fft_type col_fft_;
+  row_fft_type row_fft_;
+  row_fft_type row_fft2_;
+  ifftr_type ifft_;
   ifftmr_type ifftmr_;
   ifftmc_type ifftmc_;
 };
@@ -296,11 +300,11 @@
   : Kernel1_base<T>(scale, n, mc, m),
     scale_(scale), n_(n), mc_(mc), m_(m), 
     s_filt_(n, mc),
+    s_filt_t_(n, mc),
     s_compr_filt_(n, mc),
-    fs_spotlit_(n, m),
-    s_compr_(n, mc),
-    fs_(n, mc),
-    fs_padded_(n, m),
+    s_compr_row_(mc),
+    fs_row_(mc),
+    fs_padded_row_(m),
     s_decompr_filt_(n, m),
     fsm_(n, m),
     icKX_(n, m),
@@ -310,11 +314,14 @@
     SINC_HAM_(n_, m_, this->I_),
     F_(this->nx_, m_),
     F_shifted_(this->nx_, m_),
+    tmp_(this->nx_, m_),
+    tmp_col_(n_),
     spatial_(this->nx_, m_),
-    col_fftm_(Domain<2>(n, mc), T(1)),
-    row_fftm_(Domain<2>(n, mc), T(1)),
-    row_fftm2_(Domain<2>(n, m), T(1)),
-    ifftm_(Domain<2>(n, m), T(1.f/m)),
+    image_t_(this->nx_, m_),
+    col_fft_(Domain<1>(n), T(1)),
+    row_fft_(Domain<1>(mc), T(1)),
+    row_fft2_(Domain<1>(m), T(1)),
+    ifft_(Domain<1>(m), T(1.f/m)),
     ifftmr_(Domain<2>(this->nx_, m_), T(1./m_)),
     ifftmc_(Domain<2>(this->nx_, m_), T(1./this->nx_))
 {
@@ -350,7 +357,7 @@
       // 87. (1 by m array of ints) icKX are the indices of the closest 
       //     cross-range sliver in the KX domain
       icKX_(i, j) = static_cast<index_type>(
-        ((this->kx_.get(i, j) - KX_.get(0, 0)) / this->dkx_) + 0.5f);
+        ((this->kx_.get(i, j) - KX0_.get(0)) / this->dkx_) + 0.5f);
 
       // 88. (I by m array of ints) ikx are the indices of the slice that 
       //     include the cross-range sliver at its center
@@ -361,7 +368,7 @@
       {
         // 89. (I by m array of reals) nKX are the signal values 
         //     of the corresponding slice
-        T nKX =  KX_.get(ikxrows + h, j);
+        T nKX =  KX0_.get(ikxrows + h);
 
         // 90. (I by m array of reals) SINC is the interpolating window 
         //     (note not stand-alone sinc coefficients)
@@ -398,7 +405,7 @@
   // Time the remainder of this function, provided profiling is enabled 
   // (pass '--vsipl++-profile-mode=[accum|trace]' on the command line).  
   // If profiling is not enabled, then this statement has no effect.
-  impl::profile::Scope_event kernel1_event("Kernel1 total", 1);
+  impl::profile::Scope_event kernel1_event("Kernel1 total", 391015615);
 
 
   // Digital spotlighting and bandwidth-expansion using slow-time 
@@ -418,66 +425,99 @@
 void
 Kernel1<T>::digital_spotlighting(complex_matrix_type s_raw)
 {
+  impl::profile::Scope_event kernel1_event("digital_spotlighting", 135485380);
   using vsip_csl::matlab::fftshift;
   assert(s_raw.size(0) == n_);
   assert(s_raw.size(1) == mc_);
 
+  // 64. (scalar, int) number of zeros to be padded into the ku domain 
+  //     for slow-time upsampling
+  length_type mz = m_ - mc_;
+
+  // Domains for bandwidth expansion.
+  Domain<1> left(0, 1, mc_/2);
+  Domain<1> center_dst(mc_/2, 1, mz);
+  Domain<1> right_dst(mz + mc_/2, 1, mc_/2);
+  Domain<1> right_src(mc_/2, 1, mc_/2);
+
+  // left/right domains for emulating fftshift of fs_padded_row_.
+  Domain<1> ldom(0, 1, m_/2);
+  Domain<1> rdom(m_/2, 1, m_/2);
+
   // The baseband reference signal is first transformed into the Doppler 
   // (spatial frequency) domain.  
 
+  // corner-turn: to col-major
+  fftshift(s_raw, s_filt_); 
+
   // 59. (n by mc array of complex numbers) filtered echoed signal
-  s_filt_ = vmmul<col>(this->fast_time_filter_, 
-    col_fftm_(fftshift(s_raw, s_filt_)));
+  for (index_type c=0; c<mc_; ++c)
+  {
+    col_fft_(s_filt_.col(c), tmp_col_);
+    s_filt_.col(c) = tmp_col_ * this->fast_time_filter_;
+  }
 
   SAVE_VIEW("p59_s_filt.view", vsip_csl::matlab::fftshift(s_filt_));
 
-  // 62. (n by mc array of complex numbers) signal compressed along 
-  //     slow-time (note that to view 'sCompr' it will need to be 
-  //     fftshifted first.)
-  s_compr_ = s_filt_ * s_compr_filt_;
+  // corner-turn: to row-major
+  s_filt_t_ = s_filt_;
 
-  SAVE_VIEW("p62_s_compr.view", fftshift(s_compr_));
+  for (index_type r=0; r<n_; ++r)
+  {
+    // 62. (n by mc array of complex numbers) signal compressed along 
+    //     slow-time (note that to view 'sCompr' it will need to be 
+    //     fftshifted first.)
+    s_compr_row_ = s_filt_t_.row(r) * s_compr_filt_.row(r);
 
-  // 63. (n by mc array of complex numbers) narrow-bandwidth polar format
-  //     reconstruction along slow-time
-  fs_ = row_fftm_(s_compr_);
+    SAVE_VIEW("p62_s_compr.view", fftshift(s_compr_));
 
-  // 64. (scalar, int) number of zeros to be padded into the ku domain 
-  //     for slow-time upsampling
-  length_type mz = m_ - mc_;
+    // 63. (n by mc array of complex numbers) narrow-bandwidth polar format
+    //     reconstruction along slow-time
+    row_fft_(s_compr_row_, fs_row_);
 
-  // 65. (n by m array of complex numbers) zero pad the spatial frequency 
-  //     domain's compressed signal along its slow-time (note that to view 
-  //     'fsPadded' it will need to be fftshifted first)
-  fs_ *= static_cast<T>(m_) / mc_;
+    // 65. (n by m array of complex numbers) zero pad the spatial frequency 
+    //     domain's compressed signal along its slow-time (note that to view 
+    //     'fsPadded' it will need to be fftshifted first)
+    // fs_row_ *= static_cast<T>(m_) / mc_;
+    T scale = static_cast<T>(m_) / mc_;
 
-  Domain<2> left(Domain<1>(0, 1, n_), Domain<1>(0, 1, mc_/2));
-  Domain<2> center_dst(Domain<1>(0, 1, n_), Domain<1>(mc_/2, 1, mz));
-  Domain<2> right_dst(Domain<1>(0, 1, n_), Domain<1>(mz + mc_/2, 1, mc_/2));
-  Domain<2> right_src(Domain<1>(0, 1, n_), Domain<1>(mc_/2, 1, mc_/2));
+    fs_padded_row_(left)       = scale * fs_row_(left);
+    fs_padded_row_(center_dst) = T();
+    fs_padded_row_(right_dst)  = scale * fs_row_(right_src);
 
-  fs_padded_(left) = fs_(left);
-  fs_padded_(center_dst) = T();
-  fs_padded_(right_dst) = fs_(right_src);
+    SAVE_VIEW("p65_fs_padded.view", fftshift(fs_padded_));
 
-  SAVE_VIEW("p65_fs_padded.view", fftshift(fs_padded_));
+    // 66. (n by m array of complex numbers) transform-back the zero 
+    // padded spatial spectrum along its cross-range
+    ifft_(fs_padded_row_);
 
-  // 66. (n by m array of complex numbers) transform-back the zero 
-  // padded spatial spectrum along its cross-range
-  ifftm_(fs_padded_);
+    // 68. (n by m array of complex numbers) slow-time decompression (note 
+    //     that to view 'sDecompr' it will need to be fftshifted first.)
+    fs_padded_row_ *= s_decompr_filt_.row(r);
 
-  // 68. (n by m array of complex numbers) slow-time decompression (note 
-  //     that to view 'sDecompr' it will need to be fftshifted first.)
-  fs_padded_ *= s_decompr_filt_;
+    SAVE_VIEW("p68_s_decompr.view", fftshift(fs_padded_));
 
-  SAVE_VIEW("p68_s_decompr.view", fftshift(fs_padded_));
+    // 69. (n by m array of complex numbers) digitally-spotlighted SAR 
+    //     signal spectrum
+    row_fft2_(fs_padded_row_);
 
-  // 69. (n by m array of complex numbers) digitally-spotlighted SAR 
-  //     signal spectrum
-  fftshift(row_fftm2_(fs_padded_), fs_spotlit_);
+    index_type xr = (r < n_/2) ? (n_/2 + r) : (r - n_/2);
 
-  SAVE_VIEW("p69_fs_spotlit.view", fs_spotlit_);
+    // 77. (n by m array of complex nums) Doppler domain matched-filtered
+    //     signal
 
+    // Merge fftshift and vmul:
+    //
+    //   fftshift(fs_padded_row_, fs_spotlit_row_);
+    //   fsm_.row(xr) = fs_spotlit_row_ * this->fs_ref_.row(xr);
+    //
+
+    fsm_.row(xr)(ldom) = fs_padded_row_(rdom) * this->fs_ref_.row(xr)(ldom);
+    fsm_.row(xr)(rdom) = fs_padded_row_(ldom) * this->fs_ref_.row(xr)(rdom);
+
+    SAVE_VIEW("p69_fs_spotlit.view", fs_spotlit_);
+  }
+
 #ifdef VERBOSE
   std::cout << "mz = " << mz << std::endl;
 #endif
@@ -489,6 +529,7 @@
 void // Matrix<T>
 Kernel1<T>::interpolation(real_matrix_type image)
 {
+  impl::profile::Scope_event kernel1_event("interpolation", 255530235);
   using vsip_csl::matlab::fftshift;
   assert(image.size(0) == n_);
   assert(image.size(1) == mc_);
@@ -497,13 +538,12 @@
   // complex conjugate 'fsRef' along fast-time and slow-time, to remove 
   // the reference signal's spectral components.
 
-  // 77. (n by m array of complex nums) Doppler domain matched-filtered signal
-  fsm_ = fs_spotlit_ * this->fs_ref_;
 
   // 86a. initialize the F(kx,ku) array
   F_ = complex<T>(0);
 
   // 86b. begin the range loop
+  { impl::profile::Scope_event kernel1_event("interpolate", 83393024);
   for (index_type i = 0; i < n_; ++i)
   {
     for (index_type j = 0; j < m_; ++j)
@@ -525,6 +565,7 @@
     }
 
   } // 93. end the range loop
+  }
 
   SAVE_VIEW("p92_F.view", F_);
 
@@ -533,9 +574,15 @@
 
   // 94. (nx by m array of complex nums) spatial image (complex pixel 
   //     intensities) 
-  fftshift(ifftmr_(ifftmc_(fftshift(F_, F_shifted_))), spatial_);
+  // fftshift(ifftmr_(ifftmc_(fftshift(F_, F_shifted_))), spatial_);
+  fftshift(F_, F_shifted_);
+  ifftmc_(F_shifted_);
+  tmp_ = F_shifted_;
+  ifftmr_(tmp_);
+  fftshift(tmp_, spatial_);
 
   // for viewing, transpose spatial's magnitude 
   // 95. (m by nx array of reals) image (pixel intensities)
-  image = mag(spatial_.transpose());
+  image_t_ = mag(spatial_);
+  image = image_t_.transpose();
 }
Index: apps/ssar/ssar.cpp
===================================================================
--- apps/ssar/ssar.cpp	(revision 154746)
+++ apps/ssar/ssar.cpp	(working copy)
@@ -33,7 +33,12 @@
 void
 process_ssar_options(int argc, char** argv, ssar_options& options);
 
+// Options set in process_ssar_options
 
+int loop = 1;  // Number of process_image iterations to perform (default 1)
+
+
+
 int
 main(int argc, char** argv)
 {
@@ -59,8 +64,18 @@
   // Resolve the image.  This Computation component is timed.
   Kernel1<double>::real_matrix_type 
     image(k1.output_size(0), k1.output_size(1));
-  k1.process_image(s_raw, image);
 
+  // Process the image.
+  vsip::impl::profile::Acc_timer t1;
+  for (int l=0; l<loop; ++l)
+  {
+    t1.start();
+    k1.process_image(s_raw, image);
+    t1.stop();
+    cout << t1.delta() << endl;
+  }
+  if (loop > 1)
+    cout << "average: "  << t1.total() / t1.count() << endl;
 
   // Store the image on disk for later processing (not timed).
   save_view_as<float>("image.view", image); 
@@ -70,15 +85,30 @@
 void
 process_ssar_options(int argc, char** argv, ssar_options& options)
 {
-  if (argc != 2)
+  char* dir = 0;
+
+  for (int i=1; i<argc; ++i)
   {
-    cerr << "Usage: " << argv[0] << " <data dir>" << endl;
-    exit(-1);
+    if (!strcmp(argv[i], "-loop")) loop = atoi(argv[++i]);
+    else if (dir == 0) dir = argv[i];
+    else
+    {
+      cerr << "Unknown arg: " << argv[i] << endl;
+      cerr << "Usage: " << argv[0] << " [-loop] <data dir>" << endl;
+      exit(-1);
+    }
   }
 
-  if (chdir(argv[1]) < 0)
+  if (dir == 0)
   {
-    perror(argv[1]);
+      cerr << "No dir given" << endl;
+      cerr << "Usage: " << argv[0] << " [-loop] <data dir>" << endl;
+      exit(-1);
+  }
+
+  if (chdir(dir) < 0)
+  {
+    perror(dir);
     exit(-1);
   }
 
