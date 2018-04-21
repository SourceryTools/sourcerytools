Index: ChangeLog
===================================================================
--- ChangeLog	(revision 188744)
+++ ChangeLog	(working copy)
@@ -1,5 +1,34 @@
 2007-12-05  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/core/view_cast.hpp: Fix typo in expr block type.
+	* src/vsip/opt/cbe/pwarp_params.h: New file, pwarp ALF kernel
+	  parameter block.
+	* src/vsip/opt/cbe/ppu/pwarp.hpp: New file, pwarp ALF kernel bridge.
+	* src/vsip/opt/cbe/ppu/pwarp.cpp: New file, pwarp ALF kernel bridge.
+	* src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp: New file, pwarp ALF kernel.
+	* src/vsip/opt/cbe/ppu/task_manager.hpp: Add tag for uchar pwarp
+	  ALF task.
+	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Add rules for C++ ALF
+	  kernels.
+	* src/vsip/opt/simd/simd.hpp: Add AltiVec unsigned short and
+	  unsigned int support.  Split common traits into ...
+	* src/vsip/opt/simd/simd_common.hpp: ... here, new file.
+	* src/vsip/opt/simd/simd_spu.hpp: New file, SPU SIMD traits.
+	* src/vsip/GNUmakefile.inc.in (src_vsip_cxx_sources): Add pwarp.cpp
+	* src/vsip_csl/error_db.hpp: Cast difference to double, allows
+	  error_db to be used for unsigned types.
+	* src/vsip_csl/img/impl/pwarp_common.hpp: New file, common bits
+	  for perspective warp.
+	* src/vsip_csl/img/impl/pwarp_cbe.hpp: New file, CBE pwarp BE.
+	* src/vsip_csl/img/impl/pwarp_gen.hpp: New file, generic pwarp BE.
+	* src/vsip_csl/img/impl/pwarp_simd.hpp: New file, SIMD pwarp BE.
+	* src/vsip_csl/img/perspective_warp.hpp: New file, API and functional
+	  pwarp impl.
+	* tests/vsip_csl/pwarp.cpp: New file, unit test for pwarp.
+	* benchmarks/pwarp.cpp: New file, benchmark for pwarp.
+
+2007-12-05  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/core/signal/types.hpp (support_min_zeropad): New
 	  support_region_type.
 	* src/vsip_csl/img/impl/sfilt_common.hpp: New file, common
Index: src/vsip/core/lvalue_proxy.hpp
===================================================================
--- src/vsip/core/lvalue_proxy.hpp	(revision 188740)
+++ src/vsip/core/lvalue_proxy.hpp	(working copy)
@@ -265,6 +265,26 @@
     { return block_.impl_ref(i, j, k); }
 };
 
