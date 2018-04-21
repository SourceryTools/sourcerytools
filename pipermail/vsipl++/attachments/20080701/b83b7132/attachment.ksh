Index: ChangeLog
===================================================================
--- ChangeLog	(revision 213285)
+++ ChangeLog	(working copy)
@@ -1,5 +1,15 @@
 2008-06-30  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/cbe/ppu/task_manager.hpp: Remove V++ level caching.
+	* src/vsip/opt/cbe/ppu/task_manager.cpp: Likewise.
+	* src/vsip/opt/cbe/ppu/alf.cpp: Use CML alf_chache routines.
+	* src/vsip/opt/cbe/ppu/alf.hpp: Destroy task on destruction.
+	* src/vsip/opt/cbe/cml/matvec.hpp: Fix Wall warnings.
+	* tests/regressions/alf_caching.cpp: New file, test alternate
+	  CML and VSIPL++ usage of ALF kernels.
+
+2008-06-30  Jules Bergmann  <jules@codesourcery.com>
+
 	* m4/fft.m4: Fix definition of VSIP_IMPL_FFTW3_HAVE_{TYPE} when
 	  neutral_acconfig != y.
 
Index: src/vsip/opt/cbe/ppu/task_manager.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/task_manager.hpp	(revision 213283)
+++ src/vsip/opt/cbe/ppu/task_manager.hpp	(working copy)
@@ -83,17 +83,8 @@
 	       length_type osize, // output buffer size
 	       length_type tsize) // number of DMA transfers
   {
-    if (task_ && task_.image() == Task_map<O, S>::image() &&
-	task_.ssize() >= ssize &&
-	task_.psize() >= psize &&
-	task_.isize() >= isize &&
-	task_.osize() >= osize &&
-	task_.tsize() >= tsize)
-      return task_; // reuse it !
-    else if (task_) task_.destroy();
-    task_ = alf_->create_task(Task_map<O, S>::image(),
- 			      ssize, psize, isize, osize, tsize);
-    return task_;
+    return alf_->create_task(Task_map<O, S>::image(),
+			     ssize, psize, isize, osize, tsize);
   }
 
   length_type num_spes() { return num_spes_; }
@@ -107,7 +98,6 @@
   static Task_manager *instance_;
 
   ALF*        alf_;
-  Task        task_;
   length_type num_spes_;
 };
 
Index: src/vsip/opt/cbe/ppu/alf.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/alf.cpp	(revision 213283)
+++ src/vsip/opt/cbe/ppu/alf.cpp	(working copy)
@@ -11,6 +11,7 @@
 */
 
 #include "alf.hpp"
+#include <cml/ppu/alf_cache.h>
 #include <iostream>
 
 namespace vsip
@@ -30,36 +31,30 @@
     osize_(osize),
     tsize_(tsize)
 {
-    int status = alf_task_desc_create(alf, ALF_ACCEL_TYPE_SPE, &desc_);
-    assert(status >= 0);
-    alf_task_desc_set_int32(desc_, ALF_TASK_DESC_PARTITION_ON_ACCEL, 1);
-    alf_task_desc_set_int32(desc_, ALF_TASK_DESC_TSK_CTX_SIZE, 0);
-    alf_task_desc_set_int32(desc_, ALF_TASK_DESC_WB_PARM_CTX_BUF_SIZE, psize);
-    alf_task_desc_set_int32(desc_, ALF_TASK_DESC_WB_IN_BUF_SIZE, isize);
-    alf_task_desc_set_int32(desc_, ALF_TASK_DESC_WB_OUT_BUF_SIZE, osize);
-    alf_task_desc_set_int32(desc_, ALF_TASK_DESC_NUM_DTL_ENTRIES, tsize);
-    alf_task_desc_set_int32(desc_, ALF_TASK_DESC_MAX_STACK_SIZE, ssize);
-    typedef unsigned long ul;
-    alf_task_desc_set_int64(desc_, ALF_TASK_DESC_ACCEL_IMAGE_REF_L, (ul) image_);
-    alf_task_desc_set_int64(desc_, ALF_TASK_DESC_ACCEL_LIBRARY_REF_L, (ul) "svpp_kernels.so");
-    alf_task_desc_set_int64(desc_, ALF_TASK_DESC_ACCEL_KERNEL_REF_L, (ul) "kernel");
-    alf_task_desc_set_int64(desc_, ALF_TASK_DESC_ACCEL_INPUT_DTL_REF_L, (ul) "input");
-    alf_task_desc_set_int64(desc_, ALF_TASK_DESC_ACCEL_OUTPUT_DTL_REF_L, (ul) "output");
-    // FIXME: this should be fetched
-    status = alf_task_create(desc_, 0, spes, ALF_TASK_ATTR_SCHED_FIXED, 0, &task_);
-    assert(status >= 0);
+  (void)spes;
+  task_desc_handle_t desc;
+
+  cached_alf_task_desc_create(&desc);
+  desc->tsk_ctx_size           = 0;
+  desc->wb_parm_ctx_buf_size   = psize;
+  desc->wb_in_buf_size         = isize;
+  desc->wb_out_buf_size        = osize;
+  desc->num_dtl_entries        = tsize;
+  desc->max_stack_size         = ssize;
+  desc->accel_image_ref_l      = image_;
+  desc->accel_library_ref_l    = "svpp_kernels.so";
+  desc->accel_kernel_ref_l     = "kernel";
+  desc->accel_input_dtl_ref_l  = "input";
+  desc->accel_output_dtl_ref_l = "output";
+
+  int status = cached_alf_task_create(alf, desc, &task_);
+  assert(status >= 0);
 }
 
 void Task::destroy()
 {
-  int status = alf_task_finalize(task_);
-  assert(status >= 0);
-  status = alf_task_wait(task_, -1);
-  assert(status >= 0);
-  status = alf_task_destroy(task_);
-  assert(status >= 0);
-  status = alf_task_desc_destroy(desc_);
-  assert(status >= 0);
+  if (task_)
+    cached_alf_task_destroy(task_);
 }
 
 } // namespace vsip::impl::cbe
