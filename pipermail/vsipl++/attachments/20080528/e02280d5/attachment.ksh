Index: ChangeLog
===================================================================
--- ChangeLog	(revision 209510)
+++ ChangeLog	(working copy)
@@ -1,3 +1,45 @@
+2008-05-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* m4/cbe.m4 (CPP_SPU_FLAGS, LD_SPU_FLAGS): Pass CML paths.
+	* src/vsip/core/signal/conv_common.hpp: Implement correct min
+	  support size case for 2D conv_min.
+	* src/vsip/core/fft.hpp: Remove LLC.
+	* src/vsip/opt/cbe/ppu/fft.cpp: Add split FFT support.  Remove
+	  twiddle factor computation (now taken care of by kernels).
+	* src/vsip/opt/cbe/ppu/task_manager.hpp: Fix bug in argument
+	  processing.  Add split FFT tag.
+	* src/vsip/opt/cbe/ppu/fastconv.cpp: Remove twiddle factor computation.
+	* src/vsip/opt/cbe/ppu/fastconv.hpp: Likewise.
+	* src/vsip/opt/cbe/fconv_params.h: Likewise.  Also remove padding.
+	* src/vsip/opt/cbe/ppu/alf.hpp: Make exceptions more informative.
+	* src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp: Move ALF decls to
+	  alf_decl.hpp.  Add missing argument to kernel.
+	* src/vsip/opt/ceb/spu/alf_decls.hpp: New file, decls for functions
+	  expected by ALF.
+	* src/vsip/opt/cbe/spu/alf_fconv_c.c: Refactor to use CML.
+	* src/vsip/opt/cbe/spu/alf_fft_c.c: Likewise.
+	* src/vsip/opt/cbe/spu/alf_fconv_split_c.c: Likewise.
+	* src/vsip/opt/cbe/spu/alf_fconvm_c.c: Likewise.
+	* src/vsip/opt/cbe/spu/alf_vmul_split_c.c: Likewise.
+	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Use LD_SPU_FLAGS from
+	  configure.  (LIBS_SPU): Add -lcml_spu.
+	* src/vsip/opt/cbe/spu/alf_vmmul_c.c: Update to use ALF 3.0.
+	* src/vsip/opt/cbe/spu/alf_vmul_s.c: Likewise.
+	* src/vsip/opt/cbe/spu/alf_fconvm_split_c.c: Update to use CML.
+	* src/vsip/opt/cbe/fft_params.h: Remove twiddle factor addresses,
+	  add parameters for split FFT.
+	* src/vsip/opt/diag/fft.hpp: Fix Wall warning.
+	* benchmarks/copy.cpp: Add more error detail.
+	* benchmarks/fastconv.cpp: Update parameter passing, make check
+	  optional.
+	* benchmarks/vmul.hpp: Add diagnostics.
+	* benchmarks/fftm.cpp: Fix Wall warnings.
+	* src/vsip/opt/cbe/spu/vmul_split.h: Remove file, unused.
+	* src/vsip/opt/cbe/spu/fft_1d.h: Remove file, unused.
+	* src/vsip/opt/cbe/spu/fft_1d_r2.h: Remove file, unused.
+	* src/vsip/opt/cbe/spu/fft_1d_r2_split.h: Remove file, unused.
+	* src/vsip/opt/cbe/spu/spe_assert.h: Remove file, unused.
+	
 2008-05-28  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* tests/GNUmakefile.inc.in: Adjust for new test database.
Index: m4/cbe.m4
===================================================================
--- m4/cbe.m4	(revision 208645)
+++ m4/cbe.m4	(working copy)
@@ -67,9 +67,10 @@
   if test "$with_cml_prefix" != ""; then
     CPPFLAGS="$CPPFLAGS -I$with_cml_prefix/include"
     LDFLAGS="$LDFLAGS -L$with_cml_prefix/lib"
+    CPP_SPU_FLAGS="$CPP_SPU_FLAGS -I$with_cml_prefix/include"
+    LD_SPU_FLAGS="$LD_SPU_FLAGS -L$with_cml_prefix/lib"
   fi
 
-  AC_SUBST(CPP_SPU_FLAGS, "")
   if test "$neutral_acconfig" = 'y'; then
     CPPFLAGS="$CPPFLAGS -DVSIP_CBE_SDK_VERSION=$cbe_sdk_version"
     CPP_SPU_FLAGS="$CPP_SPU_FLAGS -DVSIP_CBE_SDK_VERSION=$cbe_sdk_version"
@@ -80,6 +81,8 @@
 
   LIBS="-lcml -lalf -lspe2 -ldl $LIBS"
 
+  AC_SUBST(CPP_SPU_FLAGS, $CPP_SPU_FLAGS)
+  AC_SUBST(LD_SPU_FLAGS, $LD_SPU_FLAGS)
 else
   AC_SUBST(VSIP_IMPL_HAVE_CBE_SDK, "")
   cbe_sdk_version="none"
Index: src/vsip/core/signal/conv_common.hpp
===================================================================
--- src/vsip/core/signal/conv_common.hpp	(revision 209510)
+++ src/vsip/core/signal/conv_common.hpp	(working copy)
@@ -641,8 +641,29 @@
   typedef typename Convolution_accum_trait<T>::sum_type sum_type;
 
 #if VSIP_IMPL_CONV_CORRECT_MIN_SUPPORT_SIZE
