Index: src/vsip/complex.hpp
===================================================================
--- src/vsip/complex.hpp	(revision 147065)
+++ src/vsip/complex.hpp	(working copy)
@@ -88,6 +88,7 @@
 struct realtocomplex_functor
 {
   typedef complex<T> result_type;
+  static char const* name() { return "realtocomplex"; }
   static result_type apply(T rho) { return complex<T>(rho);}
   result_type operator() (T rho) const { return apply(rho);}
 };
@@ -96,6 +97,7 @@
 struct polartorect_functor
 {
   typedef typename Promotion<complex<T1>, complex<T2> >::type result_type;
+  static char const* name() { return "polartorect"; }
   static result_type apply(T1 rho, T2 theta) { return polar(rho, theta);}
   result_type operator() (T1 rho, T2 theta) const { return apply(rho, theta);}
 };
@@ -112,11 +114,12 @@
 struct cmplx_functor
 {
   typedef typename Promotion<complex<T1>, complex<T2> >::type result_type;
+  static char const* name() { return "cmplx"; }
   static result_type apply(T1 real, T2 imag) { return result_type(real, imag);}
   result_type operator() (T1 real, T2 imag) const { return apply(real, imag);}
 };
 
-}
+} // namespace impl
 
 template <typename T>
 inline complex<T>
Index: src/vsip/impl/expr_ops_info.hpp
===================================================================
--- src/vsip/impl/expr_ops_info.hpp	(revision 147029)
+++ src/vsip/impl/expr_ops_info.hpp	(working copy)
@@ -1,14 +1,14 @@
 /* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    vsip/impl/expr_ops_per_point.hpp
+/** @file    vsip/impl/expr_ops_info.hpp
     @author  Jules Bergmann
     @date    2006-08-04
     @brief   VSIPL++ Library: Determine the number of ops per point for
                               an expression template.
 */
 
