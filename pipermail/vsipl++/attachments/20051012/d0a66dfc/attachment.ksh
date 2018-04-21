Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.291
diff -c -p -r1.291 ChangeLog
*** ChangeLog	12 Oct 2005 12:45:05 -0000	1.291
--- ChangeLog	12 Oct 2005 13:16:35 -0000
***************
*** 1,5 ****
--- 1,12 ----
  2005-10-12 Jules Bergmann  <jules@codesourcery.com>
  
+ 	* configure.ac (--with-atlas-prefix, --with-atlas-libdir): New
+ 	  options to specify ATLAS prefix and/or libdir.  Add support to use
+ 	  ATLAS for BLAS and LAPACK.  Change trypkg search order for mkl7
+ 	  and mkl5.
+ 
+ 2005-10-12 Jules Bergmann  <jules@codesourcery.com>
+ 
  	Implement General_dispatch (similar to Serial_expr_dispatch),
  	Use for dot- and matrix-matrix products.
  	* configure.ac (VSIP_IMPL_HAVE_BLAS, VSIPL_IMPL_HAVE_LAPACK):
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.42
diff -c -p -r1.42 configure.ac
*** configure.ac	12 Oct 2005 12:45:05 -0000	1.42
--- configure.ac	12 Oct 2005 13:16:35 -0000
*************** AC_ARG_ENABLE([lapack],
*** 76,81 ****
--- 76,94 ----
                   [use LAPACK if found (default is to not search for it)]),,
    [enable_lapack=no])
  
+ AC_ARG_WITH(atlas_prefix,
+   AS_HELP_STRING([--with-atlas-prefix=PATH],
+                  [specify the installation prefix of the ATLAS library.
+ 	          Headers must be in PATH/include; libraries in PATH/lib.
+ 	          (Enables LAPACK).]),
+   [enable_lapack=atlas])
+ 
+ AC_ARG_WITH(atlas_libdir,
+   AS_HELP_STRING([--with-atlas-libdir=PATH],
+                  [specify the directory containing ATLAS librariews.
+ 	          (Enables LAPACK).]),
+   [enable_lapack=atlas])
+ 
  AC_ARG_WITH(mkl_prefix,
    AS_HELP_STRING([--with-mkl-prefix=PATH],
                   [specify the installation prefix of the MKL library.  Headers
*************** if test "$enable_lapack" != "no"; then
*** 556,564 ****
    keep_LIBS=$LIBS
  
    if test "$enable_lapack" == "mkl"; then
!     lapack_packages="mkl5 mkl7 lapack"
    else
!     lapack_packages="lapack"
    fi
  
    for trypkg in $lapack_packages; do
--- 569,579 ----
    keep_LIBS=$LIBS
  
    if test "$enable_lapack" == "mkl"; then
!     lapack_packages="mkl7 mkl7"
!   elif test "$enable_lapack" == "atlas"; then
!     lapack_packages="atlas"
    else
!     lapack_packages="atlas lapack"
    fi
  
    for trypkg in $lapack_packages; do
*************** if test "$enable_lapack" != "no"; then
*** 570,582 ****
  
        lapack_use_ilaenv=0
      elif test "$trypkg" == "mkl7"; then
!       AC_MSG_CHECKING([for LAPACK/MKL 7.x library])
  
        LDFLAGS="$keep_LDFLAGS -L$with_mkl_prefix"
        CPPFLAGS="$keep_CPPFLAGS -pthread"
        LIBS="$keep_LIBS -lmkl_lapack -lmkl -lguide -lpthread"
  
        lapack_use_ilaenv=0
      else
        AC_MSG_CHECKING([for LAPACK/Generic library])
        LIBS="$keep_LIBS -llapack"
--- 585,613 ----
  
        lapack_use_ilaenv=0
      elif test "$trypkg" == "mkl7"; then
!       AC_MSG_CHECKING([for LAPACK/MKL 7.x or 8.x library])
  
        LDFLAGS="$keep_LDFLAGS -L$with_mkl_prefix"
        CPPFLAGS="$keep_CPPFLAGS -pthread"
        LIBS="$keep_LIBS -lmkl_lapack -lmkl -lguide -lpthread"
  
        lapack_use_ilaenv=0
+     elif test "$trypkg" == "atlas"; then
+       AC_MSG_CHECKING([for LAPACK/ATLAS library])
+ 
+       if test "$with_atlas_libdir" != ""; then
+ 	atlas_libdir=" -L$with_atlas_libdir"
+       elif test "$with_atlas_prefix" != ""; then
+ 	atlas_libdir=" -L$with_atlas_prefix/lib"
+       else
+ 	atlas_libdir=""
+       fi
+ 
+       LDFLAGS="$keep_LDFLAGS$atlas_libdir"
+       CPPFLAGS="$keep_CPPFLAGS"
+       LIBS="$keep_LIBS -llapack -lcblas -lf77blas -latlas -lg2c"
+ 
+       lapack_use_ilaenv=0
      else
        AC_MSG_CHECKING([for LAPACK/Generic library])
        LIBS="$keep_LIBS -llapack"
