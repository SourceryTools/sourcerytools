Index: ChangeLog
===================================================================
--- ChangeLog	(revision 192398)
+++ ChangeLog	(working copy)
@@ -1,3 +1,21 @@
+2008-02-22  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/simd/rscvmul.hpp: Fix bug in handling unalignment.
+	* src/vsip/opt/simd/threshold.hpp: Likewise.
+	* src/vsip/opt/simd/vgt.hpp: Likewise.
+	* src/vsip/opt/simd/vma_ip_csc.hpp: Likewise.
+	* src/vsip/opt/simd/vaxpy.hpp: Likewise.
+	* src/vsip/opt/simd/vadd.hpp: Likewise.
+	* src/vsip/opt/simd/vlogic.hpp: Likewise.
+	* src/vsip/opt/simd/vmul.hpp: Likewise.
+	* tests/regressions/view_offset.cpp: New test, regression coverage
+	  for unalignment handling bug.
+	
+	* src/vsip_csl/img/impl/pwarp_simd.hpp: Clear u/v if out of bounds,
+	  add error checking.
+	* tests/vsip_csl/pwarp.cpp: Merge from afrl branch.
+	* tests/regressions/transpose_assign.cpp: Add runtime verbosity.
+	
 2008-02-01  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/simd/simd.hpp (SSE2 double): Fix bug in mag mask width.
Index: src/vsip/opt/simd/rscvmul.hpp
===================================================================
--- src/vsip/opt/simd/rscvmul.hpp	(revision 192398)
+++ src/vsip/opt/simd/rscvmul.hpp	(working copy)
@@ -113,7 +113,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of((T*)B) != 0)
+    while (n && simd::alignment_of((T*)B) != 0)
     {
       *R = alpha * *B;
       R++; B++;
@@ -196,8 +196,10 @@
     T                        alpha,
     std::pair<T*, T*> const& B,
     std::pair<T*, T*> const& R,
-    int n)
+    int                      n)
   {
+    assert(n >= 0);
+
     typedef Simd_traits<T> simd;
     typedef typename simd::simd_type simd_type;
     
@@ -225,7 +227,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of(pRr) != 0)
+    while (n && simd::alignment_of(pRr) != 0)
     {
       *pRr = alpha * *pBr;
       *pRi = alpha * *pBi;
Index: src/vsip/opt/simd/threshold.hpp
===================================================================
--- src/vsip/opt/simd/threshold.hpp	(revision 192398)
+++ src/vsip/opt/simd/threshold.hpp	(working copy)
@@ -178,7 +178,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of(A) != 0)
+    while (n && simd::alignment_of(A) != 0)
     {
       if(O<T,T>::apply(*A,*B)) *Z = *A;
       else *Z = k;
Index: src/vsip/opt/simd/vgt.hpp
===================================================================
--- src/vsip/opt/simd/vgt.hpp	(revision 192398)
+++ src/vsip/opt/simd/vgt.hpp	(working copy)
@@ -114,7 +114,7 @@
   }
 
   // clean up initial unaligned values
-  while (simd::alignment_of(A) != 0)
+  while (n && simd::alignment_of(A) != 0)
   {
     *R = *A > *B;
     R++; A++; B++;
Index: src/vsip/opt/simd/vma_ip_csc.hpp
===================================================================
--- src/vsip/opt/simd/vma_ip_csc.hpp	(revision 192398)
+++ src/vsip/opt/simd/vma_ip_csc.hpp	(working copy)
@@ -113,7 +113,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of((T*)R) != 0)
+    while (n && simd::alignment_of((T*)R) != 0)
     {
       *R += a * *B;
       R++; B++;
Index: src/vsip/opt/simd/vaxpy.hpp
===================================================================
--- src/vsip/opt/simd/vaxpy.hpp	(revision 192398)
+++ src/vsip/opt/simd/vaxpy.hpp	(working copy)
@@ -116,7 +116,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of((T*)R) != 0)
+    while (n && simd::alignment_of((T*)R) != 0)
     {
       *R = a * *B + *C;
       R++; B++; C++;
Index: src/vsip/opt/simd/vadd.hpp
===================================================================
--- src/vsip/opt/simd/vadd.hpp	(revision 192398)
+++ src/vsip/opt/simd/vadd.hpp	(working copy)
@@ -113,7 +113,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of(A) != 0)
+    while (n && simd::alignment_of(A) != 0)
     {
       *R = *A + *B;
       R++; A++; B++;
Index: src/vsip/opt/simd/vlogic.hpp
===================================================================
--- src/vsip/opt/simd/vlogic.hpp	(revision 192398)
+++ src/vsip/opt/simd/vlogic.hpp	(working copy)
@@ -278,7 +278,7 @@
     }
 
     // clean up initial unaligned values
