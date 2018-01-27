Index: ChangeLog
===================================================================
--- ChangeLog	(revision 177792)
+++ ChangeLog	(working copy)
@@ -1,3 +1,17 @@
+2007-07-31  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/signal/conv.hpp: Fix ifdef logic bug.  Optimized
+	  BEs were not being included.
+	* src/vsip/opt/ipp/fir.hpp: Use aligned_array for temporary storage
+	  (using Vector doesn't work when dense format is split).
+	* src/vsip/opt/fftw3/fft_impl.cpp (fftw3_complex_type): Centralize
+	  choice of complex_type.
+	  (USE_FFTW_SPLIT): New macro, avoid use of split-complex altogether.
+	* src/vsip/opt/diag/eval.hpp (Dispatch_name): Add missing impl tags.
+	* tests/fft.cpp: Fix Wall warning.
+	* benchmarks/conv.cpp: Add diag output.
+	* benchmarks/conv2d.cpp: New file, benchmark for 2D convolution.
+
 2007-07-30  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/layout.hpp: Fix typo.
Index: src/vsip/core/signal/conv.hpp
===================================================================
--- src/vsip/core/signal/conv.hpp	(revision 176624)
+++ src/vsip/core/signal/conv.hpp	(working copy)
@@ -22,9 +22,8 @@
 #include <vsip/core/signal/types.hpp>
 #include <vsip/core/profile.hpp>
 #include <vsip/core/signal/conv_common.hpp>
-#ifndef VSIP_IMPL_REF_IMPL
+#if !VSIP_IMPL_REF_IMPL
 # include <vsip/opt/signal/conv_ext.hpp>
-#else
 # if VSIP_IMPL_HAVE_IPP
 #  include <vsip/opt/ipp/conv.hpp>
 # endif
Index: src/vsip/opt/ipp/fir.hpp
===================================================================
--- src/vsip/opt/ipp/fir.hpp	(revision 176624)
+++ src/vsip/opt/ipp/fir.hpp	(working copy)
@@ -128,11 +128,9 @@
     // Make data be available with unit-stride.
     typedef Layout<1, tuple<0,1,2>, Stride_unit, Cmplx_inter_fmt> layout_type;
     Ext_data<sub_block_type, layout_type> ext_in
-      (sub_in_block, SYNC_IN,
-       Ext_data<block_type>(this->temp_in_.block()).data());
+      (sub_in_block, SYNC_IN, temp_in_.get());
     Ext_data<sub_block_type, layout_type>  ext_out
-      (sub_out_block, SYNC_OUT,
-       Ext_data<block_type>(this->temp_out_.block()).data());
+      (sub_out_block, SYNC_OUT, temp_out_.get());
     Ext_data<block_type, layout_type>  ext_kernel(this->kernel_.block());
     Ext_data<block_type, layout_type>  ext_state(this->state_.block());
     length_type const d = this->decimation();
@@ -158,8 +156,8 @@
   Vector<T, block_type> kernel_; 
   Vector<T, block_type> state_;
   length_type state_saved_;   // number of elements saved
-  Vector<T, block_type> temp_in_;
-  Vector<T, block_type> temp_out_;
+  aligned_array<T> temp_in_;
+  aligned_array<T> temp_out_;
 };
 } // namespace vsip::impl::ipp
 
Index: src/vsip/opt/fftw3/fft_impl.cpp
===================================================================
--- src/vsip/opt/fftw3/fft_impl.cpp	(revision 177792)
+++ src/vsip/opt/fftw3/fft_impl.cpp	(working copy)
@@ -29,18 +29,28 @@
 
 
 // 070729: FFTW 3.1.2's split in-place complex-to-complex FFT is
-// broken.  The plan captures the gap between the real and imaginary
-// components.
+// broken on PowerPC and x86.  The plan captures the gap between the
+// real and imaginary components.
 //
+// 070730: FFTW 3.1.2 split out-of-place complex FFT is broken on
+// PowerPC.
+//
 // 070730: FFTW 3.1.2's split real-complex and complex-real FFT
-// also appear broken.
+// also appear broken on x86.
 //
-// As a work-around: copy, then perform transform out-of-place.
+// Brave souls may set
+//   USE_FFTW_SPLIT 1
+//   USE_BROKEN_FFTW_SPLIT 0
+// to attempt a work-around: copy, then perform transform out-of-place.
 
