Index: ChangeLog
===================================================================
--- ChangeLog	(revision 218277)
+++ ChangeLog	(working copy)
@@ -1,5 +1,27 @@
 2008-08-21  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/ukernel.hpp: Guard iostream include, generalize
+	  align_shift computation for split.
+	* src/vsip/opt/ukernel/cbe_accel/buffer_resource.hpp: Minor
+	  debug changes.
+	* src/vsip/opt/ukernel/cbe_accel/fft_resource.hpp: Undef DEBUG when
+	  done.
+	* src/vsip/opt/ukernel/kernels/cbe_accel/zvmmul_f.cpp: New file,
+	  split-complex vmmul.
+	* src/vsip/opt/ukernel/kernels/cbe_accel/zvmmul_f.hpp: New file,
+	  split-complex vmmul.
+	* src/vsip/opt/ukernel/kernels/cbe_accel/zfconv_f.cpp: New file,
+	  split-complex fast convolution.
+	* src/vsip/opt/ukernel/kernels/cbe_accel/zfft_f.hpp: Use Fft/Buffer
+	  resources.
+	* src/vsip/opt/ukernel/kernels/host/fconv.hpp: Add split kernel
+	  lookup.
+	* tests/ukernel/fft.cpp: Avoid large FFT when split.  CML needs
+	  to implement split out-of-place, modify input FFT.
+	* tests/ukernel/fconv.cpp: Minor debug changes.
+
+2008-08-21  Jules Bergmann  <jules@codesourcery.com>
+
 	* tests/fft_be.cpp: Add XFails for cbe double FFTMs.
 
 2008-08-20  Mike LeBlanc  <mike@codesourcery.com>
Index: src/vsip/opt/ukernel.hpp
===================================================================
--- src/vsip/opt/ukernel.hpp	(revision 218238)
+++ src/vsip/opt/ukernel.hpp	(working copy)
@@ -20,7 +20,9 @@
 #define DEBUG             0
 #define DEBUG_SPATT_EXTRA 1
 
-#include <iostream>
+#if DEBUG_SPATT_EXTRA
+#  include <iostream>
+#endif
 #include <vsip/opt/cbe/ppu/util.hpp>
 #include <vsip/opt/cbe/ppu/task_manager.hpp>
 #include <vsip/opt/ukernel/ukernel_params.hpp>
@@ -32,8 +34,6 @@
 ***********************************************************************/
 
 #define VSIP_IMPL_DMA_SIZE_QUANTUM 16
-#define VSIP_IMPL_DMA_SIZE_IN_FLOATS \
-  (VSIP_IMPL_DMA_SIZE_QUANTUM / sizeof(float))
 
 // Increase to DMA size, in terms of elementsize ES.
 #define VSIP_IMPL_INCREASE_TO_DMA_SIZE(S, ES)		\
@@ -413,7 +413,23 @@
 };
 
 
