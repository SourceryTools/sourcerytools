Index: ChangeLog
===================================================================
--- ChangeLog	(revision 173224)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2007-06-05  Don McCoy  <don@codesourcery.com>
+
+	* benchmarks/dot.cpp: No longer calls BLAS dot product if using
+	  split complex format (not suported).
+
 2007-06-05  Jules Bergmann  <jules@codesourcery.com>
 
 	* tests/coverage_ternary.cpp: Delete file, split into ...
Index: benchmarks/dot.cpp
===================================================================
--- benchmarks/dot.cpp	(revision 173224)
+++ benchmarks/dot.cpp	(working copy)
@@ -157,8 +157,10 @@
 
 #if VSIP_IMPL_HAVE_BLAS
   case  5: loop(t_dot2<impl::Blas_tag, float>()); break;
+#if !(VSIP_IMPL_PREFER_SPLIT_COMPLEX)
   case  6: loop(t_dot2<impl::Blas_tag, complex<float> >()); break;
 #endif
+#endif
 
   default: return 0;
   }
