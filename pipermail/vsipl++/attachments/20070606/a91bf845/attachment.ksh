Index: ChangeLog
===================================================================
--- ChangeLog	(revision 173217)
+++ ChangeLog	(working copy)
@@ -1,5 +1,22 @@
 2007-06-05  Jules Bergmann  <jules@codesourcery.com>
 
+	* tests/coverage_ternary.cpp: Delete file, split into ...
+	* tests/coverage_ternary_ma.cpp: New file, ... this.
+	* tests/coverage_ternary_am.cpp: New file, ... this.
+	* tests/coverage_ternary_msb.cpp: New file, ... this.
+	* tests/coverage_ternary_sbm.cpp: New file, ... and this.
+	* tests/coverage_common.hpp (TEST_BINARY_OP): New macro.
+	* tests/coverage_binary.cpp: Split add/sub/mul/div into ...
+	* tests/coverage_binary_add.cpp: ... here.
+	* tests/coverage_binary_sub.cpp: ... here.
+	* tests/coverage_binary_mul.cpp: ... here.
+	* tests/coverage_binary_div.cpp: ... and here.
+	* tests/parallel/block.cpp: Split par assign tests into ...
+	* tests/parallel/assign.cpp: New file, ... here.
+	* tests/util-par.hpp (check_local_view): Common function.
+
+2007-06-05  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/simd/simd.hpp: Fix compilation errors.  Workaround
 	  ppu-g++ handling of vec_cmple.
 
Index: tests/coverage_ternary_msb.cpp
===================================================================
--- tests/coverage_ternary_msb.cpp	(revision 0)
+++ tests/coverage_ternary_msb.cpp	(revision 0)
@@ -0,0 +1,52 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/coverage_ternary_msb.hpp
+    @author  Jules Bergmann
+    @date    2005-09-13
+    @brief   VSIPL++ Library: Coverage tests for ternary expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include "coverage_common.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Ternary Operator Tests
+***********************************************************************/
+
+TEST_TERNARY(msb, msb, *, -, *, -)
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
+  test_ternary<Test_msb>();
+}
Index: tests/coverage_common.hpp
===================================================================
--- tests/coverage_common.hpp	(revision 173072)
+++ tests/coverage_common.hpp	(working copy)
@@ -130,6 +130,46 @@
   Binary Operator Tests
 ***********************************************************************/
 
+#define TEST_BINARY_OP(NAME, OP, CHKOP, RT)				\
+struct Test_##NAME							\
+{									\
+  template <typename View1,						\
+	    typename View2,						\
+	    typename View3>						\
+  static void								\
+  exec(									\
+    View1 view1,							\
+    View2 view2,							\
+    View3 view3)							\
+  {									\
+    length_type size = get_size(view3);					\
+    test_assert(Is_scalar<View1>::value || get_size(view1) == size);	\
+    test_assert(Is_scalar<View2>::value || get_size(view2) == size);	\
+									\
+    typedef typename Value_type_of<View1>::type T1;			\
+    typedef typename Value_type_of<View2>::type T2;			\
+    typedef typename Value_type_of<View3>::type T3;			\
+  									\
+    for (index_type i=0; i<get_size(view1); ++i)			\
+      put_nth(view1, i, Get_value<T1>::at(0, i));			\
+    for (index_type i=0; i<get_size(view2); ++i)			\
+      put_nth(view2, i, Get_value<T2>::at(1, i, RT));			\
+    									\
+    view3 = view1 OP view2;						\
+									\
+    for (index_type i=0; i<get_size(view3); ++i)			\
+    {									\
+      T3 expected =							\
+        (Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)		\
+	 CHKOP								\
+	 Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i, RT));	\
+      test_assert(equal(get_nth(view3, i), expected));			\
+    }									\
+  }									\
+};
+
+
+
 #define TEST_BINARY_FUNC(NAME, FUN, CHKFUN, RT)				\
 struct Test_##NAME							\
 {									\
@@ -170,6 +210,68 @@
 
 
 /***********************************************************************
+  Ternary Operator Tests
+***********************************************************************/
+
+#define TEST_TERNARY(NAME, FCN, OP1, OP2, CHKOP1, CHKOP2)		\
+struct Test_##NAME							\
+{									\
+  template <typename View1,						\
+	    typename View2,						\
+	    typename View3,						\
+	    typename View4>						\
+  static void								\
+  exec(									\
+    View1 view1,							\
+    View2 view2,							\
+    View3 view3,							\
+    View4 view4)	/* Result */					\
+  {									\
+    length_type size = get_size(view4);					\
+    test_assert(Is_scalar<View1>::value || get_size(view1) == size);	\
+    test_assert(Is_scalar<View2>::value || get_size(view2) == size);	\
+    test_assert(Is_scalar<View3>::value || get_size(view3) == size);	\
+    									\
+    typedef typename Value_type_of<View1>::type T1;			\
+    typedef typename Value_type_of<View2>::type T2;			\
+    typedef typename Value_type_of<View3>::type T3;			\
+    typedef typename Value_type_of<View4>::type T4;			\
+									\
+    for (index_type i=0; i<get_size(view1); ++i)			\
+      put_nth(view1, i, Get_value<T1>::at(0, i));			\
+    for (index_type i=0; i<get_size(view2); ++i)			\
+      put_nth(view2, i, Get_value<T2>::at(1, i));			\
+    for (index_type i=0; i<get_size(view3); ++i)			\
+      put_nth(view3, i, Get_value<T2>::at(2, i));			\
+    									\
+    view4 = FCN(view1, view2, view3);					\
+    									\
+    for (index_type i=0; i<get_size(view4); ++i)			\
+    {									\
+      T4 expected =							\
+	(       Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)	\
+	 CHKOP1 Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i))	\
+	 CHKOP2 Get_value<T3>::at(2, Is_scalar<View3>::value ? 0 : i);	\
+      test_assert(equal(get_nth(view4, i), expected));			\
+    }									\
+    									\
+    view4 = T4();							\
+    view4 = (view1 OP1 view2) OP2 view3;				\
+    									\
+    for (index_type i=0; i<get_size(view4); ++i)			\
+    {									\
+      T4 expected =							\
+	(       Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)	\
+	 CHKOP1 Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i))	\
+	 CHKOP2 Get_value<T3>::at(2, Is_scalar<View3>::value ? 0 : i);	\
+      test_assert(equal(get_nth(view4, i), expected));			\
+    }									\
+  }									\
+};
+
+
+
+/***********************************************************************
   Test Drivers
 ***********************************************************************/
 
@@ -586,5 +688,25 @@
 }
 
 
