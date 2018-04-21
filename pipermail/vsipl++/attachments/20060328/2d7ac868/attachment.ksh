? ChangeLog.new
? config.log
? src/vsip/impl/.lapack.hpp.swp
? tests/Makefile.in
? vendor/atlas/autom4te.cache
? vendor/atlas/configure
? vendor/atlas/CONFIG/acconfig.hpp.in
? vendor/atlas/bin/Makefile.in
? vendor/atlas/interfaces/blas/C/src/Makefile.in
? vendor/atlas/interfaces/blas/C/testing/Makefile.in
? vendor/atlas/interfaces/blas/F77/src/Makefile.in
? vendor/atlas/interfaces/blas/F77/testing/Makefile.in
? vendor/atlas/interfaces/lapack/C/src/Makefile.in
? vendor/atlas/interfaces/lapack/F77/src/Makefile.in
? vendor/atlas/lib/Makefile.in
? vendor/atlas/src/auxil/Makefile.in
? vendor/atlas/src/blas/gemm/Make.inc.in
? vendor/atlas/src/blas/gemm/Makefile.in
? vendor/atlas/src/blas/gemm/GOTO/Makefile.in
? vendor/atlas/src/blas/gemv/Make.inc.in
? vendor/atlas/src/blas/gemv/Makefile.in
? vendor/atlas/src/blas/ger/Make.inc.in
? vendor/atlas/src/blas/ger/Makefile.in
? vendor/atlas/src/blas/level1/Make.inc.in
? vendor/atlas/src/blas/level1/Makefile.in
? vendor/atlas/src/blas/level2/Makefile.in
? vendor/atlas/src/blas/level2/kernel/Makefile.in
? vendor/atlas/src/blas/level3/Makefile.in
? vendor/atlas/src/blas/level3/kernel/Makefile.in
? vendor/atlas/src/blas/level3/rblas/Makefile.in
? vendor/atlas/src/blas/pklevel3/Makefile.in
? vendor/atlas/src/blas/pklevel3/gpmm/Makefile.in
? vendor/atlas/src/blas/pklevel3/sprk/Makefile.in
? vendor/atlas/src/blas/reference/level1/Makefile.in
? vendor/atlas/src/blas/reference/level2/Makefile.in
? vendor/atlas/src/blas/reference/level3/Makefile.in
? vendor/atlas/src/lapack/Makefile.in
? vendor/atlas/src/pthreads/blas/level1/Makefile.in
? vendor/atlas/src/pthreads/blas/level2/Makefile.in
? vendor/atlas/src/pthreads/blas/level3/Makefile.in
? vendor/atlas/src/pthreads/misc/Makefile.in
? vendor/atlas/src/testing/Makefile.in
? vendor/atlas/tune/blas/gemm/Makefile.in
? vendor/atlas/tune/blas/gemv/Makefile.in
? vendor/atlas/tune/blas/ger/Makefile.in
? vendor/atlas/tune/blas/level1/Makefile.in
? vendor/atlas/tune/blas/level3/Makefile.in
? vendor/atlas/tune/sysinfo/Makefile.in
? vendor/clapack/SRC/.cblas.h.swp
Index: src/vsip/impl/lapack.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/lapack.hpp,v
retrieving revision 1.11
diff -u -r1.11 lapack.hpp
--- src/vsip/impl/lapack.hpp	1 Dec 2005 16:39:27 -0000	1.11
+++ src/vsip/impl/lapack.hpp	28 Mar 2006 19:55:53 -0000
@@ -32,6 +32,31 @@
 #include <vsip/impl/acconfig.hpp>
 #include <vsip/impl/metaprogramming.hpp>
 
+#define CVT_TRANSPOSE(c) \
+   (((c) == 'N' || (c) == 'n') ? CblasNoTrans : \
+    ((c) == 'T' || (c) == 't') ? CblasTrans : \
+    ((c) == 'C' || (c) == 'c') ? CblasConjTrans : \
+    CblasNoTrans)
+
+#define CVT_UPLO(c) \
+   (((c) == 'U' || (c) == 'u') ? CblasUpper : \
+    ((c) == 'L' || (c) == 'l') ? CblasLower : \
+    CblasLower)
+
+#define CVT_DIAG(c) \
+   (((c) == 'U' || (c) == 'u') ? CblasUnit : \
+    ((c) == 'N' || (c) == 'n') ? CblasNonUnit : \
+    CblasNonUnit)
+
+#define CVT_SIDE(c) \
+   (((c) == 'L' || (c) == 'l') ? CblasLeft : \
+    ((c) == 'R' || (c) == 'r') ? CblasRight : \
+    CblasRight)
+
+
+
+
+
 extern "C"
 {
 #if VSIP_IMPL_USE_CBLAS == 1
@@ -75,7 +100,6 @@
 
   void cdotc_(C, I, C, I, C, I);
   void zdotc_(Z, I, Z, I, Z, I);
-#endif
 
   // trsm
   void strsm_ (char*, char*, char*, char*, I, I, S, S, I, S, I);
@@ -103,6 +127,8 @@
   void cgeru_ ( I, I, C, C, I, C, I, C, I );
   void zgeru_ ( I, I, Z, Z, I, Z, I, Z, I );
 
+
+#endif
 };
 
 #define VSIP_IMPL_CBLAS_DOT(T, VPPFCN, BLASFCN)				\
@@ -193,11 +219,49 @@
       b, &ldb);								\
 }
 
+/* define an overloaded function that helps as pas some scalars to the cblas
+   functions. Some cblas functions require the argument to be passed as a
+   pointer when it is complex but by reference otherwise. This makes the
+   defines a little easier to look at */
+
+inline float  cblas_scalar_cast(float arg) { return arg; }
+inline double cblas_scalar_cast(double arg) { return arg; }
+inline void*  cblas_scalar_cast(std::complex<float> &arg)
+  { return static_cast<void*> (&arg); }
+inline void*  cblas_scalar_cast(std::complex<double> &arg)
+  { return static_cast<void*> (&arg); }
+
+
+#define VSIP_IMPL_CBLAS_TRSM(T, FCN)					\
+inline void								\
+trsm(char side, char uplo,char transa,char diag,			\
+     int m, int n,							\
+     T alpha,								\
+     T *a, int lda,							\
+     T *b, int ldb)							\
+{									\
+  FCN(CblasColMajor,							\
+      CVT_SIDE(side), CVT_UPLO(uplo),CVT_TRANSPOSE(transa),		\
+      CVT_DIAG(diag),							\
+      m, n,								\
+      cblas_scalar_cast(alpha),						\
+      a, lda,							\
+      b, ldb);							\
+}
+
+#if VSIP_IMPL_USE_CBLAS
+VSIP_IMPL_CBLAS_TRSM(float,               cblas_strsm)
+VSIP_IMPL_CBLAS_TRSM(double,              cblas_dtrsm)
+VSIP_IMPL_CBLAS_TRSM(std::complex<float>, cblas_ctrsm)
+VSIP_IMPL_CBLAS_TRSM(std::complex<double>,cblas_ztrsm)
+#else
 VSIP_IMPL_BLAS_TRSM(float,                strsm_)
 VSIP_IMPL_BLAS_TRSM(double,               dtrsm_)
 VSIP_IMPL_BLAS_TRSM(std::complex<float>,  ctrsm_)
 VSIP_IMPL_BLAS_TRSM(std::complex<double>, ztrsm_)
+#endif
 
+#undef VSIP_IMPL_CBLAS_TRSM
 #undef VSIP_IMPL_BLAS_TRSM
 
 
@@ -221,11 +285,40 @@
       y, &incy);							\
 }
 
