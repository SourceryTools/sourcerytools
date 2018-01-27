Index: ChangeLog
===================================================================
--- ChangeLog	(revision 223942)
+++ ChangeLog	(working copy)
@@ -1,3 +1,18 @@
+2008-10-07  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (CPP_SPU_FLAGS): Add -DPPU_IS_32=1 if ppu is 32-bit.
+	* src/vsip/opt/cbe/spu/alf_fft_split_c.c: Avoid DMA list when PPU
+	  EAs are 64-bit.
+	* src/vsip/opt/cbe/spu/alf_vmmul_split_c.c: Likewise.
+	* src/vsip/opt/cbe/spu/alf_vmul_split_c.c: Likewise.
+	* src/vsip/opt/cbe/spu/alf_vmul_c.c: Likewise.
+	* src/vsip/opt/cbe/spu/alf_vmul_s.c: Likewise.
+	* src/vsip/opt/cbe/spu/alf_fconvm_split_c.c: Likewise.
+	* src/vsip/opt/cbe/spu/alf_fconv_split_c.c: Likewise.
+	* src/vsip/opt/cbe/spu/alf_fconvm_c.c: Likewise.
+	* tests/solver-common.hpp: Relax is_positive defn to allow
+	  near zero imaginary part.
+	
 2008-10-06  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/cbe/spu/alf_vmmul_split_c.c: New file, split vmmul,
Index: configure.ac
===================================================================
--- configure.ac	(revision 223485)
+++ configure.ac	(working copy)
@@ -404,6 +404,7 @@
 
   if test -n "`echo $CFLAGS | sed -n '/-m32/p'`" -o \
           -n "`echo $CFLAGS | sed -n '/-q32/p'`"; then
+    CPP_SPU_FLAGS="$CPP_SPU_FLAGS -DPPU_IS_32BIT=1"
     EMBED_SPU="$EMBED_SPU -m32"
   elif test -n "`echo $CFLAGS | sed -n '/-m64/p'`" -o \
             -n "`echo $CFLAGS | sed -n '/-q64/p'`"; then
Index: src/vsip/opt/cbe/spu/alf_fft_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fft_split_c.c	(revision 223485)
+++ src/vsip/opt/cbe/spu/alf_fft_split_c.c	(working copy)
@@ -44,6 +44,7 @@
   alf_data_addr64_t ea;
 
   // Transfer input.
+#if PPU_IS_32BIT
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
 
   ea = fft->ea_input_re + current_count * fft->in_blk_stride *
@@ -55,7 +56,20 @@
   ALF_ACCEL_DTL_ENTRY_ADD(entries, fft->fft_size, ALF_DATA_FLOAT, ea);
 
   ALF_ACCEL_DTL_END(entries);
+#else
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+  ea = fft->ea_input_re + current_count * fft->in_blk_stride *
+           sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fft->fft_size, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, fft->fft_size*sizeof(float));
+  ea = fft->ea_input_im + current_count * fft->in_blk_stride *
+           sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fft->fft_size, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
@@ -73,6 +87,7 @@
   alf_data_addr64_t ea;
 
   // Transfer output.
+#if PPU_IS_32BIT
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
 
   ea = fft->ea_output_re + current_count * fft->out_blk_stride * sizeof(float);
@@ -82,7 +97,18 @@
   ALF_ACCEL_DTL_ENTRY_ADD(entries, fft->fft_size, ALF_DATA_FLOAT, ea);
 
   ALF_ACCEL_DTL_END(entries);
+#else
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
+  ea = fft->ea_output_re + current_count * fft->out_blk_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fft->fft_size, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, fft->fft_size*sizeof(float));
+  ea = fft->ea_output_im + current_count * fft->out_blk_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fft->fft_size, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
Index: src/vsip/opt/cbe/spu/alf_vmmul_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmmul_split_c.c	(revision 223942)
+++ src/vsip/opt/cbe/spu/alf_vmmul_split_c.c	(working copy)
@@ -88,6 +88,7 @@
   Vmmul_split_params* params = (Vmmul_split_params*)p_params;
   unsigned long       length = params->length;
 
+#if PPU_IS_32BIT
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
 
   add_vector_f(entries, 
@@ -100,7 +101,22 @@
 	       length);
 
   ALF_ACCEL_DTL_END(entries);
+#else
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+  add_vector_f(entries, 
+	       params->ea_input_matrix_re +
+	       current_count * FP * params->input_stride * sizeof(float),
+	       length);
+  ALF_ACCEL_DTL_END(entries);
 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, length*sizeof(float));
+  add_vector_f(entries, 
+	       params->ea_input_matrix_im +
+	       current_count * FP * params->input_stride * sizeof(float),
+	       length);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
@@ -117,6 +133,7 @@
   Vmmul_split_params* params = (Vmmul_split_params*)p_params;
   unsigned long       length = params->length;
 
