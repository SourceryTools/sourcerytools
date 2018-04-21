Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 155287)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -35,6 +35,7 @@
   typedef Matrix<complex<T>, Dense<2, complex<T>, col2_type> > complex_col_matrix_type;
   typedef Matrix<complex<T> > complex_matrix_type;
   typedef Vector<complex<T> > complex_vector_type;
+  typedef Matrix<T, Dense<2, T, col2_type> > real_col_matrix_type;
   typedef Matrix<T> real_matrix_type;
   typedef Vector<T> real_vector_type;
 
@@ -228,9 +229,9 @@
 {
 public:
   typedef typename Kernel1_base<T>::complex_col_matrix_type complex_col_matrix_type;
-
   typedef typename Kernel1_base<T>::complex_matrix_type complex_matrix_type;
   typedef typename Kernel1_base<T>::complex_vector_type complex_vector_type;
+  typedef typename Kernel1_base<T>::real_col_matrix_type real_col_matrix_type;
   typedef typename Kernel1_base<T>::real_matrix_type real_matrix_type;
   typedef typename Kernel1_base<T>::real_vector_type real_vector_type;
 
@@ -272,15 +273,16 @@
   Vector<complex<T> > fs_padded_row_;
   complex_matrix_type s_decompr_filt_;
   complex_matrix_type fsm_;
-  Matrix<index_type> icKX_;
+  complex_col_matrix_type fsm_t_;
+  Matrix<index_type, Dense<2, index_type, col2_type> > icKX_;
 //  real_vector_type x_;
   real_vector_type KX0_;
 //  real_matrix_type KX_;
-  Tensor<T> SINC_HAM_;
-  complex_matrix_type F_;
-  complex_col_matrix_type F_shifted_;
-  complex_matrix_type spatial_;
-  real_matrix_type image_t_;
+  Tensor<T, Dense<3, T, col2_type> > SINC_HAM_;
+  complex_col_matrix_type F_;
+  complex_matrix_type F_shifted_;
+  complex_col_matrix_type spatial_;
+  real_col_matrix_type image_t_;
 
   col_fft_type col_fft_;
   row_fft_type row_fft_;
@@ -303,6 +305,7 @@
     fs_padded_row_(m),
     s_decompr_filt_(n, m),
     fsm_(n, m),
+    fsm_t_(n, m),
     icKX_(n, m),
 //    x_(this->nx_),
     KX0_(this->nx_),
@@ -404,12 +407,10 @@
 
   // Digital spotlighting and bandwidth-expansion using slow-time 
   // compression and decompression.  
-  //   fs_spotlit_   stores the processed signal
   this->digital_spotlighting(input);
 
 
   // Digital reconstruction via spatial frequency interpolation.
-  //real_matrix_type image(this->interpolation());
   this->interpolation(output);
 }
 
@@ -523,15 +524,17 @@
   // complex conjugate 'fsRef' along fast-time and slow-time, to remove 
   // the reference signal's spectral components.
 
+  // corner-turn to col-major
+  fsm_t_ = fsm_;
 
   // 86a. initialize the F(kx,ku) array
   F_ = complex<T>(0);
 
   // 86b. begin the range loop
   { impl::profile::Scope_event kernel1_event("interpolate", 83393024);
-  for (index_type i = 0; i < n_; ++i)
+  for (index_type j = 0; j < m_; ++j)
   {
-    for (index_type j = 0; j < m_; ++j)
+    for (index_type i = 0; i < n_; ++i)
     {
       // 88. (I by m array of ints) ikx are the indices of the slice that 
       //     include the cross-range sliver at its center
@@ -545,10 +548,9 @@
         // 92. (nx by m array of complex nums) F is the rectangular signal 
         //     spectrum
         F_.put(ikxrows + h, j, F_.get(ikxrows + h, j) + 
-          (fsm_.get(i, j) * SINC_HAM_.get(i, j, h)));
+          (fsm_t_.get(i, j) * SINC_HAM_.get(i, j, h)));
       }
     }
-
   } // 93. end the range loop
   }
 
@@ -559,7 +561,7 @@
 
   // 94. (nx by m array of complex nums) spatial image (complex pixel 
   //     intensities) 
-  fftshift(ifftmr_(F_ = ifftmc_(fftshift(F_, F_shifted_))), spatial_);
+  fftshift(ifftmc_(F_ = ifftmr_(fftshift(F_, F_shifted_))), spatial_);
 
   // for viewing, transpose spatial's magnitude 
   // 95. (m by nx array of reals) image (pixel intensities)
Index: apps/ssar/ssar.cpp
===================================================================
--- apps/ssar/ssar.cpp	(revision 155287)
+++ apps/ssar/ssar.cpp	(working copy)
@@ -50,7 +50,7 @@
   ssar_options opt;
   process_ssar_options(argc, argv, opt);
 
-  typedef double T;
+  typedef float T;
 
   // Setup for Stage 1, Kernel 1 
   Kernel1<T> k1(opt.scale, opt.n, opt.mc, opt.m); 
