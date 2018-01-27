Index: ChangeLog
===================================================================
--- ChangeLog	(revision 218237)
+++ ChangeLog	(working copy)
@@ -1,3 +1,7 @@
+2008-08-21  Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/fft_be.cpp: Add XFails for cbe double FFTMs.
+
 2008-08-20  Mike LeBlanc  <mike@codesourcery.com>
 
 	* doc/manual/datatypes.xml: Insert a section about enumeration
Index: tests/fft_be.cpp
===================================================================
--- tests/fft_be.cpp	(revision 217743)
+++ tests/fft_be.cpp	(working copy)
@@ -311,6 +311,22 @@
 template <typename F, return_mechanism_type R, typename O, unsigned int S>
 struct XFail<cbe, F, 1, R, complex<double>, O, S> { static bool const value = true;};
 
+// Expected failures for Fftm
+template <typename ImplTag,	// ImplTag
+	  typename CmplxFmt,	// complex format (Cmplx_{inter,spilt>_fmt
+	  return_mechanism_type R,
+          typename I,		// Input type
+	  typename O,		// output type
+	  unsigned int fft_dir> // Fft direction
+struct XFailM
+{ static bool const value = false;};
+
+// CBE doesn't support double FFTMs
+template <typename F, return_mechanism_type R, typename O, unsigned int S>
+struct XFailM<cbe, F, R, double, O, S> { static bool const value = true;};
+template <typename F, return_mechanism_type R, typename O, unsigned int S>
+struct XFailM<cbe, F, R, complex<double>, O, S> { static bool const value = true;};
+
 bool has_errors = false;
 
 template <typename T, typename B, dimension_type D>
@@ -452,10 +468,17 @@
 
   if (error_db(output, ref) > -100)
   {
-    std::cout << "error." << std::endl;
-    has_errors = true;
+    if (XFailM<B, typename T::o_format, r, I, O, T::direction>::value)
+    {
+      std::cout << "expected error." << std::endl;
+    }
+    else
+    {
+      std::cout << "error." << std::endl;
+      has_errors = true;
 //     std::cout << "out " << output << std::endl;
 //     std::cout << "ref  " << ref << std::endl;
+    }
   }
   else std::cout << "ok." << std::endl;
 }
@@ -487,10 +510,15 @@
 
   if (error_db(data, ref) > -100)
   {
-    std::cout << "error." << std::endl;
-    has_errors = true;
+    if (XFailM<B, F, r, CT, CT, d>::value)
+      std::cout << "expected error." << std::endl;
+    else
+    {
+      std::cout << "error." << std::endl;
+      has_errors = true;
 //     std::cout << "data " << data << std::endl;
 //     std::cout << "ref  " << ref << std::endl;
+    }
   }
   else std::cout << "ok." << std::endl;
 }
