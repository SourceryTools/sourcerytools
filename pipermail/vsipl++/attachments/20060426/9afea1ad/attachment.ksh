Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.437
diff -u -r1.437 ChangeLog
--- ChangeLog	26 Apr 2006 13:07:18 -0000	1.437
+++ ChangeLog	26 Apr 2006 14:22:50 -0000
@@ -1,3 +1,30 @@
+2006-04-26  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (--with-lapack): Support both CLAPACK and Fortran
+	  LAPACK.  Use CLAPACK and libF77 when option is 'builtin'.  
+	  Use Fortran LAPACK and libg2c when option is 'fortran-builtin'.
+	  Substitute USE_FORTRAN_LAPACK and USE_BUILTIN_LIBF77.
+	  (--disable-builtin-lapack): Remove option.
+	* src/vsip/map.hpp (impl_global_from_local_index): Fix Wall warning.
+	* src/vsip/impl/fns_scalar.hpp: Move ::hypotf extern decl to top-level
+	  namespace.
+	* tests/convolution.cpp: Fix invalid reference to rand when
+	  TEST_LEVEL == 0.
+	* vendor/GNUmakefile.inc.in: Allow either Fortran LAPACK or
+	  C LAPACK to be built, depending on USE_FORTRAN_LAPACK AC_SUBST.
+	  Build LibF77 if USE_BUILTIN_LIBF77 AC_SUBST is set.
+	* vendor/atlas/configure.ac: Use test "=" instead "==" to improve
+	  portability.
+	  (CCFLAGS_OPT and MMFLAGS_OPT): New SUBST to pass known good
+	  optimization flags for specific architecture-compilers.
+	* vendor/atlas/Make.ARCH.in: Use CCFLAGS_OPT and MMFLAGS_OPT.
+	* vendor/clapack/F2CLIBS/libF77/GNUmakefile.in: New file, makefile
+	  for libF77.
+	* vendor/clapack/F2CLIBS/libF77/f2c.h: Make integer typedef consistent
+	  with SRC/f2c.h
+	* vendor/clapack/F2CLIBS/libF77/sig_die.c: Remove call to f_exit.
+	  Only necessary if Fortran I/O (libI77) is being used.
+	
 2006-04-26  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* configure.ac: Add tests for hypotf and logf, which don't exist
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.92
diff -u -r1.92 configure.ac
--- configure.ac	26 Apr 2006 13:07:18 -0000	1.92
+++ configure.ac	26 Apr 2006 14:22:50 -0000
@@ -183,17 +183,11 @@
   AS_HELP_STRING([--with-lapack\[=PKG\]],
                  [enable use of LAPACK if found
                   (default is to not search for it).  Optionally, the
-		  specific LAPACK library (mkl7, mkl5, atlas, generic, or
-		  builtin) to use can be specified with PKG]),,
+		  specific LAPACK library (mkl7, mkl5, atlas, generic,
+		  builtin, or fortran-builtin) to use can be specified
+		  with PKG]),,
   [with_lapack=no])
 
-AC_ARG_ENABLE([builtin_lapack],
-  AS_HELP_STRING([--disable-builtin-lapack],
-                 [disable use of builtin LAPACK (default is to use it if
-		 LAPACK is enabled by no installed LAPACK library is
-		 found).]),,
-  [enable_builtin_lapack="yes"])
-
 AC_ARG_WITH(atlas_prefix,
   AS_HELP_STRING([--with-atlas-prefix=PATH],
                  [specify the installation prefix of the ATLAS library.
@@ -1188,7 +1182,8 @@
     LIBS="$LIBS $with_g2c_path/libg2c.a"
   fi
 
-  status="unknown-failure"
+  status="not found"
+  detailstatus="unknown-failure"
   AC_MSG_CHECKING([for g2c $try])
   AC_LANG([Fortran 77])
   AC_COMPILE_IFELSE([
@@ -1207,16 +1202,17 @@
         AC_LANG_SOURCE([[
 	  int main() { return 0; }
 	  ]])],
-       [status="link-success"],
-       [status="link-failure"])
+       [status="found"
+        detailstatus="link-success"],
+       [detailstatus="link-failure"])
       LDFLAGS="$keep_LDFLAGS"
       rm conftest2.$ac_objext
     ],
-    [status="compile-failure"])
+    [detailstatus="compile-failure"])
 
   LIBS="$keep_LIBS"
   AC_MSG_RESULT([$status])
-  if test $status == "link-success"; then
+  if test $detailstatus == "link-success"; then
     use_g2c="$tenative_use_g2c"
     break
   fi
@@ -1272,11 +1268,7 @@
 
     lapack_packages="mkl7 mkl5"
   elif test "$with_lapack" == "yes"; then
-    if test "$enable_builtin_lapack" == "yes"; then
-      lapack_packages="atlas generic1 generic2 builtin"
-    else
-      lapack_packages="atlas generic1 generic2"
-    fi
+    lapack_packages="atlas generic1 generic2 builtin"
   elif test "$with_lapack" == "generic"; then
     lapack_packages="generic1 generic2"
   else
@@ -1345,11 +1337,17 @@
       LIBS="$keep_LIBS -llapack -lblas"
       cblas_style="0"	# no cblas.h
       lapack_use_ilaenv=0
-    elif test "$trypkg" == "builtin"; then
-      AC_MSG_CHECKING([for built-in ATLAS library])
+    elif test "$trypkg" == "builtin" -o "$trypkg" == "fortran-builtin"; then
+
+      if test "$trypkg" == "fortran-builtin"; then
+        AC_MSG_CHECKING([for built-in ATLAS/F77-LAPACK library])
+      else
+        AC_MSG_CHECKING([for built-in ATLAS/C-LAPACK library])
+      fi
+
       if test -e "$srcdir/vendor/atlas/configure"; then
