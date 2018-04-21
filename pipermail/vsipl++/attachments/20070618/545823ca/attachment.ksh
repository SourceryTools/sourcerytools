Index: ChangeLog
===================================================================
--- ChangeLog	(revision 174264)
+++ ChangeLog	(working copy)
@@ -1,3 +1,18 @@
+2007-06-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/expr/scalar_block.hpp (Scalar_block_base): Add
+	  copy constructor when compiling with GCC 3.x.  Work around
+	  apparant inlining/optimization bug.
+	* tests/coverage_common.hpp: Add optional verbose debug output.
+	* tests/ea_from_ptr.cpp: Only test vsip::impl::cbe when CBE
+	  support is actually installed.
+	
+	* benchmarks/hpec_kernel/GNUmakefile.inc.in (install-benchmarks):
+	  Rename rule from install.
+	* benchmarks/GNUmakefile.inc.in (install-benchmarks): Likewise.
+	* scripts/package.py: Install benchmarks using 'install-benchmarks'
+	  rule.
+
 2007-06-17  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/fftw3/fft_impl.cpp: Respect aligned when planning for
Index: src/vsip/core/expr/scalar_block.hpp
===================================================================
--- src/vsip/core/expr/scalar_block.hpp	(revision 173875)
+++ src/vsip/core/expr/scalar_block.hpp	(working copy)
@@ -57,6 +57,12 @@
   static dimension_type const dim = D;
 
   Scalar_block_base(Scalar s) : value_(s) {}
+#if (defined(__GNUC__) && __GNUC__ < 4)
+  // GCC 3.4.4 appears to over-optimize multiple scalar values on
+  // stack when optimization & strong inlining are enabled, causing
+  // threshold.cpp and other tests to fail.  (070618)
+  Scalar_block_base(Scalar_block_base const& b) : value_(b.value_) {}
+#endif
 
   void increment_count() const VSIP_NOTHROW {}
   void decrement_count() const VSIP_NOTHROW {}
Index: tests/coverage_common.hpp
===================================================================
--- tests/coverage_common.hpp	(revision 173875)
+++ tests/coverage_common.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -17,6 +17,11 @@
   Included Files
 ***********************************************************************/
 
+#if VERBOSE
+#  include <iostream>
+#  include <vsip/opt/diag/eval.hpp>
+#endif
+
 #include <vsip/support.hpp>
 #include <vsip/complex.hpp>
 #include <vsip/random.hpp>
@@ -40,6 +45,8 @@
 {
   static T at(vsip::index_type arg, vsip::index_type i, range_type rt=anyval)
   {
+    if (i == 0) return T(arg+3);
+
     // return T((2+arg)*i + (1+arg));
     vsip::Rand<T> rand(5*i + arg);
     T value =  rand.randu();
@@ -213,7 +220,8 @@
   Ternary Operator Tests
 ***********************************************************************/
 
-#define TEST_TERNARY(NAME, FCN, OP1, OP2, CHKOP1, CHKOP2)		\
+#if VERBOSE
+#  define TEST_TERNARY(NAME, FCN, OP1, OP2, CHKOP1, CHKOP2)		\
 struct Test_##NAME							\
 {									\
   template <typename View1,						\
@@ -252,6 +260,26 @@
 	(       Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)	\
 	 CHKOP1 Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i))	\
 	 CHKOP2 Get_value<T3>::at(2, Is_scalar<View3>::value ? 0 : i);	\
+      if (!equal(get_nth(view4, i), expected))				\
+      {									\
+	std::cout							\
+	  << "TEST_TERNARY FCN FAILURE\n"				\
+	  << "  i       : " << i << "\n"				\
+	  << "  at(0, i): "						\
+	  << Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)	\
+	  << "\n"							\
+	  << "  at(1, i): "						\
+	  << Get_value<T1>::at(1, Is_scalar<View1>::value ? 0 : i)	\
+	  << "\n"							\
+	  << "  at(2, i): "						\
+	  << Get_value<T1>::at(2, Is_scalar<View1>::value ? 0 : i)	\
+	  << "\n"							\
+	  << "  result: " << get_nth(view4, i) << "\n"			\
+	  << "  expected: " << expected << "\n"				\
+	  ;								\
+	/* vsip::impl::diagnose_eval_list_std(view4,			\
+	   FCN(view1, view2, view3)); */				\
+      }									\
       test_assert(equal(get_nth(view4, i), expected));			\
     }									\
     									\
@@ -264,10 +292,87 @@
 	(       Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)	\
 	 CHKOP1 Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i))	\
 	 CHKOP2 Get_value<T3>::at(2, Is_scalar<View3>::value ? 0 : i);	\
+      if (!equal(get_nth(view4, i), expected) || i == 0)		\
+      {									\
+	std::cout							\
+	  << "TEST_TERNARY OP1/OP2 FAILURE\n"				\
+	  << "  i       : " << i << "\n"				\
+	  << "  at(0, i): "						\
+	  << Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)	\
+	  << "\n"							\
+	  << "  at(1, i): "						\
+	  << Get_value<T1>::at(1, Is_scalar<View1>::value ? 0 : i)	\
+	  << "\n"							\
+	  << "  at(2, i): "						\
+	  << Get_value<T1>::at(2, Is_scalar<View1>::value ? 0 : i)	\
+	  << "\n"							\
+	  << "  result: " << get_nth(view4, i) << "\n"			\
+	  << "  expected: " << expected << "\n"				\
+	  ;								\
+	/* vsip::impl::diagnose_eval_list_std(view4,			\
+	   (view1 OP1 view2) OP2 view3); */ 				\
+      }									\
       test_assert(equal(get_nth(view4, i), expected));			\
     }									\
   }									\
 };
