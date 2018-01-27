Index: ChangeLog
===================================================================
--- ChangeLog	(revision 164924)
+++ ChangeLog	(working copy)
@@ -1,5 +1,24 @@
 2007-03-06  Jules Bergmann  <jules@codesourcery.com>
 
+	* tests/scalar-view.cpp: Rename file to scalar_view.hpp, and split
+	  tests into separate files.
+	* tests/scalar_view.hpp: New file.
+	* tests/scalar_view_add.cpp: New file, subset of scalar-view.cpp.
+	* tests/scalar_view_mul.cpp: New file, likewise.
+	* tests/scalar_view_sub.cpp: New file, likewise.
+	* tests/scalar_view_div.cpp: New file, likewise.
+	* tests/corr-2d.cpp: Disable double tests when VSIP_IMPL_TEST_DOUBLE
+	  not defined, add level 0 test subset.
+	* tests/coverage_binary.cpp: Likewise.
+	* tests/matvec-prod.cpp: Likewise.
+	* tests/conv-2d.cpp: Add level 0 test subset.
+	* tests/correlation.cpp: Likewise.
+	* tests/coverage_unary.cpp: Likewise.
+	* tests/convolution.cpp: Simplify level 0 test subset.
+	* tests/make.standalone: Add smallcheck target.
+	
+2007-03-06  Jules Bergmann  <jules@codesourcery.com>
+
 	Add CBE split-complex fast convolution kernel.
 	* src/vsip/opt/cbe/ppu/task_manager.hpp: Add tasks for split vmul
 	  and split fastconv.