-        if test $use_g2c == "error"; then
-          AC_MSG_RESULT([skipping (g2c needed but not found)])
+        if test "$trypkg" == "fortran-builtin" -a $use_g2c == "error"; then
+          AC_MSG_RESULT([skipping (libg2c needed but not found)])
 	  continue
         fi
         AC_MSG_RESULT([found])
@@ -1442,7 +1440,18 @@
 	# fail).  Instead we add them to LATE_LIBS, which gets added to
 	# LIBS just before AC_OUTPUT.
 
-        LATE_LIBS="-llapack -lcblas -lf77blas -latlas $use_g2c $LATE_LIBS"
+	if test "$trypkg" == "fortran-builtin"; then
+	  # When using Fortran LAPACK, we need ATLAS' f77blas (it
+	  # provides the Fortran BLAS bindings) and we need libg2c.
+          LATE_LIBS="-llapack -lcblas -lf77blas -latlas $use_g2c $LATE_LIBS"
+          AC_SUBST(USE_FORTRAN_LAPACK, 1)
+        else
+	  # When using C LAPACK, we need libF77 (the builtin equivalent
+	  # of libg2c).
+          LATE_LIBS="-llapack -lF77 -lcblas -latlas $LATE_LIBS"
+          AC_SUBST(USE_BUILTIN_LIBF77, 1)
+          ln -s ../../clapack/F2CLIBS/libF77/libF77.a vendor/atlas/lib/libF77.a
+        fi
 
 	INT_CPPFLAGS="-I$my_abs_top_srcdir/vendor/atlas/include $INT_CPPFLAGS"
 	INT_LDFLAGS="-L$curdir/vendor/atlas/lib $INT_LDFLAGS"
Index: src/vsip/map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/map.hpp,v
retrieving revision 1.22
diff -u -r1.22 map.hpp
--- src/vsip/map.hpp	27 Mar 2006 23:19:34 -0000	1.22
+++ src/vsip/map.hpp	26 Apr 2006 14:22:50 -0000
@@ -729,10 +729,10 @@
 
   switch (d)
   {
+  default: assert(false);
   case 0: return dist0_.impl_global_from_local_index(dom_[0], dim_sb[0], idx);
   case 1: return dist1_.impl_global_from_local_index(dom_[1], dim_sb[1], idx);
   case 2: return dist2_.impl_global_from_local_index(dom_[2], dim_sb[2], idx);
-  default: assert(false);
   }
 }
 
Index: src/vsip/impl/fns_scalar.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fns_scalar.hpp,v
retrieving revision 1.16
diff -u -r1.16 fns_scalar.hpp
--- src/vsip/impl/fns_scalar.hpp	26 Apr 2006 13:07:18 -0000	1.16
+++ src/vsip/impl/fns_scalar.hpp	26 Apr 2006 14:22:50 -0000
@@ -22,6 +22,14 @@
 #include <cstdlib> // ghs imports ::abs into std here.
 #include <complex>
 
+#if !HAVE_DECL_HYPOTF
+# if HAVE_HYPOTF
+extern float hypotf(float, float);
+# endif
+#endif
+
+
+
 namespace vsip
 {
 namespace impl
@@ -92,12 +100,6 @@
 #endif // !HAVE_DECL_EXP10L
 }
 
-#if !defined(HAVE_DECL_HYPOTF)
-#if defined(HAVE_HYPOTF)
-extern float hypotf(float, float);
-# endif
-#endif
-
 template <typename T1,
 	  typename T2,
 	  typename T3>
Index: tests/convolution.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/convolution.cpp,v
retrieving revision 1.11
diff -u -r1.11 convolution.cpp
--- tests/convolution.cpp	7 Mar 2006 02:15:22 -0000	1.11
+++ tests/convolution.cpp	26 Apr 2006 14:22:50 -0000
@@ -485,7 +485,7 @@
 
 #if VSIP_IMPL_TEST_LEVEL == 0
   cases<float>(true);
-  cases<complex<float> >(rand);
+  cases<complex<float> >(true);
 #else
 
   // Regression: These cases trigger undefined behavior according to
Index: vendor/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/vendor/GNUmakefile.inc.in,v
retrieving revision 1.12
diff -u -r1.12 GNUmakefile.inc.in
--- vendor/GNUmakefile.inc.in	21 Mar 2006 21:40:16 -0000	1.12
+++ vendor/GNUmakefile.inc.in	26 Apr 2006 14:22:50 -0000
@@ -12,16 +12,26 @@
 # Variables
 ########################################################################
 
-USE_BUILTIN_ATLAS := @USE_BUILTIN_ATLAS@
+USE_BUILTIN_ATLAS  := @USE_BUILTIN_ATLAS@
+USE_FORTRAN_LAPACK := @USE_FORTRAN_LAPACK@
+USE_BUILTIN_LIBF77 := @USE_BUILTIN_LIBF77@
 USE_BUILTIN_FFTW  := @USE_BUILTIN_FFTW@
 USE_BUILTIN_FFTW_FLOAT := @USE_BUILTIN_FFTW_FLOAT@
 USE_BUILTIN_FFTW_DOUBLE := @USE_BUILTIN_FFTW_DOUBLE@
 USE_BUILTIN_FFTW_LONG_DOUBLE := @USE_BUILTIN_FFTW_LONG_DOUBLE@
 
