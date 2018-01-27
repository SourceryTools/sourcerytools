Index: ChangeLog
===================================================================
--- ChangeLog	(revision 152479)
+++ ChangeLog	(working copy)
@@ -1,5 +1,42 @@
 2006-10-26  Jules Bergmann  <jules@codesourcery.com>
 
+	Add dispatch to SAL vector comparisons (lv{eq,ne,gt,ge,lt,le}x).
+	* src/vsip/core/setup_assign.hpp: Remove reference to
+	  Tag_serial_assign.
+	* src/vsip/core/dispatch_assign.hpp (assign): Pass const
+	  modifier of SrcBlock thru to Dispatch_assign.
+	* src/vsip/opt/sal/eval_vcmp..hpp: New file, evaluators for
+	  SAL vector comparisons.
+	* src/vsip/opt/sal/bindings.hpp: Include eval_vcmp.hpp
+	* src/vsip/opt/sal/is_op_supported.hpp: New file, Is_op_supported
+	  traits, move from ...
+	* src/vsip/opt/sal/eval_elementwise.hpp: ... here.
+	* src/vsip/opt/sal/elementwise.hpp: Add bindings for SAL
+	  vector comparisons.
+	* tests/threshold.cpp: Add coverage for vector comparisons.
+
+	Extend load_view and save_view to work w/distributed views.
+	* src/vsip_csl/load_view.hpp: Extend load_view to work w/distributed
+	  views.
+	* src/vsip_csl/save_view.hpp: Extend save_view to work w/distributed
+	  views.
+	* src/vsip/opt/extdata.hpp (is_ext_dense): New function, check
+	  if Ext_data refers to a dense space.
+	* src/vsip/core/adjust_layout.hpp (Adjust_layout_complex): New
+	  class to adjust complex format of layout type.
+	* tests/test_common.hpp (setup, check): Overload for tensors.
+	* tests/vsip_csl/load_view.cpp: New file, unit tests for load_view
+	  and save_view.
+	
+	* src/vsip/map.hpp: Add assertion to prevent a higher-dimensional
+	  map from being applied to a view.
+
+	* tests/extdata-fft.cpp: Update path to fast_block include.
+	* tests/elementwise.cpp: Likewise.
+	* tests/fast-block.cpp: Likewise.
+
+2006-10-26  Jules Bergmann  <jules@codesourcery.com>
+
 	* tests/threshold.hpp: New file, unit tests for threshold
 	  expressions that are dispatched to SAL.
 	
Index: src/vsip/core/setup_assign.hpp
===================================================================
--- src/vsip/core/setup_assign.hpp	(revision 152478)
+++ src/vsip/core/setup_assign.hpp	(working copy)
@@ -299,14 +299,8 @@
 
     typedef typename
       impl::Dispatch_assign_helper<dim, Block1, Block2, true>::type
-      raw_dispatch_type;
+      dispatch_type;
 
-    typedef typename
-      ITE_Type<Type_equal<raw_dispatch_type, impl::Tag_serial_assign>::value,
-               As_type<impl::Tag_serial_expr>,
-               As_type<raw_dispatch_type> >
-      ::type dispatch_type;
-
     create_holder<dim>(dst, src, dispatch_type());
   }
 
Index: src/vsip/core/adjust_layout.hpp
===================================================================
--- src/vsip/core/adjust_layout.hpp	(revision 152478)
+++ src/vsip/core/adjust_layout.hpp	(working copy)
@@ -162,6 +162,18 @@
 
 
 
+template <typename NewComplexType,
+	  typename LP>
+struct Adjust_layout_complex
+{
+  typedef typename LP::order_type     order_type;
+  typedef typename LP::pack_type      pack_type;
+
+  typedef Layout<LP::dim, order_type, pack_type, NewComplexType> type;
+};
+
+
+
 // Determine if an given layout policy is compatible with a required
 // layout policy.
 
Index: src/vsip/core/dispatch_assign.hpp
===================================================================
--- src/vsip/core/dispatch_assign.hpp	(revision 152478)
+++ src/vsip/core/dispatch_assign.hpp	(working copy)
@@ -302,7 +302,7 @@
 
 template <dimension_type D, typename DstBlock, typename SrcBlock>
 inline void 
-assign(DstBlock & dst, SrcBlock const& src)
+assign(DstBlock& dst, SrcBlock& src)
 {
   Dispatch_assign<D, DstBlock, SrcBlock>::exec(dst, src);
 }
Index: src/vsip/opt/sal/bindings.hpp
===================================================================
--- src/vsip/opt/sal/bindings.hpp	(revision 152478)
+++ src/vsip/opt/sal/bindings.hpp	(working copy)
@@ -23,6 +23,7 @@
 #include <vsip/opt/sal/elementwise.hpp>
 #include <vsip/opt/sal/eval_elementwise.hpp>
 #include <vsip/opt/sal/eval_threshold.hpp>
