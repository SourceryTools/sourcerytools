Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.396
diff -u -r1.396 ChangeLog
--- ChangeLog	16 Feb 2006 15:59:52 -0000	1.396
+++ ChangeLog	16 Feb 2006 16:15:44 -0000
@@ -1,5 +1,12 @@
 2006-02-16  Stefan Seefeld  <stefan@codesourcery.com>
 
+	* configure.ac: Add support for sal-fft.
+	* src/vsip/impl/fft-core.hpp: Likewise.
+	* src/vsip/impl/signal-fft.hpp: Likewise.
+	* src/vsip/impl/sal/fft.hpp: Likewise.
+	* tests/fft.cpp: Temporarily mask all tests that sal-fft is known
+	not to support, when building with sal-fft.
+
 	* configure.ac: Emit variable PAR_SERVICE.
 	* vsipl++.pc.in: Publish it.
 	* tests/GNUmakefile.inc.in: Propagate it...
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.81
diff -u -r1.81 configure.ac
--- configure.ac	16 Feb 2006 15:59:52 -0000	1.81
+++ configure.ac	16 Feb 2006 16:15:44 -0000
@@ -11,7 +11,7 @@
 dnl Autoconf initialization
 dnl ------------------------------------------------------------------
 AC_PREREQ(2.56)
-AC_REVISION($Revision: 1.81 $)
+AC_REVISION($Revision: 1.80 $)
 AC_INIT(Sourcery VSIPL++, 1.0, vsipl++@codesourcery.com, sourceryvsipl++)
 
 ######################################################################
@@ -110,7 +110,7 @@
 AC_ARG_WITH(fft,
   AS_HELP_STRING([--with-fft=LIB],
                  [Specify FFT engine: fftw3, fftw2-float, fftw2-double,
-		  fftw2-generic, ipp, or builtin.  For fftw2-generic, 
+		  fftw2-generic, ipp, sal, or builtin.  For fftw2-generic, 
 		  float support is in <fftw.h> and -lfftw, not <sfftw.h> 
 	          and -lsfftw.  (Default is fftw3 if found, otherwise 
                   builtin, meaning build and use in-tree fftw3.)]),
@@ -418,6 +418,7 @@
 enable_fftw3="no"
 enable_fftw2="no"
 enable_ipp_fft="no"
+enable_sal_fft="no"
 build_fftw3="no"
 
 if test "$enable_fft_float" = yes -o \
@@ -440,9 +441,11 @@
     enable_fftw2_float="yes"
   elif test "$with_fft" = "ipp"; then
     enable_ipp_fft="yes"
+  elif test "$with_fft" = "sal"; then
+    enable_sal_fft="yes"
   elif test "$with_fft" != "none"; then
     AC_MSG_ERROR([Argument to --with-fft= must be one of fftw3, fftw2-float,
-                  fftw2-double, fftw2-generic, ipp, builtin, or none.])
+                  fftw2-double, fftw2-generic, ipp, sal, builtin, or none.])
   fi 
 fi
 
@@ -500,6 +503,7 @@
   LIBS="$keep_LIBS"
 
   enable_ipp_fft="no"
+  enable_sal_fft="no"
   enable_fftw2="no"
 fi
 
@@ -710,6 +714,7 @@
     AC_SUBST(FFT_LIBS)
 
     enable_ipp_fft="no"
+    enable_sal_fft="no"
   fi
 fi
 
@@ -851,6 +856,14 @@
 #
 # Find the Mercury SAL library, if enabled.
 #
+if test "$enable_sal_fft" == "yes"; then
+  if test "$enable_sal" == "no"; then
+    AC_MSG_ERROR([SAL FFT requires SAL])
+  else
+    enable_sal="yes"
+  fi 
+fi
+
 if test "$enable_sal" != "no"; then
 
   if test -n "$with_sal_include"; then