-vendor_REF_CLAPACK= vendor/clapack/lapack.a
-vendor_REF_LAPACK = vendor/lapack/lapack.a
+vendor_CLAPACK    = vendor/clapack/lapack.a
+vendor_FLAPACK    = vendor/lapack/lapack.a
 vendor_PRE_LAPACK = vendor/atlas/lib/libprelapack.a
 vendor_USE_LAPACK = vendor/atlas/lib/liblapack.a
+ifdef USE_FORTRAN_LAPACK
+  vendor_REF_LAPACK = $(vendor_FLAPACK)
+else
+  vendor_REF_LAPACK = $(vendor_CLAPACK)
+endif
+
+vendor_LIBF77      = vendor/clapack/F2CLIBS/libF77/libF77.a
+
 
 vendor_ATLAS_LIBS :=				\
 	vendor/atlas/lib/libatlas.a		\
@@ -37,7 +47,7 @@
 
 
 ########################################################################
-# Rules
+# ATLAS Rules
 ########################################################################
 
 ifdef USE_BUILTIN_ATLAS
@@ -49,27 +59,51 @@
 	@echo "Building ATLAS (see atlas.build.log)"
 	@$(MAKE) -C vendor/atlas build > atlas.build.log 2>&1
 
-$(vendor_REF_CLAPACK):
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
 	@echo "Building CLAPACK (see clapack.build.log)"
 	@$(MAKE) -C vendor/clapack/SRC all > clapack.build.log 2>&1
 
+clean::
+	@echo "Cleaning CLAPACK (see clapack.clean.log)"
+	@$(MAKE) -C vendor/clapack/SRC clean > clapack.clean.log 2>&1
+endif
 
-$(vendor_REF_LAPACK):
-	@echo "Building LAPACK (see lapack.build.log)"
-	@$(MAKE) -C vendor/lapack/SRC all > lapack.build.log 2>&1
-
-$(vendor_USE_LAPACK): $(vendor_PRE_LAPACK) $(vendor_REF_CLAPACK)
+$(vendor_USE_LAPACK): $(vendor_PRE_LAPACK) $(vendor_REF_LAPACK)
 	mkdir -p vendor/atlas/lib/tmp
-	pushd vendor/atlas/lib/tmp; ar x ../../../../$(vendor_PRE_LAPACK); popd
-	cp $(vendor_REF_CLAPACK) $(vendor_USE_LAPACK)
-	pushd vendor/atlas/lib/tmp; ar r ../../../../$(vendor_USE_LAPACK); popd
+	cd vendor/atlas/lib/tmp; ar x ../../../../$(vendor_PRE_LAPACK); cd ../../../..
+	cp $(vendor_REF_LAPACK) $(vendor_USE_LAPACK)
+	cd vendor/atlas/lib/tmp; ar r ../../../../$(vendor_USE_LAPACK); cd ../../../..
 	rm -rf vendor/atlas/lib/tmp
 
+
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
+clean::
+	@echo "Cleaning libF77 (see libF77.clean.log)"
+	@$(MAKE) -C vendor/clapack/F2CLIBS/libF77 clean > libF77.clean.log 2>&1
+endif
+
+
 clean::
 	@echo "Cleaning ATLAS (see atlas.clean.log)"
 	@$(MAKE) -C vendor/atlas clean > atlas.clean.log 2>&1
-	@echo "Cleaning CLAPACK (see clapack.clean.log)"
-	@$(MAKE) -C vendor/clapack/SRC clean > clapack.clean.log 2>&1
 
 install:: $(vendor_LIBS)
 	@echo "Installing ATLAS (see atlas.install.log)"
@@ -83,6 +117,12 @@
 	$(INSTALL_DATA) $(srcdir)/vendor/atlas/include/cblas.h $(DESTDIR)$(includedir)
 endif
 
+
+
+########################################################################
+# FFTW Rules
+########################################################################
+
 ifdef USE_BUILTIN_FFTW
 
 ifdef USE_BUILTIN_FFTW_FLOAT
Index: vendor/atlas/Make.ARCH.in
===================================================================
RCS file: /home/cvs/Repository/atlas/Make.ARCH.in,v
retrieving revision 1.1
diff -u -r1.1 Make.ARCH.in
--- vendor/atlas/Make.ARCH.in	1 Dec 2005 14:43:17 -0000	1.1
+++ vendor/atlas/Make.ARCH.in	26 Apr 2006 14:22:50 -0000
@@ -112,9 +112,9 @@
    GOODGCC = @GOODGCC@
    CC = @CC@
    CCFLAG0 = @CFLAGS@
-   CCFLAGS = $(CDEFS) $(CCFLAG0)
+   CCFLAGS = $(CDEFS) $(CCFLAG0) @CCFLAGS_OPT@
    MCC = @MCC@
-   MMFLAGS = @MMFLAGS@
+   MMFLAGS = @MMFLAGS@ @MMFLAGS_OPT@
    XCC = @XCC@
    XCCFLAGS = @XCCFLAGS@
    CLINKER  = @CLINKER@
Index: vendor/atlas/configure.ac
===================================================================
RCS file: /home/cvs/Repository/atlas/configure.ac,v
retrieving revision 1.3
diff -u -r1.3 configure.ac
--- vendor/atlas/configure.ac	20 Jan 2006 04:52:46 -0000	1.3
+++ vendor/atlas/configure.ac	26 Apr 2006 14:22:50 -0000
@@ -91,7 +91,7 @@
 #
 # Set ar
 #
