Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 163038)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -15,11 +15,13 @@
   Included Files
 ***********************************************************************/
 
-#include <vsip/core/config.hpp>
 #include <vsip/support.hpp>
-#include <vsip/opt/cbe/ppu/fft.hpp>
+#include <vsip/core/aligned_allocator.hpp>
 #include <vsip/core/fft/backend.hpp>
 #include <vsip/core/fft/util.hpp>
+#include <vsip/opt/cbe/common.h>
+#include <vsip/opt/cbe/ppu/fft.hpp>
+#include <vsip/opt/cbe/ppu/task_manager.hpp>
 
 /***********************************************************************
   Declarations
@@ -32,8 +34,51 @@
 namespace cbe
 {
 
-template <dimension_type D, typename I, typename O, int A, int E> class Fft_impl;
+template <typename T>
+void 
+fft_8K(std::complex<T>* out, std::complex<T> const* in, 
+  std::complex<T> const* twiddle_factors, length_type length, 
+  T scale, int exponent)
+{
+  // Note: the twiddle factors require only 1/4 the memory of the input and 
+  // output arrays.
+  Fft_params fftp;
+  fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
+  fftp.elements = length;
+  fftp.scale = scale;
+  Task_manager *mgr = Task_manager::instance();
+  Task task = mgr->reserve<Fft_tag, void(complex<T>,complex<T>)>(
+    sizeof(Fft_params), sizeof(complex<T>)*(length*5/4), 
+    sizeof(complex<T>)*length);
+  Workblock block = task.create_block();
+  block.set_parameters(fftp);
+  block.add_input(in, length);
+  block.add_input(twiddle_factors, length/4);
+  block.add_output(out, length);
+  task.enqueue(block);
+  task.wait();
+}
 
+template<typename T>
+void
+compute_twiddle_factors(std::complex<T>* twiddle_factors, length_type length)
+{
+  unsigned int i = 0;
+  unsigned int n = length;
+  T* W = reinterpret_cast<T*>(twiddle_factors);
+  W[0] = 1.0f;
+  W[1] = 0.0f;
+  for (i = 1; i < n / 4; ++i) 
+  {
+    W[2*i] = cos(i * 2*M_PI / n);
+    W[2*(n/4 - i)+1] = -W[2*i];
+  }
+}
+
+
+template <dimension_type D, typename I, typename O, int A, int E> 
+class Fft_impl;
+
 // 1D complex -> complex FFT
 
 template <typename T, int A, int E>
@@ -46,14 +91,23 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  Fft_impl(Domain<1> const &dom)
+  Fft_impl(Domain<1> const &dom, rtype scale) VSIP_THROW((std::bad_alloc))
+      : scale_(scale),
+        W_(alloc_align<ctype>(VSIP_IMPL_ALLOC_ALIGNMENT, dom.size()/4))
   {
-    // TBD
+    compute_twiddle_factors(W_, dom.size());
   }
-  virtual void in_place(ctype *inout, stride_type s, length_type l)
+  virtual ~Fft_impl()
   {
-    // TBD
+    delete(W_);
   }
+
+  virtual bool supports_scale() { return true;}
+  virtual void in_place(ctype *inout, stride_type stride, length_type length)
+  {
+    assert(stride == 1);
+    fft_8K<T>(inout, inout, W_, length, this->scale_, E);
+  }
   virtual void in_place(ztype, stride_type, length_type)
   {
   }
@@ -61,13 +115,19 @@
 			    ctype *out, stride_type out_stride,
 			    length_type length)
   {
-    // TBD
+    assert(in_stride == 1);
+    assert(out_stride == 1);
+    fft_8K<T>(out, in, W_, length, this->scale_, E);
   }
   virtual void by_reference(ztype, stride_type,
 			    ztype, stride_type,
 			    length_type)
   {
   }
+
+private:
+  rtype scale_;
+  ctype* W_;
 };
 
 // 1D real -> complex FFT
@@ -81,10 +141,11 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  Fft_impl(Domain<1> const &dom)
+  Fft_impl(Domain<1> const & dom, rtype scale)
   {
-    // TBD
   }
+
+  virtual bool supports_scale() { return true;}
   virtual void by_reference(rtype *in, stride_type,
 			    ctype *out, stride_type,
 			    length_type)
@@ -110,7 +171,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  Fft_impl(Domain<1> const &dom)
+  Fft_impl(Domain<1> const &dom, rtype scale)
   {
     // TBD
   }
@@ -131,13 +192,13 @@
 
 };
 
-#define VSIPL_IMPL_PROVIDE(D, I, O, A, E)	       \
-template <>                                            \
-std::auto_ptr<fft::backend<D, I, O, A, E> >	       \
-create(Domain<D> const &dom)            	       \
-{                                                      \
-  return std::auto_ptr<fft::backend<D, I, O, A, E> >   \
-    (new Fft_impl<D, I, O, A, E>(dom));                \
+#define VSIPL_IMPL_PROVIDE(D, I, O, A, E)	                             \
+template <>                                                                  \
+std::auto_ptr<fft::backend<D, I, O, A, E> >	                             \
+create(Domain<D> const &dom, fft::backend<D, I, O, A, E>::scalar_type scale) \
+{                                                                            \
+  return std::auto_ptr<fft::backend<D, I, O, A, E> >                         \
+    (new Fft_impl<D, I, O, A, E>(dom, scale));                               \
 }
 
 VSIPL_IMPL_PROVIDE(1, float, std::complex<float>, 0, -1)
Index: src/vsip/opt/cbe/ppu/task_manager.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/task_manager.hpp	(revision 163038)
+++ src/vsip/opt/cbe/ppu/task_manager.hpp	(working copy)
@@ -35,6 +35,10 @@
 {
 namespace impl
 {
+
+struct Fft_tag;
+
+
 namespace cbe
 {
 
@@ -119,5 +123,6 @@
 
 DEFINE_IMAGE(op::Mult, float(float, float), vmul_s)
 DEFINE_IMAGE(op::Mult, std::complex<float>(std::complex<float>, std::complex<float>), vmul_c)
+DEFINE_IMAGE(Fft_tag, void(std::complex<float>, std::complex<float>), fft_c)
 
 #endif
Index: src/vsip/opt/cbe/ppu/fft.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.hpp	(revision 163038)
+++ src/vsip/opt/cbe/ppu/fft.hpp	(working copy)
@@ -25,6 +25,7 @@
 #include <vsip/domain.hpp>
 #include <vsip/core/fft/factory.hpp>
 #include <vsip/core/fft/util.hpp>
+#include <vsip/opt/cbe/common.h>
 
 /***********************************************************************
   Declarations
@@ -37,14 +38,14 @@
 namespace cbe
 {
 
-template <typename I, dimension_type D>
+template <typename I, dimension_type D, typename S>
 std::auto_ptr<I>
-create(Domain<D> const &dom);
+create(Domain<D> const &dom, S scale);
 
 #define VSIP_IMPL_FFT_DECL(D,I,O,A,E)                          \
 template <>                                                    \
 std::auto_ptr<fft::backend<D,I,O,A,E> >                        \
-create(Domain<D> const &);
+create(Domain<D> const &, fft::backend<D, I, O, A, E>::scalar_type);
 
 #define VSIP_IMPL_FFT_DECL_T(T)				       \
 VSIP_IMPL_FFT_DECL(1, T, std::complex<T>, 0, -1)               \
@@ -60,7 +61,7 @@
 #define VSIP_IMPL_FFT_DECL(I,O,A,E)                            \
 template <>                                                    \
 std::auto_ptr<fft::fftm<I,O,A,E> >                             \
-create(Domain<2> const &);
+create(Domain<2> const &, fft::backend<2, I, O, A, E>::scalar_type);
 
 #define VSIP_IMPL_FFT_DECL_T(T)				       \
 VSIP_IMPL_FFT_DECL(T, std::complex<T>, 0, -1)                  \
@@ -92,16 +93,23 @@
 struct evaluator<D, I, O, S, R, N, Cbe_sdk_tag>
 {
   static bool const ct_valid = true;
-  static bool rt_valid(Domain<D> const &) { return true;}
+  static bool rt_valid(Domain<D> const &dom) 
+  { 
+    unsigned int log2_size = static_cast<unsigned int>(log2(dom.size()));
+    return
+      (dom.size() >= MIN_FFT_1D_SIZE) &&
+      (dom.size() <= MAX_FFT_1D_SIZE) &&
+      (dom.size() == static_cast<unsigned int>(1 << log2_size));
+  }
   static std::auto_ptr<backend<D, I, O,
  			       axis<I, O, S>::value,
  			       exponent<I, O, S>::value> >
-  create(Domain<D> const &dom, typename Scalar_of<I>::type)
+  create(Domain<D> const &dom, typename Scalar_of<I>::type scale)
   {
     return cbe::create<backend<D, I, O, 
       axis<I, O, S>::value,
       exponent<I, O, S>::value> >
-      (dom);
+      (dom, scale);
   }
 };
 
@@ -120,9 +128,9 @@
   static bool const ct_valid = true;
   static bool rt_valid(Domain<2> const &/*dom*/) { return true;}
   static std::auto_ptr<fft::fftm<I, O, A, E> > 
