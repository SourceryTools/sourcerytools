Index: ChangeLog
===================================================================
--- ChangeLog	(revision 207681)
+++ ChangeLog	(working copy)
@@ -1,3 +1,19 @@
+2008-05-14  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/cbe/ppu/alf.hpp: Queury ALF handle from CML.  Allow
+	  num SPUs to be set only once.  Check return status of ALF functions.
+	* src/vsip/opt/cbe/vmul_params.h: Pass pointers as unsigned long long.
+	* src/vsip/opt/cbe/ppu/bindings.cpp: Likewise.
+	* src/vsip/opt/cbe/spu/alf_vmul_c.c: Pass pointers as unsigned long
+	  long.  Add missing header.
+	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in (libs): Add spe_kernels.
+	* src/vsip/GNUmakefile.inc.in: Avoid building huge_page_pool if
+	  HAVE_HUGE_PAGE_POOL not defined.
+	* src/vsip_csl/img/perspective_warp.hpp: Remove dead code.
+	* tests/fir.cpp: Remove unused variable.
+	* tests/extdata-runtime.cpp: Add missing library initialization.
+	* benchmarks/vmul.cpp: Correct usage.
+
 2008-05-13  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/opt/cbe/ppu/alf.hpp: Initialize ALF through CML if
@@ -39,7 +55,6 @@
 	* src/vsip/opt/cbe/spu/alf_vmul_c.c: Likewise.
 	* src/vsip/opt/cbe/alf/*: Removed as obsolete.
 
-
 2008-04-23  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/initfin.cpp: Initialize default pool.
Index: src/vsip/opt/cbe/ppu/alf.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/alf.hpp	(revision 207681)
+++ src/vsip/opt/cbe/ppu/alf.hpp	(working copy)
@@ -13,6 +13,8 @@
 #ifndef VSIP_OPT_CBE_PPU_ALF_HPP
 #define VSIP_OPT_CBE_PPU_ALF_HPP
 
+#include <vsip/core/config.hpp>
+
 #if VSIP_IMPL_REF_IMPL
 # error "vsip/opt files cannot be used as part of the reference impl."
 #endif
@@ -21,11 +23,12 @@
 #include <cml/ppu/cml.h>
 #endif
 
-#include <vsip/core/config.hpp>
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/support.hpp>
 #include "alf.h"
 
+extern alf_handle_t cml_impl_alf_handle();
+
 namespace vsip
 {
 namespace impl
@@ -70,7 +73,11 @@
     assert(status >= 0);
   }
 
-  void enqueue() { alf_wb_enqueue(workblock_);}
+  void enqueue()
+  {
+    int status = alf_wb_enqueue(workblock_);
+    assert(status >= 0);
+  }
 private:
   Workblock() {}
 
@@ -139,29 +146,42 @@
 {
 public:
   ALF(unsigned int num_accelerators)
-    : num_accelerators_(num_accelerators)
+    : num_accelerators_(0)
   {
 #ifdef VSIP_IMPL_HAVE_CML
     cml_init();
+    (void)num_accelerators;
+    alf_ = cml_impl_alf_handle();
+    num_accelerators_ = query(ALF_QUERY_NUM_ACCEL);
 #else
     int status = alf_init(0, &alf_);
     assert(status >= 0);
-    if (num_accelerators) 
-    {
-      set_num_accelerators(num_accelerators);
-      assert(status >= 0);
-    }
+
+    set_num_accelerators(num_accelerators);
 #endif
   }
-  ~ALF() 
-  { 
+  ~ALF()
+  {
 #ifdef VSIP_IMPL_HAVE_CML
     cml_fini();
 #else
     alf_exit(&alf_, ALF_EXIT_POLICY_WAIT, -1);
 #endif
   }
-  void set_num_accelerators(unsigned int n) { alf_num_instances_set(alf_, n);}
+  void set_num_accelerators(unsigned int n)
+  {
+    // In ALF 3.0, this function can only be called once, in between
+    // alf_init and first alf_task_create.
+    assert(num_accelerators_ == 0);
+
+    unsigned int num_spus = query(ALF_QUERY_NUM_ACCEL);
+    if (num_spus > n || n == 0)
+      n = num_spus;
+    
+    int status = alf_num_instances_set(alf_, n);
+    assert(status > 0);
+    num_accelerators_ = status;
+  }
   unsigned int num_accelerators() const { return num_accelerators_;}
 
   Task create_task(const char *image,
@@ -178,7 +198,9 @@
   unsigned int query(ALF_QUERY_SYS_INFO_T info) const
   {
     unsigned int result;
-    alf_query_system_info(alf_, info, ALF_ACCEL_TYPE_SPE, &result);
+    int status = alf_query_system_info(alf_, info, ALF_ACCEL_TYPE_SPE,
+				       &result);
+    assert(status >= 0);
     return result;
   }
 
Index: src/vsip/opt/cbe/ppu/bindings.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/bindings.cpp	(revision 207681)
+++ src/vsip/opt/cbe/ppu/bindings.cpp	(working copy)
@@ -52,9 +52,6 @@
   params.a_blk_stride = chunk_size;
   params.b_blk_stride = chunk_size;
   params.r_blk_stride = chunk_size;
-  params.a_ptr        = (float*)A;
-  params.b_ptr        = (float*)B;
-  params.r_ptr        = (float*)R;
   params.pad          = 1;
 
   Task_manager *mgr = Task_manager::instance();
@@ -69,6 +66,10 @@
   length_type chunks_per_spe = chunks / spes;
   assert(chunks_per_spe * spes <= chunks);
 
+  T const* a_ptr = A;
+  T const* b_ptr = B;
+  T*       r_ptr = R;
+
   for (index_type i=0; i<spes && i<chunks; ++i)
   {
     // If chunks don't divide evenly, give the first SPEs one extra.
@@ -76,11 +77,15 @@
                                                 : chunks_per_spe;
 
     Workblock block = task.create_workblock(my_chunks);
+    params.a_ptr = (uintptr_t)a_ptr;
+    params.b_ptr = (uintptr_t)b_ptr;
+    params.r_ptr = (uintptr_t)r_ptr;
     block.set_parameters(params);
     block.enqueue();
-    params.a_ptr += (sizeof(T)/sizeof(float))*my_chunks*chunk_size;
-    params.b_ptr += (sizeof(T)/sizeof(float))*my_chunks*chunk_size;
-    params.r_ptr += (sizeof(T)/sizeof(float))*my_chunks*chunk_size;
+
+    a_ptr += my_chunks*chunk_size;
+    b_ptr += my_chunks*chunk_size;
+    r_ptr += my_chunks*chunk_size;
     len -= my_chunks * chunk_size;
   }
 
@@ -96,6 +101,9 @@
     params.length = (len / granularity) * granularity;
     assert(is_dma_size_ok(params.length*sizeof(T)));
     Workblock block = task.create_workblock(1);
+    params.a_ptr = (uintptr_t)a_ptr;
+    params.b_ptr = (uintptr_t)b_ptr;
+    params.r_ptr = (uintptr_t)r_ptr;
     block.set_parameters(params);
     block.enqueue();
     len -= params.length;
Index: src/vsip/opt/cbe/spu/alf_vmul_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmul_c.c	(revision 207681)
+++ src/vsip/opt/cbe/spu/alf_vmul_c.c	(working copy)
@@ -10,6 +10,7 @@
     @brief   VSIPL++ Library: Kernel to compute vmul complex float.
 */
 
