Index: ChangeLog
===================================================================
--- ChangeLog	(revision 145532)
+++ ChangeLog	(working copy)
@@ -1,3 +1,49 @@
+2006-07-22  Jules Bergmann  <jules@codesourcery.com>
+
+	New Par_assign framework that makes it easier to plug in
+	other parallel assignments.
+	* src/vsip/impl/par_assign.hpp: New file, general Par_assign
+	  class that is specialized for specific implementation tags.
+	* src/vsip/impl/par_assign_blkvec.hpp: New file, implements
+	  parallel assignment for special case of block distributed
+	  vectors.  Avoids creating type chains (i.e. MPI datatypes).
+	* src/vsip/impl/par-chain-assign.hpp: Update to be a Par_assign
+	  specialization.
+	* src/vsip/impl/map-traits.hpp (Is_block_dist): New map traits
+	  class to determine if a particular dimension is block or whole
+	  (i.e. only 1 patch per subblock).
+	* src/vsip/impl/dispatch-assign.hpp: Use new Par_assign class.
+	  Identify when block-vector assignment can be done.
+	* src/vsip/impl/par-expr.hpp: Likewise.
+	* src/vsip/impl/setup-assign.hpp: Likewise.
+	* tests/parallel/block.cpp: Likewise.
+	* src/vsip/impl/par-services-mpi.hpp (par_assign_impl_type):
+	  Define preferred Par_assign ImplTag.
+	* src/vsip/map.hpp (Is_block_dist): Provide specialization for Map.
+	* src/vsip/vector.hpp: Move par-chain-assign.hpp include to
+	  dispatch-assign.hpp.
+	* src/vsip/matrix.hpp: Likewise.
+	* src/vsip/tensor.hpp: Likewise.
+
+	Bug fixes.
+	* src/vsip/impl/sal/elementwise.hpp: Fix bug in ZVS_SYN wrapper
+	  (used for split-complex synthetic wrappers like scalar-vector add).
+	* src/vsip/impl/eval_dense_expr.hpp: Fix handling of Dense blocks
+	  with a Local_or_global_map.
+	* src/vsip/impl/expr_serial_evaluator.hpp: Fix Copy_tag
+	  evaluator to request 1-dim Ext_data access.
+	
+	* src/vsip/impl/adjust-layout.hpp (Adjust_layout_pack): New
+	  class to adjust layout by setting pack_type.
+	* benchmarks/dist_vmul.cpp: New benchmark, covers distributed
+	  vector-multiply including scatter, gather costs.
+	* benchmarks/copy.cpp: Update to test Par_assign class performance.
+	* benchmarks/loop.hpp: Add capability to skip calibration.
+	* benchmarks/vmul.cpp: Move setup_assign outside of timer.
+	* benchmarks/main.cpp: Add options to skip calibration (-nocal)
+	  and pause before running (-pause).
+	* examples/fft.cpp: Fix Wall warning.
+	
 2006-07-21  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* doc/GNUmakefile.inc.in: Add xml dependencies and convenience targets.
Index: src/vsip/vector.hpp
===================================================================
--- src/vsip/vector.hpp	(revision 145532)
+++ src/vsip/vector.hpp	(working copy)
@@ -27,7 +27,6 @@
 #include <vsip/impl/refcount.hpp>
 #include <vsip/impl/noncopyable.hpp>
 #include <vsip/impl/view_traits.hpp>
-#include <vsip/impl/par-chain-assign.hpp>
 #include <vsip/impl/dispatch-assign.hpp>
 #include <vsip/impl/lvalue-proxy.hpp>
 // #include <vsip/math.hpp>
Index: src/vsip/matrix.hpp
===================================================================
--- src/vsip/matrix.hpp	(revision 145532)
+++ src/vsip/matrix.hpp	(working copy)
@@ -28,7 +28,6 @@
 #include <vsip/impl/subblock.hpp>
 #include <vsip/impl/refcount.hpp>
 #include <vsip/impl/view_traits.hpp>
-#include <vsip/impl/par-chain-assign.hpp>
 #include <vsip/impl/dispatch-assign.hpp>
 #include <vsip/impl/lvalue-proxy.hpp>
 
Index: src/vsip/tensor.hpp
===================================================================
--- src/vsip/tensor.hpp	(revision 145532)
+++ src/vsip/tensor.hpp	(working copy)
@@ -28,7 +28,6 @@
 #include <vsip/impl/subblock.hpp>
 #include <vsip/impl/refcount.hpp>
 #include <vsip/impl/view_traits.hpp>
-#include <vsip/impl/par-chain-assign.hpp>
 #include <vsip/impl/dispatch-assign.hpp>
 #include <vsip/impl/lvalue-proxy.hpp>
 
Index: src/vsip/impl/setup-assign.hpp
===================================================================
--- src/vsip/impl/setup-assign.hpp	(revision 145532)
+++ src/vsip/impl/setup-assign.hpp	(working copy)
@@ -87,7 +87,8 @@
 
   template <dimension_type Dim,
 	    typename       DstBlock,
-	    typename       SrcBlock>
+	    typename       SrcBlock,
+	    typename       ParAssignImpl>
   class Par_assign_holder : public Holder_base
   {
     typedef typename DstBlock::value_type value1_type;
@@ -113,8 +114,9 @@
 
     // Member data
   private:
-    vsip::impl::Chained_parallel_assign<Dim,
-	value1_type, value2_type, DstBlock, SrcBlock> par_assign_;
+    vsip::impl::Par_assign<Dim, value1_type, value2_type,
+			   DstBlock, SrcBlock, ParAssignImpl>
+		par_assign_;
   };
 
 
@@ -196,9 +198,10 @@
 
   template <dimension_type Dim,
 	    typename       View1,
-	    typename       View2>
+	    typename       View2,
+	    typename       ParAssignImpl>
   void
-  create_holder(View1 dst, View2 src, impl::Tag_par_assign)
+  create_holder(View1 dst, View2 src, impl::Tag_par_assign<ParAssignImpl>)
   {
     typedef typename View1::value_type           value1_type;
     typedef typename View2::value_type           value2_type;
@@ -229,7 +232,7 @@
     }
     else
     {
-      holder_ = new Par_assign_holder<Dim, block1_type, block2_type>(dst, src);
+      holder_ = new Par_assign_holder<Dim, block1_type, block2_type, ParAssignImpl>(dst, src);
     }
   }
 
@@ -297,10 +300,10 @@
     typedef typename impl::Dispatch_assign_helper<dim, Block1, Block2>::type
       raw_dispatch_type;
 
-    typedef typename ITE_Type<Type_equal<raw_dispatch_type,
-                                impl::Tag_serial_assign>::value,
-                     As_type<impl::Tag_serial_expr>,
-                     As_type<raw_dispatch_type> >
+    typedef typename
+      ITE_Type<Type_equal<raw_dispatch_type, impl::Tag_serial_assign>::value,
+               As_type<impl::Tag_serial_expr>,
+               As_type<raw_dispatch_type> >
       ::type dispatch_type;
 
     create_holder<dim>(dst, src, dispatch_type());
Index: src/vsip/impl/sal/elementwise.hpp
===================================================================
--- src/vsip/impl/sal/elementwise.hpp	(revision 145532)
+++ src/vsip/impl/sal/elementwise.hpp	(working copy)
@@ -1055,8 +1055,8 @@
   T real = SCALAR_OP B.value.real();					\
   T imag = SCALAR_OP B.value.imag();					\
 									\
-  SALFCN(A.ptr.first,  A.stride, &real, Z.ptr.first, Z.stride, len,0);\
-  SALFCN(A.ptr.second, A.stride, &imag, Z.ptr.first, Z.stride, len,0);\
+  SALFCN(A.ptr.first,  A.stride, &real, Z.ptr.first,  Z.stride, len,0);\
+  SALFCN(A.ptr.second, A.stride, &imag, Z.ptr.second, Z.stride, len,0);\
 }
 
 #define VSIP_IMPL_ZSV_SYN(FCN, T, SALFCN)				\
Index: src/vsip/impl/eval_dense_expr.hpp
===================================================================
--- src/vsip/impl/eval_dense_expr.hpp	(revision 145532)
+++ src/vsip/impl/eval_dense_expr.hpp	(working copy)
@@ -407,6 +407,14 @@
   };
 
   template <dimension_type Dim0,
+	    typename       T,
+	    typename       OrderT>
+  struct leaf_node<Dense<Dim0, T, OrderT, Local_or_global_map<Dim0> > >
+  {
+    typedef Dense<Dim0, T, OrderT, Local_map> type;
+  };
+
+  template <dimension_type Dim0,
 	    typename       T>
   struct leaf_node<Scalar_block<Dim0, T> >
   {
@@ -567,6 +575,16 @@
     return block;
   }
 
+  template <dimension_type Dim0,
+	    typename       T,
+	    typename       OrderT>
+  // typename transform<Dense<Dim0, T, OrderT, Local_or_global_map<Dim0> > >::type&
+  Dense<Dim0, T, OrderT, Local_map>&
+  apply(Dense<Dim0, T, OrderT, Local_or_global_map<Dim0> >& block) const
+  {
+    return block.get_local_block();
+  }
+
   // Leaf combine function for Scalar_block.
   template <dimension_type Dim0,
 	    typename       T>
Index: src/vsip/impl/adjust-layout.hpp
===================================================================
--- src/vsip/impl/adjust-layout.hpp	(revision 145532)
+++ src/vsip/impl/adjust-layout.hpp	(working copy)
@@ -149,6 +149,19 @@
 
 
 
+template <typename NewPackType,
+	  typename LP>
+struct Adjust_layout_pack
+{
+  typedef typename LP::order_type     order_type;
+  typedef typename LP::pack_type      pack_type;
+  typedef typename LP::complex_type   complex_type;
+
+  typedef Layout<LP::dim, order_type, NewPackType, complex_type> type;
+};
+
+
+
 // Determine if an given layout policy is compatible with a required
 // layout policy.
 
