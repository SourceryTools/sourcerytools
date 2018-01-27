Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.344
diff -c -p -r1.344 ChangeLog
*** ChangeLog	21 Dec 2005 04:04:36 -0000	1.344
--- ChangeLog	21 Dec 2005 14:49:33 -0000
***************
*** 1,3 ****
--- 1,12 ----
+ 2005-12-21  Nathan Myers  <ncm@codesourcery.com>
+ 
+ 	* configure.ac, vendor/fftw/simd/sse.c, vendor/fftw/simd/sse2.c:
+ 	  enable using SSE/SSE2 on x86-64.
+ 	* vendor/GNUmakefile.inc.in: improve build status reports.
+ 	* configure.ac, GNUmakefile.in, tests/context.in:
+ 	  rearrange -I, -L so compiler will find internal includes & libs
+ 	  first, installed ones second, environment ones last.
+ 
  2005-12-20  Stefan Seefeld  <stefan@codesourcery.com>
  
  	* synopsis.py.in: Additional code not yet part of the last (0.8) release.
Index: GNUmakefile.in
===================================================================
RCS file: /home/cvs/Repository/vpp/GNUmakefile.in,v
retrieving revision 1.32
diff -c -p -r1.32 GNUmakefile.in
*** GNUmakefile.in	20 Dec 2005 17:10:34 -0000	1.32
--- GNUmakefile.in	21 Dec 2005 14:49:33 -0000
*************** CXXINCLUDES := -I src -I $(srcdir)/src
*** 58,70 ****
  # C++ macro definitions.
  CXXDEFS :=
  # C++ preprocessor flags.
! CXXCPPFLAGS := $(CXXINCLUDES) $(CXXDEFS) @CPPFLAGS@ @INT_CPPFLAGS@
  # C++ compilation flags.
  CXXFLAGS := $(CXXCPPFLAGS) @CXXFLAGS@
  # The extension for executable programs.
  EXEEXT := @EXEEXT@
  # Linker flags.
! LDFLAGS := @LDFLAGS@ @INT_LDFLAGS@
  # Libraries to link to.
  LIBS := @LIBS@
  # The extension for object files.
--- 58,70 ----
  # C++ macro definitions.
  CXXDEFS :=
  # C++ preprocessor flags.
! CXXCPPFLAGS := $(CXXINCLUDES) $(CXXDEFS) @INT_CPPFLAGS@ @CPPFLAGS@
  # C++ compilation flags.
  CXXFLAGS := $(CXXCPPFLAGS) @CXXFLAGS@
  # The extension for executable programs.
  EXEEXT := @EXEEXT@
  # Linker flags.
! LDFLAGS := @INT_LDFLAGS@ @LDFLAGS@
  # Libraries to link to.
  LIBS := @LIBS@
  # The extension for object files.
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.60
diff -c -p -r1.60 configure.ac
*** configure.ac	20 Dec 2005 18:50:29 -0000	1.60
--- configure.ac	21 Dec 2005 14:49:33 -0000
*************** if test "$build_fftw3" != "no"; then
*** 456,466 ****
      fftw3_d_simd=
      fftw3_l_simd=
      case "$host_cpu" in
!       (ia32|i686)        fftw3_f_simd="--enable-sse"
  	                 fftw3_d_simd="--enable-sse2" 
  	                 ;;
-       (x86_64)           fftw3_d_simd=""
- 	                 ;;
        (ppc*)             fftw3_f_simd="--enable-altivec" ;;
      esac
      AC_MSG_NOTICE([fftw3 config options: $fftw3_opts $fftw3_simd.])
--- 456,464 ----
      fftw3_d_simd=
      fftw3_l_simd=
      case "$host_cpu" in
!       (ia32|i686|x86_64) fftw3_f_simd="--enable-sse"
  	                 fftw3_d_simd="--enable-sse2" 
  	                 ;;
        (ppc*)             fftw3_f_simd="--enable-altivec" ;;
      esac
      AC_MSG_NOTICE([fftw3 config options: $fftw3_opts $fftw3_simd.])
*************** if test "$build_fftw3" != "no"; then
*** 523,533 ****
    # fail).  Instead we add them to LATE_LIBS, which gets added to
    # LIBS just before AC_OUTPUT.
  
!   LATE_LIBS="$LATE_LIBS $FFTW3_LIBS"
!   INT_CPPFLAGS="$INT_CPPFLAGS -I$curdir/vendor/fftw/include"
!   INT_LDFLAGS="$INT_LDFLAGS -L$curdir/vendor/fftw/lib"
!   CPPFLAGS="$CPPFLAGS -I$includedir/fftw3"
!   LDFLAGS="$LDFLAGS -L$libdir/fftw3"
  fi
  
  if test "$enable_fftw2" != "no" ; then
