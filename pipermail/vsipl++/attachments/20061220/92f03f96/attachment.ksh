Index: ChangeLog
===================================================================
--- ChangeLog	(revision 158196)
+++ ChangeLog	(working copy)
@@ -1,5 +1,19 @@
 2006-12-20  Jules Bergmann  <jules@codesourcery.com>
+
+	Move Ext_data_dist into core.
+	* src/vsip/opt/extdata_local.hpp: Rename to ...
+	* src/vsip/core/extdata_dist.hpp: ... this.  Rename Ext_data_local
+	  to Ext_data_dist.
+	* src/vsip/core/cvsip/eval_reductions_idx.hpp: Use Ext_data_dist.
+	* src/vsip/core/cvsip/eval_reductions.hpp: Likewise.
+	* src/vsip/opt/sal/conv.hpp: Likewise.
+	* src/vsip/opt/signal/conv_ext.hpp: Likewise.
+	* src/vsip/opt/signal/corr_ext.hpp: Likewise.
+	* tests/extdata-local.cpp: Rename to ...
+	* tests/extdata_dist.cpp: ... this, and use Ext_data_local
 	
+2006-12-20  Jules Bergmann  <jules@codesourcery.com>
+	
 	* src/vsip/core/block_traits.hpp (Proper_type_of): Determine if
 	  block type should be const.  Useful for cases were const is
 	  stripped off expression blocks.
Index: src/vsip/core/extdata_dist.hpp
===================================================================
--- src/vsip/core/extdata_dist.hpp	(revision 157392)
+++ src/vsip/core/extdata_dist.hpp	(working copy)
@@ -1,14 +1,14 @@
 /* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    vsip/opt/extdata-local.hpp
+/** @file    vsip/core/extdata-dist.hpp
     @author  Jules Bergmann
     @date    2006-01-31
-    @brief   VSIPL++ Library: Direct Data Access.
+    @brief   VSIPL++ Library: Direct Data Access to Distributed blocks.
 
 */
 
