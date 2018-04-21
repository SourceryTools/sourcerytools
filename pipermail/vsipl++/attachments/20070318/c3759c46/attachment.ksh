Index: ChangeLog
===================================================================
--- ChangeLog	(revision 166132)
+++ ChangeLog	(working copy)
@@ -1,5 +1,22 @@
-2007-03-16  Jules Bergmann  <jules@codesourcery.com>
+2007-03-18  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/cbe/ppu/fft.cpp (query_layout): Set pack type to
+	  16-byte stride_unit_dense.
+	* tests/regressions/fft_unaligned.cpp: New file, regression tests
+	  for unaligned Fft.
+	* tests/regressions/fftm_unaligned.cpp: New file, regression tests
+	  for unaligned Fftm.
+	
+	* tests/view_functions.cpp: Remove file, split test into ...
+	* tests/view_functions.hpp: New file, ... common bits.
+	* tests/view_functions_unary.cpp: New file ... unary tests.
+	* tests/view_functions_binary.cpp: New file, ... binary tests.
+	* tests/view_functions_ternary.cpp: New file ... ternary tests.
+	
+	* tests/parallel/fftm.cpp: Set VERBOSE to 0.
+	
+2007-03-17  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/core/fft/dft.hpp (name): New member function to aid Fft
 	  backend debugging.  Fix query_layout to give input and output same
 	  complex format.  Change DFT accumulation type to double to reduce
Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 166132)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -204,6 +204,20 @@
 
   virtual char const* name() { return "fft-cbe-1D-complex"; }
   virtual bool supports_scale() { return true;}
+  virtual void query_layout(Rt_layout<1> &rtl_inout)
+  {
+    rtl_inout.pack    = stride_unit_align;
+    rtl_inout.order   = tuple<0, 1, 2>();
+    rtl_inout.complex = cmplx_inter_fmt;
+    rtl_inout.align   = 16;
+  }
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  {
+    rtl_in.pack    = rtl_out.pack    = stride_unit_align;
+    rtl_in.order   = rtl_out.order   = tuple<0, 1, 2>();
+    rtl_in.complex = rtl_out.complex = cmplx_inter_fmt;
+    rtl_in.align   = rtl_out.align   = 16;
+  }
   virtual void in_place(ctype *inout, stride_type stride, length_type length)
   {
     assert(stride == 1);
@@ -326,8 +340,9 @@
       rtl_inout.order = tuple<0, 1, 2>();
     else
       rtl_inout.order = tuple<1, 0, 2>();
-    rtl_inout.pack = stride_unit;
+    rtl_inout.pack = stride_unit_align;
     rtl_inout.complex = cmplx_inter_fmt;
+    rtl_inout.align = 16;
   }
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
@@ -336,8 +351,9 @@
       rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
     else
       rtl_in.order = rtl_out.order = tuple<1, 0, 2>();
-    rtl_in.pack = rtl_out.pack = stride_unit;
+    rtl_in.pack = rtl_out.pack = stride_unit_align;
     rtl_in.complex = rtl_out.complex = cmplx_inter_fmt;
+    rtl_in.align = rtl_out.align = 16;
   }
 private:
   rtype scale_;
