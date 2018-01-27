Index: ChangeLog
===================================================================
--- ChangeLog	(revision 171241)
+++ ChangeLog	(working copy)
@@ -1,3 +1,11 @@
+2007-05-14  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/simd/threshold.hpp (simd_thresh, simd_thresh0): Fix
+	  compilation error.  Make static inline.
+	* src/vsip/opt/simd/simd.hpp (AltiVec float load_scalar): Fix GHS
+	  compilation error.
+	* src/vsip/opt/expr/lf_initfini.hpp: Add missing inline.
+	
 2007-05-14  Assem Salama <assem@codesourcery.com>
 
 	* src/vsip/opt/simd/threshold.hpp: New file. Implements a SIMD threshold
Index: src/vsip/opt/simd/threshold.hpp
===================================================================
--- src/vsip/opt/simd/threshold.hpp	(revision 171241)
+++ src/vsip/opt/simd/threshold.hpp	(working copy)
@@ -53,8 +53,8 @@
 
 // Simd function to do threshold only when K is 0
 template <typename T>
-int
-simd_thresh0(T* Z, T const* A, T const* B, int const n)
+static inline int
+simd_thresh0(T* Z, T const* A, T const* B, int n)
 {
   typedef Simd_traits<T>                         simd;
   typedef Simd_traits<int>                       simdi;
@@ -89,8 +89,8 @@
 
 // Simd function to do threshold only when K is not 0
 template <typename T>
-int
-simd_thresh(T* Z, T const* A, T const* B, T const k, int const n)
+static inline int
+simd_thresh(T* Z, T const* A, T const* B, T const k, int n)
 {
   typedef Simd_traits<T>                         simd;
   typedef Simd_traits<int>                       simdi;
Index: src/vsip/opt/simd/simd.hpp
===================================================================
--- src/vsip/opt/simd/simd.hpp	(revision 171241)
+++ src/vsip/opt/simd/simd.hpp	(working copy)
@@ -471,7 +471,18 @@
 
   static simd_type load_scalar(value_type value)
   {
+#if __ghs__
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec             = zero();
+    u.val[scalar_pos] = value;
+    return u.vec;
+#else
     return VSIP_IMPL_AV_LITERAL(simd_type, value, 0.f, 0.f, 0.f);
+#endif
   }
 
   static simd_type load_scalar_all(value_type value)
Index: src/vsip/opt/expr/lf_initfini.hpp
===================================================================
--- src/vsip/opt/expr/lf_initfini.hpp	(revision 171241)
+++ src/vsip/opt/expr/lf_initfini.hpp	(working copy)
@@ -185,7 +185,7 @@
 
 
 template <typename BlockT>
-void
+inline void
 do_loop_fusion_init(BlockT const& block)
 {
   Do_loop_fusion_init::transform<BlockT>::apply(block);
@@ -194,7 +194,7 @@
 
 
 template <typename BlockT>
-void
+inline void
 do_loop_fusion_fini(BlockT const& block)
 {
   Do_loop_fusion_fini::transform<BlockT>::apply(block);
