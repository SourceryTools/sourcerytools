? ChangeLog.new
? config.log
? src/vsip/impl/my_patch
? src/vsip/impl/sal/.solver_lu.hpp.swp
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
Index: src/vsip/impl/solver-cholesky.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-cholesky.hpp,v
retrieving revision 1.3
diff -u -r1.3 solver-cholesky.hpp
--- src/vsip/impl/solver-cholesky.hpp	10 Feb 2006 22:24:02 -0000	1.3
+++ src/vsip/impl/solver-cholesky.hpp	14 Apr 2006 01:14:06 -0000
@@ -21,6 +21,11 @@
 #include <vsip/impl/math-enum.hpp>
 #include <vsip/impl/lapack.hpp>
 #include <vsip/impl/temp_buffer.hpp>
+#ifdef VSIP_IMPL_USE_SAL_SOL
+#include <vsip/impl/sal/solver_cholesky.hpp>
+#endif
+#include <vsip/impl/lapack/solver_cholesky.hpp>
+#include <vsip/impl/solver_common.hpp>
 
 
 
@@ -31,65 +36,24 @@
 namespace vsip
 {
 
-enum mat_uplo
-{
-  lower,
-  upper
-};
-
 namespace impl
 {
 
-/// Cholesky factorization implementation class.  Common functionality
-/// for chold by-value and by-reference classes.
-
 template <typename T>
-class Chold_impl
-  : Compile_time_assert<blas::Blas_traits<T>::valid>
+struct Choose_chold_impl
 {
-  // BLAS/LAPACK require complex data to be in interleaved format.
-  typedef Layout<2, col2_type, Stride_unit_dense, Cmplx_inter_fmt> data_LP;
-  typedef Fast_block<2, T, data_LP> data_block_type;
-
-  // Constructors, copies, assignments, and destructors.
-public:
-  Chold_impl(mat_uplo, length_type)
-    VSIP_THROW((std::bad_alloc));
-  Chold_impl(Chold_impl const&)
-    VSIP_THROW((std::bad_alloc));
-
-  Chold_impl& operator=(Chold_impl const&) VSIP_NOTHROW;
-  ~Chold_impl() VSIP_NOTHROW;
+#ifndef VSIP_IMPL_USE_SAL_SOL
+  typedef typename ITE_Type<Is_chold_impl_avail<Mercury_sal_tag, T>::value,
+                            As_type<Merucry_sal_tag>,
+			    As_type<Lapack_tag> >::type type;
+#else
+  typedef typename As_type<Lapack_tag>::type type;
+#endif
 
-  // Accessors.
-public:
-  length_type length()const VSIP_NOTHROW { return length_; }
-  mat_uplo    uplo()  const VSIP_NOTHROW { return uplo_; }
-
-  // Solve systems.
-public:
-  template <typename Block>
-  bool decompose(Matrix<T, Block>) VSIP_NOTHROW;
-
-protected:
-  template <typename Block0,
-	    typename Block1>
-  bool impl_solve(const_Matrix<T, Block0>, Matrix<T, Block1>)
-    VSIP_NOTHROW;
-
-  // Member data.
-private:
-  typedef std::vector<T, Aligned_allocator<T> > vector_type;
-
-  mat_uplo     uplo_;			// A upper/lower triangular
-  length_type  length_;			// Order of A.
-
-  Matrix<T, data_block_type> data_;	// Factorized Cholesky matrix (A)
 };
 
-} // namespace vsip::impl
-
 
+} // namespace vsip::impl
 
 /// CHOLESKY solver object.
 
@@ -99,9 +63,10 @@
 
 template <typename T>
 class chold<T, by_reference>
