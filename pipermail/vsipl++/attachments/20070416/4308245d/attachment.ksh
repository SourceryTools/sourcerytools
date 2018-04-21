Index: src/vsip/opt/cbe/ppu/eval_fastconv.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/eval_fastconv.hpp	(revision 168968)
+++ src/vsip/opt/cbe/ppu/eval_fastconv.hpp	(working copy)
@@ -14,10 +14,10 @@
   Included Files
 ***********************************************************************/
 
+#include <vsip/core/fft.hpp>
 #include <vsip/core/metaprogramming.hpp>
-#include <vsip/core/fft.hpp>
+#include <vsip/opt/cbe/ppu/fastconv.hpp>
 #include <vsip/opt/expr/return_block.hpp>
-#include <vsip/opt/cbe/ppu/fastconv.hpp>
 
 /***********************************************************************
   Declarations
@@ -77,16 +77,26 @@
   typedef typename Block_layout<DstBlock>::complex_type complex_type;
   typedef impl::cbe::Fastconv<1, T, complex_type> fconv_type;
 
-  static bool const ct_valid = Type_equal<T, std::complex<float> >::value;
+  static bool const ct_valid = 
+    Type_equal<T, std::complex<float> >::value &&
+    Type_equal<T, typename VecBlockT::value_type>::value &&
+    Type_equal<T, typename MatBlockT::value_type>::value;
 
-  static bool rt_valid(DstBlock& dst, SrcBlock const& /*src*/)
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
   {
-    return fconv_type::rt_valid_size(dst.size(2, 1));
+    Ext_data<VecBlockT> ext_kernel(src.functor().block().get_vblk());
+    Ext_data<MatBlockT> ext_in    (src.functor().block().get_mblk().functor().block());
+    Ext_data<DstBlock>  ext_out   (dst);
+
+    return 
+      fconv_type::rt_valid_size(dst.size(2, 1)) &&
+      ext_kernel.stride(0) == 1 &&
+      ext_in.stride(1) == 1 &&
+      ext_out.stride(1) == 1;
   }
   
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
-    // length_type rows = dst.size(2, 0);
     length_type cols = dst.size(2, 1);
     Matrix<T> tmp(1, cols);
 
@@ -102,6 +112,172 @@
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
+    Cbe_sdk_tag
+  >
+{
+  static char const* name() { return "Cbe_sdk_tag"; }
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
+  typedef typename Block_layout<DstBlock>::complex_type complex_type;
+  typedef impl::cbe::Fastconv_base<2, T, complex_type> fconv_type;
+
+  static bool const ct_valid = 
+    Type_equal<T, std::complex<float> >::value &&
+    Type_equal<T, typename CoeffsMatBlockT::value_type>::value &&
+    Type_equal<T, typename MatBlockT::value_type>::value &&
+    Ext_data_cost<CoeffsMatBlockT>::value == 0 &&
+    Ext_data_cost<MatBlockT>::value == 0 &&
+    Ext_data_cost<DstBlock>::value == 0;
+
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    Ext_data<CoeffsMatBlockT> ext_kernel(src.functor().block().left());
+    Ext_data<MatBlockT>       ext_in    (src.functor().block().right().functor().block());
+    Ext_data<DstBlock>        ext_out   (dst);
+
+    return 
+      fconv_type::rt_valid_size(dst.size(2, 1)) &&
+      ext_kernel.stride(1) == 1 &&
+      ext_in.stride(1) == 1 &&
+      ext_out.stride(1) == 1;
+  }
+  
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    length_type cols = dst.size(2, 1);
+    Matrix<T, CoeffsMatBlockT> w 
+      (const_cast<CoeffsMatBlockT&>(src.functor().block().left()));
+    Matrix<T, MatBlockT> in 
+      (const_cast<MatBlockT&>(src.functor().block().right().functor().block()));
+    Matrix<T, DstBlock> out(dst);
+
+    fconv_type fconv(cols, false);
+
+    fconv.convolve(in, w, out);
+  }
+};
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
+    Cbe_sdk_tag
+  >
+{
+  static char const* name() { return "Cbe_sdk_tag"; }
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
+  typedef typename Block_layout<DstBlock>::complex_type complex_type;
+  typedef impl::cbe::Fastconv_base<2, T, complex_type> fconv_type;
+
+  static bool const ct_valid = 
+    Type_equal<T, std::complex<float> >::value &&
+    Type_equal<T, typename CoeffsMatBlockT::value_type>::value &&
+    Type_equal<T, typename MatBlockT::value_type>::value &&
+    Ext_data_cost<CoeffsMatBlockT>::value == 0 &&
+    Ext_data_cost<MatBlockT>::value == 0 &&
+    Ext_data_cost<DstBlock>::value == 0;
+
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    Ext_data<CoeffsMatBlockT> ext_kernel(src.functor().block().right());
+    Ext_data<MatBlockT>       ext_in    (src.functor().block().left().functor().block());
+    Ext_data<DstBlock>        ext_out   (dst);
+
+    return 
+      fconv_type::rt_valid_size(dst.size(2, 1)) &&
+      ext_kernel.stride(1) == 1 &&
+      ext_in.stride(1) == 1 &&
+      ext_out.stride(1) == 1;
+  }
+  
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    length_type cols = dst.size(2, 1);
+    Matrix<T, CoeffsMatBlockT> w 
+      (const_cast<CoeffsMatBlockT&>(src.functor().block().right()));
+    Matrix<T, MatBlockT> in 
+      (const_cast<MatBlockT&>(src.functor().block().left().functor().block()));
+    Matrix<T, DstBlock> out(dst);
+
+    fconv_type fconv(cols, false);
+
+    fconv.convolve(in, w, out);
+  }
+};
+
 } // namespace vsip::impl
 
 } // namespace vsip
