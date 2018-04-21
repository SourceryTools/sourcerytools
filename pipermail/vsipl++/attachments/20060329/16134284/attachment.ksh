Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.422
diff -u -r1.422 ChangeLog
--- ChangeLog	28 Mar 2006 14:46:38 -0000	1.422
+++ ChangeLog	29 Mar 2006 13:00:25 -0000
@@ -1,3 +1,17 @@
+2006-03-29  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/GNUmakefile.inc.in (src_vsip_cxx_sources): Add rscvmul.cpp.
+	* src/vsip/impl/simd/eval-generic.hpp: Allow vmul evaluator to work
+	  if destination aliases one of the inputs.  Add evaluators for
+	  rscvmul cases.
+	* src/vsip/impl/simd/rscvmul.cpp: New file, generic SIMD impl of
+	  rscvmul (real scalar, complex vector, element-wise multiply).
+	* src/vsip/impl/simd/rscvmul.hpp: New file, generic SIMD impl of
+	  rscvmul (real scalar, complex vector, element-wise multiply).
+	* src/vsip/impl/simd/simd.hpp (Alg_rscvmul): New algorithm tag.
+	* src/vsip/impl/simd/vmul.hpp: Use regular store instead of
+	  stream_store.  Performance is better for in-cache vector sizes.
+	
 2006-03-28  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac (CLAPACK_NOOPT): New substitution, non-optimized
Index: src/vsip/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/GNUmakefile.inc.in,v
retrieving revision 1.14
diff -u -r1.14 GNUmakefile.inc.in
--- src/vsip/GNUmakefile.inc.in	3 Mar 2006 14:30:53 -0000	1.14
+++ src/vsip/GNUmakefile.inc.in	29 Mar 2006 13:00:26 -0000
@@ -22,7 +22,8 @@
 ifdef VSIP_IMPL_HAVE_SAL
 src_vsip_cxx_sources += $(srcdir)/src/vsip/impl/sal.cpp
 endif
-src_vsip_cxx_sources += $(srcdir)/src/vsip/impl/simd/vmul.cpp
+src_vsip_cxx_sources += $(srcdir)/src/vsip/impl/simd/vmul.cpp \
+			$(srcdir)/src/vsip/impl/simd/rscvmul.cpp
 src_vsip_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(src_vsip_cxx_sources))
 cxx_sources += $(src_vsip_cxx_sources)
 
Index: src/vsip/impl/simd/eval-generic.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/simd/eval-generic.hpp,v
retrieving revision 1.1
diff -u -r1.1 eval-generic.hpp
--- src/vsip/impl/simd/eval-generic.hpp	3 Mar 2006 14:30:53 -0000	1.1
+++ src/vsip/impl/simd/eval-generic.hpp	29 Mar 2006 13:00:26 -0000
@@ -23,6 +23,7 @@
 
 #include <vsip/impl/simd/simd.hpp>
 #include <vsip/impl/simd/vmul.hpp>