@@ -863,8 +876,11 @@
   vsipl_sal_h_name="not found"
   AC_CHECK_HEADER([sal.h], [vsipl_sal_h_name='<sal.h>'],, [// no prerequisites])
   if test "$vsipl_sal_h_name" == "not found"; then
-    AC_MSG_ERROR([SAL enabled, but no sal.h detected])
-    CPPFLAGS="$save_CPPFLAGS"
+    if test "$enable_sal" != "probe" -o "$enable_sal_fft" == "yes"; then
+      AC_MSG_ERROR([SAL enabled, but no sal.h detected])
+    else
+      CPPFLAGS="$save_CPPFLAGS"
+    fi
   else
 
     # Find the library.
@@ -908,6 +924,21 @@
     AC_SUBST(VSIP_IMPL_HAVE_SAL, 1)
     AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SAL, 1,
       [Define to set whether or not to use Mercury's SAL library.])
+
+    if test "$enable_sal_fft" != "no"; then 
+      AC_SUBST(VSIP_IMPL_SAL_FFT, 1)
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_SAL_FFT, 1,
+	    [Define to use Mercury's SAL library to perform FFTs.])
+      if test "$enable_fft_float" = yes; then
+	AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_FLOAT, $vsip_impl_use_float,
+	      [Define to build code with support for FFT on float types.])
+      fi
+      if test "$enable_fft_double" = yes; then
+	AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_DOUBLE, $vsip_impl_use_double,
+	      [Define to build code with support for FFT on double types.])
+      fi
+    fi
+
   fi
 
 fi
Index: src/vsip/impl/fft-core.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft-core.hpp,v
retrieving revision 1.19
diff -u -r1.19 fft-core.hpp
--- src/vsip/impl/fft-core.hpp	22 Dec 2005 08:21:23 -0000	1.19
+++ src/vsip/impl/fft-core.hpp	16 Feb 2006 16:15:45 -0000
@@ -68,6 +68,10 @@
 # include <ippi.h>
 #endif
 
+#if defined(VSIP_IMPL_SAL_FFT)
+# include <vsip/impl/sal/fft.hpp>
+#endif // VSIP_IMPL_SAL_FFT
+
 //////////////////////////////////////////////////////////////////////////
 //
 // Local includes
@@ -1503,7 +1507,6 @@
 
 #endif // VSIP_IMPL_IPP_FFT
 
-
 //////////////////////////////////////////////////////////////////////////
 //
 // Generic entry points
Index: src/vsip/impl/signal-fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-fft.hpp,v
retrieving revision 1.29
diff -u -r1.29 signal-fft.hpp
--- src/vsip/impl/signal-fft.hpp	10 Feb 2006 22:24:02 -0000	1.29
+++ src/vsip/impl/signal-fft.hpp	16 Feb 2006 16:15:46 -0000
@@ -82,7 +82,19 @@
   void* p_buffer_;      // temporary storage not allocated in the plan
   unsigned row_step_;    // length in bytes of 2D row.
 # endif
-
+#elif defined(VSIP_IMPL_SAL_FFT)
+  // Array sizes (in log2 units).
+  // size_[0] always corresponds to the line being processed first,
+  // and thus may depend on the sD template parameter.
+  unsigned long size_[Dim];
+  void *plan_;
+  bool is_forward_;
+
+  int  stride_; // 1 for sd_ == 0, length of row for sd_ == 1.
+  int  dist_;   // 1 for sd_ == 1, length of column for sd_ == 0.
+  // used only for Fftm
+  int  sd_;     // 0: compute FFTs of rows; 1: of columns
+  int  runs_;   // number of 1D FFTs to perform; varies by map
 #endif
 
   // if any of the above functions applies the scale itself, it must
@@ -421,6 +433,37 @@
     static const vsip::dimension_type  transpose_target =
       (sizeof(inT) != sizeof(outT)) ? Fft_imp::dim-1 : sD;
 
+#elif defined(VSIP_IMPL_SAL_FFT) 
+
+    // In some contexts, SAL destroys the input data itself, and sometimes
+    // we have to modify it to 'pack' data into the format SAL expects
+    // (see SAL Tutorial for details).
+    // Therefor, we always copy the input.
+    static const bool  force_copy = true;
+    // SAL cannot handle non-unit strides properly as 'complex' isn't
+    // a real (packed) datatype, so the stride would be applied to the real/imag
+    // offset, too.
+    static const vsip::dimension_type  transpose_target = Fft_imp::dim-1;
+
+    // FIXME: For now SAL always operates on a copy of the input / output buffers
+    //        with unit stride, so we only adjust here to effectively transpose if
+    //        required by the sD parameter (that concerns fft 2D and fftm).
+    //        If these copies can be avoided, we have to track the compound strides
+    //        here.
+    // These are already dealt with for fftm elsewhere, so we only adjust them
+    // here for fft2d
+//     if (sD)
+//     {
+//       this->core_->stride_ = 1;
+//       this->core_->dist_ = 1 << this->core_->size_[0];
+//     }
+//     else
+//     {
+//       this->core_->stride_ = 1 << this->core_->size_[0];
+//       this->core_->dist_ = 1;
+//     }
+    this->core_->stride_ = 1;
+    this->core_->dist_ = 1 << this->core_->size_[0];
 #else
 
     // ideal case: can c->r, r->c on any axis, never clobbers input.
@@ -435,7 +478,7 @@
             Fft_imp::dim,sD,transpose_target>::type>::type
         raw_in(in.block(), impl::SYNC_IN,
 	  impl::Ext_data<in_block_type>(this->in_temp_).data());
-      
+
       typename impl::Maybe_force_copy<force_copy,Block1,
 	  typename impl::Maybe_transpose<
             Fft_imp::dim,sD,transpose_target>::type>::type
@@ -744,6 +787,11 @@
       static const bool force_copy = inPlace::value;
       static const vsip::dimension_type  transpose_target = 1;
 
+#elif defined(VSIP_IMPL_SAL_FFT)
+
+      static const bool force_copy = true;
+      static const vsip::dimension_type  transpose_target = 1;
+
 #else
       static const bool force_copy = false;
       static const vsip::dimension_type  transpose_target = axis;
@@ -820,11 +868,20 @@
 #if defined(VSIP_IMPL_FFTW3)
       static const bool  must_copy = (sD == vsip::col);
       static const vsip::dimension_type  transpose_target = 1;
+#elif defined(VSIP_IMPL_SAL_FFT)
+    // In some contexts, SAL destroys the input data itself, and sometimes
+    // we have to modify it to 'pack' data into the format SAL expects
+    // (see SAL Tutorial for details).
+    // Therefor, we always copy the input.
+    static const bool  must_copy = true;
+    // SAL cannot handle non-unit strides properly as 'complex' isn't
+    // a real (packed) datatype, so the stride would be applied to the real/imag
+    // offset, too.
+    static const vsip::dimension_type  transpose_target = 1;
 #else
       static const bool  must_copy = false;
       static const vsip::dimension_type  transpose_target = axis;
 #endif
-
       typename impl::Maybe_force_copy<
 	  must_copy,typename local_type::block_type,
           typename impl::Maybe_transpose<2,axis,transpose_target>::type>::type
@@ -833,7 +890,7 @@
 	  impl::Ext_data<in_block_type>(this->in_temp_).data());
 
       const bool native_order = (axis == transpose_target);
-      
+
       this->core_->scale_ = this->scale_;
       this->core_->runs_ = local_inout.size(1-axis);
       this->core_->stride_ = 1;
Index: src/vsip/impl/sal/fft.hpp
===================================================================
RCS file: src/vsip/impl/sal/fft.hpp
diff -N src/vsip/impl/sal/fft.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/sal/fft.hpp	16 Feb 2006 16:15:46 -0000
@@ -0,0 +1,624 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/sal/sal.hpp
+    @author  Stefan Seefeld
+    @date    2006-02-02
+    @brief   VSIPL++ Library: FFT wrappers and traits to bridge with Mercury's SAL.
+*/
+
+#ifndef VSIP_IMPL_SAL_FFT_HPP
+#define VSIP_IMPL_SAL_FFT_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/impl/signal-fft.hpp>
+#include <sal.h>
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace sal
+{
+
+// TODO: figure out what exactly this ESAL flag is and tune it.
+//       (requires SAL, not CSAL, and real h/w)
+long const ESAL = 0;
+
+inline unsigned int
+int_log2(unsigned int size)    // assume size = 2^n, != 0, return n.
+{
+  unsigned int n = 0;
+  while (size >>= 1) ++n;
+  return n;
+}
+
+template <dimension_type D> struct log2n;
+
+template <>
+struct log2n<1>
+{
+  static unsigned long translate(Domain<1> const &d, int, unsigned long *out) 
+  {
+    *out = int_log2(d.size());
+    return *out;
+  }
+};
+
+template <>
+struct log2n<2>
+{
+  static unsigned long translate(Domain<2> const &d, int sd, unsigned long *out)
+  {
+    // If sd == 1, invert size[0] and size[1], i.e. transpose.
+    *out = int_log2(d[sd].size());
+    *(out + 1) = int_log2(d[1 - sd].size());
+    return std::max(*out, *(out + 1));
+  }
+};
+
+template <>
+struct log2n<3>
+{
+  static unsigned long translate(Domain<3> const &d, int sd, unsigned long *out)
+  {
+    // If sd == 1, invert size[0] and size[1], i.e. transpose.
+    *out = int_log2(d[sd].size());
+    *(out + 1) = int_log2(d[1 - sd].size());
+    *(out + 2) = int_log2(d[2].size());
+    return std::max(*out, std::max(*(out + 1), *(out + 2)));
+  }
+};
+
+/// Helper trait used to discriminate setup / cleanup functions and options.
+template <typename inT, typename outT> struct fft_inout_trait;
+
+template <>
+struct fft_inout_trait<float, float>
+{
+  static bool const single = true;
+  static long const option = FFT_REAL_ONLY;
+};
+
+template <>
+struct fft_inout_trait<float, std::complex<float> >
+{
+  static bool const single = true;
+  static long const option = 0;
+};
+
+template <>
+struct fft_inout_trait<std::complex<float>, float>
+{
+  static bool const single = true;
+  static long const option = 0;
+};
+
+template <>
+struct fft_inout_trait<std::complex<float>, std::complex<float> >
+{
+  static bool const single = true;
+  static long const option = FFT_COMPLEX_ONLY;
+};
+
+template <>
+struct fft_inout_trait<double, double>
+{
+  static bool const single = false;
+  static long const option = FFT_REAL_ONLY;
+};
+
+template <>
+struct fft_inout_trait<double, std::complex<double> >
+{
+  static bool const single = false;
+  static long const option = 0;
+};
+
+template <>
+struct fft_inout_trait<std::complex<double>, double>
+{
+  static bool const single = false;
+  static long const option = 0;
+};
+
+template <>
+struct fft_inout_trait<std::complex<double>, std::complex<double> >
+{
+  static bool const single = false;
+  static long const option = FFT_COMPLEX_ONLY;
+};
+
+template <dimension_type D,
+	  typename inT, typename outT,
+	  bool single = fft_inout_trait<inT, outT>::single >
+struct fft_planner;
+
+template <dimension_type D,
+	  typename inT, typename outT>
+struct fft_planner<D, inT, outT, true /* single */>
+{
+  static void
+  create(void *&plan, unsigned long size) VSIP_THROW((std::bad_alloc))
+  {
+    long options = fft_inout_trait<inT, outT>::option;
+    FFT_setup setup = 0;
+    unsigned long nbytes = 0;
+    fft_setup(size, options, &setup, &nbytes);
+    plan = setup;
+  }
+  static void 
+  destroy(void *plan)
+  {
+    FFT_setup setup = reinterpret_cast<FFT_setup>(plan);
+    fft_free(&setup);
+  }
+};
+
+template <dimension_type D,
+	  typename inT, typename outT>
+struct fft_planner<D, inT, outT, false /* single */>
+{
+  static void
+  create(void *&plan, unsigned long size) VSIP_THROW((std::bad_alloc))
+  {
+    long options = fft_inout_trait<inT, outT>::option;
+    FFT_setupd setup = 0;
+    unsigned long nbytes = 0;
+    fft_setupd(size, options, &setup, &nbytes);
+    plan = setup;
+  }
+  static void 
+  destroy(void *plan)
+  {
+    FFT_setupd setup = reinterpret_cast<FFT_setupd>(plan);
+    fft_freed(&setup);
+  }
+};
+
+} // namespace vsip::impl::sal
+
+template<dimension_type D, typename inT, typename outT, bool doFftm>
+inline void
+create_plan(Fft_core<D, inT, outT, doFftm>& self, Domain<D> const& dom, 
+	    int sd, int expn, unsigned /* will_call */, inT*, outT*)
+  VSIP_THROW((std::bad_alloc))
+{
+  self.is_forward_ = (expn == -1);
+  unsigned long max = sal::log2n<D>::translate(dom, sd, self.size_);
+  sal::fft_planner<D, inT, outT>::create(self.plan_, max);
+}
+
+template<dimension_type D, typename inT, typename outT, bool doFftm>
+inline void
+destroy(Fft_core<D, inT, outT, doFftm>& self) VSIP_THROW((std::bad_alloc))
+{
+  sal::fft_planner<D, inT, outT>::destroy(self.plan_);
+}
+
+inline void
+in_place(Fft_core<1, std::complex<float>, std::complex<float>, false>& self,
+	 std::complex<float> *inout) VSIP_NOTHROW
+{
+  FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
+  COMPLEX *data = reinterpret_cast<COMPLEX *>(inout);
+  long stride = 2;
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fft_cipx(&setup, data, stride, self.size_[0], direction, sal::ESAL);
+}
+
+inline void
+in_place(Fft_core<1, std::complex<double>, std::complex<double>, false>& self,
+	 std::complex<double> *inout) VSIP_NOTHROW
+{
+  FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
+  DOUBLE_COMPLEX *data = reinterpret_cast<DOUBLE_COMPLEX *>(inout);
+  long stride = 2;
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fft_cipdx(&setup, data, stride, self.size_[0], direction, sal::ESAL);
+}
+
+inline void
+in_place(Fft_core<2, std::complex<float>, std::complex<float>, false>& self,
+	 std::complex<float> *inout) VSIP_NOTHROW
+{
+  FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
+  COMPLEX *data = reinterpret_cast<COMPLEX *>(inout);
+  long stride = 2;
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fft2d_cipx(&setup, data, stride, 2 << self.size_[1],
+	     self.size_[1], self.size_[0], direction, sal::ESAL);
+}
+
+inline void
+in_place(Fft_core<2, std::complex<double>, std::complex<double>, false>& self,
+	 std::complex<double> *inout) VSIP_NOTHROW
+{
+  FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
+  DOUBLE_COMPLEX *data = reinterpret_cast<DOUBLE_COMPLEX *>(inout);
+  long stride = 2;
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fft2d_cipdx(&setup, data, stride, 2 << self.size_[1],
+	      self.size_[1], self.size_[0], direction, sal::ESAL);
+}
+
+template <vsip::dimension_type D, typename inT, typename outT, bool doFftm>
+inline void
+from_to(Fft_core<D, inT, outT, doFftm>& self, inT const* in, outT* out)
+  VSIP_NOTHROW
+{
+  assert(0 && "Sorry, operation not yet supported for this type !");
+  // TBD
+}
+
+// 1D real -> complex forward fft
+
+inline void
+from_to(Fft_core<1, float, std::complex<float>, false>& self,
+	float const* in, std::complex<float>* out)
+  VSIP_NOTHROW
+{
+  FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
+  float *out_ = reinterpret_cast<float*>(out);
+  fft_ropx(&setup, const_cast<float*>(in), 1, out_, 1,
+	   self.size_[0], FFT_FORWARD, sal::ESAL);
+  // unpack the data (see SAL reference for details).
+  int const N = (1 << self.size_[0]) + 2;
+  out_[N - 2] = out_[1];
+  out_[1] = 0.f;
+  out_[N - 1] = 0.f;
+  // forward fft_ropx is scaled up by 2.
+  float scale = 0.5f;
+  vsmulx(out_, 1, &scale, out_, 1, N, sal::ESAL);
+}
+
+// 1D complex -> real inverse fft
+
+inline void
+from_to(Fft_core<1, std::complex<float>, float, false>& self,
+	std::complex<float> const* in, float* out)
+  VSIP_NOTHROW
+{
+  FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
+  float *in_ = 
+    reinterpret_cast<float *>(const_cast<std::complex<float>*>(in));
+  // pack the data (see SAL reference for details).
+  int const N = (1 << self.size_[0]) + 2;
+  in_[1] = in_[N - 2];
+  in_[N - 2] = in_[N - 1] = 0.f;
+
+  fft_ropx(&setup, in_, 1,
+	   out, 1, self.size_[0], FFT_INVERSE, sal::ESAL);
+}
+
+// 1D real -> complex forward fft
+
+inline void
+from_to(Fft_core<1, double, std::complex<double>, false>& self,
+	double const* in, std::complex<double>* out)
+  VSIP_NOTHROW
+{
+  FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
+  double *out_ = reinterpret_cast<double*>(out);
+  fft_ropdx(&setup, const_cast<double*>(in), 1, out_, 1,
+	    self.size_[0], FFT_FORWARD, sal::ESAL);
+  // unpack the data (see SAL reference for details).
+  int const N = (1 << self.size_[0]) + 2;
+  out_[N - 2] = out_[1];
+  out_[1] = 0.f;
+  out_[N - 1] = 0.f;
+  // forward fft_ropx is scaled up by 2.
+  double scale = 0.5f;
+  vsmuldx(out_, 1, &scale, out_, 1, N, sal::ESAL);
+}
+
+// 1D complex -> real inverse fft
+
+inline void
+from_to(Fft_core<1, std::complex<double>, double, false>& self,
+	std::complex<double> const* in, double* out)
+  VSIP_NOTHROW
+{
+  FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
+  double *in_ = 
+    reinterpret_cast<double *>(const_cast<std::complex<double>*>(in));
+  // pack the data (see SAL reference for details).
+  int const N = (1 << self.size_[0]) + 2;
+  in_[1] = in_[N - 2];
+  in_[N - 2] = in_[N - 1] = 0.f;
+
+  fft_ropdx(&setup, in_, 1,
+	    out, 1, self.size_[0], FFT_INVERSE, sal::ESAL);
+}
+
+inline void
+from_to(Fft_core<1, std::complex<float>, std::complex<float>, false>& self,
+	std::complex<float> const *in, std::complex<float> *out) VSIP_NOTHROW
+{
+  FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
+  COMPLEX *in_ = reinterpret_cast<COMPLEX *>(const_cast<std::complex<float>*>(in));
+  COMPLEX *out_ = reinterpret_cast<COMPLEX *>(out);
+  long stride = 2;
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fft_copx(&setup, in_, stride, out_, stride, self.size_[0],
+	   direction, sal::ESAL);
+}
+
+inline void
+from_to(Fft_core<1, std::complex<double>, std::complex<double>, false>& self,
+	std::complex<double> const *in, std::complex<double> *out) VSIP_NOTHROW
+{
+  FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
+  DOUBLE_COMPLEX *in_ = 
+    reinterpret_cast<DOUBLE_COMPLEX *>(const_cast<std::complex<double>*>(in));
+  DOUBLE_COMPLEX *out_ = reinterpret_cast<DOUBLE_COMPLEX *>(out);
+  long stride = 2;
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fft_copdx(&setup, in_, stride, out_, stride, self.size_[0],
+	    direction, sal::ESAL);
+}
+
+// 2D real -> complex forward fft
+
+template <typename T>
+inline void 
+unpack(T *data, unsigned long N, unsigned long M, unsigned long stride)
+{
+  // unpack the data (see SAL reference, figure 3.6, for details).
+  unsigned long const M2 = M/2 + 1;
+  T t10r = data[N * stride];         // (1, 0).real()
+  T t10i = data[N * stride + 1];     // (1, 0).imag()
+  data[N * stride + 1] = 0.;         // (0, 0).imag()
+  data[N * stride - 2] = data[1];    // (0,-1).real()
+  data[N * stride - 1] = 0.;         // (0,-1).imag()
+  data[1] = 0.;
+  for (unsigned long r = 1; r != M2 - 1; ++r)
+  {
+    // set last row (r,-1)
+    data[(r + 1) * N * stride - 2] = data[2 * r * N * stride + 1];
+    data[(r + 1) * N * stride - 1] = data[(2 * r + 1) * N * stride + 1];
+    data[2 * r * N * stride + 1] = 0.;
+    data[(2 * r + 1) * N * stride + 1] = 0.;
+    // set first row (r, 0)
+    data[r * N * stride] = data[2 * r * N * stride];
+    data[r * N * stride + 1] = data[(2 * r + 1) * N * stride];
+    data[2 * r * N * stride] = 0.;
+    data[(2 * r + 1) * N * stride] = 0.;
+  }
+  data[(M2 - 1) * N * stride] = t10r;
+  data[(M2 - 1) * N * stride + 1] = 0.;
+  data[M2  * N * stride - 2] = t10i;
+  data[M2  * N * stride - 1] = 0;
+
+  // Now fill in the missing cells by symmetry.
+  for (unsigned long r = M2; r != M; ++r)
+  {
+    // first column (r, 0)
+    data[r * N * stride] = data[(M - r) * N * stride];
+    data[r * N * stride + 1] = - data[(M - r) * N * stride + 1];
+    // last column (r, -1)
+    data[(r + 1) * N * stride - 2] = data[(M - r + 1) * N * stride - 2];
+    data[(r + 1) * N * stride - 1] = - data[(M - r + 1) * N * stride - 1];
+  }
+}
+
+inline void
+from_to(Fft_core<2, float, std::complex<float>, false>& self,
+	float const* in, std::complex<float>* out)
+  VSIP_NOTHROW
+{
+  FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
+  float *out_ = reinterpret_cast<float*>(out);
+  // The size of the output array is (N/2) x M (if measured in std::complex<float>)
+  unsigned long const N = (1 << self.size_[1]) + 2;
+  unsigned long const M = (1 << self.size_[0]);
+  fft2d_ropx(&setup, const_cast<float*>(in), self.stride_, self.dist_,
+	     out_, self.stride_, N,
+	     self.size_[1], self.size_[0], FFT_FORWARD, sal::ESAL);
+
+  // unpack the data (see SAL reference, figure 3.6, for details).
+  unpack(out_, N, M, self.stride_);
+  // forward fft_ropx is scaled up by 2.
+  float scale = 0.5f;
+  for (unsigned long i = 0; i != M; ++i, out_ += N)
+    vsmulx(out_, self.stride_, &scale, out_, self.stride_, N, sal::ESAL);
+}
+
+inline void
+from_to(Fft_core<2, double, std::complex<double>, false>& self,
+	double const* in, std::complex<double>* out)
+  VSIP_NOTHROW
+{
+  FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
+  double *out_ = reinterpret_cast<double*>(out);
+  // The size of the output array is (N/2) x M (if measured in std::complex<float>)
+  unsigned long const N = (1 << self.size_[1]) + 2;
+  unsigned long const M = (1 << self.size_[0]);
+  fft2d_ropdx(&setup, const_cast<double*>(in), self.stride_, self.dist_,
+	      out_, self.stride_, N,
+	      self.size_[1], self.size_[0], FFT_FORWARD, sal::ESAL);
+
+  // unpack the data (see SAL reference, figure 3.6, for details).
+  unpack(out_, N, M, self.stride_);
+
+  // forward fft_ropx is scaled up by 2.
+  double scale = 0.5f;
+  for (unsigned long i = 0; i != M; ++i, out_ += N)
+    vsmuldx(out_, self.stride_, &scale, out_, self.stride_, N, sal::ESAL);
+}
+
+// 2D complex -> real inverse fft
+
+template <typename T>
+inline void 
+pack(T *data, unsigned long N, unsigned long M, unsigned long stride)
+{
+  unsigned long const M2 = M/2 + 1;
+
+  T t10i = data[M2  * N * stride - 2];
+  T t10r = data[(M2 - 1) * N * stride];
+
+  for (unsigned long r = M2 - 2; r; --r)
+  {
+    // pack first row (r, 0)
+    data[2 * r * N * stride] = data[r * N * stride];
+    data[(2 * r + 1) * N * stride] = data[r * N * stride + 1];
+    // pack last row (r,-1)
+    data[2 * r * N * stride + 1] = data[(r + 1) * N * stride - 2];
+    data[(2 * r + 1) * N * stride + 1] = data[(r + 1) * N * stride - 1];
+  }
+
+  data[N * stride] = t10r;         // (1, 0).real()
+  data[N * stride + 1] = t10i;     // (1, 0).imag()
+  data[1] = data[N * stride - 2];  // (0,-1).real()
+}
+
+inline void
+from_to(Fft_core<2, std::complex<float>, float, false>& self,
+	std::complex<float> const* in, float* out)
+  VSIP_NOTHROW
+{
+  FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
+  float *in_ = 
+    reinterpret_cast<float *>(const_cast<std::complex<float>*>(in));
+  // The size of the output array is (N/2) x M (if measured in std::complex<float>)
+  // pack the data (see SAL reference for details).
+  int const N = (1 << self.size_[1]) + 2;
+  unsigned long const M = (1 << self.size_[0]);
+  pack(in_, N, M, self.stride_);
+  fft2d_ropx(&setup, in_, 1, N,
+	     out, 1, 1 << self.size_[1],
+	     self.size_[1], self.size_[0], FFT_INVERSE, sal::ESAL);
+  // inverse fft_ropx is scaled up by N.
+//   float N = 1 << self.size_[1] + 2;
+//   vsmul(out, 1, &N, out, 1, (int)N);
+}
+
+inline void
+from_to(Fft_core<2, std::complex<double>, double, false>& self,
+	std::complex<double> const* in, double* out)
+  VSIP_NOTHROW
+{
+  FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
+  double *in_ = 
+    reinterpret_cast<double *>(const_cast<std::complex<double>*>(in));
+  // pack the data (see SAL reference for details).
+  int const N = (1 << self.size_[1]) + 2;
+  in_[1] = in_[N - 2];
+  in_[N - 2] = in_[N - 1] = 0.f;
+
+  fft2d_ropdx(&setup, in_, 1, 1 << self.size_[1],
+	      out, 1, 1 << self.size_[1],
+	      self.size_[1], self.size_[0], FFT_INVERSE, sal::ESAL);
+}
+
+inline void
+from_to(Fft_core<2, std::complex<float>, std::complex<float>, false>& self,
+	std::complex<float> const *in, std::complex<float> *out) VSIP_NOTHROW
+{
+  FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
+  COMPLEX *in_ = reinterpret_cast<COMPLEX *>(const_cast<std::complex<float>*>(in));
+  COMPLEX *out_ = reinterpret_cast<COMPLEX *>(out);
+  long stride = 2;
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fft2d_copx(&setup, in_, stride, 2 << self.size_[1],
+	     out_, stride, 2 << self.size_[1],
+	     self.size_[1], self.size_[0],
+	     direction, sal::ESAL);
+}
+
+inline void
+from_to(Fft_core<2, std::complex<double>, std::complex<double>, false>& self,
+	std::complex<double> const *in, std::complex<double> *out) VSIP_NOTHROW
+{
+  FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
+  DOUBLE_COMPLEX *in_ = 
+    reinterpret_cast<DOUBLE_COMPLEX *>(const_cast<std::complex<double>*>(in));
+  DOUBLE_COMPLEX *out_ = reinterpret_cast<DOUBLE_COMPLEX *>(out);
+  long stride = 2;
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fft2d_copdx(&setup, in_, stride, stride << self.size_[1],
+	      out_, stride, stride << self.size_[1],
+	      self.size_[1], self.size_[0],
+	      direction, sal::ESAL);
+}
+
+// FFTM 
+
+inline void
+in_place(Fft_core<2, std::complex<float>, std::complex<float>, true>& self,
+	 std::complex<float> *inout) VSIP_NOTHROW
+{
+  FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fftm_cipx(&setup, reinterpret_cast<COMPLEX *>(inout),
+	    2, 2 << self.size_[1], self.size_[1], self.runs_,
+	    direction, sal::ESAL);
+}
+
+inline void
+from_to(Fft_core<2, std::complex<float>, std::complex<float>, true>& self,
+	std::complex<float> const *in, std::complex<float> *out) VSIP_NOTHROW
+{
+  FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
+  COMPLEX *in_ = 
+    reinterpret_cast<COMPLEX *>(const_cast<std::complex<float>*>(in));
+  COMPLEX *out_ = reinterpret_cast<COMPLEX *>(out);
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fftm_copx(&setup, in_, self.stride_, self.dist_,
+	    out_, 2, 2 << self.size_[1], self.size_[1], self.runs_,
+	    direction, sal::ESAL);
+}
+
+inline void
+from_to(Fft_core<2, float, std::complex<float>, true>& self,
+	float const *in, std::complex<float> *out) VSIP_NOTHROW
+{
+  FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
+  float *out_ = reinterpret_cast<float*>(out);
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fftm_ropx(&setup, const_cast<float *>(in), self.stride_, self.dist_,
+ 	    out_, self.stride_, self.dist_ + 2,
+ 	    self.size_[1], self.runs_,
+ 	    direction, sal::ESAL);
+  // Unpack the data (see SAL reference for details), and scale back by 1/2.
+  int const N = (1 << self.size_[1]) + 2;
+  float scale = 0.5f;
+  for (unsigned int i = 0; i != self.runs_; ++i, out_ += self.dist_ + 2)
+  {
+    out_[(N - 2) * self.stride_] = out_[self.stride_];
+    out_[self.stride_] = 0.f;
+    out_[(N - 1) * self.stride_] = 0.f;
+    vsmulx(out_, self.stride_, &scale, out_, self.stride_, N, sal::ESAL);
+  }
+}
+
+inline void
+from_to(Fft_core<2, std::complex<double>, std::complex<double>, true>& self,
+	std::complex<double> const *in, std::complex<double> *out) VSIP_NOTHROW
+{
+  FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
+  DOUBLE_COMPLEX *in_ = 
+    reinterpret_cast<DOUBLE_COMPLEX *>(const_cast<std::complex<double>*>(in));
+  DOUBLE_COMPLEX *out_ = reinterpret_cast<DOUBLE_COMPLEX *>(out);
+  long stride = 2;
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fftm_copdx(&setup, in_, stride, stride << self.size_[1],
+	     out_, stride, stride << self.size_[1],
+	     self.size_[1], 1 << self.size_[0],
+	     direction, sal::ESAL);
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif
+
Index: tests/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft.cpp,v
retrieving revision 1.10
diff -u -r1.10 fft.cpp
--- tests/fft.cpp	22 Dec 2005 08:21:23 -0000	1.10
+++ tests/fft.cpp	16 Feb 2006 16:15:46 -0000
@@ -762,14 +762,20 @@
 
 unsigned  sizes[][3] =
 {
+#if !defined(VSIP_IMPL_SAL_FFT)
   { 2, 2, 2 },
+#endif
   { 8, 8, 8 },
+#if !defined(VSIP_IMPL_SAL_FFT)
   { 1, 1, 1 },
   { 2, 2, 1 },
   { 2, 8, 128 },
+#endif
   { 3, 5, 7 },
+#if !defined(VSIP_IMPL_SAL_FFT)
   { 2, 24, 48 },
   { 24, 1, 5 },
+#endif
 };
 
 //   the generic test
@@ -924,17 +930,23 @@
 #if defined(VSIP_IMPL_FFT_USE_FLOAT)
 
   test_by_ref<complex<float> >(2, 64);
+#if !defined(VSIP_IMPL_SAL_FFT)
   test_by_ref<complex<float> >(1, 68);
+#endif
   test_by_ref<complex<float> >(2, 256);
+#if !defined(VSIP_IMPL_SAL_FFT)
   test_by_ref<complex<float> >(2, 252);
   test_by_ref<complex<float> >(3, 17);
+#endif
 
   test_by_val<complex<float> >(1, 128);
   test_by_val<complex<float> >(2, 256);
   test_by_val<complex<float> >(3, 512);
 
   test_real<float>(1, 128);
+#if !defined(VSIP_IMPL_SAL_FFT)
   test_real<float>(2, 242);
+#endif
   test_real<float>(3, 16);
 
 #endif 
@@ -942,17 +954,23 @@
 #if defined(VSIP_IMPL_FFT_USE_DOUBLE)
 
   test_by_ref<complex<double> >(2, 64);
+#if !defined(VSIP_IMPL_SAL_FFT)
   test_by_ref<complex<double> >(1, 68);
+#endif
   test_by_ref<complex<double> >(2, 256);
+#if !defined(VSIP_IMPL_SAL_FFT)
   test_by_ref<complex<double> >(2, 252);
   test_by_ref<complex<double> >(3, 17);
+#endif
 
   test_by_val<complex<double> >(1, 128);
   test_by_val<complex<double> >(2, 256);
   test_by_val<complex<double> >(3, 512);
 
   test_real<double>(1, 128);
+#if !defined(VSIP_IMPL_SAL_FFT)
   test_real<double>(2, 242);
+#endif
   test_real<double>(3, 16);
 
 #endif 
@@ -960,18 +978,24 @@
 #if defined(VSIP_IMPL_FFT_USE_LONG_DOUBLE)
 
 #if ! defined(VSIP_IMPL_IPP_FFT)
+#if !defined(VSIP_IMPL_SAL_FFT)
   test_by_ref<complex<long double> >(2, 64);
+#endif 
   test_by_ref<complex<long double> >(1, 68);
   test_by_ref<complex<long double> >(2, 256);
+#if !defined(VSIP_IMPL_SAL_FFT)
   test_by_ref<complex<long double> >(2, 252);
   test_by_ref<complex<long double> >(3, 17);
+#endif 
 
   test_by_val<complex<long double> >(1, 128);
   test_by_val<complex<long double> >(2, 256);
   test_by_val<complex<long double> >(3, 512);
 
   test_real<long double>(1, 128);
+#if !defined(VSIP_IMPL_SAL_FFT)
   test_real<long double>(2, 242);
+#endif 
   test_real<long double>(3, 16);
 #endif
 
@@ -988,14 +1012,17 @@
   test_fft<0,0,float,false,2,vsip::fft_fwd>();
 
 #if ! defined(VSIP_IMPL_IPP_FFT)
+#if ! defined(VSIP_IMPL_SAL_FFT)
   test_fft<0,0,float,false,3,vsip::fft_fwd>();
-
+#endif
   test_fft<0,0,float,true,2,1>();
   test_fft<0,0,float,true,2,0>();
 
+#if ! defined(VSIP_IMPL_SAL_FFT)
   test_fft<0,0,float,true,3,2>();
   test_fft<0,0,float,true,3,1>();
   test_fft<0,0,float,true,3,0>();
+#endif
 #endif   /* VSIP_IMPL_IPP_FFT */
 
 #endif 
@@ -1004,14 +1031,17 @@
 
 #if ! defined(VSIP_IMPL_IPP_FFT)
   test_fft<0,0,double,false,2,vsip::fft_fwd>();
+#if ! defined(VSIP_IMPL_SAL_FFT)
   test_fft<0,0,double,false,3,vsip::fft_fwd>();
-
+#endif
   test_fft<0,0,double,true,2,1>();
   test_fft<0,0,double,true,2,0>();
 
+#if ! defined(VSIP_IMPL_SAL_FFT)
   test_fft<0,0,double,true,3,2>();
   test_fft<0,0,double,true,3,1>();
   test_fft<0,0,double,true,3,0>();
+#endif
 #endif  /* VSIP_IMPL_IPP_FFT */
 
 #endif
@@ -1020,14 +1050,17 @@
 
 #if ! defined(VSIP_IMPL_IPP_FFT)
   test_fft<0,0,double,false,2,vsip::fft_fwd>();
+#if ! defined(VSIP_IMPL_SAL_FFT)
   test_fft<0,0,double,false,3,vsip::fft_fwd>();
-
+#endif
   test_fft<0,0,double,true,2,1>();
   test_fft<0,0,double,true,2,0>();
 
+#if ! defined(VSIP_IMPL_SAL_FFT)
   test_fft<0,0,double,true,3,2>();
   test_fft<0,0,double,true,3,1>();
   test_fft<0,0,double,true,3,0>();
+#endif
 #endif  /* VSIP_IMPL_IPP_FFT */
 
 #endif
@@ -1075,7 +1108,7 @@
   test_fft<2,2,SCALAR,true,2,1>();
   test_fft<2,2,SCALAR,true,2,0>();
 
-
+#if ! defined(VSIP_IMPL_SAL_FFT)
   test_fft<0,1,SCALAR,false,3,vsip::fft_fwd>();
   test_fft<0,2,SCALAR,false,3,vsip::fft_fwd>();
   test_fft<1,0,SCALAR,false,3,vsip::fft_fwd>();
@@ -1111,7 +1144,7 @@
   test_fft<2,2,SCALAR,true,3,2>();
   test_fft<2,2,SCALAR,true,3,1>();
   test_fft<2,2,SCALAR,true,3,0>();
-
+#endif
 #endif  /* VSIP_IMPL_IPP_FFT */
 
 #endif
