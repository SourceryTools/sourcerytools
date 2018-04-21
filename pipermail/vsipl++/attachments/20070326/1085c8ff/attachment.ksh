Index: ChangeLog
===================================================================
--- ChangeLog	(revision 166903)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2007-03-26  Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/regressions/vector_headers.cpp: New file, regression
+	  test for headers required to use a vector.
+
 2007-03-23  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/opt/cbe/ppu/fastconv.cpp: Changed kernel stack 
Index: tests/regressions/vector_headers.cpp
===================================================================
--- tests/regressions/vector_headers.cpp	(revision 0)
+++ tests/regressions/vector_headers.cpp	(revision 0)
@@ -0,0 +1,41 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/vector_header.cpp
+    @author  Jules Bergmann
+    @date    2007-03-26
+    @brief   VSIPL++ Library: Test that vector.hpp header is sufficient
+                              to use a Vector.
+
+    This is requires that Local_or_global_map be defined.  However,
+    global_map.hpp (and map.hpp) cannot be included until after the
+    definitions for Vector are made.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+   vsip::vsipl(argc, argv);
+
+   vsip::Vector<float> foo(10, 3.f);
+   vsip::Vector<float> bar(10, 4.f);
+
+   bar *= foo;
+}
