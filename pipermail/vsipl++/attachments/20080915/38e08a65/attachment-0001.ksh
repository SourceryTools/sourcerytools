Index: kernel1.hpp
===================================================================
--- kernel1.hpp	(revision 221292)
+++ kernel1.hpp	(working copy)
@@ -18,13 +18,27 @@
 #include <vsip_csl/save_view.hpp>
 #include <vsip_csl/load_view.hpp>
 
-#if 0
+#if 1
 #define VERBOSE
 #define SAVE_VIEW(a, b, c)    vsip_csl::save_view_as<complex<float> >(a, b, c)
 #else
 #define SAVE_VIEW(a, b, c)
 #endif
 
+
+// This compiler switch changes the behavior of the digital spotlighting
+// computation such that it behaves in a more cache-friendly way.
+// 
+// A value of '1' will use 1-D FFTs instead of FFTMs (multiple-FFTs)
+// and it will perform several operations at a time when it processes the
+// rows, leading to more cache hits on some architectures (like x86).
+// 
+// A value of '0' will utilize FFTMs and likewise perform each step on the 
+// entire image before proceeding to the next.  This can be more efficient
+// on certain architectures (such as Cell/B.E.) where large computations
+// can be distributed amongst several compute elements and run in parallel.
+#define CACHE_FRIENDLY 1
+
 template <typename T>
 class Kernel1_base
 {
@@ -222,6 +236,8 @@
   typedef Fft<const_Vector, complex<T>, complex<T>, fft_fwd, by_reference> col_fft_type;
   typedef Fft<const_Vector, complex<T>, complex<T>, fft_fwd, by_reference> row_fft_type;
   typedef Fft<const_Vector, complex<T>, complex<T>, fft_inv, by_reference> inv_fft_type;
+  typedef Fftm<complex<T>, complex<T>, row, fft_fwd, by_reference> row_fftm_type;
+  typedef Fftm<complex<T>, complex<T>, col, fft_fwd, by_reference> col_fftm_type;
   typedef Fftm<complex<T>, complex<T>, row, fft_inv, by_reference> inv_row_fftm_type;
   typedef Fftm<complex<T>, complex<T>, col, fft_inv, by_reference> inv_col_fftm_type;
 
@@ -267,8 +283,6 @@
   complex_col_matrix_type s_filt_;
   complex_matrix_type s_filt_t_;
   complex_matrix_type s_compr_filt_;
-  Vector<complex<T> > fs_row_;
-  Vector<complex<T> > fs_spotlit_;
   complex_matrix_type s_decompr_filt_;
   complex_matrix_type fsm_;
   complex_col_matrix_type fsm_t_;
@@ -280,10 +294,23 @@
   complex_col_matrix_type spatial_;
   real_col_matrix_type image_t_;
 
+#if CACHE_FRIENDLY
+  Vector<complex<T> > fs_row_;
+  Vector<complex<T> > fs_spotlit_row_;
   col_fft_type ft_fft_;
   row_fft_type st_fft_;
   row_fft_type compr_fft_;
   inv_fft_type decompr_fft_;
+#else
+  complex_matrix_type fs_spotlit_;
+  complex_matrix_type s_compr_;
+  complex_matrix_type fs_;
+  complex_matrix_type fs_padded_;
+  col_fftm_type ft_fftm_;
+  row_fftm_type st_fftm_;
+  row_fftm_type compr_fftm_;
+  inv_row_fftm_type decompr_fftm_;
+#endif
   inv_row_fftm_type ifftmr_;
   inv_col_fftm_type ifftmc_;
 };
@@ -297,8 +324,6 @@
     s_filt_(n, mc),
     s_filt_t_(n, mc),
     s_compr_filt_(n, mc),
-    fs_row_(mc),
-    fs_spotlit_(m),
     s_decompr_filt_(n, m),
     fsm_(n, m),
     fsm_t_(n, m),
@@ -309,10 +334,23 @@
     F_shifted_(this->nx_, m_),
     spatial_(this->nx_, m_),
     image_t_(this->nx_, m_),
+#if CACHE_FRIENDLY
+    fs_row_(mc),
+    fs_spotlit_row_(m),
     ft_fft_(Domain<1>(n), T(1)),
     st_fft_(Domain<1>(m), T(1)),
     compr_fft_(Domain<1>(mc), static_cast<T>(m_) / mc_),
     decompr_fft_(Domain<1>(m), T(1.f/m)),
