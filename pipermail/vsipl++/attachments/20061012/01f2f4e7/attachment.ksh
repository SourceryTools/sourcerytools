Index: ChangeLog
===================================================================
--- ChangeLog	(revision 151279)
+++ ChangeLog	(working copy)
@@ -1,3 +1,12 @@
+2006-10-12  Jules Bergmann  <jules@codesourcery.com>
+
+	* tests/matvec.cpp: Disable long double test when
+	  VSIP_IMPL_TEST_LONG_DOUBLE not set.
+	* tests/vmmul.cpp: Use length_type to represent number of processors.
+	* tests/util-par.hpp: Likewise.
+	* tests/parallel/subviews.cpp: Likewise.
+	* tests/parallel/block.cpp: Likewise.
+	
 2006-10-11  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* vendor/atlas/configure.ac: Add case to properly handle ATHLON.
Index: tests/matvec.cpp
===================================================================
--- tests/matvec.cpp	(revision 151279)
+++ tests/matvec.cpp	(working copy)
@@ -508,7 +508,7 @@
 
   modulate_cases<float>(10);
   modulate_cases<double>(32);
-#if VSIP_IMPL_HAVE_COMPLEX_LONG_DOUBLE
+#if VSIP_IMPL_HAVE_COMPLEX_LONG_DOUBLE && VSIP_IMPL_TEST_LONG_DOUBLE
   modulate_cases<long double>(16);
 #endif
 
Index: tests/vmmul.cpp
===================================================================
--- tests/vmmul.cpp	(revision 151279)
+++ tests/vmmul.cpp	(working copy)
@@ -142,7 +142,7 @@
 void
 par_vmmul_cases()
 {
-  processor_type np, nr, nc;
+  length_type np, nr, nc;
 
   get_np_square(np, nr, nc);
 
Index: tests/util-par.hpp
===================================================================
--- tests/util-par.hpp	(revision 151279)
+++ tests/util-par.hpp	(working copy)
@@ -35,13 +35,13 @@
 
 void
 get_np_square(
-  vsip::processor_type& np,
-  vsip::processor_type& nr,
-  vsip::processor_type& nc)
+  vsip::length_type& np,
+  vsip::length_type& nr,
+  vsip::length_type& nc)
 {
   np = vsip::num_processors();
-  nr = (vsip::processor_type)floor(sqrt((double)np));
-  nc = (vsip::processor_type)floor((double)np/nr);
+  nr = (vsip::length_type)floor(sqrt((double)np));
+  nc = (vsip::length_type)floor((double)np/nr);
 
   assert(nr*nc <= np);
 }
@@ -50,16 +50,16 @@
 
 void
 get_np_cube(
-  vsip::processor_type& np,
-  vsip::processor_type& n1,
-  vsip::processor_type& n2,
-  vsip::processor_type& n3)
+  vsip::length_type& np,
+  vsip::length_type& n1,
+  vsip::length_type& n2,
+  vsip::length_type& n3)
 {
   np = vsip::num_processors();
   // cbrt() may not be available, so do it manually.
-  n1 = (vsip::processor_type)floor(exp(log((double)np)/3));
-  n2 = (vsip::processor_type)floor((double)np/(n1*n1));
-  n3 = (vsip::processor_type)floor((double)np/(n1*n2));
+  n1 = (vsip::length_type)floor(exp(log((double)np)/3));
+  n2 = (vsip::length_type)floor((double)np/(n1*n1));
+  n3 = (vsip::length_type)floor((double)np/(n1*n2));
 
   assert(n1*n2*n3 <= np);
 }
@@ -70,15 +70,15 @@
 
 void
 get_np_half(
-  vsip::processor_type& np,
-  vsip::processor_type& nr,
-  vsip::processor_type& nc)
+  vsip::length_type& np,
+  vsip::length_type& nr,
+  vsip::length_type& nc)
 {
   np = vsip::num_processors();
 
   if (np >= 2)
   {
-    nr = (vsip::processor_type)floor((double)np/2);
+    nr = (vsip::length_type)floor((double)np/2);
     nc = 2;
   }
   else
Index: tests/parallel/subviews.cpp
===================================================================
--- tests/parallel/subviews.cpp	(revision 151282)
+++ tests/parallel/subviews.cpp	(working copy)
@@ -136,7 +136,7 @@
 void
 cases_row_sum(Domain<2> const& dom)
 {
-  processor_type np, nr, nc;
+  length_type np, nr, nc;
 
   get_np_square(np, nr, nc);
 
@@ -249,7 +249,7 @@
 void
 cases_col_sum(Domain<2> const& dom)
 {
-  processor_type np, nr, nc;
+  length_type np, nr, nc;
 
   get_np_square(np, nr, nc);
 
@@ -417,7 +417,7 @@
 void
 cases_tensor_v_sum(Domain<3> const& dom)
 {
-  processor_type np, nr, nc, nt;
+  length_type np, nr, nc, nt;
 
   get_np_square(np, nr, nc);
 
@@ -596,7 +596,7 @@
 void
 cases_tensor_m_sum(Domain<3> const& dom)
 {
-  processor_type np, nr, nc, nt;
+  length_type np, nr, nc, nt;
 
   get_np_square(np, nr, nc);
 
@@ -665,7 +665,7 @@
   comm.barrier();
 #endif
 
-  processor_type np, nr, nc;
+  length_type np, nr, nc;
 
   get_np_square(np, nr, nc);
 
Index: tests/parallel/block.cpp
===================================================================
--- tests/parallel/block.cpp	(revision 151279)
+++ tests/parallel/block.cpp	(working copy)
@@ -444,7 +444,7 @@
 void
 test_matrix(int loop)
 {
-  processor_type np, nr, nc;
+  length_type np, nr, nc;
   get_np_half(np, nr, nc);
 
   test_distributed_view<TestImplTag, T>(
@@ -482,7 +482,7 @@
 void
 test_par_assign_cases(int loop)
 {
-  processor_type np, nr, nc;
+  length_type np, nr, nc;
   get_np_square(np, nr, nc);
 
   // Vector Serial -> Serial
@@ -591,7 +591,7 @@
   cout << "start\n";
 #endif
 
-  processor_type np, nc, nr;
+  length_type np, nc, nr;
   get_np_square(np, nc, nr);
 
   test_par_assign_cases<float>(loop);