+template <typename TestC>
+void
+test_ternary()
+{
+  using vsip::complex;
 
+  vector_cases4<TestC, float,           float,           float>();
+  vector_cases4<TestC, complex<float>,  complex<float>,  complex<float> >();
+#if VSIP_IMPL_TEST_LEVEL > 0
+  vector_cases4<TestC, double,          double,          double>();
+  vector_cases4<TestC, complex<double>, complex<double>, complex<double> >();
+#endif
+
+#if VSIP_IMPL_TEST_LEVEL > 0
+  matrix_cases4<TestC, float, float, float>();
+#endif
+}
+
+
+
+
 #endif // TESTS_COMMON_COVERAGE_HPP
Index: tests/coverage_binary_sub.cpp
===================================================================
--- tests/coverage_binary_sub.cpp	(revision 0)
+++ tests/coverage_binary_sub.cpp	(revision 0)
@@ -0,0 +1,69 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/coverage_binary_sub.hpp
+    @author  Jules Bergmann
+    @date    2005-09-13
+    @brief   VSIPL++ Library: Coverage tests for sub binary expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include "coverage_common.hpp"
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
+TEST_BINARY_OP(sub,  -,  -,  anyval)
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
+#if VSIP_IMPL_TEST_LEVEL == 0
+  vector_cases3<Test_sub,  float,           float>();
+#else
+
+  vector_cases3<Test_sub, int,             int>();
+  vector_cases3<Test_sub, float,           float>();
+  vector_cases3<Test_sub, complex<float>,  complex<float> >();
+  vector_cases3<Test_sub, complex<float>,  float>();
+#if VSIP_IMPL_TEST_DOUBLE
+  vector_cases3<Test_sub, double,          double>();
+  vector_cases3<Test_sub, complex<double>, complex<double> >();
+#endif
+
+  matrix_cases3<Test_sub, float,          float>();
+  matrix_cases3<Test_sub, complex<float>, complex<float> >();
+#endif
+
+  return EXIT_SUCCESS;
+}
Index: tests/coverage_binary_mul.cpp
===================================================================
--- tests/coverage_binary_mul.cpp	(revision 0)
+++ tests/coverage_binary_mul.cpp	(revision 0)
@@ -0,0 +1,73 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/coverage_binary_mul.hpp
+    @author  Jules Bergmann
+    @date    2005-09-13
+    @brief   VSIPL++ Library: Coverage tests for binary expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include "coverage_common.hpp"
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
+TEST_BINARY_OP(mul,  *,  *,  anyval)
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
+#if VSIP_IMPL_TEST_LEVEL == 0
+  vector_cases3<Test_mul,  complex<float>,  complex<float> >();
+  vector_cases3<Test_mul,  float,           complex<float> >();
+#else
+
+  vector_cases3<Test_mul, int,             int>();
+  vector_cases3<Test_mul, float,           float>();
+  vector_cases3<Test_mul, complex<float>,  complex<float> >();
+  vector_cases3<Test_mul, float,           complex<float> >();
+  vector_cases3<Test_mul, complex<float>,  float>();
+#if VSIP_IMPL_TEST_DOUBLE
+  vector_cases3<Test_mul, double,          double>();
+  vector_cases3<Test_mul, complex<double>, complex<double> >();
+#endif
+  matrix_cases3<Test_mul, complex<float>,  complex<float> >();
+
+
+  matrix_cases3<Test_mul, float, float>();
+  matrix_cases3<Test_mul, complex<float>, complex<float> >();
+#endif
+
+  return EXIT_SUCCESS;
+}
Index: tests/coverage_ternary.cpp
===================================================================
--- tests/coverage_ternary.cpp	(revision 173072)
+++ tests/coverage_ternary.cpp	(working copy)
@@ -1,366 +0,0 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
-
-   This file is available for license from CodeSourcery, Inc. under the terms
-   of a commercial license and under the GPL.  It is not part of the VSIPL++
-   reference implementation and is not available under the BSD license.
-*/
-/** @file    tests/coverage_ternary.hpp
-    @author  Jules Bergmann
-    @date    2005-09-13
-    @brief   VSIPL++ Library: Coverage tests for ternary expressions.
-*/
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <iostream>
-
-#include <vsip/support.hpp>
-#include <vsip/initfin.hpp>
-#include <vsip/vector.hpp>
-#include <vsip/math.hpp>
-#include <vsip/random.hpp>
-
-#include <vsip_csl/test.hpp>
-#include <vsip_csl/test-storage.hpp>
-#include "coverage_common.hpp"
-
-using namespace std;
-using namespace vsip;
-using namespace vsip_csl;
-
-
-/***********************************************************************
-  Ternary Operator Tests
-***********************************************************************/
-
-/// Test ternary 'ma' (and nested */+) expressions
-
-struct Test_ma
-{
-  template <typename View1,
-	    typename View2,
-	    typename View3,
-	    typename View4>
-  static void
-  exec(
-    View1 view1,
-    View2 view2,
-    View3 view3,
-    View4 view4)	// Result
-  {
-    length_type size = get_size(view4);
-    test_assert(Is_scalar<View1>::value || get_size(view1) == size);
-    test_assert(Is_scalar<View2>::value || get_size(view2) == size);
-    test_assert(Is_scalar<View3>::value || get_size(view3) == size);
-
-    typedef typename Value_type_of<View1>::type T1;
-    typedef typename Value_type_of<View2>::type T2;
-    typedef typename Value_type_of<View3>::type T3;
-    typedef typename Value_type_of<View4>::type T4;
-
-    for (index_type i=0; i<get_size(view1); ++i)
-      put_nth(view1, i, Get_value<T1>::at(0, i));
-    for (index_type i=0; i<get_size(view2); ++i)
-      put_nth(view2, i, Get_value<T2>::at(1, i));
-    for (index_type i=0; i<get_size(view3); ++i)
-      put_nth(view3, i, Get_value<T2>::at(2, i));
-  
-    view4 = ma(view1, view2, view3);
-
-    for (index_type i=0; i<get_size(view4); ++i)
-    {
-      T4 expected = Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)
-	          * Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i)
-	          + Get_value<T3>::at(2, Is_scalar<View3>::value ? 0 : i);
-      test_assert(equal(get_nth(view4, i), expected));
-    }
-    
-    view4 = T4();
-    view4 = view1 * view2 + view3;
-
-    for (index_type i=0; i<get_size(view4); ++i)
-    {
-      T4 expected = Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)
-	          * Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i)
-	          + Get_value<T3>::at(2, Is_scalar<View3>::value ? 0 : i);
-      test_assert(equal(get_nth(view4, i), expected));
-    }
-  }
-};
-
-
-
-/// Test ternary 'cma' (and nested conj(*)/+) expressions
-
-struct Test_cma
-{
-  template <typename View1,
-	    typename View2,
-	    typename View3,
-	    typename View4>
-  static void
-  exec(
-    View1 view1,
-    View2 view2,
-    View3 view3,
-    View4 view4)	// Result
-  {
-    length_type size = get_size(view4);
-    test_assert(Is_scalar<View1>::value || get_size(view1) == size);
-    test_assert(Is_scalar<View2>::value || get_size(view2) == size);
-    test_assert(Is_scalar<View3>::value || get_size(view3) == size);
-
-    typedef typename Value_type_of<View1>::type T1;
-    typedef typename Value_type_of<View2>::type T2;
-    typedef typename Value_type_of<View3>::type T3;
-    typedef typename Value_type_of<View4>::type T4;
-
-    for (index_type i=0; i<get_size(view1); ++i)
-      put_nth(view1, i, T1(2*i + 1));
-    for (index_type i=0; i<get_size(view2); ++i)
-      put_nth(view2, i, T2(3*i + 2));
-    for (index_type i=0; i<get_size(view3); ++i)
-      put_nth(view3, i, T3(5*i + 3));
-  
-    view4 = ma(conj(view1), view2, view3);
-
-    for (index_type i=0; i<get_size(view4); ++i)
-    {
-      T4 expected = conj(T1(Is_scalar<View1>::value ? (2*0+1) : (2*i+1)))
-	          *      T2(Is_scalar<View2>::value ? (3*0+2) : (3*i+2))
-	          +      T3(Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
-      test_assert(equal(get_nth(view4, i), T4(expected)));
-    }
-    
-    view4 = T4();
-    view4 = conj(view1) * view2 + view3;
-
-    for (index_type i=0; i<get_size(view4); ++i)
-    {
-      T4 expected = conj(T1(Is_scalar<View1>::value ? (2*0+1) : (2*i+1)))
-	          *      T2(Is_scalar<View2>::value ? (3*0+2) : (3*i+2))
-	          +      T3(Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
-      test_assert(equal(get_nth(view4, i), T4(expected)));
-    }
-  }
-};
-
-
-
-/// Test ternary 'msb' (and nested */-) expressions
-
-struct Test_msb
-{
-  template <typename View1,
-	    typename View2,
-	    typename View3,
-	    typename View4>
-  static void
-  exec(
-    View1 view1,
-    View2 view2,
-    View3 view3,
-    View4 view4)	// Result
-  {
-    length_type size = get_size(view4);
-    test_assert(Is_scalar<View1>::value || get_size(view1) == size);
-    test_assert(Is_scalar<View2>::value || get_size(view2) == size);
-    test_assert(Is_scalar<View3>::value || get_size(view3) == size);
-
-    typedef typename Value_type_of<View1>::type T1;
-    typedef typename Value_type_of<View2>::type T2;
-    typedef typename Value_type_of<View3>::type T3;
-    typedef typename Value_type_of<View4>::type T4;
-
-    for (index_type i=0; i<get_size(view1); ++i)
-      put_nth(view1, i, T1(2*i + 1));
-    for (index_type i=0; i<get_size(view2); ++i)
-      put_nth(view2, i, T2(3*i + 2));
-    for (index_type i=0; i<get_size(view3); ++i)
-      put_nth(view3, i, T3(5*i + 3));
-  
-    view4 = msb(view1, view2, view3);
-
-    for (index_type i=0; i<get_size(view4); ++i)
-    {
-      int expected = (Is_scalar<View1>::value ? (2*0+1) : (2*i+1))
-	           * (Is_scalar<View2>::value ? (3*0+2) : (3*i+2))
-	           - (Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
-      test_assert(equal(get_nth(view4, i), T4(expected)));
-    }
-    
-    view4 = T4();
-    view4 = view1 * view2 - view3;
-
-    for (index_type i=0; i<get_size(view4); ++i)
-    {
-      int expected = (Is_scalar<View1>::value ? (2*0+1) : (2*i+1))
-	           * (Is_scalar<View2>::value ? (3*0+2) : (3*i+2))
-	           - (Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
-      test_assert(equal(get_nth(view4, i), T4(expected)));
-    }
-  }
-};
-
-
-
-/// Test ternary 'am' (and nested +/*) expressions
-
-struct Test_am
-{
-  template <typename View1,
-	    typename View2,
-	    typename View3,
-	    typename View4>
-  static void
-  exec(
-    View1 view1,
-    View2 view2,
-    View3 view3,
-    View4 view4)	// Result
-  {
-    length_type size = get_size(view4);
-    test_assert(Is_scalar<View1>::value || get_size(view1) == size);
-    test_assert(Is_scalar<View2>::value || get_size(view2) == size);
-    test_assert(Is_scalar<View3>::value || get_size(view3) == size);
-
-    typedef typename Value_type_of<View1>::type T1;
-    typedef typename Value_type_of<View2>::type T2;
-    typedef typename Value_type_of<View3>::type T3;
-    typedef typename Value_type_of<View4>::type T4;
-
-    for (index_type i=0; i<get_size(view1); ++i)
-      put_nth(view1, i, T1(2*i + 1));
-    for (index_type i=0; i<get_size(view2); ++i)
-      put_nth(view2, i, T2(3*i + 2));
-    for (index_type i=0; i<get_size(view3); ++i)
-      put_nth(view3, i, T3(5*i + 3));
-  
-    view4 = am(view1, view2, view3);
-
-    for (index_type i=0; i<get_size(view4); ++i)
-    {
-      int expected = ( (Is_scalar<View1>::value ? (2*0+1) : (2*i+1))
-		     + (Is_scalar<View2>::value ? (3*0+2) : (3*i+2)) )
-	           * (Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
-      test_assert(equal(get_nth(view4, i), T4(expected)));
-    }
-    
-    view4 = T4();
-    view4 = (view1 + view2) * view3;
-
-    for (index_type i=0; i<get_size(view4); ++i)
-    {
-      int expected = ( (Is_scalar<View1>::value ? (2*0+1) : (2*i+1))
-		     + (Is_scalar<View2>::value ? (3*0+2) : (3*i+2)) )
-	           * (Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
-      test_assert(equal(get_nth(view4, i), T4(expected)));
-    }
-  }
-};
-
-
-
-/// Test ternary 'sbm' (and nested -/*) expressions
-
-struct Test_sbm
-{
-  template <typename View1,
-	    typename View2,
-	    typename View3,
-	    typename View4>
-  static void
-  exec(
-    View1 view1,
-    View2 view2,
-    View3 view3,
-    View4 view4)	// Result
-  {
-    length_type size = get_size(view4);
-    test_assert(Is_scalar<View1>::value || get_size(view1) == size);
-    test_assert(Is_scalar<View2>::value || get_size(view2) == size);
-    test_assert(Is_scalar<View3>::value || get_size(view3) == size);
-
-    typedef typename Value_type_of<View1>::type T1;
-    typedef typename Value_type_of<View2>::type T2;
-    typedef typename Value_type_of<View3>::type T3;
-    typedef typename Value_type_of<View4>::type T4;
-
-    for (index_type i=0; i<get_size(view1); ++i)
-      put_nth(view1, i, T1(2*i + 1));
-    for (index_type i=0; i<get_size(view2); ++i)
-      put_nth(view2, i, T2(3*i + 2));
-    for (index_type i=0; i<get_size(view3); ++i)
-      put_nth(view3, i, T3(5*i + 3));
-  
-    view4 = sbm(view1, view2, view3);
-
-    for (index_type i=0; i<get_size(view4); ++i)
-    {
-      int expected = ( (Is_scalar<View1>::value ? (2*0+1) : (2*i+1))
-		     - (Is_scalar<View2>::value ? (3*0+2) : (3*i+2)) )
-	           * (Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
-      test_assert(equal(get_nth(view4, i), T4(expected)));
-    }
-    
-    view4 = T4();
-    view4 = (view1 - view2) * view3;
-
-    for (index_type i=0; i<get_size(view4); ++i)
-    {
-      int expected = ( (Is_scalar<View1>::value ? (2*0+1) : (2*i+1))
-		     - (Is_scalar<View2>::value ? (3*0+2) : (3*i+2)) )
-	           * (Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
-      test_assert(equal(get_nth(view4, i), T4(expected)));
-    }
-  }
-};
-
-
-
-/***********************************************************************
-  Main
-***********************************************************************/
-
-int
-main(int argc, char** argv)
-{
-  vsipl init(argc, argv);
-
-  // Ternary Operators
-  vector_cases4<Test_ma, float,  float,  float>();
-  vector_cases4<Test_ma, complex<float>,  complex<float>, complex<float> >();
-#if VSIP_IMPL_TEST_LEVEL > 0
-  vector_cases4<Test_ma, double, double, double>();
-  vector_cases4<Test_ma, complex<double>, complex<double>,complex<double> >();
-#endif
-
-  vector_cases4<Test_cma, complex<float>,  complex<float>, complex<float> >();
-
-  vector_cases4<Test_msb, float,  float,  float>();
-  vector_cases4<Test_msb, complex<float>,  complex<float>, complex<float> >();
-#if VSIP_IMPL_TEST_LEVEL > 0
-  vector_cases4<Test_msb, double, double, double>();
-  vector_cases4<Test_msb, complex<double>, complex<double>,complex<double> >();
-#endif
-
-  vector_cases4<Test_am, float,           float,          float>();
-  vector_cases4<Test_am, complex<float>,  complex<float>, complex<float> >();
-#if VSIP_IMPL_TEST_LEVEL > 0
-  vector_cases4<Test_am, double,          double,         double>();
-  vector_cases4<Test_am, complex<double>, complex<double>,complex<double> >();
-#endif
-
-  vector_cases4<Test_sbm, float,           float,          float>();
-  vector_cases4<Test_sbm, complex<float>,  complex<float>, complex<float> >();
-#if VSIP_IMPL_TEST_LEVEL > 0
-  vector_cases4<Test_sbm, double,          double,         double>();
-  vector_cases4<Test_sbm, complex<double>, complex<double>,complex<double> >();
-#endif
-
-#if VSIP_IMPL_TEST_LEVEL > 0
-  matrix_cases4<Test_ma, float, float, float>();
-#endif
-}
Index: tests/coverage_ternary_am.cpp
===================================================================
--- tests/coverage_ternary_am.cpp	(revision 0)
+++ tests/coverage_ternary_am.cpp	(revision 0)
@@ -0,0 +1,52 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/coverage_ternary_am.hpp
+    @author  Jules Bergmann
+    @date    2005-09-13
+    @brief   VSIPL++ Library: Coverage tests for am ternary expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include "coverage_common.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Ternary Operator Tests
+***********************************************************************/
+
+TEST_TERNARY(am, am, +, *, +, *)
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
+  test_ternary<Test_am>();
+}
Index: tests/coverage_ternary_ma.cpp
===================================================================
--- tests/coverage_ternary_ma.cpp	(revision 0)
+++ tests/coverage_ternary_ma.cpp	(revision 0)
@@ -0,0 +1,111 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/coverage_ternary_ma.hpp
+    @author  Jules Bergmann
+    @date    2005-09-13
+    @brief   VSIPL++ Library: Coverage tests for ma ternary expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include "coverage_common.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+
+/***********************************************************************
+  Ternary Operator Tests
+***********************************************************************/
+
+TEST_TERNARY(ma, ma, *, +, *, +)
+
+/// Test ternary 'cma' (and nested conj(*)/+) expressions
+
+struct Test_cma
+{
+  template <typename View1,
+	    typename View2,
+	    typename View3,
+	    typename View4>
+  static void
+  exec(
+    View1 view1,
+    View2 view2,
+    View3 view3,
+    View4 view4)	// Result
+  {
+    length_type size = get_size(view4);
+    test_assert(Is_scalar<View1>::value || get_size(view1) == size);
+    test_assert(Is_scalar<View2>::value || get_size(view2) == size);
+    test_assert(Is_scalar<View3>::value || get_size(view3) == size);
+
+    typedef typename Value_type_of<View1>::type T1;
+    typedef typename Value_type_of<View2>::type T2;
+    typedef typename Value_type_of<View3>::type T3;
+    typedef typename Value_type_of<View4>::type T4;
+
+    for (index_type i=0; i<get_size(view1); ++i)
+      put_nth(view1, i, T1(2*i + 1));
+    for (index_type i=0; i<get_size(view2); ++i)
+      put_nth(view2, i, T2(3*i + 2));
+    for (index_type i=0; i<get_size(view3); ++i)
+      put_nth(view3, i, T3(5*i + 3));
+  
+    view4 = ma(conj(view1), view2, view3);
+
+    for (index_type i=0; i<get_size(view4); ++i)
+    {
+      T4 expected = conj(T1(Is_scalar<View1>::value ? (2*0+1) : (2*i+1)))
+	          *      T2(Is_scalar<View2>::value ? (3*0+2) : (3*i+2))
+	          +      T3(Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
+      test_assert(equal(get_nth(view4, i), T4(expected)));
+    }
+    
+    view4 = T4();
+    view4 = conj(view1) * view2 + view3;
+
+    for (index_type i=0; i<get_size(view4); ++i)
+    {
+      T4 expected = conj(T1(Is_scalar<View1>::value ? (2*0+1) : (2*i+1)))
+	          *      T2(Is_scalar<View2>::value ? (3*0+2) : (3*i+2))
+	          +      T3(Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
+      test_assert(equal(get_nth(view4, i), T4(expected)));
+    }
+  }
+};
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
+  test_ternary<Test_ma>();
+
+  // special coverage.
+  vector_cases4<Test_cma, complex<float>,  complex<float>, complex<float> >();
+}
Index: tests/coverage_binary_div.cpp
===================================================================
--- tests/coverage_binary_div.cpp	(revision 0)
+++ tests/coverage_binary_div.cpp	(revision 0)
@@ -0,0 +1,70 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/coverage_binary.hpp
+    @author  Jules Bergmann
+    @date    2005-09-13
+    @brief   VSIPL++ Library: Coverage tests for div binary expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include "coverage_common.hpp"
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
+TEST_BINARY_OP(div,  /,  /,  nonzero)
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
+#if VSIP_IMPL_TEST_LEVEL == 0
+  vector_cases3<Test_div,  complex<float>,  float>();
+#else
+
+  vector_cases3<Test_div, int,             int>();
+  vector_cases3<Test_div, float,           float>();
+  vector_cases3<Test_div, complex<float>,  complex<float> >();
+  vector_cases3<Test_div, complex<float>,  float>();
+#if VSIP_IMPL_TEST_DOUBLE
+  vector_cases3<Test_div, double,          double>();
+  vector_cases3<Test_div, complex<double>, complex<double> >();
+#endif
+
+
+  matrix_cases3<Test_div, float, float>();
+  matrix_cases3<Test_div, complex<float>, complex<float> >();
+#endif
+
+  return EXIT_SUCCESS;
+}
Index: tests/coverage_binary_add.cpp
===================================================================
--- tests/coverage_binary_add.cpp	(revision 0)
+++ tests/coverage_binary_add.cpp	(revision 0)
@@ -0,0 +1,71 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/coverage_binary_add.hpp
+    @author  Jules Bergmann
+    @date    2005-09-13
+    @brief   VSIPL++ Library: Coverage tests for binary expressions -- add.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include "coverage_common.hpp"
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
+TEST_BINARY_OP(add,  +,  +,  anyval)
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
+#if VSIP_IMPL_TEST_LEVEL == 0
+  vector_cases3<Test_add,  int,             int>();
+#else
+
+  // Binary Operators
+  vector_cases3<Test_add, int,             int>();
+  vector_cases3<Test_add, float,           float>();
+  vector_cases3<Test_add, complex<float>,  complex<float> >();
+  vector_cases3<Test_add, float,           complex<float> >();
+  vector_cases3<Test_add, complex<float>,  float>();
+#if VSIP_IMPL_TEST_DOUBLE
+  vector_cases3<Test_add, double,          double>();
+  vector_cases3<Test_add, complex<double>, complex<double> >();
+#endif
+
+  matrix_cases3<Test_add, float,           float>();
+  matrix_cases3<Test_add, complex<float>,  complex<float> >();
+#endif // VSIP_IMPL_TEST_LEVEL == 0
+
+  return EXIT_SUCCESS;
+}
Index: tests/coverage_binary.cpp
===================================================================
--- tests/coverage_binary.cpp	(revision 173072)
+++ tests/coverage_binary.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -46,167 +46,6 @@
 
 
 
-/// Test '+' expression
-
-struct Test_add
-{
-  template <typename View1,
-	    typename View2,
-	    typename View3>
-  static void
-  exec(
-    View1 view1,
-    View2 view2,
-    View3 view3)
-  {
-    length_type size = get_size(view3);
-    test_assert(Is_scalar<View1>::value || get_size(view1) == size);
-    test_assert(Is_scalar<View2>::value || get_size(view2) == size);
-
-    typedef typename Value_type_of<View1>::type T1;
-    typedef typename Value_type_of<View2>::type T2;
-    typedef typename Value_type_of<View3>::type T3;
-  
-    for (index_type i=0; i<get_size(view1); ++i)
-      put_nth(view1, i, Get_value<T1>::at(0, i));
-    for (index_type i=0; i<get_size(view2); ++i)
-      put_nth(view2, i, Get_value<T2>::at(1, i));
-    
-    view3 = view1 + view2;
-
-    for (index_type i=0; i<get_size(view3); ++i)
-    {
-      T3 expected = Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)
-	          + Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i);
-      test_assert(equal(get_nth(view3, i), expected));
-    }
-  }
-};
-
-
-
-/// Test '-' expression
-
-struct Test_sub
-{
-  template <typename View1,
-	    typename View2,
-	    typename View3>
-  static void
-  exec(
-    View1 view1,
-    View2 view2,
-    View3 view3)
-  {
-    length_type size = get_size(view3);
-    test_assert(Is_scalar<View1>::value || get_size(view1) == size);
-    test_assert(Is_scalar<View2>::value || get_size(view2) == size);
-
-    typedef typename Value_type_of<View1>::type T1;
-    typedef typename Value_type_of<View2>::type T2;
-    typedef typename Value_type_of<View3>::type T3;
-  
-    for (index_type i=0; i<get_size(view1); ++i)
-      put_nth(view1, i, Get_value<T1>::at(0, i));
-    for (index_type i=0; i<get_size(view2); ++i)
-      put_nth(view2, i, Get_value<T2>::at(1, i));
-    
-    view3 = view1 - view2;
-
-    for (index_type i=0; i<get_size(view3); ++i)
-    {
-      T3 expected = Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)
-	          - Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i);
-      test_assert(equal(get_nth(view3, i), T3(expected)));
-    }
-  }
-};
-
-
-
-/// Test '*' expression
-
-struct Test_mul
-{
-  template <typename View1,
-	    typename View2,
-	    typename View3>
-  static void
-  exec(
-    View1 view1,
-    View2 view2,
-    View3 view3)
-  {
-    length_type size = get_size(view3);
-    test_assert(Is_scalar<View1>::value || get_size(view1) == size);
-    test_assert(Is_scalar<View2>::value || get_size(view2) == size);
-
-    typedef typename Value_type_of<View1>::type T1;
-    typedef typename Value_type_of<View2>::type T2;
-    typedef typename Value_type_of<View3>::type T3;
-  
-    // Initialize result first, in case we're doing an in-place operation.
-    for (index_type i=0; i<get_size(view3); ++i)
-      put_nth(view3, i, T3());
-
-    for (index_type i=0; i<get_size(view1); ++i)
-      put_nth(view1, i, Get_value<T1>::at(0, i));
-    for (index_type i=0; i<get_size(view2); ++i)
-      put_nth(view2, i, Get_value<T2>::at(1, i));
-    
-    view3 = view1 * view2;
-
-    for (index_type i=0; i<get_size(view3); ++i)
-    {
-      T3 expected = Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)
-	          * Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i);
-      test_assert(equal(get_nth(view3, i), T3(expected)));
-    }
-  }
-};
-
-
-
-/// Test '/' expression
-
-struct Test_div
-{
-  template <typename View1,
-	    typename View2,
-	    typename View3>
-  static void
-  exec(
-    View1 view1,
-    View2 view2,
-    View3 view3)
-  {
-    length_type size = get_size(view3);
-    test_assert(Is_scalar<View1>::value || get_size(view1) == size);
-    test_assert(Is_scalar<View2>::value || get_size(view2) == size);
-
-    typedef typename Value_type_of<View1>::type T1;
-    typedef typename Value_type_of<View2>::type T2;
-    typedef typename Value_type_of<View3>::type T3;
-
-    for (index_type i=0; i<get_size(view1); ++i)
-      put_nth(view1, i, Get_value<T1>::at(0, i));
-    for (index_type i=0; i<get_size(view2); ++i)
-      put_nth(view2, i, Get_value<T2>::at(1, i, nonzero));
-    
-    view3 = view1 / view2;
-
-    for (index_type i=0; i<get_size(view3); ++i)
-    {
-      T3 expected =
-	  Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)
-	/ Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i, nonzero);
-      test_assert(equal(get_nth(view3, i), expected));
-    }
-  }
-};
-
-
-
 /***********************************************************************
   Main
 ***********************************************************************/