-#ifndef VSIP_IMPL_EXPR_OPS_PER_POINT_HPP
-#define VSIP_IMPL_EXPR_OPS_PER_POINT_HPP
+#ifndef VSIP_IMPL_EXPR_OPS_INFO_HPP
+#define VSIP_IMPL_EXPR_OPS_INFO_HPP
 
 /***********************************************************************
   Included Files
@@ -16,10 +16,12 @@
 
 #include <vsip/impl/metaprogramming.hpp>
 #include <vsip/impl/block-traits.hpp>
+#include <vsip/impl/expr_operations.hpp>
 #include <vsip/impl/expr_scalar_block.hpp>
 #include <vsip/impl/expr_unary_block.hpp>
 #include <vsip/impl/expr_binary_block.hpp>
 #include <vsip/impl/expr_ternary_block.hpp>
+#include <vsip/impl/fns_elementwise.hpp>
 #include <vsip/impl/coverage.hpp>
 
 
@@ -33,9 +35,43 @@
 namespace impl
 {
 
+/// These generate char tags for given data types, defaulting to int
+/// with specializations for common floating point types.  These use
+/// BLAS/LAPACK convention.
 
-// Traits classes to determine the ops for a particular operation.
+template <typename T> 
+struct Type_name    { static char const value = 'I'; };
 
+#define VSIP_IMPL_TYPE_NAME(T, VALUE)		\
+template <>					\
+struct Type_name<T> { static char const value = VALUE; };
+
+VSIP_IMPL_TYPE_NAME(float,                'S');
+VSIP_IMPL_TYPE_NAME(double,               'D');
+VSIP_IMPL_TYPE_NAME(std::complex<float>,  'C');
+VSIP_IMPL_TYPE_NAME(std::complex<double>, 'Z');
+
+#undef VSIP_IMPL_TYPE_NAME
+
+
+template <typename T> 
+struct Scalar_type_name    { static char const value = 'i'; };
+
+#define VSIP_IMPL_SCALAR_TYPE_NAME(T, VALUE)	\
+template <>					\
+struct Scalar_type_name<T> { static char const value = VALUE; };
+
+VSIP_IMPL_SCALAR_TYPE_NAME(float,                's');
+VSIP_IMPL_SCALAR_TYPE_NAME(double,               'd');
+VSIP_IMPL_SCALAR_TYPE_NAME(std::complex<float>,  'c');
+VSIP_IMPL_SCALAR_TYPE_NAME(std::complex<double>, 'z');
+
+#undef VSIP_IMPL_SCALAR_TYPE_NAME
+
+
+
+/// Traits classes to determine the ops for a particular operation.
+
 template <template <typename> class UnaryOp,
 	  typename                  T1>
 struct Unary_op_count
@@ -43,53 +79,234 @@
   static unsigned const value = 0;
 }; 
 
-template <template <typename, typename> class BinaryOp,
-	  typename                            T1,
-	  typename                            T2>
+template <template <typename, 
+                    typename> class BinaryOp,
+	  typename                  T1,
+	  typename                  T2>
 struct Binary_op_count
 {
   static unsigned const value = 0;
 }; 
 
-template <template <typename, typename, typename> class TernaryOp,
-	  typename                            T1,
-	  typename                            T2,
-	  typename                            T3>
+template <template <typename, 
+                    typename, 
+                    typename> class TernaryOp,
+	  typename                  T1,
+	  typename                  T2,
+	  typename                  T3>
 struct Ternary_op_count
 {
   static unsigned const value = 0;
 }; 
 
 
+/// Specializations for Unary types
 
-// FIXME: Ops count for unary ops
+#define VSIP_IMPL_UNARY_OPS_FUNCTOR(OP, TYPE, VALUE)		\
+template <typename T>					\
+struct Unary_op_count<OP##_functor, TYPE>		\
+{							\
+  static unsigned const value = VALUE;			\
+}; 
 
-#define BINARY_OPS(OP, TYPE1, TYPE2, VALUE)				\
-template <typename T1,							\
-          typename T2>							\
-struct Binary_op_count<OP, TYPE1, TYPE2>				\
-{									\
-  static unsigned const value = VALUE;					\
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(acos)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(arg)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(asin)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(atan)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(bnot,  T,            1)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(ceil,  T,            1)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(conj,  complex<T>,   1)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(cos,   T,            1)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(cos,   complex<T>,  12)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(cosh)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(euler)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(exp)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(exp10)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(floor, T,            1)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(imag,  complex<T>,   0)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(lnot,  T,            1)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(log)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(log10)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(mag,   T,            0)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(mag,   complex<T>,  13)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(magsq, T,            3)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(neg,   T,            1)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(real,  complex<T>,   0)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(recip)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(rsqrt)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(sin,   T,            1)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(sin,   complex<T>,  12)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(sinh)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(sq,    T,            1)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(sq,    complex<T>,   5)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(sqrt,  T,            1)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(sqrt,  complex<T>,  10)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(tan,   T,            1)
+VSIP_IMPL_UNARY_OPS_FUNCTOR(tan,   complex<T>,  14)
+//VSIP_IMPL_UNARY_OPS_FUNCTOR(tanh)
+
+#undef VSIP_IMPL_UNARY_OPS_FUNCTOR
+
+
+/// Specializations for Binary types
+
+#define VSIP_IMPL_BINARY_OPS(OP, TYPE1, TYPE2, VALUE)		\
+template <typename T1,					\
+          typename T2>					\
+struct Binary_op_count<OP, TYPE1, TYPE2>		\
+{							\
+  static unsigned const value = VALUE;			\
 }; 
 
-BINARY_OPS(op::Add,  T1,          T2,          1)
-BINARY_OPS(op::Add,  T1,          complex<T2>, 1)
-BINARY_OPS(op::Add,  complex<T1>, T2,          1)
-BINARY_OPS(op::Add,  complex<T1>, complex<T2>, 2)
+#define VSIP_IMPL_BINARY_OPS_FUNCTOR(OP, TYPE1, TYPE2, VALUE)	\
+        VSIP_IMPL_BINARY_OPS(OP##_functor, TYPE1, TYPE2, VALUE)
 
-BINARY_OPS(op::Mult, T1,          T2,          1)
-BINARY_OPS(op::Mult, T1,          complex<T2>, 2)
-BINARY_OPS(op::Mult, complex<T1>, T2,          2)
-BINARY_OPS(op::Mult, complex<T1>, complex<T2>, 6)
+VSIP_IMPL_BINARY_OPS(op::Add,  T1,          T2,          1)
+VSIP_IMPL_BINARY_OPS(op::Add,  T1,          complex<T2>, 1)
+VSIP_IMPL_BINARY_OPS(op::Add,  complex<T1>, T2,          1)
+VSIP_IMPL_BINARY_OPS(op::Add,  complex<T1>, complex<T2>, 2)
+VSIP_IMPL_BINARY_OPS(op::Sub,  T1,          T2,          1)
+VSIP_IMPL_BINARY_OPS(op::Sub,  T1,          complex<T2>, 1)
+VSIP_IMPL_BINARY_OPS(op::Sub,  complex<T1>, T2,          1)
+VSIP_IMPL_BINARY_OPS(op::Sub,  complex<T1>, complex<T2>, 2)
+VSIP_IMPL_BINARY_OPS(op::Mult, T1,          T2,          1)
+VSIP_IMPL_BINARY_OPS(op::Mult, T1,          complex<T2>, 2)
+VSIP_IMPL_BINARY_OPS(op::Mult, complex<T1>, T2,          2)
+VSIP_IMPL_BINARY_OPS(op::Mult, complex<T1>, complex<T2>, 6)
+VSIP_IMPL_BINARY_OPS(op::Div,  T1,          T2,          1)
+VSIP_IMPL_BINARY_OPS(op::Div,  T1,          complex<T2>, 2)
+VSIP_IMPL_BINARY_OPS(op::Div,  complex<T1>, T2,          2)
+VSIP_IMPL_BINARY_OPS(op::Div,  complex<T1>, complex<T2>, 6)
 
-#undef BINARY_OPS
+VSIP_IMPL_BINARY_OPS_FUNCTOR(add,     T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(add,     T1,          complex<T2>,  1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(add,     complex<T1>, T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(add,     complex<T1>, complex<T2>,  2)
+//VSIP_IMPL_BINARY_OPS_FUNCTOR(atan2)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(band,    T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(bor,     T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(bxor,    T1,          T2,           1)
+//VSIP_IMPL_BINARY_OPS_FUNCTOR(div)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(eq,      T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(eq,      complex<T1>, complex<T2>,  2)
+//VSIP_IMPL_BINARY_OPS_FUNCTOR(fmod)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(ge,      T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(gt,      T1,          T2,           1)
+//VSIP_IMPL_BINARY_OPS_FUNCTOR(hypot)
+//VSIP_IMPL_BINARY_OPS_FUNCTOR(jmul)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(land,    T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(le,      T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(lt,      T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(lor,     T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(lxor,    T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(mul,     T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(mul,     T1,          complex<T2>,  2)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(mul,     complex<T1>, T2,           2)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(mul,     complex<T1>, complex<T2>,  6)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(max,     T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(maxmg,   T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(maxmg,   complex<T1>, complex<T2>, 27)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(maxmgsq, T1,          T2,           3)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(maxmgsq, complex<T1>, complex<T2>,  7)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(min,     T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(minmg,   T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(minmg,   complex<T1>, complex<T2>, 27)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(minmgsq, T1,          T2,           3)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(minmgsq, complex<T1>, complex<T2>,  7)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(ne,      T1,          T2,           1)
+VSIP_IMPL_BINARY_OPS_FUNCTOR(ne,      complex<T1>, complex<T2>,  2)
+//VSIP_IMPL_BINARY_OPS_FUNCTOR(pow)
+//VSIP_IMPL_BINARY_OPS_FUNCTOR(sub)
 
-// FIXME: Ops count for ternary ops
+#undef VSIP_IMPL_BINARY_OPS_FUNCTOR
+#undef VSIP_IMPL_BINARY_OPS
 
 
 
-// Reduction to count the number operations per point of an expression.
+/// Specializations for Ternary types
 
+#define VSIP_IMPL_TERNARY_OPS(OP, TYPE1, TYPE2, TYPE3, VALUE)	\
+template <typename T1,						\
+          typename T2,						\
+          typename T3>						\
+struct Ternary_op_count<OP, TYPE1, TYPE2, TYPE3>		\
+{								\
+  static unsigned const value = VALUE;				\
+}; 
+
+#define VSIP_IMPL_TERNARY_OPS_FUNCTOR(OP, TYPE1, TYPE2, TYPE3, VALUE)	\
+        VSIP_IMPL_TERNARY_OPS(OP##_functor, TYPE1, TYPE2, TYPE3, VALUE)
+
+// Short synonym for above.
+#define VSIP_IMPL_TOF(OP, T1, T2, T3, VALUE) \
+    VSIP_IMPL_TERNARY_OPS_FUNCTOR(OP, T1, T2, T3, VALUE)
+
+#define VSIP_IMPL_TERNARY_OPS_RRR(OP, VALUE) \
+    VSIP_IMPL_TOF(OP, T1,          T2,          T3,          VALUE)
+#define VSIP_IMPL_TERNARY_OPS_RRC(OP, VALUE) \
+    VSIP_IMPL_TOF(OP, T1,          T2,          complex<T3>, VALUE)
+#define VSIP_IMPL_TERNARY_OPS_RCR(OP, VALUE) \
+    VSIP_IMPL_TOF(OP, T1,          complex<T2>, T3,          VALUE)
+#define VSIP_IMPL_TERNARY_OPS_RCC(OP, VALUE) \
+    VSIP_IMPL_TOF(OP, T1,          complex<T2>, complex<T3>, VALUE)
+#define VSIP_IMPL_TERNARY_OPS_CRR(OP, VALUE) \
+    VSIP_IMPL_TOF(OP, complex<T1>, T2,          T3,          VALUE)
+#define VSIP_IMPL_TERNARY_OPS_CRC(OP, VALUE) \
+    VSIP_IMPL_TOF(OP, complex<T1>, T2,          complex<T3>, VALUE)
+#define VSIP_IMPL_TERNARY_OPS_CCR(OP, VALUE) \
+    VSIP_IMPL_TOF(OP, complex<T1>, complex<T2>, T3,          VALUE)
+#define VSIP_IMPL_TERNARY_OPS_CCC(OP, VALUE) \
+    VSIP_IMPL_TOF(OP, complex<T1>, complex<T2>, complex<T3>, VALUE)
+
+
+// The cost for ternary functions is computed by adding the costs for 
+// pure real, mixed real-complex and pure complex adds and multiples 
+// for the given equation:
+
+//  (t1 + t2) * t3
+//                            <  adds  >    <   muls   >
+//                            R   M   C     R   M     C
+VSIP_IMPL_TERNARY_OPS_RRR(am, 1 + 0 + 0*2 + 1 + 0*2 + 0*6)
+VSIP_IMPL_TERNARY_OPS_RRC(am, 1 + 0 + 0*2 + 0 + 0*2 + 0*6)
+VSIP_IMPL_TERNARY_OPS_RCR(am, 0 + 1 + 0*2 + 0 + 1*2 + 0*6)
+VSIP_IMPL_TERNARY_OPS_RCC(am, 0 + 1 + 0*2 + 0 + 0*2 + 1*6)
+VSIP_IMPL_TERNARY_OPS_CRR(am, 0 + 1 + 0*2 + 0 + 1*2 + 0*6)
+VSIP_IMPL_TERNARY_OPS_CRC(am, 0 + 1 + 0*2 + 0 + 0*2 + 1*6)
+VSIP_IMPL_TERNARY_OPS_CCR(am, 0 + 0 + 1*2 + 0 + 1*2 + 0*6)
+VSIP_IMPL_TERNARY_OPS_CCC(am, 0 + 0 + 1*2 + 0 + 0*2 + 1*6)
+
+//  t1 * t2 + (T1(1) - t1) * t3
+//                                 <  adds  >    <   muls   >
+//                                 R   M   C     R   M     C
+VSIP_IMPL_TERNARY_OPS_RRR(expoavg, 2 + 0 + 0*2 + 2 + 0*2 + 0*6)
+VSIP_IMPL_TERNARY_OPS_RRC(expoavg, 1 + 1 + 0*2 + 1 + 1*2 + 0*6)
+VSIP_IMPL_TERNARY_OPS_RCR(expoavg, 1 + 1 + 0*2 + 1 + 1*2 + 0*6)
+VSIP_IMPL_TERNARY_OPS_RCC(expoavg, 1 + 0 + 1*2 + 0 + 2*2 + 0*6)
+VSIP_IMPL_TERNARY_OPS_CRR(expoavg, 0 + 0 + 2*2 + 0 + 2*2 + 0*6)
+VSIP_IMPL_TERNARY_OPS_CRC(expoavg, 0 + 0 + 2*2 + 0 + 1*2 + 1*6)
+VSIP_IMPL_TERNARY_OPS_CCR(expoavg, 0 + 0 + 2*2 + 0 + 1*2 + 1*6)
+VSIP_IMPL_TERNARY_OPS_CCC(expoavg, 0 + 0 + 2*2 + 0 + 0*2 + 2*6)
+
+//VSIP_IMPL_TERNARY_OPS_FUNCTOR(ma)
+//VSIP_IMPL_TERNARY_OPS_FUNCTOR(msb)
+//VSIP_IMPL_TERNARY_OPS_FUNCTOR(sbm)
+//VSIP_IMPL_TERNARY_OPS_FUNCTOR(ite)
+
+#undef VSIP_IMPL_TERNARY_OPS_RRR
+#undef VSIP_IMPL_TERNARY_OPS_RRC
+#undef VSIP_IMPL_TERNARY_OPS_RCR
+#undef VSIP_IMPL_TERNARY_OPS_RCC
+#undef VSIP_IMPL_TERNARY_OPS_CRR
+#undef VSIP_IMPL_TERNARY_OPS_CRC
+#undef VSIP_IMPL_TERNARY_OPS_CCR
+#undef VSIP_IMPL_TERNARY_OPS_CCC
+#undef VSIP_IMPL_TOF
+#undef VSIP_IMPL_TERNARY_OPS_FUNCTOR
+#undef VSIP_IMPL_TERNARY_OPS
+
+
+/// Reduction to count the number operations per point of an expression.
+
 struct Reduce_expr_ops_per_point
 {
 public:
@@ -152,11 +369,14 @@
     typedef typename leaf_node<BlockT>::type type;
   };
 
+  template <typename BlockT>
+  struct transform<BlockT const> : public transform<BlockT> {};
+
   template <dimension_type            Dim0,
 	    template <typename> class Op,
 	    typename                  BlockT,
 	    typename                  T>
-  struct transform<Unary_expr_block<Dim0, Op, BlockT, T> const>
+  struct transform<Unary_expr_block<Dim0, Op, BlockT, T> >
   {
     typedef typename unary_node<Dim0, Op,
 				typename transform<BlockT>::type,
@@ -170,7 +390,7 @@
 	    typename                      RBlock,
 	    typename                      RType>
   struct transform<Binary_expr_block<Dim0, Op, LBlock, LType,
-				     RBlock, RType> const>
+				     RBlock, RType> >
   {
     typedef typename binary_node<Dim0, Op,
 				typename transform<LBlock>::type, LType,
@@ -187,7 +407,7 @@
 	    typename                      Block3,
 	    typename                      Type3>
   struct transform<Ternary_expr_block<Dim0, Op, Block1, Type1,
-				     Block2, Type2, Block3, Type3> const>
+				     Block2, Type2, Block3, Type3> >
   {
     typedef typename ternary_node<Dim0, Op,
 				typename transform<Block1>::type, Type1,
@@ -198,17 +418,158 @@
 };
 
 
+/// This generates the total number of operations per point in a given 
+/// expression.  It also computes the total number of points, as this
+/// information is needed to calculate the total number of operations.
 
 template <typename BlockT>
 struct Expr_ops_per_point
 {
+  static length_type size(BlockT const& src)
+  {
+    length_type size = src.size(BlockT::dim, 0);
+    if ( BlockT::dim > 1 )
+      size *= src.size(BlockT::dim, 1);
+    if ( BlockT::dim > 2 )
+      size *= src.size(BlockT::dim, 2);
+    return size;
+  }
+
   static unsigned const value =
     Reduce_expr_ops_per_point::template transform<BlockT>::type::value;
 };
 
 
 
+
+/// Reduction to generate a tag for the entire expression tree
+
+struct Reduce_expr_op_name
+{
+public:
+
+  template <typename BlockT>
+  struct transform
+  {
+    static std::string tag() 
+    {
+      std::string st;
+      st = Type_name<typename BlockT::value_type>::value;
+      return st;
+    }
+  };
+
+  template <typename BlockT>
+  struct transform<BlockT const> : public transform<BlockT> 
+  {};
+
+  template <dimension_type            Dim,
+	    typename                  T>
+  struct transform<Scalar_block<Dim, T> >
+  {
+    static std::string tag() 
+    {
+      std::string st;
+      st = Scalar_type_name<T>::value;
+      return st;
+    }
+  };
+
+  template <dimension_type            Dim0,
+	    template <typename> class Op,
+	    typename                  Block,
+	    typename                  Type>
+  struct transform<Unary_expr_block<Dim0, Op, 
+                                    Block, Type> >
+  {
+    static std::string tag()
+    {
+      return Op<Type>::name() + std::string("(") 
+        + transform<Block>::tag() + std::string(")");
+    } 
+  };
+
+  template <dimension_type                Dim0,
+	    template <typename, typename> class Op,
+	    typename                      LBlock,
+	    typename                      LType,
+	    typename                      RBlock,
+	    typename                      RType>
+  struct transform<Binary_expr_block<Dim0, Op, 
+                                     LBlock, LType,
+                                     RBlock, RType> >
+  {
+    static std::string tag()
+    {
+      return Op<LType, RType>::name() + std::string("(")
+        + transform<LBlock>::tag() + std::string(",")
+        + transform<RBlock>::tag() + std::string(")"); 
+    } 
+  };
+
+  template <dimension_type                                Dim0,
+	    template <typename, typename, typename> class Op,
+	    typename                                      Block1,
+	    typename                                      Type1,
+	    typename                                      Block2,
+	    typename                                      Type2,
+	    typename                                      Block3,
+	    typename                                      Type3>
+  struct transform<Ternary_expr_block<Dim0, Op, 
+                                     Block1, Type1,
+                                     Block2, Type2,
+                                     Block3, Type3> >
+  {
+    static std::string tag()
+    {
+      return Op<Type1, Type2, Type3>::name() + std::string("(")
+        + transform<Block1>::tag() + std::string(",")
+        + transform<Block2>::tag() + std::string(",")
+        + transform<Block3>::tag() + std::string(")"); 
+
+    } 
+  };
+
+};
+
+
+/// This generates a tag for an expression in standard prefix notation
+/// where the operator is shown, followed by the list of operands in
+/// parenthesis.  The operator may be one of  the common binary 
+/// operators +-*/ or simply the name of the function.  User-defined
+/// expression evaluators will use one of 'unary', 'binary' or 'ternary' 
+/// for the function name.  The operand will be one of the letters 'S', 
+/// 'D', 'C', and 'Z' for views of those types (using the BLAS convention).
+/// Scalar operands use lower-case equivalents of the same letters.
+/// For example for matrices of single-precision values where A and B 
+/// are real and C is complex:
+///
+///   A * B + C    -->  +(*(S,S),C)
+///   A * 5.f + C  -->  +(*(S,s),C)
+///   A * (B + C)  -->  *(S,+(S,C))
+
+template <typename EvalExpr,
+          typename BlockT>
+struct Expr_op_name
+{
+  static std::string tag(BlockT const& src)
+  {
+    std::ostringstream  tag;
+    tag << EvalExpr::name() << " "
+        << BlockT::dim << "D "
+        << Reduce_expr_op_name::template transform<BlockT>::tag() << " "
+        << src.size(BlockT::dim, 0);
+    if ( BlockT::dim > 1 )
+      tag << "x" << src.size(BlockT::dim, 1);
+    if ( BlockT::dim > 2 )
+      tag << "x" << src.size(BlockT::dim, 2);
+
+    return tag.str();
+  }
+};
+
+
 } // namespace vsip::impl
 } // namespace vsip
 
