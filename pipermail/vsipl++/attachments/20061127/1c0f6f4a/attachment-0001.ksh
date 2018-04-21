Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 155796)
+++ GNUmakefile.in	(working copy)
@@ -55,6 +55,7 @@
 libdir := @libdir@
 builtin_libdir := @builtin_libdir@
 sbindir := @sbindir@
+bindir := @bindir@
 # The directory for putting data that is specific to this package.
 # This is not a standard variable name.
 pkgdatadir := $(datadir)/$(PACKAGE_TARNAME)
@@ -474,6 +475,8 @@
 	$(install_pc)
 	$(INSTALL) -d $(DESTDIR)$(sbindir)
 	$(INSTALL_SCRIPT) $(srcdir)/scripts/set-prefix.sh $(DESTDIR)$(sbindir)
+	$(INSTALL) -d $(DESTDIR)$(bindir)
+	$(INSTALL_SCRIPT) $(srcdir)/scripts/fmt-profile.pl $(DESTDIR)$(bindir)
 	$(INSTALL) -d $(DESTDIR)$(docdir)
 	$(INSTALL_SCRIPT) $(srcdir)/README.bin-pkg $(DESTDIR)$(docdir)
 
Index: apps/ssar/GNUmakefile
===================================================================
--- apps/ssar/GNUmakefile	(revision 155796)
+++ apps/ssar/GNUmakefile	(working copy)
@@ -1,4 +1,4 @@
-########################################################################
+######################################################### -*-Makefile-*-
 #
 # File:   apps/ssar/Makefile
 # Author: Don McCoy
@@ -21,6 +21,17 @@
 # /usr/local/lib/pkgconfig/ directory for a complete list of packages.
 suffix = -ser-builtin-32
 
+# The default precision is single (double may also be used)
+precision = single
+
+ifeq ($(precision),double)
+ref_image_base = ref_image_dp
+ssar_type = SSAR_BASE_TYPE=double
+else
+ref_image_base = ref_image_sp
+ssar_type = SSAR_BASE_TYPE=float
+endif
+
 pkgcommand := PKG_CONFIG_PATH=$(prefix)/lib/pkgconfig 	\
                      pkg-config vsipl++$(suffix) 	\
                      --define-variable=prefix=$(prefix)
@@ -28,7 +39,7 @@
 CXX      = $(shell ${pkgcommand} --variable=cxx)
 CXXFLAGS = $(shell ${pkgcommand} --cflags) \
 	   $(shell ${pkgcommand} --variable=cxxflags) \
-	   -DVSIP_IMPL_PROFILER=15
+	   -DVSIP_IMPL_PROFILER=11 -D$(ssar_type)
 LIBS     = $(shell ${pkgcommand} --libs)
  
 
@@ -49,7 +60,7 @@
 	./ssar set1
 	@echo
 	@echo "Comparing output to reference view (should be less than -100)"
-	./diffview -r set1/image.view set1/ref_image.view 756 1144
+	./diffview -r set1/image.view set1/$(ref_image_base).view 756 1144
 	@echo
 	@echo "Creating viewable image of output"
 	./viewtoraw -s set1/image.view set1/image.raw 1144 756
@@ -57,10 +68,15 @@
 	rm set1/image.raw
 	@echo
 	@echo "Creating viewable image of reference view"
-	./viewtoraw -s set1/ref_image.view set1/ref_image.raw 1144 756
-	rawtopgm 756 1144 set1/ref_image.raw > set1/ref_image.pgm
-	rm set1/ref_image.raw
+	./viewtoraw -s set1/$(ref_image_base).view set1/$(ref_image_base).raw 1144 756
+	rawtopgm 756 1144 set1/$(ref_image_base).raw > set1/$(ref_image_base).pgm
+	rm set1/$(ref_image_base).raw
 
+profile: ssar
+	@echo "Profiling SSAR application..."
+	./ssar set1 -loop 10 --vsipl++-profile-mode=accum --vsipl++-profile-output=profile.out
+	@echo "Formatting profiler output..."
+	$(prefix)/bin/fmt-profile.pl -sec -o profile.txt set1/profile.out
 
 ssar.o: ssar.cpp kernel1.hpp
 
