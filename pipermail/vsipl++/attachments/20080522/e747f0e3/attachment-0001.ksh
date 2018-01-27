Index: tests/test-prod.hpp
===================================================================
--- tests/test-prod.hpp	(revision 0)
+++ tests/test-prod.hpp	(revision 0)
@@ -0,0 +1,106 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/test-prod.hpp
+    @author  Jules Bergmann
+    @date    2005-09-12
+    @brief   VSIPL++ Library: Common definitions for matrix product tests.
+*/
+
+#ifndef VSIP_TESTS_TEST_PROD_HPP
+#define VSIP_TESTS_TEST_PROD_HPP
+
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/vector.hpp>
+
+#include <vsip_csl/test-precision.hpp>
+#include <vsip_csl/test.hpp>
+
+
+#if VERBOSE
+#include <iostream>
+#endif
+
+
+/***********************************************************************
+  Reference Definitions
+***********************************************************************/
+
+template <typename T0,
+	  typename T1,
+          typename T2,
+          typename Block0,
+          typename Block1,
+          typename Block2>
+void
+check_prod(
+  vsip::Matrix<T0, Block0> test,
+  vsip::Matrix<T1, Block1> chk,
+  vsip::Matrix<T2, Block2> gauge)
+{
+  typedef typename vsip::Promotion<T0, T1>::type return_type;
+  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
+
+  vsip::Index<2> idx;
+  scalar_type err = vsip::maxval(((mag(chk - test)
+			     / vsip_csl::Precision_traits<scalar_type>::eps)
+			    / gauge),
+			   idx);
+
+#if VERBOSE
+  std::cout << "test  =\n" << test;
+  std::cout << "chk   =\n" << chk;
+  std::cout << "gauge =\n" << gauge;
+  std::cout << "err = " << err << std::endl;
+#endif
+
+  test_assert(err < 10.0);
+}
+
+
+template <typename T0,
+	  typename T1,
+          typename T2,
+          typename Block0,
+          typename Block1,
+          typename Block2>
+void
+check_prod(
+  vsip::Vector<T0, Block0> test,
+  vsip::Vector<T1, Block1> chk,
+  vsip::Vector<T2, Block2> gauge)
+{
+  typedef typename vsip::Promotion<T0, T1>::type return_type;
+  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
+
+  vsip::Index<1> idx;
+  scalar_type err = vsip::maxval(((mag(chk - test)
+			     / vsip_csl::Precision_traits<scalar_type>::eps)
+			    / gauge),
+			   idx);
+
+#if VERBOSE
+  std::cout << "test  =\n" << test;
+  std::cout << "chk   =\n" << chk;
+  std::cout << "gauge =\n" << gauge;
+  std::cout << "err = " << err << std::endl;
+#endif
+
+  test_assert(err < 10.0);
+}
+
+
+template <> float  vsip_csl::Precision_traits<float>::eps = 0.0;
+template <> double vsip_csl::Precision_traits<double>::eps = 0.0;
+
+
+#endif // VSIP_TESTS_TEST_PROD_HPP
Index: tests/matvec-prodmv.cpp
===================================================================
--- tests/matvec-prodmv.cpp	(revision 208645)
+++ tests/matvec-prodmv.cpp	(working copy)
@@ -4,11 +4,10 @@
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    tests/matvec-prod.cpp
+/** @file    tests/matvec-prodmv.cpp
     @author  Jules Bergmann
     @date    2005-09-12
-    @brief   VSIPL++ Library: Unit tests for products
-	     (matrix-matrix, matrix-vector, vector-matrix).
+    @brief   VSIPL++ Library: Unit tests for matrix products.
 */
 
 /***********************************************************************
@@ -27,6 +26,7 @@
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/test-precision.hpp>
 
+#include "test-prod.hpp"
 #include "test-random.hpp"
 
 using namespace std;
@@ -35,250 +35,10 @@
 
 
 /***********************************************************************
-  Reference Definitions
-***********************************************************************/
-
-template <typename T0,
-	  typename T1,
-          typename T2,
-          typename Block0,
-          typename Block1,
-          typename Block2>
-void
-check_prod(
-  Matrix<T0, Block0> test,
-  Matrix<T1, Block1> chk,
-  Matrix<T2, Block2> gauge)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Index<2> idx;
-  scalar_type err = maxval(((mag(chk - test)
-			     / Precision_traits<scalar_type>::eps)
-			    / gauge),
-			   idx);
-
-#if VERBOSE
-  cout << "test  =\n" << test;
-  cout << "chk   =\n" << chk;
-  cout << "gauge =\n" << gauge;
-  cout << "err = " << err << endl;
-#endif
-
-  test_assert(err < 10.0);
-}
-
-
-template <typename T0,
-	  typename T1,
-          typename T2,
-          typename Block0,
-          typename Block1,
-          typename Block2>
-void
-check_prod(
-  Vector<T0, Block0> test,
-  Vector<T1, Block1> chk,
-  Vector<T2, Block2> gauge)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Index<1> idx;
-  scalar_type err = maxval(((mag(chk - test)
-			     / Precision_traits<scalar_type>::eps)
-			    / gauge),
-			   idx);
-
-#if VERBOSE
-  cout << "test  =\n" << test;
-  cout << "chk   =\n" << chk;
-  cout << "gauge =\n" << gauge;
-  cout << "err = " << err << endl;
-#endif
-
-  test_assert(err < 10.0);
-}
-
-
-
-/***********************************************************************
   Test Definitions
 ***********************************************************************/
 
-/// Test matrix-matrix, matrix-vector, and vector-matrix products.
-
 template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-test_prod_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  typedef Dense<2, T0, Order0>          block0_type;
-  typedef Dense<2, T1, Order1>          block1_type;
-  typedef Dense<2, return_type, OrderR> blockR_type;
-
-  Matrix<T0, block0_type>          a(m, n);
-  Matrix<T1, block1_type>          b(n, k);
-  Matrix<return_type, blockR_type> res1(m, k);
-  Matrix<return_type, blockR_type> res2(m, k);
-  Matrix<return_type, blockR_type> res3(m, k);
-  Matrix<return_type, blockR_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod(a, b.col(i));
-
-  // Test vector-matrix prod
-  for (index_type i=0; i<m; ++i)
-    res3.row(i) = prod(a.row(i), b);
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]  [" << 
-    n << "x" << k << "]  [" << m << "x" << k << "]  "  << endl;
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-  check_prod( res3, chk, gauge );
-}
-
-
-
-template <typename T>
-void
-test_mm_prod_subview( const length_type m, 
-                      const length_type n, 
-                      const length_type k )
-{
-  typedef typename Matrix<T>::subview_type matrix_subview_type;
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-
-  // non-unit strides - dense rows, non-dense columns
-  {
-    Matrix<T> aa(m, k*2, T());
-    Matrix<T> bb(k, n*3, T());
-    matrix_subview_type a = aa(Domain<2>(
-                                 Domain<1>(0, 1, m), Domain<1>(0, 2, k)));
-    matrix_subview_type b = bb(Domain<2>(
-                                 Domain<1>(0, 1, k), Domain<1>(0, 3, n)));
-    Matrix<T> res(m, n);
-    Matrix<T> chk(m, n);
-    Matrix<scalar_type> gauge(m, n);
-
-    randm(a);
-    randm(b);
-
-    res = prod( a, b );
-    chk = ref::prod( a, b );
-    gauge = ref::prod(mag(a), mag(b));
-
-    for (index_type i=0; i<gauge.size(0); ++i)
-      for (index_type j=0; j<gauge.size(1); ++j)
-        if (!(gauge(i, j) > scalar_type()))
-          gauge(i, j) = scalar_type(1);
-
-    check_prod( res, chk, gauge );
-  }
-
-  // non-unit strides - non-dense rows, dense columns
-  {
-    Matrix<T> aa(m*2, k, T());
-    Matrix<T> bb(k*3, n, T());
-    matrix_subview_type a = aa(Domain<2>( 
-                                 Domain<1>(0, 2, m), Domain<1>(0, 1, k)));
-    matrix_subview_type b = bb(Domain<2>(
-                                 Domain<1>(0, 3, k), Domain<1>(0, 1, n)));
-
-    Matrix<T> res(m, n);
-    Matrix<T> chk(m, n);
-    Matrix<scalar_type> gauge(m, n);
-
-    randm(a);
-    randm(b);
-
-    res = prod( a, b );
-    chk = ref::prod( a, b );
-    gauge = ref::prod(mag(a), mag(b));
-
-    for (index_type i=0; i<gauge.size(0); ++i)
-      for (index_type j=0; j<gauge.size(1); ++j)
-        if (!(gauge(i, j) > scalar_type()))
-          gauge(i, j) = scalar_type(1);
-
-    check_prod( res, chk, gauge );
-  }
-}
-
-
-
-template <typename T>
-void 
-test_mm_prod_complex_split(  const length_type m, 
-                             const length_type n, 
-                             const length_type k )
-{
-  typedef vsip::impl::Fast_block<2, complex<T>,
-    vsip::impl::Layout<2, row2_type,
-    vsip::impl::Stride_unit_dense,
-    vsip::impl::Cmplx_split_fmt> > split_type;
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-  
-  Matrix<complex<T>, split_type> a(m, k);
-  Matrix<complex<T>, split_type> b(k, n);
-  Matrix<complex<T>, split_type> res(m, n, T());
-
-  randm(a);
-  randm(b);
-
-  // call prod()'s underlying interface directly
-  vsip::impl::generic_prod(a, b, res);
-
-  // compute a reference matrix using interleaved (default) layout
-  Matrix<complex<T> > aa(m, k);
-  Matrix<complex<T> > bb(k, n);
-  aa = a;
-  bb = b;
-
-  Matrix<complex<T> > chk(m, n);
-  Matrix<scalar_type> gauge(m, n);
-  chk = ref::prod( aa, bb );
-  gauge = ref::prod( mag(aa), mag(bb) );
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-        gauge(i, j) = scalar_type(1);
-
-  check_prod( res, chk, gauge );
-}
-
-
-
-template <typename T0,
 	  typename T1>
 void
 test_prod_mv(length_type m, length_type n)
@@ -330,6 +90,7 @@
   check_prod( r2, chk2, gauge2 );
 }
 
+
 template <typename T0,
 	  typename T1>
 void
@@ -387,324 +148,18 @@
 template <typename T0,
 	  typename T1>
 void