Index: tests/scalar_view.hpp
===================================================================
--- tests/scalar_view.hpp	(revision 164339)
+++ tests/scalar_view.hpp	(working copy)
@@ -1,10 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    tests/scalar-view.cpp
+/** @file    tests/scalar_view.hpp
     @author  Jules Bergmann
     @date    2005-12-19
     @brief   VSIPL++ Library: Coverage tests for scalar-view expressions.
@@ -257,18 +257,3 @@
   test_type<op, complex<float>, complex<float>,         float  >();
   test_type<op, complex<float>, complex<float>, complex<float> >();
 }
-
-
-
-int
-main()
-{
-#if VSIP_IMPL_TEST_LEVEL == 0
-  test_lite<op_mul>();
-#else
-  test<op_mul>();
-  test<op_add>();
-  test<op_sub>();
-  test<op_div>();
-#endif
-}
Index: tests/scalar-view.cpp
===================================================================
--- tests/scalar-view.cpp	(revision 164339)
+++ tests/scalar-view.cpp	(working copy)
@@ -1,274 +0,0 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
-
-   This file is available for license from CodeSourcery, Inc. under the terms
-   of a commercial license and under the GPL.  It is not part of the VSIPL++
-   reference implementation and is not available under the BSD license.
-*/
-/** @file    tests/scalar-view.cpp
-    @author  Jules Bergmann
-    @date    2005-12-19
-    @brief   VSIPL++ Library: Coverage tests for scalar-view expressions.
-
-*/
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <vsip/support.hpp>
-#include <vsip/vector.hpp>
-#include <vsip/selgen.hpp>
-#include <vsip/math.hpp>
-
-#include <vsip_csl/test.hpp>
-#include <vsip_csl/test-storage.hpp>
-
-using namespace std;
-using namespace vsip;
-using namespace vsip_csl;
-
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-enum Op_type
-{
-  op_add,
-  op_sub,
-  op_mul,
-  op_div
-};
-
-/// Utility class to hold an Op_type value as a distinct type.
-template <Op_type Type> struct Op_holder {};
-
-
-/// Trait to determine value type of a type.
-
-/// For general types, type is value type.
-template <typename T>
-struct Value_type
-{
-  typedef T type;
-};
-
-/// For views, element type is value type.
-template <typename T, typename Block>
-struct Value_type<Vector<T, Block> >
-{
-  typedef T type;
-};
-
-
-
-/// Overload of test_case for add expression: res = a + b.
-
-template <typename T1,
-	  typename T2,
-	  typename T3>
-void
-test_case(
-  Op_holder<op_add>,
-  T1 res,
-  T2 a,
-  T3 b)
-{
-  typedef typename Value_type<T1>::type value_type;
-
-  res = a + b;
-  
-  for (index_type i=0; i<get_size(res); ++i)
-  {
-    test_assert(equal(get_nth(res, i),
-		       value_type(get_nth(a, i) + get_nth(b, i))));
-  }
-}
-
-
-
-/// Overload of test_case for subtract expression: res = a - b.
-
-template <typename T1,
-	  typename T2,
-	  typename T3>
-void
-test_case(
-  Op_holder<op_sub>,
-  T1 res,
-  T2 a,
-  T3 b)
-{
-  typedef typename Value_type<T1>::type value_type;
-
-  res = a - b;
-  
-  for (index_type i=0; i<get_size(res); ++i)
-  {
-    test_assert(equal(get_nth(res, i),
-		       value_type(get_nth(a, i) - get_nth(b, i))));
-  }
-}
-
-
-
-/// Overload of test_case for multiply expression: res = a * b.
-
-template <typename T1,
-	  typename T2,
-	  typename T3>
-void
-test_case(
-  Op_holder<op_mul>,
-  T1 res,
-  T2 a,
-  T3 b)
-{
-  typedef typename Value_type<T1>::type value_type;
-
-  res = a * b;
-  
-  for (index_type i=0; i<get_size(res); ++i)
-  {
-    test_assert(equal(get_nth(res, i),
-		       value_type(get_nth(a, i) * get_nth(b, i))));
-  }
-}
-
-
-
-/// Overload of test_case for divide expression: res = a / b.
-
-template <typename T1,
-	  typename T2,
-	  typename T3>
-void
-test_case(
-  Op_holder<op_div>,
-  T1 res,
-  T2 a,
-  T3 b)
-{
-  typedef typename Value_type<T1>::type value_type;
-
-  res = a / b;
-  
-  for (index_type i=0; i<get_size(res); ++i)
-  {
-    test_assert(equal(get_nth(res, i),
-		       value_type(get_nth(a, i) / get_nth(b, i))));
-  }
-}
-
-
-
-// Test given expression with various combinations of scalar vs view
-// operands and stride-1 vs stride-N operands.
-
-template <Op_type  op,
-	  typename T1,
-	  typename T2,
-	  typename T3>
-void
-test_type()
-{
-  length_type size = 8;
-
-  Vector<T1> big_res(2 * size);
-  Vector<T2> big_a(2 * size);
-  Vector<T3> big_b(2 * size);
-
-  Vector<T1> res(size);
-  Vector<T2> a(size);
-  Vector<T3> b(size);
-
-  typename Vector<T1>::subview_type res2 = big_res(Domain<1>(0, 2, size));
-  typename Vector<T2>::subview_type a2   = big_a(Domain<1>(0, 2, size));
-  typename Vector<T3>::subview_type b2   = big_b(Domain<1>(0, 2, size));
-
-  T2 alpha = T2(2);
-  T3 beta  = T3(3);
-
-  a  = ramp(T2(1), T2(1),  size);
-  b  = ramp(T3(1), T3(-2), size);
-  a2 = ramp(T2(1), T2(1),  size);
-  b2 = ramp(T3(1), T3(-2), size);
-
-  test_case(Op_holder<op>(), res, a, b);
-  test_case(Op_holder<op>(), res, alpha, b);
-  test_case(Op_holder<op>(), res, a, beta);
-
-  test_case(Op_holder<op>(), res, a2, b);
-  test_case(Op_holder<op>(), res, a, b2);
-  test_case(Op_holder<op>(), res, alpha, b2);
-  test_case(Op_holder<op>(), res, a2, beta);
-
-  test_case(Op_holder<op>(), res2, a, b);
-  test_case(Op_holder<op>(), res2, a2, b);
-  test_case(Op_holder<op>(), res2, a, b2);
-  test_case(Op_holder<op>(), res2, alpha, b);
-  test_case(Op_holder<op>(), res2, a, beta);
-
-  test_case(Op_holder<op>(), res2, a2, b2);
-  test_case(Op_holder<op>(), res2, alpha, b2);
-  test_case(Op_holder<op>(), res2, a2, beta);
-}
-
-
-
-// Test an operation for various types.
-
-template <Op_type op>
-void
-test()
-{
-  test_type<op, short, short, short>();
-  test_type<op, int, short, short>();
-  test_type<op, int, int, short>();
-  test_type<op, int, short, int>();
-  test_type<op, int, int, int>();
-
-  test_type<op, float, float, float>();
-  test_type<op, float, double, float>();
-  test_type<op, float, float, double>();
-
-  test_type<op, double, double, double>();
-  test_type<op, double, double, float>();
-  test_type<op, double, float,  double>();
-  test_type<op, double, float,  float>();
-
-  test_type<op, complex<float>,         float,  complex<float> >();
-  test_type<op, complex<float>, complex<float>,         float  >();
-  test_type<op, complex<float>, complex<float>, complex<float> >();
-
-  test_type<op, complex<double>,         double,  complex<double> >();
-  test_type<op, complex<double>, complex<double>,         double  >();
-  test_type<op, complex<double>, complex<double>, complex<double> >();
-
-}
-
-
-
-template <Op_type op>
-void
-test_lite()
-{
-  test_type<op, complex<float>,         float,  complex<float> >();
-  test_type<op, complex<float>, complex<float>,         float  >();
-  test_type<op, complex<float>, complex<float>, complex<float> >();
-}
-
-
-
-int
-main()
-{
-#if VSIP_IMPL_TEST_LEVEL == 0
-  test_lite<op_mul>();
-#else
-  test<op_mul>();
-  test<op_add>();
-  test<op_sub>();
-  test<op_div>();
-#endif
-}
Index: tests/scalar_view_div.cpp
===================================================================
--- tests/scalar_view_div.cpp	(revision 0)
+++ tests/scalar_view_div.cpp	(revision 0)
@@ -0,0 +1,34 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/scalar_view_div.cpp
+    @author  Jules Bergmann
+    @date    2007-02-08
+    @brief   VSIPL++ Library: Coverage tests for scalar-view div expressions.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include "scalar_view.hpp"
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+int
+main()
+{
+#if VSIP_IMPL_TEST_LEVEL == 0
+  test_lite<op_div>();
+#else
+  test<op_div>();
+#endif
+}
Index: tests/scalar_view_add.cpp
===================================================================
--- tests/scalar_view_add.cpp	(revision 0)
+++ tests/scalar_view_add.cpp	(revision 0)
@@ -0,0 +1,34 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/scalar_view_add.cpp
+    @author  Jules Bergmann
+    @date    2007-02-08
+    @brief   VSIPL++ Library: Coverage tests for scalar-view add expressions.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include "scalar_view.hpp"
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+int
+main()
+{
+#if VSIP_IMPL_TEST_LEVEL == 0
+  test_lite<op_add>();
+#else
+  test<op_add>();
+#endif
+}
Index: tests/corr-2d.cpp
===================================================================
--- tests/corr-2d.cpp	(revision 164339)
+++ tests/corr-2d.cpp	(working copy)
@@ -175,11 +175,15 @@
 {
   vsipl init(argc, argv);
 
+#if VSIP_IMPL_TEST_LEVEL == 0
+  corr_cover<float>();
+#else
   // Test user-visible correlation
   corr_cover<float>();
   corr_cover<complex<float> >();
-#if VSIP_IMPL_TEST_DOUBLE
+#  if VSIP_IMPL_TEST_DOUBLE
   corr_cover<double>();
   corr_cover<complex<double> >();
-#endif // VSIP_IMPL_TEST_DOUBLE
+#  endif // VSIP_IMPL_TEST_DOUBLE
+#endif // VSIP_IMPL_TEST_LEVEL >= 1
 }