-  VSIP_IMPL_THROW(vsip::impl::unimplemented(
-	   "conv_min not implemented for Matrix CORRECT_MIN_SUPPORT_SIZE"));
+  (void)in_rows;
+  (void)in_cols;
+
+  for (index_type r=0; r<out_rows; ++r)
+  {
+    index_type ir = r*decimation + (coeff_rows-1);
+    for (index_type c=0; c<out_cols; ++c)
+    {
+      index_type ic = c*decimation + (coeff_cols-1);
+
+      sum_type sum = sum_type();
+
+      for (index_type rr=0; rr<coeff_rows; ++rr)
+      {
+	for (index_type cc=0; cc<coeff_cols; ++cc)
+	{
+	  sum += coeff[rr*coeff_row_stride + cc*coeff_col_stride] *
+	         in[(ir-rr) * in_row_stride + (ic-cc) * in_col_stride];
+	}
+      }
+      out[r * out_row_stride + c * out_col_stride] = sum;
+    }
+  }
 #else
   for (index_type r=0; r<out_rows; ++r)
   {
Index: src/vsip/core/fft.hpp
===================================================================
--- src/vsip/core/fft.hpp	(revision 209510)
+++ src/vsip/core/fft.hpp	(working copy)
@@ -1,5 +1,4 @@
-/* Copyright (c) 2006, 2007, 2008 by CodeSourcery, LLC. 
-   All rights reserved. */
+/* Copyright (c) 2006, 2007, 2008 by CodeSourcery. All rights reserved. */
 
 /** @file    vsip/core/fft.hpp
     @author  Stefan Seefeld
Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 209510)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2007, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -42,14 +42,13 @@
   typedef std::complex<rtype> ctype;
 
 public:
-  Fft_base(length_type size) 
-    : twiddle_factors_(size / 4)
-  {
-    compute_twiddle_factors(size);
-  }
+  Fft_base(length_type) 
+  {}
+
   virtual ~Fft_base() 
   {}
 
+  // Interleaved-complex FFT
   void 
   fft(std::complex<T> const* in, std::complex<T>* out, 
     length_type length, T scale, int exponent)
@@ -59,9 +58,8 @@
 
     Fft_params fftp;
     fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
-    fftp.elements = length;
+    fftp.fft_size = length;
     fftp.scale = scale;
-    fftp.ea_twiddle_factors = ea_from_ptr(twiddle_factors_.get());
     fftp.ea_input_buffer    = ea_from_ptr(in);
     fftp.ea_output_buffer   = ea_from_ptr(out);
     fftp.in_blk_stride      = 0;  // not applicable in the single FFT case
@@ -89,7 +87,51 @@
     task.sync();
   }
 
+  // Split-complex FFT
   void 
+  fft(T const* in_re, T const* in_im, T* out_re, T* out_im, 
+    length_type length, T scale, int exponent)
+  {
+    assert(is_dma_addr_ok(in_re));
+    assert(is_dma_addr_ok(in_im));
+    assert(is_dma_addr_ok(out_re));
+    assert(is_dma_addr_ok(out_im));
+
+    Fft_split_params fftp;
+    fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
+    fftp.fft_size = length;
+    fftp.scale = scale;
+    fftp.ea_input_re        = ea_from_ptr(in_re);
+    fftp.ea_input_im        = ea_from_ptr(in_im);
+    fftp.ea_output_re       = ea_from_ptr(out_re);
+    fftp.ea_output_im       = ea_from_ptr(out_im);
+    fftp.in_blk_stride      = 0;  // not applicable in the single FFT case
+    fftp.out_blk_stride     = 0;
+
+    Task_manager *mgr = Task_manager::instance();
+    // The stack size is determined by accounting for the *worst case*
+    // stack requirements, which, to date, are _at least_ equal
+    // to 64 KB for the 8 K FFT (using two temporary arrays of 4 bytes
+    // per point each).
+    // Note on the input buffer size: the buffer is made twice the
+    // size of the output buffer.  This improves performance only at
+    // some lengths, notably 2048 and 4096, but does not hurt for
+    // other problem sizes.  Warning: this may change if the underlying
+    // implementation changes and should be revised as needed.
+    Task task = mgr->reserve<Fft_tag, void(std::pair<T*,T*>,std::pair<T*,T*>)>
+      (80*1024, // max stack size
+       sizeof(Fft_split_params), 
+       sizeof(complex<T>)*length*2, 
+       sizeof(complex<T>)*length,
+       true);
+    Workblock block = task.create_workblock(1);
+    block.set_parameters(fftp);
+    block.enqueue();
+    task.sync();
+  }
+
+  // Interleaved-complex FFTM
+  void 
   fftm(std::complex<T> const* in, std::complex<T>* out, 
     stride_type in_r_stride, stride_type in_c_stride,
     stride_type out_r_stride, stride_type out_c_stride,
@@ -104,7 +146,6 @@
     Fft_params fftp;
     fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
     fftp.scale = scale;
-    fftp.ea_twiddle_factors = ea_from_ptr(twiddle_factors_.get());
     length_type num_ffts;
     length_type in_stride;
     length_type out_stride;
@@ -113,14 +154,14 @@
       num_ffts = rows;
       in_stride = in_r_stride;
       out_stride = out_r_stride;
-      fftp.elements = cols;
+      fftp.fft_size = cols;
     }
     else
     {
       num_ffts = cols;
       in_stride = in_c_stride;
       out_stride = out_c_stride;
-      fftp.elements = rows;
+      fftp.fft_size = rows;
     }
     fftp.ea_input_buffer    = ea_from_ptr(in);
     fftp.ea_output_buffer   = ea_from_ptr(out);
@@ -140,8 +181,8 @@
     Task task = mgr->reserve<Fft_tag, void(complex<T>,complex<T>)>
       (80*1024, // max stack size
        sizeof(Fft_params), 
-       sizeof(complex<T>)*fftp.elements*2, 
-       sizeof(complex<T>)*fftp.elements,
+       sizeof(complex<T>)*fftp.fft_size*2, 
+       sizeof(complex<T>)*fftp.fft_size,
        true);
 
     length_type spes         = mgr->num_spes();
@@ -162,23 +203,90 @@
     task.sync();
   }
 
-  void
-  compute_twiddle_factors(length_type length)
+  // Split-complex FFTM
+  void 
+  fftm(T const* in_re, T const* in_im,
+    T* out_re, T* out_im,
+    stride_type in_r_stride, stride_type in_c_stride,
+    stride_type out_r_stride, stride_type out_c_stride,
+    length_type rows, length_type cols, 
+    T scale, int exponent, int axis)
   {
-    unsigned int i = 0;
-    unsigned int n = length;
-    T* W = reinterpret_cast<T*>(twiddle_factors_.get());
-    W[0] = 1.0f;
-    W[1] = 0.0f;
-    for (i = 1; i < n / 4; ++i) 
+    assert(is_dma_addr_ok(in_re));
+    assert(is_dma_addr_ok(in_im));
+    assert(is_dma_addr_ok(out_re));
+    assert(is_dma_addr_ok(out_im));
+    assert(is_dma_addr_ok(in_re  + (axis != 0 ? in_r_stride  : in_c_stride)));
+    assert(is_dma_addr_ok(out_re + (axis != 0 ? out_r_stride : out_c_stride)));
+    assert(is_dma_addr_ok(in_im  + (axis != 0 ? in_r_stride  : in_c_stride)));
+    assert(is_dma_addr_ok(out_im + (axis != 0 ? out_r_stride : out_c_stride)));
+
+    Fft_split_params fftp;
+    fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
+    fftp.scale = scale;
+    length_type num_ffts;
+    length_type in_stride;
+    length_type out_stride;
+
+    if (axis != 0)
     {
-      W[2*i] = cos(i * 2*M_PI / n);
-      W[2*(n/4 - i)+1] = -W[2*i];
+      num_ffts = rows;
+      in_stride = in_r_stride;
+      out_stride = out_r_stride;
+      fftp.fft_size = cols;
     }
+    else
+    {
+      num_ffts = cols;
+      in_stride = in_c_stride;
+      out_stride = out_c_stride;
+      fftp.fft_size = rows;
+    }
+
+    fftp.ea_input_re    = ea_from_ptr(in_re);
+    fftp.ea_input_im    = ea_from_ptr(in_im);
+    fftp.ea_output_re   = ea_from_ptr(out_re);
+    fftp.ea_output_im   = ea_from_ptr(out_im);
+    fftp.in_blk_stride  = in_stride;
+    fftp.out_blk_stride = out_stride;
+
+    Task_manager *mgr = Task_manager::instance();
+    // The stack size is determined by accounting for the *worst case*
+    // stack requirements, which, to date, are _at least_ equal
+    // to 64 KB for the 8 K FFT (using two temporary arrays of 4 bytes
+    // per point each).
+    // Note on the input buffer size: the buffer is made twice the
+    // size of the output buffer.  This improves performance only at
+    // some lengths, notably 2048 and 4096, but does not hurt for
+    // other problem sizes.  Warning: this may change if the underlying
+    // implementation changes and should be revised as needed.
+    Task task = mgr->reserve<Fft_tag, void(std::pair<T*,T*>,std::pair<T*,T*>)>
+      (80*1024, // max stack size
+       sizeof(Fft_split_params), 
+       sizeof(complex<T>)*fftp.fft_size*2, 
+       sizeof(complex<T>)*fftp.fft_size,
+       true);
+
+    length_type spes         = mgr->num_spes();
+    length_type ffts_per_spe = num_ffts / spes;
+
+    for (length_type i = 0; i < spes && i < num_ffts; ++i)
+    {
+      // If rows don't divide evenly, give the first SPEs one extra.
+      length_type spe_ffts = (i < num_ffts % spes) ? ffts_per_spe + 1
+                                                   : ffts_per_spe;
+
+      Workblock block = task.create_workblock(spe_ffts);
+      block.set_parameters(fftp);
+      block.enqueue();
+
+      fftp.ea_input_re  += sizeof(T) * spe_ffts * in_stride;
+      fftp.ea_input_im  += sizeof(T) * spe_ffts * in_stride;
+      fftp.ea_output_re += sizeof(T) * spe_ffts * out_stride;
+      fftp.ea_output_im += sizeof(T) * spe_ffts * out_stride;
+    }
+    task.sync();
   }
-
-private:
-  aligned_array<ctype> twiddle_factors_;
 };
 
 
@@ -215,14 +323,15 @@
   {
     rtl_inout.pack    = stride_unit_align;
     rtl_inout.order   = tuple<0, 1, 2>();
-    rtl_inout.complex = cmplx_inter_fmt;
+    // Both split and interleaved supported.
     rtl_inout.align   = 16;
   }
   virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
   {
     rtl_in.pack    = rtl_out.pack    = stride_unit_align;
     rtl_in.order   = rtl_out.order   = tuple<0, 1, 2>();
-    rtl_in.complex = rtl_out.complex = cmplx_inter_fmt;
+    // Both split and interleaved supported, however in and out must match.
+    rtl_in.complex = rtl_out.complex;
     rtl_in.align   = rtl_out.align   = 16;
   }
   virtual void in_place(ctype *inout, stride_type stride, length_type length)
@@ -230,8 +339,11 @@
     assert(stride == 1);
     this->fft(inout, inout, length, this->scale_, E);
   }
-  virtual void in_place(ztype, stride_type, length_type)
+  virtual void in_place(ztype inout, stride_type stride, length_type length)
   {
+    assert(stride == 1);
+    this->fft(inout.first, inout.second, inout.first, inout.second,
+	      length, this->scale_, E);
   }
   virtual void by_reference(ctype *in, stride_type in_stride,
 			    ctype *out, stride_type out_stride,
@@ -241,10 +353,14 @@
     assert(out_stride == 1);
     this->fft(in, out, length, this->scale_, E);
   }
-  virtual void by_reference(ztype, stride_type,
-			    ztype, stride_type,
-			    length_type)
+  virtual void by_reference(ztype in, stride_type in_stride,
+			    ztype out, stride_type out_stride,
+			    length_type length)
   {
+    assert(in_stride == 1);
+    assert(out_stride == 1);
+    this->fft(in.first, in.second, out.first, out.second,
+	      length, this->scale_, E);
   }
 
 private:
@@ -308,9 +424,30 @@
       this->scale_, E, A);
   }
 
-  virtual void in_place(ztype, stride_type, stride_type,
-			length_type, length_type)
+  virtual void in_place(ztype inout,
+			stride_type r_stride, stride_type c_stride,
+			length_type rows, length_type cols)
   {
+    if (A != 0)
+    {
+      if (rows == 0) return; // Handle empty local subblock.
+      assert(rows <= this->size_[0]); // OK if rows are distributed.
+      assert(cols == this->size_[1]); // Columns must be whole.
+      assert(c_stride == 1);
+    }
+    else
+    {
+      if (cols == 0) return; // Handle empty local subblock.
+      assert(rows == this->size_[0]); // Rows must be whole.
+      assert(cols <= this->size_[1]); // OK if columns are distributed.
+      assert(r_stride == 1);
+    }
+    this->fftm(inout.first, inout.second,
+      inout.first, inout.second,
+      r_stride, c_stride,
+      r_stride, c_stride,
+      rows, cols,
+      this->scale_, E, A);
   }
 
   virtual void by_reference(ctype *in,
@@ -339,10 +476,31 @@
       rows, cols,
       this->scale_, E, A);
   }
-  virtual void by_reference(ztype, stride_type, stride_type,
-			    ztype, stride_type, stride_type,
-			    length_type, length_type)
+  virtual void by_reference(ztype in,
+			    stride_type in_r_stride, stride_type in_c_stride,
+			    ztype out,
+			    stride_type out_r_stride, stride_type out_c_stride,
+			    length_type rows, length_type cols)
   {
+    if (A != 0)
+    {
+      if (rows == 0) return; // Handle empty local subblock.
+      assert(rows <= this->size_[0]); // OK if rows are distributed.
+      assert(cols == this->size_[1]); // Columns must be whole.
+      assert(in_c_stride == 1 && out_c_stride == 1);
+    }
+    else
+    {
+      if (cols == 0) return; // Handle empty local subblock.
+      assert(rows == this->size_[0]); // Rows must be whole.
+      assert(cols <= this->size_[1]); // OK if columns are distributed.
+      assert(in_r_stride == 1 && out_r_stride == 1);
+    }
+    this->fftm(in.first, in.second, out.first, out.second, 
+      in_r_stride, in_c_stride,
+      out_r_stride, out_c_stride,
+      rows, cols,
+      this->scale_, E, A);
   }
   virtual void query_layout(Rt_layout<2> &rtl_inout)
   {
@@ -352,7 +510,7 @@
     else
       rtl_inout.order = tuple<1, 0, 2>();
     rtl_inout.pack = stride_unit_align;
-    rtl_inout.complex = cmplx_inter_fmt;
+    // Both split and interleaved supported.
     rtl_inout.align = 16;
   }
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
@@ -363,7 +521,8 @@
     else
       rtl_in.order = rtl_out.order = tuple<1, 0, 2>();
     rtl_in.pack = rtl_out.pack = stride_unit_align;
-    rtl_in.complex = rtl_out.complex = cmplx_inter_fmt;
+    // Both split and interleaved supported, however in and out must match.
+    rtl_in.complex = rtl_out.complex;
     rtl_in.align = rtl_out.align = 16;
   }
 private:
Index: src/vsip/opt/cbe/ppu/task_manager.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/task_manager.hpp	(revision 209510)
+++ src/vsip/opt/cbe/ppu/task_manager.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2007, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -65,6 +65,7 @@
       {
 	num_spes = atoi(argv[i+1]);
 	shift_argv(argc, argv, i, 2);
+	i -= 1;
       }
     }
     
@@ -105,7 +106,7 @@
 
   static Task_manager *instance_;
 
-  ALF*         alf_;
+  ALF*        alf_;
   Task        task_;
   length_type num_spes_;
 };
@@ -132,10 +133,11 @@
 DEFINE_TASK(Mult_tag, std::complex<float>(std::complex<float>, std::complex<float>), vmul_c)
 DEFINE_TASK(Mult_tag, split_float_type(split_float_type, split_float_type), vmul_split_c)
 DEFINE_TASK(Fft_tag, void(std::complex<float>, std::complex<float>), fft_c)
+DEFINE_TASK(Fft_tag, void(split_float_type, split_float_type), fft_split_c)
 DEFINE_TASK(Fastconv_tag, void(std::complex<float>, std::complex<float>), fconv_c)
 DEFINE_TASK(Fastconv_tag, void(split_float_type, split_float_type), fconv_split_c)
 DEFINE_TASK(Fastconvm_tag, void(std::complex<float>, std::complex<float>), fconvm_c)
 DEFINE_TASK(Fastconvm_tag, void(split_float_type, split_float_type), fconvm_split_c)
 DEFINE_TASK(Vmmul_tag, std::complex<float>(std::complex<float>, std::complex<float>), vmmul_c)
 DEFINE_TASK(Pwarp_tag, void(unsigned char, unsigned char), pwarp_ub)
-#endif
+#endif // VSIP_OPT_CBE_PPU_TASK_MANAGER_HPP
Index: src/vsip/opt/cbe/ppu/fastconv.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.cpp	(revision 209510)
+++ src/vsip/opt/cbe/ppu/fastconv.cpp	(working copy)
@@ -48,12 +48,10 @@
   (T* in, T* kernel, T* out, length_type rows, length_type length)
 {
   Fastconv_params params;
-  VSIP_IMPL_STATIC_ASSERT(sizeof(Fastconv_params) % 16 == 0);
 
   params.instance_id        = this->instance_id_;
   params.elements           = length;
   params.transform_kernel   = this->transform_kernel_;
-  params.ea_twiddle_factors = ea_from_ptr(this->twiddle_factors_.get());
   params.ea_kernel          = ea_from_ptr(kernel);
   params.ea_input           = ea_from_ptr(in);
   params.ea_output          = ea_from_ptr(out);
@@ -115,12 +113,10 @@
   length_type      length)
 {
   Fastconv_split_params params;
-  VSIP_IMPL_STATIC_ASSERT(sizeof(Fastconv_split_params) % 16 == 0);
 
   params.instance_id        = this->instance_id_;
   params.elements           = length;
   params.transform_kernel   = this->transform_kernel_;
-  params.ea_twiddle_factors = ea_from_ptr(this->twiddle_factors_.get());
   params.ea_kernel_re       = ea_from_ptr(kernel.first);
   params.ea_kernel_im       = ea_from_ptr(kernel.second);
   params.ea_input_re        = ea_from_ptr(in.first);
@@ -168,28 +164,7 @@
 }
 
 
-template <dimension_type D,
-          typename       T,
-	  typename       ComplexFmt>
-void
-Fastconv_base<D, T, ComplexFmt>::compute_twiddle_factors(
-  length_type length)
-{
-  typedef typename Scalar_of<T>::type stype;
 
-  unsigned int i = 0;
-  unsigned int n = length;
-  stype* W = reinterpret_cast<stype*>(this->twiddle_factors_.get());
-  W[0] = 1.0f;
-  W[1] = 0.0f;
-  for (i = 1; i < n / 4; ++i) 
-  {
-    W[2*i] = cos(i * 2*M_PI / n);
-    W[2*(n/4 - i)+1] = -W[2*i];
-  }
-}
-
-
 typedef std::complex<float> ctype;
 typedef std::pair<float*,float*> ztype;
 
@@ -197,17 +172,11 @@
 template void                                                                  \
 Fastconv_base<COEFFS_DIM, ctype, Cmplx_inter_fmt>::fconv(                      \
   ctype* in, ctype* kernel, ctype* out, length_type rows, length_type length); \
-template void                                                                  \
-Fastconv_base<COEFFS_DIM, ctype, Cmplx_inter_fmt>::compute_twiddle_factors(    \
-  length_type length);                                                         \
 template<> unsigned int                                                        \
 Fastconv_base<COEFFS_DIM, ctype, Cmplx_inter_fmt>::instance_id_counter_ = 0;   \
 template void                                                                  \
 Fastconv_base<COEFFS_DIM, ctype, Cmplx_split_fmt>::fconv(                      \
   ztype in, ztype kernel, ztype out, length_type rows, length_type length);    \
-template void                                                                  \
-Fastconv_base<COEFFS_DIM, ctype, Cmplx_split_fmt>::compute_twiddle_factors(    \
-  length_type length);                                                         \
 template<> unsigned int                                                        \
 Fastconv_base<COEFFS_DIM, ctype, Cmplx_split_fmt>::instance_id_counter_ = 0; 
 
Index: src/vsip/opt/cbe/ppu/alf.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/alf.hpp	(revision 209510)
+++ src/vsip/opt/cbe/ppu/alf.hpp	(working copy)
@@ -107,7 +107,7 @@
     Workblock block;
     int status = alf_wb_create(task_, ALF_WB_SINGLE, 1, &block.workblock_);
     if (status != 0)      
-      VSIP_IMPL_THROW(std::runtime_error("unable to create work block!"));
+      VSIP_IMPL_THROW(std::runtime_error("Task::create_workblock(single) -- alf_wb_create failed."));
     return block;
   }
   Workblock create_workblock(int times)
@@ -115,7 +115,7 @@
     Workblock block;
     int status = alf_wb_create(task_, ALF_WB_MULTI, times, &block.workblock_);
     if (status != 0)      
-      VSIP_IMPL_THROW(std::runtime_error("unable to create work block!"));
+      VSIP_IMPL_THROW(std::runtime_error("Task::create_workblock(multi) -- alf_wb_create failed."));
     return block;
   }
   void sync()
Index: src/vsip/opt/cbe/ppu/fastconv.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.hpp	(revision 209510)
+++ src/vsip/opt/cbe/ppu/fastconv.hpp	(working copy)
@@ -92,12 +92,10 @@
 public:
   Fastconv_base(length_type const input_size, bool transform_kernel)
     : size_            (input_size),
-      twiddle_factors_ (input_size / 4),
       transform_kernel_(transform_kernel),
       instance_id_     (++instance_id_counter_)
   {
     assert(rt_valid_size(this->size_));
-    compute_twiddle_factors(this->size_);
   }
 
   static bool rt_valid_size(length_type size)
@@ -157,21 +155,19 @@
 
 private:
   typedef typename Scalar_of<T>::type uT;
-  void compute_twiddle_factors(length_type length);
   void fconv(T* in, T* kernel, T* out, length_type rows, length_type length);
   void fconv(std::pair<uT*,uT*> in, std::pair<uT*,uT*> kernel,
 	     std::pair<uT*,uT*> out, length_type rows, length_type length);
 
   // Member data.
   length_type size_;
-  aligned_array<T> twiddle_factors_;
   bool transform_kernel_;
   unsigned int instance_id_;
 
   // This counter is used to give each instance of this type
   // a unique ID that is passed to the SPEs as part of the 
   // parameter block.  When an SPE sees that the ID has changed,
-  // it knows to reload the weights and twiddle factors.
+  // it knows to reload the weights.
   static unsigned int instance_id_counter_;
 };
 
Index: src/vsip/opt/cbe/fconv_params.h
===================================================================
--- src/vsip/opt/cbe/fconv_params.h	(revision 209510)
+++ src/vsip/opt/cbe/fconv_params.h	(working copy)
@@ -36,20 +36,13 @@
 #endif
 
 
-// Structures used in DMAs should be sized in multiples of 128-bits
 
-// Definitions for 'command' bitfields:
-#define RELOAD_TWIDDLE_FACTORS   (0x01)
-#define RELOAD_WEIGHTS           (0x02)
-
 typedef struct
 {
   unsigned int       instance_id;
   unsigned int       elements;
   unsigned int       transform_kernel;
-  unsigned int        pad1;
 
-  unsigned long long ea_twiddle_factors;
   unsigned long long ea_kernel;
 
   unsigned long long ea_input;
@@ -58,7 +51,6 @@
   unsigned int       kernel_stride;
   unsigned int       input_stride;
   unsigned int       output_stride;
-  unsigned int        pad2;
 } Fastconv_params;
 
 typedef struct
@@ -66,11 +58,7 @@
   unsigned int       instance_id;
   unsigned int       elements;
   unsigned int       transform_kernel;
-  unsigned int        pad1;
 
-  unsigned long long ea_twiddle_factors;
-  unsigned long long  pad2;
-
   unsigned long long ea_kernel_re;
   unsigned long long ea_kernel_im;
 
@@ -83,7 +71,6 @@
   unsigned int       kernel_stride;
   unsigned int       input_stride;
   unsigned int       output_stride;
-  unsigned int        pad3;
 } Fastconv_split_params;
 
 
Index: src/vsip/opt/cbe/spu/alf_fconv_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconv_c.c	(revision 209510)
+++ src/vsip/opt/cbe/spu/alf_fconv_c.c	(working copy)
@@ -13,46 +13,28 @@
 #include <sys/time.h>
 #include <spu_mfcio.h>
 #include <alf_accel.h>
-#include <vsip/opt/cbe/fconv_params.h>
-#include "fft_1d_r2.h"
 #include <assert.h>
+#include <cml/spu/cml.h>
+#include <cml/spu/cml_core.h>
 
+#include <vsip/opt/cbe/fconv_params.h>
+
 // These are sized for complex values, taking two floats each.  
 static float coeff[2 * VSIP_IMPL_MAX_FCONV_SIZE] 
        __attribute__ ((aligned (128)));
 
-// The twiddle factors occupy only 1/4 the space as the inputs, 
-// outputs and convolution kernels.
-static float twiddle_factors[2 * VSIP_IMPL_MAX_FCONV_SIZE / 4] 
-       __attribute__ ((aligned (128)));
-
 static unsigned int instance_id = 0;
 
-#define VEC_SIZE  (4)
 
-unsigned int log2i(unsigned int size)
-{
-  unsigned int log2_size = 0;
-  while (!(size & 1))
-  { 
-    size >>= 1;
-    log2_size++;
-  }
-  return log2_size;
-}
 
-
-void initialize(Fastconv_params* fc, void volatile* p_kernel, 
-		void volatile* p_twiddles, unsigned int n, 
-		unsigned int log2n)
+void initialize(
+  Fastconv_params* fc,
+  void*            p_kernel, 
+  fft1d_f*         obj,
+  void*            buf)
 {
   unsigned int size = fc->elements*2*sizeof(float);
 
-  // The number of twiddle factors is 1/4 the input size
-  mfc_get(p_twiddles, fc->ea_twiddle_factors, size/4, 31, 0, 0);
-  mfc_write_tag_mask(1<<31);
-  mfc_read_tag_status_all();
-
   // The kernel matches the input and output size
   mfc_get(p_kernel, fc->ea_kernel, size, 31, 0, 0);
   mfc_write_tag_mask(1<<31);
@@ -62,11 +44,7 @@
   {
     // Perform the forward FFT on the kernel, in place.  This only need 
     // be done once -- subsequent calls will utilize the same kernel.
-    vector float* inout = (vector float *)coeff;
-    vector float* W = (vector float*)twiddle_factors;
-    vector float re[n / VEC_SIZE], im[n / VEC_SIZE];
-    _fft_1d_r2_pre(re, im, inout, W, log2n);
-    _fft_1d_r2_fini(inout, re, im, W, log2n);
+    cml_ccfft1d_ip_f(obj, (float*)coeff, CML_FFT_FWD, buf);
   }
 }
 
@@ -114,71 +92,57 @@
 
 
 
-int kernel(void* context,
-	   void* params,
-	   void* input,
-	   void* output,
-	   unsigned int iter,
-	   unsigned int iter_max)
+int kernel(
+  void*        context,
+  void*        params,
+  void*        input,
+  void*        output,
+  void*        inout,
+  unsigned int iter,
+  unsigned int iter_max)
 {
+  static fft1d_f* obj;
+  static char*    buf;
+  static size_t   current_size = 0;
+
   Fastconv_params* fc = (Fastconv_params *)params;
-  unsigned int n = fc->elements;
-  unsigned int log2n = log2i(n);
-  assert(n <= VSIP_IMPL_MAX_FCONV_SIZE);
+  unsigned int fft_size = fc->elements;
+  assert(fft_size <= VSIP_IMPL_MAX_FCONV_SIZE);
 
   // Initialization establishes the weights (kernel) for the
   // convolution step and the twiddle factors for the FFTs.
   // These are loaded once per task by checking a unique
   // ID passed down from the caller.
-  if (instance_id != fc->instance_id)
+  if (iter == 0)
   {
-    instance_id = fc->instance_id;
-    initialize(fc, coeff, twiddle_factors, n, log2n);
+    if (fft_size != current_size)
+    {
+      if (obj)
+      {
+	free(buf);
+	cml_fft1d_destroy_f_alloc(obj);
+      }
+      int rt = cml_fft1d_setup_f_alloc(&obj, CML_FFT_CC, fft_size);
+      assert(rt && obj != NULL);
+      buf = (char*)memalign(16, cml_zzfft1d_buf_size_f(obj));
+      assert(buf != NULL);
+      current_size = fft_size;
+    }
+    if (instance_id != fc->instance_id)
+    {
+      instance_id = fc->instance_id;
+      initialize(fc, coeff, obj, buf);
+    }
   }
 
-  vector float* in = (vector float *)input;
-  vector float* W = (vector float*)twiddle_factors;
-  vector float* out = (vector float*)output;
+  float* in  = (float*)input;
+  float* out = (float*)output;
 
-  // Create real & imaginary working arrays
-  vector float re[n / VEC_SIZE], im[n / VEC_SIZE];
+  cml_ccfft1d_ip_f(obj, in, CML_FFT_FWD, buf);
+  cml_cvmul1_f(coeff, in, out, fft_size);
+  cml_ccfft1d_ip_f(obj, out, CML_FFT_INV, buf);
+  cml_core_rcsvmul1_f(1.f / fft_size, out, out, fft_size);
 
-
-  // Perform the forward FFT, rolling the convolution into 
-  // the last stage
-  _fft_1d_r2_pre(re, im, in, W, log2n);
-  _fft_1d_r2_fini_cvmul(out, re, im, (vector float*)coeff, W, log2n);
-
-
-  // Revert back the time domain.  
-  _fft_1d_r2_pre(re, im, out, W, log2n);
-  _fft_1d_r2_fini(out, re, im, W, log2n);
-
-
-  // Code for the inverse FFT scaling is taken from the CBE 
-  // SDK Libraries Overview and Users Guide, sec. 8.1.  
-  {
-    unsigned int i;
-    vector float *start, *end, s0, s1, e0, e1;
-    vector unsigned int mask = (vector unsigned int){-1, -1, 0, 0};
-    vector float vscale = spu_splats(1 / (float)n);
-    start = out;
-
-    // Scale the output vector and swap the order of the outputs.
-    // Note: there are two float values for each of 'n' complex values.
-    end = start + 2 * n / VEC_SIZE;
-    s0 = e1 = *start;
-    for (i = 0; i < n / VEC_SIZE; ++i) 
-    {
-      s1 = *(start + 1);
-      e0 = *(--end);
-
-      *start++ = spu_mul(spu_sel(e0, e1, mask), vscale);
-      *end = spu_mul(spu_sel(s0, s1, mask), vscale);
-      s0 = s1;
-      e1 = e0;
-    }
-  }
   return 0;
 }
 
Index: src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp
===================================================================
--- src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp	(revision 209510)
+++ src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp	(working copy)
@@ -19,6 +19,7 @@
 #include <vsip/core/acconfig.hpp>
 #include <spu_mfcio.h>
 #include <vsip/opt/cbe/pwarp_params.h>
+#include <vsip/opt/cbe/spu/alf_decls.hpp>
 
 #include <vsip/opt/simd/simd_spu.hpp>
 
@@ -26,32 +27,9 @@
 
 static unsigned char src_img[IMG_SIZE] __attribute__ ((aligned (128)));
 
-extern "C" {
-int input(
-  void*        context,
-  void*        params,
-  void*        entries,
-  unsigned int current_count,
-  unsigned int total_count);
 
-int output(
-  void*        context,
-  void*        params,
-  void*        entries,
-  unsigned int cur_iter,
-  unsigned int tot_iter);
 
-int kernel(
-  void*        context,
-  void*        params,
-  void*        input,
-  void*        output,
-  unsigned int cur_iter,
-  unsigned int tot_iter);
-}
 
-
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -718,6 +696,7 @@
   void*        params,
   void*        input,
   void*        output,
+  void*        inout,
   unsigned int cur_iter,
   unsigned int tot_iter)
 {
Index: src/vsip/opt/cbe/spu/alf_fft_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fft_c.c	(revision 209510)
+++ src/vsip/opt/cbe/spu/alf_fft_c.c	(working copy)
@@ -12,45 +12,13 @@
 
 #include <alf_accel.h>
 #include <assert.h>
+#include <spu_intrinsics.h>
+#include <cml/spu/cml.h>
+#include <cml/spu/cml_core.h>
+
 #include <vsip/core/acconfig.hpp>
-#if VSIP_CBE_SDK_VERSION == 210
-#  include <libfft.h>
-#else
-#  include <libfft_example.h>
-#endif
-#include <spu_mfcio.h>
 #include <vsip/opt/cbe/fft_params.h>
 
-// These are sized for complex values, taking two floats each.  The twiddle 
-// factors occupy only 1/4 the space as the inputs, outputs and convolution 
-// kernels.
-static volatile float twiddle_factors[MAX_FFT_1D_SIZE*2/4] __attribute__ ((aligned (128)));
-static unsigned int initialized = 0;
-
-#define VEC_SIZE  (4)
-
-unsigned int log2i(unsigned int size)
-{
-  unsigned int log2_size = 0;
-  while (!(size & 1))
-  { 
-    size >>= 1;
-    log2_size++;
-  }
-  return log2_size;
-}
-
-void initialize(Fft_params* fft, void volatile* p_twiddles, 
-		unsigned int n, unsigned int log2n)
-{
-  unsigned int size = fft->elements*2*sizeof(float);
-
-  // The number of twiddle factors is 1/4 the input size
-  mfc_get(p_twiddles, fft->ea_twiddle_factors, size/4, 31, 0, 0);
-  mfc_write_tag_mask(1<<31);
-  mfc_read_tag_status_all();
-}
-
 #define _ALF_MAX_SINGLE_DT_SIZE 16*1024
 
 int input(void*        context,
@@ -66,7 +34,7 @@
 
   // Transfer input.
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
-  unsigned long length = fft->elements;
+  unsigned long length = fft->fft_size;
   unsigned long max_length = _ALF_MAX_SINGLE_DT_SIZE / FP / sizeof(float);
   ea = fft->ea_input_buffer + current_count * FP * fft->in_blk_stride * sizeof(float);
   while (length > 0)
@@ -99,7 +67,7 @@
 
   // Transfer output.
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
-  unsigned long length = fft->elements;
+  unsigned long length = fft->fft_size;
   unsigned long max_length = _ALF_MAX_SINGLE_DT_SIZE / FP / sizeof(float);
   ea = fft->ea_output_buffer + current_count * FP * fft->out_blk_stride * sizeof(float);
   while (length > 0)
@@ -118,80 +86,69 @@
 }
 
 
-int kernel(void* context,
-	   void* params,
-	   void* input,
-	   void* output,
-	   unsigned int iter,
-	   unsigned int iter_max)
+int kernel(
+  void*        context,
+  void*        params,
+  void*        input,
+  void*        output,
+  void*        inout,
+  unsigned int iter,
+  unsigned int iter_max)
 {
-  Fft_params* fftp = (Fft_params *)params;
-  unsigned int n = fftp->elements;
-  unsigned int log2n = log2i(n);
-  assert(n <= MAX_FFT_1D_SIZE);
+  static fft1d_f* obj;
+  static char*    buf;
+  static size_t   current_size = 0;
 
+  Fft_params* fp = (Fft_params *)params;
+  size_t      fft_size = fp->fft_size;
 
-  // Initialization establishes the twiddle factors for the FFTs.
-  // These are reloaded any time the FFT size changes.
-  if (initialized != n)
+  assert(fft_size <= MAX_FFT_1D_SIZE);
+
+  if (iter == 0 && fft_size != current_size)
   {
-    initialized = n;
-    initialize(fftp, twiddle_factors, n, log2n);
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
   }
 
-  vector float* in = (vector float *)input;
-  vector float* W = (vector float *)twiddle_factors;
-  vector float* out = (vector float*)output;
+  // Handle inverse FFT explicitly so that shuffle and scale can happen
+  // in single step.
+  cml_ccfft1d_op_f(obj, (float*)input, (float*)output, CML_FFT_FWD, buf);
 
-  unsigned int const vec_size = 4; 
-
-  // Perform the FFT, 
-  //   -- 'in' may be the same as 'out'
-  fft_1d_r2(out, in, W, log2n);
-
-
-  if (fftp->direction == fwd_fft)
+  if (fp->direction == fwd_fft)
   {
-    // Forward FFT support scaling, but for efficiency, this step
-    // can be skipped for a scale factor of one.
-    if (fftp->scale != (double)1.f)
-    {
-      unsigned int i;
-      vector float *start;
-      vector float vscale = spu_splats((float)fftp->scale);
-      vector float s;
-      start = out;
-      
-      // Scale the output vector.
-      // Note: there are two float values for each of 'n' complex values.
-      for (i = 0; i < 2 * n / vec_size; ++i) 
-      {
-        s = *start;
-        *start++ = spu_mul(s, vscale);
-      }
-    }
+    if (fp->scale != (double)1.f)
+      cml_core_rcsvmul1_f(fp->scale, output, output, fft_size);
   }
   else
   {
     // Code for the inverse FFT taken from the CBE SDK Libraries
     // Overview and Users Guide, sec. 8.1.
-    unsigned int i;
-    vector float *start, *end, s0, s1, e0, e1;
+    int const vec_size = 4;
+    vector float* start = (vector float*)output;
+    vector float* end   = start + 2 * fft_size / vec_size;
+    vector float  s0, s1, e0, e1;
     vector unsigned int mask = (vector unsigned int){-1, -1, 0, 0};
-    vector float vscale = spu_splats((float)fftp->scale);
-    start = out;
+    vector float vscale = spu_splats((float)fp->scale);
+    unsigned int i;
 
     // Scale the output vector and swap the order of the outputs.
     // Note: there are two float values for each of 'n' complex values.
-    end = start + 2 * n / vec_size;
     s0 = e1 = *start;
-    for (i = 0; i < n / vec_size; ++i) 
+    for (i = 0; i < fft_size / vec_size; ++i) 
     {
       s1 = *(start + 1);
       e0 = *(--end);
 
       *start++ = spu_mul(spu_sel(e0, e1, mask), vscale);
-      *end = spu_mul(spu_sel(s0, s1, mask), vscale);
+      *end     = spu_mul(spu_sel(s0, s1, mask), vscale);
       s0 = s1;
       e1 = e0;
     }
Index: src/vsip/opt/cbe/spu/vmul_split.h
===================================================================
--- src/vsip/opt/cbe/spu/vmul_split.h	(revision 209510)
+++ src/vsip/opt/cbe/spu/vmul_split.h	(working copy)
@@ -1,242 +0,0 @@
-/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
-
-   This file is available for license from CodeSourcery, Inc. under the terms
-   of a commercial license and under the GPL.  It is not part of the VSIPL++
-   reference implementation and is not available under the BSD license.
-*/
-/** @file    vsip/opt/cbe/spu/vmul_split.c
-    @author  Jules Bergmann
-    @date    2007-02-28
-    @brief   VSIPL++ Library: Split complex vector-multiply routines.
-*/
-
-#ifndef VSIP_OPT_CBE_SPU_VMUL_SPLIT_H
-#define VSIP_OPT_CBE_SPU_VMUL_SPLIT_H
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-// Complex vector-multiply, loop unrolled by 8 version.
-
-inline void
-cvmul(
-  float* r_re,
-  float* r_im,
-  float* a_re,
-  float* a_im,
-  float* b_re,
-  float* b_im,
-  int    length)
-{
-  unsigned const vec_len = 4;
-  vector float const v_zero = {0, 0, 0, 0};
-
-  vector float* v_r_re = (vector float*)r_re;
-  vector float* v_r_im = (vector float*)r_im;
-  vector float* v_a_re = (vector float*)a_re;
-  vector float* v_a_im = (vector float*)a_im;
-  vector float* v_b_re = (vector float*)b_re;
-  vector float* v_b_im = (vector float*)b_im;
-
-  while (length >= (int)(8*vec_len))
-  {
-    vector float ar0 = *v_a_re++;
-    vector float ai0 = *v_a_im++;
-    vector float br0 = *v_b_re++;
-    vector float bi0 = *v_b_im++;
-    vector float ar1 = *v_a_re++;
-    vector float ai1 = *v_a_im++;
-    vector float br1 = *v_b_re++;
-    vector float bi1 = *v_b_im++;
-    vector float ar2 = *v_a_re++;
-    vector float ai2 = *v_a_im++;
-    vector float br2 = *v_b_re++;
-    vector float bi2 = *v_b_im++;
-    vector float ar3 = *v_a_re++;
-    vector float ai3 = *v_a_im++;
-    vector float br3 = *v_b_re++;
-    vector float bi3 = *v_b_im++;
-    vector float ar4 = *v_a_re++;
-    vector float ai4 = *v_a_im++;
-    vector float br4 = *v_b_re++;
-    vector float bi4 = *v_b_im++;
-    vector float ar5 = *v_a_re++;
-    vector float ai5 = *v_a_im++;
-    vector float br5 = *v_b_re++;
-    vector float bi5 = *v_b_im++;
-    vector float ar6 = *v_a_re++;
-    vector float ai6 = *v_a_im++;
-    vector float br6 = *v_b_re++;
-    vector float bi6 = *v_b_im++;
-    vector float ar7 = *v_a_re++;
-    vector float ai7 = *v_a_im++;
-    vector float br7 = *v_b_re++;
-    vector float bi7 = *v_b_im++;
-
-    vector float p10 = spu_nmsub(ai0, bi0, v_zero);	// -(ai*bi - 0)
-    vector float p20 = spu_mul(ai0, br0);		//  (ai*br) 
-    vector float ri0 = spu_madd(ar0, bi0, p20);		//   ar*bi + ai*br 
-    vector float rr0 = spu_madd(ar0, br0, p10);		//   ar*br - ai*bi 
-
-    vector float p11 = spu_nmsub(ai1, bi1, v_zero);	// -(ai*bi - 0)
-    vector float p21 = spu_mul(ai1, br1);		//  (ai*br)
-    vector float ri1 = spu_madd(ar1, bi1, p21);		//   ar*bi + ai*br 
-    vector float rr1 = spu_madd(ar1, br1, p11);		//   ar*br - ai*bi 
-
-    vector float p12 = spu_nmsub(ai2, bi2, v_zero);	// -(ai*bi - 0)
-    vector float p22 = spu_mul(ai2, br2);		//  (ai*br)
-    vector float ri2 = spu_madd(ar2, bi2, p22);		//   ar*bi + ai*br 
-    vector float rr2 = spu_madd(ar2, br2, p12);		//   ar*br - ai*bi 
-
-    vector float p13 = spu_nmsub(ai3, bi3, v_zero);	// -(ai*bi - 0)
-    vector float p23 = spu_mul(ai3, br3);		//  (ai*br)
-    vector float ri3 = spu_madd(ar3, bi3, p23);		//   ar*bi + ai*br 
-    vector float rr3 = spu_madd(ar3, br3, p13);		//   ar*br - ai*bi 
-
-    vector float p14 = spu_nmsub(ai4, bi4, v_zero);	// -(ai*bi - 0)
-    vector float p24 = spu_mul(ai4, br4);		//  (ai*br)
-    vector float ri4 = spu_madd(ar4, bi4, p24);		//   ar*bi + ai*br 
-    vector float rr4 = spu_madd(ar4, br4, p14);		//   ar*br - ai*bi 
-
-    vector float p15 = spu_nmsub(ai5, bi5, v_zero);	// -(ai*bi - 0)
-    vector float p25 = spu_mul(ai5, br5);		//  (ai*br)
-    vector float ri5 = spu_madd(ar5, bi5, p25);		//   ar*bi + ai*br 
-    vector float rr5 = spu_madd(ar5, br5, p15);		//   ar*br - ai*bi 
-
-    vector float p16 = spu_nmsub(ai6, bi6, v_zero);	// -(ai*bi - 0)
-    vector float p26 = spu_mul(ai6, br6);		//  (ai*br)
-    vector float ri6 = spu_madd(ar6, bi6, p26);		//   ar*bi + ai*br 
-    vector float rr6 = spu_madd(ar6, br6, p16);		//   ar*br - ai*bi 
-
-    vector float p17 = spu_nmsub(ai7, bi7, v_zero);	// -(ai*bi - 0)
-    vector float p27 = spu_mul(ai7, br7);		//  (ai*br)
-    vector float ri7 = spu_madd(ar7, bi7, p27);		//   ar*bi + ai*br 
-    vector float rr7 = spu_madd(ar7, br7, p17);		//   ar*br - ai*bi 
-
-    *v_r_re++ = rr0;
-    *v_r_im++ = ri0;
-    *v_r_re++ = rr1;
-    *v_r_im++ = ri1;
-    *v_r_re++ = rr2;
-    *v_r_im++ = ri2;
-    *v_r_re++ = rr3;
-    *v_r_im++ = ri3;
-    *v_r_re++ = rr4;
-    *v_r_im++ = ri4;
-    *v_r_re++ = rr5;
-    *v_r_im++ = ri5;
-    *v_r_re++ = rr6;
-    *v_r_im++ = ri6;
-    *v_r_re++ = rr7;
-    *v_r_im++ = ri7;
-
-    length -= 8*vec_len;
-  }
-
-  if (length)
-  {
-    a_re = (float*)v_a_re; a_im = (float*)v_a_im;
-    b_re = (float*)v_b_re; b_im = (float*)v_b_im;
-    r_re = (float*)v_r_re; r_im = (float*)v_r_im;
-    while (length--)
-    {
-      float ar = *a_re++; float ai = *a_im++;
-      float br = *b_re++; float bi = *b_im++;
-      *r_re++ = ar*br - ai*bi;
-      *r_im++ = ar*bi + ai*br;
-    }
-  }
-}
-
-
-
-// Complex vector-multiply, loop unrolled by 4 version.
-
-inline void
-cvmul_4(
-  float* r_re,
-  float* r_im,
-  float* a_re,
-  float* a_im,
-  float* b_re,
-  float* b_im,
-  int    length)
-{
-  unsigned const vec_len = 4;
-  vector float const v_zero = {0, 0, 0, 0};
-
-  vector float* v_r_re = (vector float*)r_re;
-  vector float* v_r_im = (vector float*)r_im;
-  vector float* v_a_re = (vector float*)a_re;
-  vector float* v_a_im = (vector float*)a_im;
-  vector float* v_b_re = (vector float*)b_re;
-  vector float* v_b_im = (vector float*)b_im;
-
-  while (length >= (int)(4*vec_len))
-  {
-    vector float ar0 = *v_a_re++;
-    vector float ai0 = *v_a_im++;
-    vector float br0 = *v_b_re++;
-    vector float bi0 = *v_b_im++;
-    vector float ar1 = *v_a_re++;
-    vector float ai1 = *v_a_im++;
-    vector float br1 = *v_b_re++;
-    vector float bi1 = *v_b_im++;
-    vector float ar2 = *v_a_re++;
-    vector float ai2 = *v_a_im++;
-    vector float br2 = *v_b_re++;
-    vector float bi2 = *v_b_im++;
-    vector float ar3 = *v_a_re++;
-    vector float ai3 = *v_a_im++;
-    vector float br3 = *v_b_re++;
-    vector float bi3 = *v_b_im++;
-
-    vector float p10 = spu_nmsub(ai0, bi0, v_zero);	// -(ai*bi - 0)
-    vector float p20 = spu_madd(ai0, br0, v_zero);	//  (ai*br + 0) 
-    vector float ri0 = spu_madd(ar0, bi0, p20);		//   ar*bi + ai*br 
-    vector float rr0 = spu_madd(ar0, br0, p10);		//   ar*br - ai*bi 
-
-    vector float p11 = spu_nmsub(ai1, bi1, v_zero);	// -(ai*bi - 0)
-    vector float p21 = spu_madd(ai1, br1, v_zero);	//  (ai*br + 0) 
-    vector float ri1 = spu_madd(ar1, bi1, p21);		//   ar*bi + ai*br 
-    vector float rr1 = spu_madd(ar1, br1, p11);		//   ar*br - ai*bi 
-
-    vector float p12 = spu_nmsub(ai2, bi2, v_zero);	// -(ai*bi - 0)
-    vector float p22 = spu_madd(ai2, br2, v_zero);	//  (ai*br + 0) 
-    vector float ri2 = spu_madd(ar2, bi2, p22);		//   ar*bi + ai*br 
-    vector float rr2 = spu_madd(ar2, br2, p12);		//   ar*br - ai*bi 
-
-    vector float p13 = spu_nmsub(ai3, bi3, v_zero);	// -(ai*bi - 0)
-    vector float p23 = spu_madd(ai3, br3, v_zero);	//  (ai*br + 0) 
-    vector float ri3 = spu_madd(ar3, bi3, p23);		//   ar*bi + ai*br 
-    vector float rr3 = spu_madd(ar3, br3, p13);		//   ar*br - ai*bi 
-
-    *v_r_re++ = rr0;
-    *v_r_im++ = ri0;
-    *v_r_re++ = rr1;
-    *v_r_im++ = ri1;
-    *v_r_re++ = rr2;
-    *v_r_im++ = ri2;
-    *v_r_re++ = rr3;
-    *v_r_im++ = ri3;
-
-    length -= 4*vec_len;
-  }
-
-  if (length)
-  {
-    a_re = (float*)v_a_re; a_im = (float*)v_a_im;
-    b_re = (float*)v_b_re; b_im = (float*)v_b_im;
-    r_re = (float*)v_r_re; r_im = (float*)v_r_im;
-    while (length--)
-    {
-      float ar = *a_re++; float ai = *a_im++;
-      float br = *b_re++; float bi = *b_im++;
-      *r_re++ = ar*br - ai*bi;
-      *r_im++ = ar*bi + ai*br;
-    }
-  }
-}
-
-#endif // VSIP_OPT_CBE_SPU_VMUL_SPLIT_H
Index: src/vsip/opt/cbe/spu/fft_1d.h
===================================================================
--- src/vsip/opt/cbe/spu/fft_1d.h	(revision 209510)
+++ src/vsip/opt/cbe/spu/fft_1d.h	(working copy)
@@ -1,93 +0,0 @@
-/* --------------------------------------------------------------  */
-/* (C)Copyright 2001,2006,                                         */
-/* International Business Machines Corporation,                    */
-/* Sony Computer Entertainment, Incorporated,                      */
-/* Toshiba Corporation,                                            */
-/*                                                                 */
-/* All Rights Reserved.                                            */
-/* --------------------------------------------------------------  */
-/* PROLOG END TAG zYx                                              */
-#ifndef _FFT_1D_H_
-#define _FFT_1D_H_	1
-
-#include <spu_intrinsics.h>
-#include <vec_literal.h>
-
-/* BIT_SWAP - swaps up to 16 bits of the integer _i according to the 
- *            pattern specified by _pat.
- */
-#define BIT_SWAP(_i, _pat)	  spu_extract(spu_gather(spu_shuffle(spu_maskb(_i), _pat, _pat)), 0)
-
-static vector unsigned char byte_reverse[] = {
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15), /*  0 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15), /*  1 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,4,5,6,7,8,9,10,11,12,13,15,14), /*  2 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,4,5,6,7,8,9,10,11,12,15,14,13), /*  3 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,4,5,6,7,8,9,10,11,15,14,13,12), /*  4 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,4,5,6,7,8,9,10,15,14,13,12,11), /*  5 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,4,5,6,7,8,9,15,14,13,12,11,10), /*  6 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,4,5,6,7,8,15,14,13,12,11,10,9), /*  7 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,4,5,6,7,15,14,13,12,11,10,9,8), /*  8 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,4,5,6,15,14,13,12,11,10,9,8,7), /*  9 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,4,5,15,14,13,12,11,10,9,8,7,6), /* 10 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,4,15,14,13,12,11,10,9,8,7,6,5), /* 11 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,3,15,14,13,12,11,10,9,8,7,6,5,4), /* 12 */
-  VEC_LITERAL(vector unsigned char, 0,1,2,15,14,13,12,11,10,9,8,7,6,5,4,3), /* 13 */
-  VEC_LITERAL(vector unsigned char, 0,1,15,14,13,12,11,10,9,8,7,6,5,4,3,2), /* 14 */
-  VEC_LITERAL(vector unsigned char, 0,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1), /* 15 */
-  VEC_LITERAL(vector unsigned char, 15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0), /* 16 */
-};
-
-
-#ifndef MAX_FFT_1D_SIZE
-#define MAX_FFT_1D_SIZE	8192
-#endif
-
-#ifndef INV_SQRT_2
-#define INV_SQRT_2	0.7071067811865
-#endif
-
-
-/* The following macro, FFT_1D_BUTTERFLY, performs a 4 way SIMD basic butterfly 
- * operation. The inputs are in parallel arrays (seperate real and imaginary
- * vectors). 
- * 
- *          p --------------------------> P = p + q*Wi
- *                        \      /
- *                         \    /
- *                          \  /
- *                           \/
- *                           /\
- *                          /  \
- *                         /    \
- *               ____     /      \
- *          q --| Wi |-----------------> Q = p - q*Wi
- *               ----
- */
-
-#define FFT_1D_BUTTERFLY(_P_re, _P_im, _Q_re, _Q_im, _p_re, _p_im, _q_re, _q_im, _W_re, _W_im) {	\
-  vector float _qw_re, _qw_im;										\
-													\
-  _qw_re = spu_msub(_q_re, _W_re, spu_mul(_q_im, _W_im));						\
-  _qw_im = spu_madd(_q_re, _W_im, spu_mul(_q_im, _W_re));						\
-  _P_re  = spu_add(_p_re, _qw_re);									\
-  _P_im  = spu_add(_p_im, _qw_im);									\
-  _Q_re  = spu_sub(_p_re, _qw_re);									\
-  _Q_im  = spu_sub(_p_im, _qw_im);									\
-}
-
-
-/* FFT_1D_BUTTERFLY_HI is equivalent to FFT_1D_BUTTERFLY with twiddle factors (W_im, -W_re)
- */
-#define FFT_1D_BUTTERFLY_HI(_P_re, _P_im, _Q_re, _Q_im, _p_re, _p_im, _q_re, _q_im, _W_re, _W_im) {	\
-  vector float _qw_re, _qw_im;										\
-													\
-  _qw_re = spu_madd(_q_re, _W_im, spu_mul(_q_im, _W_re));						\
-  _qw_im = spu_msub(_q_im, _W_im, spu_mul(_q_re, _W_re));						\
-  _P_re  = spu_add(_p_re, _qw_re);									\
-  _P_im  = spu_add(_p_im, _qw_im);									\
-  _Q_re  = spu_sub(_p_re, _qw_re);									\
-  _Q_im  = spu_sub(_p_im, _qw_im);									\
-}
-
-#endif /* _FFT_1D_H_ */
Index: src/vsip/opt/cbe/spu/alf_fconv_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconv_split_c.c	(revision 209510)
+++ src/vsip/opt/cbe/spu/alf_fconv_split_c.c	(working copy)
@@ -20,12 +20,12 @@
 #include <sys/time.h>
 #include <spu_mfcio.h>
 #include <alf_accel.h>
