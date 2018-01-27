Index: ChangeLog
===================================================================
--- ChangeLog	(revision 161125)
+++ ChangeLog	(working copy)
@@ -1,3 +1,20 @@
+2007-01-25  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/parallel.hpp: Guard inclusion of opt/parallel/foreach
+	  when building ref-impl.
+	* src/vsip_csl/GNUmakefile.inc.in: Guard makefile when building
+	  ref-impl.
+	* benchmarks/hpec_kernel/GNUmakefile.inc.in: Likewise.
+	* benchmarks/GNUmakefile.inc.in: Likewise.
+	
+	* configure.ac (VSIP_CSL_LIB): New AC_SUBST to indicate whether
+	  vsip_csl.a is present.
+	* vsipl++.pc.in: Use VSIP_CSL_LIB.
+	* tests/context.in: Likewise.
+	
+	* benchmarks/benchmarks.hpp: Don't include opt/parallel/foreach.
+	  directly.
+	
 2007-01-24  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/opt/cbe/ppu/alf.hpp: Made correction for data buffer size
Index: src/vsip/parallel.hpp
===================================================================
--- src/vsip/parallel.hpp	(revision 161125)
+++ src/vsip/parallel.hpp	(working copy)
@@ -20,7 +20,9 @@
 #include <vsip/core/working_view.hpp>
 #include <vsip/core/parallel/support.hpp>
 #include <vsip/core/parallel/util.hpp>
-#include <vsip/opt/parallel/foreach.hpp>
+#ifndef VSIP_IMPL_REF_IMPL
+#  include <vsip/opt/parallel/foreach.hpp>
+#endif
 
 
 
Index: src/vsip_csl/GNUmakefile.inc.in
===================================================================
--- src/vsip_csl/GNUmakefile.inc.in	(revision 161125)
+++ src/vsip_csl/GNUmakefile.inc.in	(working copy)
@@ -8,6 +8,11 @@
 #
 ########################################################################
 
+# Files in this directory are not available under the BSD license, so
+# avoid putting them into cxx_sources, building them, installing them,
+# etc. when building the reference implementation.
+ifndef VSIP_IMPL_REF_IMPL
+
 ########################################################################
 # Variables
 ########################################################################
@@ -40,7 +45,6 @@
 lib/libvsip_csl.$(LIBEXT): $(src_vsip_csl_cxx_objects)
 	$(archive)
 
-ifndef VSIP_IMPL_REF_IMPL
 # Install the extensions library and its header files.
 install:: lib/libvsip_csl.$(LIBEXT)
 	$(INSTALL) -d $(DESTDIR)$(libdir)
