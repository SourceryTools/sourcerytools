Index: ChangeLog
===================================================================
--- ChangeLog	(revision 228625)
+++ ChangeLog	(working copy)
@@ -1,3 +1,19 @@
+2008-11-21  Jules Bergmann  <jules@codesourcery.com>
+
+	HPEC SSAR Optimizations
+	* apps/ssar/kernel1.hpp: optimizations for Cell: Half-fast
+	  convolutions, remove fftshift in compute path, ensure
+	  128-byte alignment, place large dataset in huge-page memory.
+	* apps/ssar/ssar.cpp: Likewise.
+	* src/vsip/core/parallel/local_map.hpp (impl_set_pool): Allow
+	  memory pool to be set.
+	* src/vsip/core/huge_page_pool.cpp: Maintain 128-byte alignment.
+	* src/vsip/opt/ukernel/kernels/cbe_accel/interp_f.hpp: Vectorize,
+	  unroll, and perform freq-domain fftshfit.
+	* src/vsip_csl/memory_pool.hpp: User API for memory pool extension.
+	* src/vsip_csl/matlab_utils.hpp: Partial matrix fftshifts.  Freq-
+	  domain matrix fftshifts.
+	
 2008-11-20  Jules Bergmann  <jules@codesourcery.com>
 
 	Fix ukernel/interp.cpp 64-bit failure:
Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 228622)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -13,14 +13,12 @@
 #include <vsip/selgen.hpp>
 
 #include <vsip/core/profile.hpp>
-#include <vsip_csl/ukernel.hpp>
-#include <vsip/opt/ukernel/kernels/host/interp.hpp>
 
 #include <vsip_csl/matlab_utils.hpp>
 #include <vsip_csl/save_view.hpp>
 #include <vsip_csl/load_view.hpp>
 
-#if 1
+#if 0
 #define VERBOSE
 #define SAVE_VIEW(a, b, c)    vsip_csl::save_view_as<complex<float> >(a, b, c)
 #else
@@ -28,6 +26,7 @@
 #endif
 
 
+
 // This compiler switch changes the way the digital spotlighting routine
 // interacts with the cache.
 // 
@@ -39,7 +38,11 @@
 // entire image before proceeding to the next.  This can be more efficient
 // on certain architectures (such as Cell/B.E.) where large computations
 // can be distributed amongst several compute elements and run in parallel.
-#define DIGITAL_SPOTLIGHT_BY_ROW  1
+#if VSIP_IMPL_CBE_SDK
+#  define DIGITAL_SPOTLIGHT_BY_ROW  0
+#else
+#  define DIGITAL_SPOTLIGHT_BY_ROW  1
+#endif
 
 
 // On Cell/B.E. platforms, this may be defined to utilize a user-defined
@@ -52,22 +55,51 @@
 //
 // Setting it to '0' will perform the computation entirely on the PPE
 // as it does on x86 processors.
-#define USE_CELL_UKERNEL  0
+#if VSIP_IMPL_CBE_SDK
+#  define USE_CELL_UKERNEL 1
+#else
+#  define USE_CELL_UKERNEL 0
+#endif
 
+#if USE_CELL_UKERNEL
+#  include <vsip_csl/ukernel.hpp>
+#  include <vsip/opt/ukernel/kernels/host/interp.hpp>
+#endif
 
+
 template <typename T>
 class Kernel1_base
 {
 protected:
-  typedef Matrix<complex<T>, Dense<2, complex<T>, col2_type> > complex_col_matrix_type;
-  typedef Matrix<complex<T> > complex_matrix_type;
+#if VSIP_IMPL_CBE_SDK
+  typedef vsip::impl::Layout<2, row2_type, vsip::impl::Stride_unit_align<128>,
+		             vsip::impl::dense_complex_type>
+		row_layout_type;
+  typedef vsip::impl::Layout<2, col2_type, vsip::impl::Stride_unit_align<128>,
+			     vsip::impl::dense_complex_type>
+		col_layout_type;
+  typedef vsip::impl::Fast_block<2, T, row_layout_type> real_row_block_type;
+  typedef vsip::impl::Fast_block<2, T, col_layout_type> real_col_block_type;
+  typedef vsip::impl::Fast_block<2, complex<T>, row_layout_type>
+		complex_row_block_type;
+  typedef vsip::impl::Fast_block<2, complex<T>, col_layout_type>
+		complex_col_block_type;
+#else
+  typedef Dense<2, complex<T>, col2_type> complex_col_block_type;
+  typedef Dense<2, complex<T>, row2_type> complex_row_block_type;
+  typedef Dense<2, T, col2_type> real_col_block_type;
+  typedef Dense<2, T, row2_type> real_row_block_type;
+#endif
+
+  typedef Matrix<complex<T>, complex_col_block_type> complex_col_matrix_type;
+  typedef Matrix<complex<T>, complex_row_block_type> complex_matrix_type;
+  typedef Matrix<T, real_col_block_type> real_col_matrix_type;
+  typedef Matrix<T, real_row_block_type> real_matrix_type;
   typedef Vector<complex<T> > complex_vector_type;
-  typedef Matrix<T, Dense<2, T, col2_type> > real_col_matrix_type;
-  typedef Matrix<T> real_matrix_type;
   typedef Vector<T> real_vector_type;
 
   Kernel1_base(scalar_f scale, length_type n, length_type mc, 
-    length_type m, bool swap_bytes);
+    length_type m, bool swap_bytes, Local_map huge_map);
   ~Kernel1_base() {}
 
   scalar_f scale_;
