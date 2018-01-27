Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.298
diff -c -p -r1.298 ChangeLog
*** ChangeLog	27 Oct 2005 17:50:49 -0000	1.298
--- ChangeLog	28 Oct 2005 16:31:22 -0000
***************
*** 1,3 ****
--- 1,8 ----
+ 2005-10-28 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* src/vsip/impl/lapack.hpp: Treat FORTRAN functions returning
+ 	  complex values as subroutines.
+ 
  2005-10-27  Nathan Myers  <ncm@codesourcery.com>
  
  	* src/vsip/impl/ipp.cpp, sal.cpp: remove glorious #ifdefs, defer
Index: src/vsip/impl/lapack.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/lapack.hpp,v
retrieving revision 1.8
diff -c -p -r1.8 lapack.hpp
*** src/vsip/impl/lapack.hpp	12 Oct 2005 12:45:05 -0000	1.8
--- src/vsip/impl/lapack.hpp	28 Oct 2005 16:31:22 -0000
*************** extern "C"
*** 58,68 ****
    // dot
    float  sdot_ (I, S, I, S, I);
    double ddot_ (I, D, I, D, I);
-   std::complex<float>  cdotu_(I, C, I, C, I);
-   std::complex<double> zdotu_(I, Z, I, Z, I);
  
!   std::complex<float>  cdotc_(I, C, I, C, I);
!   std::complex<double> zdotc_(I, Z, I, Z, I);
  
    // trsm
    void strsm_ (char*, char*, char*, char*, I, I, S, S, I, S, I);
--- 58,69 ----
    // dot
    float  sdot_ (I, S, I, S, I);
    double ddot_ (I, D, I, D, I);
  
!   void cdotu_(C, I, C, I, C, I);
!   void zdotu_(Z, I, Z, I, Z, I);
! 
!   void cdotc_(C, I, C, I, C, I);
!   void zdotc_(Z, I, Z, I, Z, I);
  
    // trsm
    void strsm_ (char*, char*, char*, char*, I, I, S, S, I, S, I);
*************** VPPFCN(int n,								\
*** 88,103 ****
  
  VSIP_IMPL_BLAS_DOT(float,                dot, sdot_)
  VSIP_IMPL_BLAS_DOT(double,               dot, ddot_)
- VSIP_IMPL_BLAS_DOT(std::complex<float>,  dot, cdotu_)
- VSIP_IMPL_BLAS_DOT(std::complex<double>, dot, zdotu_)
- 
- VSIP_IMPL_BLAS_DOT(std::complex<float>,  dotc, cdotc_)
- VSIP_IMPL_BLAS_DOT(std::complex<double>, dotc, zdotc_)
  
  #undef VSIP_IMPL_BLAS_DOT
  
  
  
  #define VSIP_IMPL_BLAS_TRSM(T, FCN)					\
  inline void								\
  trsm(char side, char uplo,char transa,char diag,			\
--- 89,121 ----
  
  VSIP_IMPL_BLAS_DOT(float,                dot, sdot_)
  VSIP_IMPL_BLAS_DOT(double,               dot, ddot_)
  
  #undef VSIP_IMPL_BLAS_DOT
  
  
  
+ #define VSIP_IMPL_BLAS_CDOT(T, VPPFCN, BLASFCN)				\
+ inline T								\
+ VPPFCN(int n,								\
+     T* x, int incx,							\
+     T* y, int incy)							\
+ {									\
+   T ret;								\
+   BLASFCN(&ret, &n, x, &incx, y, &incy);				\
+   return ret;								\
+ }
+ 
+ 
+ VSIP_IMPL_BLAS_CDOT(std::complex<float>,  dot, cdotu_)
+ VSIP_IMPL_BLAS_CDOT(std::complex<double>, dot, zdotu_)
+ 
+ VSIP_IMPL_BLAS_CDOT(std::complex<float>,  dotc, cdotc_)
+ VSIP_IMPL_BLAS_CDOT(std::complex<double>, dotc, zdotc_)
+ 
+ #undef VSIP_IMPL_BLAS_CDOT
+ 
+ 
+ 
  #define VSIP_IMPL_BLAS_TRSM(T, FCN)					\
  inline void								\
  trsm(char side, char uplo,char transa,char diag,			\
