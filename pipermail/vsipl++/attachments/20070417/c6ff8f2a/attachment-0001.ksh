Index: src/vsip/opt/expr/eval_fastconv.hpp
===================================================================
--- src/vsip/opt/expr/eval_fastconv.hpp	(revision 168991)
+++ src/vsip/opt/expr/eval_fastconv.hpp	(working copy)
@@ -139,6 +139,183 @@
   }
 };
 
+
+template <typename       DstBlock,
+	  typename       T,
+	  typename       CoeffsMatBlockT,
+	  typename       MatBlockT,
+	  typename       Backend1T,
+	  typename       Workspace1T,
+	  typename       Backend2T,
+	  typename       Workspace2T>
+struct Serial_expr_evaluator<2, DstBlock,
+  const Return_expr_block<2, T,
+    fft::Fft_return_functor<2, T,
+      const Binary_expr_block<2, op::Mult,
+        CoeffsMatBlockT, T, 
+        const Return_expr_block<2, T,
+          fft::Fft_return_functor<2, T,
+            MatBlockT,
+            Backend2T, Workspace2T>
+        >, T
+      >,
+      Backend1T, Workspace1T>
+    >,
+    Fc_expr_tag
+  >
+{
+  static char const* name() { return "Fc_expr_tag"; }
+
+  typedef
+  Return_expr_block<2, T,
+    fft::Fft_return_functor<2, T,
+      const Binary_expr_block<2, op::Mult,
+        CoeffsMatBlockT, T,
+        const Return_expr_block<2, T,
+          fft::Fft_return_functor<2, T,
+            MatBlockT,
+            Backend2T, Workspace2T>
+        >, T
+      >,
+      Backend1T, Workspace1T>
+    >
+    SrcBlock;
+
+  typedef typename DstBlock::value_type dst_type;
+  typedef typename SrcBlock::value_type src_type;
+
+  static bool const ct_valid = true;
+
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    (void)dst;
+    (void)src;
+    return true;
+  }
+  
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    length_type rows = dst.size(2, 0);
+    length_type cols = dst.size(2, 1);
+    Matrix<T> tmp(1, cols);
+
+    Matrix<T, CoeffsMatBlockT> w 
+      (const_cast<CoeffsMatBlockT&>(src.functor().block().left()));
+    Matrix<T, MatBlockT> in 
+      (const_cast<MatBlockT&>(src.functor().block().right().functor().block()));
+    Matrix<T, DstBlock> out(dst);
+
+    Workspace2T const& fwd_workspace(
+      src.functor().block().right().functor().workspace());
+
+    Backend2T&         fwd_backend  (const_cast<Backend2T&>(
+      src.functor().block().right().functor().backend()) );
+
+    Workspace1T const& inv_workspace(src.functor().workspace());
+    Backend1T&         inv_backend  (const_cast<Backend1T&>(src.functor().backend()));
+
+    for (index_type r=0; r<rows; ++r)
+    {
+      fwd_workspace.by_reference(&fwd_backend,
+				 in (Domain<2>(Domain<1>(r, 1, 1), cols)),
+				 tmp(Domain<2>(Domain<1>(0, 1, 1), cols)) );
+      tmp.row(0) *= w.row(r);
+      inv_workspace.by_reference(&inv_backend,
+				 tmp(Domain<2>(Domain<1>(0, 1, 1), cols)),
+				 out(Domain<2>(Domain<1>(r, 1, 1), cols)) );
+    }
+  }
+};
+
+
+
+template <typename       DstBlock,
+	  typename       T,
+	  typename       CoeffsMatBlockT,
+	  typename       MatBlockT,
+	  typename       Backend1T,
+	  typename       Workspace1T,
+	  typename       Backend2T,
+	  typename       Workspace2T>
+struct Serial_expr_evaluator<2, DstBlock,
+  const Return_expr_block<2, T,
+    fft::Fft_return_functor<2, T,
+      const Binary_expr_block<2, op::Mult,
+        const Return_expr_block<2, T,
+          fft::Fft_return_functor<2, T,
+            MatBlockT,
+            Backend2T, Workspace2T>
+        >, T, 
+        CoeffsMatBlockT, T
+      >,
+      Backend1T, Workspace1T>
+    >,
+    Fc_expr_tag
+  >
+{
+  static char const* name() { return "Fc_expr_tag"; }
+
+  typedef
+  Return_expr_block<2, T,
+    fft::Fft_return_functor<2, T,
+      const Binary_expr_block<2, op::Mult,
+        const Return_expr_block<2, T,
+          fft::Fft_return_functor<2, T,
+            MatBlockT,
+            Backend2T, Workspace2T>
+        >, T,
+        CoeffsMatBlockT, T
+      >,
+      Backend1T, Workspace1T>
+    >
+    SrcBlock;
+
+  typedef typename DstBlock::value_type dst_type;
+  typedef typename SrcBlock::value_type src_type;
+
+  static bool const ct_valid = true;
+
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    (void)dst;
+    (void)src;
+    return true;
+  }
+  
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    length_type rows = dst.size(2, 0);
+    length_type cols = dst.size(2, 1);
+    Matrix<T> tmp(1, cols);
+
+    Matrix<T, CoeffsMatBlockT> w 
+      (const_cast<CoeffsMatBlockT&>(src.functor().block().right()));
+    Matrix<T, MatBlockT> in 
+      (const_cast<MatBlockT&>(src.functor().block().left().functor().block()));
+    Matrix<T, DstBlock> out(dst);
+
+    Workspace2T const& fwd_workspace(
+      src.functor().block().left().functor().workspace());
+
+    Backend2T&         fwd_backend  (const_cast<Backend2T&>(
+      src.functor().block().left().functor().backend()) );
+
+    Workspace1T const& inv_workspace(src.functor().workspace());
+    Backend1T&         inv_backend  (const_cast<Backend1T&>(src.functor().backend()));
+
+    for (index_type r=0; r<rows; ++r)
+    {
+      fwd_workspace.by_reference(&fwd_backend,
+				 in (Domain<2>(Domain<1>(r, 1, 1), cols)),
+				 tmp(Domain<2>(Domain<1>(0, 1, 1), cols)) );
+      tmp.row(0) *= w.row(r);
+      inv_workspace.by_reference(&inv_backend,
+				 tmp(Domain<2>(Domain<1>(0, 1, 1), cols)),
+				 out(Domain<2>(Domain<1>(r, 1, 1), cols)) );
+    }
+  }
+};
+
 } // namespace vsip::impl
 
 } // namespace vsip
Index: tests/fastconv.cpp
===================================================================
--- tests/fastconv.cpp	(revision 168991)
+++ tests/fastconv.cpp	(working copy)
@@ -211,7 +211,7 @@
     for_fftm_type;
   typedef Fftm<value_type, value_type, row, fft_inv, by_value>
     inv_fftm_type;
-  int const order = O;
+  static int const order = O;
 
 public:
   template <typename B>
