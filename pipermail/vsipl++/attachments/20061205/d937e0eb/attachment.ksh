Index: ChangeLog
===================================================================
--- ChangeLog	(revision 156543)
+++ ChangeLog	(working copy)
@@ -1,3 +1,24 @@
+2006-12-05  Jules Bergmann  <jules@codesourcery.com>
+
+	Fix issue #125.
+	* src/vsip/core/expr/binary_block.hpp: Add asserts at block
+	  create that lhs and rhs are same size.
+	* src/vsip/core/metaprogramming.hpp (Non_const_of): New trait
+	  to strip const qualifier from type.
+	* src/vsip/core/fft.hpp: Check input/output view sizes.
+	* src/vsip/opt/extdata.hpp: Use Block_copy_{to_ptr,from_ptr}.
+	  Fix Ext_data to work const blocks (such as expression blocks).
+	* src/vsip/opt/profile.cpp: Fix Wall warning.
+	* src/vsip/opt/rt_extdata.hpp: Use Rt_block_copy_{to_ptr,from_ptr}.
+	  Add Copy_access_tag specialization for Rt_low_level_data_access.
+	  Fix Rt_ext_data to work const blocks (such as expression blocks).
+	* src/vsip/opt/block_copy.hpp: Split Block_copy into
+	  Block_copy_{to_ptr,from_ptr}.   Ditto for Rt_block_copy.
+	* tests/regressions/fft_expr_arg.cpp: New file, regression test
+	  for issue 125, passing expression to Fft.
+	
+	* src/vsip/opt/diag/eval.hpp: Update diagnostics.
+	
 2006-11-29  Don McCoy  <don@codesourcery.com>
 
 	* apps/ssar/diffview.cpp: Remove stdlib include.
Index: src/vsip/core/expr/binary_block.hpp
===================================================================
--- src/vsip/core/expr/binary_block.hpp	(revision 156170)
+++ src/vsip/core/expr/binary_block.hpp	(working copy)
@@ -337,6 +337,9 @@
 (LBlock const& lhs, RBlock const& rhs)
   : lhs_(lhs), rhs_(rhs) 
 {
+  assert(!Is_sized_block<LBlock>::value ||
+	 !Is_sized_block<RBlock>::value ||
+	 extent<D>(lhs_) == extent<D>(rhs_));
 }
 
 template <dimension_type D,
@@ -350,6 +353,9 @@
 (LBlock const& lhs, RBlock const& rhs, Operator<LType, RType> const& op)
   : Operator<LType, RType>(op), lhs_(lhs), rhs_(rhs) 
 {
+  assert(!Is_sized_block<LBlock>::value ||
+	 !Is_sized_block<RBlock>::value ||
+	 extent<D>(lhs_) == extent<D>(rhs_));
 }
 
 template <dimension_type D,
Index: src/vsip/core/metaprogramming.hpp
===================================================================
--- src/vsip/core/metaprogramming.hpp	(revision 156170)
+++ src/vsip/core/metaprogramming.hpp	(working copy)
@@ -142,6 +142,17 @@
 struct false_type { static const bool value = false; };
 struct true_type  { static const bool value = true; };
 
+
+// Strip const qualifier from type.
+
+template <typename T>
+struct Non_const_of
+{ typedef T type; };
+
+template <typename T>
+struct Non_const_of<T const>
+{ typedef T type; };
+
 } // namespace impl
 } // namespace vsip
 