+#include <spu_intrinsics.h>
 #include <alf_accel.h>
 #include <vsip/opt/cbe/vmul_params.h>
 
@@ -26,15 +27,14 @@
 
   // Transfer input A.
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
-  ea = (params->a_ptr + current_count * 2 * params->a_blk_stride);
+  ea = params->a_ptr + current_count*2*params->a_blk_stride*sizeof(float);
   ALF_ACCEL_DTL_ENTRY_ADD(entries,
 			  2 * params->length,  	// 2 * for complex
 			  ALF_DATA_FLOAT,
 			  ea);
 
   // Transfer input B.
-/*   ALF_DT_LIST_CREATE(p_list_entries, 2*params->length*sizeof(float)); */
-  ea = (params->b_ptr + current_count * 2 * params->b_blk_stride);
+  ea = params->b_ptr + current_count*2*params->b_blk_stride*sizeof(float);
   ALF_ACCEL_DTL_ENTRY_ADD(entries,
 			  2 * params->length,  	// 2 * for complex
 			  ALF_DATA_FLOAT,
@@ -56,7 +56,7 @@
 
   // Transfer output R.
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
-  ea = (params->r_ptr + current_count * 2 * params->r_blk_stride);
+  ea = params->r_ptr + current_count*2*params->r_blk_stride*sizeof(float);
   ALF_ACCEL_DTL_ENTRY_ADD(entries,
 			  2 * params->length,  	// 2 * for complex
 			  ALF_DATA_FLOAT,
@@ -66,11 +66,11 @@
 }
 
 
-
 int kernel(void* p_context,
 	   void* p_params,
 	   void* input,
 	   void* output,
+	   void* inout,
 	   unsigned int iter,
 	   unsigned int n)
 {
@@ -112,7 +112,6 @@
     /* input vectors are in interleaved form in A1,A2 and B1,B2 with each input vector representing 2 complex numbers
        and thus this loop would repeat for N/4 iterations
     */
-#if 0 // FIXME: the following doesn't compile
     I1 = spu_shuffle(A1, A2, I_Perm_Vector); /* pulls out 1st and 3rd 4-byte element from vectors A1 and A2 */
     I2 = spu_shuffle(B1, B2, I_Perm_Vector); /* pulls out 1st and 3rd 4-byte element from vectors B1 and B2 */
     Q1 = spu_shuffle(A1, A2, Q_Perm_Vector); /* pulls out 2nd and 4th 4-byte element from vectors A1 and A2 */
@@ -123,7 +122,6 @@
     I1 = spu_madd(I1, I2, A1);               /* calculates ac - bd for all four elements */ 
     *D1 = spu_shuffle(I1, Q1, vcvmrgh);       /* spreads the results back into interleaved format */
     *D2 = spu_shuffle(I1, Q1, vcvmrgl);       /* spreads the results back into interleaved format */
-#endif
     ++i;
   }
 
Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 207681)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -34,6 +34,8 @@
 
 spe_kernels := lib/svpp_kernels.so
 
