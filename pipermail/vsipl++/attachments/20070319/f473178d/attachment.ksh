Index: ChangeLog
===================================================================
--- ChangeLog	(revision 166198)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2007-03-19  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/layout.hpp: Fix bug in aligned stride computation.
+	* src/vsip/opt/cbe/ppu/fft.cpp: Assert fft and fftm input and output
+	  are DMA aligned.
+	
 2007-03-18  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* src/vsip/GNUmakefile.inc.in: Remove obsolete reference to $(SVPP_LIBRARY)
Index: src/vsip/core/layout.hpp
===================================================================
--- src/vsip/core/layout.hpp	(revision 166187)
+++ src/vsip/core/layout.hpp	(working copy)
@@ -957,7 +957,7 @@
       stride_[order_[0]] = size_[order_[1]];
 
       if (layout.align != 0 &&
-	  (elem_size*stride_[order_[1]]) % layout.align != 0)
+	  (elem_size*stride_[order_[0]]) % layout.align != 0)
 	stride_[order_[0]] +=
 	  (layout.align/elem_size - stride_[order_[0]]%layout.align);
     }
Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 166187)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -21,6 +21,7 @@
 #include <vsip/core/fft/util.hpp>
 #include <vsip/opt/cbe/common.h>
 #include <vsip/opt/cbe/ppu/fft.hpp>
+#include <vsip/opt/cbe/ppu/bindings.hpp>
 #include <vsip/opt/cbe/ppu/task_manager.hpp>
 
 /***********************************************************************
@@ -53,6 +54,9 @@
   fft(std::complex<T> const* in, std::complex<T>* out, 
     length_type length, T scale, int exponent)
   {
+    assert(is_dma_addr_ok(in));
+    assert(is_dma_addr_ok(out));
+
     Fft_params fftp;
     fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
     fftp.elements = length;
@@ -93,6 +97,11 @@
     length_type rows, length_type cols, 
     T scale, int exponent, int axis)
   {
+    assert(is_dma_addr_ok(in));
+    assert(is_dma_addr_ok(out));
+    assert(is_dma_addr_ok(in   + (axis != 0 ? in_r_stride  : in_c_stride)));
+    assert(is_dma_addr_ok(out  + (axis != 0 ? out_r_stride : out_c_stride)));
+
     Fft_params fftp;
     fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
     fftp.scale = scale;