-  : public impl::Chold_impl<T>
+  : public impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::type>
 {
-  typedef impl::Chold_impl<T> base_type;
+  typedef impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::type>
+    base_type;
 
   // Constructors, copies, assignments, and destructors.
 public:
@@ -123,9 +88,10 @@
 
 template <typename T>
 class chold<T, by_value>
-  : public impl::Chold_impl<T>
+  : public impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::type>
 {
-  typedef impl::Chold_impl<T> base_type;
+  typedef impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::type>
+    base_type;
 
   // Constructors, copies, assignments, and destructors.
 public:
@@ -150,118 +116,6 @@
 };
 
 
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-namespace impl
-{
-
-template <typename T>
-Chold_impl<T>::Chold_impl(
-  mat_uplo    uplo,
-  length_type length
-  )
-VSIP_THROW((std::bad_alloc))
-  : uplo_   (uplo),
-    length_ (length),
-    data_   (length_, length_)
-{
-  assert(length_ > 0);
-  assert(uplo_ == upper || uplo_ == lower);
-}
-
-
-
-template <typename T>
-Chold_impl<T>::Chold_impl(Chold_impl const& qr)
-VSIP_THROW((std::bad_alloc))
-  : uplo_       (qr.uplo_),
-    length_     (qr.length_),
-    data_       (length_, length_)
-{
-  data_ = qr.data_;
-}
-
-
-
-template <typename T>
-Chold_impl<T>::~Chold_impl()
-  VSIP_NOTHROW
-{
-}
-
-
-
-/// Form Cholesky factorization of matrix A
-///
-/// Requires
-///   A to be a square matrix, either
-///     symmetric positive definite (T real), or
-///     hermitian positive definite (T complex).
-///
-/// FLOPS:
-///   real   : (1/3) n^3
-///   complex: (4/3) n^3
-
-template <typename T>
-template <typename Block>
-bool
-Chold_impl<T>::decompose(Matrix<T, Block> m)
-  VSIP_NOTHROW
-{
-  assert(m.size(0) == length_ && m.size(1) == length_);
-
-  data_ = m;
-
-  Ext_data<data_block_type> ext(data_.block());
-
-  bool success = lapack::potrf(
-		uplo_ == upper ? 'U' : 'L', // A upper/lower lower triangular
-		length_,		    // order of matrix A
-		ext.data(),		    // matrix A
-		ext.stride(1));		    // lda - first dim of A
-
-  return success;
-}
-
-
-
-/// Solve A x = b (where A previously given to decompose)
-
-template <typename T>
-template <typename Block0,
-	  typename Block1>
-bool
-Chold_impl<T>::impl_solve(
-  const_Matrix<T, Block0> b,
-  Matrix<T, Block1>       x)
-  VSIP_NOTHROW
-{
-  assert(b.size(0) == length_);
-  assert(b.size(0) == x.size(0) && b.size(1) == x.size(1));
-
-  Matrix<T, data_block_type> b_int(b.size(0), b.size(1));
-  b_int = b;
-
-  {
-    Ext_data<data_block_type> b_ext(b_int.block());
-    Ext_data<data_block_type> a_ext(data_.block());
-
-    lapack::potrs(uplo_ == upper ? 'U' : 'L',
-		  length_,
-		  b.size(1),		    // number of RHS systems
-		  a_ext.data(), a_ext.stride(1), // A, lda
-		  b_ext.data(), b_ext.stride(1));  // B, ldb
-  }
-  x = b_int;
-
-  return true;
-}
-
-} // namespace vsip::impl
-
 } // namespace vsip
 
 
Index: src/vsip/impl/solver-lu.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-lu.hpp,v
retrieving revision 1.3
diff -u -r1.3 solver-lu.hpp
--- src/vsip/impl/solver-lu.hpp	10 Feb 2006 22:24:02 -0000	1.3
+++ src/vsip/impl/solver-lu.hpp	14 Apr 2006 01:14:06 -0000
@@ -21,6 +21,9 @@
 #include <vsip/impl/math-enum.hpp>
 #include <vsip/impl/lapack.hpp>
 #include <vsip/impl/temp_buffer.hpp>
+#include <vsip/impl/metaprogramming.hpp>
+#include <vsip/impl/sal/solver_lu.hpp>
+#include <vsip/impl/lapack/solver_lu.hpp>
 
 
 
@@ -34,56 +37,22 @@
 namespace impl
 {
 
-/// Cholesky factorization implementation class.  Common functionality
-/// for lud by-value and by-reference classes.
-
+// a structure to chose implementation type
 template <typename T>
-class Lud_impl
-  : Compile_time_assert<blas::Blas_traits<T>::valid>
+struct Choose_lud_impl
 {
-  // BLAS/LAPACK require complex data to be in interleaved format.
-  typedef Layout<2, col2_type, Stride_unit_dense, Cmplx_inter_fmt> data_LP;
-  typedef Fast_block<2, T, data_LP> data_block_type;
-
-  // Constructors, copies, assignments, and destructors.
-public:
-  Lud_impl(length_type)
-    VSIP_THROW((std::bad_alloc));
-  Lud_impl(Lud_impl const&)
-    VSIP_THROW((std::bad_alloc));
-
-  Lud_impl& operator=(Lud_impl const&) VSIP_NOTHROW;
-  ~Lud_impl() VSIP_NOTHROW;
-
-  // Accessors.
-public:
-  length_type length()const VSIP_NOTHROW { return length_; }
-
-  // Solve systems.
-public:
-  template <typename Block>
-  bool decompose(Matrix<T, Block>) VSIP_NOTHROW;
-
-protected:
-  template <mat_op_type tr,
-	    typename    Block0,
-	    typename    Block1>
-  bool impl_solve(const_Matrix<T, Block0>, Matrix<T, Block1>)
-    VSIP_NOTHROW;
-
-  // Member data.
-private:
-  typedef std::vector<int, Aligned_allocator<int> > vector_type;
 
-  length_type  length_;			// Order of A.
-  vector_type  ipiv_;			// Additional info on Q
-
-  Matrix<T, data_block_type> data_;	// Factorized Cholesky matrix (A)
+#ifdef VSIP_IMPL_USE_SAL_SOL
+  typedef typename ITE_Type<Is_lud_impl_avail<Mercury_sal_tag, T>::value,
+                            As_type<Mercury_sal_tag>,
+			    As_type<Lapack_tag> >::type type;
+#else
+  typedef typename As_type<Lapack_tag>::type type;
+#endif
+                            
 };
 
-} // namespace vsip::impl
-
-
+} // namespace impl
 
 /// LU solver object.
 
@@ -97,9 +66,9 @@
 
 template <typename T>
 class lud<T, by_reference>