Index: src/vsip/opt/cbe/ppu/fastconv.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.hpp	(revision 168968)
+++ src/vsip/opt/cbe/ppu/fastconv.hpp	(working copy)
@@ -89,42 +89,17 @@
   typedef Layout<1, row1_type, Stride_unit_dense, complex_type> layout1_type;
   typedef Layout<2, row2_type, Stride_unit_dense, complex_type> layout2_type;
 
-  typedef Layout<dim, row2_type, 
-                 Stride_unit_dense, complex_type>   kernel_layout_type;
-  typedef Fast_block<dim, T, 
-                     kernel_layout_type, Local_map> kernel_block_type;
-
 public:
-  template <typename Block>
-  Fastconv_base(Vector<T, Block> coeffs, Domain<dim> const& input_size,
-		bool transform_kernel)
-    : kernel_          (input_size[0].size(), T()),
+  Fastconv_base(length_type const input_size, bool transform_kernel)
+    : size_            (input_size),
+      twiddle_factors_ (input_size / 4),
       transform_kernel_(transform_kernel),
-      size_            (input_size[0].size()),
-      twiddle_factors_ (input_size[0].size() / 4),
       instance_id_     (++instance_id_counter_)
   {
-    assert(rt_valid_size(size_));
-    assert(coeffs.size(0) <= size_);
-    kernel_(view_domain(coeffs)) = coeffs.local();
-    compute_twiddle_factors(input_size[0].size());
+    assert(rt_valid_size(this->size_));
+    compute_twiddle_factors(this->size_);
   }
 
-  template <typename Block>
-  Fastconv_base(Matrix<T, Block> coeffs, Domain<dim> const& input_size,
-		bool transform_kernel)
-    : kernel_          (input_size[0].size(), input_size[1].size(), T()),
-      transform_kernel_(transform_kernel),
-      size_            (input_size[1].size()),
-      twiddle_factors_ (input_size[1].size() / 4),
-      instance_id_     (++instance_id_counter_)
-  {
-    assert(rt_valid_size(size_));
-    assert(coeffs.size(1) <= size_);
-    kernel_(view_domain(coeffs)) = coeffs.local();
-    compute_twiddle_factors(input_size[1].size());
-  }
-
   static bool rt_valid_size(length_type size)
   {
     return (size >= cbe::Fastconv_traits<dim, T, complex_type>::min_size &&
@@ -132,33 +107,52 @@
 	    fft::is_power_of_two(size));
   }
 
