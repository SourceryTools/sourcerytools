Index: src/vsip/core/expr/generator_block.hpp
===================================================================
--- src/vsip/core/expr/generator_block.hpp	(revision 168042)
+++ src/vsip/core/expr/generator_block.hpp	(working copy)
@@ -28,6 +28,88 @@
   Declarations
 ***********************************************************************/
 
+template <typename Generator,
+          typename MapT>
+class Distributed_generator_block
+{
+
+public:
+  static dimension_type const dim = Generator::dim;
+  typedef typename Generator::result_type value_type;
+  typedef Local_or_global_map<dim> map_type;
+
+  // Constructors.
+public:
+  Distributed_generator_block(Domain<dim> const& dom, Generator& op,
+                              MapT const& map)
+    : op_(op),
+      dom_(dom),
+      map_(map)
+    {}
+
+
+  // Accessors.
+public:
+  length_type size() const VSIP_NOTHROW
+  { return dom_.size(); }
+
+  length_type size(dimension_type block_dim, dimension_type d)
+    const VSIP_NOTHROW
+  { assert(block_dim == dim); return dom_[d].size(); }
+
+  void increment_count() const VSIP_NOTHROW {}
+  void decrement_count() const VSIP_NOTHROW {}
+  map_type const& map() const VSIP_NOTHROW { return *(new map_type());}
+
+
+  value_type get(index_type i)
+  {
+    index_type global_i;
+
+    assert(i < dom_[0].size());
+    global_i = map_.impl_global_from_local_index(0,map_.subblock(),i);
+    return op_.get(global_i);
+  }
+
+  value_type get(index_type i, index_type j)
+  {
+    index_type global_i, global_j;
+
+    assert(i < dom_[0].size());
+    assert(j < dom_[1].size());
+    global_i = map_.impl_global_from_local_index(0,map_.subblock(),i);
+    global_j = map_.impl_global_from_local_index(1,map_.subblock(),j);
+    return op_.get(global_i,global_j);
+  }
+
+  value_type get(index_type i, index_type j, index_type k)
+  {
+    index_type global_i, global_j, global_k;
+
+    assert(i < dom_[0].size());
+    assert(j < dom_[1].size());
+    assert(k < dom_[2].size());
+    global_i = map_.impl_global_from_local_index(0,map_.subblock(),i);
+    global_j = map_.impl_global_from_local_index(1,map_.subblock(),j);
+    global_k = map_.impl_global_from_local_index(2,map_.subblock(),k);
+    return op_.get(global_i,global_j,global_k);
+  }
+
+  // Member data.
+private:
+  Generator&   op_;
+  Domain<dim>  dom_;
+  MapT const&  map_;
+
+};
+
+// Store Distributed_generator_block by reference
+template <typename Block, typename MapT>
+struct View_block_storage<Distributed_generator_block<Block, MapT> >
+  : By_value_block_storage<Distributed_generator_block<Block, MapT> >
+{};
+
+
 /// Expression template block for Generator expressions.
 ///
 /// Requires:
Index: src/vsip/core/parallel/expr.hpp
===================================================================
--- src/vsip/core/parallel/expr.hpp	(revision 168042)
+++ src/vsip/core/parallel/expr.hpp	(working copy)
@@ -20,6 +20,7 @@
 #include <vsip/core/block_traits.hpp>
 #include <vsip/core/parallel/assign.hpp>
 #include <vsip/core/parallel/choose_assign_impl.hpp>
+#include <vsip/core/expr/generator_block.hpp>
 
 
 
@@ -195,16 +196,16 @@
   typedef MapT                                  map_type;
 
 
-  typedef Subset_block<BlockT const>            local_block_type;
+  typedef Distributed_generator_block<BlockT const, MapT> local_block_type;
   typedef typename View_block_storage<local_block_type>::plain_type
                                                 local_block_ret_type;
 
 public:
   Par_expr_block(MapT const& map, BlockT const& block)
     : map_     (map),
-      dom_     (map_.template impl_global_domain<Dim>(map_.subblock(), 0)),
+      dom_     (map_.template impl_subblock_domain<Dim>(map_.subblock())),
       blk_     (block),
-      subblock_(dom_,blk_)
+      subblock_(dom_,blk_,map_)
   {}
 
   ~Par_expr_block() {}
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 169648)
+++ ChangeLog	(working copy)
@@ -1,3 +1,31 @@
+2007-04-25  Assem Salama <assem@codesourcery.com>
+	* src/vsip/core/parallel/expr.hpp: Changed the Par_expr_block that
+	  is specialized for Peb_reuse_tag to use Distributed_generator_block
+	  instead of Subset_block.
+	* src/vsip/core/expr/generator_block.hpp: Added new class
+	  Distributed_generator_block. This new class works with either a 
+	  Block_dist or Cyclic_dist. It uses global_from_local_index to
+	  retrieve values.
+