+// Control whether FFTW split-complex transforms are performed at all.
+#define USE_FFTW_SPLIT 0
+
+// Control whether a subset broken FFTW split-complex transforms are
+// worked around.
 #define USE_BROKEN_FFTW_SPLIT 0
 
 
-
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -52,6 +62,12 @@
 namespace fftw3
 {
 
+#if USE_FFTW_SPLIT
+typedef vsip::impl::dense_complex_type fftw3_complex_type;
+#else
+typedef Cmplx_inter_fmt fftw3_complex_type;
+#endif
+
 template <dimension_type D>
 struct Fft_base<D, std::complex<SCALAR_TYPE>, std::complex<SCALAR_TYPE> >
 {
@@ -68,13 +84,13 @@
     
     for(index_type i=0;i<D;i++) size_[i] = dom[i].size();
     plan_in_place_ =
-      Create_plan<vsip::impl::dense_complex_type>
+      Create_plan<fftw3_complex_type>
         ::create<FFTW(plan), FFTW(iodim)>
         (in_buffer_.ptr(), in_buffer_.ptr(), exp, flags, dom);
     
     if (!plan_in_place_) VSIP_IMPL_THROW(std::bad_alloc());
 
-    plan_by_reference_ = Create_plan<vsip::impl::dense_complex_type>
+    plan_by_reference_ = Create_plan<fftw3_complex_type>
       ::create<FFTW(plan), FFTW(iodim)>
       (in_buffer_.ptr(), out_buffer_.ptr(), exp, flags, dom);
 
@@ -90,8 +106,8 @@
     if (plan_by_reference_) FFTW(destroy_plan)(plan_by_reference_);
   }
 
-  Cmplx_buffer<dense_complex_type, SCALAR_TYPE> in_buffer_;
-  Cmplx_buffer<dense_complex_type, SCALAR_TYPE> out_buffer_;
+  Cmplx_buffer<fftw3_complex_type, SCALAR_TYPE> in_buffer_;
+  Cmplx_buffer<fftw3_complex_type, SCALAR_TYPE> out_buffer_;
   FFTW(plan) plan_in_place_;
   FFTW(plan) plan_by_reference_;
   int size_[D];
@@ -112,7 +128,7 @@
     // FFTW3 assumes A == D - 1.
     // See also query_layout().
     if (A != D - 1) std::swap(size_[A], size_[D - 1]);
-    plan_by_reference_ = Create_plan<dense_complex_type>::
+    plan_by_reference_ = Create_plan<fftw3_complex_type>::
       create<FFTW(plan), FFTW(iodim)>
       (in_buffer_.get(), out_buffer_.ptr(), A, flags, dom);
     if (!plan_by_reference_) VSIP_IMPL_THROW(std::bad_alloc());
@@ -123,7 +139,7 @@
   }
 
   aligned_array<SCALAR_TYPE> in_buffer_;
-  Cmplx_buffer<dense_complex_type, SCALAR_TYPE> out_buffer_;
+  Cmplx_buffer<fftw3_complex_type, SCALAR_TYPE> out_buffer_;
   FFTW(plan) plan_by_reference_;
   int size_[D];
   bool aligned_;
@@ -143,7 +159,7 @@
     // FFTW3 assumes A == D - 1.
     // See also query_layout().
     if (A != D - 1) std::swap(size_[A], size_[D - 1]);
-    plan_by_reference_ = Create_plan<dense_complex_type>::
+    plan_by_reference_ = Create_plan<fftw3_complex_type>::
       create<FFTW(plan), FFTW(iodim)>
       (in_buffer_.ptr(), out_buffer_.get(), A, flags, dom);
 
@@ -154,7 +170,7 @@
     if (plan_by_reference_) FFTW(destroy_plan)(plan_by_reference_);
   }
 
-  Cmplx_buffer<dense_complex_type, SCALAR_TYPE> in_buffer_;
+  Cmplx_buffer<fftw3_complex_type, SCALAR_TYPE> in_buffer_;
   aligned_array<SCALAR_TYPE>              out_buffer_;
   FFTW(plan) plan_by_reference_;
   int size_[D];
