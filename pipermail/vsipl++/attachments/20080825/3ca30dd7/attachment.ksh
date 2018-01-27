Index: ChangeLog
===================================================================
--- ChangeLog	(revision 218694)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2008-08-25  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/cbe/spu/alf_fft_split_c.c: Check in missing file,
+	  split FFT.
+
 2008-08-25  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* tests/cvsip/ctensor.c: Fix blockbind call.
Index: src/vsip/opt/cbe/spu/alf_fft_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fft_split_c.c	(revision 0)
+++ src/vsip/opt/cbe/spu/alf_fft_split_c.c	(revision 0)
@@ -0,0 +1,149 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/spu/alf_fft_split_c.c
+    @author  Don McCoy, Jules Bergmann
+    @date    2008-01-23
+    @brief   VSIPL++ Library: Kernel to compute split-complex float FFT's.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <stdio.h>
+#include <alf_accel.h>
+#include <spu_mfcio.h>
+#include <cml/spu/cml.h>
+#include <cml/spu/cml_core.h>
+
+#include <vsip/core/acconfig.hpp>
+#include <vsip/opt/cbe/fft_params.h>
+
+#define _ALF_MAX_SINGLE_DT_SIZE 16*1024
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+int input(
+  void*        context,
+  void*        params,
+  void*        entries,
+  unsigned int current_count,
+  unsigned int total_count)
+{
+  Fft_split_params* fft = (Fft_split_params *)params;
+  assert(fft->fft_size * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
+  alf_data_addr64_t ea;
+
+  // Transfer input.
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+
+  ea = fft->ea_input_re + current_count * fft->in_blk_stride *
+           sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fft->fft_size, ALF_DATA_FLOAT, ea);
+
+  ea = fft->ea_input_im + current_count * fft->in_blk_stride *
+           sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fft->fft_size, ALF_DATA_FLOAT, ea);
+
+  ALF_ACCEL_DTL_END(entries);
+
+  return 0;
+}
+
+
+
+int output(
+  void*        context,
+  void*        params,
+  void*        entries,
+  unsigned int current_count,
+  unsigned int total_count)
+{
+  Fft_split_params* fft = (Fft_split_params *)params;
+  assert(fft->fft_size * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
+  alf_data_addr64_t ea;
+
+  // Transfer output.
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
+
+  ea = fft->ea_output_re + current_count * fft->out_blk_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fft->fft_size, ALF_DATA_FLOAT, ea);
+
+  ea = fft->ea_output_im + current_count * fft->out_blk_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fft->fft_size, ALF_DATA_FLOAT, ea);
+
+  ALF_ACCEL_DTL_END(entries);
+
+  return 0;
+}
+
+
+int kernel(
+  void*        context,
+  void*        params,
+  void*        input,
+  void*        output,
+  void*        inout,
+  unsigned int iter,
+  unsigned int iter_max)
+{
+  static fft1d_f* obj;
+  static char*    buf;
+  static size_t   current_size = 0;
+
+  Fft_split_params* fftp = (Fft_split_params *)params;
+
+  unsigned int fft_size = fftp->fft_size;
+  int dir = fftp->direction == fwd_fft ? CML_FFT_FWD : CML_FFT_INV;
+
+  assert(fft_size >= MIN_FFT_1D_SIZE);
+  assert(fft_size <= MAX_FFT_1D_SIZE);
+
+  if (iter == 0 && fft_size != current_size)
+  {
+    if (obj)
+    {
+      free(buf);
+      cml_fft1d_destroy_f_alloc(obj);
+    }
+    int rt = cml_fft1d_setup_f_alloc(&obj, CML_FFT_CC, fft_size);
+    assert(rt && obj != NULL);
+    buf = (char*)memalign(16, cml_zzfft1d_buf_size_f(obj));
+    assert(buf != NULL);
+    current_size = fft_size;
+  }
+
+  float*        in_re  = (float*)input  + 0 * fft_size;
+  float*        in_im  = (float*)input  + 1 * fft_size;
+  float*        out_re = (float*)output + 0 * fft_size;
+  float*        out_im = (float*)output + 1 * fft_size;
+
+  cml_zzfft1d_op_f(obj,
+		   (float*)in_re,  (float*)in_im,
+		   (float*)out_re, (float*)out_im,
+		   dir, buf);
+
+  if (fftp->scale != (double)1.f)
+  {
+    // Instead of regular split svmul:
+    // cml_core_rzsvmul1_f(fftp->scale, out_re,out_im,out_re,out_im,fft_size);
+    // Take advantage of real and imag being contiguous:
+    cml_core_svmul1_f(fftp->scale, out_re, out_re, 2*fft_size);
+  }
+
+  return 0;
+}
+
+ALF_ACCEL_EXPORT_API_LIST_BEGIN
+  ALF_ACCEL_EXPORT_API ("input", input);
+  ALF_ACCEL_EXPORT_API ("output", output); 
+  ALF_ACCEL_EXPORT_API ("kernel", kernel);
+ALF_ACCEL_EXPORT_API_LIST_END
