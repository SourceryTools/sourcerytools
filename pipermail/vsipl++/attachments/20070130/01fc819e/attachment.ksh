Index: src/vsip/dense.hpp
===================================================================
--- src/vsip/dense.hpp	(revision 161463)
+++ src/vsip/dense.hpp	(working copy)
@@ -1216,6 +1216,17 @@
 
 
 
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT,
+	  typename       MapT>
+struct Is_modifiable_block<Dense<Dim, T, OrderT, MapT> >
+{
+  static bool const value = true;
+};
+
+
+
 /***********************************************************************
   Definitions - Dense_storage
 ***********************************************************************/
Index: src/vsip/core/extdata.hpp
===================================================================
--- src/vsip/core/extdata.hpp	(revision 161463)
+++ src/vsip/core/extdata.hpp	(working copy)
@@ -486,6 +486,9 @@
   length_type size(dimension_type d) const
     { return ext_.size  (blk_.get(), d); }
 
+  int cost() const
+    { return ext_.cost(); }
+
   // Member data.
 private:
   typename View_block_storage<Block>::template With_rp<RP>::type
Index: src/vsip/core/fast_block.hpp
===================================================================
--- src/vsip/core/fast_block.hpp	(revision 161463)
+++ src/vsip/core/fast_block.hpp	(working copy)
@@ -299,6 +299,17 @@
 
 
 
+template <dimension_type Dim,
+	  typename       T,
+	  typename       LP,
+	  typename       Map>
+struct Is_modifiable_block<Fast_block<Dim, T, LP, Map> >
+{
+  static bool const value = true;
+};
+
+
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: src/vsip/core/extdata_dist.hpp
===================================================================
--- src/vsip/core/extdata_dist.hpp	(revision 161463)
+++ src/vsip/core/extdata_dist.hpp	(working copy)
@@ -93,7 +93,7 @@
 ///   AT is a data access tag that selects the low-level interface
 ///      used to access the data.  By default, Choose_access is used to
 ///      select the appropriate access tag for a given block type
-///      BLOCK and layout LP.
+///      BLOCK and layout LP. [2]
 ///   IMPLTAG is a tag to choose how block needs to be reorganized,
 ///      if at all.
 ///
@@ -101,28 +101,54 @@
 /// [1] Selecting a specific low-level interface is discouraged.
 ///     Selecting one that is not compatible with BLOCK will result in
 ///     undefined behavior.
+///
+/// [2] Choose_access is not used for the default template parameter,
+///     because the block type may change before access is done, esp
+///     when ImplTag = remap.  Instead, "Default_access_type" is used
+///     to indicate that Choose_access should be used once the block
+///     type is known.
 
 template <typename Block,
+	  sync_action_type SP,
 	  typename LP      = typename Desired_block_layout<Block>::layout_type,
 	  typename RP      = No_count_policy,
-	  typename AT      = typename Choose_access<Block, LP>::type,
+	  typename AT      = Default_access_tag,
 	  typename ImplTag = typename 
                              edl_details::Choose_impl_tag<Block, LP>::type>
 class Ext_data_dist;
 
 
 
+/// Helper class for Impl_use_direct variant of Ext_data_dist to determine
+/// base class to derive from.
+
+template <typename BlockT,
+	  typename LP,
+	  typename RP,
+	  typename AT>
+struct Use_direct_helper
+{
+  typedef typename
+          ITE_Type<Type_equal<AT, Default_access_tag>::value,
+                   Choose_access<BlockT, LP>, As_type<AT> >::type
+          access_type;
+  typedef Ext_data<BlockT, LP, RP, access_type> base_type;
+};
+
+
+
 /// Ext_data_dist variant to directly use Ext_data for access to block.
 
 template <typename BlockT,
+	  sync_action_type SP,
 	  typename LP,
 	  typename RP,
 	  typename AT>
-class Ext_data_dist<BlockT, LP, RP, AT, edl_details::Impl_use_direct>
-  : public Ext_data<BlockT, LP, RP, AT>
+class Ext_data_dist<BlockT, SP, LP, RP, AT, edl_details::Impl_use_direct>
+  : public Use_direct_helper<BlockT, LP, RP, AT>::base_type
 {
   typedef typename Non_const_of<BlockT>::type non_const_block_type;
-  typedef Ext_data<BlockT, LP, RP, AT> base_type;
+  typedef typename Use_direct_helper<BlockT, LP, RP, AT>::base_type base_type;
 
   typedef typename base_type::storage_type storage_type;
   typedef typename base_type::raw_ptr_type raw_ptr_type;
@@ -130,15 +156,13 @@
   // Constructor and destructor.
 public:
   Ext_data_dist(non_const_block_type& block,
-		 sync_action_type      sync,
-		 raw_ptr_type          buffer = raw_ptr_type())
-    : base_type(block, sync, buffer)
+		raw_ptr_type          buffer = raw_ptr_type())
+    : base_type(block, SP, buffer)
   {}
 
   Ext_data_dist(BlockT const&      block,
-		 sync_action_type   sync,
-		 raw_ptr_type       buffer = raw_ptr_type())
-    : base_type(block, sync, buffer)
+		raw_ptr_type       buffer = raw_ptr_type())
+    : base_type(block, SP, buffer)
   {}
 
   ~Ext_data_dist() {}
@@ -146,19 +170,40 @@
 
 
 
-/// Ext_data_dist variant to use Ext_data access on a distributed block's
-/// local block (as returned by get_local_block).
+/// Helper class for Impl_use_local variant of Ext_data_dist to determine
+/// base class to derive from.
 
 template <typename BlockT,
 	  typename LP,
 	  typename RP,
 	  typename AT>
-class Ext_data_dist<BlockT, LP, RP, AT, edl_details::Impl_use_local>
-  : public Ext_data<typename Distributed_local_block<BlockT>::type, LP, RP, AT>
+struct Use_local_helper
 {
+  typedef typename Distributed_local_block<BlockT>::type local_block_type;
+  typedef typename
+          ITE_Type<Type_equal<AT, Default_access_tag>::value,
+                   Choose_access<local_block_type, LP>, As_type<AT> >::type
+          access_type;
+  typedef Ext_data<local_block_type, LP, RP, access_type> base_type;
+};
+
+
+
+/// Ext_data_dist variant to use Ext_data access on a distributed block's
+/// local block (as returned by get_local_block).
+
+template <typename         BlockT,
+	  sync_action_type SP,
+	  typename         LP,
+	  typename         RP,
+	  typename         AT>
+class Ext_data_dist<BlockT, SP, LP, RP, AT, edl_details::Impl_use_local>
+  : public Use_local_helper<BlockT, LP, RP, AT>::base_type
+// : public Ext_data<typename Distributed_local_block<BlockT>::type, LP, RP, AT>
+{
   typedef typename Non_const_of<BlockT>::type non_const_block_type;
   typedef typename Distributed_local_block<BlockT>::type local_block_type;
-  typedef Ext_data<local_block_type, LP, RP, AT> base_type;
+  typedef typename Use_local_helper<BlockT, LP, RP, AT>::base_type base_type;
 
   typedef typename base_type::storage_type storage_type;
   typedef typename base_type::raw_ptr_type raw_ptr_type;
@@ -166,15 +211,13 @@
   // Constructor and destructor.
 public:
   Ext_data_dist(non_const_block_type& block,
-		 sync_action_type      sync,
-		 raw_ptr_type          buffer = raw_ptr_type())
-    : base_type(get_local_block(block), sync, buffer)
+		raw_ptr_type          buffer = raw_ptr_type())
+    : base_type(get_local_block(block), SP, buffer)
   {}
 
   Ext_data_dist(BlockT const&      block,
-		 sync_action_type   sync,
-		 raw_ptr_type       buffer = raw_ptr_type())
-    : base_type(get_local_block(block), sync, buffer)
+		raw_ptr_type       buffer = raw_ptr_type())
+    : base_type(get_local_block(block), SP, buffer)
   {}
 
   ~Ext_data_dist() {}
@@ -185,11 +228,12 @@
 /// Ext_data_dist variant to use Ext_data access on a reorganized
 /// copy of the original distributed block.
 
-template <typename BlockT,
-	  typename LP,
-	  typename RP,
-	  typename AT>
-class Ext_data_dist<BlockT, LP, RP, AT, edl_details::Impl_remap>
+template <typename         BlockT,
+	  sync_action_type SP,
+	  typename         LP,
+	  typename         RP,
+	  typename         AT>
+class Ext_data_dist<BlockT, SP, LP, RP, AT, edl_details::Impl_remap>
 {
   typedef typename Non_const_of<BlockT>::type non_const_block_type;
   static dimension_type const dim = BlockT::dim;
@@ -199,7 +243,11 @@
 
   typedef typename View_of_dim<dim, value_type, BlockT>::type src_view_type;
 
-  typedef Ext_data<block_type, LP, RP, AT> ext_type;
+  typedef typename
+          ITE_Type<Type_equal<AT, Default_access_tag>::value,
+                   Choose_access<block_type, LP>, As_type<AT> >::type
+          access_type;
+  typedef Persistent_ext_data<block_type, LP, RP, access_type> ext_type;
 
   typedef Allocated_storage<typename LP::complex_type,
 			    typename BlockT::value_type> storage_type;
@@ -208,36 +256,34 @@
   // Constructor and destructor.
 public:
   Ext_data_dist(non_const_block_type& block,
-		 sync_action_type      sync,
-		 raw_ptr_type          buffer = raw_ptr_type())
+		raw_ptr_type          buffer = raw_ptr_type())
     : src_     (block),
       storage_ (block.size(), buffer),
       block_   (block_domain<dim>(block), storage_.data()),
       view_    (block_),