+libs += $(spe_kernels)
+
 CC_SPU := @CC_SPU@
 CXX_SPU := @CXX_SPU@
 EMBED_SPU := @EMBED_SPU@
@@ -112,6 +114,7 @@
 -include src/vsip/opt/cbe/alf/src/spu/GNUmakefile.inc
 
 mostlyclean::
+	rm $(spe_kernels)
 	rm -f $(src_vsip_opt_cbe_spu_obj)
 	rm -f $(src_vsip_opt_cbe_spu_mod)
 
Index: src/vsip/opt/cbe/vmul_params.h
===================================================================
--- src/vsip/opt/cbe/vmul_params.h	(revision 207681)
+++ src/vsip/opt/cbe/vmul_params.h	(working copy)
@@ -30,32 +30,32 @@
 
 typedef struct
 {
-  unsigned int length;
-  unsigned int a_blk_stride;
-  unsigned int b_blk_stride;
-  unsigned int r_blk_stride;
-  float*       a_ptr; // input
-  float*       b_ptr; // input
-  float*       r_ptr; // result = A * B
-  unsigned int pad;
+  unsigned int       length;
+  unsigned int       a_blk_stride;
+  unsigned int       b_blk_stride;
+  unsigned int       r_blk_stride;
+  unsigned long long a_ptr; // input
+  unsigned long long b_ptr; // input
+  unsigned long long r_ptr; // result = A * B
+  unsigned int       pad;
 } Vmul_params;
 
 typedef struct
 {
-  unsigned int length;
-  unsigned int a_blk_stride;
-  unsigned int b_blk_stride;
-  unsigned int r_blk_stride;
+  unsigned int       length;
+  unsigned int       a_blk_stride;
+  unsigned int       b_blk_stride;
+  unsigned int       r_blk_stride;
 
-  float*       a_im_ptr;
-  float*       a_re_ptr;
-  float*       b_im_ptr;
-  float*       b_re_ptr;
+  unsigned long long a_im_ptr;
+  unsigned long long a_re_ptr;
+  unsigned long long b_im_ptr;
+  unsigned long long b_re_ptr;
 
-  float*       r_im_ptr;
-  float*       r_re_ptr;
-  unsigned int command;
-  unsigned int pad[1];
+  unsigned long long r_im_ptr;
+  unsigned long long r_re_ptr;
+  unsigned int       command;
+  unsigned int       pad[1];
 } Vmul_split_params;
 
 #ifdef _cplusplus
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 207681)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -63,6 +63,10 @@
 			$(srcdir)/src/vsip/opt/simd/threshold.cpp \
 			$(srcdir)/src/vsip/opt/simd/vaxpy.cpp \
 			$(srcdir)/src/vsip/opt/simd/vma_ip_csc.cpp
+ifndef VSIP_IMPL_HAVE_HUGE_PAGE_POOL
+src_vsip_cxx_sources := $(filter-out %/huge_page_pool.cpp, $(src_vsip_cxx_sources))
+
+endif
 endif # VSIP_IMPL_REF_IMPL
 
 src_vsip_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(src_vsip_cxx_sources))
