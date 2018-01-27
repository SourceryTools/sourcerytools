Index: ChangeLog
===================================================================
--- ChangeLog	(revision 149246)
+++ ChangeLog	(working copy)
@@ -1,5 +1,13 @@
 2006-09-14  Jules Bergmann  <jules@codesourcery.com>
 
+	* tests/regressions/transpose_assign.cpp: New file, regression
+	  test for ICC 9.1 for Windows bug in fast-transpose.hpp.
+	  (Bug work around already committed).
+	* tests/test_common.hpp: New file, common routines to setup,
+	  check, and show views.
+	
+2006-09-14  Jules Bergmann  <jules@codesourcery.com>
+
 	* scripts/set-prefix.sh: Change #! to /bin/sh
 	* scripts/package.py: Add support for builtin_libdir to distinguish
 	  libdir of builtin libraries (which can be shared amonst
Index: tests/regressions/transpose_assign.cpp
===================================================================
--- tests/regressions/transpose_assign.cpp	(revision 0)
+++ tests/regressions/transpose_assign.cpp	(revision 0)
@@ -0,0 +1,162 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    tests/regressions/transpose_assign.cpp
+    @author  Jules Bergmann
+    @date    2006-09-14
+    @brief   VSIPL++ Library: Regression test for transpose assignment.
+
+    This test triggers a bug with Intel C++ for Windows 9.1 Build 20060816Z,
+    32-bit version.  Soucery VSIPL++ works around this bug by disabling
+    some dispatch in fast-transpose.hpp.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <memory>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+
+#include "test_common.hpp"
+
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Definitions - Utility Functions
+***********************************************************************/
+
+// High-level transpose test.
+
+template <typename T,
+	  typename DstOrderT,
+	  typename SrcOrderT>
+void
+test_hl(length_type rows, length_type cols)
+{
+  typedef Dense<2, T, SrcOrderT> src_block_type;
+  typedef Dense<2, T, DstOrderT> dst_block_type;
+
+  Matrix<T, src_block_type> src(rows, cols, T(-1));
+  Matrix<T, dst_block_type> dst(rows, cols, T(-2));
+
+  setup(src, 1);
+
+  dst = src;
+
+  check(dst, 1);
+}
+
+
+
+template <typename T,
+	  typename DstOrderT,
+	  typename SrcOrderT>
+void
+cover_hl()
+{
+  // These tests fail for Intel C++ 9.1 for Windows prior
+  // to workaround in fast-transpose.hpp:
+  test_hl<T, DstOrderT, SrcOrderT>(5, 3);  // known bad case
+  test_hl<T, DstOrderT, SrcOrderT>(16, 3); // known bad case
+  test_hl<T, DstOrderT, SrcOrderT>(17, 3); // known bad case
+
+  {
+    length_type max_rows = 32;
+    length_type max_cols = 32;
+    for (index_type rows=1; rows<max_rows; ++rows)
+      for (index_type cols=1; cols<max_cols; ++cols)
+	test_hl<T, DstOrderT, SrcOrderT>(rows, cols);
+  }
+
+  {
+    length_type max_rows = 256;
+    length_type max_cols = 256;
+    for (index_type rows=1; rows<max_rows; rows+=3)
+      for (index_type cols=1; cols<max_cols; cols+=5)
+      {
+	test_hl<T, DstOrderT, SrcOrderT>(rows, cols);
+	test_hl<T, DstOrderT, SrcOrderT>(cols, rows);
+      }
+  }
+}
+
+
+
+// Low-level transpose test (call transpose_unit directly).
+
+template <typename T>
+void
+test_ll(length_type rows, length_type cols)
+{
+  std::auto_ptr<T> src(new T[rows*cols]);
+  std::auto_ptr<T> dst(new T[rows*cols]);
+
+  for (index_type r=0; r<rows; r++)
+    for (index_type c=0; c<cols; c++)
+    {
+      src.get()[r*cols + c] = T(100*r + c);
+      dst.get()[r + c*rows] = T(-100);
+    }
+
+  vsip::impl::transpose_unit(
+		dst.get(), src.get(), rows, cols, 
+  		rows, // dst_col_stride
+  		cols); // src_row_stride
+
+  for (index_type r=0; r<rows; r++)
+    for (index_type c=0; c<cols; c++)
+      test_assert(dst.get()[r + c*rows] == T(100*r + c));
+}
+
+
+template <typename T>
+void
+cover_ll()
+{
+  {
+    length_type max_rows = 32;
+    length_type max_cols = 32;
+    for (index_type rows=1; rows<max_rows; ++rows)
+      for (index_type cols=1; cols<max_cols; ++cols)
+	test_ll<T>(rows, cols);
+  }
+
+  {
+    length_type max_rows = 256;
+    length_type max_cols = 256;
+    for (index_type rows=1; rows<max_rows; rows+=3)
+      for (index_type cols=1; cols<max_cols; cols+=5)
+      {
+	test_ll<T>(rows, cols);
+	test_ll<T>(cols, rows);
+      }
+  }
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  typedef impl::Cmplx_inter_fmt cif;
+  typedef impl::Cmplx_split_fmt csf;
+
+  vsipl init(argc, argv);
+
+  cover_hl<float, row2_type, col2_type>();
+  cover_hl<complex<float>, row2_type, col2_type>();
+
+  cover_ll<float>();
+  cover_ll<complex<float> >();
+}
Index: tests/test_common.hpp
===================================================================
--- tests/test_common.hpp	(revision 0)
+++ tests/test_common.hpp	(revision 0)
@@ -0,0 +1,290 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    tests/test_common.cpp
+    @author  Jules Bergmann
+    @date    2006-08-21
+    @brief   VSIPL++ Library: Common routines tests.
+
+*/
+
+#ifndef TESTS_TEST_COMMON_HPP
+#define TESTS_TEST_COMMON_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/complex.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/map.hpp>
+
+#define VERBOSE   0
+#define DO_ASSERT 1
+
+#if VERBOSE
+#  include <iostream>
+#endif
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T>
+struct Value_class
+{
+  static T exec(vsip::index_type idx, int k)
+  {
+    return T(k*idx);
+  }
+};
+
+template <typename T>
+struct Value_class<vsip::complex<T> >
+{
+  static vsip::complex<T> exec(vsip::index_type idx, int k)
+  {
+    return vsip::complex<T>(k*idx, k*idx+1);
+  }
+};
+
+
+
+template <typename T>
+inline T
+value(vsip::index_type idx, int k)
+{
+  return Value_class<T>::exec(idx, k);
+}
+
+
+
+template <typename T>
+inline T
+value(vsip::index_type row, vsip::index_type col, int k)
+{
+  return T(100*k*row + col);
+}
+
+
+
+template <typename T,
+	  typename BlockT>
+void
+setup(vsip::Vector<T, BlockT> vec, int k)
+{
+  using vsip::no_subblock;
+  using vsip::index_type;
+  typedef T value_type;
+
+  if (subblock(vec) != no_subblock)
+  {
+    for (index_type li=0; li<vec.local().size(); ++li)
+    {
+      index_type gi = global_from_local_index(vec, 0, li); 
+      vec.local().put(li, value<T>(gi, k));
+    }
+  }
+}
+
+
+
+template <typename T,
+	  typename BlockT>
+void
+setup(vsip::Matrix<T, BlockT> view, int k)
+{
+  using vsip::no_subblock;
+  using vsip::index_type;
+  typedef T value_type;
+
+  if (subblock(view) != no_subblock)
+  {
+    for (index_type lr=0; lr<view.local().size(0); ++lr)
+      for (index_type lc=0; lc<view.local().size(1); ++lc)
+      {
+	index_type gr = global_from_local_index(view, 0, lr); 
+	index_type gc = global_from_local_index(view, 1, lc); 
+	view.local().put(lr, lc, value<T>(gr, gc, k));
+      }
+  }
+}
+
+
+
+template <typename T,
+	  typename BlockT>
+void
+check(vsip::const_Vector<T, BlockT> vec, int k, int shift=0)
+{
+  using vsip::no_subblock;
+  using vsip::index_type;
+  typedef T value_type;
+
+#if VERBOSE
+  std::cout << "check(k=" << k << ", shift=" << shift << "):"
+	    << std::endl;
+#endif
+  if (subblock(vec) != no_subblock)
+  {
+    for (index_type li=0; li<vec.local().size(); ++li)
+    {
+      index_type gi = global_from_local_index(vec, 0, li); 
+#if VERBOSE
+      std::cout << " - " << li << "  gi:" << gi << " = "
+		<< vec.local().get(li)
+		<< "  exp: " << value<T>(gi + shift, k)
+		<< std::endl;
+#endif
+#if DO_ASSERT
+      test_assert(vec.local().get(li) == value<T>(gi + shift, k));
+#endif
+    }
+  }
+}
+
+
+
+template <typename T,
+	  typename BlockT>
+void
+check(vsip::const_Matrix<T, BlockT> view, int k, int rshift=0, int cshift=0)
+{
+  using vsip::no_subblock;
+  using vsip::index_type;
+  typedef T value_type;
+
+#if VERBOSE
+  std::cout << "check(k=" << k << ", rshift=" << rshift
+	    << ", cshift=" << cshift << "):"
+	    << std::endl;
+#endif
+  if (subblock(view) != no_subblock)
+  {
+    for (index_type lr=0; lr<view.local().size(0); ++lr)
+      for (index_type lc=0; lc<view.local().size(1); ++lc)
+      {
+	index_type gr = global_from_local_index(view, 0, lr); 
+	index_type gc = global_from_local_index(view, 1, lc); 
+#if VERBOSE
+	std::cout << " - " << lr << ", " << lc << "  g:"
+		  << gr << ", " << gc << " = "
+		  << view.local().get(lr, lc)
+		  << "  exp: " << value<T>(gr+rshift, gc + cshift, k)
+		  << std::endl;
+#endif
+#if DO_ASSERT
+	test_assert(view.local().get(lr, lc) ==
+		    value<T>(gr+rshift, gc+cshift, k));
+#endif
+      }
+  }
+}
+
+
+
+template <typename T,
+	  typename BlockT>
+void
+check_row_vector(vsip::const_Vector<T, BlockT> view, int row, int k=1)
+{
+  using vsip::no_subblock;
+  using vsip::index_type;
+  typedef T value_type;
+
+  if (subblock(view) != no_subblock)
+  {
+    for (index_type lc=0; lc<view.local().size(0); ++lc)
+    {
+      index_type gc = global_from_local_index(view, 0, lc); 
+      test_assert(view.local().get(lc) ==
+		  value<T>(row, gc, k));
+      }
+  }
+}
+
+
+
+template <typename T,
+	  typename BlockT>
+void
+check_col_vector(vsip::const_Vector<T, BlockT> view, int col, int k=0)
+{
+  using vsip::no_subblock;
+  using vsip::index_type;
+  typedef T value_type;
+
+  if (subblock(view) != no_subblock)
+  {
+    for (index_type lr=0; lr<view.local().size(0); ++lr)
+    {
+      index_type gr = global_from_local_index(view, 0, lr); 
+      test_assert(view.local().get(lr) == value<T>(gr, col, k));
+    }
+  }
+}
+
+
+
+template <typename T,
+	  typename BlockT>
+void
+show(vsip::const_Vector<T, BlockT> vec)
+{
+  using vsip::no_subblock;
+  using vsip::index_type;
+  typedef T value_type;
+
+  std::cout << "[" << vsip::local_processor() << "] " << "show\n";
+  if (subblock(vec) != no_subblock)
+  {
+    for (index_type li=0; li<vec.local().size(); ++li)
+    {
+      index_type gi = global_from_local_index(vec, 0, li); 
+      std::cout << "[" << vsip::local_processor() << "] "
+		<< li << "  gi:" << gi << " = "
+		<< vec.local().get(li)
+		<< std::endl;
+    }
+  }
+  else
+    std::cout << "[" << vsip::local_processor() << "] "
+	      << "show: no local subblock\n";
+}
+
+
+
+template <typename T,
+	  typename BlockT>
+void
+show(vsip::const_Matrix<T, BlockT> view)
+{
+  using vsip::no_subblock;
+  using vsip::index_type;
+  typedef T value_type;
+
+  std::cout << "[" << vsip::local_processor() << "] " << "show\n";
+  if (subblock(view) != no_subblock)
+  {
+    for (index_type lr=0; lr<view.local().size(0); ++lr)
+      for (index_type lc=0; lc<view.local().size(1); ++lc)
+      {
+	index_type gr = global_from_local_index(view, 0, lr); 
+	index_type gc = global_from_local_index(view, 1, lc); 
+	std::cout << "[" << vsip::local_processor() << "] "
+		  << lr << "," << lc
+		  << "  g:" << gr << "," << gc << " = "
+		  << view.local().get(lr, lc)
+		  << std::endl;
+      }
+  }
+  else
+    std::cout << "[" << vsip::local_processor() << "] "
+	      << "show: no local subblock\n";
+}
+
+#undef VERBOSE
+
+#endif // TESTS_TEST_COMMON_HPP