+
+
+// Trait to determine if type is an lvalue_proxy.
+
+template <typename T>
+struct Is_lvalue_proxy_type
+{
+  static bool const value = false;
+  typedef T value_type;
+};
+
+template <typename       T,
+	  typename       BlockT,
+	  dimension_type Dim>
+struct Is_lvalue_proxy_type<Lvalue_proxy<T, BlockT, Dim> >
+{
+  static bool const value = true;
+  typedef T value_type;
+};
+
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/core/view_cast.hpp
===================================================================
--- src/vsip/core/view_cast.hpp	(revision 188740)
+++ src/vsip/core/view_cast.hpp	(working copy)
@@ -59,7 +59,7 @@
 {
   typedef const Unary_expr_block<ViewT<T1, Block1>::dim,
 				 Cast_closure<T>::template Cast,
-				 Block1, T1> block_type;
+				 Block1, T> block_type;
 
   typedef typename ViewConversion<ViewT, T, block_type>::const_view_type
     view_type;
Index: src/vsip/core/fns_elementwise.hpp
===================================================================
--- src/vsip/core/fns_elementwise.hpp	(revision 188740)
+++ src/vsip/core/fns_elementwise.hpp	(working copy)
@@ -19,6 +19,7 @@
 #include <vsip/core/promote.hpp>
 #include <vsip/core/fns_scalar.hpp>
 #include <vsip/core/metaprogramming.hpp>
+#include <vsip/core/lvalue_proxy.hpp>
 
 namespace vsip
 {
@@ -52,7 +53,9 @@
 struct Dispatch_##fname :                                                 \
   ITE_Type<Is_view_type<T>::value,                                        \
            As_type<Unary_func_view<fname##_functor, T> >,                 \
-           As_type<fname##_functor<T> > >::type                           \
+  ITE_Type<Is_lvalue_proxy_type<T>::value,			          \
+           As_type<fname##_functor<typename Is_lvalue_proxy_type<T>::value_type> >,	\
+           As_type<fname##_functor<T> > > >::type                         \
 {                                                                         \
 };
 
Index: src/vsip/core/fns_scalar.hpp
===================================================================
--- src/vsip/core/fns_scalar.hpp	(revision 188740)
+++ src/vsip/core/fns_scalar.hpp	(working copy)
@@ -224,12 +224,29 @@
 inline typename impl::Scalar_of<T>::type 
 mag(T t) VSIP_NOTHROW { return abs_detail::abs(t);}
 
+namespace magsq_detail
+{
+
 template <typename T>
+struct Magsq_impl
+{
+  static T exec(T val) { return val*val; }
+};
+
+template <typename T>
+struct Magsq_impl<std::complex<T> >
+{
+  static T exec(std::complex<T> const& val)
+  { return sq(val.real()) + sq(val.imag()); }
+};
+
+} // namespace magsq_detail
+
+template <typename T>
 inline typename impl::Scalar_of<T>::type 
 magsq(T t) VSIP_NOTHROW 
 {
-  typename impl::Scalar_of<T>::type tmp(abs_detail::abs(t)); 
-  return tmp*tmp;
+  return magsq_detail::Magsq_impl<T>::exec(t);
 }
 
 template <typename T>
Index: src/vsip/opt/cbe/pwarp_params.h
===================================================================
--- src/vsip/opt/cbe/pwarp_params.h	(revision 0)
+++ src/vsip/opt/cbe/pwarp_params.h	(revision 0)
@@ -0,0 +1,43 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/pwarp_params.h
+    @author  Jules Bergmann
+    @date    2007-11-19
+    @brief   VSIPL++ Library: Parameters for PWarp kernels.
+*/
+
+#ifndef VSIP_OPT_CBE_PWARP_PARAMS_H
+#define VSIP_OPT_CBE_PWARP_PARAMS_H
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Structures used in DMAs should be sized in multiples of 128-bits
+
+typedef struct
+{
+  float P[9];			// perspective warp matrix
+  int   pad[3];
+
+  unsigned long long ea_in;	// input block EA
+  unsigned long long ea_out;	// output block EA
+
+  unsigned int in_row_0;	// input origin row
+  unsigned int in_col_0;	// input origin column
+  unsigned int in_rows;		// input number of rows
+  unsigned int in_cols;		// input number of cols
+  unsigned int in_stride_0;	// input stride to next row
+
+  unsigned int out_row_0;	// output origin row
+  unsigned int out_col_0;	// output origin column
+  unsigned int out_rows;	// output number of rows
+  unsigned int out_cols;	// output number of cols
+  unsigned int out_stride_0;	// output stride to next row
+} Pwarp_params;
+
+#endif // VSIP_OPT_CBE_FFT_PARAMS_H
Index: src/vsip/opt/cbe/ppu/pwarp.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/pwarp.hpp	(revision 0)
+++ src/vsip/opt/cbe/ppu/pwarp.hpp	(revision 0)
@@ -0,0 +1,99 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/ppu/pwarp.hpp
+    @author  Jules Bergmann
+    @date    2007-11-19
+    @brief   VSIPL++ Library: Perspective warp bridge with the CBE ALF.
+*/
+
+#ifndef VSIP_OPT_CBE_PPU_PWARP_HPP
+#define VSIP_OPT_CBE_PPU_PWARP_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/opt/cbe/pwarp_params.h>
+#include <vsip/opt/cbe/ppu/task_manager.hpp>
+#include <vsip/matrix.hpp>
+
+
+
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
+// Maximum number of columns that CBE pwarp can handle.
+
+length_type const pwarp_block_max_col_size = 4096;
+
+// Foward decl: ALF bridge function for perspective warp.
+
+template <typename T>
+void
+pwarp_block_impl(
+  Matrix<float> P,
+  T const*      p_in,
+  stride_type   in_stride_0,
+  T*            p_out,
+  stride_type   out_stride_0,
+  length_type   in_rows,
+  length_type   in_cols,
+  length_type   out_rows,
+  length_type   out_cols);
+
+
+
+template <typename CoeffT,
+	  typename T,
+	  typename Block1,
+	  typename Block2,
+	  typename Block3>
+void
+pwarp_block(
+  const_Matrix<CoeffT, Block1> P,
+  const_Matrix<T, Block2>      in,
+  Matrix<T, Block3>            out)
+{
+  using vsip::length_type;
+  using vsip::impl::Ext_data;
+
+  length_type out_rows = out.size(0);
+  length_type out_cols = out.size(1);
+  length_type in_rows  = in.size(0);
+  length_type in_cols  = in.size(1);
+
+  Ext_data<Block2> ext_in(in.block());
+  Ext_data<Block3> ext_out(out.block());
+
+  pwarp_block_impl(
+    P,
+    ext_in.data(),  ext_in.stride(0),
+    ext_out.data(), ext_out.stride(0),
+    in_rows, in_cols,
+    out_rows, out_cols);
+}
+
+
+} // namespace vsip::impl::fftm
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_CBE_PPU_PWARP_HPP
Index: src/vsip/opt/cbe/ppu/task_manager.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/task_manager.hpp	(revision 188740)
+++ src/vsip/opt/cbe/ppu/task_manager.hpp	(working copy)
@@ -43,6 +43,7 @@
 struct Fastconv_tag;
 struct Fastconvm_tag;
 struct Vmmul_tag;
+struct Pwarp_tag;
 
 
 namespace cbe
@@ -150,5 +151,6 @@
 DEFINE_TASK(6, Fastconvm_tag, void(std::complex<float>, std::complex<float>), fconvm_c)
 DEFINE_TASK(7, Fastconvm_tag, void(split_float_type, split_float_type), fconvm_split_c)
 DEFINE_TASK(8, Vmmul_tag, std::complex<float>(std::complex<float>, std::complex<float>), vmmul_c)
+DEFINE_TASK(9, Pwarp_tag, void(unsigned char, unsigned char), pwarp_ub)
 
 #endif
Index: src/vsip/opt/cbe/ppu/pwarp.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/pwarp.cpp	(revision 0)
+++ src/vsip/opt/cbe/ppu/pwarp.cpp	(revision 0)
@@ -0,0 +1,236 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/ppu/pwarp.cpp
+    @author  Jules Bergmann
+    @date    2007-11-19
+    @brief   VSIPL++ Library: Perspective warp bridge with the CBE ALF.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/support.hpp>
+#include <vsip/core/allocation.hpp>
+#include <vsip/opt/cbe/pwarp_params.h>
+#include <vsip/opt/cbe/ppu/pwarp.hpp>
+#include <vsip/opt/cbe/ppu/task_manager.hpp>
+#include <vsip/opt/cbe/ppu/util.hpp>
+#include <vsip/matrix.hpp>
+
+
+
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
+// Transform coordinates (u, v) into (x, y) with projection matrix P.
+
+template <typename T,
+	  typename CoeffT,
+	  typename Block1>
+void
+apply_proj(
+  vsip::const_Matrix<CoeffT, Block1> P,
+  T                                  u,
+  T                                  v,
+  T&                                 x,
+  T&                                 y)
+{
+  T w =  u * P.get(2, 0) + v * P.get(2, 1) + P.get(2,2);
+  x   = (u * P.get(0, 0) + v * P.get(0, 1) + P.get(0,2)) / w;
+  y   = (u * P.get(1, 0) + v * P.get(1, 1) + P.get(1,2)) / w;
+}
+
+
+
+// Quantize value to smaller than or equal value that is multiple of quantum.
+
+inline vsip::length_type
+quantize_floor(vsip::length_type x, vsip::length_type quantum)
+{
+  // assert(quantum is power of 2);
+  return x & ~(quantum-1);
+}
+
+
+
+// Quantize value to larger than or equal value that is multiple of quantum.
+
+inline vsip::length_type
+quantize_ceil(
+  vsip::length_type x,
+  vsip::length_type quantum,
+  vsip::length_type max)
+{
+  // assert(quantum is power of 2);
+  x = (x-1 % quantum == 0) ? x : (x & ~(quantum-1)) + quantum-1;
+  if (x > max) x = max;
+  return x;
+}
+
+
+
+// ALF bridge function for perspective warp.
+
+template <typename T>
+void
+pwarp_block_impl(
+  Matrix<float> P,
+  T const*      p_in,
+  stride_type   in_stride_0,
+  T*            p_out,
+  stride_type   out_stride_0,
+  length_type   in_rows,
+  length_type   in_cols,
+  length_type   out_rows,
+  length_type   out_cols)
+{
+  typedef float CoeffT;
+
+  using vsip::length_type;
+  using vsip::index_type;
+  using vsip::Domain;
+  using std::min;
+  using std::max;
+
+  length_type max_col_chunk_size = pwarp_block_max_col_size;
+
+  length_type col_chunk_size = out_cols;
+  length_type row_chunk_size = (128*128)/col_chunk_size;
+
+  assert(col_chunk_size < max_col_chunk_size);
+
+  length_type row_quantum = 1;
+  length_type col_quantum = 128/sizeof(T);
+
+  assert(is_dma_addr_ok(p_in));
+  assert(is_dma_addr_ok(p_out));
+  assert(is_dma_addr_ok(p_in  + in_stride_0));
+  assert(is_dma_addr_ok(p_out + out_stride_0));
+
+  Pwarp_params pwp;
+
+  pwp.P[0] = P.get(0, 0);
+  pwp.P[1] = P.get(0, 1);
+  pwp.P[2] = P.get(0, 2);
+  pwp.P[3] = P.get(1, 0);
+  pwp.P[4] = P.get(1, 1);
+  pwp.P[5] = P.get(1, 2);
+  pwp.P[6] = P.get(2, 0);
+  pwp.P[7] = P.get(2, 1);
+  pwp.P[8] = P.get(2, 2);
+
+  pwp.ea_in        = ea_from_ptr(p_in);
+  pwp.ea_out       = ea_from_ptr(p_out);
+  pwp.in_stride_0  = in_stride_0;
+  pwp.out_stride_0 = out_stride_0;
+
+  Task_manager *mgr = Task_manager::instance();
+  Task task = mgr->reserve<Pwarp_tag, void(T,T)>
+    (8*1024, // max stack size
+     sizeof(Pwarp_params), 
+     0,
+     sizeof(T)*max_col_chunk_size,
+     true);
+
+  length_type spes         = mgr->num_spes();
+  length_type rows_per_spe = min(out_rows / spes, row_chunk_size);
+  // length_type n_wbs        = out_rows / rows_per_spe;
+
+#if DEBUG
+  std::cout << "CBE rows_per_spe: " << rows_per_spe << "\n";
+  std::cout << "    ea_in: " << (unsigned long long)p_in 
+	    << "   " << pwp.ea_in << "\n";
+#endif
+
+
+  for (index_type r=0; r<out_rows; r += rows_per_spe)
+  {
+    length_type actual_rows = std::min(rows_per_spe, out_rows - r);
+
+    for (index_type c=0; c<out_cols; c += col_chunk_size)
+    {
+      length_type actual_cols = std::min(col_chunk_size, out_cols-c);
+
+      CoeffT u00, v00;
+      CoeffT u01, v01;
+      CoeffT u10, v10;
+      CoeffT u11, v11;
+      apply_proj<CoeffT>(P, c+0*actual_cols, r+0*actual_rows, u00, v00);
+      apply_proj<CoeffT>(P, c+0*actual_cols, r+1*actual_rows, u01, v01);
+      apply_proj<CoeffT>(P, c+1*actual_cols, r+0*actual_rows, u10, v10);
+      apply_proj<CoeffT>(P, c+1*actual_cols, r+1*actual_rows, u11, v11);
+
+      CoeffT min_u = max(CoeffT(0), min(min(u00, u01), min(u10, u11)));
+      CoeffT min_v = max(CoeffT(0), min(min(v00, v01), min(v10, v11)));
+      CoeffT max_u = min(CoeffT(in_cols-1), max(max(u00, u01),max(u10, u11)));
+      CoeffT max_v = min(CoeffT(in_rows-1), max(max(v00, v01),max(v10, v11)));
+
+      index_type in_r0, in_c0, in_r1, in_c1;
+      in_r0 = quantize_floor((index_type)floorf(min_v), row_quantum);
+      in_c0 = quantize_floor((index_type)floorf(min_u), col_quantum);
+      in_r1 = quantize_ceil((index_type)ceilf(max_v), row_quantum, in_rows-1);
+      in_c1 = quantize_ceil((index_type)ceilf(max_u), col_quantum, in_cols-1);
+
+      pwp.in_row_0 = in_r0;
+      pwp.in_col_0 = in_c0;
+      pwp.in_rows  = in_r1 - in_r0 + 1;
+      pwp.in_cols  = in_c1 - in_c0 + 1;
+
+      pwp.out_row_0 = r;
+      pwp.out_col_0 = c;
+      pwp.out_rows  = actual_rows;
+      pwp.out_cols  = actual_cols;
+
+      Workblock block = task.create_multi_block(actual_rows);
+      block.set_parameters(pwp);
+      task.enqueue(block);
+
+#if DEBUG
+      std::cout << "CBE in 0: " << in_r0 << " " << in_c0 << "   "
+		<< "in 1: " << in_r1 << " " << in_c1 << "   "
+		<< "out 0: " << r << " " << c << "   "
+		<< "out size: " << actual_rows << " " << actual_cols
+		<< std::endl;
+      std::cout << "in size: " << (in_r1 - in_r0 + 1) << " "
+		<< (in_c1 - in_c0 + 1)
+		<< std::endl;
+#endif
+	
+    }
+  }
+  task.sync();
+}
+
+
+
+template
+void
+pwarp_block_impl(
+  Matrix<float> P,
+  unsigned char const* in,
+  stride_type          in_stride_0,
+  unsigned char*       out,
+  stride_type          out_stride_0,
+  length_type          in_rows,
+  length_type          in_cols,
+  length_type          out_rows,
+  length_type          out_cols);
+
+} // namespace vsip::impl::cbe
+} // namespace vsip::impl
+} // namespace vsip
Index: src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp
===================================================================
--- src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp	(revision 0)
+++ src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp	(revision 0)
@@ -0,0 +1,737 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/spu/alf_pwarp_ub.c
+    @author  Jules Bergmann
+    @date    2007-11-19
+    @brief   VSIPL++ Library: Kernel to compute perspective warp.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <alf_accel.h>
+#include <assert.h>
+#include <vsip/core/acconfig.hpp>
+#include <spu_mfcio.h>
+#include <vsip/opt/cbe/pwarp_params.h>
+
+#include <vsip/opt/simd/simd_spu.hpp>
+
+#define IMG_SIZE (155*512)
+
+static unsigned char src_img[IMG_SIZE] __attribute__ ((aligned (128)));
+
+extern "C" {
+int alf_prepare_input_list(
+  void*        context,
+  void*        params,
+  void*        list_entries,
+  unsigned int current_count,
+  unsigned int total_count);
+
+int alf_prepare_output_list(
+  void*        context,
+  void*        params,
+  void*        list_entries,
+  unsigned int cur_iter,
+  unsigned int tot_iter);
+
+int alf_comp_kernel(
+  void*        context,
+  void*        params,
+  void*        input,
+  void*        output,
+  unsigned int cur_iter,
+  unsigned int tot_iter);
+}
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+void initialize(Pwarp_params* pwp)
+{
+  if (pwp->in_cols == pwp->in_stride_0)
+  {
+    unsigned int size = pwp->in_rows * pwp->in_cols;
+    unsigned long long ea = pwp->ea_in;
+
+    // assert(size <= IMG_SIZE);
+
+    ea += pwp->in_row_0 * pwp->in_stride_0 + pwp->in_col_0;
+
+    unsigned char*     c_in = src_img;
+    while (size > 0)
+    {
+      unsigned int this_size = (size > 16384) ? 16384 : size;
+      mfc_get(c_in, ea, this_size, 31, 0, 0);
+      c_in += this_size;
+      ea   += this_size;
+      size -= this_size;
+    }
+
+    mfc_write_tag_mask(1<<31);
+    mfc_read_tag_status_all();
+  }
+  else
+  {
+    unsigned int size = pwp->in_cols;
+    unsigned long long ea = pwp->ea_in+
+      pwp->in_row_0 * pwp->in_stride_0 + pwp->in_col_0;
+
+    unsigned int r;
+    unsigned char* cur_in = src_img;
+    for (r=0; r < pwp->in_rows; ++r)
+    {
+      mfc_get(cur_in, ea, size, 31, 0, 0);
+      mfc_write_tag_mask(1<<31);
+      mfc_read_tag_status_all();
+      ea     += pwp->in_stride_0;
+      cur_in += size;
+    }
+  }
+}
+
+
+
+void
+apply_proj(
+  float const* P,
+  float        u,
+  float        v,
+  float*       x,
+  float*       y)
+{
+  float w = (u * P[6] + v * P[7] + P[8]);
+  *x      = (u * P[0] + v * P[1] + P[2]) / w;
+  *y      = (u * P[3] + v * P[4] + P[5]) / w;
+}
+
+
+
+void
+apply_proj_w(
+  float const* P,
+  float        u,
+  float        v,
+  float*       x,
+  float*       y,
+  float*       w)
+{
+  *x = (u * P[0] + v * P[1] + P[2]);
+  *y = (u * P[3] + v * P[4] + P[5]);
+  *w = (u * P[6] + v * P[7] + P[8]);
+}
+
+
+
+void
+pwarp_offset_test_pattern(
+  float*               P,
+  unsigned char const* in,
+  unsigned int         in_r0,
+  unsigned int         in_c0,
+  unsigned char*       out,
+  unsigned int         out_r0,
+  unsigned int         out_c0,
+  unsigned int         in_rows,
+  unsigned int         in_cols,
+  unsigned int         out_rows,
+  unsigned int         out_cols)
+{
+  // Test pattern
+  unsigned int r, c;
+  for (r=0; r<out_rows; ++r)
+    for (c=0; c<out_cols; ++c)
+    {
+      unsigned int rr = r + out_r0;
+      unsigned int cc = c + out_c0;
+      out[r*out_cols + c] = ((rr & 0x10) ^ (cc & 0x10)) ? 255 : 0;
+    }
+}
+
+
+void
+pwarp_offset(
+  float*               P,
+  unsigned char const* in,
+  unsigned int         in_r0,
+  unsigned int         in_c0,
+  unsigned char*       out,
+  unsigned int         out_r0,
+  unsigned int         out_c0,
+  unsigned int         in_rows,
+  unsigned int         in_cols,
+  unsigned int         out_rows,
+  unsigned int         out_cols)
+{
+  unsigned int r, c;
+  for (r=0; r<out_rows; ++r)
+    for (c=0; c<out_cols; ++c)
+    {
+      float x = (float)(c + out_c0);
+      float y = (float)(r + out_r0);
+      float u, v;
+      apply_proj(P, x, y, &u, &v);
+
+      u -= in_c0;
+      v -= in_r0;
+
+      if (u >= 0 && u < in_cols-1 &&
+	  v >= 0 && v < in_rows-1)
+      {
+	unsigned int u0 = (unsigned int)(u);
+	unsigned int v0 = (unsigned int)(v);
+
+	float u_beta = u - u0;
+	float v_beta = v - v0;
+
+	unsigned char x00 = in[(v0+0)*in_cols + u0+0];
+	unsigned char x10 = in[(v0+1)*in_cols + u0+0];
+	unsigned char x01 = in[(v0+0)*in_cols + u0+1];
+	unsigned char x11 = in[(v0+1)*in_cols + u0+1];
+
+	float x0 = (float)((1 - u_beta) * x00 + u_beta * x01);
+	float x1 = (float)((1 - u_beta) * x10 + u_beta * x11);
+
+	float x  = (float)((1 - v_beta) * x0  + v_beta * x1);
+
+	out[r*out_cols + c] = (unsigned char)(x);
+      }
+      else
+      {
+	out[r*out_cols + c] = 0;
+      }
+      
+    }
+}
+
+
+void
+pwarp_offset_simd(
+  float*               P,
+  unsigned char const* p_in,
+  unsigned int         in_r0,
+  unsigned int         in_c0,
+  unsigned char*       p_out,
+  unsigned int         out_r0,
+  unsigned int         out_c0,
+  unsigned int         in_rows,
+  unsigned int         in_cols,
+  unsigned int         out_rows,
+  unsigned int         out_cols)
+{
+  typedef unsigned int index_type;
+  typedef unsigned int length_type;
+  typedef signed int   stride_type;
+
+  typedef float  CoeffT;
+  typedef CoeffT AccumT;
+  typedef unsigned char T;
+
+  typedef vsip::impl::simd::Simd_traits<CoeffT> simd;
+  typedef simd::simd_type              simd_t;
+  typedef simd::bool_simd_type         bool_simd_t;
+
+  typedef vsip::impl::simd::Simd_traits<unsigned int>   ui_simd;
+  typedef ui_simd::simd_type                            ui_simd_t;
+  typedef vsip::impl::simd::Simd_traits<signed int>     si_simd;
+  typedef si_simd::simd_type                            si_simd_t;
+  typedef vsip::impl::simd::Simd_traits<unsigned short> us_simd;
+  typedef us_simd::simd_type                            us_simd_t;
+  typedef vsip::impl::simd::Simd_traits<signed short>   ss_simd;
+  typedef ss_simd::simd_type                            ss_simd_t;
+  typedef vsip::impl::simd::Simd_traits<unsigned char>  uc_simd;
+  typedef uc_simd::simd_type                            uc_simd_t;
+  typedef vsip::impl::simd::Simd_traits<signed char>    sc_simd;
+  typedef sc_simd::simd_type                            sc_simd_t;
+
+  CoeffT      v_clip  = in_rows - 1;
+  CoeffT      u_clip  = in_cols - 1;
+
+  CoeffT u_0, v_0, w_0;
+  CoeffT u_1, v_1, w_1;
+  apply_proj_w(P, 0.,         0., &u_0, &v_0, &w_0);
+  apply_proj_w(P, out_cols-1, 0., &u_1, &v_1, &w_1);
+  CoeffT u_delta = (u_1 - u_0) / (out_cols-1);
+  CoeffT v_delta = (v_1 - v_0) / (out_cols-1);
+  CoeffT w_delta = (w_1 - w_0) / (out_cols-1);
+
+  simd_t vec_u_delta = simd::load_scalar_all(4*u_delta);
+  simd_t vec_v_delta = simd::load_scalar_all(4*v_delta);
+  simd_t vec_w_delta = simd::load_scalar_all(4*w_delta);
+  simd_t vec_u_delta_16 = simd::load_scalar_all(16*u_delta);
+  simd_t vec_v_delta_16 = simd::load_scalar_all(16*v_delta);
+  simd_t vec_w_delta_16 = simd::load_scalar_all(16*w_delta);
+  simd_t vec_0       = simd::load_scalar_all(T(0));
+  simd_t vec_1       = simd::load_scalar_all(T(1));
+  simd_t vec_05      = simd::load_scalar_all(0.0);
+  simd_t vec_u_clip  = simd::load_scalar_all(u_clip);
+  simd_t vec_v_clip  = simd::load_scalar_all(v_clip);
+
+  simd_t vec_u_delta_ramp = simd::load_values(0*u_delta,
+					      1*u_delta,
+					      2*u_delta,
+					      3*u_delta);
+  simd_t vec_v_delta_ramp = simd::load_values(0*v_delta,
+					      1*v_delta,
+					      2*v_delta,
+					      3*v_delta);
+  simd_t vec_w_delta_ramp = simd::load_values(0*w_delta,
+					      1*w_delta,
+					      2*w_delta,
+					      3*w_delta);
+
+  stride_type in_stride_0  = in_cols;
+  stride_type out_stride_0 = out_cols;
+
+  ui_simd_t vec_in_stride_0 = ui_simd::load_scalar_all(in_stride_0);
+  int yet = 0;
+
+  int const fxp_shift = 7;
+
+  ss_simd_t vec_z3_base = ss_simd::load_scalar_all(1 << (fxp_shift-1));
+  si_simd_t vec_z3_i_base = si_simd::load_scalar_all(1 << (15+fxp_shift-1));
+  us_simd_t vec_fxp_shift = us_simd::load_scalar_all(fxp_shift);
+  si_simd_t vec_start = si_simd::load_scalar_all(0x0000);
+
+  for (index_type r=0; r<out_rows; ++r)
+  {
+    CoeffT y = static_cast<CoeffT>(r);
+
+    CoeffT u_base, v_base, w_base;
+    apply_proj_w(P, 0. + out_c0, y + out_r0, &u_base, &v_base, &w_base);
+
+    simd_t vec_u0_base = simd::add(simd::load_scalar_all(u_base),
+				   vec_u_delta_ramp);
+    simd_t vec_v0_base = simd::add(simd::load_scalar_all(v_base),
+				   vec_v_delta_ramp);
+    simd_t vec_w0_base = simd::add(simd::load_scalar_all(w_base),
+				   vec_w_delta_ramp);
+
+    simd_t vec_w1_base = simd::add(vec_w0_base, vec_w_delta);
+    simd_t vec_u1_base = simd::add(vec_u0_base, vec_u_delta);
+    simd_t vec_v1_base = simd::add(vec_v0_base, vec_v_delta);
+    simd_t vec_w2_base = simd::add(vec_w1_base, vec_w_delta);
+    simd_t vec_u2_base = simd::add(vec_u1_base, vec_u_delta);
+    simd_t vec_v2_base = simd::add(vec_v1_base, vec_v_delta);
+    simd_t vec_w3_base = simd::add(vec_w2_base, vec_w_delta);
+    simd_t vec_u3_base = simd::add(vec_u2_base, vec_u_delta);
+    simd_t vec_v3_base = simd::add(vec_v2_base, vec_v_delta);
+
+    for (index_type c=0; c<out_cols; c+=16)
+    {
+      simd_t vec_w0_re = simd::recip(vec_w0_base);
+      simd_t vec_w1_re = simd::recip(vec_w1_base);
+      simd_t vec_w2_re = simd::recip(vec_w2_base);
+      simd_t vec_w3_re = simd::recip(vec_w3_base);
+
+      simd_t vec_u0    = simd::mul(vec_u0_base, vec_w0_re);
+      simd_t vec_v0    = simd::mul(vec_v0_base, vec_w0_re);
+
+      simd_t vec_u1    = simd::mul(vec_u1_base, vec_w1_re);
+      simd_t vec_v1    = simd::mul(vec_v1_base, vec_w1_re);
+
+      simd_t vec_u2    = simd::mul(vec_u2_base, vec_w2_re);
+      simd_t vec_v2    = simd::mul(vec_v2_base, vec_w2_re);
+
+      simd_t vec_u3    = simd::mul(vec_u3_base, vec_w3_re);
+      simd_t vec_v3    = simd::mul(vec_v3_base, vec_w3_re);
+
+      vec_u0 = simd::sub(vec_u0, spu_splats((float)in_c0));
+      vec_u1 = simd::sub(vec_u1, spu_splats((float)in_c0));
+      vec_u2 = simd::sub(vec_u2, spu_splats((float)in_c0));
+      vec_u3 = simd::sub(vec_u3, spu_splats((float)in_c0));
+      vec_v0 = simd::sub(vec_v0, spu_splats((float)in_r0));
+      vec_v1 = simd::sub(vec_v1, spu_splats((float)in_r0));
+      vec_v2 = simd::sub(vec_v2, spu_splats((float)in_r0));
+      vec_v3 = simd::sub(vec_v3, spu_splats((float)in_r0));
+
+      vec_w0_base = simd::add(vec_w0_base, vec_w_delta_16);
+      vec_w1_base = simd::add(vec_w1_base, vec_w_delta_16);
+      vec_w2_base = simd::add(vec_w2_base, vec_w_delta_16);
+      vec_w3_base = simd::add(vec_w3_base, vec_w_delta_16);
+      vec_u0_base = simd::add(vec_u0_base, vec_u_delta_16);
+      vec_u1_base = simd::add(vec_u1_base, vec_u_delta_16);
+      vec_u2_base = simd::add(vec_u2_base, vec_u_delta_16);
+      vec_u3_base = simd::add(vec_u3_base, vec_u_delta_16);
+      vec_v0_base = simd::add(vec_v0_base, vec_v_delta_16);
+      vec_v1_base = simd::add(vec_v1_base, vec_v_delta_16);
+      vec_v2_base = simd::add(vec_v2_base, vec_v_delta_16);
+      vec_v3_base = simd::add(vec_v3_base, vec_v_delta_16);
+
+      bool_simd_t vec_u0_ge0 = simd::ge(vec_u0, vec_0);
+      bool_simd_t vec_u1_ge0 = simd::ge(vec_u1, vec_0);
+      bool_simd_t vec_u2_ge0 = simd::ge(vec_u2, vec_0);
+      bool_simd_t vec_u3_ge0 = simd::ge(vec_u3, vec_0);
+
+      bool_simd_t vec_v0_ge0 = simd::ge(vec_v0, vec_0);
+      bool_simd_t vec_v1_ge0 = simd::ge(vec_v1, vec_0);
+      bool_simd_t vec_v2_ge0 = simd::ge(vec_v2, vec_0);
+      bool_simd_t vec_v3_ge0 = simd::ge(vec_v3, vec_0);
+
+      bool_simd_t vec_u0_ltc = simd::lt(vec_u0, vec_u_clip);
+      bool_simd_t vec_u1_ltc = simd::lt(vec_u1, vec_u_clip);
+      bool_simd_t vec_u2_ltc = simd::lt(vec_u2, vec_u_clip);
+      bool_simd_t vec_u3_ltc = simd::lt(vec_u3, vec_u_clip);
+
+      bool_simd_t vec_v0_ltc = simd::lt(vec_v0, vec_v_clip);
+      bool_simd_t vec_v1_ltc = simd::lt(vec_v1, vec_v_clip);
+      bool_simd_t vec_v2_ltc = simd::lt(vec_v2, vec_v_clip);
+      bool_simd_t vec_v3_ltc = simd::lt(vec_v3, vec_v_clip);
+
+      bool_simd_t vec_u0_good = ui_simd::band(vec_u0_ge0, vec_u0_ltc);
+      bool_simd_t vec_u1_good = ui_simd::band(vec_u1_ge0, vec_u1_ltc);
+      bool_simd_t vec_u2_good = ui_simd::band(vec_u2_ge0, vec_u2_ltc);
+      bool_simd_t vec_u3_good = ui_simd::band(vec_u3_ge0, vec_u3_ltc);
+      bool_simd_t vec_v0_good = ui_simd::band(vec_v0_ge0, vec_v0_ltc);
+      bool_simd_t vec_v1_good = ui_simd::band(vec_v1_ge0, vec_v1_ltc);
+      bool_simd_t vec_v2_good = ui_simd::band(vec_v2_ge0, vec_v2_ltc);
+      bool_simd_t vec_v3_good = ui_simd::band(vec_v3_ge0, vec_v3_ltc);
+      bool_simd_t vec_0_good  = ui_simd::band(vec_u0_good, vec_v0_good);
+      bool_simd_t vec_1_good  = ui_simd::band(vec_u1_good, vec_v1_good);
+      bool_simd_t vec_2_good  = ui_simd::band(vec_u2_good, vec_v2_good);
+      bool_simd_t vec_3_good  = ui_simd::band(vec_u3_good, vec_v3_good);
+
+      us_simd_t vec_s01_good = ui_simd::pack(vec_0_good, vec_1_good);
+      us_simd_t vec_s23_good = ui_simd::pack(vec_2_good, vec_3_good);
+      sc_simd_t vec_good     = (sc_simd_t)us_simd::pack(vec_s01_good,
+							vec_s23_good);
+
+      ui_simd_t vec_u0_int = simd::convert_uint(vec_u0);
+      ui_simd_t vec_u1_int = simd::convert_uint(vec_u1);
+      ui_simd_t vec_u2_int = simd::convert_uint(vec_u2);
+      ui_simd_t vec_u3_int = simd::convert_uint(vec_u3);
+
+      ui_simd_t vec_v0_int = simd::convert_uint(vec_v0);
+      ui_simd_t vec_v1_int = simd::convert_uint(vec_v1);
+      ui_simd_t vec_v2_int = simd::convert_uint(vec_v2);
+      ui_simd_t vec_v3_int = simd::convert_uint(vec_v3);
+
+      simd_t vec_u0_f = ui_simd::convert_float(vec_u0_int);
+      simd_t vec_u1_f = ui_simd::convert_float(vec_u1_int);
+      simd_t vec_u2_f = ui_simd::convert_float(vec_u2_int);
+      simd_t vec_u3_f = ui_simd::convert_float(vec_u3_int);
+      simd_t vec_v0_f = ui_simd::convert_float(vec_v0_int);
+      simd_t vec_v1_f = ui_simd::convert_float(vec_v1_int);
+      simd_t vec_v2_f = ui_simd::convert_float(vec_v2_int);
+      simd_t vec_v3_f = ui_simd::convert_float(vec_v3_int);
+
+      simd_t vec_u0_beta = simd::sub(vec_u0, vec_u0_f);
+      simd_t vec_u1_beta = simd::sub(vec_u1, vec_u1_f);
+      simd_t vec_u2_beta = simd::sub(vec_u2, vec_u2_f);
+      simd_t vec_u3_beta = simd::sub(vec_u3, vec_u3_f);
+      simd_t vec_v0_beta = simd::sub(vec_v0, vec_v0_f);
+      simd_t vec_v1_beta = simd::sub(vec_v1, vec_v1_f);
+      simd_t vec_v2_beta = simd::sub(vec_v2, vec_v2_f);
+      simd_t vec_v3_beta = simd::sub(vec_v3, vec_v3_f);
+      simd_t vec_u0_1_beta = simd::sub(vec_1, vec_u0_beta);
+      simd_t vec_u1_1_beta = simd::sub(vec_1, vec_u1_beta);
+      simd_t vec_u2_1_beta = simd::sub(vec_1, vec_u2_beta);
+      simd_t vec_u3_1_beta = simd::sub(vec_1, vec_u3_beta);
+      simd_t vec_v0_1_beta = simd::sub(vec_1, vec_v0_beta);
+      simd_t vec_v1_1_beta = simd::sub(vec_1, vec_v1_beta);
+      simd_t vec_v2_1_beta = simd::sub(vec_1, vec_v2_beta);
+      simd_t vec_v3_1_beta = simd::sub(vec_1, vec_v3_beta);
+
+      si_simd_t vec_0_k00= simd::convert_sint<15>(
+	simd::fma(vec_u0_1_beta, vec_v0_1_beta, vec_05));
+      si_simd_t vec_1_k00= simd::convert_sint<15>(
+	simd::fma(vec_u1_1_beta, vec_v1_1_beta, vec_05));
+      si_simd_t vec_2_k00= simd::convert_sint<15>(
+	simd::fma(vec_u2_1_beta, vec_v2_1_beta, vec_05));
+      si_simd_t vec_3_k00= simd::convert_sint<15>(
+	simd::fma(vec_u3_1_beta, vec_v3_1_beta, vec_05));
+      si_simd_t vec_0_k01= simd::convert_sint<15>(
+	simd::fma(vec_u0_beta,   vec_v0_1_beta, vec_05));
+      si_simd_t vec_1_k01= simd::convert_sint<15>(
+	simd::fma(vec_u1_beta,   vec_v1_1_beta, vec_05));
+      si_simd_t vec_2_k01= simd::convert_sint<15>(
+	simd::fma(vec_u2_beta,   vec_v2_1_beta, vec_05));
+      si_simd_t vec_3_k01= simd::convert_sint<15>(
+	simd::fma(vec_u3_beta,   vec_v3_1_beta, vec_05));
+      si_simd_t vec_0_k10= simd::convert_sint<15>(
+	simd::fma(vec_u0_1_beta, vec_v0_beta, vec_05));
+      si_simd_t vec_1_k10= simd::convert_sint<15>(
+	simd::fma(vec_u1_1_beta, vec_v1_beta, vec_05));
+      si_simd_t vec_2_k10= simd::convert_sint<15>(
+	simd::fma(vec_u2_1_beta, vec_v2_beta, vec_05));
+      si_simd_t vec_3_k10= simd::convert_sint<15>(
+	simd::fma(vec_u3_1_beta, vec_v3_beta, vec_05));
+      si_simd_t vec_0_k11= simd::convert_sint<15>(
+	simd::fma(vec_u0_beta,   vec_v0_beta, vec_05));
+      si_simd_t vec_1_k11= simd::convert_sint<15>(
+	simd::fma(vec_u1_beta,   vec_v1_beta, vec_05));
+      si_simd_t vec_2_k11= simd::convert_sint<15>(
+	simd::fma(vec_u2_beta,   vec_v2_beta, vec_05));
+      si_simd_t vec_3_k11= simd::convert_sint<15>(
+	simd::fma(vec_u3_beta,   vec_v3_beta, vec_05));
+
+      ss_simd_t vec_01_k00 = si_simd::pack(vec_0_k00, vec_1_k00);
+      ss_simd_t vec_23_k00 = si_simd::pack(vec_2_k00, vec_3_k00);
+      ss_simd_t vec_01_k01 = si_simd::pack(vec_0_k01, vec_1_k01);
+      ss_simd_t vec_23_k01 = si_simd::pack(vec_2_k01, vec_3_k01);
+      ss_simd_t vec_01_k10 = si_simd::pack(vec_0_k10, vec_1_k10);
+      ss_simd_t vec_23_k10 = si_simd::pack(vec_2_k10, vec_3_k10);
+      ss_simd_t vec_01_k11 = si_simd::pack(vec_0_k11, vec_1_k11);
+      ss_simd_t vec_23_k11 = si_simd::pack(vec_2_k11, vec_3_k11);
+
+      ui_simd_t vec_0_offset = ui_simd::add(
+	ui_simd::mull(vec_v0_int, vec_in_stride_0), vec_u0_int);
+      ui_simd_t vec_1_offset = ui_simd::add(
+	ui_simd::mull(vec_v1_int, vec_in_stride_0), vec_u1_int);
+      ui_simd_t vec_2_offset = ui_simd::add(
+	ui_simd::mull(vec_v2_int, vec_in_stride_0), vec_u2_int);
+      ui_simd_t vec_3_offset = ui_simd::add(
+	ui_simd::mull(vec_v3_int, vec_in_stride_0), vec_u3_int);
+
+      unsigned int off_00, off_01, off_02, off_03;
+      unsigned int off_10, off_11, off_12, off_13;
+      unsigned int off_20, off_21, off_22, off_23;
+      unsigned int off_30, off_31, off_32, off_33;
+
+      ui_simd::extract_all(vec_0_offset, off_00, off_01, off_02, off_03);
+      ui_simd::extract_all(vec_1_offset, off_10, off_11, off_12, off_13);
+      ui_simd::extract_all(vec_2_offset, off_20, off_21, off_22, off_23);
+      ui_simd::extract_all(vec_3_offset, off_30, off_31, off_32, off_33);
+
+      T const* p_00 = p_in + off_00;
+      T const* p_01 = p_in + off_01;
+      T const* p_02 = p_in + off_02;
+      T const* p_03 = p_in + off_03;
+      T const* p_10 = p_in + off_10;
+      T const* p_11 = p_in + off_11;
+      T const* p_12 = p_in + off_12;
+      T const* p_13 = p_in + off_13;
+      T const* p_20 = p_in + off_20;
+      T const* p_21 = p_in + off_21;
+      T const* p_22 = p_in + off_22;
+      T const* p_23 = p_in + off_23;
+      T const* p_30 = p_in + off_30;
+      T const* p_31 = p_in + off_31;
+      T const* p_32 = p_in + off_32;
+      T const* p_33 = p_in + off_33;
+
+      T z00_00 =  *p_00;
+      T z10_00 = *(p_00 + in_stride_0);
+      T z01_00 = *(p_00               + 1);
+      T z11_00 = *(p_00 + in_stride_0 + 1);
+      T z00_01 =  *p_01;
+      T z10_01 = *(p_01 + in_stride_0);
+      T z01_01 = *(p_01               + 1);
+      T z11_01 = *(p_01 + in_stride_0 + 1);
+      T z00_02 =  *p_02;
+      T z10_02 = *(p_02 + in_stride_0);
+      T z01_02 = *(p_02               + 1);
+      T z11_02 = *(p_02 + in_stride_0 + 1);
+      T z00_03 =  *p_03;
+      T z10_03 = *(p_03 + in_stride_0);
+      T z01_03 = *(p_03               + 1);
+      T z11_03 = *(p_03 + in_stride_0 + 1);
+
+      T z00_10 =  *p_10;
+      T z10_10 = *(p_10 + in_stride_0);
+      T z01_10 = *(p_10               + 1);
+      T z11_10 = *(p_10 + in_stride_0 + 1);
+      T z00_11 =  *p_11;
+      T z10_11 = *(p_11 + in_stride_0);
+      T z01_11 = *(p_11               + 1);
+      T z11_11 = *(p_11 + in_stride_0 + 1);
+      T z00_12 =  *p_12;
+      T z10_12 = *(p_12 + in_stride_0);
+      T z01_12 = *(p_12               + 1);
+      T z11_12 = *(p_12 + in_stride_0 + 1);
+      T z00_13 =  *p_13;
+      T z10_13 = *(p_13 + in_stride_0);
+      T z01_13 = *(p_13               + 1);
+      T z11_13 = *(p_13 + in_stride_0 + 1);
+
+      T z00_20 =  *p_20;
+      T z10_20 = *(p_20 + in_stride_0);
+      T z01_20 = *(p_20               + 1);
+      T z11_20 = *(p_20 + in_stride_0 + 1);
+      T z00_21 =  *p_21;
+      T z10_21 = *(p_21 + in_stride_0);
+      T z01_21 = *(p_21               + 1);
+      T z11_21 = *(p_21 + in_stride_0 + 1);
+      T z00_22 =  *p_22;
+      T z10_22 = *(p_22 + in_stride_0);
+      T z01_22 = *(p_22               + 1);
+      T z11_22 = *(p_22 + in_stride_0 + 1);
+      T z00_23 =  *p_23;
+      T z10_23 = *(p_23 + in_stride_0);
+      T z01_23 = *(p_23               + 1);
+      T z11_23 = *(p_23 + in_stride_0 + 1);
+
+      T z00_30 =  *p_30;
+      T z10_30 = *(p_30 + in_stride_0);
+      T z01_30 = *(p_30               + 1);
+      T z11_30 = *(p_30 + in_stride_0 + 1);
+      T z00_31 =  *p_31;
+      T z10_31 = *(p_31 + in_stride_0);
+      T z01_31 = *(p_31               + 1);
+      T z11_31 = *(p_31 + in_stride_0 + 1);
+      T z00_32 =  *p_32;
+      T z10_32 = *(p_32 + in_stride_0);
+      T z01_32 = *(p_32               + 1);
+      T z11_32 = *(p_32 + in_stride_0 + 1);
+      T z00_33 =  *p_33;
+      T z10_33 = *(p_33 + in_stride_0);
+      T z01_33 = *(p_33               + 1);
+      T z11_33 = *(p_33 + in_stride_0 + 1);
+
+      ss_simd_t vec_01_z00 = ss_simd::load_values(
+	z00_00, z00_01, z00_02, z00_03,
+	z00_10, z00_11, z00_12, z00_13);
+      ss_simd_t vec_23_z00 = ss_simd::load_values(
+	z00_20, z00_21, z00_22, z00_23,
+	z00_30, z00_31, z00_32, z00_33);
+
+      ss_simd_t vec_01_z10 = ss_simd::load_values(
+	z10_00, z10_01, z10_02, z10_03,
+	z10_10, z10_11, z10_12, z10_13);
+      ss_simd_t vec_23_z10 = ss_simd::load_values(
+	z10_20, z10_21, z10_22, z10_23,
+	z10_30, z10_31, z10_32, z10_33);
+
+      ss_simd_t vec_01_z01 = ss_simd::load_values(
+	z01_00, z01_01, z01_02, z01_03,
+	z01_10, z01_11, z01_12, z01_13);
+      ss_simd_t vec_23_z01 = ss_simd::load_values(
+	z01_20, z01_21, z01_22, z01_23,
+	z01_30, z01_31, z01_32, z01_33);
+
+      ss_simd_t vec_01_z11 = ss_simd::load_values(
+	z11_00, z11_01, z11_02, z11_03,
+	z11_10, z11_11, z11_12, z11_13);
+      ss_simd_t vec_23_z11 = ss_simd::load_values(
+	z11_20, z11_21, z11_22, z11_23,
+	z11_30, z11_31, z11_32, z11_33);
+
+      vec_01_z00 = ss_simd::shiftl(vec_01_z00, vec_fxp_shift);
+      vec_23_z00 = ss_simd::shiftl(vec_23_z00, vec_fxp_shift);
+      vec_01_z10 = ss_simd::shiftl(vec_01_z10, vec_fxp_shift);
+      vec_23_z10 = ss_simd::shiftl(vec_23_z10, vec_fxp_shift);
+      vec_01_z01 = ss_simd::shiftl(vec_01_z01, vec_fxp_shift);
+      vec_23_z01 = ss_simd::shiftl(vec_23_z01, vec_fxp_shift);
+      vec_01_z11 = ss_simd::shiftl(vec_01_z11, vec_fxp_shift);
+      vec_23_z11 = ss_simd::shiftl(vec_23_z11, vec_fxp_shift);
+ 
+      // AltiVec
+      // ss_simd_t vec_01_z0 = vec_madds(vec_01_k00, vec_01_z00, vec_start);
+      // ss_simd_t vec_23_z0 = vec_madds(vec_23_k00, vec_23_z00, vec_start);
+      // ss_simd_t vec_01_z1 = vec_madds(vec_01_k01, vec_01_z01, vec_01_z0);
+      // ss_simd_t vec_23_z1 = vec_madds(vec_23_k01, vec_23_z01, vec_23_z0);
+      // ss_simd_t vec_01_z2 = vec_madds(vec_01_k10, vec_01_z10, vec_01_z1);
+      // ss_simd_t vec_23_z2 = vec_madds(vec_23_k10, vec_23_z10, vec_23_z1);
+      // ss_simd_t vec_01_z3 = vec_madds(vec_01_k11, vec_01_z11, vec_01_z2);
+      // ss_simd_t vec_23_z3 = vec_madds(vec_23_k11, vec_23_z11, vec_23_z2);
+
+      // SPU
+      si_simd_t vec_01_z0l = spu_madd(vec_01_k00, vec_01_z00, vec_start);
+      si_simd_t vec_23_z0l = spu_madd(vec_23_k00, vec_23_z00, vec_start);
+      si_simd_t vec_01_z1l = spu_madd(vec_01_k01, vec_01_z01, vec_01_z0l);
+      si_simd_t vec_23_z1l = spu_madd(vec_23_k01, vec_23_z01, vec_23_z0l);
+      si_simd_t vec_01_z2l = spu_madd(vec_01_k10, vec_01_z10, vec_01_z1l);
+      si_simd_t vec_23_z2l = spu_madd(vec_23_k10, vec_23_z10, vec_23_z1l);
+      si_simd_t vec_01_z3l = spu_madd(vec_01_k11, vec_01_z11, vec_01_z2l);
+      si_simd_t vec_23_z3l = spu_madd(vec_23_k11, vec_23_z11, vec_23_z2l);
+
+      si_simd_t vec_01_z0h = spu_mhhadd(vec_01_k00, vec_01_z00, vec_start);
+      si_simd_t vec_23_z0h = spu_mhhadd(vec_23_k00, vec_23_z00, vec_start);
+      si_simd_t vec_01_z1h = spu_mhhadd(vec_01_k01, vec_01_z01, vec_01_z0h);
+      si_simd_t vec_23_z1h = spu_mhhadd(vec_23_k01, vec_23_z01, vec_23_z0h);
+      si_simd_t vec_01_z2h = spu_mhhadd(vec_01_k10, vec_01_z10, vec_01_z1h);
+      si_simd_t vec_23_z2h = spu_mhhadd(vec_23_k10, vec_23_z10, vec_23_z1h);
+      si_simd_t vec_01_z3h = spu_mhhadd(vec_01_k11, vec_01_z11, vec_01_z2h);
+      si_simd_t vec_23_z3h = spu_mhhadd(vec_23_k11, vec_23_z11, vec_23_z2h);
+
+      vec_01_z3l = si_simd::add(vec_01_z3l, vec_z3_i_base);
+      vec_23_z3l = si_simd::add(vec_23_z3l, vec_z3_i_base);
+      vec_01_z3h = si_simd::add(vec_01_z3h, vec_z3_i_base);
+      vec_23_z3h = si_simd::add(vec_23_z3h, vec_z3_i_base);
+
+      vec_01_z3l = si_simd::shiftr<15+fxp_shift>(vec_01_z3l);
+      vec_23_z3l = si_simd::shiftr<15+fxp_shift>(vec_23_z3l);
+      vec_01_z3h = si_simd::shiftr<15+fxp_shift>(vec_01_z3h);
+      vec_23_z3h = si_simd::shiftr<15+fxp_shift>(vec_23_z3h);
+
+      ss_simd_t vec_01_z3 = si_simd::pack_shuffle(vec_01_z3h, vec_01_z3l);
+      ss_simd_t vec_23_z3 = si_simd::pack_shuffle(vec_23_z3h, vec_23_z3l);
+
+      sc_simd_t vec_out = ss_simd::pack(vec_01_z3, vec_23_z3);
+      vec_out = sc_simd::band(vec_good, vec_out);
+
+      sc_simd::store((signed char*)p_out, vec_out);
+      p_out += 16;
+    }
+  }
+}
+
+
+int alf_prepare_input_list(
+  void*        context,
+  void*        params,
+  void*        list_entries,
+  unsigned int current_count,
+  unsigned int total_count)
+{
+  ALF_DT_LIST_CREATE(list_entries, 0);
+  return 0;
+}
+
+
+
+int alf_prepare_output_list(
+  void*        context,
+  void*        params,
+  void*        list_entries,
+  unsigned int cur_iter,
+  unsigned int tot_iter)
+{
+  Pwarp_params* pwp = (Pwarp_params*)params;
+  addr64 ea;
+
+  // Transfer output.
+  ALF_DT_LIST_CREATE(list_entries, 0);
+  unsigned long length = pwp->out_cols;
+  ea.ull = pwp->ea_out
+    + (cur_iter + pwp->out_row_0) * pwp->out_stride_0 * sizeof(unsigned char);
+  ALF_DT_LIST_ADD_ENTRY(list_entries, length, ALF_DATA_BYTE, ea);
+
+  return 0;
+}
+
+
+
+int alf_comp_kernel(
+  void*        context,
+  void*        params,
+  void*        input,
+  void*        output,
+  unsigned int cur_iter,
+  unsigned int tot_iter)
+{
+  Pwarp_params* pwp = (Pwarp_params *)params;
+
+  if (cur_iter == 0)
+    initialize(pwp);
+
+  unsigned char* out = (unsigned char*)output;
+
+  pwarp_offset_simd(
+    pwp->P,
+    src_img, pwp->in_row_0,             pwp->in_col_0,
+    out,     pwp->out_row_0 + cur_iter, pwp->out_col_0,
+    pwp->in_rows, pwp->in_cols,
+    1, pwp->out_cols);
+
+  return 0;
+}
Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 188740)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -16,13 +16,19 @@
 cbe_sdk_version := @cbe_sdk_version@
 
 src_vsip_opt_cbe_spu_src := $(wildcard $(srcdir)/src/vsip/opt/cbe/spu/*.c)
+src_vsip_opt_cbe_spu_cxx_src := $(wildcard $(srcdir)/src/vsip/opt/cbe/spu/*.cpp)
 ifneq ($(VSIP_IMPL_CBE_SDK_FFT),1)
 src_vsip_opt_cbe_spu_src := $(filter-out %alf_fft_c.c, $(src_vsip_opt_cbe_spu_src))
 endif
+
 src_vsip_opt_cbe_spu_mod := $(patsubst $(srcdir)/%.c, %.spe,\
                               $(src_vsip_opt_cbe_spu_src))
+src_vsip_opt_cbe_spu_cxx_mod := $(patsubst $(srcdir)/%.cpp, %.spe,\
+                              $(src_vsip_opt_cbe_spu_cxx_src))
 src_vsip_opt_cbe_spu_obj := $(patsubst %.spe, %.$(OBJEXT),\
-                              $(src_vsip_opt_cbe_spu_mod))
+                              $(src_vsip_opt_cbe_spu_mod))\
+			    $(patsubst %.spe, %.$(OBJEXT),\
+                              $(src_vsip_opt_cbe_spu_cxx_mod))
 
 #
 # Depending on this configuration parameter, SPE images are either embedded into
@@ -31,11 +37,15 @@
 ifeq ($(enable_cbe_sdk_embedded_images),1)
 src_vsip_cxx_objects += $(src_vsip_opt_cbe_spu_obj)
 else
-spe_images := $(patsubst src/vsip/opt/cbe/spu/%, lib/%, $(src_vsip_opt_cbe_spu_mod))
+spe_images := $(patsubst src/vsip/opt/cbe/spu/%, lib/%,		\
+	                 $(src_vsip_opt_cbe_spu_mod))		\
+	      $(patsubst src/vsip/opt/cbe/spu/%, lib/%,		\
+	                 $(src_vsip_opt_cbe_spu_cxx_mod))
 libs += $(spe_images)
 endif
 
 CC_SPU := @CC_SPU@
+CXX_SPU := spu-g++ ## @CXX_SPU@
 EMBED_SPU := @EMBED_SPU@ -m32
 CPP_SPU_FLAGS := @CPP_SPU_FLAGS@
 
@@ -46,10 +56,12 @@
 CPP_SPU_FLAGS += -I $(srcdir)/src/vsip/opt/cbe
 CPP_SPU_FLAGS += -I $(CBE_SDK_SYSROOT)/usr/spu/include
 CPP_SPU_FLAGS += -I $(CBE_SDK_SYSROOT)/opt/cell/sdk/usr/spu/include
-C_SPU_FLAGS := -O3
+C_SPU_FLAGS := -g
+CXX_SPU_FLAGS := -g
 LD_SPU_FLAGS := -Wl,-N -L$(CBE_SDK_SYSROOT)/usr/spu/lib
 LD_SPU_FLAGS += -L$(CBE_SDK_SYSROOT)/opt/cell/sdk/usr/spu/lib
-SPU_LIBS := src/vsip/opt/cbe/alf/src/spu/libalf_spu.a
+LIBALF_SPU := src/vsip/opt/cbe/alf/src/spu/libalf_spu.a
+SPU_LIBS := $(LIBALF_SPU)
 
 ########################################################################
 # Build instructions
@@ -60,6 +72,11 @@
 $(CC_SPU) -c $(CPP_SPU_FLAGS) $(C_SPU_FLAGS) -o $@ $<
 endef
 
+define compile_cpp_spu
+@echo compiling $(@D)/$(@F)
+$(CXX_SPU) -c $(CPP_SPU_FLAGS) $(CXX_SPU_FLAGS) -o $@ $<
+endef
+
 define archive_spu
 $(archive)
 endef
@@ -85,12 +102,16 @@
 $(src_vsip_opt_cbe_spu_obj): %.$(OBJEXT): %.spe
 	$(EMBED_SPU) $(*F)_spu $< $@
 
-$(src_vsip_opt_cbe_spu_mod): %.spe: %.c src/vsip/opt/cbe/alf/src/spu/libalf_spu.a
+$(src_vsip_opt_cbe_spu_mod): %.spe: %.c $(LIBALF_SPU)
 	$(CC_SPU) $(CPP_SPU_FLAGS) $(C_SPU_FLAGS) $(LD_SPU_FLAGS) -o $@ $< $(SPU_LIBS)
 
+$(src_vsip_opt_cbe_spu_cxx_mod): %.spe: %.cpp $(LIBALF_SPU)
+	$(CXX_SPU) $(CPP_SPU_FLAGS) $(CXX_SPU_FLAGS) $(LD_SPU_FLAGS) -o $@ $< $(SPU_LIBS)
+
 -include src/vsip/opt/cbe/alf/src/spu/GNUmakefile.inc
 
 mostlyclean::
 	rm -f $(src_vsip_opt_cbe_spu_obj)
 	rm -f $(src_vsip_opt_cbe_spu_mod)
+	rm -f $(src_vsip_opt_cbe_spu_cxx_mod)
 
Index: src/vsip/opt/simd/simd.hpp
===================================================================
--- src/vsip/opt/simd/simd.hpp	(revision 188740)
+++ src/vsip/opt/simd/simd.hpp	(working copy)
@@ -40,6 +40,10 @@
 #include <complex>
 #include <cassert>
 
+#include <vsip/opt/simd/simd_common.hpp>
+
+
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -51,168 +55,6 @@
 namespace simd
 {
 
-#if defined(_MC_EXEC)
-typedef long intptr_t;
-#endif
-
-
-
-// -------------------------------------------------------------------- //
-// Simd_traits -- traits class for SIMD types and operations
-//
-// Each specialization should define the following:
-//
-// Values:
-//  - vec_size  - width of SIMD vector
-//  - is_accel  - true  if specialization actually defines a SIMD Vector type
-//              - false if default trait is used (simd_type == value_type)
-//  - alignment - alignment required for SIMD types (in bytes).
-//                (If alignment == 1, then no special alignment required).
-//  - scalar_pos - the position of the scalar value if SIMD vector is
-//                 written to array in memory.
-//
-// Types:
-//  - value_type - base type (or element type) of SIMD vector
-//  - simd_type  - SIMD vector type
-//
-// Alignment Utilities
-//  - alignment_of    - returns 0 if address is aligned, returns
-//                      number of bytes of misalignment otherwise.
-//
-// IO Operations:
-//  - zero            - return "zero" SIMD vector.
-//  - load            - load a SIMD vector from an address
-//  - load_scalar     - load a scalar into pos 0 of SIMD vector
-//  - load_scalar_all - load a scalar into all pos of SIMD vector
-//  - store           - store a SIMD vector to an address
-//
-// Arithmetic Operations:
-//  - add             - add two SIMD vectors together
-//  - sub             - subtract two SIMD vectors
-//  - mul             - multiply two SIMD vectors together
-//  - fma
-//  - mag	      - magnitude (aka absolute value) of a SIMD vector
-//
-// Logic Operations:
-//  - band            - bitwise-and two SIMD vectors
-//  - bor             - bitwise-or two SIMD vectors
-//  - bxor            - bitwise-xor two SIMD vectors
-//  - bnot            - bitwise-negation of one SIMD vector
-//
-// Shuffle Operations
-//  - extend                    - extend value in pos 0 to entire SIMD vector.
-//  - real_from_interleaved     - create real SIMD from two interleaved SIMDs
-//  - imag_from_interleaved     - create imag SIMD from two interleaved SIMDs
-//  - interleaved_lo_from_split -
-//  - interleaved_hi_from_split -
-//  - pack                      - pack 2 SIMD vectors into 1, reducing range
-//
-// Architecture/Compiler Notes
-//  - GCC support for Intel SSE is good (3.4, 4.0, 4.1 all work)
-//  - GCC 3.4 is broken for Altivec
-//     - typedefs of vector types are not supported within a struct
-//       (top-level typedefs work fine).
-//  - GHS support for Altivec is good.
-//     - peculiar about order: __vector must come first.
-// -------------------------------------------------------------------- //
-template <typename T>
-struct Simd_traits;
-
-
-
-// -------------------------------------------------------------------- //
-// default class definition - defines value_type == simd_type
-template <typename T>
-struct Simd_traits {
-  typedef T	value_type;
-  typedef T	simd_type;
-  typedef int   simd_itype;
-   
-  static int const  vec_size   = 1;
-  static bool const is_accel   = false;
-  static bool const has_perm   = false;
-  static bool const has_div    = true;
-  static int  const alignment  = 1;
-  static unsigned int const scalar_pos = 0;
-
-  static intptr_t alignment_of(value_type const* addr)
-  { return (intptr_t)addr & (alignment - 1); }
-
-  static simd_type zero()
-  { return simd_type(0); }
-
-  static simd_type load(value_type const* addr)
-  { return *addr; }
-
-  static simd_type load_unaligned(value_type const* addr)
-  { return *addr; }
-
-  static simd_type load_scalar(value_type value)
-  { return value; }
-
-  static simd_type load_scalar_all(value_type value)
-  { return value; }
-
-  static void store(value_type* addr, simd_type const& vec)
-  { *addr = vec; }
-
-  static simd_type add(simd_type const& v1, simd_type const& v2)
-  { return v1 + v2; }
-
-  static simd_type mul(simd_type const& v1, simd_type const& v2)
-  { return v1 * v2; }
-
-  static simd_type div(simd_type const& v1, simd_type const& v2)
-  { return v1 / v2; }
-
-  static simd_type mag(simd_type const& v1)
-  { return mag(v1); }
-
-  static simd_type fma(simd_type const& v1, simd_type const& v2,
-		       simd_type const& v3)
-  { return v1 * v2 + v3; }
-
-  static simd_type min(simd_type const& v1, simd_type const& v2)
-  { return (v1 < v2) ? v1 : v2; }
-
-  static simd_type max(simd_type const& v1, simd_type const& v2)
-  { return (v1 > v2) ? v1 : v2; }
-
-  // These functions return ints and operate on ints
-  static simd_itype band(simd_itype const& v1, simd_itype const& v2)
-  { return v1 & v2; }
-
-  static simd_itype bor(simd_itype const& v1, simd_itype const& v2)
-  { return v1 | v2; }
-
-  static simd_itype bxor(simd_itype const& v1, simd_itype const& v2)
-  { return v1 ^ v2; }
-
-  static simd_itype bnot(simd_itype const& v1)
-  { return ~v1; }
-
-  // These functions take floats and return ints
-  static simd_itype gt(simd_type const& v1, simd_type const& v2)
-  { return (v1 > v2) ? simd_itype(-1) : simd_itype(0); }
-
-  static simd_itype lt(simd_type const& v1, simd_type const& v2)
-  { return (v1 < v2) ? simd_itype(-1) : simd_itype(0); }
-
-  static simd_itype ge(simd_type const& v1, simd_type const& v2)
-  { return (v1 >= v2) ? simd_itype(-1) : simd_itype(0); }
-
-  static simd_itype le(simd_type const& v1, simd_type const& v2)
-  { return (v1 <= v2) ? simd_itype(-1) : simd_itype(0); }
-
-  static simd_type pack(simd_type const&, simd_type const&)
-  { assert(0); }
-
-  static void enter() {}
-  static void exit()  {}
-};
-
-
-
 /***********************************************************************
   AltiVec
 ***********************************************************************/
@@ -235,9 +77,11 @@
 #    endif
 
 #if __BIG_ENDIAN__
-#  define VSIP_IMPL_SCALAR_POS(VS) 0
+#  define VSIP_IMPL_SCALAR_POS(VS)  0
+#  define VSIP_IMPL_SCALAR_INCR     1
 #else
-#  define VSIP_IMPL_SCALAR_POS(VS) VS-1
+#  define VSIP_IMPL_SCALAR_POS(VS)  VS-1
+#  define VSIP_IMPL_SCALAR_INCR     -1
 #endif
 
 // PowerPC AltiVec - signed char
@@ -365,7 +209,7 @@
   }
 
   static simd_type load(value_type const* addr)