Index: tests/conv-2d.cpp
===================================================================
--- tests/conv-2d.cpp	(revision 164339)
+++ tests/conv-2d.cpp	(working copy)
@@ -527,7 +527,28 @@
 {
   vsipl init(argc, argv);
 
-#if 1
+#if VSIP_IMPL_TEST_LEVEL == 0
+  // small sets of tests, covered by 'cases()' below
+  cases_nonsym<int>(8, 8, 3, 3);
+  cases_nonsym<float>(8, 8, 3, 3);
+  cases_nonsym<complex<float> >(8, 8, 3, 3);
+
+  // individual tests, covered by 'cases()' below
+  test_conv_nonsym<int, support_min>(8, 8, 3, 3, 1, 1, 1);
+  test_conv_nonsym<int, support_min>(8, 8, 3, 3, 0, 2, -1);
+  test_conv_nonsym<int, support_min>(8, 8, 3, 3, 2, 0, 2);
+  test_conv_nonsym<int, support_min>(8, 8, 3, 3, 2, 2, -2);
+
+  test_conv_nonsym<int, support_same>(8, 8, 3, 3, 1, 1, 1);
+  test_conv_nonsym<int, support_same>(8, 8, 3, 3, 0, 2, -1);
+  test_conv_nonsym<int, support_same>(8, 8, 3, 3, 2, 0, 2);
+
+  test_conv_nonsym<int, support_full>(8, 8, 3, 3, 1, 1, 1);
+  test_conv_nonsym<int, support_full>(8, 8, 3, 3, 0, 0, 2);
+  test_conv_nonsym<int, support_full>(8, 8, 3, 3, 2, 2, -1);
+#endif
+
+#if VSIP_IMPL_TEST_LEVEL >= 1
   // General tests.
   bool rand = true;
   cases<short>(rand);
@@ -545,30 +566,6 @@
 
   cases_nonsym<complex<double> >(8, 8, 3, 3);
 #  endif // VSIP_IMPL_TEST_DOUBLE
-
 #endif
 
-#if 0
-  // small sets of tests, covered by 'cases()' above
-  cases_nonsym<int>(8, 8, 3, 3);
-  cases_nonsym<float>(8, 8, 3, 3);
-  cases_nonsym<double>(8, 8, 3, 3);
-  cases_nonsym<complex<int> >(8, 8, 3, 3);
-  cases_nonsym<complex<float> >(8, 8, 3, 3);
-  cases_nonsym<complex<double> >(8, 8, 3, 3);
-
-  // individual tests, covered by 'cases()' above
-  test_conv_nonsym<int, support_min>(8, 8, 3, 3, 1, 1, 1);
-  test_conv_nonsym<int, support_min>(8, 8, 3, 3, 0, 2, -1);
-  test_conv_nonsym<int, support_min>(8, 8, 3, 3, 2, 0, 2);
-  test_conv_nonsym<int, support_min>(8, 8, 3, 3, 2, 2, -2);
-
-  test_conv_nonsym<int, support_same>(8, 8, 3, 3, 1, 1, 1);
-  test_conv_nonsym<int, support_same>(8, 8, 3, 3, 0, 2, -1);
-  test_conv_nonsym<int, support_same>(8, 8, 3, 3, 2, 0, 2);
-
-  test_conv_nonsym<int, support_full>(8, 8, 3, 3, 1, 1, 1);
-  test_conv_nonsym<int, support_full>(8, 8, 3, 3, 0, 0, 2);
-  test_conv_nonsym<int, support_full>(8, 8, 3, 3, 2, 2, -1);
-#endif
 }