+#include <vsip/opt/sal/eval_vcmp.hpp>
 
 /***********************************************************************
   Declarations
Index: src/vsip/opt/sal/eval_vcmp.hpp
===================================================================
--- src/vsip/opt/sal/eval_vcmp.hpp	(revision 0)
+++ src/vsip/opt/sal/eval_vcmp.hpp	(revision 0)
@@ -0,0 +1,129 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/sal/eval_vcmp.hpp
+    @author  Jules Bergmann
+    @date    2006-10-26
+    @brief   VSIPL++ Library: Dispatch for Mercury SAL -- vector comparisons.
+*/
+
+#ifndef VSIP_OPT_SAL_EVAL_VCMP_HPP
+#define VSIP_OPT_SAL_EVAL_VCMP_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/expr/serial_evaluator.hpp>
+#include <vsip/core/expr/scalar_block.hpp>
+#include <vsip/core/expr/unary_block.hpp>
+#include <vsip/core/expr/binary_block.hpp>
+#include <vsip/core/expr/ternary_block.hpp>
+#include <vsip/core/expr/operations.hpp>
+#include <vsip/core/fns_elementwise.hpp>
+#include <vsip/opt/extdata.hpp>
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/opt/sal/eval_util.hpp>
+#include <vsip/core/adjust_layout.hpp>
+#include <vsip/opt/sal/is_op_supported.hpp>
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
+/***********************************************************************
+  Threshold Expressions
+***********************************************************************/
+
+// Optimize threshold expression: ite(A > B, VAL1, VAL0)
+#define VSIP_IMPL_SAL_VCMP_EXPR(FUNCTOR, OPTOKEN, FUN, VAL1, VAL0)	\
+template <typename DstBlock,						\
+	  typename T,							\
+	  typename Block2,						\
+	  typename Block1>						\
+struct Serial_expr_evaluator<						\
+         1, DstBlock, 							\
+									\
+         Ternary_expr_block<1, ite_functor,				\
+           Binary_expr_block<1u, FUNCTOR,				\
+			     Block1, T,					\
+			     Block2, T> const, bool,			\
+	   Scalar_block<1, T>, T,					\
+	   Scalar_block<1, T>, T> const,				\
+									\
+         Mercury_sal_tag>						\
+{									\
+  static char const* name() { return "Expr_SAL_vsmp-" # FUNCTOR; }	\
+									\
+  typedef Ternary_expr_block<1, ite_functor,				\
+            Binary_expr_block<1u, FUNCTOR,				\
+			      Block1, T,				\
+			      Block2, T> const, bool,			\
+	   Scalar_block<1, T>, T,					\
+	   Scalar_block<1, T>, T>					\
+	SrcBlock;							\
+									\
+  typedef typename DstBlock::value_type dst_type;			\
+									\
+  typedef typename sal::Effective_value_type<DstBlock>::type  eff_d_t;	\
+  typedef typename sal::Effective_value_type<Block1, T>::type eff_1_t;	\
+  typedef typename sal::Effective_value_type<Block2, T>::type eff_2_t;	\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block1>::layout_type>::type		\
+    block1_lp;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<Block2>::layout_type>::type		\
+    block2_lp;								\
+  									\
+  static bool const ct_valid =						\
+     sal::Is_op2_supported<OPTOKEN, eff_1_t, eff_2_t, eff_d_t>::value &&\
+     /* check that direct access is supported */			\
+     Ext_data_cost<DstBlock>::value == 0 &&				\
+     Ext_data_cost<Block1>::value == 0 &&				\
+     Ext_data_cost<Block2>::value == 0;					\
+									\
+  static bool rt_valid(DstBlock&, SrcBlock const& src)			\
+  {									\
+    return src.second().value() == T(VAL1) &&				\
+            src.third().value() == T(VAL0);				\
+  }									\
+									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    typedef Scalar_block<1, T> sb_type;					\
+									\
+    sal::Ext_wrapper<DstBlock, dst_lp>  ext_dst(dst,        SYNC_OUT);	\
+    sal::Ext_wrapper<Block1, block1_lp> ext_A(src.first().left(), SYNC_IN);\
+    sal::Ext_wrapper<Block2, block2_lp> ext_B(src.first().right(), SYNC_IN);\
+									\
+    FUN(								\
+      typename sal::Ext_wrapper<Block1, block1_lp>::sal_type(ext_A),	\
+      typename sal::Ext_wrapper<Block2, block2_lp>::sal_type(ext_B),	\
+      typename sal::Ext_wrapper<DstBlock, dst_lp>::sal_type(ext_dst),	\
+      dst.size());							\
+  }									\
+};
+
+VSIP_IMPL_SAL_VCMP_EXPR(eq_functor, sal::veq_token, sal::lveq, 1, 0)
+VSIP_IMPL_SAL_VCMP_EXPR(ne_functor, sal::vne_token, sal::lvne, 1, 0)
+VSIP_IMPL_SAL_VCMP_EXPR(gt_functor, sal::vgt_token, sal::lvgt, 1, 0)
+VSIP_IMPL_SAL_VCMP_EXPR(ge_functor, sal::vge_token, sal::lvge, 1, 0)
+VSIP_IMPL_SAL_VCMP_EXPR(lt_functor, sal::vlt_token, sal::lvlt, 1, 0)
+VSIP_IMPL_SAL_VCMP_EXPR(le_functor, sal::vle_token, sal::lvle, 1, 0)
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_SAL_EVAL_VCMP_HPP
Index: src/vsip/opt/sal/is_op_supported.hpp
===================================================================
--- src/vsip/opt/sal/is_op_supported.hpp	(revision 0)
+++ src/vsip/opt/sal/is_op_supported.hpp	(revision 0)
@@ -0,0 +1,449 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/sal/is_op_supported.hpp
+    @author  Jules Bergmann
+    @date    2006-10-26
+    @brief   VSIPL++ Library: Mercury SAL ops supported for dispatch.
+*/
+
+#ifndef VSIP_OPT_SAL_IS_OP_SUPPORTED_HPP
+#define VSIP_OPT_SAL_IS_OP_SUPPORTED_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/fns_elementwise.hpp>
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
+namespace sal
+{
+
+/// Traits class to help determine when SAL supports a given
+/// binary operation.
+///
+/// Requirements:
+///   OPERATOR is the Operator template class for the operation
+///      (from the vsip::impl::op namespace).
+///   LTYPE is the type of the left operand.
+///   RTYPE is the type of the right operand.
+///   RTYPE is the type of the result.
+///
+/// For LTYPE, RTYPE, and DSTTYPE, vector operands should be represented
+/// by a pointer type (for example: float*, complex<float>*, and
+/// std::pair<float*, float*>).  scalar operand should be represented
+/// by a value type, such as float, complex<float>, std::pair<float, float>.
+
+template <template <typename> class Operator,
+	  typename                  SrcType,
+	  typename                  DstType>
+struct Is_op1_supported
+{
+  static bool const value = false;
+};
+
+template <template <typename, typename> class Operator,
+	  typename                            LType,
+	  typename                            RType,
+	  typename                            DstType>
+struct Is_op2_supported
+{
+  static bool const value = false;
+};
+
+template <template <typename, typename, typename> class Operator,
+	  typename                            Type1,
+	  typename                            Type2,
+	  typename                            Type3,
+	  typename                            DstType>
+struct Is_op3_supported
+{
+  static bool const value = false;
+};
+
+
+// Tokens for ops not mapping directly to functors.
+
+template <typename> struct copy_token;
+
+template <typename, typename> struct veq_token;
+template <typename, typename> struct vne_token;
+template <typename, typename> struct vgt_token;
+template <typename, typename> struct vge_token;
+template <typename, typename> struct vlt_token;
+template <typename, typename> struct vle_token;
+
+template <typename, typename, typename> struct cma_token;
+
+
+#define VSIP_IMPL_OP1SUP(Op, T1, DT)					\
+  template <> struct Is_op1_supported<Op, T1, DT >			\
+  { static bool const value = true; }
+
+#define VSIP_IMPL_OP2SUP(Op, LT, RT, DT)				\
+  template <> struct Is_op2_supported<Op, LT, RT, DT >			\
+  { static bool const value = true; }
+
+#define VSIP_IMPL_OP3SUP(Op, T1, T2, T3, DT)				\
+  template <> struct Is_op3_supported<Op, T1, T2, T3, DT >		\
+  { static bool const value = true; }
+
+typedef std::pair<float*, float*>   split_float;
+typedef std::pair<double*, double*> split_double;
+
+
+/***********************************************************************
+  Unary operators and functions provided by SAL
+***********************************************************************/
+
+VSIP_IMPL_OP1SUP(magsq_functor, complex<float>*,  float*);
+VSIP_IMPL_OP1SUP(magsq_functor, complex<double>*, double*);
+VSIP_IMPL_OP1SUP(magsq_functor, split_float,      float*);
+VSIP_IMPL_OP1SUP(magsq_functor, split_double,     double*);
+
+VSIP_IMPL_OP1SUP(op::Minus,     int*,             int*);
+VSIP_IMPL_OP1SUP(op::Minus,     float*,           float*);
+VSIP_IMPL_OP1SUP(op::Minus,     double*,          double*);
+VSIP_IMPL_OP1SUP(op::Minus,     complex<float>*,  complex<float>*);
+VSIP_IMPL_OP1SUP(op::Minus,     complex<double>*, complex<double>*);
+VSIP_IMPL_OP1SUP(op::Minus,     split_float,      split_float);
+VSIP_IMPL_OP1SUP(op::Minus,     split_double,     split_double);
+
+VSIP_IMPL_OP1SUP(mag_functor,   int*,             int*);
+VSIP_IMPL_OP1SUP(mag_functor,   float*,           float*);
+VSIP_IMPL_OP1SUP(mag_functor,   double*,          double*);
+VSIP_IMPL_OP1SUP(mag_functor,   complex<float>*,  float*);
+VSIP_IMPL_OP1SUP(mag_functor,   split_float,      float*);
+
+VSIP_IMPL_OP1SUP(cos_functor,   float*,           float*);
+VSIP_IMPL_OP1SUP(cos_functor,   double*,          double*);
+
+VSIP_IMPL_OP1SUP(sin_functor,   float*,           float*);
+VSIP_IMPL_OP1SUP(sin_functor,   double*,          double*);
+
+VSIP_IMPL_OP1SUP(tan_functor,   float*,           float*);
+
+VSIP_IMPL_OP1SUP(atan_functor,  float*,           float*);
+VSIP_IMPL_OP1SUP(atan_functor,  double*,          double*);
+
+VSIP_IMPL_OP1SUP(log_functor,   float*,           float*);
+VSIP_IMPL_OP1SUP(log_functor,   double*,          double*);
+
+VSIP_IMPL_OP1SUP(log10_functor, float*,           float*);
+VSIP_IMPL_OP1SUP(log10_functor, double*,          double*);
+
+VSIP_IMPL_OP1SUP(exp_functor,   float*,           float*);
+VSIP_IMPL_OP1SUP(exp_functor,   double*,          double*);
+
+VSIP_IMPL_OP1SUP(exp10_functor, float*,           float*);
+VSIP_IMPL_OP1SUP(exp10_functor, double*,          double*);
+
+VSIP_IMPL_OP1SUP(sqrt_functor,  float*,           float*);
+VSIP_IMPL_OP1SUP(sqrt_functor,  double*,          double*);
+VSIP_IMPL_OP1SUP(sqrt_functor,  complex<float>*,  complex<float>*);
+VSIP_IMPL_OP1SUP(sqrt_functor,  split_float,      split_float);
+
+VSIP_IMPL_OP1SUP(rsqrt_functor, float*,           float*);
+VSIP_IMPL_OP1SUP(rsqrt_functor, double*,          double*);
+
+VSIP_IMPL_OP1SUP(sq_functor,    float*,           float*);
+VSIP_IMPL_OP1SUP(sq_functor,    double*,          double*);
+
+VSIP_IMPL_OP1SUP(recip_functor, float*,           float*);
+// no scalar double
+VSIP_IMPL_OP1SUP(recip_functor, complex<float>*,  complex<float>*);
+VSIP_IMPL_OP1SUP(recip_functor, split_float,      split_float);
+VSIP_IMPL_OP1SUP(recip_functor, complex<double>*, complex<double>*);
+VSIP_IMPL_OP1SUP(recip_functor, split_double,     split_double);
+
+VSIP_IMPL_OP1SUP(copy_token,    float*,           float*);
+VSIP_IMPL_OP1SUP(copy_token,    complex<float>*,  complex<float>*);
+VSIP_IMPL_OP1SUP(copy_token,    split_float,      split_float);
+VSIP_IMPL_OP1SUP(copy_token,    complex<double>*, complex<double>*);
+VSIP_IMPL_OP1SUP(copy_token,    split_double,     split_double);
+
+VSIP_IMPL_OP1SUP(copy_token,    split_float,      complex<float>*);
+VSIP_IMPL_OP1SUP(copy_token,    complex<float>*,  split_float);
+VSIP_IMPL_OP1SUP(copy_token,    split_double,     complex<double>*);
+VSIP_IMPL_OP1SUP(copy_token,    complex<double>*, split_double);
+
+
+
+/***********************************************************************
+  Binary operators and functions provided by SAL
+***********************************************************************/
+
+// straight-up vector add
+VSIP_IMPL_OP2SUP(op::Add, int*,             int*,            int*);
+VSIP_IMPL_OP2SUP(op::Add, float*,           float*,          float*);
+VSIP_IMPL_OP2SUP(op::Add, double*,          double*,         double*);
+VSIP_IMPL_OP2SUP(op::Add, complex<float>*,  complex<float>*, complex<float>*);
+VSIP_IMPL_OP2SUP(op::Add, complex<double>*, complex<double>*,complex<double>*);
+VSIP_IMPL_OP2SUP(op::Add, split_float,      split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Add, split_double,     split_double,    split_double);
+
+VSIP_IMPL_OP2SUP(op::Add, float*,           complex<float>*, complex<float>*);
+VSIP_IMPL_OP2SUP(op::Add, complex<float>*,  float*,          complex<float>*);
+VSIP_IMPL_OP2SUP(op::Add, float*,           split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Add, split_float,      float*,          split_float);
+// not crvadddx in SAL
+
+// scalar-vector vector add
+VSIP_IMPL_OP2SUP(op::Add, int,              int*,            int*);
+VSIP_IMPL_OP2SUP(op::Add, int*,             int,             int*);
+VSIP_IMPL_OP2SUP(op::Add, float,            float*,          float*);
+VSIP_IMPL_OP2SUP(op::Add, float*,           float,           float*);
+VSIP_IMPL_OP2SUP(op::Add, double,           double*,         double*);
+VSIP_IMPL_OP2SUP(op::Add, double*,          double,          double*);
+VSIP_IMPL_OP2SUP(op::Add, complex<float>,   complex<float>*, complex<float>*);
+VSIP_IMPL_OP2SUP(op::Add, complex<float>*,  complex<float>,  complex<float>*);
+VSIP_IMPL_OP2SUP(op::Add, complex<double>,  complex<double>*,complex<double>*);
+VSIP_IMPL_OP2SUP(op::Add, complex<double>*, complex<double>, complex<double>*);
+VSIP_IMPL_OP2SUP(op::Add, complex<float>,   split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Add, split_float,      complex<float>,  split_float);
+VSIP_IMPL_OP2SUP(op::Add, complex<double>,  split_double,    split_double);
+VSIP_IMPL_OP2SUP(op::Add, split_double,     complex<double>, split_double);
+
+VSIP_IMPL_OP2SUP(op::Add, float,            complex<float>*, complex<float>*);
+VSIP_IMPL_OP2SUP(op::Add, complex<float>*,  float,           complex<float>*);
+VSIP_IMPL_OP2SUP(op::Add, double,           complex<double>*,complex<double>*);
+VSIP_IMPL_OP2SUP(op::Add, complex<double>*, double,          complex<double>*);
+
+VSIP_IMPL_OP2SUP(op::Add, float,            split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Add, split_float,      float,           split_float);
+VSIP_IMPL_OP2SUP(op::Add, double,           split_double,    split_double);
+VSIP_IMPL_OP2SUP(op::Add, split_double,     double,          split_double);
+
+
+// straight-up vector sub
+VSIP_IMPL_OP2SUP(op::Sub, int*,             int*,            int*);
+VSIP_IMPL_OP2SUP(op::Sub, float*,           float*,          float*);
+VSIP_IMPL_OP2SUP(op::Sub, double*,          double*,         double*);
+VSIP_IMPL_OP2SUP(op::Sub, complex<float>*,  complex<float>*, complex<float>*);
+VSIP_IMPL_OP2SUP(op::Sub, complex<double>*, complex<double>*,complex<double>*);
+VSIP_IMPL_OP2SUP(op::Sub, split_float,      split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Sub, split_double,     split_double,    split_double);
+
+VSIP_IMPL_OP2SUP(op::Sub, complex<float>*,  float*,          complex<float>*);
+VSIP_IMPL_OP2SUP(op::Sub, split_float,      float*,          split_float);
+
+// scalar-vector vector sub
+VSIP_IMPL_OP2SUP(op::Sub, int*,             int,             int*);
+// not in sal   (op::Sub, float,            float*,          float*);
+VSIP_IMPL_OP2SUP(op::Sub, float*,           float,           float*);
+// not in sal   (op::Sub, double,           double*,         double*);
+VSIP_IMPL_OP2SUP(op::Sub, double*,          double,          double*);
+// not in sal   (op::Sub, complex<float>,   complex<float>*, complex<float>*);
+VSIP_IMPL_OP2SUP(op::Sub, complex<float>*,  complex<float>,  complex<float>*);
+// not in sal   (op::Sub, complex<double>,  complex<double>*,complex<double>*);
+VSIP_IMPL_OP2SUP(op::Sub, complex<double>*, complex<double>, complex<double>*);
+// not in sal   (op::Sub, complex<float>,   split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Sub, split_float,      complex<float>,  split_float);
+// not in sal   (op::Sub, complex<double>,  split_double,    split_double);
+VSIP_IMPL_OP2SUP(op::Sub, split_double,     complex<double>, split_double);
+
+VSIP_IMPL_OP2SUP(op::Sub, complex<float>*,  float,           complex<float>*);
+VSIP_IMPL_OP2SUP(op::Sub, complex<double>*, double,          complex<double>*);
+VSIP_IMPL_OP2SUP(op::Sub, split_float,      float,           split_float);
+VSIP_IMPL_OP2SUP(op::Sub, split_double,     double,          split_double);
+
+
+// straight-up vector multiply
+VSIP_IMPL_OP2SUP(op::Mult, int*,            int*,            int*);
+VSIP_IMPL_OP2SUP(op::Mult, float*,          float*,          float*);
+VSIP_IMPL_OP2SUP(op::Mult, double*,         double*,         double*);
+VSIP_IMPL_OP2SUP(op::Mult, complex<float>*, complex<float>*, complex<float>*);
+VSIP_IMPL_OP2SUP(op::Mult, complex<double>*,complex<double>*,complex<double>*);
+VSIP_IMPL_OP2SUP(op::Mult, split_float,     split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Mult, split_double,    split_double,    split_double);
+
+// real-complex vector multiply
+VSIP_IMPL_OP2SUP(op::Mult, complex<float>*, float*,          complex<float>*);
+VSIP_IMPL_OP2SUP(op::Mult, float*,          complex<float>*, complex<float>*);
+VSIP_IMPL_OP2SUP(op::Mult, split_float,     float*,          split_float);
+VSIP_IMPL_OP2SUP(op::Mult, float*,          split_float,     split_float);
+
+// scalar-vector vector multiply
+VSIP_IMPL_OP2SUP(op::Mult, int,             int*,            int*);
+VSIP_IMPL_OP2SUP(op::Mult, int*,            int,             int*);
+VSIP_IMPL_OP2SUP(op::Mult, float,           float*,          float*);
+VSIP_IMPL_OP2SUP(op::Mult, float*,          float,           float*);
+VSIP_IMPL_OP2SUP(op::Mult, double,          double*,         double*);
+VSIP_IMPL_OP2SUP(op::Mult, double*,         double,          double*);
+VSIP_IMPL_OP2SUP(op::Mult, complex<float>,  complex<float>*, complex<float>*);
+VSIP_IMPL_OP2SUP(op::Mult, complex<float>*, complex<float>,  complex<float>*);
+VSIP_IMPL_OP2SUP(op::Mult, complex<double>, complex<double>*,complex<double>*);
+VSIP_IMPL_OP2SUP(op::Mult, complex<double>*,complex<double>, complex<double>*);
+VSIP_IMPL_OP2SUP(op::Mult, complex<float>,  split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Mult, split_float,     complex<float>,  split_float);
+VSIP_IMPL_OP2SUP(op::Mult, complex<double>, split_double,    split_double);
+VSIP_IMPL_OP2SUP(op::Mult, split_double,    complex<double>, split_double);
+
+VSIP_IMPL_OP2SUP(op::Mult, float,           complex<float>*, complex<float>*);
+VSIP_IMPL_OP2SUP(op::Mult, complex<float>*, float,           complex<float>*);
+VSIP_IMPL_OP2SUP(op::Mult, double,          complex<double>*,complex<double>*);
+VSIP_IMPL_OP2SUP(op::Mult, complex<double>*,double,          complex<double>*);
+
+VSIP_IMPL_OP2SUP(op::Mult, float,           split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Mult, split_float,     float,           split_float);
+VSIP_IMPL_OP2SUP(op::Mult, double,          split_double,    split_double);
+VSIP_IMPL_OP2SUP(op::Mult, split_double,    double,          split_double);
+
+
+
+// straight-up vector division
+VSIP_IMPL_OP2SUP(op::Div, int*,             int*,            int*);
+VSIP_IMPL_OP2SUP(op::Div, float*,           float*,          float*);
+VSIP_IMPL_OP2SUP(op::Div, double*,          double*,         double*);
+VSIP_IMPL_OP2SUP(op::Div, complex<float>*,  complex<float>*, complex<float>*);
+VSIP_IMPL_OP2SUP(op::Div, complex<double>*, complex<double>*,complex<double>*);
+VSIP_IMPL_OP2SUP(op::Div, split_float,      split_float,     split_float);
+VSIP_IMPL_OP2SUP(op::Div, split_double,     split_double,    split_double);
+
+VSIP_IMPL_OP2SUP(op::Div, complex<float>*,  float*,          complex<float>*);
+VSIP_IMPL_OP2SUP(op::Div, split_float,      float*,          split_float);
+
+// scalar-vector vector division
+// not in sal  (op::Div, int,             int*,            int*);
+VSIP_IMPL_OP2SUP(op::Div, int*,            int,             int*);
+VSIP_IMPL_OP2SUP(op::Div, float,           float*,          float*);
+VSIP_IMPL_OP2SUP(op::Div, float*,          float,           float*);
+// not in sal   (op::Div, complex<float>,  complex<float>*, complex<float>*);
+// not in sal   (op::Div, complex<float>*, complex<float>,  complex<float>*);
+// not in sal   (op::Div, double,          double*,         double*);
+VSIP_IMPL_OP2SUP(op::Div, double*,         double,          double*);
+// not in sal   (op::Div, complex<double>, complex<double>*,complex<double>*);
+// not in sal   (op::Div, complex<double>*,complex<double>, complex<double>*);
+
+
+// Logical
+
+VSIP_IMPL_OP2SUP(band_functor, int*,             int*,            int*);
+VSIP_IMPL_OP2SUP(bor_functor,  int*,             int*,            int*);
+
+
+// vector comparisons
+
+VSIP_IMPL_OP2SUP(max_functor, float*,             float*,            float*);
+VSIP_IMPL_OP2SUP(max_functor, double*,            double*,           double*);
+
+VSIP_IMPL_OP2SUP(min_functor, float*,             float*,            float*);
+VSIP_IMPL_OP2SUP(min_functor, double*,            double*,           double*);
+
+
+// Vector comparisons to 1/0
+VSIP_IMPL_OP2SUP(veq_token, float*,  float*,  float*);
+VSIP_IMPL_OP2SUP(veq_token, double*, double*, double*);
+VSIP_IMPL_OP2SUP(veq_token, int*,    int*,    int*);
+VSIP_IMPL_OP2SUP(vne_token, float*,  float*,  float*);
+VSIP_IMPL_OP2SUP(vne_token, double*, double*, double*);
+VSIP_IMPL_OP2SUP(vne_token, int*,    int*,    int*);
+VSIP_IMPL_OP2SUP(vgt_token, float*,  float*,  float*);
+VSIP_IMPL_OP2SUP(vgt_token, double*, double*, double*);
+VSIP_IMPL_OP2SUP(vgt_token, int*,    int*,    int*);
+VSIP_IMPL_OP2SUP(vge_token, float*,  float*,  float*);
+VSIP_IMPL_OP2SUP(vge_token, double*, double*, double*);
+VSIP_IMPL_OP2SUP(vge_token, int*,    int*,    int*);
+VSIP_IMPL_OP2SUP(vlt_token, float*,  float*,  float*);
+VSIP_IMPL_OP2SUP(vlt_token, double*, double*, double*);
+VSIP_IMPL_OP2SUP(vlt_token, int*,    int*,    int*);
+VSIP_IMPL_OP2SUP(vle_token, float*,  float*,  float*);
+VSIP_IMPL_OP2SUP(vle_token, double*, double*, double*);
+VSIP_IMPL_OP2SUP(vle_token, int*,    int*,    int*);
+
+
+
+/***********************************************************************
+  Ternary operators and functions provided by SAL.
+***********************************************************************/
+
+// Multiply-add
+
+VSIP_IMPL_OP3SUP(ma_functor, float,   float*,  float*, float*);
+VSIP_IMPL_OP3SUP(ma_functor, float*,  float,   float*, float*);
+VSIP_IMPL_OP3SUP(ma_functor, float*,  float*,  float,  float*);
+VSIP_IMPL_OP3SUP(ma_functor, float*,  float*,  float*, float*);
+
+VSIP_IMPL_OP3SUP(ma_functor, complex<float>*, complex<float>, complex<float>*,
+		 complex<float>*);
+VSIP_IMPL_OP3SUP(ma_functor, complex<float>, complex<float>*, complex<float>*,
+		 complex<float>*);
+VSIP_IMPL_OP3SUP(ma_functor, split_float, complex<float>, split_float,
+		 split_float);
+VSIP_IMPL_OP3SUP(ma_functor, complex<float>, split_float, split_float,
+		 split_float);
+
+VSIP_IMPL_OP3SUP(ma_functor, double,   double*,  double*, double*);
+VSIP_IMPL_OP3SUP(ma_functor, double*,  double,   double*, double*);
+VSIP_IMPL_OP3SUP(ma_functor, double*,  double*,  double,  double*);
+VSIP_IMPL_OP3SUP(ma_functor, double*,  double*,  double*, double*);
+
+VSIP_IMPL_OP3SUP(ma_functor,
+		 complex<double>*, complex<double>, complex<double>*,
+		 complex<double>*);
+VSIP_IMPL_OP3SUP(ma_functor,
+		 complex<double>, complex<double>*, complex<double>*,
+		 complex<double>*);
+
+
+// Multiply-subtract
+
+VSIP_IMPL_OP3SUP(msb_functor, float,   float*,  float*, float*);
+VSIP_IMPL_OP3SUP(msb_functor, float*,  float,   float*, float*);
+// not in sal   (msb_functor, float*,  float*,  float,  float*);
+VSIP_IMPL_OP3SUP(msb_functor, float*,  float*,  float*, float*);
+
+VSIP_IMPL_OP3SUP(msb_functor, double,   double*,  double*, double*);
+VSIP_IMPL_OP3SUP(msb_functor, double*,  double,   double*, double*);
+// not in sal   (msb_functor, double*,  double*,  double,  double*);
+VSIP_IMPL_OP3SUP(msb_functor, double*,  double*,  double*, double*);
+
+// no complex msb in SAL
+
+
+// Add-multiply
+
+// not in SAL   (am_functor, float,   float*,  float*, float*);
+// not in SAL   (am_functor, float*,  float,   float*, float*);
+VSIP_IMPL_OP3SUP(am_functor, float*,  float*,  float,  float*);
+VSIP_IMPL_OP3SUP(am_functor, float*,  float*,  float*, float*);
+
+// not in SAL   (am_functor, double,  double*, double*,double*);
+// not in SAL   (am_functor, double*, double,  double*,double*);
+// not in SAL   (am_functor, double*, double*, double, double*);
+VSIP_IMPL_OP3SUP(am_functor, double*, double*, double*,double*);
+
+
+// Subtract-multiply
+VSIP_IMPL_OP3SUP(sbm_functor, float*,  float*,  float,  float*);
+VSIP_IMPL_OP3SUP(sbm_functor, float*,  float*,  float*, float*);
+VSIP_IMPL_OP3SUP(sbm_functor, double*, double*, double*,double*);
+
+
+// Conjugate(multiply)-add
+
+VSIP_IMPL_OP3SUP(cma_token, complex<float>*, complex<float>*, complex<float>*,
+		 complex<float>*);
+VSIP_IMPL_OP3SUP(cma_token, split_float*, split_float*, split_float*,
+		 split_float*);
+
+
+
+#undef VSIP_IMPL_OP1SUP
+#undef VSIP_IMPL_OP2SUP
+#undef VSIP_IMPL_OP3SUP
+
+} // namespace vsip::impl::sal
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_SAL_IS_OP_SUPPORTED_HPP
Index: src/vsip/opt/sal/elementwise.hpp
===================================================================
--- src/vsip/opt/sal/elementwise.hpp	(revision 152478)
+++ src/vsip/opt/sal/elementwise.hpp	(working copy)
@@ -287,6 +287,24 @@
 VSIP_IMPL_VV  (vminmg, float,  vminmgx)
 VSIP_IMPL_VV  (vminmg, double, vminmgdx)
 
