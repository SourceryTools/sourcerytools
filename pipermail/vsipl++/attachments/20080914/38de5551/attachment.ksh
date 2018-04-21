Index: ChangeLog
===================================================================
--- ChangeLog	(revision 221242)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2008-09-14  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/subblock.hpp (Permuted_block): Support direct data
+	  interface, so Ext_data doesn't have to copy!
+
 2008-09-13  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/cbe/ppu/alf.cpp: Use cached_alf_task_desc_init to
Index: src/vsip/core/subblock.hpp
===================================================================
--- src/vsip/core/subblock.hpp	(revision 220851)
+++ src/vsip/core/subblock.hpp	(working copy)
@@ -669,7 +669,7 @@
 {
 protected:
   // Policy class.
-  typedef Permutor<Block, Ordering> perm_;
+  typedef Permutor<Block, Ordering> perm_type;
 
 public:
   // Compile-time values and types.
@@ -693,7 +693,7 @@
   length_type size() const VSIP_NOTHROW
     { return blk_->size(); }
   length_type size(dimension_type block_d, dimension_type d) const VSIP_NOTHROW
-    { return blk_->size(block_d, perm_::dimension_order(d)); }
+    { return blk_->size(block_d, perm_type::dimension_order(d)); }
   // These are noops as Transposed_block is held by-value.
   void increment_count() const VSIP_NOTHROW {}
   void decrement_count() const VSIP_NOTHROW {}
@@ -701,14 +701,34 @@
 
   // Data accessors.
   value_type get(index_type i, index_type j, index_type k) const VSIP_NOTHROW
-    { return perm_::get(*blk_, i, j, k); }
+    { return perm_type::get(*blk_, i, j, k); }
 
   void put(index_type i, index_type j, index_type k, value_type val) VSIP_NOTHROW
-    { perm_::put(*blk_, i, j, k, val); }
+    { perm_type::put(*blk_, i, j, k, val); }
 
   reference_type impl_ref(index_type i, index_type j, index_type k) VSIP_NOTHROW
-    { return perm_::impl_ref(*blk_, i, j, k); }
+    { return perm_type::impl_ref(*blk_, i, j, k); }
 
+  // Support Direct_data interface.
+public:
+  typedef impl::Storage<typename Block_layout<Block>::complex_type, value_type>
+		storage_type;
+  typedef typename storage_type::type       data_type;
+  typedef typename storage_type::const_type const_data_type;
+
+  data_type       impl_data()       VSIP_NOTHROW
+  { return blk_->impl_data(); }
+
+  const_data_type impl_data() const VSIP_NOTHROW
+  { return blk_->impl_data(); }
+
+  stride_type impl_stride(dimension_type Dim, dimension_type d)
+     const VSIP_NOTHROW
+  {
+    assert(Dim == dim && d<dim);
+    return blk_->impl_stride(dim,  perm_type::dimension_order(d));
+  }
+
  private:
   // Data members.
   typename View_block_storage<Block>::type blk_;
@@ -776,6 +796,57 @@
 {};
 
 
+// Take permutation of dimension-order.
+template <typename PermutionT,		// Tuple expressing permutation
+	  typename OrderT>		// Original dim-order
+struct Permute_order;
+
+template <dimension_type Dim0, dimension_type Dim1, dimension_type Dim2>
+struct Permute_order<tuple<0, 1, 2>, tuple<Dim0, Dim1, Dim2> >
+{ typedef tuple<Dim0, Dim1, Dim2> type; };
+
+template <dimension_type Dim0, dimension_type Dim1, dimension_type Dim2>
+struct Permute_order<tuple<1, 0, 2>, tuple<Dim0, Dim1, Dim2> >
+{ typedef tuple<Dim1, Dim0, Dim2> type; };
+
+template <dimension_type Dim0, dimension_type Dim1, dimension_type Dim2>
+struct Permute_order<tuple<0, 2, 1>, tuple<Dim0, Dim1, Dim2> >
+{ typedef tuple<Dim0, Dim2, Dim1> type; };
+
+template <dimension_type Dim0, dimension_type Dim1, dimension_type Dim2>
+struct Permute_order<tuple<1, 2, 0>, tuple<Dim0, Dim1, Dim2> >
+{ typedef tuple<Dim1, Dim2, Dim0> type; };
+
+template <dimension_type Dim0, dimension_type Dim1, dimension_type Dim2>
+struct Permute_order<tuple<2, 1, 0>, tuple<Dim0, Dim1, Dim2> >
+{ typedef tuple<Dim2, Dim1, Dim0> type; };
+
+template <dimension_type Dim0, dimension_type Dim1, dimension_type Dim2>
+struct Permute_order<tuple<2, 0, 1>, tuple<Dim0, Dim1, Dim2> >
+{ typedef tuple<Dim2, Dim0, Dim1> type; };
+
+template <typename BlockT, typename PermutionT>
+struct Block_layout<Permuted_block<BlockT, PermutionT> >
+{
+  // Dimension: Same
+  // Access   : Same
+  // Order    : permuted
+  // Stride   : Stride_unknown
+  // Cmplx    : Same
+
+  static dimension_type const dim = BlockT::dim;
+
+  typedef typename Block_layout<BlockT>::access_type  access_type;
+  typedef typename Permute_order<PermutionT, 
+                      typename Block_layout<BlockT>::order_type>::type
+					            order_type;
+  typedef Stride_unknown                             pack_type;
+  typedef typename Block_layout<BlockT>::complex_type complex_type;
+
+  typedef Layout<dim, order_type, pack_type, complex_type> layout_type;
+};
+
+
 template <typename MapT, dimension_type SubDim>
 struct Sliced_block_map {};
 
