Index: ChangeLog
===================================================================
--- ChangeLog	(revision 177533)
+++ ChangeLog	(working copy)
@@ -1,3 +1,27 @@
+2007-07-30  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/layout.hpp: Fix typo.
+	* src/vsip/core/parallel/scalar_block_map.hpp (impl_apply): Remove
+	  assert.
+	* src/vsip/core/parallel/expr.hpp (Par_expr_block): Add pass-thru
+	  Is_sized_block trait.
+	* src/vsip/opt/fftw3/fft_impl.cpp: Work around FFTW split-complex
+	  bugs.  Fix broken VSIPL++ split-complex inverse transforms.
+	  Add missing transforms for FFTM split real->complex and
+	  complex->real.
+	* src/vsip/opt/simd/expr_evaluator.hpp: Fix handling of unaligned
+	  data.
+	* src/vsip/opt/simd/expr_iterator.hpp: Likewise.
+	* src/vsip/opt/diag/extdata.hpp (Diagnose_rt_ext_data): New helper
+	  function for debugging Rt_ext_data.
+	* tests/regressions/fft_ip_subview.cpp: New file, test in-place
+	  FFT and FFTM, including subviews.
+	* tests/regressions/simd_alignment.cpp: New file, test SIMD with
+	  unaligned data.
+	* tests/regressions/subview_exprs.cpp: Add VERBOSE output.
+	* tests/fftm.cpp: Fix typo in file header.
+	* tests/fft.cpp: Add more VERBOSE output.
+	
 2007-07-27  Jules Bergmann  <jules@codesourcery.com>
 
 	Fix bug with distributed matrix and tensor index reductions.
Index: src/vsip/core/layout.hpp
===================================================================
--- src/vsip/core/layout.hpp	(revision 177479)
+++ src/vsip/core/layout.hpp	(working copy)
@@ -797,7 +797,7 @@
   {
     size_[0] = size_of_dim(extent, 0);
     size_[1] = size_of_dim(extent, 1);
-    size_[2] = size_of_dim(extent, 1);
+    size_[2] = size_of_dim(extent, 2);
 
     stride_[Dim2] = 1;
     stride_[Dim1] = size_[Dim2];
Index: src/vsip/core/parallel/scalar_block_map.hpp
===================================================================
--- src/vsip/core/parallel/scalar_block_map.hpp	(revision 176624)
+++ src/vsip/core/parallel/scalar_block_map.hpp	(working copy)
@@ -81,14 +81,14 @@
 
   const_Vector<processor_type> processor_set() const
     { return vsip::processor_set(); }
-
+  
   // Applied map functions.
 public:
   length_type impl_num_patches(index_type sb) const VSIP_NOTHROW
     { assert(sb == 0); return 1; }
 
   void impl_apply(Domain<Dim> const& /*dom*/) VSIP_NOTHROW
-    { assert(0); }
+    {}
 
   template <dimension_type Dim2>
   Domain<Dim2> impl_subblock_domain(index_type sb) const VSIP_NOTHROW
Index: src/vsip/core/parallel/expr.hpp
===================================================================
--- src/vsip/core/parallel/expr.hpp	(revision 176624)
+++ src/vsip/core/parallel/expr.hpp	(working copy)
@@ -182,6 +182,16 @@
   typename View_block_storage<BlockT>::expr_type blk_;
 };
 
+
+
+template <dimension_type Dim,
+	  typename       MapT,
+	  typename       BlockT>
+struct Is_sized_block<Par_expr_block<Dim, MapT, BlockT, Peb_reuse_tag> >
+{ static bool const value = Is_sized_block<BlockT>::value; };
+
+
+
 template <typename RetBlock>
 struct Create_subblock;
 
Index: src/vsip/opt/fftw3/fft_impl.cpp
===================================================================
--- src/vsip/opt/fftw3/fft_impl.cpp	(revision 176624)
+++ src/vsip/opt/fftw3/fft_impl.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -15,6 +15,8 @@
   Included Files
 ***********************************************************************/
 
+#include <cassert>
+
 #include <vsip/support.hpp>
 #include <vsip/domain.hpp>
 #include <vsip/core/fft/backend.hpp>
@@ -24,6 +26,21 @@
 #include <vsip/dense.hpp>
 #include <fftw3.h>
 