-    while (traits::alignment_of((SimdValueT*)A) != 0)
+    while (n && traits::alignment_of((SimdValueT*)A) != 0)
     {
       *R = FunctionT::exec(*A);
       R++; A++;
@@ -386,7 +386,7 @@
     }
 
     // clean up initial unaligned values
-    while (traits::alignment_of((SimdValueT*)A) != 0)
+    while (n && traits::alignment_of((SimdValueT*)A) != 0)
     {
       *R = FunctionT::exec(*A, *B);
       R++; A++; B++;
Index: src/vsip/opt/simd/vmul.hpp
===================================================================
--- src/vsip/opt/simd/vmul.hpp	(revision 192398)
+++ src/vsip/opt/simd/vmul.hpp	(working copy)
@@ -113,7 +113,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of(A) != 0)
+    while (n && simd::alignment_of(A) != 0)
     {
       *R = *A * *B;
       R++; A++; B++;
@@ -191,7 +191,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of((T*)A) != 0)
+    while (n && simd::alignment_of((T*)A) != 0)
     {
       *R = *A * *B;
       R++; A++; B++;
@@ -329,7 +329,7 @@
     }
 
     // clean up initial unaligned values
-    while (simd::alignment_of(pRr) != 0)
+    while (n && simd::alignment_of(pRr) != 0)
     {
       T rr = *pAr * *pBr - *pAi * *pBi;
       *pRi = *pAr * *pBi + *pAi * *pBr;
Index: src/vsip_csl/img/impl/pwarp_simd.hpp
===================================================================
--- src/vsip_csl/img/impl/pwarp_simd.hpp	(revision 192398)
+++ src/vsip_csl/img/impl/pwarp_simd.hpp	(working copy)
@@ -408,6 +408,16 @@
 	bool_simd_t vec_1_good  = ui_simd::band(vec_u1_good, vec_v1_good);
 	bool_simd_t vec_2_good  = ui_simd::band(vec_u2_good, vec_v2_good);
 	bool_simd_t vec_3_good  = ui_simd::band(vec_u3_good, vec_v3_good);
+
+	// Clear u/v if out of bounds.
+	vec_u0 = simd::band(vec_0_good, vec_u0);
+	vec_u1 = simd::band(vec_1_good, vec_u1);
+	vec_u2 = simd::band(vec_2_good, vec_u2);
+	vec_u3 = simd::band(vec_3_good, vec_u3);
+	vec_v0 = simd::band(vec_0_good, vec_v0);
+	vec_v1 = simd::band(vec_1_good, vec_v1);
+	vec_v2 = simd::band(vec_2_good, vec_v2);
+	vec_v3 = simd::band(vec_3_good, vec_v3);
 	
 #if __PPU__
 	us_simd_t vec_s01_good = (us_simd_t)vec_pack(vec_0_good, vec_1_good);
@@ -518,22 +528,22 @@
 	ui_simd::extract_all(vec_2_offset, off_20, off_21, off_22, off_23);
 	ui_simd::extract_all(vec_3_offset, off_30, off_31, off_32, off_33);
 	
-	T* p_00 = p_in + off_00;
-	T* p_01 = p_in + off_01;
-	T* p_02 = p_in + off_02;
-	T* p_03 = p_in + off_03;
-	T* p_10 = p_in + off_10;
-	T* p_11 = p_in + off_11;
-	T* p_12 = p_in + off_12;
-	T* p_13 = p_in + off_13;
-	T* p_20 = p_in + off_20;
-	T* p_21 = p_in + off_21;
-	T* p_22 = p_in + off_22;
-	T* p_23 = p_in + off_23;
-	T* p_30 = p_in + off_30;
-	T* p_31 = p_in + off_31;
-	T* p_32 = p_in + off_32;
-	T* p_33 = p_in + off_33;
+	T* p_00 = p_in + off_00; assert(off_00 <= rows*cols);
+	T* p_01 = p_in + off_01; assert(off_01 <= rows*cols);
+	T* p_02 = p_in + off_02; assert(off_02 <= rows*cols);
+	T* p_03 = p_in + off_03; assert(off_03 <= rows*cols);
+	T* p_10 = p_in + off_10; assert(off_10 <= rows*cols);
+	T* p_11 = p_in + off_11; assert(off_11 <= rows*cols);
+	T* p_12 = p_in + off_12; assert(off_12 <= rows*cols);
+	T* p_13 = p_in + off_13; assert(off_13 <= rows*cols);
+	T* p_20 = p_in + off_20; assert(off_20 <= rows*cols);
+	T* p_21 = p_in + off_21; assert(off_21 <= rows*cols);
+	T* p_22 = p_in + off_22; assert(off_22 <= rows*cols);
+	T* p_23 = p_in + off_23; assert(off_23 <= rows*cols);
+	T* p_30 = p_in + off_30; assert(off_30 <= rows*cols);
+	T* p_31 = p_in + off_31; assert(off_31 <= rows*cols);
+	T* p_32 = p_in + off_32; assert(off_32 <= rows*cols);
+	T* p_33 = p_in + off_33; assert(off_33 <= rows*cols);
 
 	T z00_00 =  *p_00;
 	T z10_00 = *(p_00 + in_stride_0);
Index: tests/vsip_csl/pwarp.cpp
===================================================================
--- tests/vsip_csl/pwarp.cpp	(revision 192398)
+++ tests/vsip_csl/pwarp.cpp	(working copy)
@@ -12,14 +12,16 @@
 
 #define VERBOSE 1
 #define SAVE_IMAGES 0
-#define DO_CHECK 1
+#define DO_CHECK 0
+#define TEST_TYPES 1
 
-#define NUM_TCS 4
+#define NUM_TCS 6
 
 #if VERBOSE
 #  include <iostream>
 #endif
 #include <string>
+#include <sstream>
 
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
@@ -177,6 +179,36 @@
     P(1, 0) = 0; P(1, 1) = 1; P(1, 2) = 0;
     P(2, 0) = 0; P(2, 1) = 0; P(2, 2) = 1;
     break;
+
+  case 4: // Random projection #3, extracted from example application.
+          // Broke SPU input streaming for VGA images.
+    P(0, 0) = 1.00202;
+    P(0, 1) = 0.00603114;
+    P(0, 2) = 1.03277;
+
+    P(1, 0) = 0.000532397;
+    P(1, 1) = 1.01655;
+    P(1, 2) = 1.66292;
+
+    P(2, 0) = 1.40122e-06;
+    P(2, 1) = 1.05832e-05;
+    P(2, 2) = 1.00002;
+    break;
+
+  case 5: // Random projection #4, extracted from example application.
+          // Broke SIMD for VGA images.
+    P(0, 0) = 1.00504661;
+    P(0, 1) = 0.0150403921;
+    P(0, 2) = 9.60451126;
+
+    P(1, 0) = 0.00317225;
+    P(1, 1) = 1.04547524;
+    P(1, 2) = 16.1063614;
+
+    P(2, 0) = 2.21413484e-06;
+    P(2, 1) = 2.5766507e-05;
+    P(2, 2) = 1.00024176;
+    break;
   }
 }
 
