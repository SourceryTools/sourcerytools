Index: benchmarks/hpec_kernel/cfar.cpp
===================================================================
--- benchmarks/hpec_kernel/cfar.cpp	(revision 149094)
+++ benchmarks/hpec_kernel/cfar.cpp	(working copy)
@@ -787,37 +787,39 @@
 
   typedef float F;
   typedef double D;
-  typedef col3_type R;  // Reverse storage order, tuple<2, 1, 0>
+  typedef tuple<2, 0, 1>  S;  // Slice storage order
+  typedef tuple<1, 0, 2>  V;  // Vector storage order
+  typedef tuple<0, 1, 2>  H;  // Hybrid storage order
 
   switch (what)
   {
   // parameters are number of: beams, doppler bins, CFAR range gates and 
   // CFAR guard cells respectively
-  case  1: loop(t_cfar_sweep_range<F, ImplSlice, R>(16,  24,  5,  4)); break;
-  case  2: loop(t_cfar_sweep_range<F, ImplSlice, R>(48, 128, 10,  8)); break;
-  case  3: loop(t_cfar_sweep_range<F, ImplSlice, R>(48,  64, 10,  8)); break;
-  case  4: loop(t_cfar_sweep_range<F, ImplSlice, R>(16,  16, 20, 16)); break;
+  case  1: loop(t_cfar_sweep_range<F, ImplSlice, S>(16,  24,  5,  4)); break;
+  case  2: loop(t_cfar_sweep_range<F, ImplSlice, S>(48, 128, 10,  8)); break;
+  case  3: loop(t_cfar_sweep_range<F, ImplSlice, S>(48,  64, 10,  8)); break;
+  case  4: loop(t_cfar_sweep_range<F, ImplSlice, S>(16,  16, 20, 16)); break;
 
-  case 11: loop(t_cfar_sweep_range<D, ImplSlice, R>(16,  24,  5,  4)); break;
-  case 12: loop(t_cfar_sweep_range<D, ImplSlice, R>(48, 128, 10,  8)); break;
-  case 13: loop(t_cfar_sweep_range<D, ImplSlice, R>(48,  64, 10,  8)); break;
-  case 14: loop(t_cfar_sweep_range<D, ImplSlice, R>(16,  16, 20, 16)); break;
+  case 11: loop(t_cfar_sweep_range<D, ImplSlice, S>(16,  24,  5,  4)); break;
+  case 12: loop(t_cfar_sweep_range<D, ImplSlice, S>(48, 128, 10,  8)); break;
+  case 13: loop(t_cfar_sweep_range<D, ImplSlice, S>(48,  64, 10,  8)); break;
+  case 14: loop(t_cfar_sweep_range<D, ImplSlice, S>(16,  16, 20, 16)); break;
 
-  case 21: loop(t_cfar_sweep_range<F, ImplVector>(16,  24,  5,  4)); break;
-  case 22: loop(t_cfar_sweep_range<F, ImplVector>(48, 128, 10,  8)); break;
-  case 23: loop(t_cfar_sweep_range<F, ImplVector>(48,  64, 10,  8)); break;
-  case 24: loop(t_cfar_sweep_range<F, ImplVector>(16,  16, 20, 16)); break;
+  case 21: loop(t_cfar_sweep_range<F, ImplVector, V>(16,  24,  5,  4)); break;
+  case 22: loop(t_cfar_sweep_range<F, ImplVector, V>(48, 128, 10,  8)); break;
+  case 23: loop(t_cfar_sweep_range<F, ImplVector, V>(48,  64, 10,  8)); break;
+  case 24: loop(t_cfar_sweep_range<F, ImplVector, V>(16,  16, 20, 16)); break;
 
-  case 31: loop(t_cfar_sweep_range<D, ImplVector>(16,  24,  5,  4)); break;
-  case 32: loop(t_cfar_sweep_range<D, ImplVector>(48, 128, 10,  8)); break;
-  case 33: loop(t_cfar_sweep_range<D, ImplVector>(48,  64, 10,  8)); break;
-  case 34: loop(t_cfar_sweep_range<D, ImplVector>(16,  16, 20, 16)); break;
+  case 31: loop(t_cfar_sweep_range<D, ImplVector, V>(16,  24,  5,  4)); break;
+  case 32: loop(t_cfar_sweep_range<D, ImplVector, V>(48, 128, 10,  8)); break;
+  case 33: loop(t_cfar_sweep_range<D, ImplVector, V>(48,  64, 10,  8)); break;
+  case 34: loop(t_cfar_sweep_range<D, ImplVector, V>(16,  16, 20, 16)); break;
 
 #if __GNUC__ >= 4
-  case 41: loop(t_cfar_sweep_range<F, ImplHybrid>(16,  24,  5,  4)); break;
-  case 42: loop(t_cfar_sweep_range<F, ImplHybrid>(48, 128, 10,  8)); break;
-  case 43: loop(t_cfar_sweep_range<F, ImplHybrid>(48,  64, 10,  8)); break;
-  case 44: loop(t_cfar_sweep_range<F, ImplHybrid>(16,  16, 20, 16)); break;
+  case 41: loop(t_cfar_sweep_range<F, ImplHybrid, H>(16,  24,  5,  4)); break;
+  case 42: loop(t_cfar_sweep_range<F, ImplHybrid, H>(48, 128, 10,  8)); break;
+  case 43: loop(t_cfar_sweep_range<F, ImplHybrid, H>(48,  64, 10,  8)); break;
+  case 44: loop(t_cfar_sweep_range<F, ImplHybrid, H>(16,  16, 20, 16)); break;
 #endif // __GNUC__ >= 4
 
   default: 
