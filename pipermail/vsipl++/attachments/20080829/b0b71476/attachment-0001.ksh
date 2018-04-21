Index: src/vsip/opt/ukernel.hpp
===================================================================
--- src/vsip/opt/ukernel.hpp	(revision 218845)
+++ src/vsip/opt/ukernel.hpp	(working copy)
@@ -18,7 +18,7 @@
 ***********************************************************************/
 
 #define DEBUG             0
-#define DEBUG_SPATT_EXTRA 1
+#define DEBUG_SPATT_EXTRA 0
 
 #if DEBUG_SPATT_EXTRA
 #  include <iostream>
@@ -389,6 +389,18 @@
   {
 #if DEBUG_SPATT_EXTRA
     std::cout << "Ps_helper<2, View>: " << name << "\n"
+	      << "  num_chunks_      : " << num_chunks_ << "\n"
+	      << "  num_chunks0_     : " << num_chunks0_ << "\n"
+	      << "  num_chunks1_     : " << num_chunks1_ << "\n"
+	      << "  chunks_per_spe_  : " << chunks_per_spe_ << "\n"
+	      << "  chunk_size_      : " << chunk_size_ << "\n"
+	      << "  chunk_size0_     : " << chunk_size0_ << "\n"
+	      << "  chunk_size1_     : " << chunk_size1_ << "\n"
+	      << "  chunk_size0_last_: " << chunk_size0_last_ << "\n"
+	      << "  chunk_size1_last_: " << chunk_size1_last_ << "\n"
+	      << "  chunk_size0_xtra_: " << chunk_size0_xtra_ << "\n"
+	      << "  chunk_size1_xtra_: " << chunk_size1_xtra_ << "\n"
+	      << "  chunk_index_     : " << chunk_index_ << "\n"
       ;
 #endif
   }
@@ -707,8 +719,8 @@
 	 vh2.extra_size() != 0))
     {
       if (vh0.extra_size() != 0) vh0.dump("vh0");
-      if (vh1.extra_size() != 0) vh0.dump("vh1");
-      if (vh2.extra_size() != 0) vh0.dump("vh2");
+      if (vh1.extra_size() != 0) vh1.dump("vh1");
+      if (vh2.extra_size() != 0) vh2.dump("vh2");
       // TODO: THROW
       assert(0);
     }
@@ -766,6 +778,114 @@
 
     task.sync();
   }
