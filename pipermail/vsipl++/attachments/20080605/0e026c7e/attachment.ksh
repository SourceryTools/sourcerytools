Index: ChangeLog
===================================================================
--- ChangeLog	(revision 210528)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2008-06-05  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/lapack/matvec.hpp: Fix stride bug in MV and VM
+	  prod evaluators.
+
 2008-06-03  Mike LeBlanc  <mike@codesourcery.com>
 
 	* src/vsip/opt/cbe/cml/conv.hpp: Use aligned_array<> and array_cast().
@@ -17,6 +22,14 @@
 	* src/vsip/opt/cbe/cml/corr.hpp: New file.  Implement the CML backend
 	  for 1D correlation.
 
+2008-06-02  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/core/matvec.hpp: Added include for cml matvec functions.
+	* src/vsip/opt/cbe/cml/matvec.hpp: New evaluators for dot and outer
+	  products.
+	* src/vsip/opt/cbe/cml/prod.hpp: New bindings for dot and outer
+	  product calls into CML.
+
 2008-05-30  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/opt/cbe/cml/matvec.hpp: Added evaluators for matrix-vector
Index: src/vsip/opt/lapack/matvec.hpp
===================================================================
--- src/vsip/opt/lapack/matvec.hpp	(revision 210528)
+++ src/vsip/opt/lapack/matvec.hpp	(working copy)
@@ -350,7 +350,7 @@
         transa,                          // char trans,
         a.size(2, 0), a.size(2, 1),      // int m, int n,
         1.0,                             // T alpha,
-        ext_a.data(), a.size(2, 0),      // T *a, int lda,
+        ext_a.data(), ext_a.stride(1),   // T *a, int lda,
         ext_b.data(), ext_b.stride(0),   // T *x, int incx,
         0.0,                             // T beta,
         ext_r.data(), ext_r.stride(0)    // T *y, int incy)
@@ -423,7 +423,7 @@
         transa,                          // char trans,
         b.size(2, 1), b.size(2, 0),      // int m, int n,
         1.0,                             // T alpha,
-        ext_b.data(), b.size(2, 1),      // T *a, int lda,
+        ext_b.data(), ext_b.stride(0),   // T *a, int lda,
         ext_a.data(), ext_a.stride(0),   // T *x, int incx,
         0.0,                             // T beta,
         ext_r.data(), ext_r.stride(0)    // T *y, int incy)
