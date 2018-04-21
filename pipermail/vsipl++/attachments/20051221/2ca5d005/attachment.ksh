Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.61
diff -c -p -r1.61 configure.ac
*** configure.ac	21 Dec 2005 14:52:42 -0000	1.61
--- configure.ac	21 Dec 2005 16:15:58 -0000
*************** vsip_impl_avoid_posix_memalign=
*** 362,367 ****
--- 362,368 ----
  enable_fftw3="no"
  enable_fftw2="no"
  enable_ipp_fft="no"
+ build_fftw3="no"
  
  if test "$chose_fft" = "no" \
       -o "$with_fft"  = "fftw3" \
*************** else
*** 384,391 ****
                  fftw2-double, fftw2-generic, ipp, or builtin.])
  fi 
  
- build_fftw3=yes
  if test "$enable_fftw3" != "no" ; then
  
    keep_CPPFLAGS="$CPPFLAGS"
    keep_LIBS="$LIBS"
--- 385,392 ----
                  fftw2-double, fftw2-generic, ipp, or builtin.])
  fi 
  
  if test "$enable_fftw3" != "no" ; then
+   build_fftw3=yes
  
    keep_CPPFLAGS="$CPPFLAGS"
    keep_LIBS="$LIBS"
