Index: src/vsip/opt/ukernel.hpp
===================================================================
--- src/vsip/opt/ukernel.hpp	(revision 220385)
+++ src/vsip/opt/ukernel.hpp	(working copy)
@@ -253,7 +253,14 @@
 };
 
 
-
+/// This class has methods used by Stream_spe::apply() to set up streaming for
+/// views of different dimensions.
+///
+///   ::fill()     Takes information from a Stream_pattern as well as a count
+///                of the number of available SPEs and fills in a Uk_stream
+///                struct with information about how the data is to be sub-
+///                divided for each iteration of data ('chunk') sent to an SPE.
+///
 template <typename ViewT,
 	  dimension_type Dim = ViewT::dim>
 struct Ps_helper;
@@ -580,7 +587,215 @@
 };
 
 
+template <typename ViewT>
+struct Ps_helper<ViewT, 3>
+{
+  typedef typename ViewT::block_type block_type;
+  typedef typename ViewT::value_type value_type;
+  typedef typename Block_layout<block_type>::complex_type complex_type;
+  typedef Storage<complex_type, value_type> storage_type;
+  typedef typename storage_type::type       ptr_type;
+  typedef typename storage_type::alloc_type alloc_type;
 
+  Ps_helper(ViewT& view, Stream_pattern const& spatt, bool input)
+    : ext_   (view.block())
+    , addr_  (ext_.data())
+    , spatt_ (spatt)
+    , input_ (input)
+  {}
+
+  void fill(Uk_stream& stream, length_type spes)
+  {
+    num_chunks_ = 1;
+    chunk_size0_ = ext_.size(0);
+    chunk_size1_ = ext_.size(1);
+    chunk_size2_ = ext_.size(2);
+    chunk_size0_last_ = 0;
+    chunk_size1_last_ = 0;
+    chunk_size2_last_ = 0;
+
+    if (spatt_.sdist0_.num_chunks_ > 0)
+    {
+      num_chunks0_ = spatt_.sdist0_.num_chunks_;
+      chunk_size0_ = ext_.size(0) / num_chunks0_;
+      chunk_size0_xtra_ = ext_.size(0) - (chunk_size0_ * num_chunks0_);
+    }
+    else if (spatt_.sdist0_.num_chunks_ == 0)
+    {
+      chunk_size0_ = spatt_.sdist0_.max_chunk_size_;
+      num_chunks0_ = ext_.size(0) / chunk_size0_;
+      chunk_size0_last_ = ext_.size(0) - (chunk_size0_ * num_chunks0_);
+      if (chunk_size0_last_ % spatt_.sdist0_.chunk_multiple_)
+      {
+	chunk_size0_xtra_ =
+	  chunk_size0_last_ % spatt_.sdist0_.chunk_multiple_;
+	chunk_size0_last_  -= chunk_size0_xtra_;
+      }
+      else chunk_size0_xtra_ = 0;
+      if (chunk_size0_last_) num_chunks0_++;
+    }
+    else assert(0);
+
+    if (spatt_.sdist1_.num_chunks_ > 0)
+    {
+      num_chunks1_ = spatt_.sdist1_.num_chunks_;
+      chunk_size1_ = ext_.size(1) / num_chunks1_;
+      chunk_size1_xtra_ = ext_.size(1) - (chunk_size1_ * num_chunks1_);
+    }
+    else if (spatt_.sdist1_.num_chunks_ == 0)
+    {
+      chunk_size1_ = spatt_.sdist1_.max_chunk_size_;
+      num_chunks1_ = ext_.size(1) / chunk_size1_;
+      chunk_size1_last_ = ext_.size(1) - (chunk_size1_ * num_chunks1_);
+      if (chunk_size1_last_ % spatt_.sdist1_.chunk_multiple_)
+      {
+	chunk_size1_xtra_ =
+	  chunk_size1_last_ % spatt_.sdist1_.chunk_multiple_;
+	chunk_size1_last_  -= chunk_size1_xtra_;
+      }
+      else chunk_size1_xtra_ = 0;
+      if (chunk_size1_last_) num_chunks1_++;
+    }
+    else assert(0);
+
+    if (spatt_.sdist2_.num_chunks_ > 0)
+    {
+      num_chunks2_ = spatt_.sdist2_.num_chunks_;
+      chunk_size2_ = ext_.size(2) / num_chunks2_;
+      chunk_size2_xtra_ = ext_.size(2) - (chunk_size2_ * num_chunks2_);
+    }
+    else if (spatt_.sdist2_.num_chunks_ == 0)
+    {
+      chunk_size2_ = spatt_.sdist2_.max_chunk_size_;
+      num_chunks2_ = ext_.size(2) / chunk_size2_;
+      chunk_size2_last_ = ext_.size(2) - (chunk_size2_ * num_chunks2_);
+      if (chunk_size2_last_ % spatt_.sdist2_.chunk_multiple_)
+      {
+	chunk_size2_xtra_ =
+	  chunk_size2_last_ % spatt_.sdist2_.chunk_multiple_;
+	chunk_size2_last_  -= chunk_size2_xtra_;
+      }
+      else chunk_size2_xtra_ = 0;
+      if (chunk_size2_last_) num_chunks2_++;
+    }
+    else assert(0);
+
+    num_chunks_              = num_chunks0_ * num_chunks1_  * num_chunks2_;
+    chunks_per_spe_          = num_chunks_ / spes;
+    chunk_index_             = 0;
+
+    stream.dim               = 3;
+    stream.align_shift       = 0;
+    stream.num_chunks0       = num_chunks0_;
+    stream.num_chunks1       = num_chunks1_;
+    stream.num_chunks2       = num_chunks2_;
+    stream.chunk_size0       = chunk_size0_;
+    stream.chunk_size1       = chunk_size1_;
+    stream.chunk_size2       = chunk_size2_;
+    stream.chunk_size0_extra = chunk_size0_last_;
+    stream.chunk_size1_extra = chunk_size1_last_;
+    stream.chunk_size2_extra = chunk_size2_last_;
+    stream.stride0           = ext_.stride(0);
+    stream.stride1           = ext_.stride(1);
+    stream.stride2           = ext_.stride(2);
+    stream.leading_overlap0  = spatt_.sdist0_.leading_overlap_;
+    stream.leading_overlap1  = spatt_.sdist1_.leading_overlap_;
+    stream.leading_overlap2  =
+      VSIP_IMPL_INCREASE_TO_DMA_SIZE(spatt_.sdist2_.leading_overlap_,
+				     sizeof(float));
+    stream.trailing_overlap0 = spatt_.sdist0_.trailing_overlap_;
+    stream.trailing_overlap1 = spatt_.sdist1_.trailing_overlap_;
+    stream.trailing_overlap2 =
+      VSIP_IMPL_INCREASE_TO_DMA_SIZE(spatt_.sdist2_.trailing_overlap_,
+				     sizeof(float));
+    stream.skip_first_overlap0 = spatt_.sdist0_.skip_first_overlap_;
+    stream.skip_first_overlap1 = spatt_.sdist1_.skip_first_overlap_;
+    stream.skip_first_overlap2 = spatt_.sdist2_.skip_first_overlap_;
+    stream.skip_last_overlap0  = spatt_.sdist0_.skip_last_overlap_;
+    stream.skip_last_overlap1  = spatt_.sdist1_.skip_last_overlap_;
+    stream.skip_last_overlap2  = spatt_.sdist2_.skip_last_overlap_;
+
+    chunk_size0_ += stream.leading_overlap0 +
+                    stream.trailing_overlap0;
+    chunk_size1_ += stream.leading_overlap1 +
+                    stream.trailing_overlap1;
+    chunk_size2_ += stream.leading_overlap2 +
+                    stream.trailing_overlap2;
+
+    chunk_size_ = chunk_size0_ * chunk_size1_ * chunk_size2_;
+
+    Set_addr<ptr_type>::set(stream, addr_);
+  }
+
+  void set_workblock(Uk_stream& stream, length_type chunks_this_spe)
+  {
+    stream.chunk_offset = chunk_index_;
+    chunk_index_ += chunks_this_spe;
+  }
+
+  int extra_size()
+  { return chunk_size0_xtra_ * chunk_size1_xtra_ * chunk_size2_xtra_; }
+
+  int extra_size(dimension_type dim)
+  { return (dim == 0) ? chunk_size0_xtra_ :
+           (dim == 1) ? chunk_size1_xtra_ : chunk_size2_xtra_; }
+
+  length_type buffer_size()
+  { return sizeof(value_type)*chunk_size_; }
+
+  length_type dtl_size()       { return chunk_size0_ * chunk_size1_; }
+  length_type num_chunks()     { return num_chunks_; }
+  length_type chunks_per_spe() { return chunks_per_spe_; }
+
+  void dump(char const* name)
+  {
+#if DEBUG_SPATT_EXTRA
+    std::cout << "Ps_helper<3, View>: " << name << "\n"
+	      << "  num_chunks_      : " << num_chunks_ << "\n"
+	      << "  num_chunks0_     : " << num_chunks0_ << "\n"
+	      << "  num_chunks1_     : " << num_chunks1_ << "\n"
+	      << "  num_chunks2_     : " << num_chunks2_ << "\n"
+	      << "  chunks_per_spe_  : " << chunks_per_spe_ << "\n"
+	      << "  chunk_size_      : " << chunk_size_ << "\n"
+	      << "  chunk_size0_     : " << chunk_size0_ << "\n"
+	      << "  chunk_size1_     : " << chunk_size1_ << "\n"
+	      << "  chunk_size2_     : " << chunk_size2_ << "\n"
+	      << "  chunk_size0_last_: " << chunk_size0_last_ << "\n"
+	      << "  chunk_size1_last_: " << chunk_size1_last_ << "\n"
+	      << "  chunk_size2_last_: " << chunk_size2_last_ << "\n"
+	      << "  chunk_size0_xtra_: " << chunk_size0_xtra_ << "\n"
+	      << "  chunk_size1_xtra_: " << chunk_size1_xtra_ << "\n"
+	      << "  chunk_size2_xtra_: " << chunk_size2_xtra_ << "\n"
+	      << "  chunk_index_     : " << chunk_index_ << "\n"
+      ;
+#endif
+  }
+
+private:
+  Ext_data<block_type>  ext_;
+  ptr_type              addr_;
+  Stream_pattern const& spatt_;
+  bool                  input_;
+  length_type           num_chunks_;
+  length_type           num_chunks0_;
+  length_type           num_chunks1_;
+  length_type           num_chunks2_;
+  length_type           chunks_per_spe_;
+  length_type           chunk_size_;
+  length_type           chunk_size0_;
+  length_type           chunk_size1_;
+  length_type           chunk_size2_;
+  length_type           chunk_size0_last_;
+  length_type           chunk_size1_last_;
+  length_type           chunk_size2_last_;
+  length_type           chunk_size0_xtra_;
+  length_type           chunk_size1_xtra_;
+  length_type           chunk_size2_xtra_;
+  index_type            chunk_index_;
+};
+
+
+
 template <typename FuncT>
 struct Stream_spe
 {
Index: src/vsip/opt/ukernel/cbe_accel/alf_base.hpp
===================================================================
--- src/vsip/opt/ukernel/cbe_accel/alf_base.hpp	(revision 220385)
+++ src/vsip/opt/ukernel/cbe_accel/alf_base.hpp	(working copy)
@@ -84,7 +84,7 @@
     assert(IS_DMA_SIZE(this_size*sizeof(T)));
     ALF_ACCEL_DTL_ENTRY_ADD(entries, this_size, ALF_DATA_FLOAT, ea);
     size -= this_size;
-    ea   += this_size;
+    ea   += this_size * sizeof(T);
   }
 }
 