-      ext_     (block_, sync, buffer),
-      sync_    (sync)
+      ext_     (block_, SP)
   {
     assign_local(view_, src_);
+    ext_.begin();
   }
 
   Ext_data_dist(BlockT const&      block,
-		 sync_action_type   sync,
-		 raw_ptr_type       buffer = raw_ptr_type())
-    : src_   (const_cast<BlockT&>(block)),
+		raw_ptr_type       buffer = raw_ptr_type())
+    : src_     (const_cast<BlockT&>(block)),
       storage_ (block.size(), buffer),
-      block_ (block_domain<dim>(block), storage_.data()),
-      view_  (block_),
-      ext_   (block_, sync, buffer),
-      sync_  (sync)
+      block_   (block_domain<dim>(block), storage_.data()),
+      view_    (block_),
+      ext_     (block_, SP)
   {
-    assert(sync != SYNC_OUT && sync != SYNC_INOUT);
+    assert(SP != SYNC_OUT && SP != SYNC_INOUT);
     assign_local(view_, src_);
+    ext_.begin();
   }
 
   ~Ext_data_dist()
   {
-    if (sync_ & SYNC_OUT)
-      assign_local(src_, view_);
+    ext_.end();
+    assign_local_if<SP & SYNC_OUT>(src_, view_);
     storage_.deallocate(block_.size());
   }
 
@@ -248,7 +294,8 @@
   stride_type	stride(dimension_type d) { return ext_.stride(d); }
   length_type	size  (dimension_type d) { return ext_.size  (d); }
 
-  int           cost  ()                 { return ext_.cost(); }
+  // Copy to temp buffer view_/block_ forces cost = 2.
+  int           cost  ()                 { return 2; }
 
 private:
   src_view_type    src_;
@@ -256,7 +303,6 @@
   block_type       block_;
   view_type        view_;
   ext_type         ext_;
-  sync_action_type sync_;
 };
 
 
Index: src/vsip/core/block_copy.hpp
===================================================================
--- src/vsip/core/block_copy.hpp	(revision 161463)
+++ src/vsip/core/block_copy.hpp	(working copy)
@@ -66,7 +66,8 @@
 	  typename       Block,
 	  typename       Order,
 	  typename       PackType,
-	  typename       CmplxFmt>
+	  typename       CmplxFmt,
+	  bool           Modifiable = Is_modifiable_block<Block>::value>
 struct Block_copy_from_ptr
 {
   typedef Applied_layout<Layout<Dim, Order, PackType, CmplxFmt> > LP;
@@ -91,13 +92,13 @@
 	  typename       Order,
 	  typename       PackType,
 	  typename       CmplxFmt>
-struct Block_copy_from_ptr<Dim, Block const, Order, PackType, CmplxFmt>
+struct Block_copy_from_ptr<Dim, Block, Order, PackType, CmplxFmt, false>
 {
   typedef Applied_layout<Layout<Dim, Order, PackType, CmplxFmt> > LP;
   typedef Storage<CmplxFmt, typename Block::value_type> storage_type;
   typedef typename storage_type::type ptr_type;
 
-  static void copy(Block const*, LP&, ptr_type)
+  static void copy(Block*, LP&, ptr_type)
   { assert(0); }
 };
 
@@ -201,20 +202,27 @@
 ///   DIM is the dimension of the run-time layout.
 ///   BLOCK is a block type,
 ///   ISCOMPLEX indicates whether the value type is complex
+///   MODIFIABLE indicates whether the block is modifiable
 ///
 /// ISCOMPLEX is used to specialize the implementation so that functions
 /// can be overloaded for split and interleaved arguments.
+///
+/// ISMODIFIABLE is used to convert attempting to write to a
+/// non-modifiable block from a compile-time error to a run-time
+/// error.  This is necessary because Ext_data passes sync as
+/// a run-time parameter.
 
 template <dimension_type Dim,
 	  typename       Block,
-	  bool           IsComplex>
+	  bool           IsComplex,
+	  bool           Modifiable = Is_modifiable_block<Block>::value>
 struct Rt_block_copy_from_ptr_impl;
 
 /// Specializations for blocks with complex value_types.
 
 template <dimension_type Dim,
 	  typename       Block>
-struct Rt_block_copy_from_ptr_impl<Dim, Block, true>
+struct Rt_block_copy_from_ptr_impl<Dim, Block, true, true>
 {
   typedef Applied_layout<Rt_layout<Dim> > LP;
 
@@ -256,12 +264,13 @@
 
 // Specialization for const blocks (with complex value type).
 //
-// Const blocks cannot be written to.  However, Ext_data and Rt_ext_data
-// use a run-time value (sync) to determine if a block will be written.
+// Non-modifiable blocks cannot be written to.  However, Ext_data and
+// Rt_ext_data use a run-time value (sync) to determine if a block
+// will be written.
 
 template <dimension_type Dim,
 	  typename       Block>
-struct Rt_block_copy_from_ptr_impl<Dim, Block const, true>
+struct Rt_block_copy_from_ptr_impl<Dim, Block, true, false>
 {
   typedef Applied_layout<Rt_layout<Dim> > LP;
 
@@ -278,7 +287,7 @@
 
 template <dimension_type Dim,
 	  typename       Block>
-struct Rt_block_copy_from_ptr_impl<Dim, Block, false>
+struct Rt_block_copy_from_ptr_impl<Dim, Block, false, true>
 {
   typedef Applied_layout<Rt_layout<Dim> > LP;
 
@@ -307,7 +316,7 @@
 
 template <dimension_type Dim,
 	  typename       Block>
-struct Rt_block_copy_from_ptr_impl<Dim, Block const, false>
+struct Rt_block_copy_from_ptr_impl<Dim, Block, false, false>
 {
   typedef Applied_layout<Rt_layout<Dim> > LP;
 
Index: src/vsip/core/cvsip/eval_reductions_idx.hpp
===================================================================
--- src/vsip/core/cvsip/eval_reductions_idx.hpp	(revision 161463)
+++ src/vsip/core/cvsip/eval_reductions_idx.hpp	(working copy)
@@ -161,7 +161,7 @@
   static void exec(T& r, Block const& blk, Index<Dim>& idx, OrderT)
   {
     typedef typename Proper_type_of<Block>::type block_type;
-    Ext_data_dist<block_type> ext(blk, SYNC_IN);
+    Ext_data_dist<block_type, SYNC_IN> ext(blk);
     cvsip::View_from_ext<Dim, value_type> view(ext);
     
     r = cvsip::Reduce_idx_class<ReduceT, Dim, value_type>::exec(
Index: src/vsip/core/cvsip/conv.hpp
===================================================================
--- src/vsip/core/cvsip/conv.hpp	(revision 161463)
+++ src/vsip/core/cvsip/conv.hpp	(working copy)
@@ -29,6 +29,19 @@
 #include <vsip.h>
 }
 
+// Define this to 1 to fix the convolution results returned from
+// C-VSIP.  This works around incorrect results produced by the
+// C-VSIP ref-impl for a subset of the symmetry/support-region
+// combinations.  This may not be necessary for other C-VSIP
+// implementations.
+//
+// Defining this to 1 will produce results consistent with the
+// other Convolution implementations (Ext, IPP, and SAL).
+
+#define VSIP_IMPL_FIX_CVSIP_CONV 1
+
+
+
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -257,6 +270,7 @@
   template <typename Block0, typename Block1>
   void convolve(const_Vector<T, Block0> in, Vector<T, Block1> out)
   {
+    {
     Ext_data<Block0> ext_in(const_cast<Block0&>(in.block()));
     Ext_data<Block1> ext_out(out.block());
     cvsip::View<1, T> iview(ext_in.data(), 0,
@@ -264,6 +278,109 @@
     cvsip::View<1, T> oview(ext_out.data(), 0,
                             ext_out.stride(0), ext_out.size(0));
     traits::call(impl_, iview.ptr(), oview.ptr());
+    }
+
+
+#if VSIP_IMPL_FIX_CVSIP_CONV
+    // Fixup C-VSIP results.
+    if (S == vsip::sym_even_len_even && R == vsip::support_same)
+    {
+      typedef cvsip::View_traits<1, T> traits;
+
+      T sum = T();
+      length_type coeff_size = traits::length(coeffs_.ptr());
+      index_type D = this->decimation();
+      
+      index_type n = out.size()-1;
+      for (index_type k=0; k<2*coeff_size; ++k)
+      {
+	if (n*D + (coeff_size)   >= k &&
+	    n*D + (coeff_size)-k <  in.size())
+	{
+	  if (k<coeff_size)
+	    sum += traits::get(coeffs_.ptr(), k)
+	         * in.get((n*D+coeff_size-k));
+	  else
+	    sum += traits::get(coeffs_.ptr(), 2*coeff_size - k - 1)
+	         * in.get((n*D+coeff_size-k));
+	}
+      }
+      out.put(n, sum);
+    }
+
+    if (S == vsip::sym_even_len_even && R  == vsip::support_full)
+    {
+      typedef cvsip::View_traits<1, T> traits;
+      length_type coeff_size = traits::length(coeffs_.ptr());
+      index_type D = this->decimation();
+
+      for (index_type i=0; i<coeff_size; ++i)
+      {
+	index_type n = out.size()-1-i;
+
+	T sum = T();
+      
+	for (index_type k=0; k<2*coeff_size; ++k)
+	{
+	  if (n*D >= k && n*D-k < in.size())
+	  {
+	    if (k<coeff_size)
+	      sum += traits::get(coeffs_.ptr(), k)
+	           * in.get((n*D-k));
+	    else
+	      sum += traits::get(coeffs_.ptr(), 2*coeff_size - k - 1)
+	           * in.get((n*D-k));
+	  }
+	}
+	out.put(n, sum);
+      }
+    }
+
+    if (S == vsip::nonsym && R == vsip::support_same)
+    {
+      typedef cvsip::View_traits<1, T> traits;
+
+      T sum = T();
+      length_type coeff_size = traits::length(coeffs_.ptr());
+      index_type D = this->decimation();
+      
+      index_type n = out.size()-1;
+      for (index_type k=0; k<coeff_size; ++k)
+      {
+	if (n*D + (coeff_size/2)   >= k &&
+	    n*D + (coeff_size/2)-k <  in.size())
+	{
+	    sum += traits::get(coeffs_.ptr(), k)
+	         * in.get((n*D+(coeff_size/2)-k));
+	}
+      }
+      out.put(n, sum);
+    }
+
+    if (S == vsip::nonsym && R == vsip::support_full)
+    {
+      typedef cvsip::View_traits<1, T> traits;
+      length_type coeff_size = traits::length(coeffs_.ptr());
+      index_type D = this->decimation();
+
+      for (index_type i=0; i<(coeff_size+1)/2; ++i)
+      {
+	index_type n = out.size()-1-i;
+
+	T sum = T();
+      
+	for (index_type k=0; k<coeff_size; ++k)
+	{
+	  if (n*D >= k && n*D-k < in.size())
+	  {
+	      sum += traits::get(coeffs_.ptr(), k)
+	           * in.get((n*D-k));
+	  }
+	}
+	out.put(n, sum);
+      }
+    }
+#endif
   }
 
 private:
Index: src/vsip/core/cvsip/view.hpp
===================================================================
--- src/vsip/core/cvsip/view.hpp	(revision 161463)
+++ src/vsip/core/cvsip/view.hpp	(working copy)
@@ -149,6 +149,11 @@
   static vsip_offset offset(view_type *v) { return vsip_vgetoffset_f(v);}
   static vsip_stride stride(view_type *v) { return vsip_vgetstride_f(v);}
   static vsip_length length(view_type *v) { return vsip_vgetlength_f(v);}
+
+  static float get(view_type* v, index_type i)
+    { return (float)vsip_vget_f(v, i); }
+  static void put(view_type* v, index_type i, float value)
+    { vsip_vput_f(v, i, (vsip_scalar_f)value); }
 };
 
 template <>
@@ -220,6 +225,11 @@
   static vsip_offset offset(view_type *v) { return vsip_vgetoffset_d(v);}
   static vsip_stride stride(view_type *v) { return vsip_vgetstride_d(v);}
   static vsip_length length(view_type *v) { return vsip_vgetlength_d(v);}
+
+  static value_type get(view_type* v, index_type i)
+    { return (value_type)vsip_vget_d(v, i); }
+  static void put(view_type* v, index_type i, value_type value)
+    { vsip_vput_d(v, i, (vsip_scalar_d)value); }
 };
 
 template <>
Index: src/vsip/core/cvsip/lu.hpp
===================================================================
--- src/vsip/core/cvsip/lu.hpp	(revision 161463)
+++ src/vsip/core/cvsip/lu.hpp	(working copy)
@@ -108,8 +108,6 @@
     assert(b.size(0) == length_);
     assert(b.size(0) == x.size(0) && b.size(1) == x.size(1));
 
-    vsip_mat_op trans;
-
     Matrix<T, block_type> b_int(b.size(0), b.size(1));
     assign_local(b_int, b);
 
Index: src/vsip/core/cvsip/eval_reductions.hpp
===================================================================
--- src/vsip/core/cvsip/eval_reductions.hpp	(revision 161463)
+++ src/vsip/core/cvsip/eval_reductions.hpp	(working copy)
@@ -171,7 +171,7 @@
   static void exec(T& r, Block const& blk, OrderT, Int_type<Dim>)
   {
     typedef typename Proper_type_of<Block>::type block_type;
-    Ext_data_dist<block_type> ext(blk, SYNC_IN);
+    Ext_data_dist<block_type, SYNC_IN> ext(blk);
     cvsip::View_from_ext<Dim, value_type> view(ext);
     
     r = cvsip::Reduce_class<ReduceT, Dim, value_type>::exec(view.view_.ptr());
Index: src/vsip/core/subblock.hpp
===================================================================
--- src/vsip/core/subblock.hpp	(revision 161463)
+++ src/vsip/core/subblock.hpp	(working copy)
@@ -222,8 +222,13 @@
   typedef Layout<dim, order_type, pack_type, complex_type> layout_type;
 };
 
+template <typename BlockT, template <typename> class Extractor>
+struct Is_modifiable_block<Component_block<BlockT, Extractor> >
+  : Is_modifiable_block<BlockT>
+{};
 
 
+
 template <dimension_type Dim,
 	  typename       MapT>
 struct Subset_block_map
@@ -471,6 +476,13 @@
   };
 };
 
+template <typename BlockT>
+struct Is_modifiable_block<Subset_block<BlockT> >
+  : Is_modifiable_block<BlockT>
+{};
+
+
+
 /// The Transposed_block class exchanges the order of indices to a
 /// 2-dimensional block, and the dimensions visible via 2-argument
 /// size().
@@ -569,8 +581,13 @@
   };
 };
 
+template <typename BlockT>
+struct Is_modifiable_block<Transposed_block<BlockT> >
+  : Is_modifiable_block<BlockT>
+{};
 
 
+
 // Take transpose of dimension-order.
 template <typename T>
 struct Transpose_order;
@@ -732,7 +749,12 @@
   };
 };
 
