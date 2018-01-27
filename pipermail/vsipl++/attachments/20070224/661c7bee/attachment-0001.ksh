Index: src/vsip/opt/cbe/ppu/task_manager.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/task_manager.hpp	(revision 164121)
+++ src/vsip/opt/cbe/ppu/task_manager.hpp	(working copy)
@@ -39,6 +39,7 @@
 
 struct Mult_tag;
 struct Fft_tag;
+struct Fastconv_tag;
 
 
 namespace cbe
@@ -49,8 +50,6 @@
 class Task_manager
 {
 public:
-//   static size_t const MAX_NUM_SPES = 8;
-
   static Task_manager *instance() { return instance_;}
 
   static void initialize(int& argc, char**&argv)
@@ -135,5 +134,6 @@
 DEFINE_TASK(0, Mult_tag, float(float, float), vmul_s)
 DEFINE_TASK(1, Mult_tag, std::complex<float>(std::complex<float>, std::complex<float>), vmul_c)
 DEFINE_TASK(2, Fft_tag, void(std::complex<float>, std::complex<float>), fft_c)
+DEFINE_TASK(3, Fastconv_tag, void(std::complex<float>, std::complex<float>), fconv_c)
 
 #endif
Index: src/vsip/opt/cbe/ppu/fastconv.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.cpp	(revision 0)
+++ src/vsip/opt/cbe/ppu/fastconv.cpp	(revision 0)
@@ -0,0 +1,100 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/ppu/fastconv.cpp
+    @author  Don McCoy
+    @date    2007-02-23
+    @brief   VSIPL++ Library: Wrapper for fast convolution on the SPEs.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/config.hpp>
+#include <vsip/core/fns_scalar.hpp>
+#include <vsip/math.hpp>
+#include <vsip/opt/cbe/common.h>
+#include <vsip/opt/cbe/ppu/fastconv.hpp>
+#include <vsip/opt/cbe/ppu/task_manager.hpp>
+extern "C"
+{
+#include <libspe2.h>
+}
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace cbe
+{
+
+
+template <typename T>
+void
+Fastconv_base<T>::fconv(
+  T* in, T* kernel, T* out, length_type rows, length_type length)
+{
+  Fastconv_params params;
+  params.elements = length;
+  params.ea_kernel = reinterpret_cast<unsigned long long>(kernel);
+  params.ea_twiddle_factors = reinterpret_cast<unsigned long long>
+    (this->twiddle_factors_.get());
+
+  length_type psize = sizeof(params);
+  // The stack size is determined by multiplying the maximum convolution
+  // size by 4:  2 to support double-buffering and 2 to account for 
+  // separate input and output buffers.
+  length_type stack_size = 4096 + 4*sizeof(T)*MAX_FCONV_SIZE;
+  Task_manager *mgr = Task_manager::instance();
+  Task task = mgr->reserve<Fastconv_tag, void(T,T)>
+    (stack_size, psize, sizeof(T)*length, sizeof(T)*length);
+  for (index_type i = 0; i < rows; ++i)
+  {
+    Workblock block = task.create_block();
+    block.set_parameters(params);
+    block.add_input(in, length);
+    block.add_output(out, length);
+    task.enqueue(block);
+    in += length;
+    out += length;
+  }
+  task.sync();
+}
+
+
+template <typename T>
+void
+Fastconv_base<T>::compute_twiddle_factors(length_type length)
+{
+  typedef typename Scalar_of<T>::type stype;
+
+  unsigned int i = 0;
+  unsigned int n = length;
+  stype* W = reinterpret_cast<stype*>(this->twiddle_factors_.get());
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
+typedef std::complex<float> ctype;
+
+template void Fastconv_base<ctype>::fconv(ctype* in, ctype* kernel, 
+  ctype* out, length_type rows, length_type length);
+template void Fastconv_base<ctype>::compute_twiddle_factors(length_type length);
+
+
+} // namespace vsip::impl::cbe
+} // namespace vsip::impl
+} // namespace vsip
Index: src/vsip/opt/cbe/ppu/fastconv.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.hpp	(revision 0)
+++ src/vsip/opt/cbe/ppu/fastconv.hpp	(revision 0)
@@ -0,0 +1,144 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/ppu/fastconv.hpp
+    @author  Don McCoy
+    @date    2007-02-23
+    @brief   VSIPL++ Library: Wrapper for fast convolution on the SPEs.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/allocation.hpp>
+#include <vsip/core/config.hpp>
+#include <vsip/core/extdata.hpp>
+#include <vsip/math.hpp>
+#include <vsip/opt/cbe/ppu/bindings.hpp>
+#include <vsip/opt/cbe/ppu/task_manager.hpp>
+extern "C"
+{
+#include <libspe2.h>
+}
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace cbe
+{
+
+template <typename T>
+class Fastconv_base
+{
+public:
+  template <typename Block>
+  Fastconv_base(Vector<T, Block> coeffs, length_type input_size)
+    : kernel_(input_size, T()),
+      twiddle_factors_(input_size / 4)
+  {
+    assert(coeffs.size() <= input_size);
+    kernel_(view_domain(coeffs)) = coeffs;
+    compute_twiddle_factors(input_size);
+  }
+
+protected:
+  template <typename Block0, typename Block1>
+  void convolve(const_Vector<T, Block0> in, Vector<T, Block1> out)
+  {
+    Ext_data<Block0>       ext_in(const_cast<Block0&>(in.block()), SYNC_IN);
+    Ext_data<Dense<1, T> > ext_kernel(this->kernel_.block(), SYNC_IN);
+    Ext_data<Block1>       ext_out(out.block(), SYNC_OUT);
+    assert(ext_in.stride() == 1);
+    assert(ext_out.stride() == 1);
+
+    length_type rows = 1;
+    fconv(ext_in.data(), ext_kernel.data(), ext_out.data(), rows, out.size());
+  }
+
+  template <typename Block0, typename Block1>
+  void convolve(const_Matrix<T, Block0> in, Matrix<T, Block1> out)
+  {
+    Ext_data<Block0>       ext_in(const_cast<Block0&>(in.block()), SYNC_IN);
+    Ext_data<Dense<1, T> > ext_kernel(this->kernel_.block(), SYNC_IN);
+    Ext_data<Block1>       ext_out(out.block(), SYNC_OUT);
+    assert(ext_in.stride(1) == 1);
+    assert(ext_out.stride(1) == 1);
+
+    length_type rows = in.size(0);
+    fconv(ext_in.data(), ext_kernel.data(), ext_out.data(), rows, out.size(1));
+  }
+
+
+private:
+  void compute_twiddle_factors(length_type length);
+  void fconv(T* in, T* kernel, T* out, length_type rows, length_type length);
+
+  Vector<T> kernel_;
+  length_type size_;
+  aligned_array<T> twiddle_factors_;
+};
+
+
+
+
+template <typename T>
+class Fastconv : public Fastconv_base<T>
+{
+  // Constructors, copies, assignments, and destructors.
+public:
+  template <typename Block>
+  Fastconv(Vector<T, Block>   filter_coeffs,
+           length_type        input_size)
+    VSIP_THROW((std::bad_alloc))
+    : Fastconv_base<T>(filter_coeffs, input_size)
+  {}
+
+  ~Fastconv() VSIP_NOTHROW {}
+
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
+    assert(in.size() == this->size_);
+    assert(out.size() == this->size_);
+    
+    this->convolve(in, out);
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
+    assert(in.size(1) == this->size_);
+    assert(out.size(1) == this->size_);
+    
+    this->convolve(in, out);
+    
+    return out;
+  }
+};
+
+
+} // namespace vsip::impl::cbe
+} // namespace vsip::impl
+} // namespace vsip
Index: src/vsip/opt/cbe/spu/alf_fconv_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconv_c.c	(revision 0)
+++ src/vsip/opt/cbe/spu/alf_fconv_c.c	(revision 0)
@@ -0,0 +1,195 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/spu/alf_fconv_c.c
+    @author  Don McCoy
+    @date    2007-02-23
+    @brief   VSIPL++ Library: Kernel to compute fast convolution.
+*/
+
+#include <sys/time.h>
+#include <spu_mfcio.h>
+#include <alf_accel.h>
+#include <assert.h>
+#include <libfft.h>
+#include <vsip/opt/cbe/common.h>
+
+// These are sized for complex values, taking two floats each.  The twiddle 
+// factors occupy only 1/4 the space as the inputs, outputs and convolution 
+// kernels.
+static volatile float kernel[MAX_FCONV_SIZE*2] __attribute__ ((aligned (128)));
+static volatile float twiddle_factors[MAX_FCONV_SIZE*2/4] __attribute__ ((aligned (128)));
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
+int cvmul(float const* a,
+	  float const* b,
+	  float* c,       // c = a * b
+	  int length)
+{
+  // Taken from IBM Cell Arch Workshop, Day Two, Example 3
+
+  const vector float v_zero = {0, 0, 0, 0};
+  const vector unsigned char I_Perm_Vector = {0,1,2,3,8,9,10,11,16,17,18,19,24,25,26,27};
+  const vector unsigned char Q_Perm_Vector = {4,5,6,7,12,13,14,15,20,21,22,23,28,29,30,31};
+  const vector unsigned char vcvmrgh = {0,1,2,3,16,17,18,19,4,5,6,7,20,21,22,23};
+  const vector unsigned char vcvmrgl = {8,9,10,11,24,25,26,27,12,13,14,15,28,29,30,31};
+
+  int i = 0;
+  while (length / 4)
+  {
+    length -= 4;   // The loop handles four values on each pass
+
+    vector float A1 = *( (vector float *) ( a +(4*2*i)));     // a0-3, a8-11, a16-19, a24-a27, ...
+    vector float A2 = *( (vector float *) ( a +(4*2*i+4)));   // a4-7, a12-15, a20-23, a28-a31,   ...
+    const vector float B1 = *( (vector float *) ( b +(4*2*i))); 
+    const vector float B2 = *( (vector float *) ( b +(4*2*i+4)));
+    vector float * const D1 = ( (vector float *) ( c +(4*2*i)));
+    vector float * const D2 = ( (vector float *) ( c +(4*2*i+4)));
+
+    vector float I1, I2, Q1, Q2;  /* in-phase (real), quadrature (imag), temp, and output vectors*/
+
+    /* input vectors are in interleaved form in A1,A2 and B1,B2 with each input vector representing 2 complex numbers
+       and thus this loop would repeat for N/4 iterations
+    */
+    I1 = spu_shuffle(A1, A2, I_Perm_Vector); /* pulls out 1st and 3rd 4-byte element from vectors A1 and A2 */
+    I2 = spu_shuffle(B1, B2, I_Perm_Vector); /* pulls out 1st and 3rd 4-byte element from vectors B1 and B2 */
+    Q1 = spu_shuffle(A1, A2, Q_Perm_Vector); /* pulls out 2nd and 4th 4-byte element from vectors A1 and A2 */
+    Q2 = spu_shuffle(B1, B2, Q_Perm_Vector); /* pulls out 3rd and 4th 4-byte element from vectors B1 and B2 */
+    A1 = spu_nmsub(Q1, Q2, v_zero);          /* calculates -(bd - 0) for all four elements */
+    A2 = spu_madd(Q1, I2, v_zero);           /* calculates (bc + 0) for all four elements */
+    Q1 = spu_madd(I1, Q2, A2);               /* calculates ad + bc for all four elements */
+    I1 = spu_madd(I1, I2, A1);               /* calculates ac - bd for all four elements */ 
+    *D1 = spu_shuffle(I1, Q1, vcvmrgh);       /* spreads the results back into interleaved format */
+    *D2 = spu_shuffle(I1, Q1, vcvmrgl);       /* spreads the results back into interleaved format */
+    ++i;
+  }
+
+  a += i*4*2;
+  b += i*4*2;
+  c += i*4*2;
+  while (length--)
+  {
+    float ar = *a++; float ai = *a++;
+    float br = *b++; float bi = *b++;
+    *c++ = ar*br - ai*bi;
+    *c++ = ar*bi + ai*br;
+  }
+
+  return 0;
+}
+
+
+int 
+fft_inv(vector float* in,
+	vector float* W,
+	vector float* out,
+	unsigned int n,
+	unsigned int log2n)
+{
+  unsigned int const vec_size = 4; 
+
+  // Perform the FFT, 
+  //   -- 'in' may be the same as 'out'
+  fft_1d_r2(out, in, W, log2n);
+
+  // Code for the inverse FFT taken from the CBE SDK Libraries
+  // Overview and Users Guide, sec. 8.1.
+  unsigned int i;
+  vector float *start, *end, s0, s1, e0, e1;
+  vector unsigned int mask = (vector unsigned int){-1, -1, 0, 0};
+  vector float vscale = spu_splats(1 / (float)n);
+  start = out;
+
+  // Scale the output vector and swap the order of the outputs.
+  // Note: there are two float values for each of 'n' complex values.
+  end = start + 2 * n / vec_size;
+  s0 = e1 = *start;
+  for (i = 0; i < n / vec_size; ++i) 
+  {
+    s1 = *(start + 1);
+    e0 = *(--end);
+
+    *start++ = spu_mul(spu_sel(e0, e1, mask), vscale);
+    *end = spu_mul(spu_sel(s0, s1, mask), vscale);
+    s0 = s1;
+    e1 = e0;
+  }
+
+  return 0;
+}
+
+
+
+
+static int fconv_initialized = 0;
+
+void initialize(Fastconv_params* fc, void volatile* p_kernel, 
+		void volatile* p_twiddles, unsigned int log2n)
+{
+  fconv_initialized = 1;
+  unsigned int size = fc->elements*2*sizeof(float);
+
+  // The number of twiddle factors is 1/4 the input size
+  mfc_get(p_twiddles, fc->ea_twiddle_factors, size/4, 31, 0, 0);
+  mfc_write_tag_mask(1<<31);
+  mfc_read_tag_status_all();
+
+  // The kernel matches the input and output size
+  mfc_get(p_kernel, fc->ea_kernel, size, 31, 0, 0);
+  mfc_write_tag_mask(1<<31);
+  mfc_read_tag_status_all();
+
+  // Perform the forward FFT on the kernel, in place.  This only need 
+  // be done once -- subsequent calls will utilize the same kernel.
+  vector float* inout = (vector float *)kernel;
+  vector float* W = (vector float*)twiddle_factors;
+  fft_1d_r2(inout, inout, W, log2n);
+}
+
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
+  Fastconv_params* fc = (Fastconv_params *)params;
+  unsigned int n = fc->elements;
+  unsigned int log2n = log2i(n);
+  assert(n <= MAX_FCONV_SIZE);
+
+  if (!fconv_initialized)
+    initialize(fc, kernel, twiddle_factors, log2n);
+
+  vector float* in = (vector float *)input;
+  vector float* W = (vector float*)twiddle_factors;
+  vector float* out = (vector float*)output;
+
+  // Switch to frequency space
+  fft_1d_r2(in, in, W, log2n);
+
+  // Perform convolution -- now a straight multiplication
+  cvmul((float*)in, (float*)kernel, (float*)out, n);
+
+  // Revert back the time domain
+  fft_inv(out, W, out, n, log2n);
+
+  return 0;
+}
Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 164121)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -65,6 +65,8 @@
 
 src/vsip/opt/cbe/spu/alf_fft_c.spe: override SPU_LIBS += -lfft
 
