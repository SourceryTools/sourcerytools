Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.492
diff -u -r1.492 ChangeLog
--- ChangeLog	2 Jun 2006 02:21:50 -0000	1.492
+++ ChangeLog	5 Jun 2006 21:36:08 -0000
@@ -1,3 +1,12 @@
+2006-06-05  Jules Bergmann  <jules@codesourcery.com>
+
+	* benchmarks/vmul_sal.cpp: Add benchmark case for SAL
+	  complex svmul (calls cvcsmlx and zvzsmlx).
+	* src/vsip/impl/coverage.hpp: Fix broken ifdef.
+	* src/vsip/impl/sal/eval_elementwise.hpp: Add evaluators for
+	  bop2(A, bop1(B, C)) that map to bop2(bop1(B, C), A).  Fixes
+	  issue #117.
+	
 2006-06-01  Jules Bergmann  <jules@codesourcery.com>
 
 	* benchmarks/conv.cpp: Add complex cases.
Index: benchmarks/vmul_sal.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/vmul_sal.cpp,v
retrieving revision 1.3
diff -u -r1.3 vmul_sal.cpp
--- benchmarks/vmul_sal.cpp	2 Jun 2006 02:21:50 -0000	1.3
+++ benchmarks/vmul_sal.cpp	5 Jun 2006 21:36:08 -0000
@@ -296,6 +296,11 @@
 };
 
 
+
+/***********************************************************************
+  Definitions - scalar-vector element-wise multiply
+***********************************************************************/
+
 template <typename ScalarT,
 	  typename T,
 	  typename ComplexFmt = Cmplx_inter_fmt>
@@ -351,6 +356,113 @@
 
 
 