+template <typename BlockT, typename Ordering>
+struct Is_modifiable_block<Permuted_block<BlockT, Ordering> >
+  : Is_modifiable_block<BlockT>
+{};
 
+
 template <typename MapT, dimension_type SubDim>
 struct Sliced_block_map {};
 
@@ -839,6 +861,11 @@
   };
 };
 
+template <typename BlockT, dimension_type D>
+struct Is_modifiable_block<Sliced_block<BlockT, D> >
+  : Is_modifiable_block<BlockT>
+{};
+
 template <typename Block, dimension_type D> 
 class Sliced_block_base : public impl::Compile_time_assert<(Block::dim >= 2)>,
 			  public impl::Non_assignable
@@ -1028,6 +1055,11 @@
   };
 };
 
+template <typename BlockT, dimension_type D1, dimension_type D2>
+struct Is_modifiable_block<Sliced2_block<BlockT, D1, D2> >
+  : Is_modifiable_block<BlockT>
+{};
+
 template <typename Block, dimension_type D1, dimension_type D2>
 class Sliced2_block_base 
   : public impl::Compile_time_assert<(Block::dim > D2 && D2 > D1)>,
@@ -1729,6 +1761,11 @@
   };
 };
 
+template <typename BlockT>
+struct Is_modifiable_block<Diag_block<BlockT> >
+  : Is_modifiable_block<BlockT>
+{};
+
 template <typename Block> 
 class Diag_block 
     : public impl::Compile_time_assert<(Block::dim == 2)>,
Index: src/vsip/core/working_view.hpp
===================================================================
--- src/vsip/core/working_view.hpp	(revision 161463)
+++ src/vsip/core/working_view.hpp	(working copy)
@@ -175,6 +175,31 @@
 
 
 
+/// Guarded Assign_local
+
+template <bool     PerformAssignment,
+	  typename ViewT1,
+	  typename ViewT2>
+struct Assign_local_if
+{
+  static void exec(ViewT1 dst, ViewT2 src)
+  {
+    Assign_local<ViewT1, ViewT2>::exec(dst, src);
+  }
+};
+
+
+
+template <typename ViewT1,
+	  typename ViewT2>
+struct Assign_local_if<false, ViewT1, ViewT2>
+{
+  static void exec(ViewT1, ViewT2)
+  { /* no assignment */ }
+};
+
+
+
 /// Assign between local and distributed views.
 
 template <typename ViewT1,
@@ -193,6 +218,24 @@
 
 
 
+/// Guarded assign between local and distributed views.
+
+template <bool     PerformAssignment,
+	  typename ViewT1,
+	  typename ViewT2>
+void assign_local_if(
+  ViewT1 dst,
+  ViewT2 src)
+{
+  VSIP_IMPL_STATIC_ASSERT((Is_view_type<ViewT1>::value));
+  VSIP_IMPL_STATIC_ASSERT((Is_view_type<ViewT2>::value));
+  VSIP_IMPL_STATIC_ASSERT(ViewT1::dim == ViewT2::dim);
+
+  Assign_local_if<PerformAssignment, ViewT1, ViewT2>::exec(dst, src);
+}
+
+
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: src/vsip/core/block_traits.hpp
===================================================================
--- src/vsip/core/block_traits.hpp	(revision 161463)
+++ src/vsip/core/block_traits.hpp	(working copy)
@@ -160,12 +160,16 @@
 /// Flexible_access_tag -- determine whether to use direct or copy access
 ///                        at runtime.
 /// Bogus_access_tag    -- Tag for debugging purposes.
+/// Default_access_tag  -- When used as argument to Ext_data_dist, indicate
+///                        that default tag (from Choose_access) should be
+///                        used.
 
 struct Direct_access_tag {};
 struct Reorder_access_tag {};
 struct Copy_access_tag {};
 struct Flexible_access_tag {};
 struct Bogus_access_tag {};
+struct Default_access_tag {};
 
 
 
@@ -446,6 +450,39 @@
   static bool const value = false;
 };
 
+
+namespace detail
+{
+
+typedef char (&no_tag)[1];
+typedef char (&yes_tag)[2];
+
+template <typename T>
+no_tag
+has_put_helper(...);
+
+template <typename T, void (T::*)(index_type, typename T::value_type)>
+struct ptmf_helper;
+
+template <typename T>
+yes_tag
+has_put_helper(int, ptmf_helper<T, &T::put>* p = 0);
+
+template <typename BlockT>
+struct Has_put
+{
+  static bool const value = 
+  sizeof(has_put_helper<BlockT>(0)) == sizeof(yes_tag);
+};
+
+} // namespace detail
+
+template <typename BlockT>
+struct Is_modifiable_block
+{
+  static bool const value = detail::Has_put<BlockT>::value;
+};
+
 } // namespace impl
 
 } // namespace vsip