Index: tests/correlation.cpp
===================================================================
--- tests/correlation.cpp	(revision 164339)
+++ tests/correlation.cpp	(working copy)
@@ -24,7 +24,7 @@
 #include <vsip_csl/ref_corr.hpp>
 #include <vsip_csl/error_db.hpp>
 
-#define VERBOSE 1
+#define VERBOSE 0
 
 #if VERBOSE
 #  include <iostream>
@@ -96,7 +96,7 @@
     double error = error_db(out, chk);
 
 #if VERBOSE
-    if (error > -120)
+    if (error > -100)
     {
       for (index_type i=0; i<P; ++i)
       {
@@ -282,6 +282,9 @@
 {
   vsipl init(argc, argv);
 
+#if VSIP_IMPL_TEST_LEVEL == 0
+  corr_cover<float>();
+#else
   // Test user-visible correlation
   corr_cover<float>();
   corr_cover<complex<float> >();
@@ -290,16 +293,16 @@
   impl_corr_cover<impl::Opt_tag, float>();
   impl_corr_cover<impl::Opt_tag, complex<float> >();
 
-#if VSIP_IMPL_HAVE_CVSIP
+# if VSIP_IMPL_HAVE_CVSIP
   // Test C-VSIPL implementation
   impl_corr_cover<impl::Cvsip_tag, float>();
   impl_corr_cover<impl::Cvsip_tag, complex<float> >();
-#endif
+# endif
   // Test generic implementation
   impl_corr_cover<impl::Generic_tag, float>();
   impl_corr_cover<impl::Generic_tag, complex<float> >();
 
-#if VSIP_IMPL_TEST_DOUBLE
+# if VSIP_IMPL_TEST_DOUBLE
   // Test user-visible correlation
   corr_cover<double>();
   corr_cover<complex<double> >();
@@ -308,14 +311,15 @@
   impl_corr_cover<impl::Opt_tag, double>();
   impl_corr_cover<impl::Opt_tag, complex<double> >();
 
-#if VSIP_IMPL_HAVE_CVSIP
+#  if VSIP_IMPL_HAVE_CVSIP
   // Test generic implementation
   impl_corr_cover<impl::Cvsip_tag, double>();
   impl_corr_cover<impl::Cvsip_tag, complex<double> >();
-#endif
+#  endif
 
   // Test generic implementation
   impl_corr_cover<impl::Generic_tag, double>();
   impl_corr_cover<impl::Generic_tag, complex<double> >();
-#endif // VSIP_IMPL_TEST_DOUBLE
+# endif // VSIP_IMPL_TEST_DOUBLE
+#endif
 }
Index: tests/coverage_binary.cpp
===================================================================
--- tests/coverage_binary.cpp	(revision 164339)
+++ tests/coverage_binary.cpp	(working copy)
@@ -207,9 +207,6 @@
 
 
 
-
-
-
 /***********************************************************************
   Main
 ***********************************************************************/
@@ -219,13 +216,26 @@
 {
   vsipl init(argc, argv);
 
+#if VSIP_IMPL_TEST_LEVEL == 0
+  vector_cases3<Test_add,  int,             int>();
+  vector_cases3<Test_sub,  float,           float>();
+  vector_cases3<Test_mul,  complex<float>,  complex<float> >();
+  vector_cases3<Test_mul,  float,           complex<float> >();
+  vector_cases3<Test_div,  complex<float>,  float>();
+  vector_cases3<Test_max,  float,           float>();
+  vector_cases3<Test_min,  float,           float>();
+  vector_cases3<Test_band, int,           int>();
+  vector_cases3<Test_lxor, bool,          bool>();
+  matrix_cases3<Test_add,  float, float>();
+#else
+
   // Binary Operators
   vector_cases3<Test_add, int,             int>();
   vector_cases3<Test_add, float,           float>();
   vector_cases3<Test_add, complex<float>,  complex<float> >();
   vector_cases3<Test_add, float,           complex<float> >();
   vector_cases3<Test_add, complex<float>,  float>();
-#if VSIP_IMPL_TEST_LEVEL > 0
+#if VSIP_IMPL_TEST_DOUBLE
   vector_cases3<Test_add, double,          double>();
   vector_cases3<Test_add, complex<double>, complex<double> >();
 #endif
@@ -234,7 +244,7 @@
   vector_cases3<Test_sub, float,           float>();
   vector_cases3<Test_sub, complex<float>,  complex<float> >();
   vector_cases3<Test_sub, complex<float>,  float>();
-#if VSIP_IMPL_TEST_LEVEL > 0
+#if VSIP_IMPL_TEST_DOUBLE
   vector_cases3<Test_sub, double,          double>();
   vector_cases3<Test_sub, complex<double>, complex<double> >();
 #endif
@@ -244,7 +254,7 @@
   vector_cases3<Test_mul, complex<float>,  complex<float> >();
   vector_cases3<Test_mul, float,           complex<float> >();
   vector_cases3<Test_mul, complex<float>,  float>();
-#if VSIP_IMPL_TEST_LEVEL > 0
+#if VSIP_IMPL_TEST_DOUBLE
   vector_cases3<Test_mul, double,          double>();
   vector_cases3<Test_mul, complex<double>, complex<double> >();
 #endif
@@ -254,16 +264,18 @@
   vector_cases3<Test_div, float,           float>();
   vector_cases3<Test_div, complex<float>,  complex<float> >();
   vector_cases3<Test_div, complex<float>,  float>();
-#if VSIP_IMPL_TEST_LEVEL > 0
+#if VSIP_IMPL_TEST_DOUBLE
   vector_cases3<Test_div, double,          double>();
   vector_cases3<Test_div, complex<double>, complex<double> >();
 #endif
 
   vector_cases3<Test_max, float,           float>();
+  vector_cases3<Test_min, float,           float>();
+
+#if VSIP_IMPL_TEST_DOUBLE
   vector_cases3<Test_max, double,          double>();
-
-  vector_cases3<Test_min, float,           float>();
   vector_cases3<Test_min, double,          double>();
+#endif
 
   vector_cases3<Test_band, int,           int>();
   vector_cases3<Test_bor,  int,           int>();
@@ -275,4 +287,5 @@
 
 
   matrix_cases3<Test_add, float, float>();
+#endif
 }
Index: tests/scalar_view_sub.cpp
===================================================================
--- tests/scalar_view_sub.cpp	(revision 0)
+++ tests/scalar_view_sub.cpp	(revision 0)
@@ -0,0 +1,34 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/scalar_view_sub.cpp
+    @author  Jules Bergmann
+    @date    2007-02-08
+    @brief   VSIPL++ Library: Coverage tests for scalar-view sub expressions.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include "scalar_view.hpp"
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+int
+main()
+{
+#if VSIP_IMPL_TEST_LEVEL == 0
+  test_lite<op_sub>();
+#else
+  test<op_sub>();
+#endif
+}
Index: tests/coverage_unary.cpp
===================================================================
--- tests/coverage_unary.cpp	(revision 164339)
+++ tests/coverage_unary.cpp	(working copy)
@@ -67,6 +67,24 @@
 {
   vsipl init(argc, argv);
 
+#if VSIP_IMPL_TEST_LEVEL == 0
+
+  vector_cases2<Test_neg, float>();
+  vector_cases2<Test_mag, float>();
+  vector_cases2_rt<Test_mag, complex<float>,  float>();
+  vector_cases2<Test_cos, float>();
+  vector_cases2<Test_atan, float>();
+  vector_cases2<Test_log, float>();
+  vector_cases2<Test_exp, float>();
+  vector_cases2<Test_sqrt, float>();
+  vector_cases2<Test_sq, float>();
+  vector_cases2<Test_copy, float>();
+  vector_cases2_mix<Test_copy, complex<float> >();
+  vector_cases2<Test_bnot, int>();
+  vector_cases2<Test_lnot, bool>();
+
+#else
+
   // Unary operators
   vector_cases2<Test_neg, int>();
   vector_cases2<Test_neg, float>();
@@ -125,4 +143,6 @@
 
   vector_cases2<Test_bnot, int>();
   vector_cases2<Test_lnot, bool>();
+
+#endif // VSIP_IMPL_TEST_LEVEL > 0
 }
Index: tests/scalar_view_mul.cpp
===================================================================
--- tests/scalar_view_mul.cpp	(revision 0)
+++ tests/scalar_view_mul.cpp	(revision 0)
@@ -0,0 +1,34 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/scalar_view_mul.cpp
+    @author  Jules Bergmann
+    @date    2007-02-08
+    @brief   VSIPL++ Library: Coverage tests for scalar-view mul expressions.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include "scalar_view.hpp"
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+int
+main()
+{
+#if VSIP_IMPL_TEST_LEVEL == 0
+  test_lite<op_mul>();
+#else
+  test<op_mul>();
+#endif
+}
Index: tests/convolution.cpp
===================================================================
--- tests/convolution.cpp	(revision 164339)
+++ tests/convolution.cpp	(working copy)
@@ -536,7 +536,6 @@
 
 #if VSIP_IMPL_TEST_LEVEL == 0
   cases<float>(true);
-  cases<complex<float> >(true);
 #else
 
   // Regression: These cases trigger undefined behavior according to
Index: tests/matvec-prod.cpp
===================================================================
--- tests/matvec-prod.cpp	(revision 164339)
+++ tests/matvec-prod.cpp	(working copy)
@@ -659,16 +659,12 @@
 }
 
 
+template <typename T>
 void 
 prod_special_cases()
 {
-  test_mm_prod_subview<float>(5, 7, 3);
-  test_mm_prod_complex_split<float>(5, 7, 3);
-
-#if VSIP_IMPL_TEST_DOUBLE
-  test_mm_prod_subview<double>(5, 7, 3);
-  test_mm_prod_complex_split<double>(5, 7, 3);
-#endif
+  test_mm_prod_subview<T>(5, 7, 3);
+  test_mm_prod_complex_split<T>(5, 7, 3);
 }
 
 
@@ -689,7 +685,14 @@
   Precision_traits<float>::compute_eps();
   Precision_traits<double>::compute_eps();
 
+#if VSIP_IMPL_TEST_LEVEL == 0
 
+  prod_cases<complex<float>, complex<float> >();
+  prod_cases_complex_only<complex<float>, complex<float> >();
+  prod_special_cases<float>();
+
+#else
+
   prod_cases<float,  float>();
 
   prod_cases<complex<float>, complex<float> >();
@@ -698,16 +701,20 @@
 
   prod_cases_complex_only<complex<float>, complex<float> >();
 
+  prod_special_cases<float>();
+
 #if VSIP_IMPL_TEST_DOUBLE
   prod_cases<double, double>();
   prod_cases<float,  double>();
   prod_cases<double, float>();
+
+  prod_special_cases<double>();
 #endif
 
-  prod_special_cases();
 
   // Test a large matrix-matrix product (order > 80) to trigger
   // ATLAS blocking code.  If order < NB, only the cleanup code
   // gets exercised.
   test_prod_rand<float, float, row2_type, row2_type, row2_type>(256, 256, 256);
+#endif // VSIP_IMPL_TEST_LEVEL > 0
 }
Index: tests/make.standalone
===================================================================
--- tests/make.standalone	(revision 164339)
+++ tests/make.standalone	(working copy)
@@ -73,8 +73,28 @@
 sources := $(wildcard *.cpp)
 tests   := $(patsubst %.cpp, %.test, $(sources))
 
+smalltests :=				\
+	check_config.test		\
+	convolution.test		\
+	coverage_binary.test		\
+	dense.test			\
+	domain.test			\
+	fft_be.test			\
+	fftm.test			\
+	fir.test			\
+	matrix-transpose.test		\
+	matrix.test			\
+	matvec.test			\
+	reductions.test			\
+	solver-qr.test			\
+	vector.test			\
+	vmmul.test			\
+	parallel/corner-turn.test	\
+	parallel/expr.test		\
+	parallel/fftm.test
 
 
+
 ########################################################################
 # Targets
 ########################################################################
@@ -83,6 +103,8 @@
 
 check: $(tests)
 
+smallcheck: $(smalltests)
+
 vars:
 	@echo "CXX     : " $(CXX)
 	@echo "CXXFLAGS: " $(CXXFLAGS)