+
+
+// 070729: FFTW 3.1.2's split in-place complex-to-complex FFT is
+// broken.  The plan captures the gap between the real and imaginary
+// components.
+//
+// 070730: FFTW 3.1.2's split real-complex and complex-real FFT
+// also appear broken.
+//
+// As a work-around: copy, then perform transform out-of-place.
+
+#define USE_BROKEN_FFTW_SPLIT 0
+
+
+
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -189,9 +206,30 @@
   virtual void in_place(ztype inout, stride_type s, length_type l)
   {
     assert(s == 1 && static_cast<int>(l) == this->size_[0]);
-    FFTW(execute_split_dft)(plan_in_place_,
-		      inout.first, inout.second,
-		      inout.first, inout.second);
+
+#if USE_BROKEN_FFTW_SPLIT
+    if (E == -1)
+      FFTW(execute_split_dft)(plan_in_place_,
+			      inout.first, inout.second,
+			      inout.first, inout.second);
+    else
+      FFTW(execute_split_dft)(plan_in_place_,
+			      inout.second, inout.first,
+			      inout.second, inout.first);
+#else
+    rtype* real = in_buffer_.ptr().first;
+    rtype* imag = in_buffer_.ptr().second;
+    memcpy(real, inout.first, l*sizeof(rtype));
+    memcpy(imag, inout.second, l*sizeof(rtype));
+    if (E == -1)
+      FFTW(execute_split_dft)(plan_by_reference_,
+			      real, imag,
+			      inout.first, inout.second);
+    else
+      FFTW(execute_split_dft)(plan_by_reference_,
+			      imag, real,
+			      inout.second, inout.first);
+#endif
   }
   virtual void by_reference(ctype *in, stride_type in_stride,
 			    ctype *out, stride_type out_stride,
@@ -209,9 +247,31 @@
   {
     assert(in_stride == 1 && out_stride == 1 &&
 	   static_cast<int>(length) == this->size_[0]);
-    FFTW(execute_split_dft)(plan_by_reference_,
-		      in.first,  in.second,
-		      out.first, out.second);
+#if 1
+    if (E == -1)
+      FFTW(execute_split_dft)(plan_by_reference_,
+			      in.first,  in.second,
+			      out.first, out.second);
+    else
+      FFTW(execute_split_dft)(plan_by_reference_,
+			      in.second,  in.first,
+			      out.second, out.first);
+#else
+    rtype* in_r = in_buffer_.ptr().first;
+    rtype* in_i = in_buffer_.ptr().second;
+    rtype* out_r = out_buffer_.ptr().first;
+    rtype* out_i = out_buffer_.ptr().second;
+    memcpy(in_r, in.first, length*sizeof(rtype));
+    memcpy(in_i, in.second, length*sizeof(rtype));
+    if (E == -1)
+      FFTW(execute_split_dft)(plan_by_reference_,
+			      in_r, in_i, out_r, out_i);
+    else
+      FFTW(execute_split_dft)(plan_by_reference_,
+			      in_i, in_r, out_i, out_r);
+    memcpy(out.first,  out_r, length*sizeof(rtype));
+    memcpy(out.second, out_i, length*sizeof(rtype));
+#endif
   }
 };
 
@@ -249,12 +309,21 @@
   }
   virtual void by_reference(rtype *in, stride_type is,
 			    ztype out, stride_type os,
-			    length_type)
+			    length_type length)
   {
     assert(is == 1);
     assert(os == 1);
+#if USE_BROKEN_FFTW_SPLIT
     FFTW(execute_split_dft_r2c)(plan_by_reference_, 
 			  in, out.first, out.second);
+#else
+    rtype* out_r = out_buffer_.ptr().first;
+    rtype* out_i = out_buffer_.ptr().second;
+    FFTW(execute_split_dft_r2c)(plan_by_reference_, 
+				in, out_r, out_i);
+    memcpy(out.first,  out_r, (length/2+1)*sizeof(rtype));
+    memcpy(out.second, out_i, (length/2+1)*sizeof(rtype));
+#endif
   }
 };
 
@@ -296,12 +365,21 @@
   }
   virtual void by_reference(ztype in, stride_type is,
 			    rtype *out, stride_type os,
-			    length_type)
+			    length_type length)
   {
     assert(is == 1);
     assert(os == 1);
+#if USE_BROKEN_FFTW_SPLIT
     FFTW(execute_split_dft_c2r)(plan_by_reference_,
 			  in.first, in.second, out);
+#else
+    rtype* in_r = in_buffer_.ptr().first;
+    rtype* in_i = in_buffer_.ptr().second;
+    memcpy(in_r, in.first, (length/2+1)*sizeof(rtype));
+    memcpy(in_i, in.second, (length/2+1)*sizeof(rtype));
+    FFTW(execute_split_dft_c2r)(plan_by_reference_,
+			  in_r, in_i, out);
+#endif
   }
 };
 
