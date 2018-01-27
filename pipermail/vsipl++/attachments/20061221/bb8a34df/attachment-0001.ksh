Index: src/vsip_csl/save_view.hpp
===================================================================
--- src/vsip_csl/save_view.hpp	(revision 158225)
+++ src/vsip_csl/save_view.hpp	(working copy)
@@ -18,8 +18,8 @@
 #include <vsip/tensor.hpp>
 #include <vsip/core/adjust_layout.hpp>
 #include <vsip/core/view_cast.hpp>
+#include <vsip/core/working_view.hpp>
 
-
 namespace vsip_csl
 {
 
@@ -201,7 +201,7 @@
 
   view_type disk_view = vsip::impl::clone_view<view_type>(view);
 
-  disk_view = vsip::impl::view_cast<T>(view);
+  vsip::impl::assign_local(disk_view, vsip::impl::view_cast<T>(view));
     
   vsip_csl::save_view(filename, disk_view);
 } 
Index: apps/ssar/GNUmakefile
===================================================================
--- apps/ssar/GNUmakefile	(revision 158225)
+++ apps/ssar/GNUmakefile	(working copy)
@@ -1,6 +1,6 @@
 ######################################################### -*-Makefile-*-
 #
-# File:   apps/ssar/Makefile
+# File:   apps/ssar/GNUmakefile
 # Author: Don McCoy
 # Date:   2006-10-28
 #
@@ -17,7 +17,7 @@
 # then this may be left blank, as pkg-config will obtain the path
 # from the .pc file.  If you set prefix here, it overrides the above
 # environment variable.
-prefix =
+prefix :=
 
 # This selects the desired library, which will vary depending on the
 # platform.  Consult the pkgconfig directory for a complete list of 
@@ -25,10 +25,10 @@
 # and it is in the path that pkg-config normally searches, then
 # this may be left blank (preferred).  Append '-debug' for building a 
 # version suitable for debugging or omit to use the optimized version.  
-suffix =
+suffix :=
 
 # The default precision is single (double may also be used)
-precision = single
+precision := single
 
 ifeq ($(precision),double)
 ref_image_base := ref_image_dp
@@ -89,6 +89,12 @@
 	@echo "Formatting profiler output..."
 	$(prefix)/bin/fmt-profile.pl -sec -o profile.txt set1/profile.out
 
+parallel: ssar
+	@echo "Running SSAR application on two processors..."
+	mpirun -np 2 ./ssar set1 
+	@echo "Comparing output to reference view (should be less than -100)"
+	./diffview -r set1/image.view set1/$(ref_image_base).view 756 1144
+
 ssar.o: ssar.cpp kernel1.hpp
 
 ssar: ssar.o
Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 158225)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -6,6 +6,9 @@
     @brief   VSIPL++ implementation of SSCA #3: Kernel 1, Image Formation
 */
 
+#include <vsip/map.hpp>
+#include <vsip/math.hpp>
+#include <vsip/matrix.hpp>
 #include <vsip/selgen.hpp>
 
 #include <vsip/core/profile.hpp>
@@ -21,17 +24,83 @@
 #define SAVE_VIEW(a, b)
 #endif
 
