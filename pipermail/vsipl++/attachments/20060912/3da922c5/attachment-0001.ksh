Index: benchmarks/hpec_kernel/cfar.cpp
===================================================================
--- benchmarks/hpec_kernel/cfar.cpp	(revision 149094)
+++ benchmarks/hpec_kernel/cfar.cpp	(working copy)
@@ -787,7 +787,7 @@
 
   typedef float F;
   typedef double D;
-  typedef col3_type R;  // Reverse storage order, tuple<2, 1, 0>
+  typedef tuple<2, 0, 1>  S;  // Slice storage order
 
   switch (what)
   {
