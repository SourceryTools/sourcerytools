Index: ChangeLog
===================================================================
--- ChangeLog	(revision 186103)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2007-10-30  Jules Bergmann  <jules@codesourcery.com>
 
+	* tests/tutorial/matlab_iter_example.cpp (test_write): New function,
+	  initialize sample.mat.
+
+2007-10-30  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/ipp/bindings.hpp: Add bindings for vcopy and vzero.
 	* src/vsip/opt/ipp/bindings.cpp: Likewise.
 	* src/vsip/opt/ipp/fir.hpp: Manipulate C arrays directly, rather
Index: tests/tutorial/matlab_iter_example.cpp
===================================================================
--- tests/tutorial/matlab_iter_example.cpp	(revision 185668)
+++ tests/tutorial/matlab_iter_example.cpp	(working copy)
@@ -22,20 +22,23 @@
 #include <vsip_csl/error_db.hpp>
 
 
+void
+test_write()
+{
+#include <../doc/tutorial/src/matlab_bin_formatter_write.cpp>
+}
 
 void
 test_read_matrix()
 {
 #include <../doc/tutorial/src/matlab_iter_example1.cpp>
 
-#if 1
-  // Initialize matrix 'm'.
+  // Check result.  Example reads record 'm' from file into matrix 'm'.
   Matrix<float> chk_m(3, 3);
   for(index_type i=0;i<3;i++)
     chk_m.row(i) = ramp<float>(3*i, 1, 3);
 
   test_assert(vsip_csl::error_db(m, chk_m) < -100);
-#endif
 }
 
 
@@ -45,13 +48,11 @@
 {
 #include <../doc/tutorial/src/matlab_iter_example2.cpp>
 
-#if 0
-  // Initialize vector 'v'.
+  // Check result.  Example reads record 'v' from file into vector 'v'.
   Vector<float> chk_v(3);
   chk_v = ramp<float>(0, 1, 3);
 
   test_assert(vsip_csl::error_db(v, chk_v) < -100);
-#endif
 }
 
 
@@ -60,7 +61,8 @@
 {
   vsipl init(argc, argv);
 
-  // test_write();
+  test_write();
+
   test_read_matrix();
   test_read_vector();
 }
