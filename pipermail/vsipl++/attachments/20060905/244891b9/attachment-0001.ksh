Index: src/vsip/impl/simd/eval-generic.hpp
===================================================================
--- src/vsip/impl/simd/eval-generic.hpp	(revision 148408)
+++ src/vsip/impl/simd/eval-generic.hpp	(working copy)
@@ -433,6 +433,13 @@
 			    VBlock, complex<T> >
 	SrcBlock;
 
+  typedef typename Adjust_layout_dim<
+    1, typename Block_layout<DstBlock>::layout_type>::type
+  dst_lp;
+  typedef typename Adjust_layout_dim<
+    1, typename Block_layout<VBlock>::layout_type>::type
+  vblock_lp;
+
   static char const* name() { return "Expr_SIMD_V-simd::rscvmul"; }
 
   static bool const ct_valid = 
@@ -453,15 +460,15 @@
   static bool rt_valid(DstBlock& dst, SrcBlock const& src)
   {
     // check if all data is unit stride
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
+    Ext_data<DstBlock, dst_lp> ext_dst(dst, SYNC_OUT);
+    Ext_data<VBlock, vblock_lp> ext_r(src.right(), SYNC_IN);
     return (ext_dst.stride(0) == 1 && ext_r.stride(0) == 1);
   }
 
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
+    Ext_data<DstBlock, dst_lp> ext_dst(dst, SYNC_OUT);
+    Ext_data<VBlock, vblock_lp> ext_r(src.right(), SYNC_IN);
     simd::rscvmul(src.left().value(), ext_r.data(), ext_dst.data(),
 		  dst.size());
   }
@@ -486,6 +493,13 @@
 			    Scalar_block<1, T>, T>
 	SrcBlock;
 
+  typedef typename Adjust_layout_dim<
+    1, typename Block_layout<DstBlock>::layout_type>::type
+  dst_lp;
+  typedef typename Adjust_layout_dim<
+    1, typename Block_layout<VBlock>::layout_type>::type
+  vblock_lp;
+
   static char const* name() { return "Expr_SIMD_V-simd::rscvmul"; }
 
   static bool const ct_valid = 
@@ -493,7 +507,7 @@
     simd::Is_algorithm_supported<
         T,
         Is_split_block<DstBlock>::value,
-	simd::Map_operator_to_algorithm<op::Mult>::type>::value &&
+	typename simd::Map_operator_to_algorithm<op::Mult>::type>::value &&
 
     Type_equal<typename DstBlock::value_type, std::complex<T> >::value &&
     // check that direct access is supported
@@ -506,15 +520,15 @@
   static bool rt_valid(DstBlock& dst, SrcBlock const& src)
   {
     // check if all data is unit stride
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
+    Ext_data<DstBlock, dst_lp> ext_dst(dst, SYNC_OUT);
+    Ext_data<VBlock, vblock_lp> ext_l(src.left(), SYNC_IN);
     return (ext_dst.stride(0) == 1 && ext_l.stride(0) == 1);
   }
 
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
+    Ext_data<DstBlock, dst_lp> ext_dst(dst, SYNC_OUT);
+    Ext_data<VBlock, vblock_lp> ext_l(src.left(), SYNC_IN);
     simd::rscvmul(src.right().value(), ext_l.data(), ext_dst.data(),
 		  dst.size());
   }