+
+template <typename T1,
+          typename T2,
+          typename Block1,
+          typename Block2>
+void
+fftshift(
+  const_Matrix<T1, Block1> in,
+  Matrix<T2, Block2>       out)
+{
+  Matrix<T2, Dense<2, T2, row2_type, Map<> > > rin (in.size(0), in.size(1));
+  Matrix<T2, Dense<2, T2, row2_type, Map<> > > rout(out.size(0), out.size(1));
+
+  rin = in;
+  vsip_csl::matlab::fftshift(rin, rout);
+  out = rout;
+}
+
+
+template <typename T1,
+          typename T2,
+          typename Block1,
+          typename Block2>
+void
+fftshift(
+  const_Vector<T1, Block1> in,
+  Vector<T2, Block2>       out)
+{
+  Vector<T2, Dense<1, T2, row2_type, Map<> > > rin (in.size(0));
+  Vector<T2, Dense<1, T2, row2_type, Map<> > > rout(out.size(0));
+
+  rin = in;
+  vsip_csl::matlab::fftshift(rin, rout);
+  out = rout;
+}
+
+
 template <typename T>
 class Kernel1_base
 {
 protected:
-  typedef Matrix<complex<T>, Dense<2, complex<T>, col2_type> > complex_col_matrix_type;
-  typedef Matrix<complex<T> > complex_matrix_type;
-  typedef Vector<complex<T> > complex_vector_type;
-  typedef Matrix<T, Dense<2, T, col2_type> > real_col_matrix_type;
-  typedef Matrix<T> real_matrix_type;
-  typedef Vector<T> real_vector_type;
+  // Data distribution maps.  Key:
+  //   cmap  column-distributed
+  //   rmap  row-distributed
+  //   tmap  tensor, distributed like cmap
+  //   vmap  vector, distributed like rmap
+  //   gmap  global map (all processors own a copy)
+  //   root  root map (base processor own's only copy)
+  typedef Map<Whole_dist, Block_dist> cmap_type;
+  typedef Map<Block_dist, Whole_dist> rmap_type;
+  typedef Map<Whole_dist, Block_dist, Whole_dist> tmap_type;
+  typedef Map<Block_dist> vmap_type;
+  typedef Global_map<1> gmap_type;
+  typedef Map<> root_map_type;
 
+  typedef Dense<2, complex<T>, col2_type, cmap_type> cblock_type;
+  typedef Dense<2, complex<T>, row2_type, rmap_type> rblock_type;
+  typedef Dense<1, complex<T>, row1_type, vmap_type> vblock_type;
+  typedef Dense<2, T, col2_type, cmap_type> real_cblock_type;
+  typedef Dense<2, T, row2_type, rmap_type> real_rblock_type;
+  typedef Dense<1, T, row1_type, vmap_type> real_vblock_type;
+  typedef Dense<3, T, tuple<1, 0, 2>, tmap_type > tblock_type;
+  typedef Dense<2, index_type, col2_type, cmap_type> int_cblock_type;
+  typedef Dense<1, T, tuple<0, 1, 2>, gmap_type > gblock_type;
+  typedef Dense<1, T, tuple<0, 1, 2>, root_map_type > root_block_type;
+
+  typedef Matrix<complex<T>, cblock_type> complex_col_matrix_type;
+  typedef Matrix<complex<T>, rblock_type> complex_matrix_type;
+  typedef Vector<complex<T>, vblock_type> complex_vector_type;
+  typedef Matrix<T, real_cblock_type> real_col_matrix_type;
+  typedef Matrix<T, real_rblock_type> real_matrix_type;
+  typedef Vector<T, real_vblock_type> real_vector_type;
+  typedef Tensor<T, tblock_type> real_col_tensor_type;
+  typedef Matrix<index_type, int_cblock_type> int_col_matrix_type;
+  typedef Vector<T, gblock_type> global_real_vector_type;
+  typedef Vector<T, root_block_type> root_real_vector_type;
+
   Kernel1_base(length_type scale, length_type n, length_type mc, 
     length_type m);
   ~Kernel1_base() {}
@@ -52,27 +121,38 @@
   T dkx_;
   T kx_min_;
   T kxs_;
+  processor_type np_;
+  vmap_type vmap_;
+  rmap_type rmap_;
+  cmap_type cmap_;
+  gmap_type gmap_;
 
   complex_vector_type fast_time_filter_;
   complex_matrix_type fs_ref_;
   real_vector_type ks_;
-  real_vector_type ucs_;
-  real_vector_type us_;
+  global_real_vector_type ucs_;
+  global_real_vector_type us_;
   real_matrix_type kx_;
+  real_col_matrix_type kx_col_;
 };
 
 template <typename T>
 Kernel1_base<T>::Kernel1_base(length_type scale, length_type n, 
   length_type mc, length_type m)
   : scale_(scale), n_(n), mc_(mc), m_(m),