@@ -143,18 +143,47 @@
   unsigned int iter_count)
 {
   alf_data_addr64_t ea;
+  unsigned int chunk_idx;
+  unsigned int chunk_idx0;
+  unsigned int chunk_idx1;
+  int offset;
+  unsigned int num_lines;
+  unsigned int line_size;
 
-  unsigned int chunk_idx  = stream.chunk_offset + iter;
+  if (stream.dim == 3)
+  {
+    // Currently there is a restriction on the third dimension of a view
+    // being limited to a whole distribution.  To handle this, the third
+    // dimension is folded into the second (similar to the way a dense
+    // 2-D view can be recast as a 1-D view)
 
-  unsigned int chunk_idx0 = chunk_idx / stream.num_chunks1;
-  unsigned int chunk_idx1 = chunk_idx % stream.num_chunks1;
-  int offset              = 
+    assert(stream.num_chunks2 == 1);
+
+    chunk_idx  = stream.chunk_offset + iter;
+
+    chunk_idx0 = chunk_idx / stream.num_chunks1;
+    chunk_idx1 = chunk_idx % stream.num_chunks1;
+    offset     = 
         chunk_idx0 * stream.chunk_size0 * stream.stride0 * sizeof(float)
       + chunk_idx1 * stream.chunk_size1 * stream.stride1 * sizeof(float);
 
-  unsigned int num_lines = stream.chunk_size0;
-  unsigned int line_size = stream.chunk_size1;
+    num_lines = stream.chunk_size0;
+    line_size = stream.chunk_size1 * stream.chunk_size2;
+  }
+  else
+  {
+    chunk_idx  = stream.chunk_offset + iter;
 
+    chunk_idx0 = chunk_idx / stream.num_chunks1;
+    chunk_idx1 = chunk_idx % stream.num_chunks1;
+    offset     = 
+        chunk_idx0 * stream.chunk_size0 * stream.stride0 * sizeof(float)
+      + chunk_idx1 * stream.chunk_size1 * stream.stride1 * sizeof(float);
+
+    num_lines = stream.chunk_size0;
+    line_size = stream.chunk_size1;
+  }
+
   // Handle last chunk in row/column (if odd sized)
   if (chunk_idx0 == stream.num_chunks0-1 && stream.chunk_size0_extra)
     num_lines = stream.chunk_size0_extra;
@@ -242,6 +271,16 @@
       add_entry<float>(entries, line_size,
 		       ea + i*stream.stride0*sizeof(float));
   }
