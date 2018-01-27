Index: apps/ssar/load_save.hpp
===================================================================
--- apps/ssar/load_save.hpp	(revision 0)
+++ apps/ssar/load_save.hpp	(revision 0)
@@ -0,0 +1,114 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    load_save.hpp
+    @author  Don McCoy
+    @date    2006-10-26
+    @brief   Extensions to allow type double to be used as the view
+             data type while using float as the storage type on disk.
+*/
+
+#ifndef LOAD_SAVE_HPP
+#define LOAD_SAVE_HPP
+
+#include <vsip_csl/load_view.hpp>
+#include <vsip_csl/save_view.hpp>
+
+using namespace vsip_csl;
+
+template <typename Block>
+void
+save_view(
+  char const* filename,
+  vsip::const_Matrix<complex<double>, Block> view)
+{
+  vsip::Matrix<complex<float> > sp_view(view.size(0), view.size(1));
+
+  for (index_type i = 0; i < view.size(0); ++i)
+    for (index_type j = 0; j < view.size(1); ++j)
+      sp_view.put(i, j, static_cast<complex<float> >(view.get(i, j)));
+  
+  Save_view<2, complex<float> >::save(const_cast<char*>(filename), sp_view);
+}
+
+template <typename Block>
+void
+save_view(
+  char const* filename,
+  vsip::const_Matrix<double, Block> view)
+{
+  vsip::Matrix<float> sp_view(view.size(0), view.size(1));
+
+  for (index_type i = 0; i < view.size(0); ++i)
+    for (index_type j = 0; j < view.size(1); ++j)
+      sp_view.put(i, j, static_cast<float>(view.get(i, j)));
+  
+  Save_view<2, float>::save(const_cast<char *>(filename), sp_view);
+}
+
+template <typename Block>
+void
+save_view(
+  char const* filename,
+  vsip::const_Vector<double, Block> view)
+{
+  vsip::Vector<float> sp_view(view.size(0));
+
+  for (index_type i = 0; i < view.size(0); ++i)
+    sp_view.put(i, static_cast<float>(view.get(i)));
+  
+  Save_view<1, float>::save(const_cast<char *>(filename), sp_view);
+}
+
+
+vsip::Matrix<complex<double> >
+load_view(
+  char const* filename,
+  vsip::Domain<2> const& dom)
+{
+  vsip::Matrix<complex<float> > sp_view(dom[0].size(), dom[1].size());
+  sp_view = Load_view<2, complex<float> >(filename, dom).view();
+
+  vsip::Matrix<complex<double> > view(dom[0].size(), dom[1].size());
+
+  for (index_type i = 0; i < dom[0].size(); ++i)
+    for (index_type j = 0; j < dom[1].size(); ++j)
+      view.put(i, j, static_cast<complex<double> >(sp_view.get(i, j)));
+
+  return view;
+}
+
+vsip::Vector<double>
+load_view(
+  char const* filename,
+  vsip::Domain<1> const& dom, 
+  double)
+{
+  vsip::Vector<float> sp_view(dom[0].size());
+  sp_view = Load_view<1, float>(filename, dom).view();
+
+  vsip::Vector<double> view(dom[0].size());
+
+  for (index_type i = 0; i < dom[0].size(); ++i)
+    view.put(i, static_cast<double>(sp_view.get(i)));
+
+  return view;
+}
+
+vsip::Vector<complex<double> >
+load_view(
+  char const* filename,
+  vsip::Domain<1> const& dom, 
+  complex<double>)
+{
+  vsip::Vector<complex<float> > sp_view(dom[0].size());
+  sp_view = Load_view<1, complex<float> >(filename, dom).view();
+
+  vsip::Vector<complex<double> > view(dom[0].size());
+
+  for (index_type i = 0; i < dom[0].size(); ++i)
+    view.put(i, static_cast<complex<double> >(sp_view.get(i)));
+
+  return view;
+}
+
+#endif // LOAD_SAVE_HPP
Index: apps/ssar/diffview.cpp
===================================================================
--- apps/ssar/diffview.cpp	(revision 0)
+++ apps/ssar/diffview.cpp	(revision 0)
@@ -0,0 +1,110 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    diffview.cpp
+    @author  Don McCoy
+    @date    2006-10-29
+    @brief   Utility to compare VSIPL++ views to determine equality
+*/
+
+#include <iostream>
+#include <stdlib.h>
+
+#include <vsip/initfin.hpp>
+#include <vsip/math.hpp>
+
+#include <vsip_csl/load_view.hpp>
+#include <vsip_csl/save_view.hpp>
+#include <vsip_csl/error_db.hpp>
+
+
+using namespace vsip;
+using namespace vsip_csl;
+using namespace std;
+
+
+enum data_format_type
+{
+  COMPLEX_VIEW = 0,
+  REAL_VIEW,
+  INTEGER_VIEW
+};
+
+void compare(data_format_type format, 
+  char const* infile, char const* ref, length_type rows, length_type cols);
+
+int
+main(int argc, char** argv)
+{
+  vsip::vsipl init(argc, argv);
+
+  if (argc < 5 || argc > 6)
+  {
+    fprintf(stderr, "Usage: %s [-rn] <input> <reference> <rows> <cols>\n", 
+      argv[0]);
+    return -1;
+  }
+  else
+  {
+    data_format_type format = COMPLEX_VIEW;
+    if (argc == 6)
+    {
+      if (0 == strncmp("-r", argv[1], 2))
+        format = REAL_VIEW;
+      else if (0 == strncmp("-n", argv[1], 2))
+        format = INTEGER_VIEW;
+      argv++;
+    }
+
+    compare(format, argv[1], argv[2], atoi(argv[3]), atoi(argv[4]));
+  }
+
+  return 0;
+}
+
+
+
+void
+compare(data_format_type format, 
+  char const* infile, char const* ref, length_type rows, length_type cols)
+{
+  if (format == REAL_VIEW)
+  {
+    typedef Matrix<scalar_f> matrix_type;
+    Domain<2> dom(rows, cols);
+
+    matrix_type in(rows, cols);
+    in = Load_view<2, scalar_f>(infile, dom).view();
+
+    matrix_type refv(rows, cols);
+    refv = Load_view<2, scalar_f>(ref, dom).view();
+
+    cout << error_db(in, refv) << endl;
+  }
+  else if (format == INTEGER_VIEW)
+  {
+    typedef Matrix<scalar_i> matrix_type;
+    Domain<2> dom(rows, cols);
+
+    matrix_type in(rows, cols);
+    in = Load_view<2, scalar_i>(infile, dom).view();
+
+    matrix_type refv(rows, cols);
+    refv = Load_view<2, scalar_i>(ref, dom).view();
+
+    cout << error_db(in, refv) << endl;
+  }
+  else          // Using complex views.
+  {
+    typedef Matrix<cscalar_f> matrix_type;
+    Domain<2> dom(rows, cols);
+
+    matrix_type in(rows, cols);
+    in = Load_view<2, cscalar_f>(infile, dom).view();
+
+    matrix_type refv(rows, cols);
+    refv = Load_view<2, cscalar_f>(ref, dom).view();
+
+    cout << error_db(in, refv) << endl;
+  }
+}
+
Index: apps/ssar/make_set1_images.sh
===================================================================
--- apps/ssar/make_set1_images.sh	(revision 0)
+++ apps/ssar/make_set1_images.sh	(revision 0)
@@ -0,0 +1,29 @@
+#! /bin/sh
+
+# This script creates images from the intermediate images produced during
+# Kernel 1 processing (when VERBOSE is defined in kernel1.hpp).
+#
+# Requires 'rawtopgm' and 'viewtoraw' (the source for the latter is included).
+
+echo "converting to raw greyscale..."
+./viewtoraw set1/sar.view set1/p00_sar.raw 1072 480
+./viewtoraw set1/p62_s_compr.view set1/p62_s_compr.raw 1072 480
+./viewtoraw set1/p65_fs_padded.view set1/p65_fs_padded.raw 1072 1144
+./viewtoraw set1/p68_s_decompr.view set1/p68_s_decompr.raw 1072 1144
+./viewtoraw set1/p69_fs_spotlit.view set1/p69_fs_spotlit.raw 1072 1144
+./viewtoraw -r set1/p76_fs_ref.view set1/p76_fs_ref.raw 1072 1144
+./viewtoraw set1/p92_F.view set1/p92_F.raw 756 1144
+./viewtoraw -s set1/image.view set1/p95_image.raw 1144 756
+
+echo "converting to set1/pgm format..."
+rawtopgm 480 1072 set1/p00_sar.raw > set1/p00_sar.pgm
+rawtopgm 480 1072 set1/p62_s_compr.raw > set1/p62_s_compr.pgm
+rawtopgm 1144 1072 set1/p65_fs_padded.raw > set1/p65_fs_padded.pgm
+rawtopgm 1144 1072 set1/p68_s_decompr.raw > set1/p68_s_decompr.pgm
+rawtopgm 1144 1072 set1/p69_fs_spotlit.raw > set1/p69_fs_spotlit.pgm
+rawtopgm 1144 1072 set1/p76_fs_ref.raw > set1/p76_fs_ref.pgm
+rawtopgm 1144 756 set1/p92_F.raw > set1/p92_F.pgm
+rawtopgm 756 1144 set1/p95_image.raw > set1/p95_image.pgm
+
+echo "cleaning up raw files..."
+rm set1/p*.raw