+#include <vsip/impl/simd/rscvmul.hpp>
 
 /***********************************************************************
   Declarations
@@ -85,9 +86,7 @@
     Ext_data<RBlock> ext_r(src.right(), SYNC_IN);
     return (ext_dst.stride(0) == 1 &&
 	    ext_l.stride(0) == 1 &&
-	    ext_r.stride(0) == 1 &&
-	    ext_dst.data() != ext_l.data() &&
-	    ext_dst.data() != ext_r.data());
+	    ext_r.stride(0) == 1);
   }
 };
 } // namespace vsip::impl::simd
@@ -120,6 +119,114 @@
 
 
 
+
+/***********************************************************************
+  Scalar-view element-wise operations
+***********************************************************************/
+
+// Evaluate real-scalar * complex-view
+
+template <typename DstBlock,
+	  typename T,
+	  typename VBlock>
+struct Serial_expr_evaluator<
+         1, DstBlock, 
+         const Binary_expr_block<1, op::Mult,
+                                 Scalar_block<1, T>, T,
+                                 VBlock, std::complex<T> >,
+         Intel_ipp_tag>
+{
+  typedef Binary_expr_block<1, op::Mult,
+			    Scalar_block<1, T>, T,
+			    VBlock, complex<T> >
+	SrcBlock;
+
+  static bool const ct_valid = 
+    !Is_expr_block<VBlock>::value &&
+    simd::Is_algorithm_supported<
+        T,
+        Is_split_block<DstBlock>::value,
+	typename simd::Map_operator_to_algorithm<op::Mult>::type>::value &&
+
+    Type_equal<typename DstBlock::value_type, std::complex<T> >::value &&
+    // check that direct access is supported
+    Ext_data_cost<DstBlock>::value == 0 &&
+    Ext_data_cost<VBlock>::value == 0 &&
+    // Must have same complex interleaved/split format
+    Type_equal<typename Block_layout<DstBlock>::complex_type,
+	       typename Block_layout<VBlock>::complex_type>::value;
+
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    // check if all data is unit stride
+    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+    Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
+    return (ext_dst.stride(0) == 1 && ext_r.stride(0) == 1);
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+    Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
+    simd::rscvmul(src.left().value(), ext_r.data(), ext_dst.data(),
+		  dst.size());
+  }
+};
+
+
+
+// Evaluate complex-view * real-scalar
+
+template <typename DstBlock,
+	  typename T,
+	  typename VBlock>
+struct Serial_expr_evaluator<
+         1, DstBlock, 
+         const Binary_expr_block<1, op::Mult,
+                                 VBlock, std::complex<T>,
+                                 Scalar_block<1, T>, T>,
+         Intel_ipp_tag>
+{
+  typedef Binary_expr_block<1, op::Mult,
+			    VBlock, std::complex<T>,
+			    Scalar_block<1, T>, T>
+	SrcBlock;
+
+  static bool const ct_valid = 
+    !Is_expr_block<VBlock>::value &&
+    simd::Is_algorithm_supported<
+        T,
+        Is_split_block<DstBlock>::value,
+	simd::Map_operator_to_algorithm<op::Mult>::type>::value &&
+
+    Type_equal<typename DstBlock::value_type, std::complex<T> >::value &&
+    // check that direct access is supported
+    Ext_data_cost<DstBlock>::value == 0 &&
+    Ext_data_cost<VBlock>::value == 0 &&
+    // Must have same complex interleaved/split format
+    Type_equal<typename Block_layout<DstBlock>::complex_type,
+	       typename Block_layout<VBlock>::complex_type>::value;
+
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    // check if all data is unit stride
+    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+    Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
+    return (ext_dst.stride(0) == 1 && ext_l.stride(0) == 1);
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+    Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
+    simd::rscvmul(src.right().value(), ext_l.data(), ext_dst.data(),
+		  dst.size());
+  }
+};
+
+
+
+
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/impl/simd/rscvmul.cpp
===================================================================
RCS file: src/vsip/impl/simd/rscvmul.cpp
diff -N src/vsip/impl/simd/rscvmul.cpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/simd/rscvmul.cpp	29 Mar 2006 13:00:26 -0000
@@ -0,0 +1,74 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/simd/rscvmul.cpp
+    @author  Jules Bergmann
+    @date    2006-03-28
+    @brief   VSIPL++ Library: SIMD element-wise vector multiplication.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/simd/rscvmul.hpp>
+
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
+inline void
+rscvmul(
+  T                op1,
+  std::complex<T>* op2,
+  std::complex<T>* res,
+  int size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<T, false, Alg_rscvmul>::value;
+  Simd_rscvmul<std::complex<T>, Is_vectorized>::exec(op1, op2, res, size);
+}
+
+template void rscvmul(float, std::complex<float>*, std::complex<float>*, int);
+template void rscvmul(double, std::complex<double>*,
+		      std::complex<double>*, int);
+
+
+
+template <typename T>
+inline void
+rscvmul(
+  T                op1,
+  std::pair<T*,T*> op2,
+  std::pair<T*,T*> res,
+  int              size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<T, true, Alg_rscvmul>::value;
+  Simd_rscvmul<std::pair<T,T>, Is_vectorized>::exec(op1, op2, res, size);
+}
+
+template void rscvmul(float,
+		   std::pair<float*,float*>,
+		   std::pair<float*,float*>, int);
+template void rscvmul(double,
+		   std::pair<double*,double*>,
+		   std::pair<double*,double*>, int);
+
+#endif
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
Index: src/vsip/impl/simd/rscvmul.hpp
===================================================================
RCS file: src/vsip/impl/simd/rscvmul.hpp
diff -N src/vsip/impl/simd/rscvmul.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/simd/rscvmul.hpp	29 Mar 2006 13:00:26 -0000
@@ -0,0 +1,323 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/simd/rscvmul.hpp
+    @author  Jules Bergmann
+    @date    2006-03-28
+    @brief   VSIPL++ Library: SIMD element-wise vector multiplication.
+
+*/
+
+#ifndef VSIP_IMPL_SIMD_RSCVMUL_HPP
+#define VSIP_IMPL_SIMD_RSCVMUL_HPP
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
+#define VSIP_IMPL_INLINE_LIBSIMD 0
+
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
+// Define value_types for which vmul is optimized.
+//  - complex<float>
+//  - complex<double>
+
+template <typename T,
+	  bool     IsSplit>
+struct Is_algorithm_supported<T, IsSplit, Alg_rscvmul>
+{
+  static bool const value =
+    Simd_traits<T>::is_accel &&
+    (Type_equal<T, float>::value ||
+     Type_equal<T, double>::value);
+};
+
+
+
+// Class for vmul - vector element-wise multiplication.
+
+template <typename T,
+	  bool     Is_vectorized>
+struct Simd_rscvmul;
+
+
+
+// Generic, non-vectorized implementation of vector element-wise multiply.
+
+template <typename T>
+struct Simd_rscvmul<std::complex<T>, false>
+{
+  static void exec(T alpha, std::complex<T>* B, std::complex<T>* R, int n)
+  {
+    while (n)
+    {
+      *R = alpha * *B;
+      R++; B++;
+      n--;
+    }
+  }
+};
+
+
+
+// Vectorized implementation of vector element-wise multiply for
+// interleaved complex (complex<float>, complex<double>, etc).
+
+template <typename T>
+struct Simd_rscvmul<std::complex<T>, true>
+{
+  static void exec(
+    T                alpha,
+    std::complex<T>* B,
+    std::complex<T>* R,
+    int n)
+  {
+    // handle mis-aligned vectors
+    if ((((unsigned long)B) & 0xf) != (((unsigned long)R) & 0xf))
+    {
+      // PROFILE
+      while (n)
+      {
+	*R = alpha * *B;
+	R++; B++;
+	n--;
+      }
+      return;
+    }
+
+    // clean up initial unaligned values
+    while (((unsigned long)B) & 0xf)
+    {
+      *R = alpha * *B;
+      R++; B++;
+      n--;
+    }
+  
+    if (n == 0) return;
+
+    typedef Simd_traits<T> simd;
+    typedef typename simd::simd_type simd_type;
+    
+    simd::enter();
+
+    simd_type regA = simd::load_scalar_all(alpha);
+
+    while (n >= simd::vec_size)
+    {
+      n -= simd::vec_size;
+
+      simd_type regB1 = simd::load((T*)B);
+      simd_type regB2 = simd::load((T*)B + simd::vec_size);
+
+      simd_type regR1 = simd::mul(regA, regB1);
+      simd_type regR2 = simd::mul(regA, regB2);
+      
+      simd::store((T*)R,                  regR1);
+      simd::store((T*)R + simd::vec_size, regR2);
+      
+      B+=simd::vec_size; R+=simd::vec_size;
+    }
+
+    simd::exit();
+
+    while (n)
+    {
+      *R = alpha * *B;
+      R++; B++;
+      n--;
+    }
+  }
+};
+
+
+
+// Generic, non-vectorized implementation of vector element-wise multiply for
+// split complex (as represented by pair<float*, float*>, etc).
+
+template <typename T>
+struct Simd_rscvmul<std::pair<T, T>, false>
+{
+  static void exec(
+    T                        alpha,
+    std::pair<T*, T*> const& B,
+    std::pair<T*, T*> const& R,
+    int n)
+  {
+    T const* pBr = B.first;
+    T const* pBi = B.second;
+
+    T* pRr = R.first;
+    T* pRi = R.second;
+
+    while (n)
+    {
+      *pRr = alpha * *pBr;
+      *pRi = alpha * *pBi;
+      pRr++; pRi++;
+      pBr++; pBi++;
+      n--;
+    }
+  }
+};
+
+
+
+// Vectorized implementation of vector element-wise multiply for
+// split complex (as represented by pair<float*, float*>, etc).
+
+template <typename T>
+struct Simd_rscvmul<std::pair<T, T>, true>
+{
+  static void exec(
+    T                        alpha,
+    std::pair<T*, T*> const& B,
+    std::pair<T*, T*> const& R,
+    int n)
+  {
+    T const* pBr = B.first;
+    T const* pBi = B.second;
+
+    T* pRr = R.first;
+    T* pRi = R.second;
+
+    // handle mis-aligned vectors
+    if ( ((((unsigned long)pRr) & 0xf) != (((unsigned long)pRi) & 0xf)) ||
+	 ((((unsigned long)pRr) & 0xf) != (((unsigned long)pBr) & 0xf)) ||
+	 ((((unsigned long)pRr) & 0xf) != (((unsigned long)pBi) & 0xf)))
+    {
+      // PROFILE
+      while (n)
+      {
+	*pRr = alpha * *pBr;
+	*pRi = alpha * *pBi;
+	pRr++; pRi++;
+	pBr++; pBi++;
+	n--;
+      }
+      return;
+    }
+
+    // clean up initial unaligned values
+    while (((unsigned long)pRr) & 0xf)
+    {
+      *pRr = alpha * *pBr;
+      *pRi = alpha * *pBi;
+      pRr++; pRi++;
+      pBr++; pBi++;
+      n--;
+    }
+  
+    if (n == 0) return;
+
+    typedef Simd_traits<T> simd;
+    typedef typename simd::simd_type simd_type;
+    
+    simd::enter();
+
+    simd_type regA = simd::load_scalar_all(alpha);
+
+    while (n >= simd::vec_size)
+    {
+      n -= simd::vec_size;
+
+      simd_type Br = simd::load((T*)pBr);
+      simd_type Bi = simd::load((T*)pBi);
+      
+      simd_type Rr   = simd::mul(regA, Br);
+      simd_type Ri   = simd::mul(regA, Bi);
+
+      simd::store_stream(pRr, Rr);
+      simd::store_stream(pRi, Ri);
+      
+      pRr += simd::vec_size; pRi += simd::vec_size;
+      pBr += simd::vec_size; pBi += simd::vec_size;
+    }
+
+    simd::exit();
+
+    while (n)
+    {
+      *pRr = alpha * *pBr;
+      *pRi = alpha * *pBi;
+      pRr++; pRi++;
+      pBr++; pBi++;
+      n--;
+    }
+  }
+};
+
+
+
+// Depending on VSIP_IMPL_LIBSIMD_INLINE macro, either provide these
+// functions inline, or provide non-inline functions in the libvsip.a.
+
+#if VSIP_IMPL_INLINE_LIBSIMD
+
+template <typename T>
+inline void
+rscvmul(
+  T                op1,
+  std::complex<T>* op2,
+  std::complex<T>* res,
+  int size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<T, false, Alg_rscvmul>::value;
+  Simd_rscvmul<T, Is_vectorized>::exec(op1, op2, res, size);
+}
+
+template <typename T>
+inline void
+rscvmul(
+  T                op1,
+  std::pair<T*,T*> op2,
+  std::pair<T*,T*> res,
+  int              size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<T, true, Alg_rscvmul>::value;
+  Simd_rscvmul<std::pair<T,T>, Is_vectorized>::exec(op1, op2, res, size);
+}
+
+#else
+
+template <typename T>
+void
+rscvmul(
+  T                op1,
+  std::complex<T>* op2,
+  std::complex<T>* res,
+  int              size);
+
+template <typename T>
+void
+rscvmul(
+  T                op1,
+  std::pair<T*,T*> op2,
+  std::pair<T*,T*> res,
+  int              size);
+
+#endif // VSIP_IMPL_INLINE_LIBSIMD
+
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_SIMD_VMUL_HPP
Index: src/vsip/impl/simd/simd.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/simd/simd.hpp,v
retrieving revision 1.1
diff -u -r1.1 simd.hpp
--- src/vsip/impl/simd/simd.hpp	3 Mar 2006 14:30:53 -0000	1.1
+++ src/vsip/impl/simd/simd.hpp	29 Mar 2006 13:00:26 -0000
@@ -336,6 +336,7 @@
 
 struct Alg_none;
 struct Alg_vmul;
