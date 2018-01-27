Index: ChangeLog
===================================================================
--- ChangeLog	(revision 174126)
+++ ChangeLog	(working copy)
@@ -1,3 +1,14 @@
+2007-06-16  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/layout.hpp (Applied_layout<Rt_layout<Dim> >): Check
+	  pack type before adjusting strides to meat alignment.
+	* src/vsip/opt/fft/workspace.hpp (workspace): Allocate temporary
+	  buffers large enough to fix row-start alignment.
+	* src/vsip/opt/fftw3/fft_impl.hpp: Robustify Fftm stride handling.
+	* src/vsip/opt/fftw3/create_plan.hpp: Fix Wall warnings.
+	* tests/regressions/rtl_align.cpp: New file, regression test
+	  for above Applied_layout<Rt_layout<Dim> > fix.
+
 2007-06-15  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/impl_tags.hpp (Simd_unaligned_loop_fusion_tag):
Index: src/vsip/core/layout.hpp
===================================================================
--- src/vsip/core/layout.hpp	(revision 173836)
+++ src/vsip/core/layout.hpp	(working copy)
@@ -940,11 +940,17 @@
 
       stride_[order_[2]] = 1;
       stride_[order_[1]] = size_[order_[2]];
-      if (layout.align != 0 &&
+      if (layout.pack == stride_unit_align && 
+	  layout.align != 0 &&
 	  (elem_size*stride_[order_[1]]) % layout.align != 0)
-	stride_[order_[1]] +=
-	  (layout.align/elem_size -
-	   stride_[order_[1]]%layout.align);
+      {
+	stride_type adjust =
+	  layout.align - (stride_[order_[1]] * elem_size)%layout.align;
+	assert(adjust > 0 && adjust % elem_size == 0);
+	adjust /= elem_size;
+	stride_[order_[1]] += adjust;
+	assert((stride_[order_[1]] * elem_size)%layout.align == 0);
+      }
       stride_[order_[0]] = size_[order_[1]] * stride_[order_[1]];
     }
     else if (Dim == 2)
@@ -956,10 +962,17 @@
       stride_[order_[1]] = 1;
       stride_[order_[0]] = size_[order_[1]];
 
