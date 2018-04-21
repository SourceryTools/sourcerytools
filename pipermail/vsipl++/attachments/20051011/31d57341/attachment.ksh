Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.290
diff -c -p -r1.290 ChangeLog
*** ChangeLog	10 Oct 2005 06:33:40 -0000	1.290
--- ChangeLog	11 Oct 2005 19:18:41 -0000
***************
*** 1,3 ****
--- 1,35 ----
+ 2005-10-11 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	Implement General_dispatch (similar to Serial_expr_dispatch),
+ 	Use for dot- and matrix-matrix products.
+ 	* configure.ac (VSIP_IMPL_HAVE_BLAS, VSIPL_IMPL_HAVE_LAPACK):
+ 	  Define if if BLAS/LAPACK libraries present.
+ 	* src/vsip/impl/eval-blas.hpp: New file, BLAS evaluators for
+ 	  dot-product and matrix-matrix product.
+ 	* src/vsip/impl/general_dispatch.hpp: New file, generalized
+ 	  dispatch of functions to various implementations.
+ 	* src/vsip/impl/lapack.hpp: Add dot-product and matrix-matrix
+ 	  product functions.  Mover error handler xerbla_ into lapack.cpp
+ 	* src/vsip/impl/matvec.hpp: Use general dispatch for dot products.
+ 	  Provide default generic evaluator.
+ 	* src/vsip/impl/matvec-prod.hpp: Use general dispatch for
+ 	  matrix-matrix products.  Provide default generic evaluator.
+ 	* src/vsip/impl/signal-conv-common.hpp (Generic_tag, Opt_tag: Change 
+ 	  to forward decls.
+ 	* src/vsip/lapack.cpp: New file, contains xerbla_.
+ 	* tests/matvec-dot.cpp: New file, tests for dot() and cvjdot().
+ 	* tests/matvec-prod.cpp: Extend to cover different dimension-orders.
+ 	  (row-major and col-major).  Move reference routines to ref_matvec.
+ 	* tests/ref_matvec.hpp: New file, reference matvec routines.
+ 	* tests/test-random.hpp (randv): New function, fill a vector
+ 	  with random values.
+ 	* tests/extdata-output.hpp: Optionally use typeid, handle const
+ 	  types, provide more details for Dense, and handle Unary_expr_block
+ 	  type.
+ 
+ 	* benchmarks/dot.cpp: New file, benchmark for dot product.
+ 	* benchmarks/prod.cpp: New file, benchmark for matrix-matrix products.
+ 
  2005-10-09  Nathan Myers  <ncm@codesourcery.com>
  
  	* src/vsip/impl/signal-fir.hpp: support Fir<>::impl_performance()
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.41
diff -c -p -r1.41 configure.ac
*** configure.ac	27 Sep 2005 21:30:16 -0000	1.41
--- configure.ac	11 Oct 2005 19:18:41 -0000
*************** if test "$enable_lapack" != "no"; then
*** 610,615 ****
--- 610,619 ----
      LIBS=$keep_LIBS
    else
      AC_MSG_RESULT([Using $lapack_found for LAPACK])
+     AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_BLAS, 1,
+       [Define to set whether or not BLAS is present.])
+     AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_LAPACK, 1,
+       [Define to set whether or not LAPACK is present.])
      AC_DEFINE_UNQUOTED(VSIP_IMPL_USE_LAPACK_ILAENV, $lapack_use_ilaenv,
        [Use LAPACK ILAENV (0 == do not use, 1 = use).])
    fi
