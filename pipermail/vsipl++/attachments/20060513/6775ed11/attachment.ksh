Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.478
diff -u -r1.478 ChangeLog
--- ChangeLog	13 May 2006 23:19:34 -0000	1.478
+++ ChangeLog	14 May 2006 02:17:11 -0000
@@ -1,3 +1,31 @@
+2006-05-13  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac: Check if long double is supported before attempting
+	  to configure builtin FFT with long doule.  Add missing export
+	  for --with-fftw3-cflags..
+	* doc/quickstart/quickstart.xml: Bump version to 1.1.  Update
+	  Mercury configuration section.
+	* examples/mercury/mcoe-setup.sh: Update to include test levels
+	  and FFT backends.
+	* scripts/config: Prefer -march to -mtune for binary packages
+	  (other than 32-bit generic).
+	* src/vsip/impl/layout.hpp: Improve runtime layout efficiency.
+	* src/vsip/impl/rt_extdata.hpp: Improve runtime layout efficiency.
+	* src/vsip/impl/fftw3/fft.cpp: Use VSIP_IMPL_USE_<type> macros
+	  to determine types provided by FFTW3. 
+	* src/vsip/impl/fftw3/fft_impl.cpp: Use VSIP_IMPL_THROW.
+	* src/vsip/impl/sal/solver_qr.hpp: Add missing member initializer
+	  for copy constructor.
+
+	* src/vsip/impl/expr_serial_dispatch.hpp: Remove include of iostream.
+	* src/vsip/impl/sal.hpp: Likewise.
+	* src/vsip/impl/fft/util.hpp: Likewise.
+	* src/vsip/impl/fft/workspace.hpp: Likewise.
+	
+	* benchmarks/fft.cpp: Add cases with different Fft NumberOfTimes
+	  template parameter.
+	* benchmarks/fftm.cpp: Move NumberOfTimes to global.
+	
 2006-05-13  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* src/vsip/impl/fftw3/fft.hpp: Fix signature of forward-declared create()
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.103
diff -u -r1.103 configure.ac
--- configure.ac	13 May 2006 18:04:53 -0000	1.103
+++ configure.ac	14 May 2006 02:17:11 -0000
@@ -151,7 +151,7 @@
 AC_ARG_WITH(fftw3_cflags,
   AS_HELP_STRING([--with-fftw3-cflags=CFLAGS],
                  [Specify CFLAGS to use when building built-inFFTW3.
-		  Only used if --with-fft=buildint.]))
+		  Only used if --with-fft=builtin.]))
 
 # LAPACK and related libraries (Intel MKL)
 
@@ -607,6 +607,23 @@
 
     # assert(NOT CROSS-COMPILING)
 
+    # Determine whether long double is supported.
+    AC_CHECK_SIZEOF(double)
+    AC_CHECK_SIZEOF(long double)
+    AC_MSG_CHECKING([for long double support])
+    if test $ac_cv_sizeof_long_double = 0; then
+      AC_MSG_RESULT([not a supported type.])
+      AC_MSG_NOTICE([Disabling FFT support (--disable-fft-long-double).])
+      enable_fft_long_double=no 
+    elif test $ac_cv_sizeof_long_double = $ac_cv_sizeof_double; then
+      AC_MSG_RESULT([same size as double.])
+      AC_MSG_NOTICE([Disabling FFT support (--disable-fft-long-double).])
+      enable_fft_long_double=no 
+    else
+      AC_MSG_RESULT([supported.])
+    fi
+
+
     # if $srcdir is relative, correct for chdir into vendor/fftw3*.
     fftw3_configure="`(cd $srcdir/vendor/fftw; echo \"$PWD\")`"/configure
 
@@ -647,7 +664,7 @@
     keep_CFLAGS="$CFLAGS"
 
     if test "x$with_fftw3_cflags" != "x"; then
-      CFLAGS="$with_fftw3_cflags"
+      export CFLAGS="$with_fftw3_cflags"
     else
       unset CFLAGS
     fi
Index: benchmarks/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/fft.cpp,v
retrieving revision 1.5
diff -u -r1.5 fft.cpp
--- benchmarks/fft.cpp	12 Apr 2006 18:51:18 -0000	1.5
+++ benchmarks/fft.cpp	14 May 2006 02:17:11 -0000
@@ -30,7 +30,8 @@
 }
 
 