@@ -217,75 +56,29 @@
   vsipl init(argc, argv);
 
 #if VSIP_IMPL_TEST_LEVEL == 0
-  vector_cases3<Test_add,  int,             int>();
-  vector_cases3<Test_sub,  float,           float>();
-  vector_cases3<Test_mul,  complex<float>,  complex<float> >();
-  vector_cases3<Test_mul,  float,           complex<float> >();
-  vector_cases3<Test_div,  complex<float>,  float>();
-  vector_cases3<Test_max,  float,           float>();
-  vector_cases3<Test_min,  float,           float>();
-  vector_cases3<Test_band, int,           int>();
-  vector_cases3<Test_lxor, bool,          bool>();
-  matrix_cases3<Test_add,  float, float>();
+  vector_cases3<Test_max,  float,  float>();
+  vector_cases3<Test_min,  float,  float>();
+  vector_cases3<Test_band, int,    int>();
+  vector_cases3<Test_lxor, bool,   bool>();
+  matrix_cases3<Test_add,  float,  float>();
 #else
 
-  // Binary Operators
-  vector_cases3<Test_add, int,             int>();
-  vector_cases3<Test_add, float,           float>();
-  vector_cases3<Test_add, complex<float>,  complex<float> >();
-  vector_cases3<Test_add, float,           complex<float> >();
-  vector_cases3<Test_add, complex<float>,  float>();
-#if VSIP_IMPL_TEST_DOUBLE
-  vector_cases3<Test_add, double,          double>();
-  vector_cases3<Test_add, complex<double>, complex<double> >();
-#endif
+  vector_cases3<Test_max, float,   float>();
+  vector_cases3<Test_min, float,   float>();
 
