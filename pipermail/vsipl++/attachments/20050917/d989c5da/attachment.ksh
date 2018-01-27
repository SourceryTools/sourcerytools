Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.249
diff -c -p -r1.249 ChangeLog
*** ChangeLog	17 Sep 2005 08:45:35 -0000	1.249
--- ChangeLog	17 Sep 2005 16:17:02 -0000
***************
*** 1,3 ****
--- 1,7 ----
+ 2005-09-17  Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* configure.ac: Fix typo.
+ 
  2005-09-17  Nathan Myers  <ncm@codesourcery.com>
  
  	* src/vsip/impl/signal-fft.hpp: fix a real->complex FFTM
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.32
diff -c -p -r1.32 configure.ac
*** configure.ac	16 Sep 2005 02:13:38 -0000	1.32
--- configure.ac	17 Sep 2005 16:17:02 -0000
*************** int main(int, char **)
*** 498,504 ****
  [AC_MSG_RESULT(yes)],
  [AC_MSG_ERROR([std::complex-incompatible IPP-types detected!])])
  
!     if test "enable_ipp_fft" != "no"; then 
        save_LDFLAGS="$LDFLAGS"
        LDFLAGS="$LDFLAGS $IPP_FFT_LDFLAGS"
        
--- 498,504 ----
  [AC_MSG_RESULT(yes)],
  [AC_MSG_ERROR([std::complex-incompatible IPP-types detected!])])
  
!     if test "$enable_ipp_fft" != "no"; then 
        save_LDFLAGS="$LDFLAGS"
        LDFLAGS="$LDFLAGS $IPP_FFT_LDFLAGS"
        
