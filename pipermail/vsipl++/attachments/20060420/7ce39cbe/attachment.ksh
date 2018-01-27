Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.435
diff -u -r1.435 ChangeLog
--- ChangeLog	14 Apr 2006 21:41:41 -0000	1.435
+++ ChangeLog	21 Apr 2006 01:06:48 -0000
@@ -1,4 +1,20 @@
+2006-04-20  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/fast-transpose.hpp: Use VSIPL++ types length_type
+	  and stride_type instead of unsigned.  Fixes bug with negative
+	  strides when size(unsigned) != sizeof(stride_type).
+	  Fix broken non-unit-stride transpose.
+	* tests/regressions/transpose-mirror.cpp: New file, regression
+	  test for transposes with negative stride.
+	* tests/regressions/transpose-nonunit.cpp: New file, regression
+	  test for transposes with non-unit stride.
+	
+	* src/vsip/impl/solver-cholesky.hpp: Use VSIP_IMPL_HAVE_SAL to
+	  determine we should use SAL solvers.
+	* src/vsip/impl/solver-lu.hpp: Likewise.
+
 2006-04-13  Assem Salama <assem@codesourcery.com>
+
 	* src/vsip/impl/solver-lu.hpp: Removed Lud_impl from this file and put
 	  it in sal/solver_lu.hpp and lapack/solver_lu.hpp. This class has a
 	  new tag for implementation. The implementation is chosen using
Index: src/vsip/impl/fast-transpose.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fast-transpose.hpp,v
retrieving revision 1.3
diff -u -r1.3 fast-transpose.hpp
--- src/vsip/impl/fast-transpose.hpp	12 Apr 2006 13:46:42 -0000	1.3
+++ src/vsip/impl/fast-transpose.hpp	21 Apr 2006 01:06:48 -0000
@@ -22,6 +22,8 @@
 #  include <xmmintrin.h>
 #endif
 
+#include <vsip/support.hpp>
+
 
 
 /***********************************************************************
@@ -59,15 +61,17 @@
   General Unrolled_transpose definitions
 ***********************************************************************/
 
