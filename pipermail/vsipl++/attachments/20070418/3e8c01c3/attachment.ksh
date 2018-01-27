Index: ChangeLog
===================================================================
--- ChangeLog	(revision 169070)
+++ ChangeLog	(working copy)
@@ -1,3 +1,17 @@
+2007-04-18  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Find -lippcore for IPP 5.1 ia32.
+	  (--enable-ref-impl): automatically disable lapack (--with-lapack=no).
+	  (--with-lapack=atlas_no_cblas): Use ATLAS without cblas.  Necessary
+	  to use Ubuntu 6.06 ATLAS.
+	  Update MKL/IPP handling for ia64.
+	* src/vsip/core/cvsip/fft.cpp (Fftm_impl): Fix number of rows/cols
+	  used for distributed Fftms.
+
+	* vendor/atlas/configure.ac: Handle unknown PowerPC architecture
+	  as G4.  Determine IA64 architecture mach type.  Distinguish
+	  between P4 and P4E mach types.  Improve pentium model check. 
+	
 2007-02-08  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/parallel/block.hpp: Include distributed_block.hpp
Index: configure.ac
===================================================================
--- configure.ac	(revision 169070)
+++ configure.ac	(working copy)
@@ -1450,7 +1450,10 @@
       ippi_search="ippi ippiem64t"
       ippm_search="ippm ippmem64t"
     else
-      ippcore_search="ippcore$with_ipp_suffix"
+      # Use of suffix not consistent:
+      #  - for em64t, ipp 5.0 has libippcoreem64t.so
+      #  - for ia32,  ipp 5.1 has libippcore.so
+      ippcore_search="ippcore ippcore$with_ipp_suffix"
       ipps_search="ipps$with_ipp_suffix"
       ippi_search="ippi$with_ipp_suffix"
       ippm_search="ippm$with_ipp_suffix"
@@ -1717,6 +1720,14 @@
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
@@ -1730,7 +1741,7 @@
   fi
   if test "$with_mkl_prefix" != ""; then
     if test "$already_prefix" = "1"; then
