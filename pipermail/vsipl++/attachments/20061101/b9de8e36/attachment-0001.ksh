Index: src/vsip_csl/matlab_utils.hpp
===================================================================
--- src/vsip_csl/matlab_utils.hpp	(revision 0)
+++ src/vsip_csl/matlab_utils.hpp	(revision 0)
@@ -0,0 +1,161 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    matlab_utils.hpp
+    @author  Don McCoy
+    @date    2006-10-31
+    @brief   VSIPL++ CodeSourcery Library: Matlab-like utility functions.
+*/
+
+#ifndef VSIP_CSL_MATLAB_UTILS_HPP
+#define VSIP_CSL_MATLAB_UTILS_HPP
+
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+
+
+namespace vsip_csl
+{
+
+namespace matlab
+{
+  
+
+template <typename T1,
+          typename T2,
+          typename Block1,
+          typename Block2>
+Vector<T2, Block2>
+fftshift(
+  const_Vector<T1, Block1> in, Vector<T2, Block2> out)
+{
+  // This function swaps halves of a vector (dimension
+  // must be even).
+
+  length_type nx = in.size(0);
+  assert(!(nx & 1));
+  assert(nx == out.size(0));
+
+  Domain<1> left(0, 1, nx/2);
+  Domain<1> right(nx/2, 1, nx/2);
+
+  out(left) = in(right);
+  out(right) = in(left);
+
+  return out;
+}
+
+
+template <typename T1,
+	  typename T2,
+	  typename Block1,
+	  typename Block2>
+Matrix<T2, Block2>
+fftshift(
+  const_Matrix<T1, Block1> in, Matrix<T2, Block2> out)
+{
+  // This function swaps quadrants of a matrix (both dimensions
+  // must be even) as follows:
+  //
+  //  | 1  2 |            | 4  3 |
+  //  | 3  4 |   becomes  | 1  2 |
+
+  length_type nx = in.size(0);
+  length_type ny = in.size(1);
+  assert(!(nx & 1));
+  assert(!(ny & 1));
+  assert(nx == out.size(0));
+  assert(ny == out.size(1));
+
+  Domain<1> left(0, 1, nx/2);
+  Domain<1> right(nx/2, 1, nx/2);
+  Domain<1> upper(0, 1, ny/2);
+  Domain<1> lower(ny/2, 1, ny/2);
+
+  Domain<2> dom1(left, upper);
+  Domain<2> dom2(right, upper);
+  Domain<2> dom3(left, lower);
+  Domain<2> dom4(right, lower);
+
+  out(dom1) = in(dom4);
+  out(dom2) = in(dom3);
+  out(dom3) = in(dom2);
+  out(dom4) = in(dom1);
+
+  return out;
+}
+
+
+// The following versions are not as efficient as those above due
+// to the overhead of creating a new view.  For optimized code,
+// use the ones above.
+
+template <typename T1,
+          typename Block1>
+Vector<T1, Block1>
+fftshift(
+  const_Vector<T1, Block1> in)
+{
+  // This function swaps halves of a vector (dimension
+  // must be even).
+
+  length_type nx = in.size(0);
+  assert(!(nx & 1));
+  assert(nx == out.size(0));
+
+  Domain<1> left(0, 1, nx/2);
+  Domain<1> right(nx/2, 1, nx/2);
+
+  Vector<T1, Block1> out(nx);
+  out(left) = in(right);
+  out(right) = in(left);
+
+  return out;
+}
+
+
+template <typename T1,
+	  typename Block1>
+Matrix<T1, Block1>
+fftshift(
+  const_Matrix<T1, Block1> in)
+{
+  // This function swaps quadrants of a matrix (both dimensions
+  // must be even) as follows:
+  //
+  //  | 1  2 |            | 4  3 |
+  //  | 3  4 |   becomes  | 1  2 |
+
+  length_type nx = in.size(0);
+  length_type ny = in.size(1);
+  assert(!(nx & 1));
+  assert(!(ny & 1));
+  assert(nx == out.size(0));
+  assert(ny == out.size(1));
+
+  Domain<1> left(0, 1, nx/2);
+  Domain<1> right(nx/2, 1, nx/2);
+  Domain<1> upper(0, 1, ny/2);
+  Domain<1> lower(ny/2, 1, ny/2);
+
+  Domain<2> dom1(left, upper);
+  Domain<2> dom2(right, upper);
+  Domain<2> dom3(left, lower);
+  Domain<2> dom4(right, lower);
+
+  Matrix<T1, Block1> out(nx, ny);
+  out(dom1) = in(dom4);
+  out(dom2) = in(dom3);
+  out(dom3) = in(dom2);
+  out(dom4) = in(dom1);
+
+  return out;
+}
+
+
+
+
+} // namesapce matlab
+
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_MATLAB_UTILS_HPP
Index: apps/ssar/load_save.hpp
===================================================================
--- apps/ssar/load_save.hpp	(revision 153717)
+++ apps/ssar/load_save.hpp	(working copy)
@@ -26,9 +26,8 @@
   for (index_type i = 0; i < view.size(0); ++i)
     for (index_type j = 0; j < view.size(1); ++j)
       sp_view.put(i, j, static_cast<complex<float> >(view.get(i, j)));
-  
-  vsip_csl::Save_view<2, complex<float> >::save(const_cast<char*>(filename), 
-    sp_view);
+
+  vsip_csl::save_view(filename, sp_view);
 }
 
 template <typename Block>