@@ -186,14 +202,14 @@
     rtl_inout.align = VSIP_IMPL_ALLOC_ALIGNMENT;
     rtl_inout.order = tuple<0, 1, 2>();
     // make default based on library
-    rtl_inout.complex = Create_plan<dense_complex_type>::format;
+    rtl_inout.complex = Create_plan<fftw3_complex_type>::format;
   }
   virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
   {
     rtl_in.pack = this->aligned_ ? stride_unit_align : stride_unit_dense;
     rtl_in.align = VSIP_IMPL_ALLOC_ALIGNMENT;
     rtl_in.order = tuple<0, 1, 2>();
-    rtl_in.complex = Create_plan<dense_complex_type>::format;
+    rtl_in.complex = Create_plan<fftw3_complex_type>::format;
     rtl_out = rtl_in;
   }
   virtual void in_place(ctype *inout, stride_type s, length_type l)
@@ -217,7 +233,7 @@
 			      inout.second, inout.first,
 			      inout.second, inout.first);
 #else
-    typedef Storage<dense_complex_type, ctype> storage_type;
+    typedef Storage<fftw3_complex_type, ctype> storage_type;
     rtype* real = storage_type::get_real_ptr(in_buffer_.ptr());
     rtype* imag = storage_type::get_imag_ptr(in_buffer_.ptr());
     memcpy(real, inout.first, l*sizeof(rtype));
@@ -282,7 +298,7 @@
     rtl_in.pack = this->aligned_ ? stride_unit_align : stride_unit_dense;
     rtl_in.align = VSIP_IMPL_ALLOC_ALIGNMENT;
     rtl_in.order = tuple<0, 1, 2>();
-    rtl_in.complex = Create_plan<dense_complex_type>::format;
+    rtl_in.complex = Create_plan<fftw3_complex_type>::format;
     rtl_out = rtl_in;
   }
   virtual void by_reference(rtype *in, stride_type,
@@ -302,7 +318,7 @@
     FFTW(execute_split_dft_r2c)(plan_by_reference_, 
 			  in, out.first, out.second);
 #else
-    typedef Storage<dense_complex_type, ctype> storage_type;
+    typedef Storage<fftw3_complex_type, ctype> storage_type;
     rtype* out_r = storage_type::get_real_ptr(out_buffer_.ptr());
     rtype* out_i = storage_type::get_imag_ptr(out_buffer_.ptr());
     FFTW(execute_split_dft_r2c)(plan_by_reference_, 
@@ -336,7 +352,7 @@
     rtl_in.pack = this->aligned_ ? stride_unit_align : stride_unit_dense;
     rtl_in.align = VSIP_IMPL_ALLOC_ALIGNMENT;
     rtl_in.order = tuple<0, 1, 2>();
-    rtl_in.complex = Create_plan<dense_complex_type>::format;
+    rtl_in.complex = Create_plan<fftw3_complex_type>::format;
     rtl_out = rtl_in;
   }
 
@@ -359,7 +375,7 @@
     FFTW(execute_split_dft_c2r)(plan_by_reference_,
 			  in.first, in.second, out);
 #else
-    typedef Storage<dense_complex_type, ctype> storage_type;
+    typedef Storage<fftw3_complex_type, ctype> storage_type;
     rtype* in_r = storage_type::get_real_ptr(in_buffer_.ptr());
     rtype* in_i = storage_type::get_imag_ptr(in_buffer_.ptr());
     memcpy(in_r, in.first, (length/2+1)*sizeof(rtype));
@@ -392,7 +408,7 @@
   {
     rtl_in.pack = stride_unit_dense;
     rtl_in.order = row2_type();
-    rtl_in.complex = Create_plan<dense_complex_type>::format;
+    rtl_in.complex = Create_plan<fftw3_complex_type>::format;
     rtl_out = rtl_in;
   }
   virtual void in_place(ctype *inout,
@@ -477,7 +493,7 @@
     // FFTW3 assumes A is the last dimension.
     if (A == 0) rtl_in.order = tuple<1, 0, 2>();
     else rtl_in.order = tuple<0, 1, 2>();
-    rtl_in.complex = Create_plan<dense_complex_type>::format;
+    rtl_in.complex = Create_plan<fftw3_complex_type>::format;
     rtl_out = rtl_in;
   }
   virtual bool requires_copy(Rt_layout<2> &) { return true;}
@@ -527,7 +543,7 @@
     // FFTW3 assumes A is the last dimension.
     if (A == 0) rtl_in.order = tuple<1, 0, 2>();
     else rtl_in.order = tuple<0, 1, 2>();
-    rtl_in.complex = Create_plan<dense_complex_type>::format;
+    rtl_in.complex = Create_plan<fftw3_complex_type>::format;
     rtl_out = rtl_in;
   }
   virtual bool requires_copy(Rt_layout<2> &) { return true;}
