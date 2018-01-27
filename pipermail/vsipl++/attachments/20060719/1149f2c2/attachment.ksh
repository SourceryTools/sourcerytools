Index: vendor/GNUmakefile.inc.in
===================================================================
--- vendor/GNUmakefile.inc.in	(revision 144408)
+++ vendor/GNUmakefile.inc.in	(working copy)
@@ -12,169 +12,177 @@
 # Variables
 ########################################################################
 
-USE_BUILTIN_ATLAS  := @USE_BUILTIN_ATLAS@
-USE_FORTRAN_LAPACK := @USE_FORTRAN_LAPACK@
-USE_BUILTIN_LIBF77 := @USE_BUILTIN_LIBF77@
-USE_BUILTIN_FFTW  := @USE_BUILTIN_FFTW@
-USE_BUILTIN_FFTW_FLOAT := @USE_BUILTIN_FFTW_FLOAT@
-USE_BUILTIN_FFTW_DOUBLE := @USE_BUILTIN_FFTW_DOUBLE@
-USE_BUILTIN_FFTW_LONG_DOUBLE := @USE_BUILTIN_FFTW_LONG_DOUBLE@
 
-vendor_CLAPACK    = vendor/clapack/lapack.a
-vendor_FLAPACK    = vendor/lapack/lapack.a
-vendor_PRE_LAPACK = vendor/atlas/lib/libprelapack.a
-vendor_USE_LAPACK = vendor/atlas/lib/liblapack.a
-ifdef USE_FORTRAN_LAPACK
-  vendor_F77BLAS    = vendor/atlas/lib/libf77blas.a
-  vendor_REF_LAPACK = $(vendor_FLAPACK)
-else
-  vendor_F77BLAS    = 
-  vendor_REF_LAPACK = $(vendor_CLAPACK)
-endif
+BUILD_ATLAS            := @BUILD_ATLAS@
+BUILD_REF_LAPACK       := @BUILD_REF_LAPACK@
+BUILD_REF_CLAPACK      := @BUILD_REF_CLAPACK@
+BUILD_REF_CLAPACK_BLAS := @BUILD_REF_CLAPACK_BLAS@
+BUILD_LIBF77           := @BUILD_LIBF77@
 
-vendor_LIBF77      = vendor/clapack/F2CLIBS/libF77/libF77.a
+USE_ATLAS_LAPACK       := @USE_ATLAS_LAPACK@
+USE_SIMPLE_LAPACK      := @USE_SIMPLE_LAPACK@
 
+#### LIBS
+vendor_ATLAS           := vendor/atlas/lib/libatlas.a
+vendor_FLAPACK         := vendor/lapack/lapack.a
+vendor_CLAPACK         := vendor/clapack/liblapack.a
+vendor_MERGED_LAPACK   := vendor/atlas/lib/liblapack.a
+vendor_PRE_LAPACK      := vendor/atlas/lib/libprelapack.a
+vendor_CLAPACK_BLAS    := vendor/clapack/libblas.a
+vendor_LIBF77          := vendor/clapack/F2CLIBS/libF77/libF77.a
 
-vendor_ATLAS_LIBS :=				\
-	vendor/atlas/lib/libatlas.a		\
-	vendor/atlas/lib/libcblas.a		\
-	$(vendor_F77BLAS)			\
-	$(vendor_PRE_LAPACK)
+########################################################################
+################# BUILD PART ###########################################
+########################################################################
 
-vendor_LIBS :=					\
-	vendor/atlas/lib/libatlas.a		\
-	vendor/atlas/lib/libcblas.a		\
-	$(vendor_USE_LAPACK)
 
+ifdef BUILD_REF_LAPACK
+all:: $(vendor_FLAPACK)
+endif
 
-########################################################################
-# ATLAS Rules
-########################################################################
+ifdef BUILD_REF_LAPACK
+all:: $(vendor_FLAPACK)
+vendor_LAPACK := $(vendor_FLAPACK)
+endif
 
-ifdef USE_BUILTIN_ATLAS
-all:: $(vendor_F77BLAS) $(vendor_LIBS)
+ifdef BUILD_REF_CLAPACK
+all:: $(vendor_CLAPACK)
+vendor_LAPACK := $(vendor_CLAPACK)
+endif
 
-libs += $(vendor_F77BLAS) $(vendor_LIBS)
+ifdef BUILD_REF_CLAPACK_BLAS
+all:: $(vendor_CLAPACK_BLAS)
+endif
 