-  create(Domain<2> const &dom, typename impl::Scalar_of<I>::type /*scale*/)
+  create(Domain<2> const &dom, typename impl::Scalar_of<I>::type scale)
   {
-    return cbe::create<fft::fftm<I, O, A, E> >(dom);
+    return cbe::create<fft::fftm<I, O, A, E> >(dom, scale);
   }
 };
 
Index: src/vsip/opt/cbe/ppu/alf.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/alf.hpp	(revision 163038)
+++ src/vsip/opt/cbe/ppu/alf.hpp	(working copy)
@@ -63,26 +63,32 @@
 
   template <typename P>
   void set_parameters(P const &p) 
-  {
-    alf_wb_add_param(impl_, const_cast<P *>(&p), sizeof(p), ALF_DATA_BYTE, 0);
+  { 
+    int alf_wb_add_param_ret = alf_wb_add_param(impl_, 
+      const_cast<P *>(&p), sizeof(p), ALF_DATA_BYTE, 0);
+    assert( alf_wb_add_param_ret >= 0 );
   }
   template <typename D>
   void add_input(D const *d, unsigned int length)
   {
     // The data size is doubled in the case of complex values, because
     // ALF only understands floats and doubles.
-    alf_wb_add_io_buffer(impl_, ALF_BUFFER_INPUT, const_cast<D *>(d),
-                         length * (Is_complex<D>::value ? 2 : 1),
-                         alf_data_type<D>::value);
+    int alf_wb_add_io_buffer_ret = alf_wb_add_io_buffer(impl_, 
+      ALF_BUFFER_INPUT, const_cast<D *>(d),
+      length * (Is_complex<D>::value ? 2 : 1), 
+      alf_data_type<D>::value);
+    assert( alf_wb_add_io_buffer_ret >= 0 );
   }
   template <typename D>
   void add_output(D *d, unsigned int length)
   {
     // The data size is doubled in the case of complex values, because
     // ALF only understands floats and doubles.
-    alf_wb_add_io_buffer(impl_, ALF_BUFFER_OUTPUT, d,
-                         length * (Is_complex<D>::value ? 2 : 1),
-                         alf_data_type<D>::value);
+    int alf_wb_add_io_buffer_ret = alf_wb_add_io_buffer(impl_, 
+      ALF_BUFFER_OUTPUT, d,
+      length * (Is_complex<D>::value ? 2 : 1),
+      alf_data_type<D>::value);
+    assert( alf_wb_add_io_buffer_ret >= 0 );
   }
 
 private:
@@ -148,7 +154,11 @@
     alf_task_info_t info;
     alf_task_info_t_CBEA spe_tsk;
     spe_tsk.spe_task_image = image;
-    spe_tsk.max_stack_size = 4096; // compute good value !
+    // The stack size is determined by accounting for the *worst case*
+    // stack requirements are, which, to date, are _at least_ equal
+    // to 64 KB for the 8 K FFT (using two temporary arrays of 4 bytes
+    // per point each).
+    spe_tsk.max_stack_size = 80*1024;
     info.p_task_info = &spe_tsk;
     info.parm_ctx_buffer_size = psize;
     info.input_buffer_size = isize;
Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 163038)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -33,11 +33,11 @@
 endif
 
 CC_SPU := spu-gcc