@@ -575,7 +591,7 @@
   {
     rtl_in.pack = stride_unit_dense;
     rtl_in.order = row3_type();
-    rtl_in.complex = Create_plan<dense_complex_type>::format;
+    rtl_in.complex = Create_plan<fftw3_complex_type>::format;
     rtl_out = rtl_in;
   }
   virtual void in_place(ctype *inout,
@@ -706,7 +722,7 @@
       case 1: rtl_in.order = tuple<0, 2, 1>(); break;
       default: rtl_in.order = tuple<0, 1, 2>(); break;
     }
-    rtl_in.complex = Create_plan<dense_complex_type>::format;
+    rtl_in.complex = Create_plan<fftw3_complex_type>::format;
     rtl_out = rtl_in;
   }
   virtual bool requires_copy(Rt_layout<3> &) { return true;}
@@ -772,7 +788,7 @@
       case 1: rtl_in.order = tuple<0, 2, 1>(); break;
       default: rtl_in.order = tuple<0, 1, 2>(); break;
     }
-    rtl_in.complex = Create_plan<dense_complex_type>::format;
+    rtl_in.complex = Create_plan<fftw3_complex_type>::format;
     rtl_out = rtl_in;
   }
   virtual bool requires_copy(Rt_layout<3> &) { return true;}
@@ -837,7 +853,7 @@
     if (A == 0) rtl_in.order = tuple<1, 0, 2>();
     else  rtl_in.order = tuple<0, 1, 2>();
     // make default based on library
-    rtl_in.complex = Create_plan<dense_complex_type>::format;
+    rtl_in.complex = Create_plan<fftw3_complex_type>::format;
     rtl_out = rtl_in;
   }
   virtual void by_reference(rtype *in,
@@ -882,7 +898,7 @@
     rtype* out_i = out.second;
 
 #if !USE_BROKEN_FFTW_SPLIT
-    typedef Storage<dense_complex_type, ctype> storage_type;
+    typedef Storage<fftw3_complex_type, ctype> storage_type;
     rtype* tmp_out_r = storage_type::get_real_ptr(out_buffer_.ptr());
     rtype* tmp_out_i = storage_type::get_imag_ptr(out_buffer_.ptr());
 #endif
@@ -937,7 +953,7 @@
     if (A == 0) rtl_in.order = tuple<1, 0, 2>();
     else  rtl_in.order = tuple<0, 1, 2>();
     // make default based on library
-    rtl_in.complex = Create_plan<dense_complex_type>::format;
+    rtl_in.complex = Create_plan<fftw3_complex_type>::format;
     rtl_out = rtl_in;
   }
   virtual bool requires_copy(Rt_layout<2> &) { return true;}
@@ -984,7 +1000,7 @@
     rtype* in_i = in.second;
 
 #if !USE_BROKEN_FFTW_SPLIT
-    typedef Storage<dense_complex_type, ctype> storage_type;
+    typedef Storage<fftw3_complex_type, ctype> storage_type;
     rtype* tmp_in_r = storage_type::get_real_ptr(in_buffer_.ptr());
     rtype* tmp_in_i = storage_type::get_imag_ptr(in_buffer_.ptr());
 #endif
@@ -1040,7 +1056,7 @@
     if (A == 0) rtl_inout.order = tuple<1, 0, 2>();
     else rtl_inout.order = tuple<0, 1, 2>();
     // make default based on library
-    rtl_inout.complex = Create_plan<dense_complex_type>::format;
+    rtl_inout.complex = Create_plan<fftw3_complex_type>::format;
   }
 
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
@@ -1050,7 +1066,7 @@
     if (A == 0) rtl_in.order = tuple<1, 0, 2>();
     else  rtl_in.order = tuple<0, 1, 2>();
     // make default based on library
