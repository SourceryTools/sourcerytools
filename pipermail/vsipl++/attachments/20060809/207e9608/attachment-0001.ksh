Index: src/vsip/impl/expr_op_names.hpp
===================================================================
--- src/vsip/impl/expr_op_names.hpp	(revision 0)
+++ src/vsip/impl/expr_op_names.hpp	(revision 0)
@@ -0,0 +1,241 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/expr_op_name.hpp
+    @author  Don McCoy
+    @date    2006-08-04
+    @brief   VSIPL++ Library: Determine the name of the operation(s) in
+                              an expression template.
+*/
+
+#ifndef VSIP_IMPL_EXPR_OP_NAME_HPP
+#define VSIP_IMPL_EXPR_OP_NAME_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <string>
+
+#include <vsip/impl/metaprogramming.hpp>
+#include <vsip/impl/block-traits.hpp>
+#include <vsip/impl/expr_operations.hpp>
+#include <vsip/impl/expr_scalar_block.hpp>
+#include <vsip/impl/expr_unary_block.hpp>
+#include <vsip/impl/expr_binary_block.hpp>
+#include <vsip/impl/expr_ternary_block.hpp>
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
+/// These generate char tags for given data types, defaulting to int
+/// with specializations for common floating point types.  These use
+/// BLAS/LAPACK convention.
+
+template <typename T> 
+struct Type_name 
+{ 
+  static char const value = 'I'; 
+};
+
+#define TYPE_NAME(T, VALUE)             \
+template <>                             \
+struct Type_name<T>                     \
+{                                       \
+  static char const value = VALUE;      \
+};
+
+TYPE_NAME(float,                'S');
+TYPE_NAME(double,               'D');
+TYPE_NAME(std::complex<float>,  'C');
+TYPE_NAME(std::complex<double>, 'Z');
+
+#undef TYPE_NAME
+
+
+/// These generate char tags for each of the operators.
+
+template <template <typename> class UnaryOp>
+struct Unary_op_name
+{
+  static char const value = 'u';
+}; 
+
+template <template <typename, typename> class BinaryOp>
+struct Binary_op_name
+{
+  static char const value = 'b';
+}; 
+
+#define BINARY_NAME(OP, VALUE)          \
+template <>                             \
+struct Binary_op_name<OP>               \
+{                                       \
+  static char const value = VALUE;      \
+}; 
+
+BINARY_NAME(op::Add,  '+');
+BINARY_NAME(op::Sub,  '-');
+BINARY_NAME(op::Mult, '*');
+BINARY_NAME(op::Div,  '/');
+
+#undef BINARY_NAME
+
+template <template <typename, typename, typename> class TernaryOp>
+struct Ternary_op_name
+{
+  static char const value = 't';
+}; 
+
+
+/// These generate tags for operators and their operands.
+
+template <template <typename> class UnaryOp,
+          typename                  T1>
+struct Unary_op_tag
+{
+  static std::string tag() 
+  { 
+    std::ostringstream   st;
+    st << Unary_op_name<UnaryOp>::value
+       << Type_name<T1>::value;
+
+    return st.str();
+  }
+}; 
+
+template <template <typename, typename> class BinaryOp,
+          typename                            T1,
+          typename                            T2>
+struct Binary_op_tag
+{
+  static std::string tag() 
+  { 
+    std::ostringstream   st;
+    st << Binary_op_name<BinaryOp>::value
+       << Type_name<T1>::value
+       << Type_name<T2>::value;
+
+    return st.str();
+  }
+}; 
+
+template <template <typename, typename, typename> class TernaryOp,
+          typename                                      T1,
+          typename                                      T2,
+          typename                                      T3>
+struct Ternary_op_tag
+{
+  static std::string tag() 
+  { 
+    std::ostringstream   st;
+    st << Ternary_op_name<TernaryOp>::value
+       << Type_name<T1>::value
+       << Type_name<T2>::value
+       << Type_name<T3>::value;
+
+    return st.str();
+  }
+}; 
+
+
+
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
+    // Leaf nodes get empty tags
+    static std::string tag() { return std::string(); }
+  };
+
+  template <dimension_type            Dim0,
+	    template <typename> class Op,
+	    typename                  Block,
+	    typename                  Type>
+  struct transform<Unary_expr_block<Dim0, Op, 
+                                    Block, Type> const>
+  {
+    static std::string tag()
+    {
+      return transform<Block>::tag() + Unary_op_tag<Op, Type>::tag();
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
+                                     RBlock, RType> const>
+  {
+    static std::string tag()
+    {
+      return transform<LBlock>::tag() + transform<RBlock>::tag() + 
+        Binary_op_tag<Op, LType, RType>::tag();
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
+                                     Block3, Type3> const>
+  {
+    static std::string tag()
+    {
+      return transform<Block1>::tag() + transform<Block2>::tag() + 
+        transform<Block3>::tag() + Ternary_op_tag<Op, Type1, Type2, Type3>::tag();
+    } 
+  };
+
+};
+
+
+/// This generates a tag for an expression consisting of one or more of the
+/// letters 'u', 'b' or 't' to describe an operator followed by one, two or 
+/// three of the letters 'S', 'D', 'C', and 'Z' to describe the operand types. 
+/// The common binary operands +-*/ are listed instead of a 'b' as needed.  
+/// Expressions may have multiple operators - they are listed in order of 
+/// precedence.  For example for matrices of single-precision values where
+/// A and B are real and C is complex:
+///
+///   A * B + C    -->  *SS+SC
+///   A * (B + C)  -->  +SC*SC
+
+template <typename BlockT>
+struct Expr_op_name
+{
+  static std::string tag()
+  {
+    return Reduce_expr_op_name::template transform<BlockT>::tag();
+  }
+};
+
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_EXPR_OP_NAME_HPP
Index: src/vsip/impl/eval_dense_expr.hpp
===================================================================
--- src/vsip/impl/eval_dense_expr.hpp	(revision 146504)
+++ src/vsip/impl/eval_dense_expr.hpp	(working copy)
@@ -869,6 +869,17 @@
 
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
+    length_type size_0 = dst.size(Dim, 0);
+    length_type size_1 = dst.size(Dim, 1);
+    length_type size_2 = (Dim > 2) ? dst.size(Dim, 1) : 1;
+
+    std::ostringstream  tag;
+    tag << "Expr[Dense] " << Dim << "D " << impl::Expr_op_name<SrcBlock>::tag()
+        << " " << size_0 << "x" << size_1;
+    if (Dim > 2)     tag << "x" << size_2;
+    impl::profile::Scope_event event( tag.str(), 
+      impl::Expr_ops_per_point<SrcBlock>::value * size_0 * size_1 * size_2 );
+
     VSIP_IMPL_COVER_BLK("EDV", SrcBlock);
 
     typedef typename Redim_expr<1>::template transform<SrcBlock>::type
Index: src/vsip/impl/expr_ops_per_point.hpp
===================================================================
--- src/vsip/impl/expr_ops_per_point.hpp	(revision 146504)
+++ src/vsip/impl/expr_ops_per_point.hpp	(working copy)
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
 
 
@@ -43,18 +45,21 @@
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
@@ -62,14 +67,57 @@
 
 
 
-// FIXME: Ops count for unary ops
+#define UNARY_OPS_FUNCTOR(OP, TYPE, VALUE)		\
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
+//UNARY_OPS_FUNCTOR(acos)
+//UNARY_OPS_FUNCTOR(arg)
+//UNARY_OPS_FUNCTOR(asin)
+//UNARY_OPS_FUNCTOR(atan)
+//UNARY_OPS_FUNCTOR(bnot)
+//UNARY_OPS_FUNCTOR(ceil)
+//UNARY_OPS_FUNCTOR(conj)
+UNARY_OPS_FUNCTOR(cos,   T,            1);
+UNARY_OPS_FUNCTOR(cos,   complex<T>,  12);
+//UNARY_OPS_FUNCTOR(cosh)
+//UNARY_OPS_FUNCTOR(euler)
+//UNARY_OPS_FUNCTOR(exp)
+//UNARY_OPS_FUNCTOR(exp10)
+//UNARY_OPS_FUNCTOR(floor)
+//UNARY_OPS_FUNCTOR(imag)
+//UNARY_OPS_FUNCTOR(lnot)
+//UNARY_OPS_FUNCTOR(log)
+//UNARY_OPS_FUNCTOR(log10)
+//UNARY_OPS_FUNCTOR(mag)
+//UNARY_OPS_FUNCTOR(magsq)
+//UNARY_OPS_FUNCTOR(neg)
+//UNARY_OPS_FUNCTOR(real)
+//UNARY_OPS_FUNCTOR(recip)
+//UNARY_OPS_FUNCTOR(rsqrt)
+UNARY_OPS_FUNCTOR(sin,   T,            1);
+UNARY_OPS_FUNCTOR(sin,   complex<T>,  12);
+//UNARY_OPS_FUNCTOR(sinh)
+UNARY_OPS_FUNCTOR(sq,    T,            1);
+UNARY_OPS_FUNCTOR(sq,    complex<T>,   5);
+UNARY_OPS_FUNCTOR(sqrt,  T,            1);
+UNARY_OPS_FUNCTOR(sqrt,  complex<T>,  10);
+UNARY_OPS_FUNCTOR(tan,   T,            1);
+UNARY_OPS_FUNCTOR(tan,   complex<T>,  14);
+//UNARY_OPS_FUNCTOR(tanh)
+
+#undef UNARY_OPS_FUNCTOR
+
+
+#define BINARY_OPS(OP, TYPE1, TYPE2, VALUE)		\
+template <typename T1,					\
+          typename T2>					\
+struct Binary_op_count<OP, TYPE1, TYPE2>		\
+{							\
+  static unsigned const value = VALUE;			\
 }; 
 
 BINARY_OPS(op::Add,  T1,          T2,          1)
@@ -77,17 +125,113 @@
 BINARY_OPS(op::Add,  complex<T1>, T2,          1)
 BINARY_OPS(op::Add,  complex<T1>, complex<T2>, 2)
 
+BINARY_OPS(op::Sub,  T1,          T2,          1)
+BINARY_OPS(op::Sub,  T1,          complex<T2>, 1)
+BINARY_OPS(op::Sub,  complex<T1>, T2,          1)
+BINARY_OPS(op::Sub,  complex<T1>, complex<T2>, 2)
+
 BINARY_OPS(op::Mult, T1,          T2,          1)
 BINARY_OPS(op::Mult, T1,          complex<T2>, 2)
 BINARY_OPS(op::Mult, complex<T1>, T2,          2)
 BINARY_OPS(op::Mult, complex<T1>, complex<T2>, 6)
 
+BINARY_OPS(op::Div, T1,          T2,          1)
+BINARY_OPS(op::Div, T1,          complex<T2>, 2)
+BINARY_OPS(op::Div, complex<T1>, T2,          2)
+BINARY_OPS(op::Div, complex<T1>, complex<T2>, 6)
+
+#define BINARY_OPS_FUNCTOR(OP, TYPE1, TYPE2, VALUE)	\
+        BINARY_OPS(OP##_functor, TYPE1, TYPE2, VALUE)
+
+//BINARY_OPS_FUNCTOR(add)
+//BINARY_OPS_FUNCTOR(atan2)
+//BINARY_OPS_FUNCTOR(band)
+//BINARY_OPS_FUNCTOR(bor)
+//BINARY_OPS_FUNCTOR(bxor)
+//BINARY_OPS_FUNCTOR(div)
+//BINARY_OPS_FUNCTOR(eq)
+//BINARY_OPS_FUNCTOR(fmod)
+//BINARY_OPS_FUNCTOR(ge)
+//BINARY_OPS_FUNCTOR(gt)
+//BINARY_OPS_FUNCTOR(hypot)
+//BINARY_OPS_FUNCTOR(jmul)
+//BINARY_OPS_FUNCTOR(land)
+//BINARY_OPS_FUNCTOR(le)
+//BINARY_OPS_FUNCTOR(lt)
+//BINARY_OPS_FUNCTOR(lor)
+//BINARY_OPS_FUNCTOR(lxor)
+//BINARY_OPS_FUNCTOR(mul)
+//BINARY_OPS_FUNCTOR(max)
+//BINARY_OPS_FUNCTOR(maxmg)
+//BINARY_OPS_FUNCTOR(maxmgsq)
+//BINARY_OPS_FUNCTOR(min)
+//BINARY_OPS_FUNCTOR(minmg)
+//BINARY_OPS_FUNCTOR(minmgsq)
+//BINARY_OPS_FUNCTOR(ne)
+//BINARY_OPS_FUNCTOR(pow)
+//BINARY_OPS_FUNCTOR(sub)
+
+
+#undef BINARY_OPS_FUNCTOR
 #undef BINARY_OPS
 
-// FIXME: Ops count for ternary ops
 
 
+#define TERNARY_OPS(OP, TYPE1, TYPE2, TYPE3, VALUE)		\
+template <typename T1,						\
+          typename T2,						\
+          typename T3>						\
+struct Ternary_op_count<OP, TYPE1, TYPE2, TYPE3>		\
+{								\
+  static unsigned const value = VALUE;				\
+}; 
 
+#define TERNARY_OPS_FUNCTOR(OP, TYPE1, TYPE2, TYPE3, VALUE)	\
+        TERNARY_OPS(OP##_functor, TYPE1, TYPE2, TYPE3, VALUE)
+
+#define C1   complex<T1>
+#define C2   complex<T2>
+#define C3   complex<T3>
+
+// The cost is computed by adding the costs for pure real, mixed real-complex and 
+// pure complex adds and multiples for the given equation:
+
+//  (t1 + t2) * t3
+//                                   <  adds  >    <   muls   >
+//                                   R   M   C     R   M     C
+TERNARY_OPS_FUNCTOR(am, T1, T2, T3,  1 + 0 + 0*2 + 1 + 0*2 + 0*6)
+TERNARY_OPS_FUNCTOR(am, T1, T2, C3,  1 + 0 + 0*2 + 0 + 0*2 + 0*6)
+TERNARY_OPS_FUNCTOR(am, T1, C2, T3,  0 + 1 + 0*2 + 0 + 1*2 + 0*6)
+TERNARY_OPS_FUNCTOR(am, T1, C2, C3,  0 + 1 + 0*2 + 0 + 0*2 + 1*6)
+TERNARY_OPS_FUNCTOR(am, C1, T2, T3,  0 + 1 + 0*2 + 0 + 1*2 + 0*6)
+TERNARY_OPS_FUNCTOR(am, C1, T2, C3,  0 + 1 + 0*2 + 0 + 0*2 + 1*6)
+TERNARY_OPS_FUNCTOR(am, C1, C2, T3,  0 + 0 + 1*2 + 0 + 1*2 + 0*6)
+TERNARY_OPS_FUNCTOR(am, C1, C2, C3,  0 + 0 + 1*2 + 0 + 0*2 + 1*6)
+
+//  t1 * t2 + (T1(1) - t1) * t3
+//                                        <  adds  >    <   muls   >
+//                                        R   M   C     R   M     C
+TERNARY_OPS_FUNCTOR(expoavg, T1, T2, T3,  2 + 0 + 0*2 + 2 + 0*2 + 0*6)
+TERNARY_OPS_FUNCTOR(expoavg, T1, T2, C3,  1 + 1 + 0*2 + 1 + 1*2 + 0*6)
+TERNARY_OPS_FUNCTOR(expoavg, T1, C2, T3,  1 + 1 + 0*2 + 1 + 1*2 + 0*6)
+TERNARY_OPS_FUNCTOR(expoavg, T1, C2, C3,  1 + 0 + 1*2 + 0 + 2*2 + 0*6)
+TERNARY_OPS_FUNCTOR(expoavg, C1, T2, T3,  0 + 0 + 2*2 + 0 + 2*2 + 0*6)
+TERNARY_OPS_FUNCTOR(expoavg, C1, T2, C3,  0 + 0 + 2*2 + 0 + 1*2 + 1*6)
+TERNARY_OPS_FUNCTOR(expoavg, C1, C2, T3,  0 + 0 + 2*2 + 0 + 1*2 + 1*6)
+TERNARY_OPS_FUNCTOR(expoavg, C1, C2, C3,  0 + 0 + 2*2 + 0 + 0*2 + 2*6)
+
+//TERNARY_OPS_FUNCTOR(ma)
+//TERNARY_OPS_FUNCTOR(msb)
+//TERNARY_OPS_FUNCTOR(sbm)
+//TERNARY_OPS_FUNCTOR(ite)
+
+#undef C3
+#undef C2
+#undef C1
+#undef TERNARY_OPS_FUNCTOR
+#undef TERNARY_OPS
+
+
 // Reduction to count the number operations per point of an expression.
 
 struct Reduce_expr_ops_per_point
Index: src/vsip/impl/expr_serial_evaluator.hpp
===================================================================
--- src/vsip/impl/expr_serial_evaluator.hpp	(revision 146504)
+++ src/vsip/impl/expr_serial_evaluator.hpp	(working copy)
@@ -19,6 +19,9 @@
 #include <vsip/impl/fast-transpose.hpp>
 #include <vsip/impl/adjust-layout.hpp>
 #include <vsip/impl/coverage.hpp>
+#include <vsip/impl/profile.hpp>
+#include <vsip/impl/expr_ops_per_point.hpp>
+#include <vsip/impl/expr_op_names.hpp>
 
 
 
@@ -67,6 +70,12 @@
   {
     VSIP_IMPL_COVER_BLK("SEE_1", SrcBlock);
     length_type const size = dst.size(1, 0);
+
+    std::ostringstream  tag;
+    tag << "Expr[LF] 1D " << impl::Expr_op_name<SrcBlock>::tag() << " " << size;
+    impl::profile::Scope_event event( tag.str(), 
+      impl::Expr_ops_per_point<SrcBlock>::value * size );
+
     for (index_type i=0; i<size; ++i)
       dst.put(i, src.get(i));
   }
@@ -98,6 +107,12 @@
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
     VSIP_IMPL_COVER_BLK("SEE_COPY", SrcBlock);
+    length_type size    = dst.size(1, 0);
+
+    std::ostringstream  tag;
+    tag << "Expr[Copy] 1D " << size;
+    impl::profile::Scope_event event( tag.str(), size );
+
     Ext_data<DstBlock, dst_lp> ext_dst(dst, impl::SYNC_OUT);
     Ext_data<SrcBlock, src_lp> ext_src(src, impl::SYNC_IN);
 
@@ -106,7 +121,6 @@
 
     stride_type stride1 = ext_dst.stride(0);
     stride_type stride2 = ext_src.stride(0);
-    length_type size    = ext_dst.size(0);
     assert(size <= ext_src.size(0));
 
     if (Type_equal<typename DstBlock::value_type,
@@ -165,6 +179,13 @@
 
   static void exec(DstBlock& dst, SrcBlock const& src, row2_type, row2_type)
   {
+    length_type size_0 = dst.size(2, 0);
+    length_type size_1 = dst.size(2, 1);
+
+    std::ostringstream  tag;
+    tag << "Expr[Trans] 2D row row " << size_0 << "x" << size_1;
+    impl::profile::Scope_event event( tag.str(), size_0 * size_1 );
+
     vsip::impl::Ext_data<DstBlock> d_ext(dst, vsip::impl::SYNC_OUT);
     vsip::impl::Ext_data<SrcBlock> s_ext(src, vsip::impl::SYNC_IN);
 
@@ -176,9 +197,6 @@
     stride_type s_stride_0 = s_ext.stride(0);
     stride_type s_stride_1 = s_ext.stride(1);
 
-    length_type size_0     = d_ext.size(0);
-    length_type size_1     = d_ext.size(1);
-
     assert(size_0 <= s_ext.size(0));
     assert(size_1 <= s_ext.size(1));
 
@@ -218,6 +236,13 @@
 
   static void exec(DstBlock& dst, SrcBlock const& src, col2_type, col2_type)
   {
+    length_type size_0 = dst.size(2, 0);
+    length_type size_1 = dst.size(2, 1);
+
+    std::ostringstream  tag;
+    tag << "Expr[Trans] 2D col col " << size_0 << "x" << size_1;
+    impl::profile::Scope_event event( tag.str(), size_0 * size_1 );
+
     vsip::impl::Ext_data<DstBlock> d_ext(dst, vsip::impl::SYNC_OUT);
     vsip::impl::Ext_data<SrcBlock> s_ext(src, vsip::impl::SYNC_IN);
 
@@ -229,9 +254,6 @@
     stride_type s_stride_0 = s_ext.stride(0);
     stride_type s_stride_1 = s_ext.stride(1);
 
-    length_type size_0     = d_ext.size(0);
-    length_type size_1     = d_ext.size(1);
-
     assert(size_0 <= s_ext.size(0));
     assert(size_1 <= s_ext.size(1));
 
@@ -271,20 +293,27 @@
 
   static void exec(DstBlock& dst, SrcBlock const& src, col2_type, row2_type)
   {
+    length_type size_0 = dst.size(2, 0);
+    length_type size_1 = dst.size(2, 1);
+
+    std::ostringstream  tag;
+    tag << "Expr[Trans] 2D col row " << size_0 << "x" << size_1;
+    impl::profile::Scope_event event( tag.str(), size_0 * size_1 );
+
     vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
     vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
 
     if (dst_ext.stride(0) == 1 && src_ext.stride(1) == 1)
     {
       transpose_unit(dst_ext.data(), src_ext.data(),
-		     dst.size(2, 0), dst.size(2, 1), // rows, cols
+                     size_0, size_1,                 // rows, cols
 		     dst_ext.stride(1),		     // dst_col_stride
 		     src_ext.stride(0));	     // src_row_stride
     }
     else
     {
       transpose(dst_ext.data(), src_ext.data(),
-		dst.size(2, 0), dst.size(2, 1),		// rows, cols
+                size_0, size_1,                         // rows, cols
 		dst_ext.stride(0), dst_ext.stride(1),	// dst strides
 		src_ext.stride(0), src_ext.stride(1));	// srd strides
     }
@@ -292,20 +321,27 @@
 
   static void exec(DstBlock& dst, SrcBlock const& src, row2_type, col2_type)
   {
+    length_type size_0 = dst.size(2, 0);
+    length_type size_1 = dst.size(2, 1);
+
+    std::ostringstream  tag;
+    tag << "Expr[Trans] 2D row col " << size_0 << "x" << size_1;
+    impl::profile::Scope_event event( tag.str(), size_0 * size_1 );
+
     vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
     vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
 
     if (dst_ext.stride(1) == 1 && src_ext.stride(0) == 1)
     {
       transpose_unit(dst_ext.data(), src_ext.data(),
-		     dst.size(2, 1), dst.size(2, 0), // rows, cols
+		     size_1, size_0,      // rows, cols
 		     dst_ext.stride(0),	  // dst_col_stride
-		     src_ext.stride(1));	  // src_row_stride
+		     src_ext.stride(1));  // src_row_stride
     }
     else
     {
       transpose(dst_ext.data(), src_ext.data(),
-		dst.size(2, 1), dst.size(2, 0), // rows, cols
+                size_1, size_0,                         // rows, cols
 		dst_ext.stride(1), dst_ext.stride(0),	// dst strides
 		src_ext.stride(1), src_ext.stride(0));	// srd strides
     }
@@ -333,6 +369,13 @@
   {
     length_type const rows = dst.size(2, 0);
     length_type const cols = dst.size(2, 1);
+
+    std::ostringstream  tag;
+    tag << "Expr[LF] 2D row " << impl::Expr_op_name<SrcBlock>::tag() 
+        << " " << rows << "x" << cols;
+    impl::profile::Scope_event event( tag.str(), 
+      impl::Expr_ops_per_point<SrcBlock>::value * rows * cols );
+
     for (index_type i=0; i<rows; ++i)
       for (index_type j=0; j<cols; ++j)
 	dst.put(i, j, src.get(i, j));
@@ -342,6 +385,13 @@
   {
     length_type const rows = dst.size(2, 0);
     length_type const cols = dst.size(2, 1);
+
+    std::ostringstream  tag;
+    tag << "Expr[LF] 2D col " << impl::Expr_op_name<SrcBlock>::tag() 
+        << " " << rows << "x" << cols;
+    impl::profile::Scope_event event( tag.str(),
+      impl::Expr_ops_per_point<SrcBlock>::value * rows * cols );
+
     for (index_type j=0; j<cols; ++j)
       for (index_type i=0; i<rows; ++i)
 	dst.put(i, j, src.get(i, j));
@@ -371,6 +421,12 @@
     length_type const size1 = dst.size(3, 1);
     length_type const size2 = dst.size(3, 2);
 
+    std::ostringstream  tag;
+    tag << "Expr[LF] 3D 0-1-2 " << impl::Expr_op_name<SrcBlock>::tag() 
+        << " " << size0 << "x" << size1 << "x" << size2;
+    impl::profile::Scope_event event( tag.str(),
+      impl::Expr_ops_per_point<SrcBlock>::value * size0 * size1 * size2 );
+
     for (index_type i=0; i<size0; ++i)
     for (index_type j=0; j<size1; ++j)
     for (index_type k=0; k<size2; ++k)
@@ -382,6 +438,12 @@
     length_type const size1 = dst.size(3, 1);
     length_type const size2 = dst.size(3, 2);
 
+    std::ostringstream  tag;
+    tag << "Expr[LF] 3D 0-2-1 " << impl::Expr_op_name<SrcBlock>::tag() 
+        << " " << size0 << "x" << size1 << "x" << size2;
+    impl::profile::Scope_event event( tag.str(),
+      impl::Expr_ops_per_point<SrcBlock>::value * size0 * size1 * size2 );
+
     for (index_type i=0; i<size0; ++i)
     for (index_type k=0; k<size2; ++k)
     for (index_type j=0; j<size1; ++j)
@@ -393,6 +455,12 @@
     length_type const size1 = dst.size(3, 1);
     length_type const size2 = dst.size(3, 2);
 
+    std::ostringstream  tag;
+    tag << "Expr[LF] 3D 1-0-2 " << impl::Expr_op_name<SrcBlock>::tag() 
+        << " " << size0 << "x" << size1 << "x" << size2;
+    impl::profile::Scope_event event( tag.str(),
+      impl::Expr_ops_per_point<SrcBlock>::value * size0 * size1 * size2 );
+
     for (index_type j=0; j<size1; ++j)
     for (index_type i=0; i<size0; ++i)
     for (index_type k=0; k<size2; ++k)
@@ -404,6 +472,12 @@
     length_type const size1 = dst.size(3, 1);
     length_type const size2 = dst.size(3, 2);
 
+    std::ostringstream  tag;
+    tag << "Expr[LF] 3D 1-2-0 " << impl::Expr_op_name<SrcBlock>::tag() 
+        << " " << size0 << "x" << size1 << "x" << size2;
+    impl::profile::Scope_event event( tag.str(),
+      impl::Expr_ops_per_point<SrcBlock>::value * size0 * size1 * size2 );
+
     for (index_type j=0; j<size1; ++j)
     for (index_type k=0; k<size2; ++k)
     for (index_type i=0; i<size0; ++i)
@@ -415,6 +489,12 @@
     length_type const size1 = dst.size(3, 1);
     length_type const size2 = dst.size(3, 2);
 
+    std::ostringstream  tag;
+    tag << "Expr[LF] 3D 2-0-1 " << impl::Expr_op_name<SrcBlock>::tag() 
+        << " " << size0 << "x" << size1 << "x" << size2;
+    impl::profile::Scope_event event( tag.str(),
+      impl::Expr_ops_per_point<SrcBlock>::value * size0 * size1 * size2 );
+
     for (index_type k=0; k<size2; ++k)
     for (index_type i=0; i<size0; ++i)
     for (index_type j=0; j<size1; ++j)
@@ -426,6 +506,12 @@
     length_type const size1 = dst.size(3, 1);
     length_type const size2 = dst.size(3, 2);
 
+    std::ostringstream  tag;
+    tag << "Expr[LF] 3D 2-1-0 " << impl::Expr_op_name<SrcBlock>::tag() 
+        << " " << size0 << "x" << size1 << "x" << size2;
+    impl::profile::Scope_event event( tag.str(),
+      impl::Expr_ops_per_point<SrcBlock>::value * size0 * size1 * size2 );
+
     for (index_type k=0; k<size2; ++k)
     for (index_type j=0; j<size1; ++j)
     for (index_type i=0; i<size0; ++i)
Index: tests/expr_ops_per_point.cpp
===================================================================
--- tests/expr_ops_per_point.cpp	(revision 146504)
+++ tests/expr_ops_per_point.cpp	(working copy)
@@ -51,6 +51,16 @@
   test_expr(1, vec1 * vec2);
   test_expr(2, vec1 * vec3);
   test_expr(6, vec3 * vec4);
+
+  test_expr(1,  sin(vec1));
+  test_expr(12, sin(vec3));
+  test_expr(1,  tan(vec1));
+  test_expr(14, tan(vec3));
+
+  test_expr(1,  sq(vec1));
+  test_expr(5,  sq(vec3));
+  test_expr(1,  sqrt(vec1));
+  test_expr(10, sqrt(vec3));
 }
 
 
Index: tests/expr_op_names.cpp
===================================================================
--- tests/expr_op_names.cpp	(revision 0)
+++ tests/expr_op_names.cpp	(revision 0)
@@ -0,0 +1,90 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    tests/expr_op_names.cpp
+    @author  Don McCoy
+    @date    2006-08-07
+    @brief   VSIPL++ Library: Test Expr_op_name expression template
+                              reduction.
+
+    This functionality is used by the profiler to generate tags used for
+    logging events, such as expressions being evaluated.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <string>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/impl/expr_op_names.hpp>
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
+// Test that the operation name (or 'tag') generated for various 
+// expressions is correct.
+
+template <typename ViewT>
+void
+test_expr(char const* tag, ViewT /*expr*/)
+{
+  typedef typename ViewT::block_type block_type;
+
+//  if (tag != impl::Expr_op_name<block_type>::tag())
+    cout << tag << " ?= " << impl::Expr_op_name<block_type>::tag() << endl;
+  test_assert(tag == impl::Expr_op_name<block_type>::tag());
+}
+
+
+void
+test_expr_eval()
+{
+  Vector<float> vec1(5);
+  Vector<float> vec2(5);
+  Vector<complex<float> > vec3(5);
+  Vector<complex<float> > vec4(5);
+
+  // unary
+  test_expr("uS", sin(vec1));
+  test_expr("uC", exp(vec3));
+
+  // binary
+  test_expr("bSS", max(vec1, vec2));
+  test_expr("+SS", vec1 + vec2);
+  test_expr("*SS", vec1 * vec2);
+  test_expr("*SC", vec1 * vec3);
+  test_expr("*CC", vec3 * vec4);
+  test_expr("+SS-SC", (vec1 + vec2) - vec3);
+  test_expr("-SC+SC", vec1 + (vec2 - vec3));
+  test_expr("*SS/CS+SC", vec1 * 3.f + vec3 / 4.f);
+
+  // ternary
+  test_expr("tSSC", expoavg(vec1, vec2, vec3));
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
+  test_expr_eval();
+
+  return 0;
+}
Index: tests/GNUmakefile.inc.in
===================================================================
--- tests/GNUmakefile.inc.in	(revision 146504)
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
