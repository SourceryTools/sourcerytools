Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.105
diff -u -r1.105 configure.ac
--- configure.ac	14 May 2006 20:57:05 -0000	1.105
+++ configure.ac	3 Jun 2006 10:40:47 -0000
@@ -175,8 +175,9 @@
 		  Library), acml (AMD Core Math Library), atlas (system
 		  ATLAS/LAPACK installation), generic (system generic
 		  LAPACK installation), builtin (Sourcery VSIPL++'s
-		  builtin ATLAS/C-LAPACK), and fortran-builtin (Sourcery
-		  VSIPL++'s builtin ATLAS/Fortran-LAPACK). 
+		  builtin ATLAS/C-LAPACK), fortran-builtin (Sourcery
+		  VSIPL++'s builtin ATLAS/Fortran-LAPACK, and a simple (Lapack
+                  that doesn't require atlas).). 
 		  Specifying 'no' disables search for a LAPACK library.]),,
   [with_lapack=probe])
 
@@ -492,6 +493,9 @@
 #endif])
 vsip_impl_avoid_posix_memalign=
 
+AC_CHECK_HEADERS([png.h], 
+                 [AC_SUBST(HAVE_PNG_H, 1)], 
+                 [], [// no prerequisites])
 
 #
 # Find the FFT backends.
@@ -1275,6 +1279,8 @@
     lapack_packages="atlas generic1 generic2 builtin"
   elif test "$with_lapack" == "generic"; then
     lapack_packages="generic1 generic2"
+  elif test "$with_lapack" == "simple"; then
+    lapack_packages="simple";
   else
     lapack_packages="$with_lapack"
   fi
@@ -1515,6 +1521,19 @@
         AC_MSG_RESULT([not present])
 	continue
       fi
+    elif test "$trypkg" == "simple"; then
+
+      curdir=`pwd`
+      CPPFLAGS="$keep_CPPFLAGS -I$srcdir/vendor/clapack/SRC"
+      LDFLAGS="$keep_LDFLAGS -L$curdir/vendor/clapack"
+      LIBS="$keep_LIBS -llapack -lcblas"
+
+      AC_SUBST(USE_SIMPLE_LAPACK, 1)
+      
+      lapack_use_ilaenv=0
+      lapack_found="simple"
+      break
     fi
 
Index: vendor/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/vendor/GNUmakefile.inc.in,v
retrieving revision 1.15
diff -u -r1.15 GNUmakefile.inc.in
--- vendor/GNUmakefile.inc.in	11 May 2006 11:29:04 -0000	1.15
+++ vendor/GNUmakefile.inc.in	3 Jun 2006 10:41:15 -0000
@@ -12,6 +12,7 @@
 # Variables
 ########################################################################
 
+USE_SIMPLE_LAPACK  := @USE_SIMPLE_LAPACK@
 USE_BUILTIN_ATLAS  := @USE_BUILTIN_ATLAS@
 USE_FORTRAN_LAPACK := @USE_FORTRAN_LAPACK@
 USE_BUILTIN_LIBF77 := @USE_BUILTIN_LIBF77@
@@ -20,7 +21,7 @@
 USE_BUILTIN_FFTW_DOUBLE := @USE_BUILTIN_FFTW_DOUBLE@
 USE_BUILTIN_FFTW_LONG_DOUBLE := @USE_BUILTIN_FFTW_LONG_DOUBLE@
 
-vendor_CLAPACK    = vendor/clapack/lapack.a
+vendor_CLAPACK    = vendor/clapack/liblapack.a
 vendor_FLAPACK    = vendor/lapack/lapack.a
 vendor_PRE_LAPACK = vendor/atlas/lib/libprelapack.a
 vendor_USE_LAPACK = vendor/atlas/lib/liblapack.a
@@ -33,6 +34,7 @@
 endif
 
 vendor_LIBF77      = vendor/clapack/F2CLIBS/libF77/libF77.a
+vendor_SIMPLE_BLAS = vendor/clapack/libcblas.a
 
 
 vendor_ATLAS_LIBS :=				\
@@ -104,7 +106,6 @@
 	@$(MAKE) -C vendor/clapack/F2CLIBS/libF77 clean > libF77.clean.log 2>&1
 endif
 
-
 clean::
 	@echo "Cleaning ATLAS (see atlas.clean.log)"
 	@$(MAKE) -C vendor/atlas clean > atlas.clean.log 2>&1
@@ -123,6 +124,53 @@
 endif # USE_FORTRAN_LAPACK
 
 endif # USE_BUILTIN_ATLAS
+################################################################################
+
+ifdef USE_SIMPLE_LAPACK
+all:: $(vendor_SIMPLE_BLAS) $(vendor_REF_LAPACK)
+
+libs += $(vendor_F77BLAS) $(vendor_REF_LAPACK)
+
+$(vendor_SIMPLE_BLAS):
+	@echo "Building simple BLAS (see simpleBLAS.build.log)"
+	@$(MAKE) -C vendor/clapack/blas/SRC all > simpleBLAS.build.log 2>&1
+
+ifdef USE_FORTRAN_LAPACK
+$(vendor_FLAPACK):
+	@echo "Building LAPACK (see lapack.build.log)"
+	@$(MAKE) -C vendor/lapack/SRC all > lapack.build.log 2>&1
+
+clean::
+	@echo "Cleaning LAPACK (see lapack.clean.log)"
+	@$(MAKE) -C vendor/lapack/SRC clean > lapack.clean.log 2>&1
+else
+$(vendor_CLAPACK):
+	@echo "Building CLAPACK (see clapack.build.log)"
+	@$(MAKE) -C vendor/clapack/SRC all > clapack.build.log 2>&1
+
+clean::
+	@echo "Cleaning CLAPACK (see clapack.clean.log)"
+	@$(MAKE) -C vendor/clapack/SRC clean > clapack.clean.log 2>&1
+endif # USE_FORTRAN_LAPACK
+
+ifdef USE_BUILTIN_LIBF77
+all:: $(vendor_LIBF77)
+
+libs += $(vendor_LIBF77)
+
+$(vendor_LIBF77):
+	@echo "Building libF77 (see libF77.build.log)"
+	@$(MAKE) -C vendor/clapack/F2CLIBS/libF77 all > libF77.build.log 2>&1
+
+install:: $(vendor_LIBF77)
+	$(INSTALL_DATA) $(vendor_LIBF77) $(DESTDIR)$(libdir)
+
+clean::
+	@echo "Cleaning libF77 (see libF77.clean.log)"
+	@$(MAKE) -C vendor/clapack/F2CLIBS/libF77 clean > libF77.clean.log 2>&1
+endif # USE_BUILTIN_LIBF77
+
+endif # USE_SIMPLE_LAPACK
 
 
 
Index: vendor/clapack/blas/SRC/GNUmakefile.in
===================================================================
RCS file: vendor/clapack/blas/SRC/GNUmakefile.in
diff -N vendor/clapack/blas/SRC/GNUmakefile.in
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ vendor/clapack/blas/SRC/GNUmakefile.in	3 Jun 2006 10:41:20 -0000
@@ -0,0 +1,164 @@
+include ../../SRC/make.inc
+
+srcdir = @srcdir@
+OBJEXT = @OBJEXT@
+
+VPATH = $(srcdir)
+
+
+#######################################################################
+#  This is the makefile to create a library for the BLAS.
+#  The files are grouped as follows:
+#
+#       SBLAS1 -- Single precision real BLAS routines
+#       CBLAS1 -- Single precision complex BLAS routines
+#       DBLAS1 -- Double precision real BLAS routines
+#       ZBLAS1 -- Double precision complex BLAS routines
+#
+#       CB1AUX -- Real BLAS routines called by complex routines
+#       ZB1AUX -- D.P. real BLAS routines called by d.p. complex
+#                 routines
+#
+#      ALLBLAS -- Auxiliary routines for Level 2 and 3 BLAS
+#
+#       SBLAS2 -- Single precision real BLAS2 routines
+#       CBLAS2 -- Single precision complex BLAS2 routines
+#       DBLAS2 -- Double precision real BLAS2 routines
+#       ZBLAS2 -- Double precision complex BLAS2 routines
+#
+#       SBLAS3 -- Single precision real BLAS3 routines
+#       CBLAS3 -- Single precision complex BLAS3 routines
+#       DBLAS3 -- Double precision real BLAS3 routines
+#       ZBLAS3 -- Double precision complex BLAS3 routines
+#
+#  The library can be set up to include routines for any combination
+#  of the four precisions.  To create or add to the library, enter make
+#  followed by one or more of the precisions desired.  Some examples:
+#       make single
+#       make single complex
+#       make single double complex complex16
+#  Alternatively, the command
+#       make
+#  without any arguments creates a library of all four precisions.
+#  The library is called
+#       blas.a
+#
+#  To remove the object files after the library is created, enter
+#       make clean
+#  To force the source files to be recompiled, enter, for example,
+#       make single FRC=FRC
+#
+#---------------------------------------------------------------------
+#
+#  Edward Anderson, University of Tennessee
+#  March 26, 1990
+#  Susan Ostrouchov, Last updated September 30, 1994
+#
+#######################################################################
+
+all: single double complex complex16
+ 
+#---------------------------------------------------------
+#  Comment out the next 6 definitions if you already have
+#  the Level 1 BLAS.
+#---------------------------------------------------------
+SBLAS1 = isamax.o sasum.o saxpy.o scopy.o sdot.o snrm2.o \
+	srot.o srotg.o sscal.o sswap.o
+$(SBLAS1): $(FRC)
+
+CBLAS1 = scasum.o scnrm2.o icamax.o caxpy.o ccopy.o \
+	cdotc.o cdotu.o csscal.o crotg.o cscal.o cswap.o
+$(CBLAS1): $(FRC)
+
+DBLAS1 = idamax.o dasum.o daxpy.o dcopy.o ddot.o dnrm2.o \
+	drot.o drotg.o dscal.o dswap.o
+$(DBLAS1): $(FRC)
+
+ZBLAS1 = dcabs1.o dzasum.o dznrm2.o izamax.o zaxpy.o zcopy.o \
+	zdotc.o zdotu.o zdscal.o zrotg.o zscal.o zswap.o
+$(ZBLAS1): $(FRC)
+
+CB1AUX = isamax.o sasum.o saxpy.o scopy.o snrm2.o sscal.o
+$(CB1AUX): $(FRC)
+
+ZB1AUX = idamax.o dasum.o daxpy.o dcopy.o dnrm2.o dscal.o
+$(ZB1AUX): $(FRC)
+
+#---------------------------------------------------------------------
+#  The following line defines auxiliary routines needed by both the
+#  Level 2 and Level 3 BLAS.  Comment it out only if you already have
+#  both the Level 2 and 3 BLAS.
+#---------------------------------------------------------------------
+ALLBLAS  = lsame.o xerbla.o
+$(ALLBLAS) : $(FRC)
+
+#---------------------------------------------------------
+#  Comment out the next 4 definitions if you already have
+#  the Level 2 BLAS.
+#---------------------------------------------------------
+SBLAS2 = sgemv.o sgbmv.o ssymv.o ssbmv.o sspmv.o \
+	strmv.o stbmv.o stpmv.o strsv.o stbsv.o stpsv.o \
+	sger.o ssyr.o sspr.o ssyr2.o sspr2.o
+$(SBLAS2): $(FRC)
+
+CBLAS2 = cgemv.o cgbmv.o chemv.o chbmv.o chpmv.o \
+	ctrmv.o ctbmv.o ctpmv.o ctrsv.o ctbsv.o ctpsv.o \
+	cgerc.o cgeru.o cher.o chpr.o cher2.o chpr2.o
+$(CBLAS2): $(FRC)
+
+DBLAS2 = dgemv.o dgbmv.o dsymv.o dsbmv.o dspmv.o \
+	dtrmv.o dtbmv.o dtpmv.o dtrsv.o dtbsv.o dtpsv.o \
+	dger.o dsyr.o dspr.o dsyr2.o dspr2.o
+$(DBLAS2): $(FRC)
+
+ZBLAS2 = zgemv.o zgbmv.o zhemv.o zhbmv.o zhpmv.o \
+	ztrmv.o ztbmv.o ztpmv.o ztrsv.o ztbsv.o ztpsv.o \
+	zgerc.o zgeru.o zher.o zhpr.o zher2.o zhpr2.o
+$(ZBLAS2): $(FRC)
+
+#---------------------------------------------------------
+#  Comment out the next 4 definitions if you already have
+#  the Level 3 BLAS.
+#---------------------------------------------------------
+SBLAS3 = sgemm.o ssymm.o ssyrk.o ssyr2k.o strmm.o strsm.o 
+$(SBLAS3): $(FRC)
+
+CBLAS3 = cgemm.o csymm.o csyrk.o csyr2k.o ctrmm.o ctrsm.o \
+	chemm.o cherk.o cher2k.o
+$(CBLAS3): $(FRC)
+
+DBLAS3 = dgemm.o dsymm.o dsyrk.o dsyr2k.o dtrmm.o dtrsm.o
+$(DBLAS3): $(FRC)
+
+ZBLAS3 = zgemm.o zsymm.o zsyrk.o zsyr2k.o ztrmm.o ztrsm.o \
+	zhemm.o zherk.o zher2k.o
+$(ZBLAS3): $(FRC)
+
+
+single: $(SBLAS1) $(ALLBLAS) $(SBLAS2) $(SBLAS3)
+	$(ARCH) $(ARCHFLAGS) $(BLASLIB) $(SBLAS1) $(ALLBLAS) \
+	$(SBLAS2) $(SBLAS3)
+	$(RANLIB) $(BLASLIB)
+
+double: $(DBLAS1) $(ALLBLAS) $(DBLAS2) $(DBLAS3)
+	$(ARCH) $(ARCHFLAGS) $(BLASLIB) $(DBLAS1) $(ALLBLAS) \
+	$(DBLAS2) $(DBLAS3)
+	$(RANLIB) $(BLASLIB)
+
+complex: $(CBLAS1) $(CB1AUX) $(ALLBLAS) $(CBLAS2) $(CBLAS3)
+	$(ARCH) $(ARCHFLAGS) $(BLASLIB) $(CBLAS1) $(CB1AUX) \
+	$(ALLBLAS) $(CBLAS2) $(CBLAS3)
+	$(RANLIB) $(BLASLIB)
+
+complex16: $(ZBLAS1) $(ZB1AUX) $(ALLBLAS) $(ZBLAS2) $(ZBLAS3)
+	$(ARCH) $(ARCHFLAGS) $(BLASLIB) $(ZBLAS1) $(ZB1AUX) \
+	$(ALLBLAS) $(ZBLAS2) $(ZBLAS3)
+	$(RANLIB) $(BLASLIB)
+
+FRC:
+	@FRC=$(FRC)
+
+clean:
+	rm -f *.o
+
+
Index: vendor/clapack/blas/SRC/Makefile
===================================================================
RCS file: vendor/clapack/blas/SRC/Makefile
diff -N vendor/clapack/blas/SRC/Makefile
--- vendor/clapack/blas/SRC/Makefile	16 Mar 2006 23:11:40 -0000	1.1.1.1
+++ /dev/null	1 Jan 1970 00:00:00 -0000
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
Index: vendor/clapack/blas/SRC/blaswrap.h
===================================================================
RCS file: /home/cvs/Repository/clapack/BLAS/SRC/blaswrap.h,v
retrieving revision 1.1.1.1
diff -u -r1.1.1.1 blaswrap.h
--- vendor/clapack/blas/SRC/blaswrap.h	16 Mar 2006 23:11:40 -0000	1.1.1.1
+++ vendor/clapack/blas/SRC/blaswrap.h	3 Jun 2006 10:41:20 -0000
@@ -5,6 +5,8 @@
 #ifndef __BLASWRAP_H
 #define __BLASWRAP_H
 
+#define NO_BLAS_WRAP
+
 #ifndef NO_BLAS_WRAP
  
 /* BLAS1 routines */
? examples/png.cpp
Index: examples/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/examples/GNUmakefile.inc.in,v
retrieving revision 1.9
diff -u -r1.9 GNUmakefile.inc.in
--- examples/GNUmakefile.inc.in	1 May 2006 19:36:25 -0000	1.9
+++ examples/GNUmakefile.inc.in	3 Jun 2006 12:13:25 -0000
@@ -20,17 +20,22 @@
 	$(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(examples_cxx_sources))
 cxx_sources += $(examples_cxx_sources)
 
+examples_targets     := examples/example1 examples/png
+
 ########################################################################
 # Rules
 ########################################################################
 
 all:: examples/example1$(EXEEXT)
 
-examples/example1$(EXEEXT): examples/example1.$(OBJEXT) $(libs)
-	$(CXX) $(LDFLAGS) -o $@ $< -Llib -lvsip $(LIBS)
+examples/png: override LIBS += -lvsip_csl -lpng
 
 install::
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)
 	$(INSTALL_DATA) $(examples_cxx_sources) $(DESTDIR)$(pkgdatadir)
 	$(INSTALL_DATA) examples/makefile.standalone \
 	  $(DESTDIR)$(pkgdatadir)/Makefile
+
+$(examples_targets): %$(EXEEXT): %.$(OBJEXT) $(libs)
+	$(CXX) $(LDFLAGS) -o $@ $< -Llib -lvsip $(LIBS)
+
Index: vendor/clapack/SRC/make.inc.in
===================================================================
RCS file: /home/cvs/Repository/clapack/SRC/make.inc.in,v
retrieving revision 1.4
diff -u -r1.4 make.inc.in
--- vendor/clapack/SRC/make.inc.in	29 Mar 2006 16:07:54 -0000	1.4
+++ vendor/clapack/SRC/make.inc.in	3 Jun 2006 12:23:42 -0000
@@ -45,8 +45,8 @@
 #  machine-specific, optimized BLAS library should be used whenever
 #  possible.)
 #
-BLASLIB      = ../../blas$(PLAT).a
-LAPACKLIB    = lapack$(PLAT).a
+BLASLIB      = ../../libcblas$(PLAT).a
+LAPACKLIB    = liblapack$(PLAT).a
 F2CLIB       = ../../F2CLIBS/libF77.a ../../F2CLIBS/libI77.a
 TMGLIB       = tmglib$(PLAT).a
 EIGSRCLIB    = eigsrc$(PLAT).a
