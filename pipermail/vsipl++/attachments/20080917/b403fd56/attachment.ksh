Index: ChangeLog
===================================================================
--- ChangeLog	(revision 221746)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2008-09-17  Jules Bergmann  <jules@codesourcery.com>
+
+	* apps/ssar/kernel1.hpp (digital_spotlighting): add additional
+	  profiling, avoid unnec copies, avoid transpose+mmul.
+
 2008-09-16  Don McCoy  <don@codesourcery.com>
 
 	* apps/ssar/kernel1.hpp: Added a switch to utilize the Cell/B.E. user-
Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 221746)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -20,7 +20,7 @@
 #include <vsip_csl/save_view.hpp>
 #include <vsip_csl/load_view.hpp>
 
-#if 1
+#if 0
 #define VERBOSE
 #define SAVE_VIEW(a, b, c)    vsip_csl::save_view_as<complex<float> >(a, b, c)
 #else
@@ -630,17 +630,25 @@
   //
   // Note that the fast-time filter is combined with the compression
   // along the slow-time axis below.  
-  s_filt_ = ft_fftm_(fftshift(s_raw, s_filt_));
+  { Scope<user> scope("fftshift-1", n_ * mc_ * sizeof(complex<float>));
+  fftshift(s_raw, s_filt_);
+  }
+  ft_fftm_(s_filt_);
 
+  { Scope<user> scope("tranpose", n_ * mc_ * sizeof(complex<float>));
+  fs_ = s_filt_;
+  }
 
   // 62. (n by mc array of complex numbers) signal compressed along 
   //     slow-time (note that to view 'sCompr' it will need to be 
   //     fftshifted first.)
-  s_compr_ = s_filt_ * s_compr_filt_;
+  { Scope<user> scope("vmul-compr", n_ * mc_ * 6);
+  fs_ *= s_compr_filt_;
+  }
 
   // 63. (n by mc array of complex numbers) narrow-bandwidth polar format
   //     reconstruction along slow-time
-  fs_ = compr_fftm_(s_compr_);
+  compr_fftm_(fs_);
 
   // 64. (scalar, int) number of zeros to be padded into the ku domain 
   //     for slow-time upsampling
@@ -654,9 +662,11 @@
   Domain<2> right_dst(Domain<1>(0, 1, n_), Domain<1>(mz + mc_/2, 1, mc_/2));
   Domain<2> right_src(Domain<1>(0, 1, n_), Domain<1>(mc_/2, 1, mc_/2));
 
+  { Scope<user> scope("expand", n_ * m_ * sizeof(complex<float>));
   fs_padded_(left) = fs_(left);
   fs_padded_(center_dst) = T();
   fs_padded_(right_dst) = fs_(right_src);
+  }
 
   // 66. (n by m array of complex numbers) transform-back the zero 
   // padded spatial spectrum along its cross-range
@@ -664,18 +674,25 @@
 
   // 68. (n by m array of complex numbers) slow-time decompression (note 
   //     that to view 'sDecompr' it will need to be fftshifted first.)
+  { Scope<user> scope("vmul-decompr", n_ * m_ * 6);
   fs_padded_ *= s_decompr_filt_;
+  }
 
   // 69. (n by m array of complex numbers) digitally-spotlighted SAR 
   //     signal spectrum
-  fftshift(st_fftm_(fs_padded_), fs_spotlit_);
+  st_fftm_(fs_padded_);
+  { Scope<user> scope("fftshift-3", n_ * m_ * sizeof(complex<float>));
+  fftshift(fs_padded_, fsm_);
+  }
 
   // match filter the spotlighted signal 'fsSpotLit' with the reference's 
   // complex conjugate 'fsRef' along fast-time and slow-time, to remove 
   // the reference signal's spectral components.
 
   // 77. (n by m array of complex nums) Doppler domain matched-filtered signal
-  fsm_ = fs_spotlit_ * this->fs_ref_;
+  { Scope<user> scope("vmul-fsm", n_ * m_ * 6);
+  fsm_ *= this->fs_ref_;
+  }
 
   SAVE_VIEW("p77_fsm.view", fsm_, this->swap_bytes_);
 }
@@ -698,10 +715,14 @@
   // Interpolate From Polar Coordinates to Rectangular Coordinates
 
   // corner-turn to col-major
+  { Scope<user> scope("fsm corner-turn", n_ * m_ * sizeof(complex<float>));
   fsm_t_ = fsm_;
+  }
 
   // 86a. initialize the F(kx,ku) array
+  { Scope<user> scope("zero", this->nx_ * m_ * sizeof(complex<float>));
   F_ = complex<T>(0);
+  }
 
   // 86b. begin the range loop
   { Scope<user> scope("range loop", range_loop_ops_);
@@ -753,8 +774,9 @@
 
   // for viewing, transpose spatial's magnitude 
   // 95. (m by nx array of reals) image (pixel intensities)
-  { Scope<user> scope("magnitude/trans", magnitude_ops_);
-  image_t_ = mag(spatial_);
+  { Scope<user> scope("magnitude", magnitude_ops_);
+  image_t_ = mag(spatial_); }
+  { Scope<user> scope("trans", m_ * this->nx_ * sizeof(complex<float>));
   image = image_t_.transpose();
   }
 }
