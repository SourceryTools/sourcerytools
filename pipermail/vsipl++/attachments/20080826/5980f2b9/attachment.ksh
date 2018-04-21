Index: ChangeLog
===================================================================
--- ChangeLog	(revision 218804)
+++ ChangeLog	(working copy)
@@ -1,5 +1,9 @@
 2008-08-26  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/ukernel.hpp: Make 64-bit clean.
+
+2008-08-26  Jules Bergmann  <jules@codesourcery.com>
+
 	* tests/coverage_binary_mul.cpp: Remove file, split into ...
 	* tests/coverage_binary_mul_vi.cpp: New file, ... vector/int cases.
 	* tests/coverage_binary_mul_vf.cpp: New file, ... vector/float cases.
Index: src/vsip/opt/ukernel.hpp
===================================================================
--- src/vsip/opt/ukernel.hpp	(revision 218695)
+++ src/vsip/opt/ukernel.hpp	(working copy)
@@ -417,16 +417,16 @@
 int
 find_align_shift(T* addr)
 {
-  return ((unsigned)(addr) % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(T);
+  return ((uintptr_t)(addr) % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(T);
 }
 
 template <typename T>
 int
 find_align_shift(std::pair<T*, T*> const& addr)
 {
-  assert( ((unsigned)(addr.first)  % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(T) ==
-	  ((unsigned)(addr.second) % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(T));
-  return ((unsigned)(addr.first) % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(T);
+  assert(((uintptr_t)(addr.first)  % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(T) ==
+	 ((uintptr_t)(addr.second) % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(T));
+  return ((uintptr_t)(addr.first) % VSIP_IMPL_DMA_SIZE_QUANTUM) / sizeof(T);
 }
 
 