@@ -449,7 +481,8 @@
   typedef typename Perspective_warp<CoeffT, T, interp_linear, forward>
     ::impl_tag impl_tag;
   std::cout << f_prefix
-	    << " (" << Dispatch_name<impl_tag>::name() << ")"
+	    << " (" << Dispatch_name<impl_tag>::name() << ") "
+	    << rows << " x " << cols << " "
 	    << " tc: " << tc 
 	    << "  error: " << error1 << ", " << error2 << std::endl;
 #else
@@ -489,13 +522,45 @@
   length_type row_size,
   length_type col_size)
 {
-  test_pwarp_obj<CoeffT, T>(f_prefix + "-0", rows,cols, row_size,col_size, 0);
-  test_pwarp_obj<CoeffT, T>(f_prefix + "-1", rows,cols, row_size,col_size, 1);
-  test_pwarp_obj<CoeffT, T>(f_prefix + "-2", rows,cols, row_size,col_size, 2);
-  test_pwarp_obj<CoeffT, T>(f_prefix + "-3", rows,cols, row_size,col_size, 3);
+  for (index_type i=0; i<NUM_TCS; ++i)
+  {
+    std::ostringstream filename;
+    filename << f_prefix << "-" << i;
+    test_pwarp_obj<CoeffT, T>(filename.str(), rows,cols, row_size,col_size, i);
+  }
 }
 
 
