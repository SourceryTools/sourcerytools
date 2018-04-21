Index: ChangeLog
===================================================================
--- ChangeLog	(revision 156639)
+++ ChangeLog	(working copy)
@@ -1,3 +1,72 @@
+2006-12-06  Jules Bergmann  <jules@codesourcery.com>
+
+	Reorganize extdata for ref-impl:
+	* src/vsip/core/extdata.hpp: New file, basic data access goes in
+	  core, plus high-level wrappers.
+	* src/vsip/opt/extdata.hpp: flexible data access stays in opt.
+	* src/vsip/core/extdata_common.hpp: New file, commont bits.
+
+	Use Ext_data instead of Rt_ext_data in ref-impl:
+	* src/vsip/core/fft/ct_workspace.cpp: New workspace impl that
+	  uses Ext_data instead of Rt_ext_data.
+	* src/vsip/core/fft.hpp: Use Ct_workspace for ref-impl.
+	* src/vsip/core/cvsip/fft.cpp: Handle non-unit strides.
+	  Rename VSIP_IMPL_CVSIP_HAS_{FLOAT,DOUBLE} to _HAVE_.
+
+	Hardwire solver dispatch for ref-impl:
+	* src/vsip/core/solver/svd.hpp: Hardware dispatch for ref-impl.
+	* src/vsip/core/solver/cholesky.hpp: Likewise.
+	* src/vsip/core/solver/qr.hpp: Likewise.
+	* src/vsip/core/solver/common.hpp: Fix dispatch to work with empty
+	  list.
+	
+	* src/vsip/core/vmmul.hpp: Disable vmmul evaluator in ref-impl.
+
+	Cleanup includes.
+	* src/vsip/dense.hpp: Include core/extdata instead of opt/extdata.
+	* src/vsip/core/signal/fir.hpp: Likewise.
+	* src/vsip/core/fast_block.hpp: Likewise.
+	* src/vsip/opt/sal/eval_threshold.hpp: Likewise.
+	* src/vsip/opt/sal/eval_vcmp.hpp: Likewise.
+	* src/vsip/opt/sal/eval_util.hpp: Likewise.
+	* src/vsip/opt/sal/eval_elementwise.hpp: Likewise.
+	* src/vsip/opt/rt_extdata.hpp:: Likewise.
+	* src/vsip/opt/us_block.hpp: Likewise.
+	* src/vsip/opt/ipp/bindings.hpp: Likewise.
+	* src/vsip/opt/extdata_local.hpp: Likewise.
+	* src/vsip/opt/simd/expr_evaluator.hpp: Likewise.
+	* src/vsip/opt/simd/eval_generic.hpp: Likewise.
+	* src/vsip/opt/expr/serial_evaluator.hpp: Likewise.
+	* src/vsip/opt/expr/eval_dense.hpp: Likewise.
+	* src/vsip_csl/matlab_bin_formatter.hpp: Likewise.
+	* src/vsip_csl/plainblock.hpp: Likewise.
+	
+	* src/vsip/opt/block_copy.hpp: Split Block_fill into ...
+	* src/vsip/core/block_fill.hpp: ... here.
+	* src/vsip/vector.hpp: Include new Block_fill header.
+	
+	* configure.ac (VSIP_IMPL_PROVIDE_FFT_*): New macros to hint
+	  at what FFT types are supported.
+	  Rename VSIP_IMPL_CVSIP_HAS_{FLOAT,DOUBLE} to _HAVE_.
+	* tests/fftm.cpp: Add verbose macro.  Pay attention to
+	  VSIP_IMPL_PROVIDE_FFT_{*}
+	* tests/fft.cpp: Pay attention to VSIP_IMPL_PROVIDE_FFT_{*}
+	* src/vsip/core/cvsip/block.hpp: Rename
+	  VSIP_IMPL_CVSIP_HAS_{FLOAT,DOUBLE} to _HAVE_.
+	* src/vsip/core/cvsip/view.hpp: Likewise.
+	* src/vsip/core/cvsip/fft.hpp: Likewise.
+	* src/vsip/core/cvsip/matvec.hpp: Likewise.
+	
+	* tests/random.cpp: Move explicit cvsip bits into namespace
+	  to avoid conflict with real cvsip.
+	
+	* src/vsip/core/mpi/services.hpp (Mpi_datatype): Add specializations
+	  for {signed,unsigned} char.
+	
+	* src/vsip/core/signal/fir_backend.hpp: Fix Wall warning, not
+	  initializing base class in copy constructor.
+	* src/vsip/opt/dispatch.hpp: Fix Wall warning.
+	
 2006-12-05  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/parallel/expr.hpp: Add missing size(dim, d)
Index: src/vsip/dense.hpp
===================================================================
--- src/vsip/dense.hpp	(revision 156639)
+++ src/vsip/dense.hpp	(working copy)
@@ -22,7 +22,7 @@
 #include <vsip/core/refcount.hpp>
 #include <vsip/core/parallel/local_map.hpp>
 #include <vsip/core/layout.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/block_traits.hpp>
 #include <vsip/core/parallel/choose_dist_block.hpp>
 #include <vsip/domain.hpp>
Index: src/vsip/vector.hpp
===================================================================
--- src/vsip/vector.hpp	(revision 156639)
+++ src/vsip/vector.hpp	(working copy)
@@ -29,6 +29,7 @@
 #include <vsip/core/view_traits.hpp>
 #include <vsip/core/dispatch_assign.hpp>
 #include <vsip/core/lvalue_proxy.hpp>
+#include <vsip/core/block_fill.hpp>
 
 /***********************************************************************
   Declarations
Index: src/vsip/core/fft/ct_workspace.hpp
===================================================================
--- src/vsip/core/fft/ct_workspace.hpp	(revision 0)
+++ src/vsip/core/fft/ct_workspace.hpp	(revision 0)
@@ -0,0 +1,259 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/fft/ct_workspace.cpp
+    @author  Stefan Seefeld
+    @date    2006-11-30
+    @brief   VSIPL++ Library: FFT common infrastructure used by all 
+    implementations.
+*/
+
+#ifndef VSIP_CORE_FFT_CT_WORKSPACE_HPP
+#define VSIP_CORE_FFT_CT_WORKSPACE_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/core/fft/backend.hpp>
+#include <vsip/core/view_traits.hpp>
+#include <vsip/core/adjust_layout.hpp>
+#include <vsip/core/allocation.hpp>
+#include <vsip/core/equal.hpp>
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace fft
+{
+
+template <typename InT,
+	  typename OutT>
+struct Select_fft_size
+{
+  static length_type exec(length_type /*in_size*/, length_type out_size)
+  { return out_size; }
+};
+
+template <typename T>
+struct Select_fft_size<T, std::complex<T> >
+{
+  static length_type exec(length_type in_size, length_type /*out_size*/)
+  { return in_size; }
+};
+
+template <typename InT,
+	  typename OutT>
+inline length_type
+select_fft_size(length_type in_size, length_type out_size)
+{
+  return Select_fft_size<InT, OutT>::exec(in_size, out_size);
+}
+
+
+
+/// This provides the temporary data as well as the
+/// conversion logic from blocks to arrays as expected
+/// by fft backends.
+template <dimension_type D, typename I, typename O>
+class Ct_workspace;
+
+template <typename InT,
+	  typename OutT>
+class Ct_workspace<1, InT, OutT>
+{
+  typedef typename Scalar_of<OutT>::type scalar_type;
+
+public:
+  template <typename BE>
+  Ct_workspace(BE* /*backend*/, Domain<1> const &in, Domain<1> const &out,
+	       scalar_type scale)
+    : scale_(scale),
+      input_buffer_(in.size()),
+      output_buffer_(out.size())
+  {
+  }
+  
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference(BE *backend,
+		    const_Vector<InT, Block0>& in,
+		    Vector<OutT, Block1>& out)
+  {
+    {
+      Ext_data<Block0> in_ext (in.block(),  SYNC_IN);
+      Ext_data<Block1> out_ext(out.block(), SYNC_OUT);
+
+      backend->by_reference(
+		in_ext.data(),  in_ext.stride(0),
+		out_ext.data(), out_ext.stride(0),
+		select_fft_size<InT, OutT>(in_ext.size(0), out_ext.size(0)));
+    }
+
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, scalar_type(1.)))
+      out *= scale_;
+  }
+
+  template <typename BE, typename BlockT>
+  void in_place(BE *backend, Vector<OutT, BlockT> inout)
+  {
+    {
+      // Create a 'direct data accessor', adjusting the block layout if
+      // necessary.
+      Ext_data<BlockT> inout_ext(inout.block(), SYNC_INOUT); // input_buffer_.get());
+    
+      // Call the backend.
+      backend->in_place(inout_ext.data(),
+			inout_ext.stride(0), inout_ext.size(0));
+    }
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, scalar_type(1.)))
+      inout *= scale_;
+  }
+
+private:
+  scalar_type scale_;
+  aligned_array<InT> input_buffer_;
+  aligned_array<OutT> output_buffer_;
+};
+
+
+
+template <typename InT,
+	  typename OutT>
+class Ct_workspace<2, InT, OutT>
+{
+  typedef typename Scalar_of<OutT>::type scalar_type;
+
+public:
+  template <typename BE>
+  Ct_workspace(BE* /*backend*/, Domain<2> const &in, Domain<2> const &out,
+	       scalar_type scale)
+    : scale_(scale),
+      input_buffer_(in.size()),
+      output_buffer_(out.size())
+  {
+  }
+  
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference(BE *backend,
+		    const_Matrix<InT, Block0> in,
+		    Matrix<OutT, Block1> out)
+  {
+    {
+      Ext_data<Block0> in_ext (in.block(),  SYNC_IN);
+      Ext_data<Block1> out_ext(out.block(), SYNC_OUT);
+
+      backend->by_reference(
+		in_ext.data(),  in_ext.stride(0),  in_ext.stride(1),
+		out_ext.data(), out_ext.stride(0), out_ext.stride(1),
+		select_fft_size<InT, OutT>(in_ext.size(0), out_ext.size(0)),
+		select_fft_size<InT, OutT>(in_ext.size(1), out_ext.size(1)));
+    }
+
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, scalar_type(1.)))
+      out *= scale_;
+  }
+
+  template <typename BE, typename BlockT>
+  void in_place(BE *backend, Matrix<OutT, BlockT> inout)
+  {
+    {
+      // Create a 'direct data accessor', adjusting the block layout if
+      // necessary.
+      Ext_data<BlockT> inout_ext(inout.block(), SYNC_INOUT); // FIXME (split): input_buffer_.get());
+    
+      // Call the backend.
+      backend->in_place(inout_ext.data(),
+			inout_ext.stride(0), inout_ext.stride(1),
+			inout_ext.size(0), inout_ext.size(1));
+    }
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, scalar_type(1.)))
+      inout *= scale_;
+  }
+
+private:
+  scalar_type scale_;
+  aligned_array<InT> input_buffer_;
+  aligned_array<OutT> output_buffer_;
+};
+
+
+template <typename InT,
+	  typename OutT>
+class Ct_workspace<3, InT, OutT>
+{
+  typedef typename Scalar_of<OutT>::type scalar_type;
+
+public:
+  template <typename BE>
+  Ct_workspace(BE* /*backend*/, Domain<3> const &in, Domain<3> const &out,
+	       scalar_type scale)
+    : scale_(scale),
+      input_buffer_(in.size()),
+      output_buffer_(out.size())
+  {
+  }
+  
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference(BE *backend,
+		    const_Tensor<InT, Block0> in,
+		    Tensor<OutT, Block1> out)
+  {
+    {
+      Ext_data<Block0> in_ext (in.block(),  SYNC_IN);
+      Ext_data<Block1> out_ext(out.block(), SYNC_OUT);
+
+      backend->by_reference(
+		in_ext.data(), 
+		in_ext.stride(0), in_ext.stride(1), in_ext.stride(2),
+		out_ext.data(),
+		out_ext.stride(0), out_ext.stride(1), out_ext.stride(2),
+		select_fft_size<InT, OutT>(in_ext.size(0), out_ext.size(0)),
+		select_fft_size<InT, OutT>(in_ext.size(1), out_ext.size(1)),
+		select_fft_size<InT, OutT>(in_ext.size(2), out_ext.size(2)));
+    }
+
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, scalar_type(1.)))
+      out *= scale_;
+  }
+
+  template <typename BE, typename BlockT>
+  void in_place(BE *backend, Vector<OutT, BlockT> inout)
+  {
+    {
+      // Create a 'direct data accessor', adjusting the block layout if
+      // necessary.
+      Ext_data<BlockT> inout_ext(inout.block(), SYNC_INOUT,
+				 input_buffer_.get());
+    
+      // Call the backend.
+      backend->in_place(
+		inout_ext.data(),
+		inout_ext.stride(0), inout_ext.stride(1), inout_ext.stride(2),
+		inout_ext.size(0), inout_ext.size(1), inout_ext.size(2));
+    }
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, scalar_type(1.)))
+      inout *= scale_;
+  }
+
+private:
+  scalar_type scale_;
+  aligned_array<InT> input_buffer_;
+  aligned_array<OutT> output_buffer_;
+};
+
+} // namespace vsip::impl::fft
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif
Index: src/vsip/core/cvsip/block.hpp
===================================================================
--- src/vsip/core/cvsip/block.hpp	(revision 156639)
+++ src/vsip/core/cvsip/block.hpp	(working copy)
@@ -33,7 +33,7 @@
 
 template <typename T> struct Block_traits;
 
-#if VSIP_IMPL_CVSIP_HAS_FLOAT
+#if VSIP_IMPL_CVSIP_HAVE_FLOAT
 template <>
 struct Block_traits<float>
 {
@@ -110,7 +110,7 @@
 };
 
 #endif
-#if VSIP_IMPL_CVSIP_HAS_DOUBLE
+#if VSIP_IMPL_CVSIP_HAVE_DOUBLE
 
 template <>
 struct Block_traits<double>
Index: src/vsip/core/cvsip/fft.cpp
===================================================================
--- src/vsip/core/cvsip/fft.cpp	(revision 156639)
+++ src/vsip/core/cvsip/fft.cpp	(working copy)
@@ -31,7 +31,7 @@
 
 template <dimension_type D, typename T, int E> struct FFT_traits;
 
-#if VSIP_IMPL_CVSIP_HAS_FLOAT
+#if VSIP_IMPL_CVSIP_HAVE_FLOAT
 template <int E>
 struct FFT_traits<1, std::complex<float>, E>
 {
@@ -74,7 +74,7 @@
 };
 
 #endif
-#if VSIP_IMPL_CVSIP_HAS_DOUBLE
+#if VSIP_IMPL_CVSIP_HAVE_DOUBLE
 
 template <int E>
 struct FFT_traits<1, std::complex<double>, E>
@@ -139,23 +139,21 @@
   typedef FFT_traits<1, std::complex<T>, E> traits;
 
 public:
-  Fft_impl(Domain<1> const &d, rtype scale, unsigned int n, int h)
+  Fft_impl(Domain<1> const &d, rtype scale, unsigned int n, int /*h*/)
     : impl_(traits::create(d.size(), scale, n))
   {}
   ~Fft_impl() { traits::destroy(impl_);}
   virtual bool supports_scale() { return true;}
   virtual void in_place(ctype *inout, stride_type stride, length_type length)
   {
-    assert(stride == 1);
-    View<1, ctype> input(inout, length);
+    View<1, ctype> input(inout, 0, stride, length);
     View<1, ctype, false> output(length);
     traits::call(impl_, input.ptr(), output.ptr());
     input = output;
   }
   virtual void in_place(ztype inout, stride_type stride, length_type length)
   {
-    assert(stride == 1);
-    View<1, ctype> input(inout, length);
+    View<1, ctype> input(inout, 0, stride, length);
     View<1, ctype, false> output(length);
     traits::call(impl_, input.ptr(), output.ptr());
     input = output;
@@ -164,18 +162,16 @@
 			    ctype *out, stride_type out_stride,
 			    length_type length)
   {
-    assert(in_stride == 1 && out_stride == 1);
-    View<1, ctype> input(in, length);
-    View<1, ctype> output(out, length);
+    View<1, ctype> input(in, 0, in_stride, length);
+    View<1, ctype> output(out, 0, out_stride, length);
     traits::call(impl_, input.ptr(), output.ptr());
   }
   virtual void by_reference(ztype in, stride_type in_stride,
 			    ztype out, stride_type out_stride,
 			    length_type length)
   {
-    assert(in_stride == 1 && out_stride == 1);
-    View<1, ctype> input(in, length);
-    View<1, ctype> output(out, length);
+    View<1, ctype> input(in, 0, in_stride, length);
+    View<1, ctype> output(out, 0, out_stride, length);
     traits::call(impl_, input.ptr(), output.ptr());
   }
 
@@ -193,7 +189,7 @@
   typedef FFT_traits<1, T, -1> traits;
 
 public:
-  Fft_impl(Domain<1> const &d, rtype scale, unsigned int n, int h)
+  Fft_impl(Domain<1> const &d, rtype scale, unsigned int n, int /*h*/)
     : impl_(traits::create(d.size(), scale, n))
   {}
   ~Fft_impl() { traits::destroy(impl_);}
@@ -202,18 +198,16 @@
 			    ctype *out, stride_type out_stride,
 			    length_type length)
   {
-    assert(in_stride == 1 && out_stride == 1);
-    View<1, rtype> input(in, length);
-    View<1, ctype> output(out, length);
+    View<1, rtype> input(in, 0, in_stride, length);
+    View<1, ctype> output(out, 0, out_stride, length);
     traits::call(impl_, input.ptr(), output.ptr());
   }
   virtual void by_reference(rtype *in, stride_type in_stride,
 			    ztype out, stride_type out_stride,
 			    length_type length)
   {
-    assert(in_stride == 1 && out_stride == 1);
-    View<1, rtype> input(in, length);
-    View<1, ctype> output(out, length);
+    View<1, rtype> input(in, 0, in_stride, length);
+    View<1, ctype> output(out, 0, out_stride, length);
     traits::call(impl_, input.ptr(), output.ptr());
   }
 
@@ -231,7 +225,7 @@
   typedef FFT_traits<1, T, 1> traits;
 
 public:
-  Fft_impl(Domain<1> const &d, rtype scale, unsigned int n, int h)
+  Fft_impl(Domain<1> const &d, rtype scale, unsigned int n, int /*h*/)
     : impl_(traits::create(d.size(), scale, n))
   {}
   ~Fft_impl() { traits::destroy(impl_);}
@@ -240,18 +234,16 @@
 			    rtype *out, stride_type out_stride,
 			    length_type length)
   {
-    assert(in_stride == 1 && out_stride == 1);
-    View<1, ctype> input(in, length);
-    View<1, rtype> output(out, length);
+    View<1, ctype> input(in, 0, in_stride, length);
+    View<1, rtype> output(out, 0, out_stride, length);
     traits::call(impl_, input.ptr(), output.ptr());
   }
   virtual void by_reference(ztype in, stride_type in_stride,
 			    rtype *out, stride_type out_stride,
 			    length_type length)
   {
-    assert(in_stride == 1 && out_stride == 1);
-    View<1, ctype> input(in, length);
-    View<1, rtype> output(out, length);
+    View<1, ctype> input(in, 0, in_stride, length);
+    View<1, rtype> output(out, 0, out_stride, length);
     traits::call(impl_, input.ptr(), output.ptr());
   }
 
@@ -271,7 +263,7 @@
   typedef FFT_traits<1, std::complex<T>, E> traits;
 
 public:
-  Fftm_impl(Domain<2> const &dom, rtype scale, unsigned int n, int h)
+  Fftm_impl(Domain<2> const &dom, rtype scale, unsigned int n, int /*h*/)
     : impl_(traits::create(dom[A].size(), scale, n)),
       mult_(dom[1-A].size())
   {}
@@ -282,24 +274,25 @@
 			stride_type stride_r, stride_type stride_c,
 			length_type rows, length_type cols)
   {
-    stride_type stride = 1;
+    stride_type vect_stride;
+    stride_type elem_stride;
     length_type length = 0;
     if (A == 0)
     {
-      assert(stride_r == 1);
-      stride = stride_c;
+      vect_stride = stride_c;
+      elem_stride = stride_r;
       length = rows;
     }
     else
     {
-      assert(stride_c == 1);
-      stride = stride_r;
+      vect_stride = stride_r;
+      elem_stride = stride_c;
       length = cols;
     }
     View<1, ctype, false> output(length);
     for (length_type i = 0; i != mult_; ++i)
     {
-      View<1, ctype> input(inout, i * stride, 1, length);
+      View<1, ctype> input(inout, i * vect_stride, elem_stride, length);
       traits::call(impl_, input.ptr(), output.ptr());
       input = output;
     }
@@ -309,24 +302,25 @@
 			stride_type stride_r, stride_type stride_c,
 			length_type rows, length_type cols)
   {
-    stride_type stride = 1;
+    stride_type vect_stride;
+    stride_type elem_stride;
     length_type length = 0;
     if (A == 0)
     {
-      assert(stride_r == 1);
-      stride = stride_c;
+      vect_stride = stride_c;
+      elem_stride = stride_r;
       length = rows;
     }
     else
     {
-      assert(stride_c == 1);
-      stride = stride_r;
+      vect_stride = stride_r;
+      elem_stride = stride_c;
       length = cols;
     }
     View<1, ctype, false> output(length);
     for (length_type i = 0; i != mult_; ++i)
     {
-      View<1, ctype> input(inout, i * stride, 1, length);
+      View<1, ctype> input(inout, i * vect_stride, elem_stride, length);
       traits::call(impl_, input.ptr(), output.ptr());
       input = output;
     }
@@ -338,27 +332,31 @@
 			    stride_type out_stride_r, stride_type out_stride_c,
 			    length_type rows, length_type cols)
   {
-    stride_type in_stride = 1;
-    stride_type out_stride = 1;
+    stride_type in_vect_stride;
+    stride_type in_elem_stride;
+    stride_type out_vect_stride;
+    stride_type out_elem_stride;
     length_type length = 0;
     if (A == 0)
     {
-      assert(in_stride_r == 1 && out_stride_r == 1);
-      in_stride = in_stride_c;
-      out_stride = out_stride_c;
+      in_vect_stride = in_stride_c;
+      in_elem_stride = in_stride_r;
+      out_vect_stride = out_stride_c;
+      out_elem_stride = out_stride_r;
       length = rows;
     }
     else
     {
-      assert(in_stride_c == 1 && out_stride_c == 1);
-      in_stride = in_stride_r;
-      out_stride = out_stride_r;
+      in_vect_stride = in_stride_r;
+      in_elem_stride = in_stride_c;
+      out_vect_stride = out_stride_r;
+      out_elem_stride = out_stride_c;
       length = cols;
     }
     for (length_type i = 0; i != mult_; ++i)
     {
-      View<1, ctype> input(in, i * in_stride, 1, length);
-      View<1, ctype> output(out, i * out_stride, 1, length);
+      View<1, ctype> input(in, i * in_vect_stride, in_elem_stride, length);
+      View<1, ctype> output(out, i * out_vect_stride, out_elem_stride, length);
       traits::call(impl_, input.ptr(), output.ptr());
     }
   }
@@ -368,27 +366,31 @@
 			    stride_type out_stride_r, stride_type out_stride_c,
 			    length_type rows, length_type cols)
   {
-    stride_type in_stride = 1;
-    stride_type out_stride = 1;
+    stride_type in_vect_stride;
+    stride_type in_elem_stride;
+    stride_type out_vect_stride;
+    stride_type out_elem_stride;
     length_type length = 0;
     if (A == 0)
     {
-      assert(in_stride_r == 1 && out_stride_r == 1);
-      in_stride = in_stride_c;
-      out_stride = out_stride_c;
+      in_vect_stride = in_stride_c;
+      in_elem_stride = in_stride_r;
+      out_vect_stride = out_stride_c;
+      out_elem_stride = out_stride_r;
       length = rows;
     }
     else
     {
-      assert(in_stride_c == 1 && out_stride_c == 1);
-      in_stride = in_stride_r;
-      out_stride = out_stride_r;
+      in_vect_stride = in_stride_r;
+      in_elem_stride = in_stride_c;
+      out_vect_stride = out_stride_r;
+      out_elem_stride = out_stride_c;
       length = cols;
     }
     for (length_type i = 0; i != mult_; ++i)
     {
-      View<1, ctype> input(in, i * in_stride, 1, length);
-      View<1, ctype> output(out, i * out_stride, 1, length);
+      View<1, ctype> input(in, i * in_vect_stride, out_elem_stride, length);
+      View<1, ctype> output(out, i * out_vect_stride, out_elem_stride, length);
       traits::call(impl_, input.ptr(), output.ptr());
     }
   }
@@ -408,7 +410,7 @@
   typedef FFT_traits<1, T, -1> traits;
 
 public:
-  Fftm_impl(Domain<2> const &dom, rtype scale, unsigned int n, int h)
+  Fftm_impl(Domain<2> const &dom, rtype scale, unsigned int n, int /*h*/)
     : impl_(traits::create(dom[A].size(), scale, n)),
       mult_(dom[1-A].size())
   {}
@@ -421,27 +423,31 @@
 			    stride_type out_stride_r, stride_type out_stride_c,
 			    length_type rows, length_type cols)
   {
-    stride_type in_stride = 1;
-    stride_type out_stride = 1;
+    stride_type in_vect_stride;
+    stride_type in_elem_stride;
+    stride_type out_vect_stride;
+    stride_type out_elem_stride;
     length_type length = 0;
     if (A == 0)
     {
-      assert(in_stride_r == 1 && out_stride_r == 1);
-      in_stride = in_stride_c;
-      out_stride = out_stride_c;
+      in_vect_stride = in_stride_c;
+      in_elem_stride = in_stride_r;
+      out_vect_stride = out_stride_c;
+      out_elem_stride = out_stride_r;
       length = rows;
     }
     else
     {
-      assert(in_stride_c == 1 && out_stride_c == 1);
-      in_stride = in_stride_r;
-      out_stride = out_stride_r;
+      in_vect_stride = in_stride_r;
+      in_elem_stride = in_stride_c;
+      out_vect_stride = out_stride_r;
+      out_elem_stride = out_stride_c;
       length = cols;
     }
     for (length_type i = 0; i != mult_; ++i)
     {
-      View<1, rtype> input(in, i * in_stride, 1, length);
-      View<1, ctype> output(out, i * out_stride, 1, length/2+1);
+      View<1, rtype> input(in, i * in_vect_stride, in_elem_stride, length);
+      View<1, ctype> output(out, i * out_vect_stride, out_elem_stride, length/2+1);
       traits::call(impl_, input.ptr(), output.ptr());
     }
   }
@@ -451,27 +457,31 @@
 			    stride_type out_stride_r, stride_type out_stride_c,
 			    length_type rows, length_type cols)
   {
-    stride_type in_stride = 1;
-    stride_type out_stride = 1;
+    stride_type in_vect_stride;
+    stride_type in_elem_stride;
+    stride_type out_vect_stride;
+    stride_type out_elem_stride;
     length_type length = 0;
     if (A == 0)
     {
-      assert(in_stride_r == 1 && out_stride_r == 1);
-      in_stride = in_stride_c;
-      out_stride = out_stride_c;
+      in_vect_stride = in_stride_c;
+      in_elem_stride = in_stride_r;
+      out_vect_stride = out_stride_c;
+      out_elem_stride = out_stride_r;
       length = rows;
     }
     else
     {
-      assert(in_stride_c == 1 && out_stride_c == 1);
-      in_stride = in_stride_r;
-      out_stride = out_stride_r;
+      in_vect_stride = in_stride_r;
+      in_elem_stride = in_stride_c;
+      out_vect_stride = out_stride_r;
+      out_elem_stride = out_stride_c;
       length = cols;
     }
     for (length_type i = 0; i != mult_; ++i)
     {
-      View<1, rtype> input(in, i * in_stride, 1, length);
-      View<1, ctype> output(out, i * out_stride, 1, length/2+1);
+      View<1, rtype> input(in, i * in_vect_stride, in_elem_stride, length);
+      View<1, ctype> output(out, i * out_vect_stride, out_elem_stride, length/2+1);
       traits::call(impl_, input.ptr(), output.ptr());
     }
   }
@@ -491,40 +501,44 @@
   typedef FFT_traits<1, T, 1> traits;
 
 public:
-  Fftm_impl(Domain<2> const &dom, rtype scale, unsigned int n, int h)
+  Fftm_impl(Domain<2> const &dom, rtype scale, unsigned int n, int /*h*/)
     : impl_(traits::create(dom[A].size(), scale, n)),
       mult_(dom[1-A].size())
   {}
   ~Fftm_impl() { traits::destroy(impl_);}
   virtual bool supports_scale() { return true;}
 