-    fast_time_filter_(n),
-    fs_ref_(n, m),
-    ks_(n),
-    ucs_(mc),
-    us_(m),
-    kx_(n, m)
+    np_(num_processors()),
+    vmap_(np_),
+    rmap_(np_, 1),
+    cmap_(1, np_),
+    gmap_(),
+    fast_time_filter_(n, vmap_),
+    fs_ref_(n, m, rmap_),
+    ks_(n, vmap_),
+    ucs_(mc, gmap_),
+    us_(m, gmap_),
+    kx_(n, m, rmap_),
+    kx_col_(n, m, cmap_)
 {
-  using vsip_csl::matlab::fftshift;
   using vsip_csl::load_view_as;
 
   interp_sidelobes_ = 8;     // 2. (scalar, integer) number of 
@@ -107,43 +187,57 @@
                              //    center point (m)
 
   // Load scale-dependent processing parameters.
-  real_vector_type k(n);
-  real_vector_type uc(mc);
-  real_vector_type u(m);
-  real_vector_type ku0(m);
+  root_real_vector_type k(n);
+  root_real_vector_type k_tmp(n);
+  root_real_vector_type uc(mc);
+  root_real_vector_type u(m);
+  global_real_vector_type ku0(m, gmap_);
 
   load_view_as<complex<float>, complex_vector_type>
     (FAST_TIME_FILTER, fast_time_filter_);
-  load_view_as<float, real_vector_type>(SLOW_TIME_WAVENUMBER, k);
-  load_view_as<float, real_vector_type>
+  load_view_as<float, root_real_vector_type>
+    (SLOW_TIME_WAVENUMBER, k);
+  load_view_as<float, root_real_vector_type>
     (SLOW_TIME_COMPRESSED_APERTURE_POSITION, uc);
-  load_view_as<float, real_vector_type>(SLOW_TIME_APERTURE_POSITION, u);
-  load_view_as<float, real_vector_type>(SLOW_TIME_SPATIAL_FREQUENCY, ku0);
+  load_view_as<float, root_real_vector_type>
+    (SLOW_TIME_APERTURE_POSITION, u);
+  load_view_as<float, global_real_vector_type>
+    (SLOW_TIME_SPATIAL_FREQUENCY, ku0);
 
   // 60. (1 by n array of reals) fftshifted slow-time wavenumber
-  fftshift(k, ks_);
+  ::fftshift(k, ks_);
 
   // 61. (1 by mc array of reals) fftshifted slow-time synthetic aperture
-  fftshift(uc, ucs_);
+  ::fftshift(uc, ucs_);
 
   // 67. (1 by m array of reals) shifted u
-  fftshift(u, us_);
+  ::fftshift(u, us_);
 
   // 70. (1 by m array of reals) ku0 is transformed into the intermediate 
   //     (n by m array of reals) kx0 (wn)
-  real_matrix_type ku(n, m);
-  ku = vmmul<row>(ku0, real_matrix_type(n_, m_, T(1)));
+  real_matrix_type ones(n, m, rmap_);
 
-  real_matrix_type k1(n, m);
-  k1 = vmmul<col>(k, real_matrix_type(n_, m_, T(1)));
+  ones = T(1);
+  real_matrix_type ku(n, m, rmap_);
+  ku.local() = vmmul<row>(ku0.local(), ones.local());
 
-  real_matrix_type kx0(n, m);
-  kx0 = 4 * sq(k1) - sq(ku);
+  real_vector_type k_dist(n, vmap_);
+  k_dist = k;
 
+  ones = T(1);
+  real_matrix_type k1(n, m, rmap_);
+  k1.local() = vmmul<col>(k_dist.local(), ones.local());
+
+  real_matrix_type kx0(n, m, rmap_);
+  kx0.local() = 4 * sq(k1.local()) - sq(ku.local());
+
   // 71. (n by m array of reals) kx is the Doppler domain range 
   //     wavenumber (wn)    
-  kx_ = sqrt(max(T(0), kx0));
+  kx_.local() = sqrt(max(T(0), kx0.local()));
 
+  Matrix<T, Dense<2, T, row2_type, root_map_type > > kx_tmp(n_, m_);
+  kx_tmp = kx_;
+
   // 72. (scalar, real) minimum wavenum (wn)
   Index<2> idx;
   kx_min_ = minval(kx_, idx);
@@ -167,9 +261,11 @@
   //
   // this is equivalent to the elementwise operation
   //    fs_ref_.put(i, j, (kx_.get(i, j) > 0) ? exp(...) : complex<T>(0));
-  fs_ref_ = ite(kx_ > 0, exp(complex<T>(0, 1) * 
-    (Xc_ * (kx_ - 2 * k1) + T(0.25 * M_PI) + ku)), complex<T>(0));
+  fs_ref_.local() = ite(kx_.local() > 0, exp(complex<T>(0, 1) * 
+    (Xc_ * (kx_.local() - 2 * k1.local()) + T(0.25 * M_PI) + ku.local())), complex<T>(0));
 
+  kx_col_ = kx_;
+
   SAVE_VIEW("p76_fs_ref.view", fs_ref_);
 
   // 78. (scalar, int) interpolation processing sliver size
@@ -183,7 +279,6 @@
   //     indexing in interpolation loop)
   nx_ = nx0 + 2 * interp_sidelobes_ + 4;
 
-
 #ifdef VERBOSE
   std::cout << "kx_min = " << kx_min_ << std::endl;
   std::cout << "kx_max = " << kx_max << std::endl;
@@ -207,13 +302,22 @@
 class Kernel1 : public Kernel1_base<T>
 {
 public:
+  typedef typename Kernel1_base<T>::cmap_type cmap_type;
+  typedef typename Kernel1_base<T>::rmap_type rmap_type;
+  typedef typename Kernel1_base<T>::tmap_type tmap_type;
+  typedef typename Kernel1_base<T>::gmap_type gmap_type;
+
   typedef typename Kernel1_base<T>::complex_col_matrix_type complex_col_matrix_type;
   typedef typename Kernel1_base<T>::complex_matrix_type complex_matrix_type;
-  typedef typename Kernel1_base<T>::complex_vector_type complex_vector_type;
   typedef typename Kernel1_base<T>::real_col_matrix_type real_col_matrix_type;
   typedef typename Kernel1_base<T>::real_matrix_type real_matrix_type;
   typedef typename Kernel1_base<T>::real_vector_type real_vector_type;
+  typedef typename Kernel1_base<T>::real_col_tensor_type real_col_tensor_type;
+  typedef typename Kernel1_base<T>::int_col_matrix_type int_col_matrix_type;
+  typedef typename Kernel1_base<T>::global_real_vector_type global_real_vector_type;
 
+
+  typedef Vector<complex<T> > local_complex_vector_type;
   typedef Fft<const_Vector, complex<T>, complex<T>, fft_fwd, by_reference> col_fft_type;
   typedef Fft<const_Vector, complex<T>, complex<T>, fft_fwd, by_reference> row_fft_type;
   typedef Fft<const_Vector, complex<T>, complex<T>, fft_inv, by_reference> inv_fft_type;
@@ -244,18 +348,23 @@
   length_type n_;
   length_type mc_;
   length_type m_;
+  cmap_type cmap_;
+  rmap_type rmap_;
+  tmap_type tmap_;
+  gmap_type gmap_;
 
   complex_col_matrix_type s_filt_;
   complex_matrix_type s_filt_t_;
   complex_matrix_type s_compr_filt_;
-  Vector<complex<T> > fs_row_;
-  Vector<complex<T> > fs_spotlit_;
+  local_complex_vector_type fs_row_;
+  local_complex_vector_type fs_spotlit_;
   complex_matrix_type s_decompr_filt_;
   complex_matrix_type fsm_;
+  complex_matrix_type fsm_tmp_;
   complex_col_matrix_type fsm_t_;
-  Matrix<index_type, Dense<2, index_type, col2_type> > icKX_;
-  real_vector_type KX0_;
-  Tensor<T, Dense<3, T, tuple<1, 0, 2> > > SINC_HAM_;
+  int_col_matrix_type icKX_;
+  global_real_vector_type KX0_;
+  real_col_tensor_type SINC_HAM_;
   complex_col_matrix_type F_;
   complex_matrix_type F_shifted_;
   complex_col_matrix_type spatial_;
@@ -275,21 +384,26 @@
   length_type m)
   : Kernel1_base<T>(scale, n, mc, m),
     scale_(scale), n_(n), mc_(mc), m_(m), 
-    s_filt_(n, mc),
-    s_filt_t_(n, mc),
-    s_compr_filt_(n, mc),
+    cmap_(1, this->np_),
+    rmap_(this->np_, 1),
+    tmap_(1, this->np_, 1),
+    gmap_(),
+    s_filt_(n, mc, cmap_),
+    s_filt_t_(n, mc, rmap_),
+    s_compr_filt_(n, mc, rmap_),
     fs_row_(mc),
     fs_spotlit_(m),
-    s_decompr_filt_(n, m),
-    fsm_(n, m),
-    fsm_t_(n, m),
-    icKX_(n, m),
-    KX0_(this->nx_),
-    SINC_HAM_(n_, m_, this->I_),
-    F_(this->nx_, m_),
-    F_shifted_(this->nx_, m_),
-    spatial_(this->nx_, m_),
-    image_t_(this->nx_, m_),
+    s_decompr_filt_(n, m, rmap_),
+    fsm_(n, m, rmap_),
+    fsm_tmp_(n, m, rmap_),
+    fsm_t_(n, m, cmap_),
+    icKX_(n, m, cmap_),
+    KX0_(this->nx_, gmap_),
+    SINC_HAM_(n_, m_, this->I_, tmap_),
+    F_(this->nx_, m_, cmap_),
+    F_shifted_(this->nx_, m_, rmap_),
+    spatial_(this->nx_, m_, cmap_),
+    image_t_(this->nx_, m_, cmap_),
     ft_fft_(Domain<1>(n), T(1)),
     st_fft_(Domain<1>(m), T(1)),
     compr_fft_(Domain<1>(mc), static_cast<T>(m_) / mc_),
@@ -299,52 +413,57 @@
 {
   // 83. (1 by nx array of reals) uniformly-spaced KX0 points where 
   //     interpolation is done  
-  KX0_ = this->kx_min_ + 
-    (vsip::ramp(T(0),T(1), this->nx_) - this->interp_sidelobes_ - 2) *
+  KX0_.local() = vsip::ramp(T(0),T(1),this->nx_);
+  KX0_.local() = this->kx_min_ + 
+    (KX0_.local() - this->interp_sidelobes_ - 2) *
     this->dkx_;
 
   // Pre-computed values for eq. 62.
-  real_matrix_type nmc_ones(n_, mc_, T(1));
-  s_compr_filt_ = vmmul<col>(this->fast_time_filter_, 
-    exp(complex<T>(0, 2) * vmmul<col>(this->ks_, nmc_ones) *
-      (sqrt(sq(this->Xc_) + sq(vmmul<row>(this->ucs_, nmc_ones))) - this->Xc_)));
+  real_matrix_type nmc_ones(n_, mc_, T(1), rmap_);
+  s_compr_filt_.local() = vmmul<col>(this->fast_time_filter_.local(), 
+    exp(complex<T>(0, 2) * vmmul<col>(this->ks_.local(), nmc_ones.local()) *
+      (sqrt(sq(this->Xc_) + sq(vmmul<row>(this->ucs_.local(), nmc_ones.local()))) - this->Xc_)));
 
   // Pre-computed values for eq. 68. 
-  real_matrix_type nm_ones(n_, m_, T(1));
-  s_decompr_filt_ = exp( complex<T>(0, 2) * vmmul<col>(this->ks_, nm_ones) *
-    (this->Xc_ - sqrt(sq(this->Xc_) + sq(vmmul<row>(this->us_, nm_ones)))) );
+  real_matrix_type nm_ones(n_, m_, T(1), rmap_);
+  s_decompr_filt_.local() = exp( complex<T>(0, 2) * vmmul<col>(this->ks_.local(), nm_ones.local()) *
+    (this->Xc_ - sqrt(sq(this->Xc_) + sq(vmmul<row>(this->us_.local(), nm_ones.local())))) );
 
   // Pre-computed values for eq. 92.
-  for (index_type i = 0; i < n_; ++i)
-    for (index_type j = 0; j < m_; ++j)
+  typename real_col_matrix_type::local_type kx_local = this->kx_col_.local();
+  typename int_col_matrix_type::local_type icKX_local = icKX_.local();
+  typename real_col_tensor_type::local_type SINC_HAM_local = SINC_HAM_.local();
+
+  for (index_type j = 0; j < icKX_local.size(1); ++j)
+    for (index_type i = 0; i < n_; ++i)
     {
       // 87. (1 by m array of ints) icKX are the indices of the closest 
       //     cross-range sliver in the KX domain
-      icKX_.put(i, j, static_cast<index_type>(
-        ((this->kx_.get(i, j) - KX0_.get(0)) / this->dkx_) + 0.5f) );
+      icKX_local.put(i, j, static_cast<index_type>(
+        ((kx_local.get(i, j) - KX0_.get(0)) / this->dkx_) + 0.5f) );
 
       // 88. (I by m array of ints) ikx are the indices of the slice that 
       //     include the cross-range sliver at its center
-      index_type ikxrows = icKX_.get(i, j) - this->interp_sidelobes_;
+      index_type ikxrows = icKX_local.get(i, j) - this->interp_sidelobes_;
 
       for (index_type h = 0; h < this->I_; ++h)
       {
         // 89. (I by m array of reals) nKX are the signal values 
         //     of the corresponding slice
-        T nKX =  KX0_.get(ikxrows + h);
+        T nKX =  KX0_.local().get(ikxrows + h);
 
         // 90. (I by m array of reals) SINC is the interpolating window 
         //     (note not stand-alone sinc coefficients)
-        T sx = M_PI * (nKX - this->kx_.get(i, j)) / this->dkx_;
+        T sx = M_PI * (nKX - kx_local.get(i, j)) / this->dkx_;
 
         // reduce interpolation computational costs by using a tapered 
         // window
     
         // 91. (I by m array of reals) (not stand-alone Hamming 
         //     coefficients)
-        SINC_HAM_.put(i, j, h, (sx ? sin(sx) / sx : 1) * 
+        SINC_HAM_local.put(i, j, h, (sx ? sin(sx) / sx : 1) * 
           (0.54 + 0.46 * cos((M_PI / this->kxs_) * 
-            (nKX - this->kx_.get(i, j)))) );
+            (nKX - kx_local.get(i, j)))) );
       }
     }
 
