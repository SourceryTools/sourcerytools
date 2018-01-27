? ChangeLog.new
? config.log
? src/vsip/impl/.nfs0000000000181e83000003d5
? src/vsip/impl/.sal.hpp.swp
? src/vsip/impl/my_patch
? src/vsip/impl/sal/.nfs000000000018e03f000003d6
? tests/.solver-lu.cpp.swp
? tests/Makefile.in
? tests/solver-cpp.mine
? vendor/atlas/autom4te.cache
? vendor/atlas/configure
? vendor/atlas/CONFIG/acconfig.hpp.in
? vendor/atlas/bin/Makefile.in
? vendor/atlas/interfaces/blas/C/src/Makefile.in
? vendor/atlas/interfaces/blas/C/testing/Makefile.in
? vendor/atlas/interfaces/blas/F77/src/Makefile.in
? vendor/atlas/interfaces/blas/F77/testing/Makefile.in
? vendor/atlas/interfaces/lapack/C/src/Makefile.in
? vendor/atlas/interfaces/lapack/F77/src/Makefile.in
? vendor/atlas/lib/Makefile.in
? vendor/atlas/src/auxil/Makefile.in
? vendor/atlas/src/blas/gemm/Make.inc.in
? vendor/atlas/src/blas/gemm/Makefile.in
? vendor/atlas/src/blas/gemm/GOTO/Makefile.in
? vendor/atlas/src/blas/gemv/Make.inc.in
? vendor/atlas/src/blas/gemv/Makefile.in
? vendor/atlas/src/blas/ger/Make.inc.in
? vendor/atlas/src/blas/ger/Makefile.in
? vendor/atlas/src/blas/level1/Make.inc.in
? vendor/atlas/src/blas/level1/Makefile.in
? vendor/atlas/src/blas/level2/Makefile.in
? vendor/atlas/src/blas/level2/kernel/Makefile.in
? vendor/atlas/src/blas/level3/Makefile.in
? vendor/atlas/src/blas/level3/kernel/Makefile.in
? vendor/atlas/src/blas/level3/rblas/Makefile.in
? vendor/atlas/src/blas/pklevel3/Makefile.in
? vendor/atlas/src/blas/pklevel3/gpmm/Makefile.in
? vendor/atlas/src/blas/pklevel3/sprk/Makefile.in
? vendor/atlas/src/blas/reference/level1/Makefile.in
? vendor/atlas/src/blas/reference/level2/Makefile.in
? vendor/atlas/src/blas/reference/level3/Makefile.in
? vendor/atlas/src/lapack/Makefile.in
? vendor/atlas/src/pthreads/blas/level1/Makefile.in
? vendor/atlas/src/pthreads/blas/level2/Makefile.in
? vendor/atlas/src/pthreads/blas/level3/Makefile.in
? vendor/atlas/src/pthreads/misc/Makefile.in
? vendor/atlas/src/testing/Makefile.in
? vendor/atlas/tune/blas/gemm/Makefile.in
? vendor/atlas/tune/blas/gemv/Makefile.in
? vendor/atlas/tune/blas/ger/Makefile.in
? vendor/atlas/tune/blas/level1/Makefile.in
? vendor/atlas/tune/blas/level3/Makefile.in
? vendor/atlas/tune/sysinfo/Makefile.in
Index: src/vsip/solvers.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/solvers.hpp,v
retrieving revision 1.6
diff -u -r1.6 solvers.hpp
--- src/vsip/solvers.hpp	30 Sep 2005 21:43:07 -0000	1.6
+++ src/vsip/solvers.hpp	12 Apr 2006 00:50:19 -0000
@@ -17,7 +17,11 @@
 #include <vsip/impl/solver-qr.hpp>
 #include <vsip/impl/solver-covsol.hpp>
 #include <vsip/impl/solver-llsqsol.hpp>
+#ifdef VSIP_IMPL_USE_SAL_SOL
+#include <vsip/impl/sal/solver_lu.hpp>
+#else
 #include <vsip/impl/solver-lu.hpp>
+#endif
 #include <vsip/impl/solver-cholesky.hpp>
 #include <vsip/impl/solver-svd.hpp>
 #include <vsip/impl/solver-toepsol.hpp>
