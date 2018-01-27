Index: ChangeLog
===================================================================
--- ChangeLog	(revision 166057)
+++ ChangeLog	(working copy)
@@ -1,5 +1,15 @@
 2007-03-16  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/cbe/ppu/bindings.hpp (VSIP_IMPL_CBE_DMA_GRANULARITY):
+	  New macro, granularity of DMA size in bytes.
+	  (is_dma_size_ok): New funcion, check if DMA size is OK.
+	* src/vsip/opt/cbe/ppu/bindings.cpp: Avoid DMAs with invalid sizes.
+	* tests/regressions/vmul_sizes.cpp: New file, regression test
+	  for range of vmul sizes.
+	* tests/expr-test.cpp: Add library initialization.
+	
+2007-03-16  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/initfin.cpp: Parse vsipl++ options from SVPP_OPT
 	  environment variables.
 	* src/vsip/core/block_copy.hpp: Call loop fusion init/fini
Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 166043)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -202,6 +202,7 @@
   virtual ~Fft_impl()
   {}
 
+  virtual char const* name() { return "fft-cbe-1D-complex"; }
   virtual bool supports_scale() { return true;}
   virtual void in_place(ctype *inout, stride_type stride, length_type length)
   {
@@ -215,6 +216,7 @@
 			    ctype *out, stride_type out_stride,
 			    length_type length)
   {
+    printf("by_reference\n");
     assert(in_stride == 1);
     assert(out_stride == 1);
     this->fft(in, out, length, this->scale_, E);
@@ -259,6 +261,7 @@
   virtual ~Fftm_impl()
   {}
 
+  virtual char const* name() { return "fftm-cbe-1D-complex"; }
   virtual bool supports_scale() { return true;}
   virtual void in_place(ctype *inout,
 			stride_type r_stride, stride_type c_stride,
Index: src/vsip/opt/cbe/ppu/bindings.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/bindings.hpp	(revision 166057)
+++ src/vsip/opt/cbe/ppu/bindings.hpp	(working copy)
@@ -33,6 +33,17 @@
 #include <vsip/core/adjust_layout.hpp>
 
 /***********************************************************************
+  Macros
+***********************************************************************/
+
+// DMA size granularity in bytes (although DMAs of fixed size 1, 2, 4,
+// and 8 bytes are also allowed)
+
+#define VSIP_IMPL_CBE_DMA_GRANULARITY 16
+
+
+
+/***********************************************************************
   Declarations
 ***********************************************************************/
 
@@ -43,6 +54,19 @@
 namespace cbe
 {
 
+// Determine if size in bytes is valid for a Cbe DMA.
+inline bool
+is_dma_size_ok(length_type size_in_bytes)
+{
+  return (size_in_bytes == 1 ||
+	  size_in_bytes == 2 ||
+	  size_in_bytes == 4 ||
+	  size_in_bytes == 8 ||
+	  size_in_bytes % 16 == 0);
+}
+
+
+
 template <typename T> void vmul(T const *A, T const *B, T *R, length_type len);
 
 template <template <typename, typename> class Operator,
Index: src/vsip/opt/cbe/ppu/bindings.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/bindings.cpp	(revision 166043)
+++ src/vsip/opt/cbe/ppu/bindings.cpp	(working copy)
@@ -39,6 +39,8 @@
 {
   length_type const chunk_size = 1024;
 
+  length_type orig_len = len;
+
   Vmul_params params;
   params.length = chunk_size;
   params.a_blk_stride = chunk_size;
@@ -73,16 +75,34 @@
     params.a_ptr += (sizeof(T)/sizeof(float))*my_chunks*chunk_size;
     params.b_ptr += (sizeof(T)/sizeof(float))*my_chunks*chunk_size;
     params.r_ptr += (sizeof(T)/sizeof(float))*my_chunks*chunk_size;
+    len -= chunk_size;
   }
 
-  if (len % chunk_size)
+  // Cleanup leftover data that doesn't fit into a full chunk.
+
+  // First, handle data that can be DMA'd to the SPEs.  DMA granularity
+  // is 16 bytes for sizes 16 bytes or larger.
+
+  length_type const granularity = VSIP_IMPL_CBE_DMA_GRANULARITY / sizeof(T);
+
+  if (len >= granularity)
   {
-    params.length = len % chunk_size;
+    params.length = (len / granularity) * granularity;
+    assert(is_dma_size_ok(params.length*sizeof(T)));
     Workblock block = task.create_multi_block(1);
     block.set_parameters(params);
     task.enqueue(block);
+    len -= params.length;
   }
 
+  // Finally, handle remaining data on the PPE.
+
+  if (len > 0)
+  {
+    for (index_type i=orig_len-len; i<orig_len; ++i)
+      R[i] = A[i] * B[i];
+  }
+
   task.sync();
 }
 
Index: src/vsip/opt/cbe/spu/alf_vmul_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmul_c.c	(revision 166043)
+++ src/vsip/opt/cbe/spu/alf_vmul_c.c	(working copy)
@@ -86,6 +86,11 @@
   float *b = a + length * 2;
   float *c = (float *)output;
 
+  // DMA size is a multiple of 16 bytes:
+  //   assert(length*2*sizeof(float) % 16 == 0);
+  // This is equivalent to:
+  //   assert(length % 2 == 0);
+  // Hence cleanup code is necessary.
 
   // Taken from IBM Cell Arch Workshop, Day Two, Example 3
 
Index: src/vsip/opt/cbe/spu/alf_vmul_s.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmul_s.c	(revision 166043)
+++ src/vsip/opt/cbe/spu/alf_vmul_s.c	(working copy)
@@ -88,24 +88,22 @@
   float *a = (float *)input;
   float *b = a + length;
   float *c = (float *)output;
-  if (length < 4)
-  {
-    while (length--) 
-      *c++ = *a++ * *b++;
-  }
-  else
-  {
-    vector float* A;
-    vector float* B;
-    vector float* C;
-    A = (vector float *) a;
-    B = (vector float *) b;
-    C = (vector float *) c;
 
-    int i;
-    for (i = 0; i < (length / 4); ++i)     // divide by 4 due to simd vector
-      *C++ = spu_mul(*A++, *B++);
-  }
+  // DMA size is a multiple of 16 bytes:
+  //   assert(length*sizeof(float) % 16 == 0);
+  // This is equivalent to:
+  //   assert(length % 8 == 0);
+  
+  vector float* A;
+  vector float* B;
+  vector float* C;
+  A = (vector float *) a;
+  B = (vector float *) b;
+  C = (vector float *) c;
+  
+  int i;
+  for (i = 0; i < (length / 4); ++i)     // divide by 4 due to simd vector
+    *C++ = spu_mul(*A++, *B++);
 
   return 0;
 }
Index: tests/regressions/vmul_sizes.cpp
===================================================================
--- tests/regressions/vmul_sizes.cpp	(revision 0)
+++ tests/regressions/vmul_sizes.cpp	(revision 0)
@@ -0,0 +1,88 @@
+/* Copyright (c) 2007 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/vmul_sizes.cpp
+    @author  Jules Bergmann
+    @date    2007-03-16
+    @brief   VSIPL++ Library: Check that range of vmul sizes are handled.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
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
+template <typename T,
+	  typename ComplexFmt>
+void
+test_vmul(length_type len)
+{
+  typedef impl::Layout<1, row1_type, impl::Stride_unit_dense, ComplexFmt>
+		LP;
+  typedef impl::Fast_block<1, T, LP> block_type;
+
+  Rand<T> gen(0, 0);
+
+  Vector<T, block_type> A(len);
+  Vector<T, block_type> B(len);
+  Vector<T, block_type> Z(len);
+
+  A = gen.randu(len);
+  B = gen.randu(len);
+
+  Z = A * B;
+
+  for (index_type i=0; i<len; ++i)
+  {
+    if (!equal(Z.get(i), A.get(i) * B.get(i)))
+    {
+      std::cout << "Z(" << i << ")        = " << Z(i) << std::endl;
+      std::cout << "A(" << i << ") * B(" << i << ") = "
+		<< A(i) * B(i) << std::endl;
+    }
+    test_assert(almost_equal(Z.get(i), A.get(i) * B.get(i)));
+  }
+}
+
+
+
+
+template <typename T,
+	  typename ComplexFmt>
+void
+test_sweep()
+{
+  for (index_type i=1; i<=128; ++i)
+    test_vmul<T, ComplexFmt>(i);
+}
+
+
+
+
+int
+main(int argc, char** argv)
+{
+  typedef impl::Cmplx_inter_fmt cif;
+  typedef impl::Cmplx_split_fmt csf;
+
+  vsipl init(argc, argv);
+
+  test_sweep<float,          impl::Cmplx_inter_fmt>();
+  test_sweep<complex<float>, impl::Cmplx_inter_fmt>();
+  test_sweep<complex<float>, impl::Cmplx_split_fmt>();
+}
Index: tests/expr-test.cpp
===================================================================
--- tests/expr-test.cpp	(revision 166043)
+++ tests/expr-test.cpp	(working copy)
@@ -17,6 +17,7 @@
 
 #include <iostream>
 
+#include <vsip/initfin.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/math.hpp>
@@ -303,8 +304,10 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsipl init(argc, argv);
+
   test_neg();
   test_expr<float>();
   test_expr<int>();