-#ifndef VSIP_OPT_EXTDATA_LOCAL_HPP
-#define VSIP_OPT_EXTDATA_LOCAL_HPP
+#ifndef VSIP_CORE_EXTDATA_DIST_HPP
+#define VSIP_CORE_EXTDATA_DIST_HPP
 
 /***********************************************************************
   Included Files
@@ -47,7 +47,7 @@
 
 
 
-/// Choose Ext_data_local implementation tag for a block.
+/// Choose Ext_data_dist implementation tag for a block.
 
 /// Requires:
 ///   BLOCKT is a block type to use direct access on,
@@ -108,17 +108,17 @@
 	  typename AT      = typename Choose_access<Block, LP>::type,
 	  typename ImplTag = typename 
                              edl_details::Choose_impl_tag<Block, LP>::type>
-class Ext_data_local;
+class Ext_data_dist;
 
 
 
-/// Ext_data_local variant to directly use Ext_data for access to block.
+/// Ext_data_dist variant to directly use Ext_data for access to block.
 
 template <typename BlockT,
 	  typename LP,
 	  typename RP,
 	  typename AT>
-class Ext_data_local<BlockT, LP, RP, AT, edl_details::Impl_use_direct>
+class Ext_data_dist<BlockT, LP, RP, AT, edl_details::Impl_use_direct>
   : public Ext_data<BlockT, LP, RP, AT>
 {
   typedef typename Non_const_of<BlockT>::type non_const_block_type;
@@ -129,31 +129,31 @@
 
   // Constructor and destructor.
 public:
-  Ext_data_local(non_const_block_type& block,
+  Ext_data_dist(non_const_block_type& block,
 		 sync_action_type      sync,
 		 raw_ptr_type          buffer = raw_ptr_type())
     : base_type(block, sync, buffer)
   {}
 
-  Ext_data_local(BlockT const&      block,
+  Ext_data_dist(BlockT const&      block,
 		 sync_action_type   sync,
 		 raw_ptr_type       buffer = raw_ptr_type())
     : base_type(block, sync, buffer)
   {}
 
-  ~Ext_data_local() {}
+  ~Ext_data_dist() {}
 };
 
 
 
-/// Ext_data_local variant to use Ext_data access on a distributed block's
+/// Ext_data_dist variant to use Ext_data access on a distributed block's
 /// local block (as returned by get_local_block).
 
 template <typename BlockT,
 	  typename LP,
 	  typename RP,
 	  typename AT>
-class Ext_data_local<BlockT, LP, RP, AT, edl_details::Impl_use_local>
+class Ext_data_dist<BlockT, LP, RP, AT, edl_details::Impl_use_local>
   : public Ext_data<typename Distributed_local_block<BlockT>::type, LP, RP, AT>
 {
   typedef typename Non_const_of<BlockT>::type non_const_block_type;
@@ -165,31 +165,31 @@
 
   // Constructor and destructor.
 public:
-  Ext_data_local(non_const_block_type& block,
+  Ext_data_dist(non_const_block_type& block,
 		 sync_action_type      sync,
 		 raw_ptr_type          buffer = raw_ptr_type())
     : base_type(get_local_block(block), sync, buffer)
   {}
 
-  Ext_data_local(BlockT const&      block,
+  Ext_data_dist(BlockT const&      block,
 		 sync_action_type   sync,
 		 raw_ptr_type       buffer = raw_ptr_type())
     : base_type(get_local_block(block), sync, buffer)
   {}
 
-  ~Ext_data_local() {}
+  ~Ext_data_dist() {}
 };
 
 
 
-/// Ext_data_local variant to use Ext_data access on a reorganized
+/// Ext_data_dist variant to use Ext_data access on a reorganized
 /// copy of the original distributed block.
 
 template <typename BlockT,
 	  typename LP,
 	  typename RP,
 	  typename AT>
-class Ext_data_local<BlockT, LP, RP, AT, edl_details::Impl_remap>
+class Ext_data_dist<BlockT, LP, RP, AT, edl_details::Impl_remap>
 {
   typedef typename Non_const_of<BlockT>::type non_const_block_type;
   static dimension_type const dim = BlockT::dim;
@@ -207,7 +207,7 @@
 
   // Constructor and destructor.
 public:
-  Ext_data_local(non_const_block_type& block,
+  Ext_data_dist(non_const_block_type& block,
 		 sync_action_type      sync,
 		 raw_ptr_type          buffer = raw_ptr_type())
     : src_     (block),
@@ -220,7 +220,7 @@
     assign_local(view_, src_);
   }
 
-  Ext_data_local(BlockT const&      block,
+  Ext_data_dist(BlockT const&      block,
 		 sync_action_type   sync,
 		 raw_ptr_type       buffer = raw_ptr_type())
     : src_   (const_cast<BlockT&>(block)),
@@ -234,7 +234,7 @@
     assign_local(view_, src_);
   }
 
-  ~Ext_data_local()
+  ~Ext_data_dist()
   {
     if (sync_ & SYNC_OUT)
       assign_local(src_, view_);
@@ -264,4 +264,4 @@
 } // namespace vsip::impl
 } // namespace vsip
 
-#endif // VSIP_IMPL_EXTDATA_LOCAL_HPP
+#endif // VSIP_CORE_EXTDATA_DIST_HPP
Index: src/vsip/core/cvsip/eval_reductions_idx.hpp
===================================================================
--- src/vsip/core/cvsip/eval_reductions_idx.hpp	(revision 158196)
+++ src/vsip/core/cvsip/eval_reductions_idx.hpp	(working copy)
@@ -23,7 +23,7 @@
 #include <vsip/core/impl_tags.hpp>
 #include <vsip/core/coverage.hpp>
 #include <vsip/core/static_assert.hpp>
-#include <vsip/opt/extdata_local.hpp>
+#include <vsip/core/extdata_dist.hpp>
 #include <vsip/core/cvsip/view.hpp>
 #include <vsip/core/cvsip/convert_value.hpp>
 
@@ -161,7 +161,7 @@
   static void exec(T& r, Block const& blk, Index<Dim>& idx, OrderT)
   {
     typedef typename Proper_type_of<Block>::type block_type;
-    Ext_data_local<block_type> ext(blk, SYNC_IN);
+    Ext_data_dist<block_type> ext(blk, SYNC_IN);
     cvsip::View_from_ext<Dim, value_type> view(ext);
     
     r = cvsip::Reduce_idx_class<ReduceT, Dim, value_type>::exec(
Index: src/vsip/core/cvsip/eval_reductions.hpp
===================================================================
--- src/vsip/core/cvsip/eval_reductions.hpp	(revision 158196)
+++ src/vsip/core/cvsip/eval_reductions.hpp	(working copy)
@@ -26,7 +26,7 @@
 #include <vsip/core/impl_tags.hpp>
 #include <vsip/core/coverage.hpp>
 #include <vsip/core/static_assert.hpp>
-#include <vsip/opt/extdata_local.hpp>
+#include <vsip/core/extdata_dist.hpp>
 #include <vsip/core/cvsip/view.hpp>
 #include <vsip/core/cvsip/convert_value.hpp>
 
@@ -171,7 +171,7 @@
   static void exec(T& r, Block const& blk, OrderT, Int_type<Dim>)
   {
     typedef typename Proper_type_of<Block>::type block_type;
-    Ext_data_local<block_type> ext(blk, SYNC_IN);
+    Ext_data_dist<block_type> ext(blk, SYNC_IN);
     cvsip::View_from_ext<Dim, value_type> view(ext);
     
     r = cvsip::Reduce_class<ReduceT, Dim, value_type>::exec(view.view_.ptr());
Index: src/vsip/opt/sal/conv.hpp
===================================================================
--- src/vsip/opt/sal/conv.hpp	(revision 157392)
+++ src/vsip/opt/sal/conv.hpp	(working copy)
@@ -21,6 +21,7 @@
 #include <vsip/core/signal/types.hpp>
 #include <vsip/core/profile.hpp>
 #include <vsip/core/signal/conv_common.hpp>
+#include <vsip/core/extdata_dist.hpp>
 #include <vsip/opt/sal/bindings.hpp>
 
 /***********************************************************************
@@ -253,8 +254,8 @@
   typedef typename Adjust_layout<T, req_LP, LP0>::type use_LP0;
   typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
 
-  typedef vsip::impl::Ext_data_local<Block0, use_LP0>  in_ext_type;
-  typedef vsip::impl::Ext_data_local<Block1, use_LP1> out_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block0, use_LP0>  in_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block1, use_LP1> out_ext_type;
 
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
Index: src/vsip/opt/signal/conv_ext.hpp
===================================================================
--- src/vsip/opt/signal/conv_ext.hpp	(revision 157392)
+++ src/vsip/opt/signal/conv_ext.hpp	(working copy)
@@ -21,7 +21,7 @@
 #include <vsip/core/signal/types.hpp>
 #include <vsip/core/profile.hpp>
 #include <vsip/core/signal/conv_common.hpp>
-#include <vsip/opt/extdata_local.hpp>
+#include <vsip/core/extdata_dist.hpp>
 
 /***********************************************************************
   Declarations
@@ -239,8 +239,8 @@
   typedef typename Adjust_layout<T, req_LP, LP0>::type use_LP0;
   typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
 
-  typedef vsip::impl::Ext_data_local<Block0, use_LP0>  in_ext_type;
-  typedef vsip::impl::Ext_data_local<Block1, use_LP1> out_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block0, use_LP0>  in_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block1, use_LP1> out_ext_type;
 
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
@@ -311,8 +311,8 @@
   typedef typename Adjust_layout<T, req_LP, LP0>::type use_LP0;
   typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
 
-  typedef vsip::impl::Ext_data_local<Block0, use_LP0>  in_ext_type;
-  typedef vsip::impl::Ext_data_local<Block1, use_LP1> out_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block0, use_LP0>  in_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block1, use_LP1> out_ext_type;
 
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
Index: src/vsip/opt/signal/corr_ext.hpp
===================================================================
--- src/vsip/opt/signal/corr_ext.hpp	(revision 157392)
+++ src/vsip/opt/signal/corr_ext.hpp	(working copy)
@@ -22,7 +22,7 @@
 #include <vsip/core/profile.hpp>
 #include <vsip/core/signal/conv_common.hpp>
 #include <vsip/core/signal/corr_common.hpp>
-#include <vsip/opt/extdata_local.hpp>
+#include <vsip/core/extdata_dist.hpp>
 
 /***********************************************************************
   Declarations
@@ -221,9 +221,9 @@
   typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
   typedef typename Adjust_layout<T, req_LP, LP2>::type use_LP2;
 
-  typedef vsip::impl::Ext_data_local<Block0, use_LP0> ref_ext_type;
-  typedef vsip::impl::Ext_data_local<Block1, use_LP1>  in_ext_type;
-  typedef vsip::impl::Ext_data_local<Block2, use_LP2> out_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block0, use_LP0> ref_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block1, use_LP1>  in_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block2, use_LP2> out_ext_type;
 
   ref_ext_type ref_ext(ref.block(), vsip::impl::SYNC_IN,  ref_buffer_);
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
@@ -305,9 +305,9 @@
   typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
   typedef typename Adjust_layout<T, req_LP, LP2>::type use_LP2;
 
-  typedef vsip::impl::Ext_data_local<Block0, use_LP0> ref_ext_type;
-  typedef vsip::impl::Ext_data_local<Block1, use_LP1>  in_ext_type;
-  typedef vsip::impl::Ext_data_local<Block2, use_LP2> out_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block0, use_LP0> ref_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block1, use_LP1>  in_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block2, use_LP2> out_ext_type;
 
   ref_ext_type ref_ext(ref.block(), vsip::impl::SYNC_IN,  ref_buffer_);
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
Index: tests/extdata_dist.cpp
===================================================================
--- tests/extdata_dist.cpp	(revision 157392)
+++ tests/extdata_dist.cpp	(working copy)
@@ -11,7 +11,7 @@
 ***********************************************************************/
 
 #include <vsip/vector.hpp>