+VSIP_IMPL_VV  (lveq,   float,  lveqx)
+VSIP_IMPL_VV  (lveq,   double, lveqdx)
+VSIP_IMPL_VV  (lveq,   int,    lveqix)
+VSIP_IMPL_VV  (lvne,   float,  lvnex)
+VSIP_IMPL_VV  (lvne,   double, lvnedx)
+VSIP_IMPL_VV  (lvne,   int,    lvneix)
+VSIP_IMPL_VV  (lvge,   float,  lvgex)
+VSIP_IMPL_VV  (lvge,   double, lvgedx)
+VSIP_IMPL_VV  (lvge,   int,    lvgeix)
+VSIP_IMPL_VV  (lvgt,   float,  lvgtx)
+VSIP_IMPL_VV  (lvgt,   double, lvgtdx)
+VSIP_IMPL_VV  (lvgt,   int,    lvgtix)
+VSIP_IMPL_VV  (lvle,   float,  lvlex)
+VSIP_IMPL_VV  (lvle,   double, lvledx)
+VSIP_IMPL_VV  (lvle,   int,    lvleix)
+VSIP_IMPL_VV  (lvlt,   float,  lvltx)
+VSIP_IMPL_VV  (lvlt,   double, lvltdx)
+VSIP_IMPL_VV  (lvlt,   int,    lvltix)
 
 
 // (inter vector, inter vector) -> inter vector