Index: src/vsip/impl/map-traits.hpp
===================================================================
--- src/vsip/impl/map-traits.hpp	(revision 145532)
+++ src/vsip/impl/map-traits.hpp	(working copy)
@@ -46,7 +46,12 @@
 { static bool const value = Is_global_map<MapT>::value &&
                            !Is_local_map<MapT>::value; };
 
+template <dimension_type Dim,
+	  typename       MapT>
+struct Is_block_dist
+{ static bool const value = false; };
 
+
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/impl/dispatch-assign.hpp
===================================================================
--- src/vsip/impl/dispatch-assign.hpp	(revision 145532)
+++ src/vsip/impl/dispatch-assign.hpp	(working copy)
@@ -20,6 +20,8 @@
 #include <vsip/impl/map-traits.hpp>
 #include <vsip/impl/par-expr.hpp>
 #include <vsip/impl/expr_serial_dispatch.hpp>
+#include <vsip/impl/par-chain-assign.hpp>
+#include <vsip/impl/par_assign_blkvec.hpp>
 
 
 
@@ -39,7 +41,7 @@
 
 struct Tag_serial_assign {};
 struct Tag_serial_expr {};
-struct Tag_par_assign {};
+template <typename ParAssignImpl> struct Tag_par_assign {};
 struct Tag_par_expr_noreorg {};
 struct Tag_par_expr {};
 
@@ -80,15 +82,20 @@
   static int const  lhs_cost      = Ext_data_cost<Block1>::value;
   static int const  rhs_cost      = Ext_data_cost<Block2>::value;
 
+  static int const  is_blkvec     = is_rhs_simple && (Dim == 1) &&
+                                    Is_block_dist<0, map1_type>::value &&
+                                    Is_block_dist<0, map2_type>::value;
+
   typedef typename
-  ITE_Type<is_illegal,                As_type<Tag_illegal_mix_of_local_and_global_in_assign>,
+  ITE_Type<is_illegal,          As_type<Tag_illegal_mix_of_local_and_global_in_assign>,
   ITE_Type<is_local && !is_rhs_expr && lhs_cost == 0 && rhs_cost == 0 &&
 	   !is_lhs_split && !is_rhs_split,
-                                      As_type<Tag_serial_assign>,
-  ITE_Type<is_local,                  As_type<Tag_serial_expr>,
-  ITE_Type<is_rhs_simple,             As_type<Tag_par_assign>,
-  ITE_Type<is_rhs_reorg,              As_type<Tag_par_expr>,
-	                              As_type<Tag_par_expr_noreorg> > > > > >
+                                As_type<Tag_serial_assign>,
+  ITE_Type<is_local,            As_type<Tag_serial_expr>,
+  ITE_Type<is_blkvec,           As_type<Tag_par_assign<Blkvec_assign> >,
+  ITE_Type<is_rhs_simple,       As_type<Tag_par_assign<par_assign_impl_type> >,
+  ITE_Type<is_rhs_reorg,        As_type<Tag_par_expr>,
+	                        As_type<Tag_par_expr_noreorg> > > > > > >
 		::type type;
 };
 
@@ -215,14 +222,11 @@
 
 // Specialization for parallel assignment, RHS is simple.
 
-// Note: We could check if maps are same and avoid communication, but
-//       Chained_parallel_assign provides this functionality by
-//       copying data // that stays on the same processor.
-
 template <dimension_type Dim,
 	  typename       Block1,
