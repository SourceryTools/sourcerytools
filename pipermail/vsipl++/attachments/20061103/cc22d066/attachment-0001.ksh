Index: src/vsip_csl/load_view.hpp
===================================================================
--- src/vsip_csl/load_view.hpp	(revision 153804)
+++ src/vsip_csl/load_view.hpp	(working copy)
@@ -22,6 +22,8 @@
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
 #include <vsip/core/noncopyable.hpp>
+#include <vsip/core/working_view.hpp>
+#include <vsip/opt/view_cast.hpp>
 
 
 
@@ -139,7 +141,36 @@
 }
 
 
+/// Load a view from a file as another type
+///
+/// Requires:
+///   T to be the type on disk.
+///   FILENAME to be filename.
+///   VIEW to be a VSIPL++ view.
 
+template <typename T,
+          typename ViewT>
+void
+load_view_as(
+  char const* filename,
+  ViewT       view)
+{
+  using vsip::impl::View_of_dim;
+
+  typedef
+    typename View_of_dim<ViewT::dim, T, vsip::Dense<ViewT::dim, T> >::type
+    view_type;
+
+  view_type disk_view = vsip::impl::clone_view<view_type>(view);
+
+  load_view(filename, disk_view);
+
+  view = vsip::impl::view_cast<typename ViewT::value_type>(disk_view);
+} 
+
+
+
+
 /// Load values from a file into a VSIPL++ view.
 
 /// Requires
Index: src/vsip_csl/save_view.hpp
===================================================================
--- src/vsip_csl/save_view.hpp	(revision 153804)
+++ src/vsip_csl/save_view.hpp	(working copy)
@@ -17,9 +17,9 @@
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
 #include <vsip/core/adjust_layout.hpp>
+#include <vsip/opt/view_cast.hpp>
 
 
-
 namespace vsip_csl
 {
 
@@ -178,6 +178,35 @@
   }
 }
 
+
+/// Save a view to a file as another type
+///
+/// Requires:
+///   T to be the desired type on disk.
+///   FILENAME to be filename.
+///   VIEW to be a VSIPL++ view.
+
+template <typename T,
+          typename ViewT>
+void
+save_view_as(
+  char* filename,
+  ViewT view)
+{
+  using vsip::impl::View_of_dim;
+
+  typedef
+    typename View_of_dim<ViewT::dim, T, vsip::Dense<ViewT::dim, T> >::type
+    view_type;
+
+  view_type disk_view = vsip::impl::clone_view<view_type>(view);
+
+  disk_view = vsip::impl::view_cast<T>(view);
+    
+  vsip_csl::save_view(filename, disk_view);
+} 
+
+
 } // namespace vsip_csl
 
 #endif // VSIP_CSL_SAVE_VIEW_HPP
Index: apps/ssar/load_save.hpp
===================================================================
--- apps/ssar/load_save.hpp	(revision 153804)
+++ apps/ssar/load_save.hpp	(working copy)
@@ -1,114 +0,0 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
-
-/** @file    load_save.hpp
-    @author  Don McCoy
-    @date    2006-10-26
-    @brief   Extensions to allow type double to be used as the view
-             data type while using float as the storage type on disk.
-*/
-
-#ifndef LOAD_SAVE_HPP
-#define LOAD_SAVE_HPP
-
-#include <vsip_csl/load_view.hpp>
-#include <vsip_csl/save_view.hpp>
-
-
-
-template <typename Block>
-void
-save_view(
-  char const* filename,
-  vsip::const_Matrix<complex<double>, Block> view)
-{
-  vsip::Matrix<complex<float> > sp_view(view.size(0), view.size(1));
-
-  for (index_type i = 0; i < view.size(0); ++i)
-    for (index_type j = 0; j < view.size(1); ++j)
-      sp_view.put(i, j, static_cast<complex<float> >(view.get(i, j)));
-
-  vsip_csl::save_view(filename, sp_view);
-}
-
-template <typename Block>
-void
-save_view(
-  char const* filename,
-  vsip::const_Matrix<double, Block> view)
-{
-  vsip::Matrix<float> sp_view(view.size(0), view.size(1));
-
-  for (index_type i = 0; i < view.size(0); ++i)
-    for (index_type j = 0; j < view.size(1); ++j)
-      sp_view.put(i, j, static_cast<float>(view.get(i, j)));
-  
-  vsip_csl::save_view(filename, sp_view);
-}
-
-template <typename Block>
-void
-save_view(
-  char const* filename,
-  vsip::const_Vector<double, Block> view)
-{
-  vsip::Vector<float> sp_view(view.size(0));
-
-  for (index_type i = 0; i < view.size(0); ++i)
-    sp_view.put(i, static_cast<float>(view.get(i)));
-  
-  vsip_csl::save_view(filename, sp_view);
-}
-
-
-vsip::Matrix<complex<double> >
-load_view(
-  char const* filename,
-  vsip::Domain<2> const& dom)
-{
-  vsip::Matrix<complex<float> > sp_view(dom[0].size(), dom[1].size());
-  sp_view = vsip_csl::Load_view<2, complex<float> >(filename, dom).view();
-
-  vsip::Matrix<complex<double> > view(dom[0].size(), dom[1].size());
-
-  for (index_type i = 0; i < dom[0].size(); ++i)
-    for (index_type j = 0; j < dom[1].size(); ++j)
-      view.put(i, j, static_cast<complex<double> >(sp_view.get(i, j)));
-
-  return view;
-}
-
-vsip::Vector<double>
-load_view(
-  char const* filename,
-  vsip::Domain<1> const& dom, 
-  double)
-{
-  vsip::Vector<float> sp_view(dom[0].size());
-  sp_view = vsip_csl::Load_view<1, float>(filename, dom).view();
-
-  vsip::Vector<double> view(dom[0].size());
-
-  for (index_type i = 0; i < dom[0].size(); ++i)
-    view.put(i, static_cast<double>(sp_view.get(i)));
-
-  return view;
-}
-
-vsip::Vector<complex<double> >
-load_view(
-  char const* filename,
-  vsip::Domain<1> const& dom, 
-  complex<double>)
-{
-  vsip::Vector<complex<float> > sp_view(dom[0].size());
-  sp_view = vsip_csl::Load_view<1, complex<float> >(filename, dom).view();
-
-  vsip::Vector<complex<double> > view(dom[0].size());
-
-  for (index_type i = 0; i < dom[0].size(); ++i)
-    view.put(i, static_cast<complex<double> >(sp_view.get(i)));
-
-  return view;
-}
-
-#endif // LOAD_SAVE_HPP
Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 153804)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -9,12 +9,12 @@
 #include <vsip/opt/profile.hpp>
 
 #include <vsip_csl/matlab_utils.hpp>
