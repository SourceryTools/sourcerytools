Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.274
diff -c -p -r1.274 ChangeLog
*** ChangeLog	26 Sep 2005 20:23:28 -0000	1.274
--- ChangeLog	27 Sep 2005 16:28:28 -0000
***************
*** 1,3 ****
--- 1,20 ----
+ 2005-09-27  Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* configure.ac: Add -lpthread for MKL 5.x.
+ 	* src/vsip/solvers.hpp: Include solver-svd.
+ 	* src/vsip/impl/lapack.hpp: Add LAPACK routines for SVD (gebrd,
+ 	  orgbr/ungbr, sbdsqr).  Replace assertions on LAPACK info with
+ 	  exceptions.
+ 	* src/vsip/impl/matvec.hpp: Add trans_or_herm() function.
+ 	* src/vsip/impl/metaprogramming.hpp: Add Bool_type to encapsulate
+ 	  a bool as a type.
+ 	* src/vsip/impl/solver-svd.hpp: New file, implement SVD solver.
+ 	* src/vsip/impl/subblock.hpp (Diag::size): Check block_d argumment.
+ 	* tests/solver-common.hpp: Add compare_view functions.  Define
+ 	  perferred tranpose for value type (regular or conjugate) in
+ 	  Test_traits.
+ 	* tests/solver-svd.cpp: New file, unit tests for SVD solver.
+ 
  2005-09-26  Jules Bergmann  <jules@codesourcery.com>
  
  	* src/vsip/math.hpp: Include expr_generator_block.hpp
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.40
diff -c -p -r1.40 configure.ac
*** configure.ac	21 Sep 2005 06:45:07 -0000	1.40
--- configure.ac	27 Sep 2005 16:28:28 -0000
*************** if test "$enable_lapack" != "no"; then
*** 566,572 ****
        AC_MSG_CHECKING([for LAPACK/MKL 5.x library])
  
        LDFLAGS="$keep_LDFLAGS -L$with_mkl_prefix"
!       LIBS="$keep_LIBS -lmkl_lapack -lmkl -lg2c"
  
        lapack_use_ilaenv=0
      elif test "$trypkg" == "mkl7"; then
--- 566,572 ----
        AC_MSG_CHECKING([for LAPACK/MKL 5.x library])
  
        LDFLAGS="$keep_LDFLAGS -L$with_mkl_prefix"
!       LIBS="$keep_LIBS -lmkl_lapack -lmkl -lg2c -lpthread"
  
        lapack_use_ilaenv=0
      elif test "$trypkg" == "mkl7"; then
Index: src/vsip/solvers.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/solvers.hpp,v
retrieving revision 1.3
diff -c -p -r1.3 solvers.hpp
*** src/vsip/solvers.hpp	10 Sep 2005 17:41:16 -0000	1.3
--- src/vsip/solvers.hpp	27 Sep 2005 16:28:28 -0000
***************
*** 18,22 ****
--- 18,23 ----
  #include <vsip/impl/solver-covsol.hpp>
  #include <vsip/impl/solver-llsqsol.hpp>
  #include <vsip/impl/solver-cholesky.hpp>
+ #include <vsip/impl/solver-svd.hpp>
  
  #endif // VSIP_SOLVERS_HPP
Index: src/vsip/impl/lapack.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/lapack.hpp,v
retrieving revision 1.5
diff -c -p -r1.5 lapack.hpp
*** src/vsip/impl/lapack.hpp	10 Sep 2005 17:41:16 -0000	1.5
--- src/vsip/impl/lapack.hpp	27 Sep 2005 16:28:28 -0000
*************** extern "C"
*** 154,159 ****
--- 154,174 ----
    void cunmqr_(char*, char*, I, I, I, C, I, C, C, I, C, I, I);
    void zunmqr_(char*, char*, I, I, I, Z, I, Z, Z, I, Z, I, I);
  
+   void sgebrd_(I, I, S, I, S, S, S, S, S, I, I);
+   void dgebrd_(I, I, D, I, D, D, D, D, D, I, I);
+   void cgebrd_(I, I, C, I, S, S, C, C, C, I, I);
+   void zgebrd_(I, I, Z, I, D, D, Z, Z, Z, I, I);
+ 
+   void sorgbr_(char*, I, I, I, S, I, S, S, I, I);
+   void dorgbr_(char*, I, I, I, D, I, D, D, I, I);
+   void cungbr_(char*, I, I, I, C, I, C, C, I, I);
+   void zungbr_(char*, I, I, I, Z, I, Z, Z, I, I);
+ 
+   void sbdsqr_(char*, I, I, I, I, S, S, S, I, S, I, S, I, S, I);
+   void dbdsqr_(char*, I, I, I, I, D, D, D, I, D, I, D, I, D, I);
+   void cbdsqr_(char*, I, I, I, I, S, S, C, I, C, I, C, I, C, I);
+   void zbdsqr_(char*, I, I, I, I, D, D, Z, I, Z, I, Z, I, Z, I);
+ 
    void spotrf_(char*, I, S, I, I);
    void dpotrf_(char*, I, D, I, I);
    void cpotrf_(char*, I, C, I, I);
*************** inline void geqrf(int m, int n, T* a, in
*** 191,197 ****
  {									\
    int info;								\
    FCN(&m, &n, a, &lda, tau, work, &lwork, &info);			\
!   assert(info == 0);							\
  }									\
  									\
  template <>								\
--- 206,217 ----
  {									\
    int info;								\
    FCN(&m, &n, a, &lda, tau, work, &lwork, &info);			\
!   if (info != 0)							\
!   {									\
!     char msg[256];							\
!     sprintf(msg, "lapack::geqrf -- illegal arg (info=%d)", info);	\
!     VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));			\
!   }									\
  }									\
  									\
  template <>								\
*************** inline void geqr2(int m, int n, T* a, in
*** 221,227 ****
  {									\
    int info;								\
    FCN(&m, &n, a, &lda, tau, work, &info);				\
!   assert(info == 0);							\
  }									\
  									\
  template <>								\
--- 241,252 ----
  {									\
    int info;								\
    FCN(&m, &n, a, &lda, tau, work, &info);				\
!   if (info != 0)							\
!   {									\
!     char msg[256];							\
!     sprintf(msg, "lapack::geqr2 -- illegal arg (info=%d)", info);	\
!     VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));			\
!   }									\
  }									\
  									\
  template <>								\
*************** inline void mqr(char side, char trans,		
*** 255,261 ****
  {									\
    int info;								\
    FCN(&side, &trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info); \
!   assert(info == 0);							\
  }									\
  									\
  template <>								\
--- 280,291 ----
  {									\
    int info;								\
    FCN(&side, &trans, &m, &n, &k, a, &lda, tau, c, &ldc, work, &lwork, &info); \
!   if (info != 0)							\
!   {									\
!     char msg[256];							\
!     sprintf(msg, "lapack::mqr -- illegal arg (info=%d)", info);	\
!     VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));			\
!   }									\
  }									\
  									\
  template <>								\