+src/vsip/opt/cbe/spu/alf_fconv_c.spe: override SPU_LIBS += -lfft
+
 lib/%.spe: src/vsip/opt/cbe/spu/%.spe
 	cp $< $@
 
Index: src/vsip/opt/cbe/common.h
===================================================================
--- src/vsip/opt/cbe/common.h	(revision 164121)
+++ src/vsip/opt/cbe/common.h	(working copy)
@@ -30,7 +30,13 @@
 #define MAX_FFT_1D_SIZE	  4096
 #endif
 
+// Fast convolution shares the same minimum as FFT, but the maximum
+// is less.
+#ifndef MAX_FCONV_SIZE
+#define MAX_FCONV_SIZE	  2048
+#endif
 
+
 typedef enum
 {
   fwd_fft = 0,
@@ -47,4 +53,14 @@
   double scale;
 } Fft_params;
 
+
+typedef struct
+{
+  unsigned int _pad;
+  unsigned int elements;
+  unsigned long long ea_kernel;
+  unsigned long long ea_twiddle_factors;
+} Fastconv_params;
+
+
 #endif // VSIP_OPT_CBE_COMMON_H
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 164121)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -44,6 +44,7 @@
 ifdef enable_cbe_sdk
 src_vsip_cxx_sources += $(srcdir)/src/vsip/opt/cbe/ppu/task_manager.cpp \
                         $(srcdir)/src/vsip/opt/cbe/ppu/fft.cpp \