-  virtual void by_reference(ctype *in,
+  virtual void by_reference(ctype* in,
 			    stride_type in_stride_r, stride_type in_stride_c,
 			    rtype *out,
 			    stride_type out_stride_r, stride_type out_stride_c,
 			    length_type rows, length_type cols)
   {
-    stride_type in_stride = 1;
-    stride_type out_stride = 1;
+    stride_type in_vect_stride;
+    stride_type in_elem_stride;
+    stride_type out_vect_stride;
+    stride_type out_elem_stride;
     length_type length = 0;
     if (A == 0)
     {
-      assert(in_stride_r == 1 && out_stride_r == 1);
-      in_stride = in_stride_c;
-      out_stride = out_stride_c;
+      in_vect_stride = in_stride_c;
+      in_elem_stride = in_stride_r;
+      out_vect_stride = out_stride_c;
+      out_elem_stride = out_stride_r;
       length = rows;
     }
     else
     {
-      assert(in_stride_c == 1 && out_stride_c == 1);
-      in_stride = in_stride_r;
-      out_stride = out_stride_r;
+      in_vect_stride = in_stride_r;
+      in_elem_stride = in_stride_c;
+      out_vect_stride = out_stride_r;
+      out_elem_stride = out_stride_c;
       length = cols;
     }
     for (length_type i = 0; i != mult_; ++i)
     {
-      View<1, ctype> input(in, i * in_stride, 1, length/2+1);
-      View<1, rtype> output(out, i * out_stride, 1, length);
+      View<1, ctype> input(in, i * in_vect_stride, in_elem_stride, length/2+1);
+      View<1, rtype> output(out, i * out_vect_stride, out_elem_stride, length);
       traits::call(impl_, input.ptr(), output.ptr());
     }
   }
@@ -534,27 +548,31 @@
 			    stride_type out_stride_r, stride_type out_stride_c,
 			    length_type rows, length_type cols)
   {
-    stride_type in_stride = 1;
-    stride_type out_stride = 1;
+    stride_type in_vect_stride;
+    stride_type in_elem_stride;
+    stride_type out_vect_stride;
+    stride_type out_elem_stride;
     length_type length = 0;
     if (A == 0)
     {
-      assert(in_stride_r == 1 && out_stride_r == 1);
-      in_stride = in_stride_c;
-      out_stride = out_stride_c;
+      in_vect_stride = in_stride_c;
+      in_elem_stride = in_stride_r;
+      out_vect_stride = out_stride_c;
+      out_elem_stride = out_stride_r;
       length = rows;
     }
     else
     {
-      assert(in_stride_c == 1 && out_stride_c == 1);
-      in_stride = in_stride_r;
-      out_stride = out_stride_r;
+      in_vect_stride = in_stride_r;
+      in_elem_stride = in_stride_c;
+      out_vect_stride = out_stride_r;
+      out_elem_stride = out_stride_c;
       length = cols;
     }
     for (length_type i = 0; i != mult_; ++i)
     {
-      View<1, ctype> input(in, i * in_stride, 1, length/2+1);
-      View<1, rtype> output(out, i * out_stride, 1, length);
+      View<1, ctype> input(in, i * in_vect_stride, in_elem_stride, length/2+1);
+      View<1, rtype> output(out, i * out_vect_stride, out_elem_stride, length);
       traits::call(impl_, input.ptr(), output.ptr());
     }
   }
@@ -574,13 +592,13 @@
     (new Fft_impl<D, I, O, A, E>(dom, scale, n, 0));     \
 }
 
-#if defined VSIP_IMPL_FFT_USE_FLOAT && VSIP_IMPL_CVSIP_HAS_FLOAT
+#if defined VSIP_IMPL_FFT_USE_FLOAT && VSIP_IMPL_CVSIP_HAVE_FLOAT
 VSIPL_IMPL_PROVIDE(1, std::complex<float>, std::complex<float>, 0, -1)
 VSIPL_IMPL_PROVIDE(1, std::complex<float>, std::complex<float>, 0, 1)
 VSIPL_IMPL_PROVIDE(1, float, std::complex<float>, 0, -1)
 VSIPL_IMPL_PROVIDE(1, std::complex<float>, float, 0, 1)
 #endif
-#if defined VSIP_IMPL_FFT_USE_DOUBLE && VSIP_IMPL_CVSIP_HAS_DOUBLE
+#if defined VSIP_IMPL_FFT_USE_DOUBLE && VSIP_IMPL_CVSIP_HAVE_DOUBLE
 VSIPL_IMPL_PROVIDE(1, std::complex<double>, std::complex<double>, 0, -1)
 VSIPL_IMPL_PROVIDE(1, std::complex<double>, std::complex<double>, 0, 1)
 VSIPL_IMPL_PROVIDE(1, double, std::complex<double>, 0, -1)
@@ -598,7 +616,7 @@
     (new Fftm_impl<I, O, A, E>(dom, scale, n, 0));     \
 }
 
-#if defined VSIP_IMPL_FFT_USE_FLOAT && VSIP_IMPL_CVSIP_HAS_FLOAT
+#if defined VSIP_IMPL_FFT_USE_FLOAT && VSIP_IMPL_CVSIP_HAVE_FLOAT
 VSIPL_IMPL_PROVIDE(float, std::complex<float>, 0, -1)
 VSIPL_IMPL_PROVIDE(float, std::complex<float>, 1, -1)
 VSIPL_IMPL_PROVIDE(std::complex<float>, float, 0, 1)
@@ -608,7 +626,7 @@
 VSIPL_IMPL_PROVIDE(std::complex<float>, std::complex<float>, 0, 1)
 VSIPL_IMPL_PROVIDE(std::complex<float>, std::complex<float>, 1, 1)
 #endif
-#if defined VSIP_IMPL_FFT_USE_DOUBLE && VSIP_IMPL_CVSIP_HAS_DOUBLE
+#if defined VSIP_IMPL_FFT_USE_DOUBLE && VSIP_IMPL_CVSIP_HAVE_DOUBLE
 VSIPL_IMPL_PROVIDE(double, std::complex<double>, 0, -1)
 VSIPL_IMPL_PROVIDE(double, std::complex<double>, 1, -1)
 VSIPL_IMPL_PROVIDE(std::complex<double>, double, 0, 1)
Index: src/vsip/core/cvsip/view.hpp
===================================================================
--- src/vsip/core/cvsip/view.hpp	(revision 156639)
+++ src/vsip/core/cvsip/view.hpp	(working copy)
@@ -32,7 +32,7 @@
 {
 template <dimension_type D, typename T> struct View_traits;
 
-#if VSIP_IMPL_CVSIP_HAS_FLOAT
+#if VSIP_IMPL_CVSIP_HAVE_FLOAT
 
 template <>
 struct View_traits<1, float>
@@ -103,7 +103,7 @@
 };
 
 #endif
-#if VSIP_IMPL_CVSIP_HAS_DOUBLE
+#if VSIP_IMPL_CVSIP_HAVE_DOUBLE
 
 template <>
 struct View_traits<1, double>
Index: src/vsip/core/cvsip/fft.hpp
===================================================================
--- src/vsip/core/cvsip/fft.hpp	(revision 156639)
+++ src/vsip/core/cvsip/fft.hpp	(working copy)
@@ -74,14 +74,14 @@
 struct evaluator<1, I, O, S, R, N, Cvsip_tag>
 {
   static bool const has_float =
-#if VSIP_IMPL_CVSIP_HAS_FLOAT
+#if VSIP_IMPL_CVSIP_HAVE_FLOAT
     true
 #else
     false
 #endif
     ;
   static bool const has_double =
-#if VSIP_IMPL_CVSIP_HAS_DOUBLE
+#if VSIP_IMPL_CVSIP_HAVE_DOUBLE
     true
 #else
     false
@@ -93,7 +93,7 @@
                                (has_double && 
                                 Type_equal<typename Scalar_of<I>::type,
                                            double>::value);
-  static bool rt_valid(Domain<1> const &dom) { return true;}
+  static bool rt_valid(Domain<1> const &/*dom*/) { return true;}
   static std::auto_ptr<backend<1, I, O,
 			       axis<I, O, S>::value,
 			       exponent<I, O, S>::value> >
@@ -120,7 +120,7 @@
 {
   static bool const ct_valid = !Type_equal<typename Scalar_of<I>::type,
                                            long double>::value;
-  static bool rt_valid(Domain<2> const &dom) { return true;}
+  static bool rt_valid(Domain<2> const& /*dom*/) { return true;}
   static std::auto_ptr<fft::fftm<I, O, A, E> > 
   create(Domain<2> const &dom, typename Scalar_of<I>::type scale)
   {
Index: src/vsip/core/cvsip/matvec.hpp
===================================================================
--- src/vsip/core/cvsip/matvec.hpp	(revision 156639)
+++ src/vsip/core/cvsip/matvec.hpp	(working copy)
@@ -31,7 +31,7 @@
 
 template <typename T> struct Op_traits { static bool const valid = false;};
 
-#if VSIP_IMPL_CVSIP_HAS_FLOAT
+#if VSIP_IMPL_CVSIP_HAVE_FLOAT
 template <>
 struct Op_traits<float>
 {
@@ -93,7 +93,7 @@
   { vsip_cmvprod_f(a, x, y);}
 };
 #endif
-#if VSIP_IMPL_CVSIP_HAS_DOUBLE
+#if VSIP_IMPL_CVSIP_HAVE_DOUBLE
 template <>
 struct Op_traits<double>
 {
Index: src/vsip/core/mpi/services.hpp
===================================================================
--- src/vsip/core/mpi/services.hpp	(revision 156639)
+++ src/vsip/core/mpi/services.hpp	(working copy)
@@ -74,6 +74,8 @@
 VSIP_IMPL_MPIDATATYPE(short,          MPI_SHORT)
 VSIP_IMPL_MPIDATATYPE(int,            MPI_INT)
 VSIP_IMPL_MPIDATATYPE(long,           MPI_LONG)
+VSIP_IMPL_MPIDATATYPE(signed char,    MPI_CHAR)
+VSIP_IMPL_MPIDATATYPE(unsigned char,  MPI_UNSIGNED_CHAR)
 VSIP_IMPL_MPIDATATYPE(unsigned short, MPI_UNSIGNED_SHORT)
 VSIP_IMPL_MPIDATATYPE(unsigned int,   MPI_UNSIGNED)
 VSIP_IMPL_MPIDATATYPE(unsigned long,  MPI_UNSIGNED_LONG)
Index: src/vsip/core/block_fill.hpp
===================================================================
--- src/vsip/core/block_fill.hpp	(revision 0)
+++ src/vsip/core/block_fill.hpp	(revision 0)
@@ -0,0 +1,104 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/block_fill.hpp
+    @author  Jules Bergmann
+    @date    2005-02-11
+    @brief   VSIPL++ Library: Fill block with value.
+*/
+
+#ifndef VSIP_CORE_BLOCK_FILL_HPP
+#define VSIP_CORE_BLOCK_FILL_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/layout.hpp>
+#include <vsip/core/block_traits.hpp>
+#include <vsip/core/parallel/map_traits.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+template <dimension_type Dim,
+	  typename       BlockT,
+	  typename       OrderT  = typename Block_layout<BlockT>::order_type,
+	  bool           IsGlobal = 
+			    Is_global_only<typename BlockT::map_type>::value>
+struct Block_fill;
+
+template <dimension_type Dim,
+	  typename       BlockT,
+	  typename       OrderT>
+struct Block_fill<Dim, BlockT, OrderT, true>
+{
+  typedef typename BlockT::value_type value_type;
+  static void exec(BlockT& block, value_type const& val)
+  {
+    typedef typename Distributed_local_block<BlockT>::type local_block_type;
+    typedef typename impl::View_block_storage<local_block_type>::plain_type
+		type;
+
+    if (block.map().subblock() != no_subblock)
+    {
+      // If get_local_block returns a temporary value, we need to copy it.
+      // Other (if it returns a reference), this captures it.
+      type l_block = get_local_block(block);
+      Block_fill<Dim, local_block_type>::exec(l_block, val);
+    }
+  }
+};
+
+template <typename BlockT,
+	  typename OrderT>
+struct Block_fill<1, BlockT, OrderT, false>
+{
+  typedef typename BlockT::value_type value_type;
+
+  static void exec(BlockT& block, value_type const& val)
+  {
+    for (index_type i=0; i<block.size(1, 0); ++i)
+      block.put(i, val);
+  }
+};
+
+template <typename BlockT>
+struct Block_fill<2, BlockT, row2_type, false>
+{
+  typedef typename BlockT::value_type value_type;
+
+  static void exec(BlockT& block, value_type const& val)
+  {
+    for (vsip::index_type r=0; r<block.size(2, 0); ++r)
+      for (vsip::index_type c=0; c<block.size(2, 1); ++c)
+	block.put(r, c, val);
+  }
+};
+
+template <typename BlockT>
+struct Block_fill<2, BlockT, col2_type, false>
+{
+  typedef typename BlockT::value_type value_type;
+
+  static void exec(BlockT& block, value_type const& val)
+  {
+    for (vsip::index_type c=0; c<block.size(2, 1); ++c)
+      for (vsip::index_type r=0; r<block.size(2, 0); ++r)
+	block.put(r, c, val);
+  }
+};
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_BLOCK_FILL_HPP
+
Index: src/vsip/core/extdata_common.hpp
===================================================================
--- src/vsip/core/extdata_common.hpp	(revision 0)
+++ src/vsip/core/extdata_common.hpp	(revision 0)
@@ -0,0 +1,85 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/extdata_common.hpp
+    @author  Jules Bergmann
+    @date    2006-11-29
+    @brief   VSIPL++ Library: Common Decls for Direct Data Access.
+
+*/
+
+#ifndef VSIP_CORE_EXTDATA_COMMON_HPP
+#define VSIP_CORE_EXTDATA_COMMON_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/static_assert.hpp>
+#include <vsip/core/block_traits.hpp>
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/core/layout.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+/// Enum to indicate data interface syncronization necessary for
+/// correctness.
+///
+/// SYNC_IN            - syncronize data interface on creation,
+/// SYNC_OUT           - syncronize data interface on destruction,
+/// SYNC_INOUT         - syncronize data interface on creation and destruction,
+/// SYNC_IN_NOPRESERVE - syncronize data interface on creation
+///                      with guarantee that changes are not preserved
+///                      (usually by forcing a copy).
+
+enum sync_action_type
+{
+  SYNC_IN              = 0x01,
+  SYNC_OUT             = 0x02,
+  SYNC_INOUT           = SYNC_IN | SYNC_OUT,		// 0x03
+  SYNC_NOPRESERVE_impl = 0x04,
+  SYNC_IN_NOPRESERVE   = SYNC_IN | SYNC_NOPRESERVE_impl	// 0x05
+};
+
+namespace data_access 
+{
+
+/// Low-level data access class.
+
+/// Requires:
+///   AT is a valid data access tag,
+///   BLOCK is a block that supports the data access interface indicated
+///      by AT.
+///   LP is a layout policy compatible with access tag AT and block BLOCK.
+///
+///   (Each specializtion may provide additional requirements).
+///
+/// Member Functions:
+///    ...
+///
+/// Notes:
+///  - Low_level_data_access does not hold a block reference/pointer, it
+///    is provided to each member function by the caller.  This allows
+///    the caller to make policy decisions, such as reference counting.
+
+template <typename AT,
+          typename Block,
+	  typename LP>
+class Low_level_data_access;
+
+template <typename AT> struct Cost { static int const value = 10; };
+
+} // namespace vsip::impl::data_access
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_CORE_EXTDATA_COMMON_HPP
Index: src/vsip/core/solver/svd.hpp
===================================================================
--- src/vsip/core/solver/svd.hpp	(revision 156639)
+++ src/vsip/core/solver/svd.hpp	(working copy)
@@ -60,6 +60,10 @@
 template <typename T>
 struct Choose_svd_impl
 {
+#ifdef VSIP_IMPL_REF_IMPL
+  typedef Cvsip_tag use_type;
+  typedef Cvsip_tag type;
+#else
   typedef typename Choose_solver_impl<
     Is_svd_impl_avail,
     T,
@@ -69,6 +73,7 @@
     Type_equal<type, None_type>::value,
     As_type<Error_no_solver_for_this_type>,
     As_type<type> >::type use_type;
+#endif
 };
 
 } // namespace vsip::impl
Index: src/vsip/core/solver/cholesky.hpp
===================================================================
--- src/vsip/core/solver/cholesky.hpp	(revision 156639)
+++ src/vsip/core/solver/cholesky.hpp	(working copy)
@@ -61,6 +61,10 @@
 template <typename T>
 struct Choose_chold_impl
 {
+#ifdef VSIP_IMPL_REF_IMPL
+  typedef Cvsip_tag use_type;
+  typedef Cvsip_tag type;
+#else
   typedef typename Choose_solver_impl<
     Is_chold_impl_avail,
     T,
@@ -70,6 +74,7 @@
     Type_equal<type, None_type>::value,
     As_type<Error_no_solver_for_this_type>,
     As_type<type> >::type use_type;
+#endif
 };
 
 } // namespace vsip::impl
Index: src/vsip/core/solver/qr.hpp
===================================================================
--- src/vsip/core/solver/qr.hpp	(revision 156639)
+++ src/vsip/core/solver/qr.hpp	(working copy)
@@ -63,6 +63,10 @@
 template <typename T>
 struct Choose_qrd_impl
 {
+#ifdef VSIP_IMPL_REF_IMPL
+  typedef Cvsip_tag use_type;
+  typedef Cvsip_tag type;
+#else
   typedef typename Choose_solver_impl<
     Is_qrd_impl_avail,
     T,
@@ -72,6 +76,7 @@
     Type_equal<type, None_type>::value,
     As_type<Error_no_solver_for_this_type>,
     As_type<type> >::type use_type;
+#endif
 };
 
 } // namespace vsip::impl
Index: src/vsip/core/solver/common.hpp
===================================================================
--- src/vsip/core/solver/common.hpp	(revision 156639)
+++ src/vsip/core/solver/common.hpp	(working copy)
@@ -91,6 +91,20 @@
 namespace impl
 {
 
+template <typename List>
+struct List_get
+{
+  typedef typename List::first first;
+  typedef typename List::rest  rest;
+};
+
+template <>
+struct List_get<None_type>
+{
+  typedef None_type first;
+  typedef None_type rest;
+};
+
 /// Template class to determine which tag implements a solver.
 
 /// Requires:
@@ -107,8 +121,8 @@
 template <template <typename, typename> class IsTypeAvail,
 	  typename T,
 	  typename TagList,
-	  typename Tag  = typename TagList::first,
-	  typename Rest = typename TagList::rest,
+	  typename Tag  = typename List_get<TagList>::first,
+	  typename Rest = typename List_get<TagList>::rest,
 	  bool     Valid = IsTypeAvail<Tag, T>::value>
 struct Choose_solver_impl;
 
@@ -144,6 +158,17 @@
   typedef None_type type;
 };
 
+
+/// Special terminator.  If original list is empty, define type to
+/// be None_type.
+
+template <template <typename, typename> class IsTypeAvail,
+	  typename T>
+struct Choose_solver_impl<IsTypeAvail, T, None_type, None_type, None_type, false>
+{
+  typedef None_type type;
+};
+
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/core/signal/fir.hpp
===================================================================
--- src/vsip/core/signal/fir.hpp	(revision 156639)
+++ src/vsip/core/signal/fir.hpp	(working copy)
@@ -14,7 +14,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/domain.hpp>
 #include <vsip/core/allocation.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/profile.hpp>
 #ifndef VSIP_IMPL_REF_IMPL
 # include <vsip/opt/dispatch.hpp>
Index: src/vsip/core/signal/fir_backend.hpp
===================================================================
--- src/vsip/core/signal/fir_backend.hpp	(revision 156639)
+++ src/vsip/core/signal/fir_backend.hpp	(working copy)
@@ -40,7 +40,8 @@
     output_size_ = (input_size_ + decimation_ - 1) / decimation_;
   }
   Fir_backend(Fir_backend const &fir)
