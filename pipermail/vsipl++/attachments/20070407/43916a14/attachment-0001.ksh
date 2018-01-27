Index: src/vsip/opt/cbe/ppu/eval_fastconv.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/eval_fastconv.hpp	(revision 167975)
+++ src/vsip/opt/cbe/ppu/eval_fastconv.hpp	(working copy)
@@ -75,7 +75,7 @@
   typedef typename DstBlock::value_type dst_type;
   typedef typename SrcBlock::value_type src_type;
   typedef typename Block_layout<DstBlock>::complex_type complex_type;
-  typedef impl::cbe::Fastconv<T, complex_type> fconv_type;
+  typedef impl::cbe::Fastconv<1, T, complex_type> fconv_type;
 
   static bool const ct_valid = Type_equal<T, std::complex<float> >::value;
 
Index: src/vsip/opt/cbe/ppu/task_manager.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/task_manager.hpp	(revision 167975)
+++ src/vsip/opt/cbe/ppu/task_manager.hpp	(working copy)
@@ -40,6 +40,7 @@
 struct Mult_tag;
 struct Fft_tag;
 struct Fastconv_tag;
+struct Fastconvm_tag;
 struct Vmmul_tag;
 
 
@@ -145,6 +146,8 @@
 DEFINE_TASK(3, Fft_tag, void(std::complex<float>, std::complex<float>), fft_c)
 DEFINE_TASK(4, Fastconv_tag, void(std::complex<float>, std::complex<float>), fconv_c)
 DEFINE_TASK(5, Fastconv_tag, void(split_float_type, split_float_type), fconv_split_c)
-DEFINE_TASK(6, Vmmul_tag, std::complex<float>(std::complex<float>, std::complex<float>), vmmul_c)
+DEFINE_TASK(6, Fastconvm_tag, void(std::complex<float>, std::complex<float>), fconvm_c)
+DEFINE_TASK(7, Fastconvm_tag, void(split_float_type, split_float_type), fconvm_split_c)
+DEFINE_TASK(8, Vmmul_tag, std::complex<float>(std::complex<float>, std::complex<float>), vmmul_c)
 
 #endif
Index: src/vsip/opt/cbe/ppu/fastconv.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.cpp	(revision 167975)
+++ src/vsip/opt/cbe/ppu/fastconv.cpp	(working copy)
@@ -38,10 +38,12 @@
 
 // Fast convolution binding for interleaved complex data.
 
-template <typename T,
-	  typename ComplexFmt>
+
+template <dimension_type D,
+          typename       T,
+	  typename       ComplexFmt>
 void
-Fastconv_base<T, ComplexFmt>::fconv
+Fastconv_base<D, T, ComplexFmt>::fconv
   (T* in, T* kernel, T* out, length_type rows, length_type length)
 {
   Fastconv_params params;
@@ -55,6 +57,7 @@
   params.ea_kernel          = reinterpret_cast<unsigned long long>(kernel);
   params.ea_input           = reinterpret_cast<unsigned long long>(in);
   params.ea_output          = reinterpret_cast<unsigned long long>(out);
+  params.kernel_stride      = length;
   params.input_stride       = length;
   params.output_stride      = length;
 
@@ -62,10 +65,18 @@
   // The stack size takes into account two temporary buffers used
   // to hold the real and imaginary parts of the complex input data.
   length_type stack_size = 4096 + 
-    2*sizeof(T)*cbe::Fastconv_traits<T, complex_type>::max_size;
+    2 * sizeof(T) * cbe::Fastconv_traits<dim, T, complex_type>::max_size;
+  typedef typename cbe::Fastconv_traits<dim, T, complex_type>::tag_type tag_type;
+
+  // In the case of a matrix of coefficients (dim == 2), there are two inputs,
+  // one row of source data and one row of coefficients.  In the normal case, 
+  // where the coeffcients are the same for each row, they are sent in 
+  // advance, leaving only one input.
+  length_type const num_inputs = (dim == 1 ? 1 : 2);
+
   Task_manager *mgr = Task_manager::instance();
-  Task task = mgr->reserve<Fastconv_tag, void(T,T)>
-    (stack_size, psize, sizeof(T)*length, sizeof(T)*length, true);
+  Task task = mgr->reserve<tag_type, void(T,T)>
+    (stack_size, psize, sizeof(T)*length*num_inputs, sizeof(T)*length, true);
 
   length_type spes         = mgr->num_spes();
   length_type rows_per_spe = rows / spes;
@@ -78,7 +89,10 @@
     Workblock block = task.create_multi_block(my_rows);
     block.set_parameters(params);
     task.enqueue(block);
-
+    // Note: for a matrix of coefficients, unique rows are transferred.
+    // For the normal case, the address is constant because the same
+    // vector is sent repeatedly.
+    params.ea_kernel += (dim == 1 ? 0 : sizeof(T) * my_rows * length);
     params.ea_input  += sizeof(T) * my_rows * length;
     params.ea_output += sizeof(T) * my_rows * length;
   }
@@ -87,13 +101,13 @@
 }
 
 
-
 // Fast convolution binding for split complex data.
 
-template <typename T,
-	  typename ComplexFmt>
+template <dimension_type D,
+          typename       T,
+	  typename       ComplexFmt>
 void
