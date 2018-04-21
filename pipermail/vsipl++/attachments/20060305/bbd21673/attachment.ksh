Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.403
diff -u -r1.403 ChangeLog
--- ChangeLog	4 Mar 2006 23:03:04 -0000	1.403
+++ ChangeLog	6 Mar 2006 04:31:07 -0000
@@ -1,3 +1,54 @@
+2006-03-05  Jules Bergmann  <jules@codesourcery.com>
+
+	* configure.ac (--with-alignment): New option to set
+	  VSIP_IMPL ALLOC_ALIGNMENT.
+	  Extend std::abs test to cover long double.
+	  (VSIP_IMPL_HAVE_COMPLEX_LONG_DOUBLE) define if stdlib supports
+	  complex<long double>.
+	  Check if acosh is provided.
+	* examples/mercury/mcoe-setup.sh: New file, example setup for
+	  mercury.
+	* src/vsip/dense.hpp (vsip::impl::dense_complex_type): New typedef.
+	* src/vsip/signal-window.cpp (acosh): provide definition when
+	  stdlib doesn't.
+	  (pragma) Add instantiation pragmas for GHS.
+	* src/vsip/impl/aligned_allocator.hpp (VSIP_IMPL_ALLOC_ALIGNMENT):
+	  Remove hard-coded definition, use acconfig version.
+	* src/vsip/impl/eval-sal.hpp (VSIP_IMPL_SAL_USE_MAT_MUL):
+	  Don't use mat_mul at all when defined (even if no alternative
+	  exists).  Have dot-product to check if complex formats are the same.
+	* src/vsip/impl/expr_scalar_block.hpp (Scalar_block): Provide
+	  3-dim specialization.
+	* src/vsip/impl/extdata.hpp (is_aligned_to): new function overloads
+	  to generalize alignment check.
+	* src/vsip/impl/fft-core.hpp (Ipp_DFT_base::create_plan2): Fix
+	  reversed use of rows and columns.
+	  (create_ipp_plan): Likewise, cleanup.
+	  (destroy): Fix IPP backend effective dimension used to destroy
+	  plan.
+	* src/vsip/impl/fns_elementwise.hpp: Make operator functions
+	  inline.
+	* src/vsip/impl/layout.hpp (Storage): provide alloc_align based
+	  allocation and deallocation.
+	* src/vsip/impl/point.hpp: Make generic get/put functions inline.
+	* src/vsip/impl/sal.hpp: Add support for split complex convolution.
+	* src/vsip/impl/signal-conv-sal.hpp: Likewise.
+	* src/vsip/impl/signal-conv-common.hpp: Add generic routines for
+	  split complex convolution.
+	* src/vsip/impl/signal-fft.hpp: Make small utility functions inline.
+	* tests/convolution.cpp: Test complex convolution when
+	  VSIP_IMPL_TEST_LEVEL == 0.
+	* tests/counter.cpp: Make test work when not using exceptions.
+	* tests/fft.cpp: Use DFT for reference 2D FFT.  Limit tests run
+	  when VSIP_IMPL_TEST_LEVEL == 0.
+	* tests/fftm-par.cpp: Disable real-complex tests (mistakenly
+	  enabled in previous patch).
+	* tests/matvec.cpp: Disable long double modulation test if
+	  library does not support long double.
+	* tests/ref_dft.hpp: Fix DFT to work for real to complex.
+	* tests/test.hpp (VSIP_IMPL_TEST_LEVEL): Guard definition to allow
+	  override from command line.
+
 2006-03-04  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac (--with-mpi-prefix64): New option, similar to
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.84
diff -u -r1.84 configure.ac
--- configure.ac	4 Mar 2006 23:03:05 -0000	1.84
+++ configure.ac	6 Mar 2006 04:31:07 -0000
@@ -235,6 +235,14 @@
   ,
   )
 