+  else if (Type_equal<PtrT, unsigned int*>::value)
+  {
+    ea = stream.addr + offset;
+
+    for (int i=0; i<num_lines; ++i)
+    {
+      alf_data_addr64_t eax = ea + i*stream.stride0 * sizeof(unsigned int);
+      add_entry<unsigned int>(entries, line_size, eax);
+    }
+  }
   else { assert(0); }
 }
 
@@ -292,7 +331,7 @@
       pinfo.o_trailing[0] = 0;
 
   }
-  else
+  else if (stream.dim == 2)
   {
     unsigned int chunk_idx0 = chunk_idx / stream.num_chunks1;
     unsigned int chunk_idx1 = chunk_idx % stream.num_chunks1;
@@ -361,6 +400,88 @@
     else
       pinfo.o_trailing[1] = 0;
   }
+  else if (stream.dim == 3)
+  {
+    unsigned int chunk_idx0 = chunk_idx / stream.num_chunks1;
+    unsigned int chunk_idx1 = chunk_idx % stream.num_chunks1;
+    pinfo.g_offset[0]   = chunk_idx0 * stream.chunk_size0;
+    pinfo.g_offset[1]   = chunk_idx1 * stream.chunk_size1;
+    pinfo.g_offset[2]   = 0;
+
+    if (chunk_idx0 == stream.num_chunks0-1 && stream.chunk_size0_extra)
+      pinfo.l_size[0] = stream.chunk_size0_extra;
+    else
+      pinfo.l_size[0] = stream.chunk_size0;
+
+    if (chunk_idx1 == stream.num_chunks1-1 && stream.chunk_size1_extra)
+      pinfo.l_size[1] = stream.chunk_size1_extra;
+    else
+      pinfo.l_size[1] = stream.chunk_size1;
+
+    assert(stream.num_chunks2 == 1);
+    pinfo.l_size[2] = stream.chunk_size2;
+
+    pinfo.l_total_size = pinfo.l_size[0] * pinfo.l_size[1] * pinfo.l_size[2];
+
+    pinfo.l_stride[0]   = pinfo.l_size[1] * pinfo.l_size[2];
+    pinfo.l_stride[1]   = 1;
+    pinfo.l_stride[2]   = 1;
+    pinfo.o_leading[0]  = stream.leading_overlap0;
+    pinfo.o_leading[1]  = stream.leading_overlap1;
+    pinfo.o_leading[2]  = stream.leading_overlap2;
+    pinfo.o_trailing[0] = stream.trailing_overlap0;
+    pinfo.o_trailing[1] = stream.trailing_overlap1;
+    pinfo.o_trailing[2] = stream.trailing_overlap2;
+
+    if (stream.leading_overlap0 &&
+	(chunk_idx0 != 0 || !stream.skip_first_overlap0))
+    {
+      pinfo.o_leading[0] = stream.leading_overlap0;
+      pinfo.l_offset[0]  = stream.leading_overlap0;
+    }
+    else
+    {
+      pinfo.o_leading[0] = 0;
+      pinfo.l_offset[0]  = 0;
+    }
+
+    if (stream.trailing_overlap0 &&
+        (chunk_idx0 != stream.num_chunks0-1 || !stream.skip_last_overlap0))
+      pinfo.o_trailing[0] = stream.trailing_overlap0;
+    else
+      pinfo.o_trailing[0] = 0;
+
+    if (stream.leading_overlap1 &&
+	(chunk_idx1 != 0 || !stream.skip_first_overlap1))
+    {
+      pinfo.o_leading[1] = stream.leading_overlap1;
+      pinfo.l_offset[1] =
+	stream.align_shift + 
+	INCREASE_TO_DMA_SIZE_IN_FLOATS(stream.leading_overlap1);
+      pinfo.l_stride[0] += pinfo.l_offset[1];
+    }
+    else
+    {
+      pinfo.o_leading[1] = 0;
+      pinfo.l_offset[1] = stream.align_shift;
+    }
+
+    if (stream.trailing_overlap1 &&
+	(chunk_idx1 != stream.num_chunks1-1 || !stream.skip_last_overlap1))
+    {
+      pinfo.o_trailing[1] = stream.trailing_overlap1;
+      pinfo.l_stride[0]  +=
+	INCREASE_TO_DMA_SIZE_IN_FLOATS(stream.leading_overlap1);
+    }
+    else
+      pinfo.o_trailing[1] = 0;
+
+    // overlap for the third dimension is not supported
+    assert(stream.leading_overlap2 == 0);
+    assert(stream.trailing_overlap2 == 0);
+  }
+  else
+    assert(0);
 }
 
 
