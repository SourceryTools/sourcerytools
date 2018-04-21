Index: ChangeLog
===================================================================
--- ChangeLog	(revision 157171)
+++ ChangeLog	(working copy)
@@ -1,5 +1,11 @@
 2006-12-11  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/vector.hpp: Assert index is valid for get/put.
+	* src/vsip/matrix.hpp: Likewise.
+	* src/vsip/tensor.hpp: Likewise.
+	
+2006-12-11  Jules Bergmann  <jules@codesourcery.com>
+
 	C-VSIP reduction BE.
 	* src/vsip/core/cvsip/eval_reductions.hpp: New file.  Evaluators for
 	  performing reductions with C-VSIP.
Index: src/vsip/vector.hpp
===================================================================
--- src/vsip/vector.hpp	(revision 156837)
+++ src/vsip/vector.hpp	(working copy)
@@ -88,7 +88,10 @@
 
   // [view.vector.valaccess]
   value_type get(index_type i) const VSIP_NOTHROW
-    { return this->block().get(i); }
+  {
+    assert(i < this->size(0));
+    return this->block().get(i);
+  }
 
   // Supported for some, but not all, underlying Blocks.
   const_reference_type operator()(index_type i) const VSIP_NOTHROW
@@ -207,7 +210,10 @@
 
   // [view.vector.valaccess]
   void put(index_type i, value_type val) const VSIP_NOTHROW
-  { this->block().put(i, val); }
+  {
+    assert(i < this->size(0));
+    this->block().put(i, val);
+  }
 
   reference_type operator()(index_type i) VSIP_NOTHROW
   { impl_factory_type f(this->block()); return f.impl_ref(i); }
Index: src/vsip/matrix.hpp
===================================================================
--- src/vsip/matrix.hpp	(revision 156850)
+++ src/vsip/matrix.hpp	(working copy)
@@ -99,7 +99,11 @@
 
   // [view.matrix.valaccess]
   value_type get(vsip::index_type r, vsip::index_type c) const VSIP_NOTHROW
-  { return this->block().get(r, c); }
+  {
+    assert(r < this->size(0));
+    assert(c < this->size(1));
+    return this->block().get(r, c);
+  }
 
   // Supported for some, but not all, underlying Blocks.
   const_reference_type operator()(vsip::index_type r, vsip::index_type c)
@@ -132,11 +136,13 @@
 
   const_col_type col(vsip::index_type i) const VSIP_THROW((std::bad_alloc))
   {
+    assert(i < this->size(1));
     impl_coblock_type block(this->block(), i);
     return const_col_type(block);
   }
   const_row_type row(vsip::index_type i) const VSIP_THROW((std::bad_alloc))
   {
+    assert(i < this->size(0));
     impl_roblock_type block(this->block(), i);
     return const_row_type(block);
   }
@@ -207,7 +213,11 @@
 
   // [view.matrix.valaccess]
   void put(vsip::index_type r, vsip::index_type c, value_type val) const VSIP_NOTHROW
-  { this->block().put(r, c, val);}
+  {
+    assert(r < this->size(0));
+    assert(c < this->size(1));
+    this->block().put(r, c, val);
+  }
 
   reference_type operator()(vsip::index_type r, vsip::index_type c) VSIP_NOTHROW
   { impl_factory_type f(this->block()); return f.impl_ref(r, c); }
@@ -265,6 +275,7 @@
   { return impl_base_type::col(i); } 
   col_type col(vsip::index_type i) VSIP_THROW((std::bad_alloc))
   {
+    assert(i < this->size(1));
     impl_coblock_type block(this->block(), i);
     return col_type(block);
   }
@@ -273,6 +284,7 @@
   { return impl_base_type::row(i); } 
   row_type row(vsip::index_type i) VSIP_THROW((std::bad_alloc))
   {
+    assert(i < this->size(0));
     impl_roblock_type block(this->block(), i);
     return row_type(block);
   }
Index: src/vsip/tensor.hpp
===================================================================
--- src/vsip/tensor.hpp	(revision 156744)
+++ src/vsip/tensor.hpp	(working copy)
@@ -137,7 +137,12 @@
 
   // [view.tensor.valaccess]
   value_type get(index_type i, index_type j, index_type k) const VSIP_NOTHROW
-  { return this->block().get(i, j, k);}
+  {
+    assert(i < this->size(0));
+    assert(j < this->size(1));
+    assert(k < this->size(2));
+    return this->block().get(i, j, k);
+  }
 
   // Supported for some, but not all, underlying Blocks.
   const_reference_type operator()(index_type i, index_type j, index_type k)
@@ -364,7 +369,12 @@
 	   index_type j,
 	   index_type k,
 	   value_type val) const VSIP_NOTHROW
-  { this->block().put(i, j, k, val);}
+  {
+    assert(i < this->size(0));
+    assert(j < this->size(1));
+    assert(k < this->size(2));
+    this->block().put(i, j, k, val);
+  }
 
   reference_type operator()(index_type i,
                             index_type j,