*************** VSIP_IMPL_LAPACK_MQR(std::complex<double
*** 279,284 ****
--- 309,422 ----
  
  
  
+ #define VSIP_IMPL_LAPACK_GEBRD(T, FCN, NAME)				\
+ inline void gebrd(int m, int n, T* a, int lda,				\
+ 		  vsip::impl::Scalar_of<T >::type* d,			\
+ 		  vsip::impl::Scalar_of<T >::type* e,			\
+ 		  T* tauq, T* taup, T* work, int& lwork)		\
+ {									\
+   int info;								\
+   FCN(&m, &n, a, &lda, d, e, tauq, taup, work, &lwork, &info);		\
+   if (info != 0)							\
+   {									\
+     char msg[256];							\
+     sprintf(msg, "lapack::gebrd -- illegal arg (info=%d)", info);	\
+     VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));			\
+   }									\
+ }									\
+ 									\
+ template <>								\
+ inline int								\
+ gebrd_blksize<T >(int m, int n) /* Note [1] */				\
+ {									\
+   return ilaenv(1, NAME, "", m, n, -1, -1);				\
+ }
+ 
+ template <typename T>
+ inline int
+ gebrd_blksize(int m, int n);
+ 
+ 
+ VSIP_IMPL_LAPACK_GEBRD(float,                sgebrd_, "sgebrd")
+ VSIP_IMPL_LAPACK_GEBRD(double,               dgebrd_, "dgebrd")
+ VSIP_IMPL_LAPACK_GEBRD(std::complex<float>,  cgebrd_, "cgebrd")
+ VSIP_IMPL_LAPACK_GEBRD(std::complex<double>, zgebrd_, "zgebrd")
+ 
+ #undef VSIP_IMPL_LAPACK_GEBRD
+ 
+ 
+ 
+ #define VSIP_IMPL_LAPACK_GBR(T, FCN, NAME)				\
+ inline void gbr(char vect,						\
+ 		int m, int n, int k,					\
+ 		T *a, int lda,						\
+ 		T *tau,							\
+ 		T *work, int& lwork)					\
+ {									\
+   int info;								\
+   FCN(&vect, &m, &n, &k, a, &lda, tau, work, &lwork, &info);		\
+   if (info != 0)							\
+   {									\
+     char msg[256];							\
+     sprintf(msg, "lapack::gbr -- illegal arg (info=%d)", info);	\
+     VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));			\
+   }									\
+ }									\
+ 									\
+ template <>								\
+ inline int								\
+ gbr_blksize<T >(char vect, int m, int n, int k) /* Note [1] */		\
+ {									\
+   char arg[2]; arg[0] = vect; arg[1] = 0;				\
+   return ilaenv(1, NAME, arg, m, n, k, -1);				\
+ }
+ 
+ template <typename T>
+ inline int
+ gbr_blksize(char vect, int m, int n, int k);
+ 
+ VSIP_IMPL_LAPACK_GBR(float,                sorgbr_, "sorgbr")
+ VSIP_IMPL_LAPACK_GBR(double,               dorgbr_, "dorgbr")
+ VSIP_IMPL_LAPACK_GBR(std::complex<float>,  cungbr_, "cungbr")
+ VSIP_IMPL_LAPACK_GBR(std::complex<double>, zungbr_, "zungbr")
+ 
+ #undef VSIP_IMPL_LAPACK_GBR
+ 
+ 
+ 
+ /// BDSQR - compute the singular value decomposition of a general matrix
+ ///         that has been reduce to bidiagonal form.
+ 
+ #define VSIP_IMPL_LAPACK_BDSQR(T, FCN)					\
+ inline void bdsqr(char uplo,						\
+ 		  int n, int ncvt, int nru, int ncc,			\
+ 		  vsip::impl::Scalar_of<T >::type* d,			\
+ 		  vsip::impl::Scalar_of<T >::type* e,			\
+ 		  T *vt, int ldvt,					\
+ 		  T *u, int ldu,					\
+ 		  T *c, int ldc,					\
+ 		  T *work)						\
+ {									\
+   int info;								\
+   FCN(&uplo, &n, &ncvt, &nru, &ncc, d, e,				\
+       vt, &ldvt, u, &ldu, c, &ldc, work, &info);			\
+   if (info != 0)							\
+   {									\
+     char msg[256];							\
+     sprintf(msg, "lapack::bdsqr -- illegal arg (info=%d)", info);	\
+     VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));			\
+   }									\
+ }
+ 
+ VSIP_IMPL_LAPACK_BDSQR(float,                sbdsqr_)
+ VSIP_IMPL_LAPACK_BDSQR(double,               dbdsqr_)
+ VSIP_IMPL_LAPACK_BDSQR(std::complex<float>,  cbdsqr_)
+ VSIP_IMPL_LAPACK_BDSQR(std::complex<double>, zbdsqr_)
+ 
+ #undef VSIP_IMPL_LAPACK_BDSQR
+ 
+ 
+ 
  /// POTRF - compute cholesky factorization of a symmetric (hermtian)
  /// postive definite matrix
  
*************** potrf(char uplo, int n, T* a, int lda)		
*** 295,302 ****
  {									\
    int info;								\
    FCN(&uplo, &n, a, &lda, &info);					\
!   assert(info >= 0);							\
!   if (info > 0) printf("POTRF: %d\n", info);				\
    return (info == 0);							\
  }
  
--- 433,444 ----
  {									\
    int info;								\
    FCN(&uplo, &n, a, &lda, &info);					\
!   if (info < 0)								\
!   {									\
!     char msg[256];							\
!     sprintf(msg, "lapack::potrf -- illegal arg (info=%d)", info);	\
!     VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));			\
!   }									\
    return (info == 0);							\
  }
  
*************** potrs(char uplo, int n, int nhrs, T* a, 
*** 325,331 ****
  {									\
    int info;								\
    FCN(&uplo, &n, &nhrs, a, &lda, b, &ldb, &info);			\
!   assert(info == 0);							\
  }
  
  VSIP_IMPL_LAPACK_POTRS(float,                spotrs_)
--- 467,478 ----
  {									\
    int info;								\
    FCN(&uplo, &n, &nhrs, a, &lda, b, &ldb, &info);			\
!   if (info != 0)							\
!   {									\
!     char msg[256];							\
!     sprintf(msg, "lapack::potrs -- illegal arg (info=%d)", info);	\
!     VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));			\
!   }									\
  }
  
  VSIP_IMPL_LAPACK_POTRS(float,                spotrs_)
*************** extern "C"
*** 349,361 ****
  /// LAPACK error handler.  Called by LAPACK functions if illegal
  /// argument is passed.
  
! void xerbla_(char* name, int* /*info*/)
  {
    char copy[8];
    strncpy(copy, name, 6);
    copy[6] = 0;
  
!   VSIP_IMPL_THROW(vsip::impl::unimplemented("lapack -- illegal arg"));
  }
  
  }
--- 496,511 ----
  /// LAPACK error handler.  Called by LAPACK functions if illegal
  /// argument is passed.
  
! void xerbla_(char* name, int* info)
  {
    char copy[8];
+   char msg[256];
+ 
    strncpy(copy, name, 6);
    copy[6] = 0;
+   sprintf(msg, "lapack -- illegal arg (name=%s  info=%d)", copy, *info);
  
!   VSIP_IMPL_THROW(vsip::impl::unimplemented(msg));
  }
  
  }
Index: src/vsip/impl/matvec.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/matvec.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 matvec.hpp
*** src/vsip/impl/matvec.hpp	19 Sep 2005 21:06:46 -0000	1.1
--- src/vsip/impl/matvec.hpp	27 Sep 2005 16:28:28 -0000
*************** kron( T0 alpha, Matrix<T1, Block1> v, Ma
*** 90,95 ****
--- 90,147 ----
    return r;
  }
  
+ 
+ 
+ /// Class to perform transpose or hermetian (conjugate-transpose),
+ /// depending on value type.
+ 
+ /// Primary case - perform transpose.
+ 
+ template <typename T,
+ 	  typename Block>
+ struct Trans_or_herm
+ {
+   typedef typename const_Matrix<T, Block>::transpose_type result_type;
+ 
+   static result_type
+   exec(const_Matrix<T, Block> m) VSIP_NOTHROW
+   {
+     return m.transpose();
+   }
+ };
+ 
+ /// Complex specialization - perform hermetian.
+ 
+ template <typename T,
+ 	  typename Block>
+ struct Trans_or_herm<complex<T>, Block>
+ {
+   typedef typename const_Matrix<complex<T>, Block>::transpose_type 
+       transpose_type;
+   typedef impl::Unary_func_view<impl::conj_functor, transpose_type> 
+       functor_type;
+   typedef typename functor_type::result_type result_type;
+ 
+   static result_type
+   exec(const_Matrix<complex<T>, Block> m) VSIP_NOTHROW
+   {
+     return functor_type::apply(m.transpose());
+   } 
+ };
+ 
+ 
+ 
+ /// Perform transpose or hermetian, depending on value type.
+ 
+ template <typename T,
+ 	  typename Block>
+ inline
+ typename Trans_or_herm<T, Block>::result_type
+ trans_or_herm(const_Matrix<T, Block> m)
+ {
+   return Trans_or_herm<T, Block>::exec(m);
+ };
+ 
  } // namespace impl
  
  
Index: src/vsip/impl/metaprogramming.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/metaprogramming.hpp,v
retrieving revision 1.8
diff -c -p -r1.8 metaprogramming.hpp
*** src/vsip/impl/metaprogramming.hpp	28 Aug 2005 02:15:57 -0000	1.8
--- src/vsip/impl/metaprogramming.hpp	27 Sep 2005 16:28:28 -0000
*************** template <typename T>
*** 108,113 ****
--- 108,118 ----
  struct Is_complex<std::complex<T> >
  { static bool const value = true; };
  
+ 
+ template <bool value>
+ struct Bool_type
+ {};
+ 
  } // namespace impl
  } // namespace vsip
  
