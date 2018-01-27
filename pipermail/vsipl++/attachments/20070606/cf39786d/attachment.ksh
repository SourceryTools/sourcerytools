Index: ChangeLog
===================================================================
--- ChangeLog	(revision 173214)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2007-06-06  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/simd/simd.hpp: Fix compilation errors.  Workaround
+	  ppu-g++ handling of vec_cmple.
+
 2007-06-05  Don McCoy  <don@codesourcery.com>
 
 	* benchmarks/cell/bw.cpp: Remove debug code.
Index: src/vsip/opt/simd/simd.hpp
===================================================================
--- src/vsip/opt/simd/simd.hpp	(revision 173077)
+++ src/vsip/opt/simd/simd.hpp	(working copy)
@@ -265,7 +265,7 @@
   }
   
   static perm_simd_type shift_for_addr(value_type* addr)
-  { return vec_lvsl(0, addr);
+  { return vec_lvsl(0, addr); }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
   { return vec_perm(x0, x1, sh); }
@@ -361,7 +361,7 @@
   }
 
   static perm_simd_type shift_for_addr(value_type* addr)
-  { return vec_lvsl(0, addr);
+  { return vec_lvsl(0, addr); }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
   { return vec_perm(x0, x1, sh); }
@@ -460,7 +460,7 @@
   }
 
   static perm_simd_type shift_for_addr(value_type* addr)
-  { return vec_lvsl(0, addr);
+  { return vec_lvsl(0, addr); }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
   { return vec_perm(x0, x1, sh); }
@@ -558,7 +558,7 @@
   }
 
   static perm_simd_type shift_for_addr(value_type* addr)
-  { return vec_lvsl(0, addr);
+  { return vec_lvsl(0, addr); }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
   { return vec_perm(x0, x1, sh); }
@@ -610,8 +610,10 @@
   static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
   { return vec_cmpge(v1, v2); }
 
+  // 070505: ppu-g++ 4.1.1 confused by return type for vec_cmple
+  //         (but regular g++ 4.1.1 OK).  Use vec_cmpgt instead.
   static bool_simd_type le(simd_type const& v1, simd_type const& v2)
-  { return vec_cmple(v1, v2); }
+  { return vec_cmpgt(v2, v1); }
 
   static simd_type real_from_interleaved(simd_type const& v1,
 					 simd_type const& v2)