+#else
+    fs_spotlit_(n, m),
+    s_compr_(n, mc),
+    fs_(n, mc),
+    fs_padded_(n, m),
+    ft_fftm_(Domain<2>(n, mc), T(1)),
+    st_fftm_(Domain<2>(n, m), T(1)),
+    compr_fftm_(Domain<2>(n, mc), static_cast<T>(m_) / mc_),
+    decompr_fftm_(Domain<2>(n, m), T(1.f/m)),
+#endif
     ifftmr_(Domain<2>(this->nx_, m_), T(1./m_)),
     ifftmc_(Domain<2>(this->nx_, m_), T(1./this->nx_))
 {
@@ -454,6 +492,8 @@
 
 
 
+#if CACHE_FRIENDLY
+
 template <typename T>
 void
 Kernel1<T>::digital_spotlighting(complex_matrix_type s_raw)
@@ -515,21 +555,21 @@
     // 65. (n by m array of complex numbers) zero pad the spatial frequency 
     //     domain's compressed signal along its slow-time (note that to view 
     //     'fsPadded' it will need to be fftshifted first)
-    fs_spotlit_(left)       = fs_row_(left);
-    fs_spotlit_(center_dst) = T();
-    fs_spotlit_(right_dst)  = fs_row_(right_src);
+    fs_spotlit_row_(left)       = fs_row_(left);
+    fs_spotlit_row_(center_dst) = T();
+    fs_spotlit_row_(right_dst)  = fs_row_(right_src);
 
     // 66. (n by m array of complex numbers) transform-back the zero 
     //     padded spatial spectrum along its cross-range
-    decompr_fft_(fs_spotlit_);
+    decompr_fft_(fs_spotlit_row_);
 
     // 68. (n by m array of complex numbers) slow-time decompression (note 
     //     that to view 'sDecompr' it will need to be fftshifted first.)
-    fs_spotlit_ *= s_decompr_filt_.row(i);
+    fs_spotlit_row_ *= s_decompr_filt_.row(i);
 
     // 69. (n by m array of complex numbers) digitally-spotlighted SAR 
     //     signal spectrum
-    st_fft_(fs_spotlit_);
+    st_fft_(fs_spotlit_row_);
 
 
     // Match filter the spotlighted signal 'fsSpotLit' with the reference's 
@@ -545,16 +585,89 @@
     //   fsm_.row(xr) = fs_spotlit_ * this->fs_ref_.row(xr);
     //
     index_type xr = (i < n_/2) ? (n_/2 + i) : (i - n_/2);
-    fsm_.row(xr)(ldom) = fs_spotlit_(rdom) * this->fs_ref_.row(xr)(ldom);
-    fsm_.row(xr)(rdom) = fs_spotlit_(ldom) * this->fs_ref_.row(xr)(rdom);
+    fsm_.row(xr)(ldom) = fs_spotlit_row_(rdom) * this->fs_ref_.row(xr)(ldom);
+    fsm_.row(xr)(rdom) = fs_spotlit_row_(ldom) * this->fs_ref_.row(xr)(rdom);
   }
 
   SAVE_VIEW("p77_fsm.view", fsm_, this->swap_bytes_);
 }
 
 
+#else
 
 template <typename T>
+void
+Kernel1<T>::digital_spotlighting(complex_matrix_type s_raw)
+{
+  using impl::profile::Scope;
+  using impl::profile::user;
+  Scope<user> scope("digital_spotlighting", digital_spotlighting_ops_);
+
+  using vsip_csl::matlab::fftshift;
+  assert(s_raw.size(0) == n_);
+  assert(s_raw.size(1) == mc_);
+
+  // The baseband reference signal is first transformed into the Doppler 
+  // (spatial frequency) domain.  
+
+  // 59. (n by mc array of complex numbers) filtered echoed signal
+  //
+  // Note that the fast-time filter is combined with the compression
+  // along the slow-time axis below.  
+  s_filt_ = ft_fftm_(fftshift(s_raw, s_filt_));
+
+
+  // 62. (n by mc array of complex numbers) signal compressed along 
+  //     slow-time (note that to view 'sCompr' it will need to be 
+  //     fftshifted first.)
+  s_compr_ = s_filt_ * s_compr_filt_;
+
+  // 63. (n by mc array of complex numbers) narrow-bandwidth polar format
+  //     reconstruction along slow-time
+  fs_ = compr_fftm_(s_compr_);
+
+  // 64. (scalar, int) number of zeros to be padded into the ku domain 
+  //     for slow-time upsampling
+  length_type mz = m_ - mc_;
+
+  // 65. (n by m array of complex numbers) zero pad the spatial frequency 
+  //     domain's compressed signal along its slow-time (note that to view 
+  //     'fsPadded' it will need to be fftshifted first)
+  Domain<2> left(Domain<1>(0, 1, n_), Domain<1>(0, 1, mc_/2));
+  Domain<2> center_dst(Domain<1>(0, 1, n_), Domain<1>(mc_/2, 1, mz));
+  Domain<2> right_dst(Domain<1>(0, 1, n_), Domain<1>(mz + mc_/2, 1, mc_/2));
+  Domain<2> right_src(Domain<1>(0, 1, n_), Domain<1>(mc_/2, 1, mc_/2));
+
+  fs_padded_(left) = fs_(left);
+  fs_padded_(center_dst) = T();
+  fs_padded_(right_dst) = fs_(right_src);
+
+  // 66. (n by m array of complex numbers) transform-back the zero 
+  // padded spatial spectrum along its cross-range
+  decompr_fftm_(fs_padded_);
+
+  // 68. (n by m array of complex numbers) slow-time decompression (note 
+  //     that to view 'sDecompr' it will need to be fftshifted first.)
+  fs_padded_ *= s_decompr_filt_;
+
+  // 69. (n by m array of complex numbers) digitally-spotlighted SAR 
+  //     signal spectrum
+  fftshift(st_fftm_(fs_padded_), fs_spotlit_);
+
+  // match filter the spotlighted signal 'fsSpotLit' with the reference's 
+  // complex conjugate 'fsRef' along fast-time and slow-time, to remove 
+  // the reference signal's spectral components.
+
+  // 77. (n by m array of complex nums) Doppler domain matched-filtered signal
+  fsm_ = fs_spotlit_ * this->fs_ref_;
+
+  SAVE_VIEW("p77_fsm.view", fsm_, this->swap_bytes_);
+}
+#endif // CACHE_FRIENDLY
+
+
+
+template <typename T>
 void // Matrix<T>
 Kernel1<T>::interpolation(real_matrix_type image)
 {
@@ -609,6 +722,7 @@
   fftshift(ifftmc_(F_ = ifftmr_(fftshift(F_, F_shifted_))), spatial_);
   }
 
+
   // for viewing, transpose spatial's magnitude 
   // 95. (m by nx array of reals) image (pixel intensities)
   { Scope<user> scope("magnitude/trans", magnitude_ops_);