Index: src/vsip/opt/pas/assign_eb.hpp
===================================================================
--- src/vsip/opt/pas/assign_eb.hpp	(revision 161463)
+++ src/vsip/opt/pas/assign_eb.hpp	(working copy)
@@ -94,8 +94,10 @@
     long  max_components = Block1::components > Block2::components ?
                            Block1::components : Block2::components;
 
-    pas_pset_get_pnums_list(src_pset, &src_pnums, &src_npnums);
-    pas_pset_get_pnums_list(dst_pset, &dst_pnums, &dst_npnums);
+    rc = pas_pset_get_pnums_list(src_pset, &src_pnums, &src_npnums);
+    VSIP_IMPL_CHECK_RC(rc, "pas_pset_get_pnums_list");
+    rc = pas_pset_get_pnums_list(dst_pset, &dst_pnums, &dst_npnums);
+    VSIP_IMPL_CHECK_RC(rc, "pas_pset_get_pnums_list");
     all_pnums = pas_pset_combine(src_pnums, dst_pnums, PAS_PSET_UNION,
 				 &all_npnums);
     rc = pas_pset_create(all_pnums, 0, &all_pset);
@@ -167,6 +169,7 @@
 		    &xfer_handle_); 
       VSIP_IMPL_CHECK_RC(rc, "pas_push_setup");
     }
+
     rc = pas_pset_close(all_pset, 0);
     VSIP_IMPL_CHECK_RC(rc, "pas_pset_close");
   }
Index: src/vsip/opt/pas/assign.hpp
===================================================================
--- src/vsip/opt/pas/assign.hpp	(revision 161463)
+++ src/vsip/opt/pas/assign.hpp	(working copy)
@@ -94,8 +94,10 @@
     long  max_components = Block1::components > Block2::components ?
                            Block1::components : Block2::components;
 
-    pas_pset_get_pnums_list(src_pset, &src_pnums, &src_npnums);
-    pas_pset_get_pnums_list(dst_pset, &dst_pnums, &dst_npnums);
+    rc = pas_pset_get_pnums_list(src_pset, &src_pnums, &src_npnums);
+    VSIP_IMPL_CHECK_RC(rc, "pas_pset_get_pnums_list");
+    rc = pas_pset_get_pnums_list(dst_pset, &dst_pnums, &dst_npnums);
+    VSIP_IMPL_CHECK_RC(rc, "pas_pset_get_pnums_list");
     all_pnums = pas_pset_combine(src_pnums, dst_pnums, PAS_PSET_UNION,
 				 &all_npnums);
     rc = pas_pset_create(all_pnums, 0, &all_pset);
Index: src/vsip/opt/signal/conv_ext.hpp
===================================================================
--- src/vsip/opt/signal/conv_ext.hpp	(revision 161463)
+++ src/vsip/opt/signal/conv_ext.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -247,11 +247,11 @@
   typedef typename Adjust_layout<T, req_LP, LP0>::type use_LP0;
   typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
 
-  typedef vsip::impl::Ext_data_dist<Block0, use_LP0>  in_ext_type;
-  typedef vsip::impl::Ext_data_dist<Block1, use_LP1> out_ext_type;
+  typedef Ext_data_dist<Block0, SYNC_IN,  use_LP0>  in_ext_type;
+  typedef Ext_data_dist<Block1, SYNC_OUT, use_LP1> out_ext_type;
 
-  in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
-  out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
+  in_ext_type  in_ext (in.block(),  in_buffer_);
+  out_ext_type out_ext(out.block(), out_buffer_);
 
   VSIP_IMPL_PROFILE(pm_in_ext_cost_  += in_ext.cost());
   VSIP_IMPL_PROFILE(pm_out_ext_cost_ += out_ext.cost());
@@ -319,11 +319,11 @@
   typedef typename Adjust_layout<T, req_LP, LP0>::type use_LP0;
   typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
 
-  typedef vsip::impl::Ext_data_dist<Block0, use_LP0>  in_ext_type;
-  typedef vsip::impl::Ext_data_dist<Block1, use_LP1> out_ext_type;
+  typedef Ext_data_dist<Block0, SYNC_IN,  use_LP0>  in_ext_type;
+  typedef Ext_data_dist<Block1, SYNC_OUT, use_LP1> out_ext_type;
 
-  in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
-  out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
+  in_ext_type  in_ext (in.block(),  in_buffer_);
+  out_ext_type out_ext(out.block(), out_buffer_);
 
   VSIP_IMPL_PROFILE(pm_in_ext_cost_  += in_ext.cost());
   VSIP_IMPL_PROFILE(pm_out_ext_cost_ += out_ext.cost());
Index: src/vsip/opt/signal/corr_ext.hpp
===================================================================
--- src/vsip/opt/signal/corr_ext.hpp	(revision 161463)
+++ src/vsip/opt/signal/corr_ext.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -229,13 +229,13 @@
   typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
   typedef typename Adjust_layout<T, req_LP, LP2>::type use_LP2;
 
-  typedef vsip::impl::Ext_data_dist<Block0, use_LP0> ref_ext_type;
-  typedef vsip::impl::Ext_data_dist<Block1, use_LP1>  in_ext_type;
-  typedef vsip::impl::Ext_data_dist<Block2, use_LP2> out_ext_type;
+  typedef Ext_data_dist<Block0, SYNC_IN,  use_LP0> ref_ext_type;
+  typedef Ext_data_dist<Block1, SYNC_IN,  use_LP1> in_ext_type;
+  typedef Ext_data_dist<Block2, SYNC_OUT, use_LP2> out_ext_type;
 
-  ref_ext_type ref_ext(ref.block(), vsip::impl::SYNC_IN,  ref_buffer_);
-  in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
-  out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
+  ref_ext_type ref_ext(ref.block(), ref_buffer_);
+  in_ext_type  in_ext (in.block(),  in_buffer_);
+  out_ext_type out_ext(out.block(), out_buffer_);
 
   pm_ref_ext_cost_ += ref_ext.cost();
   pm_in_ext_cost_  += in_ext.cost();
@@ -313,13 +313,13 @@
   typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
   typedef typename Adjust_layout<T, req_LP, LP2>::type use_LP2;
 
-  typedef vsip::impl::Ext_data_dist<Block0, use_LP0> ref_ext_type;
-  typedef vsip::impl::Ext_data_dist<Block1, use_LP1>  in_ext_type;
-  typedef vsip::impl::Ext_data_dist<Block2, use_LP2> out_ext_type;
+  typedef Ext_data_dist<Block0, SYNC_IN,  use_LP0> ref_ext_type;
+  typedef Ext_data_dist<Block1, SYNC_IN,  use_LP1> in_ext_type;
+  typedef Ext_data_dist<Block2, SYNC_OUT, use_LP2> out_ext_type;
 
-  ref_ext_type ref_ext(ref.block(), vsip::impl::SYNC_IN,  ref_buffer_);
-  in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
-  out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
+  ref_ext_type ref_ext(ref.block(), ref_buffer_);
+  in_ext_type  in_ext (in.block(),  in_buffer_);
+  out_ext_type out_ext(out.block(), out_buffer_);
 
   pm_ref_ext_cost_ += ref_ext.cost();
   pm_in_ext_cost_  += in_ext.cost();
Index: scripts/package.py
===================================================================
--- scripts/package.py	(revision 161463)
+++ scripts/package.py	(working copy)
@@ -25,6 +25,7 @@
 class Configuration:
     suffix=''
     options=''
+    tests_ids=''
 
 class Package:
     suffix=''
@@ -54,6 +55,7 @@
             configs[c.suffix]['options']        = ' '.join(c.options)
             configs[c.suffix]['libdir']         = c.libdir
             configs[c.suffix]['builtin_libdir'] = c.builtin_libdir
+            configs[c.suffix]['tests_ids']      = c.tests_ids
 
     return package.suffix, package.host, configs
 
@@ -133,7 +135,7 @@
             configure('--enable-maintainer-mode', '--enable-fft=')
             announce('build docs...')
             try:
-                spawn(['sh', '-c', 'make doc2src'])
+                spawn(['sh', '-c', 'make doc2src_noapi'])
             finally:
                 announce('done building docs.')
         else:
@@ -248,11 +250,12 @@
         for s in parameters['config']: # keys are suffixes...
             libdir              = parameters['config'][s]['libdir']
             builtin_libdir      = parameters['config'][s]['builtin_libdir']
+            tests_ids           = parameters['config'][s]['tests_ids']
             full_libdir         = '%s/lib/%s'%(prefix,libdir)
             full_builtin_libdir = '%s/lib/%s'%(prefix,builtin_libdir)
             announce('testing suffix %s...'%s)
             spawn(['sh', '-c',
-                   'make installcheck prefix=%s libdir=%s builtin_libdir=%s'%(prefix, full_libdir, full_builtin_libdir)])
+                   'make installcheck prefix=%s libdir=%s builtin_libdir=%s tests_ids="%s"'%(prefix, full_libdir, full_builtin_libdir, tests_ids)])
             # Save results file for later investigation of failures.
             spawn(['sh', '-c',
                    'cp tests/results.qmr tests/results%s.qmr'%s])
Index: scripts/config
===================================================================
--- scripts/config	(revision 161463)
+++ scripts/config	(working copy)
@@ -41,7 +41,23 @@
 # Serial   Builtin sparc  sparc
 # Parallel Builtin sparc  sparc
 
+########################################################################
+# Files and Directories
+########################################################################
 
