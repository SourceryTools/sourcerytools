Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 221467)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -26,8 +26,8 @@
 #endif
 
 
-// This compiler switch changes the behavior of the digital spotlighting
-// computation such that it behaves in a more cache-friendly way.
+// This compiler switch changes the way the digital spotlighting routine
+// interacts with the cache.
 // 
 // A value of '1' will use 1-D FFTs instead of FFTMs (multiple-FFTs)
 // and it will perform several operations at a time when it processes the
@@ -37,7 +37,7 @@
 // entire image before proceeding to the next.  This can be more efficient
 // on certain architectures (such as Cell/B.E.) where large computations
 // can be distributed amongst several compute elements and run in parallel.
-#define CACHE_FRIENDLY 1
+#define DIGITAL_SPOTLIGHT_BY_ROW  1
 
 template <typename T>
 class Kernel1_base
@@ -294,7 +294,7 @@
   complex_col_matrix_type spatial_;
   real_col_matrix_type image_t_;
 
-#if CACHE_FRIENDLY
+#if DIGITAL_SPOTLIGHT_BY_ROW
   Vector<complex<T> > fs_row_;
   Vector<complex<T> > fs_spotlit_row_;
   col_fft_type ft_fft_;
@@ -334,7 +334,7 @@
     F_shifted_(this->nx_, m_),
     spatial_(this->nx_, m_),
     image_t_(this->nx_, m_),
-#if CACHE_FRIENDLY
+#if DIGITAL_SPOTLIGHT_BY_ROW
     fs_row_(mc),
     fs_spotlit_row_(m),
     ft_fft_(Domain<1>(n), T(1)),
@@ -492,7 +492,7 @@
 
 
 
-#if CACHE_FRIENDLY
+#if DIGITAL_SPOTLIGHT_BY_ROW
 
 template <typename T>
 void
@@ -663,7 +663,7 @@
 
   SAVE_VIEW("p77_fsm.view", fsm_, this->swap_bytes_);
 }
-#endif // CACHE_FRIENDLY
+#endif // DIGITAL_SPOTLIGHT_BY_ROW
 
 
 
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 221467)
+++ ChangeLog	(working copy)
@@ -1,7 +1,7 @@
 2008-09-15  Don McCoy  <don@codesourcery.com>
 
-	* kernel1.hpp (CACHE_FRIENDLY): Added a switch to control the way the
-	  digitial spotlighting computation is performed.
+	* apps/ssar/kernel1.hpp (DIGITAL_SPOTLIGHT_BY_ROW): Added a switch to
+	  control the way the digitial spotlighting computation is performed.
 
 2008-09-15  Stefan Seefeld  <stefan@codesourcery.com>
 