@@ -43,7 +42,7 @@
     for (index_type j = 0; j < view.size(1); ++j)
       sp_view.put(i, j, static_cast<float>(view.get(i, j)));
   
-  vsip_csl::Save_view<2, float>::save(const_cast<char *>(filename), sp_view);
+  vsip_csl::save_view(filename, sp_view);
 }
 
 template <typename Block>
@@ -57,7 +56,7 @@
   for (index_type i = 0; i < view.size(0); ++i)
     sp_view.put(i, static_cast<float>(view.get(i)));
   
-  vsip_csl::Save_view<1, float>::save(const_cast<char *>(filename), sp_view);
+  vsip_csl::save_view(filename, sp_view);
 }
 
 
Index: apps/ssar/diffview.cpp
===================================================================
--- apps/ssar/diffview.cpp	(revision 153717)
+++ apps/ssar/diffview.cpp	(working copy)
@@ -29,8 +29,10 @@
   INTEGER_VIEW
 };
 
-void compare(data_format_type format, 
-  char const* infile, char const* ref, length_type rows, length_type cols);
+template <typename T>
+void 
+compare(char const* infile, char const* ref, length_type rows, 
+  length_type cols);
 
 int
 main(int argc, char** argv)
@@ -39,8 +41,8 @@
 
   if (argc < 5 || argc > 6)
   {
-    fprintf(stderr, "Usage: %s [-rn] <input> <reference> <rows> <cols>\n", 
-      argv[0]);
+    cerr << "Usage: " << argv[0] 
+         << " [-crn] <input> <reference> <rows> <cols>" << endl;
     return -1;
   }
   else
@@ -48,63 +50,49 @@
     data_format_type format = COMPLEX_VIEW;
     if (argc == 6)
     {
-      if (0 == strncmp("-r", argv[1], 2))
+      if (0 == strncmp("-c", argv[1], 2))
+        format = COMPLEX_VIEW;
+      else if (0 == strncmp("-r", argv[1], 2))
         format = REAL_VIEW;
       else if (0 == strncmp("-n", argv[1], 2))
         format = INTEGER_VIEW;
-      argv++;
+      else
+      {
+        cerr << "Usage: " << argv[0] 
+             << " [-crn] <input> <reference> <rows> <cols>" << endl;
+        return -1;
+      }
+      ++argv;
+      --argc;
     }
 
-    compare(format, argv[1], argv[2], atoi(argv[3]), atoi(argv[4]));
+    if (format == REAL_VIEW)
+      compare<float>(argv[1], argv[2], atoi(argv[3]), atoi(argv[4]));
+    else if (format == INTEGER_VIEW)
+      compare<int>(argv[1], argv[2], atoi(argv[3]), atoi(argv[4]));
+    else
+      compare<complex<float> >(argv[1], argv[2], atoi(argv[3]), atoi(argv[4])); 
+
   }
 
   return 0;
 }
 
 
-
+template <typename T>
 void