-$(vendor_ATLAS_LIBS):
-	@echo "Building ATLAS (see atlas.build.log)"
-	@$(MAKE) -C vendor/atlas build > atlas.build.log 2>&1
+ifdef BUILD_LIBF77
+all:: $(vendor_LIBF77)
+endif
 
-ifdef USE_FORTRAN_LAPACK
+ifdef BUILD_ATLAS
+all:: $(vendor_ATLAS) $(vendor_MERGED_LAPACK)
+endif
+
+##### RULES
 $(vendor_FLAPACK):
-	@echo "Building LAPACK (see lapack.build.log)"
-	@$(MAKE) -C vendor/lapack/SRC all > lapack.build.log 2>&1
+	@echo "Building FLAPACK (see flapack.build.log)"
+	@make -C vendor/lapack/SRC all >& flapack.build.log
 
-clean::
-	@echo "Cleaning LAPACK (see lapack.clean.log)"
-	@$(MAKE) -C vendor/lapack/SRC clean > lapack.clean.log 2>&1
-else
 $(vendor_CLAPACK):
 	@echo "Building CLAPACK (see clapack.build.log)"
-	@$(MAKE) -C vendor/clapack/SRC all > clapack.build.log 2>&1
+	@make -C vendor/clapack/SRC all >& clapack.build.log
 
-clean::
-	@echo "Cleaning CLAPACK (see clapack.clean.log)"
-	@$(MAKE) -C vendor/clapack/SRC clean > clapack.clean.log 2>&1
-endif
+$(vendor_CLAPACK_BLAS):
+	@echo "Building CLAPACK BLAS (see clapack.blas.build.log)"
+	@make -C vendor/clapack/blas/SRC all >& clapack.blas.build.log
 
-$(vendor_USE_LAPACK): $(vendor_PRE_LAPACK) $(vendor_REF_LAPACK)
-	mkdir -p vendor/atlas/lib/tmp
-	cd vendor/atlas/lib/tmp; ar x ../../../../$(vendor_PRE_LAPACK); cd ../../../..
-	cp $(vendor_REF_LAPACK) $(vendor_USE_LAPACK)
-	cd vendor/atlas/lib/tmp; ar r ../../../../$(vendor_USE_LAPACK); cd ../../../..
-	rm -rf vendor/atlas/lib/tmp
+$(vendor_LIBF77):
+	@echo "Building LIBF77 (see libF77.blas.build.log)"
+	@make -C vendor/clapack/F2CLIBS/libF77 all >& libF77.blas.build.log
 
+$(vendor_ATLAS):
+	@echo "Building ATLAS (see atlas.build.log)"
+	@make -C vendor/atlas build >& atlas.build.log
 
+$(vendor_MERGED_LAPACK):
+	@echo "Merging pre-lapack and reference lapack..."
+	@mkdir -p vendor/atlas/lib/tmp
+	@cd vendor/atlas/lib/tmp;ar x ../../../../$(vendor_PRE_LAPACK)
+	@cp $(vendor_LAPACK) $(vendor_MERGED_LAPACK)
+	@cd vendor/atlas/lib/tmp;ar r ../../../../$(vendor_MERGED_LAPACK) *
+	@rm -rf vendor/atlas/lib/tmp
 
-ifdef USE_BUILTIN_LIBF77
-all:: $(vendor_LIBF77)
 
-libs += $(vendor_LIBF77)
+########################################################################
+################# INSTALL PART #########################################
+########################################################################
 
-$(vendor_LIBF77):
-	@echo "Building libF77 (see libF77.build.log)"
-	@$(MAKE) -C vendor/clapack/F2CLIBS/libF77 all > libF77.build.log 2>&1
-	@rm -f vendor/atlas/lib/libF77.a
-	@ln -s `pwd`/vendor/clapack/F2CLIBS/libF77/libF77.a vendor/atlas/lib/libF77.a
-
-
-install:: $(vendor_LIBF77)
+ifdef BUILD_LIBF77
+install::
 	$(INSTALL_DATA) $(vendor_LIBF77) $(DESTDIR)$(libdir)
+endif
 
-clean::
-	@echo "Cleaning libF77 (see libF77.clean.log)"
-	@$(MAKE) -C vendor/clapack/F2CLIBS/libF77 clean > libF77.clean.log 2>&1
+ifdef BUILD_REF_LAPACK
+install::
+	$(INSTALL_DATA) vendor/atlas/lib/libf77blas.a $(DESTDIR)$(libdir)
 endif
 