Index: src/vsip/core/fft.hpp
===================================================================
--- src/vsip/core/fft.hpp	(revision 156170)
+++ src/vsip/core/fft.hpp	(working copy)
@@ -182,6 +182,7 @@
   operator()(ViewT in) VSIP_THROW((std::bad_alloc))
   {
     typename base::Scope scope(*this);
+    assert(extent(in) == extent(this->input_size()));
     typedef fft::result<O, typename ViewT::block_type> traits;
     typename traits::view_type out(traits::create(this->output_size(),
 						  in.block().map()));
@@ -233,6 +234,8 @@
   {
     typename base::Scope scope(*this);
     VSIP_IMPL_STATIC_ASSERT((View0<I,Block0>::dim == View1<O,Block1>::dim));
+    assert(extent(in) == extent(this->input_size()));
+    assert(extent(out) == extent(this->output_size()));
     workspace_.by_reference(this->backend_.get(), in, out);
     return out;
   }
@@ -242,6 +245,8 @@
   operator()(View<I,BlockT> inout) VSIP_NOTHROW
   {
     typename base::Scope scope(*this);
+    assert(extent(inout) == extent(this->input_size()));
+    assert(extent(inout) == extent(this->output_size()));
     workspace_.in_place(this->backend_.get(), inout);
     return inout;
   }
Index: src/vsip/opt/extdata.hpp
===================================================================
--- src/vsip/opt/extdata.hpp	(revision 156170)
+++ src/vsip/opt/extdata.hpp	(working copy)
@@ -448,15 +448,15 @@
   void begin(Block* blk, bool sync)
   {
     if (!use_direct_ && sync)
-      Block_copy<LP::dim, Block, order_type, pack_type, complex_type>::
-	copy_in(blk, layout_, storage_.data());
+      Block_copy_to_ptr<LP::dim, Block, order_type, pack_type, complex_type>
+	::copy(blk, layout_, storage_.data());
   }
 
   void end(Block* blk, bool sync)
   {
     if (!use_direct_ && sync)
-      Block_copy<LP::dim, Block, order_type, pack_type, complex_type>::
-	copy_out(blk, layout_, storage_.data());
+      Block_copy_from_ptr<LP::dim, Block, order_type, pack_type, complex_type>
+	::copy(blk, layout_, storage_.data());
   }
 
   int cost() const { return use_direct_ ? 0 : 2; }
@@ -544,15 +544,15 @@
   void begin(Block* blk, bool sync)
   {
     if (sync)
-      Block_copy<LP::dim, Block, order_type, pack_type, complex_type>::
-	copy_in(blk, layout_, storage_.data());
+      Block_copy_to_ptr<LP::dim, Block, order_type, pack_type, complex_type>
+	::copy(blk, layout_, storage_.data());
   }
 
   void end(Block* blk, bool sync)
   {
     if (sync)
-      Block_copy<LP::dim, Block, order_type, pack_type, complex_type>::
-	copy_out(blk, layout_, storage_.data());
+      Block_copy_from_ptr<LP::dim, Block, order_type, pack_type, complex_type>
+	::copy(blk, layout_, storage_.data());
   }
 
   int cost() const { return CT_Cost; }
@@ -697,6 +697,7 @@
 {
   // Compile time typedefs.
 public:
+  typedef typename Non_const_of<Block>::type non_const_block_type;
   typedef data_access::Low_level_data_access<AT, Block, LP> ext_type;
   typedef typename Block::value_type value_type;
 
@@ -717,9 +718,9 @@
 
   // Constructor and destructor.
 public:
-  Ext_data(Block&             block,
-	   sync_action_type   sync   = SYNC_INOUT,
-	   raw_ptr_type       buffer = storage_type::null())
+  Ext_data(non_const_block_type& block,
+	   sync_action_type      sync   = SYNC_INOUT,
+	   raw_ptr_type          buffer = storage_type::null())
     : blk_ (&block),
       ext_ (block, buffer),
       sync_(sync)
Index: src/vsip/opt/profile.cpp
===================================================================
--- src/vsip/opt/profile.cpp	(revision 156170)
+++ src/vsip/opt/profile.cpp	(working copy)
@@ -174,7 +174,7 @@
 
     // Build nested event name from stack.
     std::string event_name(event_stack_[0]);
-    for (int i=1; i<event_stack_.size(); ++i)
+    for (unsigned i=1; i<event_stack_.size(); ++i)
     {
       event_name += "\\,";
       event_name += event_stack_[i];
Index: src/vsip/opt/rt_extdata.hpp
===================================================================
--- src/vsip/opt/rt_extdata.hpp	(revision 156170)
+++ src/vsip/opt/rt_extdata.hpp	(working copy)
@@ -335,13 +335,15 @@
   void begin(Block* blk, bool sync)
   {
     if (!use_direct_ && sync)
-      Rt_block_copy<Dim, Block>::copy_in(blk, app_layout_, storage_.data());
+      Rt_block_copy_to_ptr<Dim, Block>::copy(blk, app_layout_,
+					     storage_.data());
   }
 
   void end(Block* blk, bool sync)
   {
     if (!use_direct_ && sync)
-      Rt_block_copy<Dim, Block>::copy_out(blk, app_layout_, storage_.data());
+      Rt_block_copy_from_ptr<Dim, Block>::copy(blk, app_layout_,
+					       storage_.data());
   }
 
   int cost() const { return use_direct_ ? 0 : 2; }
@@ -364,6 +366,88 @@
   storage_type                    storage_;
 };
 
+
+
+/// Specialization for low-level copied data access.
+
+/// Requires:
+///   BLOCK to be a block.
+///   DIM to be the dimension of the desired run-time layout.
+
+template <typename       Block,
+	  dimension_type Dim>
+class Rt_low_level_data_access<Copy_access_tag, Block, Dim>
+{
+  // Compile time typedefs.
+public:
+  static dimension_type const dim = Dim;
+
+  typedef typename Block::value_type value_type;
+  typedef Rt_allocated_storage<value_type> storage_type;
+  typedef Rt_pointer<value_type> raw_ptr_type;
+
+  // Compile- and run-time properties.
+public:
+  static int   const CT_Cost          = 2;
+  static bool  const CT_Mem_not_req   = false;
+  static bool  const CT_Xfer_not_req  = false;
+
+  static int    cost         (Block const& block, Rt_layout<Dim> const& rtl)
+    { return is_direct_ok(block, rtl) ? 0 : 2; }
+
+  static size_t mem_required (Block const& block, Rt_layout<Dim> const& )
+    { return sizeof(typename Block::value_type) * block.size(); }
+  static size_t xfer_required(Block const& , Rt_layout<Dim> const& )
+    { return !CT_Xfer_not_req; }
+
+  // Constructor and destructor.
+public:
+  Rt_low_level_data_access(
+    Block&                blk,
+    Rt_layout<Dim> const& rtl,
+    bool                  /*no_preserve*/,
+    raw_ptr_type          buffer = NULL)
+  : app_layout_(Applied_layout<Rt_layout<Dim> >(
+		  rtl, extent<dim>(blk), sizeof(value_type))),
+    storage_(app_layout_.total_size(), rtl.complex, buffer)
+  {}
+
+  ~Rt_low_level_data_access()
+    { if (storage_.is_alloc()) storage_.deallocate(app_layout_.total_size()); }
+
+  void begin(Block* blk, bool sync)
+  {
+    if (sync)
+      Rt_block_copy_to_ptr<Dim, Block>::copy(blk, app_layout_,
+					     storage_.data());
+  }
+
+  void end(Block* blk, bool sync)
+  {
+    if (sync)
+      Rt_block_copy_from_ptr<Dim, Block>::copy(blk, app_layout_,
+					       storage_.data());
+  }
+
+  int cost() const { return 2; }
+
+  // Direct data acessors.
+public:
+  raw_ptr_type data(Block*) const
+    { return storage_.data(); }
+
+  stride_type stride(Block*, dimension_type d) const
+    { return app_layout_.stride(d);  }
+
+  length_type size(Block* blk, dimension_type d) const
+    { return blk->size(Block::dim, d); }
+
+  // Member data.
+private:
+  Applied_layout<Rt_layout<Dim> > app_layout_;
+  storage_type                    storage_;
+};
+
 } // namespace vsip::impl::data_access
 
 
@@ -383,6 +467,8 @@
 {
   // Compile time typedefs.
 public:
+  typedef typename Non_const_of<Block>::type non_const_block_type;
+
   typedef typename Block_layout<Block>::access_type              AT;
   typedef data_access::Rt_low_level_data_access<AT, Block, Dim>  ext_type;
   typedef typename Block::value_type                             value_type;
@@ -398,7 +484,7 @@
 
   // Constructor and destructor.
 public:
-  Rt_ext_data(Block&                block,
+  Rt_ext_data(non_const_block_type& block,
 	      Rt_layout<Dim> const& rtl,
 	      sync_action_type      sync   = SYNC_INOUT,
 	      raw_ptr_type          buffer = 0 /*storage_type::null()*/)
Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 156170)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -70,6 +70,11 @@
 	  bool     CtValid = SeeT::ct_valid>
 struct Check_rt_valid
 {
+  static char const* name()
+  {
+    return 0;
+  }
+
   static bool rt_valid(DstBlockT&, SrcBlockT const&)
   {
     return false;
@@ -83,6 +88,11 @@
 	  typename SrcBlockT>
 struct Check_rt_valid<SeeT, DstBlockT, SrcBlockT, true>
 {
+  static char const* name()
+  {
+    return SeeT::name();
+  }
+
   static bool rt_valid(DstBlockT& dst, SrcBlockT const& src)
   {
     return SeeT::rt_valid(dst, src);
@@ -98,25 +108,90 @@
 	  typename       Tag,
 	  typename       DstBlockT,
           typename       SrcBlockT>
+struct See_summary
+{
+  static void exec(
+    DstBlockT&       dst,
+    SrcBlockT const& src)
+  {
+    using std::cout;
+    using std::setw;
+    using std::endl;
+
+    typedef Serial_expr_evaluator<Dim, DstBlockT, SrcBlockT, Tag>
+      see_type;
+
+    bool rt_valid = Check_rt_valid<see_type, DstBlockT, SrcBlockT>
+      ::rt_valid(dst, src);
+
+    cout << "  - " << setw(20) << Dispatch_name<Tag>::name()
+	 << "  ct: " << setw(5) << (see_type::ct_valid ? "true" : "false")
+	 << "  rt: " << setw(5) << (rt_valid ? "true" : "false");
+
+    if (see_type::ct_valid)
+    {
+      char const* name = Check_rt_valid<see_type, DstBlockT, SrcBlockT>
+	::name();
+      cout << "  (" << name << ")";
+    }
+    cout << endl;
+  }
+};
+
+// Specialization for Transpose_tag
+
+template <typename       DstBlockT,
+          typename       SrcBlockT>
+struct See_summary<2, Transpose_tag, DstBlockT, SrcBlockT>
+{
+  typedef Transpose_tag Tag;
+  static dimension_type const Dim = 2;
+
+  static void exec(
+    DstBlockT&       dst,
+    SrcBlockT const& src)
+  {
+    using std::cout;
+    using std::setw;
+    using std::endl;
+
+    typedef Serial_expr_evaluator<Dim, DstBlockT, SrcBlockT, Tag>
+      see_type;
+
+    bool rt_valid = Check_rt_valid<see_type, DstBlockT, SrcBlockT>
+      ::rt_valid(dst, src);
+
+    cout << "  - " << setw(20) << Dispatch_name<Tag>::name()
+	 << "  ct: " << setw(5) << (see_type::ct_valid ? "true" : "false")
+	 << "  rt: " << setw(5) << (rt_valid ? "true" : "false");
+
+    if (see_type::ct_valid)
+    {
+      char const* name = Check_rt_valid<see_type, DstBlockT, SrcBlockT>
+	::name();
+      cout << "  (" << name << ")";
+    }
+
+    cout << " ["
+	 << see_type::is_rhs_expr << ", "
+	 << see_type::lhs_cost << ", "
+	 << see_type::rhs_cost << ", "
+	 << see_type::is_rhs_split << ", "
+	 << see_type::is_rhs_split << "]";
+    cout << endl;
+  }
+};
+
+template <dimension_type Dim,
+	  typename       Tag,
+	  typename       DstBlockT,
+          typename       SrcBlockT>
 void
 see_summary(
   DstBlockT&       dst,
   SrcBlockT const& src)
 {
-  using std::cout;
-  using std::setw;
-  using std::endl;
-
-  typedef Serial_expr_evaluator<Dim, DstBlockT, SrcBlockT const, Tag>
-    see_type;
-
-  bool rt_valid = Check_rt_valid<see_type, DstBlockT, SrcBlockT const>
-    ::rt_valid(dst, src);
-
-  cout << " - " << setw(20) << Dispatch_name<Tag>::name()
-	    << "  ct: " << setw(5) << (see_type::ct_valid ? "true" : "false")
-	    << "  rt: " << setw(5) << (rt_valid ? "true" : "false")
-	    << endl;
+  See_summary<Dim, Tag, DstBlockT, SrcBlockT>::exec(dst, src);
 }
 
 
@@ -138,7 +213,7 @@
     DstBlock&       dst,
     SrcBlock const& src)
   {
-    see_summary<Dim, Tag>(dst, src);
+    see_summary<Dim, Tag, DstBlock, SrcBlock>(dst, src);
     Diag_eval_list_helper<Dim, DstBlock, SrcBlock, Rest>::exec(dst, src);
   }
 };
@@ -156,7 +231,7 @@
     DstBlock&       dst,
     SrcBlock const& src)
   {
-    see_summary<Dim, Tag>(dst, src);
+    see_summary<Dim, Tag, DstBlock, SrcBlock>(dst, src);
   }
 };
 
@@ -274,6 +349,9 @@
 
   dimension_type const dim = DstViewT::dim;
 
+  std::cout << "diagnose_eval_list" << std::endl
+	    << "  dst expr: " << typeid(dst_block_type).name() << std::endl
+	    << "  src expr: " << typeid(src_block_type).name() << std::endl;
   Diag_eval_list_helper<dim, dst_block_type, src_block_type, TagList>
     ::exec(dst.block(), src.block());
 }
Index: src/vsip/opt/block_copy.hpp
===================================================================
--- src/vsip/opt/block_copy.hpp	(revision 156170)
+++ src/vsip/opt/block_copy.hpp	(working copy)
@@ -42,14 +42,14 @@
 	  typename       Order,
 	  typename       PackType,
 	  typename       CmplxFmt>
-struct Block_copy
+struct Block_copy_to_ptr
 {
   typedef Applied_layout<Layout<Dim, Order, PackType, CmplxFmt> > LP;
   typedef Storage<CmplxFmt, typename Block::value_type> storage_type;
   typedef typename storage_type::type ptr_type;
 
 
-  static void copy_in (Block* block, LP& layout, ptr_type data)
+  static void copy (Block* block, LP& layout, ptr_type data)
   {
     Length<Dim> ext = extent<Dim>(*block);
 
@@ -58,8 +58,22 @@
       storage_type::put(data, layout.index(idx), get(*block, idx));
     }
   }
+};
 