-#endif // VSIP_IMPL_EXPR_OPS_PER_POINT_HPP
+#endif // VSIP_IMPL_EXPR_OPS_INFO_HPP
Index: src/vsip/impl/expr_operations.hpp
===================================================================
--- src/vsip/impl/expr_operations.hpp	(revision 147065)
+++ src/vsip/impl/expr_operations.hpp	(working copy)
@@ -33,6 +33,7 @@
 {
   typedef Operand result_type;
 
+  static char const* name() { return "+"; }
   static result_type apply(Operand op) { return op;}
   result_type operator()(Operand op) const { return apply(op);}
 };
@@ -42,6 +43,7 @@
 {
   typedef Operand result_type;
 
+  static char const* name() { return "-"; }
   static result_type apply(Operand op) { return -op;}
   result_type operator()(Operand op) const { return apply(op);}
 };
@@ -51,6 +53,7 @@
 {
   typedef typename Promotion<LType, RType>::type result_type;
 
+  static char const* name() { return "+"; }
   static result_type apply(LType lhs, RType rhs) { return lhs + rhs;}
   result_type operator()(LType lhs, RType rhs) const { return apply(lhs, rhs);}
 };
@@ -60,6 +63,7 @@
 {
   typedef typename Promotion<LType, RType>::type result_type;
 
+  static char const* name() { return "-"; }
   static result_type apply(LType lhs, RType rhs) { return lhs - rhs;}
   result_type operator()(LType lhs, RType rhs) const { return apply(lhs, rhs);}
 };
@@ -69,6 +73,7 @@
 {
   typedef typename Promotion<LType, RType>::type result_type;
 
+  static char const* name() { return "*"; }
   static result_type apply(LType lhs, RType rhs) { return lhs * rhs;}
   result_type operator()(LType lhs, RType rhs) const { return apply(lhs, rhs);}
 };
@@ -78,6 +83,7 @@
 {
   typedef typename Promotion<LType, RType>::type result_type;
 
+  static char const* name() { return "/"; }
   static result_type apply(LType lhs, RType rhs) { return lhs / rhs;}
   result_type operator()(LType lhs, RType rhs) const { return apply(lhs, rhs);}
 };