@@ -771,7 +849,8 @@
     rtl_in.align = VSIP_IMPL_ALLOC_ALIGNMENT;
     if (A == 0) rtl_in.order = tuple<1, 0, 2>();
     else  rtl_in.order = tuple<0, 1, 2>();
-    rtl_in.complex = cmplx_inter_fmt;
+    // make default based on library
+    rtl_in.complex = Create_plan<dense_complex_type>::format;
     rtl_out = rtl_in;
   }
   virtual void by_reference(rtype *in,
@@ -795,12 +874,46 @@
       out += out_fft_stride;
     }
   }
-  virtual void by_reference(rtype *,
-			    stride_type, stride_type,
-			    ztype,
-			    stride_type, stride_type,
-			    length_type, length_type)
+  virtual void by_reference(
+    rtype*      in,
+    stride_type i_str_0,
+    stride_type i_str_1,
+    ztype       out,
+    stride_type o_str_0,
+    stride_type o_str_1,
+    length_type rows,
+    length_type cols)
   {
+    length_type const n_fft          = (A == 1) ? rows : cols;
+    length_type const in_fft_stride  = (A == 1) ? i_str_0 : i_str_1;
+    length_type const out_fft_stride = (A == 1) ? o_str_0 : o_str_1;
+
+    if (A == 1) assert(rows <= mult_ && static_cast<int>(cols) == size_[0]);
+    else        assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+
+    rtype* out_r = out.first;
+    rtype* out_i = out.second;
+
+#if !USE_BROKEN_FFTW_SPLIT
+    rtype* tmp_out_r = out_buffer_.ptr().first;
+    rtype* tmp_out_i = out_buffer_.ptr().second;
+#endif
+
+    for (index_type i = 0; i < n_fft; ++i)
+    {
+#if USE_BROKEN_FFTW_SPLIT
+      FFTW(execute_split_dft_r2c)(plan_by_reference_,
+				  in, out_r, out_i);
+#else
+      FFTW(execute_split_dft_r2c)(plan_by_reference_,
+				  in, tmp_out_r, tmp_out_i);
+      memcpy(out_r, tmp_out_r, (size_[0]/2+1)*sizeof(rtype));
+      memcpy(out_i, tmp_out_i, (size_[0]/2+1)*sizeof(rtype));
+#endif
+      in    += in_fft_stride;
+      out_r += out_fft_stride;
+      out_i += out_fft_stride;
+    }
   }
 
 private:
@@ -835,7 +948,8 @@
     rtl_in.align = VSIP_IMPL_ALLOC_ALIGNMENT;
     if (A == 0) rtl_in.order = tuple<1, 0, 2>();
     else  rtl_in.order = tuple<0, 1, 2>();
-    rtl_in.complex = cmplx_inter_fmt;
+    // make default based on library
+    rtl_in.complex = Create_plan<dense_complex_type>::format;
     rtl_out = rtl_in;
   }
   virtual bool requires_copy(Rt_layout<2> &) { return true;}
@@ -861,12 +975,46 @@
       out += out_fft_stride;
     }
   }
-  virtual void by_reference(ztype,
-			    stride_type, stride_type,
-			    rtype *,
-			    stride_type, stride_type,
-			    length_type, length_type)
+  virtual void by_reference(
+    ztype       in,
+    stride_type i_str_0,
+    stride_type i_str_1,
+    rtype*      out,
+    stride_type o_str_0,
+    stride_type o_str_1,
+    length_type rows,
+    length_type cols)
   {
+    length_type const n_fft          = (A == 1) ? rows : cols;
+    length_type const in_fft_stride  = (A == 1) ? i_str_0 : i_str_1;
+    length_type const out_fft_stride = (A == 1) ? o_str_0 : o_str_1;
+
+    if (A == 1) assert(rows <= mult_ && static_cast<int>(cols) == size_[0]);
+    else        assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+
+    rtype* in_r = in.first;
+    rtype* in_i = in.second;
+
+#if !USE_BROKEN_FFTW_SPLIT
+    rtype* tmp_in_r = in_buffer_.ptr().first;
+    rtype* tmp_in_i = in_buffer_.ptr().second;
+#endif
+
+    for (index_type i = 0; i < n_fft; ++i)
+    {
+#if USE_BROKEN_FFTW_SPLIT
+      FFTW(execute_split_dft_c2r)(plan_by_reference_,
+				  in_r, in_i, out);
+#else
+      memcpy(tmp_in_r, in_r, (size_[0]/2+1)*sizeof(rtype));
+      memcpy(tmp_in_i, in_i, (size_[0]/2+1)*sizeof(rtype));
+      FFTW(execute_split_dft_c2r)(plan_by_reference_,
+				  tmp_in_r, tmp_in_i, out);
+#endif
+      in_r += in_fft_stride;
+      in_i += in_fft_stride;
+      out  += out_fft_stride;
+    }
   }
 
 private:
