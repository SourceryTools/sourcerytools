Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.283
diff -c -p -r1.283 ChangeLog
*** ChangeLog	30 Sep 2005 15:19:16 -0000	1.283
--- ChangeLog	30 Sep 2005 15:37:21 -0000
***************
*** 1,5 ****
--- 1,18 ----
  2005-09-30  Jules Bergmann  <jules@codesourcery.com>
  
+ 	Implement LU linear system solver.
+ 	* src/vsip/impl/solver-lu.hpp: New file, LU solver.
+ 	* src/vsip/solvers.hpp: Include solver-lu.
+ 	* src/vsip/impl/lapack.hpp: Add LAPACK routines for LU solver
+ 	  (getrf and getrs).
+ 	* tests/solver-lu.cpp: New file, unit tests for LU solver.
+ 
+ 	* src/vsip/impl/solver-cholesky.hpp: Use stride to determine
+ 	  leading dimension.
+ 
+ 2005-09-30  Jules Bergmann  <jules@codesourcery.com>
+ 
  	Implement toeplitz linear system solver.
  	* src/vsip/solvers.hpp: Include solver-toepsol.
  	* src/vsip/impl/fns_scalar.hpp: Implement impl_conj, impl_real,
Index: src/vsip/solvers.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/solvers.hpp,v
retrieving revision 1.5
diff -c -p -r1.5 solvers.hpp
*** src/vsip/solvers.hpp	30 Sep 2005 15:19:16 -0000	1.5
--- src/vsip/solvers.hpp	30 Sep 2005 15:37:21 -0000
***************
*** 17,22 ****
--- 17,23 ----
  #include <vsip/impl/solver-qr.hpp>
  #include <vsip/impl/solver-covsol.hpp>
  #include <vsip/impl/solver-llsqsol.hpp>
+ #include <vsip/impl/solver-lu.hpp>
  #include <vsip/impl/solver-cholesky.hpp>
  #include <vsip/impl/solver-svd.hpp>
  #include <vsip/impl/solver-toepsol.hpp>
Index: src/vsip/impl/lapack.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/lapack.hpp,v
retrieving revision 1.6
diff -c -p -r1.6 lapack.hpp
*** src/vsip/impl/lapack.hpp	27 Sep 2005 21:30:17 -0000	1.6
--- src/vsip/impl/lapack.hpp	30 Sep 2005 15:37:21 -0000
*************** extern "C"
*** 179,184 ****
--- 179,194 ----
    void cpotrs_(char*, I, I, C, I, C, I, I);
    void zpotrs_(char*, I, I, Z, I, Z, I, I);
  
+   void sgetrf_(I, I, S, I, I, I);
+   void dgetrf_(I, I, D, I, I, I);
+   void cgetrf_(I, I, C, I, I, I);
+   void zgetrf_(I, I, Z, I, I, I);
+ 
+   void sgetrs_(char*, I, I, S, I, I, S, I, I);
+   void dgetrs_(char*, I, I, D, I, I, D, I, I);
+   void cgetrs_(char*, I, I, C, I, I, C, I, I);
+   void zgetrs_(char*, I, I, Z, I, I, Z, I, I);
+ 
  #if VSIP_IMPL_USE_LAPACK_ILAENV
    int ilaenv_(I, char*, char*, I, I, I, I);
  #endif