@@ -90,6 +122,7 @@
 
   complex_vector_type fast_time_filter_;
   complex_matrix_type fs_ref_;
+  complex_matrix_type fs_ref_preshift_;
   real_vector_type ks_;
   real_vector_type ucs_;
   real_vector_type us_;
@@ -98,16 +131,18 @@
 
 template <typename T>
 Kernel1_base<T>::Kernel1_base(scalar_f scale, length_type n, 
-  length_type mc, length_type m, bool swap_bytes)
+  length_type mc, length_type m, bool swap_bytes, Local_map huge_map)
   : scale_(scale), n_(n), mc_(mc), m_(m), swap_bytes_(swap_bytes),
     fast_time_filter_(n),
     fs_ref_(n, m),
+    fs_ref_preshift_(n, m, huge_map),
     ks_(n),
     ucs_(mc),
     us_(m),
     kx_(n, m)
 {
   using vsip_csl::matlab::fftshift;
+  using vsip_csl::matlab::fd_fftshift;
   using vsip_csl::load_view_as;
 
   interp_sidelobes_ = 8;     // 2. (scalar, integer) number of 
@@ -204,6 +239,8 @@
   //    fs_ref_.put(i, j, (kx_.get(i, j) > 0) ? exp(...) : complex<T>(0));
   fs_ref_ = ite(kx_ > 0, exp(complex<T>(0, 1) * 
     (Xc_ * (kx_ - 2 * k1) + T(0.25 * M_PI) + ku)), complex<T>(0));
+  fftshift<col>(fs_ref_, fs_ref_preshift_);
+  fd_fftshift<row>(fs_ref_preshift_, fs_ref_preshift_);
 
   SAVE_VIEW("p76_fs_ref.view", fs_ref_, swap_bytes_);
 
@@ -253,12 +290,15 @@
   typedef Fft<const_Vector, complex<T>, complex<T>, fft_fwd, by_reference> row_fft_type;
   typedef Fft<const_Vector, complex<T>, complex<T>, fft_inv, by_reference> inv_fft_type;
   typedef Fftm<complex<T>, complex<T>, row, fft_fwd, by_reference> row_fftm_type;
-  typedef Fftm<complex<T>, complex<T>, col, fft_fwd, by_reference> col_fftm_type;
+  typedef Fftm<complex<T>, complex<T>, row, fft_fwd, by_value> val_row_fftm_type;
+  //FOO typedef Fftm<complex<T>, complex<T>, col, fft_fwd, by_reference> col_fftm_type;
+  typedef Fftm<complex<T>, complex<T>, col, fft_fwd, by_value> val_col_fftm_type;
   typedef Fftm<complex<T>, complex<T>, row, fft_inv, by_reference> inv_row_fftm_type;
+  typedef Fftm<complex<T>, complex<T>, row, fft_inv, by_value> val_inv_row_fftm_type;
   typedef Fftm<complex<T>, complex<T>, col, fft_inv, by_reference> inv_col_fftm_type;
 
   Kernel1(scalar_f scale, length_type n, length_type mc, length_type m,
-    bool swap_bytes);
+	  bool swap_bytes, Local_map huge_map);
   ~Kernel1() {}
 
   void process_image(complex_matrix_type const input, 
@@ -298,17 +338,23 @@
 
   complex_col_matrix_type s_filt_;
   complex_matrix_type s_filt_t_;
+#if DIGITAL_SPOTLIGHT_BY_ROW
   complex_matrix_type s_compr_filt_;
+#else
+  complex_col_matrix_type s_compr_filt_;
+  complex_col_matrix_type s_compr_filt_shift_;
+#endif
   complex_matrix_type s_decompr_filt_;
+#if !DIGITAL_SPOTLIGHT_BY_ROW
+  complex_matrix_type s_decompr_filt_shift_;
+#endif
   complex_matrix_type fsm_;
   complex_col_matrix_type fsm_t_;
   Matrix<index_type, Dense<2, index_type, col2_type> > icKX_;
   real_vector_type KX0_;
   Tensor<T, Dense<3, T, tuple<1, 0, 2> > > SINC_HAM_;
   complex_col_matrix_type F_;
-  complex_matrix_type F_shifted_;
-  complex_col_matrix_type spatial_;
-  real_col_matrix_type image_t_;
+  complex_matrix_type spatial_;
 
 #if DIGITAL_SPOTLIGHT_BY_ROW
   Vector<complex<T> > fs_row_;
@@ -322,10 +368,10 @@
   complex_matrix_type s_compr_;
   complex_matrix_type fs_;
   complex_matrix_type fs_padded_;
-  col_fftm_type ft_fftm_;
-  row_fftm_type st_fftm_;
+  val_col_fftm_type ft_fftm_;
+  val_row_fftm_type st_fftm_;
   row_fftm_type compr_fftm_;
-  inv_row_fftm_type decompr_fftm_;
+  val_inv_row_fftm_type decompr_fftm_;
 #endif
   inv_row_fftm_type ifftmr_;
   inv_col_fftm_type ifftmc_;
@@ -334,22 +380,26 @@
 
 template <typename T>
 Kernel1<T>::Kernel1(scalar_f scale, length_type n, length_type mc, 
-  length_type m, bool swap_bytes)
-  : Kernel1_base<T>(scale, n, mc, m, swap_bytes),
+  length_type m, bool swap_bytes, Local_map huge_map)
+  : Kernel1_base<T>(scale, n, mc, m, swap_bytes, huge_map),
     scale_(scale), n_(n), mc_(mc), m_(m), 
