Index: ChangeLog
===================================================================
--- ChangeLog	(revision 156637)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2006-12-05  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/core/parallel/expr.hpp: Add missing size(dim, d)
+	  accessor.
+	
+2006-12-05  Jules Bergmann  <jules@codesourcery.com>
+
 	Fix issue #125.
 	* src/vsip/core/expr/binary_block.hpp: Add asserts at block
 	  create that lhs and rhs are same size.
Index: src/vsip/core/parallel/expr.hpp
===================================================================
--- src/vsip/core/parallel/expr.hpp	(revision 156170)
+++ src/vsip/core/parallel/expr.hpp	(working copy)
@@ -99,6 +99,8 @@
   // Accessors.
 public:
   length_type size() const VSIP_NOTHROW { return src_.block().size(); }
+  length_type size(dimension_type blk_dim, dimension_type d) const VSIP_NOTHROW
+  { return src_.block().size(blk_dim, d); }
 
   void increment_count() const VSIP_NOTHROW {}
   void decrement_count() const VSIP_NOTHROW {}
@@ -158,6 +160,8 @@
   // Accessors.
 public:
   length_type size() const VSIP_NOTHROW { return blk_.size(); }
+  length_type size(dimension_type blk_dim, dimension_type d) const VSIP_NOTHROW
+  { return blk_.size(blk_dim, d); }
 
   void increment_count() const VSIP_NOTHROW {}
   void decrement_count() const VSIP_NOTHROW {}
