Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 154641)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -32,6 +32,7 @@
 class Kernel1_base
 {
 protected:
+  typedef Matrix<complex<T>, Dense<2, complex<T>, col2_type> > complex_col_matrix_type;
   typedef Matrix<complex<T> > complex_matrix_type;
   typedef Vector<complex<T> > complex_vector_type;
   typedef Matrix<T> real_matrix_type;
@@ -226,15 +227,17 @@
 class Kernel1 : public Kernel1_base<T>
 {
 public:
+  typedef typename Kernel1_base<T>::complex_col_matrix_type complex_col_matrix_type;
+
   typedef typename Kernel1_base<T>::complex_matrix_type complex_matrix_type;
   typedef typename Kernel1_base<T>::complex_vector_type complex_vector_type;
   typedef typename Kernel1_base<T>::real_matrix_type real_matrix_type;
   typedef typename Kernel1_base<T>::real_vector_type real_vector_type;
 
-  typedef Fftm<complex<T>, complex<T>, col> col_fftm_type;
-  typedef Fftm<complex<T>, complex<T>, row> row_fftm_type;
-  typedef Fftm<complex<T>, complex<T>, row, fft_inv> ifftmr_type;
-  typedef Fftm<complex<T>, complex<T>, col, fft_inv> ifftmc_type;
+  typedef Fftm<complex<T>, complex<T>, col, fft_fwd, by_reference> col_fftm_type;
+  typedef Fftm<complex<T>, complex<T>, row, fft_fwd, by_reference> row_fftm_type;
+  typedef Fftm<complex<T>, complex<T>, row, fft_inv, by_reference> ifftmr_type;
+  typedef Fftm<complex<T>, complex<T>, col, fft_inv, by_reference> ifftmc_type;
 
   Kernel1(length_type scale, length_type n, length_type mc, length_type m);
   ~Kernel1() {}
@@ -261,15 +264,13 @@
   length_type mc_;
   length_type m_;
 
-  complex_matrix_type s_filt_;
+  complex_col_matrix_type s_filt_;
   complex_matrix_type s_compr_filt_;
   complex_matrix_type fs_spotlit_;
   complex_matrix_type s_compr_;
   complex_matrix_type fs_;
   complex_matrix_type fs_padded_;
-  complex_matrix_type s_padded_;
   complex_matrix_type s_decompr_filt_;
-  complex_matrix_type s_decompr_;
   complex_matrix_type fsm_;
   Matrix<index_type> icKX_;
 //  real_vector_type x_;
@@ -300,9 +301,7 @@
     s_compr_(n, mc),
     fs_(n, mc),
     fs_padded_(n, m),
-    s_padded_(n, m),
     s_decompr_filt_(n, m),
-    s_decompr_(n, m),
     fsm_(n, m),
     icKX_(n, m),
 //    x_(this->nx_),
@@ -450,31 +449,32 @@
   // 65. (n by m array of complex numbers) zero pad the spatial frequency 
   //     domain's compressed signal along its slow-time (note that to view 
   //     'fsPadded' it will need to be fftshifted first)
-  T m_scale = static_cast<T>(m_) / static_cast<T>(mc_);
+  fs_ *= static_cast<T>(m_) / mc_;
+
   Domain<2> left(Domain<1>(0, 1, n_), Domain<1>(0, 1, mc_/2));
   Domain<2> center_dst(Domain<1>(0, 1, n_), Domain<1>(mc_/2, 1, mz));
   Domain<2> right_dst(Domain<1>(0, 1, n_), Domain<1>(mz + mc_/2, 1, mc_/2));
   Domain<2> right_src(Domain<1>(0, 1, n_), Domain<1>(mc_/2, 1, mc_/2));
 
-  fs_padded_(left) = m_scale * fs_(left);
+  fs_padded_(left) = fs_(left);
   fs_padded_(center_dst) = T();
-  fs_padded_(right_dst) = m_scale * fs_(right_src);
+  fs_padded_(right_dst) = fs_(right_src);
 
   SAVE_VIEW("p65_fs_padded.view", fftshift(fs_padded_));
 
   // 66. (n by m array of complex numbers) transform-back the zero 
   // padded spatial spectrum along its cross-range
-  s_padded_ = ifftm_(fs_padded_);
+  ifftm_(fs_padded_);
 
   // 68. (n by m array of complex numbers) slow-time decompression (note 
   //     that to view 'sDecompr' it will need to be fftshifted first.)
-  s_decompr_ = s_padded_ * s_decompr_filt_;
+  fs_padded_ *= s_decompr_filt_;
 
-  SAVE_VIEW("p68_s_decompr.view", fftshift(s_decompr_));
+  SAVE_VIEW("p68_s_decompr.view", fftshift(fs_padded_));
 
   // 69. (n by m array of complex numbers) digitally-spotlighted SAR 
   //     signal spectrum
-  fftshift(row_fftm2_(s_decompr_), fs_spotlit_);
+  fftshift(row_fftm2_(fs_padded_), fs_spotlit_);
 
   SAVE_VIEW("p69_fs_spotlit.view", fs_spotlit_);
 
@@ -533,8 +533,7 @@
 
   // 94. (nx by m array of complex nums) spatial image (complex pixel 
   //     intensities) 
-  fftshift(F_, F_shifted_);
-  fftshift(ifftmr_(ifftmc_(F_shifted_)), spatial_);
+  fftshift(ifftmr_(ifftmc_(fftshift(F_, F_shifted_))), spatial_);
 
   // for viewing, transpose spatial's magnitude 
   // 95. (m by nx array of reals) image (pixel intensities)