-    :  input_size_(fir.input_size_),
+    :  Ref_count<Fir_backend>(),  // copy is unique, count starts at 1.
+       input_size_(fir.input_size_),
        output_size_(fir.output_size_),
        order_(fir.order_),
        decimation_(fir.decimation_)
Index: src/vsip/core/extdata.hpp
===================================================================
--- src/vsip/core/extdata.hpp	(revision 0)
+++ src/vsip/core/extdata.hpp	(revision 0)
@@ -0,0 +1,614 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/extdata.hpp
+    @author  Jules Bergmann
+    @date    2005-02-11
+    @brief   VSIPL++ Library: Core Direct Data Access.
+
+*/
+
+#ifndef VSIP_CORE_EXTDATA_HPP
+#define VSIP_CORE_EXTDATA_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/static_assert.hpp>
+#include <vsip/core/extdata_common.hpp>
+#include <vsip/core/block_traits.hpp>
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/core/layout.hpp>
+#include <vsip/core/domain_utils.hpp>
+
+#if !VSIP_IMPL_REF_IMPL
+#  include <vsip/opt/extdata.hpp>
+#endif
+#include <vsip/opt/block_copy.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+/// Reference Counting Policies.
+///
+/// A reference counting policy describes which behavior should be
+/// taken when an DDI class creates and destroys references to a block. 
+///
+/// A policy should implement two static functions:
+///  - inc() - action to perform when reference is created 
+///  - dec() - action to perform when reference is destroyed 
+///
+///
+/// The following policies are available:
+///
+///  - No_count_policy: do not increment/decrement block reference count.
+///
+///    When a DDI class is used in the same scope as another reference
+///    to the block being accessed, it is not necessary to increment
+///    the reference count.
+///
+///  - Ref_count_policy: increment/decrement block reference count.
+///
+///    When a DDI class is used in a situation where the block it
+///    references does not have a guarenteed reference.
+
+
+/// No reference count policy, indicates DDI object will not increment
+/// and decrement reference count.
+
+struct No_count_policy
+{
+  template <typename Block>
+  static void inc(Block const* /* block */) {}
+
+  template <typename Block>
+  static void dec(Block const* /* block */) {}
+};
+
+
+
+/// Reference count policy, indicates DDI object will increment and
+/// decrement reference count.
+
+struct Ref_count_policy
+{
+  template <typename Block>
+  static void inc(Block const* block) { block->increment_count(); }
+
+  template <typename Block>
+  static void dec(Block const* block) { block->decrement_count(); }
+};
+
+
+
+/// Namespace for low-level data access interfaces.  These interfaces
+/// provide low-level data access to data stored within blocks
+/// (directly or indirectly).
+
+/// These interfaces are not intended to be used in application code,
+/// or in the library implementation outside of the Ext_data class.
+/// Not all low-level interfaces are valid for all blocks, and over time
+/// details of the low-level interface may change.  To provide a
+/// consistent data interface to all blocks, the Ext_data class should
+/// be used instead.
+
+namespace data_access 
+{
+
+/// Specialization for low-level direct data access.
+
+/// Requires:
+///   BLOCK to be a block that supports direct access via member
+///     functions impl_data() and impl_stride().  Access to these
+///     members can be protected by making Low_level_data_access a friend
+///     class to the block.
+///   LP is a layout policy describing the desired layout.  It is should
+///     match the inherent layout of the block.  Specifying a layout
+///     not directly supported by the block is an error and results in
+///     undefined behavior.
+
+template <typename Block,
+	  typename LP>
+class Low_level_data_access<Direct_access_tag, Block, LP>
+{
+  // Compile time typedefs.
+public:
+  static dimension_type const dim = LP::dim;
+
+  typedef typename Block::value_type value_type;
+  typedef typename LP::order_type    order_type;
+  typedef typename LP::pack_type     pack_type;
+  typedef typename LP::complex_type  complex_type;
+
+  typedef Storage<complex_type, value_type> storage_type;
+  typedef typename storage_type::type       raw_ptr_type;
+  typedef typename storage_type::const_type const_raw_ptr_type;
+
+  // Compile- and run-time properties.
+public:
+  static int   const CT_Cost         = 0;
+  static bool  const CT_Mem_not_req  = true;
+  static bool  const CT_Xfer_not_req = true;
+
+  static int    cost         (Block const& /*block*/, LP const& /*layout*/)
+    { return CT_Cost; }
+  static size_t mem_required (Block const& /*block*/, LP const& /*layout*/)
+    { return 0; }
+  static size_t xfer_required(Block const& /*block*/, LP const& /*layout*/)
+    { return !CT_Xfer_not_req; }
+
+  // Constructor and destructor.
+public:
+  Low_level_data_access(Block&,
+			raw_ptr_type     = NULL)
+  {}
+
+  ~Low_level_data_access() {}
+
+  void begin(Block*, bool) {}
+  void end(Block*, bool) {}
+
+  int cost() const { return CT_Cost; }
+
+  // Direct data acessors.
+public:
+  raw_ptr_type 	data  (Block* blk) const
+    { return blk->impl_data(); }
+  stride_type	stride(Block* blk, dimension_type d) const
+    { return blk->impl_stride(dim, d); }
+  length_type	size  (Block* blk, dimension_type d) const
+    { return blk->size(dim, d); }
+  length_type	size  (Block* blk) const
+    { return blk->size(); }
+};
+
+
+
+/// Specialization for copied direct data access.
+
+/// Requires:
+///   BLOCK to be a block.
+///   LP is a layout policy describing the desired layout.
+///      The desired layout can be different from the block's layout.
+///
+/// Notes:
+///   When the desired layout packing format is either Stride_unit or
+///   Stride_unknown, the packing format used will be Stride_unit_dense.
+
+template <typename Block,
+	  typename LP>
+class Low_level_data_access<Copy_access_tag, Block, LP>
+{
+  // Compile time typedefs.
+public:
+  static dimension_type const dim = LP::dim;
+
+  typedef typename Block::value_type value_type;
+  typedef typename LP::order_type    order_type;
+  typedef typename
+          ITE_Type<Type_equal<typename LP::pack_type, Stride_unit>::value ||
+	           Type_equal<typename LP::pack_type, Stride_unknown>::value,
+                   As_type<Stride_unit_dense>,
+		   As_type<typename LP::pack_type> >::type pack_type;
+  typedef typename LP::complex_type  complex_type;
+
+  typedef Layout<dim, order_type, pack_type, complex_type> actual_layout_type;
+
+  typedef Allocated_storage<complex_type, value_type> storage_type;
+  typedef typename storage_type::type                 raw_ptr_type;
+  typedef typename storage_type::const_type           const_raw_ptr_type;
+
+  // Compile- and run-time properties.
+public:
+  static int   const CT_Cost          = 2;
+  static bool  const CT_Mem_not_req   = false;
+  static bool  const CT_Xfer_not_req  = false;
+
+  static int    cost(Block const&, LP const&)
+    { return CT_Cost; }
+  static size_t mem_required (Block const& block, LP const&)
+    { return sizeof(typename Block::value_type) * block.size(); }
+  static size_t xfer_required(Block const&, LP const&)
+    { return !CT_Xfer_not_req; }
+
+  // Constructor and destructor.
+public:
+  Low_level_data_access(Block&         blk,
+			raw_ptr_type   buffer = NULL)
+    : layout_   (extent<dim>(blk)),
+      storage_  (layout_.total_size(), buffer)
+  {}
+
+  ~Low_level_data_access()
+    { storage_.deallocate(layout_.total_size()); }
+
+  void begin(Block* blk, bool sync)
+  {
+    if (sync)
+      Block_copy_to_ptr<LP::dim, Block, order_type, pack_type, complex_type>::
+	copy(blk, layout_, storage_.data());
+  }
+
+  void end(Block* blk, bool sync)
+  {
+    if (sync)
+      Block_copy_from_ptr<LP::dim, Block, order_type, pack_type, complex_type>::
+	copy(blk, layout_, storage_.data());
+  }
+
+  int cost() const { return CT_Cost; }
+
+  // Direct data acessors.
+public:
+  raw_ptr_type	data(Block*)
+    { return storage_.data(); }
+  const_raw_ptr_type	data(Block*) const
+    { return storage_.data(); }
+  stride_type	stride(Block*, dimension_type d) const
+    { return layout_.stride(d); }
+  length_type	size  (Block* blk, dimension_type d) const
+    { return blk->size(Block::dim, d); }
+  length_type	size  (Block* blk) const
+    { return blk->size(); }
+
+  // Member data.
+private:
+  Applied_layout<actual_layout_type> layout_;
+  storage_type                       storage_;
+};
+
+
+
+template <> struct Cost<Direct_access_tag>   { static int const value = 0; };
+template <> struct Cost<Copy_access_tag>     { static int const value = 2; };
+
+} // namespace vsip::impl::data_access
+
+
+
+/// Choose access type for a given block and desired layout.
+
+#if VSIP_IMPL_REF_IMPL
+template <typename Block,
+	  typename LP>
+struct Choose_access
+{
+  typedef typename Block_layout<Block>::layout_type BLP;
+  typedef typename Block_layout<Block>::access_type access_type;
+
+  typedef typename 
+    ITE_Type<Type_equal<BLP, LP>::value,
+	   As_type<access_type>, As_type<Copy_access_tag> >::type
+    type;
+};
+#endif
+
+
+
+/// Determine desired block layout.
+///
+/// For a block with direct access, the desired layout is the same
+/// as the block's layout (Block_layout).
+///
+/// For a block with copy access, the desired layout adjusts the
+/// pack type to be dense, so that the block can be copied into
+/// contiguous memory.
+
+template <typename BlockT>
+struct Desired_block_layout
+{
+private:
+  typedef Block_layout<BlockT> raw_type;
+
+public:
+  static dimension_type const dim = raw_type::dim;
+
+  typedef typename raw_type::access_type   access_type;
+  typedef typename raw_type::order_type    order_type;
+  typedef typename
+	  ITE_Type<Type_equal<access_type, Direct_access_tag>::value,
+		   As_type<typename raw_type::pack_type>,
+	  ITE_Type<Type_equal<access_type, Copy_access_tag>::value &&
+                   Is_stride_unit_align<typename raw_type::pack_type>::value,
+		      As_type<typename raw_type::pack_type>,
+		      As_type<Stride_unit_dense>
+	          > >::type                  pack_type;
+  typedef typename raw_type::complex_type  complex_type;
+
+  typedef Layout<dim, order_type, pack_type, complex_type> layout_type;
+};
+
+
+
+/// High-level data access class.  Provides data access to data
+/// stored in blocks, using an appropriate low-level data interface.
+
+/// Requires:
+///   BLOCK is a block type.
+///   LP is the desired layout policy for the data access.
+///   RP is a reference counting policy.
+///   AT is a data access tag that selects the low-level interface
+///      used to access the data.  By default, Choose_access is used to
+///      select the appropriate access tag for a given block type
+///      BLOCK and layout LP.
+///
+/// Notes:
+/// [1] Selecting a specific low-level interface is discouraged.
+///     Selecting one that is not compatible with BLOCK will result in
+///     undefined behavior.
+
+template <typename BlockT,
+	  typename LP  = typename Desired_block_layout<BlockT>::layout_type,
+	  typename RP  = No_count_policy,
+	  typename AT  = typename Choose_access<BlockT, LP>::type>
+class Ext_data
+{
+  // Compile time typedefs.
+public:
+  typedef typename Non_const_of<BlockT>::type non_const_block_type;
+
+  typedef data_access::Low_level_data_access<AT, BlockT, LP> ext_type;
+  typedef typename BlockT::value_type value_type;
+
+  typedef Storage<typename LP::complex_type, typename BlockT::value_type>
+		storage_type;
+
+  typedef typename storage_type::alloc_type element_type;
+  typedef typename storage_type::type       raw_ptr_type;
+  typedef typename storage_type::const_type const_raw_ptr_type;
+
+
+  // Compile- and run-time properties.
+public:
+  static int   const CT_Cost          = ext_type::CT_Cost;
+  static bool  const CT_Mem_not_req   = ext_type::CT_Mem_not_req;
+  static bool  const CT_Xfer_not_req  = ext_type::CT_Xfer_not_req;
+
+
+  // Constructor and destructor.
+public:
+  Ext_data(non_const_block_type& block,
+	   sync_action_type      sync   = SYNC_INOUT,
+	   raw_ptr_type          buffer = storage_type::null())
+    : blk_ (&block),
+      ext_ (block, buffer),
+      sync_(sync)
+    { ext_.begin(blk_.get(), sync_ & SYNC_IN); }
+
+  Ext_data(BlockT const&      block,
+	   sync_action_type   sync   = SYNC_IN,
+	   raw_ptr_type       buffer = storage_type::null())
+    : blk_ (&const_cast<BlockT&>(block)),
+      ext_ (const_cast<BlockT&>(block), buffer),
+      sync_(sync)
+  {
+    assert(sync != SYNC_OUT && sync != SYNC_INOUT);
+    ext_.begin(blk_.get(), sync_ & SYNC_IN);
+  }
+
+  ~Ext_data()
+    { ext_.end(blk_.get(), sync_ & SYNC_OUT); }
+
+  // Direct data acessors.
+public:
+  raw_ptr_type data()
+    { return ext_.data  (blk_.get()); }
+
+  const_raw_ptr_type data() const
+    { return ext_.data  (blk_.get()); }
+
+  stride_type stride(dimension_type d) const
+    { return ext_.stride(blk_.get(), d); }
+
+  length_type size(dimension_type d) const
+    { return ext_.size  (blk_.get(), d); }
+
+  length_type size() const
+    { return ext_.size  (blk_.get()); }
+
+  int cost() const
+    { return ext_.cost(); }
+
+  // Member data.
+private:
+  typename View_block_storage<BlockT>::template With_rp<RP>::type
+		   blk_;
+  ext_type         ext_;
+  sync_action_type sync_;
+};
+
+
+
+template <typename Block,
+	  typename LP  = typename Desired_block_layout<Block>::layout_type,
+	  typename RP  = No_count_policy,
+	  typename AT  = typename Choose_access<Block, LP>::type>
+class Persistent_ext_data
+{
+  // Compile time typedefs.
+public:
+  typedef data_access::Low_level_data_access<AT, Block, LP> ext_type;
+  typedef typename Block::value_type value_type;
+
+  typedef Storage<typename LP::complex_type, typename Block::value_type>
+		storage_type;
+
+  typedef typename storage_type::alloc_type element_type;
+  typedef typename storage_type::type       raw_ptr_type;
+  typedef typename storage_type::const_type const_raw_ptr_type;
+
+
+  // Compile- and run-time properties.
+public:
+  static int   const CT_Cost          = ext_type::CT_Cost;
+  static bool  const CT_Mem_not_req   = ext_type::CT_Mem_not_req;
+  static bool  const CT_Xfer_not_req  = ext_type::CT_Xfer_not_req;
+
+
+  // Constructor and destructor.
+public:
+  Persistent_ext_data(Block&             block,
+		      sync_action_type   sync   = SYNC_INOUT,
+		      raw_ptr_type       buffer = storage_type::null())
+    : blk_ (&block),
+      ext_ (block, buffer),
+      sync_(sync)
+    {}
+
+  ~Persistent_ext_data()
+    {}
+
+  void begin()
+    { ext_.begin(blk_.get(), sync_ & SYNC_IN); }
+
+  void end()
+    { ext_.end(blk_.get(), sync_ & SYNC_OUT); }
+
+  // Direct data acessors.
+public:
+  raw_ptr_type data()
+    { return ext_.data  (blk_.get()); }
+
+  const_raw_ptr_type data() const
+    { return ext_.data  (blk_.get()); }
+
+  stride_type stride(dimension_type d) const
+    { return ext_.stride(blk_.get(), d); }
+
+  length_type size(dimension_type d) const
+    { return ext_.size  (blk_.get(), d); }
+
+  // Member data.
+private:
+  typename View_block_storage<Block>::template With_rp<RP>::type
+		   blk_;
+  ext_type         ext_;
+  sync_action_type sync_;
+};
+
+
+
+template <typename Block,
+	  typename LP = typename Desired_block_layout<Block>::layout_type>
+struct Ext_data_cost
+{
+  typedef typename Choose_access<Block, LP>::type access_type;
+  static int const value = data_access::Cost<access_type>::value;
+};
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+/// Return the cost of accessing a block with a given layout.
+
+template <typename LP,
+	  typename Block>
+inline 
+int
+cost(
+  Block const& block,
+  LP    const& layout = LP())
+{
+  typedef typename Choose_access<Block, LP>::type
+		access_type;
+
+  return data_access::Low_level_data_access<access_type, Block, LP>
+    ::cost(block, layout);
+}
+
+
+
+/// Return the number of bytes of memory required to access a block
+/// with a given layout.
+
+template <typename LP,
+	  typename Block>
+size_t
+mem_required(
+  Block const& block,
+  LP    const& layout = LP())
+{
+  typedef typename Choose_access<Block, LP>::type
+		access_type;
+
+  return data_access::Low_level_data_access<access_type, Block, LP>
+    ::mem_required(block, layout);
+}
+
+
+
+/// Return whether a transfer is required to access a block with
+/// a given layout.
+
+template <typename LP,
+	  typename Block>
+bool
+xfer_required(
+  Block const& block,
+  LP    const& layout = LP())
+{
+  typedef typename Choose_access<Block, LP>::type
+		access_type;
+
+  return data_access::Low_level_data_access<access_type, Block, LP>
+    ::xfer_required(block, layout);
+}
+
+
+
+// Determine if an Ext_data object refers to a dense (contiguous,
+// unit-stride) region of memory.
+
+template <typename OrderT,
+	  typename ExtT>
+bool
+is_ext_dense(
+  vsip::dimension_type dim,
+  ExtT const&          ext)
+{
+  using vsip::dimension_type;
+  using vsip::stride_type;
+
+  dimension_type const dim0 = OrderT::impl_dim0;
+  dimension_type const dim1 = OrderT::impl_dim1;
+  dimension_type const dim2 = OrderT::impl_dim2;
+
+  assert(dim <= VSIP_MAX_DIMENSION);
+
+  if (dim == 1)
+  {
+    return (ext.stride(dim0) == 1);
+  }
+  else if (dim == 2)
+  {
+    return (ext.stride(dim1) == 1) &&
+           (ext.stride(dim0) == static_cast<stride_type>(ext.size(dim1)) ||
+	    ext.size(dim0) == 1);
+  }
+  else /*  if (dim == 2) */
+  {
+    return (ext.stride(dim2) == 1) &&
+           (ext.stride(dim1) == static_cast<stride_type>(ext.size(dim2)) ||
+	    (ext.size(dim0) == 1 && ext.size(dim1) == 1)) &&
+           (ext.stride(dim0) == static_cast<stride_type>(ext.size(dim1)  *
+							 ext.size(dim2)) ||
+	    ext.size(dim0) == 1);
+  }
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_CORE_EXTDATA_HPP
Index: src/vsip/core/vmmul.hpp
===================================================================
--- src/vsip/core/vmmul.hpp	(revision 156639)
+++ src/vsip/core/vmmul.hpp	(working copy)
@@ -18,7 +18,9 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/core/promote.hpp>
-#include <vsip/opt/expr/serial_evaluator.hpp>
+#if !VSIP_IMPL_REF_IMPL
+#  include <vsip/opt/expr/serial_evaluator.hpp>
+#endif
 
 
 
@@ -285,6 +287,7 @@
 
 
 
+#if !VSIP_IMPL_REF_IMPL
 /// Evaluator for vector-matrix multiply.
 
 /// Reduces vmmul into either vector element-wise multipy, or
@@ -356,6 +359,7 @@
     }
   }
 };