-  vector_cases3<Test_sub, int,             int>();
-  vector_cases3<Test_sub, float,           float>();
-  vector_cases3<Test_sub, complex<float>,  complex<float> >();
-  vector_cases3<Test_sub, complex<float>,  float>();
 #if VSIP_IMPL_TEST_DOUBLE
-  vector_cases3<Test_sub, double,          double>();
-  vector_cases3<Test_sub, complex<double>, complex<double> >();
+  vector_cases3<Test_max, double,  double>();
+  vector_cases3<Test_min, double,  double>();
 #endif
 
-  vector_cases3<Test_mul, int,             int>();
-  vector_cases3<Test_mul, float,           float>();
-  vector_cases3<Test_mul, complex<float>,  complex<float> >();
-  vector_cases3<Test_mul, float,           complex<float> >();
-  vector_cases3<Test_mul, complex<float>,  float>();
-#if VSIP_IMPL_TEST_DOUBLE
-  vector_cases3<Test_mul, double,          double>();
-  vector_cases3<Test_mul, complex<double>, complex<double> >();
-#endif
-  matrix_cases3<Test_mul, complex<float>,  complex<float> >();
+  vector_cases3<Test_band, int,    int>();
+  vector_cases3<Test_bor,  int,    int>();
+  vector_cases3<Test_bxor, int,    int>();
 
