Index: benchmarks/hpec_kernel/cfar.cpp
===================================================================
--- benchmarks/hpec_kernel/cfar.cpp	(revision 148805)
+++ benchmarks/hpec_kernel/cfar.cpp	(working copy)
@@ -570,7 +570,7 @@
 
 template <typename T,
           typename ImplTag,
- 	  typename OrderT = tuple<2, 0, 1> >
+ 	  typename OrderT = tuple<0, 1, 2> >
 struct t_cfar_sweep_range : public t_cfar_base<T, ImplTag>
 {
   int ops_per_point(length_type /*size*/)
@@ -787,20 +787,21 @@
 
   typedef float F;
   typedef double D;
+  typedef col3_type R;  // Reverse storage order, tuple<2, 1, 0>
 
   switch (what)
   {
   // parameters are number of: beams, doppler bins, CFAR range gates and 
   // CFAR guard cells respectively
-  case  1: loop(t_cfar_sweep_range<F, ImplSlice>(16,  24,  5,  4)); break;
-  case  2: loop(t_cfar_sweep_range<F, ImplSlice>(48, 128, 10,  8)); break;
-  case  3: loop(t_cfar_sweep_range<F, ImplSlice>(48,  64, 10,  8)); break;
-  case  4: loop(t_cfar_sweep_range<F, ImplSlice>(16,  16, 20, 16)); break;
+  case  1: loop(t_cfar_sweep_range<F, ImplSlice, R>(16,  24,  5,  4)); break;
+  case  2: loop(t_cfar_sweep_range<F, ImplSlice, R>(48, 128, 10,  8)); break;
+  case  3: loop(t_cfar_sweep_range<F, ImplSlice, R>(48,  64, 10,  8)); break;
+  case  4: loop(t_cfar_sweep_range<F, ImplSlice, R>(16,  16, 20, 16)); break;
 
-  case 11: loop(t_cfar_sweep_range<D, ImplSlice>(16,  24,  5,  4)); break;
-  case 12: loop(t_cfar_sweep_range<D, ImplSlice>(48, 128, 10,  8)); break;
-  case 13: loop(t_cfar_sweep_range<D, ImplSlice>(48,  64, 10,  8)); break;
-  case 14: loop(t_cfar_sweep_range<D, ImplSlice>(16,  16, 20, 16)); break;
+  case 11: loop(t_cfar_sweep_range<D, ImplSlice, R>(16,  24,  5,  4)); break;
+  case 12: loop(t_cfar_sweep_range<D, ImplSlice, R>(48, 128, 10,  8)); break;
+  case 13: loop(t_cfar_sweep_range<D, ImplSlice, R>(48,  64, 10,  8)); break;
+  case 14: loop(t_cfar_sweep_range<D, ImplSlice, R>(16,  16, 20, 16)); break;
 
   case 21: loop(t_cfar_sweep_range<F, ImplVector>(16,  24,  5,  4)); break;
   case 22: loop(t_cfar_sweep_range<F, ImplVector>(48, 128, 10,  8)); break;