+#endif
 
 } // namespace vsip::impl
 
Index: src/vsip/core/fast_block.hpp
===================================================================
--- src/vsip/core/fast_block.hpp	(revision 156639)
+++ src/vsip/core/fast_block.hpp	(working copy)
@@ -22,7 +22,7 @@
 
 #include <vsip/core/refcount.hpp>
 #include <vsip/core/layout.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/block_traits.hpp>
 
 
Index: src/vsip/core/fft.hpp
===================================================================
--- src/vsip/core/fft.hpp	(revision 156639)
+++ src/vsip/core/fft.hpp	(working copy)
@@ -9,6 +9,10 @@
 #ifndef VSIP_CORE_FFT_HPP
 #define VSIP_CORE_FFT_HPP
 
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
 #include <vsip/support.hpp>
 #include <vsip/core/config.hpp>
 #include <vsip/core/signal/types.hpp>
@@ -16,7 +20,10 @@
 #include <vsip/core/fft/backend.hpp>
 #include <vsip/core/fft/factory.hpp>
 #include <vsip/core/fft/util.hpp>
-#include <vsip/core/fft/workspace.hpp>
+#include <vsip/core/fft/ct_workspace.hpp>
+#ifndef VSIP_IMPL_REF_IMPL
+#  include <vsip/core/fft/workspace.hpp>
+#endif
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/profile.hpp>
 
