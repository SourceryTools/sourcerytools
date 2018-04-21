Index: ChangeLog
===================================================================
--- ChangeLog	(revision 217943)
+++ ChangeLog	(working copy)
@@ -1,4 +1,10 @@
 2008-08-19  Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/vsip_csl/matlab_bin_file/matlab_bin_file.cpp: Add missing
+	  library initialization.
+	* tests/vsip_csl/matlab_iterator.cpp: Likewise.
+
+2008-08-19  Jules Bergmann  <jules@codesourcery.com>
 	
 	* src/vsip/core/solver/llsqsol.hpp: Use Qrd_traits to determine
 	  whether skinny or full QR is appropriate.
Index: tests/vsip_csl/matlab_bin_file/matlab_bin_file.cpp
===================================================================
--- tests/vsip_csl/matlab_bin_file/matlab_bin_file.cpp	(revision 217743)
+++ tests/vsip_csl/matlab_bin_file/matlab_bin_file.cpp	(working copy)
@@ -18,6 +18,7 @@
 #include <iomanip>
 #include <fstream>
 
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
@@ -220,6 +221,8 @@
 
 int main(int ac, char** av)
 {
+  vsipl init(ac, av);
+
   write_file("temp.mat");
 
   // Read what we just wrote.
Index: tests/vsip_csl/matlab_iterator.cpp
===================================================================
--- tests/vsip_csl/matlab_iterator.cpp	(revision 217743)
+++ tests/vsip_csl/matlab_iterator.cpp	(working copy)
@@ -17,6 +17,7 @@
 
 #include <iostream>
 
+#include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
@@ -139,8 +140,14 @@
   // write it out to file
   ofs << Matlab_bin_formatter<Vector<T> >(a,name);
 }
-int main()
+
+
+
+int
+main(int argc, char** argv)
 {
+  vsipl init(argc, argv);
+
   // We need to generate the matlab file first.
   {
     std::ofstream ofs("temp.mat");
