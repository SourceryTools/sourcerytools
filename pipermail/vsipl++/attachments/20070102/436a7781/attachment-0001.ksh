Index: src/vsip/opt/cbe/ppu/vmul.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/vmul.cpp	(revision 0)
+++ src/vsip/opt/cbe/ppu/vmul.cpp	(revision 0)
@@ -0,0 +1,170 @@
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/ppu/vmul.hpp
+    @author  Don McCoy
+    @date    2006-12-31
+    @brief   VSIPL++ Library: Vectory multiply for Cell BE
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/math.hpp>
+#include <vsip/opt/cbe/vmul.h>
+#include <vsip/opt/cbe/ppu/vmul.hpp>
+#include <libspe.h>
+#include <iostream>
+#include <cerrno>
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+extern spe_program_handle_t vmul_spu;
+
+namespace vsip
+{
+namespace impl
+{
+namespace cbe
+{
+namespace ppu
+{
+
+
+Elementwise_vmul::Elementwise_vmul()
+{
+  gid_ = spe_create_group(SCHED_OTHER, 0, 1);
+  if (gid_ == NULL) 
+  {
+    std::cerr << "Failed spe_create_group(errno=" << errno << ")" << std::endl;
+    return;
+  }
+
+  if (spe_group_max (gid_) < 1) 
+  {
+    std::cerr << "System doesn't have a working SPE.  I'm leaving." << std::endl;
+    return;
+  }
+
+  // allocate the SPE task
+  speid_ = spe_create_thread (gid_, &vmul_spu, 0, NULL, -1, 0);
+  if (speid_ == NULL) 
+  {
+    std::cerr << "FAILED: spe_create_thread(num=0, errno=" << errno << ")" << std::endl;
+    return;
+  }
+}
+
+Elementwise_vmul::~Elementwise_vmul()
+{
+  while (spe_stat_in_mbox (speid_) < 1);
+  spe_write_in_mbox(speid_, cmd_terminate_thread);
+
+  // wait for the single SPE to complete
+  spe_wait(speid_, &status_, 0);
+
+  // returns the SPE status
+  if (WIFEXITED(status_)) 
+  {
+    if (WEXITSTATUS(status_)) 
+    {
+      std::cerr << "FAILED: SPE returned a non-zero exit status (" << status_ << ")" << std::endl;
+      return;
+    }
+  } 
+  else
+  {
+    std::cerr << "FAILED: SPE abnormally terminated" << std::endl;
+  }
+}
+
+
+
+static Elementwise_vmul elementwise_vmul;
+
+
+template <typename T>
+void Elementwise_vmul::apply(T const *A, T const *B, T *R, length_type len)
+{
+  volatile command_block cb __attribute__ ((aligned (128)));
+  volatile data_block db[3] __attribute__ ((aligned (128)));
+
+  speid_t speid = elementwise_vmul.speid_;
+
+  // pass data blocks to SPE
+  {
+    db[0].element_size = sizeof(float);
+    db[0].num_elements = len;
+    db[0].id = 'A';
+    db[0].prefetch = 1;  // input, read ahead
+    db[0].addr.ull = reinterpret_cast<unsigned long long>(A);
+
+    while (spe_stat_in_mbox (speid) < 2);
+    spe_write_in_mbox(speid, cmd_operand_data);
+    spe_write_in_mbox(speid, (unsigned long long) &db[0]);
+  }
+
+  {
+    db[1].element_size = sizeof(float);
+    db[1].num_elements = len;
+    db[1].id = 'B';
+    db[1].prefetch = 1;  // input, read ahead
+    db[1].addr.ull = reinterpret_cast<unsigned long long>(B);
+
+    while (spe_stat_in_mbox (speid) < 2);
+    spe_write_in_mbox(speid, cmd_operand_data);
+    spe_write_in_mbox(speid, (unsigned long long) &db[1]);
+  }
+
+  {
+    db[2].element_size = sizeof(float);
+    db[2].num_elements = len;
+    db[2].id = 'R';
+    db[2].prefetch = 0;   // output, do not read
+    db[2].addr.ull = reinterpret_cast<unsigned long long>(R);
+
+    while (spe_stat_in_mbox (speid) < 2);
+    spe_write_in_mbox(speid, cmd_operand_data);
+    spe_write_in_mbox(speid, (unsigned long long) &db[2]);
+  }
+
+
+  // now do the multiply
+  {
+    cb.op = vector_multiply;
+    cb.result_id = 'R';
+    cb.op_A_id = 'A';
+    cb.op_B_id = 'B';
+    cb.completed = 0;
+
+    while (spe_stat_in_mbox (speid) < 2);
+    spe_write_in_mbox(speid, cmd_elementwise_compute);
+    spe_write_in_mbox(speid, (unsigned long long) &cb);
+  }
+
+  // wait
+  while (cb.completed == 0);
+
+  // flush the SPE's compute space 
+  {
+    while (spe_stat_in_mbox (speid) < 2);    
+    spe_write_in_mbox(speid, cmd_flush_blocks);
+  }
+
+}
+
+template void Elementwise_vmul::apply(float const *A, float const *B, float *R, length_type len);
+
+
+
+
+} // namespace vsip::impl::cbe::ppu
+} // namespace vsip::impl::cbe
+} // namespace vsip::impl
+} // namespace vsip
Index: src/vsip/opt/cbe/ppu/vmul.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/vmul.hpp	(revision 0)
+++ src/vsip/opt/cbe/ppu/vmul.hpp	(revision 0)
@@ -0,0 +1,68 @@
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/ppu/vmul.hpp
+    @author  Don McCoy
+    @date    2006-12-31
+    @brief   VSIPL++ Library: Vectory multiply for Cell BE
+*/
+
+#ifndef VSIP_OPT_CBE_PPU_VMUL_HPP
+#define VSIP_OPT_CBE_PPU_VMUL_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+
+#if VSIP_IMPL_CBE_SDK
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <libspe.h>
+#include <vsip/support.hpp>
+#include <vsip/opt/cbe/vmul.h>
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
+namespace ppu
+{
+
+class Elementwise_vmul
+{
+public:
+  Elementwise_vmul();
+  ~Elementwise_vmul();
+
+  template <typename T>
+  static void apply(T const *A, T const *B, T *R, length_type len);
+
+private:
+  spe_gid_t gid_;
+  speid_t speid_;
+  int status_;
+};
+
+
+} // namespace vsip::impl::cbe::ppu
+} // namespace vsip::impl::cbe
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_CBE_SDK
+
+#endif // VSIP_OPT_CBE_PPU_VMUL_HPP
Index: src/vsip/opt/cbe/ppu/bindings.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/bindings.cpp	(revision 159105)
+++ src/vsip/opt/cbe/ppu/bindings.cpp	(working copy)
@@ -16,6 +16,7 @@
 
 #include <vsip/math.hpp>
 #include <vsip/opt/cbe/ppu/bindings.hpp>
