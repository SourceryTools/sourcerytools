Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.450
diff -u -r1.450 ChangeLog
--- ChangeLog	2 May 2006 15:15:30 -0000	1.450
+++ ChangeLog	2 May 2006 21:24:03 -0000
@@ -1,5 +1,28 @@
 2006-05-02  Jules Bergmann  <jules@codesourcery.com>
 
+	* configure.ac: Add --with-lapack=acml option to use AMD Core Math
+	  Library (ACML) for LAPACK.
+	* src/vsip/impl/lapack.hpp: Add support for ACML.
+	* src/vsip/impl/solver-cholesky.hpp: Use Choose_solver_impl for
+	  dispatch.
+	* src/vsip/impl/solver-lu.hpp: Likewise.
+	* src/vsip/impl/solver_common.hpp (Choose_solver_impl): New dispatch
+	  class for selecting a solver implementation.
+	* src/vsip/impl/lapack/solver_cholesky.hpp (Is_lud_impl_avail):
+	  Specialize for Lapack tag.
+	* src/vsip/impl/lapack/solver_lu.hpp (Is_lud_impl_avail):
+	  Specialize for Lapack tag.
+	* src/vsip/impl/sal/solver_cholesky.hpp: Fix order of member
+	  initialization.
+	* src/vsip/impl/lapack/acml_cblas.hpp: New file, cblas wrappers
+	  for ACML's dot-product functions.
+	* tests/solver-cholesky.cpp: Only test Chold for types implemented
+	  by a backend.
+	* tests/solver-lu.cpp: Only test LU for types implemented by a
+	  backend.
+	
+2006-05-02  Jules Bergmann  <jules@codesourcery.com>
+
 	* benchmarks/GNUmakefile.inc.in: Update libvsip location.
 	* benchmarks/dot.cpp: Fix Wall warning.
 	* benchmarks/mcopy_ipp.cpp: Likewise.
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.97
diff -u -r1.97 configure.ac
--- configure.ac	1 May 2006 19:12:03 -0000	1.97
+++ configure.ac	2 May 2006 21:24:03 -0000
@@ -210,6 +210,12 @@
 		  (Default is to probe arch based on host cpu type).]),,
   [with_mkl_arch=probe])
 