-    rtl_in.complex = Create_plan<dense_complex_type>::format;
+    rtl_in.complex = Create_plan<fftw3_complex_type>::format;
     rtl_out = rtl_in;
   }
 
@@ -1058,7 +1074,7 @@
 			stride_type str_0, stride_type str_1,
 			length_type rows, length_type cols)
   {
-    assert((Type_equal<dense_complex_type, Cmplx_inter_fmt>::value));
+    assert((Type_equal<fftw3_complex_type, Cmplx_inter_fmt>::value));
 
     length_type const n_fft       = (A == 1) ? rows : cols;
     stride_type const fft_stride  = (A == 1) ? str_0 : str_1;
@@ -1083,7 +1099,7 @@
     length_type rows,
     length_type cols)
   {
-    assert((Type_equal<dense_complex_type, Cmplx_split_fmt>::value));
+    assert((Type_equal<fftw3_complex_type, Cmplx_split_fmt>::value));
 
     length_type const n_fft       = (A == 1) ? rows : cols;
     stride_type const fft_stride  = (A == 1) ? str_0 : str_1;
@@ -1107,7 +1123,7 @@
 				imag_ptr, real_ptr,
 				imag_ptr, real_ptr);
 #else
-      typedef Storage<dense_complex_type, ctype> storage_type;
+      typedef Storage<fftw3_complex_type, ctype> storage_type;
       rtype* tmp_in_r = storage_type::get_real_ptr(in_buffer_.ptr());
       rtype* tmp_in_i = storage_type::get_imag_ptr(in_buffer_.ptr());
       memcpy(tmp_in_r, real_ptr, size_[0]*sizeof(rtype));
Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 176624)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -66,6 +66,8 @@
 VSIP_IMPL_DISPATCH_NAME(Fc_expr_tag)
 VSIP_IMPL_DISPATCH_NAME(Rbo_expr_tag)
 VSIP_IMPL_DISPATCH_NAME(Loop_fusion_tag)
+VSIP_IMPL_DISPATCH_NAME(Cvsip_tag)
+VSIP_IMPL_DISPATCH_NAME(Generic_tag)
 
 VSIP_IMPL_DISPATCH_NAME(Tag_illegal_mix_of_local_and_global_in_assign)
 VSIP_IMPL_DISPATCH_NAME(Tag_serial_expr)
Index: tests/fft.cpp
===================================================================
--- tests/fft.cpp	(revision 177792)
+++ tests/fft.cpp	(working copy)
@@ -72,6 +72,8 @@
     std::cout << "  v1 =\n" << v1;
     std::cout << "  v2 =\n" << v2;
   }
+#else
+  (void)where;
 #endif
   test_assert(error < epsilon);
 }
Index: benchmarks/conv.cpp
===================================================================
--- benchmarks/conv.cpp	(revision 173215)
+++ benchmarks/conv.cpp	(working copy)
@@ -7,7 +7,7 @@
 /** @file    benchmarks/conv.cpp
     @author  Jules Bergmann
     @date    2005-07-11
-    @brief   VSIPL++ Library: Benchmark for Convolution.
+    @brief   VSIPL++ Library: Benchmark for 1D Convolution.
 
 */
 
@@ -22,7 +22,7 @@
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
 
-#include <vsip/core/profile.hpp>
+#include <vsip/opt/diag/eval.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
@@ -99,6 +99,13 @@
 
   t_conv1(length_type coeff_size) : coeff_size_(coeff_size) {}
 
+  void diag()
+  {
+    using impl::diag_detail::Dispatch_name;
+    typedef typename impl::Choose_conv_impl<1, T>::type impl_tag;
+    std::cout << "BE: " << Dispatch_name<impl_tag>::name() << std::endl;
+  }
+
   length_type coeff_size_;
 };
 
