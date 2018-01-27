Index: ChangeLog
===================================================================
--- ChangeLog	(revision 218807)
+++ ChangeLog	(working copy)
@@ -1,5 +1,20 @@
+2008-08-27  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/cbe/ppu/fastconv.cpp: Fix number of DTL entires
+	  reserved, conservatively at 8.  Fixes fastconv.cpp test failure.
+	* src/vsip/opt/ukernel.hpp: Avoid excess pre_chunks.
+	* src/vsip/opt/diag/eval.hpp: Add Opt_tag to dispatch_name.
+	* tests/coverage_binary_mul_m.cpp: Fix typo in comment.
+	* tests/ukernel/vmmul.cpp: Fix typo in header
+	* benchmarks/vmmul.cpp: Add usage, improve checking.
+
 2008-08-26  Jules Bergmann  <jules@codesourcery.com>
 
+	* benchmarks/GNUmakefile.inc.in: Add <benchmark>.prof rule to create
+	  benchmark binaries with profiling enabled.
+
+2008-08-26  Jules Bergmann  <jules@codesourcery.com>
+
 	* README.cbe: Update for binary CML package.
 	* examples/cell/setup.sh: New file, example CBE configury options.
 
Index: src/vsip/opt/cbe/ppu/fastconv.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fastconv.cpp	(revision 218695)
+++ src/vsip/opt/cbe/ppu/fastconv.cpp	(working copy)
@@ -74,7 +74,7 @@
 
   Task_manager *mgr = Task_manager::instance();
   Task task = mgr->reserve<tag_type, void(T,T)>
-    (stack_size, psize, sizeof(T)*length*num_inputs, sizeof(T)*length, true);
+    (stack_size, psize, sizeof(T)*length*num_inputs, sizeof(T)*length, 8);
 
   length_type spes         = mgr->num_spes();
   length_type rows_per_spe = rows / spes;
@@ -139,7 +139,7 @@
   Task_manager *mgr = Task_manager::instance();
   Task task = mgr->reserve<tag_type, void(std::pair<uT*,uT*>,
 					  std::pair<uT*,uT*>)>
-    (stack_size, psize, sizeof(T)*length*num_inputs, sizeof(T)*length, true);
+    (stack_size, psize, sizeof(T)*length*num_inputs, sizeof(T)*length, 8);
 
   length_type spes         = mgr->num_spes();
   length_type rows_per_spe = rows / spes;
Index: src/vsip/opt/ukernel.hpp
===================================================================
--- src/vsip/opt/ukernel.hpp	(revision 218806)
+++ src/vsip/opt/ukernel.hpp	(working copy)
@@ -718,7 +718,7 @@
     length_type dtl_size;
     if (FuncT::pre_argc > 0)
     {
-      ukp.pre_chunks = vh1.num_chunks();
+      ukp.pre_chunks = vh0.num_chunks();
       isize = std::max(vh0.buffer_size(), vh1.buffer_size());
       dtl_size = std::max(vh0.dtl_size(), vh1.dtl_size() + vh2.dtl_size());
       osize = vh2.buffer_size();
Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 218695)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -94,6 +94,7 @@
 VSIP_IMPL_DISPATCH_NAME(Mdim_expr_tag)
 VSIP_IMPL_DISPATCH_NAME(Loop_fusion_tag)
 VSIP_IMPL_DISPATCH_NAME(Cvsip_tag)
+VSIP_IMPL_DISPATCH_NAME(Opt_tag)
 VSIP_IMPL_DISPATCH_NAME(Generic_tag)
 
 VSIP_IMPL_DISPATCH_NAME(Tag_illegal_mix_of_local_and_global_in_assign)
Index: tests/coverage_binary_mul_m.cpp
===================================================================
--- tests/coverage_binary_mul_m.cpp	(revision 218804)
+++ tests/coverage_binary_mul_m.cpp	(working copy)
@@ -8,7 +8,7 @@
     @author  Jules Bergmann
     @date    2005-09-13
     @brief   VSIPL++ Library: Coverage tests for binary expressions.
