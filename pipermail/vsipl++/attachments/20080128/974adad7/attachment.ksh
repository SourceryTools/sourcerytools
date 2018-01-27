Index: ChangeLog
===================================================================
--- ChangeLog	(revision 191870)
+++ ChangeLog	(working copy)
@@ -1,3 +1,12 @@
+2008-01-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/fft.hpp (fftm_facade): Make friends with Diagnose_fftm.
+	* src/vsip/opt/diag/fft.hpp: Diagnosis routines for Fftm.
+	* vendor/GNUmakefile.inc.in (clean): Clean vendor libraries from lib/
+	* benchmarks/fftm.cpp: Use new diagnosis routines.  Pass fixed row
+	  column dimension to diag.  Guard available cases on FFT provisioning.
+	* benchmarks/fft.cpp: Guard available cases on FFT provisioning.
+
 2008-01-23  Don McCoy  <don@codesourcery.com>
 
 	* m4/cvsip.m4: Changed --enable-cvsip to --with-cvsip.
@@ -28,7 +37,7 @@
 
 	* src/vsip_csl/img/impl/pwarp_gen.hpp: Fix indexing error.
 
-2007-01-09  Jules Bergmann  <jules@codesourcery.com>
+2008-01-09  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/diag/eval.hpp: Include necessary headers.
 	* src/vsip/opt/expr/serial_dispatch_fwd.hpp: Likewise.