Index: benchmarks/dot.cpp
===================================================================
RCS file: benchmarks/dot.cpp
diff -N benchmarks/dot.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/dot.cpp	11 Oct 2005 19:18:41 -0000
***************
*** 0 ****
--- 1,162 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    benchmarks/dot.cpp
+     @author  Jules Bergmann
+     @date    2005-10-11
+     @brief   VSIPL++ Library: Benchmark for dot-produtcs.
+ 
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <iostream>
+ 
+ #include <vsip/initfin.hpp>
+ #include <vsip/support.hpp>
+ #include <vsip/math.hpp>
+ #include <vsip/signal.hpp>
+ 
+ #include <vsip/impl/profile.hpp>
+ 
+ #include "test.hpp"
+ #include "loop.hpp"
+ #include "ops_info.hpp"
+ 
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   Definition
+ ***********************************************************************/
+ 
+ // Dot-product benchmark class.
+ 
+ template <typename T>
+ struct t_dot1
+ {
+   static length_type const Dec = 1;
+ 
+   char* what() { return "t_dot1"; }
+   float ops_per_point(length_type)
+   {
+     float ops = (Ops_info<T>::mul + Ops_info<T>::add);
+ 
+     return ops;
+   }
+ 
+   int riob_per_point(length_type) { return 2*sizeof(T); }
+   int wiob_per_point(length_type) { return 0; }
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+     Vector<T>   A (size, T());
+     Vector<T>   B (size, T());
+     T r;
+ 
+     A(0) = T(3);
+     B(0) = T(4);
+ 
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       r = dot(A, B);
+     t1.stop();
+ 
+     if (r != T(3)*T(4))
+       abort();
+     
+     time = t1.delta();
+   }
+ 
+   t_dot1() {}
+ };
+ 
+ 
+ 
+ // Dot-product benchmark class with particular ImplTag.
+ 
+ template <typename ImplTag,
+ 	  typename T>
+ struct t_dot2
+ {
+   static length_type const Dec = 1;
+ 
+   char* what() { return "t_dot2"; }
+   float ops_per_point(length_type)
+   {
+     float ops = (Ops_info<T>::mul + Ops_info<T>::add);
+ 
+     return ops;
+   }
+ 
+   int riob_per_point(length_type) { return 2*sizeof(T); }
+   int wiob_per_point(length_type) { return 0; }
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+     Vector<T>   A (size, T());
+     Vector<T>   B (size, T());
+     T r;
+ 
+     A(0) = T(3);
+     B(0) = T(4);
+ 
+     typedef typename Vector<T>::block_type block_type;
+ 
+     typedef impl::Evaluator<impl::Op_prod_vv, impl::Return_scalar<T>,
+                             impl::Op_list_2<block_type, block_type>, ImplTag>
+ 		Eval;
+ 
+     assert(Eval::ct_valid);
+   
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       r = Eval::exec(A.block(), B.block());
+     t1.stop();
+ 
+     if (r != T(3)*T(4))
+       abort();
+     
+     time = t1.delta();
+   }
+ 
+   t_dot2() {}
+ };
+ 
+ 
+ 
+ void
+ defaults(Loop1P& loop)
+ {
+   loop.loop_start_ = 5000;
+   loop.start_ = 4;
+ }
+ 
+ 
+ 
+ int
+ test(Loop1P& loop, int what)
+ {
+   switch (what)
+   {
+   case  1: loop(t_dot1<float>()); break;
+   case  2: loop(t_dot1<complex<float> >()); break;
+ 
+   case  3: loop(t_dot2<impl::Generic_tag, float>()); break;
+   case  4: loop(t_dot2<impl::Generic_tag, complex<float> >()); break;
+ 
+ #if VSIP_IMPL_HAVE_BLAS
+   case  5: loop(t_dot2<impl::Blas_tag, float>()); break;
+   case  6: loop(t_dot2<impl::Blas_tag, complex<float> >()); break;
+ #endif
+ 
+   default: return 0;
+   }
+   return 1;
+ }
Index: benchmarks/prod.cpp
===================================================================
RCS file: benchmarks/prod.cpp
diff -N benchmarks/prod.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/prod.cpp	11 Oct 2005 19:18:41 -0000
***************
*** 0 ****
--- 1,259 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    benchmarks/prod.cpp
+     @author  Jules Bergmann
+     @date    2005-10-11
+     @brief   VSIPL++ Library: Benchmark for matrix-matrix produtcs.
+ 
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <iostream>
+ 
+ #include <vsip/initfin.hpp>
+ #include <vsip/support.hpp>
+ #include <vsip/math.hpp>
+ #include <vsip/signal.hpp>
+ 
+ #include <vsip/impl/profile.hpp>
+ 
+ #include "test.hpp"
+ #include "loop.hpp"
+ #include "ops_info.hpp"
+ 
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   Definition
+ ***********************************************************************/
+ 
+ // Matrix-matrix product benchmark class.
+ 
+ template <typename T>
+ struct t_prod1
+ {
+   static length_type const Dec = 1;
+ 
+   char* what() { return "t_prod1"; }
+   float ops_per_point(length_type M)
+   {
+     length_type N = M;
+     length_type P = M;
+ 
+     float ops = /*M * */ P * N * (Ops_info<T>::mul + Ops_info<T>::add);
+ 
+     return ops;
+   }
+ 
+   int riob_per_point(length_type) { return 2*sizeof(T); }
+   int wiob_per_point(length_type) { return 0; }
+ 
+   void operator()(length_type M, length_type loop, float& time)
+   {
+     length_type N = M;
+     length_type P = M;
+ 
+     Matrix<T>   A (M, N, T());
+     Matrix<T>   B (N, P, T());
+     Matrix<T>   Z (M, P, T());
+ 
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       Z = prod(A, B);
+     t1.stop();
+     
+     time = t1.delta();
+   }
+ 
+   t_prod1() {}
+ };
+ 
+ 
+ 
+ // Matrix-matrix product (with hermetian) benchmark class.
+ 
+ template <typename T>
+ struct t_prodh1
+ {
+   static length_type const Dec = 1;
+ 
+   char* what() { return "t_prodh1"; }
+   float ops_per_point(length_type M)
+   {
+     length_type N = M;
+     length_type P = M;
+ 
+     float ops = /*M * */ P * N * (Ops_info<T>::mul + Ops_info<T>::add);
+ 
+     return ops;
+   }
+ 
+   int riob_per_point(length_type) { return 2*sizeof(T); }
+   int wiob_per_point(length_type) { return 0; }
+ 
+   void operator()(length_type M, length_type loop, float& time)
+   {
+     length_type N = M;
+     length_type P = M;
+ 
+     Matrix<T>   A (M, N, T());
+     Matrix<T>   B (P, N, T());
+     Matrix<T>   Z (M, P, T());
+ 
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       Z = prodh(A, B);
+     t1.stop();
+     
+     time = t1.delta();
+   }
+ 
+   t_prodh1() {}
+ };
+ 
+ 
+ 
+ // Matrix-matrix product (with tranpose) benchmark class.
+ 
+ template <typename T>
+ struct t_prodt1
+ {
+   static length_type const Dec = 1;
+ 
+   char* what() { return "t_prodt1"; }
+   float ops_per_point(length_type M)
+   {
+     length_type N = M;
+     length_type P = M;
+ 
+     float ops = /*M * */ P * N * (Ops_info<T>::mul + Ops_info<T>::add);
+ 
+     return ops;
+   }
+ 
+   int riob_per_point(length_type) { return 2*sizeof(T); }
+   int wiob_per_point(length_type) { return 0; }
+ 
+   void operator()(length_type M, length_type loop, float& time)
+   {
+     length_type N = M;
+     length_type P = M;
+ 
+     Matrix<T>   A (M, N, T());
+     Matrix<T>   B (P, N, T());
+     Matrix<T>   Z (M, P, T());
+ 
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       Z = prodt(A, B);
+     t1.stop();
+     
+     time = t1.delta();
+   }
+ 
+   t_prodt1() {}
+ };
+ 
+ 
+ 
+ // Matrix-matrix product benchmark class with particular ImplTag.
+ 
+ template <typename ImplTag,
+ 	  typename T>
+ struct t_prod2
+ {
+   static length_type const Dec = 1;
+ 
+   char* what() { return "t_prod2"; }
+   float ops_per_point(length_type M)
+   {
+     length_type N = M;
+     length_type P = M;
+ 
+     float ops = /*M * */ P * N * (Ops_info<T>::mul + Ops_info<T>::add);
+ 
+     return ops;
+   }
+ 
+   int riob_per_point(length_type) { return 2*sizeof(T); }
+   int wiob_per_point(length_type) { return 0; }
+ 
+   void operator()(length_type M, length_type loop, float& time)
+   {
+     length_type N = M;
+     length_type P = M;
+ 
+     typedef Dense<2, T, row2_type> a_block_type;
+     typedef Dense<2, T, row2_type> b_block_type;
+     typedef Dense<2, T, row2_type> z_block_type;
+ 
+     Matrix<T, a_block_type>   A(M, N, T());
+     Matrix<T, b_block_type>   B(N, P, T());
+     Matrix<T, z_block_type>   Z(M, P, T());
+ 
+ 
+     typedef impl::Evaluator<impl::Op_prod_mm, z_block_type,
+                             impl::Op_list_2<a_block_type, a_block_type>,
+ 			    ImplTag>
+ 		Eval;
+ 
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       Eval::exec(Z.block(), A.block(), B.block());
+     t1.stop();
+     
+     time = t1.delta();
+   }
+ 
+   t_prod2() {}
+ };
+ 
+ 
+ 
+ void
+ defaults(Loop1P& loop)
+ {
+   loop.loop_start_ = 5000;
+   loop.start_ = 4;
+   loop.stop_  = 8;
+ }
+ 
+ 
+ 
+ int
+ test(Loop1P& loop, int what)
+ {
+   switch (what)
+   {
+   case  1: loop(t_prod1<float>()); break;
+   case  2: loop(t_prod1<complex<float> >()); break;
+ 
+   case  3: loop(t_prod2<impl::Generic_tag, float>()); break;
+   case  4: loop(t_prod2<impl::Generic_tag, complex<float> >()); break;
+ 
+ #if VSIP_IMPL_HAVE_BLAS
+   case  5: loop(t_prod2<impl::Blas_tag, float>()); break;
+   case  6: loop(t_prod2<impl::Blas_tag, complex<float> >()); break;
+ #endif
+ 
+   case  11: loop(t_prodt1<float>()); break;
+   case  12: loop(t_prodt1<complex<float> >()); break;
+   case  13: loop(t_prodh1<complex<float> >()); break;
+ 
+   default: return 0;
+   }
+   return 1;
+ }
Index: src/vsip/lapack.cpp
===================================================================
RCS file: src/vsip/lapack.cpp
diff -N src/vsip/lapack.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/lapack.cpp	11 Oct 2005 19:18:41 -0000
***************
*** 0 ****
--- 1,40 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/lapack.cpp
+     @author  Jules Bergmann
+     @date    2005-10-11
+     @brief   VSIPL++ Library: Lacpack interface
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/impl/lapack.hpp>
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ extern "C"
+ {
+ 
+ /// LAPACK error handler.  Called by LAPACK functions if illegal
+ /// argument is passed.
+ 
+ void
+ xerbla_(char* name, int* info)
+ {
+   char copy[8];
+   char msg[256];
+ 
+   strncpy(copy, name, 6);
+   copy[6] = 0;
+   sprintf(msg, "lapack -- illegal arg (name=%s  info=%d)", copy, *info);
+ 
+   VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));
+ }
+ 
+ } // extern "C"
Index: src/vsip/impl/eval-blas.hpp
===================================================================
RCS file: src/vsip/impl/eval-blas.hpp
diff -N src/vsip/impl/eval-blas.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/eval-blas.hpp	11 Oct 2005 19:18:41 -0000
***************
*** 0 ****
--- 1,220 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/eval-blas.hpp
+     @author  Jules Bergmann
+     @date    2005-10-11
+     @brief   VSIPL++ Library: BLAS evaluators (for use in general dispatch).
+ 
+ */
+ 
+ #ifndef VSIP_IMPL_EVAL_BLAS_HPP
+ #define VSIP_IMPL_EVAL_BLAS_HPP
+ 
+ #ifdef VSIP_IMPL_HAVE_BLAS
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/impl/general_dispatch.hpp>
+ #include <vsip/impl/lapack.hpp>
+ 
+ 
+ 
+ /***********************************************************************
+   Declarations
+ ***********************************************************************/
+ 
+ namespace vsip
+ {
+ 
+ namespace impl
+ {
+ 
+ // BLAS evaluator for vector-vector dot-product (non-conjugated).
+ 
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2>
+ struct Evaluator<Op_prod_vv, Return_scalar<T>, Op_list_2<Block1, Block2>,
+ 		 Blas_tag>
+ {
+   static bool const ct_valid = 
+     impl::blas::Blas_traits<T>::valid &&
+     Type_equal<T, typename Block1::value_type>::value &&
+     Type_equal<T, typename Block2::value_type>::value &&
+     // check that direct access is supported
+     Ext_data_cost<Block1>::value == 0 &&
+     Ext_data_cost<Block2>::value == 0;
+ 
+   static bool rt_valid(Block1 const&, Block2 const&) { return true; }
+ 
+   static T exec(Block1 const& a, Block2 const& b)
+   {
+     assert(a.size(1, 0) == b.size(1, 0));
+ 
+     Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+     Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+ 
+     T r = blas::dot(a.size(1, 0),
+ 		    ext_a.data(), ext_a.stride(0),
+ 		    ext_b.data(), ext_b.stride(0));
+ 
+     return r;
+   }
+ };
+ 
+ 
+ 
+ // BLAS evaluator for vector-vector dot-product (conjugated).
+ 
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2>
+ struct Evaluator<Op_prod_vv, Return_scalar<complex<T> >,
+ 		 Op_list_2<Block1, 
+ 			   Unary_expr_block<1, impl::conj_functor,
+ 					    Block2, complex<T> > const>,
+ 		 Blas_tag>
+ {
+   static bool const ct_valid = 
+     impl::blas::Blas_traits<complex<T> >::valid &&
+     Type_equal<complex<T>, typename Block1::value_type>::value &&
+     Type_equal<complex<T>, typename Block2::value_type>::value &&
+     // check that direct access is supported
+     Ext_data_cost<Block1>::value == 0 &&
+     Ext_data_cost<Block2>::value == 0;
+ 
+   static bool rt_valid(
+     Block1 const&, 
+     Unary_expr_block<1, impl::conj_functor, Block2, complex<T> > const&)
+   { return true; }
+ 
+   static complex<T> exec(
+     Block1 const& a, 
+     Unary_expr_block<1, impl::conj_functor, Block2, complex<T> > const& b)
+   {
+     assert(a.size(1, 0) == b.size(1, 0));
+ 
+     Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+     Ext_data<Block2> ext_b(const_cast<Block2&>(b.op()));
+ 
+     return blas::dotc(a.size(1, 0),
+ 		      ext_b.data(), ext_b.stride(0),
+ 		      ext_a.data(), ext_a.stride(0));
+     // Note:
+     //   BLAS    cdotc(x, y)  => conj(x) * y, while 
+     //   VSIPL++ cvjdot(x, y) => x * conj(y)
+   }
+ };
+ 
+ 
+ 
+ // BLAS evaluator for matrix-matrix products.
+ 
+ template <typename Block0,
+ 	  typename Block1,
+ 	  typename Block2>
+ struct Evaluator<Op_prod_mm, Block0, Op_list_2<Block1, Block2>,
+ 		 Blas_tag>
+ {
+   typedef typename Block0::value_type T;
+ 
+   static bool const ct_valid = 
+     impl::blas::Blas_traits<T>::valid &&
+     Type_equal<T, typename Block1::value_type>::value &&
+     Type_equal<T, typename Block2::value_type>::value &&
+     // check that direct access is supported
+     Ext_data_cost<Block0>::value == 0 &&
+     Ext_data_cost<Block1>::value == 0 &&
+     Ext_data_cost<Block2>::value == 0;
+ 
+   static bool rt_valid(Block0& r, Block1 const& a, Block2 const& b)
+   {
+     typedef typename Block_layout<Block0>::order_type order0_type;
+     typedef typename Block_layout<Block1>::order_type order1_type;
+     typedef typename Block_layout<Block2>::order_type order2_type;
+ 
+     Ext_data<Block0> ext_r(const_cast<Block0&>(r));
+     Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+     Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+ 
+     bool is_r_row = Type_equal<order0_type, row2_type>::value;
+     bool is_a_row = Type_equal<order1_type, row2_type>::value;
+     bool is_b_row = Type_equal<order2_type, row2_type>::value;
+ 
+     return is_r_row ? (ext_a.stride(is_a_row ? 1 : 0) == 1 &&
+ 		       ext_b.stride(is_b_row ? 1 : 0) == 1)
+                     : (ext_a.stride(is_a_row ? 0 : 1) == 1 &&
+ 		       ext_b.stride(is_b_row ? 0 : 1) == 1);
+   }
+ 
+   static void exec(Block0& r, Block1 const& a, Block2 const& b)
+   {
+     typedef typename Block0::value_type RT;
+ 
+     typedef typename Block_layout<Block0>::order_type order0_type;
+     typedef typename Block_layout<Block1>::order_type order1_type;
+     typedef typename Block_layout<Block2>::order_type order2_type;
+ 
+     Ext_data<Block0> ext_r(const_cast<Block0&>(r));
+     Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+     Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+ 
+     if (Type_equal<order0_type, row2_type>::value)
+     {
+       bool is_a_row = Type_equal<order1_type, row2_type>::value;
+       char transa   = is_a_row ? 'n' : 't';
+       int  lda      = is_a_row ? ext_a.stride(0) : ext_a.stride(1);
+ 
+       bool is_b_row = Type_equal<order2_type, row2_type>::value;
+       char transb   = is_b_row ? 'n' : 't';
+       int  ldb      = is_b_row ? ext_b.stride(0) : ext_b.stride(1);
+ 
+       // Use identity:
+       //   R = A B	<=>	trans(R) = trans(B) trans(A)
+       // to evaluate row-major matrix result with BLAS.
+ 
+       blas::gemm(transb, transa,
+ 		 b.size(2, 1),	// N
+ 		 a.size(2, 0),	// M
+ 		 a.size(2, 1),	// K
+ 		 1.0,		// alpha
+ 		 ext_b.data(), ldb,
+ 		 ext_a.data(), lda,
+ 		 0.0,		// beta
+ 		 ext_r.data(), ext_r.stride(0));
+     }
+     else if (Type_equal<order0_type, col2_type>::value)
+     {
+       bool is_a_col = Type_equal<order1_type, col2_type>::value;
+       char transa   = is_a_col ? 'n' : 't';
+       int  lda      = is_a_col ? ext_a.stride(1) : ext_a.stride(0);
+ 
+       bool is_b_col = Type_equal<order2_type, col2_type>::value;
+       char transb   = is_b_col ? 'n' : 't';
+       int  ldb      = is_b_col ? ext_b.stride(1) : ext_b.stride(0);
+ 
+       blas::gemm(transa, transb,
+ 		 a.size(2, 0),	// M
+ 		 b.size(2, 1),	// N
+ 		 a.size(2, 1),	// K
+ 		 1.0,		// alpha
+ 		 ext_a.data(), lda,
+ 		 ext_b.data(), ldb,
+ 		 0.0,		// beta
+ 		 ext_r.data(), ext_r.stride(1));
+     }
+     else assert(0);
+   }
+ };
+ 
+ 
+ 
+ } // namespace vsip::impl
+ 
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_HAVE_BLAS
+ 
+ #endif // VSIP_IMPL_EVAL_BLAS_HPP
Index: src/vsip/impl/general_dispatch.hpp
===================================================================
RCS file: src/vsip/impl/general_dispatch.hpp
diff -N src/vsip/impl/general_dispatch.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/general_dispatch.hpp	11 Oct 2005 19:18:41 -0000
***************
*** 0 ****
--- 1,230 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/general_dispatch.hpp
+     @author  Jules Bergmann
+     @date    2005-10-10
+     @brief   VSIPL++ Library: Dispatch harness that allows various
+              implementations to be bound to a particular operation.
+ */
+ 
+ #ifndef VSIP_IMPL_GENERAL_DISPATCH_HPP
+ #define VSIP_IMPL_GENERAL_DISPATCH_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/impl/config.hpp>
+ #include <vsip/impl/type_list.hpp>
+ 
+ 
+ 
+ /***********************************************************************
+   Declarations
+ ***********************************************************************/
+ 
+ namespace vsip
+ {
+ namespace impl
+ {
+ 
+ // Operation Tags.
+ //
+ // Each operation (dot-product, matrix-matrix product, etc) has a 
+ // unique operation tag.
+ 
+ struct Op_prod_vv;	// vector-vector dot-product
+ struct Op_prod_mm;	// matrix-matrix product
+ 
+ 
+ 
+ // Implementation Tags.
+ //
+ // Each implementation (generic, BLAS, IPP, etc) has a unique
+ // implementation tag.
+ 
+ struct Blas_tag;		// BLAS implementation (ATLAS, MKL, etc)
+ struct Intel_ipp_tag;		// Intel IPP library.
+ struct Generic_tag;		// Generic implementation.
+ 
+ 
+ 
+ // Wrapper class to describe scalar return-type.
+ 
+ template <typename T> struct Return_scalar {};
+ 
+ 
+ 
+ // Wrapper classes to capture list of operand types.
+ 
+ template <typename Block1>                  struct Op_list_1 {};
+ template <typename Block1, typename Block2> struct Op_list_2 {};
+ 
+ 
+ 
+ // General evaluator class.
+ 
+ template <typename OpTag,
+ 	  typename DstType,
+ 	  typename SrcType,
+ 	  typename ImplTag>
+ struct Evaluator
+ {
+   static bool const ct_valid = false;
+ };
+ 
+ 
+ 
+ template <typename OpTag>
+ struct Dispatch_order
+ {
+   typedef typename Make_type_list<Blas_tag, Generic_tag>::type type;
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   General_dispatch - primary definition and common specializations
+ ***********************************************************************/
+ 
+ /// Serial_dispatch_helper dispatches the evaluation of an expression along
+ /// a type list of potential backends.
+ /// Whether a given backend is actually used depends on its compile-time
+ /// and run-time validity checks.
+ template <typename OpTag,
+ 	  typename DstType,
+ 	  typename SrcType,
+ 	  typename TagList,
+ 	  typename Tag = typename TagList::first,
+ 	  typename Rest = typename TagList::rest,
+ 	  typename EvalExpr = Evaluator<OpTag, DstType, SrcType, Tag>,
+ 	  bool CtValid = EvalExpr::ct_valid>
+ struct General_dispatch;
+ 
+ 
+ 
+ /// In case the compile-time check fails, we continue the search
+ /// directly at the next entry in the type list.
+ template <typename OpTag,
+ 	  typename DstType,
+ 	  typename SrcType,
+ 	  typename TagList,
+ 	  typename Tag,
+ 	  typename Rest,
+ 	  typename EvalExpr>
+ struct General_dispatch<OpTag, DstType, SrcType, TagList, Tag, Rest, EvalExpr,
+ 			false>
+   : General_dispatch<OpTag, DstType, SrcType, Rest>
+ {};
+ 
+ 
+ 
+ /***********************************************************************
+   General_dispatch - 2-op scalar return specializations
+ ***********************************************************************/
+ 
+ /// In case the compile-time check passes, we decide at run-time whether
+ /// or not to use this backend.
+ template <typename OpTag,
+ 	  typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename TagList,
+ 	  typename Tag,
+ 	  typename Rest,
+ 	  typename EvalExpr>
+ struct General_dispatch<OpTag, Return_scalar<T>, Op_list_2<Block1, Block2>,
+ 			TagList, Tag, Rest, EvalExpr, true>
+ {
+   static T exec(Block1 const& op1, Block2 const& op2)
+   {
+     if (EvalExpr::rt_valid(op1, op2))
+       return EvalExpr::exec(op1, op2);
+     else
+       return General_dispatch<OpTag, Return_scalar<T>,
+ 			      Op_list_2<Block1, Block2>,
+ 			      Rest>::exec(op1, op2);
+   }
+ };
+ 
+ 
+ 
+ /// Terminator. Instead of passing on to the next element
+ /// it aborts the program. It is a program error to define
+ /// callback lists that can't handle a given expression.
+ template <typename OpTag,
+ 	  typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename TagList,
+ 	  typename Tag,
+ 	  typename EvalExpr>
+ struct General_dispatch<OpTag, Return_scalar<T>, Op_list_2<Block1, Block2>,
+ 			TagList, Tag, None_type, EvalExpr, true>
+ {
+   static T exec(Block1 const& op1, Block2 const& op2)
+   {
+     if (EvalExpr::rt_valid(op1, op2))
+       return EvalExpr::exec(op1, op2);
+     else
+       assert(0);
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   General_dispatch - 2-op block return specializations
+ ***********************************************************************/
+ 
+ /// In case the compile-time check passes, we decide at run-time whether
+ /// or not to use this backend.
+ template <typename OpTag,
+ 	  typename DstBlock,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename TagList,
+ 	  typename Tag,
+ 	  typename Rest,
+ 	  typename EvalExpr>
+ struct General_dispatch<OpTag, DstBlock, Op_list_2<Block1, Block2>,
+                        TagList, Tag, Rest, EvalExpr, true>
+ {
+   static void exec(DstBlock& res, Block1 const& op1, Block2 const& op2)
+   {
+     if (EvalExpr::rt_valid(res, op1, op2))
+       EvalExpr::exec(res, op1, op2);
+     else
+       General_dispatch<OpTag, DstBlock, Op_list_2<Block1, Block2>, Rest>
+ 		::exec(res, op1, op2);
+   }
+ };
+ 
+ 
+ 
+ /// Terminator. Instead of passing on to the next element
+ /// it aborts the program. It is a program error to define
+ /// callback lists that can't handle a given expression.
+ template <typename OpTag,
+ 	  typename DstBlock,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename TagList,
+ 	  typename Tag,
+ 	  typename EvalExpr>
+ struct General_dispatch<OpTag, DstBlock, Op_list_2<Block1, Block2>,
+ 			TagList, Tag, None_type, EvalExpr, true>
+ {
+   static void exec(DstBlock& res, Block1 const& op1, Block2 const& op2)
+   {
+     if (EvalExpr::rt_valid(res, op1, op2))
+       EvalExpr::exec(res, op1, op2);
+     else
+       assert(0);
+   }
+ };
+ 
+ } // namespace vsip::impl
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_GENERAL_DISPATCH_HPP
Index: src/vsip/impl/lapack.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/lapack.hpp,v
retrieving revision 1.7
diff -c -p -r1.7 lapack.hpp
*** src/vsip/impl/lapack.hpp	30 Sep 2005 21:43:07 -0000	1.7
--- src/vsip/impl/lapack.hpp	11 Oct 2005 19:18:41 -0000
*************** NOTES:
*** 30,35 ****
--- 30,36 ----
  
  #include <vsip/support.hpp>
  #include <vsip/impl/acconfig.hpp>
+ #include <vsip/impl/metaprogramming.hpp>
  
  
  
*************** extern "C"
*** 54,66 ****
--- 55,103 ----
    typedef std::complex<float>*  C;
    typedef std::complex<double>* Z;
  
+   // dot
+   float  sdot_ (I, S, I, S, I);
+   double ddot_ (I, D, I, D, I);
+   std::complex<float>  cdotu_(I, C, I, C, I);
+   std::complex<double> zdotu_(I, Z, I, Z, I);
+ 
+   std::complex<float>  cdotc_(I, C, I, C, I);
+   std::complex<double> zdotc_(I, Z, I, Z, I);
+ 
    // trsm
    void strsm_ (char*, char*, char*, char*, I, I, S, S, I, S, I);
    void dtrsm_ (char*, char*, char*, char*, I, I, D, D, I, D, I);
    void ctrsm_ (char*, char*, char*, char*, I, I, C, C, I, C, I);
    void ztrsm_ (char*, char*, char*, char*, I, I, Z, Z, I, Z, I);
+ 
+   // gemm
+   void sgemm_(char*, char*, I, I, I, S, S, I, S, I, S, S, I);
+   void dgemm_(char*, char*, I, I, I, D, D, I, D, I, D, D, I);
+   void cgemm_(char*, char*, I, I, I, C, C, I, C, I, C, C, I);
+   void zgemm_(char*, char*, I, I, I, Z, Z, I, Z, I, Z, Z, I);
  };
  
+ #define VSIP_IMPL_BLAS_DOT(T, VPPFCN, BLASFCN)				\
+ inline T								\
+ VPPFCN(int n,								\
+     T* x, int incx,							\
+     T* y, int incy)							\
+ {									\
+   return BLASFCN(&n, x, &incx, y, &incy);				\
+ }
+ 
+ VSIP_IMPL_BLAS_DOT(float,                dot, sdot_)
+ VSIP_IMPL_BLAS_DOT(double,               dot, ddot_)
+ VSIP_IMPL_BLAS_DOT(std::complex<float>,  dot, cdotu_)
+ VSIP_IMPL_BLAS_DOT(std::complex<double>, dot, zdotu_)
+ 
+ VSIP_IMPL_BLAS_DOT(std::complex<float>,  dotc, cdotc_)
+ VSIP_IMPL_BLAS_DOT(std::complex<double>, dotc, zdotc_)
+ 
+ #undef VSIP_IMPL_BLAS_DOT
+ 
+ 
+ 
  #define VSIP_IMPL_BLAS_TRSM(T, FCN)					\
  inline void								\
  trsm(char side, char uplo,char transa,char diag,			\
*************** VSIP_IMPL_BLAS_TRSM(std::complex<double>
*** 85,90 ****
--- 122,155 ----
  
  
  
+ #define VSIP_IMPL_BLAS_GEMM(T, FCN)					\
+ inline void								\
+ gemm(char transa, char transb,						\
+      int m, int n, int k,						\
+      T alpha,								\
+      T *a, int lda,							\
+      T *b, int ldb,							\
+      T beta,								\
+      T *c, int ldc)							\
+ {									\
+   FCN(&transa, &transb,							\
+       &m, &n, &k,							\
+       &alpha,								\
+       a, &lda,								\
+       b, &ldb,								\
+       &beta,								\
+       c, &ldc);								\
+ }
+ 
+ VSIP_IMPL_BLAS_GEMM(float,                sgemm_)
+ VSIP_IMPL_BLAS_GEMM(double,               dgemm_)
+ VSIP_IMPL_BLAS_GEMM(std::complex<float>,  cgemm_)
+ VSIP_IMPL_BLAS_GEMM(std::complex<double>, zgemm_)
+ 
+ #undef VSIP_IMPL_BLAS_GEMM
+ 
+ 
+ 
  template <typename T>
  struct Blas_traits
  {
*************** extern "C"
*** 195,207 ****
  } // extern "C"
  
  #if VSIP_IMPL_USE_LAPACK_ILAENV
! int
  ilaenv(int ispec, char* name, char* opts, int n1, int n2, int n3, int n4)
  {
    return ilaenv_(&ispec, name, opts, &n1, &n2, &n3, &n4);
  }
  #else
! int
  ilaenv(int, char*, char*, int , int , int , int)
  {
    return 80;
--- 260,272 ----
  } // extern "C"
  
  #if VSIP_IMPL_USE_LAPACK_ILAENV
! inline int
  ilaenv(int ispec, char* name, char* opts, int n1, int n2, int n3, int n4)
  {
    return ilaenv_(&ispec, name, opts, &n1, &n2, &n3, &n4);
  }
  #else
! inline int
  ilaenv(int, char*, char*, int , int , int , int)
  {
    return 80;
*************** extern "C"
*** 565,581 ****
  /// LAPACK error handler.  Called by LAPACK functions if illegal
  /// argument is passed.
  
! void xerbla_(char* name, int* info)
! {
!   char copy[8];
!   char msg[256];
! 
!   strncpy(copy, name, 6);
!   copy[6] = 0;
!   sprintf(msg, "lapack -- illegal arg (name=%s  info=%d)", copy, *info);
! 
!   VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));
! }
  
  }
  
--- 630,636 ----
  /// LAPACK error handler.  Called by LAPACK functions if illegal
  /// argument is passed.
  
! void xerbla_(char* name, int* info);
  
  }
  
Index: src/vsip/impl/matvec-prod.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/matvec-prod.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 matvec-prod.hpp
*** src/vsip/impl/matvec-prod.hpp	29 Sep 2005 06:00:51 -0000	1.2
--- src/vsip/impl/matvec-prod.hpp	11 Oct 2005 19:18:41 -0000
***************
*** 17,22 ****
--- 17,24 ----
  #include <vsip/vector.hpp>
  #include <vsip/matrix.hpp>
  #include <vsip/impl/matvec.hpp>
+ #include <vsip/impl/eval-blas.hpp>
+ 
  
  
  /***********************************************************************
*************** namespace vsip
*** 29,34 ****
--- 31,67 ----
  namespace impl
  {
  
+ // Generic evaluator for matrix-matrix products.
+ 
+ template <typename Block0,
+ 	  typename Block1,
+ 	  typename Block2>
+ struct Evaluator<Op_prod_mm, Block0, Op_list_2<Block1, Block2>,
+ 		 Generic_tag>
+ {
+   static bool const ct_valid = true;
+   static bool rt_valid(Block0&, Block1 const&, Block2 const&)
+   { return true; }
+ 
+   static void exec(Block0& r, Block1 const& a, Block2 const& b)
+   {
+     typedef typename Block0::value_type RT;
+ 
+     for (index_type i=0; i<r.size(2, 0); ++i)
+       for (index_type j=0; j<r.size(2, 1); ++j)
+       {
+ 	RT sum = RT();
+ 	for (index_type k=0; k<a.size(2, 1); ++k)
+ 	{
+ 	  sum += a.get(i, k) * b.get(k, j);
+ 	}
+ 	r.put(i, j, sum);
+     }
+   }
+ };
+ 
+ 
+ 
  /// Matrix-matrix product.
  
  template <typename T0,
*************** generic_prod(
*** 47,62 ****
    assert(r.size(1) == b.size(1));
    assert(a.size(1) == b.size(0));
  
!   for (index_type i=0; i<r.size(0); ++i)
!     for (index_type j=0; j<r.size(1); ++j)
!     {
!       T2 sum = T2();
!       for (index_type k=0; k<a.size(1); ++k)
!       {
! 	sum += a.get(i, k) * b.get(k, j);
!       }
!       r.put(i, j, sum);
!     }
  }
  
  
--- 80,91 ----
    assert(r.size(1) == b.size(1));
    assert(a.size(1) == b.size(0));
  
!   impl::General_dispatch<
! 		impl::Op_prod_mm,
! 		Block2,
!                 impl::Op_list_2<Block0, Block1>,
!                 typename impl::Dispatch_order<impl::Op_prod_mm>::type >
! 	::exec(r.block(), a.block(), b.block());
  }
  
  
Index: src/vsip/impl/matvec.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/matvec.hpp,v
retrieving revision 1.4
diff -c -p -r1.4 matvec.hpp
*** src/vsip/impl/matvec.hpp	4 Oct 2005 05:59:53 -0000	1.4
--- src/vsip/impl/matvec.hpp	11 Oct 2005 19:18:41 -0000
***************
*** 19,24 ****
--- 19,27 ----
  #include <vsip/matrix.hpp>
  #include <vsip/impl/promote.hpp>
  #include <vsip/impl/fns_elementwise.hpp>
+ #include <vsip/impl/general_dispatch.hpp>
+ #include <vsip/impl/eval-blas.hpp>
+ 
  
  
  namespace vsip
*************** namespace vsip
*** 26,48 ****
  
  namespace impl
  {
! // vector-vector product.
! template <typename T0,
! 	  typename T1,
! 	  typename T2,
! 	  typename Block0,
! 	  typename Block1>
! void
! generic_prod(
!   const_Vector<T0, Block0> a,
!   const_Vector<T1, Block1> b,
!   T2 &r)
  {
!   assert(a.size() == b.size());
  
-   for ( index_type i = 0; i < a.size(); ++i )
-     r += a.get(i) * b.get(i);
- }
  
  // vector-vector kron
  template <typename T0,
--- 29,60 ----
  
  namespace impl
  {
! 
! 
! 
! // Generic evaluator for vector-vector dot-product.
! 
! template <typename T,
! 	  typename Block1,
! 	  typename Block2>
! struct Evaluator<Op_prod_vv, Return_scalar<T>, Op_list_2<Block1, Block2>,
! 		 Generic_tag>
  {
!   static bool const ct_valid = true;
!   static bool rt_valid(Block1 const&, Block2 const&) { return true; }
! 
!   static T exec(Block1 const& a, Block2 const& b)
!   {
!     assert(a.size(1, 0) == b.size(1, 0));
! 
!     T r = T();
!     for ( index_type i = 0; i < a.size(); ++i )
!       r += a.get(i) * b.get(i);
!     return r;
!   }
! };
! 
  
  
  // vector-vector kron
  template <typename T0,
*************** cumsum(
*** 359,379 ****
  
  // dot products  [math.matvec.dot]
  
- /// cvjdot
- template <typename T0, typename T1, typename Block0, typename Block1>
- typename Promotion<complex<T0>, complex<T1> >::type
- cvjdot(
-   const_Vector<complex<T0>, Block0> v,
-   const_Vector<complex<T1>, Block1> w) VSIP_NOTHROW
- {
-   typedef typename Promotion<complex<T0>, complex<T1> >::type return_type;
-   
-   return_type r(0);
-   impl::generic_prod( v, conj(w), r );
- 
-   return r;
- }
- 
  /// dot
  template <typename T0, typename T1, typename Block0, typename Block1>
  typename Promotion<T0, T1>::type
--- 371,376 ----
*************** dot(
*** 384,393 ****
    typedef typename Promotion<T0, T1>::type return_type;
  
    return_type r(0);
!   impl::generic_prod( v, w, r );
  
    return r;
  }
   
   
  // Transpositions  [math.matvec.transpose]
--- 381,409 ----
    typedef typename Promotion<T0, T1>::type return_type;
  
    return_type r(0);
! 
!   r = impl::General_dispatch<
! 		impl::Op_prod_vv,
!                 impl::Return_scalar<return_type>,
!                 impl::Op_list_2<Block0, Block1>,
!                 typename impl::Dispatch_order<impl::Op_prod_vv>::type >
! 	::exec(v.block(), w.block());
  
    return r;
  }
+ 
+ 
+ 
+ /// cvjdot
+ template <typename T0, typename T1, typename Block0, typename Block1>
+ typename Promotion<complex<T0>, complex<T1> >::type
+ cvjdot(
+   const_Vector<complex<T0>, Block0> v,
+   const_Vector<complex<T1>, Block1> w) VSIP_NOTHROW
+ {
+   return dot(v, conj(w));
+ }
+ 
   
   
  // Transpositions  [math.matvec.transpose]
Index: src/vsip/impl/signal-conv-common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv-common.hpp,v
retrieving revision 1.4
diff -c -p -r1.4 signal-conv-common.hpp
*** src/vsip/impl/signal-conv-common.hpp	7 Oct 2005 13:46:46 -0000	1.4
--- src/vsip/impl/signal-conv-common.hpp	11 Oct 2005 19:18:41 -0000
*************** namespace vsip
*** 56,63 ****
  namespace impl
  {
  
! struct Generic_tag {};
! struct Opt_tag {};
  
  template <template <typename, typename> class ConstViewT,
  	  symmetry_type                       Symm,
--- 56,63 ----
  namespace impl
  {
  
! struct Generic_tag;
! struct Opt_tag;
  
  template <template <typename, typename> class ConstViewT,
  	  symmetry_type                       Symm,
Index: tests/extdata-output.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/extdata-output.hpp,v
retrieving revision 1.6
diff -c -p -r1.6 extdata-output.hpp
*** tests/extdata-output.hpp	26 Sep 2005 20:11:05 -0000	1.6
--- tests/extdata-output.hpp	11 Oct 2005 19:18:41 -0000
***************
*** 17,22 ****
--- 17,32 ----
  #include <sstream>
  #include <complex>
  
+ #define USE_TYPEID 0
+ 
+ #if USE_TYPEID
+ #  include <typeinfo>
+ #endif
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/vector.hpp>
+ #include <vsip/impl/expr_unary_block.hpp>
+ 
  
  
  /***********************************************************************
***************
*** 26,32 ****
  template <typename T>
  struct Type_name
  {
!   static std::string name() { return "#unknown#"; }
  };
  
  #define TYPE_NAME(TYPE, NAME)				\
--- 36,61 ----
  template <typename T>
  struct Type_name
  {
!   static std::string name()
!   {
! #if USE_TYPEID
!     return typeid(T).name();
! #else
!     return "#unknown#";
! #endif
!   }
! }
! ;
! 
! template <typename T>
! struct Type_name<T const>
! {
!   static std::string name()
!   {
!     std::ostringstream s;
!     s << Type_name<T>::name() << " const";
!     return s.str();
!   }
  };
  
  #define TYPE_NAME(TYPE, NAME)				\
*************** template <vsip::dimension_type Dim,
*** 134,140 ****
  	  typename    Map>
  struct Type_name<vsip::Dense<Dim, T, Order, Map> >
  {
!   static std::string name() { return std::string("Dense<>"); }
  };
  
  template <vsip::dimension_type Dim,
--- 163,178 ----
  	  typename    Map>
  struct Type_name<vsip::Dense<Dim, T, Order, Map> >
  {
!   static std::string name()
!   {
!     std::ostringstream s;
!     s << "Dense<" 
!       << Dim << ", "
!       << Type_name<T>::name() << ", "
!       << Type_name<Order>::name() << ", "
!       << Type_name<Map>::name() << ">";
!     return s.str();
!  }
  };
  
  template <vsip::dimension_type Dim,
*************** struct Type_name<vsip::impl::Fast_block<
*** 146,151 ****
--- 184,198 ----
    static std::string name() { return std::string("Fast_block<>"); }
  };
  
+ template <vsip::dimension_type      D,
+ 	  template <typename> class Operator,
+ 	  typename                  Block,
+ 	  typename                  Type>
+ struct Type_name<vsip::impl::Unary_expr_block<D, Operator, Block, Type> >
+ {
+   static std::string name() { return std::string("Unary_expr_block<>"); }
+ };
+ 
  
  TYPE_NAME(vsip::Block_dist,  "Block_dist")
  TYPE_NAME(vsip::Cyclic_dist, "Cyclic_dist")
Index: tests/matvec-dot.cpp
===================================================================
RCS file: tests/matvec-dot.cpp
diff -N tests/matvec-dot.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/matvec-dot.cpp	11 Oct 2005 19:18:41 -0000
***************
*** 0 ****
--- 1,161 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    tests/matvec-dot.cpp
+     @author  Jules Bergmann
+     @date    2005-10-11
+     @brief   VSIPL++ Library: Unit tests for dot products.
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <cassert>
+ 
+ 
+ #include <vsip/initfin.hpp>
+ #include <vsip/support.hpp>
+ #include <vsip/tensor.hpp>
+ #include <vsip/math.hpp>
+ 
+ #include "ref_matvec.hpp"
+ 
+ #include "test.hpp"
+ #include "test-random.hpp"
+ #include "test-precision.hpp"
+ 
+ #define VERBOSE 0
+ 
+ #if VERBOSE
+ #  include <iostream>
+ #  include "output.hpp"
+ #endif
+ 
+ using namespace std;
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ /// Test dot product with random values.
+ 
+ template <typename T0,
+ 	  typename T1>
+ void
+ test_dot_rand(length_type m)
+ {
+   typedef typename Promotion<T0, T1>::type return_type;
+   typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
+ 
+   Vector<T0> a(m);
+   Vector<T1> b(m);
+ 
+   randv(a);
+   randv(b);
+ 
+   // Test vector-vector prod
+   return_type val = dot(a, b);
+   return_type chk = ref::dot(a, b);
+ 
+   assert(equal(val, chk));
+ }
+ 
+ 
+ 
+ /// Test conjugated vector dot product with random values.
+ 
+ template <typename T0,
+ 	  typename T1>
+ void
+ test_cvjdot_rand(length_type m)
+ {
+   typedef typename Promotion<T0, T1>::type return_type;
+   typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
+ 
+   Vector<T0> a(m);
+   Vector<T1> b(m);
+ 
+   randv(a);
+   randv(b);
+ 
+   // Test vector-vector prod
+   return_type val  = cvjdot(a, b);
+   return_type chk1 = dot(a, conj(b));
+   return_type chk2 = ref::dot(a, conj(b));
+ 
+   assert(equal(val, chk1));
+   assert(equal(val, chk2));
+ }
+ 
+ 
+ 
+ template <typename T0,
+ 	  typename T1>
+ void
+ dot_cases()
+ {
+   for (length_type m=16; m<16384; m *= 4)
+   {
+     test_dot_rand<T0, T1>(m);
+     test_dot_rand<T0, T1>(m+1);
+     test_dot_rand<T0, T1>(2*m);
+   }
+ }
+ 
+ 
+ 
+ template <typename T0,
+ 	  typename T1>
+ void
+ cvjdot_cases()
+ {
+   for (length_type m=16; m<16384; m *= 4)
+   {
+     test_cvjdot_rand<T0, T1>(m);
+     test_cvjdot_rand<T0, T1>(m+1);
+     test_cvjdot_rand<T0, T1>(2*m);
+   }
+ }
+ 
+ 
+ 
+ void
+ dot_types()
+ {
+   dot_cases<float,  float>();
+   dot_cases<float,  double>();
+   dot_cases<double, float>();
+   dot_cases<double, double>();
+ 
+   dot_cases<complex<float>, complex<float> >();
+   dot_cases<float,          complex<float> >();
+   dot_cases<complex<float>, float>();
+ 
+   cvjdot_cases<complex<float>,  complex<float> >();
+   cvjdot_cases<complex<double>, complex<double> >();
+ }
+ 
+ 
+ 
+ /***********************************************************************
+   Main
+ ***********************************************************************/
+ 
+ template <> float  Precision_traits<float>::eps = 0.0;
+ template <> double Precision_traits<double>::eps = 0.0;
+ 
+ int
+ main(int argc, char** argv)
+ {
+   vsipl init(argc, argv);
+ 
+   Precision_traits<float>::compute_eps();
+   Precision_traits<double>::compute_eps();
+ 
+   test_cvjdot_rand<complex<float>, complex<float> >(16);
+ 
+   dot_types();
+ }
Index: tests/matvec-prod.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/matvec-prod.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 matvec-prod.cpp
*** tests/matvec-prod.cpp	29 Sep 2005 06:00:51 -0000	1.2
--- tests/matvec-prod.cpp	11 Oct 2005 19:18:41 -0000
***************
*** 19,24 ****
--- 19,26 ----
  #include <vsip/tensor.hpp>
  #include <vsip/math.hpp>
  
+ #include "ref_matvec.hpp"
+ 
  #include "test.hpp"
  #include "test-random.hpp"
  #include "test-precision.hpp"
*************** using namespace vsip;
*** 36,113 ****
  
  template <typename T0,
  	  typename T1,
! 	  typename Block0,
! 
! 	  typename Block1>
! typename Promotion<T0, T1>::type
! inner_product(
!   const_Vector<T0, Block0> u,
!   const_Vector<T1, Block1> v)
! {
!   typedef typename Promotion<T0, T1>::type return_type;
! 
!   assert(u.size() == v.size());
! 
!   return_type sum = return_type();
! 
!   for (index_type i=0; i<u.size(); ++i)
!     sum += u(i) * v(i);
! 
!   return sum;
! }
! 
! 
! 
! template <typename T0,
! 	  typename T1,
! 	  typename Block0,
! 	  typename Block1>
! Matrix<typename Promotion<T0, T1>::type>
! outer_product(
!   const_Vector<T0, Block0> u,
!   const_Vector<T1, Block1> v)
! {
!   typedef typename Promotion<T0, T1>::type return_type;
! 
!   Matrix<return_type> r(u.size(), v.size());
! 
!   for (index_type i=0; i<u.size(); ++i)
!     for (index_type j=0; j<v.size(); ++j)
!       // r(i, j) = u(i) * v(j);
!       r.put(i, j, u.get(i) * v.get(j));
! 
!   return r;
! }
! 
! 
! 
! template <typename T0,
! 	  typename T1,
! 	  typename Block0,
! 	  typename Block1>
! Matrix<typename Promotion<T0, T1>::type>
! ref_prod(
!   const_Matrix<T0, Block0> a,
!   const_Matrix<T1, Block1> b)
! {
!   typedef typename Promotion<T0, T1>::type return_type;
! 
!   assert(a.size(1) == b.size(0));
! 
!   Matrix<return_type> r(a.size(0), b.size(1), return_type());
! 
!   for (index_type k=0; k<a.size(1); ++k)
!     r += outer_product(a.col(k), b.row(k));
! 
!   return r;
! }
! 
! 
! template <typename T0,
! 	  typename T1,
!           typename T2>
  void
! check_prod( Matrix<T0> test, Matrix<T1> chk, Matrix<T2> gauge )
  {
    typedef typename Promotion<T0, T1>::type return_type;
    typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
--- 38,52 ----
  
  template <typename T0,
  	  typename T1,
!           typename T2,
!           typename Block0,
!           typename Block1,
!           typename Block2>
  void
! check_prod(
!   Matrix<T0, Block0> test,
!   Matrix<T1, Block1> chk,
!   Matrix<T2, Block2> gauge)
  {
    typedef typename Promotion<T0, T1>::type return_type;
    typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
*************** check_prod( Matrix<T0> test, Matrix<T1> 
*** 130,154 ****
  
  
  /***********************************************************************
!   Reference Definitions
  ***********************************************************************/
  
  /// Test matrix-matrix, matrix-vector, and vector-matrix products.
  
  template <typename T0,
! 	  typename T1>
  void
  test_prod_rand(length_type m, length_type n, length_type k)
  {
    typedef typename Promotion<T0, T1>::type return_type;
    typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
  
!   Matrix<T0> a(m, n);
!   Matrix<T1> b(n, k);
!   Matrix<return_type> res1(m, k);
!   Matrix<return_type> res2(m, k);
!   Matrix<return_type> res3(m, k);
!   Matrix<return_type> chk(m, k);
    Matrix<scalar_type> gauge(m, k);
  
    randm(a);
--- 69,100 ----
  
  
  /***********************************************************************
!   Test Definitions
  ***********************************************************************/
  
  /// Test matrix-matrix, matrix-vector, and vector-matrix products.
  
  template <typename T0,
! 	  typename T1,
! 	  typename OrderR,
! 	  typename Order0,
! 	  typename Order1>
  void
  test_prod_rand(length_type m, length_type n, length_type k)
  {
    typedef typename Promotion<T0, T1>::type return_type;
    typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
  
!   typedef Dense<2, T0, Order0>          block0_type;
!   typedef Dense<2, T1, Order1>          block1_type;
!   typedef Dense<2, return_type, OrderR> blockR_type;
! 
!   Matrix<T0, block0_type>          a(m, n);
!   Matrix<T1, block1_type>          b(n, k);
!   Matrix<return_type, blockR_type> res1(m, k);
!   Matrix<return_type, blockR_type> res2(m, k);
!   Matrix<return_type, blockR_type> res3(m, k);
!   Matrix<return_type, blockR_type> chk(m, k);
    Matrix<scalar_type> gauge(m, k);
  
    randm(a);
*************** test_prod_rand(length_type m, length_typ
*** 165,172 ****
    for (index_type i=0; i<m; ++i)
      res3.row(i) = prod(a.row(i), b);
  
!   chk   = ref_prod(a, b);
!   gauge = ref_prod(mag(a), mag(b));
  
    for (index_type i=0; i<gauge.size(0); ++i)
      for (index_type j=0; j<gauge.size(1); ++j)
--- 111,118 ----
    for (index_type i=0; i<m; ++i)
      res3.row(i) = prod(a.row(i), b);
  
!   chk   = ref::prod(a, b);
!   gauge = ref::prod(mag(a), mag(b));
  
    for (index_type i=0; i<gauge.size(0); ++i)
      for (index_type j=0; j<gauge.size(1); ++j)
*************** test_prod3_rand()
*** 213,220 ****
    for (index_type i=0; i<k; ++i)
      res2.col(i) = prod3(a, b.col(i));
  
!   chk   = ref_prod(a, b);
!   gauge = ref_prod(mag(a), mag(b));
  
    for (index_type i=0; i<gauge.size(0); ++i)
      for (index_type j=0; j<gauge.size(1); ++j)
--- 159,166 ----
    for (index_type i=0; i<k; ++i)
      res2.col(i) = prod3(a, b.col(i));
  
!   chk   = ref::prod(a, b);
!   gauge = ref::prod(mag(a), mag(b));
  
    for (index_type i=0; i<gauge.size(0); ++i)
      for (index_type j=0; j<gauge.size(1); ++j)
*************** test_prod4_rand()
*** 259,266 ****
    for (index_type i=0; i<k; ++i)
      res2.col(i) = prod4(a, b.col(i));
  
!   chk   = ref_prod(a, b);
!   gauge = ref_prod(mag(a), mag(b));
  
    for (index_type i=0; i<gauge.size(0); ++i)
      for (index_type j=0; j<gauge.size(1); ++j)
--- 205,212 ----
    for (index_type i=0; i<k; ++i)
      res2.col(i) = prod4(a, b.col(i));
  
!   chk   = ref::prod(a, b);
!   gauge = ref::prod(mag(a), mag(b));
  
    for (index_type i=0; i<gauge.size(0); ++i)
      for (index_type j=0; j<gauge.size(1); ++j)
*************** test_prodh_rand(length_type m, length_ty
*** 298,305 ****
    // Test matrix-matrix prod for hermitian
    res1   = prod(a, herm(b));
  
!   chk   = ref_prod(a, herm(b));
!   gauge = ref_prod(mag(a), mag(herm(b)));
  
    for (index_type i=0; i<gauge.size(0); ++i)
      for (index_type j=0; j<gauge.size(1); ++j)
--- 244,251 ----
    // Test matrix-matrix prod for hermitian
    res1   = prod(a, herm(b));
  
!   chk   = ref::prod(a, herm(b));
!   gauge = ref::prod(mag(a), mag(herm(b)));
  
    for (index_type i=0; i<gauge.size(0); ++i)
      for (index_type j=0; j<gauge.size(1); ++j)
*************** test_prodj_rand(length_type m, length_ty
*** 336,343 ****
    // Test matrix-matrix prod for hermitian
    res1   = prod(a, conj(b));
  
!   chk   = ref_prod(a, conj(b));
!   gauge = ref_prod(mag(a), mag(conj(b)));
  
    for (index_type i=0; i<gauge.size(0); ++i)
      for (index_type j=0; j<gauge.size(1); ++j)
--- 282,289 ----
    // Test matrix-matrix prod for hermitian
    res1   = prod(a, conj(b));
  
!   chk   = ref::prod(a, conj(b));
!   gauge = ref::prod(mag(a), mag(conj(b)));
  
    for (index_type i=0; i<gauge.size(0); ++i)
      for (index_type j=0; j<gauge.size(1); ++j)
*************** test_prodt_rand(length_type m, length_ty
*** 374,381 ****
    // Test matrix-matrix prod for transpose
    res1   = prod(a, trans(b));
  
!   chk   = ref_prod(a, trans(b));
!   gauge = ref_prod(mag(a), mag(trans(b)));
  
    for (index_type i=0; i<gauge.size(0); ++i)
      for (index_type j=0; j<gauge.size(1); ++j)
--- 320,327 ----
    // Test matrix-matrix prod for transpose
    res1   = prod(a, trans(b));
  
!   chk   = ref::prod(a, trans(b));
!   gauge = ref::prod(mag(a), mag(trans(b)));
  
    for (index_type i=0; i<gauge.size(0); ++i)
      for (index_type j=0; j<gauge.size(1); ++j)
*************** test_prodt_rand(length_type m, length_ty
*** 393,406 ****
  
  
  template <typename T0,
! 	  typename T1>
  void
  prod_cases()
  {
!   test_prod_rand<T0, T1>(5, 5, 5);
!   test_prod_rand<T0, T1>(5, 7, 9);
!   test_prod_rand<T0, T1>(9, 5, 7);
!   test_prod_rand<T0, T1>(9, 7, 5);
  
    test_prod3_rand<T0, T1>();
    test_prod4_rand<T0, T1>();
--- 339,355 ----
  
  
  template <typename T0,
! 	  typename T1,
! 	  typename OrderR,
! 	  typename Order0,
! 	  typename Order1>
  void
  prod_cases()
  {
!   test_prod_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
!   test_prod_rand<T0, T1, OrderR, Order0, Order1>(5, 7, 9);
!   test_prod_rand<T0, T1, OrderR, Order0, Order1>(9, 5, 7);
!   test_prod_rand<T0, T1, OrderR, Order0, Order1>(9, 7, 5);
  
    test_prod3_rand<T0, T1>();
    test_prod4_rand<T0, T1>();
*************** prod_cases_complex_only()
*** 429,453 ****
  }
  
  
  void
  prod_types()
  {
!   prod_cases<float,  float>();
!   prod_cases<double, double>();
!   prod_cases<float,  double>();
!   prod_cases<double, float>();
! 
!   prod_cases<complex<float>, complex<float> >();
!   prod_cases<float,          complex<float> >();
!   prod_cases<complex<float>, float >();
  
    prod_cases_complex_only<complex<float>, complex<float> >();
  }
  
  
  
- 
- 
  /***********************************************************************
    Main
  ***********************************************************************/
--- 378,404 ----
  }
  
  
+ 
+ template <typename OrderR,
+ 	  typename Order0,
+ 	  typename Order1>
  void
  prod_types()
  {
!   prod_cases<float,  float,  OrderR, Order0, Order1>();
!   prod_cases<double, double, OrderR, Order0, Order1>();
!   prod_cases<float,  double, OrderR, Order0, Order1>();
!   prod_cases<double, float,  OrderR, Order0, Order1>();
! 
!   prod_cases<complex<float>, complex<float>, OrderR, Order0, Order1 >();
!   prod_cases<float,          complex<float>, OrderR, Order0, Order1 >();
!   prod_cases<complex<float>, float,          OrderR, Order0, Order1 >();
  
    prod_cases_complex_only<complex<float>, complex<float> >();
  }
  
  
  
  /***********************************************************************
    Main
  ***********************************************************************/
*************** main(int argc, char** argv)
*** 463,467 ****
    Precision_traits<float>::compute_eps();
    Precision_traits<double>::compute_eps();
  
!   prod_types();
  }
--- 414,424 ----
    Precision_traits<float>::compute_eps();
    Precision_traits<double>::compute_eps();
  
!   prod_types<row2_type, row2_type, row2_type>();
!   prod_types<row2_type, col2_type, row2_type>();
!   prod_types<row2_type, row2_type, col2_type>();
! 
!   prod_types<col2_type, col2_type, col2_type>();
!   prod_types<col2_type, row2_type, col2_type>();
!   prod_types<col2_type, col2_type, row2_type>();
  }
Index: tests/ref_matvec.hpp
===================================================================
RCS file: tests/ref_matvec.hpp
diff -N tests/ref_matvec.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/ref_matvec.hpp	11 Oct 2005 19:18:41 -0000
***************
*** 0 ****
--- 1,107 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    tests/ref_matvec.hpp
+     @author  Jules Bergmann
+     @date    2005-10-11
+     @brief   VSIPL++ Library: Reference implementations of matvec routines.
+ */
+ 
+ #ifndef VSIP_REF_MATVEC_HPP
+ #define VSIP_REF_MATVEC_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <cassert>
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/vector.hpp>
+ 
+ 
+ 
+ /***********************************************************************
+   Reference Definitions
+ ***********************************************************************/
+ 
+ namespace ref
+ {
+ 
+ // Reference dot-product function.
+ 
+ template <typename T0,
+ 	  typename T1,
+ 	  typename Block0,
+ 	  typename Block1>
+ typename vsip::Promotion<T0, T1>::type
+ dot(
+   vsip::const_Vector<T0, Block0> u,
+   vsip::const_Vector<T1, Block1> v)
+ {
+   typedef typename vsip::Promotion<T0, T1>::type return_type;
+ 
+   assert(u.size() == v.size());
+ 
+   return_type sum = return_type();
+ 
+   for (vsip::index_type i=0; i<u.size(); ++i)
+     sum += u.get(i) * v.get(i);
+ 
+   return sum;
+ }
+ 
+ 
+ 
+ // Reference outer-product function.
+ 
+ template <typename T0,
+ 	  typename T1,
+ 	  typename Block0,
+ 	  typename Block1>
+ vsip::Matrix<typename vsip::Promotion<T0, T1>::type>
+ outer(
+   vsip::const_Vector<T0, Block0> u,
+   vsip::const_Vector<T1, Block1> v)
+ {
+   typedef typename vsip::Promotion<T0, T1>::type return_type;
+ 
+   vsip::Matrix<return_type> r(u.size(), v.size());
+ 
+   for (vsip::index_type i=0; i<u.size(); ++i)
+     for (vsip::index_type j=0; j<v.size(); ++j)
+       // r(i, j) = u(i) * v(j);
+       r.put(i, j, u.get(i) * v.get(j));
+ 
+   return r;
+ }
+ 
+ 
+ 
+ // Reference matrix-matrix product function (using outer-product).
+ 
+ template <typename T0,
+ 	  typename T1,
+ 	  typename Block0,
+ 	  typename Block1>
+ vsip::Matrix<typename vsip::Promotion<T0, T1>::type>
+ prod(
+   vsip::const_Matrix<T0, Block0> a,
+   vsip::const_Matrix<T1, Block1> b)
+ {
+   typedef typename vsip::Promotion<T0, T1>::type return_type;
+ 
+   assert(a.size(1) == b.size(0));
+ 
+   vsip::Matrix<return_type> r(a.size(0), b.size(1), return_type());
+ 
+   for (vsip::index_type k=0; k<a.size(1); ++k)
+     r += ref::outer(a.col(k), b.row(k));
+ 
+   return r;
+ }
+ 
+ 
+ 
+ } // namespace ref
+ 
+ #endif // VSIP_REF_MATVEC_HPP
Index: tests/test-random.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/test-random.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 test-random.hpp
*** tests/test-random.hpp	13 Sep 2005 16:39:45 -0000	1.1
--- tests/test-random.hpp	11 Oct 2005 19:18:41 -0000
*************** randm(vsip::Matrix<T, Block> m)
*** 57,60 ****
--- 57,75 ----
        m(r, c) = Random<T>::value();
  }
  
+ 
+ 
+ /// Fill a vector with random values.
+ 
+ template <typename T,
+ 	  typename Block>
+ void
+ randv(vsip::Vector<T, Block> v)
+ {
+   using vsip::index_type;
+ 
+   for (index_type i=0; i<v.size(0); ++i)
+     v(i) = Random<T>::value();
+ }
+ 
  #endif // VSIP_TESTS_TEST_RANDOM_HPP