Index: tests/view_functions_binary.cpp
===================================================================
--- tests/view_functions_binary.cpp	(revision 0)
+++ tests/view_functions_binary.cpp	(revision 0)
@@ -0,0 +1,80 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/view_functions_binary.hpp
+    @author  Stefan Seefeld
+    @date    2005-03-16
+    @brief   VSIPL++ Library: Unit tests for binary View expressions.
+
+    This file contains unit tests for View expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <cassert>
+#include <complex>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/dense.hpp>
+#include <vsip/math.hpp>
+#include <vsip_csl/test.hpp>
+
+#include "view_functions.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+using namespace impl;
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsip::vsipl init(argc, argv);
+
+  TEST_BINARY(add, scalar_f, 2.f, 2.f)
+  TEST_BINARY(atan2, scalar_f, 0.5f, 0.5f)
+  TEST_BINARY(band, int, 2, 4)
+  TEST_BINARY(bor, int, 2, 4)
+  TEST_BINARY(bxor, int, 2, 4)
+  TEST_BINARY(div, scalar_f, 5.f, 2.f)
+  TEST_BINARY_RETN(eq, scalar_f, bool, 4.f, 4.f)
+  TEST_BINARY_RETN(eq, scalar_f, bool, 4.f, 3.f)
+  TEST_BINARY(fmod, scalar_f, 5.f, 2.f)
+  TEST_BINARY_RETN(ge, scalar_f, bool, 2.f, 5.f)
+  TEST_BINARY_RETN(ge, scalar_f, bool, 5.f, 2.f)
+  TEST_BINARY_RETN(gt, scalar_f, bool, 2.f, 5.f)
+  TEST_BINARY_RETN(gt, scalar_f, bool, 5.f, 2.f)
+  TEST_BINARY(jmul, cscalar_f, cscalar_f(5.f, 2.f), cscalar_f(2.f, 2.f))
+  TEST_BINARY_RETN(land, int, bool, 1, 2)
+  TEST_BINARY_RETN(land, int, bool, 1, 0)
+  TEST_BINARY_RETN(land, int, bool, 0, 2)
+  TEST_BINARY_RETN(le, scalar_f, bool, 2.f, 5.f)
+  TEST_BINARY_RETN(le, scalar_f, bool, 5.f, 2.f)
+  TEST_BINARY_RETN(lt, scalar_f, bool, 2.f, 5.f)
+  TEST_BINARY_RETN(lt, scalar_f, bool, 5.f, 2.f)
+  TEST_BINARY_RETN(lor, int, bool, 4, 2)
+  TEST_BINARY_RETN(lor, int, bool, 0, 2)
+  TEST_BINARY_RETN(lor, int, bool, 4, 0)
+  TEST_BINARY_RETN(lxor, int, bool, 4, 2)
+  TEST_BINARY_RETN(lxor, int, bool, 0, 2)
+  TEST_BINARY_RETN(lxor, int, bool, 4, 0)
+  TEST_BINARY(max, scalar_f, 4.f, 2.f)
+  TEST_BINARY(maxmg, scalar_f, 4.f, 2.f)
+  TEST_BINARY(maxmgsq, scalar_f, 4.f, 2.f)
+  TEST_BINARY(min, scalar_f, 4.f, 2.f)
+  TEST_BINARY(minmg, scalar_f, 4.f, 2.f)
+  TEST_BINARY(minmgsq, scalar_f, 4.f, 2.f)
+  TEST_BINARY(mul, scalar_f, 4.f, 2.f)
+  TEST_BINARY_RETN(ne, scalar_f, bool, 4.f, 4.f)
+  TEST_BINARY_RETN(ne, scalar_f, bool, 4.f, 3.f)
+  TEST_BINARY(pow, scalar_f, 4.f, 2.f)
+  TEST_BINARY(sub, scalar_f, 4.f, 2.f)
+}
Index: tests/view_functions.hpp
===================================================================
--- tests/view_functions.hpp	(revision 166043)
+++ tests/view_functions.hpp	(working copy)
@@ -1,10 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    tests/view_operators.cpp
+/** @file    tests/view_functions.hpp
     @author  Stefan Seefeld
     @date    2005-03-16
     @brief   VSIPL++ Library: Unit tests for View expressions.
@@ -12,6 +12,9 @@
     This file contains unit tests for View expressions.
 */
 
+#ifndef VSIP_TESTS_VIEW_FUNCTIONS_HPP
+#define VSIP_TESTS_VIEW_FUNCTIONS_HPP
+
 /***********************************************************************
   Included Files
 ***********************************************************************/
@@ -192,83 +195,4 @@
 TEST_SVS(name, type, value1, value2, value3)             \
 TEST_SSV(name, type, value1, value2, value3)
 
