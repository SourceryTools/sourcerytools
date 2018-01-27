Index: ChangeLog
===================================================================
--- ChangeLog	(revision 146321)
+++ ChangeLog	(working copy)
@@ -1,3 +1,11 @@
+2006-08-04  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/expr_ops_per_point.hpp: New file, expression
+	  template reduction to determine the number of ops/point.
+	* src/vsip/impl/metaprogramming.hpp (Int_value): Make value visible.
+	* tests/expr_ops_per_point.cpp: New file, unit test for
+	  Expr_ops_per_point reduction.
+
 2006-07-31  Jules Bergmann  <jules@codesourcery.com>
 
 	* vendor/GNUmakefile.inc.in: Add LAPACK related libraries to
Index: src/vsip/impl/expr_ops_per_point.hpp
===================================================================
--- src/vsip/impl/expr_ops_per_point.hpp	(revision 0)
+++ src/vsip/impl/expr_ops_per_point.hpp	(revision 0)
@@ -0,0 +1,214 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/expr_ops_per_point.hpp
+    @author  Jules Bergmann
+    @date    2006-08-04
+    @brief   VSIPL++ Library: Determine the number of ops per point for
+                              an expression template.
+*/
+
+#ifndef VSIP_IMPL_EXPR_OPS_PER_POINT_HPP
+#define VSIP_IMPL_EXPR_OPS_PER_POINT_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/metaprogramming.hpp>
+#include <vsip/impl/block-traits.hpp>
+#include <vsip/impl/expr_scalar_block.hpp>
+#include <vsip/impl/expr_unary_block.hpp>
+#include <vsip/impl/expr_binary_block.hpp>
+#include <vsip/impl/expr_ternary_block.hpp>
+#include <vsip/impl/coverage.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+
+
+// Traits classes to determine the ops for a particular operation.
+
+template <template <typename> class UnaryOp,
+	  typename                  T1>
+struct Unary_op_count
+{
+  static unsigned const value = 0;
+}; 
+
+template <template <typename, typename> class BinaryOp,
+	  typename                            T1,
+	  typename                            T2>
+struct Binary_op_count
+{
+  static unsigned const value = 0;
+}; 
+
+template <template <typename, typename, typename> class TernaryOp,
+	  typename                            T1,
+	  typename                            T2,
+	  typename                            T3>
+struct Ternary_op_count
+{
+  static unsigned const value = 0;
+}; 
+
+
+
+// FIXME: Ops count for unary ops
+
+#define BINARY_OPS(OP, TYPE1, TYPE2, VALUE)				\
+template <typename T1,							\
+          typename T2>							\
+struct Binary_op_count<OP, TYPE1, TYPE2>				\
+{									\
+  static unsigned const value = VALUE;					\
+}; 
+
+BINARY_OPS(op::Add,  T1,          T2,          1)
+BINARY_OPS(op::Add,  T1,          complex<T2>, 1)
+BINARY_OPS(op::Add,  complex<T1>, T2,          1)
+BINARY_OPS(op::Add,  complex<T1>, complex<T2>, 2)
+
+BINARY_OPS(op::Mult, T1,          T2,          1)
+BINARY_OPS(op::Mult, T1,          complex<T2>, 2)
+BINARY_OPS(op::Mult, complex<T1>, T2,          2)
+BINARY_OPS(op::Mult, complex<T1>, complex<T2>, 6)
+
+#undef BINARY_OPS
+
+// FIXME: Ops count for ternary ops
+
+
+
+// Reduction to count the number operations per point of an expression.
+
+struct Reduce_expr_ops_per_point
+{
+public:
+  template <typename BlockT>
+  struct leaf_node
+  {
+    typedef Int_type<0> type;
+  };
+
+  template <dimension_type Dim0,
+	    typename       T>
+  struct leaf_node<Scalar_block<Dim0, T> >
+  {
+    typedef Int_type<0> type;
+  };
+
+  template <dimension_type            Dim0,
+	    template <typename> class Op,
+	    typename                  NewBlockT,
+	    typename                  NewT>
+  struct unary_node
+  {
+    typedef Int_type<Unary_op_count<Op, NewT>::value +
+                     NewBlockT::value> type;
+  };
+
+  template <dimension_type                Dim0,
+	    template <typename, typename> class Op,
+	    typename                      NewLBlock,
+	    typename                      NewLType,
+	    typename                      NewRBlock,
+	    typename                      NewRType>
+  struct binary_node
+  {
+    typedef Int_type<Binary_op_count<Op, NewLType, NewRType>::value +
+                     NewLBlock::value +
+                     NewRBlock::value> type;
+  };
+
+  template <dimension_type                          Dim0,
+	    template <typename, typename, typename> class Op,
+	    typename                                NewBlock1,
+	    typename                                NewType1,
+	    typename                                NewBlock2,
+	    typename                                NewType2,
+	    typename                                NewBlock3,
+	    typename                                NewType3>
+  struct ternary_node
+  {
+    typedef Int_type<
+      Ternary_op_count<Op, NewType1, NewType2, NewType3>::value +
+      NewBlock1::value +
+      NewBlock2::value +
+      NewBlock3::value> type;
+  };
+
+  template <typename BlockT>
+  struct transform
+  {
+    typedef typename leaf_node<BlockT>::type type;
+  };
+
+  template <dimension_type            Dim0,
+	    template <typename> class Op,
+	    typename                  BlockT,
+	    typename                  T>
+  struct transform<Unary_expr_block<Dim0, Op, BlockT, T> const>
+  {
+    typedef typename unary_node<Dim0, Op,
+				typename transform<BlockT>::type,
+				T>::type type;
+  };
+
+  template <dimension_type                Dim0,
+	    template <typename, typename> class Op,
+	    typename                      LBlock,
+	    typename                      LType,
+	    typename                      RBlock,
+	    typename                      RType>
+  struct transform<Binary_expr_block<Dim0, Op, LBlock, LType,
+				     RBlock, RType> const>
+  {
+    typedef typename binary_node<Dim0, Op,
+				typename transform<LBlock>::type, LType,
+				typename transform<RBlock>::type, RType>
+				::type type;
+  };
+
+  template <dimension_type                Dim0,
+	    template <typename, typename, typename> class Op,
+	    typename                      Block1,
+	    typename                      Type1,
+	    typename                      Block2,
+	    typename                      Type2,
+	    typename                      Block3,
+	    typename                      Type3>
+  struct transform<Ternary_expr_block<Dim0, Op, Block1, Type1,
+				     Block2, Type2, Block3, Type3> const>
+  {
+    typedef typename ternary_node<Dim0, Op,
+				typename transform<Block1>::type, Type1,
+				typename transform<Block2>::type, Type2,
+				typename transform<Block3>::type, Type3>
+				::type type;
+  };
+};
+
+
+
+template <typename BlockT>
+struct Expr_ops_per_point
+{
+  static unsigned const value =
+    Reduce_expr_ops_per_point::template transform<BlockT>::type::value;
+};
+
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_EXPR_OPS_PER_POINT_HPP
Index: src/vsip/impl/metaprogramming.hpp
===================================================================
--- src/vsip/impl/metaprogramming.hpp	(revision 146321)
+++ src/vsip/impl/metaprogramming.hpp	(working copy)
@@ -135,9 +135,9 @@
 struct Bool_type
 { static const bool value = Value; };
 