Index: src/vsip/impl/solver-svd.hpp
===================================================================
RCS file: src/vsip/impl/solver-svd.hpp
diff -N src/vsip/impl/solver-svd.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/solver-svd.hpp	27 Sep 2005 16:28:28 -0000
***************
*** 0 ****
--- 1,801 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/solver-svd.hpp
+     @author  Jules Bergmann
+     @date    2005-09-11
+     @brief   VSIPL++ Library: SVD Linear system solver.
+ 
+ */
+ 
+ #ifndef VSIP_IMPL_SOLVER_SVD_HPP
+ #define VSIP_IMPL_SOLVER_SVD_HPP
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
+ /// SVD decomposition implementation class.  Common functionality for
+ /// svd by-value and by-reference classes.
+ 
+ template <typename T,
+ 	  bool     Blocked = true>
+ class Svd_impl
+   : Compile_time_assert<blas::Blas_traits<T>::valid>
+ {
+   typedef Dense<2, T, col2_type> data_block_type;
+ 
+   // Constructors, copies, assignments, and destructors.
+ public:
+   Svd_impl(length_type, length_type, storage_type, storage_type)
+     VSIP_THROW((std::bad_alloc));
+   Svd_impl(Svd_impl const&)
+     VSIP_THROW((std::bad_alloc));
+ 
+   Svd_impl& operator=(Svd_impl const&) VSIP_NOTHROW;
+   ~Svd_impl() VSIP_NOTHROW;
+ 
+   // Accessors.
+ public:
+   length_type  rows()     const VSIP_NOTHROW { return m_; }
+   length_type  columns()  const VSIP_NOTHROW { return n_; }
+   storage_type ustorage() const VSIP_NOTHROW { return ust_; }
+   storage_type vstorage() const VSIP_NOTHROW { return vst_; }
+ 
+   // Solve systems.
+ protected:
+   template <typename Block0,
+ 	    typename Block1>
+   bool impl_decompose(Matrix<T, Block0>,
+ 		      Vector<scalar_f, Block1>) VSIP_NOTHROW;
+ 
+   template <mat_op_type       tr,
+ 	    product_side_type ps,
+ 	    typename          Block0,
+ 	    typename          Block1>
+   bool impl_produ(const_Matrix<T, Block0>, Matrix<T, Block1>)
+     VSIP_NOTHROW;
+ 
+   template <mat_op_type       tr,
+ 	    product_side_type ps,
+ 	    typename          Block0,
+ 	    typename          Block1>
+   bool impl_prodv(const_Matrix<T, Block0>, Matrix<T, Block1>)
+     VSIP_NOTHROW;
+ 
+   template <typename          Block>
+   bool impl_u(index_type, index_type, Matrix<T, Block>)
+     VSIP_NOTHROW;
+ 
+   template <typename          Block>
+   bool impl_v(index_type, index_type, Matrix<T, Block>)
+     VSIP_NOTHROW;
+ 
+   length_type  impl_order()  const VSIP_NOTHROW { return p_; }
+ 
+   // Member data.
+ private:
+   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+   typedef std::vector<T, Aligned_allocator<T> > vector_type;
+   typedef std::vector<scalar_type, Aligned_allocator<scalar_type> >
+ 		svector_type;
+ 
+   length_type  m_;			// Number of rows.
+   length_type  n_;			// Number of cols.
+   length_type  p_;			// min(rows, cols)
+   storage_type ust_;			// U storage type
+   storage_type vst_;			// V storage type
+ 
+   Matrix<T, data_block_type> data_;	// Factorized matrix
+   Matrix<T, data_block_type> q_;	// U matrix
+   Matrix<T, data_block_type> pt_;	// V' matrix
+ 
+   vector_type  tauq_;			// Additional info on Q
+   vector_type  taup_;			// Additional info on P
+   svector_type b_d_;			// Diagonal elements of B
+   svector_type b_e_;			// Off-diagonal elements of B
+ 					//  - gebrd requires min(m, n)-1
+ 					//  - bdsqr requires min(m, n)
+ 
+   length_type lwork_gebrd_;		// size of workspace needed for gebrd
+   vector_type work_gebrd_;		// workspace for gebrd
+   length_type lwork_gbr_;		// size of workspace needed for gebrd
+   vector_type work_gbr_;		// workspace for gebrd
+ };
+ 
+ } // namespace vsip::impl
+ 
+ 
+ 
+ /// SVD solver object.
+ 
+ template <typename              T               = VSIP_DEFAULT_VALUE_TYPE,
+ 	  return_mechanism_type ReturnMechanism = by_value>
+ class svd;
+ 
+ template <typename T>
+ class svd<T, by_reference>
+   : public impl::Svd_impl<T>
+ {
+   typedef impl::Svd_impl<T> base_type;
+ 
+   // Constructors, copies, assignments, and destructors.
+ public:
+   svd(length_type rows, length_type cols, storage_type ust, storage_type vst)
+     VSIP_THROW((std::bad_alloc))
+     : base_type(rows, cols, ust, vst)
+   {}
+ 
+   ~svd() VSIP_NOTHROW {}
+ 
+   // By-reference solvers.
+ public:
+   template <typename Block0,
+ 	    typename Block1>
+   bool decompose(Matrix<T, Block0> m, Vector<scalar_f, Block1> dest)
+     VSIP_NOTHROW
+   { return this->impl_decompose(m, dest); }
+ 
+   template <mat_op_type       tr,
+ 	    product_side_type ps,
+ 	    typename          Block0,
+ 	    typename          Block1>
+   bool produ(const_Matrix<T, Block0> b, Matrix<T, Block1> x)
+     VSIP_NOTHROW
+   // { return true; }
+   { return this->template impl_produ<tr, ps>(b, x); }
+ 
+   template <mat_op_type       tr,
+ 	    product_side_type ps,
+ 	    typename          Block0,
+ 	    typename          Block1>
+   bool prodv(const_Matrix<T, Block0> b, Matrix<T, Block1> x)
+     VSIP_NOTHROW
+   { return this->template impl_prodv<tr, ps>(b, x); }
+ 
+   template <typename Block>
+   bool u(index_type low, index_type high, Matrix<T, Block> dest)
+     VSIP_NOTHROW
+   { return this->template impl_u(low, high, dest); }
+ 
+   template <typename Block>
+   bool v(index_type low, index_type high, Matrix<T, Block> dest)
+     VSIP_NOTHROW
+   { return this->template impl_v(low, high, dest); }
+ };
+ 
+ template <typename T>
+ class svd<T, by_value>
+   : public impl::Svd_impl<T>
+ {
+   typedef impl::Svd_impl<T> base_type;
+ 
+   // Constructors, copies, assignments, and destructors.
+ public:
+   svd(length_type rows, length_type cols, storage_type ust, storage_type vst)
+     VSIP_THROW((std::bad_alloc))
+     : base_type(rows, cols, ust, vst)
+   {}
+ 
+   ~svd() VSIP_NOTHROW {}
+ 
+   // By-value solvers.
+ public:
+   template <typename Block0>
+   Vector<scalar_f>
+   decompose(Matrix<T, Block0> m)
+     VSIP_THROW((std::bad_alloc, computation_error))
+   {
+     Vector<scalar_f> dest(this->impl_order());
+     if (!this->impl_decompose(m, dest))
+       VSIP_IMPL_THROW(computation_error("svd::decompose"));
+     return dest;
+   }
+ 
+   template <mat_op_type       tr,
+ 	    product_side_type ps,
+ 	    typename          Block>
+   Matrix<T>
+   produ(const_Matrix<T, Block> b)
+     VSIP_THROW((std::bad_alloc, computation_error))
+   {
+     length_type q_rows = this->rows();
+     length_type q_cols = this->ustorage() == svd_uvfull ? this->rows() :
+                                                           this->impl_order();
+ 
+     length_type x_rows, x_cols;
+     if (ps == mat_lside)
+     {
+       x_rows = (tr == mat_ntrans) ? q_rows : q_cols;
+       x_cols = b.size(1);
+     }
+     else /* (ps == mat_rside) */
+     {
+       x_rows = b.size(0);
+       x_cols = (tr == mat_ntrans) ? q_cols : q_rows;
+     }
+     Matrix<T> x(x_rows, x_cols);
+     this->template impl_produ<tr, ps>(b, x);
+     return x;
+   }
+ 
+   template <mat_op_type       tr,
+ 	    product_side_type ps,
+ 	    typename          Block>
+   Matrix<T>
+   prodv(const_Matrix<T, Block> b)
+     VSIP_THROW((std::bad_alloc, computation_error))
+   { 
+     length_type vt_rows = this->vstorage() == svd_uvfull ? this->columns() :
+                                                            this->impl_order();
+     length_type vt_cols = this->columns();
+ 
+     length_type x_rows, x_cols;
+     if (ps == mat_lside)
+     {
+       x_rows = (tr == mat_ntrans) ? vt_cols : vt_rows;
+       x_cols = b.size(1);
+     }
+     else /* (ps == mat_rside) */
+     {
+       x_rows = b.size(0);
+       x_cols = (tr == mat_ntrans) ? vt_rows : vt_cols;
+     }
+     Matrix<T> x(x_rows, x_cols);
+     this->template impl_prodv<tr, ps>(b, x);
+     return x;
+   }
+ 
+   Matrix<T>
+   u(index_type low, index_type high)
+     VSIP_THROW((std::bad_alloc, computation_error))
+   {
+     assert(this->ustorage() == svd_uvpart && high <= this->impl_order() ||
+ 	   this->ustorage() == svd_uvfull && high <= this->rows());
+ 
+     Matrix<T> dest(this->rows(), high - low + 1);
+     if (!this->template impl_u(low, high, dest))
+       VSIP_IMPL_THROW(computation_error("svd::u"));
+     return dest;
+   }
+ 
+   Matrix<T>
+   v(index_type low, index_type high)
+     VSIP_THROW((std::bad_alloc, computation_error))
+   {
+     assert(this->vstorage() == svd_uvpart && high <= this->impl_order() ||
+ 	   this->vstorage() == svd_uvfull && high <= this->columns());
+ 
+     Matrix<T> dest(this->columns(), high - low + 1);
+     if (!this->template impl_v(low, high, dest))
+       VSIP_IMPL_THROW(computation_error("svd::v"));
+     return dest;
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
+ length_type inline
+ select_dim(storage_type st, length_type full, length_type part)
+ {
+   return (st == svd_uvfull) ? full :
+          (st == svd_uvpart) ? part : 0;
+ }
+ 
+ template <typename T,
+ 	  bool     Blocked>
+ Svd_impl<T, Blocked>::Svd_impl(
+   length_type  rows,
+   length_type  cols,
+   storage_type ust,
+   storage_type vst
+   )
+ VSIP_THROW((std::bad_alloc))
+   : m_          (rows),
+     n_          (cols),
+     p_          (std::min(m_, n_)),
+     ust_        (ust),
+     vst_        (vst),
+ 
+     data_       (m_, n_),
+     q_          (select_dim(ust_, m_, m_), select_dim(ust_, m_, p_)),
+     pt_         (select_dim(vst_, n_, p_), select_dim(vst_, n_, n_)),
+ 
+     tauq_       (p_),
+     taup_       (p_),
+     b_d_        (p_),
+     b_e_        (p_),
+ 
+     lwork_gebrd_((m_ + n_) * lapack::gebrd_blksize<T>(m_, n_)),
+     work_gebrd_ (lwork_gebrd_),
+     lwork_gbr_  (p_ * lapack::gbr_blksize<T>('Q', m_, m_, n_)),
+     work_gbr_   (lwork_gbr_)
+ {
+   assert(m_ > 0 && n_ > 0);
+   assert(ust_ == svd_uvnos || ust_ == svd_uvpart || ust_ == svd_uvfull);
+   assert(vst_ == svd_uvnos || vst_ == svd_uvpart || vst_ == svd_uvfull);
+ }
+ 
+ 
+ 
+ template <typename T,
+ 	  bool     Blocked>
+ Svd_impl<T, Blocked>::Svd_impl(Svd_impl const& sv)
+ VSIP_THROW((std::bad_alloc))
+   : m_          (sv.m_),
+     n_          (sv.n_),
+     p_          (sv.p_),
+     ust_        (sv.ust_),
+     vst_        (sv.vst_),
+ 
+     data_       (m_, n_),
+     q_          (select_dim(ust_, m_, m_), select_dim(ust_, m_, p_)),
+     pt_         (select_dim(vst_, n_, p_), select_dim(vst_, n_, n_)),
+ 
+     tauq_       (p_),
+     taup_       (p_),
+     b_d_        (p_),
+     b_e_        (p_),
+     lwork_gebrd_((m_ + n_) * lapack::gebrd_blksize<T>(m_, n_)),
+     work_gebrd_ (lwork_gebrd_),
+     lwork_gbr_  (p_ * lapack::gbr_blksize<T>('Q', m_, m_, n_)),
+     work_gbr_   (lwork_gbr_)
+ {
+   data_ = sv.data_;
+   q_    = sv.q_;
+   pt_   = sv.pt_;
+   for (index_type i=0; i<p_; ++i)
+   {
+     b_d_[i]  = sv.b_d_[i];
+     b_e_[i]  = sv.b_e_[i];
+     tauq_[i] = sv.tauq_[i];
+     taup_[i] = sv.taup_[i];
+   }
+ }
+ 
+ 
+ 
+ template <typename T,
+ 	  bool     Blocked>
+ Svd_impl<T, Blocked>::~Svd_impl()
+   VSIP_NOTHROW
+ {
+ }
+ 
+ 
+ 
+ /// Decompose matrix M into
+ ///
+ /// Return
+ ///   DEST contains M's singular values.
+ ///
+ /// Requires
+ ///   M to be a full rank, modifiable matrix of ROWS x COLS.
+ 
+ template <typename T,
+ 	  bool     Blocked>
+ template <typename Block0,
+ 	  typename Block1>
+ bool
+ Svd_impl<T, Blocked>::impl_decompose(
+   Matrix<T, Block0>              m,
+   Vector<vsip::scalar_f, Block1> dest)
+   VSIP_NOTHROW
+ {
+   assert(m.size(0) == m_ && m.size(1) == n_);
+   assert(dest.size() == p_);
+ 
+   int lwork   = lwork_gebrd_;
+ 
+   data_ = m;
+ 
+   // Step 1: Reduce general matrix A to bidiagonal form.
+   //
+   // If m >= n, then
+   //   A = Q_1 B_1 P'
+   // Where
+   //   Q_1 (m, n) orthogonal/unitary
+   //   B_1 (n, n) upper diagonal
+   //   P'  (n, n) orthogonal/unitary
+   //
+   // If m < n, then
+   //   A = Q_1 B_1 P'
+   // Where
+   //   Q_1 (m, m) orthogonal/unitary
+   //   B_1 (m, m) lower diagonal
+   //   P'  (m, n) orthogonal/unitary
+   {
+     Ext_data<data_block_type> ext(data_.block());
+ 
+     lapack::gebrd(m_, n_,
+ 		  ext.data(), ext.stride(1),	// A, lda
+ 		  &b_d_[0],			// diagonal of B
+ 		  &b_e_[0],			// off-diagonal of B
+ 		  &tauq_[0],
+ 		  &taup_[0],
+ 		  &work_gebrd_[0], lwork);
+     assert((length_type)lwork <= lwork_gebrd_);
+     // FLOPS:
+     //   scalar : (4/3)*n^2*(3*m-n) for m >= n
+     //          : (4/3)*m^2*(3*n-m) for m <  n
+     //   complex: 4*
+   }
+ 
+   
+   // Step 2: Generate real orthoganol/unitary matrices Q and P'
+ 
+   if (ust_ == svd_uvfull || ust_ == svd_uvpart)
+   {
+     // svd_uvfull: generate whole Q (m_, m_):
+     // svd_uvpart: generate first p_ columns of Q (m_, p_):
+ 
+     length_type cols = (ust_ == svd_uvfull) ? m_ : p_;
+ 
+     if (m_ >= n_)
+       q_(Domain<2>(m_, n_)) = data_;
+     else
+       q_ = data_(Domain<2>(m_, m_));
+ 
+     Ext_data<data_block_type> ext_q(q_.block());
+     lwork   = lwork_gbr_;
+     lapack::gbr('Q', m_, cols, n_,
+ 		ext_q.data(), ext_q.stride(1),	// A, lda
+ 		&tauq_[0],
+ 		&work_gbr_[0], lwork);
+   }
+ 
+ 
+   if (vst_ == svd_uvfull || vst_ == svd_uvpart)
+   {
+     // svd_uvfull: generate whole P' (n_, n_):
+     // svd_uvpart: generate first p_ rows of P' (p_, n_):
+ 
+     length_type rows = (vst_ == svd_uvfull) ? n_ : p_;
+ 
+     if (m_ >= n_)
+       pt_ = data_(Domain<2>(n_, n_));
+     else
+       pt_(Domain<2>(m_, n_)) = data_;
+ 
+     Ext_data<data_block_type> ext_pt(pt_.block());
+     lwork   = lwork_gbr_;
+     lapack::gbr('P', rows, n_, m_,
+ 		ext_pt.data(), ext_pt.stride(1),	// A, lda
+ 		&taup_[0],
+ 		&work_gbr_[0], lwork);
+   }
+ 
+ 
+   {
+     Ext_data<data_block_type> ext_q (q_.block());
+     Ext_data<data_block_type> ext_pt(pt_.block());
+ 
+     length_type nru    = (ust_ != svd_uvnos) ? m_ : 0;
+     T*          q_ptr  = (ust_ != svd_uvnos) ? ext_q.data()    : 0;
+     stride_type q_ld   = (ust_ != svd_uvnos) ? ext_q.stride(1) : 1;
+ 
+     length_type ncvt   = (vst_ != svd_uvnos) ? n_ : 0;
+     T*          pt_ptr = (vst_ != svd_uvnos) ? ext_pt.data()    : 0;
+     stride_type pt_ld  = (vst_ != svd_uvnos) ? ext_pt.stride(1) : 1;
+     
+     // Compute SVD of bidiagonal matrix B.
+ 
+     // Note: MKL says that work-size need only 4*(p_-1), 
+     //       however MKL 5.x needs 4*(p_).
+     vector_type work(4*p_);
+     char uplo = (m_ >= n_) ? 'U' : 'L';
+     lapack::bdsqr(uplo,
+ 		p_,	// Order of matrix B.
+ 		ncvt,	// Number of columns of VT (right singular vectors)
+ 		nru,	// Number of rows of U     (left  singular vectors)
+ 		0,	// Number of columns of C: 0 since no C supplied.
+ 		&b_d_[0],	//
+ 		&b_e_[0],	//
+ 	        pt_ptr, pt_ld,		// [p_ x ncvt]
+ 		q_ptr,  q_ld,		// [nru x p_]
+ 		0, 1,	// Not referenced since ncc = 0
+ 		&work[0]);
+     // Flops (scalar):
+     //  n^2 (singular values)
+     //  6n^2 * nru  (left singular vectors)	(complex 2*)
+     //  6n^2 * ncvt (right singular vectors)	(complex 2*)
+   }
+ 
+   for (index_type i=0; i<p_; ++i)
+     dest(i) = b_d_[i];
+ 
+   return true;
+ }
+ 
+ 
+ 
+ /// prod_uv() is a set of helper routines for produ() and prodv().
+ 
+ /// It is overloaded on Bool_type<Is_complex<T>::value> to handle
+ /// transpose and hermetian properly.  (Tranpose is defined for non-complex
+ /// T, but does not make sense.  Hermetion is only defined for complex
+ /// T).
+ 
+ template <mat_op_type       tr,
+ 	  product_side_type ps,
+ 	  typename          T,
+ 	  typename          Block0,
+ 	  typename          Block1,
+ 	  typename          Block2>
+ inline void
+ prod_uv(
+   const_Matrix<T, Block0> uv,
+   const_Matrix<T, Block1> b,
+   Matrix<T, Block2>       x,
+   Bool_type<false>         /*is_complex*/)
+ {
+   VSIP_IMPL_STATIC_ASSERT(Is_complex<T>::value == false);
+   VSIP_IMPL_STATIC_ASSERT(tr != mat_herm);
+ 
+   if (ps == mat_lside)
+   {
+     if (tr == mat_ntrans)
+     {
+       assert(b.size(0) == uv.size(1));
+       assert(x.size(0) == uv.size(0));
+       assert(b.size(1) == x.size(1));
+       x = prod(uv, b);
+     }
+     else if (tr == mat_trans)
+     {
+       assert(b.size(0) == uv.size(0));
+       assert(x.size(0) == uv.size(1));
+       assert(b.size(1) == x.size(1));
+       x = prod(trans(uv), b);
+     }
+     else if (tr == mat_herm)
+     {
+       assert(false);
+     }
+   }
+   else /* (ps == mat_rside) */
+   {
+     if (tr == mat_ntrans)
+     {
+       assert(b.size(1) == uv.size(0));
+       assert(x.size(1) == uv.size(1));
+       assert(b.size(0) == x.size(0));
+       x = prod(b, uv);
+     }
+     else if (tr == mat_trans)
+     {
+       assert(b.size(1) == uv.size(1));
+       assert(x.size(1) == uv.size(0));
+       assert(b.size(0) == x.size(0));
+       x = prod(b, trans(uv));
+     }
+     else if (tr == mat_herm)
+     {
+       assert(false);
+     }
+   }
+ }
+ 
+ 
+ 
+ template <mat_op_type       tr,
+ 	  product_side_type ps,
+ 	  typename          T,
+ 	  typename          Block0,
+ 	  typename          Block1,
+ 	  typename          Block2>
+ inline void
+ prod_uv(
+   const_Matrix<T, Block0> uv,
+   const_Matrix<T, Block1> b,
+   Matrix<T, Block2>       x,
+   Bool_type<true>         /*is_complex*/)
+ {
+   VSIP_IMPL_STATIC_ASSERT(Is_complex<T>::value == true);
+   VSIP_IMPL_STATIC_ASSERT(tr != mat_trans);
+ 
+   if (ps == mat_lside)
+   {
+     if (tr == mat_ntrans)
+     {
+       assert(b.size(0) == uv.size(1));
+       assert(x.size(0) == uv.size(0));
+       assert(b.size(1) == x.size(1));
+       x = prod(uv, b);
+     }
+     else if (tr == mat_trans)
+     {
+       assert(0);
+     }
+     else if (tr == mat_herm)
+     {
+       assert(b.size(0) == uv.size(0));
+       assert(x.size(0) == uv.size(1));
+       assert(b.size(1) == x.size(1));
+       x = prod(herm(uv), b);
+     }
+   }
+   else /* (ps == mat_rside) */
+   {
+     if (tr == mat_ntrans)
+     {
+       assert(b.size(1) == uv.size(0));
+       assert(x.size(1) == uv.size(1));
+       assert(b.size(0) == x.size(0));
+       x = prod(b, uv);
+     }
+     else if (tr == mat_trans)
+     {
+       assert(0);
+     }
+     else if (tr == mat_herm)
+     {
+       assert(b.size(1) == uv.size(1));
+       assert(x.size(1) == uv.size(0));
+       assert(b.size(0) == x.size(0));
+       x = prod(b, herm(uv));
+     }
+   }
+ }
+ 
+ 
+ 
+ /// Compute product of U and b
+ ///
+ /// If svd_uvpart: U is (m, p)
+ /// If svd_uvfull: U is (m, m)
+ ///
+ /// ustorage   | ps        | tr         | product | b (in) | x (out)
+ /// svd_uvpart | mat_lside | mat_ntrans | U b     | (p, s) | (m, s)
+ /// svd_uvpart | mat_lside | mat_trans  | U' b    | (m, s) | (p, s)
+ /// svd_uvpart | mat_lside | mat_herm   | U* b    | (m, s) | (p, s)
+ ///
+ /// svd_uvpart | mat_rside | mat_ntrans | b U     | (s, m) | (s, p)
+ /// svd_uvpart | mat_rside | mat_trans  | b U'    | (s, p) | (s, m)
+ /// svd_uvpart | mat_rside | mat_herm   | b U*    | (s, p) | (s, m)
+ ///
+ /// svd_uvfull | mat_lside | mat_ntrans | U b     | (m, s) | (m, s)
+ /// svd_uvfull | mat_lside | mat_trans  | U' b    | (m, s) | (m, s)
+ /// svd_uvfull | mat_lside | mat_herm   | U* b    | (m, s) | (m, s)
+ ///
+ /// svd_uvfull | mat_rside | mat_ntrans | b U     | (s, m) | (s, m)
+ /// svd_uvfull | mat_rside | mat_trans  | b U'    | (s, m) | (s, m)
+ /// svd_uvfull | mat_rside | mat_herm   | b U*    | (s, m) | (s, m)
+ 
+ template <typename T,
+ 	  bool     Blocked>
+ template <mat_op_type       tr,
+ 	  product_side_type ps,
+ 	  typename          Block0,
+ 	  typename          Block1>
+ bool
+ Svd_impl<T, Blocked>::impl_produ(
+   const_Matrix<T, Block0> b,
+   Matrix<T, Block1>       x)
+   VSIP_NOTHROW
+ {
+   prod_uv<tr, ps>(this->q_, b, x, Bool_type<Is_complex<T>::value>());
+   return true;
+ }
+ 
+ 
+ 
+ /// Compute product of V and b
+ ///
+ /// Note: product is with V, not V' (unless asked)
+ ///
+ /// If svd_uvpart: V is (n, p)
+ /// If svd_uvfull: V is (n, n)
+ ///
+ /// ustorage   | ps        | tr         | product | b (in) | x (out)
+ /// svd_uvpart | mat_lside | mat_ntrans | V b     | (p, s) | (n, s)
+ /// svd_uvpart | mat_lside | mat_trans  | V' b    | (n, s) | (p, s)
+ /// svd_uvpart | mat_lside | mat_herm   | V* b    | (n, s) | (p, s)
+ ///
+ /// svd_uvpart | mat_rside | mat_ntrans | b V     | (s, n) | (s, p)
+ /// svd_uvpart | mat_rside | mat_trans  | b V'    | (s, p) | (s, n)
+ /// svd_uvpart | mat_rside | mat_herm   | b V*    | (s, p) | (s, n)
+ ///
+ /// svd_uvfull | mat_lside | mat_ntrans | V b     | (n, s) | (n, s)
+ /// svd_uvfull | mat_lside | mat_trans  | V' b    | (n, s) | (n, s)
+ /// svd_uvfull | mat_lside | mat_herm   | V* b    | (n, s) | (n, s)
+ ///
+ /// svd_uvfull | mat_rside | mat_ntrans | b V     | (s, n) | (s, n)
+ /// svd_uvfull | mat_rside | mat_trans  | b V'    | (s, n) | (s, n)
+ /// svd_uvfull | mat_rside | mat_herm   | b V*    | (s, n) | (s, n)
+ 
+ template <typename T,
+ 	  bool     Blocked>
+ template <mat_op_type       tr,
+ 	  product_side_type ps,
+ 	  typename          Block0,
+ 	  typename          Block1>
+ bool
+ Svd_impl<T, Blocked>::impl_prodv(
+   const_Matrix<T, Block0> b,
+   Matrix<T, Block1>       x)
+   VSIP_NOTHROW
+ {
+   prod_uv<tr, ps>(trans_or_herm(this->pt_), b, x,
+ 		  Bool_type<Is_complex<T>::value>());
+   return true;
+ }
+ 
+ 
+ 
+ /// Return the submatrix U containing columns (low .. high) inclusive.
+ 
+ template <typename T,
+ 	  bool     Blocked>
+ template <typename Block>
+ bool
+ Svd_impl<T, Blocked>::impl_u(
+   index_type       low,
+   index_type       high,
+   Matrix<T, Block> u)
+   VSIP_NOTHROW
+ {
+   assert(ust_ == svd_uvpart && high < p_ || ust_ == svd_uvfull && high < m_);
+   assert(u.size(0) == m_);
+   assert(u.size(1) == high - low + 1);
+ 
+   u = q_(Domain<2>(m_, Domain<1>(low, 1, high-low+1)));
+ 
+   return true;
+ }
+ 
+ 
+ 
+ /// Return the submatrix V containing columns (low .. high) inclusive.
+ 
+ template <typename T,
+ 	  bool     Blocked>
+ template <typename Block>
+ bool
+ Svd_impl<T, Blocked>::impl_v(
+   index_type       low,
+   index_type       high,
+   Matrix<T, Block> v)
+   VSIP_NOTHROW
+ {
+   assert(vst_ == svd_uvpart && high < p_ || vst_ == svd_uvfull && high < n_);
+   assert(v.size(0) == n_);
+   assert(v.size(1) == high - low + 1);
+ 
+   v = trans_or_herm(pt_(Domain<2>(Domain<1>(low, 1, high-low+1), n_)));
+ 
+   return true;
+ }
+ 
+ } // namespace vsip::impl
+ 
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_SOLVER_SVD_HPP
Index: src/vsip/impl/subblock.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/subblock.hpp,v
retrieving revision 1.33
diff -c -p -r1.33 subblock.hpp
*** src/vsip/impl/subblock.hpp	26 Sep 2005 20:11:05 -0000	1.33
--- src/vsip/impl/subblock.hpp	27 Sep 2005 16:28:28 -0000
*************** class Diag_block 
*** 1541,1547 ****
      }
    length_type size(dimension_type block_d, dimension_type d) const VSIP_NOTHROW
      { 
!       assert(dim == 1 && d == 0);
        return std::min( this->blk_->size(2, 0),
          this->blk_->size(2, 1) );
      }