Property changes on: apps/ssar/make_set1_images.sh
___________________________________________________________________
Name: svn:executable
   + *

Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 0)
+++ apps/ssar/kernel1.hpp	(revision 0)
@@ -0,0 +1,537 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    kernel.hpp
+    @author  Don McCoy
+    @date    2006-10-26
+    @brief   VSIPL++ implementation of SSCA #3: Kernel 1, Image Formation
+*/
+
+#include <vsip/impl/profile.hpp>
+
+#include "load_save.hpp"
+
+#if 0
+#define VERBOSE
+#define SAVE_VIEW(a, b)    save_view(a, b)
+#else
+#define SAVE_VIEW(a, b)
+#endif
+
+// Files required to be in the data directory:
+char const* SAR_DIMENSIONS =                         "dims.txt";
+char const* RAW_SAR_DATA =                           "sar.view";
+char const* FAST_TIME_FILTER =                       "ftfilt.view";
+char const* SLOW_TIME_WAVENUMBER =                   "k.view";
+char const* SLOW_TIME_COMPRESSED_APERTURE_POSITION = "uc.view";
+char const* SLOW_TIME_APERTURE_POSITION =            "u.view";
+char const* SLOW_TIME_SPATIAL_FREQUENCY =            "ku.view";
+
+
+class Kernel1
+{
+public:
+  typedef double T;
+  typedef Matrix<complex<T> > complex_matrix_type;
+  typedef Vector<complex<T> > complex_vector_type;
+  typedef Matrix<T> real_matrix_type;
+  typedef Vector<T> real_vector_type;
+  typedef Fftm<complex<T>, complex<T>, col> col_fftm_type;
+  typedef Fftm<complex<T>, complex<T>, row> row_fftm_type;
+  typedef Fftm<complex<T>, complex<T>, row, fft_inv> ifftm_type;
+
+  Kernel1(length_type scale, length_type n, length_type mc, length_type m);
+  ~Kernel1() {}
+
+  void process_image();
+
+private:
+  void
+  fast_time_filtering(complex_matrix_type s_raw, 
+    complex_vector_type fast_time_filter);
+
+  void
+  digital_spotlighting(complex_matrix_type s_filt, 
+    real_vector_type k, real_vector_type uc, real_vector_type u );
+
+  real_matrix_type
+  interpolation(complex_matrix_type fs_spotlit, real_vector_type k, 
+    real_vector_type ku0);
+
+  complex_matrix_type
+  fft_shift(complex_matrix_type in);
+
+  real_vector_type
+  fft_shift(real_vector_type in);
+
+private:
+  length_type scale_;
+  length_type n_;
+  length_type mc_;
+  length_type m_;
+  length_type nx_;
+  length_type interp_sidelobes_;
+  T range_factor_;
+  T aspect_ratio_;
+  T L_;
+  T Y0_;
+  T X0_;
+  T Xc_;
+
+  complex_matrix_type s_raw_;
+  complex_vector_type fast_time_filter_;
+
+  real_vector_type slow_time_wavenumber_;
+  real_vector_type slow_time_compressed_aperture_position_;
+  real_vector_type slow_time_aperture_position_;
+  real_vector_type slow_time_spatial_frequency_;
+  complex_matrix_type s_filt_;
+  complex_matrix_type fs_spotlit_;
+  real_vector_type ks_;
+  real_vector_type ucs_;
+  complex_matrix_type s_compr_;
+  complex_matrix_type fs_;
+  complex_matrix_type fs_padded_;
+  complex_matrix_type s_padded_;
+  real_vector_type us_;
+  complex_matrix_type s_decompr_;
+  real_matrix_type ku_;
+  real_matrix_type k1_;
+  real_matrix_type kx0_;
+  real_matrix_type kx_;
+  complex_matrix_type fs_ref_;
+  complex_matrix_type fsm_;
+  Vector<index_type> icKX_;
+
+  col_fftm_type col_fftm;
+  row_fftm_type row_fftm;
+  row_fftm_type row_fftm2;
+  ifftm_type ifftm;
+};
+
+
+
+Kernel1::Kernel1(length_type scale, length_type n, length_type mc, 
+  length_type m)
+  : scale_(scale), n_(n), mc_(mc), m_(m), nx_(0),
+    s_raw_(n, mc),
+    fast_time_filter_(n),
+    s_filt_(n, mc),
+    slow_time_wavenumber_(n),
+    slow_time_compressed_aperture_position_(mc),
+    slow_time_aperture_position_(m),
+    slow_time_spatial_frequency_(m),
+    fs_spotlit_(n, m),
+    ks_(n_),
+    ucs_(mc_),
+    s_compr_(n_, mc_),
+    fs_(n_, mc_),
+    fs_padded_(n_, m_, T()),
+    s_padded_(n_, m_),
+    us_(m_),
+    s_decompr_(n_, m_),
+    ku_(n_, m_),
+    k1_(n_, m_),
+    kx0_(n_, m_),
+    kx_(n_, m_),
+    fs_ref_(n_, m_, T(0)),
+    fsm_(n_, m_),
+    icKX_(m_),
+    col_fftm(Domain<2>(n, mc), T(1)),
+    row_fftm(Domain<2>(n, mc), T(1)),
+    row_fftm2(Domain<2>(n, m), T(1)),
+    ifftm(Domain<2>(n, m), T(1.f/m))
+{
+  interp_sidelobes_ = 8;     // 2. (scalar, integer) number of 
+                             //    neighboring sidelobes used in sinc interp.
+                             //    WARNING: Changing 'nInterpSidelobes' 
+                             //    changes the size of the Y dimension  
+                             //    of the resulting image.
+
+  // SPATIAL/GEOMETRIC PARAMETERS
+
+  range_factor_ = T(10);     // 3. (scalar, real) ratio of swath's range
+                             //    center point to the synthetic aperture's
+                             //    half-length (unitless)
+
+  aspect_ratio_ = T(0.4);    // 4. (scalar, real) ratio of swath's range
+                             //    to cross-range (unitless)
+
+  L_ = T(100) * scale_;      // 5. (scalar, real) half of the synthetic
+                             //    aperture (in meters, synthetic aperterture 
+                             //    is 2*L). 'L' is the only physical dimension
+                             //    (since we have the L=Y0 simplification)
+                             //    all other SAR parameters are keyed on
+                             //    this value.
+
+  Y0_ = L_;                  // 6. (scalar, real) target area's half
+                             //    cross-range (within [Yc-Y0, Yc+Y0], meters)
+
+  X0_ = aspect_ratio_ * Y0_; // 7. (scalar, real) target area's half range
+                             //    (within [Xc-X0, Xc+X0], in meters)
+
+  Xc_ = range_factor_ * Y0_; // 8. (scalar, real) swath's range
+                             //    center point (m)
+
+#ifdef VERBOSE
+  std::cout << "n = " << n_ << std::endl;
+  std::cout << "mc = " << mc_ << std::endl;
+  std::cout << "m = " << m_ << std::endl;
+#endif
+}
+
+
+void
+Kernel1::process_image()
+{
+  // Load the raw radar image data
+  s_raw_ = load_view(RAW_SAR_DATA, Domain<2>(n_, mc_));
+
+  // Load scale-dependent processing parameters.
+  fast_time_filter_ = 
+    load_view(FAST_TIME_FILTER, Domain<1>(n_), complex<T>());
+  slow_time_wavenumber_ = 
+    load_view(SLOW_TIME_WAVENUMBER, Domain<1>(n_), T());
+  slow_time_compressed_aperture_position_ = 
+    load_view(SLOW_TIME_COMPRESSED_APERTURE_POSITION, Domain<1>(mc_), T());
+  slow_time_aperture_position_ = 
+    load_view(SLOW_TIME_APERTURE_POSITION, Domain<1>(m_), T());
+  slow_time_spatial_frequency_ = 
+    load_view(SLOW_TIME_SPATIAL_FREQUENCY, Domain<1>(m_), T());
+
+  // Time the remainder of this function, provided profiling is enabled 
+  // (pass '--vsipl++-profile-mode=[accum|trace]' on the command line).  
+  // If profiling is not enabled, then this statement has no effect.
+  impl::profile::Scope_event kernel1_event("Kernel1 total", 1);
+
+
+  // Digital spotlighting and bandwidth-expansion using slow-time 
+  // compression and decompression.  
+  //   fs_spotlit_   stores the processed signal
+  this->digital_spotlighting(s_filt_, slow_time_wavenumber_, 
+    slow_time_compressed_aperture_position_, slow_time_aperture_position_);
+
+
+  // Digital reconstruction via spatial frequency interpolation.
+  real_matrix_type image(
+    this->interpolation(fs_spotlit_, slow_time_wavenumber_, 
+      slow_time_spatial_frequency_));
+
+  // Store the image on disk for later processing.
+  save_view("image.view", image);  
+}
+
+
+
+void
+Kernel1::digital_spotlighting(complex_matrix_type s_filt, 
+  real_vector_type k, real_vector_type uc, real_vector_type u )
+{
+  assert(n_ == s_filt.size(0));
+  assert(mc_ == s_filt.size(1));
+  assert(n_ == k.size());
+  assert(mc_ == uc.size());
+  assert(m_ == u.size());
+
+  // The baseband reference signal is first transformed into the Doppler 
+  // (spatial frequency) domain.  
+
+  // 59. (n by mc array of complex numbers) filtered echoed signal
+  s_filt_ = vmmul<col>(fast_time_filter_, col_fftm(this->fft_shift(s_raw_)));
+
+  SAVE_VIEW("p59_s_filt.view", this->fft_shift(s_filt_));
+
+  // 60. (1 by n array of reals) fftshifted slow-time wavenumber
+  ks_ = this->fft_shift(k);
+
+  // 61. (1 by mc array of reals) fftshifted slow-time synthetic aperture
+  ucs_ = this->fft_shift(uc);
+
+  // 62. (n by mc array of complex numbers) signal compressed along 
+  //     slow-time (note that to view 'sCompr' it will need to be 
+  //     fftshifted first.)
+  for (index_type i = 0; i < n_; ++i)
+    for (index_type j = 0; j < mc_; ++j)
+    {
+      s_compr_.put(i, j, s_filt.get(i, j) * 
+        exp(complex<T>(0, 2) * ks_(i) * (sqrt(sq(Xc_) + sq(ucs_(j))) - Xc_)));
+    }
+
+  SAVE_VIEW("p62_s_compr.view", this->fft_shift(s_compr_));
+
+  // 63. (n by mc array of complex numbers) narrow-bandwidth polar format
+  //     reconstruction along slow-time
+  fs_ = row_fftm(s_compr_);
+
+  // 64. (scalar, int) number of zeros to be padded into the ku domain 
+  //     for slow-time upsampling
+  length_type mz = m_ - mc_;
+
+  // 65. (n by m array of complex numbers) zero pad the spatial frequency 
+  //     domain's compressed signal along its slow-time (note that to view 
+  //     'fsPadded' it will need to be fftshifted first)
+  T m_scale = static_cast<T>(m_) / static_cast<T>(mc_);
+  for (index_type i = 0; i < n_; ++i)
+  {
+    for (index_type j = 0; j < mc_ / 2; ++j)
+        fs_padded_.put(i, j, m_scale * fs_.get(i, j));
+
+    for (index_type j = mc_ / 2; j < mc_; ++j)
+        fs_padded_.put(i, j + mz, m_scale * fs_.get(i, j));
+  }
+  SAVE_VIEW("p65_fs_padded.view", this->fft_shift(fs_padded_));
+
+  // 66. (n by m array of complex numbers) transform-back the zero 
+  // padded spatial spectrum along its cross-range
+  s_padded_ = ifftm(fs_padded_);
+
+  // 67. (1 by m array of reals) shifted u
+  us_ = this->fft_shift(u);
+
+  // 68. (n by m array of complex numbers) slow-time decompression (note 
+  //     that to view 'sDecompr' it will need to be fftshifted first.)
+  for (index_type i = 0; i < n_; ++i)
+    for (index_type j = 0; j < m_; ++j)
+    {
+      s_decompr_.put(i, j, s_padded_.get(i, j) * 
+        exp( complex<T>(0, 2) * ks_(i) * (Xc_ - sqrt(sq(Xc_) + sq(us_(j)))) ));
+    }
+
+  SAVE_VIEW("p68_s_decompr.view", this->fft_shift(s_decompr_));
+
+  // 69. (n by m array of complex numbers) digitally-spotlighted SAR 
+  //     signal spectrum
+  fs_spotlit_ = this->fft_shift(row_fftm2(s_decompr_));
+
+  SAVE_VIEW("p69_fs_spotlit.view", fs_spotlit_);
+
+#ifdef VERBOSE
+  std::cout << "mz = " << mz << std::endl;
+#endif
+}
+
+
+
+Kernel1::real_matrix_type
+Kernel1::interpolation(complex_matrix_type fs_spotlit, real_vector_type k, 
+  real_vector_type ku0)
+{
+  assert(n_ == fs_spotlit.size(0));
+  assert(m_ == fs_spotlit.size(1));
+  assert(n_ == k.size());
+  assert(m_ == ku0.size(0));
+
+  // 70. (1 by m array of reals) ku0 is transformed into the intermediate 
+  //     (n by m array of reals) kx0 (wn)
+  ku_ = vmmul<row>(ku0, real_matrix_type(n_, m_, T(1)));
+
+  k1_ = vmmul<col>(k, real_matrix_type(n_, m_, T(1)));
+
+  kx0_ = 4 * sq(k1_) - sq(ku_);
+
+  // 71. (n by m array of reals) kx is the Doppler domain range 
+  //     wavenumber (wn)    
+  kx_ = sqrt(max(T(0), kx0_));
+
+  // 72. (scalar, real) minimum wavenum (wn)
+  Index<2> idx;
+  T kx_min = minval(kx_, idx);
+
+  // 73. (scalar, real) maximum wavenum (wn)
+  T kx_max = maxval(kx_, idx);
+
+  // 74. (scalar, real) Nyquist sample spacing in kx domain (wn)
+  T dkx = M_PI / X0_;
+
+  // 75. (scalar, integer) nx0 is the min number of required kx samples 
+  //     (pixels);  (later it will be increased slightly to avoid 
+  //     negative array indexing)
+  index_type nx0 = static_cast<index_type>
+    (2 * ceil((kx_max - kx_min) / (2 * dkx)));   
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
+          (Xc_ * (kx_(i, j) - T(2) * k(i)) + T(0.25*M_PI) + ku_(i, j)));
+    }
+
+  SAVE_VIEW("p76_fs_ref.view", fs_ref_);
+
+  // match filter the spotlighted signal 'fsSpotLit' with the reference's 
+  // complex conjugate 'fsRef' along fast-time and slow-time, to remove 
+  // the reference signal's spectral components.
+
+  // 77. (n by m array of complex nums) Doppler domain matched-filtered signal
+  fsm_ = fs_spotlit * fs_ref_;
+
+  // 78. (scalar, int) interpolation processing sliver size
+  length_type I = 2 * interp_sidelobes_ + 1;
+                            
+  // 79. (scalar, real) +/- interpolation neighborhood size in KX domain
+  T kxs = interp_sidelobes_ * dkx;  
+
+  // 80. (scalar, int) total number of kx samples required in the SAR 
+  //     image's col (in pixels; increased to avoid negative array 
+  //     indexing in interpolation loop)
+  nx_ = nx0 + 2 * interp_sidelobes_ + 4;
+
+  // 81. (scalar, real) range sample spacing 
+  T dx = 2 * M_PI / (nx_ * dkx);             
+
+  // 82. (1 by nx array of reals) range array
+  real_vector_type x(nx_);
+  for (index_type i = 0; i < nx_; ++i)
+    x.put(i, dx * (i - nx_/2));
+
+  // 83. (1 by nx array of reals) uniformly-spaced KX0 points where 
+  //     interpolation is done  
+  real_vector_type KX0(nx_);
+  for (index_type i = 0; i < nx_; ++i)
+    KX0.put(i, kx_min + (T(i) - interp_sidelobes_ - 2.f) * dkx);
+
+  // 84. (scalar, real) carrier frequency in KX domain, where (nx/2+1) 
+  //     is its index number
+  T kxc = KX0.get(nx_ / 2);
+
+  // 85. KX0 (1 by nx array of reals) is expanded to the SAR image's 
+  //     final dims of (nx by m array of reals).
+  real_matrix_type KX(nx_, m_);
+  KX = vmmul<col>(KX0, real_matrix_type(nx_, m_, T(1)));
+
+  // 86a. initialize the F(kx,ku) array
+  complex_matrix_type F(nx_, m_, complex<T>(0));
+
+  // 86b. begin the range loop
+  for (index_type i = 0; i < n_; ++i)
+  {
+
+    // 87. (1 by m array of ints) icKX are the indices of the closest 
+    //     cross-range sliver in the KX domain
+    for (index_type j = 0; j < m_; ++j)
+      icKX_(j) = static_cast<index_type>(
+        ((kx_.get(i, j) - KX.get(0, 0)) / dkx) + 0.5f);
+
+    // 88. (I by m array of ints) ikx are the indices of the slice that 
+    //     include the cross-range sliver at its center
+    Matrix<index_type> ikxrows(I, m_);
+    Matrix<index_type> ikxcols(I, m_);
+    real_matrix_type nKX(I, m_);
+    real_matrix_type SINC(I, m_);
+    real_matrix_type HAM(I, m_);
+
+    for (index_type h = 0; h < I; ++h)
+      for (index_type j = 0; j < m_; ++j)
+      {
+        ikxrows.put(h, j, icKX_.get(j) + (h - interp_sidelobes_));
+        ikxcols.put(h, j, j);
+
+        // 89. (I by m array of reals) nKX are the signal values 
+        //     of the corresponding slice
+        nKX.put(h, j, KX.get(ikxrows.get(h, j), ikxcols.get(h, j)));
+
+        // 90. (I by m array of reals) SINC is the interpolating window 
+        //     (note not stand-alone sinc coefficients)
+        T sx = M_PI * (nKX.get(h, j) - kx_.get(i, j)) / dkx;
+        SINC.put(h, j, (sx ? sin(sx) / sx : 1));
+
+        // reduce interpolation computational costs by using a tapered 
+        // window
+    
+        // 91. (I by m array of reals) (not stand-alone Hamming 
+        //     coefficients)
+        HAM.put(h, j, 0.54 + 0.46 * cos((M_PI / kxs) * 
+                  (nKX.get(h, j) - kx_.get(i, j))));
+
+        // sinc convolution interpolation of the signal's Doppler 
+        // spectrum, from polar to rectangular coordinates 
+    
+        // 92. (nx by m array of complex nums) F is the rectangular signal 
+        //     spectrum
+        F.put(ikxrows.get(h, j), ikxcols.get(h, j), 
+          F.get(ikxrows.get(h, j), ikxcols.get(h, j)) + 
+          (fsm_.get(i, j) * SINC.get(h, j) * HAM.get(h, j)));
+      }
+
+  } // 93. end the range loop
+
+  SAVE_VIEW("p92_F.view", F);
+
+
+  // transform from the Doppler domain image into a spatial domain image
+
+  // 94. (nx by m array of complex nums) spatial image (complex pixel 
+  //     intensities) 
+  typedef Fftm<complex<T>, complex<T>, row, fft_inv> ifftmr_type;
+  ifftmr_type ifftmr(Domain<2>(nx_, m_), T(1./m_));
+
+  typedef Fftm<complex<T>, complex<T>, col, fft_inv> ifftmc_type;
+  ifftmc_type ifftmc(Domain<2>(nx_, m_), T(1./nx_));
+      
+  complex_matrix_type spatial(nx_, m_);
+  spatial = this->fft_shift(ifftmr(ifftmc(this->fft_shift(F))));
+
+#ifdef VERBOSE
+  std::cout << "kx_min = " << kx_min << std::endl;
+  std::cout << "kx_max = " << kx_max << std::endl;
+  std::cout << "kxc = " << kxc << std::endl;
+  std::cout << "dkx = " << dkx << std::endl;
+  std::cout << "nx0 = " << nx0 << std::endl;
+  std::cout << "nx = " << nx_ << std::endl;
+  std::cout << "dx = " << dx << std::endl;
+  std::cout << "kxc = " << kxc << std::endl;
+#endif
+
+  // for viewing, transpose spatial's magnitude 
+  // 95. (m by nx array of reals) image (pixel intensities)
+  real_matrix_type image(m_, nx_);
+  image = mag(spatial.transpose());
+
+  save_view("image2.view", image);  
+
+  return image;
+}
+
+
+
+Kernel1::complex_matrix_type
+Kernel1::fft_shift(complex_matrix_type in)
+{
+  // This function swaps quadrants of a matrix (both dimensions
+  // must be even) as follows:
+  //
+  //  | 1  2 |            | 4  3 |
+  //  | 3  4 |   becomes  | 1  2 |
+
+  length_type nx = in.size(0);
+  length_type ny = in.size(1);
+  assert( !(nx & 1) );
+  assert( !(ny & 1) );
+
+  complex_matrix_type out(nx, ny);
+  for (index_type i = 0; i < nx; ++i) 
+    for (index_type j = 0; j < ny; ++j) 
+      out.put(i, j, in.get((i + nx/2) % nx, (j + ny/2) % ny));
+
+  return out;
+}
+
+Kernel1::real_vector_type
+Kernel1::fft_shift(real_vector_type in)
+{
+  // This function swaps halves of a vector (dimension
+  // must be even).
+
+  length_type nx = in.size(0);
+  assert( !(nx & 1) );
+
+  real_vector_type out(nx);
+  for (index_type i = 0; i < nx; ++i) 
+    out.put(i, in.get((i + nx/2) % nx));
+
+  return out;
+}
Index: apps/ssar/viewtoraw.cpp
===================================================================
--- apps/ssar/viewtoraw.cpp	(revision 0)
+++ apps/ssar/viewtoraw.cpp	(revision 0)
@@ -0,0 +1,121 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    viewtoraw.cpp
+    @author  Don McCoy
+    @date    2006-10-28
+    @brief   Utility to convert VSIPL++ views to raw greyscale
+*/
+
+#include <iostream>
+#include <stdlib.h>
+
+#include <vsip/initfin.hpp>
+#include <vsip/math.hpp>
+
+#include <vsip_csl/load_view.hpp>
+#include <vsip_csl/save_view.hpp>
+
+
+using namespace vsip;
+using namespace vsip_csl;
+using namespace std;
+
+
+enum data_format_type
+{
+  COMPLEX_MAG = 0,
+  COMPLEX_REAL,
+  COMPLEX_IMAG,
+  SCALAR_FLOAT,
+  SCALAR_INTEGER
+};
+
+void convert_to_greyscale(data_format_type format, 
+  char const* infile, char const* outfile, length_type rows, length_type cols);
+
+
+int
+main(int argc, char** argv)
+{
+  vsip::vsipl init(argc, argv);
+
+  if (argc < 5 || argc > 6)
+  {
+    fprintf(stderr, "Usage: %s [-risn] <input> <output> <rows> <cols>\n", 
+      argv[0]);
+    return -1;
+  }
+  else
+  {
+    // The default is to create the image using both the real and imaginary 
+    // parts by computing the magnitude.  Alternatively, the real or 
+    // imaginary parts (-r or -i respectively) may be used individually, 
+    // or, if the data is already scalar, it MUST be either single-precision 
+    // floating point or integer format (-s or -n must be used to indicate 
+    // which).
+    data_format_type format = COMPLEX_MAG;
+    if (argc == 6)
+    {
+      if (0 == strncmp("-r", argv[1], 2))
+        format = COMPLEX_REAL;
+      else if (0 == strncmp("-i", argv[1], 2))
+        format = COMPLEX_IMAG;
+      else if (0 == strncmp("-s", argv[1], 2))
+        format = SCALAR_FLOAT;
+      else if (0 == strncmp("-n", argv[1], 2))
+        format = SCALAR_INTEGER;
+      ++argv;
+      --argc;
+    }
+    convert_to_greyscale(format, argv[1], argv[2], atoi(argv[3]), 
+      atoi(argv[4]));
+  }
+
+  return 0;
+}
+
+
+
+void
+convert_to_greyscale(data_format_type format, 
+  char const* infile, char const* outfile, length_type rows, length_type cols)
+{
+  typedef Matrix<scalar_f> matrix_type;
+  Domain<2> dom(rows, cols);
+
+  matrix_type in(rows, cols);
+
+  if (format == COMPLEX_MAG)
+    in = mag(Load_view<2, cscalar_f>(infile, dom).view());
+  else if (format == COMPLEX_REAL)
+    in = real(Load_view<2, cscalar_f>(infile, dom).view());
+  else if (format == COMPLEX_IMAG)
+    in = imag(Load_view<2, cscalar_f>(infile, dom).view());
+  else if (format == SCALAR_FLOAT)
+    in = Load_view<2, scalar_f>(infile, dom).view();
+  else if (format == SCALAR_INTEGER)
+    in = Load_view<2, scalar_i>(infile, dom).view();
+  else
+    cerr << "Error: format type " << format << " not supported." << endl;
+
+
+  Index<2> idx;
+  scalar_f minv = minval(in, idx);
+  scalar_f maxv = maxval(in, idx);
+  scalar_f scale = (maxv - minv ? maxv - minv : 1.f);
+
+  Matrix<scalar_f> outf(rows, cols);
+  outf = (in - minv) * 255.f / scale;
+
+  Matrix<char> out(rows, cols);
+  for (index_type i = 0; i < rows; ++i)
+    for (index_type j = 0; j < cols; ++j)
+      out.put(i, j, static_cast<char>(outf.get(i, j)));
+
+  save_view(const_cast<char *>(outfile), out);
+
+  // The min and max values are displayed to reveal the scale
+  cout << infile << " [" << rows << " x " << cols << "] : "
+       << "min " << minv << ", max " << maxv << endl;
+}
+
Index: apps/ssar/ssar.cpp
===================================================================
--- apps/ssar/ssar.cpp	(revision 0)
+++ apps/ssar/ssar.cpp	(revision 0)
@@ -0,0 +1,93 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    ssar.cpp
+    @author  Don McCoy
+    @date    2006-10-26
+    @brief   VSIPL++ implementation of HPCS Challenge Benchmarks 
+               Scalable Synthetic Compact Applications - 
+             SSCA #3: Sensor Processing and Knowledge Formation
+*/
+
+#include <iostream>
+#include <fstream>
+#include <cerrno>
+
+#include <vsip/initfin.hpp>
+#include <vsip/math.hpp>
+#include <vsip/signal.hpp>
+
+using namespace vsip;
+using namespace std;
+
+#include "kernel1.hpp"
+
+struct
+ssar_options
+{
+  length_type scale;
+  length_type n;
+  length_type mc;
+  length_type m;
+};
+
+void
+process_ssar_options(int argc, char** argv, ssar_options& options);
+
+
+int
+main(int argc, char** argv)
+{
+  vsip::vsipl init(argc, argv);
+
+  ssar_options opt;
+  process_ssar_options(argc, argv, opt);
+
+
+  // Setup for Stage 1, Kernel 1 
+  Kernel1 k1(opt.scale, opt.n, opt.mc, opt.m); 
+
+  // Process an image at a time.  
+  //
+  // This step includes a Data I/O component, where the raw data is 
+  // retrieved from disk, as well as a Computation component, where 
+  // the image is resolved from the incoming radar data.
+  k1.process_image();
+}
+
+
+void
+process_ssar_options(int argc, char** argv, ssar_options& options)
+{
+  if (argc != 2)
+  {
+    cerr << "Usage: " << argv[0] << " <data dir>" << endl;
+    exit(-1);
+  }
+
+  if (chdir(argv[1]) < 0)
+  {
+    perror(argv[1]);
+    exit(-1);
+  }
+
+  ifstream fp_in(SAR_DIMENSIONS);
+  if (fp_in.fail())
+  {
+    perror(SAR_DIMENSIONS);
+    exit(-1);
+  }
+
+  fp_in >> options.scale;
+  fp_in >> options.n;
+  fp_in >> options.mc;
+  fp_in >> options.m;
+
+  if (fp_in.fail())
+  {
+    cerr << "Error reading dimension data" << endl;
+    exit(-1);
+  }
+
+  fp_in.close();
+}
+
Index: apps/ssar/set1/uc.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/set1/uc.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/set1/ftfilt.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/set1/ftfilt.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/set1/k.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/set1/k.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/set1/ref_image.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/set1/ref_image.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/set1/ku.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/set1/ku.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/set1/dims.txt
===================================================================
--- apps/ssar/set1/dims.txt	(revision 0)
+++ apps/ssar/set1/dims.txt	(revision 0)
@@ -0,0 +1,4 @@
+3
+1072
+480
+1144
Index: apps/ssar/set1/u.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/set1/u.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/set1/sar.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/set1/sar.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/Makefile
===================================================================
--- apps/ssar/Makefile	(revision 0)
+++ apps/ssar/Makefile	(revision 0)
@@ -0,0 +1,74 @@
+########################################################################
+#
+# File:   apps/ssar/Makefile
+# Author: Don McCoy
+# Date:   2006-10-28
+#
+# Contents: Makefile for Scalable SAR (SSAR) benchmark program.
+#
+########################################################################
+
+########################################################################
+# Variables
+########################################################################
+
+# This should point to the directory where Sourcery VSIPL++ is installed.
+prefix = /usr/local
+
+# This selects the desired library, which will vary depending on the
+# platform.  Append '-debug' for building a version suitable for 
+# debugging or omit to use the optimized version.  Consult the
+# /usr/local/lib/pkgconfig/ directory for a complete list of packages.
+suffix = -ser-builtin-32
+
+pkgcommand := PKG_CONFIG_PATH=$(prefix)/lib/pkgconfig 	\
+                     pkg-config vsipl++$(suffix) 	\
+                     --define-variable=prefix=$(prefix)
+
+CXX      = $(shell ${pkgcommand} --variable=cxx)
+CXXFLAGS = $(shell ${pkgcommand} --cflags) \
+	   $(shell ${pkgcommand} --variable=cxxflags) \
+	   -DVSIP_IMPL_PROFILER=15
+LIBS     = $(shell ${pkgcommand} --libs)
+ 
+
+########################################################################
+# Rules
+########################################################################
+
+all: ssar viewtoraw diffview
+
+clean: 
+	rm *.o
+	rm ssar
+	rm viewtoraw
+	rm diffview
+
+check: all
+	@echo "Running SSAR application..."
+	./ssar set1
+	@echo
+	@echo "Comparing output to reference view (should be less than -100)"
+	./diffview -r set1/image.view set1/ref_image.view 756 1144
+	@echo
+	@echo "Creating viewable image of output"
+	./viewtoraw -s set1/image.view set1/image.raw 1144 756
+	rawtopgm 756 1144 set1/image.raw > set1/image.pgm
+	rm set1/image.raw
+	@echo
+	@echo "Creating viewable image of reference view"
+	./viewtoraw -s set1/ref_image.view set1/ref_image.raw 1144 756
+	rawtopgm 756 1144 set1/ref_image.raw > set1/ref_image.pgm
+	rm set1/ref_image.raw
+
+
+ssar.o: ssar.cpp kernel1.hpp load_save.hpp
+
+ssar: ssar.o
+	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
+
+viewtoraw: viewtoraw.o
+	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
+
+diffview: diffview.o
+	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