Index: src/vsip/opt/sal/eval_elementwise.hpp
===================================================================
--- src/vsip/opt/sal/eval_elementwise.hpp	(revision 152478)
+++ src/vsip/opt/sal/eval_elementwise.hpp	(working copy)
@@ -24,6 +24,7 @@
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/opt/sal/eval_util.hpp>
 #include <vsip/core/adjust_layout.hpp>
+#include <vsip/opt/sal/is_op_supported.hpp>
 
 
 
@@ -38,391 +39,7 @@
 namespace sal
 {
 
-/// Traits class to help determine when SAL supports a given
-/// binary operation.
-///
-/// Requirements:
-///   OPERATOR is the Operator template class for the operation
-///      (from the vsip::impl::op namespace).
-///   LTYPE is the type of the left operand.
-///   RTYPE is the type of the right operand.
-///   RTYPE is the type of the result.
-///
-/// For LTYPE, RTYPE, and DSTTYPE, vector operands should be represented
-/// by a pointer type (for example: float*, complex<float>*, and
-/// std::pair<float*, float*>).  scalar operand should be represented
-/// by a value type, such as float, complex<float>, std::pair<float, float>.
-
-template <template <typename, typename> class Operator,
-	  typename                            LType,
-	  typename                            RType,
-	  typename                            DstType>
-struct Is_op2_supported
-{
-  static bool const value = false;
-};
-
-template <template <typename> class Operator,
-	  typename                  SrcType,
-	  typename                  DstType>
-struct Is_op1_supported
-{
-  static bool const value = false;
-};
-
-template <template <typename, typename, typename> class Operator,
-	  typename                            Type1,
-	  typename                            Type2,
-	  typename                            Type3,
-	  typename                            DstType>
-struct Is_op3_supported
-{
-  static bool const value = false;
-};
-
-
-template <typename, typename, typename> struct cma_token;
-template <typename> struct copy_token;
-
-#define VSIP_IMPL_OP1SUP(Op, T1, DT)					\
-  template <> struct Is_op1_supported<Op, T1, DT >			\
-  { static bool const value = true; }
-
-#define VSIP_IMPL_OP2SUP(Op, LT, RT, DT)				\
-  template <> struct Is_op2_supported<Op, LT, RT, DT >			\
-  { static bool const value = true; }
-
-#define VSIP_IMPL_OP3SUP(Op, T1, T2, T3, DT)				\
-  template <> struct Is_op3_supported<Op, T1, T2, T3, DT >		\
-  { static bool const value = true; }
-
-typedef std::pair<float*, float*>   split_float;
-typedef std::pair<double*, double*> split_double;
-
-
 /***********************************************************************
-  Unary operators and functions provided by SAL
-***********************************************************************/
-
-VSIP_IMPL_OP1SUP(magsq_functor, complex<float>*,  float*);
-VSIP_IMPL_OP1SUP(magsq_functor, complex<double>*, double*);
-VSIP_IMPL_OP1SUP(magsq_functor, split_float,      float*);
-VSIP_IMPL_OP1SUP(magsq_functor, split_double,     double*);
-
-VSIP_IMPL_OP1SUP(op::Minus,     int*,             int*);
-VSIP_IMPL_OP1SUP(op::Minus,     float*,           float*);
-VSIP_IMPL_OP1SUP(op::Minus,     double*,          double*);
-VSIP_IMPL_OP1SUP(op::Minus,     complex<float>*,  complex<float>*);
-VSIP_IMPL_OP1SUP(op::Minus,     complex<double>*, complex<double>*);
-VSIP_IMPL_OP1SUP(op::Minus,     split_float,      split_float);
-VSIP_IMPL_OP1SUP(op::Minus,     split_double,     split_double);
-
-VSIP_IMPL_OP1SUP(mag_functor,   int*,             int*);
-VSIP_IMPL_OP1SUP(mag_functor,   float*,           float*);
-VSIP_IMPL_OP1SUP(mag_functor,   double*,          double*);
-VSIP_IMPL_OP1SUP(mag_functor,   complex<float>*,  float*);
-VSIP_IMPL_OP1SUP(mag_functor,   split_float,      float*);
-
-VSIP_IMPL_OP1SUP(cos_functor,   float*,           float*);
-VSIP_IMPL_OP1SUP(cos_functor,   double*,          double*);
-
-VSIP_IMPL_OP1SUP(sin_functor,   float*,           float*);
-VSIP_IMPL_OP1SUP(sin_functor,   double*,          double*);
-
-VSIP_IMPL_OP1SUP(tan_functor,   float*,           float*);
-
-VSIP_IMPL_OP1SUP(atan_functor,  float*,           float*);
-VSIP_IMPL_OP1SUP(atan_functor,  double*,          double*);
-
-VSIP_IMPL_OP1SUP(log_functor,   float*,           float*);
-VSIP_IMPL_OP1SUP(log_functor,   double*,          double*);
-
-VSIP_IMPL_OP1SUP(log10_functor, float*,           float*);
-VSIP_IMPL_OP1SUP(log10_functor, double*,          double*);
-
-VSIP_IMPL_OP1SUP(exp_functor,   float*,           float*);
-VSIP_IMPL_OP1SUP(exp_functor,   double*,          double*);
-
-VSIP_IMPL_OP1SUP(exp10_functor, float*,           float*);
-VSIP_IMPL_OP1SUP(exp10_functor, double*,          double*);
-
-VSIP_IMPL_OP1SUP(sqrt_functor,  float*,           float*);
-VSIP_IMPL_OP1SUP(sqrt_functor,  double*,          double*);
-VSIP_IMPL_OP1SUP(sqrt_functor,  complex<float>*,  complex<float>*);
-VSIP_IMPL_OP1SUP(sqrt_functor,  split_float,      split_float);
-
-VSIP_IMPL_OP1SUP(rsqrt_functor, float*,           float*);
-VSIP_IMPL_OP1SUP(rsqrt_functor, double*,          double*);
-
-VSIP_IMPL_OP1SUP(sq_functor,    float*,           float*);
-VSIP_IMPL_OP1SUP(sq_functor,    double*,          double*);
-
-VSIP_IMPL_OP1SUP(recip_functor, float*,           float*);
-// no scalar double
-VSIP_IMPL_OP1SUP(recip_functor, complex<float>*,  complex<float>*);
-VSIP_IMPL_OP1SUP(recip_functor, split_float,      split_float);
-VSIP_IMPL_OP1SUP(recip_functor, complex<double>*, complex<double>*);
-VSIP_IMPL_OP1SUP(recip_functor, split_double,     split_double);
-
-VSIP_IMPL_OP1SUP(copy_token,    float*,           float*);
-VSIP_IMPL_OP1SUP(copy_token,    complex<float>*,  complex<float>*);
-VSIP_IMPL_OP1SUP(copy_token,    split_float,      split_float);
-VSIP_IMPL_OP1SUP(copy_token,    complex<double>*, complex<double>*);
-VSIP_IMPL_OP1SUP(copy_token,    split_double,     split_double);
-
-VSIP_IMPL_OP1SUP(copy_token,    split_float,      complex<float>*);
-VSIP_IMPL_OP1SUP(copy_token,    complex<float>*,  split_float);
-VSIP_IMPL_OP1SUP(copy_token,    split_double,     complex<double>*);
-VSIP_IMPL_OP1SUP(copy_token,    complex<double>*, split_double);
-
-
-
-/***********************************************************************
-  Binary operators and functions provided by SAL
-***********************************************************************/
-
-// straight-up vector add
-VSIP_IMPL_OP2SUP(op::Add, int*,             int*,            int*);
-VSIP_IMPL_OP2SUP(op::Add, float*,           float*,          float*);
-VSIP_IMPL_OP2SUP(op::Add, double*,          double*,         double*);
-VSIP_IMPL_OP2SUP(op::Add, complex<float>*,  complex<float>*, complex<float>*);
-VSIP_IMPL_OP2SUP(op::Add, complex<double>*, complex<double>*,complex<double>*);
-VSIP_IMPL_OP2SUP(op::Add, split_float,      split_float,     split_float);
-VSIP_IMPL_OP2SUP(op::Add, split_double,     split_double,    split_double);
-
-VSIP_IMPL_OP2SUP(op::Add, float*,           complex<float>*, complex<float>*);
-VSIP_IMPL_OP2SUP(op::Add, complex<float>*,  float*,          complex<float>*);
-VSIP_IMPL_OP2SUP(op::Add, float*,           split_float,     split_float);
-VSIP_IMPL_OP2SUP(op::Add, split_float,      float*,          split_float);
-// not crvadddx in SAL
-
-// scalar-vector vector add
-VSIP_IMPL_OP2SUP(op::Add, int,              int*,            int*);
-VSIP_IMPL_OP2SUP(op::Add, int*,             int,             int*);
-VSIP_IMPL_OP2SUP(op::Add, float,            float*,          float*);
-VSIP_IMPL_OP2SUP(op::Add, float*,           float,           float*);
-VSIP_IMPL_OP2SUP(op::Add, double,           double*,         double*);
-VSIP_IMPL_OP2SUP(op::Add, double*,          double,          double*);
-VSIP_IMPL_OP2SUP(op::Add, complex<float>,   complex<float>*, complex<float>*);
-VSIP_IMPL_OP2SUP(op::Add, complex<float>*,  complex<float>,  complex<float>*);
-VSIP_IMPL_OP2SUP(op::Add, complex<double>,  complex<double>*,complex<double>*);
-VSIP_IMPL_OP2SUP(op::Add, complex<double>*, complex<double>, complex<double>*);
-VSIP_IMPL_OP2SUP(op::Add, complex<float>,   split_float,     split_float);
-VSIP_IMPL_OP2SUP(op::Add, split_float,      complex<float>,  split_float);
-VSIP_IMPL_OP2SUP(op::Add, complex<double>,  split_double,    split_double);
-VSIP_IMPL_OP2SUP(op::Add, split_double,     complex<double>, split_double);
-
-VSIP_IMPL_OP2SUP(op::Add, float,            complex<float>*, complex<float>*);
-VSIP_IMPL_OP2SUP(op::Add, complex<float>*,  float,           complex<float>*);
-VSIP_IMPL_OP2SUP(op::Add, double,           complex<double>*,complex<double>*);
-VSIP_IMPL_OP2SUP(op::Add, complex<double>*, double,          complex<double>*);
-
-VSIP_IMPL_OP2SUP(op::Add, float,            split_float,     split_float);
-VSIP_IMPL_OP2SUP(op::Add, split_float,      float,           split_float);
-VSIP_IMPL_OP2SUP(op::Add, double,           split_double,    split_double);
-VSIP_IMPL_OP2SUP(op::Add, split_double,     double,          split_double);
-
-
-// straight-up vector sub
-VSIP_IMPL_OP2SUP(op::Sub, int*,             int*,            int*);
-VSIP_IMPL_OP2SUP(op::Sub, float*,           float*,          float*);
-VSIP_IMPL_OP2SUP(op::Sub, double*,          double*,         double*);
-VSIP_IMPL_OP2SUP(op::Sub, complex<float>*,  complex<float>*, complex<float>*);
-VSIP_IMPL_OP2SUP(op::Sub, complex<double>*, complex<double>*,complex<double>*);
-VSIP_IMPL_OP2SUP(op::Sub, split_float,      split_float,     split_float);
-VSIP_IMPL_OP2SUP(op::Sub, split_double,     split_double,    split_double);
-
-VSIP_IMPL_OP2SUP(op::Sub, complex<float>*,  float*,          complex<float>*);
-VSIP_IMPL_OP2SUP(op::Sub, split_float,      float*,          split_float);
-
-// scalar-vector vector sub
-VSIP_IMPL_OP2SUP(op::Sub, int*,             int,             int*);
-// not in sal   (op::Sub, float,            float*,          float*);
-VSIP_IMPL_OP2SUP(op::Sub, float*,           float,           float*);
-// not in sal   (op::Sub, double,           double*,         double*);
-VSIP_IMPL_OP2SUP(op::Sub, double*,          double,          double*);
-// not in sal   (op::Sub, complex<float>,   complex<float>*, complex<float>*);
-VSIP_IMPL_OP2SUP(op::Sub, complex<float>*,  complex<float>,  complex<float>*);
-// not in sal   (op::Sub, complex<double>,  complex<double>*,complex<double>*);
-VSIP_IMPL_OP2SUP(op::Sub, complex<double>*, complex<double>, complex<double>*);
-// not in sal   (op::Sub, complex<float>,   split_float,     split_float);
-VSIP_IMPL_OP2SUP(op::Sub, split_float,      complex<float>,  split_float);
-// not in sal   (op::Sub, complex<double>,  split_double,    split_double);
-VSIP_IMPL_OP2SUP(op::Sub, split_double,     complex<double>, split_double);
-
-VSIP_IMPL_OP2SUP(op::Sub, complex<float>*,  float,           complex<float>*);
-VSIP_IMPL_OP2SUP(op::Sub, complex<double>*, double,          complex<double>*);
-VSIP_IMPL_OP2SUP(op::Sub, split_float,      float,           split_float);
-VSIP_IMPL_OP2SUP(op::Sub, split_double,     double,          split_double);
-
-
-// straight-up vector multiply
-VSIP_IMPL_OP2SUP(op::Mult, int*,            int*,            int*);
-VSIP_IMPL_OP2SUP(op::Mult, float*,          float*,          float*);
-VSIP_IMPL_OP2SUP(op::Mult, double*,         double*,         double*);
-VSIP_IMPL_OP2SUP(op::Mult, complex<float>*, complex<float>*, complex<float>*);
-VSIP_IMPL_OP2SUP(op::Mult, complex<double>*,complex<double>*,complex<double>*);
-VSIP_IMPL_OP2SUP(op::Mult, split_float,     split_float,     split_float);
-VSIP_IMPL_OP2SUP(op::Mult, split_double,    split_double,    split_double);
-
-// real-complex vector multiply
-VSIP_IMPL_OP2SUP(op::Mult, complex<float>*, float*,          complex<float>*);
-VSIP_IMPL_OP2SUP(op::Mult, float*,          complex<float>*, complex<float>*);
-VSIP_IMPL_OP2SUP(op::Mult, split_float,     float*,          split_float);
-VSIP_IMPL_OP2SUP(op::Mult, float*,          split_float,     split_float);
-
-// scalar-vector vector multiply
-VSIP_IMPL_OP2SUP(op::Mult, int,             int*,            int*);
-VSIP_IMPL_OP2SUP(op::Mult, int*,            int,             int*);
-VSIP_IMPL_OP2SUP(op::Mult, float,           float*,          float*);
-VSIP_IMPL_OP2SUP(op::Mult, float*,          float,           float*);
-VSIP_IMPL_OP2SUP(op::Mult, double,          double*,         double*);
-VSIP_IMPL_OP2SUP(op::Mult, double*,         double,          double*);
-VSIP_IMPL_OP2SUP(op::Mult, complex<float>,  complex<float>*, complex<float>*);
-VSIP_IMPL_OP2SUP(op::Mult, complex<float>*, complex<float>,  complex<float>*);
-VSIP_IMPL_OP2SUP(op::Mult, complex<double>, complex<double>*,complex<double>*);
-VSIP_IMPL_OP2SUP(op::Mult, complex<double>*,complex<double>, complex<double>*);
-VSIP_IMPL_OP2SUP(op::Mult, complex<float>,  split_float,     split_float);
-VSIP_IMPL_OP2SUP(op::Mult, split_float,     complex<float>,  split_float);
-VSIP_IMPL_OP2SUP(op::Mult, complex<double>, split_double,    split_double);
-VSIP_IMPL_OP2SUP(op::Mult, split_double,    complex<double>, split_double);
-
-VSIP_IMPL_OP2SUP(op::Mult, float,           complex<float>*, complex<float>*);
-VSIP_IMPL_OP2SUP(op::Mult, complex<float>*, float,           complex<float>*);
-VSIP_IMPL_OP2SUP(op::Mult, double,          complex<double>*,complex<double>*);
-VSIP_IMPL_OP2SUP(op::Mult, complex<double>*,double,          complex<double>*);
-
-VSIP_IMPL_OP2SUP(op::Mult, float,           split_float,     split_float);
-VSIP_IMPL_OP2SUP(op::Mult, split_float,     float,           split_float);
-VSIP_IMPL_OP2SUP(op::Mult, double,          split_double,    split_double);
-VSIP_IMPL_OP2SUP(op::Mult, split_double,    double,          split_double);
-
-
-
-// straight-up vector division
-VSIP_IMPL_OP2SUP(op::Div, int*,             int*,            int*);
-VSIP_IMPL_OP2SUP(op::Div, float*,           float*,          float*);
-VSIP_IMPL_OP2SUP(op::Div, double*,          double*,         double*);
-VSIP_IMPL_OP2SUP(op::Div, complex<float>*,  complex<float>*, complex<float>*);
-VSIP_IMPL_OP2SUP(op::Div, complex<double>*, complex<double>*,complex<double>*);
-VSIP_IMPL_OP2SUP(op::Div, split_float,      split_float,     split_float);
-VSIP_IMPL_OP2SUP(op::Div, split_double,     split_double,    split_double);
-
-VSIP_IMPL_OP2SUP(op::Div, complex<float>*,  float*,          complex<float>*);
-VSIP_IMPL_OP2SUP(op::Div, split_float,      float*,          split_float);
-
-// scalar-vector vector division
-// not in sal  (op::Div, int,             int*,            int*);
-VSIP_IMPL_OP2SUP(op::Div, int*,            int,             int*);
-VSIP_IMPL_OP2SUP(op::Div, float,           float*,          float*);
-VSIP_IMPL_OP2SUP(op::Div, float*,          float,           float*);
-// not in sal   (op::Div, complex<float>,  complex<float>*, complex<float>*);
-// not in sal   (op::Div, complex<float>*, complex<float>,  complex<float>*);
-// not in sal   (op::Div, double,          double*,         double*);
-VSIP_IMPL_OP2SUP(op::Div, double*,         double,          double*);
-// not in sal   (op::Div, complex<double>, complex<double>*,complex<double>*);
-// not in sal   (op::Div, complex<double>*,complex<double>, complex<double>*);
-
-
-// Logical
-
-VSIP_IMPL_OP2SUP(band_functor, int*,             int*,            int*);
-VSIP_IMPL_OP2SUP(bor_functor,  int*,             int*,            int*);
-
-
-// vector comparisons
-
-VSIP_IMPL_OP2SUP(max_functor, float*,             float*,            float*);
-VSIP_IMPL_OP2SUP(max_functor, double*,            double*,           double*);
-
-VSIP_IMPL_OP2SUP(min_functor, float*,             float*,            float*);
-VSIP_IMPL_OP2SUP(min_functor, double*,            double*,           double*);
-
-
-
-/***********************************************************************
-  Ternary operators and functions provided by SAL.
-***********************************************************************/
-
-// Multiply-add
-
-VSIP_IMPL_OP3SUP(ma_functor, float,   float*,  float*, float*);
-VSIP_IMPL_OP3SUP(ma_functor, float*,  float,   float*, float*);
-VSIP_IMPL_OP3SUP(ma_functor, float*,  float*,  float,  float*);
-VSIP_IMPL_OP3SUP(ma_functor, float*,  float*,  float*, float*);
-
-VSIP_IMPL_OP3SUP(ma_functor, complex<float>*, complex<float>, complex<float>*,
-		 complex<float>*);
-VSIP_IMPL_OP3SUP(ma_functor, complex<float>, complex<float>*, complex<float>*,
-		 complex<float>*);
-VSIP_IMPL_OP3SUP(ma_functor, split_float, complex<float>, split_float,
-		 split_float);
-VSIP_IMPL_OP3SUP(ma_functor, complex<float>, split_float, split_float,
-		 split_float);
-
-VSIP_IMPL_OP3SUP(ma_functor, double,   double*,  double*, double*);
-VSIP_IMPL_OP3SUP(ma_functor, double*,  double,   double*, double*);
-VSIP_IMPL_OP3SUP(ma_functor, double*,  double*,  double,  double*);
-VSIP_IMPL_OP3SUP(ma_functor, double*,  double*,  double*, double*);
-
-VSIP_IMPL_OP3SUP(ma_functor,
-		 complex<double>*, complex<double>, complex<double>*,
-		 complex<double>*);
-VSIP_IMPL_OP3SUP(ma_functor,
-		 complex<double>, complex<double>*, complex<double>*,
-		 complex<double>*);
-
-
-// Multiply-subtract
-
-VSIP_IMPL_OP3SUP(msb_functor, float,   float*,  float*, float*);
-VSIP_IMPL_OP3SUP(msb_functor, float*,  float,   float*, float*);
-// not in sal   (msb_functor, float*,  float*,  float,  float*);
-VSIP_IMPL_OP3SUP(msb_functor, float*,  float*,  float*, float*);
-
-VSIP_IMPL_OP3SUP(msb_functor, double,   double*,  double*, double*);
-VSIP_IMPL_OP3SUP(msb_functor, double*,  double,   double*, double*);
-// not in sal   (msb_functor, double*,  double*,  double,  double*);
-VSIP_IMPL_OP3SUP(msb_functor, double*,  double*,  double*, double*);
-
-// no complex msb in SAL
-
-
-// Add-multiply
-
-// not in SAL   (am_functor, float,   float*,  float*, float*);
-// not in SAL   (am_functor, float*,  float,   float*, float*);
-VSIP_IMPL_OP3SUP(am_functor, float*,  float*,  float,  float*);
-VSIP_IMPL_OP3SUP(am_functor, float*,  float*,  float*, float*);
-
-// not in SAL   (am_functor, double,  double*, double*,double*);
-// not in SAL   (am_functor, double*, double,  double*,double*);
-// not in SAL   (am_functor, double*, double*, double, double*);
-VSIP_IMPL_OP3SUP(am_functor, double*, double*, double*,double*);
-
-
-// Subtract-multiply
-VSIP_IMPL_OP3SUP(sbm_functor, float*,  float*,  float,  float*);
-VSIP_IMPL_OP3SUP(sbm_functor, float*,  float*,  float*, float*);
-VSIP_IMPL_OP3SUP(sbm_functor, double*, double*, double*,double*);
-
-
-// Conjugate(multiply)-add
-
-VSIP_IMPL_OP3SUP(cma_token, complex<float>*, complex<float>*, complex<float>*,
-		 complex<float>*);
-VSIP_IMPL_OP3SUP(cma_token, split_float*, split_float*, split_float*,
-		 split_float*);
-
-
-
-#undef VSIP_IMPL_OP1SUP
-#undef VSIP_IMPL_OP2SUP
-#undef VSIP_IMPL_OP3SUP
-
-
-
-/***********************************************************************
   Serial expression evaluator base classes
 ***********************************************************************/
 
Index: src/vsip/opt/extdata.hpp
===================================================================
--- src/vsip/opt/extdata.hpp	(revision 152478)
+++ src/vsip/opt/extdata.hpp	(working copy)
@@ -909,6 +909,46 @@
 
 
 
+// Determine if an Ext_data object refers to a dense (contiguous,
+// unit-stride) region of memory.
+
+template <typename OrderT,
+	  typename ExtT>
+bool
+is_ext_dense(
+  vsip::dimension_type dim,
+  ExtT const&          ext)
+{
+  using vsip::dimension_type;
+  using vsip::stride_type;
+
+  dimension_type const dim0 = OrderT::impl_dim0;
+  dimension_type const dim1 = OrderT::impl_dim1;
+  dimension_type const dim2 = OrderT::impl_dim2;
+
+  assert(dim <= VSIP_MAX_DIMENSION);
+
+  if (dim == 1)
+  {
+    return (ext.stride(dim0) == 1);
+  }
+  else if (dim == 2)
+  {
+    return (ext.stride(dim1) == 1) &&
+           (ext.stride(dim0) == static_cast<stride_type>(ext.size(dim1)) ||
+	    ext.size(dim0) == 1);
+  }
+  else /*  if (dim == 2) */
+  {
+    return (ext.stride(dim2) == 1) &&
+           (ext.stride(dim1) == static_cast<stride_type>(ext.size(dim2)) ||
+	    (ext.size(dim0) == 1 && ext.size(dim1) == 1)) &&
+           (ext.stride(dim0) == static_cast<stride_type>(ext.size(dim1)  *
+							 ext.size(dim2)) ||
+	    ext.size(dim0) == 1);
+  }
+}
+
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/map.hpp
===================================================================
--- src/vsip/map.hpp	(revision 152478)
+++ src/vsip/map.hpp	(working copy)
@@ -446,6 +446,14 @@
 
 
 
+// Apply a map to a domain.
+
+// Notes:
+// [1] Do not allow maps to partition dimensions beyond the applied domain.
+//     This creates empty subblocks outside of the map's dimension,
+//     which confuses the routines which convert a map subblock index
+//     into individual dimension subblock indices (split_tuple).
+
 template <typename       Dist0,
 	  typename       Dist1,
 	  typename       Dist2>
@@ -459,7 +467,10 @@
   for (dimension_type d=0; d<Dim; ++d)
     arr[d] = dom[d];
   for (dimension_type d=Dim; d<VSIP_MAX_DIMENSION; ++d)
+  {
     arr[d] = Domain<1>(1);
+    assert(this->num_subblocks(d) == 1); // note [1]
+  }
 
   dim_ = Dim;
   dom_ = impl::construct_domain<VSIP_MAX_DIMENSION>(arr);
Index: src/vsip_csl/load_view.hpp
===================================================================
--- src/vsip_csl/load_view.hpp	(revision 152397)
+++ src/vsip_csl/load_view.hpp	(working copy)
@@ -13,9 +13,14 @@
   Included Files
 ***********************************************************************/
 
+#include <string.h>
+#include <errno.h>
+#include <memory>
+
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
+#include <vsip/core/noncopyable.hpp>
 
 
 
@@ -26,93 +31,167 @@
   Definitions
 ***********************************************************************/
 
-// This is nearly same as sarsim LoadView, but doesn't include byte
-// ordering.  Move this into common location.
+/// Load values from a file descriptor into a VSIPL++ view.
 
-template <typename T>
-struct Load_view_traits
-{
-  typedef T base_t;
-  static unsigned const factor = 1;
-};
+/// Note: assumes complex data on disk is always interleaved. 
 
-template <typename T>
-struct Load_view_traits<vsip::complex<T> >
+template <typename ViewT>
+void
+load_view(
+  FILE* fd,
+  ViewT view)
 {
-  typedef T base_t;
-  static unsigned const factor = 2;
-};
+  using vsip::impl::Block_layout;
+  using vsip::impl::Ext_data;
+  using vsip::impl::Adjust_layout_complex;
+  using vsip::impl::Cmplx_inter_fmt;
 
+  if (subblock(view) != vsip::no_subblock && subblock_domain(view).size() > 0)
+  {
+    vsip::dimension_type const Dim = ViewT::dim;
 
-template <vsip::dimension_type Dim,
-	  typename             T>
-class Load_view
-{
-public:
-  typedef typename Load_view_traits<T>::base_t base_t;
-  static unsigned const factor = Load_view_traits<T>::factor;
+    typedef typename ViewT::value_type       value_type;
+    typedef typename ViewT::local_type       l_view_type;
+    typedef typename l_view_type::block_type l_block_type;
+    typedef typename Block_layout<l_block_type>::order_type order_type;
 
-  typedef vsip::Dense<Dim, T> block_t;
-  typedef typename vsip::impl::View_of_dim<Dim, T, block_t>::type view_t;
+    typedef typename Block_layout<l_block_type>::layout_type layout_type;
+    typedef typename Adjust_layout_complex<Cmplx_inter_fmt, layout_type>::type
+      use_layout_type;
 
-public:
-  Load_view(char const*              filename,
-	    vsip::Domain<Dim> const& dom)
-    : data_  (new base_t[factor*dom.size()]),
-      block_ (dom, data_),
-      view_  (block_)
-  {
-    FILE*  fd;
-    size_t size = dom.size();
-    
-    if (!(fd = fopen(filename,"r")))
+    l_view_type l_view = view.local();
+
+    vsip::Domain<Dim> g_dom = global_domain(view);
+    vsip::Domain<Dim> l_dom = subblock_domain(view);
+
+    Ext_data<l_block_type, use_layout_type> ext(l_view.block());
+
+    // Check that subblock is dense.
+    if (!vsip::impl::is_ext_dense<order_type>(Dim, ext))
+      VSIP_IMPL_THROW(vsip::impl::unimplemented(
+	"load_view can only handle dense subblocks"));
+
+    long l_pos = 0;
+
+    if (Dim >= 1)
     {
-      fprintf(stderr,"Load_view: error opening '%s'.\n", filename);
+      l_pos += g_dom[order_type::impl_dim0].first();
+    }
+
+    if (Dim >= 2)
+    {
+      l_pos *= g_dom[order_type::impl_dim1].size();
+      l_pos += g_dom[order_type::impl_dim1].first();
+    }
+
+    if (Dim >= 3)
+    {
+      l_pos *= g_dom[order_type::impl_dim2].size();
+      l_pos += g_dom[order_type::impl_dim2].first();
+    }
+
+    l_pos *= sizeof(value_type);
+
+    size_t l_size = l_dom.size();
+
+    if (fseek(fd, l_pos, SEEK_SET) == -1)
+    {
+      fprintf(stderr, "load_view: error on fseek.\n");
       exit(1);
     }
 
-    if (size != fread(data_, sizeof(T), size, fd))
+    size_t l_read = fread(ext.data(), sizeof(value_type), l_size, fd);
+    if (l_read != l_size)
     {
-      fprintf(stderr, "Load_view: error reading file %s.\n", filename);
+      std::cout << "load_view: error reading file %s." << std::endl;
+      std::cout << "         : read " << l_read << " elements" << std::endl;
+      std::cout << "         : expecting " << l_size << std::endl;
       exit(1);
     }
-  
-    fclose(fd);
-    
-    block_.admit(true);
   }
+}
 
 
 
-  Load_view(FILE*              fd,
-	    vsip::Domain<Dim> const& dom)
-    : data_  (new base_t[factor*dom.size()]),
-      block_ (dom, data_),
-      view_  (block_)
+/// Load values from a file into a VSIPL++ view.
+
+template <typename ViewT>
+void
+load_view(
+  char const* filename,
+  ViewT       view)
+{
+  if (subblock(view) != vsip::no_subblock && subblock_domain(view).size() > 0)
   {
-    size_t size = dom.size();
-
-    if (size != fread(data_, sizeof(T), size, fd))
+    FILE*  fd;
+    
+    if (!(fd = fopen(filename, "r")))
     {
-      fprintf(stderr, "Load_view: error reading file.\n");
+      fprintf(stderr, "load_view: error opening '%s'.\n", filename);
       exit(1);
     }
-    
-    block_.admit(true);
+
+    load_view(fd, view);
+
+    fclose(fd);
   }
+}
 
-  ~Load_view()
-  { delete[] data_; }
 
-  view_t view() { return view_; }
 
+/// Load values from a file into a VSIPL++ view.
+
+/// Requires
+///   DIM to be the dimension of the data/view,
+///   T to be the value type of the data/view
+///   ORDERT to be the dimension ordering of the data and view
+///      (row-major by default).
+///   MAPT to be the mapping of the view
+///      (Local_map by default).
+
+template <vsip::dimension_type Dim,
+	  typename          T,
+	  typename          OrderT = typename vsip::impl::Row_major<Dim>::type,
+	  typename          MapT = vsip::Local_map>
+class Load_view : vsip::impl::Non_copyable
+{
+public:
+  typedef T value_type;
+  typedef vsip::Dense<Dim, T, OrderT, MapT> block_type;
+  typedef typename vsip::impl::View_of_dim<Dim, T, block_type>::type view_type;
+
+public:
+  Load_view(char const*              filename,
+	    vsip::Domain<Dim> const& dom,
+	    MapT const&              map = MapT())
+    : block_ (dom, map),
+      view_  (block_)
+  {
+    load_view(filename, view_);
+  }
+
+
+
+  Load_view(FILE*                    fd,
+	    vsip::Domain<Dim> const& dom,
+	    MapT const&              map = MapT())
+    : block_ (dom, map),
+      view_  (block_)
+  {
+    load_view(fd, view_);
+  }
+
+  view_type view() { return view_; }
+
 private:
-  base_t*       data_;
-
-  block_t       block_;
-  view_t        view_;
+  block_type                block_;
+  view_type                 view_;
 };
 
+
+
+
+
 } // namespace vsip_csl
 
 #endif // VSIP_CSL_LOAD_VIEW_HPP
Index: src/vsip_csl/save_view.hpp
===================================================================
--- src/vsip_csl/save_view.hpp	(revision 152397)
+++ src/vsip_csl/save_view.hpp	(working copy)
@@ -16,6 +16,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
+#include <vsip/core/adjust_layout.hpp>
 
 
 
@@ -26,115 +27,155 @@
   Definitions
 ***********************************************************************/
 
-template <typename T>
-struct Save_view_traits
+template <typename             OrderT,
+	  vsip::dimension_type Dim>
+bool
+is_subdomain_contiguous(
+  vsip::Domain<Dim> const&       sub_dom,
+  vsip::impl::Length<Dim> const& ext)
 {
-   typedef T base_t;
-   static unsigned const factor = 1;
-};
+  using vsip::dimension_type;
+  using vsip::stride_type;
 
-template <typename T>
-struct Save_view_traits<vsip::complex<T> >
-{
-   typedef T base_t;
-   static unsigned const factor = 2;
-};
+  dimension_type const dim0 = OrderT::impl_dim0;
+  dimension_type const dim1 = OrderT::impl_dim1;
+  dimension_type const dim2 = OrderT::impl_dim2;
 
+  assert(Dim <= VSIP_MAX_DIMENSION);
 
+  if (Dim == 1)
+  {
+    return (sub_dom[dim0].stride() == 1);
+  }
+  else if (Dim == 2)
+  {
+    return (sub_dom[dim1].stride() == 1) &&
+           (sub_dom[dim0].size() == 1 ||
+	    (sub_dom[dim0].stride() == 1 &&
+	     sub_dom[dim1].size() == ext[dim1]));
+  }
+  else /*  if (Dim == 2) */
+  {
+    return (sub_dom[dim2].stride() == 1) &&
+           (sub_dom[dim0].size() == 1 && sub_dom[dim1].size() == 1 ||
+	    (sub_dom[dim1].stride() == 1 &&
+	     sub_dom[dim2].size() == ext[dim2])) &&
+           (sub_dom[dim0].size() == 1 ||
+	    (sub_dom[dim0].stride() == 1 &&
+	     sub_dom[dim1].size() == ext[dim1]));
+  }
+}
 
