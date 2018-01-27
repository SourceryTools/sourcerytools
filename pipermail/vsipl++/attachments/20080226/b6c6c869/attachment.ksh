Index: src/vsip/opt/simd/expr_evaluator.hpp
===================================================================
--- src/vsip/opt/simd/expr_evaluator.hpp	(revision 192398)
+++ src/vsip/opt/simd/expr_evaluator.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2007, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -31,6 +31,7 @@
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/extdata.hpp>
 #include <vsip/opt/expr/serial_evaluator.hpp>
+#include <vsip/opt/simd/proxy_factory.hpp>
 
 /***********************************************************************
   Definitions
@@ -40,213 +41,9 @@
 {
 namespace impl
 {
-namespace simd
-{
 
-template <typename BlockT, bool A>
-struct Proxy_factory
-{
-  typedef Direct_access_traits<typename BlockT::value_type> access_traits;
-  typedef Proxy<access_traits, A> proxy_type;
-  typedef typename Adjust_layout_dim<
-                     1, typename Block_layout<BlockT>::layout_type>::type
-		layout_type;
+// SIMD Loop Fusion evaluator for aligned expressions.
 
-  static bool const ct_valid = Ext_data_cost<BlockT>::value == 0 &&
-    !Is_split_block<BlockT>::value;
-
-  static bool 
-  rt_valid(BlockT const &b, int alignment)
-  {
-    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
-    return dda.stride(0) == 1 && 
-      (!A ||
-       Simd_traits<typename BlockT::value_type>::alignment_of(dda.data()) ==
-       alignment);
-  }
-
-  static int
-  alignment(BlockT const &b)
-  {
-    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
-    return Simd_traits<typename BlockT::value_type>::alignment_of(dda.data());
-  }
-
-  static proxy_type
-  create(BlockT const &b) 
-  {
-    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
-    return proxy_type(dda.data());
-  }
-};
-
-template <typename T, bool A>
-struct Proxy_factory<Scalar_block<1, T>, A>
-{
-  typedef Scalar_access_traits<T> access_traits;
-  typedef Proxy<access_traits, A> proxy_type;
-  static bool const ct_valid = true;
-
-  static bool 
-  rt_valid(Scalar_block<1, T> const &, int) {return true;}
-
-  static proxy_type
-  create(Scalar_block<1, T> const &b) 
-  {
-    return proxy_type(b.value());
-  }
-};
-
-template <dimension_type D,
-	  template <typename> class O,
-	  typename B,
-	  typename T,
-	  bool A>
-struct Proxy_factory<Unary_expr_block<D, O, B, T> const, A>
-{
-  typedef 
-    Unary_access_traits<typename Proxy_factory<B,A>::proxy_type, O>
-    access_traits;
-  typedef Proxy<access_traits,A> proxy_type;
-
-  static bool const ct_valid =
-    Unary_operator_map<T, O>::is_supported &&
-    Type_equal<typename B::value_type, T>::value &&
-    Proxy_factory<B, A>::ct_valid;
-
-  static bool 
-  rt_valid(Unary_expr_block<D, O, B, T> const &b, int alignment)
-  {
-    return Proxy_factory<B, A>::rt_valid(b.op(), alignment);
-  }
-
-  static proxy_type
-  create(Unary_expr_block<D, O, B, T> const &b)
-  {
-    return proxy_type(Proxy_factory<B, A>::create(b.op()));
-  }
-};
-
-// This proxy is specialized for unaligned blocks. If the user specifies
-// ualigned(block), this is a hint to switch to an unaligned proxy.
-template <dimension_type D,
-	  typename B,
-	  typename T,
-	  bool A>
-struct Proxy_factory<Unary_expr_block<D, unaligned_functor, B, T> const, A>
-{
-  typedef typename Proxy_factory<B, false>::access_traits access_traits;
-  typedef Proxy<access_traits,false> proxy_type;
-  static bool const ct_valid = Proxy_factory<B,false>::ct_valid;
-
-
-  static bool 
-  rt_valid(Unary_expr_block<D, unaligned_functor, B, T> const &b, int alignment)
-  {
-    return Proxy_factory<B, false>::rt_valid(b.op(), alignment);
-  }
-
-  static proxy_type
-  create(Unary_expr_block<D, unaligned_functor, B, T> const &b)
-  {
-    return proxy_type(Proxy_factory<B, false>::create(b.op()));
-  }
-};
-
-template <dimension_type                D,
-	  template <typename, typename> class O,
-	  typename                      LB,
-	  typename                      LT,
-	  typename                      RB,
-	  typename                      RT,
-	  bool A>
-struct Proxy_factory<Binary_expr_block<D, O, LB, LT, RB, RT> const, A>
-{
-  typedef
-    Binary_access_traits<typename Proxy_factory<LB, A>::proxy_type,
-			 typename Proxy_factory<RB, A>::proxy_type, O> 
-    access_traits;
-  typedef Proxy<access_traits, A> proxy_type;
-  static bool const ct_valid = 
-    Type_equal<typename LB::value_type, LT>::value &&
-    Type_equal<typename RB::value_type, RT>::value &&
-    Type_equal<LT, RT>::value &&
-    Binary_operator_map<LT, O>::is_supported &&
-    Proxy_factory<LB, A>::ct_valid &&
-    Proxy_factory<RB, A>::ct_valid;
-
-  static bool 
-  rt_valid(Binary_expr_block<D, O, LB, LT, RB, RT> const &b, int alignment)
-  {
-    return Proxy_factory<LB, A>::rt_valid(b.left(), alignment) &&
-           Proxy_factory<RB, A>::rt_valid(b.right(), alignment);
-  }
-
-  static proxy_type
-  create(Binary_expr_block<D, O, LB, LT, RB, RT> const &b)
-  {
-    typename Proxy_factory<LB, A>::proxy_type lp =
-      Proxy_factory<LB, A>::create(b.left());
-    typename Proxy_factory<RB, A>::proxy_type rp =
-      Proxy_factory<RB, A>::create(b.right());
-
-    return proxy_type(lp, rp);
-  }
-};
-
-template <dimension_type                         D,
-	  template <typename, typename,typename> class O,
-	  typename                               Block1, typename Type1,
-	  typename                               Block2, typename Type2,
-	  typename                               Block3, typename Type3,
-	  bool A>
-struct Proxy_factory<Ternary_expr_block<D, O,
-  Block1,Type1,Block2,Type2,Block3,Type3> const, A>
-{
-  typedef Ternary_access_traits<typename Proxy_factory<Block1, A>::proxy_type,
-                                typename Proxy_factory<Block2, A>::proxy_type,
-                                typename Proxy_factory<Block3, A>::proxy_type,
-		 	        O> 
-    access_traits;
-
-  typedef Ternary_expr_block<D, O, Block1,Type1,Block2,Type2,Block3,Type3>
-    SrcBlock;
-
-  typedef Proxy<access_traits, A> proxy_type;
-  static bool const ct_valid = 
-    Ternary_operator_map<Type1, O>::is_supported &&
-    Proxy_factory<Block1, A>::ct_valid &&
-    Proxy_factory<Block2, A>::ct_valid &&
-    Proxy_factory<Block3, A>::ct_valid;
-
-  static bool 
-  rt_valid(SrcBlock const &b, int alignment)
-  {
-    return Proxy_factory<Block1, A>::rt_valid(b.first(), alignment) &&
-           Proxy_factory<Block2, A>::rt_valid(b.second(), alignment) &&
-           Proxy_factory<Block3, A>::rt_valid(b.third(), alignment);
-  }
-
-  static proxy_type
-  create(SrcBlock const &b)
-  {
-    typename Proxy_factory<Block1, A>::proxy_type
-      b1p = Proxy_factory<Block1, A>::create(b.first());
-    typename Proxy_factory<Block2, A>::proxy_type
-      b2p = Proxy_factory<Block2, A>::create(b.second());
-    typename Proxy_factory<Block3, A>::proxy_type
-      b3p = Proxy_factory<Block3, A>::create(b.third());
-
-    return proxy_type(b1p,b2p,b3p);
-  }
-};
-
-
-} // namespace vsip::impl::simd
-
-
-// This evaluator is for aligned data only.
-// Look at Simd_unaligned_loop_fusion_tag for unaligned data.
 template <typename LB,
 	  typename RB>
 struct Serial_expr_evaluator<1, LB, RB, Simd_loop_fusion_tag>
@@ -326,78 +123,6 @@
   }
 };
 
-// This evaluator is for unaligned data. Any time any of the blocks are
-// unaligned, we use this evalutator. Basically, in the evaluator list, this
-// evaluator is right after the aligned evaluator and rt_valid determines
-// which one to use.
-template <typename LB,
-	  typename RB>
-struct Serial_expr_evaluator<1, LB, RB, Simd_unaligned_loop_fusion_tag>
-{
-  typedef typename Adjust_layout_dim<
-                     1, typename Block_layout<LB>::layout_type>::type
-		layout_type;
-
-  static char const* name() { return "Expr_SIMD_Unaligned_Loop"; }
-  
-  static bool const ct_valid =
-    // Is SIMD supported at all ?
-    simd::Simd_traits<typename LB::value_type>::is_accel &&
-    // Check that direct access is possible.
-    Ext_data_cost<LB>::value == 0 &&
-    simd::Proxy_factory<RB, false>::ct_valid &&
-    // Only allow float, double, complex<float>,
-    // and complex<double> at this time.
-    (Type_equal<typename Scalar_of<typename LB::value_type>::type, float>::value ||
-     Type_equal<typename Scalar_of<typename LB::value_type>::type, double>::value) &&
-    // Make sure both sides have the same type.
-    Type_equal<typename LB::value_type, typename RB::value_type>::value &&
-    // Make sure the left side is not a complex split block.
-    !Is_split_block<LB>::value;
-
-
-  static bool rt_valid(LB& lhs, RB const& rhs)
-  {
-    Ext_data<LB, layout_type> dda(lhs, SYNC_OUT);
-    return (dda.stride(0) == 1 &&
-	    simd::Simd_traits<typename LB::value_type>::
-	      alignment_of(dda.data()) == 0 &&
-	    simd::Proxy_factory<RB, false>::rt_valid(rhs, 0));
-  }
-
-  static void exec(LB& lhs, RB const& rhs)
-  {
-    typedef typename simd::LValue_access_traits<typename LB::value_type> WAT;
-    typedef typename simd::Proxy_factory<RB, false>::access_traits EAT;
-
-    length_type const vec_size =
-      simd::Simd_traits<typename LB::value_type>::vec_size;
-    Ext_data<LB, layout_type> dda(lhs, SYNC_OUT);
-
-    simd::Proxy<WAT,true>  lp(dda.data());
-    simd::Proxy<EAT,false> rp(simd::Proxy_factory<RB,false>::create(rhs));
-
-    length_type const size = dda.size(0);
-    length_type n = size;
-
-    // loop using proxy interface. This generates the best code
-    // with gcc 3.4 (with gcc 4.1 the difference to the first case
-    // above is negligible).
-
-    while (n >= vec_size)
-    {
-      lp.store(rp.load());
-      n -= vec_size;
-      lp.increment();
-      rp.increment();
-    }
-
-    // Process the remainder, using simple loop fusion.
-    for (index_type i = size - n; i != size; ++i) lhs.put(i, rhs.get(i));
-  }
-};
-
-
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/opt/simd/proxy_factory.hpp
===================================================================
--- src/vsip/opt/simd/proxy_factory.hpp	(revision 0)
+++ src/vsip/opt/simd/proxy_factory.hpp	(revision 0)
@@ -0,0 +1,249 @@
+/* Copyright (c) 2006, 2007, 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/simd/expr_evaluator.hpp
+    @author  Stefan Seefeld
+    @date    2006-07-25
+    @brief   VSIPL++ Library: SIMD expression evaluator proxy factory.
+
+*/
+
+#ifndef VSIP_IMPL_SIMD_PROXY_FACTORY_HPP
+#define VSIP_IMPL_SIMD_PROXY_FACTORY_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip/opt/simd/expr_iterator.hpp>
+#include <vsip/core/expr/operations.hpp>
+#include <vsip/core/expr/unary_block.hpp>
+#include <vsip/core/expr/binary_block.hpp>
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/core/extdata.hpp>
+#include <vsip/opt/expr/serial_evaluator.hpp>
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace simd
+{
+
+template <typename BlockT, bool A>
+struct Proxy_factory
+{
+  typedef Direct_access_traits<typename BlockT::value_type> access_traits;
+  typedef Proxy<access_traits, A> proxy_type;
+  typedef typename Adjust_layout_dim<
+                     1, typename Block_layout<BlockT>::layout_type>::type
+		layout_type;
+
+  static bool const ct_valid = Ext_data_cost<BlockT>::value == 0 &&
+    !Is_split_block<BlockT>::value;
+
+  static bool 
+  rt_valid(BlockT const &b, int alignment)
+  {
+    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
+    return dda.stride(0) == 1 && 
+      (!A ||
+       Simd_traits<typename BlockT::value_type>::alignment_of(dda.data()) ==
+       alignment);
+  }
+
+  static int
+  alignment(BlockT const &b)
+  {
+    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
+    return Simd_traits<typename BlockT::value_type>::alignment_of(dda.data());
+  }
+
+  static proxy_type
+  create(BlockT const &b) 
+  {
+    Ext_data<BlockT, layout_type> dda(b, SYNC_IN);
+    return proxy_type(dda.data());
+  }
+};
+
+template <typename T, bool A>
+struct Proxy_factory<Scalar_block<1, T>, A>
+{
+  typedef Scalar_access_traits<T> access_traits;
+  typedef Proxy<access_traits, A> proxy_type;
+  static bool const ct_valid = true;
+
+  static bool 
+  rt_valid(Scalar_block<1, T> const &, int) {return true;}
+
+  static proxy_type
+  create(Scalar_block<1, T> const &b) 
+  {
+    return proxy_type(b.value());
+  }
+};
+
+template <dimension_type D,
+	  template <typename> class O,
+	  typename B,
+	  typename T,
+	  bool A>
+struct Proxy_factory<Unary_expr_block<D, O, B, T> const, A>
+{
+  typedef 
+    Unary_access_traits<typename Proxy_factory<B,A>::proxy_type, O>
+    access_traits;
+  typedef Proxy<access_traits,A> proxy_type;
+
+  static bool const ct_valid =
+    Unary_operator_map<T, O>::is_supported &&
+    Type_equal<typename B::value_type, T>::value &&
+    Proxy_factory<B, A>::ct_valid;
+
+  static bool 
+  rt_valid(Unary_expr_block<D, O, B, T> const &b, int alignment)
+  {
+    return Proxy_factory<B, A>::rt_valid(b.op(), alignment);
+  }
+
+  static proxy_type
+  create(Unary_expr_block<D, O, B, T> const &b)
+  {
+    return proxy_type(Proxy_factory<B, A>::create(b.op()));
+  }
+};
+
+// This proxy is specialized for unaligned blocks. If the user specifies
+// ualigned(block), this is a hint to switch to an unaligned proxy.
+template <dimension_type D,
+	  typename B,
+	  typename T,
+	  bool A>
+struct Proxy_factory<Unary_expr_block<D, unaligned_functor, B, T> const, A>
+{
+  typedef typename Proxy_factory<B, false>::access_traits access_traits;
+  typedef Proxy<access_traits,false> proxy_type;
+  static bool const ct_valid = Proxy_factory<B,false>::ct_valid;
+
+
+  static bool 
+  rt_valid(Unary_expr_block<D, unaligned_functor, B, T> const &b, int alignment)
+  {
+    return Proxy_factory<B, false>::rt_valid(b.op(), alignment);
+  }
+
+  static proxy_type
+  create(Unary_expr_block<D, unaligned_functor, B, T> const &b)
+  {
+    return proxy_type(Proxy_factory<B, false>::create(b.op()));
+  }
+};
+
+template <dimension_type                D,
+	  template <typename, typename> class O,
+	  typename                      LB,
+	  typename                      LT,
+	  typename                      RB,
+	  typename                      RT,
+	  bool A>
+struct Proxy_factory<Binary_expr_block<D, O, LB, LT, RB, RT> const, A>
+{
+  typedef
+    Binary_access_traits<typename Proxy_factory<LB, A>::proxy_type,
+			 typename Proxy_factory<RB, A>::proxy_type, O> 
+    access_traits;
+  typedef Proxy<access_traits, A> proxy_type;
+  static bool const ct_valid = 
+    Type_equal<typename LB::value_type, LT>::value &&
+    Type_equal<typename RB::value_type, RT>::value &&
+    Type_equal<LT, RT>::value &&
+    Binary_operator_map<LT, O>::is_supported &&
+    Proxy_factory<LB, A>::ct_valid &&
+    Proxy_factory<RB, A>::ct_valid;
+
+  static bool 
+  rt_valid(Binary_expr_block<D, O, LB, LT, RB, RT> const &b, int alignment)
+  {
+    return Proxy_factory<LB, A>::rt_valid(b.left(), alignment) &&
+           Proxy_factory<RB, A>::rt_valid(b.right(), alignment);
+  }
+
+  static proxy_type
+  create(Binary_expr_block<D, O, LB, LT, RB, RT> const &b)
+  {
+    typename Proxy_factory<LB, A>::proxy_type lp =
+      Proxy_factory<LB, A>::create(b.left());
+    typename Proxy_factory<RB, A>::proxy_type rp =
+      Proxy_factory<RB, A>::create(b.right());
+
+    return proxy_type(lp, rp);
+  }
+};
+
+template <dimension_type                         D,
+	  template <typename, typename,typename> class O,
+	  typename                               Block1, typename Type1,
+	  typename                               Block2, typename Type2,
+	  typename                               Block3, typename Type3,
+	  bool A>
+struct Proxy_factory<Ternary_expr_block<D, O,
+  Block1,Type1,Block2,Type2,Block3,Type3> const, A>
+{
+  typedef Ternary_access_traits<typename Proxy_factory<Block1, A>::proxy_type,
+                                typename Proxy_factory<Block2, A>::proxy_type,
+                                typename Proxy_factory<Block3, A>::proxy_type,
+		 	        O> 
+    access_traits;
+
+  typedef Ternary_expr_block<D, O, Block1,Type1,Block2,Type2,Block3,Type3>
+    SrcBlock;
+
+  typedef Proxy<access_traits, A> proxy_type;
+  static bool const ct_valid = 
+    Ternary_operator_map<Type1, O>::is_supported &&
+    Proxy_factory<Block1, A>::ct_valid &&
+    Proxy_factory<Block2, A>::ct_valid &&
+    Proxy_factory<Block3, A>::ct_valid;
+
+  static bool 
+  rt_valid(SrcBlock const &b, int alignment)
+  {
+    return Proxy_factory<Block1, A>::rt_valid(b.first(), alignment) &&
+           Proxy_factory<Block2, A>::rt_valid(b.second(), alignment) &&
+           Proxy_factory<Block3, A>::rt_valid(b.third(), alignment);
+  }
+
+  static proxy_type
+  create(SrcBlock const &b)
+  {
+    typename Proxy_factory<Block1, A>::proxy_type
+      b1p = Proxy_factory<Block1, A>::create(b.first());
+    typename Proxy_factory<Block2, A>::proxy_type
+      b2p = Proxy_factory<Block2, A>::create(b.second());
+    typename Proxy_factory<Block3, A>::proxy_type
+      b3p = Proxy_factory<Block3, A>::create(b.third());
+
+    return proxy_type(b1p,b2p,b3p);
+  }
+};
+
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_SIMD_PROXY_FACTORY_HPP
Index: src/vsip/opt/simd/eval_unaligned.hpp
===================================================================
--- src/vsip/opt/simd/eval_unaligned.hpp	(revision 0)
+++ src/vsip/opt/simd/eval_unaligned.hpp	(revision 0)
@@ -0,0 +1,121 @@
+/* Copyright (c) 2006, 2007, 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/simd/eval_unaligned.hpp
+    @author  Stefan Seefeld
+    @date    2006-07-25
+    @brief   VSIPL++ Library: SIMD expression evaluator logic.
+
+*/
+
+#ifndef VSIP_IMPL_SIMD_EVAL_UNALIGNED_HPP
+#define VSIP_IMPL_SIMD_EVAL_UNALIGNED_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip/opt/simd/expr_iterator.hpp>
+#include <vsip/core/expr/operations.hpp>
+#include <vsip/core/expr/unary_block.hpp>
+#include <vsip/core/expr/binary_block.hpp>
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/core/extdata.hpp>
+#include <vsip/opt/expr/serial_evaluator.hpp>
+#include <vsip/opt/simd/proxy_factory.hpp>
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+
+// SIMD Loop Fusion evaluator for unaligned expressions.
+//
+// Handles expressions where the result is aligned, but the operands
+// are unaligned.
+
+template <typename LB,
+	  typename RB>
+struct Serial_expr_evaluator<1, LB, RB, Simd_unaligned_loop_fusion_tag>
+{
+  typedef typename Adjust_layout_dim<
+                     1, typename Block_layout<LB>::layout_type>::type
+		layout_type;
+
+  static char const* name() { return "Expr_SIMD_Unaligned_Loop"; }
+  
+  static bool const ct_valid =
+    // Is SIMD supported at all ?
+    simd::Simd_traits<typename LB::value_type>::is_accel &&
+    // Check that direct access is possible.
+    Ext_data_cost<LB>::value == 0 &&
+    simd::Proxy_factory<RB, false>::ct_valid &&
+    // Only allow float, double, complex<float>,
+    // and complex<double> at this time.
+    (Type_equal<typename Scalar_of<typename LB::value_type>::type, float>::value ||
+     Type_equal<typename Scalar_of<typename LB::value_type>::type, double>::value) &&
+    // Make sure both sides have the same type.
+    Type_equal<typename LB::value_type, typename RB::value_type>::value &&
+    // Make sure the left side is not a complex split block.
+    !Is_split_block<LB>::value;
+
+
+  static bool rt_valid(LB& lhs, RB const& rhs)
+  {
+    Ext_data<LB, layout_type> dda(lhs, SYNC_OUT);
+    return (dda.stride(0) == 1 &&
+	    simd::Simd_traits<typename LB::value_type>::
+	      alignment_of(dda.data()) == 0 &&
+	    simd::Proxy_factory<RB, false>::rt_valid(rhs, 0));
+  }
+
+  static void exec(LB& lhs, RB const& rhs)
+  {
+    typedef typename simd::LValue_access_traits<typename LB::value_type> WAT;
+    typedef typename simd::Proxy_factory<RB, false>::access_traits EAT;
+
+    length_type const vec_size =
+      simd::Simd_traits<typename LB::value_type>::vec_size;
+    Ext_data<LB, layout_type> dda(lhs, SYNC_OUT);
+
+    simd::Proxy<WAT,true>  lp(dda.data());
+    simd::Proxy<EAT,false> rp(simd::Proxy_factory<RB,false>::create(rhs));
+
+    length_type const size = dda.size(0);
+    length_type n = size;
+
+    // loop using proxy interface. This generates the best code
+    // with gcc 3.4 (with gcc 4.1 the difference to the first case
+    // above is negligible).
+
+    while (n >= vec_size)
+    {
+      lp.store(rp.load());
+      n -= vec_size;
+      lp.increment();
+      rp.increment();
+    }
+
+    // Process the remainder, using simple loop fusion.
+    for (index_type i = size - n; i != size; ++i) lhs.put(i, rhs.get(i));
+  }
+};
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_SIMD_EVAL_UNALIGNED_HPP
Index: src/vsip/opt/simd/expr_iterator.hpp
===================================================================
--- src/vsip/opt/simd/expr_iterator.hpp	(revision 192398)
+++ src/vsip/opt/simd/expr_iterator.hpp	(working copy)
@@ -327,34 +327,31 @@
   typedef typename simd::perm_simd_type  perm_simd_type;
   typedef typename simd::value_type      value_type;
 
-  Simd_unaligned_loader(value_type const* ptr) : ptr_unaligned_(ptr) 
+  Simd_unaligned_loader(value_type const* ptr)
   {
     ptr_aligned_    = (value_type*)((intptr_t)ptr & ~(simd::alignment-1));
 
     x0_  = simd::load((value_type*)ptr_aligned_);
-    x1_  = simd::load((value_type*)(ptr_aligned_+simd::vec_size));
-    sh_  = simd::shift_for_addr(ptr_unaligned_);
+    sh_  = simd::shift_for_addr(ptr);
   }
 
   simd_type load() const
-  { return simd::perm(x0_, x1_, sh_); }
+  {
+    x1_  = simd::load((value_type*)(ptr_aligned_+simd::vec_size));
+    return simd::perm(x0_, x1_, sh_);
+  }
 
   void increment(length_type n = 1)
   {
-    ptr_unaligned_ += n * simd::vec_size;
     ptr_aligned_   += n * simd::vec_size;
   
     // update x0
     x0_ = (n == 1) ? x1_ : simd::load((value_type*)ptr_aligned_);
-
-    // update x1
-    x1_ = simd::load((value_type*)(ptr_aligned_+simd::vec_size));
   }
 
-  value_type const*            ptr_unaligned_;
   value_type const*            ptr_aligned_;
   simd_type                    x0_;
-  simd_type                    x1_;
+  mutable simd_type            x1_;
   perm_simd_type               sh_;
 
 };