-
-clean::
-	@echo "Cleaning ATLAS (see atlas.clean.log)"
-	@$(MAKE) -C vendor/atlas clean > atlas.clean.log 2>&1
-
-install:: $(vendor_LIBS)
-	@echo "Installing ATLAS (see atlas.install.log)"
-	# @$(MAKE) -C vendor/atlas installinstall > atlas.install.log 2>&1
+ifdef USE_ATLAS_LAPACK
+install::
 	$(INSTALL_DATA) vendor/atlas/lib/libatlas.a   $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) vendor/atlas/lib/libcblas.a   $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) vendor/atlas/lib/liblapack.a  $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) vendor/atlas/lib/liblapack.a  $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) $(srcdir)/vendor/atlas/include/cblas.h $(DESTDIR)$(includedir)
+endif
 
-ifdef USE_FORTRAN_LAPACK
-install:: $(vendor_F77BLAS)
-	$(INSTALL_DATA) vendor/atlas/lib/libf77blas.a $(DESTDIR)$(libdir)
-endif # USE_FORTRAN_LAPACK
+ifdef USE_SIMPLE_LAPACK
+install::
+	$(INSTALL_DATA) $(vendor_CLAPACK)      $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) $(vendor_CLAPACK_BLAS) $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) $(srcdir)/vendor/clapack/SRC/cblas.h $(DESTDIR)$(includedir)
+endif
 
-endif # USE_BUILTIN_ATLAS
 
+########################################################################
 
 
+USE_BUILTIN_FFTW  := @USE_BUILTIN_FFTW@
+USE_BUILTIN_FFTW_FLOAT := @USE_BUILTIN_FFTW_FLOAT@
+USE_BUILTIN_FFTW_DOUBLE := @USE_BUILTIN_FFTW_DOUBLE@
+USE_BUILTIN_FFTW_LONG_DOUBLE := @USE_BUILTIN_FFTW_LONG_DOUBLE@
+
 ########################################################################
 # FFTW Rules
 ########################################################################
 
-vpath %.h src:$(srcdir)
+ifdef USE_BUILTIN_FFTW
 
-lib/libfftw3f.a: vendor/fftw3f/.libs/libfftw3f.a
-	cp $< $@
- 
-vendor/fftw3f/.libs/libfftw3f.a:
+ifdef USE_BUILTIN_FFTW_FLOAT
+LIBFFTW_FLOAT := vendor/fftw3f/.libs/libfftw3f.a
+$(LIBFFTW_FLOAT):
 	@echo "Building FFTW float (see fftw-f.build.log)"
 	@$(MAKE) -C vendor/fftw3f > fftw-f.build.log 2>&1
-
-lib/libfftw3.a: vendor/fftw3/.libs/libfftw3.a
-	cp $< $@
-
-vendor/fftw3/.libs/libfftw3.a:
+else
+LIBFFTW_LONG_FLOAT :=
+endif
+ifdef USE_BUILTIN_FFTW_DOUBLE
+LIBFFTW_DOUBLE := vendor/fftw3/.libs/libfftw3.a
+$(LIBFFTW_DOUBLE):
 	@echo "Building FFTW double (see fftw-d.build.log)"
 	@$(MAKE) -C vendor/fftw3 > fftw-d.build.log 2>&1
+else
+LIBFFTW_DOUBLE :=
+endif
 
-lib/libfftw3l.a: vendor/fftw3l/.libs/libfftw3l.a
-	cp $< $@
-
-vendor/fftw3l/.libs/libfftw3l.a:
+ifdef USE_BUILTIN_FFTW_LONG_DOUBLE
+LIBFFTW_LONG_DOUBLE := vendor/fftw3l/.libs/libfftw3l.a
+$(LIBFFTW_LONG_DOUBLE):
 	@echo "Building FFTW long double (see fftw-l.build.log)"
 	@$(MAKE) -C vendor/fftw3l > fftw-l.build.log 2>&1
+else
+LIBFFTW_LONG_DOUBLE :=
+endif
 