+template <typename T>
+int
+find_align_shift(T* addr)
+{
+  return ((unsigned)(addr) % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(T);
+}
 
+template <typename T>
+int
+find_align_shift(std::pair<T*, T*> const& addr)
+{
+  assert( ((unsigned)(addr.first)  % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(T) ==
+	  ((unsigned)(addr.second) % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(T));
+  return ((unsigned)(addr.first) % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(T);
+}
+
+
 template <typename ViewT>
 struct Ps_helper<ViewT, 1>
 {
@@ -437,7 +453,7 @@
 
   void fill(Uk_stream& stream, length_type spes)
   {
-    stream.align_shift = ((unsigned)(addr_) % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(float);
+    stream.align_shift = find_align_shift(addr_);
     total_size_  = ext_.size(0);
     if (spatt_.sdist0_.num_chunks_ != 0)
     {
@@ -475,7 +491,7 @@
 
     chunk_index_       = 0;
 
-    stream.addr              = cbe::ea_from_ptr(addr_);
+    Set_addr<ptr_type>::set(stream, addr_);
     stream.dim               = 1;
     stream.num_chunks0       = 1;
     stream.num_chunks1       = num_chunks_;
@@ -801,7 +817,6 @@
 } // namespace vsip
 
 #undef VSIP_IMPL_DMA_SIZE_QUANTUM
-#undef VSIP_IMPL_DMA_SIZE_IN_FLOATS
 #undef VSIP_IMPL_INCREASE_TO_DMA_SIZE
 
 #endif // VSIP_OPT_UKERNEL_UKERNEL_HPP
Index: src/vsip/opt/ukernel/cbe_accel/buffer_resource.hpp
===================================================================
--- src/vsip/opt/ukernel/cbe_accel/buffer_resource.hpp	(revision 218238)
+++ src/vsip/opt/ukernel/cbe_accel/buffer_resource.hpp	(working copy)
@@ -45,13 +45,13 @@
   {
     char* buf = (char*)b - PAD/2;
 #if DEBUG
-    printf("destroy_buffer -- start %x\n", buf);
+    printf("Buffer_resource::destroy -- start %x\n", buf);
 #endif
 
-    int size = ((int*)buf)[0];
 
 #if PAD_CHECK
     // Check beginning and end of allocated buffer for corruption.
+    int size = ((int*)buf)[0];
     for (int i=1; i<4; ++i)
       assert(((int*)buf)[i] == (0xbeef0000 | i));
     for (int i=0; i<4; ++i)
@@ -61,7 +61,7 @@
 
     free(buf);
 #if DEBUG
-    printf("destroy_buffer -- done\n");
+    printf("Buffer_resource::destroy -- done\n");
 #endif
   }
 
@@ -84,19 +84,19 @@
       size_t buf_size = CML_INCREASE_TO_SIMD_ALIGNMENT(size) + PAD;
       buf_ = (char*)memalign(16, buf_size);
 #if DEBUG
-      printf("size: %d  %x\n", buf_size, buf_);
+      printf("Buffer_resource::init -- size %d  addr %x\n", buf_size, buf_);
 #endif
       assert(buf_ != NULL);
 
+#if PAD_CHECK
       ((int*)buf_)[0] = size;
-#if PAD_CHECK
       // Mark beginning and end of allocated buffer.
       for (int i=1; i<4; ++i)
 	((int*)buf_)[i] = (0xbeef0000 | i);
       for (int i=0; i<4; ++i)
 	((int*)buf_ + 4 + CML_INCREASE_TO_SIMD_ALIGNMENT(size)/4)[i] = (0xbaef0000 | i);
 
-      buf_ += 16;
+      buf_ += PAD/2;
 #endif
 
       rman.set_resource(buf_idx_, (void*)buf_, &destroy_buffer);
Index: src/vsip/opt/ukernel/cbe_accel/fft_resource.hpp
===================================================================
--- src/vsip/opt/ukernel/cbe_accel/fft_resource.hpp	(revision 218238)
+++ src/vsip/opt/ukernel/cbe_accel/fft_resource.hpp	(working copy)
@@ -82,4 +82,6 @@
   char*    buf_;
 };
 
+#undef DEBUG
+
 #endif // VSIP_OPT_UKERNEL_CBE_ACCEL_FFT_RESOURCE_HPP
Index: src/vsip/opt/ukernel/kernels/cbe_accel/zvmmul_f.cpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/zvmmul_f.cpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/zvmmul_f.cpp	(revision 0)
@@ -0,0 +1,21 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/zvmmul_f.cpp
+    @author  Jules Bergmann
+    @date    2008-08-20
+    @brief   VSIPL++ Library: Elementwise vector-matrix multiply ukernel.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/ukernel/kernels/cbe_accel/zvmmul_f.hpp>
+
+typedef Zvmmul_kernel kernel_type;
+
+#include <vsip/opt/ukernel/cbe_accel/alf_base.hpp>
Index: src/vsip/opt/ukernel/kernels/cbe_accel/zvmmul_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/zvmmul_f.hpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/zvmmul_f.hpp	(revision 0)
@@ -0,0 +1,90 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/zvmmul_f.hpp
+    @author  Jules Bergmann
+    @date    2008-08-20
+    @brief   VSIPL++ Library: Split-complex vector-matrix multiply UKernel.
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
+#include <vsip/opt/ukernel/cbe_accel/ukernel.hpp>
+#include <vsip/opt/ukernel/cbe_accel/buffer_resource.hpp>
+#include <vsip/opt/ukernel/kernels/params/vmmul_param.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+struct Zvmmul_kernel : Spu_kernel
+{
+  typedef std::pair<float*, float*> in0_type;
+  typedef std::pair<float*, float*> in1_type;
+  typedef std::pair<float*, float*> out0_type;
+
+  static unsigned int const pre_argc = 1;
+  static unsigned int const in_argc  = 1;
+  static unsigned int const out_argc = 1;
+  typedef Uk_vmmul_params param_type;
+
+  static bool const in_place = true;
+
+  void reserve(Resource_manager& rman, param_type& params)
+  {
+    buffer_resource_.reserve(rman, rid_vmmul_buffer, params.size);
+  }
+
+  void init(Resource_manager& rman, param_type& params)
+  {
+    buffer_resource_.init(rman, 2*params.size*sizeof(float));
+  }
+
+  void pre_compute(
+    in0_type     in0,
+    Pinfo const& p_in0)
+  {
+    float const* r = (float const*)buffer_resource_.buffer();
+    float const* i = (float const*)buffer_resource_.buffer() + p_in0.l_total_size;
+    cml_core_vcopy1_f((float const*)in0.first,
+		      (float*)buffer_resource_.buffer(),
+		      p_in0.l_total_size);
+    cml_core_vcopy1_f((float const*)in0.second,
+		      (float*)buffer_resource_.buffer() + p_in0.l_total_size,
+		      p_in0.l_total_size);
+  }
+
+  void compute(
+    in1_type     in1,
+    out0_type    out,
+    Pinfo const& p_in1,
+    Pinfo const& p_out)
+  {
+    cml_zvmul1_f((float const*)buffer_resource_.buffer(),
+		 (float const*)buffer_resource_.buffer() + p_out.l_total_size,
+		 (float const*)in1.first, (float const*)in1.second,
+		 (float*)out.first, (float*)out.second,
+		 p_out.l_total_size);
+  }
+
+  void fini(Resource_manager& rman)
+  {
+    buffer_resource_.fini(rman);
+  }
+
+// Member data
+  Buffer_resource buffer_resource_;
+};
Index: src/vsip/opt/ukernel/kernels/cbe_accel/zfconv_f.cpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/zfconv_f.cpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/zfconv_f.cpp	(revision 0)
@@ -0,0 +1,26 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/zfconv_f.hpp
+    @author  Jules Bergmann
+    @date    2008-08-21
+    @brief   VSIPL++ Library: Inter-complex fastconv ukernel.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/ukernel/kernels/params/fused_param.hpp>
+
+#include <vsip/opt/ukernel/kernels/cbe_accel/fused_kernel.hpp>
+#include <vsip/opt/ukernel/kernels/cbe_accel/zfft_f.hpp>
+#include <vsip/opt/ukernel/kernels/cbe_accel/zvmmul_f.hpp>
+
+typedef Fused_kernel<Fft_kernel, Zvmmul_kernel, Fft_kernel>
+	kernel_type;
+
+#include <vsip/opt/ukernel/cbe_accel/alf_base.hpp>
Index: src/vsip/opt/ukernel/kernels/cbe_accel/zfft_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/zfft_f.hpp	(revision 218238)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/zfft_f.hpp	(working copy)
@@ -19,6 +19,8 @@
 #include <cml/spu/cml.h>
 #include <cml/spu/cml_core.h>
 #include <vsip/opt/ukernel/cbe_accel/ukernel.hpp>
+#include <vsip/opt/ukernel/cbe_accel/fft_resource.hpp>
+#include <vsip/opt/ukernel/cbe_accel/buffer_resource.hpp>
 #include <vsip/opt/ukernel/kernels/params/fft_param.hpp>
 
 #define MIN_FFT_1D_SIZE	  32
@@ -40,32 +42,22 @@
   typedef Uk_fft_params param_type;
 
   Fft_kernel()
-    : current_size(0)
   {}
 
-  void init(Resource_manager&, param_type& params)
+  void reserve(Resource_manager& rman, param_type& params)
   {
-    size_t size = params.size;
-    printf("init: %d\n", size);
-    assert(size >= MIN_FFT_1D_SIZE);
-    assert(size <= MAX_FFT_1D_SIZE);
+    fft_resource_.reserve(rman, params.size);
+    buf_resource_.reserve(rman, rid_fft_buffer, 2*params.size*sizeof(float));
+  }
 
-    if (size != current_size)
-    {
-      if (obj)
-      {
-	free(buf);
-	cml_fft1d_destroy_f_alloc(obj);
-      }
-      int rt = cml_fft1d_setup_f_alloc(&obj, CML_FFT_CC, size);
-      assert(rt && obj != NULL);
-      buf = (char*)memalign(16, cml_zzfft1d_buf_size_f(obj));
-      assert(buf != NULL);
-      current_size = size;
-    }
+  void init(Resource_manager& rman, param_type& params)
+  {
+    fft_resource_.init(rman, params.size);
+    buf_resource_.init(rman, 2*params.size*sizeof(float));
 
-    // dir = ukp->direction == fwd_fft ? CML_FFT_FWD : CML_FFT_INV;
-    dir = CML_FFT_FWD;
+    size  = params.size;
+    dir   = params.dir;
+    scale = params.scale;
   }
 
   void compute(
@@ -74,27 +66,25 @@
     Pinfo const&     p_in,
     Pinfo const&     p_out)
   {
-    printf("compute:\n");
-    cml_zzfft1d_op_f(obj,
+    cml_zzfft1d_op_f(fft_resource_.fft(),
 		     in.first, in.second,
 		     out.first, out.second,
-		     dir, buf);
+		     dir, (float*)buf_resource_.buffer());
 
-    float scale = 1.f; // ukp->scale
     if (scale != 1.f)
       cml_core_rzsvmul1_f(scale, out.first, out.second,
-			  out.first, out.second, current_size);
+			  out.first, out.second, size);
   }
 
-  void fini(Resource_manager&)
+  void fini(Resource_manager& rman)
   {
-    printf("uk_zzfft_f: fini:\n");
+    fft_resource_.fini(rman);
+    buf_resource_.fini(rman);
   }
 
-  fft1d_f* obj;
-  char*    buf;
-  size_t   current_size;
-  int      dir;
+  Fft_resource    fft_resource_;
+  Buffer_resource buf_resource_;
+  size_t          size;
+  int             dir;
+  float           scale;
 };
-
-typedef Fft_kernel kernel_type;
Index: src/vsip/opt/ukernel/kernels/host/fconv.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/host/fconv.hpp	(revision 218238)
+++ src/vsip/opt/ukernel/kernels/host/fconv.hpp	(working copy)
@@ -105,6 +105,14 @@
   vsip::impl::ukernel::Stream_pattern io_sp;	
 };
 
-DEFINE_UKERNEL_TASK(Fconv_kernel, void(std::complex<float>*, std::complex<float>*, std::complex<float>*), cfconv_f)
+DEFINE_UKERNEL_TASK(Fconv_kernel,
+		    void(std::complex<float>*, std::complex<float>*,
+			 std::complex<float>*),
+		    cfconv_f)
 
+DEFINE_UKERNEL_TASK(Fconv_kernel,
+		    void(std::pair<float*,float*>, std::pair<float*,float*>,
+			 std::pair<float*,float*>),
+		    zfconv_f)
+
 #endif // VSIP_TESTS_HOST_UK_FCONV_HPP
Index: tests/ukernel/fft.cpp
===================================================================
--- tests/ukernel/fft.cpp	(revision 218238)
+++ tests/ukernel/fft.cpp	(working copy)
@@ -1,9 +1,9 @@
 /* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
 
-/** @file    tests/x-ukernel.cpp
+/** @file    tests/ukernel/fft.cpp
     @author  Jules Bergmann
     @date    2008-06-10
-    @brief   VSIPL++ Library: Test Ukernel
+    @brief   VSIPL++ Library: Test Fft Ukernel
 */
 
 /***********************************************************************
@@ -66,12 +66,16 @@
 {
   vsipl init(argc, argv);
 
-  test_ukernel<complex<float> >(32, 4096);
+  bool do_large = !VSIP_IMPL_PREFER_SPLIT_COMPLEX;
+
+  if (do_large)
+    test_ukernel<complex<float> >(32, 4096);
   test_ukernel<complex<float> >(32, 2048);
 
   for (index_type i=0; i<100; ++i)
   {
-    test_ukernel<complex<float> >(32, 4096);
+    if (do_large)
+      test_ukernel<complex<float> >(32, 4096);
     test_ukernel<complex<float> >(32, 2048);
     test_ukernel<complex<float> >(32, 1024);
   }
Index: tests/ukernel/fconv.cpp
===================================================================
--- tests/ukernel/fconv.cpp	(revision 218238)
+++ tests/ukernel/fconv.cpp	(working copy)
@@ -1,6 +1,6 @@
 /* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
 
-/** @file    tests/x-uk-fconv.cpp
+/** @file    tests/ukernel/fconv.cpp
     @author  Jules Bergmann
     @date    2008-07-23
     @brief   VSIPL++ Library: Test Fastconv Ukernel
@@ -34,7 +34,7 @@
 
 template <typename T>
 void
-test_ukernel(length_type rows, length_type cols, float scale)
+test_ukernel(length_type rows, length_type cols, float scale, int tc)
 {
   Fconv_kernel obj(cols);
 
@@ -47,9 +47,18 @@
   Rand<T> gen(0, 0);
 
   in0 = T(scale);
-  in1 = gen.randu(rows, cols);
 
-  in1.row(0)(Domain<1>(16)) = ramp<T>(0, 0.1, 16);
+  switch(tc)
+  {
+  case 0:
+    in1 = gen.randu(rows, cols);
+    in1.row(0)(Domain<1>(16)) = ramp<T>(0, 0.1, 16);
+    break;
+  case 1:
+    for (index_type r=0; r<rows; ++r)
+      in1.row(r) = ramp<T>(r, 0.1, cols);
+    break;
+  }
 
   uk(in0, in1, out);
 
@@ -73,16 +82,17 @@
 {
   vsipl init(argc, argv);
 
-  // test_ukernel<float>();
+  int tc = 0;
+
   for (index_type i=0; i<100; ++i)
   {
-    test_ukernel<complex<float> >(4, 2048, 0.5);
-    test_ukernel<complex<float> >(4, 1024, 1.0);
-    test_ukernel<complex<float> >(4,  512, 1.5);
-    test_ukernel<complex<float> >(4,  512, 3.5);
-    test_ukernel<complex<float> >(4, 1024, 2.5);
+    test_ukernel<complex<float> >(4, 2048, 0.5, tc);
+    test_ukernel<complex<float> >(4, 1024, 1.0, tc);
+    test_ukernel<complex<float> >(4,  512, 1.5, tc);
+    test_ukernel<complex<float> >(4,  512, 3.5, tc);
+    test_ukernel<complex<float> >(4, 1024, 2.5, tc);
+    test_ukernel<complex<float> >(4,  256, 4.5, tc);
   }
-  // test_ukernel<complex<float> >(128, 2048, 1.5);
 
   return 0;
 }