-    s_filt_(n, mc),
+    s_filt_(n, mc, huge_map),
     s_filt_t_(n, mc),
     s_compr_filt_(n, mc),
+#if !DIGITAL_SPOTLIGHT_BY_ROW
+    s_compr_filt_shift_(n, mc, huge_map),
+#endif
     s_decompr_filt_(n, m),
-    fsm_(n, m),
-    fsm_t_(n, m),
-    icKX_(n, m),
+#if !DIGITAL_SPOTLIGHT_BY_ROW
+    s_decompr_filt_shift_(n, m, huge_map),
+#endif
+    fsm_(n, m, huge_map),
+    fsm_t_(n, m, huge_map),
+    icKX_(n, m, huge_map),
     KX0_(this->nx_),
-    SINC_HAM_(n_, m_, this->I_),
-    F_(this->nx_, m_),
-    F_shifted_(this->nx_, m_),
-    spatial_(this->nx_, m_),
-    image_t_(this->nx_, m_),
+    SINC_HAM_(n_, m_, 20 /*this->I_*/, huge_map),
+    F_(this->nx_, m_, huge_map),
+    spatial_(this->nx_, m_, huge_map),
 #if DIGITAL_SPOTLIGHT_BY_ROW
     fs_row_(mc),
     fs_spotlit_row_(m),
@@ -360,8 +410,8 @@
 #else
     fs_spotlit_(n, m),
     s_compr_(n, mc),
-    fs_(n, mc),
-    fs_padded_(n, m),
+    fs_(n, mc, huge_map),
+    fs_padded_(n, m, huge_map),
     ft_fftm_(Domain<2>(n, mc), T(1)),
     st_fftm_(Domain<2>(n, m), T(1)),
     compr_fftm_(Domain<2>(n, mc), static_cast<T>(m_) / mc_),
@@ -370,6 +420,9 @@
     ifftmr_(Domain<2>(this->nx_, m_), T(1./m_)),
     ifftmc_(Domain<2>(this->nx_, m_), T(1./this->nx_))
 {
+  using vsip_csl::matlab::fftshift;
+  using vsip_csl::matlab::fd_fftshift;
+
   // 83. (1 by nx array of reals) uniformly-spaced KX0 points where 
   //     interpolation is done  
   KX0_ = this->kx_min_ + 
@@ -381,11 +434,19 @@
   s_compr_filt_ = vmmul<col>(this->fast_time_filter_, 
     exp(complex<T>(0, 2) * vmmul<col>(this->ks_, nmc_ones) *
       (sqrt(sq(this->Xc_) + sq(vmmul<row>(this->ucs_, nmc_ones))) - this->Xc_)));
+#if !DIGITAL_SPOTLIGHT_BY_ROW
+  fftshift<row>(s_compr_filt_, s_compr_filt_shift_);
+  fd_fftshift<col>(s_compr_filt_shift_, s_compr_filt_shift_);
+#endif
 
   // Pre-computed values for eq. 68. 
   real_matrix_type nm_ones(n_, m_, T(1));
   s_decompr_filt_ = exp( complex<T>(0, 2) * vmmul<col>(this->ks_, nm_ones) *
     (this->Xc_ - sqrt(sq(this->Xc_) + sq(vmmul<row>(this->us_, nm_ones)))) );
+#if !DIGITAL_SPOTLIGHT_BY_ROW
+  fftshift<row>(s_decompr_filt_, s_decompr_filt_shift_);
+  fd_fftshift<row>(s_decompr_filt_shift_, s_decompr_filt_shift_);
+#endif
 
   // Pre-computed values for eq. 92.
   for (index_type i = 0; i < n_; ++i)
@@ -605,7 +666,7 @@
     fsm_.row(xr)(rdom) = fs_spotlit_row_(ldom) * this->fs_ref_.row(xr)(rdom);
   }
 
-  SAVE_VIEW("p77_fsm.view", fsm_, this->swap_bytes_);
+  SAVE_VIEW("p77_fsm_row.view", fsm_, this->swap_bytes_);
 }
 
 
@@ -626,21 +687,31 @@
   // The baseband reference signal is first transformed into the Doppler 
   // (spatial frequency) domain.  
 
+  {
+    Scope<user> scope("corner-turn-1", n_ * mc_ * sizeof(complex<float>));
+    s_filt_ = s_raw;
+  }
+
   // 59. (n by mc array of complex numbers) filtered echoed signal
   //
   // Note that the fast-time filter is combined with the compression
   // along the slow-time axis below.  
-  s_filt_ = ft_fftm_(fftshift(s_raw, s_filt_));
-
-
+  //
   // 62. (n by mc array of complex numbers) signal compressed along 
   //     slow-time (note that to view 'sCompr' it will need to be 
   //     fftshifted first.)
-  s_compr_ = s_filt_ * s_compr_filt_;
+  {
+    Scope<user> scope("ft-half-fc",  fast_time_filter_ops_);
+    s_filt_ = s_compr_filt_shift_ * ft_fftm_(s_filt_);
+  }
+  {
+    Scope<user> scope("corner-turn-2", n_ * mc_ * sizeof(complex<float>));
+    fs_ = s_filt_;
+  }
 
   // 63. (n by mc array of complex numbers) narrow-bandwidth polar format
   //     reconstruction along slow-time
-  fs_ = compr_fftm_(s_compr_);
+  compr_fftm_(fs_);
 
   // 64. (scalar, int) number of zeros to be padded into the ku domain 
   //     for slow-time upsampling