-template <typename T>
+template <typename T,
+	  int      no_times>
 struct t_fft_op
 {
   char* what() { return "t_fft_op"; }
@@ -44,9 +45,6 @@
     Vector<T>   A(size, T());
     Vector<T>   Z(size);
 
-    // int const no_times = 0; // FFTW_PATIENT
-    int const no_times = 15; // not > 12 = FFT_MEASURE
-
     typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times, alg_time>
       fft_type;
 
@@ -78,7 +76,8 @@
 
 
 
-template <typename T>
+template <typename T,
+	  int      no_times>
 struct t_fft_ip
 {
   char* what() { return "t_fft_ip"; }
@@ -91,9 +90,6 @@
   {
     Vector<T>   A(size, T(0));
 
-    // int const no_times = 0; // FFTW_PATIENT
-    int const no_times = 15; // not > 12 = FFT_MEASURE
-
     typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times, alg_time>
       fft_type;
 
@@ -134,13 +130,27 @@
 int
 test(Loop1P& loop, int what)
 {
+  int const estimate = 1;  // FFT_ESTIMATE
+  int const measure  = 15; // FFT_MEASURE (no_times > 12)
+  int const patient  = 0;  // FFTW_PATIENT
+
   switch (what)
   {
-  case  1: loop(t_fft_op<complex<float> >(false)); break;
-  case  2: loop(t_fft_ip<complex<float> >(false)); break;
+  case  1: loop(t_fft_op<complex<float>, estimate>(false)); break;
+  case  2: loop(t_fft_ip<complex<float>, estimate>(false)); break;
+  case  5: loop(t_fft_op<complex<float>, estimate>(true)); break;
+  case  6: loop(t_fft_ip<complex<float>, estimate>(true)); break;
+
+  case 11: loop(t_fft_op<complex<float>, measure>(false)); break;
+  case 12: loop(t_fft_ip<complex<float>, measure>(false)); break;
+  case 15: loop(t_fft_op<complex<float>, measure>(true)); break;
+  case 16: loop(t_fft_ip<complex<float>, measure>(true)); break;
+
+  case 21: loop(t_fft_op<complex<float>, patient>(false)); break;
+  case 22: loop(t_fft_ip<complex<float>, patient>(false)); break;
+  case 25: loop(t_fft_op<complex<float>, patient>(true)); break;
+  case 26: loop(t_fft_ip<complex<float>, patient>(true)); break;
 
-  case  5: loop(t_fft_op<complex<float> >(true)); break;
-  case  6: loop(t_fft_ip<complex<float> >(true)); break;
   default: return 0;
   }
   return 1;
Index: benchmarks/fftm.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/fftm.cpp,v
retrieving revision 1.2
diff -u -r1.2 fftm.cpp
--- benchmarks/fftm.cpp	7 Mar 2006 20:09:35 -0000	1.2
+++ benchmarks/fftm.cpp	14 May 2006 02:17:11 -0000
@@ -30,6 +30,16 @@
   Definitions
 ***********************************************************************/
 
+// Number of times.  Parameter to Fftm.
+//  1 - 12       - FFTW3 backend uses FFTW_ESTIMATE
+//  12 +         - FFTW3 backend uses FFTW_MEASURE
+//  0 (infinite) - FFTW3 backend uses FFTW_PATIENT (slow for big sizes)
+//
+// Turns out that FFTW_ESTIMATE is nearly as good as MEASURE and PATIENT.
+int const no_times = 1;
+
+
+
 int
 fft_ops(length_type len)
 {
@@ -69,9 +79,6 @@
     Matrix<T>   A(rows, cols, T());
     Matrix<T>   Z(rows, cols);
 
-    // int const no_times = 0; // FFTW_PATIENT
-    int const no_times = 15; // not > 12 = FFT_MEASURE
-
     typedef Fftm<T, T, SD, fft_fwd, by_reference, no_times, alg_time>
       fftm_type;
 
@@ -116,9 +123,6 @@
   {
     Matrix<T>   A(rows, cols, T());
 
-    // int const no_times = 0; // FFTW_PATIENT
-    int const no_times = 15; // not > 12 = FFT_MEASURE
-
     typedef Fftm<T, T, SD, fft_fwd, by_reference, no_times, alg_time>
       fftm_type;
 
@@ -166,9 +170,6 @@
   {
     Matrix<T>   A(rows, cols, T());
 
-    // int const no_times = 0; // FFTW_PATIENT
-    int const no_times = 15; // not > 12 = FFT_MEASURE
-
     typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times, alg_time>
       fft_type;
 
@@ -216,7 +217,7 @@
 
 
 /***********************************************************************
-  Impl_pip2: Pseudo In-place Fftm (using in-place Fft)
+  Impl_pip2: Pseudo In-place Fftm (using out-of-place Fft)
 ***********************************************************************/
 
 template <typename T,
@@ -234,9 +235,6 @@
     Matrix<T>   A(rows, cols, T());
     Vector<T>   tmp(SD == row ? cols : rows);
 
-    // int const no_times = 0; // FFTW_PATIENT
-    int const no_times = 15; // not > 12 = FFT_MEASURE
-
     typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times, alg_time>
       fft_type;
 
Index: doc/quickstart/quickstart.xml
===================================================================
RCS file: /home/cvs/Repository/vpp/doc/quickstart/quickstart.xml,v
retrieving revision 1.30
diff -u -r1.30 quickstart.xml
--- doc/quickstart/quickstart.xml	12 May 2006 02:48:45 -0000	1.30
+++ doc/quickstart/quickstart.xml	14 May 2006 02:17:11 -0000
@@ -16,7 +16,7 @@
  <!ENTITY specification
   "<ulink url=&#34;http://www.codesourcery.com/public/vsiplplusplus/specification-1.0.pdf&#34;
     >VSIPL++ API specification</ulink>">
- <!ENTITY version "1.1 (prerelease)">
+ <!ENTITY version "1.1">
 ]>
 
 <book>
@@ -1053,9 +1053,9 @@
     <title>Configuration Notes for Mercury Systems</title>
 
     <para>
-     When configuring Sourcery VSIPL++ to for a Mercury
+     When configuring Sourcery VSIPL++ for a Mercury
      PowerPC system, the following environment variables
-     and configuration flags recommended:
+     and configuration flags are recommended:
      <itemizedlist>
 
       <listitem>
@@ -1067,6 +1067,31 @@
       </listitem>
 
       <listitem>
+       <para><option>CC=ccmc</option></para>
+       <para>
+	This selects the <option>ccmc</option> cross compiler as the
+        C compiler.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>AR=armc</option></para>
+       <para>
+	This selects the <option>armc</option> archiver.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>AR_FLAGS=cr</option></para>
+       <para>
+	This selects the <option>c</option> (create archive if it
+	does not exist) and <option>r</option> (replace files in
+	archive) flags for the <program>armc</program> archiver.
+	<program>armc</program> does not support the <option>u</option>
+	(only replace files if they are an update).
+      </listitem>
+
+      <listitem>
        <para><option>CXXFLAGS="--no_explicit_include -Ospeed -Onotailrecursion -t <replaceable>architecture</replaceable> --no_exceptions -DNDEBUG --diag_suppress 177,550</option></para>
        <para>
         These are the recommended flags for compiling Sourcery VSIPL++
@@ -1202,9 +1227,23 @@
       </listitem>
 
       <listitem>
-       <para><option>--with-fft=sal</option></para>
+       <para><option>--enable-fft=sal,builtin</option></para>
+       <para>
+        Use SAL and Sourcery VSIPL++ builtin FFTW3 to perform FFT
+        operations.  SAL FFT will be used for FFTs with power-of-two
+	sizes, FFTW3 will be used otherwise.
+       </para>
+      </listitem>
+
+      <listitem>
+       <para><option>--with-fftw3-cflags="-O2"</option></para>
        <para>
-        Use SAL to perform FFT operations.
+        Compile Sourcery VSIPL++'s builtin FFTW3 library with
+	optimization level <option>-O2</option>.  (Compiling
+	FFTW3 with optimization level <option>-O3</option>
+	produces link-errors with GreenHills C related to the
+	handling of static functions.  CodeSourcery is currently
+	developing a work-around for this.)
        </para>
       </listitem>
 
Index: examples/mercury/mcoe-setup.sh
===================================================================
RCS file: /home/cvs/Repository/vpp/examples/mercury/mcoe-setup.sh,v
retrieving revision 1.2
diff -u -r1.2 mcoe-setup.sh
--- examples/mercury/mcoe-setup.sh	22 Mar 2006 20:48:58 -0000	1.2
+++ examples/mercury/mcoe-setup.sh	14 May 2006 02:17:11 -0000
@@ -10,22 +10,79 @@
 #########################################################################
 # Instructions:
 #  - Modify flags below to control where and how VSIPL++ is built.
-#  - Run setup.sh
+#  - Run mcoe-setup.sh
 #  - Run 'make'
 #  - Run 'make install'
+#
+#    Flags can either be uncommented and edited below, or placed in a
+#    separate file that sources this one.
+#
+# Flags:
+#
+#   dir="."			# Sourcery VSIPL++ source directory.
+#   comm="ser"			# set to (ser)ial or (par)allel.
+#   fmt="inter"			# set to (inter)leaved or (split).
+#   opt="y"			# (y) for optimized flags, (n) for debug flags.
+#   pflags="-t ppc7400_le"	# processor architecture
+#   fft="sal,builtin"		# FFT backend(s)
+#   testlevel="0"		# Test level
+#   prefix="/opt/vsipl++"	# Installation prefix.
+#
 #########################################################################
 
-# Set 'dir' the directory containing SourceryVSIPL++
-dir="."
-# dir=$HOME/sourceryvsipl++-1.0
-
-comm="ser"		# set to (ser)ial or (par)allel.
-fmt="inter"		# set to (inter)leaved or (split).
-opt="y"			# (y) for optimized flags, (n) for debug flags.
-pflags="-t ppc7400_le"	# processor architecture
+# 'dir' is the directory containing SourceryVSIPL++
+if test "x$dir" = x; then
+  dir="."
+fi
+
+if test "x$comm" = x; then
+  comm="ser"			# set to (ser)ial or (par)allel.
+fi
+
+if test "x$fmt" = x; then
+  fmt="inter"			# set to (inter)leaved or (split).
+fi
+
+if test "x$opt" = x; then
+  opt="y"			# (y) for optimized flags, (n) for debug flags.
+fi
+
+if test "x$pflags" = x; then
+  pflags="-t ppc7400_le"	# processor architecture
+fi
+
+
+# FFT backend.  This controls which backend or backends are used for
+# FFTs.
+#
+# Possible Values:
+#   sal,builtin	- Use SAL and builtin Sourcery VSIPL++ FFTW3 (recommended).
+#   sal,fftw3	- Use SAL and pre-built FFTW3.
+#   sal		- Use SAL only (only power-of-2 sizes are supported).
+
+if test "x$fft" = x; then
+  fft="sal,builtin"	# FFT backend.
+fi
+
+
+# Test level.  This controls how hard Sourcery VSIPL++'s test-suite
+# tries to test the system.
+#
+# Values:
+#   0 - low-level (avoids long-running and long-compiling tests).
+#   1 - default
+#   2 - high-level (enables additional long-running tests).
+
+if test "x$testlevel" = x; then
+  testlevel="0"		# Test level
+fi
+
+
 
 # Set 'prefix' the directory where SourceryVSIPL++ Should be installed
-prefix="/opt/sourcery-vsipl++"
+if test "x$prefix" = x; then
+  prefix="/opt/sourcery-vsipl++"
+fi
 
 
 
@@ -45,16 +102,24 @@
   cxxflags="$base -g"
 fi
 
+
+export CC=ccmc
 export CXX=ccmc++
 export CXXFLAGS=$cxxflags
+export AR=armc
+export AR_FLAGS=cr		# armc doesn't support 'u'pdate
 export LDFLAGS="$pflags"
 
+
+echo "$dir/configure"
 $dir/configure					\
 	--prefix=$prefix			\
 	--host=powerpc				\
 	--enable-sal				\
-	--with-fft=sal				\
+	--enable-fft=$fft			\
+	--with-fftw3-cflags="-O2"		\
 	--with-complex=$fmt			\
 	--disable-exceptions			\
 	$par_opt				\
+	--with-test-level=$testlevel		\
 	--enable-profile-timer=realtime
Index: scripts/config
===================================================================
RCS file: /home/cvs/Repository/vpp/scripts/config,v
retrieving revision 1.14
diff -u -r1.14 config
--- scripts/config	10 May 2006 14:08:52 -0000	1.14
+++ scripts/config	14 May 2006 02:17:11 -0000
@@ -58,11 +58,11 @@
 
 m32 = ['-m32']
 flags_32_generic = ['-m32', '-mtune=pentium4']
-flags_32_p4sse2  = ['-m32', '-mtune=pentium4', '-mmmx', '-msse', '-msse2']
-flags_64_generic = ['-m64', '-mtune=nocona',   '-mmmx', '-msse', '-msse2']
-flags_64_em64t   = ['-m64', '-mtune=nocona',   '-mmmx', '-msse', '-msse2',
+flags_32_p4sse2  = ['-m32', '-march=pentium4', '-mmmx', '-msse', '-msse2']
+flags_64_generic = ['-m64', '-march=nocona',   '-mmmx', '-msse', '-msse2']
+flags_64_em64t   = ['-m64', '-march=nocona',   '-mmmx', '-msse', '-msse2',
                                                '-msse3']
-flags_64_amd64   = ['-m64', '-mtune=opteron',  '-mmmx', '-msse', '-msse2',
+flags_64_amd64   = ['-m64', '-march=opteron',  '-mmmx', '-msse', '-msse2',
                                                '-m3dnow']
 
 
Index: src/vsip/impl/expr_serial_dispatch.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_serial_dispatch.hpp,v
retrieving revision 1.4
diff -u -r1.4 expr_serial_dispatch.hpp
--- src/vsip/impl/expr_serial_dispatch.hpp	3 Mar 2006 14:30:53 -0000	1.4
+++ src/vsip/impl/expr_serial_dispatch.hpp	14 May 2006 02:17:11 -0000
@@ -31,7 +31,7 @@
 #  include <vsip/impl/simd/eval-simd-3dnowext.hpp>
 #endif
 
-#include <iostream>
+
 
 /***********************************************************************
   Declarations
Index: src/vsip/impl/layout.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/layout.hpp,v
retrieving revision 1.22
diff -u -r1.22 layout.hpp
--- src/vsip/impl/layout.hpp	10 May 2006 02:54:09 -0000	1.22
+++ src/vsip/impl/layout.hpp	14 May 2006 02:17:11 -0000
@@ -21,8 +21,6 @@
 #include <vsip/impl/metaprogramming.hpp>
 
 
-using vsip::Index;
-
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -33,6 +31,14 @@
 namespace impl
 {
 
+/// Enum to indicate that an Applied_layout or Rt_layout object
+/// will not be used and therefor should not be initialized when
+/// constructed.
+
+enum empty_layout_type { empty_layout };
+
+
+
 /// Class to represent either a interleaved-pointer or a split-pointer.
 
 /// Primary definition handles non-complex types.  Functions
@@ -285,12 +291,31 @@
 template <dimension_type Dim>
 struct Rt_layout
 {
+  // Dimension is fixed at compile-time.
   static dimension_type const dim = Dim;
 
+  // Run-time layout.
   rt_pack_type      pack;
   Rt_tuple          order;
   rt_complex_type   complex;
   unsigned          align;	// Only valid if pack == stride_unit_align
+
+
+  // Construct an empty Rt_layout object.
+  Rt_layout() {}
+
+  Rt_layout(
+    rt_pack_type    a_pack,
+    Rt_tuple const& a_order,
+    rt_complex_type a_complex,
+    unsigned        a_align)
+  : pack    (a_pack),
+    order   (a_order),
+    complex (a_complex),
+    align   (a_align)
+  {}
+
+
 };
 
 
@@ -872,6 +897,12 @@
 
 /// Applied run-time layout.
 
+/// This object gets created for run-time extdata access.
+///
+/// Efficiency is important to reduce library interface overhead.
+///  - Don't store the whole Rt_layout, only the parts we need:
+///    the complex_format and part of the dimension-order.
+
 template <dimension_type Dim>
 class Applied_layout<Rt_layout<Dim> >
 {
@@ -879,6 +910,9 @@
   static dimension_type const dim = Dim;
 
 public:
+  // Construct an empty Applied_layout.  Used when it is known that object
+  // will not be used.
+  Applied_layout(empty_layout_type) {}
 
   // Construct Applied_layout object.
   //
@@ -891,39 +925,48 @@
     Rt_layout<Dim> const& layout,
     Length<Dim> const&    extent,
     length_type           elem_size = 1)
-    : layout_(layout)
+  : cformat_(layout.complex)
   {
-    assert(layout_.align == 0 || layout_.align % elem_size == 0);
+    assert(layout.align == 0 || layout.align % elem_size == 0);
 
     for (dimension_type d=0; d<Dim; ++d)
       size_[d] = extent[d];
 
     if (Dim == 3)
     {
-      stride_[layout_.order.impl_dim2] = 1;
-      stride_[layout_.order.impl_dim1] = size_[layout_.order.impl_dim2];
-      if (layout_.align != 0 &&
-	  (elem_size*stride_[layout_.order.impl_dim1]) % layout_.align != 0)
-	stride_[layout_.order.impl_dim1] +=
-	  (layout_.align/elem_size -
-	   stride_[layout_.order.impl_dim1]%layout_.align);
-      stride_[layout_.order.impl_dim0] = size_[layout_.order.impl_dim1] *
-	                                 stride_[layout_.order.impl_dim1];
+      order_[2] = layout.order.impl_dim2;
+      order_[1] = layout.order.impl_dim1;
+      order_[0] = layout.order.impl_dim0;
+
+      stride_[order_[2]] = 1;
+      stride_[order_[1]] = size_[order_[2]];
+      if (layout.align != 0 &&
+	  (elem_size*stride_[order_[1]]) % layout.align != 0)
+	stride_[order_[1]] +=
+	  (layout.align/elem_size -
+	   stride_[order_[1]]%layout.align);
+      stride_[order_[0]] = size_[order_[1]] * stride_[order_[1]];
     }
     else if (Dim == 2)
     {
-      stride_[layout_.order.impl_dim1] = 1;
-      stride_[layout_.order.impl_dim0] = size_[layout_.order.impl_dim1];
-
-      if (layout_.align != 0 &&
-	  (elem_size*stride_[layout_.order.impl_dim0]) % layout_.align != 0)
-	stride_[layout_.order.impl_dim0] +=
-	  (layout_.align/elem_size -
-	   stride_[layout_.order.impl_dim0]%layout_.align);
+      // Copy only the portion of the dimension-order that we use.
+      order_[1] = layout.order.impl_dim1;
+      order_[0] = layout.order.impl_dim0;
+
+      stride_[order_[1]] = 1;
+      stride_[order_[0]] = size_[order_[1]];
+
+      if (layout.align != 0 &&
+	  (elem_size*stride_[order_[1]]) % layout.align != 0)
+	stride_[order_[0]] +=
+	  (layout.align/elem_size - stride_[order_[0]]%layout.align);
     }
     else  // (Dim == 1)
     {
-      stride_[layout_.order.impl_dim0] = 1;
+      // Copy only the portion of the dimension-order that we use.
+      order_[0] = layout.order.impl_dim0;
+
+      stride_[0] = 1;
     }
   }
 
@@ -933,15 +976,15 @@
     if (Dim == 3)
     {
       assert(idx[0] < size_[0] && idx[1] < size_[1] && idx[2] < size_[2]);
-      return idx[layout_.order.impl_dim0]*stride_[layout_.order.impl_dim0] +
-	     idx[layout_.order.impl_dim1]*stride_[layout_.order.impl_dim1] + 
-	     idx[layout_.order.impl_dim2];
+      return idx[order_[0]]*stride_[order_[0]] +
+	     idx[order_[1]]*stride_[order_[1]] + 
+	     idx[order_[2]];
     }
     else if (Dim == 2)
     {
       assert(idx[0] < size_[0] && idx[1] < size_[1]);
-      return idx[layout_.order.impl_dim0]*stride_[layout_.order.impl_dim0] +
-	     idx[layout_.order.impl_dim1];
+      return idx[order_[0]]*stride_[order_[0]] +
+	     idx[order_[1]];
     }
     else // (Dim == 1)
     {
@@ -962,13 +1005,15 @@
 
   length_type total_size()
     const VSIP_NOTHROW
-  { return size_[layout_.order.impl_dim0] * stride_[layout_.order.impl_dim0]; }
+  { return size_[order_[0]] * stride_[order_[0]]; }
 
 public:
-  Rt_layout<Dim> const layout_;
+  rt_complex_type cformat_;
+
 private:
-  length_type size_  [Dim];
-  stride_type stride_[Dim];
+  dimension_type order_ [Dim];
+  length_type    size_  [Dim];
+  stride_type    stride_[Dim];
 };
 
 
@@ -1201,8 +1246,7 @@
 
 // Allocated storage, with complex format determined at run-time.
 
-template <typename T,
-	  typename AllocT = vsip::impl::Aligned_allocator<T> >
+template <typename T>
 class Rt_allocated_storage
 {
   // Compile-time values and types.
@@ -1225,9 +1269,8 @@
   // Constructors and destructor.
 public:
   static Rt_pointer<T> allocate_(
-    AllocT const&   /*arg_alloc*/,
-    length_type     size,
-    rt_complex_type cformat)
+    rt_complex_type cformat,
+    length_type     size)
   {
     if (!Is_complex<T>::value || cformat == cmplx_inter_fmt)
     {
@@ -1245,8 +1288,8 @@
   static void deallocate_(
     Rt_pointer<T>   ptr,
     rt_complex_type cformat,
-    length_type     /*size*/,
-    AllocT const&   /*arg_alloc*/)
+    length_type     /*size*/
+    )
   {
     if (cformat == cmplx_inter_fmt)
     {
@@ -1288,17 +1331,20 @@
     }
   }
 
+  // Fast-path Constructor for unused object.
+  Rt_allocated_storage(empty_layout_type)
+    : state_ (no_data)
+  {}
+
   Rt_allocated_storage(length_type     size,
 		       rt_complex_type cformat,
-		       type            buffer = type(),
-		       AllocT const&   alloc  = AllocT())
+		       type            buffer = type())
     VSIP_THROW((std::bad_alloc))
     : cformat_(cformat),
-      alloc_ (alloc),
       state_ (size == 0         ? no_data   :
 	      buffer.is_null()  ? alloc_data
 		                : user_data),
-      data_  (state_ == alloc_data ? allocate_(alloc_, size, cformat_) :
+      data_  (state_ == alloc_data ? allocate_ (cformat_, size) :
 	      state_ == user_data  ? partition_(cformat, buffer, size)
 	                           : type())
   {}
@@ -1306,15 +1352,13 @@
   Rt_allocated_storage(length_type   size,
 		       rt_complex_type cformat,
 		       T               val,
-		       type            buffer = type(),
-		       AllocT const& alloc  = AllocT())
+		       type            buffer = type())
   VSIP_THROW((std::bad_alloc))
     : cformat_(cformat),
-      alloc_ (alloc),
       state_ (size == 0         ? no_data   :
 	      buffer.is_null() ? alloc_data
 		                : user_data),
-      data_  (state_ == alloc_data ? allocate_(alloc_, size, cformat_) :
+      data_  (state_ == alloc_data ? allocate_ (cformat, size) :
 	      state_ == user_data  ? partition_(cformat, buffer, size)
 	                           : type())
   {
@@ -1347,7 +1391,7 @@
   {
     if (state_ == alloc_data)
     {
-      deallocate_(data_, cformat_, size, alloc_);
+      deallocate_(data_, cformat_, size);
       data_ = type();
     }
   }
@@ -1360,7 +1404,6 @@
   // Member data.
 private:
   rt_complex_type cformat_;
-  AllocT          alloc_;
   state_type      state_;
   type            data_;
 };
Index: src/vsip/impl/rt_extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/rt_extdata.hpp,v
retrieving revision 1.5
diff -u -r1.5 rt_extdata.hpp
--- src/vsip/impl/rt_extdata.hpp	9 May 2006 16:44:25 -0000	1.5
+++ src/vsip/impl/rt_extdata.hpp	14 May 2006 02:17:11 -0000
@@ -64,7 +64,7 @@
 inline rt_complex_type
 complex_format(Applied_layout<Rt_layout<D> > const& appl)
 {
-  return appl.layout_.complex;
+  return appl.cformat_;
 }
 
 
@@ -156,19 +156,16 @@
 inline Rt_layout<D>
 block_layout(Block const&)
 {
-  Rt_layout<D> rtl;
-
   typedef typename Block_layout<Block>::access_type  access_type;
   typedef typename Block_layout<Block>::order_type   order_type;
   typedef typename Block_layout<Block>::pack_type    pack_type;
   typedef typename Block_layout<Block>::complex_type complex_type;
 
-  rtl.pack    = pack_format<pack_type>();
-  rtl.order   = Rt_tuple(order_type());
-  rtl.complex = complex_format<complex_type>();
-  rtl.align   = Is_stride_unit_align<pack_type>::align;
-
-  return rtl;
+  return Rt_layout<D>(
+    pack_format<pack_type>(),
+    Rt_tuple(order_type()),
+    complex_format<complex_type>(),
+    Is_stride_unit_align<pack_type>::align);
 }
 
 
@@ -325,8 +322,13 @@
     bool                  no_preserve,
     raw_ptr_type          buffer = NULL)
   : use_direct_(!no_preserve && is_direct_ok(blk, rtl)),
-    app_layout_(rtl, extent<dim>(blk), sizeof(value_type)),
-    storage_   (use_direct_ ? 0 : app_layout_.total_size(), rtl.complex, buffer)
+    app_layout_(use_direct_ ?
+		Applied_layout<Rt_layout<Dim> >(empty_layout) :
+		Applied_layout<Rt_layout<Dim> >(
+		  rtl, extent<dim>(blk), sizeof(value_type))),
+    storage_   (use_direct_ ?
+		storage_type(empty_layout) :
+		storage_type(app_layout_.total_size(), rtl.complex, buffer))
   {}
 
   ~Rt_low_level_data_access()
@@ -403,8 +405,7 @@
 	      sync_action_type      sync   = SYNC_INOUT,
 	      raw_ptr_type          buffer = 0 /*storage_type::null()*/)
     : blk_    (&block),
-      rtl_    (rtl),
-      ext_    (block, rtl_, sync & SYNC_NOPRESERVE_impl, buffer),
+      ext_    (block, rtl, sync & SYNC_NOPRESERVE_impl, buffer),
       sync_   (sync)
     { ext_.begin(blk_.get(), sync_ & SYNC_IN); }
 
@@ -413,8 +414,7 @@
 	      sync_action_type      sync,
 	      raw_ptr_type          buffer = 0 /*storage_type::null()*/)
     : blk_ (&const_cast<Block&>(block)),
-      rtl_ (rtl),
-      ext_ (const_cast<Block&>(block), rtl_,
+      ext_ (const_cast<Block&>(block), rtl,
 	    sync & SYNC_NOPRESERVE_impl, buffer),
       sync_(sync)
   {
@@ -443,7 +443,6 @@
 private:
   typename View_block_storage<Block>::template With_rp<RP>::type
 		   blk_;
-  Rt_layout<Dim>   rtl_;
   ext_type         ext_;
   sync_action_type sync_;
 };
Index: src/vsip/impl/sal.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal.hpp,v
retrieving revision 1.5
diff -u -r1.5 sal.hpp
--- src/vsip/impl/sal.hpp	7 Mar 2006 02:15:22 -0000	1.5
+++ src/vsip/impl/sal.hpp	14 May 2006 02:17:11 -0000
@@ -14,7 +14,6 @@
   Included Files
 ***********************************************************************/
 
-#include <iostream>
 #include <complex>
 #include <sal.h>
 
Index: src/vsip/impl/fft/util.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/util.hpp,v
retrieving revision 1.3
diff -u -r1.3 util.hpp
--- src/vsip/impl/fft/util.hpp	13 May 2006 18:04:53 -0000	1.3
+++ src/vsip/impl/fft/util.hpp	14 May 2006 02:17:11 -0000
@@ -18,7 +18,6 @@
 #include <vsip/impl/fft/backend.hpp>
 #include <vsip/impl/fast-block.hpp>
 #include <vsip/impl/view_traits.hpp>
-#include <iostream>
 
 /***********************************************************************
   Declarations
Index: src/vsip/impl/fft/workspace.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/workspace.hpp,v
retrieving revision 1.4
diff -u -r1.4 workspace.hpp
--- src/vsip/impl/fft/workspace.hpp	10 May 2006 14:08:53 -0000	1.4
+++ src/vsip/impl/fft/workspace.hpp	14 May 2006 02:17:11 -0000
@@ -21,7 +21,6 @@
 #include <vsip/impl/allocation.hpp>
 #include <vsip/impl/equal.hpp>
 #include <vsip/impl/rt_extdata.hpp>
-#include <iostream>
 
 /***********************************************************************
   Declarations
Index: src/vsip/impl/fftw3/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fftw3/fft.cpp,v
retrieving revision 1.2
diff -u -r1.2 fft.cpp
--- src/vsip/impl/fftw3/fft.cpp	12 May 2006 00:28:24 -0000	1.2
+++ src/vsip/impl/fftw3/fft.cpp	14 May 2006 02:17:11 -0000
@@ -42,18 +42,24 @@
 } // namespace vsip::impl
 } // namespace vsip
 
-#define FFTW(fun) fftwf_##fun
-#define SCALAR_TYPE float
-#include "fft_impl.cpp"
-#undef SCALAR_TYPE
-#undef FFTW
-#define FFTW(fun) fftw_##fun
-#define SCALAR_TYPE double
-#include "fft_impl.cpp"
-#undef SCALAR_TYPE
-#undef FFTW
-#define FFTW(fun) fftwl_##fun
-#define SCALAR_TYPE long double
-#include "fft_impl.cpp"
-#undef SCALAR_TYPE
-#undef FFTW
+#ifdef VSIP_IMPL_FFT_USE_FLOAT
+#  define FFTW(fun) fftwf_##fun
+#  define SCALAR_TYPE float
+#  include "fft_impl.cpp"
+#  undef SCALAR_TYPE
+#  undef FFTW
+#endif
+#ifdef VSIP_IMPL_FFT_USE_DOUBLE
+#  define FFTW(fun) fftw_##fun
+#  define SCALAR_TYPE double
+#  include "fft_impl.cpp"
+#  undef SCALAR_TYPE
+#  undef FFTW
+#endif
+#ifdef VSIP_IMPL_FFT_USE_LONG_DOUBLE
+#  define FFTW(fun) fftwl_##fun
+#  define SCALAR_TYPE long double
+#  include "fft_impl.cpp"
+#  undef SCALAR_TYPE
+#  undef FFTW
+#endif
Index: src/vsip/impl/fftw3/fft_impl.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fftw3/fft_impl.cpp,v
retrieving revision 1.4
diff -u -r1.4 fft_impl.cpp
--- src/vsip/impl/fftw3/fft_impl.cpp	13 May 2006 18:04:53 -0000	1.4
+++ src/vsip/impl/fftw3/fft_impl.cpp	14 May 2006 02:17:11 -0000
@@ -45,7 +45,7 @@
       reinterpret_cast<FFTW(complex)*>(in_buffer_.get()),
       exp, flags);
     
-    if (!plan_in_place_) throw std::bad_alloc();
+    if (!plan_in_place_) VSIP_IMPL_THROW(std::bad_alloc());
 
     plan_by_reference_ = FFTW(plan_dft)(D, size_,
       reinterpret_cast<FFTW(complex)*>(in_buffer_.get()),
@@ -54,7 +54,7 @@
     if (!plan_by_reference_)
     {
       FFTW(destroy_plan)(plan_in_place_);
-      throw std::bad_alloc();
+      VSIP_IMPL_THROW(std::bad_alloc());
     }
   }
   ~Fft_base() VSIP_NOTHROW
@@ -87,7 +87,7 @@
       in_buffer_.get(), reinterpret_cast<FFTW(complex)*>(out_buffer_.get()),
       FFTW_PRESERVE_INPUT | flags);
     
-    if (!plan_by_reference_) throw std::bad_alloc();
+    if (!plan_by_reference_) VSIP_IMPL_THROW(std::bad_alloc());
   }
   ~Fft_base() VSIP_NOTHROW
   {
@@ -117,7 +117,7 @@
       reinterpret_cast<FFTW(complex)*>(in_buffer_.get()), out_buffer_.get(),
       flags);
 
-    if (!plan_by_reference_) throw std::bad_alloc();
+    if (!plan_by_reference_) VSIP_IMPL_THROW(std::bad_alloc());
   }
   ~Fft_base() VSIP_NOTHROW
   {
Index: src/vsip/impl/sal/solver_qr.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/solver_qr.hpp,v
retrieving revision 1.1
diff -u -r1.1 solver_qr.hpp
--- src/vsip/impl/sal/solver_qr.hpp	9 May 2006 11:24:49 -0000	1.1
+++ src/vsip/impl/sal/solver_qr.hpp	14 May 2006 02:17:11 -0000
@@ -261,7 +261,7 @@
   // SAL only provides a thin-QR decomposition.
   if (st_ == qrd_saveq)
     VSIP_IMPL_THROW(impl::unimplemented(
-	      "Qrd does not support full QR when using SAL(qrd_saveq)"));
+	      "Qrd does not support full storage of Q (qrd_saveq) when using SAL"));
 }
 
 
@@ -275,7 +275,8 @@
     st_         (qr.st_),
     data_       (m_, n_),
     t_data_     (n_, m_),
-    r_data_     (n_, n_)
+    r_data_     (n_, n_),
+    rt_data_    (n_, n_)
 {
   data_ = qr.data_;
 }