+#define VSIP_IMPL_CBLAS_GEMV(T, FCN)					\
+inline void								\
+gemv(char transa,            						\
+     int m, int n,       						\
+     T alpha,								\
+     T *a, int lda,							\
+     T *x, int incx,							\
+     T beta,								\
+     T *y, int incy)							\
+{									\
+  FCN(CblasColMajor, 							\
+      CVT_TRANSPOSE(transa), 						\
+      m, n,    								\
+      cblas_scalar_cast(alpha),						\
+      a, lda,								\
+      x, incx,								\
+      cblas_scalar_cast(beta),						\
+      y, incy);								\
+}
+
+
+#if VSIP_IMPL_USE_CBLAS
+VSIP_IMPL_CBLAS_GEMV(float,               cblas_sgemv)
+VSIP_IMPL_CBLAS_GEMV(double,              cblas_dgemv)
+VSIP_IMPL_CBLAS_GEMV(std::complex<float>, cblas_cgemv)
+VSIP_IMPL_CBLAS_GEMV(std::complex<double>,cblas_zgemv)
+#else
 VSIP_IMPL_BLAS_GEMV(float,                sgemv_)
 VSIP_IMPL_BLAS_GEMV(double,               dgemv_)
 VSIP_IMPL_BLAS_GEMV(std::complex<float>,  cgemv_)
 VSIP_IMPL_BLAS_GEMV(std::complex<double>, zgemv_)
+#endif
 
+#undef VSIP_IMPL_CBLAS_GEMV
 #undef VSIP_IMPL_BLAS_GEMV
 
 
@@ -249,12 +342,41 @@
       c, &ldc);								\
 }
 
+#define VSIP_IMPL_CBLAS_GEMM(T, FCN)					\
+inline void								\
+gemm(char transa, char transb,						\
+     int m, int n, int k,						\
+     T alpha,								\
+     T *a, int lda,							\
+     T *b, int ldb,							\
+     T beta,								\
+     T *c, int ldc)							\
+{									\
+  FCN(CblasColMajor,							\
+      CVT_TRANSPOSE(transa), CVT_TRANSPOSE(transb),			\
+      m, n, k,								\
+      cblas_scalar_cast(alpha),						\
+      a, lda,								\
+      b, ldb,								\
+      cblas_scalar_cast(beta),						\
+      c, ldc);								\
+}
+
+
+#if VSIP_IMPL_USE_CBLAS
+VSIP_IMPL_CBLAS_GEMM(float,                cblas_sgemm)
+VSIP_IMPL_CBLAS_GEMM(double,               cblas_dgemm)
+VSIP_IMPL_CBLAS_GEMM(std::complex<float>,  cblas_cgemm)
+VSIP_IMPL_CBLAS_GEMM(std::complex<double>, cblas_zgemm)
+#else
 VSIP_IMPL_BLAS_GEMM(float,                sgemm_)
 VSIP_IMPL_BLAS_GEMM(double,               dgemm_)
 VSIP_IMPL_BLAS_GEMM(std::complex<float>,  cgemm_)
 VSIP_IMPL_BLAS_GEMM(std::complex<double>, zgemm_)
+#endif
 
 #undef VSIP_IMPL_BLAS_GEMM
+#undef VSIP_IMPL_CBLAS_GEMM
 
 
 
@@ -273,14 +395,40 @@
       a, &lda);					\
 }
 
+#define VSIP_IMPL_CBLAS_GER(T, VPPFCN, FCN)    	\
+inline void					\
+VPPFCN( int m, int n,           		\
+     T alpha,					\
+     T *x, int incx,				\
+     T *y, int incy,				\
+     T *a, int lda)				\
+{						\
+  FCN(CblasColMajor,				\
+      m, n,    					\
+      cblas_scalar_cast(alpha),			\
+      x, incx,					\
+      y, incy,					\
+      a, lda);					\
+}
+
+#if VSIP_IMPL_USE_CBLAS
+VSIP_IMPL_CBLAS_GER(float,                ger, cblas_sger)
+VSIP_IMPL_CBLAS_GER(double,               ger, cblas_dger)
+VSIP_IMPL_CBLAS_GER(std::complex<float>,  gerc, cblas_cgerc)
+VSIP_IMPL_CBLAS_GER(std::complex<double>, gerc, cblas_zgerc)
+VSIP_IMPL_CBLAS_GER(std::complex<float>,  geru, cblas_cgeru)
+VSIP_IMPL_CBLAS_GER(std::complex<double>, geru, cblas_zgeru)
+#else
 VSIP_IMPL_BLAS_GER(float,                ger, sger_)
 VSIP_IMPL_BLAS_GER(double,               ger, dger_)
 VSIP_IMPL_BLAS_GER(std::complex<float>,  gerc, cgerc_)
 VSIP_IMPL_BLAS_GER(std::complex<double>, gerc, zgerc_)
 VSIP_IMPL_BLAS_GER(std::complex<float>,  geru, cgeru_)
 VSIP_IMPL_BLAS_GER(std::complex<double>, geru, zgeru_)
+#endif
 
 #undef VSIP_IMPL_BLAS_GER
+#undef VSIP_IMPL_CBLAS_GER
 
 
 
Index: vendor/clapack/SRC/blaswrap.h
===================================================================
RCS file: /home/cvs/Repository/clapack/SRC/blaswrap.h,v
retrieving revision 1.1.1.1
diff -u -r1.1.1.1 blaswrap.h
--- vendor/clapack/SRC/blaswrap.h	16 Mar 2006 23:11:40 -0000	1.1.1.1
+++ vendor/clapack/SRC/blaswrap.h	28 Mar 2006 19:55:58 -0000
@@ -155,4 +155,19 @@
 
 #endif /* NO_BLAS_WRAP */
 
+/* now include cblaswr.h which has the definitions of these functions. The
+   reason that we do this here is because we want to have the ability to control
+   inlines. If NO_INLINE_WRAP is not defined, we define INLINE to "inline". If 
+   NO_INLINE_WRAP is defined, we skip this section and cblaswr.c includes
+   cblaswr.h and will define INLINE to "". This way when NO_INLINE_WRAP is
+   defined, the user will see the functions when they include blaswrap.h
+*/
+
+#ifndef NO_INLINE_WRAP   /* controls the definition of inline */
+
+#define INLINE static inline
+#include "cblaswr.h"
+
+#endif
+
 #endif /* __BLASWRAP_H */
Index: vendor/clapack/SRC/cblaswr.c
===================================================================
RCS file: /home/cvs/Repository/clapack/SRC/cblaswr.c,v
retrieving revision 1.1
diff -u -r1.1 cblaswr.c
--- vendor/clapack/SRC/cblaswr.c	21 Mar 2006 13:37:27 -0000	1.1
+++ vendor/clapack/SRC/cblaswr.c	28 Mar 2006 19:55:58 -0000
@@ -1,1714 +1,16 @@
 #include "f2c.h"
 #include "cblas.h"
 
-/*
-#define CBLAS_INDEX size_t 
-
-enum CBLAS_ORDER 	{CblasRowMajor=101, CblasColMajor=102};
-enum CBLAS_TRANSPOSE 	{CblasNoTrans=111, CblasTrans=112, CblasConjTrans=113};
-enum CBLAS_UPLO		{CblasUpper=121, CblasLower=122};
-enum CBLAS_DIAG		{CblasNonUnit=131, CblasUnit=132};
-enum CBLAS_SIDE		{CblasLeft=141, CblasRight=142};
+/* This is the part the brings in the functions if we define the NO_INLINE_WRAP
+   macro. If that is the case, we define INLINE to nothing and just grab the
+   functions from cblaswr.h. If NO_INLINE_WRAP is not defined, then blaswrap.h
+   defines INLINE to static inline and includes cblaswr.h.
 */
 