-
-int
-main()
-{
-
-  TEST_UNARY(acos, scalar_f, 0.5f)
-  TEST_UNARY_RETN(arg, cscalar_f, scalar_f, cscalar_f(4.f, 2.f))
-  TEST_UNARY(asin, scalar_f, 0.5f)
-  TEST_UNARY(atan, scalar_f, 0.5f)
-  TEST_UNARY(bnot, int, 4)
-  TEST_UNARY(ceil, scalar_f, 1.6f)
-  TEST_UNARY(conj, cscalar_f, 4.f)
-  TEST_UNARY(cos, scalar_f, 4.f)
-  TEST_UNARY(cosh, scalar_f, 4.f)
-  TEST_UNARY_RETN(euler, scalar_f, cscalar_f, 4.f)
-  TEST_UNARY(exp, scalar_f, 4.f)
-  TEST_UNARY(exp10, scalar_f, 4.f)
-  TEST_UNARY(floor, scalar_f, 4.f)
-  TEST_UNARY_RETN(imag, cscalar_f, scalar_f, cscalar_f(4.f, 2.f))
-  TEST_UNARY_RETN(lnot, int, bool, 4)
-  TEST_UNARY_RETN(lnot, int, bool, 0)
-  TEST_UNARY(log, scalar_f, 4.f)
-  TEST_UNARY(log10, scalar_f, 4.f)
-  TEST_UNARY(mag, scalar_f, -2.f)
-  TEST_UNARY(magsq, scalar_f, -2.f)
-  TEST_UNARY(neg, scalar_f, 4.f)
-  TEST_UNARY_RETN(real, cscalar_f, scalar_f, cscalar_f(4.f, 2.f))
-  TEST_UNARY(recip, scalar_f, 2.f)
-  TEST_UNARY(rsqrt, scalar_f, 2.f)
-  TEST_UNARY(sin, scalar_f, 2.f)
-  TEST_UNARY(sinh, scalar_f, 2.f)
-  TEST_UNARY(sq, scalar_f, 2.f)
-  TEST_UNARY(sqrt, scalar_f, 2.f)
-  TEST_UNARY(tan, scalar_f, 2.f)
-  TEST_UNARY(tanh, scalar_f, 2.f)
-
-  TEST_BINARY(add, scalar_f, 2.f, 2.f)
-  TEST_BINARY(atan2, scalar_f, 0.5f, 0.5f)
-  TEST_BINARY(band, int, 2, 4)
-  TEST_BINARY(bor, int, 2, 4)
-  TEST_BINARY(bxor, int, 2, 4)
-  TEST_BINARY(div, scalar_f, 5.f, 2.f)
-  TEST_BINARY_RETN(eq, scalar_f, bool, 4.f, 4.f)
-  TEST_BINARY_RETN(eq, scalar_f, bool, 4.f, 3.f)
-  TEST_BINARY(fmod, scalar_f, 5.f, 2.f)
-  TEST_BINARY_RETN(ge, scalar_f, bool, 2.f, 5.f)
-  TEST_BINARY_RETN(ge, scalar_f, bool, 5.f, 2.f)
-  TEST_BINARY_RETN(gt, scalar_f, bool, 2.f, 5.f)
-  TEST_BINARY_RETN(gt, scalar_f, bool, 5.f, 2.f)
-  TEST_BINARY(jmul, cscalar_f, cscalar_f(5.f, 2.f), cscalar_f(2.f, 2.f))
-  TEST_BINARY_RETN(land, int, bool, 1, 2)
-  TEST_BINARY_RETN(land, int, bool, 1, 0)
-  TEST_BINARY_RETN(land, int, bool, 0, 2)
-  TEST_BINARY_RETN(le, scalar_f, bool, 2.f, 5.f)
-  TEST_BINARY_RETN(le, scalar_f, bool, 5.f, 2.f)
-  TEST_BINARY_RETN(lt, scalar_f, bool, 2.f, 5.f)
-  TEST_BINARY_RETN(lt, scalar_f, bool, 5.f, 2.f)
-  TEST_BINARY_RETN(lor, int, bool, 4, 2)
-  TEST_BINARY_RETN(lor, int, bool, 0, 2)
-  TEST_BINARY_RETN(lor, int, bool, 4, 0)
-  TEST_BINARY_RETN(lxor, int, bool, 4, 2)
-  TEST_BINARY_RETN(lxor, int, bool, 0, 2)
-  TEST_BINARY_RETN(lxor, int, bool, 4, 0)
-  TEST_BINARY(max, scalar_f, 4.f, 2.f)
-  TEST_BINARY(maxmg, scalar_f, 4.f, 2.f)
-  TEST_BINARY(maxmgsq, scalar_f, 4.f, 2.f)
-  TEST_BINARY(min, scalar_f, 4.f, 2.f)
-  TEST_BINARY(minmg, scalar_f, 4.f, 2.f)
-  TEST_BINARY(minmgsq, scalar_f, 4.f, 2.f)
-  TEST_BINARY(mul, scalar_f, 4.f, 2.f)
-  TEST_BINARY_RETN(ne, scalar_f, bool, 4.f, 4.f)
-  TEST_BINARY_RETN(ne, scalar_f, bool, 4.f, 3.f)
-  TEST_BINARY(pow, scalar_f, 4.f, 2.f)
-  TEST_BINARY(sub, scalar_f, 4.f, 2.f)
-
-  TEST_TERNARY(am, scalar_f, 1.f, 2.f, 3.f)
-  TEST_TERNARY(ma, scalar_f, 1.f, 2.f, 3.f)
-  TEST_TERNARY(msb, scalar_f, 1.f, 2.f, 3.f)
-  TEST_TERNARY(sbm, scalar_f, 1.f, 2.f, 3.f)
-}
+#endif // VSIP_TESTS_VIEW_FUNCTIONS_HPP
Index: tests/regressions/fft_unaligned.cpp
===================================================================
--- tests/regressions/fft_unaligned.cpp	(revision 0)
+++ tests/regressions/fft_unaligned.cpp	(revision 0)
@@ -0,0 +1,106 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/fft_unaligned.cpp
+    @author  Jules Bergmann
+    @date    2007-03-16
+    @brief   VSIPL++ Library: Test Fft on unaligned views.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/signal.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Test FFT by-reference out-of-place with given alignment.
+
+template <typename T,
+	  typename ComplexFmt>
+void
+test_fft_op_align(length_type size, length_type align)
+{
+  typedef impl::Stride_unit_dense sud_type;
+  typedef impl::Layout<1, row1_type, sud_type, ComplexFmt> lp_type;
+
+  typedef impl::Fast_block<1, T, lp_type> block_type;
+
+  typedef Fft<const_Vector, T, T, fft_fwd, by_reference, 1, alg_space>
+	fft_type;
+
+  fft_type fft(Domain<1>(size), 1.f);
+
+  Vector<T, block_type> in (size + align);
+  Vector<T, block_type> out(size + align);
+
+  in = T(1);
+
+  fft(in(Domain<1>(align, 1, size)), out(Domain<1>(align, 1, size)));
+
+  test_assert(out.get(align) == T(size));
+}
+
+
+
+// Test FFT by-reference in-place with given alignment.
+
+template <typename T,
+	  typename ComplexFmt>
+void
+test_fft_ip_align(length_type size, length_type align)
+{
+  typedef impl::Stride_unit_dense sud_type;
+  typedef impl::Layout<1, row1_type, sud_type, ComplexFmt> lp_type;
+
+  typedef impl::Fast_block<1, T, lp_type> block_type;
+
+  typedef Fft<const_Vector, T, T, fft_fwd, by_reference, 1, alg_space>
+	fft_type;
+
+  fft_type fft(Domain<1>(size), 1.f);
+
+  Vector<T, block_type> inout(size + align);
+
+  inout = T(1);
+
+  fft(inout(Domain<1>(align, 1, size)));
+
+  test_assert(inout.get(align) == T(size));
+}
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_fft_op_align<complex<float>, impl::Cmplx_inter_fmt>(256, 0);
+  test_fft_op_align<complex<float>, impl::Cmplx_inter_fmt>(256, 1);
+
+  test_fft_ip_align<complex<float>, impl::Cmplx_inter_fmt>(256, 0);
+  test_fft_ip_align<complex<float>, impl::Cmplx_inter_fmt>(256, 1);
+
+  return 0;
+}
Index: tests/regressions/fftm_unaligned.cpp
===================================================================
--- tests/regressions/fftm_unaligned.cpp	(revision 0)
+++ tests/regressions/fftm_unaligned.cpp	(revision 0)
@@ -0,0 +1,129 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/fftm_unaligned.cpp
+    @author  Jules Bergmann
+    @date    2007-03-18
+    @brief   VSIPL++ Library: Test Fftm on unaligned views.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/signal.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// Test FFTM by-reference out-of-place with given alignment.
+
+// Requires
+//   ROWS to be the number of rows
+//   SIZE to be the number of elements per row.
+//   GAP to be the extra space between rows.
+//   ALIGN to be the alignment of the subview (ALIGN <= GAP)
+
+template <typename T,
+	  typename ComplexFmt>
+void
+test_fftm_op_align(
+  length_type rows,
+  length_type size,
+  length_type gap,
+  length_type align)
+{
+  typedef impl::Stride_unit_dense sud_type;
+  typedef impl::Layout<2, row2_type, sud_type, ComplexFmt> lp_type;
+
+  typedef impl::Fast_block<2, T, lp_type> block_type;
+
+  typedef Fftm<T, T, row, fft_fwd, by_reference, 1, alg_space> fftm_type;
+
+  fftm_type fftm(Domain<2>(rows, size), 1.f);
+
+  Matrix<T, block_type> in (rows, size + gap);
+  Matrix<T, block_type> out(rows, size + gap);
+
+  in = T(1);
+
+  fftm(in (Domain<2>(rows, Domain<1>(align, 1, size))),
+       out(Domain<2>(rows, Domain<1>(align, 1, size))));
+
+  for (index_type i=0; i<rows; ++i)
+    test_assert(out.get(i, align) == T(size));
+}
+
+
+
+// Test FFTM by-reference in-place with given alignment.
+
+// Requires
+//   ROWS to be the number of rows
+//   SIZE to be the number of elements per row.
+//   GAP to be the extra space between rows.
+//   ALIGN to be the alignment of the subview (ALIGN <= GAP)
+
+template <typename T,
+	  typename ComplexFmt>
+void
+test_fftm_ip_align(
+  length_type rows,
+  length_type size,
+  length_type gap,
+  length_type align)
+{
+  typedef impl::Stride_unit_dense sud_type;
+  typedef impl::Layout<2, row2_type, sud_type, ComplexFmt> lp_type;
+
+  typedef impl::Fast_block<2, T, lp_type> block_type;
+
+  typedef Fftm<T, T, row, fft_fwd, by_reference, 1, alg_space> fftm_type;
+
+  fftm_type fftm(Domain<2>(rows, size), 1.f);
+
+  Matrix<T, block_type> inout(rows, size + gap);
+
+  inout = T(1);
+
+  fftm(inout(Domain<2>(rows, Domain<1>(align, 1, size))));
+
+  for (index_type i=0; i<rows; ++i)
+    test_assert(inout.get(i, align) == T(size));
+}
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_fftm_op_align<complex<float>, impl::Cmplx_inter_fmt>(64, 256, 0, 0);
+  test_fftm_op_align<complex<float>, impl::Cmplx_inter_fmt>(64, 256, 1, 1);
+  test_fftm_op_align<complex<float>, impl::Cmplx_inter_fmt>(64, 256, 1, 0);
+
+  test_fftm_ip_align<complex<float>, impl::Cmplx_inter_fmt>(64, 256, 0, 0);
+  test_fftm_ip_align<complex<float>, impl::Cmplx_inter_fmt>(64, 256, 1, 1);
+  test_fftm_ip_align<complex<float>, impl::Cmplx_inter_fmt>(64, 256, 1, 0);
+
+  return 0;
+}
Index: tests/view_functions_ternary.cpp
===================================================================
--- tests/view_functions_ternary.cpp	(revision 0)
+++ tests/view_functions_ternary.cpp	(revision 0)
@@ -0,0 +1,46 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/view_functions_binary.hpp
+    @author  Stefan Seefeld
+    @date    2005-03-16
+    @brief   VSIPL++ Library: Unit tests for binary View expressions.
+
+    This file contains unit tests for View expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <cassert>
+#include <complex>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/dense.hpp>
+#include <vsip/math.hpp>
+#include <vsip_csl/test.hpp>
+
+#include "view_functions.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+using namespace impl;
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsip::vsipl init(argc, argv);
+
+  TEST_TERNARY(am, scalar_f, 1.f, 2.f, 3.f)
+  TEST_TERNARY(ma, scalar_f, 1.f, 2.f, 3.f)
+  TEST_TERNARY(msb, scalar_f, 1.f, 2.f, 3.f)
+  TEST_TERNARY(sbm, scalar_f, 1.f, 2.f, 3.f)
+}
Index: tests/view_functions_unary.cpp
===================================================================
--- tests/view_functions_unary.cpp	(revision 0)
+++ tests/view_functions_unary.cpp	(revision 0)
@@ -0,0 +1,73 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/view_functions_binary.hpp
+    @author  Stefan Seefeld
+    @date    2005-03-16
+    @brief   VSIPL++ Library: Unit tests for binary View expressions.
+
+    This file contains unit tests for View expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <cassert>
+#include <complex>
+#include <iostream>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/dense.hpp>
+#include <vsip/math.hpp>
+#include <vsip_csl/test.hpp>
+
+#include "view_functions.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+using namespace impl;
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsip::vsipl init(argc, argv);
+
+  TEST_UNARY(acos, scalar_f, 0.5f)
+  TEST_UNARY_RETN(arg, cscalar_f, scalar_f, cscalar_f(4.f, 2.f))
+  TEST_UNARY(asin, scalar_f, 0.5f)
+  TEST_UNARY(atan, scalar_f, 0.5f)
+  TEST_UNARY(bnot, int, 4)
+  TEST_UNARY(ceil, scalar_f, 1.6f)
+  TEST_UNARY(conj, cscalar_f, 4.f)
+  TEST_UNARY(cos, scalar_f, 4.f)
+  TEST_UNARY(cosh, scalar_f, 4.f)
+  TEST_UNARY_RETN(euler, scalar_f, cscalar_f, 4.f)
+  TEST_UNARY(exp, scalar_f, 4.f)
+  TEST_UNARY(exp10, scalar_f, 4.f)
+  TEST_UNARY(floor, scalar_f, 4.f)
+  TEST_UNARY_RETN(imag, cscalar_f, scalar_f, cscalar_f(4.f, 2.f))
+  TEST_UNARY_RETN(lnot, int, bool, 4)
+  TEST_UNARY_RETN(lnot, int, bool, 0)
+  TEST_UNARY(log, scalar_f, 4.f)
+  TEST_UNARY(log10, scalar_f, 4.f)
+  TEST_UNARY(mag, scalar_f, -2.f)
+  TEST_UNARY(magsq, scalar_f, -2.f)
+  TEST_UNARY(neg, scalar_f, 4.f)
+  TEST_UNARY_RETN(real, cscalar_f, scalar_f, cscalar_f(4.f, 2.f))
+  TEST_UNARY(recip, scalar_f, 2.f)
+  TEST_UNARY(rsqrt, scalar_f, 2.f)
+  TEST_UNARY(sin, scalar_f, 2.f)
+  TEST_UNARY(sinh, scalar_f, 2.f)
+  TEST_UNARY(sq, scalar_f, 2.f)
+  TEST_UNARY(sqrt, scalar_f, 2.f)
+  TEST_UNARY(tan, scalar_f, 2.f)
+  TEST_UNARY(tanh, scalar_f, 2.f)
+}
Index: tests/view_functions.cpp
===================================================================
--- tests/view_functions.cpp	(revision 166043)
+++ tests/view_functions.cpp	(working copy)
@@ -1,274 +0,0 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
-
-   This file is available for license from CodeSourcery, Inc. under the terms
-   of a commercial license and under the GPL.  It is not part of the VSIPL++
-   reference implementation and is not available under the BSD license.
-*/
-/** @file    tests/view_operators.cpp
-    @author  Stefan Seefeld
-    @date    2005-03-16
-    @brief   VSIPL++ Library: Unit tests for View expressions.
-
-    This file contains unit tests for View expressions.
-*/
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <cassert>
-#include <complex>
-#include <iostream>
-#include <vsip/vector.hpp>
-#include <vsip/matrix.hpp>
-#include <vsip/dense.hpp>
-#include <vsip/math.hpp>
-#include <vsip_csl/test.hpp>
-
-using namespace std;
-using namespace vsip;
-using namespace vsip_csl;
-using namespace impl;
-
-// Unary func(View) call.
-#define TEST_UNARY(func, type, value)		   \
-  {                                                \
-    Vector<type, Dense<1, type> > v1(3, value);    \
-    Vector<type, Dense<1, type> > v2 = func(v1);   \
-    test_assert(equal(v2.get(0), func(v1.get(0))));     \
-  }
-
-// Unary func(View) call.
-#define TEST_UNARY_RETN(func, type, retn, value)   \
-  {                                                \
-    Vector<type, Dense<1, type> > v1(3, value);    \
-    Vector<type, Dense<1, retn> > v2 = func(v1);   \
-    test_assert(equal(v2.get(0), func(v1.get(0))));     \
-  }
-
-// Binary func(View, View) call.
-#define TEST_VV(func, type, value1, value2)		  \
-  {                                                       \
-    Vector<type, Dense<1, type> > v1(2, value1);          \
-    Vector<type, Dense<1, type> > v2(2, value2);          \
-    Vector<type, Dense<1, type> > v3 = func(v1, v2);      \
-    test_assert(equal(v3.get(0), func(v1.get(0), v2.get(0)))); \
-  }
-
-// Binary func(View, View) call.
-#define TEST_VV_RETN(func, type, retn, value1, value2)    \
-  {                                                       \
-    Vector<type, Dense<1, type> > v1(2, value1);          \
-    Vector<type, Dense<1, type> > v2(2, value2);          \
-    Vector<retn, Dense<1, retn> > v3 = func(v1, v2);      \
-    test_assert(equal(v3.get(0), func(v1.get(0), v2.get(0)))); \
-  }
-
-// Binary func(View, Scalar) call.
-#define TEST_VS(func, type, value1, value2)               \
-  {                                                       \
-    Vector<type, Dense<1, type> > v1(2, value1);          \
-    Vector<type, Dense<1, type> > v2 = func(v1, value2);  \
-    test_assert(equal(v2.get(0), func(v1.get(0), value2)));    \
-  }
-
-// Binary func(View, Scalar) call.
-#define TEST_VS_RETN(func, type, retn, value1, value2)	  \
-  {                                                       \
-    Vector<type, Dense<1, type> > v1(2, value1);          \
-    Vector<retn, Dense<1, retn> > v2 = func(v1, value2);  \
-    test_assert(equal(v2.get(0), func(v1.get(0), value2)));    \
-  }
-
-// Binary func(Scalar, View) call.
-#define TEST_SV(func, type, value1, value2)               \
-  {                                                       \
-    Vector<type, Dense<1, type> > v1(2, value1);          \
-    Vector<type, Dense<1, type> > v2 = func(value2, v1);  \
-    test_assert(equal(v2.get(0), func(value2, v1.get(0))));    \
-  }
-
-// Binary func(Scalar, View) call.
-#define TEST_SV_RETN(func, type, retn, value1, value2)	  \
-  {                                                       \
-    Vector<type, Dense<1, type> > v1(2, value1);          \
-    Vector<retn, Dense<1, retn> > v2 = func(value2, v1);  \
-    test_assert(equal(v2.get(0), func(value2, v1.get(0))));    \
-  }
-
-// Ternary func(View, View, View) call.
-#define TEST_VVV(func, type, value1, value2, value3)	             \
-  {                                                                  \
-    Vector<type, Dense<1, type> > v1(2, value1);                     \
-    Vector<type, Dense<1, type> > v2(2, value2);                     \
-    Vector<type, Dense<1, type> > v3(2, value3);                     \
-    Vector<type, Dense<1, type> > v4 = func(v1, v2, v3);             \
-    test_assert(equal(v4.get(0), func(v1.get(0), v2.get(0), v3.get(0)))); \
-    test_assert(equal(v4.get(1), func(v1.get(1), v2.get(1), v3.get(1)))); \
-  }
-
-// Ternary func(Scalar, View, View) call.
-#define TEST_SVV(func, type, value1, value2, value3)                 \
-  {                                                                  \
-    type scalar = value1;                                            \
-    Vector<type, Dense<1, type> > v1(2, value2);                     \
-    Vector<type, Dense<1, type> > v2(2, value3);                     \
-    Vector<type, Dense<1, type> > v3 = func(scalar, v1, v2);         \
-    test_assert(equal(v3.get(0), func(scalar, v1.get(0), v2.get(0))));    \
-    test_assert(equal(v3.get(1), func(scalar, v1.get(1), v2.get(1))));    \
-  }
-
-// Ternary func(View, Scalar, View) call.
-#define TEST_VSV(func, type, value1, value2, value3)                 \
-  {                                                                  \
-    type scalar = value1;                                            \
-    Vector<type, Dense<1, type> > v1(2, value2);                     \
-    Vector<type, Dense<1, type> > v2(2, value3);                     \
-    Vector<type, Dense<1, type> > v3 = func(v1, scalar, v2);         \
-    test_assert(equal(v3.get(0), func(v1.get(0), scalar, v2.get(0))));    \
-    test_assert(equal(v3.get(1), func(v1.get(1), scalar, v2.get(1))));    \
-  }
-
-// Ternary func(View, View, Scalar) call.
-#define TEST_VVS(func, type, value1, value2, value3)                 \
-  {                                                                  \
-    type scalar = value1;                                            \
-    Vector<type, Dense<1, type> > v1(2, value2);                     \
-    Vector<type, Dense<1, type> > v2(2, value3);                     \
-    Vector<type, Dense<1, type> > v3 = func(v1, v2, scalar);         \
-    test_assert(equal(v3.get(0), func(v1.get(0), v2.get(0), scalar)));    \
-    test_assert(equal(v3.get(1), func(v1.get(1), v2.get(1), scalar)));    \
-  }
-
-// Ternary func(View, Scalar, Scalar) call.
-#define TEST_VSS(func, type, value1, value2, value3)                 \
-  {                                                                  \
-    type scalar1 = value1;                                           \
-    type scalar2 = value2;                                           \
-    Vector<type, Dense<1, type> > v(2, value3);                      \
-    Vector<type, Dense<1, type> > v2 = func(v, scalar1, scalar2);    \
-    test_assert(equal(v2.get(0), func(v.get(0), scalar1, scalar2)));      \
-    test_assert(equal(v2.get(1), func(v.get(1), scalar1, scalar2)));      \
-  }
-
-// Ternary func(Scalar, View, Scalar) call.
-#define TEST_SVS(func, type, value1, value2, value3)                 \
-  {                                                                  \
-    type scalar1 = value1;                                           \
-    type scalar2 = value2;                                           \
-    Vector<type, Dense<1, type> > v(2, value3);                      \
-    Vector<type, Dense<1, type> > v2 = func(scalar1, v, scalar2);    \
-    test_assert(equal(v2.get(0), func(scalar1, v.get(0), scalar2)));      \
-    test_assert(equal(v2.get(1), func(scalar1, v.get(1), scalar2)));      \
-  }
-
-// Ternary func(Scalar, Scalar, View) call.
-#define TEST_SSV(func, type, value1, value2, value3)                 \
-  {                                                                  \
-    type scalar1 = value1;                                           \
-    type scalar2 = value2;                                           \
-    Vector<type, Dense<1, type> > v(2, value3);                      \
-    Vector<type, Dense<1, type> > v2 = func(scalar1, scalar2, v);    \
-    test_assert(equal(v2.get(0), func(scalar1, scalar2, v.get(0))));      \
-    test_assert(equal(v2.get(1), func(scalar1, scalar2, v.get(1))));      \
-  }
-
-#define TEST_BINARY(name, type, value1, value2) \
-TEST_VV(name, type, value1, value2)             \
-TEST_VS(name, type, value1, value2)             \
-TEST_SV(name, type, value1, value2)
-
-#define TEST_BINARY_RETN(name, type, retn, value1, value2) \
-TEST_VV_RETN(name, type, retn, value1, value2)		   \
-TEST_VS_RETN(name, type, retn, value1, value2)		   \
-TEST_SV_RETN(name, type, retn, value1, value2)
-
-#define TEST_TERNARY(name, type, value1, value2, value3) \
-TEST_VVV(name, type, value1, value2, value3)             \
-TEST_SVV(name, type, value1, value2, value3)             \
-TEST_VSV(name, type, value1, value2, value3)             \
-TEST_VVS(name, type, value1, value2, value3)             \
-TEST_VSS(name, type, value1, value2, value3)             \
-TEST_SVS(name, type, value1, value2, value3)             \
-TEST_SSV(name, type, value1, value2, value3)
-
-
-int
-main()
-{
-
-  TEST_UNARY(acos, scalar_f, 0.5f)
-  TEST_UNARY_RETN(arg, cscalar_f, scalar_f, cscalar_f(4.f, 2.f))
-  TEST_UNARY(asin, scalar_f, 0.5f)
-  TEST_UNARY(atan, scalar_f, 0.5f)
-  TEST_UNARY(bnot, int, 4)
-  TEST_UNARY(ceil, scalar_f, 1.6f)
-  TEST_UNARY(conj, cscalar_f, 4.f)
-  TEST_UNARY(cos, scalar_f, 4.f)
-  TEST_UNARY(cosh, scalar_f, 4.f)
-  TEST_UNARY_RETN(euler, scalar_f, cscalar_f, 4.f)
-  TEST_UNARY(exp, scalar_f, 4.f)
-  TEST_UNARY(exp10, scalar_f, 4.f)
-  TEST_UNARY(floor, scalar_f, 4.f)
-  TEST_UNARY_RETN(imag, cscalar_f, scalar_f, cscalar_f(4.f, 2.f))
-  TEST_UNARY_RETN(lnot, int, bool, 4)
-  TEST_UNARY_RETN(lnot, int, bool, 0)
-  TEST_UNARY(log, scalar_f, 4.f)
-  TEST_UNARY(log10, scalar_f, 4.f)
-  TEST_UNARY(mag, scalar_f, -2.f)
-  TEST_UNARY(magsq, scalar_f, -2.f)
-  TEST_UNARY(neg, scalar_f, 4.f)
-  TEST_UNARY_RETN(real, cscalar_f, scalar_f, cscalar_f(4.f, 2.f))
-  TEST_UNARY(recip, scalar_f, 2.f)
-  TEST_UNARY(rsqrt, scalar_f, 2.f)
-  TEST_UNARY(sin, scalar_f, 2.f)
-  TEST_UNARY(sinh, scalar_f, 2.f)
-  TEST_UNARY(sq, scalar_f, 2.f)
-  TEST_UNARY(sqrt, scalar_f, 2.f)
-  TEST_UNARY(tan, scalar_f, 2.f)
-  TEST_UNARY(tanh, scalar_f, 2.f)
-
-  TEST_BINARY(add, scalar_f, 2.f, 2.f)
-  TEST_BINARY(atan2, scalar_f, 0.5f, 0.5f)
-  TEST_BINARY(band, int, 2, 4)
-  TEST_BINARY(bor, int, 2, 4)
-  TEST_BINARY(bxor, int, 2, 4)
-  TEST_BINARY(div, scalar_f, 5.f, 2.f)
-  TEST_BINARY_RETN(eq, scalar_f, bool, 4.f, 4.f)
-  TEST_BINARY_RETN(eq, scalar_f, bool, 4.f, 3.f)
-  TEST_BINARY(fmod, scalar_f, 5.f, 2.f)
-  TEST_BINARY_RETN(ge, scalar_f, bool, 2.f, 5.f)
-  TEST_BINARY_RETN(ge, scalar_f, bool, 5.f, 2.f)
-  TEST_BINARY_RETN(gt, scalar_f, bool, 2.f, 5.f)
-  TEST_BINARY_RETN(gt, scalar_f, bool, 5.f, 2.f)
-  TEST_BINARY(jmul, cscalar_f, cscalar_f(5.f, 2.f), cscalar_f(2.f, 2.f))
-  TEST_BINARY_RETN(land, int, bool, 1, 2)
-  TEST_BINARY_RETN(land, int, bool, 1, 0)
-  TEST_BINARY_RETN(land, int, bool, 0, 2)
-  TEST_BINARY_RETN(le, scalar_f, bool, 2.f, 5.f)
-  TEST_BINARY_RETN(le, scalar_f, bool, 5.f, 2.f)
-  TEST_BINARY_RETN(lt, scalar_f, bool, 2.f, 5.f)
-  TEST_BINARY_RETN(lt, scalar_f, bool, 5.f, 2.f)
-  TEST_BINARY_RETN(lor, int, bool, 4, 2)
-  TEST_BINARY_RETN(lor, int, bool, 0, 2)
-  TEST_BINARY_RETN(lor, int, bool, 4, 0)
-  TEST_BINARY_RETN(lxor, int, bool, 4, 2)
-  TEST_BINARY_RETN(lxor, int, bool, 0, 2)
-  TEST_BINARY_RETN(lxor, int, bool, 4, 0)
-  TEST_BINARY(max, scalar_f, 4.f, 2.f)
-  TEST_BINARY(maxmg, scalar_f, 4.f, 2.f)
-  TEST_BINARY(maxmgsq, scalar_f, 4.f, 2.f)
-  TEST_BINARY(min, scalar_f, 4.f, 2.f)
-  TEST_BINARY(minmg, scalar_f, 4.f, 2.f)
-  TEST_BINARY(minmgsq, scalar_f, 4.f, 2.f)
-  TEST_BINARY(mul, scalar_f, 4.f, 2.f)
-  TEST_BINARY_RETN(ne, scalar_f, bool, 4.f, 4.f)
-  TEST_BINARY_RETN(ne, scalar_f, bool, 4.f, 3.f)
-  TEST_BINARY(pow, scalar_f, 4.f, 2.f)
-  TEST_BINARY(sub, scalar_f, 4.f, 2.f)
-
-  TEST_TERNARY(am, scalar_f, 1.f, 2.f, 3.f)
-  TEST_TERNARY(ma, scalar_f, 1.f, 2.f, 3.f)
-  TEST_TERNARY(msb, scalar_f, 1.f, 2.f, 3.f)
-  TEST_TERNARY(sbm, scalar_f, 1.f, 2.f, 3.f)
-}
Index: tests/parallel/fftm.cpp
===================================================================
--- tests/parallel/fftm.cpp	(revision 166132)
+++ tests/parallel/fftm.cpp	(working copy)
@@ -33,7 +33,7 @@
 #include <vsip_csl/error_db.hpp>
 #include <vsip_csl/ref_dft.hpp>
 
-#define VERBOSE 1
+#define VERBOSE 0
 
 #if VSIP_IMPL_SAL_FFT
 #  define TEST_NON_REALCOMPLEX 0
