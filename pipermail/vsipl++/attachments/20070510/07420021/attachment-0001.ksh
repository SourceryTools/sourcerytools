Index: benchmarks/hpec_kernel/cfar.cpp
===================================================================
--- benchmarks/hpec_kernel/cfar.cpp	(revision 170838)
+++ benchmarks/hpec_kernel/cfar.cpp	(working copy)
@@ -77,7 +77,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_cfar_base<T, ImplSlice>
+struct t_cfar_base<T, ImplSlice> : Benchmark_base
 {
   char* what() { return "t_cfar_sweep_range<T, ImplSlice>"; }
 
@@ -213,7 +213,7 @@
 
 
 template <typename T>
-struct t_cfar_base<T, ImplVector>
+struct t_cfar_base<T, ImplVector> : public Benchmark_base
 {
   char* what() { return "t_cfar_sweep_range<T, ImplVector>"; }
 
@@ -359,7 +359,7 @@
 // This uses GCC's vector extensions, in particular the builtin operators
 // such as '+', '/', etc.  These are only supported in GCC 4.x and above.
 #if __GNUC__ >= 4
-
+#  if defined(__SSE__)
 static const int zero[4] __attribute__((aligned(16))) =
     { 0, 0, 0, 0 };
 
@@ -390,7 +390,7 @@
 }
 
 template <typename T>
-struct t_cfar_base<T, ImplHybrid>
+struct t_cfar_base<T, ImplHybrid> : public Benchmark_base
 {
   char* what() { return "t_cfar_sweep_range<T, ImplHybrid>"; }
 
@@ -563,6 +563,7 @@
 };
 
 
+#  endif // defined(__SSE__)
 #endif // __GNUC__ >= 4
 
 
@@ -820,10 +821,12 @@
   case 34: loop(t_cfar_sweep_range<D, ImplVector, V>(16,  16, 20, 16)); break;
 
 #if __GNUC__ >= 4
+#  if defined(__SSE__)
   case 41: loop(t_cfar_sweep_range<F, ImplHybrid, H>(16,  24,  5,  4)); break;
   case 42: loop(t_cfar_sweep_range<F, ImplHybrid, H>(48, 128, 10,  8)); break;
   case 43: loop(t_cfar_sweep_range<F, ImplHybrid, H>(48,  64, 10,  8)); break;
   case 44: loop(t_cfar_sweep_range<F, ImplHybrid, H>(16,  16, 20, 16)); break;
+#  endif // defined(__SSE__)
 #endif // __GNUC__ >= 4
 
   default: 
Index: benchmarks/hpec_kernel/firbank.cpp
===================================================================
--- benchmarks/hpec_kernel/firbank.cpp	(revision 170838)
+++ benchmarks/hpec_kernel/firbank.cpp	(working copy)
@@ -51,7 +51,8 @@
 struct t_firbank_base;
 
 struct ImplFull;	   // Time-domain convolution using Fir class
-struct ImplFast;	   // Fast convolution using FFT's
+struct ImplFast;	   // Fast convolution using FFTs
+struct ImplExpr;	   // Fast convolution using FFTMs
 
 
 template <typename T>
@@ -104,7 +105,7 @@
 // This helper class holds an array of Fir objects 
 
 template <typename T>
-struct fir_vector : public std::vector<Fir<T, nonsym, state_no_save, 1>*>
+struct fir_vector : std::vector<Fir<T, nonsym, state_no_save, 1>*>
 {
   typedef Fir<T, nonsym, state_no_save, 1> fir_type;
   typedef std::vector<fir_type*> base_type;
@@ -129,7 +130,7 @@
 
 
 template <typename T>
-struct t_firbank_base<T, ImplFull> : public t_local_view<T>
+struct t_firbank_base<T, ImplFull> : t_local_view<T>,  Benchmark_base
 {
   float ops(length_type filters, length_type points, length_type coeffs)
   {
@@ -191,11 +192,11 @@
 
 
 /***********************************************************************
-  ImplFast: fast convolution using FFT's
+  ImplFast: fast convolution using FFTs
 ***********************************************************************/
 
 template <typename T>
-struct t_firbank_base<T, ImplFast> : public t_local_view<T>
+struct t_firbank_base<T, ImplFast> : t_local_view<T>, Benchmark_base
 {
   float fft_ops(length_type len)
   {
@@ -252,7 +253,6 @@
     for ( length_type i = 0; i < local_M; ++i )
       fwd_fft(response.row(i));
 
-
     vsip::impl::profile::Timer t1;
     
     t1.start();
@@ -275,7 +275,7 @@
     if ( N > 2*(K-1) )
     {
       vsip::Domain<2> middle( Domain<1>(local_M), Domain<1>(K-1, 1, N-2*(K-1)) );
-      assert( view_equal(outputs.local()(middle), expected.local()(middle)) );
+      assert( view_equal(LOCAL(outputs)(middle), LOCAL(expected)(middle)) );
     }
   }
 
@@ -289,13 +289,107 @@
 };
 
 
+/***********************************************************************
+  ImplExpr: fast convolution using a single expression with FFTMs
+***********************************************************************/
 
+template <typename T>
+struct t_firbank_base<T, ImplExpr> : t_local_view<T>, Benchmark_base
+{
+  float fft_ops(length_type len)
+  {
+    return float(5 * len * std::log(float(len)) / std::log(float(2)));
+  }
+
+  float ops(length_type filters, length_type points, length_type /*coeffs*/)
+  {
+    // 'coeffs' is not used because the coefficients are zero-padded to the 
+    // length of the inputs.
+
+    return float(
+      filters * ( 
+        2 * fft_ops(points) +                   // one forward, one reverse FFT
+        vsip::impl::Ops_info<T>::mul * points   // element-wise vector multiply
+      )
+    );
+  }
+  
+  static int const no_times = 15; // not > 12 = FFT_MEASURE
+  
+  typedef Fftm<T, T, row, fft_fwd, by_value, no_times>    for_fftm_type;
+  typedef Fftm<T, T, row, fft_inv, by_value, no_times>    inv_fftm_type;
+
+  template <
+    typename Block1,
+    typename Block2,
+    typename Block3,
+    typename Block4
+    >
+  void firbank(
+    Matrix<T, Block1> inputs,
+    Matrix<T, Block2> filters,
+    Matrix<T, Block3> outputs,
+    Matrix<T, Block4> expected,
+    length_type       loop,
+    float&            time)
+  {
+    this->verify_views(inputs, filters, outputs, expected);
+    assert(inputs.size(0) <= this->m_);
+
+    // Create FFT objects
+    length_type local_M = LOCAL(inputs).size(0);
+    length_type M = inputs.size(0);
+    length_type N = inputs.size(1);
+    length_type K = this->k_;
+    length_type scale = 1;
+    
+    for_fftm_type for_fftm(Domain<2>(M, N), scale);
+    inv_fftm_type inv_fftm(Domain<2>(M, N), scale / float(N));
+
+    // Copy the filters and zero pad to same length as inputs
+    Matrix<T, Block2> response(M, N, T(), filters.block().map());
+    LOCAL(response)(Domain<2>(local_M, K)) = LOCAL(filters); 
+
+    // Pre-compute the FFT on the filters
+    response = for_fftm(response);
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      outputs = inv_fftm(response * for_fftm(inputs));
+    }
+    t1.stop();
+    time = t1.delta();
+
+    
+    // Verify data - ignore values that overlap due to circular convolution. 
+    // This means 'k-1' values at either end of each vector.
+    if ( N > 2*(K-1) )
+    {
+      vsip::Domain<2> middle( Domain<1>(local_M), Domain<1>(K-1, 1, N-2*(K-1)) );
+      assert( view_equal(LOCAL(outputs)(middle), LOCAL(expected)(middle)) );
+    }
+  }
+
+  t_firbank_base(length_type filters, length_type coeffs)
+   : m_(filters), k_(coeffs) {}
+
+public:
+  // Member data
+  length_type const m_;
+  length_type const k_;
+};
+
+
+
 /***********************************************************************
   Generic front-end for varying input vector lengths 
 ***********************************************************************/
 
 template <typename T, typename ImplTag>
-struct t_firbank_sweep_n : public t_firbank_base<T, ImplTag>
+struct t_firbank_sweep_n : t_firbank_base<T, ImplTag>
 {
   char* what() { return "t_firbank_sweep_n"; }
   int ops_per_point(length_type size)
@@ -345,10 +439,8 @@
     expected.row(0).put(3, 7);
     expected.row(0).put(4, 4);
 
-
     // Run the test and time it
-    this->firbank( LOCAL(inputs), LOCAL(filters), LOCAL(outputs),
-      LOCAL(expected), loop, time );
+    this->firbank(inputs, filters, outputs, expected, loop, time);
   }
 
   t_firbank_sweep_n(length_type filters, length_type coeffs)
@@ -364,7 +456,7 @@
 ***********************************************************************/
 
 template <typename T, typename ImplTag>
-struct t_firbank_from_file : public t_firbank_base<T, ImplTag>
+struct t_firbank_from_file : t_firbank_base<T, ImplTag>
 {
   char* what() { return "t_firbank_from_file"; }
   int ops_per_point(length_type size)
@@ -401,9 +493,9 @@
     if (root_map.subblock() != no_subblock)
     {
       // Initialize
-      inputs_root.local() = T();
-      filters_root.local() = T();
-      expected_root.local() = T();
+      LOCAL(inputs_root) = T();
+      LOCAL(filters_root) = T();
+      LOCAL(expected_root) = T();
       
       // read in inputs, filters and outputs
       std::ostringstream input_file;
@@ -426,9 +518,9 @@
       Load_view<2, T> load_outputs(output_file.str().c_str(), 
         Domain<2>(this->m_, size));
 
-      inputs_root.local() = load_inputs.view();
-      filters_root.local() = load_filters.view();
-      expected_root.local() = load_outputs.view();
+      LOCAL(inputs_root) = load_inputs.view();
+      LOCAL(filters_root) = load_filters.view();
+      LOCAL(expected_root) = load_outputs.view();
     }
 
 
@@ -453,8 +545,7 @@
 
 
     // Run the test and time it
-    this->firbank( inputs.local(), filters.local(), outputs.local(), 
-      expected.local(), loop, time );
+    this->firbank(inputs, filters, outputs, expected, loop, time);
   }
 
   t_firbank_from_file(length_type m, length_type k, char * directory )
@@ -476,7 +567,6 @@
   loop.cal_        = 7;
   loop.start_      = 7;
   loop.stop_       = 15;
-  loop.loop_start_ = 100;
   loop.user_param_ = 64;
 }
 
@@ -512,22 +602,53 @@
   case  12: loop(
     t_firbank_sweep_n<complex<float>, ImplFast>(20,  12));
     break;
+  case  21: loop(
+    t_firbank_sweep_n<complex<float>, ImplExpr>(64, 128));
+    break;
+  case  22: loop(
+    t_firbank_sweep_n<complex<float>, ImplExpr>(20,  12));
+    break;
 
 #ifdef VSIP_IMPL_SOURCERY_VPP
-  case  21: loop(
+  case  51: loop(
     t_firbank_from_file<complex<float>, ImplFull> (64, 128, "data/set1"));
     break;
-  case  22: loop(
+  case  52: loop(
     t_firbank_from_file<complex<float>, ImplFull> (20,  12, "data/set2"));
     break;
-  case  31: loop(
+  case  61: loop(
     t_firbank_from_file<complex<float>, ImplFast> (64, 128, "data/set1"));
     break;
-  case  32: loop(
+  case  62: loop(
     t_firbank_from_file<complex<float>, ImplFast> (20,  12, "data/set2"));
     break;
+  case  71: loop(
+    t_firbank_from_file<complex<float>, ImplExpr> (64, 128, "data/set1"));
+    break;
+  case  72: loop(
+    t_firbank_from_file<complex<float>, ImplExpr> (20,  12, "data/set2"));
+    break;
 #endif
 
+  case 0:
+    std::cout
+      << "firbank -- FIR Filter Bank\n"
+      << "  #   Set    Method   Data\n"
+      << "  -1   1      Time     generated\n"
+      << "  -2   2      Time     generated\n"
+      << " -11   1    Freq/FFT   generated\n"
+      << " -12   2    Freq/FFT   generated\n"
+      << " -21   1    Freq/FFTM  generated\n"
+      << " -22   2    Freq/FFTM  generated\n"
+      << " ---\n"
+      << " -51   1      Time     external\n"
+      << " -52   2      Time     external\n"
+      << " -61   1    Freq/FFT   external\n"
+      << " -62   2    Freq/FFT   external\n"
+      << " -71   1    Freq/FFTM  external\n"
+      << " -72   2    Freq/FFTM  external\n"
+      << std::endl;
+
   default: 
     return 0;
   }
Index: benchmarks/hpec_kernel/svd.cpp
===================================================================
--- benchmarks/hpec_kernel/svd.cpp	(revision 170838)
+++ benchmarks/hpec_kernel/svd.cpp	(working copy)
@@ -189,7 +189,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_svd_base
+struct t_svd_base : public Benchmark_base
 {
   t_svd_base(storage_type ust, storage_type vst)
     : ust_(ust), vst_(vst) {}
Index: benchmarks/hpec_kernel/cfar_c.cpp
===================================================================
--- benchmarks/hpec_kernel/cfar_c.cpp	(revision 170838)
+++ benchmarks/hpec_kernel/cfar_c.cpp	(working copy)
@@ -38,7 +38,9 @@
 ***********************************************************************/
 
 #include <iostream>
-#include <xmmintrin.h>
+#if defined(__SSE__)
+#  include <xmmintrin.h>
+#endif
 
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
@@ -64,7 +66,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_cfar_base
+struct t_cfar_base : Benchmark_base
 {
   int ops_per_point(length_type /*size*/)
   { 
@@ -416,6 +418,7 @@
 /***********************************************************************
   cfar_by_vector_csimd
 ***********************************************************************/
+#if defined(__SSE__)
 
 static const int zero[4] __attribute__((aligned(16))) =
     { 0, 0, 0, 0 };
@@ -697,6 +700,7 @@
   length_type mu_;            // Threshold for determining targets
 };
 
+#endif // #if defined(__SSE__)
 
 
 /***********************************************************************
@@ -750,10 +754,12 @@
   case 23: loop(t_cfar_by_vector_c<float>(48,  64, 10,  8)); break;
   case 24: loop(t_cfar_by_vector_c<float>(16,  16, 20, 16)); break;
 
+#if defined(__SSE__)
   case 41: loop(t_cfar_by_vector_csimd<float>(16,  24,  5,  4)); break;
   case 42: loop(t_cfar_by_vector_csimd<float>(48, 128, 10,  8)); break;
   case 43: loop(t_cfar_by_vector_csimd<float>(48,  64, 10,  8)); break;
   case 44: loop(t_cfar_by_vector_csimd<float>(16,  16, 20, 16)); break;
+#endif
 
   default: 
     return 0;