-template <vsip::dimension_type Dim,
-	  typename             T>
-class Save_view
+
+
+/// Save a view to a FILE*.
+///
+/// Requires:
+///   FD to be a FILE open for writing.
+///   VIEW to be a VSIPL++ view.
+
+template <typename ViewT>
+void
+save_view(
+  FILE* fd,
+  ViewT view)
 {
-public:
-  typedef typename Save_view_traits<T>::base_t base_t;
-  static unsigned const factor = Save_view_traits<T>::factor;
+  using vsip::impl::Block_layout;
+  using vsip::impl::Ext_data;
+  using vsip::impl::Adjust_layout_complex;
+  using vsip::impl::Cmplx_inter_fmt;
 
-  typedef vsip::Dense<Dim, T> block_t;
-  typedef typename vsip::impl::View_of_dim<Dim, T, block_t>::type view_t;
-
-public:
-  static void save(char*  filename,
-		   view_t view)
+  if (subblock(view) != vsip::no_subblock)
   {
-    vsip::Domain<Dim> dom(get_domain(view));
-    base_t*           data(new base_t[factor*dom.size()]);
+    vsip::dimension_type const Dim = ViewT::dim;
 
-    block_t           block(dom, data);
-    view_t            store(block);
+    typedef typename ViewT::value_type       value_type;
+    typedef typename ViewT::local_type       l_view_type;
+    typedef typename l_view_type::block_type l_block_type;
+    typedef typename Block_layout<l_block_type>::order_type order_type;
 
-    FILE*  fd;
-    size_t size = dom.size();
+    typedef typename Block_layout<l_block_type>::layout_type layout_type;
+    typedef typename Adjust_layout_complex<Cmplx_inter_fmt, layout_type>::type
+      use_layout_type;
 
-    if (!(fd = fopen(filename,"w")))
+    l_view_type l_view = view.local();
+
+    vsip::Domain<Dim> g_dom = global_domain(view);
+    vsip::Domain<Dim> l_dom = subblock_domain(view);
+
+    assert(is_subdomain_contiguous<order_type>(g_dom, extent(view)));
+
+    Ext_data<l_block_type, use_layout_type> ext(l_view.block());
+
+
+    // Check that subblock is dense.
+    assert(vsip::impl::is_ext_dense<order_type>(Dim, ext));
+
+    long l_pos = 0;
+
+    if (Dim >= 1)
     {
-      fprintf(stderr,"Save_view: error opening '%s'.\n", filename);
-      exit(1);
+      l_pos += g_dom[order_type::impl_dim0].first();
     }
 
-    block.admit(false);
-    store = view;
-    block.release(true);
-    
-    if (size != fwrite(data, sizeof(T), size, fd))
+    if (Dim >= 2)
     {
-      fprintf(stderr, "Save_view: Error writing.\n");
-      exit(1);
+      l_pos *= g_dom[order_type::impl_dim1].size();
+      l_pos += g_dom[order_type::impl_dim1].first();
     }
 
-    fclose(fd);
-  }
+    if (Dim >= 3)
+    {
+      l_pos *= g_dom[order_type::impl_dim2].size();
+      l_pos += g_dom[order_type::impl_dim2].first();
+    }
 
-private:
-  template <typename T1,
-	    typename Block1>
-  static vsip::Domain<1> get_domain(vsip::const_Vector<T1, Block1> view)
-  { return vsip::Domain<1>(view.size()); }
+    l_pos *= sizeof(value_type);
 
-  template <typename T1,
-	    typename Block1>
-  static vsip::Domain<2> get_domain(vsip::const_Matrix<T1, Block1> view)
-  { return vsip::Domain<2>(view.size(0), view.size(1)); }
+    size_t l_size = l_dom.size();
 
-  template <typename T1,
-	    typename Block1>
-  static vsip::Domain<3> get_domain(vsip::const_Tensor<T1, Block1> view)
-  { return vsip::Domain<3>(view.size(0), view.size(1), view.size(2)); }
-};
+    if (fseek(fd, l_pos, SEEK_SET) == -1)
+    {
+      fprintf(stderr, "save_view: error on fseek.\n");
+      exit(1);
+    }
 