-  static void copy_out(Block* block, LP& layout, ptr_type data)
+
+
+template <dimension_type Dim,
+	  typename       Block,
+	  typename       Order,
+	  typename       PackType,
+	  typename       CmplxFmt>
+struct Block_copy_from_ptr
+{
+  typedef Applied_layout<Layout<Dim, Order, PackType, CmplxFmt> > LP;
+  typedef Storage<CmplxFmt, typename Block::value_type> storage_type;
+  typedef typename storage_type::type ptr_type;
+
+  static void copy(Block* block, LP& layout, ptr_type data)
   {
     Length<Dim> ext = extent<Dim>(*block);
 
@@ -72,7 +86,24 @@
 
 
 
-/// Implementation class to copy block data into/out-of of regular memory,
+template <dimension_type Dim,
+	  typename       Block,
+	  typename       Order,
+	  typename       PackType,
+	  typename       CmplxFmt>
+struct Block_copy_from_ptr<Dim, Block const, Order, PackType, CmplxFmt>
+{
+  typedef Applied_layout<Layout<Dim, Order, PackType, CmplxFmt> > LP;
+  typedef Storage<CmplxFmt, typename Block::value_type> storage_type;
+  typedef typename storage_type::type ptr_type;
+
+  static void copy(Block const*, LP&, ptr_type)
+  { assert(0); }
+};
+
+
+
+/// Implementation class to copy block data to pointer to regular memory,
 /// with layout determined at run-time.
 
 /// Requires:
@@ -86,13 +117,13 @@
 template <dimension_type Dim,
 	  typename       Block,
 	  bool           IsComplex>
-struct Rt_block_copy_impl;
+struct Rt_block_copy_to_ptr_impl;
 
 /// Specialization for blocks with complex value_types.
 
 template <dimension_type Dim,
 	  typename       Block>
-struct Rt_block_copy_impl<Dim, Block, true>
+struct Rt_block_copy_to_ptr_impl<Dim, Block, true>
 {
   typedef Applied_layout<Rt_layout<Dim> > LP;
 
@@ -106,7 +137,7 @@
 
   typedef Rt_pointer<typename Block::value_type> rt_ptr_type;
 
-  static void copy_in (Block* block, LP const& layout, inter_ptr_type data)
+  static void copy(Block* block, LP const& layout, inter_ptr_type data)
   {
     Length<Dim> ext = extent<Dim>(*block);
 
@@ -114,7 +145,7 @@
       inter_storage_type::put(data, layout.index(idx), get(*block, idx));
   }
 
-  static void copy_in (Block* block, LP const& layout, split_ptr_type data)
+  static void copy(Block* block, LP const& layout, split_ptr_type data)
   {
     Length<Dim> ext = extent<Dim>(*block);
 
@@ -122,23 +153,90 @@
       split_storage_type::put(data, layout.index(idx), get(*block, idx));
   }
 
-  static void copy_in (Block* block, LP const& layout, rt_ptr_type data)
+  static void copy(Block* block, LP const& layout, rt_ptr_type data)
   {
     if (complex_format(layout) == cmplx_inter_fmt)
-      copy_in(block, layout, data.as_inter());
+      copy(block, layout, data.as_inter());
     else
-      copy_in(block, layout, data.as_split());
+      copy(block, layout, data.as_split());
   }
+};
 
-  static void copy_out(Block* block, LP const& layout, inter_ptr_type data)
+/// Specialization for blocks with non-complex value_types.
+
+template <dimension_type Dim,
+	  typename       Block>
+struct Rt_block_copy_to_ptr_impl<Dim, Block, false>
+{
+  typedef Applied_layout<Rt_layout<Dim> > LP;
+
+  typedef Storage<Cmplx_inter_fmt, typename Block::value_type>
+	  inter_storage_type;
+
+  typedef typename inter_storage_type::type inter_ptr_type;
+  typedef Rt_pointer<typename Block::value_type> rt_ptr_type;
+
+
+  static void copy(Block* block, LP const& layout, inter_ptr_type data)
   {
     Length<Dim> ext = extent<Dim>(*block);
 
     for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
+      inter_storage_type::put(data, layout.index(idx), get(*block, idx));
+  }
+
+  static void copy(Block* block, LP const& layout, rt_ptr_type data)
+  {
+    copy(block, layout, data.as_inter());
+  }
+
+};
+
+
+
+/// Implementation class to copy block data from pointer to regular memory,
+/// with layout determined at run-time.
+
+/// Requires:
+///   DIM is the dimension of the run-time layout.
+///   BLOCK is a block type,
+///   ISCOMPLEX indicates whether the value type is complex
+///
+/// ISCOMPLEX is used to specialize the implementation so that functions
+/// can be overloaded for split and interleaved arguments.
+
+template <dimension_type Dim,
+	  typename       Block,
+	  bool           IsComplex>
+struct Rt_block_copy_from_ptr_impl;
+
+/// Specializations for blocks with complex value_types.
+
+template <dimension_type Dim,
+	  typename       Block>
+struct Rt_block_copy_from_ptr_impl<Dim, Block, true>
+{
+  typedef Applied_layout<Rt_layout<Dim> > LP;
+
+  typedef Storage<Cmplx_inter_fmt, typename Block::value_type>
+	  inter_storage_type;
+  typedef Storage<Cmplx_split_fmt, typename Block::value_type>
+	  split_storage_type;
+
+  typedef typename inter_storage_type::type inter_ptr_type;
+  typedef typename split_storage_type::type split_ptr_type;
+
+  typedef Rt_pointer<typename Block::value_type> rt_ptr_type;
+
+  static void copy(Block* block, LP const& layout, inter_ptr_type data)
+  {
+    Length<Dim> ext = extent<Dim>(*block);
+
+    for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
       put(*block, idx, inter_storage_type::get(data, layout.index(idx)));
   }
 
-  static void copy_out(Block* block, LP const& layout, split_ptr_type data)
+  static void copy(Block* block, LP const& layout, split_ptr_type data)
   {
     Length<Dim> ext = extent<Dim>(*block);
 
@@ -146,22 +244,41 @@
       put(*block, idx, split_storage_type::get(data, layout.index(idx)));
   }
 
-  static void copy_out(Block* block, LP const& layout, rt_ptr_type data)
+  static void copy(Block* block, LP const& layout, rt_ptr_type data)
   {
     if (complex_format(layout) == cmplx_inter_fmt)
-      copy_out(block, layout, data.as_inter());
+      copy(block, layout, data.as_inter());
     else
-      copy_out(block, layout, data.as_split());
+      copy(block, layout, data.as_split());
   }
 };
 
 
+// Specialization for const blocks (with complex value type).
+//
+// Const blocks cannot be written to.  However, Ext_data and Rt_ext_data
+// use a run-time value (sync) to determine if a block will be written.
 
+template <dimension_type Dim,
+	  typename       Block>
+struct Rt_block_copy_from_ptr_impl<Dim, Block const, true>
+{
+  typedef Applied_layout<Rt_layout<Dim> > LP;
+
+  typedef Rt_pointer<typename Block::value_type> rt_ptr_type;
+
+  static void copy(Block const*, LP const&, rt_ptr_type)
+  {
+    assert(false);
+  }
+};
+
+
 /// Specialization for blocks with non-complex value_types.
 
 template <dimension_type Dim,
 	  typename       Block>
-struct Rt_block_copy_impl<Dim, Block, false>
+struct Rt_block_copy_from_ptr_impl<Dim, Block, false>
 {
   typedef Applied_layout<Rt_layout<Dim> > LP;
 
@@ -171,37 +288,40 @@
   typedef typename inter_storage_type::type inter_ptr_type;
   typedef Rt_pointer<typename Block::value_type> rt_ptr_type;
 
-
-  static void copy_in (Block* block, LP const& layout, inter_ptr_type data)
+  static void copy(Block* block, LP const& layout, inter_ptr_type data)
   {
     Length<Dim> ext = extent<Dim>(*block);
 
     for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
-      inter_storage_type::put(data, layout.index(idx), get(*block, idx));
+      put(*block, idx, inter_storage_type::get(data, layout.index(idx)));
   }
 
-  static void copy_in (Block* block, LP const& layout, rt_ptr_type data)
+  static void copy(Block* block, LP const& layout, rt_ptr_type data)
   {
-    copy_in(block, layout, data.as_inter());
+    copy(block, layout, data.as_inter());
   }
+};
 
-  static void copy_out(Block* block, LP const& layout, inter_ptr_type data)
-  {
-    Length<Dim> ext = extent<Dim>(*block);
 
-    for (Index<Dim> idx; valid(ext, idx); next(ext, idx))
-      put(*block, idx, inter_storage_type::get(data, layout.index(idx)));
-  }
+/// Specialization for const blocks (with non-complex value type).
 
-  static void copy_out(Block* block, LP const& layout, rt_ptr_type data)
+template <dimension_type Dim,
+	  typename       Block>
+struct Rt_block_copy_from_ptr_impl<Dim, Block const, false>
+{
+  typedef Applied_layout<Rt_layout<Dim> > LP;
+
+  typedef Rt_pointer<typename Block::value_type> rt_ptr_type;
+
+  static void copy(Block const*, LP const&, rt_ptr_type)
   {
-    copy_out(block, layout, data.as_inter());
+    assert(false);
   }
 };
 
 
 
-/// Utility class to copy block data into/out-of of regular memory,
+/// Utility classes to copy block data to/from a pointer to regular memory,
 /// with layout determined at run-time.
 
 /// Requires:
@@ -210,14 +330,21 @@
 
 template <dimension_type Dim,
 	  typename       Block>
-struct Rt_block_copy
-  : Rt_block_copy_impl<Dim, Block,
+struct Rt_block_copy_to_ptr
+  : Rt_block_copy_to_ptr_impl<Dim, Block,
 		    vsip::impl::Is_complex<typename Block::value_type>::value>
-{
-};
+{};
 
+template <dimension_type Dim,
+	  typename       Block>
+struct Rt_block_copy_from_ptr
+  : Rt_block_copy_from_ptr_impl<Dim, Block,
+		    vsip::impl::Is_complex<typename Block::value_type>::value>
+{};
 
 
+
+
 template <dimension_type Dim,
 	  typename       BlockT,
 	  typename       OrderT  = typename Block_layout<BlockT>::order_type,
Index: tests/regressions/fft_expr_arg.cpp
===================================================================
--- tests/regressions/fft_expr_arg.cpp	(revision 0)
+++ tests/regressions/fft_expr_arg.cpp	(revision 0)
@@ -0,0 +1,98 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/fft_expr_arg.cpp
+    @author  Jules Bergmann
+    @date    2006-05-10
+    @brief   VSIPL++ Library: Regression test for passing an expression
+             as an argument to Fft (Issue #125).
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/signal.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T1,
+	  typename T2>
+struct Fft_dir_trait;
+
+template <typename T>
+struct Fft_dir_trait<complex<T>, complex<T> >
+{
+  static int const fwd = fft_fwd;
+  static int const inv = fft_inv;
+};
+
+template <typename T>
+struct Fft_dir_trait<T, complex<T> >
+{
+  static int const fwd = 0;
+  // cannot perform inverse
+};
+
+template <typename T>
+struct Fft_dir_trait<complex<T>, T>
+{
+  // cannot perform forward
+  static int const inv = 0;
+};
+
+
+
+template <typename View1, typename View2, typename View3>
+void pulseCompression(int decimationFactor, 
+                      View1 in, View2 ref, View3 out) {
+  int size = in.size() / decimationFactor;
+
+  Domain<1> decimatedDomain(0, decimationFactor, size);
+
+  typedef typename View1::value_type T1;
+  typedef typename View2::value_type T2;
+  typedef typename View3::value_type T3;
+
+  Fft<const_Vector, T1, T2, Fft_dir_trait<T1, T2>::fwd>
+    forwardFft (size, 1);
+  Fft<const_Vector, T2, T3, Fft_dir_trait<T2, T3>::inv, by_reference> 
+    inverseFft (size, 1.0/size);
+
+  T1 alpha = T1(1);
+
+  inverseFft(ref * forwardFft(alpha * in(decimatedDomain)), out);
+}
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  length_type size = 16;
+
+  Vector<complex<float> > in(size, complex<float>());
+  Vector<complex<float> > ref(size, complex<float>());
+  Vector<complex<float> > out(size);
+
+  pulseCompression(1, in, ref, out);
+
+
+  Vector<float>           in2(size,      float());
+  Vector<complex<float> > ref2(size/2+1, complex<float>());
+  Vector<float>           out2(size);
+
+  pulseCompression(1, in2, ref2, out2);
+
+  return 0;
+}