Index: src/vsip/impl/sal/eval_elementwise.hpp
===================================================================
--- src/vsip/impl/sal/eval_elementwise.hpp	(revision 147065)
+++ src/vsip/impl/sal/eval_elementwise.hpp	(working copy)
@@ -481,7 +481,7 @@
          typename Type_if<Mercury_sal_tag,				\
                           Is_leaf_block<SrcBlock>::value>::type>	\
 {									\
-  static char const* name() { return "SEE_1_SAL_COPY"; }		\
+  static char const* name() { return "Expr_SAL_COPY"; }			\
 									\
   typedef typename DstBlock::value_type dst_type;			\
 									\
@@ -538,7 +538,7 @@
          typename Type_if<Mercury_sal_tag,				\
                           Is_leaf_block<Block1>::value>::type>		\
 {									\
-  static char const* name() { return "SEE_1_SAL_V"; }			\
+  static char const* name() { return "Expr_SAL_V"; }			\
 									\
   typedef Unary_expr_block<1, OP, Block1, Type1> const			\
 	SrcBlock;							\
@@ -615,7 +615,7 @@
                      Is_leaf_block<RBlock>::value>::type>		\
   : sal::Serial_expr_evaluator_base_mixed<OP, DstBlock, LBlock, RBlock, LType, RType>		\
 {									\
-  static char const* name() { return "SEE_1_SAL_VV"; }			\
+  static char const* name() { return "Expr_SAL_VV"; }			\
 									\
   typedef Binary_expr_block<1, OP, LBlock, LType, RBlock, RType>	\
     SrcBlock;								\
@@ -683,7 +683,7 @@
                                  Block3, Type3>,			\
          Mercury_sal_tag>						\
 {									\
-  static char const* name() { return "SEE_1_SAL_VVV"; }			\
+  static char const* name() { return "Expr_SAL_VVV"; }			\
 									\
   typedef Ternary_expr_block<1, OP,					\
                                  Block1, Type1,				\
@@ -770,7 +770,7 @@
            Block3, Type3> const,					\
          Mercury_sal_tag>						\
 {									\
-  static char const* name() { return "SEE_1_SAL_fVVV"; }		\
+  static char const* name() { return "Expr_SAL_fVVV"; }			\
 									\
   typedef Ternary_expr_block<1, OP,					\
            Unary_expr_block<1, UOP, Block1, Type1> const, Type1,	\
@@ -862,7 +862,7 @@
                      Is_leaf_block<Block2>::value &&			\
                      Is_leaf_block<Block3>::value>::type>		\
 {									\
-  static char const* name() { return "SEE_1_SAL_VV_V"; }		\
+  static char const* name() { return "Expr_SAL_VV_V"; }			\
 									\
   typedef Binary_expr_block<						\
                  1, OP2,						\
@@ -952,7 +952,7 @@
                      Is_leaf_block<Block2>::value &&			\
                      Is_leaf_block<Block3>::value>::type>		\
 {									\
-  static char const* name() { return "SEE_1_SAL_V_VV"; }		\
+  static char const* name() { return "Expr_SAL_V_VV"; }			\
 									\
   typedef Binary_expr_block<						\
                  1, OP2,						\
@@ -1051,7 +1051,7 @@
            Block3, Type3> const,					\
          Mercury_sal_tag>						\
 {									\
-  static char const* name() { return "SEE_1_SAL_fVV_V"; }		\
+  static char const* name() { return "Expr_SAL_fVV_V"; }		\
 									\
   typedef Binary_expr_block<						\
             1, OP2,							\
Index: src/vsip/impl/vmmul.hpp
===================================================================
--- src/vsip/impl/vmmul.hpp	(revision 147065)
+++ src/vsip/impl/vmmul.hpp	(working copy)
@@ -295,7 +295,7 @@
 			     const Vmmul_expr_block<SD, VBlock, MBlock>,
 			     Loop_fusion_tag>
 {
-  static char const* name() { return "SEE_1_Vmmul"; }
+  static char const* name() { return "Expr_Loop_Vmmul"; }
 
   typedef Vmmul_expr_block<SD, VBlock, MBlock> SrcBlock;
 
Index: src/vsip/impl/eval_dense_expr.hpp
===================================================================
--- src/vsip/impl/eval_dense_expr.hpp	(revision 147065)
+++ src/vsip/impl/eval_dense_expr.hpp	(working copy)
@@ -857,7 +857,7 @@
 	  typename       SrcBlock>
 struct Serial_expr_evaluator<Dim, DstBlock, SrcBlock, Dense_expr_tag>
 {
-  static char const* name() { return "SEE_EDV"; }
+  static char const* name() { return "Expr_Dense"; }
 
   static bool const ct_valid =
     Dim > 1 &&
@@ -871,7 +871,7 @@
 
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
-    VSIP_IMPL_COVER_BLK("EDV", SrcBlock);
+//    VSIP_IMPL_COVER_BLK("EDV", SrcBlock);
 
     typedef typename Redim_expr<1>::template transform<SrcBlock>::type
       new_src_type;
Index: src/vsip/impl/simd/expr_evaluator.hpp
===================================================================
--- src/vsip/impl/simd/expr_evaluator.hpp	(revision 147065)
+++ src/vsip/impl/simd/expr_evaluator.hpp	(working copy)
@@ -137,6 +137,8 @@
 	  typename RB>
 struct Serial_expr_evaluator<1, LB, RB, Simd_loop_fusion_tag>
 {
+  static char const* name() { return "Expr_SIMD_Loop"; }
+  
   static bool const ct_valid =
     // Is SIMD supported at all ?
     simd::Simd_traits<typename LB::value_type>::is_accel &&
@@ -160,10 +162,9 @@
 	      alignment_of(dda.data()) == 0 &&
 	    simd::Proxy_factory<RB>::rt_valid(rhs));
   }
-  
+
   static void exec(LB& lhs, RB const& rhs)
   {
-    VSIP_IMPL_COVER_BLK("SEE_SIMD_LF", RB);
     typedef typename simd::LValue_access_traits<typename LB::value_type> WAT;
     typedef typename simd::Proxy_factory<RB>::access_traits EAT;
     length_type const vec_size =
Index: src/vsip/impl/simd/eval-generic.hpp
===================================================================
--- src/vsip/impl/simd/eval-generic.hpp	(revision 147065)
+++ src/vsip/impl/simd/eval-generic.hpp	(working copy)
@@ -125,6 +125,8 @@
       1, typename Block_layout<LBlock>::layout_type>::type		\
     lblock_lp;								\
   									\
+  static char const* name() { return "Expr_SIMD_V-" #FCN; }		\
+  									\
   static bool const ct_valid = 						\
     !Is_expr_block<LBlock>::value &&					\
     simd::Is_algorithm_supported<					\
@@ -152,7 +154,6 @@
   {									\
     Ext_data<DstBlock, dst_lp> ext_dst(dst, SYNC_OUT);			\
     Ext_data<LBlock, lblock_lp> ext_l(src.op(), SYNC_IN);		\
-    VSIP_IMPL_COVER_FCN("eval_SIMD_V", FCN);				\
     FCN(ext_l.data(), ext_dst.data(), dst.size());			\
   }									\
 };
@@ -181,6 +182,8 @@
       1, typename Block_layout<RBlock>::layout_type>::type		\
     rblock_lp;								\
   									\
+  static char const* name() { return "Expr_SIMD_VV-" #FCN; }		\
+  									\
   static bool const ct_valid = 						\
     !Is_expr_block<LBlock>::value &&					\
     !Is_expr_block<RBlock>::value &&					\
@@ -216,7 +219,6 @@
     Ext_data<DstBlock, dst_lp>  ext_dst(dst, SYNC_OUT);			\
     Ext_data<LBlock, lblock_lp> ext_l(src.left(), SYNC_IN);		\
     Ext_data<RBlock, rblock_lp> ext_r(src.right(), SYNC_IN);		\
-    VSIP_IMPL_COVER_FCN("eval_SIMD_VV", FCN);				\
     FCN(ext_l.data(), ext_r.data(), ext_dst.data(), dst.size());	\
   }									\
 };
@@ -262,6 +264,8 @@
       1, typename Block_layout<RBlock>::layout_type>::type
     rblock_lp;
 
+  static char const* name() { return "Expr_SIMD_VV-simd::vgt"; }
+
   static bool const ct_valid = 
     !Is_expr_block<LBlock>::value &&
     !Is_expr_block<RBlock>::value &&
@@ -290,7 +294,6 @@
     Ext_data<DstBlock, dst_lp>  ext_dst(dst,         SYNC_OUT);
     Ext_data<LBlock, lblock_lp> ext_l  (src.left(),  SYNC_IN);
     Ext_data<RBlock, rblock_lp> ext_r  (src.right(), SYNC_IN);
-    VSIP_IMPL_COVER_FCN("eval_SIMD_VV", simd::vgt);
     simd::vgt(ext_l.data(), ext_r.data(), ext_dst.data(), dst.size());
   }
 };
@@ -319,6 +322,8 @@
       1, typename Block_layout<BlockT>::layout_type>::type		\
     block_lp;								\
 									\
+  static char const* name() { return "Expr_SIMD_V-" #FCN; }		\
+  									\
   static bool const ct_valid = 						\
     !Is_expr_block<BlockT>::value &&					\
      Type_equal<typename DstBlock::value_type, bool>::value &&		\
@@ -340,7 +345,6 @@
   {									\
     Ext_data<DstBlock, dst_lp>  ext_dst(dst,         SYNC_OUT);		\
     Ext_data<BlockT, block_lp>  ext_l  (src.op(),  SYNC_IN);		\
-    VSIP_IMPL_COVER_FCN("eval_SIMD_V", FCN);				\
     FCN(ext_l.data(), ext_dst.data(), dst.size());			\
   }									\
 };
@@ -367,6 +371,8 @@
       1, typename Block_layout<RBlock>::layout_type>::type		\
     rblock_lp;								\
 									\
+  static char const* name() { return "Expr_SIMD_VV-" #FCN; }		\
+  									\
   static bool const ct_valid = 						\
     !Is_expr_block<LBlock>::value &&					\
     !Is_expr_block<RBlock>::value &&					\
@@ -393,7 +399,6 @@
     Ext_data<DstBlock, dst_lp>  ext_dst(dst,         SYNC_OUT);		\
     Ext_data<LBlock, lblock_lp> ext_l  (src.left(),  SYNC_IN);		\
     Ext_data<RBlock, rblock_lp> ext_r  (src.right(), SYNC_IN);		\
-    VSIP_IMPL_COVER_FCN("eval_SIMD_VV", FCN);				\
     FCN(ext_l.data(), ext_r.data(), ext_dst.data(), dst.size());	\
   }									\
 };
@@ -428,6 +433,8 @@
 			    VBlock, complex<T> >
 	SrcBlock;
 
+  static char const* name() { return "Expr_SIMD_V-simd::rscvmul"; }
+
   static bool const ct_valid = 
     !Is_expr_block<VBlock>::value &&
     simd::Is_algorithm_supported<
@@ -479,6 +486,8 @@
 			    Scalar_block<1, T>, T>
 	SrcBlock;
 
+  static char const* name() { return "Expr_SIMD_V-simd::rscvmul"; }
+
   static bool const ct_valid = 
     !Is_expr_block<VBlock>::value &&
     simd::Is_algorithm_supported<
Index: src/vsip/impl/fns_elementwise.hpp
===================================================================
--- src/vsip/impl/fns_elementwise.hpp	(revision 147065)
+++ src/vsip/impl/fns_elementwise.hpp	(working copy)
@@ -27,206 +27,215 @@
 
 /// Macro to define a unary function on views in terms of
 /// its homologe on scalars.
-#define VSIP_IMPL_UNARY_FUNCTOR(name)                                     \
+#define VSIP_IMPL_UNARY_FUNCTOR(fname)                                    \
 template <typename T>                                                     \
-struct name##_functor                                                     \
+struct fname##_functor                                                    \
 {                                                                         \
   typedef T result_type;                                                  \
-  static result_type apply(T t) { return fn::name(t);}                    \
+  static char const* name() { return #fname; }                            \
+  static result_type apply(T t) { return fn::fname(t);}                   \
   result_type operator()(T t) const { return apply(t);}                   \
 };
 
-#define VSIP_IMPL_UNARY_FUNCTOR_RETN(name, retn)	       		  \
+#define VSIP_IMPL_UNARY_FUNCTOR_RETN(fname, retn)                         \
 template <typename T>                                                     \
-struct name##_functor                                                     \
+struct fname##_functor                                                    \
 {                                                                         \
   typedef retn result_type;                                               \
-  static result_type apply(T t) { return fn::name(t);}                    \
+  static char const* name() { return #fname; }                            \
+  static result_type apply(T t) { return fn::fname(t);}                   \
   result_type operator()(T t) const { return apply(t);}                   \
 };
 
-#define VSIP_IMPL_UNARY_DISPATCH(name)                                    \
+#define VSIP_IMPL_UNARY_DISPATCH(fname)                                   \
 template <typename T>                                                     \
-struct Dispatch_##name :                                                  \
+struct Dispatch_##fname :                                                 \
   ITE_Type<Is_view_type<T>::value,                                        \
-	   As_type<Unary_func_view<name##_functor, T> >,                  \
-	   As_type<name##_functor<T> > >::type                            \
+           As_type<Unary_func_view<fname##_functor, T> >,                 \
+           As_type<fname##_functor<T> > >::type                           \
 {                                                                         \
 };
 
-#define VSIP_IMPL_UNARY_FUNCTION(name)                                    \
+#define VSIP_IMPL_UNARY_FUNCTION(fname)                                   \
 template <typename T>                                                     \
-inline									  \
-typename Dispatch_##name<T>::result_type				  \
-name(T t) { return Dispatch_##name<T>::apply(t);}
+inline                                                                    \
+typename Dispatch_##fname<T>::result_type                                 \
+fname(T t) { return Dispatch_##fname<T>::apply(t);}
 
-#define VSIP_IMPL_UNARY_FUNC(name)                                        \
-VSIP_IMPL_UNARY_FUNCTOR(name)                                             \
-VSIP_IMPL_UNARY_DISPATCH(name)                                            \
-VSIP_IMPL_UNARY_FUNCTION(name)
+#define VSIP_IMPL_UNARY_FUNC(fname)                                       \
+VSIP_IMPL_UNARY_FUNCTOR(fname)                                            \
+VSIP_IMPL_UNARY_DISPATCH(fname)                                           \
+VSIP_IMPL_UNARY_FUNCTION(fname)
 
-#define VSIP_IMPL_UNARY_FUNC_RETN(name, retn)	 			  \
-VSIP_IMPL_UNARY_FUNCTOR_RETN(name, retn)				  \
-VSIP_IMPL_UNARY_DISPATCH(name)                                            \
-VSIP_IMPL_UNARY_FUNCTION(name)
+#define VSIP_IMPL_UNARY_FUNC_RETN(fname, retn)                            \
+VSIP_IMPL_UNARY_FUNCTOR_RETN(fname, retn)                                 \
+VSIP_IMPL_UNARY_DISPATCH(fname)                                           \
+VSIP_IMPL_UNARY_FUNCTION(fname)
 
 // Define a unary operator. Assume the associated Dispatch 
 // is already defined.
-#define VSIP_IMPL_UNARY_OP(op, name)           			          \
-template <typename T>	 				                  \
-typename Dispatch_##name<typename Is_view_type<T>::type>::result_type     \
-operator op(T t)                             \
-{ return Dispatch_##name<T>::apply(t);}
+#define VSIP_IMPL_UNARY_OP(op, fname)                                     \
+template <typename T>                                                     \
+typename Dispatch_##fname<typename Is_view_type<T>::type>::result_type    \
+operator op(T t)                                                          \
+{ return Dispatch_##fname<T>::apply(t);}
 
 /// Macro to define a binary function on views in terms of
 /// its homologe on scalars.
-#define VSIP_IMPL_BINARY_FUNCTOR(name)                                    \
-template <typename T1, typename T2>					  \
-struct name##_functor                                                     \
+#define VSIP_IMPL_BINARY_FUNCTOR(fname)                                   \
+template <typename T1, typename T2>                                       \
+struct fname##_functor                                                    \
 {                                                                         \
-  typedef typename Promotion<T1, T2>::type result_type;			  \
-  static result_type apply(T1 t1, T2 t2) { return fn::name(t1, t2);}	  \
-  result_type operator()(T1 t1, T2 t2) const { return apply(t1, t2);}	  \
+  typedef typename Promotion<T1, T2>::type result_type;                   \
+  static char const* name() { return #fname; }                            \
+  static result_type apply(T1 t1, T2 t2) { return fn::fname(t1, t2);}     \
+  result_type operator()(T1 t1, T2 t2) const { return apply(t1, t2);}     \
 };
 
-#define VSIP_IMPL_BINARY_FUNCTOR_RETN(name, retn)			  \
-template <typename T1, typename T2>					  \
-struct name##_functor                                                     \
+#define VSIP_IMPL_BINARY_FUNCTOR_RETN(fname, retn)                        \
+template <typename T1, typename T2>                                       \
+struct fname##_functor                                                    \
 {                                                                         \
-  typedef retn result_type;			                          \
-  static result_type apply(T1 t1, T2 t2) { return fn::name(t1, t2);}	  \
-  result_type operator()(T1 t1, T2 t2) const { return apply(t1, t2);}	  \
+  typedef retn result_type;                                               \
+  static char const* name() { return #fname; }                            \
+  static result_type apply(T1 t1, T2 t2) { return fn::fname(t1, t2);}     \
+  result_type operator()(T1 t1, T2 t2) const { return apply(t1, t2);}     \
 };
 
-#define VSIP_IMPL_BINARY_FUNCTOR_SCALAR_RETN(name)                        \
-template <typename T1, typename T2>					  \
-struct name##_functor                                                     \
+#define VSIP_IMPL_BINARY_FUNCTOR_SCALAR_RETN(fname)                       \
+template <typename T1, typename T2>                                       \
+struct fname##_functor                                                    \
 {                                                                         \
   typedef typename Scalar_of<typename Promotion<T1, T2>::type>::type      \
-		result_type;                                              \
-  static result_type apply(T1 t1, T2 t2) { return fn::name(t1, t2);}	  \
-  result_type operator()(T1 t1, T2 t2) const { return apply(t1, t2);}	  \
+                result_type;                                              \
+  static char const* name() { return #fname; }                            \
+  static result_type apply(T1 t1, T2 t2) { return fn::fname(t1, t2);}     \
+  result_type operator()(T1 t1, T2 t2) const { return apply(t1, t2);}     \
 };
 
-#define VSIP_IMPL_BINARY_DISPATCH(name)			                  \
-template <typename T1, typename T2>					  \
-struct Dispatch_##name :                                                  \
+#define VSIP_IMPL_BINARY_DISPATCH(fname)                                  \
+template <typename T1, typename T2>                                       \
+struct Dispatch_##fname :                                                 \
   ITE_Type<Is_view_type<T1>::value || Is_view_type<T2>::value,            \
-	   As_type<Binary_func_view<name##_functor, T1, T2> >,	  	  \
-	   As_type<name##_functor<T1, T2> > >::type			  \
+           As_type<Binary_func_view<fname##_functor, T1, T2> >,           \
+           As_type<fname##_functor<T1, T2> > >::type                      \
 {                                                                         \
 };
 
 // Define a dispatcher that only matches if at least one of the arguments
 // is a view type.
-#define VSIP_IMPL_BINARY_OP_DISPATCH(name)				  \
+#define VSIP_IMPL_BINARY_OP_DISPATCH(fname)                               \
 template <typename T1, typename T2,                                       \
           bool P = Is_view_type<T1>::value || Is_view_type<T2>::value>    \
-struct Dispatch_op_##name                                                 \
-  : As_type<Binary_func_view<name##_functor, T1, T2> >::type {};   	  \
+struct Dispatch_op_##fname                                                \
+  : As_type<Binary_func_view<fname##_functor, T1, T2> >::type {};         \
 template <typename T1, typename T2>                                       \
-struct Dispatch_op_##name<T1, T2, false> {};                              \
+struct Dispatch_op_##fname<T1, T2, false> {};                             \
 
-#define VSIP_IMPL_BINARY_FUNCTION(name)			                  \
-template <typename T1, typename T2>					  \
-inline									  \
-typename Dispatch_##name<T1, T2>::result_type				  \
-name(T1 t1, T2 t2) { return Dispatch_##name<T1, T2>::apply(t1, t2);}
+#define VSIP_IMPL_BINARY_FUNCTION(fname)                                  \
+template <typename T1, typename T2>                                       \
+inline                                                                    \
+typename Dispatch_##fname<T1, T2>::result_type                            \
+fname(T1 t1, T2 t2) { return Dispatch_##fname<T1, T2>::apply(t1, t2);}
 
-#define VSIP_IMPL_BINARY_OPERATOR_ONE(op, name)				\
-template <typename T1, typename T2>					\
-inline									\
-typename Dispatch_op_##name<T1, T2>::result_type			\
-operator op(T1 t1, T2 t2) { return Dispatch_op_##name<T1, T2>::apply(t1, t2);}
+#define VSIP_IMPL_BINARY_OPERATOR_ONE(op, fname)                          \
+template <typename T1, typename T2>                                       \
+inline                                                                    \
+typename Dispatch_op_##fname<T1, T2>::result_type                         \
+operator op(T1 t1, T2 t2) { return Dispatch_op_##fname<T1, T2>::apply(t1, t2);}
 
-#define VSIP_IMPL_BINARY_OPERATOR_TWO(op, name)       			\
-template <template <typename, typename> class View,			\
- 	  typename T1, typename Block1, typename T2>			\
-inline									\
-typename Dispatch_op_##name<View<T1, Block1>, T2>::result_type		\
-operator op(View<T1, Block1> t1, T2 t2)					\
-{ return Dispatch_op_##name<View<T1, Block1>, T2>::apply(t1, t2);}	\
-  									\
-template <template <typename, typename> class View,			\
- 	  typename T1, typename T2, typename Block2>			\
-inline									\
-typename Dispatch_op_##name<T1, View<T2, Block2> >::result_type		\
-operator op(T1 t1, View<T2, Block2> t2)					\
-{ return Dispatch_op_##name<T1, View<T2, Block2> >::apply(t1, t2);}	\
- 									\
-template <template <typename, typename> class LView,			\
- 	  template <typename, typename> class RView,			\
- 	  typename T1, typename Block1,					\
- 	  typename T2, typename Block2>					\
-inline									\
-typename Dispatch_op_##name<LView<T1, Block1>,				\
- 			    RView<T2, Block2> >::result_type		\
-operator op(LView<T1, Block1> t1, RView<T2, Block2> t2)			\
-{ return Dispatch_op_##name<LView<T1, Block1>, RView<T2, Block2> >::apply(t1, t2);}
+#define VSIP_IMPL_BINARY_OPERATOR_TWO(op, fname)                          \
+template <template <typename, typename> class View,                       \
+          typename T1, typename Block1, typename T2>                      \
+inline                                                                    \
+typename Dispatch_op_##fname<View<T1, Block1>, T2>::result_type           \
+operator op(View<T1, Block1> t1, T2 t2)                                   \
+{ return Dispatch_op_##fname<View<T1, Block1>, T2>::apply(t1, t2);}       \
+                                                                          \
+template <template <typename, typename> class View,                       \
+          typename T1, typename T2, typename Block2>                      \
+inline                                                                    \
+typename Dispatch_op_##fname<T1, View<T2, Block2> >::result_type          \
+operator op(T1 t1, View<T2, Block2> t2)                                   \
+{ return Dispatch_op_##fname<T1, View<T2, Block2> >::apply(t1, t2);}      \
+                                                                          \
+template <template <typename, typename> class LView,                      \
+          template <typename, typename> class RView,                      \
+          typename T1, typename Block1,                                   \
+          typename T2, typename Block2>                                   \
+inline                                                                    \
+typename Dispatch_op_##fname<LView<T1, Block1>,                           \
+                             RView<T2, Block2> >::result_type             \
+operator op(LView<T1, Block1> t1, RView<T2, Block2> t2)                   \
+{ return Dispatch_op_##fname<LView<T1, Block1>,                           \
+                             RView<T2, Block2> >::apply(t1, t2);}
 
 #if (defined(__GNUC__) && __GNUC__ < 4) || defined(__ghs__)
-# define VSIP_IMPL_BINARY_OPERATOR(op, name) VSIP_IMPL_BINARY_OPERATOR_ONE(op, name)
+# define VSIP_IMPL_BINARY_OPERATOR(op, fname)                             \
+VSIP_IMPL_BINARY_OPERATOR_ONE(op, fname)
 #else
-# define VSIP_IMPL_BINARY_OPERATOR(op, name) VSIP_IMPL_BINARY_OPERATOR_TWO(op, name)
+# define VSIP_IMPL_BINARY_OPERATOR(op, fname)                             \
+VSIP_IMPL_BINARY_OPERATOR_TWO(op, fname)
 #endif
 
 
-#define VSIP_IMPL_BINARY_VIEW_FUNCTION(name)	       	                  \
+#define VSIP_IMPL_BINARY_VIEW_FUNCTION(fname)                             \
 template <template <typename, typename> class V,                          \
-          typename T, typename B>					  \
-inline									  \
-typename Dispatch_##name<V<T,B>, V<T,B> >::result_type           	  \
-name(V<T,B> t1, V<T,B> t2)                                                \
-{ return Dispatch_##name<V<T,B>, V<T,B> >::apply(t1, t2);}
+          typename T, typename B>                                         \
+inline                                                                    \
+typename Dispatch_##fname<V<T,B>, V<T,B> >::result_type                   \
+fname(V<T,B> t1, V<T,B> t2)                                               \
+{ return Dispatch_##fname<V<T,B>, V<T,B> >::apply(t1, t2);}
 
-#define VSIP_IMPL_BINARY_FUNC(name)                                       \
-VSIP_IMPL_BINARY_FUNCTOR(name)                                            \
-VSIP_IMPL_BINARY_DISPATCH(name)                                           \
-VSIP_IMPL_BINARY_FUNCTION(name)                                           \
-VSIP_IMPL_BINARY_VIEW_FUNCTION(name)
+#define VSIP_IMPL_BINARY_FUNC(fname)                                      \
+VSIP_IMPL_BINARY_FUNCTOR(fname)                                           \
+VSIP_IMPL_BINARY_DISPATCH(fname)                                          \
+VSIP_IMPL_BINARY_FUNCTION(fname)                                          \
+VSIP_IMPL_BINARY_VIEW_FUNCTION(fname)
 
-#define VSIP_IMPL_BINARY_FUNC_RETN(name, retn)	 			  \
-VSIP_IMPL_BINARY_FUNCTOR_RETN(name, retn)				  \
-VSIP_IMPL_BINARY_DISPATCH(name)                                           \
-VSIP_IMPL_BINARY_FUNCTION(name)
+#define VSIP_IMPL_BINARY_FUNC_RETN(fname, retn)                           \
+VSIP_IMPL_BINARY_FUNCTOR_RETN(fname, retn)                                \
+VSIP_IMPL_BINARY_DISPATCH(fname)                                          \
+VSIP_IMPL_BINARY_FUNCTION(fname)
 
-#define VSIP_IMPL_BINARY_FUNC_SCALAR_RETN(name)	 			  \
-VSIP_IMPL_BINARY_FUNCTOR_SCALAR_RETN(name)				  \
-VSIP_IMPL_BINARY_DISPATCH(name)                                           \
-VSIP_IMPL_BINARY_FUNCTION(name)
+#define VSIP_IMPL_BINARY_FUNC_SCALAR_RETN(fname)                          \
+VSIP_IMPL_BINARY_FUNCTOR_SCALAR_RETN(fname)                               \
+VSIP_IMPL_BINARY_DISPATCH(fname)                                          \
+VSIP_IMPL_BINARY_FUNCTION(fname)
 
-#define VSIP_IMPL_BINARY_OP(op, name)     				  \
-VSIP_IMPL_BINARY_OP_DISPATCH(name)					  \
-VSIP_IMPL_BINARY_OPERATOR(op, name)
+#define VSIP_IMPL_BINARY_OP(op, fname)                                    \
+VSIP_IMPL_BINARY_OP_DISPATCH(fname)                                       \
+VSIP_IMPL_BINARY_OPERATOR(op, fname)
 
 /// Macro to define a ternary function on views in terms of
 /// its homologe on scalars.
-#define VSIP_IMPL_TERNARY_FUNC(name)                                      \
-template <typename T1, typename T2, typename T3>			  \
-struct name##_functor                                                     \
+#define VSIP_IMPL_TERNARY_FUNC(fname)                                     \
+template <typename T1, typename T2, typename T3>                          \
+struct fname##_functor                                                    \
 {                                                                         \
   typedef typename Promotion<typename Promotion<T1, T2>::type,            \
                              T3>::type result_type;                       \
+  static char const* name() { return #fname; }                            \
   static result_type apply(T1 t1, T2 t2, T3 t3)                           \
-  { return fn::name(t1, t2, t3);}                                         \
+  { return fn::fname(t1, t2, t3);}                                        \
   result_type operator()(T1 t1, T2 t2, T3 t3) const                       \
-  { return apply(t1, t2, t3);}						  \
+  { return apply(t1, t2, t3);}                                            \
 };                                                                        \
                                                                           \
-template <typename T1, typename T2, typename T3>			  \
-struct Dispatch_##name :                                                  \
+template <typename T1, typename T2, typename T3>                          \
+struct Dispatch_##fname :                                                 \
   ITE_Type<Is_view_type<T1>::value ||                                     \
            Is_view_type<T2>::value ||                                     \
-           Is_view_type<T3>::value,					  \
-	   As_type<Ternary_func_view<name##_functor, T1, T2, T3> >,    	  \
-	   As_type<name##_functor<T1, T2, T3> > >::type			  \
+           Is_view_type<T3>::value,                                       \
+           As_type<Ternary_func_view<fname##_functor, T1, T2, T3> >,      \
+           As_type<fname##_functor<T1, T2, T3> > >::type                  \
 {                                                                         \
 };                                                                        \
                                                                           \
-template <typename T1, typename T2, typename T3>      	      		  \
-typename Dispatch_##name<T1, T2, T3>::result_type		       	  \
-name(T1 t1, T2 t2, T3 t3)                                                 \
-{ return Dispatch_##name<T1, T2, T3>::apply(t1, t2, t3);}
+template <typename T1, typename T2, typename T3>                          \
+typename Dispatch_##fname<T1, T2, T3>::result_type                        \
+fname(T1 t1, T2 t2, T3 t3)                                                \
+{ return Dispatch_##fname<T1, T2, T3>::apply(t1, t2, t3);}
 
 
 /***********************************************************************
@@ -241,6 +250,7 @@
 struct arg_functor<std::complex<T> >
 {
   typedef T result_type;
+  static char const* name() { return "arg"; }                
   static result_type apply(std::complex<T> t) { return fn::arg(t);}
   result_type operator()(std::complex<T> t) const { return apply(t);}
 };
@@ -260,6 +270,7 @@
 struct euler_functor
 {
   typedef std::complex<T> result_type;
+  static char const* name() { return "euler"; }                
   static result_type apply(T t) { return fn::euler(t);}
   result_type operator()(T t) const { return apply(t);}
 };
@@ -277,6 +288,7 @@
 struct imag_functor<std::complex<T> >
 {
   typedef T result_type;
+  static char const* name() { return "imag"; }                
   static result_type apply(std::complex<T> t) { return fn::imag(t);}
   result_type operator()(std::complex<T> t) const { return apply(t);}
 };
@@ -297,6 +309,7 @@
 struct real_functor<std::complex<T> >
 {
   typedef T result_type;
+  static char const* name() { return "real"; }                
   static result_type apply(std::complex<T> t) { return fn::real(t);}
   result_type operator()(std::complex<T> t) const { return apply(t);}
 };
@@ -319,6 +332,7 @@
 struct impl_real_functor
 {
   typedef typename Scalar_of<T>::type result_type;
+  static char const* name() { return "impl_real"; }                
   static result_type apply(T t) { return fn::impl_real(t);}
   result_type operator()(T t) const { return apply(t);}
 };
@@ -330,6 +344,7 @@
 struct impl_imag_functor
 {
   typedef typename Scalar_of<T>::type result_type;
+  static char const* name() { return "impl_imag"; }                
   static result_type apply(T t) { return fn::impl_imag(t);}
   result_type operator()(T t) const { return apply(t);}
 };
@@ -406,6 +421,7 @@
 struct bxor_or_lxor_functor
 {
   typedef typename Promotion<T1, T2>::type result_type;
+  static char const* name() { return "bxor"; }                
   static result_type apply(T1 t1, T2 t2) { return fn::bxor(t1, t2);}
   result_type operator()(T1 t1, T2 t2) const { return apply(t1, t2);}
 };
@@ -414,6 +430,7 @@
 struct bxor_or_lxor_functor<bool, bool>
 {
   typedef bool result_type;
+  static char const* name() { return "lxor"; }                
   static result_type apply(bool t1, bool t2) { return fn::lxor(t1, t2);}
   result_type operator()(bool t1, bool t2) const { return apply(t1, t2);}
 };
Index: src/vsip/impl/ipp.hpp
===================================================================
--- src/vsip/impl/ipp.hpp	(revision 147065)
+++ src/vsip/impl/ipp.hpp	(working copy)
@@ -288,7 +288,7 @@
     Unary_expr_block<1, OP, Block, Type> const,				\
     Intel_ipp_tag>							\
 {									\
-  static char const* name() { return "SEE_IPP_V-" #FUN; }		\
+  static char const* name() { return "Expr_IPP_V-" #FUN; }		\
 									\
   typedef typename Adjust_layout_dim<					\
       1, typename Block_layout<DstBlock>::layout_type>::type		\
@@ -356,7 +356,7 @@
   : ipp::Serial_expr_evaluator_base<OP, DstBlock,			\
 				    LBlock, RBlock, LType, RType>	\
 {									\
-  static char const* name() { return "SEE_IPP_VV-" #FUN; }		\
+  static char const* name() { return "Expr_IPP_VV-" #FUN; }		\
 									\
   typedef Binary_expr_block<1, OP, LBlock, LType, RBlock, RType>	\
     SrcBlock;								\
@@ -510,7 +510,7 @@
   : ipp::Scalar_view_evaluator_base<OP, DstBlock, SType,		\
                                     VBlock, VType, true>		\
 {									\
-  static char const* name() { return "SEE_IPP_SV-" #FCN; }		\
+  static char const* name() { return "Expr_IPP_SV-" #FCN; }		\
 									\
   typedef Binary_expr_block<1, OP,					\
 			    Scalar_block<1, SType>, SType,		\
@@ -545,7 +545,7 @@
   : ipp::Scalar_view_evaluator_base<OP, DstBlock, float,		\
                                     VBlock, float, true>		\
 {									\
-  static char const* name() { return "SEE_IPP_SV_FO-" #FCN; }		\
+  static char const* name() { return "Expr_IPP_SV_FO-" #FCN; }		\
 									\
   typedef float SType;							\
   typedef float VType;							\
@@ -587,7 +587,7 @@
   : ipp::Scalar_view_evaluator_base<OP, DstBlock, SType,		\
                                     VBlock, VType, false>		\
 {									\
-  static char const* name() { return "SEE_IPP_VS-" #FCN; }		\
+  static char const* name() { return "Expr_IPP_VS-" #FCN; }		\
 									\
   typedef Binary_expr_block<1, OP,					\
 			    VBlock, VType,				\
@@ -624,7 +624,7 @@
   : ipp::Scalar_view_evaluator_base<OP, DstBlock, SType,		\
                                     VBlock, VType, false>		\
 {									\
-  static char const* name() { return "SEE_IPP_VS_AS_SV-" #FCN; }	\
+  static char const* name() { return "Expr_IPP_VS_AS_SV-" #FCN; }	\
 									\
   typedef Binary_expr_block<1, OP,					\
 			    VBlock, VType,				\
Index: src/vsip/impl/expr_ops_per_point.hpp
===================================================================
--- src/vsip/impl/expr_ops_per_point.hpp	(revision 147065)
+++ src/vsip/impl/expr_ops_per_point.hpp	(working copy)
@@ -1,214 +0,0 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    vsip/impl/expr_ops_per_point.hpp
-    @author  Jules Bergmann
-    @date    2006-08-04
-    @brief   VSIPL++ Library: Determine the number of ops per point for
-                              an expression template.
-*/
-
-#ifndef VSIP_IMPL_EXPR_OPS_PER_POINT_HPP
-#define VSIP_IMPL_EXPR_OPS_PER_POINT_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <vsip/impl/metaprogramming.hpp>
-#include <vsip/impl/block-traits.hpp>
-#include <vsip/impl/expr_scalar_block.hpp>
-#include <vsip/impl/expr_unary_block.hpp>
-#include <vsip/impl/expr_binary_block.hpp>
-#include <vsip/impl/expr_ternary_block.hpp>
-#include <vsip/impl/coverage.hpp>
-
-
-
-/***********************************************************************
-  Declarations
-***********************************************************************/
-
-namespace vsip
-{
-namespace impl
-{
-
-
-// Traits classes to determine the ops for a particular operation.
-
-template <template <typename> class UnaryOp,
-	  typename                  T1>
-struct Unary_op_count
-{
-  static unsigned const value = 0;
-}; 
-
-template <template <typename, typename> class BinaryOp,
-	  typename                            T1,
-	  typename                            T2>
-struct Binary_op_count
-{
-  static unsigned const value = 0;
-}; 
-
-template <template <typename, typename, typename> class TernaryOp,
-	  typename                            T1,
-	  typename                            T2,
-	  typename                            T3>
-struct Ternary_op_count
-{
-  static unsigned const value = 0;
-}; 
-
-
-
-// FIXME: Ops count for unary ops
-
-#define BINARY_OPS(OP, TYPE1, TYPE2, VALUE)				\
-template <typename T1,							\
-          typename T2>							\
-struct Binary_op_count<OP, TYPE1, TYPE2>				\
-{									\
-  static unsigned const value = VALUE;					\
-}; 
-
-BINARY_OPS(op::Add,  T1,          T2,          1)
-BINARY_OPS(op::Add,  T1,          complex<T2>, 1)
-BINARY_OPS(op::Add,  complex<T1>, T2,          1)
-BINARY_OPS(op::Add,  complex<T1>, complex<T2>, 2)
-
-BINARY_OPS(op::Mult, T1,          T2,          1)
-BINARY_OPS(op::Mult, T1,          complex<T2>, 2)
-BINARY_OPS(op::Mult, complex<T1>, T2,          2)
-BINARY_OPS(op::Mult, complex<T1>, complex<T2>, 6)
-
-#undef BINARY_OPS
-
-// FIXME: Ops count for ternary ops
-
-
-
-// Reduction to count the number operations per point of an expression.
-
-struct Reduce_expr_ops_per_point
-{
-public:
-  template <typename BlockT>
-  struct leaf_node
-  {
-    typedef Int_type<0> type;
-  };
-
-  template <dimension_type Dim0,
-	    typename       T>
-  struct leaf_node<Scalar_block<Dim0, T> >
-  {
-    typedef Int_type<0> type;
-  };
-
-  template <dimension_type            Dim0,
-	    template <typename> class Op,
-	    typename                  NewBlockT,
-	    typename                  NewT>
-  struct unary_node
-  {
-    typedef Int_type<Unary_op_count<Op, NewT>::value +
-                     NewBlockT::value> type;
-  };
-
-  template <dimension_type                Dim0,
-	    template <typename, typename> class Op,
-	    typename                      NewLBlock,
-	    typename                      NewLType,
-	    typename                      NewRBlock,
-	    typename                      NewRType>
-  struct binary_node
-  {
-    typedef Int_type<Binary_op_count<Op, NewLType, NewRType>::value +
-                     NewLBlock::value +
-                     NewRBlock::value> type;
-  };
-
-  template <dimension_type                          Dim0,
-	    template <typename, typename, typename> class Op,
-	    typename                                NewBlock1,
-	    typename                                NewType1,
-	    typename                                NewBlock2,
-	    typename                                NewType2,
-	    typename                                NewBlock3,
-	    typename                                NewType3>
-  struct ternary_node
-  {
-    typedef Int_type<
-      Ternary_op_count<Op, NewType1, NewType2, NewType3>::value +
-      NewBlock1::value +
-      NewBlock2::value +
-      NewBlock3::value> type;
-  };
-
-  template <typename BlockT>
-  struct transform
-  {
-    typedef typename leaf_node<BlockT>::type type;
-  };
-
-  template <dimension_type            Dim0,
-	    template <typename> class Op,
-	    typename                  BlockT,
-	    typename                  T>
-  struct transform<Unary_expr_block<Dim0, Op, BlockT, T> const>
-  {
-    typedef typename unary_node<Dim0, Op,
-				typename transform<BlockT>::type,
-				T>::type type;
-  };
-
-  template <dimension_type                Dim0,
-	    template <typename, typename> class Op,
-	    typename                      LBlock,
-	    typename                      LType,
-	    typename                      RBlock,
-	    typename                      RType>
-  struct transform<Binary_expr_block<Dim0, Op, LBlock, LType,
-				     RBlock, RType> const>
-  {
-    typedef typename binary_node<Dim0, Op,
-				typename transform<LBlock>::type, LType,
-				typename transform<RBlock>::type, RType>
-				::type type;
-  };
-
-  template <dimension_type                Dim0,
-	    template <typename, typename, typename> class Op,
-	    typename                      Block1,
-	    typename                      Type1,
-	    typename                      Block2,
-	    typename                      Type2,
-	    typename                      Block3,
-	    typename                      Type3>
-  struct transform<Ternary_expr_block<Dim0, Op, Block1, Type1,
-				     Block2, Type2, Block3, Type3> const>
-  {
-    typedef typename ternary_node<Dim0, Op,
-				typename transform<Block1>::type, Type1,
-				typename transform<Block2>::type, Type2,
-				typename transform<Block3>::type, Type3>
-				::type type;
-  };
-};
-
-
-
-template <typename BlockT>
-struct Expr_ops_per_point
-{
-  static unsigned const value =
-    Reduce_expr_ops_per_point::template transform<BlockT>::type::value;
-};
-
-
-
-} // namespace vsip::impl
-} // namespace vsip
-
-#endif // VSIP_IMPL_EXPR_OPS_PER_POINT_HPP
Index: src/vsip/impl/fns_userelt.hpp
===================================================================
--- src/vsip/impl/fns_userelt.hpp	(revision 147065)
+++ src/vsip/impl/fns_userelt.hpp	(working copy)
@@ -39,6 +39,8 @@
   template <typename A>
   struct Type : std::unary_function<A, R>
   {
+    static char const* name() { return "unary"; }
+
     Type(F f) : function_(f) {}
 
     R operator()(A a) const { return function_(a);}
@@ -56,6 +58,8 @@
   struct Type : std::unary_function<typename F::argument_type,
 				    typename F::result_type>
   {
+    static char const* name() { return "unary"; }
+
     Type(F f) : function_(f) {}
 
     typename F::result_type operator()(typename F::argument_type a) const 
@@ -73,6 +77,8 @@
   template <typename Dummy>
   struct Type : std::pointer_to_unary_function<A, R>
   {
+    static char const* name() { return "unary"; }
+
     Type(R (*f)(A)) : std::pointer_to_unary_function<A, R>(f) {}
   };
 };
@@ -83,6 +89,8 @@
   template <typename A1, typename A2>
   struct Type : std::binary_function<A1, A2, R>
   {
+    static char const* name() { return "binary"; }
+
     Type(F f) : function_(f) {}
 
     R operator()(A1 a1, A2 a2) const { return function_(a1, a2);}
@@ -101,6 +109,8 @@
                                      typename F::second_argument_type,
                                      typename F::result_type>
   {
+    static char const* name() { return "binary"; }
+
     Type(F f) : function_(f) {}
 
     typename F::result_type operator()(typename F::first_argument_type a1,
@@ -119,6 +129,8 @@
   template <typename Dummy1, typename Dummy2>
   struct Type : std::pointer_to_binary_function<A1, A2, R>
   {
+    static char const* name() { return "binary"; }
+
     Type(R (*f)(A1, A2)) : std::pointer_to_binary_function<A1, A2, R>(f) {}
   };
 };
@@ -134,6 +146,8 @@
     typedef A3 third_argument_type;
     typedef R result_type;
 
+    static char const* name() { return "ternary"; }
+
     Type(F f) : function_(f) {}
 
     R operator()(A1 a1, A2 a2, A3 a3) const { return function_(a1, a2, a3);}
@@ -155,6 +169,8 @@
     typedef A3 third_argument_type;
     typedef R result_type;
 
+    static char const* name() { return "ternary"; }
+
     Type(R (*f)(A1, A2, A3)) : function_(f) {}
 
     R operator()(A1 a1, A2 a2, A3 a3) const { return function_(a1, a2, a3);}
Index: src/vsip/impl/expr_serial_dispatch.hpp
===================================================================
--- src/vsip/impl/expr_serial_dispatch.hpp	(revision 147065)
+++ src/vsip/impl/expr_serial_dispatch.hpp	(working copy)
@@ -19,6 +19,7 @@
 #include <vsip/impl/expr_serial_evaluator.hpp>
 #include <vsip/impl/expr_serial_dispatch_fwd.hpp>
 #include <vsip/impl/eval_dense_expr.hpp>
+#include <vsip/impl/expr_ops_info.hpp>
 
 #ifdef VSIP_IMPL_HAVE_IPP
 #include <vsip/impl/ipp.hpp>
@@ -38,8 +39,9 @@
 #endif
 
 
+#define VSIP_IMPL_DO_PROFILE  (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_FNS)
 
-#if VSIP_IMPL_DO_COVERAGE 
+#if VSIP_IMPL_DO_COVERAGE
 #  define VSIP_IMPL_SD_PROFILE_POLICY Eval_coverage_policy
 #elif VSIP_IMPL_DO_PROFILE
 #  define VSIP_IMPL_SD_PROFILE_POLICY Eval_profile_policy
@@ -62,12 +64,18 @@
 template <typename EvalExpr>
 struct Eval_profile_policy
 {
+  typedef impl::profile::Scope_event event_type;
+
   template <typename DstBlock,
 	    typename SrcBlock>
-  Eval_profile_policy(DstBlock const&, SrcBlock const&)
+  Eval_profile_policy(DstBlock const&, SrcBlock const& src)
+    : event_( Expr_op_name<EvalExpr, SrcBlock>::tag(src), 
+              Expr_ops_per_point<SrcBlock>::value * 
+                Expr_ops_per_point<SrcBlock>::size(src) )
   {}
 
-  // TODO
+private:
+  event_type event_;
 };
 
 
Index: src/vsip/impl/expr_serial_evaluator.hpp
===================================================================
--- src/vsip/impl/expr_serial_evaluator.hpp	(revision 147065)
+++ src/vsip/impl/expr_serial_evaluator.hpp	(working copy)
@@ -21,7 +21,6 @@
 #include <vsip/impl/coverage.hpp>
 
 
-
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -52,6 +51,7 @@
 	  typename Tag>
 struct Serial_expr_evaluator
 {
+  static char const* name() { return "Expr"; }
   static bool const ct_valid = false;
 };
 
@@ -59,7 +59,7 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<1, DstBlock, SrcBlock, Loop_fusion_tag>
 {
-  static char const* name() { return "SEE_1"; }
+  static char const* name() { return "Expr_Loop"; }
   static bool const ct_valid = true;
   static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
   { return true; }
@@ -78,7 +78,7 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<1, DstBlock, SrcBlock, Copy_tag>
 {
-  static char const* name() { return "SEE_1_Copy"; }
+  static char const* name() { return "Expr_Copy"; }
 
   typedef typename Adjust_layout_dim<
       1, typename Block_layout<DstBlock>::layout_type>::type
@@ -134,7 +134,7 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<2, DstBlock, SrcBlock, Transpose_tag>
 {
-  static char const* name() { return "SEE_2_Transpose"; }
+  static char const* name() { return "Expr_Trans"; }
 
   typedef typename DstBlock::value_type dst_value_type;
   typedef typename SrcBlock::value_type src_value_type;
@@ -328,7 +328,7 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<2, DstBlock, SrcBlock, Loop_fusion_tag>
 {
-  static char const* name() { return "SEE_2"; }
+  static char const* name() { return "Expr_Loop"; }
   static bool const ct_valid = true;
   static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
   { return true; }
@@ -364,7 +364,7 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<3, DstBlock, SrcBlock, Loop_fusion_tag>
 {
-  static char const* name() { return "SEE_3"; }
+  static char const* name() { return "Expr_Loop"; }
   static bool const ct_valid = true;
   static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
   { return true; }
Index: src/vsip/selgen.hpp
===================================================================
--- src/vsip/selgen.hpp	(revision 147065)
+++ src/vsip/selgen.hpp	(working copy)
@@ -167,6 +167,7 @@
   struct clip_functor
   {
     typedef Tout result_type;
+    static char const* name() { return "clip"; }                
     result_type operator()(Tin0 t) const 
     {
       return t <= lower_threshold ? lower_clip_value 
@@ -183,6 +184,7 @@
   struct invclip_functor
   {
     typedef Tout result_type;
+    static char const* name() { return "invclip"; }                
     result_type operator()(Tin0 t) const 
     {
       return t < lower_threshold ? t
Index: tests/expr_ops_per_point.cpp
===================================================================
--- tests/expr_ops_per_point.cpp	(revision 147065)
+++ tests/expr_ops_per_point.cpp	(working copy)
@@ -1,70 +0,0 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    tests/expr_ops_per_point.cpp
-    @author  Jules Bergmann
-    @date    2006-08-04
-    @brief   VSIPL++ Library: Test Expr_ops_per_point expression template
-                              reduction.
-*/
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <vsip/initfin.hpp>
-#include <vsip/support.hpp>
-#include <vsip/matrix.hpp>
-#include <vsip/signal.hpp>
-#include <vsip/impl/expr_ops_per_point.hpp>
-
-#include <vsip_csl/test.hpp>
-
-using namespace std;
-using namespace vsip;
-
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-// Test that the ops/point of an EXPR is as expected by OPS.
-
-template <typename ViewT>
-void
-test_expr(unsigned ops, ViewT /*expr*/)
-{
-  typedef typename ViewT::block_type block_type;
-
-  test_assert(ops == impl::Expr_ops_per_point<block_type>::value);
-}
-
-
-void
-test()
-{
-  Vector<float> vec1(5);
-  Vector<float> vec2(5);
-  Vector<complex<float> > vec3(5);
-  Vector<complex<float> > vec4(5);
-
-  test_expr(1, vec1 + vec2);
-  test_expr(1, vec1 * vec2);
-  test_expr(2, vec1 * vec3);
-  test_expr(6, vec3 * vec4);
-}
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
-  test();
-
-  return 0;
-}
Index: tests/expr_ops_info.cpp
===================================================================
--- tests/expr_ops_info.cpp	(revision 147029)
+++ tests/expr_ops_info.cpp	(working copy)
@@ -1,10 +1,10 @@
 /* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    tests/expr_ops_per_point.cpp
+/** @file    tests/expr_ops_info.cpp
     @author  Jules Bergmann
     @date    2006-08-04
-    @brief   VSIPL++ Library: Test Expr_ops_per_point expression template
-                              reduction.
+    @brief   VSIPL++ Library: Test expression template reductions
+             used for generating operation counts and expression tags.
 */
 
 /***********************************************************************
@@ -15,7 +15,7 @@
 #include <vsip/support.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/signal.hpp>
-#include <vsip/impl/expr_ops_per_point.hpp>
+#include <vsip/impl/expr_ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 
@@ -31,7 +31,7 @@
 
 template <typename ViewT>
 void
-test_expr(unsigned ops, ViewT /*expr*/)
+test_expr_ops(unsigned ops, ViewT /*expr*/)
 {
   typedef typename ViewT::block_type block_type;
 
@@ -39,22 +39,63 @@
 }
 
 
+// Test that the operation tag generated for the given expression
+// is correct.
+
+template <typename ViewT>
 void
-test()
+test_expr_tag(char const* tag, ViewT /*expr*/)
 {
+  typedef typename ViewT::block_type block_type;
+
+  test_assert(tag == impl::Reduce_expr_op_name::template transform<block_type>::tag());
+}
+
+
+
+void
+test_op_counts()
+{
   Vector<float> vec1(5);
   Vector<float> vec2(5);
   Vector<complex<float> > vec3(5);
   Vector<complex<float> > vec4(5);
 
-  test_expr(1, vec1 + vec2);
-  test_expr(1, vec1 * vec2);
-  test_expr(2, vec1 * vec3);
-  test_expr(6, vec3 * vec4);
+  test_expr_ops(1, vec1 + vec2);
+  test_expr_ops(1, vec1 * vec2);
+  test_expr_ops(2, vec1 * vec3);
+  test_expr_ops(6, vec3 * vec4);
 }
 
 
+void
+test_tags()
+{
+  Vector<float> vec1(5);
+  Vector<float> vec2(5);
+  Vector<complex<float> > vec3(5);
+  Vector<complex<float> > vec4(5);
+  complex<double> z(2,1);
 
+  // unary
+  test_expr_tag("sin(S)", sin(vec1));
+  test_expr_tag("exp(C)", exp(vec3));
+
+  // binary
+  test_expr_tag("max(S,S)", max(vec1, vec2));
+  test_expr_tag("+(S,S)", vec1 + vec2);
+  test_expr_tag("*(S,S)", vec1 * vec2);
+  test_expr_tag("*(S,C)", vec1 * vec3);
+  test_expr_tag("*(C,C)", vec3 * vec4);
+  test_expr_tag("-(+(S,S),C)", (vec1 + vec2) - vec3);
+  test_expr_tag("+(S,-(S,C))", vec1 + (vec2 - vec3));
+  test_expr_tag("+(*(S,s),/(C,z))", vec1 * 3.f + vec3 / z);
+
+  // ternary
+  test_expr_tag("expoavg(S,S,C)", expoavg(vec1, vec2, vec3));
+}
+
+
 /***********************************************************************
   Main
 ***********************************************************************/
@@ -64,7 +105,8 @@
 {
   vsipl init(argc, argv);
 
-  test();
+  test_op_counts();
+  test_tags();
 
   return 0;
 }
Index: tests/GNUmakefile.inc.in
===================================================================
--- tests/GNUmakefile.inc.in	(revision 147065)
+++ tests/GNUmakefile.inc.in	(working copy)
@@ -1,4 +1,4 @@
-########################################################################
+######################################################### -*-Makefile-*-
 #
 # File:   GNUmakefile.inc.in
 # Author: Mark Mitchell 
@@ -27,10 +27,18 @@
 tests_run_ident :=-a run_id=$(tests_run_id)
 endif
 
+tests_cxx_sources := $(wildcard $(srcdir)/tests/*.cpp)
+
+tests_cxx_exes := \
+	$(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(tests_cxx_sources))
+
 ########################################################################
 # Rules
 ########################################################################
 
+$(tests_cxx_exes): %$(EXEEXT): %.$(OBJEXT) $(libs)
+	$(CXX) $(LDFLAGS) -o $@ $< -Llib -lvsip $(LIBS)
+
 check::	$(libs) $(tests_qmtest_extensions)
 	cd tests; qmtest run $(tests_run_ident) $(tests_ids); \
           result=$$?; test $$tmp=0 || $$tmp=2
