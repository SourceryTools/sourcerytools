Index: ChangeLog
===================================================================
--- ChangeLog	(revision 179845)
+++ ChangeLog	(working copy)
@@ -1,3 +1,17 @@
+2007-08-25  Jules Bergmann  <jules@codesourcery.com>
+
+	Fix bug: dispatch to SAL evaluated A-b*C as A*b-C.
+	* src/vsip/opt/sal/is_op_supported.hpp: Remove incorrect dispatch for
+	  msb_functor.
+	* src/vsip/opt/sal/elementwise.hpp: Remove incorrect wrapper functions
+	  for vmsb..
+	* src/vsip/opt/sal/eval_elementwise.hpp: Fix typo in V_VV support
+	  check.
+	* tests/regressions/fused_mul_sub.cpp: Coverage for incorrect msb
+	  case.
+
+	* src/vsip_csl/GNUmakefile.inc.in (install): Add src/vsip_csl/output.
+
 2007-08-23  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/subblock.hpp: Fix parent local domain query for
Index: src/vsip/opt/sal/is_op_supported.hpp
===================================================================
--- src/vsip/opt/sal/is_op_supported.hpp	(revision 179530)
+++ src/vsip/opt/sal/is_op_supported.hpp	(working copy)
@@ -481,13 +481,11 @@
 
 // Multiply-subtract
 
-VSIP_IMPL_OP3SUP(msb_functor, float,   float*,  float*, float*);
 VSIP_IMPL_OP3SUP(msb_functor, float*,  float,   float*, float*);
 // not in sal   (msb_functor, float*,  float*,  float,  float*);
 VSIP_IMPL_OP3SUP(msb_functor, float*,  float*,  float*, float*);
 
 #if VSIP_IMPL_HAVE_SAL_DOUBLE
-VSIP_IMPL_OP3SUP(msb_functor, double,   double*,  double*, double*);
 VSIP_IMPL_OP3SUP(msb_functor, double*,  double,   double*, double*);
 // not in sal   (msb_functor, double*,  double*,  double,  double*);
 VSIP_IMPL_OP3SUP(msb_functor, double*,  double*,  double*, double*);
Index: src/vsip/opt/sal/elementwise.hpp
===================================================================
--- src/vsip/opt/sal/elementwise.hpp	(revision 179530)
+++ src/vsip/opt/sal/elementwise.hpp	(working copy)
@@ -826,8 +826,6 @@
 // Z = A*b-C -- Vector scalar multiply and vector subtract
 VSIP_IMPL_SAL_VSV(vmsb, float,  vsmsbx)
 VSIP_IMPL_SAL_VSV(vmsb, double, vsmsbdx)
-VSIP_IMPL_SAL_SVV_AS_VSV(vmsb, float,  vsmsbx)
-VSIP_IMPL_SAL_SVV_AS_VSV(vmsb, double, vsmsbdx)
 
 
 
Index: src/vsip/opt/sal/eval_elementwise.hpp
===================================================================
--- src/vsip/opt/sal/eval_elementwise.hpp	(revision 178505)
+++ src/vsip/opt/sal/eval_elementwise.hpp	(working copy)
@@ -625,7 +625,7 @@
     (!Is_expr_block<Block1>::value || Is_scalar_block<Block1>::value) &&\
     (!Is_expr_block<Block2>::value || Is_scalar_block<Block2>::value) &&\
     (!Is_expr_block<Block3>::value || Is_scalar_block<Block3>::value) &&\
-     sal::Is_op3_supported<OP, eff_1_t, eff_2_t, eff_3_t, eff_dst_t>::value&&\
+     sal::Is_op3_supported<OP, eff_2_t, eff_3_t, eff_1_t, eff_dst_t>::value&&\
      /* check that direct access is supported */			\
      Ext_data_cost<DstBlock>::value == 0 &&				\
      (Ext_data_cost<Block1>::value == 0 || Is_scalar_block<Block1>::value) &&\