+#if TEST_TYPES
+void
+test_types(
+  length_type rows,
+  length_type cols,
+  length_type r_size,
+  length_type c_size)
+{
+  typedef unsigned char byte_t;
+
+#if TEST_LEVEL >= 2
+  // Cool types, but not that useful in practice.
+  test_perspective_fun<double, double>("double", rows, cols, r_size, c_size);
+  test_perspective_fun<double, float> ("dfloat", rows, cols, r_size, c_size);
+  test_perspective_fun<double, byte_t>("duchar", rows, cols, r_size, c_size);
+
+  test_perspective_obj<double, float> ("obj-dfloat",rows,cols,r_size,c_size);
+  test_perspective_obj<double, double>("obj-double",rows,cols,r_size,c_size);
+  test_perspective_obj<double, byte_t>("obj-duchar",rows,cols,r_size,c_size);
+#endif
+
+  test_perspective_fun<float,  float> ("float",  rows, cols, r_size, c_size);
+  test_perspective_fun<float,  byte_t>("uchar",  rows, cols, r_size, c_size);
+
+  test_perspective_obj<float,  float> ("obj-float", rows,cols, r_size, c_size);
+  test_perspective_obj<float,  byte_t>("obj-uchar", rows,cols, r_size, c_size);
+}
+#endif
+
+
 int
 main(int argc, char** argv)
 {
@@ -503,27 +568,14 @@
 
   test_apply_proj<double>();
 
-#if 0
-  test_perspective_fun<double, double>       ("double", 480, 640, 32, 16);
-  test_perspective_fun<double, float>        ("dfloat", 480, 640, 32, 16);
-  test_perspective_fun<float,  float>        ("float",  480, 640, 32, 16);
-  test_perspective_fun<double, unsigned char>("duchar", 480, 640, 32, 16);
-  test_perspective_fun<float,  unsigned char>("uchar",  480, 640, 32, 16);
-
-  test_perspective_obj<double, float>        ("obj-dfloat", 480, 640, 32, 16);
-  test_perspective_obj<double, double>       ("obj-double", 480, 640, 32, 16);
-  test_perspective_obj<float,  float>        ("obj-float",  480, 640, 32, 16);
-  test_perspective_obj<double, unsigned char>("obj-duchar", 480, 640, 32, 16);
-  test_perspective_obj<float,  unsigned char>("obj-uchar",  480, 640, 32, 16);
+#if TEST_TYPES
+  test_types(1080, 1920, 32, 16);
+  test_types(480,   640, 32, 16);
+  test_types(512,   512, 32, 16);
 #endif
 
-  test_perspective_fun<double, double>      ("fun-double", 512, 512, 32, 16);
-  test_perspective_fun<double, float>       ("fun-dfloat", 512, 512, 32, 16);
-  test_perspective_fun<float, float>        ("fun-float",  512, 512, 32, 16);
-  test_perspective_fun<float, unsigned char>("fun-uchar",  512, 512, 32, 16);
-
-  test_perspective_obj<double, double>      ("obj-double", 512, 512, 32, 16);
-  test_perspective_obj<double, float>       ("obj-dfloat", 512, 512, 32, 16);
-  test_perspective_obj<float, float>        ("obj-float",  512, 512, 32, 16);
-  test_perspective_obj<float, unsigned char>("obj-uchar",  512, 512, 32, 16);
+  // Standalone examples for debugging.
+  // test_perspective_obj<float, byte_t>("obj-uchar", 1080, 1920, 32, 16);
+  // test_pwarp_obj<float, byte_t>("obj-uchar", 480, 640, 32, 16, 5);
+  // test_pwarp_obj<float, byte_t>("obj-uchar", 1080, 1920, 32, 16, 5);
 }
