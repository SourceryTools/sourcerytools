Index: ChangeLog
===================================================================
--- ChangeLog	(revision 151366)
+++ ChangeLog	(working copy)
@@ -1,3 +1,15 @@
+2006-10-13  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/vmmul.hpp (Distributed_local_block): Add missing
+	  proxy_type typedef.
+	  (Serial_expr_evaluator): Move vmmul evaluator to Op_expr_tag.
+	* src/vsip/opt/expr/serial_dispatch_fwd.hpp (LibraryTagList):
+	  Add Op_expr_tag.
+	* src/vsip/opt/expr/serial_evaluator.hpp (Op_expr_tag): New evaluator
+	  tag, intended for special op handling, such as vmmul.
+	* tests/vmmul.cpp: Extend to cover cases where vmmul has
+	  expr argument, and is used in a expression.
+	
 2006-10-12  Jules Bergmann  <jules@codesourcery.com>
 
 	* tests/matvec.cpp: Disable long double test when
Index: src/vsip/core/vmmul.hpp
===================================================================
--- src/vsip/core/vmmul.hpp	(revision 151279)
+++ src/vsip/core/vmmul.hpp	(working copy)
@@ -111,6 +111,10 @@
 			   typename Distributed_local_block<Block0>::type,
 			   typename Distributed_local_block<Block1>::type>
 		const type;
+  typedef Vmmul_expr_block<VecDim,
+			 typename Distributed_local_block<Block0>::proxy_type,
+			 typename Distributed_local_block<Block1>::proxy_type>
+		const proxy_type;
 };
 
 
@@ -293,7 +297,7 @@
 	  dimension_type SD>
 struct Serial_expr_evaluator<2, DstBlock,
 			     const Vmmul_expr_block<SD, VBlock, MBlock>,
-			     Loop_fusion_tag>
+			     Op_expr_tag>
 {
   static char const* name() { return "Expr_Loop_Vmmul"; }
 
Index: src/vsip/opt/expr/serial_dispatch_fwd.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch_fwd.hpp	(revision 151279)
+++ src/vsip/opt/expr/serial_dispatch_fwd.hpp	(working copy)
@@ -39,6 +39,7 @@
 		       Dense_expr_tag,
 #endif
 		       Copy_tag,
+		       Op_expr_tag,
 		       Simd_loop_fusion_tag,
 		       Loop_fusion_tag>::type LibraryTagList;
 
Index: src/vsip/opt/expr/serial_evaluator.hpp
===================================================================
--- src/vsip/opt/expr/serial_evaluator.hpp	(revision 151279)
+++ src/vsip/opt/expr/serial_evaluator.hpp	(working copy)
@@ -40,6 +40,7 @@
 struct Mercury_sal_tag;		// Mercury SAL Library
 struct Dense_expr_tag;		// Dense multi-dim expr reduction
 struct Copy_tag;		// Optimized Copy
+struct Op_expr_tag;		// Special expr handling (vmmul, etc)
 struct Simd_loop_fusion_tag;	// SIMD Loop Fusion.
 struct Loop_fusion_tag;		// Generic Loop Fusion (base case).
 
Index: tests/vmmul.cpp
===================================================================
--- tests/vmmul.cpp	(revision 151366)
+++ tests/vmmul.cpp	(working copy)
@@ -53,25 +53,39 @@
 
   v = test_ramp(T(), T(1), v.size());
 
-  Matrix<T> res = vmmul<Dim>(v, m);
+  Matrix<T> res1 =  vmmul<Dim>(     v,      m);
+  Matrix<T> res2 =  vmmul<Dim>(T(2)*v,      m);
+  Matrix<T> res3 =  vmmul<Dim>(     v, T(3)*m);
+  Matrix<T> res4 = -vmmul<Dim>(     v,      m);
 
   for (index_type r=0; r<rows; ++r)
     for (index_type c=0; c<cols; ++c)
       if (Dim == 0)
-	test_assert(equal(res(r, c), T(c * (r*cols+c))));
+      {
+	test_assert(equal(res1(r, c),  T(c      * (r*cols+c))));
+	test_assert(equal(res2(r, c),  T(T(2)*c * (r*cols+c))));
+	test_assert(equal(res3(r, c),  T(T(3)*c * (r*cols+c))));
+	test_assert(equal(res4(r, c), -T(c      * (r*cols+c))));
+      }
       else
-	test_assert(equal(res(r, c), T(r * (r*cols+c))));
+      {
+	test_assert(equal(res1(r, c),  T(r      * (r*cols+c))));
+	test_assert(equal(res2(r, c),  T(T(2)*r * (r*cols+c))));
+	test_assert(equal(res3(r, c),  T(T(3)*r * (r*cols+c))));
+	test_assert(equal(res4(r, c), -T(r      * (r*cols+c))));
+      }
 }
 
 
 
+template <typename T>
 void
 vmmul_cases()
 {
-  test_vmmul<0, row2_type, float>(5, 7);
-  test_vmmul<0, col2_type, float>(5, 7);
-  test_vmmul<1, row2_type, float>(5, 7);
-  test_vmmul<1, col2_type, float>(5, 7);
+  test_vmmul<0, row2_type, T>(5, 7);
+  test_vmmul<0, col2_type, T>(5, 7);
+  test_vmmul<1, row2_type, T>(5, 7);
+  test_vmmul<1, col2_type, T>(5, 7);
 }
 
 
@@ -196,7 +210,7 @@
 {
   vsipl init(argc, argv);
 
-  vmmul_cases();
+  vmmul_cases<float>();
 
   par_vmmul_cases<row2_type, float>();
   par_vmmul_cases<col2_type, float>();