-compare(data_format_type format, 
-  char const* infile, char const* ref, length_type rows, length_type cols)
+compare(char const* infile, char const* ref, length_type rows, 
+  length_type cols)
 {
-  if (format == REAL_VIEW)
-  {
-    typedef Matrix<scalar_f> matrix_type;
-    Domain<2> dom(rows, cols);
+  typedef Matrix<T> matrix_type;
+  Domain<2> dom(rows, cols);
 
-    matrix_type in(rows, cols);
-    in = Load_view<2, scalar_f>(infile, dom).view();
+  matrix_type in(rows, cols);
+  in = Load_view<2, T>(infile, dom).view();
 
-    matrix_type refv(rows, cols);
-    refv = Load_view<2, scalar_f>(ref, dom).view();
+  matrix_type refv(rows, cols);
+  refv = Load_view<2, T>(ref, dom).view();
 
-    cout << error_db(in, refv) << endl;
-  }
-  else if (format == INTEGER_VIEW)
-  {
-    typedef Matrix<scalar_i> matrix_type;
-    Domain<2> dom(rows, cols);
-
-    matrix_type in(rows, cols);
-    in = Load_view<2, scalar_i>(infile, dom).view();
-
-    matrix_type refv(rows, cols);
-    refv = Load_view<2, scalar_i>(ref, dom).view();
-
-    cout << error_db(in, refv) << endl;
-  }
-  else          // Using complex views.
-  {
-    typedef Matrix<cscalar_f> matrix_type;
-    Domain<2> dom(rows, cols);
-
-    matrix_type in(rows, cols);
-    in = Load_view<2, cscalar_f>(infile, dom).view();
-
-    matrix_type refv(rows, cols);
-    refv = Load_view<2, cscalar_f>(ref, dom).view();
-
-    cout << error_db(in, refv) << endl;
-  }
+  cout << error_db(in, refv) << endl;
 }
 
Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 153717)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -6,11 +6,13 @@
     @brief   VSIPL++ implementation of SSCA #3: Kernel 1, Image Formation
 */
 
-#include <vsip/impl/profile.hpp>
+#include <vsip/opt/profile.hpp>
 
+#include <vsip_csl/matlab_utils.hpp>
+
 #include "load_save.hpp"
 
-#if 0
+#if 1
 #define VERBOSE
 #define SAVE_VIEW(a, b)    save_view(a, b)
 #else
@@ -50,12 +52,6 @@
   real_matrix_type
   interpolation(void);
 
-  complex_matrix_type
-  fft_shift(complex_matrix_type in);
-
-  real_vector_type
-  fft_shift(real_vector_type in);
-
 private:
   length_type scale_;
   length_type n_;
@@ -225,15 +221,16 @@
   // (spatial frequency) domain.  
 
   // 59. (n by mc array of complex numbers) filtered echoed signal
-  s_filt_ = vmmul<col>(fast_time_filter_, col_fftm_(this->fft_shift(s_raw_)));
+  s_filt_ = vmmul<col>(fast_time_filter_, 
+    col_fftm_(vsip_csl::matlab::fftshift(s_raw_, s_filt_)));
 
-  SAVE_VIEW("p59_s_filt.view", this->fft_shift(s_filt_));
+  SAVE_VIEW("p59_s_filt.view", vsip_csl::matlab::fftshift(s_filt_));
 
   // 60. (1 by n array of reals) fftshifted slow-time wavenumber
-  ks_ = this->fft_shift(k_);
+  vsip_csl::matlab::fftshift(k_, ks_);
 
   // 61. (1 by mc array of reals) fftshifted slow-time synthetic aperture
-  ucs_ = this->fft_shift(uc_);
+  vsip_csl::matlab::fftshift(uc_, ucs_);
 
   // 62. (n by mc array of complex numbers) signal compressed along 
   //     slow-time (note that to view 'sCompr' it will need to be 
@@ -245,7 +242,7 @@
         exp(complex<T>(0, 2) * ks_(i) * (sqrt(sq(Xc_) + sq(ucs_(j))) - Xc_)));
     }
 
-  SAVE_VIEW("p62_s_compr.view", this->fft_shift(s_compr_));
+  SAVE_VIEW("p62_s_compr.view", vsip_csl::matlab::fftshift(s_compr_));
 
   // 63. (n by mc array of complex numbers) narrow-bandwidth polar format
   //     reconstruction along slow-time