*************** VSIP_IMPL_LAPACK_POTRS(std::complex<doub
*** 484,489 ****
--- 494,558 ----
  
  
  
+ /// GETRF - compute LU factorization of a general matrix.
+ 
+ /// Returns:
+ ///   true  if info == 0
+ ///   false if info > 0,
+ ///     (When info > 0, this indicates the factorization has been
+ ///     completed, but U is exactly singular.  Division by 0 will
+ ///     occur if factor U is used to solve a system of linear eq.
+ 
+ #define VSIP_IMPL_LAPACK_GETRF(T, FCN)					\
+ inline bool								\
+ getrf(int m, int n, T* a, int lda, int* ipiv)				\
+ {									\
+   int info;								\
+   FCN(&m, &n, a, &lda, ipiv, &info);					\
+   if (info < 0)								\
+   {									\
+     char msg[256];							\
+     sprintf(msg, "lapack::getrf -- illegal arg (info=%d)", info);	\
+     VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));			\
+   }									\
+   return (info == 0);							\
+ }
+ 
+ VSIP_IMPL_LAPACK_GETRF(float,                sgetrf_)
+ VSIP_IMPL_LAPACK_GETRF(double,               dgetrf_)
+ VSIP_IMPL_LAPACK_GETRF(std::complex<float>,  cgetrf_)
+ VSIP_IMPL_LAPACK_GETRF(std::complex<double>, zgetrf_)
+ 
+ #undef VSIP_IMPL_LAPACK_GETRF
+ 
+ 
+ 
+ /// GETRS - Solves a system of linear equations with a LU-factored
+ /// square matrix, with multiple right-hand sides.
+ 
+ #define VSIP_IMPL_LAPACK_GETRS(T, FCN)					\
+ inline void								\
+ getrs(char trans, int n, int nhrs, T* a, int lda, int* ipiv, T* b, int ldb) \
+ {									\
+   int info;								\
+   FCN(&trans, &n, &nhrs, a, &lda, ipiv, b, &ldb, &info);		\
+   if (info != 0)							\
+   {									\
+     char msg[256];							\
+     sprintf(msg, "lapack::getrs -- illegal arg (info=%d)", info);	\
+     VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));			\
+   }									\
+ }
+ 
+ VSIP_IMPL_LAPACK_GETRS(float,                sgetrs_)
+ VSIP_IMPL_LAPACK_GETRS(double,               dgetrs_)
+ VSIP_IMPL_LAPACK_GETRS(std::complex<float>,  cgetrs_)
+ VSIP_IMPL_LAPACK_GETRS(std::complex<double>, zgetrs_)
+ 
+ #undef VSIP_IMPL_LAPACK_GETRS
+ 
+ 
+ 
  } // namespace vsip::impl::lapack
  } // namespace vsip::impl
  } // namespace vsip
Index: src/vsip/impl/solver-cholesky.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-cholesky.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 solver-cholesky.hpp
*** src/vsip/impl/solver-cholesky.hpp	10 Sep 2005 17:41:16 -0000	1.1
--- src/vsip/impl/solver-cholesky.hpp	30 Sep 2005 15:37:21 -0000
*************** Chold_impl<T>::decompose(Matrix<T, Block
*** 219,225 ****
  		uplo_ == upper ? 'U' : 'L', // A upper/lower lower triangular
  		length_,		    // order of matrix A
  		ext.data(),		    // matrix A
! 		length_);		    // lda - first dim of A
  
    return success;
  }
--- 219,225 ----
  		uplo_ == upper ? 'U' : 'L', // A upper/lower lower triangular
  		length_,		    // order of matrix A
  		ext.data(),		    // matrix A
! 		ext.stride(1));		    // lda - first dim of A
  
    return success;
  }
*************** Chold_impl<T>::impl_solve(
*** 250,257 ****
      lapack::potrs(uplo_ == upper ? 'U' : 'L',
  		  length_,
  		  b.size(1),		    // number of RHS systems
! 		  a_ext.data(), length_,    // A, lda
! 		  b_ext.data(), b.size(0)); // B, ldb
    }
    x = b_int;
  
--- 250,257 ----
      lapack::potrs(uplo_ == upper ? 'U' : 'L',
  		  length_,
  		  b.size(1),		    // number of RHS systems
! 		  a_ext.data(), a_ext.stride(1), // A, lda
! 		  b_ext.data(), b_ext.stride(1));  // B, ldb
    }
    x = b_int;
  
