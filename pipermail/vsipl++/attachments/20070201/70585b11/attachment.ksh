diff -rN -uN old-rbo-merge/src/vsip/core/fft/util.hpp new-rbo-merge/src/vsip/core/fft/util.hpp
--- old-rbo-merge/src/vsip/core/fft/util.hpp	2007-02-01 10:03:50.000000000 -0500
+++ new-rbo-merge/src/vsip/core/fft/util.hpp	2007-02-01 10:03:54.000000000 -0500
@@ -18,6 +18,7 @@
 #include <vsip/core/fft/backend.hpp>
 #include <vsip/core/fast_block.hpp>
 #include <vsip/core/view_traits.hpp>
+#include <vsip/opt/expr/return_block.hpp>
 
 /***********************************************************************
   Declarations
@@ -146,6 +147,87 @@
   { return new_view<view_type>(dom);}
 };
 
+
+
+/// Return functor class for Fft.
+
+/// Captures invocation of Fft object on an input block for later
+/// evaluation, once the destination block is known.
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ViewT,
+	  typename       BackendT,
+	  typename       WorkspaceT>
+struct Fft_return_functor
+{
+  typedef typename ViewT::block_type                          block_type;
+  typedef typename ViewT::block_type::map_type                map_type;
+  typedef typename View_block_storage<block_type>::plain_type block_ref_type;
+
+  Fft_return_functor(
+    ViewT       in,
+    BackendT&   backend,
+    WorkspaceT& workspace)
+  : in_block_  (in.block()),
+    backend_   (backend),
+    workspace_ (workspace)
+  {}
+
+  Fft_return_functor(Fft_return_functor const& rhs)
+    : in_block_(rhs.in_block_),
+      backend_(rhs.backend_),
+      workspace_(rhs.workspace_)
+  {}
+
+  template <typename BlockT>
+  void apply(BlockT& result) const
+  {
+    workspace_.by_reference_blk(&backend_, in_block_, result);
+  }
+
+  length_type size() const
+  {
+    return in_block_.size();
+  }
+
+  length_type size(dimension_type block_dim, dimension_type d) const
+  {
+    assert(block_dim == Dim);
+    return in_block_.size(block_dim, d);
+  }
+
+  block_ref_type in_block_;
+  BackendT&      backend_;
+  WorkspaceT&    workspace_;
+};
+
+
+
+/// Traits class to determine view type returned by Fft for
+/// by_value operators with return-block optimization.
+
+template<dimension_type Dim,
+	 typename       InT,
+	 typename       OutT,
+	 typename       ViewT,
+	 typename       WorkspaceT,
+	 int            AxisV,
+	 int            ExponentV>
+struct Result_rbo
+{
+  typedef Fft_return_functor<Dim, OutT, ViewT,
+                      fft::backend<Dim, InT, OutT, AxisV, ExponentV>,
+		      WorkspaceT>
+		functor_type;
+
+  typedef Return_expr_block<Dim, OutT, functor_type>
+		block_type;
+
+  typedef typename View_of_dim<Dim, OutT, block_type const>::type
+		view_type;
+};
+
 } // namespace vsip::impl::fft
 } // namespace vsip::impl
 } // namespace vsip
diff -rN -uN old-rbo-merge/src/vsip/core/fft.hpp new-rbo-merge/src/vsip/core/fft.hpp
--- old-rbo-merge/src/vsip/core/fft.hpp	2007-02-01 10:03:50.000000000 -0500
+++ new-rbo-merge/src/vsip/core/fft.hpp	2007-02-01 10:03:54.000000000 -0500
@@ -25,6 +25,7 @@
 #  include <vsip/opt/fft/workspace.hpp>
 #endif
 #include <vsip/core/metaprogramming.hpp>
+#include <vsip/opt/expr/return_block.hpp>
 #include <vsip/core/profile.hpp>
 
 #ifndef VSIP_IMPL_REF_IMPL
@@ -193,16 +194,21 @@
   {}
 
   template <typename ViewT>
-  typename fft::result<O, typename ViewT::block_type>::view_type
+  typename fft::Result_rbo<D, I, O, ViewT, workspace, axis, exponent>
+                          ::view_type
   operator()(ViewT in) VSIP_THROW((std::bad_alloc))
   {
     typename base::Scope scope(*this);
     assert(extent(in) == extent(this->input_size()));
-    typedef fft::result<O, typename ViewT::block_type> traits;
-    typename traits::view_type out(traits::create(this->output_size(),
-						  in.block().map()));
-    workspace_.by_reference(this->backend_.get(), in, out);
-    return out;
+    typedef fft::Result_rbo<D, I, O, ViewT, workspace, axis, exponent>
+      traits;
+    typedef typename traits::functor_type functor_type;
+    typedef typename traits::block_type   block_type;
+    typedef typename traits::view_type    view_type;
+
+    functor_type rf(in, *(this->backend_.get()), workspace_);
+    block_type block(rf);
+    return view_type(block);
   }
 private:
   std::auto_ptr<fft::backend<D, I, O, axis, exponent> > backend_;
diff -rN -uN old-rbo-merge/src/vsip/core/impl_tags.hpp new-rbo-merge/src/vsip/core/impl_tags.hpp
--- old-rbo-merge/src/vsip/core/impl_tags.hpp	2007-02-01 10:03:50.000000000 -0500
+++ new-rbo-merge/src/vsip/core/impl_tags.hpp	2007-02-01 10:03:54.000000000 -0500
@@ -40,6 +40,7 @@
 struct Copy_tag {};		// Optimized Copy
 struct Op_expr_tag {};		// Special expr handling (vmmul, etc)
 struct Simd_loop_fusion_tag {};	// SIMD Loop Fusion.
+struct Special_tag;             // Special evaluators.
 struct Loop_fusion_tag {};	// Generic Loop Fusion (base case).
 struct Cbe_sdk_tag {};          // IBM CBE SDK.
 
diff -rN -uN old-rbo-merge/src/vsip/opt/expr/eval_return_block.hpp new-rbo-merge/src/vsip/opt/expr/eval_return_block.hpp
--- old-rbo-merge/src/vsip/opt/expr/eval_return_block.hpp	1969-12-31 19:00:00.000000000 -0500
+++ new-rbo-merge/src/vsip/opt/expr/eval_return_block.hpp	2007-02-01 10:03:54.000000000 -0500
@@ -0,0 +1,63 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/expr/eval_return_block.hpp
+    @author  Jules Bergmann
+    @date    2006-09-02
+    @brief   VSIPL++ Library: Evaluator for return-block optimization.
+
+*/
+
+#ifndef VSIP_OPT_EXPR_EVAL_RETURN_BLOCK_HPP
+#define VSIP_OPT_EXPR_EVAL_RETURN_BLOCK_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/expr/return_block.hpp>
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
+/// Evaluator for return expression block.
+
+template <dimension_type Dim,
+	  typename       DstBlock,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Serial_expr_evaluator<Dim, DstBlock,
+	const Return_expr_block<Dim, T, ReturnFunctor>,
+	Special_tag>
+{
+  typedef Return_expr_block<Dim, T, ReturnFunctor> SrcBlock;
+
+  typedef typename DstBlock::value_type dst_type;
+  typedef typename SrcBlock::value_type src_type;
+
+  static bool const ct_valid = true;
+
+  static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
+  {
+    return true;
+  }
+  
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    src.apply(dst);
+  }
+};
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_OPT_EXPR_EVAL_RETURN_BLOCK_HPP
diff -rN -uN old-rbo-merge/src/vsip/opt/expr/lf_initfini.hpp new-rbo-merge/src/vsip/opt/expr/lf_initfini.hpp
--- old-rbo-merge/src/vsip/opt/expr/lf_initfini.hpp	1969-12-31 19:00:00.000000000 -0500
+++ new-rbo-merge/src/vsip/opt/expr/lf_initfini.hpp	2007-02-01 10:03:54.000000000 -0500
@@ -0,0 +1,194 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/expr/lf_initfini.hpp
+    @author  Jules Bergmann
+    @date    2006-08-04
+    @brief   VSIPL++ Library: Loop-fusion init/fini
+*/
+
+#ifndef VSIP_OPT_EXPR_LF_INITFINI_HPP
+#define VSIP_OPT_EXPR_LF_INITFINI_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/core/block_traits.hpp>
+#include <vsip/core/expr/operations.hpp>
+#include <vsip/core/expr/scalar_block.hpp>
+#include <vsip/core/expr/unary_block.hpp>
+#include <vsip/core/expr/binary_block.hpp>
+#include <vsip/core/expr/ternary_block.hpp>
+// #include <vsip/impl/expr_return_block.hpp>
+#include <vsip/core/fns_elementwise.hpp>
+#include <vsip/core/coverage.hpp>
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
+// fwd decl
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+class Return_expr_block;
+
+
+
+/// Reduction to count the number operations per point of an expression.
+
+template <typename LeafT>
+struct Apply_leaf
+{
+public:
+  template <typename BlockT>
+  struct transform
+  {
+    static void apply(BlockT const& block)
+    {
+      LeafT::template leaf_node<BlockT>::apply(block);
+    }
+  };
+
+  template <typename BlockT>
+  struct transform<BlockT const> : public transform<BlockT> {};
+
+  template <dimension_type            Dim0,
+	    template <typename> class Op,
+	    typename                  BlockT,
+	    typename                  T>
+  struct transform<Unary_expr_block<Dim0, Op, BlockT, T> >
+  {
+    typedef Unary_expr_block<Dim0, Op, BlockT, T>
+		block_type;
+
+    static void apply(block_type const& block)
+    {
+      transform<BlockT>::apply(block.op());
+    }
+  };
+
+  template <dimension_type                Dim0,
+	    template <typename, typename> class Op,
+	    typename                      LBlock,
+	    typename                      LType,
+	    typename                      RBlock,
+	    typename                      RType>
+  struct transform<Binary_expr_block<Dim0, Op, LBlock, LType,
+				     RBlock, RType> >
+  {
+    typedef Binary_expr_block<Dim0, Op, LBlock, LType, RBlock, RType> 
+		block_type;
+
+    static void apply(block_type const& block)
+    {
+      transform<LBlock>::apply(block.left());
+      transform<RBlock>::apply(block.right());
+    }
+  };
+
+  template <dimension_type                Dim0,
+	    template <typename, typename, typename> class Op,
+	    typename                      Block1,
+	    typename                      Type1,
+	    typename                      Block2,
+	    typename                      Type2,
+	    typename                      Block3,
+	    typename                      Type3>
+  struct transform<Ternary_expr_block<Dim0, Op, Block1, Type1,
+				     Block2, Type2, Block3, Type3> >
+  {
+    typedef Ternary_expr_block<Dim0, Op, Block1, Type1,
+			       Block2, Type2, Block3, Type3> const
+		block_type;
+
+    static void apply(block_type const& block)
+    {
+      transform<Block1>::apply(block.first());
+      transform<Block2>::apply(block.second());
+      transform<Block3>::apply(block.third());
+    }
+  };
+};
+
+
+
+struct Do_loop_fusion_init : Apply_leaf<Do_loop_fusion_init>
+{
+  template <typename BlockT>
+  struct leaf_node
+  {
+    static void apply(BlockT const&) {} // no-op
+  };
+
+  template <dimension_type Dim,
+	    typename       T,
+	    typename       ReturnFunctor>
+  struct leaf_node<Return_expr_block<Dim, T, ReturnFunctor> >
+  {
+    typedef Return_expr_block<Dim, T, ReturnFunctor>
+		block_type;
+
+    static void apply(block_type const& block) 
+    {
+      const_cast<block_type&>(block).loop_fusion_init();
+    }
+  };
+};
+
+
+
+struct Do_loop_fusion_fini : Apply_leaf<Do_loop_fusion_fini>
+{
+  template <typename BlockT>
+  struct leaf_node
+  {
+    static void apply(BlockT const&) {} // no-op
+  };
+
+  template <dimension_type Dim,
+	    typename       T,
+	    typename       ReturnFunctor>
+  struct leaf_node<Return_expr_block<Dim, T, ReturnFunctor> >
+  {
+    typedef Return_expr_block<Dim, T, ReturnFunctor>
+		block_type;
+
+    static void apply(block_type const& block) 
+    {
+      const_cast<block_type&>(block).loop_fusion_fini();
+    } // no-op
+  };
+};
+
+
+template <typename BlockT>
+void
+do_loop_fusion_init(BlockT const& block)
+{
+  Do_loop_fusion_init::transform<BlockT>::apply(block);
+}
+
+
+
+template <typename BlockT>
+void
+do_loop_fusion_fini(BlockT const& block)
+{
+  Do_loop_fusion_fini::transform<BlockT>::apply(block);
+}
+
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_EXPR_LF_INITFINI_HPP
diff -rN -uN old-rbo-merge/src/vsip/opt/expr/return_block.hpp new-rbo-merge/src/vsip/opt/expr/return_block.hpp
--- old-rbo-merge/src/vsip/opt/expr/return_block.hpp	1969-12-31 19:00:00.000000000 -0500
+++ new-rbo-merge/src/vsip/opt/expr/return_block.hpp	2007-02-01 10:03:54.000000000 -0500
@@ -0,0 +1,232 @@
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/expr/return_block.hpp
+    @author  Jules Bergmann
+    @date    2006-09-02
+    @brief   VSIPL++ Library: Expression return block.
+
+*/
+
+#ifndef VSIP_OPT_EXPR_RETURN_BLOCK_HPP
+#define VSIP_OPT_EXPR_RETURN_BLOCK_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <memory>
+
+#include <vsip/core/block_traits.hpp>
+#include <vsip/core/view_traits.hpp>
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
+/// Expression template block for return block optimization.
+
+/// Requires:
+///   DIM to be a dimension.
+///   T to be a value type.
+///   RETURNFUNCTOR to be ...
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+class Return_expr_block : public Non_assignable
+{
+public:
+  static dimension_type const dim = Dim;
+
+  typedef T                                value_type;
+  typedef value_type&                      reference_type;
+  typedef value_type const&                const_reference_type;
+  typedef typename ReturnFunctor::map_type map_type;
+
+  typedef Dense<Dim, T> block_type;
+
+  Return_expr_block(ReturnFunctor& rf)
+    : rf_   (rf)
+    , block_()
+  {}
+
+  // Necessary to provide copy constructor, because auto_ptr cannot
+  // be copied.
+  Return_expr_block(Return_expr_block const& rhs)
+    : rf_   (rhs.rf_),
+      block_()
+  {}
+
+  length_type size() const VSIP_NOTHROW { return rf_.size(); }
+  length_type size(dimension_type block_dim, dimension_type d)
+    const VSIP_NOTHROW
+  { return rf_.size(block_dim, d); }
+
+
+  void increment_count() const VSIP_NOTHROW {}
+  void decrement_count() const VSIP_NOTHROW {}
+  map_type const& map() const VSIP_NOTHROW { return rf_.map();}
+
+  value_type get(index_type i) const
+  { 
+    assert(block_.get());
+    return block_->get(i);
+  }
+
+  value_type get(index_type i, index_type j) const
+  { 
+    assert(block_.get());
+    return block_->get(i, j);
+  }
+
+  value_type get(index_type i, index_type j, index_type k) const
+  { 
+    assert(block_.get());
+    return block_->get(i, j, k);
+  }
+
+  template <typename DstBlock>
+  void apply(DstBlock& dst) const
+  {
+    rf_.apply(dst);
+  }
+
+  void loop_fusion_init()
+  {
+    length_type size = this->size();
+    block_.reset(new block_type(size));
+    rf_.apply(*(block_.get()));
+  }
+
+  void loop_fusion_fini()
+  {
+    block_.reset(0);
+  }
+
+public:
+  ReturnFunctor             rf_;
+  std::auto_ptr<block_type> block_;
+};
+
+
+
+/// Specialize traits for Vmmul_expr_block.
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Is_expr_block<Return_expr_block<Dim, T, ReturnFunctor> >
+{ static bool const value = true; };
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct View_block_storage<Return_expr_block<Dim, T, ReturnFunctor> const>
+  : By_value_block_storage<Return_expr_block<Dim, T, ReturnFunctor> const>
+{};
+
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct View_block_storage<Return_expr_block<Dim, T, ReturnFunctor> >
+  : By_value_block_storage<Return_expr_block<Dim, T, ReturnFunctor> >
+{};
+
+#if 0 // TO BE IMPLEMENTED
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Distributed_local_block<Return_expr_block<Dim, T, ReturnFunctor> >
+{
+  typedef ... type;
+};
+
+
+
+template <typename       CombineT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Combine_return_type<CombineT,
+			   Return_expr_block<Dim, T, ReturnFunctor> const>
+{
+  typedef ... tree_type;
+  typedef tree_type type;
+};
+
+
+
+template <typename       CombineT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+struct Combine_return_type<CombineT,
+			   Return_expr_block<Dim, T, ReturnFunctor> >
+{
+  typedef ... tree_type;
+  typedef tree_type type;
+};
+
+
+  
+template <dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+...
+get_local_block(
+  Return_expr_block<Dim, T, ReturnFunctor> const& block)
+{
+  typedef ... block_type;
+
+  return block_type(...);
+}
+
+
+
+template <typename       CombineT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+typename Combine_return_type<CombineT,
+			     Return_expr_block<Dim, T, ReturnFunctor> const>
+		::type
+apply_combine(
+  CombineT const&                                 combine,
+  Return_expr_block<Dim, T, ReturnFunctor> const& block)
+{
+  typedef typename Combine_return_type<
+    CombineT,
+    Return_expr_block<Dim, T, ReturnFunctor> const>::type
+		block_type;
+
+  return block_type(...);
+}
+
+
+
+template <typename       VisitorT,
+	  dimension_type Dim,
+	  typename       T,
+	  typename       ReturnFunctor>
+void
+apply_leaf(
+  VisitorT const&                                 visitor,
+  Return_expr_block<Dim, T, ReturnFunctor> const& block)
+{
+  apply_leaf(visitor, ...);
+}
+#endif
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_OPT_EXPR_RETURN_BLOCK_HPP
diff -rN -uN old-rbo-merge/src/vsip/opt/expr/serial_dispatch_fwd.hpp new-rbo-merge/src/vsip/opt/expr/serial_dispatch_fwd.hpp
--- old-rbo-merge/src/vsip/opt/expr/serial_dispatch_fwd.hpp	2007-02-01 10:03:50.000000000 -0500
+++ new-rbo-merge/src/vsip/opt/expr/serial_dispatch_fwd.hpp	2007-02-01 10:03:54.000000000 -0500
@@ -50,6 +50,7 @@
 		       Copy_tag,
 		       Op_expr_tag,
 		       Simd_loop_fusion_tag,