@@ -568,7 +565,7 @@
   AB const &left() const { return left_;}
   C const &right() const { return right_;}
 
-  simd_type load() const 
+  simd_type load() const
   {
     simd_type a = left_.left().load();
     simd_type b = left_.right().load();
Index: src/vsip/opt/expr/serial_dispatch.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch.hpp	(revision 192398)
+++ src/vsip/opt/expr/serial_dispatch.hpp	(working copy)
@@ -47,6 +47,9 @@
 #ifdef VSIP_IMPL_HAVE_SIMD_LOOP_FUSION
 #  include <vsip/opt/simd/expr_evaluator.hpp>
 #endif
+#ifdef VSIP_IMPL_HAVE_SIMD_UNALIGNED_LOOP_FUSION
+#  include <vsip/opt/simd/eval_unaligned.hpp>
+#endif
 #ifdef VSIP_IMPL_HAVE_SIMD_GENERIC
 #  include <vsip/opt/simd/eval_generic.hpp>
 #endif
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 194489)
+++ ChangeLog	(working copy)
@@ -1,3 +1,20 @@
+2008-02-26  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/simd/expr_evaluator.hpp
+	* src/vsip/opt/simd/proxy_factory.hpp: New file, Proxy_factor from
+	  expr_evaluator.hpp.
+	* src/vsip/opt/simd/eval_unaligned.hpp: New file, unaligned SIMD
+	  loop-fusion evaluator from expr_evaluator.hpp.
+	* src/vsip/opt/simd/expr_iterator.hpp (Simd_unaligned_loader): Move
+	  loads around to avoid second load past end of vector
+	  (first load inevitable).
+	* src/vsip/opt/expr/serial_dispatch.hpp: Include eval_unaligned.hpp.
+	* configure.ac (--enable-simd-unaligned-loop-fusion): Allow SIMD
+	  unaligned loop fusion to be controlled independently of aligned
+	  loop fusion.
+	* doc/quickstart/quickstart.xml: Document --enable-simd-loop-fusion
+	  and --enable-simd-unaligned-loop-fusion.
+
 2008-02-25  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/simd/rscvmul.hpp: Fix bug in handling unalignment.