Index: apps/ssar/kernel1.hpp
===================================================================
--- apps/ssar/kernel1.hpp	(revision 155797)
+++ apps/ssar/kernel1.hpp	(working copy)
@@ -21,15 +21,6 @@
 #define SAVE_VIEW(a, b)
 #endif
 
-// Files required to be in the data directory:
-char const* SAR_DIMENSIONS =                         "dims.txt";
-char const* RAW_SAR_DATA =                           "sar.view";
-char const* FAST_TIME_FILTER =                       "ftfilt.view";
-char const* SLOW_TIME_WAVENUMBER =                   "k.view";
-char const* SLOW_TIME_COMPRESSED_APERTURE_POSITION = "uc.view";
-char const* SLOW_TIME_APERTURE_POSITION =            "u.view";
-char const* SLOW_TIME_SPATIAL_FREQUENCY =            "ku.view";
-
 template <typename T>
 class Kernel1_base
 {
@@ -449,8 +440,6 @@
     fs_spotlit_(center_dst) = T();
     fs_spotlit_(right_dst)  = fs_row_(right_src);
 
-    SAVE_VIEW("p65_fs_padded.view", fftshift(fs_spotlit_));
-
     // 66. (n by m array of complex numbers) transform-back the zero 
     //     padded spatial spectrum along its cross-range
     decompr_fft_(fs_spotlit_);
@@ -459,8 +448,6 @@
     //     that to view 'sDecompr' it will need to be fftshifted first.)
     fs_spotlit_ *= s_decompr_filt_.row(i);
 
-    SAVE_VIEW("p68_s_decompr.view", fftshift(fs_spotlit_));
-
     // 69. (n by m array of complex numbers) digitally-spotlighted SAR 
     //     signal spectrum
     st_fft_(fs_spotlit_);
@@ -484,10 +471,6 @@
   }
 
   SAVE_VIEW("p77_fsm.view", fsm_);
-
-#ifdef VERBOSE
-  std::cout << "mz = " << mz << std::endl;
-#endif
 }
 
 
Index: apps/ssar/make_set1_images.sh
===================================================================
--- apps/ssar/make_set1_images.sh	(revision 155796)
+++ apps/ssar/make_set1_images.sh	(working copy)
@@ -7,21 +7,15 @@
 
 echo "converting to raw greyscale..."
 ./viewtoraw set1/sar.view set1/p00_sar.raw 1072 480
-./viewtoraw set1/p62_s_compr.view set1/p62_s_compr.raw 1072 480
-./viewtoraw set1/p65_fs_padded.view set1/p65_fs_padded.raw 1072 1144
-./viewtoraw set1/p68_s_decompr.view set1/p68_s_decompr.raw 1072 1144
-./viewtoraw set1/p69_fs_spotlit.view set1/p69_fs_spotlit.raw 1072 1144
 ./viewtoraw -r set1/p76_fs_ref.view set1/p76_fs_ref.raw 1072 1144
+./viewtoraw set1/p77_fsm.view set1/p77_fsm.raw 1072 1144
 ./viewtoraw set1/p92_F.view set1/p92_F.raw 756 1144
 ./viewtoraw -s set1/image.view set1/p95_image.raw 1144 756
 
 echo "converting to set1/pgm format..."
 rawtopgm 480 1072 set1/p00_sar.raw > set1/p00_sar.pgm
-rawtopgm 480 1072 set1/p62_s_compr.raw > set1/p62_s_compr.pgm
-rawtopgm 1144 1072 set1/p65_fs_padded.raw > set1/p65_fs_padded.pgm
-rawtopgm 1144 1072 set1/p68_s_decompr.raw > set1/p68_s_decompr.pgm
-rawtopgm 1144 1072 set1/p69_fs_spotlit.raw > set1/p69_fs_spotlit.pgm
 rawtopgm 1144 1072 set1/p76_fs_ref.raw > set1/p76_fs_ref.pgm
