Index: ChangeLog
===================================================================
--- ChangeLog	(revision 236551)
+++ ChangeLog	(working copy)
@@ -1,3 +1,7 @@
+2009-02-19  Jules Bergmann  <jules@codesourcery.com>
+
+	* examples/cell/setup.sh: Add recommended --enable-timer=power_tb.
+
 2009-02-13  Jules Bergmann  <jules@codesourcery.com>
 
 	* m4/parallel.m4: Only define VSIP_IMPL_HAVE_MPI when we actually
Index: examples/cell/setup.sh
===================================================================
--- examples/cell/setup.sh	(revision 236492)
+++ examples/cell/setup.sh	(working copy)
@@ -37,18 +37,18 @@
 export CXX=ppu-g++
 export LD=ppu-ld
 
-$src_dir/configure								\
-	--with-cbe-sdk=3.0							\
-	--with-cbe-sdk-prefix=$sdk_dir						\
-	--disable-fft-long-double						\
-	--disable-parallel							\
-	--with-lapack=atlas							\
-	--with-atlas-include=/usr/include/atlas					\
-	--with-atlas-libdir=/usr/lib/altivec					\
-	--enable-fft=cbe_sdk,fftw3						\
-	--with-builtin-simd-routines=generic					\
-	--with-complex=split							\
-	--with-test-level=1							\
-	--prefix=$svpp_prefix							\
-	--with-cml-prefix=$cml_dir 			 			\
+$src_dir/configure							\
+	--with-cbe-sdk=3.0						\
+	--with-cbe-sdk-prefix=$sdk_dir					\
+	--disable-fft-long-double					\
+	--disable-parallel						\
+	--with-lapack=atlas						\
+	--with-atlas-include=/usr/include/atlas				\
+	--with-atlas-libdir=/usr/lib/altivec				\
+	--enable-fft=cbe_sdk,fftw3					\
+	--with-builtin-simd-routines=generic				\
+	--with-complex=split						\
+	--with-test-level=1						\
+	--prefix=$svpp_prefix						\
+	--with-cml-prefix=$cml_dir 			 		\
 	--enable-timer=power_tb
