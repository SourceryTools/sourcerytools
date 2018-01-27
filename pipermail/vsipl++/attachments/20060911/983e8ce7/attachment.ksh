Index: ChangeLog
===================================================================
--- ChangeLog	(revision 148934)
+++ ChangeLog	(working copy)
@@ -1,3 +1,10 @@
+2006-09-11  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Fix handling of 'mpicxx -show'; add --with-qmtest.
+	* GNUmakefile.in: Define QMTEST variable.
+	* tests/GNUmakefile.inc.in: Use it.
+	* src/vsip/impl/fns_elementwise.hpp: Fix for icl.
+
 2006-09-07  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* src/vsip/support.hpp: Define VSIP_HAS_EXCEPTIONS appropriately when
Index: src/vsip/impl/fns_elementwise.hpp
===================================================================
--- src/vsip/impl/fns_elementwise.hpp	(revision 148934)
+++ src/vsip/impl/fns_elementwise.hpp	(working copy)
@@ -170,7 +170,7 @@
 { return Dispatch_op_##fname<LView<T1, Block1>,                           \
                              RView<T2, Block2> >::apply(t1, t2);}
 
-#if (defined(__GNUC__) && __GNUC__ < 4) || defined(__ghs__)
+#if (defined(__GNUC__) && __GNUC__ < 4) || defined(__ghs__) || defined(__ICL)
 # define VSIP_IMPL_BINARY_OPERATOR(op, fname)                             \
 VSIP_IMPL_BINARY_OPERATOR_ONE(op, fname)
 #else
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 148934)
+++ GNUmakefile.in	(working copy)
@@ -100,6 +100,8 @@
 OBJEXT := @OBJEXT@
 # The extension for archives.
 LIBEXT := @LIBEXT@
+# The QMTest command to use for testing.
+QMTEST := @QMTEST@
 
 ### Parallelization ###
 
Index: tests/GNUmakefile.inc.in
===================================================================
--- tests/GNUmakefile.inc.in	(revision 148934)
+++ tests/GNUmakefile.inc.in	(working copy)
@@ -37,10 +37,10 @@
 ########################################################################
 
 $(tests_cxx_exes): %$(EXEEXT): %.$(OBJEXT) $(libs)
-	$(CXX) $(LDFLAGS) -o $@ $< -Llib -l$(SVPP_LIBRARY) $(LIBS)
+	$(link_app)
 
 check::	$(libs) $(tests_qmtest_extensions)
-	cd tests; qmtest run $(tests_run_ident) $(tests_ids); \
+	cd tests; $(QMTEST) run $(tests_run_ident) $(tests_ids); \
           result=$$?; test $$tmp=0 || $$tmp=2
 
 installcheck:: $(tests_qmtest_extensions)
@@ -52,7 +52,7 @@
           sed -e "s|@PAR_SERVICE_@|`$(tests_pkgconfig) --variable=par_service`|" \
           > tests/context-installed
 	cd tests; \
-          qmtest run -C context-installed $(tests_run_ident) \
+          $(QMTEST) run -C context-installed $(tests_run_ident) \
             -o results$(suffix).qmr $(tests_ids); \
           result=$$?; test $$tmp=0 || $$tmp=2
 
Index: configure.ac
===================================================================
--- configure.ac	(revision 148934)
+++ configure.ac	(working copy)
@@ -311,6 +311,13 @@
       [Set 1 to enable eval_dense_expr evaluator, set 0 to disable.])
 
 
+AC_ARG_WITH(qmtest,
+  AS_HELP_STRING([--with-qmtest=QMTEST], [Provide the command to run QMTest.]),
+  ,
+  [with_qmtest="qmtest"]) 
+
+AC_SUBST(QMTEST, $with_qmtest)
+ 
 #
 # Put libs directory int INT_LDFLAGS:
 #
@@ -940,12 +947,11 @@
     esac
 
     if test "$check_mpicxx" == "yes"; then
-
 changequote(<<, >>)dnl
     MPI_CPPFLAGS="$MPI_CPPFLAGS\
-                  `$MPICXX -c conftest.cc | sed -e \"s|^[^ \t]*||\"\
-                                                -e \"s|-DHAVE_MPI_CXX||\"\
-                                                -e \"s|-c conftest.cc[ \t]*$||\"`"
+                  `$MPICXX -c | sed -e \"s|^[^ \t]*||\"\
+                                    -e \"s|-DHAVE_MPI_CXX||\"\
+                                    -e \"s|-c[ \t]*||\"`"
     MPI_LIBS="$MPI_LIBS `$MPICXX | sed -e \"s|^[^ \t]*||\"\
                                        -e \"s|-DHAVE_MPI_CXX||\"`"
 changequote([, ])dnl
