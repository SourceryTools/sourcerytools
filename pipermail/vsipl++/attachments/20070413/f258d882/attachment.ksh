Index: ChangeLog
===================================================================
--- ChangeLog	(revision 168761)
+++ ChangeLog	(working copy)
@@ -1,3 +1,19 @@
+2007-04-13  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/cbe/ppu/util.hpp: New file, conatins new function
+	  ea_from_ptr, pulls existing functions
+	  is_dma_{size_ok,addr_ok,stride_ok} from bindings.hpp.
+	* src/vsip/opt/cbe/ppu/bindings.hpp: Check if num_spes > 0 at
+	  rt_valid.
+	* src/vsip/opt/cbe/ppu/fft.hpp: Likewise.
+	* src/vsip/opt/cbe/ppu/fft.cpp: Use ea_from_ptr to convert pointer
+	  to EA.
+	* src/vsip/opt/cbe/ppu/fastconv.cpp: Likewise.
+	* src/vsip/opt/cbe/ppu/bindings.cpp: Likewise.  Fix cleanup DMA for
+	  vmul, was not properly counting length of non-cleanup DMA.
+	* tests/regressions/large_vmul.cpp: New file, regression test
+	  for vmul DMA cleanup.
+	
 2007-04-09  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/opt/cbe/ppu/eval_fastconv.hpp: Specified value for new template
@@ -21,6 +37,7 @@
 	* examples/fconv.cpp: Specified template parameter for Fastconv.
 
 2007-04-02  Assem Salama <assem@codesourcery.com>
+	
 	* src/vsip/core/expr/generator_block.hpp: Made Choose_peb of
 	  Generator_expr_block a Peb_remap_tag. Changed apply function to call
 	  apply instead of apply_const.  Removed const from type of 
Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 168761)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -21,8 +21,8 @@
 #include <vsip/core/fft/util.hpp>
 #include <vsip/opt/cbe/fft_params.h>
 #include <vsip/opt/cbe/ppu/fft.hpp>
-#include <vsip/opt/cbe/ppu/bindings.hpp>
 #include <vsip/opt/cbe/ppu/task_manager.hpp>
+#include <vsip/opt/cbe/ppu/util.hpp>
 
 /***********************************************************************
   Declarations
@@ -61,10 +61,9 @@
     fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
     fftp.elements = length;
     fftp.scale = scale;
-    fftp.ea_twiddle_factors = 
-      reinterpret_cast<unsigned long long>(twiddle_factors_.get());
-    fftp.ea_input_buffer    = reinterpret_cast<unsigned long long>(in);
-    fftp.ea_output_buffer   = reinterpret_cast<unsigned long long>(out);
+    fftp.ea_twiddle_factors = ea_from_ptr(twiddle_factors_.get());
+    fftp.ea_input_buffer    = ea_from_ptr(in);
+    fftp.ea_output_buffer   = ea_from_ptr(out);
     fftp.in_blk_stride      = 0;  // not applicable in the single FFT case
     fftp.out_blk_stride     = 0;
 
@@ -105,8 +104,7 @@
     Fft_params fftp;
     fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
     fftp.scale = scale;
-    fftp.ea_twiddle_factors = 
-      reinterpret_cast<unsigned long long>(twiddle_factors_.get());
+    fftp.ea_twiddle_factors = ea_from_ptr(twiddle_factors_.get());
     length_type num_ffts;
     length_type in_stride;
     length_type out_stride;
@@ -124,8 +122,8 @@
       out_stride = out_c_stride;
       fftp.elements = rows;
     }
-    fftp.ea_input_buffer    = reinterpret_cast<unsigned long long>(in);
-    fftp.ea_output_buffer   = reinterpret_cast<unsigned long long>(out);
+    fftp.ea_input_buffer    = ea_from_ptr(in);
+    fftp.ea_output_buffer   = ea_from_ptr(out);
     fftp.in_blk_stride      = in_stride;
     fftp.out_blk_stride     = out_stride;
 
Index: src/vsip/opt/cbe/ppu/bindings.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/bindings.hpp	(revision 168761)
+++ src/vsip/opt/cbe/ppu/bindings.hpp	(working copy)
@@ -32,23 +32,10 @@
 #include <vsip/core/extdata.hpp>
 #include <vsip/core/adjust_layout.hpp>
 #include <vsip/opt/cbe/vmmul_params.h>
+#include <vsip/opt/cbe/ppu/task_manager.hpp>
+#include <vsip/opt/cbe/ppu/util.hpp>
 
 /***********************************************************************
-  Macros
-***********************************************************************/
-
-// DMA starting address alignment (in bytes).
-
-#define VSIP_IMPL_CBE_DMA_ALIGNMENT 16
-
-// Bulk DMA size granularity (in bytes) 
-// (Note that DMAs of fixed size 1, 2, 4, and 8 bytes are also allowed.)
-
-#define VSIP_IMPL_CBE_DMA_GRANULARITY 16
-
-
-
-/***********************************************************************
   Declarations
 ***********************************************************************/
 