@@ -50,4 +54,5 @@
 	for header in $(wildcard $(srcdir)/src/vsip_csl/*.hpp); do \
           $(INSTALL_DATA) $$header $(DESTDIR)$(includedir)/vsip_csl; \
 	done
+
 endif
Index: configure.ac
===================================================================
--- configure.ac	(revision 161125)
+++ configure.ac	(working copy)
@@ -85,10 +85,25 @@
      esac],
     [ref_impl=0]) 
 
+# VSIP_IMPL_REF_IMPL is defined to 1 when building the reference
+# implementation.  The reference implementation uses only the core
+# of the library and the C-VSIP backends, all of which are available
+# under GPL.  The reference implementation does not use the opt
+# parts of the library, which are only available under GPL and
+# commercial license.
+
+# VSIP_CSL_LIB is an AC_SUBST used by the pkg-config vsipl++.pc and
+# QMtest context files to determine if they should link against the
+# vsip_csl library.  The vsip_csl library is not built with the
+# reference implementation.
+
 if test "$ref_impl" = "1"; then
   AC_DEFINE_UNQUOTED(VSIP_IMPL_REF_IMPL, 1,
         [Set to 1 to compile the reference implementation.])
   AC_SUBST(VSIP_IMPL_REF_IMPL, 1)
+  AC_SUBST(VSIP_CSL_LIB, "")
+else
+  AC_SUBST(VSIP_CSL_LIB, "-lvsip_csl")
 fi
 
 AC_ARG_ENABLE([exceptions],
Index: vsipl++.pc.in
===================================================================
--- vsipl++.pc.in	(revision 161125)
+++ vsipl++.pc.in	(working copy)
@@ -13,5 +13,5 @@
 Name: Sourcery VSIPL++
 Description: CodeSourcery VSIPL++ library
 Version: @PACKAGE_VERSION@
-Libs: ${ldflags} -L${libdir} -lvsip_csl -l${svpp_library}@suffix_@ @LIBS@
+Libs: ${ldflags} -L${libdir} @VSIP_CSL_LIB@ -l${svpp_library}@suffix_@ @LIBS@
 Cflags: ${cppflags}
Index: benchmarks/GNUmakefile.inc.in
===================================================================
--- benchmarks/GNUmakefile.inc.in	(revision 161125)
+++ benchmarks/GNUmakefile.inc.in	(working copy)
@@ -8,6 +8,11 @@
 #
 ########################################################################
 
+# Files in this directory are not available under the BSD license, so
+# avoid putting them into cxx_sources, building them, installing them,
+# etc. when building the reference implementation.
+ifndef VSIP_IMPL_REF_IMPL
+
 ########################################################################
 # Variables
 ########################################################################
@@ -55,3 +60,5 @@
 
 $(benchmarks_static_targets): %.static$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
 	$(CXX) -static $(LDFLAGS) -o $@ $^ -Llib -l$(SVPP_LIBRARY) $(LIBS) || rm -f $@
+
+endif # VSIP_IMPL_REF_IMPL
Index: benchmarks/hpec_kernel/GNUmakefile.inc.in
===================================================================
--- benchmarks/hpec_kernel/GNUmakefile.inc.in	(revision 161125)
+++ benchmarks/hpec_kernel/GNUmakefile.inc.in	(working copy)
@@ -8,6 +8,11 @@
 #
 ########################################################################
 
+# Files in this directory are not available under the BSD license, so
+# avoid putting them into cxx_sources, building them, installing them,
+# etc. when building the reference implementation.
+ifndef VSIP_IMPL_REF_IMPL
+
 ########################################################################
 # Variables
 ########################################################################
@@ -41,3 +46,5 @@
 $(hpec_cxx_exes_def_build): %$(EXEEXT) : \
   %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
 	$(CXX) $(LDFLAGS) -o $@ $^ -Llib -l$(SVPP_LIBRARY) $(LIBS) || rm -f $@
+
+endif
Index: benchmarks/benchmarks.hpp
===================================================================
--- benchmarks/benchmarks.hpp	(revision 161125)
+++ benchmarks/benchmarks.hpp	(working copy)
@@ -21,7 +21,6 @@
 // Sourcery VSIPL++ provides certain resources such as system 
 // timers that are needed for running the benchmarks.
 
-#include <vsip/opt/parallel/foreach.hpp>
 #include <vsip/core/profile.hpp>
 #include <vsip_csl/load_view.hpp>
 #include <vsip_csl/test.hpp>
Index: tests/context.in
===================================================================
--- tests/context.in	(revision 161125)
+++ tests/context.in	(working copy)
@@ -1,6 +1,6 @@
 CompilationTest.compiler_path=@CXX@
 CompilationTest.compiler_options= -I@abs_top_srcdir@/tests -I@abs_top_builddir@/src -I@abs_top_srcdir@/src @INT_CPPFLAGS@ @CPPFLAGS@ @CXXFLAGS@
-CompilationTest.compiler_ldflags= @INT_LDFLAGS@ @LDFLAGS@ -L@abs_top_builddir@/lib/ -lvsip_csl -l@svpp_library@ @LIBS@
+CompilationTest.compiler_ldflags= @INT_LDFLAGS@ @LDFLAGS@ -L@abs_top_builddir@/lib/ @VSIP_CSL_LIB@ -l@svpp_library@ @LIBS@
 CompilationTest.target=@QMTEST_TARGET@
 ExecutableTest.host=@QMTEST_TARGET@
 par_service=@PAR_SERVICE@