-      AC_MSG_ERROR([Multiple prefixes given for LAPACk libraries (i.e.
+      AC_MSG_ERROR([Multiple prefixes given for LAPACK libraries (i.e.
 		    MKL, ACML, and/or ATLAS])
     fi
     AC_MSG_RESULT([MKL prefixes specified, assume --with-lapack=mkl])
@@ -1763,6 +1774,8 @@
     if test "$with_mkl_arch" == "probe"; then
       if test "$host_cpu" == "x86_64"; then
         with_mkl_arch="em64t"
+      elif test "$host_cpu" == "ia64"; then
+        with_mkl_arch="64"
       else
         with_mkl_arch="32"
       fi
@@ -1847,7 +1860,7 @@
 
       lapack_use_ilaenv=0
     elif test "$trypkg" == "atlas"; then
-      AC_MSG_CHECKING([for LAPACK/ATLAS library])
+      AC_MSG_CHECKING([for LAPACK/ATLAS library (w/CBLAS])
 
       if test "$with_atlas_libdir" != ""; then
 	atlas_libdir=" -L$with_atlas_libdir"
@@ -1871,6 +1884,31 @@
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
@@ -2488,6 +2526,7 @@
 mkdir -p benchmarks/mpi
 mkdir -p benchmarks/ipp
 mkdir -p benchmarks/sal
+mkdir -p benchmarks/fftw3
 mkdir -p benchmarks/lapack
 
 AC_OUTPUT
Index: src/vsip/core/cvsip/fft.cpp
===================================================================
--- src/vsip/core/cvsip/fft.cpp	(revision 169070)
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
Index: vendor/atlas/configure.ac
===================================================================
--- vendor/atlas/configure.ac	(revision 169070)
+++ vendor/atlas/configure.ac	(working copy)
@@ -139,6 +139,7 @@
   mach="unknown"
 
   echo "linux arch $la"
+
   if test "$la" = "ppc"; then
     mach_is_ppc="true"
     model=`fgrep -m 1 cpu /proc/cpuinfo`
@@ -157,40 +158,72 @@
       mach="PPCG4"
     elif test "`echo $model | sed -n /PPC970FX/p`" != ""; then
       mach="PPCG5"
+    else
+      # Assume architecture is G4 (PPCG4).
+      # Pick G4 because we have architectural defaults for both
+      # with and without altivec.
+      AC_MSG_RESULT([Model '$model' not recognized for arch $la, assuming PowerPC g$])
+      mach="PPCG4"
     fi
-  fi
 
 	
   # SPARC
   # ALPHA
   # IA64
+  elif test "$la" = "ia64"; then
+    model=`fgrep -m 1 'family' /proc/cpuinfo`
+    if test "`echo $model | sed -n /Itanium 2/Ip`" != ""; then
+      mach="IA64Itan2"
+    else
+      mach="IA64Itan"
+    fi
   # X86
-  if test "$la" = "x86_32"; then
+  elif test "$la" = "x86_32"; then
     model=`fgrep -m 1 'model name' /proc/cpuinfo`
     if test "x$model" = "x"; then
       model=`fgrep -m 1 model /proc/cpuinfo`
     fi
 
-    if test "`echo $model | sed -n /Pentium/p`" != ""; then
-      if test "`echo $model | sed -n /III/p`" = "match"; then
+    if test "`echo $model | sed -n /Pentium/Ip`" != ""; then
+      if test "`echo $model | sed -n /III/Ip`" != ""; then
         mach="PIII"
-      elif test "`echo $model | sed -n '/ II/p'`" != ""; then
+      elif test "`echo $model | sed -n '/ II/Ip'`" != ""; then
         mach="PII"
-      elif test "`echo $model | sed -n '/Pro/p'`" != ""; then
+      elif test "`echo $model | sed -n '/Pro/Ip'`" != ""; then
         mach="PPRO"
-      elif test "`echo $model | sed -n '/MMX/p'`" != ""; then
+      elif test "`echo $model | sed -n '/MMX/Ip'`" != ""; then
         mach="P5MMX"
-      elif test "`echo $model | sed -n '/ 4 /p'`" != ""; then
+      elif test "`echo $model | sed -n '/ 4 /Ip'`" != ""; then
+        model_number=`fgrep -m 1 'model' /proc/cpuinfo | fgrep -v 'name'`
+	echo "MODEL_NUMBER: $model_number"
+        if test "`echo $model_number | sed -n '/3/Ip'`" != ""; then
+          mach="P4E"
+        elif test "`echo $model_number | sed -n '/4/Ip'`" != ""; then
+          mach="P4E"
+        else
+          mach="P4"
+        fi
+      elif test "`echo $model | sed -n '/ M /Ip'`" != ""; then
         mach="P4"
-      elif test "`echo $model | sed -n '/ M /p'`" != ""; then
+      fi
+    elif test "`echo $model | sed -n /Xeon/Ip`" != ""; then
+      model_number=`fgrep -m 1 'model' /proc/cpuinfo | fgrep -v 'name'`
+      echo "MODEL_NUMBER: $model_number"
+      if test "`echo $model_number | sed -n '/3/Ip'`" != ""; then
+        mach="P4E"
+      elif test "`echo $model_number | sed -n '/4/Ip'`" != ""; then
+        mach="P4E"
+      else
         mach="P4"
       fi
-    elif test "`echo $model | sed -n /XEON/p`" != ""; then
-      mach="P4"
-    elif test "`echo $model | sed -n '/Athlon/p'`" != ""; then
+    elif test "`echo $model | sed -n '/Athlon/Ip'`" != ""; then
       mach="ATHLON"
-    elif test "`echo $model | sed -n '/Opteron/p'`" != ""; then
+    elif test "`echo $model | sed -n '/Opteron/Ip'`" != ""; then
       mach="HAMMER32"
+    else
+      # Assume architecture is a Pentium (P5MMX)
+      AC_MSG_RESULT([Model '$model' not recognized for arch $la, assuming Pentium])
+      mach="P5MMX"
     fi
   elif test "$la" = "x86_64"; then
     model=`fgrep -m 1 'model name' /proc/cpuinfo`
@@ -281,7 +314,8 @@
 elif test "$mach_is_ppc" = "true"; then
   asmd="GAS_LINUX_PPC"
 else
-  AC_MSG_ERROR([cannot determine asm type.])
+  AC_MSG_RESULT([cannot determine asm type.])
+  asmd="none"
 fi
 
 AC_MSG_RESULT($asmd)
@@ -971,7 +1005,7 @@
       fi
       ;;
     PPCG4)
-      AC_MSG_ERROR([Linux/PPCG4 L2 cache size not implemented])
+      # AC_MSG_ERROR([Linux/PPCG4 L2 cache size not implemented])
       ;;
   esac
 elif test $os_name = "IRIX"; then
@@ -1376,6 +1410,11 @@
   ARCHDEFS="$ARCHDEFS -DATL_$asmd"
 fi
 
+case $mach in
+  IA64Itan | IA64Itan2 )
+    ARCHDEFS="$ARCHDEFS -DATL_MAXNREG=128"
+    ;;
+esac
 
 AC_SUBST(ARCHDEFS)
 
