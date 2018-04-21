Index: src/vsip/opt/cbe/ppu/alf.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/alf.hpp	(revision 171286)
+++ src/vsip/opt/cbe/ppu/alf.hpp	(working copy)
@@ -154,10 +154,8 @@
     alf_wb_sync_handle_t hsync;
     alf_wb_sync(&hsync, impl_, ALF_SYNC_BARRIER, 0, 0, 0);
     alf_wb_sync_wait(hsync, -1);
-    alf_wb_sync_destroy(&hsync);
   }
   void wait() { alf_task_wait(impl_, -1);}
-  void abort() { alf_task_abort(&impl_);}
 
 private:
   int type_;
Index: src/vsip/opt/cbe/spu/alf_fconv_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconv_c.c	(revision 171286)
+++ src/vsip/opt/cbe/spu/alf_fconv_c.c	(working copy)
@@ -124,10 +124,10 @@
 
 
 
-int alf_comp_kernel(void volatile *context,
-		    void volatile *params,
-                    void volatile *input,
-                    void volatile *output,
+int alf_comp_kernel(void* context,
+		    void* params,
+                    void* input,
+                    void* output,
                     unsigned int iter,
                     unsigned int iter_max)
 {
Index: src/vsip/opt/cbe/spu/alf_fft_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fft_c.c	(revision 171286)
+++ src/vsip/opt/cbe/spu/alf_fft_c.c	(working copy)
@@ -115,10 +115,10 @@
 }
 
 
-int alf_comp_kernel(void volatile *context,
-		    void volatile *params,
-                    void volatile *input,
-                    void volatile *output,
+int alf_comp_kernel(void* context,
+		    void* params,
+                    void* input,
+                    void* output,
                     unsigned int iter,
                     unsigned int iter_max)
 {
Index: src/vsip/opt/cbe/spu/alf_vmul_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmul_c.c	(revision 171286)
+++ src/vsip/opt/cbe/spu/alf_vmul_c.c	(working copy)
@@ -72,10 +72,10 @@
 
 
 int alf_comp_kernel(
-  void volatile* p_context,
-  void volatile* p_params,
-  void volatile* input,
-  void volatile* output,
+  void* p_context,
+  void* p_params,
+  void* input,
+  void* output,
   unsigned int iter,
   unsigned int n)
 {
Index: src/vsip/opt/cbe/spu/alf_fconv_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconv_split_c.c	(revision 171286)
+++ src/vsip/opt/cbe/spu/alf_fconv_split_c.c	(working copy)
@@ -160,10 +160,10 @@
 
 
 
-int alf_comp_kernel(void volatile *context,
-		    void volatile *params,
-                    void volatile *input,
-                    void volatile *output,
+int alf_comp_kernel(void* context,
+		    void* params,
+                    void* input,
+                    void* output,
                     unsigned int iter,
                     unsigned int iter_max)
 {
Index: src/vsip/opt/cbe/spu/alf_fconvm_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconvm_c.c	(revision 171286)
+++ src/vsip/opt/cbe/spu/alf_fconvm_c.c	(working copy)
@@ -113,10 +113,10 @@
 
 int 
 alf_comp_kernel(
-    void volatile* context,
-    void volatile* params,
-    void volatile* input,
-    void volatile* output,
+    void* context,
+    void* params,
+    void* input,
+    void* output,
     unsigned int   current_count,
     unsigned int   total_count)
 {
Index: src/vsip/opt/cbe/spu/alf_vmul_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmul_split_c.c	(revision 171286)
+++ src/vsip/opt/cbe/spu/alf_vmul_split_c.c	(working copy)
@@ -79,10 +79,10 @@
 
 
 int alf_comp_kernel(
-  void volatile* p_context,
-  void volatile* p_params,
-  void volatile* input,
-  void volatile* output,
+  void* p_context,
+  void* p_params,
+  void* input,
+  void* output,
   unsigned int iter,
   unsigned int n)
 {
Index: src/vsip/opt/cbe/spu/alf_vmmul_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmmul_c.c	(revision 171286)
+++ src/vsip/opt/cbe/spu/alf_vmmul_c.c	(working copy)
@@ -111,10 +111,10 @@
 
 
 int alf_comp_kernel(
-  void volatile* p_context,
-  void volatile* p_params,
-  void volatile* input,
-  void volatile* output,
+  void* p_context,
+  void* p_params,
+  void* input,
+  void* output,
   unsigned int iter,
   unsigned int n)
 {
Index: src/vsip/opt/cbe/spu/alf_vmul_s.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmul_s.c	(revision 171286)
+++ src/vsip/opt/cbe/spu/alf_vmul_s.c	(working copy)
@@ -76,10 +76,10 @@
 
 
 int alf_comp_kernel(
-  void volatile* p_context,
-  void volatile* p_params,
-  void volatile* input,
-  void volatile* output,
+  void* p_context,
+  void* p_params,
+  void* input,
+  void* output,
   unsigned int iter,
   unsigned int n)
 {
Index: src/vsip/opt/cbe/spu/alf_fconvm_split_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconvm_split_c.c	(revision 171286)
+++ src/vsip/opt/cbe/spu/alf_fconvm_split_c.c	(working copy)
@@ -141,10 +141,10 @@
 
 
 
-int alf_comp_kernel(void volatile *context,
-		    void volatile *params,
-                    void volatile *input,
-                    void volatile *output,
+int alf_comp_kernel(void* context,
+		    void* params,
+                    void* input,
+                    void* output,
                     unsigned int iter,
                     unsigned int iter_max)
 {