+# Control default alignment for memory allocations.
+AC_ARG_WITH([alignment],
+  AS_HELP_STRING([--with-alignment=ALIGNMENT],
+                 [Specify ALIGNMENT to use for allocated data in bytes.
+		  Default is to use preferred alignment for system.]),
+  ,
+  [with_alignment=probe])
+
 
 AC_ARG_ENABLE([profile_timer],
   AS_HELP_STRING([--enable-profile-timer=type],
@@ -352,14 +360,14 @@
 
 
 #
-# Check for the std::abs(float) and std::abs(double) overloads.
+# Check for the std::abs(...) overloads.
 #
-# GreenHills <cmath> defines ::abs(float) and ::abs(double), but does
-# not place them into the std namespace when targeting mercury (when
-# _MC_EXEC is defined).
+# GreenHills <cmath> defines ::abs(float), ::abs(double) and
+# ::abs(long double), but does not place them into the std namespace when
+# targeting mercury (when _MC_EXEC is defined).
 
 # First check if std::abs handles float and double:
-AC_MSG_CHECKING([for std::abs(float) and std::abs(double).])
+AC_MSG_CHECKING([for std::abs(float), std::abs(double), and std::abs(long double).])
 have_abs_float="no"
 AC_COMPILE_IFELSE([
 #include <cmath>
@@ -370,6 +378,8 @@
   f1 = std::abs(f1); 
   double d1 = 1.0;
   d1 = std::abs(d1); 
+  long double l1 = 1.0;
+  l1 = std::abs(l1);
 }
 ],
 [have_abs_float="std"
@@ -378,7 +388,7 @@
 
 if test "$have_abs_float" = "no"; then
   # next check for them in ::
-  AC_MSG_CHECKING([for ::abs(float) and ::abs(double).])
+  AC_MSG_CHECKING([for ::abs(float), ::abs(double), and ::abs(long double).])
   AC_COMPILE_IFELSE([
 #include <cmath>
 
@@ -388,6 +398,8 @@
   f1 = ::abs(f1); 
   double d1 = 1.0;
   d1 = ::abs(d1); 
+  long double l1 = 1.0;
+  l1 = ::abs(l1);
 }
 ],
   [have_abs_float="global"
@@ -397,6 +409,28 @@
       [Define to use both ::abs and std::abs for vsip::mag.])
 fi
 
+#
+# Check if standard library supports complex<long double>
+#
+# GreenHills std::abs support complex<float> and complex<double>,
+# but not complex<long double> (neither does ::abs).
+#
+
+AC_MSG_CHECKING([if complex<long double> supported.])
+AC_COMPILE_IFELSE([
+#include <cmath>
+
+int main(int, char **)
+{
+  std::complex<long double> c1 = std::complex<long double>(1.0, 0.0);
+  long double l1 = std::abs(c1);
+}
+],
+[AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_COMPLEX_LONG_DOUBLE, 1,
+	         [Define if standard library supports complex<long double>.])
+ AC_MSG_RESULT(yes)],
+[AC_MSG_RESULT([no])])
+
 
 #
 # Check for the exp10 function.  
@@ -409,6 +443,16 @@
 	       [#include <cmath>])
 
 #
+# Check for the acosh function.
+#
+# Sourcery VSIPL++ uses this to implelemnt Chebychev window.
+#
+# On GreenHills/Mercury, cmath/math.c provide declaration for acosh(),
+# but do not link against a library containing.
+#
+AC_CHECK_FUNCS([acosh], [], [], [#include <cmath>])
+
+#
 # Check for posix_memalign, memalign
 #
 AC_CHECK_HEADERS([malloc.h], [], [], [// no prerequisites])
@@ -1447,6 +1491,15 @@
 fi
 
 #
+# Configure alignment
+#
+if test "$with_alignment" == "probe"; then
+  with_alignment=32
+fi
+AC_DEFINE_UNQUOTED(VSIP_IMPL_ALLOC_ALIGNMENT, $with_alignment,
+                   [Alignment for allocated memory (in bytes)])
+
+#
 # Configure profile timer
 #
 if test "$enable_profile_timer" == "none"; then
Index: examples/mercury/mcoe-setup.sh
===================================================================
RCS file: examples/mercury/mcoe-setup.sh
diff -N examples/mercury/mcoe-setup.sh
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ examples/mercury/mcoe-setup.sh	6 Mar 2006 04:31:07 -0000
@@ -0,0 +1,60 @@
+#! /bin/sh
+
+#########################################################################
+# mcoe-setup.sh -- setup script to configure SourceryVSIPL++ for use on
+#                  Mercury systems
+#
+# (27 Feb 05) Jules Bergmann, CodeSourcery, Inc.
+#########################################################################
+
+#########################################################################
+# Instructions:
+#  - Modify flags below to control where and how VSIPL++ is built.
+#  - Run setup.sh
+#  - Run 'make'
+#  - Run 'make install'
+#########################################################################
+
+# Set 'dir' the directory containing SourceryVSIPL++
+# dir="."
+dir=$HOME/csl/src/vpp/work
+
+comm="ser"		# set to (ser)ial or (par)allel.
+fmt="inter"		# set to (inter)leaved or (split).
+opt="y"			# (y) for optimized flags, (n) for debug flags.
+pflags="-t ppc7400_le"	# processor architecture
+
+# Set 'prefix' the directory where SourceryVSIPL++ Should be installed
+prefix="/opt/tmp/jules/opt/$comm-$fmt"
+
+
+
+#########################################################################
+
+if test $comm == "par"; then
+  par_opt="--enable-mpi=mpipro"
+else
+  par_opt="--disable-mpi"
+fi
+
+base="$pflags --no_exceptions --no_implicit_include"
+if test $opt == "y"; then
+  cxxflags="$base     -Ospeed -Onotailrecursion --max_inlining"
+  cxxflags="$cxxflags -DNDEBUG --diag_suppress 177,550"
+else
+  cxxflags="$base -g"
+fi
+
+export CXX=ccmc++
+export CXXFLAGS=$cxxflags
+export LDFLAGS="$pflags"
+
+$dir/configure					\
+	--prefix=$prefix			\
+	--host=powerpc				\
+	--enable-sal				\
+	--with-fft=sal				\
+	--with-complex=$fmt			\
+	--disable-exceptions			\
+	$par_opt				\
+	--enable-profile-timer=realtime
Index: src/vsip/dense.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/dense.hpp,v
retrieving revision 1.33
diff -u -r1.33 dense.hpp
--- src/vsip/dense.hpp	10 Feb 2006 22:24:01 -0000	1.33
+++ src/vsip/dense.hpp	6 Mar 2006 04:31:07 -0000
@@ -68,6 +68,8 @@
 namespace impl
 { 
 
+typedef VSIP_IMPL_DENSE_CMPLX_FMT dense_complex_type;
+
 /// Forward Declaration
 template <typename Block,
 	  typename Map>
@@ -482,7 +484,7 @@
 	  typename       OrderT = typename impl::Row_major<Dim>::type,
 	  typename       MapT   = Local_map>
 class Dense_impl
-  : public impl::Dense_storage<VSIP_IMPL_DENSE_CMPLX_FMT, T>,
+  : public impl::Dense_storage<dense_complex_type, T>,
     public impl::Ref_count<Dense_impl<Dim, T, OrderT, MapT> >
 {
   enum private_type {};
@@ -505,7 +507,7 @@
 
   // Implementation types.
 public:
-  typedef VSIP_IMPL_DENSE_CMPLX_FMT complex_type;
+  typedef dense_complex_type complex_type;
   typedef impl::Layout<Dim, order_type, impl::Stride_unit_dense,
 		       complex_type> layout_type;
   typedef impl::Applied_layout<layout_type>   applied_layout_type;
@@ -969,7 +971,7 @@
   typedef Direct_access_tag access_type;
   typedef Order             order_type;
   typedef Stride_unit_dense pack_type;
-  typedef VSIP_IMPL_DENSE_CMPLX_FMT complex_type;
+  typedef dense_complex_type complex_type;
   // typedef typename Dense<Dim, T, Order, Map>::complex_type complex_type;
 
   typedef Layout<dim, order_type, pack_type, complex_type> layout_type;
Index: src/vsip/signal-window.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/signal-window.cpp,v
retrieving revision 1.4
diff -u -r1.4 signal-window.cpp
--- src/vsip/signal-window.cpp	7 Dec 2005 19:22:05 -0000	1.4
+++ src/vsip/signal-window.cpp	6 Mar 2006 04:31:07 -0000
@@ -10,6 +10,8 @@
   Included Files
 ***********************************************************************/
 
+#include <cmath>
+
 #include <vsip/selgen.hpp>
 #include "impl/signal-fft.hpp"
 #include "impl/signal-freqswap.hpp"
@@ -44,6 +46,22 @@
   return v;
 }
 
+namespace impl
+{
+
+#if HAVE_DECL_ACOSH
+// If the C++ library provides ::acosh, we'll use it.
+using ::acosh;
+#else // !HAVE_DECL_ACOSH
+// Otherwise, we have to provide our own version.
+inline double
+acosh(double f)
+{
+  return log(f + sqrt(f+1)*sqrt(f-1));
+}
+#endif
+
+} // namespace impl
 
 /// Creates Chebyshev window with user-specified ripple.
 /// Requires: len > 1.
@@ -57,7 +75,7 @@
 
   scalar_f dp = pow( 10.0, -ripple / 20.0 );
   scalar_f df = acos( 1.0 / 
-    cosh( acosh( (1.0 + dp) / dp) / (len - 1.0) ) ) / M_PI;
+    cosh( impl::acosh( (1.0 + dp) / dp) / (len - 1.0) ) ) / M_PI;
   scalar_f x0 = (3.0 - cos( 2 * M_PI * df )) / (1.0 + cos( 2 * M_PI * df ));
 
   Vector<scalar_f> f = ramp(0.f, 1.f / len, len);
@@ -179,5 +197,31 @@
   return v;
 }
 
+
+
+// The GreenHills compiler on the mercury does not automatically 
+// instantiate templates until link time, which is too late for
+// applications linking against VSIPL++.  We use pragmas to force
+// the instantiation of templates necessary for this source file.
+// We need to make sure that we don't force the instantiation of
+// the same templates in multiply library files because that will
+// result in multiple symbol definition errors.
+
+#if defined(__ghs__)
+#pragma instantiate float vsip::impl::bessel_I_0(float)
+
+#pragma instantiate  Vector<float, Dense<1, float, row1_type, Local_map> > vsip::freqswap<Vector, float, Dense<1, float, row1_type, Local_map> >(Vector<float, Dense<1, float, row1_type, Local_map> >)
+
+#pragma instantiate vsip::const_Vector<float, Dense<1, float, row1_type, Local_map> > vsip::impl::freqswap<float, Dense<1, float, row1_type, Local_map> >(vsip::const_Vector<float, Dense<1, float, row1_type, Local_map> >)
+
+#pragma instantiate vsip::const_Vector<float, const vsip::impl::Generator_expr_block<(unsigned int)1, vsip::impl::Ramp_generator<float> > > vsip::ramp<float>(float, float, unsigned int)
+
+#pragma instantiate vsip::impl::Clip_return_type<double, float, double, Vector, Dense<1, float, row1_type, Local_map> >::type vsip::clip<double, float, double, Vector, Dense<1, float, row1_type, Local_map> >(Vector<float, Dense<1, float, row1_type, Local_map> >, double, double, double, double)
+
+#pragma instantiate void vsip::impl::acosh<float>(vsip::Vector<float, vsip::Dense<(unsigned int)1, float, vsip::tuple<(unsigned int)0, (unsigned int)1, (unsigned int)2>, vsip::Local_map> > &, vsip::Vector<std::complex<float>, vsip::Dense<(unsigned int)1, std::complex<float>, vsip::tuple<(unsigned int)0, (unsigned int)1, (unsigned int)2>, vsip::Local_map> > &)
+
+#pragma instantiate vsip::impl::Point<1> vsip::impl::extent_old<1, Dense<1, complex<float>, row1_type, Local_map> >(const Dense<1, complex<float>, row1_type, Local_map>  &)
+#endif
+
 } // namespace vsip
 
Index: src/vsip/impl/aligned_allocator.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/aligned_allocator.hpp,v
retrieving revision 1.5
diff -u -r1.5 aligned_allocator.hpp
--- src/vsip/impl/aligned_allocator.hpp	27 Feb 2006 15:07:13 -0000	1.5
+++ src/vsip/impl/aligned_allocator.hpp	6 Mar 2006 04:31:07 -0000
@@ -20,8 +20,6 @@
 
 #include <vsip/impl/allocation.hpp>
 
-#define VSIP_IMPL_ALLOC_ALIGNMENT 32
-
 
 
 /***********************************************************************
Index: src/vsip/impl/eval-sal.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/eval-sal.hpp,v
retrieving revision 1.2
diff -u -r1.2 eval-sal.hpp
--- src/vsip/impl/eval-sal.hpp	3 Mar 2006 14:30:53 -0000	1.2
+++ src/vsip/impl/eval-sal.hpp	6 Mar 2006 04:31:07 -0000
@@ -26,6 +26,9 @@
 // set.  At present, Mecury states that the mmul() functions are 
 // faster, but the API is changing towards that used with mat_mul().
 // See 'sal.hpp' for details as to the differences.
+//
+// In addition, complex mat_mul veriants have a defect that
+// affects CSAL and SAL for MCOE 6.3.0.
 
 #define VSIP_IMPL_SAL_USE_MAT_MUL 0
 
@@ -41,6 +44,8 @@
 namespace impl
 {
 
+#if VSIP_IMPL_SAL_USE_MAT_MUL
+
 // SAL evaluator for vector-vector outer product
 
 template <typename T1,
@@ -209,6 +214,8 @@
   }
 };
 
+#endif // VSIP_IMPL_SAL_USE_MAT_MUL
+
 
 
 // SAL evaluator for vector-vector dot-product (non-conjugated).
@@ -219,13 +226,18 @@
 struct Evaluator<Op_prod_vv_dot, Return_scalar<T>, Op_list_2<Block1, Block2>,
                  Mercury_sal_tag>
 {
+  typedef typename Block_layout<Block1>::complex_type complex1_type;
+  typedef typename Block_layout<Block2>::complex_type complex2_type;
+
   static bool const ct_valid = 
     impl::sal::Sal_traits<T>::valid &&
     Type_equal<T, typename Block1::value_type>::value &&
     Type_equal<T, typename Block2::value_type>::value &&
     // check that direct access is supported
     Ext_data_cost<Block1>::value == 0 &&
-    Ext_data_cost<Block2>::value == 0;
+    Ext_data_cost<Block2>::value == 0 &&
+    // check complex layout is consistent
+    Type_equal<complex1_type, complex2_type>::value;
 
   static bool rt_valid(Block1 const&, Block2 const&) { return true; }
 
@@ -257,13 +269,18 @@
                                             Block2, complex<T> > const>,
                  Mercury_sal_tag>
 {
+  typedef typename Block_layout<Block1>::complex_type complex1_type;
+  typedef typename Block_layout<Block2>::complex_type complex2_type;
+
   static bool const ct_valid = 
     impl::sal::Sal_traits<complex<T> >::valid &&
     Type_equal<complex<T>, typename Block1::value_type>::value &&
     Type_equal<complex<T>, typename Block2::value_type>::value &&
     // check that direct access is supported
     Ext_data_cost<Block1>::value == 0 &&
-    Ext_data_cost<Block2>::value == 0;
+    Ext_data_cost<Block2>::value == 0 &&
+    // check complex layout is consistent
+    Type_equal<complex1_type, complex2_type>::value;
 
   static bool rt_valid(
     Block1 const&, 
@@ -830,6 +847,7 @@
 
     
 
+#if VSIP_IMPL_SAL_USE_MAT_MUL
 
 // SAL evaluator for generalized matrix-matrix products.
 
@@ -954,6 +972,8 @@
   }
 };
 
+#endif // VSIP_IMPL_SAL_USE_MAT_MUL
+
 
 
 } // namespace vsip::impl
Index: src/vsip/impl/expr_scalar_block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_scalar_block.hpp,v
retrieving revision 1.13
diff -u -r1.13 expr_scalar_block.hpp
--- src/vsip/impl/expr_scalar_block.hpp	18 Jan 2006 12:32:05 -0000	1.13
+++ src/vsip/impl/expr_scalar_block.hpp	6 Mar 2006 04:31:07 -0000
@@ -104,6 +104,32 @@
   length_type const size1_;
 };
 
+/// Scalar_block specialization for 3-dimension.
+template <typename Scalar>
+class Scalar_block<3, Scalar> : public Scalar_block_base<3, Scalar>
+{
+public:
+  Scalar_block(Scalar s, Length<3> const& l)
+    : Scalar_block_base<3, Scalar>(s),
+      size0_(l[0]), size1_(l[1]), size2_(l[2]) {}
+  Scalar_block(Scalar s,
+	      length_type x,
+	      length_type y,
+	      length_type z)
+    : Scalar_block_base<3, Scalar>(s), size0_(x), size1_(y), size2_(z) {}
+
+  length_type size() const VSIP_NOTHROW;
+  length_type size(dimension_type block_dim, dimension_type d) const VSIP_NOTHROW;
+
+  Scalar get(index_type idx) const VSIP_NOTHROW;
+  Scalar get(index_type x, index_type y, index_type z) const VSIP_NOTHROW;
+
+private:
+  length_type const size0_;
+  length_type const size1_;
+  length_type const size2_;
+};
+
 
 
 /// Specialize Is_expr_block for scalar expr blocks.
@@ -292,6 +318,48 @@
   return this->value();
 }
 
+
+
+template <typename Scalar>
+inline length_type
+Scalar_block<3, Scalar>::size() const VSIP_NOTHROW
+{
+  return size0_ * size1_ * size2_;
+}
+
+template <typename Scalar>
+inline length_type
+Scalar_block<3, Scalar>::size(
+  dimension_type block_dim,
+  dimension_type d) const
+  VSIP_NOTHROW
+{
+  assert((block_dim == 1 || block_dim == 3) && d < block_dim);
+  if (block_dim == 1) return size();
+  else return d == 0 ? size0_ :
+              d == 1 ? size1_ :
+                       size2_;
+}
+
+template <typename Scalar>
+inline Scalar
+Scalar_block<3, Scalar>::get(index_type idx) const VSIP_NOTHROW
+{
+  assert(idx < size());
+  return this->value();
+}
+
+template <typename Scalar>
+inline Scalar
+Scalar_block<3, Scalar>::get(index_type x, index_type y, index_type z)
+  const VSIP_NOTHROW
+{
+  assert(x < size0_ && y < size1_ && z < size2_);
+  return this->value();
+}
+
+
+
 /// Store Scalar_blocks by-value.
 template <dimension_type D, typename Scalar>
 struct View_block_storage<Scalar_block<D, Scalar> >
Index: src/vsip/impl/extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/extdata.hpp,v
retrieving revision 1.17
diff -u -r1.17 extdata.hpp
--- src/vsip/impl/extdata.hpp	10 Feb 2006 22:24:01 -0000	1.17
+++ src/vsip/impl/extdata.hpp	6 Mar 2006 04:31:07 -0000
@@ -281,6 +281,20 @@
 
 
 
+template <typename T>
+bool is_aligned_to(T* pointer, size_t align)
+{
+  return reinterpret_cast<size_t>(pointer) % align == 0;
+}
+
+template <typename T>
+bool is_aligned_to(std::pair<T*, T*> pointer, size_t align)
+{
+  return reinterpret_cast<size_t>(pointer.first)  % align == 0 &&
+         reinterpret_cast<size_t>(pointer.second) % align == 0;
+}
+
+
 /// Determine if direct access is OK at runtime for a given block.
 
 template <typename LP,
@@ -336,7 +350,7 @@
   {
     unsigned align = Is_stride_unit_align<typename LP::pack_type>::align;
 
-    if (reinterpret_cast<size_t>(block.impl_data()) % align != 0)
+    if (!is_aligned_to(block.impl_data(), align))
       return false;
 
     if (LP::dim == 1)
Index: src/vsip/impl/fft-core.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft-core.hpp,v
retrieving revision 1.20
diff -u -r1.20 fft-core.hpp
--- src/vsip/impl/fft-core.hpp	17 Feb 2006 20:23:44 -0000	1.20
+++ src/vsip/impl/fft-core.hpp	6 Mar 2006 04:31:07 -0000
@@ -953,14 +953,15 @@
   }
 
   static void*
-  create_plan2(int x, int y, int flags, bool f) VSIP_THROW((std::bad_alloc))
+  create_plan2(int rows, int cols, int flags, bool f)
+    VSIP_THROW((std::bad_alloc))
   {
     planFT* planf;
     planDT* pland;
     IppiSize size;
-    size.width = x; size.height = y;
+    size.width = cols; size.height = rows;
     IppStatus result = (f ?
-	 (*planFFun2)(&planf, x, y, flags, ippAlgHintFast) :
+	 (*planFFun2)(&planf, cols, rows, flags, ippAlgHintFast) :
 	 (*planDFun2)(&pland, size, flags, ippAlgHintFast) );
     if (result != ippStsNoErr)
       VSIP_THROW(std::bad_alloc());
@@ -1107,14 +1108,24 @@
 struct Ipp_DFT<2,std::complex<float> >
   : Ipp_DFT_base<
       2,Ipp32fc,
-      IppiFFTSpec_C_32fc,
-      dum,ippiFFTInitAlloc_C_32fc,
-      ippiFFTFree_C_32fc,ippiFFTGetBufSize_C_32fc,dum,dum,
-      ippiFFTFwd_CToC_32fc_C1R,ippiFFTInv_CToC_32fc_C1R, 
-      IppiDFTSpec_C_32fc,
-      dum,ippiDFTInitAlloc_C_32fc,
-      ippiDFTFree_C_32fc,ippiDFTGetBufSize_C_32fc,dum,dum,
-      ippiDFTFwd_CToC_32fc_C1R,ippiDFTInv_CToC_32fc_C1R> 
+      IppiFFTSpec_C_32fc,		// planFT
+      dum,				// planFFun1
+      ippiFFTInitAlloc_C_32fc,		// planFFun2
+      ippiFFTFree_C_32fc,		// disposeFFun
+      ippiFFTGetBufSize_C_32fc,		// bufsizeFFun
+      dum,				// ForwardFFun1
+      dum,				// InverseFFun1
+      ippiFFTFwd_CToC_32fc_C1R,		// ForwardFFun2
+      ippiFFTInv_CToC_32fc_C1R,		// InverseFFun2
+      IppiDFTSpec_C_32fc,		// planDT
+      dum,				// planDFun1
+      ippiDFTInitAlloc_C_32fc,		// planDFun2
+      ippiDFTFree_C_32fc,		// disposeDFun
+      ippiDFTGetBufSize_C_32fc,		// bufsizeDFun
+      dum,				// forwardDFun1
+      dum,				// inverseDFun1
+      ippiDFTFwd_CToC_32fc_C1R,		// forwardDFun2
+      ippiDFTInv_CToC_32fc_C1R>		// inverseDFun2
 {
    static const vsip::dimension_type dim = 2;
    typedef std::complex<float> in_type;
@@ -1249,31 +1260,41 @@
   vsip::Domain<Dim> const& dom)
     VSIP_THROW((std::bad_alloc))
 {
-  self.use_fft_ = is_power_of_two(dom[0].size());
-  if (Dim - doFFTM == 2)
-    self.use_fft_ = (self.use_fft_ && is_power_of_two(dom[1].size()));
-  int sizex = self.use_fft_ ? int_log2(dom[0].size()) : dom[0].size();
-  int sizey = 0;
-  if (Dim - doFFTM == 2)
-    sizey = self.use_fft_ ? int_log2(dom[1].size()) : dom[1].size();
-
   self.doing_scaling_ = (self.scale_ == 1.0/dom.size());
   const int flags = self.doing_scaling_ ? (self.is_forward_ ? 
       IPP_FFT_DIV_FWD_BY_N : IPP_FFT_DIV_INV_BY_N) : IPP_FFT_NODIV_BY_ANY;
 
+  dimension_type const ActualDim = Dim-doFFTM;
+
   typedef typename Time_domain<inT,outT>::type time_domain_type;
-  typedef Ipp_DFT< (Dim-doFFTM),time_domain_type>  fft_type;
+  typedef Ipp_DFT<ActualDim, time_domain_type> fft_type;
+
+  if (ActualDim == 1)
+  {
+    self.use_fft_ = is_power_of_two(dom[0].size());
+
+    int sizex = self.use_fft_ ? int_log2(dom[0].size()) : dom[0].size();
 
-  if (Dim - doFFTM == 1)
     self.plan_from_to_ = fft_type::create_plan(sizex, flags, self.use_fft_);
-  else
+  }
+  else if (ActualDim == 2)
   {
+    self.use_fft_ = (self.use_fft_ && is_power_of_two(dom[1].size()));
+
+    int rows = self.use_fft_ ? int_log2(dom[0].size()) : dom[0].size();
+    int cols = self.use_fft_ ? int_log2(dom[1].size()) : dom[1].size();
+
     self.plan_from_to_ = 
-      fft_type::create_plan2(sizex, sizey, flags, self.use_fft_);
-    self.row_step_ = sizeof(outT) * dom[0].size();
+      fft_type::create_plan2(rows, cols, flags, self.use_fft_);
+    self.row_step_ = sizeof(outT) * dom[1].size();
   }
-  
-  self.p_buffer_ = impl::alloc_align(
+  else
+  {
+    VSIP_IMPL_THROW(impl::unimplemented(
+			"IPP only supports 1-dim and 2-dim FFTs"));
+  }
+
+  self.p_buffer_ = impl::alloc_align<char>(
     16, fft_type::bufsize(self.plan_from_to_, self.use_fft_));
   if (self.p_buffer_ == 0)
   {
@@ -1330,7 +1351,7 @@
   Fft_core<Dim,T1,T2,doFFTM>&  self)
     VSIP_NOTHROW
 {
-  Ipp_DFT<Dim,typename Time_domain<T1,T2>::type>::dispose(
+  Ipp_DFT<(Dim-doFFTM),typename Time_domain<T1,T2>::type>::dispose(
     self.plan_from_to_, self.use_fft_);
   impl::free_align(self.p_buffer_);
 }
Index: src/vsip/impl/fns_elementwise.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fns_elementwise.hpp,v
retrieving revision 1.17
diff -u -r1.17 fns_elementwise.hpp
--- src/vsip/impl/fns_elementwise.hpp	12 Dec 2005 17:47:50 -0000	1.17
+++ src/vsip/impl/fns_elementwise.hpp	6 Mar 2006 04:31:07 -0000
@@ -56,6 +56,7 @@
 
 #define VSIP_IMPL_UNARY_FUNCTION(name)                                    \
 template <typename T>                                                     \
+inline									  \
 typename Dispatch_##name<T>::result_type				  \
 name(T t) { return Dispatch_##name<T>::apply(t);}
 
@@ -128,23 +129,27 @@
 
 #define VSIP_IMPL_BINARY_FUNCTION(name)			                  \
 template <typename T1, typename T2>					  \
+inline									  \
 typename Dispatch_##name<T1, T2>::result_type				  \
 name(T1 t1, T2 t2) { return Dispatch_##name<T1, T2>::apply(t1, t2);}
 
 #define VSIP_IMPL_BINARY_OPERATOR_ONE(op, name)				\
 template <typename T1, typename T2>					\
+inline									\
 typename Dispatch_op_##name<T1, T2>::result_type			\
 operator op(T1 t1, T2 t2) { return Dispatch_op_##name<T1, T2>::apply(t1, t2);}
 
 #define VSIP_IMPL_BINARY_OPERATOR_TWO(op, name)       			\
 template <template <typename, typename> class View,			\
  	  typename T1, typename Block1, typename T2>			\
+inline									\
 typename Dispatch_op_##name<View<T1, Block1>, T2>::result_type		\
 operator op(View<T1, Block1> t1, T2 t2)					\
 { return Dispatch_op_##name<View<T1, Block1>, T2>::apply(t1, t2);}	\
   									\
 template <template <typename, typename> class View,			\
  	  typename T1, typename T2, typename Block2>			\
+inline									\
 typename Dispatch_op_##name<T1, View<T2, Block2> >::result_type		\
 operator op(T1 t1, View<T2, Block2> t2)					\
 { return Dispatch_op_##name<T1, View<T2, Block2> >::apply(t1, t2);}	\
@@ -153,6 +158,7 @@
  	  template <typename, typename> class RView,			\
  	  typename T1, typename Block1,					\
  	  typename T2, typename Block2>					\
+inline									\
 typename Dispatch_op_##name<LView<T1, Block1>,				\
  			    RView<T2, Block2> >::result_type		\
 operator op(LView<T1, Block1> t1, RView<T2, Block2> t2)			\
@@ -168,6 +174,7 @@
 #define VSIP_IMPL_BINARY_VIEW_FUNCTION(name)	       	                  \
 template <template <typename, typename> class V,                          \
           typename T, typename B>					  \
+inline									  \
 typename Dispatch_##name<V<T,B>, V<T,B> >::result_type           	  \
 name(V<T,B> t1, V<T,B> t2)                                                \
 { return Dispatch_##name<V<T,B>, V<T,B> >::apply(t1, t2);}
Index: src/vsip/impl/layout.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/layout.hpp,v
retrieving revision 1.17
diff -u -r1.17 layout.hpp
--- src/vsip/impl/layout.hpp	10 Feb 2006 22:24:01 -0000	1.17
+++ src/vsip/impl/layout.hpp	6 Mar 2006 04:31:07 -0000
@@ -775,6 +775,9 @@
   static bool is_null(type data) { return data == 0; }
   static type null() { return 0; }
 
+
+  // Allocator based allocation
+
   template <typename AllocT>
   static T*   allocate(AllocT& allocator, length_type size) 
   {
@@ -787,6 +790,20 @@
     allocator.deallocate(data, size);
   }
 
+
+  // Direct allocation
+
+  static T*   allocate(length_type size) 
+  {
+    return alloc_align<T>(VSIP_IMPL_ALLOC_ALIGNMENT, size);
+  }
+
+  static void deallocate(type data)
+  {
+    free_align(data);
+  }
+
+
   static type offset(type ptr, stride_type stride)
   { return ptr + stride; }
 };
@@ -813,6 +830,9 @@
     { return data.first == 0 || data.second == 0; }
   static type null() { return type(0, 0); }
 
+
+  // Allocator based allocation
+
   template <typename AllocT>
   static std::pair<T*, T*> allocate(AllocT& allocator, length_type size) 
   {
@@ -827,6 +847,21 @@
     allocator.deallocate(data.second, size);
   }
 
+
+  // Direct allocation
+
+  static std::pair<T*, T*> allocate(length_type size) 
+  {
+    return std::pair<T*, T*>(alloc_align<T>(VSIP_IMPL_ALLOC_ALIGNMENT, size),
+			     alloc_align<T>(VSIP_IMPL_ALLOC_ALIGNMENT, size));
+  }
+
+  static void deallocate(type data) 
+  {
+    free_align(data.first);
+    free_align(data.second);
+  }
+
   static type offset(type ptr, stride_type stride)
   { return type(ptr.first + stride, ptr.second + stride); }
 };
Index: src/vsip/impl/point.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/point.hpp,v
retrieving revision 1.7
diff -u -r1.7 point.hpp
--- src/vsip/impl/point.hpp	5 Aug 2005 15:43:48 -0000	1.7
+++ src/vsip/impl/point.hpp	6 Mar 2006 04:31:07 -0000
@@ -248,7 +248,7 @@
 /// Get a value from a 1-dim block.
 
 template <typename Block>
-typename Block::value_type
+inline typename Block::value_type
 get(
   Block const&    block,
   Point<1> const& idx)
@@ -261,7 +261,7 @@
 /// Get a value from a 2-dim block.
 
 template <typename Block>
-typename Block::value_type
+inline typename Block::value_type
 get(
   Block const&    block,
   Point<2> const& idx)
@@ -274,7 +274,7 @@
 /// Get a value from a 3-dim block.
 
 template <typename Block>
-typename Block::value_type
+inline typename Block::value_type
 get(
   Block const&    block,
   Point<3> const& idx)
@@ -287,7 +287,7 @@
 /// Put a value into a 1-dim block.
 
 template <typename Block>
-void
+inline void
 put(
   Block&                            block,
   Point<1> const&                   idx,
@@ -301,7 +301,7 @@
 /// Put a value into a 2-dim block.
 
 template <typename Block>
-void
+inline void
 put(
   Block&                            block,
   Point<2> const&                   idx,
@@ -315,7 +315,7 @@
 /// Put a value into a 3-dim block.
 
 template <typename Block>
-void
+inline void
 put(
   Block&                            block,
   Point<3> const&                   idx,
Index: src/vsip/impl/sal.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal.hpp,v
retrieving revision 1.4
diff -u -r1.4 sal.hpp
--- src/vsip/impl/sal.hpp	3 Mar 2006 14:30:53 -0000	1.4
+++ src/vsip/impl/sal.hpp	6 Mar 2006 04:31:07 -0000
@@ -583,8 +583,30 @@
   );                                   \
 }
 
-VSIP_IMPL_SAL_CONV( float,          float,   convx,  1 );
-VSIP_IMPL_SAL_CONV( complex<float>, COMPLEX, cconvx, 2 );
+#define VSIP_IMPL_SAL_CONV_SPLIT( T, SAL_T, SALFCN, STRIDE_X )		\
+inline void								\
+conv( std::pair<T*, T*> filter, int f_as, int M,			\
+      std::pair<T*, T*> input,  int i_as, int N,			\
+      std::pair<T*, T*> output, int o_as )				\
+{									\
+  SAL_T filter_end = { filter.first + M-1, filter.second + M-1 };	\
+  SALFCN(								\
+    (SAL_T *) &input,         /* input vector, length of A >= N+p-1 */	\
+    i_as * STRIDE_X,          /* address stride for A               */	\
+    (SAL_T *) &filter_end,    /* input filter                       */	\
+    -1 * f_as * STRIDE_X,     /* address stride for B               */	\
+    (SAL_T *) &output,        /* output vector                      */	\
+    o_as * STRIDE_X,          /* address stride for C               */	\
+    N,                        /* real output count                  */	\
+    M,                        /* filter length (vector B)           */	\
+    0                         /* ESAL flag                          */	\
+    );									\
+}
+
+VSIP_IMPL_SAL_CONV( float,          float,         convx,  1 );
+VSIP_IMPL_SAL_CONV( complex<float>, COMPLEX,       cconvx, 2 );
+
+VSIP_IMPL_SAL_CONV_SPLIT( float, COMPLEX_SPLIT, zconvx, 1 );
 
 
 
Index: src/vsip/impl/signal-conv-common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv-common.hpp,v
retrieving revision 1.7
diff -u -r1.7 signal-conv-common.hpp
--- src/vsip/impl/signal-conv-common.hpp	11 Jan 2006 16:22:45 -0000	1.7
+++ src/vsip/impl/signal-conv-common.hpp	6 Mar 2006 04:31:07 -0000
@@ -231,6 +231,10 @@
 
 
 
+/***********************************************************************
+  1-D Convolutions (interleaved)
+***********************************************************************/
+
 /// Perform 1-D convolution with full region of support.
 
 template <typename T>
@@ -263,7 +267,7 @@
 
 
 
-/// Perform convolution with same region of support.
+/// Perform 1-D convolution with same region of support.
 
 template <typename T>
 inline void
@@ -296,7 +300,7 @@
 
 
 
-/// Perform convolution with minimal region of support.
+/// Perform 1-D convolution with minimal region of support.
 
 template <typename T>
 inline void
@@ -345,6 +349,135 @@
 
 
 
+/***********************************************************************
+  1-D Convolutions (split)
+***********************************************************************/
+
+/// Perform 1-D convolution with full region of support.
+
+template <typename T>
+inline void
+conv_full(
+  std::pair<T*, T*> coeff,
+  length_type       coeff_size,	// M
+  std::pair<T*, T*> in,
+  length_type       in_size,		// N
+  stride_type       in_stride,
+  std::pair<T*, T*> out,
+  length_type       out_size,		// P
+  stride_type       out_stride,
+  length_type       decimation)
+{
+  typedef typename Convolution_accum_trait<complex<T> >::sum_type sum_type;
+  typedef Storage<Cmplx_split_fmt, complex<T> > storage_type;
+
+  for (index_type n=0; n<out_size; ++n)
+  {
+    sum_type sum = sum_type();
+      
+    for (index_type k=0; k<coeff_size; ++k)
+    {
+      if (n*decimation >= k && n*decimation-k < in_size)
+	sum += storage_type::get(coeff, k) *
+	       storage_type::get(in,   (n*decimation-k) * in_stride);
+    }
+    storage_type::put(out, n * out_stride, sum);
+  }
+}
+
+
+
+/// Perform 1-D convolution with same region of support.
+
+template <typename T>
+inline void
+conv_same(
+  std::pair<T*, T*> coeff,
+  length_type       coeff_size,	// M
+  std::pair<T*, T*> in,
+  length_type       in_size,		// N
+  stride_type       in_stride,
+  std::pair<T*, T*> out,
+  length_type       out_size,		// P
+  stride_type       out_stride,
+  length_type       decimation)
+{
+  typedef typename Convolution_accum_trait<complex<T> >::sum_type sum_type;
+  typedef Storage<Cmplx_split_fmt, complex<T> > storage_type;
+
+  for (index_type n=0; n<out_size; ++n)
+  {
+    sum_type sum = sum_type();
+      
+    for (index_type k=0; k<coeff_size; ++k)
+    {
+      if (n*decimation + (coeff_size/2)   >= k &&
+	  n*decimation + (coeff_size/2)-k <  in_size)
+	sum += storage_type::get(coeff, k) *
+	       storage_type::get(in, (n*decimation+(coeff_size/2)-k) * in_stride);
+    }
+    storage_type::put(out, n * out_stride, sum);
+  }
+}
+
+
+
+/// Perform 1-D convolution with minimal region of support.
+
+template <typename T>
+inline void
+conv_min(
+  std::pair<T*, T*> coeff,
+  length_type       coeff_size,	// M
+  std::pair<T*, T*> in,
+  length_type       in_size,		// N
+  stride_type       in_stride,
+  std::pair<T*, T*> out,
+  length_type       out_size,		// P
+  stride_type       out_stride,
+  length_type       decimation)
+{
+  typedef typename Convolution_accum_trait<complex<T> >::sum_type sum_type;
+  typedef Storage<Cmplx_split_fmt, complex<T> > storage_type;
+
+#if VSIP_IMPL_CONV_CORRECT_MIN_SUPPORT_SIZE
+  assert((out_size-1)*decimation+(coeff_size-1) < in_size);
+
+  for (index_type n=0; n<out_size; ++n)
+  {
+    sum_type sum = sum_type();
+      
+    index_type offset = n*decimation+(coeff_size-1);
+    for (index_type k=0; k<coeff_size; ++k)
+    {
+      sum += storage_type::get(coeff, k) *
+	     storage_type::get(in,    (offset-k) * in_stride);
+    }
+    storage_type::put(out, n * out_stride, sum);
+  }
+#else
+  for (index_type n=0; n<out_size; ++n)
+  {
+    sum_type sum = sum_type();
+      
+    index_type offset = n*decimation+(coeff_size-1);
+    for (index_type k=0; k<coeff_size; ++k)
+    {
+      if (offset-k < in_size)
+        sum += storage_type::get(coeff, k) *
+	       storage_type::get(in,    (offset-k) * in_stride);
+    }
+    storage_type::put(out, n * out_stride, sum);
+  }
+#endif
+}
+
+
+
+/***********************************************************************
+  2-D Convolutions (interleaved)
+***********************************************************************/
+
 /// Perform 2-D convolution with full region of support.
 
 template <typename T>
Index: src/vsip/impl/signal-conv-sal.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv-sal.hpp,v
retrieving revision 1.3
diff -u -r1.3 signal-conv-sal.hpp
--- src/vsip/impl/signal-conv-sal.hpp	3 Mar 2006 14:30:53 -0000	1.3
+++ src/vsip/impl/signal-conv-sal.hpp	6 Mar 2006 04:31:07 -0000
@@ -82,6 +82,10 @@
 {
   static dimension_type const dim = impl::Dim_of_view<ConstViewT>::dim;
 
+  typedef vsip::impl::dense_complex_type complex_type;
+  typedef Storage<complex_type, T>       storage_type;
+  typedef typename storage_type::type    ptr_type;
+
   // Compile-time constants.
 public:
   static symmetry_type const       symmtry = Symm;
@@ -143,7 +147,8 @@
 	   Matrix<T, Block1>)
     VSIP_NOTHROW;
 
-  typedef vsip::impl::Layout<1, row1_type, vsip::impl::Stride_unit, vsip::impl::Cmplx_inter_fmt> layout_type;
+  typedef vsip::impl::Layout<1, row1_type, vsip::impl::Stride_unit,
+			     complex_type> layout_type;
   typedef Vector<T> coeff_view_type;
   typedef impl::Ext_data<typename coeff_view_type::block_type, layout_type> c_ext_type;
 
@@ -151,13 +156,13 @@
 private:
   coeff_view_type coeff_;
   c_ext_type      coeff_ext_;
-  T*              pcoeff_;
+  ptr_type        pcoeff_;
 
   Domain<dim>     kernel_size_;
   Domain<dim>     input_size_;
   Domain<dim>     output_size_;
-  T*              in_buffer_;
-  T*              out_buffer_;
+  ptr_type        in_buffer_;
+  ptr_type        out_buffer_;
   length_type     decimation_;
 
   int             pm_non_opt_calls_;
@@ -196,14 +201,14 @@
     decimation_ (decimation),
     pm_non_opt_calls_ (0)
 {
-  in_buffer_  = new T[input_size_.size()];
-  if (in_buffer_ == NULL)
+  in_buffer_  = storage_type::allocate(input_size_.size());
+  if (storage_type::is_null(in_buffer_))
     VSIP_IMPL_THROW(std::bad_alloc());
 
-  out_buffer_ = new T[output_size_.size()];
-  if (out_buffer_ == NULL)
+  out_buffer_ = storage_type::allocate(output_size_.size());
+  if (storage_type::is_null(out_buffer_))
   {
-    delete[] in_buffer_;
+    storage_type::deallocate(in_buffer_);
     VSIP_IMPL_THROW(std::bad_alloc());
   }
 }
@@ -222,8 +227,8 @@
 ~Convolution_impl()
   VSIP_NOTHROW
 {
-  delete[] out_buffer_;
-  delete[] in_buffer_;
+  storage_type::deallocate(out_buffer_);
+  storage_type::deallocate(in_buffer_);
 }
 
 
@@ -251,8 +256,16 @@
 
   assert(P == out.size());
 
-  typedef vsip::impl::Ext_data<Block0> in_ext_type;
-  typedef vsip::impl::Ext_data<Block1> out_ext_type;
+  typedef typename Block_layout<Block0>::layout_type LP0;
+  typedef typename Block_layout<Block1>::layout_type LP1;
+
+  typedef Layout<1, Any_type, Any_type, complex_type> req_LP;
+
+  typedef typename Adjust_layout<T, req_LP, LP0>::type use_LP0;
+  typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
+
+  typedef vsip::impl::Ext_data_local<Block0, use_LP0>  in_ext_type;
+  typedef vsip::impl::Ext_data_local<Block1, use_LP1> out_ext_type;
 
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
@@ -260,8 +273,8 @@
   pm_in_ext_cost_  += in_ext.cost();
   pm_out_ext_cost_ += out_ext.cost();
 
-  T* pin    = in_ext.data();
-  T* pout   = out_ext.data();
+  ptr_type pin    = in_ext.data();
+  ptr_type pout   = out_ext.data();
 
   stride_type s_in  = in_ext.stride(0);
   stride_type s_out = out_ext.stride(0);
@@ -275,44 +288,53 @@
     {
       impl::sal::conv( pcoeff_, s_coeff, M, 
                        pin, s_in, N, 
-                       pout + (M - 1) * s_out, s_out );
+                       storage_type::offset(pout, (M - 1) * s_out),
+		       s_out );
 
       // fill in missing values
       for (index_type n = 0; n < M - 1; ++n )
       {
-        pout[n * s_out] = T();
+	T sum = T();
         for (index_type k = 0; k < M; ++k )
           if ( (n >= k) && (n - k < N) )
-            pout[n * s_out] += pcoeff_[k * s_coeff] * pin[(n - k) * s_in];
+	    sum += storage_type::get(pcoeff_, k * s_coeff) *
+	           storage_type::get(pin,     (n - k) * s_in);
+	storage_type::put(pout, n * s_out, sum);
       }
       for (index_type n = N; n < N + M - 1; ++n )
       {
-        pout[n * s_out] = T();
+	T sum = T();
         for (index_type k = 0; k < M; ++k )
           if ( (n >= k) && (n - k < N) )
-            pout[n * s_out] += pcoeff_[k * s_coeff] * pin[(n - k) * s_in];
+	    sum += storage_type::get(pcoeff_, k * s_coeff) *
+	           storage_type::get(pin,     (n - k) * s_in);
+	storage_type::put(pout, n * s_out, sum);
       }
     }
     else if (Supp == support_same)
     {
       impl::sal::conv( pcoeff_, s_coeff, M, 
                        pin, s_in, N - (M - M/2), 
-                       pout + (M - M/2 - 1) * s_out, s_out );
+                       storage_type::offset(pout, (M - M/2 - 1) * s_out), s_out );
 
       // fill in missing values
       for (index_type n = 0; n < M/2; ++n )
       {
-        pout[n * s_out] = T();
+	T sum = T();
         for (index_type k = 0; k < M; ++k )
           if ( (n + M/2 >= k) && (n + M/2 - k < N) )
-            pout[n * s_out] += pcoeff_[k * s_coeff] * pin[(n + M/2 - k) * s_in];
+	    sum += storage_type::get(pcoeff_, k * s_coeff) *
+	           storage_type::get(pin,     (n + M/2 - k) * s_in);
+	storage_type::put(pout, n * s_out, sum);
       }
       for (index_type n = N - (M - M/2); n < N; ++n )
       {
-        pout[n * s_out] = T();
+	T sum = T();
         for (index_type k = 0; k < M; ++k )
           if ( (n + M/2 >= k) && (n + M/2 - k < N) )
-            pout[n * s_out] += pcoeff_[k * s_coeff] * pin[(n + M/2 - k) * s_in];
+	    sum += storage_type::get(pcoeff_, k * s_coeff) *
+	           storage_type::get(pin,     (n + M/2 - k) * s_in);
+	storage_type::put(pout, n * s_out, sum);
       }
     }
     else // (Supp == support_min)
@@ -327,17 +349,17 @@
     if (Supp == support_full)
     {
       pm_non_opt_calls_++;
-      conv_full<T>(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
+      conv_full(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
     }
     else if (Supp == support_same)
     {
       pm_non_opt_calls_++;
-      conv_same<T>(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
+      conv_same(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
     }
     else // (Supp == support_min)
     {
       pm_non_opt_calls_++;
-      conv_min<T>(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
+      conv_min(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
     }
   }
 
Index: src/vsip/impl/signal-corr-opt.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-corr-opt.hpp,v
retrieving revision 1.2
diff -u -r1.2 signal-corr-opt.hpp
--- src/vsip/impl/signal-corr-opt.hpp	12 Dec 2005 17:47:50 -0000	1.2
+++ src/vsip/impl/signal-corr-opt.hpp	6 Mar 2006 04:31:07 -0000
@@ -343,7 +343,8 @@
 	out(Domain<1>(0, 1, M-1))     /= ramp(T(1), T(1), M-1);
 	out(Domain<1>(P-M+1, 1, M-1)) /= ramp(T(M-1), T(-1), M-1);
       }
-      out(Domain<1>(M-1, 1, P-2*M+2)) /= T(M);
+      if (P+2 > 2*M)
+	out(Domain<1>(M-1, 1, P-2*M+2)) /= T(M);
     }
     else if (Supp == support_same)
     {
@@ -354,7 +355,8 @@
 	out(Domain<1>(0, 1, edge))      /= ramp(T(M/2 + (M%2)), T(1), edge);
 	out(Domain<1>(P-edge, 1, edge)) /= ramp(T(M), T(-1), edge);
       }
-      out(Domain<1>(edge, 1, P - 2*edge)) /= T(M);
+      if (P > 2*edge)
+	out(Domain<1>(edge, 1, P - 2*edge)) /= T(M);
     }
     else // (Supp == support_min)
     {
Index: src/vsip/impl/signal-fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-fft.hpp,v
retrieving revision 1.33
diff -u -r1.33 signal-fft.hpp
--- src/vsip/impl/signal-fft.hpp	4 Mar 2006 23:03:30 -0000	1.33
+++ src/vsip/impl/signal-fft.hpp	6 Mar 2006 04:31:07 -0000
@@ -79,7 +79,7 @@
   bool use_fft_;        // use ipp[si]FFT* or ipp[si]DFT*
   bool doing_scaling_;  // scaling is performed in the driver.
   bool is_forward_;
-  void* p_buffer_;      // temporary storage not allocated in the plan
+  char* p_buffer_;      // temporary storage not allocated in the plan
   unsigned row_step_;    // length in bytes of 2D row.
 # endif
 #elif defined(VSIP_IMPL_SAL_FFT)
@@ -243,17 +243,17 @@
 // 
 
 template <typename View>
-View
+inline View
 empty_view_like(vsip::Domain<1> const& dom)
   { return View(dom[0].size()); } 
 
 template <typename View>
-View 
+inline View 
 empty_view_like(vsip::Domain<2> const& dom)
   { return View(dom[0].size(), dom[1].size()); }
 
 template <typename View>
-View  
+inline View  
 empty_view_like(vsip::Domain<3> const& dom)
   { return View(dom[0].size(), dom[1].size(), dom[2].size()); }
 
Index: tests/convolution.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/convolution.cpp,v
retrieving revision 1.10
diff -u -r1.10 convolution.cpp
--- tests/convolution.cpp	3 Mar 2006 14:30:53 -0000	1.10
+++ tests/convolution.cpp	6 Mar 2006 04:31:07 -0000
@@ -485,6 +485,7 @@
 
 #if VSIP_IMPL_TEST_LEVEL == 0
   cases<float>(true);
+  cases<complex<float> >(rand);
 #else
 
   // Regression: These cases trigger undefined behavior according to
Index: tests/counter.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/counter.cpp,v
retrieving revision 1.6
diff -u -r1.6 counter.cpp
--- tests/counter.cpp	20 Dec 2005 12:48:40 -0000	1.6
+++ tests/counter.cpp	6 Mar 2006 04:31:07 -0000
@@ -152,13 +152,16 @@
 int
 main(void)
 {
+#if VSIP_HAS_EXCEPTIONS
   try
   {
+#endif
     test_relational();
     test_addition();
     test_subtraction();
     test_under();
     test_over();
+#if VSIP_HAS_EXCEPTIONS
   }
   catch (std::exception& E)
   {
@@ -166,4 +169,5 @@
               << ": " << E.what() << std::endl;
     test_assert(0);
   }
+#endif
 }
Index: tests/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft.cpp,v
retrieving revision 1.14
diff -u -r1.14 fft.cpp
--- tests/fft.cpp	4 Mar 2006 23:03:30 -0000	1.14
+++ tests/fft.cpp	6 Mar 2006 04:31:07 -0000
@@ -407,6 +407,15 @@
   vsip::Domain<2> const& out_dom,
   int (& /* dum */)[1])
 {
+  assert(in.size(0) == ref.size(0));
+  assert(in.size(1) == ref.size(1));
+  assert(in.size(0) == in_dom[0].size());
+  assert(in.size(1) == in_dom[1].size());
+  assert(ref.size(0) == out_dom[0].size());
+  assert(ref.size(1) == out_dom[1].size());
+
+#if 0
+  // This is faster, but relies on correctness of Fftm.
   vsip::Fftm<std::complex<T>,std::complex<T>,0,
              vsip::fft_fwd,vsip::by_reference,1>  fftm_across(in_dom, 1.0);
   fftm_across(in, ref);
@@ -414,6 +423,17 @@
   vsip::Fftm<std::complex<T>,std::complex<T>,1,
              vsip::fft_fwd,vsip::by_reference,1>  fftm_down(out_dom, 1.0);
   fftm_down(ref);
+#else
+  // This is slower, but should always be correct.
+  for (index_type r=0; r<in.size(0); ++r)
+    ref::dft(in.row(r), ref.row(r), -1);
+  Vector<complex<T> > tmp(in.size(0));
+  for (index_type c=0; c<in.size(1); ++c)
+  {
+    tmp = ref.col(c);
+    ref::dft(tmp, ref.col(c), -1);
+  }
+#endif
 }
 
 // 2D, rc
@@ -630,6 +650,7 @@
 #if !defined(VSIP_IMPL_SAL_FFT)
   { 1, 1, 1 },
   { 2, 2, 1 },
+  { 2, 4, 8 },
   { 2, 8, 128 },
   { 3, 5, 7 },
   { 2, 24, 48 },
@@ -890,6 +911,8 @@
 // check 2D, 3D
 //
 
+#if VSIP_IMPL_TEST_LEVEL > 0
+
 #if defined(VSIP_IMPL_FFT_USE_FLOAT)
 
   test_fft<0,0,float,false,2,vsip::fft_fwd>();
@@ -1032,5 +1055,6 @@
 
 #endif
 
+#endif // VSIP_IMPL_TEST_LEVEL > 0
   return 0;
 }
Index: tests/fftm-par.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fftm-par.cpp,v
retrieving revision 1.6
diff -u -r1.6 fftm-par.cpp
--- tests/fftm-par.cpp	4 Mar 2006 23:03:30 -0000	1.6
+++ tests/fftm-par.cpp	6 Mar 2006 04:31:07 -0000
@@ -35,7 +35,7 @@
 #  define TEST_NON_REALCOMPLEX 0
 #  define TEST_NON_POWER_OF_2  0
 #else
-#  define TEST_NON_REALCOMPLEX 1
+#  define TEST_NON_REALCOMPLEX 0
 #  define TEST_NON_POWER_OF_2  1
 #endif
 
Index: tests/matvec.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/matvec.cpp,v
retrieving revision 1.6
diff -u -r1.6 matvec.cpp
--- tests/matvec.cpp	20 Dec 2005 12:48:41 -0000	1.6
+++ tests/matvec.cpp	6 Mar 2006 04:31:07 -0000
@@ -507,7 +507,9 @@
 
   modulate_cases<float>(10);
   modulate_cases<double>(32);
+#if VSIP_IMPL_HAVE_COMPLEX_LONG_DOUBLE
   modulate_cases<long double>(16);
+#endif
 
   Test_outer<float>( static_cast<float>(M_PI), 3, 3 );
   Test_outer<float>( static_cast<float>(M_PI), 5, 7 );
Index: tests/ref_dft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/ref_dft.hpp,v
retrieving revision 1.1
diff -u -r1.1 ref_dft.hpp
--- tests/ref_dft.hpp	4 Mar 2006 23:03:30 -0000	1.1
+++ tests/ref_dft.hpp	6 Mar 2006 04:31:07 -0000
@@ -54,23 +54,24 @@
 	  typename Block1,
 	  typename Block2>
 void dft(
-  vsip::Vector<T1, Block1> in,
-  vsip::Vector<T2, Block2> out,
-  int                      idir)
+  vsip::const_Vector<T1, Block1> in,
+  vsip::Vector<T2, Block2>       out,
+  int                            idir)
 {
   using vsip::length_type;
   using vsip::index_type;
 
   length_type const size = in.size();
-  assert(in.size() == out.size());
+  assert(sizeof(T1) <  sizeof(T2) && in.size()/2 + 1 == out.size() ||
+	 sizeof(T1) == sizeof(T2) && in.size() == out.size());
   typedef double AccT;
 
   AccT const phi = idir * 2.0 * M_PI/size;
 
-  for (index_type w=0; w<size; ++w)
+  for (index_type w=0; w<out.size(); ++w)
   {
     vsip::complex<AccT> sum = vsip::complex<AccT>();
-    for (index_type k=0; k<size; ++k)
+    for (index_type k=0; k<in.size(); ++k)
       sum += vsip::complex<AccT>(in(k)) * sin_cos<AccT>(phi*k*w);
     out.put(w, T2(sum));
   }
@@ -133,9 +134,9 @@
   vsip::Matrix<T, Block1> in,
   vsip::Matrix<vsip::complex<T>, Block2> out)
 {
-  test_assert(in.size(0) == out.size(0));
+  test_assert(in.size(0)/2 + 1 == out.size(0));
   test_assert(in.size(1) == out.size(1));
-  test_assert(in.local().size(0) == out.local().size(0));
+  test_assert(in.local().size(0)/2 + 1 == out.local().size(0));
   test_assert(in.local().size(1) == out.local().size(1));
 
   for (vsip::index_type c=0; c < in.local().size(1); ++c)
Index: tests/test.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/test.hpp,v
retrieving revision 1.15
diff -u -r1.15 test.hpp
--- tests/test.hpp	3 Mar 2006 14:30:53 -0000	1.15
+++ tests/test.hpp	6 Mar 2006 04:31:07 -0000
@@ -33,7 +33,9 @@
 //   1 - default
 //   2 - high-level (enable long-running tests)
 
-#define VSIP_IMPL_TEST_LEVEL 1
+#ifndef VSIP_IMPL_TEST_LEVEL
+#  define VSIP_IMPL_TEST_LEVEL 1
+#endif
 
 
 /// Compare two floating-point values for equality.
