Index: ChangeLog
===================================================================
--- ChangeLog	(revision 235873)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2009-02-05  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/ukernel.hpp: Use ALF inout buffers for ukernels.
+	* src/vsip/opt/ukernel/cbe_accel/alf_base.hpp: Likewise.
+
 2009-02-04  Brooks Moses  <brooks@codesourcery.com>
 
 	* GNUmakefile.in (clean): Add automatic cleanup of $(libs)
Index: src/vsip/opt/ukernel.hpp
===================================================================
--- src/vsip/opt/ukernel.hpp	(revision 235873)
+++ src/vsip/opt/ukernel.hpp	(working copy)
@@ -845,7 +845,7 @@
     char const* image =
       Ukernel_task_map<FuncT, void()>::image();
     Task task = mgr->alf_handle()->create_task(
-      library, image, stack_size, psize, isize, osize, 0, dtl_size);
+      library, image, stack_size, psize, 0, 0, isize + osize, dtl_size);
 
     for (index_type i=0; i<spes; ++i)
     {
@@ -922,7 +922,7 @@
     char const* image =
       Ukernel_task_map<FuncT, void(ptr0_type, ptr2_type)>::image();
     Task task = mgr->alf_handle()->create_task(
-      library, image, stack_size, psize, isize, osize, 0, dtl_size);
+      library, image, stack_size, psize, 0, 0, isize + osize, dtl_size);
 
     for (index_type i=0; i<spes && i<chunks; ++i)
     {
@@ -1031,7 +1031,7 @@
     char const* image =
       Ukernel_task_map<FuncT, void(ptr0_type, ptr1_type, ptr2_type)>::image();
     Task task = mgr->alf_handle()->create_task(
-      library, image, stack_size, psize, isize, osize, 0, dtl_size);
+      library, image, stack_size, psize, 0, 0, isize + osize, dtl_size);
 
     ukp.nspe       = std::min(spes, chunks);
 
@@ -1141,7 +1141,7 @@
     char const* image =
       Ukernel_task_map<FuncT, void(ptr0_type, ptr1_type, ptr2_type, ptr3_type)>::image();
     Task task = mgr->alf_handle()->create_task(
-      library, image, stack_size, psize, isize, osize, 0, dtl_size);
+      library, image, stack_size, psize, 0, 0, isize + osize, dtl_size);
 
     ukp.nspe       = std::min(spes, chunks);
 
Index: src/vsip/opt/ukernel/cbe_accel/alf_base.hpp
===================================================================
--- src/vsip/opt/ukernel/cbe_accel/alf_base.hpp	(revision 235873)
+++ src/vsip/opt/ukernel/cbe_accel/alf_base.hpp	(working copy)
@@ -134,21 +134,19 @@
 };
 
 
-template <typename PtrT>
 void