-
-template <typename T,
-	  typename Block>
-void
-save_view(
-   char*                        filename,
-   vsip::const_Vector<T, Block> view)
-{
-   Save_view<1, T>::save(filename, view);
+    if (fwrite(ext.data(), sizeof(value_type), l_size, fd) != l_size)
+    {
+      fprintf(stderr, "save_view: error reading file.\n");
+      exit(1);
+    }
+  }
 }
 
 
 
-template <typename T,
-	  typename Block>
+/// Save a view to a file
+///
+/// Requires:
+///   FILENAME to be filename.
+///   VIEW to be a VSIPL++ view.
+
+template <typename ViewT>
 void
 save_view(
-   char*                        filename,
-   vsip::const_Matrix<T, Block> view)
+   char const* filename,
+   ViewT       view)
 {
-   Save_view<2, T>::save(filename, view);
-}
+  if (subblock(view) != vsip::no_subblock)
+  {
+    FILE*  fd;
+    
+    if (!(fd = fopen(filename, "w")))
+    {
+      fprintf(stderr, "save_view: error opening '%s'.\n", filename);
+      exit(1);
+    }
 
+    save_view(fd, view);
 
-
-template <typename T,
-	  typename Block>
-void
-save_view(
-   char*                        filename,
-   vsip::const_Tensor<T, Block> view)
-{
-   Save_view<3, T>::save(filename, view);
+    fclose(fd);
+  }
 }
 
 } // namespace vsip_csl