+template <>
+struct t_svmul_sal<complex<float>, complex<float>, Cmplx_inter_fmt>
+{
+  typedef float T;
+
+  char* what() { return "t_svmul_sal"; }
+  int ops_per_point(size_t)  { return Ops_info<float>::mul; }
+  int riob_per_point(size_t) { return 2*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 3*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   A(size, T());
+    Vector<T, block_type>   B(1, T());
+    Vector<T, block_type>   C(size);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size); A(0) = T(3);
+    B(0) = T(4);
+
+    vsip::impl::profile::Timer t1;
+
+    {
+    impl::Ext_data<block_type> ext_a(A.block(), impl::SYNC_IN);
+    impl::Ext_data<block_type> ext_b(B.block(), impl::SYNC_IN);
+    impl::Ext_data<block_type> ext_c(C.block(), impl::SYNC_OUT);
+    
+    T* pA = ext_a.data();
+    T* pB = ext_b.data();
+    T* pC = ext_c.data();
+    
+    t1.start();
+    for (size_t l=0; l<loop; ++l)
+      cvcsmlx((COMPLEX*)pA, 2,
+	      (COMPLEX*)pB,
+	      (COMPLEX*)pC, 2,
+	      size, 0 );
+    t1.stop();
+    }
+
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(0)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+template <>
+struct t_svmul_sal<complex<float>, complex<float>, Cmplx_split_fmt>
+{
+  typedef float T;
+
+  char* what() { return "t_svmul_sal"; }
+  int ops_per_point(size_t)  { return Ops_info<float>::mul; }
+  int riob_per_point(size_t) { return 2*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 3*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_split_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+    typedef impl::Ext_data<block_type>::raw_ptr_type ptr_type;
+
+    Vector<T, block_type>   A(size, T());
+    Vector<T, block_type>   B(1, T());
+    Vector<T, block_type>   C(size);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size); A(0) = T(3);
+    B(0) = T(4);
+
+    vsip::impl::profile::Timer t1;
+
+    {
+    impl::Ext_data<block_type> ext_a(A.block(), impl::SYNC_IN);
+    impl::Ext_data<block_type> ext_b(B.block(), impl::SYNC_IN);
+    impl::Ext_data<block_type> ext_c(C.block(), impl::SYNC_OUT);
+    
+    ptr_type pA = ext_a.data();
+    ptr_type pB = ext_b.data();
+    ptr_type pC = ext_c.data();
+    
+    t1.start();
+    for (size_t l=0; l<loop; ++l)
+      zvzsmlx((COMPLEX_SPLIT*)&pA, 2,
+	      (COMPLEX_SPLIT*)&pB,
+	      (COMPLEX_SPLIT*)&pC, 2,
+	      size, 0 );
+    t1.stop();
+    }
+
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(0)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
 void
 defaults(Loop1P&)
 {
@@ -361,6 +473,7 @@
 void
 test(Loop1P& loop, int what)
 {
+  typedef complex<float> cf_type;
   switch (what)
   {
   case  1: loop(t_vmul_sal<float>()); break;
@@ -368,6 +481,8 @@
   case  3: loop(t_vmul_sal<complex<float>, Cmplx_split_fmt>()); break;
 
   case 11: loop(t_svmul_sal<float, float>()); break;
+  case 13: loop(t_svmul_sal<cf_type, cf_type, Cmplx_inter_fmt>()); break;
+  case 14: loop(t_svmul_sal<cf_type, cf_type, Cmplx_split_fmt>()); break;
 
   case 32: loop(t_vmul_sal_ip<1, complex<float> >()); break;
   case 33: loop(t_vmul_sal_ip<2, complex<float> >()); break;
Index: src/vsip/impl/coverage.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/coverage.hpp,v
retrieving revision 1.1
diff -u -r1.1 coverage.hpp
--- src/vsip/impl/coverage.hpp	2 Jun 2006 02:21:50 -0000	1.1
+++ src/vsip/impl/coverage.hpp	5 Jun 2006 21:36:08 -0000
@@ -38,7 +38,7 @@
 #  define VSIP_IMPL_COVER_FCN(TYPE, FCN)
 #endif
 
-#if VSIP_IMPL_COVERAGE
+#if VSIP_IMPL_DO_COVERAGE
 #  define VSIP_IMPL_COVER_BLK(TYPE, BLK)				\
      std::cout << "BLK," << TYPE << "," << typeid(BLK).name() << std::endl;
 #else
Index: src/vsip/impl/sal/eval_elementwise.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/eval_elementwise.hpp,v
retrieving revision 1.1
diff -u -r1.1 eval_elementwise.hpp
--- src/vsip/impl/sal/eval_elementwise.hpp	2 Jun 2006 02:21:51 -0000	1.1
+++ src/vsip/impl/sal/eval_elementwise.hpp	5 Jun 2006 21:36:08 -0000
@@ -797,11 +797,85 @@
   }									\
 };
 
+// Nested binary expressions, V_VV
+
+#define VSIP_IMPL_SAL_V_VV_EXPR(OP, OP1, OP2, FUN)			\
+template <typename DstBlock,						\
+	  typename Block1,						\
+	  typename Type1,						\
+	  typename Block2,						\
+	  typename Type2,						\
+	  typename Block3,						\
+	  typename Type3,						\
+	  typename TypeB>						\
+struct Serial_expr_evaluator<						\
+         1, DstBlock, 							\
+         Binary_expr_block<						\
+                 1, OP2,						\
+                 Block1, Type1,						\
+                 Binary_expr_block<					\
+                         1, OP1,					\
+                         Block2, Type2,					\
+                         Block3, Type3> const, TypeB> const,		\
+         Mercury_sal_tag>						\
+{									\
+  typedef Binary_expr_block<						\
+                 1, OP2,						\
+                 Block1, Type1,						\
+                 Binary_expr_block<					\
+                         1, OP1,					\
+                         Block2, Type2,					\
+                         Block3, Type3> const, TypeB>			\
+	SrcBlock;							\
+									\
+  typedef typename DstBlock::value_type dst_type;			\
+									\
+  typedef typename sal::Effective_value_type<DstBlock>::type eff_dst_t;	\
+  typedef typename sal::Effective_value_type<Block1, Type1>::type eff_1_t;\
+  typedef typename sal::Effective_value_type<Block2, Type2>::type eff_2_t;\
+  typedef typename sal::Effective_value_type<Block3, Type3>::type eff_3_t;\
+									\
+  static bool const ct_valid = 						\
+    (!Is_expr_block<Block1>::value || Is_scalar_block<Block1>::value) &&\
+    (!Is_expr_block<Block2>::value || Is_scalar_block<Block2>::value) &&\
+    (!Is_expr_block<Block3>::value || Is_scalar_block<Block3>::value) &&\
+     sal::Is_op3_supported<OP, eff_1_t, eff_2_t, eff_3_t, eff_dst_t>::value&&\
+     /* check that direct access is supported */			\
+     Ext_data_cost<DstBlock>::value == 0 &&				\
+     (Ext_data_cost<Block1>::value == 0 || Is_scalar_block<Block1>::value) &&\
+     (Ext_data_cost<Block2>::value == 0 || Is_scalar_block<Block2>::value) &&\
+     (Ext_data_cost<Block3>::value == 0 || Is_scalar_block<Block3>::value);\
+									\
+  static bool rt_valid(DstBlock&, SrcBlock const&)			\
+  {									\
+    /* SAL supports all strides */					\
+    return true;							\
+  }									\
+									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    sal::Ext_wrapper<DstBlock> ext_dst(dst,               SYNC_OUT);	\
+    sal::Ext_wrapper<Block1>   ext_1(src.left(),          SYNC_IN);	\
+    sal::Ext_wrapper<Block2>   ext_2(src.right().left(),  SYNC_IN);	\
+    sal::Ext_wrapper<Block3>   ext_3(src.right().right(), SYNC_IN);	\
+    FUN(typename sal::Ext_wrapper<Block2>::sal_type(ext_2),		\
+        typename sal::Ext_wrapper<Block3>::sal_type(ext_3),		\
+        typename sal::Ext_wrapper<Block1>::sal_type(ext_1),		\
+	typename sal::Ext_wrapper<DstBlock>::sal_type(ext_dst),		\
+	dst.size());							\
+  }									\
+};
+
 VSIP_IMPL_SAL_VV_V_EXPR(ma_functor,  op::Mult, op::Add,  sal::vma)
 VSIP_IMPL_SAL_VV_V_EXPR(msb_functor, op::Mult, op::Sub,  sal::vmsb)
 VSIP_IMPL_SAL_VV_V_EXPR(am_functor,  op::Add,  op::Mult, sal::vam)
 VSIP_IMPL_SAL_VV_V_EXPR(sbm_functor, op::Sub,  op::Mult, sal::vsbm)
 
+VSIP_IMPL_SAL_V_VV_EXPR(ma_functor,  op::Mult, op::Add,  sal::vma)
+VSIP_IMPL_SAL_V_VV_EXPR(msb_functor, op::Mult, op::Sub,  sal::vmsb)
+VSIP_IMPL_SAL_V_VV_EXPR(am_functor,  op::Add,  op::Mult, sal::vam)
+VSIP_IMPL_SAL_V_VV_EXPR(sbm_functor, op::Sub,  op::Mult, sal::vsbm)
+
 
 
 // Nested binary expressions, f(V)V_V
