Index: cvsip/solver_lu.hpp
===================================================================
--- cvsip/solver_lu.hpp	(revision 0)
+++ cvsip/solver_lu.hpp	(revision 0)
@@ -0,0 +1,232 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/lapack/solver_lu.hpp
+    @author  Assem Salama
+    @date    2006-04-13
+    @brief   VSIPL++ Library: LU linear system solver using lapack.
+
+*/
+
+#ifndef VSIP_REF_IMPL_SOLVER_LU_HPP
+#define VSIP_REF_IMPL_SOLVER_LU_HPP
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
+#include <vsip/core/solver/common.hpp>
+
+#include <vsip/core/cvsip/cvsip_matrix.hpp>
+#include <vsip/core/cvsip/cvsip_lu.hpp>
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
+class Lud_impl<T, Cvsip_tag>
+  : Compile_time_assert<cvsip::Cvsip_traits<T>::valid>
+{
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
+  cvsip::Cvsip_matrix<T>     cvsip_data_;
+  cvsip::Cvsip_lud<T>        cvsip_lud_;
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
+Lud_impl<T, Cvsip_tag>::Lud_impl(
+  length_type length
+  )
+VSIP_THROW((std::bad_alloc))
+  : length_      (length),
+    ipiv_        (length_),
+    data_        (length_, length_),
+    cvsip_data_  (data_.block().impl_data(), length_, length_),
+    cvsip_lud_   (length_)
+{
+  assert(length_ > 0);
+}
+
+
+
+template <typename T>
+Lud_impl<T, Cvsip_tag>::Lud_impl(Lud_impl const& lu)
+VSIP_THROW((std::bad_alloc))
+  : length_      (lu.length_),
+    ipiv_        (length_),
+    data_        (length_, length_),
+    cvsip_data_  (data_.block().impl_data(), length_, length_),
+    cvsip_lud_   (length_)
+{
+  data_ = lu.data_;
+  for (index_type i=0; i<length_; ++i)
+    ipiv_[i] = lu.ipiv_[i];
+}
+
+
+
+template <typename T>
+Lud_impl<T, Cvsip_tag>::~Lud_impl()
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
+Lud_impl<T, Cvsip_tag>::decompose(Matrix<T, Block> m)
+  VSIP_NOTHROW
+{
+  assert(m.size(0) == length_ && m.size(1) == length_);
+
+  assign_local(data_, m);
+
+  bool success = cvsip_lud_.decompose(cvsip_data_);
+
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
+Lud_impl<T, Cvsip_tag>::impl_solve(
+  const_Matrix<T, Block0> b,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  typedef typename Block_layout<Block0>::order_type order_type;
+  typedef typename Block_layout<Block0>::complex_type complex_type;
+  typedef Layout<2, order_type, Stride_unit_dense, complex_type> data_LP;
+  typedef Fast_block<2, T, data_LP, Local_map> block_type;
+
+  assert(b.size(0) == length_);
+  assert(b.size(0) == x.size(0) && b.size(1) == x.size(1));
+
+  vsip_mat_op trans;
+
+  Matrix<T, block_type> b_int(b.size(0), b.size(1));
+  assign_local(b_int, b);
+
+  if (tr == mat_ntrans)
+    trans = VSIP_MAT_NTRANS;
+  else if (tr == mat_trans)
+    trans = VSIP_MAT_TRANS;
+  else if (tr == mat_herm)
+  {
+    assert(Is_complex<T>::value);
+    trans = VSIP_MAT_HERM;
+  }
+
+  {
+    Ext_data<block_type> b_ext(b_int.block());
+
+    cvsip::Cvsip_matrix<T>
+	      cvsip_b_int(b_ext.data(),b_ext.size(0),b_ext.size(1),
+			               b_ext.stride(0),b_ext.stride(1));
+
+    cvsip_lud_.solve(trans,cvsip_b_int);
+
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
Index: cvsip/cvsip.hpp
===================================================================
--- cvsip/cvsip.hpp	(revision 0)
+++ cvsip/cvsip.hpp	(revision 0)
@@ -0,0 +1,208 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/cvsip/cvsip.hpp
+    @author  Assem Salama
+    @date    2006-10-12
+    @brief   VSIPL++ Library: CVSIP support wrappers.
+
+*/
+
+#ifndef VSIP_CORE_CVSIP_CVSIPL_HPP
+#define VSIP_CORE_CVSIP_CVSIPL_HPP
+
+extern "C" {
+#include <vsip.h>
+}
+#include <complex>
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
+  template <typename T>
+  struct Cvsip_traits;
+
+  template<> struct Cvsip_traits<float>
+  {
+    typedef vsip_mview_f        mview_type;
+    typedef vsip_block_f        block_type;
+    typedef vsip_lu_f           lud_object_type;
+    static bool const valid = true;
+  };
+
+  template<> struct Cvsip_traits<double>
+  {
+    typedef vsip_mview_d        mview_type;
+    typedef vsip_block_d        block_type;
+    typedef vsip_lu_d           lud_object_type;
+    static bool const valid = true;
+  };
+
+  template<> struct Cvsip_traits<std::complex<float> >
+  {
+    typedef vsip_cmview_f        mview_type;
+    typedef vsip_cblock_f        block_type;
+    typedef vsip_clu_f           lud_object_type;
+    static bool const valid = true;
+  };
+
+  template<> struct Cvsip_traits<std::complex<double> >
+  {
+    typedef vsip_cmview_d        mview_type;
+    typedef vsip_cblock_d        block_type;
+    typedef vsip_clu_d           lud_object_type;
+    static bool const valid = true;
+  };
+
+
+#define CVSIPL_BLOCKBIND(BT, T, ST, VF) \
+inline BT *blockbind(T *data, vsip_length N, vsip_memory_hint hint) \
+{ \
+  return VF((ST*)data, N, hint); \
+}
+
+#define CVSIPL_CBLOCKBIND(BT, T, ST, VF) \
+inline BT *blockbind(complex<T> *data, \
+                    vsip_length N, vsip_memory_hint hint) \
+{ \
+  return VF((ST*)data, NULL, N, hint); \
+}
+
+#define CVSIPL_MBIND(VT, BT, VF) \
+inline VT *mbind(const BT *b, vsip_offset o, \
+  vsip_stride cs, vsip_length cl, vsip_stride rs, vsip_length rl) \
+{ \
+  return VF(b, o, cs, cl, rs, rl); \
+}
+
+#define CVSIPL_BLOCKCREATE(BT, VF) \
+inline void blockcreate(vsip_length N, vsip_memory_hint hint, BT **block) \
+{ \
+  *block = VF(N,hint); \
+}
+
+#define CVSIPL_BLOCKDESTROY(BT, VF) \
+inline void blockdestroy(BT *block) \
+{ \
+  VF(block); \
+}
+
+#define CVSIPL_BLOCKADMIT(BT, VF) \
+inline void blockadmit(BT *block, vsip_scalar_bl flag) \
+{ \
+  VF(block,flag); \
+}
+
+#define CVSIPL_BLOCKRELEASE(BT, VF) \
+inline void blockrelease(BT *block, vsip_scalar_bl flag) \
+{ \
+  VF(block,flag); \
+}
+
+#define CVSIPL_CBLOCKRELEASE(BT, VF, ST) \
+inline void blockrelease(BT *block, vsip_scalar_bl flag) \
+{ \
+  ST *a1,*a2; \
+  VF(block,flag,&a1,&a2); \
+}
+
+#define CVSIPL_MDESTROY(VT, VF) \
+inline void mdestroy(VT *view) \
+{ \
+  VF(view); \
+}
+
+#define CVSIPL_LUD_CREATE(LT, VF) \
+inline void lud_create(vsip_length N, LT **lu_obj) \
+{ \
+  *lu_obj = VF(N); \
+}
+
+#define CVSIPL_LUD_DESTROY(LT, VF) \
+inline void lud_destroy(LT *lu_obj) \
+{ \
+  VF(lu_obj); \
+}
+
+#define CVSIPL_LUD(LT, VT, VF) \
+inline int lud(LT *lu_obj, VT *view) \
+{ \
+  return VF(lu_obj, view); \
+}
+
+#define CVSIPL_LUSOL(LT, VT, VF) \
+inline int lusol(LT *lu_obj, vsip_mat_op op, VT *view) \
+{ \
+  return VF(lu_obj, op, view); \
+}
+/******************************************************************************
+ * Function declarations
+******************************************************************************/
+
+CVSIPL_BLOCKBIND(vsip_block_f,  float, vsip_scalar_f,  vsip_blockbind_f)
+CVSIPL_BLOCKBIND(vsip_block_d,  double, vsip_scalar_d,  vsip_blockbind_d)
+CVSIPL_CBLOCKBIND(vsip_cblock_f, float,  vsip_scalar_f,vsip_cblockbind_f)
+CVSIPL_CBLOCKBIND(vsip_cblock_d, double, vsip_scalar_d,vsip_cblockbind_d)
+
+CVSIPL_MBIND(vsip_mview_f,  vsip_block_f,  vsip_mbind_f)
+CVSIPL_MBIND(vsip_mview_d,  vsip_block_d,  vsip_mbind_d)
+CVSIPL_MBIND(vsip_cmview_f, vsip_cblock_f, vsip_cmbind_f)
+CVSIPL_MBIND(vsip_cmview_d, vsip_cblock_d, vsip_cmbind_d)
+
+CVSIPL_BLOCKCREATE(vsip_block_f,  vsip_blockcreate_f)
+CVSIPL_BLOCKCREATE(vsip_block_d,  vsip_blockcreate_d)
+CVSIPL_BLOCKCREATE(vsip_cblock_f, vsip_cblockcreate_f)
+CVSIPL_BLOCKCREATE(vsip_cblock_d, vsip_cblockcreate_d)
+
+CVSIPL_BLOCKDESTROY(vsip_block_f,  vsip_blockdestroy_f)
+CVSIPL_BLOCKDESTROY(vsip_block_d,  vsip_blockdestroy_d)
+CVSIPL_BLOCKDESTROY(vsip_cblock_f, vsip_cblockdestroy_f)
+CVSIPL_BLOCKDESTROY(vsip_cblock_d, vsip_cblockdestroy_d)
+
+CVSIPL_BLOCKADMIT(vsip_block_f,  vsip_blockadmit_f)
+CVSIPL_BLOCKADMIT(vsip_block_d,  vsip_blockadmit_d)
+CVSIPL_BLOCKADMIT(vsip_cblock_f, vsip_cblockadmit_f)
+CVSIPL_BLOCKADMIT(vsip_cblock_d, vsip_cblockadmit_d)
+
+CVSIPL_BLOCKRELEASE(vsip_block_f,  vsip_blockrelease_f)
+CVSIPL_BLOCKRELEASE(vsip_block_d,  vsip_blockrelease_d)
+CVSIPL_CBLOCKRELEASE(vsip_cblock_f, vsip_cblockrelease_f,vsip_scalar_f)
+CVSIPL_CBLOCKRELEASE(vsip_cblock_d, vsip_cblockrelease_d,vsip_scalar_d)
+
+CVSIPL_MDESTROY(vsip_mview_f,  vsip_mdestroy_f)
+CVSIPL_MDESTROY(vsip_mview_d,  vsip_mdestroy_d)
+CVSIPL_MDESTROY(vsip_cmview_f, vsip_cmdestroy_f)
+CVSIPL_MDESTROY(vsip_cmview_d, vsip_cmdestroy_d)
+
+CVSIPL_LUD_CREATE(vsip_lu_f,  vsip_lud_create_f)
+CVSIPL_LUD_CREATE(vsip_lu_d,  vsip_lud_create_d)
+CVSIPL_LUD_CREATE(vsip_clu_f, vsip_clud_create_f)
+CVSIPL_LUD_CREATE(vsip_clu_d, vsip_clud_create_d)
+
+CVSIPL_LUD_DESTROY(vsip_lu_f,  vsip_lud_destroy_f)
+CVSIPL_LUD_DESTROY(vsip_lu_d,  vsip_lud_destroy_d)
+CVSIPL_LUD_DESTROY(vsip_clu_f, vsip_clud_destroy_f)
+CVSIPL_LUD_DESTROY(vsip_clu_d, vsip_clud_destroy_d)
+
+CVSIPL_LUD(vsip_lu_f,  vsip_mview_f,  vsip_lud_f)
+CVSIPL_LUD(vsip_lu_d,  vsip_mview_d,  vsip_lud_d)
+CVSIPL_LUD(vsip_clu_f, vsip_cmview_f, vsip_clud_f)
+CVSIPL_LUD(vsip_clu_d, vsip_cmview_d, vsip_clud_d)
+
+CVSIPL_LUSOL(vsip_lu_f,  vsip_mview_f,  vsip_lusol_f)
+CVSIPL_LUSOL(vsip_lu_d,  vsip_mview_d,  vsip_lusol_d)
+CVSIPL_LUSOL(vsip_clu_f, vsip_cmview_f, vsip_clusol_f)
+CVSIPL_LUSOL(vsip_clu_d, vsip_cmview_d, vsip_clusol_d)
+
+}  // namespace cvsip
+
+}  // namespace impl
+
+}  // namespace vsip
+
+#endif // VSIP_CORE_CVSIP_CVSIPL_HPP
Index: cvsip/cvsip_lu.hpp
===================================================================
--- cvsip/cvsip_lu.hpp	(revision 0)
+++ cvsip/cvsip_lu.hpp	(revision 0)
@@ -0,0 +1,81 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/cvsip/cvsip_lu.hpp
+    @author  Assem Salama
+    @date    2006-10-12
+    @brief   VSIPL++ Library: CVSIP wrapper for LU object
+
+*/
+
+#ifndef VSIP_CORE_CVSIP_CVSIP_LU_HPP
+#define VSIP_CORE_CVSIP_CVSIP_LU_HPP
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
+class Cvsip_lud;
+
+template <typename T>
+class Cvsip_lud : Non_copyable
+{
+  typedef typename Cvsip_traits<T>::lud_object_type     lud_object_type;
+
+  public:
+    Cvsip_lud(int n);
+    ~Cvsip_lud();
+
+    int decompose(Cvsip_matrix<T> &a);
+    int solve(vsip_mat_op op, Cvsip_matrix<T> &xb);
+
+  private:
+    lud_object_type       *lu_;
+};
+
+template <typename T>
+Cvsip_lud<T>::Cvsip_lud(int n)
+{
+  lud_create(n, &lu_);
+}
+
+template <typename T>
+Cvsip_lud<T>::~Cvsip_lud()
+{
+  lud_destroy(lu_);
+}
+
+template <typename T>
+int Cvsip_lud<T>::decompose(Cvsip_matrix<T> &a)
+{
+  a.admit(true);
+  int ret = lud(lu_, a.get_view());
+  a.release(true);
+  return ret;
+}
+
+template <typename T>
+int Cvsip_lud<T>::solve(vsip_mat_op op, Cvsip_matrix<T> &xb)
+{
+  xb.admit(true);
+  int ret = lusol(lu_, op, xb.get_view());
+  xb.release(true);
+  return ret;
+}
+
+
+} // namespace cvsip
+
+} // namespace impl
+
+} // namespace vsip
+
+#endif // VSIP_CORE_CVSIP_CVSIP_LU_HPP
Index: cvsip/cvsip_matrix.hpp
===================================================================
--- cvsip/cvsip_matrix.hpp	(revision 0)
+++ cvsip/cvsip_matrix.hpp	(revision 0)
@@ -0,0 +1,115 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/cvsip/cvsip_matrix.hpp
+    @author  Assem Salama
+    @date    2006-10-12
+    @brief   VSIPL++ Library: CVSIP wrapper for Matrix views.
+
+*/
+
+#ifndef VSIP_CORE_CVSIP_CVSIP_MATRIX_HPP
+#define VSIP_CORE_CVSIP_CVSIP_MATRIX_HPP
+
+#include <vsip/core/cvsip/cvsip.hpp>
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
+class Cvsip_matrix;
+
+template <typename T>
+class Cvsip_matrix : Non_copyable
+{
+  typedef typename Cvsip_traits<T>::mview_type       mview_type;
+  typedef typename Cvsip_traits<T>::block_type       block_type;
+
+  public:
+    Cvsip_matrix<T>(T *block, int m, int n, int s1, int s2);
+    Cvsip_matrix<T>(int m, int n, int s1, int s2);
+    Cvsip_matrix<T>(T *block, int m, int n);
+    Cvsip_matrix<T>(int m, int n);
+    ~Cvsip_matrix<T>();
+
+    mview_type *get_view() { return mview_; }
+    void admit(bool flag) { blockadmit(mblock_, flag); }
+    void release(bool flag) { blockrelease(mblock_, flag); }
+    
+  private:
+    mview_type         *mview_;
+    block_type         *mblock_;
+    bool               local_data_;
+    
+    
+};
+
+template <typename T>
+Cvsip_matrix<T>::Cvsip_matrix(T *block, int m, int n, int s1, int s2)
+{
+  // block is allocated, just bind to it.
+  mblock_ = blockbind(block, m*n, VSIP_MEM_NONE);
+
+  // block must be dense
+  mview_ = mbind(mblock_, 0, s1, n, s2, m);
+
+  local_data_ = false;
+}
+
+template <typename T>
+Cvsip_matrix<T>::Cvsip_matrix(int m, int n, int s1, int s2)
+{
+  // create block
+  blockcreate(m*n, VSIP_MEM_NONE, &mblock_);
+
+  // block must be dense
+  mview_ = mbind(mblock_, 0, s1, n, s2, m);
+
+  local_data_ = true;
+}
+
+template <typename T>
+Cvsip_matrix<T>::Cvsip_matrix(T *block, int m, int n)
+{
+  // block is allocated, just bind to it.
+  mblock_ = blockbind(block, m*n, VSIP_MEM_NONE);
+
+  // block must be dense
+  mview_ = mbind(mblock_, 0, 1, n, n, m);
+
+  local_data_ = false;
+}
+
+template <typename T>
+Cvsip_matrix<T>::Cvsip_matrix(int m, int n)
+{
+  // create block
+  blockcreate(m*n, VSIP_MEM_NONE, &mblock_);
+
+  // block must be dense
+  mview_ = mbind(mblock_, 0, 1, n, n, m);
+
+  local_data_ = true;
+}
+
+template <typename T>
+Cvsip_matrix<T>::~Cvsip_matrix()
+{
+  // destroy everything!
+  if(local_data_) blockdestroy(mblock_);
+
+  mdestroy(mview_);
+}
+
+} // namespace cvsip
+
+} // namespace impl
+
+} // namespace vsip
+
+#endif // VSIP_CORE_CVSIP_CVSIP_MATRIX_HPP
Index: solver/lu.hpp
===================================================================
--- solver/lu.hpp	(revision 151692)
+++ solver/lu.hpp	(working copy)
@@ -28,6 +28,12 @@
 #ifdef VSIP_IMPL_HAVE_LAPACK
 #  include <vsip/opt/lapack/lu.hpp>
 #endif
+#ifdef VSIP_IMPL_HAVE_LAPACK
+#  include <vsip/opt/lapack/lu.hpp>
+#endif
+#ifdef VSIP_IMPL_HAVE_CVSIP
+#  include <vsip/core/cvsip/solver_lu.hpp>
+#endif
 
 
 
@@ -62,6 +68,10 @@
 template <typename T>
 struct Choose_lud_impl
 {
+#ifdef VSIP_IMPL_HAVE_CVSIP
+  typedef Cvsip_tag use_type;
+  typedef Cvsip_tag type;
+#else
   typedef typename Choose_solver_impl<
     Is_lud_impl_avail,
     T,
@@ -71,6 +81,7 @@
     Type_equal<type, None_type>::value,
     As_type<Error_no_solver_for_this_type>,
     As_type<type> >::type use_type;
+#endif
 };
 
 } // namespace impl
Index: solver/common.hpp
===================================================================
--- solver/common.hpp	(revision 151692)
+++ solver/common.hpp	(working copy)
@@ -71,6 +71,7 @@
 
 // Implementation tags
 struct Lapack_tag;
+struct Cvsip_tag;
 
 // Error tags
 struct Error_no_solver_for_this_type;
