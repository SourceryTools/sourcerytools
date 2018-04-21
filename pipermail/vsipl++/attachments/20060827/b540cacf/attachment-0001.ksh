Index: tests/extdata-subviews.cpp
===================================================================
--- tests/extdata-subviews.cpp	(revision 147814)
+++ tests/extdata-subviews.cpp	(working copy)
@@ -1403,9 +1403,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
 
 #if VSIP_IMPL_TEST_LEVEL == 0
   vector_test<float>(Domain<1>(7));
Index: tests/reductions-idx.cpp
===================================================================
--- tests/reductions-idx.cpp	(revision 147814)
+++ tests/reductions-idx.cpp	(working copy)
@@ -314,9 +314,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
-   vsipl init;
+   vsipl init(argc, argv);
 
    cover_maxval<int>();
    cover_maxval<float>();
Index: tests/window.cpp
===================================================================
--- tests/window.cpp	(revision 147814)
+++ tests/window.cpp	(working copy)
@@ -96,9 +96,9 @@
 
 
 int
-main ()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
 
 
   // Blackman
Index: tests/fns_scalar.cpp
===================================================================
--- tests/fns_scalar.cpp	(revision 147814)
+++ tests/fns_scalar.cpp	(working copy)
@@ -132,9 +132,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
   
   // magsq
   test_magsq<0, float, complex<float> >();
Index: tests/fft_ext/fft_ext.cpp
===================================================================
--- tests/fft_ext/fft_ext.cpp	(revision 147814)
+++ tests/fft_ext/fft_ext.cpp	(working copy)
@@ -311,7 +311,7 @@
 ///
 int main (int argc, char **argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
   struct arguments arguments;
      
   /* Default values. */
Index: tests/regressions/fft_temp_view.cpp
===================================================================
--- tests/regressions/fft_temp_view.cpp	(revision 147814)
+++ tests/regressions/fft_temp_view.cpp	(working copy)
@@ -140,9 +140,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
 
   test_fft<complex<float> >(32);
   test_fftm<0, complex<float> >(8, 16);
Index: tests/regressions/proxy_lvalue_conv.cpp
===================================================================
--- tests/regressions/proxy_lvalue_conv.cpp	(revision 147814)
+++ tests/regressions/proxy_lvalue_conv.cpp	(working copy)
@@ -71,9 +71,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
 
   // Dense uses real lvalues.
   Vector<float> v_float(5);
Index: tests/regressions/const_view_at_op.cpp
===================================================================
--- tests/regressions/const_view_at_op.cpp	(revision 147814)
+++ tests/regressions/const_view_at_op.cpp	(working copy)
@@ -186,9 +186,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
 
   do_vector<float>();
   do_vector<complex<float> >();
Index: tests/regressions/subview_exprs.cpp
===================================================================
--- tests/regressions/subview_exprs.cpp	(revision 147814)
+++ tests/regressions/subview_exprs.cpp	(working copy)
@@ -161,9 +161,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
 
   // tests using expressions of row/col subviews
   test_a1<float>(7, 5);	// PASS: dst.row(i) = src.row(i)
Index: tests/view_lvalue.cpp
===================================================================
--- tests/view_lvalue.cpp	(revision 147814)
+++ tests/view_lvalue.cpp	(working copy)
@@ -227,7 +227,7 @@
 }
 
 int
-main()
+main(int argc, char** argv)
 {
   using vsip::Vector;
   using vsip::Matrix;
@@ -236,7 +236,7 @@
   using vsip::Plain_block;
   using vsip::scalar_f;
 
-  vsip::vsipl initialize_library;
+  vsip::vsipl init(argc, argv);
 
   // Tests with Dense test true lvalue access.
   test_vector<Vector<scalar_f, Dense<1, scalar_f> > >();
Index: tests/iir.cpp
===================================================================
--- tests/iir.cpp	(revision 147814)
+++ tests/iir.cpp	(working copy)
@@ -334,9 +334,9 @@
 ***********************************************************************/
 
 int
-main()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
 
   test_iir_as_fir<int>();
   test_iir_as_fir<float>();
Index: tests/histogram.cpp
===================================================================
--- tests/histogram.cpp	(revision 147814)
+++ tests/histogram.cpp	(working copy)
@@ -158,9 +158,9 @@
 
 
 int
-main ()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
 
   cases_by_type<float>();
   cases_by_type<double>();
Index: tests/reductions-bool.cpp
===================================================================
--- tests/reductions-bool.cpp	(revision 147814)
+++ tests/reductions-bool.cpp	(working copy)
@@ -108,9 +108,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
    
   simple_tests();
 
Index: tests/freqswap.cpp
===================================================================
--- tests/freqswap.cpp	(revision 147814)
+++ tests/freqswap.cpp	(working copy)
@@ -78,9 +78,9 @@
 
 
 int
-main ()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
 
   cases_by_type<float>();
   cases_by_type<double>();
Index: tests/random.cpp
===================================================================
--- tests/random.cpp	(revision 147814)
+++ tests/random.cpp	(working copy)
@@ -348,11 +348,11 @@
 
 
 int
-main ()
+main(int argc, char** argv)
 {
   using namespace vsip;
   using namespace vsip_csl;
-  vsipl init;
+  vsipl init(argc, argv);
 
   // Random generation tests -- Compare against C VSIPL generator.
 
Index: tests/fir.cpp
===================================================================
--- tests/fir.cpp	(revision 147814)
+++ tests/fir.cpp	(working copy)
@@ -169,9 +169,9 @@
 }
   
 int
-main()
+main(int argc, char** argv)
 {
-  vsip::vsipl init;
+  vsip::vsipl init(argc, argv);
 
   test_fir<float,vsip::nonsym>(1,2,3);
   test_fir<float,vsip::nonsym>(1,3,5);
Index: tests/fftm.cpp
===================================================================
--- tests/fftm.cpp	(revision 147814)
+++ tests/fftm.cpp	(working copy)
@@ -389,9 +389,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
 
 #if defined(VSIP_IMPL_FFT_USE_FLOAT)
   test<float>();
Index: tests/selgen-ramp.cpp
===================================================================
--- tests/selgen-ramp.cpp	(revision 147814)
+++ tests/selgen-ramp.cpp	(working copy)
@@ -61,9 +61,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
 
   ramp_cases();
 }
Index: tests/reductions.cpp
===================================================================
--- tests/reductions.cpp	(revision 147814)
+++ tests/reductions.cpp	(working copy)
@@ -405,9 +405,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
    
   simple_tests();
 
Index: tests/fft.cpp
===================================================================
--- tests/fft.cpp	(revision 147814)
+++ tests/fft.cpp	(working copy)
@@ -1005,9 +1005,9 @@
 
 
 int
-main()
+main(int argc, char** argv)
 {
-  vsipl init;
+  vsipl init(argc, argv);
 
   // show_config();
 
Index: tests/elementwise.cpp
===================================================================
--- tests/elementwise.cpp	(revision 147814)
+++ tests/elementwise.cpp	(working copy)
@@ -344,9 +344,9 @@
 
 
 
-int main() 
+main(int argc, char** argv)
 {
-  vsip::vsipl v;
+  vsip::vsipl init(argc, argv);
 
   Test_add();
   Test_sub();