-  vector_cases3<Test_div, int,             int>();
-  vector_cases3<Test_div, float,           float>();
-  vector_cases3<Test_div, complex<float>,  complex<float> >();
-  vector_cases3<Test_div, complex<float>,  float>();
-#if VSIP_IMPL_TEST_DOUBLE
-  vector_cases3<Test_div, double,          double>();
-  vector_cases3<Test_div, complex<double>, complex<double> >();
+  vector_cases3<Test_land, bool,   bool>();
+  vector_cases3<Test_lor,  bool,   bool>();
+  vector_cases3<Test_lxor, bool,   bool>();
 #endif
 
-  vector_cases3<Test_max, float,           float>();
-  vector_cases3<Test_min, float,           float>();
-
-#if VSIP_IMPL_TEST_DOUBLE
-  vector_cases3<Test_max, double,          double>();
-  vector_cases3<Test_min, double,          double>();
-#endif
-
-  vector_cases3<Test_band, int,           int>();
-  vector_cases3<Test_bor,  int,           int>();
-  vector_cases3<Test_bxor, int,           int>();
-
-  vector_cases3<Test_land, bool,          bool>();
-  vector_cases3<Test_lor,  bool,          bool>();
-  vector_cases3<Test_lxor, bool,          bool>();
-
-
-  matrix_cases3<Test_add, float, float>();
-#endif
+  return EXIT_SUCCESS;
 }