@@ -895,35 +1043,98 @@
 
   virtual char const* name() { return "fftm-fftw3-complex"; }
 
+  virtual void query_layout(Rt_layout<2> &rtl_inout)
+  {
+    // By default use unit_stride,
+    rtl_inout.pack = stride_unit;
+    // an ordering that gives unit strides on the axis perpendicular to A,
+    if (A == 0) rtl_inout.order = tuple<1, 0, 2>();
+    else rtl_inout.order = tuple<0, 1, 2>();
+    // make default based on library
+    rtl_inout.complex = Create_plan<dense_complex_type>::format;
+  }
+
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
     rtl_in.pack = this->aligned_ ? stride_unit_align : stride_unit_dense;
     rtl_in.align = VSIP_IMPL_ALLOC_ALIGNMENT;
     if (A == 0) rtl_in.order = tuple<1, 0, 2>();
     else  rtl_in.order = tuple<0, 1, 2>();
-    rtl_in.complex = cmplx_inter_fmt;
+    // make default based on library
+    rtl_in.complex = Create_plan<dense_complex_type>::format;
     rtl_out = rtl_in;
   }
+
   virtual void in_place(ctype *inout,
-			stride_type, stride_type,
+			stride_type str_0, stride_type str_1,
 			length_type rows, length_type cols)
   {
-    length_type const n_fft = (A == 1) ? rows : cols;
+    assert((Type_equal<dense_complex_type, Cmplx_inter_fmt>::value));
+
+    length_type const n_fft       = (A == 1) ? rows : cols;
+    stride_type const fft_stride  = (A == 1) ? str_0 : str_1;
+
     if (A == 1) assert(rows <= mult_ && static_cast<int>(cols) == size_[0]);
-    else assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+    else        assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+    assert(((A == 1) ? str_1 : str_0) == 1);
+
     for (index_type i = 0; i != n_fft; ++i)
     {
       FFTW(execute_dft)(this->plan_in_place_, 
  			reinterpret_cast<FFTW(complex)*>(inout),
  			reinterpret_cast<FFTW(complex)*>(inout));
-      inout += size_[0];
+      inout += fft_stride;
     }
   }
 
-  virtual void in_place(ztype,
-			stride_type, stride_type,
-			length_type, length_type)
+  virtual void in_place(
+    ztype       inout,
+    stride_type str_0,
+    stride_type str_1,
+    length_type rows,
+    length_type cols)
   {
+    assert((Type_equal<dense_complex_type, Cmplx_split_fmt>::value));
+
+    length_type const n_fft       = (A == 1) ? rows : cols;
+    stride_type const fft_stride  = (A == 1) ? str_0 : str_1;
+
+    if (A == 1) assert(rows <= mult_ && static_cast<int>(cols) == size_[0]);
+    else        assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+    assert(((A == 1) ? str_1 : str_0) == 1);
+
+    rtype* real_ptr = inout.first;
+    rtype* imag_ptr = inout.second;
+
+    for (index_type i = 0; i != n_fft; ++i)
+    {
+#if USE_BROKEN_FFTW_SPLIT
+      if (E == -1)
+	FFTW(execute_split_dft)(this->plan_in_place_,
+				real_ptr, imag_ptr,
+				real_ptr, imag_ptr);
+      else
+	FFTW(execute_split_dft)(this->plan_in_place_,
+				imag_ptr, real_ptr,
+				imag_ptr, real_ptr);
+#else
+      rtype* tmp_real = in_buffer_.ptr().first;
+      rtype* tmp_imag = in_buffer_.ptr().second;
+      memcpy(tmp_real, real_ptr, size_[0]*sizeof(rtype));
+      memcpy(tmp_imag, imag_ptr, size_[0]*sizeof(rtype));
+      if (E == -1)
+	FFTW(execute_split_dft)(plan_by_reference_,
+				tmp_real, tmp_imag,
+				real_ptr, imag_ptr);
+      else
+	FFTW(execute_split_dft)(plan_by_reference_,
+				tmp_imag, tmp_real,
+				imag_ptr, real_ptr);
+#endif
+
+      real_ptr += fft_stride;
+      imag_ptr += fft_stride;
+    }
   }
 
   virtual void by_reference(ctype *in,
@@ -950,12 +1161,44 @@
       out += out_fft_stride;
     }
   }