-  { return vec_ld(0, (short*)addr); }
+  { return vec_ld(0, (signed short*)addr); }
 
   static simd_type load_unaligned(value_type const* addr)
   {
@@ -396,9 +240,56 @@
   static simd_type load_scalar_all(value_type value)
   { return vec_splat(load_scalar(value), scalar_pos); }
 
+  static simd_type load_values(value_type v0, value_type v1,
+			       value_type v2, value_type v3,
+			       value_type v4, value_type v5,
+			       value_type v6, value_type v7)
+  {
+#if __ghs__
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.val[scalar_pos + 0*VSIP_IMPL_SCALAR_INCR] = v0;
+    u.val[scalar_pos + 1*VSIP_IMPL_SCALAR_INCR] = v1;
+    u.val[scalar_pos + 2*VSIP_IMPL_SCALAR_INCR] = v2;
+    u.val[scalar_pos + 3*VSIP_IMPL_SCALAR_INCR] = v3;
+    u.val[scalar_pos + 4*VSIP_IMPL_SCALAR_INCR] = v4;
+    u.val[scalar_pos + 5*VSIP_IMPL_SCALAR_INCR] = v5;
+    u.val[scalar_pos + 6*VSIP_IMPL_SCALAR_INCR] = v6;
+    u.val[scalar_pos + 7*VSIP_IMPL_SCALAR_INCR] = v7;
+    return u.vec;
+#else
+return VSIP_IMPL_AV_LITERAL(simd_type, v0, v1, v2, v3, v4, v5, v6, v7);
+#endif
+  }
+
   static void store(value_type* addr, simd_type const& vec)
   { vec_st(vec, 0, addr); }
 
+  static void extract_all(simd_type const& v,
+			  value_type& v0, value_type& v1,
+			  value_type& v2, value_type& v3,
+			  value_type& v4, value_type& v5,
+			  value_type& v6, value_type& v7)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec = v;
+    v0 = u.val[0];
+    v1 = u.val[1];
+    v2 = u.val[2];
+    v3 = u.val[3];
+    v4 = u.val[4];
+    v5 = u.val[5];
+    v6 = u.val[6];
+    v7 = u.val[7];
+  }
+
   static simd_type add(simd_type const& v1, simd_type const& v2)
   { return vec_add(v1, v2); }
 
@@ -438,6 +329,173 @@
 
 
 
+// PowerPC AltiVec - unsigned short vector
+template <>
+struct Simd_traits<unsigned short>
+{
+  typedef unsigned short                   value_type;
+  typedef __vector unsigned short          simd_type;
+  typedef __vector unsigned char           perm_simd_type;
+  typedef __vector VSIP_IMPL_AV_BOOL short bool_simd_type;
+  typedef __vector unsigned char           pack_simd_type;
+   
+  static int const  vec_size  = 8;
+  static bool const is_accel  = true;
+  static bool const has_perm  = true;
+  static bool const has_div   = false;
+  static int  const alignment = 16;
+
+  static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  {
+    return VSIP_IMPL_AV_LITERAL(simd_type, 0, 0, 0, 0,  0, 0, 0, 0);
+  }
+
+  static simd_type load(value_type const* addr)
+  // 071116: CBE SDK 2.1 ppu-g++ 4.1.1 thinks vec_ld returns vector
+  //         unsigned int.
+  { return (simd_type)vec_ld(0, (unsigned short*)addr); }
+
+  static simd_type load_unaligned(value_type const* addr)
+  {
+    simd_type              x0 = vec_ld(0,  (value_type*)addr);
+    simd_type              x1 = vec_ld(16, (value_type*)addr);
+    __vector unsigned char sh = vec_lvsl(0, (value_type*)addr);
+    return vec_perm(x0, x1, sh);
+  }
+
+  static perm_simd_type shift_for_addr(value_type const* addr)
+  { return vec_lvsl(0, addr); }
+
+  static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
+  { return vec_perm(x0, x1, sh); }
+
+  static simd_type load_scalar(value_type value)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec    = zero();
+    u.val[0] = value;
+    return u.vec;
+  }
+
+  static simd_type load_scalar_all(value_type value)
+  { return vec_splat(load_scalar(value), scalar_pos); }
+
+  static simd_type load_values(value_type v0, value_type v1,
+			       value_type v2, value_type v3,
+			       value_type v4, value_type v5,
+			       value_type v6, value_type v7)
+  {
+#if __ghs__
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.val[scalar_pos + 0*VSIP_IMPL_SCALAR_INCR] = v0;
+    u.val[scalar_pos + 1*VSIP_IMPL_SCALAR_INCR] = v1;
+    u.val[scalar_pos + 2*VSIP_IMPL_SCALAR_INCR] = v2;
+    u.val[scalar_pos + 3*VSIP_IMPL_SCALAR_INCR] = v3;
+    u.val[scalar_pos + 4*VSIP_IMPL_SCALAR_INCR] = v4;
+    u.val[scalar_pos + 5*VSIP_IMPL_SCALAR_INCR] = v5;
+    u.val[scalar_pos + 6*VSIP_IMPL_SCALAR_INCR] = v6;
+    u.val[scalar_pos + 7*VSIP_IMPL_SCALAR_INCR] = v7;
+    return u.vec;
+#else
+return VSIP_IMPL_AV_LITERAL(simd_type, v0, v1, v2, v3, v4, v5, v6, v7);
+#endif
+  }
+
+  static void store(value_type* addr, simd_type const& vec)
+  { vec_st(vec, 0, addr); }
+
+  static value_type extract(simd_type const& v, int pos)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec             = v;
+    return u.val[pos];
+  }
+
+  static void extract_all(simd_type const& v,
+			  value_type& v0, value_type& v1,
+			  value_type& v2, value_type& v3,
+			  value_type& v4, value_type& v5,
+			  value_type& v6, value_type& v7)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec = v;
+    v0 = u.val[0];
+    v1 = u.val[1];
+    v2 = u.val[2];
+    v3 = u.val[3];
+    v4 = u.val[4];
+    v5 = u.val[5];
+    v6 = u.val[6];
+    v7 = u.val[7];
+  }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return vec_add(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return vec_sub(v1, v2); }
+
+  static simd_type fma(simd_type const& v1, simd_type const& v2,
+		       simd_type const& v3)
+  { return vec_mladd(v1, v2, v3); }
+
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return vec_and(v1, v2); }
+
+  static simd_type band(bool_simd_type const& v1, simd_type const& v2)
+  { return vec_and(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return vec_or(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return vec_xor(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return vec_nor(v1, v1); }
+
+  static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return vec_cmpgt(v1, v2); }
+
+  static bool_simd_type lt(simd_type const& v1, simd_type const& v2)
+  { return vec_cmplt(v1, v2); }
+
+  static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
+  { return vec_cmplt(v2, v1); }
+
+  static bool_simd_type le(simd_type const& v1, simd_type const& v2)
+  { return vec_cmpgt(v2, v1); }
+
+  static pack_simd_type pack(simd_type const& v1, simd_type const& v2)
+  { return vec_pack(v1, v2); }
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+
+
 // PowerPC AltiVec - signed short vector
 template <>
 struct Simd_traits<signed int>
@@ -508,6 +566,10 @@
   static simd_type band(simd_type const& v1, simd_type const& v2)
   { return vec_and(v1, v2); }
 
+  static bool_simd_type band(bool_simd_type const& v1,
+			     bool_simd_type const& v2)
+  { return vec_and(v1, v2); }
+
   static simd_type bor(simd_type const& v1, simd_type const& v2)
   { return vec_or(v1, v2); }
 
@@ -538,12 +600,155 @@
 
 
 
+// PowerPC AltiVec - unsigned short vector
+template <>
+struct Simd_traits<unsigned int>
+{
+  typedef unsigned int                   value_type;
+  typedef __vector unsigned int          simd_type;
+  typedef __vector unsigned char         perm_simd_type;
+  typedef __vector VSIP_IMPL_AV_BOOL int bool_simd_type;
+  typedef __vector unsigned short        pack_simd_type;
+   
+  static int const  vec_size  = 4;
+  static bool const is_accel  = true;
+  static bool const has_perm  = true;
+  static bool const has_div   = false;
+  static int  const alignment = 16;
+
+  static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  {
+    return VSIP_IMPL_AV_LITERAL(simd_type, 0, 0, 0, 0);
+  }
+
+  static simd_type load(value_type const* addr)
+  { return vec_ld(0, (value_type*)addr); }
+
+  static simd_type load_unaligned(value_type const* addr)
+  {
+    simd_type              x0 = vec_ld(0,  (value_type*)addr);
+    simd_type              x1 = vec_ld(16, (value_type*)addr);
+    __vector unsigned char sh = vec_lvsl(0, (value_type*)addr);
+    return vec_perm(x0, x1, sh);
+  }
+
+  static perm_simd_type shift_for_addr(value_type const* addr)
+  { return vec_lvsl(0, addr); }
+
+  static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
+  { return vec_perm(x0, x1, sh); }
+
+  static simd_type load_scalar(value_type value)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec    = zero();
+    u.val[0] = value;
+    return u.vec;
+  }
+
+  static simd_type load_scalar_all(value_type value)
+  { return vec_splat(load_scalar(value), scalar_pos); }
+
+  static void store(value_type* addr, simd_type const& vec)
+  { vec_st(vec, 0, addr); }
+
+  static value_type extract(simd_type const& v, int pos)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec             = v;
+    return u.val[pos];
+  }
+
+  static void extract_all(simd_type const& v,
+			  value_type& v0, value_type& v1,
+			  value_type& v2, value_type& v3)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec             = v;
+    v0 = u.val[0];
+    v1 = u.val[1];
+    v2 = u.val[2];
+    v3 = u.val[3];
+  }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return vec_add(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return vec_sub(v1, v2); }
+
+  // multiply high half-width (or even half-width elements).
+  static simd_type mulh(simd_type const& v1, simd_type const& v2)
+  { return vec_mule((__vector unsigned short)v1, (__vector unsigned short)v2); }
+
+  // multiply low half-width (or odd half-width elements).
+  static simd_type mull(simd_type const& v1, simd_type const& v2)
+  { return vec_mulo((__vector unsigned short)v1, (__vector unsigned short)v2); }
+
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return vec_and(v1, v2); }
+
+  static bool_simd_type band(bool_simd_type const& v1,
+			     bool_simd_type const& v2)
+  { return vec_and(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return vec_or(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return vec_xor(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return vec_nor(v1, v1); }
+
+  static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return vec_cmpgt(v1, v2); }
+
+  static bool_simd_type lt(simd_type const& v1, simd_type const& v2)
+  { return vec_cmplt(v1, v2); }
+
+  static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
+  { return vec_cmplt(v2, v1); }
+
+  static bool_simd_type le(simd_type const& v1, simd_type const& v2)
+  { return vec_cmpgt(v2, v1); }
+
+  static pack_simd_type pack(simd_type const& v1, simd_type const& v2)
+  { return vec_pack(v1, v2); }
+
+  static __vector float convert_float(simd_type const& v)
+  { return vec_ctf(v, 0); }
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+
+
 // PowerPC AltiVec - float vector
 template <>
 struct Simd_traits<float>
 {
   typedef float                          value_type;
   typedef __vector float                 simd_type;
+  typedef __vector unsigned int          uint_simd_type;
   typedef __vector unsigned char         perm_simd_type;
   typedef __vector VSIP_IMPL_AV_BOOL int bool_simd_type;
    
@@ -599,12 +804,58 @@
   static simd_type load_scalar_all(value_type value)
   { return vec_splat(load_scalar(value), scalar_pos); }
 
+  static simd_type load_values(value_type v0, value_type v1,
+			       value_type v2, value_type v3)
+  {
+#if __ghs__
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.val[scalar_pos + 0*VSIP_IMPL_SCALAR_INCR] = v0;
+    u.val[scalar_pos + 1*VSIP_IMPL_SCALAR_INCR] = v1;
+    u.val[scalar_pos + 2*VSIP_IMPL_SCALAR_INCR] = v2;
+    u.val[scalar_pos + 3*VSIP_IMPL_SCALAR_INCR] = v3;
+    return u.vec;
+#else
+    return VSIP_IMPL_AV_LITERAL(simd_type, v0, v1, v2, v3);
+#endif
+  }
+
   static void store(value_type* addr, simd_type const& vec)
   { vec_st(vec, 0, addr); }
 
   static void store_stream(value_type* addr, simd_type const& vec)
   { vec_st(vec, 0, addr); }
 
+  static value_type extract(simd_type const& v, int pos)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec             = v;
+    return u.val[pos];
+  }
+
+  static void extract_all(simd_type const& v,
+			  value_type& v0, value_type& v1,
+			  value_type& v2, value_type& v3)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec             = v;
+    v0 = u.val[0];
+    v1 = u.val[1];
+    v2 = u.val[2];
+    v3 = u.val[3];
+  }
+
   static simd_type add(simd_type const& v1, simd_type const& v2)
   { return vec_add(v1, v2); }
 
@@ -614,10 +865,28 @@
   static simd_type mul(simd_type const& v1, simd_type const& v2)
   { return vec_madd(v1, v2, zero()); }
 
+  static simd_type div_est(simd_type const& v1, simd_type const& v2)
+  { return vec_madd(v1, vec_re(v2), zero()); }
+
+  static simd_type div(simd_type const& v1, simd_type const& v2)
+  { return vec_madd(v1, vec_re(v2), zero()); }
+
   static simd_type fma(simd_type const& v1, simd_type const& v2,
 		       simd_type const& v3)
   { return vec_madd(v1, v2, v3); }
 
+  static simd_type recip_est(simd_type const& v1)
+  { return vec_re(v1); }
+
+  static simd_type recip(simd_type const& v1)
+  {
+    simd_type one = VSIP_IMPL_AV_LITERAL(simd_type, 1.f, 1.f, 1.f, 1.f);
+    simd_type y0  = vec_re(v1);
+    simd_type t   = vec_nmsub(y0, v1, one);
+    simd_type y1  = vec_madd(y0, t, y0);
+    return y1;
+  }
+
   static simd_type mag(simd_type const& v1)
   { return vec_abs(v1); }
 
@@ -627,6 +896,9 @@
   static simd_type max(simd_type const& v1, simd_type const& v2)
   { return vec_max(v1, v2); }
 
+  static simd_type band(bool_simd_type const& v1, simd_type const& v2)
+  { return vec_and(v1, v2); }
+
   static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
   { return vec_cmpgt(v1, v2); }
 
@@ -669,6 +941,9 @@
 					     simd_type const& imag)
   { return vec_mergel(real, imag); }
 
