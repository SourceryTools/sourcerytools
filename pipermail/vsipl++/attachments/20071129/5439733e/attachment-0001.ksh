Index: src/vsip/core/temp_buffer.hpp
===================================================================
--- src/vsip/core/temp_buffer.hpp	(revision 185580)
+++ src/vsip/core/temp_buffer.hpp	(working copy)
@@ -63,7 +63,10 @@
   ~Temp_buffer()
     VSIP_NOTHROW
   {
-    if (is_alloc_) delete[] data_;
+    if (is_alloc_) 
+      delete[] data_;
+    else
+      std::return_temporary_buffer(data_);
   }
 
   T* data() const { return data_; }