-protected:
-  template <typename Block0, typename Block1>
-  void convolve(const_Vector<T, Block0> in, Vector<T, Block1> out)
+
+  template <typename Block0, typename Block1, typename Block2>
+  void convolve(const_Vector<T, Block0> in, const_Vector<T, Block1> kernel, Vector<T, Block2> out)
   {
-    Ext_data<Block0, layout1_type> ext_in    (in.block(),            SYNC_IN);
-    Ext_data<kernel_block_type>    ext_kernel(this->kernel_.block(), SYNC_IN);
-    Ext_data<Block1, layout1_type> ext_out   (out.block(),           SYNC_OUT);
+    Ext_data<Block0, layout1_type> ext_in    (in.block(),     SYNC_IN);
+    Ext_data<Block1, layout1_type> ext_kernel(kernel.block(), SYNC_IN);
+    Ext_data<Block2, layout1_type> ext_out   (out.block(),    SYNC_OUT);
+    assert(dim == 1);
     assert(ext_in.stride(0) == 1);
+    assert(ext_kernel.stride(0) == 1);
     assert(ext_out.stride(0) == 1);
 
     length_type rows = 1;
-    fconv(ext_in.data(), ext_kernel.data(), ext_out.data(), rows, out.size());
+    fconv(ext_in.data(), ext_kernel.data(), ext_out.data(), rows, out.size(0));
   }
 
-  template <typename Block0, typename Block1>
-  void convolve(const_Matrix<T, Block0> in, Matrix<T, Block1> out)
+  template <typename Block0, typename Block1, typename Block2>
+  void convolve(const_Matrix<T, Block0> in, const_Vector<T, Block1> kernel, Matrix<T, Block2> out)
   {
-    Ext_data<Block0, layout2_type> ext_in    (in.block(),            SYNC_IN);
-    Ext_data<kernel_block_type>    ext_kernel(this->kernel_.block(), SYNC_IN);
-    Ext_data<Block1, layout2_type> ext_out   (out.block(),           SYNC_OUT);
+    Ext_data<Block0, layout2_type> ext_in    (in.block(),     SYNC_IN);
+    Ext_data<Block1, layout1_type> ext_kernel(kernel.block(), SYNC_IN);
+    Ext_data<Block2, layout2_type> ext_out   (out.block(),    SYNC_OUT);
+    assert(dim == 1);
     assert(ext_in.stride(1) == 1);
+    assert(ext_kernel.stride(0) == 1);
     assert(ext_out.stride(1) == 1);
 
     length_type rows = in.size(0);
     fconv(ext_in.data(), ext_kernel.data(), ext_out.data(), rows, out.size(1));
   }
 
+  template <typename Block0, typename Block1, typename Block2>
+  void convolve(const_Matrix<T, Block0> in, const_Matrix<T, Block1> kernel, Matrix<T, Block2> out)
+  {
+    Ext_data<Block0, layout2_type> ext_in    (in.block(),     SYNC_IN);
+    Ext_data<Block1, layout2_type> ext_kernel(kernel.block(), SYNC_IN);
+    Ext_data<Block2, layout2_type> ext_out   (out.block(),    SYNC_OUT);
+    assert(dim == 2);
+    assert(ext_in.stride(1) == 1);
+    assert(ext_kernel.stride(1) == 1);
+    assert(ext_out.stride(1) == 1);
+
+    length_type rows = in.size(0);
+    fconv(ext_in.data(), ext_kernel.data(), ext_out.data(), rows, out.size(1));
+  }
+
   length_type size() { return size_; }
 
 private:
@@ -168,13 +162,10 @@
   void fconv(std::pair<uT*,uT*> in, std::pair<uT*,uT*> kernel,
 	     std::pair<uT*,uT*> out, length_type rows, length_type length);
 
-  typedef typename View_of_dim<D, T, kernel_block_type>::type kernel_view_type;
-
   // Member data.