+		       Special_tag,
 		       Loop_fusion_tag>::type LibraryTagList;
 
 
diff -rN -uN old-rbo-merge/src/vsip/opt/expr/serial_dispatch.hpp new-rbo-merge/src/vsip/opt/expr/serial_dispatch.hpp
--- old-rbo-merge/src/vsip/opt/expr/serial_dispatch.hpp	2007-02-01 10:03:50.000000000 -0500
+++ new-rbo-merge/src/vsip/opt/expr/serial_dispatch.hpp	2007-02-01 10:03:54.000000000 -0500
@@ -27,6 +27,7 @@
 #include <vsip/opt/expr/serial_evaluator.hpp>
 #include <vsip/opt/expr/serial_dispatch_fwd.hpp>
 #include <vsip/opt/expr/eval_dense.hpp>
+#include <vsip/opt/expr/eval_return_block.hpp>
 #include <vsip/opt/expr/ops_info.hpp>
 #include <vsip/core/profile.hpp>
 
diff -rN -uN old-rbo-merge/src/vsip/opt/expr/serial_evaluator.hpp new-rbo-merge/src/vsip/opt/expr/serial_evaluator.hpp
--- old-rbo-merge/src/vsip/opt/expr/serial_evaluator.hpp	2007-02-01 10:03:50.000000000 -0500
+++ new-rbo-merge/src/vsip/opt/expr/serial_evaluator.hpp	2007-02-01 10:03:54.000000000 -0500
@@ -28,6 +28,7 @@
 #include <vsip/core/adjust_layout.hpp>
 #include <vsip/core/coverage.hpp>
 #include <vsip/core/impl_tags.hpp>