@@ -657,8 +657,8 @@
 VSIP_IMPL_SAL_VV_V_EXPR(am_functor,  op::Add,  op::Mult, sal::vam)
 VSIP_IMPL_SAL_VV_V_EXPR(sbm_functor, op::Sub,  op::Mult, sal::vsbm)
 
+// V OP2 (V OP1 V)
 VSIP_IMPL_SAL_V_VV_EXPR(ma_functor,  op::Mult, op::Add,  sal::vma)
-VSIP_IMPL_SAL_V_VV_EXPR(msb_functor, op::Mult, op::Sub,  sal::vmsb)
 VSIP_IMPL_SAL_V_VV_EXPR(am_functor,  op::Add,  op::Mult, sal::vam)
 VSIP_IMPL_SAL_V_VV_EXPR(sbm_functor, op::Sub,  op::Mult, sal::vsbm)
 
Index: src/vsip_csl/GNUmakefile.inc.in
===================================================================
--- src/vsip_csl/GNUmakefile.inc.in	(revision 177479)
+++ src/vsip_csl/GNUmakefile.inc.in	(working copy)
@@ -52,11 +52,15 @@
           $(DESTDIR)$(libdir)/libvsip_csl$(suffix).$(LIBEXT)
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip_csl
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip_csl/stencil
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip_csl/output
 	for header in $(wildcard $(srcdir)/src/vsip_csl/*.hpp); do \
           $(INSTALL_DATA) $$header $(DESTDIR)$(includedir)/vsip_csl; \
 	done
 	for header in $(wildcard $(srcdir)/src/vsip_csl/stencil/*.hpp); do \
           $(INSTALL_DATA) $$header $(DESTDIR)$(includedir)/vsip_csl/stencil; \
 	done
+	for header in $(wildcard $(srcdir)/src/vsip_csl/output/*.hpp); do \
+          $(INSTALL_DATA) $$header $(DESTDIR)$(includedir)/vsip_csl/output; \
+	done
 
 endif
Index: tests/regressions/fused_mul_sub.cpp
===================================================================
--- tests/regressions/fused_mul_sub.cpp	(revision 0)
+++ tests/regressions/fused_mul_sub.cpp	(revision 0)
@@ -0,0 +1,89 @@
+/* Copyright (c) 2007 by CodeSourcery, LLC.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/regressions/fused_mul_sub.cpp
+    @author  Jules Bergmann
+    @date    2007-08-23
+    @brief   VSIPL++ Library: Regresions for cases mishandled by SAL dispatch.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/signal.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T>
+void
+test()
+{
+  length_type size = 4;
+
+  Vector<T> A(size, T(3));
+  T         b = T(4);
+  Vector<T> C(size, T(3));
+  Vector<T> Z(size, T());
+
+  // --------------------------------------------------------------------
+  // SAL dispatch had this going to b*C - A instead of A - b*C.
+  Z = A - b*C;
+
+  for (index_type i=0; i<size; ++i)
+    test_assert(Z.get(i) == A.get(i) - b*C.get(i));
+
+  // --------------------------------------------------------------------
+  Z = A + b*C;
+
+  for (index_type i=0; i<size; ++i)
+    test_assert(Z.get(i) == A.get(i) + b*C.get(i));
+
+  // --------------------------------------------------------------------
+  Z = b * (A+C);
+
+  for (index_type i=0; i<size; ++i)
+    test_assert(Z.get(i) == b*(A.get(i) + C.get(i)));
+
+  // --------------------------------------------------------------------
+  // SAL dispatch wasn't catching this
+  // (wrong order of args to is_op_supported)
+  Z = b * (A-C);
+
+  for (index_type i=0; i<size; ++i)
+    test_assert(Z.get(i) == b*(A.get(i) - C.get(i)));
+}
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test<float>();
+  test<double>();
+  test<complex<float> >();
+  test<complex<double> >();
+
+  return 0;
+}
