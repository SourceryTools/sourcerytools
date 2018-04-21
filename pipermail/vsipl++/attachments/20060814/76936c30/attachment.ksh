Index: ChangeLog
===================================================================
--- ChangeLog	(revision 146749)
+++ ChangeLog	(working copy)
@@ -1,3 +1,19 @@
+2006-08-14  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/expr_serial_dispatch_fwd.hpp (Serial_dispatch_helper):
+	  Add ProfileP template parameter for profiling policy.
+	  (Serial_dispatch): New class, front-end to Serial_dispatch_helper.
+	* src/vsip/impl/expr_serial_evaluator.hpp (Serial_dispatch_helper):
+	  Use profiling policy to determine if profiling, coverage, or
+	  nothing is done when calling an evaluator.
+	* src/vsip/impl/dispatch-assign.hpp: Use Serial_dispatch frontend.
+	* src/vsip/impl/eval_dense_expr.hpp: Likewise, add name() member
+	  functions to Serial_expr_evaluator specializations.
+	* src/vsip/impl/sal/eval_elementwise.hpp: Add name() member
+	  functions to Serial_expr_evaluator sepcializations.
+	* src/vsip/impl/expr_serial_dispatch.hpp: Likewise.
+	* src/vsip/impl/ipp.hpp: Likewise
+
 2006-08-13  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/initfin.cpp: Modified to hand off command-line arguments 
@@ -4,8 +20,10 @@
 	  to the new object made for handling profiler options.  These allow 
 	  the profiler to be enabled without altering an existing program.
 	* src/vsip/profile.cpp: New definition of Profiler_options class.
-	* src/vsip/initfin.hpp: New static member to hold pointer to options object.
-	* src/vsip/impl/profile.hpp: New declaration for Profiler_options class.
+	* src/vsip/initfin.hpp: New static member to hold pointer to options
+	  object.
+	* src/vsip/impl/profile.hpp: New declaration for Profiler_options
+	  class.
 
 2006-08-13  Don McCoy  <don@codesourcery.com>
 
Index: src/vsip/impl/coverage.hpp
===================================================================
--- src/vsip/impl/coverage.hpp	(revision 146503)
+++ src/vsip/impl/coverage.hpp	(working copy)
@@ -16,7 +16,7 @@
 #include <vsip/impl/acconfig.hpp>
 
 #ifndef VSIP_IMPL_DO_COVERAGE
-#  define VSIP_IMPL_DO_COVERAGE 0
+#  define VSIP_IMPL_DO_COVERAGE 1
 #endif
 
 #if VSIP_IMPL_DO_COVERAGE
Index: src/vsip/impl/expr_serial_dispatch_fwd.hpp
===================================================================
--- src/vsip/impl/expr_serial_dispatch_fwd.hpp	(revision 146503)
+++ src/vsip/impl/expr_serial_dispatch_fwd.hpp	(working copy)
@@ -49,9 +49,14 @@
 /// Whether a given backend is actually used depends on its compile-time
 /// and run-time validity checks.
 
+/// Requires:
+///   PROFILEP to be a profiling policy.  Used to optionaly add
+///      profiling or coverage to dispatch.
+
 template <dimension_type Dim,
 	  typename DstBlock,
 	  typename SrcBlock,
+	  template <typename> class ProfileP,
 	  typename TagList,
 	  typename Tag = typename TagList::first,
 	  typename Rest = typename TagList::rest,
@@ -60,6 +65,17 @@
 	  bool CtValid = EvalExpr::ct_valid>
 struct Serial_dispatch_helper;
 
