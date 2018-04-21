Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.314
diff -c -p -r1.314 ChangeLog
*** ChangeLog	28 Nov 2005 16:54:21 -0000	1.314
--- ChangeLog	29 Nov 2005 20:24:10 -0000
***************
*** 1,3 ****
--- 1,81 ----
+ 2005-11-29 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	Integrate ATLAS and LAPACK into VSIPL++ source tree.
+ 	* autogen.sh: process configure.ac in vendor/atlas directory.
+ 	* configure.ac: Configuration support for builtin lapack library.
+           (disable-builtin-lapack): New option to disable
+ 	  consideration of builtin lapack (ATLAS).
+ 	  (--with-lapack): New option to specify lapack library(libraries)
+ 	  to consider.
+ 	* GNUmakefile.in (LDFLAGS): Add internal ld flags (@INT_LDFLAGS@).
+ 	  (libs): New target for libraries necessary to build executables.
+ 	* src/vsip/GNUmakefile.inc.in (libs): Add dependency to
+ 	  src/vsip/libvsip.a
+ 	* examples/GNUmakefile.inc.in: Add dependency to 'libs' target.
+ 	* tests/GNUmakefile.inc.in (check): Add dependency to libs.
+ 	* tests/context.in (cxx_options): Add internal ld flags (@INT_LDFLAGS@)
+ 	* vendor/GNUmakefile.inc.in: New file, brige from VSIPL++
+ 	  integrate makefile to ATLAS and LAPACK build/make.
+ 
+ 	Autoconf for ATLAS.
+ 	* vendor/atlas/autogen.sh: New file, generate vendor/atlas
+ 	  configure scripts.
+ 	* vendor/atlas/configure.ac: New file, autoconf script for ATLAS.
+ 	* vendor/atlas/csl-scripts/convert-makefile.pl: New file, convert
+ 	  ATLAS makes/Make.xxx files to CSL Makefile.in files.
+ 	* vendor/atlas/csl-scripts/create-makeinc.pl: New file, create
+ 	  per-directory Make.inc files.
+ 	* vendor/atlas/csl-scripts/convert.sh: New file, wrapper around
+ 	  convert-makefile.pl and create-makeinc.pl.  Called by autogen.sh.
+ 	* vendor/atlas/GNUmakefile.in: New file, top-level makefile for
+ 	  ATLAS.
+ 	* vendor/atlas/Make.ARCH.in: New file, template Make.ARCH file.
+ 	* vendor/atlas/bin/ATLrun.sh.in: New file, script to run executable.
+ 
+ 	* vendor/atlas/tune/blas/gemm/tfc.c: Fix bug causing heap
+ 	  corruption.
+ 
+ 	Misc. changes to build atlas out of the source directory
+ 	and prevent compiler warnings.
+ 	* vendor/atlas/makes/Make.bin: Support build dir different from
+ 	  source dir.
+ 	* vendor/atlas/tune/blas/gemm/emit_mm.c: Increase string size to
+ 	  avoid overrun.  Support build dir different from source dir.
+ 	* vendor/atlas/bin/atlas_install.c: Assert that defaults are found.
+ 	* vendor/atlas/bin/atlas_tee.c: Add missing include.
+ 	* vendor/atlas/bin/atlas_waitfile.c: Likewise.
+ 	* vendor/atlas/bin/ccobj.c: Likewise.
+ 	* vendor/atlas/include/contrib/ATL_gemv_ger_SSE.h: Likewise.
+ 	* vendor/atlas/src/auxil/ATL_buildinfo.c: Likewise.
+ 	* vendor/atlas/tune/blas/gemm/usercomb.c: Likewise.
+ 	* vendor/atlas/tune/blas/gemv/gemvtune.c: Likewise.
+ 	* vendor/atlas/tune/blas/ger/ger1tune.c: Likewise.
+ 	* vendor/atlas/tune/blas/gemv/mvsearch.c: Add missing include,
+ 	  automatically rerun if variation exceeds tolerance.
+ 	* vendor/atlas/tune/blas/ger/r1search.c: Likewise.
+ 	* vendor/atlas/tune/blas/gemm/ummsearch.c: Support build dir
+ 	  different from source dir.
+ 	* vendor/atlas/tune/blas/gemm/userindex.c: Likewise.
+ 	* vendor/atlas/tune/blas/level1/asumsrch.c: Likewise.
+ 	* vendor/atlas/tune/blas/level1/axpbysrch.c: Likewise.
+ 	* vendor/atlas/tune/blas/level1/axpysrch.c: Likewise.
+ 	* vendor/atlas/tune/blas/level1/copysrch.c: Likewise.
+ 	* vendor/atlas/tune/blas/level1/cpscsrch.c: Likewise.
+ 	* vendor/atlas/tune/blas/level1/dotsrch.c: Likewise.
+ 	* vendor/atlas/tune/blas/level1/iamaxsrch.c: Likewise.
+ 	* vendor/atlas/tune/blas/level1/nrm2srch.c: Likewise.
+ 	* vendor/atlas/tune/blas/level1/rotsrch.c: Likewise.
+ 	* vendor/atlas/tune/blas/level1/scalsrch.c: Likewise.
+ 	* vendor/atlas/tune/blas/level1/setsrch.c: Likewise.
+ 	* vendor/atlas/tune/blas/level1/swapsrch.c: Likewise.
+ 	* vendor/atlas/tune/sysinfo/masearch.c: Add missing headers.
+ 	  Put missing headers in generated programs.
+ 
+ 	Fit LAPACK into autoconf build.
+ 	* vendor/lapack/make.inc.in: LAPACK make include template.
+ 	* vendor/lapack/SRC/GNUmakefile.in: New file, Makefile
+ 	  template for LAPACK.
+ 
  2005-11-28 Jules Bergmann  <jules@codesourcery.com>
  
  	* src/vsip/impl/extdata.hpp (is_direct_ok): Merge if statements to
Index: GNUmakefile.in
===================================================================
RCS file: /home/cvs/Repository/vpp/GNUmakefile.in,v
retrieving revision 1.25
diff -c -p -r1.25 GNUmakefile.in
*** GNUmakefile.in	10 Nov 2005 05:44:02 -0000	1.25
--- GNUmakefile.in	29 Nov 2005 20:24:10 -0000
*************** CXXFLAGS := $(CXXCPPFLAGS) @CXXFLAGS@
*** 60,66 ****
  # The extension for executable programs.
  EXEEXT := @EXEEXT@
  # Linker flags.
! LDFLAGS := @LDFLAGS@
  # Libraries to link to.
  LIBS := @LIBS@
  # The extension for object files.
--- 60,66 ----
  # The extension for executable programs.
  EXEEXT := @EXEEXT@
  # Linker flags.
! LDFLAGS := @LDFLAGS@ @INT_LDFLAGS@
  # Libraries to link to.
  LIBS := @LIBS@
  # The extension for object files.
*************** endif
*** 295,300 ****
--- 295,303 ----
  .PHONY: all
  all::
  
+ .PHONY: libs
+ libs::
+ 
  .PHONY: depend
  depend:: 
  
Index: autogen.sh
===================================================================
RCS file: /home/cvs/Repository/vpp/autogen.sh,v
retrieving revision 1.1
diff -c -p -r1.1 autogen.sh
*** autogen.sh	31 Mar 2005 21:10:48 -0000	1.1
--- autogen.sh	29 Nov 2005 20:24:10 -0000
***************
*** 5,7 ****
--- 5,11 ----
  autoheader
  # Generate 'configure' from 'configure.ac'
  autoconf
+ 
+ cd vendor/atlas
+ autogen.sh
+ cd ../..
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.50
diff -c -p -r1.50 configure.ac
*** configure.ac	28 Nov 2005 16:54:21 -0000	1.50
--- configure.ac	29 Nov 2005 20:24:10 -0000
*************** AC_ARG_ENABLE([lapack],
*** 103,108 ****
--- 103,120 ----
                   [use LAPACK if found (default is to not search for it)]),,
    [enable_lapack=no])
  
