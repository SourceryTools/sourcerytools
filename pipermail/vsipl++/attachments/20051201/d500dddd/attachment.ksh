Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.317
diff -c -p -r1.317 ChangeLog
*** ChangeLog	1 Dec 2005 14:43:17 -0000	1.317
--- ChangeLog	1 Dec 2005 15:08:25 -0000
***************
*** 1,5 ****
--- 1,24 ----
  2005-12-01 Jules Bergmann  <jules@codesourcery.com>
  
+ 	* configure.ac (with-mkl-arch): New option to set MKL arch library
+ 	  sub-directory.  Default is to deduce arch based on host_cpu.
+ 	  (--disable-cblas): New option to disable use of CBLAS API and
+ 	  use fortran BLAS API instead.  Default is to use CBLAS API,
+ 	  which avoids problems with calling fortran functions from C++.
+ 	  (--with-g2c-path): New option to specify path for libg2c.a.
+ 	  (VSIP_IMPL_FORTRAN_FLOAT_RETURN): New AC_DEFINE for the C
+ 	  return type of a fortran real function.
+ 	  (--with-mkl-prefix): Change behavior, previously PATH was
+ 	  the library directory, now it is the prefix above library
+ 	  and include directories.  Old help string was correct.
+ 	* GNUmakefile.in: Substitute INT_CPPFLAGS.
+ 	* tests/context.in: Likewise.
+ 	* src/vsip/impl/lapack.hpp: Support CBLAS API.
+ 	* vendor/GNUmakefile.inc.in: Install ATLAS cblas header.
+ 	* vendor/lapack/make.inc.in: Substitute FFLAGS.
+ 
+ 2005-12-01 Jules Bergmann  <jules@codesourcery.com>
+ 
  	Integrate ATLAS and LAPACK into VSIPL++ source tree.
  	* autogen.sh: process configure.ac in vendor/atlas directory.
  	* configure.ac: Configuration support for builtin lapack library.
Index: GNUmakefile.in
===================================================================
RCS file: /home/cvs/Repository/vpp/GNUmakefile.in,v
retrieving revision 1.26
diff -c -p -r1.26 GNUmakefile.in
*** GNUmakefile.in	1 Dec 2005 14:43:17 -0000	1.26
--- GNUmakefile.in	1 Dec 2005 15:08:25 -0000
*************** CXXINCLUDES := -I src -I $(srcdir)/src
*** 54,60 ****
  # C++ macro definitions.
  CXXDEFS :=
  # C++ preprocessor flags.
! CXXCPPFLAGS := $(CXXINCLUDES) $(CXXDEFS) @CPPFLAGS@
  # C++ compilation flags.
  CXXFLAGS := $(CXXCPPFLAGS) @CXXFLAGS@
  # The extension for executable programs.
--- 54,60 ----
  # C++ macro definitions.
  CXXDEFS :=
  # C++ preprocessor flags.
! CXXCPPFLAGS := $(CXXINCLUDES) $(CXXDEFS) @CPPFLAGS@ @INT_CPPFLAGS@
  # C++ compilation flags.
  CXXFLAGS := $(CXXCPPFLAGS) @CXXFLAGS@
  # The extension for executable programs.
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.52
diff -c -p -r1.52 configure.ac
*** configure.ac	1 Dec 2005 14:43:17 -0000	1.52
--- configure.ac	1 Dec 2005 15:08:25 -0000
*************** AC_ARG_WITH(mkl_prefix,
*** 135,140 ****
--- 135,160 ----
  	          (Enables LAPACK).]),
    [enable_lapack=mkl])
  