-#define CVT_TRANSPOSE(c) \
-   (((c) == 'N' || (c) == 'n') ? CblasNoTrans : \
-    ((c) == 'T' || (c) == 't') ? CblasTrans : \
-    ((c) == 'C' || (c) == 'c') ? CblasConjTrans : \
-    -1)
-
-#define CVT_UPLO(c) \
-   (((c) == 'U' || (c) == 'u') ? CblasUpper : \
-    ((c) == 'L' || (c) == 'l') ? CblasLower : \
-    -1)
-
-#define CVT_DIAG(c) \
-   (((c) == 'U' || (c) == 'u') ? CblasUnit : \
-    ((c) == 'N' || (c) == 'n') ? CblasNonUnit : \
-    -1)
-
-#define CVT_SIDE(c) \
-   (((c) == 'L' || (c) == 'l') ? CblasLeft : \
-    ((c) == 'R' || (c) == 'r') ? CblasRight : \
-    -1)
-
-
-
-/*
- * ===========================================================================
- * Prototypes for level 1 BLAS functions (complex are recast as routines)
- * ===========================================================================
- */
-
-doublereal 
-f2c_sdot(integer* N, 
-         real* X, integer* incX, 
-         real* Y, integer* incY)
-{
-    return cblas_sdot(*N, X, *incX, Y, *incY);
-}
-
-doublereal 
-f2c_ddot(integer* N, 
-         doublereal* X, integer* incX, 
-         doublereal* Y, integer* incY)
-{
-    return cblas_ddot(*N, X, *incX, Y, *incY);
-}
-
-
-/*
- * Functions having prefixes Z and C only
- */
-
-void
-f2c_cdotu(complex* retval,
-          integer* N, 
-          complex* X, integer* incX, 
-          complex* Y, integer* incY)
-{
-    cblas_cdotu_sub(*N, X, *incX, Y, *incY, retval);
-}
-
-void
-f2c_cdotc(complex* retval,
-          integer* N, 
-          complex* X, integer* incX, 
-          complex* Y, integer* incY)
-{
-    cblas_cdotc_sub(*N, X, *incX, Y, *incY, retval);
-}
-
-void
-f2c_zdotu(doublecomplex* retval,
-          integer* N, 
-          doublecomplex* X, integer* incX, 
-          doublecomplex* Y, integer* incY)
-{
-    cblas_zdotu_sub(*N, X, *incX, Y, *incY, retval);
-}
-
-void
-f2c_zdotc(doublecomplex* retval,
-          integer* N, 
-          doublecomplex* X, integer* incX, 
-          doublecomplex* Y, integer* incY)
-{
-    cblas_zdotc_sub(*N, X, *incX, Y, *incY, retval);
-}
-
-
-/*
- * Functions having prefixes S D SC DZ
- */
-
-doublereal 
-f2c_snrm2(integer* N, 
-          real* X, integer* incX)
-{
-    return cblas_snrm2(*N, X, *incX);
-}
-
-doublereal
-f2c_sasum(integer* N, 
-          real* X, integer* incX)
-{
-    return cblas_sasum(*N, X, *incX);
-}
-
-doublereal 
-f2c_dnrm2(integer* N, 
-          doublereal* X, integer* incX)
-{
-    return cblas_dnrm2(*N, X, *incX);
-}
-
-doublereal
-f2c_dasum(integer* N, 
-          doublereal* X, integer* incX)
-{
-    return cblas_dasum(*N, X, *incX);
-}
-
-doublereal 
-f2c_scnrm2(integer* N, 
-           complex* X, integer* incX)
-{
-    return cblas_scnrm2(*N, X, *incX);
-}
-
-doublereal
-f2c_scasum(integer* N, 
-           complex* X, integer* incX)
-{
-    return cblas_scasum(*N, X, *incX);
-}
-
-doublereal 
-f2c_dznrm2(integer* N, 
-           doublecomplex* X, integer* incX)
-{
-    return cblas_dznrm2(*N, X, *incX);
-}
-
-doublereal
-f2c_dzasum(integer* N, 
-           doublecomplex* X, integer* incX)
-{
-    return cblas_dzasum(*N, X, *incX);
-}
-
-
-/*
- * Functions having standard 4 prefixes (S D C Z)
- */
-integer
-f2c_isamax(integer* N,
-           real* X, integer* incX)
-{
-    if (*N == 0)
-        return 0;
-    return (integer) cblas_isamax(*N, X, *incX) + 1;
-}
-
-integer
-f2c_idamax(integer* N,
-           doublereal* X, integer* incX)
-{
-    if (*N == 0)
-        return 0;
-    return (integer) cblas_idamax(*N, X, *incX) + 1;
-}
-
-integer
-f2c_icamax(integer* N,
-           complex* X, integer* incX)
-{
-    if (*N == 0)
-        return 0;
-    return (integer) cblas_icamax(*N, X, *incX) + 1;
-}
-
-integer
-f2c_izamax(integer* N,
-           doublecomplex* X, integer* incX)
-{
-    if (*N == 0)
-        return 0;
-    return (integer) cblas_izamax(*N, X, *incX) + 1;
-}
-
-
-/*
- * ===========================================================================
- * Prototypes for level 1 BLAS routines
- * ===========================================================================
- */
-
-/*
- * Routines with standard 4 prefixes (s, d, c, z)
- */
-
-int
-f2c_sswap(integer* N,
-          real* X, integer* incX,
-          real* Y, integer* incY)
-{
-    cblas_sswap(*N, X, *incX, Y, *incY);
-    return 0;
-}
-
-int
-f2c_scopy(integer* N,
-          real* X, integer* incX,
-          real* Y, integer* incY)
-{
-    cblas_scopy(*N, X, *incX, Y, *incY);
-    return 0;
-}
-
-int
-f2c_saxpy(integer* N,
-          real* alpha,
-          real* X, integer* incX,
-          real* Y, integer* incY)
-{
-    cblas_saxpy(*N, *alpha, X, *incX, Y, *incY);
-    return 0;
-}
-
-int
-f2c_dswap(integer* N,
-          doublereal* X, integer* incX,
-          doublereal* Y, integer* incY)
-{
-    cblas_dswap(*N, X, *incX, Y, *incY);
-    return 0;
-}
-
-int
-f2c_dcopy(integer* N,
-          doublereal* X, integer* incX,
-          doublereal* Y, integer* incY)
-{
-    cblas_dcopy(*N, X, *incX, Y, *incY);
-    return 0;
-}
-
-int
-f2c_daxpy(integer* N,
-          doublereal* alpha,
-          doublereal* X, integer* incX,
-          doublereal* Y, integer* incY)
-{
-    cblas_daxpy(*N, *alpha, X, *incX, Y, *incY);
-    return 0;
-}
-
-int
-f2c_cswap(integer* N,
-          complex* X, integer* incX,
-          complex* Y, integer* incY)
-{
-    cblas_cswap(*N, X, *incX, Y, *incY);
-    return 0;
-}
-
-int
-f2c_ccopy(integer* N,
-          complex* X, integer* incX,
-          complex* Y, integer* incY)
-{
-    cblas_ccopy(*N, X, *incX, Y, *incY);
-    return 0;
-}
-
-int
-f2c_caxpy(integer* N,
-          complex* alpha,
-          complex* X, integer* incX,
-          complex* Y, integer* incY)
-{
-    cblas_caxpy(*N, alpha, X, *incX, Y, *incY);
-    return 0;
-}
-
-int
-f2c_zswap(integer* N,
-          doublecomplex* X, integer* incX,
-          doublecomplex* Y, integer* incY)
-{
-    cblas_zswap(*N, X, *incX, Y, *incY);
-    return 0;
-}
-
-int
-f2c_zcopy(integer* N,
-          doublecomplex* X, integer* incX,
-          doublecomplex* Y, integer* incY)
-{
-    cblas_zcopy(*N, X, *incX, Y, *incY);
-    return 0;
-}
-
-int
-f2c_zaxpy(integer* N,
-          doublecomplex* alpha,
-          doublecomplex* X, integer* incX,
-          doublecomplex* Y, integer* incY)
-{
-    cblas_zaxpy(*N, alpha, X, *incX, Y, *incY);
-    return 0;
-}
-
-
-/*
- * Routines with S and D prefix only
- */
-
-int
-f2c_srotg(real* a, real* b, real* c, real* s)
-{
-    cblas_srotg(a, b, c, s);
-    return 0;
-}
-
-int
-f2c_srot(integer* N,
-         real* X, integer* incX,
-         real* Y, integer* incY,
-         real* c, real* s)
-{
-    cblas_srot(*N, X, *incX, Y, *incY, *c, *s);
-    return 0;
-}
-
-int
-f2c_drotg(doublereal* a, doublereal* b, doublereal* c, doublereal* s)
-{
-    cblas_drotg(a, b, c, s);
-    return 0;
-}
-
-int
-f2c_drot(integer* N,
-         doublereal* X, integer* incX,
-         doublereal* Y, integer* incY,
-         doublereal* c, doublereal* s)
-{
-    cblas_drot(*N, X, *incX, Y, *incY, *c, *s);
-    return 0;
-}
-
-
-/*
- * Routines with S D C Z CS and ZD prefixes
- */
-
-int
-f2c_sscal(integer* N,
-          real* alpha,
-          real* X, integer* incX)
-{
-    cblas_sscal(*N, *alpha, X, *incX);
-    return 0;
-}
-
-int
-f2c_dscal(integer* N,
-          doublereal* alpha,
-          doublereal* X, integer* incX)
-{
-    cblas_dscal(*N, *alpha, X, *incX);
-    return 0;
-}
-
-int
-f2c_cscal(integer* N,
-          complex* alpha,
-          complex* X, integer* incX)
-{
-    cblas_cscal(*N, alpha, X, *incX);
-    return 0;
-}
-
-
-int
-f2c_zscal(integer* N,
-          doublecomplex* alpha,
-          doublecomplex* X, integer* incX)
-{
-    cblas_zscal(*N, alpha, X, *incX);
-    return 0;
-}
-
-
-int
-f2c_csscal(integer* N,
-           real* alpha,
-           complex* X, integer* incX)
-{
-    cblas_csscal(*N, *alpha, X, *incX);
-    return 0;
-}
-
-
-int
-f2c_zdscal(integer* N,
-           doublereal* alpha,
-           doublecomplex* X, integer* incX)
-{
-    cblas_zdscal(*N, *alpha, X, *incX);
-    return 0;
-}
-
-
-
-/*
- * ===========================================================================
- * Prototypes for level 2 BLAS
- * ===========================================================================
- */
-
-/*
- * Routines with standard 4 prefixes (S, D, C, Z)
- */
-int
-f2c_sgemv(char* trans, integer* M, integer* N,
-          real* alpha,
-          real* A, integer* lda,
-          real* X, integer* incX,
-          real* beta,
-          real* Y, integer* incY)
-{
-    cblas_sgemv(CblasColMajor,
-                CVT_TRANSPOSE(*trans), *M, *N,
-                *alpha, A, *lda, X, *incX, *beta, Y, *incY);
-    return 0;
-}
-
-int 
-f2c_sgbmv(char *trans, integer *M, integer *N, integer *KL, integer *KU, 
-          real *alpha, 
-          real *A, integer *lda, 
-          real *X, integer *incX, 
-          real *beta, 
-          real *Y, integer *incY)
-{
-    cblas_sgbmv(CblasColMajor,
-                CVT_TRANSPOSE(*trans), *M, *N, *KL, *KU,
-                *alpha, A, *lda, X, *incX, *beta, Y, *incY);
-    return 0;
-}
-
-int 
-f2c_strmv(char* uplo, char *trans, char* diag, integer *N,  
-          real *A, integer *lda, 
-          real *X, integer *incX)
-{
-    cblas_strmv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_stbmv(char* uplo, char* trans, char* diag, integer* N, integer* K,
-          real* A, integer* lda,
-          real* X, integer* incX)
-{
-    cblas_stbmv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, *K, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_stpmv(char* uplo, char* trans, char* diag, integer* N, 
-          real* Ap, 
-          real* X, integer* incX)
-{
-    cblas_stpmv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, Ap, X, *incX);
-    return 0;
-}
-
-int
-f2c_strsv(char* uplo, char* trans, char* diag, integer* N,
-          real* A, integer* lda,
-          real* X, integer* incX)
-{
-    cblas_strsv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_stbsv(char* uplo, char* trans, char* diag, integer* N, integer* K,
-          real* A, integer* lda, 
-          real* X, integer* incX)
-{
-    cblas_stbsv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, *K, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_stpsv(char* uplo, char* trans, char* diag, integer* N, 
-          real* Ap, 
-          real* X, integer* incX)
-{
-    cblas_stpsv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, Ap, X, *incX);
-    return 0;
-} 
-
-
-
-int
-f2c_dgemv(char* trans, integer* M, integer* N,
-          doublereal* alpha,
-          doublereal* A, integer* lda,
-          doublereal* X, integer* incX,
-          doublereal* beta,
-          doublereal* Y, integer* incY)
-{
-    cblas_dgemv(CblasColMajor,
-                CVT_TRANSPOSE(*trans), *M, *N,
-                *alpha, A, *lda, X, *incX, *beta, Y, *incY);
-    return 0;
-}
-
-int 
-f2c_dgbmv(char *trans, integer *M, integer *N, integer *KL, integer *KU, 
-          doublereal *alpha, 
-          doublereal *A, integer *lda, 
-          doublereal *X, integer *incX, 
-          doublereal *beta, 
-          doublereal *Y, integer *incY)
-{
-    cblas_dgbmv(CblasColMajor,
-                CVT_TRANSPOSE(*trans), *M, *N, *KL, *KU,
-                *alpha, A, *lda, X, *incX, *beta, Y, *incY);
-    return 0;
-}
-
-int 
-f2c_dtrmv(char* uplo, char *trans, char* diag, integer *N,  
-          doublereal *A, integer *lda, 
-          doublereal *X, integer *incX)
-{
-    cblas_dtrmv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_dtbmv(char* uplo, char* trans, char* diag, integer* N, integer* K,
-          doublereal* A, integer* lda,
-          doublereal* X, integer* incX)
-{
-    cblas_dtbmv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, *K, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_dtpmv(char* uplo, char* trans, char* diag, integer* N, 
-          doublereal* Ap, 
-          doublereal* X, integer* incX)
-{
-    cblas_dtpmv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, Ap, X, *incX);
-    return 0;
-}
-
-int
-f2c_dtrsv(char* uplo, char* trans, char* diag, integer* N,
-          doublereal* A, integer* lda,
-          doublereal* X, integer* incX)
-{
-    cblas_dtrsv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_dtbsv(char* uplo, char* trans, char* diag, integer* N, integer* K,
-          doublereal* A, integer* lda, 
-          doublereal* X, integer* incX)
-{
-    cblas_dtbsv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, *K, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_dtpsv(char* uplo, char* trans, char* diag, integer* N, 
-          doublereal* Ap, 
-          doublereal* X, integer* incX)
-{
-    cblas_dtpsv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, Ap, X, *incX);
-    return 0;
-} 
-
-
-
-int
-f2c_cgemv(char* trans, integer* M, integer* N,
-          complex* alpha,
-          complex* A, integer* lda,
-          complex* X, integer* incX,
-          complex* beta,
-          complex* Y, integer* incY)
-{
-    cblas_cgemv(CblasColMajor,
-                CVT_TRANSPOSE(*trans), *M, *N,
-                alpha, A, *lda, X, *incX, beta, Y, *incY);
-    return 0;
-}
-
-int 
-f2c_cgbmv(char *trans, integer *M, integer *N, integer *KL, integer *KU, 
-          complex *alpha, 
-          complex *A, integer *lda, 
-          complex *X, integer *incX, 
-          complex *beta, 
-          complex *Y, integer *incY)
-{
-    cblas_cgbmv(CblasColMajor,
-                CVT_TRANSPOSE(*trans), *M, *N, *KL, *KU,
-                alpha, A, *lda, X, *incX, beta, Y, *incY);
-    return 0;
-}
-
-int 
-f2c_ctrmv(char* uplo, char *trans, char* diag, integer *N,  
-          complex *A, integer *lda, 
-          complex *X, integer *incX)
-{
-    cblas_ctrmv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_ctbmv(char* uplo, char* trans, char* diag, integer* N, integer* K,
-          complex* A, integer* lda,
-       complex* X, integer* incX)
-{
-    cblas_ctbmv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, *K, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_ctpmv(char* uplo, char* trans, char* diag, integer* N, 
-          complex* Ap, 
-          complex* X, integer* incX)
-{
-    cblas_ctpmv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, Ap, X, *incX);
-    return 0;
-}
-
-int
-f2c_ctrsv(char* uplo, char* trans, char* diag, integer* N,
-          complex* A, integer* lda,
-          complex* X, integer* incX)
-{
-    cblas_ctrsv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_ctbsv(char* uplo, char* trans, char* diag, integer* N, integer* K,
-          complex* A, integer* lda, 
-          complex* X, integer* incX)
-{
-    cblas_ctbsv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, *K, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_ctpsv(char* uplo, char* trans, char* diag, integer* N, 
-          complex* Ap, 
-          complex* X, integer* incX)
-{
-    cblas_ctpsv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, Ap, X, *incX);
-    return 0;
-} 
-
-
-
-int
-f2c_zgemv(char* trans, integer* M, integer* N,
-          doublecomplex* alpha,
-          doublecomplex* A, integer* lda,
-          doublecomplex* X, integer* incX,
-          doublecomplex* beta,
-          doublecomplex* Y, integer* incY)
-{
-    cblas_zgemv(CblasColMajor,
-                CVT_TRANSPOSE(*trans), *M, *N,
-                alpha, A, *lda, X, *incX, beta, Y, *incY);
-    return 0;
-}
-
-int 
-f2c_zgbmv(char *trans, integer *M, integer *N, integer *KL, integer *KU, 
-          doublecomplex *alpha, 
-          doublecomplex *A, integer *lda, 
-          doublecomplex *X, integer *incX, 
-          doublecomplex *beta, 
-          doublecomplex *Y, integer *incY)
-{
-    cblas_zgbmv(CblasColMajor,
-                CVT_TRANSPOSE(*trans), *M, *N, *KL, *KU,
-                alpha, A, *lda, X, *incX, beta, Y, *incY);
-    return 0;
-}
-
-int 
-f2c_ztrmv(char* uplo, char *trans, char* diag, integer *N,  
-          doublecomplex *A, integer *lda, 
-          doublecomplex *X, integer *incX)
-{
-    cblas_ztrmv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_ztbmv(char* uplo, char* trans, char* diag, integer* N, integer* K,
-          doublecomplex* A, integer* lda,
-          doublecomplex* X, integer* incX)
-{
-    cblas_ztbmv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, *K, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_ztpmv(char* uplo, char* trans, char* diag, integer* N, 
-          doublecomplex* Ap, 
-          doublecomplex* X, integer* incX)
-{
-    cblas_ztpmv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, Ap, X, *incX);
-    return 0;
-}
-
-int
-f2c_ztrsv(char* uplo, char* trans, char* diag, integer* N,
-          doublecomplex* A, integer* lda,
-          doublecomplex* X, integer* incX)
-{
-    cblas_ztrsv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_ztbsv(char* uplo, char* trans, char* diag, integer* N, integer* K,
-          doublecomplex* A, integer* lda, 
-          doublecomplex* X, integer* incX)
-{
-    cblas_ztbsv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, *K, A, *lda, X, *incX);
-    return 0;
-}
-
-int
-f2c_ztpsv(char* uplo, char* trans, char* diag, integer* N, 
-          doublecomplex* Ap, 
-          doublecomplex* X, integer* incX)
-{
-    cblas_ztpsv(CblasColMajor, 
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), CVT_DIAG(*diag),
-                *N, Ap, X, *incX);
-    return 0;
-} 
-
-
-/*
- * Routines with S and D prefixes only
- */
-
-int
-f2c_ssymv(char* uplo, integer* N,
-          real* alpha,
-          real* A, integer* lda,
-          real* X, integer* incX,
-          real* beta,
-          real* Y, integer* incY)
-{
-    cblas_ssymv(CblasColMajor, 
-                CVT_UPLO(*uplo), *N, *alpha, A, *lda, 
-                X, *incX, *beta, Y, *incY);
-    return 0;
-}
-
-int 
-f2c_ssbmv(char* uplo, integer* N, integer* K,
-          real* alpha,
-          real* A, integer* lda,
-          real* X, integer* incX,
-          real* beta,
-          real* Y, integer* incY)
-{
-    cblas_ssbmv(CblasColMajor, 
-                CVT_UPLO(*uplo), *N, *K, *alpha, A, *lda, 
-                X, *incX, *beta, Y, *incY);
-    return 0;
-}
-
-int
-f2c_sspmv(char* uplo, integer* N,
-          real* alpha,
-          real* Ap,
-          real* X, integer* incX,
-          real* beta,
-          real* Y, integer* incY)
-{
-    cblas_sspmv(CblasColMajor, 
-                CVT_UPLO(*uplo), *N, *alpha, Ap,  
-                X, *incX, *beta, Y, *incY);
-    return 0;
-}
-
-int
-f2c_sger(integer* M, integer* N,
-         real* alpha,
-         real* X, integer* incX,
-         real* Y, integer* incY,
-         real* A, integer* lda)
-{
-    cblas_sger(CblasColMajor,
-               *M, *N, *alpha,
-               X, *incX, Y, *incY, A, *lda);
-    return 0;
-}
-
-int
-f2c_ssyr(char* uplo, integer* N,
-         real* alpha,
-         real* X, integer* incX,
-         real* A, integer* lda)
-{
-    cblas_ssyr(CblasColMajor,
-               CVT_UPLO(*uplo), *N, *alpha, X, *incX, A, *lda);
-    return 0;
-}
-
-int
-f2c_sspr(char* uplo, integer* N,
-         real* alpha,
-         real* X, integer* incX,
-         real* Ap)
-{
-    cblas_sspr(CblasColMajor,
-               CVT_UPLO(*uplo), *N, *alpha, X, *incX, Ap);
-    return 0;
-}
-
-int
-f2c_ssyr2(char* uplo, integer* N,
-          real* alpha,
-          real* X, integer* incX,
-          real* Y, integer* incY,
-          real* A, integer* lda)
-{
-    cblas_ssyr2(CblasColMajor,
-                CVT_UPLO(*uplo), *N, *alpha,
-                X, *incX, Y, *incY, A, *lda);
-    return 0;
-}
-
-int
-f2c_sspr2(char* uplo, integer* N,
-          real* alpha, 
-          real* X, integer* incX,
-          real* Y, integer* incY,
-          real* A)
-{
-    cblas_sspr2(CblasColMajor,
-                CVT_UPLO(*uplo), *N, *alpha,
-                X, *incX, Y, *incY, A);
-    return 0;
-}
-
-
-
-int
-f2c_dsymv(char* uplo, integer* N,
-          doublereal* alpha,
-          doublereal* A, integer* lda,
-          doublereal* X, integer* incX,
-          doublereal* beta,
-          doublereal* Y, integer* incY)
-{
-    cblas_dsymv(CblasColMajor, 
-                CVT_UPLO(*uplo), *N, *alpha, A, *lda, 
-                X, *incX, *beta, Y, *incY);
-    return 0;
-}
-
-int 
-f2c_dsbmv(char* uplo, integer* N, integer* K,
-          doublereal* alpha,
-          doublereal* A, integer* lda,
-          doublereal* X, integer* incX,
-          doublereal* beta,
-          doublereal* Y, integer* incY)
-{
-    cblas_dsbmv(CblasColMajor, 
-                CVT_UPLO(*uplo), *N, *K, *alpha, A, *lda, 
-                X, *incX, *beta, Y, *incY);
-    return 0;
-}
-
-int
-f2c_dspmv(char* uplo, integer* N,
-          doublereal* alpha,
-          doublereal* Ap,
-          doublereal* X, integer* incX,
-          doublereal* beta,
-          doublereal* Y, integer* incY)
-{
-    cblas_dspmv(CblasColMajor, 
-                CVT_UPLO(*uplo), *N, *alpha, Ap,  
-                X, *incX, *beta, Y, *incY);
-    return 0;
-}
-
-int
-f2c_dger(integer* M, integer* N,
-         doublereal* alpha,
-         doublereal* X, integer* incX,
-         doublereal* Y, integer* incY,
-         doublereal* A, integer* lda)
-{
-    cblas_dger(CblasColMajor,
-               *M, *N, *alpha,
-               X, *incX, Y, *incY, A, *lda);
-    return 0;
-}
-
-int
-f2c_dsyr(char* uplo, integer* N,
-         doublereal* alpha,
-         doublereal* X, integer* incX,
-         doublereal* A, integer* lda)
-{
-    cblas_dsyr(CblasColMajor,
-               CVT_UPLO(*uplo), *N, *alpha, X, *incX, A, *lda);
-    return 0;
-}
-
-int
-f2c_dspr(char* uplo, integer* N,
-         doublereal* alpha,
-         doublereal* X, integer* incX,
-         doublereal* Ap)
-{
-    cblas_dspr(CblasColMajor,
-               CVT_UPLO(*uplo), *N, *alpha, X, *incX, Ap);
-    return 0;
-}
-
-int
-f2c_dsyr2(char* uplo, integer* N,
-          doublereal* alpha,
-          doublereal* X, integer* incX,
-          doublereal* Y, integer* incY,
-          doublereal* A, integer* lda)
-{
-    cblas_dsyr2(CblasColMajor,
-                CVT_UPLO(*uplo), *N, *alpha,
-                X, *incX, Y, *incY, A, *lda);
-    return 0;
-}
-
-int
-f2c_dspr2(char* uplo, integer* N,
-          doublereal* alpha, 
-          doublereal* X, integer* incX,
-          doublereal* Y, integer* incY,
-          doublereal* A)
-{
-    cblas_dspr2(CblasColMajor,
-                CVT_UPLO(*uplo), *N, *alpha,
-                X, *incX, Y, *incY, A);
-    return 0;
-}
-
-
-
-/*
- * Routines with C and Z prefixes only
- */
-
-int
-f2c_chemv(char* uplo, integer* N,
-          complex* alpha,
-          complex* A, integer* lda,
-          complex* X, integer* incX,
-          complex* beta,
-          complex* Y, integer* incY)
-{
-    cblas_chemv(CblasColMajor,
-                CVT_UPLO(*uplo), *N, alpha, A, *lda,
-                X, *incX, beta, Y, *incY);
-    return 0;
-}
-
-int
-f2c_chbmv(char* uplo, integer* N, integer* K,
-          complex* alpha,
-          complex* A, integer* lda,
-          complex* X, integer* incX,
-          complex* beta,
-          complex* Y, integer* incY)
-{
-    cblas_chbmv(CblasColMajor,
-                CVT_UPLO(*uplo), *N, *K, alpha, A, *lda,
-                X, *incX, beta, Y, *incY);
-    return 0;
-}
-
-int
-f2c_chpmv(char* uplo, integer* N, 
-          complex* alpha,
-          complex* Ap, 
-          complex* X, integer* incX,
-          complex* beta,
-          complex* Y, integer* incY)
-{
-    cblas_chpmv(CblasColMajor,
-                CVT_UPLO(*uplo), *N, alpha, Ap, 
-                X, *incX, beta, Y, *incY);
-    return 0;
-}
-
-int
-f2c_cgeru(integer* M, integer* N,
-          complex* alpha,
-          complex* X, integer* incX,
-          complex* Y, integer* incY,
-          complex* A, integer* lda)
-{
-    cblas_cgeru(CblasColMajor,
-                *M, *N, alpha, 
-                X, *incX, Y, *incY, A, *lda);
-    return 0;
-}
-
-int
-f2c_cgerc(integer* M, integer* N,
-          complex* alpha,
-          complex* X, integer* incX,
-          complex* Y, integer* incY,
-          complex* A, integer* lda)
-{
-    cblas_cgerc(CblasColMajor,
-                *M, *N, alpha, 
-                X, *incX, Y, *incY, A, *lda);
-    return 0;
-}
-
-int
-f2c_cher(char* uplo, integer* N,
-         real* alpha,
-         complex* X, integer* incX,
-         complex* A, integer* lda)
-{
-    cblas_cher(CblasColMajor,
-               CVT_UPLO(*uplo), *N, *alpha,
-               X, *incX, A, *lda);
-    return 0;
-}
-
-int
-f2c_chpr(char* uplo, integer* N,
-         real* alpha,
-         complex* X, integer* incX,
-         complex* Ap)
-{
-    cblas_chpr(CblasColMajor,
-               CVT_UPLO(*uplo), *N, *alpha,
-               X, *incX, Ap);
-    return 0;
-}
-
-int
-f2c_cher2(char* uplo, integer* N,
-          complex* alpha,
-          complex* X, integer* incX,
-          complex* Y, integer* incY,
-          complex* A, integer* lda)
-{
-    cblas_cher2(CblasColMajor,
-                CVT_UPLO(*uplo), *N, alpha,
-                X, *incX, Y, *incY, A, *lda);
-    return 0;
-}
-
-int
-f2c_chpr2(char* uplo, integer* N,
-          complex* alpha,
-          complex* X, integer* incX,
-          complex* Y, integer* incY,
-          complex* Ap)
-{
-    cblas_chpr2(CblasColMajor,
-                CVT_UPLO(*uplo), *N, alpha,
-                X, *incX, Y, *incY, Ap);
-    return 0;
-}
-
-
-
-int
-f2c_zhemv(char* uplo, integer* N,
-          doublecomplex* alpha,
-          doublecomplex* A, integer* lda,
-          doublecomplex* X, integer* incX,
-          doublecomplex* beta,
-          doublecomplex* Y, integer* incY)
-{
-    cblas_zhemv(CblasColMajor,
-                CVT_UPLO(*uplo), *N, alpha, A, *lda,
-                X, *incX, beta, Y, *incY);
-    return 0;
-}
-
-int
-f2c_zhbmv(char* uplo, integer* N, integer* K,
-          doublecomplex* alpha,
-          doublecomplex* A, integer* lda,
-          doublecomplex* X, integer* incX,
-          doublecomplex* beta,
-          doublecomplex* Y, integer* incY)
-{
-    cblas_zhbmv(CblasColMajor,
-                CVT_UPLO(*uplo), *N, *K, alpha, A, *lda,
-                X, *incX, beta, Y, *incY);
-    return 0;
-}
-
-int
-f2c_zhpmv(char* uplo, integer* N, 
-          doublecomplex* alpha,
-          doublecomplex* Ap, 
-          doublecomplex* X, integer* incX,
-          doublecomplex* beta,
-          doublecomplex* Y, integer* incY)
-{
-    cblas_zhpmv(CblasColMajor,
-                CVT_UPLO(*uplo), *N, alpha, Ap, 
-                X, *incX, beta, Y, *incY);
-    return 0;
-}
-
-int
-f2c_zgeru(integer* M, integer* N,
-          doublecomplex* alpha,
-          doublecomplex* X, integer* incX,
-          doublecomplex* Y, integer* incY,
-          doublecomplex* A, integer* lda)
-{
-    cblas_zgeru(CblasColMajor,
-                *M, *N, alpha, 
-                X, *incX, Y, *incY, A, *lda);
-    return 0;
-}
-
-int
-f2c_zgerc(integer* M, integer* N,
-          doublecomplex* alpha,
-          doublecomplex* X, integer* incX,
-          doublecomplex* Y, integer* incY,
-          doublecomplex* A, integer* lda)
-{
-    cblas_zgerc(CblasColMajor,
-                *M, *N, alpha, 
-                X, *incX, Y, *incY, A, *lda);
-    return 0;
-}
-
-int
-f2c_zher(char* uplo, integer* N,
-         doublereal* alpha,
-         doublecomplex* X, integer* incX,
-         doublecomplex* A, integer* lda)
-{
-    cblas_zher(CblasColMajor,
-               CVT_UPLO(*uplo), *N, *alpha,
-               X, *incX, A, *lda);
-    return 0;
-}
-
-int
-f2c_zhpr(char* uplo, integer* N,
-         doublereal* alpha,
-         doublecomplex* X, integer* incX,
-         doublecomplex* Ap)
-{
-    cblas_zhpr(CblasColMajor,
-               CVT_UPLO(*uplo), *N, *alpha,
-               X, *incX, Ap);
-    return 0;
-}
-
-int
-f2c_zher2(char* uplo, integer* N,
-          doublecomplex* alpha,
-          doublecomplex* X, integer* incX,
-          doublecomplex* Y, integer* incY,
-          doublecomplex* A, integer* lda)
-{
-    cblas_zher2(CblasColMajor,
-                CVT_UPLO(*uplo), *N, alpha,
-                X, *incX, Y, *incY, A, *lda);
-    return 0;
-}
-
-int
-f2c_zhpr2(char* uplo, integer* N,
-          doublecomplex* alpha,
-          doublecomplex* X, integer* incX,
-          doublecomplex* Y, integer* incY,
-          doublecomplex* Ap)
-{
-    cblas_zhpr2(CblasColMajor,
-                CVT_UPLO(*uplo), *N, alpha,
-                X, *incX, Y, *incY, Ap);
-    return 0;
-}
-
-
-
-/*
- * ===========================================================================
- * Prototypes for level 3 BLAS
- * ===========================================================================
- */
-
-/*
- * Routines with standard 4 prefixes (S, D, C, Z)
- */
-
-int
-f2c_sgemm(char* transA, char* transB, integer* M, integer* N, integer* K,
-          real* alpha,
-          real* A, integer* lda,
-          real* B, integer* ldb,
-          real* beta,
-          real* C, integer* ldc)
-{
-    cblas_sgemm(CblasColMajor,
-                CVT_TRANSPOSE(*transA), CVT_TRANSPOSE(*transB), *M, *N, *K,
-                *alpha, A, *lda, B, *ldb, *beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_ssymm(char* side, char* uplo, integer* M, integer* N,
-          real* alpha,
-          real* A, integer* lda,
-          real* B, integer* ldb,
-          real* beta,
-          real* C, integer* ldc)
-{
-    cblas_ssymm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), *M, *N,
-                *alpha, A, *lda, B, *ldb, *beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_ssyrk(char* uplo, char* trans, integer* N, integer* K,
-          real* alpha,
-          real* A, integer* lda,
-          real* beta,
-          real* C, integer* ldc)
-{
-    cblas_ssyrk(CblasColMajor,
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), *N, *K,
-                *alpha, A, *lda, *beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_ssyr2k(char* uplo, char* trans, integer* N, integer* K,
-           real* alpha,
-           real* A, integer* lda,
-           real* B, integer* ldb,
-           real* beta,
-           real* C, integer* ldc)
-{
-    cblas_ssyr2k(CblasColMajor,
-                 CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), *N, *K,
-                 *alpha, A, *lda, B, *ldb, *beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_strmm(char* side, char* uplo, char* trans, char* diag, 
-          integer* M, integer* N,
-          real* alpha,
-          real* A, integer* lda,
-          real* B, integer* ldb)
-{
-    cblas_strmm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), 
-                CVT_TRANSPOSE(*trans), CVT_DIAG(*diag), 
-                *M, *N, *alpha, A, *lda, B, *ldb);
-    return 0;
-}
-
-int 
-f2c_strsm(char* side, char* uplo, char* trans, char* diag,
-          integer* M, integer* N,
-          real* alpha,
-          real* A, integer* lda,
-          real* B, integer* ldb)
-{
-    cblas_strsm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), 
-                CVT_TRANSPOSE(*trans), CVT_DIAG(*diag), 
-                *M, *N, *alpha, A, *lda, B, *ldb);
-    return 0;
-}
-
-
-
-int
-f2c_dgemm(char* transA, char* transB, integer* M, integer* N, integer* K,
-          doublereal* alpha,
-          doublereal* A, integer* lda,
-          doublereal* B, integer* ldb,
-          doublereal* beta,
-          doublereal* C, integer* ldc)
-{
-    cblas_dgemm(CblasColMajor,
-                CVT_TRANSPOSE(*transA), CVT_TRANSPOSE(*transB), *M, *N, *K,
-                *alpha, A, *lda, B, *ldb, *beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_dsymm(char* side, char* uplo, integer* M, integer* N,
-          doublereal* alpha,
-          doublereal* A, integer* lda,
-          doublereal* B, integer* ldb,
-          doublereal* beta,
-          doublereal* C, integer* ldc)
-{
-    cblas_dsymm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), *M, *N,
-                *alpha, A, *lda, B, *ldb, *beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_dsyrk(char* uplo, char* trans, integer* N, integer* K,
-          doublereal* alpha,
-          doublereal* A, integer* lda,
-          doublereal* beta,
-          doublereal* C, integer* ldc)
-{
-    cblas_dsyrk(CblasColMajor,
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), *N, *K,
-                *alpha, A, *lda, *beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_dsyr2k(char* uplo, char* trans, integer* N, integer* K,
-           doublereal* alpha,
-           doublereal* A, integer* lda,
-           doublereal* B, integer* ldb,
-           doublereal* beta,
-           doublereal* C, integer* ldc)
-{
-    cblas_dsyr2k(CblasColMajor,
-                 CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), *N, *K,
-                 *alpha, A, *lda, B, *ldb, *beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_dtrmm(char* side, char* uplo, char* trans, char* diag, 
-          integer* M, integer* N,
-          doublereal* alpha,
-          doublereal* A, integer* lda,
-          doublereal* B, integer* ldb)
-{
-    cblas_dtrmm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), 
-                CVT_TRANSPOSE(*trans), CVT_DIAG(*diag), 
-                *M, *N, *alpha, A, *lda, B, *ldb);
-    return 0;
-}
-
-int 
-f2c_dtrsm(char* side, char* uplo, char* trans, char* diag,
-          integer* M, integer* N,
-          doublereal* alpha,
-          doublereal* A, integer* lda,
-          doublereal* B, integer* ldb)
-{
-    cblas_dtrsm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), 
-                CVT_TRANSPOSE(*trans), CVT_DIAG(*diag), 
-                *M, *N, *alpha, A, *lda, B, *ldb);
-    return 0;
-}
-
-
-
-int
-f2c_cgemm(char* transA, char* transB, integer* M, integer* N, integer* K,
-          complex* alpha,
-          complex* A, integer* lda,
-          complex* B, integer* ldb,
-          complex* beta,
-          complex* C, integer* ldc)
-{
-    cblas_cgemm(CblasColMajor,
-                CVT_TRANSPOSE(*transA), CVT_TRANSPOSE(*transB), *M, *N, *K,
-                alpha, A, *lda, B, *ldb, beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_csymm(char* side, char* uplo, integer* M, integer* N,
-          complex* alpha,
-          complex* A, integer* lda,
-          complex* B, integer* ldb,
-          complex* beta,
-          complex* C, integer* ldc)
-{
-    cblas_csymm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), *M, *N,
-                alpha, A, *lda, B, *ldb, beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_csyrk(char* uplo, char* trans, integer* N, integer* K,
-          complex* alpha,
-          complex* A, integer* lda,
-          complex* beta,
-          complex* C, integer* ldc)
-{
-    cblas_csyrk(CblasColMajor,
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), *N, *K,
-                alpha, A, *lda, beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_csyr2k(char* uplo, char* trans, integer* N, integer* K,
-           complex* alpha,
-           complex* A, integer* lda,
-           complex* B, integer* ldb,
-           complex* beta,
-           complex* C, integer* ldc)
-{
-    cblas_csyr2k(CblasColMajor,
-                 CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), *N, *K,
-                 alpha, A, *lda, B, *ldb, beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_ctrmm(char* side, char* uplo, char* trans, char* diag, 
-          integer* M, integer* N,
-          complex* alpha,
-          complex* A, integer* lda,
-          complex* B, integer* ldb)
-{
-    cblas_ctrmm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), 
-                CVT_TRANSPOSE(*trans), CVT_DIAG(*diag), 
-                *M, *N, alpha, A, *lda, B, *ldb);
-    return 0;
-}
-
-int 
-f2c_ctrsm(char* side, char* uplo, char* trans, char* diag,
-          integer* M, integer* N,
-          complex* alpha,
-          complex* A, integer* lda,
-          complex* B, integer* ldb)
-{
-    cblas_ctrsm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), 
-                CVT_TRANSPOSE(*trans), CVT_DIAG(*diag), 
-                *M, *N, alpha, A, *lda, B, *ldb);
-    return 0;
-}
-
-
-
-int
-f2c_zgemm(char* transA, char* transB, integer* M, integer* N, integer* K,
-          doublecomplex* alpha,
-          doublecomplex* A, integer* lda,
-          doublecomplex* B, integer* ldb,
-          doublecomplex* beta,
-          doublecomplex* C, integer* ldc)
-{
-    cblas_zgemm(CblasColMajor,
-                CVT_TRANSPOSE(*transA), CVT_TRANSPOSE(*transB), *M, *N, *K,
-                alpha, A, *lda, B, *ldb, beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_zsymm(char* side, char* uplo, integer* M, integer* N,
-          doublecomplex* alpha,
-          doublecomplex* A, integer* lda,
-          doublecomplex* B, integer* ldb,
-          doublecomplex* beta,
-          doublecomplex* C, integer* ldc)
-{
-    cblas_zsymm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), *M, *N,
-                alpha, A, *lda, B, *ldb, beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_zsyrk(char* uplo, char* trans, integer* N, integer* K,
-          doublecomplex* alpha,
-          doublecomplex* A, integer* lda,
-          doublecomplex* beta,
-          doublecomplex* C, integer* ldc)
-{
-    cblas_zsyrk(CblasColMajor,
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), *N, *K,
-                alpha, A, *lda, beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_zsyr2k(char* uplo, char* trans, integer* N, integer* K,
-           doublecomplex* alpha,
-           doublecomplex* A, integer* lda,
-           doublecomplex* B, integer* ldb,
-           doublecomplex* beta,
-           doublecomplex* C, integer* ldc)
-{
-    cblas_zsyr2k(CblasColMajor,
-                 CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), *N, *K,
-                 alpha, A, *lda, B, *ldb, beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_ztrmm(char* side, char* uplo, char* trans, char* diag, 
-          integer* M, integer* N,
-          doublecomplex* alpha,
-          doublecomplex* A, integer* lda,
-          doublecomplex* B, integer* ldb)
-{
-    cblas_ztrmm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), 
-                CVT_TRANSPOSE(*trans), CVT_DIAG(*diag), 
-                *M, *N, alpha, A, *lda, B, *ldb);
-    return 0;
-}
-
-int 
-f2c_ztrsm(char* side, char* uplo, char* trans, char* diag,
-          integer* M, integer* N,
-          doublecomplex* alpha,
-          doublecomplex* A, integer* lda,
-          doublecomplex* B, integer* ldb)
-{
-    cblas_ztrsm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), 
-                CVT_TRANSPOSE(*trans), CVT_DIAG(*diag), 
-                *M, *N, alpha, A, *lda, B, *ldb);
-    return 0;
-}
-
-
-
-/*
- * Routines with prefixes C and Z only
- */
-
-int
-f2c_chemm(char* side, char* uplo, integer* M, integer* N,
-          complex* alpha,
-          complex* A, integer* lda,
-          complex* B, integer* ldb,
-          complex* beta,
-          complex* C, integer* ldc)
-{
-    cblas_chemm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), *M, *N,
-                alpha, A, *lda, B, *ldb, beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_cherk(char* uplo, char* trans, integer* N, integer* K,
-          real* alpha,
-          complex* A, integer* lda,
-          real* beta,
-          complex* C, integer* ldc)
-{
-    cblas_cherk(CblasColMajor,
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), *N, *K,
-                *alpha, A, *lda, *beta, C, *ldc);
-    return 0;
-}
-
-int
-f2c_cher2k(char* uplo, char* trans, integer* N, integer* K,
-           complex* alpha,
-           complex* A, integer* lda,
-           complex* B, integer* ldb,
-           real* beta,
-           complex* C, integer* ldc)
-{
-    cblas_cher2k(CblasColMajor,
-                 CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), *N, *K,
-                 alpha, A, *lda, B, *ldb, *beta, C, *ldc);
-    return 0;
-}
-
-
-
-int
-f2c_zhemm(char* side, char* uplo, integer* M, integer* N,
-          doublecomplex* alpha,
-          doublecomplex* A, integer* lda,
-          doublecomplex* B, integer* ldb,
-          doublecomplex* beta,
-          doublecomplex* C, integer* ldc)
-{
-    cblas_zhemm(CblasColMajor,
-                CVT_SIDE(*side), CVT_UPLO(*uplo), *M, *N,
-                alpha, A, *lda, B, *ldb, beta, C, *ldc);
-    return 0;
-}
+#ifdef NO_INLINE_WRAP
 
-int
-f2c_zherk(char* uplo, char* trans, integer* N, integer* K,
-          doublereal* alpha,
-          doublecomplex* A, integer* lda,
-          doublereal* beta,
-          doublecomplex* C, integer* ldc)
-{
-    cblas_zherk(CblasColMajor,
-                CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), *N, *K,
-                *alpha, A, *lda, *beta, C, *ldc);
-    return 0;
-}
+#define INLINE
+#include "cblaswr.h"
 
-int
-f2c_zher2k(char* uplo, char* trans, integer* N, integer* K,
-           doublecomplex* alpha,
-           doublecomplex* A, integer* lda,
-           doublecomplex* B, integer* ldb,
-           doublereal* beta,
-           doublecomplex* C, integer* ldc)
-{
-    cblas_zher2k(CblasColMajor,
-                 CVT_UPLO(*uplo), CVT_TRANSPOSE(*trans), *N, *K,
-                 alpha, A, *lda, B, *ldb, *beta, C, *ldc);
-    return 0;
-}
+#endif
 
