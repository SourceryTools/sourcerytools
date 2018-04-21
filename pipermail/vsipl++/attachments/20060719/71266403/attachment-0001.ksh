Index: impl/simd/update_running_sum.cpp
===================================================================
--- impl/simd/update_running_sum.cpp	(revision 0)
+++ impl/simd/update_running_sum.cpp	(revision 0)
@@ -0,0 +1,56 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/simd/update_running_sum.cpp
+    @author  Assem Salama
+    @date    2006-06-25
+    @brief   VSIPL++ Library: SIMD running sum used in CFAR
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/simd/update_running_sum.hpp>
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace simd
+{
+
+#if !VSIP_IMPL_INLINE_LIBSIMD
+
+template <typename T>
+void
+update_running_sum(
+  T*  a,
+  T*  b,
+  T*  c,
+  T*  d,
+  T*  z,
+  int len)
+{
+  static bool const Is_vectorized = Is_algorithm_supported<T, false,
+     Alg_update_running_sum>::value;
+  
+  Simd_update_running_sum<T,Is_vectorized>::exec(a,b,c,d,z,len);
+}
+
+template void update_running_sum(float *a,float *b,float *c,float *d,float *z,
+                                 int len);
+template void update_running_sum(double *a,double *b,double *c,double *d,
+                                 double *z, int len);
+
+#endif
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
+
Index: impl/simd/update_running_sum.hpp
===================================================================
--- impl/simd/update_running_sum.hpp	(revision 0)
+++ impl/simd/update_running_sum.hpp	(revision 0)
@@ -0,0 +1,222 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/simd/update_running_sum.hpp
+    @author  Assem Salama
+    @date    2006-06-07
+    @brief   VSIPL++ Library: SIMD update running sum for CFAR
+
+*/
+
+#ifndef VSIP_IMPL_SIMD_UPDATE_RUNNING_SUM_HPP
+#define VSIP_IMPL_SIMD_UPDATE_RUNNING_SUM_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <complex>
+
+#include <vsip/impl/simd/simd.hpp>
+#include <vsip/impl/metaprogramming.hpp>
+
+#define VSIP_IMPL_INLINE_LIBSIMD 1
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace simd
+{
+
+// Define value_types for which update_running_sum is optimized.
+//  - float
+//  - double
+//  - complex<float>
+//  - complex<double>
+
+template <typename T,
+	  bool     IsSplit>
+struct Is_algorithm_supported<T, IsSplit, Alg_update_running_sum>
+{
+  typedef typename Scalar_of<T>::type scalar_type;
+  static bool const value =
+    Simd_traits<scalar_type>::is_accel &&
+    (Type_equal<scalar_type, float>::value ||
+     Type_equal<scalar_type, double>::value);
+};
+
+
+
+// Class for update_running_sum - Z += A+B - (C+D)
+
+template <typename T,
+	  bool     Is_vectorized>
+struct Simd_update_running_sum;
+
+
+// Generic, non-vectorized implementation
+
+template <typename T>
+struct Simd_update_running_sum<T, false>
+{
+  static void exec(T* A, T* B, T *C, T *D, T *Z, int len)
+  {
+    while (len)
+    {
+      *Z += (*A + *B) - (*C + *D);
+      Z++;A++;B++;C++;D++;
+      len--;
+    }
+  }
+};
+
+
+
+// Vectorized implementation
+
+template <typename T>
+struct Simd_update_running_sum<T, true>
+{
+  static void exec(T* A, T* B, T *C, T *D, T *Z, int len)
+  {
+    // handle mis-aligned vectors
+    if ( ((((unsigned long)Z) & 0xf) != (((unsigned long)A) & 0xf)) ||
+	 ((((unsigned long)Z) & 0xf) != (((unsigned long)B) & 0xf)) ||
+	 ((((unsigned long)Z) & 0xf) != (((unsigned long)C) & 0xf)) ||
+	 ((((unsigned long)Z) & 0xf) != (((unsigned long)D) & 0xf)))
+    {
+      // PROFILE
+      Simd_update_running_sum<T,false>::exec(A,B,C,D,Z,len);
+      return;
+    }
+
+    // clean up initial unaligned values
+    while (((unsigned long)A) & 0xf)
+    {
+      *Z = (*A + *B) - (*C + *D);
+      Z++;A++;B++;C++;D++;
+      len--;
+    }
+
+    // return if we finished
+    if(!len) return;
+
+    // go through simd loop
+    typedef Simd_traits<T> simd;
+    typedef typename simd::simd_type simd_type;
+
+    simd_type reg0;
+    simd_type reg1;
+    simd_type reg2;
+    simd_type reg3;
+    simd_type reg4;
+    simd_type reg5;
+    simd_type reg6;
+    simd_type reg7;
+
+    simd::enter();
+
+    while (len >= 2*simd::vec_size)
+    {
+      // in order to make this a little faster, we will unroll the loop and
+      // do twice as much work in one interation
+      reg0 = simd::load(A);
+      reg1 = simd::load(B);
+      reg0 = simd::add(reg0, reg1);
+
+      reg2 = simd::load(C);
+      reg3 = simd::load(D);
+      reg2 = simd::add(reg2, reg3);
+
+      reg1 = simd::load(A+simd::vec_size);
+      reg3 = simd::load(B+simd::vec_size);
+      reg1 = simd::add(reg1, reg3);
+
+      reg3 = simd::load(C+simd::vec_size);
+      reg4 = simd::load(D+simd::vec_size);
+      reg3 = simd::add(reg3, reg4);
+
+      // Z += (A+B) - (C+D)
+      reg4 = simd::load(Z);
+      reg5 = simd::load(Z+simd::vec_size);
+
+#if 0
+// this order doesn't work correctly
+      reg4 = simd::add(reg4,reg0);
+      reg4 = simd::sub(reg4,reg2);
+      reg5 = simd::add(reg5,reg1);
+      reg5 = simd::sub(reg5,reg3);
+#else
+      reg0 = simd::sub(reg0,reg2);
+      reg4 = simd::add(reg4,reg0);
+      reg1 = simd::sub(reg1,reg3);
+      reg5 = simd::add(reg5,reg1);
+#endif
+
+      // store
+      simd::store(Z,                reg0);
+      simd::store(Z+simd::vec_size, reg1);
+
+      // increment pointers
+      A += 2*simd::vec_size; B += 2*simd::vec_size;
+      C += 2*simd::vec_size; D += 2*simd::vec_size;
+      Z += 2*simd::vec_size;
+
+      len -= 2*simd::vec_size;
+
+    }
+
+    simd::exit();
+
+    // do the rest
+    while (len)
+    {
+      *Z += (*A + *B)-(*C + *D);
+      Z++;A++;B++;C++;D++;
+      len--;
+    }
+
+  }
+
+};
+
+// if VSIP_IMPL_LIBSIMD_INLINE macro is 1, we define the function as inline
+// here, otherwise, we just declare it
+#if VSIP_IMPL_INLINE_LIBSIMD
+template <typename T>
+inline void
+update_running_sum(
+  T*  a,
+  T*  b,
+  T*  c,
+  T*  d,
+  T*  z,
+  int len)
+{
+  static bool const Is_vectorized = Is_algorithm_supported<T, false,
+     Alg_update_running_sum>::value;
+  
+  Simd_update_running_sum<T,Is_vectorized>::exec(a,b,c,d,z,len);
+}
+#else
+template <typename T>
+void
+update_running_sum(
+  T*  a,
+  T*  b,
+  T*  c,
+  T*  d,
+  T*  z,
+  int len);
+#endif
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif
