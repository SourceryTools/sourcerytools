Index: ChangeLog
===================================================================
--- ChangeLog	(revision 166904)
+++ ChangeLog	(working copy)
@@ -1,7 +1,21 @@
 2007-03-26  Jules Bergmann  <jules@codesourcery.com>
 
+	* configure.ac: Find -lippcore for IPP 5.1 ia32.
+	  (--enable-ref-impl): automatically disable lapack (--with-lapack=no).
+	  (--with-lapack=atlas_no_cblas): Use ATLAS without cblas.  Necessary
+	  to use Ubuntu 6.06 ATLAS.
+	  Update MKL/IPP handling for ia64.
+	* src/vsip/core/cvsip/fft.cpp (Fftm_impl): Fix number of rows/cols
+	  used for distributed Fftms.
+	
+2007-03-26  Jules Bergmann  <jules@codesourcery.com>
+
 	* tests/regressions/vector_headers.cpp: New file, regression
 	  test for headers required to use a vector.
+	* tests/regressions/matrix_headers.cpp: New file, likewise for
+	  matrices.
+	* tests/regressions/tensor_headers.cpp: New file, likewise for
+	  tensors.
 
 2007-03-23  Don McCoy  <don@codesourcery.com>
 
Index: configure.ac
===================================================================
--- configure.ac	(revision 166223)
+++ configure.ac	(working copy)
@@ -1527,12 +1527,15 @@
   else
 
     if test "${with_ipp_suffix-unset}" == "unset"; then
-      ippcore_search="ippcore ippcoreem64t"
-      ipps_search="ipps ippsem64t"
-      ippi_search="ippi ippiem64t"
-      ippm_search="ippm ippmem64t"
+      ippcore_search="ippcore ippcoreem64t ippcore64"
+      ipps_search="ipps ippsem64t ipps64"
+      ippi_search="ippi ippiem64t ippi64"
+      ippm_search="ippm ippmem64t ippm64"
     else
-      ippcore_search="ippcore$with_ipp_suffix"
+      # Use of suffix not consistent:
+      #  - for em64t, ipp 5.0 has libippcoreem64t.so
+      #  - for ia32,  ipp 5.1 has libippcore.so
+      ippcore_search="ippcore ippcore$with_ipp_suffix"
       ipps_search="ipps$with_ipp_suffix"
       ippi_search="ippi$with_ipp_suffix"
       ippm_search="ippm$with_ipp_suffix"
@@ -1809,6 +1812,14 @@
   AC_MSG_RESULT([will use $use_g2c for libg2c.])
 fi
 
+# Disable lapack if building ref-impl
+if test "$ref_impl" = "1"; then
+  if test "$with_lapack" == "probe"; then
+    with_lapack="no"
+  else
+    AC_MSG_ERROR([Cannot use LAPACK with reference implementation.])
+  fi
+fi
 
 #
 # Check to see if any options have implied with_lapack
@@ -1822,7 +1833,7 @@
   fi
   if test "$with_mkl_prefix" != ""; then
     if test "$already_prefix" = "1"; then