+#if PPU_IS_32BIT
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
 
   add_vector_f(entries, 
@@ -129,7 +146,22 @@
 	       length);
 
   ALF_ACCEL_DTL_END(entries);
+#else
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
+  add_vector_f(entries, 
+	       params->ea_output_matrix_re +
+	       current_count * FP * params->output_stride * sizeof(float),
+	       length);
+  ALF_ACCEL_DTL_END(entries);
 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, length*sizeof(float));
+  add_vector_f(entries, 
+	       params->ea_output_matrix_im +
+	       current_count * FP * params->output_stride * sizeof(float),
+	       length);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
Index: src/vsip/opt/cbe/spu/alf_vmul_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmul_split_c.c	(revision 223485)
+++ src/vsip/opt/cbe/spu/alf_vmul_split_c.c	(working copy)
@@ -27,6 +27,7 @@
   Vmul_split_params* p = (Vmul_split_params*)p_params;
   alf_data_addr64_t ea;
 
+#if PPU_IS_32BIT
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
 
   // Transfer input A real
@@ -44,7 +45,30 @@
   ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
 
   ALF_ACCEL_DTL_END(entries);
+#else
+  // Transfer input A real
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+  ea = p->a_re_ptr + current_count * p->a_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 1*p->length*sizeof(float));
+  ea = p->a_im_ptr + current_count * p->a_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+
+  // Transfer input B.
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 2*p->length*sizeof(float));
+  ea = p->b_re_ptr + current_count * p->b_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 3*p->length*sizeof(float));
+  ea = p->b_im_ptr + current_count * p->b_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
@@ -61,6 +85,7 @@
   alf_data_addr64_t ea;
 
   // Transfer output R.
+#if PPU_IS_32BIT
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
 
   ea = p->r_re_ptr + current_count *  p->r_blk_stride;
@@ -70,7 +95,18 @@
   ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
 
   ALF_ACCEL_DTL_END(entries);
+#else
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
+  ea = p->r_re_ptr + current_count *  p->r_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, p->length*sizeof(float));
+  ea = p->r_im_ptr + current_count *  p->r_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
Index: src/vsip/opt/cbe/spu/alf_vmul_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmul_c.c	(revision 223485)
+++ src/vsip/opt/cbe/spu/alf_vmul_c.c	(working copy)
@@ -26,6 +26,7 @@
   Vmul_params* params = (Vmul_params*)p_params;
   alf_data_addr64_t ea;
 
+#if PPU_IS_32BIT
   // Transfer input A.
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
   ea = params->a_ptr + current_count*2*params->a_blk_stride*sizeof(float);
@@ -41,6 +42,26 @@
 			  ALF_DATA_FLOAT,
 			  ea);
   ALF_ACCEL_DTL_END(entries);
+#else
+  // Transfer input A.
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+  ea = params->a_ptr + current_count*2*params->a_blk_stride*sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries,
+			  2 * params->length,  	// 2 * for complex
+			  ALF_DATA_FLOAT,
+			  ea);
+  ALF_ACCEL_DTL_END(entries);
+
+  // Transfer input B.
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 2*params->length*sizeof(float));
+  ea = params->b_ptr + current_count*2*params->b_blk_stride*sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries,
+			  2 * params->length,  	// 2 * for complex
+			  ALF_DATA_FLOAT,
+			  ea);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
Index: src/vsip/opt/cbe/spu/alf_vmul_s.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmul_s.c	(revision 223485)
+++ src/vsip/opt/cbe/spu/alf_vmul_s.c	(working copy)
@@ -29,6 +29,7 @@
   Vmul_params* params = (Vmul_params*)p_params;
   alf_data_addr64_t ea;
 
+#if PPU_IS_32BIT
   // Transfer input A.
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
   ea = params->a_ptr + current_count * FP * params->a_blk_stride;
@@ -45,7 +46,26 @@
 			  ea);
 
   ALF_ACCEL_DTL_END(entries);
+#else
+  // Transfer input A.
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+  ea = params->a_ptr + current_count * FP * params->a_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries,
+			  FP * params->length,
+			  ALF_DATA_FLOAT,
+			  ea);
+  ALF_ACCEL_DTL_END(entries);
 
+  // Transfer input B.
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, FP * params->length*sizeof(float));
+  ea = params->b_ptr + current_count * FP * params->b_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries,
+			  FP * params->length,
+			  ALF_DATA_FLOAT,
+			  ea);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
Index: src/vsip/opt/cbe/spu/alf_fconvm_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconvm_split_c.c	(revision 223485)
+++ src/vsip/opt/cbe/spu/alf_fconvm_split_c.c	(working copy)
@@ -64,6 +64,7 @@
   alf_data_addr64_t ea;
 
   // Transfer input.