@@ -59,49 +46,6 @@
 namespace cbe
 {
 
-// Determine if DMA size (in bytes) is valid for a bulk DMA.
-
-inline bool
-is_dma_size_ok(length_type size_in_bytes)
-{
-  return (size_in_bytes == 1 ||
-	  size_in_bytes == 2 ||
-	  size_in_bytes == 4 ||
-	  size_in_bytes == 8 ||
-	  size_in_bytes % 16 == 0);
-}
-
-
-// Determine if DMA address is properly aligned.
-
-template <typename T>
-inline bool
-is_dma_addr_ok(T const* addr)
-{
-  return ((intptr_t)addr & (VSIP_IMPL_CBE_DMA_ALIGNMENT - 1)) == 0;
-}
-
-
-
-template <typename T>
-inline bool
-is_dma_addr_ok(std::pair<T*, T*> const& addr)
-{
-  return is_dma_addr_ok(addr.first) && is_dma_addr_ok(addr.second);
-}
-
-
-// Determine if stride will cause an unaligned DMA
-
-template <typename T>
-inline bool
-is_dma_stride_ok(stride_type stride)
-{
-  return ((stride * sizeof(T)) & (VSIP_IMPL_CBE_DMA_GRANULARITY - 1)) == 0;
-}
-
-
-
 template <typename T> void vmul(T const* A, T const* B, T* R, length_type len);
 template <typename T> void vmmul(T const* V, T const* M, T* R, 
   stride_type m_stride, stride_type r_stride, length_type length, length_type lines);
@@ -152,12 +96,13 @@
     Ext_data<DstBlock, dst_lp>    ext_dst(dst,       SYNC_OUT);
     Ext_data<LBlock,   lblock_lp> ext_l(src.left(),  SYNC_IN);
     Ext_data<RBlock,   rblock_lp> ext_r(src.right(), SYNC_IN);
-    return (ext_dst.stride(0) == 1 &&
-	    ext_l.stride(0) == 1   &&
-	    ext_r.stride(0) == 1   &&
-	    is_dma_addr_ok(ext_dst.data()) &&
-	    is_dma_addr_ok(ext_l.data())   &&
-	    is_dma_addr_ok(ext_r.data()) );
+    return ext_dst.stride(0) == 1 &&
+	   ext_l.stride(0) == 1   &&
+	   ext_r.stride(0) == 1   &&
+	   is_dma_addr_ok(ext_dst.data()) &&
+	   is_dma_addr_ok(ext_l.data())   &&
+	   is_dma_addr_ok(ext_r.data())   &&
+           Task_manager::instance()->num_spes() > 0;
   }
 };
 
@@ -284,7 +229,8 @@
       cbe::is_dma_addr_ok(ext_m.data()) &&
       cbe::is_dma_stride_ok<dst_type>(ext_dst.stride(SD == row ? 0 : 1)) &&
       cbe::is_dma_stride_ok<m_type>(ext_m.stride(SD == row ? 0 : 1)) &&
-      cbe::is_dma_size_ok(ext_v.size() * sizeof(v_type));
+      cbe::is_dma_size_ok(ext_v.size() * sizeof(v_type)) &&
+      cbe::Task_manager::instance()->num_spes() > 0;
   }
   
   static void exec(DstBlock& dst, SrcBlock const& src)
