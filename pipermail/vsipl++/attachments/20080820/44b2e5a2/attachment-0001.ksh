Index: apps/ssar/diffview.cpp
===================================================================
--- apps/ssar/diffview.cpp	(revision 217117)
+++ apps/ssar/diffview.cpp	(working copy)
@@ -32,6 +32,12 @@
   INTEGER_VIEW
 };
 
+#if _BIG_ENDIAN
+bool swap_bytes = true;   // Whether or not to swap bytes during file I/O
+#else
+bool swap_bytes = false;
+#endif
+
 template <typename T>
 void 
 compare(char const* infile, char const* ref, length_type rows, 
@@ -91,10 +97,10 @@
   Domain<2> dom(rows, cols);
 
   matrix_type in(rows, cols);
-  in = Load_view<2, T>(infile, dom).view();
+  in = Load_view<2, T>(infile, dom, vsip::Local_map(), swap_bytes).view();
 
   matrix_type refv(rows, cols);
-  refv = Load_view<2, T>(ref, dom).view();
+  refv = Load_view<2, T>(ref, dom, vsip::Local_map(), swap_bytes).view();
 
   cout << error_db(in, refv) << endl;
 }
Index: apps/ssar/GNUmakefile
===================================================================
--- apps/ssar/GNUmakefile	(revision 217117)
+++ apps/ssar/GNUmakefile	(working copy)
@@ -40,10 +40,12 @@
 
 ifeq ($(strip $(prefix)),)
 pkgcommand := pkg-config vsipl++$(suffix)
+fmt-profile-command := $(subst /lib/pkgconfig,,$(PKG_CONFIG_PATH))/bin/fmt-profile.pl
 else
 pkgcommand := PKG_CONFIG_PATH=$(prefix)/lib/pkgconfig 	\
                      pkg-config vsipl++$(suffix) 	\
                      --define-variable=prefix=$(prefix)
+fmt-profile-command := $(prefix)/bin/fmt-profile.pl
 endif
 
 
@@ -60,35 +62,49 @@
 
 all: ssar viewtoraw diffview
 
+show:
+	@echo "pkgcommand: " $(pkgcommand)
+	@echo "CXX       : " $(CXX)
+	@echo "CXXFLAGS  : " $(CXXFLAGS)
+	@echo "LIBS      : " $(LIBS)
+
 clean: 
-	rm *.o
-	rm ssar
-	rm viewtoraw
-	rm diffview
+	rm -f *.o
+	rm -f ssar
+	rm -f viewtoraw
+	rm -f diffview
 
 check: all
 	@echo "Running SSAR application..."
-	./ssar set1
+	./ssar data3
 	@echo
 	@echo "Comparing output to reference view (should be less than -100)"
-	./diffview -r set1/image.view set1/$(ref_image_base).view 756 1144
+	./diffview -r data3/image.view data3/$(ref_image_base).view 756 1144
 	@echo
 	@echo "Creating viewable image of output"
-	./viewtoraw -s set1/image.view set1/image.raw 1144 756
-	rawtopgm 756 1144 set1/image.raw > set1/image.pgm
-	rm set1/image.raw
+	./viewtoraw -s data3/image.view data3/image.raw 1144 756
+	rawtopgm 756 1144 data3/image.raw > data3/image.pgm
+	rm -f data3/image.raw
 	@echo
 	@echo "Creating viewable image of reference view"
-	./viewtoraw -s set1/$(ref_image_base).view set1/$(ref_image_base).raw 1144 756
-	rawtopgm 756 1144 set1/$(ref_image_base).raw > set1/$(ref_image_base).pgm
-	rm set1/$(ref_image_base).raw
+	./viewtoraw -s data3/$(ref_image_base).view data3/$(ref_image_base).raw 1144 756
+	rawtopgm 756 1144 data3/$(ref_image_base).raw > data3/$(ref_image_base).pgm
+	rm -f data3/$(ref_image_base).raw
 