-ifdef USE_BUILTIN_FFTW
-  ifdef USE_BUILTIN_FFTW_FLOAT
-    vendor_FFTW_LIBS += lib/libfftw3f.a
-  endif
-  ifdef USE_BUILTIN_FFTW_DOUBLE
-    vendor_FFTW_LIBS += lib/libfftw3.a
-  endif
-  ifdef USE_BUILTIN_FFTW_LONG_DOUBLE
-    vendor_FFTW_LIBS += lib/libfftw3l.a
-  endif
-
+vendor_FFTW_LIBS := $(LIBFFTW_FLOAT) $(LIBFFTW_DOUBLE) $(LIBFFTW_LONG_DOUBLE)
 libs += $(vendor_FFTW_LIBS) 
 
+all:: $(vendor_FFTW_LIBS)
+	@rm -rf vendor/fftw/include
+	@mkdir -p vendor/fftw/include
+	@ln -s $(srcdir)/vendor/fftw/api/fftw3.h vendor/fftw/include/fftw3.h
+	@rm -rf vendor/fftw/lib
+	@mkdir -p vendor/fftw/lib
+	@for lib in $(vendor_FFTW_LIBS); do \
+          ln -s `pwd`/$$lib vendor/fftw/lib/`basename $$lib`; \
+          done
+
 clean::
 	@echo "Cleaning FFTW (see fftw.clean.log)"
 	@for ldir in $(subst /.libs/,,$(dir $(vendor_FFTW_LIBS))); do \
 	  echo "$(MAKE) -C $$ldir clean "; \
 	  $(MAKE) -C $$ldir clean; done  > fftw.clean.log 2>&1
 
+        # note: configure script constructs vendor/fftw/ symlinks used here.
 install:: $(vendor_FFTW_LIBS)
 	@echo "Installing FFTW"
 	$(INSTALL) -d $(DESTDIR)$(libdir)
@@ -182,5 +190,5 @@
 	  echo "$(INSTALL_DATA) $$lib  $(DESTDIR)$(libdir)"; \
 	  $(INSTALL_DATA) $$lib  $(DESTDIR)$(libdir); done
 	$(INSTALL) -d $(DESTDIR)$(includedir)
-	$(INSTALL_DATA) src/fftw3.h $(DESTDIR)$(includedir)
+	$(INSTALL_DATA) $(srcdir)/vendor/fftw/api/fftw3.h $(DESTDIR)$(includedir)
 endif
Index: configure.ac
===================================================================
--- configure.ac	(revision 144408)
+++ configure.ac	(working copy)
@@ -175,8 +175,9 @@
 		  Library), acml (AMD Core Math Library), atlas (system
 		  ATLAS/LAPACK installation), generic (system generic
 		  LAPACK installation), builtin (Sourcery VSIPL++'s
-		  builtin ATLAS/C-LAPACK), and fortran-builtin (Sourcery
-		  VSIPL++'s builtin ATLAS/Fortran-LAPACK). 
+		  builtin ATLAS/C-LAPACK), fortran-builtin (Sourcery
+		  VSIPL++'s builtin ATLAS/Fortran-LAPACK, and simple-builtin
+                  (Lapack that doesn't require atlas).). 
 		  Specifying 'no' disables search for a LAPACK library.]),,
   [with_lapack=probe])
 
@@ -1280,6 +1281,8 @@
     lapack_packages="atlas generic1 generic2 builtin"
   elif test "$with_lapack" == "generic"; then
     lapack_packages="generic1 generic2"
+  elif test "$with_lapack" == "simple-builtin"; then
+    lapack_packages="simple-builtin";
   else
     lapack_packages="$with_lapack"
   fi
@@ -1457,7 +1460,8 @@
         fi
 
 
-        AC_SUBST(USE_BUILTIN_ATLAS, 1)
+	AC_SUBST(BUILD_ATLAS,       1)  # Build ATLAS
+        AC_SUBST(USE_ATLAS_LAPACK,  1)
 
 	curdir=`pwd`
 	if test "`echo $srcdir | sed -n '/^\//p'`" != ""; then
@@ -1475,12 +1479,14 @@
 	  # When using Fortran LAPACK, we need ATLAS' f77blas (it
 	  # provides the Fortran BLAS bindings) and we need libg2c.
           LATE_LIBS="-llapack -lcblas -lf77blas -latlas $use_g2c $LATE_LIBS"
-          AC_SUBST(USE_FORTRAN_LAPACK, 1)
+          AC_SUBST(BUILD_REF_LAPACK, 1)  # Build lapack in vendor/lapack/SRC
         else
 	  # When using C LAPACK, we need libF77 (the builtin equivalent
 	  # of libg2c).
           LATE_LIBS="-llapack -lF77 -lcblas -latlas $LATE_LIBS"
