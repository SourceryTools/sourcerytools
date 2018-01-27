Index: src/vsip/impl/ops_info.hpp
===================================================================
--- src/vsip/impl/ops_info.hpp	(revision 145531)
+++ src/vsip/impl/ops_info.hpp	(working copy)
@@ -1,33 +1,41 @@
 /* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
-/** @file    benchmarks/ops_info.cpp
+/** @file    vsip/impl/ops_info.cpp
     @author  Jules Bergmann
     @date    2005-07-11
-    @brief   VSIPL++ Library: Ops info for benchmarks.
+    @brief   VSIPL++ Library: Operation
 
 */
 
-#ifndef VSIP_BENCHMARKS_OPS_INFO_HPP
-#define VSIP_BENCHMARKS_OPS_INFO_HPP
+#ifndef VSIP_IMPL_OPS_INFO_HPP
+#define VSIP_IMPL_OPS_INFO_HPP
 
 #include <complex>
 
+namespace vsip
+{
+namespace impl
+{
+
 template <typename T>
 struct Ops_info
 {
-  static int const div = 1;
-  static int const sqr = 1;
-  static int const mul = 1;
-  static int const add = 1;
+  static unsigned int const div = 1;
+  static unsigned int const sqr = 1;
+  static unsigned int const mul = 1;
+  static unsigned int const add = 1;
 };
 
 template <typename T>
 struct Ops_info<std::complex<T> >
 {
-  static int const div = 6 + 3 + 2; // mul + add + div
-  static int const sqr = 2 + 1;     // mul + add
-  static int const mul = 4 + 2;     // mul + add
-  static int const add = 2;
+  static unsigned int const div = 6 + 3 + 2; // mul + add + div
+  static unsigned int const sqr = 2 + 1;     // mul + add
+  static unsigned int const mul = 4 + 2;     // mul + add
+  static unsigned int const add = 2;
 };
 
-#endif // VSIP_BENCHMARKS_OPS_INFO_HPP
+} // namespace impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_OPS_INFO_HPP
Index: benchmarks/vmagsq.cpp
===================================================================
--- benchmarks/vmagsq.cpp	(revision 145531)
+++ benchmarks/vmagsq.cpp	(working copy)
@@ -37,9 +37,10 @@
   int ops_per_point(length_type)
   {
     if (impl::Is_complex<T>::value)
-      return 2*Ops_info<scalar_type>::mul + Ops_info<scalar_type>::add;
+      return 2*vsip::impl::Ops_info<scalar_type>::mul + 
+        vsip::impl::Ops_info<scalar_type>::add;
     else
-      return Ops_info<T>::mul;
+      return vsip::impl::Ops_info<T>::mul;
   }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
Index: benchmarks/mcopy_ipp.cpp
===================================================================
--- benchmarks/mcopy_ipp.cpp	(revision 145531)
+++ benchmarks/mcopy_ipp.cpp	(working copy)
@@ -23,11 +23,11 @@
 #include <vsip/map.hpp>
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/metaprogramming.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/output.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 #include "plainblock.hpp"
 
Index: benchmarks/prod.cpp
===================================================================
--- benchmarks/prod.cpp	(revision 145531)
+++ benchmarks/prod.cpp	(working copy)
@@ -19,17 +19,16 @@
 #include <vsip/signal.hpp>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 #include "plainblock.hpp"
 
 using namespace vsip;
 
 
-
 /***********************************************************************
   Definition
 ***********************************************************************/
@@ -47,7 +46,8 @@
     length_type N = M;
     length_type P = M;
 
-    float ops = /*M * */ P * N * (Ops_info<T>::mul + Ops_info<T>::add);
+    float ops = /*M * */ P * N * 
+      (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
 
     return ops;
   }
@@ -93,7 +93,8 @@
     length_type N = M;
     length_type P = M;
 
-    float ops = /*M * */ P * N * (Ops_info<T>::mul + Ops_info<T>::add);
+    float ops = /*M * */ P * N * 
+      (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
 
     return ops;
   }
@@ -139,7 +140,8 @@
     length_type N = M;
     length_type P = M;
 
-    float ops = /*M * */ P * N * (Ops_info<T>::mul + Ops_info<T>::add);
+    float ops = /*M * */ P * N * 
+      (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
 
     return ops;
   }
@@ -186,7 +188,8 @@
     length_type N = M;
     length_type P = M;
 
-    float ops = /*M * */ P * N * (Ops_info<T>::mul + Ops_info<T>::add);
+    float ops = /*M * */ P * N * 
+      (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
 
     return ops;
   }
@@ -241,7 +244,8 @@
     length_type N = M;
     length_type P = M;
 
-    float ops = /*M * */ P * N * (Ops_info<T>::mul + Ops_info<T>::add);
+    float ops = /*M * */ P * N * 
+      (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
 
     return ops;
   }
Index: benchmarks/conv.cpp
===================================================================
--- benchmarks/conv.cpp	(revision 145531)
+++ benchmarks/conv.cpp	(working copy)
@@ -19,10 +19,10 @@
 #include <vsip/signal.hpp>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
 
@@ -51,7 +51,7 @@
       output_size = ((size-1)/Dec) - ((coeff_size_-1)/Dec) + 1;
 
     float ops = coeff_size_ * output_size *
-      (Ops_info<T>::mul + Ops_info<T>::add);
+      (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
 
     return ops / size;
   }
Index: benchmarks/corr.cpp
===================================================================
--- benchmarks/corr.cpp	(revision 145531)
+++ benchmarks/corr.cpp	(working copy)
@@ -19,15 +19,14 @@
 #include <vsip/signal.hpp>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -41,7 +40,7 @@
   {
     length_type output_size = this->my_output_size(size);
     float ops = ref_size_ * output_size *
-      (Ops_info<T>::mul + Ops_info<T>::add);
+      (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
 
     return ops / size;
   }
@@ -111,7 +110,7 @@
   {
     length_type output_size = this->my_output_size(size);
     float ops = ref_size_ * output_size *
-      (Ops_info<T>::mul + Ops_info<T>::add);
+      (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
 
     return ops / size;
   }
Index: benchmarks/fft_ext_ipp.cpp
===================================================================
--- benchmarks/fft_ext_ipp.cpp	(revision 145531)
+++ benchmarks/fft_ext_ipp.cpp	(working copy)
@@ -21,13 +21,13 @@
 
 #include <ipps.h>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "loop.hpp"
 
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
Index: benchmarks/vdiv.cpp
===================================================================
--- benchmarks/vdiv.cpp	(revision 145531)
+++ benchmarks/vdiv.cpp	(working copy)
@@ -30,7 +30,7 @@
 struct t_vdiv1
 {
   char* what() { return "t_vdiv1"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::div; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::div; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -75,7 +75,7 @@
 struct t_vdiv_ip1
 {
   char* what() { return "t_vdiv_ip1"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::div; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::div; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -111,7 +111,7 @@
 struct t_vdiv_dom1
 {
   char* what() { return "t_vdiv_dom1"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::div; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::div; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -158,7 +158,7 @@
 struct t_vdiv2
 {
   char* what() { return "t_vdiv2"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::div; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::div; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -204,7 +204,7 @@
 struct t_rcvdiv1
 {
   char* what() { return "t_rcvdiv1"; }
-  int ops_per_point(length_type)  { return 2*Ops_info<T>::div; }
+  int ops_per_point(length_type)  { return 2*vsip::impl::Ops_info<T>::div; }
   int riob_per_point(length_type) { return sizeof(T) + sizeof(complex<T>); }
   int wiob_per_point(length_type) { return 1*sizeof(complex<T>); }
   int mem_per_point(length_type)  { return 1*sizeof(T)+2*sizeof(complex<T>); }
@@ -247,9 +247,9 @@
   char* what() { return "t_svdiv1"; }
   int ops_per_point(length_type)
   { if (sizeof(ScalarT) == sizeof(T))
-      return Ops_info<T>::div;
+      return vsip::impl::Ops_info<T>::div;
     else
-      return 2*Ops_info<ScalarT>::div;
+      return 2*vsip::impl::Ops_info<ScalarT>::div;
   }
   int riob_per_point(length_type) { return 1*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
@@ -284,7 +284,7 @@
 struct t_svdiv2
 {
   char* what() { return "t_svdiv2"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::div; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::div; }
   int riob_per_point(length_type) { return 1*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 2*sizeof(T); }
Index: benchmarks/copy.cpp
===================================================================
--- benchmarks/copy.cpp	(revision 145531)
+++ benchmarks/copy.cpp	(working copy)
@@ -21,10 +21,10 @@
 #include <vsip/map.hpp>
 #include <vsip/parallel.hpp>
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
 using namespace vsip_csl;
Index: benchmarks/conv_ipp.cpp
===================================================================
--- benchmarks/conv_ipp.cpp	(revision 145531)
+++ benchmarks/conv_ipp.cpp	(working copy)
@@ -16,16 +16,15 @@
 #include <complex>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <ipps.h>
 
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using std::complex;
 
 
-
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -67,7 +66,7 @@
     size_t output_size = size+coeff_size_+1; 
 
     float ops = coeff_size_ * output_size *
-      (Ops_info<float>::mul + Ops_info<float>::add);
+      (vsip::impl::Ops_info<float>::mul + vsip::impl::Ops_info<float>::add);
 
     return ops / size;
   }
Index: benchmarks/fir.cpp
===================================================================
--- benchmarks/fir.cpp	(revision 145531)
+++ benchmarks/fir.cpp	(working copy)
@@ -19,13 +19,14 @@
 #include <vsip/signal.hpp>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
 
+
 template <obj_state      Save,
 	  length_type    Dec,
 	  typename       T>
@@ -37,7 +38,7 @@
   float ops_per_point(length_type size)
   {
     float ops = (coeff_size_ * size / Dec) *
-      (Ops_info<T>::mul + Ops_info<T>::add);
+      (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
 
     return ops / size;
   }
Index: benchmarks/benchmarks.hpp
===================================================================
--- benchmarks/benchmarks.hpp	(revision 145531)
+++ benchmarks/benchmarks.hpp	(working copy)
@@ -11,13 +11,13 @@
 #define VSIP_IMPL_BENCHMARKS_HPP
 
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 #ifdef VSIP_IMPL_SOURCERY_VPP
 
 // Sourcery VSIPL++ provides certain resources such as system 
 // timers that are needed for running the benchmarks.
 
+#include <vsip/impl/ops_info.hpp>
 #include <vsip/impl/par-foreach.hpp>
 #include <vsip/impl/profile.hpp>
 #include <vsip_csl/load_view.hpp>
@@ -138,7 +138,26 @@
 } // namespace vsip
 
 
+template <typename T>
+struct Ops_info
+{
+  static unsigned int const div = 1;
+  static unsigned int const sqr = 1;
+  static unsigned int const mul = 1;
+  static unsigned int const add = 1;
+};
 
+template <typename T>
+struct Ops_info<std::complex<T> >
+{
+  static unsigned int const div = 6 + 3 + 2; // mul + add + div
+  static unsigned int const sqr = 2 + 1;     // mul + add
+  static unsigned int const mul = 4 + 2;     // mul + add
+  static unsigned int const add = 2;
+};
+
+
+
 /// Compare two floating-point values for equality.
 ///
 /// Algorithm from:
Index: benchmarks/vmul.cpp
===================================================================
--- benchmarks/vmul.cpp	(revision 145531)
+++ benchmarks/vmul.cpp	(working copy)
@@ -94,7 +94,7 @@
 struct t_vmul1_nonglobal
 {
   char* what() { return "t_vmul1_nonglobal"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -140,7 +140,7 @@
 struct t_vmul1
 {
   char* what() { return "t_vmul1"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -192,7 +192,7 @@
 struct t_vmul1_local
 {
   char* what() { return "t_vmul1"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -243,7 +243,7 @@
 struct t_vmul1_early_local
 {
   char* what() { return "t_vmul1_early_local"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -297,7 +297,7 @@
 struct t_vmul1_sa
 {
   char* what() { return "t_vmul1_sa"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -345,7 +345,7 @@
 struct t_vmul_ip1
 {
   char* what() { return "t_vmul_ip1"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -381,7 +381,7 @@
 struct t_vmul_dom1
 {
   char* what() { return "t_vmul_dom1"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -422,7 +422,7 @@
 struct t_vmul2
 {
   char* what() { return "t_vmul2"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -468,7 +468,7 @@
 struct t_rcvmul1
 {
   char* what() { return "t_rcvmul1"; }
-  int ops_per_point(length_type)  { return 2*Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return 2*vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return sizeof(T) + sizeof(complex<T>); }
   int wiob_per_point(length_type) { return 1*sizeof(complex<T>); }
   int mem_per_point(length_type)  { return 1*sizeof(T)+2*sizeof(complex<T>); }
@@ -511,9 +511,9 @@
   char* what() { return "t_svmul1"; }
   int ops_per_point(length_type)
   { if (sizeof(ScalarT) == sizeof(T))
-      return Ops_info<T>::mul;
+      return vsip::impl::Ops_info<T>::mul;
     else
-      return 2*Ops_info<ScalarT>::mul;
+      return 2*vsip::impl::Ops_info<ScalarT>::mul;
   }
   int riob_per_point(length_type) { return 1*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
@@ -552,7 +552,7 @@
 struct t_svmul2
 {
   char* what() { return "t_svmul2"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 1*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 2*sizeof(T); }
Index: benchmarks/vma.cpp
===================================================================
--- benchmarks/vma.cpp	(revision 145531)
+++ benchmarks/vma.cpp	(working copy)
@@ -20,7 +20,7 @@
 #include <vsip/random.hpp>
 
 #include "benchmarks.hpp"
-#include "test-storage.hpp"
+#include "../tests/test-storage.hpp"
 
 using namespace vsip;
 
@@ -37,7 +37,7 @@
 {
   char* what() { return "t_vma"; }
   int ops_per_point(length_type)
-    { return Ops_info<T>::mul + Ops_info<T>::add; }
+    { return vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -75,7 +75,7 @@
 {
   char* what() { return "t_vma_ip"; }
   int ops_per_point(length_type)
-    { return Ops_info<T>::mul + Ops_info<T>::add; }
+    { return vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
Index: benchmarks/dot.cpp
===================================================================
--- benchmarks/dot.cpp	(revision 145531)
+++ benchmarks/dot.cpp	(working copy)
@@ -19,15 +19,14 @@
 #include <vsip/signal.hpp>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
 
 
-
 /***********************************************************************
   Definition
 ***********************************************************************/
@@ -42,7 +41,7 @@
   char* what() { return "t_dot1"; }
   float ops_per_point(length_type)
   {
-    float ops = (Ops_info<T>::mul + Ops_info<T>::add);
+    float ops = (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
 
     return ops;
   }
@@ -89,7 +88,7 @@
   char* what() { return "t_dot2"; }
   float ops_per_point(length_type)
   {
-    float ops = (Ops_info<T>::mul + Ops_info<T>::add);
+    float ops = (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
 
     return ops;
   }
Index: benchmarks/vmul_ipp.cpp
===================================================================
--- benchmarks/vmul_ipp.cpp	(revision 145531)
+++ benchmarks/vmul_ipp.cpp	(working copy)
@@ -15,11 +15,11 @@
 #include <complex>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <ipps.h>
 
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
 
@@ -35,7 +35,7 @@
 {
   typedef float T;
   char* what() { return "t_vmul_ipp"; }
-  int ops_per_point(size_t)  { return Ops_info<T>::mul; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
   int mem_per_point(size_t)  { return 3*sizeof(T); }
@@ -86,7 +86,7 @@
   typedef std::complex<float> T;
 
   char* what() { return "t_vmul_ipp complex<float>"; }
-  int ops_per_point(size_t)  { return Ops_info<T>::mul; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
   int mem_per_point(size_t)  { return 3*sizeof(T); }
@@ -139,7 +139,7 @@
   typedef std::complex<float> T;
 
   char* what() { return "t_vmul_ipp complex<float>"; }
-  int ops_per_point(size_t)  { return Ops_info<T>::mul; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
   int mem_per_point(size_t)  { return 2*sizeof(T); }
@@ -190,7 +190,7 @@
   typedef std::complex<float> T;
 
   char* what() { return "t_vmul_ipp complex<float>"; }
-  int ops_per_point(size_t)  { return Ops_info<T>::mul; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
   int mem_per_point(size_t)  { return 2*sizeof(T); }
Index: benchmarks/hpec_kernel/GNUmakefile.inc.in
===================================================================
--- benchmarks/hpec_kernel/GNUmakefile.inc.in	(revision 145531)
+++ benchmarks/hpec_kernel/GNUmakefile.inc.in	(working copy)
@@ -39,5 +39,5 @@
 	rm -f $(hpec_cxx_exes_def_build)
 
 $(hpec_cxx_exes_def_build): %$(EXEEXT) : \
-  %.$(OBJEXT) benchmarks/main.$(OBJEXT) lib/libvsip.a
-	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS) || rm -f $@
+  %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
+	$(CXX) $(LDFLAGS) -o $@ $^ -Llib -lvsip $(LIBS) || rm -f $@
Index: benchmarks/hpec_kernel/cfar.cpp
===================================================================
--- benchmarks/hpec_kernel/cfar.cpp	(revision 145531)
+++ benchmarks/hpec_kernel/cfar.cpp	(working copy)
@@ -575,8 +575,8 @@
 {
   int ops_per_point(length_type /*size*/)
   { 
-    int ops = Ops_info<T>::sqr + Ops_info<T>::mul
-        + 4 * Ops_info<T>::add + Ops_info<T>::div; 
+    int ops = vsip::impl::Ops_info<T>::sqr + vsip::impl::Ops_info<T>::mul
+        + 4 * vsip::impl::Ops_info<T>::add + vsip::impl::Ops_info<T>::div; 
     return (this->beams_ * this->dbins_ * ops);
   }
   int riob_per_point(length_type) { return -1; }
Index: benchmarks/hpec_kernel/firbank.cpp
===================================================================
--- benchmarks/hpec_kernel/firbank.cpp	(revision 145531)
+++ benchmarks/hpec_kernel/firbank.cpp	(working copy)
@@ -130,7 +130,7 @@
   float ops(length_type filters, length_type points, length_type coeffs)
   {
     float total_ops = filters * points * coeffs *
-                  (Ops_info<T>::mul + Ops_info<T>::add); 
+                  (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add); 
     return total_ops;
   }
 
@@ -205,8 +205,8 @@
 
     return float(
       filters * ( 
-        2 * fft_ops(points) +       // one forward, one reverse FFT
-        Ops_info<T>::mul * points   // element-wise vector multiply
+        2 * fft_ops(points) +                   // one forward, one reverse FFT
+        vsip::impl::Ops_info<T>::mul * points   // element-wise vector multiply
       )
     );
   }
Index: benchmarks/hpec_kernel/cfar_c.cpp
===================================================================
--- benchmarks/hpec_kernel/cfar_c.cpp	(revision 145531)
+++ benchmarks/hpec_kernel/cfar_c.cpp	(working copy)
@@ -64,8 +64,8 @@
 {
   int ops_per_point(length_type /*size*/)
   { 
-    int ops = Ops_info<T>::sqr + Ops_info<T>::mul
-        + 4 * Ops_info<T>::add + Ops_info<T>::div; 
+    int ops = vsip::impl::Ops_info<T>::sqr + vsip::impl::Ops_info<T>::mul
+        + 4 * vsip::impl::Ops_info<T>::add + vsip::impl::Ops_info<T>::div; 
     return (beams_ * dbins_ * ops);
   }
   int riob_per_point(length_type) { return -1; }
Index: benchmarks/vmmul.cpp
===================================================================
--- benchmarks/vmmul.cpp	(revision 145531)
+++ benchmarks/vmmul.cpp	(working copy)
@@ -18,16 +18,15 @@
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
 using namespace vsip_csl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -52,7 +51,7 @@
 {
   char* what() { return "t_vmmul<T, Impl_op, SD>"; }
   int ops(length_type rows, length_type cols)
-    { return rows * cols * Ops_info<T>::mul; }
+    { return rows * cols * vsip::impl::Ops_info<T>::mul; }
 
   void exec(length_type rows, length_type cols, length_type loop, float& time)
   {
@@ -92,7 +91,7 @@
 {
   char* what() { return "t_vmmul<T, Impl_op, SD>"; }
   int ops(length_type rows, length_type cols)
-    { return rows * cols * Ops_info<T>::mul; }
+    { return rows * cols * vsip::impl::Ops_info<T>::mul; }
 
   void exec(length_type rows, length_type cols, length_type loop, float& time)
   {
Index: benchmarks/mpi_alltoall.cpp
===================================================================
--- benchmarks/mpi_alltoall.cpp	(revision 145531)
+++ benchmarks/mpi_alltoall.cpp	(working copy)
@@ -18,10 +18,10 @@
 #include <vsip/math.hpp>
 #include <vsip/map.hpp>
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
 using namespace vsip_csl;
Index: benchmarks/prod_var.cpp
===================================================================
--- benchmarks/prod_var.cpp	(revision 145531)
+++ benchmarks/prod_var.cpp	(working copy)
@@ -19,22 +19,22 @@
 #include <vsip/signal.hpp>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/test-precision.hpp>
 #include <vsip_csl/output.hpp>
-#include "ref_matvec.hpp"
+#include <vsip_csl/ref_matvec.hpp>
 
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 #define VERBOSE 1
 
 using namespace vsip;
 using namespace vsip_csl;
+using namespace ref;
 
 
-
 /***********************************************************************
   Matrix-matrix product variants
 ***********************************************************************/
@@ -56,7 +56,7 @@
   Matrix<T, Block2> B,
   Matrix<T, Block3> C)
 {
-  C = prod(A,B);
+  C = vsip::prod(A,B);
 }
 
 // prod_2: Alg 1.1.8 Outer Product from G&VL
@@ -268,7 +268,7 @@
   for(index_type i = 0; i<A.size(0); i++){
     typename Matrix<T, Block1>::row_type a_row(A.row(i));
     for(index_type j=0; j<B.size(1); j++){
-      C.put(i, j, dot(a_row, B.col(j)));
+      C.put(i, j, vsip::dot(a_row, B.col(j)));
     }
   }
 }
@@ -326,7 +326,8 @@
     length_type N = M;
     length_type P = M;
 
-    float ops = /*M * */ P * N * (Ops_info<T>::mul + Ops_info<T>::add);
+    float ops = /*M * */ P * N * 
+      (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
 
     return ops;
   }
Index: benchmarks/ops_info.hpp
===================================================================
--- benchmarks/ops_info.hpp	(revision 145531)
+++ benchmarks/ops_info.hpp	(working copy)
@@ -1,33 +0,0 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
-
-/** @file    benchmarks/ops_info.cpp
-    @author  Jules Bergmann
-    @date    2005-07-11
-    @brief   VSIPL++ Library: Ops info for benchmarks.
-
-*/
-
-#ifndef VSIP_BENCHMARKS_OPS_INFO_HPP
-#define VSIP_BENCHMARKS_OPS_INFO_HPP
-
-#include <complex>
-
-template <typename T>
-struct Ops_info
-{
-  static int const div = 1;
-  static int const sqr = 1;
-  static int const mul = 1;
-  static int const add = 1;
-};
-
-template <typename T>
-struct Ops_info<std::complex<T> >
-{
-  static int const div = 6 + 3 + 2; // mul + add + div
-  static int const sqr = 2 + 1;     // mul + add
-  static int const mul = 4 + 2;     // mul + add
-  static int const add = 2;
-};
-
-#endif // VSIP_BENCHMARKS_OPS_INFO_HPP
Index: benchmarks/vmul_sal.cpp
===================================================================
--- benchmarks/vmul_sal.cpp	(revision 145531)
+++ benchmarks/vmul_sal.cpp	(working copy)
@@ -17,10 +17,10 @@
 #include <vsip/random.hpp>
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/extdata.hpp>
+#include <vsip/impl/ops_info.hpp>
 #include <sal.h>
 
 #include "loop.hpp"
-#include "ops_info.hpp"
 #include "benchmarks.hpp"
 
 using namespace std;
@@ -49,7 +49,7 @@
   typedef float T;
 
   char* what() { return "t_vmul_sal"; }
-  int ops_per_point(size_t)  { return Ops_info<float>::mul; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<float>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(float); }
   int wiob_per_point(size_t) { return 1*sizeof(float); }
   int mem_per_point(size_t)  { return 3*sizeof(float); }
@@ -99,7 +99,7 @@
   typedef complex<float> T;
 
   char* what() { return "t_vmul_sal complex<float> inter"; }
-  int ops_per_point(size_t)  { return Ops_info<T>::mul; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
   int mem_per_point(size_t)  { return 3*sizeof(float); }
@@ -151,7 +151,7 @@
   typedef complex<float> T;
 
   char* what() { return "t_vmul_sal complex<float> split"; }
-  int ops_per_point(size_t)  { return Ops_info<T>::mul; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
   int mem_per_point(size_t)  { return 3*sizeof(float); }
@@ -205,7 +205,7 @@
   typedef complex<float> T;
 
   char* what() { return "t_vmul_sal complex<float>"; }
-  int ops_per_point(size_t)  { return Ops_info<T>::mul; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
   int mem_per_point(size_t)  { return 2*sizeof(float); }
@@ -254,7 +254,7 @@
   typedef complex<float> T;
 
   char* what() { return "t_vmul_sal complex<float>"; }
-  int ops_per_point(size_t)  { return Ops_info<T>::mul; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
   int mem_per_point(size_t)  { return 2*sizeof(float); }
@@ -312,7 +312,7 @@
   typedef float T;
 
   char* what() { return "t_svmul_sal"; }
-  int ops_per_point(size_t)  { return Ops_info<float>::mul; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<float>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(float); }
   int wiob_per_point(size_t) { return 1*sizeof(float); }
   int mem_per_point(size_t)  { return 3*sizeof(float); }
@@ -362,7 +362,7 @@
   typedef float T;
 
   char* what() { return "t_svmul_sal"; }
-  int ops_per_point(size_t)  { return Ops_info<float>::mul; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<float>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(float); }
   int wiob_per_point(size_t) { return 1*sizeof(float); }
   int mem_per_point(size_t)  { return 3*sizeof(float); }
@@ -415,7 +415,7 @@
   typedef float T;
 
   char* what() { return "t_svmul_sal"; }
-  int ops_per_point(size_t)  { return Ops_info<float>::mul; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<float>::mul; }
   int riob_per_point(size_t) { return 2*sizeof(float); }
   int wiob_per_point(size_t) { return 1*sizeof(float); }
   int mem_per_point(size_t)  { return 3*sizeof(float); }
Index: benchmarks/vma_sal.cpp
===================================================================
--- benchmarks/vma_sal.cpp	(revision 145531)
+++ benchmarks/vma_sal.cpp	(working copy)
@@ -17,10 +17,10 @@
 #include <vsip/random.hpp>
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/extdata.hpp>
+#include <vsip/impl/ops_info.hpp>
 #include <sal.h>
 
 #include "loop.hpp"
-#include "ops_info.hpp"
 #include "benchmarks.hpp"
 
 using namespace std;
@@ -41,7 +41,8 @@
   typedef float T;
 
   char* what() { return "t_vma_sal"; }
-  int ops_per_point(size_t)  { return Ops_info<T>::mul + Ops_info<T>::add; }
+  int ops_per_point(size_t)  
+    { return vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add; }
   int riob_per_point(size_t) { return 3*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
   int mem_per_point(size_t)  { return 4*sizeof(T); }
@@ -101,7 +102,8 @@
   typedef float T;
 
   char* what() { return "t_vsma_sal"; }
-  int ops_per_point(size_t)  { return Ops_info<T>::mul + Ops_info<T>::add; }
+  int ops_per_point(size_t)  
+    { return vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
   int mem_per_point(size_t)  { return 3*sizeof(T); }
@@ -155,7 +157,8 @@
   typedef complex<float> T;
 
   char* what() { return "t_vsma_sal complex<float> inter"; }
-  int ops_per_point(size_t)  { return Ops_info<T>::mul + Ops_info<T>::add; }
+  int ops_per_point(size_t)  
+    { return vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
   int mem_per_point(size_t)  { return 3*sizeof(T); }
@@ -213,7 +216,8 @@
   typedef complex<float> T;
 
   char* what() { return "t_vsma_sal complex<float> split"; }
-  int ops_per_point(size_t)  { return Ops_info<T>::mul + Ops_info<T>::add; }
+  int ops_per_point(size_t)  
+    { return vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add; }
   int riob_per_point(size_t) { return 2*sizeof(T); }
   int wiob_per_point(size_t) { return 1*sizeof(T); }
   int mem_per_point(size_t)  { return 3*sizeof(T); }
Index: benchmarks/vmul_c.cpp
===================================================================
--- benchmarks/vmul_c.cpp	(revision 145531)
+++ benchmarks/vmul_c.cpp	(working copy)
@@ -17,10 +17,10 @@
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
 using namespace vsip_csl;
@@ -79,7 +79,7 @@
 struct t_vmul1
 {
   char* what() { return "t_vmul1"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -137,7 +137,7 @@
 struct t_vmul2
 {
   char* what() { return "t_vmul2"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -192,7 +192,7 @@
 struct t_svmul1
 {
   char* what() { return "t_svmul1"; }
-  int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 1*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
Index: benchmarks/mcopy.cpp
===================================================================
--- benchmarks/mcopy.cpp	(revision 145531)
+++ benchmarks/mcopy.cpp	(working copy)
@@ -21,10 +21,10 @@
 #include <vsip/map.hpp>
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/metaprogramming.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 #include "plainblock.hpp"
 
Index: benchmarks/maxval.cpp
===================================================================
--- benchmarks/maxval.cpp	(revision 145531)
+++ benchmarks/maxval.cpp	(working copy)
@@ -18,13 +18,13 @@
 #include <vsip/selgen.hpp>
 #include <vsip/impl/profile.hpp>
 
-#include "test.hpp"
+#include <vsip_csl/test.hpp>
 #include "loop.hpp"
 
 using namespace vsip;
+using namespace vsip_csl;
 
 
-
 template <typename T>
 struct t_maxval1
 {
