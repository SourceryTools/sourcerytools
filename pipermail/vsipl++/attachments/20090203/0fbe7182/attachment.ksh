Index: ChangeLog
===================================================================
--- ChangeLog	(revision 235653)
+++ ChangeLog	(working copy)
@@ -1,3 +1,7 @@
+2009-02-03  Jules Bergmann  <jules@codesourcery.com>
+
+	* benchmarks/ipp/fft.cpp: Guard IPP 5.0 API usage.
+
 2009-02-02  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* src/vsip_csl/cvsip/block.hpp: Add is_derived() method.
Index: benchmarks/ipp/fft.cpp
===================================================================
--- benchmarks/ipp/fft.cpp	(revision 235308)
+++ benchmarks/ipp/fft.cpp	(working copy)
@@ -130,7 +130,7 @@
 };
 
 
-
+#if IPP_VERSION_MAJOR >= 5
 template <>
 struct t_fft_inter_ip<complex<float> > : Benchmark_base
 {
@@ -201,6 +201,7 @@
     ippsFree(A);
   }
 };
+#endif // IPP_VERSION_MAJOR >= 5
 
 
 
@@ -280,6 +281,7 @@
 
 
 
+#if IPP_VERSION_MAJOR >= 5
 template <>
 struct t_fft_split_ip<complex<float> > : Benchmark_base
 {
@@ -353,6 +355,7 @@
     ippsFree(Ai);
   }
 };
+#endif // IPP_VERSION_MAJOR >= 5
 
 
 
@@ -369,18 +372,26 @@
   switch (what)
   {
   case  1: loop(t_fft_inter_op<complex<float> >()); break;
+#if IPP_VERSION_MAJOR >= 5
   case  2: loop(t_fft_inter_ip<complex<float> >()); break;
+#endif // IPP_VERSION_MAJOR >= 5
   case 11: loop(t_fft_split_op<complex<float> >()); break;
+#if IPP_VERSION_MAJOR >= 5
   case 12: loop(t_fft_split_ip<complex<float> >()); break;
+#endif // IPP_VERSION_MAJOR >= 5
 
   case 0:
     std::cout
       << "ipp/fft -- IPP Fft (fast fourier transform) benchmark\n"
       << "Single precision\n"
       << "   -1 -- inter-op: interleaved, out-of-place CC fwd fft\n"
+#if IPP_VERSION_MAJOR >= 5
       << "   -2 -- inter-ip: interleaved, in-place     CC fwd fft\n"
+#endif // IPP_VERSION_MAJOR >= 5
       << "  -11 -- split-op: interleaved, out-of-place CC fwd fft\n"
+#if IPP_VERSION_MAJOR >= 5
       << "  -12 -- split-ip: interleaved, out-of-place CC fwd fft\n"
+#endif // IPP_VERSION_MAJOR >= 5
       ;
 
   default: return 0;
