*** ncm-fftw3/configure.ac	2005-12-20 12:36:37.000000000 -0500
--- work-fftw3/configure.ac	2005-12-20 13:32:28.000000000 -0500
*************** if test "$build_fftw3" != "no"; then
*** 452,478 ****
      fftw3_opts="$fftw3_opts --disable-fortran"
  
  
!     fftw3_simd=
      case "$host_cpu" in
!       (ia32|i686|x86_64) fftw3_simd="--enable-sse2" ;;
!       (ppc*)             fftw3_simd="--enable-altivec" ;;
      esac
      AC_MSG_NOTICE([fftw3 config options: $fftw3_opts $fftw3_simd.])
  
      echo "==============================================================="
  
      mkdir -p vendor/fftw3f
      AC_MSG_NOTICE([Configuring fftw3f (float).])
!     (cd vendor/fftw3f; $fftw3_configure $fftw3_opts $fftw3_simd --enable-float)
  
      mkdir -p vendor/fftw3
      AC_MSG_NOTICE([Configuring fftw3 (double).])
!     (cd vendor/fftw3; $fftw3_configure $fftw3_simd $fftw3_opts )
  
      # fftw3l config doesn't get SIMD option
      mkdir -p vendor/fftw3l
      AC_MSG_NOTICE([Configuring fftw3l (long double).])
!     (cd vendor/fftw3l; $fftw3_configure $fftw3_opts --enable-long-double)
  
      echo "==============================================================="
  
--- 452,487 ----
      fftw3_opts="$fftw3_opts --disable-fortran"
  
  
!     fftw3_f_simd=
!     fftw3_d_simd=
!     fftw3_l_simd=
      case "$host_cpu" in
!       (ia32|i686)        fftw3_f_simd="--enable-sse"
! 	                 fftw3_d_simd="--enable-sse2" 
! 	                 ;;
!       (x86_64)           fftw3_d_simd=""
! 	                 ;;
!       (ppc*)             fftw3_f_simd="--enable-altivec" ;;
      esac
      AC_MSG_NOTICE([fftw3 config options: $fftw3_opts $fftw3_simd.])
+     AC_MSG_NOTICE([fftw3 float config options: '$fftw3_f_simd'.])
+     AC_MSG_NOTICE([fftw3 double config options: '$fftw3_d_simd'.])
+     AC_MSG_NOTICE([fftw3 long-double config options: '$fftw3_l_simd'.])
  
      echo "==============================================================="
  
      mkdir -p vendor/fftw3f
      AC_MSG_NOTICE([Configuring fftw3f (float).])
!     (cd vendor/fftw3f; $fftw3_configure $fftw3_f_simd $fftw3_opts --enable-float)
  
      mkdir -p vendor/fftw3
      AC_MSG_NOTICE([Configuring fftw3 (double).])
!     (cd vendor/fftw3; $fftw3_configure $fftw3_d_simd $fftw3_opts )
  
      # fftw3l config doesn't get SIMD option
      mkdir -p vendor/fftw3l
      AC_MSG_NOTICE([Configuring fftw3l (long double).])
!     (cd vendor/fftw3l; $fftw3_configure $fftw3_l_simd $fftw3_opts --enable-long-double)
  
      echo "==============================================================="
  
*************** if test "$build_fftw3" != "no"; then
*** 481,489 ****
      fftw3_src_prefix="`(cd $srcdir/vendor/fftw; echo \"$PWD\")`"
      ln -s "$fftw3_src_prefix"/api vendor/fftw/include
      # these don't refer to anything yet, but will when built:
!     ln -s ../../fftwf/libfftw3f-csl.a vendor/fftw/lib/libfftw3f-csl.a
!     ln -s ../../fftwf/libfftw3-csl.a vendor/fftw/lib/libfftw3-csl.a
!     ln -s ../../fftwf/libfftw3l-csl.a vendor/fftw/lib/libfftw3l-csl.a
    else
      AC_MSG_RESULT([not found])
    fi
--- 490,498 ----
      fftw3_src_prefix="`(cd $srcdir/vendor/fftw; echo \"$PWD\")`"
      ln -s "$fftw3_src_prefix"/api vendor/fftw/include
      # these don't refer to anything yet, but will when built:
!     ln -s ../../fftw3f/libfftw3f-csl.a vendor/fftw/lib/libfftw3f-csl.a
!     ln -s ../../fftw3/libfftw3-csl.a vendor/fftw/lib/libfftw3-csl.a
!     ln -s ../../fftw3l/libfftw3l-csl.a vendor/fftw/lib/libfftw3l-csl.a
    else
      AC_MSG_RESULT([not found])
    fi