--- 521,531 ----
    # fail).  Instead we add them to LATE_LIBS, which gets added to
    # LIBS just before AC_OUTPUT.
  
!   LATE_LIBS="$FFTW3_LIBS $LATE_LIBS"
!   INT_CPPFLAGS="-I$curdir/vendor/fftw/include $INT_CPPFLAGS"
!   INT_LDFLAGS="-L$curdir/vendor/fftw/lib $INT_LDFLAGS"
!   CPPFLAGS="-I$includedir/fftw3 $CPPFLAGS"
!   LDFLAGS="-L$libdir/fftw3 $LDFLAGS"
  fi
  
  if test "$enable_fftw2" != "no" ; then
*************** if test "$with_lapack" != "no"; then
*** 1083,1094 ****
  	# fail).  Instead we add them to LATE_LIBS, which gets added to
  	# LIBS just before AC_OUTPUT.
  
!         LATE_LIBS="$LATE_LIBS -lcsl_lapack -lcsl_cblas -lcsl_f77blas -lcsl_atlas $use_g2c"
  
! 	INT_CPPFLAGS="$INT_CPPFLAGS -I$my_abs_top_srcdir/vendor/atlas/include"
! 	INT_LDFLAGS="$INT_LDFLAGS -L$curdir/vendor/atlas/lib"
!         CPPFLAGS="$keep_CPPFLAGS -I$includedir/atlas"
!         LDFLAGS="$keep_LDFLAGS -L$libdir/atlas"
          LIBS="$keep_LIBS"
          lapack_use_ilaenv=0
          cblas_style="1"	# use cblas.h
--- 1081,1092 ----
  	# fail).  Instead we add them to LATE_LIBS, which gets added to
  	# LIBS just before AC_OUTPUT.
  
!         LATE_LIBS="-lcsl_lapack -lcsl_cblas -lcsl_f77blas -lcsl_atlas $use_g2c $LATE_LIBS"
  
! 	INT_CPPFLAGS="-I$my_abs_top_srcdir/vendor/atlas/include $INT_CPPFLAGS"
! 	INT_LDFLAGS="-L$curdir/vendor/atlas/lib $INT_LDFLAGS"
!         CPPFLAGS="-I$includedir/atlas $keep_CPPFLAGS"
!         LDFLAGS="-L$libdir/atlas $keep_LDFLAGS"
          LIBS="$keep_LIBS"
          lapack_use_ilaenv=0
          cblas_style="1"	# use cblas.h
*************** AC_CHECK_PROGS(XEP, xep)
*** 1231,1237 ****
  AC_PROG_INSTALL
  
  # "Late" variables
! LIBS="$LIBS $LATE_LIBS"
  AC_SUBST(INT_LDFLAGS)
  AC_SUBST(INT_CPPFLAGS)
  
--- 1229,1235 ----
  AC_PROG_INSTALL
  
  # "Late" variables
! LIBS="$LATE_LIBS $LIBS"
  AC_SUBST(INT_LDFLAGS)
  AC_SUBST(INT_CPPFLAGS)
  
Index: tests/context.in
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/context.in,v
retrieving revision 1.4
diff -c -p -r1.4 context.in
*** tests/context.in	1 Dec 2005 16:39:27 -0000	1.4
--- tests/context.in	21 Dec 2005 14:49:33 -0000
***************
*** 1,8 ****
  CompilerTable.languages= cxx
  CompilerTable.cxx_kind= GCC
  CompilerTable.cxx_path= @CXX@
! CompilerTable.cxx_options= -I@abs_top_builddir@/src -I@abs_top_srcdir@/src @CPPFLAGS@ @INT_CPPFLAGS@ @CXXFLAGS@
! CompilerTable.cxx_ldflags= @LDFLAGS@ @INT_LDFLAGS@ @abs_top_builddir@/src/vsip/libvsip.a @LIBS@
  GPPInit.options=
  GPPInit.library_directories= 
  DejaGNUTest.target= @host@
--- 1,8 ----
  CompilerTable.languages= cxx
  CompilerTable.cxx_kind= GCC
  CompilerTable.cxx_path= @CXX@
! CompilerTable.cxx_options= -I@abs_top_builddir@/src -I@abs_top_srcdir@/src @INT_CPPFLAGS@ @CPPFLAGS@ @CXXFLAGS@
! CompilerTable.cxx_ldflags= @INT_LDFLAGS@ @LDFLAGS@ @abs_top_builddir@/src/vsip/libvsip.a @LIBS@
  GPPInit.options=
  GPPInit.library_directories= 
  DejaGNUTest.target= @host@