+ AC_ARG_WITH(mkl_arch,
+   AS_HELP_STRING([--with-mkl-arch=ARCH],
+                  [specify the MKL library architecture directory.  MKL
+ 		  libraries from PATH/lib/ARCH will be used, where
+ 		  PATH is specified with '--with-mkl-prefix' option.
+ 		  (Default is to probe arch based on host cpu type).]),,
+   [with_mkl_arch=probe])
+ 
+ AC_ARG_ENABLE([cblas],
+   AS_HELP_STRING([--disable-cblas],
+                  [disable C BLAS API (default is to use it if possible)]),,
+   [enable_cblas=yes])
+ 
+ AC_ARG_WITH([g2c-path],
+   AS_HELP_STRING([--with-g2c-path=PATH],
+                  [path to libg2c.a library (libg2c.a) (default is to include
+ 		  g2c via -lg2c)]),
+   [search_g2c="path"],
+   [search_g2c="none lopt"])
+ 
  
  AC_ARG_ENABLE([profile_timer],
    AS_HELP_STRING([--enable-profile-timer=type],
*************** fi
*** 190,195 ****
--- 210,226 ----
  AC_SUBST(CXXDEP)
  AC_LANG(C++)
  
+ AC_MSG_CHECKING([for FORTRAN float return type])
+ if test "$host_cpu" == "x86_64"; then
+   AC_DEFINE_UNQUOTED(VSIP_IMPL_FORTRAN_FLOAT_RETURN, double,
+       [Define to C return type of FORTRAN real function.])
+   AC_MSG_RESULT([double.])
+ else
+   AC_DEFINE_UNQUOTED(VSIP_IMPL_FORTRAN_FLOAT_RETURN, float,
+       [Define to C return type of FORTRAN real function.])
+   AC_MSG_RESULT([float.])
+ fi
+ 
  #
  # Set ar
  #
*************** int main(int, char **)
*** 728,733 ****
--- 759,827 ----
  fi
  
  #
+ # Find the location of g2c, in case it is needed for LAPACK
+ #
+ AC_LANG_SAVE()
+ keep_LIBS="$LIBS"
+ keep_LDFLAGS="$LDFLAGS"
+ use_g2c="error"
+ for try in $search_g2c; do
+ 
+   if test $try == "none"; then
+     tenative_use_g2c=""
+   elif test $try == "lopt"; then
+     tenative_use_g2c="-lg2c"
+     LIBS="$LIBS -lg2c"
+   elif test $try == "path"; then
+     tenative_use_g2c="$with_g2c_path/libg2c.a"
+     LIBS="$LIBS $with_g2c_path/libg2c.a"
+   fi
+ 
+   status="unknown-failure"
+   AC_MSG_CHECKING([for g2c $try])
+   AC_LANG([Fortran 77])
+   AC_COMPILE_IFELSE([
+     AC_LANG_SOURCE([[
+         SUBROUTINE TEST
+         character*1     ch1, ch2
+         character*2     opts
+         opts = ch1 // ch2
+         end
+ 	]]) ],
+     [
+       mv conftest.$ac_objext conftest2.$ac_objext
+       AC_LANG([C++])
+       LDFLAGS="conftest2.$ac_objext $LDFLAGS"
+       AC_LINK_IFELSE([
+         AC_LANG_SOURCE([[
+ 	  int main() { return 0; }
+ 	  ]])],
+        [status="link-success"],
+        [status="link-failure"])
+       LDFLAGS="$keep_LDFLAGS"
+       rm conftest2.$ac_objext
+     ],
+     [status="compile-failure"])
+ 
+   LIBS="$keep_LIBS"
+   AC_MSG_RESULT([$status])
+   if test $status == "link-success"; then
+     use_g2c="$tenative_use_g2c"
+     break
+   fi
+ done
+ AC_LANG_RESTORE()
+ 
+ if test $use_g2c == "error"; then
+   AC_MSG_RESULT([libg2c not found.])
+ elif test $use_g2c == ""; then
+   AC_MSG_RESULT([libg2c not required.])
+ else
+   AC_MSG_RESULT([will use $use_g2c for libg2c.])
+ fi
+ 
+ 
+ #
  # Find the lapack library, if enabled.
  #
  echo "enable_lapack: $enable_lapack"
*************** if test "$enable_lapack" != "no"; then
*** 735,743 ****
    keep_CPPFLAGS=$CPPFLAGS
    keep_LDFLAGS=$LDFLAGS
    keep_LIBS=$LIBS
  
    if test "$enable_lapack" == "mkl"; then
!     lapack_packages="mkl7 mkl7"
    elif test "$enable_lapack" == "atlas"; then
      lapack_packages="atlas"
    else
--- 829,848 ----
    keep_CPPFLAGS=$CPPFLAGS
    keep_LDFLAGS=$LDFLAGS
    keep_LIBS=$LIBS
+   cblas_style="0"
  
    if test "$enable_lapack" == "mkl"; then
! 
!     if test "$with_mkl_arch" == "probe"; then
!       if test "$host_cpu" == "x86_64"; then
!         with_mkl_arch="em64t"
!       else
!         with_mkl_arch="32"
!       fi
!     fi
!     AC_MSG_RESULT([Using $with_mkl_arch for MKL architecture directory])
! 
!     lapack_packages="mkl7 mkl5"
    elif test "$enable_lapack" == "atlas"; then
      lapack_packages="atlas"
    else
*************** if test "$enable_lapack" != "no"; then
*** 750,769 ****
      fi
    fi
  
    for trypkg in $lapack_packages; do
      if test "$trypkg" == "mkl5"; then
        AC_MSG_CHECKING([for LAPACK/MKL 5.x library])
  
!       LDFLAGS="$keep_LDFLAGS -L$with_mkl_prefix"
!       LIBS="$keep_LIBS -lmkl_lapack -lmkl -lg2c -lpthread"
  
        lapack_use_ilaenv=0
      elif test "$trypkg" == "mkl7"; then
        AC_MSG_CHECKING([for LAPACK/MKL 7.x or 8.x library])
  
!       LDFLAGS="$keep_LDFLAGS -L$with_mkl_prefix"
!       CPPFLAGS="$keep_CPPFLAGS -pthread"
        LIBS="$keep_LIBS -lmkl_lapack -lmkl -lguide -lpthread"
  
        lapack_use_ilaenv=0
      elif test "$trypkg" == "atlas"; then
--- 855,883 ----
      fi
    fi
  
+   lapack_found="no"
    for trypkg in $lapack_packages; do
      if test "$trypkg" == "mkl5"; then
        AC_MSG_CHECKING([for LAPACK/MKL 5.x library])
  
!       CPPFLAGS="$keep_CPPFLAGS -I$with_mkl_prefix/include"
!       LDFLAGS="$keep_LDFLAGS -L$with_mkl_prefix/lib/$with_mkl_arch/"
!       LIBS="$keep_LIBS -lmkl_lapack -lmkl $use_g2c -lpthread"
!       cblas_style="2"	# use mkl_cblas.h
! 
!       if test $use_g2c == "error"; then
!         AC_MSG_RESULT([skipping (g2c needed but not found)])
! 	continue
!       fi
  
        lapack_use_ilaenv=0
      elif test "$trypkg" == "mkl7"; then
        AC_MSG_CHECKING([for LAPACK/MKL 7.x or 8.x library])
  
!       CPPFLAGS="$keep_CPPFLAGS -I$with_mkl_prefix/include -pthread"
!       LDFLAGS="$keep_LDFLAGS -L$with_mkl_prefix/lib/$with_mkl_arch/"
        LIBS="$keep_LIBS -lmkl_lapack -lmkl -lguide -lpthread"
+       cblas_style="2"	# use mkl_cblas.h
  
        lapack_use_ilaenv=0
      elif test "$trypkg" == "atlas"; then
*************** if test "$enable_lapack" != "no"; then
*** 779,794 ****
  
        LDFLAGS="$keep_LDFLAGS$atlas_libdir"
        CPPFLAGS="$keep_CPPFLAGS"
!       LIBS="$keep_LIBS -llapack -lcblas -lf77blas -latlas -lg2c"
  
        lapack_use_ilaenv=0
      elif test "$trypkg" == "generic"; then
        AC_MSG_CHECKING([for LAPACK/Generic library])
        LIBS="$keep_LIBS -llapack"
        lapack_use_ilaenv=0
      elif test "$trypkg" == "builtin"; then
        AC_MSG_CHECKING([for built-in ATLAS library])
        if test -e "$srcdir/vendor/atlas/configure"; then
          AC_MSG_RESULT([found])
  
          # assert(NOT CROSS-COMPILING)
--- 893,919 ----
  
        LDFLAGS="$keep_LDFLAGS$atlas_libdir"
        CPPFLAGS="$keep_CPPFLAGS"
!       LIBS="$keep_LIBS -llapack -lcblas -lf77blas -latlas $use_g2c"
!       cblas_style="1"	# use cblas.h
! 
!       if test $use_g2c == "error"; then
!         AC_MSG_RESULT([skipping (g2c needed but not found)])
! 	continue
!       fi
  
        lapack_use_ilaenv=0
      elif test "$trypkg" == "generic"; then
        AC_MSG_CHECKING([for LAPACK/Generic library])
        LIBS="$keep_LIBS -llapack"
+       cblas_style="0"	# no cblas.h
        lapack_use_ilaenv=0
      elif test "$trypkg" == "builtin"; then
        AC_MSG_CHECKING([for built-in ATLAS library])
        if test -e "$srcdir/vendor/atlas/configure"; then
+         if test $use_g2c == "error"; then
+           AC_MSG_RESULT([skipping (g2c needed but not found)])
+ 	  continue
+         fi
          AC_MSG_RESULT([found])
  
          # assert(NOT CROSS-COMPILING)
*************** if test "$enable_lapack" != "no"; then
*** 811,817 ****
          echo "==============================================================="
  
  	if test -f "vendor/atlas/Make.ARCH"; then
!           AC_MSG_RESULT([built-in ATLAS configur successful.])
  	else
            AC_MSG_ERROR([built-in ATLAS configure FAILED.])
  	fi
--- 936,942 ----
          echo "==============================================================="
  
  	if test -f "vendor/atlas/Make.ARCH"; then
!           AC_MSG_RESULT([built-in ATLAS configure successful.])
  	else
            AC_MSG_ERROR([built-in ATLAS configure FAILED.])
  	fi
*************** if test "$enable_lapack" != "no"; then
*** 826,838 ****
  	# fail).  Instead we add them to LATE_LIBS, which gets added to
  	# LIBS just before AC_OUTPUT.
  
!         LATE_LIBS="$LATE_LIBS -lcsl_lapack -lcsl_cblas -lcsl_f77blas -lcsl_atlas -lg2c"
  
  	INT_LDFLAGS="$INT_LDFLAGS -L$curdir/vendor/atlas/lib"
!         LDFLAGS="$keep_LDFLAGS -L$libdir/lib/atlas"
!         CPPFLAGS="$keep_CPPFLAGS"
          LIBS="$keep_LIBS"
          lapack_use_ilaenv=0
  
          lapack_found="builtin"
          break
--- 951,965 ----
  	# fail).  Instead we add them to LATE_LIBS, which gets added to
  	# LIBS just before AC_OUTPUT.
  
!         LATE_LIBS="$LATE_LIBS -lcsl_lapack -lcsl_cblas -lcsl_f77blas -lcsl_atlas $use_g2c"
  
+ 	INT_CPPFLAGS="$INT_CPPFLAGS -I$srcdir/vendor/atlas/include"
  	INT_LDFLAGS="$INT_LDFLAGS -L$curdir/vendor/atlas/lib"
!         CPPFLAGS="$keep_CPPFLAGS -I$includedir/atlas"
!         LDFLAGS="$keep_LDFLAGS -L$libdir/atlas"
          LIBS="$keep_LIBS"
          lapack_use_ilaenv=0
+         cblas_style="1"	# use cblas.h
  
          lapack_found="builtin"
          break
*************** if test "$enable_lapack" != "no"; then
*** 842,848 ****
        fi
      fi
  
-     lapack_found="no"
  
      AC_LINK_IFELSE(
        [AC_LANG_PROGRAM(
--- 969,974 ----
*************** if test "$enable_lapack" != "no"; then
*** 861,867 ****
  
    if test "$lapack_found" == "no"; then
      if test "$enable_lapack" != "probe"; then
!       AC_MSG_ERROR([No LAPACK library found])
      fi
      AC_MSG_RESULT([No LAPACK library found])
      CPPFLAGS=$keep_CPPFLAGS
--- 987,993 ----
  
    if test "$lapack_found" == "no"; then
      if test "$enable_lapack" != "probe"; then
!       AC_MSG_ERROR([LAPACK enabled but no library found])
      fi
      AC_MSG_RESULT([No LAPACK library found])
      CPPFLAGS=$keep_CPPFLAGS
*************** if test "$enable_lapack" != "no"; then
*** 875,880 ****
--- 1001,1013 ----
        [Define to set whether or not LAPACK is present.])
      AC_DEFINE_UNQUOTED(VSIP_IMPL_USE_LAPACK_ILAENV, $lapack_use_ilaenv,
        [Use LAPACK ILAENV (0 == do not use, 1 = use).])
+     if test $enable_cblas == "yes"; then
+       enable_cblas=$cblas_style
+     else
+       enable_cblas="0"
+     fi
+     AC_DEFINE_UNQUOTED(VSIP_IMPL_USE_CBLAS, $enable_cblas,
+       [CBLAS style (0 == no CBLAS, 1 = ATLAS CBLAS, 2 = MKL CBLAS).])
    fi
  fi
  
*************** AC_PROG_INSTALL
*** 966,971 ****
--- 1099,1105 ----
  # "Late" variables
  LIBS="$LIBS $LATE_LIBS"
  AC_SUBST(INT_LDFLAGS)
+ AC_SUBST(INT_CPPFLAGS)
  
  
  #
Index: src/vsip/impl/lapack.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/lapack.hpp,v
retrieving revision 1.10
diff -c -p -r1.10 lapack.hpp
*** src/vsip/impl/lapack.hpp	11 Nov 2005 00:08:21 -0000	1.10
--- src/vsip/impl/lapack.hpp	1 Dec 2005 15:08:26 -0000
*************** NOTES:
*** 32,37 ****
--- 32,46 ----
  #include <vsip/impl/acconfig.hpp>
  #include <vsip/impl/metaprogramming.hpp>
  
+ extern "C"
+ {
+ #if VSIP_IMPL_USE_CBLAS == 1
+ #  include <cblas.h>
+ #elif VSIP_IMPL_USE_CBLAS == 2
+ #  include <mkl_cblas.h>
+ #endif
+ }
+ 
  
  
  /***********************************************************************
*************** extern "C"
*** 55,62 ****
    typedef std::complex<float>*  C;
    typedef std::complex<double>* Z;
  
    // dot
!   float  sdot_ (I, S, I, S, I);
    double ddot_ (I, D, I, D, I);
  
    void cdotu_(C, I, C, I, C, I);
--- 64,73 ----
    typedef std::complex<float>*  C;
    typedef std::complex<double>* Z;
  
+ #if VSIP_IMPL_USE_CBLAS
+ #else
    // dot
!   VSIP_IMPL_FORTRAN_FLOAT_RETURN sdot_ (I, S, I, S, I);
    double ddot_ (I, D, I, D, I);
  
    void cdotu_(C, I, C, I, C, I);
*************** extern "C"
*** 64,69 ****
--- 75,81 ----
  
    void cdotc_(C, I, C, I, C, I);
    void zdotc_(Z, I, Z, I, Z, I);
+ #endif
  
    // trsm
    void strsm_ (char*, char*, char*, char*, I, I, S, S, I, S, I);
*************** extern "C"
*** 93,98 ****
--- 105,119 ----
  
  };
  
+ #define VSIP_IMPL_CBLAS_DOT(T, VPPFCN, BLASFCN)				\
+ inline T								\
+ VPPFCN(int n,								\
+     T* x, int incx,							\
+     T* y, int incy)							\
+ {									\
+   return BLASFCN(n, x, incx, y, incy);				\
+ }
+ 
  #define VSIP_IMPL_BLAS_DOT(T, VPPFCN, BLASFCN)				\
  inline T								\
  VPPFCN(int n,								\
*************** VPPFCN(int n,								\
*** 102,114 ****
    return BLASFCN(&n, x, &incx, y, &incy);				\
  }
  
! VSIP_IMPL_BLAS_DOT(float,                dot, sdot_)
! VSIP_IMPL_BLAS_DOT(double,               dot, ddot_)
  
  #undef VSIP_IMPL_BLAS_DOT
  
  
  
  #define VSIP_IMPL_BLAS_CDOT(T, VPPFCN, BLASFCN)				\
  inline T								\
  VPPFCN(int n,								\
--- 123,153 ----
    return BLASFCN(&n, x, &incx, y, &incy);				\
  }
  
! #if VSIP_IMPL_USE_CBLAS
!   VSIP_IMPL_CBLAS_DOT(float,                dot, cblas_sdot)
!   VSIP_IMPL_CBLAS_DOT(double,               dot, cblas_ddot)
! #else
!   VSIP_IMPL_BLAS_DOT(float,                dot, sdot_)
!   VSIP_IMPL_BLAS_DOT(double,               dot, ddot_)
! #endif // VSIP_IMPL_USE_CBLAS
  
  #undef VSIP_IMPL_BLAS_DOT
  
  
  
+ #define VSIP_IMPL_CBLAS_CDOT(T, VPPFCN, BLASFCN)			\
+ inline T								\
+ VPPFCN(int n,								\
+     T* x, int incx,							\
+     T* y, int incy)							\
+ {									\
+   T ret;								\
+   BLASFCN(n,								\
+ 	  static_cast<const void*>(x), incx,				\
+ 	  static_cast<const void*>(y), incy, &ret);			\
+   return ret;								\
+ }
+ 
  #define VSIP_IMPL_BLAS_CDOT(T, VPPFCN, BLASFCN)				\
  inline T								\
  VPPFCN(int n,								\
*************** VPPFCN(int n,								\
*** 121,131 ****
  }
  
  
! VSIP_IMPL_BLAS_CDOT(std::complex<float>,  dot, cdotu_)
! VSIP_IMPL_BLAS_CDOT(std::complex<double>, dot, zdotu_)
  
! VSIP_IMPL_BLAS_CDOT(std::complex<float>,  dotc, cdotc_)
! VSIP_IMPL_BLAS_CDOT(std::complex<double>, dotc, zdotc_)
  
  #undef VSIP_IMPL_BLAS_CDOT
  
--- 160,178 ----
  }
  
  
! #if VSIP_IMPL_USE_CBLAS
!   VSIP_IMPL_CBLAS_CDOT(std::complex<float>,  dot, cblas_cdotu_sub)
!   VSIP_IMPL_CBLAS_CDOT(std::complex<double>, dot, cblas_zdotu_sub)
  
!   VSIP_IMPL_CBLAS_CDOT(std::complex<float>,  dotc, cblas_cdotc_sub)
!   VSIP_IMPL_CBLAS_CDOT(std::complex<double>, dotc, cblas_zdotc_sub)
! #else
!   VSIP_IMPL_BLAS_CDOT(std::complex<float>,  dot, cdotu_)
!   VSIP_IMPL_BLAS_CDOT(std::complex<double>, dot, zdotu_)
! 
!   VSIP_IMPL_BLAS_CDOT(std::complex<float>,  dotc, cdotc_)
!   VSIP_IMPL_BLAS_CDOT(std::complex<double>, dotc, zdotc_)
! #endif
  
  #undef VSIP_IMPL_BLAS_CDOT
  
Index: tests/context.in
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/context.in,v
retrieving revision 1.3
diff -c -p -r1.3 context.in
*** tests/context.in	1 Dec 2005 14:43:17 -0000	1.3
--- tests/context.in	1 Dec 2005 15:08:26 -0000
***************
*** 1,7 ****
  CompilerTable.languages= cxx
  CompilerTable.cxx_kind= GCC
  CompilerTable.cxx_path= @CXX@
! CompilerTable.cxx_options= -I@abs_top_builddir@/src -I@abs_top_srcdir@/src @CPPFLAGS@ @CXXFLAGS@
  CompilerTable.cxx_ldflags= @LDFLAGS@ @INT_LDFLAGS@ @abs_top_builddir@/src/vsip/libvsip.a @LIBS@
  GPPInit.options=
  GPPInit.library_directories= 
--- 1,7 ----
  CompilerTable.languages= cxx
  CompilerTable.cxx_kind= GCC
  CompilerTable.cxx_path= @CXX@
! CompilerTable.cxx_options= -I@abs_top_builddir@/src -I@abs_top_srcdir@/src @CPPFLAGS@ @INT_CPPFLAGS@ @CXXFLAGS@
  CompilerTable.cxx_ldflags= @LDFLAGS@ @INT_LDFLAGS@ @abs_top_builddir@/src/vsip/libvsip.a @LIBS@
  GPPInit.options=
  GPPInit.library_directories= 
Index: vendor/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/vendor/GNUmakefile.inc.in,v
retrieving revision 1.1
diff -c -p -r1.1 GNUmakefile.inc.in
*** vendor/GNUmakefile.inc.in	1 Dec 2005 14:43:17 -0000	1.1
--- vendor/GNUmakefile.inc.in	1 Dec 2005 15:08:26 -0000
*************** install::
*** 67,70 ****
--- 67,72 ----
  	$(INSTALL_DATA) vendor/atlas/lib/libcsl_cblas.a   $(libdir)/atlas
  	$(INSTALL_DATA) vendor/atlas/lib/libcsl_f77blas.a $(libdir)/atlas
  	$(INSTALL_DATA) vendor/atlas/lib/libcsl_lapack.a  $(libdir)/atlas
+ 	$(INSTALL) -d $(includedir)/atlas
+ 	$(INSTALL_DATA) $(srcdir)/vendor/atlas/include/cblas.h $(includedir)/atlas
  endif
Index: vendor/lapack/make.inc.in
===================================================================
RCS file: /home/cvs/Repository/lapack/make.inc.in,v
retrieving revision 1.1
diff -c -p -r1.1 make.inc.in
*** vendor/lapack/make.inc.in	1 Dec 2005 14:43:18 -0000	1.1
--- vendor/lapack/make.inc.in	1 Dec 2005 15:08:26 -0000
*************** PLAT = 
*** 19,25 ****
  #  desired load options for your machine.
  #
  FORTRAN  = @F77@ 
! OPTS     = -funroll-all-loops -O3
  DRVOPTS  = $(OPTS)
  NOOPT    =
  LOADER   = $(FORTRAN)
--- 19,25 ----
  #  desired load options for your machine.
  #
  FORTRAN  = @F77@ 
! OPTS     = @FFLAGS@ -funroll-all-loops -O3
  DRVOPTS  = $(OPTS)
  NOOPT    =
  LOADER   = $(FORTRAN)