-template <int value>
+template <int Value>
 struct Int_type
-{};
+{ static const int value = Value; };
 
 struct false_type { static const bool value = false; };
 struct true_type  { static const bool value = true; };
Index: tests/expr_ops_per_point.cpp
===================================================================
--- tests/expr_ops_per_point.cpp	(revision 0)
+++ tests/expr_ops_per_point.cpp	(revision 0)
@@ -0,0 +1,70 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/expr_ops_per_point.cpp
+    @author  Jules Bergmann
+    @date    2006-08-04
+    @brief   VSIPL++ Library: Test Expr_ops_per_point expression template
+                              reduction.
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
+#include <vsip/impl/expr_ops_per_point.hpp>
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
+// Test that the ops/point of an EXPR is as expected by OPS.
+
+template <typename ViewT>
+void
+test_expr(unsigned ops, ViewT /*expr*/)
+{
+  typedef typename ViewT::block_type block_type;
+
+  test_assert(ops == impl::Expr_ops_per_point<block_type>::value);
+}
+
+
+void
+test()
+{
+  Vector<float> vec1(5);
+  Vector<float> vec2(5);
+  Vector<complex<float> > vec3(5);
+  Vector<complex<float> > vec4(5);
+
+  test_expr(1, vec1 + vec2);
+  test_expr(1, vec1 * vec2);
+  test_expr(2, vec1 * vec3);
+  test_expr(6, vec3 * vec4);
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
+  test();
+
+  return 0;
+}
