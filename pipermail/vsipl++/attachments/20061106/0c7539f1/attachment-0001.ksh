Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 154102)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -271,10 +271,11 @@
   complex_matrix_type s_decompr_filt_;
   complex_matrix_type s_decompr_;
   complex_matrix_type fsm_;
-  Vector<index_type> icKX_;
+  Matrix<index_type> icKX_;
 //  real_vector_type x_;
   real_vector_type KX0_;
   real_matrix_type KX_;
+  Tensor<T> SINC_HAM_;
   complex_matrix_type F_;
   complex_matrix_type F_shifted_;
   complex_matrix_type spatial_;
@@ -303,10 +304,11 @@
     s_decompr_filt_(n, m),
     s_decompr_(n, m),
     fsm_(n, m),
-    icKX_(m),
+    icKX_(n, m),
 //    x_(this->nx_),
     KX0_(this->nx_),
     KX_(this->nx_, m_),
+    SINC_HAM_(n_, m_, this->I_),
     F_(this->nx_, m_),
     F_shifted_(this->nx_, m_),
     spatial_(this->nx_, m_),
@@ -342,7 +344,42 @@
   s_decompr_filt_ = exp( complex<T>(0, 2) * vmmul<col>(this->ks_, nm_ones) *
     (this->Xc_ - sqrt(sq(this->Xc_) + sq(vmmul<row>(this->us_, nm_ones)))) );
 
+  // Pre-computed values for eq. 92.
+  for (index_type i = 0; i < n_; ++i)
+    for (index_type j = 0; j < m_; ++j)
+    {
+      // 87. (1 by m array of ints) icKX are the indices of the closest 
+      //     cross-range sliver in the KX domain
+      icKX_(i, j) = static_cast<index_type>(
+        ((this->kx_.get(i, j) - KX_.get(0, 0)) / this->dkx_) + 0.5f);
 
+      // 88. (I by m array of ints) ikx are the indices of the slice that 
+      //     include the cross-range sliver at its center
+      index_type ikxrows;
+      ikxrows = icKX_.get(i, j) - this->interp_sidelobes_;
+
+      for (index_type h = 0; h < this->I_; ++h)
+      {
+        // 89. (I by m array of reals) nKX are the signal values 
+        //     of the corresponding slice
+        T nKX =  KX_.get(ikxrows + h, j);
+
+        // 90. (I by m array of reals) SINC is the interpolating window 
+        //     (note not stand-alone sinc coefficients)
+        T sx = M_PI * (nKX - this->kx_.get(i, j)) / this->dkx_;
+
+        // reduce interpolation computational costs by using a tapered 
+        // window
+    
+        // 91. (I by m array of reals) (not stand-alone Hamming 
+        //     coefficients)
+        SINC_HAM_.put(i, j, h, (sx ? sin(sx) / sx : 1) * 
+          (0.54 + 0.46 * cos((M_PI / this->kxs_) * 
+            (nKX - this->kx_.get(i, j)))) );
+      }
+    }
+
+
 #ifdef VERBOSE
   std::cout << "kxc = " << kxc << std::endl;
 #endif
@@ -469,49 +506,23 @@
   // 86b. begin the range loop
   for (index_type i = 0; i < n_; ++i)
   {
-
-    // 87. (1 by m array of ints) icKX are the indices of the closest 
-    //     cross-range sliver in the KX domain
     for (index_type j = 0; j < m_; ++j)
-      icKX_(j) = static_cast<index_type>(
-        ((this->kx_.get(i, j) - KX_.get(0, 0)) / this->dkx_) + 0.5f);
+    {
+      // 88. (I by m array of ints) ikx are the indices of the slice that 
+      //     include the cross-range sliver at its center
+      index_type ikxrows = icKX_.get(i, j) - this->interp_sidelobes_;
 
-    // 88. (I by m array of ints) ikx are the indices of the slice that 
-    //     include the cross-range sliver at its center
-    index_type ikxrows;
-    index_type ikxcols;
-
-    for (index_type h = 0; h < this->I_; ++h)
-      for (index_type j = 0; j < m_; ++j)
+      for (index_type h = 0; h < this->I_; ++h)
       {
-        ikxrows = icKX_.get(j) + h - this->interp_sidelobes_;
-        ikxcols = j;
-
-        // 89. (I by m array of reals) nKX are the signal values 
-        //     of the corresponding slice
-        T nKX = KX_.get(ikxrows, ikxcols);
-
-        // 90. (I by m array of reals) SINC is the interpolating window 
-        //     (note not stand-alone sinc coefficients)
-        T sx = M_PI * (nKX - this->kx_.get(i, j)) / this->dkx_;
-        T SINC = (sx ? sin(sx) / sx : 1);
-
-        // reduce interpolation computational costs by using a tapered 
-        // window
-    
-        // 91. (I by m array of reals) (not stand-alone Hamming 
-        //     coefficients)
-        T HAM = 0.54 + 0.46 * cos((M_PI / this->kxs_) * 
-                  (nKX - this->kx_.get(i, j)));
-
         // sinc convolution interpolation of the signal's Doppler 
         // spectrum, from polar to rectangular coordinates 
     
         // 92. (nx by m array of complex nums) F is the rectangular signal 
         //     spectrum
-        F_.put(ikxrows, ikxcols, F_.get(ikxrows, ikxcols) + 
-          (fsm_.get(i, j) * SINC * HAM));
+        F_.put(ikxrows + h, j, F_.get(ikxrows + h, j) + 
+          (fsm_.get(i, j) * SINC_HAM_.get(i, j, h)));
       }
+    }
 
   } // 93. end the range loop
 