-if test "x$AR" == "x"; then
+if test "x$AR" = "x"; then
   AR="ar"
 fi
 
@@ -104,7 +104,7 @@
 # --------------------------------------------------------------------
 os_name=`uname -s`
 
-# if test "$os_name" == "Linux"; then
+# if test "$os_name" = "Linux"; then
 # fi
 
 
@@ -114,8 +114,8 @@
 
 mach_is_ppc=""		# true if PowerPC architecture
 
-if test "$mach" == "probe"; then
- if test "$os_name" == "Linux"; then
+if test "$mach" = "probe"; then
+ if test "$os_name" = "Linux"; then
   la=`uname -m`
 
   case $la in
@@ -130,7 +130,7 @@
   mach="unknown"
 
   echo "linux arch $la"
-  if test "$la" == "ppc"; then
+  if test "$la" = "ppc"; then
     mach_is_ppc="true"
     model=`fgrep -m 1 cpu /proc/cpuinfo`
 
@@ -156,14 +156,14 @@
   # ALPHA
   # IA64
   # X86
-  if test "$la" == "x86_32"; then
+  if test "$la" = "x86_32"; then
     model=`fgrep -m 1 'model name' /proc/cpuinfo`
-    if test "x$model" == "x"; then
+    if test "x$model" = "x"; then
       model=`fgrep -m 1 model /proc/cpuinfo`
     fi
 
     if test "`echo $model | sed -n /Pentium/p`" != ""; then
-      if test "`echo $model | sed -n /III/p`" == "match"; then
+      if test "`echo $model | sed -n /III/p`" = "match"; then
         mach="PIII"
       elif test "`echo $model | sed -n '/ II/p'`" != ""; then
         mach="PII"
@@ -183,9 +183,9 @@
     elif test "`echo $model | sed -n '/Opteron/p'`" != ""; then
       mach="HAMMER32"
     fi
-  elif test "$la" == "x86_64"; then
+  elif test "$la" = "x86_64"; then
     model=`fgrep -m 1 'model name' /proc/cpuinfo`
-    if test "x$model" == "x"; then
+    if test "x$model" = "x"; then
       model=`fgrep -m 1 model /proc/cpuinfo`
     fi
 
@@ -201,9 +201,16 @@
       mach="HAMMER64"
     fi
   fi
+ elif test "$os_name" = "SunOS"; then
+  AC_MSG_ERROR(["Use --with-mach=XXX to specify mach type."])
  fi
 fi
 
+# Atlas treats SunUSX as a SunUS2.
+if test "$mach" = "SunUSX"; then
+  mach=SunUS2
+fi
+
 echo "mach: $mach"
 
 mach_is_x86_32=""	# true if x86 architecture
@@ -216,6 +223,8 @@
     mach_is_x86_32="true" ;;
   P4E64 | HAMMER64 )
     mach_is_x86_64="true" ;;
+  SunMS | SunSS | SunUS1 | SunUS2 | SunUS4 | SunUS5 | SunUSIII | SunUSX )
+    mach_is_us="true" ;;
 esac
   
 
@@ -226,13 +235,13 @@
 
 AC_MSG_CHECKING([for asm style])
 
-if test "$mach_is_x86_32" == "true"; then
+if test "$mach_is_x86_32" = "true"; then
   asmd="GAS_x8632"
-elif test "$mach_is_x86_64" == "true"; then
+elif test "$mach_is_x86_64" = "true"; then
   asmd="GAS_x8664"
-elif test "$mach_is_us" == "true"; then
+elif test "$mach_is_us" = "true"; then
   asmd="GAS_SPARC"
-elif test "$mach_is_ppc" == "true"; then
+elif test "$mach_is_ppc" = "true"; then
   asmd="GAS_LINUX_PPC"
 else
   AC_MSG_ERROR([cannot determine asm type.])
@@ -247,16 +256,16 @@
 # --------------------------------------------------------------------
 
 # Check for AltiVec
-if test "$with_isa" == "probe"; then
+if test "$with_isa" = "probe"; then
   AC_MSG_CHECKING([for AltiVec ISA])
 
   altivec_cfgs="altivec1 altivec2"
   old_CFLAGS="$CFLAGS"
   for try_cfg in $altivec_cfgs; do
-    if test "$try_cfg" == "altivec1"; then
+    if test "$try_cfg" = "altivec1"; then
       # gcc
       CFLAGS="$CFLAGS -maltivec -mabi=altivec"
-    elif test "$try_cfg" == "altivec2"; then
+    elif test "$try_cfg" = "altivec2"; then
       # OSX
       CFLAGS="$CFLAGS -faltivec"
     fi
@@ -303,7 +312,7 @@
     CFLAGS=$old_CFLAGS
   done
 
-  if test "$with_isa" == "AltiVec"; then
+  if test "$with_isa" = "AltiVec"; then
     AC_MSG_RESULT([FOUND.])
   else
     AC_MSG_RESULT([not found.])
@@ -311,7 +320,7 @@
 fi
 
 # --------------------------------------------------------------------