-      if (layout.align != 0 &&
+      if (layout.pack == stride_unit_align && 
+	  layout.align != 0 &&
 	  (elem_size*stride_[order_[0]]) % layout.align != 0)
-	stride_[order_[0]] +=
-	  (layout.align/elem_size - stride_[order_[0]]%layout.align);
+      {
+	stride_type adjust =
+	  layout.align - (stride_[order_[0]] * elem_size)%layout.align;
+	assert(adjust > 0 && adjust % elem_size == 0);
+	adjust /= elem_size;
+	stride_[order_[0]] += adjust;
+	assert((stride_[order_[0]] * elem_size)%layout.align == 0);
+      }
     }
     else  // (Dim == 1)
     {
Index: src/vsip/opt/fft/workspace.hpp
===================================================================
--- src/vsip/opt/fft/workspace.hpp	(revision 173875)
+++ src/vsip/opt/fft/workspace.hpp	(working copy)
@@ -66,6 +66,41 @@
 
 
 
+template <typename       T,
+	  bool           ComputeInSize,
+	  typename       BE,
+	  dimension_type Dim>
+inline length_type
+inout_size(BE* backend, Domain<Dim> const& dom)
+{
+  Rt_layout<Dim> rtl_in, rtl_out;
+
+  rtl_in.pack    = stride_unit_dense;
+  rtl_in.order   = Rt_tuple(0, 1, 2);
+  rtl_in.complex = cmplx_inter_fmt;
+  rtl_in.align   = 0;
+
+  rtl_out.pack    = stride_unit_dense;
+  rtl_out.order   = Rt_tuple(0, 1, 2);
+  rtl_out.complex = cmplx_inter_fmt;
+  rtl_out.align   = 0;
+
+  backend->query_layout(rtl_in, rtl_out);
+
+  if (ComputeInSize)
+  {
+    Applied_layout<Rt_layout<Dim> > layout(rtl_in, extent(dom), sizeof(T));
+    return layout.total_size();
+  }
+  else
+  {
+    Applied_layout<Rt_layout<Dim> > layout(rtl_out, extent(dom), sizeof(T));
+    return layout.total_size();
+  }
+}
+
+
+
 /// This provides the temporary data as well as the
 /// conversion logic from blocks to arrays as expected
 /// by fft backends.
@@ -483,10 +518,10 @@
 {
 public:
   template <typename BE>
-  workspace(BE*, Domain<2> const &in, Domain<2> const &out, T scale)
+  workspace(BE* backend, Domain<2> const& in, Domain<2> const& out, T scale)
     : scale_(scale),
-      input_buffer_(in.size()),
-      output_buffer_(out.size())
+      input_buffer_ (inout_size<std::complex<T>, true> (backend, in)),
+      output_buffer_(inout_size<std::complex<T>, false>(backend, out))
   {}
   
   template <typename BE, typename Block0, typename Block1>
@@ -628,10 +663,10 @@
 {
 public:
   template <typename BE>
-  workspace(BE*, Domain<2> const &in, Domain<2> const &out, T scale)
+  workspace(BE* backend, Domain<2> const &in, Domain<2> const &out, T scale)
     : scale_(scale),
-      input_buffer_(in.size()),
-      output_buffer_(out.size())
+      input_buffer_ (inout_size<T,               true> (backend, in)),
+      output_buffer_(inout_size<std::complex<T>, false>(backend, out))
   {}
   
   template <typename BE, typename Block0, typename Block1>
@@ -732,10 +767,10 @@
 {
 public:
   template <typename BE>
-  workspace(BE*, Domain<2> const &in, Domain<2> const &out, T scale)
+  workspace(BE* backend, Domain<2> const &in, Domain<2> const &out, T scale)
     : scale_(scale),
-      input_buffer_(in.size()),
-      output_buffer_(out.size())
+      input_buffer_ (inout_size<std::complex<T>, true> (backend, in)),
+      output_buffer_(inout_size<T,               false>(backend, out))
   {}
   
   template <typename BE, typename Block0, typename Block1>
@@ -760,7 +795,6 @@
 				 input_buffer_.get());
       Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT,
 				  output_buffer_.get());
-    
       // Call the backend.
       if (rtl_in.complex == cmplx_inter_fmt) 
 	backend->by_reference(in_ext.data().as_inter(),
Index: src/vsip/opt/fftw3/fft_impl.cpp
===================================================================
--- src/vsip/opt/fftw3/fft_impl.cpp	(revision 174122)
+++ src/vsip/opt/fftw3/fft_impl.cpp	(working copy)
@@ -247,8 +247,10 @@
   }
   virtual void by_reference(rtype *in, stride_type is,
 			    ztype out, stride_type os,
-			    length_type length)
+			    length_type)
   {
+    assert(is == 1);
+    assert(os == 1);
     FFTW(execute_split_dft_r2c)(plan_by_reference_, 
 			  in, out.first, out.second);
   }
@@ -292,8 +294,10 @@
   }
   virtual void by_reference(ztype in, stride_type is,
 			    rtype *out, stride_type os,
-			    length_type length)
+			    length_type)
   {
+    assert(is == 1);
+    assert(os == 1);
     FFTW(execute_split_dft_c2r)(plan_by_reference_,
 			  in.first, in.second, out);
   }
