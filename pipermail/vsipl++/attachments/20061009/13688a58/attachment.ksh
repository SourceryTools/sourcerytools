Index: ref_impl/vsipl/solver_lu.hpp
===================================================================
--- ref_impl/vsipl/solver_lu.hpp	(revision 0)
+++ ref_impl/vsipl/solver_lu.hpp	(revision 0)
@@ -0,0 +1,230 @@
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
+#include <vsip/impl/math-enum.hpp>
+#include <vsip/impl/lapack.hpp>
+#include <vsip/impl/temp_buffer.hpp>
+#include <vsip/impl/solver_common.hpp>
+
+#include <vsip/ref_impl/vsipl/cvsipl_matrix.hpp>
+#include <vsip/ref_impl/vsipl/cvsipl_lu.hpp>
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
+class Lud_impl<T, Ref_impl_tag>
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
+  vsip::ref_impl::cvsipl::CVSIPL_Matrix<T>           cvsipl_data_;
+  vsip::ref_impl::cvsipl::CVSIPL_Lud<T>              cvsipl_lud_;
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
+Lud_impl<T, Ref_impl_tag>::Lud_impl(
+  length_type length
+  )
+VSIP_THROW((std::bad_alloc))
+  : length_      (length),
+    ipiv_        (length_),
+    data_        (length_, length_),
+    cvsipl_data_ (data_.block().impl_data(), length_, length_),
+    cvsipl_lud_  (length_)
+{
+  assert(length_ > 0);
+}
+
+
+
+template <typename T>
+Lud_impl<T, Ref_impl_tag>::Lud_impl(Lud_impl const& lu)
+VSIP_THROW((std::bad_alloc))
+  : length_      (lu.length_),
+    ipiv_        (length_),
+    data_        (length_, length_),
+    cvsipl_data_ (data_.block().impl_data(), length_, length_),
+    cvsipl_lud_  (length_)
+{
+  data_ = lu.data_;
+  for (index_type i=0; i<length_; ++i)
+    ipiv_[i] = lu.ipiv_[i];
+}
+
+
+
+template <typename T>
+Lud_impl<T, Ref_impl_tag>::~Lud_impl()
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
+Lud_impl<T, Ref_impl_tag>::decompose(Matrix<T, Block> m)
+  VSIP_NOTHROW
+{
+  assert(m.size(0) == length_ && m.size(1) == length_);
+
+  assign_local(data_, m);
+
+  Ext_data<data_block_type> ext(data_.block());
+
+  bool success = cvsipl_lud_.decompose(cvsipl_data_);
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
+Lud_impl<T, Ref_impl_tag>::impl_solve(
+  const_Matrix<T, Block0> b,
+  Matrix<T, Block1>       x)
+  VSIP_NOTHROW
+{
+  assert(b.size(0) == length_);
+  assert(b.size(0) == x.size(0) && b.size(1) == x.size(1));
+
+  vsip_mat_op trans;
+
+  Matrix<T, data_block_type> b_int(b.size(0), b.size(1));
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
+    Ext_data<data_block_type> b_ext(b_int.block());
+
+    vsip::ref_impl::cvsipl::CVSIPL_Matrix<T>
+	      cvsipl_b_int(b_ext.data(), b.size(0),b.size(1));
+
+    cvsipl_lud_.solve(trans,cvsipl_b_int);
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
Index: ref_impl/vsipl/cvsipl_support.hpp
===================================================================
--- ref_impl/vsipl/cvsipl_support.hpp	(revision 0)
+++ ref_impl/vsipl/cvsipl_support.hpp	(revision 0)
@@ -0,0 +1,195 @@
+#ifndef CVSIPL_SUPPORT_HPP
+#define CVSIPL_SUPPORT_HPP
+
+extern "C" {
+#include <vsip.h>
+}
+#include <complex>
+
+namespace vsip
+{
+
+namespace ref_impl
+{
+
+namespace cvsipl
+{
+
+  template <typename T>
+  struct CVSIPL_mview;
+
+  template<> struct CVSIPL_mview<float>      { typedef vsip_mview_f  type; };
+  template<> struct CVSIPL_mview<double>     { typedef vsip_mview_d  type; };
+  template<> struct CVSIPL_mview<std::complex<float> >
+    { typedef vsip_cmview_f type; };
+  template<> struct CVSIPL_mview<std::complex<double> >
+    { typedef vsip_cmview_d type; };
+
+  template <typename T>
+  struct CVSIPL_block;
+
+  template<> struct CVSIPL_block<float>      { typedef vsip_block_f  type; };
+  template<> struct CVSIPL_block<double>     { typedef vsip_block_d  type; };
+  template<> struct CVSIPL_block<std::complex<float> >
+    { typedef vsip_cblock_f type; };
+  template<> struct CVSIPL_block<std::complex<double> >
+    { typedef vsip_cblock_d type; };
+
+
+  template <typename T>
+  struct CVSIPL_Lud_object;
+
+  template <> struct CVSIPL_Lud_object<float>  { typedef vsip_lu_f type; };
+  template <> struct CVSIPL_Lud_object<double> { typedef vsip_lu_d type; };
+  template <> struct CVSIPL_Lud_object<std::complex<float> >
+    { typedef vsip_clu_f type; };
+  template <> struct CVSIPL_Lud_object<std::complex<double> >
+    { typedef vsip_clu_d type; };
+
+
+#define CVSIPL_BLOCKBIND(BT, T, ST, VF) \
+inline BT *vsip_blockbind(T *data, vsip_length N, vsip_memory_hint hint) \
+{ \
+  return VF((ST*)data, N, hint); \
+}
+
+#define CVSIPL_CBLOCKBIND(BT, T, ST, VF) \
+inline BT *vsip_blockbind(complex<T> *data, \
+                    vsip_length N, vsip_memory_hint hint) \
+{ \
+  return VF((ST*)data, NULL, N, hint); \
+}
+
+#define CVSIPL_MBIND(VT, BT, VF) \
+inline VT *vsip_mbind(const BT *b, vsip_offset o, \
+  vsip_stride cs, vsip_length cl, vsip_stride rs, vsip_length rl) \
+{ \
+  return VF(b, o, cs, cl, rs, rl); \
+}
+
+#define CVSIPL_BLOCKCREATE(BT, VF) \
+inline void vsip_blockcreate(vsip_length N, vsip_memory_hint hint, BT **block) \
+{ \
+  *block = VF(N,hint); \
+}
+
+#define CVSIPL_BLOCKDESTROY(BT, VF) \
+inline void vsip_blockdestroy(BT *block) \
+{ \
+  VF(block); \
+}
+
+#define CVSIPL_BLOCKADMIT(BT, VF) \
+inline void vsip_blockadmit(BT *block, vsip_scalar_bl flag) \
+{ \
+  VF(block,flag); \
+}
+
+#define CVSIPL_BLOCKRELEASE(BT, VF) \
+inline void vsip_blockrelease(BT *block, vsip_scalar_bl flag) \
+{ \
+  VF(block,flag); \
+}
+
+#define CVSIPL_CBLOCKRELEASE(BT, VF, ST) \
+inline void vsip_blockrelease(BT *block, vsip_scalar_bl flag) \
+{ \
+  ST *a1,*a2; \
+  VF(block,flag,&a1,&a2); \
+}
+
+#define CVSIPL_MDESTROY(VT, VF) \
+inline void vsip_mdestroy(VT *view) \
+{ \
+  VF(view); \
+}
+
+#define CVSIPL_LUD_CREATE(LT, VF) \
+inline void vsip_lud_create(vsip_length N, LT **lu_obj) \
+{ \
+  *lu_obj = VF(N); \
+}
+
+#define CVSIPL_LUD_DESTROY(LT, VF) \
+inline void vsip_lud_destroy(LT *lu_obj) \
+{ \
+  VF(lu_obj); \
+}
+
+#define CVSIPL_LUD(LT, VT, VF) \
+inline int vsip_lud(LT *lu_obj, VT *view) \
+{ \
+  return VF(lu_obj, view); \
+}
+
+#define CVSIPL_LUSOL(LT, VT, VF) \
+inline int vsip_lusol(LT *lu_obj, vsip_mat_op op, VT *view) \
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
+}  // namespace cvsipl
+
+}  // namespace ref_impl
+
+}  // namespace vsip
+
+#endif // CVSIPL_SUPPORT_HPP
Index: ref_impl/vsipl/cvsipl_lu.hpp
===================================================================
--- ref_impl/vsipl/cvsipl_lu.hpp	(revision 0)
+++ ref_impl/vsipl/cvsipl_lu.hpp	(revision 0)
@@ -0,0 +1,72 @@
+#ifndef CVSIPL_LU_HPP
+#define CVSIPL_LU_HPP
+
+#include <vsip/ref_impl/vsipl/cvsipl_support.hpp>
+#include <vsip/ref_impl/vsipl/cvsipl_matrix.hpp>
+
+namespace vsip
+{
+
+namespace ref_impl
+{
+
+namespace cvsipl
+{
+
+template <typename T>
+class CVSIPL_Lud;
+
+template <typename T>
+class CVSIPL_Lud
+{
+  typedef typename CVSIPL_Lud_object<T>::type     lud_object_type;
+
+  public:
+    CVSIPL_Lud(int n);
+    ~CVSIPL_Lud();
+
+    int decompose(CVSIPL_Matrix<T> &a);
+    int solve(vsip_mat_op op, CVSIPL_Matrix<T> &xb);
+
+  private:
+    lud_object_type       *lu_;
+};
+
+template <typename T>
+CVSIPL_Lud<T>::CVSIPL_Lud(int n)
+{
+  vsip_lud_create(n, &lu_);
+}
+
+template <typename T>
+CVSIPL_Lud<T>::~CVSIPL_Lud()
+{
+  vsip_lud_destroy(lu_);
+}
+
+template <typename T>
+int CVSIPL_Lud<T>::decompose(CVSIPL_Matrix<T> &a)
+{
+  a.admit();
+  int ret = vsip_lud(lu_, a.get_view());
+  a.release();
+  return ret;
+}
+
+template <typename T>
+int CVSIPL_Lud<T>::solve(vsip_mat_op op, CVSIPL_Matrix<T> &xb)
+{
+  xb.admit();
+  int ret = vsip_lusol(lu_, op, xb.get_view());
+  xb.release();
+  return ret;
+}
+
+
+} // namespace cvsipl
+
+} // namespace ref_impl
+
+} // namespace vsip
+
+#endif // CVSIPL_LU_HPP
Index: ref_impl/vsipl/cvsipl_matrix.hpp
===================================================================
--- ref_impl/vsipl/cvsipl_matrix.hpp	(revision 0)
+++ ref_impl/vsipl/cvsipl_matrix.hpp	(revision 0)
@@ -0,0 +1,81 @@
+#ifndef CVSIPL_MATRIX_HPP
+#define CVSIPL_MATRIX_HPP
+
+#include <vsip/ref_impl/vsipl/cvsipl_support.hpp>
+
+namespace vsip
+{
+
+namespace ref_impl
+{
+
+namespace cvsipl
+{
+
+template <typename T>
+class CVSIPL_Matrix;
+
+template <typename T>
+class CVSIPL_Matrix
+{
+  typedef typename CVSIPL_mview<T>::type       mview_type;
+  typedef typename CVSIPL_block<T>::type       block_type;
+
+  public:
+    CVSIPL_Matrix<T>(T *block, int m, int n);
+    CVSIPL_Matrix<T>(int m, int n);
+    ~CVSIPL_Matrix<T>();
+
+    mview_type *get_view() { return mview_; }
+    void admit() { vsip_blockadmit(mblock_, false); }
+    void release() { vsip_blockrelease(mblock_,false); }
+    
+  private:
+    mview_type         *mview_;
+    block_type         *mblock_;
+    bool               local_data_;
+    
+    
+};
+
+
+template <typename T>
+CVSIPL_Matrix<T>::CVSIPL_Matrix(T *block, int m, int n)
+{
+  // block is allocated, just bind to it.
+  mblock_ = vsip_blockbind(block, m*n, VSIP_MEM_NONE);
+
+  // block must be dense
+  mview_ = vsip_mbind(mblock_, 0, 1, n, n, m);
+
+  local_data_ = false;
+}
+
+template <typename T>
+CVSIPL_Matrix<T>::CVSIPL_Matrix(int m, int n)
+{
+  // create block
+  vsip_blockcreate(m*n, VSIP_MEM_NONE, &mblock_);
+
+  // block must be dense
+  mview_ = vsip_mbind(mblock_, 0, 1, n, n, m);
+
+  local_data_ = true;
+}
+
+template <typename T>
+CVSIPL_Matrix<T>::~CVSIPL_Matrix()
+{
+  // destroy everything!
+  if(local_data_) vsip_blockdestroy(mblock_);
+
+  vsip_mdestroy(mview_);
+}
+
+} // namespace cvsipl
+
+} // namespace ref_impl
+
+} // namespace vsip
+
+#endif // CVSIPL_MATRIX_HPP
Index: impl/solver-lu.hpp
===================================================================
--- impl/solver-lu.hpp	(revision 151073)
+++ impl/solver-lu.hpp	(working copy)
@@ -28,6 +28,9 @@
 #ifdef VSIP_IMPL_HAVE_LAPACK
 #  include <vsip/impl/lapack/solver_lu.hpp>
 #endif
+#ifdef VSIP_IMPL_HAVE_REF
+#  include <vsip/ref_impl/vsipl/solver_lu.hpp>
+#endif
 
 
 
@@ -62,6 +65,10 @@
 template <typename T>
 struct Choose_lud_impl
 {
+#ifdef VSIP_IMPL_HAVE_REF
+  typedef Ref_impl_tag use_type;
+
+#else
   typedef typename Choose_solver_impl<
     Is_lud_impl_avail,
     T,
@@ -71,6 +78,8 @@
     Type_equal<type, None_type>::value,
     As_type<Error_no_solver_for_this_type>,
     As_type<type> >::type use_type;
+#endif
+
 };
 
 } // namespace impl
Index: impl/solver_common.hpp
===================================================================
--- impl/solver_common.hpp	(revision 151073)
+++ impl/solver_common.hpp	(working copy)
@@ -71,6 +71,7 @@
 
 // Implementation tags
 struct Lapack_tag;
+struct Ref_impl_tag;
 
 // Error tags
 struct Error_no_solver_for_this_type;
Index: GNUmakefile.inc.in
===================================================================
--- GNUmakefile.inc.in	(revision 151073)
+++ GNUmakefile.inc.in	(working copy)
@@ -69,6 +69,8 @@
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/pas
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/ipp
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/fftw3
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/ref_impl
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/ref_impl/vsipl
 	$(INSTALL_DATA) src/vsip/impl/acconfig.hpp $(DESTDIR)$(includedir)/vsip/impl
 	for header in $(hdr); do \
           $(INSTALL_DATA) $(srcdir)/src/$$header \