-profile: ssar
-	@echo "Profiling SSAR application..."
-	./ssar set1 -loop 10 --vsipl++-profile-mode=accum --vsipl++-profile-output=profile.out
+profile1: ssar viewtoraw
+	@echo "Profiling SSAR application (SCALE = 1)..."
+	./ssar data1 -loop 1 --vsipl++-profile-mode=accum --vsipl++-profile-output=profile.out
 	@echo "Formatting profiler output..."
-	$(prefix)/bin/fmt-profile.pl -sec -o profile.txt set1/profile.out
+	${fmt-profile-command}  -sec -o profile1.txt data1/profile.out
+	./make_images.sh data1 438 160 382 266
 
+profile3: ssar viewtoraw
+	@echo "Profiling SSAR application (SCALE = 3)..."
+	./ssar data3 -loop 1 --vsipl++-profile-mode=accum --vsipl++-profile-output=profile.out
+	@echo "Formatting profiler output..."
+	${fmt-profile-command}  -sec -o profile3.txt data3/profile.out
+	./make_images.sh data3 1072 480 1144 756
+
 ssar.o: ssar.cpp kernel1.hpp
 
 ssar: ssar.o
Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 217117)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -20,9 +20,9 @@
 
 #if 0
 #define VERBOSE
-#define SAVE_VIEW(a, b)    vsip_csl::save_view_as<complex<float> >(a, b)
+#define SAVE_VIEW(a, b, c)    vsip_csl::save_view_as<complex<float> >(a, b, c)
 #else
-#define SAVE_VIEW(a, b)
+#define SAVE_VIEW(a, b, c)
 #endif
 
 template <typename T>
@@ -36,14 +36,15 @@
   typedef Matrix<T> real_matrix_type;
   typedef Vector<T> real_vector_type;
 
-  Kernel1_base(length_type scale, length_type n, length_type mc, 
-    length_type m);
+  Kernel1_base(scalar_f scale, length_type n, length_type mc, 
+    length_type m, bool swap_bytes);
   ~Kernel1_base() {}
 
-  length_type scale_;
+  scalar_f scale_;
   length_type n_;
   length_type mc_;
   length_type m_;
+  bool swap_bytes_;
   length_type nx_;
   length_type interp_sidelobes_;
   length_type I_;
@@ -66,9 +67,9 @@
 };
 
 template <typename T>
-Kernel1_base<T>::Kernel1_base(length_type scale, length_type n, 
-  length_type mc, length_type m)
-  : scale_(scale), n_(n), mc_(mc), m_(m),
+Kernel1_base<T>::Kernel1_base(scalar_f scale, length_type n, 
+  length_type mc, length_type m, bool swap_bytes)
+  : scale_(scale), n_(n), mc_(mc), m_(m), swap_bytes_(swap_bytes),
     fast_time_filter_(n),
     fs_ref_(n, m),
     ks_(n),
@@ -117,12 +118,12 @@
   real_vector_type ku0(m);
 
   load_view_as<complex<float>, complex_vector_type>
-    (FAST_TIME_FILTER, fast_time_filter_);
-  load_view_as<float, real_vector_type>(SLOW_TIME_WAVENUMBER, k);
+    (FAST_TIME_FILTER, fast_time_filter_, swap_bytes_);
+  load_view_as<float, real_vector_type>(SLOW_TIME_WAVENUMBER, k, swap_bytes_);
   load_view_as<float, real_vector_type>
-    (SLOW_TIME_COMPRESSED_APERTURE_POSITION, uc);
-  load_view_as<float, real_vector_type>(SLOW_TIME_APERTURE_POSITION, u);
-  load_view_as<float, real_vector_type>(SLOW_TIME_SPATIAL_FREQUENCY, ku0);
+    (SLOW_TIME_COMPRESSED_APERTURE_POSITION, uc, swap_bytes_);
+  load_view_as<float, real_vector_type>(SLOW_TIME_APERTURE_POSITION, u, swap_bytes_);
+  load_view_as<float, real_vector_type>(SLOW_TIME_SPATIAL_FREQUENCY, ku0, swap_bytes_);
 
   // 60. (1 by n array of reals) fftshifted slow-time wavenumber
   fftshift(k, ks_);