Index: src/vsip/impl/solver-lu.hpp
===================================================================
RCS file: src/vsip/impl/solver-lu.hpp
diff -N src/vsip/impl/solver-lu.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/solver-lu.hpp	30 Sep 2005 15:37:21 -0000
***************
*** 0 ****
--- 1,293 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/solver-lu.hpp
+     @author  Jules Bergmann
+     @date    2005-09-29
+     @brief   VSIPL++ Library: LU linear system solver.
+ 
+ */
+ 
+ #ifndef VSIP_IMPL_SOLVER_LU_HPP
+ #define VSIP_IMPL_SOLVER_LU_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <algorithm>
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/matrix.hpp>
+ #include <vsip/impl/math-enum.hpp>
+ #include <vsip/impl/lapack.hpp>
+ #include <vsip/impl/temp_buffer.hpp>
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
+ /// Cholesky factorization implementation class.  Common functionality
+ /// for lud by-value and by-reference classes.
+ 
+ template <typename T>
+ class Lud_impl
+   : Compile_time_assert<blas::Blas_traits<T>::valid>
+ {
+   typedef Dense<2, T, col2_type> data_block_type;
+ 
+   // Constructors, copies, assignments, and destructors.
+ public:
+   Lud_impl(length_type)
+     VSIP_THROW((std::bad_alloc));
+   Lud_impl(Lud_impl const&)
+     VSIP_THROW((std::bad_alloc));
+ 
+   Lud_impl& operator=(Lud_impl const&) VSIP_NOTHROW;
+   ~Lud_impl() VSIP_NOTHROW;
+ 
+   // Accessors.
+ public:
+   length_type length()const VSIP_NOTHROW { return length_; }
+ 
+   // Solve systems.
+ public:
+   template <typename Block>
+   bool decompose(Matrix<T, Block>) VSIP_NOTHROW;
+ 
+ protected:
+   template <mat_op_type tr,
+ 	    typename    Block0,
+ 	    typename    Block1>
+   bool impl_solve(const_Matrix<T, Block0>, Matrix<T, Block1>)
+     VSIP_NOTHROW;
+ 
+   // Member data.
+ private:
+   typedef std::vector<int, Aligned_allocator<int> > vector_type;
+ 
+   length_type  length_;			// Order of A.
+   vector_type  ipiv_;			// Additional info on Q
+ 
+   Matrix<T, data_block_type> data_;	// Factorized Cholesky matrix (A)
+ };
+ 
+ } // namespace vsip::impl
+ 
+ 
+ 
+ /// LU solver object.
+ 
+ template <typename              T               = VSIP_DEFAULT_VALUE_TYPE,
+ 	  return_mechanism_type ReturnMechanism = by_value>
+ class lud;
+ 
+ 
+ 
+ /// LU solver object (by-reference).
+ 
+ template <typename T>
+ class lud<T, by_reference>
+   : public impl::Lud_impl<T>
+ {
+   typedef impl::Lud_impl<T> base_type;
+ 
+   // Constructors, copies, assignments, and destructors.
+ public:
+   lud(length_type length)
+     VSIP_THROW((std::bad_alloc))
+       : base_type(length)
+     {}
+ 
+   ~lud() VSIP_NOTHROW {}
+ 
+   // By-reference solvers.
+ public:
+   template <mat_op_type tr,
+ 	    typename    Block0,
+ 	    typename    Block1>
+   bool solve(const_Matrix<T, Block0> b, Matrix<T, Block1> x)
+     VSIP_NOTHROW
+   { return this->template impl_solve<tr, Block0, Block1>(b, x); }
+ };
+ 
+ 
+ 
+ /// LU solver object (by-value).
+ 
+ template <typename T>
+ class lud<T, by_value>
+   : public impl::Lud_impl<T>
+ {
+   typedef impl::Lud_impl<T> base_type;
+ 
+   // Constructors, copies, assignments, and destructors.
+ public:
+   lud(length_type length)
+     VSIP_THROW((std::bad_alloc))
+       : base_type(length)
+     {}
+ 
+   ~lud() VSIP_NOTHROW {}
+ 
+   // By-value solvers.
+ public:
+   template <mat_op_type tr,
+ 	    typename    Block0>
+   Matrix<T>
+   solve(const_Matrix<T, Block0> b)
+     VSIP_NOTHROW
+   {
+     Matrix<T> x(b.size(0), b.size(1));
+     this->template impl_solve<tr>(b, x); 
+     return x;
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ namespace impl
+ {
+ 
+ template <typename T>
+ Lud_impl<T>::Lud_impl(
+   length_type length
+   )
+ VSIP_THROW((std::bad_alloc))
+   : length_ (length),
+     ipiv_   (length_),
+     data_   (length_, length_)
+ {
+   assert(length_ > 0);
+ }
+ 
+ 
+ 
+ template <typename T>
+ Lud_impl<T>::Lud_impl(Lud_impl const& lu)
+ VSIP_THROW((std::bad_alloc))
+   : length_ (lu.length_),
+     ipiv_   (length_),
+     data_   (length_, length_)
+ {
+   data_ = lu.data_;
+   for (index_type i=0; i<length_; ++i)
+     ipiv_[i] = lu.ipiv_[i];
+ }
+ 
+ 
+ 
+ template <typename T>
+ Lud_impl<T>::~Lud_impl()
+   VSIP_NOTHROW
+ {
+ }
+ 
+ 
+ 
+ /// Form LU factorization of matrix A
+ ///
+ /// Requires
+ ///   A to be a square matrix, either
+ ///
+ /// FLOPS:
+ ///   real   : UPDATE
+ ///   complex: UPDATE
+ 
+ template <typename T>
+ template <typename Block>
+ bool
+ Lud_impl<T>::decompose(Matrix<T, Block> m)
+   VSIP_NOTHROW
+ {
+   assert(m.size(0) == length_ && m.size(1) == length_);
+ 
+   data_ = m;
+ 
+   Ext_data<data_block_type> ext(data_.block());
+ 
+   bool success = lapack::getrf(
+ 		length_, length_,
+ 		ext.data(), ext.stride(1),	// matrix A, ldA
+ 		&ipiv_[0]);			// pivots
+ 
+   return success;
+ }
+ 
+ 
+ 
+ /// Solve Op(A) x = b (where A previously given to decompose)
+ ///
+ /// Op(A) is
+ ///   A   if tr == mat_ntrans
+ ///   A^T if tr == mat_trans
+ ///   A'  if tr == mat_herm (valid for T complex only)
+ ///
+ /// Requires
+ ///   B to be a (length, P) matrix
+ ///   X to be a (length, P) matrix
+ ///
+ /// Effects:
+ ///   X contains solution to Op(A) X = B
+ 
+ template <typename T>
+ template <mat_op_type tr,
+ 	  typename    Block0,
+ 	  typename    Block1>
+ bool
+ Lud_impl<T>::impl_solve(
+   const_Matrix<T, Block0> b,
+   Matrix<T, Block1>       x)
+   VSIP_NOTHROW
+ {
+   assert(b.size(0) == length_);
+   assert(b.size(0) == x.size(0) && b.size(1) == x.size(1));
+ 
+   char trans;
+ 
+   Matrix<T, Dense<2, T, col2_type> > b_int(b.size(0), b.size(1));
+   b_int = b;
+ 
+   if (tr == mat_ntrans)
+     trans = 'N';
+   else if (tr == mat_trans)
+     trans = 'T';
+   else if (tr == mat_herm)
+   {
+     assert(Is_complex<T>::value);
+     trans = 'C';
+   }
+ 
+   {
+     Ext_data<Dense<2, T, col2_type> > b_ext(b_int.block());
+     Ext_data<data_block_type>         a_ext(data_.block());
+ 
+     lapack::getrs(trans,
+ 		  length_,			  // order of A
+ 		  b.size(1),			  // nrhs: number of RH sides
+ 		  a_ext.data(), a_ext.stride(1),  // A, lda
+ 		  &ipiv_[0],			  // pivots
+ 		  b_ext.data(), b_ext.stride(1)); // B, ldb
+   }
+   x = b_int;
+ 
+   return true;
+ }
+ 
+ } // namespace vsip::impl
+ 
+ } // namespace vsip
+ 
+ 
+ #endif // VSIP_IMPL_SOLVER_LU_HPP
Index: tests/solver-lu.cpp
===================================================================
RCS file: tests/solver-lu.cpp
diff -N tests/solver-lu.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/solver-lu.cpp	30 Sep 2005 15:37:21 -0000
***************
*** 0 ****
--- 1,346 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    tests/solver-lu.cpp
+     @author  Jules Bergmann
+     @date    2005-09-30
+     @brief   VSIPL++ Library: Unit tests for LU solver.
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
+ 
+ #include "test.hpp"
+ #include "test-precision.hpp"
+ #include "test-random.hpp"
+ #include "solver-common.hpp"
+ #include "load_view.hpp"
+ 
+ #define VERBOSE       0
+ #define DO_SWEEP      0
+ #define DO_BIG        1
+ #define FILE_MATRIX_1 0
+ 
+ #if VERBOSE || 1
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
+   Support Definitions
+ ***********************************************************************/
+ 
+ template <typename T,
+ 	  typename Block>
+ typename vsip::impl::Scalar_of<T>::type
+ norm_2(const_Vector<T, Block> v)
+ {
+   return sqrt(sumval(magsq(v)));
+ }
+ 
+ 
+ 
+ /***********************************************************************
+   LU tests
+ ***********************************************************************/
+ 
+ double max_err1 = 0.0;
+ double max_err2 = 0.0;
+ double max_err3 = 0.0;
+ 
+ 
+ 
+ // Chold test w/random matrix.
+ 
+ 
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2>
+ void
+ solve_lu(
+   return_mechanism_type rtm,
+   Matrix<T, Block1>     a,
+   Matrix<T, Block2>     b)
+ {
+   length_type n = a.size(0);
+   length_type p = b.size(1);
+ 
+   assert(n == a.size(1));
+   assert(n == b.size(0));
+ 
+   Matrix<T> x1(n, p);
+   Matrix<T> x2(n, p);
+   Matrix<T> x3(n, p);
+ 
+   if (rtm == by_reference)
+   {
+     // 1. Build solver and factor A.
+     lud<T, by_reference> lu(n);
+     assert(lu.length() == n);
+ 
+     bool success = lu.decompose(a);
+     assert(success);
+ 
+     // 2. Solve A X = B.
+     lu.template solve<mat_ntrans>(b, x1);
+     lu.template solve<mat_trans>(b, x2);
+     lu.template solve<Test_traits<T>::trans>(b, x3); // mat_herm if T complex
+   }
+   if (rtm == by_value)
+   {
+     // 1. Build solver and factor A.
+     lud<T, by_value> lu(n);
+     assert(lu.length() == n);
+ 
+     bool success = lu.decompose(a);
+     assert(success);
+ 
+     // 2. Solve A X = B.
+     x1 = lu.template solve<mat_ntrans>(b);
+     x2 = lu.template solve<mat_trans>(b);
+     x3 = lu.template solve<Test_traits<T>::trans>(b); // mat_herm if T complex
+   }
+ 
+ 
+   // 3. Check result.
+ 
+   Matrix<T> chk1(n, p);
+   Matrix<T> chk2(n, p);
+   Matrix<T> chk3(n, p);
+ 
+   prod(a, x1, chk1);
+   prod(trans(a), x2, chk2);
+   prod(trans_or_herm(a), x3, chk3);
+ 
+   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+ 
+   Vector<float> sv_s(n);
+   svd<T, by_reference> sv(n, n, svd_uvnos, svd_uvnos);
+   sv.decompose(a, sv_s);
+ 
+   scalar_type a_norm_2 = sv_s(0);
+ 
+ 
+   // Gaussian roundoff error (J.H Wilkinson)
+   // (From Moler, Chapter 2.9, p19)
+   //
+   //  || residual ||
+   // ----------------- <= p eps
+   // || A || || x_* ||
+   //
+   // Where 
+   //   x_* is computed solution (x is true solution)
+   //   residual = b - A x_*
+   //   eps is machine precision
+   //   p is usually less than 10
+ 
+   scalar_type eps     = Precision_traits<scalar_type>::eps;
+   scalar_type p_limit = scalar_type(20);
+ 
+   for (index_type i=0; i<p; ++i)
+   {
+     scalar_type residual_1 = norm_2((b - chk1).col(i));
+     scalar_type err1       = residual_1 / (a_norm_2 * norm_2(x1.col(i)) * eps);
+     scalar_type residual_2 = norm_2((b - chk2).col(i));
+     scalar_type err2       = residual_2 / (a_norm_2 * norm_2(x2.col(i)) * eps);
+     scalar_type residual_3 = norm_2((b - chk3).col(i));
+     scalar_type err3       = residual_3 / (a_norm_2 * norm_2(x3.col(i)) * eps);
+ 
+ #if VERBOSE
+     scalar_type cond = sv_s(0) / sv_s(n-1);
+     cout << "err " << i << " = "
+ 	 << err1 << ", " << err2 << ", " << err3
+ 	 << "  cond = " << cond
+ 	 << endl;
+ #endif
+ 
+     assert(err1 < p_limit);
+     assert(err2 < p_limit);
+     assert(err3 < p_limit);
+ 
+     if (err1 > max_err1) max_err1 = err1;
+     if (err2 > max_err2) max_err2 = err2;
+     if (err3 > max_err3) max_err3 = err3;
+   }
+ 
+ #if VERBOSE
+   cout << "a = " << endl << a << endl;
+   cout << "x1 = " << endl << x1 << endl;
+   cout << "x2 = " << endl << x2 << endl;
+   cout << "b = " << endl << b << endl;
+   cout << "chk1 = " << endl << chk1 << endl;
+   cout << "chk2 = " << endl << chk2 << endl;
+   cout << "chk3 = " << endl << chk3 << endl;
+ #endif
+ }
+ 
+ 
+ 
+ // Simple lud test w/diagonal matrix.
+ 
+ template <typename T>
+ void
+ test_lud_diag(
+   return_mechanism_type rtm,
+   length_type n,
+   length_type p)
+ {
+   Matrix<T> a(n, n);
+   Matrix<T> b(n, p);
+ 
+   a        = T();
+   a.diag() = T(1);
+   if (n > 0) a(0, 0)  = mag(Test_traits<T>::value1());
+   if (n > 2) a(2, 2)  = mag(Test_traits<T>::value2());
+   if (n > 3) a(3, 3)  = mag(Test_traits<T>::value3());
+ 
+   for (index_type i=0; i<p; ++i)
+     b.col(i) = test_ramp(T(1), T(i), n);
+   if (p > 1)
+     b.col(1) += Test_traits<T>::offset();
+ 
+   solve_lu(rtm, a, b);
+ }
+ 
+ 
+ 
+ // Chold test w/random matrix.
+ 
+ template <typename T>
+ void
+ test_lud_random(
+   return_mechanism_type rtm,
+   length_type           n,
+   length_type           p)
+ {
+   Matrix<T> a(n, n);
+   Matrix<T> b(n, p);
+ 
+   randm(a);
+   randm(b);
+ 
+   solve_lu(rtm, a, b);
+ }
+ 
+ 
+ 
+ // Chold test w/matrix from file.
+ 
+ template <typename FileT,
+ 	  typename T>
+ void
+ test_lud_file(
+   return_mechanism_type rtm,
+   char*                 afilename,
+   char*                 bfilename,
+   length_type           n,
+   length_type           p)
+ {
+   Load_view<2, FileT> load_a(afilename, Domain<2>(n, n));
+   Load_view<2, FileT> load_b(bfilename, Domain<2>(n, p));
+ 
+   Matrix<T> a(n, n);
+   Matrix<T> b(n, p);
+ 
+   a = load_a.view();
+   b = load_b.view();
+ 
+   solve_lu(rtm, a, b);
+ }
+ 
+ 
+ 
+ template <typename T>
+ void lud_cases(return_mechanism_type rtm)
+ {
+   for (index_type p=1; p<=3; ++p)
+   {
+     test_lud_diag<T>(rtm, 1, p);
+     test_lud_diag<T>(rtm, 5, p);
+     test_lud_diag<T>(rtm, 6, p);
+     test_lud_diag<T>(rtm, 17, p);
+   }
+ 
+ 
+   for (index_type p=1; p<=3; ++p)
+   {
+     test_lud_random<T>(rtm, 1, p);
+     test_lud_random<T>(rtm, 2, p);
+     test_lud_random<T>(rtm, 5, p);
+     test_lud_random<T>(rtm, 6, p);
+     test_lud_random<T>(rtm, 16, p);
+     test_lud_random<T>(rtm, 17, p);
+   }
+ 
+ #if DO_BIG
+   test_lud_random<T>(rtm, 97,   5+1);
+   test_lud_random<T>(rtm, 97+1, 5);
+   test_lud_random<T>(rtm, 97+2, 5+2);
+ #endif
+ 
+ #if DO_SWEEP
+   for (index_type i=1; i<100; i+= 8)
+     for (index_type j=1; j<10; j += 4)
+     {
+       test_lud_random<T>(rtm, i,   j+1);
+       test_lud_random<T>(rtm, i+1, j);
+       test_lud_random<T>(rtm, i+2, j+2);
+     }
+ #endif
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
+ #if FILE_MATRIX_1
+   test_lud_file<complex<float>, complex<double> >(
+     "lu-a-complex-float-99x99.dat", "lu-b-complex-float-99x7.dat", 99, 7);
+   test_lud_file<complex<float>, complex<float> >(
+     "lu-a-complex-float-99x99.dat", "lu-b-complex-float-99x7.dat", 99, 7);
+ #endif
+ 
+   lud_cases<float>           (by_reference);
+   lud_cases<double>          (by_reference);
+   lud_cases<complex<float> > (by_reference);
+   lud_cases<complex<double> >(by_reference);
+ 
+   lud_cases<float>           (by_value);
+   lud_cases<double>          (by_value);
+   lud_cases<complex<float> > (by_value);
+   lud_cases<complex<double> >(by_value);
+ 
+ #if VERBOSE
+   cout << "max_err1 " << max_err1 << endl;
+   cout << "max_err2 " << max_err2 << endl;
+   cout << "max_err3 " << max_err3 << endl;
+ #endif
+ }