@@ -43,6 +50,10 @@
 #endif
 
 
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
 namespace vsip
 {
 
@@ -162,7 +173,11 @@
   static int const axis = fft::axis<I, O, S>::value;
   static int const exponent = fft::exponent<I, O, S>::value;
   typedef fft::base_interface<D, I, O, axis, exponent> base;
+#if VSIP_IMPL_REF_IMPL
+  typedef fft::Ct_workspace<D, I, O> workspace;
+#else
   typedef fft::workspace<D, I, O> workspace;
+#endif
   typedef fft::factory<D, I, O, S, by_value, N, L> factory;
 
   fft_facade(Domain<D> const& dom, typename base::scalar_type scale)
@@ -210,7 +225,11 @@
   static int const axis = fft::axis<I, O, S>::value;
   static int const exponent = fft::exponent<I, O, S>::value;
   typedef fft::base_interface<D, I, O, axis, exponent> base;
+#if VSIP_IMPL_REF_IMPL
+  typedef fft::Ct_workspace<D, I, O> workspace;
+#else
   typedef fft::workspace<D, I, O> workspace;
+#endif
   typedef fft::factory<D, I, O, S, vsip::by_reference, N, L> factory;
 
   fft_facade(Domain<D> const& dom, typename base::scalar_type scale)
@@ -279,7 +298,11 @@
   static int const axis = A;
   static int const exponent = D == -2 ? -1 : 1;
   typedef fft::base_interface<2, I, O, axis, exponent> base;
+#if VSIP_IMPL_REF_IMPL
+  typedef fft::Ct_workspace<2, I, O> workspace;
+#else
   typedef fft::workspace<2, I, O> workspace;
+#endif
   typedef fftm::factory<I, O, axis, exponent, by_value, N, L> factory;
 public:
   fftm_facade(Domain<2> const& dom, typename base::scalar_type scale)
@@ -328,7 +351,11 @@
   static int const axis = A;
   static int const exponent = D == -2 ? -1 : 1;
   typedef fft::base_interface<2, I, O, axis, exponent> base;
+#if VSIP_IMPL_REF_IMPL
+  typedef fft::Ct_workspace<2, I, O> workspace;
+#else
   typedef fft::workspace<2, I, O> workspace;
+#endif
   typedef fftm::factory<I, O, axis, exponent, by_value, N, L> factory;
 public:
   fftm_facade(Domain<2> const& dom, typename base::scalar_type scale)
Index: src/vsip/opt/sal/eval_threshold.hpp
===================================================================
--- src/vsip/opt/sal/eval_threshold.hpp	(revision 156639)
+++ src/vsip/opt/sal/eval_threshold.hpp	(working copy)
@@ -20,7 +20,7 @@
 #include <vsip/core/expr/ternary_block.hpp>
 #include <vsip/core/expr/operations.hpp>
 #include <vsip/core/fns_elementwise.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/opt/sal/eval_util.hpp>
 #include <vsip/core/adjust_layout.hpp>
Index: src/vsip/opt/sal/eval_vcmp.hpp
===================================================================
--- src/vsip/opt/sal/eval_vcmp.hpp	(revision 156639)
+++ src/vsip/opt/sal/eval_vcmp.hpp	(working copy)
@@ -20,7 +20,7 @@
 #include <vsip/core/expr/ternary_block.hpp>
 #include <vsip/core/expr/operations.hpp>
 #include <vsip/core/fns_elementwise.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/opt/sal/eval_util.hpp>
 #include <vsip/core/adjust_layout.hpp>
Index: src/vsip/opt/sal/eval_util.hpp
===================================================================
--- src/vsip/opt/sal/eval_util.hpp	(revision 156639)
+++ src/vsip/opt/sal/eval_util.hpp	(working copy)
@@ -13,7 +13,7 @@
   Included Files
 ***********************************************************************/
 
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/coverage.hpp>
 
 
Index: src/vsip/opt/sal/eval_elementwise.hpp
===================================================================
--- src/vsip/opt/sal/eval_elementwise.hpp	(revision 156639)
+++ src/vsip/opt/sal/eval_elementwise.hpp	(working copy)
@@ -20,7 +20,7 @@
 #include <vsip/core/expr/ternary_block.hpp>
 #include <vsip/core/expr/operations.hpp>
 #include <vsip/core/fns_elementwise.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/opt/sal/eval_util.hpp>
 #include <vsip/core/adjust_layout.hpp>
Index: src/vsip/opt/extdata.hpp
===================================================================
--- src/vsip/opt/extdata.hpp	(revision 156639)
+++ src/vsip/opt/extdata.hpp	(working copy)
@@ -3,18 +3,26 @@
 /** @file    vsip/opt/extdata.hpp
     @author  Jules Bergmann
     @date    2005-02-11
-    @brief   VSIPL++ Library: Direct Data Access.
+    @brief   VSIPL++ Library: Direct Data Access extensions for Optimized
+             Library.
 
+    This file is included by core/extdata.hpp when appropriate.  It
+    should not be included directly by other source files.
 */
 
 #ifndef VSIP_OPT_EXTDATA_HPP
 #define VSIP_OPT_EXTDATA_HPP
 
+#if VSIP_IMPL_REF_IMPL
+#  error "vsip/opt/extdata.hpp is not part of reference implementation."
+#endif
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
 
 #include <vsip/core/static_assert.hpp>
+#include <vsip/core/extdata_common.hpp>
 #include <vsip/opt/block_copy.hpp>
 #include <vsip/core/block_traits.hpp>
 #include <vsip/core/metaprogramming.hpp>
@@ -34,83 +42,6 @@
 namespace impl
 {
 
-/// Reference Counting Policies.
-///
-/// A reference counting policy describes which behavior should be
-/// taken when an DDI class creates and destroys references to a block. 
-///
-/// A policy should implement two static functions:
-///  - inc() - action to perform when reference is created 
-///  - dec() - action to perform when reference is destroyed 
-///
-///
-/// The following policies are available:
-///
-///  - No_count_policy: do not increment/decrement block reference count.
-///
-///    When a DDI class is used in the same scope as another reference
-///    to the block being accessed, it is not necessary to increment
-///    the reference count.
-///
-///  - Ref_count_policy: increment/decrement block reference count.
-///
-///    When a DDI class is used in a situation where the block it
-///    references does not have a guarenteed reference.
-
-
-/// No reference count policy, indicates DDI object will not increment
-/// and decrement reference count.
-
-struct No_count_policy
-{
-  template <typename Block>
-  static void inc(Block const* /* block */) {}
-
-  template <typename Block>
-  static void dec(Block const* /* block */) {}
-};
-
-
-
-/// Reference count policy, indicates DDI object will increment and
-/// decrement reference count.
-
-struct Ref_count_policy
-{
-  template <typename Block>
-  static void inc(Block const* block) { block->increment_count(); }
-
-  template <typename Block>
-  static void dec(Block const* block) { block->decrement_count(); }
-};
-
-
-
-struct No_profile_policy {};
-
-
-
-/// Enum to indicate data interface syncronization necessary for
-/// correctness.
-///
-/// SYNC_IN            - syncronize data interface on creation,
-/// SYNC_OUT           - syncronize data interface on destruction,
-/// SYNC_INOUT         - syncronize data interface on creation and destruction,
-/// SYNC_IN_NOPRESERVE - syncronize data interface on creation
-///                      with guarantee that changes are not preserved
-///                      (usually by forcing a copy).
-
-enum sync_action_type
-{
-  SYNC_IN              = 0x01,
-  SYNC_OUT             = 0x02,
-  SYNC_INOUT           = SYNC_IN | SYNC_OUT,		// 0x03
-  SYNC_NOPRESERVE_impl = 0x04,
-  SYNC_IN_NOPRESERVE   = SYNC_IN | SYNC_NOPRESERVE_impl	// 0x05
-};
-
-
-
 /// Namespace for low-level data access interfaces.  These interfaces
 /// provide low-level data access to data stored within blocks
 /// (directly or indirectly).
@@ -125,100 +56,15 @@
 namespace data_access 
 {
 
-/// Low-level data access class.
+/// Low_level_data_access declared in extdata_common.hpp.
 
-/// Requires:
-///   AT is a valid data access tag,
-///   BLOCK is a block that supports the data access interface indicated
-///      by AT.
-///   LP is a layout policy compatible with access tag AT and block BLOCK.
-///
-///   (Each specializtion may provide additional requirements).
-///
-/// Member Functions:
-///    ...
-///
-/// Notes:
-///  - Low_level_data_access does not hold a block reference/pointer, it
-///    is provided to each member function by the caller.  This allows
-///    the caller to make policy decisions, such as reference counting.
+/// Specializaitons for
+///  - Direct_access_tag
+///  - Copy_access_tag
+/// are defined in core/extdata.hpp.
 
-template <typename AT,
-          typename Block,
-	  typename LP>
-class Low_level_data_access;
 
 
-
-/// Specialization for low-level direct data access.
-
-/// Requires:
-///   BLOCK to be a block that supports direct access via member
-///     functions impl_data() and impl_stride().  Access to these
-///     members can be protected by making Low_level_data_access a friend
-///     class to the block.
-///   LP is a layout policy describing the desired layout.  It is should
-///     match the inherent layout of the block.  Specifying a layout
-///     not directly supported by the block is an error and results in
-///     undefined behavior.
-
-template <typename Block,
-	  typename LP>
-class Low_level_data_access<Direct_access_tag, Block, LP>
-{
-  // Compile time typedefs.
-public:
-  static dimension_type const dim = LP::dim;
-
-  typedef typename Block::value_type value_type;
-  typedef typename LP::order_type    order_type;
-  typedef typename LP::pack_type     pack_type;
-  typedef typename LP::complex_type  complex_type;
-
-  typedef Storage<complex_type, value_type> storage_type;
-  typedef typename storage_type::type       raw_ptr_type;
-  typedef typename storage_type::const_type const_raw_ptr_type;
-
-  // Compile- and run-time properties.
-public:
-  static int   const CT_Cost         = 0;
-  static bool  const CT_Mem_not_req  = true;
-  static bool  const CT_Xfer_not_req = true;
-
-  static int    cost         (Block const& /*block*/, LP const& /*layout*/)
-    { return CT_Cost; }
-  static size_t mem_required (Block const& /*block*/, LP const& /*layout*/)
-    { return 0; }
-  static size_t xfer_required(Block const& /*block*/, LP const& /*layout*/)
-    { return !CT_Xfer_not_req; }
-
-  // Constructor and destructor.
-public:
-  Low_level_data_access(Block&,
-			raw_ptr_type     = NULL)
-  {}
-
-  ~Low_level_data_access() {}
-
-  void begin(Block*, bool) {}
-  void end(Block*, bool) {}
-
-  int cost() const { return CT_Cost; }
-
-  // Direct data acessors.
-public:
-  raw_ptr_type 	data  (Block* blk) const
-    { return blk->impl_data(); }
-  stride_type	stride(Block* blk, dimension_type d) const
-    { return blk->impl_stride(dim, d); }
-  length_type	size  (Block* blk, dimension_type d) const
-    { return blk->size(dim, d); }
-  length_type	size  (Block* blk) const
-    { return blk->size(); }
-};
-
-
-
 /// Specialization for low-level reordered direct data access.
 /// (Not implemented yet).
 
@@ -482,106 +328,7 @@
 };
 
 
-
-/// Specialization for copied direct data access.
-
-/// Requires:
-///   BLOCK to be a block.
-///   LP is a layout policy describing the desired layout.
-///      The desired layout can be different from the block's layout.
-///
-/// Notes:
-///   When the desired layout packing format is either Stride_unit or
-///   Stride_unknown, the packing format used will be Stride_unit_dense.
-
-template <typename Block,
-	  typename LP>
-class Low_level_data_access<Copy_access_tag, Block, LP>
-{
-  // Compile time typedefs.
-public:
-  static dimension_type const dim = LP::dim;
-
-  typedef typename Block::value_type value_type;
-  typedef typename LP::order_type    order_type;
-  typedef typename
-          ITE_Type<Type_equal<typename LP::pack_type, Stride_unit>::value ||
-	           Type_equal<typename LP::pack_type, Stride_unknown>::value,
-                   As_type<Stride_unit_dense>,
-		   As_type<typename LP::pack_type> >::type pack_type;
-  typedef typename LP::complex_type  complex_type;
-
-  typedef Layout<dim, order_type, pack_type, complex_type> actual_layout_type;
-
-  typedef Allocated_storage<complex_type, value_type> storage_type;
-  typedef typename storage_type::type                 raw_ptr_type;
-  typedef typename storage_type::const_type           const_raw_ptr_type;
-
-  // Compile- and run-time properties.
-public:
-  static int   const CT_Cost          = 2;
-  static bool  const CT_Mem_not_req   = false;
-  static bool  const CT_Xfer_not_req  = false;
-
-  static int    cost(Block const&, LP const&)
-    { return CT_Cost; }
-  static size_t mem_required (Block const& block, LP const&)
-    { return sizeof(typename Block::value_type) * block.size(); }
-  static size_t xfer_required(Block const&, LP const&)
-    { return !CT_Xfer_not_req; }
-
-  // Constructor and destructor.
-public:
-  Low_level_data_access(Block&         blk,
-			raw_ptr_type   buffer = NULL)
-    : layout_   (extent<dim>(blk)),
-      storage_  (layout_.total_size(), buffer)
-  {}
-
-  ~Low_level_data_access()
-    { storage_.deallocate(layout_.total_size()); }
-
-  void begin(Block* blk, bool sync)
-  {
-    if (sync)
-      Block_copy_to_ptr<LP::dim, Block, order_type, pack_type, complex_type>
-	::copy(blk, layout_, storage_.data());
-  }
-
-  void end(Block* blk, bool sync)
-  {
-    if (sync)
-      Block_copy_from_ptr<LP::dim, Block, order_type, pack_type, complex_type>
-	::copy(blk, layout_, storage_.data());
-  }
-
-  int cost() const { return CT_Cost; }
-
-  // Direct data acessors.
-public:
-  raw_ptr_type	data(Block*)
-    { return storage_.data(); }
-  const_raw_ptr_type	data(Block*) const
-    { return storage_.data(); }
-  stride_type	stride(Block*, dimension_type d) const
-    { return layout_.stride(d); }
-  length_type	size  (Block* blk, dimension_type d) const
-    { return blk->size(Block::dim, d); }
-  length_type	size  (Block* blk) const
-    { return blk->size(); }
-
-  // Member data.
-private:
-  Applied_layout<actual_layout_type> layout_;
-  storage_type                       storage_;
-};
-
-
-template <typename AT> struct Cost { static int const value = 10; };
-
-template <> struct Cost<Direct_access_tag>   { static int const value = 0; };
 template <> struct Cost<Reorder_access_tag>  { static int const value = 1; };
-template <> struct Cost<Copy_access_tag>     { static int const value = 2; };
 template <> struct Cost<Flexible_access_tag> { static int const value = 2; };
 
 } // namespace vsip::impl::data_access
@@ -645,311 +392,6 @@
 	     typename LP::complex_type>::type type;
 };
 
