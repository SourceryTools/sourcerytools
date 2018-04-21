Index: ChangeLog
===================================================================
--- ChangeLog	(revision 235080)
+++ ChangeLog	(working copy)
@@ -1,3 +1,13 @@
+2009-01-30  Jules Bergmann  <jules@codesourcery.com>
+
+	* benchmarks/ipp/fft.cpp: Add in-place and split options.  Add usage.
+	* benchmarks/fftw3/fft.cpp: Simplify shorten-dimension logic,
+	  Allow wisdom to be saved.  Add usage.
+	* benchmarks/benchmarks.hpp: Add mag op cost estimate.
+	* benchmarks/vma.cpp: Add usage.
+	* benchmarks/fftm.cpp: Parallelize some cases.
+	* benchmarks/vmmul.cpp: Parallelize some cases.
+	
 2009-01-27  Jules Bergmann  <jules@codesourcery.com>
 
 	* GNUmakefile.in: Include scripts/GNUmakefile.inc.in
Index: benchmarks/ipp/fft.cpp
===================================================================
--- benchmarks/ipp/fft.cpp	(revision 230289)
+++ benchmarks/ipp/fft.cpp	(working copy)
@@ -1,10 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2009 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    benchmarks/fft_ipp.cpp
+/** @file    benchmarks/ipp/fft.cpp
     @author  Jules Bergmann
     @date    2005-08-24
     @brief   VSIPL++ Library: Benchmark for IPP's FFT.
@@ -28,16 +28,28 @@
 
 #include <ipps.h>
 
-#include "loop.hpp"
+#include "benchmarks.hpp"
 
 using std::complex;
 
 
 
 /***********************************************************************
+  Globals
+***********************************************************************/
+
+bool check = true;
+
+
+
+/***********************************************************************
   Declarations
 ***********************************************************************/
 
+template <typename T> struct t_fft_inter_op;
+template <typename T> struct t_fft_inter_ip;
+template <typename T> struct t_fft_split_op;
+template <typename T> struct t_fft_split_ip;
 
 
 
@@ -49,13 +61,10 @@
 
 
 
-template <typename T>
-struct t_fft_ipp;
-
 template <>
-struct t_fft_ipp<complex<float> > : Benchmark_base
+struct t_fft_inter_op<complex<float> > : Benchmark_base
 {
-  char* what() { return "t_fft_ipp"; }
+  char const* what() { return "t_fft_ipp"; }
   int ops_per_point(size_t len)  { return fft_ops(len); }
   int riob_per_point(size_t) { return -1*(int)sizeof(Ipp32fc); }
   int wiob_per_point(size_t) { return -1*(int)sizeof(Ipp32fc); }
@@ -104,11 +113,11 @@
     }
     t1.stop();
     
-//    if (!equal(Z(0), T(size)))
-//    {
-//      std::cout << "t_fft_ipp: ERROR" << std::endl;
-//      abort();
-//    }
+    if (check)
+    {
+      test_assert(equal(Z[0].re, float(size)));
+      test_assert(equal(Z[0].im, float(0)));
+    }
     
     time = t1.delta();
 
@@ -122,6 +131,231 @@
 
 
 
