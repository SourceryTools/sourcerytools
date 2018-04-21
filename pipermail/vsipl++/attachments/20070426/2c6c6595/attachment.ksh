Index: ChangeLog
===================================================================
--- ChangeLog	(revision 169646)
+++ ChangeLog	(working copy)
@@ -1,3 +1,7 @@
+2007-04-26  Jules Bergmann  <jules@codesourcery.com>
+
+	* benchmarks/vma.cpp: Fix reference to missing header.
+
 2007-04-22  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac: Fix typos with exception option handling.
Index: benchmarks/vma.cpp
===================================================================
--- benchmarks/vma.cpp	(revision 168970)
+++ benchmarks/vma.cpp	(working copy)
@@ -16,14 +16,18 @@
   Included Files
 ***********************************************************************/
 
+#define DO_SIMD 0
+
 #include <iostream>
 
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
-#include <vsip/opt/simd/simd.hpp>
-#include <vsip/opt/simd/vaxpy.hpp>
+#if DO_SIMD
+#  include <vsip/opt/simd/simd.hpp>
+#  include <vsip/opt/simd/vaxpy.hpp>
+#endif
 #include <vsip/opt/diag/eval.hpp>
 
 #include <vsip_csl/test-storage.hpp>