Index: tests/coverage_ternary_sbm.cpp
===================================================================
--- tests/coverage_ternary_sbm.cpp	(revision 0)
+++ tests/coverage_ternary_sbm.cpp	(revision 0)
@@ -0,0 +1,52 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/coverage_ternary_sbm.hpp
+    @author  Jules Bergmann
+    @date    2005-09-13
+    @brief   VSIPL++ Library: Coverage tests for sbm ternary expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include "coverage_common.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Ternary Operator Tests
+***********************************************************************/
+
+TEST_TERNARY(sbm, sbm, -, *, -, *)
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
+  test_ternary<Test_sbm>();
+}
Index: tests/util-par.hpp
===================================================================
--- tests/util-par.hpp	(revision 173072)
+++ tests/util-par.hpp	(working copy)
@@ -96,6 +96,35 @@
 
 
 
+// Check validity of local view.
+
+template <vsip::dimension_type                Dim,
+	  template <typename, typename> class ViewT,
+	  typename                            T,
+	  typename                            BlockT>
+inline void
+check_local_view(
+  ViewT<T, BlockT> view)
+{
+  typedef typename vsip::impl::Distributed_local_block<BlockT>::type
+          local_block_t;
+
+  typename BlockT::map_type const& map = view.block().map();
+  typename ViewT<T, BlockT>::local_type lview = view.local();
+
+  vsip::index_type sb = map.subblock();
+
+  vsip::Domain<Dim> dom = subblock_domain(view, sb);
+  test_assert(lview.size() == vsip::impl::size(dom));
+  for (vsip::dimension_type d=0; d<Dim; ++d)
+    test_assert(lview.size(d) == dom[d].size());
+
+  if (sb == vsip::no_subblock)
+    test_assert(lview.size() == 0);
+}
+
+
+
 // Syncronize processors and print message to screen.
 
 template <typename Map>
