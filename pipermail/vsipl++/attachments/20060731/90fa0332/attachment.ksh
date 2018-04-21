Index: ChangeLog
===================================================================
--- ChangeLog	(revision 146032)
+++ ChangeLog	(working copy)
@@ -1,3 +1,10 @@
+2006-07-31  Jules Bergmann  <jules@codesourcery.com>
+
+	* vendor/GNUmakefile.inc.in: Add LAPACK related libraries to
+	  $(libs).  Add missing dependencies.
+	* configure.ac: Add missing AC_SUBST variables for new
+	  vendor/GNUmakefile.inc.in.
+	
 2006-07-28  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/impl/simd/expr_iterator.hpp: Fix template parameter
Index: vendor/GNUmakefile.inc.in
===================================================================
--- vendor/GNUmakefile.inc.in	(revision 146032)
+++ vendor/GNUmakefile.inc.in	(working copy)
@@ -31,6 +31,13 @@
 vendor_CLAPACK_BLAS    := vendor/clapack/libblas.a
 vendor_LIBF77          := vendor/clapack/F2CLIBS/libF77/libF77.a
 
+## Libraries built by ATLAS make:
+vendor_ATLAS_LIBS :=				\
+	$(vendor_ATLAS)				\
+	vendor/atlas/lib/libcblas.a		\
+	vendor/atlas/lib/libf77blas.a		\
+	$(vendor_PRE_LAPACK)
+
 ########################################################################
 ################# BUILD PART ###########################################
 ########################################################################
@@ -55,7 +62,9 @@
 endif
 
 ifdef BUILD_LIBF77
-all:: $(vendor_LIBF77)
+all:: lib/libF77.a
+
+libs += lib/libF77.a
 endif
 
 ifdef BUILD_ATLAS
@@ -79,11 +88,14 @@
 	@echo "Building LIBF77 (see libF77.blas.build.log)"
 	@make -C vendor/clapack/F2CLIBS/libF77 all >& libF77.blas.build.log
 
-$(vendor_ATLAS):
+lib/libF77.a: $(vendor_LIBF77)
+	cp $< $@
+
+$(vendor_ATLAS_LIBS):
 	@echo "Building ATLAS (see atlas.build.log)"
 	@make -C vendor/atlas build >& atlas.build.log
 
-$(vendor_MERGED_LAPACK):
+$(vendor_MERGED_LAPACK): $(vendor_LAPACK) $(vendor_PRE_LAPACK)
 	@echo "Merging pre-lapack and reference lapack..."
 	@mkdir -p vendor/atlas/lib/tmp
 	@cd vendor/atlas/lib/tmp;ar x ../../../../$(vendor_PRE_LAPACK)
@@ -97,29 +109,34 @@
 ########################################################################
 
 ifdef BUILD_LIBF77
-install::
-	$(INSTALL_DATA) $(vendor_LIBF77) $(DESTDIR)$(libdir)
+install:: lib/libF77.a
+	$(INSTALL_DATA) lib/libF77.a $(DESTDIR)$(libdir)
 endif
 
 ifdef BUILD_REF_LAPACK
-install::
+install:: vendor/atlas/lib/libf77blas.a
 	$(INSTALL_DATA) vendor/atlas/lib/libf77blas.a $(DESTDIR)$(libdir)
+
+libs += vendor/atlas/lib/libf77blas.a
 endif
 
 ifdef USE_ATLAS_LAPACK
-install::
-	$(INSTALL_DATA) vendor/atlas/lib/libatlas.a   $(DESTDIR)$(libdir)
+install:: $(vendor_ATLAS) vendor/atlas/lib/libcblas.a $(vendor_MERGED_LAPACK)
+	$(INSTALL_DATA) $(vendor_ATLAS)               $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) vendor/atlas/lib/libcblas.a   $(DESTDIR)$(libdir)
-	$(INSTALL_DATA) vendor/atlas/lib/liblapack.a  $(DESTDIR)$(libdir)
-	$(INSTALL_DATA) vendor/atlas/lib/liblapack.a  $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) $(vendor_MERGED_LAPACK)       $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) $(srcdir)/vendor/atlas/include/cblas.h $(DESTDIR)$(includedir)
+
+libs += $(vendor_ATLAS) vendor/atlas/lib/libcblas.a $(vendor_MERGED_LAPACK)
 endif
 
 ifdef USE_SIMPLE_LAPACK
-install::
+install:: $(vendor_CLAPACK) $(vendor_CLAPACK_BLAS)
 	$(INSTALL_DATA) $(vendor_CLAPACK)      $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) $(vendor_CLAPACK_BLAS) $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) $(srcdir)/vendor/clapack/SRC/cblas.h $(DESTDIR)$(includedir)
+
+libs += $(vendor_CLAPACK) $(vendor_CLAPACK_BLAS)
 endif
 
 
Index: configure.ac
===================================================================
--- configure.ac	(revision 146032)
+++ configure.ac	(working copy)
@@ -297,6 +297,13 @@
 
 
 #
+# Put libs directory int INT_LDFLAGS:
+#
+INT_LDFLAGS="$INT_LDFLAGS -L$curdir/lib"
+
+
+
+#
 # Files to generate.
 #
 
@@ -1383,7 +1390,7 @@
 	  mv `find atlas_untar -name "*.a"` vendor/atlas/lib
 	  mv vendor/atlas/lib/liblapack.a vendor/atlas/lib/libprelapack.a
 	  rm -rf atlas_untar
-        else
+        else # test "x$with_atlas_tarball" != "x"
         # assert(NOT CROSS-COMPILING)
 
         echo "==============================================================="
@@ -1453,11 +1460,23 @@
 	else
           AC_MSG_ERROR([built-in ATLAS configure FAILED.])
 	fi
+        fi # test "x$with_atlas_tarball" != "x"
+
+        # AC_SUBST(USE_BUILTIN_ATLAS, 1)
+        AC_SUBST(BUILD_ATLAS, 1)
+        if test "$trypkg" == "fortran-builtin"; then
+          AC_SUBST(BUILD_REF_LAPACK,  1)
+          AC_SUBST(BUILD_REF_CLAPACK, "")
+          AC_SUBST(BUILD_LIBF77,      "")
+        else
+          AC_SUBST(BUILD_REF_LAPACK,  "")
+          AC_SUBST(BUILD_REF_CLAPACK, 1)
+          AC_SUBST(BUILD_LIBF77,      1)
         fi
+        AC_SUBST(BUILD_REF_CLAPACK_BLAS, "")
+        AC_SUBST(USE_ATLAS_LAPACK,       1)
+        AC_SUBST(USE_SIMPLE_LAPACK,      "")
 
-
-        AC_SUBST(USE_BUILTIN_ATLAS, 1)
-
 	curdir=`pwd`
 	if test "`echo $srcdir | sed -n '/^\//p'`" != ""; then
 	  my_abs_top_srcdir="$srcdir"
