Index: ChangeLog
===================================================================
--- ChangeLog	(revision 174122)
+++ ChangeLog	(working copy)
@@ -1,3 +1,10 @@
+2007-06-15  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/impl_tags.hpp (Simd_unaligned_loop_fusion_tag):
+	  Add missing tag.
+	* src/vsip/opt/simd/simd.hpp (simd): Add has_perm trait to general
+	  class.
+
 2007-06-14  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* src/vsip_csl/stencil.hpp: Disable debug output.
Index: src/vsip/core/impl_tags.hpp
===================================================================
--- src/vsip/core/impl_tags.hpp	(revision 173836)
+++ src/vsip/core/impl_tags.hpp	(working copy)
@@ -41,6 +41,7 @@
 struct Copy_tag {};		// Optimized Copy
 struct Op_expr_tag {};		// Special expr handling (vmmul, etc)
 struct Simd_loop_fusion_tag {};	// SIMD Loop Fusion.
+struct Simd_unaligned_loop_fusion_tag {};
 struct Fc_expr_tag {};		// Fused Fastconv RBO evaluator.
 struct Rbo_expr_tag {};		// Return-block expression evaluator.
 struct Loop_fusion_tag {};	// Generic Loop Fusion (base case).
Index: src/vsip/opt/simd/simd.hpp
===================================================================
--- src/vsip/opt/simd/simd.hpp	(revision 173836)
+++ src/vsip/opt/simd/simd.hpp	(working copy)
@@ -128,6 +128,7 @@
    
   static int const  vec_size   = 1;
   static bool const is_accel   = false;
+  static bool const has_perm   = false;
   static int  const alignment  = 1;
   static unsigned int const scalar_pos = 0;
 