Index: configure.ac
===================================================================
--- configure.ac	(revision 192398)
+++ configure.ac	(working copy)
@@ -303,9 +303,15 @@
 
 AC_ARG_ENABLE([simd_loop_fusion],
   AS_HELP_STRING([--enable-simd-loop-fusion],
-                 [Enable SIMD loop-fusion.]),,
+                 [Enable SIMD loop-fusion (Disable by default).]),,
   [enable_simd_loop_fusion=no])
 
+AC_ARG_ENABLE([simd_unaligned_loop_fusion],
+  AS_HELP_STRING([--enable-simd-unaligned-loop-fusion],
+                 [Enable SIMD loop-fusion for unaligned expressions
+                  (Follows --enable-simd-loop-fusion by default).]),,
+  [enable_simd_unaligned_loop_fusion=default])
+
 AC_ARG_WITH([builtin_simd_routines],
   AS_HELP_STRING([--with-builtin-simd-routines=WHAT],
                  [Use builtin SIMD routines.]),,
@@ -856,13 +862,22 @@
 #
 # Configure use of SIMD loop-fusion
 #
+if test "$enable_simd_unaligned_loop_fusion" = "default"; then
+  enable_simd_unaligned_loop_fusion=$enable_simd_loop_fusion
+fi
+
 if test "$enable_simd_loop_fusion" = "yes"; then
   AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SIMD_LOOP_FUSION, 1,
     [Define whether to use SIMD loop-fusion in expr dispatch.])
 fi
 