+template <>
+struct t_fft_inter_ip<complex<float> > : Benchmark_base
+{
+  char const* what() { return "t_fft_inter_ip"; }
+  int ops_per_point(size_t len)  { return fft_ops(len); }
+  int riob_per_point(size_t) { return -1*(int)sizeof(Ipp32fc); }
+  int wiob_per_point(size_t) { return -1*(int)sizeof(Ipp32fc); }
+  int mem_per_point(size_t)  { return  2*sizeof(Ipp32fc); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    Ipp32fc*            A;
+
+    IppsFFTSpec_C_32fc* fft;
+    Ipp8u*              buffer;
+
+    int                 bufsize;
+    int                 order = 0;
+
+    for (size_t i=1; i<size; i <<= 1)
+      order++;
+
+
+    ippsFFTInitAlloc_C_32fc(&fft, order,
+			    IPP_FFT_DIV_INV_BY_N, 
+			    ippAlgHintFast);
+    ippsFFTGetBufSize_C_32fc(fft, &bufsize);
+
+    buffer = ippsMalloc_8u(bufsize);
+    A      = ippsMalloc_32fc(size);
+
+    if (!buffer || !A)
+      throw(std::bad_alloc());
+      
+
+    for (size_t i=0; i<size; ++i)
+    {
+      A[i].re = 0.f;
+      A[i].im = 0.f;
+    }
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (size_t l=0; l<loop; ++l)
+    {
+      ippsFFTFwd_CToC_32fc_I(A, fft, buffer);
+    }
+    t1.stop();
+    
+    if (check)
+    {
+      for (size_t i=0; i<size; ++i)
+      {
+	A[i].re = 0.f;
+	A[i].im = 0.f;
+      }
+      ippsFFTFwd_CToC_32fc_I(A, fft, buffer);
+      test_assert(equal(A[0].re, float(size)));
+      test_assert(equal(A[0].im, float(0)));
+    }
+    
+    time = t1.delta();
+
+    ippsFFTFree_C_32fc(fft);
+
+    ippsFree(buffer);
+    ippsFree(A);
+  }
+};
+
+
+
+template <>
+struct t_fft_split_op<complex<float> > : Benchmark_base
+{
+  char const* what() { return "t_fft_split_op"; }
+  int ops_per_point(size_t len)  { return fft_ops(len); }
+  int riob_per_point(size_t) { return -1*(int)sizeof(Ipp32fc); }
+  int wiob_per_point(size_t) { return -1*(int)sizeof(Ipp32fc); }
+  int mem_per_point(size_t)  { return  2*sizeof(Ipp32fc); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    Ipp32f*            Ar;
+    Ipp32f*            Ai;
+    Ipp32f*            Zr;
+    Ipp32f*            Zi;
+
+    IppsFFTSpec_C_32f* fft;
+    Ipp8u*             buffer;
+
+    int                 bufsize;
+    int                 order = 0;
+
+    for (size_t i=1; i<size; i <<= 1)
+      order++;
+
+
+    ippsFFTInitAlloc_C_32f(&fft, order,
+			   IPP_FFT_DIV_INV_BY_N, 
+			   ippAlgHintFast);
+    ippsFFTGetBufSize_C_32f(fft, &bufsize);
+
+    buffer = ippsMalloc_8u(bufsize);
+    Ar     = ippsMalloc_32f(size);
+    Ai     = ippsMalloc_32f(size);
+    Zr     = ippsMalloc_32f(size);
+    Zi     = ippsMalloc_32f(size);
+
+    if (!buffer || !Ar || !Ai || !Zr || !Zi)
+      throw(std::bad_alloc());
+      
+
+    for (size_t i=0; i<size; ++i)
+    {
+      Ar[i] = 1.f;
+      Ai[i] = 0.f;
+    }
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (size_t l=0; l<loop; ++l)
+    {
+      ippsFFTFwd_CToC_32f(Ar, Ai, Zr, Zi, fft, buffer);
+    }
+    t1.stop();
+    
+    if (check)
+    {
+      test_assert(equal(Zr[0], float(size)));
+      test_assert(equal(Zi[0], float(0)));
+    }
+    
+    time = t1.delta();
+
+    ippsFFTFree_C_32f(fft);
+
+    ippsFree(buffer);
+    ippsFree(Ar);
+    ippsFree(Ai);
+    ippsFree(Zr);
+    ippsFree(Zi);
+  }
+};
+
+
+
+template <>
+struct t_fft_split_ip<complex<float> > : Benchmark_base
+{
+  char const* what() { return "t_fft_split_ip"; }
+  int ops_per_point(size_t len)  { return fft_ops(len); }
+  int riob_per_point(size_t) { return -1*(int)sizeof(Ipp32fc); }
+  int wiob_per_point(size_t) { return -1*(int)sizeof(Ipp32fc); }
+  int mem_per_point(size_t)  { return  2*sizeof(Ipp32fc); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    Ipp32f*            Ar;
+    Ipp32f*            Ai;
+
+    IppsFFTSpec_C_32f* fft;
+    Ipp8u*             buffer;
+
+    int                bufsize;
+    int                order = 0;
+
+    for (size_t i=1; i<size; i <<= 1)
+      order++;
+
+
+    ippsFFTInitAlloc_C_32f(&fft, order,
+			   IPP_FFT_DIV_INV_BY_N, 
+			   ippAlgHintFast);
+    ippsFFTGetBufSize_C_32f(fft, &bufsize);
+
+    buffer = ippsMalloc_8u(bufsize);
+    Ar     = ippsMalloc_32f(size);
+    Ai     = ippsMalloc_32f(size);
+
+    if (!buffer || !Ar || !Ai)
+      throw(std::bad_alloc());
+      
+
+    for (size_t i=0; i<size; ++i)
+    {
+      Ar[i] = 1.f;
+      Ai[i] = 0.f;
+    }
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (size_t l=0; l<loop; ++l)
+    {
+      ippsFFTFwd_CToC_32f_I(Ar, Ai, fft, buffer);
+    }
+    t1.stop();
+    
+    if (check)
+    {
+      for (size_t i=0; i<size; ++i)
+      {
+	Ar[i] = 1.f;
+	Ai[i] = 0.f;
+      }
+      ippsFFTFwd_CToC_32f_I(Ar, Ai, fft, buffer);
+      test_assert(equal(Ar[0], float(size)));
+      test_assert(equal(Ai[0], float(0)));
+    }
+    
+    time = t1.delta();
+
+    ippsFFTFree_C_32f(fft);
+
+    ippsFree(buffer);
+    ippsFree(Ar);
+    ippsFree(Ai);
+  }
+};
+
+
+
 void
 defaults(Loop1P& loop)
 {
@@ -134,7 +368,21 @@
 {
   switch (what)
   {
-  case  1: loop(t_fft_ipp<complex<float> >()); break;
+  case  1: loop(t_fft_inter_op<complex<float> >()); break;
+  case  2: loop(t_fft_inter_ip<complex<float> >()); break;
+  case 11: loop(t_fft_split_op<complex<float> >()); break;
+  case 12: loop(t_fft_split_ip<complex<float> >()); break;
+
+  case 0:
+    std::cout
+      << "ipp/fft -- IPP Fft (fast fourier transform) benchmark\n"
+      << "Single precision\n"
+      << "   -1 -- inter-op: interleaved, out-of-place CC fwd fft\n"
+      << "   -2 -- inter-ip: interleaved, in-place     CC fwd fft\n"
+      << "  -11 -- split-op: interleaved, out-of-place CC fwd fft\n"
+      << "  -12 -- split-ip: interleaved, out-of-place CC fwd fft\n"
+      ;
+
   default: return 0;
   }
   return 1;
Index: benchmarks/benchmarks.hpp
===================================================================
--- benchmarks/benchmarks.hpp	(revision 230289)
+++ benchmarks/benchmarks.hpp	(working copy)
@@ -147,6 +147,7 @@
   static unsigned int const sqr = 1;
   static unsigned int const mul = 1;
   static unsigned int const add = 1;
+  static unsigned int const mag = 1;
 };
 
 template <typename T>
@@ -156,6 +157,7 @@
   static unsigned int const sqr = 2 + 1;     // mul + add
   static unsigned int const mul = 4 + 2;     // mul + add
   static unsigned int const add = 2;
+  static unsigned int const mag = 2 + 1 + 1; // 2*mul + add + sqroot
 };
 
 
