Index: configure.ac
===================================================================
--- configure.ac	(revision 152549)
+++ configure.ac	(working copy)
@@ -374,6 +374,18 @@
   [with_qmtest="qmtest"]) 
 
 AC_SUBST(QMTEST, $with_qmtest)
+
+AC_ARG_WITH(qmtest-command,
+  AS_HELP_STRING([--with-qmtest-command=PROXY],
+                 [Provide the proxy command for QMTest to run test with.]),
+  ,
+  [with_qmtest_command=""]) 
+
+if test "x$with_qmtest_command" = "x"; then
+  AC_SUBST(QMTEST_TARGET, "local_host.LocalHost")
+else
+  AC_SUBST(QMTEST_TARGET, "command_host.CommandHost(command=\"$with_qmtest_command\")")
+fi
  
 AC_ARG_ENABLE(scripting,
   [  --enable-scripting         Specify whether or not to build the python bindings.],,
@@ -815,10 +827,10 @@
     fftw3_d_simd=
     fftw3_l_simd=
     case "$host_cpu" in
-      (ia32|i686|x86_64) fftw3_f_simd="--enable-sse"
+      ia32|i686|x86_64) fftw3_f_simd="--enable-sse"
 	                 fftw3_d_simd="--enable-sse2" 
 	                 ;;
-      (ppc*)             fftw3_f_simd="--enable-altivec" ;;
+      ppc*)             fftw3_f_simd="--enable-altivec" ;;
     esac
     AC_MSG_NOTICE([fftw3 config options: $fftw3_opts $fftw3_simd.])
 
Index: vsipl++.pc.in
===================================================================
--- vsipl++.pc.in	(revision 152549)
+++ vsipl++.pc.in	(working copy)
@@ -7,6 +7,7 @@
 cxxflags=@CXXFLAGS@
 ldflags=@LDFLAGS@
 par_service=@PAR_SERVICE@
+qmtest_target=@QMTEST_TARGET@
 svpp_library=@svpp_library@
 
 Name: Sourcery VSIPL++
Index: tests/context-installed.pre.in
===================================================================
--- tests/context-installed.pre.in	(revision 152549)
+++ tests/context-installed.pre.in	(working copy)
@@ -1,6 +1,6 @@
 CompilationTest.compiler_path=@CXX_@
 CompilationTest.compiler_options= -I@abs_top_srcdir@/tests @CPPFLAGS_@ @CXXFLAGS_@
 CompilationTest.compiler_ldflags= @LIBS_@
-CompilationTest.target=local_host.LocalHost
-ExecutableTest.host=local_host.LocalHost
+CompilationTest.target=@QMTEST_TARGET_@
+ExecutableTest.host=@QMTEST_TARGET_@
 par_service=@PAR_SERVICE_@
Index: tests/context.in
===================================================================
--- tests/context.in	(revision 152549)
+++ tests/context.in	(working copy)
@@ -1,6 +1,6 @@
 CompilationTest.compiler_path=@CXX@
 CompilationTest.compiler_options= -I@abs_top_srcdir@/tests -I@abs_top_builddir@/src -I@abs_top_srcdir@/src @INT_CPPFLAGS@ @CPPFLAGS@ @CXXFLAGS@
 CompilationTest.compiler_ldflags= @INT_LDFLAGS@ @LDFLAGS@ -L@abs_top_builddir@/lib/ -lvsip_csl -l@svpp_library@ @LIBS@
-CompilationTest.target=local_host.LocalHost
-ExecutableTest.host=local_host.LocalHost
+CompilationTest.target=@QMTEST_TARGET@
+ExecutableTest.host=@QMTEST_TARGET@
 par_service=@PAR_SERVICE@
Index: tests/GNUmakefile.inc.in
===================================================================
--- tests/GNUmakefile.inc.in	(revision 152549)
+++ tests/GNUmakefile.inc.in	(working copy)
@@ -49,6 +49,7 @@
 	  sed -e "s|@CPPFLAGS_@|`$(tests_pkgconfig) --variable=cppflags`|" | \
           sed -e "s|@CXXFLAGS_@|`$(tests_pkgconfig) --variable=cxxflags`|" | \
           sed -e "s|@LIBS_@|`$(tests_pkgconfig) --libs`|" | \
+          sed -e "s|@QMTEST_TARGET_@|`$(tests_pkgconfig) --variable=qmtest_target`|" | \
           sed -e "s|@PAR_SERVICE_@|`$(tests_pkgconfig) --variable=par_service`|" \
           > tests/context-installed
 	cd tests; \