-if test "$with_isa" == "probe"; then
+if test "$with_isa" = "probe"; then
   AC_MSG_CHECKING([for SSE3])
 
   AC_RUN_IFELSE([
@@ -369,19 +378,19 @@
   [with_isa="SSE3"
    break])
 
-  if test "$with_isa" == "SSE3"; then
+  if test "$with_isa" = "SSE3"; then
     AC_MSG_RESULT([FOUND.])
   else
     AC_MSG_RESULT([not found.])
   fi
 fi
 
-if test "$with_isa" == "SSE3"; then
+if test "$with_isa" = "SSE3"; then
   ARCHDEFS="$ARCHDEFS -DATL_SSE1 -DATL_SSE2 -DATL_SSE3"
 fi
 
 # --------------------------------------------------------------------
-if test "$with_isa" == "probe"; then
+if test "$with_isa" = "probe"; then
   AC_MSG_CHECKING([for SSE2])
 
   AC_RUN_IFELSE([
@@ -447,20 +456,20 @@
   [with_isa="SSE2"
    break])
 
-  if test "$with_isa" == "SSE2"; then
+  if test "$with_isa" = "SSE2"; then
     AC_MSG_RESULT([FOUND.])
   else
     AC_MSG_RESULT([not found.])
   fi
 fi
 
-if test "$with_isa" == "SSE2"; then
+if test "$with_isa" = "SSE2"; then
   ARCHDEFS="$ARCHDEFS -DATL_SSE1 -DATL_SSE2"
 fi
 
 
 # --------------------------------------------------------------------
-if test "$with_isa" == "probe"; then
+if test "$with_isa" = "probe"; then
   AC_MSG_CHECKING([for SSE1])
 
   AC_RUN_IFELSE([
@@ -527,19 +536,19 @@
   [with_isa="SSE1"
    break])
 
-  if test "$with_isa" == "SSE1"; then
+  if test "$with_isa" = "SSE1"; then
     AC_MSG_RESULT([FOUND.])
   else
     AC_MSG_RESULT([not found.])
   fi
 fi
 
-if test "$with_isa" == "SSE1"; then
+if test "$with_isa" = "SSE1"; then
   ARCHDEFS="$ARCHDEFS -DATL_SSE1"
 fi
 
 # --------------------------------------------------------------------
-if test "$with_isa" == "probe"; then
+if test "$with_isa" = "probe"; then
   if test "$disable_3dnow" != "yes"; then
   AC_MSG_CHECKING([for 3DNow2])
 
@@ -613,7 +622,7 @@
   [with_isa="3DNow2"
    break])
 
-  if test "$with_isa" == "3DNow2"; then
+  if test "$with_isa" = "3DNow2"; then
     AC_MSG_RESULT([FOUND.])
   else
     AC_MSG_RESULT([not found.])
@@ -621,13 +630,13 @@
 fi
 fi
 
-if test "$with_isa" == "3DNow2"; then
+if test "$with_isa" = "3DNow2"; then
   ARCHDEFS="$ARCHDEFS -DATL_3DNow2"
 fi
 
 
 # --------------------------------------------------------------------
-if test "$with_isa" == "probe"; then
+if test "$with_isa" = "probe"; then
   if test "$disable_3dnow" != "yes"; then
   AC_MSG_CHECKING([for 3DNow1])
 
@@ -700,7 +709,7 @@
   [with_isa="3DNow1"
    break])
 
-  if test "$with_isa" == "3DNow1"; then
+  if test "$with_isa" = "3DNow1"; then
     AC_MSG_RESULT([FOUND.])
   else
     AC_MSG_RESULT([not found.])
@@ -708,11 +717,11 @@
 fi
 fi
 
-if test "$with_isa" == "3DNow1"; then
+if test "$with_isa" = "3DNow1"; then
   ARCHDEFS="$ARCHDEFS -DATL_3DNow1"
 fi
 
-if test "$with_isa" == "probe"; then
+if test "$with_isa" = "probe"; then
   with_isa="none"
 fi
 
@@ -729,14 +738,14 @@
 
 # This is a cheap workaround to Linux_21164GOTO error, forcing use
 # of the non-goto defaults on such a platform
-if test "$mach" == "21164"; then
+if test "$mach" = "21164"; then
   if test "$disable_goto_gemm" != "yes"; then
     UMMdir='$(TOPdir)/src/blas/gemm/GOTO/$(ARCH)'
     UMMDEF='-DEV5'
     usermm_name='GOTO'
   fi
 fi
-if test "$mach" == "21264"; then
+if test "$mach" = "21264"; then
   if test "$disable_goto_gemm" != "yes"; then
     UMMdir='$(TOPdir)/src/blas/gemm/GOTO/$(ARCH)'
     UMMDEF='-DEV6'
@@ -749,15 +758,15 @@
 # Probe threads
 # --------------------------------------------------------------------
 
-if test "$use_threads" == "yes"; then
+if test "$use_threads" = "yes"; then
   AC_MSG_ERROR([Threaded ATLAS not supported.])
 
   THREAD_CDEFS="-DATL_NCPU=$ncpu"
-  if test $os_name == "FreeBSD"; then
+  if test $os_name = "FreeBSD"; then
     THREAD_CDEFS="$THREAD_CDEFS -D_THREAD_SAFE -D_REENTRANT"
-  elif test $os_name == "AIX"; then
+  elif test $os_name = "AIX"; then
     THREAD_CDEFS="$THREAD_CDEFS -DIBM_PT_ERROR"
-  elif test $os_name == "IRIX"; then
+  elif test $os_name = "IRIX"; then
     THREAD_CDEFS="$THREAD_CDEFS -D_POSIX_C_SOURCE=199506L"
   fi
 else
@@ -779,7 +788,7 @@
 fi
 ARCH0="$ARCH0$usermm_name"
 
-if test $os_name == "Other"; then
+if test $os_name = "Other"; then
   ARCH="UNKNOWN"
 else
   ARCH=$os_name
@@ -787,7 +796,7 @@
 
 ARCH="${ARCH}_$ARCH0"
 
-if test "$use_threads" == "yes"; then
+if test "$use_threads" = "yes"; then
   ARCH="${ARCH}_$ncpu"
 fi
 
@@ -888,7 +897,7 @@
 # Probe cache size
 AC_MSG_CHECKING([for L2 cache size])
 size="0"
-if test $os_name == "Linux"; then
+if test $os_name = "Linux"; then
   case $mach in
     PII | PIII | PPRO | ATHLON | HAMMER32 | HAMMER64 )
       line=`fgrep 'cache size' /proc/cpuinfo`