+#if PPU_IS_32BIT
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
 
   ea = fc->ea_input_re + current_count * fc->input_stride * sizeof(float);
@@ -79,7 +80,28 @@
   ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
 
   ALF_ACCEL_DTL_END(entries);
+#else
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+  ea = fc->ea_input_re + current_count * fc->input_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 1*fc->elements*sizeof(float));
+  ea = fc->ea_input_im + current_count * fc->input_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 2*fc->elements*sizeof(float));
+  ea = fc->ea_kernel_re + current_count * fc->kernel_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 3*fc->elements*sizeof(float));
+  ea = fc->ea_kernel_im + current_count * fc->kernel_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
@@ -100,6 +122,7 @@
   alf_data_addr64_t ea;
 
   // Transfer output.
+#if PPU_IS_32BIT
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
 
   ea = fc->ea_output_re + current_count * fc->output_stride * sizeof(float);
@@ -109,7 +132,18 @@
   ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
 
   ALF_ACCEL_DTL_END(entries);
+#else
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
+  ea = fc->ea_output_re + current_count * fc->output_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, fc->elements*sizeof(float));
+  ea = fc->ea_output_im + current_count * fc->output_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
Index: src/vsip/opt/cbe/spu/alf_fconv_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconv_split_c.c	(revision 223485)
+++ src/vsip/opt/cbe/spu/alf_fconv_split_c.c	(working copy)
@@ -65,8 +65,6 @@
 
   // The kernel matches the input and output size
   mfc_get(p_kernel_re, fc->ea_kernel_re, n*sizeof(float), 31, 0, 0);
-  mfc_write_tag_mask(1<<31);
-  mfc_read_tag_status_all();
   mfc_get(p_kernel_im, fc->ea_kernel_im, n*sizeof(float), 31, 0, 0);
   mfc_write_tag_mask(1<<31);
   mfc_read_tag_status_all();
@@ -98,6 +96,7 @@
   alf_data_addr64_t ea;
 
   // Transfer input.
+#if PPU_IS_32BIT
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
   ea = fc->ea_input_re + current_count * fc->input_stride * sizeof(float);
   ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
@@ -106,7 +105,18 @@
   ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
 
   ALF_ACCEL_DTL_END(entries);
+#else
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+  ea = fc->ea_input_re + current_count * fc->input_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, fc->elements*sizeof(float));
+  ea = fc->ea_input_im + current_count * fc->input_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
@@ -127,6 +137,7 @@
   alf_data_addr64_t ea;
 
   // Transfer output.
+#if PPU_IS_32BIT
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
   ea = fc->ea_output_re + current_count * fc->output_stride * sizeof(float);
   ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
@@ -135,7 +146,18 @@
   ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
 
   ALF_ACCEL_DTL_END(entries);
+#else
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
+  ea = fc->ea_output_re + current_count * fc->output_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, fc->elements*sizeof(float));
+  ea = fc->ea_output_im + current_count * fc->output_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
Index: src/vsip/opt/cbe/spu/alf_fconvm_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconvm_c.c	(revision 223485)
+++ src/vsip/opt/cbe/spu/alf_fconvm_c.c	(working copy)
@@ -38,6 +38,7 @@
   assert(fc->elements * FP *sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
   alf_data_addr64_t ea;
 
+#if PPU_IS_32BIT
   // Transfer input.
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
   ea = fc->ea_input + 
@@ -49,7 +50,22 @@
     current_count * FP * fc->kernel_stride * sizeof(float);
   ALF_ACCEL_DTL_ENTRY_ADD(entries, FP * fc->elements, ALF_DATA_FLOAT, ea);
   ALF_ACCEL_DTL_END(entries);
+#else
+  // Transfer input.
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+  ea = fc->ea_input + 
+    current_count * FP * fc->input_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, FP * fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
 
+  // Transfer kernel.
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, FP*fc->elements*sizeof(float));
+  ea = fc->ea_kernel + 
+    current_count * FP * fc->kernel_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, FP * fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
+#endif
+
   return 0;
 }
 
Index: tests/solver-common.hpp
===================================================================
--- tests/solver-common.hpp	(revision 223485)
+++ tests/solver-common.hpp	(working copy)
@@ -86,7 +86,7 @@
   static vsip::complex<T> value3() { return vsip::complex<T>(1, -1); }
   static vsip::complex<T> conj(vsip::complex<T> a) { return vsip::conj(a); }
   static bool is_positive(vsip::complex<T> a)
-  { return (a.real() > T(0)) && (a.imag() == T(0)); }
+  { return (a.real() > T(0)) && (equal(a.imag(), T(0))); }
 
   static vsip::mat_op_type const trans = vsip::mat_herm;
 };
