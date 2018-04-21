Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 167098)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -19,7 +19,7 @@
 #include <vsip/core/allocation.hpp>
 #include <vsip/core/fft/backend.hpp>
 #include <vsip/core/fft/util.hpp>
-#include <vsip/opt/cbe/common.h>
+#include <vsip/opt/cbe/fft_params.h>
 #include <vsip/opt/cbe/ppu/fft.hpp>
 #include <vsip/opt/cbe/ppu/bindings.hpp>
 #include <vsip/opt/cbe/ppu/task_manager.hpp>
Index: src/vsip/opt/cbe/ppu/fastconv.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.cpp	(revision 167098)
+++ src/vsip/opt/cbe/ppu/fastconv.cpp	(working copy)
@@ -18,7 +18,7 @@
 #include <vsip/core/fns_scalar.hpp>
 #include <vsip/core/static_assert.hpp>
 #include <vsip/math.hpp>
-#include <vsip/opt/cbe/common.h>
+#include <vsip/opt/cbe/fconv_params.h>
 #include <vsip/opt/cbe/ppu/fastconv.hpp>
 #include <vsip/opt/cbe/ppu/task_manager.hpp>
 extern "C"
@@ -49,14 +49,14 @@
 
   params.instance_id        = this->instance_id_;
   params.elements           = length;
-  params.in_ptr             = (float*)in;
-  params.out_ptr            = (float*)out;
-  params.in_blk_stride      = length;
-  params.out_blk_stride     = length;
-  params.ea_kernel          = reinterpret_cast<unsigned long long>(kernel);
   params.transform_kernel   = this->transform_kernel_;
   params.ea_twiddle_factors = reinterpret_cast<unsigned long long>
-    (this->twiddle_factors_.get());
+                                (this->twiddle_factors_.get());
+  params.ea_kernel          = reinterpret_cast<unsigned long long>(kernel);
+  params.ea_input           = reinterpret_cast<unsigned long long>(in);
+  params.ea_output          = reinterpret_cast<unsigned long long>(out);
+  params.input_stride       = length;
+  params.output_stride      = length;
 
   length_type psize = sizeof(params);
   // The stack size takes into account two temporary buffers used
@@ -79,8 +79,8 @@
     block.set_parameters(params);
     task.enqueue(block);
 
-    params.in_ptr  += (sizeof(T)/sizeof(float))*my_rows*length;
-    params.out_ptr += (sizeof(T)/sizeof(float))*my_rows*length;
+    params.ea_input  += sizeof(T) * my_rows * length;
+    params.ea_output += sizeof(T) * my_rows * length;
   }
 
   task.sync();
@@ -105,17 +105,17 @@
 
   params.instance_id        = this->instance_id_;
   params.elements           = length;
-  params.in_re_ptr          = (float*)in.first;
-  params.in_im_ptr          = (float*)in.second;
-  params.out_re_ptr         = (float*)out.first;
-  params.out_im_ptr         = (float*)out.second;
-  params.in_blk_stride      = length;
-  params.out_blk_stride     = length;
+  params.transform_kernel   = this->transform_kernel_;
+  params.ea_twiddle_factors = reinterpret_cast<unsigned long long>
+                                (this->twiddle_factors_.get());
   params.ea_kernel_re       = reinterpret_cast<unsigned long long>(kernel.first);
   params.ea_kernel_im       = reinterpret_cast<unsigned long long>(kernel.second);
-  params.transform_kernel   = this->transform_kernel_;
-  params.ea_twiddle_factors = reinterpret_cast<unsigned long long>
-    (this->twiddle_factors_.get());
+  params.ea_input_re        = reinterpret_cast<unsigned long long>(in.first);
+  params.ea_input_im        = reinterpret_cast<unsigned long long>(in.second);
+  params.ea_output_re       = reinterpret_cast<unsigned long long>(out.first);
+  params.ea_output_im       = reinterpret_cast<unsigned long long>(out.second);
+  params.input_stride       = length;
+  params.output_stride      = length;
 
   length_type psize = sizeof(params);
   // The split complex version has a smaller stack size requirement,