-add_stream(
-  void*        entries,
-  Uk_stream&   stream,
-  unsigned int iter, 
-  unsigned int iter_count)
+stream_buffer_size(
+  Uk_stream&    stream,
+  unsigned int  iter, 
+  unsigned int  iter_count,
+  unsigned int& num_lines,
+  unsigned int& line_size,
+  int&          offset,
+  char          ptype)
 {
-  alf_data_addr64_t ea;
   unsigned int chunk_idx;
   unsigned int chunk_idx0;
   unsigned int chunk_idx1;
-  int offset;
-  unsigned int num_lines;
-  unsigned int line_size;
 
   if (stream.dim == 3)
   {
@@ -225,12 +223,6 @@
   line_size = INCREASE_TO_DMA_SIZE_IN_FLOATS(line_size);
 
 #if DEBUG_ALF_BASE
-  char ptype = 
-    Type_equal<PtrT, float*>::value ? 'S' :
-      Type_equal<PtrT, std::complex<float>*>::value ? 'C' :
-        Type_equal<PtrT, std::pair<float*, float*> >::value ? 'Z' :
-          Type_equal<PtrT, unsigned int*>::value ? 'I' :
-            '?';
   printf("add_stream: type: %c  chunk: %d (%d/%d, %d/%d)  size: %d/%d x %d/%d  stride: %d, %d\n",
     ptype, chunk_idx,
     chunk_idx0, stream.num_chunks0,
@@ -239,6 +231,32 @@
     stream.stride0, stream.stride1);
 #endif
 
+}
+
+
+template <typename PtrT>
+void
+add_stream(
+  void*        entries,
+  Uk_stream&   stream,
+  unsigned int iter, 
+  unsigned int iter_count)
+{
+  alf_data_addr64_t ea;
+  int offset;
+  unsigned int num_lines;
+  unsigned int line_size;
+
+  char ptype =
+    Type_equal<PtrT, float*>::value ? 'S' :
+      Type_equal<PtrT, std::complex<float>*>::value ? 'C' :
+        Type_equal<PtrT, std::pair<float*, float*> >::value ? 'Z' :
+          Type_equal<PtrT, unsigned int*>::value ? 'I' :
+            '?';
+
+  stream_buffer_size(stream, iter, iter_count, num_lines, line_size, offset,
+		     ptype);
+
   if (Type_equal<PtrT, float*>::value)
   {
     ea = stream.addr + offset;
@@ -511,8 +529,7 @@
   kernel(
     KernelT&     ukobj,
     param_type*  /*ukp*/,
-    void*        /*in*/,
-    void*        /*out*/,
+    void*        /*inout*/,
     unsigned int /*iter*/, 
     unsigned int /*iter_count*/)
   {
@@ -533,9 +550,14 @@
     unsigned int iter_count)
   {
     typedef typename KernelT::in0_type  in0_type;
+    typedef typename KernelT::out0_type out0_type;
 
+    Pinfo p_out;
+    set_chunk_info(ukp->out_stream[0], p_out, iter);
+    size_t off1 = Byte_offset<out0_type>::index(p_out.l_total_size);
+
     // Transfer input A.
-    ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+    ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OVL_IN, off1);
 
     add_stream<in0_type>(entries, ukp->in_stream[0], iter, iter_count);
 
@@ -546,8 +568,7 @@
   kernel(
     KernelT&     ukobj,
     param_type*  ukp,
-    void*        in,
-    void*        out,
+    void*        inout,
     unsigned int iter, 
     unsigned int iter_count)
   {
@@ -559,9 +580,11 @@
     set_chunk_info(ukp->in_stream[0], p_in,   iter);
     set_chunk_info(ukp->out_stream[0], p_out, iter);
 
+    size_t off1 = Byte_offset<out0_type>::index(p_out.l_total_size);
+
     ukobj.compute(
-      To_ptr<in0_type >::offset(in,  0, p_in.l_total_size),
-      To_ptr<out0_type>::offset(out, 0, p_out.l_total_size),
+      To_ptr<in0_type >::offset(inout, off1, p_in.l_total_size),
+      To_ptr<out0_type>::offset(inout,    0, p_out.l_total_size),
       p_in, p_out);
   }
 };
@@ -578,9 +601,14 @@
   {
     typedef typename KernelT::in0_type  in0_type;
     typedef typename KernelT::in1_type  in1_type;
+    typedef typename KernelT::out0_type out0_type;
 
-    ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+    Pinfo p_out;
+    set_chunk_info(ukp->out_stream[0], p_out, iter);
+    size_t off1 = Byte_offset<out0_type>::index(p_out.l_total_size);
 
+    ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OVL_IN, off1);
+
     add_stream<in0_type>(entries, ukp->in_stream[0], iter, iter_count);
     add_stream<in1_type>(entries, ukp->in_stream[1], iter, iter_count);
 
@@ -590,9 +618,8 @@
   static void
   kernel(
     KernelT&     ukobj,
-    param_type* ukp,
-    void*       in,
-    void*       out,
+    param_type*  ukp,
+    void*        inout,
     unsigned int iter, 
     unsigned int iter_count)
   {
@@ -606,12 +633,13 @@
     set_chunk_info(ukp->in_stream[1],  p_in1, iter);
     set_chunk_info(ukp->out_stream[0], p_out, iter);
 
-    size_t offset1 = Byte_offset<in0_type>::index(p_in0.l_total_size);
+    size_t off1 = Byte_offset<out0_type>::index(p_out.l_total_size);
+    size_t off2 = Byte_offset<in0_type>::index(p_in0.l_total_size) + off1;
 
     ukobj.compute(
-      To_ptr<in0_type >::offset(in,  0,       p_in0.l_total_size),
-      To_ptr<in1_type >::offset(in,  offset1, p_in1.l_total_size),
-      To_ptr<out0_type>::offset(out, 0,       p_out.l_total_size),
+      To_ptr<in0_type >::offset(inout, off1, p_in0.l_total_size),
+      To_ptr<in1_type >::offset(inout, off2, p_in1.l_total_size),
+      To_ptr<out0_type>::offset(inout, 0,    p_out.l_total_size),
       p_in0, p_in1, p_out);
   }
 };
@@ -630,15 +658,20 @@
   {
     typedef typename KernelT::in0_type  in0_type;
     typedef typename KernelT::in1_type  in1_type;
+    typedef typename KernelT::out0_type out0_type;
 
-    ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
-
     if (iter < ukp->pre_chunks)
     {
+      ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OVL_IN, 0);
       add_stream<in0_type>(entries, ukp->in_stream[0], iter, iter_count);
     }
     else
     {
+      Pinfo p_out;
+      set_chunk_info(ukp->out_stream[0], p_out, iter);
+      size_t off1 = Byte_offset<out0_type>::index(p_out.l_total_size);
+
+      ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OVL_IN, off1);
       add_stream<in1_type>(entries, ukp->in_stream[1],
 			   iter - ukp->pre_chunks, 
 			   iter_count - ukp->pre_chunks);
@@ -651,8 +684,7 @@
   kernel(
     KernelT&     ukobj,
     param_type*  ukp,
-    void*        in,
-    void*        out,
+    void*        inout,
     unsigned int iter, 
     unsigned int iter_count)
   {
@@ -666,7 +698,7 @@
     {
       set_chunk_info(ukp->in_stream[0],  p_in0, iter);
       ukobj.pre_compute(
-	To_ptr<in0_type >::offset(in,  0, p_in0.l_total_size),
+	To_ptr<in0_type >::offset(inout,  0, p_in0.l_total_size),
 	p_in0);
     }
     else
@@ -675,9 +707,10 @@
       // one used above
       set_chunk_info(ukp->in_stream[1],  p_in1, iter - 1);
       set_chunk_info(ukp->out_stream[0], p_out, iter - 1);
+      size_t off1 = Byte_offset<out0_type>::index(p_out.l_total_size);
       ukobj.compute(
-	To_ptr<in1_type >::offset(in,  0, p_in1.l_total_size),
-	To_ptr<out0_type>::offset(out, 0, p_out.l_total_size),
+	To_ptr<in1_type >::offset(inout, off1, p_in1.l_total_size),
+	To_ptr<out0_type>::offset(inout, 0,    p_out.l_total_size),
 	p_in1, p_out);
     }
   }