Index: tests/test_common.hpp
===================================================================
--- tests/test_common.hpp	(revision 152397)
+++ tests/test_common.hpp	(working copy)
@@ -71,6 +71,19 @@
 
 
 
+template <typename T>
+inline T
+value(
+  vsip::index_type idx0,
+  vsip::index_type idx1,
+  vsip::index_type idx2,
+  int              k)
+{
+  return T(k*(10000*idx0 + 100*idx1 + idx2));
+}
+
+
+
 template <typename T,
 	  typename BlockT>
 void
@@ -118,6 +131,31 @@
 template <typename T,
 	  typename BlockT>
 void
+setup(vsip::Tensor<T, BlockT> view, int k)
+{
+  using vsip::no_subblock;
+  using vsip::index_type;
+  typedef T value_type;
+
+  if (subblock(view) != no_subblock)
+  {
+    for (index_type l0=0; l0<view.local().size(0); ++l0)
+      for (index_type l1=0; l1<view.local().size(1); ++l1)
+	for (index_type l2=0; l2<view.local().size(2); ++l2)
+	{
+	  index_type g0 = global_from_local_index(view, 0, l0); 
+	  index_type g1 = global_from_local_index(view, 1, l1); 
+	  index_type g2 = global_from_local_index(view, 2, l2); 
+	  view.local().put(l0, l1, l2, value<T>(g0, g1, g2, k));
+	}
+  }
+}
+
+
+
+template <typename T,
+	  typename BlockT>
+void
 check(vsip::const_Vector<T, BlockT> vec, int k, int shift=0)
 {
   using vsip::no_subblock;
@@ -189,6 +227,55 @@
 template <typename T,
 	  typename BlockT>
 void
+check(
+  vsip::const_Tensor<T, BlockT> view,
+  int                           k,
+  int                           shift0=0,
+  int                           shift1=0,
+  int                           shift2=0)
+{
+  using vsip::no_subblock;
+  using vsip::index_type;
+  typedef T value_type;
+
+#if VERBOSE
+  std::cout << "check(k=" << k
+	    << ", shift0=" << shift0
+	    << ", shift1=" << shift1
+	    << ", shift2=" << shift2 << "):"
+	    << std::endl;
+#endif
+  if (subblock(view) != no_subblock)
+  {
+    for (index_type l0=0; l0<view.local().size(0); ++l0)
+      for (index_type l1=0; l1<view.local().size(1); ++l1)
+	for (index_type l2=0; l2<view.local().size(2); ++l2)
+        {
+	  index_type g0 = global_from_local_index(view, 0, l0); 
+	  index_type g1 = global_from_local_index(view, 1, l1); 
+	  index_type g2 = global_from_local_index(view, 2, l2); 
+#if VERBOSE
+	  std::cout << " - "
+		    << l0 << ", " << l1 << ", " << l2 << "  g:"
+		    << g0 << ", " << g1 << ", " << g2 << " = "
+		    << view.local().get(l0, l1, l2)
+		    << "  exp: " << value<T>(g0+shift0, g1 + shift1,
+					     g2+shift2, k)
+		    << std::endl;
+#endif
+#if DO_ASSERT
+	test_assert(view.local().get(l0, l1, l2) ==
+		    value<T>(g0+shift0, g1+shift1, g2+shift2, k));
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
 check_row_vector(vsip::const_Vector<T, BlockT> view, int row, int k=1)
 {
   using vsip::no_subblock;
Index: tests/threshold.cpp
===================================================================
--- tests/threshold.cpp	(revision 152479)
+++ tests/threshold.cpp	(working copy)
@@ -20,6 +20,7 @@
 
 using namespace std;
 using namespace vsip;
+using vsip_csl::equal;
 
 
 /***********************************************************************
@@ -37,17 +38,15 @@
   Rand<T> r(0);
 
   Vector<T> A(size);
-  T         b;
+  T         b = T(0.5);
   Vector<T> C1(size);
   Vector<T> C2(size);
   Vector<T> C3(size);
   Vector<T> C4(size);
 
   A = r.randu(size);
-  b = T(0.5);
+  A.put(0, b); // force boundary condition.
 
-  A.put(0, b);
-
   C1 = ite(A >= b, A,    T(0));
   C2 = ite(A <  b, T(0), A);
   C3 = ite(b <= A, A,    T(0));
@@ -55,20 +54,10 @@
 
   for (index_type i=0; i<size; ++i)
   {
-    if (A.get(i) >= b)
-    {
-      test_assert(C1.get(i) == A.get(i));
-      test_assert(C2.get(i) == A.get(i));
-      test_assert(C3.get(i) == A.get(i));
-      test_assert(C4.get(i) == A.get(i));
-    }
-    else
-    {
-      test_assert(C1.get(i) == T(0));
-      test_assert(C2.get(i) == T(0));
-      test_assert(C3.get(i) == T(0));
-      test_assert(C4.get(i) == T(0));
-    }
+    test_assert(equal(C1.get(i), A.get(i) >= b ? A.get(i) : T(0)));
+    test_assert(equal(C2.get(i), A.get(i) >= b ? A.get(i) : T(0)));
+    test_assert(equal(C3.get(i), A.get(i) >= b ? A.get(i) : T(0)));
+    test_assert(equal(C4.get(i), A.get(i) >= b ? A.get(i) : T(0)));
   }
 }
 
@@ -85,13 +74,14 @@
   Rand<T> r(0);
 
   Vector<T> A(size);
-  T         b;
+  T         b = T(0.5);
   Vector<T> C1(size);
   Vector<T> C2(size);
   Vector<T> C3(size);
   Vector<T> C4(size);
 
   A = r.randu(size);
+  A.put(0, b); // force boundary condition.
 
   C1 = ite(A >= b, A, b);
   C2 = ite(A <  b, b, A);
@@ -100,25 +90,68 @@
 
   for (index_type i=0; i<size; ++i)
   {
-    if (A.get(i) >= b)
-    {
-      test_assert(C1.get(i) == A.get(i));
-      test_assert(C2.get(i) == A.get(i));
-      test_assert(C3.get(i) == A.get(i));
-      test_assert(C4.get(i) == A.get(i));
-    }
-    else
-    {
-      test_assert(C1.get(i) == b);
-      test_assert(C2.get(i) == b);
-      test_assert(C3.get(i) == b);
-      test_assert(C4.get(i) == b);
-    }
+    test_assert(equal(C1.get(i), A.get(i) >= b ? A.get(i) : b));
+    test_assert(equal(C2.get(i), A.get(i) >= b ? A.get(i) : b));
+    test_assert(equal(C3.get(i), A.get(i) >= b ? A.get(i) : b));
+    test_assert(equal(C4.get(i), A.get(i) >= b ? A.get(i) : b));
   }
 }
 
 
 
+// Test C = ite(A OP B, T(1), T(0)) threshold
+//
+// This variations are dispatched to SAL lv{eq,ne,gt,ge,lt,le}x
+
+#define TEST_LVOP(NAME, OP)						\
+template <typename T>							\
+void									\
+test_l ## NAME (length_type size)					\
+{									\
+  Rand<T> r(0);								\
+									\
+  Vector<T> A(size);							\
+  Vector<T> B(size);							\
+  Vector<T> C(size);							\
+									\
+  A = r.randu(size);							\
+  B = r.randu(size);							\
+									\
+  A.put(0, B.get(0));							\
+									\
+  C = ite(A OP B, T(1), T(0));						\
+									\
+  for (index_type i=0; i<size; ++i)					\
+  {									\
+    test_assert(equal(C.get(i), (A.get(i) OP B.get(i) ? T(1) : T(0))));	\
+  }									\
+}
+
+TEST_LVOP(veq, ==)
+TEST_LVOP(vne, !=)
+TEST_LVOP(vgt, >)
+TEST_LVOP(vge, >=)
+TEST_LVOP(vlt, >)
+TEST_LVOP(vle, >=)
+
+
+
+template <typename T>
+void
+test_type(length_type size)
+{
+  test_ge_threshold_0<T>(size);
+  test_ge_threshold_b<T>(size);
+
+  test_lveq<T>(size);
+  test_lvne<T>(size);
+  test_lvge<T>(size);
+  test_lvgt<T>(size);
+  test_lvle<T>(size);
+  test_lvlt<T>(size);
+}
+
+
 /***********************************************************************
   Main
 ***********************************************************************/
@@ -128,11 +161,10 @@
 {
   vsipl init(argc, argv);
 
-  test_ge_threshold_0<float>(16);
-  test_ge_threshold_0<float>(17);
+  test_type<float>(16);
+  test_type<float>(17);
+  test_type<double>(19);
+  test_type<int>(21);
 
-  test_ge_threshold_b<float>(16);
-  test_ge_threshold_b<float>(17);
-
   return 0;
 }
Index: tests/vsip_csl/load_view.cpp
===================================================================
--- tests/vsip_csl/load_view.cpp	(revision 0)
+++ tests/vsip_csl/load_view.cpp	(revision 0)
@@ -0,0 +1,178 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    tests/vsip_csl/load_view.hpp
+    @author  Jules Bergmann
+    @date    2006-09-28
+    @brief   VSIPL++ Library: Unit-tests for vsip_csl/load_view.hpp
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <unistd.h>
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include <vsip_csl/load_view.hpp>
+#include <vsip_csl/save_view.hpp>
+
+#include "test_common.hpp"
+#include "util.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Test a round-trip through a file:
+//  - create data in view
+//  - save to disk using 'save_view'
+//  - load from disk using 'Load_view'
+//  - check result.
+
+template <typename       T,
+	  typename       OrderT,
+	  dimension_type Dim,
+	  typename       SaveMapT,
+	  typename       LoadMapT>
+void
+test_ls(
+  Domain<Dim> const& dom,
+  SaveMapT const&    save_map,
+  LoadMapT const&    load_map,
+  int                k,
+  bool               do_barrier = false)
+{
+  using vsip::impl::View_of_dim;
+
+  char const* filename = "test.load_view.tmpfile";
+
+  typedef Dense<Dim, T, OrderT, SaveMapT>                     save_block_type;
+  typedef typename View_of_dim<Dim, T, save_block_type>::type save_view_type;
+
+  typedef Dense<Dim, T, OrderT, LoadMapT>                     load_block_type;
+  typedef typename View_of_dim<Dim, T, load_block_type>::type load_view_type;
+
+  save_view_type s_view(create_view<save_view_type>(dom, save_map));
+
+  setup(s_view, k);
+
+  // Because the same file is shared for all tests, Wait for any
+  // processors still doing an earlier test.
+  if (do_barrier) impl::default_communicator().barrier();
+
+  save_view(filename, s_view);
+
+  // Wait for all writers to complete before starting to read.
+  if (do_barrier) impl::default_communicator().barrier();
+
+  // Test load_view function.
+  load_view_type l_view(create_view<load_view_type>(dom, load_map));
+  load_view(filename, l_view);
+  check(l_view, k);
+
+  // Test Load_view class.
+  Load_view<Dim, T, OrderT, LoadMapT> l_view_obj(filename, dom, load_map);
+  check(l_view_obj.view(), k);
+}
+
+
+
+template <typename T>
+void
+test_type()
+{
+  Local_map l_map;
+
+  Map<> map_0(1, 1);				// Root map
+  Map<> map_r(vsip::num_processors(), 1);
+  Map<> map_c(1, vsip::num_processors());
+
+  // Local_map tests
+  if (vsip::local_processor() == 0)
+  {
+    test_ls<T, row1_type>      (Domain<1>(16),      l_map, l_map, 1, false);
+
+    test_ls<T, row2_type>      (Domain<2>(7, 5),    l_map, l_map, 1, false);
+    test_ls<T, col2_type>      (Domain<2>(4, 7),    l_map, l_map, 1, false);
+
+    test_ls<T, row3_type>      (Domain<3>(5, 3, 6), l_map, l_map, 1, false);
+    test_ls<T, col3_type>      (Domain<3>(4, 7, 3), l_map, l_map, 1, false);
+    test_ls<T, tuple<0, 2, 1> >(Domain<3>(5, 3, 6), l_map, l_map, 1, false);
+  }
+
+  // Because the same file name is used for all invocations of test_ls,
+  // it is possible that processors other than 0 can race ahead and
+  // corrupt the file being used by processor 0.  To avoid this, we
+  // use a barrier here.
+  impl::default_communicator().barrier();
+
+  // 1D tests
+  test_ls<T, row1_type>      (Domain<1>(16),      map_0, map_0, 1, true);
+  test_ls<T, row2_type>      (Domain<2>(7, 5),    map_0, map_0, 1, true);
+  test_ls<T, col2_type>      (Domain<2>(4, 7),    map_0, map_0, 1, true);
+  test_ls<T, row3_type>      (Domain<3>(5, 3, 6), map_0, map_0, 1, true);
+  test_ls<T, tuple<1, 0, 2> >(Domain<3>(4, 7, 3), map_0, map_0, 1, true);
+  test_ls<T, tuple<0, 2, 1> >(Domain<3>(5, 3, 6), map_0, map_0, 1, true);
+
+
+  // 1D tests
+  test_ls<T, row1_type>      (Domain<1>(16),      map_0, map_r, 1, true);
+
+  // 2D tests
+  test_ls<T, row2_type>      (Domain<2>(7, 5),    map_0, map_r, 1, true);
+  test_ls<T, col2_type>      (Domain<2>(4, 7),    map_0, map_c, 1, true);
+
+  // 3D tests
+  test_ls<T, row3_type>      (Domain<3>(5, 3, 6), map_0, map_r, 1, true);
+  test_ls<T, tuple<1, 0, 2> >(Domain<3>(4, 7, 3), map_0, map_c, 1, true);
+  test_ls<T, tuple<0, 2, 1> >(Domain<3>(5, 3, 6), map_0, map_r, 1, true);
+
+  // As above, prevent processors from going on to the next set of
+  // local tests before all the others are done reading.
+  impl::default_communicator().barrier();
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
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
+  test_type<int>();
+  test_type<float>();
+  test_type<double>();
+  test_type<complex<float> >();
+}
+
+
Index: tests/extdata-fft.cpp
===================================================================
--- tests/extdata-fft.cpp	(revision 152397)
+++ tests/extdata-fft.cpp	(working copy)
@@ -18,7 +18,7 @@
 #include <vsip/support.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/vector.hpp>
-#include <vsip/opt/fast_block.hpp>
+#include <vsip/core/fast_block.hpp>
 
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/plainblock.hpp>
Index: tests/elementwise.cpp
===================================================================
--- tests/elementwise.cpp	(revision 152397)
+++ tests/elementwise.cpp	(working copy)
@@ -21,7 +21,7 @@
 #include <vsip/initfin.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/math.hpp>
-#include <vsip/opt/fast_block.hpp>
+#include <vsip/core/fast_block.hpp>
 #include <vsip/core/subblock.hpp>
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/output.hpp>
@@ -342,8 +342,7 @@
 
 
 
-
-
+int
 main(int argc, char** argv)
 {
   vsip::vsipl init(argc, argv);
Index: tests/fast-block.cpp
===================================================================
--- tests/fast-block.cpp	(revision 152397)
+++ tests/fast-block.cpp	(working copy)
@@ -13,7 +13,7 @@
 #include <iostream>
 #include <cassert>
 #include <vsip/support.hpp>
-#include <vsip/opt/fast_block.hpp>
+#include <vsip/core/fast_block.hpp>
 #include <vsip/core/length.hpp>
 #include <vsip/core/domain_utils.hpp>
 #include <vsip_csl/test.hpp>