+rawtopgm 1144 1072 set1/p77_fsm.raw > set1/p77_fsm.pgm
 rawtopgm 1144 756 set1/p92_F.raw > set1/p92_F.pgm
 rawtopgm 756 1144 set1/p95_image.raw > set1/p95_image.pgm
 
Index: apps/ssar/ssar.cpp
===================================================================
--- apps/ssar/ssar.cpp	(revision 155797)
+++ apps/ssar/ssar.cpp	(working copy)
@@ -19,6 +19,16 @@
 using namespace vsip;
 using namespace std;
 
+// Files required to be in the data directory (must be included 
+// before kernel1.hpp):
+char const* SAR_DIMENSIONS =                         "dims.txt";
+char const* RAW_SAR_DATA =                           "sar.view";
+char const* FAST_TIME_FILTER =                       "ftfilt.view";
+char const* SLOW_TIME_WAVENUMBER =                   "k.view";
+char const* SLOW_TIME_COMPRESSED_APERTURE_POSITION = "uc.view";
+char const* SLOW_TIME_APERTURE_POSITION =            "u.view";
+char const* SLOW_TIME_SPATIAL_FREQUENCY =            "ku.view";
+
 #include "kernel1.hpp"
 
 struct
@@ -50,7 +60,7 @@
   ssar_options opt;
   process_ssar_options(argc, argv, opt);
 
-  typedef float T;
+  typedef SSAR_BASE_TYPE T;
 
   // Setup for Stage 1, Kernel 1 
   vsip::impl::profile::Acc_timer t0;
Index: apps/ssar/set1/ref_image.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream
Index: apps/ssar/set1/ref_image_sp.view
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: apps/ssar/set1/ref_image_sp.view
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: apps/ssar/README
===================================================================
--- apps/ssar/README	(revision 0)
+++ apps/ssar/README	(revision 0)
@@ -0,0 +1,61 @@
+=============================================================================
+Scalable SAR (SSAR) Application Benchmark
+Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+=============================================================================
+
+This directory contains the Sourcery VSIPL++ implementation of an
+application benchmark that is part of the High Performance Embedded 
+Computing (HPEC) "Challenge Benchmark Suite" from MIT's Lincoln Laboratory.
+
+  http://www.ll.mit.edu/HPECchallenge/sar.html
+
+This benchmark is also part of the High Productivity Computing 
+Systems (HPCS) Scalable Synthetic Compact Application #3 (SSCA #3).
+
+  http://www.highproductivity.org/SSCABmks.htm
+
+
+In brief, the application showcases several computationally-intensive 
+operations typically found in radar data processing applications.  At 
+present, this application focus on the first stage - image formation 
+from raw radar signal returns.  Later stages deal with image storage and 
+retrieval as well as target detection through image differencing.
+
+
+Run the benchmark by specifying the any one of these commands:
+
+  make		Build the benchmark
+
+  make clean	Removed temporary files.
+
+  make check	Run the benchmark, comparing output to a known reference
+		(produced by the HPCS version that runs under Matlab).
+
+  make profile	Use the built-in profiling capabilities of the library
+		to investigate application timing.
+
+		
+Notes
+
+  The makefile assumes the default install location of /usr/local.  If 
+  Sourcery VSIPL++ is installed in a non-standard location, edit the
+  'prefix=...' line in the makefile or pass the correctly value on
+  the command line ('make prefix=/path/to/vsipl++').
+
+  The application may perform computations using either single or double-
+  precision floating point.  Use 'precision=double' in the makefile
+  as desired.
+
+  All data read from or written to disk is single-precision, regardless
+  of the computational mode.
+
+  The validation step uses a utility called 'diffview' (provided) that
+  is used to compare the generated output to the reference output.  It
+  also converts the data to a greyscale using 'viewtoraw' (also 
+  provided) and then to a viewable image using 'rawtopgm' (part of
+  the Netpbm package).  
+
+  Creating the viewable images is not necessary to validate the images, 
+  but it is helpful.  The synthesized data is of a field of rectangularly
+  spaced corner reflectors that appear as bright spots within an 
+  otherwise dark background.