-  kernel_view_type kernel_;
-  bool transform_kernel_;
   length_type size_;
   aligned_array<T> twiddle_factors_;
+  bool transform_kernel_;
   unsigned int instance_id_;
 
   // This counter is used to give each instance of this type
@@ -198,17 +189,25 @@
 public:
 
   template <typename Block>
-  Fastconv(Vector<T, Block> filter_coeffs,
+  Fastconv(Vector<T, Block> coeffs,
            length_type input_size,
 	   bool transform_kernel = true)
     VSIP_THROW((std::bad_alloc))
-    : Fastconv_base<1, T, ComplexFmt>(filter_coeffs, 
-          Domain<1>(input_size), transform_kernel)
-  {}
+    : Fastconv_base<1, T, ComplexFmt>(input_size, transform_kernel),
+      kernel_(input_size)
+  {
+    assert(coeffs.size(0) <= this->size());
+    if (transform_kernel)
+    {
+      kernel_ = T();
+      kernel_(view_domain(coeffs.local())) = coeffs.local();
+    }
+    else
+      kernel_ = coeffs.local();
+  }
   ~Fastconv() VSIP_NOTHROW {}
 
   // Fastconv operators.
-public:
   template <typename Block1,
 	    typename Block2>
   Vector<T, Block2>
@@ -220,7 +219,7 @@
     assert(in.size() == this->size());
     assert(out.size() == this->size());
     
-    this->convolve(in.local(), out.local());
+    this->convolve(in.local(), this->kernel_, out.local());
     
     return out;
   }
@@ -235,11 +234,22 @@
   {
     assert(in.size(1) == this->size());
     assert(out.size(1) == this->size());
+
+    this->convolve(in.local(), this->kernel_, out.local());
     
-    this->convolve(in.local(), out.local());
-    
     return out;
   }
+
+private:
+  typedef ComplexFmt complex_type;
+  typedef Layout<1, row1_type, 
+                 Stride_unit_dense, complex_type>   kernel_layout_type;
+  typedef Fast_block<1, T, 
+                     kernel_layout_type, Local_map> kernel_block_type;
+  typedef Vector<T, kernel_block_type>              kernel_view_type;
+
+  // Member data.
+  kernel_view_type kernel_;
 };
 
 
@@ -251,17 +261,25 @@
 public:
 
   template <typename Block>
-  Fastconv(Matrix<T, Block> filter_coeffs,
+  Fastconv(Matrix<T, Block> coeffs,
            length_type input_size,
 	   bool transform_kernel = true)
     VSIP_THROW((std::bad_alloc))
-    : Fastconv_base<2, T, ComplexFmt>(filter_coeffs, 
-          Domain<2>(filter_coeffs.size(0), input_size), transform_kernel) 
-  {}
+    : Fastconv_base<2, T, ComplexFmt>(input_size, transform_kernel),
+      kernel_(coeffs.local().size(0), input_size)
+  {
+    assert(coeffs.size(1) <= this->size());
+    if (transform_kernel)
+    {
+      kernel_ = T();
+      kernel_(view_domain(coeffs.local())) = coeffs.local();
+    }
+    else
+      kernel_ = coeffs.local();
+  }
   ~Fastconv() VSIP_NOTHROW {}
 
   // Fastconv operators.
-public:
   template <typename Block1,
 	    typename Block2>
   Vector<T, Block2>
@@ -273,7 +291,7 @@
     assert(in.size() == this->size());
     assert(out.size() == this->size());
     
-    this->convolve(in.local(), out.local());
+    this->convolve(in.local(), this->kernel_, out.local());
     
     return out;
   }
@@ -289,10 +307,21 @@
     assert(in.size(1) == this->size());
     assert(out.size(1) == this->size());
     
-    this->convolve(in.local(), out.local());
+    this->convolve(in.local(), this->kernel_, out.local());
     
     return out;
   }