@@ -654,30 +725,38 @@
   Domain<2> right_dst(Domain<1>(0, 1, n_), Domain<1>(mz + mc_/2, 1, mc_/2));
   Domain<2> right_src(Domain<1>(0, 1, n_), Domain<1>(mc_/2, 1, mc_/2));
 
-  fs_padded_(left) = fs_(left);
-  fs_padded_(center_dst) = T();
-  fs_padded_(right_dst) = fs_(right_src);
+  {
+    Scope<user> scope("expand", n_ * m_ * sizeof(complex<float>));
+    fs_padded_(left) = fs_(left);
+    fs_padded_(center_dst) = complex<T>();
+    fs_padded_(right_dst) = fs_(right_src);
+  }
 
   // 66. (n by m array of complex numbers) transform-back the zero 
   // padded spatial spectrum along its cross-range
-  decompr_fftm_(fs_padded_);
-
+  //
   // 68. (n by m array of complex numbers) slow-time decompression (note 
   //     that to view 'sDecompr' it will need to be fftshifted first.)
-  fs_padded_ *= s_decompr_filt_;
+  {
+    Scope<user> scope("decompr-half-fc",  slow_time_decompression_ops_);
+    fs_padded_ = s_decompr_filt_shift_ * decompr_fftm_(fs_padded_);
+  }
 
   // 69. (n by m array of complex numbers) digitally-spotlighted SAR 
   //     signal spectrum
-  fftshift(st_fftm_(fs_padded_), fs_spotlit_);
-
+  //
   // match filter the spotlighted signal 'fsSpotLit' with the reference's 
   // complex conjugate 'fsRef' along fast-time and slow-time, to remove 
   // the reference signal's spectral components.
-
+  //
   // 77. (n by m array of complex nums) Doppler domain matched-filtered signal
-  fsm_ = fs_spotlit_ * this->fs_ref_;
 
-  SAVE_VIEW("p77_fsm.view", fsm_, this->swap_bytes_);
+  {
+    Scope<user> scope("st-half-fc",  slow_time_decompression_ops_);
+    fsm_ = this->fs_ref_preshift_ * st_fftm_(fs_padded_); // row
+  }
+
+  SAVE_VIEW("p77_fsm_half_fc.view", fsm_, this->swap_bytes_);
 }
 #endif // DIGITAL_SPOTLIGHT_BY_ROW
 
@@ -698,44 +777,58 @@
   // Interpolate From Polar Coordinates to Rectangular Coordinates
 
   // corner-turn to col-major
-  fsm_t_ = fsm_;
+  {
+    Scope<user> scope("corner-turn-3", n_ * m_ * sizeof(complex<float>));
+    fsm_t_ = fsm_;
+  }
 
-  // 86a. initialize the F(kx,ku) array
-  F_ = complex<T>(0);
 
   // 86b. begin the range loop
-  { Scope<user> scope("range loop", range_loop_ops_);
+  {
+    Scope<user> scope("range loop", range_loop_ops_);
 #if USE_CELL_UKERNEL
-  Interp_kernel obj;
-  ukernel::Ukernel<Interp_kernel> uk(obj);
-  uk(
-    icKX_.transpose(), 
-    SINC_HAM_.template transpose<1, 0, 2>(), 
-    fsm_t_.transpose(), 
-    F_.transpose());
+    // (86a. initialize the F(kx,ku) array) - ukernel does this
+    Interp_kernel obj;
+    ukernel::Ukernel<Interp_kernel> uk(obj);
+    uk(
+      icKX_.transpose(), 
+      SINC_HAM_.template transpose<1, 0, 2>(), 
+      fsm_t_.transpose(), 
+      F_.transpose());
 
 #else
-  for (index_type j = 0; j < m_; ++j)
-  {
-    for (index_type i = 0; i < n_; ++i)
+    // (86a. initialize the F(kx,ku) array)
     {
-      // 88. (I by m array of ints) ikx are the indices of the slice that 
-      //     include the cross-range sliver at its center
-      index_type ikxrows = icKX_.get(i, j);
+      Scope<user> scope("zero", this->nx_ * m_ * sizeof(complex<float>));
+      F_ = complex<T>(0);
+    }
 
-      for (index_type h = 0; h < this->I_; ++h)
+    for (index_type j = 0; j < m_; ++j)
+    {
+      for (index_type i = 0; i < n_; ++i)
       {
-        // sinc convolution interpolation of the signal's Doppler 
-        // spectrum, from polar to rectangular coordinates 
-    
-        // 92. (nx by m array of complex nums) F is the rectangular signal 
-        //     spectrum
-        F_.put(ikxrows + h, j, F_.get(ikxrows + h, j) + 
-          (fsm_t_.get(i, j) * SINC_HAM_.get(i, j, h)));
+	// 88. (I by m array of ints) ikx are the indices of the slice that 
+	//     include the cross-range sliver at its center
+	index_type ikxrows = icKX_.get(i, j);
+#if DIGITAL_SPOTLIGHT_BY_ROW
+	index_type i_shift = i;
+#else
+	index_type i_shift = (i + n_/2) % n_;
+#endif
+	
+	for (index_type h = 0; h < this->I_; ++h)
+	{
+	  // sinc convolution interpolation of the signal's Doppler 
+	  // spectrum, from polar to rectangular coordinates 
+	  
+	  // 92. (nx by m array of complex nums) F is the rectangular signal 
+	  //     spectrum
+	  F_.put(ikxrows + h, j, F_.get(ikxrows + h, j) + 
+		 (fsm_t_.get(i_shift, j) * SINC_HAM_.get(i, j, h)));
+	}
       }
-    }
-  } // 93. end the range loop
-
+      F_.col(j)(Domain<1>(j%2, 2, this->nx_/2)) *= T(-1);
+    } // 93. end the range loop
 #endif
   }
 
