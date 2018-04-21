Index: ChangeLog
===================================================================
--- ChangeLog	(revision 179530)
+++ ChangeLog	(working copy)
@@ -1,3 +1,10 @@
+2007-08-21  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/simd/expr_evaluator.hpp (Proxy_factory): Fix ct_valid
+	  for Unary_expr to check operand block's ct_valid too.
+	* src/vsip/opt/diag/extdata.hpp: Fix typo.
+	* src/vsip/opt/diag/block.hpp: New file, diagnostics for blocks.
+
 2007-08-20  Jules Bergmann  <jules@codesourcery.com>
 
 	* scripts/config (MondoTestSerial): New test package, since
Index: src/vsip/opt/simd/expr_evaluator.hpp
===================================================================
--- src/vsip/opt/simd/expr_evaluator.hpp	(revision 179530)
+++ src/vsip/opt/simd/expr_evaluator.hpp	(working copy)
@@ -108,8 +108,12 @@
     Unary_access_traits<typename Proxy_factory<B,A>::proxy_type, O>
     access_traits;
   typedef Proxy<access_traits,A> proxy_type;
-  static bool const ct_valid = Unary_operator_map<T, O>::is_supported;
 
+  static bool const ct_valid =
+    Unary_operator_map<T, O>::is_supported &&
+    Type_equal<typename B::value_type, T>::value &&
+    Proxy_factory<B, A>::ct_valid;
+
   static bool 
   rt_valid(Unary_expr_block<D, O, B, T> const &b, int alignment)
   {
Index: src/vsip/opt/diag/extdata.hpp
===================================================================
--- src/vsip/opt/diag/extdata.hpp	(revision 177792)
+++ src/vsip/opt/diag/extdata.hpp	(working copy)
@@ -124,7 +124,7 @@
 
     cout << "diagnose_rt_ext_data(" << name << ")" << endl
 	 << "  BlockT: " << typeid(BlockT).name() << endl
-	 << "  access_type: " << Class_name<access_type>::name() << endl
+	 << "  access_type: " << Class_name<AT>::name() << endl
       // << "  static-cost: " << access_type::cost << endl
       ;
   }
Index: src/vsip/opt/diag/block.hpp
===================================================================
--- src/vsip/opt/diag/block.hpp	(revision 0)
+++ src/vsip/opt/diag/block.hpp	(revision 0)
@@ -0,0 +1,64 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/diag/block.hpp
+    @author  Jules Bergmann
+    @date    2007-08-21
+    @brief   VSIPL++ Library: Diagnostics for blocks.
+*/
+
+#ifndef VSIP_OPT_DIAG_BLOCK_HPP
+#define VSIP_OPT_DIAG_BLOCK_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <iomanip>
+
+#include <vsip/opt/diag/extdata.hpp>
+
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
+
+template <typename BlockT>
+void
+diagnose_block(char const* str, BlockT const& /*blk*/)
+{
+  using std::cout;
+  using std::endl;
+  using vsip::impl::diag_detail::Class_name;
+
+  typedef typename Block_layout<BlockT>::access_type AT;
+  dimension_type const dim = Block_layout<BlockT>::dim;
+  bool const is_split = Is_split_block<BlockT>::value;
+
+  cout << "diagnose_block(" << str << "):" << std::endl
+       << "  BlockT        : " << typeid(BlockT).name() << endl
+       << "  Dim           : " << dim << endl
+       << "  Is_split_block: " << (is_split ? "yes" : "no") << endl
+       << "  Ext_data_cost : " << Ext_data_cost<BlockT>::value << endl
+       << "  access_type   : " << Class_name<AT>::name() << endl
+    ;
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_DIAG_BLOCK_HPP
