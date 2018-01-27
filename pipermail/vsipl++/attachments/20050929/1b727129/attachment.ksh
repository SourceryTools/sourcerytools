Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.282
diff -c -p -r1.282 ChangeLog
*** ChangeLog	29 Sep 2005 06:00:51 -0000	1.282
--- ChangeLog	29 Sep 2005 15:28:11 -0000
***************
*** 1,3 ****
--- 1,13 ----
+ 2005-09-29  Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	Implement toeplitz linear system solver.
+ 	* src/vsip/solvers.hpp: Include solver-toepsol.
+ 	* src/vsip/impl/fns_scalar.hpp: Implement impl_conj, impl_real,
+ 	  and impl_imag functions that work with both scalar and complex.
+ 	* src/vsip/impl/fns_elementwise.hpp: Likewise.
+ 	* src/vsip/impl/solver-toepsol.hpp: New file, toeplitz solver.
+ 	* tests/solver-toepsol.cpp: New file, test for toeplitz solver.
+ 
  2005-09-28  Don McCoy  <don@codesourcery.com>
  	
  	* src/vsip/impl/matvec-prod.hpp: added prod3, prod4,
Index: src/vsip/solvers.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/solvers.hpp,v
retrieving revision 1.4
diff -c -p -r1.4 solvers.hpp
*** src/vsip/solvers.hpp	27 Sep 2005 21:30:17 -0000	1.4
--- src/vsip/solvers.hpp	29 Sep 2005 15:28:11 -0000
***************
*** 19,23 ****
--- 19,24 ----
  #include <vsip/impl/solver-llsqsol.hpp>
  #include <vsip/impl/solver-cholesky.hpp>
  #include <vsip/impl/solver-svd.hpp>
+ #include <vsip/impl/solver-toepsol.hpp>
  
  #endif // VSIP_SOLVERS_HPP
Index: src/vsip/impl/fns_elementwise.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fns_elementwise.hpp,v
retrieving revision 1.12
diff -c -p -r1.12 fns_elementwise.hpp
*** src/vsip/impl/fns_elementwise.hpp	26 Sep 2005 14:09:24 -0000	1.12
--- src/vsip/impl/fns_elementwise.hpp	29 Sep 2005 15:28:11 -0000
*************** VSIP_IMPL_UNARY_FUNC(sqrt)
*** 305,310 ****
--- 305,334 ----
  VSIP_IMPL_UNARY_FUNC(tan)
  VSIP_IMPL_UNARY_FUNC(tanh)
  
+ VSIP_IMPL_UNARY_FUNC(impl_conj)
+ 
+ template <typename T>
+ struct impl_real_functor
+ {
+   typedef typename Scalar_of<T>::type result_type;
+   static result_type apply(T t) { return fn::impl_real(t);}
+   result_type operator()(T t) const { return apply(t);}
+ };
+ 
+ VSIP_IMPL_UNARY_DISPATCH(impl_real)
+ VSIP_IMPL_UNARY_FUNCTION(impl_real)
+ 
+ template <typename T>
+ struct impl_imag_functor
+ {
+   typedef typename Scalar_of<T>::type result_type;
+   static result_type apply(T t) { return fn::impl_imag(t);}
+   result_type operator()(T t) const { return apply(t);}
+ };
+ 
+ VSIP_IMPL_UNARY_DISPATCH(impl_imag)
+ VSIP_IMPL_UNARY_FUNCTION(impl_imag)
+ 
  /***********************************************************************
    Binary Functions
  ***********************************************************************/
Index: src/vsip/impl/fns_scalar.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fns_scalar.hpp,v
retrieving revision 1.11
diff -c -p -r1.11 fns_scalar.hpp
*** src/vsip/impl/fns_scalar.hpp	17 Sep 2005 18:26:39 -0000	1.11
--- src/vsip/impl/fns_scalar.hpp	29 Sep 2005 15:28:12 -0000
*************** template <typename T1, typename T2, type
*** 275,280 ****
--- 275,308 ----
  inline typename Promotion<typename Promotion<T1, T2>::type, T3>::type
  sbm(T1 t1, T2 t2, T3 t3) VSIP_NOTHROW { return (t1 - t2) * t3;}
  
