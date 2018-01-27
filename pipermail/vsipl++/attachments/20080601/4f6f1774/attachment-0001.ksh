Index: src/vsip/opt/sal/bridge_util.hpp
===================================================================
--- src/vsip/opt/sal/bridge_util.hpp	(revision 209993)
+++ src/vsip/opt/sal/bridge_util.hpp	(working copy)
@@ -26,6 +26,7 @@
 
 #include <vsip/support.hpp>
 #include <vsip/core/coverage.hpp>
+#include <vsip/core/storage.hpp>
 
 
 
Index: src/vsip/opt/sal/eval_misc.hpp
===================================================================
--- src/vsip/opt/sal/eval_misc.hpp	(revision 209993)
+++ src/vsip/opt/sal/eval_misc.hpp	(working copy)
@@ -29,10 +29,12 @@
 // faster, but the API is changing towards that used with mat_mul().
 // See 'sal.hpp' for details as to the differences.
 //
-// In addition, complex mat_mul veriants have a defect that
-// affects CSAL and SAL for MCOE 6.3.0.
+// In addition, complex mat_mul variants have a defect that
+// affect CSAL and SAL for MCOE 6.3.0.
 
+#ifndef VSIP_IMPL_SAL_USE_MAT_MUL
 #define VSIP_IMPL_SAL_USE_MAT_MUL 0
+#endif
 
 
 
@@ -69,7 +71,7 @@
 
   static bool rt_valid(Block0& r, T1, Block1 const& a, Block2 const& b)
   {
-    typedef typename Block_layout<Block1>::order_type order0_type;
+    typedef typename Block_layout<Block0>::order_type order0_type;
     dimension_type const r_dim1 = order0_type::impl_dim1;
 
     Ext_data<Block0> ext_r(const_cast<Block0&>(r));
@@ -155,7 +157,7 @@
   static bool rt_valid(Block0& r, std::complex<T1>, 
     Block1 const& a, Block2 const& b)
   {
-    typedef typename Block_layout<Block1>::order_type order0_type;
+    typedef typename Block_layout<Block0>::order_type order0_type;
     dimension_type const r_dim1 = order0_type::impl_dim1;
 
     Ext_data<Block0> ext_r(const_cast<Block0&>(r));