+
+
+  template <typename View0,
+	    typename View1,
+	    typename View2,
+	    typename View3>
+  static void apply(
+    FuncT const&   func,
+    View0          in0,
+    View1          in1,
+    View2          in2,
+    View3          out)
+  {
+    using cbe::Task_manager;
+    using cbe::Workblock;
+    using cbe::Task;
+    using cbe::is_dma_addr_ok;
+    using cbe::is_dma_size_ok;
+
+    typedef Ps_helper<View0> vh0_t;
+    typedef Ps_helper<View1> vh1_t;
+    typedef Ps_helper<View2> vh2_t;
+    typedef Ps_helper<View3> vh3_t;
+
+    typedef typename vh0_t::ptr_type ptr0_type;
+    typedef typename vh1_t::ptr_type ptr1_type;
+    typedef typename vh2_t::ptr_type ptr2_type;
+    typedef typename vh3_t::ptr_type ptr3_type;
+
+    vh0_t vh0(in0, func.in_spatt(0),  1);
+    vh1_t vh1(in1, func.in_spatt(1),  1);
+    vh2_t vh2(in2, func.in_spatt(2),  1);
+    vh3_t vh3(out, func.out_spatt(0), 0);
+
+    assert(pre_argc + in_argc  == 3);
+    assert(out_argc == 1);
+
+    cbe::Task_manager* mgr = cbe::Task_manager::instance();
+    length_type spes       = mgr->num_spes();
+    length_type psize      = sizeof(param_type);
+    length_type stack_size = func.stack_size();
+
+    param_type ukp;
+    func.fill_params(ukp.kernel_params);
+
+    vh0.fill(ukp.in_stream[0],  spes);
+    vh1.fill(ukp.in_stream[1],  spes);
+    vh2.fill(ukp.in_stream[2],  spes);
+    vh3.fill(ukp.out_stream[0], spes);
+
+    assert(vh0.extra_size() == 0);
+    assert(vh1.extra_size() == 0);
+    assert(vh2.extra_size() == 0);
+    assert(vh3.extra_size() == 0);
+
+#if DEBUG
+    vh0.dump("vh0");
+    vh1.dump("vh1");
+    vh2.dump("vh2");
+    vh3.dump("vh3");
+#endif
+
+    length_type isize;
+    length_type osize;
+    length_type dtl_size;
+    {
+      ukp.pre_chunks = 0;
+      isize = vh0.buffer_size() + vh1.buffer_size() + vh2.buffer_size();
+      osize = vh3.buffer_size();
+      dtl_size = vh0.dtl_size() + vh1.dtl_size() + vh2.dtl_size() + vh3.dtl_size();
+    }
+
+    length_type chunks         = vh3.num_chunks();
+    length_type chunks_per_spe = vh3.chunks_per_spe();
+    assert(chunks_per_spe * spes <= chunks);
+
+#if DEBUG
+    printf("chunk num: %d (%d x %d)  size: %d (%d x %d)  block_size: %d %d  dtl_size: %d\n",
+	   vh3.num_chunks(),
+	   ukp.out_stream[0].num_chunks0, ukp.out_stream[0].num_chunks1,
+	   0, /* vh3.chunk_size_, */
+	   ukp.out_stream[0].chunk_size0, ukp.out_stream[0].chunk_size1,
+	   isize, osize, dtl_size);
+#endif
+
+    char const* image =
+      Ukernel_task_map<FuncT, void(ptr0_type, ptr1_type, ptr2_type, ptr3_type)>::image();
+    Task task = mgr->alf_handle()->create_task(
+      image, stack_size, psize, isize, osize, dtl_size);
+
+    for (index_type i=0; i<spes && i<chunks; ++i)
+    {
+      // If chunks don't divide evenly, give the first SPEs one extra.
+      length_type chunks_this_spe = (i < chunks % spes) ? chunks_per_spe + 1
+	                                                : chunks_per_spe;
+
+      vh0.set_workblock(ukp.in_stream[0],  chunks_this_spe);
+      vh1.set_workblock(ukp.in_stream[1],  chunks_this_spe);
+      vh2.set_workblock(ukp.in_stream[2],  chunks_this_spe);
+      vh3.set_workblock(ukp.out_stream[0], chunks_this_spe);
+
+      Workblock block = task.create_workblock(chunks_this_spe + ukp.pre_chunks);
+      block.set_parameters(ukp);
+      block.enqueue();
+    }
+
+    task.sync();
+  }
 };
 
 
@@ -807,6 +927,19 @@
     Stream_spe<FuncT>::apply(func_, in0, in1, out);
   }
 
+  template <typename View0,
+	    typename View1,
+	    typename View2,
+	    typename View3>
+  void operator()(
+    View0 in0,
+    View1 in1,
+    View2 in2,
+    View3 out)
+  {
+    Stream_spe<FuncT>::apply(func_, in0, in1, in2, out);
+  }
+
   // Private member data.
 private:
   FuncT&         func_;
Index: src/vsip/opt/ukernel/cbe_accel/alf_base.hpp
===================================================================
--- src/vsip/opt/ukernel/cbe_accel/alf_base.hpp	(revision 218845)
+++ src/vsip/opt/ukernel/cbe_accel/alf_base.hpp	(working copy)
@@ -494,7 +494,73 @@
 };
   
 