Index: src/vsip/opt/ukernel/cbe_accel/debug.hpp
===================================================================
--- src/vsip/opt/ukernel/cbe_accel/debug.hpp	(revision 220385)
+++ src/vsip/opt/ukernel/cbe_accel/debug.hpp	(working copy)
@@ -13,12 +13,11 @@
 #ifndef VSIP_OPT_UKERNEL_CBE_ACCEL_DEBUG_HPP
 #define VSIP_OPT_UKERNEL_CBE_ACCEL_DEBUG_HPP
 
-#ifndef NDEBUG
+#include <vsip/opt/ukernel/cbe_accel/ukernel.hpp>
 
+#ifndef NDEBUG
 #include <stdlib.h>
-#include <vsip/opt/ukernel/cbe_accel/ukernel.hpp>
 
-
 void cbe_debug_dump_pinfo(char tag[], Pinfo const& pinfo) 
 {
   printf("Pinfo %s = \n", 
Index: src/vsip/opt/ukernel/kernels/cbe_accel/interp_f.cpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/interp_f.cpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/interp_f.cpp	(revision 0)
@@ -0,0 +1,22 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/interp_f.hpp
+    @author  Don McCoy
+    @date    2008-08-26
+    @brief   VSIPL++ Library: User-defined polar to rectangular
+               interpolation kernel for SSAR images.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/ukernel/kernels/cbe_accel/interp_f.hpp>
+
+typedef Interp_kernel kernel_type;
+
+#include <vsip/opt/ukernel/cbe_accel/alf_base.hpp>
Index: src/vsip/opt/ukernel/kernels/cbe_accel/interp_f.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/cbe_accel/interp_f.hpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/cbe_accel/interp_f.hpp	(revision 0)
@@ -0,0 +1,85 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/ukernel/kernels/cbe_accel/interp_f.hpp
+    @author  Don McCoy
+    @date    2008-08-26
+    @brief   VSIPL++ Library: User-defined polar to rectangular
+               interpolation kernel for SSAR images.
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
+struct Interp_kernel : Spu_kernel
+{
+  typedef unsigned int*        in0_type;
+  typedef float*               in1_type;
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
+    assert(p_in0.l_size[0] == p_in1.l_size[0]);
+    assert(p_in1.l_size[0] == p_in2.l_size[0]);
+    assert(p_in0.l_size[1] == p_in1.l_size[1]);
+    assert(p_in1.l_size[1] == p_in2.l_size[1]);
+    assert(p_in0.l_stride[0] == p_in2.l_stride[0]);
+    assert(p_in0.l_stride[1] == p_in2.l_stride[1]);
+
+    size_t size0 = p_in1.l_size[0];
+    size_t size1 = p_in1.l_size[1];
+    size_t size2 = p_in1.l_size[2];
+    size_t stride = p_in0.l_stride[0];
+
+    for (size_t i = 0; i < p_out.l_total_size; ++i)
+      out[i] = std::complex<float>();
+
+    for (size_t j = 0; j < size1; ++j)
+      for (size_t k = 0; k < size2; ++k)
+      {
+        out[in0[j] + k] += in2[j] * in1[j * size2 + k];
+      }
+  }
+
+};
Index: src/vsip/opt/ukernel/kernels/host/interp.hpp
===================================================================
--- src/vsip/opt/ukernel/kernels/host/interp.hpp	(revision 0)
+++ src/vsip/opt/ukernel/kernels/host/interp.hpp	(revision 0)
@@ -0,0 +1,107 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    src/vsip/opt/ukernel/kernels/host/interp.hpp
+    @author  Don McCoy
+    @date    2008-08-26
+    @brief   VSIPL++ Library: User-defined polar to rectangular
+               interpolation kernel for SSAR images.
+*/
+
+#ifndef VSIP_SRC_OPT_UKERNEL_KERNELS_HOST_INTERP_HPP
+#define VSIP_SRC_OPT_UKERNEL_KERNELS_HOST_INTERP_HPP
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
+// Host-side vector elementwise copy ukernel.
+
+class Interp_kernel : public vsip::impl::ukernel::Host_kernel_base
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
+  // Streaming pattern divides matrix into whole, single columns (for now).
+  //
+
+  Interp_kernel()
+    : sp (vsip::impl::ukernel::Blocksize_sdist(1), 
+          vsip::impl::ukernel::Whole_sdist())
+  {}
+
+
+
+  // Host-side compute kernel.  Used if accelerator is not available.
+  //
+  // View sizes:
+  //   in0 is N x M
+  //   in1 is N x M x I
+  //   in2 is N x M
+  //   out is NX x M    
+  // 
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
+    out = View3::value_type();
+
+    for (vsip::index_type j = 0; j < in0.size(1); ++j)
+      for (vsip::index_type i = 0; i < in0.size(0); ++i)
+        for (vsip::index_type h = 0; h < in1.size(2); ++h)
+        {
+          vsip::index_type ikxrows = in0.get(i, j) + h;
+
+          out.put(ikxrows, j, out.get(ikxrows, j) + 
+            (in2.get(i, j) * in1.get(i, j, h)));
+        }
+  }
+
+
+  // Queury API:
+  // - in_spatt()/out_spatt() allow VSIPL++ to determine streaming
+  //   pattern for user-kernel.  Since both input and output have same
+  //   streaming pattern, simply return 'sp'
+
+  vsip::impl::ukernel::Stream_pattern const& in_spatt(vsip::index_type) const
+  { return sp; }
+
+  vsip::impl::ukernel::Stream_pattern const& out_spatt(vsip::index_type) const
+  { return sp; }
+
+  // Member data.
+  //
+  // 'sp' is the stream pattern.
+private:
+  vsip::impl::ukernel::Stream_pattern sp;	
+};
+
+
+DEFINE_UKERNEL_TASK(
+  Interp_kernel,
+  void(vsip::index_type*, float*, std::complex<float>*, std::complex<float>*),
+  interp_f)
+
+#endif // VSIP_SRC_OPT_UKERNEL_KERNELS_HOST_INTERP_HPP
Index: src/vsip/opt/ukernel/ukernel_params.hpp
===================================================================
--- src/vsip/opt/ukernel/ukernel_params.hpp	(revision 220385)
+++ src/vsip/opt/ukernel/ukernel_params.hpp	(working copy)
@@ -36,20 +36,28 @@
   unsigned int       dim;
   unsigned int       chunk_size0;
   unsigned int       chunk_size1;
