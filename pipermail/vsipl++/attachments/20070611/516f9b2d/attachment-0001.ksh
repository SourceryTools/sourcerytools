Index: benchmarks/dot.cpp
===================================================================
--- benchmarks/dot.cpp	(revision 173208)
+++ benchmarks/dot.cpp	(working copy)
@@ -83,7 +83,13 @@
 // Dot-product benchmark class with particular ImplTag.
 
 template <typename ImplTag,
-	  typename T>
+          typename T,
+          bool     IsValid = impl::Evaluator<impl::
+                     Op_prod_vv_dot, impl::Return_scalar<T>,
+                     impl::Op_list_2<
+                       typename Vector<T>::block_type, 
+                       typename Vector<T>::block_type>, 
+                     ImplTag>::ct_valid>
 struct t_dot2 : Benchmark_base
 {
   static length_type const Dec = 1;
@@ -134,6 +140,15 @@
 };
 
 
+template <typename ImplTag,
+              typename T>
+struct t_dot2<ImplTag, T, false> : Benchmark_base
+{
+  void operator()(length_type, length_type, float& time)
+  {
+    std::cout << "t_dot2: evaluator not implemented\n";
+  }
+}; 
 
 void
 defaults(Loop1P& loop)