@@ -267,14 +264,14 @@
     for (index_type j = mc_ / 2; j < mc_; ++j)
         fs_padded_.put(i, j + mz, m_scale * fs_.get(i, j));
   }
-  SAVE_VIEW("p65_fs_padded.view", this->fft_shift(fs_padded_));
+  SAVE_VIEW("p65_fs_padded.view", vsip_csl::matlab::fftshift(fs_padded_));
 
   // 66. (n by m array of complex numbers) transform-back the zero 
   // padded spatial spectrum along its cross-range
   s_padded_ = ifftm_(fs_padded_);
 
   // 67. (1 by m array of reals) shifted u
-  us_ = this->fft_shift(u_);
+  vsip_csl::matlab::fftshift(u_, us_);
 
   // 68. (n by m array of complex numbers) slow-time decompression (note 
   //     that to view 'sDecompr' it will need to be fftshifted first.)
@@ -285,11 +282,11 @@
         exp( complex<T>(0, 2) * ks_(i) * (Xc_ - sqrt(sq(Xc_) + sq(us_(j)))) ));
     }
 
-  SAVE_VIEW("p68_s_decompr.view", this->fft_shift(s_decompr_));
+  SAVE_VIEW("p68_s_decompr.view", vsip_csl::matlab::fftshift(s_decompr_));
 
   // 69. (n by m array of complex numbers) digitally-spotlighted SAR 
   //     signal spectrum
-  fs_spotlit_ = this->fft_shift(row_fftm2_(s_decompr_));
+  vsip_csl::matlab::fftshift(row_fftm2_(s_decompr_), fs_spotlit_);
 
   SAVE_VIEW("p69_fs_spotlit.view", fs_spotlit_);
 
@@ -459,8 +456,11 @@
   typedef Fftm<complex<T>, complex<T>, col, fft_inv> ifftmc_type;
   ifftmc_type ifftmc(Domain<2>(nx_, m_), T(1./nx_));
       
+  complex_matrix_type F_shifted(nx_, m_);
+  vsip_csl::matlab::fftshift(F, F_shifted);
+
   complex_matrix_type spatial(nx_, m_);
-  spatial = this->fft_shift(ifftmr(ifftmc(this->fft_shift(F))));
+  vsip_csl::matlab::fftshift(ifftmr(ifftmc(F_shifted)), spatial);
 
 #ifdef VERBOSE
   std::cout << "kx_min = " << kx_min << std::endl;
@@ -485,42 +485,3 @@
 
 
 
-template <typename T>
-Matrix<complex<T> >
-Kernel1<T>::fft_shift(complex_matrix_type in)
-{
-  // This function swaps quadrants of a matrix (both dimensions
-  // must be even) as follows:
-  //
-  //  | 1  2 |            | 4  3 |
-  //  | 3  4 |   becomes  | 1  2 |
-
-  length_type nx = in.size(0);
-  length_type ny = in.size(1);
-  assert( !(nx & 1) );
-  assert( !(ny & 1) );
-
-  complex_matrix_type out(nx, ny);
-  for (index_type i = 0; i < nx; ++i) 
-    for (index_type j = 0; j < ny; ++j) 
-      out.put(i, j, in.get((i + nx/2) % nx, (j + ny/2) % ny));
-
-  return out;
-}
-
-template <typename T>
-Vector<T>
-Kernel1<T>::fft_shift(real_vector_type in)
-{
-  // This function swaps halves of a vector (dimension
-  // must be even).
-
-  length_type nx = in.size(0);
-  assert( !(nx & 1) );
-
-  real_vector_type out(nx);
-  for (index_type i = 0; i < nx; ++i) 
-    out.put(i, in.get((i + nx/2) % nx));
-
-  return out;
-}
Index: apps/ssar/viewtoraw.cpp
===================================================================
--- apps/ssar/viewtoraw.cpp	(revision 153717)
+++ apps/ssar/viewtoraw.cpp	(working copy)
@@ -7,7 +7,6 @@
 */
 
 #include <iostream>
-#include <stdlib.h>
 
 #include <vsip/initfin.hpp>
 #include <vsip/math.hpp>