-  virtual void by_reference(ztype,
-			    stride_type, stride_type,
-			    ztype,
-			    stride_type, stride_type,
-			    length_type, length_type)
+
+  virtual void by_reference(
+    ztype       in,
+    stride_type i_str_0,
+    stride_type i_str_1,
+    ztype       out,
+    stride_type o_str_0,
+    stride_type o_str_1,
+    length_type rows,
+    length_type cols)
   {
+    // If the inputs to the Fftm are distributed, the number of FFTs may
+    // be less than mult_.
+    length_type const n_fft          = (A == 1) ? rows : cols;
+    length_type const in_fft_stride  = (A == 1) ? i_str_0 : i_str_1;
+    length_type const out_fft_stride = (A == 1) ? o_str_0 : o_str_1;
+
+    if (A == 1) assert(rows <= mult_ && static_cast<int>(cols) == size_[0]);
+    else        assert(cols <= mult_ && static_cast<int>(rows) == size_[0]);
+
+    rtype* in_real  = in.first;
+    rtype* in_imag  = in.second;
+    rtype* out_real = out.first;
+    rtype* out_imag = out.second;
+
+    for (index_type i = 0; i != n_fft; ++i)
+    {
+      if (E == -1)
+	FFTW(execute_split_dft)(plan_by_reference_, 
+				in_real, in_imag, out_real, out_imag);
+      else
+	FFTW(execute_split_dft)(plan_by_reference_, 
+				in_imag, in_real, out_imag, out_real);
+      in_real  += in_fft_stride;
+      in_imag  += in_fft_stride;
+      out_real += out_fft_stride;
+      out_imag += out_fft_stride;
+    }
   }
 
 private:
Index: src/vsip/opt/simd/expr_evaluator.hpp
===================================================================
--- src/vsip/opt/simd/expr_evaluator.hpp	(revision 176624)
+++ src/vsip/opt/simd/expr_evaluator.hpp	(working copy)
@@ -304,6 +304,8 @@
       lhs.put(size-n, rhs.get(size-n));
       n--;
       raw_ptr++;
+      lp.increment_by_element(1);
+      rp.increment_by_element(1);
     }
 
     while (n >= vec_size)
@@ -315,7 +317,8 @@
     }
 
     // Process the remainder, using simple loop fusion.
-    for (index_type i = size - n; i != size; ++i) lhs.put(i, rhs.get(i));
+    for (index_type i = size - n; i != size; ++i)
+      lhs.put(i, rhs.get(i));
   }
 };
 
Index: src/vsip/opt/simd/expr_iterator.hpp
===================================================================
--- src/vsip/opt/simd/expr_iterator.hpp	(revision 176624)
+++ src/vsip/opt/simd/expr_iterator.hpp	(working copy)
@@ -274,7 +274,7 @@
     ptr_aligned_   += n;
   
     // update x0
-    x0_ = (n == 1)? x1_:simd::load((value_type*)ptr_aligned_);
+    x0_ = (n == 1) ? x1_ : simd::load((value_type*)ptr_aligned_);
 
     // update x1
     x1_ = simd::load((value_type*)(ptr_aligned_+simd::vec_size));
@@ -302,6 +302,8 @@
   void increment(length_type n = 1)
   { ptr_unaligned_ += n * Simd_traits<value_type>::vec_size; }
 
+  void increment_by_element(length_type) { assert(0); }
+
   value_type const*            ptr_unaligned_;
 };
 
@@ -310,25 +312,23 @@
 // Optimized proxy for direct SIMD access to block data, i.e. the data
 // is contiguous (unit stride) and correctly aligned.
 template <typename T>
