Index: ChangeLog
===================================================================
--- ChangeLog	(revision 145195)
+++ ChangeLog	(working copy)
@@ -1,4 +1,13 @@
+2006-07-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/layout.hpp: Throw exception if using get_imag_ptr
+	  on a non-complex pointer.
+	* src/vsip_csl/test.hpp: Use YYYY-MM-DD format for date.  
+	  (test_assert): Qualify namespace for test_assert_fail function.
+	* tests/matlab_bin_file_test.cpp: Fix broken include.
+	
 2006-07-15  Assem Salama <assem@codesourcery.com>
+	
 	* tests/matlab_bin_file_test.cpp: New file. This file tests the low
 	  level Matlab_bin_formatter interface.
 	* src/vsip/tensor.hpp: Added the extent method to operator on a tensor
@@ -7,6 +16,7 @@
 	* src/vsip_csl/matlab_bin_formatter.hpp: Fixed compile error.
 
 2006-07-14  Don McCoy  <don@codesourcery.com>
+	
 	* src/vsip/impl/profile.hpp: Renamed Scope_enable class to Profile.
 	* src/vsip_csl/error_db.hpp:  Moved from tests directory for use
 	  with benchmarking and examples as well.
@@ -54,6 +64,7 @@
 	  without having to explicitly add the new target.
 
 2006-07-11  Assem Salama <assem@codesourcery.com>
+	
 	* src/vsip_csl/matlab.hpp: New file. This file has commonly used types
 	  and structures used in reading in Matlab .mat files.
 	* src/vsip_csl/matlab_bin_formatter.hpp: New file. This file imlements
Index: src/vsip/impl/layout.hpp
===================================================================
--- src/vsip/impl/layout.hpp	(revision 145195)
+++ src/vsip/impl/layout.hpp	(working copy)
@@ -1091,11 +1091,11 @@
   { return ptr + stride; }
 
   static T* get_real_ptr(type ptr)
+    { return ptr; }
+  static T* get_imag_ptr(type /*ptr*/)
     { VSIP_IMPL_THROW(std::runtime_error(
         "Accessing imaginary part of non-complex pointer"));
       return NULL; }
-  static T* get_imag_ptr(type ptr)
-    { return ptr; }
 
 };
 
Index: src/vsip_csl/test.hpp
===================================================================
--- src/vsip_csl/test.hpp	(revision 145195)
+++ src/vsip_csl/test.hpp	(working copy)
@@ -2,7 +2,7 @@
 
 /** @file    vsip_csl/test.hpp
     @author  Jules Bergmann
-    @date    01/25/2005
+    @date    2005-01-25
     @brief   VSIPL++ CodeSourcery Library: Common declarations and 
              definitions for testing.
 */
@@ -264,7 +264,7 @@
 
 #define test_assert(expr)						\
   (static_cast<void>((expr) ? 0 :					\
-		     (test_assert_fail(__TEST_STRING(expr), __FILE__, __LINE__, \
+		     (vsip_csl::test_assert_fail(__TEST_STRING(expr), __FILE__, __LINE__, \
 				       TEST_ASSERT_FUNCTION), 0)))
 
 } // namespace vsip_csl
Index: tests/matlab_bin_file_test.cpp
===================================================================
--- tests/matlab_bin_file_test.cpp	(revision 145195)
+++ tests/matlab_bin_file_test.cpp	(working copy)
@@ -20,7 +20,7 @@
 #include <vsip_csl/matlab_text_formatter.hpp>
 #include <vsip_csl/matlab_bin_formatter.hpp>
 #include <vsip_csl/output.hpp>
-#include <test.hpp>
+#include <vsip_csl/test.hpp>
 
 #define DEBUG 0
 