@@ -174,7 +175,7 @@
   fs_ref_ = ite(kx_ > 0, exp(complex<T>(0, 1) * 
     (Xc_ * (kx_ - 2 * k1) + T(0.25 * M_PI) + ku)), complex<T>(0));
 
-  SAVE_VIEW("p76_fs_ref.view", fs_ref_);
+  SAVE_VIEW("p76_fs_ref.view", fs_ref_, swap_bytes_);
 
   // 78. (scalar, int) interpolation processing sliver size
   I_ = 2 * interp_sidelobes_ + 1;
@@ -224,7 +225,8 @@
   typedef Fftm<complex<T>, complex<T>, row, fft_inv, by_reference> inv_row_fftm_type;
   typedef Fftm<complex<T>, complex<T>, col, fft_inv, by_reference> inv_col_fftm_type;
 
-  Kernel1(length_type scale, length_type n, length_type mc, length_type m);
+  Kernel1(scalar_f scale, length_type n, length_type mc, length_type m,
+    bool swap_bytes);
   ~Kernel1() {}
 
   void process_image(complex_matrix_type const input, 
@@ -244,7 +246,7 @@
   interpolation(real_matrix_type image);
 
 private:
-  length_type scale_;
+  scalar_f scale_;
   length_type n_;
   length_type mc_;
   length_type m_;
@@ -275,9 +277,9 @@
 
 
 template <typename T>
-Kernel1<T>::Kernel1(length_type scale, length_type n, length_type mc, 
-  length_type m)
-  : Kernel1_base<T>(scale, n, mc, m),
+Kernel1<T>::Kernel1(scalar_f scale, length_type n, length_type mc, 
+  length_type m, bool swap_bytes)
+  : Kernel1_base<T>(scale, n, mc, m, swap_bytes),
     scale_(scale), n_(n), mc_(mc), m_(m), 
     s_filt_(n, mc),
     s_filt_t_(n, mc),
@@ -474,7 +476,7 @@
     fsm_.row(xr)(rdom) = fs_spotlit_(ldom) * this->fs_ref_.row(xr)(rdom);
   }
 
-  SAVE_VIEW("p77_fsm.view", fsm_);
+  SAVE_VIEW("p77_fsm.view", fsm_, this->swap_bytes_);
 }
 
 
@@ -520,7 +522,7 @@
   } // 93. end the range loop
   }
 
-  SAVE_VIEW("p92_F.view", F_);
+  SAVE_VIEW("p92_F.view", F_, this->swap_bytes_);
 
 
   // transform from the Doppler domain image into a spatial domain image
Index: apps/ssar/make_set1_images.sh
===================================================================
--- apps/ssar/make_set1_images.sh	(revision 218079)
+++ apps/ssar/make_set1_images.sh	(working copy)
@@ -1,23 +0,0 @@
-#! /bin/sh
-
-# This script creates images from the intermediate images produced during
-# Kernel 1 processing (when VERBOSE is defined in kernel1.hpp).
-#
-# Requires 'rawtopgm' and 'viewtoraw' (the source for the latter is included).
-
-echo "converting to raw greyscale..."
-./viewtoraw set1/sar.view set1/p00_sar.raw 1072 480
-./viewtoraw -r set1/p76_fs_ref.view set1/p76_fs_ref.raw 1072 1144
-./viewtoraw set1/p77_fsm.view set1/p77_fsm.raw 1072 1144
-./viewtoraw set1/p92_F.view set1/p92_F.raw 756 1144
-./viewtoraw -s set1/image.view set1/p95_image.raw 1144 756
-
-echo "converting to set1/pgm format..."
-rawtopgm 480 1072 set1/p00_sar.raw > set1/p00_sar.pgm
-rawtopgm 1144 1072 set1/p76_fs_ref.raw > set1/p76_fs_ref.pgm
-rawtopgm 1144 1072 set1/p77_fsm.raw > set1/p77_fsm.pgm
-rawtopgm 1144 756 set1/p92_F.raw > set1/p92_F.pgm
-rawtopgm 756 1144 set1/p95_image.raw > set1/p95_image.pgm
-
-echo "cleaning up raw files..."
-rm set1/p*.raw
Index: apps/ssar/viewtoraw.cpp
===================================================================
--- apps/ssar/viewtoraw.cpp	(revision 217117)
+++ apps/ssar/viewtoraw.cpp	(working copy)
@@ -16,7 +16,7 @@
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 
-#include <vsip/opt/view_cast.hpp>
+#include <vsip/core/view_cast.hpp>
 
 #include <vsip_csl/load_view.hpp>
 #include <vsip_csl/save_view.hpp>