-class Proxy<Direct_access_traits<T>,true >
+class Proxy<Direct_access_traits<T>, true>
 {
 public:
   typedef T value_type;
   typedef typename Simd_traits<value_type>::simd_type simd_type;
 
   Proxy(value_type const *ptr) : ptr_(ptr)
-  {
-    // Force alignment of pointer.
-    intptr_t int_ptr = (intptr_t)ptr_;
-    int_ptr &= ~(Simd_traits<value_type>::alignment-1);
-    ptr_ = (value_type*) int_ptr;
-  }
+  {}
 
   simd_type load() const { return Simd_traits<value_type>::load(ptr_);}
 
   void increment(length_type n = 1)
   { ptr_ += n * Simd_traits<value_type>::vec_size;}
 
+  void increment_by_element(length_type n)
+  { ptr_ += n; }
+
 private:
   value_type const *ptr_;
 };
@@ -349,6 +349,9 @@
   void increment(length_type n = 1) 
   { simd_loader_.increment(n); }
 
+  void increment_by_element(length_type n)
+  { simd_loader_.increment_by_element(n); }
+
 private:
   Simd_unaligned_loader<T>      simd_loader_;
 };
@@ -364,12 +367,7 @@
   typedef typename Simd_traits<value_type>::simd_type simd_type;
 
   Proxy(value_type *ptr) : ptr_(ptr)
-  {
-    // Force alignment of pointer.
-    intptr_t int_ptr = (intptr_t)ptr_;
-    int_ptr &= ~(Simd_traits<value_type>::alignment-1);
-    ptr_ = (value_type*) int_ptr;
-  }
+  {}
 
   template <typename T1>
   Proxy operator = (Proxy<T1,true> const &o) 
@@ -384,8 +382,12 @@
   store(simd_type const &value) 
   { Simd_traits<value_type>::store(ptr_, value);}
 
-  void increment(length_type n = 1) { ptr_ += n * Simd_traits<value_type>::vec_size;}
+  void increment(length_type n = 1)
+  { ptr_ += n * Simd_traits<value_type>::vec_size;}
 
+  void increment_by_element(length_type n)
+  { ptr_ += n; }
+
 private:
   value_type *ptr_;
 };
@@ -403,6 +405,7 @@
   { return Simd_traits<value_type>::load_scalar_all(value_);}
 
   void increment(length_type) {}
+  void increment_by_element(length_type) {}
 
 private:
   value_type value_;
@@ -426,6 +429,7 @@
   }
 
   void increment(length_type n = 1) { op_.increment(n);}
+  void increment_by_element(length_type n) { op_.increment_by_element(n); }
 
 private:
   ProxyT op_;
@@ -462,6 +466,12 @@
     right_.increment(n);
   }
 
+  void increment_by_element(length_type n)
+  {
+    left_.increment_by_element(n);
+    right_.increment_by_element(n);
+  }
+
 private:
   L left_;
   R right_;
@@ -499,6 +509,12 @@
     right_.increment(n);
   }
 
+  void increment_by_element(length_type n)
+  {
+    left_.increment_by_element(n);
+    right_.increment_by_element(n);
+  }
+
 private:
   AB left_;
   C right_;
@@ -536,6 +552,12 @@
     right_.increment(n);
   }
 
+  void increment_by_element(length_type n)
+  {
+    left_.increment_by_element(n);
+    right_.increment_by_element(n);
+  }
+
 private:
   A left_;
   BC right_;
@@ -577,6 +599,12 @@
     right_.increment(n);
   }
 
+  void increment_by_element(length_type n)
+  {
+    left_.increment_by_element(n);
+    right_.increment_by_element(n);
+  }
+
 private:
   AB left_;
   CD right_;
@@ -617,6 +645,13 @@
     c_.increment(n);
   }
 
+  void increment_by_element(length_type n)
+  {
+    a_.increment_by_element(n);
+    b_.increment_by_element(n);
+    c_.increment_by_element(n);
+  }
+
 private:
   A a_;
   B b_;
Index: src/vsip/opt/diag/extdata.hpp
===================================================================
--- src/vsip/opt/diag/extdata.hpp	(revision 176624)
+++ src/vsip/opt/diag/extdata.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -10,8 +10,8 @@
     @brief   VSIPL++ Library: Diagnostics for extdata.
 */
 
-#ifndef VSIP_OPT_DIAG_EXTDATAL_HPP
-#define VSIP_OPT_DIAG_EXTDATAL_HPP
+#ifndef VSIP_OPT_DIAG_EXTDATA_HPP
+#define VSIP_OPT_DIAG_EXTDATA_HPP
 
 #if VSIP_IMPL_REF_IMPL
 # error "vsip/opt files cannot be used as part of the reference impl."
@@ -107,7 +107,30 @@
   }
 };
 