@@ -140,10 +140,10 @@
     block.set_parameters(params);
     task.enqueue(block);
 
-    params.in_re_ptr  += my_rows*length;
-    params.in_im_ptr  += my_rows*length;
-    params.out_re_ptr += my_rows*length;
-    params.out_im_ptr += my_rows*length;
+    params.ea_input_re  += sizeof(T) * my_rows * length;
+    params.ea_input_im  += sizeof(T) * my_rows * length;
+    params.ea_output_re += sizeof(T) * my_rows * length;
+    params.ea_output_im += sizeof(T) * my_rows * length;
   }
 
   task.sync();
Index: src/vsip/opt/cbe/ppu/fft.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.hpp	(revision 167098)
+++ src/vsip/opt/cbe/ppu/fft.hpp	(working copy)
@@ -25,7 +25,7 @@
 #include <vsip/domain.hpp>
 #include <vsip/core/fft/factory.hpp>
 #include <vsip/core/fft/util.hpp>
-#include <vsip/opt/cbe/common.h>
+#include <vsip/opt/cbe/fft_params.h>
 
 /***********************************************************************
   Declarations
Index: src/vsip/opt/cbe/ppu/fastconv.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.hpp	(revision 167098)
+++ src/vsip/opt/cbe/ppu/fastconv.hpp	(working copy)
@@ -20,7 +20,7 @@
 #include <vsip/core/allocation.hpp>
 #include <vsip/core/config.hpp>
 #include <vsip/core/extdata.hpp>
-#include <vsip/opt/cbe/common.h>
+#include <vsip/opt/cbe/fconv_params.h>
 #include <vsip/opt/cbe/ppu/bindings.hpp>
 #include <vsip/opt/cbe/ppu/task_manager.hpp>
 extern "C"
Index: src/vsip/opt/cbe/fconv_params.h
===================================================================
--- src/vsip/opt/cbe/fconv_params.h	(revision 167098)
+++ src/vsip/opt/cbe/fconv_params.h	(working copy)
@@ -1,37 +1,24 @@
-/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    vsip/opt/cbe/common.h
+/** @file    vsip/opt/cbe/fconv_params.h
     @author  Don McCoy
     @date    2007-02-04
-    @brief   VSIPL++ Library: Common definitions for Cell BE SDK functions.
+    @brief   VSIPL++ Library: Parameters for fast convolution kernels.
 */
 
-#ifndef VSIP_OPT_CBE_COMMON_H
-#define VSIP_OPT_CBE_COMMON_H
+#ifndef VSIP_OPT_CBE_FCONV_PARAMS_H
+#define VSIP_OPT_CBE_FCONV_PARAMS_H
 
 /***********************************************************************
   Definitions
 ***********************************************************************/
 
-// Note: the minimum size is determined by the fact that the SPE
-// algorithm hand unrolls one loop, doubling the minimum of 16.
-#ifndef MIN_FFT_1D_SIZE
-#define MIN_FFT_1D_SIZE	  32
-#endif
-
-// The maximum size may be up to, but no greater than 8K due to the
-// internal memory requirements of the algorithm.  This is further 
-// limited here to allow more headroom for fast convolution.
-#ifndef MAX_FFT_1D_SIZE
-#define MAX_FFT_1D_SIZE	  4096
-#endif
-
 // Fast convolution shares the same minimum as FFT, but the maximum
-// is less.
+// is less as more memory is required.
 #ifndef VSIP_IMPL_MIN_FCONV_SIZE
 #define VSIP_IMPL_MIN_FCONV_SIZE	32
 #endif
@@ -49,29 +36,8 @@
 #endif
 
 
-typedef enum
-{
-  fwd_fft = 0,
-  inv_fft
-} fft_dir_type;
-
-
 // Structures used in DMAs should be sized in multiples of 128-bits
 
