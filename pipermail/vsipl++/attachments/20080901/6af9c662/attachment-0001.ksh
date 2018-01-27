Index: src/vsip/opt/ukernel/cbe_accel/alf_base.hpp
===================================================================
--- src/vsip/opt/ukernel/cbe_accel/alf_base.hpp	(revision 219699)
+++ src/vsip/opt/ukernel/cbe_accel/alf_base.hpp	(working copy)
@@ -14,7 +14,9 @@
   Included Files
 ***********************************************************************/
 
+#ifndef DEBUG
 #define DEBUG 0
+#endif
 
 #include <utility>
 #include <cassert>
@@ -91,21 +93,46 @@
 
 
 // Helper functor, converts void buffer pointer to appropriate type.
+//
+// The 'off' parameter is a byte offset, while 'size' is in elements.
+// This is necessary because the first is calculated from the amount
+// data previously allocated, which may or may not have the same data
+// type.  Conversely, the second parameter refers to the amount of
+// data for the current segment and it is therefore easier to use
+// pointer arithmetic since the type is known.
 
 template <typename T>
 struct To_ptr
 {
-  static T offset(void* data, size_t off, size_t) { return (T)data + off; }
+  static T offset(void* data, size_t off, size_t) 
+    { return (T)((size_t)data + off); }
 };
 
 template <typename T>
 struct To_ptr<std::pair<T*, T*> >
 {
   static std::pair<T*, T*> offset(void* data, size_t off, size_t size)
-  { return std::pair<T*, T*>((T*)data + 2*off, (T*)data + 2*off + size); }
+    { return std::pair<T*, T*>((T*)((size_t)data + off), (T*)((size_t)data + off) + size); }
 };
 
+
+// Converts a size in number of elements (or index value) into an offset 
+// based on the type referenced by the pointer.
+
 template <typename PtrT>
+struct Byte_offset
+{
+  static size_t index(size_t size) { return (size_t)((PtrT)0 + size); }
+};
+
+template <typename T>
+struct Byte_offset<std::pair<T*, T*> >
+{
+  static size_t index(size_t size) { return (size_t)((T*)0 + size) * 2; }
+};
+
+
+template <typename PtrT>
 void
 add_stream(
   void*        entries,
@@ -166,19 +193,25 @@
 
   line_size = INCREASE_TO_DMA_SIZE_IN_FLOATS(line_size);
 
+#if DEBUG
+  char ptype = 
+    Type_equal<PtrT, float*>::value ? 'S' :
+      Type_equal<PtrT, std::complex<float>*>::value ? 'C' :
+        Type_equal<PtrT, std::pair<float*, float*> >::value ? 'Z' :
+          Type_equal<PtrT, unsigned int*>::value ? 'I' :
+            '?';
+  printf("add_stream: type: %c  chunk: %d (%d/%d, %d/%d)  size: %d/%d x %d/%d  stride: %d, %d\n",
+    ptype, chunk_idx,
+    chunk_idx0, stream.num_chunks0,
+    chunk_idx1, stream.num_chunks1, 
+    stream.chunk_size0, num_lines, stream.chunk_size1, line_size,
+    stream.stride0, stream.stride1);
+#endif
+
   if (Type_equal<PtrT, float*>::value)
   {
     ea = stream.addr + offset;
 
-#if DEBUG
-    printf("add_stream: chunk: %d (%d/%d, %d/%d) %llx size: %d/%d x %d/%d  str: %d, %d\n",
-	   chunk_idx,
-	   chunk_idx0, stream.num_chunks0,
-	   chunk_idx1, stream.num_chunks1, ea,
-	   stream.chunk_size0, num_lines, stream.chunk_size1, line_size,
-	   stream.stride0, stream.stride1);
-#endif
-
     for (int i=0; i<num_lines; ++i)
     {
       alf_data_addr64_t eax = ea + i*stream.stride0 * sizeof(float);
@@ -421,10 +454,12 @@
     set_chunk_info(ukp->in_stream[1],  p_in1, iter);
     set_chunk_info(ukp->out_stream[0], p_out, iter);
 
+    size_t offset1 = Byte_offset<in0_type>::index(p_in0.l_total_size);
+
     ukobj.compute(
-      To_ptr<in0_type >::offset(in,  0,                  p_in0.l_total_size),
-      To_ptr<in1_type >::offset(in,  p_in0.l_total_size, p_in1.l_total_size),
-      To_ptr<out0_type>::offset(out, 0,                  p_out.l_total_size),
+      To_ptr<in0_type >::offset(in,  0,       p_in0.l_total_size),
+      To_ptr<in1_type >::offset(in,  offset1, p_in1.l_total_size),
+      To_ptr<out0_type>::offset(out, 0,       p_out.l_total_size),
       p_in0, p_in1, p_out);
   }
 };
@@ -540,9 +575,8 @@
     // Pointers must be extracted from knowledge of the stream sizes as ALF
     // transfers all the input data into one contiguous space.
 
-    size_t offset1 = p_in0.l_total_size;
-    size_t offset2 = offset1 + p_in1.l_total_size;
-    size_t offset3 = offset2 + p_in2.l_total_size;
+    size_t offset1 = Byte_offset<in0_type>::index(p_in0.l_total_size);
+    size_t offset2 = offset1 + Byte_offset<in1_type>::index(p_in1.l_total_size);
 
     // The To_ptr<> struct calculates the correct offset for a given
     // pointer type (scalar, interleaved complex or split complex).  The 
Index: src/vsip/opt/ukernel/kernels/cbe_accel/scmadd_f.cpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/scmadd_f.cpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/scmadd_f.cpp	(revision 0)
@@ -0,0 +1,21 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/scmadd_f.hpp
+    @author  Don McCoy
+    @date    2008-08-26
+    @brief   VSIPL++ Library: User-defined kernel for multiply-add.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/ukernel/kernels/cbe_accel/scmadd_f.hpp>
+
+typedef Scmadd_kernel kernel_type;
+
+#include <vsip/opt/ukernel/cbe_accel/alf_base.hpp>
Index: src/vsip/opt/ukernel/kernels/cbe_accel/scmadd_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/scmadd_f.hpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/scmadd_f.hpp	(revision 0)
@@ -0,0 +1,78 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/scmadd_f.hpp
+    @author  Don McCoy
+    @date    2008-08-26
+    @brief   VSIPL++ Library: User-defined kernel for multiply-add.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <utility>
+#include <complex>
+
+#include <cml/spu/cml.h>
+#include <cml/spu/cml_core.h>
+
+#include <vsip/opt/ukernel/cbe_accel/debug.hpp>
+#include <vsip/opt/ukernel/cbe_accel/ukernel.hpp>
+
+#define DEBUG 0
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+struct Scmadd_kernel : Spu_kernel
+{
+  typedef float*               in0_type;
+  typedef std::complex<float>* in1_type;
+  typedef std::complex<float>* in2_type;
+  typedef std::complex<float>* out0_type;
+
+  static unsigned int const in_argc  = 3;
+  static unsigned int const out_argc = 1;
+
+  static bool const in_place = true;
+
+  void compute(
+    in0_type     in0,
+    in1_type     in1,
+    in2_type     in2,
+    out0_type    out,
+    Pinfo const& p_in0,
+    Pinfo const& p_in1,
+    Pinfo const& p_in2,
+    Pinfo const& p_out)
+  {
+#if DEBUG
+    cbe_debug_dump_pinfo("p_in0", p_in0);
+    cbe_debug_dump_pinfo("p_in1", p_in1);
+    cbe_debug_dump_pinfo("p_in2", p_in2);
+    cbe_debug_dump_pinfo("p_out", p_out);
+#endif
+
+    size_t size0 = p_in0.l_size[0];
+    size_t size1 = p_in0.l_size[1];
+    size_t stride = p_in0.l_stride[0];
+
+    for (int i = 0; i < size0; ++i)
+    {
+      in0_type pi0 = &in0[i * stride];
+      in1_type pi1 = &in1[i * stride];
+      in2_type pi2 = &in2[i * stride];
+      out0_type po = &out[i * stride];
+   
+      for (int j = 0; j < size1; ++j)
+        po[j] = pi0[j] * pi1[j] + pi2[j];
+    }
+  }
+
+};
Index: src/vsip/opt/ukernel/kernels/host/madd.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/host/madd.hpp	(revision 219699)
+++ src/vsip/opt/ukernel/kernels/host/madd.hpp	(working copy)
@@ -92,4 +92,10 @@
     std::complex<float>*),
   cmadd_f)
 
