Index: ChangeLog
===================================================================
--- ChangeLog	(revision 145318)
+++ ChangeLog	(working copy)
@@ -1,5 +1,12 @@
 2006-07-20  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/impl/ipp/fft.cpp: Make impl namespace explicit to
+	  deconfuse ICC 9.1, which thought it was a class.
+	* src/vsip/impl/eval_dense_expr.hpp: Copy functor when redimensioning
+	  a unary expr block (fixes examples/png.cpp build failure).
+	
+2006-07-20  Jules Bergmann  <jules@codesourcery.com>
+
 	Optimize comparison of maps for equivalence.
 	* src/vsip/impl/block-traits.hpp (Map_equal): Add template
 	  parameter to account for dimension of applied maps being compared.
Index: src/vsip/impl/ipp/fft.cpp
===================================================================
--- src/vsip/impl/ipp/fft.cpp	(revision 145317)
+++ src/vsip/impl/ipp/fft.cpp	(working copy)
@@ -839,7 +839,7 @@
 template <>                                             \
 std::auto_ptr<fft::fftm<I, O, A, E> >			\
 create(Domain<2> const &dom,                            \
-       impl::Scalar_of<I>::type scale,                  \
+       vsip::impl::Scalar_of<I>::type scale,            \
        bool fast)					\
 {                                                       \
   if (fast)                                             \
Index: src/vsip/impl/eval_dense_expr.hpp
===================================================================
--- src/vsip/impl/eval_dense_expr.hpp	(revision 145317)
+++ src/vsip/impl/eval_dense_expr.hpp	(working copy)
@@ -512,7 +512,7 @@
     typedef typename
       transform<Unary_expr_block<Dim0, Op, BlockT, T> const>::type
         block_type;
-    return block_type(apply(const_cast<BlockT&>(blk.op())));
+    return block_type(apply(const_cast<BlockT&>(blk.op())), blk);
   }
 
   template <dimension_type                Dim0,
