Index: ChangeLog
===================================================================
--- ChangeLog	(revision 211343)
+++ ChangeLog	(working copy)
@@ -1,5 +1,12 @@
 2008-06-10  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/fftw3/fft.cpp: Check VSIP_IMPL_FFTW3_HAVE_{*} with
+	  ifdef.
+	* src/vsip/opt/fftw3/fft.hpp: Likewise.
+	* src/vsip/opt/fftw3/fftw_support.hpp: Likewise.
+	
+2008-06-10  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/core/block_traits.hpp (is_same_block): New function to
 	  compare block pointers.
 	* src/vsip/core/signal/freqswap.hpp: Use is_same_block to compare
Index: src/vsip/opt/fftw3/fft.cpp
===================================================================
--- src/vsip/opt/fftw3/fft.cpp	(revision 211341)
+++ src/vsip/opt/fftw3/fft.cpp	(working copy)
@@ -51,21 +51,21 @@
 } // namespace vsip::impl
 } // namespace vsip
 
-#if VSIP_IMPL_FFTW3_HAVE_FLOAT
+#ifdef VSIP_IMPL_FFTW3_HAVE_FLOAT
 #  define FFTW(fun) fftwf_##fun
 #  define SCALAR_TYPE float
 #  include "fft_impl.cpp"
 #  undef SCALAR_TYPE
 #  undef FFTW
 #endif
-#if VSIP_IMPL_FFTW3_HAVE_DOUBLE
+#ifdef VSIP_IMPL_FFTW3_HAVE_DOUBLE
 #  define FFTW(fun) fftw_##fun
 #  define SCALAR_TYPE double
 #  include "fft_impl.cpp"
 #  undef SCALAR_TYPE
 #  undef FFTW
 #endif
-#if VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE
+#ifdef VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE
 #  define FFTW(fun) fftwl_##fun
 #  define SCALAR_TYPE long double
 #  include "fft_impl.cpp"
Index: src/vsip/opt/fftw3/fft.hpp
===================================================================
--- src/vsip/opt/fftw3/fft.hpp	(revision 211341)
+++ src/vsip/opt/fftw3/fft.hpp	(working copy)
@@ -72,13 +72,13 @@
 VSIP_IMPL_FFT_DECL(3, std::complex<T>, std::complex<T>, 1, 1)  \
 VSIP_IMPL_FFT_DECL(3, std::complex<T>, std::complex<T>, 2, 1)
 
-#if VSIP_IMPL_FFTW3_HAVE_FLOAT
+#ifdef VSIP_IMPL_FFTW3_HAVE_FLOAT
 VSIP_IMPL_FFT_DECL_T(float)
 #endif
-#if VSIP_IMPL_FFTW3_HAVE_DOUBLE
+#ifdef VSIP_IMPL_FFTW3_HAVE_DOUBLE
 VSIP_IMPL_FFT_DECL_T(double)
 #endif
-#if VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE
+#ifdef VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE
 VSIP_IMPL_FFT_DECL_T(long double)
 #endif
 
@@ -100,13 +100,13 @@
 VSIP_IMPL_FFT_DECL(std::complex<T>, std::complex<T>, 0, 1)     \
 VSIP_IMPL_FFT_DECL(std::complex<T>, std::complex<T>, 1, 1)
 
-#if VSIP_IMPL_FFTW3_HAVE_FLOAT
+#ifdef VSIP_IMPL_FFTW3_HAVE_FLOAT
 VSIP_IMPL_FFT_DECL_T(float)
 #endif
-#if VSIP_IMPL_FFTW3_HAVE_DOUBLE
+#ifdef VSIP_IMPL_FFTW3_HAVE_DOUBLE
 VSIP_IMPL_FFT_DECL_T(double)
 #endif
-#if VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE
+#ifdef VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE
 VSIP_IMPL_FFT_DECL_T(long double)
 #endif
 
@@ -128,13 +128,13 @@
 struct evaluator<D, I, O, S, R, N, Fftw3_tag>
 {
   static bool const ct_valid =
-#if VSIP_IMPL_FFTW3_HAVE_FLOAT
+#ifdef VSIP_IMPL_FFTW3_HAVE_FLOAT
     Type_equal<typename Scalar_of<I>::type, float>::value ||
 #endif
-#if VSIP_IMPL_FFTW3_HAVE_DOUBLE
+#ifdef VSIP_IMPL_FFTW3_HAVE_DOUBLE
     Type_equal<typename Scalar_of<I>::type, double>::value ||
 #endif
-#if VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE
+#ifdef VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE
     Type_equal<typename Scalar_of<I>::type, long double>::value ||
 #endif
     false;
@@ -165,13 +165,13 @@
 struct evaluator<I, O, A, E, R, N, fft::Fftw3_tag>
 {
   static bool const ct_valid =
-#if VSIP_IMPL_FFTW3_HAVE_FLOAT
+#ifdef VSIP_IMPL_FFTW3_HAVE_FLOAT
     Type_equal<typename Scalar_of<I>::type, float>::value ||
 #endif
-#if VSIP_IMPL_FFTW3_HAVE_DOUBLE
+#ifdef VSIP_IMPL_FFTW3_HAVE_DOUBLE
     Type_equal<typename Scalar_of<I>::type, double>::value ||
 #endif
-#if VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE
+#ifdef VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE
     Type_equal<typename Scalar_of<I>::type, long double>::value ||
 #endif
     false;
Index: src/vsip/opt/fftw3/fftw_support.hpp
===================================================================
--- src/vsip/opt/fftw3/fftw_support.hpp	(revision 211341)
+++ src/vsip/opt/fftw3/fftw_support.hpp	(working copy)
@@ -75,13 +75,13 @@
   DCL_FFTW_PLAN_FUNC_C2R(T, fT)
 
 
-#if VSIP_IMPL_FFTW3_HAVE_FLOAT
+#ifdef VSIP_IMPL_FFTW3_HAVE_FLOAT
   DCL_FFTW_PLANS(float, fftwf)
 #endif
-#if VSIP_IMPL_FFTW3_HAVE_DOUBLE
+#ifdef VSIP_IMPL_FFTW3_HAVE_DOUBLE
   DCL_FFTW_PLANS(double, fftw)
 #endif
-#if VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE
+#ifdef VSIP_IMPL_FFTW3_HAVE_LONG_DOUBLE
   DCL_FFTW_PLANS(long double, fftwl)
 #endif
 