+#include <cml/spu/cml.h>
+#include <cml/spu/cml_core.h>
 
 #include <vsip/opt/cbe/fconv_params.h>
 
-#include "fft_1d_r2_split.h"
-#include "vmul_split.h"
-#include "spe_assert.h"
+#define _ALF_MAX_SINGLE_DT_SIZE 16*1024
 
 #if PERFMON
 #  include "timer.h"
@@ -48,43 +48,20 @@
 static float kernel_im[VSIP_IMPL_MAX_FCONV_SPLIT_SIZE] 
        __attribute__ ((aligned (128)));
 
-// Twiddle factors.  For N-point convolution, N/4 twiddle factors
-// are required.
-static volatile float twiddle_factors[VSIP_IMPL_MAX_FCONV_SPLIT_SIZE*2/4]
-                __attribute__ ((aligned (128)));
-
 // Instance-id.  Used to determine when new coefficients must be loaded.
 static unsigned int instance_id = 0;
 
 
 
-unsigned int log2i(unsigned int size)
-{
-  unsigned int log2_size = 0;
-  while (!(size & 1))
-  { 
-    size >>= 1;
-    log2_size++;
-  }
-  return log2_size;
-}
-
-
-
 void initialize(
   Fastconv_split_params* fc,
-  float volatile*        p_kernel_re,
-  float volatile*        p_kernel_im,
-  void volatile*         p_twiddles,
-  unsigned int           log2n)
+  float*                 p_kernel_re,
+  float*                 p_kernel_im,
+  fft1d_f*               obj,
+  void*                  buf)
 {
   unsigned int n    = fc->elements;
 
-  // The number of twiddle factors is 1/4 the input size
-  mfc_get(p_twiddles, fc->ea_twiddle_factors, (n/4)*2*sizeof(float), 31, 0, 0);
-  mfc_write_tag_mask(1<<31);
-  mfc_read_tag_status_all();
-
   // The kernel matches the input and output size
   mfc_get(p_kernel_re, fc->ea_kernel_re, n*sizeof(float), 31, 0, 0);
   mfc_write_tag_mask(1<<31);
@@ -97,19 +74,18 @@
   {
     // Perform the forward FFT on the kernel, in place.  This only need 
     // be done once -- subsequent calls will utilize the same kernel.
-    vector float* W = (vector float*)twiddle_factors;
-    _fft_1d_r2_split((vector float*)kernel_re, (vector float*)kernel_im,
-		     (vector float*)kernel_re, (vector float*)kernel_im,
-		     W, log2n);
+    cml_zzfft1d_ip_f(obj,
+		     (float*)kernel_re, (float*)kernel_im,
+		     CML_FFT_FWD, buf);
   }
 }
 
 
 