@@ -36,6 +36,12 @@
   SCALAR_INTEGER
 };
 
+#if _BIG_ENDIAN
+bool swap_bytes = true;   // Whether or not to swap bytes during file I/O
+#else
+bool swap_bytes = false;
+#endif
+
 void convert_to_greyscale(data_format_type format, 
   char const* infile, char const* outfile, length_type rows, length_type cols);
 
@@ -100,15 +106,15 @@
   matrix_type in(rows, cols);
 
   if (format == COMPLEX_MAG)
-    in = mag(Load_view<2, cscalar_f>(infile, dom).view());
+    in = mag(Load_view<2, cscalar_f>(infile, dom, vsip::Local_map(), swap_bytes).view());
   else if (format == COMPLEX_REAL)
-    in = real(Load_view<2, cscalar_f>(infile, dom).view());
+    in = real(Load_view<2, cscalar_f>(infile, dom, vsip::Local_map(), swap_bytes).view());
   else if (format == COMPLEX_IMAG)
-    in = imag(Load_view<2, cscalar_f>(infile, dom).view());
+    in = imag(Load_view<2, cscalar_f>(infile, dom, vsip::Local_map(), swap_bytes).view());
   else if (format == SCALAR_FLOAT)
-    in = Load_view<2, scalar_f>(infile, dom).view();
+    in = Load_view<2, scalar_f>(infile, dom, vsip::Local_map(), swap_bytes).view();
   else if (format == SCALAR_INTEGER)
-    in = Load_view<2, scalar_i>(infile, dom).view();
+    in = Load_view<2, scalar_i>(infile, dom, vsip::Local_map(), swap_bytes).view();
   else
     cerr << "Error: format type " << format << " not supported." << endl;
 
Index: apps/ssar/ssar.cpp
===================================================================
--- apps/ssar/ssar.cpp	(revision 217117)
+++ apps/ssar/ssar.cpp	(working copy)
@@ -19,7 +19,9 @@
 #include <vsip/initfin.hpp>
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
+#include <vsip_csl/output.hpp>
 
+using namespace vsip_csl;
 using namespace vsip;
 using namespace std;
 
@@ -38,7 +40,7 @@
 struct
 ssar_options
 {
-  length_type scale;
+  scalar_f scale;
   length_type n;
   length_type mc;
   length_type m;
@@ -51,8 +53,12 @@
 
 int loop = 1;  // Number of process_image iterations to perform (default 1)
 
+#if _BIG_ENDIAN
+bool swap_bytes = true;   // Whether or not to swap bytes during file I/O
+#else
+bool swap_bytes = false;
+#endif
 
-
 int
 main(int argc, char** argv)
 {
@@ -69,7 +75,7 @@
   // Setup for Stage 1, Kernel 1 
   vsip::impl::profile::Acc_timer t0;
   t0.start();
-  Kernel1<T> k1(opt.scale, opt.n, opt.mc, opt.m); 
+  Kernel1<T> k1(opt.scale, opt.n, opt.mc, opt.m, swap_bytes); 
   t0.stop();
   cout << "setup:   " << t0.delta() << " (s)" << endl;
 
@@ -77,7 +83,7 @@
   // component is currently untimed.
   Kernel1<T>::complex_matrix_type s_raw(opt.n, opt.mc);
   load_view_as<complex<float>, 
-    Kernel1<T>::complex_matrix_type>(RAW_SAR_DATA, s_raw);
+    Kernel1<T>::complex_matrix_type>(RAW_SAR_DATA, s_raw, swap_bytes);
 
   // Resolve the image.  This Computation component is timed.
   Kernel1<T>::real_matrix_type 
@@ -106,7 +112,7 @@
   }
 
   // Store the image on disk for later processing (not timed).
-  save_view_as<float>("image.view", image); 
+  save_view_as<float>("image.view", image, swap_bytes); 
 }
 
 