-      AC_MSG_ERROR([Multiple prefixes given for LAPACk libraries (i.e.
+      AC_MSG_ERROR([Multiple prefixes given for LAPACK libraries (i.e.
 		    MKL, ACML, and/or ATLAS])
     fi
     AC_MSG_RESULT([MKL prefixes specified, assume --with-lapack=mkl])
@@ -1855,6 +1866,8 @@
     if test "$with_mkl_arch" == "probe"; then
       if test "$host_cpu" == "x86_64"; then
         with_mkl_arch="em64t"
+      elif test "$host_cpu" == "ia64"; then
+        with_mkl_arch="64"
       else
         with_mkl_arch="32"
       fi
@@ -1939,7 +1952,7 @@
 
       lapack_use_ilaenv=0
     elif test "$trypkg" == "atlas"; then
-      AC_MSG_CHECKING([for LAPACK/ATLAS library])
+      AC_MSG_CHECKING([for LAPACK/ATLAS library (w/CBLAS])
 
       if test "$with_atlas_libdir" != ""; then
 	atlas_libdir=" -L$with_atlas_libdir"
@@ -1963,6 +1976,31 @@
       fi
 
       lapack_use_ilaenv=0
+    elif test "$trypkg" == "atlas_no_cblas"; then
+      AC_MSG_CHECKING([for LAPACK/ATLAS library (w/o CBLAS)])
+
+      if test "$with_atlas_libdir" != ""; then
+	atlas_libdir=" -L$with_atlas_libdir"
+	atlas_incdir=""
+      elif test "$with_atlas_prefix" != ""; then
+	atlas_libdir=" -L$with_atlas_prefix/lib"
+	atlas_incdir=" -I$with_atlas_prefix/include"
+      else
+	atlas_libdir=""
+	atlas_incdir=""
+      fi
+
+      LDFLAGS="$keep_LDFLAGS$atlas_libdir"
+      CPPFLAGS="$keep_CPPFLAGS$atlas_incdir"
+      LIBS="$keep_LIBS -llapack -lf77blas -latlas $use_g2c"
+      cblas_style="0"	# no cblas.h
+
+      if test $use_g2c == "error"; then
+        AC_MSG_RESULT([skipping (g2c needed but not found)])
+	continue
+      fi
+
+      lapack_use_ilaenv=0
     elif test "$trypkg" == "generic1"; then
       AC_MSG_CHECKING([for LAPACK/Generic library (w/o blas)])
       LIBS="$keep_LIBS -llapack"
Index: src/vsip/core/cvsip/fft.cpp
===================================================================
--- src/vsip/core/cvsip/fft.cpp	(revision 166218)
+++ src/vsip/core/cvsip/fft.cpp	(working copy)
@@ -274,6 +274,9 @@
 			stride_type stride_r, stride_type stride_c,
 			length_type rows, length_type cols)
   {
+    // If the inputs to the Fftm are distributed, the number of FFTs may
+    // be less than mult_.
+    length_type const n_fft = (A == 1) ? rows : cols;
     stride_type vect_stride;
     stride_type elem_stride;
     length_type length = 0;
@@ -290,7 +293,7 @@
       length = cols;
     }
     View<1, ctype, false> output(length);
-    for (length_type i = 0; i != mult_; ++i)
+    for (length_type i = 0; i != n_fft; ++i)
     {
       View<1, ctype> input(inout, i * vect_stride, elem_stride, length);
       traits::call(impl_, input.ptr(), output.ptr());
@@ -302,6 +305,9 @@
 			stride_type stride_r, stride_type stride_c,
 			length_type rows, length_type cols)
   {
+    // If the inputs to the Fftm are distributed, the number of FFTs may
+    // be less than mult_.
+    length_type const n_fft = (A == 1) ? rows : cols;
     stride_type vect_stride;
     stride_type elem_stride;
     length_type length = 0;
@@ -318,7 +324,7 @@
       length = cols;
     }
     View<1, ctype, false> output(length);
-    for (length_type i = 0; i != mult_; ++i)
+    for (length_type i = 0; i != n_fft; ++i)
     {
       View<1, ctype> input(inout, i * vect_stride, elem_stride, length);
       traits::call(impl_, input.ptr(), output.ptr());
@@ -332,6 +338,9 @@
 			    stride_type out_stride_r, stride_type out_stride_c,
 			    length_type rows, length_type cols)
   {
+    // If the inputs to the Fftm are distributed, the number of FFTs may
+    // be less than mult_.
+    length_type const n_fft = (A == 1) ? rows : cols;
     stride_type in_vect_stride;
     stride_type in_elem_stride;
     stride_type out_vect_stride;
@@ -353,7 +362,7 @@
       out_elem_stride = out_stride_c;
       length = cols;
     }
-    for (length_type i = 0; i != mult_; ++i)
+    for (length_type i = 0; i != n_fft; ++i)
     {
       View<1, ctype> input(in, i * in_vect_stride, in_elem_stride, length);
       View<1, ctype> output(out, i * out_vect_stride, out_elem_stride, length);
@@ -366,6 +375,9 @@
 			    stride_type out_stride_r, stride_type out_stride_c,
 			    length_type rows, length_type cols)
   {
+    // If the inputs to the Fftm are distributed, the number of FFTs may
+    // be less than mult_.
+    length_type const n_fft = (A == 1) ? rows : cols;
     stride_type in_vect_stride;
     stride_type in_elem_stride;
     stride_type out_vect_stride;
@@ -387,7 +399,7 @@
       out_elem_stride = out_stride_c;
       length = cols;
     }
-    for (length_type i = 0; i != mult_; ++i)
+    for (length_type i = 0; i != n_fft; ++i)
     {
       View<1, ctype> input(in, i * in_vect_stride, out_elem_stride, length);
       View<1, ctype> output(out, i * out_vect_stride, out_elem_stride, length);
@@ -423,6 +435,9 @@
 			    stride_type out_stride_r, stride_type out_stride_c,
 			    length_type rows, length_type cols)
   {
+    // If the inputs to the Fftm are distributed, the number of FFTs may
+    // be less than mult_.
+    length_type const n_fft = (A == 1) ? rows : cols;
     stride_type in_vect_stride;
     stride_type in_elem_stride;
     stride_type out_vect_stride;
@@ -444,7 +459,7 @@
       out_elem_stride = out_stride_c;
       length = cols;
     }
-    for (length_type i = 0; i != mult_; ++i)
+    for (length_type i = 0; i != n_fft; ++i)
     {
       View<1, rtype> input(in, i * in_vect_stride, in_elem_stride, length);
       View<1, ctype> output(out, i * out_vect_stride, out_elem_stride, length/2+1);
@@ -457,6 +472,9 @@
 			    stride_type out_stride_r, stride_type out_stride_c,
 			    length_type rows, length_type cols)
   {
+    // If the inputs to the Fftm are distributed, the number of FFTs may
+    // be less than mult_.
+    length_type const n_fft = (A == 1) ? rows : cols;
     stride_type in_vect_stride;
     stride_type in_elem_stride;
     stride_type out_vect_stride;
@@ -478,7 +496,7 @@
       out_elem_stride = out_stride_c;
       length = cols;
     }
-    for (length_type i = 0; i != mult_; ++i)
+    for (length_type i = 0; i != n_fft; ++i)
     {
       View<1, rtype> input(in, i * in_vect_stride, in_elem_stride, length);
       View<1, ctype> output(out, i * out_vect_stride, out_elem_stride, length/2+1);
@@ -514,6 +532,9 @@
 			    stride_type out_stride_r, stride_type out_stride_c,
 			    length_type rows, length_type cols)
   {
+    // If the inputs to the Fftm are distributed, the number of FFTs may
+    // be less than mult_.
+    length_type const n_fft = (A == 1) ? rows : cols;
     stride_type in_vect_stride;
     stride_type in_elem_stride;
     stride_type out_vect_stride;
@@ -535,7 +556,7 @@
       out_elem_stride = out_stride_c;
       length = cols;
     }
-    for (length_type i = 0; i != mult_; ++i)
+    for (length_type i = 0; i != n_fft; ++i)
     {
       View<1, ctype> input(in, i * in_vect_stride, in_elem_stride, length/2+1);
       View<1, rtype> output(out, i * out_vect_stride, out_elem_stride, length);
@@ -548,6 +569,9 @@
 			    stride_type out_stride_r, stride_type out_stride_c,
 			    length_type rows, length_type cols)
   {
+    // If the inputs to the Fftm are distributed, the number of FFTs may
+    // be less than mult_.
+    length_type const n_fft = (A == 1) ? rows : cols;
     stride_type in_vect_stride;
     stride_type in_elem_stride;
     stride_type out_vect_stride;
@@ -569,7 +593,7 @@
       out_elem_stride = out_stride_c;
       length = cols;
     }
-    for (length_type i = 0; i != mult_; ++i)
+    for (length_type i = 0; i != n_fft; ++i)
     {
       View<1, ctype> input(in, i * in_vect_stride, in_elem_stride, length/2+1);
       View<1, rtype> output(out, i * out_vect_stride, out_elem_stride, length);
Index: tests/regressions/matrix_headers.cpp
===================================================================
--- tests/regressions/matrix_headers.cpp	(revision 0)
+++ tests/regressions/matrix_headers.cpp	(revision 0)
@@ -0,0 +1,41 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/matrix_header.cpp
+    @author  Jules Bergmann
+    @date    2007-03-26
+    @brief   VSIPL++ Library: Test that matrix.hpp header is sufficient
+                              to use a Matrix.
+
+    This is requires that Local_or_global_map be defined.  However,
+    global_map.hpp (and map.hpp) cannot be included until after the
+    definitions for Matrix are made.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/matrix.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+   vsip::vsipl(argc, argv);
+
+   vsip::Matrix<float> foo(5, 7, 3.f);
+   vsip::Matrix<float> bar(5, 7, 4.f);
+
+   bar *= foo;
+}
Index: tests/regressions/tensor_headers.cpp
===================================================================
--- tests/regressions/tensor_headers.cpp	(revision 0)
+++ tests/regressions/tensor_headers.cpp	(revision 0)
@@ -0,0 +1,41 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/tensor_header.cpp
+    @author  Jules Bergmann
+    @date    2007-03-26
+    @brief   VSIPL++ Library: Test that tensor.hpp header is sufficient
+                              to use a Tensor.
+
+    This is requires that Local_or_global_map be defined.  However,
+    global_map.hpp (and map.hpp) cannot be included until after the
+    definitions for Tensor are made.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/tensor.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+   vsip::vsipl(argc, argv);
+
+   vsip::Tensor<float> foo(3, 5, 7, 3.f);
+   vsip::Tensor<float> bar(3, 5, 7, 4.f);
+
+   bar *= foo;
+}
Index: tests/make.standalone
===================================================================
--- tests/make.standalone	(revision 166218)
+++ tests/make.standalone	(working copy)
@@ -52,7 +52,7 @@
 # Variables in this section should not be modified.
 
 # Logic to call pkg-config with PREFIX, if specified.
-ifdef $PREFIX
+ifneq ($(PREFIX),)
    PC    = env PKG_CONFIG_PATH=$(PREFIX)/lib/pkgconfig \
 	   pkg-config --define-variable=prefix=$(PREFIX) $(PKG)
 else