Index: src/vsip/impl/sal.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal.hpp,v
retrieving revision 1.5
diff -u -r1.5 sal.hpp
--- src/vsip/impl/sal.hpp	7 Mar 2006 02:15:22 -0000	1.5
+++ src/vsip/impl/sal.hpp	12 Apr 2006 00:50:19 -0000
@@ -27,6 +27,12 @@
 #include <vsip/impl/extdata.hpp>
 #include <sal.h>
 
+// help defines
+#define SAL_SOL_FLAG(f) ( ((f=='N') || (f=='n'))? SAL_NORMAL_SOLVER:    \
+                          ((f=='T') || (f=='t'))? SAL_TRANSPOSE_SOLVER: \
+			  SAL_TRANSPOSE_SOLVER \
+                        )
+
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -609,6 +615,46 @@
 VSIP_IMPL_SAL_CONV_SPLIT( float, COMPLEX_SPLIT, zconvx, 1 );
 
 
+// LUD decomposition functions
+#define VSIP_IMPL_SAL_LUD_DEC( T, D_T, SAL_T, SALFCN ) \
+inline bool                          \
+sal_mat_lud_dec(                     \
+  T *c, int ctcols,                  \
+  D_T *d, int n)                     \
+{                                    \
+  return (SALFCN(                     \
+   (SAL_T*) c, ctcols,               \
+   (D_T*) d, n,                      \
+   NULL, NULL, SAL_COND_EST_NONE) == SAL_SUCCESS); \
+}
+
+// Declare LUD decomposition functions
+VSIP_IMPL_SAL_LUD_DEC(float,         int,float,  mat_lud_dec)
+VSIP_IMPL_SAL_LUD_DEC(complex<float>,int,COMPLEX,cmat_lud_dec)
+
+#undef VSIP_IMPL_SAL_LUD_DEC
+
+
+// LUD solver functions
+#define VSIP_IMPL_SAL_LUD_SOL( T, D_T, SAL_T, SALFCN ) \
+inline bool                          \
+sal_mat_lud_sol(                     \
+  T *a, int atcols,                  \
+  D_T *d, T *b, T *w,                \
+  int n,char flag)                   \
+{                                    \
+  return (SALFCN(                     \
+   (SAL_T*) a, atcols,               \
+   (D_T*) d,(SAL_T*)b,(SAL_T*)w,     \
+   n,SAL_SOL_FLAG(flag)) == SAL_SUCCESS);            \
+}
+
+// Declare LUD decomposition functions
+VSIP_IMPL_SAL_LUD_SOL(float,         int,float,  mat_lud_sol)
+VSIP_IMPL_SAL_LUD_SOL(complex<float>,int,COMPLEX,cmat_lud_sol)
+
+#undef VSIP_IMPL_SAL_LUD_SOL
+
 
 
 
Index: src/vsip/impl/solver-lu.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-lu.hpp,v
retrieving revision 1.3
diff -u -r1.3 solver-lu.hpp
--- src/vsip/impl/solver-lu.hpp	10 Feb 2006 22:24:02 -0000	1.3
+++ src/vsip/impl/solver-lu.hpp	12 Apr 2006 00:50:19 -0000
@@ -83,6 +83,7 @@
 
 } // namespace vsip::impl
 
+#ifndef VSIP_IMPL_USE_SAL_SOL
 
 
 /// LU solver object.
@@ -154,6 +155,7 @@
 };
 
 