+#include <vsip/opt/expr/lf_initfini.hpp>
 
 
 /***********************************************************************
@@ -62,9 +63,11 @@
   
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
+    do_loop_fusion_init(src);
     length_type const size = dst.size(1, 0);
     for (index_type i=0; i<size; ++i)
       dst.put(i, src.get(i));
+    do_loop_fusion_fini(src);
   }
 };
 
diff -rN -uN old-rbo-merge/src/vsip/opt/fft/workspace.hpp new-rbo-merge/src/vsip/opt/fft/workspace.hpp
--- old-rbo-merge/src/vsip/opt/fft/workspace.hpp	2007-02-01 10:03:50.000000000 -0500
+++ new-rbo-merge/src/vsip/opt/fft/workspace.hpp	2007-02-01 10:03:53.000000000 -0500
@@ -152,7 +152,49 @@
       out *= scale_;
   }
 
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference_blk(BE *backend,
+			Block0 const& in,
+			Block1&       out)
+  {
+    // Find out about the blocks's actual layout.
+    Rt_layout<1> rtl_in = block_layout<1>(in);
+    Rt_layout<1> rtl_out = block_layout<1>(out);
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN; 
+
+    {
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in, rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out, rtl_out, SYNC_OUT,
+				  output_buffer_.get());
+    
+      // Call the backend.
+      assert(rtl_in.complex == rtl_out.complex);
+      if (rtl_in.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_inter(), in_ext.stride(0),
+			      out_ext.data().as_inter(), out_ext.stride(0),
+			      in_ext.size(0));
+      else
+	backend->by_reference(in_ext.data().as_split(), in_ext.stride(0),
+			      out_ext.data().as_split(), out_ext.stride(0),
+			      in_ext.size(0));
+    }
+    // Scale the data if not already done by the backend.
+#if TODO
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      out *= scale_;
+#endif
+  }
+
   template <typename BE, typename BlockT>
   void in_place(BE *backend, Vector<std::complex<T>,BlockT> inout)
   {
