Index: solver_lu.hpp
===================================================================
--- solver_lu.hpp	(revision 151855)
+++ solver_lu.hpp	(working copy)
@@ -3,12 +3,12 @@
 /** @file    vsip/impl/lapack/solver_lu.hpp
     @author  Assem Salama
     @date    2006-04-13
-    @brief   VSIPL++ Library: LU linear system solver using lapack.
+    @brief   VSIPL++ Library: LU linear system solver using cvsip.
 
 */
 
-#ifndef VSIP_REF_IMPL_SOLVER_LU_HPP
-#define VSIP_REF_IMPL_SOLVER_LU_HPP
+#ifndef VSIP_CORE_CVSIP_SOLVER_LU_HPP
+#define VSIP_CORE_CVSIP_SOLVER_LU_HPP
 
 /***********************************************************************
   Included Files
@@ -25,6 +25,7 @@
 #include <vsip/core/cvsip/cvsip_matrix.hpp>
 #include <vsip/core/cvsip/cvsip_lu.hpp>
 
+#include <vsip_csl/output.hpp>
 
 
 /***********************************************************************
@@ -78,7 +79,6 @@
   typedef std::vector<int, Aligned_allocator<int> > vector_type;
 
   length_type  length_;			// Order of A.
-  vector_type  ipiv_;			// Additional info on Q
 
   Matrix<T, data_block_type> data_;	// Factorized Cholesky matrix (A)
   cvsip::Cvsip_matrix<T>     cvsip_data_;
@@ -101,9 +101,8 @@
   )
 VSIP_THROW((std::bad_alloc))
   : length_      (length),
-    ipiv_        (length_),
     data_        (length_, length_),
-    cvsip_data_  (data_.block().impl_data(), length_, length_),
+    cvsip_data_  (data_.block().impl_data(), length_, length_, col2_type()),
     cvsip_lud_   (length_)
 {
   assert(length_ > 0);
@@ -115,14 +114,11 @@
 Lud_impl<T, Cvsip_tag>::Lud_impl(Lud_impl const& lu)
 VSIP_THROW((std::bad_alloc))
   : length_      (lu.length_),
-    ipiv_        (length_),
     data_        (length_, length_),
     cvsip_data_  (data_.block().impl_data(), length_, length_),
     cvsip_lud_   (length_)
 {
   data_ = lu.data_;
-  for (index_type i=0; i<length_; ++i)
-    ipiv_[i] = lu.ipiv_[i];
 }
 
 
@@ -143,6 +139,7 @@
 /// FLOPS:
 ///   real   : UPDATE
 ///   complex: UPDATE
+//
 
 template <typename T>
 template <typename Block>
@@ -152,16 +149,15 @@
 {
   assert(m.size(0) == length_ && m.size(1) == length_);
 
+  cvsip_data_.release(false);
   assign_local(data_, m);
+  cvsip_data_.admit(true);
 
   bool success = cvsip_lud_.decompose(cvsip_data_);
 
-
   return success;
 }
 
-
-
 /// Solve Op(A) x = b (where A previously given to decompose)
 ///
 /// Op(A) is
@@ -201,12 +197,13 @@
 
   if (tr == mat_ntrans)
     trans = VSIP_MAT_NTRANS;
-  else if (tr == mat_trans)
+  else if (tr == mat_trans && ! Is_complex<T>::value)
     trans = VSIP_MAT_TRANS;
-  else if (tr == mat_herm)
-  {
-    assert(Is_complex<T>::value);
+  else if (tr == mat_herm && Is_complex<T>::value)
     trans = VSIP_MAT_HERM;
+  else {
+    VSIP_IMPL_THROW(unimplemented(
+      "Lud_impl cvsip solver doesn't support this transformation"));
   }
 
   {
@@ -215,7 +212,6 @@
     cvsip::Cvsip_matrix<T>
 	      cvsip_b_int(b_ext.data(),b_ext.size(0),b_ext.size(1),
 			               b_ext.stride(0),b_ext.stride(1));
-
     cvsip_lud_.solve(trans,cvsip_b_int);
 
   }
@@ -229,4 +225,4 @@
 } // namespace vsip
 
 
-#endif // VSIP_IMPL_LAPACK_SOLVER_LU_HPP
+#endif // VSIP_CORE_CVSIP_SOLVER_LU_HPP
Index: cvsip.hpp
===================================================================
--- cvsip.hpp	(revision 151857)
+++ cvsip.hpp	(working copy)
@@ -147,6 +147,8 @@
 { \
   return VF(lu_obj, op, view); \
 }
+
+
 /******************************************************************************
  * Function declarations
 ******************************************************************************/