+#endif
 
 /***********************************************************************
   Definitions
Index: src/vsip/impl/sal/solver_lu.hpp
===================================================================
RCS file: src/vsip/impl/sal/solver_lu.hpp
diff -N src/vsip/impl/sal/solver_lu.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/sal/solver_lu.hpp	12 Apr 2006 00:50:19 -0000
@@ -0,0 +1,463 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/sal/solver_lu.hpp
+    @author  Assem Salama
+    @date    2006-04-04
+    @brief   VSIPL++ Library: LU linear system solver using SAL.
+
+*/
+
+#ifndef VSIP_IMPL_SOLVER_LU_SAL_HPP
+#define VSIP_IMPL_SOLVER_LU_SAL_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <algorithm>
+
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/impl/math-enum.hpp>
+#include <vsip/impl/temp_buffer.hpp>
+#include <vsip/impl/working-view.hpp>
+#include <vsip/impl/fns_elementwise.hpp>
+#include <vsip/impl/sal.hpp>
+
+// We still need normal solver because SAL solver doesn't support double
+#include <vsip/impl/solver-lu.hpp>
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+namespace sal
+{
+
+/// LU factorization implementation class.  Common functionality
+/// for lud by-value and by-reference classes.
+
+template <typename T>
+class Lud_impl
+  //: Compile_time_assert<blas::Blas_traits<T>::valid>
+{
+  // The input matrix must be in ROW major form. We want the b matrix
+  // to be in COL major form because we need to call the SAL function for
+  // each column in the b matrix.
+  typedef Layout<2, row2_type, Stride_unit_dense, Cmplx_inter_fmt> data_LP;
+  typedef Fast_block<2, T, data_LP> data_block_type;
+
+  typedef Layout<2, col2_type, Stride_unit_dense, Cmplx_inter_fmt> b_data_LP;
+  typedef Fast_block<2, T, b_data_LP> b_data_block_type;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  Lud_impl(length_type)
+    VSIP_THROW((std::bad_alloc));
+  Lud_impl(Lud_impl const&)
+    VSIP_THROW((std::bad_alloc));
+
+  Lud_impl& operator=(Lud_impl const&) VSIP_NOTHROW;
+  ~Lud_impl() VSIP_NOTHROW;
+
+  // Accessors.
+public:
+  length_type length()const VSIP_NOTHROW { return length_; }
+
+  // Solve systems.
+public:
+  template <typename Block>
+  bool decompose(Matrix<T, Block>) VSIP_NOTHROW;
+
+protected:
+  template <mat_op_type tr,
+	    typename    Block0,
+	    typename    Block1>
+  bool impl_solve(const_Matrix<T, Block0>, Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  // Member data.
+private:
+  typedef std::vector<int, Aligned_allocator<int> > vector_type;
+
+  length_type  length_;			// Order of A.
+  vector_type  ipiv_;			// Additional info on Q
+
+  Matrix<T, data_block_type> data_;	// Factorized matrix (A)
+};
+
+} // namespace vsip::impl::sal
+} // namespace vsip::impl
+
+
+/// LU solver object.
+
+template <typename              T               = VSIP_DEFAULT_VALUE_TYPE,
+	  return_mechanism_type ReturnMechanism = by_value>
+class lud;
+
+
+
+/// LU solver object (by-reference).
+
+template <typename T>
+class lud<T, by_reference>
+  : public impl::sal::Lud_impl<T>
+{
+  typedef impl::sal::Lud_impl<T> base_type;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  lud(length_type length)
+    VSIP_THROW((std::bad_alloc))
+      : base_type(length)
+    {}
+
+  ~lud() VSIP_NOTHROW {}
+
+  // By-reference solvers.
+public:
+  template <mat_op_type tr,
+	    typename    Block0,
+	    typename    Block1>
+  bool solve(const_Matrix<T, Block0> b, Matrix<T, Block1> x)
+    VSIP_NOTHROW
+  { return this->template impl_solve<tr, Block0, Block1>(b, x); }
+};
+
+
+
+/// LU solver object (by-value).
+
+template <typename T>
+class lud<T, by_value>
+  : public impl::sal::Lud_impl<T>
+{
+  typedef impl::sal::Lud_impl<T> base_type;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  lud(length_type length)
+    VSIP_THROW((std::bad_alloc))
+      : base_type(length)
+    {}
+
+  ~lud() VSIP_NOTHROW {}
+
+  // By-value solvers.
+public:
+  template <mat_op_type tr,
+	    typename    Block0>
+  Matrix<T>
+  solve(const_Matrix<T, Block0> b)
+    VSIP_NOTHROW
+  {
+    Matrix<T> x(b.size(0), b.size(1));
+    this->template impl_solve<tr>(b, x); 
+    return x;
+  }
+};
+
+
+/// LU solver object double (by-reference).
+
+template <>
+class lud<double, by_reference>
+  : public impl::Lud_impl<double>
+{
+  typedef impl::Lud_impl<double> base_type;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  lud(length_type length)
+    VSIP_THROW((std::bad_alloc))
+      : base_type(length)
+    {}
+
+  ~lud() VSIP_NOTHROW {}
+
+  // By-reference solvers.
+public:
+  template <mat_op_type tr,
+	    typename    Block0,
+	    typename    Block1>
+  bool solve(const_Matrix<double, Block0> b, Matrix<double, Block1> x)
+    VSIP_NOTHROW
+  { return this->template impl_solve<tr, Block0, Block1>(b, x); }
+};
+
+/// LU solver object double (by-value).
+
+template <>
+class lud<double, by_value>
+  : public impl::Lud_impl<double>
+{
+  typedef impl::Lud_impl<double> base_type;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  lud(length_type length)
+    VSIP_THROW((std::bad_alloc))
+      : base_type(length)
+    {}
+
+  ~lud() VSIP_NOTHROW {}
+
+  // By-value solvers.
+public:
+  template <mat_op_type tr,
+	    typename    Block0>
+  Matrix<double>
+  solve(const_Matrix<double, Block0> b)
+    VSIP_NOTHROW
+  {
+    Matrix<double> x(b.size(0), b.size(1));
+    this->template impl_solve<tr>(b, x); 
+    return x;
+  }
+};
+
+/// LU solver object complex double (by-reference).
+
+template <>
+class lud<complex<double>, by_reference>
+  : public impl::Lud_impl<complex<double> >
+{
+  typedef impl::Lud_impl<complex<double> > base_type;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  lud(length_type length)
+    VSIP_THROW((std::bad_alloc))
+      : base_type(length)
+    {}
+
+  ~lud() VSIP_NOTHROW {}
+
+  // By-reference solvers.
+public:
+  template <mat_op_type tr,
+	    typename    Block0,
+	    typename    Block1>
+  bool solve(const_Matrix<complex<double> , Block0> b, Matrix<complex<double> , Block1> x)
+    VSIP_NOTHROW
+  { return this->template impl_solve<tr, Block0, Block1>(b, x); }
+};
+
+/// LU solver object complex double (by-value).
+
+template <>
+class lud<complex<double> , by_value>
+  : public impl::Lud_impl<complex<double> >
+{
+  typedef impl::Lud_impl<complex<double> > base_type;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  lud(length_type length)
+    VSIP_THROW((std::bad_alloc))
+      : base_type(length)
+    {}
+
+  ~lud() VSIP_NOTHROW {}
+
+  // By-value solvers.
+public:
+  template <mat_op_type tr,
+	    typename    Block0>
+  Matrix<complex<double> >
+  solve(const_Matrix<complex<double> , Block0> b)
+    VSIP_NOTHROW
+  {
+    Matrix<complex<double> > x(b.size(0), b.size(1));
+    this->template impl_solve<tr>(b, x); 
+    return x;
+  }
+};
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace impl
+{
+namespace sal
+{
+
+template <typename T>
+Lud_impl<T>::Lud_impl(
+  length_type length
+  )
+VSIP_THROW((std::bad_alloc))
+  : length_ (length),
+    ipiv_   (length_),
+    data_   (length_, length_)
+{
+  assert(length_ > 0);
+}
+
+
+
+template <typename T>
+Lud_impl<T>::Lud_impl(Lud_impl const& lu)
+VSIP_THROW((std::bad_alloc))
+  : length_ (lu.length_),
+    ipiv_   (length_),
+    data_   (length_, length_)
+{
+  data_ = lu.data_;
+  for (index_type i=0; i<length_; ++i)
+    ipiv_[i] = lu.ipiv_[i];
+}
+
+
+
+template <typename T>
+Lud_impl<T>::~Lud_impl()
+  VSIP_NOTHROW
+{
+}
+
+
+
+/// Form LU factorization of matrix A
+///
+/// Requires
+///   A to be a square matrix, either
+///
+/// FLOPS:
+///   real   : UPDATE
+///   complex: UPDATE
+
+template <typename T>
+template <typename Block>
+bool
+Lud_impl<T>::decompose(Matrix<T, Block> m)
+  VSIP_NOTHROW
+{
+  assert(m.size(0) == length_ && m.size(1) == length_);
+
+  assign_local(data_, m);
+
+  Ext_data<data_block_type> ext(data_.block());
+
+  bool success;
+
+  if(length_ > 1) {
+    success = sal::sal_mat_lud_dec(
+                     ext.data(),ext.stride(0),
+      		     &ipiv_[0], length_);
+
+  } else {
+    success = true;
+  }
+  return success;
+}
+
+
+/// Solve Op(A) x = b (where A previously given to decompose)
+///
+/// Op(A) is
+///   A   if tr == mat_ntrans
+///   A^T if tr == mat_trans
+///   A'  if tr == mat_herm (valid for T complex only)
+///
+/// Requires
+///   B to be a (length, P) matrix
+///   X to be a (length, P) matrix
+///
+/// Effects:
+///   X contains solution to Op(A) X = B
+
+template <typename T>
+template <mat_op_type tr,
+	  typename    Block0,
+	  typename    Block1>
+bool
+Lud_impl<T>::impl_solve(
+  const_Matrix<T, Block0> b,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  assert(b.size(0) == length_);
+  assert(b.size(0) == x.size(0) && b.size(1) == x.size(1));
+
+  char trans;
+  // We want X matrix to be same layout as B matrix to make it easier to
+  // store result.
+  Matrix<T, b_data_block_type> b_int(b.size(0),b.size(1));// local copy of b
+  Matrix<T, b_data_block_type> x_int(b.size(0),b.size(1));// local copy of x
+  Matrix<T, data_block_type> data_int(length_,length_);   // local copy of data
+
+  assign_local(b_int, b);
+
+  if (tr == mat_ntrans)
+    trans = 'N';
+  else if (tr == mat_trans)
+    trans = 'T';
+  else if (tr == mat_herm)
+  {
+    assert(Is_complex<T>::value);
+    trans = 'C';
+  }
+
+  if(length_ > 1) {
+    Ext_data<b_data_block_type> b_ext(b_int.block());
+    Ext_data<b_data_block_type> x_ext(x_int.block());
+    Ext_data<data_block_type>   *a_ext;
+
+    if(trans=='T') {
+      assign_local(data_int,data_);
+      data_int = impl::impl_conj(data_int);
+      a_ext = new Ext_data<data_block_type>(data_int.block());
+    }
+    else 
+      a_ext = new Ext_data<data_block_type>(data_.block());
+
+
+
+    // sal_mat_lud_sol only takes vectors, so, we have to do this for each
+    // column in the matrix
+    T *b_ptr = b_ext.data();
+    T *x_ptr = x_ext.data();
+    for(index_type i=0;i<b.size(1);i++,b_ptr += length_,x_ptr += length_) {
+      sal::sal_mat_lud_sol(a_ext->data(), a_ext->stride(0),
+                           &ipiv_[0],b_ptr,
+			   x_ptr,length_,trans);
+    }
+
+
+    assign_local(x, x_int);
+    delete a_ext;
+
+  } else {
+    for(index_type i=0;i<b.size(1);i++)
+      if(tr == mat_herm) {
+        T result = b(0,i)/impl::impl_conj(data_.get(0,0));
+        x.put(0,i,result);
+      }
+      else
+        x.put(0,i,b(0,i)/data_(0,0));
+  }
+
+
+  return true;
+}
+
+
+} // namespace vsip::impl::sal
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+
+#endif // VSIP_IMPL_SOLVER_LU_HPP
Index: tests/reductions-idx.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/reductions-idx.cpp,v
retrieving revision 1.2
diff -u -r1.2 reductions-idx.cpp
--- tests/reductions-idx.cpp	20 Dec 2005 12:48:41 -0000	1.2
+++ tests/reductions-idx.cpp	12 Apr 2006 00:50:19 -0000
@@ -47,7 +47,7 @@
     
     val = maxval(vec, idx);
     test_assert(equal(val, nval));
-    test_assert(idx == i);
+    test_assert(idx == Index<1>(i));
   }
 }
 
@@ -304,11 +304,11 @@
 
    val = maxmgval(vec, idx);
    test_assert(equal(val, T(10)));
-   test_assert(idx == 1);
+   test_assert(idx == Index<1>(1));
 
    val = minmgval(vec, idx);
    test_assert(equal(val, T(0.5)));
-   test_assert(idx == 2);
+   test_assert(idx == Index<1>(2));
 }
 
 