Index: vendor/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/vendor/GNUmakefile.inc.in,v
retrieving revision 1.3
diff -c -p -r1.3 GNUmakefile.inc.in
*** vendor/GNUmakefile.inc.in	20 Dec 2005 18:50:30 -0000	1.3
--- vendor/GNUmakefile.inc.in	21 Dec 2005 14:49:33 -0000
*************** all:: $(vendor_LIBS)
*** 42,52 ****
  libs:: $(vendor_LIBS)
  
  $(vendor_ATLAS_LIBS):
! 	@echo "Building ATLAS (atlas.build.log)"
  	@$(MAKE) -C vendor/atlas build > atlas.build.log 2>&1
  
  $(vendor_REF_LAPACK):
! 	@echo "Building LAPACK (lapack.build.log)"
  	@$(MAKE) -C vendor/lapack/SRC all > lapack.build.log 2>&1
  
  $(vendor_USE_LAPACK): $(vendor_PRE_LAPACK) $(vendor_REF_LAPACK)
--- 42,52 ----
  libs:: $(vendor_LIBS)
  
  $(vendor_ATLAS_LIBS):
! 	@echo "Building ATLAS (see atlas.build.log)"
  	@$(MAKE) -C vendor/atlas build > atlas.build.log 2>&1
  
  $(vendor_REF_LAPACK):
! 	@echo "Building LAPACK (see lapack.build.log)"
  	@$(MAKE) -C vendor/lapack/SRC all > lapack.build.log 2>&1
  
  $(vendor_USE_LAPACK): $(vendor_PRE_LAPACK) $(vendor_REF_LAPACK)
*************** $(vendor_USE_LAPACK): $(vendor_PRE_LAPAC
*** 57,67 ****
  	rm -rf vendor/atlas/lib/tmp
  
  clean::
! 	@echo "Cleaning ATLAS (atlas.clean.log)"
  	@$(MAKE) -C vendor/atlas clean > atlas.clean.log 2>&1
  
  install::
! 	@echo "Installing ATLAS (atlas.install.log)"
  	# @$(MAKE) -C vendor/atlas installinstall > atlas.install.log 2>&1
  	$(INSTALL) -d $(libdir)/atlas
  	$(INSTALL_DATA) vendor/atlas/lib/libcsl_atlas.a   $(libdir)/atlas
--- 57,67 ----
  	rm -rf vendor/atlas/lib/tmp
  
  clean::
! 	@echo "Cleaning ATLAS (see atlas.clean.log)"
  	@$(MAKE) -C vendor/atlas clean > atlas.clean.log 2>&1
  
  install::
! 	@echo "Installing ATLAS (see atlas.install.log)"
  	# @$(MAKE) -C vendor/atlas installinstall > atlas.install.log 2>&1
  	$(INSTALL) -d $(libdir)/atlas
  	$(INSTALL_DATA) vendor/atlas/lib/libcsl_atlas.a   $(libdir)/atlas
Index: vendor/fftw/simd/sse.c
===================================================================
RCS file: /home/cvs/Repository/fftw/simd/sse.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 sse.c
*** vendor/fftw/simd/sse.c	1 Dec 2005 10:33:03 -0000	1.1.1.1
--- vendor/fftw/simd/sse.c	21 Dec 2005 14:49:35 -0000
*************** static inline int cpuid_edx(int op)
*** 40,45 ****
--- 40,52 ----
            pop ebx
       }
       return ret;
+ #elif defined(__x86_64__)
+      int rax, rcx, rdx;
+ 
+      __asm__("pushq %%rbx\n\tcpuid\n\tpopq %%rbx"
+ 	     : "=a" (rax), "=c" (rcx), "=d" (rdx)
+ 	     : "a" (op));
+      return rdx;
  #else
       int eax, ecx, edx;
  
Index: vendor/fftw/simd/sse2.c
===================================================================
RCS file: /home/cvs/Repository/fftw/simd/sse2.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 sse2.c
*** vendor/fftw/simd/sse2.c	1 Dec 2005 10:33:03 -0000	1.1.1.1
--- vendor/fftw/simd/sse2.c	21 Dec 2005 14:49:35 -0000
*************** static inline int cpuid_edx(int op)
*** 40,45 ****
--- 40,52 ----
            pop ebx
       }
       return ret;
+ #elif defined(__x86_64__)
+      int rax, rcx, rdx;
+ 
+      __asm__("pushq %%rbx\n\tcpuid\n\tpopq %%rbx"
+ 	     : "=a" (rax), "=c" (rcx), "=d" (rdx)
+ 	     : "a" (op));
+      return rdx;
  #else
       int eax, ecx, edx;
  
