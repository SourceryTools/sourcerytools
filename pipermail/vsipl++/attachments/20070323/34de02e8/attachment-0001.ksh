Index: src/vsip/opt/cbe/ppu/fastconv.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.cpp	(revision 166685)
+++ src/vsip/opt/cbe/ppu/fastconv.cpp	(working copy)
@@ -59,10 +59,10 @@
     (this->twiddle_factors_.get());
 
   length_type psize = sizeof(params);
-  // The stack size is determined by multiplying the maximum convolution
-  // size by 4:  2 to support double-buffering and 2 to account for 
-  // separate input and output buffers.
-  length_type stack_size = 4096 + 4*sizeof(T)*MAX_FCONV_SIZE;
+  // The stack size takes into account two temporary buffers used
+  // to hold the real and imaginary parts of the complex input data.
+  length_type stack_size = 4096 + 
+    2*sizeof(T)*cbe::Fastconv_traits<T, complex_type>::max_size;
   Task_manager *mgr = Task_manager::instance();
   Task task = mgr->reserve<Fastconv_tag, void(T,T)>
     (stack_size, psize, sizeof(T)*length, sizeof(T)*length, true);
@@ -118,10 +118,11 @@
     (this->twiddle_factors_.get());
 
   length_type psize = sizeof(params);
-  // The stack size is determined by multiplying the maximum convolution
-  // size by 4:  2 to support double-buffering and 2 to account for 
-  // separate input and output buffers.
-  length_type stack_size = 4096 + 4*sizeof(T)*MAX_FCONV_SIZE;
+  // The split complex version has a smaller stack size requirement,
+  // but experimentation indicates that performance is hurt by 
+  // reducing this value.
+  length_type stack_size = 4096 + 
+    sizeof(T)*cbe::Fastconv_traits<T, complex_type>::max_size;
   Task_manager *mgr = Task_manager::instance();
   Task task = mgr->reserve<Fastconv_tag, void(std::pair<uT*,uT*>,
 					      std::pair<uT*,uT*>)>
Index: src/vsip/opt/cbe/ppu/fastconv.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.hpp	(revision 166685)
+++ src/vsip/opt/cbe/ppu/fastconv.hpp	(working copy)
@@ -20,6 +20,7 @@
 #include <vsip/core/allocation.hpp>
 #include <vsip/core/config.hpp>
 #include <vsip/core/extdata.hpp>
+#include <vsip/opt/cbe/common.h>
 #include <vsip/opt/cbe/ppu/bindings.hpp>
 #include <vsip/opt/cbe/ppu/task_manager.hpp>
 extern "C"
@@ -41,14 +42,14 @@
 template <>
 struct Fastconv_traits<std::complex<float>, Cmplx_inter_fmt>
 {
-  static length_type const min_size = 32;
-  static length_type const max_size = 2048;
+  static length_type const min_size = VSIP_IMPL_MIN_FCONV_SIZE;
+  static length_type const max_size = VSIP_IMPL_MAX_FCONV_SIZE;
 };
 template <>
 struct Fastconv_traits<std::complex<float>, Cmplx_split_fmt>
 {
-  static length_type const min_size = 64;
-  static length_type const max_size = 2048;
+  static length_type const min_size = VSIP_IMPL_MIN_FCONV_SPLIT_SIZE;
+  static length_type const max_size = VSIP_IMPL_MAX_FCONV_SPLIT_SIZE;
 };
 
 // Fast convolution object using SPEs to perform computation.
Index: src/vsip/opt/cbe/spu/alf_fconv_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconv_c.c	(revision 166685)
+++ src/vsip/opt/cbe/spu/alf_fconv_c.c	(working copy)
@@ -13,15 +13,19 @@
 #include <sys/time.h>
 #include <spu_mfcio.h>
 #include <alf_accel.h>
-#include <assert.h>
 #include <vsip/opt/cbe/common.h>
 #include "fft_1d_r2.h"
+#include "spe_assert.h"
 
-// These are sized for complex values, taking two floats each.  The twiddle 
-// factors occupy only 1/4 the space as the inputs, outputs and convolution 
-// kernels.
-static volatile float kernel[MAX_FCONV_SIZE*2] __attribute__ ((aligned (128)));
-static volatile float twiddle_factors[MAX_FCONV_SIZE*2/4] __attribute__ ((aligned (128)));
+// These are sized for complex values, taking two floats each.  
+static float kernel[2 * VSIP_IMPL_MAX_FCONV_SIZE] 
+       __attribute__ ((aligned (128)));
+
+// The twiddle factors occupy only 1/4 the space as the inputs, 
+// outputs and convolution kernels.
+static float twiddle_factors[2 * VSIP_IMPL_MAX_FCONV_SIZE / 4] 
+       __attribute__ ((aligned (128)));
+
 static unsigned int instance_id = 0;
 
 #define VEC_SIZE  (4)
@@ -78,6 +82,7 @@
   unsigned int const FP = 2; // Complex data: 2 floats per point.
 
   Fastconv_params* fc = (Fastconv_params *)params;
