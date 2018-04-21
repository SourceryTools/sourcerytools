Index: ChangeLog
===================================================================
--- ChangeLog	(revision 231056)
+++ ChangeLog	(working copy)
@@ -1,6 +1,13 @@
+2008-11-21  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/ops_info.hpp: Add ops count for mag.
+	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Remove unnecessary 
+	  -lfft_example.
+	* apps/ssar/kernel1.hpp: Remove commented out code.
+
 2008-12-09  Stefan Seefeld  <stefan@codesourcery.com>
 
-	* src/vsip/core/signa./fir.hpp: Add Profile_policy specializations
+	* src/vsip/core/signal/fir.hpp: Add Profile_policy specializations
 	to prevent move-semantics.
 
 2008-12-04  Stefan Seefeld  <stefan@codesourcery.com>
Index: src/vsip/core/ops_info.hpp
===================================================================
--- src/vsip/core/ops_info.hpp	(revision 230289)
+++ src/vsip/core/ops_info.hpp	(working copy)
@@ -31,6 +31,7 @@
   static unsigned int const sqr = 1;
   static unsigned int const mul = 1;
   static unsigned int const add = 1;
+  static unsigned int const mag = 1;
 };
 
 template <typename T>
@@ -40,6 +41,7 @@
   static unsigned int const sqr = 2 + 1;     // mul + add
   static unsigned int const mul = 4 + 2;     // mul + add
   static unsigned int const add = 2;
+  static unsigned int const mag = 2 + 1 + 1; // 2*mul + add + sqroot
 };
 
 
Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 230289)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -111,8 +111,6 @@
 $(spe_kernels): $(src_vsip_opt_cbe_spu_obj)
 	$(link_spu_kernel_dso)
 
-src/vsip/opt/cbe/spu/alf_fft_c.spe: override LIBS_SPU += -lfft_example
-
 src/vsip/opt/cbe/spu/alf_vmmul_c.spe: override C_SPU_FLAGS += -funroll-loops
 
 $(src_vsip_opt_cbe_spu_obj): %.$(OBJEXT): %.spe
Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 230289)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -291,7 +291,6 @@
   typedef Fft<const_Vector, complex<T>, complex<T>, fft_inv, by_reference> inv_fft_type;
   typedef Fftm<complex<T>, complex<T>, row, fft_fwd, by_reference> row_fftm_type;
   typedef Fftm<complex<T>, complex<T>, row, fft_fwd, by_value> val_row_fftm_type;
-  //FOO typedef Fftm<complex<T>, complex<T>, col, fft_fwd, by_reference> col_fftm_type;
   typedef Fftm<complex<T>, complex<T>, col, fft_fwd, by_value> val_col_fftm_type;
   typedef Fftm<complex<T>, complex<T>, row, fft_inv, by_reference> inv_row_fftm_type;
   typedef Fftm<complex<T>, complex<T>, row, fft_inv, by_value> val_inv_row_fftm_type;
