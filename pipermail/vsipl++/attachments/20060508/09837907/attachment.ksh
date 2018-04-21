Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.460
diff -u -r1.460 ChangeLog
--- ChangeLog	8 May 2006 03:48:21 -0000	1.460
+++ ChangeLog	8 May 2006 12:52:57 -0000
@@ -1,3 +1,20 @@
+2006-05-08  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Add AC_SUBST for VSIP_IMPL_FFTW3.
+	* src/vsip/impl/solver-qr.hpp: Move Qrd_impl into lapack and sal
+	  solver_qr files.  Dispatch to appropriate Qrd_impl.
+	* src/vsip/impl/solver_common.hpp: Define Is_qrd_impl_avail,
+	  Is_svd_impl_avail, and Qrd_impl classes.
+	* src/vsip/impl/lapack/solver_qr.hpp: New file, implements Qrd
+	  using Lapack (based on old solver-qr.hpp).
+	* src/vsip/impl/sal/solver_qr.hpp: New file, implements Qrd using
+	  SAL.
+	* tests/solver-qr.cpp: Update to use Choose_qrd_impl to avoid
+	  testing unimplemented functionality.  Added coverage for
+	  non-full-QR cases (i.e. for qrd_nosaveq and qrd_saveq1).
+	  Loosened error bounds for SAL Qrd, pending better QR error
+	  model.
+	
 2006-05-07  Don McCoy  <don@codesourcery.com>
 
 	* GNUmakefile.in: Added hpec-kernel and vsip_csl directories 
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.99
diff -u -r1.99 configure.ac
--- configure.ac	6 May 2006 22:09:27 -0000	1.99
+++ configure.ac	8 May 2006 12:52:57 -0000
@@ -531,7 +531,7 @@
 dnl
 dnl fftw3 needs some special care, so we will do some extra checks here.
 dnl
-if test "x$enable_fftw3" != x; then
+if test "$enable_fftw3" != "no"; then
 
   keep_CPPFLAGS="$CPPFLAGS"
   keep_LIBS="$LIBS"
@@ -556,6 +556,7 @@
       libs="$libs -lfftw3l"
       syms="$syms const char* fftwl_version;"
   fi
+  AC_SUBST(VSIP_IMPL_FFTW3, 1)
   AC_DEFINE_UNQUOTED(VSIP_IMPL_FFTW3, 1, [Define to build using FFTW3 headers.])
 
   if test -n "$with_fftw3_prefix"; then
@@ -1714,7 +1715,10 @@
 if test "$enable_mpi" != "no"; then
   AC_MSG_RESULT([With parallel service:                   $PAR_SERVICE])
 fi
-AC_MSG_RESULT([With LAPACK                              $lapack_found])
+if test "x$lapack_found" = "x"; then
+  lapack_found="no"
+fi
+AC_MSG_RESULT([With LAPACK:                             $lapack_found])
 AC_MSG_RESULT([With SAL:                                $enable_sal])
 AC_MSG_RESULT([With IPP:                                $enable_ipp])
 AC_MSG_RESULT([Using FFT backends:                      ${enable_fft}])
Index: src/vsip/impl/solver-qr.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-qr.hpp,v
retrieving revision 1.5
diff -u -r1.5 solver-qr.hpp
--- src/vsip/impl/solver-qr.hpp	10 Feb 2006 22:24:02 -0000	1.5
+++ src/vsip/impl/solver-qr.hpp	8 May 2006 12:52:58 -0000
@@ -22,6 +22,13 @@
 #include <vsip/impl/lapack.hpp>
 #include <vsip/impl/temp_buffer.hpp>
 #include <vsip/impl/working-view.hpp>
+#include <vsip/impl/solver_common.hpp>
+#ifdef VSIP_IMPL_HAVE_LAPACK
+#  include <vsip/impl/lapack/solver_qr.hpp>
+#endif
+#ifdef VSIP_IMPL_HAVE_SAL
+#  include <vsip/impl/sal/solver_qr.hpp>
+#endif
 
 
 