+#else
+#  define TEST_TERNARY(NAME, FCN, OP1, OP2, CHKOP1, CHKOP2)		\
+struct Test_##NAME							\
+{									\
+  template <typename View1,						\
+	    typename View2,						\
+	    typename View3,						\
+	    typename View4>						\
+  static void								\
+  exec(									\
+    View1 view1,							\
+    View2 view2,							\
+    View3 view3,							\
+    View4 view4)	/* Result */					\
+  {									\
+    length_type size = get_size(view4);					\
+    test_assert(Is_scalar<View1>::value || get_size(view1) == size);	\
+    test_assert(Is_scalar<View2>::value || get_size(view2) == size);	\
+    test_assert(Is_scalar<View3>::value || get_size(view3) == size);	\
+    									\
+    typedef typename Value_type_of<View1>::type T1;			\
+    typedef typename Value_type_of<View2>::type T2;			\
+    typedef typename Value_type_of<View3>::type T3;			\
+    typedef typename Value_type_of<View4>::type T4;			\
+									\
+    for (index_type i=0; i<get_size(view1); ++i)			\
+      put_nth(view1, i, Get_value<T1>::at(0, i));			\
+    for (index_type i=0; i<get_size(view2); ++i)			\
+      put_nth(view2, i, Get_value<T2>::at(1, i));			\
+    for (index_type i=0; i<get_size(view3); ++i)			\
+      put_nth(view3, i, Get_value<T2>::at(2, i));			\
+    									\
+    view4 = FCN(view1, view2, view3);					\
+    									\
+    for (index_type i=0; i<get_size(view4); ++i)			\
+    {									\
+      T4 expected =							\
+	(       Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)	\
+	 CHKOP1 Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i))	\
+	 CHKOP2 Get_value<T3>::at(2, Is_scalar<View3>::value ? 0 : i);	\
+      test_assert(equal(get_nth(view4, i), expected));			\
+    }									\
+    									\
+    view4 = T4();							\
+    view4 = (view1 OP1 view2) OP2 view3;				\
+    									\
+    for (index_type i=0; i<get_size(view4); ++i)			\
+    {									\
+      T4 expected =							\
+	(       Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i)	\
+	 CHKOP1 Get_value<T2>::at(1, Is_scalar<View2>::value ? 0 : i))	\
+	 CHKOP2 Get_value<T3>::at(2, Is_scalar<View3>::value ? 0 : i);	\
+      test_assert(equal(get_nth(view4, i), expected));			\
+    }									\
+  }									\
+};
+#endif
 
 
 
Index: tests/ea_from_ptr.cpp
===================================================================
--- tests/ea_from_ptr.cpp	(revision 173072)
+++ tests/ea_from_ptr.cpp	(working copy)
@@ -11,7 +11,9 @@
 ***********************************************************************/
 
 #include <vsip/initfin.hpp>
-#include <vsip/opt/cbe/ppu/util.hpp>
+#if VSIP_IMPL_HAVE_CBE_SDK
+#  include <vsip/opt/cbe/ppu/util.hpp>
+#endif // VSIP_IMPL_HAVE_CBE_SDK
 
 #include <vsip_csl/test.hpp>
 
@@ -43,11 +45,16 @@
 void
 test_conv(char* ptr, unsigned long long expected_ea)
 {
+#if VSIP_IMPL_HAVE_CBE_SDK
   unsigned long long ea;
 
   ea = vsip::impl::cbe::ea_from_ptr(ptr);
 
   test_assert(ea == expected_ea);
+#else
+  (void)ptr;
+  (void)expected_ea;
+#endif // VSIP_IMPL_HAVE_CBE_SDK
 }
 
 
Index: benchmarks/hpec_kernel/GNUmakefile.inc.in
===================================================================
--- benchmarks/hpec_kernel/GNUmakefile.inc.in	(revision 173215)
+++ benchmarks/hpec_kernel/GNUmakefile.inc.in	(working copy)
@@ -50,7 +50,7 @@
 	rm -f $(hpec_targets)
 
 # Install benchmark source code and executables
-install:: hpec_kernel
+install-benchmarks:: hpec_kernel
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/hpec_kernel
 	for sourcefile in $(hpec_install_targets); do \
Index: benchmarks/GNUmakefile.inc.in
===================================================================
--- benchmarks/GNUmakefile.inc.in	(revision 173215)
+++ benchmarks/GNUmakefile.inc.in	(working copy)
@@ -80,7 +80,7 @@
 	rm -f $(benchmarks_targets) $(benchmarks_static_targets)
 
 # Install benchmark source code and executables
-install:: benchmarks
+install-benchmarks:: benchmarks
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/lapack
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/ipp
Index: scripts/package.py
===================================================================
--- scripts/package.py	(revision 173072)
+++ scripts/package.py	(working copy)
@@ -220,6 +220,7 @@
                     '--with-builtin-libdir=\${prefix}/lib/%s'%(builtin_libdir),
                     c)
             spawn(['sh', '-c', 'make install DESTDIR=%s'%abs_distdir])
+            spawn(['sh', '-c', 'make install-benchmarks DESTDIR=%s'%abs_distdir])
 
             # Make copy of acconfig for later perusal.
             spawn(['sh', '-c', 'cp %s/%s/include/vsip/core/acconfig.hpp ../acconfig%s%s.hpp'%(abs_distdir,prefix,suffix,s)])
