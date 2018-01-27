? atlas/autom4te.cache
? atlas/configure
? atlas/CONFIG/acconfig.hpp.in
? atlas/bin/Makefile.in
? atlas/interfaces/blas/C/src/Makefile.in
? atlas/interfaces/blas/C/testing/Makefile.in
? atlas/interfaces/blas/F77/src/Makefile.in
? atlas/interfaces/blas/F77/testing/Makefile.in
? atlas/interfaces/lapack/C/src/Makefile.in
? atlas/interfaces/lapack/F77/src/Makefile.in
? atlas/lib/Makefile.in
? atlas/src/auxil/Makefile.in
? atlas/src/blas/gemm/Make.inc.in
? atlas/src/blas/gemm/Makefile.in
? atlas/src/blas/gemm/GOTO/Makefile.in
? atlas/src/blas/gemv/Make.inc.in
? atlas/src/blas/gemv/Makefile.in
? atlas/src/blas/ger/Make.inc.in
? atlas/src/blas/ger/Makefile.in
? atlas/src/blas/level1/Make.inc.in
? atlas/src/blas/level1/Makefile.in
? atlas/src/blas/level2/Makefile.in
? atlas/src/blas/level2/kernel/Makefile.in
? atlas/src/blas/level3/Makefile.in
? atlas/src/blas/level3/kernel/Makefile.in
? atlas/src/blas/level3/rblas/Makefile.in
? atlas/src/blas/pklevel3/Makefile.in
? atlas/src/blas/pklevel3/gpmm/Makefile.in
? atlas/src/blas/pklevel3/sprk/Makefile.in
? atlas/src/blas/reference/level1/Makefile.in
? atlas/src/blas/reference/level2/Makefile.in
? atlas/src/blas/reference/level3/Makefile.in
? atlas/src/lapack/Makefile.in
? atlas/src/pthreads/blas/level1/Makefile.in
? atlas/src/pthreads/blas/level2/Makefile.in
? atlas/src/pthreads/blas/level3/Makefile.in
? atlas/src/pthreads/misc/Makefile.in
? atlas/src/testing/Makefile.in
? atlas/tune/blas/gemm/Makefile.in
? atlas/tune/blas/gemv/Makefile.in
? atlas/tune/blas/ger/Makefile.in
? atlas/tune/blas/level1/Makefile.in
? atlas/tune/blas/level3/Makefile.in
? atlas/tune/sysinfo/Makefile.in
? clapack/blas/SRC/GNUmakefile.in
? clapack/blas/SRC/xerbla_new.c
Index: GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/vendor/GNUmakefile.inc.in,v
retrieving revision 1.16
diff -u -r1.16 GNUmakefile.inc.in
--- GNUmakefile.inc.in	5 Jun 2006 17:57:20 -0000	1.16
+++ GNUmakefile.inc.in	13 Jun 2006 18:26:36 -0000
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
+vendor_SIMPLE_BLAS = vendor/clapack/libblas.a
 
 
 vendor_ATLAS_LIBS :=				\
@@ -95,7 +97,6 @@
 $(vendor_LIBF77):
 	@echo "Building libF77 (see libF77.build.log)"
 	@$(MAKE) -C vendor/clapack/F2CLIBS/libF77 all > libF77.build.log 2>&1
-	@ln -s `pwd`/vendor/clapack/F2CLIBS/libF77/libF77.a vendor/atlas/lib/libF77.a
 
 
 install:: $(vendor_LIBF77)
@@ -106,7 +107,6 @@
 	@$(MAKE) -C vendor/clapack/F2CLIBS/libF77 clean > libF77.clean.log 2>&1
 endif
 
-
 clean::
 	@echo "Cleaning ATLAS (see atlas.clean.log)"
 	@$(MAKE) -C vendor/atlas clean > atlas.clean.log 2>&1
@@ -125,6 +125,58 @@
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
+install:: $(vendor_SIMPLE_BLAS)
+	$(INSTALL_DATA) $(vendor_SIMPLE_BLAS) $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) $(vendor_REF_LAPACK) $(DESTDIR)$(libdir)/liblapack.a
+	$(INSTALL_DATA) $(srcdir)/vendor/clapack/SRC/cblas.h $(DESTDIR)$(includedir)
+
+endif # USE_SIMPLE_LAPACK
 
 
 
@@ -166,7 +218,7 @@
 all:: $(vendor_FFTW_LIBS)
 	@rm -rf vendor/fftw/include
 	@mkdir -p vendor/fftw/include
-	@ln -s $(abs_srcdir)/vendor/fftw/api/fftw3.h vendor/fftw/include/fftw3.h
+	@ln -s $(srcdir)/vendor/fftw/api/fftw3.h vendor/fftw/include/fftw3.h
 	@rm -rf vendor/fftw/lib
 	@mkdir -p vendor/fftw/lib
 	@for lib in $(vendor_FFTW_LIBS); do \
