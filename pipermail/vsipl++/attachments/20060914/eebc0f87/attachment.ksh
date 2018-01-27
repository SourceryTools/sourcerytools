Index: ChangeLog
===================================================================
--- ChangeLog	(revision 149215)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2006-09-14  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/fast-transpose.hpp (transpose_unit): Simplify
+	  dispatch on _WIN32, work around for Intel C++ 9.1 bug.
+	  
 2006-09-14  Don McCoy  <don@codesourcery.com>
 
 	* benchmarks/hpec_kernel/cfar.cpp: Corrected storage order for
Index: src/vsip/impl/fast-transpose.hpp
===================================================================
--- src/vsip/impl/fast-transpose.hpp	(revision 149215)
+++ src/vsip/impl/fast-transpose.hpp	(working copy)
@@ -586,6 +586,20 @@
   stride_type const dst_col_stride,
   stride_type const src_row_stride)
 {
+  // Intel C++ 9.1 for Windows has trouble with transpose_unit()
+  // when T1 and T2 are complex<>.  This appears to be a compiler
+  // bug (see icl-transpose-assign.cpp).
+  //
+  // Empircally, it appears we can avoid this bug by forgoing
+  // dispatch on block size and ignoring SIMD alignment.
+  // (060914)
+#if _WIN32
+  // #if 0
+  trans_detail::transpose_unit(dst, src, rows, cols,
+			       dst_col_stride, src_row_stride,
+			       trans_detail::Impl_block_recur<4, false>()
+			       );
+#else
   // Check if data is aligned for SSE ISA.
   //  - pointers need to be 16-byte aligned
   //  - rows/cols need to start with 16-byte alignment.
@@ -621,6 +635,7 @@
 				   trans_detail::Impl_block_recur<16, false>()
 				   );
   }
+#endif
 }
 
 