+DEFINE_UKERNEL_TASK(
+  Madd_kernel,
+  void(float*, std::complex<float>*, std::complex<float>*, 
+    std::complex<float>*),
+  scmadd_f)
+
 #endif // VSIP_SRC_OPT_UKERNEL_KERNELS_HOST_MADD_HPP
Index: tests/ukernel/madd.cpp
===================================================================
--- tests/ukernel/madd.cpp	(revision 219699)
+++ tests/ukernel/madd.cpp	(working copy)
@@ -30,7 +30,12 @@
   Definitions
 ***********************************************************************/
 
-template <typename T>
+// Performs a elementwise multiply-add for the expression
+//   Z = A * B + C
+// where T1 is the type of A and T2 is the type for B, C and D
+//
+template <typename T1,
+          typename T2>
 void
 test_ukernel(length_type rows, length_type cols)
 {
@@ -38,23 +43,25 @@
 
   vsip_csl::ukernel::Ukernel<Madd_kernel> madd_uk(obj);
 
-  Matrix<T> in0(rows, cols);
-  Matrix<T> in1(rows, cols);
-  Matrix<T> in2(rows, cols);
-  Matrix<T> out(rows, cols);
+  Matrix<T1> in0(rows, cols);
+  Matrix<T2> in1(rows, cols);
+  Matrix<T2> in2(rows, cols);
+  Matrix<T2> out(rows, cols);
 
-  Rand<T> gen(0, 0);
-  in0 = gen.randu(rows, cols);
-  in1 = gen.randu(rows, cols);
-  in2 = gen.randu(rows, cols);
+  Rand<T1> gen1(0, 0);
+  in0 = gen1.randu(rows, cols);
 
+  Rand<T2> gen2(1, 0);
+  in1 = gen2.randu(rows, cols);
+  in2 = gen2.randu(rows, cols);
+
   madd_uk(in0, in1, in2, out);
 
 
   for (index_type i=0; i < rows; ++i)
     for (index_type j=0; j < cols; ++j)
     {
-      T madd = in0.get(i, j) * in1.get(i, j) + in2.get(i, j);
+      T2 madd = in0.get(i, j) * in1.get(i, j) + in2.get(i, j);
       if (!equal(madd, out.get(i, j)))
       {
         std::cout << "index " << i << ", " << j << " : "
@@ -82,8 +89,10 @@
 {
   vsipl init(argc, argv);
 
-  test_ukernel<float>(64, 1024);
-  test_ukernel<complex<float> >(64, 1024);
+  // Parameters are rows then cols
+  test_ukernel<float, float>(64, 1024);
+  test_ukernel<float, complex<float> >(64, 1024);
+  test_ukernel<complex<float>, complex<float> >(64, 1024);
 
   return 0;
 }