-          AC_SUBST(USE_BUILTIN_LIBF77, 1)
+	  AC_SUBST(BUILD_REF_CLAPACK, 1)  # Build clapack in vendor/clapack/SRC
+	  AC_SUBST(BUILD_LIBF77,      1)  # clapack requires LIBF77
+          ln -s ../../clapack/F2CLIBS/libF77/libF77.a vendor/atlas/lib/libF77.a
         fi
 
 	INT_CPPFLAGS="-I$my_abs_top_srcdir/vendor/atlas/include $INT_CPPFLAGS"
@@ -1519,6 +1525,27 @@
         AC_MSG_RESULT([not present])
 	continue
       fi
+    elif test "$trypkg" == "simple-builtin"; then
+
+      curdir=`pwd`
+      # flags that are used internally
+      INT_CPPFLAGS="$INT_CPPFLAGS -I$srcdir/vendor/clapack/SRC"
+      INT_LDFLAGS="$INT_LDFLAGS -L$curdir/vendor/clapack"
+      INT_LDFLAGS="$INT_LDFLAGS -L$curdir/vendor/clapack/F2CLIBS/libF77"
+
+      # flags that are used after install
+      CPPFLAGS="$keep_CPPFLAGS -I$incdir/lapack"
+      LDFLAGS="$keep_LDFLAGS -L$libdir/lapack"
+      LATE_LIBS="$LATE_LIBS -llapack -lblas -lF77"
+
+      AC_SUBST(BUILD_REF_CLAPACK, 1)   # Build clapack in vendor/clapack/SRC
+      AC_SUBST(BUILD_REF_CLAPACK_BLAS, 1) # Build blas in vendor/clapack/blas
+      AC_SUBST(BUILD_LIBF77,      1)   # clapack requires libF77
+      AC_SUBST(USE_SIMPLE_LAPACK, 1)
+      
+      lapack_use_ilaenv=0
+      lapack_found="simple-builtin"
+      break
     fi
 
 
Index: vendor/clapack/SRC/make.inc.in
===================================================================
--- vendor/clapack/SRC/make.inc.in	(revision 144409)
+++ vendor/clapack/SRC/make.inc.in	(working copy)
@@ -24,8 +24,16 @@
 # specify special flags that could make CLAPACK run faster. If the 
 # --with-clapack-cflags option is not used CLAPACK_CFLAGS is the normal CFLAGS
 # 
+USE_SIMPLE_LAPACK  := @USE_SIMPLE_LAPACK@
 CC        = @CC@
 CFLAGS    = @CLAPACK_CFLAGS@ -DNO_INLINE_WRAP
+
+# If we want to use the blas that came with clapack, we have to define
+# NO_BLAS_WRAP so that blas functions will not be redefined to f2c_func
+ifdef USE_SIMPLE_LAPACK
+CFLAGS   += -DNO_BLAS_WRAP
+endif
+
 LOADER    = $(CC)
 LOADOPTS  = $(CFLAGS)
 NOOPT     = @CLAPACK_NOOPT@
@@ -45,8 +53,8 @@
 #  machine-specific, optimized BLAS library should be used whenever
 #  possible.)
 #
-BLASLIB      = ../../blas$(PLAT).a
-LAPACKLIB    = lapack$(PLAT).a
+BLASLIB      = ../../libblas$(PLAT).a
+LAPACKLIB    = liblapack$(PLAT).a
 F2CLIB       = ../../F2CLIBS/libF77.a ../../F2CLIBS/libI77.a
 TMGLIB       = tmglib$(PLAT).a
 EIGSRCLIB    = eigsrc$(PLAT).a
