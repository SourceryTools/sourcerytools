Index: ChangeLog
===================================================================
--- ChangeLog	(revision 151690)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2006-10-16  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/simd/expr_evaluator.hpp: Update includes for new layout.
+	* src/vsip/opt/simd/expr_iterator.hpp: Likewise.
+	
 2006-10-13  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* configure.ac: Add --enable-pas-heap-size option.
Index: src/vsip/opt/simd/expr_evaluator.hpp
===================================================================
--- src/vsip/opt/simd/expr_evaluator.hpp	(revision 151690)
+++ src/vsip/opt/simd/expr_evaluator.hpp	(working copy)
@@ -15,14 +15,14 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
-#include <vsip/impl/simd/simd.hpp>
-#include <vsip/impl/simd/expr_iterator.hpp>
-#include <vsip/impl/expr_operations.hpp>
-#include <vsip/impl/expr_unary_block.hpp>
-#include <vsip/impl/expr_binary_block.hpp>
-#include <vsip/impl/metaprogramming.hpp>
-#include <vsip/impl/extdata.hpp>
-#include <vsip/impl/expr_serial_evaluator.hpp>
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip/opt/simd/expr_iterator.hpp>
+#include <vsip/core/expr/operations.hpp>
+#include <vsip/core/expr/unary_block.hpp>
+#include <vsip/core/expr/binary_block.hpp>
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/opt/extdata.hpp>
+#include <vsip/opt/expr/serial_evaluator.hpp>
 
 /***********************************************************************
   Definitions
Index: src/vsip/opt/simd/expr_iterator.hpp
===================================================================
--- src/vsip/opt/simd/expr_iterator.hpp	(revision 151690)
+++ src/vsip/opt/simd/expr_iterator.hpp	(working copy)
@@ -15,9 +15,9 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
-#include <vsip/impl/simd/simd.hpp>
-#include <vsip/impl/expr_operations.hpp>
-#include <vsip/impl/metaprogramming.hpp>
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip/core/expr/operations.hpp>
+#include <vsip/core/metaprogramming.hpp>
 
 /***********************************************************************
   Definitions
