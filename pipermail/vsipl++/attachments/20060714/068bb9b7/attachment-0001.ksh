Index: src/vsip/impl/profile.hpp
===================================================================
--- src/vsip/impl/profile.hpp	(revision 144534)
+++ src/vsip/impl/profile.hpp	(working copy)
@@ -339,14 +339,14 @@
 
 extern Profiler* prof;
 
-class Scope_enable
+class Profile
 {
 public:
-  Scope_enable(char *filename)
+  Profile(char *filename)
     : filename_(filename)
   { prof->set_mode( pm_accum ); }
 
-  ~Scope_enable() { prof->dump( this->filename_ ); }
+  ~ Profile() { prof->dump( this->filename_ ); }
 
 private:
   char* const filename_;
Index: src/vsip_csl/error_db.hpp
===================================================================
--- src/vsip_csl/error_db.hpp	(revision 144534)
+++ src/vsip_csl/error_db.hpp	(working copy)
@@ -1,22 +1,26 @@
 /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    error_db.cpp
+/** @file    vsip_csl/error_db.cpp
     @author  Jules Bergmann
     @date    2005-12-12
-    @brief   VSIPL++ Library: Measure difference between views in decibels.
+    @brief   VSIPL++ CodeSourcery Library: Measure difference between 
+             views in decibels.
 */
 
-#ifndef VSIP_TESTS_ERROR_DB_HPP
-#define VSIP_TESTS_ERROR_DB_HPP
+#ifndef VSIP_CSL_ERROR_DB_HPP
+#define VSIP_CSL_ERROR_DB_HPP
 
 /***********************************************************************
   Included Files
 ***********************************************************************/
 
 #include <vsip/math.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 
+namespace vsip_csl
+{
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -48,4 +52,6 @@
   return maxsum;
 }
 
-#endif // VSIP_TESTS_ERROR_DB_HPP
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_ERROR_DB_HPP
Index: src/vsip_csl/output.hpp
===================================================================
--- src/vsip_csl/output.hpp	(revision 144538)
+++ src/vsip_csl/output.hpp	(working copy)
@@ -1,13 +1,13 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    tests/output.hpp
+/** @file    vsip_csl/output.hpp
     @author  Jules Bergmann
-    @date    03/22/2005
-    @brief   VSIPL++ Library: Output utilities.
+    @date    2005-03-22
+    @brief   VSIPL++ CodeSourcery Library: Output utilities.
 */
 
-#ifndef VSIP_TESTS_OUTPUT_HPP
-#define VSIP_TESTS_OUTPUT_HPP
+#ifndef VSIP_CSL_OUTPUT_HPP
+#define VSIP_CSL_OUTPUT_HPP
 
 /***********************************************************************
   Included Files
@@ -17,19 +17,18 @@
 #include <vsip/domain.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
-#include <vsip/domain.hpp>
 
 
 
+namespace vsip_csl
+{
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
 
 /// Write a Domain<1> object to an output stream.
 
-namespace vsip
-{
-
 inline
 std::ostream&
 operator<<(
@@ -137,9 +136,8 @@
 }
 
 
+/// Write a Length to a stream.
 
-/// Write an Length to a stream.
-
 template <vsip::dimension_type Dim>
 inline
 std::ostream&
@@ -160,4 +158,4 @@
 
 } // namespace vsip
 
-#endif // VSIP_OUTPUT_HPP
+#endif // VSIP_CSL_OUTPUT_HPP
Index: src/vsip_csl/ref_corr.hpp
===================================================================
--- src/vsip_csl/ref_corr.hpp	(revision 144534)
+++ src/vsip_csl/ref_corr.hpp	(working copy)
@@ -1,13 +1,14 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    ref_corr.cpp
+/** @file    vsip_csl/ref_corr.cpp
     @author  Jules Bergmann
     @date    2005-12-09
-    @brief   VSIPL++ Library: Reference implementation of correlation
+    @brief   VSIPL++ CodeSourcery Library: Reference implementation of 
+             correlation function.
 */
 
-#ifndef VSIP_REF_CORR_HPP
-#define VSIP_REF_CORR_HPP
+#ifndef VSIP_CSL_REF_CORR_HPP
+#define VSIP_CSL_REF_CORR_HPP
 
 /***********************************************************************
   Included Files
@@ -18,6 +19,14 @@
 #include <vsip/random.hpp>
 #include <vsip/selgen.hpp>
 
+
+namespace vsip_csl
+{
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
 namespace ref
 {
 
@@ -222,5 +231,6 @@
 }
 
 } // namespace ref
+} // namespace vsip_csl
 
-#endif // VSIP_REF_CORR_HPP
+#endif // VSIP_CSL_REF_CORR_HPP
Index: src/vsip_csl/ref_conv.hpp
===================================================================
--- src/vsip_csl/ref_conv.hpp	(revision 144534)
+++ src/vsip_csl/ref_conv.hpp	(working copy)
@@ -1,13 +1,14 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    ref_conv.cpp
+/** @file    vsip_csl/ref_conv.cpp
     @author  Jules Bergmann
     @date    2005-12-28
-    @brief   VSIPL++ Library: Reference implementation of convolution
+    @brief   VSIPL++ CodeSourcery Library: Reference implementation of 
+             convolution function.
 */
 
-#ifndef VSIP_REF_CORR_HPP
-#define VSIP_REF_CORR_HPP
+#ifndef VSIP_CSL_REF_CORR_HPP
+#define VSIP_CSL_REF_CORR_HPP
 
 /***********************************************************************
   Included Files
@@ -19,6 +20,14 @@
 #include <vsip/selgen.hpp>
 #include <vsip/parallel.hpp>
 
+
+namespace vsip_csl
+{
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
 namespace ref
 {
 
@@ -168,5 +177,6 @@
 }
 
 } // namespace ref
+} // namespace vsip_csl
 
-#endif // VSIP_REF_CORR_HPP
+#endif // VSIP_CSL_REF_CORR_HPP
Index: src/vsip_csl/test-precision.hpp
===================================================================
--- src/vsip_csl/test-precision.hpp	(revision 144536)
+++ src/vsip_csl/test-precision.hpp	(working copy)
@@ -1,13 +1,13 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    tests/test-precision.cpp
+/** @file    vsip_csl/test-precision.cpp
     @author  Jules Bergmann
     @date    2005-09-12
-    @brief   VSIPL++ Library: Precision traits for tests.
+    @brief   VSIPL++ CodeSourcery Library: Precision traits for tests.
 */
 
-#ifndef VSIP_TESTS_TEST_PRECISION_HPP
-#define VSIP_TESTS_TEST_PRECISION_HPP
+#ifndef VSIP_CSL_TEST_PRECISION_HPP
+#define VSIP_CSL_TEST_PRECISION_HPP
 
 /***********************************************************************
   Included Files
@@ -17,6 +17,9 @@
 
 
 
+namespace vsip_csl
+{
+
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -48,4 +51,6 @@
   }
 };
 
-#endif // VSIP_TESTS_TEST_PRECISION_HPP
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_TEST_PRECISION_HPP
Index: src/vsip_csl/ref_dft.hpp
===================================================================
--- src/vsip_csl/ref_dft.hpp	(revision 144534)
+++ src/vsip_csl/ref_dft.hpp	(working copy)
@@ -1,13 +1,14 @@
 /* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
 
-/** @file    ref_dft.cpp
+/** @file    vsip_csl/ref_dft.cpp
     @author  Jules Bergmann
     @date    2006-03-03
-    @brief   VSIPL++ Library: Reference implementation of DFT.
+    @brief   VSIPL++ CodeSourcery Library: Reference implementation of 
+             Discrete Fourier Transform function.
 */
 
-#ifndef VSIP_REF_DFT_HPP
-#define VSIP_REF_DFT_HPP
+#ifndef VSIP_CSL_REF_DFT_HPP
+#define VSIP_CSL_REF_DFT_HPP
 
 /***********************************************************************
   Included Files
@@ -20,6 +21,8 @@
 #include <vsip/math.hpp>
 
 
+namespace vsip_csl
+{
 
 /***********************************************************************
   Definitions
@@ -144,5 +147,6 @@
 }
 
 } // namespace ref
+} // namespace vsip_csl
 
-#endif // VSIP_REF_DFT_HPP
+#endif // VSIP_CSL_REF_DFT_HPP
Index: src/vsip_csl/load_view.hpp
===================================================================
--- src/vsip_csl/load_view.hpp	(revision 144539)
+++ src/vsip_csl/load_view.hpp	(working copy)
@@ -1,13 +1,13 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    tests/load_view.hpp
+/** @file    vsip_csl/load_view.hpp
     @author  Jules Bergmann
     @date    2005-09-30
-    @brief   VSIPL++ Library: Utility to load a view from disk.
+    @brief   VSIPL++ CodeSourcery Library: Utility to load a view from disk.
 */
 
-#ifndef VSIP_TEST_LOAD_VIEW_HPP
-#define VSIP_TEST_LOAD_VIEW_HPP
+#ifndef VSIP_CSL_LOAD_VIEW_HPP
+#define VSIP_CSL_LOAD_VIEW_HPP
 
 /***********************************************************************
   Included Files
@@ -19,6 +19,9 @@
 
 
 
+namespace vsip_csl
+{
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -53,7 +56,7 @@
   typedef typename vsip::impl::View_of_dim<Dim, T, block_t>::type view_t;
 
 public:
-  Load_view(char*                    filename,
+  Load_view(char const*              filename,
 	    vsip::Domain<Dim> const& dom)
     : data_  (new base_t[factor*dom.size()]),
       block_ (dom, data_),
@@ -110,4 +113,6 @@
   view_t        view_;
 };
 
-#endif // VSIP_TEST_LOAD_VIEW_HPP
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_LOAD_VIEW_HPP
Index: src/vsip_csl/ref_matvec.hpp
===================================================================
--- src/vsip_csl/ref_matvec.hpp	(revision 144534)
+++ src/vsip_csl/ref_matvec.hpp	(working copy)
@@ -1,13 +1,14 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    tests/ref_matvec.hpp
+/** @file    vsip_csl/ref_matvec.hpp
     @author  Jules Bergmann
     @date    2005-10-11
-    @brief   VSIPL++ Library: Reference implementations of matvec routines.
+    @brief   VSIPL++ CodeSourcery Library: Reference implementations of 
+             matvec routines.
 */
 
-#ifndef VSIP_REF_MATVEC_HPP
-#define VSIP_REF_MATVEC_HPP
+#ifndef VSIP_CSL_REF_MATVEC_HPP
+#define VSIP_CSL_REF_MATVEC_HPP
 
 /***********************************************************************
   Included Files
@@ -19,6 +20,8 @@
 #include <vsip/vector.hpp>
 
 
+namespace vsip_csl
+{
 
 /***********************************************************************
   Reference Definitions
@@ -197,5 +200,6 @@
 
 
 } // namespace ref
+} // namespace vsip_csl
 
-#endif // VSIP_REF_MATVEC_HPP
+#endif // VSIP_CSL_REF_MATVEC_HPP
Index: src/vsip_csl/test.hpp
===================================================================
--- src/vsip_csl/test.hpp	(revision 144535)
+++ src/vsip_csl/test.hpp	(working copy)
@@ -1,14 +1,14 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    tests/test.hpp
+/** @file    vsip_csl/test.hpp
     @author  Jules Bergmann
     @date    01/25/2005
-    @brief   VSIPL++ Library: Common declarations and defintions for
-             testing.
+    @brief   VSIPL++ CodeSourcery Library: Common declarations and 
+             definitions for testing.
 */
 
-#ifndef VSIP_TESTS_TEST_HPP
-#define VSIP_TESTS_TEST_HPP
+#ifndef VSIP_CSL_TEST_HPP
+#define VSIP_CSL_TEST_HPP
 
 /***********************************************************************
   Included Files
@@ -24,6 +24,9 @@
 #include <vsip/tensor.hpp>
 
 
+namespace vsip_csl
+{
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -264,6 +267,6 @@
 		     (test_assert_fail(__TEST_STRING(expr), __FILE__, __LINE__, \
 				       TEST_ASSERT_FUNCTION), 0)))
 
+} // namespace vsip_csl
 
-
-#endif // VSIP_TESTS_TEST_HPP
+#endif // VSIP_CSL_TEST_HPP
Index: src/vsip_csl/save_view.hpp
===================================================================
--- src/vsip_csl/save_view.hpp	(revision 144534)
+++ src/vsip_csl/save_view.hpp	(working copy)
@@ -1,13 +1,13 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    tests/save_view.cpp
+/** @file    vsip_csl/save_view.cpp
     @author  Jules Bergmann
     @date    2005-09-30
-    @brief   VSIPL++ Library: Utility to save a view to disk.
+    @brief   VSIPL++ CodeSourcery Library: Utility to save a view to disk.
 */
 
-#ifndef VSIP_TEST_SAVE_VIEW_HPP
-#define VSIP_TEST_SAVE_VIEW_HPP
+#ifndef VSIP_CSL_SAVE_VIEW_HPP
+#define VSIP_CSL_SAVE_VIEW_HPP
 
 /***********************************************************************
   Included Files
@@ -19,6 +19,9 @@
 
 
 
+namespace vsip_csl
+{
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -133,4 +136,7 @@
 {
    Save_view<3, T>::save(filename, view);
 }
-#endif // VSIP_TEST_SAVE_VIEW_HPP
+
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_SAVE_VIEW_HPP
Index: vendor/GNUmakefile.inc.in
===================================================================
--- vendor/GNUmakefile.inc.in	(revision 144534)
+++ vendor/GNUmakefile.inc.in	(working copy)
@@ -171,9 +171,10 @@
 
 clean::
 	@echo "Cleaning FFTW (see fftw.clean.log)"
-	@for ldir in $(subst /.libs/,,$(dir $(vendor_FFTW_LIBS))); do \
-	  echo "$(MAKE) -C $$ldir clean "; \
-	  $(MAKE) -C $$ldir clean; done  > fftw.clean.log 2>&1
+	@rm -f fftw.clean.log
+	@for ldir in $(subst .a,,$(subst lib/lib,,$(vendor_FFTW_LIBS))); do \
+	  $(MAKE) -C vendor/$$ldir clean >> fftw.clean.log 2>&1; \
+	  echo "$(MAKE) -C vendor/$$ldir clean "; done
 
 install:: $(vendor_FFTW_LIBS)
 	@echo "Installing FFTW"
Index: tests/rt_extdata.cpp
===================================================================
--- tests/rt_extdata.cpp	(revision 144534)
+++ tests/rt_extdata.cpp	(working copy)
@@ -17,10 +17,11 @@
 #include <vsip/map.hpp>
 #include <vsip/impl/rt_extdata.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "util.hpp"
 
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::Rt_layout;
 using vsip::impl::Rt_tuple;
Index: tests/extdata-subviews.cpp
===================================================================
--- tests/extdata-subviews.cpp	(revision 144534)
+++ tests/extdata-subviews.cpp	(working copy)
@@ -19,15 +19,15 @@
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "plainblock.hpp"
 #include "extdata-output.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/reductions-idx.cpp
===================================================================
--- tests/reductions-idx.cpp	(revision 144534)
+++ tests/reductions-idx.cpp	(working copy)
@@ -15,14 +15,14 @@
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "test-storage.hpp"
 
 
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   maxval tests.
 ***********************************************************************/
Index: tests/user_storage.cpp
===================================================================
--- tests/user_storage.cpp	(revision 144534)
+++ tests/user_storage.cpp	(working copy)
@@ -16,10 +16,11 @@
 #include <vsip/dense.hpp>
 #include <vsip/impl/domain-utils.hpp>
 #include <vsip/impl/length.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::Length;
 
Index: tests/sal-assumptions.cpp
===================================================================
--- tests/sal-assumptions.cpp	(revision 144534)
+++ tests/sal-assumptions.cpp	(working copy)
@@ -15,11 +15,12 @@
 #include <iostream>
 #include <vsip/initfin.hpp>
 #include <vsip/impl/layout.hpp>
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 #ifdef VSIP_IMPL_HAVE_SAL
 #include <sal.h>
Index: tests/subblock.cpp
===================================================================
--- tests/subblock.cpp	(revision 144534)
+++ tests/subblock.cpp	(working copy)
@@ -16,8 +16,10 @@
 #include <vsip/domain.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/impl/subblock.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
+using namespace vsip_csl;
+
 using vsip::dimension_type;
 using vsip::index_type;
 using vsip::Domain;
Index: tests/window.cpp
===================================================================
--- tests/window.cpp	(revision 144534)
+++ tests/window.cpp	(working copy)
@@ -15,7 +15,7 @@
 #include <vsip/support.hpp>
 #include <vsip/signal.hpp>
 #include <vsip/vector.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 #if VSIP_IMPL_SAL_FFT
 #  define TEST_NON_POWER_OF_2  0
@@ -24,7 +24,9 @@
 #endif
 
 using namespace vsip;
+using namespace vsip_csl;
 
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/replicated_map.cpp
===================================================================
--- tests/replicated_map.cpp	(revision 144534)
+++ tests/replicated_map.cpp	(working copy)
@@ -14,13 +14,13 @@
 #include <vsip/map.hpp>
 #include <vsip/initfin.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/initfini.cpp
===================================================================
--- tests/initfini.cpp	(revision 144534)
+++ tests/initfini.cpp	(working copy)
@@ -16,11 +16,13 @@
 #include <iostream>
 #include <vsip/initfin.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/fns_scalar.cpp
===================================================================
--- tests/fns_scalar.cpp	(revision 144534)
+++ tests/fns_scalar.cpp	(working copy)
@@ -20,7 +20,7 @@
 #include <vsip/matrix.hpp>
 #include <vsip/math.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "test-storage.hpp"
 
 
@@ -31,6 +31,7 @@
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 template <dimension_type Dim,
 	  typename       T1,
Index: tests/map.cpp
===================================================================
--- tests/map.cpp	(revision 144534)
+++ tests/map.cpp	(working copy)
@@ -14,13 +14,13 @@
 #include <vsip/support.hpp>
 #include <vsip/map.hpp>
 #include <vsip/initfin.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/scalar-view.cpp
===================================================================
--- tests/scalar-view.cpp	(revision 144534)
+++ tests/scalar-view.cpp	(working copy)
@@ -16,14 +16,14 @@
 #include <vsip/selgen.hpp>
 #include <vsip/math.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "test-storage.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/ref_dft.hpp
===================================================================
--- tests/ref_dft.hpp	(revision 144534)
+++ tests/ref_dft.hpp	(working copy)
@@ -1,148 +0,0 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    ref_dft.cpp
-    @author  Jules Bergmann
-    @date    2006-03-03
-    @brief   VSIPL++ Library: Reference implementation of DFT.
-*/
-
-#ifndef VSIP_REF_DFT_HPP
-#define VSIP_REF_DFT_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <cassert>
-
-#include <vsip/complex.hpp>
-#include <vsip/vector.hpp>
-#include <vsip/math.hpp>
-
-
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-namespace ref
-{
-
-/// Return sin and cos of phi as complex.
-
-template <typename T>
-inline vsip::complex<T>
-sin_cos(double phi)
-{
-  return vsip::complex<T>(cos(phi), sin(phi));
-}
-
-
-
-// Reference 1-D DFT algorithm.  Brutes it out, but easy to validate
-// and works for any size.
-
-// Requires:
-//   IN to be input Vector.
-//   OUT to be output Vector, of same size as IN.
-//   IDIR to be sign of exponential.
-//     -1 => Forward Fft,
-//     +1 => Inverse Fft.
-
-template <typename T1,
-	  typename T2,
-	  typename Block1,
-	  typename Block2>
-void dft(
-  vsip::const_Vector<T1, Block1> in,
-  vsip::Vector<T2, Block2>       out,
-  int                            idir)
-{
-  using vsip::length_type;
-  using vsip::index_type;
-
-  length_type const size = in.size();
-  assert(sizeof(T1) <  sizeof(T2) && in.size()/2 + 1 == out.size() ||
-	 sizeof(T1) == sizeof(T2) && in.size() == out.size());
-  typedef double AccT;
-
-  AccT const phi = idir * 2.0 * M_PI/size;
-
-  for (index_type w=0; w<out.size(); ++w)
-  {
-    vsip::complex<AccT> sum = vsip::complex<AccT>();
-    for (index_type k=0; k<in.size(); ++k)
-      sum += vsip::complex<AccT>(in(k)) * sin_cos<AccT>(phi*k*w);
-    out.put(w, T2(sum));
-  }
-}
-
-
-
-// Reference 1-D multi-DFT algorithm on rows of a matrix.
-
-// Requires:
-//   IN to be input Matrix.
-//   OUT to be output Matrix, of same size as IN.
-//   IDIR to be sign of exponential.
-//     -1 => Forward Fft,
-//     +1 => Inverse Fft.
-
-template <typename T,
-	  typename Block1,
-	  typename Block2>
-void dft_x(
-  vsip::Matrix<vsip::complex<T>, Block1> in,
-  vsip::Matrix<vsip::complex<T>, Block2> out,
-  int                                    idir)
-{
-  test_assert(in.size(0) == out.size(0));
-  test_assert(in.size(1) == out.size(1));
-  test_assert(in.local().size(0) == out.local().size(0));
-  test_assert(in.local().size(1) == out.local().size(1));
-
-  for (vsip::index_type r=0; r < in.local().size(0); ++r)
-    dft(in.local().row(r), out.local().row(r), idir);
-}
-
-
-
-// Reference 1-D multi-DFT algorithm on columns of a matrix.
-
-template <typename T,
-	  typename Block1,
-	  typename Block2>
-void dft_y(
-  vsip::Matrix<vsip::complex<T>, Block1> in,
-  vsip::Matrix<vsip::complex<T>, Block2> out,
-  int                                    idir)
-{
-  test_assert(in.size(0) == out.size(0));
-  test_assert(in.size(1) == out.size(1));
-  test_assert(in.local().size(0) == out.local().size(0));
-  test_assert(in.local().size(1) == out.local().size(1));
-
-  for (vsip::index_type c=0; c < in.local().size(1); ++c)
-    dft(in.local().col(c), out.local().col(c), idir);
-}
-
-
-template <typename T,
-	  typename Block1,
-	  typename Block2>
-void dft_y_real(
-  vsip::Matrix<T, Block1> in,
-  vsip::Matrix<vsip::complex<T>, Block2> out)
-{
-  test_assert(in.size(0)/2 + 1 == out.size(0));
-  test_assert(in.size(1) == out.size(1));
-  test_assert(in.local().size(0)/2 + 1 == out.local().size(0));
-  test_assert(in.local().size(1) == out.local().size(1));
-
-  for (vsip::index_type c=0; c < in.local().size(1); ++c)
-    dft(in.local().col(c), out.local().col(c), -1);
-}
-
-} // namespace ref
-
-#endif // VSIP_REF_DFT_HPP
Index: tests/matrix-transpose.cpp
===================================================================
--- tests/matrix-transpose.cpp	(revision 144534)
+++ tests/matrix-transpose.cpp	(working copy)
@@ -17,13 +17,13 @@
 #include <vsip/support.hpp>
 #include <vsip/matrix.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/regressions/fft_temp_view.cpp
===================================================================
--- tests/regressions/fft_temp_view.cpp	(revision 144534)
+++ tests/regressions/fft_temp_view.cpp	(working copy)
@@ -19,13 +19,13 @@
 #include <vsip/vector.hpp>
 #include <vsip/signal.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/regressions/proxy_lvalue_conv.cpp
===================================================================
--- tests/regressions/proxy_lvalue_conv.cpp	(revision 144534)
+++ tests/regressions/proxy_lvalue_conv.cpp	(working copy)
@@ -20,14 +20,14 @@
 #include <vsip/initfin.hpp>
 #include <vsip/vector.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "plainblock.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/regressions/transpose.cpp
===================================================================
--- tests/regressions/transpose.cpp	(revision 144534)
+++ tests/regressions/transpose.cpp	(working copy)
@@ -16,9 +16,10 @@
 #include <vsip/matrix.hpp>
 #include <vsip/domain.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace vsip;
+using namespace vsip_csl;
 
 
 /***********************************************************************
Index: tests/regressions/ext_subview_split.cpp
===================================================================
--- tests/regressions/ext_subview_split.cpp	(revision 144534)
+++ tests/regressions/ext_subview_split.cpp	(working copy)
@@ -16,13 +16,13 @@
 #include <vsip/tensor.hpp>
 #include <vsip/impl/fast-block.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/regressions/view_index.cpp
===================================================================
--- tests/regressions/view_index.cpp	(revision 144534)
+++ tests/regressions/view_index.cpp	(working copy)
@@ -16,12 +16,12 @@
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/regressions/const_view_at_op.cpp
===================================================================
--- tests/regressions/const_view_at_op.cpp	(revision 144534)
+++ tests/regressions/const_view_at_op.cpp	(working copy)
@@ -17,13 +17,13 @@
 #include <vsip/initfin.hpp>
 #include <vsip/vector.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Vector coverage
 ***********************************************************************/
Index: tests/regressions/subview_exprs.cpp
===================================================================
--- tests/regressions/subview_exprs.cpp	(revision 144534)
+++ tests/regressions/subview_exprs.cpp	(working copy)
@@ -17,13 +17,13 @@
 #include <vsip/initfin.hpp>
 #include <vsip/vector.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/regressions/transpose-mirror.cpp
===================================================================
--- tests/regressions/transpose-mirror.cpp	(revision 144534)
+++ tests/regressions/transpose-mirror.cpp	(working copy)
@@ -17,9 +17,10 @@
 #include <vsip/matrix.hpp>
 #include <vsip/domain.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace vsip;
+using namespace vsip_csl;
 
 
 /***********************************************************************
Index: tests/regressions/transpose-nonunit.cpp
===================================================================
--- tests/regressions/transpose-nonunit.cpp	(revision 144534)
+++ tests/regressions/transpose-nonunit.cpp	(working copy)
@@ -17,9 +17,10 @@
 #include <vsip/matrix.hpp>
 #include <vsip/domain.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace vsip;
+using namespace vsip_csl;
 
 
 /***********************************************************************
Index: tests/regressions/complex_proxy.cpp
===================================================================
--- tests/regressions/complex_proxy.cpp	(revision 144534)
+++ tests/regressions/complex_proxy.cpp	(working copy)
@@ -52,13 +52,13 @@
 #include <vsip/impl/static_assert.hpp>
 #include <vsip/impl/metaprogramming.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
+using namespace std;
 using namespace vsip;
-using namespace std;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/regressions/localview_of_slice.cpp
===================================================================
--- tests/regressions/localview_of_slice.cpp	(revision 144534)
+++ tests/regressions/localview_of_slice.cpp	(working copy)
@@ -23,13 +23,13 @@
 #include <vsip/matrix.hpp>
 #include <vsip/map.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/regressions/conv_to_subview.cpp
===================================================================
--- tests/regressions/conv_to_subview.cpp	(revision 144534)
+++ tests/regressions/conv_to_subview.cpp	(working copy)
@@ -19,13 +19,13 @@
 #include <vsip/vector.hpp>
 #include <vsip/signal.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/view_lvalue.cpp
===================================================================
--- tests/view_lvalue.cpp	(revision 144534)
+++ tests/view_lvalue.cpp	(working copy)
@@ -14,9 +14,12 @@
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "plainblock.hpp"
 
+using namespace vsip_csl;
+
+
 template <typename View>
 static void
 probe_vector (View v)
Index: tests/iir.cpp
===================================================================
--- tests/iir.cpp	(revision 144534)
+++ tests/iir.cpp	(working copy)
@@ -14,21 +14,21 @@
 #include <vsip/signal.hpp>
 #include <vsip/initfin.hpp>
 
-#include "test.hpp"
-#include "error_db.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/error_db.hpp>
 
 #define VERBOSE 0
 
 #ifdef VERBOSE
-#  include "output.hpp"
+#  include <vsip_csl/output.hpp>
 #endif
 
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Test IIR as single FIR -- no recursion
 ***********************************************************************/
Index: tests/test.hpp
===================================================================
--- tests/test.hpp	(revision 144534)
+++ tests/test.hpp	(working copy)
@@ -1,269 +0,0 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    tests/test.hpp
-    @author  Jules Bergmann
-    @date    01/25/2005
-    @brief   VSIPL++ Library: Common declarations and defintions for
-             testing.
-*/
-
-#ifndef VSIP_TESTS_TEST_HPP
-#define VSIP_TESTS_TEST_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <cstdlib>
-#include <cassert>
-
-#include <vsip/support.hpp>
-#include <vsip/complex.hpp>
-#include <vsip/vector.hpp>
-#include <vsip/matrix.hpp>
-#include <vsip/tensor.hpp>
-
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-// Define level of testing
-//   0 - low-level (avoid long-running and long-compiling tests)
-//   1 - default
-//   2 - high-level (enable long-running tests)
-
-#ifndef VSIP_IMPL_TEST_LEVEL
-#  define VSIP_IMPL_TEST_LEVEL 1
-#endif
-
-
-/// Compare two floating-point values for equality.
-///
-/// Algorithm from:
-///    www.cygnus-software.com/papers/comparingfloats/comparingfloats.htm
-
-template <typename T>
-bool
-almost_equal(
-  T	A,
-  T	B,
-  T	rel_epsilon = 1e-4,
-  T	abs_epsilon = 1e-6)
-{
-  if (vsip::mag(A - B) < abs_epsilon)
-    return true;
-
-  T relative_error;
-
-  if (vsip::mag(B) > vsip::mag(A))
-    relative_error = vsip::mag((A - B) / B);
-  else
-    relative_error = vsip::mag((B - A) / A);
-
-  return (relative_error <= rel_epsilon);
-}
-
-
-
-template <typename T>
-bool
-almost_equal(
-  std::complex<T>	A,
-  std::complex<T>	B,
-  T	rel_epsilon = 1e-4,
-  T	abs_epsilon = 1e-6)
-{
-  if (vsip::mag(A - B) < abs_epsilon)
-    return true;
-
-  T relative_error;
-
-  if (vsip::mag(B) > vsip::mag(A))
-    relative_error = vsip::mag((A - B) / B);
-  else
-    relative_error = vsip::mag((B - A) / A);
-
-  return (relative_error <= rel_epsilon);
-}
-
-
-
-/// Compare two values for equality.
-template <typename T>
-inline bool
-equal(T val1, T val2)
-{
-  return val1 == val2;
-}
-
-template <typename             T,
-	  typename             Block,
-	  vsip::dimension_type Dim>
-inline bool
-equal(
-  vsip::impl::Lvalue_proxy<T, Block, Dim> const& val1, 
-  T                                              val2)
-{
-  return equal(static_cast<T>(val1), val2);
-}
-
-template <typename             T,
-	  typename             Block,
-	  vsip::dimension_type Dim>
-inline bool
-equal(
-  T                                              val1,
-  vsip::impl::Lvalue_proxy<T, Block, Dim> const& val2) 
-{
-  return equal(val1, static_cast<T>(val2));
-}
-
-template <typename             T,
-	  typename             Block1,
-	  typename             Block2,
-	  vsip::dimension_type Dim1,
-	  vsip::dimension_type Dim2>
-inline bool
-equal(
-  vsip::impl::Lvalue_proxy<T, Block1, Dim1> const& val1,
-  vsip::impl::Lvalue_proxy<T, Block2, Dim2> const& val2)
-{
-  return equal(static_cast<T>(val1), static_cast<T>(val2));
-}
-
-template <typename             T,
-	  typename             Block,
-	  vsip::dimension_type Dim>
-inline bool
-equal(
-  vsip::impl::Lvalue_proxy<T, Block, Dim> const& val1,
-  vsip::impl::Lvalue_proxy<T, Block, Dim> const& val2)
-{
-  return equal(static_cast<T>(val1), static_cast<T>(val2));
-}
-
-
-
-/// Compare two floating point values for equality within epsilon.
-///
-/// Note: A fixed epsilon is not adequate for comparing the results
-///       of all floating point computations.  Epsilon should be choosen 
-///       based on the dynamic range of the computation.
-template <>
-inline bool
-equal(float val1, float val2)
-{
-  return almost_equal<float>(val1, val2);
-}
-
-
-
-/// Compare two floating point (double) values for equality within epsilon.
-template <>
-inline bool
-equal(double val1, double val2)
-{
-  return almost_equal<double>(val1, val2);
-}
-
-
-
-/// Compare two complex values for equality within epsilon.
-
-template <typename T>
-inline bool
-equal(vsip::complex<T> val1, vsip::complex<T> val2)
-{
-  return equal(val1.real(), val2.real()) &&
-         equal(val1.imag(), val2.imag());
-}
-
-template <typename T, typename Block1, typename Block2>
-inline bool
-view_equal(vsip::const_Vector<T, Block1> v, vsip::const_Vector<T, Block2> w)
-{
-  if (v.size() != w.size()) return false;
-  for (vsip::length_type i = 0; i != v.size(); ++i)
-    if (!equal(v.get(i), w.get(i)))
-      return false;
-  return true;
-}
-
-template <typename T, typename Block1, typename Block2>
-inline bool
-view_equal(vsip::const_Matrix<T, Block1> v, vsip::const_Matrix<T, Block2> w)
-{
-  if (v.size(0) != w.size(0) || v.size(1) != w.size(1)) return false;
-  for (vsip::length_type i = 0; i != v.size(0); ++i)
-    for (vsip::length_type j = 0; j != v.size(1); ++j)
-      if (!equal(v.get(i, j), w.get(i, j)))
-	return false;
-  return true;
-}
-
-template <typename T, typename Block1, typename Block2>
-inline bool
-view_equal(vsip::const_Tensor<T, Block1> v, vsip::const_Tensor<T, Block2> w)
-{
-  if (v.size(0) != w.size(0) ||
-      v.size(1) != w.size(1) ||
-      v.size(2) != w.size(2)) return false;
-  for (vsip::length_type i = 0; i != v.size(0); ++i)
-    for (vsip::length_type j = 0; j != v.size(1); ++j)
-      for (vsip::length_type k = 0; k != v.size(2); ++k)
-	if (!equal(v.get(i, j, k), w.get(i, j, k)))
-	  return false;
-  return true;
-}
-
-/// Use a variable.  Useful for tests that must create a variable but
-/// do not otherwise use it.
-
-template <typename T>
-inline void
-use_variable(T const& /*t*/)
-{
-}
-
-
-void inline
-test_assert_fail(
-  const char*  assertion,
-  const char*  file,
-  unsigned int line,
-  const char*  function)
-{
-  fprintf(stderr, "TEST ASSERT FAIL: %s %s %d %s\n",
-	  assertion, file, line, function);
-  abort();
-}
-
-#if defined(__GNU__)
-# if defined __cplusplus ? __GNUC_PREREQ (2, 6) : __GNUC_PREREQ (2, 4)
-#   define TEST_ASSERT_FUNCTION    __PRETTY_FUNCTION__
-# else
-#  if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
-#   define TEST_ASSERT_FUNCTION    __func__
-#  else
-#   define TEST_ASSERT_FUNCTION    ((__const char *) 0)
-#  endif
-# endif
-#else
-# define TEST_ASSERT_FUNCTION    ((__const char *) 0)
-#endif
-
-#ifdef __STDC__
-#  define __TEST_STRING(e) #e
-#else
-#  define __TEST_STRING(e) "e"
-#endif
-
-#define test_assert(expr)						\
-  (static_cast<void>((expr) ? 0 :					\
-		     (test_assert_fail(__TEST_STRING(expr), __FILE__, __LINE__, \
-				       TEST_ASSERT_FUNCTION), 0)))
-
-
-
-#endif // VSIP_TESTS_TEST_HPP
Index: tests/fft_be.cpp
===================================================================
--- tests/fft_be.cpp	(revision 144534)
+++ tests/fft_be.cpp	(working copy)
@@ -13,11 +13,12 @@
 #include <vsip/impl/fft/no_fft.hpp>
 #include <vsip/impl/type_list.hpp>
 #include <vsip/impl/fft.hpp>
-#include "test.hpp"
-#include "error_db.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/error_db.hpp>
+#include <vsip_csl/output.hpp>
 
 using namespace vsip;
+using namespace vsip_csl;
 
 // Construct one type-list per backend.
 // If the backend is not available, the evaluator will
Index: tests/fns_userelt.cpp
===================================================================
--- tests/fns_userelt.cpp	(revision 144534)
+++ tests/fns_userelt.cpp	(working copy)
@@ -17,9 +17,10 @@
 #include <vsip/vector.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/math.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace vsip;
+using namespace vsip_csl;
 
 typedef Vector<float, Dense<1, float> > DVector;
 typedef Vector<int, Dense<1, int> > IVector;
Index: tests/solver-qr.cpp
===================================================================
--- tests/solver-qr.cpp	(revision 144534)
+++ tests/solver-qr.cpp	(working copy)
@@ -18,8 +18,8 @@
 #include <vsip/solvers.hpp>
 #include <vsip/parallel.hpp>
 
-#include "test.hpp"
-#include "test-precision.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-precision.hpp>
 #include "test-random.hpp"
 #include "test-storage.hpp"
 #include "solver-common.hpp"
@@ -36,15 +36,15 @@
 
 #if VERBOSE
 #  include <iostream>
-#  include "output.hpp"
+#  include <vsip/csl/output.hpp>
 #  include "extdata-output.hpp"
 #endif
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Covsol tests
 ***********************************************************************/
Index: tests/histogram.cpp
===================================================================
--- tests/histogram.cpp	(revision 144534)
+++ tests/histogram.cpp	(working copy)
@@ -14,10 +14,12 @@
 #include <vsip/support.hpp>
 #include <vsip/signal.hpp>
 #include <vsip/random.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace vsip;
+using namespace vsip_csl;
 
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/save_view.hpp
===================================================================
--- tests/save_view.hpp	(revision 144534)
+++ tests/save_view.hpp	(working copy)
@@ -1,136 +0,0 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    tests/save_view.cpp
-    @author  Jules Bergmann
-    @date    2005-09-30
-    @brief   VSIPL++ Library: Utility to save a view to disk.
-*/
-
-#ifndef VSIP_TEST_SAVE_VIEW_HPP
-#define VSIP_TEST_SAVE_VIEW_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <vsip/vector.hpp>
-#include <vsip/matrix.hpp>
-#include <vsip/tensor.hpp>
-
-
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-template <typename T>
-struct Save_view_traits
-{
-   typedef T base_t;
-   static unsigned const factor = 1;
-};
-
-template <typename T>
-struct Save_view_traits<vsip::complex<T> >
-{
-   typedef T base_t;
-   static unsigned const factor = 2;
-};
-
-
-
-template <vsip::dimension_type Dim,
-	  typename             T>
-class Save_view
-{
-public:
-  typedef typename Save_view_traits<T>::base_t base_t;
-  static unsigned const factor = Save_view_traits<T>::factor;
-
-  typedef vsip::Dense<Dim, T> block_t;
-  typedef typename vsip::impl::View_of_dim<Dim, T, block_t>::type view_t;
-
-public:
-  static void save(char*  filename,
-		   view_t view)
-  {
-    vsip::Domain<Dim> dom(get_domain(view));
-    base_t*           data(new base_t[factor*dom.size()]);
-
-    block_t           block(dom, data);
-    view_t            store(block);
-
-    FILE*  fd;
-    size_t size = dom.size();
-
-    if (!(fd = fopen(filename,"w")))
-    {
-      fprintf(stderr,"Save_view: error opening '%s'.\n", filename);
-      exit(1);
-    }
-
-    block.admit(false);
-    store = view;
-    block.release(true);
-    
-    if (size != fwrite(data, sizeof(T), size, fd))
-    {
-      fprintf(stderr, "Save_view: Error writing.\n");
-      exit(1);
-    }
-
-    fclose(fd);
-  }
-
-private:
-  template <typename T1,
-	    typename Block1>
-  static vsip::Domain<1> get_domain(vsip::const_Vector<T1, Block1> view)
-  { return vsip::Domain<1>(view.size()); }
-
-  template <typename T1,
-	    typename Block1>
-  static vsip::Domain<2> get_domain(vsip::const_Matrix<T1, Block1> view)
-  { return vsip::Domain<2>(view.size(0), view.size(1)); }
-
-  template <typename T1,
-	    typename Block1>
-  static vsip::Domain<3> get_domain(vsip::const_Tensor<T1, Block1> view)
-  { return vsip::Domain<3>(view.size(0), view.size(1), view.size(2)); }
-};
-
-
-template <typename T,
-	  typename Block>
-void
-save_view(
-   char*                        filename,
-   vsip::const_Vector<T, Block> view)
-{
-   Save_view<1, T>::save(filename, view);
-}
-
-
-
-template <typename T,
-	  typename Block>
-void
-save_view(
-   char*                        filename,
-   vsip::const_Matrix<T, Block> view)
-{
-   Save_view<2, T>::save(filename, view);
-}
-
-
-
-template <typename T,
-	  typename Block>
-void
-save_view(
-   char*                        filename,
-   vsip::const_Tensor<T, Block> view)
-{
-   Save_view<3, T>::save(filename, view);
-}
-#endif // VSIP_TEST_SAVE_VIEW_HPP
Index: tests/solver-toepsol.cpp
===================================================================
--- tests/solver-toepsol.cpp	(revision 144534)
+++ tests/solver-toepsol.cpp	(working copy)
@@ -21,8 +21,8 @@
 #include <vsip/map.hpp>
 #include <vsip/parallel.hpp>
 
-#include "test.hpp"
-#include "test-precision.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-precision.hpp>
 #include "test-random.hpp"
 #include "solver-common.hpp"
 
@@ -31,15 +31,15 @@
 
 #if VERBOSE
 #  include <iostream>
-#  include "output.hpp"
+#  include <vsip/csl/output.hpp>
 #  include "extdata-output.hpp"
 #endif
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   function tests
 ***********************************************************************/
Index: tests/coverage_ternary.cpp
===================================================================
--- tests/coverage_ternary.cpp	(revision 144534)
+++ tests/coverage_ternary.cpp	(working copy)
@@ -18,15 +18,15 @@
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "test-storage.hpp"
 #include "coverage_common.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Ternary Operator Tests
 ***********************************************************************/
Index: tests/solver-llsqsol.cpp
===================================================================
--- tests/solver-llsqsol.cpp	(revision 144534)
+++ tests/solver-llsqsol.cpp	(working copy)
@@ -17,8 +17,8 @@
 #include <vsip/tensor.hpp>
 #include <vsip/solvers.hpp>
 
-#include "test.hpp"
-#include "test-precision.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-precision.hpp>
 #include "test-random.hpp"
 #include "solver-common.hpp"
 
@@ -27,15 +27,15 @@
 
 #if VERBOSE
 #  include <iostream>
-#  include "output.hpp"
+#  include <vsip/csl/output.hpp>
 #  include "extdata-output.hpp"
 #endif
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   llsqsol function using rsol tests
 ***********************************************************************/
Index: tests/error_db.hpp
===================================================================
--- tests/error_db.hpp	(revision 144534)
+++ tests/error_db.hpp	(working copy)
@@ -1,51 +0,0 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    error_db.cpp
-    @author  Jules Bergmann
-    @date    2005-12-12
-    @brief   VSIPL++ Library: Measure difference between views in decibels.
-*/
-
-#ifndef VSIP_TESTS_ERROR_DB_HPP
-#define VSIP_TESTS_ERROR_DB_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <vsip/math.hpp>
-#include "test.hpp"
-
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-template <template <typename, typename> class View1,
-	  template <typename, typename> class View2,
-	  typename                            T1,
-	  typename                            T2,
-	  typename                            Block1,
-	  typename                            Block2>
-inline double
-error_db(
-  View1<T1, Block1> v1,
-  View2<T2, Block2> v2)
-{
-  using vsip::impl::Dim_of_view;
-  using vsip::dimension_type;
-
-  test_assert(Dim_of_view<View1>::dim == Dim_of_view<View2>::dim);
-  dimension_type const dim = Dim_of_view<View2>::dim;
-
-  vsip::Index<dim> idx;
-
-  double refmax = maxval(magsq(v1), idx);
-  double maxsum = maxval(ite(magsq(v1 - v2) < 1.e-20,
-			     -201.0,
-			     10.0 * log10(magsq(v1 - v2)/(2.0*refmax)) ),
-			 idx);
-  return maxsum;
-}
-
-#endif // VSIP_TESTS_ERROR_DB_HPP
Index: tests/domain.cpp
===================================================================
--- tests/domain.cpp	(revision 144534)
+++ tests/domain.cpp	(working copy)
@@ -16,11 +16,13 @@
 #include <iostream>
 #include <vsip/domain.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/complex.cpp
===================================================================
--- tests/complex.cpp	(revision 144534)
+++ tests/complex.cpp	(working copy)
@@ -15,9 +15,10 @@
 
 #include <vsip/complex.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 
+using namespace vsip_csl;
 
 /***********************************************************************
   Macros
Index: tests/view_operators.cpp
===================================================================
--- tests/view_operators.cpp	(revision 144534)
+++ tests/view_operators.cpp	(working copy)
@@ -18,10 +18,11 @@
 #include <vsip/matrix.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/math.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 using namespace impl;
 
 // Test whether the operator '+' can be instantiated
Index: tests/reductions-bool.cpp
===================================================================
--- tests/reductions-bool.cpp	(revision 144534)
+++ tests/reductions-bool.cpp	(working copy)
@@ -15,13 +15,13 @@
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "test-storage.hpp"
 
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 void
 simple_tests()
 {
Index: tests/selgen.cpp
===================================================================
--- tests/selgen.cpp	(revision 144534)
+++ tests/selgen.cpp	(working copy)
@@ -15,10 +15,11 @@
 #include <complex>
 #include <vsip/selgen.hpp>
 #include <functional>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 using namespace impl;
 
 void 
Index: tests/matvec.cpp
===================================================================
--- tests/matvec.cpp	(revision 144534)
+++ tests/matvec.cpp	(working copy)
@@ -17,13 +17,14 @@
 #include <vsip/matrix.hpp>
 #include <vsip/math.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "test-random.hpp"
-#include "output.hpp"
-#include "ref_matvec.hpp"
+#include <vsip_csl/output.hpp>
+#include <vsip_csl/ref_matvec.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
 /***********************************************************************
Index: tests/extdata-matadd.cpp
===================================================================
--- tests/extdata-matadd.cpp	(revision 144534)
+++ tests/extdata-matadd.cpp	(working copy)
@@ -34,14 +34,14 @@
 #include <vsip/dense.hpp>
 #include <vsip/matrix.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "plainblock.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/refcount.cpp
===================================================================
--- tests/refcount.cpp	(revision 144534)
+++ tests/refcount.cpp	(working copy)
@@ -12,13 +12,13 @@
 
 #include <iostream>
 #include <vsip/impl/refcount.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/tensor-transpose.cpp
===================================================================
--- tests/tensor-transpose.cpp	(revision 144534)
+++ tests/tensor-transpose.cpp	(working copy)
@@ -17,15 +17,15 @@
 #include <vsip/support.hpp>
 #include <vsip/tensor.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 #define USE_TRANSPOSE_VIEW_TYPEDEF 1
 
-
-
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/freqswap.cpp
===================================================================
--- tests/freqswap.cpp	(revision 144534)
+++ tests/freqswap.cpp	(working copy)
@@ -14,10 +14,11 @@
 #include <vsip/support.hpp>
 #include <vsip/signal.hpp>
 #include <vsip/random.hpp>
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 
 using namespace vsip;
+using namespace vsip_csl;
 
 /***********************************************************************
   Definitions
Index: tests/dense.cpp
===================================================================
--- tests/dense.cpp	(revision 144534)
+++ tests/dense.cpp	(working copy)
@@ -15,13 +15,13 @@
 #include <vsip/support.hpp>
 #include <vsip/dense.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/expression.cpp
===================================================================
--- tests/expression.cpp	(revision 144534)
+++ tests/expression.cpp	(working copy)
@@ -15,11 +15,12 @@
 #include <vsip/math.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/map.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "block_interface.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 using namespace impl;
 
 /***********************************************************************
Index: tests/view_functions.cpp
===================================================================
--- tests/view_functions.cpp	(revision 144534)
+++ tests/view_functions.cpp	(working copy)
@@ -19,10 +19,11 @@
 #include <vsip/matrix.hpp>
 #include <vsip/dense.hpp>
 #include <vsip/math.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 using namespace impl;
 
 // Unary func(View) call.
Index: tests/vector.cpp
===================================================================
--- tests/vector.cpp	(revision 144534)
+++ tests/vector.cpp	(working copy)
@@ -18,10 +18,11 @@
 #include <cassert>
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
 template <typename T,
Index: tests/matrix.cpp
===================================================================
--- tests/matrix.cpp	(revision 144534)
+++ tests/matrix.cpp	(working copy)
@@ -18,10 +18,11 @@
 #include <cassert>
 #include <vsip/support.hpp>
 #include <vsip/matrix.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
 template <typename T,
Index: tests/solver-common.hpp
===================================================================
--- tests/solver-common.hpp	(revision 144534)
+++ tests/solver-common.hpp	(working copy)
@@ -20,7 +20,8 @@
 #include <vsip/complex.hpp>
 #include <vsip/matrix.hpp>
 
-#include "test-precision.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-precision.hpp>
 
 
 
@@ -166,7 +167,8 @@
 	guage += mag(a.get(i, k)) * mag(b.get(k, j));
       }
 
-      float err_ij = mag(tmp - c(i, j)) / Precision_traits<scalar_type>::eps;
+      float err_ij = mag(tmp - c(i, j)) / 
+        vsip_csl::Precision_traits<scalar_type>::eps;
       if (guage > scalar_type())
 	err_ij = err_ij/guage;
       err = std::max(err, err_ij);
@@ -205,59 +207,4 @@
     }
 }
 
-
-
-template <typename T,
-	  typename Block1,
-	  typename Block2>
-void
-compare_view(
-  vsip::const_Vector<T, Block1>           a,
-  vsip::const_Vector<T, Block2>           b,
-  typename vsip::impl::Scalar_of<T>::type thresh
-  )
-{
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-
-  vsip::Index<1> idx;
-  scalar_type err = vsip::maxval((mag(a - b)
-				  / Precision_traits<scalar_type>::eps),
-				 idx);
-
-  if (err > thresh)
-  {
-    for (vsip::index_type r=0; r<a.size(0); ++r)
-	test_assert(equal(a.get(r), b.get(r)));
-  }
-}
-
-
-
-template <typename T,
-	  typename Block1,
-	  typename Block2>
-void
-compare_view(
-  vsip::const_Matrix<T, Block1>           a,
-  vsip::const_Matrix<T, Block2>           b,
-  typename vsip::impl::Scalar_of<T>::type thresh
-  )
-{
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-
-  vsip::Index<2> idx;
-  scalar_type err = vsip::maxval((mag(a - b)
-				  / Precision_traits<scalar_type>::eps),
-				 idx);
-
-  if (err > thresh)
-  {
-    std::cout << "a = \n" << a;
-    std::cout << "b = \n" << b;
-    for (vsip::index_type r=0; r<a.size(0); ++r)
-      for (vsip::index_type c=0; c<a.size(1); ++c)
-	test_assert(equal(a.get(r, c), b.get(r, c)));
-  }
-}
-
 #endif // VSIP_TESTS_SOLVER_COMMON_HPP
Index: tests/lvalue-proxy.cpp
===================================================================
--- tests/lvalue-proxy.cpp	(revision 144534)
+++ tests/lvalue-proxy.cpp	(working copy)
@@ -8,16 +8,16 @@
     Explicit instantiation of lvalue proxy objects and tests of their
     functionality.  */
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include <vsip/impl/lvalue-proxy.hpp>
 #include <vsip/impl/static_assert.hpp>
 #include <vsip/impl/metaprogramming.hpp>
 #include <vsip/dense.hpp>
 
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 template <typename T>
 struct test_traits
 { static T value() { return T(1); } };
Index: tests/static_assert.cpp
===================================================================
--- tests/static_assert.cpp	(revision 144534)
+++ tests/static_assert.cpp	(working copy)
@@ -13,8 +13,9 @@
 #include <vsip/support.hpp>
 #include <vsip/impl/static_assert.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
+using namespace vsip_csl;
 
 
 /***********************************************************************
Index: tests/conv-2d.cpp
===================================================================
--- tests/conv-2d.cpp	(revision 144534)
+++ tests/conv-2d.cpp	(working copy)
@@ -15,16 +15,16 @@
 #include <vsip/random.hpp>
 #include <vsip/initfin.hpp>
 
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 
 #define VERBOSE 1
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/corr-2d.cpp
===================================================================
--- tests/corr-2d.cpp	(revision 144534)
+++ tests/corr-2d.cpp	(working copy)
@@ -16,19 +16,20 @@
 #include <vsip/selgen.hpp>
 #include <vsip/initfin.hpp>
 
-#include "test.hpp"
-#include "ref_corr.hpp"
-#include "error_db.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/ref_corr.hpp>
+#include <vsip_csl/error_db.hpp>
 
 #define VERBOSE 0
 
 #if VERBOSE
 #  include <iostream>
-#  include "output.hpp"
+#  include <vsip_csl/output.hpp>
 #endif
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
 
Index: tests/view.cpp
===================================================================
--- tests/view.cpp	(revision 144534)
+++ tests/view.cpp	(working copy)
@@ -23,11 +23,12 @@
 #include <vsip/domain.hpp>
 #include <vsip/impl/length.hpp>
 #include <vsip/impl/domain-utils.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "test-storage.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::Length;
 
Index: tests/test-precision.hpp
===================================================================
--- tests/test-precision.hpp	(revision 144534)
+++ tests/test-precision.hpp	(working copy)
@@ -1,51 +0,0 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    tests/test-precision.cpp
-    @author  Jules Bergmann
-    @date    2005-09-12
-    @brief   VSIPL++ Library: Precision traits for tests.
-*/
-
-#ifndef VSIP_TESTS_TEST_PRECISION_HPP
-#define VSIP_TESTS_TEST_PRECISION_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <vsip/support.hpp>
-
-
-
-/***********************************************************************
-  Declarations
-***********************************************************************/
-
-template <typename T>
-struct Precision_traits
-{
-  typedef T type;
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-
-  static T eps;
-
-  // Determine the lowest bit of precision.
-
-  static void compute_eps()
-  {
-    eps = scalar_type(1);
-
-    // Without 'volatile', ICC avoid rounding and compute precision of
-    // long double for all types.
-    volatile scalar_type a = 1.0 + eps;
-    volatile scalar_type b = 1.0;
-
-    while (a - b != scalar_type())
-    {
-      eps = 0.5 * eps;
-      a = 1.0 + eps;
-    }
-  }
-};
-
-#endif // VSIP_TESTS_TEST_PRECISION_HPP
Index: tests/block_interface.hpp
===================================================================
--- tests/block_interface.hpp	(revision 144534)
+++ tests/block_interface.hpp	(working copy)
@@ -13,7 +13,7 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 namespace vsip
 {
Index: tests/ref_matvec.hpp
===================================================================
--- tests/ref_matvec.hpp	(revision 144534)
+++ tests/ref_matvec.hpp	(working copy)
@@ -1,201 +0,0 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    tests/ref_matvec.hpp
-    @author  Jules Bergmann
-    @date    2005-10-11
-    @brief   VSIPL++ Library: Reference implementations of matvec routines.
-*/
-
-#ifndef VSIP_REF_MATVEC_HPP
-#define VSIP_REF_MATVEC_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <cassert>
-
-#include <vsip/support.hpp>
-#include <vsip/vector.hpp>
-
-
-
-/***********************************************************************
-  Reference Definitions
-***********************************************************************/
-
-namespace ref
-{
-
-// Reference dot-product function.
-
-template <typename T0,
-	  typename T1,
-	  typename Block0,
-	  typename Block1>
-typename vsip::Promotion<T0, T1>::type
-dot(
-  vsip::const_Vector<T0, Block0> u,
-  vsip::const_Vector<T1, Block1> v)
-{
-  typedef typename vsip::Promotion<T0, T1>::type return_type;
-
-  assert(u.size() == v.size());
-
-  return_type sum = return_type();
-
-  for (vsip::index_type i=0; i<u.size(); ++i)
-    sum += u.get(i) * v.get(i);
-
-  return sum;
-}
-
-
-
-// Reference outer-product functions.
-
-template <typename T0,
-	  typename T1,
-	  typename Block0,
-	  typename Block1>
-vsip::Matrix<typename vsip::Promotion<T0, T1>::type>
-outer(
-  vsip::const_Vector<T0, Block0> u,
-  vsip::const_Vector<T1, Block1> v)
-{
-  typedef typename vsip::Promotion<T0, T1>::type return_type;
-
-  vsip::Matrix<return_type> r(u.size(), v.size());
-
-  for (vsip::index_type i=0; i<u.size(); ++i)
-    for (vsip::index_type j=0; j<v.size(); ++j)
-      // r(i, j) = u(i) * v(j);
-      r.put(i, j, u.get(i) * v.get(j));
-
-  return r;
-}
-
-template <typename T0,
-	  typename T1,
-	  typename Block0,
-	  typename Block1>
-vsip::Matrix<typename vsip::Promotion<std::complex<T0>, std::complex<T1> >::type>
-outer(
-  vsip::const_Vector<std::complex<T0>, Block0> u,
-  vsip::const_Vector<std::complex<T1>, Block1> v)
-{
-  typedef typename vsip::Promotion<std::complex<T0>, std::complex<T1> >::type return_type;
-
-  vsip::Matrix<return_type> r(u.size(), v.size());
-
-  for (vsip::index_type i=0; i<u.size(); ++i)
-    for (vsip::index_type j=0; j<v.size(); ++j)
-      // r(i, j) = u(i) * v(j);
-      r.put(i, j, u.get(i) * conj(v.get(j)));
-
-  return r;
-}
-
-
-// Reference vector-vector product
-
-template <typename T0,
-	  typename T1,
-	  typename Block0,
-	  typename Block1>
-vsip::Matrix<typename vsip::Promotion<T0, T1>::type>
-vv_prod(
-  vsip::const_Vector<T0, Block0> u,
-  vsip::const_Vector<T1, Block1> v)
-{
-  typedef typename vsip::Promotion<T0, T1>::type return_type;
-
-  vsip::Matrix<return_type> r(u.size(), v.size());
-
-  for (vsip::index_type i=0; i<u.size(); ++i)
-    for (vsip::index_type j=0; j<v.size(); ++j)
-      // r(i, j) = u(i) * v(j);
-      r.put(i, j, u.get(i) * v.get(j));
-
-  return r;
-}
-
-
-
-
-// Reference matrix-matrix product function (using vv-product).
-
-template <typename T0,
-	  typename T1,
-	  typename Block0,
-	  typename Block1>
-vsip::Matrix<typename vsip::Promotion<T0, T1>::type>
-prod(
-  vsip::const_Matrix<T0, Block0> a,
-  vsip::const_Matrix<T1, Block1> b)
-{
-  typedef typename vsip::Promotion<T0, T1>::type return_type;
-
-  assert(a.size(1) == b.size(0));
-
-  vsip::Matrix<return_type> r(a.size(0), b.size(1), return_type());
-
-  for (vsip::index_type k=0; k<a.size(1); ++k)
-    r += ref::vv_prod(a.col(k), b.row(k));
-
-  return r;
-}
-
-
-// Reference matrix-vector product function (using dot-product).
-
-template <typename T0,
-	  typename T1,
-	  typename Block0,
-	  typename Block1>
-vsip::Vector<typename vsip::Promotion<T0, T1>::type>
-prod(
-  vsip::const_Matrix<T0, Block0> a,
-  vsip::const_Vector<T1, Block1> b)
-{
-  typedef typename vsip::Promotion<T0, T1>::type return_type;
-
-  assert(a.size(1) == b.size(0));
-
-  vsip::Vector<return_type> r(a.size(0), return_type());
-
-  for (vsip::index_type k=0; k<a.size(0); ++k)
-    r.put( k, ref::dot(a.row(k), b) );
-
-  return r;
-}
-
-
-// Reference vector-matrix product function (using dot-product).
-
-template <typename T0,
-	  typename T1,
-	  typename Block0,
-	  typename Block1>
-vsip::Vector<typename vsip::Promotion<T0, T1>::type>
-prod(
-  vsip::const_Vector<T1, Block1> a,
-  vsip::const_Matrix<T0, Block0> b)
-{
-  typedef typename vsip::Promotion<T0, T1>::type return_type;
-
-  assert(a.size(0) == b.size(0));
-
-  vsip::Vector<return_type> r(b.size(1), return_type());
-
-  for (vsip::index_type k=0; k<b.size(1); ++k)
-    r.put( k, ref::dot(a, b.col(k)) );
-
-  return r;
-}
-
-
-
-} // namespace ref
-
-#endif // VSIP_REF_MATVEC_HPP
Index: tests/fir.cpp
===================================================================
--- tests/fir.cpp	(revision 144534)
+++ tests/fir.cpp	(working copy)
@@ -20,10 +20,12 @@
 #include <vsip/math.hpp>
 #include <vsip/matrix.hpp>
 
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 
+using namespace vsip_csl;
 
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/random.cpp
===================================================================
--- tests/random.cpp	(revision 144534)
+++ tests/random.cpp	(working copy)
@@ -15,8 +15,8 @@
 #include <vsip/initfin.hpp>
 #include <vsip/random.hpp>
 #include <vsip/support.hpp>
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 
 /***********************************************************************
   Function Definitions
@@ -351,6 +351,7 @@
 main ()
 {
   using namespace vsip;
+  using namespace vsip_csl;
   vsipl init;
 
   // Random generation tests -- Compare against C VSIPL generator.
Index: tests/correlation.cpp
===================================================================
--- tests/correlation.cpp	(revision 144534)
+++ tests/correlation.cpp	(working copy)
@@ -16,19 +16,20 @@
 #include <vsip/random.hpp>
 #include <vsip/selgen.hpp>
 
-#include "test.hpp"
-#include "ref_corr.hpp"
-#include "error_db.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/ref_corr.hpp>
+#include <vsip_csl/error_db.hpp>
 
 #define VERBOSE 0
 
 #if VERBOSE
 #  include <iostream>
-#  include "output.hpp"
+#  include <vsip_csl/output.hpp>
 #endif
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
 
Index: tests/index_traversal.cpp
===================================================================
--- tests/index_traversal.cpp	(revision 144534)
+++ tests/index_traversal.cpp	(working copy)
@@ -14,10 +14,11 @@
 #include <vsip/impl/domain-utils.hpp>
 #include <vsip/impl/static_assert.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::Length;
 using vsip::impl::extent;
Index: tests/extdata.cpp
===================================================================
--- tests/extdata.cpp	(revision 144534)
+++ tests/extdata.cpp	(working copy)
@@ -16,14 +16,14 @@
 #include <vsip/dense.hpp>
 #include <vsip/vector.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "plainblock.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/fftm.cpp
===================================================================
--- tests/fftm.cpp	(revision 144534)
+++ tests/fftm.cpp	(working copy)
@@ -20,10 +20,10 @@
 #include <vsip/math.hpp>
 #include <vsip/matrix.hpp>
 
-#include "test.hpp"
-#include "output.hpp"
-#include "error_db.hpp"
-#include "ref_dft.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
+#include <vsip_csl/error_db.hpp>
+#include <vsip_csl/ref_dft.hpp>
 
 #if VSIP_IMPL_SAL_FFT
 #  define TEST_NON_REALCOMPLEX 0
@@ -41,6 +41,7 @@
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
 
Index: tests/coverage_binary.cpp
===================================================================
--- tests/coverage_binary.cpp	(revision 144534)
+++ tests/coverage_binary.cpp	(working copy)
@@ -18,15 +18,15 @@
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "test-storage.hpp"
 #include "coverage_common.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/vmmul.cpp
===================================================================
--- tests/vmmul.cpp	(revision 144534)
+++ tests/vmmul.cpp	(working copy)
@@ -22,16 +22,16 @@
 #include <vsip/domain.hpp>
 #include <vsip/impl/domain-utils.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "util-par.hpp"
 #include "solver-common.hpp"
 
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Serial tests
 ***********************************************************************/
Index: tests/util-par.hpp
===================================================================
--- tests/util-par.hpp	(revision 144534)
+++ tests/util-par.hpp	(working copy)
@@ -22,7 +22,7 @@
 #include <vsip/parallel.hpp>
 #include <vsip/domain.hpp>
 
-#include "output.hpp"
+#include <vsip_csl/output.hpp>
 #include "extdata-output.hpp"
 
 
Index: tests/matvec-dot.cpp
===================================================================
--- tests/matvec-dot.cpp	(revision 144534)
+++ tests/matvec-dot.cpp	(working copy)
@@ -18,24 +18,24 @@
 #include <vsip/tensor.hpp>
 #include <vsip/math.hpp>
 
-#include "ref_matvec.hpp"
+#include <vsip_csl/ref_matvec.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "test-random.hpp"
-#include "test-precision.hpp"
+#include <vsip_csl/test-precision.hpp>
 
 #define VERBOSE 0
 
 #if VERBOSE
 #  include <iostream>
-#  include "output.hpp"
+#  include <vsip_csl/output.hpp>
 #endif
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/solver-svd.cpp
===================================================================
--- tests/solver-svd.cpp	(revision 144534)
+++ tests/solver-svd.cpp	(working copy)
@@ -17,8 +17,8 @@
 #include <vsip/tensor.hpp>
 #include <vsip/solvers.hpp>
 
-#include "test.hpp"
-#include "test-precision.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-precision.hpp>
 #include "test-random.hpp"
 #include "solver-common.hpp"
 
@@ -33,15 +33,15 @@
 
 #if VERBOSE
 #  include <iostream>
-#  include "output.hpp"
+#  include <vsip/csl/output.hpp>
 #  include "extdata-output.hpp"
 #endif
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Support
 ***********************************************************************/
@@ -86,8 +86,58 @@
   return norm_1(m.transpose());
 }
 
+template <typename T,
+	  typename Block1,
+	  typename Block2>
+void
+compare_view(
+  vsip::const_Vector<T, Block1>           a,
+  vsip::const_Vector<T, Block2>           b,
+  typename vsip::impl::Scalar_of<T>::type thresh
+  )
+{
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
 
+  vsip::Index<1> idx;
+  scalar_type err = vsip::maxval(
+    (mag(a - b) / vsip_csl::Precision_traits<scalar_type>::eps), idx);
 
+  if (err > thresh)
+  {
+    for (vsip::index_type r=0; r<a.size(0); ++r)
+	test_assert(equal(a.get(r), b.get(r)));
+  }
+}
+
+
+
+template <typename T,
+	  typename Block1,
+	  typename Block2>
+void
+compare_view(
+  vsip::const_Matrix<T, Block1>           a,
+  vsip::const_Matrix<T, Block2>           b,
+  typename vsip::impl::Scalar_of<T>::type thresh
+  )
+{
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+
+  vsip::Index<2> idx;
+  scalar_type err = vsip::maxval(
+    (mag(a - b) / vsip_csl::Precision_traits<scalar_type>::eps), idx);
+
+  if (err > thresh)
+  {
+    std::cout << "a = \n" << a;
+    std::cout << "b = \n" << b;
+    for (vsip::index_type r=0; r<a.size(0); ++r)
+      for (vsip::index_type c=0; c<a.size(1); ++c)
+	test_assert(equal(a.get(r, c), b.get(r, c)));
+  }
+}
+
+
 /***********************************************************************
   svd function tests
 ***********************************************************************/
Index: tests/output.hpp
===================================================================
--- tests/output.hpp	(revision 144534)
+++ tests/output.hpp	(working copy)
@@ -1,163 +0,0 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    tests/output.hpp
-    @author  Jules Bergmann
-    @date    03/22/2005
-    @brief   VSIPL++ Library: Output utilities.
-*/
-
-#ifndef VSIP_TESTS_OUTPUT_HPP
-#define VSIP_TESTS_OUTPUT_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <iostream>
-#include <vsip/domain.hpp>
-#include <vsip/vector.hpp>
-#include <vsip/matrix.hpp>
-#include <vsip/domain.hpp>
-
-
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-/// Write a Domain<1> object to an output stream.
-
-namespace vsip
-{
-
-inline
-std::ostream&
-operator<<(
-  std::ostream&		 out,
-  vsip::Domain<1> const& dom)
-  VSIP_NOTHROW
-{
-  out << "("
-      << dom.first() << ","
-      << dom.stride() << ","
-      << dom.length() << ")";
-  return out;
-}
-
-
-
-/// Write a Domain<2> object to an output stream.
-
-inline
-std::ostream&
-operator<<(
-  std::ostream&		 out,
-  vsip::Domain<2> const& dom)
-  VSIP_NOTHROW
-{
-  out << "(" << dom[0] << ", " << dom[1] << ")";
-  return out;
-}
-
-
-
-/// Write a Domain<3> object to an output stream.
-
-inline
-std::ostream&
-operator<<(
-  std::ostream&		 out,
-  vsip::Domain<3> const& dom)
-  VSIP_NOTHROW
-{
-  out << "(" << dom[0] << ", " << dom[1] << ", " << dom[2] << ")";
-  return out;
-}
-
-
-
-/// Write a vector to a stream.
-
-template <typename T,
-	  typename Block>
-inline
-std::ostream&
-operator<<(
-  std::ostream&		       out,
-  vsip::const_Vector<T, Block> vec)
-  VSIP_NOTHROW
-{
-  for (vsip::index_type i=0; i<vec.size(); ++i)
-    out << "  " << i << ": " << vec.get(i) << "\n";
-  return out;
-}
-
-
-
-/// Write a matrix to a stream.
-
-template <typename T,
-	  typename Block>
-inline
-std::ostream&
-operator<<(
-  std::ostream&		       out,
-  vsip::const_Matrix<T, Block> v)
-  VSIP_NOTHROW
-{
-  for (vsip::index_type r=0; r<v.size(0); ++r)
-  {
-    out << "  " << r << ":";
-    for (vsip::index_type c=0; c<v.size(1); ++c)
-      out << "  " << v.get(r, c);
-    out << std::endl;
-  }
-  return out;
-}
-
-
-/// Write an Index to a stream.
-
-template <vsip::dimension_type Dim>
-inline
-std::ostream&
-operator<<(
-  std::ostream&		        out,
-  vsip::Index<Dim> const& idx)
-  VSIP_NOTHROW
-{
-  out << "(";
-  for (vsip::dimension_type d=0; d<Dim; ++d)
-  {
-    if (d > 0) out << ", ";
-    out << idx[d];
-  }
-  out << ")";
-  return out;
-}
-
-
-
-/// Write an Length to a stream.
-
-template <vsip::dimension_type Dim>
-inline
-std::ostream&
-operator<<(
-  std::ostream&		         out,
-  vsip::impl::Length<Dim> const& idx)
-  VSIP_NOTHROW
-{
-  out << "(";
-  for (vsip::dimension_type d=0; d<Dim; ++d)
-  {
-    if (d > 0) out << ", ";
-    out << idx[d];
-  }
-  out << ")";
-  return out;
-}
-
-} // namespace vsip
-
-#endif // VSIP_OUTPUT_HPP
Index: tests/ref_corr.hpp
===================================================================
--- tests/ref_corr.hpp	(revision 144534)
+++ tests/ref_corr.hpp	(working copy)
@@ -1,226 +0,0 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    ref_corr.cpp
-    @author  Jules Bergmann
-    @date    2005-12-09
-    @brief   VSIPL++ Library: Reference implementation of correlation
-*/
-
-#ifndef VSIP_REF_CORR_HPP
-#define VSIP_REF_CORR_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <vsip/vector.hpp>
-#include <vsip/signal.hpp>
-#include <vsip/random.hpp>
-#include <vsip/selgen.hpp>
-
-namespace ref
-{
-
-vsip::length_type
-corr_output_size(
-  vsip::support_region_type supp,
-  vsip::length_type         M,    // kernel length
-  vsip::length_type         N)    // input  length
-{
-  if      (supp == vsip::support_full)
-    return (N + M - 1);
-  else if (supp == vsip::support_same)
-    return N;
-  else //(supp == vsip::support_min)
-    return (N - M + 1);
-}
-
-
-
-vsip::stride_type
-expected_shift(
-  vsip::support_region_type supp,
-  vsip::length_type         M)     // kernel length
-{
-  if      (supp == vsip::support_full)
-    return -(M-1);
-  else if (supp == vsip::support_same)
-    return -(M/2);
-  else //(supp == vsip::support_min)
-    return 0;
-}
-
-
-
-template <typename T,
-	  typename Block1,
-	  typename Block2,
-	  typename Block3>
-void
-corr(
-  vsip::bias_type               bias,
-  vsip::support_region_type     sup,
-  vsip::const_Vector<T, Block1> ref,
-  vsip::const_Vector<T, Block2> in,
-  vsip::Vector<T, Block3>       out)
-{
-  using vsip::index_type;
-  using vsip::length_type;
-  using vsip::stride_type;
-  using vsip::Vector;
-  using vsip::Domain;
-  using vsip::unbiased;
-
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-
-  length_type M = ref.size(0);
-  length_type N = in.size(0);
-  length_type P = out.size(0);
-
-  length_type expected_P = corr_output_size(sup, M, N);
-  stride_type shift      = expected_shift(sup, M);
-
-  assert(expected_P == P);
-
-  Vector<T> sub(M);
-
-  // compute correlation
-  for (index_type i=0; i<P; ++i)
-  {
-    sub = T();
-    stride_type pos = static_cast<stride_type>(i) + shift;
-    scalar_type scale;
-
-    if (pos < 0)
-    {
-      sub(Domain<1>(-pos, 1, M + pos)) = in(Domain<1>(0, 1, M+pos));
-      scale = scalar_type(M + pos);
-    }
-    else if (pos + M > N)
-    {
-      sub(Domain<1>(0, 1, N-pos)) = in(Domain<1>(pos, 1, N-pos));
-      scale = scalar_type(N - pos);
-    }
-    else
-    {
-      sub = in(Domain<1>(pos, 1, M));
-      scale = scalar_type(M);
-    }
-      
-    T val = dot(ref, impl_conj(sub));
-    if (bias == vsip::unbiased)
-      val /= scale;
-
-    out(i) = val;
-  }
-}
-
-
-
-template <typename T,
-	  typename Block1,
-	  typename Block2,
-	  typename Block3>
-void
-corr(
-  vsip::bias_type               bias,
-  vsip::support_region_type     sup,
-  vsip::const_Matrix<T, Block1> ref,
-  vsip::const_Matrix<T, Block2> in,
-  vsip::Matrix<T, Block3>       out)
-{
-  using vsip::index_type;
-  using vsip::length_type;
-  using vsip::stride_type;
-  using vsip::Matrix;
-  using vsip::Domain;
-  using vsip::unbiased;
-
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-
-  length_type Mr = ref.size(0);
-  length_type Mc = ref.size(1);
-  length_type Nr = in.size(0);
-  length_type Nc = in.size(1);
-  length_type Pr = out.size(0);
-  length_type Pc = out.size(1);
-
-  length_type expected_Pr = corr_output_size(sup, Mr, Nr);
-  length_type expected_Pc = corr_output_size(sup, Mc, Nc);
-  stride_type shift_r     = expected_shift(sup, Mr);
-  stride_type shift_c     = expected_shift(sup, Mc);
-
-  assert(expected_Pr == Pr);
-  assert(expected_Pc == Pc);
-
-  Matrix<T> sub(Mr, Mc);
-  Domain<1> sub_dom_r;
-  Domain<1> sub_dom_c;
-  Domain<1> in_dom_r;
-  Domain<1> in_dom_c;
-
-  // compute correlation
-  for (index_type r=0; r<Pr; ++r)
-  {
-    stride_type pos_r = static_cast<stride_type>(r) + shift_r;
-
-    for (index_type c=0; c<Pc; ++c)
-    {
-
-      stride_type pos_c = static_cast<stride_type>(c) + shift_c;
-
-      scalar_type scale = scalar_type(1);
-
-      if (pos_r < 0)
-      {
-	sub_dom_r = Domain<1>(-pos_r, 1, Mr + pos_r); 
-	in_dom_r  = Domain<1>(0, 1, Mr+pos_r);
-	scale *= scalar_type(Mr + pos_r);
-      }
-      else if (pos_r + Mr > Nr)
-      {
-	sub_dom_r = Domain<1>(0, 1, Nr-pos_r);
-	in_dom_r  = Domain<1>(pos_r, 1, Nr-pos_r);
-	scale *= scalar_type(Nr - pos_r);
-      }
-      else
-      {
-	sub_dom_r = Domain<1>(0, 1, Mr);
-	in_dom_r  = Domain<1>(pos_r, 1, Mr);
-	scale *= scalar_type(Mr);
-      }
-
-      if (pos_c < 0)
-      {
-	sub_dom_c = Domain<1>(-pos_c, 1, Mc + pos_c); 
-	in_dom_c  = Domain<1>(0, 1, Mc+pos_c);
-	scale *= scalar_type(Mc + pos_c);
-      }
-      else if (pos_c + Mc > Nc)
-      {
-	sub_dom_c = Domain<1>(0, 1, Nc-pos_c);
-	in_dom_c  = Domain<1>(pos_c, 1, Nc-pos_c);
-	scale *= scalar_type(Nc - pos_c);
-      }
-      else
-      {
-	sub_dom_c = Domain<1>(0, 1, Mc);
-	in_dom_c  = Domain<1>(pos_c, 1, Mc);
-	scale *= scalar_type(Mc);
-      }
-
-      sub = T();
-      sub(Domain<2>(sub_dom_r, sub_dom_c)) = in(Domain<2>(in_dom_r, in_dom_c));
-      
-      T val = sumval(ref * impl_conj(sub));
-      if (bias == unbiased)
-	val /= scale;
-      
-      out(r, c) = val;
-    }
-  }
-}
-
-} // namespace ref
-
-#endif // VSIP_REF_CORR_HPP
Index: tests/ref_conv.hpp
===================================================================
--- tests/ref_conv.hpp	(revision 144534)
+++ tests/ref_conv.hpp	(working copy)
@@ -1,172 +0,0 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    ref_conv.cpp
-    @author  Jules Bergmann
-    @date    2005-12-28
-    @brief   VSIPL++ Library: Reference implementation of convolution
-*/
-
-#ifndef VSIP_REF_CORR_HPP
-#define VSIP_REF_CORR_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <vsip/vector.hpp>
-#include <vsip/signal.hpp>
-#include <vsip/random.hpp>
-#include <vsip/selgen.hpp>
-#include <vsip/parallel.hpp>
-
-namespace ref
-{
-
-vsip::length_type
-conv_output_size(
-  vsip::support_region_type supp,
-  vsip::length_type         M,    // kernel length
-  vsip::length_type         N,    // input  length
-  vsip::length_type         D)    // decimation factor
-{
-  if      (supp == vsip::support_full)
-    return ((N + M - 2)/D) + 1;
-  else if (supp == vsip::support_same)
-    return ((N - 1)/D) + 1;
-  else //(supp == vsip::support_min)
-  {
-#if VSIP_IMPL_CONV_CORRECT_MIN_SUPPORT_SIZE
-    return ((N - M + 1) / D) + ((N - M + 1) % D == 0 ? 0 : 1);
-#else
-    return ((N - 1)/D) - ((M-1)/D) + 1;
-#endif
-  }
-}
-
-
-
-vsip::stride_type
-conv_expected_shift(
-  vsip::support_region_type supp,
-  vsip::length_type         M)     // kernel length
-{
-  if      (supp == vsip::support_full)
-    return 0;
-  else if (supp == vsip::support_same)
-    return (M/2);
-  else //(supp == vsip::support_min)
-    return (M-1);
-}
-
-
-
-/// Generate full convolution kernel from coefficients.
-
-template <typename T,
-	  typename Block>
-vsip::Vector<T>
-kernel_from_coeff(
-  vsip::symmetry_type          symmetry,
-  vsip::const_Vector<T, Block> coeff)
-{
-  using vsip::Domain;
-  using vsip::length_type;
-
-  length_type M2 = coeff.size();
-  length_type M;
-
-  if (symmetry == vsip::nonsym)
-    M = coeff.size();
-  else if (symmetry == vsip::sym_even_len_odd)
-    M = 2*coeff.size()-1;
-  else /* (symmetry == vsip::sym_even_len_even) */
-    M = 2*coeff.size();
-
-  vsip::Vector<T> kernel(M, T());
-
-  if (symmetry == vsip::nonsym)
-  {
-    kernel = coeff;
-  }
-  else if (symmetry == vsip::sym_even_len_odd)
-  {
-    kernel(Domain<1>(0,  1, M2))   = coeff;
-    kernel(Domain<1>(M2, 1, M2-1)) = coeff(Domain<1>(M2-2, -1, M2-1));
-  }
-  else /* (symmetry == sym_even_len_even) */
-  {
-    kernel(Domain<1>(0,  1, M2)) = coeff;
-    kernel(Domain<1>(M2, 1, M2)) = coeff(Domain<1>(M2-1, -1, M2));
-  }
-
-  return kernel;
-}
-
-
-
-template <typename T,
-	  typename Block1,
-	  typename Block2,
-	  typename Block3>
-void
-conv(
-  vsip::symmetry_type           sym,
-  vsip::support_region_type     sup,
-  vsip::const_Vector<T, Block1> coeff,
-  vsip::const_Vector<T, Block2> in,
-  vsip::Vector<T, Block3>       out,
-  vsip::length_type             D)
-{
-  using vsip::index_type;
-  using vsip::length_type;
-  using vsip::stride_type;
-  using vsip::Vector;
-  using vsip::const_Vector;
-  using vsip::Domain;
-  using vsip::unbiased;
-
-  using vsip::impl::convert_to_local;
-  using vsip::impl::Working_view_holder;
-
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
-
-  Working_view_holder<const_Vector<T, Block1> > w_coeff(coeff);
-  Working_view_holder<const_Vector<T, Block2> > w_in(in);
-  Working_view_holder<Vector<T, Block3> >       w_out(out);
-
-  Vector<T> kernel = kernel_from_coeff(sym, w_coeff.view);
-
-  length_type M = kernel.size(0);
-  length_type N = in.size(0);
-  length_type P = out.size(0);
-
-  length_type expected_P = conv_output_size(sup, M, N, D);
-  stride_type shift      = conv_expected_shift(sup, M);
-
-  assert(expected_P == P);
-
-  Vector<T> sub(M);
-
-  // Check result
-  for (index_type i=0; i<P; ++i)
-  {
-    sub = T();
-    index_type pos = i*D + shift;
-
-    if (pos+1 < M)
-      sub(Domain<1>(0, 1, pos+1)) = w_in.view(Domain<1>(pos, -1, pos+1));
-    else if (pos >= N)
-    {
-      index_type start = pos - N + 1;
-      sub(Domain<1>(start, 1, M-start)) = w_in.view(Domain<1>(N-1, -1, M-start));
-    }
-    else
-      sub = w_in.view(Domain<1>(pos, -1, M));
-      
-    w_out.view(i) = dot(kernel, sub);
-  }
-}
-
-} // namespace ref
-
-#endif // VSIP_REF_CORR_HPP
Index: tests/index.cpp
===================================================================
--- tests/index.cpp	(revision 144534)
+++ tests/index.cpp	(working copy)
@@ -17,11 +17,13 @@
 #include <cassert>
 #include <vsip/domain.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/extdata-fft.cpp
===================================================================
--- tests/extdata-fft.cpp	(revision 144534)
+++ tests/extdata-fft.cpp	(working copy)
@@ -20,15 +20,15 @@
 #include <vsip/vector.hpp>
 #include <vsip/impl/fast-block.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "plainblock.hpp"
 #include "extdata-output.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Declarations
 ***********************************************************************/
Index: tests/coverage_unary.cpp
===================================================================
--- tests/coverage_unary.cpp	(revision 144534)
+++ tests/coverage_unary.cpp	(working copy)
@@ -18,15 +18,15 @@
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "test-storage.hpp"
 #include "coverage_common.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/selgen-ramp.cpp
===================================================================
--- tests/selgen-ramp.cpp	(revision 144534)
+++ tests/selgen-ramp.cpp	(working copy)
@@ -18,13 +18,13 @@
 #include <vsip/vector.hpp>
 #include <vsip/selgen.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/tensor.cpp
===================================================================
--- tests/tensor.cpp	(revision 144534)
+++ tests/tensor.cpp	(working copy)
@@ -18,10 +18,11 @@
 #include <cassert>
 #include <vsip/support.hpp>
 #include <vsip/tensor.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
 template <typename T,
Index: tests/parallel/corner-turn.cpp
===================================================================
--- tests/parallel/corner-turn.cpp	(revision 144534)
+++ tests/parallel/corner-turn.cpp	(working copy)
@@ -19,16 +19,16 @@
 #include <vsip/tensor.hpp>
 #include <vsip/parallel.hpp>
 
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 #include "util.hpp"
 #include "util-par.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/parallel/expr.cpp
===================================================================
--- tests/parallel/expr.cpp	(revision 144534)
+++ tests/parallel/expr.cpp	(working copy)
@@ -21,13 +21,14 @@
 #include <vsip/impl/length.hpp>
 #include <vsip/impl/domain-utils.hpp>
 
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 #include "util.hpp"
 #include "util-par.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::Length;
 using vsip::impl::valid;
Index: tests/parallel/user-storage.cpp
===================================================================
--- tests/parallel/user-storage.cpp	(revision 144534)
+++ tests/parallel/user-storage.cpp	(working copy)
@@ -18,11 +18,12 @@
 #include <vsip/map.hpp>
 #include <vsip/parallel.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "util.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::View_of_dim;
 
Index: tests/parallel/replicated_data.cpp
===================================================================
--- tests/parallel/replicated_data.cpp	(revision 144534)
+++ tests/parallel/replicated_data.cpp	(working copy)
@@ -21,14 +21,14 @@
 #include <vsip/map.hpp>
 #include <vsip/initfin.hpp>
 
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/parallel/subviews.cpp
===================================================================
--- tests/parallel/subviews.cpp	(revision 144534)
+++ tests/parallel/subviews.cpp	(working copy)
@@ -21,14 +21,15 @@
 
 #include <vsip/impl/profile.hpp>
 
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 #include "util.hpp"
 #include "util-par.hpp"
 #include "extdata-output.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::View_of_dim;
 
Index: tests/parallel/getput.cpp
===================================================================
--- tests/parallel/getput.cpp	(revision 144534)
+++ tests/parallel/getput.cpp	(working copy)
@@ -16,16 +16,16 @@
 #include <vsip/tensor.hpp>
 #include <vsip/parallel.hpp>
 
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 #include "util.hpp"
 #include "util-par.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/parallel/block.cpp
===================================================================
--- tests/parallel/block.cpp	(revision 144534)
+++ tests/parallel/block.cpp	(working copy)
@@ -26,13 +26,14 @@
 #include <vsip/impl/par-assign.hpp>
 #endif
 
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 #include "util.hpp"
 #include "util-par.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::Length;
 using vsip::impl::extent;
Index: tests/parallel/fftm.cpp
===================================================================
--- tests/parallel/fftm.cpp	(revision 144534)
+++ tests/parallel/fftm.cpp	(working copy)
@@ -22,12 +22,12 @@
 #include <vsip/matrix.hpp>
 #include <vsip/map.hpp>
 
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 #include "util.hpp"
 #include "util-par.hpp"
-#include "error_db.hpp"
-#include "ref_dft.hpp"
+#include <vsip_csl/error_db.hpp>
+#include <vsip_csl/ref_dft.hpp>
 
 #define VERBOSE 0
 
@@ -47,6 +47,7 @@
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
 int number_of_processors;
Index: tests/extdata-runtime.cpp
===================================================================
--- tests/extdata-runtime.cpp	(revision 144534)
+++ tests/extdata-runtime.cpp	(working copy)
@@ -20,12 +20,13 @@
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "plainblock.hpp"
 #include "extdata-output.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::ITE_Type;
 using vsip::impl::Type_equal;
Index: tests/support.cpp
===================================================================
--- tests/support.cpp	(revision 144534)
+++ tests/support.cpp	(working copy)
@@ -16,13 +16,13 @@
 #include <iostream>
 #include <vsip/support.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/solver-covsol.cpp
===================================================================
--- tests/solver-covsol.cpp	(revision 144534)
+++ tests/solver-covsol.cpp	(working copy)
@@ -17,8 +17,8 @@
 #include <vsip/tensor.hpp>
 #include <vsip/solvers.hpp>
 
-#include "test.hpp"
-#include "test-precision.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-precision.hpp>
 #include "test-random.hpp"
 #include "solver-common.hpp"
 
@@ -27,16 +27,16 @@
 
 #if VERBOSE
 #  include <iostream>
-#  include "output.hpp"
+#  include <vsip/csl/output.hpp>
 #  include "extdata-output.hpp"
 #endif
 
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   covsol function tests
 ***********************************************************************/
Index: tests/load_view.hpp
===================================================================
--- tests/load_view.hpp	(revision 144534)
+++ tests/load_view.hpp	(working copy)
@@ -1,113 +0,0 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    tests/load_view.hpp
-    @author  Jules Bergmann
-    @date    2005-09-30
-    @brief   VSIPL++ Library: Utility to load a view from disk.
-*/
-
-#ifndef VSIP_TEST_LOAD_VIEW_HPP
-#define VSIP_TEST_LOAD_VIEW_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <vsip/vector.hpp>
-#include <vsip/matrix.hpp>
-#include <vsip/tensor.hpp>
-
-
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-// This is nearly same as sarsim LoadView, but doesn't include byte
-// ordering.  Move this into common location.
-
-template <typename T>
-struct Load_view_traits
-{
-  typedef T base_t;
-  static unsigned const factor = 1;
-};
-
-template <typename T>
-struct Load_view_traits<vsip::complex<T> >
-{
-  typedef T base_t;
-  static unsigned const factor = 2;
-};
-
-
-template <vsip::dimension_type Dim,
-	  typename             T>
-class Load_view
-{
-public:
-  typedef typename Load_view_traits<T>::base_t base_t;
-  static unsigned const factor = Load_view_traits<T>::factor;
-
-  typedef vsip::Dense<Dim, T> block_t;
-  typedef typename vsip::impl::View_of_dim<Dim, T, block_t>::type view_t;
-
-public:
-  Load_view(char*                    filename,
-	    vsip::Domain<Dim> const& dom)
-    : data_  (new base_t[factor*dom.size()]),
-      block_ (dom, data_),
-      view_  (block_)
-  {
-    FILE*  fd;
-    size_t size = dom.size();
-    
-    if (!(fd = fopen(filename,"r")))
-    {
-      fprintf(stderr,"Load_view: error opening '%s'.\n", filename);
-      exit(1);
-    }
-
-    if (size != fread(data_, sizeof(T), size, fd))
-    {
-      fprintf(stderr, "Load_view: error reading file %s.\n", filename);
-      exit(1);
-    }
-  
-    fclose(fd);
-    
-    block_.admit(true);
-  }
-
-
-
-  Load_view(FILE*              fd,
-	    vsip::Domain<Dim> const& dom)
-    : data_  (new base_t[factor*dom.size()]),
-      block_ (dom, data_),
-      view_  (block_)
-  {
-    size_t size = dom.size();
-
-    if (size != fread(data_, sizeof(T), size, fd))
-    {
-      fprintf(stderr, "Load_view: error reading file.\n");
-      exit(1);
-    }
-    
-    block_.admit(true);
-  }
-
-  ~Load_view()
-  { delete[] data_; }
-
-  view_t view() { return view_; }
-
-private:
-  base_t*       data_;
-
-  block_t       block_;
-  view_t        view_;
-};
-
-#endif // VSIP_TEST_LOAD_VIEW_HPP
Index: tests/appmap.cpp
===================================================================
--- tests/appmap.cpp	(revision 144534)
+++ tests/appmap.cpp	(working copy)
@@ -15,11 +15,12 @@
 #include <vsip/matrix.hpp>
 #include <vsip/impl/length.hpp>
 #include <vsip/impl/domain-utils.hpp>
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::Length;
 using vsip::impl::extent;
Index: tests/tensor_subview.cpp
===================================================================
--- tests/tensor_subview.cpp	(revision 144534)
+++ tests/tensor_subview.cpp	(working copy)
@@ -15,12 +15,12 @@
 #include <vsip/support.hpp>
 #include <vsip/tensor.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/reductions.cpp
===================================================================
--- tests/reductions.cpp	(revision 144534)
+++ tests/reductions.cpp	(working copy)
@@ -17,13 +17,13 @@
 #include <vsip/map.hpp>
 #include <vsip/parallel.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "test-storage.hpp"
 
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 void
 simple_tests()
 {
Index: tests/fft.cpp
===================================================================
--- tests/fft.cpp	(revision 144534)
+++ tests/fft.cpp	(working copy)
@@ -21,10 +21,10 @@
 
 #include <vsip/impl/metaprogramming.hpp>
 
-#include "test.hpp"
-#include "output.hpp"
-#include "error_db.hpp"
-#include "ref_dft.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
+#include <vsip_csl/error_db.hpp>
+#include <vsip_csl/ref_dft.hpp>
 
 
 
@@ -54,6 +54,7 @@
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
 
Index: tests/counter.cpp
===================================================================
--- tests/counter.cpp	(revision 144534)
+++ tests/counter.cpp	(working copy)
@@ -12,8 +12,9 @@
 #include <limits>
 #include <vsip/impl/counter.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
+using namespace vsip_csl;
 using vsip::impl::Checked_counter;
 
 /// Exercise all relational operators on Checked_counters.
Index: tests/convolution.cpp
===================================================================
--- tests/convolution.cpp	(revision 144534)
+++ tests/convolution.cpp	(working copy)
@@ -18,17 +18,18 @@
 #include <vsip/random.hpp>
 #include <vsip/parallel.hpp>
 
-#include "test.hpp"
-#include "ref_conv.hpp"
-#include "error_db.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/ref_conv.hpp>
+#include <vsip_csl/error_db.hpp>
 
 #if VERBOSE
 #  include <iostream>
-#  include "output.hpp"
+#  include <vsip_csl/output.hpp>
 #endif
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
 
Index: tests/us-block.cpp
===================================================================
--- tests/us-block.cpp	(revision 144534)
+++ tests/us-block.cpp	(working copy)
@@ -17,10 +17,11 @@
 #include <vsip/impl/length.hpp>
 #include <vsip/impl/domain-utils.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::Length;
 using vsip::impl::extent;
Index: tests/matvec-prod.cpp
===================================================================
--- tests/matvec-prod.cpp	(revision 144534)
+++ tests/matvec-prod.cpp	(working copy)
@@ -18,19 +18,18 @@
 #include <vsip/tensor.hpp>
 #include <vsip/math.hpp>
 
-#include "ref_matvec.hpp"
+#include <vsip_csl/output.hpp>
+#include <vsip_csl/ref_matvec.hpp>
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-precision.hpp>
 
-#include "test.hpp"
 #include "test-random.hpp"
-#include "test-precision.hpp"
 
-#include "output.hpp"
-
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Reference Definitions
 ***********************************************************************/
Index: tests/elementwise.cpp
===================================================================
--- tests/elementwise.cpp	(revision 144534)
+++ tests/elementwise.cpp	(working copy)
@@ -23,13 +23,13 @@
 #include <vsip/math.hpp>
 #include <vsip/impl/fast-block.hpp>
 #include <vsip/impl/subblock.hpp>
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
-
   
 
 template <typename T>
Index: tests/extdata-local.cpp
===================================================================
--- tests/extdata-local.cpp	(revision 144534)
+++ tests/extdata-local.cpp	(working copy)
@@ -16,13 +16,14 @@
 #include <vsip/map.hpp>
 #include <vsip/selgen.hpp>
 
-#include "test.hpp"
-#include "output.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/output.hpp>
 
 #define VERBOSE 1
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::Layout;
 using vsip::impl::Stride_unit_dense;
Index: tests/coverage_comparison.cpp
===================================================================
--- tests/coverage_comparison.cpp	(revision 144534)
+++ tests/coverage_comparison.cpp	(working copy)
@@ -17,15 +17,15 @@
 #include <vsip/vector.hpp>
 #include <vsip/math.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "test-storage.hpp"
 #include "coverage_common.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: tests/fast-block.cpp
===================================================================
--- tests/fast-block.cpp	(revision 144534)
+++ tests/fast-block.cpp	(working copy)
@@ -16,10 +16,11 @@
 #include <vsip/impl/fast-block.hpp>
 #include <vsip/impl/length.hpp>
 #include <vsip/impl/domain-utils.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 using vsip::impl::Length;
 using vsip::impl::extent;
Index: tests/solver-lu.cpp
===================================================================
--- tests/solver-lu.cpp	(revision 144534)
+++ tests/solver-lu.cpp	(working copy)
@@ -19,11 +19,12 @@
 #include <vsip/map.hpp>
 #include <vsip/parallel.hpp>
 
-#include "test.hpp"
-#include "test-precision.hpp"
+#include <vsip_csl/load_view.hpp>
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-precision.hpp>
+
 #include "test-random.hpp"
 #include "solver-common.hpp"
-#include "load_view.hpp"
 
 #define VERBOSE       0
 #define DO_SWEEP      0
@@ -32,15 +33,15 @@
 
 #if VERBOSE
 #  include <iostream>
-#  include "output.hpp"
+#  include <vsip/csl/output.hpp>
 #  include "extdata-output.hpp"
 #endif
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Support Definitions
 ***********************************************************************/
Index: tests/solver-cholesky.cpp
===================================================================
--- tests/solver-cholesky.cpp	(revision 144534)
+++ tests/solver-cholesky.cpp	(working copy)
@@ -17,8 +17,8 @@
 #include <vsip/tensor.hpp>
 #include <vsip/solvers.hpp>
 
-#include "test.hpp"
-#include "test-precision.hpp"
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-precision.hpp>
 #include "test-random.hpp"
 #include "solver-common.hpp"
 
@@ -29,15 +29,15 @@
 
 #if VERBOSE
 #  include <iostream>
-#  include "output.hpp"
+#  include <vsip/csl/output.hpp>
 #  include "extdata-output.hpp"
 #endif
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Load_view utility.
 ***********************************************************************/
Index: tests/expr-test.cpp
===================================================================
--- tests/expr-test.cpp	(revision 144534)
+++ tests/expr-test.cpp	(working copy)
@@ -16,11 +16,12 @@
 #include <vsip/dense.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/math.hpp>
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "block_interface.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 #ifndef ILLEGALCASE
 #  define ILLEGALCASE 0
Index: benchmarks/hpec_kernel/svd.cpp
===================================================================
--- benchmarks/hpec_kernel/svd.cpp	(revision 144534)
+++ benchmarks/hpec_kernel/svd.cpp	(working copy)
@@ -18,9 +18,9 @@
 #include <vsip/tensor.hpp>
 #include <vsip/solvers.hpp>
 #include <vsip/random.hpp>
+#include <vsip_csl/test-precision.hpp>
 
 #include "benchmarks.hpp"
-#include "../../tests/test-precision.hpp"
 
 using namespace std;
 using namespace vsip;
Index: examples/fft.cpp
===================================================================
--- examples/fft.cpp	(revision 144534)
+++ examples/fft.cpp	(working copy)
@@ -24,7 +24,6 @@
   Definitions
 ***********************************************************************/
 
-using namespace std;
 using namespace vsip;
 using namespace vsip_csl;
 
@@ -36,38 +35,34 @@
 void
 fft_example()
 {
-  typedef Fft<const_Vector, cscalar_f, cscalar_f, fft_fwd, by_value, 1, alg_space>
-	f_fft_type;
-  typedef Fft<const_Vector, cscalar_f, cscalar_f, fft_inv, by_value, 1, alg_space>
-	i_fft_type;
-  typedef impl::Cmplx_inter_fmt Complex_format;
+  typedef Fft<const_Vector, cscalar_f, cscalar_f, fft_fwd> f_fft_type;
+  typedef Fft<const_Vector, cscalar_f, cscalar_f, fft_inv> i_fft_type;
 
+  // Create FFT objects
   vsip::length_type N = 1024;
-
   f_fft_type f_fft(Domain<1>(N), 1.0);
   i_fft_type i_fft(Domain<1>(N), 1.0/N);
 
-
-  Vector<cscalar_f> in(N, cscalar_f());
+  // Allocate input and output buffers
+  Vector<cscalar_f> in(N);
+  Vector<cscalar_f> inv(N);
   Vector<cscalar_f> out(N);
   Vector<cscalar_f> ref(N);
-  Vector<cscalar_f> inv(N);
 
-  for ( int n = 0; n < N; ++n )
-    in(n) = sin( 2 * M_PI * n / N );
+  // Create input test data
+  for ( int i = 0; i < N; ++i )
+    in(i) = sin(2 * M_PI * i / N);
 
+  // Compute discrete transform (for reference)
   ref::dft(in, ref, -1);
   
-//  for ( int i = 0; i < 1000; ++i ) {
+  // Compute forward and inverse FFT's
   out = f_fft(in);
-//  }
   inv = i_fft(out);
   
+  // Validate the results (allowing for small numerical errors)
   test_assert(error_db(ref, out) < -100);
-//  test_assert(error_db(inv, in) < -100);
-
-  cout << "fwd = " << f_fft.impl_performance("mflops") << " mflops" << endl;
-  cout << "inv = " << i_fft.impl_performance("mflops") << " mflops" << endl;
+  test_assert(error_db(inv, in) < -100);
 }
 
 
@@ -76,11 +71,9 @@
 {
   vsipl init;
   
-  impl::profile::prof->set_mode( impl::profile::pm_accum );
+  impl::profile::Profile profile("/dev/stdout");
 
   fft_example();
 
-  impl::profile::prof->dump( "/dev/stdout" );
-
   return 0;
 }
Index: examples/GNUmakefile.inc.in
===================================================================
--- examples/GNUmakefile.inc.in	(revision 144534)
+++ examples/GNUmakefile.inc.in	(working copy)
@@ -1,4 +1,4 @@
-########################################################################
+######################################################### -*-Makefile-*-
 #
 # File:   GNUmakefile.inc.in
 # Author: Mark Mitchell 
@@ -34,6 +34,10 @@
 
 examples: $(examples_cxx_exes)
 
+# Object files will be deleted by the parent clean rule.
+clean::
+	rm -f $(examples_cxx_exes)
+
 install::
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)
 	$(INSTALL_DATA) $(examples_cxx_sources) $(DESTDIR)$(pkgdatadir)