--- 1541,1547 ----
      }
    length_type size(dimension_type block_d, dimension_type d) const VSIP_NOTHROW
      { 
!       assert(block_d == 1 && dim == 1 && d == 0);
        return std::min( this->blk_->size(2, 0),
          this->blk_->size(2, 1) );
      }
Index: tests/solver-common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-common.hpp,v
retrieving revision 1.4
diff -c -p -r1.4 solver-common.hpp
*** tests/solver-common.hpp	26 Sep 2005 20:11:05 -0000	1.4
--- tests/solver-common.hpp	27 Sep 2005 16:28:28 -0000
*************** struct Test_traits
*** 50,55 ****
--- 50,57 ----
    static T value2() { return T(0.5);  }
    static T value3() { return T(-0.5); }
    static T conj(T a) { return a; }
+ 
+   static vsip::mat_op_type const trans = vsip::mat_trans;
  };
  
  template <typename T>
*************** struct Test_traits<vsip::complex<T> >
*** 60,65 ****
--- 62,69 ----
    static vsip::complex<T> value2() { return vsip::complex<T>(0.5, 1); }
    static vsip::complex<T> value3() { return vsip::complex<T>(1, -1); }
    static vsip::complex<T> conj(vsip::complex<T> a) { return vsip::conj(a); }