+  static uint_simd_type convert_uint(simd_type const& v)
+  { return vec_ctu(v, 0); }
+
   static void enter() {}
   static void exit()  {}
 };
Index: src/vsip/opt/simd/simd_common.hpp
===================================================================
--- src/vsip/opt/simd/simd_common.hpp	(revision 0)
+++ src/vsip/opt/simd/simd_common.hpp	(revision 0)
@@ -0,0 +1,196 @@
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/simd/simd_common.hpp
+    @author  Jules Bergmann
+    @date    2007-11-21
+    @brief   VSIPL++ Library: SIMD traits class.
+
+*/
+
+#ifndef VSIP_OPT_SIMD_COMMON_HPP
+#define VSIP_OPT_SIMD_COMMON_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace simd
+{
+
+#if defined(_MC_EXEC)
+typedef long intptr_t;
+#endif
+
+// -------------------------------------------------------------------- //
+// Simd_traits -- traits class for SIMD types and operations
+//
+// Each specialization should define the following:
+//
+// Values:
+//  - vec_size  - width of SIMD vector
+//  - is_accel  - true  if specialization actually defines a SIMD Vector type
+//              - false if default trait is used (simd_type == value_type)
+//  - alignment - alignment required for SIMD types (in bytes).
+//                (If alignment == 1, then no special alignment required).
+//  - scalar_pos - the position of the scalar value if SIMD vector is
+//                 written to array in memory.
+//
+// Types:
+//  - value_type - base type (or element type) of SIMD vector
+//  - simd_type  - SIMD vector type
+//
+// Alignment Utilities
+//  - alignment_of    - returns 0 if address is aligned, returns
+//                      number of bytes of misalignment otherwise.
+//
+// IO Operations:
+//  - zero            - return "zero" SIMD vector.
+//  - load            - load a SIMD vector from an address
+//  - load_scalar     - load a scalar into pos 0 of SIMD vector
+//  - load_scalar_all - load a scalar into all pos of SIMD vector
+//  - store           - store a SIMD vector to an address
+//
+// Arithmetic Operations:
+//  - add             - add two SIMD vectors together
+//  - sub             - subtract two SIMD vectors
+//  - mul             - multiply two SIMD vectors together
+//  - fma
+//  - mag	      - magnitude (aka absolute value) of a SIMD vector
+//
+// Logic Operations:
+//  - band            - bitwise-and two SIMD vectors
+//  - bor             - bitwise-or two SIMD vectors
+//  - bxor            - bitwise-xor two SIMD vectors
+//  - bnot            - bitwise-negation of one SIMD vector
+//
+// Shuffle Operations
+//  - extend                    - extend value in pos 0 to entire SIMD vector.
+//  - real_from_interleaved     - create real SIMD from two interleaved SIMDs
+//  - imag_from_interleaved     - create imag SIMD from two interleaved SIMDs
+//  - interleaved_lo_from_split -
+//  - interleaved_hi_from_split -
+//  - pack                      - pack 2 SIMD vectors into 1, reducing range
+//
+// Architecture/Compiler Notes
+//  - GCC support for Intel SSE is good (3.4, 4.0, 4.1 all work)
+//  - GCC 3.4 is broken for Altivec
+//     - typedefs of vector types are not supported within a struct
+//       (top-level typedefs work fine).
+//  - GHS support for Altivec is good.
+//     - peculiar about order: __vector must come first.
+// -------------------------------------------------------------------- //
+template <typename T>
+struct Simd_traits;
+
+
+
+// -------------------------------------------------------------------- //
+// default class definition - defines value_type == simd_type
+template <typename T>
+struct Simd_traits {
+  typedef T	value_type;
+  typedef T	simd_type;
+  typedef int   simd_itype;
+   
+  static int const  vec_size   = 1;
+  static bool const is_accel   = false;
+  static bool const has_perm   = false;
+  static bool const has_div    = true;
+  static int  const alignment  = 1;
+  static unsigned int const scalar_pos = 0;
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  { return simd_type(0); }
+
+  static simd_type load(value_type const* addr)
+  { return *addr; }
+
+  static simd_type load_unaligned(value_type const* addr)
+  { return *addr; }
+
+  static simd_type load_scalar(value_type value)
+  { return value; }
+
+  static simd_type load_scalar_all(value_type value)
+  { return value; }
+
+  static void store(value_type* addr, simd_type const& vec)
+  { *addr = vec; }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return v1 + v2; }
+
+  static simd_type mul(simd_type const& v1, simd_type const& v2)
+  { return v1 * v2; }
+
+  static simd_type div(simd_type const& v1, simd_type const& v2)
+  { return v1 / v2; }
+
+  static simd_type mag(simd_type const& v1)
+  { return mag(v1); }
+
+  static simd_type fma(simd_type const& v1, simd_type const& v2,
+		       simd_type const& v3)
+  { return v1 * v2 + v3; }
+
+  static simd_type min(simd_type const& v1, simd_type const& v2)
+  { return (v1 < v2) ? v1 : v2; }
+
+  static simd_type max(simd_type const& v1, simd_type const& v2)
+  { return (v1 > v2) ? v1 : v2; }
+
+  // These functions return ints and operate on ints
+  static simd_itype band(simd_itype const& v1, simd_itype const& v2)
+  { return v1 & v2; }
+
+  static simd_itype bor(simd_itype const& v1, simd_itype const& v2)
+  { return v1 | v2; }
+
+  static simd_itype bxor(simd_itype const& v1, simd_itype const& v2)
+  { return v1 ^ v2; }
+
+  static simd_itype bnot(simd_itype const& v1)
+  { return ~v1; }
+
+  // These functions take floats and return ints
+  static simd_itype gt(simd_type const& v1, simd_type const& v2)
+  { return (v1 > v2) ? simd_itype(-1) : simd_itype(0); }
+
+  static simd_itype lt(simd_type const& v1, simd_type const& v2)
+  { return (v1 < v2) ? simd_itype(-1) : simd_itype(0); }
+
+  static simd_itype ge(simd_type const& v1, simd_type const& v2)
+  { return (v1 >= v2) ? simd_itype(-1) : simd_itype(0); }
+
+  static simd_itype le(simd_type const& v1, simd_type const& v2)
+  { return (v1 <= v2) ? simd_itype(-1) : simd_itype(0); }
+
+  static simd_type pack(simd_type const&, simd_type const&)
+  { assert(0); }
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_SIMD_COMMON_HPP
Index: src/vsip/opt/simd/simd_spu.hpp
===================================================================
--- src/vsip/opt/simd/simd_spu.hpp	(revision 0)
+++ src/vsip/opt/simd/simd_spu.hpp	(revision 0)
@@ -0,0 +1,923 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/simd/simd_spu.hpp
+    @author  Jules Bergmann
+    @date    2007-11-20
+    @brief   VSIPL++ Library: SPU SIMD traits.
+
+*/
+
+#ifndef VSIP_OPT_SIMD_SPU_HPP
+#define VSIP_OPT_SIMD_SPU_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <spu_mfcio.h>
+#include <complex>
+
+#include <vsip/opt/simd/simd_common.hpp>
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace simd
+{
+
+/***********************************************************************
+  Cell/B.E. SPU
+***********************************************************************/
+
+#define VSIP_IMPL_SPU_LITERAL(_type_, ...) ((_type_){__VA_ARGS__})
+
+#if __BIG_ENDIAN__
+#  define VSIP_IMPL_SCALAR_POS(VS) 0
+#else
+#  define VSIP_IMPL_SCALAR_POS(VS) VS-1
+#endif
+
+
+
+/***********************************************************************
+  Cell/B.E. SPU - signed char vector
+***********************************************************************/
+
+template <>
+struct Simd_traits<signed char>
+{
+  typedef signed char            value_type;
+  typedef __vector signed char   simd_type;
+  typedef __vector unsigned char perm_simd_type;
+  typedef __vector unsigned char bool_simd_type;
+   
+  static int  const vec_size   = 16;
+  static bool const is_accel   = true;
+  static bool const has_perm   = true;
+  static bool const has_div    = false;
+  static int  const alignment  = 16;
+
+  static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  {
+    return VSIP_IMPL_SPU_LITERAL(simd_type,
+				0, 0, 0, 0,  0, 0, 0, 0,
+				0, 0, 0, 0,  0, 0, 0, 0 );
+  }
+
+  static simd_type load(value_type const* addr)
+  { return *((simd_type*)addr); }
+
+  static simd_type load_unaligned(value_type const* addr)
+  {
+    // Language Extentions for CBEA, section 1.8
+    simd_type x0 = *((simd_type*)addr);
+    simd_type x1 = *((simd_type*)addr + 1);
+    unsigned int shift = (unsigned int)(ptr) & 15;
+    return spu_or(spu_slqwbyte(x0, shift),
+		  spu_rlmaskqwbyte(x1, (signed)(shift - 16)));
+  }
+  
+  static perm_simd_type shift_for_addr(value_type const* addr)
+  { 
+    typedef __vector unsigned short us_simd_type;
+    return ((perm_simd_type)spu_add(
+	      (us_simd_type)(spu_splats((unsigned char)(((int)(addr)) & 0xF))),
+	      ((us_simd_type){0x0001, 0x0203, 0x0405, 0x0607,
+		              0x0809, 0x0A0B, 0x0C0D, 0x0E0F})));
+  }
+
+  static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
+  { return spu_shuffle(x0, x1, spu_and(c, 0x1F)); }
+
+  static simd_type load_scalar(value_type value)
+  { return (simd_type)si_from_float(value); }
+
+  static simd_type load_scalar_all(value_type value)
+  { return spu_splats(value); }
+
+  static void store(value_type* addr, simd_type const& vec)
+  { *((simd_type*)addr) = vec; }
+
+  // SPU cannot add/sub chars
+  // static simd_type add(simd_type const& v1, simd_type const& v2)
+  // static simd_type sub(simd_type const& v1, simd_type const& v2)
+
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return spu_and(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return spu_or(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return spu_xor(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return spu_nor(v1, v1); }
+
+  static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return spu_cmpgt(v1, v2); }
+
+  static bool_simd_type lt(simd_type const& v1, simd_type const& v2)
+  { return spu_cmpgt(v2, v1); }
+
+  static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
+  {
+    bool_simd_type is_lt = spu_cmpgt(v2, v1);
+    return spu_nand(is_lt, is_lt);
+  }
+
+  static bool_simd_type le(simd_type const& v1, simd_type const& v2)
+  { return ge(v2, v1); }
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+
+
+/***********************************************************************
+  Cell/B.E. SPU - vector of signed short
+***********************************************************************/
+
+template <>
+struct Simd_traits<signed short>
+{
+  typedef signed short            value_type;
+  typedef __vector signed short   simd_type;
+  typedef __vector unsigned char  perm_simd_type;
+  typedef __vector unsigned short bool_simd_type;
+  typedef __vector signed char    pack_simd_type;
+  typedef __vector unsigned short count_simd_type;
+   
+  static int const  vec_size  = 8;
+  static bool const is_accel  = true;
+  static bool const has_perm  = true;
+  static bool const has_div   = false;
+  static int  const alignment = 16;
+
+  static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  {
+    return VSIP_IMPL_SPU_LITERAL(simd_type, 0, 0, 0, 0,  0, 0, 0, 0);
+  }
+
+  static simd_type load(value_type const* addr)
+  { return *((simd_type*)addr); }
+
+  static simd_type load_unaligned(value_type const* addr)
+  {
+    // Language Extentions for CBEA, section 1.8
+    simd_type x0 = *((simd_type*)addr);
+    simd_type x1 = *((simd_type*)addr + 1);
+    unsigned int shift = (unsigned int)(ptr) & 15;
+    return spu_or(spu_slqwbyte(x0, shift),
+		  spu_rlmaskqwbyte(x1, (signed)(shift - 16)));
+  }
+
+  static perm_simd_type shift_for_addr(value_type const* addr)
+  { 
+    typedef __vector unsigned short us_simd_type;
+    return ((perm_simd_type)spu_add(
+	      (us_simd_type)(spu_splats((unsigned char)(((int)(addr)) & 0xF))),
+	      ((us_simd_type){0x0001, 0x0203, 0x0405, 0x0607,
+		              0x0809, 0x0A0B, 0x0C0D, 0x0E0F})));
+  }
+
+  static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
+  { return spu_shuffle(x0, x1, spu_and(c, 0x1F)); }
+
+  static simd_type load_scalar(value_type value)
+  { return si_from_short(value); }
+
+  static simd_type load_scalar_all(value_type value)
+  { return spu_splats(value); }
+
+  static simd_type load_values(value_type v0, value_type v1,
+			       value_type v2, value_type v3,
+			       value_type v4, value_type v5,
+			       value_type v6, value_type v7)
+  { return VSIP_IMPL_SPU_LITERAL(simd_type, v0, v1, v2, v3, v4, v5, v6, v7); }
+
+  static void store(value_type* addr, simd_type const& vec)
+  { *((simd_type*)addr) = vec; }
+
+  static void extract_all(simd_type const& v,
+			  value_type& v0, value_type& v1,
+			  value_type& v2, value_type& v3,
+			  value_type& v4, value_type& v5,
+			  value_type& v6, value_type& v7)
+  {
+    v0 = spu_extract(v, 0);
+    v1 = spu_extract(v, 1);
+    v2 = spu_extract(v, 2);
+    v3 = spu_extract(v, 3);
+    v4 = spu_extract(v, 4);
+    v5 = spu_extract(v, 5);
+    v6 = spu_extract(v, 6);
+    v7 = spu_extract(v, 7);
+  }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return spu_add(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return spu_sub(v1, v2); }
+
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return spu_and(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return spu_or(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return spu_xor(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return spu_nor(v1, v1); }
+
+  static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return spu_cmpgt(v1, v2); }
+
+  static bool_simd_type lt(simd_type const& v1, simd_type const& v2)
+  { return spu_cmpgt(v2, v1); }
+
+  static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
+  {
+    bool_simd_type is_lt = spu_cmpgt(v2, v1);
+    return spu_nand(is_lt, is_lt);
+  }
+
+  static bool_simd_type le(simd_type const& v1, simd_type const& v2)
+  { return ge(v2, v1); }
+
+  static pack_simd_type pack(simd_type const& v1, simd_type const& v2)
+  { // return vec_pack(v1, v2);
+    static __vector unsigned char shuf = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    1,  3,  5,  7,  9, 11, 13, 15,
+			   17, 19, 21, 23, 25, 27, 29, 31);
+    return (pack_simd_type)spu_shuffle(v1, v2, shuf);
+  }
+
+  static simd_type shiftl(simd_type const& v1, count_simd_type const& v2)
+  { return spu_sl(v1, v2); }
+
+  template <int shift>
+  static simd_type shiftr(simd_type const& v1)
+  { return spu_rlmask(v1, -shift); }
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+
+
+/***********************************************************************
+  Cell/B.E. SPU - vector of unsigned short
+***********************************************************************/
+
+template <>
+struct Simd_traits<unsigned short>
+{
+  typedef unsigned short          value_type;
+  typedef __vector unsigned short simd_type;
+  typedef __vector unsigned char  perm_simd_type;
+  typedef __vector unsigned short bool_simd_type;
+  typedef __vector unsigned char  pack_simd_type;
+   
+  static int const  vec_size  = 8;
+  static bool const is_accel  = true;
+  static bool const has_perm  = true;
+  static bool const has_div   = false;
+  static int  const alignment = 16;
+
+  static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  {
+    return VSIP_IMPL_SPU_LITERAL(simd_type, 0, 0, 0, 0,  0, 0, 0, 0);
+  }
+
+  static simd_type load(value_type const* addr)
+  { return *((simd_type*)addr); }
+
+  static simd_type load_unaligned(value_type const* addr)
+  {
+    // Language Extentions for CBEA, section 1.8
+    simd_type x0 = *((simd_type*)addr);
+    simd_type x1 = *((simd_type*)addr + 1);
+    unsigned int shift = (unsigned int)(ptr) & 15;
+    return spu_or(spu_slqwbyte(x0, shift),
+		  spu_rlmaskqwbyte(x1, (signed)(shift - 16)));
+  }
+
+  static perm_simd_type shift_for_addr(value_type const* addr)
+  {
+    typedef __vector unsigned short us_simd_type;
+    return ((perm_simd_type)spu_add(
+	      (us_simd_type)(spu_splats((unsigned char)(((int)(addr)) & 0xF))),
+	      ((us_simd_type){0x0001, 0x0203, 0x0405, 0x0607,
+		              0x0809, 0x0A0B, 0x0C0D, 0x0E0F})));
+  }
+
+  static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
+  { return spu_shuffle(x0, x1, spu_and(c, 0x1F)); }
+
+  static simd_type load_scalar(value_type value)
+  { return si_from_ushort(value); }
+
+  static simd_type load_scalar_all(value_type value)
+  { return spu_splats(value); }
+
+
+  static simd_type load_values(value_type v0, value_type v1,
+			       value_type v2, value_type v3,
+			       value_type v4, value_type v5,
+			       value_type v6, value_type v7)
+  {
+    return VSIP_IMPL_SPU_LITERAL(simd_type, v0, v1, v2, v3, v4, v5, v6, v7);
+  }
+
+  static void store(value_type* addr, simd_type const& vec)
+  { *((simd_type*)addr) = vec; }
+
+  static value_type extract(simd_type const& v, int pos)
+  { return spu_extract(v, pos); }
+
+  static void extract_all(simd_type const& v,
+			  value_type& v0, value_type& v1,
+			  value_type& v2, value_type& v3,
+			  value_type& v4, value_type& v5,
+			  value_type& v6, value_type& v7)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec = v;
+    v0 = u.val[0];
+    v1 = u.val[1];
+    v2 = u.val[2];
+    v3 = u.val[3];
+    v4 = u.val[4];
+    v5 = u.val[5];
+    v6 = u.val[6];
+    v7 = u.val[7];
+  }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return vec_add(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return vec_sub(v1, v2); }
+
+  static simd_type fma(simd_type const& v1, simd_type const& v2,
+		       simd_type const& v3)
+  { return vec_mladd(v1, v2, v3); }
+
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return vec_and(v1, v2); }
+
+  static simd_type band(bool_simd_type const& v1, simd_type const& v2)
+  { return vec_and(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return vec_or(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return vec_xor(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return vec_nor(v1, v1); }
+
+  static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return vec_cmpgt(v1, v2); }
+
+  static bool_simd_type lt(simd_type const& v1, simd_type const& v2)
+  { return vec_cmplt(v1, v2); }
+
+  static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
+  { return vec_cmplt(v2, v1); }
+
+  static bool_simd_type le(simd_type const& v1, simd_type const& v2)
+  { return vec_cmpgt(v2, v1); }
+
+#endif
+
+  static pack_simd_type pack(simd_type const& v1, simd_type const& v2)
+  { // return vec_pack(v1, v2);
+    static __vector unsigned char shuf = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    1,  3,  5,  7,  9, 11, 13, 15,
+			   17, 19, 21, 23, 25, 27, 29, 31);
+    return (pack_simd_type)spu_shuffle(v1, v2, shuf);
+  }
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+
+
+/***********************************************************************
+  Cell/B.E. SPU - vector of signed short
+***********************************************************************/
+
+template <>
+struct Simd_traits<signed int>
+{
+  typedef signed int             value_type;
+  typedef __vector signed int    simd_type;
+  typedef __vector unsigned char perm_simd_type;
+  typedef __vector unsigned int  bool_simd_type;
+  typedef __vector signed short  pack_simd_type;
+   
+  static int const  vec_size  = 4;
+  static bool const is_accel  = true;
+  static bool const has_perm  = true;
+  static bool const has_div   = false;
+  static int  const alignment = 16;
+
+  static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  {
+    return VSIP_IMPL_SPU_LITERAL(simd_type, 0, 0, 0, 0);
+  }
+
+  static simd_type load(value_type const* addr)
+  { return *((simd_type*)addr); }
+
+  static simd_type load_unaligned(value_type const* addr)
+  {
+    // Language Extentions for CBEA, section 1.8
+    simd_type x0 = *((simd_type*)addr);
+    simd_type x1 = *((simd_type*)addr + 1);
+    unsigned int shift = (unsigned int)(ptr) & 15;
+    return spu_or(spu_slqwbyte(x0, shift),
+		  spu_rlmaskqwbyte(x1, (signed)(shift - 16)));
+  }
+
+  static perm_simd_type shift_for_addr(value_type const* addr)
+  {
+    typedef __vector unsigned short us_simd_type;
+    return ((perm_simd_type)spu_add(
+	      (us_simd_type)(spu_splats((unsigned char)(((int)(addr)) & 0xF))),
+	      ((us_simd_type){0x0001, 0x0203, 0x0405, 0x0607,
+		              0x0809, 0x0A0B, 0x0C0D, 0x0E0F})));
+  }
+
+  static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
+  { return spu_shuffle(x0, x1, spu_and(c, 0x1F)); }
+
+  static simd_type load_scalar(value_type value)
+  { return si_from_int(value); }
+
+  static simd_type load_scalar_all(value_type value)
+  { return spu_splats(value); }
+
+  static void store(value_type* addr, simd_type const& vec)
+  { *((simd_type*)addr) = vec; }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return spu_add(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return spu_sub(v1, v2); }
+
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return spu_and(v1, v2); }
+
+  static bool_simd_type band(bool_simd_type const& v1,
+			     bool_simd_type const& v2)
+  { return spu_and(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return spu_or(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return spu_xor(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return spu_nor(v1, v1); }
+
+  static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return spu_cmpgt(v1, v2); }
+
+  static bool_simd_type lt(simd_type const& v1, simd_type const& v2)
+  { return spu_cmpgt(v2, v1); }
+
+  static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
+  {
+    bool_simd_type is_lt = spu_cmpgt(v2, v1);
+    return spu_nand(is_lt, is_lt);
+  }
+
+  static bool_simd_type le(simd_type const& v1, simd_type const& v2)
+  { return ge(v2, v1); }
+
+  static pack_simd_type pack(simd_type const& v1, simd_type const& v2)
+  { // return vec_pack(v1, v2);
+    static __vector unsigned char shuf = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    2,  3,  6,  7, 10, 11, 14, 15,
+			   18, 19, 22, 23, 26, 27, 30, 31);
+    return (pack_simd_type)spu_shuffle(v1, v2, shuf);
+  }
+
+  static pack_simd_type pack_shuffle(simd_type const& v1, simd_type const& v2)
+  {
+    static __vector unsigned char shuf = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+ 			    2,  3, 18, 19,  6,  7, 22, 23,
+			   10, 11, 26, 27, 14, 15, 30, 31);
+    return (pack_simd_type)spu_shuffle(v1, v2, shuf);
+  }
+
+  template <int shift>
+  static simd_type shiftr(simd_type const& v1)
+  { return spu_rlmask(v1, -shift); }
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+
+
+/***********************************************************************
+  Cell/B.E. SPU - vector of unsigned int
+***********************************************************************/
+
+template <>
+struct Simd_traits<unsigned int>
+{
+  typedef unsigned int            value_type;
+  typedef __vector unsigned int   simd_type;
+  typedef __vector unsigned char  perm_simd_type;
+  typedef __vector unsigned int   bool_simd_type;
+  typedef __vector unsigned short pack_simd_type;
+   
+  static int const  vec_size  = 4;
+  static bool const is_accel  = true;
+  static bool const has_perm  = true;
+  static bool const has_div   = false;
+  static int  const alignment = 16;
+
+  static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  {
+    return VSIP_IMPL_SPU_LITERAL(simd_type, 0, 0, 0, 0);
+  }
+
+  static simd_type load(value_type const* addr)
+  { return *((simd_type*)addr); }
+
+  static simd_type load_unaligned(value_type const* addr)
+  {
+    // Language Extentions for CBEA, section 1.8
+    simd_type x0 = *((simd_type*)addr);
+    simd_type x1 = *((simd_type*)addr + 1);
+    unsigned int shift = (unsigned int)(ptr) & 15;
+    return spu_or(spu_slqwbyte(x0, shift),
+		  spu_rlmaskqwbyte(x1, (signed)(shift - 16)));
+  }
+
+  static perm_simd_type shift_for_addr(value_type const* addr)
+  {
+    typedef __vector unsigned short us_simd_type;
+    return ((perm_simd_type)spu_add(
+	      (us_simd_type)(spu_splats((unsigned char)(((int)(addr)) & 0xF))),
+	      ((us_simd_type){0x0001, 0x0203, 0x0405, 0x0607,
+		              0x0809, 0x0A0B, 0x0C0D, 0x0E0F})));
+  }
+
+  static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
+  { return spu_shuffle(x0, x1, spu_and(c, 0x1F)); }
+
+  static simd_type load_scalar(value_type value)
+  { return si_from_uint(value); }
+
+  static simd_type load_scalar_all(value_type value)
+  { return spu_splats(value); }
+
+  static void store(value_type* addr, simd_type const& vec)
+  { *((simd_type*)addr) = vec; }
+
+  static value_type extract(simd_type const& v, int pos)
+  { return spu_extract(v, pos); }
+
+  static void extract_all(simd_type const& v,
+			  value_type& v0, value_type& v1,
+			  value_type& v2, value_type& v3)
+  {
+    v0 = spu_extract(v, 0);
+    v1 = spu_extract(v, 1);
+    v2 = spu_extract(v, 2);
+    v3 = spu_extract(v, 3);
+  }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return spu_add(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return spu_sub(v1, v2); }
+
+  // multiply high half-width (or even half-width elements).
+  static simd_type mulh(simd_type const& v1, simd_type const& v2)
+  { return spu_mule((__vector unsigned short)v1,
+		    (__vector unsigned short)v2); }
+
+  // multiply low half-width (or odd half-width elements).
+  static simd_type mull(simd_type const& v1, simd_type const& v2)
+  { return spu_mulo((__vector unsigned short)v1,
+		    (__vector unsigned short)v2); }
+
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return spu_and(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return spu_or(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return spu_xor(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return spu_nand(v1, v1); }
+
+  static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return spu_cmpgt(v1, v2); }
+
+  static bool_simd_type lt(simd_type const& v1, simd_type const& v2)
+  { return spu_cmpgt(v2, v1); }
+
+  static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
+  {
+    bool_simd_type is_lt = spu_cmpgt(v2, v1);
+    return spu_nand(is_lt, is_lt);
+  }
+
+  static bool_simd_type le(simd_type const& v1, simd_type const& v2)
+  { return ge(v2, v1); }
+
+  static pack_simd_type pack(simd_type const& v1, simd_type const& v2)
+  { // equiv to vec_pack(v1, v2);
+    static __vector unsigned char shuf = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    2,  3,  6,  7, 10, 11, 14, 15,
+			   18, 19, 22, 23, 26, 27, 30, 31);
+    return (pack_simd_type)spu_shuffle(v1, v2, shuf);
+  }
+
+  static __vector float convert_float(simd_type const& v)
+  { return spu_convtf(v, 0); }
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+
+
+/***********************************************************************
+  Cell/B.E. SPU - vector of float
+***********************************************************************/
+
+template <>
+struct Simd_traits<float>
+{
+  typedef float                          value_type;
+  typedef __vector float                 simd_type;
+  typedef __vector unsigned int          uint_simd_type;
+  typedef __vector signed int            sint_simd_type;
+  typedef __vector unsigned char         perm_simd_type;
+  typedef __vector unsigned int          bool_simd_type;
+   
+  static int  const vec_size  = 4;
+  static bool const is_accel  = true;
+  static bool const has_perm  = true;
+  static bool const has_div   = false;
+  static int  const alignment = 16;
+
+  static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  {
+    return VSIP_IMPL_SPU_LITERAL(simd_type, 0.f, 0.f, 0.f, 0.f);
+  }
+
+  static simd_type load(value_type const* addr)
+  { return *((simd_type*)addr); }
+
+  static simd_type load_unaligned(value_type const* addr)
+  {
+    // Language Extentions for CBEA, section 1.8
+    simd_type x0 = *((simd_type*)addr);
+    simd_type x1 = *((simd_type*)addr + 1);
+    unsigned int shift = (unsigned int)(ptr) & 15;
+    return spu_or(spu_slqwbyte(x0, shift),
+		  spu_rlmaskqwbyte(x1, (signed)(shift - 16)));
+  }
+
+  static perm_simd_type shift_for_addr(value_type const* addr)
+  {
+    typedef __vector unsigned short us_simd_type;
+    return ((perm_simd_type)spu_add(
+	      (us_simd_type)(spu_splats((unsigned char)(((int)(addr)) & 0xF))),
+	      ((us_simd_type){0x0001, 0x0203, 0x0405, 0x0607,
+		              0x0809, 0x0A0B, 0x0C0D, 0x0E0F})));
+  }
+
+  static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
+  { return spu_shuffle(x0, x1, spu_and(c, 0x1F)); }
+
+  static simd_type load_scalar(value_type value)
+  { return (simd_type)si_from_float(value); }
+
+  static simd_type load_scalar_all(value_type value)
+  { return spu_splats(value); }
+
+  static simd_type load_values(value_type v0, value_type v1,
+			       value_type v2, value_type v3)
+  {
+    return VSIP_IMPL_SPU_LITERAL(simd_type, v0, v1, v2, v3);
+  }
+
+  static void store(value_type* addr, simd_type const& vec)
+  { *((simd_type*)addr) = vec; }
+
+  static void store_stream(value_type* addr, simd_type const& vec)
+  { *((simd_type*)addr) = vec; }
+
+  static value_type extract(simd_type const& v, int pos)
+  { return spu_extract(v, pos); }
+
+  static void extract_all(simd_type const& v,
+			  value_type& v0, value_type& v1,
+			  value_type& v2, value_type& v3)
+  {
+    v0 = spu_extract(v, 0);
+    v1 = spu_extract(v, 1);
+    v2 = spu_extract(v, 2);
+    v3 = spu_extract(v, 3);
+  }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return spu_add(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return spu_sub(v1, v2); }
+
+  static simd_type mul(simd_type const& v1, simd_type const& v2)
+  { return spu_madd(v1, v2, zero()); }
+
+  static simd_type div_est(simd_type const& v1, simd_type const& v2)
+  { return spu_madd(v1, spu_re(v2), zero()); }
+
+  static simd_type div(simd_type const& v1, simd_type const& v2)
+  { return spu_madd(v1, spu_re(v2), zero()); }
+
+  static simd_type fma(simd_type const& v1, simd_type const& v2,
+		       simd_type const& v3)
+  { return spu_madd(v1, v2, v3); }
+
+  static simd_type recip_est(simd_type const& v1)
+  { return spu_re(v1); }
+
+  static simd_type recip(simd_type const& v1)
+  {
+    simd_type one = VSIP_IMPL_SPU_LITERAL(simd_type, 1.f, 1.f, 1.f, 1.f);
+    simd_type y0  = spu_re(v1);
+    simd_type t   = spu_nmsub(y0, v1, one);
+    simd_type y1  = spu_madd(y0, t, y0);
+    return y1;
+  }
+
+  static simd_type mag(simd_type const& v1)
+  { return ((simd_type)(spu_rlmask(spu_sl((uint_simd_type)(a), 1), -1))); }
+  // { uint_simd_type mask = si_from_uint(0x7fff); return spu_and(mask, v1); }
+
+  static simd_type min(simd_type const& v1, simd_type const& v2)
+  { return spu_sel(v1, v2, spu_cmpgt(v1, v2)); }
+
+  static simd_type max(simd_type const& v1, simd_type const& v2)
+  { return spu_sel(v1, v2, spu_cmpgt(v2, v1)); }
+
+  static simd_type band(bool_simd_type const& v1, simd_type const& v2)
+  { return spu_and((simd_type)v1, v2); }
+
+  static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return spu_cmpgt(v1, v2); }
+
+  static bool_simd_type lt(simd_type const& v1, simd_type const& v2)
+  { return spu_cmpgt(v2, v1); }
+
+  static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
+  {
+    bool_simd_type is_lt = spu_cmpgt(v2, v1);
+    return spu_nand(is_lt, is_lt);
+  }
+
+  static bool_simd_type le(simd_type const& v1, simd_type const& v2)
+  { return ge(v2, v1); }
+
+  static simd_type real_from_interleaved(simd_type const& v1,
+					 simd_type const& v2)
+  {
+    static __vector unsigned char shuf = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			   0,   1,  2,  3,  8,  9, 10, 11,
+			   16, 17, 18, 19, 24, 25, 26, 27);
+    return spu_shuffle(v1, v2, shuf);
+  }
+
+  static simd_type imag_from_interleaved(simd_type const& v1,
+					 simd_type const& v2)
+  {
+    static __vector unsigned char shuf = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    4,  5,  6,  7, 12, 13, 14, 15,
+			   20, 21, 22, 23, 28, 29, 30, 31);
+    return spu_shuffle(v1, v2, shuf);
+  }
+
+  static simd_type interleaved_lo_from_split(simd_type const& real,
+					     simd_type const& imag)
+  { // equiv to vec_mergeh(real, imag);
+    static __vector unsigned char shuf = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    0,  1,  2,  3, 16, 17, 18, 19,
+			    4,  5,  6,  7, 20, 21, 22, 23);
+    return spu_shuffle(real, imag, shuf);
+  }
+
+  static simd_type interleaved_hi_from_split(simd_type const& real,
+					     simd_type const& imag)
+  { // equiv to spu_mergel(real, imag);
+    static __vector unsigned char shuf = 
+      VSIP_IMPL_SPU_LITERAL(__vector unsigned char,
+			    8,  9, 10, 11, 24, 25, 26, 27,
+			   12, 13, 14, 15, 28, 29, 30, 31);
+    return spu_shuffle(real, imag, shuf);
+  }
+
+  static uint_simd_type convert_uint(simd_type const& v)
+  { return spu_convtu(v, 0); }
+
+  template <int shift>
+  static sint_simd_type convert_uint(simd_type const& v)
+  { return spu_convtu(v, shift); }
+
+  static sint_simd_type convert_sint(simd_type const& v)
+  { return spu_convts(v, 0); }
+
+  template <int shift>
+  static sint_simd_type convert_sint(simd_type const& v)
+  { return spu_convts(v, shift); }
+
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+#undef VSIP_IMPL_SPU_LITERAL
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_SIMD_SPU_HPP
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 188740)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -48,7 +48,8 @@
 ifdef VSIP_IMPL_HAVE_CBE_SDK
 src_vsip_cxx_sources += $(srcdir)/src/vsip/opt/cbe/ppu/task_manager.cpp \
                         $(srcdir)/src/vsip/opt/cbe/ppu/fastconv.cpp \
-                        $(srcdir)/src/vsip/opt/cbe/ppu/bindings.cpp
+                        $(srcdir)/src/vsip/opt/cbe/ppu/bindings.cpp \
+                        $(srcdir)/src/vsip/opt/cbe/ppu/pwarp.cpp
 endif
 ifdef VSIP_IMPL_CBE_SDK_FFT
 src_vsip_cxx_sources += $(srcdir)/src/vsip/opt/cbe/ppu/fft.cpp
Index: src/vsip_csl/error_db.hpp
===================================================================
--- src/vsip_csl/error_db.hpp	(revision 188740)
+++ src/vsip_csl/error_db.hpp	(working copy)
@@ -21,6 +21,7 @@
 #include <algorithm>
 
 #include <vsip/math.hpp>
+#include <vsip/core/view_cast.hpp>
 #include <vsip_csl/test.hpp>
 
 
@@ -31,6 +32,32 @@
   Definitions
 ***********************************************************************/
 
+namespace impl
+{
+
+template <typename T>
+struct Error_db_traits
+{
+  typedef T type;
+};
+
+template <> struct Error_db_traits<unsigned char>  { typedef float type; };
+template <> struct Error_db_traits<unsigned short> { typedef float type; };
+template <> struct Error_db_traits<unsigned int>   { typedef float type; };
+template <> struct Error_db_traits<signed char>  { typedef float type; };
+template <> struct Error_db_traits<signed short> { typedef float type; };
+template <> struct Error_db_traits<signed int>   { typedef float type; };
+
+template <typename T>
+struct Error_db_traits<std::complex<T> >
+{
+  typedef std::complex<typename Error_db_traits<T>::type> type;
+};
+
+} // namespace vsip_csl::impl
+
+
+
 // Compute the distance between two views in terms of relative magsq
 // difference in decibels.
 //
@@ -71,23 +98,34 @@
 {
   using vsip::impl::Dim_of_view;
   using vsip::dimension_type;
+  using vsip::impl::view_cast;
+  using vsip_csl::impl::Error_db_traits;
 
+  typedef typename Error_db_traits<T1>::type promote1_type;
+  typedef typename Error_db_traits<T2>::type promote2_type;
+  // typedef typename vsip::Promotion<diff1_type, diff2_type>::type diff_type;
+
   // garbage in, garbage out.
   if (anytrue(is_nan(v1)) || anytrue(is_nan(v2)))
     return 201.0;
 
-  test_assert(Dim_of_view<View1>::dim == Dim_of_view<View2>::dim);
   dimension_type const dim = Dim_of_view<View2>::dim;
 
   vsip::Index<dim> idx;
 
-  double refmax1 = maxval(magsq(v1), idx);
-  double refmax2 = maxval(magsq(v2), idx);
+  typename vsip::impl::View_cast<promote1_type, View1, T1, Block1>::view_type
+    pv1 = view_cast<promote1_type>(v1);
+  typename vsip::impl::View_cast<promote2_type, View2, T2, Block2>::view_type
+    pv2 = view_cast<promote2_type>(v2);
+
+  double refmax1 = maxval(magsq(pv1), idx);
+  double refmax2 = maxval(magsq(pv2), idx);
   double refmax  = std::max(refmax1, refmax2);
-  double maxsum  = maxval(ite(magsq(v1 - v2) < 1.e-20,
-			      -201.0,
-			      10.0 * log10(magsq(v1 - v2)/(2.0*refmax)) ),
-			  idx);
+  double maxsum  = maxval(
+    ite(magsq((pv1 - pv2)) < 1.e-20,
+	-201.0,
+	10.0 * log10(magsq((pv1 - pv2))/(2.0*refmax)) ),
+    idx);
   return maxsum;
 }
 
Index: src/vsip_csl/img/impl/pwarp_common.hpp
===================================================================
--- src/vsip_csl/img/impl/pwarp_common.hpp	(revision 0)
+++ src/vsip_csl/img/impl/pwarp_common.hpp	(revision 0)
@@ -0,0 +1,171 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip_csl/img/impl/pwarp_common.hpp
+    @author  Jules Bergmann
+    @date    2007-11-16
+    @brief   VSIPL++ Library: Common perspective warp routines.
+*/
+
+#ifndef VSIP_CSL_IMG_IMPL_PWARP_COMMON_HPP
+#define VSIP_CSL_IMG_IMPL_PWARP_COMMON_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/core/signal/types.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip_csl
+{
+
+namespace img
+{
+
+enum interpolate_type
+{
+  interp_nearest_neighbor,
+  interp_linear,
+  interp_cubic,
+  interp_super,
+  interp_lanczos
+};
+
+enum transform_dir
+{
+  forward,
+  inverse
+};
+
+
+namespace impl
+{
+
+template <typename             ImplTag,
+	  typename             CoeffT,
+	  typename             T,
+	  interpolate_type     InterpT,
+	  transform_dir        T_dir>
+struct Is_pwarp_impl_avail
+{
+  static bool const value = false;
+};
+
+
+
+template <typename            CoeffT,
+	  typename            T,
+	  interpolate_type    InterpT,
+	  transform_dir       T_dir,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint,
+	  typename            ImplTag>
+class Pwarp_impl;
+
+
+
+// Transforms coordinates with projection matrix.
+
+template <typename T,
+	  typename CoeffT,
+	  typename Block1>
+void
+apply_proj(
+  vsip::const_Matrix<CoeffT, Block1> P,
+  T                                  u,
+  T                                  v,
+  T&                                 x,
+  T&                                 y)
+{
+  T w =  u * P.get(2, 0) + v * P.get(2, 1) + P.get(2,2);
+  x   = (u * P.get(0, 0) + v * P.get(0, 1) + P.get(0,2)) / w;
+  y   = (u * P.get(1, 0) + v * P.get(1, 1) + P.get(1,2)) / w;
+}
+
+
+
+// Partially transform coordinates with projection matrix.
+
+template <typename T,
+	  typename CoeffT,
+	  typename Block1>
+void
+apply_proj_w(
+  vsip::const_Matrix<CoeffT, Block1> P,
+  T                                  u,
+  T                                  v,
+  T&                                 x,
+  T&                                 y,
+  T&                                 w)
+{
+  x = u * P.get(0, 0) + v * P.get(0, 1) + P.get(0,2);
+  y = u * P.get(1, 0) + v * P.get(1, 1) + P.get(1,2);
+  w = u * P.get(2, 0) + v * P.get(2, 1) + P.get(2,2);
+}
+
+
+
+// Invert projection matrix for purposes of perspective warping.
+//
+// Needs further scaling by det(P) to be a true inverse.
+//
+// (Wolberg 1990, Section 3.4.1)
+
+template <typename T,
+	  typename Block1,
+	  typename Block2>
+void
+invert_proj(
+  vsip::const_Matrix<T, Block1> P,
+  vsip::Matrix<T, Block2>       Pi)
+{
+  Pi(0,0) = P(1,1)*P(2,2) - P(2,1)*P(1,2);
+  Pi(0,1) = P(2,1)*P(0,2) - P(0,1)*P(2,2);
+  Pi(0,2) = P(0,1)*P(1,2) - P(1,1)*P(0,2);
+
+  Pi(1,0) = P(2,0)*P(1,2) - P(1,0)*P(2,2);
+  Pi(1,1) = P(0,0)*P(2,2) - P(2,0)*P(0,2);
+  Pi(1,2) = P(1,0)*P(0,2) - P(0,0)*P(1,2);
+
+  Pi(2,0) = P(1,0)*P(2,1) - P(2,0)*P(1,1);
+  Pi(2,1) = P(2,0)*P(0,1) - P(0,0)*P(2,1);
+  Pi(2,2) = P(0,0)*P(1,1) - P(1,0)*P(0,1);
+}
+
+
+
+// Inverse projection (Wolberg 1990, Section 3.4.1)
+
+template <typename T,
+	  typename Block1>
+void
+apply_proj_inv(
+  vsip::Matrix<T, Block1> P,
+  T                       x,
+  T                       y,
+  T&                      u,
+  T&                      v)
+{
+  vsip::Matrix<T> Pi(3, 3);
+
+  invert_proj(P, Pi);
+
+  apply_proj(Pi, x, y, u, v);
+}
+
+} // namespace vsip_csl::img::impl
+} // namespace vsip_csl::img
+} // namespace vsip
+
+#endif // VSIP_CSL_IMG_IMPL_PWARP_COMMON_HPP
Index: src/vsip_csl/img/impl/pwarp_cbe.hpp
===================================================================
--- src/vsip_csl/img/impl/pwarp_cbe.hpp	(revision 0)
+++ src/vsip_csl/img/impl/pwarp_cbe.hpp	(revision 0)
@@ -0,0 +1,357 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip_csl/img/impl/pwarp_cbe.hpp
+    @author  Jules Bergmann
+    @date    2007-11-16
+    @brief   VSIPL++ Library: Cbe perspective warp transform.
+*/
+
+#ifndef VSIP_CSL_IMG_IMPL_PWARP_CBE_HPP
+#define VSIP_CSL_IMG_IMPL_PWARP_CBE_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/core/domain_utils.hpp>
+#include <vsip/core/signal/types.hpp>
+#include <vsip/core/profile.hpp>
+#include <vsip/core/signal/conv_common.hpp>
+#include <vsip/core/extdata_dist.hpp>
+
+#include <vsip/opt/cbe/ppu/pwarp.hpp>
+
+#include <vsip_csl/img/impl/pwarp_common.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip_csl
+{
+
+namespace img
+{
+
+namespace impl
+{
+
+template <transform_dir DirT>
+struct Is_pwarp_impl_avail<vsip::impl::Cbe_sdk_tag,
+			   float, unsigned char, interp_linear, DirT>
+{
+  static bool const value = true;
+};
+
+
+
+template <typename CoeffT,
+	  typename T,
+	  typename Block1,
+	  typename Block2,
+	  typename Block3>
+void
+pwarp_offset(
+  vsip::const_Matrix<CoeffT, Block1> P,
+  vsip::const_Matrix<T, Block2>      in,
+  vsip::index_type                   in_r0,
+  vsip::index_type                   in_c0,
+  vsip::Matrix<T, Block3>            out,
+  vsip::index_type                   out_r0,
+  vsip::index_type                   out_c0)
+{
+  using vsip::index_type;
+  using vsip::length_type;
+  using vsip_csl::img::impl::apply_proj;
+
+  typedef CoeffT AccumT;
+
+  length_type rows = out.size(0);
+  length_type cols = out.size(1);
+
+  for (index_type r=0; r<rows; ++r)
+    for (index_type c=0; c<cols; ++c)
+    {
+      CoeffT x = static_cast<CoeffT>(c + out_c0);
+      CoeffT y = static_cast<CoeffT>(r + out_r0);
+      CoeffT u, v;
+      apply_proj<CoeffT>(P, x, y, u, v);
+
+      u -= in_c0;
+      v -= in_r0;
+
+      if (u >= 0 && u < in.size(1)-1 &&
+	  v >= 0 && v < in.size(0)-1)
+      {
+	index_type u0 = static_cast<index_type>(u);
+	index_type v0 = static_cast<index_type>(v);
+
+	CoeffT u_beta = u - u0;
+	CoeffT v_beta = v - v0;
+
+	T x00 = in(v0,   u0);
+	T x10 = in(v0+1, u0+0);
+	T x01 = in(v0+0, u0+1);
+	T x11 = in(v0+1, u0+1);
+
+	AccumT x0 = (AccumT)((1 - u_beta) * x00 + u_beta * x01);
+	AccumT x1 = (AccumT)((1 - u_beta) * x10 + u_beta * x11);
+
+	AccumT x  = (AccumT)((1 - v_beta) * x0  + v_beta * x1);
+
+	// out(r, c) = in((index_type)v, (index_type)u);
+	out(r, c) = static_cast<T>(x);
+      }
+      else
+      {
+	out(r, c) = 0;
+      }
+      
+    }
+}
+
+
+inline vsip::length_type
+quantize_floor(vsip::length_type x, vsip::length_type quantum)
+{
+  // assert(quantum is power of 2);
+  return x & ~(quantum-1);
+}
+
+inline vsip::length_type
+quantize_ceil(
+  vsip::length_type x,
+  vsip::length_type quantum,
+  vsip::length_type max)
+{
+  // assert(quantum is power of 2);
+  x = (x-1 % quantum == 0) ? x : (x & ~(quantum-1)) + quantum-1;
+  if (x > max) x = max;
+  return x;
+}
+
+
+
+
+template <typename CoeffT,
+	  typename T,
+	  typename Block1,
+	  typename Block2,
+	  typename Block3>
+void
+pwarp_block(
+  vsip::const_Matrix<CoeffT, Block1> P,
+  vsip::const_Matrix<T, Block2>      in,
+  vsip::Matrix<T, Block3>            out)
+{
+  using vsip::length_type;
+  using vsip::index_type;
+  using vsip::Domain;
+  using vsip_csl::img::impl::apply_proj;
+  using std::min;
+  using std::max;
+
+  length_type rows = out.size(0);
+  length_type cols = out.size(1);
+
+  length_type row_chunk_size = 128;
+  length_type col_chunk_size = 128;
+
+  length_type row_quantum = 1;
+  length_type col_quantum = 128/sizeof(T);
+
+  for (index_type r=0; r<rows; r += row_chunk_size)
+  {
+    length_type my_r_size = std::min(row_chunk_size, rows - r);
+    for (index_type c=0; c<cols; c += col_chunk_size)
+    {
+      length_type my_c_size = std::min(col_chunk_size, cols-c);
+
+      CoeffT u00, v00;
+      CoeffT u01, v01;
+      CoeffT u10, v10;
+      CoeffT u11, v11;
+      apply_proj<CoeffT>(P, c+0*my_c_size, r+0*my_r_size, u00, v00);
+      apply_proj<CoeffT>(P, c+0*my_c_size, r+1*my_r_size, u01, v01);
+      apply_proj<CoeffT>(P, c+1*my_c_size, r+0*my_r_size, u10, v10);
+      apply_proj<CoeffT>(P, c+1*my_c_size, r+1*my_r_size, u11, v11);
+
+      CoeffT min_u = max(CoeffT(0), min(min(u00, u01), min(u10, u11)));
+      CoeffT min_v = max(CoeffT(0), min(min(v00, v01), min(v10, v11)));
+      CoeffT max_u = min(CoeffT(in.size(1)-1), max(max(u00, u01),max(u10, u11)));
+      CoeffT max_v = min(CoeffT(in.size(0)-1), max(max(v00, v01),max(v10, v11)));
+
+      index_type in_r0 = quantize_floor((index_type)floorf(min_v), row_quantum);
+      index_type in_c0 = quantize_floor((index_type)floorf(min_u), col_quantum);
+      index_type in_r1 = quantize_ceil((index_type)ceilf(max_v), row_quantum,in.size(0)-1);
+      index_type in_c1 = quantize_ceil((index_type)ceilf(max_u), col_quantum,in.size(1)-1);
+
+      Domain<2> in_dom(Domain<1>(in_r0, 1, in_r1 - in_r0 + 1),
+		       Domain<1>(in_c0, 1, in_c1 - in_c0 + 1));
+
+      length_type out_r0 = r;
+      length_type out_c0 = c;
+      Domain<2> out_dom(Domain<1>(out_r0, 1, my_r_size),
+			Domain<1>(out_c0, 1, my_c_size));
+
+      pwarp_offset(P,
+		   in(in_dom),   in_r0,  in_c0,
+		   out(out_dom), out_r0, out_c0);
+    }
+  }
+}
+
+
+
+
+
+/// Cbe_sdk_tag implementation of Pwarp_impl.
+
+template <typename            CoeffT,
+	  typename            T,
+	  transform_dir       DirT,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint>
+class Pwarp_impl<CoeffT, T, interp_linear, DirT, n_times, a_hint,
+		 vsip::impl::Cbe_sdk_tag>
+{
+  static vsip::dimension_type const dim = 2;
+
+  // Compile-time constants.
+public:
+  static interpolate_type const interp_tv    = interp_linear;
+  static transform_dir    const transform_tv = DirT;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  template <typename Block1>
+  Pwarp_impl(
+    vsip::const_Matrix<CoeffT, Block1> coeff,	// coeffs for dimension 0
+    vsip::Domain<dim> const&           size)
+    VSIP_THROW((std::bad_alloc));
+
+  Pwarp_impl(Pwarp_impl const&) VSIP_NOTHROW;
+  Pwarp_impl& operator=(Pwarp_impl const&) VSIP_NOTHROW;
+  ~Pwarp_impl() VSIP_NOTHROW;
+
+  // Accessors.
+public:
+  vsip::Domain<dim> const& input_size() const VSIP_NOTHROW
+    { return size_; }
+  vsip::Domain<dim> const& output_size() const VSIP_NOTHROW
+    { return size_; }
+//  vsip::support_region_type support() const VSIP_NOTHROW
+//    { return SuppT; }
+
+  float impl_performance(char const *what) const
+  {
+    if (!strcmp(what, "in_ext_cost"))        return pm_in_ext_cost_;
+    else if (!strcmp(what, "out_ext_cost"))  return pm_out_ext_cost_;
+    else if (!strcmp(what, "non-opt-calls")) return pm_non_opt_calls_;
+    else return 0.f;
+  }
+
+  // Implementation functions.
+protected:
+  template <typename Block0,
+	    typename Block1>
+  void
+  filter(vsip::const_Matrix<T, Block0>,
+	 vsip::Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+
+  // Member data.
+private:
+  vsip::Matrix<CoeffT>    P_;
+
+  vsip::Domain<dim> size_;
+
+  int               pm_non_opt_calls_;
+  size_t            pm_in_ext_cost_;
+  size_t            pm_out_ext_cost_;
+};
+
+
+
+/***********************************************************************
+  Utility Definitions
+***********************************************************************/
+
+/// Construct a convolution object.
+
+template <typename            CoeffT,
+	  typename            T,
+	  transform_dir       DirT,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint>
+template <typename Block1>
+Pwarp_impl<CoeffT, T, interp_linear, DirT, n_times, a_hint,
+	   vsip::impl::Cbe_sdk_tag>::
+Pwarp_impl(
+  vsip::const_Matrix<CoeffT, Block1> coeff,
+  vsip::Domain<dim> const&           size)
+VSIP_THROW((std::bad_alloc))
+  : P_    (3, 3),
+    size_ (size),
+    pm_non_opt_calls_ (0)
+{
+  P_ = coeff;
+}
+
+
+
+/// Destroy a generic Convolution_impl object.
+
+template <typename            CoeffT,
+	  typename            T,
+	  transform_dir       DirT,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint>
+Pwarp_impl<CoeffT, T, interp_linear, DirT, n_times, a_hint,
+	   vsip::impl::Cbe_sdk_tag>::
+~Pwarp_impl()
+  VSIP_NOTHROW
+{
+}
+
+
+
+// Perform 2-D separable filter.
+
+template <typename            CoeffT,
+	  typename            T,
+	  transform_dir       DirT,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint>
+template <typename Block1,
+	  typename Block2>
+void
+Pwarp_impl<CoeffT, T, interp_linear, DirT, n_times, a_hint,
+	   vsip::impl::Cbe_sdk_tag>::
+filter(
+  vsip::const_Matrix<T, Block1> in,
+  vsip::Matrix<T,       Block2> out)
+VSIP_NOTHROW
+{
+  if (out.size(1) <= vsip::impl::cbe::pwarp_block_max_col_size)
+    vsip::impl::cbe::pwarp_block(P_, in, out);
+  else
+    pwarp_block(P_, in, out);
+}
+
+} // namespace vsip_csl::img::impl
+} // namespace vsip_csl::img
+} // namespace vsip
+
+#endif // VSIP_CSL_IMG_IMPL_PWARP_CBE_HPP
Index: src/vsip_csl/img/impl/pwarp_gen.hpp
===================================================================
--- src/vsip_csl/img/impl/pwarp_gen.hpp	(revision 0)
+++ src/vsip_csl/img/impl/pwarp_gen.hpp	(revision 0)
@@ -0,0 +1,259 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip_csl/img/impl/pwarp_gen.hpp
+    @author  Jules Bergmann
+    @date    2007-11-16
+    @brief   VSIPL++ Library: Generic perspective warp transform.
+*/
+
+#ifndef VSIP_CSL_IMG_IMPL_PWARP_GEN_HPP
+#define VSIP_CSL_IMG_IMPL_PWARP_GEN_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/core/domain_utils.hpp>
+#include <vsip/core/signal/types.hpp>
+#include <vsip/core/profile.hpp>
+#include <vsip/core/signal/conv_common.hpp>
+#include <vsip/core/extdata_dist.hpp>
+
+#include <vsip_csl/img/impl/pwarp_common.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip_csl
+{
+
+namespace img
+{
+
+namespace impl
+{
+
+template <typename      CoeffT,
+	  typename      T,
+	  transform_dir T_dir>
+struct Is_pwarp_impl_avail<vsip::impl::Generic_tag,
+			   CoeffT, T, interp_linear, T_dir>
+{
+  static bool const value = true;
+};
+
+
+
+/// Generic implementation of Pwarp_impl.
+
+template <typename            CoeffT,
+	  typename            T,
+	  transform_dir       DirT,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint>
+class Pwarp_impl<CoeffT, T, interp_linear, DirT, n_times, a_hint,
+		 vsip::impl::Generic_tag>
+{
+  static vsip::dimension_type const dim = 2;
+
+  // Compile-time constants.
+public:
+  static interpolate_type const interp_tv    = interp_linear;
+  static transform_dir    const transform_tv = DirT;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  template <typename Block1>
+  Pwarp_impl(
+    vsip::const_Matrix<CoeffT, Block1> coeff,	// coeffs for dimension 0
+    vsip::Domain<dim> const&           size)
+    VSIP_THROW((std::bad_alloc));
+
+  Pwarp_impl(Pwarp_impl const&) VSIP_NOTHROW;
+  Pwarp_impl& operator=(Pwarp_impl const&) VSIP_NOTHROW;
+  ~Pwarp_impl() VSIP_NOTHROW;
+
+  // Accessors.
+public:
+  vsip::Domain<dim> const& input_size() const VSIP_NOTHROW
+    { return size_; }
+  vsip::Domain<dim> const& output_size() const VSIP_NOTHROW
+    { return size_; }
+//  vsip::support_region_type support() const VSIP_NOTHROW
+//    { return SuppT; }
+
+  float impl_performance(char const *what) const
+  {
+    if (!strcmp(what, "in_ext_cost"))        return pm_in_ext_cost_;
+    else if (!strcmp(what, "out_ext_cost"))  return pm_out_ext_cost_;
+    else if (!strcmp(what, "non-opt-calls")) return pm_non_opt_calls_;
+    else return 0.f;
+  }
+
+  // Implementation functions.
+protected:
+  template <typename Block0,
+	    typename Block1>
+  void
+  filter(vsip::const_Matrix<T, Block0>,
+	 vsip::Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+
+  // Member data.
+private:
+  vsip::Matrix<CoeffT>    P_;
+
+  vsip::Domain<dim> size_;
+
+  int               pm_non_opt_calls_;
+  size_t            pm_in_ext_cost_;
+  size_t            pm_out_ext_cost_;
+};
+
+
+
+/***********************************************************************
+  Member Definitions
+***********************************************************************/
+
+/// Construct a convolution object.
+
+template <typename            CoeffT,
+	  typename            T,
+	  transform_dir       DirT,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint>
+template <typename Block1>
+Pwarp_impl<CoeffT, T, interp_linear, DirT, n_times, a_hint, vsip::impl::Generic_tag>::
+Pwarp_impl(
+  vsip::const_Matrix<CoeffT, Block1> coeff,
+  vsip::Domain<dim> const&           size)
+VSIP_THROW((std::bad_alloc))
+  : P_    (3, 3),
+    size_ (size),
+    pm_non_opt_calls_ (0)
+{
+  P_ = coeff;
+}
+
+
+
+/// Destroy a generic Convolution_impl object.
+
+template <typename            CoeffT,
+	  typename            T,
+	  transform_dir       DirT,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint>
+Pwarp_impl<CoeffT, T, interp_linear, DirT, n_times, a_hint, vsip::impl::Generic_tag>::
+~Pwarp_impl()
+  VSIP_NOTHROW
+{
+}
+
+
+
+// Perform 2-D separable filter.
+
+template <typename            CoeffT,
+	  typename            T,
+	  transform_dir       DirT,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint>
+template <typename Block1,
+	  typename Block2>
+void
+Pwarp_impl<CoeffT, T, interp_linear, DirT, n_times, a_hint, vsip::impl::Generic_tag>::
+filter(
+  vsip::const_Matrix<T, Block1> in,
+  vsip::Matrix<T,       Block2> out)
+VSIP_NOTHROW
+{
+  using vsip::index_type;
+  using vsip::length_type;
+  using vsip::stride_type;
+
+  typedef CoeffT AccumT;
+
+  CoeffT      v_clip  = in.size(0) - 1;
+  CoeffT      u_clip  = in.size(1) - 1;
+  length_type rows    = out.size(0);
+  length_type cols    = out.size(1);
+
+  CoeffT u_0, v_0, w_0;
+  CoeffT u_1, v_1, w_1;
+  apply_proj_w<CoeffT>(P_, 0.,     0., u_0, v_0, w_0);
+  apply_proj_w<CoeffT>(P_, cols-1, 0., u_1, v_1, w_1);
+  CoeffT u_delta = (u_1 - u_0) / (cols-1);
+  CoeffT v_delta = (v_1 - v_0) / (cols-1);
+  CoeffT w_delta = (w_1 - w_0) / (cols-1);
+
+  vsip::impl::Ext_data<Block1> in_ext(in.block());
+  vsip::impl::Ext_data<Block2> out_ext(out.block());
+
+  T* p_in  = in_ext.data();
+  T* p_out = out_ext.data();
+  stride_type in_stride_0            = in_ext.stride(0);
+  stride_type out_stride_0_remainder = out_ext.stride(0) - cols;
+
+  for (index_type r=0; r<rows; ++r)
+  {
+    CoeffT y = static_cast<CoeffT>(r);
+    
+    CoeffT u_base, v_base, w_base;
+    apply_proj_w<CoeffT>(P_, 0., y, u_base, v_base, w_base);
+    
+    for (index_type c=0; c<cols; ++c)
+    {
+      CoeffT w =  w_base + c*w_delta;
+      CoeffT u = (u_base + c*u_delta) / w;
+      CoeffT v = (v_base + c*v_delta) / w;
+      
+      if (u >= 0 && u < u_clip && v >= 0 && v < v_clip)
+      {
+	index_type u0 = static_cast<index_type>(u);
+	index_type v0 = static_cast<index_type>(v);
+	
+	CoeffT u_beta = u - u0;
+	CoeffT v_beta = v - v0;
+	
+	T* p = p_in + v0*in_stride_0 + u0;
+	
+	T z00 = *p;                     // in.get(v0,   u0);
+	T z10 = *(p + in_stride_0);     // in.get(v0+1, u0+0);
+	T z01 = *(p               + 1); // in.get(v0+0, u0+1);
+	T z11 = *(p + in_stride_0 + 1); // in.get(v0+1, u0+1);
+	
+	AccumT z0 = (AccumT)((1 - u_beta) * z00 + u_beta * z01);
+	AccumT z1 = (AccumT)((1 - u_beta) * z10 + u_beta * z11);
+	
+	AccumT z  = (AccumT)((1 - v_beta) * z0  + v_beta * z1);
+	
+	*p_out++ =  static_cast<T>(z);
+      }
+      else
+      {
+	*p_out++ = 0;
+      }
+    }
+    p_out += out_stride_0_remainder;
+  }
+}
+
+} // namespace vsip_csl::img::impl
+} // namespace vsip_csl::img
+} // namespace vsip
+
+#endif // VSIP_CSL_IMG_IMPL_PWARP_GEN_HPP
Index: src/vsip_csl/img/impl/pwarp_simd.hpp
===================================================================
--- src/vsip_csl/img/impl/pwarp_simd.hpp	(revision 0)
+++ src/vsip_csl/img/impl/pwarp_simd.hpp	(revision 0)
@@ -0,0 +1,820 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip_csl/img/impl/pwarp_simd.hpp
+    @author  Jules Bergmann
+    @date    2007-11-16
+    @brief   VSIPL++ Library: SIMD perspective warp transform.
+*/
+
+#ifndef VSIP_CSL_IMG_IMPL_PWARP_SIMD_HPP
+#define VSIP_CSL_IMG_IMPL_PWARP_SIMD_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/core/domain_utils.hpp>
+#include <vsip/core/signal/types.hpp>
+#include <vsip/core/profile.hpp>
+#include <vsip/core/signal/conv_common.hpp>
+#include <vsip/core/extdata_dist.hpp>
+
+#include <vsip_csl/img/impl/pwarp_common.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip_csl
+{
+
+namespace img
+{
+
+namespace impl
+{
+
+template <typename CoeffT,
+	  typename T>
+struct Pwarp_impl_simd
+{
+  static bool const is_avail = false;
+};
+
+#ifdef VSIP_IMPL_SIMD_ALTIVEC
+template <>
+struct Pwarp_impl_simd<float, float>
+{
+  static bool const is_avail = true;
+
+  typedef float T;
+  typedef float CoeffT;
+
+  template <typename Block1,
+	    typename Block2,
+	    typename Block3>
+  static void
+  exec(
+    vsip::const_Matrix<CoeffT, Block1> P,
+    vsip::const_Matrix<T, Block2>      in,
+    vsip::Matrix<T, Block3>            out)
+  {
+  using vsip::index_type;
+  using vsip::length_type;
+  using vsip::stride_type;
+
+  typedef CoeffT AccumT;
+
+  typedef vsip::impl::simd::Simd_traits<CoeffT> simd;
+  typedef typename simd::simd_type              simd_t;
+  typedef typename simd::bool_simd_type         bool_simd_t;
+
+  typedef vsip::impl::simd::Simd_traits<unsigned int> ui_simd;
+  typedef typename ui_simd::simd_type                 ui_simd_t;
+
+  CoeffT      v_clip  = in.size(0) - 1;
+  CoeffT      u_clip  = in.size(1) - 1;
+  length_type rows    = out.size(0);
+  length_type cols    = out.size(1);
+
+  CoeffT u_0, v_0, w_0;
+  CoeffT u_1, v_1, w_1;
+  apply_proj_w<CoeffT>(P, 0.,     0., u_0, v_0, w_0);
+  apply_proj_w<CoeffT>(P, cols-1, 0., u_1, v_1, w_1);
+  CoeffT u_delta = (u_1 - u_0) / (cols-1);
+  CoeffT v_delta = (v_1 - v_0) / (cols-1);
+  CoeffT w_delta = (w_1 - w_0) / (cols-1);
+
+  simd_t vec_u_delta = simd::load_scalar_all(4*u_delta);
+  simd_t vec_v_delta = simd::load_scalar_all(4*v_delta);
+  simd_t vec_w_delta = simd::load_scalar_all(4*w_delta);
+  simd_t vec_0       = simd::load_scalar_all(T(0));
+  simd_t vec_1       = simd::load_scalar_all(T(1));
+  simd_t vec_u_clip  = simd::load_scalar_all(u_clip);
+  simd_t vec_v_clip  = simd::load_scalar_all(v_clip);
+
+  simd_t vec_u_delta_ramp = simd::load_values(0*u_delta,
+					      1*u_delta,
+					      2*u_delta,
+					      3*u_delta);
+  simd_t vec_v_delta_ramp = simd::load_values(0*v_delta,
+					      1*v_delta,
+					      2*v_delta,
+					      3*v_delta);
+  simd_t vec_w_delta_ramp = simd::load_values(0*w_delta,
+					      1*w_delta,
+					      2*w_delta,
+					      3*w_delta);
+
+  vsip::impl::Ext_data<Block2> in_ext(in.block());
+  vsip::impl::Ext_data<Block3> out_ext(out.block());
+
+  T* p_in  = in_ext.data();
+  T* p_out = out_ext.data();
+  stride_type in_stride_0            = in_ext.stride(0);
+  stride_type out_stride_0_remainder = out_ext.stride(0) - cols;
+
+  ui_simd_t vec_in_stride_0 = ui_simd::load_scalar_all(in_stride_0);
+
+  for (index_type r=0; r<rows; ++r)
+  {
+    CoeffT y = static_cast<CoeffT>(r);
+
+    CoeffT u_base, v_base, w_base;
+    apply_proj_w<CoeffT>(P, 0., y, u_base, v_base, w_base);
+
+    simd_t vec_u_base;
+    simd_t vec_v_base;
+    simd_t vec_w_base;
+
+    vec_u_base = simd::add(simd::load_scalar_all(u_base), vec_u_delta_ramp);
+    vec_v_base = simd::add(simd::load_scalar_all(v_base), vec_v_delta_ramp);
+    vec_w_base = simd::add(simd::load_scalar_all(w_base), vec_w_delta_ramp);
+
+    for (index_type c=0; c<cols; c+=4)
+    {
+      simd_t vec_w_re = simd::recip(vec_w_base);
+      simd_t vec_u = simd::mul(vec_u_base, vec_w_re);
+      simd_t vec_v = simd::mul(vec_v_base, vec_w_re);
+
+      bool_simd_t vec_u_ge0 = simd::ge(vec_u, vec_0);
+      bool_simd_t vec_v_ge0 = simd::ge(vec_v, vec_0);
+      bool_simd_t vec_u_ltc = simd::lt(vec_u, vec_u_clip);
+      bool_simd_t vec_v_ltc = simd::lt(vec_v, vec_v_clip);
+
+      bool_simd_t vec_u_good = ui_simd::band(vec_u_ge0, vec_u_ltc);
+      bool_simd_t vec_v_good = ui_simd::band(vec_v_ge0, vec_v_ltc);
+      bool_simd_t vec_good   = ui_simd::band(vec_u_good, vec_v_good);
+
+      // Clear u/v if out of bounds.
+      vec_u = simd::band(vec_good, vec_u);
+      vec_v = simd::band(vec_good, vec_v);
+
+      ui_simd_t vec_u0 = simd::convert_uint(vec_u);
+      ui_simd_t vec_v0 = simd::convert_uint(vec_v);
+
+      simd_t vec_u0_f = ui_simd::convert_float(vec_u0);
+      simd_t vec_v0_f = ui_simd::convert_float(vec_v0);
+
+      simd_t vec_u_beta = simd::sub(vec_u, vec_u0_f);
+      simd_t vec_v_beta = simd::sub(vec_v, vec_v0_f);
+      simd_t vec_u_1_beta = simd::sub(vec_1, vec_u_beta);
+      simd_t vec_v_1_beta = simd::sub(vec_1, vec_v_beta);
+
+      ui_simd_t vec_offset = ui_simd::add(
+	ui_simd::mull(vec_v0, vec_in_stride_0), vec_u0);
+
+      unsigned int off_0, off_1, off_2, off_3;
+
+      ui_simd::extract_all(vec_offset, off_0, off_1, off_2, off_3);
+      T* p_0 = p_in + off_0;
+      T* p_1 = p_in + off_1;
+      T* p_2 = p_in + off_2;
+      T* p_3 = p_in + off_3;
+
+      T z00_0 =  *p_0;
+      T z10_0 = *(p_0 + in_stride_0);
+      T z01_0 = *(p_0               + 1);
+      T z11_0 = *(p_0 + in_stride_0 + 1);
+      T z00_1 =  *p_1;
+      T z10_1 = *(p_1 + in_stride_0);
+      T z01_1 = *(p_1               + 1);
+      T z11_1 = *(p_1 + in_stride_0 + 1);
+      T z00_2 =  *p_2;
+      T z10_2 = *(p_2 + in_stride_0);
+      T z01_2 = *(p_2               + 1);
+      T z11_2 = *(p_2 + in_stride_0 + 1);
+      T z00_3 =  *p_3;
+      T z10_3 = *(p_3 + in_stride_0);
+      T z01_3 = *(p_3               + 1);
+      T z11_3 = *(p_3 + in_stride_0 + 1);
+
+      simd_t vec_z00 = simd::load_values(z00_0, z00_1, z00_2, z00_3);
+      simd_t vec_z10 = simd::load_values(z10_0, z10_1, z10_2, z10_3);
+      simd_t vec_z01 = simd::load_values(z01_0, z01_1, z01_2, z01_3);
+      simd_t vec_z11 = simd::load_values(z11_0, z11_1, z11_2, z11_3);
+
+      simd_t vec_z0 = simd::fma(vec_u_1_beta, vec_z00,
+				simd::mul(vec_u_beta,   vec_z01));
+      simd_t vec_z1 = simd::fma(vec_u_1_beta, vec_z10,
+				simd::mul(vec_u_beta,   vec_z11));
+
+      simd_t vec_z  = simd::fma(vec_v_1_beta, vec_z0,
+				simd::mul(vec_v_beta,   vec_z1));
+
+      vec_z = simd::band(vec_good, vec_z);
+
+      simd::store(p_out, vec_z);
+      p_out += 4;
+
+      vec_w_base = simd::add(vec_w_base, vec_w_delta);
+      vec_u_base = simd::add(vec_u_base, vec_u_delta);
+      vec_v_base = simd::add(vec_v_base, vec_v_delta);
+    }
+    p_out += out_stride_0_remainder;
+  }
+  }
+};
+#endif
+
+
+
+#ifdef VSIP_IMPL_SIMD_ALTIVEC
+template <>
+struct Pwarp_impl_simd<float, unsigned char>
+{
+  static bool const is_avail = true;
+
+  typedef unsigned char T;
+  typedef float CoeffT;
+
+  template <typename Block1,
+	    typename Block2,
+	    typename Block3>
+  static void
+  exec(
+    vsip::const_Matrix<CoeffT, Block1> P,
+    vsip::const_Matrix<T, Block2>      in,
+    vsip::Matrix<T, Block3>            out)
+  {
+    using vsip::index_type;
+    using vsip::length_type;
+    using vsip::stride_type;
+
+    typedef CoeffT AccumT;
+
+    typedef vsip::impl::simd::Simd_traits<CoeffT> simd;
+    typedef typename simd::simd_type              simd_t;
+    typedef typename simd::bool_simd_type         bool_simd_t;
+
+    typedef vsip::impl::simd::Simd_traits<unsigned int>   ui_simd;
+    typedef typename ui_simd::simd_type                   ui_simd_t;
+    typedef vsip::impl::simd::Simd_traits<signed int>     si_simd;
+    typedef typename si_simd::simd_type                   si_simd_t;
+    typedef vsip::impl::simd::Simd_traits<unsigned short> us_simd;
+    typedef typename us_simd::simd_type                   us_simd_t;
+    typedef vsip::impl::simd::Simd_traits<signed short>   ss_simd;
+    typedef typename ss_simd::simd_type                   ss_simd_t;
+    typedef vsip::impl::simd::Simd_traits<signed char>    sc_simd;
+    typedef typename sc_simd::simd_type                   sc_simd_t;
+    
+    CoeffT      v_clip  = in.size(0) - 1;
+    CoeffT      u_clip  = in.size(1) - 1;
+    length_type rows    = out.size(0);
+    length_type cols    = out.size(1);
+    
+    CoeffT u_0, v_0, w_0;
+    CoeffT u_1, v_1, w_1;
+    apply_proj_w<CoeffT>(P, 0.,     0., u_0, v_0, w_0);
+    apply_proj_w<CoeffT>(P, cols-1, 0., u_1, v_1, w_1);
+    CoeffT u_delta = (u_1 - u_0) / (cols-1);
+    CoeffT v_delta = (v_1 - v_0) / (cols-1);
+    CoeffT w_delta = (w_1 - w_0) / (cols-1);
+    
+    simd_t vec_u_delta = simd::load_scalar_all(4*u_delta);
+    simd_t vec_v_delta = simd::load_scalar_all(4*v_delta);
+    simd_t vec_w_delta = simd::load_scalar_all(4*w_delta);
+    simd_t vec_u_delta_16 = simd::load_scalar_all(16*u_delta);
+    simd_t vec_v_delta_16 = simd::load_scalar_all(16*v_delta);
+    simd_t vec_w_delta_16 = simd::load_scalar_all(16*w_delta);
+    simd_t vec_0       = simd::load_scalar_all(T(0));
+    simd_t vec_1       = simd::load_scalar_all(T(1));
+    simd_t vec_05      = simd::load_scalar_all(0.0);
+    simd_t vec_u_clip  = simd::load_scalar_all(u_clip);
+    simd_t vec_v_clip  = simd::load_scalar_all(v_clip);
+    
+    simd_t vec_u_delta_ramp = simd::load_values(0*u_delta,
+						1*u_delta,
+						2*u_delta,
+						3*u_delta);
+    simd_t vec_v_delta_ramp = simd::load_values(0*v_delta,
+						1*v_delta,
+						2*v_delta,
+						3*v_delta);
+    simd_t vec_w_delta_ramp = simd::load_values(0*w_delta,
+						1*w_delta,
+						2*w_delta,
+						3*w_delta);
+    
+    vsip::impl::Ext_data<Block2> in_ext(in.block());
+    vsip::impl::Ext_data<Block3> out_ext(out.block());
+    
+    T* p_in  = in_ext.data();
+    T* p_out = out_ext.data();
+    stride_type in_stride_0            = in_ext.stride(0);
+    stride_type out_stride_0_remainder = out_ext.stride(0) - cols;
+    
+    ui_simd_t vec_in_stride_0 = ui_simd::load_scalar_all(in_stride_0);
+    
+    ss_simd_t vec_z3_base = ss_simd::load_scalar_all(0x0040);
+    us_simd_t vec_shift_7 = us_simd::load_scalar_all(7);
+    ss_simd_t vec_start = ss_simd::load_scalar_all(0x0000);
+    
+    for (index_type r=0; r<rows; ++r)
+    {
+      CoeffT y = static_cast<CoeffT>(r);
+      
+      CoeffT u_base, v_base, w_base;
+      apply_proj_w<CoeffT>(P, 0., y, u_base, v_base, w_base);
+      
+      simd_t vec_u0_base = simd::add(simd::load_scalar_all(u_base),
+				     vec_u_delta_ramp);
+      simd_t vec_v0_base = simd::add(simd::load_scalar_all(v_base),
+				     vec_v_delta_ramp);
+      simd_t vec_w0_base = simd::add(simd::load_scalar_all(w_base),
+				     vec_w_delta_ramp);
+
+      simd_t vec_w1_base = simd::add(vec_w0_base, vec_w_delta);
+      simd_t vec_u1_base = simd::add(vec_u0_base, vec_u_delta);
+      simd_t vec_v1_base = simd::add(vec_v0_base, vec_v_delta);
+      simd_t vec_w2_base = simd::add(vec_w1_base, vec_w_delta);
+      simd_t vec_u2_base = simd::add(vec_u1_base, vec_u_delta);
+      simd_t vec_v2_base = simd::add(vec_v1_base, vec_v_delta);
+      simd_t vec_w3_base = simd::add(vec_w2_base, vec_w_delta);
+      simd_t vec_u3_base = simd::add(vec_u2_base, vec_u_delta);
+      simd_t vec_v3_base = simd::add(vec_v2_base, vec_v_delta);
+      
+      for (index_type c=0; c<cols; c+=16)
+      {
+	simd_t vec_w0_re = simd::recip(vec_w0_base);
+	simd_t vec_w1_re = simd::recip(vec_w1_base);
+	simd_t vec_w2_re = simd::recip(vec_w2_base);
+	simd_t vec_w3_re = simd::recip(vec_w3_base);
+	
+	simd_t vec_u0    = simd::mul(vec_u0_base, vec_w0_re);
+	simd_t vec_v0    = simd::mul(vec_v0_base, vec_w0_re);
+	
+	simd_t vec_u1    = simd::mul(vec_u1_base, vec_w1_re);
+	simd_t vec_v1    = simd::mul(vec_v1_base, vec_w1_re);
+	
+	simd_t vec_u2    = simd::mul(vec_u2_base, vec_w2_re);
+	simd_t vec_v2    = simd::mul(vec_v2_base, vec_w2_re);
+	
+	simd_t vec_u3    = simd::mul(vec_u3_base, vec_w3_re);
+	simd_t vec_v3    = simd::mul(vec_v3_base, vec_w3_re);
+	
+	vec_w0_base = simd::add(vec_w0_base, vec_w_delta_16);
+	vec_w1_base = simd::add(vec_w1_base, vec_w_delta_16);
+	vec_w2_base = simd::add(vec_w2_base, vec_w_delta_16);
+	vec_w3_base = simd::add(vec_w3_base, vec_w_delta_16);
+	vec_u0_base = simd::add(vec_u0_base, vec_u_delta_16);
+	vec_u1_base = simd::add(vec_u1_base, vec_u_delta_16);
+	vec_u2_base = simd::add(vec_u2_base, vec_u_delta_16);
+	vec_u3_base = simd::add(vec_u3_base, vec_u_delta_16);
+	vec_v0_base = simd::add(vec_v0_base, vec_v_delta_16);
+	vec_v1_base = simd::add(vec_v1_base, vec_v_delta_16);
+	vec_v2_base = simd::add(vec_v2_base, vec_v_delta_16);
+	vec_v3_base = simd::add(vec_v3_base, vec_v_delta_16);
+	
+	bool_simd_t vec_u0_ge0 = simd::ge(vec_u0, vec_0);
+	bool_simd_t vec_u1_ge0 = simd::ge(vec_u1, vec_0);
+	bool_simd_t vec_u2_ge0 = simd::ge(vec_u2, vec_0);
+	bool_simd_t vec_u3_ge0 = simd::ge(vec_u3, vec_0);
+	
+	bool_simd_t vec_v0_ge0 = simd::ge(vec_v0, vec_0);
+	bool_simd_t vec_v1_ge0 = simd::ge(vec_v1, vec_0);
+	bool_simd_t vec_v2_ge0 = simd::ge(vec_v2, vec_0);
+	bool_simd_t vec_v3_ge0 = simd::ge(vec_v3, vec_0);
+	
+	bool_simd_t vec_u0_ltc = simd::lt(vec_u0, vec_u_clip);
+	bool_simd_t vec_u1_ltc = simd::lt(vec_u1, vec_u_clip);
+	bool_simd_t vec_u2_ltc = simd::lt(vec_u2, vec_u_clip);
+	bool_simd_t vec_u3_ltc = simd::lt(vec_u3, vec_u_clip);
+
+	bool_simd_t vec_v0_ltc = simd::lt(vec_v0, vec_v_clip);
+	bool_simd_t vec_v1_ltc = simd::lt(vec_v1, vec_v_clip);
+	bool_simd_t vec_v2_ltc = simd::lt(vec_v2, vec_v_clip);
+	bool_simd_t vec_v3_ltc = simd::lt(vec_v3, vec_v_clip);
+	
+	bool_simd_t vec_u0_good = ui_simd::band(vec_u0_ge0, vec_u0_ltc);
+	bool_simd_t vec_u1_good = ui_simd::band(vec_u1_ge0, vec_u1_ltc);
+	bool_simd_t vec_u2_good = ui_simd::band(vec_u2_ge0, vec_u2_ltc);
+	bool_simd_t vec_u3_good = ui_simd::band(vec_u3_ge0, vec_u3_ltc);
+	bool_simd_t vec_v0_good = ui_simd::band(vec_v0_ge0, vec_v0_ltc);
+	bool_simd_t vec_v1_good = ui_simd::band(vec_v1_ge0, vec_v1_ltc);
+	bool_simd_t vec_v2_good = ui_simd::band(vec_v2_ge0, vec_v2_ltc);
+	bool_simd_t vec_v3_good = ui_simd::band(vec_v3_ge0, vec_v3_ltc);
+	bool_simd_t vec_0_good  = ui_simd::band(vec_u0_good, vec_v0_good);
+	bool_simd_t vec_1_good  = ui_simd::band(vec_u1_good, vec_v1_good);
+	bool_simd_t vec_2_good  = ui_simd::band(vec_u2_good, vec_v2_good);
+	bool_simd_t vec_3_good  = ui_simd::band(vec_u3_good, vec_v3_good);
+	
+#if __PPU__
+	us_simd_t vec_s01_good = vec_pack(vec_0_good, vec_1_good);
+	us_simd_t vec_s23_good = vec_pack(vec_2_good, vec_3_good);
+#else
+	// 071212: ppu-g++ 4.1.1 can't grok this (even though g++ 4.1.1 on
+	// a 970FX can).
+	us_simd_t vec_s01_good = ui_simd::pack(vec_0_good, vec_1_good);
+	us_simd_t vec_s23_good = ui_simd::pack(vec_2_good, vec_3_good);
+#endif
+	sc_simd_t vec_good     = (sc_simd_t)us_simd::pack(vec_s01_good,
+							  vec_s23_good);
+	
+	ui_simd_t vec_u0_int = simd::convert_uint(vec_u0);
+	ui_simd_t vec_u1_int = simd::convert_uint(vec_u1);
+	ui_simd_t vec_u2_int = simd::convert_uint(vec_u2);
+	ui_simd_t vec_u3_int = simd::convert_uint(vec_u3);
+	
+	ui_simd_t vec_v0_int = simd::convert_uint(vec_v0);
+	ui_simd_t vec_v1_int = simd::convert_uint(vec_v1);
+	ui_simd_t vec_v2_int = simd::convert_uint(vec_v2);
+	ui_simd_t vec_v3_int = simd::convert_uint(vec_v3);
+	
+	simd_t vec_u0_f = ui_simd::convert_float(vec_u0_int);
+	simd_t vec_u1_f = ui_simd::convert_float(vec_u1_int);
+	simd_t vec_u2_f = ui_simd::convert_float(vec_u2_int);
+	simd_t vec_u3_f = ui_simd::convert_float(vec_u3_int);
+	simd_t vec_v0_f = ui_simd::convert_float(vec_v0_int);
+	simd_t vec_v1_f = ui_simd::convert_float(vec_v1_int);
+	simd_t vec_v2_f = ui_simd::convert_float(vec_v2_int);
+	simd_t vec_v3_f = ui_simd::convert_float(vec_v3_int);
+	
+	simd_t vec_u0_beta = simd::sub(vec_u0, vec_u0_f);
+	simd_t vec_u1_beta = simd::sub(vec_u1, vec_u1_f);
+	simd_t vec_u2_beta = simd::sub(vec_u2, vec_u2_f);
+	simd_t vec_u3_beta = simd::sub(vec_u3, vec_u3_f);
+	simd_t vec_v0_beta = simd::sub(vec_v0, vec_v0_f);
+	simd_t vec_v1_beta = simd::sub(vec_v1, vec_v1_f);
+	simd_t vec_v2_beta = simd::sub(vec_v2, vec_v2_f);
+	simd_t vec_v3_beta = simd::sub(vec_v3, vec_v3_f);
+	simd_t vec_u0_1_beta = simd::sub(vec_1, vec_u0_beta);
+	simd_t vec_u1_1_beta = simd::sub(vec_1, vec_u1_beta);
+	simd_t vec_u2_1_beta = simd::sub(vec_1, vec_u2_beta);
+	simd_t vec_u3_1_beta = simd::sub(vec_1, vec_u3_beta);
+	simd_t vec_v0_1_beta = simd::sub(vec_1, vec_v0_beta);
+	simd_t vec_v1_1_beta = simd::sub(vec_1, vec_v1_beta);
+	simd_t vec_v2_1_beta = simd::sub(vec_1, vec_v2_beta);
+	simd_t vec_v3_1_beta = simd::sub(vec_1, vec_v3_beta);
+	
+	si_simd_t vec_0_k00= vec_cts(
+	  simd::fma(vec_u0_1_beta, vec_v0_1_beta, vec_05), 15);
+	si_simd_t vec_1_k00= vec_cts(
+	  simd::fma(vec_u1_1_beta, vec_v1_1_beta, vec_05), 15);
+	si_simd_t vec_2_k00= vec_cts(
+	  simd::fma(vec_u2_1_beta, vec_v2_1_beta, vec_05), 15);
+	si_simd_t vec_3_k00= vec_cts(
+	  simd::fma(vec_u3_1_beta, vec_v3_1_beta, vec_05), 15);
+	si_simd_t vec_0_k01= vec_cts(
+	  simd::fma(vec_u0_beta,   vec_v0_1_beta, vec_05), 15);
+	si_simd_t vec_1_k01= vec_cts(
+	  simd::fma(vec_u1_beta,   vec_v1_1_beta, vec_05), 15);
+	si_simd_t vec_2_k01= vec_cts(
+	  simd::fma(vec_u2_beta,   vec_v2_1_beta, vec_05), 15);
+	si_simd_t vec_3_k01= vec_cts(
+	  simd::fma(vec_u3_beta,   vec_v3_1_beta, vec_05), 15);
+	si_simd_t vec_0_k10= vec_cts(
+	  simd::fma(vec_u0_1_beta, vec_v0_beta, vec_05), 15);
+	si_simd_t vec_1_k10= vec_cts(
+	  simd::fma(vec_u1_1_beta, vec_v1_beta, vec_05), 15);
+	si_simd_t vec_2_k10= vec_cts(
+	  simd::fma(vec_u2_1_beta, vec_v2_beta, vec_05), 15);
+	si_simd_t vec_3_k10= vec_cts(
+	  simd::fma(vec_u3_1_beta, vec_v3_beta, vec_05), 15);
+	si_simd_t vec_0_k11= vec_cts(
+	  simd::fma(vec_u0_beta,   vec_v0_beta, vec_05), 15);
+	si_simd_t vec_1_k11= vec_cts(
+	  simd::fma(vec_u1_beta,   vec_v1_beta, vec_05), 15);
+	si_simd_t vec_2_k11= vec_cts(
+	  simd::fma(vec_u2_beta,   vec_v2_beta, vec_05), 15);
+	si_simd_t vec_3_k11= vec_cts(
+	  simd::fma(vec_u3_beta,   vec_v3_beta, vec_05), 15);
+	
+	ss_simd_t vec_01_k00 = vec_pack(vec_0_k00, vec_1_k00);
+	ss_simd_t vec_23_k00 = vec_pack(vec_2_k00, vec_3_k00);
+	ss_simd_t vec_01_k01 = vec_pack(vec_0_k01, vec_1_k01);
+	ss_simd_t vec_23_k01 = vec_pack(vec_2_k01, vec_3_k01);
+	ss_simd_t vec_01_k10 = vec_pack(vec_0_k10, vec_1_k10);
+	ss_simd_t vec_23_k10 = vec_pack(vec_2_k10, vec_3_k10);
+	ss_simd_t vec_01_k11 = vec_pack(vec_0_k11, vec_1_k11);
+	ss_simd_t vec_23_k11 = vec_pack(vec_2_k11, vec_3_k11);
+	
+	ui_simd_t vec_0_offset = ui_simd::add(
+	  ui_simd::mull(vec_v0_int, vec_in_stride_0), vec_u0_int);
+	ui_simd_t vec_1_offset = ui_simd::add(
+	  ui_simd::mull(vec_v1_int, vec_in_stride_0), vec_u1_int);
+	ui_simd_t vec_2_offset = ui_simd::add(
+	  ui_simd::mull(vec_v2_int, vec_in_stride_0), vec_u2_int);
+	ui_simd_t vec_3_offset = ui_simd::add(
+	  ui_simd::mull(vec_v3_int, vec_in_stride_0), vec_u3_int);
+	
+	unsigned int off_00, off_01, off_02, off_03;
+	unsigned int off_10, off_11, off_12, off_13;
+	unsigned int off_20, off_21, off_22, off_23;
+	unsigned int off_30, off_31, off_32, off_33;
+
+	ui_simd::extract_all(vec_0_offset, off_00, off_01, off_02, off_03);
+	ui_simd::extract_all(vec_1_offset, off_10, off_11, off_12, off_13);
+	ui_simd::extract_all(vec_2_offset, off_20, off_21, off_22, off_23);
+	ui_simd::extract_all(vec_3_offset, off_30, off_31, off_32, off_33);
+	
+	T* p_00 = p_in + off_00;
+	T* p_01 = p_in + off_01;
+	T* p_02 = p_in + off_02;
+	T* p_03 = p_in + off_03;
+	T* p_10 = p_in + off_10;
+	T* p_11 = p_in + off_11;
+	T* p_12 = p_in + off_12;
+	T* p_13 = p_in + off_13;
+	T* p_20 = p_in + off_20;
+	T* p_21 = p_in + off_21;
+	T* p_22 = p_in + off_22;
+	T* p_23 = p_in + off_23;
+	T* p_30 = p_in + off_30;
+	T* p_31 = p_in + off_31;
+	T* p_32 = p_in + off_32;
+	T* p_33 = p_in + off_33;
+
+	T z00_00 =  *p_00;
+	T z10_00 = *(p_00 + in_stride_0);
+	T z01_00 = *(p_00               + 1);
+	T z11_00 = *(p_00 + in_stride_0 + 1);
+	T z00_01 =  *p_01;
+	T z10_01 = *(p_01 + in_stride_0);
+	T z01_01 = *(p_01               + 1);
+	T z11_01 = *(p_01 + in_stride_0 + 1);
+	T z00_02 =  *p_02;
+	T z10_02 = *(p_02 + in_stride_0);
+	T z01_02 = *(p_02               + 1);
+	T z11_02 = *(p_02 + in_stride_0 + 1);
+	T z00_03 =  *p_03;
+	T z10_03 = *(p_03 + in_stride_0);
+	T z01_03 = *(p_03               + 1);
+	T z11_03 = *(p_03 + in_stride_0 + 1);
+	
+	T z00_10 =  *p_10;
+	T z10_10 = *(p_10 + in_stride_0);
+	T z01_10 = *(p_10               + 1);
+	T z11_10 = *(p_10 + in_stride_0 + 1);
+	T z00_11 =  *p_11;
+	T z10_11 = *(p_11 + in_stride_0);
+	T z01_11 = *(p_11               + 1);
+	T z11_11 = *(p_11 + in_stride_0 + 1);
+	T z00_12 =  *p_12;
+	T z10_12 = *(p_12 + in_stride_0);
+	T z01_12 = *(p_12               + 1);
+	T z11_12 = *(p_12 + in_stride_0 + 1);
+	T z00_13 =  *p_13;
+	T z10_13 = *(p_13 + in_stride_0);
+	T z01_13 = *(p_13               + 1);
+	T z11_13 = *(p_13 + in_stride_0 + 1);
+
+	T z00_20 =  *p_20;
+	T z10_20 = *(p_20 + in_stride_0);
+	T z01_20 = *(p_20               + 1);
+	T z11_20 = *(p_20 + in_stride_0 + 1);
+	T z00_21 =  *p_21;
+	T z10_21 = *(p_21 + in_stride_0);
+	T z01_21 = *(p_21               + 1);
+	T z11_21 = *(p_21 + in_stride_0 + 1);
+	T z00_22 =  *p_22;
+	T z10_22 = *(p_22 + in_stride_0);
+	T z01_22 = *(p_22               + 1);
+	T z11_22 = *(p_22 + in_stride_0 + 1);
+	T z00_23 =  *p_23;
+	T z10_23 = *(p_23 + in_stride_0);
+	T z01_23 = *(p_23               + 1);
+	T z11_23 = *(p_23 + in_stride_0 + 1);
+	
+	T z00_30 =  *p_30;
+	T z10_30 = *(p_30 + in_stride_0);
+	T z01_30 = *(p_30               + 1);
+	T z11_30 = *(p_30 + in_stride_0 + 1);
+	T z00_31 =  *p_31;
+	T z10_31 = *(p_31 + in_stride_0);
+	T z01_31 = *(p_31               + 1);
+	T z11_31 = *(p_31 + in_stride_0 + 1);
+	T z00_32 =  *p_32;
+	T z10_32 = *(p_32 + in_stride_0);
+	T z01_32 = *(p_32               + 1);
+	T z11_32 = *(p_32 + in_stride_0 + 1);
+	T z00_33 =  *p_33;
+	T z10_33 = *(p_33 + in_stride_0);
+	T z01_33 = *(p_33               + 1);
+	T z11_33 = *(p_33 + in_stride_0 + 1);
+
+	ss_simd_t vec_01_z00 = ss_simd::load_values(
+	  z00_00, z00_01, z00_02, z00_03,
+	  z00_10, z00_11, z00_12, z00_13);
+	ss_simd_t vec_23_z00 = ss_simd::load_values(
+	  z00_20, z00_21, z00_22, z00_23,
+	  z00_30, z00_31, z00_32, z00_33);
+	
+	ss_simd_t vec_01_z10 = ss_simd::load_values(
+	  z10_00, z10_01, z10_02, z10_03,
+	  z10_10, z10_11, z10_12, z10_13);
+	ss_simd_t vec_23_z10 = ss_simd::load_values(
+	  z10_20, z10_21, z10_22, z10_23,
+	  z10_30, z10_31, z10_32, z10_33);
+	
+	ss_simd_t vec_01_z01 = ss_simd::load_values(
+	  z01_00, z01_01, z01_02, z01_03,
+	  z01_10, z01_11, z01_12, z01_13);
+	ss_simd_t vec_23_z01 = ss_simd::load_values(
+	  z01_20, z01_21, z01_22, z01_23,
+	  z01_30, z01_31, z01_32, z01_33);
+
+	ss_simd_t vec_01_z11 = ss_simd::load_values(
+	  z11_00, z11_01, z11_02, z11_03,
+	  z11_10, z11_11, z11_12, z11_13);
+	ss_simd_t vec_23_z11 = ss_simd::load_values(
+	  z11_20, z11_21, z11_22, z11_23,
+	  z11_30, z11_31, z11_32, z11_33);
+	
+	vec_01_z00 = vec_sl(vec_01_z00, vec_shift_7);
+	vec_23_z00 = vec_sl(vec_23_z00, vec_shift_7);
+	vec_01_z10 = vec_sl(vec_01_z10, vec_shift_7);
+	vec_23_z10 = vec_sl(vec_23_z10, vec_shift_7);
+	vec_01_z01 = vec_sl(vec_01_z01, vec_shift_7);
+	vec_23_z01 = vec_sl(vec_23_z01, vec_shift_7);
+	vec_01_z11 = vec_sl(vec_01_z11, vec_shift_7);
+	vec_23_z11 = vec_sl(vec_23_z11, vec_shift_7);
+	
+	ss_simd_t vec_01_z0 = vec_madds(vec_01_k00, vec_01_z00, vec_start);
+	ss_simd_t vec_23_z0 = vec_madds(vec_23_k00, vec_23_z00, vec_start);
+	ss_simd_t vec_01_z1 = vec_madds(vec_01_k01, vec_01_z01, vec_01_z0);
+	ss_simd_t vec_23_z1 = vec_madds(vec_23_k01, vec_23_z01, vec_23_z0);
+	ss_simd_t vec_01_z2 = vec_madds(vec_01_k10, vec_01_z10, vec_01_z1);
+	ss_simd_t vec_23_z2 = vec_madds(vec_23_k10, vec_23_z10, vec_23_z1);
+	ss_simd_t vec_01_z3 = vec_madds(vec_01_k11, vec_01_z11, vec_01_z2);
+	ss_simd_t vec_23_z3 = vec_madds(vec_23_k11, vec_23_z11, vec_23_z2);
+	
+	vec_01_z3 = ss_simd::add(vec_01_z3, vec_z3_base);
+	vec_23_z3 = ss_simd::add(vec_23_z3, vec_z3_base);
+	
+	vec_01_z3 = vec_sr(vec_01_z3, vec_shift_7);
+	vec_23_z3 = vec_sr(vec_23_z3, vec_shift_7);
+	
+	sc_simd_t vec_out = vec_pack(vec_01_z3, vec_23_z3);
+	vec_out = vec_and(vec_good, vec_out);
+	
+	sc_simd::store((signed char*)p_out, vec_out);
+	p_out += 16;
+      }
+      p_out += out_stride_0_remainder;
+    }
+  }
+};
+#endif
+
+
+
+// Trait to define which combinations are SIMD optimized.
+
+template <typename CoeffT,
+	  typename T,
+	  transform_dir T_dir>
+struct Is_pwarp_impl_avail<vsip::impl::Simd_builtin_tag,
+			   CoeffT, T, interp_linear, T_dir>
+{
+  static bool const value = Pwarp_impl_simd<CoeffT, T>::is_avail;
+};
+
+
+/// Simd_builtin_tag implementation of Pwarp_impl.
+
+template <typename            CoeffT,
+	  typename            T,
+	  transform_dir       DirT,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint>
+class Pwarp_impl<CoeffT, T, interp_linear, DirT, n_times, a_hint,
+		 vsip::impl::Simd_builtin_tag>
+{
+  static vsip::dimension_type const dim = 2;
+
+  // Compile-time constants.
+public:
+  static interpolate_type const interp_tv    = interp_linear;
+  static transform_dir    const transform_tv = DirT;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  template <typename Block1>
+  Pwarp_impl(
+    vsip::const_Matrix<CoeffT, Block1> coeff,	// coeffs for dimension 0
+    vsip::Domain<dim> const&           size)
+    VSIP_THROW((std::bad_alloc));
+
+  Pwarp_impl(Pwarp_impl const&) VSIP_NOTHROW;
+  Pwarp_impl& operator=(Pwarp_impl const&) VSIP_NOTHROW;
+  ~Pwarp_impl() VSIP_NOTHROW;
+
+  // Accessors.
+public:
+  vsip::Domain<dim> const& input_size() const VSIP_NOTHROW
+    { return size_; }
+  vsip::Domain<dim> const& output_size() const VSIP_NOTHROW
+    { return size_; }
+//  vsip::support_region_type support() const VSIP_NOTHROW
+//    { return SuppT; }
+
+  float impl_performance(char const *what) const
+  {
+    if (!strcmp(what, "in_ext_cost"))        return pm_in_ext_cost_;
+    else if (!strcmp(what, "out_ext_cost"))  return pm_out_ext_cost_;
+    else if (!strcmp(what, "non-opt-calls")) return pm_non_opt_calls_;
+    else return 0.f;
+  }
+
+  // Implementation functions.
+protected:
+  template <typename Block0,
+	    typename Block1>
+  void
+  filter(vsip::const_Matrix<T, Block0>,
+	 vsip::Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+
+  // Member data.
+private:
+  vsip::Matrix<CoeffT>    P_;
+
+  vsip::Domain<dim> size_;
+
+  int               pm_non_opt_calls_;
+  size_t            pm_in_ext_cost_;
+  size_t            pm_out_ext_cost_;
+};
+
+
+
+/***********************************************************************
+  Utility Definitions
+***********************************************************************/
+
+/// Construct a convolution object.
+
+template <typename            CoeffT,
+	  typename            T,
+	  transform_dir       DirT,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint>
+template <typename Block1>
+Pwarp_impl<CoeffT, T, interp_linear, DirT, n_times, a_hint,
+	   vsip::impl::Simd_builtin_tag>::
+Pwarp_impl(
+  vsip::const_Matrix<CoeffT, Block1> coeff,
+  vsip::Domain<dim> const&           size)
+VSIP_THROW((std::bad_alloc))
+  : P_    (3, 3),
+    size_ (size),
+    pm_non_opt_calls_ (0)
+{
+  P_ = coeff;
+}
+
+
+
+/// Destroy a generic Convolution_impl object.
+
+template <typename            CoeffT,
+	  typename            T,
+	  transform_dir       DirT,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint>
+Pwarp_impl<CoeffT, T, interp_linear, DirT, n_times, a_hint,
+	   vsip::impl::Simd_builtin_tag>::
+~Pwarp_impl()
+  VSIP_NOTHROW
+{
+}
+
+
+
+// Perform 2-D separable filter.
+
+template <typename            CoeffT,
+	  typename            T,
+	  transform_dir       DirT,
+	  unsigned            n_times,
+          vsip::alg_hint_type a_hint>
+template <typename Block1,
+	  typename Block2>
+void
+Pwarp_impl<CoeffT, T, interp_linear, DirT, n_times, a_hint,
+	   vsip::impl::Simd_builtin_tag>::
+filter(
+  vsip::const_Matrix<T, Block1> in,
+  vsip::Matrix<T,       Block2> out)
+VSIP_NOTHROW
+{
+  Pwarp_impl_simd<CoeffT, T>::exec(P_, in, out);
+}
+
+} // namespace vsip_csl::img::impl
+} // namespace vsip_csl::img
+} // namespace vsip
+
+#endif // VSIP_CSL_IMG_IMPL_PWARP_SIMD_HPP
Index: src/vsip_csl/img/perspective_warp.hpp
===================================================================
--- src/vsip_csl/img/perspective_warp.hpp	(revision 0)
+++ src/vsip_csl/img/perspective_warp.hpp	(revision 0)
@@ -0,0 +1,170 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip_csl/img/perspective_warp.hpp
+    @author  Jules Bergmann
+    @date    2007-11-01
+    @brief   VSIPL++ Library: Image-processing perspective warp.
+
+*/
+
+#ifndef VSIP_CSL_IMG_PERSPECTIVE_WARP_HPP
+#define VSIP_CSL_IMG_PERSPECTIVE_WARP_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/matrix.hpp>
+#include <vsip/core/impl_tags.hpp>
+#include <vsip_csl/img/impl/pwarp_common.hpp>
+#include <vsip_csl/img/impl/pwarp_gen.hpp>
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip_csl/img/impl/pwarp_simd.hpp>
+#ifdef VSIP_IMPL_CBE_SDK
+#  include <vsip_csl/img/impl/pwarp_cbe.hpp>
+#endif
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip_csl
+{
+
+namespace img
+{
+
+namespace impl
+{
+
+// Implemtation chooser for perspective warp processing object.
+
+struct Choose_pwarp_impl
+{
+  
+  template <typename         CoeffT,
+	    typename         T,
+	    interpolate_type InterpT,
+	    transform_dir    T_dir>
+  struct choose_impl
+  {
+    typedef vsip::impl::Intel_ipp_tag    Intel_ipp_tag;
+    typedef vsip::impl::Mercury_sal_tag  Mercury_sal_tag;
+    typedef vsip::impl::Simd_builtin_tag Simd_builtin_tag;
+    typedef vsip::impl::Cbe_sdk_tag      Cbe_sdk_tag;
+    typedef vsip::impl::Generic_tag      Generic_tag;
+
+    typedef typename
+    vsip::impl::ITE_Type<
+      Is_pwarp_impl_avail<Intel_ipp_tag, CoeffT, T, InterpT, T_dir>::value,
+		         vsip::impl::As_type<Intel_ipp_tag>, 
+    vsip::impl::ITE_Type<
+        Is_pwarp_impl_avail<Mercury_sal_tag, CoeffT, T, InterpT, T_dir>::value,
+        vsip::impl::As_type<Mercury_sal_tag>, 
+    vsip::impl::ITE_Type<
+        Is_pwarp_impl_avail<Cbe_sdk_tag, CoeffT, T, InterpT, T_dir>::value,
+        vsip::impl::As_type<Cbe_sdk_tag>, 
+    vsip::impl::ITE_Type<
+        Is_pwarp_impl_avail<Simd_builtin_tag, CoeffT, T, InterpT, T_dir>::value,
+        vsip::impl::As_type<Simd_builtin_tag>, 
+        vsip::impl::As_type<Generic_tag> > > > >::type type;
+  };
+};
+
+} // namespace vsip_csl::img::impl
+
+
+
+// Perspective warp image processing object.
+
+template <typename            CoeffT,
+	  typename            T,
+	  interpolate_type    InterpT,
+	  transform_dir       T_dir,
+	  unsigned            N_times = 0,
+	  vsip::alg_hint_type A_hint = vsip::alg_time,
+	  typename            ChooserT = impl::Choose_pwarp_impl>
+class Perspective_warp
+  : public impl::Pwarp_impl<CoeffT, T, InterpT, T_dir, N_times, A_hint,
+           typename impl::Choose_pwarp_impl::template
+                    choose_impl<CoeffT, T, InterpT, T_dir>::type>
+{
+// Compile-time values and types.
+public:
+  typedef typename impl::Choose_pwarp_impl::template
+                    choose_impl<CoeffT, T, InterpT, T_dir>::type
+		impl_tag;
+  typedef impl::Pwarp_impl<CoeffT, T, InterpT, T_dir, N_times, A_hint,
+			   impl_tag>
+		base_type;
+  static vsip::dimension_type const dim = 2;
+
+// Constructors, copies, assignments, and destructor.
+public:
+  template <typename Block1>
+  Perspective_warp(
+    vsip::const_Matrix<CoeffT, Block1> coeff,
+    vsip::Domain<2> const&             size)
+  VSIP_THROW((std::bad_alloc))
+    : base_type(coeff, size)
+    {}
+
+  Perspective_warp(Perspective_warp const&) VSIP_NOTHROW;
+  Perspective_warp& operator=(Perspective_warp const&) VSIP_NOTHROW;
+  ~Perspective_warp() VSIP_NOTHROW {}
+
+// Operator
+public:
+  template <typename Block1,
+            typename Block2>
+  vsip::Matrix<T, Block2>
+  operator()(
+    vsip::const_Matrix<T, Block1> in,
+    vsip::Matrix<T, Block2>       out)
+    VSIP_NOTHROW
+  {
+    filter(in, out);
+    return out;
+  }
+
+// Accessors
+public:
+  vsip::Domain<dim> const& input_size()  const VSIP_NOTHROW;
+  vsip::Domain<dim> const& output_size() const VSIP_NOTHROW;
+};
+
+
+
+// Perspective warp image processing utility function.
+
+template <typename CoeffT,
+	  typename T,
+	  typename Block1,
+	  typename Block2,
+	  typename Block3>
+void
+perspective_warp(
+  vsip::const_Matrix<CoeffT, Block1> P,
+  vsip::const_Matrix<T, Block2>      in,
+  vsip::Matrix<T, Block3>            out)
+{
+  typedef Perspective_warp<CoeffT, T, interp_linear, forward, 1,
+                           vsip::alg_time>
+    pwarp_type;
+
+  pwarp_type pwarp(P, vsip::Domain<2>(in.size(0), in.size(1)));
+  pwarp(in, out);
+  // vsip_csl::img::impl::Pwarp<CoeffT, T>::exec(P, in, out);
+}
+
+} // namespace vsip_csl::img
+
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_IMG_PERSPECTIVE_WARP_HPP
Index: tests/vsip_csl/error_db.cpp
===================================================================
--- tests/vsip_csl/error_db.cpp	(revision 0)
+++ tests/vsip_csl/error_db.cpp	(revision 0)
@@ -0,0 +1,107 @@
+/* Copyright (c) 2007 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/vsip_csl/error_db.cpp
+    @author  Jules Bergmann
+    @date    2007-12-07
+    @brief   VSIPL++ Library: Unit tests for error_db
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#define VERBOSE 0
+#define SAVE_IMAGES 0
+
+#if VERBOSE
+#  include <iostream>
+#endif
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/error_db.hpp>
+
+using namespace vsip;
+using namespace vsip_csl;
+
+
+
+/***********************************************************************
+  Definitions - Utility Functions
+***********************************************************************/
+
+template <typename T>
+void
+test_vector(int what, T max)
+{
+  length_type size = 48;
+
+  Rand<T> r(1);
+
+  Vector<T> v1(size);
+  Vector<T> v2(size);
+
+  double expect;
+  double delta = 1e-5;
+
+  switch(what)
+  {
+  case 0:
+    v1 = r.randu(size);
+    v2 = v1;
+    expect = -201;
+    break;
+  case 1:
+    v1 = 0; v1(0) = max;
+    v2 = 0; v2(0) = max;
+    expect = -201;
+    break;
+  case 2:
+    // These values will overflow magsq() of unsigned char if it is not
+    // cast by error_db.
+    v1 = 0; v1(0) = max;
+    v2 = 0; v2(0) = max-1;
+    expect = -10 * log10(2.0*max*max) + delta;
+    break;
+  }
+
+  double error = error_db(v1, v2);
+
+#if VERBOSE
+  std::cout << "error: " << error << "  expect: " << expect << std::endl;
+#endif
+
+  test_assert(error <= expect);
+}
+
+
+
+template <typename T>
+void
+test_vector_cases(T max)
+{
+  test_vector<float>(0, max);
+  test_vector<float>(1, max);
+  test_vector<float>(2, max);
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_vector_cases<float>         (255);
+  test_vector_cases<int>           (255);
+  test_vector_cases<unsigned int>  (255);
+  test_vector_cases<signed short>  (255);
+  test_vector_cases<unsigned short>(255);
+  test_vector_cases<signed char>   (127);
+  test_vector_cases<unsigned char> (255);
+}
Index: tests/vsip_csl/pwarp.cpp
===================================================================
--- tests/vsip_csl/pwarp.cpp	(revision 0)
+++ tests/vsip_csl/pwarp.cpp	(revision 0)
@@ -0,0 +1,484 @@
+/* Copyright (c) 2007 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/vsip_csl/pwarp.cpp
+    @author  Jules Bergmann
+    @date    2007-11-05
+    @brief   VSIPL++ Library: Unit tests for perspective warping.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#define VERBOSE 1
+#define SAVE_IMAGES 0
+
+#if VERBOSE
+#  include <iostream>
+#endif
+#include <string>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/random.hpp>
+#include <vsip/signal.hpp>
+
+#include <vsip_csl/img/perspective_warp.hpp>
+
+#include <vsip/core/view_cast.hpp>
+#include <vsip_csl/save_view.hpp>
+#include <vsip/opt/diag/eval.hpp>
+
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/ref_pwarp.hpp>
+#include <vsip_csl/error_db.hpp>
+#if VERBOSE
+#  include <vsip_csl/output.hpp>
+#endif
+
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Definitions - Utility Functions
+***********************************************************************/
+
+template <typename T>
+struct Pwarp_traits
+{
+  typedef T diff_type;
+  typedef T print_type;
+};
+
+template <>
+struct Pwarp_traits<unsigned char>
+{
+  typedef int diff_type;
+  typedef int print_type;
+};
+
+template <typename T,
+	  typename Block1,
+	  typename Block2,
+	  typename Block3>
+void
+proj_inv(
+  vsip::Matrix<T, Block1> P,
+  vsip::Vector<T, Block2> xy,
+  vsip::Vector<T, Block3> res)
+{
+  T X = xy.get(0);
+  T Y = xy.get(1);
+
+  T yD = (P.get(1,0) - P.get(2,0)*Y) * (P.get(0,1) - P.get(2,1)*X)
+       - (P.get(1,1) - P.get(2,1)*Y) * (P.get(0,0) - P.get(2,0)*X);
+  T xD = (P.get(0,0) - P.get(2,0)*X);
+
+  if (yD == 0) yD = 1e-8;
+  if (xD == 0) xD = 1e-8;
+
+  T y  = ( (P.get(1,0) - P.get(2,0)*Y)*(X - P.get(0,2))
+         - (P.get(0,0) - P.get(2,0)*X)*(Y - P.get(1,2)) ) / yD;
+  T x  = ( (X - P.get(0,2)) - (P.get(0,1) - P.get(2,1)*X)*y ) / xD;
+
+  res.put(0, x);
+  res.put(1, y);
+}
+
+template <typename T,
+	  typename BlockT>
+void
+expect_proj(
+  Matrix<T, BlockT> P,
+  T                 ref_u,
+  T                 ref_v,
+  T                 ref_x,
+  T                 ref_y)
+{
+  using vsip_csl::img::impl::apply_proj;
+  using vsip_csl::img::impl::invert_proj;
+  using vsip_csl::img::impl::apply_proj_inv;
+
+  Matrix<T> Pi(3, 3);
+  T x, y, u, v;
+
+  apply_proj<T>(P, ref_u, ref_v, x, y);
+  test_assert(equal(x, ref_x));
+  test_assert(equal(y, ref_y));
+
+  invert_proj(P, Pi);
+
+  apply_proj<T>(Pi, x, y, u, v);
+  test_assert(equal(u, ref_u));
+  test_assert(equal(v, ref_v));
+  
+
+  Vector<T> xy(2);
+  Vector<T> chk(2);
+
+  xy(0) = ref_x; xy(1) = ref_y;
+  proj_inv(P, xy, chk);
+
+  test_assert(equal(chk.get(0), ref_u));
+  test_assert(equal(chk.get(1), ref_v));
+
+  T chk_u, chk_v;
+  apply_proj_inv<T>(P, xy.get(0), xy.get(1), chk_u, chk_v);
+  test_assert(equal(chk_u, ref_u));
+  test_assert(equal(chk_v, ref_v));
+}
+
+
+
+template <typename T,
+	  typename BlockT>
+void
+setup_p(
+  Matrix<T, BlockT> P,
+  int               i)
+{
+  switch (i) {
+  case 0:
+    P        = T();
+    P.diag() = T(1);
+
+  case 1:
+    P(0,0) = T(0.999982);    P(0,1) = T(0.000427585); P(0,2) = T(-0.180836);
+    P(1,0) = T(-0.00207906); P(1,1) = T(0.999923);    P(1,2) = T(0.745001);
+    P(2,0) = T(1.01958e-07); P(2,1) = T(8.99655e-08); P(2,2) = T(1);
+    break;
+
+  case 2:
+    P(0,0) = 8.28282751190698e-01; 
+    P(0,1) = 2.26355321374407e-02;
+    P(0,2) = -1.10504985681804e+01;
+
+    P(1,0) = -2.42950546474237e-01;
+    P(1,1) = 8.98035288576380e-01;
+    P(1,2) = 1.05162748265872e+02;
+
+    P(2,0) = -1.38973743578922e-04;
+    P(2,1) = -9.01955477542629e-05;
+    P(2,2) = 1;
+    break;
+  }
+}
+
+
+
+template <typename T>
+void
+test_apply_proj()
+{
+  Matrix<T> P(3, 3);
+
+  setup_p(P, 1);
+
+  expect_proj<T>(P, 0.181157, -0.744682, 0, 0);
+
+
+  setup_p(P, 2);
+
+  expect_proj<T>(P, 1.64202829975142e+01, -1.12660864027683e+02, 0, 0);
+  expect_proj<T>(P, 5.00593422077480e+02, 6.39343844623318e+02, 480-1, 640-1);
+}
+
+
+
+template <typename T,
+	  typename BlockT>
+void
+setup_checker(
+  vsip::Matrix<T, BlockT> img,
+  vsip::length_type       row_size,
+  vsip::length_type       col_size,
+  T                       value)
+{
+  using vsip::length_type;
+  using vsip::index_type;
+
+  length_type rows = img.size(0);
+  length_type cols = img.size(1);
+
+  for (index_type y=0; y<rows; y += row_size)
+  {
+    for (index_type x=0; x<cols; x += col_size)
+    {
+      T v = (((y / row_size) % 2) ^ ((x / col_size) % 2)) ? value : 0;
+      img(Domain<2>(Domain<1>(y, 1, min(row_size, rows-y)),
+		    Domain<1>(x, 1, min(col_size, cols-x)))) = T(v);
+    }
+  }
+}
+
+
+
+template <typename T,
+	  typename BlockT>
+void
+setup_pattern(
+  int                     pattern,
+  vsip::Matrix<T, BlockT> img,
+  vsip::length_type       row_size,
+  vsip::length_type       col_size,
+  T                       value)
+{
+  using vsip::length_type;
+  using vsip::index_type;
+
+  length_type rows = img.size(0);
+  length_type cols = img.size(1);
+
+  switch(pattern)
+  {
+  case 1: // checker
+    for (index_type y=0; y<rows; y += row_size)
+    {
+      for (index_type x=0; x<cols; x += col_size)
+      {
+	T v = (((y / row_size) % 2) ^ ((x / col_size) % 2)) ? value : 0;
+	img(Domain<2>(Domain<1>(y, 1, min(row_size, rows-y)),
+		      Domain<1>(x, 1, min(col_size, cols-x)))) = T(v);
+      }
+    }
+    break;
+  case 2: // rows
+    for (index_type y=0; y<rows; y += row_size)
+    {
+      T v = ((y / row_size) % 2) ? value : 0;
+      img(Domain<2>(Domain<1>(y, 1, min(row_size, rows-y)),
+		    Domain<1>(0, 1, cols))) = T(v);
+    }
+    break;
+  case 3: // cols
+    break;
+  case 4: // checker fade
+    int scale = 2;
+    for (index_type y=0; y<rows; y += row_size)
+    {
+      for (index_type x=0; x<cols; x += col_size)
+      {
+	T v = (((y / row_size) % 2) ^ ((x / col_size) % 2)) ? value : 0;
+	v = (T)(((float)(scale*rows-y) / (scale*rows)) *
+		((float)(scale*cols-x) / (scale*cols)) *
+		v);
+	img(Domain<2>(Domain<1>(y, 1, min(row_size, rows-y)),
+		      Domain<1>(x, 1, min(col_size, cols-x)))) = T(v);
+      }
+    }
+    break;
+  }
+}
+
+
+
+// rawtopgm -bpp 1 <cols> <rows> IN > OUT
+template <typename T,
+	  typename BlockT>
+void
+save_image(std::string outfile, Matrix<T, BlockT> img)
+{
+  using vsip::impl::view_cast;
+  
+  Index<2> idx;
+  Matrix<unsigned char> out(img.size(0), img.size(1));
+  
+  T minv      = 0; // minval(img, idx);
+  T maxv      = maxval(img, idx);
+
+  if (vsip::impl::Type_equal<T, unsigned char>::value)
+    maxv = 255;
+
+  float scale = 255.0 / (maxv - minv ? maxv - minv : 1.f);
+  
+  out = view_cast<unsigned char>(view_cast<float>(img - minv) * scale);
+  
+  vsip_csl::save_view(const_cast<char *>(outfile.c_str()), out);
+}
+
+
+
+template <typename CoeffT,
+	  typename T>
+void
+test_perspective_fun(
+  std::string f_prefix,
+  length_type rows,
+  length_type cols,
+  length_type row_size,
+  length_type col_size)
+{
+  using vsip::impl::view_cast;
+
+  typedef typename Pwarp_traits<T>::print_type print_type;
+  typedef typename Pwarp_traits<T>::diff_type  diff_type;
+
+  Matrix<T> src(rows, cols);
+  Matrix<T> dst(rows, cols);
+  Matrix<T> chk1(rows, cols);
+  Matrix<T> chk2(rows, cols);
+  Matrix<T> diff(rows, cols);
+  Matrix<T> d2(rows, cols);
+  Matrix<CoeffT> P(3, 3);
+
+  setup_checker(src, row_size, col_size, T(255));
+  setup_p(P, 2);
+
+  vsip_csl::img::perspective_warp(P, src, dst);
+  vsip_csl::ref::pwarp            (P, src, chk1);
+  vsip_csl::ref::pwarp_incremental(P, src, chk2);
+
+  float error1 = error_db(dst, chk1);
+  float error2 = error_db(dst, chk2);
+  diff = mag(view_cast<int>(dst) - view_cast<int>(chk2));
+  d2   = ite(dst != chk2, 255, 0);
+
+#if SAVE_IMAGES
+  save_image(f_prefix + "-src.raw", src);
+  save_image(f_prefix + "-dst.raw", dst);
+  save_image(f_prefix + "-diff.raw", diff);
+  save_image(f_prefix + "-d2.raw", d2);
+  save_image(f_prefix + "-chk2.raw", chk2);
+#endif
+
+#if VERBOSE > 0
+  std::cout << f_prefix << " error: " << error1 << ", " << error2 << std::endl;
+#else
+  (void)f_prefix;
+#endif
+
+#if VERBOSE > 1
+  Index<2> i;
+  std::cout << "  dst : " << static_cast<print_type>(minval(dst, i)) << " .. "
+	                  << static_cast<print_type>(maxval(dst, i)) << "\n"
+	    << "  chk1: " << static_cast<print_type>(minval(chk1, i)) << " .. "
+	                  << static_cast<print_type>(maxval(chk1, i)) << "\n"
+	    << "  chk2: " << static_cast<print_type>(minval(chk2, i)) << " .. "
+	                  << static_cast<print_type>(maxval(chk2, i)) << "\n"
+	    << "  diff: " << static_cast<print_type>(minval(diff, i)) << " .. "
+              	          << static_cast<print_type>(maxval(diff, i)) << "\n"
+    ;
+#endif
+  (void)error1;
+  // assert(error1 <= -100); // error1 unusally large on x86 SIMD
+  test_assert(error2 <= -50);
+}
+
+
+
+
+
+template <typename CoeffT,
+	  typename T>
+void
+test_perspective_obj(
+  std::string f_prefix,
+  length_type rows,
+  length_type cols,
+  length_type row_size,
+  length_type col_size)
+{
+  using vsip::Domain;
+  using vsip::impl::view_cast;
+  using vsip_csl::img::Perspective_warp;
+  using vsip_csl::img::interp_linear;
+  using vsip_csl::img::forward;
+
+  typedef typename Pwarp_traits<T>::print_type print_type;
+  typedef typename Pwarp_traits<T>::diff_type  diff_type;
+
+  Matrix<T> src(rows, cols);
+  Matrix<T> dst(rows, cols);
+  Matrix<T> chk1(rows, cols);
+  Matrix<T> chk2(rows, cols);
+  Matrix<T> diff(rows, cols);
+  Matrix<T> d2(rows, cols);
+  Matrix<CoeffT> P(3, 3);
+
+  setup_pattern(4, src, row_size, col_size, T(255));
+  setup_p(P, 2);
+
+  Perspective_warp<CoeffT, T, interp_linear, forward>
+    warp(P, Domain<2>(rows, cols));
+
+  warp(src, dst);
+  vsip_csl::ref::pwarp            (P, src, chk1);
+  vsip_csl::ref::pwarp_incremental(P, src, chk2);
+
+  float error1 = error_db(dst, chk1);
+  float error2 = error_db(dst, chk2);
+  diff = mag(view_cast<diff_type>(dst) - view_cast<diff_type>(chk2));
+  d2   = ite(dst != chk2, 255, 0);
+
+#if SAVE_IMAGES
+  save_image(f_prefix + "-src.raw", src);
+  save_image(f_prefix + "-dst.raw", dst);
+  save_image(f_prefix + "-diff.raw", diff);
+  save_image(f_prefix + "-d2.raw", d2);
+  save_image(f_prefix + "-chk2.raw", chk2);
+#endif
+
+#if VERBOSE > 0
+  using vsip::impl::diag_detail::Dispatch_name;
+  typedef typename Perspective_warp<CoeffT, T, interp_linear, forward>
+    ::impl_tag impl_tag;
+  std::cout << f_prefix
+	    << " (" << Dispatch_name<impl_tag>::name() << ")"
+	    << " error: " << error1 << ", " << error2 << std::endl;
+#else
+  (void)f_prefix;
+#endif
+
+#if VERBOSE > 1
+  Index<2> i;
+  std::cout << "  dst : " << static_cast<print_type>(minval(dst, i)) << " .. "
+	                  << static_cast<print_type>(maxval(dst, i)) << "\n"
+	    << "  chk1: " << static_cast<print_type>(minval(chk1, i)) << " .. "
+	                  << static_cast<print_type>(maxval(chk1, i)) << "\n"
+	    << "  chk2: " << static_cast<print_type>(minval(chk2, i)) << " .. "
+	                  << static_cast<print_type>(maxval(chk2, i)) << "\n"
+	    << "  diff: " << static_cast<print_type>(minval(diff, i)) << " .. "
+              	          << static_cast<print_type>(maxval(diff, i))
+	    << "  " << i[0] << "," << i[1]
+	    << "\n"
+    ;
+#endif
+  (void)error1;
+  test_assert(error2 <= -50);
+}
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_apply_proj<double>();
+
+  test_perspective_fun<double, double>       ("double", 480, 640, 32, 16);
+  test_perspective_fun<double, float>        ("dfloat", 480, 640, 32, 16);
+  test_perspective_fun<float,  float>        ("float", 480, 640, 32, 16);
+  test_perspective_fun<double, unsigned char>("duchar", 480, 640, 32, 16);
+  test_perspective_fun<float,  unsigned char>("uchar", 480, 640, 32, 16);
+
+  test_perspective_obj<double, float>        ("obj-dfloat", 480, 640, 32, 16);
+  test_perspective_obj<double, double>       ("obj-double", 480, 640, 32, 16);
+  test_perspective_obj<float,  float>        ("obj-float", 480, 640, 32, 16);
+  test_perspective_obj<double, unsigned char>("obj-duchar", 480, 640, 32, 16);
+  test_perspective_obj<float,  unsigned char>("obj-uchar", 480, 640, 32, 16);
+
+  test_perspective_fun<double, double>      ("fun-double", 512, 512, 32, 16);
+  test_perspective_fun<double, float>       ("fun-dfloat", 512, 512, 32, 16);
+  test_perspective_fun<float, float>        ("fun-float",  512, 512, 32, 16);
+  test_perspective_fun<float, unsigned char>("fun-uchar",  512, 512, 32, 16);
+
+  test_perspective_obj<double, double>      ("obj-double", 512, 512, 32, 16);
+  test_perspective_obj<double, float>       ("obj-dfloat", 512, 512, 32, 16);
+  test_perspective_obj<float, float>        ("obj-float",  512, 512, 32, 16);
+  test_perspective_obj<float, unsigned char>("obj-uchar",  512, 512, 32, 16);
+}
Index: benchmarks/pwarp.cpp
===================================================================
--- benchmarks/pwarp.cpp	(revision 0)
+++ benchmarks/pwarp.cpp	(revision 0)
@@ -0,0 +1,232 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    benchmarks/pwarp.cpp
+    @author  Jules Bergmann
+    @date    2007-11-08
+    @brief   VSIPL++ Library: Benchmark for Perspective Image Warp.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+#include <vsip/signal.hpp>
+
+#include <vsip_csl/img/perspective_warp.hpp>
+
+#include <vsip/opt/diag/eval.hpp>
+
+#include <vsip_csl/test.hpp>
+#include "loop.hpp"
+
+using namespace vsip;
+using namespace vsip_csl::img;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T,
+	  typename BlockT>
+void
+setup_p(
+  Matrix<T, BlockT> P,
+  int               i)
+{
+  switch (i) {
+  case 0:
+    P        = T();
+    P.diag() = T(1);
+
+  case 1:
+    P(0,0) = T(0.999982);    P(0,1) = T(0.000427585); P(0,2) = T(-0.180836);
+    P(1,0) = T(-0.00207906); P(1,1) = T(0.999923);    P(1,2) = T(0.745001);
+    P(2,0) = T(1.01958e-07); P(2,1) = T(8.99655e-08); P(2,2) = T(1);
+    break;
+
+  case 2:
+    P(0,0) = 8.28282751190698e-01; 
+    P(0,1) = 2.26355321374407e-02;
+    P(0,2) = -1.10504985681804e+01;
+
+    P(1,0) = -2.42950546474237e-01;
+    P(1,1) = 8.98035288576380e-01;
+    P(1,2) = 1.05162748265872e+02;
+
+    P(2,0) = -1.38973743578922e-04;
+    P(2,1) = -9.01955477542629e-05;
+    P(2,2) = 1;
+    break;
+  }
+}
+
+
+
+
+template <typename         CoeffT,
+	  typename         T,
+	  interpolate_type InterpT>
+struct t_pwarp_obj : Benchmark_base
+{
+  char const* what() { return "t_pwarp_obj"; }
+
+  float ops_per_point(length_type)
+  {
+    return rows_;
+  }
+
+  int riob_per_point(length_type) { return -1; }
+  int wiob_per_point(length_type) { return -1; }
+  int mem_per_point(length_type)  { return 2*sizeof(T); }
+
+  void operator()(length_type cols, length_type loop, float& time)
+  {
+    Matrix<CoeffT> P(3, 3);
+    Matrix<T>      in (rows_, cols, T());
+    Matrix<T>      out(rows_, cols);
+
+    setup_p(P, idx_);
+
+    vsip::impl::profile::Timer t1;
+
+    Perspective_warp<CoeffT, T, InterpT, forward>
+      warp(P, Domain<2>(rows_, cols));
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      warp(in, out);
+    t1.stop();
+    
+    time = t1.delta();
+  }
+
+  t_pwarp_obj(length_type rows, int idx)
+    : rows_(rows), idx_(idx)
+  {}
+
+  void diag()
+  {
+    using vsip::impl::diag_detail::Dispatch_name;
+    using vsip_csl::img::impl::Choose_pwarp_impl;
+    typedef typename Choose_pwarp_impl::template
+                    choose_impl<CoeffT, T, InterpT, forward>::type
+		impl_tag;
+    std::cout << "BE: " << Dispatch_name<impl_tag>::name() << std::endl;
+  }
+
+  length_type rows_;
+  int         idx_;
+};
+
+
+
+template <typename CoeffT,
+	  typename T>
+struct t_pwarp_fun : Benchmark_base
+{
+  char const* what() { return "t_pwarp_fun"; }
+
+  float ops_per_point(length_type)
+  {
+    return rows_;
+  }
+
+  int riob_per_point(length_type) { return -1; }
+  int wiob_per_point(length_type) { return -1; }
+  int mem_per_point(length_type)  { return 2*sizeof(T); }
+
+  void operator()(length_type cols, length_type loop, float& time)
+  {
+    Matrix<CoeffT> P(3, 3);
+    Matrix<T>      in (rows_, cols, T());
+    Matrix<T>      out(rows_, cols);
+
+    setup_p(P, idx_);
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      perspective_warp(P, in, out);
+    t1.stop();
+    
+    time = t1.delta();
+  }
+
+  t_pwarp_fun(length_type rows, int idx)
+    : rows_(rows), idx_(idx)
+  {}
+
+  void diag()
+  {
+    std::cout << "perspective_warp function interface\n";
+  }
+
+  length_type rows_;
+  int         idx_;
+};
+
+
+
+void
+defaults(Loop1P& loop)
+{
+  loop.loop_start_ = 1;
+  loop.start_ = 4;
+  loop.stop_  = 13;
+
+  loop.param_["rows"] = "512";
+  loop.param_["pi"]   = "0";
+}
+
+
+
+int
+test(Loop1P& loop, int what)
+{
+  typedef complex<float> cf_type;
+
+  length_type rows = atoi(loop.param_["rows"].c_str());
+  length_type pi   = atoi(loop.param_["pi"].c_str());
+
+  interpolate_type const IL = interp_linear;
+
+  switch (what)
+  {
+  case  1: loop(t_pwarp_obj<float, float, IL> (rows, pi)); break;
+  case  2: loop(t_pwarp_obj<float, unsigned char, IL>(rows, pi)); break;
+
+  case 11: loop(t_pwarp_fun<float, float> (rows, pi)); break;
+  case 12: loop(t_pwarp_fun<float, unsigned char>(rows, pi)); break;
+
+  case  0:
+    std::cout
+      << "pwarp -- Perspective_warp\n"
+      << " Object:\n"
+      << "   -1 -- float\n"
+      << "   -2 -- char\n"
+      << " Funcion:\n"
+      << "  -11 -- float\n"
+      << "  -12 -- char\n"
+      << "\n"
+      << "Parameters:\n"
+      << "   -p:rows ROWS -- set image rows (default 16)\n"
+      ;
+    
+
+  default: return 0;
+  }
+  return 1;
+}