@@ -769,20 +773,24 @@
     rtl_out = rtl_in;
   }
   virtual void by_reference(rtype *in,
-			    stride_type, stride_type,
+			    stride_type i_str_0, stride_type i_str_1,
 			    ctype *out,
-			    stride_type, stride_type,
+			    stride_type o_str_0, stride_type o_str_1,
 			    length_type rows, length_type cols)
   {
-    length_type const n_fft = (A == 1) ? rows : cols;
+    length_type const n_fft          = (A == 1) ? rows : cols;
+    length_type const in_fft_stride  = (A == 1) ? i_str_0 : i_str_1;
+    length_type const out_fft_stride = (A == 1) ? o_str_0 : o_str_1;
+
     if (A == 1) assert(rows <= mult_ && static_cast<int>(cols) == size_[0]);
-    else assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+    else        assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+
     for (index_type i = 0; i < n_fft; ++i)
     {
       FFTW(execute_dft_r2c)(plan_by_reference_, 
 			    in, reinterpret_cast<FFTW(complex)*>(out));
-      in += size_[0];
-      out += size_[0]/2 + 1;
+      in  += in_fft_stride;
+      out += out_fft_stride;
     }
   }
   virtual void by_reference(rtype *,
@@ -831,20 +839,24 @@
   virtual bool requires_copy(Rt_layout<2> &) { return true;}
 
   virtual void by_reference(ctype *in,
-			    stride_type, stride_type,
+			    stride_type i_str_0, stride_type i_str_1,
 			    rtype *out,
-			    stride_type, stride_type,
+			    stride_type o_str_0, stride_type o_str_1,
 			    length_type rows, length_type cols)
   {
-    length_type const n_fft = (A == 1) ? rows : cols;
+    length_type const n_fft          = (A == 1) ? rows : cols;
+    length_type const in_fft_stride  = (A == 1) ? i_str_0 : i_str_1;
+    length_type const out_fft_stride = (A == 1) ? o_str_0 : o_str_1;
+
     if (A == 1) assert(rows <= mult_ && static_cast<int>(cols) == size_[0]);
-    else assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+    else        assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+
     for (index_type i = 0; i < n_fft; ++i)
     {
       FFTW(execute_dft_c2r)(plan_by_reference_, 
 			    reinterpret_cast<FFTW(complex)*>(in), out);
-      in += size_[0]/2 + 1;
-      out += size_[0];
+      in  += in_fft_stride;
+      out += out_fft_stride;
     }
   }
   virtual void by_reference(ztype,
@@ -913,23 +925,27 @@
   }
 
   virtual void by_reference(ctype *in,
-			    stride_type, stride_type,
+			    stride_type i_str_0, stride_type i_str_1,
 			    ctype *out,
-			    stride_type, stride_type,
+			    stride_type o_str_0, stride_type o_str_1,
 			    length_type rows, length_type cols)
   {
     // If the inputs to the Fftm are distributed, the number of FFTs may
     // be less than mult_.
-    length_type const n_fft = (A == 1) ? rows : cols;
+    length_type const n_fft          = (A == 1) ? rows : cols;
+    length_type const in_fft_stride  = (A == 1) ? i_str_0 : i_str_1;
+    length_type const out_fft_stride = (A == 1) ? o_str_0 : o_str_1;
+
     if (A == 1) assert(rows <= mult_ && static_cast<int>(cols) == size_[0]);
-    else assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+    else        assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+
     for (index_type i = 0; i != n_fft; ++i)
     {
       FFTW(execute_dft)(plan_by_reference_, 
 			reinterpret_cast<FFTW(complex)*>(in), 
 			reinterpret_cast<FFTW(complex)*>(out));
-      in += size_[0];
-      out += size_[0];
+      in  += in_fft_stride;
+      out += out_fft_stride;
     }
   }
   virtual void by_reference(ztype,
Index: src/vsip/opt/fftw3/create_plan.hpp
===================================================================
--- src/vsip/opt/fftw3/create_plan.hpp	(revision 174122)
+++ src/vsip/opt/fftw3/create_plan.hpp	(working copy)
@@ -60,7 +60,7 @@
 Rt_tuple tuple_from_axis(int A);
 
 template <>
-Rt_tuple tuple_from_axis<1>(int A) { return Rt_tuple(0,1,2); }
+Rt_tuple tuple_from_axis<1>(int /*A*/) { return Rt_tuple(0,1,2); }
 template <>
 Rt_tuple tuple_from_axis<2>(int A) 
 {
@@ -96,8 +96,8 @@
   create(std::complex<T>* ptr1, std::complex<T>* ptr2,
          int exp, int flags, Domain<Dim> const& size)
   {
-    int sz[Dim],i;
-    for(i=0;i<Dim;i++) sz[i] = size[i].size();
+    int sz[Dim];
+    for(dimension_type i=0;i<Dim;i++) sz[i] = size[i].size();
     return create_fftw_plan(Dim, sz, ptr1,ptr2,exp,flags);
   }
 
@@ -108,8 +108,8 @@
   create(T* ptr1, std::complex<T>* ptr2,
          int A, int flags, Domain<Dim> const& size)
   {
-    int sz[Dim],i;
-    for(i=0;i<Dim;i++) sz[i] = size[i].size();
+    int sz[Dim];
+    for(dimension_type i=0;i<Dim;i++) sz[i] = size[i].size();
     if(A != Dim-1) std::swap(sz[A], sz[Dim-1]);
     return create_fftw_plan(Dim,sz,ptr1,ptr2,flags);
   }
@@ -121,8 +121,8 @@
   create(std::complex<T>* ptr1, T* ptr2,
          int A, int flags, Domain<Dim> const& size)
   {
-    int sz[Dim],i;
-    for(i=0;i<Dim;i++) sz[i] = size[i].size();
+    int sz[Dim];
+    for(dimension_type i=0;i<Dim;i++) sz[i] = size[i].size();
     if(A != Dim-1) std::swap(sz[A], sz[Dim-1]);
     return create_fftw_plan(Dim,sz,ptr1,ptr2,flags);
   }
Index: tests/regressions/rtl_align.cpp
===================================================================
--- tests/regressions/rtl_align.cpp	(revision 0)
+++ tests/regressions/rtl_align.cpp	(revision 0)
@@ -0,0 +1,112 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/regressions/rtl_align.cpp
+    @author  Jules Bergmann
+    @date    2007-06-15
+    @brief   VSIPL++ Library: Regression test for aligned Rt_layout.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/core/layout.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace vsip;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+void
+test_aligned_rtl_2()
+{
+  dimension_type const dim = 2;
+
+  impl::Rt_layout<dim> rtl;
+
+  length_type rows = 2;
+  length_type cols = 5;
+  length_type align = 32;
+  length_type elem_size = 8;
+
+  rtl.pack    = impl::stride_unit_align;
+  rtl.order   = impl::Rt_tuple(0, 1, 2);
+  rtl.complex = impl::cmplx_inter_fmt;
+  rtl.align   = align;
+
+  impl::Length<dim> ext(rows, cols);
+
+  impl::Applied_layout<impl::Rt_layout<dim> > layout(rtl, ext, elem_size);
+
+  test_assert(layout.size(0) == rows);
+  test_assert(layout.size(1) == cols);
+
+  // Check that alignment was achieved.
+  test_assert((layout.stride(0)*elem_size) % align == 0);
+
+  // Check that bounds of matrix didn't shrink while trying to
+  // achieve alignement.  (This was not being handled correctly).
+  test_assert(layout.stride(0) >= static_cast<stride_type>(cols));
+  test_assert(layout.stride(1) == 1);
+}
+
+
+
+void
+test_aligned_rtl_3()
+{
+  dimension_type const dim = 3;
+
+  impl::Rt_layout<dim> rtl;
+
+  length_type dim0      = 2;
+  length_type dim1      = 2;
+  length_type dim2      = 5;
+  length_type align     = 32;
+  length_type elem_size = 8;
+
+  rtl.pack    = impl::stride_unit_align;
+  rtl.order   = impl::Rt_tuple(0, 1, 2);
+  rtl.complex = impl::cmplx_inter_fmt;
+  rtl.align   = align;
+
+  impl::Length<dim> ext(dim0, dim1, dim2);
+
+  impl::Applied_layout<impl::Rt_layout<dim> > layout(rtl, ext, elem_size);
+
+  test_assert(layout.size(0) == dim0);
+  test_assert(layout.size(1) == dim1);
+  test_assert(layout.size(2) == dim2);
+
+  // Check that alignment was achieved.
+  test_assert((layout.stride(0)*elem_size) % align == 0);
+  test_assert((layout.stride(1)*elem_size) % align == 0);
+
+  // Check that bounds of matrix didn't shrink while trying to
+  // achieve alignement.  (This was not being handled correctly).
+  test_assert(layout.stride(0) >= static_cast<stride_type>(dim1*dim2));
+  test_assert(layout.stride(1) >= static_cast<stride_type>(dim2));
+  test_assert(layout.stride(2) == 1);
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_aligned_rtl_2();
+  test_aligned_rtl_3();
+}