*** ncm-fftw3/vendor/GNUmakefile.inc.in	2005-12-20 12:36:37.000000000 -0500
--- work-fftw3/vendor/GNUmakefile.inc.in	2005-12-20 12:33:25.000000000 -0500
*************** ifdef USE_BUILTIN_FFTW
*** 76,93 ****
  
  vendor_FFTW_LIBS := \
  	vendor/fftw3f/libfftw3f-csl.a \
! 	vendor/fftw3f/libfftw3-csl.a \
! 	vendor/fftw3f/libfftw3l-csl.a \
  
  all:: $(vendor_FFTW_LIBS)
  
  libs:: $(vendor_FFTW_LIBS)
  
! $(vendor_FFTW_LIBS):
! 	@echo "Building FFTW (fftw.build.log)"
! 	@$(MAKE) -C vendor/fftw3f build  > fftw.build.log 2>&1
! 	@$(MAKE) -C vendor/fftw3  build >> fftw.build.log 2>&1
! 	@$(MAKE) -C vendor/fftw3l build >> fftw.build.log 2>&1
  
  clean::
  	@echo "Cleaning FFTW (fftw.clean.log)"
--- 76,102 ----
  
  vendor_FFTW_LIBS := \
  	vendor/fftw3f/libfftw3f-csl.a \
! 	vendor/fftw3/libfftw3-csl.a \
! 	vendor/fftw3l/libfftw3l-csl.a \
  
  all:: $(vendor_FFTW_LIBS)
  
  libs:: $(vendor_FFTW_LIBS)
  
! vendor/fftw3f/libfftw3f-csl.a:
! 	@echo "Building FFTW float (fftw-f.build.log)"
! 	@$(MAKE) -C vendor/fftw3f > fftw-f.build.log 2>&1
! 	mv vendor/fftw3f/.libs/libfftw3f.a vendor/fftw3f/libfftw3f-csl.a
! 
! vendor/fftw3/libfftw3-csl.a:
! 	@echo "Building FFTW double (fftw-d.build.log)"
! 	@$(MAKE) -C vendor/fftw3 > fftw-d.build.log 2>&1
! 	mv vendor/fftw3/.libs/libfftw3.a vendor/fftw3/libfftw3-csl.a
! 
! vendor/fftw3l/libfftw3l-csl.a:
! 	@echo "Building FFTW double (fftw-l.build.log)"
! 	@$(MAKE) -C vendor/fftw3l > fftw-l.build.log 2>&1
! 	mv vendor/fftw3l/.libs/libfftw3l.a vendor/fftw3l/libfftw3l-csl.a
  
  clean::
  	@echo "Cleaning FFTW (fftw.clean.log)"
*************** clean::
*** 97,109 ****
  
  install::
  	@echo "Installing FFTW (fftw.install.log)"
- 	# @$(MAKE) -C vendor/fftw3f installinstall  > fftw.install.log 2>&1
- 	# @$(MAKE) -C vendor/fftw3  installinstall >> fftw.install.log 2>&1
- 	# @$(MAKE) -C vendor/fftw3l installinstall >> fftw.install.log 2>&1
  	$(INSTALL) -d $(libdir)/fftw3
! 	$(INSTALL_DATA) vendor/fftw3f/libfftw3f-csl.a   $(libdir)/fftw3
! 	$(INSTALL_DATA) vendor/fftw3f/libfftw3-csl.a    $(libdir)/fftw3
! 	$(INSTALL_DATA) vendor/fftw3f/libfftw3l-csl.a   $(libdir)/fftw3
  	$(INSTALL) -d $(includedir)
  	$(INSTALL_DATA) $(srcdir)/vendor/fftw/api/fftw3.h $(includedir)
  endif
--- 106,115 ----
  
  install::
  	@echo "Installing FFTW (fftw.install.log)"
  	$(INSTALL) -d $(libdir)/fftw3
! 	$(INSTALL_DATA) vendor/fftw3f/libfftw3f-csl.a  $(libdir)/fftw3
! 	$(INSTALL_DATA) vendor/fftw3/libfftw3-csl.a    $(libdir)/fftw3
! 	$(INSTALL_DATA) vendor/fftw3l/libfftw3l-csl.a  $(libdir)/fftw3
  	$(INSTALL) -d $(includedir)
  	$(INSTALL_DATA) $(srcdir)/vendor/fftw/api/fftw3.h $(includedir)
  endif
