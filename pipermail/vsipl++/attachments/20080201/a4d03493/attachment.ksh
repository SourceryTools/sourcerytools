Index: ChangeLog
===================================================================
--- ChangeLog	(revision 192344)
+++ ChangeLog	(working copy)
@@ -1,5 +1,9 @@
 2008-01-31  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/simd/simd.hpp (SSE2 mag): Fix bug in mask width.
+
+2008-01-31  Jules Bergmann  <jules@codesourcery.com>
+
 	* scripts/config: Add missing SIMD configure flags in Mondo package.
 
 2008-01-30  Jules Bergmann  <jules@codesourcery.com>
Index: src/vsip/opt/simd/simd.hpp
===================================================================
--- src/vsip/opt/simd/simd.hpp	(revision 191870)
+++ src/vsip/opt/simd/simd.hpp	(working copy)
@@ -1409,6 +1409,17 @@
 #endif
   }
 
+  static value_type extract(simd_type const& v, int pos)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec             = v;
+    return u.val[pos];
+  }
+
   static simd_type add(simd_type const& v1, simd_type const& v2)
   { return _mm_add_pd(v1, v2); }
 
@@ -1427,9 +1438,9 @@
 
   static simd_type mag(simd_type const& v1)
   {
-    simd_type mask = (simd_type)_mm_set_epi32(0x7ffffff, 0xfffffff,
-					      0x7ffffff, 0xfffffff);
-    return _mm_and_pd((simd_type)mask, v1);
+    simd_type mask = (simd_type)_mm_set_epi32(0x7fffffff, 0xffffffff,
+					      0x7fffffff, 0xffffffff);
+    return _mm_and_pd(mask, v1);
   }
 
   static simd_type min(simd_type const& v1, simd_type const& v2)