-typedef struct
-{
-  fft_dir_type direction;
-  unsigned int elements;
-  double scale;
-  unsigned long long ea_twiddle_factors;
-  unsigned long long ea_input_buffer;
-  unsigned long long ea_output_buffer;
-  unsigned int       in_blk_stride;
-  unsigned int       out_blk_stride;
-} Fft_params;
-
-
-
 // Definitions for 'command' bitfields:
 #define RELOAD_TWIDDLE_FACTORS   (0x01)
 #define RELOAD_WEIGHTS           (0x02)
@@ -80,35 +46,45 @@
 {
   unsigned int       instance_id;
   unsigned int       elements;
-  unsigned long long ea_kernel;
-  unsigned long long ea_twiddle_factors;
-  float*             in_ptr;
-  float*             out_ptr;
-  unsigned int       in_blk_stride;
-  unsigned int       out_blk_stride;
   unsigned int       transform_kernel;
-  unsigned int       pad;
+  unsigned int        pad1;
+
+  unsigned long long ea_twiddle_factors;
+  unsigned long long ea_kernel;
+
+  unsigned long long ea_input;
+  unsigned long long ea_output;
+
+  unsigned int       kernel_stride;
+  unsigned int       input_stride;
+  unsigned int       output_stride;
+  unsigned int        pad2;
 } Fastconv_params;
 
 typedef struct
 {
   unsigned int       instance_id;
   unsigned int       elements;
-  unsigned long long ea_kernel_re;
+  unsigned int       transform_kernel;
+  unsigned int        pad1;
 
-  unsigned long long ea_kernel_im;
   unsigned long long ea_twiddle_factors;
+  unsigned long long  pad2;
 
-  float*             in_re_ptr;
-  float*             in_im_ptr;
-  float*             out_re_ptr;
-  float*             out_im_ptr;
+  unsigned long long ea_kernel_re;
+  unsigned long long ea_kernel_im;
 
-  unsigned int       in_blk_stride;
-  unsigned int       out_blk_stride;
-  unsigned int       transform_kernel;
-  unsigned int       pad;
+  unsigned long long ea_input_re;
+  unsigned long long ea_input_im;
+
+  unsigned long long ea_output_re;
+  unsigned long long ea_output_im;
+
+  unsigned int       kernel_stride;
+  unsigned int       input_stride;
+  unsigned int       output_stride;
+  unsigned int        pad3;
 } Fastconv_split_params;
 
 
-#endif // VSIP_OPT_CBE_COMMON_H
+#endif // VSIP_OPT_CBE_FCONV_PARAMS_H
Index: src/vsip/opt/cbe/spu/alf_fconv_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconv_c.c	(revision 167098)
+++ src/vsip/opt/cbe/spu/alf_fconv_c.c	(working copy)
@@ -13,7 +13,7 @@
 #include <sys/time.h>
 #include <spu_mfcio.h>
 #include <alf_accel.h>
-#include <vsip/opt/cbe/common.h>
+#include <vsip/opt/cbe/fconv_params.h>
 #include "fft_1d_r2.h"
 #include "spe_assert.h"
 