+#include <vsip/opt/cbe/ppu/vmul.hpp>
 #include <libspe.h>
 #include <iostream>
 #include <cerrno>
@@ -36,37 +37,9 @@
 {
 
 template <typename T>
-struct vmul_args
-{
-  vmul_args(T const *a, T const *b, T *r, length_type l)
-    : A(a), B(b), R(r), length(l) {}
-  T const *A;
-  T const *B;
-  T *R;
-  length_type length;
-};
-
-template <typename T>
 void vmul(T const *A, T const *B, T *R, length_type len)
 {
-  // R = A + B
-  if (len > 0)
-  {
-    vmul_args<T> args(A, B, R, len);
-    speid_t spe_id = spe_create_thread(SPE_DEF_GRP, &vmul_spu,
-                                       &args, 0, -1, 0);
-    if (spe_id == 0)
-    {
-      std::cerr << "Failed spu_create_thread(rc=" << spe_id << ", errno=" 
-                << errno << ')' << std::endl;
-//       return 1;
-    }
-
-    int status = 0;
-    (void)spe_wait(spe_id, &status, 0);
-    std::cout << "The program has successfully executed." << std::endl;
-//     return 0;
-  }
+  Elementwise_vmul::apply(A, B, R, len);
 }
 
 template void vmul(float const *A, float const *B, float *R, length_type len);
Index: src/vsip/opt/cbe/spu/vmul.cpp
===================================================================
--- src/vsip/opt/cbe/spu/vmul.cpp	(revision 159105)
+++ src/vsip/opt/cbe/spu/vmul.cpp	(working copy)
@@ -1,5 +1,5 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
-
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
+ 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
@@ -10,24 +10,146 @@
     @brief   VSIPL++ Library: vector-multiply kernel.
 */
 
-#include <vsip/support.hpp>
+#include <spu_mfcio.h>
+#include <stdio.h>
+#include <string.h>
+#include <vsip/opt/cbe/vmul.h>
 
-using namespace vsip;
 
-typedef float T;
+data_block db __attribute__ ((aligned (128)));
+command_block cb __attribute__ ((aligned (128)));
 
-struct vadd_args
+// These are used for DMA buffer management (in the Local Store)
+data_block db_list[256];    // store data blocks (operands)
+void* ls_addr[256];         // store associated LS addresses
+
+// This is the actual portion of the LS reserved for computation
+#define COMPUTE_BUFFER_SIZE  (64*1024)
+char ls_data[COMPUTE_BUFFER_SIZE] __attribute__ ((aligned (128)));
+unsigned int ls_index = 0;
+
+
+
+int main(unsigned long long speid, addr64 argp, addr64 envp) 
 {
-  vadd_args(T *a, T *b, T *r, length_type l)
-    : A(a), B(b), R(r), length(l) {}
-  T *A;
-  T *B;
-  T *R;
-  length_type length;
-};
+  int i;
+  int bytes_avail;
+  int transfer_size;
 
-int main(vadd_args *args)
-{
-  printf("Hello Cell (%d)\n", args->length);
+  argp = argp;  /* eliminate warnings */
+  envp = envp;
+
+  memset(db_list, 0, sizeof(db_list));
+  memset(ls_addr, 0, sizeof(ls_addr));
+
+  unsigned int opcode;
+  addr64 ea;
+
+  while (1)
+  {
+    opcode = (unsigned int) spu_read_in_mbox ();
+
+    switch (opcode)
+    {
+    case cmd_operand_data:
+
+      // The next word gives us the address of the descriptor for the 
+      // data block, which is of a known size.  Fetch the descriptor
+      // and wait for it to arrive.
+      ea.ull = spu_read_in_mbox();
+      mfc_get(&db, ea.ull, sizeof(db), 31, 0, 0);
+      mfc_write_tag_mask(1<<31);
+      mfc_read_tag_status_all();
+
+
+      // DMA the data from system memory to our local store buffer.
+
+      // check space remaining
+      bytes_avail = COMPUTE_BUFFER_SIZE - ls_index;
+      transfer_size = db.element_size * db.num_elements;
+      if (bytes_avail < transfer_size)
+      {
+	printf( "SPU %llu: Error: insufficient space for data block!\n", speid );
+	break;
+      }
+      // store the entry, start the DMA, update the index and wait
+      db_list[db.id] = db;
+      ls_addr[db.id] = &ls_data[ls_index];
+      ls_index += transfer_size;
+
+      if (db.prefetch)
+      {
+	mfc_get(ls_addr[db.id], db.addr.ull, transfer_size, 31, 0, 0);
+	mfc_read_tag_status_all();
+      }
+      break;
+
+    case cmd_elementwise_compute:
+    {
+      // The next word gives us the address of the descriptor for the 
+      // command block, which is of a known size.  Fetch the descriptor
+      // and wait for it to arrive.
+      ea.ull = spu_read_in_mbox();
+      mfc_get(&cb, ea.ull, sizeof(cb), 31, 0, 0);
+      mfc_write_tag_mask(1<<31);
+      mfc_read_tag_status_all();
+
+      float* A = static_cast<float*>(ls_addr[cb.op_A_id]);
+      float* B = static_cast<float*>(ls_addr[cb.op_B_id]);
+      float* C = static_cast<float*>(ls_addr[cb.result_id]);
+      if (!A || !B || !C)
+      {
+	printf( "SPU %llu: Error: missing data blocks!\n", speid );
+      }
+      else
+      {
+	int size = db_list[cb.op_A_id].num_elements;
+	if ( size != db_list[cb.op_B_id].num_elements ||
+	     size != db_list[cb.op_B_id].num_elements )
+        {
+	  printf( "SPU %llu: Error: incongruent data blocks!\n", speid );
+	}
+	else
+        {
+	  // Do the actual computation
+	  for (i = 0; i < size; ++i)
+	    C[i] = A[i] * B[i];
+	}
+      }
+
+      // Push the result data back to main memory
+      data_block *db = &db_list[cb.result_id];
+      transfer_size = db->element_size * db->num_elements;
+      mfc_put(ls_addr[cb.result_id], db->addr.ull, transfer_size, 31, 0, 0);
+      mfc_read_tag_status_all();
+
+      // Set the completion flag in the command block as an acknowledgement 
+      // signal and DMA it back to the PPE.
+      cb.completed = 1;
+      mfc_put((void *)&cb, ea.ui[1], sizeof(cb), 3, 0, 0);
+      mfc_write_tag_mask(1 << 3);
+      mfc_read_tag_status_all();
+    }
+    break;
+
+    case cmd_flush_blocks:
+    {
+      memset(db_list, 0, sizeof(db_list));
+      memset(ls_addr, 0, sizeof(ls_addr));
+      ls_index = 0;
+    }
+    break;
+
+    case cmd_terminate_thread:
+    {
+      return 0;
+    }
+    break;
+
+    default:
+      printf("SPU %llu: Error: unknown opcode %d\n", speid, opcode);
+      break;
+    }
+  }
   return 0;
 }
Index: src/vsip/opt/cbe/vmul.h
===================================================================
--- src/vsip/opt/cbe/vmul.h	(revision 0)
+++ src/vsip/opt/cbe/vmul.h	(revision 0)
@@ -0,0 +1,60 @@
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/vmul.h
+    @author  Don McCoy
+    @date    2006-12-31
+    @brief   VSIPL++ Library: Vectory multiply for Cell BE
+*/
+
+#ifndef VSIP_OPT_CBE_VMUL_H
+#define VSIP_OPT_CBE_VMUL_H
+
+enum spe_function_type
+{
+  cmd_terminate_thread = 0x1000,
+  cmd_operand_data,
+  cmd_elementwise_compute,
+  cmd_flush_blocks
+};
+
+typedef enum
+{
+  nop = 0,
+  vector_multiply
+} op_type;
+
+
+typedef union
+{
+  unsigned long long ull;
+  unsigned int ui[2];
+  void const* p;
+} addr64;
+
+
+// keep all DMA-able structures sized in multiples of 128-bits
+
+typedef struct                  // used with operand_data
+{
+  unsigned int element_size;
+  unsigned short num_elements;
+  unsigned char id;
+  unsigned char prefetch;
+  addr64 addr;
+} data_block; 
+
+typedef struct                  // used with elementwise_compute
+{
+  op_type op;
+  unsigned char result_id;
+  unsigned char op_A_id;
+  unsigned char op_B_id;
+  unsigned char completed;
+  unsigned int pad[2];
+} command_block;
+
+#endif // VSIP_OPT_CBE_VMUL_H
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 159105)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -38,6 +38,7 @@
 endif
 ifdef enable_cbe_sdk
 src_vsip_cxx_sources += $(srcdir)/src/vsip/opt/cbe/ppu/bindings.cpp
+src_vsip_cxx_sources += $(srcdir)/src/vsip/opt/cbe/ppu/vmul.cpp
 endif
 ifdef VSIP_IMPL_CVSIP_FFT
 src_vsip_cxx_sources += $(srcdir)/src/vsip/core/cvsip/fft.cpp