Index: cvsip_lu.hpp
===================================================================
--- cvsip_lu.hpp	(revision 151855)
+++ cvsip_lu.hpp	(working copy)
@@ -31,8 +31,8 @@
   typedef typename Cvsip_traits<T>::lud_object_type     lud_object_type;
 
   public:
-    Cvsip_lud(int n);
-    ~Cvsip_lud();
+    Cvsip_lud<T>(int n);
+    ~Cvsip_lud<T>();
 
     int decompose(Cvsip_matrix<T> &a);
     int solve(vsip_mat_op op, Cvsip_matrix<T> &xb);
@@ -56,10 +56,9 @@
 template <typename T>
 int Cvsip_lud<T>::decompose(Cvsip_matrix<T> &a)
 {
-  a.admit(false);
+
   int ret = lud(lu_, a.get_view());
-  a.release(true);
-  return ret;
+  return !ret;
 }
 
 template <typename T>
@@ -67,7 +66,6 @@
 {
   xb.admit(true);
   int ret = lusol(lu_, op, xb.get_view());
-  printf("RET: %d\n", ret);
   xb.release(true);
   return ret;
 }
Index: cvsip_matrix.hpp
===================================================================
--- cvsip_matrix.hpp	(revision 151855)
+++ cvsip_matrix.hpp	(working copy)
@@ -32,9 +32,10 @@
 
   public:
     Cvsip_matrix<T>(T *block, int m, int n, int s1, int s2);
-    Cvsip_matrix<T>(int m, int n, int s1, int s2);
-    Cvsip_matrix<T>(T *block, int m, int n);
-    Cvsip_matrix<T>(int m, int n);
+    template <typename OrderT>
+    Cvsip_matrix<T>(int m, int n, OrderT const&);
+    template <typename OrderT>
+    Cvsip_matrix<T>(T *block, int m, int n, OrderT const&);
     ~Cvsip_matrix<T>();
 
     mview_type *get_view() { return mview_; }
@@ -42,8 +43,8 @@
     void release(bool flag) { blockrelease(mblock_, flag); }
     
   private:
-    mview_type         *mview_;
-    block_type         *mblock_;
+    mview_type*        mview_;
+    block_type*        mblock_;
     bool               local_data_;
     
     
@@ -53,51 +54,47 @@
 Cvsip_matrix<T>::Cvsip_matrix(T *block, int m, int n, int s1, int s2)
 {
   // block is allocated, just bind to it.
-  mblock_ = blockbind(block, m*n, VSIP_MEM_NONE);
+  mblock_ = blockbind(block, (n-1)*s2 + (m-1)*s1 + 1, VSIP_MEM_NONE);
 
-  // block must be dense
-  mview_ = mbind(mblock_, 0, s1, n, s2, m);
+  mview_ = mbind(mblock_, 0, s1, m, s2, n);
 
   local_data_ = false;
 }
 
 template <typename T>
-Cvsip_matrix<T>::Cvsip_matrix(int m, int n, int s1, int s2)
+template <typename OrderT>
+Cvsip_matrix<T>::Cvsip_matrix(int m, int n, OrderT const& = row2_type())
 {
   // create block
   blockcreate(m*n, VSIP_MEM_NONE, &mblock_);
 
   // block must be dense
-  mview_ = mbind(mblock_, 0, s1, n, s2, m);
+  if(Type_equal<OrderT, row2_type>::value)
+    mview_ = mbind(mblock_, 0, m, n, 1, m);
+  else
+    mview_ = mbind(mblock_, 0, 1, n, n, m);
 
   local_data_ = true;
 }
 
 template <typename T>
-Cvsip_matrix<T>::Cvsip_matrix(T *block, int m, int n)
+template <typename OrderT>
+Cvsip_matrix<T>::Cvsip_matrix(T *block, int m, int n,
+		              OrderT const& = row2_type())
 {
   // block is allocated, just bind to it.
   mblock_ = blockbind(block, m*n, VSIP_MEM_NONE);
 
   // block must be dense
-  mview_ = mbind(mblock_, 0, 1, n, n, m);
+  if(Type_equal<OrderT, row2_type>::value)
+    mview_ = mbind(mblock_, 0, m, n, 1, m);
+  else
+    mview_ = mbind(mblock_, 0, 1, n, n, m);
 
   local_data_ = false;
 }
 
 template <typename T>