@@ -87,8 +87,7 @@
 
   // Transfer input.
   ALF_DT_LIST_CREATE(list_entries, 0);
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(fc->in_ptr + current_count * FP * fc->in_blk_stride);
+  ea.ull = fc->ea_input + current_count * FP * fc->input_stride * sizeof(float);
   ALF_DT_LIST_ADD_ENTRY(list_entries,
 			FP * fc->elements,
 			ALF_DATA_FLOAT,
@@ -114,8 +113,7 @@
 
   // Transfer output.
   ALF_DT_LIST_CREATE(list_entries, 0);
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(fc->out_ptr + current_count * FP * fc->out_blk_stride);
+  ea.ull = fc->ea_output + current_count * FP * fc->output_stride * sizeof(float);
   ALF_DT_LIST_ADD_ENTRY(list_entries,
 			FP * fc->elements,
 			ALF_DATA_FLOAT,
Index: src/vsip/opt/cbe/spu/alf_fft_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fft_c.c	(revision 167098)
+++ src/vsip/opt/cbe/spu/alf_fft_c.c	(working copy)
@@ -14,7 +14,7 @@
 #include <assert.h>
 #include <libfft.h>
 #include <spu_mfcio.h>
-#include <vsip/opt/cbe/common.h>
+#include <vsip/opt/cbe/fft_params.h>
 
 // These are sized for complex values, taking two floats each.  The twiddle 
 // factors occupy only 1/4 the space as the inputs, outputs and convolution 
Index: src/vsip/opt/cbe/spu/alf_fconv_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconv_split_c.c	(revision 167098)
+++ src/vsip/opt/cbe/spu/alf_fconv_split_c.c	(working copy)
@@ -21,7 +21,7 @@
 #include <spu_mfcio.h>
 #include <alf_accel.h>
 
-#include <vsip/opt/cbe/common.h>
+#include <vsip/opt/cbe/fconv_params.h>
 
 #include "fft_1d_r2_split.h"
 #include "vmul_split.h"
@@ -122,12 +122,10 @@
 
   // Transfer input.
   ALF_DT_LIST_CREATE(list_entries, 0);
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(fc->in_re_ptr + current_count * fc->in_blk_stride);
+  ea.ull = fc->ea_input_re + current_count * fc->input_stride * sizeof(float);
   ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
 
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(fc->in_im_ptr + current_count * fc->in_blk_stride);
+  ea.ull = fc->ea_input_im + current_count * fc->input_stride * sizeof(float);
   ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
 
   return 0;
@@ -151,12 +149,10 @@
 
   // Transfer output.
   ALF_DT_LIST_CREATE(list_entries, 0);
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(fc->out_re_ptr + current_count * fc->out_blk_stride);
+  ea.ull = fc->ea_output_re + current_count * fc->output_stride * sizeof(float);
   ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
 
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(fc->out_im_ptr + current_count * fc->out_blk_stride);
+  ea.ull = fc->ea_output_im + current_count * fc->output_stride * sizeof(float);
   ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
 
   return 0;
Index: src/vsip/opt/cbe/fft_params.h
===================================================================
--- src/vsip/opt/cbe/fft_params.h	(revision 0)
+++ src/vsip/opt/cbe/fft_params.h	(revision 0)
@@ -0,0 +1,55 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/fft_params.h
+    @author  Don McCoy
+    @date    2007-03-27
+    @brief   VSIPL++ Library: Parameters for FFT kernels.
+*/
+
+#ifndef VSIP_OPT_CBE_FFT_PARAMS_H
+#define VSIP_OPT_CBE_FFT_PARAMS_H
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Note: the minimum size is determined by the fact that the SPE
+// algorithm hand unrolls one loop, doubling the minimum of 16.
+#ifndef MIN_FFT_1D_SIZE
+#define MIN_FFT_1D_SIZE	  32
+#endif
+
+// The maximum size may be up to, but no greater than 8K due to the
+// internal memory requirements of the algorithm.  This is further 
+// limited here to allow more headroom for fast convolution.
+#ifndef MAX_FFT_1D_SIZE
+#define MAX_FFT_1D_SIZE	  4096
+#endif
+
+
+typedef enum
+{
+  fwd_fft = 0,
+  inv_fft
+} fft_dir_type;
+
+
+// Structures used in DMAs should be sized in multiples of 128-bits
+
+typedef struct
+{
+  fft_dir_type direction;
+  unsigned int elements;
+  double scale;
+  unsigned long long ea_twiddle_factors;
+  unsigned long long ea_input_buffer;
+  unsigned long long ea_output_buffer;
+  unsigned int       in_blk_stride;
+  unsigned int       out_blk_stride;
+} Fft_params;
+
+#endif // VSIP_OPT_CBE_FFT_PARAMS_H
Index: src/vsip/opt/cbe/common.h
===================================================================
--- src/vsip/opt/cbe/common.h	(revision 167098)
+++ src/vsip/opt/cbe/common.h	(working copy)
@@ -1,114 +0,0 @@
-/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
-
-   This file is available for license from CodeSourcery, Inc. under the terms
-   of a commercial license and under the GPL.  It is not part of the VSIPL++
-   reference implementation and is not available under the BSD license.
-*/
-/** @file    vsip/opt/cbe/common.h
-    @author  Don McCoy
-    @date    2007-02-04
-    @brief   VSIPL++ Library: Common definitions for Cell BE SDK functions.
-*/
-
-#ifndef VSIP_OPT_CBE_COMMON_H
-#define VSIP_OPT_CBE_COMMON_H
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-// Note: the minimum size is determined by the fact that the SPE
-// algorithm hand unrolls one loop, doubling the minimum of 16.
-#ifndef MIN_FFT_1D_SIZE
-#define MIN_FFT_1D_SIZE	  32
-#endif
-
-// The maximum size may be up to, but no greater than 8K due to the
-// internal memory requirements of the algorithm.  This is further 
-// limited here to allow more headroom for fast convolution.
-#ifndef MAX_FFT_1D_SIZE
-#define MAX_FFT_1D_SIZE	  4096
-#endif
-
-// Fast convolution shares the same minimum as FFT, but the maximum
-// is less.
-#ifndef VSIP_IMPL_MIN_FCONV_SIZE
-#define VSIP_IMPL_MIN_FCONV_SIZE	32
-#endif
-
-#ifndef VSIP_IMPL_MAX_FCONV_SIZE
-#define VSIP_IMPL_MAX_FCONV_SIZE	2048
-#endif
-
-#ifndef VSIP_IMPL_MIN_FCONV_SPLIT_SIZE
-#define VSIP_IMPL_MIN_FCONV_SPLIT_SIZE	64
-#endif
-
-#ifndef VSIP_IMPL_MAX_FCONV_SPLIT_SIZE
-#define VSIP_IMPL_MAX_FCONV_SPLIT_SIZE	4096
-#endif
-
-
-typedef enum
-{
-  fwd_fft = 0,
-  inv_fft
-} fft_dir_type;
-
-
-// Structures used in DMAs should be sized in multiples of 128-bits
-
-typedef struct
-{
-  fft_dir_type direction;
-  unsigned int elements;
-  double scale;
-  unsigned long long ea_twiddle_factors;
-  unsigned long long ea_input_buffer;
-  unsigned long long ea_output_buffer;
-  unsigned int       in_blk_stride;
-  unsigned int       out_blk_stride;
-} Fft_params;
-
-
-
-// Definitions for 'command' bitfields:
-#define RELOAD_TWIDDLE_FACTORS   (0x01)
-#define RELOAD_WEIGHTS           (0x02)
-
-typedef struct
-{
-  unsigned int       instance_id;
-  unsigned int       elements;
-  unsigned long long ea_kernel;
-  unsigned long long ea_twiddle_factors;
-  float*             in_ptr;
-  float*             out_ptr;
-  unsigned int       in_blk_stride;
-  unsigned int       out_blk_stride;
-  unsigned int       transform_kernel;
-  unsigned int       pad;
-} Fastconv_params;
-
-typedef struct
-{
-  unsigned int       instance_id;
-  unsigned int       elements;
-  unsigned long long ea_kernel_re;
-
-  unsigned long long ea_kernel_im;
-  unsigned long long ea_twiddle_factors;
-
-  float*             in_re_ptr;
-  float*             in_im_ptr;
-  float*             out_re_ptr;
-  float*             out_im_ptr;
-
-  unsigned int       in_blk_stride;
-  unsigned int       out_blk_stride;
-  unsigned int       transform_kernel;
-  unsigned int       pad;
-} Fastconv_split_params;
-
-
-#endif // VSIP_OPT_CBE_COMMON_H
