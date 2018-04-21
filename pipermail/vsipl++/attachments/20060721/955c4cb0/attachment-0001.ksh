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
@@ -22,6 +22,7 @@
 #include "benchmarks.hpp"
 
 using namespace vsip;
+using namespace impl;
 
 
 /***********************************************************************
Index: benchmarks/mcopy_ipp.cpp
===================================================================
--- benchmarks/mcopy_ipp.cpp	(revision 145531)
+++ benchmarks/mcopy_ipp.cpp	(working copy)
@@ -23,15 +23,16 @@
 #include <vsip/map.hpp>
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/metaprogramming.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/output.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 #include "plainblock.hpp"
 
 using namespace vsip;
+using namespace impl;
 using namespace vsip_csl;
 
 using vsip::impl::ITE_Type;
Index: benchmarks/prod.cpp
===================================================================
--- benchmarks/prod.cpp	(revision 145531)
+++ benchmarks/prod.cpp	(working copy)
@@ -19,17 +19,17 @@
 #include <vsip/signal.hpp>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 #include "plainblock.hpp"
 
 using namespace vsip;
+using namespace impl;
 
 
-
 /***********************************************************************
   Definition
 ***********************************************************************/
Index: benchmarks/conv.cpp
===================================================================
--- benchmarks/conv.cpp	(revision 145531)
+++ benchmarks/conv.cpp	(working copy)
@@ -19,12 +19,13 @@
 #include <vsip/signal.hpp>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
+using namespace impl;
 
 
 
Index: benchmarks/corr.cpp
===================================================================
--- benchmarks/corr.cpp	(revision 145531)
+++ benchmarks/corr.cpp	(working copy)
@@ -19,15 +19,15 @@
 #include <vsip/signal.hpp>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
+using namespace impl;
 
 
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
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
@@ -20,6 +20,7 @@
 #include "benchmarks.hpp"
 
 using namespace vsip;
+using namespace impl;
 
 
 /***********************************************************************
Index: benchmarks/copy.cpp
===================================================================
--- benchmarks/copy.cpp	(revision 145531)
+++ benchmarks/copy.cpp	(working copy)
@@ -21,12 +21,13 @@
 #include <vsip/map.hpp>
 #include <vsip/parallel.hpp>
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
+using namespace impl;
 using namespace vsip_csl;
 
 
Index: benchmarks/conv_ipp.cpp
===================================================================
--- benchmarks/conv_ipp.cpp	(revision 145531)
+++ benchmarks/conv_ipp.cpp	(working copy)
@@ -16,16 +16,16 @@
 #include <complex>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <ipps.h>
 
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using std::complex;
+using namespace impl;
 
 
-
 /***********************************************************************
   Declarations
 ***********************************************************************/
Index: benchmarks/fir.cpp
===================================================================
--- benchmarks/fir.cpp	(revision 145531)
+++ benchmarks/fir.cpp	(working copy)
@@ -19,12 +19,13 @@
 #include <vsip/signal.hpp>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
+using namespace impl;
 
 template <obj_state      Save,
 	  length_type    Dec,
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
@@ -21,6 +21,7 @@
 #include "benchmarks.hpp"
 
 using namespace vsip;
+using namespace impl;
 
 
 template <vsip::dimension_type Dim,
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
@@ -19,15 +19,15 @@
 #include <vsip/signal.hpp>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
+using namespace impl;
 
 
-
 /***********************************************************************
   Definition
 ***********************************************************************/
Index: benchmarks/vmul_ipp.cpp
===================================================================
--- benchmarks/vmul_ipp.cpp	(revision 145531)
+++ benchmarks/vmul_ipp.cpp	(working copy)
@@ -15,13 +15,14 @@
 #include <complex>
 
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <ipps.h>
 
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
+using namespace impl;
 
 
 template <typename T>
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
@@ -45,6 +45,7 @@
 #include "benchmarks.hpp"
 
 using namespace vsip;
+using namespace impl;
 
 
 #ifdef VSIP_IMPL_SOURCERY_VPP