@@ -746,15 +839,26 @@
 
   // 94. (nx by m array of complex nums) spatial image (complex pixel 
   //     intensities) 
-  { Scope<user> scope("doppler to spatial transform", interp_fftm_ops_);
-  fftshift(ifftmc_(F_ = ifftmr_(fftshift(F_, F_shifted_))), spatial_);
+  {
+    Scope<user> scope("doppler to spatial transform", interp_fftm_ops_);
+    ifftmc_(F_);	// col
+    spatial_ = F_;	// row := col corner-turn-
+    ifftmr_(spatial_);	// row
+
+    // The final freq-domain fftshift can be skipped because mag() throws
+    // away sign:
+    // fd_fftshift(spatial_, spatial_);
   }
 
+  {
+    Scope<user> scope("corner-turn-4", m_ * this->nx_ *sizeof(complex<float>));
+    F_ = spatial_;
+  }
 
   // for viewing, transpose spatial's magnitude 
   // 95. (m by nx array of reals) image (pixel intensities)
-  { Scope<user> scope("magnitude/trans", magnitude_ops_);
-  image_t_ = mag(spatial_);
-  image = image_t_.transpose();
+  {
+    Scope<user> scope("image-prep", magnitude_ops_);
+    image = mag(F_.transpose());
   }
 }
Index: apps/ssar/ssar.cpp
===================================================================
--- apps/ssar/ssar.cpp	(revision 228622)
+++ apps/ssar/ssar.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 200, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -20,6 +20,7 @@
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
 #include <vsip_csl/output.hpp>
+#include <vsip_csl/memory_pool.hpp>
 
 using namespace vsip_csl;
 using namespace vsip;
@@ -67,27 +68,33 @@
 
   vsip::vsipl init(argc, argv);
 
+  Local_map huge_map;
+
   ssar_options opt;
   process_ssar_options(argc, argv, opt);
 
   typedef SSAR_BASE_TYPE T;
 
+#if VSIP_IMPL_ENABLE_HUGE_PAGE_POOL && VSIP_IMPL_CBE_SDK
+  set_pool(huge_map, new vsip_csl::Huge_page_pool("/huge/benchmark.bin", 20));
+#endif
+
   // Setup for Stage 1, Kernel 1 
   vsip::impl::profile::Acc_timer t0;
   t0.start();
-  Kernel1<T> k1(opt.scale, opt.n, opt.mc, opt.m, swap_bytes); 
+  Kernel1<T> k1(opt.scale, opt.n, opt.mc, opt.m, swap_bytes, huge_map); 
   t0.stop();
   cout << "setup:   " << t0.delta() << " (s)" << endl;
 
   // Retrieve the raw radar image data from disk.  This Data I/O 
   // component is currently untimed.
-  Kernel1<T>::complex_matrix_type s_raw(opt.n, opt.mc);
+  Kernel1<T>::complex_matrix_type s_raw(opt.n, opt.mc, huge_map);
   load_view_as<complex<float>, 
     Kernel1<T>::complex_matrix_type>(RAW_SAR_DATA, s_raw, swap_bytes);
 
   // Resolve the image.  This Computation component is timed.
   Kernel1<T>::real_matrix_type 
-    image(k1.output_size(0), k1.output_size(1));
+    image(k1.output_size(0), k1.output_size(1), huge_map);
 
   vsip::impl::profile::Acc_timer t1;
   vsip::Vector<double> process_time(loop);
Index: src/vsip/core/parallel/local_map.hpp
===================================================================
--- src/vsip/core/parallel/local_map.hpp	(revision 228622)
+++ src/vsip/core/parallel/local_map.hpp	(working copy)
@@ -128,6 +128,7 @@
     { assert(idx == 0); return local_processor(); }
 
   impl::Memory_pool* impl_pool() const { return pool_; }
+  void impl_set_pool(impl::Memory_pool* pool) { pool_ = pool; }
 
   // Member data.
 private:
Index: src/vsip/core/huge_page_pool.cpp
===================================================================
--- src/vsip/core/huge_page_pool.cpp	(revision 228622)
+++ src/vsip/core/huge_page_pool.cpp	(working copy)
@@ -106,6 +106,10 @@
   if (size < 2*sizeof(char*))
     size = 2*sizeof(char*);
 
+  // Maintain 128 B alignment
+  if (size % 128 != 0)
+    size += 128 - (size % 128);
+
   char*  prev  = 0;
   char*  ptr   = free_;
   size_t avail = ptr ? ((size_t*)ptr)[1] : 0;
@@ -155,6 +159,10 @@
   if (size < 2*sizeof(char*))
     size = 2*sizeof(char*);
 
+  // Maintain 128 B alignment
+  if (size % 128 != 0)
+    size += 128 - (size % 128);
+
   char*  prev  = 0;
   char*  ptr   = free_;
 
Index: src/vsip/opt/ukernel/kernels/cbe_accel/interp_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/interp_f.hpp	(revision 228622)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/interp_f.hpp	(working copy)
@@ -15,6 +15,7 @@
   Included Files
 ***********************************************************************/
 
+#include <spu_mfcio.h>
 #include <utility>
 #include <complex>
 
@@ -25,6 +26,8 @@
 #include <vsip/opt/ukernel/cbe_accel/ukernel.hpp>
 
 #define DEBUG 0
+#define USE_OPTMIZED_INTERP 1
+#define VSIP_IMPL_SPU_LITERAL(_type_, ...) ((_type_){__VA_ARGS__})
 
 
 /***********************************************************************
@@ -67,19 +70,196 @@
     assert(p_in0.l_stride[0] == p_in2.l_stride[0]);
     assert(p_in0.l_stride[1] == p_in2.l_stride[1]);
 
-    size_t size0 = p_in1.l_size[0];
-    size_t size1 = p_in1.l_size[1];
-    size_t size2 = p_in1.l_size[2];
-    size_t stride = p_in0.l_stride[0];
+    size_t const size0 = p_in1.l_size[0];
+    size_t const size1 = p_in1.l_size[1];
+    size_t const size2 = p_in1.l_size[2];
+    size_t const act_size2 = 17;
+    size_t const stride = p_in0.l_stride[0];
+    size_t const l_total_size = p_out.l_total_size;
 
-    for (size_t i = 0; i < p_out.l_total_size; ++i)
-      out[i] = std::complex<float>();
+    float* fout = (float*)out;
 
+    vector float zero = ((vector float){0.f, 0.f, 0.f, 0.f});
+
+#if USE_OPTMIZED_INTERP
+    memset((void*)out, 0, l_total_size * sizeof(std::complex<float>));
+
+// SIMD version
+    vector unsigned char shuf_0011 = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    0,  1,  2,  3,  0,  1,  2,  3,
+			    4,  5,  6,  7,  4,  5,  6,  7);
+    vector unsigned char shuf_2233 = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    8,  9, 10, 11,  8,  9, 10, 11,
+			   12, 13, 14, 15, 12, 13, 14, 15);
+    vector unsigned char shuf_1122 = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    4,  5,  6,  7,  4,  5,  6,  7,
+			    8,  9, 10, 11,  8,  9, 10, 11);
+    vector unsigned char shuf_3344 = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			   12, 13, 14, 15, 12, 13, 14, 15,
+			   16, 17, 18, 19, 16, 17, 18, 19);
+    vector unsigned char shuf_0044 = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    0,  1,  2,  3,  0,  1,  2,  3,
+			   16, 17, 18, 19, 16, 17, 18, 19);
+    vector unsigned char shuf_0101 = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    0,  1,  2,  3,  4,  5,  6,  7,
+			    0,  1,  2,  3,  4,  5,  6,  7);
+    vector unsigned char shuf_2323 = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    8,  9, 10, 11, 12, 13, 14, 15,
+			    8,  9, 10, 11, 12, 13, 14, 15);
+
     for (size_t j = 0; j < size1; ++j)
-      for (size_t k = 0; k < size2; ++k)
+    {
+      size_t j_shift = (j + size1/2) % size1;
+      vector float vscale = *(vector float*)(&in2[j_shift]);
+      if (j_shift % 2 == 0)
+	vscale = spu_shuffle(vscale, vscale, shuf_0101);
+      else
+	vscale = spu_shuffle(vscale, vscale, shuf_2323);
+      unsigned int const ui = 2*in0[j];
+
+      if (ui % 4 == 0)
       {
-        out[in0[j] + k] += in2[j] * in1[j * size2 + k];
+	vector float* vf    = (vector float*)(&fout[ui]);
+	vector float* psync = (vector float*)(&in1[j*size2]);
+
+	for (size_t k = 0; k < act_size2-15; k += 16)
+	{
+	  vector float f0 = vf[0];
+	  vector float f1 = vf[1];
+	  vector float f2 = vf[2];
+	  vector float f3 = vf[3];
+	  vector float f4 = vf[4];
+	  vector float f5 = vf[5];
+	  vector float f6 = vf[6];
+	  vector float f7 = vf[7];
+	  vector float sync0123  = psync[0];
+	  vector float sync4567  = psync[1];
+	  vector float sync89ab  = psync[2];
+	  vector float synccdef  = psync[3];
+	  vector float sync0011 = spu_shuffle(sync0123, sync0123, shuf_0011);
+	  vector float sync2233 = spu_shuffle(sync0123, sync0123, shuf_2233);
+	  vector float sync4455 = spu_shuffle(sync4567, sync4567, shuf_0011);
+	  vector float sync6677 = spu_shuffle(sync4567, sync4567, shuf_2233);
+	  vector float sync8899 = spu_shuffle(sync89ab, sync89ab, shuf_0011);
+	  vector float syncaabb = spu_shuffle(sync89ab, sync89ab, shuf_2233);
+	  vector float syncccdd = spu_shuffle(synccdef, synccdef, shuf_0011);
+	  vector float synceeff = spu_shuffle(synccdef, synccdef, shuf_2233);
+	  f0 = spu_madd(vscale, sync0011, f0);
+	  f1 = spu_madd(vscale, sync2233, f1);
+	  f2 = spu_madd(vscale, sync4455, f2);
+	  f3 = spu_madd(vscale, sync6677, f3);
+	  f4 = spu_madd(vscale, sync8899, f4);
+	  f5 = spu_madd(vscale, syncaabb, f5);
+	  f6 = spu_madd(vscale, syncccdd, f6);
+	  f7 = spu_madd(vscale, synceeff, f7);
+	  vf[0] = f0;
+	  vf[1] = f1;
+	  vf[2] = f2;
+	  vf[3] = f3;
+	  vf[4] = f4;
+	  vf[5] = f5;
+	  vf[6] = f6;
+	  vf[7] = f7;
+	  vf += 8; psync += 4;
+	}
+	vector float f0 = vf[0];
+	vector float sync0xxx = psync[0];
+	vector float sync00xx = spu_shuffle(sync0xxx, zero, shuf_0044);
+	f0 = spu_madd(vscale, sync00xx, f0);
+	vf[0] = f0;
       }
+      else
+      {
+	vector float* vf   = (vector float*)(&fout[ui + 2]);
+	vector float* psync = (vector float*)(&in1[j*size2]);
+
+	vector float sync0123 = psync[0];
+
+	vector float f0 = vf[-1];
+	vector float syncxx00 = spu_shuffle(zero, sync0123, shuf_0044);
+	f0 = spu_madd(vscale, syncxx00, f0);
+	vf[-1] = f0;
+
+	for (size_t k = 1; k < act_size2-15; k += 16)
+	{
+	  vector float f0 = vf[0];
+	  vector float f1 = vf[1];
+	  vector float f2 = vf[2];
+	  vector float f3 = vf[3];
+	  vector float f4 = vf[4];
+	  vector float f5 = vf[5];
+	  vector float f6 = vf[6];
+	  vector float f7 = vf[7];
+	  vector float sync4567 = psync[1];
+	  vector float sync89ab = psync[2];
+	  vector float synccdef = psync[3];
+	  vector float syncghij = psync[4];
+	  vector float sync1122 = spu_shuffle(sync0123, sync4567, shuf_1122);
+	  vector float sync3344 = spu_shuffle(sync0123, sync4567, shuf_3344);
+	  vector float sync5566 = spu_shuffle(sync4567, sync89ab, shuf_1122);
+	  vector float sync7788 = spu_shuffle(sync4567, sync89ab, shuf_3344);
+	  vector float sync99aa = spu_shuffle(sync89ab, synccdef, shuf_1122);
+	  vector float syncbbcc = spu_shuffle(sync89ab, synccdef, shuf_3344);
+	  vector float syncddee = spu_shuffle(synccdef, syncghij, shuf_1122);
+	  vector float syncffgg = spu_shuffle(synccdef, syncghij, shuf_3344);
+	  sync0123 = syncghij;
+	  f0 = spu_madd(vscale, sync1122, f0);
+	  f1 = spu_madd(vscale, sync3344, f1);
+	  f2 = spu_madd(vscale, sync5566, f2);
+	  f3 = spu_madd(vscale, sync7788, f3);
+	  f4 = spu_madd(vscale, sync99aa, f4);
+	  f5 = spu_madd(vscale, syncbbcc, f5);
+	  f6 = spu_madd(vscale, syncddee, f6);
+	  f7 = spu_madd(vscale, syncffgg, f7);
+	  vf[0] = f0;
+	  vf[1] = f1;
+	  vf[2] = f2;
+	  vf[3] = f3;
+	  vf[4] = f4;
+	  vf[5] = f5;
+	  vf[6] = f6;
+	  vf[7] = f7;
+	  vf += 8; psync += 4;
+	}
+      }
+    }
+
+    vector float scale;
+    if (p_out.g_offset[0] % 2)
+      scale = ((vector float){-1.f, -1.f, 1.f, 1.f});
+    else
+      scale = ((vector float){1.f, 1.f, -1.f, -1.f});
+
+    vector float* vout = (vector float*)fout;
+    for (size_t j = 0; j < l_total_size>>1; j++)
+      vout[j] = spu_madd(vout[j], scale, zero);
+
+#else
+    // Reference (non-vectorized, non-unrolled) version of interp
+    // algorithm.
+    for (size_t i = 0; i < l_total_size; ++i)
+      out[i] = std::complex<float>();
+
+    for (size_t j = 0; j < size1; ++j)
+    {
+      size_t j_shift = (j + size1/2) % size1;
+      for (size_t k = 0; k < act_size2; ++k)
+        out[in0[j] + k] += in2[j_shift] * in1[j * size2 + k];
+    }
+
+    for (size_t j = p_out.g_offset[0] % 2; j < l_total_size; j+=2)
+    {
+      fout[2*j + 0] *= -1.f;
+      fout[2*j + 1] *= -1.f;
+    }
+#endif
   }
 
 };
Index: src/vsip_csl/memory_pool.hpp
===================================================================
--- src/vsip_csl/memory_pool.hpp	(revision 0)
+++ src/vsip_csl/memory_pool.hpp	(revision 0)
@@ -0,0 +1,43 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip_csl/memory_pool.hpp
+    @author  Jules Bergmann
+    @date    2008-11-21
+    @brief   VSIPL++ Library: CSL extension: Memory pools
+*/
+
+#ifndef VSIP_CSL_MEMORY_POOL_HPP
+#define VSIP_CSL_MEMORY_POOL_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/memory_pool.hpp>
+#include <vsip/core/huge_page_pool.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip_csl
+{
+
+using vsip::impl::Memory_pool;
+using vsip::impl::Huge_page_pool;
+
+void
+set_pool(vsip::Local_map& map, Memory_pool* pool)
+{
+  map.impl_set_pool(pool);
+}
+
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_UKERNEL_HPP
Index: src/vsip_csl/matlab_utils.hpp
===================================================================
--- src/vsip_csl/matlab_utils.hpp	(revision 228622)
+++ src/vsip_csl/matlab_utils.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -23,6 +23,7 @@
 namespace matlab
 {
   
+// Vector fftshift
 
 template <typename T1,
           typename T2,
@@ -52,6 +53,9 @@
 }
 
 
+
+// Matrix fftshift
+
 template <typename T1,
 	  typename T2,
 	  typename Block1,
@@ -95,10 +99,12 @@
 }
 
 
-// The following versions are not as efficient as those above due
-// to the overhead of creating a new view.  For optimized code,
-// use the ones above.
 
+// By-value vector fftshift.
+//
+// May not as efficient as by-reference due to the overhead of
+// creating a new view.
+
 template <typename T1,
           typename Block1>
 vsip::Vector<T1>
@@ -110,6 +116,12 @@
 }
 
 