-	  typename       Block2>
-struct Dispatch_assign<Dim, Block1, Block2, Tag_par_assign>
+	  typename       Block2,
+	  typename       ParAssignImpl>
+struct Dispatch_assign<Dim, Block1, Block2, Tag_par_assign<ParAssignImpl> >
 {
   typedef typename Block1::map_type map1_type;
 
@@ -233,20 +237,30 @@
 
   static void exec(Block1& blk1, Block2 const& blk2)
   {
-    dst_type dst(blk1);
-    src_type src(const_cast<Block2&>(blk2));
-
     if (Is_par_same_map<Dim, map1_type, Block2>::value(blk1.map(), blk2))
     {
-      par_expr_simple(dst, src);
+      // Maps are same, no communication required.
+      typedef typename Distributed_local_block<Block1>::type block1_t;
+      typedef typename Distributed_local_block<Block2>::type block2_t;
+      typedef typename View_block_storage<block1_t>::type::equiv_type stor1_t;
+      typedef typename View_block_storage<block2_t>::type::equiv_type stor2_t;
+
+      stor1_t l_blk1 = get_local_block(blk1);
+      stor2_t l_blk2 = get_local_block(blk2);
+
+      Dispatch_assign<Dim, block1_t, block2_t>::exec(l_blk1, l_blk2);
     }
     else
     {
-      Chained_parallel_assign<Dim,
+      dst_type dst(blk1);
+      src_type src(const_cast<Block2&>(blk2));
+      
+      Par_assign<Dim,
 	typename Block1::value_type,
 	typename Block2::value_type,
 	Block1,
-	Block2> pa(dst, src);
+	Block2,
+	ParAssignImpl> pa(dst, src);
 
       pa();
     }
Index: src/vsip/impl/par_assign.hpp
===================================================================
--- src/vsip/impl/par_assign.hpp	(revision 0)
+++ src/vsip/impl/par_assign.hpp	(revision 0)
@@ -0,0 +1,50 @@
+/* Copyright (c)  2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/impl/par_assign.hpp
+    @author  Jules Bergmann
+    @date    2006-07-14
+    @brief   VSIPL++ Library: Parallel assignment class.
+
+*/
+
+#ifndef VSIP_IMPL_PAR_ASSIGN_HPP
+#define VSIP_IMPL_PAR_ASSIGN_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+struct Chained_assign;
+struct Blkvec_assign;
+struct Pas_assign;
+
+// Parallel assignment.
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2,
+	  typename       ImplTag>
+class Par_assign;
+
+
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_IMPL_PAR_ASSIGN_HPP
Index: src/vsip/impl/par-expr.hpp
===================================================================
--- src/vsip/impl/par-expr.hpp	(revision 145532)
+++ src/vsip/impl/par-expr.hpp	(working copy)
@@ -18,6 +18,7 @@
 #include <vsip/impl/domain-utils.hpp>
 #include <vsip/impl/distributed-block.hpp>
 #include <vsip/impl/block-traits.hpp>
+#include <vsip/impl/par_assign.hpp>
 
 
 
@@ -31,14 +32,6 @@
 namespace impl
 {
 
-// Forward declaration,
-template <dimension_type Dim,
-	  typename       T1,
-	  typename       T2,
-	  typename       Block1,
-	  typename       Block2>
-class Chained_parallel_assign;
-
 // Forward.
 template <dimension_type Dim,
 	  typename       MapT>
@@ -112,7 +105,8 @@
   Ref_counted_ptr<dst_block_type> dst_block_;
   dst_view_type   dst_;
   src_view_type   src_;
-  Chained_parallel_assign<Dim, value_type, value_type, dst_block_type, BlockT>
+  Par_assign<Dim, value_type, value_type, dst_block_type, BlockT,
+             par_assign_impl_type>
 		  assign_;
 };
 
Index: src/vsip/impl/expr_serial_evaluator.hpp
===================================================================
--- src/vsip/impl/expr_serial_evaluator.hpp	(revision 145532)
+++ src/vsip/impl/expr_serial_evaluator.hpp	(working copy)
@@ -17,6 +17,7 @@
 #include <vsip/impl/block-traits.hpp>
 #include <vsip/impl/extdata.hpp>
 #include <vsip/impl/fast-transpose.hpp>
+#include <vsip/impl/adjust-layout.hpp>
 #include <vsip/impl/coverage.hpp>
 
 
@@ -72,6 +73,14 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<1, DstBlock, SrcBlock, Copy_tag>
 {
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<DstBlock>::layout_type>::type
+    dst_lp;
+
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<SrcBlock>::layout_type>::type
+    src_lp;
+
   static bool const ct_valid = 
     Ext_data_cost<DstBlock>::value == 0 &&
     Ext_data_cost<SrcBlock>::value == 0 &&
@@ -84,10 +93,12 @@
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
     VSIP_IMPL_COVER_BLK("SEE_COPY", SrcBlock);
-    Ext_data<DstBlock> ext_dst(dst, impl::SYNC_OUT);
-    Ext_data<SrcBlock> ext_src(src, impl::SYNC_IN);
-    typename DstBlock::value_type* ptr1 = ext_dst.data();
-    typename SrcBlock::value_type* ptr2 = ext_src.data();
+    Ext_data<DstBlock, dst_lp> ext_dst(dst, impl::SYNC_OUT);
+    Ext_data<SrcBlock, src_lp> ext_src(src, impl::SYNC_IN);
+
+    typename Ext_data<DstBlock, dst_lp>::raw_ptr_type ptr1 = ext_dst.data();
+    typename Ext_data<SrcBlock, src_lp>::raw_ptr_type ptr2 = ext_src.data();
+
     stride_type stride1 = ext_dst.stride(0);
     stride_type stride2 = ext_src.stride(0);
     length_type size    = ext_dst.size(0);
@@ -333,7 +344,7 @@
 
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
-    VSIP_IMPL_COVER_BLK("SEE_3", SrcBlock);
+    VSIP_IMPL_COVER_BLK("SEE_2", SrcBlock);
     typedef typename Block_layout<DstBlock>::order_type dst_order_type;
     exec(dst, src, dst_order_type());
   }
Index: src/vsip/impl/par_assign_blkvec.hpp
===================================================================
--- src/vsip/impl/par_assign_blkvec.hpp	(revision 0)
+++ src/vsip/impl/par_assign_blkvec.hpp	(revision 0)
@@ -0,0 +1,719 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/par_assign_blkvec.hpp
+    @author  Jules Bergmann
+    @date    2006-07-19
+    @brief   VSIPL++ Library: Block-vector parallel assignment algorithm.
+
+*/
+
+#ifndef VSIP_IMPL_PAR_ASSIGN_BLOCK_VECTOR_HPP
+#define VSIP_IMPL_PAR_ASSIGN_BLOCK_VECTOR_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vector>
+#include <algorithm>
+
+#include <vsip/support.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/impl/par-services.hpp>
+#include <vsip/impl/profile.hpp>
+#include <vsip/impl/par_assign.hpp>
+
+// Verbosity level:
+//  0 - no debug info
+//  1 - show functions called
+//  2 - message size details
+//  3 - data values
+
+#define VSIP_IMPL_PCA_VERBOSE 0
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+
+
+// Block-vector parallel assignment.
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+class Par_assign<Dim, T1, T2, Block1, Block2, Blkvec_assign>
+  : Compile_time_assert<Is_split_block<Block1>::value ==
+                        Is_split_block<Block2>::value>
+{
+  static dimension_type const dim = Dim;
+
+  // disable_copy should only be set to true for testing purposes.  It
+  // disables direct copy of data when source and destination are on
+  // the same processor, causing chains to be built on both sides.
+  // This is helps cover chain-to-chain copies for par-services-none.
+  static bool const disable_copy = false;
+
+  typedef typename Distributed_local_block<Block1>::type dst_local_block;
+  typedef typename Distributed_local_block<Block2>::type src_local_block;
+
+  typedef typename View_of_dim<dim, T1, dst_local_block>::type
+		dst_lview_type;
+
+  typedef typename View_of_dim<dim, T2, src_local_block>::const_type
+		src_lview_type;
+
+  typedef typename Block_layout<src_local_block>::layout_type raw_src_lp;
+  typedef typename Block_layout<dst_local_block>::layout_type raw_dst_lp;
+
+  typedef typename Adjust_layout_pack<Stride_unit_dense, raw_src_lp>::type
+		src_lp;
+  typedef typename Adjust_layout_pack<Stride_unit_dense, raw_dst_lp>::type
+		dst_lp;
+
+  typedef impl::Persistent_ext_data<src_local_block, src_lp> src_ext_type;
+  typedef impl::Persistent_ext_data<dst_local_block, dst_lp> dst_ext_type;
+
+  typedef typename Block1::map_type dst_appmap_t;
+  typedef typename Block2::map_type src_appmap_t;
+
+  typedef typename Block_layout<Block1>::order_type dst_order_t;
+
+  typedef impl::Communicator::request_type request_type;
+  typedef impl::Communicator::chain_type   chain_type;
+
+  /// A Msg_record holds a piece of a data transfer that together
+  /// describe a complete communication.
+  ///
+  /// Members:
+  ///   PROC_ is the remote processor (to send to or receive from),
+  ///   SUBBLOCK_ is the local subblock to,
+  ///   DATA_ is the raw data pointer of the local subblock,
+  ///   CHAIN_ is the DMA chain representing the data from subblock_
+  ///      to send.
+  ///
+  /// Notes:
+  ///   [1] CHAIN_ completely describes the data to send/receive,
+  ///       but it is dependent on the distributed blocks storage
+  ///       location remaining unchanged from when the list is built
+  ///       to when it is executed.  SUBBLOCK_ and DATA_ are stored
+  ///       to check consistentcy and potentially update CHAIN_ if
+  ///       the storage location changes.
+
+  struct Msg_record
+  {
+    Msg_record(processor_type proc, index_type sb, stride_type offset,
+	       length_type size)
+      : proc_    (proc),
+        subblock_(sb),
+	offset_  (offset),
+	size_    (size)
+      {}
+
+  public:
+    processor_type      proc_;    // destination processor
+    index_type          subblock_;
+    stride_type         offset_;
+    length_type         size_;
+  };
+
+
+
+  /// A Copy_record holds part of a data transfer where the source
+  /// and destination processors are the same.
+  ///
+  /// Members:
+  ///   SRC_SB_ is the source local subblock,
+  ///   DST_SB_ is the destination local subblock,
+  ///   SRC_DOM_ is the local domain within the source subblock to transfer,
+  ///   DST_DOM_ is the local domain within the destination subblock to
+  ///      transfer.
+
+  struct Copy_record
+  {
+    Copy_record(index_type src_sb, index_type dst_sb,
+	       Domain<Dim> src_dom,
+	       Domain<Dim> dst_dom)
+      : src_sb_  (src_sb),
+        dst_sb_  (dst_sb),
+	src_dom_ (src_dom),
+	dst_dom_ (dst_dom)
+      {}
+
+  public:
+    index_type     src_sb_;    // destination processor
+    index_type     dst_sb_;
+    Domain<Dim>    src_dom_;
+    Domain<Dim>    dst_dom_;
+  };
+
+
+  // Constructor.
+public:
+  Par_assign(
+    typename View_of_dim<Dim, T1, Block1>::type       dst,
+    typename View_of_dim<Dim, T2, Block2>::const_type src)
+    : dst_      (dst),
+      src_      (src.block()),
+      dst_am_   (dst_.block().map()),
+      src_am_   (src_.block().map()),
+      comm_     (dst_am_.impl_comm()),
+      send_list (),
+      recv_list (),
+      copy_list (),
+      req_list  (),
+      msg_count (0),
+      src_ext_  (src_.local().block(), impl::SYNC_IN),
+      dst_ext_  (dst_.local().block(), impl::SYNC_OUT)
+  {
+    impl::profile::Scope_event ev("Par_assign<Blkvec_assign>-cons");
+    assert(src_am_.impl_comm() == dst_am_.impl_comm());
+
+    build_send_list();
+    if (!disable_copy)
+      build_copy_list();
+    build_recv_list();
+  }
+
+  ~Par_assign()
+  {
+    // At destruction, the list of outstanding sends should be empty.
+    // This would be non-empty if:
+    //  - Par_assign did not to clear the lists after
+    //    processing it (library design error), or
+    //  - User executed send() without a corresponding wait().
+    assert(req_list.size() == 0);
+  }
+
+
+  // Implementation functions.
+private:
+
+  void build_send_list();
+  void build_recv_list();
+  void build_copy_list();
+
+  void exec_send_list();
+  void exec_recv_list();
+  void exec_copy_list();
+
+  void wait_send_list();
+
+  void cleanup() {}	// Cleanup send_list buffers.
+
+
+  // Invoke the parallel assignment
+public:
+  void operator()()
+  {
+    if (send_list.size() > 0) exec_send_list();
+    if (copy_list.size() > 0) exec_copy_list();
+    if (recv_list.size() > 0) exec_recv_list();
+
+    if (req_list.size() > 0)  wait_send_list();
+
+    cleanup();
+  }
+
+
+  // Private member data.
+private:
+  typename View_of_dim<Dim, T1, Block1>::type       dst_;
+  typename View_of_dim<Dim, T2, Block2>::const_type src_;
+
+  dst_appmap_t const& dst_am_;
+  src_appmap_t const& src_am_;
+  impl::Communicator& comm_;
+
+  std::vector<Msg_record>    send_list;
+  std::vector<Msg_record>    recv_list;
+  std::vector<Copy_record>   copy_list;
+
+  std::vector<request_type> req_list;
+
+  int                       msg_count;
+
+  src_ext_type              src_ext_;
+  dst_ext_type              dst_ext_;
+};
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Overload set for send, abstracts handling of interleaved- and
+// split- complex.
+
+template <typename T>
+void
+send(
+  impl::Communicator&                            comm,
+  processor_type                                 proc,
+  T*                                             data,
+  length_type                                    size,
+  std::vector<impl::Communicator::request_type>& req_list)
+{
+  impl::Communicator::request_type   req;
+  comm.send(proc, data, size, req);
+  req_list.push_back(req);
+}
+
+
+
+template <typename T>
+void
+send(
+  impl::Communicator&                            comm,
+  processor_type                                 proc,
+  std::pair<T*, T*> const&                       data,
+  length_type                                    size,
+  std::vector<impl::Communicator::request_type>& req_list)
+{
+  impl::Communicator::request_type   req1;
+  impl::Communicator::request_type   req2;
+  comm.send(proc, data.first,  size, req1);
+  comm.send(proc, data.second, size, req2);
+  req_list.push_back(req1);
+  req_list.push_back(req2);
+}
+
+
+
+// Overload set for recv, abstracts handling of interleaved- and
+// split- complex.
+
+template <typename T>
+inline void
+recv(
+  impl::Communicator& comm,
+  processor_type      proc,
+  T*                  data,
+  length_type         size)
+{
+  comm.recv(proc, data, size);
+}
+
+
+
+template <typename T>
+inline void
+recv(
+  impl::Communicator&      comm,
+  processor_type           proc,
+  std::pair<T*, T*> const& data,
+  length_type              size)
+{
+  comm.recv(proc, data.first, size);
+  comm.recv(proc, data.second, size);
+}
+
+
+
+// Build the send_list, a list of processor-subblock-local_domain
+// records.  This can be done in advance of the actual assignment.
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Blkvec_assign>::build_send_list()
+{
+  impl::profile::Scope_event ev("Par_assign<Blkvec_assign>-build_send_list");
+  processor_type rank = local_processor();
+
+  length_type dsize  = dst_am_.impl_working_size();
+  // std::min(dst_am_.num_subblocks(), dst_am_.impl_pvec().size());
+
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+    std::cout << "(" << rank << ") "
+	      << "build_send_list(dsize: " << dsize
+	      << ") -------------------------------------\n";
+#endif
+
+  index_type src_sb = src_am_.subblock(rank);
+
+  // If multiple processors have the subblock, the first processor
+  // is responsible for sending it.
+
+  if (src_sb != no_subblock &&
+      *(src_am_.processor_begin(src_sb)) == rank)
+  {
+    assert(num_patches(src_, src_sb) == 1);
+    Domain<dim> src_dom  = global_domain(src_, src_sb, 0);
+    Domain<dim> src_ldom = local_domain (src_, src_sb, 0);
+
+    src_ext_.begin();
+
+    // Iterate over all processors
+    for (index_type pi=0; pi<dsize; ++pi)
+    {
+      processor_type proc = dst_am_.impl_proc_from_rank(pi);
+
+      // Transfers that stay on this processor is handled by the copy_list.
+      if (!disable_copy && proc == rank)
+	continue;
+
+      index_type dst_sb = dst_am_.subblock(proc);
+
+      if (dst_sb != no_subblock)
+      {
+	// Check to see if destination processor already has block
+	if (!disable_copy && processor_has_block(src_am_, proc, src_sb))
+	  continue;
+
+	assert(num_patches(dst_, dst_sb) == 1);
+	Domain<dim> dst_dom  = global_domain(dst_, dst_sb, 0);
+	Domain<dim> intr;
+
+	if (intersect(src_dom, dst_dom, intr))
+	{
+	  Index<dim>  offset   = first(intr) - first(src_dom);
+	  Domain<dim> send_dom = domain(first(src_ldom) + offset,
+					extent(intr));
+
+	  stride_type xoff   = send_dom.first()  * src_ext_.stride(0);
+	  stride_type stride = send_dom.stride() * src_ext_.stride(0);
+	  length_type length = send_dom.length();
+	  assert(stride == 1);
+
+	  send_list.push_back(Msg_record(proc, src_sb, xoff, length));
+
+#if VSIP_IMPL_PCA_VERBOSE >= 2
+	      std::cout << "(" << rank << ") send "
+			<< rank << "/" << src_sb << "/" << 0
+			<< " -> "
+			<< proc << "/" << dst_sb << "/" << 0
+			<< " src: " << src_dom
+			<< " dst: " << dst_dom
+			<< " intr: " << intr
+			<< " send: " << send_dom
+		// << " val: " << get(local_view, first(send_dom))
+			<< std::endl;
+#endif
+	}
+	impl::profile::Scope_event ev("Par_assign<Blkvec_assign>-build_send_list-d");
+      }
+    }
+    src_ext_.end();
+  }
+}
+
+
+
+// Build the recv_list, a list of processor-subblock-local_domain
+// records.  This can be done in advance of the actual assignment.
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Blkvec_assign>::build_recv_list()
+{
+  impl::profile::Scope_event ev("Par_assign<Blkvec_assign>-build_recv_list");
+  processor_type rank = local_processor();
+
+  length_type ssize  = src_am_.impl_working_size();
+
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+    std::cout << "(" << rank << ") "
+	      << "build_recv_list(ssize: " << ssize
+	      << ") -------------------------------------\n";
+#endif
+
+  index_type dst_sb = dst_am_.subblock(rank);
+
+  if (dst_sb != no_subblock)
+  {
+    assert(num_patches(dst_, dst_sb) == 1);
+    Domain<dim> dst_dom  = global_domain(dst_, dst_sb, 0);
+    Domain<dim> dst_ldom = local_domain (dst_, dst_sb, 0);
+
+    dst_ext_.begin();
+      
+    // Iterate over all sending processors
+    for (index_type pi=0; pi<ssize; ++pi)
+    {
+      // Rotate message order so processors don't all send to 0,
+      // then 1, etc (Currently does not work, it needs to take into
+      // account the number of subblocks).
+      // processor_type proc = (src_am_.impl_proc_from_rank(pi) + rank) % size;
+      processor_type proc = src_am_.impl_proc_from_rank(pi);
+
+      // Transfers that stay on this processor is handled by the copy_list.
+      if (!disable_copy && proc == rank)
+	continue;
+      
+      index_type src_sb = src_am_.subblock(proc);
+
+      // If multiple processors have the subblock, the first processor
+      // is responsible for sending it to us.
+
+      if (src_sb != no_subblock &&
+	  *(src_am_.processor_begin(src_sb)) == proc)
+      {
+	// Check to see if destination processor already has block
+	if (!disable_copy && processor_has_block(src_am_, rank, src_sb))
+	  continue;
+
+	assert(num_patches(src_, src_sb) == 1);
+
+	Domain<dim> src_dom  = global_domain(src_, src_sb, 0);
+	    
+	Domain<dim> intr;
+	    
+	if (intersect(dst_dom, src_dom, intr))
+	{
+	  Index<dim>  offset   = first(intr) - first(dst_dom);
+	  Domain<dim> recv_dom = domain(first(dst_ldom) + offset,
+					extent(intr));
+
+	  ptrdiff_t   xoff   = recv_dom.first()  * dst_ext_.stride(0);
+	  stride_type stride = recv_dom.stride() * dst_ext_.stride(0);
+	  length_type length = recv_dom.length();
+	  assert(stride == 1);
+
+	  recv_list.push_back(Msg_record(proc, dst_sb, xoff, length));
+	      
+#if VSIP_IMPL_PCA_VERBOSE >= 2
+	      std::cout << "(" << rank << ") recv "
+			<< rank << "/" << dst_sb << "/" << 0
+			<< " <- "
+			<< proc << "/" << src_sb << "/" << 0
+			<< " dst: " << dst_dom
+			<< " src: " << src_dom
+			<< " intr: " << intr
+			<< " recv: " << recv_dom
+		// << " val: " << get(local_view, first(recv_dom))
+			<< std::endl;
+#endif
+	}
+      }
+    }
+    dst_ext_.end();
+  }
+}
+
+
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Blkvec_assign>::build_copy_list()
+{
+  impl::profile::Scope_event ev("Par_assign<Blkvec_assign>-build_copy_list");
+  processor_type rank = local_processor();
+
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+  std::cout << "(" << rank << ") "
+	    << "build_copy_list(num_procs: " << src_am_.num_processors()
+	    << ") -------------------------------------\n";
+#endif
+
+  index_type dst_sb = dst_am_.subblock(rank);
+  if (dst_sb != no_subblock)
+  {
+    index_type src_sb = src_am_.subblock(rank);
+    if (src_sb != no_subblock)
+    {
+      assert(num_patches(dst_, dst_sb) == 1);
+      Domain<dim> dst_dom  = global_domain(dst_, dst_sb, 0);
+      Domain<dim> dst_ldom = local_domain (dst_, dst_sb, 0);
+
+      assert(num_patches(src_, src_sb) == 1);
+      Domain<dim> src_dom  = global_domain(src_, src_sb, 0);
+      Domain<dim> src_ldom = local_domain (src_, src_sb, 0);
+
+      Domain<dim> intr;
+
+      if (intersect(src_dom, dst_dom, intr))
+      {
+	Index<dim>  send_offset = first(intr) - first(src_dom);
+	Domain<dim> send_dom    = domain(first(src_ldom) + send_offset,
+					 extent(intr));
+	Index<dim>  recv_offset = first(intr) - first(dst_dom);
+	Domain<dim> recv_dom    = domain(first(dst_ldom) + recv_offset,
+					 extent(intr));
+
+	copy_list.push_back(Copy_record(src_sb, dst_sb, send_dom, recv_dom));
+
+#if VSIP_IMPL_PCA_VERBOSE >= 2
+	std::cout << "(" << rank << ")"
+		  << "copy src: " << src_sb << "/" << sp
+		  << " " << send_dom
+		  << "  dst: " << dst_sb << "/" << dp
+		  << " " << recv_dom
+		  << std::endl;
+#endif
+      }
+    }
+  }
+}
+
+
+// Execute the send_list.
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Blkvec_assign>::exec_send_list()
+{
+  impl::profile::Scope_event ev("Par_assign<Blkvec_assign>-exec_send_list");
+
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+  processor_type rank = local_processor();
+  std::cout << "(" << rank << ") "
+	    << "exec_send_list(size: " << send_list.size()
+	    << ") -------------------------------------\n";
+#endif
+  typedef typename std::vector<Msg_record>::iterator sl_iterator;
+  typedef typename src_ext_type::storage_type storage_type;
+
+  sl_iterator sl_cur = send_list.begin();
+  sl_iterator sl_end = send_list.end();
+  for (; sl_cur != sl_end; ++sl_cur)
+  {
+    processor_type proc = (*sl_cur).proc_;
+
+    src_ext_.begin();
+    send(comm_, proc,
+	 storage_type::offset(src_ext_.data(), (*sl_cur).offset_),
+	 (*sl_cur).size_, req_list);
+    src_ext_.end();
+  }
+}
+
+
+
+// Execute the recv_list.
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Blkvec_assign>::exec_recv_list()
+{
+  impl::profile::Scope_event ev("Par_assign<Blkvec_assign>-exec_recv_list");
+
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+  processor_type rank = local_processor();
+  std::cout << "(" << rank << ") "
+	    << "exec_recv_list(size: " << recv_list.size()
+	    << ") -------------------------------------\n";
+#endif
+
+  typedef typename std::vector<Msg_record>::iterator rl_iterator;
+  typedef typename dst_ext_type::storage_type storage_type;
+
+  rl_iterator rl_cur = recv_list.begin();
+  rl_iterator rl_end = recv_list.end();
+    
+  for (; rl_cur != rl_end; ++rl_cur)
+  {
+    processor_type proc = (*rl_cur).proc_;
+
+    dst_ext_.begin();
+    recv(comm_, proc,
+	 storage_type::offset(dst_ext_.data(), (*rl_cur).offset_),
+	 (*rl_cur).size_);
+    dst_ext_.end();
+  }
+}
+
+
+
+// Execute the copy_list.
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Blkvec_assign>::exec_copy_list()
+{
+  impl::profile::Scope_event ev("Par_assign<Blkvec_assign>-exec_copy_list");
+
+#if VSIP_IMPL_PCA_VERBOSE >= 1
+  processor_type rank = local_processor();
+  std::cout << "(" << rank << ") "
+	    << "exec_copy_list(size: " << copy_list.size()
+	    << ") -------------------------------------\n";
+#endif
+
+  src_lview_type src_lview = get_local_view(src_);
+  dst_lview_type dst_lview = get_local_view(dst_);
+
+  typedef typename std::vector<Copy_record>::iterator cl_iterator;
+  for (cl_iterator cl_cur = copy_list.begin();
+       cl_cur != copy_list.end();
+       ++cl_cur)
+  {
+    view_assert_local(src_, (*cl_cur).src_sb_);
+    view_assert_local(dst_, (*cl_cur).dst_sb_);
+
+    dst_lview((*cl_cur).dst_dom_) = src_lview((*cl_cur).src_dom_);
+#if VSIP_IMPL_PCA_VERBOSE >= 2
+    std::cout << "(" << rank << ") "
+	      << "src subblock: " << (*cl_cur).src_sb_ << " -> "
+	      << "dst subblock: " << (*cl_cur).dst_sb_ << std::endl
+#if VSIP_IMPL_PCA_VERBOSE >= 3
+	      << dst_lview((*cl_cur).dst_dom_)
+#endif
+      ;
+#endif
+  }
+}
+
+
+
+// Wait for the send_list instructions to be completed.
+
+template <dimension_type Dim,
+	  typename       T1,
+	  typename       T2,
+	  typename       Block1,
+	  typename       Block2>
+void
+Par_assign<Dim, T1, T2, Block1, Block2, Blkvec_assign>::wait_send_list()
+{
+  typename std::vector<request_type>::iterator
+		cur = req_list.begin(),
+		end = req_list.end();
+  for(; cur != end; ++cur)
+  {
+    comm_.wait(*cur);
+  }
+  req_list.clear();
+}
+
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#undef VSIP_IMPL_PCA_VERBOSE
+
+#endif // VSIP_IMPL_PAR_ASSIGN_BLOCK_VECTOR_HPP
Index: src/vsip/impl/par-chain-assign.hpp
===================================================================
--- src/vsip/impl/par-chain-assign.hpp	(revision 145532)
+++ src/vsip/impl/par-chain-assign.hpp	(working copy)
@@ -18,9 +18,10 @@
 #include <algorithm>
 
 #include <vsip/support.hpp>
+#include <vsip/domain.hpp>
 #include <vsip/impl/par-services.hpp>
 #include <vsip/impl/profile.hpp>
-#include <vsip/domain.hpp>
+#include <vsip/impl/par_assign.hpp>
 
 #define VSIP_IMPL_PCA_ROTATE  0
 #define VSIP_IMPL_PCA_VERBOSE 0
@@ -165,7 +166,7 @@
 	  typename       T2,
 	  typename       Block1,
 	  typename       Block2>
-class Chained_parallel_assign
+class Par_assign<Dim, T1, T2, Block1, Block2, Chained_assign>
   : Compile_time_assert<Is_split_block<Block1>::value ==
                         Is_split_block<Block2>::value>
 {
@@ -262,7 +263,7 @@
 
   // Constructor.
 public:
-  Chained_parallel_assign(
+  Par_assign(
     typename View_of_dim<Dim, T1, Block1>::type       dst,
     typename View_of_dim<Dim, T2, Block2>::const_type src)
     : dst_      (dst),
@@ -278,7 +279,7 @@
       src_ext_ (new src_ext_type*[src_.block().map().num_subblocks()]),
       dst_ext_ (new dst_ext_type*[dst_.block().map().num_subblocks()])
   {
-    impl::profile::Scope_event ev("Chained_parallel_assign-cons");
+    impl::profile::Scope_event ev("Par_assign<Chained_assign>-cons");
     assert(src_am_.impl_comm() == dst_am_.impl_comm());
 
     par_chain_assign::build_ext_array<Dim, T2, Block2>(
@@ -292,11 +293,11 @@
     build_recv_list();
   }
 
-  ~Chained_parallel_assign()
+  ~Par_assign()
   {
     // At destruction, the list of outstanding sends should be empty.
     // This would be non-empty if:
-    //  - Chained_parallel_assign did not to clear the lists after
+    //  - Par_assign did not to clear the lists after
     //    processing it (library design error), or
     //  - User executed send() without a corresponding wait().
     assert(req_list.size() == 0);
@@ -435,9 +436,9 @@
 	  typename       Block1,
 	  typename       Block2>
 void
-Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::build_send_list()
+Par_assign<Dim, T1, T2, Block1, Block2, Chained_assign>::build_send_list()
 {
-  impl::profile::Scope_event ev("Chained_parallel_assign-build_send_list");
+  impl::profile::Scope_event ev("Par_assign<Chained_assign>-build_send_list");
   processor_type rank = local_processor();
 
 #if VSIPL_IMPL_PCA_ROTATE
@@ -541,9 +542,9 @@
 	  typename       Block1,
 	  typename       Block2>
 void
-Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::build_recv_list()
+Par_assign<Dim, T1, T2, Block1, Block2, Chained_assign>::build_recv_list()
 {
-  impl::profile::Scope_event ev("Chained_parallel_assign-build_recv_list");
+  impl::profile::Scope_event ev("Par_assign<Chained_assign>-build_recv_list");
   processor_type rank = local_processor();
 
 #if VSIPL_IMPL_PCA_ROTATE
@@ -641,9 +642,9 @@
 	  typename       Block1,
 	  typename       Block2>
 void
-Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::build_copy_list()
+Par_assign<Dim, T1, T2, Block1, Block2, Chained_assign>::build_copy_list()
 {
-  impl::profile::Scope_event ev("Chained_parallel_assign-build_copy_list");
+  impl::profile::Scope_event ev("Par_assign<Chained_assign>-build_copy_list");
   processor_type rank = local_processor();
 
 #if VSIP_IMPL_PCA_VERBOSE >= 1
@@ -713,9 +714,9 @@
 	  typename       Block1,
 	  typename       Block2>
 void
-Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::exec_send_list()
+Par_assign<Dim, T1, T2, Block1, Block2, Chained_assign>::exec_send_list()
 {
-  impl::profile::Scope_event ev("Chained_parallel_assign-exec_send_list");
+  impl::profile::Scope_event ev("Par_assign<Chained_assign>-exec_send_list");
 
 #if VSIP_IMPL_PCA_VERBOSE >= 1
   processor_type rank = local_processor();
@@ -757,9 +758,9 @@
 	  typename       Block1,
 	  typename       Block2>
 void
-Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::exec_recv_list()
+Par_assign<Dim, T1, T2, Block1, Block2, Chained_assign>::exec_recv_list()
 {
-  impl::profile::Scope_event ev("Chained_parallel_assign-exec_recv_list");
+  impl::profile::Scope_event ev("Par_assign<Chained_assign>-exec_recv_list");
 
 #if VSIP_IMPL_PCA_VERBOSE >= 1
   processor_type rank = local_processor();
@@ -798,9 +799,9 @@
 	  typename       Block1,
 	  typename       Block2>
 void
-Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::exec_copy_list()
+Par_assign<Dim, T1, T2, Block1, Block2, Chained_assign>::exec_copy_list()
 {
-  impl::profile::Scope_event ev("Chained_parallel_assign-exec_copy_list");
+  impl::profile::Scope_event ev("Par_assign<Chained_assign>-exec_copy_list");
 
 #if VSIP_IMPL_PCA_VERBOSE >= 1
   processor_type rank = local_processor();
@@ -840,7 +841,7 @@
 	  typename       Block1,
 	  typename       Block2>
 void
-Chained_parallel_assign<Dim, T1, T2, Block1, Block2>::wait_send_list()
+Par_assign<Dim, T1, T2, Block1, Block2, Chained_assign>::wait_send_list()
 {
   typename std::vector<request_type>::iterator
 		cur = req_list.begin(),
Index: src/vsip/impl/par-services-mpi.hpp
===================================================================
--- src/vsip/impl/par-services-mpi.hpp	(revision 145532)
+++ src/vsip/impl/par-services-mpi.hpp	(working copy)
@@ -29,6 +29,8 @@
 #include VSIP_IMPL_MPI_H
 #include <vsip/support.hpp>
 #include <vsip/impl/reductions-types.hpp>
+#include <vsip/impl/profile.hpp>
+#include <vsip/impl/par_assign.hpp>
 
 
 
@@ -317,6 +319,7 @@
 
 typedef mpi::Communicator Communicator;
 typedef mpi::Chain_builder Chain_builder;
+typedef Chained_assign par_assign_impl_type;
 
 inline void
 free_chain(MPI_Datatype chain)
Index: src/vsip/map.hpp
===================================================================
--- src/vsip/map.hpp	(revision 145532)
+++ src/vsip/map.hpp	(working copy)
@@ -1283,12 +1283,46 @@
 struct Is_global_map<Map<Dist0, Dist1, Dist2> >
 { static bool const value = true; };
 
+template <dimension_type Dim,
+          typename       Map>
+struct Select_dist;
 
+template <typename Dist0,
+	  typename Dist1,
+	  typename Dist2>
+struct Select_dist<0, Map<Dist0, Dist1, Dist2> >
+{ typedef Dist0 type; };
 
+template <typename Dist0,
+	  typename Dist1,
+	  typename Dist2>
+struct Select_dist<1, Map<Dist0, Dist1, Dist2> >
+{ typedef Dist1 type; };
+
+template <typename Dist0,
+	  typename Dist1,
+	  typename Dist2>
+struct Select_dist<2, Map<Dist0, Dist1, Dist2> >
+{ typedef Dist2 type; };
+
 template <dimension_type Dim,
 	  typename       Dist0,
 	  typename       Dist1,
 	  typename       Dist2>
+struct Is_block_dist<Dim, Map<Dist0, Dist1, Dist2> >
+{
+private:
+  typedef typename Select_dist<Dim, Map<Dist0, Dist1, Dist2> >::type dist_type;
+public:
+  static bool const value = Type_equal<dist_type, Block_dist>::value ||
+                            Type_equal<dist_type, Whole_dist>::value;
+};
+
+
+template <dimension_type Dim,
+	  typename       Dist0,
+	  typename       Dist1,
+	  typename       Dist2>
 struct Map_equal<Dim, Map<Dist0, Dist1, Dist2>, Map<Dist0, Dist1, Dist2> >
 {
   static bool value(Map<Dist0, Dist1, Dist2> const& map1,
Index: tests/parallel/block.cpp
===================================================================
--- tests/parallel/block.cpp	(revision 145532)
+++ tests/parallel/block.cpp	(working copy)
@@ -112,15 +112,11 @@
 //    data back onto processor 0.
 //  - Check data in view0.
 
-template <template <dimension_type,
-		    typename,
-		    typename,
-		    typename,
-		    typename> class Par_assign,
-	  typename                  T,
-	  dimension_type            Dim,
-	  typename                  Map1,
-	  typename                  Map2>
+template <typename       ParAssignTag,
+	  typename       T,
+	  dimension_type Dim,
+	  typename       Map1,
+	  typename       Map2>
 void
 test_distributed_view(
   Domain<Dim> dom,
@@ -154,11 +150,11 @@
   impl::Communicator comm = impl::default_communicator();
 
   // Declare assignments, allows early binding to be done.
-  Par_assign<Dim, T, T, dist_block1_t, dist_block0_t>
+  impl::Par_assign<Dim, T, T, dist_block1_t, dist_block0_t, ParAssignTag>
 		a1(view1, view0);
-  Par_assign<Dim, T, T, dist_block2_t, dist_block1_t>
+  impl::Par_assign<Dim, T, T, dist_block2_t, dist_block1_t, ParAssignTag>
 		a2(view2, view1);
-  Par_assign<Dim, T, T, dist_block0_t, dist_block2_t>
+  impl::Par_assign<Dim, T, T, dist_block0_t, dist_block2_t, ParAssignTag>
 		a3(view0, view2);
 
   // cout << "(" << local_processor() << "): test_distributed_view\n";
@@ -362,30 +358,26 @@
 // Test several distributed vector cases for a given type and parallel
 // assignment implementation.
 
-template <template <dimension_type,
-		    typename,
-		    typename,
-		    typename,
-		    typename> class Par_assign,
-	  typename                  T>
+template <typename ParAssignTag,
+	  typename T>
 void
 test_vector(int loop)
 {
   processor_type np = num_processors();
 
-  test_distributed_view<Par_assign, T>(
+  test_distributed_view<ParAssignTag, T>(
     Domain<1>(16),
     Map<Block_dist>(Block_dist(np)),
     Map<Cyclic_dist>(Cyclic_dist(np)),
     loop);
 
-  test_distributed_view<Par_assign, T>(
+  test_distributed_view<ParAssignTag, T>(
     Domain<1>(16),
     Map<Cyclic_dist>(Cyclic_dist(np)),
     Map<Block_dist>(Block_dist(np)),
     loop);
 
-  test_distributed_view<Par_assign, T>(
+  test_distributed_view<ParAssignTag, T>(
     Domain<1>(256),
     Map<Cyclic_dist>(Cyclic_dist(np, 4)),
     Map<Cyclic_dist>(Cyclic_dist(np, 3)),
@@ -397,37 +389,33 @@
 // Test several distributed matrix cases for a given type and parallel
 // assignment implementation.
 
-template <template <dimension_type,
-		    typename,
-		    typename,
-		    typename,
-		    typename> class Par_assign,
-	  typename                  T>
+template <typename ParAssignTag,
+	  typename T>
 void
 test_matrix(int loop)
 {
   processor_type np, nr, nc;
   get_np_half(np, nr, nc);
 
-  test_distributed_view<Par_assign, T>(
+  test_distributed_view<ParAssignTag, T>(
     Domain<2>(4, 4),
     Map<>(Block_dist(np), Block_dist(1)),
     Map<>(Block_dist(1),  Block_dist(np)),
     loop);
 
-  test_distributed_view<Par_assign, T>(
+  test_distributed_view<ParAssignTag, T>(
     Domain<2>(16, 16),
     Map<>(Block_dist(nr), Block_dist(nc)),
     Map<>(Block_dist(nc), Block_dist(nr)),
     loop);
 			  
-  test_distributed_view<Par_assign, T>(
+  test_distributed_view<ParAssignTag, T>(
     Domain<2>(16, 16),
     Map<Cyclic_dist, Block_dist>(Cyclic_dist(nr, 2), Block_dist(nc)),
     Map<Block_dist, Cyclic_dist>(Block_dist(nc),    Cyclic_dist(nr, 2)),
     loop);
 
-  test_distributed_view<Par_assign, T>(
+  test_distributed_view<ParAssignTag, T>(
     Domain<2>(256, 256),
     Map<>(Block_dist(nr), Block_dist(nc)),
     Map<>(Block_dist(nc), Block_dist(nr)),
@@ -605,8 +593,8 @@
   test_vector_assign<float>(loop);
   test_matrix_assign<float>(loop);
 
-  test_vector<impl::Chained_parallel_assign,   float>(loop);
-  test_matrix<impl::Chained_parallel_assign,   float>(loop);
+  test_vector<impl::Chained_assign,   float>(loop);
+  test_matrix<impl::Chained_assign,   float>(loop);
 
   test_local_view<float>(Domain<1>(2), Map<>(Block_dist(np)));
   test_local_view<float>(Domain<1>(2), Map<>(Block_dist(np > 1 ? np-1 : 1)));
@@ -618,8 +606,8 @@
   test_vector_assign<complex<float> >(loop);
   test_matrix_assign<complex<float> >(loop);
 
-  test_vector<impl::Chained_parallel_assign,   complex<float> >(loop);
-  test_matrix<impl::Chained_parallel_assign,   complex<float> >(loop);
+  test_vector<impl::Chained_assign,   complex<float> >(loop);
+  test_matrix<impl::Chained_assign,   complex<float> >(loop);
 
   test_local_view<complex<float> >(Domain<1>(2), Map<>(Block_dist(np)));
   test_local_view<complex<float> >(Domain<1>(2), Map<>(Block_dist(np > 1 ? np-1 : 1)));
Index: benchmarks/dist_vmul.cpp
===================================================================
--- benchmarks/dist_vmul.cpp	(revision 0)
+++ benchmarks/dist_vmul.cpp	(revision 0)
@@ -0,0 +1,395 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    benchmarks/dist_vmul.cpp
+    @author  Jules Bergmann
+    @date    2006-07-21
+    @brief   VSIPL++ Library: Benchmark for distributed vector multiply.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+#include <vsip/impl/setup-assign.hpp>
+#include "benchmarks.hpp"
+
+using namespace vsip;
+
+
+
+/***********************************************************************
+  Utilities
+***********************************************************************/
+
+// Create a map of a given pattern.
+
+inline Map<>
+create_map(char type)
+{
+  length_type np = num_processors();
+  switch(type)
+  {
+  default:
+  case 'a': // all processors
+    return Map<>(num_processors());
+  case '1': // first processor
+    return Map<>(1);
+  case '2': // last processor
+  {
+    Vector<processor_type> pset(1); pset.put(0, np-1);
+    return Map<>(pset, 1);
+  }
+  case 'b': // non-root processors
+  {
+    Vector<processor_type> pset(np-1);
+    for (index_type i=0; i<np-1; ++i)
+      pset.put(i, i+1);
+    return Map<>(pset, np-1);
+  }
+  case 'w': // worker processrs (non-root and non-last)
+  {
+    Vector<processor_type> pset(np-2);
+    for (index_type i=0; i<np-2; ++i)
+      pset.put(i, i+1);
+    return Map<>(pset, np-2);
+  }
+  }
+}
+
+
+
+// Sync Policy: use barrier.
+
+struct Barrier
+{
+  Barrier() : comm_(DEFAULT_COMMUNICATOR()) {}
+
+  void sync() { BARRIER(comm_); }
+
+  COMMUNICATOR_TYPE comm_;
+};
+
+
+
+// Sync Policy: no barrier.
+
+struct No_barrier
+{
+  No_barrier() {}
+
+  void sync() {}
+};
+
+
+
+/***********************************************************************
+  Definitions - distributed vector element-wise multiply
+***********************************************************************/
+
+struct Impl_assign;
+struct Impl_sa;
+
+template <typename T,
+	  typename MapT    = Local_map,
+	  typename SP      = No_barrier,
+	  typename ImplTag = Impl_assign>
+struct t_dist_vmul;
+
+
+
+/***********************************************************************
+  Assign
+***********************************************************************/
+
+template <typename T,
+	  typename MapT,
+	  typename SP>
+struct t_dist_vmul<T, MapT, SP, Impl_assign>
+{
+  char* what() { return "t_vmul"; }
+  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    typedef Dense<1, T, row1_type, MapT> block_type;
+
+    T a_freq = 0.15f;
+    T b_freq = 0.15f;
+
+    Vector<T, block_type> A(size, map_compute_);
+    Vector<T, block_type> B(size, map_compute_);
+    Vector<T, block_type> C(size, map_compute_);
+
+    Vector<T, block_type> A_in (size, T(), map_in_);
+    Vector<T, block_type> B_in (size, T(), map_in_);
+    Vector<T, block_type> C_out(size,      map_out_);
+
+    for (index_type i=0; i<A_in.local().size(); ++i)
+    {
+      // A_in and B_in have same map.
+      index_type g_i = global_from_local_index(A_in, 0, i);
+      A_in.local().put(i, cos(3.1415f * a_freq * T(g_i)));
+      B_in.local().put(i, cos(3.1415f * b_freq * T(g_i)));
+    }
+
+    vsip::impl::profile::Timer t1;
+    SP sp;
+    
+    t1.start();
+    sp.sync();
+    for (index_type l=0; l<loop; ++l)
+    {
+      // scatter data
+      A = A_in;
+      B = B_in;
+      // perform operation
+      C = A * B;
+      // gather result
+      C_out = C;
+    }
+    sp.sync();
+    t1.stop();
+    
+    for (index_type i=0; i<C_out.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(C_out, 0, i);
+      T a_val = cos(3.1415f * a_freq * T(g_i));
+      T b_val = cos(3.1415f * b_freq * T(g_i));
+      test_assert(equal(C_out.local().get(i), a_val * b_val));
+    }
+    
+    time = t1.delta();
+  }
+
+  t_dist_vmul(MapT map_compute, MapT map_in, MapT map_out)
+    : map_compute_(map_compute),
+      map_in_     (map_in),
+      map_out_    (map_out)
+  {}
+
+  // Member data
+  MapT map_compute_;
+  MapT map_in_;
+  MapT map_out_;
+};
+
+
+
+/***********************************************************************
+  Setup-assign
+***********************************************************************/
+
+template <typename T,
+	  typename MapT,
+	  typename SP>
+struct t_dist_vmul<T, MapT, SP, Impl_sa>
+{
+  char* what() { return "t_vmul"; }
+  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    typedef Dense<1, T, row1_type, MapT> block_type;
+
+    T a_freq = 0.15f;
+    T b_freq = 0.15f;
+
+    Vector<T, block_type> A(size, map_compute_);
+    Vector<T, block_type> B(size, map_compute_);
+    Vector<T, block_type> C(size, map_compute_);
+
+    Vector<T, block_type> A_in (size, T(), map_in_);
+    Vector<T, block_type> B_in (size, T(), map_in_);
+    Vector<T, block_type> C_out(size,      map_out_);
+
+    for (index_type i=0; i<A_in.local().size(); ++i)
+    {
+      // A_in and B_in have same map.
+      index_type g_i = global_from_local_index(A_in, 0, i);
+      A_in.local().put(i, cos(3.1415f * a_freq * T(g_i)));
+      B_in.local().put(i, cos(3.1415f * b_freq * T(g_i)));
+    }
+
+    vsip::impl::profile::Timer t1;
+    SP sp;
+
+    Setup_assign scatter_A(A, A_in);
+    Setup_assign scatter_B(B, B_in);
+    Setup_assign gather   (C_out, C);
+    
+    t1.start();
+    sp.sync();
+    for (index_type l=0; l<loop; ++l)
+    {
+      // scatter data
+      scatter_A();
+      scatter_B();
+
+      // perform operation
+      C = A * B;
+
+      // gather result
+      gather();
+    }
+    sp.sync();
+    t1.stop();
+    
+    for (index_type i=0; i<C_out.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(C_out, 0, i);
+      T a_val = cos(3.1415f * a_freq * T(g_i));
+      T b_val = cos(3.1415f * b_freq * T(g_i));
+      test_assert(equal(C_out.local().get(i), a_val * b_val));
+    }
+    
+    time = t1.delta();
+  }
+
+  t_dist_vmul(MapT map_compute, MapT map_in, MapT map_out)
+    : map_compute_(map_compute),
+      map_in_     (map_in),
+      map_out_    (map_out)
+  {}
+
+  // Member data
+  MapT map_compute_;
+  MapT map_in_;
+  MapT map_out_;
+};
+
+
+
+/***********************************************************************
+  Wrapper classes
+***********************************************************************/
+
+// Local wrapper.
+
+template <typename T,
+	  typename ImplTag,
+	  typename SP = No_barrier>
+struct t_dist_vmul_local
+  : public t_dist_vmul<T, Local_map, SP, ImplTag>
+{
+  typedef t_dist_vmul<T, Local_map, SP, ImplTag> base_type;
+
+  t_dist_vmul_local()
+    : base_type(Local_map(), Local_map(), Local_map())
+  {}
+};
+
+
+
+// Clique parallelism wrapper.
+
+template <typename T,
+	  typename ImplTag,
+	  typename SP   = No_barrier>
+struct t_dist_vmul_par
+  : public t_dist_vmul<T, Map<>, SP, ImplTag>
+{
+  typedef t_dist_vmul<T, Map<>, SP, ImplTag> base_type;
+
+  t_dist_vmul_par()
+    : base_type(Map<>(num_processors()),
+		Map<>(1),
+		Map<>(1))
+  {
+    if (num_processors() == 1)
+    {
+      this->map_in_  = this->map_compute_;
+      this->map_out_ = this->map_compute_;
+    }
+  }
+};
+
+
+
+// Pipeline parallelism wrapper.
+
+template <typename T,
+	  typename ImplTag,
+	  typename SP   = No_barrier>
+struct t_dist_vmul_pipe
+  : public t_dist_vmul<T, Map<>, SP, ImplTag>
+{
+  typedef t_dist_vmul<T, Map<>, SP, ImplTag> base_type;
+
+  t_dist_vmul_pipe()
+    : base_type(create_map('w'),
+		create_map('1'),
+		create_map('2'))
+  {}
+};
+
+
+
+/***********************************************************************
+  Benchmark Definitions
+***********************************************************************/
+
+void
+defaults(Loop1P&)
+{
+}
+
+
+
+int
+test(Loop1P& loop, int what)
+{
+  switch (what)
+  {
+  case  11: loop(t_dist_vmul_local<float,          Impl_assign>()); break;
+  case  12: loop(t_dist_vmul_local<complex<float>, Impl_assign>()); break;
+  case  21: loop(t_dist_vmul_par<float,            Impl_assign>()); break;
+  case  22: loop(t_dist_vmul_par<complex<float>,   Impl_assign>()); break;
+  case  31: loop(t_dist_vmul_pipe<float,           Impl_assign>()); break;
+  case  32: loop(t_dist_vmul_pipe<complex<float>,  Impl_assign>()); break;
+
+  case  41: loop(t_dist_vmul_local<float,          Impl_sa>()); break;
+  case  42: loop(t_dist_vmul_local<complex<float>, Impl_sa>()); break;
+  case  51: loop(t_dist_vmul_par<float,            Impl_sa>()); break;
+  case  52: loop(t_dist_vmul_par<complex<float>,   Impl_sa>()); break;
+  case  61: loop(t_dist_vmul_pipe<float,           Impl_sa>()); break;
+  case  72: loop(t_dist_vmul_pipe<complex<float>,  Impl_sa>()); break;
+
+  case 0:
+    std::cout
+      << "dist_vmul -- distributed vector multiplication\n"
+      << " Using Assignment\n"
+      << "  -11 -- Local vmul (non-parallel) - float\n"
+      << "  -12 -- Local vmul (non-parallel) - complex\n"
+      << "  -21 -- Clique vmul               - float\n"
+      << "  -22 -- Clique vmul               - complex\n"
+      << "  -31 -- Pipelined vmul            - float\n"
+      << "  -32 -- Pipelined vmul            - complex\n"
+      << " Using Setup_assign\n"
+      << "  -41 -- Local vmul (non-parallel) - float\n"
+      << "  -42 -- Local vmul (non-parallel) - complex\n"
+      << "  -51 -- Clique vmul               - float\n"
+      << "  -52 -- Clique vmul               - complex\n"
+      << "  -61 -- Pipelined vmul            - float\n"
+      << "  -62 -- Pipelined vmul            - complex\n"
+      ;
+
+  default:
+    return 0;
+  }
+  return 1;
+}
Index: benchmarks/copy.cpp
===================================================================
--- benchmarks/copy.cpp	(revision 145532)
+++ benchmarks/copy.cpp	(working copy)
@@ -35,9 +35,10 @@
   Declarations
 ***********************************************************************/
 
-struct Impl_assign;
-struct Impl_sa;
-struct Impl_cpa;
+struct Impl_assign;				// normal assignment
+struct Impl_sa;					// Setup_assign object
+template <typename Impl> struct Impl_pa;	// Par_assign<Impl> object
+template <typename Impl> struct Impl_pa_na;	//  " " (not amortized)
 
 template <typename T,
 	  typename SrcMapT,
@@ -106,15 +107,16 @@
 
 
 /***********************************************************************
-  Vector copy - Chained_parallel_assign
+  Vector copy - Chained_assign
 ***********************************************************************/
 
 template <typename T,
 	  typename SrcMapT,
-	  typename DstMapT>
-struct t_vcopy<T, SrcMapT, DstMapT, Impl_cpa>
+	  typename DstMapT,
+	  typename ParAssignImpl>
+struct t_vcopy<T, SrcMapT, DstMapT, Impl_pa<ParAssignImpl> >
 {
-  char* what() { return "t_vcopy<..., Impl_cpa>"; }
+  char* what() { return "t_vcopy<..., Impl_pa>"; }
   int ops_per_point(length_type)  { return 1; }
   int riob_per_point(length_type) { return 1*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
@@ -136,7 +138,8 @@
     
     vsip::impl::profile::Timer t1;
 
-    vsip::impl::Chained_parallel_assign<dim, T, T, dst_block_t, src_block_t>
+    vsip::impl::Par_assign<dim, T, T, dst_block_t, src_block_t,
+                           ParAssignImpl>
       cpa(Z, A);
     t1.start();
     for (index_type l=0; l<loop; ++l)
@@ -165,6 +168,64 @@
 
 
 
+template <typename T,
+	  typename SrcMapT,
+	  typename DstMapT,
+	  typename ParAssignImpl>
+struct t_vcopy<T, SrcMapT, DstMapT, Impl_pa_na<ParAssignImpl> >
+{
+  char* what() { return "t_vcopy<..., Impl_pa_na>"; }
+  int ops_per_point(length_type)  { return 1; }
+  int riob_per_point(length_type) { return 1*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 1*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    dimension_type const dim = 1;
+    typedef Dense<1, T, row1_type, SrcMapT> src_block_t;
+    typedef Dense<1, T, row1_type, DstMapT> dst_block_t;
+    Vector<T, src_block_t>   A(size, T(), src_map_);
+    Vector<T, dst_block_t>   Z(size,      dst_map_);
+
+    for (index_type i=0; i<A.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(A, 0, i);
+      A.local().put(i, T(g_i));
+    }
+    
+    vsip::impl::profile::Timer t1;
+
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      vsip::impl::Par_assign<dim, T, T, dst_block_t, src_block_t,
+                             ParAssignImpl>
+	cpa(Z, A);
+      cpa();
+    }
+    t1.stop();
+    
+    for (index_type i=0; i<Z.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(Z, 0, i);
+      test_assert(equal(Z.local().get(i), T(g_i)));
+    }
+    
+    time = t1.delta();
+  }
+
+  t_vcopy(SrcMapT src_map, DstMapT dst_map)
+    : src_map_(src_map), dst_map_(dst_map)
+  {}
+
+  // Member data.
+  SrcMapT	src_map_;
+  DstMapT	dst_map_;
+};
+
+
+
 /***********************************************************************
   Vector copy - early-binding (setup_assign)
 ***********************************************************************/
@@ -251,6 +312,7 @@
   length_type np = num_processors();
   switch(type)
   {
+  default:
   case 'a':
     // 'a' - all processors
     return Map<>(num_processors());
@@ -272,7 +334,6 @@
     return Map<>(pset, np-1);
   }
   }
-      
 }
 
 template <typename T,
@@ -297,12 +358,15 @@
 int
 test(Loop1P& loop, int what)
 {
+  typedef vsip::impl::Chained_assign  Ca;
+  typedef vsip::impl::Blkvec_assign   Bva;
+
   switch (what)
   {
   case  1: loop(t_vcopy_local<float, Impl_assign>()); break;
   case  2: loop(t_vcopy_root<float, Impl_assign>()); break;
   case  3: loop(t_vcopy_root<float, Impl_sa>()); break;
-  case  4: loop(t_vcopy_root<float, Impl_cpa>()); break;
+  case  4: loop(t_vcopy_root<float, Impl_pa<Ca> >()); break;
 
   case 10: loop(t_vcopy_redist<float, Impl_assign>('1', '1')); break;
   case 11: loop(t_vcopy_redist<float, Impl_assign>('1', 'a'));  break;
@@ -311,6 +375,8 @@
   case 14: loop(t_vcopy_redist<float, Impl_assign>('1', '2')); break;
   case 15: loop(t_vcopy_redist<float, Impl_assign>('1', 'b')); break;
 
+  case 16: loop(t_vcopy_redist<complex<float>, Impl_assign>('1', '2')); break;
+
   case 20: loop(t_vcopy_redist<float, Impl_sa>('1', '1')); break;
   case 21: loop(t_vcopy_redist<float, Impl_sa>('1', 'a')); break;
   case 22: loop(t_vcopy_redist<float, Impl_sa>('a', '1')); break;
@@ -318,13 +384,36 @@
   case 24: loop(t_vcopy_redist<float, Impl_sa>('1', '2')); break;
   case 25: loop(t_vcopy_redist<float, Impl_sa>('1', 'b')); break;
 
-  case 30: loop(t_vcopy_redist<float, Impl_cpa>('1', '1')); break;
-  case 31: loop(t_vcopy_redist<float, Impl_cpa>('1', 'a')); break;
-  case 32: loop(t_vcopy_redist<float, Impl_cpa>('a', '1')); break;
-  case 33: loop(t_vcopy_redist<float, Impl_cpa>('a', 'a')); break;
-  case 34: loop(t_vcopy_redist<float, Impl_cpa>('1', '2')); break;
-  case 35: loop(t_vcopy_redist<float, Impl_cpa>('1', 'b')); break;
+  case 26: loop(t_vcopy_redist<complex<float>, Impl_sa>('1', '2')); break;
 
+  case 30: loop(t_vcopy_redist<float, Impl_pa<Ca> >('1', '1')); break;
+  case 31: loop(t_vcopy_redist<float, Impl_pa<Ca> >('1', 'a')); break;
+  case 32: loop(t_vcopy_redist<float, Impl_pa<Ca> >('a', '1')); break;
+  case 33: loop(t_vcopy_redist<float, Impl_pa<Ca> >('a', 'a')); break;
+  case 34: loop(t_vcopy_redist<float, Impl_pa<Ca> >('1', '2')); break;
+  case 35: loop(t_vcopy_redist<float, Impl_pa<Ca> >('1', 'b')); break;
+
+  case 40: loop(t_vcopy_redist<float, Impl_pa<Bva> >('1', '1')); break;
+  case 41: loop(t_vcopy_redist<float, Impl_pa<Bva> >('1', 'a')); break;
+  case 42: loop(t_vcopy_redist<float, Impl_pa<Bva> >('a', '1')); break;
+  case 43: loop(t_vcopy_redist<float, Impl_pa<Bva> >('a', 'a')); break;
+  case 44: loop(t_vcopy_redist<float, Impl_pa<Bva> >('1', '2')); break;
+  case 45: loop(t_vcopy_redist<float, Impl_pa<Bva> >('1', 'b')); break;
+
+  case 50: loop(t_vcopy_redist<float, Impl_pa_na<Ca> >('1', '1')); break;
+  case 51: loop(t_vcopy_redist<float, Impl_pa_na<Ca> >('1', 'a')); break;
+  case 52: loop(t_vcopy_redist<float, Impl_pa_na<Ca> >('a', '1')); break;
+  case 53: loop(t_vcopy_redist<float, Impl_pa_na<Ca> >('a', 'a')); break;
+  case 54: loop(t_vcopy_redist<float, Impl_pa_na<Ca> >('1', '2')); break;
+  case 55: loop(t_vcopy_redist<float, Impl_pa_na<Ca> >('1', 'b')); break;
+
+  case 60: loop(t_vcopy_redist<float, Impl_pa_na<Bva> >('1', '1')); break;
+  case 61: loop(t_vcopy_redist<float, Impl_pa_na<Bva> >('1', 'a')); break;
+  case 62: loop(t_vcopy_redist<float, Impl_pa_na<Bva> >('a', '1')); break;
+  case 63: loop(t_vcopy_redist<float, Impl_pa_na<Bva> >('a', 'a')); break;
+  case 64: loop(t_vcopy_redist<float, Impl_pa_na<Bva> >('1', '2')); break;
+  case 65: loop(t_vcopy_redist<float, Impl_pa_na<Bva> >('1', 'b')); break;
+
   case 0:
     std::cout
       << "copy -- vector copy\n"
Index: benchmarks/loop.hpp
===================================================================
--- benchmarks/loop.hpp	(revision 145532)
+++ benchmarks/loop.hpp	(working copy)
@@ -19,6 +19,7 @@
 
 #include <vsip/vector.hpp>
 #include <vsip/math.hpp>
+#include <vsip/parallel.hpp>
 
 #ifdef VSIP_IMPL_SOURCERY_VPP
 #  define PARALLEL_LOOP 1
@@ -102,6 +103,7 @@
     start_	 (2),
     stop_	 (21),
     cal_	 (4),
+    do_cal_      (true),
     loop_start_	 (10),
     samples_	 (1),
     goal_sec_	 (1.0),
@@ -143,6 +145,7 @@
   unsigned	start_;		// loop start power-of-two
   unsigned	stop_;		// loop stop power-of-two
   int	 	cal_;		// calibration power-of-two
+  bool          do_cal_;	// perform calibration
   int	 	loop_start_;
   unsigned	samples_;
   double        goal_sec_;	// measurement goal (in seconds)
@@ -265,6 +268,8 @@
   M    = this->m_value(cal_);
 
   // calibrate --------------------------------------------------------
+  if (do_cal_)
+  {
   while (1)
   {
     // printf("%d: calib %5d\n", rank, loop);
@@ -296,6 +301,7 @@
     if (factor >= 0.75 && factor <= 1.25)
       break;
   }
+  }
 
   if (rank == 0)
   {
@@ -344,7 +350,8 @@
     if (this->do_prof_)
     {
       char     filename[256];
-      sprintf(filename, "vprof.%lu.out", (unsigned long) M);
+      sprintf(filename, "vprof.%lu-%lu.out", (unsigned long) M,
+	      (unsigned long)vsip::local_processor());
       vsip::impl::profile::prof->dump(filename);
     }
 #endif
Index: benchmarks/vmul.cpp
===================================================================
--- benchmarks/vmul.cpp	(revision 145532)
+++ benchmarks/vmul.cpp	(working copy)
@@ -324,14 +324,14 @@
     vsip::impl::profile::Timer t1;
     SP sp;
     
+    Setup_assign expr(C, A*B);
     t1.start();
-    Setup_assign expr(C, A*B);
     sp.sync();
     for (index_type l=0; l<loop; ++l)
       expr();
     sp.sync();
     t1.stop();
-    
+
     for (index_type i=0; i<size; ++i)
       test_assert(equal(C.get(i), A.get(i) * B.get(i)));
     
Index: benchmarks/main.cpp
===================================================================
--- benchmarks/main.cpp	(revision 145532)
+++ benchmarks/main.cpp	(working copy)
@@ -12,6 +12,9 @@
 ***********************************************************************/
 
 #include <iostream>
+#if defined(_MC_EXEC)
+#  include <unistd.h>
+#endif
 
 #include <vsip/initfin.hpp>
 
@@ -40,6 +43,7 @@
 
   Loop1P loop;
   bool   verbose = false;
+  bool   pause   = false;
 
   loop.goal_sec_ = 0.25;
   defaults(loop);
@@ -67,6 +71,8 @@
       loop.goal_sec_ = (double)atoi(argv[++i])/100;
     else if (!strcmp(argv[i], "-verbose"))
       verbose = true;
+    else if (!strcmp(argv[i], "-pause"))
+      pause = true;
     else if (!strcmp(argv[i], "-param"))
       loop.user_param_ = atoi(argv[++i]);
     else if (!strcmp(argv[i], "-ops"))
@@ -101,6 +107,8 @@
       loop.show_time_ = true;
     else if (!strcmp(argv[i], "-steady"))
       loop.mode_ = steady_mode;
+    else if (!strcmp(argv[i], "-nocal"))
+      loop.do_cal_ = false;
     else if (!strcmp(argv[i], "-single"))
     {
       loop.mode_ = single_mode;
@@ -116,6 +124,22 @@
     std::cout << "sec  = " << loop.goal_sec_ << std::endl;
   }
 
+  if (pause)
+  {
+    // Enable this section for easier debugging.
+    impl::Communicator comm = impl::default_communicator();
+    pid_t pid = getpid();
+
+    std::cout << "rank: "   << comm.rank()
+	      << "  size: " << comm.size()
+	      << "  pid: "  << pid
+	      << std::endl;
+
+    // Stop each process, allow debugger to be attached.
+    if (comm.rank() == 0) getchar();
+    comm.barrier();
+  }
+
   loop.what_ = what;
 
   test(loop, what);
Index: examples/fft.cpp
===================================================================
--- examples/fft.cpp	(revision 145532)
+++ examples/fft.cpp	(working copy)
@@ -50,7 +50,7 @@
   Vector<cscalar_f> ref(N);
 
   // Create input test data
-  for ( int i = 0; i < N; ++i )
+  for ( index_type i = 0; i < N; ++i )
     in(i) = sin(2 * M_PI * i / N);
 
   // Compute discrete transform (for reference)