@@ -907,10 +916,12 @@
       AC_MSG_ERROR([Linux/PPCG4 L2 cache size not implemented])
       ;;
   esac
-elif test $os_name == "IRIX"; then
+elif test $os_name = "IRIX"; then
   AC_MSG_ERROR([Cannot determine L2 cache size for IRIX])
-elif test $os_name == "AIX"; then
+elif test $os_name = "AIX"; then
   AC_MSG_ERROR([Cannot determine L2 cache size for AIX])
+elif test $os_name = "SunOS"; then
+  size=0
 else
   AC_MSG_ERROR([Cannot determine L2 cache size for $os_name])
 fi
@@ -920,11 +931,11 @@
 if test "$size" != "0"; then
   # Get flush multiple
   imul="0"
-  if test $os_name == "AIX"; then
+  if test $os_name = "AIX"; then
     AC_MSG_ERROR([Configuration of ATLAS for AIX not supported.])
   fi
 
-  if test $imul == "0"; then
+  if test $imul = "0"; then
     case $mach in
       21164 | ATHLON | HAMMER32 | HAMMER64 | \
       SunUS1 | SunUS2 | SunUSIII | SunUS4 | SunUS5 | SunUSX | \
@@ -949,6 +960,35 @@
 # Compiler Info
 # --------------------------------------------------------------------
 
+AC_MSG_CHECKING([C compiler family])
+if test "$ac_cv_c_compiler_gnu" = "yes"; then
+  AC_MSG_RESULT([GCC])
+  use_cc="gcc"
+elif expr "$CC" : ".*icc" > /dev/null; then
+  AC_MSG_RESULT([ICC])
+  use_cc="icc"
+else
+  AC_MSG_RESULT([other ($CC))])
+  use_cc="$CC"
+fi
+
+
+AC_MSG_CHECKING([mach/compiler specific flags])
+specflags="none"
+case $mach in
+  SunUS1 | SunUS2 | SunUS4 | SunUS5 | SunUSIII )
+    if test "$use_cc" = "gcc"; then
+      specflags="UltraSparc GCC"
+      CCFLAGS_OPT="-mcpu=ultrasparc -mtune=ultrasparc -fomit-frame-pointer -O"
+      MMFLAGS_OPT="-mcpu=ultrasparc -mtune=ultrasparc -fomit-frame-pointer -O3"
+    fi
+    ;;
+esac
+AC_MSG_RESULT([$specflags])
+
+AC_SUBST(CCFLAGS_OPT)
+AC_SUBST(MMFLAGS_OPT)
+
 # GetSyslib
 # Find tar, gzip, gunzip
 
@@ -967,13 +1007,13 @@
 
 AC_F77_FUNC(C_ROUTINE, [MANGLE])
 
-if test "$MANGLE" == "c_routine_"; then
+if test "$MANGLE" = "c_routine_"; then
   f2c_namedef="-DAdd_"
-elif test "$MANGLE" == "c_routine__"; then
+elif test "$MANGLE" = "c_routine__"; then
   f2c_namedef="-DAdd__"
-elif test "$MANGLE" == "c_routine"; then
+elif test "$MANGLE" = "c_routine"; then
   f2c_namedef="-DNoChange"
-elif test "$MANGLE" == "C_ROUTINE"; then
+elif test "$MANGLE" = "C_ROUTINE"; then
   f2c_namedef="-DUpCase"
 fi
 
@@ -983,7 +1023,7 @@
 # Determine C type corresponding to Fortran integer
 # --------------------------------------------------------------------
 
-if test "$with_int_type" == "probe"; then
+if test "$with_int_type" = "probe"; then
   AC_MSG_CHECKING([for C type corresponding to Fortran integer])
   with_int_type="none"
 
@@ -1048,7 +1088,7 @@
   CPPFLAGS="$old_CPPFLAGS"
   AC_LANG_RESTORE()
 
-  if test "$with_int_type" == "none"; then
+  if test "$with_int_type" = "none"; then
     AC_MSG_ERROR([cannot determine C type for FORTRAN INTEGER.])
   else
     AC_MSG_RESULT([$with_int_type.])
@@ -1061,7 +1101,7 @@
 # Determine Fortran string calling convention
 # --------------------------------------------------------------------
 
-if test "$with_string_convention" == "probe"; then
+if test "$with_string_convention" = "probe"; then
   AC_MSG_CHECKING([for Fortran string calling convention.])
   string_conventions="-DSunStyle -DCrayStyle -DStringStructVal -DStringStructPtr"
 
@@ -1171,7 +1211,7 @@
        res=`cat conftestval`
        rm -f conftestval
       ])
-    if test "$res" == "yes"; then
+    if test "$res" = "yes"; then
       use_conv="$try_conv"
       break
     fi
@@ -1179,22 +1219,22 @@
   CPPFLAGS="$old_CPPFLAGS"
   AC_LANG_RESTORE()
 