Index: vendor/clapack/blas/SRC/Makefile
===================================================================
--- vendor/clapack/blas/SRC/Makefile	(revision 144409)
+++ vendor/clapack/blas/SRC/Makefile	(working copy)
@@ -1,160 +0,0 @@
-include ../../make.inc
-
-#######################################################################
-#  This is the makefile to create a library for the BLAS.
-#  The files are grouped as follows:
-#
-#       SBLAS1 -- Single precision real BLAS routines
-#       CBLAS1 -- Single precision complex BLAS routines
-#       DBLAS1 -- Double precision real BLAS routines
-#       ZBLAS1 -- Double precision complex BLAS routines
-#
-#       CB1AUX -- Real BLAS routines called by complex routines
-#       ZB1AUX -- D.P. real BLAS routines called by d.p. complex
-#                 routines
-#
-#      ALLBLAS -- Auxiliary routines for Level 2 and 3 BLAS
-#
-#       SBLAS2 -- Single precision real BLAS2 routines
-#       CBLAS2 -- Single precision complex BLAS2 routines
-#       DBLAS2 -- Double precision real BLAS2 routines
-#       ZBLAS2 -- Double precision complex BLAS2 routines
-#
-#       SBLAS3 -- Single precision real BLAS3 routines
-#       CBLAS3 -- Single precision complex BLAS3 routines
-#       DBLAS3 -- Double precision real BLAS3 routines
-#       ZBLAS3 -- Double precision complex BLAS3 routines
-#
-#  The library can be set up to include routines for any combination
-#  of the four precisions.  To create or add to the library, enter make
-#  followed by one or more of the precisions desired.  Some examples:
-#       make single
-#       make single complex
-#       make single double complex complex16
-#  Alternatively, the command
-#       make
-#  without any arguments creates a library of all four precisions.
-#  The library is called
-#       blas.a
-#
-#  To remove the object files after the library is created, enter
-#       make clean
-#  To force the source files to be recompiled, enter, for example,
-#       make single FRC=FRC
-#
-#---------------------------------------------------------------------
-#
-#  Edward Anderson, University of Tennessee
-#  March 26, 1990
-#  Susan Ostrouchov, Last updated September 30, 1994
-#
-#######################################################################
-
-all: single double complex complex16
- 
-#---------------------------------------------------------
-#  Comment out the next 6 definitions if you already have
-#  the Level 1 BLAS.
-#---------------------------------------------------------
-SBLAS1 = isamax.o sasum.o saxpy.o scopy.o sdot.o snrm2.o \
-	srot.o srotg.o sscal.o sswap.o
-$(SBLAS1): $(FRC)
-
-CBLAS1 = scasum.o scnrm2.o icamax.o caxpy.o ccopy.o \
-	cdotc.o cdotu.o csscal.o crotg.o cscal.o cswap.o
-$(CBLAS1): $(FRC)
-
-DBLAS1 = idamax.o dasum.o daxpy.o dcopy.o ddot.o dnrm2.o \
-	drot.o drotg.o dscal.o dswap.o
-$(DBLAS1): $(FRC)
-
-ZBLAS1 = dcabs1.o dzasum.o dznrm2.o izamax.o zaxpy.o zcopy.o \
-	zdotc.o zdotu.o zdscal.o zrotg.o zscal.o zswap.o
-$(ZBLAS1): $(FRC)
-
-CB1AUX = isamax.o sasum.o saxpy.o scopy.o snrm2.o sscal.o
-$(CB1AUX): $(FRC)
-
-ZB1AUX = idamax.o dasum.o daxpy.o dcopy.o dnrm2.o dscal.o
-$(ZB1AUX): $(FRC)
-
-#---------------------------------------------------------------------
-#  The following line defines auxiliary routines needed by both the
-#  Level 2 and Level 3 BLAS.  Comment it out only if you already have
-#  both the Level 2 and 3 BLAS.
-#---------------------------------------------------------------------
-ALLBLAS  = lsame.o xerbla.o
-$(ALLBLAS) : $(FRC)
-
-#---------------------------------------------------------
-#  Comment out the next 4 definitions if you already have
-#  the Level 2 BLAS.
-#---------------------------------------------------------
-SBLAS2 = sgemv.o sgbmv.o ssymv.o ssbmv.o sspmv.o \
-	strmv.o stbmv.o stpmv.o strsv.o stbsv.o stpsv.o \
-	sger.o ssyr.o sspr.o ssyr2.o sspr2.o
-$(SBLAS2): $(FRC)
-
-CBLAS2 = cgemv.o cgbmv.o chemv.o chbmv.o chpmv.o \
-	ctrmv.o ctbmv.o ctpmv.o ctrsv.o ctbsv.o ctpsv.o \
-	cgerc.o cgeru.o cher.o chpr.o cher2.o chpr2.o
-$(CBLAS2): $(FRC)
-
-DBLAS2 = dgemv.o dgbmv.o dsymv.o dsbmv.o dspmv.o \
-	dtrmv.o dtbmv.o dtpmv.o dtrsv.o dtbsv.o dtpsv.o \
-	dger.o dsyr.o dspr.o dsyr2.o dspr2.o
-$(DBLAS2): $(FRC)
-
-ZBLAS2 = zgemv.o zgbmv.o zhemv.o zhbmv.o zhpmv.o \
-	ztrmv.o ztbmv.o ztpmv.o ztrsv.o ztbsv.o ztpsv.o \
-	zgerc.o zgeru.o zher.o zhpr.o zher2.o zhpr2.o
-$(ZBLAS2): $(FRC)
-
-#---------------------------------------------------------
-#  Comment out the next 4 definitions if you already have
-#  the Level 3 BLAS.
-#---------------------------------------------------------
-SBLAS3 = sgemm.o ssymm.o ssyrk.o ssyr2k.o strmm.o strsm.o 
-$(SBLAS3): $(FRC)
-
-CBLAS3 = cgemm.o csymm.o csyrk.o csyr2k.o ctrmm.o ctrsm.o \
-	chemm.o cherk.o cher2k.o
-$(CBLAS3): $(FRC)
-
-DBLAS3 = dgemm.o dsymm.o dsyrk.o dsyr2k.o dtrmm.o dtrsm.o
-$(DBLAS3): $(FRC)
-
-ZBLAS3 = zgemm.o zsymm.o zsyrk.o zsyr2k.o ztrmm.o ztrsm.o \
-	zhemm.o zherk.o zher2k.o
-$(ZBLAS3): $(FRC)
-
-
-single: $(SBLAS1) $(ALLBLAS) $(SBLAS2) $(SBLAS3)
-	$(ARCH) $(ARCHFLAGS) $(BLASLIB) $(SBLAS1) $(ALLBLAS) \
-	$(SBLAS2) $(SBLAS3)
-	$(RANLIB) $(BLASLIB)
-
-double: $(DBLAS1) $(ALLBLAS) $(DBLAS2) $(DBLAS3)
-	$(ARCH) $(ARCHFLAGS) $(BLASLIB) $(DBLAS1) $(ALLBLAS) \
-	$(DBLAS2) $(DBLAS3)
-	$(RANLIB) $(BLASLIB)
-
-complex: $(CBLAS1) $(CB1AUX) $(ALLBLAS) $(CBLAS2) $(CBLAS3)
-	$(ARCH) $(ARCHFLAGS) $(BLASLIB) $(CBLAS1) $(CB1AUX) \
-	$(ALLBLAS) $(CBLAS2) $(CBLAS3)
-	$(RANLIB) $(BLASLIB)
-
-complex16: $(ZBLAS1) $(ZB1AUX) $(ALLBLAS) $(ZBLAS2) $(ZBLAS3)
-	$(ARCH) $(ARCHFLAGS) $(BLASLIB) $(ZBLAS1) $(ZB1AUX) \
-	$(ALLBLAS) $(ZBLAS2) $(ZBLAS3)
-	$(RANLIB) $(BLASLIB)
-
-FRC:
-	@FRC=$(FRC)
-
-clean:
-	rm -f *.o
-
-.c.o: 
-	$(CC) $(CFLAGS) -c $*.c
-
Index: vendor/clapack/blas/SRC/GNUmakefile.in
===================================================================
--- vendor/clapack/blas/SRC/GNUmakefile.in	(revision 144409)
+++ vendor/clapack/blas/SRC/GNUmakefile.in	(working copy)
@@ -1,5 +1,11 @@
-include ../../make.inc
+include ../../SRC/make.inc
 
+srcdir = @srcdir@
+OBJEXT = @OBJEXT@
+
+VPATH = $(srcdir)
+
+
 #######################################################################
 #  This is the makefile to create a library for the BLAS.
 #  The files are grouped as follows:
@@ -83,7 +89,7 @@
 #  Level 2 and Level 3 BLAS.  Comment it out only if you already have
 #  both the Level 2 and 3 BLAS.
 #---------------------------------------------------------------------
-ALLBLAS  = lsame.o xerbla.o
+ALLBLAS  = lsame.o xerbla_new.o
 $(ALLBLAS) : $(FRC)
 
 #---------------------------------------------------------
@@ -155,6 +161,3 @@
 clean:
 	rm -f *.o
 
-.c.o: 
-	$(CC) $(CFLAGS) -c $*.c
-
