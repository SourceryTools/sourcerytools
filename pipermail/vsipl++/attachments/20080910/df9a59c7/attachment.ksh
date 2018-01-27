Index: ChangeLog
===================================================================
--- ChangeLog	(revision 220851)
+++ ChangeLog	(working copy)
@@ -1,3 +1,14 @@
+2008-09-10  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/cbe/ppu/bindings.hpp: Add tunable_threshold to
+	  vmul evaluator.
+	* src/vsip/opt/cbe/cml/transpose.hpp: Add tunable_threshold to
+	  transpose/copy evaluator
+	* src/vsip/core/config.hpp (VSIP_IMPL_TUNE_MODE): New define that
+	  forces tunable_threshold functions to return 0 when collecting
+	  tuning data.
+	* src/vsip/opt/ukernel.hpp: Fix wall warning.
+
 2008-09-10  Mike LeBlanc  <mike@codesourcery.com>
 
 	* doc/manual/fir.xml: Remove " = VSIP_DEFAULT_VALUE_TYPE" from class synopsis;
Index: src/vsip/opt/cbe/ppu/bindings.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/bindings.hpp	(revision 220851)
+++ src/vsip/opt/cbe/ppu/bindings.hpp	(working copy)
@@ -90,13 +90,31 @@
      Ext_data_cost<LBlock>::value == 0 &&
      Ext_data_cost<RBlock>::value == 0;
 
+  static int tunable_threshold()
+  {
+    typedef typename DstBlock::value_type T;
+
+    if (VSIP_IMPL_TUNE_MODE)
+      return 0;
+    // Compare interleaved vmul -2 --svpp-num-spes {0,8}.
+    else if (Type_equal<Operator<T, T>,
+	     op::Mult<complex<float>, complex<float> > >::value)
+      return 16384;
+    // Compare vmul -1 --svpp-num-spes {0,8}.
+    else if (Type_equal<Operator<T, T>, op::Mult<float, float> >::value)
+      return 65536;
+    else
+      return 0;
+  }
+
   static bool rt_valid(DstBlock& dst, SrcBlock const& src)
   {
     // check if all data is unit stride
     Ext_data<DstBlock, dst_lp>    ext_dst(dst,       SYNC_OUT);
     Ext_data<LBlock,   lblock_lp> ext_l(src.left(),  SYNC_IN);
     Ext_data<RBlock,   rblock_lp> ext_r(src.right(), SYNC_IN);
-    return ext_dst.stride(0) == 1 &&
+    return ext_dst.size(0) >= tunable_threshold() &&
+           ext_dst.stride(0) == 1 &&
 	   ext_l.stride(0) == 1   &&
 	   ext_r.stride(0) == 1   &&
 	   is_dma_addr_ok(ext_dst.data()) &&
Index: src/vsip/opt/cbe/cml/transpose.hpp
===================================================================
--- src/vsip/opt/cbe/cml/transpose.hpp	(revision 220851)
+++ src/vsip/opt/cbe/cml/transpose.hpp	(working copy)
@@ -26,6 +26,7 @@
 #include <vsip/core/extdata.hpp>
 #include <vsip/core/impl_tags.hpp>
 #include <vsip/opt/cbe/cml/traits.hpp>
+#include <vsip/opt/cbe/ppu/task_manager.hpp>
 
 #include <cml/ppu/cml.h>
 
@@ -204,6 +205,22 @@
     // check complex layout is consistent
     is_lhs_split == is_rhs_split;
 
+  static int tunable_threshold()
+  {
+    if (VSIP_IMPL_TUNE_MODE)
+      return 0;
+    // Copy is alway faster with SPU
+    else if (Type_equal<src_order_type, dst_order_type>::value)
+      return 0;
+    // Transpose is alway faster with SPU
+    else if (Type_equal<dst_value_type, complex<float> >::value)
+      return 128*128;
+    else if (Type_equal<dst_value_type, float>::value)
+      return 512*512;
+
+    return 0;
+  }
+
   static bool rt_valid(DstBlock& dst, SrcBlock const& src)
   { 
     bool rt = true;
@@ -227,6 +244,9 @@
         rt = false;
     }
 
+    rt &= dst.size(2, 0) * dst.size(2, 1) > tunable_threshold();
+    rt &= cbe::Task_manager::instance()->num_spes() > 0;
+
     return rt; 
   }
 
Index: src/vsip/core/config.hpp
===================================================================
--- src/vsip/core/config.hpp	(revision 220851)
+++ src/vsip/core/config.hpp	(working copy)
@@ -98,4 +98,12 @@
 #endif
 
 
+
+// If TUNE_MODE is set to 1, all tunable_threshold functions return
+// 0, allowing tuning to be done.
+
+#ifndef VSIP_IMPL_TUNE_MODE
+#  define VSIP_IMPL_TUNE_MODE 0
+#endif
+
 #endif // VSIP_CORE_CONFIG_HPP
Index: src/vsip/opt/ukernel.hpp
===================================================================
--- src/vsip/opt/ukernel.hpp	(revision 220851)
+++ src/vsip/opt/ukernel.hpp	(working copy)
@@ -402,6 +402,8 @@
 	      << "  chunk_size1_xtra_: " << chunk_size1_xtra_ << "\n"
 	      << "  chunk_index_     : " << chunk_index_ << "\n"
       ;
+#else
+    (void)name;
 #endif
   }
 
@@ -562,6 +564,8 @@
 	      << "  chunks_per_spe_  : " << chunks_per_spe_ << "\n"
 	      << "  num_chunks_      : " << num_chunks_ << "\n"
       ;
+#else
+    (void)name;
 #endif
   }
 