-#include <vsip/opt/extdata_local.hpp>
+#include <vsip/core/extdata_dist.hpp>
 #include <vsip/initfin.hpp>
 #include <vsip/map.hpp>
 #include <vsip/selgen.hpp>
@@ -85,7 +85,7 @@
   typename storage_type::type buffer = storage_type::allocate(alloc, size);
 
   {
-    impl::Ext_data_local<block_type, use_LP> raw(block, SYNC_INOUT, buffer);
+    impl::Ext_data_dist<block_type, use_LP> raw(block, SYNC_INOUT, buffer);
 
     assert(raw.cost() == expect_cost);
 
@@ -152,7 +152,7 @@
   typename storage_type::type buffer = storage_type::allocate(alloc, size);
 
   {
-    impl::Ext_data_local<block_type, use_LP> raw(block, SYNC_INOUT, buffer);
+    impl::Ext_data_dist<block_type, use_LP> raw(block, SYNC_INOUT, buffer);
 
     if (Type_equal<OrderT, typename use_LP::order_type>::value &&
 	Type_equal<typename GivenLP::complex_type,
@@ -227,7 +227,7 @@
 
   {
     block_type const& ref = block;
-    impl::Ext_data_local<block_type, use_LP> raw(ref, SYNC_IN, buffer);
+    impl::Ext_data_dist<block_type, use_LP> raw(ref, SYNC_IN, buffer);
 
     if (Type_equal<OrderT, typename use_LP::order_type>::value &&
 	Type_equal<typename GivenLP::complex_type,