+
+private:
+  // Member data.
+  typedef ComplexFmt complex_type;
+  typedef Layout<2, row2_type, 
+                 Stride_unit_dense, complex_type>   kernel_layout_type;
+  typedef Fast_block<2, T, 
+                     kernel_layout_type, Local_map> kernel_block_type;
+  typedef Matrix<T, kernel_block_type>              kernel_view_type;
+
+  kernel_view_type kernel_;
 };
 
 
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 168968)
+++ ChangeLog	(working copy)
@@ -1,3 +1,12 @@
+2007-04-16  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/opt/cbe/ppu/eval_fastconv.hpp: Added two new expression 
+	  templates for cases utilizing a matrix of coefficients.
+	* src/vsip/opt/cbe/ppu/fastconv.hpp: Reorganization to better
+	  handle coefficients.
+	* tests/fastconv.cpp: New tests for expressions.
+	* benchmarks/fastconv.cpp: New tests to evalutate performance.
+
 2007-04-16  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/mpi/services.hpp (Mpi_datatype<bool>): Use MPI_BYTE
Index: tests/fastconv.cpp
===================================================================
--- tests/fastconv.cpp	(revision 168968)
+++ tests/fastconv.cpp	(working copy)
@@ -56,7 +56,10 @@
 // Fused fft, vmul, inv_fft calls.
 struct fused;
 // Fused fftm, vmmul, inv_fftm calls.
-struct fused_multi;
+struct fused_v_multi;
+// Fused fftm, matmul, inv_fftm calls.
+template <int O>  // order in which weights are multiplied
+struct fused_m_multi;
 // Explicit Fastconv calls:
 //   with fused fftm, vmmul, inv_fftm
 template <bool W>   // transform weights early
@@ -170,7 +173,7 @@
 };
 
 template <typename T>
-class Fast_convolution<std::complex<T>, fused_multi>
+class Fast_convolution<std::complex<T>, fused_v_multi>
 {
   typedef std::complex<T> value_type;
   typedef Fftm<value_type, value_type, row, fft_fwd, by_value>
@@ -199,6 +202,41 @@
   inv_fftm_type inv_fftm_;
 };
 
+template <typename T,
+          int      O> // order: 0 == W * fft, 1 == fft * W
+class Fast_convolution<std::complex<T>, fused_m_multi<O> >
+{
+  typedef std::complex<T> value_type;
+  typedef Fftm<value_type, value_type, row, fft_fwd, by_value>
+    for_fftm_type;
+  typedef Fftm<value_type, value_type, row, fft_inv, by_value>
+    inv_fftm_type;
+  int const order = O;
+
+public:
+  template <typename B>
+  Fast_convolution(const_Matrix<value_type, B> weights)
+    : weights_(t2f(weights)),
+      for_fftm_(Domain<2>(weights.size(0), weights.size(1)), 1.),
+      inv_fftm_(Domain<2>(weights.size(0), weights.size(1)), 1./weights.size(1))
+  {}
+
+  template <typename Block1, typename Block2>
+  void operator()(const_Matrix<value_type, Block1> in,
+                  Matrix<value_type, Block2> out)
+  {
+    if (order == 0)
+      out = inv_fftm_(weights_ * for_fftm_(in));
+    else
+      out = inv_fftm_(for_fftm_(in) * weights_);
+  }
+
+private:
+  Matrix<value_type> weights_;
+  for_fftm_type for_fftm_;
+  inv_fftm_type inv_fftm_;
+};
+
 #if VSIP_IMPL_CBE_SDK
 // Both of the direct methods perform multiple convolutions.
 // In the second case, the weights are unique for each row as well, so
@@ -218,6 +256,13 @@
   {}
 
   template <typename Block1, typename Block2>