Index: src/vsip_csl/img/perspective_warp.hpp
===================================================================
--- src/vsip_csl/img/perspective_warp.hpp	(revision 207681)
+++ src/vsip_csl/img/perspective_warp.hpp	(working copy)
@@ -160,7 +160,6 @@
 
   pwarp_type pwarp(P, vsip::Domain<2>(in.size(0), in.size(1)));
   pwarp(in, out);
-  // vsip_csl::img::impl::Pwarp<CoeffT, T>::exec(P, in, out);
 }
 
 } // namespace vsip_csl::img
Index: tests/fir.cpp
===================================================================
--- tests/fir.cpp	(revision 207681)
+++ tests/fir.cpp	(working copy)
@@ -103,7 +103,6 @@
   vsip::length_type got1a = 0;
   for (vsip::length_type i = 0; i < 2 * M; ++i) // chained
   {
-    vsip::index_type o_got1a = got1a;
     got1a += fir1a(
       input(vsip::Domain<1>(i * N, 1, N)),
       output1(vsip::Domain<1>(got1a, 1, (N + D - 1) / D)));
Index: tests/extdata-runtime.cpp
===================================================================
--- tests/extdata-runtime.cpp	(revision 207681)
+++ tests/extdata-runtime.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -843,8 +843,10 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
   vector_tests();
   matrix_tests();
   tensor_tests();
Index: benchmarks/vmul.cpp
===================================================================
--- benchmarks/vmul.cpp	(revision 207681)
+++ benchmarks/vmul.cpp	(working copy)
@@ -79,8 +79,8 @@
       << " Vector-Vector:\n"
       << "   -1 -- Vector<        float > * Vector<        float >\n"
       << "   -2 -- Vector<complex<float>> * Vector<complex<float>>\n"
-      << "   -3 -- Vector<complex<float>> * Vector<complex<float>> (SPLIT)\n"
-      << "   -4 -- Vector<complex<float>> * Vector<complex<float>> (INTER)\n"
+      << "   -3 -- Vector<complex<float>> * Vector<complex<float>> (INTER)\n"
+      << "   -4 -- Vector<complex<float>> * Vector<complex<float>> (SPLIT)\n"
       << "   -5 -- Vector<        float > * Vector<complex<float>>\n"
       << "\n"
       << "  -21 -- t_vmul_dom1\n"
Index: m4/cbe.m4
===================================================================
--- m4/cbe.m4	(revision 207681)
+++ m4/cbe.m4	(working copy)
@@ -29,12 +29,19 @@
   [],
   [with_cbe_default_num_spes=8])
 
+AC_ARG_WITH(cml_prefix,
+  AS_HELP_STRING([--with-cml-prefix=PATH],
+                 [Specify the installation path of CML.  Only valid
+		  when using CBE SDK]))
+
 if test "$with_cbe_sdk" != "no"; then
 
   cbe_sdk_version=300
 
   AC_DEFINE_UNQUOTED(VSIP_IMPL_CBE_SDK, 1,
-        [Set to 1 to support Cell Broadband Engine.])
+        [Set to 1 to support Cell Broadband Engine (requires CML).])
+  AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_CML, 1,
+        [Set to 1 if CML is available (requires SDK).])
   AC_DEFINE_UNQUOTED(VSIP_IMPL_CBE_NUM_SPES, $with_cbe_default_num_spes,
         [Define default number of SPEs.])
   AC_SUBST(VSIP_IMPL_HAVE_CBE_SDK, 1)
@@ -57,6 +64,11 @@
     fi
   fi
 
+  if test "$with_cml_prefix" != ""; then
+    CPPFLAGS="$CPPFLAGS -I$with_cml_prefix/include"
+    LDFLAGS="$LDFLAGS -L$with_cml_prefix/lib"
+  fi
+
   AC_SUBST(CPP_SPU_FLAGS, "")
   if test "$neutral_acconfig" = 'y'; then
     CPPFLAGS="$CPPFLAGS -DVSIP_CBE_SDK_VERSION=$cbe_sdk_version"
@@ -66,7 +78,7 @@
           [Cell SDK version.])
   fi
 
-  LIBS="-lalf -lspe2 -ldl $LIBS"
+  LIBS="-lcml -lalf -lspe2 -ldl $LIBS"
 
 else
   AC_SUBST(VSIP_IMPL_HAVE_CBE_SDK, "")