@@ -41,22 +40,24 @@
 
   if (argc < 5 || argc > 6)
   {
-    fprintf(stderr, "Usage: %s [-risn] <input> <output> <rows> <cols>\n", 
-      argv[0]);
+    cerr << "Usage: " << argv[0] 
+         << " [-crisn] <input> <output> <rows> <cols>" << endl;
     return -1;
   }
   else
   {
     // The default is to create the image using both the real and imaginary 
-    // parts by computing the magnitude.  Alternatively, the real or 
-    // imaginary parts (-r or -i respectively) may be used individually, 
-    // or, if the data is already scalar, it MUST be either single-precision 
-    // floating point or integer format (-s or -n must be used to indicate 
-    // which).
+    // parts by computing the magnitude (default, -c).  Alternatively, the 
+    // real or imaginary parts (-r or -i respectively) may be used 
+    // individually, or, if the data is already scalar, it MUST be either 
+    // single-precision floating point or integer format (-s or -n must be 
+    // used to indicate which).
     data_format_type format = COMPLEX_MAG;
     if (argc == 6)
     {
-      if (0 == strncmp("-r", argv[1], 2))
+      if (0 == strncmp("-c", argv[1], 2))
+        format = COMPLEX_MAG;
+      else if (0 == strncmp("-r", argv[1], 2))
         format = COMPLEX_REAL;
       else if (0 == strncmp("-i", argv[1], 2))
         format = COMPLEX_IMAG;
@@ -64,6 +65,12 @@
         format = SCALAR_FLOAT;
       else if (0 == strncmp("-n", argv[1], 2))
         format = SCALAR_INTEGER;
+      else
+      {
+        cerr << "Usage: " << argv[0] 
+             << " [-crisn] <input> <output> <rows> <cols>" << endl;
+        return -1;
+      }
       ++argv;
       --argc;
     }
Index: apps/ssar/Makefile
===================================================================
--- apps/ssar/Makefile	(revision 153717)
+++ apps/ssar/Makefile	(working copy)
@@ -1,74 +0,0 @@
-########################################################################
-#
-# File:   apps/ssar/Makefile
-# Author: Don McCoy
-# Date:   2006-10-28
-#
-# Contents: Makefile for Scalable SAR (SSAR) benchmark program.
-#
-########################################################################
-
-########################################################################
-# Variables
-########################################################################
-
-# This should point to the directory where Sourcery VSIPL++ is installed.
-prefix = /usr/local
-
-# This selects the desired library, which will vary depending on the
-# platform.  Append '-debug' for building a version suitable for 
-# debugging or omit to use the optimized version.  Consult the
-# /usr/local/lib/pkgconfig/ directory for a complete list of packages.
-suffix = -ser-builtin-32
-
-pkgcommand := PKG_CONFIG_PATH=$(prefix)/lib/pkgconfig 	\
-                     pkg-config vsipl++$(suffix) 	\
-                     --define-variable=prefix=$(prefix)
-
-CXX      = $(shell ${pkgcommand} --variable=cxx)
-CXXFLAGS = $(shell ${pkgcommand} --cflags) \
-	   $(shell ${pkgcommand} --variable=cxxflags) \
-	   -DVSIP_IMPL_PROFILER=15
-LIBS     = $(shell ${pkgcommand} --libs)
- 
-
-########################################################################
-# Rules
-########################################################################
-
-all: ssar viewtoraw diffview
-
-clean: 
-	rm *.o
-	rm ssar
-	rm viewtoraw
-	rm diffview
-
-check: all
-	@echo "Running SSAR application..."
-	./ssar set1
-	@echo
-	@echo "Comparing output to reference view (should be less than -100)"
-	./diffview -r set1/image.view set1/ref_image.view 756 1144
-	@echo
-	@echo "Creating viewable image of output"
-	./viewtoraw -s set1/image.view set1/image.raw 1144 756
-	rawtopgm 756 1144 set1/image.raw > set1/image.pgm
-	rm set1/image.raw
-	@echo
-	@echo "Creating viewable image of reference view"
-	./viewtoraw -s set1/ref_image.view set1/ref_image.raw 1144 756
-	rawtopgm 756 1144 set1/ref_image.raw > set1/ref_image.pgm
-	rm set1/ref_image.raw
-
-
-ssar.o: ssar.cpp kernel1.hpp load_save.hpp
-
-ssar: ssar.o
-	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
-
-viewtoraw: viewtoraw.o
-	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
-
-diffview: diffview.o
-	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