-  if test "$use_conv" == "none"; then
+  if test "$use_conv" = "none"; then
     AC_MSG_ERROR([unknown FORTRAN string convention.])
   else
     AC_MSG_RESULT([using $use_conv.])
   fi
-elif test "$with_string_convention" == "sun"; then
+elif test "$with_string_convention" = "sun"; then
   use_conv="-DSunStyle"
-elif test "$with_string_convention" == "cray"; then
+elif test "$with_string_convention" = "cray"; then
   use_conv="-DCrayStyle"
-elif test "$with_string_convention" == "structval"; then
+elif test "$with_string_convention" = "structval"; then
   use_conv="-DStringStructVal"
-elif test "$with_string_convention" == "structptr"; then
+elif test "$with_string_convention" = "structptr"; then
   use_conv="-DStringStructPtr"
 fi
 
-if test "$with_int_type" == "int"; then
+if test "$with_int_type" = "int"; then
   # If F77_INTEGER == int, leave it undefined here so that it will be
   # defined by atlas_f77.h ... otherwise FunkyInts will get defined too.
   F2CDEFS="$f2c_namedef $use_conv"
@@ -1228,14 +1268,15 @@
 # Check for Architecture Defaults
 # --------------------------------------------------------------------
 
-if test "$ARCH0" == "US4"; then
-  use_arch="US2"
+if test "$ARCH0" = "SunUS4"; then
+  use_arch="SunUS2"
 else
   use_arch="$ARCH0"
 fi
 
 AC_MSG_CHECKING([for architectural defaults (CONFIG/ARCHS/$use_arch.tgz)])
-if test -e "$srcdir/CONFIG/ARCHS/$use_arch.tgz"; then
+echo DIR "$srcdir/CONFIG/ARCHS/$use_arch.tgz"
+if test -f "$srcdir/CONFIG/ARCHS/$use_arch.tgz"; then
   AC_MSG_RESULT([found.])
   mkdir -p CONFIG/ARCHS
   gunzip -c $srcdir/CONFIG/ARCHS/$use_arch.tgz | tar xf - -C CONFIG/ARCHS
@@ -1243,18 +1284,6 @@
   AC_MSG_ERROR([NOT FOUND.])
 fi
 
-AC_MSG_CHECKING([C compiler family])
-if test "$ac_cv_c_compiler_gnu" == "yes"; then
-  AC_MSG_RESULT([GCC])
-  use_cc="gcc"
-elif expr "$CC" : ".*icc" > /dev/null; then
-  AC_MSG_RESULT([ICC])
-  use_cc="icc"
-else
-  AC_MSG_RESULT([other ($CC))])
-  use_cc="$CC"
-fi
-
 ARCHBASE='$(TOPdir)/CONFIG/ARCHS'
 ARCHDEF="$ARCHBASE/$use_arch/$use_cc/misc"
 MMDEF="$ARCHBASE/$use_arch/$use_cc/gemm"
@@ -1298,9 +1327,9 @@
 FLINKFLAGS='$(F77FLAGS)'
 FCLINKFLAGS='$(FLINKFLAGS)'
 
-if test $mach == "HP9735"; then
-  if test $os_name == "HPUX"; then
-    if test $F77 == "f77"; then
+if test $mach = "HP9735"; then
+  if test $os_name = "HPUX"; then
+    if test $F77 = "f77"; then
       FLINKFLAGS="-Aa"
     fi
     if test $CC != "gcc"; then
@@ -1309,10 +1338,10 @@
   fi
 fi
 
-if test $F77 == "xlf"; then
+if test $F77 = "xlf"; then
   FLINKFLAGS="FLINKFLAGS -bmaxdata:0x70000000"
 fi
-if test $CC == "xlc"; then
+if test $CC = "xlc"; then
   CLINKFLAGS="FLINKFLAGS -bmaxdata:0x70000000"
 fi
 
@@ -1327,7 +1356,7 @@
 AC_SUBST(UCDEF)
 
 # file open delay
-if test "$enable_delay" == "yes"; then
+if test "$enable_delay" = "yes"; then
   DELAY_CDEF="-DATL_FOPENDELAY"
   delay="1"
 else
@@ -1399,7 +1428,7 @@
 mkdir -p bin/$ARCH/INSTALL_LOG
 
 # refresh
-if test "0" == "1"; then
+if test "0" = "1"; then
 #jpb# cp $srcdir/makes/Make.bin bin/$ARCH/Makefile
 cp $srcdir/makes/Make.lib lib/$ARCH/Makefile
 cp $srcdir/makes/Make.aux src/auxil/$ARCH/Makefile
