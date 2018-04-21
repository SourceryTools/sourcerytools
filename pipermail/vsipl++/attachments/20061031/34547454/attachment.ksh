Index: src/vsip/core/cvsip/solver_qr.hpp
===================================================================
--- src/vsip/core/cvsip/solver_qr.hpp	(revision 0)
+++ src/vsip/core/cvsip/solver_qr.hpp	(revision 0)
@@ -0,0 +1,417 @@
+/* Copyright (c) 2006 by CodeSourcery inc.  All rights reserved. */
+
+/** @file    vsip/core/cvsip/solver_qr.hpp
+    @author  Assem Salama
+    @date    2006-10-26
+    @brief   VSIPL++ Library: QR linear system solver using CVSIP.
+
+*/
+
+#ifndef VSIP_CORE_CVSIP_SOLVER_QR_HPP
+#define VSIP_CORE_CVSIP_SOLVER_QR_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <algorithm>
+
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/core/math_enum.hpp>
+#include <vsip/core/temp_buffer.hpp>
+#include <vsip/core/working_view.hpp>
+#include <vsip/core/fns_elementwise.hpp>
+#include <vsip/core/solver/common.hpp>
+
+#include <vsip/core/cvsip/cvsip_matrix.hpp>
+#include <vsip/core/cvsip/cvsip_qr.hpp>
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
+/// Qrd implementation using CVSIP
+
+/// Requires:
+///   T to be a value type supported by SAL's QR routines
+
+template <typename T,
+	  bool     Blocked>
+class Qrd_impl<T, Blocked, Cvsip_tag>
+{
+  typedef vsip::impl::dense_complex_type   complex_type;
+  typedef Layout<2, col2_type, Stride_unit_dense, complex_type> data_LP;
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
+  Matrix<T, data_block_type> data_;	// Factorized QR(mxn) matrix
+  cvsip::Cvsip_matrix<T>     cvsip_data_;
+  cvsip::Cvsip_qr<T>         cvsip_qr_;
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
+Qrd_impl<T, Blocked, Cvsip_tag>::Qrd_impl(
+  length_type  rows,
+  length_type  cols,
+  storage_type st
+  )
+VSIP_THROW((std::bad_alloc))
+  : m_          (rows),
+    n_          (cols),
+    st_         (st),
+    data_       (m_, n_),
+    cvsip_qr_   (m_, n_, get_vsip_st(st_)),
+    cvsip_data_ (data_.block().impl_data(), m_, n_, col2_type())
+{
+  assert(m_ > 0 && n_ > 0 && m_ >= n_);
+  assert(st_ == qrd_nosaveq || st_ == qrd_saveq || st_ == qrd_saveq1);
+
+}
+
+
+
+template <typename T,
+	  bool     Blocked>
+Qrd_impl<T, Blocked, Cvsip_tag>::Qrd_impl(Qrd_impl const& qr)
+VSIP_THROW((std::bad_alloc))
+  : m_          (qr.m_),
+    n_          (qr.n_),
+    st_         (qr.st_),
+    data_       (m_, n_),
+    cvsip_qr_   (m_, n_, get_vsip_st(st_)),
+    cvsip_data_ (data_.block().impl_data(), m_, n_, col2_type())
+{
+  data_ = qr.data_;
+}
+
+
+
+template <typename T,
+	  bool     Blocked>
+Qrd_impl<T, Blocked, Cvsip_tag>::~Qrd_impl()
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
+Qrd_impl<T, Blocked, Cvsip_tag>::decompose(Matrix<T, Block> m)
+  VSIP_NOTHROW
+{
+  assert(m.size(0) == m_ && m.size(1) == n_);
+
+  cvsip_data_.release(false);
+  assign_local(data_, m);
+  cvsip_data_.admit(true);
+
+
+  cvsip_qr_.decompose(cvsip_data_);
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
+Qrd_impl<T, Blocked, Cvsip_tag>::impl_prodq(
+  const_Matrix<T, Block0> b,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  typedef typename Block_layout<Block0>::order_type order_type;
+  typedef typename Block_layout<Block0>::complex_type complex_type;
+  typedef Layout<2, order_type, Stride_unit_dense, complex_type> data_LP;
+  typedef Fast_block<2, T, data_LP, Local_map> block_type;
+
+  assert(this->qstorage() == qrd_saveq1 || this->qstorage() == qrd_saveq);
+  length_type q_rows;
+  length_type q_cols;
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
+    std::swap(q_rows, q_cols);
+  }
+  if(tr == mat_herm) 
+  {
+    std::swap(q_rows, q_cols);
+  }
+
+  // left or right?
+  if(ps == mat_lside) 
+  {
+    assert(b.size(0) == q_cols);
+    assert(x.size(0) == q_rows);
+    assert(b.size(1) == x.size(1));
+  }
+  else
+  {
+    assert(b.size(1) == q_rows);
+    assert(x.size(1) == q_cols);
+    assert(b.size(0) == x.size(0));
+  }
+
+
+  vsip_mat_side s  = get_vsip_side(ps);
+  vsip_mat_op   op = get_vsip_mat_op(tr);
+
+  Matrix<T,block_type> b_int(b.size(0), b.size(1));
+  Ext_data<block_type> b_ext(b_int.block());
+  cvsip::Cvsip_matrix<T>
+      cvsip_b_int(b_ext.data(),b_ext.size(0),b_ext.size(1),
+		               b_ext.stride(0),b_ext.stride(1));
+
+
+  cvsip_b_int.release(false);
+  assign_local(b_int, b);
+  cvsip_b_int.admit(true);
+  int ret = cvsip_qr_.qrdprodq(s,op,cvsip_b_int);
+
+  // now, copy into x
+  cvsip_b_int.release(true);
+  assign_local(x, b_int);
+
+  
+
+  return ret;
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
+Qrd_impl<T, Blocked, Cvsip_tag>::impl_rsol(
+  const_Matrix<T, Block0> b,
+  T const                 alpha,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  typedef typename Block_layout<Block0>::order_type order_type;
+  typedef typename Block_layout<Block0>::complex_type complex_type;
+  typedef Layout<2, order_type, Stride_unit_dense, complex_type> data_LP;
+  typedef Fast_block<2, T, data_LP, Local_map> block_type;
+
+  assert(b.size(0) == n_);
+  assert(b.size(0) == x.size(0));
+  assert(b.size(1) == x.size(1));
+
+  Matrix<T, block_type> b_int(b.size(0), b.size(1));
+  Ext_data<block_type>  b_ext(b_int.block());
+  cvsip::Cvsip_matrix<T>
+      cvsip_b_int(b_ext.data(),b_ext.size(0),b_ext.size(1),
+		               b_ext.stride(0),b_ext.stride(1));
+
+  cvsip_b_int.release(false);
+  assign_local(b_int, b);
+  cvsip_b_int.admit(true);
+
+  cvsip_qr_.solr(get_vsip_mat_op(tr), alpha, cvsip_b_int);
+
+  // copy b_int back into x
+  cvsip_b_int.release(true);
+  assign_local(x, b_int);
+
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
+Qrd_impl<T, Blocked, Cvsip_tag>::
+impl_covsol(const_Matrix<T, Block0> b, Matrix<T, Block1> x)
+  VSIP_NOTHROW
+{
+  typedef typename Block_layout<Block0>::order_type order_type;
+  typedef typename Block_layout<Block0>::complex_type complex_type;
+  typedef Layout<2, order_type, Stride_unit_dense, complex_type> data_LP;
+  typedef Fast_block<2, T, data_LP, Local_map> block_type;
+
+  Matrix<T, block_type> b_int(b.size(0), b.size(1));
+  Ext_data<block_type>  b_ext(b_int.block());
+  cvsip::Cvsip_matrix<T>
+    cvsip_b_int(b_ext.data(),b_ext.size(0),b_ext.size(1),
+		               b_ext.stride(0),b_ext.stride(1));
+
+  cvsip_b_int.release(false);
+  assign_local(b_int, b);
+  cvsip_b_int.admit(true);
+
+  cvsip_qr_.rsol(b_int, VSIP_COV);
+
+  // copy b_int back into x
+  cvsip_b_int.release(true);
+  assign_local(x, b_int);
+
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
+Qrd_impl<T, Blocked, Cvsip_tag>::
+impl_lsqsol(const_Matrix<T, Block0> b, Matrix<T, Block1> x)
+  VSIP_NOTHROW
+{
+  typedef typename Block_layout<Block0>::order_type order_type;
+  typedef typename Block_layout<Block0>::complex_type complex_type;
+  typedef Layout<2, order_type, Stride_unit_dense, complex_type> data_LP;
+  typedef Fast_block<2, T, data_LP, Local_map> block_type;
+
+  Matrix<T, block_type> b_int(b.size(0), b.size(1));
+  Ext_data<data_block_type> b_ext(b_int.block());
+  cvsip::Cvsip_matrix<T>
+    cvsip_b_int(b_ext.data(),b_ext.size(0),b_ext.size(1),
+		               b_ext.stride(0),b_ext.stride(1));
+
+  cvsip_b_int.release(false);
+  assign_local(b_int, b);
+  cvsip_b_int.admit(true);
+
+  cvsip_qr_.rsol(b_int, VSIP_LLS);
+  // copy b_int back into x
+  cvsip_b_int.release(true);
+  assign_local(x, b_int);
+
+  return true;
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_CORE_CVSIP_SOLVER_QR_HPP
Index: src/vsip/core/cvsip/cvsip.hpp
===================================================================
--- src/vsip/core/cvsip/cvsip.hpp	(revision 152477)
+++ src/vsip/core/cvsip/cvsip.hpp	(working copy)
@@ -183,18 +183,18 @@
   return VF(qr_obj,op,side,m); \
 }
 
-#define VSIP_IMPL_CVSIP_QRDRSOLR(QT, ST, VT, VF) \
-inline int qrdprod(QT *qr_obj, vsip_mat_op op, ST *s, \
+#define VSIP_IMPL_CVSIP_QRDSOLR(QT, ST, VT, VF) \
+inline int qrsolr(QT *qr_obj, vsip_mat_op op, ST s, \
 		vsip_mat_side side, VT *m) \
 { \
   return VF(qr_obj,op,s,m); \
 }
 
-#define VSIP_IMPL_CVSIP_CQRDRSOLR(QT, T, ST, VT, VF) \
-inline int qrdprod(QT *qr_obj, vsip_mat_op op, std::complex<T> *s, \
+#define VSIP_IMPL_CVSIP_CQRDSOLR(QT, T, ST, VT, VF) \
+inline int qrsolr(QT *qr_obj, vsip_mat_op op, std::complex<T> s, \
 		vsip_mat_side side, VT *m) \
 { \
-  return VF(qr_obj,op,(ST*)s,m); \
+  return VF(qr_obj,op,*(ST*)&s,m); \
 }
 /******************************************************************************
  * Function declarations
@@ -231,11 +231,11 @@
 VSIP_IMPL_CVSIP_QRSOL(vsip_cqr_f, vsip_cmview_f, vsip_cqrsol_f)
 VSIP_IMPL_CVSIP_QRD_DESTROY(vsip_qr_f, vsip_qrd_destroy_f)
 VSIP_IMPL_CVSIP_QRD_DESTROY(vsip_cqr_f, vsip_cqrd_destroy_f)
-VSIP_IMPL_CVSIP_QRDPROD(vsip_qr_f, vsip_mview_f, vsip_qrdprodq_f)
-VSIP_IMPL_CVSIP_QRDPROD(vsip_cqr_f, vsip_cmview_f, vsip_cqrdprodq_f)
-VSIP_IMPL_CVSIP_QRDRSOLR(vsip_qr_f,vsip_scalar_f,vsip_mview_f,vsip_qrdrsolr_f)
-VSIP_IMPL_CVSIP_CQRDRSOLR(vsip_cqr_f,float,vsip_cscalar_f,
-	vsip_cmview_f,vsip_cqrdrsolr_f)
+VSIP_IMPL_CVSIP_QRDPRODQ(vsip_qr_f, vsip_mview_f, vsip_qrdprodq_f)
+VSIP_IMPL_CVSIP_QRDPRODQ(vsip_cqr_f, vsip_cmview_f, vsip_cqrdprodq_f)
+VSIP_IMPL_CVSIP_QRDSOLR(vsip_qr_f,vsip_scalar_f,vsip_mview_f,vsip_qrdsolr_f)
+VSIP_IMPL_CVSIP_CQRDSOLR(vsip_cqr_f,float,vsip_cscalar_f,
+	vsip_cmview_f,vsip_cqrdsolr_f)
 #endif
 
 #ifdef VSIP_IMPL_CVSIP_HAVE_DOUBLE
@@ -269,13 +269,29 @@
 VSIP_IMPL_CVSIP_QRSOL(vsip_cqr_d, vsip_cmview_d, vsip_cqrsol_d)
 VSIP_IMPL_CVSIP_QRD_DESTROY(vsip_qr_d, vsip_qrd_destroy_d)
 VSIP_IMPL_CVSIP_QRD_DESTROY(vsip_cqr_d, vsip_cqrd_destroy_d)
-VSIP_IMPL_CVSIP_QRDPROD(vsip_qr_d, vsip_mview_d, vsip_qrdprodq_d)
-VSIP_IMPL_CVSIP_QRDPROD(vsip_cqr_d, vsip_cmview_d, vsip_cqrdprodq_d)
-VSIP_IMPL_CVSIP_QRDRSOLR(vsip_qr_d,vsip_scalar_d,vsip_mview_d,vsip_qrdrsolr_d)
-VSIP_IMPL_CVSIP_CQRDRSOLR(vsip_cqr_d,double,vsip_cscalar_d,
-	vsip_cmview_d,vsip_cqrdrsolr_d)
+VSIP_IMPL_CVSIP_QRDPRODQ(vsip_qr_d, vsip_mview_d, vsip_qrdprodq_d)
+VSIP_IMPL_CVSIP_QRDPRODQ(vsip_cqr_d, vsip_cmview_d, vsip_cqrdprodq_d)
+VSIP_IMPL_CVSIP_QRDSOLR(vsip_qr_d,vsip_scalar_d,vsip_mview_d,vsip_qrdsolr_d)
+VSIP_IMPL_CVSIP_CQRDSOLR(vsip_cqr_d,double,vsip_cscalar_d,
+	vsip_cmview_d,vsip_cqrdsolr_d)
 #endif
 
+// some support defines
+#define get_vsip_st(st) \
+	( (st == qrd_nosaveq)?     VSIP_QRD_NOSAVEQ: \
+	  (st == qrd_saveq1)?      VSIP_QRD_SAVEQ1: \
+	                           VSIP_QRD_SAVEQ \
+        )
+
+#define get_vsip_side(s) \
+	( (s == mat_lside)?        VSIP_MAT_LSIDE:VSIP_MAT_RSIDE )
+
+#define get_vsip_mat_op(op) \
+	( (op == mat_ntrans)?      VSIP_MAT_NTRANS: \
+	  (op == mat_trans)?       VSIP_MAT_TRANS: \
+	                           VSIP_MAT_HERM \
+	)
+
 }  // namespace cvsip
 
 }  // namespace impl
Index: src/vsip/core/cvsip/cvsip_qr.hpp
===================================================================
--- src/vsip/core/cvsip/cvsip_qr.hpp	(revision 0)
+++ src/vsip/core/cvsip/cvsip_qr.hpp	(revision 0)
@@ -0,0 +1,85 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/cvsip/cvsip_qr.hpp
+    @author  Assem Salama
+    @date    2006-10-25
+    @brief   VSIPL++ Library: CVSIP wrapper for QR object
+
+*/
+
+#ifndef VSIP_CORE_CVSIP_CVSIP_QR_HPP
+#define VSIP_CORE_CVSIP_CVSIP_QR_HPP
+
+#include <vsip/core/cvsip/cvsip.hpp>
+#include <vsip/core/cvsip/cvsip_matrix.hpp>
+
+namespace vsip
+{
+
+namespace impl
+{
+
+namespace cvsip
+{
+
+template <typename T>
+class Cvsip_qr;
+
+template <typename T>
+class Cvsip_qr : Non_copyable
+{
+  typedef typename Cvsip_traits<T>::qr_object_type     qr_object_type;
+
+  public:
+    Cvsip_qr<T>(int m, int n, vsip_qrd_qopt op);
+    ~Cvsip_qr<T>();
+
+    int decompose(Cvsip_matrix<T> &a);
+    int rsol(Cvsip_matrix<T> &xb, vsip_qrd_prob p);
+    int prodq(vsip_mat_op op, vsip_mat_side side, Cvsip_matrix<T> &m);
+    int solr(vsip_mat_op op, T alpha, Cvsip_matrix<T> &m);
+
+  private:
+    qr_object_type*      qr_;
+};
+
+template <typename T>
+Cvsip_qr<T>::Cvsip_qr(int m, int n, vsip_qrd_qopt op)
+{
+  qrd_create(m,n, op,&qr_);
+}
+
+template <typename T>
+Cvsip_qr<T>::~Cvsip_qr()
+{
+  qrd_destroy(qr_);
+}
+
+template <typename T>
+int Cvsip_qr<T>::decompose(Cvsip_matrix<T> &a)
+{
+  return !qrd(qr_, a.get_view());
+}
+
+template <typename T>
+int Cvsip_qr<T>::rsol(Cvsip_matrix<T> &xb, vsip_qrd_prob p)
+{
+  return qrsol(qr_, p, xb.get_view());
+}
+
+template <typename T>
+int Cvsip_qr<T>::prodq(vsip_mat_op op, vsip_mat_side side, Cvsip_matrix<T> &m)
+{
+  return qrdprodq(qr_, op, side, m.get_view());
+}
+
+template <typename T>
+int Cvsip_qr<T>::solr(vsip_mat_op op, T alpha, Cvsip_matrix<T> &m)
+{
+  return solr(qr_, op, alpha, m.get_view());
+}
+
+} // namespace cvsip
+} // namespace impl
+} // namespace vsip
+#endif // VSIP_CORE_CVSIP_CVSIP_QR_HPP
Index: src/vsip/core/solver/qr.hpp
===================================================================
--- src/vsip/core/solver/qr.hpp	(revision 151692)
+++ src/vsip/core/solver/qr.hpp	(working copy)
@@ -29,6 +29,9 @@
 #ifdef VSIP_IMPL_HAVE_SAL
 #  include <vsip/opt/sal/qr.hpp>
 #endif
+#ifdef VSIP_IMPL_HAVE_CVSIP
+#  include <vsip/core/cvsip/solver_qr.hpp>
+#endif
 
 
 
@@ -51,6 +54,9 @@
 #ifdef VSIP_IMPL_HAVE_LAPACK
   Lapack_tag,
 #endif
+#ifdef VSIP_IMPL_HAVE_CVSIP
+  Cvsip_tag,
+#endif
   None_type // None_type is treated specially by Make_type_list, it is
             // not be put into the list.  Putting an explicit None_type
             // at the end of the list lets us put a ',' after each impl
@@ -63,6 +69,10 @@
 template <typename T>
 struct Choose_qrd_impl
 {
+#ifdef VSIP_IMPL_REF_IMPL
+  typedef typename Cvsip_tag type;
+  typedef typename Cvsip_tag use_type;
+#else
   typedef typename Choose_solver_impl<
     Is_qrd_impl_avail,
     T,
@@ -72,6 +82,7 @@
     Type_equal<type, None_type>::value,
     As_type<Error_no_solver_for_this_type>,
     As_type<type> >::type use_type;
+#endif
 };
 
 } // namespace vsip::impl