-
-template <typename BlockT>
-struct Desired_block_layout
-{
-private:
-  typedef Block_layout<BlockT> raw_type;
-
-public:
-  static dimension_type const dim = raw_type::dim;
-
-  typedef typename raw_type::access_type   access_type;
-  typedef typename raw_type::order_type    order_type;
-  typedef typename
-	  ITE_Type<Type_equal<access_type, Direct_access_tag>::value,
-		   As_type<typename raw_type::pack_type>,
-	  ITE_Type<Type_equal<access_type, Copy_access_tag>::value &&
-                   Is_stride_unit_align<typename raw_type::pack_type>::value,
-		      As_type<typename raw_type::pack_type>,
-		      As_type<Stride_unit_dense>
-	          > >::type                  pack_type;
-  typedef typename raw_type::complex_type  complex_type;
-
-  typedef Layout<dim, order_type, pack_type, complex_type> layout_type;
-};
-
-
-
-/// High-level data access class.  Provides data access to data
-/// stored in blocks, using an appropriate low-level data interface.
-
-/// Requires:
-///   BLOCK is a block type.
-///   LP is the desired layout policy for the data access.
-///   RP is a reference counting policy.
-///   AT is a data access tag that selects the low-level interface
-///      used to access the data.  By default, Choose_access is used to
-///      select the appropriate access tag for a given block type
-///      BLOCK and layout LP.
-///
-/// Notes:
-/// [1] Selecting a specific low-level interface is discouraged.
-///     Selecting one that is not compatible with BLOCK will result in
-///     undefined behavior.
-
-template <typename Block,
-	  typename LP  = typename Desired_block_layout<Block>::layout_type,
-	  typename RP  = No_count_policy,
-	  typename AT  = typename Choose_access<Block, LP>::type>
-class Ext_data
-{
-  // Compile time typedefs.
-public:
-  typedef typename Non_const_of<Block>::type non_const_block_type;
-  typedef data_access::Low_level_data_access<AT, Block, LP> ext_type;
-  typedef typename Block::value_type value_type;
-
-  typedef Storage<typename LP::complex_type, typename Block::value_type>
-		storage_type;
-
-  typedef typename storage_type::alloc_type element_type;
-  typedef typename storage_type::type       raw_ptr_type;
-  typedef typename storage_type::const_type const_raw_ptr_type;
-
-
-  // Compile- and run-time properties.
-public:
-  static int   const CT_Cost          = ext_type::CT_Cost;
-  static bool  const CT_Mem_not_req   = ext_type::CT_Mem_not_req;
-  static bool  const CT_Xfer_not_req  = ext_type::CT_Xfer_not_req;
-
-
-  // Constructor and destructor.
-public:
-  Ext_data(non_const_block_type& block,
-	   sync_action_type      sync   = SYNC_INOUT,
-	   raw_ptr_type          buffer = storage_type::null())
-    : blk_ (&block),
-      ext_ (block, buffer),
-      sync_(sync)
-    { ext_.begin(blk_.get(), sync_ & SYNC_IN); }
-
-  Ext_data(Block const&       block,
-	   sync_action_type   sync,
-	   raw_ptr_type       buffer = storage_type::null())
-    : blk_ (&const_cast<Block&>(block)),
-      ext_ (const_cast<Block&>(block), buffer),
-      sync_(sync)
-  {
-    assert(sync != SYNC_OUT && sync != SYNC_INOUT);
-    ext_.begin(blk_.get(), sync_ & SYNC_IN);
-  }
-
-  ~Ext_data()
-    { ext_.end(blk_.get(), sync_ & SYNC_OUT); }
-
-  // Direct data acessors.
-public:
-  raw_ptr_type data()
-    { return ext_.data  (blk_.get()); }
-
-  const_raw_ptr_type data() const
-    { return ext_.data  (blk_.get()); }
-
-  stride_type stride(dimension_type d) const
-    { return ext_.stride(blk_.get(), d); }
-
-  length_type size(dimension_type d) const
-    { return ext_.size  (blk_.get(), d); }
-
-  length_type size() const
-    { return ext_.size  (blk_.get()); }
-
-  int cost() const
-    { return ext_.cost(); }
-
-  // Member data.
-private:
-  typename View_block_storage<Block>::template With_rp<RP>::type
-		   blk_;
-  ext_type         ext_;
-  sync_action_type sync_;
-};
-
-
-
-template <typename Block,
-	  typename LP  = typename Desired_block_layout<Block>::layout_type,
-	  typename RP  = No_count_policy,
-	  typename AT  = typename Choose_access<Block, LP>::type>
-class Persistent_ext_data
-{
-  // Compile time typedefs.
-public:
-  typedef data_access::Low_level_data_access<AT, Block, LP> ext_type;
-  typedef typename Block::value_type value_type;
-
-  typedef Storage<typename LP::complex_type, typename Block::value_type>
-		storage_type;
-
-  typedef typename storage_type::alloc_type element_type;
-  typedef typename storage_type::type       raw_ptr_type;
-  typedef typename storage_type::const_type const_raw_ptr_type;
-
-
-  // Compile- and run-time properties.
-public:
-  static int   const CT_Cost          = ext_type::CT_Cost;
-  static bool  const CT_Mem_not_req   = ext_type::CT_Mem_not_req;
-  static bool  const CT_Xfer_not_req  = ext_type::CT_Xfer_not_req;
-
-
-  // Constructor and destructor.
-public:
-  Persistent_ext_data(Block&             block,
-		      sync_action_type   sync   = SYNC_INOUT,
-		      raw_ptr_type       buffer = storage_type::null())
-    : blk_ (&block),
-      ext_ (block, buffer),
-      sync_(sync)
-    {}
-
-  ~Persistent_ext_data()
-    {}
-
-  void begin()
-    { ext_.begin(blk_.get(), sync_ & SYNC_IN); }
-
-  void end()
-    { ext_.end(blk_.get(), sync_ & SYNC_OUT); }
-
-  // Direct data acessors.
-public:
-  raw_ptr_type data()
-    { return ext_.data  (blk_.get()); }
-
-  const_raw_ptr_type data() const
-    { return ext_.data  (blk_.get()); }
-
-  stride_type stride(dimension_type d) const
-    { return ext_.stride(blk_.get(), d); }
-
-  length_type size(dimension_type d) const
-    { return ext_.size  (blk_.get(), d); }
-
-  // Member data.
-private:
-  typename View_block_storage<Block>::template With_rp<RP>::type
-		   blk_;
-  ext_type         ext_;
-  sync_action_type sync_;
-};
-
-
-
-template <typename Block,
-	  typename LP = typename Desired_block_layout<Block>::layout_type>
-struct Ext_data_cost
-{
-  typedef typename Choose_access<Block, LP>::type access_type;
-  static int const value = data_access::Cost<access_type>::value;
-};
-
-
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-/// Return the cost of accessing a block with a given layout.
-
-template <typename LP,
-	  typename Block>
-inline 
-int
-cost(
-  Block const& block,
-  LP    const& layout = LP())
-{
-  typedef typename Choose_access<Block, LP>::type
-		access_type;
-
-  return data_access::Low_level_data_access<access_type, Block, LP>
-    ::cost(block, layout);
-}
-
-
-
-/// Return the number of bytes of memory required to access a block
-/// with a given layout.
-
-template <typename LP,
-	  typename Block>
-size_t
-mem_required(
-  Block const& block,
-  LP    const& layout = LP())
-{
-  typedef typename Choose_access<Block, LP>::type
-		access_type;
-
-  return data_access::Low_level_data_access<access_type, Block, LP>
-    ::mem_required(block, layout);
-}
-
-
-
-/// Return whether a transfer is required to access a block with
-/// a given layout.
-
-template <typename LP,
-	  typename Block>
-bool
-xfer_required(
-  Block const& block,
-  LP    const& layout = LP())
-{
-  typedef typename Choose_access<Block, LP>::type
-		access_type;
-
-  return data_access::Low_level_data_access<access_type, Block, LP>
-    ::xfer_required(block, layout);
-}
-
-
-
-// Determine if an Ext_data object refers to a dense (contiguous,
-// unit-stride) region of memory.
-
-template <typename OrderT,
-	  typename ExtT>
-bool
-is_ext_dense(
-  vsip::dimension_type dim,
-  ExtT const&          ext)
-{
-  using vsip::dimension_type;
-  using vsip::stride_type;
-
-  dimension_type const dim0 = OrderT::impl_dim0;
-  dimension_type const dim1 = OrderT::impl_dim1;
-  dimension_type const dim2 = OrderT::impl_dim2;
-
-  assert(dim <= VSIP_MAX_DIMENSION);
-
-  if (dim == 1)
-  {
-    return (ext.stride(dim0) == 1);
-  }
-  else if (dim == 2)
-  {
-    return (ext.stride(dim1) == 1) &&
-           (ext.stride(dim0) == static_cast<stride_type>(ext.size(dim1)) ||
-	    ext.size(dim0) == 1);
-  }
-  else /*  if (dim == 2) */
-  {
-    return (ext.stride(dim2) == 1) &&
-           (ext.stride(dim1) == static_cast<stride_type>(ext.size(dim2)) ||
-	    (ext.size(dim0) == 1 && ext.size(dim1) == 1)) &&
-           (ext.stride(dim0) == static_cast<stride_type>(ext.size(dim1)  *
-							 ext.size(dim2)) ||
-	    ext.size(dim0) == 1);
-  }
-}
-
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/opt/rt_extdata.hpp
===================================================================
--- src/vsip/opt/rt_extdata.hpp	(revision 156639)
+++ src/vsip/opt/rt_extdata.hpp	(working copy)
@@ -14,7 +14,7 @@
   Included Files
 ***********************************************************************/
 
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 
 
 
Index: src/vsip/opt/dispatch.hpp
===================================================================
--- src/vsip/opt/dispatch.hpp	(revision 156639)
+++ src/vsip/opt/dispatch.hpp	(working copy)
@@ -128,7 +128,7 @@
 template <typename O, typename R, typename A, typename L, typename B, typename E>
 struct Dispatcher<O, R(A), L, B, None_type, E, false>
 {
-  static R dispatch(A a)
+  static R dispatch(A)
   {
     VSIP_IMPL_THROW(impl::unimplemented("No backend"));
   }
Index: src/vsip/opt/us_block.hpp
===================================================================
--- src/vsip/opt/us_block.hpp	(revision 156639)
+++ src/vsip/opt/us_block.hpp	(working copy)
@@ -19,7 +19,7 @@
 #include <vsip/core/refcount.hpp>
 #include <vsip/core/parallel/local_map.hpp>
 #include <vsip/core/layout.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/block_traits.hpp>
 
 
Index: src/vsip/opt/ipp/bindings.hpp
===================================================================
--- src/vsip/opt/ipp/bindings.hpp	(revision 156639)
+++ src/vsip/opt/ipp/bindings.hpp	(working copy)
@@ -21,7 +21,7 @@
 #include <vsip/core/expr/binary_block.hpp>
 #include <vsip/core/expr/operations.hpp>
 #include <vsip/core/fns_elementwise.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/adjust_layout.hpp>
 
 /***********************************************************************
Index: src/vsip/opt/extdata_local.hpp
===================================================================
--- src/vsip/opt/extdata_local.hpp	(revision 156639)
+++ src/vsip/opt/extdata_local.hpp	(working copy)
@@ -19,7 +19,7 @@
 #include <vsip/core/block_traits.hpp>
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/layout.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/working_view.hpp>
 #include <vsip/core/adjust_layout.hpp>
 #include <vsip/opt/us_block.hpp>
Index: src/vsip/opt/simd/expr_evaluator.hpp
===================================================================
--- src/vsip/opt/simd/expr_evaluator.hpp	(revision 156639)
+++ src/vsip/opt/simd/expr_evaluator.hpp	(working copy)
@@ -21,7 +21,7 @@
 #include <vsip/core/expr/unary_block.hpp>
 #include <vsip/core/expr/binary_block.hpp>
 #include <vsip/core/metaprogramming.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/opt/expr/serial_evaluator.hpp>
 
 /***********************************************************************
Index: src/vsip/opt/simd/eval_generic.hpp
===================================================================
--- src/vsip/opt/simd/eval_generic.hpp	(revision 156639)
+++ src/vsip/opt/simd/eval_generic.hpp	(working copy)
@@ -20,7 +20,7 @@
 #include <vsip/core/expr/binary_block.hpp>
 #include <vsip/core/expr/operations.hpp>
 #include <vsip/core/fns_elementwise.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/coverage.hpp>
 
 #include <vsip/opt/simd/simd.hpp>
Index: src/vsip/opt/block_copy.hpp
===================================================================
--- src/vsip/opt/block_copy.hpp	(revision 156639)
+++ src/vsip/opt/block_copy.hpp	(working copy)
@@ -345,74 +345,6 @@
 
 
 
-template <dimension_type Dim,
-	  typename       BlockT,
-	  typename       OrderT  = typename Block_layout<BlockT>::order_type,
-	  bool           IsGlobal = 
-			    Is_global_only<typename BlockT::map_type>::value>
-struct Block_fill;
-
-template <dimension_type Dim,
-	  typename       BlockT,
-	  typename       OrderT>
-struct Block_fill<Dim, BlockT, OrderT, true>
-{
-  typedef typename BlockT::value_type value_type;
-  static void exec(BlockT& block, value_type const& val)
-  {
-    typedef typename Distributed_local_block<BlockT>::type local_block_type;
-    typedef typename impl::View_block_storage<local_block_type>::plain_type
-		type;
-
-    if (block.map().subblock() != no_subblock)
-    {
-      // If get_local_block returns a temporary value, we need to copy it.
-      // Other (if it returns a reference), this captures it.
-      type l_block = get_local_block(block);
-      Block_fill<Dim, local_block_type>::exec(l_block, val);
-    }
-  }
-};
-
-template <typename BlockT,
-	  typename OrderT>
-struct Block_fill<1, BlockT, OrderT, false>
-{
-  typedef typename BlockT::value_type value_type;
-
-  static void exec(BlockT& block, value_type const& val)
-  {
-    for (index_type i=0; i<block.size(1, 0); ++i)
-      block.put(i, val);
-  }
-};
-
-template <typename BlockT>
-struct Block_fill<2, BlockT, row2_type, false>
-{
-  typedef typename BlockT::value_type value_type;
-
-  static void exec(BlockT& block, value_type const& val)
-  {
-    for (vsip::index_type r=0; r<block.size(2, 0); ++r)
-      for (vsip::index_type c=0; c<block.size(2, 1); ++c)
-	block.put(r, c, val);
-  }
-};
-
-template <typename BlockT>
-struct Block_fill<2, BlockT, col2_type, false>
-{
-  typedef typename BlockT::value_type value_type;
-
-  static void exec(BlockT& block, value_type const& val)
-  {
-    for (vsip::index_type c=0; c<block.size(2, 1); ++c)
-      for (vsip::index_type r=0; r<block.size(2, 0); ++r)
-	block.put(r, c, val);
-  }
-};
-
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/opt/expr/serial_evaluator.hpp
===================================================================
--- src/vsip/opt/expr/serial_evaluator.hpp	(revision 156639)
+++ src/vsip/opt/expr/serial_evaluator.hpp	(working copy)
@@ -15,7 +15,7 @@
 
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/block_traits.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/opt/fast_transpose.hpp>
 #include <vsip/core/adjust_layout.hpp>
 #include <vsip/core/coverage.hpp>
Index: src/vsip/opt/expr/eval_dense.hpp
===================================================================
--- src/vsip/opt/expr/eval_dense.hpp	(revision 156639)
+++ src/vsip/opt/expr/eval_dense.hpp	(working copy)
@@ -16,7 +16,7 @@
 
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/block_traits.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/expr/scalar_block.hpp>
 #include <vsip/core/expr/unary_block.hpp>
 #include <vsip/core/expr/binary_block.hpp>
Index: src/vsip_csl/matlab_bin_formatter.hpp
===================================================================
--- src/vsip_csl/matlab_bin_formatter.hpp	(revision 156639)
+++ src/vsip_csl/matlab_bin_formatter.hpp	(working copy)
@@ -14,7 +14,7 @@
 #include <vsip/core/fns_elementwise.hpp>
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/view_traits.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <string>
 #include <limits>
 
Index: src/vsip_csl/plainblock.hpp
===================================================================
--- src/vsip_csl/plainblock.hpp	(revision 156639)
+++ src/vsip_csl/plainblock.hpp	(working copy)
@@ -23,7 +23,7 @@
 #include <vsip/domain.hpp>
 #include <vsip/core/refcount.hpp>
 #include <vsip/core/layout.hpp>
-#include <vsip/opt/extdata.hpp>
+#include <vsip/core/extdata.hpp>
 #include <vsip/core/block_traits.hpp>
 
 
Index: configure.ac
===================================================================
--- configure.ac	(revision 156639)
+++ configure.ac	(working copy)
@@ -681,6 +681,9 @@
 # Find the FFT backends.
 # At present, SAL, IPP, and FFTW3 are supported.
 #
+provide_fft_float=0
+provide_fft_double=0
+provide_fft_long_double=0
 
 if test "$enable_fft_float" = yes; then
   vsip_impl_fft_use_float=1
@@ -752,14 +755,17 @@
   libs=
   syms=
   if test "$enable_fft_float" = yes ; then
+    provide_fft_float=1
     libs="$libs -lfftw3f"
     syms="$syms const char* fftwf_version;"
   fi
   if test "$enable_fft_double" = yes ; then
+    provide_fft_double=1
     libs="$libs -lfftw3"
     syms="$syms const char* fftw_version;"
   fi
   if test "$enable_fft_long_double" = yes; then
+    provide_fft_long_double=1
     libs="$libs -lfftw3l"
     syms="$syms const char* fftwl_version;"
   fi
@@ -861,6 +867,7 @@
     echo "==============================================================="
 
     if test "$enable_fft_float" = yes; then
+      provide_fft_float=1
       mkdir -p vendor/fftw3f
       AC_MSG_NOTICE([Configuring fftw3f (float).])
       AC_MSG_NOTICE([extra config options: '$fftw3_f_simd'.])
@@ -868,6 +875,7 @@
       libs="$libs -lfftw3f"
     fi
     if test "$enable_fft_double" = yes; then
+      provide_fft_double=1
       mkdir -p vendor/fftw3
       AC_MSG_NOTICE([Configuring fftw3 (double).])
       AC_MSG_NOTICE([extra config options: '$fftw3_d_simd'.])
@@ -875,6 +883,7 @@
       libs="$libs -lfftw3"
     fi
     if test "$enable_fft_long_double" = yes; then
+      provide_fft_long_double=1
       # fftw3l config doesn't get SIMD option
       mkdir -p vendor/fftw3l
       AC_MSG_NOTICE([Configuring fftw3l (long double).])
@@ -1273,6 +1282,8 @@
     fi
 
     if test "$enable_sal_fft" != "no"; then 
+      provide_fft_float=1
+      provide_fft_double=1
       AC_SUBST(VSIP_IMPL_SAL_FFT, 1)
       if test "$neutral_acconfig" = 'y'; then
         CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_SAL_FFT=1"
@@ -1330,6 +1341,8 @@
     [AC_MSG_ERROR(not found.)] )
 
   if test "$enable_ipp_fft" != "no"; then 
+    provide_fft_float=1
+    provide_fft_double=1
     AC_SUBST(VSIP_IMPL_IPP_FFT, 1)
     if test "$neutral_acconfig" = 'y'; then
       CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_IPP_FFT=1"
@@ -1459,32 +1472,38 @@
   CPPFLAGS="$CPPFLAGS $CVSIP_CPPFLAGS"
   AC_CHECK_HEADER([vsip.h])
   LDFLAGS="$LDFLAGS $CVSIP_LDFLAGS"
-  AC_CHECK_LIB(vsip, vsip_ccfftop_create_f,[ cvsip_has_float=1])
-  AC_CHECK_LIB(vsip, vsip_ccfftop_create_d,[ cvsip_has_double=1])
-  if test -n "$cvsip_has_float" -o -n "$cvsip_has_double"; then
+  AC_CHECK_LIB(vsip, vsip_ccfftop_create_f,[ cvsip_have_float=1])
+  AC_CHECK_LIB(vsip, vsip_ccfftop_create_d,[ cvsip_have_double=1])
+  if test -n "$cvsip_have_float" -o -n "$cvsip_have_double"; then
     LIBS="-lvsip $LIBS"
     AC_CHECK_FUNCS([vsip_conv1d_create_f vsip_conv1d_create_d\
                     vsip_conv2d_create_f vsip_conv2d_create_d\
                     vsip_corr1d_create_f vsip_corr1d_create_d\
                     vsip_corr2d_create_f vsip_corr2d_create_d],,,
       [#include <vsip.h>])
-    AC_SUBST(VSIP_IMPL_CVSIP_HAS_FLOAT, $cvsip_has_float)
-    AC_SUBST(VSIP_IMPL_CVSIP_HAS_DOUBLE, $cvsip_has_double)
+    AC_SUBST(VSIP_IMPL_CVSIP_HAVE_FLOAT, $cvsip_have_float)
+    AC_SUBST(VSIP_IMPL_CVSIP_HAVE_DOUBLE, $cvsip_have_double)
     AC_SUBST(VSIP_IMPL_HAVE_CVSIP, 1)
     if test "$neutral_acconfig" = 'y'; then
       CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_HAVE_CVSIP=1"
-      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_CVSIP_HAS_FLOAT=$cvsip_has_float"
-      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_CVSIP_HAS_DOUBLE=$cvsip_has_double"
+      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_CVSIP_HAVE_FLOAT=$cvsip_have_float"
+      CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_CVSIP_HAVE_DOUBLE=$cvsip_have_double"
     else
       AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_CVSIP, 1,
         [Define to use C-VSIPL library.])
-      AC_DEFINE_UNQUOTED(VSIP_IMPL_CVSIP_HAS_FLOAT, $cvsip_has_float,
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_CVSIP_HAVE_FLOAT, $cvsip_have_float,
         [Define if C-VSIPL supports float operations.])
-      AC_DEFINE_UNQUOTED(VSIP_IMPL_CVSIP_HAS_DOUBLE, $cvsip_has_double,
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_CVSIP_HAVE_DOUBLE, $cvsip_have_double,
         [Define if C-VSIPL supports double operations.])
     fi
   fi
   if test "$enable_cvsip_fft" != "no"; then 
+    if test "$cvsip_have_float" = "1"; then
+      provide_fft_float=1
+    fi
+    if test "$cvsip_have_double" = "1"; then
+      provide_fft_double=1
+    fi
     AC_SUBST(VSIP_IMPL_CVSIP_FFT, 1)
     if test "$neutral_acconfig" = 'y'; then
       CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_CVSIP_FFT=1"
@@ -1522,6 +1541,34 @@
   fi
 fi
 
+if test "$neutral_acconfig" = 'y'; then
+  if test "x$provide_fft_float" != "x"; then
+    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_PROVIDE_FFT_FLOAT=$provide_fft_float"
+  fi
+  if test "x$provide_fft_double" != "x"; then
+    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_PROVIDE_FFT_DOUBLE=$provide_fft_double"
+  fi
+  if test "x$provide_fft_long_double" != "x"; then
+    CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_PROVIDE_FFT_LONG_DOUBLE=$provide_fft_long_double"
+  fi
+else
+  if test "x$provide_fft_float" != "x"; then
+    AC_DEFINE_UNQUOTED(VSIP_IMPL_PROVIDE_FFT_FLOAT,
+              $provide_fft_float,
+	      [Defined if Sourcery VSIPL++ supports for FFT on float types.])
+  fi
+  if test "x$provide_fft_double" != "x"; then
+    AC_DEFINE_UNQUOTED(VSIP_IMPL_PROVIDE_FFT_DOUBLE,
+              $provide_fft_double,
+	      [Defined if Sourcery VSIPL++ supports for FFT on double types.])
+  fi
+  if test "x$provide_fft_long_double" != "x"; then
+    AC_DEFINE_UNQUOTED(VSIP_IMPL_PROVIDE_FFT_LONG_DOUBLE,
+	      $provide_fft_long_double,
+	      [Defined if Sourcery VSIPL++ supports for FFT on long double.])
+  fi
+fi
+
 #
 # Copy libg2c into libdir, if requested.
 #
@@ -2305,6 +2352,16 @@
 AC_MSG_RESULT([With IPP:                                $enable_ipp])
 AC_MSG_RESULT([With C-VSIPL:                            $enable_cvsip])
 AC_MSG_RESULT([Using FFT backends:                      ${enable_fft}])
+if test "$provide_fft_float" == "1"; then
+  AC_MSG_RESULT([  Provides float FFTs])
+fi
+if test "$provide_fft_double" == "1"; then
+  AC_MSG_RESULT([  Provides double FFTs])
+fi
+if test "$provide_fft_long_double" == "1"; then
+  AC_MSG_RESULT([  Provides long double FFTs])
+fi
+
 if test "$with_complex" == "split"; then
   AC_MSG_RESULT([Complex storage format:                  split])
 else
Index: tests/random.cpp
===================================================================
--- tests/random.cpp	(revision 156641)
+++ tests/random.cpp	(working copy)
@@ -5,7 +5,8 @@
     @date    2005-09-07
     @brief   VSIPL++ Library: Unit tests for Rand class
 
-    "C" random number generation code taken from C VSIPL.
+    "C" random number generation code taken from TVCPP C-VSIPL
+    implementation by Randy Judd.
 */
 
 /***********************************************************************
@@ -27,6 +28,12 @@
 // C VSIPL code - the following typedefs allow this code to run
 // essentially unmodified from the original source. 
 
+// This is placed in a namespace to avoid conflicting with real
+// C-VSIPL if it is used as a backend.
+
+namespace test
+{
+
 typedef double vsip_scalar_d;
 typedef struct { vsip_scalar_d  r, i; } vsip_cscalar_d;
 typedef unsigned int vsip_scalar_ue32;
@@ -343,6 +350,7 @@
   return vsip_cmplx_d(real,imag);
 }
 
+}; // namespace test
 // end C VSIPL code
 
 
@@ -354,6 +362,7 @@
   using namespace vsip_csl;
   vsipl init(argc, argv);
 
+
   // Random generation tests -- Compare against C VSIPL generator.
 
   // scalar values, portable or not, Normal or Uniform distributions
@@ -361,57 +370,57 @@
   // Normal distribution, portable
   {
     vsip::Rand<double> rgen(0, 1);
-    vsip_randstate *rstate;
-    rstate = vsip_randcreate( 0, 1, 1, 0 );
+    test::vsip_randstate *rstate;
+    rstate = test::vsip_randcreate( 0, 1, 1, 0 );
     for ( int i = 0; i < 8; ++i )
     {
       double a = rgen.randn();
-      double b = vsip_randn_d( rstate );
+      double b = test::vsip_randn_d( rstate );
       test_assert( equal( a, b ) );
     }
-    vsip_randdestroy( rstate );
+    test::vsip_randdestroy( rstate );
   }
 
   // Normal distribution, non-portable
   {
     vsip::Rand<double> rgen(0, 0);
-    vsip_randstate *rstate;
-    rstate = vsip_randcreate( 0, 1, 1, 1 );
+    test::vsip_randstate *rstate;
+    rstate = test::vsip_randcreate( 0, 1, 1, 1 );
     for ( int i = 0; i < 8; ++i ) 
     {
       double a = rgen.randn();
-      double b = vsip_randn_d( rstate );
+      double b = test::vsip_randn_d( rstate );
       test_assert( equal( a, b ) );
     }
-    vsip_randdestroy( rstate );
+    test::vsip_randdestroy( rstate );
   }
 
   // Uniform distribution, portable
   {
     vsip::Rand<double> rgen(0, 1);
-    vsip_randstate *rstate;
-    rstate = vsip_randcreate( 0, 1, 1, 0 );
+    test::vsip_randstate *rstate;
+    rstate = test::vsip_randcreate( 0, 1, 1, 0 );
     for ( int i = 0; i < 8; ++i ) 
     {
       double a = rgen.randu();
-      double b = vsip_randu_d( rstate );
+      double b = test::vsip_randu_d( rstate );
       test_assert( equal( a, b ) );
     }
-    vsip_randdestroy( rstate );
+    test::vsip_randdestroy( rstate );
   }
 
   // Uniform distribution, non-portable
   {
     vsip::Rand<double> rgen(0, 0);
-    vsip_randstate *rstate;
-    rstate = vsip_randcreate( 0, 1, 1, 1 );
+    test::vsip_randstate *rstate;
+    rstate = test::vsip_randcreate( 0, 1, 1, 1 );
     for ( int i = 0; i < 8; ++i ) 
     {
       double a = rgen.randu();
-      double b = vsip_randu_d( rstate );
+      double b = test::vsip_randu_d( rstate );
       test_assert( equal( a, b ) );
     }
-    vsip_randdestroy( rstate );
+    test::vsip_randdestroy( rstate );
   }
 
 
@@ -420,61 +429,61 @@
   // Normal distribution, portable
   {
     vsip::Rand<complex<double> > rgen(0, 1);
-    vsip_randstate *rstate;
-    rstate = vsip_randcreate( 0, 1, 1, 0 );
+    test::vsip_randstate *rstate;
+    rstate = test::vsip_randcreate( 0, 1, 1, 0 );
     for ( int i = 0; i < 8; ++i ) 
     {
       complex<double> a = rgen.randn();
-      vsip_cscalar_d z = vsip_crandn_d( rstate );
+      test::vsip_cscalar_d z = test::vsip_crandn_d( rstate );
       complex<double> b(z.r, z.i);
       test_assert( equal( a, b ) );
     }
-    vsip_randdestroy( rstate );
+    test::vsip_randdestroy( rstate );
   }
 
   // Normal distribution, non-portable
   {
     vsip::Rand<complex<double> > rgen(0, 0);
-    vsip_randstate *rstate;
-    rstate = vsip_randcreate( 0, 1, 1, 1 );
+    test::vsip_randstate *rstate;
+    rstate = test::vsip_randcreate( 0, 1, 1, 1 );
     for ( int i = 0; i < 8; ++i )
     {
       complex<double> a = rgen.randn();
-      vsip_cscalar_d z = vsip_crandn_d( rstate );
+      test::vsip_cscalar_d z = test::vsip_crandn_d( rstate );
       complex<double> b(z.r, z.i);
       test_assert( equal( a, b ) );
     }
-    vsip_randdestroy( rstate );
+    test::vsip_randdestroy( rstate );
   }
 
   // Uniform distribution, portable
   {
     vsip::Rand<complex<double> > rgen(0, 1);
-    vsip_randstate *rstate;
-    rstate = vsip_randcreate( 0, 1, 1, 0 );
+    test::vsip_randstate *rstate;
+    rstate = test::vsip_randcreate( 0, 1, 1, 0 );
     for ( int i = 0; i < 8; ++i ) 
     {
       complex<double> a = rgen.randu();
-      vsip_cscalar_d z = vsip_crandu_d( rstate );
+      test::vsip_cscalar_d z = test::vsip_crandu_d( rstate );
       complex<double> b(z.r, z.i);
       test_assert( equal( a, b ) );
     }
-    vsip_randdestroy( rstate );
+    test::vsip_randdestroy( rstate );
   }
 
   // Uniform distribution, non-portable
   {
     vsip::Rand<complex<double> > rgen(0, 0);
-    vsip_randstate *rstate;
-    rstate = vsip_randcreate( 0, 1, 1, 1 );
+    test::vsip_randstate *rstate;
+    rstate = test::vsip_randcreate( 0, 1, 1, 1 );
     for ( int i = 0; i < 8; ++i ) 
     {
       complex<double> a = rgen.randu();
-      vsip_cscalar_d z = vsip_crandu_d( rstate );
+      test::vsip_cscalar_d z = test::vsip_crandu_d( rstate );
       complex<double> b(z.r, z.i);
       test_assert( equal( a, b ) );
     }
-    vsip_randdestroy( rstate );
+    test::vsip_randdestroy( rstate );
   }
 
 
Index: tests/fftm.cpp
===================================================================
--- tests/fftm.cpp	(revision 156641)
+++ tests/fftm.cpp	(working copy)
@@ -10,8 +10,13 @@
   Included Files
 ***********************************************************************/
 
-#include <iostream>
-#include <iomanip>
+#define VERBOSE 0
+
+#if VERBOSE
+#  include <iostream>
+#  include <iomanip>
+#endif
+
 #include <cmath>
 
 #include <vsip/initfin.hpp>
@@ -45,6 +50,30 @@
 
 
 
+template <typename View1,
+	  typename View2>
+inline void
+check_error(
+  View1  v1,
+  View2  v2,
+  double epsilon)
+{
+  double error = error_db(v1, v2);
+#if VERBOSE
+  if (error >= epsilon)
+  {
+    std::cout << "check_error: error >= epsilon" << std::endl;
+    std::cout << "  error   = " << error   << std::endl;
+    std::cout << "  epsilon = " << epsilon << std::endl;
+    std::cout << "  v1 =\n" << v1;
+    std::cout << "  v2 =\n" << v2;
+  }
+#endif
+  test_assert(error < epsilon);
+}
+
+
+
 // Set up input data for Fftm.
 
 template <typename T,
@@ -125,14 +154,14 @@
 
   i_fftm(out, inv);
 
-  test_assert(error_db(ref, out) < -100);
-  test_assert(error_db(inv, in) < -100);
+  check_error(ref, out, -100);
+  check_error(inv, in,  -100);
 
   out = in;  f_fftm(out);
   inv = out; i_fftm(inv);
 
-  test_assert(error_db(ref, out) < -100);
-  test_assert(error_db(inv, in) < -100);
+  check_error(ref, out, -100);
+  check_error(inv, in,  -100);
 }
 
 