Index: tests/parallel/assign.cpp
===================================================================
--- tests/parallel/assign.cpp	(revision 0)
+++ tests/parallel/assign.cpp	(revision 0)
@@ -0,0 +1,203 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/parallel/assign.cpp
+    @author  Jules Bergmann
+    @date    2005-03-22
+    @brief   VSIPL++ Library: Unit tests for parallel assignment.
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
+#include <vsip/map.hpp>
+#include <vsip/tensor.hpp>
+#include <vsip/parallel.hpp>
+#include <vsip/core/length.hpp>
+#include <vsip/core/domain_utils.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
+#include "util.hpp"
+#include "util-par.hpp"
+
+#define IMPL_TAG impl::par_assign_impl_type
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+using vsip::impl::Length;
+using vsip::impl::extent;
+using vsip::impl::View_of_dim;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Test a single parallel assignment.
+
+template <typename                  T,
+	  dimension_type            Dim,
+	  typename                  Map1,
+	  typename                  Map2>
+void
+test_par_assign(
+  Domain<Dim> dom,
+  Map1        map1,
+  Map2        map2,
+  int         loop)
+
+{
+  typedef typename impl::Row_major<Dim>::type order_type;
+
+  typedef Dense<Dim, T, order_type, Map1>   dist_block1_t;
+  typedef Dense<Dim, T, order_type, Map2>   dist_block2_t;
+
+  typedef typename View_of_dim<Dim, T, dist_block1_t>::type view1_t;
+  typedef typename View_of_dim<Dim, T, dist_block2_t>::type view2_t;
+
+  view1_t view1(create_view<view1_t>(dom, T(), map1));
+  view2_t view2(create_view<view2_t>(dom, T(), map2));
+
+  check_local_view<Dim>(view1);
+  check_local_view<Dim>(view2);
+
+  foreach_point(view1, Set_identity<Dim>(dom));
+  for (int l=0; l<loop; ++l)
+  {
+    view2 = view1;
+  }
+  foreach_point(view2, Check_identity<Dim>(dom));
+}
+
+
+
+template <typename T>
+void
+test_par_assign_cases(int loop)
+{
+  length_type np, nr, nc;
+  get_np_square(np, nr, nc);
+
+  // Vector Serial -> Serial
+  // std::cout << "Global_map<1> -> Global_map<1>\n" << std::flush;
+  test_par_assign<float>(Domain<1>(16),
+			 Global_map<1>(),
+			 Global_map<1>(),
+			 loop);
+
+  test_par_assign<float>(Domain<1>(16),
+			 Replicated_map<1>(),
+			 Replicated_map<1>(),
+			 loop);
+
+  // Vector Serial -> Block_dist
+  // std::cout << "Global_map<1> -> Map<Block_dist>\n" << std::flush;
+  test_par_assign<float>(Domain<1>(16),
+			 Global_map<1>(),
+			 Map<Block_dist>(Block_dist(np)),
+			 loop);
+
+  // Vector Block_dist -> Serial
+  // std::cout << "Map<Block_dist> -> Global_map<1>\n" << std::flush;
+  test_par_assign<float>(Domain<1>(16),
+			 Map<Block_dist>(Block_dist(np)),
+			 Global_map<1>(),
+			 loop);
+
+  // Matrix Serial -> Serial
+  // std::cout << "Global_map<2> -> Global_map<2>\n" << std::flush;
+  test_par_assign<float>(Domain<2>(16, 16),
+			 Global_map<2>(),
+			 Global_map<2>(),
+			 loop);
+
+  // Matrix Serial -> Block_dist
+  // std::cout << "Global_map<2> -> Map<> (square)\n" << std::flush;
+  test_par_assign<float>(Domain<2>(16, 16),
+			 Global_map<2>(),
+			 Map<Block_dist>(Block_dist(nr), Block_dist(nc)),
+			 loop);
+  // std::cout << "Global_map<2> -> Map<> (cols)\n" << std::flush;
+  test_par_assign<float>(Domain<2>(16, 16),
+			 Global_map<2>(),
+			 Map<Block_dist>(Block_dist(1), Block_dist(np)),
+			 loop);
+  // std::cout << "Global_map<2> -> Map<> (rows)\n" << std::flush;
+  test_par_assign<float>(Domain<2>(16, 16),
+			 Global_map<2>(),
+			 Map<Block_dist>(Block_dist(np), Block_dist(1)),
+			 loop);
+
+  // Matrix Block_dist -> Serial
+  // std::cout << "Map<> (square) -> Global_map<2>\n" << std::flush;
+  test_par_assign<float>(Domain<2>(16, 16),
+			 Map<Block_dist>(Block_dist(nr), Block_dist(nc)),
+			 Global_map<2>(),
+			 loop);
+  // std::cout << "Map<> (cols) -> Global_map<2>\n" << std::flush;
+  test_par_assign<float>(Domain<2>(16, 16),
+			 Map<Block_dist>(Block_dist(1), Block_dist(np)),
+			 Global_map<2>(),
+			 loop);
+  // std::cout << "Map<> (rows) -> Global_map<2>\n" << std::flush;
+  test_par_assign<float>(Domain<2>(16, 16),
+			 Map<Block_dist>(Block_dist(np), Block_dist(1)),
+			 Global_map<2>(),
+			 loop);
+
+  // std::cout << "Map<> (rows) -> Map<> (cols)\n" << std::flush;
+  test_par_assign<float>(Domain<2>(16, 16),
+			 Map<Block_dist>(Block_dist(np), Block_dist(1)),
+			 Map<Block_dist>(Block_dist(1), Block_dist(np)),
+			 loop);
+
+  // Tensor case.
+  // std::cout << "3D: Map<> (rows) -> Map<> (cols)\n" << std::flush;
+  test_par_assign<float>(Domain<3>(16, 8, 5),
+		Map<Block_dist>(Block_dist(np), Block_dist(1), Block_dist(1)),
+		Map<Block_dist>(Block_dist(1), Block_dist(np), Block_dist(1)),
+		loop);
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl vpp(argc, argv);
+
+  int loop = argc > 1 ? atoi(argv[1]) : 1;
+
+#if 0
+  // Enable this section for easier debugging.
+  impl::Communicator& comm = impl::default_communicator();
+  pid_t pid = getpid();
+
+  cout << "rank: "   << comm.rank()
+       << "  size: " << comm.size()
+       << "  pid: "  << pid
+       << endl;
+
+  // Stop each process, allow debugger to be attached.
+  if (comm.rank() == 0) fgetc(stdin);
+  comm.barrier();
+  cout << "start\n";
+#endif
+
+  test_par_assign_cases<float>(loop);
+  test_par_assign_cases<complex<float> >(loop);
+
+  return 0;
+}
Index: tests/parallel/block.cpp
===================================================================
--- tests/parallel/block.cpp	(revision 173072)
+++ tests/parallel/block.cpp	(working copy)
@@ -51,34 +51,6 @@
   Definitions
 ***********************************************************************/
 