+
+
+template <typename BlockT,
+	  dimension_type Dim = Block_layout<BlockT>::dim>
+struct Diagnose_rt_ext_data
+{
+  typedef typename Block_layout<BlockT>::access_type              AT;
+  typedef data_access::Rt_low_level_data_access<AT, BlockT, Dim>   ext_type;
+
+  static void diag(std::string name)
+  {
+    using diag_detail::Class_name;
+    using std::cout;
+    using std::endl;
+
+    cout << "diagnose_rt_ext_data(" << name << ")" << endl
+	 << "  BlockT: " << typeid(BlockT).name() << endl
+	 << "  access_type: " << Class_name<access_type>::name() << endl
+      // << "  static-cost: " << access_type::cost << endl
+      ;
+  }
+};
+
 } // namespace vsip::impl::diag_detail
 } // namespace vsip
 
-#endif // VSIP_OPT_DIAG_EXTDATAL_HPP
+#endif // VSIP_OPT_DIAG_EXTDATA_HPP
Index: tests/regressions/fft_ip_subview.cpp
===================================================================
--- tests/regressions/fft_ip_subview.cpp	(revision 0)
+++ tests/regressions/fft_ip_subview.cpp	(revision 0)
@@ -0,0 +1,134 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/regressions/fft_ip_subview.cpp
+    @author  Jules Bergmann
+    @date    2007-07-29
+    @brief   VSIPL++ Library: Regression test for in-place Fft of a subview.
+
+    When planning for an in-place split complex FFT, FFTW 3.1.2
+    erroneously encodes the gap between the real and imaginary parts.
+
+    When the plan is later applied to another split-complex vector
+    with a different gap between real and complex, FFTW will read/write
+    memory outside of the vector.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/signal.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// 1-dim by-reference in-place Fft, complex vector input from a subview.
+
+template <typename T>
+void
+test_fft_ip_subview()
+{
+  typedef Fft<const_Vector, T, T, fft_fwd, by_reference, 1, alg_space>
+	fft_type;
+
+  length_type rows = 32;
+  length_type size = 64;
+
+  index_type r = rows-1;
+
+  fft_type fft(Domain<1>(size), 1.f);
+
+  Vector<T> vec(size);
+  Matrix<T> mat(rows, size);
+
+  vec        = T(1, -2);
+  mat.row(r) = vec;
+
+  fft(vec);
+  fft(mat.row(r));
+
+  test_assert(equal(vec.get(0), T(size, -2*(int)size)));
+  for (index_type i=1; i<size; ++i)
+    test_assert(equal(vec.get(i), T(0)));
+
+  test_assert(equal(mat.row(r).get(0), T(size, -2*(int)size)));
+  for (index_type i=1; i<size; ++i)
+    test_assert(equal(mat.row(r).get(i), T(0)));
+}
+
+
+
+// By-reference Fftm, in-place
+
+template <typename T>
+void
+test_fftm_ip_subview(
+  bool        scale)
+{
+  typedef Fftm<T, T, row, fft_fwd, by_reference, 1> fftm_type;
+
+  length_type rows = 16;
+  length_type cols = 64;
+
+  Matrix<T> inout(rows, cols,         T(100, -1));
+  Matrix<T> big_inout(2*rows, 2*cols, T(-101));
+
+  Domain<2> dom(Domain<1>(rows/2, 1, rows), Domain<1>(cols/2, 1, cols));
+
+  fftm_type fftm(Domain<2>(rows, cols), scale ? 1.f / cols : 1.f);
+
+  for (index_type r=0; r<rows; ++r)
+  {
+    inout.row(r) = T(r);
+    big_inout(dom).row(r) = T(r);
+  }
+
+  fftm(inout); 
+  fftm(big_inout(dom)); 
+
+  for (index_type r=0; r<rows; ++r)
+  {
+    if (!(inout.get(r, 0) == T(scale ? r : r*cols)))
+    {
+      cout << "test_fftm_br_ip: miscompare for row " << r << endl
+	   << "  expected: " << T(scale ? r : r*cols) << endl
+	   << "  got     : " << inout.get(r, 0) << endl
+	   << "  scale   : " << (scale ? "true" : "false") << endl;
+    }
+    test_assert(inout.get(r, 0) == T(scale ? r : r*cols));
+    test_assert(big_inout(dom).get(r, 0) == T(scale ? r : r*cols));
+  }
+}
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_fft_ip_subview<complex<float> >();
+  test_fftm_ip_subview<complex<float> >(true);
+
+  return 0;
+}
Index: tests/regressions/simd_alignment.cpp
===================================================================
--- tests/regressions/simd_alignment.cpp	(revision 0)
+++ tests/regressions/simd_alignment.cpp	(revision 0)
@@ -0,0 +1,111 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/regressions/simd_alignment.cpp
+    @author  Jules Bergmann
+    @date    2007-07-27
+    @brief   VSIPL++ Library: Regression tests for unaligned and misaligned
+             operations.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#define VERBOSE 0
+
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/selgen.hpp>
+#include <vsip/parallel.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
+
+#include "test_common.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+using vsip_csl::equal;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T>
+void
+do_negate(length_type size, length_type align, length_type cleanup)
+{
+  Vector<T> src(size);
+  Vector<T> dst(size);
+
+  Domain<1> dom(align, 1, size-align-cleanup);
+
+  src = ramp(T(0), T(1), size);
+
+  dst(dom) = -src(dom);
+
+  for (index_type i=0; i<dom.size(); ++i)
+  {
+#if VERBOSE
+    if (!(dst(dom)(i) == -src(dom)(i)))
+    {
+      cout << "src:\n" << src << endl;
+      cout << "dst:\n" << dst << endl;
+    }
+#endif
+    test_assert(dst(dom)(i) == -src(dom)(i));
+  }
+}
+
+
+
+template <typename T>
+void
+test()
+{
+  do_negate<T>(16, 0, 0);
+
+  do_negate<T>(16, 1, 0);
+  do_negate<T>(16, 2, 0);
+  do_negate<T>(16, 3, 0);
+
+  do_negate<T>(16, 1, 1);
+  do_negate<T>(16, 2, 1);
+  do_negate<T>(16, 3, 1);
+
+  do_negate<T>(16, 1, 2);
+  do_negate<T>(16, 2, 2);
+  do_negate<T>(16, 3, 2);
+
+  do_negate<T>(16, 1, 3);
+  do_negate<T>(16, 2, 3);
+  do_negate<T>(16, 3, 3);
+}
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test<float>();
+
+  return 0;
+}
Index: tests/regressions/subview_exprs.cpp
===================================================================
--- tests/regressions/subview_exprs.cpp	(revision 173072)
+++ tests/regressions/subview_exprs.cpp	(working copy)
@@ -14,6 +14,8 @@
   Included Files
 ***********************************************************************/
 