-  : public impl::Lud_impl<T>
+  : public impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::type>
 {
-  typedef impl::Lud_impl<T> base_type;
+  typedef impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::type> base_type;
 
   // Constructors, copies, assignments, and destructors.
 public:
@@ -126,9 +95,9 @@
 
 template <typename T>
 class lud<T, by_value>
-  : public impl::Lud_impl<T>
+  : public impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::type>
 {
-  typedef impl::Lud_impl<T> base_type;
+  typedef impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::type> base_type;
 
   // Constructors, copies, assignments, and destructors.
 public:
@@ -155,140 +124,6 @@
 
 
 
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-namespace impl
-{
-
-template <typename T>
-Lud_impl<T>::Lud_impl(
-  length_type length
-  )
-VSIP_THROW((std::bad_alloc))
-  : length_ (length),
-    ipiv_   (length_),
-    data_   (length_, length_)
-{
-  assert(length_ > 0);
-}
-
-
-
-template <typename T>
-Lud_impl<T>::Lud_impl(Lud_impl const& lu)
-VSIP_THROW((std::bad_alloc))
-  : length_ (lu.length_),
-    ipiv_   (length_),
-    data_   (length_, length_)
-{
-  data_ = lu.data_;
-  for (index_type i=0; i<length_; ++i)
-    ipiv_[i] = lu.ipiv_[i];
-}
-
-
-
-template <typename T>
-Lud_impl<T>::~Lud_impl()
-  VSIP_NOTHROW
-{
-}
-
-
-
-/// Form LU factorization of matrix A
-///
-/// Requires
-///   A to be a square matrix, either
-///
-/// FLOPS:
-///   real   : UPDATE
-///   complex: UPDATE
-
-template <typename T>
-template <typename Block>
-bool
-Lud_impl<T>::decompose(Matrix<T, Block> m)
-  VSIP_NOTHROW
-{
-  assert(m.size(0) == length_ && m.size(1) == length_);
-
-  assign_local(data_, m);
-
-  Ext_data<data_block_type> ext(data_.block());
-
-  bool success = lapack::getrf(
-		length_, length_,
-		ext.data(), ext.stride(1),	// matrix A, ldA
-		&ipiv_[0]);			// pivots
-
-  return success;
-}
-
-
-
-/// Solve Op(A) x = b (where A previously given to decompose)
-///
-/// Op(A) is
-///   A   if tr == mat_ntrans
-///   A^T if tr == mat_trans
-///   A'  if tr == mat_herm (valid for T complex only)
-///
-/// Requires
-///   B to be a (length, P) matrix
-///   X to be a (length, P) matrix
-///
-/// Effects:
-///   X contains solution to Op(A) X = B
-
-template <typename T>
-template <mat_op_type tr,
-	  typename    Block0,
-	  typename    Block1>
-bool
-Lud_impl<T>::impl_solve(
-  const_Matrix<T, Block0> b,
-  Matrix<T, Block1>       x)
-  VSIP_NOTHROW
-{
-  assert(b.size(0) == length_);
-  assert(b.size(0) == x.size(0) && b.size(1) == x.size(1));
-
-  char trans;
-
-  Matrix<T, data_block_type> b_int(b.size(0), b.size(1));
-  assign_local(b_int, b);
-
-  if (tr == mat_ntrans)
-    trans = 'N';
-  else if (tr == mat_trans)
-    trans = 'T';
-  else if (tr == mat_herm)
-  {
-    assert(Is_complex<T>::value);
-    trans = 'C';
-  }
-
-  {
-    Ext_data<data_block_type> b_ext(b_int.block());
-    Ext_data<data_block_type> a_ext(data_.block());
-
-    lapack::getrs(trans,
-		  length_,			  // order of A
-		  b.size(1),			  // nrhs: number of RH sides
-		  a_ext.data(), a_ext.stride(1),  // A, lda
-		  &ipiv_[0],			  // pivots
-		  b_ext.data(), b_ext.stride(1)); // B, ldb
-  }
-  assign_local(x, b_int);
-
-  return true;
-}
-
-} // namespace vsip::impl
-
 } // namespace vsip
 
 
Index: src/vsip/impl/solver_common.hpp
===================================================================
RCS file: src/vsip/impl/solver_common.hpp
diff -N src/vsip/impl/solver_common.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/solver_common.hpp	14 Apr 2006 01:14:06 -0000
@@ -0,0 +1,57 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/solver_common.hpp
+    @author  Assem Salama
+    @date    2005-04-13
+    @brief   VSIPL++ Library: Common stuff for linear system solvers.
+
+*/
+
+#ifndef VSIP_IMPL_SOLVER_COMMON_HPP
+#define VSIP_IMPL_SOLVER_COMMON_HPP
+
+namespace vsip
+{
+namespace impl
+{
+
+template <typename   ImplTag,
+          typename   T>
+
+// Structures for availability
+struct Is_lud_impl_avail
+{
+  static bool const value = false;
+};
+
+struct Is_chold_impl_avail
+{
+  static bool const value = false;
+};
+
+// LUD solver impl class
+template <typename T,
+          typename ImplTag>
+class Lud_impl;
+
+// CHOLESKY solver impl class
+template <typename T,
+          typename ImplTag>
+class Chold_impl;
+
+// Implementation tags
+struct Lapack_tag;
+
+
+} // namespace vsip::impl
+
+// Common enums
+enum mat_uplo
+{
+  lower,
+  upper
+};
+
+} // namespace vsip
+
+#endif
Index: src/vsip/impl/lapack/solver_cholesky.hpp
===================================================================
RCS file: src/vsip/impl/lapack/solver_cholesky.hpp
diff -N src/vsip/impl/lapack/solver_cholesky.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/lapack/solver_cholesky.hpp	14 Apr 2006 01:14:06 -0000
@@ -0,0 +1,192 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/lapack/solver_cholesky.hpp
+    @author  Assem Salama
+    @date    2006-04-13
+    @brief   VSIPL++ Library: Cholesky Linear system solver using LAPACK.
+
+*/
+
+#ifndef VSIP_IMPL_LAPACK_SOLVER_CHOLESKY_HPP
+#define VSIP_IMPL_LAPACK_SOLVER_CHOLESKY_HPP
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
+#include <vsip/impl/lapack.hpp>
+#include <vsip/impl/temp_buffer.hpp>
+#include <vsip/impl/solver_common.hpp>
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
+/// Cholesky factorization implementation class.  Common functionality
+/// for chold by-value and by-reference classes.
+
+template <typename T>
+class Chold_impl<T, Lapack_tag>
+  : Compile_time_assert<blas::Blas_traits<T>::valid>
+{
+  // BLAS/LAPACK require complex data to be in interleaved format.
+  typedef Layout<2, col2_type, Stride_unit_dense, Cmplx_inter_fmt> data_LP;
+  typedef Fast_block<2, T, data_LP> data_block_type;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  Chold_impl(mat_uplo, length_type)
+    VSIP_THROW((std::bad_alloc));
+  Chold_impl(Chold_impl const&)
+    VSIP_THROW((std::bad_alloc));
+
+  Chold_impl& operator=(Chold_impl const&) VSIP_NOTHROW;
+  ~Chold_impl() VSIP_NOTHROW;
+
+  // Accessors.
+public:
+  length_type length()const VSIP_NOTHROW { return length_; }
+  mat_uplo    uplo()  const VSIP_NOTHROW { return uplo_; }
+
+  // Solve systems.
+public:
+  template <typename Block>
+  bool decompose(Matrix<T, Block>) VSIP_NOTHROW;
+
+protected:
+  template <typename Block0,
+	    typename Block1>
+  bool impl_solve(const_Matrix<T, Block0>, Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  // Member data.
+private:
+  typedef std::vector<T, Aligned_allocator<T> > vector_type;
+
+  mat_uplo     uplo_;			// A upper/lower triangular
+  length_type  length_;			// Order of A.
+
+  Matrix<T, data_block_type> data_;	// Factorized Cholesky matrix (A)
+};
+
+
+
+template <typename T>
+Chold_impl<T,Lapack_tag>::Chold_impl(
+  mat_uplo    uplo,
+  length_type length
+  )
+VSIP_THROW((std::bad_alloc))
+  : uplo_   (uplo),
+    length_ (length),
+    data_   (length_, length_)
+{
+  assert(length_ > 0);
+  assert(uplo_ == upper || uplo_ == lower);
+}
+
+
+
+template <typename T>
+Chold_impl<T,Lapack_tag>::Chold_impl(Chold_impl const& qr)
+VSIP_THROW((std::bad_alloc))
+  : uplo_       (qr.uplo_),
+    length_     (qr.length_),
+    data_       (length_, length_)
+{
+  data_ = qr.data_;
+}
+
+
+
+template <typename T>
+Chold_impl<T,Lapack_tag>::~Chold_impl()
+  VSIP_NOTHROW
+{
+}
+
+
+
+/// Form Cholesky factorization of matrix A
+///
+/// Requires
+///   A to be a square matrix, either
+///     symmetric positive definite (T real), or
+///     hermitian positive definite (T complex).
+///
+/// FLOPS:
+///   real   : (1/3) n^3
+///   complex: (4/3) n^3
+
+template <typename T>
+template <typename Block>
+bool
+Chold_impl<T,Lapack_tag>::decompose(Matrix<T, Block> m)
+  VSIP_NOTHROW
+{
+  assert(m.size(0) == length_ && m.size(1) == length_);
+
+  data_ = m;
+
+  Ext_data<data_block_type> ext(data_.block());
+
+  bool success = lapack::potrf(
+		uplo_ == upper ? 'U' : 'L', // A upper/lower lower triangular
+		length_,		    // order of matrix A
+		ext.data(),		    // matrix A
+		ext.stride(1));		    // lda - first dim of A
+
+  return success;
+}
+
+
+
+/// Solve A x = b (where A previously given to decompose)
+
+template <typename T>
+template <typename Block0,
+	  typename Block1>
+bool
+Chold_impl<T,Lapack_tag>::impl_solve(
+  const_Matrix<T, Block0> b,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  assert(b.size(0) == length_);
+  assert(b.size(0) == x.size(0) && b.size(1) == x.size(1));
+
+  Matrix<T, data_block_type> b_int(b.size(0), b.size(1));
+  b_int = b;
+
+  {
+    Ext_data<data_block_type> b_ext(b_int.block());
+    Ext_data<data_block_type> a_ext(data_.block());
+
+    lapack::potrs(uplo_ == upper ? 'U' : 'L',
+		  length_,
+		  b.size(1),		    // number of RHS systems
+		  a_ext.data(), a_ext.stride(1), // A, lda
+		  b_ext.data(), b_ext.stride(1));  // B, ldb
+  }
+  x = b_int;
+
+  return true;
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+
+#endif // VSIP_IMPL_LAPACK_SOLVER_CHOLESKY_HPP
Index: src/vsip/impl/lapack/solver_lu.hpp
===================================================================
RCS file: src/vsip/impl/lapack/solver_lu.hpp
diff -N src/vsip/impl/lapack/solver_lu.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/lapack/solver_lu.hpp	14 Apr 2006 01:14:06 -0000
@@ -0,0 +1,225 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/lapack/solver_lu.hpp
+    @author  Assem Salama
+    @date    2006-04-13
+    @brief   VSIPL++ Library: LU linear system solver using lapack.
+
+*/
+
+#ifndef VSIP_IMPL_LAPACK_SOLVER_LU_HPP
+#define VSIP_IMPL_LAPACK_SOLVER_LU_HPP
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
+#include <vsip/impl/lapack.hpp>
+#include <vsip/impl/temp_buffer.hpp>
+#include <vsip/impl/solver_common.hpp>
+
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
+/// LU factorization implementation class.  Common functionality
+/// for lud by-value and by-reference classes.
+
+template <typename T>
+class Lud_impl<T, Lapack_tag>
+  : Compile_time_assert<blas::Blas_traits<T>::valid>
+{
+  // BLAS/LAPACK require complex data to be in interleaved format.
+  typedef Layout<2, col2_type, Stride_unit_dense, Cmplx_inter_fmt> data_LP;
+  typedef Fast_block<2, T, data_LP> data_block_type;
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
+  Matrix<T, data_block_type> data_;	// Factorized Cholesky matrix (A)
+};
+
+} // namespace vsip::impl
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace impl
+{
+
+template <typename T>
+Lud_impl<T, Lapack_tag>::Lud_impl(
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
+Lud_impl<T, Lapack_tag>::Lud_impl(Lud_impl const& lu)
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
+Lud_impl<T, Lapack_tag>::~Lud_impl()
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
+Lud_impl<T, Lapack_tag>::decompose(Matrix<T, Block> m)
+  VSIP_NOTHROW
+{
+  assert(m.size(0) == length_ && m.size(1) == length_);
+
+  assign_local(data_, m);
+
+  Ext_data<data_block_type> ext(data_.block());
+
+  bool success = lapack::getrf(
+		length_, length_,
+		ext.data(), ext.stride(1),	// matrix A, ldA
+		&ipiv_[0]);			// pivots
+
+  return success;
+}
+
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
+Lud_impl<T, Lapack_tag>::impl_solve(
+  const_Matrix<T, Block0> b,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  assert(b.size(0) == length_);
+  assert(b.size(0) == x.size(0) && b.size(1) == x.size(1));
+
+  char trans;
+
+  Matrix<T, data_block_type> b_int(b.size(0), b.size(1));
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
+  {
+    Ext_data<data_block_type> b_ext(b_int.block());
+    Ext_data<data_block_type> a_ext(data_.block());
+
+    lapack::getrs(trans,
+		  length_,			  // order of A
+		  b.size(1),			  // nrhs: number of RH sides
+		  a_ext.data(), a_ext.stride(1),  // A, lda
+		  &ipiv_[0],			  // pivots
+		  b_ext.data(), b_ext.stride(1)); // B, ldb
+  }
+  assign_local(x, b_int);
+
+  return true;
+}
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+
+#endif // VSIP_IMPL_LAPACK_SOLVER_LU_HPP
Index: src/vsip/impl/sal/solver_cholesky.hpp
===================================================================
RCS file: src/vsip/impl/sal/solver_cholesky.hpp
diff -N src/vsip/impl/sal/solver_cholesky.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/sal/solver_cholesky.hpp	14 Apr 2006 01:14:06 -0000
@@ -0,0 +1,274 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/sal/solver_cholesky.hpp
+    @author  Assem Salama
+    @date    2006-04-13
+    @brief   VSIPL++ Library: Cholesky linear system solver using SAL.
+
+*/
+
+#ifndef VSIP_IMPL_SAL_SOLVER_CHOLESKY_HPP
+#define VSIP_IMPL_SAL_SOLVER_CHOLESKY_HPP
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
+#include <vsip/impl/solver_common.hpp>
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
+// SAL Cholesky decomposition
+#define VSIP_IMPL_SAL_CHOL_DEC( T, D_T, SAL_T, SALFCN ) \
+inline void                          \
+sal_mat_chol_dec(                    \
+  T *a,                              \
+  D_T *d, int n)                     \
+{                                    \
+  SALFCN(                            \
+   (SAL_T*) a, n,                    \
+   (SAL_T*) a, n,                    \
+   (D_T*) d, n);                     \
+}
+
+#define VSIP_IMPL_SAL_CHOL_DEC_SPLIT( T, D_T, SAL_T, SALFCN ) \
+inline void                          \
+sal_mat_chol_dec(                    \
+  std::pair<T*,T*> a,                \
+  D_T *d, int n)                     \
+{                                    \
+  SALFCN(                            \
+   (SAL_T*) &a, n,                   \
+   (SAL_T*) &a, n,                   \
+   (D_T*) d, n);                     \
+}
+
+
+VSIP_IMPL_SAL_CHOL_DEC(float,                   float,float,        matchold)
+VSIP_IMPL_SAL_CHOL_DEC(complex<float>,          float,COMPLEX,      cmatchold)
+VSIP_IMPL_SAL_CHOL_DEC_SPLIT(float,             float,COMPLEX_SPLIT,zmatchold)
+
+// SAL Cholesky solver
+#define VSIP_IMPL_SAL_CHOL_SOL( T, D_T, SAL_T, SALFCN ) \
+inline void                          \
+sal_mat_chol_sol(                    \
+  T *a, int atcols,                  \
+  D_T *d, T *b, T *x, int n)         \
+{                                    \
+  SALFCN(                            \
+   (SAL_T*) a, atcols,               \
+   (D_T*) d, (SAL_T*)b, (SAL_T*)x,   \
+   n);                               \
+}
+
+#define VSIP_IMPL_SAL_CHOL_SOL_SPLIT( T, D_T, SAL_T, SALFCN ) \
+inline void                                        \
+sal_mat_chol_sol(                                  \
+  std::pair<T*,T*> a, int atcols,                  \
+  D_T *d, std::pair<T*,T*> b,                      \
+  std::pair<T*,T*> x, int n)                       \
+{                                                  \
+  SALFCN(                                          \
+   (SAL_T*) &a, atcols,                            \
+   (D_T*) d, (SAL_T*)&b, (SAL_T*)&x,               \
+   n);                                             \
+}
+
+VSIP_IMPL_SAL_CHOL_SOL(float,         float,float,        matchols)
+VSIP_IMPL_SAL_CHOL_SOL(complex<float>,float,COMPLEX,      cmatchols)
+VSIP_IMPL_SAL_CHOL_SOL_SPLIT(float,   float,COMPLEX_SPLIT,zmatchols)
+
+/// Cholesky factorization implementation class.  Common functionality
+/// for chold by-value and by-reference classes.
+
+template <typename T>
+class Chold_impl<T,Mercury_sal_tag>
+  : impl::Compile_time_assert<blas::Blas_traits<T>::valid>
+{
+  // The matrix to be decomposed using SAL must be in ROW major format. The
+  // other matrix B will be in COL major format so that we can pass each
+  // column to the solver. SAL supports both split and interleaved format.
+  typedef vsip::impl::dense_complex_type   complex_type;
+  typedef Storage<complex_type, T>         storage_type;
+  typedef typename storage_type::type      ptr_type;
+
+  typedef Layout<2, row2_type, Stride_unit_dense, complex_type> data_LP;
+  typedef Fast_block<2, T, data_LP> data_block_type;
+
+  typedef Layout<2, col2_type, Stride_unit_dense, complex_type> b_data_LP;
+  typedef Fast_block<2, T, b_data_LP> b_data_block_type;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  Chold_impl(mat_uplo, length_type)
+    VSIP_THROW((std::bad_alloc));
+  Chold_impl(Chold_impl const&)
+    VSIP_THROW((std::bad_alloc));
+
+  Chold_impl& operator=(Chold_impl const&) VSIP_NOTHROW;
+  ~Chold_impl() VSIP_NOTHROW;
+
+  // Accessors.
+public:
+  mat_uplo    uplo()  const VSIP_NOTHROW { return uplo_; }
+  length_type length()const VSIP_NOTHROW { return length_; }
+
+  // Solve systems.
+public:
+  template <typename Block>
+  bool decompose(Matrix<T, Block>) VSIP_NOTHROW;
+
+protected:
+  template <typename Block0,
+	    typename Block1>
+  bool impl_solve(const_Matrix<T, Block0>, Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  // Member data.
+private:
+  typedef std::vector<float, Aligned_allocator<float> > vector_type;
+
+  mat_uplo     uplo_;			// A upper/lower triangular
+  length_type  length_;			// Order of A.
+  vector_type  idv_;			// Daignal vector from decompose
+
+  Matrix<T, data_block_type> data_;	// Factorized Cholesky matrix (A)
+};
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T>
+Chold_impl<T,Mercury_sal_tag>::Chold_impl(
+  mat_uplo    uplo,
+  length_type length
+  )
+VSIP_THROW((std::bad_alloc))
+  : length_ (length),
+    uplo_   (uplo),
+    idv_    (length_),
+    data_   (length_, length_)
+{
+  assert(length_ > 0);
+}
+
+
+
+template <typename T>
+Chold_impl<T,Mercury_sal_tag>::Chold_impl(Chold_impl const& qr)
+VSIP_THROW((std::bad_alloc))
+  : length_     (qr.length_),
+    uplo_       (qr.uplo_),
+    idv_        (length_),
+    data_       (length_, length_)
+{
+  data_ = qr.data_;
+}
+
+
+
+template <typename T>
+Chold_impl<T,Mercury_sal_tag>::~Chold_impl()
+  VSIP_NOTHROW
+{
+}
+
+
+
+/// Form Cholesky factorization of matrix A
+///
+/// Requires
+///   A to be a square matrix, either
+///     symmetric positive definite (T real), or
+///     hermitian positive definite (T complex).
+///
+/// FLOPS:
+///   real   : (1/3) n^3
+///   complex: (4/3) n^3
+
+template <typename T>
+template <typename Block>
+bool
+Chold_impl<T,Mercury_sal_tag>::decompose(Matrix<T, Block> m)
+  VSIP_NOTHROW
+{
+  assert(m.size(0) == length_ && m.size(1) == length_);
+
+  data_ = m;
+  Ext_data<data_block_type> ext(data_.block());
+
+  if(length_ > 1) 
+    sal_mat_chol_dec(
+                  ext.data(),               // matrix A, will also store output
+		  &idv_[0],                // diagnal vector
+		  length_);		    // order of matrix A
+  return true;
+}
+
+
+/// Solve A x = b (where A previously given to decompose)
+
+template <typename T>
+template <typename Block0,
+	  typename Block1>
+bool
+Chold_impl<T,Mercury_sal_tag>::impl_solve(
+  const_Matrix<T, Block0> b,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  assert(b.size(0) == length_);
+  assert(b.size(0) == x.size(0) && b.size(1) == x.size(1));
+
+  Matrix<T, b_data_block_type> b_int(b.size(0), b.size(1));
+  Matrix<T, b_data_block_type> x_int(b.size(0), b.size(1));
+  b_int = b;
+
+  if (length_ > 1) 
+  {
+    Ext_data<b_data_block_type> b_ext(b_int.block());
+    Ext_data<b_data_block_type> x_ext(x_int.block());
+    Ext_data<data_block_type> a_ext(data_.block());
+
+    ptr_type b_ptr = b_ext.data();
+    ptr_type x_ptr = x_ext.data();
+
+    for(index_type i=0;i<b.size(1);i++) {
+      sal_mat_chol_sol(
+                 a_ext.data(), a_ext.stride(0),
+		 &idv_[0],
+		 storage_type::offset(b_ptr,i*length_),
+		 storage_type::offset(x_ptr,i*length_),
+		 length_);
+    }
+  }
+  else 
+  {
+    for(index_type i=0;i<b.size(1);i++)
+      x_int.put(0,i,b.get(0,i)/data_.get(0,0));
+  }
+  x = x_int;
+  return true;
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif
Index: src/vsip/impl/sal/solver_lu.hpp
===================================================================
RCS file: src/vsip/impl/sal/solver_lu.hpp
diff -N src/vsip/impl/sal/solver_lu.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/sal/solver_lu.hpp	14 Apr 2006 01:14:06 -0000
@@ -0,0 +1,356 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/sal/solver_lu.hpp
+    @author  Assem Salama
+    @date    2006-04-04
+    @brief   VSIPL++ Library: LU linear system solver using SAL.
+
+*/
+
+#ifndef VSIP_IMPL_SAL_SOLVER_LU_HPP
+#define VSIP_IMPL_SAL_SOLVER_LU_HPP
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
+#include <vsip/impl/solver_common.hpp>
+
+#include <sal.h>
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
+// A structure that tells us if sal lud impl is available
+// for certain types
+template <>
+struct Is_lud_impl_avail<Mercury_sal_tag, float>
+{
+  static bool const value = true;
+};
+
+template <>
+struct Is_lud_impl_avail<Mercury_sal_tag, complex<float> >
+{
+  static bool const value = true;
+};
+
+// SAL LUD decomposition functions
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
+#define VSIP_IMPL_SAL_LUD_DEC_SPLIT( T, D_T, SAL_T, SALFCN ) \
+inline bool                          \
+sal_mat_lud_dec(                     \
+  std::pair<T*,T*> c, int ctcols,    \
+  D_T *d, int n)                     \
+{                                    \
+  return (SALFCN(                    \
+   (SAL_T*) &c, ctcols,              \
+   (D_T*) d, n,                      \
+   NULL, NULL, SAL_COND_EST_NONE) == SAL_SUCCESS); \
+}
+// Declare LUD decomposition functions
+VSIP_IMPL_SAL_LUD_DEC(float,                   int,float,        mat_lud_dec)
+VSIP_IMPL_SAL_LUD_DEC(complex<float>,          int,COMPLEX,      cmat_lud_dec)
+VSIP_IMPL_SAL_LUD_DEC_SPLIT(float,             int,COMPLEX_SPLIT,zmat_lud_dec)
+
+#undef VSIP_IMPL_SAL_LUD_DEC
+
+
+// SAL LUD solver functions
+#define VSIP_IMPL_SAL_LUD_SOL( T, D_T, SAL_T, SALFCN ) \
+inline bool                          \
+sal_mat_lud_sol(                     \
+  T *a, int atcols,                  \
+  D_T *d, T *b, T *w,                \
+  int n,int flag)                    \
+{                                    \
+  return (SALFCN(                    \
+   (SAL_T*) a, atcols,               \
+   (D_T*) d,(SAL_T*)b,(SAL_T*)w,     \
+   n,flag) == SAL_SUCCESS);          \
+}
+
+#define VSIP_IMPL_SAL_LUD_SOL_SPLIT( T, D_T, SAL_T, SALFCN ) \
+inline bool                                        \
+sal_mat_lud_sol(                                   \
+  std::pair<T*,T*> a, int atcols,                  \
+  D_T *d, std::pair<T*,T*> b, std::pair<T*,T*> w,  \
+  int n,int flag)                                  \
+{                                                  \
+  return (SALFCN(                                  \
+   (SAL_T*) &a, atcols,                            \
+   (D_T*) d,(SAL_T*)&b,(SAL_T*)&w,                 \
+   n,flag) == SAL_SUCCESS);                        \
+}
+// Declare LUD decomposition functions
+VSIP_IMPL_SAL_LUD_SOL(float,         int,float,        mat_lud_sol)
+VSIP_IMPL_SAL_LUD_SOL(complex<float>,int,COMPLEX,      cmat_lud_sol)
+VSIP_IMPL_SAL_LUD_SOL_SPLIT(float,   int,COMPLEX_SPLIT,zmat_lud_sol)
+
+#undef VSIP_IMPL_SAL_LUD_SOL
+
+
+/// LU factorization implementation class.  Common functionality
+/// for lud by-value and by-reference classes. SAL only supports floats. There
+/// are specializations of lud for double farther bellow
+
+template <typename T>
+class Lud_impl<T,Mercury_sal_tag>
+{
+  // The input matrix must be in ROW major form. We want the b matrix
+  // to be in COL major form because we need to call the SAL function for
+  // each column in the b matrix. SAL supports split and interleaved complex
+  // formats. Complex_type tells us which format we will end up using.
+  typedef vsip::impl::dense_complex_type complex_type;
+  typedef Storage<complex_type, T>       storage_type;
+  typedef typename storage_type::type    ptr_type;
+
+  typedef Layout<2, row2_type, Stride_unit_dense, complex_type> data_LP;
+  typedef Fast_block<2, T, data_LP> data_block_type;
+
+  typedef Layout<2, col2_type, Stride_unit_dense, complex_type> b_data_LP;
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
+  vector_type  ipiv_;			// Pivot table for Q. This gets
+                                        // generated from the decompose and
+					// gets used in the solve
+
+  Matrix<T, data_block_type> data_;	// Factorized matrix (A)
+};
+
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+
+template <typename T>
+Lud_impl<T,Mercury_sal_tag>::Lud_impl(
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
+Lud_impl<T,Mercury_sal_tag>::Lud_impl(Lud_impl const& lu)
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
+Lud_impl<T,Mercury_sal_tag>::~Lud_impl()
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
+Lud_impl<T,Mercury_sal_tag>::decompose(Matrix<T, Block> m)
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
+  if(length_ > 1) 
+  {
+    success = sal_mat_lud_dec(
+                     ext.data(),ext.stride(0),
+      		     &ipiv_[0], length_);
+
+  }
+  else 
+  {
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
+Lud_impl<T,Mercury_sal_tag>::impl_solve(
+  const_Matrix<T, Block0> b,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  assert(b.size(0) == length_);
+  assert(b.size(0) == x.size(0) && b.size(1) == x.size(1));
+
+  int trans;
+  // We want X matrix to be same layout as B matrix to make it easier to
+  // store result.
+  Matrix<T, b_data_block_type> b_int(b.size(0),b.size(1));// local copy of b
+  Matrix<T, b_data_block_type> x_int(b.size(0),b.size(1));// local copy of x
+  Matrix<T, data_block_type> data_int(length_,length_);   // local copy of data
+
+  assign_local(b_int, b);
+
+  if (tr == mat_ntrans)
+    trans = SAL_NORMAL_SOLVER;
+  else if (tr == mat_trans)
+    trans = SAL_TRANSPOSE_SOLVER;
+  else if (tr == mat_herm)
+  {
+    assert(Is_complex<T>::value);
+    trans = SAL_TRANSPOSE_SOLVER;
+  }
+
+  if(length_ > 1) 
+  {
+    Ext_data<b_data_block_type> b_ext(b_int.block());
+    Ext_data<b_data_block_type> x_ext(x_int.block());
+    if(tr == mat_trans) 
+    {
+      assign_local(data_int,data_);
+      data_int=impl::impl_conj(data_int);
+    }
+    Ext_data<data_block_type>   a_ext((tr == mat_trans)?
+                                        data_int.block():data_.block());
+
+    // sal_mat_lud_sol only takes vectors, so, we have to do this for each
+    // column in the matrix
+    ptr_type b_ptr = b_ext.data();
+    ptr_type x_ptr = x_ext.data();
+    for(index_type i=0;i<b.size(1);i++) {
+      sal_mat_lud_sol(a_ext.data(), a_ext.stride(0),
+                      &ipiv_[0],
+		      storage_type::offset(b_ptr,i*length_),
+	   	      storage_type::offset(x_ptr,i*length_),
+		      length_,trans);
+    }
+
+
+    assign_local(x, x_int);
+  }
+  else 
+  {
+    for(index_type i=0;i<b.size(1);i++)
+      if(tr == mat_herm) 
+      {
+        T result = b.get(0,i)/impl::impl_conj(data_.get(0,0));
+        x.put(0,i,result);
+      }
+      else
+        x.put(0,i,b.get(0,i)/data_.get(0,0));
+  }
+
+
+  return true;
+}
+
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+
+#endif // VSIP_IMPL_SAL_SOLVER_LU_HPP
