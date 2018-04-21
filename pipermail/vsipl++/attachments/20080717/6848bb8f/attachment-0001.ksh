Index: diffview.cpp
===================================================================
--- diffview.cpp	(revision 211570)
+++ diffview.cpp	(working copy)
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
Index: GNUmakefile
===================================================================
--- GNUmakefile	(revision 211570)
+++ GNUmakefile	(working copy)
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
 
 
@@ -60,6 +62,12 @@
 
 all: ssar viewtoraw diffview
 
+show:
+	@echo "pkgcommand: " $(pkgcommand)
+	@echo "CXX       : " $(CXX)
+	@echo "CXXFLAGS  : " $(CXXFLAGS)
+	@echo "LIBS      : " $(LIBS)
+
 clean: 
 	rm *.o
 	rm ssar
@@ -87,7 +95,7 @@
 	@echo "Profiling SSAR application..."
 	./ssar set1 -loop 10 --vsipl++-profile-mode=accum --vsipl++-profile-output=profile.out
 	@echo "Formatting profiler output..."
-	$(prefix)/bin/fmt-profile.pl -sec -o profile.txt set1/profile.out
+	${fmt-profile-command} -sec -o profile.txt set1/profile.out
 
 ssar.o: ssar.cpp kernel1.hpp
 
Index: kernel1.hpp
===================================================================
--- kernel1.hpp	(revision 211570)
+++ kernel1.hpp	(working copy)
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
@@ -37,13 +37,14 @@
   typedef Vector<T> real_vector_type;
 
   Kernel1_base(length_type scale, length_type n, length_type mc, 
-    length_type m);
+    length_type m, bool swap_bytes);
   ~Kernel1_base() {}
 
   length_type scale_;
   length_type n_;
   length_type mc_;
   length_type m_;
+  bool swap_bytes_;
   length_type nx_;
   length_type interp_sidelobes_;
   length_type I_;
@@ -67,8 +68,8 @@
 
 template <typename T>
 Kernel1_base<T>::Kernel1_base(length_type scale, length_type n, 
-  length_type mc, length_type m)
-  : scale_(scale), n_(n), mc_(mc), m_(m),
+  length_type mc, length_type m, bool swap_bytes)
+  : scale_(scale), n_(n), mc_(mc), m_(m), swap_bytes_(swap_bytes),
     fast_time_filter_(n),
     fs_ref_(n, m),
     ks_(n),
@@ -78,6 +79,7 @@
 {
   using vsip_csl::matlab::fftshift;
   using vsip_csl::load_view_as;
+  using vsip_csl::save_view_as;
 
   interp_sidelobes_ = 8;     // 2. (scalar, integer) number of 
                              //    neighboring sidelobes used in sinc interp.
@@ -117,12 +119,12 @@
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
@@ -174,7 +176,7 @@
   fs_ref_ = ite(kx_ > 0, exp(complex<T>(0, 1) * 
     (Xc_ * (kx_ - 2 * k1) + T(0.25 * M_PI) + ku)), complex<T>(0));
 
-  SAVE_VIEW("p76_fs_ref.view", fs_ref_);
+  SAVE_VIEW("p76_fs_ref.view", fs_ref_, swap_bytes_);
 
   // 78. (scalar, int) interpolation processing sliver size
   I_ = 2 * interp_sidelobes_ + 1;
@@ -187,7 +189,6 @@
   //     indexing in interpolation loop)
   nx_ = nx0 + 2 * interp_sidelobes_ + 4;
 
-
 #ifdef VERBOSE
   std::cout << "kx_min = " << kx_min_ << std::endl;
   std::cout << "kx_max = " << kx_max << std::endl;
@@ -224,7 +225,8 @@
   typedef Fftm<complex<T>, complex<T>, row, fft_inv, by_reference> inv_row_fftm_type;
   typedef Fftm<complex<T>, complex<T>, col, fft_inv, by_reference> inv_col_fftm_type;
 
-  Kernel1(length_type scale, length_type n, length_type mc, length_type m);
+  Kernel1(length_type scale, length_type n, length_type mc, length_type m, 
+    bool swap_bytes);
   ~Kernel1() {}
 
   void process_image(complex_matrix_type const input, 
@@ -276,8 +278,8 @@
 
 template <typename T>
 Kernel1<T>::Kernel1(length_type scale, length_type n, length_type mc, 
-  length_type m)
-  : Kernel1_base<T>(scale, n, mc, m),
+  length_type m, bool swap_bytes)
+  : Kernel1_base<T>(scale, n, mc, m, swap_bytes),
     scale_(scale), n_(n), mc_(mc), m_(m), 
     s_filt_(n, mc),
     s_filt_t_(n, mc),
@@ -351,7 +353,6 @@
             (nKX - this->kx_.get(i, j)))) );
       }
     }
-
 }
 
 
@@ -474,7 +475,7 @@
     fsm_.row(xr)(rdom) = fs_spotlit_(ldom) * this->fs_ref_.row(xr)(rdom);
   }
 
-  SAVE_VIEW("p77_fsm.view", fsm_);
+  SAVE_VIEW("p77_fsm.view", fsm_, this->swap_bytes_);
 }
 
 
@@ -520,7 +521,7 @@
   } // 93. end the range loop
   }
 
-  SAVE_VIEW("p92_F.view", F_);
+  SAVE_VIEW("p92_F.view", F_, this->swap_bytes_);
 
 
   // transform from the Doppler domain image into a spatial domain image
Index: make_set1_images.sh
===================================================================
--- make_set1_images.sh	(revision 211570)
+++ make_set1_images.sh	(working copy)
@@ -6,11 +6,11 @@
 # Requires 'rawtopgm' and 'viewtoraw' (the source for the latter is included).
 
 echo "converting to raw greyscale..."
-./viewtoraw set1/sar.view set1/p00_sar.raw 1072 480
+./viewtoraw    set1/sar.view        set1/p00_sar.raw    1072  480
 ./viewtoraw -r set1/p76_fs_ref.view set1/p76_fs_ref.raw 1072 1144
-./viewtoraw set1/p77_fsm.view set1/p77_fsm.raw 1072 1144
-./viewtoraw set1/p92_F.view set1/p92_F.raw 756 1144
-./viewtoraw -s set1/image.view set1/p95_image.raw 1144 756
+./viewtoraw    set1/p77_fsm.view    set1/p77_fsm.raw    1072 1144
+./viewtoraw    set1/p92_F.view      set1/p92_F.raw       756 1144
+./viewtoraw -s set1/image.view      set1/p95_image.raw  1144  756
 
 echo "converting to set1/pgm format..."
 rawtopgm 480 1072 set1/p00_sar.raw > set1/p00_sar.pgm
Index: viewtoraw.cpp
===================================================================
--- viewtoraw.cpp	(revision 211570)
+++ viewtoraw.cpp	(working copy)
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
 
Index: ssar.cpp
===================================================================
--- ssar.cpp	(revision 211570)
+++ ssar.cpp	(working copy)
@@ -19,7 +19,9 @@
 #include <vsip/initfin.hpp>
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
+#include <vsip_csl/output.hpp>
 
+using namespace vsip_csl;
 using namespace vsip;
 using namespace std;
 
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
 
