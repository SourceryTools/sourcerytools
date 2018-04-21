Index: ChangeLog
===================================================================
--- ChangeLog	(revision 215847)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2008-07-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/cbe/cml/transpose.hpp: Fix buglet caught by
+	  regressions/transpose-nonunit.cpp.
+
 2008-07-22  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/cbe/cml/fir.hpp: Use CML FIR state copy.
Index: src/vsip/opt/cbe/cml/transpose.hpp
===================================================================
--- src/vsip/opt/cbe/cml/transpose.hpp	(revision 215403)
+++ src/vsip/opt/cbe/cml/transpose.hpp	(working copy)
@@ -210,12 +210,7 @@
 
     // If performing a copy, both source and destination blocks
     // must be unit stride and dense.
-    //
-    // 080710: CML cannot handle non-unit stride transpose
-    //         (regressions/transpose-nonunit.cpp fails),
-    //         temporarily enforce unit-stride requirement.
-    //
-    // if (Type_equal<src_order_type, dst_order_type>::value)
+    if (Type_equal<src_order_type, dst_order_type>::value)
     {
       Ext_data<DstBlock> dst_ext(dst, SYNC_OUT);
       Ext_data<SrcBlock> src_ext(src, SYNC_IN);
@@ -290,7 +285,7 @@
       cml::transpose(
         src_ext.data(), src_ext.stride(0), src_ext.stride(1),
         dst_ext.data(), dst_ext.stride(1), dst_ext.stride(0),
-        dst.size(2, 0), dst.size(2, 1));
+        dst.size(2, 1), dst.size(2, 0));
     }
   }
 
