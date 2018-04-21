Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 147489)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -39,26 +39,26 @@
 src_vsip_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(src_vsip_cxx_sources))
 cxx_sources += $(src_vsip_cxx_sources)
 
-libs += lib/libvsip.a
+libs += lib/lib$(SVPP_LIBRARY).a
 ########################################################################
 # Rules
 ########################################################################
 
-all:: lib/libvsip.a
+all:: lib/lib$(SVPP_LIBRARY).a
 
 clean::
-	rm -f lib/libvsip.a
+	rm -f lib/lib$(SVPP_LIBRARY).a
 
-lib/libvsip.a: $(src_vsip_cxx_objects)
+lib/lib$(SVPP_LIBRARY).a: $(src_vsip_cxx_objects)
 	$(AR) rc $@ $^ || rm -f $@
 
 # Install the library and its header files.  When building with
 # separate $objdir, acconfig.hpp will be generated in the $objdir, so it
 # must be copied explicitly.  By copying it last, we override any
 # stale copy in the $srcdir.
-install:: lib/libvsip.a
+install:: lib/lib$(SVPP_LIBRARY).a
 	$(INSTALL) -d $(DESTDIR)$(libdir)
-	$(INSTALL_DATA) lib/libvsip.a $(DESTDIR)$(libdir)/libvsip$(suffix).a
+	$(INSTALL_DATA) lib/lib$(SVPP_LIBRARY).a $(DESTDIR)$(libdir)/lib$(SVPP_LIBRARY)$(suffix).a
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/simd
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/impl/fft
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 147594)
+++ ChangeLog	(working copy)
@@ -1,5 +1,18 @@
 2006-08-24  Jules Bergmann  <jules@codesourcery.com>
 
+	* configure.ac: New AC_SUBST for svpp_library: root name
+	  of VSIPL++ library.
+	* GNUmakefile.in: Define SVPP_LIBRARY from svpp_library AC_SUBST.
+	* src/vsip/GNUmakefile.inc.in: Use SVPP_LIBRARY variable.
+	* tests/GNUmakefile.inc.in: Likewise.
+	* benchmarks/hpec_kernel/GNUmakefile.inc.in: Likewise.
+	* benchmarks/GNUmakefile.inc.in: Likewise.
+	* examples/GNUmakefile.inc.in: Likewise.
+	* vsipl++.pc.in: use svpp_library AC_SUBST.
+	* tests/context.in: Likewise.
+
+2006-08-24  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/parallel.hpp: Include par-foreach.
 	* src/vsip/impl/expr_serial_dispatch.hpp: Add missing include.
 	* doc/tutorial/parallel.xml: Apply Mark's 7/31 edits.
Index: vsipl++.pc.in
===================================================================
--- vsipl++.pc.in	(revision 147489)
+++ vsipl++.pc.in	(working copy)
@@ -7,9 +7,10 @@
 cxxflags=@CXXFLAGS@
 ldflags=@LDFLAGS@
 par_service=@PAR_SERVICE@
+svpp_library=@svpp_library@
 
 Name: Sourcery VSIPL++
 Description: CodeSourcery VSIPL++ library
 Version: @PACKAGE_VERSION@
-Libs: ${ldflags} -L${libdir} -lvsip@suffix_@ @LIBS@
+Libs: ${ldflags} -L${libdir} -l${svpp_library}@suffix_@ @LIBS@
 Cflags: ${cppflags}
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 147489)
+++ GNUmakefile.in	(working copy)
@@ -68,6 +68,10 @@
 suffix := @suffix@
 packagesuffix :=
 
+### Library ###
+
+SVPP_LIBRARY := @svpp_library@
+
 ### Compilation ###
 
 # The path to the archiver. 
Index: tests/context.in
===================================================================
--- tests/context.in	(revision 147489)
+++ tests/context.in	(working copy)
@@ -1,6 +1,6 @@
 CompilationTest.compiler_path=@CXX@
 CompilationTest.compiler_options= -I@abs_top_srcdir@/tests -I@abs_top_builddir@/src -I@abs_top_srcdir@/src @INT_CPPFLAGS@ @CPPFLAGS@ @CXXFLAGS@