+g2c32 = '/usr/local/tools/vpp-1.0/i686-pc-linux-gnu/lib/libg2c.a'
+# g2c64 = '/usr/lib/gcc-lib/x86_64-redhat-linux/3.2.3/libg2c.a' # RHEL 3
+g2c64 = '/usr/lib/gcc/x86_64-redhat-linux/3.4.3/libg2c.a'	# RHEL 4
+
+ipp_dir = '/opt/intel/ipp'
+mkl_dir = '/opt/intel/mkl721'
+
+pas_dir = '/usr/local/tools/vpp-1.0/pas'
+
+cvsip_dir = '/usr/local/tools/vpp-1.0'
+
+
+
 ########################################################################
 # Compiler flags
 ########################################################################
@@ -108,18 +124,28 @@
 nompi = ['--disable-mpi']
 mpi = ['--enable-mpi']
 
-g2c32 = '/usr/local/tools/vpp-1.0/i686-pc-linux-gnu/lib/libg2c.a'
-# g2c64 = '/usr/lib/gcc-lib/x86_64-redhat-linux/3.2.3/libg2c.a' # RHEL 3
-g2c64 = '/usr/lib/gcc/x86_64-redhat-linux/3.4.3/libg2c.a'	# RHEL 4
+mkl_32 = ['--with-mkl-prefix=%s'%mkl_dir, '--with-mkl-arch=32']
+mkl_64 = ['--with-mkl-prefix=%s'%mkl_dir, '--with-mkl-arch=em64t']
 
-ipp_dir = '/opt/intel/ipp'
-mkl_dir = '/opt/intel/mkl721'
 
-pas_dir = '/usr/local/tools/vpp-1.0/pas'
+# Reference Implementation
 
-mkl_32 = ['--with-mkl-prefix=%s'%mkl_dir, '--with-mkl-arch=32']
-mkl_64 = ['--with-mkl-prefix=%s'%mkl_dir, '--with-mkl-arch=em64t']
+ref_impl = [ '--enable-ref-impl',
+	     '--enable-cvsip',
+             '--with-cvsip-prefix=%s'%cvsip_dir,
+	     '--with-lapack=no',
+	     '--enable-fft=cvsip']
 
+
+# C-VSIP BE, non reference implementation
+
+cvsip_be = [ '--enable-cvsip',
+             '--with-cvsip-prefix=%s'%cvsip_dir,
+	     '--with-lapack=no',
+	     '--enable-fft=cvsip,no_fft' ]
+
+
+
 ########################################################################
 # Mondo Packages
 ########################################################################
@@ -170,6 +196,99 @@
     par_em64t_builtin_release = ParEM64TBuiltinRelease
     par_em64t_builtin_debug   = ParEM64TBuiltinDebug
 
+
+
+# Binary package for reference implementation.
+#
+# This binary package is for test purposes only.  It depends on
+# C-VSIP to be installed in /usr/local/tools/vpp-1.0 and therefore
+# may not run on non-CSL systems.
+
+class TestRefImpl(Package):
+
+    class Par64RefImplDebug(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/par-refimpl-debug'
+        suffix = '-par-refimpl-64-debug'
+        tests_ids = 'ref-impl'
+        options = ['CXXFLAGS="%s"'%' '.join(debug)
+                  ] + ref_impl + mpi + common_64
+
+    class Par64RefImplRelease(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/par-refimpl'
+        suffix = '-par-refimpl-64'
+        tests_ids = 'ref-impl'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic)
+                  ] + ref_impl + mpi + common_64
+
+    class Ser64RefImplDebug(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/ser-refimpl-debug'
+        suffix = '-ser-refimpl-64-debug'
+        tests_ids = 'ref-impl'
+        options = ['CXXFLAGS="%s"'%' '.join(debug)
+                  ] + ref_impl + nompi + common_64
+
+    class Ser64RefImplRelease(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/ser-refimpl'
+        suffix = '-ser-refimpl-64'
+        tests_ids = 'ref-impl'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic)
+                  ] + ref_impl + nompi + common_64
+
+    suffix = '-linux'
+    host = 'x86'
+
+    par_64_refimpl_debug      = Par64RefImplDebug
+    par_64_refimpl_release    = Par64RefImplRelease
+
+
+
+# Binary package for C-VSIP backends.
+#
+# This binary package is for test purposes only.  It depends on
+# C-VSIP to be installed in /usr/local/tools/vpp-1.0 and therefore
+# may not run on non-CSL systems.
+
+class TestCvsipBe(Package):
+
+    class Par64CvsipDebug(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/par-cvsip-debug'
+        suffix = '-par-cvsip-64-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug)
+		  ] + cvsip_be + mpi + common_64
+
+    class Par64CvsipRelease(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/par-cvsip'
+        suffix = '-par-cvsip-64'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic)
+		  ] + cvsip_be + mpi + common_64
+
+    class Ser64CvsipDebug(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/ser-cvsip-debug'
+        suffix = '-ser-cvsip-64-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug)
+		  ] + cvsip_be + nompi + common_64
+
+    class Ser64CvsipRelease(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/ser-cvsip'
+        suffix = '-ser-cvsip-64'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic)
+		  ] + cvsip_be + nompi + common_64
+
+    suffix = '-linux'
+    host = 'x86'
+
+
+
+# "Mondo" binary package for x86 GNU/Linux.
+
 class Mondo(Package):
 
     class Ser32IntelRelease(Configuration):
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 161463)
+++ ChangeLog	(working copy)
@@ -1,3 +1,57 @@
+2007-01-29  Jules Bergmann  <jules@codesourcery.com>
+
+	Add config support for ref-impl and C-VSIP binary packages.
+	* scripts/package.py (Configuration): Add tests_ids field.
+	* scripts/config: Add test binary packages for reference
+	  implementation (TestRefImpl) and C-VSIP backends (TestCvsipBe)
+	
+	New block trait Is_modifiable_block.
+	* src/vsip/core/block_traits.hpp (Is_modifiable_block): New trait,
+	  indicates if block is modifiable.
+	* src/vsip/dense.hpp (Is_modifiable_block): Specialize.
+	* src/vsip/core/fast_block.hpp (Is_modifiable_block): Specialize.
+	* src/vsip/core/subblock.hpp (Is_modifiable_block): Specialize.
+	* src/vsip/core/block_copy.hpp: Use Is_modifiable_block trait
+	  instead of block constness to determine if block is modifiable.
+	
+
+	Ext_data_dist cleanup.
+	* src/vsip/core/extdata_dist.hpp: Avoid choosing default value
+	  for template parameter AT until block type is known.  Change
+	  sync type from constructor/run-time parameter to template/
+	  compile-time parameter.  Use Persistent_ext_data for Impl_remap,
+	  avoid sharing buffer between Us_block and Ext_data object.
+	* src/vsip/core/extdata.hpp (Peristent_ext_data::cost): Define
+	  member function.
+	* src/vsip/core/cvsip/eval_reductions_idx.hpp: Use new Ext_data_dist
+	  interface.
+	* src/vsip/core/cvsip/eval_reductions.hpp: Likewise.
+	* src/vsip/opt/signal/conv_ext.hpp: Likewise.
+	* src/vsip/opt/signal/corr_ext.hpp: Likewise.
+	
+	* src/vsip/core/cvsip/conv.hpp: Add fixup code for the cases
+	  not handled correctly by TVCPP.
+	* src/vsip/core/cvsip/view.hpp (View_traits): Add get(), put()
+	  methods, used by conv.hpp.
+	
+	* src/vsip/core/cvsip/lu.hpp: Remove unused variable.
+	* src/vsip/core/working_view.hpp (assign_local_if): New function,
+	  conditional version of assign_local.
+	* src/vsip/opt/pas/assign_eb.hpp: Check return value for
+	  pas_pset_get_pnums_list.
+	* src/vsip/opt/pas/assign.hpp: Likewise.
+	  
+	* tests/regressions/conv_to_subview.cpp: Update error checking
+	  to use error_db.
+	* tests/fir.cpp: Likewise.
+	* tests/extdata_dist.cpp: Update to use new Ext_data_dist interface.
+	  Add coverage for expressions.
+	* tests/convolution.cpp: Use error_db instead of equal, lower
+	  error thresholds for C-VSIP BE.
+	* tests/reductions-idx.cpp: Add more coverage for distributed
+	  reductions.
+	* tests/reductions.cpp: Likewise.
+	
 2007-01-26  Stefan Seefeld  <stefan@localhost.localdomain>
 
 	* src/vsip/opt/cbe/alf/src/ppu/GNUmakefile.inc.in: New file.
@@ -7,7 +61,7 @@
 	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Don't embed SPE images.
 	* src/vsip/opt/cbe/ppu/alf.hpp: Use spe_open_image() et al.
 	* src/vsip/opt/cbe/ppu/bindings.cpp: Likewise.
-
+	
 2007-01-25  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/parallel.hpp: Guard inclusion of opt/parallel/foreach
Index: tests/reductions-idx.cpp
===================================================================
--- tests/reductions-idx.cpp	(revision 161463)
+++ tests/reductions-idx.cpp	(working copy)
@@ -18,6 +18,7 @@
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
+#include <vsip/map.hpp>
 
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/test-storage.hpp>
@@ -103,6 +104,9 @@
   test_maxval<Storage<3, T, tuple<1, 2, 0> > >(Domain<3>(15, 17, 7), 8);
   test_maxval<Storage<3, T, tuple<2, 0, 1> > >(Domain<3>(15, 17, 7), 8);
   test_maxval<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
+
+  test_maxval<Storage<1, T, row1_type, Map<> > >(Domain<1>(15), 8);
+  test_maxval<Storage<1, T, row1_type, Global_map<1> > >(Domain<1>(15), 8);
 }
 
 
@@ -155,6 +159,9 @@
   test_minval<Storage<3, T, tuple<1, 2, 0> > >(Domain<3>(15, 17, 7), 8);
   test_minval<Storage<3, T, tuple<2, 0, 1> > >(Domain<3>(15, 17, 7), 8);
   test_minval<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
