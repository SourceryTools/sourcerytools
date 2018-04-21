Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 163337)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -16,7 +16,7 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
-#include <vsip/core/aligned_allocator.hpp>
+#include <vsip/core/allocation.hpp>
 #include <vsip/core/fft/backend.hpp>
 #include <vsip/core/fft/util.hpp>
 #include <vsip/opt/cbe/common.h>
@@ -42,14 +42,12 @@
 
 public:
   Fft_base(length_type size) 
-    : twiddle_factors_(alloc_align<ctype>(VSIP_IMPL_ALLOC_ALIGNMENT, size / 4))
+    : twiddle_factors_(size / 4)
   {
     compute_twiddle_factors(size);
   }
   virtual ~Fft_base() 
-  {
-    delete(twiddle_factors_);
-  }
+  {}
 
   void 
   fft(std::complex<T> const* in, std::complex<T>* out, 
@@ -68,7 +66,7 @@
     Workblock block = task.create_block();
     block.set_parameters(fftp);
     block.add_input(in, length);
-    block.add_input(twiddle_factors_, length/4);
+    block.add_input(twiddle_factors_.get(), length/4);
     block.add_output(out, length);
     task.enqueue(block);
     task.wait();
@@ -107,7 +105,7 @@
       Workblock block = task.create_block();
       block.set_parameters(fftp);
       block.add_input(in, fftp.elements);
-      block.add_input(twiddle_factors_, fftp.elements/4);
+      block.add_input(twiddle_factors_.get(), fftp.elements/4);
       block.add_output(out, fftp.elements);
       task.enqueue(block);
       in += in_stride;
@@ -122,7 +120,7 @@
   {
     unsigned int i = 0;
     unsigned int n = length;
-    T* W = reinterpret_cast<T*>(twiddle_factors_);
+    T* W = reinterpret_cast<T*>(twiddle_factors_.get());
     W[0] = 1.0f;
     W[1] = 0.0f;
     for (i = 1; i < n / 4; ++i) 
@@ -133,7 +131,7 @@
   }
 
 private:
-  ctype* twiddle_factors_;
+  aligned_array<ctype> twiddle_factors_;
 };
 
 
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 163337)
+++ ChangeLog	(working copy)
@@ -1,5 +1,9 @@
 2007-02-15  Don McCoy  <don@codesourcery.com>
 
+	* src/vsip/opt/cbe/ppu/fft.cpp: Fixed memory allocation issue.
+
+2007-02-15  Don McCoy  <don@codesourcery.com>
+
 	* src/vsip/core/fft/util.hpp: Moved test for power of two here.
 	* src/vsip/core/fft.hpp: Revised a comment for clarity.
 	* src/vsip/opt/ipp/fft.hpp: Moved power of two test to util.hpp.