Index: benchmarks/vma.cpp
===================================================================
--- benchmarks/vma.cpp	(revision 230289)
+++ benchmarks/vma.cpp	(working copy)
@@ -349,6 +349,15 @@
   case 204: loop(t_vma_cSC_simd<SD>()); break;
 #endif
 
+  case 0:
+    std::cout
+      << "vma -- vector multiply-add\n"
+      << "  -21 -- V += A * B [float]\n"
+      << "  -22 -- V += a * B [float]\n"
+      << "  -31 -- V += A * B [complex]\n"
+      << "  -32 -- V += a * B [complex]\n"
+      << " -201 -- V = a * B + C [complex*float + complex]\n"
+      << std::endl;
   default:
     return 0;
   }
Index: benchmarks/fftm.cpp
===================================================================
--- benchmarks/fftm.cpp	(revision 230289)
+++ benchmarks/fftm.cpp	(working copy)
@@ -78,15 +78,22 @@
 {
   static int const elem_per_point = 2;
 
+  typedef Map<Block_dist, Whole_dist>      map_type;
+  typedef Dense<2, T, row2_type, map_type> block_type;
+  typedef Matrix<T, block_type>            view_type;
+
   char const* what() { return "t_fftm<T, Impl_op, SD>"; }
   float ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
 
   void fftm(length_type rows, length_type cols, length_type loop, float& time)
   {
-    Matrix<T>   A(rows, cols, T());
-    Matrix<T>   Z(rows, cols);
+    processor_type np = num_processors();
+    map_type map = map_type(Block_dist(np), Whole_dist());
 
+    view_type   A(rows, cols, T(), map);
+    view_type   Z(rows, cols, map);
+
     typedef Fftm<T, T, SD, fft_fwd, by_reference, no_times, alg_time>
       fftm_type;
 
@@ -148,14 +155,21 @@
 {
   static int const elem_per_point = 1;
 
+  typedef Map<Block_dist, Whole_dist>      map_type;
+  typedef Dense<2, T, row2_type, map_type> block_type;
+  typedef Matrix<T, block_type>            view_type;
+
   char const* what() { return "t_fftm<T, Impl_ip, SD>"; }
   float ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
 
   void fftm(length_type rows, length_type cols, length_type loop, float& time)
   {
-    Matrix<T>   A(rows, cols, T());
+    processor_type np = num_processors();
+    map_type map = map_type(Block_dist(np), Whole_dist());
 
+    view_type   A(rows, cols, T(), map);
+
     typedef Fftm<T, T, SD, fft_fwd, by_reference, no_times, alg_time>
       fftm_type;
 
Index: benchmarks/vmmul.cpp
===================================================================
--- benchmarks/vmmul.cpp	(revision 230289)
+++ benchmarks/vmmul.cpp	(working copy)
@@ -56,16 +56,26 @@
 	  int      SD>
 struct t_vmmul<T, Impl_op, SD> : Benchmark_base
 {
+  typedef Map<Block_dist, Block_dist>      map_type;
+  typedef Dense<2, T, row2_type, map_type> block_type;
+  typedef Matrix<T, block_type>            view_type;
+
+  typedef Dense<1, T, row1_type, Global_map<1> > replica_block_type;
+  typedef Vector<T, replica_block_type>          replica_view_type;
+
   char const* what() { return "t_vmmul<T, Impl_op, SD>"; }
   int ops(length_type rows, length_type cols)
     { return rows * cols * vsip::impl::Ops_info<T>::mul; }
 
   void exec(length_type rows, length_type cols, length_type loop, float& time)
   {
-    Vector<T>   W(SD == row ? cols : rows);
-    Matrix<T>   A(rows, cols, T());
-    Matrix<T>   Z(rows, cols);
+    processor_type np = num_processors();
+    map_type map = map_type(Block_dist(np), Block_dist(1));
 
+    replica_view_type W(SD == row ? cols : rows);
+    view_type         A(rows, cols, T(), map);
+    view_type         Z(rows, cols, map);
+
     Rand<T> rand(0);
 
     W = ramp(T(1), T(1), W.size());
@@ -80,15 +90,20 @@
     
     if (SD == row)
     {
-      for (index_type r=0; r<rows; ++r)
+      length_type l_rows  = Z.local().size(0);
+
+      for (index_type r=0; r<l_rows; ++r)
 	for (index_type c=0; c<cols; ++c)
-	  test_assert(equal(Z.get(r, c), W.get(c) * A.get(r, c)));
+	  test_assert(equal(Z.local().get(r, c),
+			    W.get(c) * A.local().get(r, c)));
     }
     else
     {
-      for (index_type r=0; r<rows; ++r)
-	for (index_type c=0; c<cols; ++c)
-	  test_assert(equal(Z.get(r, c), W.get(r) * A.get(r, c)));
+      length_type l_cols  = Z.local().size(1);
+      for (index_type c=0; c<l_cols; ++c)
+	for (index_type r=0; r<rows; ++r)
+	  test_assert(equal(Z.local().get(r, c),
+			    W.get(r) * A.local().get(r, c)));
     }
     
     time = t1.delta();