-CPP_SPU_FLAGS := -I $(CBE_SDK_PREFIX)/sysroot/usr/spu/include
-CC_SPU_FLAGS := 
+CPP_SPU_FLAGS := -I $(CBE_SDK_PREFIX)/sysroot/usr/spu/include -I $(srcdir)/src
+CC_SPU_FLAGS := @CXXFLAGS@
 LD_SPU_FLAGS := -Wl,-N -L$(CBE_SDK_PREFIX)/sysroot/usr/spu/lib
 CC_EMBED_SPU := ppu-embedspu -m32
-SPU_LIBS := -lalf
+SPU_LIBS := -lalf -lfft
 
 ########################################################################
 # Rules
Index: src/vsip/opt/cbe/spu/vmul.cpp
===================================================================
--- src/vsip/opt/cbe/spu/vmul.cpp	(revision 163038)
+++ src/vsip/opt/cbe/spu/vmul.cpp	(working copy)
@@ -1,155 +0,0 @@
-/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
- 
-   This file is available for license from CodeSourcery, Inc. under the terms
-   of a commercial license and under the GPL.  It is not part of the VSIPL++
-   reference implementation and is not available under the BSD license.
-*/
-/** @file    vsip/opt/cbe/spu/vmul.cpp
-    @author  Stefan Seefeld
-    @date    2006-12-29
-    @brief   VSIPL++ Library: vector-multiply kernel.
-*/
-
-#include <spu_mfcio.h>
-#include <stdio.h>
-#include <string.h>
-#include <vsip/opt/cbe/vmul.h>
-
-
-data_block db __attribute__ ((aligned (128)));
-command_block cb __attribute__ ((aligned (128)));
-
-// These are used for DMA buffer management (in the Local Store)
-data_block db_list[256];    // store data blocks (operands)
-void* ls_addr[256];         // store associated LS addresses
-
-// This is the actual portion of the LS reserved for computation
-#define COMPUTE_BUFFER_SIZE  (64*1024)
-char ls_data[COMPUTE_BUFFER_SIZE] __attribute__ ((aligned (128)));
-unsigned int ls_index = 0;
-
-
-
-int main(unsigned long long speid, addr64 argp, addr64 envp) 
-{
-  int i;
-  int bytes_avail;
-  int transfer_size;
-
-  argp = argp;  /* eliminate warnings */
-  envp = envp;
-
-  memset(db_list, 0, sizeof(db_list));
-  memset(ls_addr, 0, sizeof(ls_addr));
-
-  unsigned int opcode;
-  addr64 ea;
-
-  while (1)
-  {
-    opcode = (unsigned int) spu_read_in_mbox ();
-
-    switch (opcode)
-    {
-    case cmd_operand_data:
-
-      // The next word gives us the address of the descriptor for the 
-      // data block, which is of a known size.  Fetch the descriptor
-      // and wait for it to arrive.
-      ea.ull = spu_read_in_mbox();
-      mfc_get(&db, ea.ull, sizeof(db), 31, 0, 0);
-      mfc_write_tag_mask(1<<31);
-      mfc_read_tag_status_all();
-
-
-      // DMA the data from system memory to our local store buffer.
-
-      // check space remaining
-      bytes_avail = COMPUTE_BUFFER_SIZE - ls_index;
-      transfer_size = db.element_size * db.num_elements;
-      if (bytes_avail < transfer_size)
-      {
-	printf( "SPU %llu: Error: insufficient space for data block!\n", speid );
-	break;
-      }
-      // store the entry, start the DMA, update the index and wait
-      db_list[db.id] = db;
-      ls_addr[db.id] = &ls_data[ls_index];
-      ls_index += transfer_size;
-
-      if (db.prefetch)
-      {
-	mfc_get(ls_addr[db.id], db.addr.ull, transfer_size, 31, 0, 0);
-	mfc_read_tag_status_all();
-      }
-      break;
-
-    case cmd_elementwise_compute:
-    {
-      // The next word gives us the address of the descriptor for the 
-      // command block, which is of a known size.  Fetch the descriptor
-      // and wait for it to arrive.
-      ea.ull = spu_read_in_mbox();
-      mfc_get(&cb, ea.ull, sizeof(cb), 31, 0, 0);
-      mfc_write_tag_mask(1<<31);
-      mfc_read_tag_status_all();
-
-      float* A = static_cast<float*>(ls_addr[cb.op_A_id]);
-      float* B = static_cast<float*>(ls_addr[cb.op_B_id]);
-      float* C = static_cast<float*>(ls_addr[cb.result_id]);
-      if (!A || !B || !C)
-      {
-	printf( "SPU %llu: Error: missing data blocks!\n", speid );
-      }
-      else
-      {
-	int size = db_list[cb.op_A_id].num_elements;
-	if ( size != db_list[cb.op_B_id].num_elements ||
-	     size != db_list[cb.op_B_id].num_elements )
-        {
-	  printf( "SPU %llu: Error: incongruent data blocks!\n", speid );
-	}
-	else
-        {
-	  // Do the actual computation
-	  for (i = 0; i < size; ++i)
-	    C[i] = A[i] * B[i];
-	}
-      }
-
-      // Push the result data back to main memory
-      data_block *db = &db_list[cb.result_id];
-      transfer_size = db->element_size * db->num_elements;
-      mfc_put(ls_addr[cb.result_id], db->addr.ull, transfer_size, 31, 0, 0);
-      mfc_read_tag_status_all();
-
-      // Set the completion flag in the command block as an acknowledgement 
-      // signal and DMA it back to the PPE.
-      cb.completed = 1;
-      mfc_put((void *)&cb, ea.ui[1], sizeof(cb), 3, 0, 0);
-      mfc_write_tag_mask(1 << 3);
-      mfc_read_tag_status_all();
-    }
-    break;
-
-    case cmd_flush_blocks:
-    {
-      memset(db_list, 0, sizeof(db_list));
-      memset(ls_addr, 0, sizeof(ls_addr));
-      ls_index = 0;
-    }
-    break;
-
-    case cmd_terminate_thread:
-    {
-      return 0;
-    }
-    break;
-
-    default:
-      printf("SPU %llu: Error: unknown opcode %d\n", speid, opcode);
-      break;
-    }
-  }
-  return 0;
-}
Index: src/vsip/opt/cbe/spu/alf_fft_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fft_c.c	(revision 0)
+++ src/vsip/opt/cbe/spu/alf_fft_c.c	(revision 0)
@@ -0,0 +1,101 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/spu/alf_fft_c.c
+    @author  Don McCoy
+    @date    2007-02-03
+    @brief   VSIPL++ Library: Kernel to compute complex float FFT's.
+*/
+
+#include <alf_accel.h>
+#include <assert.h>
+#include <libfft.h>
+#include <vsip/opt/cbe/common.h>
+
+unsigned int log2i(unsigned int size)
+{
+  unsigned int log2_size = 0;
+  while (!(size & 1))
+  { 
+    size >>= 1;
+    log2_size++;
+  }
+  return log2_size;
+}
+
+
+
+int alf_comp_kernel(void volatile *params,
+                    void volatile *input,
+                    void volatile *output,
+                    unsigned int iter,
+                    unsigned int iter_max)
+{
+  Fft_params* fftp = (Fft_params *)params;
+  unsigned int n = fftp->elements;
+  assert(n <= MAX_FFT_1D_SIZE);
+
+  vector float* in = (vector float *)input;
+  vector float* W = (vector float *)((float *)in + n * 2);
+  vector float* out = (vector float*)output;
+
+  unsigned int log2_size = log2i(n);
+  unsigned int const vec_size = 4; 
+
+  // Perform the FFT, 
+  //   -- 'in' may be the same as 'out'
+  fft_1d_r2(out, in, W, log2_size);
+
+
+  if (fftp->direction == fwd_fft)
+  {
+    // Forward FFT support scaling, but for efficiency, this step
+    // can be skipped for a scale factor of one.
+    if (fftp->scale != (double)1.f)
+    {
+      unsigned int i;
+      vector float *start;
+      vector float vscale = spu_splats((float)fftp->scale);
+      vector float s;
+      start = out;
+      
+      // Scale the output vector.
+      // Note: there are two float values for each of 'n' complex values.
+      for (i = 0; i < 2 * n / vec_size; ++i) 
+      {
+        s = *start;
+        *start++ = spu_mul(s, vscale);
+      }
+    }
+  }
+  else
+  {
+    // Code for the inverse FFT taken from the CBE SDK Libraries
+    // Overview and Users Guide, sec. 8.1.
+    unsigned int i;
+    vector float *start, *end, s0, s1, e0, e1;
+    vector unsigned int mask = (vector unsigned int){-1, -1, 0, 0};
+    vector float vscale = spu_splats((float)fftp->scale);
+    start = out;
+
+    // Scale the output vector and swap the order of the outputs.
+    // Note: there are two float values for each of 'n' complex values.
+    end = start + 2 * n / vec_size;
+    s0 = e1 = *start;
+    for (i = 0; i < n / vec_size; ++i) 
+    {
+      s1 = *(start + 1);
+      e0 = *(--end);
+
+      *start++ = spu_mul(spu_sel(e0, e1, mask), vscale);
+      *end = spu_mul(spu_sel(s0, s1, mask), vscale);
+      s0 = s1;
+      e1 = e0;
+    }
+  }
+
+  return 0;
+}
Index: src/vsip/opt/cbe/vmul.h
===================================================================
--- src/vsip/opt/cbe/vmul.h	(revision 163038)
+++ src/vsip/opt/cbe/vmul.h	(working copy)
@@ -1,60 +0,0 @@
-/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
-
-   This file is available for license from CodeSourcery, Inc. under the terms
-   of a commercial license and under the GPL.  It is not part of the VSIPL++
-   reference implementation and is not available under the BSD license.
-*/
-/** @file    vsip/opt/cbe/vmul.h
-    @author  Don McCoy
-    @date    2006-12-31
-    @brief   VSIPL++ Library: Vectory multiply for Cell BE
-*/
-
-#ifndef VSIP_OPT_CBE_VMUL_H
-#define VSIP_OPT_CBE_VMUL_H
-
-enum spe_function_type
-{
-  cmd_terminate_thread = 0x1000,
-  cmd_operand_data,
-  cmd_elementwise_compute,
-  cmd_flush_blocks
-};
-
-typedef enum
-{
-  nop = 0,
-  vector_multiply
-} op_type;
-
-
-typedef union
-{
-  unsigned long long ull;
-  unsigned int ui[2];
-  void const* p;
-} addr64;
-
-
-// keep all DMA-able structures sized in multiples of 128-bits
-
-typedef struct                  // used with operand_data
-{
-  unsigned int element_size;
-  unsigned short num_elements;
-  unsigned char id;
-  unsigned char prefetch;
-  addr64 addr;
-} data_block; 
-
-typedef struct                  // used with elementwise_compute
-{
-  op_type op;
-  unsigned char result_id;
-  unsigned char op_A_id;
-  unsigned char op_B_id;
-  unsigned char completed;
-  unsigned int pad[2];
-} command_block;
-
-#endif // VSIP_OPT_CBE_VMUL_H
Index: src/vsip/opt/cbe/common.h
===================================================================
--- src/vsip/opt/cbe/common.h	(revision 0)
+++ src/vsip/opt/cbe/common.h	(revision 0)
@@ -0,0 +1,50 @@
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/common.h
+    @author  Don McCoy
+    @date    2007-02-04
+    @brief   VSIPL++ Library: Common definitions for Cell BE SDK functions.
+*/
+
+#ifndef VSIP_OPT_CBE_COMMON_H
+#define VSIP_OPT_CBE_COMMON_H
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
+} Fft_params;
+
+#endif // VSIP_OPT_CBE_COMMON_H
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 163038)
+++ ChangeLog	(working copy)
@@ -1,3 +1,17 @@
+2007-02-12  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/opt/cbe/ppu/fft.cpp: Added handlers for 8K point FFTs.
+	* src/vsip/opt/cbe/ppu/task_manager.hpp: Declared FFT SPE image.
+	* src/vsip/opt/cbe/ppu/fft.hpp: Added scale parameter for evaluators.
+	* src/vsip/opt/cbe/ppu/alf.hpp: Increased stack size, added assert()
+	  to check return value for add_* functions.
+	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Added FFT library.
+	* src/vsip/opt/cbe/spu/vmul.cpp: Removed, obsolete.
+	* src/vsip/opt/cbe/spu/alf_fft_c.c: New file, implements 1-D FFT.
+	* src/vsip/opt/cbe/vmul.h: Removed, obsolete.
+	* src/vsip/opt/cbe/common.h: New file, definitions common to both
+	  SPE and PPE sides.
+
 2007-02-08  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/parallel/block.hpp: Include distributed_block.hpp