-int alf_prepare_input_list(
+int input(
   void*        context,
   void*        params,
-  void*        list_entries,
+  void*        entries,
   unsigned int current_count,
   unsigned int total_count)
 {
@@ -117,26 +93,28 @@
   (void)total_count;
 
   Fastconv_split_params* fc = (Fastconv_split_params *)params;
-  spe_assert(fc->elements * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
-  addr64 ea;
+  assert(fc->elements * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
+  alf_data_addr64_t ea;
 
   // Transfer input.
-  ALF_DT_LIST_CREATE(list_entries, 0);
-  ea.ull = fc->ea_input_re + current_count * fc->input_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+  ea = fc->ea_input_re + current_count * fc->input_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
 
-  ea.ull = fc->ea_input_im + current_count * fc->input_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ea = fc->ea_input_im + current_count * fc->input_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
 
+  ALF_ACCEL_DTL_END(entries);
+
   return 0;
 }
 
 
 
-int alf_prepare_output_list(
+int output(
   void*        context,
   void*        params,
-  void*        list_entries,
+  void*        entries,
   unsigned int current_count,
   unsigned int total_count)
 {
@@ -144,33 +122,40 @@
   (void)total_count;
 
   Fastconv_split_params* fc = (Fastconv_split_params *)params;
-  spe_assert(fc->elements * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
-  addr64 ea;
+  assert(fc->elements * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
+  alf_data_addr64_t ea;
 
   // Transfer output.
-  ALF_DT_LIST_CREATE(list_entries, 0);
-  ea.ull = fc->ea_output_re + current_count * fc->output_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
+  ea = fc->ea_output_re + current_count * fc->output_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
 
-  ea.ull = fc->ea_output_im + current_count * fc->output_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ea = fc->ea_output_im + current_count * fc->output_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
 
+  ALF_ACCEL_DTL_END(entries);
+
   return 0;
 }
 
 
 
-int alf_comp_kernel(void* context,
-		    void* params,
-                    void* input,
-                    void* output,
-                    unsigned int iter,
-                    unsigned int iter_max)
+int kernel(
+  void*        context,
+  void*        params,
+  void*        input,
+  void*        output,
+  void*        inout,
+  unsigned int iter,
+  unsigned int iter_max)
 {
+  static fft1d_f* obj;
+  static char*    buf;
+  static size_t   current_size = 0;
+
   Fastconv_split_params* fc = (Fastconv_split_params *)params;
-  unsigned int n = fc->elements;
-  unsigned int log2n = log2i(n);
-  spe_assert(n <= VSIP_IMPL_MAX_FCONV_SPLIT_SIZE);
+  unsigned int fft_size = fc->elements;
+  assert(fft_size <= VSIP_IMPL_MAX_FCONV_SPLIT_SIZE);
 
   (void)context;
   (void)iter;
@@ -187,89 +172,62 @@
   // convolution step and the twiddle factors for the FFTs.
   // These are loaded once per task by checking a unique
   // ID passed down from the caller.
-  if (instance_id != fc->instance_id)
+  if (iter == 0)
   {
-    instance_id = fc->instance_id;
-    initialize(fc, kernel_re, kernel_im, twiddle_factors, log2n);
+    if (fft_size != current_size)
+    {
+      if (obj)
+      {
+	free(buf);
+	cml_fft1d_destroy_f_alloc(obj);
+      }
+      int rt = cml_fft1d_setup_f_alloc(&obj, CML_FFT_CC, fft_size);
+      assert(rt && obj != NULL);
+      buf = (char*)memalign(16, cml_zzfft1d_buf_size_f(obj));
+      assert(buf != NULL);
+      current_size = fft_size;
+    }
+    if (instance_id != fc->instance_id)
+    {
+      instance_id = fc->instance_id;
+      initialize(fc, kernel_re, kernel_im, obj, buf);
 #if PERFMON
-    t1 = init_timer();
-    t2 = init_timer();
-    t3 = init_timer();
-    t4 = init_timer();
+      t1 = init_timer();
+      t2 = init_timer();
+      t3 = init_timer();
+      t4 = init_timer();
 #endif
+    }
   }
 
-  float*        in_re  = (float *)input  + 0 * n;
-  float*        in_im  = (float *)input  + 1 * n;
-  vector float* W      = (vector float*)twiddle_factors;
-  float *       out_re = (float*)output + 0 * n;
-  float *       out_im = (float*)output + 1 * n;
+  float*        in_re  = (float*)input  + 0 * fft_size;
+  float*        in_im  = (float*)input  + 1 * fft_size;
+  float *       out_re = (float*)output + 0 * fft_size;
+  float *       out_im = (float*)output + 1 * fft_size;
 
   // Switch to frequency space
   START_TIMER(&t1);
-  _fft_1d_r2_split((vector float*)in_re, (vector float*)in_im,
-		   (vector float*)in_re, (vector float*)in_im, W, log2n);
+  cml_zzfft1d_ip_f(obj,
+		   (float*)in_re, (float*)in_im,
+		   CML_FFT_FWD, buf);
   STOP_TIMER(&t1);
 
   // Perform convolution -- now a straight multiplication
   START_TIMER(&t2);
-  cvmul(out_re, out_im, kernel_re, kernel_im, in_re, in_im, n);
+  cml_zvmul1_f(kernel_re, kernel_im, in_re, in_im, out_re, out_im, fft_size);
   STOP_TIMER(&t2);
 
   // Revert back the time domain
   START_TIMER(&t3);
-  _fft_1d_r2_split((vector float*)out_im, (vector float*)out_re,
-		   (vector float*)out_im, (vector float*)out_re, W, log2n);
+  cml_zzfft1d_ip_f(obj,
+		   (float*)out_re, (float*)out_im,
+		   CML_FFT_INV, buf);
   STOP_TIMER(&t3);
 
   // Scale by 1/n.
   START_TIMER(&t4);
-  {
-    vector float vscale = spu_splats(1 / (float)n);
-    vector float* v_out_re = (vector float*)out_re;
-    vector float* v_out_im = (vector float*)out_im;
-
-    unsigned int i;
-    for (i=0; i<n; i+=16*4)
-    {
-      v_out_re[0] = spu_mul(v_out_re[0], vscale);
-      v_out_re[1] = spu_mul(v_out_re[1], vscale);
-      v_out_re[2] = spu_mul(v_out_re[2], vscale);
-      v_out_re[3] = spu_mul(v_out_re[3], vscale);
-      v_out_re[4] = spu_mul(v_out_re[4], vscale);
-      v_out_re[5] = spu_mul(v_out_re[5], vscale);
-      v_out_re[6] = spu_mul(v_out_re[6], vscale);
-      v_out_re[7] = spu_mul(v_out_re[7], vscale);
-      v_out_re[8] = spu_mul(v_out_re[8], vscale);
-      v_out_re[9] = spu_mul(v_out_re[9], vscale);
-      v_out_re[10] = spu_mul(v_out_re[10], vscale);
-      v_out_re[11] = spu_mul(v_out_re[11], vscale);
-      v_out_re[12] = spu_mul(v_out_re[12], vscale);
-      v_out_re[13] = spu_mul(v_out_re[13], vscale);
-      v_out_re[14] = spu_mul(v_out_re[14], vscale);
-      v_out_re[15] = spu_mul(v_out_re[15], vscale);
-
-      v_out_im[0] = spu_mul(v_out_im[0], vscale);
-      v_out_im[1] = spu_mul(v_out_im[1], vscale);
-      v_out_im[2] = spu_mul(v_out_im[2], vscale);
-      v_out_im[3] = spu_mul(v_out_im[3], vscale);
-      v_out_im[4] = spu_mul(v_out_im[4], vscale);
-      v_out_im[5] = spu_mul(v_out_im[5], vscale);
-      v_out_im[6] = spu_mul(v_out_im[6], vscale);
-      v_out_im[7] = spu_mul(v_out_im[7], vscale);
-      v_out_im[8] = spu_mul(v_out_im[8], vscale);
-      v_out_im[9] = spu_mul(v_out_im[9], vscale);
-      v_out_im[10] = spu_mul(v_out_im[10], vscale);
-      v_out_im[11] = spu_mul(v_out_im[11], vscale);
-      v_out_im[12] = spu_mul(v_out_im[12], vscale);
-      v_out_im[13] = spu_mul(v_out_im[13], vscale);
-      v_out_im[14] = spu_mul(v_out_im[14], vscale);
-      v_out_im[15] = spu_mul(v_out_im[15], vscale);
-
-      v_out_re += 16;
-      v_out_im += 16;
-    }
-  }
+  cml_core_rzsvmul1_f(1.f / fft_size, out_re, out_im, out_re, out_im,
+		      fft_size);
   STOP_TIMER(&t4);
 
 #if PERFMON
@@ -295,3 +253,9 @@
 
   return 0;
 }
+
+ALF_ACCEL_EXPORT_API_LIST_BEGIN
+  ALF_ACCEL_EXPORT_API ("input", input);
+  ALF_ACCEL_EXPORT_API ("output", output); 
+  ALF_ACCEL_EXPORT_API ("kernel", kernel);
+ALF_ACCEL_EXPORT_API_LIST_END
Index: src/vsip/opt/cbe/spu/fft_1d_r2.h
===================================================================
--- src/vsip/opt/cbe/spu/fft_1d_r2.h	(revision 209510)
+++ src/vsip/opt/cbe/spu/fft_1d_r2.h	(working copy)
@@ -1,751 +0,0 @@
-/* --------------------------------------------------------------  */
-/* (C)Copyright 2001,2006,                                         */
-/* International Business Machines Corporation,                    */
-/* Sony Computer Entertainment, Incorporated,                      */
-/* Toshiba Corporation,                                            */
-/*                                                                 */
-/* All Rights Reserved.                                            */
-/* --------------------------------------------------------------  */
-/* PROLOG END TAG zYx                                              */
-#ifndef _FFT_1D_R2_H_
-#define _FFT_1D_R2_H_	1
-
-#include <vec_literal.h>
-#include "fft_1d.h"
-
-/* CSL: Based on the original Cell SDK FFT library, this file has
-   been modified as follows:
-
-   - The function fft_1d_r2 is now split into two separate
-     routines:
-
-     fft_1d_r2_pre()  Performs all but the last (log2(N)'th) 
-                      stage, leaving results split into 
-		      separate real and imaginary arrays.
-
-     fft_1d_r2_fini() Performs the last stage, reordering the
-                      output into an interleaved arra as part 
-		      of the final step.
-
-   - A new routine has been added to fuse two of the three
-     operations needed for fast convolution:
-
-     fft_1d_r2_fini_cvmul()  Combines the complex vector-
-                             matrix multiply with the last
-			     stage.  
-
-   2007-02-25 DM
-*/
-
-
-/* fft_1d_r2
- * ---------
- * Performs a single precision, complex Fast Fourier Transform using 
- * the DFT (Discrete Fourier Transform) with radix-2 decimation in time. 
- * The input <in> is an array of complex numbers of length (1<<log2_size)
- * entries. The result is returned in the array of complex numbers specified
- * by <out>. Note: This routine can support an in-place transformation
- * by specifying <in> and <out> to be the same array.
- *
- * This implementation utilizes the Cooley-Tukey algorithm consisting 
- * of <log2_size> stages. The basic operation is the butterfly.
- *
- *          p --------------------------> P = p + q*Wi
- *                        \      /
- *                         \    /
- *                          \  /
- *                           \/
- *                           /\
- *                          /  \
- *                         /    \
- *               ____     /      \
- *          q --| Wi |-----------------> Q = p - q*Wi
- *               ----
- *
- * This routine also requires pre-computed twiddle values, W. W is an
- * array of single precision complex numbers of length 1<<(log2_size-2) 
- * and is computed as follows:
- *
- *	for (i=0; i<n/4; i++)
- *	    W[i].real =  cos(i * 2*PI/n);
- *	    W[i].imag = -sin(i * 2*PI/n);
- *      }
- *
- * This array actually only contains the first half of the twiddle
- * factors. Due for symmetry, the second half of the twiddle factors
- * are implied and equal:
- *
- *	for (i=0; i<n/4; i++)
- *	    W[i+n/4].real =  W[i].imag =  sin(i * 2*PI/n);
- *	    W[i+n/4].imag = -W[i].real = -cos(i * 2*PI/n);
- *      }
- *
- * Further symmetry allows one to generate the twiddle factor table 
- * using half the number of trig computations as follows:
- *
- *      W[0].real = 1.0;
- *      W[0].imag = 0.0;
- *	for (i=1; i<n/4; i++)
- *	    W[i].real =  cos(i * 2*PI/n);
- *	    W[n/4 - i].imag = -W[i].real;
- *      }
- *
- * The complex numbers are packed into quadwords as follows:
- *
- *    quadword			      complex
- *  array element                   array elements
- *             -----------------------------------------------------
- *       i    |  real 2*i   |  imag 2*i  | real 2*i+1  | imag 2*i+1 | 
- *             -----------------------------------------------------
- *
- */
-
-
-void 
-_fft_1d_r2_pre(vector float *out_re, vector float *out_im, vector float *in, vector float *W, int log2_size)
-{
-  int i, j, k;
-  int stage, offset;
-  int i_rev;
-  int n, n_2, n_4, n_8, n_16, n_3_16;
-  int w_stride, w_2stride, w_3stride, w_4stride;
-  int stride, stride_2, stride_4, stride_3_4;
-  vector float *W0, *W1, *W2, *W3;
-  vector float *re0, *re1, *re2, *re3;
-  vector float *im0, *im1, *im2, *im3;
-  vector float *in0, *in1, *in2, *in3, *in4, *in5, *in6, *in7;
-  vector float tmp0, tmp1;
-  vector float w0_re, w0_im;
-  vector float w0, w1, w2, w3;
-  vector float src_lo0, src_lo1, src_lo2, src_lo3;
-  vector float src_hi0, src_hi1, src_hi2, src_hi3;
-  vector float dst_lo0, dst_lo1, dst_lo2, dst_lo3;
-  vector float dst_hi0, dst_hi1, dst_hi2, dst_hi3;
-  vector float re_lo0,  re_lo1,  re_lo2,  re_lo3;
-  vector float im_lo0,  im_lo1,  im_lo2,  im_lo3;
-  vector float re_hi0,  re_hi1,  re_hi2,  re_hi3;
-  vector float im_hi0,  im_hi1,  im_hi2,  im_hi3;
-  vector float pq_lo0,  pq_lo1,  pq_lo2,  pq_lo3;
-  vector float pq_hi0,  pq_hi1,  pq_hi2,  pq_hi3;
-  vector float ppmm = VEC_LITERAL(vector float, 1.0f,  1.0f, -1.0f, -1.0f);
-  vector float pmmp = VEC_LITERAL(vector float, 1.0f, -1.0f, -1.0f,  1.0f);
-  vector unsigned char reverse;
-  vector unsigned char shuf_lo = VEC_LITERAL(vector unsigned char,
-					     0,  1, 2, 3,  4, 5, 6, 7,
-					     16,17,18,19, 20,21,22,23);
-  vector unsigned char shuf_hi = VEC_LITERAL(vector unsigned char,
-					     8,  9,10,11, 12,13,14,15,
-					     24,25,26,27, 28,29,30,31);
-  vector unsigned char shuf_0202 = VEC_LITERAL(vector unsigned char,
-					       0, 1, 2, 3,  8, 9,10,11,
-					       0, 1, 2, 3,  8, 9,10,11);
-  vector unsigned char shuf_1313 = VEC_LITERAL(vector unsigned char,
-					       4, 5, 6, 7, 12,13,14,15,
-					       4, 5, 6, 7, 12,13,14,15);
-  vector unsigned char shuf_0303 = VEC_LITERAL(vector unsigned char, 
-					       0, 1, 2, 3, 12,13,14,15,
-					       0, 1, 2, 3, 12,13,14,15);
-  vector unsigned char shuf_1212 = VEC_LITERAL(vector unsigned char,
-					       4, 5, 6, 7,  8, 9,10,11,
-					       4, 5, 6, 7,  8, 9,10,11);
-  vector unsigned char shuf_0415 = VEC_LITERAL(vector unsigned char,
-					       0, 1, 2, 3, 16,17,18,19,
-					       4, 5, 6, 7, 20,21,22,23);
-  vector unsigned char shuf_2637 = VEC_LITERAL(vector unsigned char,
-					       8, 9,10,11, 24,25,26,27,
-					       12,13,14,15,28,29,30,31);
-  
-  n = 1 << log2_size;
-  n_2  = n >> 1;
-  n_4  = n >> 2;
-  n_8  = n >> 3;
-  n_16 = n >> 4;
-
-  n_3_16 = n_8 + n_16;
-
-
-  reverse = byte_reverse[log2_size];
-
-  /* Perform the first 3 stages of the FFT. These stages differs from 
-   * other stages in that the inputs are unscrambled and the data is 
-   * reformated into parallel arrays (ie, seperate real and imaginary
-   * arrays). The term "unscramble" means the bit address reverse the 
-   * data array. In addition, the first three stages have simple twiddle
-   * weighting factors.
-   *		stage 1: (1, 0)
-   *            stage 2: (1, 0) and (0, -1)
-   *		stage 3: (1, 0), (0.707, -0.707), (0, -1), (-0.707, -0.707)
-   *
-   * The arrays are processed as two halves, simultaneously. The lo (first 
-   * half) and hi (second half). This is done because the scramble 
-   * shares source value between each half of the output arrays.
-   */
-  i = 0;
-  i_rev = 0;
-
-  in0 = in;
-  in1 = in + n_8;
-  in2 = in + n_16;
-  in3 = in + n_3_16;  
-
-  in4 = in  + n_4;
-  in5 = in1 + n_4;
-  in6 = in2 + n_4;
-  in7 = in3 + n_4;
-
-  re0 = out_re;
-  re1 = out_re + n_8;
-  im0 = out_im;
-  im1 = out_im + n_8;
-
-  w0_re = VEC_LITERAL(vector float, 1.0f,  INV_SQRT_2,  0.0f, -INV_SQRT_2);
-  w0_im = VEC_LITERAL(vector float, 0.0f, -INV_SQRT_2, -1.0f, -INV_SQRT_2);
-      
-  do {
-    src_lo0 = in0[i_rev];
-    src_lo1 = in1[i_rev];
-    src_lo2 = in2[i_rev];
-    src_lo3 = in3[i_rev];
-
-    src_hi0 = in4[i_rev];
-    src_hi1 = in5[i_rev];
-    src_hi2 = in6[i_rev];
-    src_hi3 = in7[i_rev];
-
-    /* Perform scramble.
-     */
-    dst_lo0 = spu_shuffle(src_lo0, src_hi0, shuf_lo);
-    dst_hi0 = spu_shuffle(src_lo0, src_hi0, shuf_hi);
-    dst_lo1 = spu_shuffle(src_lo1, src_hi1, shuf_lo);
-    dst_hi1 = spu_shuffle(src_lo1, src_hi1, shuf_hi);
-    dst_lo2 = spu_shuffle(src_lo2, src_hi2, shuf_lo);
-    dst_hi2 = spu_shuffle(src_lo2, src_hi2, shuf_hi);
-    dst_lo3 = spu_shuffle(src_lo3, src_hi3, shuf_lo);
-    dst_hi3 = spu_shuffle(src_lo3, src_hi3, shuf_hi);
-
-    /* Perform the stage 1 butterfly. The multiplier constant, ppmm,
-     * is used to control the sign of the operands since a single
-     * quadword contains both of P and Q valule of the butterfly.
-     */
-    pq_lo0 = spu_madd(ppmm, dst_lo0, spu_rlqwbyte(dst_lo0, 8));
-    pq_hi0 = spu_madd(ppmm, dst_hi0, spu_rlqwbyte(dst_hi0, 8));
-    pq_lo1 = spu_madd(ppmm, dst_lo1, spu_rlqwbyte(dst_lo1, 8));
-    pq_hi1 = spu_madd(ppmm, dst_hi1, spu_rlqwbyte(dst_hi1, 8));
-    pq_lo2 = spu_madd(ppmm, dst_lo2, spu_rlqwbyte(dst_lo2, 8));
-    pq_hi2 = spu_madd(ppmm, dst_hi2, spu_rlqwbyte(dst_hi2, 8));
-    pq_lo3 = spu_madd(ppmm, dst_lo3, spu_rlqwbyte(dst_lo3, 8));
-    pq_hi3 = spu_madd(ppmm, dst_hi3, spu_rlqwbyte(dst_hi3, 8));
-
-    /* Perfrom the stage 2 butterfly. For this stage, the 
-     * inputs pq are still interleaved (p.real, p.imag, q.real, 
-     * q.imag), so we must first re-order the data into 
-     * parallel arrays as well as perform the reorder 
-     * associated with the twiddle W[n/4], which equals
-     * (0, -1). 
-     *
-     *	ie. (A, B) * (0, -1) => (B, -A)
-     */
-    re_lo0 = spu_madd(ppmm, 
-		      spu_shuffle(pq_lo1, pq_lo1, shuf_0303),
-		      spu_shuffle(pq_lo0, pq_lo0, shuf_0202));
-    im_lo0 = spu_madd(pmmp, 
-		      spu_shuffle(pq_lo1, pq_lo1, shuf_1212),
-		      spu_shuffle(pq_lo0, pq_lo0, shuf_1313));
-
-    re_lo1 = spu_madd(ppmm, 
-		      spu_shuffle(pq_lo3, pq_lo3, shuf_0303),
-		      spu_shuffle(pq_lo2, pq_lo2, shuf_0202));
-    im_lo1 = spu_madd(pmmp, 
-		      spu_shuffle(pq_lo3, pq_lo3, shuf_1212),
-		      spu_shuffle(pq_lo2, pq_lo2, shuf_1313));
-
-
-    re_hi0 = spu_madd(ppmm, 
-		      spu_shuffle(pq_hi1, pq_hi1, shuf_0303),
-		      spu_shuffle(pq_hi0, pq_hi0, shuf_0202));
-    im_hi0 = spu_madd(pmmp, 
-		       spu_shuffle(pq_hi1, pq_hi1, shuf_1212),
-		       spu_shuffle(pq_hi0, pq_hi0, shuf_1313));
-
-    re_hi1 = spu_madd(ppmm, 
-		      spu_shuffle(pq_hi3, pq_hi3, shuf_0303),
-		      spu_shuffle(pq_hi2, pq_hi2, shuf_0202));
-    im_hi1 = spu_madd(pmmp, 
-		      spu_shuffle(pq_hi3, pq_hi3, shuf_1212),
-		      spu_shuffle(pq_hi2, pq_hi2, shuf_1313));
-
-
-    /* Perform stage 3 butterfly.
-     */
-    FFT_1D_BUTTERFLY(re0[0], im0[0], re0[1], im0[1], re_lo0, im_lo0, re_lo1, im_lo1, w0_re, w0_im);
-    FFT_1D_BUTTERFLY(re1[0], im1[0], re1[1], im1[1], re_hi0, im_hi0, re_hi1, im_hi1, w0_re, w0_im);
-
-    re0 += 2;
-    re1 += 2;
-    im0 += 2; 
-    im1 += 2;
-    
-    i += 8;
-    i_rev = BIT_SWAP(i, reverse) / 2;
-  } while (i < n_2);
-
-  /* Process stages 4 to log2_size-2
-   */
-  for (stage=4, stride=4; stage<log2_size-1; stage++, stride += stride) {
-    w_stride  = n_2 >> stage;
-    w_2stride = n   >> stage;
-    w_3stride = w_stride +  w_2stride;
-    w_4stride = w_2stride + w_2stride;
-
-    W0 = W;
-    W1 = W + w_stride;
-    W2 = W + w_2stride;
-    W3 = W + w_3stride;
-
-    stride_2 = stride >> 1;
-    stride_4 = stride >> 2;
-    stride_3_4 = stride_2 + stride_4;
-
-    re0 = out_re;              im0 = out_im;
-    re1 = out_re + stride_2;   im1 = out_im + stride_2;   
-    re2 = out_re + stride_4;   im2 = out_im + stride_4;   
-    re3 = out_re + stride_3_4; im3 = out_im + stride_3_4;   
-
-    for (i=0, offset=0; i<stride_4; i++, offset += w_4stride) {
-      /* Compute the twiddle factors
-       */
-      w0 = W0[offset];
-      w1 = W1[offset];
-      w2 = W2[offset];
-      w3 = W3[offset];
-
-      tmp0 = spu_shuffle(w0, w2, shuf_0415);
-      tmp1 = spu_shuffle(w1, w3, shuf_0415);
-
-      w0_re = spu_shuffle(tmp0, tmp1, shuf_0415);
-      w0_im = spu_shuffle(tmp0, tmp1, shuf_2637);
-
-      j = i;
-      k = i + stride;
-      do {
-	re_lo0 = re0[j]; im_lo0 = im0[j];
-	re_lo1 = re1[j]; im_lo1 = im1[j];
-
-	re_hi0 = re2[j]; im_hi0 = im2[j];
-	re_hi1 = re3[j]; im_hi1 = im3[j];
-
-	re_lo2 = re0[k]; im_lo2 = im0[k];
-	re_lo3 = re1[k]; im_lo3 = im1[k];
-
-	re_hi2 = re2[k]; im_hi2 = im2[k];
-	re_hi3 = re3[k]; im_hi3 = im3[k];
-
-	FFT_1D_BUTTERFLY   (re0[j], im0[j], re1[j], im1[j], re_lo0, im_lo0, re_lo1, im_lo1, w0_re, w0_im);
-	FFT_1D_BUTTERFLY_HI(re2[j], im2[j], re3[j], im3[j], re_hi0, im_hi0, re_hi1, im_hi1, w0_re, w0_im);
-
-	FFT_1D_BUTTERFLY   (re0[k], im0[k], re1[k], im1[k], re_lo2, im_lo2, re_lo3, im_lo3, w0_re, w0_im);
-	FFT_1D_BUTTERFLY_HI(re2[k], im2[k], re3[k], im3[k], re_hi2, im_hi2, re_hi3, im_hi3, w0_re, w0_im);
-
-	j += 2 * stride;
-	k += 2 * stride;
-      } while (j < n_4);
-    }
-  }
-
-  /* Process stage log2_size-1. This is identical to the stage processing above
-   * except for this stage the inner loop is only executed once so it is removed
-   * entirely.
-   */
-  w_stride  = n_2 >> stage;
-  w_2stride = n   >> stage;
-  w_3stride = w_stride +  w_2stride;
-  w_4stride = w_2stride + w_2stride;
-
-  stride_2 = stride >> 1;
-  stride_4 = stride >> 2;
-
-  stride_3_4 = stride_2 + stride_4;
-
-  re0 = out_re;              im0 = out_im;
-  re1 = out_re + stride_2;   im1 = out_im + stride_2;   
-  re2 = out_re + stride_4;   im2 = out_im + stride_4;   
-  re3 = out_re + stride_3_4; im3 = out_im + stride_3_4;   
-
-  for (i=0, offset=0; i<stride_4; i++, offset += w_4stride) {
-    /* Compute the twiddle factors
-     */
-    w0 = W[offset];
-    w1 = W[offset + w_stride];
-    w2 = W[offset + w_2stride];
-    w3 = W[offset + w_3stride];
-
-    tmp0 = spu_shuffle(w0, w2, shuf_0415);
-    tmp1 = spu_shuffle(w1, w3, shuf_0415);
-
-    w0_re = spu_shuffle(tmp0, tmp1, shuf_0415);
-    w0_im = spu_shuffle(tmp0, tmp1, shuf_2637);
-
-    j = i;
-    k = i + stride;
-
-    re_lo0 = re0[j]; im_lo0 = im0[j];
-    re_lo1 = re1[j]; im_lo1 = im1[j];
-
-    re_hi0 = re2[j]; im_hi0 = im2[j];
-    re_hi1 = re3[j]; im_hi1 = im3[j];
-
-    re_lo2 = re0[k]; im_lo2 = im0[k];
-    re_lo3 = re1[k]; im_lo3 = im1[k];
-
-    re_hi2 = re2[k]; im_hi2 = im2[k];
-    re_hi3 = re3[k]; im_hi3 = im3[k];
-      
-    FFT_1D_BUTTERFLY   (re0[j], im0[j], re1[j], im1[j], re_lo0, im_lo0, re_lo1, im_lo1, w0_re, w0_im);
-    FFT_1D_BUTTERFLY_HI(re2[j], im2[j], re3[j], im3[j], re_hi0, im_hi0, re_hi1, im_hi1, w0_re, w0_im);
-
-    FFT_1D_BUTTERFLY   (re0[k], im0[k], re1[k], im1[k], re_lo2, im_lo2, re_lo3, im_lo3, w0_re, w0_im);
-    FFT_1D_BUTTERFLY_HI(re2[k], im2[k], re3[k], im3[k], re_hi2, im_hi2, re_hi3, im_hi3, w0_re, w0_im);
-  }
-}
-
-
-inline void 
-_fft_1d_r2_fini(vector float *out, vector float *in_re, vector float *in_im, 
-		vector float *W, int log2_size)
-{
-  int i;
-  int n, n_2, n_4, n_8, n_16, n_3_16;
-  vector float *re0, *re1, *re2, *re3;
-  vector float *im0, *im1, *im2, *im3;
-  vector float *out0, *out1, *out2, *out3;
-  vector float w0_re, w0_im, w1_re, w1_im;
-  vector float w0, w1, w2, w3;
-  vector float out_re_lo0, out_re_lo1, out_re_lo2, out_re_lo3;
-  vector float out_im_lo0, out_im_lo1, out_im_lo2, out_im_lo3;
-  vector float out_re_hi0, out_re_hi1, out_re_hi2, out_re_hi3;
-  vector float out_im_hi0, out_im_hi1, out_im_hi2, out_im_hi3;
-  vector float re_lo0,  re_lo1,  re_lo2,  re_lo3;
-  vector float im_lo0,  im_lo1,  im_lo2,  im_lo3;
-  vector float re_hi0,  re_hi1,  re_hi2,  re_hi3;
-  vector float im_hi0,  im_hi1,  im_hi2,  im_hi3;
-  vector unsigned char shuf_0415 = VEC_LITERAL(vector unsigned char,
-					       0, 1, 2, 3, 16,17,18,19,
-					       4, 5, 6, 7, 20,21,22,23);
-  vector unsigned char shuf_2637 = VEC_LITERAL(vector unsigned char,
-					       8, 9,10,11, 24,25,26,27,
-					       12,13,14,15,28,29,30,31);
-  vector unsigned char shuf_0246 = VEC_LITERAL(vector unsigned char,
-					       0, 1, 2, 3,  8, 9,10,11,
-					       16,17,18,19,24,25,26,27);
-  vector unsigned char shuf_1357 = VEC_LITERAL(vector unsigned char,
-					       4, 5, 6, 7, 12,13,14,15,
-					       20,21,22,23,28,29,30,31);
-  
-  n = 1 << log2_size;
-  n_2  = n >> 1;
-  n_4  = n >> 2;
-  n_8  = n >> 3;
-  n_16 = n >> 4;
-
-  n_3_16 = n_8 + n_16;
-
-  /* Process the final stage (stage log2_size). For this stage, 
-   * reformat the data from parallel arrays back into 
-   * interleaved arrays,storing the result into <in>.
-   *
-   * This loop has been manually unrolled by 2 to improve 
-   * dual issue rates and reduce stalls. This unrolling
-   * forces a minimum FFT size of 32.
-   */
-  re0 = in_re;
-  re1 = in_re + n_8;
-  re2 = in_re + n_16;
-  re3 = in_re + n_3_16;
-
-  im0 = in_im;
-  im1 = in_im + n_8;
-  im2 = in_im + n_16;
-  im3 = in_im + n_3_16;
-
-  out0 = out;
-  out1 = out + n_4;
-  out2 = out + n_8;
-  out3 = out1 + n_8;
-
-  i = n_16;
-
-  do {
-    /* Fetch the twiddle factors
-     */
-    w0 = W[0];
-    w1 = W[1];
-    w2 = W[2];
-    w3 = W[3];
-
-    W += 4;
-
-    w0_re = spu_shuffle(w0, w1, shuf_0246);
-    w0_im = spu_shuffle(w0, w1, shuf_1357);
-    w1_re = spu_shuffle(w2, w3, shuf_0246);
-    w1_im = spu_shuffle(w2, w3, shuf_1357);
-
-    /* Fetch the butterfly inputs, reals and imaginaries
-     */
-    re_lo0 = re0[0]; im_lo0 = im0[0];
-    re_lo1 = re1[0]; im_lo1 = im1[0];
-    re_lo2 = re0[1]; im_lo2 = im0[1];
-    re_lo3 = re1[1]; im_lo3 = im1[1];
-
-    re_hi0 = re2[0]; im_hi0 = im2[0];
-    re_hi1 = re3[0]; im_hi1 = im3[0];
-    re_hi2 = re2[1]; im_hi2 = im2[1];
-    re_hi3 = re3[1]; im_hi3 = im3[1];
-
-    re0 += 2; im0 += 2;
-    re1 += 2; im1 += 2;
-    re2 += 2; im2 += 2;
-    re3 += 2; im3 += 2;
-
-    /* Perform the butterflys
-     */
-    FFT_1D_BUTTERFLY   (out_re_lo0, out_im_lo0, out_re_lo1, out_im_lo1, re_lo0, im_lo0, re_lo1, im_lo1, w0_re, w0_im);
-    FFT_1D_BUTTERFLY   (out_re_lo2, out_im_lo2, out_re_lo3, out_im_lo3, re_lo2, im_lo2, re_lo3, im_lo3, w1_re, w1_im);
-
-    FFT_1D_BUTTERFLY_HI(out_re_hi0, out_im_hi0, out_re_hi1, out_im_hi1, re_hi0, im_hi0, re_hi1, im_hi1, w0_re, w0_im);
-    FFT_1D_BUTTERFLY_HI(out_re_hi2, out_im_hi2, out_re_hi3, out_im_hi3, re_hi2, im_hi2, re_hi3, im_hi3, w1_re, w1_im);
-
-    /* Interleave the results and store them into the output buffers (ie,
-     * the original input buffers.
-     */
-    out0[0] = spu_shuffle(out_re_lo0, out_im_lo0, shuf_0415);
-    out0[1] = spu_shuffle(out_re_lo0, out_im_lo0, shuf_2637);
-    out0[2] = spu_shuffle(out_re_lo2, out_im_lo2, shuf_0415);
-    out0[3] = spu_shuffle(out_re_lo2, out_im_lo2, shuf_2637);
-
-    out1[0] = spu_shuffle(out_re_lo1, out_im_lo1, shuf_0415);
-    out1[1] = spu_shuffle(out_re_lo1, out_im_lo1, shuf_2637);
-    out1[2] = spu_shuffle(out_re_lo3, out_im_lo3, shuf_0415);
-    out1[3] = spu_shuffle(out_re_lo3, out_im_lo3, shuf_2637);
-
-    out2[0] = spu_shuffle(out_re_hi0, out_im_hi0, shuf_0415);
-    out2[1] = spu_shuffle(out_re_hi0, out_im_hi0, shuf_2637);
-    out2[2] = spu_shuffle(out_re_hi2, out_im_hi2, shuf_0415);
-    out2[3] = spu_shuffle(out_re_hi2, out_im_hi2, shuf_2637);
-
-    out3[0] = spu_shuffle(out_re_hi1, out_im_hi1, shuf_0415);
-    out3[1] = spu_shuffle(out_re_hi1, out_im_hi1, shuf_2637);
-    out3[2] = spu_shuffle(out_re_hi3, out_im_hi3, shuf_0415);
-    out3[3] = spu_shuffle(out_re_hi3, out_im_hi3, shuf_2637);
-
-    out0 += 4;
-    out1 += 4;
-    out2 += 4;
-    out3 += 4;
-
-    i -= 2;
-  } while (i);
-}
-
-
-inline void 
-_fft_1d_r2_fini_cvmul(vector float *out, vector float *in_re, vector float *in_im, 
-		      vector float* kernel, vector float *W, int log2_size)
-{
-  int i;
-  int n, n_2, n_4, n_8, n_16, n_3_16;
-  vector float *re0, *re1, *re2, *re3;
-  vector float *im0, *im1, *im2, *im3;
-  vector float *out0, *out1, *out2, *out3;
-  vector float *k0, *k1, *k2, *k3;
-  vector float w0_re, w0_im, w1_re, w1_im;
-  vector float w0, w1, w2, w3;
-  vector float out_re_lo0, out_re_lo1, out_re_lo2, out_re_lo3;
-  vector float out_im_lo0, out_im_lo1, out_im_lo2, out_im_lo3;
-  vector float out_re_hi0, out_re_hi1, out_re_hi2, out_re_hi3;
-  vector float out_im_hi0, out_im_hi1, out_im_hi2, out_im_hi3;
-  vector float re_lo0,  re_lo1,  re_lo2,  re_lo3;
-  vector float im_lo0,  im_lo1,  im_lo2,  im_lo3;
-  vector float re_hi0,  re_hi1,  re_hi2,  re_hi3;
-  vector float im_hi0,  im_hi1,  im_hi2,  im_hi3;
-  vector unsigned char shuf_0415 = VEC_LITERAL(vector unsigned char,
-					       0, 1, 2, 3, 16,17,18,19,
-					       4, 5, 6, 7, 20,21,22,23);
-  vector unsigned char shuf_2637 = VEC_LITERAL(vector unsigned char,
-					       8, 9,10,11, 24,25,26,27,
-					       12,13,14,15,28,29,30,31);
-  vector unsigned char shuf_0246 = VEC_LITERAL(vector unsigned char,
-					       0, 1, 2, 3,  8, 9,10,11,
-					       16,17,18,19,24,25,26,27);
-  vector unsigned char shuf_1357 = VEC_LITERAL(vector unsigned char,
-					       4, 5, 6, 7, 12,13,14,15,
-					       20,21,22,23,28,29,30,31);
-  
-  n = 1 << log2_size;
-  n_2  = n >> 1;
-  n_4  = n >> 2;
-  n_8  = n >> 3;
-  n_16 = n >> 4;
-
-  n_3_16 = n_8 + n_16;
-
-  /* Process the final stage (stage log2_size). For this stage, 
-   * reformat the data from parallel arrays back into 
-   * interleaved arrays,storing the result into <in>.
-   *
-   * This loop has been manually unrolled by 2 to improve 
-   * dual issue rates and reduce stalls. This unrolling
-   * forces a minimum FFT size of 32.
-   */
-  re0 = in_re;
-  re1 = in_re + n_8;
-  re2 = in_re + n_16;
-  re3 = in_re + n_3_16;
-
-  im0 = in_im;
-  im1 = in_im + n_8;
-  im2 = in_im + n_16;
-  im3 = in_im + n_3_16;
-
-  out0 = out;
-  out1 = out + n_4;
-  out2 = out + n_8;
-  out3 = out1 + n_8;
-
-  k0 = kernel;
-  k1 = kernel + n_4;
-  k2 = kernel + n_8;
-  k3 = k1 + n_8;
-
-  i = n_16;
-
-  do {
-    /* Fetch the twiddle factors
-     */
-    w0 = W[0];
-    w1 = W[1];
-    w2 = W[2];
-    w3 = W[3];
-
-    W += 4;
-
-    w0_re = spu_shuffle(w0, w1, shuf_0246);
-    w0_im = spu_shuffle(w0, w1, shuf_1357);
-    w1_re = spu_shuffle(w2, w3, shuf_0246);
-    w1_im = spu_shuffle(w2, w3, shuf_1357);
-
-
-    /* Fetch the butterfly inputs, reals and imaginaries
-     */
-    re_lo0 = re0[0]; im_lo0 = im0[0];
-    re_lo1 = re1[0]; im_lo1 = im1[0];
-    re_lo2 = re0[1]; im_lo2 = im0[1];
-    re_lo3 = re1[1]; im_lo3 = im1[1];
-
-    re_hi0 = re2[0]; im_hi0 = im2[0];
-    re_hi1 = re3[0]; im_hi1 = im3[0];
-    re_hi2 = re2[1]; im_hi2 = im2[1];
-    re_hi3 = re3[1]; im_hi3 = im3[1];
-
-    re0 += 2; im0 += 2;
-    re1 += 2; im1 += 2;
-    re2 += 2; im2 += 2;
-    re3 += 2; im3 += 2;
-
-
-
-    /* Perform the butterflys
-     */
-    {
-      vector float k_re_lo0, k_re_lo1, k_re_lo2, k_re_lo3;
-      vector float k_im_lo0, k_im_lo1, k_im_lo2, k_im_lo3;
-      vector float k_re_hi0, k_re_hi1, k_re_hi2, k_re_hi3;
-      vector float k_im_hi0, k_im_hi1, k_im_hi2, k_im_hi3;
-      vector float t_re_lo0, t_re_lo1, t_re_lo2, t_re_lo3;
-      vector float t_im_lo0, t_im_lo1, t_im_lo2, t_im_lo3;
-      vector float t_re_hi0, t_re_hi1, t_re_hi2, t_re_hi3;
-      vector float t_im_hi0, t_im_hi1, t_im_hi2, t_im_hi3;
-      FFT_1D_BUTTERFLY   (t_re_lo0, t_im_lo0, t_re_lo1, t_im_lo1, re_lo0, im_lo0, re_lo1, im_lo1, w0_re, w0_im);
-      FFT_1D_BUTTERFLY   (t_re_lo2, t_im_lo2, t_re_lo3, t_im_lo3, re_lo2, im_lo2, re_lo3, im_lo3, w1_re, w1_im);
-
-      FFT_1D_BUTTERFLY_HI(t_re_hi0, t_im_hi0, t_re_hi1, t_im_hi1, re_hi0, im_hi0, re_hi1, im_hi1, w0_re, w0_im);
-      FFT_1D_BUTTERFLY_HI(t_re_hi2, t_im_hi2, t_re_hi3, t_im_hi3, re_hi2, im_hi2, re_hi3, im_hi3, w1_re, w1_im);
-
-
-      /* Fetch the kernel inputs, reals and imaginaries
-       */
-      k_re_lo0 = spu_shuffle(k0[0], k0[1], shuf_0246);
-      k_im_lo0 = spu_shuffle(k0[0], k0[1], shuf_1357);
-      k_re_lo1 = spu_shuffle(k1[0], k1[1], shuf_0246);
-      k_im_lo1 = spu_shuffle(k1[0], k1[1], shuf_1357);
-      k_re_lo2 = spu_shuffle(k0[2], k0[3], shuf_0246);
-      k_im_lo2 = spu_shuffle(k0[2], k0[3], shuf_1357);
-      k_re_lo3 = spu_shuffle(k1[2], k1[3], shuf_0246);
-      k_im_lo3 = spu_shuffle(k1[2], k1[3], shuf_1357);
-
-      k_re_hi0 = spu_shuffle(k2[0], k2[1], shuf_0246);
-      k_im_hi0 = spu_shuffle(k2[0], k2[1], shuf_1357);
-      k_re_hi1 = spu_shuffle(k3[0], k3[1], shuf_0246);
-      k_im_hi1 = spu_shuffle(k3[0], k3[1], shuf_1357);
-      k_re_hi2 = spu_shuffle(k2[2], k2[3], shuf_0246);
-      k_im_hi2 = spu_shuffle(k2[2], k2[3], shuf_1357);
-      k_re_hi3 = spu_shuffle(k3[2], k3[3], shuf_0246);
-      k_im_hi3 = spu_shuffle(k3[2], k3[3], shuf_1357);
-
-      k0 += 4;
-      k1 += 4;
-      k2 += 4;
-      k3 += 4;
-
-    
-      out_re_lo0 = spu_msub(k_re_lo0, t_re_lo0, spu_mul(k_im_lo0, t_im_lo0));
-      out_im_lo0 = spu_madd(k_im_lo0, t_re_lo0, spu_mul(k_re_lo0, t_im_lo0));
-      out_re_lo1 = spu_msub(k_re_lo1, t_re_lo1, spu_mul(k_im_lo1, t_im_lo1));
-      out_im_lo1 = spu_madd(k_im_lo1, t_re_lo1, spu_mul(k_re_lo1, t_im_lo1));
-      out_re_lo2 = spu_msub(k_re_lo2, t_re_lo2, spu_mul(k_im_lo2, t_im_lo2));
-      out_im_lo2 = spu_madd(k_im_lo2, t_re_lo2, spu_mul(k_re_lo2, t_im_lo2));
-      out_re_lo3 = spu_msub(k_re_lo3, t_re_lo3, spu_mul(k_im_lo3, t_im_lo3));
-      out_im_lo3 = spu_madd(k_im_lo3, t_re_lo3, spu_mul(k_re_lo3, t_im_lo3));
-
-      out_re_hi0 = spu_msub(k_re_hi0, t_re_hi0, spu_mul(k_im_hi0, t_im_hi0));
-      out_im_hi0 = spu_madd(k_im_hi0, t_re_hi0, spu_mul(k_re_hi0, t_im_hi0));
-      out_re_hi1 = spu_msub(k_re_hi1, t_re_hi1, spu_mul(k_im_hi1, t_im_hi1));
-      out_im_hi1 = spu_madd(k_im_hi1, t_re_hi1, spu_mul(k_re_hi1, t_im_hi1));
-      out_re_hi2 = spu_msub(k_re_hi2, t_re_hi2, spu_mul(k_im_hi2, t_im_hi2));
-      out_im_hi2 = spu_madd(k_im_hi2, t_re_hi2, spu_mul(k_re_hi2, t_im_hi2));
-      out_re_hi3 = spu_msub(k_re_hi3, t_re_hi3, spu_mul(k_im_hi3, t_im_hi3));
-      out_im_hi3 = spu_madd(k_im_hi3, t_re_hi3, spu_mul(k_re_hi3, t_im_hi3));
-    }
-
-    /* Interleave the results and store them into the output buffers (ie,
-     * the original input buffers.
-     */
-    out0[0] = spu_shuffle(out_re_lo0, out_im_lo0, shuf_0415);
-    out0[1] = spu_shuffle(out_re_lo0, out_im_lo0, shuf_2637);
-    out0[2] = spu_shuffle(out_re_lo2, out_im_lo2, shuf_0415);
-    out0[3] = spu_shuffle(out_re_lo2, out_im_lo2, shuf_2637);
-
-    out1[0] = spu_shuffle(out_re_lo1, out_im_lo1, shuf_0415);
-    out1[1] = spu_shuffle(out_re_lo1, out_im_lo1, shuf_2637);
-    out1[2] = spu_shuffle(out_re_lo3, out_im_lo3, shuf_0415);
-    out1[3] = spu_shuffle(out_re_lo3, out_im_lo3, shuf_2637);
-
-    out2[0] = spu_shuffle(out_re_hi0, out_im_hi0, shuf_0415);
-    out2[1] = spu_shuffle(out_re_hi0, out_im_hi0, shuf_2637);
-    out2[2] = spu_shuffle(out_re_hi2, out_im_hi2, shuf_0415);
-    out2[3] = spu_shuffle(out_re_hi2, out_im_hi2, shuf_2637);
-
-    out3[0] = spu_shuffle(out_re_hi1, out_im_hi1, shuf_0415);
-    out3[1] = spu_shuffle(out_re_hi1, out_im_hi1, shuf_2637);
-    out3[2] = spu_shuffle(out_re_hi3, out_im_hi3, shuf_0415);
-    out3[3] = spu_shuffle(out_re_hi3, out_im_hi3, shuf_2637);
-
-    out0 += 4;
-    out1 += 4;
-    out2 += 4;
-    out3 += 4;
-
-    i -= 2;
-  } while (i);
-}
-
-#endif /* _FFT_1D_R2_H_ */
Index: src/vsip/opt/cbe/spu/alf_fconvm_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconvm_c.c	(revision 209510)
+++ src/vsip/opt/cbe/spu/alf_fconvm_c.c	(working copy)
@@ -14,72 +14,40 @@
 #include <sys/time.h>
 #include <spu_mfcio.h>
 #include <alf_accel.h>
+#include <cml/spu/cml.h>
+#include <cml/spu/cml_core.h>
+
 #include <vsip/opt/cbe/fconv_params.h>
-#include "fft_1d_r2.h"
-#include "spe_assert.h"
 
-// The twiddle factors occupy only 1/4 the space as the inputs, 
-// outputs and convolution kernels.
-static float twiddle_factors[2 * VSIP_IMPL_MAX_FCONV_SIZE / 4] 
-       __attribute__ ((aligned (128)));
+#define _ALF_MAX_SINGLE_DT_SIZE 16*1024
 
-static unsigned int instance_id = 0;
 
-#define VEC_SIZE  (4)
 
-unsigned int 
-log2i(unsigned int size)
-{
-  unsigned int log2_size = 0;
-  while (!(size & 1))
-  { 
-    size >>= 1;
-    log2_size++;
-  }
-  return log2_size;
-}
-
-
-void 
-initialize(
-    unsigned long long ea_twiddles,  // source address in main memory
-    void volatile*     p_twiddles,   // destination address in local store
-    unsigned int       n)            // number of elements
-{
-  unsigned int size = n * 2 * sizeof(float);
-
-  // The number of twiddle factors is 1/4 the input size
-  mfc_get(p_twiddles, ea_twiddles, size/4, 31, 0, 0);
-  mfc_write_tag_mask(1<<31);
-  mfc_read_tag_status_all();
-}
-
-
-
 int 
-alf_prepare_input_list(
+input(
     void*        context,
     void*        params,
-    void*        list_entries,
+    void*        entries,
     unsigned int current_count,
     unsigned int total_count)
 {
   unsigned int const FP = 2; // Complex data: 2 floats per point.
 
   Fastconv_params* fc = (Fastconv_params *)params;
-  spe_assert(fc->elements * FP *sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
-  addr64 ea;
+  assert(fc->elements * FP *sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
+  alf_data_addr64_t ea;
 
   // Transfer input.
-  ALF_DT_LIST_CREATE(list_entries, 0);
-  ea.ull = fc->ea_input + 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+  ea = fc->ea_input + 
     current_count * FP * fc->input_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, FP * fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, FP * fc->elements, ALF_DATA_FLOAT, ea);
 
   // Transfer kernel.
-  ea.ull = fc->ea_kernel + 
+  ea = fc->ea_kernel + 
     current_count * FP * fc->kernel_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, FP * fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, FP * fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
 
   return 0;
 }
@@ -87,24 +55,25 @@
 
 
 int 
-alf_prepare_output_list(
+output(
     void*        context,
     void*        params,
-    void*        list_entries,
+    void*        entries,
     unsigned int current_count,
     unsigned int total_count)
 {
   unsigned int const FP = 2; // Complex data: 2 floats per point.
 
   Fastconv_params* fc = (Fastconv_params *)params;
-  spe_assert(fc->elements * FP *sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
-  addr64 ea;
+  assert(fc->elements * FP *sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
+  alf_data_addr64_t ea;
 
   // Transfer output.
-  ALF_DT_LIST_CREATE(list_entries, 0);
-  ea.ull = fc->ea_output + 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
+  ea = fc->ea_output + 
     current_count * FP * fc->output_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, FP * fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, FP * fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_END(entries);
 
   return 0;
 }
@@ -112,82 +81,53 @@
 
 
 int 
-alf_comp_kernel(
-    void* context,
-    void* params,
-    void* input,
-    void* output,
-    unsigned int   current_count,
-    unsigned int   total_count)
+kernel(
+  void*        context,
+  void*        params,
+  void*        input,
+  void*        output,
+  void*        inout,
+  unsigned int iter,
+  unsigned int iter_max)
 {
+  static fft1d_f* obj;
+  static char*    buf;
+  static size_t   current_size = 0;
+
   Fastconv_params* fc = (Fastconv_params *)params;
-  unsigned int n = fc->elements;
-  unsigned int log2n = log2i(n);
-  spe_assert(n <= VSIP_IMPL_MAX_FCONV_SIZE);
+  unsigned int fft_size = fc->elements;
+  assert(fft_size <= VSIP_IMPL_MAX_FCONV_SIZE);
 
-  // Initialization establishes the weights (kernel) for the
-  // convolution step and the twiddle factors for the FFTs.
-  // These are loaded once per task by checking a unique
-  // ID passed down from the caller.
-  if (instance_id != fc->instance_id)
+  // Reinitialize the FFT object if the fft size changes.
+  if (iter == 0 && fft_size != current_size)
   {
-    instance_id = fc->instance_id;
-    initialize(fc->ea_twiddle_factors, twiddle_factors, n);
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
   }
 
-  vector float* in = (vector float *)input;
-  vector float* k = (vector float *)input + 2 * n / VEC_SIZE;
-  vector float* W = (vector float*)twiddle_factors;
-  vector float* out = (vector float*)output;
+  float* in    = (float*)input;
+  float* coeff = (float*)input + 2 * fft_size;
+  float* out   = (float*)output;
 
-  // Create real & imaginary working arrays
-  vector float re[n / VEC_SIZE], im[n / VEC_SIZE];
-
-
   // Perform the forward FFT on the kernel, in place, but
   // only if requested (this step is often done in advance).
   if (fc->transform_kernel)
   {
-    _fft_1d_r2_pre(re, im, k, W, log2n);
-    _fft_1d_r2_fini(k, re, im, W, log2n);
+    cml_ccfft1d_ip_f(obj, coeff, CML_FFT_FWD, buf);
   }
 
+  cml_ccfft1d_ip_f(obj, in, CML_FFT_FWD, buf);
+  cml_cvmul1_f(coeff, in, out, fft_size);
+  cml_ccfft1d_ip_f(obj, out, CML_FFT_INV, buf);
+  cml_core_rcsvmul1_f(1.f / fft_size, out, out, fft_size);
 
-  // Perform the forward FFT, rolling the convolution into 
-  // the last stage
-  _fft_1d_r2_pre(re, im, in, W, log2n);
-  _fft_1d_r2_fini_cvmul(out, re, im, k, W, log2n);
-
-
-  // Revert back the time domain.  
-  _fft_1d_r2_pre(re, im, out, W, log2n);
-  _fft_1d_r2_fini(out, re, im, W, log2n);
-
-
-  // Code for the inverse FFT scaling is taken from the CBE 
-  // SDK Libraries Overview and Users Guide, sec. 8.1.  
-  {
-    unsigned int i;
-    vector float *start, *end, s0, s1, e0, e1;
-    vector unsigned int mask = (vector unsigned int){-1, -1, 0, 0};
-    vector float vscale = spu_splats(1 / (float)n);
-    start = out;
-
-    // Scale the output vector and swap the order of the outputs.
-    // Note: there are two float values for each of 'n' complex values.
-    end = start + 2 * n / VEC_SIZE;
-    s0 = e1 = *start;
-    for (i = 0; i < n / VEC_SIZE; ++i) 
-    {
-      s1 = *(start + 1);
-      e0 = *(--end);
-
-      *start++ = spu_mul(spu_sel(e0, e1, mask), vscale);
-      *end = spu_mul(spu_sel(s0, s1, mask), vscale);
-      s0 = s1;
-      e1 = e0;
-    }
-  }
-
   return 0;
 }
Index: src/vsip/opt/cbe/spu/spe_assert.h
===================================================================
--- src/vsip/opt/cbe/spu/spe_assert.h	(revision 209510)
+++ src/vsip/opt/cbe/spu/spe_assert.h	(working copy)
@@ -1,57 +0,0 @@
-/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
-
-   This file is available for license from CodeSourcery, Inc. under the terms
-   of a commercial license and under the GPL.  It is not part of the VSIPL++
-   reference implementation and is not available under the BSD license.
-*/
-/** @file    vsip/opt/cbe/spu/spe_assert.h
-    @author  Jules Bergmann, Don McCoy
-    @date    2007-03-23
-    @brief   VSIPL++ Library: Replacement function for assert(), used
-               because it is broken as of 2007/03.
-*/
-
-#ifndef _SPE_ASSERT_H_
-#define _SPE_ASSERT_H_
-
-#ifndef NDEBUG
-#include <stdio.h>
-
-void inline
-spe_assert_fail(
-  const char*  assertion,
-  const char*  file,
-  unsigned int line,
-  const char*  function)
-{
-  fprintf(stderr, "ASSERTION FAILURE: %s %s %d %s\n",
-	  assertion, file, line, function);
-  abort();
-}
-
-#if defined(__GNU__)
-# if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
-#  define SPE_ASSERT_FUNCTION    __func__
-# else
-#  define SPE_ASSERT_FUNCTION    ((__const char *) 0)
-# endif
-#else
-# define SPE_ASSERT_FUNCTION    ((__const char *) 0)
-#endif
-
-#ifdef __STDC__
-#  define __SPE_STRING(e) #e
-#else
-#  define __SPE_STRING(e) "e"
-#endif
-
-#define spe_assert(expr)						\
-  ((void)((expr) ? 0 :							\
-	     (spe_assert_fail(__SPE_STRING(expr), __FILE__, __LINE__,	\
-			       SPE_ASSERT_FUNCTION), 0)))
-#else
-#define spe_assert(expr)
-
-#endif /* #ifndef NDEBUG */
-
-#endif /* _SPE_ASSERT_H_ */
Index: src/vsip/opt/cbe/spu/alf_decls.hpp
===================================================================
--- src/vsip/opt/cbe/spu/alf_decls.hpp	(revision 0)
+++ src/vsip/opt/cbe/spu/alf_decls.hpp	(revision 0)
@@ -0,0 +1,41 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/spu/alf_decls.cpp
+    @author  Jules Bergmann
+    @date    2008-05-22
+    @brief   VSIPL++ Library: Decls for ALF input/output/kernel functions.
+*/
+
+#ifndef VSIP_OPT_CBE_SPU_ALF_DECLS_HPP
+#define VSIP_OPT_CBE_SPU_ALF_DECLS_HPP
+
+extern "C" {
+int input(
+  void*        context,
+  void*        params,
+  void*        entries,
+  unsigned int current_count,
+  unsigned int total_count);
+
+int output(
+  void*        context,
+  void*        params,
+  void*        entries,
+  unsigned int cur_iter,
+  unsigned int tot_iter);
+
+int kernel(
+  void*        context,
+  void*        params,
+  void*        input,
+  void*        output,
+  void*        inout,
+  unsigned int cur_iter,
+  unsigned int tot_iter);
+}
+
+#endif // VSIP_OPT_CBE_SPU_ALF_DECLS_HPP
Index: src/vsip/opt/cbe/spu/alf_vmul_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmul_split_c.c	(revision 209510)
+++ src/vsip/opt/cbe/spu/alf_vmul_split_c.c	(working copy)
@@ -11,78 +11,77 @@
 */
 
 #include <alf_accel.h>
+#include <cml/spu/cml.h>
+
 #include <vsip/opt/cbe/vmul_params.h>
-#include "vmul_split.h"
 
 
 
-int alf_prepare_input_list(
+int input(
   void*        p_context,
   void*        p_params, 
-  void*        p_list_entries, 
+  void*        entries, 
   unsigned int current_count, 
   unsigned int total_count)
 {
   Vmul_split_params* p = (Vmul_split_params*)p_params;
-  addr64 ea;
-  u32    base_addr;
+  alf_data_addr64_t ea;
 
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+
   // Transfer input A real
-  ALF_DT_LIST_CREATE(p_list_entries, 0);
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(p->a_re_ptr + current_count * p->a_blk_stride);
-  ALF_DT_LIST_ADD_ENTRY(p_list_entries, p->length, ALF_DATA_FLOAT, ea);
+  ea = p->a_re_ptr + current_count * p->a_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
 
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(p->a_im_ptr + current_count * p->a_blk_stride);
-  ALF_DT_LIST_ADD_ENTRY(p_list_entries, p->length, ALF_DATA_FLOAT, ea);
+  ea = p->a_im_ptr + current_count * p->a_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
 
   // Transfer input B.
-  ALF_DT_LIST_CREATE(p_list_entries, 2*p->length*sizeof(float));
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(p->b_re_ptr + current_count * p->b_blk_stride);
-  ALF_DT_LIST_ADD_ENTRY(p_list_entries, p->length, ALF_DATA_FLOAT, ea);
+  ea = p->b_re_ptr + current_count * p->b_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
 
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(p->b_im_ptr + current_count * p->b_blk_stride);
-  ALF_DT_LIST_ADD_ENTRY(p_list_entries, p->length, ALF_DATA_FLOAT, ea);
+  ea = p->b_im_ptr + current_count * p->b_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
 
+  ALF_ACCEL_DTL_END(entries);
+
   return 0;
 }
 
 
 
-int alf_prepare_output_list(
+int output(
   void*        p_context,
   void*        p_params, 
-  void*        p_list_entries, 
+  void*        entries, 
   unsigned int current_count, 
   unsigned int total_count)
 {
   Vmul_split_params* p = (Vmul_split_params*)p_params;
-  addr64 ea;
-  u32    base_addr;
+  alf_data_addr64_t ea;
 
   // Transfer output R.
-  ALF_DT_LIST_CREATE(p_list_entries, 0);
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(p->r_re_ptr + current_count *  p->r_blk_stride);
-  ALF_DT_LIST_ADD_ENTRY(p_list_entries, p->length, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
 
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(p->r_im_ptr + current_count *  p->r_blk_stride);
-  ALF_DT_LIST_ADD_ENTRY(p_list_entries, p->length, ALF_DATA_FLOAT, ea);
+  ea = p->r_re_ptr + current_count *  p->r_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
 
+  ea = p->r_im_ptr + current_count *  p->r_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, p->length, ALF_DATA_FLOAT, ea);
+
+  ALF_ACCEL_DTL_END(entries);
+
   return 0;
 }
 
 
 
-int alf_comp_kernel(
-  void* p_context,
-  void* p_params,
-  void* input,
-  void* output,
+int kernel(
+  void*        p_context,
+  void*        p_params,
+  void*        input,
+  void*        output,
+  void*        inout,
   unsigned int iter,
   unsigned int n)
 {
@@ -96,9 +95,13 @@
   float *r_re = (float *)output + 0 * length;
   float *r_im = (float *)output + 1 * length;
 
-  cvmul(r_re, r_im, a_re, a_im, b_re, b_im, length);
+  cml_zvmul1_f(a_re, a_im, b_re, b_im, r_re, r_im, length);
 
   return 0;
 }
 
-
+ALF_ACCEL_EXPORT_API_LIST_BEGIN
+  ALF_ACCEL_EXPORT_API ("input", input);
+  ALF_ACCEL_EXPORT_API ("output", output); 
+  ALF_ACCEL_EXPORT_API ("kernel", kernel);
+ALF_ACCEL_EXPORT_API_LIST_END
Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 209510)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -14,10 +14,7 @@
 
 cbe_sdk_version := @cbe_sdk_version@
 
-#src_vsip_opt_cbe_spu_c_src := $(wildcard $(srcdir)/src/vsip/opt/cbe/spu/alf_*.c)
-src_vsip_opt_cbe_spu_c_src := $(srcdir)/src/vsip/opt/cbe/spu/alf_fconv_c.c
-src_vsip_opt_cbe_spu_c_src += $(srcdir)/src/vsip/opt/cbe/spu/alf_fft_c.c
-src_vsip_opt_cbe_spu_c_src += $(srcdir)/src/vsip/opt/cbe/spu/alf_vmul_c.c
+src_vsip_opt_cbe_spu_c_src   := $(wildcard $(srcdir)/src/vsip/opt/cbe/spu/alf_*.c)
 src_vsip_opt_cbe_spu_cxx_src := $(wildcard $(srcdir)/src/vsip/opt/cbe/spu/alf_*.cpp)
 src_vsip_opt_cbe_spu_src := $(src_vsip_opt_cbe_spu_c_src) $(src_vsip_opt_cbe_spu_cxx_src)
 ifneq ($(VSIP_IMPL_CBE_SDK_FFT),1)
@@ -40,7 +37,8 @@
 CXX_SPU := @CXX_SPU@
 EMBED_SPU := @EMBED_SPU@
 CPP_SPU_FLAGS := @CPP_SPU_FLAGS@
-LIBS_SPU := -lalf -lm
+LD_SPU_FLAGS := @LD_SPU_FLAGS@
+LIBS_SPU := -lcml_spu -lalf -lm
 
 CPP_SPU_FLAGS += -I src -I $(srcdir)/src
 CPP_SPU_FLAGS += -I $(srcdir)/src/vsip/opt/cbe
@@ -48,7 +46,7 @@
 CPP_SPU_FLAGS += -I $(CBE_SDK_SYSROOT)/opt/cell/sdk/usr/spu/include
 C_SPU_FLAGS := -O3
 CXX_SPU_FLAGS := -O3
-LD_SPU_FLAGS := -Wl,-N -L$(CBE_SDK_SYSROOT)/usr/spu/lib
+LD_SPU_FLAGS += -Wl,-N -L$(CBE_SDK_SYSROOT)/usr/spu/lib
 LD_SPU_FLAGS += -L$(CBE_SDK_SYSROOT)/opt/cell/sdk/usr/spu/lib
 
 ########################################################################
@@ -112,7 +110,7 @@
 	$(compile_cxx_spu_kernel)
 
 mostlyclean::
-	rm $(spe_kernels)
+	rm -f $(spe_kernels)
 	rm -f $(src_vsip_opt_cbe_spu_obj)
 	rm -f $(src_vsip_opt_cbe_spu_mod)
 
Index: src/vsip/opt/cbe/spu/alf_vmmul_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmmul_c.c	(revision 209510)
+++ src/vsip/opt/cbe/spu/alf_vmmul_c.c	(working copy)
@@ -15,7 +15,9 @@
 #include <spu_mfcio.h>
 #include <vsip/opt/cbe/vmmul_params.h>
 
+#define _ALF_MAX_SINGLE_DT_SIZE 16*1024
 
+
 // These are sized for complex values, taking two floats each.
 static volatile float vector_in[VSIP_IMPL_MAX_VMMUL_SIZE*2]
   __attribute__ ((aligned (128)));
@@ -44,10 +46,10 @@
 }
 
 
-int alf_prepare_input_list(
+int input(
   void*        p_context,
   void*        p_params, 
-  void*        p_list_entries, 
+  void*        entries, 
   unsigned int current_count, 
   unsigned int total_count)
 {
@@ -55,32 +57,34 @@
   Vmmul_params* params = (Vmmul_params*)p_params;
 
   // Transfer input
-  ALF_DT_LIST_CREATE(p_list_entries, 0);
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
   unsigned long length = params->length;
   unsigned long max_length = _ALF_MAX_SINGLE_DT_SIZE / FP / sizeof(float);
 
-  addr64 ea;
-  ea.ull = params->ea_input_matrix + current_count * FP * params->input_stride * sizeof(float);
+  alf_data_addr64_t ea;
+  ea = params->ea_input_matrix + current_count * FP * params->input_stride * sizeof(float);
   while (length > 0)
   {
     unsigned long cur_length = (length > max_length) ? max_length : length;
-    ALF_DT_LIST_ADD_ENTRY(p_list_entries,
-			  FP * cur_length,
-			  ALF_DATA_FLOAT,
-			  ea);
+    ALF_ACCEL_DTL_ENTRY_ADD(entries,
+			    FP * cur_length,
+			    ALF_DATA_FLOAT,
+			    ea);
     length -= cur_length;
-    ea.ull += FP * cur_length * sizeof(float);
+    ea += FP * cur_length * sizeof(float);
   } 
 
+  ALF_ACCEL_DTL_END(entries);
+
   return 0;
 }
 
 
 
-int alf_prepare_output_list(
+int output(
   void*        p_context,
   void*        p_params, 
-  void*        p_list_entries, 
+  void*        entries, 
   unsigned int current_count, 
   unsigned int total_count)
 {
@@ -88,33 +92,36 @@
   Vmmul_params* params = (Vmmul_params*)p_params;
 
   // Transfer output
-  ALF_DT_LIST_CREATE(p_list_entries, 0);
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
   unsigned long length = params->length;
   unsigned long max_length = _ALF_MAX_SINGLE_DT_SIZE / FP / sizeof(float);
 
-  addr64 ea;
-  ea.ull = params->ea_output_matrix + current_count * FP * params->output_stride * sizeof(float);
+  alf_data_addr64_t ea;
+  ea = params->ea_output_matrix + current_count * FP * params->output_stride * sizeof(float);
   while (length > 0)
   {
     unsigned long cur_length = (length > max_length) ? max_length : length;
-    ALF_DT_LIST_ADD_ENTRY(p_list_entries,
-			  FP * cur_length,
-			  ALF_DATA_FLOAT,
-			  ea);
+    ALF_ACCEL_DTL_ENTRY_ADD(entries,
+			    FP * cur_length,
+			    ALF_DATA_FLOAT,
+			    ea);
     length -= cur_length;
-    ea.ull += FP * cur_length * sizeof(float);
+    ea += FP * cur_length * sizeof(float);
   } 
 
+  ALF_ACCEL_DTL_END(entries);
+
   return 0;
 }
 
 
 
-int alf_comp_kernel(
+int kernel(
   void* p_context,
   void* p_params,
   void* input,
   void* output,
+  void*        inout,
   unsigned int iter,
   unsigned int n)
 {
@@ -170,3 +177,9 @@
 
   return 0;
 }
+
+ALF_ACCEL_EXPORT_API_LIST_BEGIN
+  ALF_ACCEL_EXPORT_API ("input", input);
+  ALF_ACCEL_EXPORT_API ("output", output); 
+  ALF_ACCEL_EXPORT_API ("kernel", kernel);
+ALF_ACCEL_EXPORT_API_LIST_END
Index: src/vsip/opt/cbe/spu/fft_1d_r2_split.h
===================================================================
--- src/vsip/opt/cbe/spu/fft_1d_r2_split.h	(revision 209510)
+++ src/vsip/opt/cbe/spu/fft_1d_r2_split.h	(working copy)
@@ -1,618 +0,0 @@
-/* --------------------------------------------------------------  */
-/* (C)Copyright 2001,2006,                                         */
-/* International Business Machines Corporation,                    */
-/* Sony Computer Entertainment, Incorporated,                      */
-/* Toshiba Corporation,                                            */
-/*                                                                 */
-/* All Rights Reserved.                                            */
-/* --------------------------------------------------------------  */
-/* PROLOG END TAG zYx                                              */
-
-/* CSL: Based on the original Cell SDK FFT library, this file has
-   been modified as follows:
-
-   2007-02-28 JPB
-
-   - The function _fft_1d_r2 had been converted to operate on
-     split-complex data.
-      - Function renamed to _fft_1d_r2_split,
-      - Input stage unrolled by 2 and changed to process data
-        vertically + transpose, rather than horizontally.
-      - Later stages manually unrolled by 2.
-
-*/
-#ifndef _FFT_1D_R2_SPLIT_H_
-#define _FFT_1D_R2_SPLIT_H_	1
-
-#include <vec_literal.h>
-#include "fft_1d.h"
-
-/* fft_1d_r2
- * ---------
- * Performs a single precision, complex Fast Fourier Transform using 
- * the DFT (Discrete Fourier Transform) with radix-2 decimation in time. 
- * The input <in> is an array of complex numbers of length (1<<log2_size)
- * entries. The result is returned in the array of complex numbers specified
- * by <out>. Note: This routine can support an in-place transformation
- * by specifying <in> and <out> to be the same array.
- *
- * This implementation utilizes the Cooley-Tukey algorithm consisting 
- * of <log2_size> stages. The basic operation is the butterfly.
- *
- *          p --------------------------> P = p + q*Wi
- *                        \      /
- *                         \    /
- *                          \  /
- *                           \/
- *                           /\
- *                          /  \
- *                         /    \
- *               ____     /      \
- *          q --| Wi |-----------------> Q = p - q*Wi
- *               ----
- *
- * This routine also requires pre-computed twiddle values, W. W is an
- * array of single precision complex numbers of length 1<<(log2_size-2) 
- * and is computed as follows:
- *
- *	for (i=0; i<n/4; i++)
- *	    W[i].real =  cos(i * 2*PI/n);
- *	    W[i].imag = -sin(i * 2*PI/n);
- *      }
- *
- * This array actually only contains the first half of the twiddle
- * factors. Due for symmetry, the second half of the twiddle factors
- * are implied and equal:
- *
- *	for (i=0; i<n/4; i++)
- *	    W[i+n/4].real =  W[i].imag =  sin(i * 2*PI/n);
- *	    W[i+n/4].imag = -W[i].real = -cos(i * 2*PI/n);
- *      }
- *
- * Further symmetry allows one to generate the twiddle factor table 
- * using half the number of trig computations as follows:
- *
- *      W[0].real = 1.0;
- *      W[0].imag = 0.0;
- *	for (i=1; i<n/4; i++)
- *	    W[i].real =  cos(i * 2*PI/n);
- *	    W[n/4 - i].imag = -W[i].real;
- *      }
- *
- * The complex numbers are packed into quadwords as follows:
- *
- *    quadword			      complex
- *  array element                   array elements
- *             -----------------------------------------------------
- *       i    |  real 2*i   |  imag 2*i  | real 2*i+1  | imag 2*i+1 | 
- *             -----------------------------------------------------
- *
- */
-
-#define TRANSPOSE_4X4(abcd, efgh, ijkl, mnop, aeim, bfjn, cgko, dhlp)\
-{\
-  vector float aibj, ckdl, emfn, gohp;\
-  aibj = spu_shuffle(abcd, ijkl, shuf_0415);\
-  ckdl = spu_shuffle(abcd, ijkl, shuf_2637);\
-  emfn = spu_shuffle(efgh, mnop, shuf_0415);\
-  gohp = spu_shuffle(efgh, mnop, shuf_2637);\
-\
-  aeim = spu_shuffle(aibj, emfn, shuf_0415);\
-  bfjn = spu_shuffle(aibj, emfn, shuf_2637);\
-  cgko = spu_shuffle(ckdl, gohp, shuf_0415);\
-  dhlp = spu_shuffle(ckdl, gohp, shuf_2637);\
-}
-
-
-static __inline void _fft_1d_r2_split(
-  vector float *out_re,
-  vector float *out_im,
-  vector float *in_re,
-  vector float *in_im,
-  vector float *W,
-  int log2_size)
-{
-  int i, j, k;
-  int stage, offset;
-  int i_rev;
-  int n, n_2, n_4, n_8, n_16, n_3_16;
-  int w_stride, w_2stride, w_3stride, w_4stride;
-  int stride, stride_2, stride_4, stride_3_4;
-  vector float *W0, *W1, *W2, *W3;
-  vector float *re0, *re1, *re2, *re3;
-  vector float *im0, *im1, *im2, *im3;
-  vector float *re0_a, *re1_a;
-  vector float *re0_b, *re1_b;
-  vector float *im0_a, *im1_a;
-  vector float *im0_b, *im1_b;
-  vector float *in0_re, *in1_re, *in2_re, *in3_re, *in4_re, *in5_re, *in6_re, *in7_re;
-  vector float *in0_im, *in1_im, *in2_im, *in3_im, *in4_im, *in5_im, *in6_im, *in7_im;
-  vector float *out0_re, *out1_re, *out2_re, *out3_re;
-  vector float *out0_im, *out1_im, *out2_im, *out3_im;
-  vector float tmp0, tmp1;
-  vector float tmp0_a, tmp1_a;
-  vector float tmp0_b, tmp1_b;
-  vector float w0_re, w0_im; // , w1_re, w1_im;
-  vector float w0, w1, w2, w3;
-
-  vector float w0_re_a, w0_im_a, w1_re_a, w1_im_a;
-  vector float w0_a, w1_a, w2_a, w3_a;
-  vector float w0_re_b, w0_im_b, w1_re_b, w1_im_b;
-  vector float w0_b, w1_b, w2_b, w3_b;
-
-  vector float src_lo0_re, src_lo1_re, src_lo2_re, src_lo3_re;
-  vector float src_hi0_re, src_hi1_re, src_hi2_re, src_hi3_re;
-
-  vector float src_lo0_im, src_lo1_im, src_lo2_im, src_lo3_im;
-  vector float src_hi0_im, src_hi1_im, src_hi2_im, src_hi3_im;
-
-  vector float re_lo0_a,  re_lo1_a,  re_lo2_a,  re_lo3_a;
-  vector float im_lo0_a,  im_lo1_a,  im_lo2_a,  im_lo3_a;
-  vector float re_hi0_a,  re_hi1_a,  re_hi2_a,  re_hi3_a;
-  vector float im_hi0_a,  im_hi1_a,  im_hi2_a,  im_hi3_a;
-
-  vector float re_lo0_b,  re_lo1_b,  re_lo2_b,  re_lo3_b;
-  vector float im_lo0_b,  im_lo1_b,  im_lo2_b,  im_lo3_b;
-  vector float re_hi0_b,  re_hi1_b,  re_hi2_b,  re_hi3_b;
-  vector float im_hi0_b,  im_hi1_b,  im_hi2_b,  im_hi3_b;
-
-  vector float re[MAX_FFT_1D_SIZE/4], im[MAX_FFT_1D_SIZE/4];	/* real & imaginary working arrays */
-
-  vector unsigned char reverse;
-  vector unsigned char shuf_0415 = VEC_LITERAL(vector unsigned char,
-					       0, 1, 2, 3, 16,17,18,19,
-					       4, 5, 6, 7, 20,21,22,23);
-  vector unsigned char shuf_2637 = VEC_LITERAL(vector unsigned char,
-					       8, 9,10,11, 24,25,26,27,
-					       12,13,14,15,28,29,30,31);
-  vector unsigned char shuf_0246 = VEC_LITERAL(vector unsigned char,
-					       0, 1, 2, 3,  8, 9,10,11,
-					       16,17,18,19,24,25,26,27);
-  vector unsigned char shuf_1357 = VEC_LITERAL(vector unsigned char,
-					       4, 5, 6, 7, 12,13,14,15,
-					       20,21,22,23,28,29,30,31);
-  
-  n = 1 << log2_size;
-  n_2  = n >> 1;
-  n_4  = n >> 2;
-  n_8  = n >> 3;
-  n_16 = n >> 4;
-
-  n_3_16 = n_8 + n_16;
-
-  reverse = byte_reverse[log2_size];
-
-  /* Perform the first 3 stages of the FFT. These stages differs from 
-   * other stages in that the inputs are unscrambled and the data is 
-   * reformated into parallel arrays (ie, seperate real and imaginary
-   * arrays). The term "unscramble" means the bit address reverse the 
-   * data array. In addition, the first three stages have simple twiddle
-   * weighting factors.
-   *		stage 1: (1, 0)
-   *            stage 2: (1, 0) and (0, -1)
-   *		stage 3: (1, 0), (0.707, -0.707), (0, -1), (-0.707, -0.707)
-   *
-   * The arrays are processed as two halves, simultaneously. The lo (first 
-   * half) and hi (second half). This is done because the scramble 
-   * shares source value between each half of the output arrays.
-   */
-  i = 0;
-  i_rev = 0;
-
-  in0_re = in_re;
-  in1_re = in_re + n_8/2;
-  in2_re = in_re + n_16/2;
-  in3_re = in_re + n_3_16/2;  
-
-  in4_re = in_re  + n_8;
-  in5_re = in1_re + n_8;
-  in6_re = in2_re + n_8;
-  in7_re = in3_re + n_8;
-
-  in0_im = in_im;
-  in1_im = in_im + n_8/2;
-  in2_im = in_im + n_16/2;
-  in3_im = in_im + n_3_16/2;  
-
-  in4_im = in_im  + n_8;
-  in5_im = in1_im + n_8;
-  in6_im = in2_im + n_8;
-  in7_im = in3_im + n_8;
-
-  re0_a = re;
-  re1_a = re + n_8;
-  im0_a = im;
-  im1_a = im + n_8;
-
-  re0_b = re       + n_16;
-  re1_b = re + n_8 + n_16;
-  im0_b = im       + n_16;
-  im1_b = im + n_8 + n_16;
-
-  w0_re = VEC_LITERAL(vector float, 1.0f,  INV_SQRT_2,  0.0f, -INV_SQRT_2);
-  w0_im = VEC_LITERAL(vector float, 0.0f, -INV_SQRT_2, -1.0f, -INV_SQRT_2);
-      
-  do {
-    src_lo0_re = in0_re[i_rev];
-    src_lo1_re = in1_re[i_rev];
-    src_lo2_re = in2_re[i_rev];
-    src_lo3_re = in3_re[i_rev];
-
-    src_hi0_re = in4_re[i_rev];
-    src_hi1_re = in5_re[i_rev];
-    src_hi2_re = in6_re[i_rev];
-    src_hi3_re = in7_re[i_rev];
-
-    src_lo0_im = in0_im[i_rev];
-    src_lo1_im = in1_im[i_rev];
-    src_lo2_im = in2_im[i_rev];
-    src_lo3_im = in3_im[i_rev];
-
-    src_hi0_im = in4_im[i_rev];
-    src_hi1_im = in5_im[i_rev];
-    src_hi2_im = in6_im[i_rev];
-    src_hi3_im = in7_im[i_rev];
-
-    vector float a_0_16  = spu_add(src_lo0_re, src_hi0_re);
-    vector float s_0_16  = spu_sub(src_lo0_re, src_hi0_re);
-    vector float a_4_20  = spu_add(src_lo1_re, src_hi1_re);
-    vector float s_4_20  = spu_sub(src_lo1_re, src_hi1_re);
-    vector float a_8_24  = spu_add(src_lo2_re, src_hi2_re);
-    vector float s_8_24  = spu_sub(src_lo2_re, src_hi2_re);
-    vector float a_12_28 = spu_add(src_lo3_re, src_hi3_re);
-    vector float s_12_28 = spu_sub(src_lo3_re, src_hi3_re);
-    vector float a_32_48 = spu_add(src_lo0_im, src_hi0_im);
-    vector float s_32_48 = spu_sub(src_lo0_im, src_hi0_im);
-    vector float a_36_52 = spu_add(src_lo1_im, src_hi1_im);
-    vector float s_36_52 = spu_sub(src_lo1_im, src_hi1_im);
-    vector float a_40_56 = spu_add(src_lo2_im, src_hi2_im);
-    vector float s_40_56 = spu_sub(src_lo2_im, src_hi2_im);
-    vector float a_44_60 = spu_add(src_lo3_im, src_hi3_im);
-    vector float s_44_60 = spu_sub(src_lo3_im, src_hi3_im);
-
-
-    vector float re_hilo0_0 = spu_add(a_4_20,  a_0_16);
-    vector float re_hilo0_1 = spu_add(s_36_52, s_0_16);
-    vector float re_hilo0_2 = spu_sub(a_0_16,  a_4_20);
-    vector float re_hilo0_3 = spu_sub(s_0_16,  s_36_52);
-
-    vector float im_hilo0_0 = spu_add(a_36_52, a_32_48);
-    vector float im_hilo0_1 = spu_sub(s_32_48, s_4_20);
-    vector float im_hilo0_2 = spu_sub(a_32_48, a_36_52);
-    vector float im_hilo0_3 = spu_add(s_4_20,  s_32_48);
-
-    vector float re_hilo1_0 = spu_add(a_12_28, a_8_24);
-    vector float re_hilo1_1 = spu_add(s_44_60, s_8_24);
-    vector float re_hilo1_2 = spu_sub(a_8_24,  a_12_28);
-    vector float re_hilo1_3 = spu_sub(s_8_24,  s_44_60);
-
-    vector float im_hilo1_0 = spu_add(a_44_60, a_40_56);
-    vector float im_hilo1_1 = spu_sub(s_40_56, s_12_28);
-    vector float im_hilo1_2 = spu_sub(a_40_56, a_44_60);
-    vector float im_hilo1_3 = spu_add(s_12_28, s_40_56);
-
-
-    TRANSPOSE_4X4(re_hilo0_0, re_hilo0_1, re_hilo0_2, re_hilo0_3,
-		  re_lo0_a, re_hi0_a, re_lo0_b, re_hi0_b);
-
-    TRANSPOSE_4X4(im_hilo0_0, im_hilo0_1, im_hilo0_2, im_hilo0_3,
-		  im_lo0_a, im_hi0_a, im_lo0_b, im_hi0_b);
-
-    TRANSPOSE_4X4(re_hilo1_0, re_hilo1_1, re_hilo1_2, re_hilo1_3,
-		  re_lo1_a, re_hi1_a, re_lo1_b, re_hi1_b);
-
-    TRANSPOSE_4X4(im_hilo1_0, im_hilo1_1, im_hilo1_2, im_hilo1_3,
-		  im_lo1_a, im_hi1_a, im_lo1_b, im_hi1_b);
-
-
-    /* Perform stage 3 butterfly.
-     */
-    FFT_1D_BUTTERFLY(re0_a[0], im0_a[0], re0_a[1], im0_a[1],
-		     re_lo0_a, im_lo0_a, re_lo1_a, im_lo1_a, w0_re, w0_im);
-    FFT_1D_BUTTERFLY(re1_a[0], im1_a[0], re1_a[1], im1_a[1],
-		     re_hi0_a, im_hi0_a, re_hi1_a, im_hi1_a, w0_re, w0_im);
-
-    FFT_1D_BUTTERFLY(re0_b[0], im0_b[0], re0_b[1], im0_b[1],
-		     re_lo0_b, im_lo0_b, re_lo1_b, im_lo1_b, w0_re, w0_im);
-    FFT_1D_BUTTERFLY(re1_b[0], im1_b[0], re1_b[1], im1_b[1],
-		     re_hi0_b, im_hi0_b, re_hi1_b, im_hi1_b, w0_re, w0_im);
-
-
-    re0_a += 2;
-    re1_a += 2;
-    im0_a += 2; 
-    im1_a += 2;
-
-    re0_b += 2;
-    re1_b += 2;
-    im0_b += 2; 
-    im1_b += 2;
-    
-    i += 8;
-    i_rev = BIT_SWAP(i, reverse) / 4;
-  } while (i < n_4);
-
-  /* Process stages 4 to log2_size-2
-   */
-  for (stage=4, stride=4; stage<log2_size-1; stage++, stride += stride) {
-    w_stride  = n_2 >> stage;
-    w_2stride = n   >> stage;
-    w_3stride = w_stride +  w_2stride;
-    w_4stride = w_2stride + w_2stride;
-
-    W0 = W;
-    W1 = W + w_stride;
-    W2 = W + w_2stride;
-    W3 = W + w_3stride;
-
-    stride_2 = stride >> 1;
-    stride_4 = stride >> 2;
-    stride_3_4 = stride_2 + stride_4;
-    int stride_2x = 2*stride;
-    int stride_4x = 4*stride;
-
-    re0 = re;              im0 = im;
-    re1 = re + stride_2;   im1 = im + stride_2;   
-    re2 = re + stride_4;   im2 = im + stride_4;   
-    re3 = re + stride_3_4; im3 = im + stride_3_4;   
-
-    for (i=0, offset=0; i<stride_4; i++, offset += w_4stride) {
-      /* Compute the twiddle factors
-       */
-      w0 = W0[offset];
-      w1 = W1[offset];
-      w2 = W2[offset];
-      w3 = W3[offset];
-
-      tmp0 = spu_shuffle(w0, w2, shuf_0415);
-      tmp1 = spu_shuffle(w1, w3, shuf_0415);
-
-      w0_re = spu_shuffle(tmp0, tmp1, shuf_0415);
-      w0_im = spu_shuffle(tmp0, tmp1, shuf_2637);
-
-      j = i;
-      k = i + stride;
-
-      do {
-	re_lo0_a = re0[j]; im_lo0_a = im0[j];
-	re_lo1_a = re1[j]; im_lo1_a = im1[j];
-
-	re_hi0_a = re2[j]; im_hi0_a = im2[j];
-	re_hi1_a = re3[j]; im_hi1_a = im3[j];
-
-	re_lo2_a = re0[k]; im_lo2_a = im0[k];
-	re_lo3_a = re1[k]; im_lo3_a = im1[k];
-
-	re_hi2_a = re2[k]; im_hi2_a = im2[k];
-	re_hi3_a = re3[k]; im_hi3_a = im3[k];
-
-	re_lo0_b = re0[j+stride_2x]; im_lo0_b = im0[j+stride_2x];
-	re_lo1_b = re1[j+stride_2x]; im_lo1_b = im1[j+stride_2x];
-
-	re_hi0_b = re2[j+stride_2x]; im_hi0_b = im2[j+stride_2x];
-	re_hi1_b = re3[j+stride_2x]; im_hi1_b = im3[j+stride_2x];
-
-	re_lo2_b = re0[k+stride_2x]; im_lo2_b = im0[k+stride_2x];
-	re_lo3_b = re1[k+stride_2x]; im_lo3_b = im1[k+stride_2x];
-
-	re_hi2_b = re2[k+stride_2x]; im_hi2_b = im2[k+stride_2x];
-	re_hi3_b = re3[k+stride_2x]; im_hi3_b = im3[k+stride_2x];
-
-	FFT_1D_BUTTERFLY   (re0[j], im0[j], re1[j], im1[j], re_lo0_a, im_lo0_a, re_lo1_a, im_lo1_a, w0_re, w0_im);
-	FFT_1D_BUTTERFLY_HI(re2[j], im2[j], re3[j], im3[j], re_hi0_a, im_hi0_a, re_hi1_a, im_hi1_a, w0_re, w0_im);
-
-	FFT_1D_BUTTERFLY   (re0[k], im0[k], re1[k], im1[k], re_lo2_a, im_lo2_a, re_lo3_a, im_lo3_a, w0_re, w0_im);
-	FFT_1D_BUTTERFLY_HI(re2[k], im2[k], re3[k], im3[k], re_hi2_a, im_hi2_a, re_hi3_a, im_hi3_a, w0_re, w0_im);
-
-	FFT_1D_BUTTERFLY   (re0[j+stride_2x], im0[j+stride_2x], re1[j+stride_2x], im1[j+stride_2x], re_lo0_b, im_lo0_b, re_lo1_b, im_lo1_b, w0_re, w0_im);
-	FFT_1D_BUTTERFLY_HI(re2[j+stride_2x], im2[j+stride_2x], re3[j+stride_2x], im3[j+stride_2x], re_hi0_b, im_hi0_b, re_hi1_b, im_hi1_b, w0_re, w0_im);
-
-	FFT_1D_BUTTERFLY   (re0[k+stride_2x], im0[k+stride_2x], re1[k+stride_2x], im1[k+stride_2x], re_lo2_b, im_lo2_b, re_lo3_b, im_lo3_b, w0_re, w0_im);
-	FFT_1D_BUTTERFLY_HI(re2[k+stride_2x], im2[k+stride_2x], re3[k+stride_2x], im3[k+stride_2x], re_hi2_b, im_hi2_b, re_hi3_b, im_hi3_b, w0_re, w0_im);
-
-	j += stride_4x;
-	k += stride_4x;
-      } while (j < n_4);
-    }
-  }
-
-  /* Process stage log2_size-1. This is identical to the stage processing above
-   * except for this stage the inner loop is only executed once so it is removed
-   * entirely.
-   */
-  w_stride  = n_2 >> stage;
-  w_2stride = n   >> stage;
-  w_3stride = w_stride +  w_2stride;
-  w_4stride = w_2stride + w_2stride;
-
-  stride_2 = stride >> 1;
-  stride_4 = stride >> 2;
-
-  stride_3_4 = stride_2 + stride_4;
-
-  re0 = re;              im0 = im;
-  re1 = re + stride_2;   im1 = im + stride_2;   
-  re2 = re + stride_4;   im2 = im + stride_4;   
-  re3 = re + stride_3_4; im3 = im + stride_3_4;   
-
-  // unrolling this changes the minimum size to 64
-  // assert(n >= 64);
-  for (i=0, offset=0; i<stride_4; i+=2, offset += 2*w_4stride) {
-    /* Compute the twiddle factors
-     */
-    w0_a = W[offset];
-    w1_a = W[offset + w_stride];
-    w2_a = W[offset + w_2stride];
-    w3_a = W[offset + w_3stride];
-
-    tmp0_a = spu_shuffle(w0_a, w2_a, shuf_0415);
-    tmp1_a = spu_shuffle(w1_a, w3_a, shuf_0415);
-
-    w0_re_a = spu_shuffle(tmp0_a, tmp1_a, shuf_0415);
-    w0_im_a = spu_shuffle(tmp0_a, tmp1_a, shuf_2637);
-
-    w0_b = W[offset             + w_4stride];
-    w1_b = W[offset + w_stride  + w_4stride];
-    w2_b = W[offset + w_2stride + w_4stride];
-    w3_b = W[offset + w_3stride + w_4stride];
-
-    tmp0_b = spu_shuffle(w0_b, w2_b, shuf_0415);
-    tmp1_b = spu_shuffle(w1_b, w3_b, shuf_0415);
-
-    w0_re_b = spu_shuffle(tmp0_b, tmp1_b, shuf_0415);
-    w0_im_b = spu_shuffle(tmp0_b, tmp1_b, shuf_2637);
-
-    j = i;
-    k = i + stride;
-
-    re_lo0_a = re0[j]; im_lo0_a = im0[j];
-    re_lo1_a = re1[j]; im_lo1_a = im1[j];
-
-    re_hi0_a = re2[j]; im_hi0_a = im2[j];
-    re_hi1_a = re3[j]; im_hi1_a = im3[j];
-
-    re_lo2_a = re0[k]; im_lo2_a = im0[k];
-    re_lo3_a = re1[k]; im_lo3_a = im1[k];
-
-    re_hi2_a = re2[k]; im_hi2_a = im2[k];
-    re_hi3_a = re3[k]; im_hi3_a = im3[k];
-
-    re_lo0_b = re0[j+1]; im_lo0_b = im0[j+1];
-    re_lo1_b = re1[j+1]; im_lo1_b = im1[j+1];
-
-    re_hi0_b = re2[j+1]; im_hi0_b = im2[j+1];
-    re_hi1_b = re3[j+1]; im_hi1_b = im3[j+1];
-
-    re_lo2_b = re0[k+1]; im_lo2_b = im0[k+1];
-    re_lo3_b = re1[k+1]; im_lo3_b = im1[k+1];
-
-    re_hi2_b = re2[k+1]; im_hi2_b = im2[k+1];
-    re_hi3_b = re3[k+1]; im_hi3_b = im3[k+1];
-      
-    FFT_1D_BUTTERFLY   (re0[j], im0[j], re1[j], im1[j], re_lo0_a, im_lo0_a, re_lo1_a, im_lo1_a, w0_re_a, w0_im_a);
-    FFT_1D_BUTTERFLY_HI(re2[j], im2[j], re3[j], im3[j], re_hi0_a, im_hi0_a, re_hi1_a, im_hi1_a, w0_re_a, w0_im_a);
-
-    FFT_1D_BUTTERFLY   (re0[k], im0[k], re1[k], im1[k], re_lo2_a, im_lo2_a, re_lo3_a, im_lo3_a, w0_re_a, w0_im_a);
-    FFT_1D_BUTTERFLY_HI(re2[k], im2[k], re3[k], im3[k], re_hi2_a, im_hi2_a, re_hi3_a, im_hi3_a, w0_re_a, w0_im_a);
-
-    FFT_1D_BUTTERFLY   (re0[j+1], im0[j+1], re1[j+1], im1[j+1], re_lo0_b, im_lo0_b, re_lo1_b, im_lo1_b, w0_re_b, w0_im_b);
-    FFT_1D_BUTTERFLY_HI(re2[j+1], im2[j+1], re3[j+1], im3[j+1], re_hi0_b, im_hi0_b, re_hi1_b, im_hi1_b, w0_re_b, w0_im_b);
-
-    FFT_1D_BUTTERFLY   (re0[k+1], im0[k+1], re1[k+1], im1[k+1], re_lo2_b, im_lo2_b, re_lo3_b, im_lo3_b, w0_re_b, w0_im_b);
-    FFT_1D_BUTTERFLY_HI(re2[k+1], im2[k+1], re3[k+1], im3[k+1], re_hi2_b, im_hi2_b, re_hi3_b, im_hi3_b, w0_re_b, w0_im_b);
-  }
-
-
-  /* Process the final stage (stage log2_size). For this stage, 
-   * reformat the data from parallel arrays back into 
-   * interleaved arrays,storing the result into <in>.
-   *
-   * This loop has been manually unrolled by 2 to improve 
-   * dual issue rates and reduce stalls. This unrolling
-   * forces a minimum FFT size of 32.
-   */
-  re0 = re;
-  re1 = re + n_8;
-  re2 = re + n_16;
-  re3 = re + n_3_16;
-
-  im0 = im;
-  im1 = im + n_8;
-  im2 = im + n_16;
-  im3 = im + n_3_16;
-
-  out0_re = out_re;
-  out1_re = out_re  + n_8;
-  out2_re = out_re  + n_16;
-  out3_re = out1_re + n_16;
-
-  out0_im = out_im;
-  out1_im = out_im  + n_8;
-  out2_im = out_im  + n_16;
-  out3_im = out1_im + n_16;
-
-  i = n_16;
-
-  do {
-    /* Fetch the twiddle factors
-     */
-    w0_a = W[0];
-    w1_a = W[1];
-    w2_a = W[2];
-    w3_a = W[3];
-
-    w0_b = W[4];
-    w1_b = W[5];
-    w2_b = W[6];
-    w3_b = W[7];
-
-    W += 8;
-
-    w0_re_a = spu_shuffle(w0_a, w1_a, shuf_0246);
-    w0_im_a = spu_shuffle(w0_a, w1_a, shuf_1357);
-    w1_re_a = spu_shuffle(w2_a, w3_a, shuf_0246);
-    w1_im_a = spu_shuffle(w2_a, w3_a, shuf_1357);
-
-    w0_re_b = spu_shuffle(w0_b, w1_b, shuf_0246);
-    w0_im_b = spu_shuffle(w0_b, w1_b, shuf_1357);
-    w1_re_b = spu_shuffle(w2_b, w3_b, shuf_0246);
-    w1_im_b = spu_shuffle(w2_b, w3_b, shuf_1357);
-
-    /* Fetch the butterfly inputs, reals and imaginaries
-     */
-    re_lo0_a = re0[0]; im_lo0_a = im0[0];
-    re_lo1_a = re1[0]; im_lo1_a = im1[0];
-    re_lo2_a = re0[1]; im_lo2_a = im0[1];
-    re_lo3_a = re1[1]; im_lo3_a = im1[1];
-
-    re_hi0_a = re2[0]; im_hi0_a = im2[0];
-    re_hi1_a = re3[0]; im_hi1_a = im3[0];
-    re_hi2_a = re2[1]; im_hi2_a = im2[1];
-    re_hi3_a = re3[1]; im_hi3_a = im3[1];
-
-    re_lo0_b = re0[2]; im_lo0_b = im0[2];
-    re_lo1_b = re1[2]; im_lo1_b = im1[2];
-    re_lo2_b = re0[3]; im_lo2_b = im0[3];
-    re_lo3_b = re1[3]; im_lo3_b = im1[3];
-
-    re_hi0_b = re2[2]; im_hi0_b = im2[2];
-    re_hi1_b = re3[2]; im_hi1_b = im3[2];
-    re_hi2_b = re2[3]; im_hi2_b = im2[3];
-    re_hi3_b = re3[3]; im_hi3_b = im3[3];
-
-    re0 += 4; im0 += 4;
-    re1 += 4; im1 += 4;
-    re2 += 4; im2 += 4;
-    re3 += 4; im3 += 4;
-
-    /* Perform the butterflys
-     */
-    FFT_1D_BUTTERFLY   (out0_re[0], out0_im[0], out1_re[0], out1_im[0], re_lo0_a, im_lo0_a, re_lo1_a, im_lo1_a, w0_re_a, w0_im_a);
-    FFT_1D_BUTTERFLY   (out0_re[1], out0_im[1], out1_re[1], out1_im[1], re_lo2_a, im_lo2_a, re_lo3_a, im_lo3_a, w1_re_a, w1_im_a);
-
-    FFT_1D_BUTTERFLY_HI(out2_re[0], out2_im[0], out3_re[0], out3_im[0], re_hi0_a, im_hi0_a, re_hi1_a, im_hi1_a, w0_re_a, w0_im_a);
-    FFT_1D_BUTTERFLY_HI(out2_re[1], out2_im[1], out3_re[1], out3_im[1], re_hi2_a, im_hi2_a, re_hi3_a, im_hi3_a, w1_re_a, w1_im_a);
-
-    FFT_1D_BUTTERFLY   (out0_re[2], out0_im[2], out1_re[2], out1_im[2], re_lo0_b, im_lo0_b, re_lo1_b, im_lo1_b, w0_re_b, w0_im_b);
-    FFT_1D_BUTTERFLY   (out0_re[3], out0_im[3], out1_re[3], out1_im[3], re_lo2_b, im_lo2_b, re_lo3_b, im_lo3_b, w1_re_b, w1_im_b);
-
-    FFT_1D_BUTTERFLY_HI(out2_re[2], out2_im[2], out3_re[2], out3_im[2], re_hi0_b, im_hi0_b, re_hi1_b, im_hi1_b, w0_re_b, w0_im_b);
-    FFT_1D_BUTTERFLY_HI(out2_re[3], out2_im[3], out3_re[3], out3_im[3], re_hi2_b, im_hi2_b, re_hi3_b, im_hi3_b, w1_re_b, w1_im_b);
-
-
-    /* Store results into the output buffers */
-
-    out0_re += 4;
-    out1_re += 4;
-    out2_re += 4;
-    out3_re += 4;
-    out0_im += 4;
-    out1_im += 4;
-    out2_im += 4;
-    out3_im += 4;
-
-    i -= 4;
-  } while (i);
-}
-
-#endif /* _FFT_1D_R2_SPLIT_H_ */
Index: src/vsip/opt/cbe/spu/alf_vmul_s.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmul_s.c	(revision 209510)
+++ src/vsip/opt/cbe/spu/alf_vmul_s.c	(working copy)
@@ -10,76 +10,76 @@
     @brief   VSIPL++ Library: Kernel to compute vmul float.
 */
 
+#include <spu_intrinsics.h>
 #include <alf_accel.h>
 #include <vsip/opt/cbe/vmul_params.h>
 
 
 
-int alf_prepare_input_list(
+int input(
   void*        p_context,
   void*        p_params, 
-  void*        p_list_entries, 
+  void*        entries, 
   unsigned int current_count, 
   unsigned int total_count)
 {
   unsigned int const FP = 1; // Floats per point
 
   Vmul_params* params = (Vmul_params*)p_params;
-  addr64 ea;
+  alf_data_addr64_t ea;
 
   // Transfer input A.
-  ALF_DT_LIST_CREATE(p_list_entries, 0);
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(params->a_ptr + current_count * FP * params->a_blk_stride);
-  ALF_DT_LIST_ADD_ENTRY(p_list_entries,
-			FP * params->length,
-			ALF_DATA_FLOAT,
-			ea);
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+  ea = params->a_ptr + current_count * FP * params->a_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries,
+			  FP * params->length,
+			  ALF_DATA_FLOAT,
+			  ea);
 
   // Transfer input B.
-  ALF_DT_LIST_CREATE(p_list_entries, FP*params->length*sizeof(float));
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(params->b_ptr + current_count * FP * params->b_blk_stride);
-  ALF_DT_LIST_ADD_ENTRY(p_list_entries,
-			FP * params->length,
-			ALF_DATA_FLOAT,
-			ea);
+  ea = params->b_ptr + current_count * FP * params->b_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries,
+			  FP * params->length,
+			  ALF_DATA_FLOAT,
+			  ea);
 
+  ALF_ACCEL_DTL_END(entries);
+
   return 0;
 }
 
 
 
-int alf_prepare_output_list(
+int output(
   void*        p_context,
   void*        p_params, 
-  void*        p_list_entries, 
+  void*        entries, 
   unsigned int current_count, 
   unsigned int total_count)
 {
   unsigned int const FP = 1; // Floats per point
 
   Vmul_params* params = (Vmul_params*)p_params;
-  addr64 ea;
+  alf_data_addr64_t ea;
 
   // Transfer output R.
-  ALF_DT_LIST_CREATE(p_list_entries, 0);
-  ea.ui[0] = 0;
-  ea.ui[1] = (u32)(params->r_ptr + current_count * FP * params->r_blk_stride);
-  ALF_DT_LIST_ADD_ENTRY(p_list_entries,
-			FP * params->length,
-			ALF_DATA_FLOAT,
-			ea);
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
+  ea = params->r_ptr + current_count * FP * params->r_blk_stride;
+  ALF_ACCEL_DTL_ENTRY_ADD(entries,
+			  FP * params->length,
+			  ALF_DATA_FLOAT,
+			  ea);
   return 0;
 }
 
 
 
-int alf_comp_kernel(
-  void* p_context,
-  void* p_params,
-  void* input,
-  void* output,
+int kernel(
+  void*        p_context,
+  void*        p_params,
+  void*        input,
+  void*        output,
+  void*        inout,
   unsigned int iter,
   unsigned int n)
 {
@@ -107,3 +107,9 @@
 
   return 0;
 }
+
+ALF_ACCEL_EXPORT_API_LIST_BEGIN
+  ALF_ACCEL_EXPORT_API ("input", input);
+  ALF_ACCEL_EXPORT_API ("output", output); 
+  ALF_ACCEL_EXPORT_API ("kernel", kernel);
+ALF_ACCEL_EXPORT_API_LIST_END
Index: src/vsip/opt/cbe/spu/alf_fconvm_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconvm_split_c.c	(revision 209510)
+++ src/vsip/opt/cbe/spu/alf_fconvm_split_c.c	(working copy)
@@ -21,12 +21,12 @@
 #include <sys/time.h>
 #include <spu_mfcio.h>
 #include <alf_accel.h>
+#include <cml/spu/cml.h>
+#include <cml/spu/cml_core.h>
 
 #include <vsip/opt/cbe/fconv_params.h>
 
-#include "fft_1d_r2_split.h"
-#include "vmul_split.h"
-#include "spe_assert.h"
+#define _ALF_MAX_SINGLE_DT_SIZE 16*1024
 
 #if PERFMON
 #  include "timer.h"
@@ -43,48 +43,15 @@
   Definitions
 ***********************************************************************/
 
-// Twiddle factors.  For N-point convolution, N/4 twiddle factors
-// are required.
-static volatile float twiddle_factors[VSIP_IMPL_MAX_FCONV_SPLIT_SIZE*2/4]
-                __attribute__ ((aligned (128)));
-
 // Instance-id.  Used to determine when new coefficients must be loaded.
 static unsigned int instance_id = 0;
 
 
 
-unsigned int log2i(unsigned int size)
-{
-  unsigned int log2_size = 0;
-  while (!(size & 1))
-  { 
-    size >>= 1;
-    log2_size++;
-  }
-  return log2_size;
-}
-
-
-
-void initialize(
-  Fastconv_split_params* fc,
-  void volatile*         p_twiddles,
-  unsigned int           log2n)
-{
-  unsigned int n    = fc->elements;
-
-  // The number of twiddle factors is 1/4 the input size
-  mfc_get(p_twiddles, fc->ea_twiddle_factors, (n/4)*2*sizeof(float), 31, 0, 0);
-  mfc_write_tag_mask(1<<31);
-  mfc_read_tag_status_all();
-}
-
-
-
-int alf_prepare_input_list(
+int input(
   void*        context,
   void*        params,
-  void*        list_entries,
+  void*        entries,
   unsigned int current_count,
   unsigned int total_count)
 {
@@ -92,32 +59,35 @@
   (void)total_count;
 
   Fastconv_split_params* fc = (Fastconv_split_params *)params;
-  spe_assert(fc->elements * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
-  addr64 ea;
+  assert(fc->elements * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
+  alf_data_addr64_t ea;
 
   // Transfer input.
-  ALF_DT_LIST_CREATE(list_entries, 0);
-  ea.ull = fc->ea_input_re + current_count * fc->input_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
 
-  ea.ull = fc->ea_input_im + current_count * fc->input_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ea = fc->ea_input_re + current_count * fc->input_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
 
-  ea.ull = fc->ea_kernel_re + current_count * fc->kernel_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ea = fc->ea_input_im + current_count * fc->input_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
 
-  ea.ull = fc->ea_kernel_im + current_count * fc->kernel_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ea = fc->ea_kernel_re + current_count * fc->kernel_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
 
+  ea = fc->ea_kernel_im + current_count * fc->kernel_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
+
+  ALF_ACCEL_DTL_END(entries);
+
   return 0;
 }
 
 
 
-int alf_prepare_output_list(
+int output(
   void*        context,
   void*        params,
-  void*        list_entries,
+  void*        entries,
   unsigned int current_count,
   unsigned int total_count)
 {
@@ -125,33 +95,41 @@
   (void)total_count;
 
   Fastconv_split_params* fc = (Fastconv_split_params *)params;
-  spe_assert(fc->elements * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
-  addr64 ea;
+  assert(fc->elements * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
+  alf_data_addr64_t ea;
 
   // Transfer output.
-  ALF_DT_LIST_CREATE(list_entries, 0);
-  ea.ull = fc->ea_output_re + current_count * fc->output_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
 
-  ea.ull = fc->ea_output_im + current_count * fc->output_stride * sizeof(float);
-  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+  ea = fc->ea_output_re + current_count * fc->output_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
 
+  ea = fc->ea_output_im + current_count * fc->output_stride * sizeof(float);
+  ALF_ACCEL_DTL_ENTRY_ADD(entries, fc->elements, ALF_DATA_FLOAT, ea);
+
+  ALF_ACCEL_DTL_END(entries);
+
   return 0;
 }
 
 
 
-int alf_comp_kernel(void* context,
-		    void* params,
-                    void* input,
-                    void* output,
-                    unsigned int iter,
-                    unsigned int iter_max)
+int kernel(
+  void*        context,
+  void*        params,
+  void*        input,
+  void*        output,
+  void*        inout,
+  unsigned int iter,
+  unsigned int iter_max)
 {
+  static fft1d_f* obj;
+  static char*    buf;
+  static size_t   current_size = 0;
+
   Fastconv_split_params* fc = (Fastconv_split_params *)params;
-  unsigned int n = fc->elements;
-  unsigned int log2n = log2i(n);
-  spe_assert(n <= VSIP_IMPL_MAX_FCONV_SPLIT_SIZE);
+  unsigned int fft_size = fc->elements;
+  assert(fft_size <= VSIP_IMPL_MAX_FCONV_SPLIT_SIZE);
 
   (void)context;
   (void)iter;
@@ -164,14 +142,9 @@
   static acc_timer_t t4;
 #endif
 
-  // Initialization establishes the weights (kernel) for the
-  // convolution step and the twiddle factors for the FFTs.
-  // These are loaded once per task by checking a unique
-  // ID passed down from the caller.
   if (instance_id != fc->instance_id)
   {
     instance_id = fc->instance_id;
-    initialize(fc, twiddle_factors, log2n);
 #if PERFMON
     t1 = init_timer();
     t2 = init_timer();
@@ -180,88 +153,60 @@
 #endif
   }
 
-  float*        in_re  = (float *)input + 0 * n;
-  float*        in_im  = (float *)input + 1 * n;
-  float*     kernel_re = (float *)input + 2 * n;
-  float*     kernel_im = (float *)input + 3 * n;
-  vector float* W      = (vector float*)twiddle_factors;
-  float *       out_re = (float*)output + 0 * n;
-  float *       out_im = (float*)output + 1 * n;
+  // Reinitialize the FFT object if the fft size changes.
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
 
+  float* in_re    = (float*)input + 0 * fft_size;
+  float* in_im    = (float*)input + 1 * fft_size;
+  float* coeff_re = (float*)input + 2 * fft_size;
+  float* coeff_im = (float*)input + 3 * fft_size;
+  float* out_re   = (float*)output + 0 * fft_size;
+  float* out_im   = (float*)output + 1 * fft_size;
+
   // Perform the forward FFT on the kernel, in place, but
   // only if requested (this step is often done in advance).
   if (fc->transform_kernel)
   {
-    _fft_1d_r2_split((vector float*)kernel_re, (vector float*)kernel_im,
-		     (vector float*)kernel_re, (vector float*)kernel_im,
-		     (vector float*)twiddle_factors, log2n);
+    cml_zzfft1d_ip_f(obj,
+		     (float*)coeff_re, (float*)coeff_im,
+		     CML_FFT_FWD, buf);
   }
 
   // Switch to frequency space
   START_TIMER(&t1);
-  _fft_1d_r2_split((vector float*)in_re, (vector float*)in_im,
-		   (vector float*)in_re, (vector float*)in_im, W, log2n);
+  cml_zzfft1d_ip_f(obj,
+		   (float*)in_re, (float*)in_im,
+		   CML_FFT_FWD, buf);
   STOP_TIMER(&t1);
 
   // Perform convolution -- now a straight multiplication
   START_TIMER(&t2);
-  cvmul(out_re, out_im, kernel_re, kernel_im, in_re, in_im, n);
+  cml_zvmul1_f(coeff_re, coeff_im, in_re, in_im, out_re, out_im, fft_size);
   STOP_TIMER(&t2);
 
   // Revert back the time domain
   START_TIMER(&t3);
-  _fft_1d_r2_split((vector float*)out_im, (vector float*)out_re,
-		   (vector float*)out_im, (vector float*)out_re, W, log2n);
+  cml_zzfft1d_ip_f(obj,
+		   (float*)out_re, (float*)out_im,
+		   CML_FFT_INV, buf);
   STOP_TIMER(&t3);
 
   // Scale by 1/n.
   START_TIMER(&t4);
-  {
-    vector float vscale = spu_splats(1 / (float)n);
-    vector float* v_out_re = (vector float*)out_re;
-    vector float* v_out_im = (vector float*)out_im;
-
-    unsigned int i;
-    for (i=0; i<n; i+=16*4)
-    {
-      v_out_re[0] = spu_mul(v_out_re[0], vscale);
-      v_out_re[1] = spu_mul(v_out_re[1], vscale);
-      v_out_re[2] = spu_mul(v_out_re[2], vscale);
-      v_out_re[3] = spu_mul(v_out_re[3], vscale);
-      v_out_re[4] = spu_mul(v_out_re[4], vscale);
-      v_out_re[5] = spu_mul(v_out_re[5], vscale);
-      v_out_re[6] = spu_mul(v_out_re[6], vscale);
-      v_out_re[7] = spu_mul(v_out_re[7], vscale);
-      v_out_re[8] = spu_mul(v_out_re[8], vscale);
-      v_out_re[9] = spu_mul(v_out_re[9], vscale);
-      v_out_re[10] = spu_mul(v_out_re[10], vscale);
-      v_out_re[11] = spu_mul(v_out_re[11], vscale);
-      v_out_re[12] = spu_mul(v_out_re[12], vscale);
-      v_out_re[13] = spu_mul(v_out_re[13], vscale);
-      v_out_re[14] = spu_mul(v_out_re[14], vscale);
-      v_out_re[15] = spu_mul(v_out_re[15], vscale);
-
-      v_out_im[0] = spu_mul(v_out_im[0], vscale);
-      v_out_im[1] = spu_mul(v_out_im[1], vscale);
-      v_out_im[2] = spu_mul(v_out_im[2], vscale);
-      v_out_im[3] = spu_mul(v_out_im[3], vscale);
-      v_out_im[4] = spu_mul(v_out_im[4], vscale);
-      v_out_im[5] = spu_mul(v_out_im[5], vscale);
-      v_out_im[6] = spu_mul(v_out_im[6], vscale);
-      v_out_im[7] = spu_mul(v_out_im[7], vscale);
-      v_out_im[8] = spu_mul(v_out_im[8], vscale);
-      v_out_im[9] = spu_mul(v_out_im[9], vscale);
-      v_out_im[10] = spu_mul(v_out_im[10], vscale);
-      v_out_im[11] = spu_mul(v_out_im[11], vscale);
-      v_out_im[12] = spu_mul(v_out_im[12], vscale);
-      v_out_im[13] = spu_mul(v_out_im[13], vscale);
-      v_out_im[14] = spu_mul(v_out_im[14], vscale);
-      v_out_im[15] = spu_mul(v_out_im[15], vscale);
-
-      v_out_re += 16;
-      v_out_im += 16;
-    }
-  }
+  cml_core_rzsvmul1_f(1.f / fft_size, out_re, out_im, out_re, out_im,
+		      fft_size);
   STOP_TIMER(&t4);
 
 #if PERFMON
@@ -287,3 +232,9 @@
 
   return 0;
 }
+
+ALF_ACCEL_EXPORT_API_LIST_BEGIN
+  ALF_ACCEL_EXPORT_API ("input", input);
+  ALF_ACCEL_EXPORT_API ("output", output); 
+  ALF_ACCEL_EXPORT_API ("kernel", kernel);
+ALF_ACCEL_EXPORT_API_LIST_END
Index: src/vsip/opt/cbe/fft_params.h
===================================================================
--- src/vsip/opt/cbe/fft_params.h	(revision 209510)
+++ src/vsip/opt/cbe/fft_params.h	(working copy)
@@ -31,6 +31,7 @@
 #endif
 
 
+
 typedef enum
 {
   fwd_fft = 0,
@@ -42,14 +43,27 @@
 
 typedef struct
 {
-  fft_dir_type direction;
-  unsigned int elements;
-  double scale;
-  unsigned long long ea_twiddle_factors;
+  fft_dir_type       direction;
+  unsigned int       fft_size;
+  double             scale;
   unsigned long long ea_input_buffer;
   unsigned long long ea_output_buffer;
   unsigned int       in_blk_stride;
   unsigned int       out_blk_stride;
 } Fft_params;
 
+typedef struct
+{
+  fft_dir_type       direction;
+  unsigned int       fft_size;
+  double             scale;
+  unsigned long long ea_input_re;
+  unsigned long long ea_input_im;
+  unsigned long long ea_output_re;
+  unsigned long long ea_output_im;
+  unsigned int       in_blk_stride;
+  unsigned int       out_blk_stride;
+} Fft_split_params;
+
+
 #endif // VSIP_OPT_CBE_FFT_PARAMS_H
Index: src/vsip/opt/diag/fft.hpp
===================================================================
--- src/vsip/opt/diag/fft.hpp	(revision 209510)
+++ src/vsip/opt/diag/fft.hpp	(working copy)
@@ -232,7 +232,7 @@
 	 << "  o sz: " << fftm.output_size()[0].size() << " x "
 	               << fftm.output_size()[1].size() << endl
 	 << "  dir : " << (traits::dir == fft_fwd ? "fwd" : "inv") << endl
-	 << "  axis: " << (traits::axis == row ? "row" : "col") << endl
+	 << "  axis: " << ((dimension_type)traits::axis == row ? "row" : "col") << endl
 	 << "  rm  : " << (traits::rm == by_value ? "val" : "ref") << endl
 	 << "  be  : " << fftm.backend_.get()->name() << endl;
   }
Index: src/vsip/opt/diag/fir.hpp
===================================================================
Index: benchmarks/copy.cpp
===================================================================
--- benchmarks/copy.cpp	(revision 208645)
+++ benchmarks/copy.cpp	(working copy)
@@ -96,6 +96,12 @@
     for (index_type i=0; i<Z.local().size(); ++i)
     {
       index_type g_i = global_from_local_index(Z, 0, i);
+      if (!equal(Z.local().get(i), T(g_i)))
+      {
+	std::cout << "ERROR: at location " << i << std::endl
+		  << "       expected: " << T(g_i) << std::endl
+		  << "       got     : " << Z.local().get(i) << std::endl;
+      }
       test_assert(equal(Z.local().get(i), T(g_i)));
     }
     
Index: benchmarks/fastconv.cpp
===================================================================
--- benchmarks/fastconv.cpp	(revision 208645)
+++ benchmarks/fastconv.cpp	(working copy)
@@ -52,6 +52,14 @@
 
 
 /***********************************************************************
+  Globals
+***********************************************************************/
+
+bool check = true;
+
+
+
+/***********************************************************************
   Impl1op: out-of-place, phased fast-convolution
 ***********************************************************************/
 
@@ -907,22 +915,25 @@
     t1.stop();
 
     // CHECK RESULT
-    typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times>
+    if (check)
+    {
+      typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times>
 	  	for_fft_type;
 
-    Rand<T> gen(0, 0);
-    for_fft_type for_fft(Domain<1>(nrange), 1.0);
+      Rand<T> gen(0, 0);
+      for_fft_type for_fft(Domain<1>(nrange), 1.0);
 
-    data = gen.randu(npulse, nrange);
-    replica.put(0, T(1));
-    for_fft(replica);
+      data = gen.randu(npulse, nrange);
+      replica.put(0, T(1));
+      for_fft(replica);
+      
+      chk = inv_fftm(vmmul<0>(replica, for_fftm(data)));
 
-    chk = inv_fftm(vmmul<0>(replica, for_fftm(data)));
+      double error = error_db(LOCAL(data), LOCAL(chk));
 
-    double error = error_db(LOCAL(data), LOCAL(chk));
+      test_assert(error < -100);
+    }
 
-    test_assert(error < -100);
-
     time = t1.delta();
   }
 
@@ -1095,7 +1106,10 @@
   loop.start_      = 4;
   loop.stop_       = 16;
   loop.loop_start_ = 10;
-  loop.user_param_ = 64;
+
+  loop.param_["rows"] = "64";
+  loop.param_["size"] = "2048";
+  loop.param_["check"] = "1";
 }
 
 
@@ -1106,32 +1120,40 @@
   typedef vsip::impl::Cmplx_split_fmt Csf;
   typedef vsip::impl::Cmplx_inter_fmt Cif;
 
-  length_type param1 = loop.user_param_;
+  length_type rows  = atoi(loop.param_["rows"].c_str());
+  length_type size  = atoi(loop.param_["size"].c_str());
+  check             = (loop.param_["check"] == "1" ||
+		       loop.param_["check"] == "y");
+
+  std::cout << "rows: " << rows << "  size: " << size 
+	    << "  check: " << (check ? "yes" : "no")
+	    << std::endl;
+
   switch (what)
   {
-  case  1: loop(t_fastconv_pf<complex<float>, Impl1op>(param1)); break;
-  case  2: loop(t_fastconv_pf<complex<float>, Impl1ip>(param1)); break;
-  case  3: loop(t_fastconv_pf<complex<float>, Impl1pip1>(param1)); break;
-  case  4: loop(t_fastconv_pf<complex<float>, Impl1pip2>(param1)); break;
-  case  5: loop(t_fastconv_pf<complex<float>, Impl2op>(param1)); break;
-  case  6: loop(t_fastconv_pf<complex<float>, Impl2ip>(param1)); break;
-  case  7: loop(t_fastconv_pf<complex<float>, Impl2ip_tmp>(param1)); break;
-  case  8: loop(t_fastconv_pf<complex<float>, Impl2fv>(param1)); break;
-  case  9: loop(t_fastconv_pf<complex<float>, Impl4vc>(param1)); break;
-  case 10: loop(t_fastconv_pf<complex<float>, Impl4mc>(param1)); break;
+  case  1: loop(t_fastconv_pf<complex<float>, Impl1op>(rows)); break;
+  case  2: loop(t_fastconv_pf<complex<float>, Impl1ip>(rows)); break;
+  case  3: loop(t_fastconv_pf<complex<float>, Impl1pip1>(rows)); break;
+  case  4: loop(t_fastconv_pf<complex<float>, Impl1pip2>(rows)); break;
+  case  5: loop(t_fastconv_pf<complex<float>, Impl2op>(rows)); break;
+  case  6: loop(t_fastconv_pf<complex<float>, Impl2ip>(rows)); break;
+  case  7: loop(t_fastconv_pf<complex<float>, Impl2ip_tmp>(rows)); break;
+  case  8: loop(t_fastconv_pf<complex<float>, Impl2fv>(rows)); break;
+  case  9: loop(t_fastconv_pf<complex<float>, Impl4vc>(rows)); break;
+  case 10: loop(t_fastconv_pf<complex<float>, Impl4mc>(rows)); break;
 
-  case 11: loop(t_fastconv_rf<complex<float>, Impl1op>(param1)); break;
-  case 12: loop(t_fastconv_rf<complex<float>, Impl1ip>(param1)); break;
-  case 13: loop(t_fastconv_rf<complex<float>, Impl1pip1>(param1)); break;
-  case 14: loop(t_fastconv_rf<complex<float>, Impl1pip2>(param1)); break;
-  case 15: loop(t_fastconv_rf<complex<float>, Impl2op>(param1)); break;
-  case 16: loop(t_fastconv_rf<complex<float>, Impl2ip>(param1)); break;
-  case 17: loop(t_fastconv_rf<complex<float>, Impl2ip_tmp>(param1)); break;
-  case 18: loop(t_fastconv_rf<complex<float>, Impl2fv>(param1)); break;
-  case 19: loop(t_fastconv_rf<complex<float>, Impl4vc>(param1)); break;
-  case 20: loop(t_fastconv_rf<complex<float>, Impl4mc>(param1)); break;
+  case 11: loop(t_fastconv_rf<complex<float>, Impl1op>(size)); break;
+  case 12: loop(t_fastconv_rf<complex<float>, Impl1ip>(size)); break;
+  case 13: loop(t_fastconv_rf<complex<float>, Impl1pip1>(size)); break;
+  case 14: loop(t_fastconv_rf<complex<float>, Impl1pip2>(size)); break;
+  case 15: loop(t_fastconv_rf<complex<float>, Impl2op>(size)); break;
+  case 16: loop(t_fastconv_rf<complex<float>, Impl2ip>(size)); break;
+  case 17: loop(t_fastconv_rf<complex<float>, Impl2ip_tmp>(size)); break;
+  case 18: loop(t_fastconv_rf<complex<float>, Impl2fv>(size)); break;
+  case 19: loop(t_fastconv_rf<complex<float>, Impl4vc>(size)); break;
+  case 20: loop(t_fastconv_rf<complex<float>, Impl4mc>(size)); break;
 
-  case 101: loop(t_fastconv_pf<complex<float>, Impl1pip2_nopar>(param1)); break;
+  case 101: loop(t_fastconv_pf<complex<float>, Impl1pip2_nopar>(rows)); break;
 
 
   // case 101: loop(t_fastconv_pf<complex<float>, Impl3>(param1)); break;
@@ -1150,6 +1172,10 @@
       << "   -8 -- Foreach_vector, interleaved (2fv)\n"
       << "   -9 -- Fused expression, vector of coefficients (4vc)\n"
       << "  -10 -- Fused expression, matrix of coefficients (4mc)\n"
+      << "\n"
+      << " Parameters (for sweeping convolution size, cases 1 through 10)\n"
+      << "  -p:rows ROWS -- set number of pulses (default 64)\n"
+      << "\n"
       << " Sweeping number of pulses:\n"
       << "  -11 -- Out-of-place, phased\n"
       << "  -12 -- In-place, phased\n"
@@ -1161,6 +1187,12 @@
       << "  -18 -- Foreach_vector, interleaved (2fv)\n"
       << "  -19 -- Fused expression, vector of coefficients (4vc)\n"
       << "  -20 -- Fused expression, matrix of coefficients (4mc)\n"
+      << "\n"
+      << " Parameters (for sweeping number of convolutions, cases 11 through 20)\n"
+      << "  -p:size SIZE -- size of pulse (default 2048)\n"
+      << "\n"
+      << " Common Parameters\n"
+      << "  -p:check {0,n}|{1,y} -- check results (default 'y')\n"
       ;
 
   default: return 0;
Index: benchmarks/vmul.hpp
===================================================================
--- benchmarks/vmul.hpp	(revision 208645)
+++ benchmarks/vmul.hpp	(working copy)
@@ -528,6 +528,12 @@
 template <typename T, typename ComplexFmt>
 struct t_vmul2 : Benchmark_base
 {
+  // compile-time typedefs
+  typedef impl::Layout<1, row1_type, impl::Stride_unit_dense, ComplexFmt>
+		LP;
+  typedef impl::Fast_block<1, T, LP> block_type;
+
+  // benchmark attributes
   char* what() { return "t_vmul2"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
@@ -537,10 +543,6 @@
   void operator()(length_type size, length_type loop, float& time)
     VSIP_IMPL_NOINLINE
   {
-    typedef impl::Layout<1, row1_type, impl::Stride_unit_dense, ComplexFmt>
-		LP;
-    typedef impl::Fast_block<1, T, LP> block_type;
-
     Vector<T, block_type> A(size, T());
     Vector<T, block_type> B(size, T());
     Vector<T, block_type> C(size);
@@ -559,6 +561,17 @@
     
     time = t1.delta();
   }
+
+  void diag()
+  {
+    length_type const size = 256;
+
+    Vector<T, block_type> A(size, T());
+    Vector<T, block_type> B(size, T());
+    Vector<T, block_type> C(size);
+
+    vsip::impl::diagnose_eval_list_std(C, A * B);
+  }
 };
 #endif // VSIP_IMPL_SOURCERY_VPP
 
Index: benchmarks/fftm.cpp
===================================================================
--- benchmarks/fftm.cpp	(revision 208645)
+++ benchmarks/fftm.cpp	(working copy)
@@ -106,6 +106,9 @@
     if (!equal(Z(0, 0), T(scale_ ? 1.0 : SD == row ? cols : rows)))
     {
       std::cout << "t_fftm<T, Impl_op, SD>: ERROR" << std::endl;
+      std::cout << "   got     : " << Z(0, 0) << std::endl;
+      std::cout << "   expected: " << T(scale_ ? 1.0 : SD == row ? cols : rows)
+		<< std::endl;
       abort();
     }
     
@@ -173,13 +176,15 @@
     if (!equal(A(0, 0), T(SD == row ? cols : rows)))
     {
       std::cout << "t_fftm<T, Impl_ip, SD>: ERROR" << std::endl;
+      std::cout << "   got     : " << A(0, 0) << std::endl;
+      std::cout << "   expected: " << T(SD == row ? cols : rows) << std::endl;
       abort();
     }
     
     time = t1.delta();
   }
 
-  void diag_rc(length_type rows, length_type cols)
+  void diag_rc(length_type /*rows*/, length_type /*cols*/)
   {
     std::cout << "No diag\n";
   }
@@ -245,13 +250,16 @@
     if (!equal(Z(0, 0), T(SD == row ? cols : rows)))
     {
       std::cout << "t_fftm<T, Impl_pop, SD>: ERROR" << std::endl;
+      std::cout << "   got     : " << Z(0, 0) << std::endl;
+      std::cout << "   expected: " << T(SD == row ? cols : rows)
+		<< std::endl;
       abort();
     }
     
     time = t1.delta();
   }
 
-  void diag_rc(length_type rows, length_type cols)
+  void diag_rc(length_type /*rows*/, length_type /*cols*/)
   {
     std::cout << "No diag\n";
   }
@@ -274,7 +282,7 @@
 {
   static int const elem_per_point = 1;
 
-  char* what() { return "t_fftm<T, Impl_ip, SD>"; }
+  char* what() { return "t_fftm<T, Impl_pip1, SD>"; }
   float ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
 
@@ -318,14 +326,17 @@
 
     if (!equal(A(0, 0), T(SD == row ? cols : rows)))
     {
-      std::cout << "t_fftm<T, Impl_ip, SD>: ERROR" << std::endl;
+      std::cout << "t_fftm<T, Impl_pip1, SD>: ERROR" << std::endl;
+      std::cout << "   got     : " << A(0, 0) << std::endl;
+      std::cout << "   expected: " << T(SD == row ? cols : rows)
+		<< std::endl;
       abort();
     }
     
     time = t1.delta();
   }
 
-  void diag_rc(length_type rows, length_type cols)
+  void diag_rc(length_type /*rows*/, length_type /*cols*/)
   {
     std::cout << "No diag\n";
   }
@@ -348,7 +359,7 @@
 {
   static int const elem_per_point = 1;
 
-  char* what() { return "t_fftm<T, Impl_ip, SD>"; }
+  char* what() { return "t_fftm<T, Impl_pip2, SD>"; }
   float ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
 
@@ -405,14 +416,17 @@
 
     if (!equal(A(0, 0), T(SD == row ? cols : rows)))
     {
-      std::cout << "t_fftm<T, Impl_ip, SD>: ERROR" << std::endl;
+      std::cout << "t_fftm<T, Impl_pip2, SD>: ERROR" << std::endl;
+      std::cout << "   got     : " << A(0, 0) << std::endl;
+      std::cout << "   expected: " << T(SD == row ? cols : rows)
+		<< std::endl;
       abort();
     }
     
     time = t1.delta();
   }
 
-  void diag_rc(length_type rows, length_type cols)
+  void diag_rc(length_type /*rows*/, length_type /*cols*/)
   {
     std::cout << "No diag\n";
   }
@@ -465,7 +479,7 @@
     time = t1.delta();
   }
 
-  void diag_rc(length_type rows, length_type cols)
+  void diag_rc(length_type /*rows*/, length_type /*cols*/)
   {
     std::cout << "No diag\n";
   }
@@ -576,8 +590,8 @@
 {
   length_type rows  = atoi(loop.param_["rows"].c_str());
   length_type size  = atoi(loop.param_["size"].c_str());
-  bool scale  = (loop.param_["size"] == "1" ||
-		 loop.param_["size"] == "y");
+  bool scale  = (loop.param_["scale"] == "1" ||
+		 loop.param_["scale"] == "y");
 
   typedef complex<float>  Cf;
   typedef complex<double> Cd;