-                              multipl/matrix
+                              multiply/matrix
 */
 
 /***********************************************************************
Index: tests/ukernel/vmmul.cpp
===================================================================
--- tests/ukernel/vmmul.cpp	(revision 218695)
+++ tests/ukernel/vmmul.cpp	(working copy)
@@ -1,6 +1,6 @@
 /* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
 
-/** @file    tests/x-uk-vmul.cpp
+/** @file    tests/ukernel/vmmul.cpp
     @author  Jules Bergmann
     @date    2008-06-24
     @brief   VSIPL++ Library: Test Vmul Ukernel
Index: benchmarks/vmmul.cpp
===================================================================
--- benchmarks/vmmul.cpp	(revision 218695)
+++ benchmarks/vmmul.cpp	(working copy)
@@ -21,6 +21,7 @@
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
+#include <vsip/random.hpp>
 #include <vsip/core/profile.hpp>
 #include <vsip/opt/diag/eval.hpp>
 
@@ -65,8 +66,10 @@
     Matrix<T>   A(rows, cols, T());
     Matrix<T>   Z(rows, cols);
 
+    Rand<T> rand(0);
+
     W = ramp(T(1), T(1), W.size());
-    A = T(1);
+    A = rand.randu(rows, cols);
     
     vsip::impl::profile::Timer t1;
     
@@ -75,7 +78,18 @@
       Z = vmmul<SD>(W, A);
     t1.stop();
     
-    test_assert(equal(Z(0, 0), T(1)));
+    if (SD == row)
+    {
+      for (index_type r=0; r<rows; ++r)
+	for (index_type c=0; c<cols; ++c)
+	  test_assert(equal(Z.get(r, c), W.get(c) * A.get(r, c)));
+    }
+    else
+    {
+      for (index_type r=0; r<rows; ++r)
+	for (index_type c=0; c<cols; ++c)
+	  test_assert(equal(Z.get(r, c), W.get(r) * A.get(r, c)));
+    }
     
     time = t1.delta();
   }
@@ -315,6 +329,9 @@
   loop.stop_       = 16;
   loop.loop_start_ = 10;
   loop.user_param_ = 256;
+
+  loop.param_["rows"] = "64";
+  loop.param_["cols"] = "2048";
 }
 
 
@@ -322,30 +339,62 @@
 int
 test(Loop1P& loop, int what)
 {
-  length_type p = loop.user_param_;
+  length_type nr = atoi(loop.param_["rows"].c_str());
+  length_type nc = atoi(loop.param_["cols"].c_str());
 
   switch (what)
   {
-  case  1: loop(t_vmmul_fix_rows<complex<float>, Impl_op,    row>(p)); break;
-  case  2: loop(t_vmmul_fix_rows<complex<float>, Impl_pop,   row>(p)); break;
-  case  3: loop(t_vmmul_fix_rows<complex<float>, Impl_s_op,  row>(p)); break;
-  case  4: loop(t_vmmul_fix_rows<complex<float>, Impl_s_pop, row>(p)); break;
+  case  1: loop(t_vmmul_fix_rows<complex<float>, Impl_op,    row>(nr)); break;
+  case  2: loop(t_vmmul_fix_rows<complex<float>, Impl_pop,   row>(nr)); break;
+  case  3: loop(t_vmmul_fix_rows<complex<float>, Impl_s_op,  row>(nr)); break;
+  case  4: loop(t_vmmul_fix_rows<complex<float>, Impl_s_pop, row>(nr)); break;
 
-  case 11: loop(t_vmmul_fix_cols<complex<float>, Impl_op,    row>(p)); break;
-  case 12: loop(t_vmmul_fix_cols<complex<float>, Impl_pop,   row>(p)); break;
-  case 13: loop(t_vmmul_fix_cols<complex<float>, Impl_s_op,  row>(p)); break;
-  case 14: loop(t_vmmul_fix_cols<complex<float>, Impl_s_pop, row>(p)); break;
+  case 11: loop(t_vmmul_fix_cols<complex<float>, Impl_op,    row>(nc)); break;
+  case 12: loop(t_vmmul_fix_cols<complex<float>, Impl_pop,   row>(nc)); break;
+  case 13: loop(t_vmmul_fix_cols<complex<float>, Impl_s_op,  row>(nc)); break;
+  case 14: loop(t_vmmul_fix_cols<complex<float>, Impl_s_pop, row>(nc)); break;
 
-  case 21: loop(t_vmmul_fix_rows<complex<float>, Impl_op,    col>(p)); break;
-  case 22: loop(t_vmmul_fix_rows<complex<float>, Impl_pop,   col>(p)); break;
-  case 23: loop(t_vmmul_fix_rows<complex<float>, Impl_s_op,  col>(p)); break;
-  case 24: loop(t_vmmul_fix_rows<complex<float>, Impl_s_pop, col>(p)); break;
+  case 21: loop(t_vmmul_fix_rows<complex<float>, Impl_op,    col>(nr)); break;
+  case 22: loop(t_vmmul_fix_rows<complex<float>, Impl_pop,   col>(nr)); break;
+  case 23: loop(t_vmmul_fix_rows<complex<float>, Impl_s_op,  col>(nr)); break;
+  case 24: loop(t_vmmul_fix_rows<complex<float>, Impl_s_pop, col>(nr)); break;
 
-  case 31: loop(t_vmmul_fix_cols<complex<float>, Impl_op,    col>(p)); break;
-  case 32: loop(t_vmmul_fix_cols<complex<float>, Impl_pop,   col>(p)); break;
-  case 33: loop(t_vmmul_fix_cols<complex<float>, Impl_s_op,  col>(p)); break;
-  case 34: loop(t_vmmul_fix_cols<complex<float>, Impl_s_pop, col>(p)); break;
+  case 31: loop(t_vmmul_fix_cols<complex<float>, Impl_op,    col>(nc)); break;
+  case 32: loop(t_vmmul_fix_cols<complex<float>, Impl_pop,   col>(nc)); break;
+  case 33: loop(t_vmmul_fix_cols<complex<float>, Impl_s_op,  col>(nc)); break;
+  case 34: loop(t_vmmul_fix_cols<complex<float>, Impl_s_pop, col>(nc)); break;
 
+  case 0:
+    std::cout
+      << "vmmul -- vector-matrix multiply\n"
+      << " Sweeping column size, row major:\n"
+      << "   -1 -- Out-of-place, complex\n"
+      << "   -2 -- Out-of-place, complex, using vmul\n"
+      << "   -3 -- Out-of-place, complex, scaled\n"
+      << "   -4 -- Out-of-place, complex, scaled, using vmul\n"
+      << " Sweeping row size, row major:\n"
+      << "  -11 -- Out-of-place, complex\n"
+      << "  -12 -- Out-of-place, complex, using vmul\n"
+      << "  -13 -- Out-of-place, complex, scaled\n"
+      << "  -14 -- Out-of-place, complex, scaled, using vmul\n"
+      << " Sweeping column size, column major:\n"
+      << "  -21 -- Out-of-place, complex\n"
+      << "  -22 -- Out-of-place, complex, using vmul\n"
+      << "  -23 -- Out-of-place, complex, scaled\n"
+      << "  -24 -- Out-of-place, complex, scaled, using vmul\n"
+      << " Sweeping row size, column major:\n"
+      << "  -31 -- Out-of-place, complex\n"
+      << "  -32 -- Out-of-place, complex, using vmul\n"
+      << "  -33 -- Out-of-place, complex, scaled\n"
+      << "  -34 -- Out-of-place, complex, scaled, using vmul\n"
+      << "\n"
+      << " Parameters (for sweeping number of columns, cases 1-4, 21-24)\n"
+      << "  -p:rows ROWS -- set number of rows (default 64)\n"
+      << "\n"
+      << " Parameters (for sweeping number of columns, cases 11-14, 31-34)\n"
+      << "  -p:cols COLS -- set number of columns (default 2048)\n"
+      ;
+
   default: return 0;
   }
   return 1;
Index: benchmarks/GNUmakefile.inc.in
===================================================================
--- benchmarks/GNUmakefile.inc.in	(revision 218695)
+++ benchmarks/GNUmakefile.inc.in	(working copy)
@@ -68,7 +68,13 @@
                                %.static$(EXEEXT), \
                                $(benchmarks_targets))
 
+benchmarks_prof_obj := $(patsubst $(srcdir)/%.cpp, %.prof.$(OBJEXT), $(benchmarks_cxx_sources))
 
+benchmarks_prof_targets := $(patsubst %$(EXEEXT), \
+                               %.prof$(EXEEXT), \
+                               $(benchmarks_targets))
+
+
 ########################################################################
 # Rules
 ########################################################################
@@ -110,4 +116,10 @@
 $(benchmarks_static_targets): %.static$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
 	$(CXX) -static $(LDFLAGS) -o $@ $^ -Llib -lsvpp $(LIBS) || rm -f $@
 
+$(benchmarks_prof_obj): %.prof.$(OBJEXT): %.cpp
+	$(CXX) -c $(CXXFLAGS) $(call dir_var,$(dir $<),CXXFLAGS) -DVSIP_IMPL_PROFILER=15 -o $@ $<
+
+$(benchmarks_prof_targets): %.prof$(EXEEXT) : %.prof.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
+	$(link_app)
+
 endif # VSIP_IMPL_REF_IMPL