+template <typename KernelT>
+struct Kernel_helper<KernelT, 0, 3, 1>
+{
+  static void
+  input(
+    param_type*  ukp,
+    void*        entries,
+    unsigned int iter, 
+    unsigned int iter_count)
+  {
+    typedef typename KernelT::in0_type  in0_type;
+    typedef typename KernelT::in1_type  in1_type;
+    typedef typename KernelT::in2_type  in2_type;
 
+    ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+
+    add_stream<in0_type>(entries, ukp->in_stream[0], iter, iter_count);
+    add_stream<in1_type>(entries, ukp->in_stream[1], iter, iter_count);
+    add_stream<in2_type>(entries, ukp->in_stream[2], iter, iter_count);
+
+    ALF_ACCEL_DTL_END(entries);
+  }
+
+  static void
+  kernel(
+    param_type* ukp,
+    void*       in,
+    void*       out,
+    unsigned int iter, 
+    unsigned int iter_count)
+  {
+    typedef typename KernelT::in0_type  in0_type;
+    typedef typename KernelT::in1_type  in1_type;
+    typedef typename KernelT::in2_type  in2_type;
+    typedef typename KernelT::out0_type out0_type;
+
+    Pinfo p_in0, p_in1, p_in2, p_out;
+
+    set_chunk_info(ukp->in_stream[0],  p_in0, iter);
+    set_chunk_info(ukp->in_stream[1],  p_in1, iter);
+    set_chunk_info(ukp->in_stream[2],  p_in2, iter);
+    set_chunk_info(ukp->out_stream[0], p_out, iter);
+
+    // Pointers must be extracted from knowledge of the stream sizes as ALF
+    // transfers all the input data into one contiguous space.
+
+    size_t offset1 = p_in0.l_total_size;
+    size_t offset2 = offset1 + p_in1.l_total_size;
+    size_t offset3 = offset2 + p_in2.l_total_size;
+
+    // The To_ptr<> struct calculates the correct offset for a given
+    // pointer type (scalar, interleaved complex or split complex).  The 
+    // first size passes refers to the previous data segments.  The second 
+    // size pertains to the current segment and is only needed to calculate 
+    // offsets in the case of split complex.
+
+    ukobj.compute(
+      To_ptr<in0_type >::offset(in,  0,       p_in0.l_total_size),
+      To_ptr<in1_type >::offset(in,  offset1, p_in1.l_total_size),
+      To_ptr<in2_type >::offset(in,  offset2, p_in2.l_total_size),
+      To_ptr<out0_type>::offset(out, 0,       p_out.l_total_size),
+      p_in0, p_in1, p_in2, p_out);
+  }
+};
+
+
+
 extern "C"
 int
 input(
Index: src/vsip/opt/ukernel/cbe_accel/resource_manager.hpp
===================================================================
--- src/vsip/opt/ukernel/cbe_accel/resource_manager.hpp	(revision 218845)
+++ src/vsip/opt/ukernel/cbe_accel/resource_manager.hpp	(working copy)
@@ -48,7 +48,7 @@
       valid_[i] = 0;
   }
 