-Cvsip_matrix<T>::Cvsip_matrix(int m, int n)
-{
-  // create block
-  blockcreate(m*n, VSIP_MEM_NONE, &mblock_);
-
-  // block must be dense
-  mview_ = mbind(mblock_, 0, 1, n, n, m);
-
-  local_data_ = true;
-}
-
-template <typename T>
 Cvsip_matrix<T>::~Cvsip_matrix()
 {
   // destroy everything!
Index: solver-lu.cpp
===================================================================
--- solver-lu.cpp	(revision 151693)
+++ solver-lu.cpp	(working copy)
@@ -26,6 +26,12 @@
 #include "test-random.hpp"
 #include "solver-common.hpp"
 
+#ifdef VSIP_IMPL_HAVE_CVSIP
+#define TEST_TRANSPOSE_SOLVE      0
+#else
+#define TEST_TRANSPOSE_SOLVE      1
+#endif
+
 #define VERBOSE       0
 #define DO_ASSERT     1
 #define DO_SWEEP      0
@@ -100,7 +106,9 @@
 
     // 2. Solve A X = B.
     lu.template solve<mat_ntrans>(b, x1);
+#if TEST_TRANSPOSE_SOLVE == 1
     lu.template solve<mat_trans>(b, x2);
+#endif
     lu.template solve<Test_traits<T>::trans>(b, x3); // mat_herm if T complex
   }
   if (rtm == by_value)
@@ -114,7 +122,9 @@
 
     // 2. Solve A X = B.
     x1 = lu.template solve<mat_ntrans>(b);
+#if TEST_TRANSPOSE_SOLVE == 1
     x2 = lu.template solve<mat_trans>(b);
+#endif
     x3 = lu.template solve<Test_traits<T>::trans>(b); // mat_herm if T complex
   }
 
@@ -126,7 +136,9 @@
   Matrix<T> chk3(n, p);
 
   prod(a, x1, chk1);
+#if TEST_TRANSPOSE_SOLVE == 1
   prod(trans(a), x2, chk2);
+#endif
   prod(trans_or_herm(a), x3, chk3);
 
   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
@@ -169,8 +181,13 @@
   {
     scalar_type residual_1 = norm_2((b - chk1).col(i));
     scalar_type err1       = residual_1 / (a_norm_2 * norm_2(x1.col(i)) * eps);
+#if TEST_TRANSPOSE_SOLVE == 1
     scalar_type residual_2 = norm_2((b - chk2).col(i));
     scalar_type err2       = residual_2 / (a_norm_2 * norm_2(x2.col(i)) * eps);
+#else
+    scalar_type residual_2 = 0;
+    scalar_type err2       = 0;
+#endif
     scalar_type residual_3 = norm_2((b - chk3).col(i));
     scalar_type err3       = residual_3 / (a_norm_2 * norm_2(x3.col(i)) * eps);
 
@@ -192,7 +209,9 @@
 
 #if DO_ASSERT
     test_assert(err1 < p_limit);
+#if TEST_TRANSPOSE_SOLVE == 1
     test_assert(err2 < p_limit);
+#endif
     test_assert(err3 < p_limit);
 #endif
 
@@ -247,7 +266,9 @@
 
     // 2. Solve A X = B.
     lu.template solve<mat_ntrans>(b, x1);
+#if TEST_TRANSPOSE_SOLVE == 1
     lu.template solve<mat_trans>(b, x2);
+#endif
     lu.template solve<Test_traits<T>::trans>(b, x3); // mat_herm if T complex
   }
   if (rtm == by_value)
@@ -261,7 +282,9 @@
 
     // 2. Solve A X = B.
     impl::assign_local(x1, lu.template solve<mat_ntrans>(b));
+#if TEST_TRANSPOSE_SOLVE == 1
     impl::assign_local(x2, lu.template solve<mat_trans>(b));
+#endif
     impl::assign_local(x3, lu.template solve<Test_traits<T>::trans>(b));
   }
 
@@ -273,7 +296,9 @@
   Matrix<T, block_type> chk3(n, p);
 
   prod(a, x1, chk1);
+#if TEST_TRANSPOSE_SOLVE == 1
   prod(trans(a), x2, chk2);
+#endif
   prod(trans_or_herm(a), x3, chk3);
 
   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
@@ -317,8 +342,13 @@
   {
     scalar_type residual_1 = norm_2((b - chk1).col(i));
     scalar_type err1       = residual_1 / (a_norm_2 * norm_2(x1.col(i)) * eps);
+#if TEST_TRANSPOSE_SOLVE == 1
     scalar_type residual_2 = norm_2((b - chk2).col(i));
     scalar_type err2       = residual_2 / (a_norm_2 * norm_2(x2.col(i)) * eps);
+#else
+    scalar_type residual_2 = 0;
+    scalar_type err2       = 0;
+#endif
     scalar_type residual_3 = norm_2((b - chk3).col(i));
     scalar_type err3       = residual_3 / (a_norm_2 * norm_2(x3.col(i)) * eps);
 
@@ -339,7 +369,9 @@
 #endif
 
     test_assert(err1 < p_limit);
+#if TEST_TRANSPOSE_SOLVE == 1
     test_assert(err2 < p_limit);
+#endif
     test_assert(err3 < p_limit);
 
     if (err1 > max_err1) max_err1 = err1;