Index: src/vsip/opt/cbe/ppu/util.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/util.hpp	(revision 0)
+++ src/vsip/opt/cbe/ppu/util.hpp	(revision 0)
@@ -0,0 +1,129 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/ppu/util.hpp
+    @author  Jules Bergmann
+    @date    2007-04-13
+    @brief   VSIPL++ Library: Utilities for the IBM Cell/B.E.
+*/
+
+#ifndef VSIP_OPT_CBE_PPU_UTIL_HPP
+#define VSIP_OPT_CBE_PPU_UTIL_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+
+
+/***********************************************************************
+  Macros
+***********************************************************************/
+
+// DMA starting address alignment (in bytes).
+
+#define VSIP_IMPL_CBE_DMA_ALIGNMENT 16
+
+// Bulk DMA size granularity (in bytes) 
+//
+// DMAs larger than 16 bytes must have a granularity of 16 bytes.
+// Small DMAs of fixed size 1, 2, 4, and 8 bytes are also allowed.
+
+#define VSIP_IMPL_CBE_DMA_GRANULARITY 16
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
+// Determine if DMA size (in bytes) is valid for a bulk DMA.
+
+inline bool
+is_dma_size_ok(length_type size_in_bytes)
+{
+  return (size_in_bytes == 1 ||
+	  size_in_bytes == 2 ||
+	  size_in_bytes == 4 ||
+	  size_in_bytes == 8 ||
+	  size_in_bytes % 16 == 0);
+}
+
+
+// Determine if DMA address is properly aligned.
+
+template <typename T>
+inline bool
+is_dma_addr_ok(T const* addr)
+{
+  return ((intptr_t)addr & (VSIP_IMPL_CBE_DMA_ALIGNMENT - 1)) == 0;
+}
+
+
+
+template <typename T>
+inline bool
+is_dma_addr_ok(std::pair<T*, T*> const& addr)
+{
+  return is_dma_addr_ok(addr.first) && is_dma_addr_ok(addr.second);
+}
+
+
+// Determine if stride will cause an unaligned DMA
+
+template <typename T>
+inline bool
+is_dma_stride_ok(stride_type stride)
+{
+  return ((stride * sizeof(T)) & (VSIP_IMPL_CBE_DMA_GRANULARITY - 1)) == 0;
+}
+
+
+
+
+// Convert a pointer into a 64-bit effective address (EA).
+
+// Note: just casting a 32-bit pointer to an unsigned long long does
+//
+//   unsigned long long ea = reinterpret_cast<unsigned long long>(ptr);
+//
+// does not work.  If the high-order bit of the pointer is set, it will
+// be sign extended into the upper 32-bits of the long long.  Using such
+// an errant EA with mfc_get fails (but curiously it works with ALF's
+// ALF_DT_LIST_ADD_ENTRY).
+
+template <typename T>
+inline
+unsigned long long
+ea_from_ptr(T* ptr)
+{
+  if (sizeof(T*) == sizeof(unsigned long long))
+    reinterpret_cast<unsigned long long>(ptr);
+  else
+  {
+    union
+    {
+      unsigned long      ptr32[2];
+      unsigned long long ptr64;
+    } u;
+    u.ptr32[0] = 0;
+    u.ptr32[1] = reinterpret_cast<unsigned long>(ptr);
+    return u.ptr64;
+  }
+}
+
+} // namespace vsip::impl::cbe
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_CBE_PPU_UTIL_HPP
Index: src/vsip/opt/cbe/ppu/fastconv.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.cpp	(revision 168761)
+++ src/vsip/opt/cbe/ppu/fastconv.cpp	(working copy)
@@ -21,6 +21,7 @@
 #include <vsip/opt/cbe/fconv_params.h>
 #include <vsip/opt/cbe/ppu/fastconv.hpp>
 #include <vsip/opt/cbe/ppu/task_manager.hpp>