@@ -118,11 +124,13 @@
   for (int i=1; i<argc; ++i)
   {
     if (!strcmp(argv[i], "-loop")) loop = atoi(argv[++i]);
+    else if (!strcmp(argv[i], "-swap")) swap_bytes = true;
+    else if (!strcmp(argv[i], "-noswap")) swap_bytes = false;
     else if (dir == 0) dir = argv[i];
     else
     {
       cerr << "Unknown arg: " << argv[i] << endl;
-      cerr << "Usage: " << argv[0] << " [-loop] <data dir>" << endl;
+      cerr << "Usage: " << argv[0] << " [-loop] <data dir> [-swap|-noswap]" << endl;
       exit(-1);
     }
   }
@@ -130,7 +138,7 @@
   if (dir == 0)
   {
       cerr << "No dir given" << endl;
-      cerr << "Usage: " << argv[0] << " [-loop] <data dir>" << endl;
+      cerr << "Usage: " << argv[0] << " [-loop] <data dir> [-swap|-noswap]" << endl;
       exit(-1);
   }
 
Index: apps/ssar/data1/uc.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/data1/uc.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/data1/ftfilt.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/data1/ftfilt.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/data1/k.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/data1/k.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/data1/ku.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/data1/ku.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/data1/dims.txt
===================================================================
--- apps/ssar/data1/dims.txt	(revision 0)
+++ apps/ssar/data1/dims.txt	(revision 0)
@@ -0,0 +1,4 @@
+1
+438
+160
+382
Index: apps/ssar/data1/u.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/data1/u.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/data1/sar.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/data1/sar.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/make_images.sh
===================================================================
--- apps/ssar/make_images.sh	(revision 217117)
+++ apps/ssar/make_images.sh	(working copy)
@@ -1,23 +1,65 @@
 #! /bin/sh
 
-# This script creates images from the intermediate images produced during
-# Kernel 1 processing (when VERBOSE is defined in kernel1.hpp).
+# Copyright (c) 2008 by CodeSourcery.  All rights reserved.
 #
+#  This file is available for license from CodeSourcery, Inc. under the terms
+#  of a commercial license and under the GPL.  It is not part of the VSIPL++
+#   reference implementation and is not available under the BSD license.
+#
+#   @file    make_images.sh
+#   @author  Don McCoy
+#   @date    2008-08-19
+#   @brief   VSIPL++ implementation of SSCA #3: Kernel 1, Image Formation
+
+# This script creates images from the input and output raw data files produced 
+# during Kernel 1 processing.  It also creates intermediate images from the
+# VSIPL++ views that are saved when VERBOSE is defined in kernel1.hpp (these
+# are helpful in diagnosing problems and/or providing visual feedback as to
+# what is occuring during each stage of processing).
+#
 # Requires 'rawtopgm' and 'viewtoraw' (the source for the latter is included).
 
-echo "converting to raw greyscale..."
-./viewtoraw set1/sar.view set1/p00_sar.raw 1072 480
-./viewtoraw -r set1/p76_fs_ref.view set1/p76_fs_ref.raw 1072 1144
-./viewtoraw set1/p77_fsm.view set1/p77_fsm.raw 1072 1144
-./viewtoraw set1/p92_F.view set1/p92_F.raw 756 1144
-./viewtoraw -s set1/image.view set1/p95_image.raw 1144 756
+# Parameters
+#   dir    The directory where the image files are located (data1, data3, ...)
+#   n      Input image rows
+#   mc     Input image columns
+#   m      Output image rows
+#   nx     Output image columns
 