+                        $(srcdir)/src/vsip/opt/cbe/ppu/fastconv.cpp \
                         $(srcdir)/src/vsip/opt/cbe/ppu/bindings.cpp
 endif
 src_vsip_cxx_sources += $(srcdir)/src/vsip/opt/simd/vmul.cpp \
Index: examples/fconv.cpp
===================================================================
--- examples/fconv.cpp	(revision 0)
+++ examples/fconv.cpp	(revision 0)
@@ -0,0 +1,99 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved. */
+
+/** @file    examples/fconv.cpp
+    @author  Don McCoy
+    @date    2007-02-23
+    @brief   VSIPL++ Library: Simple fast convolution example
+                using the Cell Broadband Engine.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/math.hpp>
+#include <vsip/core/profile.hpp>
+#include <vsip/opt/cbe/ppu/fastconv.hpp>
+
+#include <vsip_csl/error_db.hpp>
+#include <vsip_csl/ref_dft.hpp>
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+using namespace vsip;
+using namespace vsip_csl;
+using namespace impl::profile;
+
+
+/***********************************************************************
+  Functions
+***********************************************************************/
+
+void
+fconv_example()
+{
+  typedef std::complex<float> T;
+  typedef impl::cbe::Fastconv<T> fconv_type;
+  typedef Fft<const_Vector, T, T, fft_fwd, by_reference> for_fft_type;
+  typedef Fft<const_Vector, T, T, fft_inv, by_reference> inv_fft_type;
+
+  const length_type M = 32;
+  const length_type N = 64;
+  Matrix<T> in(M, N, T(1));
+  Matrix<T> out(M, N, T());
+  Vector<T> kernel(N, T());  Vector<T> coeffs(4, T());
+  Vector<T> replica(N, T());
+  Vector<T> ref(N, T());
+  Vector<T> tmp(N, T());
+
+  // Create the FFT objects.
+  for_fft_type for_fft(Domain<1>(N), 1.0);
+  inv_fft_type inv_fft(Domain<1>(N), 1.0/(N));
+
+  // Initialize
+  //   Note: the size of coeffs is less than kernel, which
+  //   is zero-padded to the length of the input/output vectors.
+  kernel(0) = T(1);  coeffs(0) = T(1);
+  kernel(1) = T(1);  coeffs(1) = T(1);
+  kernel(2) = T(1);  coeffs(2) = T(1);
+  kernel(3) = T(1);  coeffs(3) = T(1);
+
+  // Compute reference
+  for_fft(kernel, replica);
+
+  for_fft(in.row(0), tmp);
+  tmp *= replica;
+  inv_fft(tmp, ref);
+
+  // Create Fast Convolution object
+  fconv_type fconv(coeffs, N);
+
+
+  // Compute convolution on a vector
+  fconv(in.row(0), out.row(0));
+  test_assert(error_db(ref, out.row(0)) < -100);
+
+
+  // And now run the convolution over the rows of a matrix
+  fconv(in, out);
+  for (index_type i = 0; i < M; ++i)
+    test_assert(error_db(ref, out.row(i)) < -100);
+}
+
+
+int
+main(int argc, char **argv)
+{
+  vsipl init(argc, argv);
+  
+  fconv_example();
+
+  return 0;
+}