Index: vendor/clapack/F2CLIBS/libF77/GNUmakefile.in
===================================================================
RCS file: vendor/clapack/F2CLIBS/libF77/GNUmakefile.in
diff -N vendor/clapack/F2CLIBS/libF77/GNUmakefile.in
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ vendor/clapack/F2CLIBS/libF77/GNUmakefile.in	26 Apr 2006 14:22:50 -0000
@@ -0,0 +1,77 @@
+########################################################################
+#
+# File:   GNUmakefile.in
+# Author: Jules Bergmann
+# Date:   2006-04-25
+#
+# Contents: Makefile for CLAPACK/F2CLIBS/libF77
+#
+########################################################################
+
+.SUFFIXES: .c .o
+
+srcdir  = @srcdir@
+
+VPATH   = $(srcdir)
+
+CC	= @CC@
+CFLAGS	= @CLAPACK_CFLAGS@
+
+# If your system lacks onexit() and you are not using an
+# ANSI C compiler, then you should add -DNO_ONEXIT to CFLAGS,
+# e.g., by changing the above "CFLAGS =" line to
+# CFLAGS = -O -DNO_ONEXIT
+
+# On at least some Sun systems, it is more appropriate to change the
+# "CFLAGS =" line to
+# CFLAGS = -O -Donexit=on_exit
+
+.c.o:
+	$(CC) -c -DSkip_f2c_Undefs $(CFLAGS) $<
+
+# We don't need to include main.o, signal_.o, and s_paus.o when building
+# clapack for VSIPL++.
+MISC =	F77_aloc.o Version.o s_rnge.o abort_.o getarg_.o iargc_.o \
+	getenv_.o s_stop.o system_.o cabs.o\
+	derf_.o derfc_.o erf_.o erfc_.o sig_die.o exit_.o
+POW =	pow_ci.o pow_dd.o pow_di.o pow_hh.o pow_ii.o  pow_ri.o pow_zi.o pow_zz.o
+CX =	c_abs.o c_cos.o c_div.o c_exp.o c_log.o c_sin.o c_sqrt.o
+DCX =	z_abs.o z_cos.o z_div.o z_exp.o z_log.o z_sin.o z_sqrt.o
+REAL =	r_abs.o r_acos.o r_asin.o r_atan.o r_atn2.o r_cnjg.o r_cos.o\
+	r_cosh.o r_dim.o r_exp.o r_imag.o r_int.o\
+	r_lg10.o r_log.o r_mod.o r_nint.o r_sign.o\
+	r_sin.o r_sinh.o r_sqrt.o r_tan.o r_tanh.o
+DBL =	d_abs.o d_acos.o d_asin.o d_atan.o d_atn2.o\
+	d_cnjg.o d_cos.o d_cosh.o d_dim.o d_exp.o\
+	d_imag.o d_int.o d_lg10.o d_log.o d_mod.o\
+	d_nint.o d_prod.o d_sign.o d_sin.o d_sinh.o\
+	d_sqrt.o d_tan.o d_tanh.o
+INT =	i_abs.o i_dim.o i_dnnt.o i_indx.o i_len.o i_mod.o i_nint.o i_sign.o
+HALF =	h_abs.o h_dim.o h_dnnt.o h_indx.o h_len.o h_mod.o  h_nint.o h_sign.o
+CMP =	l_ge.o l_gt.o l_le.o l_lt.o hl_ge.o hl_gt.o hl_le.o hl_lt.o
+EFL =	ef1asc_.o ef1cmc_.o
+CHAR =	F77_aloc.o s_cat.o s_cmp.o s_copy.o
+F90BIT = lbitbits.o lbitshft.o
+QINT =	pow_qq.o qbitbits.o qbitshft.o
+TIME =	dtime_.o etime_.o
+
+all: libF77.a
+
+# You may need to adjust signal1.h suitably for your system...
+signal1.h: signal1.h0
+	cp signal1.h0 signal1.h
+
+# If you get an error compiling dtime_.c or etime_.c, try adding
+# -DUSE_CLOCK to the CFLAGS assignment above; if that does not work,
+# omit $(TIME) from the dependency list for libF77.a below.
+
+# For INTEGER*8 support (which requires system-dependent adjustments to
+# f2c.h), add $(QINT) to the libf2c.a dependency list below...
+
+libF77.a : $(MISC) $(POW) $(CX) $(DCX) $(REAL) $(DBL) $(INT) \
+	$(HALF) $(CMP) $(EFL) $(CHAR) $(F90BIT) $(TIME)
+	ar r libF77.a $?
+	-ranlib libF77.a
+
+clean:
+	rm -f libF77.a *.o
Index: vendor/clapack/F2CLIBS/libF77/f2c.h
===================================================================
RCS file: /home/cvs/Repository/clapack/F2CLIBS/libF77/f2c.h,v
retrieving revision 1.1.1.1
diff -u -r1.1.1.1 f2c.h
--- vendor/clapack/F2CLIBS/libF77/f2c.h	16 Mar 2006 23:11:42 -0000	1.1.1.1
+++ vendor/clapack/F2CLIBS/libF77/f2c.h	26 Apr 2006 14:22:50 -0000
@@ -7,7 +7,11 @@
 #ifndef F2C_INCLUDE
 #define F2C_INCLUDE
 
-typedef long int integer;
+// We don't want integer to be 64 bits!!
+// integer was originally defined as long int, this causes some problems
+// on 64bit machines because a long int is 64 bits. The FORTRAN 'integer' was
+// originally 32 bits
+typedef int integer;
 typedef unsigned long uinteger;
 typedef char *address;
 typedef short int shortint;
Index: vendor/clapack/F2CLIBS/libF77/sig_die.c
===================================================================
RCS file: /home/cvs/Repository/clapack/F2CLIBS/libF77/sig_die.c,v
retrieving revision 1.1.1.1
diff -u -r1.1.1.1 sig_die.c
--- vendor/clapack/F2CLIBS/libF77/sig_die.c	16 Mar 2006 23:11:42 -0000	1.1.1.1
+++ vendor/clapack/F2CLIBS/libF77/sig_die.c	26 Apr 2006 14:22:50 -0000
@@ -25,8 +25,11 @@
 	if(kill)
 		{
 		fflush(stderr);
-		f_exit();
-		fflush(stderr);
+		// Calling f_exit() is only necessary if we're using
+		// libI77.
+		//
+		// f_exit();
+		// fflush(stderr);
 		/* now get a core */
 #ifdef SIGIOT
 		signal(SIGIOT, SIG_DFL);