+AC_ARG_WITH(acml_prefix,
+  AS_HELP_STRING([--with-acml-prefix=PATH],
+                 [specify the installation prefix of the ACML library.  Headers
+                  must be in PATH/include; libraries in PATH/lib
+	          (Enables LAPACK).]))
+
 AC_ARG_ENABLE([cblas],
   AS_HELP_STRING([--disable-cblas],
                  [disable C BLAS API (default is to use it if possible)]),,
@@ -1179,6 +1185,10 @@
     AC_MSG_RESULT([MKL prefixes specified, enabling lapack])
     with_lapack="mkl"
   fi
+  if test "$with_acml_prefix" != ""; then
+    AC_MSG_RESULT([ACML prefixes specified, enabling lapack])
+    with_lapack="acml"
+  fi
 fi
 
 #
@@ -1238,6 +1248,21 @@
       cblas_style="2"	# use mkl_cblas.h
 
       lapack_use_ilaenv=0
+    elif test "$trypkg" == "acml"; then
+      AC_MSG_CHECKING([for LAPACK/ACML library])
+
+      dnl We don't use the ACML header files:
+      dnl CPPFLAGS="$keep_CPPFLAGS -I$with_acml_prefix/include"
+      LDFLAGS="$keep_LDFLAGS -L$with_acml_prefix/lib"
+      LIBS="$keep_LIBS -lacml $use_g2c"
+      cblas_style="3"	# use acml_cblas.h
+
+      if test $use_g2c == "error"; then
+        AC_MSG_RESULT([skipping (g2c needed but not found)])
+	continue
+      fi
+
+      lapack_use_ilaenv=0
     elif test "$trypkg" == "atlas"; then
       AC_MSG_CHECKING([for LAPACK/ATLAS library])
 
@@ -1322,6 +1347,13 @@
 	if test "$target" != ""; then
 	  atlas_opts="$atlas_opts --target=$target"
 	fi
+
+        if test "$trypkg" == "fortran-builtin"; then
+	  atlas_opts="$atlas_opts --enable-fortran"
+        else
+	  atlas_opts="$atlas_opts --disable-fortran"
+        fi
+
 	atlas_opts="$atlas_opts $with_atlas_cfg_opts"
 
 	# Use a wrapper command to encode the -m32 and -m64 flags for
@@ -1672,6 +1704,7 @@
 if test "$enable_mpi" != "no"; then
   AC_MSG_RESULT([With parallel service:                   $PAR_SERVICE])
 fi
+AC_MSG_RESULT([With LAPACK                              $lapack_found])
 AC_MSG_RESULT([With SAL:                                $enable_sal])
 AC_MSG_RESULT([With IPP:                                $enable_ipp])
 AC_MSG_RESULT([Using FFT backends:                      ${enable_fft}])
Index: src/vsip/impl/lapack.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/lapack.hpp,v
retrieving revision 1.12
diff -u -r1.12 lapack.hpp
--- src/vsip/impl/lapack.hpp	29 Mar 2006 16:38:15 -0000	1.12
+++ src/vsip/impl/lapack.hpp	2 May 2006 21:24:03 -0000
@@ -3,7 +3,7 @@
 /** @file    vsip/impl/lapack.hpp
     @author  Jules Bergmann
     @date    2005-08-19
-    @brief   VSIPL++ Library: Lacpack interface
+    @brief   VSIPL++ Library: Lapack interface
 
 NOTES:
  [0] LAPACK is a Fortran API.  There is not a standard C API, as there is
@@ -59,10 +59,37 @@
 
 extern "C"
 {
+
+// Include the appropriate CBLAS header, depending on which library
+// we're using.
+// 
+// If VSIP_IMPL_USE_CBLAS == 1, we're using ATLAS' CBLAS.
+// If VSIP_IMPL_USE_CBLAS == 2, we're using MKL's CBLAS.
+// If VSIP_IMPL_USE_CBLAS == 3, we're using ACML's psuedo-CBLAS.
+//
+// ACML doesn't provide a CBLAS API.  However, it does provide C
+// linkage to BLAS functions.
+//  - For the dot-product routines that have a non-void return type, We
+//    use our own CBLAS wrappers on top of the ACML C linkage to avoid
+//    potential ABI issues (VISP_IMPL_USE_CBLAS_DOT == 1).
+//  - For other BLAS routines, we use the ACML Fortran linkage.
+
+
 #if VSIP_IMPL_USE_CBLAS == 1
 #  include <cblas.h>
+#  define VSIP_IMPL_USE_CBLAS_DOT    1
+#  define VSIP_IMPL_USE_CBLAS_OTHERS 1
 #elif VSIP_IMPL_USE_CBLAS == 2
 #  include <mkl_cblas.h>
+#  define VSIP_IMPL_USE_CBLAS_DOT    1
+#  define VSIP_IMPL_USE_CBLAS_OTHERS 1
+#elif VSIP_IMPL_USE_CBLAS == 3
+#  include <vsip/impl/lapack/acml_cblas.hpp>
+#  define VSIP_IMPL_USE_CBLAS_DOT    1
+#  define VSIP_IMPL_USE_CBLAS_OTHERS 0
+#else
+#  define VSIP_IMPL_USE_CBLAS_DOT    0
+#  define VSIP_IMPL_USE_CBLAS_OTHERS 0
 #endif
 }
 
@@ -89,8 +116,7 @@
   typedef std::complex<float>*  C;
   typedef std::complex<double>* Z;
 
-#if VSIP_IMPL_USE_CBLAS
-#else
+#if !VSIP_IMPL_USE_CBLAS_DOT
   // dot
   VSIP_IMPL_FORTRAN_FLOAT_RETURN sdot_ (I, S, I, S, I);
   double ddot_ (I, D, I, D, I);
@@ -100,7 +126,9 @@
 
   void cdotc_(C, I, C, I, C, I);
   void zdotc_(Z, I, Z, I, Z, I);
+#endif
 
+#if !VSIP_IMPL_USE_CBLAS_OTHERS
   // trsm
   void strsm_ (char*, char*, char*, char*, I, I, S, S, I, S, I);
   void dtrsm_ (char*, char*, char*, char*, I, I, D, D, I, D, I);
@@ -126,8 +154,6 @@
   void zgerc_ ( I, I, Z, Z, I, Z, I, Z, I );
   void cgeru_ ( I, I, C, C, I, C, I, C, I );
   void zgeru_ ( I, I, Z, Z, I, Z, I, Z, I );
-
-
 #endif
 };
 
@@ -149,13 +175,13 @@
   return BLASFCN(&n, x, &incx, y, &incy);				\
 }
 
-#if VSIP_IMPL_USE_CBLAS
+#if VSIP_IMPL_USE_CBLAS_DOT
   VSIP_IMPL_CBLAS_DOT(float,                dot, cblas_sdot)
   VSIP_IMPL_CBLAS_DOT(double,               dot, cblas_ddot)
 #else
   VSIP_IMPL_BLAS_DOT(float,                dot, sdot_)
   VSIP_IMPL_BLAS_DOT(double,               dot, ddot_)
-#endif // VSIP_IMPL_USE_CBLAS
+#endif // VSIP_IMPL_USE_CBLAS_DOT
 
 #undef VSIP_IMPL_BLAS_DOT
 
@@ -186,7 +212,7 @@
 }
 
 
-#if VSIP_IMPL_USE_CBLAS
+#if VSIP_IMPL_USE_CBLAS_DOT
   VSIP_IMPL_CBLAS_CDOT(std::complex<float>,  dot, cblas_cdotu_sub)
   VSIP_IMPL_CBLAS_CDOT(std::complex<double>, dot, cblas_zdotu_sub)
 
@@ -250,7 +276,7 @@
       b, ldb);							\
 }
 
-#if VSIP_IMPL_USE_CBLAS
+#if VSIP_IMPL_USE_CBLAS_OTHERS
 VSIP_IMPL_CBLAS_TRSM(float,               cblas_strsm)
 VSIP_IMPL_CBLAS_TRSM(double,              cblas_dtrsm)
 VSIP_IMPL_CBLAS_TRSM(std::complex<float>, cblas_ctrsm)
@@ -307,7 +333,7 @@
 }
 
 
-#if VSIP_IMPL_USE_CBLAS
+#if VSIP_IMPL_USE_CBLAS_OTHERS
 VSIP_IMPL_CBLAS_GEMV(float,               cblas_sgemv)
 VSIP_IMPL_CBLAS_GEMV(double,              cblas_dgemv)
 VSIP_IMPL_CBLAS_GEMV(std::complex<float>, cblas_cgemv)
@@ -364,7 +390,7 @@
 }
 
 
-#if VSIP_IMPL_USE_CBLAS
+#if VSIP_IMPL_USE_CBLAS_OTHERS
 VSIP_IMPL_CBLAS_GEMM(float,                cblas_sgemm)
 VSIP_IMPL_CBLAS_GEMM(double,               cblas_dgemm)
 VSIP_IMPL_CBLAS_GEMM(std::complex<float>,  cblas_cgemm)
@@ -412,7 +438,7 @@
       a, lda);					\
 }
 
-#if VSIP_IMPL_USE_CBLAS
+#if VSIP_IMPL_USE_CBLAS_OTHERS
 VSIP_IMPL_CBLAS_GER(float,                ger, cblas_sger)
 VSIP_IMPL_CBLAS_GER(double,               ger, cblas_dger)
 VSIP_IMPL_CBLAS_GER(std::complex<float>,  gerc, cblas_cgerc)
Index: src/vsip/impl/solver-cholesky.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-cholesky.hpp,v
retrieving revision 1.5
diff -u -r1.5 solver-cholesky.hpp
--- src/vsip/impl/solver-cholesky.hpp	21 Apr 2006 01:19:58 -0000	1.5
+++ src/vsip/impl/solver-cholesky.hpp	2 May 2006 21:24:03 -0000
@@ -19,13 +19,14 @@
 #include <vsip/support.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/impl/math-enum.hpp>
-#include <vsip/impl/lapack.hpp>
 #include <vsip/impl/temp_buffer.hpp>
+#include <vsip/impl/solver_common.hpp>
 #ifdef VSIP_IMPL_HAVE_SAL
-#include <vsip/impl/sal/solver_cholesky.hpp>
+#  include <vsip/impl/sal/solver_cholesky.hpp>
+#endif
+#ifdef VSIP_IMPL_HAVE_LAPACK
+#  include <vsip/impl/lapack/solver_cholesky.hpp>
 #endif
-#include <vsip/impl/lapack/solver_cholesky.hpp>
-#include <vsip/impl/solver_common.hpp>
 
 
 
@@ -39,20 +40,38 @@
 namespace impl
 {
 
+// List of implementation tags to consider for Cholesky.
+
+typedef Make_type_list<
+#ifdef VSIP_IMPL_HAVE_SAL
+  Mercury_sal_tag,
+#endif
+#ifdef VSIP_IMPL_HAVE_LAPACK
+  Lapack_tag,
+#endif
+  None_type // None_type is treated specially by Make_type_list, it is
+            // not be put into the list.  Putting an explicit None_type
+            // at the end of the list lets us put a ',' after each impl
+            // tag.
+  >::type Chold_type_list;
+  
+
+
+// a structure to chose implementation type
 template <typename T>
 struct Choose_chold_impl
 {
-#ifndef VSIP_IMPL_HAVE_SAL
-  typedef typename ITE_Type<Is_chold_impl_avail<Mercury_sal_tag, T>::value,
-                            As_type<Mercury_sal_tag>,
-			    As_type<Lapack_tag> >::type type;
-#else
-  typedef typename As_type<Lapack_tag>::type type;
-#endif
-
+  typedef typename Choose_solver_impl<
+    Is_chold_impl_avail,
+    T,
+    Chold_type_list>::type type;
+
+  typedef typename ITE_Type<
+    Type_equal<type, None_type>::value,
+    As_type<Error_no_solver_for_this_type>,
+    As_type<type> >::type use_type;
 };
 
-
 } // namespace vsip::impl
 
 /// CHOLESKY solver object.
@@ -63,9 +82,9 @@
 
 template <typename T>
 class chold<T, by_reference>
-  : public impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::type>
+  : public impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::use_type>
 {
-  typedef impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::type>
+  typedef impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::use_type>
     base_type;
 
   // Constructors, copies, assignments, and destructors.
@@ -88,9 +107,9 @@
 
 template <typename T>
 class chold<T, by_value>
-  : public impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::type>
+  : public impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::use_type>
 {
-  typedef impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::type>
+  typedef impl::Chold_impl<T, typename impl::Choose_chold_impl<T>::use_type>
     base_type;
 
   // Constructors, copies, assignments, and destructors.
Index: src/vsip/impl/solver-lu.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-lu.hpp,v
retrieving revision 1.5
diff -u -r1.5 solver-lu.hpp
--- src/vsip/impl/solver-lu.hpp	21 Apr 2006 01:19:58 -0000	1.5
+++ src/vsip/impl/solver-lu.hpp	2 May 2006 21:24:03 -0000
@@ -19,13 +19,15 @@
 #include <vsip/support.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/impl/math-enum.hpp>
-#include <vsip/impl/lapack.hpp>
 #include <vsip/impl/temp_buffer.hpp>
 #include <vsip/impl/metaprogramming.hpp>
+#  include <vsip/impl/solver_common.hpp>
 #ifdef VSIP_IMPL_HAVE_SAL
 #  include <vsip/impl/sal/solver_lu.hpp>
 #endif
-#include <vsip/impl/lapack/solver_lu.hpp>
+#ifdef VSIP_IMPL_HAVE_LAPACK
+#  include <vsip/impl/lapack/solver_lu.hpp>
+#endif
 
 
 
@@ -39,19 +41,36 @@
 namespace impl
 {
 
+// List of implementation tags to consider for LU.
+
+typedef Make_type_list<
+#ifdef VSIP_IMPL_HAVE_SAL
+  Mercury_sal_tag,
+#endif
+#ifdef VSIP_IMPL_HAVE_LAPACK
+  Lapack_tag,
+#endif
+  None_type // None_type is treated specially by Make_type_list, it is
+            // not be put into the list.  Putting an explicit None_type
+            // at the end of the list lets us put a ',' after each impl
+            // tag.
+  >::type Lud_type_list;
+
+
+
 // a structure to chose implementation type
 template <typename T>
 struct Choose_lud_impl
 {
-
-#ifdef VSIP_IMPL_HAVE_SAL
-  typedef typename ITE_Type<Is_lud_impl_avail<Mercury_sal_tag, T>::value,
-                            As_type<Mercury_sal_tag>,
-			    As_type<Lapack_tag> >::type type;
-#else
-  typedef typename As_type<Lapack_tag>::type type;
-#endif
-                            
+  typedef typename Choose_solver_impl<
+    Is_lud_impl_avail,
+    T,
+    Lud_type_list>::type type;
+
+  typedef typename ITE_Type<
+    Type_equal<type, None_type>::value,
+    As_type<Error_no_solver_for_this_type>,
+    As_type<type> >::type use_type;
 };
 
 } // namespace impl
@@ -68,9 +87,10 @@
 
 template <typename T>
 class lud<T, by_reference>
-  : public impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::type>
+  : public impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::use_type>
 {
-  typedef impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::type> base_type;
+  typedef impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::use_type>
+	  base_type;
 
   // Constructors, copies, assignments, and destructors.
 public:
@@ -97,9 +117,10 @@
 
 template <typename T>
 class lud<T, by_value>
-  : public impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::type>
+  : public impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::use_type>
 {
-  typedef impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::type> base_type;
+  typedef impl::Lud_impl<T,typename impl::Choose_lud_impl<T>::use_type>
+	  base_type;
 
   // Constructors, copies, assignments, and destructors.
 public:
Index: src/vsip/impl/solver_common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver_common.hpp,v
retrieving revision 1.1
diff -u -r1.1 solver_common.hpp
--- src/vsip/impl/solver_common.hpp	14 Apr 2006 21:42:08 -0000	1.1
+++ src/vsip/impl/solver_common.hpp	2 May 2006 21:24:03 -0000
@@ -45,6 +45,9 @@
 // Implementation tags
 struct Lapack_tag;
 
+// Error tags
+struct Error_no_solver_for_this_type;
+
 
 } // namespace vsip::impl
 
@@ -55,6 +58,65 @@
   upper
 };
 
+
+
+namespace impl
+{
+
+/// Template class to determine which tag implements a solver.
+
+/// Requires:
+///   ISTYPEAVAIL to be a template class that, given an ImplTag and
+///      value type, defines VALUE to be true if ImplTag can solve
+///      value type, else false.
+///   T is a value type.
+///   TAGLIST is a list of implementation tags.
+///
+/// Provides:
+///   TYPE to be the first implementation tag from TAGLIST that supports
+///      value type T, else None_type.
+
+template <template <typename, typename> class IsTypeAvail,
+	  typename T,
+	  typename TagList,
+	  typename Tag  = typename TagList::first,
+	  typename Rest = typename TagList::rest,
+	  bool     Valid = IsTypeAvail<Tag, T>::value>
+struct Choose_solver_impl;
+
+/// Specialization for case where impl tag TAG supports type T.
+template <template <typename, typename> class IsTypeAvail,
+	  typename T,
+	  typename TagList,
+	  typename Tag,
+	  typename Rest>
+struct Choose_solver_impl<IsTypeAvail, T, TagList, Tag, Rest, true>
+{
+  typedef Tag type;
+};
+
+/// Specialization for case where impl tag TAG does not support type T.
+/// Fall through to next entry in TAGLIST.
+template <template <typename, typename> class IsTypeAvail,
+	  typename T,
+	  typename TagList,
+	  typename Tag,
+	  typename Rest>
+struct Choose_solver_impl<IsTypeAvail, T, TagList, Tag, Rest, false>
+  : Choose_solver_impl<IsTypeAvail, T, Rest>
+{};
+
+/// Terminator.  If REST is empty, define type to be None_type.
+template <template <typename, typename> class IsTypeAvail,
+	  typename T,
+	  typename TagList,
+	  typename Tag>
+struct Choose_solver_impl<IsTypeAvail, T, TagList, Tag, None_type, false>
+{
+  typedef None_type type;
+};
+
+} // namespace vsip::impl
 } // namespace vsip
 
 #endif
Index: src/vsip/impl/lapack/acml_cblas.hpp
===================================================================
RCS file: src/vsip/impl/lapack/acml_cblas.hpp
diff -N src/vsip/impl/lapack/acml_cblas.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/vsip/impl/lapack/acml_cblas.hpp	2 May 2006 21:24:03 -0000
@@ -0,0 +1,103 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/acml_cblas.hpp
+    @author  Jules Bergmann
+    @date    2005-08-19
+    @brief   VSIPL++ Library: ACML CBLAS wrappers.
+
+    ACML doesn't provide CBLAS bindings.  Also, its headers define a
+    complex type that is compatible with std::complex, but has the
+    same name.  This file provides CBLAS bindings to ACML.
+*/
+
+#ifndef VSIP_IMPL_ACML_CBLAS_HPP
+#define VSIP_IMPL_ACML_CBLAS_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+extern "C"
+{
+
+extern float sdot(int const n, float const *x, int const incx, float const *y, int const incy);
+extern double ddot(int const n, double const *x, int const incx, double const *y, int const incy);
+
+extern std::complex<float> cdotc(int const n, void const *x, int const incx, void const *y, int const incy);
+extern std::complex<float> cdotu(int const n, void const *x, int const incx, void const *y, int const incy);
+extern std::complex<double> zdotc(int const n, void const *x, int const incx, void const *y, int const incy);
+extern std::complex<double> zdotu(int const n, void const *x, int const incx, void const *y, int const incy);
+
+} // extern "C"
+
+float inline
+cblas_sdot(
+  const int    n,
+  const float* x,
+  const int    incx,
+  const float* y,
+  const int    incy)
+{
+  return sdot(n, x, incx, y, incy);
+}
+
+double inline
+cblas_ddot(
+  const int     n,
+  const double* x,
+  const int     incx,
+  const double* y,
+  const int     incy)
+{
+  return ddot(n, x, incx, y, incy);
+}
+
+void inline
+cblas_cdotu_sub(
+  int                 const  n,
+  void const* x,
+  int                 const  incx,
+  void const* y,
+  int                 const  incy,
+  void*       dotu)
+{
+  *reinterpret_cast<std::complex<float>*>(dotu) = cdotu(n, x, incx, y, incy);
+}
+
+void inline
+cblas_cdotc_sub(
+  int                 const  n,
+  void const* x,
+  int                 const  incx,
+  void const* y,
+  int                 const  incy,
+  void*       dotc)
+{
+  *reinterpret_cast<std::complex<float>*>(dotc) = cdotc(n, x, incx, y, incy);
+}
+
+void inline
+cblas_zdotu_sub(
+  int                  const  n,
+  void const* x,
+  int                  const  incx,
+  void const* y,
+  int                  const  incy,
+  void*       dotu)
+{
+  *reinterpret_cast<std::complex<double>*>(dotu) = zdotu(n, x, incx, y, incy);
+}
+
+void inline
+cblas_zdotc_sub(
+  int                  const  n,
+  void const* x,
+  int                  const  incx,
+  void const* y,
+  int                  const  incy,
+  void*       dotc)
+{
+  *reinterpret_cast<std::complex<double>*>(dotc) = zdotc(n, x, incx, y, incy);
+}
+
+#endif // VSIP_IMPL_ACML_CBLAS_HPP
Index: src/vsip/impl/lapack/solver_cholesky.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/lapack/solver_cholesky.hpp,v
retrieving revision 1.1
diff -u -r1.1 solver_cholesky.hpp
--- src/vsip/impl/lapack/solver_cholesky.hpp	14 Apr 2006 21:42:08 -0000	1.1
+++ src/vsip/impl/lapack/solver_cholesky.hpp	2 May 2006 21:24:03 -0000
@@ -34,6 +34,15 @@
 namespace impl
 {
 
+// The Lapack Cholesky solver supports all BLAS types.
+template <typename T>
+struct Is_chold_impl_avail<Lapack_tag, T>
+{
+  static bool const value = blas::Blas_traits<T>::valid;
+};
+
+
+
 /// Cholesky factorization implementation class.  Common functionality
 /// for chold by-value and by-reference classes.
 
Index: src/vsip/impl/lapack/solver_lu.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/lapack/solver_lu.hpp,v
retrieving revision 1.1
diff -u -r1.1 solver_lu.hpp
--- src/vsip/impl/lapack/solver_lu.hpp	14 Apr 2006 21:42:08 -0000	1.1
+++ src/vsip/impl/lapack/solver_lu.hpp	2 May 2006 21:24:03 -0000
@@ -35,6 +35,15 @@
 namespace impl
 {
 
+// The Lapack LU solver supports all BLAS types.
+template <typename T>
+struct Is_lud_impl_avail<Lapack_tag, T>
+{
+  static bool const value = blas::Blas_traits<T>::valid;
+};
+
+
+
 /// LU factorization implementation class.  Common functionality
 /// for lud by-value and by-reference classes.
 
Index: src/vsip/impl/sal/solver_cholesky.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/solver_cholesky.hpp,v
retrieving revision 1.1
diff -u -r1.1 solver_cholesky.hpp
--- src/vsip/impl/sal/solver_cholesky.hpp	14 Apr 2006 21:42:08 -0000	1.1
+++ src/vsip/impl/sal/solver_cholesky.hpp	2 May 2006 21:24:03 -0000
@@ -175,8 +175,8 @@
   length_type length
   )
 VSIP_THROW((std::bad_alloc))
-  : length_ (length),
-    uplo_   (uplo),
+  : uplo_   (uplo),
+    length_ (length),
     idv_    (length_),
     data_   (length_, length_)
 {
@@ -188,8 +188,8 @@
 template <typename T>
 Chold_impl<T,Mercury_sal_tag>::Chold_impl(Chold_impl const& qr)
 VSIP_THROW((std::bad_alloc))
-  : length_     (qr.length_),
-    uplo_       (qr.uplo_),
+  : uplo_       (qr.uplo_),
+    length_     (qr.length_),
     idv_        (length_),
     data_       (length_, length_)
 {
Index: tests/solver-cholesky.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-cholesky.cpp,v
retrieving revision 1.5
diff -u -r1.5 solver-cholesky.cpp
--- tests/solver-cholesky.cpp	10 Feb 2006 22:24:02 -0000	1.5
+++ tests/solver-cholesky.cpp	2 May 2006 21:24:03 -0000
@@ -343,8 +343,11 @@
 
 
 
+// Run Chold tests when type T is supported.
+// Called by chold_cases front-end function below.
+
 template <typename T>
-void chold_cases(mat_uplo uplo)
+void chold_cases(mat_uplo uplo, vsip::impl::Bool_type<true>)
 {
   for (index_type p=1; p<=3; ++p)
   {
@@ -384,6 +387,38 @@
 
 
 
+// Don't run Chold tests when type T is not supported.
+// Called by chold_cases front-end function below.
+
+template <typename T>
+void chold_cases(mat_uplo, vsip::impl::Bool_type<false>)
+{
+  // std::cout << "chold_cases " << Type_name<T>::name() << " not supported\n";
+}
+
+
+
+// Front-end function for chold_cases.
+
+// This function dispatches to either real set of tests or an empty
+// function depending on whether the Chold backends configured in support
+// value type T.  (Not all Chold backends support all value types).
+
+template <typename T>
+void chold_cases(mat_uplo uplo)
+{
+  using vsip::impl::Bool_type;
+  using vsip::impl::Type_equal;
+  using vsip::impl::Choose_chold_impl;
+  using vsip::impl::None_type;
+
+  chold_cases<T>(uplo,
+		 Bool_type<!Type_equal<typename Choose_chold_impl<T>::type,
+		                       None_type>::value>());
+}
+
+
+
 /***********************************************************************
   Main
 ***********************************************************************/
Index: tests/solver-lu.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-lu.cpp,v
retrieving revision 1.4
diff -u -r1.4 solver-lu.cpp
--- tests/solver-lu.cpp	10 Feb 2006 22:24:02 -0000	1.4
+++ tests/solver-lu.cpp	2 May 2006 21:24:03 -0000
@@ -30,7 +30,7 @@
 #define DO_BIG        1
 #define FILE_MATRIX_1 0
 
-#if VERBOSE || 1
+#if VERBOSE
 #  include <iostream>
 #  include "output.hpp"
 #  include "extdata-output.hpp"
@@ -417,8 +417,11 @@
 
 
 
+// Run LU tests when type T is supported.
+// Called by lud_cases front-end function below.
+
 template <typename T>
-void lud_cases(return_mechanism_type rtm)
+void lud_cases(return_mechanism_type rtm, vsip::impl::Bool_type<true>)
 {
   for (index_type p=1; p<=3; ++p)
   {
@@ -458,6 +461,38 @@
 
 
 
+// Don't run LU tests when type T is not supported.
+// Called by lud_cases front-end function below.
+
+template <typename T>
+void lud_cases(return_mechanism_type, vsip::impl::Bool_type<false>)
+{
+  // std::cout << "lud_cases " << Type_name<T>::name() << " not supported\n";
+}
+
+
+
+// Front-end function for lud_cases.
+
+// This function dispatches to either real set of tests or an empty
+// function depending on whether the LU backends configured in support
+// value type T.  (Not all LU backends support all value types).
+
+template <typename T>
+void lud_cases(return_mechanism_type rtm)
+{
+  using vsip::impl::Bool_type;
+  using vsip::impl::Type_equal;
+  using vsip::impl::Choose_lud_impl;
+  using vsip::impl::None_type;
+
+  lud_cases<T>(rtm,
+	       Bool_type<!Type_equal<typename Choose_lud_impl<T>::type,
+	                             None_type>::value>());
+}
+
+
+
 template <typename T>
 void
 dist_lud_cases()