+
+  test_minval<Storage<1, T, row1_type, Map<> > >(Domain<1>(15), 8);
+  test_minval<Storage<1, T, row1_type, Global_map<1> > >(Domain<1>(15), 8);
 }
 
 
@@ -217,6 +224,9 @@
   test_mgval<Storage<3, T, tuple<1, 2, 0> > >(Domain<3>(15, 17, 7), 8);
   test_mgval<Storage<3, T, tuple<2, 0, 1> > >(Domain<3>(15, 17, 7), 8);
   test_mgval<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
+
+  test_mgval<Storage<1, T, row1_type, Map<> > >(Domain<1>(15), 8);
+  test_mgval<Storage<1, T, row1_type, Global_map<1> > >(Domain<1>(15), 8);
 }
 
 
@@ -279,6 +289,9 @@
   test_mgsqval<Storage<3, T, tuple<1, 2, 0> > >(Domain<3>(15, 17, 7), 8);
   test_mgsqval<Storage<3, T, tuple<2, 0, 1> > >(Domain<3>(15, 17, 7), 8);
   test_mgsqval<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
+
+  test_mgsqval<Storage<1, T, row1_type, Map<> > >(Domain<1>(15), 8);
+  test_mgsqval<Storage<1, T, row1_type, Global_map<1> > >(Domain<1>(15), 8);
 }
 
 
Index: tests/block_traits.cpp
===================================================================
--- tests/block_traits.cpp	(revision 0)
+++ tests/block_traits.cpp	(revision 0)
@@ -0,0 +1,148 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/block_traits.cpp
+    @author  Jules Bergmann
+    @date    2007-01-26
+    @brief   VSIPL++ Library: Test block traits.
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
+#include <vsip/vector.hpp>
+#include <vsip/core/us_block.hpp>
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
+template <typename T>
+struct put_block
+{
+  typedef T value_type;
+  value_type get() { return T(1); }
+  void put(index_type, value_type) {}
+};
+
+template <typename T>
+struct noput_block
+{
+  typedef T value_type;
+  value_type get() { return T(1); }
+};
+
+struct derived_block : put_block<float>
+{
+};
+
+
+void
+test_modifiable_1()
+{
+  using vsip::impl::Is_modifiable_block;
+  using vsip::impl::Fast_block;
+  using vsip::impl::Us_block;
+  using vsip::impl::Dense_storage;
+  using vsip::impl::Cmplx_inter_fmt;
+
+  test_assert((Is_modifiable_block<Dense<1, float> >::value == true));
+  test_assert((Is_modifiable_block<Fast_block<1, float> >::value == true));
+
+  test_assert((Is_modifiable_block<Us_block<1, float> >::value == true));
+  test_assert((Is_modifiable_block<Us_block<1, complex<float> > >::value == true));
+  test_assert((Is_modifiable_block<Us_block<2, float> >::value == true));
+  // test_assert((Is_modifiable_block<Us_block<3, complex<float> > >::value == true));
+
+  // Has_modifiable mostly does the right thing on its own.
+  test_assert((Is_modifiable_block<noput_block<float> >::value == false));
+  test_assert((Is_modifiable_block<put_block<float> >::value == true));
+
+  // However, it can get confused.
+  test_assert((Is_modifiable_block<derived_block>::value == false));
+}
+
+
+
+template <typename ViewT>
+void
+check_modifiable(ViewT, bool modifiable)
+{
+  using vsip::impl::Is_modifiable_block;
+  test_assert((Is_modifiable_block<typename ViewT::block_type>::value ==
+	  modifiable));
+}
+
+
+
+void
+test_modifiable_2()
+{
+  Vector<float> vec(16);
+  Matrix<float> mat(8, 12);
+  Matrix<float> ten(3, 4, 5);
+
+  check_modifiable(vec, true);
+  check_modifiable(vec(Domain<1>(4)), true);
+
+  check_modifiable(vec + vec, false);
+  check_modifiable((vec + vec)(Domain<1>(4)), false);
+
+  check_modifiable(mat, true);
+  check_modifiable(mat.row(0), true);
+  check_modifiable(mat.diag(0), true);
+  check_modifiable(mat.transpose(), true);
+  check_modifiable(mat(Domain<2>(4, 6)), true);
+
+  check_modifiable(mat + 1, false);
+  check_modifiable((mat + 1).col(0), false);
+  check_modifiable((-mat).transpose(), false);
+  check_modifiable((mat + mat)(Domain<2>(4, 6)), false);
+
+  check_modifiable(ten, true);
+
+  check_modifiable(ten + ten, false);
+
+
+  Vector<complex<float> > cvec(16);
+
+  check_modifiable(cvec, true);
+  check_modifiable(cvec(Domain<1>(4)), true);
+  check_modifiable(cvec.real(), true);
+  check_modifiable(cvec.imag(), true);
+
+  check_modifiable(cvec.real() + cvec.imag(), false);
+  check_modifiable((cvec + cvec).real(), false);
+}
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_modifiable_1();
+  test_modifiable_2();
+
+  return 0;
+}
Index: tests/regressions/conv_to_subview.cpp
===================================================================
--- tests/regressions/conv_to_subview.cpp	(revision 161463)
+++ tests/regressions/conv_to_subview.cpp	(working copy)
@@ -24,6 +24,7 @@
 #include <vsip/signal.hpp>
 
 #include <vsip_csl/test.hpp>
+#include <vsip_csl/error_db.hpp>
 
 using namespace std;
 using namespace vsip;
@@ -34,6 +35,8 @@
   Definitions
 ***********************************************************************/
 
+double const ERROR_THRESH = -100;
+
 length_type expected_output_size(
   support_region_type supp,
   length_type         M,    // kernel length
@@ -115,6 +118,7 @@
 
   Vector<T> in(N);
   Vector<complex<T> > out(P);
+  Vector<complex<T> > exp(P, complex<T>(201, -301));
 
   for (index_type i=0; i<N; ++i)
     in(i) = T(i);
@@ -136,8 +140,12 @@
     else
       val2 = in(i + shift - c2);
 
-    test_assert(equal(out(i), complex<T>(T(k1) * val1, T(k2) * val2)));
+    exp.put(i, complex<T>(T(k1) * val1, T(k2) * val2));
+    // test_assert(equal(out(i), complex<T>(T(k1) * val1, T(k2) * val2)));
   }
+
+  double error = error_db(out, exp);
+  test_assert(error < ERROR_THRESH);
 }
 
 
Index: tests/regressions/par_maxval.cpp
===================================================================
--- tests/regressions/par_maxval.cpp	(revision 0)
+++ tests/regressions/par_maxval.cpp	(revision 0)
@@ -0,0 +1,91 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/regressions/par_maxval.cpp
+    @author  Jules Bergmann
+    @date    2006-01-29
+    @brief   VSIPL++ Library: Test Maxval of distributed expression.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <algorithm>
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/parallel.hpp>
+
+#include <vsip_csl/test.hpp>
+
+#include "test_common.hpp"
+
+using namespace std;
+using namespace vsip;
+using vsip_csl::equal;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+
+template <typename MapT>
+void
+test_maxval()
+{
+  typedef float T;
+  typedef Dense<1, T, row1_type, MapT> block_type;
+  typedef Vector<T, block_type > view_type;
+
+  MapT map;
+
+  length_type size = 16;
+  view_type   view(size, map);
+  Index<1>    idx;
+  int         k = 1;
+  T           maxv;
+
+  setup(view, 1);
+
+  maxv = maxval(view, idx);
+
+  test_assert(equal(maxv, T((size-1)*k)));
+  test_assert(idx[0] == (size-1));
+
+
+  maxv = maxval(magsq(view), idx);
+
+  test_assert(equal(maxv, sq(T((size-1)*k))));
+  test_assert(idx[0] == (size-1));
+}
+
+
+
+
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_maxval<Local_map>();
+  test_maxval<Map<> >();
+  test_maxval<Global_map<1> >();
+
+  return 0;
+}
Index: tests/fir.cpp
===================================================================
--- tests/fir.cpp	(revision 161463)
+++ tests/fir.cpp	(working copy)
@@ -152,24 +152,13 @@
   vsip::Vector<T>  result(output1(vsip::Domain<1>(got)));
 
   test_assert(outsize - got <= 1);
-  if (got > 256)
-  {
-    double error = error_db(result, reference);
-    test_assert(error < -100);
-  }
-  else
-    test_assert(view_equal(result, reference));
+  double error = error_db(result, reference);
+  test_assert(error < -100);
 
   test_assert(got1b == got2);
-  if (got > 256)
-  {
-    double error = error_db(output2(vsip::Domain<1>(got1b)),
-                            output3(vsip::Domain<1>(got1b)));
-    test_assert(error < -100);
-  }
-  else
-    test_assert(view_equal(output2(vsip::Domain<1>(got1b)),
-                      output3(vsip::Domain<1>(got1b))));
+  error = error_db(output2(vsip::Domain<1>(got1b)),
+		   output3(vsip::Domain<1>(got1b)));
+  test_assert(error < -100);
 }
   
 int
Index: tests/extdata_dist.cpp
===================================================================
--- tests/extdata_dist.cpp	(revision 161463)
+++ tests/extdata_dist.cpp	(working copy)
@@ -14,6 +14,8 @@
   Included Files
 ***********************************************************************/
 
+#include <iostream>
+
 #include <vsip/vector.hpp>
 #include <vsip/core/extdata_dist.hpp>
 #include <vsip/initfin.hpp>
@@ -44,6 +46,8 @@
 using vsip::impl::As_type;
 using vsip::impl::Scalar_of;
 using vsip::impl::Aligned_allocator;
+using vsip::impl::Is_local_map;
+using vsip::impl::Is_complex;
 
 
 