Index: src/vsip/core/fft.hpp
===================================================================
--- src/vsip/core/fft.hpp	(revision 191870)
+++ src/vsip/core/fft.hpp	(working copy)
@@ -1,4 +1,5 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2006, 2007, 2008 by CodeSourcery, LLC. 
+   All rights reserved. */
 
 /** @file    vsip/core/fft.hpp
     @author  Stefan Seefeld
@@ -72,6 +73,7 @@
 namespace diag_detail
 {
 struct Diagnose_fft;
+struct Diagnose_fftm;
 }
 
 namespace fft
@@ -417,6 +419,7 @@
  }
 #endif
 
+  friend class vsip::impl::diag_detail::Diagnose_fftm;
 private:
   std::auto_ptr<typename fft::fftm<I, O, axis, exponent> > backend_;
   workspace workspace_;
@@ -493,6 +496,7 @@
     return inout;
   }
 
+  friend class vsip::impl::diag_detail::Diagnose_fftm;
 private:
   std::auto_ptr<typename fft::fftm<I, O, axis, exponent> > backend_;
   workspace workspace_;
Index: src/vsip/opt/diag/fft.hpp
===================================================================
--- src/vsip/opt/diag/fft.hpp	(revision 191870)
+++ src/vsip/opt/diag/fft.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2007, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -93,6 +93,26 @@
 
 
 
+template <typename FftmT>
+struct Fftm_traits;
+
+template <typename              I,
+	  typename              O,
+	  int                   A,
+	  int                   D,
+	  return_mechanism_type R,
+	  unsigned              N,
+	  alg_hint_type         H>
+struct Fftm_traits<Fftm<I, O, A, D, R, N, H> >
+{
+  static dimension_type        const dim  = 2;
+  static int                   const axis = A;
+  static int                   const dir  = D;
+  static return_mechanism_type const rm   = R;
+};
+
+
+
 struct Diagnose_fft
 {
   template <typename FftT>
@@ -192,6 +212,32 @@
   }
 };
 
+
+
+struct Diagnose_fftm
+{
+  template <typename FftmT>
+  static void diag(std::string name, FftmT const& fftm)
+  {
+    using diag_detail::Class_name;
+    using std::cout;
+    using std::endl;
+
+    typedef Fftm_traits<FftmT> traits;
+
+    cout << "diagnose_fftm(" << name << ")" << endl
+	 << "  dim : " << traits::dim << endl
+	 << "  i sz: " << fftm.input_size()[0].size() << " x "
+	               << fftm.input_size()[1].size() << endl
+	 << "  o sz: " << fftm.output_size()[0].size() << " x "
+	               << fftm.output_size()[1].size() << endl
+	 << "  dir : " << (traits::dir == fft_fwd ? "fwd" : "inv") << endl
+	 << "  axis: " << (traits::axis == row ? "row" : "col") << endl
+	 << "  rm  : " << (traits::rm == by_value ? "val" : "ref") << endl
+	 << "  be  : " << fftm.backend_.get()->name() << endl;
+  }
+};
+
 } // namespace vsip::impl::diag_detail
 
 
@@ -219,6 +265,15 @@
   diag_detail::Diagnose_fft::diag_call<FftT>(name, fft, in, out);
 }
 
+
+
+template <typename FftmT>
+void
+diagnose_fftm(std::string name, FftmT const& fftm)
+{
+  diag_detail::Diagnose_fftm::diag<FftmT>(name, fftm);
+}
+
 } // namespace vsip::impl
 } // namespace vsip
 
Index: vendor/GNUmakefile.inc.in
===================================================================
--- vendor/GNUmakefile.inc.in	(revision 191870)
+++ vendor/GNUmakefile.inc.in	(working copy)
@@ -124,6 +124,9 @@
 
 lib/libf77blas.a: vendor/atlas/lib/libf77blas.a
 	cp $< $@
+
+clean::
+	rm -f lib/libf77blas.a
 endif
 
 ifdef USE_ATLAS_LAPACK
@@ -143,6 +146,7 @@
 	rm -f vendor/atlas/lib/libcblas.a lib/libcblas.a
 	rm -f $(vendor_MERGED_LAPACK) lib/liblapack.a
 	rm -f $(vendor_PRE_LAPACK)
+	rm -f lib/libcblas.a lib/libatlas.a lib/liblapack.a
 
 libs += lib/libatlas.a lib/libcblas.a lib/liblapack.a
 
@@ -169,6 +173,9 @@
 	cp $< $@
 lib/libblas.a: vendor/clapack/libblas.a
 	cp $< $@
+
+clean::
+	rm -f lib/liblapack.a lib/libblas.a
 endif
 
 
@@ -249,6 +256,7 @@
 	@for ldir in $(subst .a,,$(subst lib/lib,,$(vendor_FFTW_LIBS))); do \
 	  $(MAKE) -C vendor/$$ldir clean >> fftw.clean.log 2>&1; \
 	  echo "$(MAKE) -C vendor/$$ldir clean "; done
+	rm -f lib/libfftw3.a lib/libfftw3f.a lib/libfftw3l.a
 
 install:: $(vendor_FFTW_LIBS)
 	@echo "Installing FFTW"
Index: benchmarks/fftm.cpp
===================================================================
--- benchmarks/fftm.cpp	(revision 191870)
+++ benchmarks/fftm.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -22,6 +22,7 @@
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
 #include <vsip/opt/profile.hpp>
+#include <vsip/opt/diag/fft.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
@@ -111,6 +112,21 @@
     time = t1.delta();
   }
 
+  void diag_rc(length_type rows, length_type cols)
+  {
+    Matrix<T>   A(rows, cols, T());
+    Matrix<T>   Z(rows, cols);
+
+    typedef Fftm<T, T, SD, fft_fwd, by_reference, no_times, alg_time>
+      fftm_type;
+
+    length_type size = SD == row ? cols : rows;
+
+    fftm_type fftm(Domain<2>(rows, cols), scale_ ? (1.f/size) : 1.f);
+
+    diagnose_fftm("fftm_op", fftm);
+  }
+
   t_fftm(bool scale) : scale_(scale) {}
 
   // Member data
@@ -163,6 +179,11 @@
     time = t1.delta();
   }
 
+  void diag_rc(length_type rows, length_type cols)
+  {
+    std::cout << "No diag\n";
+  }
+
   t_fftm(bool scale) : scale_(scale) {}
 
   // Member data
@@ -230,6 +251,11 @@
     time = t1.delta();
   }
 
+  void diag_rc(length_type rows, length_type cols)
+  {
+    std::cout << "No diag\n";
+  }
+
   t_fftm(bool scale) : scale_(scale) {}
 
   // Member data
@@ -299,6 +325,11 @@
     time = t1.delta();
   }
 
+  void diag_rc(length_type rows, length_type cols)
+  {
+    std::cout << "No diag\n";
+  }
+
   t_fftm(bool scale) : scale_(scale) {}
 
   // Member data
@@ -381,6 +412,11 @@
     time = t1.delta();
   }
 
+  void diag_rc(length_type rows, length_type cols)
+  {
+    std::cout << "No diag\n";
+  }
+
   t_fftm(bool scale) : scale_(scale) {}
 
   // Member data
@@ -429,6 +465,11 @@
     time = t1.delta();
   }
 
+  void diag_rc(length_type rows, length_type cols)
+  {
+    std::cout << "No diag\n";
+  }
+
   t_fftm(bool scale) : scale_(scale) {}
 
   // Member data
@@ -460,6 +501,11 @@
     this->fftm(rows_, cols, loop, time);
   }
 
+  void diag()
+  {
+    this->diag_rc(rows_, (vsip::length_type)1024);
+  }
+
   t_fftm_fix_rows(length_type rows, bool scale)
     : base_type(scale), rows_(rows)
   {}
@@ -492,6 +538,11 @@
     this->fftm(rows, cols_, loop, time);
   }
 
+  void diag()
+  {
+    this->diag_rc((vsip::length_type)64, cols_);
+  }
+
   t_fftm_fix_cols(length_type cols, bool scale)
     : base_type(scale), cols_(cols)
   {}
@@ -506,14 +557,16 @@
   Main definitions
 ***********************************************************************/
 