+  spe_assert(fc->elements * FP *sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
   addr64 ea;
 
   // Transfer input.
@@ -104,6 +109,7 @@
   unsigned int const FP = 2; // Complex data: 2 floats per point.
 
   Fastconv_params* fc = (Fastconv_params *)params;
+  spe_assert(fc->elements * FP *sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
   addr64 ea;
 
   // Transfer output.
@@ -130,7 +136,7 @@
   Fastconv_params* fc = (Fastconv_params *)params;
   unsigned int n = fc->elements;
   unsigned int log2n = log2i(n);
-  assert(n <= MAX_FCONV_SIZE);
+  spe_assert(n <= VSIP_IMPL_MAX_FCONV_SIZE);
 
   // Initialization establishes the weights (kernel) for the
   // convolution step and the twiddle factors for the FFTs.
Index: src/vsip/opt/cbe/spu/alf_fconv_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconv_split_c.c	(revision 166685)
+++ src/vsip/opt/cbe/spu/alf_fconv_split_c.c	(working copy)
@@ -20,12 +20,12 @@
 #include <sys/time.h>
 #include <spu_mfcio.h>
 #include <alf_accel.h>
-#include <assert.h>
 
 #include <vsip/opt/cbe/common.h>
 
 #include "fft_1d_r2_split.h"
 #include "vmul_split.h"
+#include "spe_assert.h"
 
 #if PERFMON
 #  include "timer.h"
@@ -43,12 +43,14 @@
 ***********************************************************************/
 
 // Convolution coefficients.
-static float kernel_re[MAX_FCONV_SIZE] __attribute__ ((aligned (128)));
-static float kernel_im[MAX_FCONV_SIZE] __attribute__ ((aligned (128)));
+static float kernel_re[VSIP_IMPL_MAX_FCONV_SPLIT_SIZE] 
+       __attribute__ ((aligned (128)));
+static float kernel_im[VSIP_IMPL_MAX_FCONV_SPLIT_SIZE] 
+       __attribute__ ((aligned (128)));
 
 // Twiddle factors.  For N-point convolution, N/4 twiddle factors
 // are required.
-static volatile float twiddle_factors[MAX_FCONV_SIZE*2/4]
+static volatile float twiddle_factors[VSIP_IMPL_MAX_FCONV_SPLIT_SIZE*2/4]
                 __attribute__ ((aligned (128)));
 
 // Instance-id.  Used to determine when new coefficients must be loaded.
@@ -115,6 +117,7 @@
   (void)total_count;
 
   Fastconv_split_params* fc = (Fastconv_split_params *)params;
+  spe_assert(fc->elements * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
   addr64 ea;
 
   // Transfer input.
@@ -143,6 +146,7 @@
   (void)total_count;
 
   Fastconv_split_params* fc = (Fastconv_split_params *)params;
+  spe_assert(fc->elements * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
   addr64 ea;
 
   // Transfer output.
@@ -170,7 +174,7 @@
   Fastconv_split_params* fc = (Fastconv_split_params *)params;
   unsigned int n = fc->elements;
   unsigned int log2n = log2i(n);
-  assert(n <= MAX_FCONV_SIZE);
+  spe_assert(n <= VSIP_IMPL_MAX_FCONV_SPLIT_SIZE);
 
   (void)context;
   (void)iter;
Index: src/vsip/opt/cbe/spu/spe_assert.h
===================================================================
--- src/vsip/opt/cbe/spu/spe_assert.h	(revision 0)
+++ src/vsip/opt/cbe/spu/spe_assert.h	(revision 0)
@@ -0,0 +1,57 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/spu/spe_assert.h
+    @author  Jules Bergmann, Don McCoy
+    @date    2007-03-23
+    @brief   VSIPL++ Library: Replacement function for assert(), used
+               because it is broken as of 2007/03.
+*/
+
+#ifndef _SPE_ASSERT_H_
+#define _SPE_ASSERT_H_
+
+#ifndef NDEBUG
+#include <stdio.h>
+
+void inline
+spe_assert_fail(
+  const char*  assertion,
+  const char*  file,
+  unsigned int line,
+  const char*  function)
+{
+  fprintf(stderr, "ASSERTION FAILURE: %s %s %d %s\n",
+	  assertion, file, line, function);
+  abort();
+}
+
+#if defined(__GNU__)
+# if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
+#  define SPE_ASSERT_FUNCTION    __func__
+# else
+#  define SPE_ASSERT_FUNCTION    ((__const char *) 0)
+# endif
+#else
+# define SPE_ASSERT_FUNCTION    ((__const char *) 0)
+#endif
+
+#ifdef __STDC__
+#  define __SPE_STRING(e) #e
+#else
+#  define __SPE_STRING(e) "e"
+#endif
+
+#define spe_assert(expr)						\
+  ((void)((expr) ? 0 :							\
+	     (spe_assert_fail(__SPE_STRING(expr), __FILE__, __LINE__,	\
+			       SPE_ASSERT_FUNCTION), 0)))
+#else
+#define spe_assert(expr)
+
+#endif /* #ifndef NDEBUG */
+
+#endif /* _SPE_ASSERT_H_ */
Index: src/vsip/opt/cbe/common.h
===================================================================
--- src/vsip/opt/cbe/common.h	(revision 166685)
+++ src/vsip/opt/cbe/common.h	(working copy)
@@ -32,11 +32,23 @@
 
 // Fast convolution shares the same minimum as FFT, but the maximum
 // is less.
-#ifndef MAX_FCONV_SIZE
-#define MAX_FCONV_SIZE	  2048
+#ifndef VSIP_IMPL_MIN_FCONV_SIZE
+#define VSIP_IMPL_MIN_FCONV_SIZE	32
 #endif
 
+#ifndef VSIP_IMPL_MAX_FCONV_SIZE
+#define VSIP_IMPL_MAX_FCONV_SIZE	2048
+#endif
 
+#ifndef VSIP_IMPL_MIN_FCONV_SPLIT_SIZE
+#define VSIP_IMPL_MIN_FCONV_SPLIT_SIZE	64
+#endif
+
+#ifndef VSIP_IMPL_MAX_FCONV_SPLIT_SIZE
+#define VSIP_IMPL_MAX_FCONV_SPLIT_SIZE	4096
+#endif
+
+
 typedef enum
 {
   fwd_fft = 0,
