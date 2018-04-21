diff -u apps/ssar/GNUmakefile apps/ssar/GNUmakefile
--- apps/ssar/GNUmakefile	(working copy)
+++ apps/ssar/GNUmakefile	(working copy)
@@ -93,14 +93,14 @@
 
 profile1: ssar viewtoraw
 	@echo "Profiling SSAR application (SCALE = 1)..."
-	./ssar data1 -loop 1 --vsipl++-profile-mode=accum --vsipl++-profile-output=profile.out
+	./ssar data1 -loop 10 --vsipl++-profile-mode=accum --vsipl++-profile-output=profile.out
 	@echo "Formatting profiler output..."
 	${fmt-profile-command}  -sec -o profile1.txt data1/profile.out
 	./make_images.sh data1 438 160 382 266
 
 profile3: ssar viewtoraw
 	@echo "Profiling SSAR application (SCALE = 3)..."
-	./ssar data3 -loop 1 --vsipl++-profile-mode=accum --vsipl++-profile-output=profile.out
+	./ssar data3 -loop 10 --vsipl++-profile-mode=accum --vsipl++-profile-output=profile.out
 	@echo "Formatting profiler output..."
 	${fmt-profile-command}  -sec -o profile3.txt data3/profile.out
 	./make_images.sh data3 1072 480 1144 756
diff -u apps/ssar/kernel1.hpp apps/ssar/kernel1.hpp
--- apps/ssar/kernel1.hpp	(working copy)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -251,6 +251,19 @@
   length_type mc_;
   length_type m_;
 
+  length_type fast_time_filter_ops_;
+  length_type slow_time_compression_ops_;
+  length_type slow_time_decompression_ops_;
+  length_type matched_filter_ops_;
+  length_type digital_spotlighting_ops_;
+
+  length_type range_loop_ops_;
+  length_type magnitude_ops_;
+  length_type interp_fftm_ops_;
+  length_type interpolation_ops_;
+
+  length_type kernel1_total_ops_;
+
   complex_col_matrix_type s_filt_;
   complex_matrix_type s_filt_t_;
   complex_matrix_type s_compr_filt_;
@@ -327,11 +340,12 @@
       // 87. (1 by m array of ints) icKX are the indices of the closest 
       //     cross-range sliver in the KX domain
       icKX_.put(i, j, static_cast<index_type>(
-        ((this->kx_.get(i, j) - KX0_.get(0)) / this->dkx_) + 0.5f) );
+        ((this->kx_.get(i, j) - KX0_.get(0)) / this->dkx_) + 0.5f)
+        - this->interp_sidelobes_);
 
       // 88. (I by m array of ints) ikx are the indices of the slice that 
       //     include the cross-range sliver at its center
-      index_type ikxrows = icKX_.get(i, j) - this->interp_sidelobes_;
+      index_type ikxrows = icKX_.get(i, j);
 
       for (index_type h = 0; h < this->I_; ++h)
       {
@@ -354,6 +368,60 @@
       }
     }
 
+  // Calculate operation counts
+
+  // Digital Spotlighting
+  //   : Forward FFTs = 5 N log2(N) per row/column
+  //   : Fast time filter = Forward FFT (by column) plus a vector multiply.
+  //       There are 6 ops/point for vmul.
+  //   : Slow time compression = Forward FFT (by row) of length mc followed
+  //       by an Inverse FFT (by row) of length m (after bandwidth expansion).
+  //   : Slow time decompression = Vector multiply, Forward FFT (by row)
+  //   : 2-D Matched filter ops = Vector multiply across columns, for each row.
+  float rows = static_cast<float>(n_);
+  float cols = static_cast<float>(mc_);
+  fast_time_filter_ops_ = static_cast<length_type>(
+    5 * rows * log(rows)/log(2.f) * cols +
+    6 * rows * cols);
+
+  float bwx_cols = static_cast<float>(m_);
+  slow_time_compression_ops_ = static_cast<length_type>(
+    5 * cols * log(cols)/log(2.f) * rows +
+    5 * bwx_cols * log(bwx_cols)/log(2.f) * rows);
+
+  slow_time_decompression_ops_ = static_cast<length_type>(
+    6 * rows * bwx_cols +
+    5 * bwx_cols * log(bwx_cols)/log(2.f) * rows);
+
+  matched_filter_ops_ = static_cast<length_type>(
+    6 * rows * bwx_cols);
+
+  digital_spotlighting_ops_ = fast_time_filter_ops_ + matched_filter_ops_ + 
+    slow_time_compression_ops_ + slow_time_decompression_ops_;
+
+
+  // Interpolation
+  //   : Range loop = scalar/complex multiply + complex add = 4 ops/point
+  //   : Complex mag = two multiplies, an add and a square root = 4 ops/point
+  //   : Inverse FFTMs = 5 N log2(N) in each dimension, times the opposite
+  //       dimension (there are two total, one in each direction)
+
+  range_loop_ops_ = 4 * m_ * n_ * this->I_;
+
+  magnitude_ops_ = 4 * m_ * this->nx_;
+
+  rows = static_cast<float>(m_);
+  cols = static_cast<float>(this->nx_);
+  interp_fftm_ops_ = static_cast<length_type>(
+      5 * rows * log(rows)/log(2.f) * cols +
+      5 * cols * log(cols)/log(2.f) * rows);
+
+  interpolation_ops_ = interp_fftm_ops_ + range_loop_ops_ + magnitude_ops_;
+
+
+  // Grand Total
+  
+  kernel1_total_ops_ = digital_spotlighting_ops_ + interpolation_ops_;
 }
 
 