Index: tests/regressions/view_offset.cpp
===================================================================
--- tests/regressions/view_offset.cpp	(revision 0)
+++ tests/regressions/view_offset.cpp	(revision 0)
@@ -0,0 +1,236 @@
+/* Copyright (c) 2008 by CodeSourcery, LLC.  All rights reserved. */
+
+
+/** @file    tests/view_offset.cpp
+    @author  Jules Bergmann
+    @date    2008-02-22
+    @brief   VSIPL++ Library: Regression test for small (less than SIMD
+             width), unaligned element-wise vector operations that triggered
+	     a bug in the built-in generic SIMD routines.
+     
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#define VERBOSE 0
+
+#if VERBOSE
+#  include <iostream>
+#endif
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Definitions - Utility Functions
+***********************************************************************/
+
+template <typename T>
+void
+test_vadd(
+  length_type len,
+  length_type offset1,
+  length_type offset2,
+  length_type offset3)
+{
+  Rand<T> gen(0, 0);
+
+  Vector<T> big_A(len + offset1);
+  Vector<T> big_B(len + offset2);
+  Vector<T> big_Z(len + offset3);
+
+  typename Vector<T>::subview_type A = big_A(Domain<1>(offset1, 1, len));
+  typename Vector<T>::subview_type B = big_B(Domain<1>(offset2, 1, len));
+  typename Vector<T>::subview_type Z = big_Z(Domain<1>(offset3, 1, len));
+
+  A = gen.randu(len);
+  B = gen.randu(len);
+
+  Z = A + B;
+
+  for (index_type i=0; i<len; ++i)
+  {
+    test_assert(Almost_equal<T>::eq(Z.get(i), A.get(i) + B.get(i)));
+  }
+}
+
+
+
+template <typename T>
+void
+test_vma_cSC(
+  length_type len,
+  length_type offset1,
+  length_type offset2,
+  length_type offset3)
+{
+  typedef typename vsip::impl::Scalar_of<T>::type ST;
+
+  Rand<ST> rgen(0, 0);
+  Rand<T>  cgen(0, 0);
+
+  Vector<ST> big_B(len + offset1);
+  Vector<T>  big_C(len + offset2);
+  Vector<T>  big_Z(len + offset3);
+
+  T a = 2.0;
+  typename Vector<ST>::subview_type B = big_B(Domain<1>(offset1, 1, len));
+  typename Vector<T>::subview_type  C = big_C(Domain<1>(offset2, 1, len));
+  typename Vector<T>::subview_type  Z = big_Z(Domain<1>(offset3, 1, len));
+
+  B = rgen.randu(len);
+  C = cgen.randu(len);
+
+  Z = a * B + C;
+
+  for (index_type i=0; i<len; ++i)
+  {
+    test_assert(Almost_equal<T>::eq(Z.get(i), a * B.get(i) + C.get(i)));
+  }
+}
+
+
+
+template <typename T>
+void
+test_vmul(
+  length_type len,
+  length_type offset1,
+  length_type offset2,
+  length_type offset3)
+{
+  Rand<T> gen(0, 0);
+
+  Vector<T> big_A(len + offset1);
+  Vector<T> big_B(len + offset2);
+  Vector<T> big_Z(len + offset3);
+
+  typename Vector<T>::subview_type A = big_A(Domain<1>(offset1, 1, len));
+  typename Vector<T>::subview_type B = big_B(Domain<1>(offset2, 1, len));
+  typename Vector<T>::subview_type Z = big_Z(Domain<1>(offset3, 1, len));
+
+  A = gen.randu(len);
+  B = gen.randu(len);
+
+  Z = A * B;
+
+  for (index_type i=0; i<len; ++i)
+  {
+#if VERBOSE
+    if (!equal(Z.get(i), A.get(i) * B.get(i)))
+    {
+      std::cout << "Z(" << i << ")        = " << Z(i) << std::endl;
+      std::cout << "A(" << i << ") * B(" << i << ") = "
+		<< A(i) * B(i) << std::endl;
+    }
+#endif
+    test_assert(Almost_equal<T>::eq(Z.get(i), A.get(i) * B.get(i)));
+  }
+}
+
+
+
+template <typename T>
+void
+test_vthresh(
+  length_type len,
+  length_type offset1,
+  length_type offset2,
+  length_type offset3)
+{
+  Rand<T> gen(0, 0);
+
+  Vector<T> big_A(len + offset1);
+  Vector<T> big_B(len + offset2);
+  Vector<T> big_Z(len + offset3);
+
+  typename Vector<T>::subview_type A = big_A(Domain<1>(offset1, 1, len));
+  typename Vector<T>::subview_type B = big_B(Domain<1>(offset2, 1, len));
+  typename Vector<T>::subview_type Z = big_Z(Domain<1>(offset3, 1, len));
+  T                                k = 0.5;
+
+  A = gen.randu(len);
+  B = gen.randu(len);
+
+  Z = ite(A > B, A, k);
+
+  for (index_type i=0; i<len; ++i)
+  {
+    test_assert(Almost_equal<T>::eq(Z.get(i), A.get(i) > B.get(i) ? A.get(i) : k));
+  }
+}
+
+
+
+
+template <typename T>
+void
+test_sweep()
+{
+  for (index_type i=1; i<=128; ++i)
+  {
+    // 080222: These broke built-in SIMD functions when i < vector size.
+    test_vmul<T>(i, 1, 1, 1);
+    test_vadd<T>(i, 1, 1, 1);
+
+    // 080222: This would have been broken if it was being dispatched to.
+    test_vma_cSC<T>(i, 1, 1, 1);
+
+    // These work fine.
+    test_vmul<T>(i, 0, 0, 0);
+    test_vmul<T>(i, 1, 0, 0);
+    test_vmul<T>(i, 0, 1, 0);
+    test_vmul<T>(i, 0, 0, 1);
+
+    test_vadd<T>(i, 0, 0, 0);
+    test_vadd<T>(i, 1, 0, 0);
+    test_vadd<T>(i, 0, 1, 0);
+    test_vadd<T>(i, 0, 0, 1);
+
+    test_vma_cSC<T>(i, 0, 0, 0);
+    test_vma_cSC<T>(i, 1, 0, 0);
+    test_vma_cSC<T>(i, 0, 1, 0);
+    test_vma_cSC<T>(i, 0, 0, 1);
+  }
+}
+
+template <typename T>
+void
+test_sweep_real()
+{
+  for (index_type i=1; i<=128; ++i)
+  {
+    test_vthresh<T>(i, 1, 1, 1);
+
+    test_vthresh<T>(i, 0, 0, 0);
+    test_vthresh<T>(i, 1, 0, 0);
+    test_vthresh<T>(i, 0, 1, 0);
+    test_vthresh<T>(i, 0, 0, 1);
+  }
+}
+
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_sweep<float          >();
+  test_sweep<complex<float> >();
+
+  test_sweep_real<float>();
+}
Index: tests/regressions/transpose_assign.cpp
===================================================================
--- tests/regressions/transpose_assign.cpp	(revision 192398)
+++ tests/regressions/transpose_assign.cpp	(working copy)
@@ -19,6 +19,7 @@
 ***********************************************************************/
 
 #include <memory>
