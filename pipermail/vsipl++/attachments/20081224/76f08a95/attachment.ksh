Index: ChangeLog
===================================================================
--- ChangeLog	(revision 231556)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2008-12-24  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/cbe/spu/alf_vmul_s.c: Stride from PPU is in elements
+	  (floats), not bytes.
+	* tests/regressions/large_vmul.cpp: Add regression test for above.
+
 2008-12-16  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/cbe/ppu/task_manager.hpp: Pass kernel library name.
Index: tests/regressions/large_vmul.cpp
===================================================================
--- tests/regressions/large_vmul.cpp	(revision 230289)
+++ tests/regressions/large_vmul.cpp	(working copy)
@@ -46,8 +46,8 @@
   Vector<T, block_type> Z(size);
 
   Rand<T> gen(0, 0);
-  A = gen.randu(size);
-  B = gen.randu(size);
+//  A = gen.randu(size);
+//  B = gen.randu(size);
 
   Z = A * B;
   for (index_type i=0; i<size; ++i)
@@ -61,7 +61,7 @@
       std::cout << "A(i) * B(i) = " << A(i) * B(i) << std::endl;
     }
 #endif
-    test_assert(almost_equal(Z(i), A(i) * B(i)));
+    test_assert(almost_equal(Z.get(i), A(i) * B(i)));
   }
 }
 
@@ -78,4 +78,9 @@
   test_vmul<complex<float>, impl::Cmplx_inter_fmt>(2048);
   test_vmul<complex<float>, impl::Cmplx_inter_fmt>(2048+16);
   test_vmul<complex<float>, impl::Cmplx_inter_fmt>(2048+16+1);
+
+  // Hit stride bug for CBE float backend (081224)
+  test_vmul<float, impl::Cmplx_inter_fmt>(65536);
+  test_vmul<complex<float>, impl::Cmplx_inter_fmt>(65536);
+  test_vmul<complex<float>, impl::Cmplx_split_fmt>(65536);
 }
Index: src/vsip/opt/cbe/spu/alf_vmul_s.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_vmul_s.c	(revision 230289)
+++ src/vsip/opt/cbe/spu/alf_vmul_s.c	(working copy)
@@ -32,14 +32,14 @@
 #if PPU_IS_32BIT
   // Transfer input A.
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
-  ea = params->a_ptr + current_count * FP * params->a_blk_stride;
+  ea = params->a_ptr + current_count * FP * params->a_blk_stride*sizeof(float);
   ALF_ACCEL_DTL_ENTRY_ADD(entries,
 			  FP * params->length,
 			  ALF_DATA_FLOAT,
 			  ea);
 
   // Transfer input B.
-  ea = params->b_ptr + current_count * FP * params->b_blk_stride;
+  ea = params->b_ptr + current_count * FP * params->b_blk_stride*sizeof(float);
   ALF_ACCEL_DTL_ENTRY_ADD(entries,
 			  FP * params->length,
 			  ALF_DATA_FLOAT,
@@ -49,7 +49,7 @@
 #else
   // Transfer input A.
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, 0);
-  ea = params->a_ptr + current_count * FP * params->a_blk_stride;
+  ea = params->a_ptr + current_count * FP * params->a_blk_stride*sizeof(float);
   ALF_ACCEL_DTL_ENTRY_ADD(entries,
 			  FP * params->length,
 			  ALF_DATA_FLOAT,
@@ -58,7 +58,7 @@
 
   // Transfer input B.
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_IN, FP * params->length*sizeof(float));
-  ea = params->b_ptr + current_count * FP * params->b_blk_stride;
+  ea = params->b_ptr + current_count * FP * params->b_blk_stride*sizeof(float);
   ALF_ACCEL_DTL_ENTRY_ADD(entries,
 			  FP * params->length,
 			  ALF_DATA_FLOAT,
@@ -85,7 +85,7 @@
 
   // Transfer output R.
   ALF_ACCEL_DTL_BEGIN(entries, ALF_BUF_OUT, 0);
-  ea = params->r_ptr + current_count * FP * params->r_blk_stride;
+  ea = params->r_ptr + current_count * FP * params->r_blk_stride*sizeof(float);
   ALF_ACCEL_DTL_ENTRY_ADD(entries,
 			  FP * params->length,
 			  ALF_DATA_FLOAT,
