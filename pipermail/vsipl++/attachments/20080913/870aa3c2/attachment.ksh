Index: ChangeLog
===================================================================
--- ChangeLog	(revision 221241)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2008-09-13  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/cbe/ppu/alf.cpp: Use cached_alf_task_desc_init to
+	  initialize task_desc.
+
+2008-09-13  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/cbe/ppu/bindings.hpp: Add tunable_threshold to
 	  vmul evaluator.
 	* src/vsip/opt/cbe/cml/transpose.hpp: Add tunable_threshold to
Index: src/vsip/opt/cbe/ppu/alf.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/alf.cpp	(revision 220851)
+++ src/vsip/opt/cbe/ppu/alf.cpp	(working copy)
@@ -34,7 +34,7 @@
   (void)spes;
   task_desc desc;
 
-  desc.tsk_ctx_size           = 0;
+  cached_alf_task_desc_init(desc);
   desc.wb_parm_ctx_buf_size   = psize;
   desc.wb_in_buf_size         = isize;
   desc.wb_out_buf_size        = osize;
@@ -46,7 +46,6 @@
   desc.accel_input_dtl_ref_l  = "input";
   desc.accel_output_dtl_ref_l = "output";
   desc.tsk_ctx_data_type      = ALF_DATA_BYTE;
-  desc.p_task_context_data    = NULL;
 
   int status = cached_alf_task_create(alf, &desc, &task_);
   assert(status >= 0);