+struct Alg_rscvmul;	// (scalar real * complex vector)
 
 template <typename T,
 	  bool     IsSplit,
Index: src/vsip/impl/simd/vmul.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/simd/vmul.hpp,v
retrieving revision 1.1
diff -u -r1.1 vmul.hpp
--- src/vsip/impl/simd/vmul.hpp	3 Mar 2006 14:30:53 -0000	1.1
+++ src/vsip/impl/simd/vmul.hpp	29 Mar 2006 13:00:26 -0000
@@ -134,8 +134,8 @@
       reg1 = simd::mul(reg0, reg1);
       reg3 = simd::mul(reg2, reg3);
       
-      simd::store_stream(R,                  reg1);
-      simd::store_stream(R + simd::vec_size, reg3);
+      simd::store(R,                  reg1);
+      simd::store(R + simd::vec_size, reg3);
       
       A+=2*simd::vec_size; B+=2*simd::vec_size; R+=2*simd::vec_size;
     }
@@ -221,8 +221,8 @@
       simd_type regR1 = simd::interleaved_lo_from_split(Rr, Ri);
       simd_type regR2 = simd::interleaved_hi_from_split(Rr, Ri);
       
-      simd::store_stream((T*)R,                  regR1);
-      simd::store_stream((T*)R + simd::vec_size, regR2);
+      simd::store((T*)R,                  regR1);
+      simd::store((T*)R + simd::vec_size, regR2);
       
       A+=simd::vec_size; B+=simd::vec_size; R+=simd::vec_size;
     }
@@ -352,8 +352,8 @@
       simd_type AiBr = simd::mul(Ai, Br);
       simd_type Ri   = simd::add(ArBi, AiBr);
 
-      simd::store_stream(pRr, Rr);
-      simd::store_stream(pRi, Ri);
+      simd::store(pRr, Rr);
+      simd::store(pRi, Ri);
       
       pRr += simd::vec_size; pRi += simd::vec_size;
       pAr += simd::vec_size; pAi += simd::vec_size;