-Fastconv_base<T, ComplexFmt>::fconv(
+Fastconv_base<D, T, ComplexFmt>::fconv(
   std::pair<uT*,uT*> in,
   std::pair<uT*,uT*> kernel,
   std::pair<uT*,uT*> out,
@@ -114,6 +128,7 @@
   params.ea_input_im        = reinterpret_cast<unsigned long long>(in.second);
   params.ea_output_re       = reinterpret_cast<unsigned long long>(out.first);
   params.ea_output_im       = reinterpret_cast<unsigned long long>(out.second);
+  params.kernel_stride      = length;
   params.input_stride       = length;
   params.output_stride      = length;
 
@@ -122,11 +137,14 @@
   // but experimentation indicates that performance is hurt by 
   // reducing this value.
   length_type stack_size = 4096 + 
-    sizeof(T)*cbe::Fastconv_traits<T, complex_type>::max_size;
+    sizeof(T)*cbe::Fastconv_traits<dim, T, complex_type>::max_size;
+  typedef typename cbe::Fastconv_traits<dim, T, complex_type>::tag_type tag_type;
+  length_type const num_inputs = (dim == 1 ? 1 : 2);
+
   Task_manager *mgr = Task_manager::instance();
-  Task task = mgr->reserve<Fastconv_tag, void(std::pair<uT*,uT*>,
-					      std::pair<uT*,uT*>)>
-    (stack_size, psize, sizeof(T)*length, sizeof(T)*length, true);
+  Task task = mgr->reserve<tag_type, void(std::pair<uT*,uT*>,
+					  std::pair<uT*,uT*>)>
+    (stack_size, psize, sizeof(T)*length*num_inputs, sizeof(T)*length, true);
 
   length_type spes         = mgr->num_spes();
   length_type rows_per_spe = rows / spes;
@@ -139,21 +157,24 @@
     Workblock block = task.create_multi_block(my_rows);
     block.set_parameters(params);
     task.enqueue(block);
-
-    params.ea_input_re  += sizeof(T) * my_rows * length;
-    params.ea_input_im  += sizeof(T) * my_rows * length;
-    params.ea_output_re += sizeof(T) * my_rows * length;
-    params.ea_output_im += sizeof(T) * my_rows * length;
+    params.ea_kernel_re += (dim == 1 ? 0 : sizeof(uT) * my_rows * length);
+    params.ea_kernel_im += (dim == 1 ? 0 : sizeof(uT) * my_rows * length);
+    params.ea_input_re  += sizeof(uT) * my_rows * length;
+    params.ea_input_im  += sizeof(uT) * my_rows * length;
+    params.ea_output_re += sizeof(uT) * my_rows * length;
+    params.ea_output_im += sizeof(uT) * my_rows * length;
   }
 
   task.sync();
 }
 
 
-template <typename T,
-	  typename ComplexFmt>
+template <dimension_type D,
+          typename       T,
+	  typename       ComplexFmt>
 void
-Fastconv_base<T, ComplexFmt>::compute_twiddle_factors(length_type length)
+Fastconv_base<D, T, ComplexFmt>::compute_twiddle_factors(
+  length_type length)
 {
   typedef typename Scalar_of<T>::type stype;
 
@@ -173,22 +194,30 @@
 typedef std::complex<float> ctype;
 typedef std::pair<float*,float*> ztype;
 
-template void Fastconv_base<ctype, Cmplx_inter_fmt>::fconv(
-  ctype* in, ctype* kernel, 
-  ctype* out, length_type rows, length_type length);
-template void Fastconv_base<ctype, Cmplx_split_fmt>::fconv(
-  ztype in, ztype kernel, 
-  ztype out, length_type rows, length_type length);
-template void Fastconv_base<ctype, Cmplx_inter_fmt>::compute_twiddle_factors(
-  length_type length);
-template void Fastconv_base<ctype, Cmplx_split_fmt>::compute_twiddle_factors(
-  length_type length);
+#define INSTANTIATE_FASTCONV(COEFFS_DIM)                                       \
+template void                                                                  \
+Fastconv_base<COEFFS_DIM, ctype, Cmplx_inter_fmt>::fconv(                      \
+  ctype* in, ctype* kernel, ctype* out, length_type rows, length_type length); \
+template void                                                                  \
+Fastconv_base<COEFFS_DIM, ctype, Cmplx_inter_fmt>::compute_twiddle_factors(    \
+  length_type length);                                                         \
+template<> unsigned int                                                        \
+Fastconv_base<COEFFS_DIM, ctype, Cmplx_inter_fmt>::instance_id_counter_ = 0;   \
+template void                                                                  \
+Fastconv_base<COEFFS_DIM, ctype, Cmplx_split_fmt>::fconv(                      \
+  ztype in, ztype kernel, ztype out, length_type rows, length_type length);    \
+template void                                                                  \
+Fastconv_base<COEFFS_DIM, ctype, Cmplx_split_fmt>::compute_twiddle_factors(    \
+  length_type length);                                                         \
+template<> unsigned int                                                        \
+Fastconv_base<COEFFS_DIM, ctype, Cmplx_split_fmt>::instance_id_counter_ = 0; 
 
-template<>
-unsigned int Fastconv_base<ctype, Cmplx_inter_fmt>::instance_id_counter_ = 0;
-template<>
-unsigned int Fastconv_base<ctype, Cmplx_split_fmt>::instance_id_counter_ = 0;
+INSTANTIATE_FASTCONV(1);
+INSTANTIATE_FASTCONV(2);
 
+#undef INSTANTIATE_FASTCONV
+
+          
 } // namespace vsip::impl::cbe
 } // namespace vsip::impl
 } // namespace vsip