+ AC_ARG_ENABLE([builtin_lapack],
+   AS_HELP_STRING([--disable-builtin-lapack],
+                  [disable use of builtin LAPACK (default is to use if
+                  no other LAPACK found).]),,
+   [enable_builtin_lapack="yes"])
+ 
+ AC_ARG_ENABLE([lapack],
+   AS_HELP_STRING([--with-lapack=PKG],
+                  [Specify lapack library to use: mkl7, mkl5, atlas, generic, or
+ 		  builtin]),
+   [enable_lapack="yes"])
+ 
  AC_ARG_WITH(atlas_prefix,
    AS_HELP_STRING([--with-atlas-prefix=PATH],
                   [specify the installation prefix of the ATLAS library.
*************** AC_ARG_ENABLE([cpu_mhz],
*** 140,146 ****
  #
  
  # Find all template files and strip off the $srcdir and .in suffix.
! templates=`find $srcdir -name '_darcs' -prune -o -name '*.in' -print | 
             sed -e "s,^$srcdir/,,g" -e 's,\.in$,,g'`
  
  AC_CONFIG_FILES([$templates])
--- 152,163 ----
  #
  
  # Find all template files and strip off the $srcdir and .in suffix.
! templates=`find $srcdir -name '_darcs' -prune -o	\
! 	 -name 'atlas' -prune -o			\
! 	 -name 'TIMING' -prune -o			\
! 	 -name 'TESTING' -prune -o			\
! 	 -name 'BLAS' -prune -o				\
! 	 -name '*.in' -print | 
             sed -e "s,^$srcdir/,,g" -e 's,\.in$,,g'`
  
  AC_CONFIG_FILES([$templates])
*************** AC_CANONICAL_HOST
*** 155,160 ****
--- 172,178 ----
  # Find the compiler.
  #
  AC_PROG_CXX
+ AC_PROG_F77
  if test "x$obj_ext" != "x"; then
    OBJEXT="$obj_ext"
    ac_cv_objext="$obj_ext"
*************** fi
*** 712,717 ****
--- 730,736 ----
  #
  # Find the lapack library, if enabled.
  #
+ echo "enable_lapack: $enable_lapack"
  if test "$enable_lapack" != "no"; then
    keep_CPPFLAGS=$CPPFLAGS
    keep_LDFLAGS=$LDFLAGS
*************** if test "$enable_lapack" != "no"; then
*** 722,728 ****
    elif test "$enable_lapack" == "atlas"; then
      lapack_packages="atlas"
    else
!     lapack_packages="atlas lapack"
    fi
  
    for trypkg in $lapack_packages; do
--- 741,753 ----
    elif test "$enable_lapack" == "atlas"; then
      lapack_packages="atlas"
    else
!     if test "$with_lapack" != ""; then
!       lapack_packages="$with_lapack"
!     elif test "$enable_builtin_lapack" == "yes"; then
!       lapack_packages="atlas generic builtin"
!     else
!       lapack_packages="atlas generic"
!     fi
    fi
  
    for trypkg in $lapack_packages; do
*************** if test "$enable_lapack" != "no"; then
*** 757,766 ****
        LIBS="$keep_LIBS -llapack -lcblas -lf77blas -latlas -lg2c"
  
        lapack_use_ilaenv=0
!     else
        AC_MSG_CHECKING([for LAPACK/Generic library])
        LIBS="$keep_LIBS -llapack"
        lapack_use_ilaenv=0
      fi
  
      lapack_found="no"
--- 782,845 ----
        LIBS="$keep_LIBS -llapack -lcblas -lf77blas -latlas -lg2c"
  
        lapack_use_ilaenv=0
!     elif test "$trypkg" == "generic"; then
        AC_MSG_CHECKING([for LAPACK/Generic library])
        LIBS="$keep_LIBS -llapack"
        lapack_use_ilaenv=0
+     elif test "$trypkg" == "builtin"; then
+       AC_MSG_CHECKING([for built-in ATLAS library])
+       if test -e "$srcdir/vendor/atlas/configure"; then
+         AC_MSG_RESULT([found])
+ 
+         # assert(NOT CROSS-COMPILING)
+ 
+         echo "==============================================================="
+ 
+         mkdir -p vendor/atlas
+         cd vendor/atlas
+ 	rm -rf Make.ARCH
+         if test -e "$srcdir/vendor/atlas/configure"; then
+ 	  atlas_configure="$srcdir/vendor/atlas/configure"
+         elif test -e "../../$srcdir/vendor/atlas/configure"; then
+ 	  atlas_configure="../../$srcdir/vendor/atlas/configure"
+         else
+           AC_MSG_RESULT([Cannot find vendor/atlas/configure after cd.])
+         fi
+ 	$atlas_configure --with-libprefix=csl_
+         cd ../..
+ 
+         echo "==============================================================="
+ 
+ 	if test -f "vendor/atlas/Make.ARCH"; then
+           AC_MSG_RESULT([built-in ATLAS configur successful.])
+ 	else
+           AC_MSG_ERROR([built-in ATLAS configure FAILED.])
+ 	fi
+ 
+ 
+         AC_SUBST(USE_BUILTIN_ATLAS, 1)
+ 
+ 	curdir=`pwd`
+ 	
+ 	# These libraries have not been built yet so we have to wait before
+ 	# adding the to LIBS (otherwise subsequent AC_LINK_IFELSE's will
+ 	# fail).  Instead we add them to LATE_LIBS, which gets added to
+ 	# LIBS just before AC_OUTPUT.
+ 
+         LATE_LIBS="$LATE_LIBS -lcsl_lapack -lcsl_cblas -lcsl_f77blas -lcsl_atlas -lg2c"
+ 
+ 	INT_LDFLAGS="$INT_LDFLAGS -L$curdir/vendor/atlas/lib"
+         LDFLAGS="$keep_LDFLAGS -L$libdir/lib/atlas"
+         CPPFLAGS="$keep_CPPFLAGS"
+         LIBS="$keep_LIBS"
+         lapack_use_ilaenv=0
+ 
+         lapack_found="builtin"
+         break
+       else
+         AC_MSG_RESULT([not present])
+ 	continue
+       fi
      fi
  
      lapack_found="no"
*************** if test "$enable_cpu_mhz" != "none"; the
*** 863,868 ****
--- 942,955 ----
      [Hardcoded CPU Speed (in MHz).])
  fi
  
+ #
+ # library
+ #
+ ARFLAGS="r"
+ RANLIB="echo"
+ 
+ AC_SUBST(ARFLAGS)
+ AC_SUBST(RANLIB)
  
  #
  # Documentation
*************** AC_CHECK_PROGS(XEP, xep)
*** 876,881 ****
--- 963,973 ----
  # 
  AC_PROG_INSTALL
  
+ # "Late" variables
+ LIBS="$LIBS $LATE_LIBS"
+ AC_SUBST(INT_LDFLAGS)
+ 
+ 
  #
  # Done.
  #
Index: examples/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/examples/GNUmakefile.inc.in,v
retrieving revision 1.4
diff -c -p -r1.4 GNUmakefile.inc.in
*** examples/GNUmakefile.inc.in	4 Aug 2005 11:53:02 -0000	1.4
--- examples/GNUmakefile.inc.in	29 Nov 2005 20:24:10 -0000
*************** cxx_sources += $(examples_cxx_sources)
*** 26,32 ****
  
  all:: examples/example1$(EXEEXT)
  
! examples/example1$(EXEEXT): examples/example1.$(OBJEXT) src/vsip/libvsip.a
  	$(CXX) $(LDFLAGS) -o $@ $< -Lsrc/vsip -lvsip $(LIBS)
  
  install::
--- 26,32 ----
  
  all:: examples/example1$(EXEEXT)
  
! examples/example1$(EXEEXT): examples/example1.$(OBJEXT) libs
  	$(CXX) $(LDFLAGS) -o $@ $< -Lsrc/vsip -lvsip $(LIBS)
  
  install::
Index: src/vsip/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/GNUmakefile.inc.in,v
retrieving revision 1.7
diff -c -p -r1.7 GNUmakefile.inc.in
*** src/vsip/GNUmakefile.inc.in	14 Oct 2005 14:07:45 -0000	1.7
--- src/vsip/GNUmakefile.inc.in	29 Nov 2005 20:24:10 -0000
*************** cxx_sources += $(src_vsip_cxx_sources)
*** 34,39 ****
--- 34,41 ----
  
  all:: src/vsip/libvsip.a
  
+ libs:: src/vsip/libvsip.a
+ 
  clean::
  	rm -f src/vsip/libvsip.a
  
Index: src/vsip/impl/eval-blas.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/eval-blas.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 eval-blas.hpp
*** src/vsip/impl/eval-blas.hpp	11 Nov 2005 00:08:21 -0000	1.2
--- src/vsip/impl/eval-blas.hpp	29 Nov 2005 20:24:10 -0000
*************** struct Evaluator<Op_prod_mm, Block0, Op_
*** 442,451 ****
--- 442,466 ----
  {
    typedef typename Block0::value_type T;
  
+   static bool const is_block0_interleaved =
+     !Is_complex<typename Block0::value_type>::value ||
+     Type_equal<typename Block_layout<Block0>::complex_type,
+ 	       Cmplx_inter_fmt>::value;
+   static bool const is_block1_interleaved =
+     !Is_complex<typename Block1::value_type>::value ||
+     Type_equal<typename Block_layout<Block1>::complex_type,
+ 	       Cmplx_inter_fmt>::value;
+   static bool const is_block2_interleaved =
+     !Is_complex<typename Block2::value_type>::value ||
+     Type_equal<typename Block_layout<Block2>::complex_type,
+ 	       Cmplx_inter_fmt>::value;
+ 
    static bool const ct_valid = 
      impl::blas::Blas_traits<T>::valid &&
      Type_equal<T, typename Block1::value_type>::value &&
      Type_equal<T, typename Block2::value_type>::value &&
+     // check that data is interleaved
+     is_block0_interleaved && is_block1_interleaved && is_block2_interleaved &&
      // check that direct access is supported
      Ext_data_cost<Block0>::value == 0 &&
      Ext_data_cost<Block1>::value == 0 &&
Index: tests/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/GNUmakefile.inc.in,v
retrieving revision 1.4
diff -c -p -r1.4 GNUmakefile.inc.in
*** tests/GNUmakefile.inc.in	20 Jul 2005 20:42:41 -0000	1.4
--- tests/GNUmakefile.inc.in	29 Nov 2005 20:24:10 -0000
*************** tests_qmtest_extensions = \
*** 20,26 ****
  # Rules
  ########################################################################
  
! check::	src/vsip/libvsip.a $(tests_qmtest_extensions)
  	cd tests && qmtest run
  
  tests/QMTest/%: $(srcdir)/tests/QMTest/%
--- 20,26 ----
  # Rules
  ########################################################################
  
! check::	libs $(tests_qmtest_extensions)
  	cd tests && qmtest run
  
  tests/QMTest/%: $(srcdir)/tests/QMTest/%
Index: tests/context.in
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/context.in,v
retrieving revision 1.2
diff -c -p -r1.2 context.in
*** tests/context.in	19 May 2005 01:46:01 -0000	1.2
--- tests/context.in	29 Nov 2005 20:24:10 -0000
*************** CompilerTable.languages= cxx
*** 2,8 ****
  CompilerTable.cxx_kind= GCC
  CompilerTable.cxx_path= @CXX@
  CompilerTable.cxx_options= -I@abs_top_builddir@/src -I@abs_top_srcdir@/src @CPPFLAGS@ @CXXFLAGS@
! CompilerTable.cxx_ldflags= @LDFLAGS@ @abs_top_builddir@/src/vsip/libvsip.a @LIBS@
  GPPInit.options=
  GPPInit.library_directories= 
  DejaGNUTest.target= @host@
--- 2,8 ----
  CompilerTable.cxx_kind= GCC
  CompilerTable.cxx_path= @CXX@
  CompilerTable.cxx_options= -I@abs_top_builddir@/src -I@abs_top_srcdir@/src @CPPFLAGS@ @CXXFLAGS@
! CompilerTable.cxx_ldflags= @LDFLAGS@ @INT_LDFLAGS@ @abs_top_builddir@/src/vsip/libvsip.a @LIBS@
  GPPInit.options=
  GPPInit.library_directories= 
  DejaGNUTest.target= @host@
Index: vendor/GNUmakefile.inc.in
===================================================================
RCS file: vendor/GNUmakefile.inc.in
diff -N vendor/GNUmakefile.inc.in
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- vendor/GNUmakefile.inc.in	29 Nov 2005 20:24:10 -0000
***************
*** 0 ****
--- 1,70 ----
+ ########################################################################
+ #
+ # File:   GNUmakefile.inc.in
+ # Author: Jules Beregmann
+ # Date:   2005-11-22
+ #
+ # Contents: Makefile fragment for vendor
+ #
+ ########################################################################
+ 
+ ########################################################################
+ # Variables
+ ########################################################################
+ 
+ USE_BUILTIN_ATLAS := @USE_BUILTIN_ATLAS@
+ 
+ vendor_REF_LAPACK = vendor/lapack/lapack.a
+ vendor_PRE_LAPACK = vendor/atlas/lib/libcsl_prelapack.a
+ vendor_USE_LAPACK = vendor/atlas/lib/libcsl_lapack.a
+ 
+ vendor_ATLAS_LIBS :=				\
+ 	vendor/atlas/lib/libcsl_atlas.a		\
+ 	vendor/atlas/lib/libcsl_cblas.a		\
+ 	vendor/atlas/lib/libcsl_f77blas.a	\
+ 	$(vendor_PRE_LAPACK)
+ 
+ vendor_LIBS :=					\
+ 	vendor/atlas/lib/libcsl_atlas.a		\
+ 	vendor/atlas/lib/libcsl_cblas.a		\
+ 	vendor/atlas/lib/libcsl_f77blas.a	\
+ 	$(vendor_USE_LAPACK)
+ 
+ 
+ ########################################################################
+ # Rules
+ ########################################################################
+ 
+ ifdef USE_BUILTIN_ATLAS
+ all:: $(vendor_LIBS)
+ 
+ libs:: $(vendor_LIBS)
+ 
+ $(vendor_ATLAS_LIBS):
+ 	@echo "Building ATLAS (atlas.build.log)"
+ 	@$(MAKE) -C vendor/atlas build > atlas.build.log 2>&1
+ 
+ $(vendor_REF_LAPACK):
+ 	@echo "Building LAPACK (lapack.build.log)"
+ 	@$(MAKE) -C vendor/lapack/SRC all > lapack.build.log 2>&1
+ 
+ $(vendor_USE_LAPACK): $(vendor_PRE_LAPACK) $(vendor_REF_LAPACK)
+ 	mkdir -p vendor/atlas/lib/tmp
+ 	pushd vendor/atlas/lib/tmp; ar x ../../../../$(vendor_PRE_LAPACK); popd
+ 	cp $(vendor_REF_LAPACK) $(vendor_USE_LAPACK)
+ 	pushd vendor/atlas/lib/tmp; ar r ../../../../$(vendor_USE_LAPACK); popd
+ 	rm -rf vendor/atlas/lib/tmp
+ 
+ clean::
+ 	@echo "Cleaning ATLAS (atlas.clean.log)"
+ 	@$(MAKE) -C vendor/atlas clean > atlas.clean.log 2>&1
+ 
+ install::
+ 	@echo "Installing ATLAS (atlas.install.log)"
+ 	# @$(MAKE) -C vendor/atlas installinstall > atlas.install.log 2>&1
+ 	$(INSTALL) -d $(libdir)/atlas
+ 	$(INSTALL_DATA) vendor/atlas/lib/libcsl_atlas.a   $(libdir)/atlas
+ 	$(INSTALL_DATA) vendor/atlas/lib/libcsl_cblas.a   $(libdir)/atlas
+ 	$(INSTALL_DATA) vendor/atlas/lib/libcsl_f77blas.a $(libdir)/atlas
+ 	$(INSTALL_DATA) vendor/atlas/lib/libcsl_lapack.a  $(libdir)/atlas
+ endif
Index: vendor/atlas/GNUmakefile.in
===================================================================
RCS file: vendor/atlas/GNUmakefile.in
diff -N vendor/atlas/GNUmakefile.in
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- vendor/atlas/GNUmakefile.in	29 Nov 2005 20:24:10 -0000
***************
*** 0 ****
--- 1,40 ----
+ ######################################################### -*-Makefile-*-
+ #
+ # File:   GNUmakefile
+ # Author: Jules Bergmann
+ # Date:   2005-11-22
+ #
+ # Contents: Makefile for building ATLAS in VSIPL++ source dir
+ #
+ # (Derived from ATLAS Make.top)
+ ########################################################################
+ 
+ include Make.ARCH
+ arch=@ARCH@
+ 
+ all: build
+ 
+ error_report:
+ 	- uname -a 2>&1 >> bin/$(arch)/INSTALL_LOG/ERROR.LOG
+ 	- $(CC) -v 2>&1  >> bin/$(arch)/INSTALL_LOG/ERROR.LOG
+ 	- $(CC) -V 2>&1  >> bin/$(arch)/INSTALL_LOG/ERROR.LOG
+ 	- $(CC) --version 2>&1  >> bin/$(arch)/INSTALL_LOG/ERROR.LOG
+ 	$(TAR) cf error_$(arch).tar Make.$(arch) bin/$(arch)/INSTALL_LOG/*
+ 	$(GZIP) --best error_$(arch).tar
+ 	mv error_$(arch).tar.gz error_$(arch).tgz
+ 
+ build:
+ 	$(MAKE) -C bin/$(arch) xatlas_install
+ 	cd bin/$(arch); ./xatlas_install -d $(ARCHDEF) $(MMDEF) $(INSTFLAGS)
+ 
+ ISetL1 : 
+ 	rm -f $(SYSdir)/res/L1CacheSize
+ 	echo $(L1Size) > $(SYSdir)/res/L1CacheSize
+ 
+ clean :
+ 	cd $(BINdir) ; $(MAKE) clean
+ 	# cd $(SRCdir) ; $(MAKE) clean
+ 	cd $(MMTdir) ; $(MAKE) clean
+ 	cd $(L3Bdir) ; $(MAKE) clean
+ 	# cd $(PTBdir) ; $(MAKE) clean
+ 
Index: vendor/atlas/Make.ARCH.in
===================================================================
RCS file: vendor/atlas/Make.ARCH.in
diff -N vendor/atlas/Make.ARCH.in
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- vendor/atlas/Make.ARCH.in	29 Nov 2005 20:24:10 -0000
***************
*** 0 ****
--- 1,168 ----
+ #  -----------------------------
+ #  Make.ARCH for ATLAS3.6.0
+ #  -----------------------------
+ 
+ #  ----------------------------------
+ #  Make sure we get the correct shell
+ #  ----------------------------------
+    SHELL = @SH@
+ 
+ #  -------------------------------------------------
+ #  Name indicating the platform to configure BLAS to
+ #  -------------------------------------------------
+    ARCH = @ARCH@
+ 
+ #  -------------------
+ #  Various directories
+ #  -------------------
+    TOPdir = @TOPdir@
+    INCdir = @TOPdir@/include/$(ARCH)
+    SYSdir = $(TOPdir)/tune/sysinfo/$(ARCH)
+    GMMdir = $(TOPdir)/src/blas/gemm/$(ARCH)
+    UMMdir = @UMMdir@
+    GMVdir = $(TOPdir)/src/blas/gemv/$(ARCH)
+    GR1dir = $(TOPdir)/src/blas/ger/$(ARCH)
+    L1Bdir = $(TOPdir)/src/blas/level1/$(ARCH)
+    L2Bdir = $(TOPdir)/src/blas/level2/$(ARCH)
+    L3Bdir = $(TOPdir)/src/blas/level3/$(ARCH)
+    TSTdir = $(TOPdir)/src/testing/$(ARCH)
+    AUXdir = $(TOPdir)/src/auxil/$(ARCH)
+    CBLdir = $(TOPdir)/interfaces/blas/C/src/$(ARCH)
+    FBLdir = $(TOPdir)/interfaces/blas/F77/src/$(ARCH)
+    BINdir = $(TOPdir)/bin/$(ARCH)
+    LIBdir = @LIBdir@
+    PTSdir = $(TOPdir)/src/pthreads
+    MMTdir = $(TOPdir)/tune/blas/gemm/$(ARCH)
+    MVTdir = $(TOPdir)/tune/blas/gemv/$(ARCH)
+    R1Tdir = $(TOPdir)/tune/blas/ger/$(ARCH)
+    L1Tdir = $(TOPdir)/tune/blas/level1/$(ARCH)
+    L3Tdir = $(TOPdir)/tune/blas/level3/$(ARCH)
+ 
+    src_INCdir = @abs_top_srcdir@/include
+    src_L3Bdir = @abs_top_srcdir@/src/blas/level3
+ 
+ #  ---------------------------------------------------------------------
+ #  Name and location of scripts for running executables during tuning
+ #  ---------------------------------------------------------------------
+    ATLRUN = $(BINdir)/ATLrun.sh
+    ATLFWAIT = $(BINdir)/xatlas_waitfile
+ 
+ #  ---------------------
+ #  Libraries to be built
+ #  ---------------------
+    ATLASlib = $(LIBdir)/@ATLASlib@
+    CBLASlib = $(LIBdir)/@CBLASlib@
+    F77BLASlib = $(LIBdir)/@F77BLASlib@
+ 
+ #if threads
+    PTCBLASlib = $(LIBdir)/@PTCBLASlib@
+    PTF77BLASlib = $(LIBdir)/@PTF77BLASlib@
+ 
+    LAPACKlib = $(LIBdir)/@LAPACKlib@
+    TESTlib = $(LIBdir)/libtstatlas.a
+ 
+ #  -------------------------------------------
+ #  Upper bound on largest cache size, in bytes
+ #  -------------------------------------------
+    DEF_L2SIZE = -DL2SIZE=@L2SIZE@
+ 
+ #  ---------------------------------------
+ #  Command setting up correct include path
+ #  ---------------------------------------
+    INCLUDES = -I@abs_top_srcdir@/include		\
+ 	      -I@abs_top_srcdir@/include/$(ARCH)	\
+               -I@abs_top_srcdir@/include/contrib	\
+               -I$(TOPdir)/include/$(ARCH)
+ 
+ 
+ #  -------------------------------------------
+ #  Defines for setting up F77/C interoperation
+ #  -------------------------------------------
+    F2CDEFS = @F2CDEFS@
+ 
+ #  --------------------------------------
+ #  Special defines for user-supplied GEMM
+ #  --------------------------------------
+    UMMDEFS = @UMMDEFS@
+ 
+ #  ------------------------------
+ #  Architecture identifying flags
+ #  ------------------------------
+    ARCHDEFS = @ARCHDEFS@
+ 
+ 
+ #  -------------------------------------------------------------------
+ #  NM is the flag required to name a compiled object/executable
+ #  OJ is the flag required to compile to object rather than executable
+ #  These flags are used by all compilers.
+ #  -------------------------------------------------------------------
+    NM = -o
+    OJ = -c
+ 
+    F77         = @F77@
+    F77FLAGS    = @FFLAGS@
+    FLINKER     = @FLINKER@
+    FLINKFLAGS  = @FLINKFLAGS@
+    FCLINKFLAGS = @FCLINKFLAGS@
+ 
+    CDEFS = -DSRCDIR='"@abs_top_srcdir@"' $(DEF_L2SIZE) $(INCLUDES) $(F2CDEFS) $(ARCHDEFS)	\
+ 	   @UCDEF@ @THREAD_CDEFS@ @DELAY_CDEF@
+ 
+ 
+    GOODGCC = @GOODGCC@
+    CC = @CC@
+    CCFLAG0 = @CFLAGS@
+    CCFLAGS = $(CDEFS) $(CCFLAG0)
+    MCC = @MCC@
+    MMFLAGS = @MMFLAGS@
+    XCC = @XCC@
+    XCCFLAGS = @XCCFLAGS@
+    CLINKER  = @CLINKER@
+    CLINKFLAGS = @CLINKFLAGS@
+    BC       = $(CC)
+    BCFLAGS  = $(CCFLAGS)
+    ARCHIVER = @ARCHIVER@
+    ARFLAGS  = @ARFLAGS@
+    RANLIB   = @RANLIB@
+ 
+ #  -------------------------------------
+ #  tar, gzip, gunzip, and parallel make
+ #  -------------------------------------
+    TAR    = @TAR@
+    GZIP   = @GZIP@
+    GUNZIP = @GUNZIP@
+    PMAKE  = @PMAKE@
+ 
+ #  ------------------------------------
+ #  Reference and system libraries
+ #  ------------------------------------
+    BLASlib = @BLASlib@
+    FBLASlib = 
+    FLAPACKlib = 
+    LIBS = @LIBS@
+ 
+ #  ----------------------------------------------------------
+ #  ATLAS install resources (include arch default directories)
+ #  ----------------------------------------------------------
+    ARCHDEF = @ARCHDEF@
+    MMDEF = @MMDEF@
+    USEDEFL1 = @USEDEFL1@
+ ifdef USEDEFL1
+    INSTFLAGS = -1 1
+ else
+    INSTFLAGS =
+ endif
+ 
+ 
+ #  ---------------------------------------
+ #  Generic targets needed by all makefiles
+ #  ---------------------------------------
+    delay = @delay@
+ ifdef delay
+    waitfile = wfdefault
+ waitfile:
+ 	cd $(BINdir) ; make xatlas_waitfile
+ 	$(ATLFWAIT) -s $(delay) -f $(waitfile)
+ else
+ waitfile:
+ endif
Index: vendor/atlas/autogen.sh
===================================================================
RCS file: vendor/atlas/autogen.sh
diff -N vendor/atlas/autogen.sh
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- vendor/atlas/autogen.sh	29 Nov 2005 20:24:10 -0000
***************
*** 0 ****
--- 1,9 ----
+ #!/bin/sh
+ #
+ 
+ # Generate 'src/vsip/impl/acconfig.hpp.in' by inspecting 'configure.ac'
+ autoheader
+ # Generate 'configure' from 'configure.ac'
+ autoconf
+ # Generate Makefiles
+ sh csl-scripts/convert.sh
Index: vendor/atlas/configure.ac
===================================================================
RCS file: vendor/atlas/configure.ac
diff -N vendor/atlas/configure.ac
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- vendor/atlas/configure.ac	29 Nov 2005 20:24:10 -0000
***************
*** 0 ****
--- 1,1466 ----
+ dnl
+ dnl File:   configure.ac
+ dnl Author: Jules Bergmann
+ dnl Date:   2005-11-17
+ dnl
+ dnl Contents: configuration for VSIPL++/ATLAS
+ dnl
+ 
+ dnl ------------------------------------------------------------------
+ dnl Autoconf initialization
+ dnl ------------------------------------------------------------------
+ AC_PREREQ(2.56)
+ AC_REVISION($Revision: 1.48 $)
+ AC_INIT(VSIPL++, 1.0, vsipl++@codesourcery.com)
+ 
+ # --------------------------------------------------------------------
+ # Configure command line arguments.
+ # --------------------------------------------------------------------
+ 
+ AC_ARG_WITH(mach,
+   AS_HELP_STRING([--with-mach=machine_type],
+                  [Specify machine type (default is to probe).]),,
+   [with_mach="probe"])
+ 
+ AC_ARG_WITH(libprefix,
+   AS_HELP_STRING([--with-libprefix=prefix],
+                  [Specify prefix for libraries. (default is none).]),,
+   [with_libprefix=""])
+ 
+ mach=$with_mach
+ 
+ # disable 3Dnow
+ 
+ # disable Alpha GOTO GEMM
+ 
+ # TOPdir="$srcdir"
+ TOPdir=`pwd`
+ ARCHIVER="ar"
+ ARFLAGS="r"
+ RANLIB="echo"
+ 
+ ARCHDEFS=""
+ 
+ 
+ 
+ # --------------------------------------------------------------------
+ # Files to generate.
+ # --------------------------------------------------------------------
+ 
+ # Find all template files and strip off the $srcdir and .in suffix.
+ templates=`find $srcdir -name '_darcs' -prune -o -name '.#*' -prune -o -name '*.in' -print | 
+            sed -e "s,^$srcdir/,,g" -e 's,\.in$,,g'`
+ 
+ # AC_CONFIG_FILES([$templates])
+ AC_CONFIG_HEADERS([CONFIG/acconfig.hpp])
+ 
+ 
+ 
+ #
+ # QMTest wants to know this.
+ #
+ AC_CANONICAL_HOST
+ 
+ # --------------------------------------------------------------------
+ # Find the compilers.
+ # --------------------------------------------------------------------
+ AC_PROG_CC
+ AC_PROG_F77
+ AC_LANG(C)
+ 
+ #
+ # Set ar
+ #
+ if test "x$AR" == "x"; then
+   AR="ar"
+ fi
+ 
+ AC_SUBST(AR)
+ 
+ 
+ 
+ # --------------------------------------------------------------------
+ # Get OS
+ # --------------------------------------------------------------------
+ os_name=`uname -s`
+ 
+ # if test "$os_name" == "Linux"; then
+ # fi
+ 
+ 
+ # --------------------------------------------------------------------
+ # Get Arch
+ # --------------------------------------------------------------------
+ 
+ mach_is_ppc=""		# true if PowerPC architecture
+ 
+ if test "$mach" == "probe"; then
+  if test "$os_name" == "Linux"; then
+   la=`uname -m`
+ 
+   case $la in
+     ppc | ppc64 | "Power Machintosh")
+       la="ppc" ;;
+     i386 | i486 | i586 | i686 )
+       la="x86_32" ;;
+     x86_64 )
+       la="x86_64" ;;
+   esac
+       
+   mach="unknown"
+ 
+   echo "linux arch $la"
+   if test "$la" == "ppc"; then
+     mach_is_ppc="true"
+     model=`fgrep -m 1 cpu /proc/cpuinfo`
+ 
+     if test "`echo $model | sed -n /604e/p`" != ""; then
+       mach="PPC604e"
+     elif test "`echo $model | sed -n /604/p`" != ""; then
+       mach="PPC604"
+     elif test "`echo $model | sed -n /G4/p`" != ""; then
+       mach="PPCG4"
+     elif test "`echo $model | sed -n /7400/p`" != ""; then
+       mach="PPCG4"
+     elif test "`echo $model | sed -n /7410/p`" != ""; then
+       mach="PPCG4"
+     elif test "`echo $model | sed -n /7455/p`" != ""; then
+       mach="PPCG4"
+     elif test "`echo $model | sed -n /PPC970FX/p`" != ""; then
+       mach="PPCG5"
+     fi
+   fi
+ 
+ 	
+   # SPARC
+   # ALPHA
+   # IA64
+   # X86
+   if test "$la" == "x86_32"; then
+     model=`fgrep -m 1 'model name' /proc/cpuinfo`
+     if test "x$model" == "x"; then
+       model=`fgrep -m 1 model /proc/cpuinfo`
+     fi
+ 
+     if test "`echo $model | sed -n /Pentium/p`" != ""; then
+       if test "`echo $model | sed -n /III/p`" == "match"; then
+         mach="PIII"
+       elif test "`echo $model | sed -n '/ II/p'`" != ""; then
+         mach="PII"
+       elif test "`echo $model | sed -n '/Pro/p'`" != ""; then
+         mach="PPRO"
+       elif test "`echo $model | sed -n '/MMX/p'`" != ""; then
+         mach="P5MMX"
+       elif test "`echo $model | sed -n '/ 4 /p'`" != ""; then
+         mach="P4"
+       elif test "`echo $model | sed -n '/ M /p'`" != ""; then
+         mach="P4"
+       fi
+     elif test "`echo $model | sed -n /XEON/p`" != ""; then
+       mach="P4"
+     elif test "`echo $model | sed -n '/Athlon/p'`" != ""; then
+       mach="ATHLON"
+     elif test "`echo $model | sed -n '/Opteron/p'`" != ""; then
+       mach="HAMMER32"
+     fi
+   elif test "$la" == "x86_64"; then
+     model=`fgrep -m 1 'model name' /proc/cpuinfo`
+     if test "x$model" == "x"; then
+       model=`fgrep -m 1 model /proc/cpuinfo`
+     fi
+ 
+     echo "match $model"
+     patt=`echo $model | sed -n /Xeon/p`
+     echo "patt: $patt"
+ 
+     if test "`echo $model | sed -n /Xeon/p`" != ""; then
+       mach="P4E64"
+     elif test "`echo $model | sed -n '/Athlon HX/p'`" != ""; then
+       mach="HAMMER64"
+     elif test "`echo $model | sed -n '/Athlon(tm) 64/p'`" != ""; then
+       mach="HAMMER64"
+     fi
+   fi
+  fi
+ fi
+ 
+ echo "mach: $mach"
+ 
+ mach_is_x86_32=""	# true if x86 architecture
+ mach_is_x86_64=""	# true if x86 architecture
+ mach_is_us=""		# true if Ultra-SPARC architecture
+ mach_is_alpha=""	# true if Alpha architecture
+ 
+ case $mach in
+   PII | PIII | PPRO | P5MMX | P4 )
+     mach_is_x86_32="true" ;;
+   P4E64 | HAMMER64 )
+     mach_is_x86_64="true" ;;
+ esac
+   
+ 
+ 
+ # --------------------------------------------------------------------
+ # Probe ASM
+ # --------------------------------------------------------------------
+ 
+ AC_MSG_CHECKING([for asm style])
+ 
+ if test "$mach_is_x86_32" == "true"; then
+   asmd="GAS_x8632"
+ elif test "$mach_is_x86_64" == "true"; then
+   asmd="GAS_x8664"
+ elif test "$mach_is_us" == "true"; then
+   asmd="GAS_SPARC"
+ elif test "$mach_is_ppc" == "true"; then
+   asmd="GAS_LINUX_PPC"
+ else
+   AC_MSG_ERROR([cannot determine asm type.])
+ fi
+ 
+ AC_MSG_RESULT($asmd)
+ 
+ 
+ 
+ # --------------------------------------------------------------------
+ # GetISAExt
+ # --------------------------------------------------------------------
+ 
+ use_isa="probe"
+ 
+ # Check for AltiVec
+ if test "$use_isa" == "probe"; then
+   AC_MSG_CHECKING([for AltiVec ISA])
+ 
+   altivec_cfgs="altivec1 altivec2"
+   old_CFLAGS="$CFLAGS"
+   for try_cfg in $altivec_cfgs; do
+     if test "$try_cfg" == "altivec1"; then
+       # gcc
+       CFLAGS="$CFLAGS -maltivec -mabi=altivec"
+     elif test "$try_cfg" == "altivec2"; then
+       # OSX
+       CFLAGS="$CFLAGS -faltivec"
+     fi
+   
+     AC_RUN_IFELSE([
+       AC_LANG_SOURCE([[
+ #include <stdio.h>
+ #include <stdlib.h>
+ #ifdef ATL_AVgcc
+    #include <altivec.h>
+ #endif
+ main(int nargs, char **args)
+ {
+    char ln[128];
+    float *tp;
+ #ifdef ATL_AVgcc
+    vector float v0, v1 = (vector float) {2.0f, 3.0f, 4.0f, 5.0f};
+ #else
+    vector float v0, v1 = (vector float) (2.0f, 3.0f, 4.0f, 5.0f);
+ #endif
+ 
+    tp = (void*) (16+ ((((size_t)ln)>>4)<<4));
+    tp[0] = 0.0; tp[1] = 1.0; tp[2] = 2.0; tp[3] = 3.0;
+    v0 = vec_ld(0, tp);
+    v0 = vec_add(v0, v1);
+    vec_st(v0, 0, tp);
+    vec_st(v1, 0, tp+4);
+    if (tp[0] != 2.0f || tp[1] != 4.0f || tp[2] != 6.0f || tp[3] != 8.0f)
+    {
+       printf("FAILURE\n");
+       exit(1);
+    }
+    else if (tp[4] != 2.0f || tp[5] != 3.0f || tp[6] != 4.0f || tp[7] != 5.0f)
+    {
+       printf("FAILURE\n");
+       exit(2);
+    }
+    printf("SUCCESS\n");
+    exit(0);
+ }
+     ]])],
+     [use_isa="AltiVec"
+      break])
+     CFLAGS=$old_CFLAGS
+   done
+ 
+   if test "$use_isa" == "AltiVec"; then
+     AC_MSG_RESULT([FOUND.])
+   else
+     AC_MSG_RESULT([not found.])
+   fi
+ fi
+ 
+ # --------------------------------------------------------------------
+ if test "$use_isa" == "probe"; then
+   AC_MSG_CHECKING([for SSE3])
+ 
+   AC_RUN_IFELSE([
+     AC_LANG_SOURCE([[
+ #include <stdio.h>
+ 
+ #define gen_vec_rr(op,reg1,reg2) \
+         __asm__ __volatile__ (#op " %%" #reg1 ", %%" #reg2 \
+                               :  /* nothing */ \
+                               : /* nothing */)
+ 
+ 
+ #define gen_vec_mr(op,mem,reg) \
+         __asm__ __volatile__ (#op " %0, %%" #reg \
+                               :  /* nothing */ \
+                               : "m" (((mem)[0])), "m" (((mem)[1])))
+ 
+ 
+ #define gen_vec_rm(op,reg,mem) \
+         __asm__ __volatile__ (#op " %%" #reg ", %0" \
+                               : "=m" (((mem)[0])), "=m" (((mem)[1])) \
+                               :  /* nothing */ )
+ 
+ #define vec_mov_mr(mem,reg)     gen_vec_mr(lddqu,mem,reg)
+ #define vec_mov_rm(reg,mem)     gen_vec_rm(movupd,reg,mem)
+ #define vec_add_rr(reg1,reg2)   gen_vec_rr(haddpd,reg1,reg2)
+ 
+ #define reg0 xmm0
+ #define reg1 xmm1
+ 
+ main()
+ {
+ 
+   int i;
+   double testv1[2],testv2[2],testv3[2];
+ 
+   testv1[0] = 1.0; testv1[1] = 2.0;
+   testv2[0] = 3.0; testv2[1] = 4.0;
+ 
+   vec_mov_mr(testv1,reg0);
+   vec_mov_mr(testv2,reg1);
+   vec_add_rr(reg1,reg0);
+   vec_mov_rm(reg0,testv3);
+ 
+   if (testv3[0] != 3.0 || testv3[1] != 7.0)
+   {
+      // printf("FAILURE\n");
+      exit(1);
+    }
+ 
+   // printf("SUCCESS\n");
+   exit(0);
+ }
+     ]])],
+   [use_isa="SSE3"
+    break])
+ 
+   if test "$use_isa" == "SSE3"; then
+     ARCHDEFS="$ARCHDEFS -DATL_SSE1 -DATL_SSE2 -DATL_SSE3"
+     AC_MSG_RESULT([FOUND.])
+   else
+     AC_MSG_RESULT([not found.])
+   fi
+ fi
+ 
+ # --------------------------------------------------------------------
+ if test "$use_isa" == "probe"; then
+   AC_MSG_CHECKING([for SSE2])
+ 
+   AC_RUN_IFELSE([
+     AC_LANG_SOURCE([[
+ #include <stdio.h>
+ #define VECLEN 2
+ 
+ #define gen_vec_rr(op,reg1,reg2) \
+         __asm__ __volatile__ (#op " %%" #reg1 ", %%" #reg2 \
+                               :  /* nothing */ \
+                               : /* nothing */)
+ 
+ 
+ #define gen_vec_mr(op,mem,reg) \
+         __asm__ __volatile__ (#op " %0, %%" #reg \
+                               :  /* nothing */ \
+                               : "m" (((mem)[0])), "m" (((mem)[1])))
+ 
+ 
+ #define gen_vec_rm(op,reg,mem) \
+         __asm__ __volatile__ (#op " %%" #reg ", %0" \
+                               : "=m" (((mem)[0])), "=m" (((mem)[1])) \
+                               :  /* nothing */ )
+ 
+ #define vec_mov_mr(mem,reg)     gen_vec_mr(movupd,mem,reg)
+ #define vec_mov_rm(reg,mem)     gen_vec_rm(movupd,reg,mem)
+ #define vec_add_rr(reg1,reg2)   gen_vec_rr(addpd,reg1,reg2)
+ 
+ #define reg0 xmm0
+ #define reg1 xmm1
+ 
+ main()
+ {
+ 
+   int i;
+   double testv1[VECLEN],testv2[VECLEN],testv3[VECLEN];
+ 
+   for (i=0;i<VECLEN;i++)
+     {
+       testv1[i]=i;
+       testv2[i]=i+2;
+       testv3[i]=0;
+     }
+ 
+   vec_mov_mr(testv1,reg0);
+   vec_mov_mr(testv2,reg1);
+   vec_add_rr(reg1,reg0);
+   vec_mov_rm(reg0,testv3);
+ 
+   for (i=0;i<VECLEN;i++)
+     {
+       if (testv3[i]!=(2*i+2))
+ 	{
+ 	  // printf("FAILURE\n");
+ 	  exit(1);
+ 	}
+     }
+ 
+   // printf("SUCCESS\n");
+   exit(0);
+ }
+     ]])],
+   [use_isa="SSE2"
+    break])
+ 
+   if test "$use_isa" == "SSE2"; then
+     ARCHDEFS="$ARCHDEFS -DATL_SSE1 -DATL_SSE2"
+     AC_MSG_RESULT([FOUND.])
+   else
+     AC_MSG_RESULT([not found.])
+   fi
+ fi
+ 
+ 
+ # --------------------------------------------------------------------
+ if test "$use_isa" == "probe"; then
+   AC_MSG_CHECKING([for SSE1])
+ 
+   AC_RUN_IFELSE([
+     AC_LANG_SOURCE([[
+ #include <stdio.h>
+ #define VECLEN 4
+ 
+ #define gen_vec_rr(op,reg1,reg2) \
+         __asm__ __volatile__ (#op " %%" #reg1 ", %%" #reg2 \
+                               :  /* nothing */ \
+                               : /* nothing */)
+ 
+ 
+ #define gen_vec_mr(op,mem,reg) \
+         __asm__ __volatile__ (#op " %0, %%" #reg \
+                               :  /* nothing */ \
+                               : "m" (((mem)[0])), "m" (((mem)[1])), "m" (((mem)[2])), "m" (((mem)[3])))
+ 
+ 
+ #define gen_vec_rm(op,reg,mem) \
+         __asm__ __volatile__ (#op " %%" #reg ", %0" \
+                               : "=m" (((mem)[0])), "=m" (((mem)[1])), "=m" (((mem)[2])), "=m" (((mem)[3])) \
+                               :  /* nothing */ )
+ 
+ #define vec_mov_mr(mem,reg)     gen_vec_mr(movups,mem,reg)
+ #define vec_mov_rm(reg,mem)     gen_vec_rm(movups,reg,mem)
+ #define vec_add_rr(reg1,reg2)   gen_vec_rr(addps,reg1,reg2)
+ 
+ #define reg0 xmm0
+ #define reg1 xmm1
+ 
+ main()
+ {
+ 
+   int i;
+   float testv1[VECLEN],testv2[VECLEN],testv3[VECLEN];
+ 
+   for (i=0;i<VECLEN;i++)
+     {
+       testv1[i]=i;
+       testv2[i]=i+2;
+       testv3[i]=0;
+     }
+ 
+   vec_mov_mr(testv1,reg0);
+   vec_mov_mr(testv2,reg1);
+   vec_add_rr(reg1,reg0);
+   vec_mov_rm(reg0,testv3);
+ 
+   for (i=0;i<VECLEN;i++)
+     {
+       if (testv3[i]!=(2*i+2))
+ 	{
+ 	  // printf("FAILURE\n");
+ 	  exit(1);
+ 	}
+     }
+ 
+   // printf("SUCCESS\n");
+   exit(0);
+ 
+ }
+     ]])],
+   [use_isa="SSE1"
+    break])
+ 
+   if test "$use_isa" == "SSE1"; then
+     ARCHDEFS="$ARCHDEFS -DATL_SSE1"
+     AC_MSG_RESULT([FOUND.])
+   else
+     AC_MSG_RESULT([not found.])
+   fi
+ fi
+ 
+ # --------------------------------------------------------------------
+ if test "$use_isa" == "probe"; then
+   if test "$disable_3dnow" != "yes"; then
+   AC_MSG_CHECKING([for 3DNow2])
+ 
+   AC_RUN_IFELSE([
+     AC_LANG_SOURCE([[
+ #include <stdio.h>
+ #define VECLEN 2
+ 
+ #define gen_vec_rr(op,reg1,reg2) \
+         __asm__ __volatile__ (#op " %%" #reg1 ", %%" #reg2 \
+                               :  /* nothing */ \
+                               : /* nothing */)
+ 
+ 
+ #define gen_vec_mr(op,mem,reg) \
+         __asm__ __volatile__ (#op " %0, %%" #reg \
+                               :  /* nothing */ \
+                               : "m" (((mem)[0])), "m" (((mem)[1])))
+ 
+ #define gen_vec_rm(op,reg,mem) \
+         __asm__ __volatile__ (#op " %%" #reg ", %0" \
+                               : "=m" (((mem)[0])), "=m" (((mem)[1])) \
+ 			      :  /* nothing */ )
+ 
+ 
+ #define vec_mov_mr(mem,reg)     gen_vec_mr(movq,mem,reg)
+ #define vec_mov_rm(reg,mem)     gen_vec_rm(movq,reg,mem)
+ #define vec_add_rr(reg1,reg2)   gen_vec_rr(pfadd,reg1,reg2)
+ 
+ #define reg0 mm0
+ #define reg1 mm1
+ 
+ main()
+ {
+ 
+   int i;
+   float testv1[VECLEN],testv2[VECLEN],testv3[VECLEN];
+ 
+   for (i=0;i<VECLEN;i++)
+     {
+       testv1[i]=i;
+       testv2[i]=i+2;
+       testv3[i]=0;
+     }
+ 
+   __asm__ __volatile__ ("femms");
+ 
+   __asm__ __volatile__ ("sfence");
+ 
+   vec_mov_mr(testv1,reg0);
+   vec_mov_mr(testv2,reg1);
+   vec_add_rr(reg1,reg0);
+   vec_mov_rm(reg0,testv3);
+ 
+   __asm__ __volatile__ ("femms");
+ 
+   for (i=0;i<VECLEN;i++)
+     {
+       if (testv3[i]!=(2*i+2))
+ 	{
+ 	  // printf("FAILURE\n");
+ 	  exit(1);
+ 	}
+     }
+ 
+   // printf("SUCCESS\n");
+   exit(0);
+ 
+ }
+     ]])],
+   [use_isa="3DNow2"
+    break])
+ 
+   if test "$use_isa" == "3DNow2"; then
+     ARCHDEFS="$ARCHDEFS -DATL_3DNow2"
+     AC_MSG_RESULT([FOUND.])
+   else
+     AC_MSG_RESULT([not found.])
+   fi
+ fi
+ fi
+ 
+ 
+ # --------------------------------------------------------------------
+ if test "$use_isa" == "probe"; then
+   if test "$disable_3dnow" != "yes"; then
+   AC_MSG_CHECKING([for 3DNow1])
+ 
+   AC_RUN_IFELSE([
+     AC_LANG_SOURCE([[
+ #include <stdio.h>
+ 
+ #define VECLEN 2
+ 
+ #define gen_vec_rr(op,reg1,reg2) \
+         __asm__ __volatile__ (#op " %%" #reg1 ", %%" #reg2 \
+                               :  /* nothing */ \
+                               : /* nothing */)
+ 
+ 
+ #define gen_vec_mr(op,mem,reg) \
+         __asm__ __volatile__ (#op " %0, %%" #reg \
+                               :  /* nothing */ \
+                               : "m" (((mem)[0])), "m" (((mem)[1])))
+ 
+ #define gen_vec_rm(op,reg,mem) \
+         __asm__ __volatile__ (#op " %%" #reg ", %0" \
+                               : "=m" (((mem)[0])), "=m" (((mem)[1])) \
+ 			      :  /* nothing */ )
+ 
+ 
+ #define vec_mov_mr(mem,reg)     gen_vec_mr(movq,mem,reg)
+ #define vec_mov_rm(reg,mem)     gen_vec_rm(movq,reg,mem)
+ #define vec_add_rr(reg1,reg2)   gen_vec_rr(pfadd,reg1,reg2)
+ 
+ #define reg0 mm0
+ #define reg1 mm1
+ 
+ main()
+ {
+ 
+   int i;
+   float testv1[VECLEN],testv2[VECLEN],testv3[VECLEN];
+ 
+   for (i=0;i<VECLEN;i++)
+     {
+       testv1[i]=i;
+       testv2[i]=i+2;
+       testv3[i]=0;
+     }
+ 
+   __asm__ __volatile__ ("femms");
+ 
+   vec_mov_mr(testv1,reg0);
+   vec_mov_mr(testv2,reg1);
+   vec_add_rr(reg1,reg0);
+   vec_mov_rm(reg0,testv3);
+ 
+   __asm__ __volatile__ ("femms");
+ 
+   for (i=0;i<VECLEN;i++)
+     {
+       if (testv3[i]!=(2*i+2))
+ 	{
+ 	  // printf("FAILURE\n");
+ 	  exit(1);
+ 	}
+     }
+ 
+   // printf("SUCCESS\n");
+   exit(0);
+ 
+ }
+     ]])],
+   [use_isa="3DNow1"
+    break])
+ 
+   if test "$use_isa" == "3DNow1"; then
+     ARCHDEFS="$ARCHDEFS -DATL_3DNow1"
+     AC_MSG_RESULT([FOUND.])
+   else
+     AC_MSG_RESULT([not found.])
+   fi
+ fi
+ fi
+ 
+ if test "$use_isa" == "probe"; then
+   use_isa="none"
+ fi
+ 
+ 
+ 
+ # --------------------------------------------------------------------
+ # GetUserMM
+ # --------------------------------------------------------------------
+ 
+ # defaults
+ UMMdir='$(GMMdir)'
+ UMMDEF=''
+ usermm_name=''
+ 
+ # This is a cheap workaround to Linux_21164GOTO error, forcing use
+ # of the non-goto defaults on such a platform
+ if test "$mach" == "21164"; then
+   if test "$disable_goto_gemm" != "yes"; then
+     UMMdir='$(TOPdir)/src/blas/gemm/GOTO/$(ARCH)'
+     UMMDEF='-DEV5'
+     usermm_name='GOTO'
+   fi
+ fi
+ if test "$mach" == "21264"; then
+   if test "$disable_goto_gemm" != "yes"; then
+     UMMdir='$(TOPdir)/src/blas/gemm/GOTO/$(ARCH)'
+     UMMDEF='-DEV6'
+     usermm_name='GOTO'
+   fi
+ fi
+ 
+ 
+ # --------------------------------------------------------------------
+ # Probe threads
+ # --------------------------------------------------------------------
+ 
+ if test "$use_threads" == "yes"; then
+   AC_MSG_ERROR([Threaded ATLAS not supported.])
+ 
+   THREAD_CDEFS="-DATL_NCPU=$ncpu"
+   if test $os_name == "FreeBSD"; then
+     THREAD_CDEFS="$THREAD_CDEFS -D_THREAD_SAFE -D_REENTRANT"
+   elif test $os_name == "AIX"; then
+     THREAD_CDEFS="$THREAD_CDEFS -DIBM_PT_ERROR"
+   elif test $os_name == "IRIX"; then
+     THREAD_CDEFS="$THREAD_CDEFS -D_POSIX_C_SOURCE=199506L"
+   fi
+ else
+   use_threads="no"
+   THREAD_CDEFS=""
+ fi
+ 
+ AC_SUBST(THREAD_CDEFS)
+ 
+ 
+ 
+ # --------------------------------------------------------------------
+ # Arch Name
+ # --------------------------------------------------------------------
+ 
+ ARCH0="$mach"
+ if test $use_isa != "none"; then
+   ARCH0="$ARCH0$use_isa"
+ fi
+ ARCH0="$ARCH0$usermm_name"
+ 
+ if test $os_name == "Other"; then
+   ARCH="UNKNOWN"
+ else
+   ARCH=$os_name
+ fi
+ 
+ ARCH="${ARCH}_$ARCH0"
+ 
+ if test "$use_threads" == "yes"; then
+   ARCH="${ARCH}_$ncpu"
+ fi
+ 
+ echo "ARCH: $ARCH"
+ 
+ AC_SUBST(ARCH)
+ 
+ 
+ # --------------------------------------------------------------------
+ # GetCacheSize
+ # --------------------------------------------------------------------
+ 
+ case $mach in
+ other)
+   L1SIZE="-1"
+   lf2="-1" ;;
+ SunUSIII | SunUS2 | SunUS4 | SunUS5)
+   L1SIZE="16"
+   lf2="4096" ;;
+ SunUS1)
+   L1SIZE="16"
+   lf2="1024" ;;
+ SunSS)
+   L1SIZE="32"
+   lf2="1024" ;;
+ SunMS)
+   L1SIZE="8"
+   lf2="11" ;;
+ SGIIP22)
+   L1SIZE="16" ;;
+ SGIIP32)
+   # R5K
+   L1SIZE="32" ;;
+ SGIIP27 | SGIIP28 | SGIIP30)
+   L1SIZE="32" ;;
+ ATHLON | HAMMER32 | HAMMER64)
+   L1SIZE="64"
+   lf2="4096" ;;
+ IA64Itan)
+   # ignore actual L1, 'cause fpu doesn't use it
+   L1SIZE="96"
+   lf2="4096" ;;
+ IA64Itan2)
+   L1SIZE="256"
+   lf2="4096" ;;
+ PII | PIII)
+   L1SIZE="16"
+   lf2="512" ;;
+ P4)
+   L1SIZE="64"
+   lf2="512" ;;
+ P4E | P4E64)
+   L1SIZE="16"
+   lf2="1024" ;;
+ PPRO)
+   L1SIZE="8"
+   lf2="1024" ;;
+ P5MMX)
+   L1SIZE="16"
+   lf2="1024" ;;
+ P5)
+   L1SIZE="8"
+   lf2="1024" ;;
+ PPCG4 | PPC604e)
+   L1SIZE="32"
+   lf2="4096" ;;
+ POWER)
+   L1SIZE="64"
+   lf2="256" ;;
+ POWER2Wide)
+   L1SIZE="256"
+   lf2="1024" ;;
+ POWER2Thin)
+   L1SIZE="128"
+   lf2="512" ;;
+ POWER4)
+   L1SIZE="32"
+   lf2="8096" ;;
+ POWER3)
+   L1SIZE="64"
+   lf2="4096" ;;
+ HP9735)
+   L1SIZE="256"
+   lf2="1024" ;;
+ HPPA8K)
+   L1SIZE="1024"
+   lf2="4096" ;;
+ 21064)
+   L1SIZE="16"
+   lf2="4096" ;;
+ 21164)
+   L1SIZE="8"
+   lf2="4096" ;;
+ *)
+   L1SIZE="-1" ;;
+ esac
+ 
+ # Probe cache size
+ AC_MSG_CHECKING([for L2 cache size])
+ size="0"
+ if test $os_name == "Linux"; then
+   case $mach in
+     PII | PIII | PPRO | ATHLON | HAMMER32 | HAMMER64 )
+       line=`fgrep 'cache size' /proc/cpuinfo`
+       sizek=`echo $line | sed -n 's/.* \([[0-9]]*\) KB.*/\1/p'`
+       sizem=`echo $line | sed -n 's/.* \([[0-9]]*\) MB.*/\1/p'`
+       echo "line: $line"
+       echo "sizek: $sizek"
+       echo "sizem: $sizem"
+       if test "$sizek" != ""; then
+         size=$sizek
+       elif test "$sizem" != ""; then
+         size=`expr $sizem \* 1024`
+       fi
+       ;;
+     PPCG4)
+       AC_MSG_ERROR([Linux/PPCG4 L2 cache size not implemented])
+       ;;
+   esac
+ elif test $os_name == "IRIX"; then
+   AC_MSG_ERROR([Cannot determine L2 cache size for IRIX])
+ elif test $os_name == "AIX"; then
+   AC_MSG_ERROR([Cannot determine L2 cache size for AIX])
+ else
+   AC_MSG_ERROR([Cannot determine L2 cache size for $os_name])
+ fi
+ 
+ echo "L2 Cache size: $size"
+ 
+ if test "$size" != "0"; then
+   # Get flush multiple
+   imul="0"
+   if test $os_name == "AIX"; then
+     AC_MSG_ERROR([Configuration of ATLAS for AIX not supported.])
+   fi
+ 
+   if test $imul == "0"; then
+     case $mach in
+       21164 | ATHLON | HAMMER32 | HAMMER64 | \
+       SunUS1 | SunUS2 | SunUSIII | SunUS4 | SunUS5 | SunUSX | \
+       PPCG4 | PIII)
+         imul="2" ;;
+       P4 | P4E | P4E64 )
+         imul="2" ;;
+       P5 | P5MMX | PPRO | PII)
+         imul="1" ;;
+       *)
+         imul="2" ;;
+     esac
+   fi
+   L2SIZE=`expr $size \* $imul`
+ else
+   L2SIZE="$lf2"
+ fi
+ 
+ AC_SUBST(L2SIZE)
+ 
+ # --------------------------------------------------------------------
+ # Compiler Info
+ # --------------------------------------------------------------------
+ 
+ # GetSyslib
+ # Find tar, gzip, gunzip
+ 
+ # NFSDELAY
+ # Fortran
+ #  - F77
+ #  - F77FLAGS
+ #  - FLINKER
+ #  - FLINKERFLAGS
+ 
+ 
+ 
+ # --------------------------------------------------------------------
+ # Determine Fortran naming strategy
+ # --------------------------------------------------------------------
+ 
+ AC_F77_FUNC(C_ROUTINE, [MANGLE])
+ 
+ if test "$MANGLE" == "c_routine_"; then
+   f2c_namedef="-DAdd_"
+ elif test "$MANGLE" == "c_routine__"; then
+   f2c_namedef="-DAdd__"
+ elif test "$MANGLE" == "c_routine"; then
+   f2c_namedef="-DNoChange"
+ elif test "$MANGLE" == "C_ROUTINE"; then
+   f2c_namedef="-DUpCase"
+ fi
+ 
+ 
+ 
+ # --------------------------------------------------------------------
+ # Determine C type corresponding to Fortran integer
+ # --------------------------------------------------------------------
+ 
+ AC_MSG_CHECKING([for C type corresponding to Fortran integer])
+ use_int_type="none"
+ 
+ AC_LANG_SAVE()
+ AC_LANG([C])
+ old_CPPFLAGS="$CPPFLAGS"
+ CPPFLAGS="$CPPFLAGS $f2c_namedef"
+ AC_COMPILE_IFELSE([
+       AC_LANG_SOURCE([
+       ])
+ #include <stdio.h>
+ #if defined(Add_) || defined(Add__)
+    #define c2fint c2fint_
+ #elif defined(UpCase)
+    #define c2fint C2FINT
+ #endif
+ void c2fint(void *vp)
+ {
+    int *ip=vp;
+    long *lp=vp;
+    short *sp=vp;
+ 
+    FILE *f=fopen ("conftestval","w");
+    if (!f) return 1;
+ 
+    if ( (sizeof(long) != sizeof(int)) && (*lp == 1) )
+       /* F77 INTEGER -> C long */
+       fprintf (f, "long\n");
+    else if (*ip == 1)
+       /* F77 INTEGER -> C int */
+       fprintf (f, "int\n");
+    else if (*sp == 1) 
+       /* F77 INTEGER -> C short */
+       fprintf (f, "short\n");
+    else
+       fprintf (f, "NONE\n");
+    fclose(f);
+ }
+     ],[
+       AC_LANG([Fortran 77])
+       old_LDFLAGS="$LDFLAGS"
+       LDFLAGS="conftest.$ac_objext $LDFLAGS"
+       AC_TRY_RUN([
+        PROGRAM FF2CINT
+        INTEGER IARR(8)
+        IARR(1) = 1
+        IARR(2) = -1
+        IARR(3) = -1
+        IARR(4) = -1
+        IARR(5) = -1
+        IARR(6) = -1
+        IARR(7) = -1
+        IARR(8) = -1
+        CALL C2FINT(IARR)
+        STOP
+        END
+      ])
+      LDFLAGS="$old_LDFLAGS"
+      use_int_type=`cat conftestval`
+      rm -f conftestval
+     ])
+ CPPFLAGS="$old_CPPFLAGS"
+ AC_LANG_RESTORE()
+ 
+ if test "$use_int_type" == "none"; then
+   AC_MSG_ERROR([cannot determine C type for FORTRAN INTEGER.])
+ else
+   AC_MSG_RESULT([$use_int_type.])
+ fi
+ 
+ 
+ 
+ # --------------------------------------------------------------------
+ # Determine Fortran string calling convention
+ # --------------------------------------------------------------------
+ 
+ AC_MSG_CHECKING([for Fortran string calling convention.])
+ string_conventions="-DSunStyle -DCrayStyle -DStringStructVal -DStringStructPtr"
+ 
+ use_conv="none"
+ AC_LANG_SAVE()
+ old_CPPFLAGS="$CPPFLAGS"
+ for try_conv in $string_conventions; do
+   AC_LANG([C])
+   CPPFLAGS="$old_CPPFLAGS $f2c_namedef $try_conv -DF77_INTEGER=$use_int_type"
+   res="no"
+   AC_COMPILE_IFELSE([
+       AC_LANG_SOURCE([[
+ #include <stdio.h>
+ #if defined(Add_) || defined(Add__)
+    #define crout crout_
+ #elif defined(UpCase)
+    #define crout CROUT
+ #endif
+ #ifdef SunStyle
+ 
+ void crout(char *str1, F77_INTEGER *n1, char *str2, F77_INTEGER *n2,
+            F77_INTEGER three, F77_INTEGER five)
+ {
+    FILE *f=fopen ("conftestval","w");
+    if (!f) return;
+ 
+    if ( (*n1 != -1) || (*n2 != -2) || (three != 3) || (five != 5) )
+      fprintf(f, "no\n");
+    else if (str1[0] != '1' || str1[1] != '2' || str1[2] != '3')
+      fprintf(f, "no\n");
+    else if (str2[0] != '1' || str2[1] != '2' || str2[2] != '3' ||
+        str2[3] != '4' || str2[4] != '5')
+      fprintf(f, "no\n");
+    else
+      fprintf(f, "yes\n");
+    fclose(f);
+ }
+ 
+ #elif defined(CrayStyle)
+ 
+ #include <fortran.h>
+ void crout(_fcd str1, F77_INTEGER *n1, _fcd str2, F77_INTEGER *n2)
+ {
+    FILE *f=fopen ("conftestval","w");
+    if (!f) return;
+ 
+    if ( (*n1 != -1) || (*n2 != -2) ) 
+      fprintf(f, "no\n");
+    else if (*(_fcdtocp(str1)) != '1' || *(_fcdtocp(str2)) != '1' )
+      fprintf(f, "no\n");
+    else
+      fprintf(f, "yes\n");
+    fclose(f);
+ }
+ 
+ #elif defined(StringStructVal)
+ 
+ typedef struct {char *cp; F77_INTEGER len;} F77_CHAR;
+ void crout(F77_CHAR str1, F77_INTEGER *n1, F77_CHAR str2, F77_INTEGER *n2)
+ {
+    FILE *f=fopen ("conftestval","w");
+    if (!f) return;
+ 
+    if ( (*n1 != -1) || (*n2 != -2) || (str1.len != 3) || (str2.len != 5) )
+      fprintf(f, "no - 1a\n");
+    else if (str1.cp[0] != '1' || str1.cp[1] != '2' || str1.cp[2] != '3')
+      fprintf(f, "no - 2\n");
+    else if (str2.cp[0] != '1' || str2.cp[1] != '2' || str2.cp[2] != '3' ||
+        str2.cp[3] != '4' || str2.cp[4] != '5')
+      fprintf(f, "no - 3\n");
+    else
+      fprintf(f, "yes\n");
+    fclose(f);
+ }
+ #elif defined(StringStructPtr)
+ typedef struct {char *cp; F77_INTEGER len;} *F77_CHAR;
+ void crout(F77_CHAR str1, F77_INTEGER *n1, F77_CHAR str2, F77_INTEGER *n2)
+ {
+    FILE *f=fopen ("conftestval","w");
+    if (!f) return;
+ 
+    if ( (*n1 != -1) || (*n2 != -2) || (str1->len != 3) || (str2->len != 5) )
+      fprintf(f, "no - 1b\n");
+    else if (str1->cp[0] != '1' || str1->cp[1] != '2' || str1->cp[2] != '3')
+      fprintf(f, "no - 2\n");
+    else if (str2->cp[0] != '1' || str2->cp[1] != '2' || str2->cp[2] != '3' ||
+        str2->cp[3] != '4' || str2->cp[4] != '5')
+      fprintf(f, "no - 3\n");
+    else
+      fprintf(f, "yes\n");
+    fclose(f);
+ }
+ #endif
+       ]])
+     ],[
+       AC_LANG([Fortran 77])
+       old_LDFLAGS="$LDFLAGS"
+       LDFLAGS="conftest.$ac_objext $LDFLAGS"
+       AC_TRY_RUN([
+       PROGRAM CHARTST
+       EXTERNAL CROUT
+       CALL CROUT('123', -1, '12345', -2)
+       STOP
+       END
+      ])
+      LDFLAGS="$old_LDFLAGS"
+      res=`cat conftestval`
+      rm -f conftestval
+     ])
+   if test "$res" == "yes"; then
+     use_conv="$try_conv"
+     break
+   fi
+ done
+ CPPFLAGS="$old_CPPFLAGS"
+ AC_LANG_RESTORE()
+ 
+ if test "$use_conv" == "none"; then
+   AC_MSG_ERROR([unknon FORTRAN string convention.])
+ else
+   AC_MSG_RESULT([using $use_conv.])
+ fi
+ 
+ if test "$use_int_type" == "int"; then
+   # If F77_INTEGER == int, leave it undefined here so that it will be
+   # defined by atlas_f77.h ... otherwise FunkyInts will get defined too.
+   F2CDEFS="$f2c_namedef $use_conv"
+ else
+   F2CDEFS="$f2c_namedef -DF77_INTEGER=$use_int_type $use_conv"
+ fi
+ LIBdir='$(TOPdir)/lib'
+ 
+ AC_SUBST(TOPdir)
+ AC_SUBST(UMMdir)
+ AC_SUBST(LIBdir)
+ 
+ ATLASlib="lib${with_libprefix}atlas.a"
+ CBLASlib="lib${with_libprefix}cblas.a"
+ F77BLASlib="lib${with_libprefix}f77blas.a"
+ PTCBLASlib="lib${with_libprefix}ptcblas.a"
+ PTF77BLASlib="lib${with_libprefix}ptf77blas.a"
+ LAPACKlib="lib${with_libprefix}prelapack.a"
+ 
+ AC_SUBST(ATLASlib)
+ AC_SUBST(CBLASlib)
+ AC_SUBST(F77BLASlib)
+ AC_SUBST(PTCBLASlib)
+ AC_SUBST(PTF77BLASlib)
+ AC_SUBST(LAPACKlib)
+ 
+ AC_SUBST(F2CDEFS)
+ AC_SUBST(UMMDEFS)
+ 
+ # --------------------------------------------------------------------
+ # Check for Architecture Defaults
+ # --------------------------------------------------------------------
+ 
+ if test "$ARCH0" == "US4"; then
+   use_arch="US2"
+ else
+   use_arch="$ARCH0"
+ fi
+ 
+ AC_MSG_CHECKING([for architectural defaults (CONFIG/ARCHS/$use_arch.tgz)])
+ if test -e "$srcdir/CONFIG/ARCHS/$use_arch.tgz"; then
+   AC_MSG_RESULT([found.])
+   mkdir -p CONFIG/ARCHS
+   gunzip -c $srcdir/CONFIG/ARCHS/$use_arch.tgz | tar xf - -C CONFIG/ARCHS
+ else
+   AC_MSG_ERROR([NOT FOUND.])
+ fi
+ 
+ AC_MSG_CHECKING([C compiler family])
+ if expr "$CC" : "icc" > /dev/null; then
+   AC_MSG_RESULT([ICC])
+   use_cc="icc"
+ elif expr "$CC" : "gcc" > /dev/null; then
+   AC_MSG_RESULT([GCC])
+   use_cc="gcc"
+ else
+   AC_MSG_RESULT([other ($CC))])
+   use_cc="$CC"
+ fi
+ 
+ ARCHBASE='$(TOPdir)/CONFIG/ARCHS'
+ ARCHDEF="$ARCHBASE/$use_arch/$use_cc/misc"
+ MMDEF="$ARCHBASE/$use_arch/$use_cc/gemm"
+ 
+ AC_SUBST(ARCHDEF)
+ AC_SUBST(MMDEF)
+ 
+ 
+ 
+ # --------------------------------------------------------------------
+ # Architecture identifying flags
+ # --------------------------------------------------------------------
+ 
+ if test "$os_name" != "Other"; then
+   ARCHDEFS="$ARCHDEFS -DATL_OS_$os_name"
+ fi
+ if test "$mach" != "Other"; then
+   ARCHDEFS="$ARCHDEFS -DATL_ARCH_$mach"
+ fi
+ if test "$USERMM" != ""; then
+   ARCHDEFS="$ARCHDEFS -DUSERGEMM"
+ fi
+ if test "$asmd" != "none"; then
+   ARCHDEFS="$ARCHDEFS -DATL_$asmd"
+ fi
+ 
+ 
+ AC_SUBST(ARCHDEFS)
+ 
+ 
+ 
+ # --------------------------------------------------------------------
+ # linker flags
+ # --------------------------------------------------------------------
+ 
+ # defaults
+ CLINKER='$(CC)'
+ CLINKFLAGS='$(CCFLAGS)'
+ 
+ FLINKER='$(F77)'
+ FLINKFLAGS='$(F77FLAGS)'
+ FCLINKFLAGS='$(FLINKFLAGS)'
+ 
+ if test $mach == "HP9735"; then
+   if test $os_name == "HPUX"; then
+     if test $F77 == "f77"; then
+       FLINKFLAGS="-Aa"
+     fi
+     if test $CC != "gcc"; then
+       CLINKFLAGS="-Aa"
+     fi
+   fi
+ fi
+ 
+ if test $F77 == "xlf"; then
+   FLINKFLAGS="FLINKFLAGS -bmaxdata:0x70000000"
+ fi
+ if test $CC == "xlc"; then
+   CLINKFLAGS="FLINKFLAGS -bmaxdata:0x70000000"
+ fi
+ 
+ AC_SUBST(CLINKER)
+ AC_SUBST(CLINKFLAGS)
+ AC_SUBST(FLINKER)
+ AC_SUBST(FLINKFLAGS)
+ AC_SUBST(FCLINKFLAGS)
+ 
+ # user C-defs
+ UCDEF=""
+ AC_SUBST(UCDEF)
+ 
+ # file open delay
+ if test "$enable_delay" == "yes"; then
+   DELAY_CDEF="-DATL_FOPENDELAY"
+   delay="1"
+ else
+   delay=""
+ fi
+ 
+ AC_SUBST(delay)
+ AC_SUBST(DELAY_CDEF)
+ 
+ GOODGCC=$CC
+ AC_SUBST(GOODGCC)
+ 
+ MCC='$(CC)'
+ MMFLAGS='$(CCFLAG0)'	# Note: MMFLAGS is always used with CDEFS.
+ 			#       We set it to CCFLAG0 (not CCFLAGS) to avoid
+ 			#       including CDEFS twice.
+ 
+ AC_SUBST(MCC)
+ AC_SUBST(MMFLAGS)
+ 
+ 
+ 
+ # --------------------------------------------------------------------
+ # cross-compiler flags
+ # --------------------------------------------------------------------
+ 
+ XCC='$(CC)'
+ XCCFLAGS='$(CCFLAGS)'
+ 
+ AC_SUBST(XCC)
+ AC_SUBST(XCCFLAGS)
+ 
+ AC_SUBST(ARCHIVER)
+ AC_SUBST(ARFLAGS)
+ AC_SUBST(RANLIB)
+ 
+ PMAKE='$(MAKE)'
+ AC_SUBST(PMAKE)
+ 
+ dnl AC_SUBST(BLASlib)
+ dnl AC_SUBST(LIBS)
+ dnl AC_SUBST(MMDEF)
+ dnl AC_SUBST(USEDEFL1)
+ dnl AC_SUBST(delay)
+ 
+ # --------------------------------------------------------------------
+ # ...
+ # --------------------------------------------------------------------
+ mkdir -p lib
+ mkdir -p include/$ARCH
+ touch include/$ARCH/atlas_cacheedge.h
+ touch include/$ARCH/zXover.h
+ touch include/$ARCH/cXover.h
+ touch include/$ARCH/dXover.h
+ touch include/$ARCH/sXover.h
+ cp $srcdir/makes/atlas_trsmNB.h include/$ARCH
+ 
+ mkdir -p src/blas/gemm/$ARCH/KERNEL
+ mkdir -p tune/blas/gemm/$ARCH/KERNEL
+ mkdir -p tune/blas/gemm/$ARCH/res
+ mkdir -p tune/blas/gemv/$ARCH/res
+ mkdir -p tune/blas/ger/$ARCH/res
+ mkdir -p tune/blas/level1/$ARCH/res
+ mkdir -p tune/blas/level1/$ARCH/GEN
+ mkdir -p tune/blas/level3/$ARCH/res
+ mkdir -p tune/sysinfo/$ARCH/res
+ 
+ mkdir -p CONFIG/ARCHS/$ARCH
+ mkdir -p bin/$ARCH/INSTALL_LOG
+ 
+ # refresh
+ if test "0" == "1"; then
+ #jpb# cp $srcdir/makes/Make.bin bin/$ARCH/Makefile
+ cp $srcdir/makes/Make.lib lib/$ARCH/Makefile
+ cp $srcdir/makes/Make.aux src/auxil/$ARCH/Makefile
+ cp $srcdir/makes/Make.l1ref src/blas/reference/level1/$ARCH/Makefile
+ cp $srcdir/makes/Make.l2ref src/blas/reference/level2/$ARCH/Makefile
+ cp $srcdir/makes/Make.l3ref src/blas/reference/level3/$ARCH/Makefile
+ cp $srcdir/makes/Make.tstsrc src/testing/$ARCH/Makefile
+ cp $srcdir/makes/Make.mvsrc src/blas/gemv/$ARCH/Makefile
+ cp $srcdir/makes/Make.r1src src/blas/ger/$ARCH/Makefile
+ cp $srcdir/makes/Make.mmsrc src/blas/gemm/$ARCH/Makefile
+ cp $srcdir/makes/Make.goto  src/blas/gemm/GOTO/$ARCH/Makefile
+ cp $srcdir/makes/Make.l1src src/blas/level1/$ARCH/Makefile
+ cp $srcdir/makes/Make.l2 src/blas/level2/$ARCH/Makefile
+ cp $srcdir/makes/Make.l2aux src/blas/level2/kernel/$ARCH/Makefile
+ cp $srcdir/makes/Make.lpsrc src/lapack/$ARCH/Makefile
+ cp $srcdir/makes/Make.l3tune tune/blas/level3/$ARCH/Makefile
+ cp $srcdir/makes/Make.mmtune tune/blas/gemm/$ARCH/Makefile
+ cp $srcdir/makes/Make.mvtune tune/blas/gemv/$ARCH/Makefile
+ cp $srcdir/makes/Make.r1tune tune/blas/ger/$ARCH/Makefile
+ cp $srcdir/makes/Make.l1tune tune/blas/level1/$ARCH/Makefile
+ cp $srcdir/makes/Make.sysinfo tune/sysinfo/$ARCH/Makefile
+ cp $srcdir/makes/Make.cblas interfaces/blas/C/src/$ARCH/Makefile
+ cp $srcdir/makes/Make.f77blas interfaces/blas/F77/src/$ARCH/Makefile
+ cp $srcdir/makes/Make.cblastst interfaces/blas/C/testing/$ARCH/Makefile
+ cp $srcdir/makes/Make.f77blastst interfaces/blas/F77/testing/$ARCH/Makefile
+ cp $srcdir/makes/Make.Clp interfaces/lapack/C/src/$ARCH/Makefile
+ cp $srcdir/makes/Make.Flp interfaces/lapack/F77/src/$ARCH/Makefile
+ cp $srcdir/makes/Make.l3ptblas src/pthreads/blas/level3/$ARCH/Makefile
+ cp $srcdir/makes/Make.l2ptblas src/pthreads/blas/level2/$ARCH/Makefile
+ cp $srcdir/makes/Make.l1ptblas src/pthreads/blas/level1/$ARCH/Makefile
+ cp $srcdir/makes/Make.miptblas src/pthreads/misc/$ARCH/Makefile
+ cp $srcdir/makes/Make.pkl3 src/blas/pklevel3/$ARCH/Makefile
+ cp $srcdir/makes/Make.gpmm src/blas/pklevel3/gpmm/$ARCH/Makefile
+ cp $srcdir/makes/Make.sprk src/blas/pklevel3/sprk/$ARCH/Makefile
+ cp $srcdir/makes/Make.l3 src/blas/level3/$ARCH/Makefile
+ cp $srcdir/makes/Make.l3aux src/blas/level3/rblas/$ARCH/Makefile
+ cp $srcdir/makes/Make.l3kern src/blas/level3/kernel/$ARCH/Makefile
+ #	cp makes/Make.Clptst interfaces/lapack/C/testing/$ARCH/Makefile
+ #	cp makes/Make.Flptst interfaces/lapack/F77/testing/$ARCH/Makefile
+ cp $srcdir/CONFIG/ATLrun.$ARCH bin/$ARCH/ATLrun.sh
+ fi
+ 
+ AC_CONFIG_FILES(
+    [Make.ARCH:Make.ARCH.in]
+    [GNUmakefile:GNUmakefile.in]
+    [src/blas/level1/$ARCH/Make.inc:src/blas/level1/Make.inc.in]
+    [src/blas/gemm/$ARCH/Make.inc:src/blas/gemm/Make.inc.in]
+    [src/blas/gemv/$ARCH/Make.inc:src/blas/gemv/Make.inc.in]
+    [src/blas/ger/$ARCH/Make.inc:src/blas/ger/Make.inc.in]
+ 
+    [bin/$ARCH/Makefile:bin/Makefile.in]
+    [interfaces/blas/C/src/$ARCH/Makefile:interfaces/blas/C/src/Makefile.in]
+    [interfaces/blas/C/testing/$ARCH/Makefile:interfaces/blas/C/testing/Makefile.in]
+    [interfaces/blas/F77/src/$ARCH/Makefile:interfaces/blas/F77/src/Makefile.in]
+    [interfaces/blas/F77/testing/$ARCH/Makefile:interfaces/blas/F77/testing/Makefile.in]
+    [interfaces/lapack/C/src/$ARCH/Makefile:interfaces/lapack/C/src/Makefile.in]
+    [interfaces/lapack/F77/src/$ARCH/Makefile:interfaces/lapack/F77/src/Makefile.in]
+    [lib/$ARCH/Makefile:lib/Makefile.in]
+    [src/auxil/$ARCH/Makefile:src/auxil/Makefile.in]
+    [src/blas/gemm/GOTO/$ARCH/Makefile:src/blas/gemm/GOTO/Makefile.in]
+    [src/blas/gemm/$ARCH/Makefile:src/blas/gemm/Makefile.in]
+    [src/blas/gemv/$ARCH/Makefile:src/blas/gemv/Makefile.in]
+    [src/blas/ger/$ARCH/Makefile:src/blas/ger/Makefile.in]
+    [src/blas/level1/$ARCH/Makefile:src/blas/level1/Makefile.in]
+    [src/blas/level2/kernel/$ARCH/Makefile:src/blas/level2/kernel/Makefile.in]
+    [src/blas/level2/$ARCH/Makefile:src/blas/level2/Makefile.in]
+    [src/blas/level3/kernel/$ARCH/Makefile:src/blas/level3/kernel/Makefile.in]
+    [src/blas/level3/rblas/$ARCH/Makefile:src/blas/level3/rblas/Makefile.in]
+    [src/blas/level3/$ARCH/Makefile:src/blas/level3/Makefile.in]
+    [src/blas/pklevel3/gpmm/$ARCH/Makefile:src/blas/pklevel3/gpmm/Makefile.in]
+    [src/blas/pklevel3/sprk/$ARCH/Makefile:src/blas/pklevel3/sprk/Makefile.in]
+    [src/blas/pklevel3/$ARCH/Makefile:src/blas/pklevel3/Makefile.in]
+    [src/blas/reference/level1/$ARCH/Makefile:src/blas/reference/level1/Makefile.in]
+    [src/blas/reference/level2/$ARCH/Makefile:src/blas/reference/level2/Makefile.in]
+    [src/blas/reference/level3/$ARCH/Makefile:src/blas/reference/level3/Makefile.in]
+    [src/lapack/$ARCH/Makefile:src/lapack/Makefile.in]
+    [src/pthreads/blas/level1/$ARCH/Makefile:src/pthreads/blas/level1/Makefile.in]
+    [src/pthreads/blas/level2/$ARCH/Makefile:src/pthreads/blas/level2/Makefile.in]
+    [src/pthreads/blas/level3/$ARCH/Makefile:src/pthreads/blas/level3/Makefile.in]
+    [src/pthreads/misc/$ARCH/Makefile:src/pthreads/misc/Makefile.in]
+    [src/testing/$ARCH/Makefile:src/testing/Makefile.in]
+    [tune/blas/gemm/$ARCH/Makefile:tune/blas/gemm/Makefile.in]
+    [tune/blas/gemv/$ARCH/Makefile:tune/blas/gemv/Makefile.in]
+    [tune/blas/ger/$ARCH/Makefile:tune/blas/ger/Makefile.in]
+    [tune/blas/level1/$ARCH/Makefile:tune/blas/level1/Makefile.in]
+    [tune/blas/level3/$ARCH/Makefile:tune/blas/level3/Makefile.in]
+    [tune/sysinfo/$ARCH/Makefile:tune/sysinfo/Makefile.in]
+    [bin/$ARCH/ATLrun.sh:bin/ATLrun.sh.in])
+ 
+ 
+ #
+ # Programs
+ #
+ AC_CHECK_PROGS(SH, sh)
+ AC_CHECK_PROGS(TAR, tar)
+ AC_CHECK_PROGS(GZIP, gzip)
+ AC_CHECK_PROGS(GUNZIP, gunzip)
+ 
+ #
+ # Installation
+ # 
+ AC_PROG_INSTALL
+ 
+ #
+ # Done.
+ #
+ AC_OUTPUT
+ 
+ chmod +x bin/$ARCH/ATLrun.sh
Index: vendor/atlas/bin/ATLrun.sh.in
===================================================================
RCS file: vendor/atlas/bin/ATLrun.sh.in
diff -N vendor/atlas/bin/ATLrun.sh.in
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- vendor/atlas/bin/ATLrun.sh.in	29 Nov 2005 20:24:10 -0000
***************
*** 0 ****
--- 1,5 ----
+ #! /bin/sh
+ 
+ atldir=$1
+ shift
+ $atldir/$*
Index: vendor/atlas/bin/atlas_install.c
===================================================================
RCS file: /home/cvs/Repository/atlas/bin/atlas_install.c,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 atlas_install.c
*** vendor/atlas/bin/atlas_install.c	29 Nov 2005 13:46:00 -0000	1.1.1.2
--- vendor/atlas/bin/atlas_install.c	29 Nov 2005 20:24:10 -0000
*************** void GoToTown(char *sdir, char *mmdir, i
*** 378,388 ****
--- 378,391 ----
        if (system(ln) == 0)
        {
           sprintf(ln, "make ISetDefaults defdir=%s mmdir=%s\n", sdir, mmdir);
+ 	 printf("## sdir  = %s\n", sdir);
+ 	 printf("## mmdir = %s\n", mmdir);
           ATL_Cassert(system(ln)==0, "SETTING ATLAS DEFAULTS", NULL);
           DefInstall = 1;
        }
        else sdir = NULL;
     }