+#include <iostream>
 
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
@@ -66,8 +67,9 @@
 	  typename DstOrderT,
 	  typename SrcOrderT>
 void
-cover_hl()
+cover_hl(int verbose)
 {
+  if (verbose >= 1) std::cout << "cover_hl\n";
   // These tests fail for Intel C++ 9.1 for Windows prior
   // to workaround in fast-transpose.hpp:
   test_hl<T, DstOrderT, SrcOrderT>(5, 3);  // known bad case
@@ -78,19 +80,25 @@
     length_type max_rows = 32;
     length_type max_cols = 32;
     for (index_type rows=1; rows<max_rows; ++rows)
+    {
+      if (verbose >= 2) std::cout << " - " << rows << " / " << max_rows << "\n";
       for (index_type cols=1; cols<max_cols; ++cols)
 	test_hl<T, DstOrderT, SrcOrderT>(rows, cols);
+    }
   }
 
   {
     length_type max_rows = 256;
     length_type max_cols = 256;
     for (index_type rows=1; rows<max_rows; rows+=3)
+    {
+      if (verbose >= 2) std::cout << " - " << rows << " / " << max_rows << "\n";
       for (index_type cols=1; cols<max_cols; cols+=5)
       {
 	test_hl<T, DstOrderT, SrcOrderT>(rows, cols);
 	test_hl<T, DstOrderT, SrcOrderT>(cols, rows);
       }
+    }
   }
 }
 