+ 
+   static vsip::mat_op_type const trans = vsip::mat_herm;
  };
  
  
*************** prodh(
*** 174,177 ****
--- 178,236 ----
      }
  }
  
+ 
+ 
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2>
+ void
+ compare_view(
+   vsip::const_Vector<T, Block1>           a,
+   vsip::const_Vector<T, Block2>           b,
+   typename vsip::impl::Scalar_of<T>::type thresh
+   )
+ {
+   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+ 
+   vsip::Index<1> idx;
+   scalar_type err = vsip::maxval((mag(a - b)
+ 				  / Precision_traits<scalar_type>::eps),
+ 				 idx);
+ 
+   if (err > thresh)
+   {
+     for (vsip::index_type r=0; r<a.size(0); ++r)
+ 	assert(equal(a.get(r), b.get(r)));
+   }
+ }
+ 
+ 
+ 
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2>
+ void
+ compare_view(
+   vsip::const_Matrix<T, Block1>           a,
+   vsip::const_Matrix<T, Block2>           b,
+   typename vsip::impl::Scalar_of<T>::type thresh
+   )
+ {
+   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+ 
+   vsip::Index<2> idx;
+   scalar_type err = vsip::maxval((mag(a - b)
+ 				  / Precision_traits<scalar_type>::eps),
+ 				 idx);
+ 
+   if (err > thresh)
+   {
+     std::cout << "a = \n" << a;
+     std::cout << "b = \n" << b;
+     for (vsip::index_type r=0; r<a.size(0); ++r)
+       for (vsip::index_type c=0; c<a.size(1); ++c)
+ 	assert(equal(a.get(r, c), b.get(r, c)));
+   }
+ }
+ 
  #endif // VSIP_TESTS_SOLVER_COMMON_HPP
