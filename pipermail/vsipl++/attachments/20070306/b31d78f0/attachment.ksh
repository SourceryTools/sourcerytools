Index: ChangeLog
===================================================================
--- ChangeLog	(revision 164965)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2007-03-06  Jules Bergmann  <jules@codesourcery.com>
 
+	* benchmarks/alloc_block.hpp: Remove access to private class member,
+	  fix Wall warning.
+	
+2007-03-06  Jules Bergmann  <jules@codesourcery.com>
+
 	* benchmarks/alloc_block.hpp: New file, handles block creation
 	  using either library storage or user-specified storage.
 	
Index: benchmarks/alloc_block.hpp
===================================================================
--- benchmarks/alloc_block.hpp	(revision 164965)
+++ benchmarks/alloc_block.hpp	(working copy)
@@ -62,7 +62,7 @@
     {
       blk = new block_type(dom, (T*)(addr + offset), map);
       blk->admit(false);
-      assert(!blk->is_alloc());
+      // is_alloc is private // assert(!blk->is_alloc());
     }
     return blk;
   }
@@ -95,7 +95,7 @@
       blk->rebind( (T*)(addr + offset) + 0,
 		   (T*)(addr + offset) + dom.size());
       blk->admit(false);
-      assert(!blk->is_alloc());
+      // is_alloc is private // assert(!blk->is_alloc());
     }
     return blk;
   }
@@ -129,7 +129,7 @@
 				(T*)(addr + offset)),
 			map);
       blk->admit(false);
-      assert(!blk->is_alloc());
+      // is_alloc is private // assert(!blk->is_alloc());
     }
     return blk;
   }
@@ -167,7 +167,7 @@
       blk->rebind( (T*)(addr + offset) + 0,
 		   (T*)(addr + offset) + dom.size());
       blk->admit(false);
-      assert(!blk->is_alloc());
+      // is_alloc is private // assert(!blk->is_alloc());
     }
     return blk;
   }
@@ -262,7 +262,7 @@
   }
 
     // Touch each of the large pages.
-    for (unsigned int i=0; i<pages; ++i)
+    for (int i=0; i<pages; ++i)
       mem_addr[i*0x1000000 + 0x0800000] = (char) 0;
 
   return mem_addr;