-CompilationTest.compiler_ldflags= @INT_LDFLAGS@ @LDFLAGS@ -L@abs_top_builddir@/lib/ -lvsip @LIBS@
+CompilationTest.compiler_ldflags= @INT_LDFLAGS@ @LDFLAGS@ -L@abs_top_builddir@/lib/ -l@svpp_library@ @LIBS@
 CompilationTest.target=local_host.LocalHost
 ExecutableTest.host=local_host.LocalHost
 par_service=@PAR_SERVICE@
Index: tests/GNUmakefile.inc.in
===================================================================
--- tests/GNUmakefile.inc.in	(revision 147489)
+++ tests/GNUmakefile.inc.in	(working copy)
@@ -37,7 +37,7 @@
 ########################################################################
 
 $(tests_cxx_exes): %$(EXEEXT): %.$(OBJEXT) $(libs)
-	$(CXX) $(LDFLAGS) -o $@ $< -Llib -lvsip $(LIBS)
+	$(CXX) $(LDFLAGS) -o $@ $< -Llib -l$(SVPP_LIBRARY) $(LIBS)
 
 check::	$(libs) $(tests_qmtest_extensions)
 	cd tests; qmtest run $(tests_run_ident) $(tests_ids); \
Index: configure.ac
===================================================================
--- configure.ac	(revision 147489)
+++ configure.ac	(working copy)
@@ -43,6 +43,7 @@
                   Typical suffixes are '-opt' or '-debug'.]),
   [suffix=$withval])
 AC_SUBST(suffix)
+AC_SUBST(svpp_library, "svpp")
 
 ### Filename extensions. 
 AC_ARG_WITH(obj_ext,
Index: benchmarks/hpec_kernel/GNUmakefile.inc.in
===================================================================
--- benchmarks/hpec_kernel/GNUmakefile.inc.in	(revision 147489)
+++ benchmarks/hpec_kernel/GNUmakefile.inc.in	(working copy)
@@ -40,4 +40,4 @@
 
 $(hpec_cxx_exes_def_build): %$(EXEEXT) : \
   %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
-	$(CXX) $(LDFLAGS) -o $@ $^ -Llib -lvsip $(LIBS) || rm -f $@
+	$(CXX) $(LDFLAGS) -o $@ $^ -Llib -l$(SVPP_LIBRARY) $(LIBS) || rm -f $@
Index: benchmarks/GNUmakefile.inc.in
===================================================================
--- benchmarks/GNUmakefile.inc.in	(revision 147489)
+++ benchmarks/GNUmakefile.inc.in	(working copy)
@@ -90,7 +90,7 @@
 	rm -f $(benchmarks_cxx_exes)
 
 $(benchmarks_cxx_exes_def_build): %$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
-	$(CXX) $(LDFLAGS) -o $@ $^ -Llib -lvsip $(LIBS) || rm -f $@
+	$(CXX) $(LDFLAGS) -o $@ $^ -Llib -l$(SVPP_LIBRARY) $(LIBS) || rm -f $@
 
 $(benchmarks_cxx_statics_def_build): %.static$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
-	$(CXX) -static $(LDFLAGS) -o $@ $^ -Llib -lvsip $(LIBS) || rm -f $@
+	$(CXX) -static $(LDFLAGS) -o $@ $^ -Llib -l$(SVPP_LIBRARY) $(LIBS) || rm -f $@
Index: examples/GNUmakefile.inc.in
===================================================================
--- examples/GNUmakefile.inc.in	(revision 147489)
+++ examples/GNUmakefile.inc.in	(working copy)
@@ -45,5 +45,5 @@
 	  $(DESTDIR)$(pkgdatadir)/Makefile
 
 $(examples_cxx_exes): %$(EXEEXT): %.$(OBJEXT) $(libs)
-	$(CXX) $(LDFLAGS) -o $@ $< -Llib -lvsip $(LIBS)
+	$(CXX) $(LDFLAGS) -o $@ $< -Llib -l$(SVPP_LIBRARY) $(LIBS)
 