@@ -128,25 +136,32 @@
 
 template <typename T>
 void
-cover_ll()
+cover_ll(int verbose)
 {
+  if (verbose >= 1) std::cout << "cover_ll\n";
   {
     length_type max_rows = 32;
     length_type max_cols = 32;
     for (index_type rows=1; rows<max_rows; ++rows)
+    {
+      if (verbose >= 2) std::cout << " - " << rows << " / " << max_rows << "\n";
       for (index_type cols=1; cols<max_cols; ++cols)
 	test_ll<T>(rows, cols);
+    }
   }
 
   {
     length_type max_rows = 256;
     length_type max_cols = 256;
     for (index_type rows=1; rows<max_rows; rows+=3)
+    {
+      if (verbose >= 2) std::cout << " - " << rows << " / " << max_rows << "\n";
       for (index_type cols=1; cols<max_cols; cols+=5)
       {
 	test_ll<T>(rows, cols);
 	test_ll<T>(cols, rows);
       }
+    }
   }
 }
 
@@ -160,11 +175,15 @@
 
   vsipl init(argc, argv);
 
-  cover_hl<float, row2_type, col2_type>();
-  cover_hl<complex<float>, row2_type, col2_type>();
+  int verbose = 0;
+  if (argc == 2 && argv[1][0] == '1') verbose = 1;
+  if (argc == 2 && argv[1][0] == '2') verbose = 2;
 
-  cover_ll<float>();
-  cover_ll<complex<float> >();
+  cover_hl<float, row2_type, col2_type>(verbose);
+  cover_hl<complex<float>, row2_type, col2_type>(verbose);
 
+  cover_ll<float>(verbose);
+  cover_ll<complex<float> >(verbose);
+
   return 0;
 }