Index: benchmarks/conv2d.cpp
===================================================================
--- benchmarks/conv2d.cpp	(revision 0)
+++ benchmarks/conv2d.cpp	(revision 0)
@@ -0,0 +1,172 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    benchmarks/conv.cpp
+    @author  Jules Bergmann
+    @date    2005-07-11
+    @brief   VSIPL++ Library: Benchmark for Convolution.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+#include <vsip/signal.hpp>
+
+#include <vsip/opt/diag/eval.hpp>
+
+#include <vsip_csl/test.hpp>
+#include "loop.hpp"
+
+using namespace vsip;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <support_region_type Supp,
+	  typename            T>
+struct t_conv2d : Benchmark_base
+{
+  static length_type const rdec = 1;
+  static length_type const cdec = 1;
+
+  char* what() { return "t_conv2d"; }
+
+  void output_size(
+    length_type  rows,   length_type  cols,
+    length_type& o_rows, length_type& o_cols)
+  {
+    if      (Supp == support_full)
+    {
+      o_rows = ((rows + m_ - 2)/rdec) + 1;
+      o_cols = ((cols + n_ - 2)/cdec) + 1;
+    }
+    else if (Supp == support_same)
+    {
+      o_rows = ((rows - 1)/rdec) + 1;
+      o_cols = ((cols - 1)/cdec) + 1;
+    }
+    else /* (Supp == support_min) */
+    {
+      o_rows = ((rows-1)/rdec) - ((m_-1)/rdec) + 1;
+      o_cols = ((cols-1)/cdec) - ((n_-1)/rdec) + 1;
+    }
+  }
+  
+  float ops_per_point(length_type cols)
+  {
+    length_type o_rows, o_cols;
+
+    output_size(rows_, cols, o_rows, o_cols);
+
+    float ops = m_ * n_ * o_rows * o_cols *
+      (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
+
+    return ops / cols;
+  }
+
+  int riob_per_point(length_type) { return -1; }
+  int wiob_per_point(length_type) { return -1; }
+  int mem_per_point(length_type)  { return 2*sizeof(T); }
+
+  void operator()(length_type cols, length_type loop, float& time)
+  {
+    length_type o_rows, o_cols;
+
+    output_size(rows_, cols, o_rows, o_cols);
+
+    Matrix<T>   in (rows_, cols, T());
+    Matrix<T>   out(o_rows, o_cols);
+    Matrix<T>   coeff(m_, n_, T());
+
+    coeff = T(1);
+
+    symmetry_type const       symmetry = nonsym;
+
+    typedef Convolution<const_Matrix, symmetry, Supp, T> conv_type;
+
+    conv_type conv(coeff, Domain<2>(rows_, cols), rdec);
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      conv(in, out);
+    t1.stop();
+    
+    time = t1.delta();
+  }
+
+  t_conv2d(length_type rows, length_type m, length_type n)
+    : rows_(rows), m_(m), n_(n)
+  {}
+
+  void diag()
+  {
+    using impl::diag_detail::Dispatch_name;
+    typedef typename impl::Choose_conv_impl<2, T>::type impl_tag;
+    std::cout << "BE: " << Dispatch_name<impl_tag>::name() << std::endl;
+  }
+
+  length_type rows_;
+  length_type m_;
+  length_type n_;
+};
+
+
+
+void
+defaults(Loop1P& loop)
+{
+  loop.loop_start_ = 5000;
+  loop.start_ = 4;
+
+  loop.param_["rows"] = "16";
+  loop.param_["mn"]   = "0";
+  loop.param_["m"]    = "3";
+  loop.param_["n"]    = "3";
+}
+
+
+
+int
+test(Loop1P& loop, int what)
+{
+  typedef complex<float> cf_type;
+
+  length_type rows = atoi(loop.param_["rows"].c_str());
+  length_type MN   = atoi(loop.param_["mn"].c_str());
+  length_type M    = atoi(loop.param_["m"].c_str());
+  length_type N    = atoi(loop.param_["n"].c_str());
+
+  std::cout << "MN: " << MN << std::endl;
+
+  if (MN != 0)
+    M = N = MN;
+
+  switch (what)
+  {
+  case  1: loop(t_conv2d<support_full, float>(rows, M, N)); break;
+  case  2: loop(t_conv2d<support_same, float>(rows, M, N)); break;
+  case  3: loop(t_conv2d<support_min, float> (rows, M, N)); break;
+
+  // case  4: loop(t_conv1<support_full, cf_type>(loop.user_param_)); break;
+  // case  5: loop(t_conv1<support_same, cf_type>(loop.user_param_)); break;
+  // case  6: loop(t_conv1<support_min,  cf_type>(loop.user_param_)); break;
+
+  default: return 0;
+  }
+  return 1;
+}