+#include <vsip/opt/cbe/ppu/util.hpp>
 extern "C"
 {
 #include <libspe2.h>
@@ -52,11 +53,10 @@
   params.instance_id        = this->instance_id_;
   params.elements           = length;
   params.transform_kernel   = this->transform_kernel_;
-  params.ea_twiddle_factors = reinterpret_cast<unsigned long long>
-                                (this->twiddle_factors_.get());
-  params.ea_kernel          = reinterpret_cast<unsigned long long>(kernel);
-  params.ea_input           = reinterpret_cast<unsigned long long>(in);
-  params.ea_output          = reinterpret_cast<unsigned long long>(out);
+  params.ea_twiddle_factors = ea_from_ptr(this->twiddle_factors_.get());
+  params.ea_kernel          = ea_from_ptr(kernel);
+  params.ea_input           = ea_from_ptr(in);
+  params.ea_output          = ea_from_ptr(out);
   params.kernel_stride      = length;
   params.input_stride       = length;
   params.output_stride      = length;
@@ -120,14 +120,13 @@
   params.instance_id        = this->instance_id_;
   params.elements           = length;
   params.transform_kernel   = this->transform_kernel_;
-  params.ea_twiddle_factors = reinterpret_cast<unsigned long long>
-                                (this->twiddle_factors_.get());
-  params.ea_kernel_re       = reinterpret_cast<unsigned long long>(kernel.first);
-  params.ea_kernel_im       = reinterpret_cast<unsigned long long>(kernel.second);
-  params.ea_input_re        = reinterpret_cast<unsigned long long>(in.first);
-  params.ea_input_im        = reinterpret_cast<unsigned long long>(in.second);
-  params.ea_output_re       = reinterpret_cast<unsigned long long>(out.first);
-  params.ea_output_im       = reinterpret_cast<unsigned long long>(out.second);
+  params.ea_twiddle_factors = ea_from_ptr(this->twiddle_factors_.get());
+  params.ea_kernel_re       = ea_from_ptr(kernel.first);
+  params.ea_kernel_im       = ea_from_ptr(kernel.second);
+  params.ea_input_re        = ea_from_ptr(in.first);
+  params.ea_input_im        = ea_from_ptr(in.second);
+  params.ea_output_re       = ea_from_ptr(out.first);
+  params.ea_output_im       = ea_from_ptr(out.second);
   params.kernel_stride      = length;
   params.input_stride       = length;
   params.output_stride      = length;
Index: src/vsip/opt/cbe/ppu/fft.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.hpp	(revision 168761)
+++ src/vsip/opt/cbe/ppu/fft.hpp	(working copy)
@@ -26,6 +26,7 @@
 #include <vsip/core/fft/factory.hpp>
 #include <vsip/core/fft/util.hpp>
 #include <vsip/opt/cbe/fft_params.h>
+#include <vsip/opt/cbe/ppu/task_manager.hpp>
 
 /***********************************************************************
   Declarations
@@ -99,7 +100,8 @@
     return
       (dom.size() >= MIN_FFT_1D_SIZE) &&
       (dom.size() <= MAX_FFT_1D_SIZE) &&
-      (fft::is_power_of_two(dom));
+      (fft::is_power_of_two(dom)) &&
+      vsip::impl::cbe::Task_manager::instance()->num_spes() > 0;
   }
   static std::auto_ptr<backend<1, I, O,
  			       axis<I, O, S>::value,
@@ -134,7 +136,8 @@
     return
       (size >= MIN_FFT_1D_SIZE) &&
       (size <= MAX_FFT_1D_SIZE) &&
-      (fft::is_power_of_two(size));
+      (fft::is_power_of_two(size)) &&
+      vsip::impl::cbe::Task_manager::instance()->num_spes() > 0;
   }
   static std::auto_ptr<fft::fftm<I, O, A, E> > 
   create(Domain<2> const &dom, typename impl::Scalar_of<I>::type scale)
Index: src/vsip/opt/cbe/ppu/bindings.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/bindings.cpp	(revision 168761)
+++ src/vsip/opt/cbe/ppu/bindings.cpp	(working copy)
@@ -1,10 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    vsip/opt/cbe/ppu/bindings.hpp
+/** @file    vsip/opt/cbe/ppu/bindings.cpp
     @author  Stefan Seefeld
     @date    2006-12-29
     @brief   VSIPL++ Library: Wrappers and traits to bridge with IBMs CBE SDK.
@@ -18,6 +18,7 @@
 #include <vsip/math.hpp>
 #include <vsip/opt/cbe/ppu/bindings.hpp>
 #include <vsip/opt/cbe/ppu/task_manager.hpp>
+#include <vsip/opt/cbe/ppu/util.hpp>
 #include <vsip/opt/cbe/vmmul_params.h>
 #include <vsip/opt/cbe/vmul_params.h>
 extern "C"
@@ -80,7 +81,7 @@
     params.a_ptr += (sizeof(T)/sizeof(float))*my_chunks*chunk_size;
     params.b_ptr += (sizeof(T)/sizeof(float))*my_chunks*chunk_size;
     params.r_ptr += (sizeof(T)/sizeof(float))*my_chunks*chunk_size;
-    len -= chunk_size;
+    len -= my_chunks * chunk_size;
   }
 
   // Cleanup leftover data that doesn't fit into a full chunk.
@@ -117,7 +118,6 @@
 
 
 
-
 template <typename T>
 void vmmul(
   T const* V, T const* M, T* R, 
@@ -138,9 +138,9 @@
   params.command = VSIP_IMPL_VMMUL_RELOAD_VECTOR;
   params.input_stride = m_stride;
   params.output_stride = r_stride;
-  params.ea_input_vector = reinterpret_cast<unsigned long long>(V);
-  params.ea_input_matrix = reinterpret_cast<unsigned long long>(M);
-  params.ea_output_matrix = reinterpret_cast<unsigned long long>(R);
+  params.ea_input_vector  = ea_from_ptr(V);
+  params.ea_input_matrix  = ea_from_ptr(M);
+  params.ea_output_matrix = ea_from_ptr(R);
 
   Task_manager* mgr = Task_manager::instance();
   length_type psize = sizeof(Vmmul_params);
Index: tests/regressions/large_vmul.cpp
===================================================================
--- tests/regressions/large_vmul.cpp	(revision 0)
+++ tests/regressions/large_vmul.cpp	(revision 0)
@@ -0,0 +1,73 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/regressions/large_vmul.cpp
+    @author  Jules Bergmann
+    @date    2007-04-13
+    @brief   VSIPL++ Library: Regression for large complex vmul.
+
+    Caused segfault when run with 1 SPE.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace vsip;
+using namespace vsip_csl;
+
+/***********************************************************************
+  Definitions - Utility Functions
+***********************************************************************/
+
+template <typename T,
+	  typename ComplexFmt>
+void
+test_vmul(length_type size)
+{
+  typedef impl::Layout<1, row1_type, impl::Stride_unit_dense, ComplexFmt>
+		LP;
+  typedef impl::Fast_block<1, T, LP> block_type;
+
+  Vector<T, block_type> A(size, T(3));
+  Vector<T, block_type> B(size, T(4));
+  Vector<T, block_type> Z(size);
+
+  Rand<T> gen(0, 0);
+  A = gen.randu(size);
+  B = gen.randu(size);
+
+  Z = A * B;
+  for (index_type i=0; i<size; ++i)
+  {
+    // Note: almost_equal is necessary for Cbe since SPE and PPE will not
+    //       compute idential results.
+    if (!almost_equal(Z(i), A(i) * B(i)))
+    {
+      std::cout << "Z(i)        = " << Z(i) << std::endl;
+      std::cout << "A(i) * B(i) = " << A(i) * B(i) << std::endl;
+    }
+    test_assert(almost_equal(Z(i), A(i) * B(i)));
+  }
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  typedef impl::Cmplx_inter_fmt cif;
+  typedef impl::Cmplx_split_fmt csf;
+
+  vsipl init(argc, argv);
+
+  test_vmul<complex<float>, impl::Cmplx_inter_fmt>(2048);
+  test_vmul<complex<float>, impl::Cmplx_inter_fmt>(2048+16);
+  test_vmul<complex<float>, impl::Cmplx_inter_fmt>(2048+16+1);
+}