+
+
+/// Front-end to Serial_dispatch_helper.  This should be used
+/// instead of S_d_h directly.
+
+template <dimension_type Dim,
+	  typename DstBlock,
+	  typename SrcBlock,
+	  typename TagList>
+struct Serial_dispatch;
+
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/impl/sal/eval_elementwise.hpp
===================================================================
--- src/vsip/impl/sal/eval_elementwise.hpp	(revision 146503)
+++ src/vsip/impl/sal/eval_elementwise.hpp	(working copy)
@@ -481,6 +481,8 @@
          typename Type_if<Mercury_sal_tag,				\
                           Is_leaf_block<SrcBlock>::value>::type>	\
 {									\
+  static char const* name() { return "SEE_1_SAL_COPY"; }		\
+									\
   typedef typename DstBlock::value_type dst_type;			\
 									\
   typedef typename sal::Effective_value_type<DstBlock>::type eff_dst_t;	\
@@ -536,6 +538,8 @@
          typename Type_if<Mercury_sal_tag,				\
                           Is_leaf_block<Block1>::value>::type>		\
 {									\
+  static char const* name() { return "SEE_1_SAL_V"; }			\
+									\
   typedef Unary_expr_block<1, OP, Block1, Type1> const			\
 	SrcBlock;							\
 									\
@@ -611,6 +615,8 @@
                      Is_leaf_block<RBlock>::value>::type>		\
   : sal::Serial_expr_evaluator_base_mixed<OP, DstBlock, LBlock, RBlock, LType, RType>		\
 {									\
+  static char const* name() { return "SEE_1_SAL_VV"; }			\
+									\
   typedef Binary_expr_block<1, OP, LBlock, LType, RBlock, RType>	\
     SrcBlock;								\
   									\
@@ -677,6 +683,8 @@
                                  Block3, Type3>,			\
          Mercury_sal_tag>						\
 {									\
+  static char const* name() { return "SEE_1_SAL_VVV"; }			\
+									\
   typedef Ternary_expr_block<1, OP,					\
                                  Block1, Type1,				\
                                  Block2, Type2,				\
@@ -762,6 +770,8 @@
            Block3, Type3> const,					\
          Mercury_sal_tag>						\
 {									\
+  static char const* name() { return "SEE_1_SAL_fVVV"; }		\
+									\
   typedef Ternary_expr_block<1, OP,					\
            Unary_expr_block<1, UOP, Block1, Type1> const, Type1,	\
            Block2, Type2,						\
@@ -852,6 +862,8 @@
                      Is_leaf_block<Block2>::value &&			\
                      Is_leaf_block<Block3>::value>::type>		\
 {									\
+  static char const* name() { return "SEE_1_SAL_VV_V"; }		\
+									\
   typedef Binary_expr_block<						\
                  1, OP2,						\
                  Binary_expr_block<					\
@@ -940,6 +952,8 @@
                      Is_leaf_block<Block2>::value &&			\
                      Is_leaf_block<Block3>::value>::type>		\
 {									\
+  static char const* name() { return "SEE_1_SAL_V_VV"; }		\
+									\
   typedef Binary_expr_block<						\
                  1, OP2,						\
                  Block1, Type1,						\
@@ -1037,6 +1051,8 @@
            Block3, Type3> const,					\
          Mercury_sal_tag>						\
 {									\
+  static char const* name() { return "SEE_1_SAL_fVV_V"; }		\
+									\
   typedef Binary_expr_block<						\
             1, OP2,							\
             Binary_expr_block<						\
Index: src/vsip/impl/vmmul.hpp
===================================================================
--- src/vsip/impl/vmmul.hpp	(revision 146503)
+++ src/vsip/impl/vmmul.hpp	(working copy)
@@ -295,6 +295,8 @@
 			     const Vmmul_expr_block<SD, VBlock, MBlock>,
 			     Loop_fusion_tag>
 {
+  static char const* name() { return "SEE_1_Vmmul"; }
+
   typedef Vmmul_expr_block<SD, VBlock, MBlock> SrcBlock;
 
   typedef typename DstBlock::value_type dst_type;
Index: src/vsip/impl/eval_dense_expr.hpp
===================================================================
--- src/vsip/impl/eval_dense_expr.hpp	(revision 146503)
+++ src/vsip/impl/eval_dense_expr.hpp	(working copy)
@@ -857,6 +857,8 @@
 	  typename       SrcBlock>
 struct Serial_expr_evaluator<Dim, DstBlock, SrcBlock, Dense_expr_tag>
 {
+  static char const* name() { return "SEE_EDV"; }
+
   static bool const ct_valid =
     Dim > 1 &&
     Ext_data_cost<DstBlock>::value == 0 &&
@@ -886,7 +888,7 @@
     typename View_block_storage<new_dst_type>::plain_type
       new_dst = redim.apply(const_cast<DstBlock&>(dst));
 
-    Serial_dispatch_helper<1, new_dst_type, new_src_type, LibraryTagList>
+    Serial_dispatch<1, new_dst_type, new_src_type, LibraryTagList>
       ::exec(new_dst, redim.apply(const_cast<SrcBlock&>(src)));
   }
 };
Index: src/vsip/impl/dispatch-assign.hpp
===================================================================
--- src/vsip/impl/dispatch-assign.hpp	(revision 146503)
+++ src/vsip/impl/dispatch-assign.hpp	(working copy)
@@ -119,8 +119,7 @@
 
   static void exec(Block1& blk1, Block2 const& blk2)
   {
-    Serial_dispatch_helper<1, Block1, Block2, LibraryTagList>
-      ::exec(blk1, blk2);
+    Serial_dispatch<1, Block1, Block2, LibraryTagList>::exec(blk1, blk2);
   }
 };
 
@@ -134,7 +133,7 @@
 {
   static void exec(Block1& blk1, Block2 const& blk2)
   {
-    Serial_dispatch_helper<1, Block1, Block2, LibraryTagList>::exec(blk1, blk2);
+    Serial_dispatch<1, Block1, Block2, LibraryTagList>::exec(blk1, blk2);
   }
 };
 
@@ -148,8 +147,7 @@
 {
   static void exec(Block1& blk1, Block2 const& blk2)
   {
-    Serial_dispatch_helper<2, Block1, Block2, LibraryTagList>
-      ::exec(blk1, blk2);
+    Serial_dispatch<2, Block1, Block2, LibraryTagList>::exec(blk1, blk2);
   }
 };
 
@@ -163,8 +161,7 @@
 {
   static void exec(Block1& blk1, Block2 const& blk2)
   {
-    Serial_dispatch_helper<2, Block1, Block2, LibraryTagList>
-      ::exec(blk1, blk2);
+    Serial_dispatch<2, Block1, Block2, LibraryTagList>::exec(blk1, blk2);
   }
 };
 
@@ -213,8 +210,7 @@
 {
   static void exec(Block1& blk1, Block2 const& blk2)
   {
-    Serial_dispatch_helper<3, Block1, Block2, LibraryTagList>
-      ::exec(blk1, blk2);
+    Serial_dispatch<3, Block1, Block2, LibraryTagList>::exec(blk1, blk2);
   }
 };
   
Index: src/vsip/impl/ipp.hpp
===================================================================
--- src/vsip/impl/ipp.hpp	(revision 146503)
+++ src/vsip/impl/ipp.hpp	(working copy)
@@ -288,6 +288,8 @@
     Unary_expr_block<1, OP, Block, Type> const,				\
     Intel_ipp_tag>							\
 {									\
+  static char const* name() { return "SEE_IPP_V-" #FUN; }		\
+									\
   typedef typename Adjust_layout_dim<					\
       1, typename Block_layout<DstBlock>::layout_type>::type		\
     dst_lp;								\
@@ -324,7 +326,6 @@
     Ext_data<DstBlock, dst_lp> ext_dst(dst,      SYNC_OUT);		\
     Ext_data<Block,    blk_lp> ext_src(src.op(), SYNC_IN);		\
 									\
-    VSIP_IMPL_COVER_FCN("eval_IPP_V", FUN);				\
     FUN(								\
       ext_src.data(),							\
       ext_dst.data(),							\
@@ -355,6 +356,8 @@
   : ipp::Serial_expr_evaluator_base<OP, DstBlock,			\
 				    LBlock, RBlock, LType, RType>	\
 {									\
+  static char const* name() { return "SEE_IPP_VV-" #FUN; }		\
+									\
   typedef Binary_expr_block<1, OP, LBlock, LType, RBlock, RType>	\
     SrcBlock;								\
   									\
@@ -376,7 +379,6 @@
     Ext_data<LBlock, lblock_lp> ext_l(src.left(),  SYNC_IN);		\
     Ext_data<RBlock, rblock_lp> ext_r(src.right(), SYNC_IN);		\
 									\
-    VSIP_IMPL_COVER_FCN("eval_IPP_VV", FUN);				\
     FUN(								\
       ext_l.data(),							\
       ext_r.data(),							\
@@ -508,6 +510,8 @@
   : ipp::Scalar_view_evaluator_base<OP, DstBlock, SType,		\
                                     VBlock, VType, true>		\
 {									\
+  static char const* name() { return "SEE_IPP_SV-" #FCN; }		\
+									\
   typedef Binary_expr_block<1, OP,					\
 			    Scalar_block<1, SType>, SType,		\
 			    VBlock, VType>				\
@@ -525,7 +529,6 @@
   {									\
     Ext_data<DstBlock, dst_lp>  ext_dst(dst,       SYNC_OUT);		\
     Ext_data<VBlock, vblock_lp> ext_r(src.right(), SYNC_IN);		\
-    VSIP_IMPL_COVER_FCN("eval_IPP_SV", FCN);				\
     FCN(src.left().value(), ext_r.data(), ext_dst.data(), dst.size());	\
   }									\
 };
@@ -542,6 +545,8 @@
   : ipp::Scalar_view_evaluator_base<OP, DstBlock, float,		\
                                     VBlock, float, true>		\
 {									\
+  static char const* name() { return "SEE_IPP_SV_FO-" #FCN; }		\
+									\
   typedef float SType;							\
   typedef float VType;							\
 									\
@@ -562,7 +567,6 @@
   {									\
     Ext_data<DstBlock, dst_lp>  ext_dst(dst,       SYNC_OUT);		\
     Ext_data<VBlock, vblock_lp> ext_r(src.right(), SYNC_IN);		\
-    VSIP_IMPL_COVER_FCN("eval_IPP_SV_FO", FCN);				\
     FCN(src.left().value(), ext_r.data(), ext_dst.data(), dst.size());	\
   }									\
 };
@@ -583,6 +587,8 @@
   : ipp::Scalar_view_evaluator_base<OP, DstBlock, SType,		\
                                     VBlock, VType, false>		\
 {									\
+  static char const* name() { return "SEE_IPP_VS-" #FCN; }		\
+									\
   typedef Binary_expr_block<1, OP,					\
 			    VBlock, VType,				\
 			    Scalar_block<1, SType>, SType>		\
@@ -600,7 +606,6 @@
   {									\
     Ext_data<DstBlock, dst_lp>  ext_dst(dst,       SYNC_OUT);		\
     Ext_data<VBlock, vblock_lp> ext_l(src.left(), SYNC_IN);		\
-    VSIP_IMPL_COVER_FCN("eval_IPP_VS", FCN);				\
     FCN(ext_l.data(), src.right().value(), ext_dst.data(), dst.size());	\
   }									\
 };
@@ -619,6 +624,8 @@
   : ipp::Scalar_view_evaluator_base<OP, DstBlock, SType,		\
                                     VBlock, VType, false>		\
 {									\
+  static char const* name() { return "SEE_IPP_VS_AS_SV-" #FCN; }	\
+									\
   typedef Binary_expr_block<1, OP,					\
 			    VBlock, VType,				\
 			    Scalar_block<1, SType>, SType>		\
@@ -636,7 +643,6 @@
   {									\
     Ext_data<DstBlock, dst_lp>  ext_dst(dst,       SYNC_OUT);		\
     Ext_data<VBlock, vblock_lp> ext_l(src.left(), SYNC_IN);		\
-    VSIP_IMPL_COVER_FCN("eval_IPP_VS_AS_SV", FCN);			\
     FCN(src.right().value(), ext_l.data(), ext_dst.data(), dst.size());	\
   }									\
 };
Index: src/vsip/impl/expr_serial_dispatch.hpp
===================================================================
--- src/vsip/impl/expr_serial_dispatch.hpp	(revision 146503)
+++ src/vsip/impl/expr_serial_dispatch.hpp	(working copy)
@@ -39,6 +39,16 @@
 
 
 
+#if VSIP_IMPL_DO_COVERAGE 
+#  define VSIP_IMPL_SD_PROFILE_POLICY Eval_coverage_policy
+#elif VSIP_IMPL_DO_PROFILE
+#  define VSIP_IMPL_SD_PROFILE_POLICY Eval_profile_policy
+#else
+#  define VSIP_IMPL_SD_PROFILE_POLICY Eval_nop_policy
+#endif 
+
+
+
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -48,24 +58,71 @@
 namespace impl
 {
 
+// Policy for profiling an expression evaluator.
+template <typename EvalExpr>
+struct Eval_profile_policy
+{
+  template <typename DstBlock,
+	    typename SrcBlock>
+  Eval_profile_policy(DstBlock const&, SrcBlock const&)
+  {}
+
+  // TODO
+};
+
+
+
+// Policy for recording coverage for an expression evaluator.
+template <typename EvalExpr>
+struct Eval_coverage_policy
+{
+  template <typename DstBlock,
+	    typename SrcBlock>
+  Eval_coverage_policy(DstBlock const&, SrcBlock const&)
+  {
+    char const* evaluator_name = EvalExpr::name();
+    VSIP_IMPL_COVER_BLK(evaluator_name, SrcBlock);
+  }
+};
+
+
+
+// Policy for doing nothing special for an expression evaluator.
+template <typename EvalExpr>
+struct Eval_nop_policy
+{
+  template <typename DstBlock,
+	    typename SrcBlock>
+  Eval_nop_policy(DstBlock const&, SrcBlock const&)
+  {}
+};
+
+
+
 /// In case the compile-time check passes, we decide at run-time whether
 /// or not to use this backend.
 template <dimension_type Dim,
 	  typename DstBlock,
 	  typename SrcBlock,
+	  template <typename> class ProfileP,
 	  typename TagList,
 	  typename Tag,
 	  typename Rest,
 	  typename EvalExpr>
-struct Serial_dispatch_helper<Dim, DstBlock, SrcBlock, TagList,
+struct Serial_dispatch_helper<Dim, DstBlock, SrcBlock, ProfileP, TagList,
 		       Tag, Rest, EvalExpr, true>
 {
-
   static void exec(DstBlock& dst, SrcBlock const& src)
     VSIP_NOTHROW
   {
-    if (EvalExpr::rt_valid(dst, src)) EvalExpr::exec(dst, src);
-    else Serial_dispatch_helper<Dim, DstBlock, SrcBlock, Rest>::exec(dst, src);
+    if (EvalExpr::rt_valid(dst, src))
+    {
+      ProfileP<EvalExpr> profile(dst, src);
+      EvalExpr::exec(dst, src);
+    }
+    else
+      Serial_dispatch_helper<Dim, DstBlock, SrcBlock, ProfileP, Rest>
+	::exec(dst, src);
   }
 };
 
@@ -74,14 +131,15 @@
 template <dimension_type Dim,
 	  typename DstBlock,
 	  typename SrcBlock,
+	  template <typename> class ProfileP,
 	  typename TagList,
 	  typename Tag,
 	  typename Rest,
 	  typename EvalExpr>
-struct Serial_dispatch_helper<Dim, DstBlock, SrcBlock, TagList,
+struct Serial_dispatch_helper<Dim, DstBlock, SrcBlock, ProfileP, TagList,
 			      Tag, Rest, EvalExpr,
 			      false>
-  : Serial_dispatch_helper<Dim, DstBlock, SrcBlock, Rest>
+  : Serial_dispatch_helper<Dim, DstBlock, SrcBlock, ProfileP, Rest>
 {};
 
 /// Terminator. Instead of passing on to the next element
@@ -90,20 +148,47 @@
 template <dimension_type Dim,
 	  typename DstBlock,
 	  typename SrcBlock,
+	  template <typename> class ProfileP,
 	  typename TagList,
 	  typename Tag,
 	  typename EvalExpr>
-struct Serial_dispatch_helper<Dim, DstBlock, SrcBlock, TagList,
+struct Serial_dispatch_helper<Dim, DstBlock, SrcBlock, ProfileP, TagList,
 			      Tag, None_type, EvalExpr, true>
 {
   static void exec(DstBlock& dst, SrcBlock const& src)
     VSIP_NOTHROW
   {
-    if (EvalExpr::rt_valid(dst, src)) EvalExpr::exec(dst, src);
+    if (EvalExpr::rt_valid(dst, src))
+    {
+      ProfileP<EvalExpr> profile(dst, src);
+      EvalExpr::exec(dst, src);
+    }
     else assert(0);
   }
 };
 
+
+
+/// Front-end to Serial_dispatch_helper.  Uses S_d_h's ProfileP to
+/// attach bits like profiling, coverage etc.
+
+template <dimension_type Dim,
+	  typename DstBlock,
+	  typename SrcBlock,
+	  typename TagList>
+struct Serial_dispatch
+{
+  static void exec(DstBlock& dst, SrcBlock const& src)
+    VSIP_NOTHROW
+  {
+    Serial_dispatch_helper<Dim, DstBlock, SrcBlock,
+                           VSIP_IMPL_SD_PROFILE_POLICY, TagList>::
+      exec(dst, src);
+  }
+};
+
+#undef VSIP_IMPL_SD_PROFILE_POLICY
+
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/impl/expr_serial_evaluator.hpp
===================================================================
--- src/vsip/impl/expr_serial_evaluator.hpp	(revision 146503)
+++ src/vsip/impl/expr_serial_evaluator.hpp	(working copy)
@@ -59,13 +59,13 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<1, DstBlock, SrcBlock, Loop_fusion_tag>
 {
+  static char const* name() { return "SEE_1"; }
   static bool const ct_valid = true;
   static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
   { return true; }
   
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
-    VSIP_IMPL_COVER_BLK("SEE_1", SrcBlock);
     length_type const size = dst.size(1, 0);
     for (index_type i=0; i<size; ++i)
       dst.put(i, src.get(i));
@@ -78,6 +78,8 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<1, DstBlock, SrcBlock, Copy_tag>
 {
+  static char const* name() { return "SEE_1_Copy"; }
+
   typedef typename Adjust_layout_dim<
       1, typename Block_layout<DstBlock>::layout_type>::type
     dst_lp;
@@ -97,7 +99,6 @@
   
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
-    VSIP_IMPL_COVER_BLK("SEE_COPY", SrcBlock);
     Ext_data<DstBlock, dst_lp> ext_dst(dst, impl::SYNC_OUT);
     Ext_data<SrcBlock, src_lp> ext_src(src, impl::SYNC_IN);
 
@@ -133,6 +134,8 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<2, DstBlock, SrcBlock, Transpose_tag>
 {
+  static char const* name() { return "SEE_2_Transpose"; }
+
   typedef typename DstBlock::value_type dst_value_type;
   typedef typename SrcBlock::value_type src_value_type;
 
@@ -325,6 +328,7 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<2, DstBlock, SrcBlock, Loop_fusion_tag>
 {
+  static char const* name() { return "SEE_2"; }
   static bool const ct_valid = true;
   static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
   { return true; }
@@ -349,7 +353,6 @@
 
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
-    VSIP_IMPL_COVER_BLK("SEE_2", SrcBlock);
     typedef typename Block_layout<DstBlock>::order_type dst_order_type;
     exec(dst, src, dst_order_type());
   }
@@ -361,6 +364,7 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<3, DstBlock, SrcBlock, Loop_fusion_tag>
 {
+  static char const* name() { return "SEE_3"; }
   static bool const ct_valid = true;
   static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
   { return true; }
@@ -434,7 +438,6 @@
 
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
-    VSIP_IMPL_COVER_BLK("SEE_3", SrcBlock);
     typedef typename Block_layout<DstBlock>::order_type dst_order_type;
     exec(dst, src, dst_order_type());
   }