-test_prod3_rand()
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-  const length_type m = 3;
-  const length_type n = 3;
-  const length_type k = 3;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> res2(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod3(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod3(a, b.col(i));
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-  cout << "chk   =\n" << chk;
-  cout << "res1  =\n" << res1;
-  cout << "res2  =\n" << res2;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prod4_rand()
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-  const length_type m = 4;
-  const length_type n = 4;
-  const length_type k = 4;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> res2(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod4(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod4(a, b.col(i));
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prodh_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(k, n);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for hermitian
-  res1   = prod(a, herm(b));
-
-  chk   = ref::prod(a, herm(b));
-  gauge = ref::prod(mag(a), mag(herm(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prodj_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for hermitian
-  res1   = prod(a, conj(b));
-
-  chk   = ref::prod(a, conj(b));
-  gauge = ref::prod(mag(a), mag(conj(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-          typename T1,
-          typename OrderR,
-          typename Order0,
-          typename Order1>
-void
-test_prodt_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  typedef Dense<2, T0, Order0>          block0_type;
-  typedef Dense<2, T1, Order1>          block1_type;
-  typedef Dense<2, return_type, OrderR> blockR_type;
-
-  Matrix<T0, block0_type> a(m, n);
-  Matrix<T1, block1_type> b(k, n);
-  Matrix<return_type, blockR_type> res1(m, k);
-  Matrix<return_type, blockR_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for transpose
-  res1 = prodt(a, b);
-
-  chk   = ref::prod(a, trans(b));
-  gauge = ref::prod(mag(a), mag(trans(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-prod_types_with_order()
-{
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(5, 7, 9);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(9, 5, 7);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(9, 7, 5);
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prod_cases_with_order()
-{
-  prod_types_with_order<T0, T1, row2_type, row2_type, row2_type>();
-  prod_types_with_order<T0, T1, row2_type, col2_type, row2_type>();
-  prod_types_with_order<T0, T1, row2_type, row2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, col2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, row2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, col2_type, row2_type>();
-}
-
-
-template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-prodt_types_with_order()
-{
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 7, 9);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(9, 5, 7);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(9, 7, 5);
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prodt_cases_with_order()
-{
-  prodt_types_with_order<T0, T1, row2_type, row2_type, row2_type>();
-  prodt_types_with_order<T0, T1, row2_type, row2_type, col2_type>();
-}
-
-
-template <typename T0,
-	  typename T1>
-void
 prod_cases()
 {
   test_prod_mv<T0, T1>(5, 7);
   test_prod_vm<T0, T1>(5, 7);
-
-  test_prod3_rand<T0, T1>();
-  test_prod4_rand<T0, T1>();
-
-  prod_cases_with_order<T0, T1>();
-  prodt_cases_with_order<T0, T1>();
 }
 
 
-template <typename T0,
-	  typename T1>
-void
-prod_cases_complex_only()
-{
-  test_prodh_rand<T0, T1>(5, 5, 5);
-  test_prodh_rand<T0, T1>(5, 7, 9);
-  test_prodh_rand<T0, T1>(9, 5, 7);
-  test_prodh_rand<T0, T1>(9, 7, 5);
 
-  test_prodj_rand<T0, T1>(5, 5, 5);
-  test_prodj_rand<T0, T1>(5, 7, 9);
-  test_prodj_rand<T0, T1>(9, 5, 7);
-  test_prodj_rand<T0, T1>(9, 7, 5);
-}
-
-
-template <typename T>
-void 
-prod_special_cases()
-{
-  test_mm_prod_subview<T>(5, 7, 3);
-  test_mm_prod_complex_split<T>(5, 7, 3);
-}
-
-
-
 /***********************************************************************
   Main
 ***********************************************************************/
 
-template <> float  Precision_traits<float>::eps = 0.0;
-template <> double Precision_traits<double>::eps = 0.0;
-
 int
 main(int argc, char** argv)
 {
@@ -713,36 +168,16 @@
   Precision_traits<float>::compute_eps();
   Precision_traits<double>::compute_eps();
 
-#if VSIP_IMPL_TEST_LEVEL == 0
 
-  prod_cases<complex<float>, complex<float> >();
-  prod_cases_complex_only<complex<float>, complex<float> >();
-  prod_special_cases<float>();
-
-#else
-
   prod_cases<float,  float>();
 
   prod_cases<complex<float>, complex<float> >();
   prod_cases<float,          complex<float> >();
   prod_cases<complex<float>, float          >();
 
-  prod_cases_complex_only<complex<float>, complex<float> >();
-
-  prod_special_cases<float>();
-
 #if VSIP_IMPL_TEST_DOUBLE
   prod_cases<double, double>();
   prod_cases<float,  double>();
   prod_cases<double, float>();
-
-  prod_special_cases<double>();
 #endif
-
-
-  // Test a large matrix-matrix product (order > 80) to trigger
-  // ATLAS blocking code.  If order < NB, only the cleanup code
-  // gets exercised.
-  test_prod_rand<float, float, row2_type, row2_type, row2_type>(256, 256, 256);
-#endif // VSIP_IMPL_TEST_LEVEL > 0
 }
Index: tests/matvec-prodjh.cpp
===================================================================
--- tests/matvec-prodjh.cpp	(revision 208645)
+++ tests/matvec-prodjh.cpp	(working copy)
@@ -7,8 +7,7 @@
 /** @file    tests/matvec-prod.cpp
     @author  Jules Bergmann
     @date    2005-09-12
-    @brief   VSIPL++ Library: Unit tests for products
-	     (matrix-matrix, matrix-vector, vector-matrix).
+    @brief   VSIPL++ Library: Unit tests for matrix products.
 */
 
 /***********************************************************************
@@ -27,6 +26,7 @@
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/test-precision.hpp>
 
+#include "test-prod.hpp"
 #include "test-random.hpp"
 
 using namespace std;
@@ -35,454 +35,12 @@
 
 
 /***********************************************************************
-  Reference Definitions
-***********************************************************************/
-
-template <typename T0,
-	  typename T1,
-          typename T2,
-          typename Block0,
-          typename Block1,
-          typename Block2>
-void
-check_prod(
-  Matrix<T0, Block0> test,
-  Matrix<T1, Block1> chk,
-  Matrix<T2, Block2> gauge)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Index<2> idx;
-  scalar_type err = maxval(((mag(chk - test)
-			     / Precision_traits<scalar_type>::eps)
-			    / gauge),
-			   idx);
-
-#if VERBOSE
-  cout << "test  =\n" << test;
-  cout << "chk   =\n" << chk;
-  cout << "gauge =\n" << gauge;
-  cout << "err = " << err << endl;
-#endif
-
-  test_assert(err < 10.0);
-}
-
-
-template <typename T0,
-	  typename T1,
-          typename T2,
-          typename Block0,
-          typename Block1,
-          typename Block2>
-void
-check_prod(
-  Vector<T0, Block0> test,
-  Vector<T1, Block1> chk,
-  Vector<T2, Block2> gauge)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Index<1> idx;
-  scalar_type err = maxval(((mag(chk - test)
-			     / Precision_traits<scalar_type>::eps)
-			    / gauge),
-			   idx);
-
-#if VERBOSE
-  cout << "test  =\n" << test;
-  cout << "chk   =\n" << chk;
-  cout << "gauge =\n" << gauge;
-  cout << "err = " << err << endl;
-#endif
-
-  test_assert(err < 10.0);
-}
-
-
-
-/***********************************************************************
   Test Definitions
 ***********************************************************************/
 
-/// Test matrix-matrix, matrix-vector, and vector-matrix products.
-
 template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-test_prod_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  typedef Dense<2, T0, Order0>          block0_type;
-  typedef Dense<2, T1, Order1>          block1_type;
-  typedef Dense<2, return_type, OrderR> blockR_type;
-
-  Matrix<T0, block0_type>          a(m, n);
-  Matrix<T1, block1_type>          b(n, k);
-  Matrix<return_type, blockR_type> res1(m, k);
-  Matrix<return_type, blockR_type> res2(m, k);
-  Matrix<return_type, blockR_type> res3(m, k);
-  Matrix<return_type, blockR_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod(a, b.col(i));
-
-  // Test vector-matrix prod
-  for (index_type i=0; i<m; ++i)
-    res3.row(i) = prod(a.row(i), b);
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]  [" << 
-    n << "x" << k << "]  [" << m << "x" << k << "]  "  << endl;
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-  check_prod( res3, chk, gauge );
-}
-
-
-
-template <typename T>
-void
-test_mm_prod_subview( const length_type m, 
-                      const length_type n, 
-                      const length_type k )
-{
-  typedef typename Matrix<T>::subview_type matrix_subview_type;
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-
-  // non-unit strides - dense rows, non-dense columns
-  {
-    Matrix<T> aa(m, k*2, T());
-    Matrix<T> bb(k, n*3, T());
-    matrix_subview_type a = aa(Domain<2>(
-                                 Domain<1>(0, 1, m), Domain<1>(0, 2, k)));
-    matrix_subview_type b = bb(Domain<2>(
-                                 Domain<1>(0, 1, k), Domain<1>(0, 3, n)));
-    Matrix<T> res(m, n);
-    Matrix<T> chk(m, n);
-    Matrix<scalar_type> gauge(m, n);
-
-    randm(a);
-    randm(b);
-
-    res = prod( a, b );
-    chk = ref::prod( a, b );
-    gauge = ref::prod(mag(a), mag(b));
-
-    for (index_type i=0; i<gauge.size(0); ++i)
-      for (index_type j=0; j<gauge.size(1); ++j)
-        if (!(gauge(i, j) > scalar_type()))
-          gauge(i, j) = scalar_type(1);
-
-    check_prod( res, chk, gauge );
-  }
-
-  // non-unit strides - non-dense rows, dense columns
-  {
-    Matrix<T> aa(m*2, k, T());
-    Matrix<T> bb(k*3, n, T());
-    matrix_subview_type a = aa(Domain<2>( 
-                                 Domain<1>(0, 2, m), Domain<1>(0, 1, k)));
-    matrix_subview_type b = bb(Domain<2>(
-                                 Domain<1>(0, 3, k), Domain<1>(0, 1, n)));
-
-    Matrix<T> res(m, n);
-    Matrix<T> chk(m, n);
-    Matrix<scalar_type> gauge(m, n);
-
-    randm(a);
-    randm(b);
-
-    res = prod( a, b );
-    chk = ref::prod( a, b );
-    gauge = ref::prod(mag(a), mag(b));
-
-    for (index_type i=0; i<gauge.size(0); ++i)
-      for (index_type j=0; j<gauge.size(1); ++j)
-        if (!(gauge(i, j) > scalar_type()))
-          gauge(i, j) = scalar_type(1);
-
-    check_prod( res, chk, gauge );
-  }
-}
-
-
-
-template <typename T>
-void 
-test_mm_prod_complex_split(  const length_type m, 
-                             const length_type n, 
-                             const length_type k )
-{
-  typedef vsip::impl::Fast_block<2, complex<T>,
-    vsip::impl::Layout<2, row2_type,
-    vsip::impl::Stride_unit_dense,
-    vsip::impl::Cmplx_split_fmt> > split_type;
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-  
-  Matrix<complex<T>, split_type> a(m, k);
-  Matrix<complex<T>, split_type> b(k, n);
-  Matrix<complex<T>, split_type> res(m, n, T());
-
-  randm(a);
-  randm(b);
-
-  // call prod()'s underlying interface directly
-  vsip::impl::generic_prod(a, b, res);
-
-  // compute a reference matrix using interleaved (default) layout
-  Matrix<complex<T> > aa(m, k);
-  Matrix<complex<T> > bb(k, n);
-  aa = a;
-  bb = b;
-
-  Matrix<complex<T> > chk(m, n);
-  Matrix<scalar_type> gauge(m, n);
-  chk = ref::prod( aa, bb );
-  gauge = ref::prod( mag(aa), mag(bb) );
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-        gauge(i, j) = scalar_type(1);
-
-  check_prod( res, chk, gauge );
-}
-
-
-
-template <typename T0,
 	  typename T1>
 void
-test_prod_mv(length_type m, length_type n)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n, T0());
-  Vector<T1> b1(n, T1());
-  Vector<T1> b2(m, T1());
-
-  randm(a);
-  randv(b1);
-  randv(b2);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]"  << endl;
-  cout << "a     =\n" << a;
-  cout << "b1    =\n" << b1;
-  cout << "b2    =\n" << b2;
-#endif
-
-  Vector<return_type> r1(m);
-  Vector<return_type> chk1(m);
-  Vector<scalar_type> gauge1(m);
-
-  r1 = prod( a, b1 );
-  chk1 = ref::prod( a, b1 );
-  gauge1 = ref::prod( mag(a), mag(b1) );
-
-  for (index_type i=0; i<gauge1.size(0); ++i)
-    if (!(gauge1(i) > scalar_type()))
-      gauge1(i) = scalar_type(1);
-
-  check_prod( r1, chk1, gauge1 );
-
-  Vector<return_type> r2(n);
-  Vector<return_type> chk2(n);
-  Vector<scalar_type> gauge2(n);
-
-  r2 = prod( trans(a), b2 );
-  chk2 = ref::prod( trans(a), b2 );
-  gauge2 = ref::prod( mag(trans(a)), mag(b2) );
-
-  for (index_type i=0; i<gauge2.size(0); ++i)
-    if (!(gauge2(i) > scalar_type()))
-      gauge2(i) = scalar_type(1);
-
-  check_prod( r2, chk2, gauge2 );
-}
-
-template <typename T0,
-	  typename T1>
-void
-test_prod_vm(length_type m, length_type n)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Vector<T1> a1(m, T1());
-  Vector<T1> a2(n, T1());
-  Matrix<T0> b(m, n, T0());
-
-  randv(a1);
-  randv(a2);
-  randm(b);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]"  << endl;
-  cout << "a1    =\n" << a1;
-  cout << "a2    =\n" << a2;
-  cout << "b     =\n" << b;
-#endif
-
-  Vector<return_type> r1(n);
-  Vector<return_type> chk1(n);
-  Vector<scalar_type> gauge1(n);
-
-  r1 = prod( a1, b );
-  chk1 = ref::prod( a1, b );
-  gauge1 = ref::prod( mag(a1), mag(b) );
-
-  for (index_type i=0; i<gauge1.size(0); ++i)
-    if (!(gauge1(i) > scalar_type()))
-      gauge1(i) = scalar_type(1);
-
-  check_prod( r1, chk1, gauge1 );
-
-  Vector<return_type> r2(m);
-  Vector<return_type> chk2(m);
-  Vector<scalar_type> gauge2(m);
-
-  r2 = prod( a2, trans(b) );
-  chk2 = ref::prod( a2, trans(b) );
-  gauge2 = ref::prod( mag(a2), mag(trans(b)) );
-
-  for (index_type i=0; i<gauge2.size(0); ++i)
-    if (!(gauge2(i) > scalar_type()))
-      gauge2(i) = scalar_type(1);
-
-  check_prod( r2, chk2, gauge2 );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prod3_rand()
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-  const length_type m = 3;
-  const length_type n = 3;
-  const length_type k = 3;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> res2(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod3(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod3(a, b.col(i));
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-  cout << "chk   =\n" << chk;
-  cout << "res1  =\n" << res1;
-  cout << "res2  =\n" << res2;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prod4_rand()
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-  const length_type m = 4;
-  const length_type n = 4;
-  const length_type k = 4;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> res2(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod4(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod4(a, b.col(i));
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
 test_prodh_rand(length_type m, length_type n, length_type k)
 {
   typedef typename Promotion<T0, T1>::type return_type;
@@ -557,123 +115,8 @@
 
 
 template <typename T0,
-          typename T1,
-          typename OrderR,
-          typename Order0,
-          typename Order1>
-void
-test_prodt_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  typedef Dense<2, T0, Order0>          block0_type;
-  typedef Dense<2, T1, Order1>          block1_type;
-  typedef Dense<2, return_type, OrderR> blockR_type;
-
-  Matrix<T0, block0_type> a(m, n);
-  Matrix<T1, block1_type> b(k, n);
-  Matrix<return_type, blockR_type> res1(m, k);
-  Matrix<return_type, blockR_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for transpose
-  res1 = prodt(a, b);
-
-  chk   = ref::prod(a, trans(b));
-  gauge = ref::prod(mag(a), mag(trans(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-prod_types_with_order()
-{
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(5, 7, 9);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(9, 5, 7);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(9, 7, 5);
-}
-
-
-template <typename T0,
 	  typename T1>
 void
-prod_cases_with_order()
-{
-  prod_types_with_order<T0, T1, row2_type, row2_type, row2_type>();
-  prod_types_with_order<T0, T1, row2_type, col2_type, row2_type>();
-  prod_types_with_order<T0, T1, row2_type, row2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, col2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, row2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, col2_type, row2_type>();
-}
-
-
-template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-prodt_types_with_order()
-{
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 7, 9);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(9, 5, 7);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(9, 7, 5);
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prodt_cases_with_order()
-{
-  prodt_types_with_order<T0, T1, row2_type, row2_type, row2_type>();
-  prodt_types_with_order<T0, T1, row2_type, row2_type, col2_type>();
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prod_cases()
-{
-  test_prod_mv<T0, T1>(5, 7);
-  test_prod_vm<T0, T1>(5, 7);
-
-  test_prod3_rand<T0, T1>();
-  test_prod4_rand<T0, T1>();
-
-  prod_cases_with_order<T0, T1>();
-  prodt_cases_with_order<T0, T1>();
-}
-
-
-template <typename T0,
-	  typename T1>
-void
 prod_cases_complex_only()
 {
   test_prodh_rand<T0, T1>(5, 5, 5);
@@ -688,23 +131,11 @@
 }
 
 
-template <typename T>
-void 
-prod_special_cases()
-{
-  test_mm_prod_subview<T>(5, 7, 3);
-  test_mm_prod_complex_split<T>(5, 7, 3);
-}
 
-
-
 /***********************************************************************
   Main
 ***********************************************************************/
 
-template <> float  Precision_traits<float>::eps = 0.0;
-template <> double Precision_traits<double>::eps = 0.0;
-
 int
 main(int argc, char** argv)
 {
@@ -713,36 +144,5 @@
   Precision_traits<float>::compute_eps();
   Precision_traits<double>::compute_eps();
 
-#if VSIP_IMPL_TEST_LEVEL == 0
-
-  prod_cases<complex<float>, complex<float> >();
   prod_cases_complex_only<complex<float>, complex<float> >();
-  prod_special_cases<float>();
-
-#else
-
-  prod_cases<float,  float>();
-
-  prod_cases<complex<float>, complex<float> >();
-  prod_cases<float,          complex<float> >();
-  prod_cases<complex<float>, float          >();
-
-  prod_cases_complex_only<complex<float>, complex<float> >();
-
-  prod_special_cases<float>();
-
-#if VSIP_IMPL_TEST_DOUBLE
-  prod_cases<double, double>();
-  prod_cases<float,  double>();
-  prod_cases<double, float>();
-
-  prod_special_cases<double>();
-#endif
-
-
-  // Test a large matrix-matrix product (order > 80) to trigger
-  // ATLAS blocking code.  If order < NB, only the cleanup code
-  // gets exercised.
-  test_prod_rand<float, float, row2_type, row2_type, row2_type>(256, 256, 256);
-#endif // VSIP_IMPL_TEST_LEVEL > 0
 }
Index: tests/matvec-prod-special.cpp
===================================================================
--- tests/matvec-prod-special.cpp	(revision 208645)
+++ tests/matvec-prod-special.cpp	(working copy)
@@ -4,11 +4,10 @@
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    tests/matvec-prod.cpp
+/** @file    tests/matvec-prod-special.cpp
     @author  Jules Bergmann
     @date    2005-09-12
-    @brief   VSIPL++ Library: Unit tests for products
-	     (matrix-matrix, matrix-vector, vector-matrix).
+    @brief   VSIPL++ Library: Unit tests for matrix products.
 */
 
 /***********************************************************************
@@ -27,6 +26,7 @@
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/test-precision.hpp>
 
+#include "test-prod.hpp"
 #include "test-random.hpp"
 
 using namespace std;
@@ -35,139 +35,11 @@
 
 
 /***********************************************************************
-  Reference Definitions
-***********************************************************************/
-
-template <typename T0,
-	  typename T1,
-          typename T2,
-          typename Block0,
-          typename Block1,
-          typename Block2>
-void
-check_prod(
-  Matrix<T0, Block0> test,
-  Matrix<T1, Block1> chk,
-  Matrix<T2, Block2> gauge)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Index<2> idx;
-  scalar_type err = maxval(((mag(chk - test)
-			     / Precision_traits<scalar_type>::eps)
-			    / gauge),
-			   idx);
-
-#if VERBOSE
-  cout << "test  =\n" << test;
-  cout << "chk   =\n" << chk;
-  cout << "gauge =\n" << gauge;
-  cout << "err = " << err << endl;
-#endif
-
-  test_assert(err < 10.0);
-}
-
-
-template <typename T0,
-	  typename T1,
-          typename T2,
-          typename Block0,
-          typename Block1,
-          typename Block2>
-void
-check_prod(
-  Vector<T0, Block0> test,
-  Vector<T1, Block1> chk,
-  Vector<T2, Block2> gauge)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Index<1> idx;
-  scalar_type err = maxval(((mag(chk - test)
-			     / Precision_traits<scalar_type>::eps)
-			    / gauge),
-			   idx);
-
-#if VERBOSE
-  cout << "test  =\n" << test;
-  cout << "chk   =\n" << chk;
-  cout << "gauge =\n" << gauge;
-  cout << "err = " << err << endl;
-#endif
-
-  test_assert(err < 10.0);
-}
-
-
-
-/***********************************************************************
   Test Definitions
 ***********************************************************************/
 
-/// Test matrix-matrix, matrix-vector, and vector-matrix products.
+/// Test matrix-matrix products using sub-views
 
-template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-test_prod_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  typedef Dense<2, T0, Order0>          block0_type;
-  typedef Dense<2, T1, Order1>          block1_type;
-  typedef Dense<2, return_type, OrderR> blockR_type;
-
-  Matrix<T0, block0_type>          a(m, n);
-  Matrix<T1, block1_type>          b(n, k);
-  Matrix<return_type, blockR_type> res1(m, k);
-  Matrix<return_type, blockR_type> res2(m, k);
-  Matrix<return_type, blockR_type> res3(m, k);
-  Matrix<return_type, blockR_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod(a, b.col(i));
-
-  // Test vector-matrix prod
-  for (index_type i=0; i<m; ++i)
-    res3.row(i) = prod(a.row(i), b);
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]  [" << 
-    n << "x" << k << "]  [" << m << "x" << k << "]  "  << endl;
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-  check_prod( res3, chk, gauge );
-}
-
-
-
 template <typename T>
 void
 test_mm_prod_subview( const length_type m, 
@@ -234,6 +106,7 @@
 }
 
 
+/// Test matrix-matrix products using split-complex format
 
 template <typename T>
 void 
@@ -278,416 +151,6 @@
 
 
 
-template <typename T0,
-	  typename T1>
-void
-test_prod_mv(length_type m, length_type n)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n, T0());
-  Vector<T1> b1(n, T1());
-  Vector<T1> b2(m, T1());
-
-  randm(a);
-  randv(b1);
-  randv(b2);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]"  << endl;
-  cout << "a     =\n" << a;
-  cout << "b1    =\n" << b1;
-  cout << "b2    =\n" << b2;
-#endif
-
-  Vector<return_type> r1(m);
-  Vector<return_type> chk1(m);
-  Vector<scalar_type> gauge1(m);
-
-  r1 = prod( a, b1 );
-  chk1 = ref::prod( a, b1 );
-  gauge1 = ref::prod( mag(a), mag(b1) );
-
-  for (index_type i=0; i<gauge1.size(0); ++i)
-    if (!(gauge1(i) > scalar_type()))
-      gauge1(i) = scalar_type(1);
-
-  check_prod( r1, chk1, gauge1 );
-
-  Vector<return_type> r2(n);
-  Vector<return_type> chk2(n);
-  Vector<scalar_type> gauge2(n);
-
-  r2 = prod( trans(a), b2 );
-  chk2 = ref::prod( trans(a), b2 );
-  gauge2 = ref::prod( mag(trans(a)), mag(b2) );
-
-  for (index_type i=0; i<gauge2.size(0); ++i)
-    if (!(gauge2(i) > scalar_type()))
-      gauge2(i) = scalar_type(1);
-
-  check_prod( r2, chk2, gauge2 );
-}
-
-template <typename T0,
-	  typename T1>
-void
-test_prod_vm(length_type m, length_type n)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Vector<T1> a1(m, T1());
-  Vector<T1> a2(n, T1());
-  Matrix<T0> b(m, n, T0());
-
-  randv(a1);
-  randv(a2);
-  randm(b);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]"  << endl;
-  cout << "a1    =\n" << a1;
-  cout << "a2    =\n" << a2;
-  cout << "b     =\n" << b;
-#endif
-
-  Vector<return_type> r1(n);
-  Vector<return_type> chk1(n);
-  Vector<scalar_type> gauge1(n);
-
-  r1 = prod( a1, b );
-  chk1 = ref::prod( a1, b );
-  gauge1 = ref::prod( mag(a1), mag(b) );
-
-  for (index_type i=0; i<gauge1.size(0); ++i)
-    if (!(gauge1(i) > scalar_type()))
-      gauge1(i) = scalar_type(1);
-
-  check_prod( r1, chk1, gauge1 );
-
-  Vector<return_type> r2(m);
-  Vector<return_type> chk2(m);
-  Vector<scalar_type> gauge2(m);
-
-  r2 = prod( a2, trans(b) );
-  chk2 = ref::prod( a2, trans(b) );
-  gauge2 = ref::prod( mag(a2), mag(trans(b)) );
-
-  for (index_type i=0; i<gauge2.size(0); ++i)
-    if (!(gauge2(i) > scalar_type()))
-      gauge2(i) = scalar_type(1);
-
-  check_prod( r2, chk2, gauge2 );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prod3_rand()
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-  const length_type m = 3;
-  const length_type n = 3;
-  const length_type k = 3;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> res2(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod3(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod3(a, b.col(i));
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-  cout << "chk   =\n" << chk;
-  cout << "res1  =\n" << res1;
-  cout << "res2  =\n" << res2;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prod4_rand()
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-  const length_type m = 4;
-  const length_type n = 4;
-  const length_type k = 4;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> res2(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod4(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod4(a, b.col(i));
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prodh_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(k, n);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for hermitian
-  res1   = prod(a, herm(b));
-
-  chk   = ref::prod(a, herm(b));
-  gauge = ref::prod(mag(a), mag(herm(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prodj_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for hermitian
-  res1   = prod(a, conj(b));
-
-  chk   = ref::prod(a, conj(b));
-  gauge = ref::prod(mag(a), mag(conj(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-          typename T1,
-          typename OrderR,
-          typename Order0,
-          typename Order1>
-void
-test_prodt_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  typedef Dense<2, T0, Order0>          block0_type;
-  typedef Dense<2, T1, Order1>          block1_type;
-  typedef Dense<2, return_type, OrderR> blockR_type;
-
-  Matrix<T0, block0_type> a(m, n);
-  Matrix<T1, block1_type> b(k, n);
-  Matrix<return_type, blockR_type> res1(m, k);
-  Matrix<return_type, blockR_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for transpose
-  res1 = prodt(a, b);
-
-  chk   = ref::prod(a, trans(b));
-  gauge = ref::prod(mag(a), mag(trans(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-prod_types_with_order()
-{
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(5, 7, 9);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(9, 5, 7);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(9, 7, 5);
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prod_cases_with_order()
-{
-  prod_types_with_order<T0, T1, row2_type, row2_type, row2_type>();
-  prod_types_with_order<T0, T1, row2_type, col2_type, row2_type>();
-  prod_types_with_order<T0, T1, row2_type, row2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, col2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, row2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, col2_type, row2_type>();
-}
-
-
-template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-prodt_types_with_order()
-{
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 7, 9);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(9, 5, 7);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(9, 7, 5);
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prodt_cases_with_order()
-{
-  prodt_types_with_order<T0, T1, row2_type, row2_type, row2_type>();
-  prodt_types_with_order<T0, T1, row2_type, row2_type, col2_type>();
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prod_cases()
-{
-  test_prod_mv<T0, T1>(5, 7);
-  test_prod_vm<T0, T1>(5, 7);
-
-  test_prod3_rand<T0, T1>();
-  test_prod4_rand<T0, T1>();
-
-  prod_cases_with_order<T0, T1>();
-  prodt_cases_with_order<T0, T1>();
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prod_cases_complex_only()
-{
-  test_prodh_rand<T0, T1>(5, 5, 5);
-  test_prodh_rand<T0, T1>(5, 7, 9);
-  test_prodh_rand<T0, T1>(9, 5, 7);
-  test_prodh_rand<T0, T1>(9, 7, 5);
-
-  test_prodj_rand<T0, T1>(5, 5, 5);
-  test_prodj_rand<T0, T1>(5, 7, 9);
-  test_prodj_rand<T0, T1>(9, 5, 7);
-  test_prodj_rand<T0, T1>(9, 7, 5);
-}
-
-
 template <typename T>
 void 
 prod_special_cases()
@@ -702,9 +165,6 @@
   Main
 ***********************************************************************/
 
-template <> float  Precision_traits<float>::eps = 0.0;
-template <> double Precision_traits<double>::eps = 0.0;
-
 int
 main(int argc, char** argv)
 {
@@ -713,36 +173,9 @@
   Precision_traits<float>::compute_eps();
   Precision_traits<double>::compute_eps();
 
-#if VSIP_IMPL_TEST_LEVEL == 0
-
-  prod_cases<complex<float>, complex<float> >();
-  prod_cases_complex_only<complex<float>, complex<float> >();
   prod_special_cases<float>();
 
-#else
-
-  prod_cases<float,  float>();
-
-  prod_cases<complex<float>, complex<float> >();
-  prod_cases<float,          complex<float> >();
-  prod_cases<complex<float>, float          >();
-
-  prod_cases_complex_only<complex<float>, complex<float> >();
-
-  prod_special_cases<float>();
-
 #if VSIP_IMPL_TEST_DOUBLE
-  prod_cases<double, double>();
-  prod_cases<float,  double>();
-  prod_cases<double, float>();
-
   prod_special_cases<double>();
 #endif
-
-
-  // Test a large matrix-matrix product (order > 80) to trigger
-  // ATLAS blocking code.  If order < NB, only the cleanup code
-  // gets exercised.
-  test_prod_rand<float, float, row2_type, row2_type, row2_type>(256, 256, 256);
-#endif // VSIP_IMPL_TEST_LEVEL > 0
 }
Index: tests/matvec-prodt.cpp
===================================================================
--- tests/matvec-prodt.cpp	(revision 208645)
+++ tests/matvec-prodt.cpp	(working copy)
@@ -4,11 +4,10 @@
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    tests/matvec-prod.cpp
+/** @file    tests/matvec-prodt.cpp
     @author  Jules Bergmann
     @date    2005-09-12
-    @brief   VSIPL++ Library: Unit tests for products
-	     (matrix-matrix, matrix-vector, vector-matrix).
+    @brief   VSIPL++ Library: Unit tests for matrix products.
 */
 
 /***********************************************************************
@@ -27,6 +26,7 @@
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/test-precision.hpp>
 
+#include "test-prod.hpp"
 #include "test-random.hpp"
 
 using namespace std;
@@ -35,528 +35,10 @@
 
 
 /***********************************************************************
-  Reference Definitions
-***********************************************************************/
-
-template <typename T0,
-	  typename T1,
-          typename T2,
-          typename Block0,
-          typename Block1,
-          typename Block2>
-void
-check_prod(
-  Matrix<T0, Block0> test,
-  Matrix<T1, Block1> chk,
-  Matrix<T2, Block2> gauge)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Index<2> idx;
-  scalar_type err = maxval(((mag(chk - test)
-			     / Precision_traits<scalar_type>::eps)
-			    / gauge),
-			   idx);
-
-#if VERBOSE
-  cout << "test  =\n" << test;
-  cout << "chk   =\n" << chk;
-  cout << "gauge =\n" << gauge;
-  cout << "err = " << err << endl;
-#endif
-
-  test_assert(err < 10.0);
-}
-
-
-template <typename T0,
-	  typename T1,
-          typename T2,
-          typename Block0,
-          typename Block1,
-          typename Block2>
-void
-check_prod(
-  Vector<T0, Block0> test,
-  Vector<T1, Block1> chk,
-  Vector<T2, Block2> gauge)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Index<1> idx;
-  scalar_type err = maxval(((mag(chk - test)
-			     / Precision_traits<scalar_type>::eps)
-			    / gauge),
-			   idx);
-
-#if VERBOSE
-  cout << "test  =\n" << test;
-  cout << "chk   =\n" << chk;
-  cout << "gauge =\n" << gauge;
-  cout << "err = " << err << endl;
-#endif
-
-  test_assert(err < 10.0);
-}
-
-
-
-/***********************************************************************
   Test Definitions
 ***********************************************************************/
 
-/// Test matrix-matrix, matrix-vector, and vector-matrix products.
-
 template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-test_prod_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  typedef Dense<2, T0, Order0>          block0_type;
-  typedef Dense<2, T1, Order1>          block1_type;
-  typedef Dense<2, return_type, OrderR> blockR_type;
-
-  Matrix<T0, block0_type>          a(m, n);
-  Matrix<T1, block1_type>          b(n, k);
-  Matrix<return_type, blockR_type> res1(m, k);
-  Matrix<return_type, blockR_type> res2(m, k);
-  Matrix<return_type, blockR_type> res3(m, k);
-  Matrix<return_type, blockR_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod(a, b.col(i));
-
-  // Test vector-matrix prod
-  for (index_type i=0; i<m; ++i)
-    res3.row(i) = prod(a.row(i), b);
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]  [" << 
-    n << "x" << k << "]  [" << m << "x" << k << "]  "  << endl;
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-  check_prod( res3, chk, gauge );
-}
-
-
-
-template <typename T>
-void
-test_mm_prod_subview( const length_type m, 
-                      const length_type n, 
-                      const length_type k )
-{
-  typedef typename Matrix<T>::subview_type matrix_subview_type;
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-
-  // non-unit strides - dense rows, non-dense columns
-  {
-    Matrix<T> aa(m, k*2, T());
-    Matrix<T> bb(k, n*3, T());
-    matrix_subview_type a = aa(Domain<2>(
-                                 Domain<1>(0, 1, m), Domain<1>(0, 2, k)));
-    matrix_subview_type b = bb(Domain<2>(
-                                 Domain<1>(0, 1, k), Domain<1>(0, 3, n)));
-    Matrix<T> res(m, n);
-    Matrix<T> chk(m, n);
-    Matrix<scalar_type> gauge(m, n);
-
-    randm(a);
-    randm(b);
-
-    res = prod( a, b );
-    chk = ref::prod( a, b );
-    gauge = ref::prod(mag(a), mag(b));
-
-    for (index_type i=0; i<gauge.size(0); ++i)
-      for (index_type j=0; j<gauge.size(1); ++j)
-        if (!(gauge(i, j) > scalar_type()))
-          gauge(i, j) = scalar_type(1);
-
-    check_prod( res, chk, gauge );
-  }
-
-  // non-unit strides - non-dense rows, dense columns
-  {
-    Matrix<T> aa(m*2, k, T());
-    Matrix<T> bb(k*3, n, T());
-    matrix_subview_type a = aa(Domain<2>( 
-                                 Domain<1>(0, 2, m), Domain<1>(0, 1, k)));
-    matrix_subview_type b = bb(Domain<2>(
-                                 Domain<1>(0, 3, k), Domain<1>(0, 1, n)));
-
-    Matrix<T> res(m, n);
-    Matrix<T> chk(m, n);
-    Matrix<scalar_type> gauge(m, n);
-
-    randm(a);
-    randm(b);
-
-    res = prod( a, b );
-    chk = ref::prod( a, b );
-    gauge = ref::prod(mag(a), mag(b));
-
-    for (index_type i=0; i<gauge.size(0); ++i)
-      for (index_type j=0; j<gauge.size(1); ++j)
-        if (!(gauge(i, j) > scalar_type()))
-          gauge(i, j) = scalar_type(1);
-
-    check_prod( res, chk, gauge );
-  }
-}
-
-
-
-template <typename T>
-void 
-test_mm_prod_complex_split(  const length_type m, 
-                             const length_type n, 
-                             const length_type k )
-{
-  typedef vsip::impl::Fast_block<2, complex<T>,
-    vsip::impl::Layout<2, row2_type,
-    vsip::impl::Stride_unit_dense,
-    vsip::impl::Cmplx_split_fmt> > split_type;
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-  
-  Matrix<complex<T>, split_type> a(m, k);
-  Matrix<complex<T>, split_type> b(k, n);
-  Matrix<complex<T>, split_type> res(m, n, T());
-
-  randm(a);
-  randm(b);
-
-  // call prod()'s underlying interface directly
-  vsip::impl::generic_prod(a, b, res);
-
-  // compute a reference matrix using interleaved (default) layout
-  Matrix<complex<T> > aa(m, k);
-  Matrix<complex<T> > bb(k, n);
-  aa = a;
-  bb = b;
-
-  Matrix<complex<T> > chk(m, n);
-  Matrix<scalar_type> gauge(m, n);
-  chk = ref::prod( aa, bb );
-  gauge = ref::prod( mag(aa), mag(bb) );
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-        gauge(i, j) = scalar_type(1);
-
-  check_prod( res, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prod_mv(length_type m, length_type n)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n, T0());
-  Vector<T1> b1(n, T1());
-  Vector<T1> b2(m, T1());
-
-  randm(a);
-  randv(b1);
-  randv(b2);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]"  << endl;
-  cout << "a     =\n" << a;
-  cout << "b1    =\n" << b1;
-  cout << "b2    =\n" << b2;
-#endif
-
-  Vector<return_type> r1(m);
-  Vector<return_type> chk1(m);
-  Vector<scalar_type> gauge1(m);
-
-  r1 = prod( a, b1 );
-  chk1 = ref::prod( a, b1 );
-  gauge1 = ref::prod( mag(a), mag(b1) );
-
-  for (index_type i=0; i<gauge1.size(0); ++i)
-    if (!(gauge1(i) > scalar_type()))
-      gauge1(i) = scalar_type(1);
-
-  check_prod( r1, chk1, gauge1 );
-
-  Vector<return_type> r2(n);
-  Vector<return_type> chk2(n);
-  Vector<scalar_type> gauge2(n);
-
-  r2 = prod( trans(a), b2 );
-  chk2 = ref::prod( trans(a), b2 );
-  gauge2 = ref::prod( mag(trans(a)), mag(b2) );
-
-  for (index_type i=0; i<gauge2.size(0); ++i)
-    if (!(gauge2(i) > scalar_type()))
-      gauge2(i) = scalar_type(1);
-
-  check_prod( r2, chk2, gauge2 );
-}
-
-template <typename T0,
-	  typename T1>
-void
-test_prod_vm(length_type m, length_type n)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Vector<T1> a1(m, T1());
-  Vector<T1> a2(n, T1());
-  Matrix<T0> b(m, n, T0());
-
-  randv(a1);
-  randv(a2);
-  randm(b);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]"  << endl;
-  cout << "a1    =\n" << a1;
-  cout << "a2    =\n" << a2;
-  cout << "b     =\n" << b;
-#endif
-
-  Vector<return_type> r1(n);
-  Vector<return_type> chk1(n);
-  Vector<scalar_type> gauge1(n);
-
-  r1 = prod( a1, b );
-  chk1 = ref::prod( a1, b );
-  gauge1 = ref::prod( mag(a1), mag(b) );
-
-  for (index_type i=0; i<gauge1.size(0); ++i)
-    if (!(gauge1(i) > scalar_type()))
-      gauge1(i) = scalar_type(1);
-
-  check_prod( r1, chk1, gauge1 );
-
-  Vector<return_type> r2(m);
-  Vector<return_type> chk2(m);
-  Vector<scalar_type> gauge2(m);
-
-  r2 = prod( a2, trans(b) );
-  chk2 = ref::prod( a2, trans(b) );
-  gauge2 = ref::prod( mag(a2), mag(trans(b)) );
-
-  for (index_type i=0; i<gauge2.size(0); ++i)
-    if (!(gauge2(i) > scalar_type()))
-      gauge2(i) = scalar_type(1);
-
-  check_prod( r2, chk2, gauge2 );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prod3_rand()
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-  const length_type m = 3;
-  const length_type n = 3;
-  const length_type k = 3;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> res2(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod3(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod3(a, b.col(i));
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-  cout << "chk   =\n" << chk;
-  cout << "res1  =\n" << res1;
-  cout << "res2  =\n" << res2;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prod4_rand()
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-  const length_type m = 4;
-  const length_type n = 4;
-  const length_type k = 4;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> res2(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod4(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod4(a, b.col(i));
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prodh_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(k, n);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for hermitian
-  res1   = prod(a, herm(b));
-
-  chk   = ref::prod(a, herm(b));
-  gauge = ref::prod(mag(a), mag(herm(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prodj_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for hermitian
-  res1   = prod(a, conj(b));
-
-  chk   = ref::prod(a, conj(b));
-  gauge = ref::prod(mag(a), mag(conj(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
           typename T1,
           typename OrderR,
           typename Order0,
@@ -607,35 +89,6 @@
 	  typename Order0,
 	  typename Order1>
 void
-prod_types_with_order()
-{
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(5, 7, 9);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(9, 5, 7);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(9, 7, 5);
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prod_cases_with_order()
-{
-  prod_types_with_order<T0, T1, row2_type, row2_type, row2_type>();
-  prod_types_with_order<T0, T1, row2_type, col2_type, row2_type>();
-  prod_types_with_order<T0, T1, row2_type, row2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, col2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, row2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, col2_type, row2_type>();
-}
-
-
-template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
 prodt_types_with_order()
 {
   test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
@@ -655,56 +108,11 @@
 }
 
 
-template <typename T0,
-	  typename T1>
-void
-prod_cases()
-{
-  test_prod_mv<T0, T1>(5, 7);
-  test_prod_vm<T0, T1>(5, 7);
 
-  test_prod3_rand<T0, T1>();
-  test_prod4_rand<T0, T1>();
-
-  prod_cases_with_order<T0, T1>();
-  prodt_cases_with_order<T0, T1>();
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prod_cases_complex_only()
-{
-  test_prodh_rand<T0, T1>(5, 5, 5);
-  test_prodh_rand<T0, T1>(5, 7, 9);
-  test_prodh_rand<T0, T1>(9, 5, 7);
-  test_prodh_rand<T0, T1>(9, 7, 5);
-
-  test_prodj_rand<T0, T1>(5, 5, 5);
-  test_prodj_rand<T0, T1>(5, 7, 9);
-  test_prodj_rand<T0, T1>(9, 5, 7);
-  test_prodj_rand<T0, T1>(9, 7, 5);
-}
-
-
-template <typename T>
-void 
-prod_special_cases()
-{
-  test_mm_prod_subview<T>(5, 7, 3);
-  test_mm_prod_complex_split<T>(5, 7, 3);
-}
-
-
-
 /***********************************************************************
   Main
 ***********************************************************************/
 
-template <> float  Precision_traits<float>::eps = 0.0;
-template <> double Precision_traits<double>::eps = 0.0;
-
 int
 main(int argc, char** argv)
 {
@@ -713,36 +121,16 @@
   Precision_traits<float>::compute_eps();
   Precision_traits<double>::compute_eps();
 
-#if VSIP_IMPL_TEST_LEVEL == 0
 
-  prod_cases<complex<float>, complex<float> >();
-  prod_cases_complex_only<complex<float>, complex<float> >();
-  prod_special_cases<float>();
+  prodt_cases_with_order<float,  float>();
 
-#else
+  prodt_cases_with_order<complex<float>, complex<float> >();
+  prodt_cases_with_order<float,          complex<float> >();
+  prodt_cases_with_order<complex<float>, float          >();
 
-  prod_cases<float,  float>();
-
-  prod_cases<complex<float>, complex<float> >();
-  prod_cases<float,          complex<float> >();
-  prod_cases<complex<float>, float          >();
-
-  prod_cases_complex_only<complex<float>, complex<float> >();
-
-  prod_special_cases<float>();
-
 #if VSIP_IMPL_TEST_DOUBLE
-  prod_cases<double, double>();
-  prod_cases<float,  double>();
-  prod_cases<double, float>();
-
-  prod_special_cases<double>();
+  prodt_cases_with_order<double, double>();
+  prodt_cases_with_order<float,  double>();
+  prodt_cases_with_order<double, float>();
 #endif
-
-
-  // Test a large matrix-matrix product (order > 80) to trigger
-  // ATLAS blocking code.  If order < NB, only the cleanup code
-  // gets exercised.
-  test_prod_rand<float, float, row2_type, row2_type, row2_type>(256, 256, 256);
-#endif // VSIP_IMPL_TEST_LEVEL > 0
 }
Index: tests/matvec-prod34.cpp
===================================================================
--- tests/matvec-prod34.cpp	(revision 208645)
+++ tests/matvec-prod34.cpp	(working copy)
@@ -4,11 +4,10 @@
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    tests/matvec-prod.cpp
+/** @file    tests/matvec-prod34.cpp
     @author  Jules Bergmann
     @date    2005-09-12
-    @brief   VSIPL++ Library: Unit tests for products
-	     (matrix-matrix, matrix-vector, vector-matrix).
+    @brief   VSIPL++ Library: Unit tests for matrix products.
 */
 
 /***********************************************************************
@@ -27,6 +26,7 @@
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/test-precision.hpp>
 
+#include "test-prod.hpp"
 #include "test-random.hpp"
 
 using namespace std;
@@ -35,358 +35,12 @@
 
 
 /***********************************************************************
-  Reference Definitions
-***********************************************************************/
-
-template <typename T0,
-	  typename T1,
-          typename T2,
-          typename Block0,
-          typename Block1,
-          typename Block2>
-void
-check_prod(
-  Matrix<T0, Block0> test,
-  Matrix<T1, Block1> chk,
-  Matrix<T2, Block2> gauge)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Index<2> idx;
-  scalar_type err = maxval(((mag(chk - test)
-			     / Precision_traits<scalar_type>::eps)
-			    / gauge),
-			   idx);
-
-#if VERBOSE
-  cout << "test  =\n" << test;
-  cout << "chk   =\n" << chk;
-  cout << "gauge =\n" << gauge;
-  cout << "err = " << err << endl;
-#endif
-
-  test_assert(err < 10.0);
-}
-
-
-template <typename T0,
-	  typename T1,
-          typename T2,
-          typename Block0,
-          typename Block1,
-          typename Block2>
-void
-check_prod(
-  Vector<T0, Block0> test,
-  Vector<T1, Block1> chk,
-  Vector<T2, Block2> gauge)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Index<1> idx;
-  scalar_type err = maxval(((mag(chk - test)
-			     / Precision_traits<scalar_type>::eps)
-			    / gauge),
-			   idx);
-
-#if VERBOSE
-  cout << "test  =\n" << test;
-  cout << "chk   =\n" << chk;
-  cout << "gauge =\n" << gauge;
-  cout << "err = " << err << endl;
-#endif
-
-  test_assert(err < 10.0);
-}
-
-
-
-/***********************************************************************
   Test Definitions
 ***********************************************************************/
 
-/// Test matrix-matrix, matrix-vector, and vector-matrix products.
-
 template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-test_prod_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  typedef Dense<2, T0, Order0>          block0_type;
-  typedef Dense<2, T1, Order1>          block1_type;
-  typedef Dense<2, return_type, OrderR> blockR_type;
-
-  Matrix<T0, block0_type>          a(m, n);
-  Matrix<T1, block1_type>          b(n, k);
-  Matrix<return_type, blockR_type> res1(m, k);
-  Matrix<return_type, blockR_type> res2(m, k);
-  Matrix<return_type, blockR_type> res3(m, k);
-  Matrix<return_type, blockR_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod(a, b.col(i));
-
-  // Test vector-matrix prod
-  for (index_type i=0; i<m; ++i)
-    res3.row(i) = prod(a.row(i), b);
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]  [" << 
-    n << "x" << k << "]  [" << m << "x" << k << "]  "  << endl;
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-  check_prod( res3, chk, gauge );
-}
-
-
-
-template <typename T>
-void
-test_mm_prod_subview( const length_type m, 
-                      const length_type n, 
-                      const length_type k )
-{
-  typedef typename Matrix<T>::subview_type matrix_subview_type;
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-
-  // non-unit strides - dense rows, non-dense columns
-  {
-    Matrix<T> aa(m, k*2, T());
-    Matrix<T> bb(k, n*3, T());
-    matrix_subview_type a = aa(Domain<2>(
-                                 Domain<1>(0, 1, m), Domain<1>(0, 2, k)));
-    matrix_subview_type b = bb(Domain<2>(
-                                 Domain<1>(0, 1, k), Domain<1>(0, 3, n)));
-    Matrix<T> res(m, n);
-    Matrix<T> chk(m, n);
-    Matrix<scalar_type> gauge(m, n);
-
-    randm(a);
-    randm(b);
-
-    res = prod( a, b );
-    chk = ref::prod( a, b );
-    gauge = ref::prod(mag(a), mag(b));
-
-    for (index_type i=0; i<gauge.size(0); ++i)
-      for (index_type j=0; j<gauge.size(1); ++j)
-        if (!(gauge(i, j) > scalar_type()))
-          gauge(i, j) = scalar_type(1);
-
-    check_prod( res, chk, gauge );
-  }
-
-  // non-unit strides - non-dense rows, dense columns
-  {
-    Matrix<T> aa(m*2, k, T());
-    Matrix<T> bb(k*3, n, T());
-    matrix_subview_type a = aa(Domain<2>( 
-                                 Domain<1>(0, 2, m), Domain<1>(0, 1, k)));
-    matrix_subview_type b = bb(Domain<2>(
-                                 Domain<1>(0, 3, k), Domain<1>(0, 1, n)));
-
-    Matrix<T> res(m, n);
-    Matrix<T> chk(m, n);
-    Matrix<scalar_type> gauge(m, n);
-
-    randm(a);
-    randm(b);
-
-    res = prod( a, b );
-    chk = ref::prod( a, b );
-    gauge = ref::prod(mag(a), mag(b));
-
-    for (index_type i=0; i<gauge.size(0); ++i)
-      for (index_type j=0; j<gauge.size(1); ++j)
-        if (!(gauge(i, j) > scalar_type()))
-          gauge(i, j) = scalar_type(1);
-
-    check_prod( res, chk, gauge );
-  }
-}
-
-
-
-template <typename T>
-void 
-test_mm_prod_complex_split(  const length_type m, 
-                             const length_type n, 
-                             const length_type k )
-{
-  typedef vsip::impl::Fast_block<2, complex<T>,
-    vsip::impl::Layout<2, row2_type,
-    vsip::impl::Stride_unit_dense,
-    vsip::impl::Cmplx_split_fmt> > split_type;
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-  
-  Matrix<complex<T>, split_type> a(m, k);
-  Matrix<complex<T>, split_type> b(k, n);
-  Matrix<complex<T>, split_type> res(m, n, T());
-
-  randm(a);
-  randm(b);
-
-  // call prod()'s underlying interface directly
-  vsip::impl::generic_prod(a, b, res);
-
-  // compute a reference matrix using interleaved (default) layout
-  Matrix<complex<T> > aa(m, k);
-  Matrix<complex<T> > bb(k, n);
-  aa = a;
-  bb = b;
-
-  Matrix<complex<T> > chk(m, n);
-  Matrix<scalar_type> gauge(m, n);
-  chk = ref::prod( aa, bb );
-  gauge = ref::prod( mag(aa), mag(bb) );
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-        gauge(i, j) = scalar_type(1);
-
-  check_prod( res, chk, gauge );
-}
-
-
-
-template <typename T0,
 	  typename T1>
 void
-test_prod_mv(length_type m, length_type n)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n, T0());
-  Vector<T1> b1(n, T1());
-  Vector<T1> b2(m, T1());
-
-  randm(a);
-  randv(b1);
-  randv(b2);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]"  << endl;
-  cout << "a     =\n" << a;
-  cout << "b1    =\n" << b1;
-  cout << "b2    =\n" << b2;
-#endif
-
-  Vector<return_type> r1(m);
-  Vector<return_type> chk1(m);
-  Vector<scalar_type> gauge1(m);
-
-  r1 = prod( a, b1 );
-  chk1 = ref::prod( a, b1 );
-  gauge1 = ref::prod( mag(a), mag(b1) );
-
-  for (index_type i=0; i<gauge1.size(0); ++i)
-    if (!(gauge1(i) > scalar_type()))
-      gauge1(i) = scalar_type(1);
-
-  check_prod( r1, chk1, gauge1 );
-
-  Vector<return_type> r2(n);
-  Vector<return_type> chk2(n);
-  Vector<scalar_type> gauge2(n);
-
-  r2 = prod( trans(a), b2 );
-  chk2 = ref::prod( trans(a), b2 );
-  gauge2 = ref::prod( mag(trans(a)), mag(b2) );
-
-  for (index_type i=0; i<gauge2.size(0); ++i)
-    if (!(gauge2(i) > scalar_type()))
-      gauge2(i) = scalar_type(1);
-
-  check_prod( r2, chk2, gauge2 );
-}
-
-template <typename T0,
-	  typename T1>
-void
-test_prod_vm(length_type m, length_type n)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Vector<T1> a1(m, T1());
-  Vector<T1> a2(n, T1());
-  Matrix<T0> b(m, n, T0());
-
-  randv(a1);
-  randv(a2);
-  randm(b);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]"  << endl;
-  cout << "a1    =\n" << a1;
-  cout << "a2    =\n" << a2;
-  cout << "b     =\n" << b;
-#endif
-
-  Vector<return_type> r1(n);
-  Vector<return_type> chk1(n);
-  Vector<scalar_type> gauge1(n);
-
-  r1 = prod( a1, b );
-  chk1 = ref::prod( a1, b );
-  gauge1 = ref::prod( mag(a1), mag(b) );
-
-  for (index_type i=0; i<gauge1.size(0); ++i)
-    if (!(gauge1(i) > scalar_type()))
-      gauge1(i) = scalar_type(1);
-
-  check_prod( r1, chk1, gauge1 );
-
-  Vector<return_type> r2(m);
-  Vector<return_type> chk2(m);
-  Vector<scalar_type> gauge2(m);
-
-  r2 = prod( a2, trans(b) );
-  chk2 = ref::prod( a2, trans(b) );
-  gauge2 = ref::prod( mag(a2), mag(trans(b)) );
-
-  for (index_type i=0; i<gauge2.size(0); ++i)
-    if (!(gauge2(i) > scalar_type()))
-      gauge2(i) = scalar_type(1);
-
-  check_prod( r2, chk2, gauge2 );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
 test_prod3_rand()
 {
   typedef typename Promotion<T0, T1>::type return_type;
@@ -483,228 +137,18 @@
 template <typename T0,
 	  typename T1>
 void
-test_prodh_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(k, n);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for hermitian
-  res1   = prod(a, herm(b));
-
-  chk   = ref::prod(a, herm(b));
-  gauge = ref::prod(mag(a), mag(herm(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prodj_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for hermitian
-  res1   = prod(a, conj(b));
-
-  chk   = ref::prod(a, conj(b));
-  gauge = ref::prod(mag(a), mag(conj(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-          typename T1,
-          typename OrderR,
-          typename Order0,
-          typename Order1>
-void
-test_prodt_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  typedef Dense<2, T0, Order0>          block0_type;
-  typedef Dense<2, T1, Order1>          block1_type;
-  typedef Dense<2, return_type, OrderR> blockR_type;
-
-  Matrix<T0, block0_type> a(m, n);
-  Matrix<T1, block1_type> b(k, n);
-  Matrix<return_type, blockR_type> res1(m, k);
-  Matrix<return_type, blockR_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for transpose
-  res1 = prodt(a, b);
-
-  chk   = ref::prod(a, trans(b));
-  gauge = ref::prod(mag(a), mag(trans(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-prod_types_with_order()
-{
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(5, 7, 9);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(9, 5, 7);
-  test_prod_rand<T0, T1, OrderR, Order0, Order1>(9, 7, 5);
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prod_cases_with_order()
-{
-  prod_types_with_order<T0, T1, row2_type, row2_type, row2_type>();
-  prod_types_with_order<T0, T1, row2_type, col2_type, row2_type>();
-  prod_types_with_order<T0, T1, row2_type, row2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, col2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, row2_type, col2_type>();
-  prod_types_with_order<T0, T1, col2_type, col2_type, row2_type>();
-}
-
-
-template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-prodt_types_with_order()
-{
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 7, 9);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(9, 5, 7);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(9, 7, 5);
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prodt_cases_with_order()
-{
-  prodt_types_with_order<T0, T1, row2_type, row2_type, row2_type>();
-  prodt_types_with_order<T0, T1, row2_type, row2_type, col2_type>();
-}
-
-
-template <typename T0,
-	  typename T1>
-void
 prod_cases()
 {
-  test_prod_mv<T0, T1>(5, 7);
-  test_prod_vm<T0, T1>(5, 7);
-
   test_prod3_rand<T0, T1>();
   test_prod4_rand<T0, T1>();
-
-  prod_cases_with_order<T0, T1>();
-  prodt_cases_with_order<T0, T1>();
 }
 
 
-template <typename T0,
-	  typename T1>
-void
-prod_cases_complex_only()
-{
-  test_prodh_rand<T0, T1>(5, 5, 5);
-  test_prodh_rand<T0, T1>(5, 7, 9);
-  test_prodh_rand<T0, T1>(9, 5, 7);
-  test_prodh_rand<T0, T1>(9, 7, 5);
 
-  test_prodj_rand<T0, T1>(5, 5, 5);
-  test_prodj_rand<T0, T1>(5, 7, 9);
-  test_prodj_rand<T0, T1>(9, 5, 7);
-  test_prodj_rand<T0, T1>(9, 7, 5);
-}
-
-
-template <typename T>
-void 
-prod_special_cases()
-{
-  test_mm_prod_subview<T>(5, 7, 3);
-  test_mm_prod_complex_split<T>(5, 7, 3);
-}
-
-
-
 /***********************************************************************
   Main
 ***********************************************************************/
 
-template <> float  Precision_traits<float>::eps = 0.0;
-template <> double Precision_traits<double>::eps = 0.0;
-
 int
 main(int argc, char** argv)
 {
@@ -713,36 +157,16 @@
   Precision_traits<float>::compute_eps();
   Precision_traits<double>::compute_eps();
 
-#if VSIP_IMPL_TEST_LEVEL == 0
 
-  prod_cases<complex<float>, complex<float> >();
-  prod_cases_complex_only<complex<float>, complex<float> >();
-  prod_special_cases<float>();
-
-#else
-
   prod_cases<float,  float>();
 
   prod_cases<complex<float>, complex<float> >();
   prod_cases<float,          complex<float> >();
   prod_cases<complex<float>, float          >();
 
-  prod_cases_complex_only<complex<float>, complex<float> >();
-
-  prod_special_cases<float>();
-
 #if VSIP_IMPL_TEST_DOUBLE
   prod_cases<double, double>();
   prod_cases<float,  double>();
   prod_cases<double, float>();
-
-  prod_special_cases<double>();
 #endif
-
-
-  // Test a large matrix-matrix product (order > 80) to trigger
-  // ATLAS blocking code.  If order < NB, only the cleanup code
-  // gets exercised.
-  test_prod_rand<float, float, row2_type, row2_type, row2_type>(256, 256, 256);
-#endif // VSIP_IMPL_TEST_LEVEL > 0
 }
Index: tests/matvec-prod.cpp
===================================================================
--- tests/matvec-prod.cpp	(revision 208646)
+++ tests/matvec-prod.cpp	(working copy)
@@ -7,8 +7,7 @@
 /** @file    tests/matvec-prod.cpp
     @author  Jules Bergmann
     @date    2005-09-12
-    @brief   VSIPL++ Library: Unit tests for products
-	     (matrix-matrix, matrix-vector, vector-matrix).
+    @brief   VSIPL++ Library: Unit tests for matrix products.
 */
 
 /***********************************************************************
@@ -27,6 +26,7 @@
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/test-precision.hpp>
 
+#include "test-prod.hpp"
 #include "test-random.hpp"
 
 using namespace std;
@@ -35,75 +35,6 @@
 
 
 /***********************************************************************
-  Reference Definitions
-***********************************************************************/
-
-template <typename T0,
-	  typename T1,
-          typename T2,
-          typename Block0,
-          typename Block1,
-          typename Block2>
-void
-check_prod(
-  Matrix<T0, Block0> test,
-  Matrix<T1, Block1> chk,
-  Matrix<T2, Block2> gauge)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Index<2> idx;
-  scalar_type err = maxval(((mag(chk - test)
-			     / Precision_traits<scalar_type>::eps)
-			    / gauge),
-			   idx);
-
-#if VERBOSE
-  cout << "test  =\n" << test;
-  cout << "chk   =\n" << chk;
-  cout << "gauge =\n" << gauge;
-  cout << "err = " << err << endl;
-#endif
-
-  test_assert(err < 10.0);
-}
-
-
-template <typename T0,
-	  typename T1,
-          typename T2,
-          typename Block0,
-          typename Block1,
-          typename Block2>
-void
-check_prod(
-  Vector<T0, Block0> test,
-  Vector<T1, Block1> chk,
-  Vector<T2, Block2> gauge)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Index<1> idx;
-  scalar_type err = maxval(((mag(chk - test)
-			     / Precision_traits<scalar_type>::eps)
-			    / gauge),
-			   idx);
-
-#if VERBOSE
-  cout << "test  =\n" << test;
-  cout << "chk   =\n" << chk;
-  cout << "gauge =\n" << gauge;
-  cout << "err = " << err << endl;
-#endif
-
-  test_assert(err < 10.0);
-}
-
-
-
-/***********************************************************************
   Test Definitions
 ***********************************************************************/
 
@@ -168,440 +99,7 @@
 
 
 
-template <typename T>
-void
-test_mm_prod_subview( const length_type m, 
-                      const length_type n, 
-                      const length_type k )
-{
-  typedef typename Matrix<T>::subview_type matrix_subview_type;
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-
-  // non-unit strides - dense rows, non-dense columns
-  {
-    Matrix<T> aa(m, k*2, T());
-    Matrix<T> bb(k, n*3, T());
-    matrix_subview_type a = aa(Domain<2>(
-                                 Domain<1>(0, 1, m), Domain<1>(0, 2, k)));
-    matrix_subview_type b = bb(Domain<2>(
-                                 Domain<1>(0, 1, k), Domain<1>(0, 3, n)));
-    Matrix<T> res(m, n);
-    Matrix<T> chk(m, n);
-    Matrix<scalar_type> gauge(m, n);
-
-    randm(a);
-    randm(b);
-
-    res = prod( a, b );
-    chk = ref::prod( a, b );
-    gauge = ref::prod(mag(a), mag(b));
-
-    for (index_type i=0; i<gauge.size(0); ++i)
-      for (index_type j=0; j<gauge.size(1); ++j)
-        if (!(gauge(i, j) > scalar_type()))
-          gauge(i, j) = scalar_type(1);
-
-    check_prod( res, chk, gauge );
-  }
-
-  // non-unit strides - non-dense rows, dense columns
-  {
-    Matrix<T> aa(m*2, k, T());
-    Matrix<T> bb(k*3, n, T());
-    matrix_subview_type a = aa(Domain<2>( 
-                                 Domain<1>(0, 2, m), Domain<1>(0, 1, k)));
-    matrix_subview_type b = bb(Domain<2>(
-                                 Domain<1>(0, 3, k), Domain<1>(0, 1, n)));
-
-    Matrix<T> res(m, n);
-    Matrix<T> chk(m, n);
-    Matrix<scalar_type> gauge(m, n);
-
-    randm(a);
-    randm(b);
-
-    res = prod( a, b );
-    chk = ref::prod( a, b );
-    gauge = ref::prod(mag(a), mag(b));
-
-    for (index_type i=0; i<gauge.size(0); ++i)
-      for (index_type j=0; j<gauge.size(1); ++j)
-        if (!(gauge(i, j) > scalar_type()))
-          gauge(i, j) = scalar_type(1);
-
-    check_prod( res, chk, gauge );
-  }
-}
-
-
-
-template <typename T>
-void 
-test_mm_prod_complex_split(  const length_type m, 
-                             const length_type n, 
-                             const length_type k )
-{
-  typedef vsip::impl::Fast_block<2, complex<T>,
-    vsip::impl::Layout<2, row2_type,
-    vsip::impl::Stride_unit_dense,
-    vsip::impl::Cmplx_split_fmt> > split_type;
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-  
-  Matrix<complex<T>, split_type> a(m, k);
-  Matrix<complex<T>, split_type> b(k, n);
-  Matrix<complex<T>, split_type> res(m, n, T());
-
-  randm(a);
-  randm(b);
-
-  // call prod()'s underlying interface directly
-  vsip::impl::generic_prod(a, b, res);
-
-  // compute a reference matrix using interleaved (default) layout
-  Matrix<complex<T> > aa(m, k);
-  Matrix<complex<T> > bb(k, n);
-  aa = a;
-  bb = b;
-
-  Matrix<complex<T> > chk(m, n);
-  Matrix<scalar_type> gauge(m, n);
-  chk = ref::prod( aa, bb );
-  gauge = ref::prod( mag(aa), mag(bb) );
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-        gauge(i, j) = scalar_type(1);
-
-  check_prod( res, chk, gauge );
-}
-
-
-
 template <typename T0,
-	  typename T1>
-void
-test_prod_mv(length_type m, length_type n)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n, T0());
-  Vector<T1> b1(n, T1());
-  Vector<T1> b2(m, T1());
-
-  randm(a);
-  randv(b1);
-  randv(b2);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]"  << endl;
-  cout << "a     =\n" << a;
-  cout << "b1    =\n" << b1;
-  cout << "b2    =\n" << b2;
-#endif
-
-  Vector<return_type> r1(m);
-  Vector<return_type> chk1(m);
-  Vector<scalar_type> gauge1(m);
-
-  r1 = prod( a, b1 );
-  chk1 = ref::prod( a, b1 );
-  gauge1 = ref::prod( mag(a), mag(b1) );
-
-  for (index_type i=0; i<gauge1.size(0); ++i)
-    if (!(gauge1(i) > scalar_type()))
-      gauge1(i) = scalar_type(1);
-
-  check_prod( r1, chk1, gauge1 );
-
-  Vector<return_type> r2(n);
-  Vector<return_type> chk2(n);
-  Vector<scalar_type> gauge2(n);
-
-  r2 = prod( trans(a), b2 );
-  chk2 = ref::prod( trans(a), b2 );
-  gauge2 = ref::prod( mag(trans(a)), mag(b2) );
-
-  for (index_type i=0; i<gauge2.size(0); ++i)
-    if (!(gauge2(i) > scalar_type()))
-      gauge2(i) = scalar_type(1);
-
-  check_prod( r2, chk2, gauge2 );
-}
-
-template <typename T0,
-	  typename T1>
-void
-test_prod_vm(length_type m, length_type n)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Vector<T1> a1(m, T1());
-  Vector<T1> a2(n, T1());
-  Matrix<T0> b(m, n, T0());
-
-  randv(a1);
-  randv(a2);
-  randm(b);
-
-#if VERBOSE
-  cout << "[" << m << "x" << n << "]"  << endl;
-  cout << "a1    =\n" << a1;
-  cout << "a2    =\n" << a2;
-  cout << "b     =\n" << b;
-#endif
-
-  Vector<return_type> r1(n);
-  Vector<return_type> chk1(n);
-  Vector<scalar_type> gauge1(n);
-
-  r1 = prod( a1, b );
-  chk1 = ref::prod( a1, b );
-  gauge1 = ref::prod( mag(a1), mag(b) );
-
-  for (index_type i=0; i<gauge1.size(0); ++i)
-    if (!(gauge1(i) > scalar_type()))
-      gauge1(i) = scalar_type(1);
-
-  check_prod( r1, chk1, gauge1 );
-
-  Vector<return_type> r2(m);
-  Vector<return_type> chk2(m);
-  Vector<scalar_type> gauge2(m);
-
-  r2 = prod( a2, trans(b) );
-  chk2 = ref::prod( a2, trans(b) );
-  gauge2 = ref::prod( mag(a2), mag(trans(b)) );
-
-  for (index_type i=0; i<gauge2.size(0); ++i)
-    if (!(gauge2(i) > scalar_type()))
-      gauge2(i) = scalar_type(1);
-
-  check_prod( r2, chk2, gauge2 );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prod3_rand()
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-  const length_type m = 3;
-  const length_type n = 3;
-  const length_type k = 3;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> res2(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod3(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod3(a, b.col(i));
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-  cout << "chk   =\n" << chk;
-  cout << "res1  =\n" << res1;
-  cout << "res2  =\n" << res2;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prod4_rand()
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-  const length_type m = 4;
-  const length_type n = 4;
-  const length_type k = 4;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> res2(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod
-  res1   = prod4(a, b);
-
-  // Test matrix-vector prod
-  for (index_type i=0; i<k; ++i)
-    res2.col(i) = prod4(a, b.col(i));
-
-  chk   = ref::prod(a, b);
-  gauge = ref::prod(mag(a), mag(b));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prodh_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(k, n);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for hermitian
-  res1   = prod(a, herm(b));
-
-  chk   = ref::prod(a, herm(b));
-  gauge = ref::prod(mag(a), mag(herm(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-	  typename T1>
-void
-test_prodj_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(n, k);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for hermitian
-  res1   = prod(a, conj(b));
-
-  chk   = ref::prod(a, conj(b));
-  gauge = ref::prod(mag(a), mag(conj(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
-          typename T1,
-          typename OrderR,
-          typename Order0,
-          typename Order1>
-void
-test_prodt_rand(length_type m, length_type n, length_type k)
-{
-  typedef typename Promotion<T0, T1>::type return_type;
-  typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
-
-  typedef Dense<2, T0, Order0>          block0_type;
-  typedef Dense<2, T1, Order1>          block1_type;
-  typedef Dense<2, return_type, OrderR> blockR_type;
-
-  Matrix<T0, block0_type> a(m, n);
-  Matrix<T1, block1_type> b(k, n);
-  Matrix<return_type, blockR_type> res1(m, k);
-  Matrix<return_type, blockR_type> chk(m, k);
-  Matrix<scalar_type> gauge(m, k);
-
-  randm(a);
-  randm(b);
-
-  // Test matrix-matrix prod for transpose
-  res1 = prodt(a, b);
-
-  chk   = ref::prod(a, trans(b));
-  gauge = ref::prod(mag(a), mag(trans(b)));
-
-  for (index_type i=0; i<gauge.size(0); ++i)
-    for (index_type j=0; j<gauge.size(1); ++j)
-      if (!(gauge(i, j) > scalar_type()))
-	gauge(i, j) = scalar_type(1);
-
-#if VERBOSE
-  cout << "a     =\n" << a;
-  cout << "b     =\n" << b;
-#endif
-
-  check_prod( res1, chk, gauge );
-}
-
-
-
-template <typename T0,
 	  typename T1,
 	  typename OrderR,
 	  typename Order0,
@@ -630,81 +128,10 @@
 }
 
 
-template <typename T0,
-	  typename T1,
-	  typename OrderR,
-	  typename Order0,
-	  typename Order1>
-void
-prodt_types_with_order()
-{
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 7, 9);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(9, 5, 7);
-  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(9, 7, 5);
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prodt_cases_with_order()
-{
-  prodt_types_with_order<T0, T1, row2_type, row2_type, row2_type>();
-  prodt_types_with_order<T0, T1, row2_type, row2_type, col2_type>();
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prod_cases()
-{
-  test_prod_mv<T0, T1>(5, 7);
-  test_prod_vm<T0, T1>(5, 7);
-
-  test_prod3_rand<T0, T1>();
-  test_prod4_rand<T0, T1>();
-
-  prod_cases_with_order<T0, T1>();
-  prodt_cases_with_order<T0, T1>();
-}
-
-
-template <typename T0,
-	  typename T1>
-void
-prod_cases_complex_only()
-{
-  test_prodh_rand<T0, T1>(5, 5, 5);
-  test_prodh_rand<T0, T1>(5, 7, 9);
-  test_prodh_rand<T0, T1>(9, 5, 7);
-  test_prodh_rand<T0, T1>(9, 7, 5);
-
-  test_prodj_rand<T0, T1>(5, 5, 5);
-  test_prodj_rand<T0, T1>(5, 7, 9);
-  test_prodj_rand<T0, T1>(9, 5, 7);
-  test_prodj_rand<T0, T1>(9, 7, 5);
-}
-
-
-template <typename T>
-void 
-prod_special_cases()
-{
-  test_mm_prod_subview<T>(5, 7, 3);
-  test_mm_prod_complex_split<T>(5, 7, 3);
-}
-
-
-
 /***********************************************************************
   Main
 ***********************************************************************/
 
-template <> float  Precision_traits<float>::eps = 0.0;
-template <> double Precision_traits<double>::eps = 0.0;
-
 int
 main(int argc, char** argv)
 {
@@ -713,30 +140,17 @@
   Precision_traits<float>::compute_eps();
   Precision_traits<double>::compute_eps();
 
-#if VSIP_IMPL_TEST_LEVEL == 0
 
-  prod_cases<complex<float>, complex<float> >();
-  prod_cases_complex_only<complex<float>, complex<float> >();
-  prod_special_cases<float>();
+  prod_cases_with_order<float,  float>();
 
-#else
+  prod_cases_with_order<complex<float>, complex<float> >();
+  prod_cases_with_order<float,          complex<float> >();
+  prod_cases_with_order<complex<float>, float          >();
 
-  prod_cases<float,  float>();
-
-  prod_cases<complex<float>, complex<float> >();
-  prod_cases<float,          complex<float> >();
-  prod_cases<complex<float>, float          >();
-
-  prod_cases_complex_only<complex<float>, complex<float> >();
-
-  prod_special_cases<float>();
-
 #if VSIP_IMPL_TEST_DOUBLE
-  prod_cases<double, double>();
-  prod_cases<float,  double>();
-  prod_cases<double, float>();
-
-  prod_special_cases<double>();
+  prod_cases_with_order<double, double>();
+  prod_cases_with_order<float,  double>();
+  prod_cases_with_order<double, float>();
 #endif
 
 
@@ -744,5 +158,4 @@
   // ATLAS blocking code.  If order < NB, only the cleanup code
   // gets exercised.
   test_prod_rand<float, float, row2_type, row2_type, row2_type>(256, 256, 256);
-#endif // VSIP_IMPL_TEST_LEVEL > 0
 }