+#include <vsip_csl/save_view.hpp>
+#include <vsip_csl/load_view.hpp>
 
-#include "load_save.hpp"
-
 #if 1
 #define VERBOSE
-#define SAVE_VIEW(a, b)    save_view(a, b)
+#define SAVE_VIEW(a, b)    vsip_csl::save_view_as<complex<float> >(a, b)
 #else
 #define SAVE_VIEW(a, b)
 #endif
@@ -173,20 +173,19 @@
 void
 Kernel1<T>::process_image()
 {
+  using vsip_csl::load_view_as;
+
   // Load the raw radar image data
-  s_raw_ = load_view(RAW_SAR_DATA, Domain<2>(n_, mc_));
+  load_view_as<complex<float>, complex_matrix_type>(RAW_SAR_DATA, s_raw_);
 
   // Load scale-dependent processing parameters.
-  fast_time_filter_ = 
-    load_view(FAST_TIME_FILTER, Domain<1>(n_), complex<T>());
-  k_ = 
-    load_view(SLOW_TIME_WAVENUMBER, Domain<1>(n_), T());
-  uc_ = 
-    load_view(SLOW_TIME_COMPRESSED_APERTURE_POSITION, Domain<1>(mc_), T());
-  u_ = 
-    load_view(SLOW_TIME_APERTURE_POSITION, Domain<1>(m_), T());
-  ku0_ = 
-    load_view(SLOW_TIME_SPATIAL_FREQUENCY, Domain<1>(m_), T());
+  load_view_as<complex<float>, complex_vector_type>
+    (FAST_TIME_FILTER, fast_time_filter_);
+  load_view_as<float, real_vector_type>(SLOW_TIME_WAVENUMBER, k_);
+  load_view_as<float, real_vector_type>
+    (SLOW_TIME_COMPRESSED_APERTURE_POSITION, uc_);
+  load_view_as<float, real_vector_type>(SLOW_TIME_APERTURE_POSITION, u_);
+  load_view_as<float, real_vector_type>(SLOW_TIME_SPATIAL_FREQUENCY, ku0_);
 
   // Time the remainder of this function, provided profiling is enabled 
   // (pass '--vsipl++-profile-mode=[accum|trace]' on the command line).  
@@ -204,7 +203,7 @@
   real_matrix_type image(this->interpolation());
 
   // Store the image on disk for later processing.
-  save_view("image.view", image);  
+  vsip_csl::save_view_as<float>("image.view", image); 
 }
 
 
@@ -477,12 +476,7 @@
 
   // for viewing, transpose spatial's magnitude 
   // 95. (m by nx array of reals) image (pixel intensities)
-  real_matrix_type image(m_, nx_);
-  image = mag(spatial.transpose());
-
-  save_view("image2.view", image);  
-
-  return image;
+  return mag(spatial.transpose());
 }
 
 
Index: apps/ssar/GNUmakefile
===================================================================
--- apps/ssar/GNUmakefile	(revision 153804)
+++ apps/ssar/GNUmakefile	(working copy)
@@ -62,7 +62,7 @@
 	rm set1/ref_image.raw
 
 
-ssar.o: ssar.cpp kernel1.hpp load_save.hpp
+ssar.o: ssar.cpp kernel1.hpp
 
 ssar: ssar.o
 	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
Index: apps/ssar/viewtoraw.cpp
===================================================================
--- apps/ssar/viewtoraw.cpp	(revision 153804)
+++ apps/ssar/viewtoraw.cpp	(working copy)
@@ -9,8 +9,11 @@
 #include <iostream>
 
 #include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
 #include <vsip/math.hpp>
 
+#include <vsip/opt/view_cast.hpp>
+
 #include <vsip_csl/load_view.hpp>
 #include <vsip_csl/save_view.hpp>
 
@@ -111,13 +114,8 @@
   scalar_f maxv = maxval(in, idx);
   scalar_f scale = (maxv - minv ? maxv - minv : 1.f);
 
-  Matrix<scalar_f> outf(rows, cols);
-  outf = (in - minv) * 255.f / scale;
-
   Matrix<char> out(rows, cols);
-  for (index_type i = 0; i < rows; ++i)
-    for (index_type j = 0; j < cols; ++j)
-      out.put(i, j, static_cast<char>(outf.get(i, j)));
+  out = impl::view_cast<unsigned char>((in - minv) * 255.f / scale);
 
   save_view(const_cast<char *>(outfile), out);
 
