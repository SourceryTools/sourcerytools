Index: benchmarks/fastconv.cpp
===================================================================
--- benchmarks/fastconv.cpp	(revision 164121)
+++ benchmarks/fastconv.cpp	(working copy)
@@ -21,6 +21,9 @@
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
+#ifdef VSIP_IMPL_CBE_SDK
+#include <vsip/opt/cbe/ppu/fastconv.hpp>
+#endif
 
 #include "benchmarks.hpp"
 
@@ -50,10 +53,11 @@
 struct Impl2ip;		// in-place, interleaved fast-convolution
 struct Impl2ip_tmp;	// in-place (w/tmp), interleaved fast-convolution
 struct Impl2fv;		// foreach_vector, interleaved fast-convolution
+struct ImplCbe;		// interleaved fast-convolution on Cell
 
 struct Impl1pip2_nopar;
 
-struct fastconv_ops
+struct fastconv_ops : Benchmark_base
 {
   float ops(length_type npulse, length_type nrange) 
   {
@@ -722,6 +726,42 @@
 
 
 /***********************************************************************
+  ImplCbe: interleaved fast-convolution on Cell
+***********************************************************************/
+#ifdef VSIP_IMPL_CBE_SDK
+
+template <typename T>
+struct t_fastconv_base<T, ImplCbe> : fastconv_ops
+{
+  typedef impl::cbe::Fastconv<T>   fconv_type;
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+    // Create the data cube.
+    Matrix<T> data(npulse, nrange, T());
+    
+    // Create the pulse replica
+    Vector<T> replica(nrange, T());
+
+    // Create Fast Convolution object
+    fconv_type fconv(replica, nrange);
+
+    vsip::impl::profile::Timer t1;
+
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      fconv(data, data);
+    t1.stop();
+
+    time = t1.delta();
+  }
+};
+#endif // VSIP_IMPL_CBE_SDK
+
+
+
+/***********************************************************************
   PF driver: (P)ulse (F)ixed
 ***********************************************************************/
 
@@ -817,6 +857,10 @@
   case 18: loop(t_fastconv_rf<complex<float>, Impl2fv>(param1)); break;
 #endif
 
+#ifdef VSIP_IMPL_CBE_SDK
+  case 20: loop(t_fastconv_rf<complex<float>, ImplCbe>(param1)); break;
+#endif
+
   default: return 0;
   }
   return 1;
Index: examples/fconv.cpp
===================================================================
--- examples/fconv.cpp	(revision 164122)
+++ examples/fconv.cpp	(working copy)
@@ -17,7 +17,9 @@
 #include <vsip/signal.hpp>
 #include <vsip/math.hpp>
 #include <vsip/core/profile.hpp>
+#ifdef VSIP_IMPL_CBE_SDK
 #include <vsip/opt/cbe/ppu/fastconv.hpp>
+#endif
 
 #include <vsip_csl/error_db.hpp>
 #include <vsip_csl/ref_dft.hpp>
@@ -40,7 +42,6 @@
 fconv_example()
 {
   typedef std::complex<float> T;
-  typedef impl::cbe::Fastconv<T> fconv_type;
   typedef Fft<const_Vector, T, T, fft_fwd, by_reference> for_fft_type;
   typedef Fft<const_Vector, T, T, fft_inv, by_reference> inv_fft_type;
 
@@ -72,7 +73,9 @@
   tmp *= replica;
   inv_fft(tmp, ref);
 
+#ifdef VSIP_IMPL_CBE_SDK
   // Create Fast Convolution object
+  typedef impl::cbe::Fastconv<T> fconv_type;
   fconv_type fconv(coeffs, N);
 
 
@@ -85,6 +88,7 @@
   fconv(in, out);
   for (index_type i = 0; i < M; ++i)
     test_assert(error_db(ref, out.row(i)) < -100);
+#endif
 }
 
 
