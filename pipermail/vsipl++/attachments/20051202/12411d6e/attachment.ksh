Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.318
diff -c -p -r1.318 ChangeLog
*** ChangeLog	1 Dec 2005 16:39:27 -0000	1.318
--- ChangeLog	2 Dec 2005 20:06:20 -0000
***************
*** 1,3 ****
--- 1,8 ----
+ 2005-12-02 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* configure.ac: Cleanup handling of lapack options by
+ 	  merging --enable-lapack functionality into --with-lapack.
+ 
  2005-12-01 Jules Bergmann  <jules@codesourcery.com>
  
  	* configure.ac (with-mkl-arch): New option to set MKL arch library
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.53
diff -c -p -r1.53 configure.ac
*** configure.ac	1 Dec 2005 16:39:27 -0000	1.53
--- configure.ac	2 Dec 2005 20:06:20 -0000
*************** AC_ARG_WITH(fftw2_prefix,
*** 98,139 ****
  
  
  # LAPACK and related libraries (Intel MKL)
! AC_ARG_ENABLE([lapack],
!   AS_HELP_STRING([--enable-lapack],
!                  [use LAPACK if found (default is to not search for it)]),,
!   [enable_lapack=no])
  
  AC_ARG_ENABLE([builtin_lapack],
    AS_HELP_STRING([--disable-builtin-lapack],
!                  [disable use of builtin LAPACK (default is to use if
!                  no other LAPACK found).]),,
    [enable_builtin_lapack="yes"])
  
- AC_ARG_ENABLE([lapack],
-   AS_HELP_STRING([--with-lapack=PKG],
-                  [Specify lapack library to use: mkl7, mkl5, atlas, generic, or
- 		  builtin]),
-   [enable_lapack="yes"])
- 
  AC_ARG_WITH(atlas_prefix,
    AS_HELP_STRING([--with-atlas-prefix=PATH],
                   [specify the installation prefix of the ATLAS library.
  	          Headers must be in PATH/include; libraries in PATH/lib.
! 	          (Enables LAPACK).]),
!   [enable_lapack=atlas])
  
  AC_ARG_WITH(atlas_libdir,
    AS_HELP_STRING([--with-atlas-libdir=PATH],
                   [specify the directory containing ATLAS libraries.
! 	          (Enables LAPACK).]),
!   [enable_lapack=atlas])
  
  AC_ARG_WITH(mkl_prefix,
    AS_HELP_STRING([--with-mkl-prefix=PATH],
                   [specify the installation prefix of the MKL library.  Headers
                    must be in PATH/include; libraries in PATH/lib.
! 	          (Enables LAPACK).]),
!   [enable_lapack=mkl])
  
  AC_ARG_WITH(mkl_arch,
    AS_HELP_STRING([--with-mkl-arch=ARCH],
--- 98,134 ----
  
  
  # LAPACK and related libraries (Intel MKL)
! AC_ARG_WITH([lapack],
!   AS_HELP_STRING([--with-lapack\[=PKG\]],
!                  [enable use of LAPACK if found
!                   (default is to not search for it).  Optionally, the
! 		  specific LAPACK library (mkl7, mkl5, atlas, generic, or
! 		  builtin) to use can be specified with PKG]),,
!   [with_lapack=no])
  
  AC_ARG_ENABLE([builtin_lapack],
    AS_HELP_STRING([--disable-builtin-lapack],
!                  [disable use of builtin LAPACK (default is to use it if
! 		 LAPACK is enabled by no installed LAPACK library is
! 		 found).]),,
    [enable_builtin_lapack="yes"])
  
  AC_ARG_WITH(atlas_prefix,
    AS_HELP_STRING([--with-atlas-prefix=PATH],
                   [specify the installation prefix of the ATLAS library.
  	          Headers must be in PATH/include; libraries in PATH/lib.
! 	          (Enables LAPACK).]))
  
  AC_ARG_WITH(atlas_libdir,
    AS_HELP_STRING([--with-atlas-libdir=PATH],
                   [specify the directory containing ATLAS libraries.
! 	          (Enables LAPACK).]))
  
  AC_ARG_WITH(mkl_prefix,
    AS_HELP_STRING([--with-mkl-prefix=PATH],
                   [specify the installation prefix of the MKL library.  Headers
                    must be in PATH/include; libraries in PATH/lib.
! 	          (Enables LAPACK).]))
  
  AC_ARG_WITH(mkl_arch,
    AS_HELP_STRING([--with-mkl-arch=ARCH],
*************** fi
*** 822,837 ****
  
  
  #
  # Find the lapack library, if enabled.
  #
! echo "enable_lapack: $enable_lapack"
! if test "$enable_lapack" != "no"; then
    keep_CPPFLAGS=$CPPFLAGS
    keep_LDFLAGS=$LDFLAGS
    keep_LIBS=$LIBS
    cblas_style="0"
  
!   if test "$enable_lapack" == "mkl"; then
  
      if test "$with_mkl_arch" == "probe"; then
        if test "$host_cpu" == "x86_64"; then
--- 817,849 ----
  
  
  #
+ # Check to see if any options have implied with_lapack
+ #
+ if test "$with_lapack" == "no"; then
+   if test "$with_atlas_prefix" != "" -o "$with_atlas_prefix" != ""; then
+     if test "$with_mkl_prefix" != ""; then
+       AC_MSG_ERROR([Prefixes given for both MKL and ATLAS])
+     fi
+     AC_MSG_RESULT([ATLAS prefixes specified, enabling lapack])
+     with_lapack="atlas"
+   fi
+   if test "$with_mkl_prefix" != ""; then
+     AC_MSG_RESULT([MKL prefixes specified, enabling lapack])
+     with_lapack="mkl"
+   fi
+ fi
+ 
+ #
  # Find the lapack library, if enabled.
  #
! echo "with_lapack: $with_lapack"
! if test "$with_lapack" != "no"; then
    keep_CPPFLAGS=$CPPFLAGS
    keep_LDFLAGS=$LDFLAGS
    keep_LIBS=$LIBS
    cblas_style="0"
  
!   if test "$with_lapack" == "mkl"; then
  
      if test "$with_mkl_arch" == "probe"; then
        if test "$host_cpu" == "x86_64"; then
*************** if test "$enable_lapack" != "no"; then
*** 843,860 ****
      AC_MSG_RESULT([Using $with_mkl_arch for MKL architecture directory])
  
      lapack_packages="mkl7 mkl5"
!   elif test "$enable_lapack" == "atlas"; then
      lapack_packages="atlas"
    else
!     if test "$with_lapack" != ""; then
!       lapack_packages="$with_lapack"
!     elif test "$enable_builtin_lapack" == "yes"; then
        lapack_packages="atlas generic builtin"
      else
        lapack_packages="atlas generic"
      fi
    fi
  
    lapack_found="no"
    for trypkg in $lapack_packages; do
      if test "$trypkg" == "mkl5"; then
--- 855,872 ----
      AC_MSG_RESULT([Using $with_mkl_arch for MKL architecture directory])
  
      lapack_packages="mkl7 mkl5"
!   elif test "$with_lapack" == "atlas"; then
      lapack_packages="atlas"
    else
!     if test "$enable_builtin_lapack" == "yes"; then
        lapack_packages="atlas generic builtin"
      else
        lapack_packages="atlas generic"
      fi
    fi
  
+   AC_MSG_RESULT([Searching for LAPACK packages: $lapack_packages])
+ 
    lapack_found="no"
    for trypkg in $lapack_packages; do
      if test "$trypkg" == "mkl5"; then
*************** if test "$enable_lapack" != "no"; then
*** 986,992 ****
    done
  
    if test "$lapack_found" == "no"; then
!     if test "$enable_lapack" != "probe"; then
        AC_MSG_ERROR([LAPACK enabled but no library found])
      fi
      AC_MSG_RESULT([No LAPACK library found])
--- 998,1004 ----
    done
  
    if test "$lapack_found" == "no"; then
!     if test "$with_lapack" != "probe"; then
        AC_MSG_ERROR([LAPACK enabled but no library found])
      fi
      AC_MSG_RESULT([No LAPACK library found])