+  unsigned int       chunk_size2;
   unsigned int       chunk_size0_extra;
   unsigned int       chunk_size1_extra;
+  unsigned int       chunk_size2_extra;
   unsigned int       stride0;
   unsigned int       stride1;
+  unsigned int       stride2;
   unsigned int       num_chunks0;
   unsigned int       num_chunks1;
+  unsigned int       num_chunks2;
   unsigned int       leading_overlap0;
   unsigned int       leading_overlap1;
+  unsigned int       leading_overlap2;
   unsigned int       trailing_overlap0;
   unsigned int       trailing_overlap1;
+  unsigned int       trailing_overlap2;
   unsigned int       skip_first_overlap0;
   unsigned int       skip_first_overlap1;
+  unsigned int       skip_first_overlap2;
   unsigned int       skip_last_overlap0;
   unsigned int       skip_last_overlap1;
+  unsigned int       skip_last_overlap2;
   unsigned int       align_shift;
 };
 
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 220385)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -126,6 +126,8 @@
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/cbe
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/cbe/ppu
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/cbe/cml
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/ukernel
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/ukernel/kernels/host
 endif
 endif
 	for header in $(hdr); do \
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 220385)
+++ GNUmakefile.in	(working copy)
@@ -433,6 +433,10 @@
              $(wildcard $(srcdir)/src/vsip/opt/cbe/cml/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/cbe/*.h))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/opt/ukernel/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/opt/ukernel/kernels/host/*.hpp))
 endif
 endif
 ########################################################################
Index: tests/ukernel/interp.cpp
===================================================================
--- tests/ukernel/interp.cpp	(revision 0)
+++ tests/ukernel/interp.cpp	(revision 0)
@@ -0,0 +1,163 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    tests/ukernels/interp.cpp
+    @author  Don McCoy
+    @date    2008-08-26
+    @brief   VSIPL++ Library: User-defined kernel for polar to rectangular
+               interpolation for SSAR images.
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
+#include <vsip/opt/ukernel/kernels/host/interp.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+#define DBG_SHOW_IO      0
+#define DBG_SHOW_ERRORS  0
+
+
+namespace ref
+{
+
+template <typename T,
+	  typename Block1,
+	  typename Block2,
+	  typename Block3,
+	  typename Block4>
+void
+interpolate(
+  const_Matrix<index_type, Block1> indices,  // n x m
+  Tensor<T, Block2>                window,   // n x m x I
+  const_Matrix<complex<T>, Block3> in,       // n x m
+  Matrix<complex<T>, Block4>       out)      // nx x m
+{
+  length_type n = indices.size(0);
+  length_type m = indices.size(1);
+  length_type nx = out.size(0);
+  length_type I = window.size(2);
+  assert(n == in.size(0));
+  assert(m == in.size(1));
+  assert(m == out.size(1));
+  assert(window.size(0) == n);
+  assert(window.size(1) == m);
+
+  out = complex<T>(0);
+
+  for (index_type j = 0; j < m; ++j)
+    for (index_type i = 0; i < n; ++i)
+      for (index_type h = 0; h < I; ++h)
+      {
+        index_type ikxrows = indices.get(i, j) + h;
+
+        out.put(ikxrows, j, out.get(ikxrows, j) + 
+          (in.get(i, j) * window.get(i, j, h)));
+      }
+}
+
+} // namespace ref
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T>
+void
+test_ukernel(length_type rows, length_type cols, length_type depth)
+{
+  typedef vsip::index_type I;
+  typedef std::complex<T>  C;
+  typedef tuple<1, 0, 2> order_type;
+
+  Matrix<I, Dense<2, I, order_type> > indices(rows, cols);
+  Tensor<T, Dense<3, T, order_type> > window(rows, cols, depth);
+  Matrix<C, Dense<2, C, order_type> > input(rows, cols);
+  // filled with non-zero values to ensure all are overwritten
+  Matrix<C, Dense<2, C, order_type> > out(rows + depth - 1, cols, C(-4, 4));
+  Matrix<C, Dense<2, C, order_type> > ref(rows + depth - 1, cols, C(4, -4));
+
+  // set up input data, weights and indices
+  Rand<C> gen(0, 0);
+  input = gen.randu(rows, cols);
+  Rand<T> gen_real(1, 0);
+  for (index_type k = 0; k < depth; ++k)
+    window(whole_domain, whole_domain, k) = gen_real.randu(rows, cols);
+
+  // The size of the output is determined by the way the indices are
+  // set up.  Here, they are mapped one-to-one, but the output ends up
+  // being larger by an amount determined by the depth of the window
+  // function used.
+  for (index_type i = 0; i < rows; ++i)
+    indices.row(i) = i;
+
+
+  // Compute reference output image
+  ref::interpolate(indices, window, input, ref);
+
+
+  // Compute output image using user-defined kernel.  Data must be 
+  // transposed to place it in row-major format.
+  Interp_kernel obj;
+  ukernel::Ukernel<Interp_kernel> interpolate(obj);
+  interpolate(
+    indices.transpose(), 
+    window.template transpose<1, 0, 2>(), 
+    input.transpose(), 
+    out.transpose() );
+
+
+  // verify results
+#if  DBG_SHOW_IO
+  cout << "window = " << endl << window.template transpose<2, 0, 1>() << endl;
+  cout << "indices = " << endl << indices << endl;
+  cout << "input = " << endl << input << endl;
+  cout << "ref = " << endl << ref << endl;
+  cout << "out = " << endl << out << endl;
+#endif
+
+#if DBG_SHOW_ERRORS
+  for (index_type i = 0; i < out.size(0); ++i)
+    for (index_type j = 0; j < out.size(1); ++j)
+    {
+      if (!equal(out.get(i, j), ref.get(i, j)))
+        cout << "[" << i << ", " << j << "] : " << out.get(i, j) << " != " << ref.get(i, j) 
+             << "    " << ref.get(i, j) - out.get(i, j) << endl;
+    }
+#endif
+
+  test_assert(view_equal(out, ref));
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
+  test_ukernel<float>(8, 4, 5);
+  test_ukernel<float>(512, 256, 9);
+  test_ukernel<float>(1144, 1072, 5);
+
+  return 0;
+}