Index: clapack/SRC/GNUmakefile.in
===================================================================
RCS file: /home/cvs/Repository/clapack/SRC/GNUmakefile.in,v
retrieving revision 1.2
diff -u -r1.2 GNUmakefile.in
--- clapack/SRC/GNUmakefile.in	21 Mar 2006 21:41:07 -0000	1.2
+++ clapack/SRC/GNUmakefile.in	13 Jun 2006 18:26:37 -0000
@@ -46,7 +46,15 @@
 
 OBJDIR = $(PLATFORM)
 
-BLASWR = cblaswr.o crotg.o zrotg.o
+
+USE_SIMPLE_LAPACK  := @USE_SIMPLE_LAPACK@
+
+# If SIMPLE_LAPACK is not defined, we need to include this object because it
+# has the f2c_ functions. If it is defined, we don't need this file
+ifdef USE_SIMPLE_LAPACK
+BLASWR = cblaswr.o
+endif
+BLASWR += crotg.o zrotg.o
  
 ALLAUX = ilaenv.o ieeeck.o lsame.o lsamen.o xerbla.o
 
Index: clapack/SRC/make.inc.in
===================================================================
RCS file: /home/cvs/Repository/clapack/SRC/make.inc.in,v
retrieving revision 1.4
diff -u -r1.4 make.inc.in
--- clapack/SRC/make.inc.in	29 Mar 2006 16:07:54 -0000	1.4
+++ clapack/SRC/make.inc.in	13 Jun 2006 18:26:37 -0000
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
Index: clapack/blas/SRC/blaswrap.h
===================================================================
RCS file: /home/cvs/Repository/clapack/BLAS/SRC/blaswrap.h,v
retrieving revision 1.1.1.1
diff -u -r1.1.1.1 blaswrap.h
--- clapack/blas/SRC/blaswrap.h	16 Mar 2006 23:11:40 -0000	1.1.1.1
+++ clapack/blas/SRC/blaswrap.h	13 Jun 2006 18:26:37 -0000
@@ -5,6 +5,8 @@
 #ifndef __BLASWRAP_H
 #define __BLASWRAP_H
 
+#define NO_BLAS_WRAP
+
 #ifndef NO_BLAS_WRAP
  
 /* BLAS1 routines */
Index: clapack/blas/SRC/f2c.h
===================================================================
RCS file: /home/cvs/Repository/clapack/BLAS/SRC/f2c.h,v
retrieving revision 1.1.1.1
diff -u -r1.1.1.1 f2c.h
--- clapack/blas/SRC/f2c.h	16 Mar 2006 23:11:40 -0000	1.1.1.1
+++ clapack/blas/SRC/f2c.h	13 Jun 2006 18:26:37 -0000
@@ -7,7 +7,9 @@
 #ifndef F2C_INCLUDE
 #define F2C_INCLUDE
 
-typedef long int integer;
+// integer was orinally long int. On some machines long int is 64 bits, however
+// FORTRAN requires ints to be 32 bits
+typedef int integer;
 typedef unsigned long uinteger;
 typedef char *address;
 typedef short int shortint;
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.105
diff -u -r1.105 configure.ac
--- configure.ac	14 May 2006 20:57:05 -0000	1.105
+++ configure.ac	13 Jun 2006 18:27:11 -0000
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
 
@@ -460,6 +461,9 @@
  AC_MSG_RESULT(yes)],
 [AC_MSG_RESULT([no])])
 
+AC_CHECK_HEADERS([png.h], 
+                 [AC_SUBST(HAVE_PNG_H, 1)], 
+                 [], [// no prerequisites])
 
 #
 # Check for the exp10 function.  
@@ -492,6 +496,9 @@
 #endif])
 vsip_impl_avoid_posix_memalign=
 
+AC_CHECK_HEADERS([png.h], 
+                 [AC_SUBST(HAVE_PNG_H, 1)], 
+                 [], [// no prerequisites])
 
 #
 # Find the FFT backends.
@@ -1275,6 +1282,8 @@
     lapack_packages="atlas generic1 generic2 builtin"
   elif test "$with_lapack" == "generic"; then
     lapack_packages="generic1 generic2"
+  elif test "$with_lapack" == "simple-builtin"; then
+    lapack_packages="simple-builtin";
   else
     lapack_packages="$with_lapack"
   fi
@@ -1515,6 +1524,25 @@
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
+      AC_SUBST(USE_BUILTIN_LIBF77, 1)
+      AC_SUBST(USE_SIMPLE_LAPACK, 1)
+      
+      lapack_use_ilaenv=0
+      lapack_found="simple-builtin"
+      break
     fi
 
 