@@ -89,7 +93,7 @@
   typename storage_type::type buffer = storage_type::allocate(alloc, size);
 
   {
-    impl::Ext_data_dist<block_type, use_LP> raw(block, SYNC_INOUT, buffer);
+    impl::Ext_data_dist<block_type, SYNC_INOUT, use_LP> raw(block, buffer);
 
     assert(raw.cost() == expect_cost);
 
@@ -117,8 +121,32 @@
 
 
 
+// Determine expected cost for Ext_data_dist.
+
 template <typename T,
+	  typename MapT,
 	  typename OrderT,
+	  typename use_LP,
+	  typename GivenLP>
+int expected_cost()
+{
+  bool is_local_equiv = Is_local_map<MapT>::value ||
+                        Type_equal<MapT, Global_map<1> >::value;
+
+  bool same_order = Type_equal<OrderT, typename use_LP::order_type>::value;
+
+  bool same_complex_fmt = 
+	(!Is_complex<T>::value ||
+	 Type_equal<typename GivenLP::complex_type,
+	            typename use_LP::complex_type>::value);
+
+  return (is_local_equiv && same_order && same_complex_fmt) ? 0 : 2;
+}
+
+
+
+template <typename T,
+	  typename OrderT,
 	  typename MapT,
 	  typename ReqLP>
 void
@@ -156,18 +184,10 @@
   typename storage_type::type buffer = storage_type::allocate(alloc, size);
 
   {
-    impl::Ext_data_dist<block_type, use_LP> raw(block, SYNC_INOUT, buffer);
+    impl::Ext_data_dist<block_type, SYNC_INOUT, use_LP> raw(block, buffer);
 
-    if (Type_equal<OrderT, typename use_LP::order_type>::value &&
-	Type_equal<typename GivenLP::complex_type,
-	           typename use_LP::complex_type>::value)
-    {
-      assert(raw.cost() == 0);
-    }
-    else
-    {
-      assert(raw.cost() == 2);
-    }
+    int exp_cost = expected_cost<T, MapT, OrderT, use_LP, GivenLP>();
+    assert(raw.cost() == exp_cost);
 
     // Check properties of DDI.
     test_assert(raw.stride(0) == 1);
@@ -231,18 +251,10 @@
 
   {
     block_type const& ref = block;
-    impl::Ext_data_dist<block_type, use_LP> raw(ref, SYNC_IN, buffer);
+    impl::Ext_data_dist<block_type, SYNC_IN, use_LP> raw(ref, buffer);
 
-    if (Type_equal<OrderT, typename use_LP::order_type>::value &&
-	Type_equal<typename GivenLP::complex_type,
-	           typename use_LP::complex_type>::value)
-    {
-      assert(raw.cost() == 0);
-    }
-    else
-    {
-      assert(raw.cost() == 2);
-    }
+    int exp_cost = expected_cost<T, MapT, OrderT, use_LP, GivenLP>();
+    assert(raw.cost() == exp_cost);
 
     // Check properties of DDI.
     test_assert(raw.stride(0) == 1);
@@ -260,7 +272,159 @@
 
 
 
+// Helper function to test Ext_data_dist access to an expression block.
+// Deduces type of expression block.
+//
+
+template <typename T,
+	  typename OrderT,
+	  typename MapT,
+	  typename ReqLP,
+	  typename ViewT>
 void
+test_1_expr_helper(ViewT view, T val0, T val1, bool alloc_buffer)
+{
+  typedef typename ViewT::block_type block_type;
+  typedef typename ViewT::value_type value_type;
+
+  typedef typename Block_layout<block_type>::layout_type GivenLP;
+
+  typedef typename Adjust_layout<value_type, ReqLP, GivenLP>::type use_LP;
+  typedef impl::Storage< typename use_LP::complex_type, T> storage_type;
+
+  typedef typename
+      ITE_Type<Type_equal<typename use_LP::complex_type,
+                          Cmplx_inter_fmt>::value,
+               As_type<Aligned_allocator<T> >,
+               As_type<Aligned_allocator<typename Scalar_of<T>::type> > >
+      ::type alloc_type;
+
+  length_type size = view.size();
+
+  alloc_type alloc;
+  typedef typename storage_type::type ptr_type;
+  ptr_type buffer = alloc_buffer ? storage_type::allocate(alloc, size)
+                                 : ptr_type();
+
+  {
+    impl::Ext_data_dist<block_type, SYNC_IN, use_LP> raw(view.block(), buffer);
+
+    // Because block is an expression block, access requires a copy.
+    assert(raw.cost() == 2);
+
+    // Check properties of DDI.
+    test_assert(raw.stride(0) == 1);
+    test_assert(raw.size(0) == size);
+
+    typename storage_type::type data = raw.data();
+
+    // Check that block values are reflected.
+    test_assert(equal(storage_type::get(data, 0), val0));
+    test_assert(equal(storage_type::get(data, 1), val1));
+  }
+
+  if (alloc_buffer) storage_type::deallocate(alloc, buffer, size);
+}
+
+
+
+// Test Ext_data_dist access to a simple expression block.
+// (vector + vector).
+
+template <typename T,
+	  typename OrderT,
+	  typename MapT,
+	  typename ReqLP>
+void
+test_1_expr_1(MapT const& map)
+{
+  typedef Dense<1, T, OrderT, MapT> block_type;
+
+  length_type const size = 10;
+
+  T val0 =  1.0f;
+  T val1 =  2.78f;
+
+  Vector<T, block_type> view1(size, T(), map);
+  Vector<T, block_type> view2(size, T(), map);
+
+  // Place values in block.
+  view1.put(0, val0);
+  view2.put(1, val1);
+
+  test_1_expr_helper<T, OrderT, MapT, ReqLP>(view1 + view2, val0, val1,
+					     true);
+  test_1_expr_helper<T, OrderT, MapT, ReqLP>(view1 + view2, val0, val1,
+					     false);
+}
+
+
+
+// Test Ext_data_dist access to a more complex expression block.
+// (vector + vector)(subset).
+
+template <typename T,
+	  typename OrderT,
+	  typename MapT,
+	  typename ReqLP>
+void
+test_1_expr_2(MapT const& map)
+{
+  typedef Dense<1, T, OrderT, MapT> block_type;
+
+  length_type const size = 10;
+
+  T val0 =  1.0f;
+  T val1 =  2.78f;
+
+  Vector<T, block_type> view1(size, T(), map);
+  Vector<T, block_type> view2(size, T(), map);
+
+  // Place values in block.
+  view1.put(0, val0);
+  view2.put(1, val1);
+
+  test_1_expr_helper<T, OrderT, MapT, ReqLP>((view1 + view2)(Domain<1>(8)),
+					     val0, val1, true);
+  test_1_expr_helper<T, OrderT, MapT, ReqLP>((view1 + view2)(Domain<1>(8)),
+					     val0, val1, false);
+}
+
+
+
+// Test Ext_data_dist access to an 'magsq(v)' expression block.
+
+template <typename T,
+	  typename OrderT,
+	  typename MapT,
+	  typename ReqLP>
+void
+test_1_expr_3(MapT const& map)
+{
+  typedef Dense<1, T, OrderT, MapT> block_type;
+
+  length_type const size = 10;
+
+  T val0 =  1.0f;
+  T val1 =  2.78f;
+
+  Vector<T, block_type> view(size, T(), map);
+
+  // Place values in block.
+  view.put(0, val0);
+  view.put(1, val1);
+
+  typedef typename impl::Scalar_of<T>::type scalar_type;
+
+  test_1_expr_helper<scalar_type, OrderT, MapT, ReqLP>(
+		magsq(view), magsq(val0), magsq(val1), true);
+  test_1_expr_helper<scalar_type, OrderT, MapT, ReqLP>(
+		magsq(view), magsq(val0), magsq(val1), false);
+}
+
+
+
+void
 test()
 {
   typedef Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP_1rdi;
@@ -279,6 +443,21 @@
   test_1_ext<complex<float>, Local_map, LP_1rdi, LP_1xxs >(2);
   test_1_ext<complex<float>, Local_map, LP_1rds, LP_1xxs >(0);
 
+  Local_map lmap;
+
+  test_1_expr_1<float,          row1_type, Local_map, LP_1xxi >(lmap);
+  test_1_expr_1<complex<float>, row1_type, Local_map, LP_1xxi >(lmap);
+  test_1_expr_1<complex<float>, row1_type, Local_map, LP_1xxs >(lmap);
+
+  test_1_expr_2<float,          row1_type, Local_map, LP_1xxi >(lmap);
+  test_1_expr_2<complex<float>, row1_type, Local_map, LP_1xxi >(lmap);
+  test_1_expr_2<complex<float>, row1_type, Local_map, LP_1xxs >(lmap);
+
+  test_1_expr_3<float,          row1_type, Local_map, LP_1xxi >(lmap);
+  test_1_expr_3<complex<float>, row1_type, Local_map, LP_1xxi >(lmap);
+  test_1_expr_3<complex<float>, row1_type, Local_map, LP_1xxs >(lmap);
+
+
   Global_map<1> gmap;
 
   test_1_dense<float,          row1_type, Global_map<1>, LP_1xxi >(gmap);
@@ -291,6 +470,19 @@
   test_1_dense_const<complex<float>, row1_type, Global_map<1>, LP_1xxi >(gmap);
   test_1_dense_const<complex<float>, row1_type, Global_map<1>, LP_1xxs >(gmap);
 
+  test_1_expr_1<float,          row1_type, Global_map<1>, LP_1xxi >(gmap);
+  test_1_expr_1<complex<float>, row1_type, Global_map<1>, LP_1xxi >(gmap);
+  test_1_expr_1<complex<float>, row1_type, Global_map<1>, LP_1xxs >(gmap);
+
+  test_1_expr_2<float,          row1_type, Global_map<1>, LP_1xxi >(gmap);
+  test_1_expr_2<complex<float>, row1_type, Global_map<1>, LP_1xxi >(gmap);
+  test_1_expr_2<complex<float>, row1_type, Global_map<1>, LP_1xxs >(gmap);
+
+  test_1_expr_3<float,          row1_type, Global_map<1>, LP_1xxi >(gmap);
+  test_1_expr_3<complex<float>, row1_type, Global_map<1>, LP_1xxi >(gmap);
+  test_1_expr_3<complex<float>, row1_type, Global_map<1>, LP_1xxs >(gmap);
+
+
   Map<Block_dist> map(num_processors());
 
   test_1_dense<float,          row1_type, Map<Block_dist>, LP_1xxi >(map);
@@ -302,9 +494,22 @@
   test_1_dense_const<float,          row1_type, Map<Block_dist>, LP_1xxs>(map);
   test_1_dense_const<complex<float>, row1_type, Map<Block_dist>, LP_1xxi>(map);
   test_1_dense_const<complex<float>, row1_type, Map<Block_dist>, LP_1xxs>(map);
+
+  test_1_expr_1<float,          row1_type, Map<Block_dist>, LP_1xxi >(map);
+  test_1_expr_1<complex<float>, row1_type, Map<Block_dist>, LP_1xxi >(map);
+  test_1_expr_1<complex<float>, row1_type, Map<Block_dist>, LP_1xxs >(map);
+
+  test_1_expr_2<float,          row1_type, Map<Block_dist>, LP_1xxi >(map);
+  test_1_expr_2<complex<float>, row1_type, Map<Block_dist>, LP_1xxi >(map);
+  test_1_expr_2<complex<float>, row1_type, Map<Block_dist>, LP_1xxs >(map);
+
+  test_1_expr_3<float,          row1_type, Map<Block_dist>, LP_1xxi >(map);
+  test_1_expr_3<complex<float>, row1_type, Map<Block_dist>, LP_1xxi >(map);
+  test_1_expr_3<complex<float>, row1_type, Map<Block_dist>, LP_1xxs >(map);
 }
 
 
+
 int
 main(int argc, char** argv)
 {
Index: tests/reductions.cpp
===================================================================
--- tests/reductions.cpp	(revision 161463)
+++ tests/reductions.cpp	(working copy)
@@ -158,6 +158,7 @@
   test_sumval<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
 
   test_sumval<Storage<1, T, row1_type, Map<Block_dist> > >(Domain<1>(15), 8);
+  test_sumval<Storage<1, T, row1_type, Global_map<1> > >(Domain<1>(15), 8);
 }
 
 
@@ -233,6 +234,7 @@
   test_sumval_bool<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
 
   test_sumval_bool<Storage<1, T, row1_type, Map<Block_dist> > >(Domain<1>(15), 8);
+  test_sumval_bool<Storage<1, T, row1_type, Global_map<1> > >(Domain<1>(15), 8);
 }
 
 
@@ -291,6 +293,7 @@
   test_sumsqval<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
 
   test_sumsqval<Storage<1, T, row1_type, Map<Block_dist> > >(Domain<1>(15), 8);
+  test_sumsqval<Storage<1, T, row1_type, Global_map<1> > >(Domain<1>(15), 8);
 }
 
 
@@ -348,6 +351,7 @@
   test_meanval<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
 
   test_meanval<Storage<1, T, row1_type, Map<Block_dist> > >(Domain<1>(15), 8);
+  test_meanval<Storage<1, T, row1_type, Global_map<1> > >(Domain<1>(15), 8);
 }
 
 