+  void operator()(const_Vector<value_type, Block1> in,
+                  Vector<value_type, Block2> out)
+  {
+    fastconv_(in, out);
+  }
+
+  template <typename Block1, typename Block2>
   void operator()(const_Matrix<value_type, Block1> in,
                   Matrix<value_type, Block2> out)
   {
@@ -280,6 +325,34 @@
 
 
 template <typename O, typename B, typename T>
+void test_shift_v(Domain<1> const &dom, length_type shift, T scale)
+{
+  assert(dom.size() > shift);
+  // Construct a shift kernel.
+  Vector<T> weights(dom.size(), T(0.));
+  weights.put(shift, scale);
+  Fast_convolution<T, B> fconv(weights);
+  // This logic assumes T is a complex type.
+  // Refine once we support real-valued fastconv.
+  Matrix<T, Dense<2, T, O> > input(dom.size(), dom.size());
+  for (size_t r = 0; r != dom.size(); ++r)
+    input.row(r) = ramp(0., 1., dom.size());
+  Matrix<T, Dense<2, T, O> > output(dom.size(), dom.size());
+  for (size_t r = 0; r != dom.size(); ++r)  
+    fconv(input.row(r), output.row(r));
+  double error = error_db
+    (scale * input(Domain<2>(dom.size(), (Domain<1>(0, 1, dom.size() - shift)))),
+     output(Domain<2>(dom.size(), (Domain<1>(shift, 1, dom.size() - shift)))));
+  if (error >= -100)
+  {
+    std::cout << "input" << input << std::endl;
+    std::cout << "output" << output << std::endl;
+  }
+  test_assert(error < -100);
+}
+
+
+template <typename O, typename B, typename T>
 void test_shift_m(Domain<1> const &dom, length_type shift, T scale)
 {
   assert(dom.size() > shift);
@@ -311,13 +384,29 @@
 {
   vsipl init(argc, argv);
 
+  // Test...
+
+  // ... using a vector of coefficients,
+  //    - inidividual operations, one row at a time
   test_shift<row2_type, separate>(16, 2, std::complex<float>(2.));
+  //    - inidividual operations, multiple rows at a time
   test_shift<row2_type, separate_multi>(16, 2, std::complex<float>(2.));
+  //    - combined operations, one row at a time
   test_shift<row2_type, fused>(16, 2, std::complex<float>(2.));
-  test_shift<row2_type, fused_multi>(64, 2, std::complex<float>(2.));
+  //    - combined operations, multiple rows at a time
+  test_shift<row2_type, fused_v_multi>(64, 2, std::complex<float>(2.));
+
+  // ... using a matrix of coefficients,
+  //    - multiple rows at a time, coeffs * fft() order
+  test_shift_m<row2_type, fused_m_multi<0> >(64, 2, std::complex<float>(2.));
+  //    - multiple rows at a time, fft() * coeffs order
+  test_shift_m<row2_type, fused_m_multi<1> >(64, 2, std::complex<float>(2.));
+
 #if VSIP_IMPL_CBE_SDK
   test_shift<row2_type, direct_vmmul<false> >(64, 2, std::complex<float>(0.5));
   test_shift<row2_type, direct_vmmul<true> >(64, 2, std::complex<float>(0.5));
+  test_shift_v<row2_type, direct_vmmul<false> >(64, 2, std::complex<float>(0.5));
+  test_shift_v<row2_type, direct_vmmul<true> >(64, 2, std::complex<float>(0.5));
   test_shift_m<row2_type, direct_mmmul<false> >(64, 2, std::complex<float>(0.5));
   test_shift_m<row2_type, direct_mmmul<true> >(64, 2, std::complex<float>(0.5));
 #endif
Index: benchmarks/fastconv.cpp
===================================================================
--- benchmarks/fastconv.cpp	(revision 168968)
+++ benchmarks/fastconv.cpp	(working copy)
@@ -31,12 +31,6 @@
 using namespace vsip;
 
 
-#ifdef VSIP_IMPL_SOURCERY_VPP
-#  define PARALLEL_FASTCONV 1
-#else
-#  define PARALLEL_FASTCONV 0
-#endif
-
 /***********************************************************************
   Common definitions
 ***********************************************************************/
@@ -50,7 +44,8 @@
 struct Impl2ip_tmp;	// in-place (w/tmp), interleaved fast-convolution
 struct Impl2fv;		// foreach_vector, interleaved fast-convolution
 struct Impl3;		// Mixed fast-convolution
-struct Impl4;		// Single-line fast-convolution
+struct Impl4vc;		// Single-line fast-convolution, vector of coeffs
+struct Impl4mc;		// Single-line fast-convolution, matrix of coeffs
 
 struct Impl1pip2_nopar;
 
@@ -491,7 +486,7 @@
       inv_fft(tmp, LOCAL(chk).row(p));
     }
 
-    double error = error_db(data, chk);
+    double error = error_db(LOCAL(data), LOCAL(chk));
 
     test_assert(error < -100);
   }
@@ -591,7 +586,7 @@
       inv_fft(LOCAL(data).row(p));
     }
 