-echo "converting to set1/pgm format..."
-rawtopgm 480 1072 set1/p00_sar.raw > set1/p00_sar.pgm
-rawtopgm 1144 1072 set1/p76_fs_ref.raw > set1/p76_fs_ref.pgm
-rawtopgm 1144 1072 set1/p77_fsm.raw > set1/p77_fsm.pgm
-rawtopgm 1144 756 set1/p92_F.raw > set1/p92_F.pgm
-rawtopgm 756 1144 set1/p95_image.raw > set1/p95_image.pgm
+# Usage
+#   ./make_images.sh DIR N MC M NX
 
-echo "cleaning up raw files..."
-rm set1/p*.raw
+dir=$1
+n=$2
+mc=$3
+m=$4
+nx=$5
+
+echo "Converting to raw greyscale..."
+./viewtoraw $dir/sar.view $dir/p00_sar.raw $n $mc
+if [ -f $dir/p76_fs_ref.view ]; then 
+    ./viewtoraw -r $dir/p76_fs_ref.view $dir/p76_fs_ref.raw $n $m
+fi
+if [ -f $dir/p77_fsm.view ]; then 
+    ./viewtoraw $dir/p77_fsm.view $dir/p77_fsm.raw $n $m
+fi
+if [ -f $dir/p92_F.view ]; then 
+    ./viewtoraw $dir/p92_F.view $dir/p92_F.raw $nx $m
+fi
+./viewtoraw -s $dir/image.view $dir/p95_image.raw $m $nx
+
+echo "Converting to $dir/pgm format..."
+rawtopgm $mc $n $dir/p00_sar.raw > $dir/p00_sar.pgm
+if [ -f $dir/p76_fs_ref.raw ]; then 
+    rawtopgm $m $n $dir/p76_fs_ref.raw > $dir/p76_fs_ref.pgm
+fi
+if [ -f $dir/p77_fsm.raw ]; then 
+    rawtopgm $m $n $dir/p77_fsm.raw > $dir/p77_fsm.pgm
+fi
+if [ -f $dir/p92_F.raw ]; then 
+    rawtopgm $m $nx $dir/p92_F.raw > $dir/p92_F.pgm
+fi
+rawtopgm $nx $m $dir/p95_image.raw > $dir/p95_image.pgm
+
+echo "Cleaning up raw files..."
+rm -f $dir/p*.raw
Index: apps/ssar/set1/uc.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream
Index: apps/ssar/set1/ftfilt.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream
Index: apps/ssar/set1/k.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream
Index: apps/ssar/set1/ku.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream
Index: apps/ssar/set1/ref_image_sp.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream
Index: apps/ssar/set1/dims.txt
===================================================================
--- apps/ssar/set1/dims.txt	(revision 218079)
+++ apps/ssar/set1/dims.txt	(working copy)
@@ -1,4 +0,0 @@
-3
-1072
-480
-1144
Index: apps/ssar/set1/ref_image_dp.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream
Index: apps/ssar/set1/u.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream
Index: apps/ssar/set1/sar.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream
Index: apps/ssar/README
===================================================================
--- apps/ssar/README	(revision 217117)
+++ apps/ssar/README	(working copy)
@@ -26,17 +26,24 @@
 retrieval as well as target detection through image differencing.
 
 
-Run the benchmark by specifying the any one of these commands:
+Run the benchmark or execute other functions by specifying the any one of 
+the following commands:
 
   make		Build the benchmark
 
-  make clean	Removed temporary files.
+  make show	Show which VSIPL++ package is selected, along with the
+                values of CXX, CXXFLAGS and LIBS.
 
+  make clean	Remove temporary files.
+
   make check	Run the benchmark, comparing output to a known reference
 		(produced by the HPCS version that runs under Matlab).
+		The default uses data from the data3/ subdirectory (for
+		which the scale factor is 3).
 
-  make profile	Use the built-in profiling capabilities of the library
-		to investigate application timing.
+  make profileN	Use the built-in profiling capabilities of the library
+		to investigate application timing.  N defines the scale
+		factor and the dataN/ sub-directory contains the data files.
 
 		
 Notes
