Index: ChangeLog
===================================================================
--- ChangeLog	(revision 158485)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2006-12-23  Don McCoy  <don@codesourcery.com>
 
+	* tests/us-block.cpp: Corrected header file location.
+	* tests/view_cast.cpp: Likewise.
+
+2006-12-23  Don McCoy  <don@codesourcery.com>
+
 	Updated copyright notices in the following files:
 	* src/vsip/core/reductions/types.hpp
 	* src/vsip/core/*
Index: tests/us-block.cpp
===================================================================
--- tests/us-block.cpp	(revision 158485)
+++ tests/us-block.cpp	(working copy)
@@ -17,7 +17,7 @@
 #include <iostream>
 #include <cassert>
 #include <vsip/support.hpp>
-#include <vsip/opt/us_block.hpp>
+#include <vsip/core/us_block.hpp>
 #include <vsip/core/length.hpp>
 #include <vsip/core/domain_utils.hpp>
 
Index: tests/view_cast.cpp
===================================================================
--- tests/view_cast.cpp	(revision 158485)
+++ tests/view_cast.cpp	(working copy)
@@ -19,7 +19,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/random.hpp>
 #include <vsip/selgen.hpp>
-#include <vsip/opt/view_cast.hpp>
+#include <vsip/core/view_cast.hpp>
 
 #include <vsip_csl/test.hpp>
 