-    double error = error_db(data, chk);
+    double error = error_db(LOCAL(data), LOCAL(chk));
 
     test_assert(error < -100);
   }
@@ -842,11 +837,11 @@
 
 
 /***********************************************************************
-  Impl4: Single expression fast-convolution.
+  Impl4vc: Single expression fast-convolution, vector of coefficients.
 ***********************************************************************/
 
 template <typename T>
-struct t_fastconv_base<T, Impl4> : fastconv_ops
+struct t_fastconv_base<T, Impl4vc> : fastconv_ops
 {
   static length_type const num_args = 1;
 
@@ -924,7 +919,7 @@
 
     chk = inv_fftm(vmmul<0>(replica, for_fftm(data)));
 
-    double error = error_db(data, chk);
+    double error = error_db(LOCAL(data), LOCAL(chk));
 
     test_assert(error < -100);
 
@@ -963,6 +958,133 @@
 
 
 /***********************************************************************
+  Impl4mc: Single expression fast-convolution, matrix of coefficients.
+***********************************************************************/
+
+template <typename T>
+struct t_fastconv_base<T, Impl4mc> : fastconv_ops
+{
+  // This operation is in-place, however the coefficients are unique 
+  // for each row, therefore they constitute a second argument.
+  static length_type const num_args = 2;
+
+#if PARALLEL_FASTCONV
+  typedef Map<Block_dist, Whole_dist>      map_type;
+  typedef Dense<2, T, row2_type, map_type> block_type;
+  typedef Matrix<T, block_type>            view_type;
+  typedef view_type                        replica_view_type;
+#else
+  typedef Local_map  map_type;
+  typedef Matrix<T>  view_type;
+  typedef view_type  replica_view_type;
+#endif
+
+  // static int const no_times = 0; // FFTW_PATIENT
+  static int const no_times = 15; // not > 12 = FFT_MEASURE
+    
+  typedef Fftm<T, T, row, fft_fwd, by_value, no_times>
+               for_fftm_type;
+  typedef Fftm<T, T, row, fft_inv, by_value, no_times>
+	       inv_fftm_type;
+
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+#if PARALLEL_FASTCONV
+    processor_type np = num_processors();
+    map_type map = map_type(Block_dist(np), Whole_dist());
+#else
+    map_type map;
+#endif
+
+    // Create the data cube.
+    view_type data(npulse, nrange, map);
+    view_type chk(npulse, nrange, map);
+    
+    // Create the pulse replica
+    replica_view_type replica(npulse, nrange, map);
+
+    // Create the FFT objects.
+    for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+    inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/nrange);
+
+    // Initialize
+    data    = T();
+    replica = T();
+
+
+    // Before fast convolution, convert the replica into the
+    // frequency domain
+    // for_fft(replica);
+    
+    vsip::impl::profile::Timer t1;
+
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      data = inv_fftm(replica * for_fftm(data));
+    }
+    t1.stop();
+
+    time = t1.delta();
+
+    // CHECK RESULT
+    typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times>
+	  	for_fft_type;
+
+    Rand<T> gen(0, 0);
+    for_fft_type for_fft(Domain<1>(nrange), 1.0);
+    Vector<T> tmp(nrange);
+
+    data = gen.randu(npulse, nrange);
+    length_type l_npulse  = LOCAL(data).size(0);
+    for (index_type p = 0; p < l_npulse; ++p)
+    {
+      replica.put(p, 0, T(1));
+      for_fft(LOCAL(replica).row(p), tmp);
+      LOCAL(replica).row(p) = tmp;
+    }
+
+    chk = inv_fftm(replica * for_fftm(data));
+
+    double error = error_db(LOCAL(data), LOCAL(chk));
+
+    test_assert(error < -100);
+  }
+
+  void diag()
+  {
+#if PARALLEL_FASTCONV
+    processor_type np = num_processors();
+    map_type map = map_type(Block_dist(np), Whole_dist());
+#else
+    map_type map;
+#endif
+
+    length_type npulse = 16;
+    length_type nrange = 2048;
+
+    // Create the data cube.
+    view_type data(npulse, nrange, map);
+
+    // Create the pulse replica
+    replica_view_type replica(npulse, nrange, map);
+
+    // Create the FFT objects.
+    for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+    inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/nrange);
+
+    vsip::impl::diagnose_eval_dispatch(
+      data, inv_fftm(replica * for_fftm(data)) );
+    vsip::impl::diagnose_eval_list_std(
+      data, inv_fftm(replica * for_fftm(data)) );
+  }
+};
+
+
+
+/***********************************************************************
   Benchmark Driver
 ***********************************************************************/
 