Index: tests/solver-svd.cpp
===================================================================
RCS file: tests/solver-svd.cpp
diff -N tests/solver-svd.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/solver-svd.cpp	27 Sep 2005 16:28:29 -0000
***************
*** 0 ****
--- 1,545 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    tests/solver-svd.cpp
+     @author  Jules Bergmann
+     @date    2005-09-12
+     @brief   VSIPL++ Library: Unit tests SVD solver.
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
+   Support
+ ***********************************************************************/
+ 
+ template <typename T,
+ 	  typename Block>
+ typename vsip::impl::Scalar_of<T>::type
+ norm_1(const_Vector<T, Block> v)
+ {
+   return sumval(mag(v));
+ }
+ 
+ 
+ 
+ /// Matrix norm-1
+ 
+ template <typename T,
+ 	  typename Block>
+ typename vsip::impl::Scalar_of<T>::type
+ norm_1(const_Matrix<T, Block> m)
+ {
+   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+   scalar_type norm = sumval(mag(m.col(0)));
+ 
+   for (index_type j=1; j<m.size(1); ++j)
+   {
+     norm = std::max(norm, sumval(mag(m.col(j))));
+   }
+ 
+   return norm;
+ }
+ 
+ 
+ 
+ /// Matrix norm-infinity
+ 
+ template <typename T,
+ 	  typename Block>
+ typename vsip::impl::Scalar_of<T>::type
+ norm_inf(const_Matrix<T, Block> m)
+ {
+   return norm_1(m.transpose());
+ }
+ 
+ 
+ 
+ /***********************************************************************
+   svd function tests
+ ***********************************************************************/
+ 
+ template <typename              T,
+ 	  typename              Block0,
+ 	  typename              Block1,
+ 	  typename              Block2,
+ 	  typename              Block3>
+ void
+ apply_svd(
+   svd<T, by_reference>&    sv,
+   Matrix<T, Block0>        a,
+   Vector<scalar_f, Block1> sv_s,
+   Matrix<T, Block2>        sv_u,
+   Matrix<T, Block3>        sv_v)
+ {
+   length_type m = sv.rows();
+   length_type n = sv.columns();
+   length_type p = std::min(m, n);
+   length_type u_columns = sv.ustorage() == svd_uvfull ? m : p;
+   length_type v_rows    = sv.vstorage() == svd_uvfull ? n : p;
+ 
+   sv.decompose(a, sv_s);
+   if (sv.ustorage() != svd_uvnos)
+     sv.u(0, u_columns-1, sv_u);
+   if (sv.vstorage() != svd_uvnos)
+     sv.v(0, v_rows-1,    sv_v);
+ }
+ 
+ 
+ 
+ template <typename              T,
+ 	  typename              Block0,
+ 	  typename              Block1,
+ 	  typename              Block2,
+ 	  typename              Block3>
+ void
+ apply_svd(
+   svd<T, by_value>&        sv,
+   Matrix<T, Block0>        a,
+   Vector<scalar_f, Block1> sv_s,
+   Matrix<T, Block2>        sv_u,
+   Matrix<T, Block3>        sv_v)
+ {
+   length_type m = sv.rows();
+   length_type n = sv.columns();
+   length_type p = std::min(m, n);
+   length_type u_columns = sv.ustorage() == svd_uvfull ? m : p;
+   length_type v_rows    = sv.vstorage() == svd_uvfull ? n : p;
+ 
+   sv_s = sv.decompose(a);
+   if (sv.ustorage() != svd_uvnos)
+     sv_u = sv.u(0, u_columns-1);
+   if (sv.vstorage() != svd_uvnos)
+     sv_v = sv.v(0, v_rows-1);
+ }
+ 
+ 
+ 
+ template <mat_op_type       tr,
+ 	  product_side_type ps,
+ 	  typename          T,
+ 	  typename          Block0,
+ 	  typename          Block1>
+ void
+ apply_svd_produ(
+   svd<T, by_reference>&    sv,
+   const_Matrix<T, Block0>  b,
+   Matrix<T, Block1>        produ)
+ {
+   sv.template produ<tr, ps>(b, produ);
+ }
+ 
+ 
+ 
+ template <mat_op_type       tr,
+ 	  product_side_type ps,
+ 	  typename          T,
+ 	  typename          Block0,
+ 	  typename          Block1>
+ void
+ apply_svd_produ(
+   svd<T, by_value>&        sv,
+   const_Matrix<T, Block0>  b,
+   Matrix<T, Block1>        produ)
+ {
+   produ = sv.template produ<tr, ps>(b);
+ }
+ 
+ 
+ 
+ template <mat_op_type       tr,
+ 	  product_side_type ps,
+ 	  typename          T,
+ 	  typename          Block0,
+ 	  typename          Block1>
+ void
+ apply_svd_prodv(
+   svd<T, by_reference>&    sv,
+   const_Matrix<T, Block0>  b,
+   Matrix<T, Block1>        prodv)
+ {
+   sv.template prodv<tr, ps>(b, prodv);
+ }
+ 
+ 
+ 
+ template <mat_op_type       tr,
+ 	  product_side_type ps,
+ 	  typename          T,
+ 	  typename          Block0,
+ 	  typename          Block1>
+ void
+ apply_svd_prodv(
+   svd<T, by_value>&        sv,
+   const_Matrix<T, Block0>  b,
+   Matrix<T, Block1>        prodv)
+ {
+   prodv = sv.template prodv<tr, ps>(b);
+ }
+ 
+ 
+ 
+ template <return_mechanism_type RtM,
+ 	  typename              T,
+ 	  typename              Block>
+ void
+ test_svd(
+   storage_type     ustorage,
+   storage_type     vstorage,
+   Matrix<T, Block> a,
+   length_type      loop)
+ {
+   using vsip::impl::trans_or_herm;
+   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+ 
+   length_type m = a.size(0);
+   length_type n = a.size(1);
+ 
+   length_type p = std::min(m, n);
+   assert(m > 0 && n > 0);
+ 
+   length_type u_cols = ustorage == svd_uvfull ? m : p;
+   length_type v_cols = vstorage == svd_uvfull ? n : p;
+ 
+   Vector<float> sv_s(p);		// singular values
+   Matrix<T>     sv_u(m, u_cols);	// U matrix
+   Matrix<T>     sv_v(n, v_cols);	// V matrix
+ 
+   svd<T, RtM> sv(m, n, ustorage, vstorage);
+ 
+   assert(sv.rows()     == m);
+   assert(sv.columns()  == n);
+   assert(sv.ustorage() == ustorage);
+   assert(sv.vstorage() == vstorage);
+ 
+   for (index_type i=0; i<loop; ++i)
+   {
+     apply_svd(sv, a, sv_s, sv_u, sv_v);
+ 
+     // Check that sv_sv is non-increasing.
+     for (index_type i=0; i<p-1; ++i)
+       assert(sv_s(i) >= sv_s(i+1));
+ 
+     // Check that product of u, s, v equals a.
+     if (ustorage != svd_uvnos && vstorage != svd_uvnos)
+     {
+       Matrix<T> sv_sm(m, n, T());
+       sv_sm.diag() = sv_s;
+ 
+       Matrix<T> chk(m, n);
+       if (ustorage == svd_uvfull && vstorage == svd_uvfull)
+       {
+ 	chk = prod(prod(sv_u, sv_sm), trans_or_herm(sv_v));
+       }
+       else
+       {
+ 	chk = prod(prod(sv_u(Domain<2>(m, p)), sv_sm(Domain<2>(p, p))),
+ 		   trans_or_herm(sv_v(Domain<2>(n, p))));
+       }
+ 
+       Index<2> idx;
+       scalar_type err = maxval((mag(chk - a)
+ 			      / Precision_traits<scalar_type>::eps),
+ 			     idx);
+       scalar_type errx = maxval(mag(chk - a), idx);
+       scalar_type norm_est = std::sqrt(norm_1(a) * norm_inf(a));
+       
+       err  = err / norm_est;
+       errx = errx / norm_est;
+ 
+ #if VERBOSE
+       cout << "a    = " << endl << a  << endl;
+       cout << "sv_s = " << endl << sv_s << endl;
+       cout << "sv_u = " << endl << sv_u << endl;
+       cout << "sv_v = " << endl << sv_v << endl;
+       cout << "chk  = " << endl << chk << endl;
+       cout << "err = " << err << "   "
+ 	   << "norm = " << norm_est << endl;
+       cout << "eps = " << Precision_traits<scalar_type>::eps << endl;
+       cout << "p:" << p << "   "
+ 	   << "err = " << err   << "   "
+ 	   << "errx = " << errx << endl;
+ #endif
+ 
+       if (err > 5.0)
+       {
+ 	for (index_type r=0; r<m; ++r)
+ 	  for (index_type c=0; c<n; ++c)
+ 	    assert(equal(chk(r, c), a(r, c)));
+       }
+     }
+ 
+     const length_type chk_single_uv = 2;
+ 
+     if (ustorage != svd_uvnos)
+     {
+       length_type u_cols = (ustorage == svd_uvfull) ? m : p;
+ 
+       Matrix<T> in_m (m,      m,    T());
+       Matrix<T> in_p (u_cols, u_cols, T());
+ 
+       Matrix<T> pu_nl(m,      u_cols, T());
+       Matrix<T> pu_tl(u_cols, m,      T());
+       Matrix<T> pu_nr(m,      u_cols, T());
+       Matrix<T> pu_tr(u_cols, m,      T());
+ 
+       Vector<T> zero_m(m, T());
+       Vector<T> zero_p(u_cols, T());
+ 
+       index_type pos = 0;
+       for (index_type i=0; i<chk_single_uv; ++i, pos = (17*pos+5)%u_cols)
+       {
+ 	in_m(pos, pos) = T(1);
+ 	in_p(pos, pos) = T(1);
+       
+ 	apply_svd_produ<mat_ntrans,            mat_lside>(sv, in_p, pu_nl);
+ 	apply_svd_produ<Test_traits<T>::trans, mat_lside>(sv, in_m, pu_tl);
+ 	apply_svd_produ<mat_ntrans,            mat_rside>(sv, in_m, pu_nr);
+ 	apply_svd_produ<Test_traits<T>::trans, mat_rside>(sv, in_p, pu_tr);
+ 
+ 	compare_view(pu_nl.col(pos), sv_u.col(pos), 5.0);
+ 	compare_view(pu_tl.col(pos), trans_or_herm(sv_u).col(pos), 5.0);
+ 	compare_view(pu_nr.row(pos), sv_u.row(pos), 5.0);
+ 	compare_view(pu_tr.row(pos), trans_or_herm(sv_u).row(pos), 5.0);
+ 
+ 	for (index_type j=0; j<u_cols; ++j)
+ 	{
+ 	  if (j != pos)
+ 	  {
+ 	    compare_view(pu_nl.col(j), zero_m, 5.0);
+ 	    compare_view(pu_tl.col(j), zero_p, 5.0);
+ 	    compare_view(pu_nr.row(j), zero_p, 5.0);
+ 	    compare_view(pu_tr.row(j), zero_m, 5.0);
+ 	  }
+ 	}
+ 	in_m(pos, pos) = T();
+ 	in_p(pos, pos) = T();
+       }
+     }
+ 
+     if (vstorage != svd_uvnos)
+     {
+       length_type v_cols = (vstorage == svd_uvfull) ? n : p;
+ 
+       Matrix<T> in_p (v_cols, v_cols, T());
+       Matrix<T> in_n (n,      n,      T());
+ 
+       Matrix<T> pv_nl(n,      v_cols, T());
+       Matrix<T> pv_tl(v_cols, n,      T());
+       Matrix<T> pv_nr(n,      v_cols, T());
+       Matrix<T> pv_tr(v_cols, n,      T());
+       
+       Vector<T> zero_n(n,      T());
+       Vector<T> zero_p(v_cols, T());
+       
+       index_type pos = 0;
+       for (index_type i=0; i<chk_single_uv; ++i, pos = (17*pos+5)%v_cols)
+       {
+ 	in_p(pos, pos) = T(1);
+ 	in_n(pos, pos) = T(1);
+       
+ 	apply_svd_prodv<mat_ntrans,            mat_lside>(sv, in_p, pv_nl);
+ 	apply_svd_prodv<Test_traits<T>::trans, mat_lside>(sv, in_n, pv_tl);
+ 	apply_svd_prodv<mat_ntrans,            mat_rside>(sv, in_n, pv_nr);
+ 	apply_svd_prodv<Test_traits<T>::trans, mat_rside>(sv, in_p, pv_tr);
+ 
+ 	compare_view(pv_nl.col(pos), sv_v.col(pos), 5.0);
+ 	compare_view(pv_tl.col(pos), trans_or_herm(sv_v).col(pos), 5.0);
+ 	compare_view(pv_nr.row(pos), sv_v.row(pos), 5.0);
+ 	compare_view(pv_tr.row(pos), trans_or_herm(sv_v).row(pos), 5.0);
+ 	
+ 	for (index_type j=0; j<v_cols; ++j)
+ 	{
+ 	  if (j != pos)
+ 	  {
+ 	    compare_view(pv_nl.col(j), zero_n, 5.0);
+ 	    compare_view(pv_tl.col(j), zero_p, 5.0);
+ 	    compare_view(pv_nr.row(j), zero_p, 5.0);
+ 	    compare_view(pv_tr.row(j), zero_n, 5.0);
+ 	  }
+ 	}
+ 	in_p(pos, pos) = T();
+ 	in_n(pos, pos) = T();
+       }
+     }
+ 
+     // Solver a different problem next iteration.
+     a(0, 0) = a(0, 0) + T(1);
+   }
+ }
+ 
+ 
+ 
+ // Description:
+ 
+ template <return_mechanism_type RtM,
+ 	  typename              T>
+ void
+ test_svd_ident(
+   storage_type ustorage,
+   storage_type vstorage,
+   length_type  m,
+   length_type  n,
+   length_type  loop)
+ {
+   length_type p = std::min(m, n);
+   assert(m > 0 && n > 0);
+ 
+   Matrix<T>     a(m, n);
+   Vector<float> sv_s(p);	// singular values
+   Matrix<T>     sv_u(m, m);	// U matrix
+   Matrix<T>     sv_v(n, n);	// V matrix
+ 
+   // Setup a.
+   a        = T();
+   a.diag() = T(1);
+   if (p > 0) a(0, 0)  = Test_traits<T>::value1();
+   if (p > 2) a(2, 2)  = Test_traits<T>::value2();
+   if (p > 3) a(3, 3)  = Test_traits<T>::value3();
+ 
+   test_svd<RtM>(ustorage, vstorage, a, loop);
+ }
+ 
+ 
+ 
+ template <return_mechanism_type RtM,
+ 	  typename              T>
+ void
+ test_svd_rand(
+   storage_type ustorage,
+   storage_type vstorage,
+   length_type  m,
+   length_type  n,
+   length_type  loop)
+ {
+   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+ 
+   length_type p = std::min(m, n);
+   assert(m > 0 && n > 0);
+ 
+   Matrix<T>     a(m, n);
+   Vector<float> sv_s(p);	// singular values
+   Matrix<T>     sv_u(m, m);	// U matrix
+   Matrix<T>     sv_v(n, n);	// U matrix
+ 
+   // Setup a.
+   randm(a);
+ 
+   test_svd<RtM>(ustorage, vstorage, a, loop);
+ }
+ 
+ 
+ 
+ template <return_mechanism_type RtM,
+ 	  typename              T>
+ void svd_cases(
+   storage_type ustorage,
+   storage_type vstorage,
+   length_type  loop)
+ {
+   test_svd_ident<RtM, T>(ustorage, vstorage, 1, 1, loop);
+   test_svd_ident<RtM, T>(ustorage, vstorage, 1, 7, loop);
+   test_svd_ident<RtM, T>(ustorage, vstorage, 9, 1, loop);
+ 
+   test_svd_ident<RtM, T>(ustorage, vstorage, 5,   5, loop);
+   test_svd_ident<RtM, T>(ustorage, vstorage, 16,  5, loop);
+   test_svd_ident<RtM, T>(ustorage, vstorage, 3,  20, loop);
+ 
+   test_svd_rand<RtM, T>(ustorage, vstorage, 5, 5, loop);
+   test_svd_rand<RtM, T>(ustorage, vstorage, 5, 3, loop);
+   test_svd_rand<RtM, T>(ustorage, vstorage, 3, 5, loop);
+ #if DO_FULL
+   test_svd_rand<RtM, T>(ustorage, vstorage, 17, 5, loop);
+   test_svd_rand<RtM, T>(ustorage, vstorage, 5, 17, loop);
+   test_svd_rand<RtM, T>(ustorage, vstorage, 17, 19, loop);
+   test_svd_rand<RtM, T>(ustorage, vstorage, 25, 27, loop);
+   test_svd_rand<RtM, T>(ustorage, vstorage, 32, 32, loop);
+   test_svd_rand<RtM, T>(ustorage, vstorage, 8, 32, loop);
+   test_svd_rand<RtM, T>(ustorage, vstorage, 32, 10, loop);
+ #endif
+ }
+ 
+ 
+ 
+ template <return_mechanism_type RtM>
+ void
+ svd_types(
+   storage_type ustorage,
+   storage_type vstorage,
+   length_type  loop)
+ {
+   svd_cases<RtM, float>(ustorage, vstorage, loop);
+   svd_cases<RtM, double>(ustorage, vstorage, loop);
+   svd_cases<RtM, complex<float> >(ustorage, vstorage, loop);
+   svd_cases<RtM, complex<double> >(ustorage, vstorage, loop);
+ }
+ 
+ 
+ 
+ template <return_mechanism_type RtM>
+ void
+ svd_storage(
+   length_type  loop)
+ {
+   svd_types<RtM>(svd_uvfull, svd_uvfull, loop);
+   svd_types<RtM>(svd_uvpart, svd_uvfull, loop);
+   svd_types<RtM>(svd_uvnos,  svd_uvfull, loop);
+   svd_types<RtM>(svd_uvfull, svd_uvpart, loop);
+   svd_types<RtM>(svd_uvpart, svd_uvpart, loop);
+   svd_types<RtM>(svd_uvnos,  svd_uvpart, loop);
+   svd_types<RtM>(svd_uvfull, svd_uvnos, loop);
+   svd_types<RtM>(svd_uvpart, svd_uvnos, loop);
+   svd_types<RtM>(svd_uvnos,  svd_uvnos, loop);
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
+   length_type loop = 2;
+ 
+   svd_storage<by_reference>(loop);
+   svd_storage<by_value>    (loop);
+ }