@@ -383,7 +502,6 @@
 Kernel1<T>::digital_spotlighting(complex_matrix_type s_raw)
 {
   impl::profile::Scope<impl::profile::user> scope("digital_spotlighting", 135485380);
-  using vsip_csl::matlab::fftshift;
   assert(s_raw.size(0) == n_);
   assert(s_raw.size(1) == mc_);
 
@@ -397,23 +515,19 @@
   Domain<1> right_dst(mz + mc_/2, 1, mc_/2);
   Domain<1> right_src(mc_/2, 1, mc_/2);
 
-  // left/right domains for emulating fftshift of fs_spotlit_.
-  Domain<1> ldom(0, 1, m_/2);
-  Domain<1> rdom(m_/2, 1, m_/2);
-
   // The baseband reference signal is first transformed into the Doppler 
   // (spatial frequency) domain.  
 
   // corner-turn: to col-major
-  fftshift(s_raw, s_filt_); 
+  ::fftshift(s_raw, s_filt_);
 
   // 59. (n by mc array of complex numbers) filtered echoed signal
   // 
   // Note that the fast-time filter is combined with the compression
   // along the slow-time axis below.  
-  for (index_type j = 0; j < mc_; ++j)
+  for (index_type j = 0; j < s_filt_.local().size(1); ++j)
   {
-    ft_fft_(s_filt_.col(j));
+    ft_fft_(s_filt_.local().col(j));
   }
 
   // Digital spotlighting and bandwidth expansion in the ku domain 
@@ -422,12 +536,12 @@
   // corner-turn: to row-major
   s_filt_t_ = s_filt_;
 
-  for (index_type i = 0; i < n_; ++i)
+  for (index_type i = 0; i < fsm_.local().size(0); ++i)
   {
     // 62. (n by mc array of complex numbers) signal compressed along 
     //     slow-time (note that to view 'sCompr' it will need to be 
     //     fftshifted first.)
-    fs_row_ = s_filt_t_.row(i) * s_compr_filt_.row(i);
+    fs_row_ = s_filt_t_.local().row(i) * s_compr_filt_.local().row(i);
     
     // 63. (n by mc array of complex numbers) narrow-bandwidth polar format
     //     reconstruction along slow-time
@@ -446,30 +560,22 @@
 
     // 68. (n by m array of complex numbers) slow-time decompression (note 
     //     that to view 'sDecompr' it will need to be fftshifted first.)
-    fs_spotlit_ *= s_decompr_filt_.row(i);
+    fs_spotlit_ *= s_decompr_filt_.local().row(i);
 
     // 69. (n by m array of complex numbers) digitally-spotlighted SAR 
     //     signal spectrum
-    st_fft_(fs_spotlit_);
+    st_fft_(fs_spotlit_, fsm_.local().row(i));
+  }
 
+  // Match filter the spotlighted signal 'fsSpotLit' with the reference's 
+  // complex conjugate 'fsRef' along fast-time and slow-time, to remove 
+  // the reference signal's spectral components.
 
-    // Match filter the spotlighted signal 'fsSpotLit' with the reference's 
-    // complex conjugate 'fsRef' along fast-time and slow-time, to remove 
-    // the reference signal's spectral components.
+  // 77. (n by m array of complex nums) Doppler domain matched-filtered
+  //     signal
+  ::fftshift(fsm_, fsm_tmp_);
+  fsm_.local() = fsm_tmp_.local() * this->fs_ref_.local();
 
-    // 77. (n by m array of complex nums) Doppler domain matched-filtered
-    //     signal
-
-    // Merge fftshift and vmul:
-    //
-    //   fftshift(fs_spotlit_, fsm_);
-    //   fsm_.row(xr) = fs_spotlit_ * this->fs_ref_.row(xr);
-    //
-    index_type xr = (i < n_/2) ? (n_/2 + i) : (i - n_/2);
-    fsm_.row(xr)(ldom) = fs_spotlit_(rdom) * this->fs_ref_.row(xr)(ldom);
-    fsm_.row(xr)(rdom) = fs_spotlit_(ldom) * this->fs_ref_.row(xr)(rdom);
-  }
-
   SAVE_VIEW("p77_fsm.view", fsm_);
 }
 