+#define VERBOSE 0
+
 #include <iostream>
 #include <cassert>
 
@@ -65,7 +67,17 @@
 
   for (index_type i=0; i<m; ++i)
     for (index_type j=0; j<n; ++j)
+    {
+#if VERBOSE
+      if (!(equal(dst(i, j), T(1))))
+      {
+	std::cout << "test_a2: miscompare at (" << i << ", " << j << "):\n"
+		  << "  expected: " << T(1) << "\n"
+		  << "  got     : " << dst(i, j) << "\n";
+      }
+#endif
       test_assert(equal(dst(i, j), T(1)));
+    }
 }
 
 
Index: tests/fftm.cpp
===================================================================
--- tests/fftm.cpp	(revision 173072)
+++ tests/fftm.cpp	(working copy)
@@ -1,10 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    tests/fft.cpp
+/** @file    tests/fftm.cpp
     @author  Nathan Myers
     @date    2005-08-12
     @brief   VSIPL++ Library: Testcases for Fftm.
Index: tests/fft.cpp
===================================================================
--- tests/fft.cpp	(revision 177533)
+++ tests/fft.cpp	(working copy)
@@ -53,6 +53,31 @@
 
 
 
+template <typename View1,
+	  typename View2>
+inline void
+check_error(
+  char const* where,
+  View1       v1,
+  View2       v2,
+  double      epsilon)
+{
+  double error = error_db(v1, v2);
+#if VERBOSE
+  if (error >= epsilon)
+  {
+    std::cout << "check_error " << where << ": error >= epsilon" << std::endl;
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
 // Setup input data for Fft.
 
 template <typename T,
@@ -126,7 +151,7 @@
   i_fft(out, inv);
 
   test_assert(error_db(ref, out) < -100);
-  test_assert(error_db(inv, in) < -100);
+  check_error("test_complex_by_ref", inv, in, -100);
 
   out = in;  f_fft(out);
   inv = out; i_fft(inv);
@@ -227,7 +252,7 @@
 
   ref = out;
   inv = i_fft(out);
-  test_assert(error_db(inv, in) < -100);
+  check_error("test_real", inv, in, -100);
 
   // make sure out has not been scribbled in during the conversion.
   test_assert(error_db(ref,out) < -100);