@@ -995,9 +1117,9 @@
   case  6: loop(t_fastconv_pf<complex<float>, Impl2ip>(param1)); break;
   case  7: loop(t_fastconv_pf<complex<float>, Impl2ip_tmp>(param1)); break;
   case  8: loop(t_fastconv_pf<complex<float>, Impl2fv>(param1)); break;
-  case  9: loop(t_fastconv_pf<complex<float>, Impl4>(param1)); break;
+  case  9: loop(t_fastconv_pf<complex<float>, Impl4vc>(param1)); break;
+  case 10: loop(t_fastconv_pf<complex<float>, Impl4mc>(param1)); break;
 
-
   case 11: loop(t_fastconv_rf<complex<float>, Impl1op>(param1)); break;
   case 12: loop(t_fastconv_rf<complex<float>, Impl1ip>(param1)); break;
   case 13: loop(t_fastconv_rf<complex<float>, Impl1pip1>(param1)); break;
@@ -1006,7 +1128,8 @@
   case 16: loop(t_fastconv_rf<complex<float>, Impl2ip>(param1)); break;
   case 17: loop(t_fastconv_rf<complex<float>, Impl2ip_tmp>(param1)); break;
   case 18: loop(t_fastconv_rf<complex<float>, Impl2fv>(param1)); break;
-  case 19: loop(t_fastconv_rf<complex<float>, Impl4>(param1)); break;
+  case 19: loop(t_fastconv_rf<complex<float>, Impl4vc>(param1)); break;
+  case 20: loop(t_fastconv_rf<complex<float>, Impl4mc>(param1)); break;
 
   case 101: loop(t_fastconv_pf<complex<float>, Impl1pip2_nopar>(param1)); break;
 
@@ -1025,7 +1148,8 @@
       << "   -6 -- In-place, interleaved\n"
       << "   -7 -- In-place (w/tmp), interleaved\n"
       << "   -8 -- Foreach_vector, interleaved (2fv)\n"
-      << "   -9 -- Fused expression (4)\n"
+      << "   -9 -- Fused expression, vector of coefficients (4vc)\n"
+      << "  -10 -- Fused expression, matrix of coefficients (4mc)\n"
       << " Sweeping number of pulses:\n"
       << "  -11 -- Out-of-place, phased\n"
       << "  -12 -- In-place, phased\n"
@@ -1034,7 +1158,9 @@
       << "  -15 -- Out-of-place, interleaved\n"
       << "  -16 -- In-place, interleaved\n"
       << "  -17 -- In-place (w/tmp), interleaved\n"
-      << "  -19 -- Fused expression (4)\n"
+      << "  -18 -- Foreach_vector, interleaved (2fv)\n"
+      << "  -19 -- Fused expression, vector of coefficients (4vc)\n"
+      << "  -20 -- Fused expression, matrix of coefficients (4mc)\n"
       ;
 
   default: return 0;