+if test "$enable_simd_unaligned_loop_fusion" = "yes"; then
+  AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SIMD_UNALIGNED_LOOP_FUSION, 1,
+    [Define whether to use SIMD unaligned loop-fusion in expr dispatch.])
+fi
 
 
+
 #
 # Configure use of builtin SIMD routines
 #
@@ -1055,6 +1070,8 @@
 else
   AC_MSG_RESULT([Complex storage format:                  interleaved])
 fi
+AC_MSG_RESULT([Using SIMD aligned loop-fusion           ${enable_simd_loop_fusion}])
+AC_MSG_RESULT([Using SIMD unaligned loop-fusion         ${enable_simd_unaligned_loop_fusion}])
 AC_MSG_RESULT([Timer:                                   ${enable_timer}])
 AC_MSG_RESULT([With Python bindings:                    ${enable_scripting}])
 
Index: doc/quickstart/quickstart.xml
===================================================================
--- doc/quickstart/quickstart.xml	(revision 192398)
+++ doc/quickstart/quickstart.xml	(working copy)
@@ -1215,6 +1215,40 @@
      </varlistentry>
 
      <varlistentry>
+      <term><option>--enable-simd-loop-fusion</option></term>
+      <listitem>
+       <para>
+        Enable VSIPL++ to generate SIMD instructions for loop-fusion
+        expressions (containing data that is SIMD aligned).
+
+        This option is useful for increasing performance of many
+        VSIPL++ expressions on platforms with SIMD instruction
+        set extensions (such as Intel SSE, or Power VMX/AltiVec).
+
+        The default is not to generate SIMD instructions.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><option>--enable-simd-unaligned-loop-fusion</option></term>
+      <listitem>
+       <para>
+        Enable VSIPL++ to generate SIMD instructions for loop-fusion
+        expressions, possibly containing data that is SIMD unaligned.
+
+        This option is useful for increasing performance of VSIPL++
+        expressions that work with unaligned data on platforms with
+        SIMD instruction set extensions (such as Intel SSE, or Power
+        VMX/AltiVec).
+
+        The default is to follow the setting of
+        <option>--enable-simd-loop-fusion</option>.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
       <term><option>--with-complex=<replaceable>format</replaceable></option></term>
       <listitem>
        <para>