-// Check validity of local view.
-
-template <dimension_type                      Dim,
-	  template <typename, typename> class ViewT,
-	  typename                            T,
-	  typename                            BlockT>
-void
-check_local_view(
-  ViewT<T, BlockT> view)
-{
-  typedef typename impl::Distributed_local_block<BlockT>::type local_block_t;
-
-  typename BlockT::map_type const& map = view.block().map();
-  typename ViewT<T, BlockT>::local_type lview = view.local();
-
-  index_type sb = map.subblock();
-
-  Domain<Dim> dom = subblock_domain(view, sb);
-  test_assert(lview.size() == impl::size(dom));
-  for (dimension_type d=0; d<Dim; ++d)
-    test_assert(lview.size(d) == dom[d].size());
-
-  if (sb == no_subblock)
-    test_assert(lview.size() == 0);
-}
-
-
-
 template <typename       T,
 	  dimension_type Dim,
 	  typename       MapT>
@@ -355,45 +327,6 @@
 
 
 
-
-// Test a single parallel assignment.
-
-template <typename                  T,
-	  dimension_type            Dim,
-	  typename                  Map1,
-	  typename                  Map2>
-void
-test_par_assign(
-  Domain<Dim> dom,
-  Map1        map1,
-  Map2        map2,
-  int         loop)
-
-{
-  typedef typename impl::Row_major<Dim>::type order_type;
-
-  typedef Dense<Dim, T, order_type, Map1>   dist_block1_t;
-  typedef Dense<Dim, T, order_type, Map2>   dist_block2_t;
-
-  typedef typename View_of_dim<Dim, T, dist_block1_t>::type view1_t;
-  typedef typename View_of_dim<Dim, T, dist_block2_t>::type view2_t;
-
-  view1_t view1(create_view<view1_t>(dom, T(), map1));
-  view2_t view2(create_view<view2_t>(dom, T(), map2));
-
-  check_local_view<Dim>(view1);
-  check_local_view<Dim>(view2);
-
-  foreach_point(view1, Set_identity<Dim>(dom));
-  for (int l=0; l<loop; ++l)
-  {
-    view2 = view1;
-  }
-  foreach_point(view2, Check_identity<Dim>(dom));
-}
-
-
-
 // Test several distributed vector cases for a given type and parallel
 // assignment implementation.
 
@@ -482,96 +415,6 @@
 
 
 
-template <typename T>
-void
-test_par_assign_cases(int loop)
-{
-  length_type np, nr, nc;
-  get_np_square(np, nr, nc);
-
-  // Vector Serial -> Serial
-  // std::cout << "Global_map<1> -> Global_map<1>\n" << std::flush;
-  test_par_assign<float>(Domain<1>(16),
-			 Global_map<1>(),
-			 Global_map<1>(),
-			 loop);
-
-  test_par_assign<float>(Domain<1>(16),
-			 Replicated_map<1>(),
-			 Replicated_map<1>(),
-			 loop);
-
-  // Vector Serial -> Block_dist
-  // std::cout << "Global_map<1> -> Map<Block_dist>\n" << std::flush;
-  test_par_assign<float>(Domain<1>(16),
-			 Global_map<1>(),
-			 Map<Block_dist>(Block_dist(np)),
-			 loop);
-
-  // Vector Block_dist -> Serial
-  // std::cout << "Map<Block_dist> -> Global_map<1>\n" << std::flush;
-  test_par_assign<float>(Domain<1>(16),
-			 Map<Block_dist>(Block_dist(np)),
-			 Global_map<1>(),
-			 loop);
-
-  // Matrix Serial -> Serial
-  // std::cout << "Global_map<2> -> Global_map<2>\n" << std::flush;
-  test_par_assign<float>(Domain<2>(16, 16),
-			 Global_map<2>(),
-			 Global_map<2>(),
-			 loop);
-
-  // Matrix Serial -> Block_dist
-  // std::cout << "Global_map<2> -> Map<> (square)\n" << std::flush;
-  test_par_assign<float>(Domain<2>(16, 16),
-			 Global_map<2>(),
-			 Map<Block_dist>(Block_dist(nr), Block_dist(nc)),
-			 loop);
-  // std::cout << "Global_map<2> -> Map<> (cols)\n" << std::flush;
-  test_par_assign<float>(Domain<2>(16, 16),
-			 Global_map<2>(),
-			 Map<Block_dist>(Block_dist(1), Block_dist(np)),
-			 loop);
-  // std::cout << "Global_map<2> -> Map<> (rows)\n" << std::flush;
-  test_par_assign<float>(Domain<2>(16, 16),
-			 Global_map<2>(),
-			 Map<Block_dist>(Block_dist(np), Block_dist(1)),
-			 loop);
-
-  // Matrix Block_dist -> Serial
-  // std::cout << "Map<> (square) -> Global_map<2>\n" << std::flush;
-  test_par_assign<float>(Domain<2>(16, 16),
-			 Map<Block_dist>(Block_dist(nr), Block_dist(nc)),
-			 Global_map<2>(),
-			 loop);
-  // std::cout << "Map<> (cols) -> Global_map<2>\n" << std::flush;
-  test_par_assign<float>(Domain<2>(16, 16),
-			 Map<Block_dist>(Block_dist(1), Block_dist(np)),
-			 Global_map<2>(),
-			 loop);
-  // std::cout << "Map<> (rows) -> Global_map<2>\n" << std::flush;
-  test_par_assign<float>(Domain<2>(16, 16),
-			 Map<Block_dist>(Block_dist(np), Block_dist(1)),
-			 Global_map<2>(),
-			 loop);
-
-  // std::cout << "Map<> (rows) -> Map<> (cols)\n" << std::flush;
-  test_par_assign<float>(Domain<2>(16, 16),
-			 Map<Block_dist>(Block_dist(np), Block_dist(1)),
-			 Map<Block_dist>(Block_dist(1), Block_dist(np)),
-			 loop);
-
-  // Tensor case.
-  // std::cout << "3D: Map<> (rows) -> Map<> (cols)\n" << std::flush;
-  test_par_assign<float>(Domain<3>(16, 8, 5),
-		Map<Block_dist>(Block_dist(np), Block_dist(1), Block_dist(1)),
-		Map<Block_dist>(Block_dist(1), Block_dist(np), Block_dist(1)),
-		loop);
-}
-
-
-
 int
 main(int argc, char** argv)
 {
@@ -598,8 +441,6 @@
   length_type np, nc, nr;
   get_np_square(np, nc, nr);
 
-  test_par_assign_cases<float>(loop);
-
   test_vector<TestImplicit, float>(loop);
   test_matrix<TestImplicit, float>(loop);
 
@@ -612,8 +453,6 @@
 
 
 
-  test_par_assign_cases<complex<float> >(loop);
-
   test_vector<TestImplicit, complex<float> >(loop);
   test_matrix<TestImplicit, complex<float> >(loop);
 
