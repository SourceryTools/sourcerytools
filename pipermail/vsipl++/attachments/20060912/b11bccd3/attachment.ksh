Index: ChangeLog
===================================================================
--- ChangeLog	(revision 149033)
+++ ChangeLog	(working copy)
@@ -1,5 +1,16 @@
-2006-09-11  Stefan Seefeld  <stefan@codesourcery.com>
+2006-09-12  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/impl/simd/expr_evaluator.hpp: Use Adjust_layout_dim
+	  to work with re-dimensioned expressions.
+	* tests/coverage_common.hpp (matrix_cases3): Add scalar-matrix
+	  combinations.
+	* tests/coverage_binary.cpp: Add coverage for col-mat * scalar.
+	* tests/regressions/col_mat_scale.cpp: New test, regression for
+	  col-mat * scalar, which tests SIMD loop fusion with re-dimensioned
+	  expressions.
+	
+2006-09-12  Stefan Seefeld  <stefan@codesourcery.com>
+
 	* configure.ac: Fix handling of 'mpicxx -show'; add --with-qmtest.
 	* GNUmakefile.in: Define QMTEST variable.
 	* tests/GNUmakefile.inc.in: Use it.
Index: src/vsip/impl/simd/expr_evaluator.hpp
===================================================================
--- src/vsip/impl/simd/expr_evaluator.hpp	(revision 149033)
+++ src/vsip/impl/simd/expr_evaluator.hpp	(working copy)
@@ -40,20 +40,24 @@
 {
   typedef Direct_access_traits<typename BlockT::value_type> access_traits;
   typedef Proxy<access_traits> proxy_type;
+  typedef typename Adjust_layout_dim<
+                     1, typename Block_layout<BlockT>::layout_type>::type
+		layout_type;
+
   static bool const ct_valid = Ext_data_cost<BlockT>::value == 0 &&
     !Is_split_block<BlockT>::value;
 
   static bool 
   rt_valid(BlockT const &b)
   {
-    Ext_data<BlockT> dda(b, SYNC_IN);
+    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
     return dda.stride(0) == 1 && 
       Simd_traits<typename BlockT::value_type>::alignment_of(dda.data()) == 0;
   }
   static proxy_type 
   create(BlockT const &b) 
   {
-    Ext_data<BlockT> dda(b, SYNC_IN);
+    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
     return proxy_type(dda.data());
   }
 };
@@ -137,6 +141,10 @@
 	  typename RB>
 struct Serial_expr_evaluator<1, LB, RB, Simd_loop_fusion_tag>
 {
+  typedef typename Adjust_layout_dim<
+                     1, typename Block_layout<LB>::layout_type>::type
+		layout_type;
+
   static char const* name() { return "Expr_SIMD_Loop"; }
   
   static bool const ct_valid =
@@ -156,7 +164,7 @@
 
   static bool rt_valid(LB& lhs, RB const& rhs)
   {
-    Ext_data<LB> dda(lhs, SYNC_OUT);
+    Ext_data<LB, layout_type> dda(lhs, SYNC_OUT);
     return (dda.stride(0) == 1 &&
 	    simd::Simd_traits<typename LB::value_type>::
 	      alignment_of(dda.data()) == 0 &&
@@ -169,7 +177,7 @@
     typedef typename simd::Proxy_factory<RB>::access_traits EAT;
     length_type const vec_size =
       simd::Simd_traits<typename LB::value_type>::vec_size;
-    Ext_data<LB> dda(lhs, SYNC_OUT);
+    Ext_data<LB, layout_type> dda(lhs, SYNC_OUT);
     length_type const size = dda.size(0);
     length_type n = size;
     simd::Proxy<WAT> lp(dda.data());
Index: tests/coverage_common.hpp
===================================================================
--- tests/coverage_common.hpp	(revision 149033)
+++ tests/coverage_common.hpp	(working copy)
@@ -500,15 +500,28 @@
   using namespace vsip;
   typedef typename Promotion<T1, T2>::type  T3;
 
+  typedef Storage<0, T1>                  ss_1_t;
+  typedef Storage<0, T2>                  ss_2_t;
+
   typedef Storage<2, T1, row2_type>       mr_1_t;
   typedef Storage<2, T2, row2_type>       mr_2_t;
   typedef Storage<2, T3, row2_type>       mr_3_t;
 
+  typedef Storage<2, T1, col2_type>       mc_1_t;
+  typedef Storage<2, T2, col2_type>       mc_2_t;
+  typedef Storage<2, T3, col2_type>       mc_3_t;
+
   typedef Transpose_matrix<T1, row2_type> tr_1_t;
   typedef Transpose_matrix<T2, row2_type> tr_2_t;
   typedef Transpose_matrix<T3, row2_type> tr_3_t;
 
   Domain<2> dom(7, 11);
+
+  do_case3<Test_class, ss_1_t, mr_2_t, mr_3_t>(dom);
+  do_case3<Test_class, mr_1_t, ss_2_t, mr_3_t>(dom);
+
+  do_case3<Test_class, ss_1_t, mc_2_t, mc_3_t>(dom);
+  do_case3<Test_class, mc_1_t, ss_2_t, mc_3_t>(dom);
   
   do_case3<Test_class, mr_1_t, mr_2_t, mr_3_t>(dom);
 
Index: tests/regressions/col_mat_scale.cpp
===================================================================
--- tests/regressions/col_mat_scale.cpp	(revision 0)
+++ tests/regressions/col_mat_scale.cpp	(revision 0)
@@ -0,0 +1,68 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/col_mat_scale.cpp
+    @author  Jules Bergmann
+    @date    2006-09-11
+    @brief   VSIPL++ Library: Matrix Scale
+
+    Regression test: SIMD Loop Fusion did not adjust dimension for
+      re-dimensioned blocks.  As a result, column-major matrix scale
+      failed.
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
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+
+
+template <typename T,
+	  typename OrderT>
+void
+matrix_scale()
+{
+  typedef Dense<2, T, OrderT> block_type;
+
+  Matrix<T, block_type> view(2, 2);
+
+  view.put(0, 0, T(1, 2));
+  view.put(0, 1, T(3, 4));
+  view.put(1, 0, T(5, 6));
+  view.put(1, 1, T(7, 8));
+
+  view *= T(0.25);
+
+  test_assert(view.get(0, 0) == T(0.25*1, 0.25*2));
+  test_assert(view.get(0, 1) == T(0.25*3, 0.25*4));
+  test_assert(view.get(1, 0) == T(0.25*5, 0.25*6));
+  test_assert(view.get(1, 1) == T(0.25*7, 0.25*8));
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  matrix_scale<complex<float>, row2_type>();
+  matrix_scale<complex<float>, col2_type>();
+
+  return 0;
+}
+
Index: tests/coverage_binary.cpp
===================================================================
--- tests/coverage_binary.cpp	(revision 149033)
+++ tests/coverage_binary.cpp	(working copy)
@@ -244,6 +244,7 @@
   vector_cases3<Test_mul, double,          double>();
   vector_cases3<Test_mul, complex<double>, complex<double> >();
 #endif
+  matrix_cases3<Test_mul, complex<float>,  complex<float> >();
 
   vector_cases3<Test_div, int,             int>();
   vector_cases3<Test_div, float,           float>();