@@ -362,6 +430,8 @@
 Kernel1<T>::process_image(complex_matrix_type const input, 
   real_matrix_type output)
 {
+  using impl::profile::Scope;
+  using impl::profile::user;
   assert(input.size(0) == n_);
   assert(input.size(1) == mc_);
   assert(output.size(0) == m_);
@@ -370,7 +440,7 @@
   // Time the remainder of this function, provided profiling is enabled 
   // (pass '--vsipl++-profile-mode=[accum|trace]' on the command line).  
   // If profiling is not enabled, then this statement has no effect.
-  impl::profile::Scope<impl::profile::user> scope("Kernel1 total", 391015615);
+  Scope<user> scope("Kernel1 total", kernel1_total_ops_);
 
 
   // Digital spotlighting and bandwidth-expansion using slow-time 
@@ -388,7 +458,10 @@
 void
 Kernel1<T>::digital_spotlighting(complex_matrix_type s_raw)
 {
-  impl::profile::Scope<impl::profile::user> scope("digital_spotlighting", 135485380);
+  using impl::profile::Scope;
+  using impl::profile::user;
+  Scope<user> scope("digital_spotlighting", digital_spotlighting_ops_);
+
   using vsip_csl::matlab::fftshift;
   assert(s_raw.size(0) == n_);
   assert(s_raw.size(1) == mc_);
@@ -485,7 +558,10 @@
 void // Matrix<T>
 Kernel1<T>::interpolation(real_matrix_type image)
 {
-  impl::profile::Scope<impl::profile::user> scope("interpolation", 255530235);
+  using impl::profile::Scope;
+  using impl::profile::user;
+  Scope<user> scope("interpolation", interpolation_ops_);
+
   using vsip_csl::matlab::fftshift;
   assert(image.size(0) == m_);
   assert(image.size(1) == this->nx_);
@@ -499,14 +575,14 @@
   F_ = complex<T>(0);
 
   // 86b. begin the range loop
-  { impl::profile::Scope<impl::profile::user> scope("interpolate", 83393024);
+  { Scope<user> scope("range loop", range_loop_ops_);
   for (index_type j = 0; j < m_; ++j)
   {
     for (index_type i = 0; i < n_; ++i)
     {
       // 88. (I by m array of ints) ikx are the indices of the slice that 
       //     include the cross-range sliver at its center
-      index_type ikxrows = icKX_.get(i, j) - this->interp_sidelobes_;
+      index_type ikxrows = icKX_.get(i, j);
 
       for (index_type h = 0; h < this->I_; ++h)
       {
@@ -531,8 +607,12 @@
   //     intensities) 
+  { Scope<user> scope("doppler to spatial transform", interp_fftm_ops_);
   fftshift(ifftmc_(F_ = ifftmr_(fftshift(F_, F_shifted_))), spatial_);
+  }
 
   // for viewing, transpose spatial's magnitude 
   // 95. (m by nx array of reals) image (pixel intensities)
+  { Scope<user> scope("magnitude/trans", magnitude_ops_);
   image_t_ = mag(spatial_);
   image = image_t_.transpose();
+  }
 }