+    ATL_Cassert(sdir, "ATLAS DEFAULTS NOT FOUND (sdir == NULL)", NULL);
  
     ATL_mprintf(2, stdout, fpsum,
                 "\n\nIN STAGE 1 INSTALL:  SYSTEM PROBE/AUX COMPILE\n");
Index: vendor/atlas/bin/atlas_tee.c
===================================================================
RCS file: /home/cvs/Repository/atlas/bin/atlas_tee.c,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 atlas_tee.c
*** vendor/atlas/bin/atlas_tee.c	29 Nov 2005 13:46:00 -0000	1.1.1.2
--- vendor/atlas/bin/atlas_tee.c	29 Nov 2005 20:24:10 -0000
***************
*** 29,34 ****
--- 29,35 ----
   */
  
  #include <stdio.h>
+ #include <stdlib.h>
  main(int nargs, char *args[])
  {
     char ln[512];
Index: vendor/atlas/bin/atlas_waitfile.c
===================================================================
RCS file: /home/cvs/Repository/atlas/bin/atlas_waitfile.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 atlas_waitfile.c
*** vendor/atlas/bin/atlas_waitfile.c	16 Nov 2005 21:03:26 -0000	1.1.1.1
--- vendor/atlas/bin/atlas_waitfile.c	29 Nov 2005 20:24:10 -0000
***************
*** 1,4 ****
--- 1,5 ----
  #include <stdio.h>
+ #include <stdlib.h>
  
  void PrintUsage(char *nam)
  {
Index: vendor/atlas/bin/ccobj.c
===================================================================
RCS file: /home/cvs/Repository/atlas/bin/ccobj.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 ccobj.c
*** vendor/atlas/bin/ccobj.c	16 Nov 2005 21:03:24 -0000	1.1.1.1
--- vendor/atlas/bin/ccobj.c	29 Nov 2005 20:24:10 -0000
***************
*** 1,4 ****
--- 1,5 ----
  #include <stdio.h>
+ #include <stdlib.h>
  #include <string.h>
  #include <ctype.h>
  #define Mstr2(m) # m
Index: vendor/atlas/csl-scripts/convert-makefile.pl
===================================================================
RCS file: vendor/atlas/csl-scripts/convert-makefile.pl
diff -N vendor/atlas/csl-scripts/convert-makefile.pl
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- vendor/atlas/csl-scripts/convert-makefile.pl	29 Nov 2005 20:24:11 -0000
***************
*** 0 ****
--- 1,79 ----
+ #! /usr/bin/perl
+ 
+ # convert-makefile.pl
+ # 2005-11-18
+ #
+ # Converts an ATLAS makefile from the makes/ directory to a Makefile.in
+ #  - places header on Makefile to find Make.ARCH and set paths
+ #  - corrects paths for include files
+ #
+ # This is meant to be called by the convert.sh script
+ 
+ use strict;
+ 
+ my ($from, $to) = @ARGV;
+ 
+ my @topath = split('/', $to);
+ 
+ pop @topath;
+ 
+ my $root = "";
+ foreach my $i (1 .. $#topath) {
+    $root .= "/..";
+    }
+ 
+ open(IN, $from)    || die "Can't read '$from': $!\n";
+ open(OUT, "> $to") || die "Can't write '$to': $!\n";
+ 
+ print OUT "# --------------------------------------------------------------\n";
+ print OUT "# DO NOT EDIT\n";
+ print OUT "# generated from '$from' by csl-scripts/convert-makefile.pl\n";
+ print OUT "# --------------------------------------------------------------\n";
+ print OUT "\n";
+ 
+ while (<IN>) {
+    if (/^include Make.inc$/) {
+       print OUT "include \@TOPdir@/Make.ARCH\n";
+       printf OUT "srcdir = \@top_srcdir@/%s\n", join('/', @topath);
+       printf OUT "top_srcdir = \@top_srcdir@\n";
+       print OUT "rootdir = \@srcdir\@$root\n";
+       }
+    else {
+       s/cd \.\.\/\.\.;/CSL_CD_UP2_CSL/g;
+       s/cd \.\.\//CSL_CD_UP1_CSL/g;
+ 
+       # rename $(INCdir)/../*.h
+       s/\$\(INCdir\)\/\.\.\/atlas_(misc|f77|tst|lvl[23]|level[123]|refalias[123]|reflevel[123]|enum|ptalias[123]|ptlvl3|ptlevel3|r1|kern3|refmisc|pkblas|mv|kernel[23]|rblas3|ptmisc|aux|lapack|l[23]ref|reflvl[23])\.h/\$(src_INCdir)\/atlas_$1\.h/g;
+       s/\$\(INCdir\)\/\.\.\/(cblas|cblas_test|clapack)\.h/\$(src_INCdir)\/$1\.h/g;
+ 
+       # rename $(L3Bdir)/../kernel/ATL_*.c
+       s/\$\(L3Bdir\)\/\.\.\/kernel\/ATL_(trsmL)\.c/\$(src_L3Bdir)\/kernel\/ATL_$1\.c/g;
+ 
+       s/ \.\.\// \$(srcdir)\//g;
+       s/CSL_CD_UP2_CSL/cd \.\.\/\.\.;/g;
+       s/CSL_CD_UP1_CSL/cd \.\.\//g;
+ 
+       my $tmp = $_;
+       my $missing = 0;
+       while ($tmp =~ /\$\(INCdir\)\/\.\.\/(.+)\.h/) {
+ 	 print "Missing: $1\n";
+ 	 $tmp =~ s/\$\(INCdir\)\/\.\.\/(.+)\.h//;
+ 	 $missing = 1;
+ 	 }
+       while ($tmp =~ /\$\(L3Bdir\)\/\.\.\/kernel\/([\w_]+)\.c/) {
+ 	 print "Missing: $1\n";
+ 	 $tmp =~ s/\$\(L3Bdir\)\/\.\.\/kernel\/([\w_]+)\.c//;
+ 	 $missing = 1;
+ 	 }
+       if ($missing) {
+ 	 print "  line : $_";
+ 	 print "  file : $from\n"
+ 	 }
+ 
+       print OUT $_;
+       }
+    }
+ 
+ close(IN);
+ close(OUT);
+ 
Index: vendor/atlas/csl-scripts/convert.sh
===================================================================
RCS file: vendor/atlas/csl-scripts/convert.sh
diff -N vendor/atlas/csl-scripts/convert.sh
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- vendor/atlas/csl-scripts/convert.sh	29 Nov 2005 20:24:11 -0000
***************
*** 0 ****
--- 1,70 ----
+ #! /bin/sh
+ 
+ # csl-sciprts/convert.sh
+ # 2005-11-18
+ 
+ # DESCRIPTION
+ #   automates the conversion of ATLAS makefiles to .in files
+ #   suitable for use with configure.
+ #
+ #   The files produced by this script are stored in CVS.
+ #
+ #   This script is not part of the usual build or release process.  It
+ #   only needs to be run when a new upstream ATLAS version is
+ #   imported, or when a new substitution is added to
+ #   convert-makefile.pl
+ #
+ # USAGE
+ #   (in the vendor/atlas directory):
+ #   csl-scripts/convert.sh
+ 
+ 
+ CMF="csl-scripts/convert-makefile.pl"
+ CMI="csl-scripts/create-makeinc.pl"
+ 
+ $CMI src/blas/level1/Make.inc.in
+ $CMI src/blas/gemm/Make.inc.in
+ $CMI src/blas/gemv/Make.inc.in
+ $CMI src/blas/ger/Make.inc.in
+ 
+ $CMF makes/Make.bin bin/Makefile.in
+ $CMF makes/Make.lib lib/Makefile.in
+ $CMF makes/Make.aux src/auxil/Makefile.in
+ $CMF makes/Make.l1ref src/blas/reference/level1/Makefile.in
+ $CMF makes/Make.l2ref src/blas/reference/level2/Makefile.in
+ $CMF makes/Make.l3ref src/blas/reference/level3/Makefile.in
+ $CMF makes/Make.tstsrc src/testing/Makefile.in
+ $CMF makes/Make.mvsrc src/blas/gemv/Makefile.in
+ $CMF makes/Make.r1src src/blas/ger/Makefile.in
+ $CMF makes/Make.mmsrc src/blas/gemm/Makefile.in
+ $CMF makes/Make.goto  src/blas/gemm/GOTO/Makefile.in
+ $CMF makes/Make.l1src src/blas/level1/Makefile.in
+ $CMF makes/Make.l2 src/blas/level2/Makefile.in
+ $CMF makes/Make.l2aux src/blas/level2/kernel/Makefile.in
+ $CMF makes/Make.lpsrc src/lapack/Makefile.in
+ $CMF makes/Make.l3tune tune/blas/level3/Makefile.in
+ $CMF makes/Make.mmtune tune/blas/gemm/Makefile.in
+ $CMF makes/Make.mvtune tune/blas/gemv/Makefile.in
+ $CMF makes/Make.r1tune tune/blas/ger/Makefile.in
+ $CMF makes/Make.l1tune tune/blas/level1/Makefile.in
+ $CMF makes/Make.sysinfo tune/sysinfo/Makefile.in
+ $CMF makes/Make.cblas interfaces/blas/C/src/Makefile.in
+ $CMF makes/Make.f77blas interfaces/blas/F77/src/Makefile.in
+ $CMF makes/Make.cblastst interfaces/blas/C/testing/Makefile.in
+ $CMF makes/Make.f77blastst interfaces/blas/F77/testing/Makefile.in
+ $CMF makes/Make.Clp interfaces/lapack/C/src/Makefile.in
+ $CMF makes/Make.Flp interfaces/lapack/F77/src/Makefile.in
+ $CMF makes/Make.l3ptblas src/pthreads/blas/level3/Makefile.in
+ $CMF makes/Make.l2ptblas src/pthreads/blas/level2/Makefile.in
+ $CMF makes/Make.l1ptblas src/pthreads/blas/level1/Makefile.in
+ $CMF makes/Make.miptblas src/pthreads/misc/Makefile.in
+ $CMF makes/Make.pkl3 src/blas/pklevel3/Makefile.in
+ $CMF makes/Make.gpmm src/blas/pklevel3/gpmm/Makefile.in
+ $CMF makes/Make.sprk src/blas/pklevel3/sprk/Makefile.in
+ $CMF makes/Make.l3 src/blas/level3/Makefile.in
+ $CMF makes/Make.l3aux src/blas/level3/rblas/Makefile.in
+ $CMF makes/Make.l3kern src/blas/level3/kernel/Makefile.in
+ #$CMF makes/Make.Clptst interfaces/lapack/C/testing/Makefile.in
+ #$CMF makes/Make.Flptst interfaces/lapack/F77/testing/Makefile.in
+ ## $CMF CONFIG/ATLrun. bin/$(arch)/ATLrun.sh
+ 
Index: vendor/atlas/csl-scripts/create-makeinc.pl
===================================================================
RCS file: vendor/atlas/csl-scripts/create-makeinc.pl
diff -N vendor/atlas/csl-scripts/create-makeinc.pl
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- vendor/atlas/csl-scripts/create-makeinc.pl	29 Nov 2005 20:24:11 -0000
***************
*** 0 ****
--- 1,26 ----
+ #! /usr/bin/perl
+ 
+ use strict;
+ 
+ my ($file) = @ARGV;
+ 
+ my @path = split('/', $file);
+ 
+ pop @path;
+ 
+ my $root = "";
+ foreach my $i (1 .. $#path) {
+    $root .= "/..";
+    }
+ 
+ open(OUT, "> $file") || die "Can't write '$file': $!\n";
+ 
+ print OUT "# generated by create-makeinc.pl\n";
+ 
+ print  OUT "include \@TOPdir@/Make.ARCH\n";
+ printf OUT "srcdir = \@top_srcdir@/%s\n", join('/', @path);
+ printf OUT "top_srcdir = \@top_srcdir@\n";
+ print  OUT "rootdir = \@srcdir\@$root\n";
+ 
+ close(OUT);
+ 
Index: vendor/atlas/include/contrib/ATL_gemv_ger_SSE.h
===================================================================
RCS file: /home/cvs/Repository/atlas/include/contrib/ATL_gemv_ger_SSE.h,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 ATL_gemv_ger_SSE.h
*** vendor/atlas/include/contrib/ATL_gemv_ger_SSE.h	16 Nov 2005 21:03:27 -0000	1.1.1.1
--- vendor/atlas/include/contrib/ATL_gemv_ger_SSE.h	29 Nov 2005 20:24:11 -0000
***************
*** 18,23 ****
--- 18,24 ----
  
  #include <stdio.h>
  #include <stdlib.h>
+ #include <string.h>
  
  #include "camm_util.h"
  
Index: vendor/atlas/makes/Make.bin
===================================================================
RCS file: /home/cvs/Repository/atlas/makes/Make.bin,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 Make.bin
*** vendor/atlas/makes/Make.bin	29 Nov 2005 13:45:59 -0000	1.1.1.2
--- vendor/atlas/makes/Make.bin	29 Nov 2005 20:24:11 -0000
*************** IPostTune:
*** 65,71 ****
  error_report :
  	cd ../.. ; $(MAKE) error_report arch=$(ARCH)
  IBozoL1:
! 	cd $(TOPdir)/CONFIG/ARCHS ; $(GUNZIP) -c BOZOL1.tgz | tar xvf -
  	$(MAKE) IL1Defaults defdir=$(TOPdir)/CONFIG/ARCHS/BOZOL1
  
  IL1Defaults:
--- 65,71 ----
  error_report :
  	cd ../.. ; $(MAKE) error_report arch=$(ARCH)
  IBozoL1:
! 	$(GUNZIP) -c $(top_srcdir)/CONFIG/ARCHS/BOZOL1.tgz | tar xvf - -C $(TOPdir)/CONFIG/ARCHS
  	$(MAKE) IL1Defaults defdir=$(TOPdir)/CONFIG/ARCHS/BOZOL1
  
  IL1Defaults:
Index: vendor/atlas/src/auxil/ATL_buildinfo.c
===================================================================
RCS file: /home/cvs/Repository/atlas/src/auxil/ATL_buildinfo.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 ATL_buildinfo.c
*** vendor/atlas/src/auxil/ATL_buildinfo.c	16 Nov 2005 21:03:45 -0000	1.1.1.1
--- vendor/atlas/src/auxil/ATL_buildinfo.c	29 Nov 2005 20:24:11 -0000
***************
*** 1,3 ****
--- 1,4 ----
+ #include <stdio.h>
  #include "atlas_buildinfo.h"
  #include "atlas_cacheedge.h"
  
Index: vendor/atlas/tune/blas/gemm/emit_mm.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/gemm/emit_mm.c,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 emit_mm.c
*** vendor/atlas/tune/blas/gemm/emit_mm.c	29 Nov 2005 13:46:03 -0000	1.1.1.2
--- vendor/atlas/tune/blas/gemm/emit_mm.c	29 Nov 2005 20:24:12 -0000
*************** void GenAllUNBCases(char pre, enum CW wh
*** 3363,3369 ****
  {
     char cwh[3] = {'M', 'N', 'K'};
     char cbeta[3] = {'0', '1', 'X'};
!    char ln[128];
     int i, j, n, *NBs, NB[3];
     FILE *fp;
  
--- 3363,3369 ----
  {
     char cwh[3] = {'M', 'N', 'K'};
     char cbeta[3] = {'0', '1', 'X'};
!    char ln[1024];
     int i, j, n, *NBs, NB[3];
     FILE *fp;
  
*************** void GenAllUNBCases(char pre, enum CW wh
*** 3384,3390 ****
           emit_uhead(fp, pre, which, NB[0], NB[1], NB[2], cp->imult, cp->fixed,
                      cp->NBs[j], i);
           fclose(fp);
!          sprintf(ln, "cat ../CASES/%s >> KERNEL/ATL_%cup%cBmm%d_%d_%d_b%c.c\n",
                   cp->rout, pre, cwh[which], NBs[j], cp->imult, cp->fixed,
                   cbeta[i]);
           assert(system(ln) == 0);
--- 3384,3391 ----
           emit_uhead(fp, pre, which, NB[0], NB[1], NB[2], cp->imult, cp->fixed,
                      cp->NBs[j], i);
           fclose(fp);
!          sprintf(ln, "cat %s/tune/blas/gemm/CASES/%s >> KERNEL/ATL_%cup%cBmm%d_%d_%d_b%c.c\n",
! 		 SRCDIR,
                   cp->rout, pre, cwh[which], NBs[j], cp->imult, cp->fixed,
                   cbeta[i]);
           assert(system(ln) == 0);
*************** CLEANNODE *DoUNBmm(char pre, double gmf)
*** 3612,3619 ****
           assert(fp);
           emit_uhead(fp, pre, CleanNot, nb, nb, nb, nb, nb, 0, i);
           fclose(fp);
!          sprintf(ln, "cat ../CASES/%s >> KERNEL/ATL_%cNBmm_b%c.c",
!                  cp->rout, pre, beta[i]);
           assert(system(ln) == 0);
        }
     }
--- 3613,3620 ----
           assert(fp);
           emit_uhead(fp, pre, CleanNot, nb, nb, nb, nb, nb, 0, i);
           fclose(fp);
!          sprintf(ln, "cat %s/tune/blas/gemm/CASES/%s >> KERNEL/ATL_%cNBmm_b%c.c",
! 		 SRCDIR, cp->rout, pre, beta[i]);
           assert(system(ln) == 0);
        }
     }
Index: vendor/atlas/tune/blas/gemm/tfc.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/gemm/tfc.c,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 tfc.c
*** vendor/atlas/tune/blas/gemm/tfc.c	29 Nov 2005 13:46:03 -0000	1.1.1.2
--- vendor/atlas/tune/blas/gemm/tfc.c	29 Nov 2005 20:24:12 -0000
*************** int mmcase(char TA, char TB, int M, int 
*** 171,178 ****
  /*
   * preload instructions from disk
   */
!    small_gemm(TAc, TBc, 80, 80, 80, alpha, a, 80, b, 80, beta, c, 80);
!    big_gemm(TAc, TBc, 80, 80, 80, alpha, a, 80, b, 80, beta, c, 80);
     matgen(la, 1, A, la, K*1112);
     matgen(lb, 1, B, lb, N*1287);
     matgen(lc, 1, C, lc, M*N);
--- 171,178 ----
  /*
   * preload instructions from disk
   */
!    small_gemm(TAc, TBc, M, N, K, alpha, a, lda, b, ldb, beta, c, ldc);
!    big_gemm(TAc, TBc, M, N, K, alpha, a, lda, b, ldb, beta, c, ldc);
     matgen(la, 1, A, la, K*1112);
     matgen(lb, 1, B, lb, N*1287);
     matgen(lc, 1, C, lc, M*N);
Index: vendor/atlas/tune/blas/gemm/ummsearch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/gemm/ummsearch.c,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 ummsearch.c
*** vendor/atlas/tune/blas/gemm/ummsearch.c	29 Nov 2005 13:46:03 -0000	1.1.1.2
--- vendor/atlas/tune/blas/gemm/ummsearch.c	29 Nov 2005 20:24:12 -0000
*************** double ummcase0
*** 737,744 ****
     if (!FileExists(outnam))
     {
        if (pre == 'c' || pre == 'z')
!          i = sprintf(ln, "make cmmucase mmrout=../CASES/%s csC=2 ", fnam);
!       else i = sprintf(ln, "make mmucase mmrout=../CASES/%s ", fnam);
        if (MCC) i += sprintf(ln+i, "MCC=\"%s\" MMFLAGS=\"%s\" ", MCC, MMFLAGS);
        i += sprintf(ln+i, "casnam=%s ", outnam);
        i += sprintf(ln+i, "pre=%c muladd=%d lat=%d M=%d N=%d K=%d mb=%d nb=%d kb=%d mu=%d nu=%d ku=%d lda=%d ldb=%d ldc=%d ",
--- 737,744 ----
     if (!FileExists(outnam))
     {
        if (pre == 'c' || pre == 'z')
!          i = sprintf(ln, "make cmmucase mmrout=%s/tune/blas/gemm/CASES/%s csC=2 ", SRCDIR, fnam);
!       else i = sprintf(ln, "make mmucase mmrout=%s/tune/blas/gemm/CASES/%s ", SRCDIR, fnam);
        if (MCC) i += sprintf(ln+i, "MCC=\"%s\" MMFLAGS=\"%s\" ", MCC, MMFLAGS);
        i += sprintf(ln+i, "casnam=%s ", outnam);
        i += sprintf(ln+i, "pre=%c muladd=%d lat=%d M=%d N=%d K=%d mb=%d nb=%d kb=%d mu=%d nu=%d ku=%d lda=%d ldb=%d ldc=%d ",
*************** int ummtstcase0
*** 998,1005 ****
     int i;
  
     if (pre == 'c' || pre == 'z')
!       i = sprintf(ln, "make cmmutstcase mmrout=../CASES/%s csC=2 ", fnam);
!    else i = sprintf(ln, "make mmutstcase mmrout=../CASES/%s ", fnam);
     if (MCC) i += sprintf(ln+i, "MCC=\"%s\" MMFLAGS=\"%s\" ", MCC, MMFLAGS);
     i += sprintf(ln+i, "pre=%c muladd=%d lat=%d M=%d N=%d K=%d mb=%d nb=%d kb=%d mu=%d nu=%d ku=%d lda=%d ldb=%d ldc=%d ",
                  pre, muladd, lat, M, N, K, mb, nb, kb, mu, nu, ku,
--- 998,1005 ----
     int i;
  
     if (pre == 'c' || pre == 'z')
!       i = sprintf(ln, "make cmmutstcase mmrout=%s/tune/blas/gemm/CASES/%s csC=2 ", SRCDIR, fnam);
!    else i = sprintf(ln, "make mmutstcase mmrout=%s/tune/blas/gemm/CASES/%s ", SRCDIR, fnam);
     if (MCC) i += sprintf(ln+i, "MCC=\"%s\" MMFLAGS=\"%s\" ", MCC, MMFLAGS);
     i += sprintf(ln+i, "pre=%c muladd=%d lat=%d M=%d N=%d K=%d mb=%d nb=%d kb=%d mu=%d nu=%d ku=%d lda=%d ldb=%d ldc=%d ",
                  pre, muladd, lat, M, N, K, mb, nb, kb, mu, nu, ku,
Index: vendor/atlas/tune/blas/gemm/usercomb.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/gemm/usercomb.c,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 usercomb.c
*** vendor/atlas/tune/blas/gemm/usercomb.c	29 Nov 2005 13:46:03 -0000	1.1.1.2
--- vendor/atlas/tune/blas/gemm/usercomb.c	29 Nov 2005 20:24:12 -0000
***************
*** 29,34 ****
--- 29,35 ----
   */
  #include <stdio.h>
  #include <stdlib.h>
+ #include <string.h>
  #include <assert.h>
  
  int LineIsCont(char *ln)
Index: vendor/atlas/tune/blas/gemm/userindex.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/gemm/userindex.c,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 userindex.c
*** vendor/atlas/tune/blas/gemm/userindex.c	29 Nov 2005 13:46:03 -0000	1.1.1.2
--- vendor/atlas/tune/blas/gemm/userindex.c	29 Nov 2005 20:24:12 -0000
*************** void CreateIndex(char pre)
*** 62,78 ****
     char fnams[8][256];
     int n=1, i, j, itmp;
  
!    sprintf(fnams[0], "../CASES/%ccases.0", pre);
     #ifdef ATL_SSE1
        #ifdef ATL_SSE2
           if (pre == 'd' || pre == 'z')
!             sprintf(fnams[n++], "../CASES/%ccases.SSE", pre);
        #endif
        if (pre == 's' || pre == 'c')
!          sprintf(fnams[n++], "../CASES/%ccases.SSE", pre);
     #elif (defined(ATL_3DNow1) || defined(ATL_3DNow2)) && defined(ATL_3DNowFLOPS)
        if (pre == 's' || pre == 'c')
!          sprintf(fnams[n++], "../CASES/%ccases.3DN", pre);
     #endif
     sprintf(ln, "make FindFlagCases pre=%c outfile=%ccases.tmp\n", pre, pre);
     assert(system(ln) == 0);
--- 62,78 ----
     char fnams[8][256];
     int n=1, i, j, itmp;
  
!    sprintf(fnams[0], "%s/tune/blas/gemm/CASES/%ccases.0", SRCDIR, pre);
     #ifdef ATL_SSE1
        #ifdef ATL_SSE2
           if (pre == 'd' || pre == 'z')
!             sprintf(fnams[n++], "%s/tune/blas/gemm/CASES/%ccases.SSE", SRCDIR, pre);
        #endif
        if (pre == 's' || pre == 'c')
!          sprintf(fnams[n++], "%s/tune/blas/gemm/CASES/%ccases.SSE", SRCDIR, pre);
     #elif (defined(ATL_3DNow1) || defined(ATL_3DNow2)) && defined(ATL_3DNowFLOPS)
        if (pre == 's' || pre == 'c')
!          sprintf(fnams[n++], "%s/tune/blas/gemm/CASES/%ccases.3DN", SRCDIR, pre);
     #endif
     sprintf(ln, "make FindFlagCases pre=%c outfile=%ccases.tmp\n", pre, pre);
     assert(system(ln) == 0);
Index: vendor/atlas/tune/blas/gemv/gemvtune.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/gemv/gemvtune.c,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 gemvtune.c
*** vendor/atlas/tune/blas/gemv/gemvtune.c	29 Nov 2005 13:46:03 -0000	1.1.1.2
--- vendor/atlas/tune/blas/gemv/gemvtune.c	29 Nov 2005 20:24:12 -0000
***************
*** 28,33 ****
--- 28,34 ----
   *
   */
  
+ #include <string.h>
  #include "atlas_misc.h"
  #include "atlas_lvl2.h"
  #include "atlas_fopen.h"
Index: vendor/atlas/tune/blas/gemv/mvsearch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/gemv/mvsearch.c,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 mvsearch.c
*** vendor/atlas/tune/blas/gemv/mvsearch.c	29 Nov 2005 13:46:03 -0000	1.1.1.2
--- vendor/atlas/tune/blas/gemv/mvsearch.c	29 Nov 2005 20:24:12 -0000
***************
*** 30,35 ****
--- 30,36 ----
  
  #include <stdio.h>
  #include <stdlib.h>
+ #include <string.h>
  #include <ctype.h>
  #include <assert.h>
  #include "atlas_fopen.h"
*************** double svcase
*** 144,151 ****
     if (mf == -1.0)
     {
        fprintf(stderr,
! "\n\n%s : VARIATION EXCEEDS TOLERENCE, RERUN WITH HIGHER REPS.\n\n", fnam);
!       sprintf(ln, "rm -f %s\n", fnam);
        system(ln);
        exit(-1);
     }
--- 145,153 ----
     if (mf == -1.0)
     {
        fprintf(stderr,
! "\n\n%s : VARIATION EXCEEDS TOLERENCE, RERUN WITH HIGHER REPS 1.\n\n", fnam);
!       sprintf(ln, "mv %s %s-bad\n", fnam, fnam);
!       // sprintf(ln, "rm -f %s\n", fnam);
        system(ln);
        exit(-1);
     }
*************** double mvcase(int SY, char pre, char *mv
*** 161,166 ****
--- 163,169 ----
     int i, mb;
     double mfs[3], mf;
     FILE *fp;
+    int try, num_tries=3;
  
     if (TA == 'n' || TA == 'N') nTA = 'T';
     else nTA = 'N';
*************** double mvcase(int SY, char pre, char *mv
*** 173,178 ****
--- 176,184 ----
        if (ATL_MVNoBlock(flag)) sprintf(fnam, "res/%cgemv%c_%d_0", pre, TA, cas);
        else sprintf(fnam, "res/%cgemv%c_%d_%d", pre, TA, cas, imul);
     }
+ 
+    for (try=0; try<num_tries; try++)
+    {
     if (!FileExists(fnam))
     {
        i = sprintf(ln, "make %cmvcase%c mvrout=%s cas=%d xu=%d yu=%d l1mul=%d iflag=%d gmvout=\"-o %s\"",
*************** double mvcase(int SY, char pre, char *mv
*** 199,205 ****
           i += sprintf(ln+i, " opt=\"-2 1 -L %d\" M=%d N=%d", mb, mb, nu);
        }
        sprintf(ln+i, "\n");
!       fprintf(stderr, "%s", ln);
        if (system(ln)) return(-1.0);  /* won't compile here */
     }
     fp = fopen(fnam, "r");
--- 205,211 ----
           i += sprintf(ln+i, " opt=\"-2 1 -L %d\" M=%d N=%d", mb, mb, nu);
        }
        sprintf(ln+i, "\n");
!       fprintf(stderr, "======\n%s=====\n", ln);
        if (system(ln)) return(-1.0);  /* won't compile here */
     }
     fp = fopen(fnam, "r");
*************** double mvcase(int SY, char pre, char *mv
*** 207,217 ****
     assert(fscanf(fp, " %lf %lf %lf", mfs, mfs+1, mfs+2) == 3);
     fclose(fp);
     mf = GetAvg(3, 1.20, mfs);
     if (mf == -1.0)
     {
        fprintf(stderr,
! "\n\n%s : VARIATION EXCEEDS TOLERENCE, RERUN WITH HIGHER REPS.\n\n", fnam);
!       sprintf(ln, "rm -f %s\n", fnam);
        system(ln);
        exit(-1);
     }
--- 213,237 ----
     assert(fscanf(fp, " %lf %lf %lf", mfs, mfs+1, mfs+2) == 3);
     fclose(fp);
     mf = GetAvg(3, 1.20, mfs);
+ 
+    if (mf == -1.0)
+    {
+       fprintf(stderr,
+ "\n\n%s : VARIATION EXCEEDS TOLERENCE, TRYING AGAIN.\n", fnam);
+       sprintf(ln, "mv %s %s-bad-%d\n", fnam, fnam, try);
+       system(ln);
+    }
+    else
+       break;
+    }
+ 
     if (mf == -1.0)
     {
        fprintf(stderr,
! "\n\n%s : VARIATION EXCEEDS TOLERENCE, RERUN WITH HIGHER REPS 2.\n\n", fnam);
!       fprintf(stderr, "Moving file aside as %s-bad\n", fnam);
!       sprintf(ln, "mv %s %s-bad\n", fnam, fnam);
!       // sprintf(ln, "rm -f %s\n", fnam);
        system(ln);
        exit(-1);
     }
Index: vendor/atlas/tune/blas/ger/ger1tune.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/ger/ger1tune.c,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 ger1tune.c
*** vendor/atlas/tune/blas/ger/ger1tune.c	29 Nov 2005 13:46:04 -0000	1.1.1.2
--- vendor/atlas/tune/blas/ger/ger1tune.c	29 Nov 2005 20:24:12 -0000
***************
*** 28,33 ****
--- 28,34 ----
   *
   */
  
+ #include <string.h>
  #include "atlas_misc.h"
  #include "atlas_lvl2.h"
  #include "atlas_fopen.h"
Index: vendor/atlas/tune/blas/ger/r1search.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/ger/r1search.c,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 r1search.c
*** vendor/atlas/tune/blas/ger/r1search.c	29 Nov 2005 13:46:04 -0000	1.1.1.2
--- vendor/atlas/tune/blas/ger/r1search.c	29 Nov 2005 20:24:13 -0000
***************
*** 30,35 ****
--- 30,36 ----
  
  #include <stdio.h>
  #include <stdlib.h>
+ #include <string.h>
  #include <ctype.h>
  #include <assert.h>
  #include "atlas_fopen.h"
*************** double r1case(char pre, char *r1nam, int
*** 140,148 ****
--- 141,153 ----
     double mf, mfs[3];
     int i;
     FILE *fp;
+    int try, num_tries=3;
  
     if (ATL_NoBlock(flag)) sprintf(fnam, "res/%cger1_%d_0", pre, cas);
     else sprintf(fnam, "res/%cger1_%d_%d", pre, cas, l1mul);
+ 
+    for (try=0; try<num_tries; try++)
+    {
     if (!FileExists(fnam))
     {
        i = sprintf(ln,
*************** double r1case(char pre, char *r1nam, int
*** 161,171 ****
     assert(fscanf(fp, " %lf %lf %lf", mfs, mfs+1, mfs+2) == 3);
     fclose(fp);
     mf = GetAvg(3, 1.20, mfs);
     if (mf == -1.0)
     {
        fprintf(stderr,
  "\n\n%s : VARIATION EXCEEDS TOLERENCE, RERUN WITH HIGHER REPS.\n\n", fnam);
!       sprintf(ln, "rm -f %s\n", fnam);
        system(ln);
        exit(-1);
     }
--- 166,190 ----
     assert(fscanf(fp, " %lf %lf %lf", mfs, mfs+1, mfs+2) == 3);
     fclose(fp);
     mf = GetAvg(3, 1.20, mfs);
+ 
+    if (mf == -1.0)
+    {
+       fprintf(stderr,
+ "\n\n%s : (r1search) VARIATION EXCEEDS TOLERENCE, TRYING AGAIN.\n", fnam);
+       sprintf(ln, "mv %s %s-bad-%d\n", fnam, fnam, try);
+       system(ln);
+    }
+    else
+       break;
+    } // for
+ 
     if (mf == -1.0)
     {
        fprintf(stderr,
  "\n\n%s : VARIATION EXCEEDS TOLERENCE, RERUN WITH HIGHER REPS.\n\n", fnam);
!       fprintf(stderr, "Moving file aside as %s-bad\n", fnam);
!       sprintf(ln, "mv %s %s-bad\n", fnam, fnam);
!       // sprintf(ln, "rm -f %s\n", fnam);
        system(ln);
        exit(-1);
     }
Index: vendor/atlas/tune/blas/level1/asumsrch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/level1/asumsrch.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 asumsrch.c
*** vendor/atlas/tune/blas/level1/asumsrch.c	16 Nov 2005 21:03:52 -0000	1.1.1.1
--- vendor/atlas/tune/blas/level1/asumsrch.c	29 Nov 2005 20:24:13 -0000
*************** void DumpFile(char *fnam, FILE *fpout)
*** 693,699 ****
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "../ASUM/%s", fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
--- 693,699 ----
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "%s/tune/blas/level1/ASUM/%s", SRCDIR, fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
Index: vendor/atlas/tune/blas/level1/axpbysrch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/level1/axpbysrch.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 axpbysrch.c
*** vendor/atlas/tune/blas/level1/axpbysrch.c	16 Nov 2005 21:03:53 -0000	1.1.1.1
--- vendor/atlas/tune/blas/level1/axpbysrch.c	29 Nov 2005 20:24:13 -0000
*************** void DumpFile(char *fnam, FILE *fpout)
*** 1025,1031 ****
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "../AXPBY/%s", fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
--- 1025,1031 ----
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "%s/tune/blas/level1/AXPBY/%s", SRCDIR, fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
Index: vendor/atlas/tune/blas/level1/axpysrch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/level1/axpysrch.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 axpysrch.c
*** vendor/atlas/tune/blas/level1/axpysrch.c	16 Nov 2005 21:03:52 -0000	1.1.1.1
--- vendor/atlas/tune/blas/level1/axpysrch.c	29 Nov 2005 20:24:13 -0000
*************** void DumpFile(char *fnam, FILE *fpout)
*** 880,887 ****
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "../AXPY/%s", fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
     fclose(fpin);
--- 880,891 ----
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "%s/tune/blas/level1/AXPY/%s", SRCDIR, fnam);
     fpin = fopen(ln, "r");
+    if (!fpin) {
+       fprintf(stderr, "rotsrch: fopen(%s) FAILED\n", ln);
+       exit(-1);
+       }
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
     fclose(fpin);
Index: vendor/atlas/tune/blas/level1/copysrch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/level1/copysrch.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 copysrch.c
*** vendor/atlas/tune/blas/level1/copysrch.c	16 Nov 2005 21:03:53 -0000	1.1.1.1
--- vendor/atlas/tune/blas/level1/copysrch.c	29 Nov 2005 20:24:13 -0000
*************** void DumpFile(char *fnam, FILE *fpout)
*** 801,807 ****
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "../COPY/%s", fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
--- 801,807 ----
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "%s/tune/blas/level1/COPY/%s", SRCDIR, fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
Index: vendor/atlas/tune/blas/level1/cpscsrch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/level1/cpscsrch.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 cpscsrch.c
*** vendor/atlas/tune/blas/level1/cpscsrch.c	16 Nov 2005 21:03:53 -0000	1.1.1.1
--- vendor/atlas/tune/blas/level1/cpscsrch.c	29 Nov 2005 20:24:13 -0000
*************** void DumpFile(char *fnam, FILE *fpout)
*** 900,906 ****
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "../CPSC/%s", fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
--- 900,906 ----
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "%s/tune/blas/level1/CPSC/%s", SRCDIR, fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
Index: vendor/atlas/tune/blas/level1/dotsrch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/level1/dotsrch.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 dotsrch.c
*** vendor/atlas/tune/blas/level1/dotsrch.c	16 Nov 2005 21:03:54 -0000	1.1.1.1
--- vendor/atlas/tune/blas/level1/dotsrch.c	29 Nov 2005 20:24:13 -0000
*************** void DumpFile(char *fnam, FILE *fpout)
*** 841,847 ****
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "../DOT/%s", fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
--- 841,847 ----
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "%s/tune/blas/level1/DOT/%s", SRCDIR, fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
Index: vendor/atlas/tune/blas/level1/iamaxsrch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/level1/iamaxsrch.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 iamaxsrch.c
*** vendor/atlas/tune/blas/level1/iamaxsrch.c	16 Nov 2005 21:03:54 -0000	1.1.1.1
--- vendor/atlas/tune/blas/level1/iamaxsrch.c	29 Nov 2005 20:24:13 -0000
*************** void DumpFile(char *fnam, FILE *fpout)
*** 681,687 ****
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "../IAMAX/%s", fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
--- 681,687 ----
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "%s/tune/blas/level1/IAMAX/%s", SRCDIR, fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
Index: vendor/atlas/tune/blas/level1/nrm2srch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/level1/nrm2srch.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 nrm2srch.c
*** vendor/atlas/tune/blas/level1/nrm2srch.c	16 Nov 2005 21:03:54 -0000	1.1.1.1
--- vendor/atlas/tune/blas/level1/nrm2srch.c	29 Nov 2005 20:24:13 -0000
*************** void DumpFile(char *fnam, FILE *fpout)
*** 692,698 ****
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "../NRM2/%s", fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
--- 692,698 ----
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "%s/tune/blas/level1/NRM2/%s", SRCDIR, fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
Index: vendor/atlas/tune/blas/level1/rotsrch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/level1/rotsrch.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 rotsrch.c
*** vendor/atlas/tune/blas/level1/rotsrch.c	16 Nov 2005 21:03:55 -0000	1.1.1.1
--- vendor/atlas/tune/blas/level1/rotsrch.c	29 Nov 2005 20:24:13 -0000
*************** void DumpFile(char *fnam, FILE *fpout)
*** 971,978 ****
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "../ROT/%s", fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
     fclose(fpin);
--- 971,982 ----
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "%s/tune/blas/level1/ROT/%s", SRCDIR, fnam);
     fpin = fopen(ln, "r");
+    if (!fpin) {
+       fprintf(stderr, "rotsrch: fopen(%s) FAILED\n", ln);
+       exit(-1);
+       }
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
     fclose(fpin);
Index: vendor/atlas/tune/blas/level1/scalsrch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/level1/scalsrch.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 scalsrch.c
*** vendor/atlas/tune/blas/level1/scalsrch.c	16 Nov 2005 21:03:54 -0000	1.1.1.1
--- vendor/atlas/tune/blas/level1/scalsrch.c	29 Nov 2005 20:24:13 -0000
*************** void DumpFile(char *fnam, FILE *fpout)
*** 789,795 ****
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "../SCAL/%s", fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
--- 789,795 ----
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "%s/tune/blas/level1/SCAL/%s", SRCDIR, fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
Index: vendor/atlas/tune/blas/level1/setsrch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/level1/setsrch.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 setsrch.c
*** vendor/atlas/tune/blas/level1/setsrch.c	16 Nov 2005 21:03:54 -0000	1.1.1.1
--- vendor/atlas/tune/blas/level1/setsrch.c	29 Nov 2005 20:24:13 -0000
*************** void DumpFile(char *fnam, FILE *fpout)
*** 764,770 ****
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "../SET/%s", fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
--- 764,770 ----
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "%s/tune/blas/level1/SET/%s", SRCDIR, fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
Index: vendor/atlas/tune/blas/level1/swapsrch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/blas/level1/swapsrch.c,v
retrieving revision 1.1.1.1
diff -c -p -r1.1.1.1 swapsrch.c
*** vendor/atlas/tune/blas/level1/swapsrch.c	16 Nov 2005 21:03:55 -0000	1.1.1.1
--- vendor/atlas/tune/blas/level1/swapsrch.c	29 Nov 2005 20:24:13 -0000
*************** void DumpFile(char *fnam, FILE *fpout)
*** 801,807 ****
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "../SWAP/%s", fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
--- 801,807 ----
  {
     FILE *fpin;
     char ln[512];
!    sprintf(ln, "%s/tune/blas/level1/SWAP/%s", SRCDIR, fnam);
     fpin = fopen(ln, "r");
     assert(fpin);
     while(fgets(ln, 512, fpin)) fputs(ln, fpout);
Index: vendor/atlas/tune/sysinfo/masearch.c
===================================================================
RCS file: /home/cvs/Repository/atlas/tune/sysinfo/masearch.c,v
retrieving revision 1.1.1.2
diff -c -p -r1.1.1.2 masearch.c
*** vendor/atlas/tune/sysinfo/masearch.c	29 Nov 2005 13:46:04 -0000	1.1.1.2
--- vendor/atlas/tune/sysinfo/masearch.c	29 Nov 2005 20:24:13 -0000
***************
*** 28,33 ****
--- 28,34 ----
   *
   */
  #include <stdio.h>
+ #include <stdlib.h>
  #include <assert.h>
  
  #define NTIM 3
*************** void emit_muladd(char *type, char pre, i
*** 62,68 ****
     assert(fpout != NULL);
     if (MULADD) ma = "Combined MULADD";
     else ma = "Separate multiply and add";
!    fprintf(fpout, "#include <stdio.h>\n#include<assert.h>\n");
     fprintf(fpout, "#if defined(PentiumCPS) || defined(WALL)\n");
     fprintf(fpout, "   #define time00 ATL_walltime\n");
     fprintf(fpout, "#else\n   #define time00 ATL_cputime\n#endif\n");
--- 63,69 ----
     assert(fpout != NULL);
     if (MULADD) ma = "Combined MULADD";
     else ma = "Separate multiply and add";
!    fprintf(fpout, "#include <stdio.h>\n#include<stdlib.h>\n#include<assert.h>\n");
     fprintf(fpout, "#if defined(PentiumCPS) || defined(WALL)\n");
     fprintf(fpout, "   #define time00 ATL_walltime\n");
     fprintf(fpout, "#else\n   #define time00 ATL_cputime\n#endif\n");
Index: vendor/lapack/make.inc.in
===================================================================
RCS file: vendor/lapack/make.inc.in
diff -N vendor/lapack/make.inc.in
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- vendor/lapack/make.inc.in	29 Nov 2005 20:24:13 -0000
***************
*** 0 ****
--- 1,43 ----
+ ####################################################################
+ #  LAPACK make include file.                                       #
+ #  LAPACK, Version 3.0                                             #
+ #  June 30, 1999                                                   #
+ #								   #
+ #  CSL in-tree version						   #
+ ####################################################################
+ #
+ # SHELL = @SH@	# /bin/sh
+ #
+ #  The machine (platform) identifier to append to the library names
+ #
+ PLAT = 
+ #  
+ #  Modify the FORTRAN and OPTS definitions to refer to the
+ #  compiler and desired compiler options for your machine.  NOOPT
+ #  refers to the compiler options desired when NO OPTIMIZATION is
+ #  selected.  Define LOADER and LOADOPTS to refer to the loader and 
+ #  desired load options for your machine.
+ #
+ FORTRAN  = @F77@ 
+ OPTS     = -funroll-all-loops -O3
+ DRVOPTS  = $(OPTS)
+ NOOPT    =
+ LOADER   = $(FORTRAN)
+ LOADOPTS =
+ #
+ #  The archiver and the flag(s) to use when building archive (library)
+ #  If you system has no ranlib, set RANLIB = echo.
+ #
+ ARCH     = @AR@		# ar
+ ARCHFLAGS= @ARFLAGS@	# cr
+ RANLIB   = @RANLIB@	# ranlib
+ #
+ #  The location of the libraries to which you will link.  (The 
+ #  machine-specific, optimized BLAS library should be used whenever
+ #  possible.)
+ #
+ BLASLIB      = ../../blas$(PLAT).a
+ LAPACKLIB    = lapack$(PLAT).a
+ TMGLIB       = tmglib$(PLAT).a
+ EIGSRCLIB    = eigsrc$(PLAT).a
+ LINSRCLIB    = linsrc$(PLAT).a
Index: vendor/lapack/SRC/GNUmakefile.in
===================================================================
RCS file: vendor/lapack/SRC/GNUmakefile.in
diff -N vendor/lapack/SRC/GNUmakefile.in
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- vendor/lapack/SRC/GNUmakefile.in	29 Nov 2005 20:24:13 -0000
***************
*** 0 ****
--- 1,342 ----
+ include ../make.inc
+ 
+ srcdir = @srcdir@
+ OBJEXT = @OBJEXT@
+ 
+ vpath %.f $(srcdir)
+ 
+ #######################################################################
+ #  This is the makefile to create a library for LAPACK.
+ #  The files are organized as follows:
+ #       ALLAUX -- Auxiliary routines called from all precisions
+ #       SCLAUX -- Auxiliary routines called from both REAL and COMPLEX
+ #       DZLAUX -- Auxiliary routines called from both DOUBLE PRECISION
+ #                 and COMPLEX*16
+ #       SLASRC -- Single precision real LAPACK routines
+ #       CLASRC -- Single precision complex LAPACK routines
+ #       DLASRC -- Double precision real LAPACK routines
+ #       ZLASRC -- Double precision complex LAPACK routines
+ #
+ #  The library can be set up to include routines for any combination
+ #  of the four precisions.  To create or add to the library, enter make
+ #  followed by one or more of the precisions desired.  Some examples:
+ #       make single
+ #       make single complex
+ #       make single double complex complex16
+ #  Alternatively, the command
+ #       make
+ #  without any arguments creates a library of all four precisions.
+ #  The library is called
+ #       lapack.a
+ #  and is created at the next higher directory level.
+ #
+ #  To remove the object files after the library is created, enter
+ #       make clean
+ #  On some systems, you can force the source files to be recompiled by
+ #  entering (for example)
+ #       make single FRC=FRC
+ #
+ #  ***Note***
+ #  The functions lsame, second, dsecnd, slamch, and dlamch may have
+ #  to be installed before compiling the library.  Refer to the
+ #  installation guide, LAPACK Working Note 41, for instructions.
+ #
+ #######################################################################
+  
+ ALLAUX = ilaenv.o ieeeck.o lsame.o lsamen.o xerbla.o
+ 
+ SCLAUX = \
+    sbdsdc.o \
+    sbdsqr.o sdisna.o slabad.o slacpy.o sladiv.o slae2.o  slaebz.o \
+    slaed0.o slaed1.o slaed2.o slaed3.o slaed4.o slaed5.o slaed6.o \
+    slaed7.o slaed8.o slaed9.o slaeda.o slaev2.o slagtf.o \
+    slagts.o slamch.o slamrg.o slanst.o \
+    slapy2.o slapy3.o slarnv.o \
+    slarrb.o slarre.o slarrf.o \
+    slartg.o slaruv.o slas2.o  slascl.o \
+    slasd0.o slasd1.o slasd2.o slasd3.o slasd4.o slasd5.o slasd6.o \
+    slasd7.o slasd8.o slasd9.o slasda.o slasdq.o slasdt.o \
+    slaset.o slasq1.o slasq2.o slasq3.o slasq4.o slasq5.o slasq6.o \
+    slasr.o  slasrt.o slassq.o slasv2.o spttrf.o sstebz.o sstedc.o \
+    ssteqr.o ssterf.o second.o
+ 
+ DZLAUX = \
+    dbdsdc.o \
+    dbdsqr.o ddisna.o dlabad.o dlacpy.o dladiv.o dlae2.o  dlaebz.o \
+    dlaed0.o dlaed1.o dlaed2.o dlaed3.o dlaed4.o dlaed5.o dlaed6.o \
+    dlaed7.o dlaed8.o dlaed9.o dlaeda.o dlaev2.o dlagtf.o \
+    dlagts.o dlamch.o dlamrg.o dlanst.o \
+    dlapy2.o dlapy3.o dlarnv.o \
+    dlarrb.o dlarre.o dlarrf.o \
+    dlartg.o dlaruv.o dlas2.o  dlascl.o \
+    dlasd0.o dlasd1.o dlasd2.o dlasd3.o dlasd4.o dlasd5.o dlasd6.o \
+    dlasd7.o dlasd8.o dlasd9.o dlasda.o dlasdq.o dlasdt.o \
+    dlaset.o dlasq1.o dlasq2.o dlasq3.o dlasq4.o dlasq5.o dlasq6.o \
+    dlasr.o  dlasrt.o dlassq.o dlasv2.o dpttrf.o dstebz.o dstedc.o \
+    dsteqr.o dsterf.o dsecnd.o
+ 
+ SLASRC = \
+    sgbbrd.o sgbcon.o sgbequ.o sgbrfs.o sgbsv.o  \
+    sgbsvx.o sgbtf2.o sgbtrf.o sgbtrs.o sgebak.o sgebal.o sgebd2.o \
+    sgebrd.o sgecon.o sgeequ.o sgees.o  sgeesx.o sgeev.o  sgeevx.o \
+    sgegs.o  sgegv.o  sgehd2.o sgehrd.o sgelq2.o sgelqf.o \
+    sgels.o  sgelsd.o sgelss.o sgelsx.o sgelsy.o sgeql2.o sgeqlf.o \
+    sgeqp3.o sgeqpf.o sgeqr2.o sgeqrf.o sgerfs.o sgerq2.o sgerqf.o \
+    sgesc2.o sgesdd.o sgesv.o  sgesvd.o sgesvx.o sgetc2.o sgetf2.o \
+    sgetrf.o sgetri.o \
+    sgetrs.o sggbak.o sggbal.o sgges.o  sggesx.o sggev.o  sggevx.o \
+    sggglm.o sgghrd.o sgglse.o sggqrf.o \
+    sggrqf.o sggsvd.o sggsvp.o sgtcon.o sgtrfs.o sgtsv.o  \
+    sgtsvx.o sgttrf.o sgttrs.o sgtts2.o shgeqz.o \
+    shsein.o shseqr.o slabrd.o slacon.o \
+    slaein.o slaexc.o slag2.o  slags2.o slagtm.o slagv2.o slahqr.o \
+    slahrd.o slaic1.o slaln2.o slals0.o slalsa.o slalsd.o \
+    slangb.o slange.o slangt.o slanhs.o slansb.o slansp.o \
+    slansy.o slantb.o slantp.o slantr.o slanv2.o \
+    slapll.o slapmt.o \
+    slaqgb.o slaqge.o slaqp2.o slaqps.o slaqsb.o slaqsp.o slaqsy.o \
+    slaqtr.o slar1v.o slar2v.o \
+    slarf.o  slarfb.o slarfg.o slarft.o slarfx.o slargv.o \
+    slarrv.o slartv.o \
+    slarz.o  slarzb.o slarzt.o slaswp.o slasy2.o slasyf.o \
+    slatbs.o slatdf.o slatps.o slatrd.o slatrs.o slatrz.o slatzm.o \
+    slauu2.o slauum.o sopgtr.o sopmtr.o sorg2l.o sorg2r.o \
+    sorgbr.o sorghr.o sorgl2.o sorglq.o sorgql.o sorgqr.o sorgr2.o \
+    sorgrq.o sorgtr.o sorm2l.o sorm2r.o \
+    sormbr.o sormhr.o sorml2.o sormlq.o sormql.o sormqr.o sormr2.o \
+    sormr3.o sormrq.o sormrz.o sormtr.o spbcon.o spbequ.o spbrfs.o \
+    spbstf.o spbsv.o  spbsvx.o \
+    spbtf2.o spbtrf.o spbtrs.o spocon.o spoequ.o sporfs.o sposv.o  \
+    sposvx.o spotf2.o spotrf.o spotri.o spotrs.o sppcon.o sppequ.o \
+    spprfs.o sppsv.o  sppsvx.o spptrf.o spptri.o spptrs.o sptcon.o \
+    spteqr.o sptrfs.o sptsv.o  sptsvx.o spttrs.o sptts2.o srscl.o  \
+    ssbev.o  ssbevd.o ssbevx.o ssbgst.o ssbgv.o  ssbgvd.o ssbgvx.o \
+    ssbtrd.o sspcon.o sspev.o  sspevd.o sspevx.o sspgst.o \
+    sspgv.o  sspgvd.o sspgvx.o ssprfs.o sspsv.o  sspsvx.o ssptrd.o \
+    ssptrf.o ssptri.o ssptrs.o sstegr.o sstein.o sstev.o  sstevd.o sstevr.o \
+    sstevx.o ssycon.o ssyev.o  ssyevd.o ssyevr.o ssyevx.o ssygs2.o \
+    ssygst.o ssygv.o  ssygvd.o ssygvx.o ssyrfs.o ssysv.o  ssysvx.o \
+    ssytd2.o ssytf2.o ssytrd.o ssytrf.o ssytri.o ssytrs.o stbcon.o \
+    stbrfs.o stbtrs.o stgevc.o stgex2.o stgexc.o stgsen.o \
+    stgsja.o stgsna.o stgsy2.o stgsyl.o stpcon.o stprfs.o stptri.o \
+    stptrs.o \
+    strcon.o strevc.o strexc.o strrfs.o strsen.o strsna.o strsyl.o \
+    strti2.o strtri.o strtrs.o stzrqf.o stzrzf.o
+ 
+ CLASRC = \
+    cbdsqr.o cgbbrd.o cgbcon.o cgbequ.o cgbrfs.o cgbsv.o  cgbsvx.o \
+    cgbtf2.o cgbtrf.o cgbtrs.o cgebak.o cgebal.o cgebd2.o cgebrd.o \
+    cgecon.o cgeequ.o cgees.o  cgeesx.o cgeev.o  cgeevx.o \
+    cgegs.o  cgegv.o  cgehd2.o cgehrd.o cgelq2.o cgelqf.o \
+    cgels.o  cgelsd.o cgelss.o cgelsx.o cgelsy.o cgeql2.o cgeqlf.o cgeqp3.o \
+    cgeqpf.o cgeqr2.o cgeqrf.o cgerfs.o cgerq2.o cgerqf.o \
+    cgesc2.o cgesdd.o cgesv.o  cgesvd.o cgesvx.o cgetc2.o cgetf2.o cgetrf.o \
+    cgetri.o cgetrs.o \
+    cggbak.o cggbal.o cgges.o  cggesx.o cggev.o  cggevx.o cggglm.o \
+    cgghrd.o cgglse.o cggqrf.o cggrqf.o \
+    cggsvd.o cggsvp.o \
+    cgtcon.o cgtrfs.o cgtsv.o  cgtsvx.o cgttrf.o cgttrs.o cgtts2.o chbev.o  \
+    chbevd.o chbevx.o chbgst.o chbgv.o  chbgvd.o chbgvx.o chbtrd.o \
+    checon.o cheev.o  cheevd.o cheevr.o cheevx.o chegs2.o chegst.o \
+    chegv.o  chegvd.o chegvx.o cherfs.o chesv.o  chesvx.o chetd2.o \
+    chetf2.o chetrd.o \
+    chetrf.o chetri.o chetrs.o chgeqz.o chpcon.o chpev.o  chpevd.o \
+    chpevx.o chpgst.o chpgv.o  chpgvd.o chpgvx.o chprfs.o chpsv.o  \
+    chpsvx.o \
+    chptrd.o chptrf.o chptri.o chptrs.o chsein.o chseqr.o clabrd.o \
+    clacgv.o clacon.o clacp2.o clacpy.o clacrm.o clacrt.o cladiv.o \
+    claed0.o claed7.o claed8.o \
+    claein.o claesy.o claev2.o clags2.o clagtm.o \
+    clahef.o clahqr.o \
+    clahrd.o claic1.o clals0.o clalsa.o clalsd.o clangb.o clange.o clangt.o \
+    clanhb.o clanhe.o \
+    clanhp.o clanhs.o clanht.o clansb.o clansp.o clansy.o clantb.o \
+    clantp.o clantr.o clapll.o clapmt.o clarcm.o claqgb.o claqge.o \
+    claqhb.o claqhe.o claqhp.o claqp2.o claqps.o claqsb.o \
+    claqsp.o claqsy.o clar1v.o clar2v.o clarf.o  clarfb.o clarfg.o clarft.o \
+    clarfx.o clargv.o clarnv.o clarrv.o clartg.o clartv.o \
+    clarz.o  clarzb.o clarzt.o clascl.o claset.o clasr.o  classq.o \
+    claswp.o clasyf.o clatbs.o clatdf.o clatps.o clatrd.o clatrs.o clatrz.o \
+    clatzm.o clauu2.o clauum.o cpbcon.o cpbequ.o cpbrfs.o cpbstf.o cpbsv.o  \
+    cpbsvx.o cpbtf2.o cpbtrf.o cpbtrs.o cpocon.o cpoequ.o cporfs.o \
+    cposv.o  cposvx.o cpotf2.o cpotrf.o cpotri.o cpotrs.o cppcon.o \
+    cppequ.o cpprfs.o cppsv.o  cppsvx.o cpptrf.o cpptri.o cpptrs.o \
+    cptcon.o cpteqr.o cptrfs.o cptsv.o  cptsvx.o cpttrf.o cpttrs.o cptts2.o \
+    crot.o   cspcon.o cspmv.o  cspr.o   csprfs.o cspsv.o  \
+    cspsvx.o csptrf.o csptri.o csptrs.o csrot.o  csrscl.o cstedc.o \
+    cstegr.o cstein.o csteqr.o csycon.o csymv.o  \
+    csyr.o   csyrfs.o csysv.o  csysvx.o csytf2.o csytrf.o csytri.o \
+    csytrs.o ctbcon.o ctbrfs.o ctbtrs.o ctgevc.o ctgex2.o \
+    ctgexc.o ctgsen.o ctgsja.o ctgsna.o ctgsy2.o ctgsyl.o ctpcon.o \
+    ctprfs.o ctptri.o \
+    ctptrs.o ctrcon.o ctrevc.o ctrexc.o ctrrfs.o ctrsen.o ctrsna.o \
+    ctrsyl.o ctrti2.o ctrtri.o ctrtrs.o ctzrqf.o ctzrzf.o cung2l.o cung2r.o \
+    cungbr.o cunghr.o cungl2.o cunglq.o cungql.o cungqr.o cungr2.o \
+    cungrq.o cungtr.o cunm2l.o cunm2r.o cunmbr.o cunmhr.o cunml2.o \
+    cunmlq.o cunmql.o cunmqr.o cunmr2.o cunmr3.o cunmrq.o cunmrz.o \
+    cunmtr.o cupgtr.o cupmtr.o icmax1.o scsum1.o
+ 
+ DLASRC = \
+    dgbbrd.o dgbcon.o dgbequ.o dgbrfs.o dgbsv.o  \
+    dgbsvx.o dgbtf2.o dgbtrf.o dgbtrs.o dgebak.o dgebal.o dgebd2.o \
+    dgebrd.o dgecon.o dgeequ.o dgees.o  dgeesx.o dgeev.o  dgeevx.o \
+    dgegs.o  dgegv.o  dgehd2.o dgehrd.o dgelq2.o dgelqf.o \
+    dgels.o  dgelsd.o dgelss.o dgelsx.o dgelsy.o dgeql2.o dgeqlf.o \
+    dgeqp3.o dgeqpf.o dgeqr2.o dgeqrf.o dgerfs.o dgerq2.o dgerqf.o \
+    dgesc2.o dgesdd.o dgesv.o  dgesvd.o dgesvx.o dgetc2.o dgetf2.o \
+    dgetrf.o dgetri.o \
+    dgetrs.o dggbak.o dggbal.o dgges.o  dggesx.o dggev.o  dggevx.o \
+    dggglm.o dgghrd.o dgglse.o dggqrf.o \
+    dggrqf.o dggsvd.o dggsvp.o dgtcon.o dgtrfs.o dgtsv.o  \
+    dgtsvx.o dgttrf.o dgttrs.o dgtts2.o dhgeqz.o \
+    dhsein.o dhseqr.o dlabrd.o dlacon.o \
+    dlaein.o dlaexc.o dlag2.o  dlags2.o dlagtm.o dlagv2.o dlahqr.o \
+    dlahrd.o dlaic1.o dlaln2.o dlals0.o dlalsa.o dlalsd.o \
+    dlangb.o dlange.o dlangt.o dlanhs.o dlansb.o dlansp.o \
+    dlansy.o dlantb.o dlantp.o dlantr.o dlanv2.o \
+    dlapll.o dlapmt.o \
+    dlaqgb.o dlaqge.o dlaqp2.o dlaqps.o dlaqsb.o dlaqsp.o dlaqsy.o \
+    dlaqtr.o dlar1v.o dlar2v.o \
+    dlarf.o  dlarfb.o dlarfg.o dlarft.o dlarfx.o dlargv.o \
+    dlarrv.o dlartv.o \
+    dlarz.o  dlarzb.o dlarzt.o dlaswp.o dlasy2.o dlasyf.o \
+    dlatbs.o dlatdf.o dlatps.o dlatrd.o dlatrs.o dlatrz.o dlatzm.o dlauu2.o \
+    dlauum.o dopgtr.o dopmtr.o dorg2l.o dorg2r.o \
+    dorgbr.o dorghr.o dorgl2.o dorglq.o dorgql.o dorgqr.o dorgr2.o \
+    dorgrq.o dorgtr.o dorm2l.o dorm2r.o \
+    dormbr.o dormhr.o dorml2.o dormlq.o dormql.o dormqr.o dormr2.o \
+    dormr3.o dormrq.o dormrz.o dormtr.o dpbcon.o dpbequ.o dpbrfs.o \
+    dpbstf.o dpbsv.o  dpbsvx.o \
+    dpbtf2.o dpbtrf.o dpbtrs.o dpocon.o dpoequ.o dporfs.o dposv.o  \
+    dposvx.o dpotf2.o dpotrf.o dpotri.o dpotrs.o dppcon.o dppequ.o \
+    dpprfs.o dppsv.o  dppsvx.o dpptrf.o dpptri.o dpptrs.o dptcon.o \
+    dpteqr.o dptrfs.o dptsv.o  dptsvx.o dpttrs.o dptts2.o drscl.o  \
+    dsbev.o  dsbevd.o dsbevx.o dsbgst.o dsbgv.o  dsbgvd.o dsbgvx.o \
+    dsbtrd.o  dspcon.o dspev.o  dspevd.o dspevx.o dspgst.o \
+    dspgv.o  dspgvd.o dspgvx.o dsprfs.o dspsv.o  dspsvx.o dsptrd.o \
+    dsptrf.o dsptri.o dsptrs.o dstegr.o dstein.o dstev.o  dstevd.o dstevr.o \
+    dstevx.o dsycon.o dsyev.o  dsyevd.o dsyevr.o \
+    dsyevx.o dsygs2.o dsygst.o dsygv.o  dsygvd.o dsygvx.o dsyrfs.o \
+    dsysv.o  dsysvx.o \
+    dsytd2.o dsytf2.o dsytrd.o dsytrf.o dsytri.o dsytrs.o dtbcon.o \
+    dtbrfs.o dtbtrs.o dtgevc.o dtgex2.o dtgexc.o dtgsen.o \
+    dtgsja.o dtgsna.o dtgsy2.o dtgsyl.o dtpcon.o dtprfs.o dtptri.o \
+    dtptrs.o \
+    dtrcon.o dtrevc.o dtrexc.o dtrrfs.o dtrsen.o dtrsna.o dtrsyl.o \
+    dtrti2.o dtrtri.o dtrtrs.o dtzrqf.o dtzrzf.o
+ 
+ ZLASRC = \
+    zbdsqr.o zgbbrd.o zgbcon.o zgbequ.o zgbrfs.o zgbsv.o  zgbsvx.o \
+    zgbtf2.o zgbtrf.o zgbtrs.o zgebak.o zgebal.o zgebd2.o zgebrd.o \
+    zgecon.o zgeequ.o zgees.o  zgeesx.o zgeev.o  zgeevx.o \
+    zgegs.o  zgegv.o  zgehd2.o zgehrd.o zgelq2.o zgelqf.o \
+    zgels.o  zgelsd.o zgelss.o zgelsx.o zgelsy.o zgeql2.o zgeqlf.o zgeqp3.o \
+    zgeqpf.o zgeqr2.o zgeqrf.o zgerfs.o zgerq2.o zgerqf.o \
+    zgesc2.o zgesdd.o zgesv.o  zgesvd.o zgesvx.o zgetc2.o zgetf2.o zgetrf.o \
+    zgetri.o zgetrs.o \
+    zggbak.o zggbal.o zgges.o  zggesx.o zggev.o  zggevx.o zggglm.o \
+    zgghrd.o zgglse.o zggqrf.o zggrqf.o \
+    zggsvd.o zggsvp.o \
+    zgtcon.o zgtrfs.o zgtsv.o  zgtsvx.o zgttrf.o zgttrs.o zgtts2.o zhbev.o  \
+    zhbevd.o zhbevx.o zhbgst.o zhbgv.o  zhbgvd.o zhbgvx.o zhbtrd.o \
+    zhecon.o zheev.o  zheevd.o zheevr.o zheevx.o zhegs2.o zhegst.o \
+    zhegv.o  zhegvd.o zhegvx.o zherfs.o zhesv.o  zhesvx.o zhetd2.o \
+    zhetf2.o zhetrd.o \
+    zhetrf.o zhetri.o zhetrs.o zhgeqz.o zhpcon.o zhpev.o  zhpevd.o \
+    zhpevx.o zhpgst.o zhpgv.o  zhpgvd.o zhpgvx.o zhprfs.o zhpsv.o  \
+    zhpsvx.o \
+    zhptrd.o zhptrf.o zhptri.o zhptrs.o zhsein.o zhseqr.o zlabrd.o \
+    zlacgv.o zlacon.o zlacp2.o zlacpy.o zlacrm.o zlacrt.o zladiv.o \
+    zlaed0.o zlaed7.o zlaed8.o \
+    zlaein.o zlaesy.o zlaev2.o zlags2.o zlagtm.o \
+    zlahef.o zlahqr.o \
+    zlahrd.o zlaic1.o zlals0.o zlalsa.o zlalsd.o zlangb.o zlange.o \
+    zlangt.o zlanhb.o \
+    zlanhe.o \
+    zlanhp.o zlanhs.o zlanht.o zlansb.o zlansp.o zlansy.o zlantb.o \
+    zlantp.o zlantr.o zlapll.o zlapmt.o zlaqgb.o zlaqge.o \
+    zlaqhb.o zlaqhe.o zlaqhp.o zlaqp2.o zlaqps.o zlaqsb.o \
+    zlaqsp.o zlaqsy.o zlar1v.o zlar2v.o zlarcm.o zlarf.o  zlarfb.o \
+    zlarfg.o zlarft.o \
+    zlarfx.o zlargv.o zlarnv.o zlarrv.o zlartg.o zlartv.o \
+    zlarz.o  zlarzb.o zlarzt.o zlascl.o zlaset.o zlasr.o  \
+    zlassq.o zlaswp.o zlasyf.o \
+    zlatbs.o zlatdf.o zlatps.o zlatrd.o zlatrs.o zlatrz.o zlatzm.o zlauu2.o \
+    zlauum.o zpbcon.o zpbequ.o zpbrfs.o zpbstf.o zpbsv.o  \
+    zpbsvx.o zpbtf2.o zpbtrf.o zpbtrs.o zpocon.o zpoequ.o zporfs.o \
+    zposv.o  zposvx.o zpotf2.o zpotrf.o zpotri.o zpotrs.o zppcon.o \
+    zppequ.o zpprfs.o zppsv.o  zppsvx.o zpptrf.o zpptri.o zpptrs.o \
+    zptcon.o zpteqr.o zptrfs.o zptsv.o  zptsvx.o zpttrf.o zpttrs.o zptts2.o \
+    zrot.o   zspcon.o zspmv.o  zspr.o   zsprfs.o zspsv.o  \
+    zspsvx.o zsptrf.o zsptri.o zsptrs.o zdrot.o  zdrscl.o zstedc.o \
+    zstegr.o zstein.o zsteqr.o zsycon.o zsymv.o  \
+    zsyr.o   zsyrfs.o zsysv.o  zsysvx.o zsytf2.o zsytrf.o zsytri.o \
+    zsytrs.o ztbcon.o ztbrfs.o ztbtrs.o ztgevc.o ztgex2.o \
+    ztgexc.o ztgsen.o ztgsja.o ztgsna.o ztgsy2.o ztgsyl.o ztpcon.o \
+    ztprfs.o ztptri.o \
+    ztptrs.o ztrcon.o ztrevc.o ztrexc.o ztrrfs.o ztrsen.o ztrsna.o \
+    ztrsyl.o ztrti2.o ztrtri.o ztrtrs.o ztzrqf.o ztzrzf.o zung2l.o \
+    zung2r.o zungbr.o zunghr.o zungl2.o zunglq.o zungql.o zungqr.o zungr2.o \
+    zungrq.o zungtr.o zunm2l.o zunm2r.o zunmbr.o zunmhr.o zunml2.o \
+    zunmlq.o zunmql.o zunmqr.o zunmr2.o zunmr3.o zunmrq.o zunmrz.o \
+    zunmtr.o zupgtr.o \
+    zupmtr.o izmax1.o dzsum1.o
+ 
+ all: single complex double complex16
+ 
+ single: $(SLASRC) $(ALLAUX) $(SCLAUX) 
+ 	$(ARCH) $(ARCHFLAGS) ../$(LAPACKLIB) $(SLASRC) $(ALLAUX) \
+ 	$(SCLAUX)
+ 	$(RANLIB) ../$(LAPACKLIB)
+ 
+ complex: $(CLASRC) $(ALLAUX) $(SCLAUX)
+ 	$(ARCH) $(ARCHFLAGS) ../$(LAPACKLIB) $(CLASRC) $(ALLAUX) \
+ 	$(SCLAUX)
+ 	$(RANLIB) ../$(LAPACKLIB)
+ 
+ double: $(DLASRC) $(ALLAUX) $(DZLAUX)
+ 	$(ARCH) $(ARCHFLAGS) ../$(LAPACKLIB) $(DLASRC) $(ALLAUX) \
+ 	$(DZLAUX)
+ 	$(RANLIB) ../$(LAPACKLIB)
+ 
+ complex16: $(ZLASRC) $(ALLAUX) $(DZLAUX)
+ 	$(ARCH) $(ARCHFLAGS) ../$(LAPACKLIB) $(ZLASRC) $(ALLAUX) \
+ 	$(DZLAUX)
+ 	$(RANLIB) ../$(LAPACKLIB)
+ 
+ $(ALLAUX): $(FRC)
+ $(SCLAUX): $(FRC)
+ $(DZLAUX): $(FRC)
+ $(SLASRC): $(FRC)
+ $(CLASRC): $(FRC)
+ $(DLASRC): $(FRC)
+ $(ZLASRC): $(FRC)
+ 
+ FRC:
+ 	@FRC=$(FRC)
+ 
+ clean:
+ 	rm -f *.o
+ 
+ slamch.o: $(srcdir)/slamch.f
+ 	$(FORTRAN) $(NOOPT) -c $<
+ dlamch.o: $(srcdir)/dlamch.f
+ 	$(FORTRAN) $(NOOPT) -c $<
+ 
+ sources := $(wildcard $(srcdir)/*.f)
+ objects := $(patsubst $(srcdir)/%.f, %.$(OBJEXT), $(sources))
+ depends := $(patsubst $(srcdir)/%.f, %.d, $(sources))
+ 
+ # .f.o: 
+ # 	$(FORTRAN) $(OPTS) -c $<
+ 
+ %.$(OBJEXT): %.f
+ 	$(FORTRAN) $(OPTS) -c -o $@ $<
+ 
+ # Generate a dependency Makefile fragment for a C++ source file.
+ # (This recipe is taken from the GNU Make manual.)
+ %.d: %.f
+ 	$(SHELL) -ec '$(FORTRAN) $(OPTS) \
+ 		      | sed "s|$(*F)\\.o[ :]*|$*\\.d $*\\.$(OBJEXT) : |g" > $@'
+ 
+ # include $(depends)