-
 void
 defaults(Loop1P& loop)
 {
   loop.start_      = 4;
   loop.stop_       = 16;
   loop.loop_start_ = 10;
-  loop.user_param_ = 64;
+
+  loop.param_["rows"] = "64";
+  loop.param_["size"] = "2048";
+  loop.param_["scale"] = "0";
 }
 
 
@@ -521,26 +574,30 @@
 int
 test(Loop1P& loop, int what)
 {
-  length_type p = loop.user_param_;
+  length_type rows  = atoi(loop.param_["rows"].c_str());
+  length_type size  = atoi(loop.param_["size"].c_str());
+  bool scale  = (loop.param_["size"] == "1" ||
+		 loop.param_["size"] == "y");
 
   typedef complex<float>  Cf;
   typedef complex<double> Cd;
 
   switch (what)
   {
-  case  1: loop(t_fftm_fix_rows<Cf, Impl_op,   row>(p, false)); break;
-  case  2: loop(t_fftm_fix_rows<Cf, Impl_ip,   row>(p, false)); break;
-  case  3: loop(t_fftm_fix_rows<Cf, Impl_pop,  row>(p, false)); break;
-  case  4: loop(t_fftm_fix_rows<Cf, Impl_pip1, row>(p, false)); break;
-  case  5: loop(t_fftm_fix_rows<Cf, Impl_pip2, row>(p, false)); break;
-  case  6: loop(t_fftm_fix_rows<Cf, Impl_bv,   row>(p, false)); break;
+#if VSIP_IMPL_PROVIDE_FFT_FLOAT
+  case  1: loop(t_fftm_fix_rows<Cf, Impl_op,   row>(rows, scale)); break;
+  case  2: loop(t_fftm_fix_rows<Cf, Impl_ip,   row>(rows, false)); break;
+  case  3: loop(t_fftm_fix_rows<Cf, Impl_pop,  row>(rows, false)); break;
+  case  4: loop(t_fftm_fix_rows<Cf, Impl_pip1, row>(rows, false)); break;
+  case  5: loop(t_fftm_fix_rows<Cf, Impl_pip2, row>(rows, false)); break;
+  case  6: loop(t_fftm_fix_rows<Cf, Impl_bv,   row>(rows, false)); break;
 
-  case 11: loop(t_fftm_fix_cols<Cf, Impl_op,   row>(p, false)); break;
-  case 12: loop(t_fftm_fix_cols<Cf, Impl_ip,   row>(p, false)); break;
-  case 13: loop(t_fftm_fix_cols<Cf, Impl_pop,  row>(p, false)); break;
-  case 14: loop(t_fftm_fix_cols<Cf, Impl_pip1, row>(p, false)); break;
-  case 15: loop(t_fftm_fix_cols<Cf, Impl_pip2, row>(p, false)); break;
-  case 16: loop(t_fftm_fix_cols<Cf, Impl_bv,   row>(p, false)); break;
+  case 11: loop(t_fftm_fix_cols<Cf, Impl_op,   row>(size, false)); break;
+  case 12: loop(t_fftm_fix_cols<Cf, Impl_ip,   row>(size, false)); break;
+  case 13: loop(t_fftm_fix_cols<Cf, Impl_pop,  row>(size, false)); break;
+  case 14: loop(t_fftm_fix_cols<Cf, Impl_pip1, row>(size, false)); break;
+  case 15: loop(t_fftm_fix_cols<Cf, Impl_pip2, row>(size, false)); break;
+  case 16: loop(t_fftm_fix_cols<Cf, Impl_bv,   row>(size, false)); break;
 
 #if 0
   case 11: loop(t_fftm_fix_rows<complex<float>, Impl_op,   col>(p)); break;
@@ -553,22 +610,52 @@
   case 18: loop(t_fftm_fix_cols<complex<float>, Impl_pip2, col>(p)); break;
 #endif
 
-  case 21: loop(t_fftm_fix_rows<Cf, Impl_op,   row>(p, true)); break;
+  case 21: loop(t_fftm_fix_rows<Cf, Impl_op,   row>(rows, true)); break;
+#endif
 
-  case 101: loop(t_fftm_fix_rows<Cd, Impl_op,   row>(p, false)); break;
-  case 102: loop(t_fftm_fix_rows<Cd, Impl_ip,   row>(p, false)); break;
-  case 103: loop(t_fftm_fix_rows<Cd, Impl_pop,  row>(p, false)); break;
-  case 104: loop(t_fftm_fix_rows<Cd, Impl_pip1, row>(p, false)); break;
-  case 105: loop(t_fftm_fix_rows<Cd, Impl_pip2, row>(p, false)); break;
-  case 106: loop(t_fftm_fix_rows<Cd, Impl_bv,   row>(p, false)); break;
+#if VSIP_IMPL_PROVIDE_FFT_DOUBLE
+  case 101: loop(t_fftm_fix_rows<Cd, Impl_op,   row>(rows, false)); break;
+  case 102: loop(t_fftm_fix_rows<Cd, Impl_ip,   row>(rows, false)); break;
+  case 103: loop(t_fftm_fix_rows<Cd, Impl_pop,  row>(rows, false)); break;
+  case 104: loop(t_fftm_fix_rows<Cd, Impl_pip1, row>(rows, false)); break;
+  case 105: loop(t_fftm_fix_rows<Cd, Impl_pip2, row>(rows, false)); break;
+  case 106: loop(t_fftm_fix_rows<Cd, Impl_bv,   row>(rows, false)); break;
 
-  case 111: loop(t_fftm_fix_cols<Cd, Impl_op,   row>(p, false)); break;
-  case 112: loop(t_fftm_fix_cols<Cd, Impl_ip,   row>(p, false)); break;
-  case 113: loop(t_fftm_fix_cols<Cd, Impl_pop,  row>(p, false)); break;
-  case 114: loop(t_fftm_fix_cols<Cd, Impl_pip1, row>(p, false)); break;
-  case 115: loop(t_fftm_fix_cols<Cd, Impl_pip2, row>(p, false)); break;
-  case 116: loop(t_fftm_fix_cols<Cd, Impl_bv,   row>(p, false)); break;
+  case 111: loop(t_fftm_fix_cols<Cd, Impl_op,   row>(size, false)); break;
+  case 112: loop(t_fftm_fix_cols<Cd, Impl_ip,   row>(size, false)); break;
+  case 113: loop(t_fftm_fix_cols<Cd, Impl_pop,  row>(size, false)); break;
+  case 114: loop(t_fftm_fix_cols<Cd, Impl_pip1, row>(size, false)); break;
+  case 115: loop(t_fftm_fix_cols<Cd, Impl_pip2, row>(size, false)); break;
+  case 116: loop(t_fftm_fix_cols<Cd, Impl_bv,   row>(size, false)); break;
+#endif
 
+  case 0:
+    std::cout
+      << "fftm -- Fftm (multiple fast fourier transform) benchmark\n"
+      << "Single precision\n"
+      << " Fixed rows, sweeping FFT size:\n"
+      << "   -1 -- op  : out-of-place CC fwd fft\n"
+      << "   -2 -- ip  : In-place CC fwd fft\n"
+      << "   -3 -- pop : Psuedo out-of-place CC fwd fft\n"
+      << "   -4 -- pip1: Psuedo in-place v1 CC fwd fft\n"
+      << "   -5 -- pip2: Psuedo in-place v2 CC fwd fft\n"
+      << "   -6 -- bv  : By-value CC fwd fft\n"
+      << "\n"
+      << " Parameters (for sweeping FFT size, cases 1 through 6)\n"
+      << "  -p:rows ROWS -- set number of pulses (default 64)\n"
+      << "\n"
+      << " Fixed FFT size, sweeping number of FFTs:\n"
+      << "  -11 -- op  : out-of-place CC fwd fft\n"
+      << "  -12 -- ip  : In-place CC fwd fft\n"
+      << "  -13 -- pop : Psuedo out-of-place CC fwd fft\n"
+      << "  -14 -- pip1: Psuedo in-place v1 CC fwd fft\n"
+      << "  -15 -- pip2: Psuedo in-place v2 CC fwd fft\n"
+      << "  -16 -- bv  : By-value CC fwd fft\n"
+      << "\n"
+      << " Parameters (for sweeping number of FFTs, cases 11 through 16)\n"
+      << "  -p:size SIZE -- size of pulse (default 2048)\n"
+      ;
+
   default: return 0;
   }
   return 1;
Index: benchmarks/fft.cpp
===================================================================
--- benchmarks/fft.cpp	(revision 191870)
+++ benchmarks/fft.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007, 2008 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -211,6 +211,7 @@
 
   switch (what)
   {
+#if VSIP_IMPL_PROVIDE_FFT_FLOAT
   case  1: loop(t_fft_op<complex<float>, estimate>(false)); break;
   case  2: loop(t_fft_ip<complex<float>, estimate>(false)); break;
   case  3: loop(t_fft_bv<complex<float>, estimate>(false)); break;
@@ -231,9 +232,11 @@
   case 25: loop(t_fft_op<complex<float>, patient>(true)); break;
   case 26: loop(t_fft_ip<complex<float>, patient>(true)); break;
   case 27: loop(t_fft_bv<complex<float>, patient>(true)); break;
+#endif
 
   // Double precision cases.
 
+#if VSIP_IMPL_PROVIDE_FFT_DOUBLE
   case 101: loop(t_fft_op<complex<double>, estimate>(false)); break;
   case 102: loop(t_fft_ip<complex<double>, estimate>(false)); break;
   case 103: loop(t_fft_bv<complex<double>, estimate>(false)); break;
@@ -254,10 +257,12 @@
   case 125: loop(t_fft_op<complex<double>, patient>(true)); break;
   case 126: loop(t_fft_ip<complex<double>, patient>(true)); break;
   case 127: loop(t_fft_bv<complex<double>, patient>(true)); break;
+#endif
 
   case 0:
     std::cout
       << "fft -- Fft (fast fourier transform)\n"
+#if VSIP_IMPL_PROVIDE_FFT_FLOAT
       << "Single precision\n"
       << " Planning effor: estimate (number of times = 1):\n"
       << "   -1 -- op: out-of-place CC fwd fft\n"
@@ -269,11 +274,19 @@
 
       << " Planning effor: measure (number of times = 15): 11-16\n"
       << " Planning effor: pateint (number of times = 0): 21-26\n"
+#else
+      << "Single precision FFT support not provided by library\n"
+#endif
 
+      << "\n"
+#if VSIP_IMPL_PROVIDE_FFT_DOUBLE
       << "\nDouble precision\n"
       << " Planning effor: estimate (number of times = 1): 101-106\n"
       << " Planning effor: measure (number of times = 15): 111-116\n"
       << " Planning effor: pateint (number of times = 0): 121-126\n"
+#else
+      << "Double precision FFT support not provided by library\n"
+#endif
       ;
 
   default: return 0;
