Index: ChangeLog
===================================================================
--- ChangeLog	(revision 223895)
+++ ChangeLog	(working copy)
@@ -1,5 +1,9 @@
 2008-10-06  Jules Bergmann  <jules@codesourcery.com>
 
+	* tests/fft_be.cpp: Fix check for CBE SDK FFT BE.
+
+2008-10-06  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/core/check_config_body.hpp: Add additional output for
 	  FFT BE configuration.
 
Index: tests/fft_be.cpp
===================================================================
--- tests/fft_be.cpp	(revision 223485)
+++ tests/fft_be.cpp	(working copy)
@@ -87,7 +87,7 @@
 {
   typedef 
   vsip::impl::Make_type_list<
-#if VSIP_IMPL_CBE_SDK
+#if VSIP_IMPL_CBE_SDK_FFT
     vsip::impl::Cbe_sdk_tag,
 #endif
     vsip::impl::fft::No_FFT_tag>::type
@@ -590,7 +590,7 @@
   fft_in_place<T, F, 1, cvsip>(Domain<1>(0, 2, 8));
 #endif
 
-#if VSIP_IMPL_CBE_SDK
+#if VSIP_IMPL_CBE_SDK_FFT
   std::cout << "testing fwd in_place cbe...";
   fft_in_place<T, F, -1, cbe>(Domain<1>(32));
   std::cout << "testing inv in_place cbe...";
@@ -657,7 +657,7 @@
   fft_by_ref<rfft_type<T, F, 1, 0>, cvsip>(Domain<1>(0, 2, 8));
 #endif
 
-#if VSIP_IMPL_CBE_SDK
+#if VSIP_IMPL_CBE_SDK_FFT
   std::cout << "testing c->c fwd by_ref cbe...";
   fft_by_ref<cfft_type<T, F, -1>, cbe>(Domain<1>(32));
   std::cout << "testing c->c inv by_ref cbe...";
@@ -1009,7 +1009,7 @@
   fftm_in_place<T, F, 1, 1, cvsip>(Domain<2>(8, 16));
 #endif
 
-#if VSIP_IMPL_CBE_SDK
+#if VSIP_IMPL_CBE_SDK_FFT
 // Note: column-wise FFTs need to be performed on
 // col-major data in this case.  These are commented
 // out until fftm_in_place is changed to be like
@@ -1102,7 +1102,7 @@
   fftm_by_ref<rfft_type<T, F, 1, 1>, cvsip> (Domain<2>(4, 16));
 #endif
 
-#if VSIP_IMPL_CBE_SDK
+#if VSIP_IMPL_CBE_SDK_FFT
   std::cout << "testing c->c fwd on cols by_ref cbe...";
   fftm_by_ref<cfft_type<T, F, -1, 0, col2_type>, cbe>(Domain<2>(32, 64));
   fftm_by_ref<cfft_type<T, F, -1, 0, col2_type>, cbe>(Domain<2>(Domain<1>(32), Domain<1>(0, 2, 32)));