-  // Find index for reosource key/param.  Return -1 if not found.
+  // Find index for resource key/param.  Return -1 if not found.
   // Increment use count if found.
   int find(int key, int param)
   {
Index: src/vsip/opt/ukernel/cbe_accel/ukernel.hpp
===================================================================
--- src/vsip/opt/ukernel/cbe_accel/ukernel.hpp	(revision 218845)
+++ src/vsip/opt/ukernel/cbe_accel/ukernel.hpp	(working copy)
@@ -4,14 +4,14 @@
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    vsip/opt/ukernel/spu/ukernel.hpp
+/** @file    vsip/opt/ukernel/cbe_accel/ukernel.hpp
     @author  Jules Bergmann
     @date    2008-06-10
     @brief   VSIPL++ Library: User-defined Kernel.
 */
 
-#ifndef VSIP_OPT_CBE_SPU_UKERNEL_HPP
-#define VSIP_OPT_CBE_SPU_UKERNEL_HPP
+#ifndef VSIP_OPT_UKERNEL_CBE_ACCEL_UKERNEL_HPP
+#define VSIP_OPT_UKERNEL_CBE_ACCEL_UKERNEL_HPP
 
 /***********************************************************************
   Included Files
@@ -28,14 +28,15 @@
 
 struct Pinfo
 {
-  unsigned int dim;
-  unsigned int l_total_size;
-  unsigned int l_offset[3];
-  unsigned int l_size[3];
-  signed int   l_stride[3];
-  signed int   g_offset[3];
-  signed int   o_leading[3];
-  signed int   o_trailing[3];
+  unsigned int dim;            // dimensions in this sub-block
+  unsigned int l_total_size;   // total elements for this iteration
+  unsigned int l_offset[3];    // offset to beginning of data (if alignment
+                               //  was required for DMA)
+  unsigned int l_size[3];      // elements per dimension for this iteration
+  signed int   l_stride[3];    // next-element stride in each dimension
+  signed int   g_offset[3];    // offset from block origin 
+  signed int   o_leading[3];   // 
+  signed int   o_trailing[3];  // 
 };
 
 
@@ -65,4 +66,4 @@
 
 
 
-#endif // VSIP_OPT_CBE_SPU_UKERNEL_HPP
+#endif // VSIP_OPT_UKERNEL_CBE_ACCEL_UKERNEL_HPP
Index: src/vsip/opt/ukernel/cbe_accel/debug.hpp
===================================================================
--- src/vsip/opt/ukernel/cbe_accel/debug.hpp	(revision 0)
+++ src/vsip/opt/ukernel/cbe_accel/debug.hpp	(revision 0)
@@ -0,0 +1,64 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/cbe_accel/debug.hpp
+    @author  Don McCoy
+    @date    2008-08-27
+    @brief   VSIPL++ Library: User-defined Kernel, debug routines.
+*/
+
+#ifndef VSIP_OPT_UKERNEL_CBE_ACCEL_DEBUG_HPP
+#define VSIP_OPT_UKERNEL_CBE_ACCEL_DEBUG_HPP
+
+#ifndef NDEBUG
+
+#include <stdlib.h>
+#include <vsip/opt/ukernel/cbe_accel/ukernel.hpp>
+
+
+void cbe_debug_dump_pinfo(char tag[], Pinfo const& pinfo) 
+{
+  printf("Pinfo %s = \n", 
+    tag);
+  printf(" dim:           %u\n", 
+    pinfo.dim );
+  printf(" l_total_size:  %u\n", 
+    pinfo.l_total_size );
+  printf(" l_offset[3]:   %u  %u  %u\n",
+    pinfo.l_offset[0], 
+    pinfo.l_offset[1], 
+    pinfo.l_offset[2]);
+  printf(" l_size[3]:     %u  %u  %u\n", 
+    pinfo.l_size[0], 
+    pinfo.l_size[1], 
+    pinfo.l_size[2]);
+  printf(" l_stride[3]:   %d  %d  %d\n", 
+    pinfo.l_stride[0], 
+    pinfo.l_stride[1], 
+    pinfo.l_stride[2]);
+  printf(" g_offset[3]:   %d  %d  %d\n", 
+    pinfo.g_offset[0], 
+    pinfo.g_offset[1], 
+    pinfo.g_offset[2]);
+  printf(" o_leading[3]:  %d  %d  %d\n", 
+    pinfo.o_leading[0], 
+    pinfo.o_leading[1], 
+    pinfo.o_leading[2]);
+  printf(" o_trailing[3]: %d  %d  %d\n", 
+    pinfo.o_trailing[0], 
+    pinfo.o_trailing[1], 
+    pinfo.o_trailing[2]);
+}
+
+
+#else
+
+inline void cbe_debug_dump_pinfo(Pinfo const&) {}
+
+
+#endif // NDEBUG
+
+#endif // VSIP_OPT_UKERNEL_CBE_ACCEL_DEBUG_HPP
Index: src/vsip/opt/ukernel/kernels/cbe_accel/madd_f.cpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/madd_f.cpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/madd_f.cpp	(revision 0)
@@ -0,0 +1,21 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/madd_f.hpp
+    @author  Don McCoy
+    @date    2008-08-26
+    @brief   VSIPL++ Library: User-defined kernel for multiply-add.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/ukernel/kernels/cbe_accel/madd_f.hpp>
+
+typedef Madd_kernel kernel_type;
+
+#include <vsip/opt/ukernel/cbe_accel/alf_base.hpp>
Index: src/vsip/opt/ukernel/kernels/cbe_accel/cmadd_f.cpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/cmadd_f.cpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/cmadd_f.cpp	(revision 0)
@@ -0,0 +1,21 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/cmadd_f.hpp
+    @author  Don McCoy
+    @date    2008-08-26
+    @brief   VSIPL++ Library: User-defined kernel for multiply-add.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/ukernel/kernels/cbe_accel/cmadd_f.hpp>
+
+typedef Cmadd_kernel kernel_type;
+
+#include <vsip/opt/ukernel/cbe_accel/alf_base.hpp>
Index: src/vsip/opt/ukernel/kernels/cbe_accel/madd_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/madd_f.hpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/madd_f.hpp	(revision 0)
@@ -0,0 +1,78 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/madd_f.hpp
+    @author  Don McCoy
+    @date    2008-08-26
+    @brief   VSIPL++ Library: User-defined kernel for multiply-add.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <utility>
+#include <complex>
+
+#include <cml/spu/cml.h>
+#include <cml/spu/cml_core.h>
+
+#include <vsip/opt/ukernel/cbe_accel/debug.hpp>
+#include <vsip/opt/ukernel/cbe_accel/ukernel.hpp>
+
+#define DEBUG 0
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+struct Madd_kernel : Spu_kernel
+{
+  typedef float* in0_type;
+  typedef float* in1_type;
+  typedef float* in2_type;
+  typedef float* out0_type;
+
+  static unsigned int const in_argc  = 3;
+  static unsigned int const out_argc = 1;
+
+  static bool const in_place = true;
+
+  void compute(
+    in0_type     in0,
+    in1_type     in1,
+    in2_type     in2,
+    out0_type    out,
+    Pinfo const& p_in0,
+    Pinfo const& p_in1,
+    Pinfo const& p_in2,
+    Pinfo const& p_out)
+  {
+#if DEBUG
+    cbe_debug_dump_pinfo("p_in0", p_in0);
+    cbe_debug_dump_pinfo("p_in1", p_in1);
+    cbe_debug_dump_pinfo("p_in2", p_in2);
+    cbe_debug_dump_pinfo("p_out", p_out);
+#endif
+
+    size_t size0 = p_in0.l_size[0];
+    size_t size1 = p_in0.l_size[1];
+    size_t stride = p_in0.l_stride[0];
+
+    for (int i = 0; i < size0; ++i)
+    {
+      in0_type pi0 = &in0[i * stride];
+      in1_type pi1 = &in1[i * stride];
+      in2_type pi2 = &in2[i * stride];
+      out0_type po = &out[i * stride];
+   
+      for (int j = 0; j < size1; ++j)
+        po[j] = pi0[j] * pi1[j] + pi2[j];
+    }
+  }
+
+};
Index: src/vsip/opt/ukernel/kernels/cbe_accel/cmadd_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/cmadd_f.hpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/cmadd_f.hpp	(revision 0)
@@ -0,0 +1,78 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/cmadd_f.hpp
+    @author  Don McCoy
+    @date    2008-08-26
+    @brief   VSIPL++ Library: User-defined kernel for multiply-add.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <utility>
+#include <complex>
+
+#include <cml/spu/cml.h>
+#include <cml/spu/cml_core.h>
+
+#include <vsip/opt/ukernel/cbe_accel/debug.hpp>
+#include <vsip/opt/ukernel/cbe_accel/ukernel.hpp>
+
+#define DEBUG 0
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+struct Cmadd_kernel : Spu_kernel
+{
+  typedef std::complex<float>* in0_type;
+  typedef std::complex<float>* in1_type;
+  typedef std::complex<float>* in2_type;
+  typedef std::complex<float>* out0_type;
+
+  static unsigned int const in_argc  = 3;
+  static unsigned int const out_argc = 1;
+
+  static bool const in_place = true;
+
+  void compute(
+    in0_type     in0,
+    in1_type     in1,
+    in2_type     in2,
+    out0_type    out,
+    Pinfo const& p_in0,
+    Pinfo const& p_in1,
+    Pinfo const& p_in2,
+    Pinfo const& p_out)
+  {
+#if DEBUG
+    cbe_debug_dump_pinfo("p_in0", p_in0);
+    cbe_debug_dump_pinfo("p_in1", p_in1);
+    cbe_debug_dump_pinfo("p_in2", p_in2);
+    cbe_debug_dump_pinfo("p_out", p_out);
+#endif
+
+    size_t size0 = p_in0.l_size[0];
+    size_t size1 = p_in0.l_size[1];
+    size_t stride = p_in0.l_stride[0];
+
+    for (int i = 0; i < size0; ++i)
+    {
+      in0_type pi0 = &in0[i * stride];
+      in1_type pi1 = &in1[i * stride];
+      in2_type pi2 = &in2[i * stride];
+      out0_type po = &out[i * stride];
+   
+      for (int j = 0; j < size1; ++j)
+        po[j] = pi0[j] * pi1[j] + pi2[j];
+    }
+  }
+
+};
Index: src/vsip/opt/ukernel/kernels/cbe_accel/id1_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/id1_f.hpp	(revision 218845)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/id1_f.hpp	(working copy)
@@ -4,7 +4,7 @@
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    vsip/opt/cbe/spu/alf_id1_s.hpp
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/id1_f.hpp
     @author  Jules Bergmann
     @date    2008-01-23
     @brief   VSIPL++ Library: Kernel to perform vector copy.
Index: src/vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.hpp	(revision 218845)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.hpp	(working copy)
@@ -4,10 +4,10 @@
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    vsip/opt/cbe/ukspu/alf_uk_fft_split_c.hpp
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/zvmul_f.hpp
     @author  Jules Bergmann
     @date    2008-06-12
-    @brief   VSIPL++ Library: UKernel to compute split-complex float FFT's.
+    @brief   VSIPL++ Library: UKernel to compute split-complex vmul.
 */
 
 /***********************************************************************
Index: src/vsip/opt/ukernel/kernels/cbe_accel/id2_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/id2_f.hpp	(revision 218845)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/id2_f.hpp	(working copy)
@@ -4,7 +4,7 @@
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    vsip/opt/cbe/spu/alf_id2_s.hpp
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/id2_f.hpp
     @author  Jules Bergmann
     @date    2008-07-29
     @brief   VSIPL++ Library: Kernel to ID2.
Index: src/vsip/opt/ukernel/kernels/cbe_accel/cfft_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/cfft_f.hpp	(revision 218845)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/cfft_f.hpp	(working copy)
@@ -4,14 +4,14 @@
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    vsip/opt/cbe/ukspu/alf_uk_fft_c.hpp
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/cfft_f.hpp
     @author  Jules Bergmann
     @date    2008-06-12
     @brief   VSIPL++ Library: UKernel to compute interleaved-complex float FFT's.
 */
 
-#ifndef VSIP_OPT_CBE_UKSPU_ALF_UK_FFT_C_HPP
-#define VSIP_OPT_CBE_UKSPU_ALF_UK_FFT_C_HPP
+#ifndef VSIP_OPT_UKERNEL_KERNELS_CBE_ACCEL_CFFT_F_HPP
+#define VSIP_OPT_UKERNEL_KERNELS_CBE_ACCEL_CFFT_F_HPP
 
 /***********************************************************************
   Included Files
@@ -133,4 +133,4 @@
 // typedef Fft_kernel kernel_type;
 // #endif
 
-#endif // VSIP_OPT_CBE_UKSPU_ALF_UK_FFT_C_HPP
+#endif // VSIP_OPT_UKERNEL_KERNELS_CBE_ACCEL_CFFT_F_HPP
Index: src/vsip/opt/ukernel/kernels/cbe_accel/vmul_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/vmul_f.hpp	(revision 218845)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/vmul_f.hpp	(working copy)
@@ -4,7 +4,7 @@
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    vsip/opt/cbe/ukspu/alf_uk_vmul_f.hpp
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/vmul_f.hpp
     @author  Jules Bergmann
     @date    2008-06-24
     @brief   VSIPL++ Library: Elementwise vector multiply ukernel.
Index: src/vsip/opt/ukernel/kernels/host/madd.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/host/madd.hpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/host/madd.hpp	(revision 0)
@@ -0,0 +1,95 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    src/vsip/opt/ukernel/kernels/host/madd.hpp
+    @author  Don McCoy
+    @date    2008-08-26
+    @brief   VSIPL++ Library: User-defined kernel for multiply-add.
+*/
+
+#ifndef VSIP_SRC_OPT_UKERNEL_KERNELS_HOST_MADD_HPP
+#define VSIP_SRC_OPT_UKERNEL_KERNELS_HOST_MADD_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/ukernel.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Host-side vector elementwise multiply-add ukernel.
+
+class Madd_kernel : public vsip::impl::ukernel::Host_kernel_base
+{
+  // Parameters.
+  //  - 'tag_type' is used to select the appropriate kernel (via
+  //    Task_manager's Task_map)
+  //  - in_argc and out_argc describe the number of input and output
+  //    streams.
+  //  - param_type (inherited) defaults to 'Empty_params'.
+public:
+  static unsigned int const in_argc  = 3;
+  static unsigned int const out_argc = 1;
+
+  // Host-side ukernel object initialization.
+  //
+  // Streaming pattern divides matrix into whole, single rows.
+
+  Madd_kernel()
+    : sp (vsip::impl::ukernel::Blocksize_sdist(1), 
+          vsip::impl::ukernel::Whole_sdist())
+  {}
+
+
+
+  // Host-side compute kernel.  Used if accelerator is not available.
+
+  template <typename View0,
+	    typename View1,
+	    typename View2,
+	    typename View3>
+  void compute(
+    View0 in0,
+    View1 in1,
+    View2 in2,
+    View3 out)
+  {
+    out = in0 * in1 + in2;
+  }
+
+
+  // Queury API:
+  // - in_spatt()/out_spatt() allow VSIPL++ to determine streaming
+  //   pattern for user-kernel.  Since both input and output have same
+  //   streaming pattern, simply return 'sp'
+
+  vsip::impl::ukernel::Stream_pattern const& in_spatt(vsip::index_type i) const
+  { return sp; }
+
+  vsip::impl::ukernel::Stream_pattern const& out_spatt(vsip::index_type) const
+  { return sp; }
+
+
+  // Member data.
+  //
+  // 'sp' is the stream pattern.
+private:
+  vsip::impl::ukernel::Stream_pattern sp;	
+};
+
+DEFINE_UKERNEL_TASK(
+  Madd_kernel,
+  void(float*, float*, float*, float*),
+  madd_f)
+
+DEFINE_UKERNEL_TASK(
+  Madd_kernel,
+  void(std::complex<float>*, std::complex<float>*, std::complex<float>*, 
+    std::complex<float>*),
+  cmadd_f)
+
+#endif // VSIP_SRC_OPT_UKERNEL_KERNELS_HOST_MADD_HPP
Index: tests/GNUmakefile.inc.in
===================================================================
--- tests/GNUmakefile.inc.in	(revision 218845)
+++ tests/GNUmakefile.inc.in	(working copy)
@@ -40,7 +40,8 @@
 tests_cxx_sources += $(wildcard $(srcdir)/tests/ref-impl/*.cpp)
 
 # These need to be linked with -lvsip_csl
-tests_csl_cxx_sources := $(wildcard $(srcdir)/tests/tutorial/*.cpp)
+tests_csl_cxx_sources := $(wildcard $(srcdir)/tests/tutorial/*.cpp) \
+                         $(wildcard $(srcdir)/tests/ukernel/*.cpp)
 
 tests_cxx_exes := \
 	$(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(tests_cxx_sources))
Index: tests/ukernel/vmul.cpp
===================================================================
--- tests/ukernel/vmul.cpp	(revision 218845)
+++ tests/ukernel/vmul.cpp	(working copy)
@@ -79,9 +79,8 @@
   vsipl init(argc, argv);
 
   test_ukernel<float>(1024+32);
-  // test_ukernel<float>(1025);
-  // test_ukernel<float>(16384);
-  // test_ukernel<complex<float> >(16384);
+  test_ukernel<float>(16384);
+  test_ukernel<complex<float> >(16384);
 
   return 0;
 }
Index: tests/ukernel/madd.cpp
===================================================================
--- tests/ukernel/madd.cpp	(revision 0)
+++ tests/ukernel/madd.cpp	(revision 0)
@@ -0,0 +1,89 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    tests/ukernels/madd.cpp
+    @author  Don McCoy
+    @date    2008-08-26
+    @brief   VSIPL++ Library: User-defined kernel for multiply-add.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/random.hpp>
+#include <vsip_csl/ukernel.hpp>
+#include <vsip/opt/ukernel/kernels/host/madd.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
+
+using namespace std;
+using namespace vsip;
+using vsip_csl::equal;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T>
+void
+test_ukernel(length_type rows, length_type cols)
+{
+  Madd_kernel obj;
+
+  vsip_csl::ukernel::Ukernel<Madd_kernel> madd_uk(obj);
+
+  Matrix<T> in0(rows, cols);
+  Matrix<T> in1(rows, cols);
+  Matrix<T> in2(rows, cols);
+  Matrix<T> out(rows, cols);
+
+  Rand<T> gen(0, 0);
+  in0 = gen.randu(rows, cols);
+  in1 = gen.randu(rows, cols);
+  in2 = gen.randu(rows, cols);
+
+  madd_uk(in0, in1, in2, out);
+
+
+  for (index_type i=0; i < rows; ++i)
+    for (index_type j=0; j < cols; ++j)
+    {
+      T madd = in0.get(i, j) * in1.get(i, j) + in2.get(i, j);
+      if (!equal(madd, out.get(i, j)))
+      {
+        std::cout << "index " << i << ", " << j << " : "
+                  << in0.get(i, j) << " * "
+                  << in1.get(i, j) << " + "
+                  << in2.get(i, j) << " = "
+                  << in0.get(i, j) * in1.get(i, j) + in2.get(i, j) << "  vs  "
+                  << out.get(i, j)
+                  << std::endl;
+      }
+      test_assert(equal(
+          in0.get(i, j) * in1.get(i, j) + in2.get(i, j), 
+          out.get(i, j)));
+    }
+}
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_ukernel<float>(64, 1024);
+  test_ukernel<complex<float> >(64, 1024);
+
+  return 0;
+}