-template <typename T1,
-	  typename T2,
-	  unsigned Block,
-	  bool     SimdAligned>
+template <typename    T1,
+	  typename    T2,
+	  length_type Block,
+	  bool        SimdAligned>
 struct Unrolled_transpose
 {
-  static void exec(T1* dst, T2 const* src,
-	    unsigned const dst_col_stride,
-	    unsigned const src_row_stride)
+  static void exec(
+    T1*               dst,
+    T2 const*         src,
+    stride_type const dst_col_stride,
+    stride_type const src_row_stride)
   {
     typedef Unrolled_transpose<T1, T2, Block/2, SimdAligned> meta;
 
@@ -95,10 +99,10 @@
 struct Unrolled_transpose<T1, T2, 1, SimdAligned>
 {
   static void exec(
-    T1*            dst, 
-    T2 const*      src,
-    unsigned const /*dst_col_stride*/,
-    unsigned const /*src_row_stride*/)
+    T1*               dst,
+    T2 const*         src,
+    stride_type const /*dst_col_stride*/,
+    stride_type const /*src_row_stride*/)
   {
     *dst = *src;
   }
@@ -117,10 +121,10 @@
 struct Unrolled_transpose<float, float, 4, false>
 {
   static void exec(
-    float*         dst,
-    float const*   src,
-    unsigned const dst_col_stride,
-    unsigned const src_row_stride)
+    float*            dst,
+    float const*      src,
+    stride_type const dst_col_stride,
+    stride_type const src_row_stride)
   {
     __v4sf row0 = _mm_loadu_ps(src + 0*src_row_stride + 0);
     __v4sf row1 = _mm_loadu_ps(src + 1*src_row_stride + 0);
@@ -142,10 +146,10 @@
 struct Unrolled_transpose<float, float, 4, true>
 {
   static void exec(
-    float*         dst,
-    float const*   src,
-    unsigned const dst_col_stride,
-    unsigned const src_row_stride)
+    float*            dst,
+    float const*      src,
+    stride_type const dst_col_stride,
+    stride_type const src_row_stride)
   {
     __v4sf row0 = _mm_load_ps(src + 0*src_row_stride + 0);
     __v4sf row1 = _mm_load_ps(src + 1*src_row_stride + 0);
@@ -169,8 +173,8 @@
   static void exec(
     complex<float>*       dst,
     complex<float>const * src,
-    unsigned const        dst_col_stride,
-    unsigned const        src_row_stride)
+    stride_type const     dst_col_stride,
+    stride_type const     src_row_stride)
   {
     __v4sf row0 = _mm_loadu_ps(
 		reinterpret_cast<float const*>(src + 0*src_row_stride + 0));
@@ -195,8 +199,8 @@
   static void exec(
     complex<float>*       dst,
     complex<float>const * src,
-    unsigned const        dst_col_stride,
-    unsigned const        src_row_stride)
+    stride_type const     dst_col_stride,
+    stride_type const     src_row_stride)
   {
     __v4sf row0 = _mm_load_ps(
 		reinterpret_cast<float const*>(src + 0*src_row_stride + 0));
@@ -226,10 +230,10 @@
 struct Unrolled_transpose<float, float, 2, SimdAligned>
 {
   static void exec(
-    float*         dst,
-    float const*   src,
-    unsigned const dst_col_stride,
-    unsigned const src_row_stride)
+    float*            dst,
+    float const*      src,
+    stride_type const dst_col_stride,
+    stride_type const src_row_stride)
   {
     __v2sf row0 = *(__v2sf*)(src  + 0*src_row_stride + 0);
     __v2sf row1 = *(__v2sf*)(src  + 1*src_row_stride + 0);
@@ -248,8 +252,8 @@
   static void exec(
     complex<float>*         dst,
     complex<float> const*   src,
-    unsigned const          /*dst_col_stride*/,
-    unsigned const          /*src_row_stride*/)
+    stride_type const       /*dst_col_stride*/,
+    stride_type const       /*src_row_stride*/)
   {
     __v2sf row0 = *(__v2sf*)(src);
 
@@ -267,25 +271,26 @@
 // transpose_unit implementation tags.
 
 struct Impl_loop {};
-template <unsigned Block, bool SimdAligned> struct Impl_block_iter {};
-template <unsigned Block, bool SimdAligned> struct Impl_block_recur {};
-template <unsigned Block, bool SimdAligned> struct Impl_block_recur_helper {};
+template <length_type Block, bool SimdAligned> struct Impl_block_iter {};
+template <length_type Block, bool SimdAligned> struct Impl_block_recur {};
+template <length_type Block, bool SimdAligned> struct Impl_block_recur_helper
+{};
 struct Impl_recur {};
 
 template <typename T1,
 	  typename T2>
 void
 transpose_unit(
-  T1*            dst,
-  T2 const*      src,
-  unsigned const rows,		// dst rows
-  unsigned const cols,		// dst cols
-  unsigned const dst_col_stride,
-  unsigned const src_row_stride,
+  T1*               dst,
+  T2 const*         src,
+  length_type const rows,		// dst rows
+  length_type const cols,		// dst cols
+  stride_type const dst_col_stride,
+  stride_type const src_row_stride,
   Impl_loop)
 {
-  for (unsigned r=0; r<rows; ++r)
-    for (unsigned c=0; c<cols; ++c)
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
       dst[r+c*dst_col_stride] = src[r*src_row_stride+c];
 }
 
@@ -297,15 +302,15 @@
 transpose_unit(
   complex<float>*       dst,
   complex<float> const* src,
-  unsigned const        rows,		// dst rows
-  unsigned const        cols,		// dst cols
-  unsigned const        dst_col_stride,
-  unsigned const        src_row_stride,
+  length_type const     rows,		// dst rows
+  length_type const     cols,		// dst cols
+  stride_type const     dst_col_stride,
+  stride_type const     src_row_stride,
   Impl_loop)
 {
   __asm__ __volatile__ ("femms");
-  for (unsigned r=0; r<rows; ++r)
-    for (unsigned c=0; c<cols; ++c)
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
     {
       __v2sf row0 = *(__v2sf*)(src + r*src_row_stride+c);
       *(__v2sf*)(dst + r+c*dst_col_stride) = row0;
@@ -318,28 +323,28 @@
 
 /// Blocked transpose, using iteration over blocks.
 
-template <typename T1,
-	  typename T2,
-	  unsigned Block,
-	  bool     SimdAligned>
+template <typename    T1,
+	  typename    T2,
+	  length_type Block,
+	  bool        SimdAligned>
 void
 transpose_unit(
-  T1*            dst,
-  T2 const*      src,
-  unsigned const rows,		// dst rows
-  unsigned const cols,		// dst cols
-  unsigned const dst_col_stride,
-  unsigned const src_row_stride,
+  T1*               dst,
+  T2 const*         src,
+  length_type const rows,		// dst rows
+  length_type const cols,		// dst cols
+  stride_type const dst_col_stride,
+  stride_type const src_row_stride,
   Impl_block_iter<Block, SimdAligned>)
 {
-  unsigned full_cols = cols - cols%Block;
-  unsigned full_rows = rows - rows%Block;
+  length_type full_cols = cols - cols%Block;
+  length_type full_rows = rows - rows%Block;
 
   // Transpose core of matrix using Unrolled_transpose a block
   // at a time.
 
-  for (unsigned r=0; r<full_rows; r += Block)
-    for (unsigned c=0; c<full_cols; c += Block)
+  for (index_type r=0; r<full_rows; r += Block)
+    for (index_type c=0; c<full_cols; c += Block)
     {
       transpose_simd_start();
       Unrolled_transpose<T1, T2, Block, SimdAligned>::exec(
@@ -355,8 +360,8 @@
 
   if (full_cols != cols)
   {
-    unsigned extra_cols = cols - full_cols;
-    for (unsigned r=0; r<full_rows; r += Block)
+    length_type extra_cols = cols - full_cols;
+    for (index_type r=0; r<full_rows; r += Block)
       transpose_unit(dst + r + full_cols*dst_col_stride,
 		     src + r*src_row_stride + full_cols,
 		     Block, extra_cols,
@@ -366,8 +371,8 @@
   }
   if (full_rows != rows)
   {
-    unsigned extra_rows = rows - full_rows;
-    for (unsigned c=0; c<full_cols; c += Block)
+    length_type extra_rows = rows - full_rows;
+    for (index_type c=0; c<full_cols; c += Block)
       transpose_unit(dst + full_rows + c*dst_col_stride,
 		     src + full_rows*src_row_stride + c,
 		     extra_rows, Block,
@@ -392,25 +397,25 @@
 
 /// This routine performs the recursive sub-division for Impl_block_recur.
 
-template <typename T1,
-	  typename T2,
-	  unsigned Block,
-	  bool     SimdAligned>
+template <typename    T1,
+	  typename    T2,
+	  length_type Block,
+	  bool        SimdAligned>
 void
 transpose_unit(
-  T1*            dst,
-  T2 const*      src,
-  unsigned const rows,		// dst rows
-  unsigned const cols,		// dst cols
-  unsigned const dst_col_stride,
-  unsigned const src_row_stride,
+  T1*               dst,
+  T2 const*         src,
+  length_type const rows,		// dst rows
+  length_type const cols,		// dst cols
+  stride_type const dst_col_stride,
+  stride_type const src_row_stride,
   Impl_block_recur_helper<Block, SimdAligned>)
 {
-  unsigned const thresh = 4*Block;
+  length_type const thresh = 4*Block;
   if (rows <= thresh && cols <= thresh)
   {
-    for (unsigned r=0; r<rows; r+=Block)
-      for (unsigned c=0; c<cols; c+=Block)
+    for (index_type r=0; r<rows; r+=Block)
+      for (index_type c=0; c<cols; c+=Block)
 	Unrolled_transpose<T1, T2, Block, SimdAligned>::exec(
 			dst + r + c*dst_col_stride,
 			src + r*src_row_stride + c,
@@ -419,8 +424,8 @@
   }
   else if (cols >= rows)
   {
-    unsigned cols1 = ((cols/Block)/2) * Block;
-    unsigned cols2 = cols - cols1;
+    length_type cols1 = ((cols/Block)/2) * Block;
+    length_type cols2 = cols - cols1;
 
     transpose_unit(dst,          src,
 		   rows, cols1,
@@ -434,8 +439,8 @@
   }
   else
   {
-    unsigned rows1 = ((rows/Block)/2) * Block;
-    unsigned rows2 = rows - rows1;
+    length_type rows1 = ((rows/Block)/2) * Block;
+    length_type rows2 = rows - rows1;
 
     transpose_unit(dst,          src,
 		   rows1, cols,
@@ -453,22 +458,22 @@
 
 /// Blocked transpose, using recursion over blocks.
 
-template <typename T1,
-	  typename T2,
-	  unsigned Block,
-	  bool     SimdAligned>
+template <typename    T1,
+	  typename    T2,
+	  length_type Block,
+	  bool        SimdAligned>
 void
 transpose_unit(
   T1*            dst,
   T2 const*      src,
-  unsigned const rows,		// dst rows
-  unsigned const cols,		// dst cols
-  unsigned const dst_col_stride,
-  unsigned const src_row_stride,
+  length_type const rows,		// dst rows
+  length_type const cols,		// dst cols
+  stride_type const dst_col_stride,
+  stride_type const src_row_stride,
   Impl_block_recur<Block, SimdAligned>)
 {
-  unsigned full_cols = cols - cols%Block;
-  unsigned full_rows = rows - rows%Block;
+  length_type full_cols = cols - cols%Block;
+  length_type full_rows = rows - rows%Block;
 
   // Transpose core of matrix using Unrolled_transpose a block
   // at a time.
@@ -485,8 +490,8 @@
 
   if (full_cols != cols)
   {
-    unsigned extra_cols = cols - full_cols;
-    for (unsigned r=0; r<full_rows; r += Block)
+    length_type extra_cols = cols - full_cols;
+    for (index_type r=0; r<full_rows; r += Block)
       transpose_unit(dst + r + full_cols*dst_col_stride,
 		     src + r*src_row_stride + full_cols,
 		     Block, extra_cols,
@@ -496,8 +501,8 @@
   }
   if (full_rows != rows)
   {
-    unsigned extra_rows = rows - full_rows;
-    for (unsigned c=0; c<full_cols; c += Block)
+    length_type extra_rows = rows - full_rows;
+    for (index_type c=0; c<full_cols; c += Block)
       transpose_unit(dst + full_rows + c*dst_col_stride,
 		     src + full_rows*src_row_stride + c,
 		     extra_rows, Block,
@@ -528,19 +533,19 @@
 	  typename T2>
 void
 transpose_unit(
-  T1*            dst,
-  T2 const*      src,
-  unsigned const rows,		// dst rows
-  unsigned const cols,		// dst cols
-  unsigned const dst_col_stride,
-  unsigned const src_row_stride,
+  T1*               dst,
+  T2 const*         src,
+  length_type const rows,		// dst rows
+  length_type const cols,		// dst cols
+  stride_type const dst_col_stride,
+  stride_type const src_row_stride,
   Impl_recur)
 {
-  unsigned const thresh = 16;
+  length_type const thresh = 16;
   if (rows <= thresh && cols <= thresh)
   {
-    for (unsigned r=0; r<rows; ++r)
-      for (unsigned c=0; c<cols; ++c)
+    for (index_type r=0; r<rows; ++r)
+      for (index_type c=0; c<cols; ++c)
 	dst[r+c*dst_col_stride] = src[r*src_row_stride+c];
   }
   else if (cols >= rows)
@@ -576,10 +581,10 @@
 transpose_unit(
   T1*            dst,
   T2 const*      src,
-  unsigned const rows,		// dst rows
-  unsigned const cols,		// dst cols
-  unsigned const dst_col_stride,
-  unsigned const src_row_stride)
+  length_type const rows,		// dst rows
+  length_type const cols,		// dst cols
+  stride_type const dst_col_stride,
+  stride_type const src_row_stride)
 {
   // Check if data is aligned for SSE ISA.
   //  - pointers need to be 16-byte aligned
@@ -630,20 +635,20 @@
 	  typename T2>
 void
 transpose(
-  T1*            dst,
-  T2 const*      src,
-  unsigned const rows,		// dst rows
-  unsigned const cols,		// dst cols
-  unsigned const dst_stride0,
-  unsigned const dst_stride1,	// eq. to dst_col_stride
-  unsigned const src_stride0,	// eq. to src_row_stride
-  unsigned const src_stride1)
+  T1*               dst,
+  T2 const*         src,
+  length_type const rows,		// dst rows
+  length_type const cols,		// dst cols
+  stride_type const dst_stride0,
+  stride_type const dst_stride1,	// eq. to dst_col_stride
+  stride_type const src_stride0,	// eq. to src_row_stride
+  stride_type const src_stride1)
 {
-  unsigned const thresh = 16;
+  length_type const thresh = 16;
   if (rows <= thresh && cols <= thresh)
   {
-    for (unsigned r=0; r<rows; ++r)
-      for (unsigned c=0; c<cols; ++c)
+    for (index_type r=0; r<rows; ++r)
+      for (index_type c=0; c<cols; ++c)
 	dst[r*dst_stride0+c*dst_stride1] = src[r*src_stride0+c*src_stride1];
   }
   else if (cols >= rows)
@@ -653,7 +658,7 @@
 	      dst_stride0, dst_stride1,
 	      src_stride0, src_stride1);
 
-    transpose(dst + (cols/2)*dst_stride1, src + (cols/2),
+    transpose(dst + (cols/2)*dst_stride1, src + (cols/2)*src_stride1,
 	      rows, cols/2 + cols%2,
 	      dst_stride0, dst_stride1,
 	      src_stride0, src_stride1);
@@ -665,7 +670,7 @@
 	      dst_stride0, dst_stride1,
 	      src_stride0, src_stride1);
 
-    transpose(dst + (rows/2), src + (rows/2)*src_stride0,
+    transpose(dst + (rows/2)*dst_stride0, src + (rows/2)*src_stride0,
 	      rows/2 + rows%2, cols,
 	      dst_stride0, dst_stride1,
 	      src_stride0, src_stride1);
Index: src/vsip/impl/solver-cholesky.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-cholesky.hpp,v
retrieving revision 1.4
diff -u -r1.4 solver-cholesky.hpp
--- src/vsip/impl/solver-cholesky.hpp	14 Apr 2006 21:42:08 -0000	1.4
+++ src/vsip/impl/solver-cholesky.hpp	21 Apr 2006 01:06:48 -0000
@@ -21,7 +21,7 @@
 #include <vsip/impl/math-enum.hpp>
 #include <vsip/impl/lapack.hpp>
 #include <vsip/impl/temp_buffer.hpp>
-#ifdef VSIP_IMPL_USE_SAL_SOL
+#ifdef VSIP_IMPL_HAVE_SAL
 #include <vsip/impl/sal/solver_cholesky.hpp>
 #endif
 #include <vsip/impl/lapack/solver_cholesky.hpp>
@@ -42,9 +42,9 @@
 template <typename T>
 struct Choose_chold_impl
 {
-#ifndef VSIP_IMPL_USE_SAL_SOL
+#ifndef VSIP_IMPL_HAVE_SAL
   typedef typename ITE_Type<Is_chold_impl_avail<Mercury_sal_tag, T>::value,
-                            As_type<Merucry_sal_tag>,
+                            As_type<Mercury_sal_tag>,
 			    As_type<Lapack_tag> >::type type;
 #else
   typedef typename As_type<Lapack_tag>::type type;
Index: src/vsip/impl/solver-lu.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-lu.hpp,v
retrieving revision 1.4
diff -u -r1.4 solver-lu.hpp
--- src/vsip/impl/solver-lu.hpp	14 Apr 2006 21:42:08 -0000	1.4
+++ src/vsip/impl/solver-lu.hpp	21 Apr 2006 01:06:48 -0000
@@ -22,7 +22,9 @@
 #include <vsip/impl/lapack.hpp>
 #include <vsip/impl/temp_buffer.hpp>
 #include <vsip/impl/metaprogramming.hpp>
-#include <vsip/impl/sal/solver_lu.hpp>
+#ifdef VSIP_IMPL_HAVE_SAL
+#  include <vsip/impl/sal/solver_lu.hpp>
+#endif
 #include <vsip/impl/lapack/solver_lu.hpp>
 
 
@@ -42,7 +44,7 @@
 struct Choose_lud_impl
 {
 
-#ifdef VSIP_IMPL_USE_SAL_SOL
+#ifdef VSIP_IMPL_HAVE_SAL
   typedef typename ITE_Type<Is_lud_impl_avail<Mercury_sal_tag, T>::value,
                             As_type<Mercury_sal_tag>,
 			    As_type<Lapack_tag> >::type type;
Index: tests/regressions/transpose-mirror.cpp
===================================================================
RCS file: tests/regressions/transpose-mirror.cpp
diff -N tests/regressions/transpose-mirror.cpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ tests/regressions/transpose-mirror.cpp	21 Apr 2006 01:06:48 -0000
@@ -0,0 +1,84 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/regressions/transpose-mirror.cpp
+    @author  Jules Bergmann
+    @date    2006-04-20
+    @brief   VSIPL++ Library: Regression test for fast transpose with
+                              negative strides.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/domain.hpp>
+
+#include "test.hpp"
+
+using namespace vsip;
+
+
+/***********************************************************************
+  Definitions - Utility Functions
+***********************************************************************/
+
+template <typename T>
+void
+test_assign(Domain<2> const& dom)
+{
+  length_type const rows = dom[0].size();
+  length_type const cols = dom[1].size();
+
+  Matrix<T, Dense<2, T, row2_type> > src(rows, cols);
+  Matrix<T, Dense<2, T, col2_type> > dst1(rows, cols, T());
+  Matrix<T, Dense<2, T, col2_type> > dst2(rows, cols, T());
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+      src(r, c) = T(r*cols+c);
+
+  // Setup transpose so that RHS has negative strides for both
+  // rows and columns.
+  dst1 = src(Domain<2>(Domain<1>(rows-1, -1, rows),
+		      Domain<1>(cols-1, -1, cols)));
+  dst2(Domain<2>(Domain<1>(rows-1, -1, rows), Domain<1>(cols-1, -1, cols)))
+    = src;
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+    {
+      index_type rr = rows-1-r;
+      index_type cc = cols-1-c;
+      test_assert(equal(dst1(r, c), T(rr*cols+cc)));
+      test_assert(equal(dst1(r, c), src(rr, cc)));
+
+      test_assert(equal(dst2(r, c), T(rr*cols+cc)));
+      test_assert(equal(dst2(r, c), src(rr, cc)));
+    }
+}
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  // These tests caused seg-faults in fast-transpose on
+  // systems where sizeof(unsigned) != sizeof(stride_type),
+  // such as x86-64.
+
+
+  test_assign<float>(Domain<2>(3, 3));
+  test_assign<float>(Domain<2>(3, 4));
+  test_assign<float>(Domain<2>(16, 17));
+
+  test_assign<complex<float> >(Domain<2>(3, 3));
+  test_assign<complex<float> >(Domain<2>(4, 8));
+  test_assign<complex<float> >(Domain<2>(16, 64));
+  test_assign<complex<float> >(Domain<2>(64, 32));
+  test_assign<complex<float> >(Domain<2>(256, 256));
+}
Index: tests/regressions/transpose-nonunit.cpp
===================================================================
RCS file: tests/regressions/transpose-nonunit.cpp
diff -N tests/regressions/transpose-nonunit.cpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ tests/regressions/transpose-nonunit.cpp	21 Apr 2006 01:06:48 -0000
@@ -0,0 +1,76 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/transpose-nonunit.cpp
+    @author  Jules Bergmann
+    @date    2006-04-20
+    @brief   VSIPL++ Library: Regression test for fast transpose with
+                              non-unit strides.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/domain.hpp>
+
+#include "test.hpp"
+
+using namespace vsip;
+
+
+/***********************************************************************
+  Definitions - Utility Functions
+***********************************************************************/
+
+// Test transpose between arrays with non-unit-stride
+
+template <typename T>
+void
+test_assign(Domain<2> const& dom)
+{
+  length_type const rows = dom[0].size();
+  length_type const cols = dom[1].size();
+
+  typedef typename Matrix<T, Dense<2, T, row2_type> >::subview_type src_view;
+  typedef typename Matrix<T, Dense<2, T, col2_type> >::subview_type dst_view;
+
+  Matrix<T, Dense<2, T, row2_type> > big_src(2*rows, 2*cols, T(-5));
+  Matrix<T, Dense<2, T, col2_type> > big_dst(2*rows, 2*cols, T(-10));
+
+  src_view src = big_src(Domain<2>(Domain<1>(0, 2, rows),
+				   Domain<1>(0, 2, cols)));
+  dst_view dst = big_dst(Domain<2>(Domain<1>(0, 2, rows),
+				   Domain<1>(0, 2, cols)));
+
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+      src(r, c) = T(r*cols+c);
+
+  dst = src;
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+    {
+      test_assert(equal(dst(r, c), T(r*cols+c)));
+      test_assert(equal(dst(r, c), src(r, c)));
+    }
+}
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_assign<float>(Domain<2>(16, 17));
+  test_assign<float>(Domain<2>(32, 16));
+
+  test_assign<complex<float> >(Domain<2>(16, 64));
+  test_assign<complex<float> >(Domain<2>(64, 32));
+  test_assign<complex<float> >(Domain<2>(256, 256));
+}
