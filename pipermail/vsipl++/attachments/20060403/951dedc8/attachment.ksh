Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.426
diff -u -r1.426 ChangeLog
--- ChangeLog	3 Apr 2006 19:24:28 -0000	1.426
+++ ChangeLog	3 Apr 2006 20:30:22 -0000
@@ -1,3 +1,13 @@
+2006-04-03  Jules Bergmann  <jules@codesourcery.com>
+
+	* GNUmakefile.in (hdr): Add SIMD headers in src/vsip/impl/simd.
+	* scripts/package (--version): New option that sets a specific
+	  version (--snapshot is equiv to --version=YYYYMMDD).
+	* src/vsip/impl/expr_serial_evaluator.hpp: Optimize simple matrix
+	  copy to use memcpy or explicit loop when possible.
+	* src/vsip/impl/fast-transpose.hpp: New transpose_unit implementation
+	  that uses SIMD transpose kernels when possible.
+
 2006-04-03  Don McCoy  <don@codesourcery.com>
 
 	* benchmarks/fastconv.cpp: Updated to use benchmarks.hpp.  Separated
Index: GNUmakefile.in
===================================================================
RCS file: /home/cvs/Repository/vpp/GNUmakefile.in,v
retrieving revision 1.45
diff -u -r1.45 GNUmakefile.in
--- GNUmakefile.in	24 Jan 2006 17:33:15 -0000	1.45
+++ GNUmakefile.in	3 Apr 2006 20:30:22 -0000
@@ -181,6 +181,8 @@
              $(wildcard $(srcdir)/src/vsip/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/impl/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/impl/simd/*.hpp))
 
 ########################################################################
 # Included Files
Index: src/vsip/impl/expr_serial_evaluator.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_serial_evaluator.hpp,v
retrieving revision 1.5
diff -u -r1.5 expr_serial_evaluator.hpp
--- src/vsip/impl/expr_serial_evaluator.hpp	3 Mar 2006 14:30:53 -0000	1.5
+++ src/vsip/impl/expr_serial_evaluator.hpp	3 Apr 2006 20:30:22 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/impl/expr_evaluator.hpp
     @author  Stefan Seefeld
@@ -68,6 +68,9 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<2, DstBlock, SrcBlock, Transpose_tag>
 {
+  typedef typename DstBlock::value_type dst_value_type;
+  typedef typename SrcBlock::value_type src_value_type;
+
   static bool const is_rhs_expr   = Is_expr_block<SrcBlock>::value;
 
   static bool const is_rhs_simple =
@@ -90,12 +93,115 @@
   static bool const ct_valid =
     !is_rhs_expr &&
     lhs_cost == 0 && rhs_cost == 0 &&
-    !is_lhs_split && !is_rhs_split &&
-    !Type_equal<src_order_type, dst_order_type>::value;
+    !is_lhs_split && !is_rhs_split;
 
   static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
   { return true; }
 
+  static void exec(DstBlock& dst, SrcBlock const& src, row2_type, row2_type)
+  {
+    vsip::impl::Ext_data<DstBlock> d_ext(dst, vsip::impl::SYNC_OUT);
+    vsip::impl::Ext_data<SrcBlock> s_ext(src, vsip::impl::SYNC_IN);
+
+    dst_value_type* d_ptr = d_ext.data();
+    src_value_type* s_ptr = s_ext.data();
+
+    stride_type d_stride_0 = d_ext.stride(0);
+    stride_type d_stride_1 = d_ext.stride(1);
+    stride_type s_stride_0 = s_ext.stride(0);
+    stride_type s_stride_1 = s_ext.stride(1);
+
+    length_type size_0     = d_ext.size(0);
+    length_type size_1     = d_ext.size(1);
+
+    assert(size_0 <= s_ext.size(0));
+    assert(size_1 <= s_ext.size(1));
+
+    if (Type_equal<dst_value_type, src_value_type>::value
+	&& d_stride_1 == 1 && s_stride_1 == 1)
+    {
+      if (d_stride_0 == size_1 && s_stride_0 == size_1)
+	memcpy(d_ptr, s_ptr, size_0*size_1*sizeof(dst_value_type));
+      else
+	for (index_type i=0; i<size_0; ++i)
+	{
+	  memcpy(d_ptr, s_ptr, size_1*sizeof(dst_value_type));
+	  d_ptr += d_stride_0;
+	  s_ptr += s_stride_0;
+	}
+    }
+    else
+    {
+      for (index_type i=0; i<size_0; ++i)
+      {
+	dst_value_type* d_row = d_ptr;
+	src_value_type* s_row = s_ptr;
+	
+	for (index_type j=0; j<size_1; ++j)
+        {
+	  *d_row = *s_row;
+	  d_row += d_stride_1;
+	  s_row += s_stride_1;
+        }
+
+	d_ptr += d_stride_0;
+	s_ptr += s_stride_0;
+      }
+    }
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src, col2_type, col2_type)
+  {
+    vsip::impl::Ext_data<DstBlock> d_ext(dst, vsip::impl::SYNC_OUT);
+    vsip::impl::Ext_data<SrcBlock> s_ext(src, vsip::impl::SYNC_IN);
+
+    dst_value_type* d_ptr = d_ext.data();
+    src_value_type* s_ptr = s_ext.data();
+
+    stride_type d_stride_0 = d_ext.stride(0);
+    stride_type d_stride_1 = d_ext.stride(1);
+    stride_type s_stride_0 = s_ext.stride(0);
+    stride_type s_stride_1 = s_ext.stride(1);
+
+    length_type size_0     = d_ext.size(0);
+    length_type size_1     = d_ext.size(1);
+
+    assert(size_0 <= s_ext.size(0));
+    assert(size_1 <= s_ext.size(1));
+
+    if (Type_equal<dst_value_type, src_value_type>::value
+	&& d_stride_0 == 1 && s_stride_0 == 1)
+    {
+      if (d_stride_1 == size_0 && s_stride_1 == size_0)
+	memcpy(d_ptr, s_ptr, size_0*size_1*sizeof(dst_value_type));
+      else
+	for (index_type j=0; j<size_1; ++j)
+	{
+	  memcpy(d_ptr, s_ptr, size_0*sizeof(dst_value_type));
+	  d_ptr += d_stride_1;
+	  s_ptr += s_stride_1;
+	}
+    }
+    else
+    {
+      for (index_type j=0; j<size_1; ++j)
+      {
+	dst_value_type* d_row = d_ptr;
+	src_value_type* s_row = s_ptr;
+	
+	for (index_type i=0; i<size_0; ++i)
+        {
+	  *d_row = *s_row;
+	  d_row += d_stride_0;
+	  s_row += s_stride_0;
+        }
+
+	d_ptr += d_stride_1;
+	s_ptr += s_stride_1;
+      }
+    }
+  }
+
   static void exec(DstBlock& dst, SrcBlock const& src, col2_type, row2_type)
   {
     vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
Index: src/vsip/impl/fast-transpose.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fast-transpose.hpp,v
retrieving revision 1.1
diff -u -r1.1 fast-transpose.hpp
--- src/vsip/impl/fast-transpose.hpp	22 Dec 2005 01:29:25 -0000	1.1
+++ src/vsip/impl/fast-transpose.hpp	3 Apr 2006 20:30:22 -0000
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
 
 /** @file    vsip/impl/fast-transpose.hpp
     @author  Jules Bergmann
@@ -11,6 +11,20 @@
 #define VSIP_IMPL_FAST_TRANSPOSE_HPP
 
 /***********************************************************************
+  Includes & Macros
+***********************************************************************/
+
+#if   __SSE2__ && __amd64__
+#  define VSIP_IMPL_TRANSPOSE_USE_3DNOW 1
+#  include <mmintrin.h>
+#elif __SSE2__
+#  define VSIP_IMPL_TRANSPOSE_USE_SSE   1
+#  include <xmmintrin.h>
+#endif
+
+
+
+/***********************************************************************
   Definitions
 ***********************************************************************/
 
@@ -20,7 +34,489 @@
 namespace impl
 {
 
-// Transpose for unit-strides.
+namespace trans_detail
+{
+
+inline void
+transpose_simd_start()
+{
+#if VSIP_IMPL_TRANSPOSE_USE_3DNOW
+  __asm__ __volatile__ ("femms");
+#endif
+}
+
+inline void
+transpose_simd_stop()
+{
+#if VSIP_IMPL_TRANSPOSE_USE_3DNOW
+  __asm__ __volatile__ ("femms");
+#endif
+}
+
+
+
+/***********************************************************************
+  General Unrolled_transpose definitions
+***********************************************************************/
+
+template <typename T1,
+	  typename T2,
+	  unsigned Block,
+	  bool     SimdAligned>
+struct Unrolled_transpose
+{
+  static void exec(T1* dst, T2 const* src,
+	    unsigned const dst_col_stride,
+	    unsigned const src_row_stride)
+  {
+    typedef Unrolled_transpose<T1, T2, Block/2, SimdAligned> meta;
+
+    meta::exec(dst, src,
+	       dst_col_stride,
+	       src_row_stride);
+    meta::exec(dst + (Block/2)*dst_col_stride, src + (Block/2),
+	       dst_col_stride,
+	       src_row_stride);
+    meta::exec(dst + (Block/2), src + (Block/2)*src_row_stride,
+	       dst_col_stride,
+	       src_row_stride);
+    meta::exec(dst + (Block/2) + (Block/2)*dst_col_stride,
+	       src + (Block/2)*src_row_stride + (Block/2),
+	       dst_col_stride,
+	       src_row_stride);
+  }
+};
+
+
+
+template <typename T1,
+	  typename T2,
+	  bool     SimdAligned>
+struct Unrolled_transpose<T1, T2, 1, SimdAligned>
+{
+  static void exec(T1* dst, T2 const* src,
+	    unsigned const dst_col_stride,
+	    unsigned const src_row_stride)
+  {
+    *dst = *src;
+  }
+};
+
+
+
+/***********************************************************************
+  SSE specific Unrolled_transpose definitions
+***********************************************************************/
+
+#if VSIP_IMPL_TRANSPOSE_USE_SSE
+// 4x4 float unaligned fragment for SSE.
+
+template <>
+struct Unrolled_transpose<float, float, 4, false>
+{
+  static void exec(
+    float*         dst,
+    float const*   src,
+    unsigned const dst_col_stride,
+    unsigned const src_row_stride)
+  {
+    __v4sf row0 = _mm_loadu_ps(src + 0*src_row_stride + 0);
+    __v4sf row1 = _mm_loadu_ps(src + 1*src_row_stride + 0);
+    __v4sf row2 = _mm_loadu_ps(src + 2*src_row_stride + 0);
+    __v4sf row3 = _mm_loadu_ps(src + 3*src_row_stride + 0);
+    _MM_TRANSPOSE4_PS(row0, row1, row2, row3);
+    _mm_storeu_ps(dst + 0 + 0*dst_col_stride, row0);
+    _mm_storeu_ps(dst + 0 + 1*dst_col_stride, row1);
+    _mm_storeu_ps(dst + 0 + 2*dst_col_stride, row2);
+    _mm_storeu_ps(dst + 0 + 3*dst_col_stride, row3);
+  }
+};
+
+
+
+// 4x4 float aligned fragment for SSE.
+
+template <>
+struct Unrolled_transpose<float, float, 4, true>
+{
+  static void exec(
+    float*         dst,
+    float const*   src,
+    unsigned const dst_col_stride,
+    unsigned const src_row_stride)
+  {
+    __v4sf row0 = _mm_load_ps(src + 0*src_row_stride + 0);
+    __v4sf row1 = _mm_load_ps(src + 1*src_row_stride + 0);
+    __v4sf row2 = _mm_load_ps(src + 2*src_row_stride + 0);
+    __v4sf row3 = _mm_load_ps(src + 3*src_row_stride + 0);
+    _MM_TRANSPOSE4_PS(row0, row1, row2, row3);
+    _mm_store_ps(dst + 0 + 0*dst_col_stride, row0);
+    _mm_store_ps(dst + 0 + 1*dst_col_stride, row1);
+    _mm_store_ps(dst + 0 + 2*dst_col_stride, row2);
+    _mm_store_ps(dst + 0 + 3*dst_col_stride, row3);
+  }
+};
+
+
+
+// 2x2 complex<float> unaligned fragment for SSE.
+
+template <>
+struct Unrolled_transpose<complex<float>, complex<float>, 2, false>
+{
+  static void exec(
+    complex<float>*       dst,
+    complex<float>const * src,
+    unsigned const        dst_col_stride,
+    unsigned const        src_row_stride)
+  {
+    __v4sf row0 = _mm_loadu_ps(
+		reinterpret_cast<float const*>(src + 0*src_row_stride + 0));
+    __v4sf row1 = _mm_loadu_ps(
+		reinterpret_cast<float const*>(src + 1*src_row_stride + 0));
+
+    __v4sf col0 = __builtin_ia32_shufps(row0, row1, 0x44); // 10 00 01 00
+    __v4sf col1 = __builtin_ia32_shufps(row0, row1, 0xEE); // 11 10 11 10
+
+    _mm_storeu_ps(reinterpret_cast<float*>(dst + 0 + 0*dst_col_stride), col0);
+    _mm_storeu_ps(reinterpret_cast<float*>(dst + 0 + 1*dst_col_stride), col1);
+  }
+};
+
+
+
+// 2x2 complex<float> aligned fragment for SSE.
+
+template <>
+struct Unrolled_transpose<complex<float>, complex<float>, 2, true>
+{
+  static void exec(
+    complex<float>*       dst,
+    complex<float>const * src,
+    unsigned const        dst_col_stride,
+    unsigned const        src_row_stride)
+  {
+    __v4sf row0 = _mm_load_ps(
+		reinterpret_cast<float const*>(src + 0*src_row_stride + 0));
+    __v4sf row1 = _mm_load_ps(
+		reinterpret_cast<float const*>(src + 1*src_row_stride + 0));
+
+    __v4sf col0 = __builtin_ia32_shufps(row0, row1, 0x44); // 10 00 01 00
+    __v4sf col1 = __builtin_ia32_shufps(row0, row1, 0xEE); // 11 10 11 10
+
+    _mm_store_ps(reinterpret_cast<float*>(dst + 0 + 0*dst_col_stride), col0);
+    _mm_store_ps(reinterpret_cast<float*>(dst + 0 + 1*dst_col_stride), col1);
+  }
+};
+#endif
+
+
+
+/***********************************************************************
+  3DNow! specific Unrolled_transpose definitions
+***********************************************************************/
+
+#if VSIP_IMPL_TRANSPOSE_USE_3DNOW
+
+typedef float __v2sf __attribute__ ((__mode__ (__V2SF__),__aligned__(8)));
+
+template <bool     SimdAligned>
+struct Unrolled_transpose<float, float, 2, SimdAligned>
+{
+  static void exec(
+    float*         dst,
+    float const*   src,
+    unsigned const dst_col_stride,
+    unsigned const src_row_stride)
+  {
+    __v2sf row0 = *(__v2sf*)(src  + 0*src_row_stride + 0);
+    __v2sf row1 = *(__v2sf*)(src  + 1*src_row_stride + 0);
+
+    __v2sf col0 = (__v2sf)_m_punpckldq((__m64)row0, (__m64)row1);
+    __v2sf col1 = (__v2sf)_m_punpckhdq((__m64)row0, (__m64)row1);
+
+    *(__v2sf*)(dst + 0 + 0*dst_col_stride) = col0;
+    *(__v2sf*)(dst + 0 + 1*dst_col_stride) = col1;
+  }
+};
+
+template <bool     SimdAligned>
+struct Unrolled_transpose<complex<float>, complex<float>, 1, SimdAligned>
+{
+  static void exec(
+    complex<float>*         dst,
+    complex<float> const*   src,
+    unsigned const dst_col_stride,
+    unsigned const src_row_stride)
+  {
+    __v2sf row0 = *(__v2sf*)(src);
+
+    *(__v2sf*)(dst) = row0;
+  }
+};
+#endif
+
+
+
+/***********************************************************************
+  Definitions - transpose_unit
+***********************************************************************/
+
+// transpose_unit implementation tags.
+
+struct Impl_loop {};
+template <unsigned Block, bool SimdAligned> struct Impl_block_iter {};
+template <unsigned Block, bool SimdAligned> struct Impl_block_recur {};
+template <unsigned Block, bool SimdAligned> struct Impl_block_recur_helper {};
+struct Impl_recur {};
+
+template <typename T1,
+	  typename T2>
+void
+transpose_unit(
+  T1*            dst,
+  T2 const*      src,
+  unsigned const rows,		// dst rows
+  unsigned const cols,		// dst cols
+  unsigned const dst_col_stride,
+  unsigned const src_row_stride,
+  Impl_loop)
+{
+  for (unsigned r=0; r<rows; ++r)
+    for (unsigned c=0; c<cols; ++c)
+      dst[r+c*dst_col_stride] = src[r*src_row_stride+c];
+}
+
+
+
+#if VSIP_IMPL_TRANSPOSE_USE_3DNOW
+template <>
+inline void
+transpose_unit(
+  complex<float>*       dst,
+  complex<float> const* src,
+  unsigned const        rows,		// dst rows
+  unsigned const        cols,		// dst cols
+  unsigned const        dst_col_stride,
+  unsigned const        src_row_stride,
+  Impl_loop)
+{
+  __asm__ __volatile__ ("femms");
+  for (unsigned r=0; r<rows; ++r)
+    for (unsigned c=0; c<cols; ++c)
+    {
+      __v2sf row0 = *(__v2sf*)(src + r*src_row_stride+c);
+      *(__v2sf*)(dst + r+c*dst_col_stride) = row0;
+    }
+  __asm__ __volatile__ ("femms");
+}
+#endif
+
+
+
+/// Blocked transpose, using iteration over blocks.
+
+template <typename T1,
+	  typename T2,
+	  unsigned Block,
+	  bool     SimdAligned>
+void
+transpose_unit(
+  T1*            dst,
+  T2 const*      src,
+  unsigned const rows,		// dst rows
+  unsigned const cols,		// dst cols
+  unsigned const dst_col_stride,
+  unsigned const src_row_stride,
+  Impl_block_iter<Block, SimdAligned>)
+{
+  unsigned full_cols = cols - cols%Block;
+  unsigned full_rows = rows - rows%Block;
+
+  // Transpose core of matrix using Unrolled_transpose a block
+  // at a time.
+
+  for (unsigned r=0; r<full_rows; r += Block)
+    for (unsigned c=0; c<full_cols; c += Block)
+    {
+      transpose_simd_start();
+      Unrolled_transpose<T1, T2, Block, SimdAligned>::exec(
+			dst + r + c*dst_col_stride,
+			src + r*src_row_stride + c,
+			dst_col_stride,
+			src_row_stride);
+      transpose_simd_stop();
+    }
+
+
+  // Cleanup edges of matrix using Impl_loop.
+
+  if (full_cols != cols)
+  {
+    unsigned extra_cols = cols - full_cols;
+    for (unsigned r=0; r<full_rows; r += Block)
+      transpose_unit(dst + r + full_cols*dst_col_stride,
+		     src + r*src_row_stride + full_cols,
+		     Block, extra_cols,
+		     dst_col_stride,
+		     src_row_stride,
+		     Impl_loop());
+  }
+  if (full_rows != rows)
+  {
+    unsigned extra_rows = rows - full_rows;
+    for (unsigned c=0; c<full_cols; c += Block)
+      transpose_unit(dst + full_rows + c*dst_col_stride,
+		     src + full_rows*src_row_stride + c,
+		     extra_rows, Block,
+		     dst_col_stride,
+		     src_row_stride,
+		     Impl_loop());
+    if (full_cols != cols)
+    {
+      transpose_unit(dst + full_rows + full_cols*dst_col_stride,
+		     src + full_rows*src_row_stride + full_cols,
+		     extra_rows, cols - full_cols,
+		     dst_col_stride,
+		     src_row_stride,
+		     Impl_loop());
+    }
+  }
+}
+
+
+
+/// Recurcive blocked transpose helper function.
+
+/// This routine performs the recursive sub-division for Impl_block_recur.
+
+template <typename T1,
+	  typename T2,
+	  unsigned Block,
+	  bool     SimdAligned>
+void
+transpose_unit(
+  T1*            dst,
+  T2 const*      src,
+  unsigned const rows,		// dst rows
+  unsigned const cols,		// dst cols
+  unsigned const dst_col_stride,
+  unsigned const src_row_stride,
+  Impl_block_recur_helper<Block, SimdAligned>)
+{
+  unsigned const thresh = 4*Block;
+  if (rows <= thresh && cols <= thresh)
+  {
+    for (unsigned r=0; r<rows; r+=Block)
+      for (unsigned c=0; c<cols; c+=Block)
+	Unrolled_transpose<T1, T2, Block, SimdAligned>::exec(
+			dst + r + c*dst_col_stride,
+			src + r*src_row_stride + c,
+			dst_col_stride,
+			src_row_stride);
+  }
+  else if (cols >= rows)
+  {
+    unsigned cols1 = ((cols/Block)/2) * Block;
+    unsigned cols2 = cols - cols1;
+
+    transpose_unit(dst,          src,
+		   rows, cols1,
+		   dst_col_stride, src_row_stride,
+		   Impl_block_recur_helper<Block, SimdAligned>());
+
+    transpose_unit(dst + (cols1)*dst_col_stride, src + (cols1),
+		   rows, cols2,
+		   dst_col_stride, src_row_stride,
+		   Impl_block_recur_helper<Block, SimdAligned>());
+  }
+  else
+  {
+    unsigned rows1 = ((rows/Block)/2) * Block;
+    unsigned rows2 = rows - rows1;
+
+    transpose_unit(dst,          src,
+		   rows1, cols,
+		   dst_col_stride, src_row_stride,
+		   Impl_block_recur_helper<Block, SimdAligned>());
+
+    transpose_unit(dst + (rows1), src + (rows1)*src_row_stride,
+		   rows2, cols,
+		   dst_col_stride, src_row_stride,
+		   Impl_block_recur_helper<Block, SimdAligned>());
+  }
+}
+
+
+
+/// Blocked transpose, using recursion over blocks.
+
+template <typename T1,
+	  typename T2,
+	  unsigned Block,
+	  bool     SimdAligned>
+void
+transpose_unit(
+  T1*            dst,
+  T2 const*      src,
+  unsigned const rows,		// dst rows
+  unsigned const cols,		// dst cols
+  unsigned const dst_col_stride,
+  unsigned const src_row_stride,
+  Impl_block_recur<Block, SimdAligned>)
+{
+  unsigned full_cols = cols - cols%Block;
+  unsigned full_rows = rows - rows%Block;
+
+  // Transpose core of matrix using Unrolled_transpose a block
+  // at a time.
+
+  transpose_simd_start();
+  transpose_unit(dst, src, full_rows, full_cols,
+		 dst_col_stride,
+		 src_row_stride,
+		 Impl_block_recur_helper<Block, SimdAligned>());
+  transpose_simd_stop();
+
+
+  // Cleanup edges of matrix using Impl_loop.
+
+  if (full_cols != cols)
+  {
+    unsigned extra_cols = cols - full_cols;
+    for (unsigned r=0; r<full_rows; r += Block)
+      transpose_unit(dst + r + full_cols*dst_col_stride,
+		     src + r*src_row_stride + full_cols,
+		     Block, extra_cols,
+		     dst_col_stride,
+		     src_row_stride,
+		     Impl_loop());
+  }
+  if (full_rows != rows)
+  {
+    unsigned extra_rows = rows - full_rows;
+    for (unsigned c=0; c<full_cols; c += Block)
+      transpose_unit(dst + full_rows + c*dst_col_stride,
+		     src + full_rows*src_row_stride + c,
+		     extra_rows, Block,
+		     dst_col_stride,
+		     src_row_stride,
+		     Impl_loop());
+    if (full_cols != cols)
+    {
+      transpose_unit(dst + full_rows + full_cols*dst_col_stride,
+		     src + full_rows*src_row_stride + full_cols,
+		     extra_rows, cols - full_cols,
+		     dst_col_stride,
+		     src_row_stride,
+		     Impl_loop());
+    }
+  }
+}
+
+
+
+// Recurively decomposed transposition for unit-strides.
 
 // Algorithm based on "Cache-Oblivious Algorithms (Extended Abstract)"
 // by M. Frigo, C. Leiseron, H. Prokop, S. Ramachandran.
@@ -30,11 +526,13 @@
 	  typename T2>
 void
 transpose_unit(
-  T1* dst, T2* src,
+  T1*            dst,
+  T2 const*      src,
   unsigned const rows,		// dst rows
   unsigned const cols,		// dst cols
   unsigned const dst_col_stride,
-  unsigned const src_row_stride)
+  unsigned const src_row_stride,
+  Impl_recur)
 {
   unsigned const thresh = 16;
   if (rows <= thresh && cols <= thresh)
@@ -65,6 +563,59 @@
   }
 }
 
+} // namespace vsip::impl::trans_detail
+
+
+// Unit-stride transpose dispatch function.
+
+template <typename T1,
+	  typename T2>
+inline void
+transpose_unit(
+  T1*            dst,
+  T2 const*      src,
+  unsigned const rows,		// dst rows
+  unsigned const cols,		// dst cols
+  unsigned const dst_col_stride,
+  unsigned const src_row_stride)
+{
+  // Check if data is aligned for SSE ISA.
+  //  - pointers need to be 16-byte aligned
+  //  - rows/cols need to start with 16-byte alignment.
+  bool aligned = 
+    (((unsigned long)dst                      ) & 0xf) == 0 &&
+    (((unsigned long)src                      ) & 0xf) == 0 &&
+    (((unsigned long)dst_col_stride*sizeof(T1)) & 0xf) == 0 &&
+    (((unsigned long)src_row_stride*sizeof(T1)) & 0xf) == 0;
+
+  if (rows < 16 || cols < 16)
+  {
+    if (aligned)
+      trans_detail::transpose_unit(dst, src, rows, cols,
+				   dst_col_stride, src_row_stride,
+				   trans_detail::Impl_block_recur<4, true>()
+				   );
+    else
+      trans_detail::transpose_unit(dst, src, rows, cols,
+				   dst_col_stride, src_row_stride,
+				   trans_detail::Impl_block_recur<4, false>()
+				   );
+  }
+  else
+  {
+    if (aligned)
+      trans_detail::transpose_unit(dst, src, rows, cols,
+				   dst_col_stride, src_row_stride,
+				   trans_detail::Impl_block_recur<16, true>()
+				   );
+    else
+      trans_detail::transpose_unit(dst, src, rows, cols,
+				   dst_col_stride, src_row_stride,
+				   trans_detail::Impl_block_recur<16, false>()
+				   );
+  }
+}
+
 
 
 // Transpose for matrices with arbitrary strides.
@@ -77,7 +628,8 @@
 	  typename T2>
 void
 transpose(
-  T1* dst, T2* src,
+  T1*            dst,
+  T2 const*      src,
   unsigned const rows,		// dst rows
   unsigned const cols,		// dst cols
   unsigned const dst_stride0,