@@ -480,7 +586,6 @@
 Kernel1<T>::interpolation(real_matrix_type image)
 {
   impl::profile::Scope<impl::profile::user> scope("interpolation", 255530235);
-  using vsip_csl::matlab::fftshift;
   assert(image.size(0) == m_);
   assert(image.size(1) == this->nx_);
 
@@ -490,17 +595,22 @@
   fsm_t_ = fsm_;
 
   // 86a. initialize the F(kx,ku) array
-  F_ = complex<T>(0);
+  typename complex_col_matrix_type::local_type F_local = F_.local();
+  F_local = complex<T>(0);
 
   // 86b. begin the range loop
+  typename int_col_matrix_type::local_type icKX_local = icKX_.local();
+  typename complex_col_matrix_type::local_type fsm_t_local = fsm_t_.local();
+  typename real_col_tensor_type::local_type SINC_HAM_local = SINC_HAM_.local();
+
   { impl::profile::Scope<impl::profile::user> scope("interpolate", 83393024);
-  for (index_type j = 0; j < m_; ++j)
+  for (index_type j = 0; j < icKX_local.size(1); ++j)
   {
     for (index_type i = 0; i < n_; ++i)
     {
       // 88. (I by m array of ints) ikx are the indices of the slice that 
       //     include the cross-range sliver at its center
-      index_type ikxrows = icKX_.get(i, j) - this->interp_sidelobes_;
+      index_type ikxrows = icKX_local.get(i, j) - this->interp_sidelobes_;
 
       for (index_type h = 0; h < this->I_; ++h)
       {
@@ -509,8 +619,8 @@
     
         // 92. (nx by m array of complex nums) F is the rectangular signal 
         //     spectrum
-        F_.put(ikxrows + h, j, F_.get(ikxrows + h, j) + 
-          (fsm_t_.get(i, j) * SINC_HAM_.get(i, j, h)));
+        F_local.put(ikxrows + h, j, F_local.get(ikxrows + h, j) + 
+          (fsm_t_local.get(i, j) * SINC_HAM_local.get(i, j, h)));
       }
     }
   } // 93. end the range loop
@@ -523,10 +633,14 @@
 
   // 94. (nx by m array of complex nums) spatial image (complex pixel 
   //     intensities) 
-  fftshift(ifftmc_(F_ = ifftmr_(fftshift(F_, F_shifted_))), spatial_);
+  ::fftshift(F_, F_shifted_);
 
+  ifftmc_(F_ = ifftmr_(F_shifted_));
+
+  ::fftshift(F_, spatial_);
+
   // for viewing, transpose spatial's magnitude 
   // 95. (m by nx array of reals) image (pixel intensities)
-  image_t_ = mag(spatial_);
-  image = image_t_.transpose();
+  image_t_.local() = mag(spatial_.local());
+  image.local() = image_t_.local().transpose();
 }
Index: apps/ssar/ssar.cpp
===================================================================
--- apps/ssar/ssar.cpp	(revision 158225)
+++ apps/ssar/ssar.cpp	(working copy)
@@ -71,13 +71,14 @@
 
   // Retrieve the raw radar image data from disk.  This Data I/O 
   // component is currently untimed.
-  Kernel1<T>::complex_matrix_type s_raw(opt.n, opt.mc);
-  load_view_as<complex<float>, 
-    Kernel1<T>::complex_matrix_type>(RAW_SAR_DATA, s_raw);
+  typedef Kernel1<T>::rmap_type map_type;
+  map_type rmap = map_type(Block_dist(num_processors()), Whole_dist());
+  Kernel1<T>::complex_matrix_type s_raw(opt.n, opt.mc, rmap);
+  load_view_as<complex<float>, Kernel1<T>::complex_matrix_type>(RAW_SAR_DATA, s_raw);
 
   // Resolve the image.  This Computation component is timed.
   Kernel1<T>::real_matrix_type 
-    image(k1.output_size(0), k1.output_size(1));
+    image(k1.output_size(0), k1.output_size(1), rmap);
 
   vsip::impl::profile::Acc_timer t1;
   vsip::Vector<double> process_time(loop);