@@ -406,6 +410,7 @@
   test_meansqval<Storage<3, T, tuple<2, 1, 0> > >(Domain<3>(15, 17, 7), 8);
 
   test_meansqval<Storage<1, T, row1_type, Map<Block_dist> > >(Domain<1>(15), 8);
+  test_meansqval<Storage<1, T, row1_type, Global_map<1> > >(Domain<1>(15), 8);
 }
 
 
Index: tests/convolution.cpp
===================================================================
--- tests/convolution.cpp	(revision 161463)
+++ tests/convolution.cpp	(working copy)
@@ -21,6 +21,7 @@
 #include <vsip/initfin.hpp>
 #include <vsip/random.hpp>
 #include <vsip/parallel.hpp>
+#include <vsip/core/metaprogramming.hpp>
 
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/ref_conv.hpp>
@@ -35,8 +36,10 @@
 using namespace vsip;
 using namespace vsip_csl;
 
+double const ERROR_THRESH = -70;
 
 
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -137,6 +140,7 @@
 
   Vector<T> in(N);
   Vector<T> out(P, T(100));
+  Vector<T> exp(P, T(201));
 
   for (index_type i=0; i<N; ++i)
     in(i) = T(i);
@@ -157,8 +161,20 @@
     else
       val2 = in(i + shift - c2);
 
-    test_assert(equal(out(i), T(k1) * val1 + T(k2) * val2));
+    exp.put(i, T(k1) * val1 + T(k2) * val2);
   }
+
+  double error = error_db(out, exp);
+#if VERBOSE
+  std::cout << "error-nonsym: " << error
+	    << "  M/N/P " << M << "/" << N << "/" << P
+	    << (support == vsip::support_full  ? " full"  :
+		support == vsip::support_same  ? " same"  :
+		support == vsip::support_min   ? " min"   :
+		                                 " *unknown*" )
+	    << std::endl;
+#endif
+  test_assert(error < ERROR_THRESH);
 }
 
 
@@ -179,6 +195,10 @@
   length_type              D,		// decimation
   length_type const        n_loop = 2)
 {
+  using vsip::impl::ITE_Type;
+  using vsip::impl::Is_global_map;
+  using vsip::impl::As_type;
+
   typedef Convolution<const_Vector, symmetry, support, T> conv_type;
 
   length_type M = expected_kernel_size(symmetry, coeff.size());
@@ -199,8 +219,18 @@
   test_assert(conv.input_size().size()   == N);
   test_assert(conv.output_size().size()  == P);
 
-  Vector<T> exp(P);
+  // Determine type of map to use for expected result.
+  // If 'out's map is global, make it global_map.
+  // Otherwise, make it a local_map.
+  typedef typename
+          ITE_Type<Is_global_map<typename Block2::map_type>::value,
+                   As_type<Global_map<1> >,
+                   As_type<Local_map> >::type
+          map_type;
+  typedef Dense<1, T, row1_type, map_type> block_type;
 
+  Vector<T, block_type> exp(P);
+
   for (index_type loop=0; loop<n_loop; ++loop)
   {
     for (index_type i=0; i<N; ++i)
@@ -211,10 +241,24 @@
     ref::conv(symmetry, support, coeff, in, exp, D);
 
     // Check result
-    double error = error_db(out, exp);
+    Index<1> idx;
+    double error   = error_db(out, exp);
+    double maxdiff = maxval(magsq(out - exp), idx);
 
 #if VERBOSE
-    if (error > -120)
+    std::cout << "error: " << error
+	      << "  M/N/P " << M << "/" << N << "/" << P
+	      << (symmetry == vsip::sym_even_len_odd  ? " odd"  :
+	          symmetry == vsip::sym_even_len_even ? " even" :
+	          symmetry == vsip::nonsym            ? " nonsym" :
+		                                        " *unknown*" )
+	      << (support == vsip::support_full  ? " full"  :
+	          support == vsip::support_same  ? " same"  :
+	          support == vsip::support_min   ? " min"   :
+		                                   " *unknown*" )
+	      << std::endl;
+
+    if (error > ERROR_THRESH)
     {
       cout << "exp = \n" << exp;
       cout << "out = \n" << out;
@@ -222,7 +266,7 @@
     }
 #endif
 
-    test_assert(error < -120);
+    test_assert(error < ERROR_THRESH || maxdiff < 1e-4);
   }
 }
 
@@ -445,6 +489,8 @@
   cases_conv<T, nonsym>(5, 4, 3, rand);
   cases_conv<T, nonsym>(5, 4, 4, rand);
 
+  cases_nonsym<T>(100);
+
   for (length_type size=32; size<=1024; size *= 4)
   {
     cases_nonsym<T>(size);
@@ -504,14 +550,14 @@
   cases<float>(rand);
   // cases<complex<int> >(rand);
   cases<complex<float> >(rand);
-#if VSIP_IMPL_TEST_DOUBLE
+#  if VSIP_IMPL_TEST_DOUBLE
   cases<double>(rand);
   cases<complex<double> >(rand);
+#  endif
+
 #endif
-
   // Test distributed arguments.
   cases_conv_dist<float>(32, 8, 1);
-#endif
 
   return 0;
 }
Index: tests/ref-impl/fft-coverage.cpp
===================================================================
--- tests/ref-impl/fft-coverage.cpp	(revision 161463)
+++ tests/ref-impl/fft-coverage.cpp	(working copy)
@@ -263,7 +263,7 @@
 
 
 
-// test_1d_cc -- Test single, 1-dimensional, real-to-complex and
+// test_1d_rc -- Test single, 1-dimensional, real-to-complex and
 //               complex-to-real FFTs.
 
 // Template Parameters:
Index: tests/ref-impl/signal-fir.cpp
===================================================================
--- tests/ref-impl/signal-fir.cpp	(revision 161463)
+++ tests/ref-impl/signal-fir.cpp	(working copy)
@@ -145,11 +145,11 @@
 
   /* Test assignment operator and copy constructor.  */
 
-  vsip::Fir<> 	fir2 (fir1);
-  out_length = fir2 (input0, output0);
-  insist (checkVector (out_length, output0, answer2));
   try
   {
+    vsip::Fir<> 	fir2 (fir1);
+    out_length = fir2 (input0, output0);
+    insist (checkVector (out_length, output0, answer2));
     fir2 = fir0;
     out_length = fir2 (input0, output0);
     insist (checkVector (out_length, output0, answer0));