Index: benchmarks/hpec_kernel/firbank.cpp
===================================================================
--- benchmarks/hpec_kernel/firbank.cpp	(revision 145531)
+++ benchmarks/hpec_kernel/firbank.cpp	(working copy)
@@ -29,6 +29,7 @@
 #include "benchmarks.hpp"
 
 using namespace vsip;
+using namespace impl;
 
 
 #ifdef VSIP_IMPL_SOURCERY_VPP
Index: benchmarks/hpec_kernel/svd.cpp
===================================================================
--- benchmarks/hpec_kernel/svd.cpp	(revision 145531)
+++ benchmarks/hpec_kernel/svd.cpp	(working copy)
@@ -24,6 +24,7 @@
 
 using namespace std;
 using namespace vsip;
+using namespace impl;
 
 
 /***********************************************************************
Index: benchmarks/hpec_kernel/cfar_c.cpp
===================================================================
--- benchmarks/hpec_kernel/cfar_c.cpp	(revision 145531)
+++ benchmarks/hpec_kernel/cfar_c.cpp	(working copy)
@@ -46,6 +46,7 @@
 #include "benchmarks.hpp"
 
 using namespace vsip;
+using namespace impl;
 
 
 #ifdef VSIP_IMPL_SOURCERY_VPP
Index: benchmarks/vmmul.cpp
===================================================================
--- benchmarks/vmmul.cpp	(revision 145531)
+++ benchmarks/vmmul.cpp	(working copy)
@@ -18,12 +18,13 @@
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
+using namespace impl;
 using namespace vsip_csl;
 
 
Index: benchmarks/mpi_alltoall.cpp
===================================================================
--- benchmarks/mpi_alltoall.cpp	(revision 145531)
+++ benchmarks/mpi_alltoall.cpp	(working copy)
@@ -18,12 +18,13 @@
 #include <vsip/math.hpp>
 #include <vsip/map.hpp>
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
+using namespace impl;
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
@@ -17,14 +17,15 @@
 #include <vsip/random.hpp>
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/extdata.hpp>
+#include <vsip/impl/ops_info.hpp>
 #include <sal.h>
 
 #include "loop.hpp"
-#include "ops_info.hpp"
 #include "benchmarks.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace impl;
 
 using impl::Stride_unit_dense;
 using impl::Cmplx_inter_fmt;
Index: benchmarks/vma_sal.cpp
===================================================================
--- benchmarks/vma_sal.cpp	(revision 145531)
+++ benchmarks/vma_sal.cpp	(working copy)
@@ -17,14 +17,15 @@
 #include <vsip/random.hpp>
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/extdata.hpp>
+#include <vsip/impl/ops_info.hpp>
 #include <sal.h>
 
 #include "loop.hpp"
-#include "ops_info.hpp"
 #include "benchmarks.hpp"
 
 using namespace std;
 using namespace vsip;
+using namespace impl;
 
 using impl::Stride_unit_dense;
 using impl::Cmplx_inter_fmt;
Index: benchmarks/vmul_c.cpp
===================================================================
--- benchmarks/vmul_c.cpp	(revision 145531)
+++ benchmarks/vmul_c.cpp	(working copy)
@@ -17,12 +17,13 @@
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 #include <vsip/impl/profile.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 using namespace vsip;
+using namespace impl;
 using namespace vsip_csl;
 
 using impl::Stride_unit_dense;
Index: benchmarks/mcopy.cpp
===================================================================
--- benchmarks/mcopy.cpp	(revision 145531)
+++ benchmarks/mcopy.cpp	(working copy)
@@ -21,14 +21,15 @@
 #include <vsip/map.hpp>
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/metaprogramming.hpp>
+#include <vsip/impl/ops_info.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
-#include "ops_info.hpp"
 
 #include "plainblock.hpp"
 
 using namespace vsip;
+using namespace impl;
 using namespace vsip_csl;
 
 using vsip::impl::ITE_Type;
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