+ template <typename T>
+ struct Impl_complex_class
+ {
+   static T conj(T val) { return val; }
+   static T real(T val) { return val; }
+   static T imag(T val) { return T(); }
+ };
+ 
+ template <typename T>
+ struct Impl_complex_class<std::complex<T> >
+ {
+   static std::complex<T> conj(std::complex<T> val) { return std::conj(val); }
+   static T real(std::complex<T> val) { return val.real(); }
+   static T imag(std::complex<T> val) { return val.imag(); }
+ };
+ 
+ template <typename T>
+ inline T
+ impl_conj(T val) { return Impl_complex_class<T>::conj(val); }
+ 
+ template <typename T>
+ inline typename Scalar_of<T>::type
+ impl_real(T val) { return Impl_complex_class<T>::real(val); }
+ 
+ template <typename T>
+ inline typename Scalar_of<T>::type
+ impl_imag(T val) { return Impl_complex_class<T>::imag(val); }
+ 
  } // namespace vsip::impl::fn
  } // namespace vsip::impl
  } // namespace vsip
Index: src/vsip/impl/solver-toepsol.hpp
===================================================================
RCS file: src/vsip/impl/solver-toepsol.hpp
diff -N src/vsip/impl/solver-toepsol.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/solver-toepsol.hpp	29 Sep 2005 15:28:12 -0000
***************
*** 0 ****
--- 1,159 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/solver-svd.hpp
+     @author  Jules Bergmann
+     @date    2005-09-11
+     @brief   VSIPL++ Library: Toeplitz linear system solver.
+ 
+     Algorithm based on TASP C-VSIPL toeplitz solver.
+ */
+ 
+ #ifndef VSIP_IMPL_SOLVER_TOEPSOL_HPP
+ #define VSIP_IMPL_SOLVER_TOEPSOL_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <algorithm>
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/matrix.hpp>
+ #include <vsip/math.hpp>
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
+ /// Solve a real symmetric or complex Hermetian positive definite Toeplitz
+ /// linear system.
+ 
+ /// Solves:
+ ///   T x = B
+ /// for x, given T and B.
+ ///
+ /// Requires:
+ ///   T to be an input vector of length N, first row of the Toeplitz matrix.
+ ///   B to be an input vector of length N.
+ ///   Y to be a vector of length N used for temporary workspace.
+ ///   X to be a vector of length N, for the result to be stored.
+ ///
+ /// Effects:
+ ///   On return, X containts solution to system T X = B.
+ ///
+ /// Returns X.
+ ///
+ /// Throws:
+ ///   computation_error if T is ill-formed (non postive definite)
+ ///   bad_alloc if allocation fails.
+ 
+ template <typename T,
+ 	  typename Block0,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ const_Vector<T, Block3>
+ toepsol(
+    const_Vector<T, Block0> t,
+    const_Vector<T, Block1> b,
+    Vector<T, Block2>       y,
+    Vector<T, Block3>       x)
+ VSIP_THROW((std::bad_alloc, computation_error))
+ {
+   typedef typename impl::Scalar_of<T>::type scalar_type;
+ 
+   assert(t.size() == b.size());
+   assert(t.size() == y.size());
+   assert(t.size() == x.size());
+ 
+   length_type n = t.size();
+ 
+ 
+   typename const_Vector<T, Block0>::subview_type r = t(Domain<1>(1, 1, n-1));
+   Vector<T> tmpv(n);
+ 
+   scalar_type beta  = 1.0;
+   scalar_type scale = impl::impl_real(t(0));
+   T           alpha = impl::impl_conj(-r(0)/scale);
+   T           tmps; 
+   
+   alpha = impl::impl_conj(-r(0)/scale);
+   
+   y(0) = alpha;
+   x(0) = b(0) / scale;
+ 
+   for (index_type k=1; k<n; ++k)
+   {
+     beta *= (1.0 - magsq(alpha));
+     if (beta == 0.0)
+     { 
+       VSIP_IMPL_THROW(computation_error("TOEPSOL: not full rank"));
+     } 
+ 
+     tmps = dot(impl_conj(r(Domain<1>(k))), x(Domain<1>(k-1, -1, k)));
+     T mu = (b(k) - tmps) / (scale*beta);
+ 
+     // x(Domain<1>(k)) += mu * impl_conj(y(Domain<1>(k-1, -1, k)));
+     x(Domain<1>(k)) = mu * impl_conj(y(Domain<1>(k-1, -1, k)))
+                     + x(Domain<1>(k));
+     x(k) = mu;
+ 
+     if (k < (n - 1))
+     {
+       tmps  = dot(impl_conj(r(Domain<1>(k))), y(Domain<1>(k-1, -1, k)));
+       alpha = -(tmps + impl::impl_conj(r(k))) / (scale*beta);
+       
+       tmpv(Domain<1>(k)) = alpha * impl_conj(y(Domain<1>(k-1, -1, k))) 
+ 	                 + y(Domain<1>(k));
+       y(Domain<1>(k)) = tmpv(Domain<1>(k));
+       y(k) = alpha;
+     }
+   }
+ 
+   return x;
+ }
+ 
+ 
+ 
+ /// Solve a real symmetric or complex Hermetian positive definite Toeplitz
+ /// linear system.
+ 
+ /// Solves:
+ ///   T x = B
+ /// for x, given T and B.
+ ///
+ /// Requires:
+ ///   T to be an input vector of length N, first row of the Toeplitz matrix.
+ ///   B to be an input vector of length N.
+ ///   Y to be a vector of length N used for temporary workspace.
+ ///
+ /// Effects:
+ ///   Returns vector X of length N, solution to system T X = B.
+ ///
+ /// Throws:
+ ///   computation_error if T is ill-formed (non postive definite)
+ ///   bad_alloc if allocation fails.
+ 
+ template <typename T,
+ 	  typename Block0,
+ 	  typename Block1,
+ 	  typename Block2>
+ const_Vector<T>
+ toepsol(
+    const_Vector<T, Block0> t,
+    const_Vector<T, Block1> b,
+    Vector<T, Block2>       y)
+ VSIP_THROW((std::bad_alloc, computation_error))
+ {
+   Vector<T> x(t.size());
+   return toepsol(t, b, y, x);
+ }
+ 
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_SOLVER_TOEPSOL_HPP
Index: tests/solver-toepsol.cpp
===================================================================
RCS file: tests/solver-toepsol.cpp
diff -N tests/solver-toepsol.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/solver-toepsol.cpp	29 Sep 2005 15:28:12 -0000
***************
*** 0 ****
--- 1,267 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    tests/solver-toepsol.cpp
+     @author  Jules Bergmann
+     @date    2005-09-28
+     @brief   VSIPL++ Library: Unit tests for toeplitz solver.
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <cassert>
+ 
+ #include <vsip/initfin.hpp>
+ #include <vsip/support.hpp>
+ #include <vsip/tensor.hpp>
+ #include <vsip/solvers.hpp>
+ #include <vsip/selgen.hpp>
+ #include <vsip/random.hpp>
+ 
+ #include "test.hpp"
+ #include "test-precision.hpp"
+ #include "test-random.hpp"
+ #include "solver-common.hpp"
+ 
+ #define VERBOSE  0
+ #define DO_FULL  0
+ 
+ #if VERBOSE
+ #  include <iostream>
+ #  include "output.hpp"
+ #  include "extdata-output.hpp"
+ #endif
+ 
+ using namespace std;
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   function tests
+ ***********************************************************************/
+ 
+ /// Solve a linear system with the Toeplitz solver.
+ 
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2>
+ void
+ test_toepsol(
+   return_mechanism_type rtm,
+   Vector<T, Block1>     a,
+   Vector<T, Block2>     b)
+ {
+   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+ 
+   length_type size = a.size();
+ 
+   Vector<T> y(size);
+   Vector<T> x(size, T(99));
+ 
+   Matrix<T> aa(size, size);
+ 
+   aa.diag() = a(0);
+   for (index_type i=1; i<size; ++i)
+   {
+     aa.diag(+i) =                 a(i);
+     aa.diag(-i) = impl::impl_conj(a(i));
+   }
+ 
+ 
+   // Solve toeplize system
+   if (rtm == by_reference)
+     toepsol(a, b, y, x);
+   else
+     x = toepsol(a, b, y);
+ 
+ 
+   // Check answer
+   Vector<T>           chk(size);
+   Vector<scalar_type> gauge(size);
+ 
+   chk   = prod(aa, x);
+   gauge = prod(mag(aa), mag(x));
+ 
+   for (index_type i=0; i<gauge.size(0); ++i)
+     if (!(gauge(i) > scalar_type()))
+       gauge(i) = scalar_type(1);
+ 
+   Index<1> idx;
+   scalar_type err = maxval(((mag(chk - b) / gauge)
+ 			     / Precision_traits<scalar_type>::eps
+ 			     / size),
+ 			   idx);
+ 
+ #if VERBOSE
+   cout << "aa = " << endl << aa  << endl;
+   cout << "a = " << endl << a  << endl;
+   cout << "b = " << endl << b  << endl;
+   cout << "x = " << endl << x  << endl;
+   cout << "chk = " << endl << chk  << endl;
+   cout << "err = " << err  << endl;
+ #endif
+ 
+   assert(err < 5.0);
+ }
+ 
+ 
+ 
+ /// Test a simple toeplitz linear system with zeros outside of diagonal.
+ 
+ template <typename T>
+ void
+ test_toepsol_diag(
+   return_mechanism_type rtm,
+   T                     value,
+   length_type           size)
+ {
+   Vector<T> a(size, T());
+   Vector<T> b(size);
+ 
+   a = T(); a(0) = value;
+ 
+   b = ramp(T(1), T(1), size);
+ 
+   test_toepsol(rtm, a, b);
+ }
+ 
+ 
+ 
+ template <typename T>
+ struct Toepsol_traits
+ {
+   static T value(index_type i)
+   {
+     if (i == 0) return T(5);
+     if (i == 1) return T(0.5);
+     if (i == 2) return T(0.2);
+     if (i == 3) return T(0.1);
+     return T(0);
+   }
+ };
+ 
+ 
+ 
+ template <typename T>
+ struct Toepsol_traits<complex<T> >
+ {
+   static complex<T> value(index_type i)
+   {
+     if (i == 0) return complex<T>(5, 0);
+     if (i == 1) return complex<T>(0.5, .1);
+     if (i == 2) return complex<T>(0.2, .1);
+     if (i == 3) return complex<T>(0.1, .15);
+     return complex<T>(0, 0);
+   }
+ };
+ 
+ 
+ 
+ /// Test a general toeplitz linear system.
+ 
+ template <typename T>
+ void
+ test_toepsol_rand(
+   return_mechanism_type rtm,
+   length_type           size,
+   length_type           loop)
+ {
+   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+ 
+   Vector<T> a(size, T());
+   Vector<T> b(size);
+ 
+   a = T();
+ 
+   for (index_type i=0; i<size; ++i)
+     a(i) = Toepsol_traits<T>::value(i);
+ 
+   Rand<T> rand(1);
+ 
+   for (index_type l=0; l<loop; ++l)
+   {
+     b = rand.randu(size);
+     test_toepsol(rtm, a, b);
+   }
+ }
+ 
+ 
+ 
+ /// Test a non positive-definite toeplitz linear system.
+ 
+ template <typename T>
+ void
+ test_toepsol_illformed(
+   return_mechanism_type rtm,
+   length_type           size)
+ {
+   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+ 
+   Vector<T> a(size, T());
+   Vector<T> b(size);
+ 
+   // Specify a non positive-definite matrix.
+   a = T();
+   a(0) = T(1);
+   a(1) = T(1);
+ 
+   Rand<T> rand(1);
+ 
+   b = rand.randu(size);
+ 
+   int pass = 0;
+   try
+   {
+     test_toepsol(rtm, a, b);
+     pass = 0;
+   }
+   catch (const std::exception& error)
+   {
+     if (error.what() == std::string("TOEPSOL: not full rank"))
+       pass = 1;
+   }
+ 
+   assert(pass == 1);
+ }
+ 
+ 
+ void
+ toepsol_cases(return_mechanism_type rtm)
+ {
+   test_toepsol_diag<float>           (rtm, 1.0, 5);
+   test_toepsol_diag<double>          (rtm, 2.0, 5);
+   test_toepsol_diag<complex<float> > (rtm, complex<float>(2.0, 0.0), 5);
+   test_toepsol_diag<complex<double> >(rtm, complex<double>(3.0, 0.0), 5);
+ 
+   test_toepsol_rand<float>           (rtm, 4, 5);
+   test_toepsol_rand<double>          (rtm, 5, 5);
+   test_toepsol_rand<complex<float> > (rtm, 6, 5);
+   test_toepsol_rand<complex<double> >(rtm, 7, 5);
+ 
+   test_toepsol_illformed<float>      (rtm, 4);
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
+ 
+ 
+ int
+ main(int argc, char** argv)
+ {
+   vsipl init(argc, argv);
+ 
+   Precision_traits<float>::compute_eps();
+   Precision_traits<double>::compute_eps();
+ 
+   toepsol_cases(by_reference);
+   toepsol_cases(by_value);
+ }