Index: src/vsip/opt/cbe/ppu/fastconv.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.hpp	(revision 167975)
+++ src/vsip/opt/cbe/ppu/fastconv.hpp	(working copy)
@@ -38,19 +38,38 @@
 namespace cbe
 {
 
-template <typename T, typename ComplexFmt> struct Fastconv_traits;
+template <dimension_type D,
+          typename T,
+	  typename ComplexFmt> 
+struct Fastconv_traits;
 template <>
-struct Fastconv_traits<std::complex<float>, Cmplx_inter_fmt>
+struct Fastconv_traits<1, std::complex<float>, Cmplx_inter_fmt>
 {
+  typedef Fastconv_tag tag_type;
   static length_type const min_size = VSIP_IMPL_MIN_FCONV_SIZE;
   static length_type const max_size = VSIP_IMPL_MAX_FCONV_SIZE;
 };
 template <>
-struct Fastconv_traits<std::complex<float>, Cmplx_split_fmt>
+struct Fastconv_traits<1, std::complex<float>, Cmplx_split_fmt>
 {
+  typedef Fastconv_tag tag_type;
   static length_type const min_size = VSIP_IMPL_MIN_FCONV_SPLIT_SIZE;
   static length_type const max_size = VSIP_IMPL_MAX_FCONV_SPLIT_SIZE;
 };
+template <>
+struct Fastconv_traits<2, std::complex<float>, Cmplx_inter_fmt>
+{
+  typedef Fastconvm_tag tag_type;
+  static length_type const min_size = VSIP_IMPL_MIN_FCONV_SIZE;
+  static length_type const max_size = VSIP_IMPL_MAX_FCONV_SIZE;
+};
+template <>
+struct Fastconv_traits<2, std::complex<float>, Cmplx_split_fmt>
+{
+  typedef Fastconvm_tag tag_type;
+  static length_type const min_size = VSIP_IMPL_MIN_FCONV_SPLIT_SIZE;
+  static length_type const max_size = VSIP_IMPL_MAX_FCONV_SPLIT_SIZE;
+};
 
 // Fast convolution object using SPEs to perform computation.
 
@@ -59,35 +78,57 @@
 //   COMPLEXFMT to be the complex format (either Cmplx_inter_fmt or
 //     Cmplx_split_fmt) to be processed.
 
-template <typename T,
-	  typename ComplexFmt>
+template <dimension_type D,
+          typename       T,
+	  typename       ComplexFmt>
 class Fastconv_base
 {
+  static dimension_type const dim = D;
+
   typedef ComplexFmt complex_type;
   typedef Layout<1, row1_type, Stride_unit_dense, complex_type> layout1_type;
   typedef Layout<2, row2_type, Stride_unit_dense, complex_type> layout2_type;
-  typedef Fast_block<1, T, layout1_type, Local_map> kernel_block_type;
 
+  typedef Layout<dim, row2_type, 
+                 Stride_unit_dense, complex_type>   kernel_layout_type;
+  typedef Fast_block<dim, T, 
+                     kernel_layout_type, Local_map> kernel_block_type;
+
 public:
   template <typename Block>
-  Fastconv_base(Vector<T, Block> coeffs, length_type input_size,
+  Fastconv_base(Vector<T, Block> coeffs, Domain<dim> input_size,
 		bool transform_kernel)
-    : kernel_         (input_size, T()),
+    : kernel_          (input_size[0].size(), T()),
       transform_kernel_(transform_kernel),
-      size_           (input_size),
-      twiddle_factors_(input_size / 4),
-      instance_id_    (++instance_id_counter_)
+      size_            (input_size[0].size()),
+      twiddle_factors_ (input_size[0].size() / 4),
+      instance_id_     (++instance_id_counter_)
   {
-    assert(rt_valid_size(input_size));
-    assert(coeffs.size() <= input_size);
+    assert(rt_valid_size(size_));
+    assert(coeffs.size(0) <= size_);
     kernel_(view_domain(coeffs)) = coeffs.local();
-    compute_twiddle_factors(input_size);
+    compute_twiddle_factors(input_size[0].size());
   }
 
+  template <typename Block>
+  Fastconv_base(Matrix<T, Block> coeffs, Domain<dim> input_size,
+		bool transform_kernel)
+    : kernel_          (input_size[0].size(), input_size[1].size(), T()),
+      transform_kernel_(transform_kernel),
+      size_            (input_size[1].size()),
+      twiddle_factors_ (input_size[1].size() / 4),
+      instance_id_     (++instance_id_counter_)
+  {
+    assert(rt_valid_size(size_));
+    assert(coeffs.size(1) <= size_);
+    kernel_(view_domain(coeffs)) = coeffs.local();
+    compute_twiddle_factors(input_size[1].size());
+  }
+
   static bool rt_valid_size(length_type size)
   {
-    return (size >= cbe::Fastconv_traits<T, complex_type>::min_size &&
-	    size <= cbe::Fastconv_traits<T, complex_type>::max_size &&
+    return (size >= cbe::Fastconv_traits<dim, T, complex_type>::min_size &&
+	    size <= cbe::Fastconv_traits<dim, T, complex_type>::max_size &&
 	    fft::is_power_of_two(size));
   }
 
@@ -127,8 +168,11 @@
   void fconv(std::pair<uT*,uT*> in, std::pair<uT*,uT*> kernel,
 	     std::pair<uT*,uT*> out, length_type rows, length_type length);
 
+  typedef typename View_of_dim<D, T, kernel_block_type>::type kernel_view_type;
 
-  Vector<T, kernel_block_type> kernel_;
+  // Member data.
+  Domain<dim> input_size_;
+  kernel_view_type kernel_;
   bool transform_kernel_;
   length_type size_;
   aligned_array<T> twiddle_factors_;
@@ -143,22 +187,78 @@
 
 
 
+template <dimension_type D,
+          typename T,
+	  typename ComplexFmt = Cmplx_inter_fmt>
+class Fastconv;
 
-template <typename T,
-	  typename ComplexFmt = Cmplx_inter_fmt>
-class Fastconv : public Fastconv_base<T, ComplexFmt>
+template <typename T, typename ComplexFmt>
+class Fastconv<1, T, ComplexFmt> : public Fastconv_base<1, T, ComplexFmt>
 {
   // Constructors, copies, assignments, and destructors.
 public:
+
   template <typename Block>
-  Fastconv(Vector<T, Block>   filter_coeffs,
-           length_type        input_size,
+  Fastconv(Vector<T, Block> filter_coeffs,
+           length_type input_size,
 	   bool transform_kernel = true)
     VSIP_THROW((std::bad_alloc))
-    : Fastconv_base<T, ComplexFmt>(filter_coeffs, input_size,
-				   transform_kernel)
+    : Fastconv_base<1, T, ComplexFmt>(filter_coeffs, 
+          Domain<1>(input_size), transform_kernel)
   {}
+  ~Fastconv() VSIP_NOTHROW {}
 
+  // Fastconv operators.
+public:
+  template <typename Block1,
+	    typename Block2>
+  Vector<T, Block2>
+  operator()(
+    const_Vector<T, Block1> in, 
+    Vector<T, Block2>       out)
+      VSIP_NOTHROW
+  {
+    assert(in.size() == this->size());
+    assert(out.size() == this->size());
+    
+    this->convolve(in.local(), out.local());
+    
+    return out;
+  }
+
+  template <typename Block1,
+	    typename Block2>
+  Matrix<T, Block2>
+  operator()(
+    const_Matrix<T, Block1> in, 
+    Matrix<T, Block2>       out)
+    VSIP_NOTHROW
+  {
+    assert(in.size(1) == this->size());
+    assert(out.size(1) == this->size());
+    
+    this->convolve(in.local(), out.local());
+    
+    return out;
+  }
+};
+
+
+
+template <typename T, typename ComplexFmt>
+class Fastconv<2, T, ComplexFmt> : public Fastconv_base<2, T, ComplexFmt>
+{
+  // Constructors, copies, assignments, and destructors.
+public:
+
+  template <typename Block>
+  Fastconv(Matrix<T, Block> filter_coeffs,
+           length_type input_size,
+	   bool transform_kernel = true)
+    VSIP_THROW((std::bad_alloc))
+    : Fastconv_base<2, T, ComplexFmt>(filter_coeffs, 
+          Domain<2>(filter_coeffs.size(0), input_size), transform_kernel) 
+  {}
   ~Fastconv() VSIP_NOTHROW {}
 
   // Fastconv operators.
Index: src/vsip/opt/cbe/spu/fft_1d_r2.h
===================================================================
--- src/vsip/opt/cbe/spu/fft_1d_r2.h	(revision 167975)
+++ src/vsip/opt/cbe/spu/fft_1d_r2.h	(working copy)
@@ -163,9 +163,7 @@
 
   n_3_16 = n_8 + n_16;
 
-  //  printf(">>>>>>>>  %d  %d  %d  %d\n", log2_size, n, n_16, n_3_16);
 
-
   reverse = byte_reverse[log2_size];
 
   /* Perform the first 3 stages of the FFT. These stages differs from 
Index: src/vsip/opt/cbe/spu/alf_fconvm_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconvm_c.c	(revision 0)
+++ src/vsip/opt/cbe/spu/alf_fconvm_c.c	(revision 0)
@@ -0,0 +1,193 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/spu/alf_fconvm_c.c
+    @author  Don McCoy
+    @date    2007-03-28
+    @brief   VSIPL++ Library: Kernel to compute multiple fast convolutions
+               (with distinct convolutions for each row of the matrix).
+*/
+
+#include <sys/time.h>
+#include <spu_mfcio.h>
+#include <alf_accel.h>
+#include <vsip/opt/cbe/fconv_params.h>
+#include "fft_1d_r2.h"
+#include "spe_assert.h"
+
+// The twiddle factors occupy only 1/4 the space as the inputs, 
+// outputs and convolution kernels.
+static float twiddle_factors[2 * VSIP_IMPL_MAX_FCONV_SIZE / 4] 
+       __attribute__ ((aligned (128)));
+
+static unsigned int instance_id = 0;
+
+#define VEC_SIZE  (4)
+
+unsigned int 
+log2i(unsigned int size)
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
+void 
+initialize(
+    unsigned long long ea_twiddles,  // source address in main memory
+    void volatile*     p_twiddles,   // destination address in local store
+    unsigned int       n)            // number of elements
+{
+  unsigned int size = n * 2 * sizeof(float);
+
+  // The number of twiddle factors is 1/4 the input size
+  mfc_get(p_twiddles, ea_twiddles, size/4, 31, 0, 0);
+  mfc_write_tag_mask(1<<31);
+  mfc_read_tag_status_all();
+}
+
+
+
+int 
+alf_prepare_input_list(
+    void*        context,
+    void*        params,
+    void*        list_entries,
+    unsigned int current_count,
+    unsigned int total_count)
+{
+  unsigned int const FP = 2; // Complex data: 2 floats per point.
+
+  Fastconv_params* fc = (Fastconv_params *)params;
+  spe_assert(fc->elements * FP *sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
+  addr64 ea;
+
+  // Transfer input.
+  ALF_DT_LIST_CREATE(list_entries, 0);
+  ea.ull = fc->ea_input + 
+    current_count * FP * fc->input_stride * sizeof(float);
+  ALF_DT_LIST_ADD_ENTRY(list_entries, FP * fc->elements, ALF_DATA_FLOAT, ea);
+
+  // Transfer kernel.
+  ea.ull = fc->ea_kernel + 
+    current_count * FP * fc->kernel_stride * sizeof(float);
+  ALF_DT_LIST_ADD_ENTRY(list_entries, FP * fc->elements, ALF_DATA_FLOAT, ea);
+
+  return 0;
+}
+
+
+
+int 
+alf_prepare_output_list(
+    void*        context,
+    void*        params,
+    void*        list_entries,
+    unsigned int current_count,
+    unsigned int total_count)
+{
+  unsigned int const FP = 2; // Complex data: 2 floats per point.
+
+  Fastconv_params* fc = (Fastconv_params *)params;
+  spe_assert(fc->elements * FP *sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
+  addr64 ea;
+
+  // Transfer output.
+  ALF_DT_LIST_CREATE(list_entries, 0);
+  ea.ull = fc->ea_output + 
+    current_count * FP * fc->output_stride * sizeof(float);
+  ALF_DT_LIST_ADD_ENTRY(list_entries, FP * fc->elements, ALF_DATA_FLOAT, ea);
+
+  return 0;
+}
+
+
+
+int 
+alf_comp_kernel(
+    void volatile* context,
+    void volatile* params,
+    void volatile* input,
+    void volatile* output,
+    unsigned int   current_count,
+    unsigned int   total_count)
+{
+  Fastconv_params* fc = (Fastconv_params *)params;
+  unsigned int n = fc->elements;
+  unsigned int log2n = log2i(n);
+  spe_assert(n <= VSIP_IMPL_MAX_FCONV_SIZE);
+
+  // Initialization establishes the weights (kernel) for the
+  // convolution step and the twiddle factors for the FFTs.
+  // These are loaded once per task by checking a unique
+  // ID passed down from the caller.
+  if (instance_id != fc->instance_id)
+  {
+    instance_id = fc->instance_id;
+    initialize(fc->ea_twiddle_factors, twiddle_factors, n);
+  }
+
+  vector float* in = (vector float *)input;
+  vector float* k = (vector float *)input + 2 * n / VEC_SIZE;
+  vector float* W = (vector float*)twiddle_factors;
+  vector float* out = (vector float*)output;
+
+  // Create real & imaginary working arrays
+  vector float re[n / VEC_SIZE], im[n / VEC_SIZE];
+
+
+  // Perform the forward FFT on the kernel, in place, but
+  // only if requested (this step is often done in advance).
+  if (fc->transform_kernel)
+  {
+    _fft_1d_r2_pre(re, im, k, W, log2n);
+    _fft_1d_r2_fini(k, re, im, W, log2n);
+  }
+
+
+  // Perform the forward FFT, rolling the convolution into 
+  // the last stage
+  _fft_1d_r2_pre(re, im, in, W, log2n);
+  _fft_1d_r2_fini_cvmul(out, re, im, k, W, log2n);
+
+
+  // Revert back the time domain.  
+  _fft_1d_r2_pre(re, im, out, W, log2n);
+  _fft_1d_r2_fini(out, re, im, W, log2n);
+
+
+  // Code for the inverse FFT scaling is taken from the CBE 
+  // SDK Libraries Overview and Users Guide, sec. 8.1.  
+  {
+    unsigned int i;
+    vector float *start, *end, s0, s1, e0, e1;
+    vector unsigned int mask = (vector unsigned int){-1, -1, 0, 0};
+    vector float vscale = spu_splats(1 / (float)n);
+    start = out;
+
+    // Scale the output vector and swap the order of the outputs.
+    // Note: there are two float values for each of 'n' complex values.
+    end = start + 2 * n / VEC_SIZE;
+    s0 = e1 = *start;
+    for (i = 0; i < n / VEC_SIZE; ++i) 
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
Index: src/vsip/opt/cbe/spu/alf_fconvm_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconvm_split_c.c	(revision 0)
+++ src/vsip/opt/cbe/spu/alf_fconvm_split_c.c	(revision 0)
@@ -0,0 +1,289 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/spu/alf_fconvm_split_c.c
+    @author  Don McCoy, Jules Bergmann
+    @date    2007-04-05
+    @brief   VSIPL++ Library: Kernel to compute fast convolution using
+             split-complex (with distinct convolutions for each row 
+	     of the matrix).
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#define PERFMON 0
+
+#include <sys/time.h>
+#include <spu_mfcio.h>
+#include <alf_accel.h>
+
+#include <vsip/opt/cbe/fconv_params.h>
+
+#include "fft_1d_r2_split.h"
+#include "vmul_split.h"
+#include "spe_assert.h"
+
+#if PERFMON
+#  include "timer.h"
+#  define START_TIMER(x) start_timer(x)
+#  define STOP_TIMER(x)  stop_timer(x)
+#else
+#  define START_TIMER(x)
+#  define STOP_TIMER(x)
+#endif
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Twiddle factors.  For N-point convolution, N/4 twiddle factors
+// are required.
+static volatile float twiddle_factors[VSIP_IMPL_MAX_FCONV_SPLIT_SIZE*2/4]
+                __attribute__ ((aligned (128)));
+
+// Instance-id.  Used to determine when new coefficients must be loaded.
+static unsigned int instance_id = 0;
+
+
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
+void initialize(
+  Fastconv_split_params* fc,
+  void volatile*         p_twiddles,
+  unsigned int           log2n)
+{
+  unsigned int n    = fc->elements;
+
+  // The number of twiddle factors is 1/4 the input size
+  mfc_get(p_twiddles, fc->ea_twiddle_factors, (n/4)*2*sizeof(float), 31, 0, 0);
+  mfc_write_tag_mask(1<<31);
+  mfc_read_tag_status_all();
+}
+
+
+
+int alf_prepare_input_list(
+  void*        context,
+  void*        params,
+  void*        list_entries,
+  unsigned int current_count,
+  unsigned int total_count)
+{
+  (void)context;
+  (void)total_count;
+
+  Fastconv_split_params* fc = (Fastconv_split_params *)params;
+  spe_assert(fc->elements * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
+  addr64 ea;
+
+  // Transfer input.
+  ALF_DT_LIST_CREATE(list_entries, 0);
+  ea.ull = fc->ea_input_re + current_count * fc->input_stride * sizeof(float);
+  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+
+  ea.ull = fc->ea_input_im + current_count * fc->input_stride * sizeof(float);
+  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+
+  ea.ull = fc->ea_kernel_re + current_count * fc->kernel_stride * sizeof(float);
+  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+
+  ea.ull = fc->ea_kernel_im + current_count * fc->kernel_stride * sizeof(float);
+  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+
+  return 0;
+}
+
+
+
+int alf_prepare_output_list(
+  void*        context,
+  void*        params,
+  void*        list_entries,
+  unsigned int current_count,
+  unsigned int total_count)
+{
+  (void)context;
+  (void)total_count;
+
+  Fastconv_split_params* fc = (Fastconv_split_params *)params;
+  spe_assert(fc->elements * sizeof(float) <= _ALF_MAX_SINGLE_DT_SIZE);
+  addr64 ea;
+
+  // Transfer output.
+  ALF_DT_LIST_CREATE(list_entries, 0);
+  ea.ull = fc->ea_output_re + current_count * fc->output_stride * sizeof(float);
+  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+
+  ea.ull = fc->ea_output_im + current_count * fc->output_stride * sizeof(float);
+  ALF_DT_LIST_ADD_ENTRY(list_entries, fc->elements, ALF_DATA_FLOAT, ea);
+
+  return 0;
+}
+
+
+
+int alf_comp_kernel(void volatile *context,
+		    void volatile *params,
+                    void volatile *input,
+                    void volatile *output,
+                    unsigned int iter,
+                    unsigned int iter_max)
+{
+  Fastconv_split_params* fc = (Fastconv_split_params *)params;
+  unsigned int n = fc->elements;
+  unsigned int log2n = log2i(n);
+  spe_assert(n <= VSIP_IMPL_MAX_FCONV_SPLIT_SIZE);
+
+  (void)context;
+  (void)iter;
+  (void)iter_max;
+
+#if PERFMON
+  static acc_timer_t t1;
+  static acc_timer_t t2;
+  static acc_timer_t t3;
+  static acc_timer_t t4;
+#endif
+
+  // Initialization establishes the weights (kernel) for the
+  // convolution step and the twiddle factors for the FFTs.
+  // These are loaded once per task by checking a unique
+  // ID passed down from the caller.
+  if (instance_id != fc->instance_id)
+  {
+    instance_id = fc->instance_id;
+    initialize(fc, twiddle_factors, log2n);
+#if PERFMON
+    t1 = init_timer();
+    t2 = init_timer();
+    t3 = init_timer();
+    t4 = init_timer();
+#endif
+  }
+
+  float*        in_re  = (float *)input + 0 * n;
+  float*        in_im  = (float *)input + 1 * n;
+  float*     kernel_re = (float *)input + 2 * n;
+  float*     kernel_im = (float *)input + 3 * n;
+  vector float* W      = (vector float*)twiddle_factors;
+  float *       out_re = (float*)output + 0 * n;
+  float *       out_im = (float*)output + 1 * n;
+
+  // Perform the forward FFT on the kernel, in place, but
+  // only if requested (this step is often done in advance).
+  if (fc->transform_kernel)
+  {
+    _fft_1d_r2_split((vector float*)kernel_re, (vector float*)kernel_im,
+		     (vector float*)kernel_re, (vector float*)kernel_im,
+		     (vector float*)twiddle_factors, log2n);
+  }
+
+  // Switch to frequency space
+  START_TIMER(&t1);
+  _fft_1d_r2_split((vector float*)in_re, (vector float*)in_im,
+		   (vector float*)in_re, (vector float*)in_im, W, log2n);
+  STOP_TIMER(&t1);
+
+  // Perform convolution -- now a straight multiplication
+  START_TIMER(&t2);
+  cvmul(out_re, out_im, kernel_re, kernel_im, in_re, in_im, n);
+  STOP_TIMER(&t2);
+
+  // Revert back the time domain
+  START_TIMER(&t3);
+  _fft_1d_r2_split((vector float*)out_im, (vector float*)out_re,
+		   (vector float*)out_im, (vector float*)out_re, W, log2n);
+  STOP_TIMER(&t3);
+
+  // Scale by 1/n.
+  START_TIMER(&t4);
+  {
+    vector float vscale = spu_splats(1 / (float)n);
+    vector float* v_out_re = (vector float*)out_re;
+    vector float* v_out_im = (vector float*)out_im;
+
+    unsigned int i;
+    for (i=0; i<n; i+=16*4)
+    {
+      v_out_re[0] = spu_mul(v_out_re[0], vscale);
+      v_out_re[1] = spu_mul(v_out_re[1], vscale);
+      v_out_re[2] = spu_mul(v_out_re[2], vscale);
+      v_out_re[3] = spu_mul(v_out_re[3], vscale);
+      v_out_re[4] = spu_mul(v_out_re[4], vscale);
+      v_out_re[5] = spu_mul(v_out_re[5], vscale);
+      v_out_re[6] = spu_mul(v_out_re[6], vscale);
+      v_out_re[7] = spu_mul(v_out_re[7], vscale);
+      v_out_re[8] = spu_mul(v_out_re[8], vscale);
+      v_out_re[9] = spu_mul(v_out_re[9], vscale);
+      v_out_re[10] = spu_mul(v_out_re[10], vscale);
+      v_out_re[11] = spu_mul(v_out_re[11], vscale);
+      v_out_re[12] = spu_mul(v_out_re[12], vscale);
+      v_out_re[13] = spu_mul(v_out_re[13], vscale);
+      v_out_re[14] = spu_mul(v_out_re[14], vscale);
+      v_out_re[15] = spu_mul(v_out_re[15], vscale);
+
+      v_out_im[0] = spu_mul(v_out_im[0], vscale);
+      v_out_im[1] = spu_mul(v_out_im[1], vscale);
+      v_out_im[2] = spu_mul(v_out_im[2], vscale);
+      v_out_im[3] = spu_mul(v_out_im[3], vscale);
+      v_out_im[4] = spu_mul(v_out_im[4], vscale);
+      v_out_im[5] = spu_mul(v_out_im[5], vscale);
+      v_out_im[6] = spu_mul(v_out_im[6], vscale);
+      v_out_im[7] = spu_mul(v_out_im[7], vscale);
+      v_out_im[8] = spu_mul(v_out_im[8], vscale);
+      v_out_im[9] = spu_mul(v_out_im[9], vscale);
+      v_out_im[10] = spu_mul(v_out_im[10], vscale);
+      v_out_im[11] = spu_mul(v_out_im[11], vscale);
+      v_out_im[12] = spu_mul(v_out_im[12], vscale);
+      v_out_im[13] = spu_mul(v_out_im[13], vscale);
+      v_out_im[14] = spu_mul(v_out_im[14], vscale);
+      v_out_im[15] = spu_mul(v_out_im[15], vscale);
+
+      v_out_re += 16;
+      v_out_im += 16;
+    }
+  }
+  STOP_TIMER(&t4);
+
+#if PERFMON
+  if (0 && iter == iter_max-1)
+  {
+    double total1 = timer_total(&t1);
+    double total2 = timer_total(&t2);
+    double total3 = timer_total(&t3);
+    double total4 = timer_total(&t4);
+    double fft_flops = (double)t1.count * 5 * n * log2n;
+    double cvm_flops = (double)t1.count * 6 * n;
+    double sca_flops = (double)t1.count * 2 * n;
+    double fwd_mflops = fft_flops / (total1 * 1e6);
+    double cvm_mflops = cvm_flops / (total2 * 1e6);
+    double inv_mflops = fft_flops / (total3 * 1e6);
+    double sca_mflops = sca_flops / (total4 * 1e6);
+    printf("fwd fft: %f s  %f MFLOP/s\n", total1, fwd_mflops);
+    printf("cvmul  : %f s  %f MFLOP/s\n", total2, cvm_mflops);
+    printf("inv fft: %f s  %f MFLOP/s\n", total3, inv_mflops);
+    printf("scale  : %f s  %f MFLOP/s\n", total4, sca_mflops);
+  }
+#endif
+
+  return 0;
+}
Index: tests/fastconv.cpp
===================================================================
--- tests/fastconv.cpp	(revision 167975)
+++ tests/fastconv.cpp	(working copy)
@@ -41,6 +41,14 @@
   return fft(weights);
 }
 
+// Multiple FFTs to transform weights from time- to frequency-domain.
+template <typename T, typename B>
+Matrix<T, B> t2f(const_Matrix<T, B> weights)
+{
+  Fftm<T, T, row, fft_fwd, by_value> fftm(view_domain(weights), 1.);
+  return fftm(weights);
+}
+  
 // Separate fft, vmul, inv_fft calls.
 struct separate;
 // Separate fftm, vmmul, inv_fftm calls.
@@ -49,8 +57,13 @@
 struct fused;
 // Fused fftm, vmmul, inv_fftm calls.
 struct fused_multi;
-// Explicit Fastconv calls.
-struct direct;
+// Explicit Fastconv calls:
+//   with fused fftm, vmmul, inv_fftm
+template <bool W>   // transform weights early
+struct direct_vmmul;
+//   with fused fftm, mmmul, inv_fftm (matrix of coefficients)
+template <bool W>   // transform weights early
+struct direct_mmmul;
 
 template <typename T, typename B> class Fast_convolution;
 
@@ -187,14 +200,21 @@
 };
 
 #if VSIP_IMPL_CBE_SDK
-template <typename T>
-class Fast_convolution<std::complex<T>, direct>
+// Both of the direct methods perform multiple convolutions.
+// In the second case, the weights are unique for each row as well, so
+// they are passed as a matrix rather than a vector.
+
+template <typename T,
+          bool     W>  // pre-transform weights 
+class Fast_convolution<std::complex<T>, direct_vmmul<W> >
 {
   typedef std::complex<T> value_type;
 public:
   template <typename B>
   Fast_convolution(Vector<value_type, B> weights)
-    : fastconv_(weights, weights.size())
+  // Note the third parameter indicates the opposite of W, i.e. whether
+  // or not the Fastconv object needs to do the transform.
+    : fastconv_((W ? t2f(weights) : weights), weights.size(0), !W)
   {}
 
   template <typename Block1, typename Block2>
@@ -205,8 +225,31 @@
   }
 
 private:
-  impl::cbe::Fastconv<value_type, impl::dense_complex_type> fastconv_;
+  impl::cbe::Fastconv<1, value_type, impl::dense_complex_type> fastconv_;
 };
+
+
+template <typename T,
+          bool     W>  // pre-transform weights 
+class Fast_convolution<std::complex<T>, direct_mmmul<W> >
+{
+  typedef std::complex<T> value_type;
+public:
+  template <typename B>
+  Fast_convolution(Matrix<value_type, B> weights)
+    : fastconv_((W ? t2f(weights) : weights), weights.size(1), !W)
+  {}
+
+  template <typename Block1, typename Block2>
+  void operator()(const_Matrix<value_type, Block1> in,
+                  Matrix<value_type, Block2> out)
+  {
+    fastconv_(in, out);
+  }
+
+private:
+  impl::cbe::Fastconv<2, value_type, impl::dense_complex_type> fastconv_;
+};
 #endif
 
 template <typename O, typename B, typename T>
@@ -236,6 +279,34 @@
 }
 
 
+template <typename O, typename B, typename T>
+void test_shift_m(Domain<1> const &dom, length_type shift, T scale)
+{
+  assert(dom.size() > shift);
+  // Construct a shift kernel.
+  Matrix<T> weights(dom.size(), dom.size(), T(0.));
+  for (index_type i = 0; i < dom.size(); ++i)
+    weights.put(i, shift, scale);
+  Fast_convolution<T, B> fconv(weights);
+  // This logic assumes T is a complex type.
+  // Refine once we support real-valued fastconv.
+  Matrix<T, Dense<2, T, O> > input(dom.size(), dom.size());
+  for (size_t r = 0; r != dom.size(); ++r)
+    input.row(r) = ramp(0., 1., dom.size());
+  Matrix<T, Dense<2, T, O> > output(dom.size(), dom.size());
+  fconv(input, output);
+  double error = error_db
+    (scale * input(Domain<2>(dom.size(), (Domain<1>(0, 1, dom.size() - shift)))),
+     output(Domain<2>(dom.size(), (Domain<1>(shift, 1, dom.size() - shift)))));
+  if (error >= -100)
+  {
+    std::cout << "input" << input << std::endl;
+    std::cout << "output" << output << std::endl;
+  }
+  test_assert(error < -100);
+}
+
+
 int main(int argc, char **argv)
 {
   vsipl init(argc, argv);
@@ -245,6 +316,9 @@
   test_shift<row2_type, fused>(16, 2, std::complex<float>(2.));
   test_shift<row2_type, fused_multi>(64, 2, std::complex<float>(2.));
 #if VSIP_IMPL_CBE_SDK
-  test_shift<row2_type, direct>(64, 2, std::complex<float>(0.5));
+  test_shift<row2_type, direct_vmmul<false> >(64, 2, std::complex<float>(0.5));
+  test_shift<row2_type, direct_vmmul<true> >(64, 2, std::complex<float>(0.5));
+  test_shift_m<row2_type, direct_mmmul<false> >(64, 2, std::complex<float>(0.5));
+  test_shift_m<row2_type, direct_mmmul<true> >(64, 2, std::complex<float>(0.5));
 #endif
 }
Index: benchmarks/cell/fastconv.cpp
===================================================================
--- benchmarks/cell/fastconv.cpp	(revision 167975)
+++ benchmarks/cell/fastconv.cpp	(working copy)
@@ -46,10 +46,11 @@
 struct ImplCbe_ip;	// interleaved fast-convolution on Cell, in-place
 template <typename ComplexFmt>
 struct ImplCbe_op;	// interleaved fast-convolution on Cell, out-of-place
+template <bool transform_replica>
+struct ImplCbe_multi;	// interleaved fast-convolution on Cell, multiple
 
 
 
-
 /***********************************************************************
   ImplCbe: interleaved fast-convolution on Cell
 
@@ -62,6 +63,10 @@
 
   ImplCbe_op: out-of-place, non-distributed, split/interleaved
            controllable.
+
+  ImplCbe_multi: in-place, non-distributed, split/interleaved
+           as configured, multiple coefficient vectors (i.e. a matrix),
+           pre-transforming coeffs to frequency space is controllable.
 ***********************************************************************/
 bool        use_huge_pages_ = true;
 
@@ -97,7 +102,7 @@
     typedef Vector<T, block1_type> view1_type;
     typedef Matrix<T, block2_type> view2_type;
 
-    typedef impl::cbe::Fastconv<T, complex_type>   fconv_type;
+    typedef impl::cbe::Fastconv<1, T, complex_type>   fconv_type;
 
     block1_type* repl_block;
     block2_type* data_block;
@@ -166,7 +171,7 @@
 
   static length_type const num_args = 1;
 
-  typedef impl::cbe::Fastconv<T, ComplexFmt>   fconv_type;
+  typedef impl::cbe::Fastconv<1, T, ComplexFmt>   fconv_type;
 
   void fastconv(length_type npulse, length_type nrange,
 		length_type loop, float& time)
@@ -263,7 +268,7 @@
 
   static length_type const num_args = 2;
 
-  typedef impl::cbe::Fastconv<T, ComplexFmt>   fconv_type;
+  typedef impl::cbe::Fastconv<1, T, ComplexFmt>   fconv_type;
 
   void fastconv(length_type npulse, length_type nrange,
 		length_type loop, float& time)
@@ -274,16 +279,16 @@
     Matrix<T, block2_type> in (npulse, nrange, T());
     Matrix<T, block2_type> out(npulse, nrange, T());
     in = gen.randu(npulse, nrange);
-    
+
     // Create the pulse replica
     Vector<T, block1_type> replica(nrange, T());
     replica.put(0, T(1));
 
+
     // Create Fast Convolution object
     fconv_type fconv(replica, nrange);
 
     vsip::impl::profile::Timer t1;
-
     t1.start();
     for (index_type l=0; l<loop; ++l)
       fconv(in, out);
@@ -291,6 +296,7 @@
 
     time = t1.delta();
 
+
     // Check result.
 #if 0
     // Ideally we would do a full check, using FFT and vmul.
@@ -323,6 +329,76 @@
 
 
 
+
+
+template <typename T,
+          bool     transform_replica>
+struct t_fastconv_base<T, ImplCbe_multi<transform_replica> > : fastconv_ops
+{
+  static length_type const num_args = 1;
+
+  typedef impl::dense_complex_type complex_type;
+  typedef impl::cbe::Fastconv<2, T, complex_type>   fconvm_type;
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+    typedef typename Alloc_block<2, T, complex_type, Local_map>::block_type  block_type;
+    block_type* data_block;
+    block_type* repl_block;
+
+    Local_map map;
+    repl_block = alloc_block<2, T, complex_type>(Domain<2>(npulse, nrange),
+		                                 mem_addr_, 0x0000000,
+						 map);
+    data_block = alloc_block<2, T, complex_type>(Domain<2>(npulse, nrange),
+						 mem_addr_, nrange*sizeof(T),
+						 map);
+    {
+      typedef Matrix<T, block_type> view_type;
+      // Create the data cube.
+      view_type data(*data_block);
+      // Create the pulse replicas
+      view_type replica(*repl_block);
+      // Note: we treat the replica as if it were in the frequency
+      // domain already.  Actually performing an FFT would push
+      // the compute kernel out of SPE memory.
+
+
+      // Create Fast Convolution object
+      fconvm_type fconvm(replica, nrange, transform_replica);
+
+      vsip::impl::profile::Timer t1;
+      t1.start();
+      for (index_type l=0; l<loop; ++l)
+        fconvm(data, data);
+      t1.stop();
+
+      time = t1.delta();
+    }
+
+    delete repl_block;
+    delete data_block;
+  }
+
+  t_fastconv_base()
+    : mem_addr_ (0)
+    , pages_    (9)
+  {
+    char const* mem_file = "/huge/fastconv.bin";
+
+    if (use_huge_pages_)
+      mem_addr_ = open_huge_pages(mem_file, pages_);
+    else
+      mem_addr_ = 0;
+  }
+
+// Member data.
+  char*        mem_addr_;
+  unsigned int pages_;
+};
+
+
 /***********************************************************************
   Benchmark Driver
 ***********************************************************************/
@@ -360,6 +436,9 @@
   case 22: loop(t_fastconv_rf<T, ImplCbe_ip<Csf, true> >(param1));break;
   case 23: loop(t_fastconv_rf<T, ImplCbe_ip<Csf, false> >(param1));break;
 
+  case 32: loop(t_fastconv_rf<T, ImplCbe_multi<true> >(param1));break;
+  case 42: loop(t_fastconv_rf<T, ImplCbe_multi<false> >(param1));break;
+
   case 0:
     std::cout
       << "fastconv -- fast convolution benchmark for Cell BE\n"
@@ -373,6 +452,9 @@
       << "   -21 -- OP, split complex,  non-dist\n"
       << "   -22 -- IP, split complex,  non-dist\n"
       << "   -23 -- IP, split complex,  non-dist, multi FC\n"
+      << "\n"
+      << "   -32 -- Multiple coeff vectors in time domain, IP, native complex, non-dist, single FC\n"
+      << "   -42 -- Multiple coeff vectors in freq domain, IP, native complex, non-dist, single FC\n"
       ;
 
   default: return 0;
Index: benchmarks/alloc_block.hpp
===================================================================
--- benchmarks/alloc_block.hpp	(revision 167975)
+++ benchmarks/alloc_block.hpp	(working copy)
@@ -103,21 +103,20 @@
 
 
 
-template <vsip::dimension_type Dim,
-	  typename             T>
-struct Alloc_block<Dim, T, vsip::impl::Cmplx_inter_fmt, vsip::Local_map>
+template <typename T>
+struct Alloc_block<1, T, vsip::impl::Cmplx_inter_fmt, vsip::Local_map>
 {
-  typedef typename vsip::impl::Row_major<Dim>::type order_type;
-  typedef vsip::impl::Dense_impl<Dim, T, order_type, 
+  typedef typename vsip::impl::Row_major<1>::type order_type;
+  typedef vsip::impl::Dense_impl<1, T, order_type, 
 				 vsip::impl::Cmplx_inter_fmt, vsip::Local_map>
           block_type;
 
   static block_type*
   alloc(
-    vsip::Domain<Dim> const& dom,
-    char*                    addr,
-    unsigned long            offset,
-    vsip::Local_map const&   map)
+    vsip::Domain<1> const& dom,
+    char*                  addr,
+    unsigned long          offset,
+    vsip::Local_map const& map)
   {
     block_type* blk;
     if (addr == NULL)
@@ -137,19 +136,18 @@
 
 
 
-template <vsip::dimension_type Dim,
-	  typename             T>
-struct Alloc_block<Dim, std::complex<T>, vsip::impl::Cmplx_split_fmt,
+template <typename T>
+struct Alloc_block<1, std::complex<T>, vsip::impl::Cmplx_split_fmt,
 		   vsip::Local_map>
 {
-  typedef typename vsip::impl::Row_major<Dim>::type order_type;
-  typedef vsip::impl::Dense_impl<Dim, std::complex<T>, order_type,
+  typedef typename vsip::impl::Row_major<1>::type order_type;
+  typedef vsip::impl::Dense_impl<1, std::complex<T>, order_type,
 				 vsip::impl::Cmplx_split_fmt, vsip::Local_map>
           block_type;
 
   static block_type*
   alloc(
-    vsip::Domain<Dim> const& dom,
+    vsip::Domain<1> const& dom,
     char*                    addr,
     unsigned long            offset,
     vsip::Local_map const&   map)
Index: examples/fconv.cpp
===================================================================
--- examples/fconv.cpp	(revision 167975)
+++ examples/fconv.cpp	(working copy)
@@ -75,7 +75,7 @@
 
 #ifdef VSIP_IMPL_CBE_SDK
   // Create Fast Convolution object
-  typedef impl::cbe::Fastconv<T, impl::dense_complex_type> fconv_type;
+  typedef impl::cbe::Fastconv<1, T, impl::dense_complex_type> fconv_type;
   fconv_type fconv(coeffs, N);
 
 