@@ -393,15 +422,15 @@
 {
   vsipl init(argc, argv);
 
-#if defined(VSIP_IMPL_FFT_USE_FLOAT)
+#if VSIP_IMPL_PROVIDE_FFT_FLOAT
   test<float>();
 #endif
 
-#if defined(VSIP_IMPL_FFT_USE_DOUBLE)
+#if VSIP_IMPL_PROVIDE_FFT_DOUBLE
   test<double>();
 #endif
 
-#if defined(VSIP_IMPL_FFT_USE_LONG_DOUBLE)
+#if VSIP_IMPL_PROVIDE_FFT_LONG_DOUBLE
 #  if ! defined(VSIP_IMPL_IPP_FFT)
   test<long double>();
 #  endif /* VSIP_IMPL_IPP_FFT */
Index: tests/fft.cpp
===================================================================
--- tests/fft.cpp	(revision 156641)
+++ tests/fft.cpp	(working copy)
@@ -1074,15 +1074,15 @@
 //
 // First check 1D 
 //
-#if defined(VSIP_IMPL_FFT_USE_FLOAT)
+#if VSIP_IMPL_PROVIDE_FFT_FLOAT
   test_1d<float>();
 #endif 
 
-#if defined(VSIP_IMPL_FFT_USE_DOUBLE)
+#if VSIP_IMPL_PROVIDE_FFT_DOUBLE
   test_1d<double>();
 #endif 
 
-#if defined(VSIP_IMPL_FFT_USE_LONG_DOUBLE)
+#if VSIP_IMPL_PROVIDE_FFT_LONG_DOUBLE
   test_1d<long double>();
 #endif
 
@@ -1093,15 +1093,15 @@
 
 #if VSIP_IMPL_TEST_LEVEL > 0
 
-#if defined(VSIP_IMPL_FFT_USE_FLOAT)
+#if VSIP_IMPL_PROVIDE_FFT_FLOAT
   test_nd<float>();
 #endif 
 
-#if defined(VSIP_IMPL_FFT_USE_DOUBLE)
+#if VSIP_IMPL_PROVIDE_FFT_DOUBLE
   test_nd<double>();
 #endif
 
-#if defined(VSIP_IMPL_FFT_USE_LONG_DOUBLE)
+#if VSIP_IMPL_PROVIDE_FFT_LONG_DOUBLE
   test_nd<long double>();
 #endif
 
