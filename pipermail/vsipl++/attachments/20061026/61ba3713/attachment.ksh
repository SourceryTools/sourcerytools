Index: ChangeLog
===================================================================
--- ChangeLog	(revision 152478)
+++ ChangeLog	(working copy)
@@ -1,4 +1,10 @@
+2006-10-26  Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/threshold.hpp: New file, unit tests for threshold
+	  expressions that are dispatched to SAL.
+	
 2006-10-26  Assem Salama <assem@codesourcery.com>
+	
 	* src/vsip/core/cvsip/solver_lu.hpp: Fixed header gaurds, move
 	  admit/release from decompose function into this file.
 	* src/vsip/core/cvsip/cvsip.hpp: Added some more functions for qr.
Index: tests/threshold.cpp
===================================================================
--- tests/threshold.cpp	(revision 0)
+++ tests/threshold.cpp	(revision 0)
@@ -0,0 +1,138 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/threshold.cpp
+    @author  Jules Bergmann
+    @date    2006-10-16
+    @brief   VSIPL++ Library: Test threshold operations.
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
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Test C = ite(A >= b, A, T(0)) threshold
+//
+// This C1 and C2 variations of this are dispatched to SAL vthresx
+
+template <typename T>
+void
+test_ge_threshold_0(length_type size)
+{
+  Rand<T> r(0);
+
+  Vector<T> A(size);
+  T         b;
+  Vector<T> C1(size);
+  Vector<T> C2(size);
+  Vector<T> C3(size);
+  Vector<T> C4(size);
+
+  A = r.randu(size);
+  b = T(0.5);
+
+  A.put(0, b);
+
+  C1 = ite(A >= b, A,    T(0));
+  C2 = ite(A <  b, T(0), A);
+  C3 = ite(b <= A, A,    T(0));
+  C4 = ite(b >  A, T(0), A);
+
+  for (index_type i=0; i<size; ++i)
+  {
+    if (A.get(i) >= b)
+    {
+      test_assert(C1.get(i) == A.get(i));
+      test_assert(C2.get(i) == A.get(i));
+      test_assert(C3.get(i) == A.get(i));
+      test_assert(C4.get(i) == A.get(i));
+    }
+    else
+    {
+      test_assert(C1.get(i) == T(0));
+      test_assert(C2.get(i) == T(0));
+      test_assert(C3.get(i) == T(0));
+      test_assert(C4.get(i) == T(0));
+    }
+  }
+}
+
+
+
+// Test C = ite(A >= b, A, T(b)) threshold
+//
+// This C1 and C2 variations of this are dispatched to SAL vthrx
+
+template <typename T>
+void
+test_ge_threshold_b(length_type size)
+{
+  Rand<T> r(0);
+
+  Vector<T> A(size);
+  T         b;
+  Vector<T> C1(size);
+  Vector<T> C2(size);
+  Vector<T> C3(size);
+  Vector<T> C4(size);
+
+  A = r.randu(size);
+
+  C1 = ite(A >= b, A, b);
+  C2 = ite(A <  b, b, A);
+  C3 = ite(b <= A, A, b);
+  C4 = ite(b >  A, b, A);
+
+  for (index_type i=0; i<size; ++i)
+  {
+    if (A.get(i) >= b)
+    {
+      test_assert(C1.get(i) == A.get(i));
+      test_assert(C2.get(i) == A.get(i));
+      test_assert(C3.get(i) == A.get(i));
+      test_assert(C4.get(i) == A.get(i));
+    }
+    else
+    {
+      test_assert(C1.get(i) == b);
+      test_assert(C2.get(i) == b);
+      test_assert(C3.get(i) == b);
+      test_assert(C4.get(i) == b);
+    }
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
+  test_ge_threshold_0<float>(16);
+  test_ge_threshold_0<float>(17);
+
+  test_ge_threshold_b<float>(16);
+  test_ge_threshold_b<float>(17);
+
+  return 0;
+}