+
+// By-value matrix fftshift.
+//
+// May not as efficient as by-reference due to the overhead of
+// creating a new view.
+
 template <typename T1,
 	  typename Block1>
 vsip::Matrix<T1>
@@ -122,7 +134,181 @@
 
 
 
+// Partial matrix fftshift across dimension 0 (along columns)
+//
+// This function swaps halves of a matrix (both dimensions
+// must be even) as follows:
+//
+//  | 1  |            | 2 |
+//  | 2  |   becomes  | 1 |
 
+template <typename T1,
+	  typename T2,
+	  typename Block1,
+	  typename Block2>
+vsip::Matrix<T2, Block2>
+fftshift_col(
+  vsip::const_Matrix<T1, Block1> in, vsip::Matrix<T2, Block2> out)
+{
+  using vsip::length_type;
+  using vsip::Domain;
+
+  length_type nx = in.size(0);
+  length_type ny = in.size(1);
+  assert(!(nx & 1));
+  assert(!(ny & 1));
+  assert(nx == out.size(0));
+  assert(ny == out.size(1));
+
+  Domain<1> upper(0, 1, nx/2);
+  Domain<1> lower(nx/2, 1, nx/2);
+  Domain<1> all(0, 1, ny);
+
+  Domain<2> dom1(upper, all);
+  Domain<2> dom2(lower, all);
+
+  out(dom1) = in(dom2);
+  out(dom2) = in(dom1);
+
+  return out;
+}
+
+
+
+// Partial matrix fftshift across dimension 1 (along rows)
+//
+// This function swaps halves of a matrix (both dimensions
+// must be even) as follows:
+//
+//  | 1  2 |   becomes  | 1  2 |
+
+template <typename T1,
+	  typename T2,
+	  typename Block1,
+	  typename Block2>
+vsip::Matrix<T2, Block2>
+fftshift_row(
+  vsip::const_Matrix<T1, Block1> in, vsip::Matrix<T2, Block2> out)
+{
+  using vsip::length_type;
+  using vsip::Domain;
+
+  length_type nx = in.size(0);
+  length_type ny = in.size(1);
+  assert(!(nx & 1));
+  assert(!(ny & 1));
+  assert(nx == out.size(0));
+  assert(ny == out.size(1));
+
+  Domain<1> all(0, 1, nx);
+
+  Domain<1> left (0, 1, ny/2);
+  Domain<1> right(ny/2, 1, ny/2);
+
+  Domain<2> dom1(all,  left);
+  Domain<2> dom2(all, right);
+
+  out(dom1) = in(dom2);
+  out(dom2) = in(dom1);
+
+  return out;
+}
+
+
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+vsip::Matrix<T2, Block2>
+fftshift(
+  vsip::const_Matrix<T1, Block1> in, vsip::Matrix<T2, Block2> out)
+{
+  return (Dim == row) ? fftshift_row(in, out) : fftshift_col(in, out);
+}
+
+
+
+// Frequency domain matrix fftshift
+
+template <typename Matrix1T,
+	  typename Matrix2T>
+void
+fd_fftshift(Matrix1T in, Matrix2T out)
+{
+  typedef typename Matrix1T::value_type T;
+  length_type rows = in.size(0);
+  length_type cols = in.size(1);
+
+  Matrix<T> w(rows, cols);
+  
+  w = T(+1);
+  w(Domain<2>(Domain<1>(0, 2, rows/2), Domain<1>(1, 2, cols/2))) = T(-1);
+  w(Domain<2>(Domain<1>(1, 2, rows/2), Domain<1>(0, 2, cols/2))) = T(-1);
+
+  out = in * w;
+}
+
+
+
+// Partial frequency domain matrix fftshift across dimension 0 (along columns)
+
+template <typename Matrix1T,
+	  typename Matrix2T>
+void
+fd_fftshift_col(Matrix1T in, Matrix2T out)
+{
+  typedef typename Matrix1T::value_type T;
+  length_type rows = in.size(0);
+  length_type cols = in.size(1);
+
+  Matrix<T> w(rows, cols);
+  
+  w = T(+1);
+  w(Domain<2>(Domain<1>(1, 2, rows/2), Domain<1>(0, 1, cols))) = T(-1);
+
+  out = in * w;
+}
+
+
+
+// Partial frequency domain matrix fftshift across dimension 1 (along rows)
+
+template <typename Matrix1T,
+	  typename Matrix2T>
+void
+fd_fftshift_row(Matrix1T in, Matrix2T out)
+{
+  typedef typename Matrix1T::value_type T;
+  length_type rows = in.size(0);
+  length_type cols = in.size(1);
+
+  Matrix<T> w(rows, cols);
+  
+  w = T(+1);
+  w(Domain<2>(Domain<1>(0, 1, rows), Domain<1>(1, 2, cols/2))) = T(-1);
+
+  out = in * w;
+}
+
+
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+fd_fftshift(
+  vsip::const_Matrix<T1, Block1> in, vsip::Matrix<T2, Block2> out)
+{
+  return (Dim == row) ? fd_fftshift_row(in, out) : fd_fftshift_col(in, out);
+}
+
+
+
+
 } // namesapce matlab
 
 } // namespace vsip_csl