Index: src/vsip/opt/cbe/ppu/alf.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/alf.hpp	(revision 213283)
+++ src/vsip/opt/cbe/ppu/alf.hpp	(working copy)
@@ -90,7 +90,7 @@
 public:
   Task()
     : image_(0), ssize_(0), psize_(0), isize_(0), osize_(0), tsize_(0), task_(0) {}
-  ~Task() {}
+  ~Task() { destroy(); }
   Task(char const *image, length_type ssize, length_type psize,
        length_type isize, length_type osize, length_type tsize,
        alf_handle_t, unsigned int spes);
Index: src/vsip/opt/cbe/ppu/task_manager.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/task_manager.cpp	(revision 213283)
+++ src/vsip/opt/cbe/ppu/task_manager.cpp	(working copy)
@@ -34,7 +34,6 @@
 
 Task_manager::~Task_manager()
 {
-  if (task_) task_.destroy();
   delete alf_;
 }
 
Index: src/vsip/opt/cbe/cml/matvec.hpp
===================================================================
--- src/vsip/opt/cbe/cml/matvec.hpp	(revision 213283)
+++ src/vsip/opt/cbe/cml/matvec.hpp	(working copy)
@@ -288,7 +288,7 @@
     Ext_data_cost<Block1>::value == 0 &&
     Ext_data_cost<Block2>::value == 0;
 
-  static bool rt_valid(Block0& r, Block1 const& a, Block2 const& b)
+  static bool rt_valid(Block0& /*r*/, Block1 const& a, Block2 const& /*b*/)
   {
     Ext_data<Block1> ext_a(const_cast<Block1&>(a));
 
Index: tests/regressions/alf_caching.cpp
===================================================================
--- tests/regressions/alf_caching.cpp	(revision 0)
+++ tests/regressions/alf_caching.cpp	(revision 0)
@@ -0,0 +1,73 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/regressions/alf_caching.cpp
+    @author  Jules Bergmann
+    @date    2008-07-01
+    @brief   VSIPL++ Library: Test switching between CML and VSIPL++
+             ALF tasks.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/opt/diag/eval.hpp>
+
+#include <vsip_csl/test.hpp>
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
+void
+test(length_type size)
+{
+  length_type loop = 10;
+
+  Matrix<T> M(size, size, T(0)); M.diag() = T(2);
+  Vector<T> a(size,    T(3));
+  Vector<T> b(size,    T(4));
+  Vector<T> c(size,    T(5));
+  Vector<T> d(size,    T(5));
+
+#if DEBUG
+  vsip::impl::diagnose_eval_list_std(c, a * b);
+#endif
+
+  for (index_type l=0; l<loop; ++l)
+  {
+    c = T(0);
+    d = T(0);
+
+    d = prod(M, a);
+    test_assert(d.get(0) == T(2*3));
+
+    c = a * b;
+    test_assert(c.get(0) == T(3*4));
+  }
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  typedef complex<float> Cf;
+
+  vsipl init(argc, argv);
+
+  test<float>(128*16);
+}