@@ -35,93 +42,56 @@
 namespace impl
 {
 
+// List of implementation tags to consider for QR.
 
-/// QR decomposition implementation class.  Common functionality for
-/// qrd by-value and by-reference classes.
+typedef Make_type_list<
+#ifdef VSIP_IMPL_HAVE_SAL
+  Mercury_sal_tag,
+#endif
+#ifdef VSIP_IMPL_HAVE_LAPACK
+  Lapack_tag,
+#endif
+  None_type // None_type is treated specially by Make_type_list, it is
+            // not be put into the list.  Putting an explicit None_type
+            // at the end of the list lets us put a ',' after each impl
+            // tag.
+  >::type Qrd_type_list;
 
-template <typename T,
-	  bool     Blocked = true>
-class Qrd_impl
-  : Compile_time_assert<blas::Blas_traits<T>::valid>
-{
-  // BLAS/LAPACK require complex data to be in interleaved format.
-  typedef Layout<2, col2_type, Stride_unit_dense, Cmplx_inter_fmt> data_LP;
-  typedef Fast_block<2, T, data_LP> data_block_type;
-
-  // Constructors, copies, assignments, and destructors.
-public:
-  Qrd_impl(length_type, length_type, storage_type)
-    VSIP_THROW((std::bad_alloc));
-  Qrd_impl(Qrd_impl const&)
-    VSIP_THROW((std::bad_alloc));
-
-  Qrd_impl& operator=(Qrd_impl const&) VSIP_NOTHROW;
-  ~Qrd_impl() VSIP_NOTHROW;
-
-  // Accessors.
-public:
-  length_type  rows()     const VSIP_NOTHROW { return m_; }
-  length_type  columns()  const VSIP_NOTHROW { return n_; }
-  storage_type qstorage() const VSIP_NOTHROW { return st_; }
-
-  // Solve systems.
-public:
-  template <typename Block>
-  bool decompose(Matrix<T, Block>) VSIP_NOTHROW;
 
-protected:
-  template <mat_op_type       tr,
-	    product_side_type ps,
-	    typename          Block0,
-	    typename          Block1>
-  bool impl_prodq(const_Matrix<T, Block0>, Matrix<T, Block1>)
-    VSIP_NOTHROW;
-
-  template <mat_op_type       tr,
-	    typename          Block0,
-	    typename          Block1>
-  bool impl_rsol(const_Matrix<T, Block0>, T const, Matrix<T, Block1>)
-    VSIP_NOTHROW;
 
-  template <typename          Block0,
-	    typename          Block1>
-  bool impl_covsol(const_Matrix<T, Block0>, Matrix<T, Block1>)
-    VSIP_NOTHROW;
-
-  template <typename          Block0,
-	    typename          Block1>
-  bool impl_lsqsol(const_Matrix<T, Block0>, Matrix<T, Block1>)
-    VSIP_NOTHROW;
-
-  // Member data.
-private:
-  typedef std::vector<T, Aligned_allocator<T> > vector_type;
-
-  length_type  m_;			// Number of rows.
-  length_type  n_;			// Number of cols.
-  storage_type st_;			// Q storage type
-
-  Matrix<T, data_block_type> data_;	// Factorized QR matrix
-  vector_type tau_;			// Additional info on Q
-  length_type geqrf_lwork_;		// size of workspace needed for geqrf
-  vector_type geqrf_work_;		// workspace for geqrf
+// a structure to chose implementation type
+template <typename T>
+struct Choose_qrd_impl
+{
+  typedef typename Choose_solver_impl<
+    Is_qrd_impl_avail,
+    T,
+    Qrd_type_list>::type type;
+
+  typedef typename ITE_Type<
+    Type_equal<type, None_type>::value,
+    As_type<Error_no_solver_for_this_type>,
+    As_type<type> >::type use_type;
 };
 
 } // namespace vsip::impl
 
-
-
 /// QR solver object.
 
 template <typename              T               = VSIP_DEFAULT_VALUE_TYPE,
 	  return_mechanism_type ReturnMechanism = by_value>
 class qrd;
 
+
+
+// QR solver object (by-reference).
+
 template <typename T>
 class qrd<T, by_reference>
-  : public impl::Qrd_impl<T>
+  : public impl::Qrd_impl<T,true,typename impl::Choose_qrd_impl<T>::use_type>
 {
-  typedef impl::Qrd_impl<T> base_type;
+  typedef impl::Qrd_impl<T,true,typename impl::Choose_qrd_impl<T>::use_type>
+    base_type;
 
   // Constructors, copies, assignments, and destructors.
 public:
@@ -162,11 +132,16 @@
   { return this->impl_lsqsol(b, x); }
 };
 
+
+
+// QR solver object (by-value).
+
 template <typename T>
 class qrd<T, by_value>
-  : public impl::Qrd_impl<T>
+  : public impl::Qrd_impl<T,true,typename impl::Choose_qrd_impl<T>::use_type >
 {
-  typedef impl::Qrd_impl<T> base_type;
+  typedef impl::Qrd_impl<T,true,typename impl::Choose_qrd_impl<T>::use_type >
+    base_type;
 
   // Constructors, copies, assignments, and destructors.
 public:
@@ -241,402 +216,6 @@
 
 
 
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-namespace impl
-{
-
-template <typename T,
-	  bool     Blocked>
-Qrd_impl<T, Blocked>::Qrd_impl(
-  length_type  rows,
-  length_type  cols,
-  storage_type st
-  )
-VSIP_THROW((std::bad_alloc))
-  : m_          (rows),
-    n_          (cols),
-    st_         (st),
-    data_       (m_, n_),
-    tau_        (n_),
-    geqrf_lwork_(n_ * lapack::geqrf_blksize<T>(m_, n_)),
-    geqrf_work_ (geqrf_lwork_)
-{
-  assert(m_ > 0 && n_ > 0 && m_ >= n_);
-  assert(st_ == qrd_nosaveq || st_ == qrd_saveq || st_ == qrd_saveq1);
-}
-
-
-
-template <typename T,
-	  bool     Blocked>
-Qrd_impl<T, Blocked>::Qrd_impl(Qrd_impl const& qr)
-VSIP_THROW((std::bad_alloc))
-  : m_          (qr.m_),
-    n_          (qr.n_),
-    st_         (qr.st_),
-    data_       (m_, n_),
-    tau_        (n_),
-    geqrf_lwork_(qr.geqrf_lwork_),
-    geqrf_work_ (geqrf_lwork_)
-{
-  data_ = qr.data_;
-  for (index_type i=0; i<n_; ++i)
-    tau_[i] = qr.tau_[i];
-}
-
-
-
-template <typename T,
-	  bool     Blocked>
-Qrd_impl<T, Blocked>::~Qrd_impl()
-  VSIP_NOTHROW
-{
-}
-
-
-
-/// Decompose matrix M into QR form.
-///
-/// Requires
-///   M to be a full rank, modifiable matrix of ROWS x COLS.
-
-template <typename T,
-	  bool     Blocked>
-template <typename Block>
-bool
-Qrd_impl<T, Blocked>::decompose(Matrix<T, Block> m)
-  VSIP_NOTHROW
-{
-  assert(m.size(0) == m_ && m.size(1) == n_);
-
-  int lwork   = geqrf_lwork_;
-
-  assign_local(data_, m);
-
-  Ext_data<data_block_type> ext(data_.block());
-
-  // lda is m_.
-  if (Blocked)
-     lapack::geqrf(m_, n_, ext.data(), m_, &tau_[0], &geqrf_work_[0], lwork);
-  else
-     lapack::geqr2(m_, n_, ext.data(), m_, &tau_[0], &geqrf_work_[0], lwork);
-
-  assert((length_type)lwork <= geqrf_lwork_);
-
-  return true;
-}
-
-
-
-/// Compute product of Q and b
-///
-/// qstoarge   | ps        | tr         | product | b (in) | x (out)
-/// qrd_saveq1 | mat_lside | mat_ntrans | Q b     | (n, p) | (m, p)
-/// qrd_saveq1 | mat_lside | mat_trans  | Q' b    | (m, p) | (n, p)
-/// qrd_saveq1 | mat_lside | mat_herm   | Q* b    | (m, p) | (n, p)
-///
-/// qrd_saveq1 | mat_rside | mat_ntrans | b Q     | (p, m) | (p, n)
-/// qrd_saveq1 | mat_rside | mat_trans  | b Q'    | (p, n) | (p, m)
-/// qrd_saveq1 | mat_rside | mat_herm   | b Q*    | (p, n) | (p, m)
-///
-/// qrd_saveq  | mat_lside | mat_ntrans | Q b     | (m, p) | (m, p)
-/// qrd_saveq  | mat_lside | mat_trans  | Q' b    | (m, p) | (m, p)
-/// qrd_saveq  | mat_lside | mat_herm   | Q* b    | (m, p) | (m, p)
-///
-/// qrd_saveq  | mat_rside | mat_ntrans | b Q     | (p, m) | (p, m)
-/// qrd_saveq  | mat_rside | mat_trans  | b Q'    | (p, m) | (p, m)
-/// qrd_saveq  | mat_rside | mat_herm   | b Q*    | (p, m) | (p, m)
-
-template <typename T,
-	  bool     Blocked>
-template <mat_op_type       tr,
-	  product_side_type ps,
-	  typename          Block0,
-	  typename          Block1>
-bool
-Qrd_impl<T, Blocked>::impl_prodq(
-  const_Matrix<T, Block0> b,
-  Matrix<T, Block1>       x)
-  VSIP_NOTHROW
-{
-  assert(this->qstorage() == qrd_saveq1 || this->qstorage() == qrd_saveq);
-
-  char        side;
-  char        trans;
-  length_type q_rows;
-  length_type q_cols;
-  length_type k_reflectors = n_;
-  int         mqr_lwork;
-
-  if (qstorage() == qrd_saveq1)
-  {
-    q_rows = m_;
-    q_cols = n_;
-  }
-  else // (qstorage() == qrd_saveq1)
-  {
-    q_rows = m_;
-    q_cols = m_;
-  }
-
-  if (tr == mat_trans)
-  {
-    trans = 't';
-    std::swap(q_rows, q_cols);
-  }
-  else if (tr == mat_herm)
-  {
-    trans = 'c';
-    std::swap(q_rows, q_cols);
-  }
-  else // if (tr == mat_ntrans)
-  {
-    trans = 'n';
-  }
-  
-  if (ps == mat_lside)
-  {
-    assert(b.size(0) == q_cols);
-    assert(x.size(0) == q_rows);
-    assert(b.size(1) == x.size(1));
-    side = 'l';
-    mqr_lwork = b.size(1);
-  }
-  else // (ps == mat_rside)
-  {
-    assert(b.size(1) == q_rows);
-    assert(x.size(1) == q_cols);
-    assert(b.size(0) == x.size(0));
-    side = 'r';
-    mqr_lwork = b.size(0);
-  }
-
-  Matrix<T, data_block_type> b_int(b.size(0), b.size(1));
-  assign_local(b_int, b);
-
-  int blksize   = lapack::mqr_blksize<T>(side, trans,
-					 b.size(0), b.size(1), k_reflectors);
-  mqr_lwork *= blksize;
-  Temp_buffer<T> mqr_work(mqr_lwork);
-
-  {
-    Ext_data<data_block_type> b_ext(b_int.block());
-    Ext_data<data_block_type> a_ext(data_.block());
-
-    lapack::mqr(side,
-		trans,
-		b.size(0), b.size(1),
-		k_reflectors,
-		a_ext.data(), m_,
-		&tau_[0],
-		b_ext.data(), b.size(0),
-		mqr_work.data(), mqr_lwork);
-		
-  }
-  assign_local(x, b_int);
-
-  return true;
-}
-
-
-
-/// Solve op(R) x = alpha b
-
-template <typename T,
-	  bool     Blocked>
-template <mat_op_type tr,
-	  typename    Block0,
-	  typename    Block1>
-bool
-Qrd_impl<T, Blocked>::impl_rsol(
-  const_Matrix<T, Block0> b,
-  T const                 alpha,
-  Matrix<T, Block1>       x)
-  VSIP_NOTHROW
-{
-  assert(b.size(0) == n_);
-  assert(b.size(0) == x.size(0));
-  assert(b.size(1) == x.size(1));
-
-  char trans;
-
-  switch(tr)
-  {
-  case mat_trans:
-    // assert(Is_scalar<T>::value);
-    trans = 't';
-    break;
-  case mat_herm:
-    // assert(Is_complex<T>::value);
-    trans = 'c';
-    break;
-  default:
-    trans = 'n';
-    break;
-  }
-
-  Matrix<T, data_block_type> b_int(b.size(0), b.size(1));
-  assign_local(b_int, b);
-  
-
-  {
-    Ext_data<data_block_type> a_ext(data_.block());
-    Ext_data<data_block_type> b_ext(b_int.block());
-      
-    blas::trsm('l',		// R appears on [l]eft-side
-	       'u',		// R is [u]pper-triangular
-	       trans,		// 
-	       'n',		// R is [n]ot unit triangular
-	       b.size(0), b.size(1),
-	       alpha,
-	       a_ext.data(), m_,
-	       b_ext.data(), b_ext.stride(1));
-  }
-  assign_local(x, b_int);
-
-  return true;
-}
-
-
-
-/// Solve covariance system for x:
-///   A' A X = B
-
-template <typename T,
-	  bool     Blocked>
-template <typename Block0,
-	  typename Block1>
-bool
-Qrd_impl<T, Blocked>::impl_covsol(const_Matrix<T, Block0> b, Matrix<T, Block1> x)
-  VSIP_NOTHROW
-{
-  length_type b_rows = b.size(0);
-  length_type b_cols = b.size(1);
-  T alpha = T(1);
-
-  assert(b_rows == n_);
-
-  // Solve A' A x = b
-
-  // Equiv to solve: R' R x = b
-  // First solve:    R' b_1 = b
-  // Then solve:     R x = b_1
-
-  Matrix<T, data_block_type> b_int(b_rows, b_cols);
-  assign_local(b_int, b);
-
-  {
-    Ext_data<data_block_type> b_ext(b_int.block());
-    Ext_data<data_block_type> a_ext(data_.block());
-
-    // First solve: R' b_1 = b
-
-    blas::trsm('l',	// R' appears on [l]eft-side
-	       'u',	// R is [u]pper-triangular
-	       blas::Blas_traits<T>::trans, // [c]onj/[t]ranspose (conj(R'))
-	       'n',	// R is [n]ot unit triangular
-	       b_rows, b_cols,
-	       alpha,
-	       a_ext.data(), m_,
-	       b_ext.data(), b_rows);
-
-    // Then solve: R x = b_1
-    
-    blas::trsm('l',	// R appears on [l]eft-side
-	       'u',	// R is [u]pper-triangular
-	       'n',	// [n]o-op (R)
-	       'n',	// R is [n]ot unit triangular
-	       b_rows, b_cols,
-	       alpha,
-	       a_ext.data(), m_,
-	       b_ext.data(), b_rows);
-  }
-
-  assign_local(x, b_int);
-
-  return true;
-}
-
-
-
-/// Solve linear least squares problem for x:
-///   min_x norm-2( A x - b )
-
-template <typename T,
-	  bool     Blocked>
-template <typename          Block0,
-	  typename          Block1>
-bool
-Qrd_impl<T, Blocked>::impl_lsqsol(const_Matrix<T, Block0> b, Matrix<T, Block1> x)
-  VSIP_NOTHROW
-{
-  length_type p = b.size(1);
-
-  assert(b.size(0) == m_);
-  assert(x.size(0) == n_);
-  assert(x.size(1) == p);
-
-  length_type c_rows = m_;
-  length_type c_cols = p;
-  
-  int blksize   = lapack::mqr_blksize<T>('l', blas::Blas_traits<T>::trans,
-					 c_rows, c_cols, n_);
-  int mqr_lwork = c_cols*blksize;
-  Temp_buffer<T> mqr_work(mqr_lwork);
-
-  // Solve  A X = B  for X
-  //
-  // 0. factor:             QR X = B
-  //    mult by Q'        Q'QR X = Q'B
-  //    simplify             R X = Q'B
-  //
-  // 1. compute C = Q'B:     R X = C
-  // 2. solve for X:         R X = C
-
-  Matrix<T, data_block_type> c(c_rows, c_cols);
-  assign_local(c, b);
-
-  {
-    Ext_data<data_block_type> c_ext(c.block());
-    Ext_data<data_block_type> a_ext(data_.block());
-
-    // 1. compute C = Q'B:     R X = C
-
-    lapack::mqr('l',				// Q' on [l]eft (C = Q' B)
-		blas::Blas_traits<T>::trans,	// [t]ranspose (Q')
-		c_rows, c_cols, 
-		n_,			// No. elementary reflectors in Q
-		a_ext.data(), m_,
-		&tau_[0],
-		c_ext.data(), c_rows,
-		mqr_work.data(), mqr_lwork);
-		
-    // 2. solve for X:         R X = C
-    //      R (n, n)
-    //      X (n, p)
-    //      C (m, p)
-    // Since R is (n, n), we treat C as an (n, p) matrix.
-
-    blas::trsm('l',	// R appears on [l]eft-side
-	       'u',	// R is [u]pper-triangular
-	       'n',	// [n]o op (R)
-	       'n',	// R is [n]ot unit triangular
-	       n_, c_cols,
-	       T(1),
-	       a_ext.data(), m_,
-	       c_ext.data(), c_rows);
-  }
-
-  assign_local(x, c(Domain<2>(n_, p)));
-
-  return true;
-}
-
-} // namespace vsip::impl
-
 } // namespace vsip
 
 
Index: src/vsip/impl/solver_common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver_common.hpp,v
retrieving revision 1.2
diff -u -r1.2 solver_common.hpp
--- src/vsip/impl/solver_common.hpp	3 May 2006 18:43:10 -0000	1.2
+++ src/vsip/impl/solver_common.hpp	8 May 2006 12:52:58 -0000
@@ -18,7 +18,6 @@
 // Structures for availability
 template <typename   ImplTag,
           typename   T>
-
 struct Is_lud_impl_avail
 {
   static bool const value = false;
@@ -26,12 +25,27 @@
 
 template <typename   ImplTag,
           typename   T>
-
 struct Is_chold_impl_avail
 {
   static bool const value = false;
 };
 
+template <typename   ImplTag,
+          typename   T>
+struct Is_qrd_impl_avail
+{
+  static bool const value = false;
+};
+
+template <typename   ImplTag,
+          typename   T>
+struct Is_svd_impl_avail
+{
+  static bool const value = false;
+};
+
+
+
 // LUD solver impl class
 template <typename T,
           typename ImplTag>
@@ -42,6 +56,20 @@
           typename ImplTag>
 class Chold_impl;
 
+// QR solver impl class
+template <typename T,
+        bool     Blocked,
+        typename ImplTag>
+class Qrd_impl;
+
+// SVD solver impl class
+// template <typename T,
+//         bool     Blocked,
+//         typename ImplTag>
+// class Svd_impl;
+
+
+
 // Implementation tags
 struct Lapack_tag;
 
Index: src/vsip/impl/lapack/solver_qr.hpp
===================================================================
RCS file: src/vsip/impl/lapack/solver_qr.hpp
diff -N src/vsip/impl/lapack/solver_qr.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/lapack/solver_qr.hpp	8 May 2006 12:52:58 -0000
@@ -0,0 +1,523 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/lapack/solver_qr.hpp
+    @author  Jules Bergmann
+    @date    2005-08-19
+    @brief   VSIPL++ Library: QR Linear system solver using Lapack.
+
+*/
+
+#ifndef VSIP_IMPL_LAPACK_SOLVER_QR_HPP
+#define VSIP_IMPL_LAPACK_SOLVER_QR_HPP
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
+#include <vsip/impl/working-view.hpp>
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
+// Specialize Is_lud_impl_avail to indicate what types Lapack QR
+// solver supports.  It supports all BLAS types.
+
+template <typename T>
+struct Is_qrd_impl_avail<Lapack_tag, T>
+{
+  static bool const value = blas::Blas_traits<T>::valid;
+};
+
+
+
+/// QR decomposition implementation class.  Common functionality for
+/// qrd by-value and by-reference classes.
+
+template <typename T,
+	  bool     Blocked>
+class Qrd_impl<T, Blocked, Lapack_tag>
+  : Compile_time_assert<blas::Blas_traits<T>::valid>
+{
+  // BLAS/LAPACK require complex data to be in interleaved format.
+  typedef Layout<2, col2_type, Stride_unit_dense, Cmplx_inter_fmt> data_LP;
+  typedef Fast_block<2, T, data_LP> data_block_type;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  Qrd_impl(length_type, length_type, storage_type)
+    VSIP_THROW((std::bad_alloc));
+  Qrd_impl(Qrd_impl const&)
+    VSIP_THROW((std::bad_alloc));
+
+  Qrd_impl& operator=(Qrd_impl const&) VSIP_NOTHROW;
+  ~Qrd_impl() VSIP_NOTHROW;
+
+  // Accessors.
+public:
+  length_type  rows()     const VSIP_NOTHROW { return m_; }
+  length_type  columns()  const VSIP_NOTHROW { return n_; }
+  storage_type qstorage() const VSIP_NOTHROW { return st_; }
+
+  // Solve systems.
+public:
+  template <typename Block>
+  bool decompose(Matrix<T, Block>) VSIP_NOTHROW;
+
+protected:
+  template <mat_op_type       tr,
+	    product_side_type ps,
+	    typename          Block0,
+	    typename          Block1>
+  bool impl_prodq(const_Matrix<T, Block0>, Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  template <mat_op_type       tr,
+	    typename          Block0,
+	    typename          Block1>
+  bool impl_rsol(const_Matrix<T, Block0>, T const, Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  template <typename          Block0,
+	    typename          Block1>
+  bool impl_covsol(const_Matrix<T, Block0>, Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  template <typename          Block0,
+	    typename          Block1>
+  bool impl_lsqsol(const_Matrix<T, Block0>, Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  // Member data.
+private:
+  typedef std::vector<T, Aligned_allocator<T> > vector_type;
+
+  length_type  m_;			// Number of rows.
+  length_type  n_;			// Number of cols.
+  storage_type st_;			// Q storage type
+
+  Matrix<T, data_block_type> data_;	// Factorized QR matrix
+  vector_type tau_;			// Additional info on Q
+  length_type geqrf_lwork_;		// size of workspace needed for geqrf
+  vector_type geqrf_work_;		// workspace for geqrf
+};
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T,
+	  bool     Blocked>
+Qrd_impl<T, Blocked, Lapack_tag>::Qrd_impl(
+  length_type  rows,
+  length_type  cols,
+  storage_type st
+  )
+VSIP_THROW((std::bad_alloc))
+  : m_          (rows),
+    n_          (cols),
+    st_         (st),
+    data_       (m_, n_),
+    tau_        (n_),
+    geqrf_lwork_(n_ * lapack::geqrf_blksize<T>(m_, n_)),
+    geqrf_work_ (geqrf_lwork_)
+{
+  assert(m_ > 0 && n_ > 0 && m_ >= n_);
+  assert(st_ == qrd_nosaveq || st_ == qrd_saveq || st_ == qrd_saveq1);
+}
+
+
+
+template <typename T,
+	  bool     Blocked>
+Qrd_impl<T, Blocked, Lapack_tag>::Qrd_impl(Qrd_impl const& qr)
+VSIP_THROW((std::bad_alloc))
+  : m_          (qr.m_),
+    n_          (qr.n_),
+    st_         (qr.st_),
+    data_       (m_, n_),
+    tau_        (n_),
+    geqrf_lwork_(qr.geqrf_lwork_),
+    geqrf_work_ (geqrf_lwork_)
+{
+  data_ = qr.data_;
+  for (index_type i=0; i<n_; ++i)
+    tau_[i] = qr.tau_[i];
+}
+
+
+
+template <typename T,
+	  bool     Blocked>
+Qrd_impl<T, Blocked, Lapack_tag>::~Qrd_impl()
+  VSIP_NOTHROW
+{
+}
+
+
+
+/// Decompose matrix M into QR form.
+///
+/// Requires
+///   M to be a full rank, modifiable matrix of ROWS x COLS.
+
+template <typename T,
+	  bool     Blocked>
+template <typename Block>
+bool
+Qrd_impl<T, Blocked, Lapack_tag>::decompose(Matrix<T, Block> m)
+  VSIP_NOTHROW
+{
+  assert(m.size(0) == m_ && m.size(1) == n_);
+
+  int lwork   = geqrf_lwork_;
+
+  assign_local(data_, m);
+
+  Ext_data<data_block_type> ext(data_.block());
+
+  // lda is m_.
+  if (Blocked)
+     lapack::geqrf(m_, n_, ext.data(), m_, &tau_[0], &geqrf_work_[0], lwork);
+  else
+     lapack::geqr2(m_, n_, ext.data(), m_, &tau_[0], &geqrf_work_[0], lwork);
+
+  assert((length_type)lwork <= geqrf_lwork_);
+
+  return true;
+}
+
+
+
+/// Compute product of Q and b
+///
+/// qstoarge   | ps        | tr         | product | b (in) | x (out)
+/// qrd_saveq1 | mat_lside | mat_ntrans | Q b     | (n, p) | (m, p)
+/// qrd_saveq1 | mat_lside | mat_trans  | Q' b    | (m, p) | (n, p)
+/// qrd_saveq1 | mat_lside | mat_herm   | Q* b    | (m, p) | (n, p)
+///
+/// qrd_saveq1 | mat_rside | mat_ntrans | b Q     | (p, m) | (p, n)
+/// qrd_saveq1 | mat_rside | mat_trans  | b Q'    | (p, n) | (p, m)
+/// qrd_saveq1 | mat_rside | mat_herm   | b Q*    | (p, n) | (p, m)
+///
+/// qrd_saveq  | mat_lside | mat_ntrans | Q b     | (m, p) | (m, p)
+/// qrd_saveq  | mat_lside | mat_trans  | Q' b    | (m, p) | (m, p)
+/// qrd_saveq  | mat_lside | mat_herm   | Q* b    | (m, p) | (m, p)
+///
+/// qrd_saveq  | mat_rside | mat_ntrans | b Q     | (p, m) | (p, m)
+/// qrd_saveq  | mat_rside | mat_trans  | b Q'    | (p, m) | (p, m)
+/// qrd_saveq  | mat_rside | mat_herm   | b Q*    | (p, m) | (p, m)
+
+template <typename T,
+	  bool     Blocked>
+template <mat_op_type       tr,
+	  product_side_type ps,
+	  typename          Block0,
+	  typename          Block1>
+bool
+Qrd_impl<T, Blocked, Lapack_tag>::impl_prodq(
+  const_Matrix<T, Block0> b,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  assert(this->qstorage() == qrd_saveq1 || this->qstorage() == qrd_saveq);
+
+  char        side;
+  char        trans;
+  length_type q_rows;
+  length_type q_cols;
+  length_type k_reflectors = n_;
+  int         mqr_lwork;
+
+  if (qstorage() == qrd_saveq1)
+  {
+    q_rows = m_;
+    q_cols = n_;
+  }
+  else // (qstorage() == qrd_saveq1)
+  {
+    q_rows = m_;
+    q_cols = m_;
+  }
+
+  if (tr == mat_trans)
+  {
+    trans = 't';
+    std::swap(q_rows, q_cols);
+  }
+  else if (tr == mat_herm)
+  {
+    trans = 'c';
+    std::swap(q_rows, q_cols);
+  }
+  else // if (tr == mat_ntrans)
+  {
+    trans = 'n';
+  }
+  
+  if (ps == mat_lside)
+  {
+    assert(b.size(0) == q_cols);
+    assert(x.size(0) == q_rows);
+    assert(b.size(1) == x.size(1));
+    side = 'l';
+    mqr_lwork = b.size(1);
+  }
+  else // (ps == mat_rside)
+  {
+    assert(b.size(1) == q_rows);
+    assert(x.size(1) == q_cols);
+    assert(b.size(0) == x.size(0));
+    side = 'r';
+    mqr_lwork = b.size(0);
+  }
+
+  Matrix<T, data_block_type> b_int(b.size(0), b.size(1));
+  assign_local(b_int, b);
+
+  int blksize   = lapack::mqr_blksize<T>(side, trans,
+					 b.size(0), b.size(1), k_reflectors);
+  mqr_lwork *= blksize;
+  Temp_buffer<T> mqr_work(mqr_lwork);
+
+  {
+    Ext_data<data_block_type> b_ext(b_int.block());
+    Ext_data<data_block_type> a_ext(data_.block());
+
+    lapack::mqr(side,
+		trans,
+		b.size(0), b.size(1),
+		k_reflectors,
+		a_ext.data(), m_,
+		&tau_[0],
+		b_ext.data(), b.size(0),
+		mqr_work.data(), mqr_lwork);
+		
+  }
+  assign_local(x, b_int);
+
+  return true;
+}
+
+
+
+/// Solve op(R) x = alpha b
+
+template <typename T,
+	  bool     Blocked>
+template <mat_op_type tr,
+	  typename    Block0,
+	  typename    Block1>
+bool
+Qrd_impl<T, Blocked, Lapack_tag>::impl_rsol(
+  const_Matrix<T, Block0> b,
+  T const                 alpha,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  assert(b.size(0) == n_);
+  assert(b.size(0) == x.size(0));
+  assert(b.size(1) == x.size(1));
+
+  char trans;
+
+  switch(tr)
+  {
+  case mat_trans:
+    // assert(Is_scalar<T>::value);
+    trans = 't';
+    break;
+  case mat_herm:
+    // assert(Is_complex<T>::value);
+    trans = 'c';
+    break;
+  default:
+    trans = 'n';
+    break;
+  }
+
+  Matrix<T, data_block_type> b_int(b.size(0), b.size(1));
+  assign_local(b_int, b);
+  
+
+  {
+    Ext_data<data_block_type> a_ext(data_.block());
+    Ext_data<data_block_type> b_ext(b_int.block());
+      
+    blas::trsm('l',		// R appears on [l]eft-side
+	       'u',		// R is [u]pper-triangular
+	       trans,		// 
+	       'n',		// R is [n]ot unit triangular
+	       b.size(0), b.size(1),
+	       alpha,
+	       a_ext.data(), m_,
+	       b_ext.data(), b_ext.stride(1));
+  }
+  assign_local(x, b_int);
+
+  return true;
+}
+
+
+
+/// Solve covariance system for x:
+///   A' A X = B
+
+template <typename T,
+	  bool     Blocked>
+template <typename Block0,
+	  typename Block1>
+bool
+Qrd_impl<T, Blocked, Lapack_tag>::impl_covsol(
+  const_Matrix<T, Block0> b,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  length_type b_rows = b.size(0);
+  length_type b_cols = b.size(1);
+  T alpha = T(1);
+
+  assert(b_rows == n_);
+
+  // Solve A' A x = b
+
+  // Equiv to solve: R' R x = b
+  // First solve:    R' b_1 = b
+  // Then solve:     R x = b_1
+
+  Matrix<T, data_block_type> b_int(b_rows, b_cols);
+  assign_local(b_int, b);
+
+  {
+    Ext_data<data_block_type> b_ext(b_int.block());
+    Ext_data<data_block_type> a_ext(data_.block());
+
+    // First solve: R' b_1 = b
+
+    blas::trsm('l',	// R' appears on [l]eft-side
+	       'u',	// R is [u]pper-triangular
+	       blas::Blas_traits<T>::trans, // [c]onj/[t]ranspose (conj(R'))
+	       'n',	// R is [n]ot unit triangular
+	       b_rows, b_cols,
+	       alpha,
+	       a_ext.data(), m_,
+	       b_ext.data(), b_rows);
+
+    // Then solve: R x = b_1
+    
+    blas::trsm('l',	// R appears on [l]eft-side
+	       'u',	// R is [u]pper-triangular
+	       'n',	// [n]o-op (R)
+	       'n',	// R is [n]ot unit triangular
+	       b_rows, b_cols,
+	       alpha,
+	       a_ext.data(), m_,
+	       b_ext.data(), b_rows);
+  }
+
+  assign_local(x, b_int);
+
+  return true;
+}
+
+
+
+/// Solve linear least squares problem for x:
+///   min_x norm-2( A x - b )
+
+template <typename T,
+	  bool     Blocked>
+template <typename          Block0,
+	  typename          Block1>
+bool
+Qrd_impl<T, Blocked, Lapack_tag>::impl_lsqsol(
+  const_Matrix<T, Block0> b,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  length_type p = b.size(1);
+
+  assert(b.size(0) == m_);
+  assert(x.size(0) == n_);
+  assert(x.size(1) == p);
+
+  length_type c_rows = m_;
+  length_type c_cols = p;
+  
+  int blksize   = lapack::mqr_blksize<T>('l', blas::Blas_traits<T>::trans,
+					 c_rows, c_cols, n_);
+  int mqr_lwork = c_cols*blksize;
+  Temp_buffer<T> mqr_work(mqr_lwork);
+
+  // Solve  A X = B  for X
+  //
+  // 0. factor:             QR X = B
+  //    mult by Q'        Q'QR X = Q'B
+  //    simplify             R X = Q'B
+  //
+  // 1. compute C = Q'B:     R X = C
+  // 2. solve for X:         R X = C
+
+  Matrix<T, data_block_type> c(c_rows, c_cols);
+  assign_local(c, b);
+
+  {
+    Ext_data<data_block_type> c_ext(c.block());
+    Ext_data<data_block_type> a_ext(data_.block());
+
+    // 1. compute C = Q'B:     R X = C
+
+    lapack::mqr('l',				// Q' on [l]eft (C = Q' B)
+		blas::Blas_traits<T>::trans,	// [t]ranspose (Q')
+		c_rows, c_cols, 
+		n_,			// No. elementary reflectors in Q
+		a_ext.data(), m_,
+		&tau_[0],
+		c_ext.data(), c_rows,
+		mqr_work.data(), mqr_lwork);
+		
+    // 2. solve for X:         R X = C
+    //      R (n, n)
+    //      X (n, p)
+    //      C (m, p)
+    // Since R is (n, n), we treat C as an (n, p) matrix.
+
+    blas::trsm('l',	// R appears on [l]eft-side
+	       'u',	// R is [u]pper-triangular
+	       'n',	// [n]o op (R)
+	       'n',	// R is [n]ot unit triangular
+	       n_, c_cols,
+	       T(1),
+	       a_ext.data(), m_,
+	       c_ext.data(), c_rows);
+  }
+
+  assign_local(x, c(Domain<2>(n_, p)));
+
+  return true;
+}
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+
+#endif // VSIP_IMPL_LAPACK_SOLVER_QR_HPP
Index: src/vsip/impl/sal/solver_qr.hpp
===================================================================
RCS file: src/vsip/impl/sal/solver_qr.hpp
diff -N src/vsip/impl/sal/solver_qr.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/sal/solver_qr.hpp	8 May 2006 12:52:58 -0000
@@ -0,0 +1,610 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/sal/solver_qr.hpp
+    @author  Assem Salama
+    @date    2006-04-17
+    @brief   VSIPL++ Library: QR linear system solver using SAL.
+
+*/
+
+#ifndef VSIP_IMPL_SAL_SOLVER_QR_HPP
+#define VSIP_IMPL_SAL_SOLVER_QR_HPP
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
+#include <sal.h>
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
+// SAL QR decomposition
+#define VSIP_IMPL_SAL_QR_DEC( T, SAL_T, SALFCN )	\
+inline void						\
+sal_mat_qr_dec(						\
+  T* a, int tcols_a,					\
+  T* r, int tcols_r,					\
+  int m, int n)						\
+{							\
+  SALFCN((SAL_T*)a,tcols_a,				\
+         (SAL_T*)r,tcols_r,				\
+	 m,n);						\
+}
+
+#define VSIP_IMPL_SAL_QR_DEC_SPLIT( T, SAL_T, SALFCN )	\
+inline void						\
+sal_mat_qr_dec(						\
+  std::pair<T*,T*> const& a, int tcols_a,		\
+  std::pair<T*,T*> const& r, int tcols_r,		\
+  int m, int n)						\
+{							\
+  SALFCN((SAL_T*)&a,tcols_a,				\
+         (SAL_T*)&r,tcols_r,				\
+	 m,n);						\
+}
+
+VSIP_IMPL_SAL_QR_DEC      (float,          float,          matmgs_dqr)
+VSIP_IMPL_SAL_QR_DEC      (complex<float>, COMPLEX,       cmatmgs_dqr)
+VSIP_IMPL_SAL_QR_DEC_SPLIT(float,          COMPLEX_SPLIT, zmatmgs_dqr)
+
+#undef VSIP_IMPL_SAL_QR_DEC
+#undef VSIP_IMPL_SAL_QR_DEC_SPLIT
+
+// SAL QR r solver
+#define VSIP_IMPL_SAL_QR_RSOL( T, SAL_T, SALFCN )	\
+inline void						\
+sal_mat_qr_rsol(					\
+  T* r, int tcols_r,					\
+  T* b, T* x,						\
+  int n)						\
+{							\
+  SALFCN((SAL_T*)r,tcols_r,				\
+         (SAL_T*)b,					\
+	 (SAL_T*)x,n);					\
+}
+
+#define VSIP_IMPL_SAL_QR_RSOL_SPLIT( T, SAL_T, SALFCN )	\
+inline void						\
+sal_mat_qr_rsol(					\
+  std::pair<T*,T*> const& r, int tcols_r,		\
+  std::pair<T*,T*> const& b,				\
+  std::pair<T*,T*> const& x,				\
+  int n)						\
+{							\
+  SALFCN((SAL_T*)&r, tcols_r,				\
+         (SAL_T*)&b,					\
+	 (SAL_T*)&x, n);				\
+}
+
+VSIP_IMPL_SAL_QR_RSOL      (float,          float,          matmgs_sr)
+VSIP_IMPL_SAL_QR_RSOL      (complex<float>, COMPLEX,       cmatmgs_sr)
+VSIP_IMPL_SAL_QR_RSOL_SPLIT(float,          COMPLEX_SPLIT, zmatmgs_sr)
+
+#undef VSIP_IMPL_SAL_QR_RSOL
+#undef VSIP_IMPL_SAL_QR_RSOL_SPLIT
+
+// SAL QR rhr solver
+#define VSIP_IMPL_SAL_QR_RHSOL( T, SAL_T, SALFCN )	\
+inline void						\
+sal_mat_qr_rhsol(					\
+  T* r, int tcols_r,					\
+  T* b, T* x,						\
+  int n)						\
+{							\
+  SALFCN((SAL_T*)r,tcols_r,				\
+         (SAL_T*)b,					\
+	 (SAL_T*)x,n);					\
+}
+
+// SAL QR rhr solver
+#define VSIP_IMPL_SAL_QR_RHSOL_SPLIT( T, SAL_T, SALFCN )\
+inline void						\
+sal_mat_qr_rhsol(					\
+  std::pair<T*,T*> const& r,				\
+  int tcols_r,						\
+  std::pair<T*,T*> const& b,				\
+  std::pair<T*,T*> const& x,				\
+  int n)						\
+{							\
+  SALFCN((SAL_T*)&r, tcols_r,				\
+         (SAL_T*)&b,					\
+	 (SAL_T*)&x, n);				\
+}
+
+VSIP_IMPL_SAL_QR_RHSOL      (float,          float,          matmgs_srhr)
+VSIP_IMPL_SAL_QR_RHSOL      (complex<float>, COMPLEX,       cmatmgs_srhr)
+VSIP_IMPL_SAL_QR_RHSOL_SPLIT(float,          COMPLEX_SPLIT, zmatmgs_srhr)
+
+#undef VSIP_IMPL_SAL_QR_RHSOL
+#undef VSIP_IMPL_SAL_QR_RHSOL_SPLIT
+
+// A structure that tells us if sal qr impl is available
+// for certain types
+template <>
+struct Is_qrd_impl_avail<Mercury_sal_tag, float>
+{
+  static bool const value = true;
+};
+
+template <>
+struct Is_qrd_impl_avail<Mercury_sal_tag, complex<float> >
+{
+  static bool const value = true;
+};
+
+
+
+/// Qrd implementation using Mercury SAL library.
+
+/// Requires:
+///   T to be a value type supported by SAL's QR routines
+///   BLOCKED is not used (it is used by the Lapack QR implementation
+///      class).
+
+template <typename T,
+	  bool     Blocked>
+class Qrd_impl<T, Blocked, Mercury_sal_tag>
+{
+  // SAL input matrix must be in ROW major form. Sal supports both interleaved
+  // and split complex formats
+  typedef vsip::impl::dense_complex_type   complex_type;
+  typedef Storage<complex_type, T>         cp_storage_type;
+  typedef typename cp_storage_type::type   ptr_type;
+
+  typedef Layout<2, row2_type, Stride_unit_dense, complex_type> data_LP;
+  typedef Fast_block<2, T, data_LP> data_block_type;
+
+  typedef Layout<2, col2_type, Stride_unit_dense, complex_type> t_data_LP;
+  typedef Fast_block<2, T, t_data_LP> t_data_block_type;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  Qrd_impl(length_type, length_type, storage_type)
+    VSIP_THROW((std::bad_alloc));
+  Qrd_impl(Qrd_impl const&)
+    VSIP_THROW((std::bad_alloc));
+
+  Qrd_impl& operator=(Qrd_impl const&) VSIP_NOTHROW;
+  ~Qrd_impl() VSIP_NOTHROW;
+
+  // Accessors.
+public:
+  length_type  rows()     const VSIP_NOTHROW { return m_; }
+  length_type  columns()  const VSIP_NOTHROW { return n_; }
+  storage_type qstorage() const VSIP_NOTHROW { return st_; }
+
+  // Solve systems.
+public:
+  template <typename Block>
+  bool decompose(Matrix<T, Block>) VSIP_NOTHROW;
+
+protected:
+  template <mat_op_type       tr,
+	    product_side_type ps,
+	    typename          Block0,
+	    typename          Block1>
+  bool impl_prodq(const_Matrix<T, Block0>, Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  template <mat_op_type       tr,
+	    typename          Block0,
+	    typename          Block1>
+  bool impl_rsol(const_Matrix<T, Block0>, T const, Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  template <typename          Block0,
+	    typename          Block1>
+  bool impl_covsol(const_Matrix<T, Block0>, Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  template <typename          Block0,
+	    typename          Block1>
+  bool impl_lsqsol(const_Matrix<T, Block0>, Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  // Member data.
+private:
+  typedef std::vector<T, Aligned_allocator<T> > vector_type;
+
+  length_type  m_;			// Number of rows.
+  length_type  n_;			// Number of cols.
+  storage_type st_;			// Q storage type
+
+  Matrix<T, t_data_block_type> data_;	// Factorized QR(mxn) matrix
+  Matrix<T, t_data_block_type> t_data_;	// Factorized QR(mxn) matrix transposed
+  Matrix<T, data_block_type> r_data_;	// Factorized R(nxn) matrix
+  Matrix<T, data_block_type> rt_data_;	// Factorized R(nxn) matrix transposed
+};
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T,
+	  bool     Blocked>
+Qrd_impl<T, Blocked, Mercury_sal_tag>::Qrd_impl(
+  length_type  rows,
+  length_type  cols,
+  storage_type st
+  )
+VSIP_THROW((std::bad_alloc))
+  : m_          (rows),
+    n_          (cols),
+    st_         (st),
+    data_       (m_, n_),
+    t_data_     (n_, m_),
+    r_data_     (n_, n_),
+    rt_data_    (n_, n_)
+{
+  assert(m_ > 0 && n_ > 0 && m_ >= n_);
+  assert(st_ == qrd_nosaveq || st_ == qrd_saveq || st_ == qrd_saveq1);
+
+  // SAL only provides a thin-QR decomposition.
+  if (st_ == qrd_saveq)
+    VSIP_IMPL_THROW(impl::unimplemented(
+	      "Qrd does not support full QR when using SAL(qrd_saveq)"));
+}
+
+
+
+template <typename T,
+	  bool     Blocked>
+Qrd_impl<T, Blocked, Mercury_sal_tag>::Qrd_impl(Qrd_impl const& qr)
+VSIP_THROW((std::bad_alloc))
+  : m_          (qr.m_),
+    n_          (qr.n_),
+    st_         (qr.st_),
+    data_       (m_, n_),
+    t_data_     (n_, m_),
+    r_data_     (n_, n_)
+{
+  data_ = qr.data_;
+}
+
+
+
+template <typename T,
+	  bool     Blocked>
+Qrd_impl<T, Blocked, Mercury_sal_tag>::~Qrd_impl()
+  VSIP_NOTHROW
+{
+}
+
+
+
+/// Decompose matrix M into QR form.
+///
+/// Requires
+///   M to be a full rank, modifiable matrix of ROWS x COLS.
+
+template <typename T,
+	  bool     Blocked>
+template <typename Block>
+bool
+Qrd_impl<T, Blocked, Mercury_sal_tag>::decompose(Matrix<T, Block> m)
+  VSIP_NOTHROW
+{
+  assert(m.size(0) == m_ && m.size(1) == n_);
+
+  assign_local(data_, m);
+
+  Ext_data<t_data_block_type> ext(data_.block());
+  Ext_data<data_block_type> r_ext(r_data_.block());
+
+  sal_mat_qr_dec(ext.data(), m_,
+                 r_ext.data(), n_, 
+		 m_, n_);
+
+  return true;
+}
+
+
+
+/// Compute product of Q and b
+/// 
+/// If qstorage == qrd_saveq1, Q is MxN.
+/// If qstorage == qrd_saveq,  Q is MxM.
+///
+/// qstoarge   | ps        | tr         | product | b (in) | x (out)
+/// qrd_saveq1 | mat_lside | mat_ntrans | Q b     | (n, p) | (m, p)
+/// qrd_saveq1 | mat_lside | mat_trans  | Q' b    | (m, p) | (n, p)
+/// qrd_saveq1 | mat_lside | mat_herm   | Q* b    | (m, p) | (n, p)
+///
+/// qrd_saveq1 | mat_rside | mat_ntrans | b Q     | (p, m) | (p, n)
+/// qrd_saveq1 | mat_rside | mat_trans  | b Q'    | (p, n) | (p, m)
+/// qrd_saveq1 | mat_rside | mat_herm   | b Q*    | (p, n) | (p, m)
+///
+/// qrd_saveq  | mat_lside | mat_ntrans | Q b     | (m, p) | (m, p)
+/// qrd_saveq  | mat_lside | mat_trans  | Q' b    | (m, p) | (m, p)
+/// qrd_saveq  | mat_lside | mat_herm   | Q* b    | (m, p) | (m, p)
+///
+/// qrd_saveq  | mat_rside | mat_ntrans | b Q     | (p, m) | (p, m)
+/// qrd_saveq  | mat_rside | mat_trans  | b Q'    | (p, m) | (p, m)
+/// qrd_saveq  | mat_rside | mat_herm   | b Q*    | (p, m) | (p, m)
+
+template <typename T,
+	  bool     Blocked>
+template <mat_op_type       tr,
+	  product_side_type ps,
+	  typename          Block0,
+	  typename          Block1>
+bool
+Qrd_impl<T, Blocked, Mercury_sal_tag>::impl_prodq(
+  const_Matrix<T, Block0> b,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  assert(this->qstorage() == qrd_saveq1 || this->qstorage() == qrd_saveq);
+
+  length_type q_rows;
+  length_type q_cols;
+
+  if (qstorage() == qrd_saveq1)
+  {
+    q_rows = m_;
+    q_cols = n_;
+  }
+  else // (qstorage() == qrd_saveq1)
+  {
+    assert(0);
+    q_rows = m_;
+    q_cols = m_;
+  }
+
+  // do we need a transpose?
+  if(tr == mat_trans || tr == mat_herm) 
+  {
+    t_data_ = data_.transpose();
+    std::swap(q_rows, q_cols);
+  }
+  if(tr == mat_herm) 
+  {
+    t_data_ = impl::impl_conj(t_data_);
+    std::swap(q_rows, q_cols);
+  }
+
+  // left or right?
+  if(ps == mat_lside) 
+  {
+    assert(b.size(0) == q_cols);
+    assert(x.size(0) == q_rows);
+    assert(b.size(1) == x.size(1));
+
+    generic_prod(tr == mat_trans || tr == mat_herm ? t_data_ : data_, b, x);
+  }
+  else
+  {
+    assert(b.size(1) == q_rows);
+    assert(x.size(1) == q_cols);
+    assert(b.size(0) == x.size(0));
+
+    generic_prod(b, tr == mat_trans || tr == mat_herm ? t_data_ : data_, x);
+  }
+
+  return true;
+}
+
+
+
+/// Solve op(R) x = alpha b
+
+template <typename T,
+	  bool     Blocked>
+template <mat_op_type tr,
+	  typename    Block0,
+	  typename    Block1>
+bool
+Qrd_impl<T, Blocked, Mercury_sal_tag>::impl_rsol(
+  const_Matrix<T, Block0> b,
+  T const                 alpha,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  assert(b.size(0) == n_);
+  assert(b.size(0) == x.size(0));
+  assert(b.size(1) == x.size(1));
+
+  Matrix<T, t_data_block_type> b_int(b.size(0), b.size(1));
+  Matrix<T, t_data_block_type> x_int(x.size(0), x.size(1));
+
+  if(tr == mat_ntrans)
+  {
+    assign_local(b_int, b);
+
+    // multiply b by alpha
+    b_int *= alpha;
+
+    {
+      Ext_data<t_data_block_type> b_ext(b_int.block());
+      Ext_data<t_data_block_type> x_ext(x_int.block());
+      Ext_data<data_block_type>   r_ext(r_data_.block());
+
+      ptr_type b_ptr = b_ext.data();
+      ptr_type x_ptr = x_ext.data();
+      
+      for(length_type i=0;i < b.size(1);i++)
+      {
+	sal_mat_qr_rsol(r_ext.data(), n_,
+			cp_storage_type::offset(b_ptr,i*n_),
+			cp_storage_type::offset(x_ptr,i*n_),
+			n_);
+      }
+    }
+    assign_local(x,x_int);
+  }
+  else
+  {
+    rt_data_ = r_data_(Domain<2>(Domain<1>(n_-1, -1, n_),
+				 Domain<1>(n_-1, -1, n_)));
+
+    Domain<2> flip(Domain<1>(b.size(0)-1, -1, b.size(0)),
+		   Domain<1>(b.size(1)-1, -1, b.size(1)));
+
+    assign_local(b_int, b(flip));
+
+    // multiply b by alpha
+    b_int *= alpha;
+
+    if(tr == mat_herm) rt_data_ = impl::impl_conj(rt_data_);
+
+    {
+      Ext_data<t_data_block_type> b_ext(b_int.block());
+      Ext_data<t_data_block_type> x_ext(x_int.block());
+      Ext_data<data_block_type>   r_ext(rt_data_.block());
+
+      ptr_type b_ptr = b_ext.data();
+      ptr_type x_ptr = x_ext.data();
+
+      // It turns out if I want to solve R'x=b, I need to read everything
+      // backwards!. That is why I'm remaping the matrixes using negative
+      // strides.
+
+      for(length_type i=0;i < b.size(1);i++)
+      {
+        sal_mat_qr_rsol(r_ext.data(), n_,
+		      cp_storage_type::offset(b_ptr,i*n_),
+		      cp_storage_type::offset(x_ptr,i*n_),
+		      n_);
+      }
+    }
+
+    // X is now backwards too. Have to flip it arround!
+    assign_local(x, x_int(flip));
+  }
+  
+  return true;
+}
+
+
+
+/// Solve covariance system for x:
+///   A' A X = B
+
+template <typename T,
+	  bool     Blocked>
+template <typename Block0,
+	  typename Block1>
+bool
+Qrd_impl<T, Blocked, Mercury_sal_tag>::
+impl_covsol(const_Matrix<T, Block0> b, Matrix<T, Block1> x)
+  VSIP_NOTHROW
+{
+  Matrix<T, t_data_block_type> b_int(b.size(0), b.size(1));
+  Matrix<T, t_data_block_type> x_int(x.size(0), x.size(1));
+
+  assign_local(b_int, b);
+
+  {
+    Ext_data<t_data_block_type> b_ext(b_int.block());
+    Ext_data<t_data_block_type> x_ext(x_int.block());
+    Ext_data<data_block_type>   r_ext(r_data_.block());
+
+    ptr_type b_ptr = b_ext.data();
+    ptr_type x_ptr = x_ext.data();
+
+    // Because SAL only wants x and b as vectors, we have to look at each
+    // column.
+    for(length_type i=0;i<b.size(1);i++)
+    {
+      sal_mat_qr_rhsol(r_ext.data(), n_,
+		      cp_storage_type::offset(b_ptr,i*n_),
+		      cp_storage_type::offset(x_ptr,i*n_),
+		      n_);
+    }
+  }
+
+  assign_local(x, x_int);
+
+  return true;
+}
+
+
+
+/// Solve linear least squares problem for x:
+///   min_x norm-2( A x - b )
+
+template <typename T,
+	  bool     Blocked>
+template <typename Block0,
+	  typename Block1>
+bool
+Qrd_impl<T, Blocked, Mercury_sal_tag>::
+impl_lsqsol(const_Matrix<T, Block0> b, Matrix<T, Block1> x)
+  VSIP_NOTHROW
+{
+  length_type p = b.size(1);
+
+  assert(b.size(0) == m_);
+  assert(x.size(0) == n_);
+  assert(x.size(1) == p);
+ 
+  Matrix<T, t_data_block_type> x_int(x.size(0), x.size(1));
+
+  // C will be Q'b, Q' is nxm, so, c is nxb.size(1)
+  Matrix<T, t_data_block_type> c_int(n_, b.size(1));
+
+
+
+  // Solve  A X = B  for X
+  //
+  // 0. factor:             QR X = B
+  //    mult by Q'        Q'QR X = Q'B
+  //    simplify             R X = Q'B
+  //
+  // 1. compute C = Q'B:     R X = C
+  // 2. solve for X:         R X = C
+
+  t_data_ = data_.transpose();
+  if (Is_complex<T>::value) t_data_ = impl::impl_conj(t_data_);
+  generic_prod(t_data_,b,c_int);
+
+  assign_local(x_int, x);
+
+  // Ok, now, solve Rx=C
+  {
+    Ext_data<t_data_block_type> x_ext(x_int.block());
+    Ext_data<t_data_block_type> c_ext(c_int.block());
+    Ext_data<data_block_type>   r_ext(r_data_.block());
+
+    ptr_type c_ptr = c_ext.data();
+    ptr_type x_ptr = x_ext.data();
+
+    // Because SAL only wants x and b as vectors, we have to look at each
+    // column.
+    for(length_type i=0;i<x.size(1);i++)
+    {
+      sal_mat_qr_rsol(r_ext.data(), n_,
+		      cp_storage_type::offset(c_ptr,i*n_),
+		      cp_storage_type::offset(x_ptr,i*n_),
+		      n_);
+    }
+  }
+
+  assign_local(x,x_int);
+
+  return true;
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_SAL_SOLVER_QR_HPP
Index: tests/solver-qr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-qr.cpp,v
retrieving revision 1.7
diff -u -r1.7 solver-qr.cpp
--- tests/solver-qr.cpp	10 Feb 2006 22:24:02 -0000	1.7
+++ tests/solver-qr.cpp	8 May 2006 12:52:58 -0000
@@ -24,8 +24,15 @@
 #include "test-storage.hpp"
 #include "solver-common.hpp"
 
-#define VERBOSE  0
-#define DO_SWEEP 0
+#define VERBOSE        0
+#define DO_SWEEP       0
+#define NORMAL_EPSILON 0
+
+#ifdef VSIP_IMPL_HAVE_LAPACK
+#  define EXPECT_FULL_COVERAGE 1
+#else
+#  define EXPECT_FULL_COVERAGE 0
+#endif
 
 #if VERBOSE
 #  include <iostream>
@@ -47,9 +54,10 @@
 template <typename T>
 void
 test_covsol_diag(
-  length_type m = 5,
-  length_type n = 5,
-  length_type p = 2
+  length_type  m = 5,
+  length_type  n = 5,
+  length_type  p = 2,
+  storage_type st
   )
 {
   test_assert(m >= n);
@@ -64,11 +72,11 @@
   if (n > 2) a(2, 2)  = Test_traits<T>::value2();
   if (n > 3) a(3, 3)  = Test_traits<T>::value3();
 
-  qrd<T, by_reference> qr(m, n, qrd_saveq);
+  qrd<T, by_reference> qr(m, n, st);
 
   test_assert(qr.rows()     == m);
   test_assert(qr.columns()  == n);
-  test_assert(qr.qstorage() == qrd_saveq);
+  test_assert(qr.qstorage() == st);
 
   qr.decompose(a);
 
@@ -96,9 +104,10 @@
 	  typename MapT>
 void
 test_covsol_random(
-  length_type m,
-  length_type n,
-  length_type p)
+  length_type  m,
+  length_type  n,
+  length_type  p,
+  storage_type st)
 {
   test_assert(m >= n);
 
@@ -112,11 +121,11 @@
 
   randm(a);
 
-  qrd<T, by_reference> qr(m, n, qrd_saveq);
+  qrd<T, by_reference> qr(m, n, st);
 
   test_assert(qr.rows()     == m);
   test_assert(qr.columns()  == n);
-  test_assert(qr.qstorage() == qrd_saveq);
+  test_assert(qr.qstorage() == st);
 
   qr.decompose(a);
 
@@ -153,46 +162,85 @@
 
 
 template <typename T>
-void covsol_cases()
-{
-  test_covsol_diag<T>(1,   1, 2);
-  test_covsol_diag<T>(5,   5, 2);
-  test_covsol_diag<T>(6,   6, 2);
-  test_covsol_diag<T>(17, 17, 2);
-
-  test_covsol_diag<T>(1,   1, 3);
-  test_covsol_diag<T>(5,   5, 3);
-  test_covsol_diag<T>(17, 17, 3);
-
-  test_covsol_diag<T>(3,   1, 3);
-  test_covsol_diag<T>(5,   3, 3);
-  test_covsol_diag<T>(17, 11, 3);
-
-  test_covsol_random<T, Local_map>(1,   1, 2);
-  test_covsol_random<T, Local_map>(5,   5, 2);
-  test_covsol_random<T, Local_map>(17, 17, 2);
-
-  test_covsol_random<T, Local_map>(1,   1, 3);
-  test_covsol_random<T, Local_map>(5,   5, 3);
-  test_covsol_random<T, Local_map>(17, 17, 3);
-
-  test_covsol_random<T, Local_map>(3,   1, 3);
-  test_covsol_random<T, Local_map>(5,   3, 3);
-  test_covsol_random<T, Local_map>(17, 11, 3);
+void covsol_cases(
+  storage_type st,
+  vsip::impl::Bool_type<true>)
+{
+  test_covsol_diag<T>(1,   1, 2, st);
+  test_covsol_diag<T>(5,   5, 2, st);
+  test_covsol_diag<T>(6,   6, 2, st);
+  test_covsol_diag<T>(17, 17, 2, st);
+
+  test_covsol_diag<T>(1,   1, 3, st);
+  test_covsol_diag<T>(5,   5, 3, st);
+  test_covsol_diag<T>(17, 17, 3, st);
+
+  test_covsol_diag<T>(3,   1, 3, st);
+  test_covsol_diag<T>(5,   3, 3, st);
+  test_covsol_diag<T>(17, 11, 3, st);
+
+  test_covsol_random<T, Local_map>(1,   1, 2, st);
+  test_covsol_random<T, Local_map>(5,   5, 2, st);
+  test_covsol_random<T, Local_map>(17, 17, 2, st);
+
+  test_covsol_random<T, Local_map>(1,   1, 3, st);
+  test_covsol_random<T, Local_map>(5,   5, 3, st);
+  test_covsol_random<T, Local_map>(17, 17, 3, st);
+
+  test_covsol_random<T, Local_map>(3,   1, 3, st);
+  test_covsol_random<T, Local_map>(5,   3, 3, st);
+  test_covsol_random<T, Local_map>(17, 11, 3, st);
 
 #if DO_SWEEP
   for (index_type i=1; i<100; i+= 8)
     for (index_type j=1; j<10; j += 4)
     {
-      test_covsol_random<T, Local_map>(i,   i,   j+1);
-      test_covsol_random<T, Local_map>(i+1, i+1, j);
-      test_covsol_random<T, Local_map>(i+2, i+2, j+2);
+      test_covsol_random<T, Local_map>(i,   i,   j+1, st);
+      test_covsol_random<T, Local_map>(i+1, i+1, j,   st);
+      test_covsol_random<T, Local_map>(i+2, i+2, j+2, st);
     }
 #endif
 }
 
 
 
+template <typename T>
+void covsol_cases(
+  storage_type,
+  vsip::impl::Bool_type<false>)
+{
+  test_assert(!EXPECT_FULL_COVERAGE);
+}
+
+
+
+// Front-end function for covsol_cases.
+
+// This function dispatches to either real set of tests or an empty
+// function depending on whether the QR backends configured in support
+// value type T.  (Not all QR backends support all value types).
+
+template <typename T>
+void covsol_cases(storage_type st)
+{
+  using vsip::impl::Bool_type;
+  using vsip::impl::Type_equal;
+  using vsip::impl::Choose_qrd_impl;
+  using vsip::impl::None_type;
+  using vsip::impl::Mercury_sal_tag;
+
+  // Qrd doesn't support full QR when using SAL (060507).
+  if (Type_equal<typename Choose_qrd_impl<T>::type, Mercury_sal_tag>::value &&
+      st == qrd_saveq)
+    return;
+
+  covsol_cases<T>(st,
+		  Bool_type<!Type_equal<typename Choose_qrd_impl<T>::type,
+		                        None_type>::value>());
+}
+
+
+
 /***********************************************************************
   Linear Least Squares tests
 ***********************************************************************/
@@ -200,9 +248,10 @@
 template <typename T>
 void
 test_lsqsol_diag(
-  length_type m,
-  length_type n,
-  length_type p)
+  length_type  m,
+  length_type  n,
+  length_type  p,
+  storage_type st)
 {
   test_assert(m >= n);
 
@@ -216,11 +265,11 @@
   if (n > 2) a(2, 2)  = Test_traits<T>::value2();
   if (n > 3) a(3, 3)  = Test_traits<T>::value3();
 
-  qrd<T, by_reference> qr(m, n, qrd_saveq);
+  qrd<T, by_reference> qr(m, n, st);
 
   test_assert(qr.rows()     == m);
   test_assert(qr.columns()  == n);
-  test_assert(qr.qstorage() == qrd_saveq);
+  test_assert(qr.qstorage() == st);
 
   qr.decompose(a);
 
@@ -249,9 +298,10 @@
 	  typename MapT>
 void
 test_lsqsol_random(
-  length_type m,
-  length_type n,
-  length_type p)
+  length_type  m,
+  length_type  n,
+  length_type  p,
+  storage_type st)
 {
   test_assert(m >= n);
 
@@ -278,11 +328,11 @@
     b.row(i) = T(i-n+2) * b.row(i-n);
   }
 
-  qrd<T, by_reference> qr(m, n, qrd_saveq);
+  qrd<T, by_reference> qr(m, n, st);
 
   test_assert(qr.rows()     == m);
   test_assert(qr.columns()  == n);
-  test_assert(qr.qstorage() == qrd_saveq);
+  test_assert(qr.qstorage() == st);
 
   qr.decompose(a);
 
@@ -297,15 +347,32 @@
   cout << "x = " << endl << x << endl;
   cout << "b = " << endl << b << endl;
   cout << "chk = " << endl << chk << endl;
+  cout << "adiff = " << endl << mag(b-chk) << endl;
+  cout << "rdiff1 = " << endl << mag((b-chk)/b) << endl;
+  cout << "rdiff2 = " << endl << mag(b-chk)/mag(b) << endl;
   cout << "lsqsol<" << Type_name<T>::name()
        << ">(" << m << ", " << n << ", " << p << "): " << err << endl;
 #endif
 
-  if (err > 10.0)
+  typedef typename impl::Scalar_of<T>::type scalar_type;
+#if NORMAL_EPSILON
+  // These are almost_equal()'s normal epsilon.  They work fine for Lapack.
+  scalar_type rel_epsilon = 1e-3;
+  scalar_type abs_epsilon = 1e-5;
+  float       err_bound   = 10.0;
+#else
+  // These are looser bounds.  They are necessary for SAL.
+  scalar_type rel_epsilon = 1e-3;
+  scalar_type abs_epsilon = 1e-5;
+  float       err_bound   = 50.0;
+#endif
+
+  if (err > err_bound)
   {
     for (index_type r=0; r<m; ++r)
       for (index_type c=0; c<p; ++c)
-	test_assert(equal(b(r, c), chk(r, c)));
+	test_assert(almost_equal(b.get(r, c), chk.get(r, c),
+				 rel_epsilon, abs_epsilon));
   }
 
   // test_assert(err < 10.0);
@@ -314,46 +381,81 @@
 
 
 template <typename T>
-void lsqsol_cases()
-{
-  test_lsqsol_diag<T>(1,   1, 2);
-  test_lsqsol_diag<T>(5,   5, 2);
-  test_lsqsol_diag<T>(6,   6, 2);
-  test_lsqsol_diag<T>(17, 17, 2);
-
-  test_lsqsol_diag<T>(1,   1, 3);
-  test_lsqsol_diag<T>(5,   5, 3);
-  test_lsqsol_diag<T>(17, 17, 3);
-
-  test_lsqsol_diag<T>(3,   1, 3);
-  test_lsqsol_diag<T>(5,   3, 3);
-  test_lsqsol_diag<T>(17, 11, 3);
-
-  test_lsqsol_random<T, Local_map>(1,   1, 2);
-  test_lsqsol_random<T, Local_map>(5,   5, 2);
-  test_lsqsol_random<T, Local_map>(17, 17, 2);
-
-  test_lsqsol_random<T, Local_map>(1,   1, 3);
-  test_lsqsol_random<T, Local_map>(5,   5, 3);
-  test_lsqsol_random<T, Local_map>(17, 17, 3);
-
-  test_lsqsol_random<T, Local_map>(3,   1, 3);
-  test_lsqsol_random<T, Local_map>(5,   3, 3);
-  test_lsqsol_random<T, Local_map>(17, 11, 3);
+void lsqsol_cases(
+  storage_type st,
+  vsip::impl::Bool_type<true>)
+{
+  test_lsqsol_diag<T>(1,   1, 2, st);
+  test_lsqsol_diag<T>(5,   5, 2, st);
+  test_lsqsol_diag<T>(6,   6, 2, st);
+  test_lsqsol_diag<T>(17, 17, 2, st);
+
+  test_lsqsol_diag<T>(1,   1, 3, st);
+  test_lsqsol_diag<T>(5,   5, 3, st);
+  test_lsqsol_diag<T>(17, 17, 3, st);
+
+  test_lsqsol_diag<T>(3,   1, 3, st);
+  test_lsqsol_diag<T>(5,   3, 3, st);
+  test_lsqsol_diag<T>(17, 11, 3, st);
+
+  test_lsqsol_random<T, Local_map>(1,   1, 2, st);
+  test_lsqsol_random<T, Local_map>(5,   5, 2, st);
+  test_lsqsol_random<T, Local_map>(17, 17, 2, st);
+
+  test_lsqsol_random<T, Local_map>(1,   1, 3, st);
+  test_lsqsol_random<T, Local_map>(5,   5, 3, st);
+  test_lsqsol_random<T, Local_map>(17, 17, 3, st);
+
+  test_lsqsol_random<T, Local_map>(3,   1, 3, st);
+  test_lsqsol_random<T, Local_map>(5,   3, 3, st);
+  test_lsqsol_random<T, Local_map>(17, 11, 3, st);
 
 #if DO_SWEEP
   for (index_type i=1; i<100; i+= 8)
     for (index_type j=1; j<10; j += 4)
     {
-      test_lsqsol_random<T, Local_map>(i,   i,   j+1);
-      test_lsqsol_random<T, Local_map>(i+1, i+1, j);
-      test_lsqsol_random<T, Local_map>(i+2, i+2, j+2);
+      test_lsqsol_random<T, Local_map>(i,   i,   j+1, st);
+      test_lsqsol_random<T, Local_map>(i+1, i+1, j,   st);
+      test_lsqsol_random<T, Local_map>(i+2, i+2, j+2, st);
     }
 #endif
 }
 
 
 
+template <typename T>
+void lsqsol_cases(
+  storage_type,
+  vsip::impl::Bool_type<false>)
+{
+  test_assert(!EXPECT_FULL_COVERAGE);
+}
+
+
+
+// Front-end function for lsqsol_cases.
+
+template <typename T>
+void lsqsol_cases(storage_type st)
+{
+  using vsip::impl::Bool_type;
+  using vsip::impl::Type_equal;
+  using vsip::impl::Choose_qrd_impl;
+  using vsip::impl::None_type;
+  using vsip::impl::Mercury_sal_tag;
+
+  // Qrd doesn't support full QR when using SAL (060507).
+  if (Type_equal<typename Choose_qrd_impl<T>::type, Mercury_sal_tag>::value &&
+      st == qrd_saveq)
+    return;
+
+  lsqsol_cases<T>(st,
+		  Bool_type<!Type_equal<typename Choose_qrd_impl<T>::type,
+		                        None_type>::value>());
+}
+
+
+
 /***********************************************************************
   Rsol tests
 ***********************************************************************/
@@ -362,9 +464,10 @@
 	  typename MapT>
 void
 test_rsol_diag(
-  length_type m,
-  length_type n,
-  length_type p)
+  length_type  m,
+  length_type  n,
+  length_type  p,
+  storage_type st)
 {
   test_assert(m >= n);
 
@@ -384,11 +487,11 @@
   if (n > 2) a(2, 2)  = Test_traits<T>::value2();
   if (n > 3) a(3, 3)  = Test_traits<T>::value3();
 
-  qrd<T, by_reference> qr(m, n, qrd_saveq);
+  qrd<T, by_reference> qr(m, n, st);
 
   test_assert(qr.rows()     == m);
   test_assert(qr.columns()  == n);
-  test_assert(qr.qstorage() == qrd_saveq);
+  test_assert(qr.qstorage() == st);
 
   qr.decompose(a);
 
@@ -398,94 +501,135 @@
   //   For complex<T>, Q should be unitary
   // (For complex, we can use Q to check rsol)
 
-  Matrix<T, block_type> I(m, m, T(), map);
-  // I.diag() = T(1);
-  for (index_type i=0; i<m; ++i)
-    I.put(i, i, T(1));
-  Matrix<T, block_type> qi(m, m, map);
-  Matrix<T, block_type> iq(m, m, map);
-  Matrix<T, block_type> qtq(m, m, map);
-
-  // First, check multiply w/identity from left-side:
-  //   Q I = qi
-  qr.template prodq<mat_ntrans, mat_lside>(I, qi);
-
-  for (index_type i=0; i<m; ++i)
-    for (index_type j=0; j<m; ++j)
-      if (i == j)
-	test_assert(equal(qi(i, j) * tconj<T>(qi(i, j)), T(1)));
-      else
-	test_assert(equal(qi(i, j), T()));
-
-  // Next, check multiply w/identity from right-side:
-  //   I Q = iq
-  // (should get same answer as qi)
-  qr.template prodq<mat_ntrans, mat_rside>(I, iq);
-
-  for (index_type i=0; i<m; ++i)
-    for (index_type j=0; j<m; ++j)
-    {
-      if (i == j)
-	test_assert(equal(iq(i, j) * tconj<T>(qi(i, j)), T(1)));
-      else
-	test_assert(equal(iq(i, j), T()));
-      test_assert(equal(iq(i, j), qi(i, j)));
-    }
+  // Currently, we can only check rsol if doing a full QR, or if
+  // doing a thing QR when m == n.
+  if (st == qrd_saveq || (st == qrd_saveq1 && m == n))
+  {
+    Matrix<T, block_type> I(m, m, T(), map);
+    // I.diag() = T(1);
+    for (index_type i=0; i<m; ++i)
+      I.put(i, i, T(1));
+    Matrix<T, block_type> qi(m, m, map);
+    Matrix<T, block_type> iq(m, m, map);
+    Matrix<T, block_type> qtq(m, m, map);
+
+    // First, check multiply w/identity from left-side:
+    //   Q I = qi
+    qr.template prodq<mat_ntrans, mat_lside>(I, qi);
+
+    for (index_type i=0; i<m; ++i)
+      for (index_type j=0; j<m; ++j)
+	if (i == j)
+	  test_assert(equal(qi(i, j) * tconj<T>(qi(i, j)), T(1)));
+	else
+	  test_assert(equal(qi(i, j), T()));
+
+    // Next, check multiply w/identity from right-side:
+    //   I Q = iq
+    // (should get same answer as qi)
+    qr.template prodq<mat_ntrans, mat_rside>(I, iq);
+
+    for (index_type i=0; i<m; ++i)
+      for (index_type j=0; j<m; ++j)
+      {
+	if (i == j)
+	  test_assert(equal(iq(i, j) * tconj<T>(qi(i, j)), T(1)));
+	else
+	  test_assert(equal(iq(i, j), T()));
+	test_assert(equal(iq(i, j), qi(i, j)));
+      }
+
+    // Next, check hermitian multiply w/Q from left-side:
+    //   Q' (qi) = I
+    //   Q' Q    = I
+    mat_op_type const tr = impl::Is_complex<T>::value ? mat_herm : mat_trans;
+    qr.template prodq<tr, mat_lside>(qi, qtq);
 
-  // Next, check hermitian multiply w/Q from left-side:
-  //   Q' (qi) = I
-  //   Q' Q    = I
-  mat_op_type const tr = impl::Is_complex<T>::value ? mat_herm : mat_trans;
-  qr.template prodq<tr, mat_lside>(qi, qtq);
-
-  // Result should be I
-  for (index_type i=0; i<m; ++i)
-    for (index_type j=0; j<m; ++j)
-      test_assert(equal(qtq(i, j), I(i, j)));
+    // Result should be I
+    for (index_type i=0; i<m; ++i)
+      for (index_type j=0; j<m; ++j)
+	test_assert(equal(qtq(i, j), I(i, j)));
 
   
-  // -------------------------------------------------------------------
-  // Check rsol()
+    // -----------------------------------------------------------------
+    // Check rsol()
 
-  for (index_type i=0; i<p; ++i)
-    test_ramp(b.col(i), T(1), T(i));
-  if (p > 1) b.col(1) += Test_traits<T>::offset();
-
-  T alpha = T(2);
+    for (index_type i=0; i<p; ++i)
+      test_ramp(b.col(i), T(1), T(i));
+    if (p > 1) b.col(1) += Test_traits<T>::offset();
+    
+    T alpha = T(2);
 
-  qr.template rsol<mat_ntrans>(b, alpha, x);
+    qr.template rsol<mat_ntrans>(b, alpha, x);
 
 #if VERBOSE
-  cout << "a = " << endl << a << endl;
-  cout << "x = " << endl << x << endl;
-  cout << "b = " << endl << b << endl;
-  cout << "qi = " << endl << qi << endl;
+    cout << "a = " << endl << a << endl;
+    cout << "x = " << endl << x << endl;
+    cout << "b = " << endl << b << endl;
+    cout << "qi = " << endl << qi << endl;
 #endif
 
-  // a * x = alpha * Q * b
+    // a * x = alpha * Q * b
 
-  for (index_type i=0; i<b.size(0); ++i)
-    for (index_type j=0; j<b.size(1); ++j)
-      test_assert(equal(alpha * qi(i, i) * b(i, j),
-		   a(i, i) * x(i, j)));
+    for (index_type i=0; i<b.size(0); ++i)
+      for (index_type j=0; j<b.size(1); ++j)
+	test_assert(equal(alpha * qi(i, i) * b(i, j),
+			  a(i, i) * x(i, j)));
+  }
+}
+
+
+template <typename T>
+void
+rsol_cases(
+  storage_type st,
+  vsip::impl::Bool_type<true>)
+{
+  test_rsol_diag<T, Local_map>( 1,   1, 2, st);
+  test_rsol_diag<T, Local_map>( 5,   4, 2, st);
+  test_rsol_diag<T, Local_map>( 5,   5, 2, st);
+  test_rsol_diag<T, Local_map>( 6,   6, 2, st);
+  test_rsol_diag<T, Local_map>(17,  17, 2, st);
+  test_rsol_diag<T, Local_map>(17,  11, 2, st);
+
+  test_rsol_diag<T, Local_map>( 5,   2, 2, st);
+  test_rsol_diag<T, Local_map>( 5,   3, 2, st);
+  test_rsol_diag<T, Local_map>( 5,   4, 2, st);
+  test_rsol_diag<T, Local_map>( 11,  5, 2, st);
 }
 
 
+
 template <typename T>
 void
-rsol_cases()
+rsol_cases(
+  storage_type,
+  vsip::impl::Bool_type<false>)
 {
-  test_rsol_diag<T, Local_map>( 1,   1, 2);
-  test_rsol_diag<T, Local_map>( 5,   4, 2);
-  test_rsol_diag<T, Local_map>( 5,   5, 2);
-  test_rsol_diag<T, Local_map>( 6,   6, 2);
-  test_rsol_diag<T, Local_map>(17,  17, 2);
-  test_rsol_diag<T, Local_map>(17,  11, 2);
-
-  test_rsol_diag<T, Local_map>( 5,   2, 2);
-  test_rsol_diag<T, Local_map>( 5,   3, 2);
-  test_rsol_diag<T, Local_map>( 5,   4, 2);
-  test_rsol_diag<T, Local_map>( 11,  5, 2);
+  test_assert(!EXPECT_FULL_COVERAGE);
+}
+
+
+
+// Front-end function for rsol_cases.
+
+template <typename T>
+void rsol_cases(storage_type st)
+{
+  using vsip::impl::Bool_type;
+  using vsip::impl::Type_equal;
+  using vsip::impl::Choose_qrd_impl;
+  using vsip::impl::None_type;
+  using vsip::impl::Mercury_sal_tag;
+
+  // Qrd doesn't support full QR when using SAL (060507).
+  if (Type_equal<typename Choose_qrd_impl<T>::type, Mercury_sal_tag>::value &&
+      st == qrd_saveq)
+    return;
+
+  rsol_cases<T>(st,
+		  Bool_type<!Type_equal<typename Choose_qrd_impl<T>::type,
+		                        None_type>::value>());
 }
 
 
@@ -525,7 +669,7 @@
     test_assert(x.size(0) == n);
     test_assert(x.size(1) == p);
     
-    qrd<T, by_reference> qr(m, n, qrd_saveq);
+    qrd<T, by_reference> qr(m, n, qrd_saveq1);
     
     qr.decompose(a);
     
@@ -571,7 +715,7 @@
     test_assert(x.size(0) == n);
     test_assert(x.size(1) == p);
     
-    qrd<T, by_value> qr(m, n, qrd_saveq);
+    qrd<T, by_value> qr(m, n, qrd_saveq1);
     
     qr.decompose(a);
     
@@ -702,7 +846,7 @@
 
 template <return_mechanism_type RtM,
 	  typename              T>
-void f_covsol_cases()
+void f_covsol_cases(vsip::impl::Bool_type<true>)
 {
   test_f_covsol_diag<RtM, T>(1,   1, 2);
   test_f_covsol_diag<RtM, T>(5,   5, 2);
@@ -739,6 +883,34 @@
     }
 #endif
 }
+
+
+
+template <return_mechanism_type RtM,
+	  typename              T>
+void f_covsol_cases(vsip::impl::Bool_type<false>)
+{
+  test_assert(!EXPECT_FULL_COVERAGE);
+}
+
+
+
+// Front-end function for f_covsol_cases.
+
+template <return_mechanism_type RtM,
+	  typename              T>
+void f_covsol_cases()
+{
+  using vsip::impl::Bool_type;
+  using vsip::impl::Type_equal;
+  using vsip::impl::Choose_qrd_impl;
+  using vsip::impl::None_type;
+  using vsip::impl::Mercury_sal_tag;
+
+  f_covsol_cases<RtM, T>(
+    Bool_type<!Type_equal<typename Choose_qrd_impl<T>::type,
+		          None_type>::value>());
+}
   
 
 
@@ -974,7 +1146,7 @@
 
 template <return_mechanism_type RtM,
 	  typename              T>
-void f_lsqsol_cases()
+void f_lsqsol_cases(vsip::impl::Bool_type<true>)
 {
   test_f_lsqsol_diag<RtM, T>(1,   1, 2);
   test_f_lsqsol_diag<RtM, T>(5,   5, 2);
@@ -1014,6 +1186,38 @@
 
 
 
+template <return_mechanism_type RtM,
+	  typename              T>
+void f_lsqsol_cases(vsip::impl::Bool_type<false>)
+{
+  test_assert(!EXPECT_FULL_COVERAGE);
+}
+
+
+
+// Front-end function for f_lsqsol_cases.
+
+template <return_mechanism_type RtM,
+	  typename              T>
+void f_lsqsol_cases()
+{
+  using vsip::impl::Bool_type;
+  using vsip::impl::Type_equal;
+  using vsip::impl::Choose_qrd_impl;
+  using vsip::impl::None_type;
+  using vsip::impl::Mercury_sal_tag;
+
+  // Qrd doesn't support full Q when using SAL (060507).
+  if (Type_equal<typename Choose_qrd_impl<T>::type, Mercury_sal_tag>::value)
+    return;
+
+  f_lsqsol_cases<RtM, T>(
+    Bool_type<!Type_equal<typename Choose_qrd_impl<T>::type,
+		          None_type>::value>());
+}
+
+
+
 /***********************************************************************
   Main
 ***********************************************************************/
@@ -1031,20 +1235,34 @@
   Precision_traits<float>::compute_eps();
   Precision_traits<double>::compute_eps();
 
-  covsol_cases<float>();
-  covsol_cases<double>();
-  covsol_cases<complex<float> >();
-  covsol_cases<complex<double> >();
-
-  lsqsol_cases<float>();
-  lsqsol_cases<double>();
-  lsqsol_cases<complex<float> >();
-  lsqsol_cases<complex<double> >();
-
-  rsol_cases<float>();
-  rsol_cases<double>();
-  rsol_cases<complex<float> >();
-  rsol_cases<complex<double> >();
+  storage_type st[3];
+  st[0] = qrd_nosaveq;
+  st[1] = qrd_saveq1;
+  st[2] = qrd_saveq;
+
+  for (int i=0; i<3; ++i)
+  {
+    covsol_cases<float>(st[i]);
+    covsol_cases<double>(st[i]);
+    covsol_cases<complex<float> >(st[i]);
+    covsol_cases<complex<double> >(st[i]);
+  }
+
+  for (int i=0; i<3; ++i)
+  {
+    lsqsol_cases<float>(st[i]);
+    lsqsol_cases<double>(st[i]);
+    lsqsol_cases<complex<float> >(st[i]);
+    lsqsol_cases<complex<double> >(st[i]);
+  }
+
+  for (int i=0; i<3; ++i)
+  {
+    rsol_cases<float>(st[i]);
+    rsol_cases<double>(st[i]);
+    rsol_cases<complex<float> >(st[i]);
+    rsol_cases<complex<double> >(st[i]);
+  }
 
   f_covsol_cases<by_reference, float>();
   f_covsol_cases<by_reference, double>();
@@ -1067,8 +1285,12 @@
   f_lsqsol_cases<by_value, complex<double> >();
 
   // Distributed tests
-  test_covsol_random<float, Map<> >(5, 5, 2);
-  test_lsqsol_random<float, Map<> >(5, 5, 2);
-  test_rsol_diag<float, Map<> >( 5,   5, 2);
-  test_f_lsqsol_random<by_reference, float, Map<> >(5,   5, 2);
+  test_covsol_random<float, Map<> >(5, 5, 2, qrd_saveq1);
+  test_lsqsol_random<float, Map<> >(5, 5, 2, qrd_saveq1);
+  test_rsol_diag<float, Map<> >( 5,   5, 2, qrd_saveq1);
+
+  // f_lsqsol requires full QR, which isn't supported when using SAL (060507).
+  if (!vsip::impl::Type_equal<vsip::impl::Choose_qrd_impl<float>::type,
+                              vsip::impl::Mercury_sal_tag>::value)
+    test_f_lsqsol_random<by_reference, float, Map<> >(5,   5, 2);
 }