@@ -697,9 +730,14 @@
     typedef typename KernelT::in0_type  in0_type;
     typedef typename KernelT::in1_type  in1_type;
     typedef typename KernelT::in2_type  in2_type;
+    typedef typename KernelT::out0_type out0_type;
 
-    ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
+    Pinfo p_out;
+    set_chunk_info(ukp->out_stream[0], p_out, iter);
+    size_t off1 = Byte_offset<out0_type>::index(p_out.l_total_size);
 
+    ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OVL_IN, off1);
+
     add_stream<in0_type>(entries, ukp->in_stream[0], iter, iter_count);
     add_stream<in1_type>(entries, ukp->in_stream[1], iter, iter_count);
     add_stream<in2_type>(entries, ukp->in_stream[2], iter, iter_count);
@@ -710,9 +748,8 @@
   static void
   kernel(
     KernelT&     ukobj,
-    param_type* ukp,
-    void*       in,
-    void*       out,
+    param_type*  ukp,
+    void*        inout,
     unsigned int iter, 
     unsigned int iter_count)
   {
@@ -731,8 +768,9 @@
     // Pointers must be extracted from knowledge of the stream sizes as ALF
     // transfers all the input data into one contiguous space.
 
-    size_t offset1 = Byte_offset<in0_type>::index(p_in0.l_total_size);
-    size_t offset2 = offset1 + Byte_offset<in1_type>::index(p_in1.l_total_size);
+    size_t off1 = Byte_offset<out0_type>::index(p_out.l_total_size);
+    size_t off2 = Byte_offset<in0_type>::index(p_in0.l_total_size) + off1;
+    size_t off3 = Byte_offset<in1_type>::index(p_in1.l_total_size) + off2;
 
     // The To_ptr<> struct calculates the correct offset for a given
     // pointer type (scalar, interleaved complex or split complex).  The 
@@ -741,10 +779,10 @@
     // offsets in the case of split complex.
 
     ukobj.compute(
-      To_ptr<in0_type >::offset(in,  0,       p_in0.l_total_size),
-      To_ptr<in1_type >::offset(in,  offset1, p_in1.l_total_size),
-      To_ptr<in2_type >::offset(in,  offset2, p_in2.l_total_size),
-      To_ptr<out0_type>::offset(out, 0,       p_out.l_total_size),
+      To_ptr<in0_type >::offset(inout, off1, p_in0.l_total_size),
+      To_ptr<in1_type >::offset(inout, off2, p_in1.l_total_size),
+      To_ptr<in2_type >::offset(inout, off3, p_in2.l_total_size),
+      To_ptr<out0_type>::offset(inout, 0,    p_out.l_total_size),
       p_in0, p_in1, p_in2, p_out);
   }
 };
@@ -785,7 +823,7 @@
     }
     
     // Transfer output Z.
-    ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
+    ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OVL_OUT, 0);
     
     add_stream<out0_type>(entries, ukp->out_stream[0], iter, iter_count);
     
@@ -851,7 +889,7 @@
     ukobj.init(rman, ukp->kernel_params);
   }
 
-  Kernel_helper<kernel_type>::kernel(ukobj, ukp, in, out, iter, iter_count);
+  Kernel_helper<kernel_type>::kernel(ukobj, ukp, inout, iter, iter_count);
 
   if (iter == iter_count-1)
     ukobj.fini(rman);
