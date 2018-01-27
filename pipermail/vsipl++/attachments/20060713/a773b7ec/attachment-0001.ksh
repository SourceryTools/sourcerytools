Index: src/vsip/impl/profile.hpp
===================================================================
--- src/vsip/impl/profile.hpp	(revision 144534)
+++ src/vsip/impl/profile.hpp	(working copy)
@@ -339,14 +339,14 @@
 
 extern Profiler* prof;
 
-class Scope_enable
+class Profile
 {
 public:
-  Scope_enable(char *filename)
+  Profile(char *filename)
     : filename_(filename)
   { prof->set_mode( pm_accum ); }
 
-  ~Scope_enable() { prof->dump( this->filename_ ); }
+  ~ Profile() { prof->dump( this->filename_ ); }
 
 private:
   char* const filename_;
Index: src/vsip_csl/error_db.hpp
===================================================================
--- src/vsip_csl/error_db.hpp	(revision 0)
+++ src/vsip_csl/error_db.hpp	(revision 0)
@@ -0,0 +1,57 @@
+/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip_csl/error_db.cpp
+    @author  Jules Bergmann
+    @date    2005-12-12
+    @brief   VSIPL++ CodeSourcery Library: Measure difference between 
+             views in decibels.
+*/
+
+#ifndef VSIP_CSL_ERROR_DB_HPP
+#define VSIP_CSL_ERROR_DB_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/math.hpp>
+#include <vsip_csl/test.hpp>
+
+
+namespace vsip_csl
+{
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <template <typename, typename> class View1,
+	  template <typename, typename> class View2,
+	  typename                            T1,
+	  typename                            T2,
+	  typename                            Block1,
+	  typename                            Block2>
+inline double
+error_db(
+  View1<T1, Block1> v1,
+  View2<T2, Block2> v2)
+{
+  using vsip::impl::Dim_of_view;
+  using vsip::dimension_type;
+
+  test_assert(Dim_of_view<View1>::dim == Dim_of_view<View2>::dim);
+  dimension_type const dim = Dim_of_view<View2>::dim;
+
+  vsip::Index<dim> idx;
+
+  double refmax = maxval(magsq(v1), idx);
+  double maxsum = maxval(ite(magsq(v1 - v2) < 1.e-20,
+			     -201.0,
+			     10.0 * log10(magsq(v1 - v2)/(2.0*refmax)) ),
+			 idx);
+  return maxsum;
+}
+
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_ERROR_DB_HPP
Index: src/vsip_csl/ref_corr.hpp
===================================================================
--- src/vsip_csl/ref_corr.hpp	(revision 0)
+++ src/vsip_csl/ref_corr.hpp	(revision 0)
@@ -0,0 +1,236 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip_csl/ref_corr.cpp
+    @author  Jules Bergmann
+    @date    2005-12-09
+    @brief   VSIPL++ CodeSourcery Library: Reference implementation of 
+             correlation function.
+*/
+
+#ifndef VSIP_CSL_REF_CORR_HPP
+#define VSIP_CSL_REF_CORR_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/vector.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/random.hpp>
+#include <vsip/selgen.hpp>
+
+
+namespace vsip_csl
+{
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace ref
+{
+
+vsip::length_type
+corr_output_size(
+  vsip::support_region_type supp,
+  vsip::length_type         M,    // kernel length
+  vsip::length_type         N)    // input  length
+{
+  if      (supp == vsip::support_full)
+    return (N + M - 1);
+  else if (supp == vsip::support_same)
+    return N;
+  else //(supp == vsip::support_min)
+    return (N - M + 1);
+}
+
+
+
+vsip::stride_type
+expected_shift(
+  vsip::support_region_type supp,
+  vsip::length_type         M)     // kernel length
+{
+  if      (supp == vsip::support_full)
+    return -(M-1);
+  else if (supp == vsip::support_same)
+    return -(M/2);
+  else //(supp == vsip::support_min)
+    return 0;
+}
+
+
+
+template <typename T,
+	  typename Block1,
+	  typename Block2,
+	  typename Block3>
+void
+corr(
+  vsip::bias_type               bias,
+  vsip::support_region_type     sup,
+  vsip::const_Vector<T, Block1> ref,
+  vsip::const_Vector<T, Block2> in,
+  vsip::Vector<T, Block3>       out)
+{
+  using vsip::index_type;
+  using vsip::length_type;
+  using vsip::stride_type;
+  using vsip::Vector;
+  using vsip::Domain;
+  using vsip::unbiased;
+
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+
+  length_type M = ref.size(0);
+  length_type N = in.size(0);
+  length_type P = out.size(0);
+
+  length_type expected_P = corr_output_size(sup, M, N);
+  stride_type shift      = expected_shift(sup, M);
+
+  assert(expected_P == P);
+
+  Vector<T> sub(M);
+
+  // compute correlation
+  for (index_type i=0; i<P; ++i)
+  {
+    sub = T();
+    stride_type pos = static_cast<stride_type>(i) + shift;
+    scalar_type scale;
+
+    if (pos < 0)
+    {
+      sub(Domain<1>(-pos, 1, M + pos)) = in(Domain<1>(0, 1, M+pos));
+      scale = scalar_type(M + pos);
+    }
+    else if (pos + M > N)
+    {
+      sub(Domain<1>(0, 1, N-pos)) = in(Domain<1>(pos, 1, N-pos));
+      scale = scalar_type(N - pos);
+    }
+    else
+    {
+      sub = in(Domain<1>(pos, 1, M));
+      scale = scalar_type(M);
+    }
+      
+    T val = dot(ref, impl_conj(sub));
+    if (bias == vsip::unbiased)
+      val /= scale;
+
+    out(i) = val;
+  }
+}
+
+
+
+template <typename T,
+	  typename Block1,
+	  typename Block2,
+	  typename Block3>
+void
+corr(
+  vsip::bias_type               bias,
+  vsip::support_region_type     sup,
+  vsip::const_Matrix<T, Block1> ref,
+  vsip::const_Matrix<T, Block2> in,
+  vsip::Matrix<T, Block3>       out)
+{
+  using vsip::index_type;
+  using vsip::length_type;
+  using vsip::stride_type;
+  using vsip::Matrix;
+  using vsip::Domain;
+  using vsip::unbiased;
+
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+
+  length_type Mr = ref.size(0);
+  length_type Mc = ref.size(1);
+  length_type Nr = in.size(0);
+  length_type Nc = in.size(1);
+  length_type Pr = out.size(0);
+  length_type Pc = out.size(1);
+
+  length_type expected_Pr = corr_output_size(sup, Mr, Nr);
+  length_type expected_Pc = corr_output_size(sup, Mc, Nc);
+  stride_type shift_r     = expected_shift(sup, Mr);
+  stride_type shift_c     = expected_shift(sup, Mc);
+
+  assert(expected_Pr == Pr);
+  assert(expected_Pc == Pc);
+
+  Matrix<T> sub(Mr, Mc);
+  Domain<1> sub_dom_r;
+  Domain<1> sub_dom_c;
+  Domain<1> in_dom_r;
+  Domain<1> in_dom_c;
+
+  // compute correlation
+  for (index_type r=0; r<Pr; ++r)
+  {
+    stride_type pos_r = static_cast<stride_type>(r) + shift_r;
+
+    for (index_type c=0; c<Pc; ++c)
+    {
+
+      stride_type pos_c = static_cast<stride_type>(c) + shift_c;
+
+      scalar_type scale = scalar_type(1);
+
+      if (pos_r < 0)
+      {
+	sub_dom_r = Domain<1>(-pos_r, 1, Mr + pos_r); 
+	in_dom_r  = Domain<1>(0, 1, Mr+pos_r);
+	scale *= scalar_type(Mr + pos_r);
+      }
+      else if (pos_r + Mr > Nr)
+      {
+	sub_dom_r = Domain<1>(0, 1, Nr-pos_r);
+	in_dom_r  = Domain<1>(pos_r, 1, Nr-pos_r);
+	scale *= scalar_type(Nr - pos_r);
+      }
+      else
+      {
+	sub_dom_r = Domain<1>(0, 1, Mr);
+	in_dom_r  = Domain<1>(pos_r, 1, Mr);
+	scale *= scalar_type(Mr);
+      }
+
+      if (pos_c < 0)
+      {
+	sub_dom_c = Domain<1>(-pos_c, 1, Mc + pos_c); 
+	in_dom_c  = Domain<1>(0, 1, Mc+pos_c);
+	scale *= scalar_type(Mc + pos_c);
+      }
+      else if (pos_c + Mc > Nc)
+      {
+	sub_dom_c = Domain<1>(0, 1, Nc-pos_c);
+	in_dom_c  = Domain<1>(pos_c, 1, Nc-pos_c);
+	scale *= scalar_type(Nc - pos_c);
+      }
+      else
+      {
+	sub_dom_c = Domain<1>(0, 1, Mc);
+	in_dom_c  = Domain<1>(pos_c, 1, Mc);
+	scale *= scalar_type(Mc);
+      }
+
+      sub = T();
+      sub(Domain<2>(sub_dom_r, sub_dom_c)) = in(Domain<2>(in_dom_r, in_dom_c));
+      
+      T val = sumval(ref * impl_conj(sub));
+      if (bias == unbiased)
+	val /= scale;
+      
+      out(r, c) = val;
+    }
+  }
+}
+
+} // namespace ref
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_REF_CORR_HPP
Index: src/vsip_csl/ref_conv.hpp
===================================================================
--- src/vsip_csl/ref_conv.hpp	(revision 0)
+++ src/vsip_csl/ref_conv.hpp	(revision 0)
@@ -0,0 +1,182 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip_csl/ref_conv.cpp
+    @author  Jules Bergmann
+    @date    2005-12-28
+    @brief   VSIPL++ CodeSourcery Library: Reference implementation of 
+             convolution function.
+*/
+
+#ifndef VSIP_CSL_REF_CORR_HPP
+#define VSIP_CSL_REF_CORR_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/vector.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/random.hpp>
+#include <vsip/selgen.hpp>
+#include <vsip/parallel.hpp>
+
+
+namespace vsip_csl
+{
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace ref
+{
+
+vsip::length_type
+conv_output_size(
+  vsip::support_region_type supp,
+  vsip::length_type         M,    // kernel length
+  vsip::length_type         N,    // input  length
+  vsip::length_type         D)    // decimation factor
+{
+  if      (supp == vsip::support_full)
+    return ((N + M - 2)/D) + 1;
+  else if (supp == vsip::support_same)
+    return ((N - 1)/D) + 1;
+  else //(supp == vsip::support_min)
+  {
+#if VSIP_IMPL_CONV_CORRECT_MIN_SUPPORT_SIZE
+    return ((N - M + 1) / D) + ((N - M + 1) % D == 0 ? 0 : 1);
+#else
+    return ((N - 1)/D) - ((M-1)/D) + 1;
+#endif
+  }
+}
+
+
+
+vsip::stride_type
+conv_expected_shift(
+  vsip::support_region_type supp,
+  vsip::length_type         M)     // kernel length
+{
+  if      (supp == vsip::support_full)
+    return 0;
+  else if (supp == vsip::support_same)
+    return (M/2);
+  else //(supp == vsip::support_min)
+    return (M-1);
+}
+
+
+
+/// Generate full convolution kernel from coefficients.
+
+template <typename T,
+	  typename Block>
+vsip::Vector<T>
+kernel_from_coeff(
+  vsip::symmetry_type          symmetry,
+  vsip::const_Vector<T, Block> coeff)
+{
+  using vsip::Domain;
+  using vsip::length_type;
+
+  length_type M2 = coeff.size();
+  length_type M;
+
+  if (symmetry == vsip::nonsym)
+    M = coeff.size();
+  else if (symmetry == vsip::sym_even_len_odd)
+    M = 2*coeff.size()-1;
+  else /* (symmetry == vsip::sym_even_len_even) */
+    M = 2*coeff.size();
+
+  vsip::Vector<T> kernel(M, T());
+
+  if (symmetry == vsip::nonsym)
+  {
+    kernel = coeff;
+  }
+  else if (symmetry == vsip::sym_even_len_odd)
+  {
+    kernel(Domain<1>(0,  1, M2))   = coeff;
+    kernel(Domain<1>(M2, 1, M2-1)) = coeff(Domain<1>(M2-2, -1, M2-1));
+  }
+  else /* (symmetry == sym_even_len_even) */
+  {
+    kernel(Domain<1>(0,  1, M2)) = coeff;
+    kernel(Domain<1>(M2, 1, M2)) = coeff(Domain<1>(M2-1, -1, M2));
+  }
+
+  return kernel;
+}
+
+
+
+template <typename T,
+	  typename Block1,
+	  typename Block2,
+	  typename Block3>
+void
+conv(
+  vsip::symmetry_type           sym,
+  vsip::support_region_type     sup,
+  vsip::const_Vector<T, Block1> coeff,
+  vsip::const_Vector<T, Block2> in,
+  vsip::Vector<T, Block3>       out,
+  vsip::length_type             D)
+{
+  using vsip::index_type;
+  using vsip::length_type;
+  using vsip::stride_type;
+  using vsip::Vector;
+  using vsip::const_Vector;
+  using vsip::Domain;
+  using vsip::unbiased;
+
+  using vsip::impl::convert_to_local;
+  using vsip::impl::Working_view_holder;
+
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+
+  Working_view_holder<const_Vector<T, Block1> > w_coeff(coeff);
+  Working_view_holder<const_Vector<T, Block2> > w_in(in);
+  Working_view_holder<Vector<T, Block3> >       w_out(out);
+
+  Vector<T> kernel = kernel_from_coeff(sym, w_coeff.view);
+
+  length_type M = kernel.size(0);
+  length_type N = in.size(0);
+  length_type P = out.size(0);
+
+  length_type expected_P = conv_output_size(sup, M, N, D);
+  stride_type shift      = conv_expected_shift(sup, M);
+
+  assert(expected_P == P);
+
+  Vector<T> sub(M);
+
+  // Check result
+  for (index_type i=0; i<P; ++i)
+  {
+    sub = T();
+    index_type pos = i*D + shift;
+
+    if (pos+1 < M)
+      sub(Domain<1>(0, 1, pos+1)) = w_in.view(Domain<1>(pos, -1, pos+1));
+    else if (pos >= N)
+    {
+      index_type start = pos - N + 1;
+      sub(Domain<1>(start, 1, M-start)) = w_in.view(Domain<1>(N-1, -1, M-start));
+    }
+    else
+      sub = w_in.view(Domain<1>(pos, -1, M));
+      
+    w_out.view(i) = dot(kernel, sub);
+  }
+}
+
+} // namespace ref
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_REF_CORR_HPP
Index: src/vsip_csl/ref_dft.hpp
===================================================================
--- src/vsip_csl/ref_dft.hpp	(revision 0)
+++ src/vsip_csl/ref_dft.hpp	(revision 0)
@@ -0,0 +1,152 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip_csl/ref_dft.cpp
+    @author  Jules Bergmann
+    @date    2006-03-03
+    @brief   VSIPL++ CodeSourcery Library: Reference implementation of 
+             Discrete Fourier Transform function.
+*/
+
+#ifndef VSIP_CSL_REF_DFT_HPP
+#define VSIP_CSL_REF_DFT_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <cassert>
+
+#include <vsip/complex.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+
+
+namespace vsip_csl
+{
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace ref
+{
+
+/// Return sin and cos of phi as complex.
+
+template <typename T>
+inline vsip::complex<T>
+sin_cos(double phi)
+{
+  return vsip::complex<T>(cos(phi), sin(phi));
+}
+
+
+
+// Reference 1-D DFT algorithm.  Brutes it out, but easy to validate
+// and works for any size.
+
+// Requires:
+//   IN to be input Vector.
+//   OUT to be output Vector, of same size as IN.
+//   IDIR to be sign of exponential.
+//     -1 => Forward Fft,
+//     +1 => Inverse Fft.
+
+template <typename T1,
+	  typename T2,
+	  typename Block1,
+	  typename Block2>
+void dft(
+  vsip::const_Vector<T1, Block1> in,
+  vsip::Vector<T2, Block2>       out,
+  int                            idir)
+{
+  using vsip::length_type;
+  using vsip::index_type;
+
+  length_type const size = in.size();
+  assert(sizeof(T1) <  sizeof(T2) && in.size()/2 + 1 == out.size() ||
+	 sizeof(T1) == sizeof(T2) && in.size() == out.size());
+  typedef double AccT;
+
+  AccT const phi = idir * 2.0 * M_PI/size;
+
+  for (index_type w=0; w<out.size(); ++w)
+  {
+    vsip::complex<AccT> sum = vsip::complex<AccT>();
+    for (index_type k=0; k<in.size(); ++k)
+      sum += vsip::complex<AccT>(in(k)) * sin_cos<AccT>(phi*k*w);
+    out.put(w, T2(sum));
+  }
+}
+
+
+
+// Reference 1-D multi-DFT algorithm on rows of a matrix.
+
+// Requires:
+//   IN to be input Matrix.
+//   OUT to be output Matrix, of same size as IN.
+//   IDIR to be sign of exponential.
+//     -1 => Forward Fft,
+//     +1 => Inverse Fft.
+
+template <typename T,
+	  typename Block1,
+	  typename Block2>
+void dft_x(
+  vsip::Matrix<vsip::complex<T>, Block1> in,
+  vsip::Matrix<vsip::complex<T>, Block2> out,
+  int                                    idir)
+{
+  test_assert(in.size(0) == out.size(0));
+  test_assert(in.size(1) == out.size(1));
+  test_assert(in.local().size(0) == out.local().size(0));
+  test_assert(in.local().size(1) == out.local().size(1));
+
+  for (vsip::index_type r=0; r < in.local().size(0); ++r)
+    dft(in.local().row(r), out.local().row(r), idir);
+}
+
+
+
+// Reference 1-D multi-DFT algorithm on columns of a matrix.
+
+template <typename T,
+	  typename Block1,
+	  typename Block2>
+void dft_y(
+  vsip::Matrix<vsip::complex<T>, Block1> in,
+  vsip::Matrix<vsip::complex<T>, Block2> out,
+  int                                    idir)
+{
+  test_assert(in.size(0) == out.size(0));
+  test_assert(in.size(1) == out.size(1));
+  test_assert(in.local().size(0) == out.local().size(0));
+  test_assert(in.local().size(1) == out.local().size(1));
+
+  for (vsip::index_type c=0; c < in.local().size(1); ++c)
+    dft(in.local().col(c), out.local().col(c), idir);
+}
+
+
+template <typename T,
+	  typename Block1,
+	  typename Block2>
+void dft_y_real(
+  vsip::Matrix<T, Block1> in,
+  vsip::Matrix<vsip::complex<T>, Block2> out)
+{
+  test_assert(in.size(0)/2 + 1 == out.size(0));
+  test_assert(in.size(1) == out.size(1));
+  test_assert(in.local().size(0)/2 + 1 == out.local().size(0));
+  test_assert(in.local().size(1) == out.local().size(1));
+
+  for (vsip::index_type c=0; c < in.local().size(1); ++c)
+    dft(in.local().col(c), out.local().col(c), -1);
+}
+
+} // namespace ref
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_REF_DFT_HPP
Index: src/vsip_csl/ref_matvec.hpp
===================================================================
--- src/vsip_csl/ref_matvec.hpp	(revision 0)
+++ src/vsip_csl/ref_matvec.hpp	(revision 0)
@@ -0,0 +1,205 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip_csl/ref_matvec.hpp
+    @author  Jules Bergmann
+    @date    2005-10-11
+    @brief   VSIPL++ CodeSourcery Library: Reference implementations of 
+             matvec routines.
+*/
+
+#ifndef VSIP_CSL_REF_MATVEC_HPP
+#define VSIP_CSL_REF_MATVEC_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <cassert>
+
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+
+
+namespace vsip_csl
+{
+
+/***********************************************************************
+  Reference Definitions
+***********************************************************************/
+
+namespace ref
+{
+
+// Reference dot-product function.
+
+template <typename T0,
+	  typename T1,
+	  typename Block0,
+	  typename Block1>
+typename vsip::Promotion<T0, T1>::type
+dot(
+  vsip::const_Vector<T0, Block0> u,
+  vsip::const_Vector<T1, Block1> v)
+{
+  typedef typename vsip::Promotion<T0, T1>::type return_type;
+
+  assert(u.size() == v.size());
+
+  return_type sum = return_type();
+
+  for (vsip::index_type i=0; i<u.size(); ++i)
+    sum += u.get(i) * v.get(i);
+
+  return sum;
+}
+
+
+
+// Reference outer-product functions.
+
+template <typename T0,
+	  typename T1,
+	  typename Block0,
+	  typename Block1>
+vsip::Matrix<typename vsip::Promotion<T0, T1>::type>
+outer(
+  vsip::const_Vector<T0, Block0> u,
+  vsip::const_Vector<T1, Block1> v)
+{
+  typedef typename vsip::Promotion<T0, T1>::type return_type;
+
+  vsip::Matrix<return_type> r(u.size(), v.size());
+
+  for (vsip::index_type i=0; i<u.size(); ++i)
+    for (vsip::index_type j=0; j<v.size(); ++j)
+      // r(i, j) = u(i) * v(j);
+      r.put(i, j, u.get(i) * v.get(j));
+
+  return r;
+}
+
+template <typename T0,
+	  typename T1,
+	  typename Block0,
+	  typename Block1>
+vsip::Matrix<typename vsip::Promotion<std::complex<T0>, std::complex<T1> >::type>
+outer(
+  vsip::const_Vector<std::complex<T0>, Block0> u,
+  vsip::const_Vector<std::complex<T1>, Block1> v)
+{
+  typedef typename vsip::Promotion<std::complex<T0>, std::complex<T1> >::type return_type;
+
+  vsip::Matrix<return_type> r(u.size(), v.size());
+
+  for (vsip::index_type i=0; i<u.size(); ++i)
+    for (vsip::index_type j=0; j<v.size(); ++j)
+      // r(i, j) = u(i) * v(j);
+      r.put(i, j, u.get(i) * conj(v.get(j)));
+
+  return r;
+}
+
+
+// Reference vector-vector product
+
+template <typename T0,
+	  typename T1,
+	  typename Block0,
+	  typename Block1>
+vsip::Matrix<typename vsip::Promotion<T0, T1>::type>
+vv_prod(
+  vsip::const_Vector<T0, Block0> u,
+  vsip::const_Vector<T1, Block1> v)
+{
+  typedef typename vsip::Promotion<T0, T1>::type return_type;
+
+  vsip::Matrix<return_type> r(u.size(), v.size());
+
+  for (vsip::index_type i=0; i<u.size(); ++i)
+    for (vsip::index_type j=0; j<v.size(); ++j)
+      // r(i, j) = u(i) * v(j);
+      r.put(i, j, u.get(i) * v.get(j));
+
+  return r;
+}
+
+
+
+
+// Reference matrix-matrix product function (using vv-product).
+
+template <typename T0,
+	  typename T1,
+	  typename Block0,
+	  typename Block1>
+vsip::Matrix<typename vsip::Promotion<T0, T1>::type>
+prod(
+  vsip::const_Matrix<T0, Block0> a,
+  vsip::const_Matrix<T1, Block1> b)
+{
+  typedef typename vsip::Promotion<T0, T1>::type return_type;
+
+  assert(a.size(1) == b.size(0));
+
+  vsip::Matrix<return_type> r(a.size(0), b.size(1), return_type());
+
+  for (vsip::index_type k=0; k<a.size(1); ++k)
+    r += ref::vv_prod(a.col(k), b.row(k));
+
+  return r;
+}
+
+
+// Reference matrix-vector product function (using dot-product).
+
+template <typename T0,
+	  typename T1,
+	  typename Block0,
+	  typename Block1>
+vsip::Vector<typename vsip::Promotion<T0, T1>::type>
+prod(
+  vsip::const_Matrix<T0, Block0> a,
+  vsip::const_Vector<T1, Block1> b)
+{
+  typedef typename vsip::Promotion<T0, T1>::type return_type;
+
+  assert(a.size(1) == b.size(0));
+
+  vsip::Vector<return_type> r(a.size(0), return_type());
+
+  for (vsip::index_type k=0; k<a.size(0); ++k)
+    r.put( k, ref::dot(a.row(k), b) );
+
+  return r;
+}
+
+
+// Reference vector-matrix product function (using dot-product).
+
+template <typename T0,
+	  typename T1,
+	  typename Block0,
+	  typename Block1>
+vsip::Vector<typename vsip::Promotion<T0, T1>::type>
+prod(
+  vsip::const_Vector<T1, Block1> a,
+  vsip::const_Matrix<T0, Block0> b)
+{
+  typedef typename vsip::Promotion<T0, T1>::type return_type;
+
+  assert(a.size(0) == b.size(0));
+
+  vsip::Vector<return_type> r(b.size(1), return_type());
+
+  for (vsip::index_type k=0; k<b.size(1); ++k)
+    r.put( k, ref::dot(a, b.col(k)) );
+
+  return r;
+}
+
+
+
+} // namespace ref
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_REF_MATVEC_HPP
Index: vendor/GNUmakefile.inc.in
===================================================================
--- vendor/GNUmakefile.inc.in	(revision 144534)
+++ vendor/GNUmakefile.inc.in	(working copy)
@@ -171,9 +171,10 @@
 
 clean::
 	@echo "Cleaning FFTW (see fftw.clean.log)"
-	@for ldir in $(subst /.libs/,,$(dir $(vendor_FFTW_LIBS))); do \
-	  echo "$(MAKE) -C $$ldir clean "; \
-	  $(MAKE) -C $$ldir clean; done  > fftw.clean.log 2>&1
+	@rm -f fftw.clean.log
+	@for ldir in $(subst .a,,$(subst lib/lib,,$(vendor_FFTW_LIBS))); do \
+	  $(MAKE) -C vendor/$$ldir clean >> fftw.clean.log 2>&1; \
+	  echo "$(MAKE) -C vendor/$$ldir clean "; done
 
 install:: $(vendor_FFTW_LIBS)
 	@echo "Installing FFTW"
Index: examples/fft.cpp
===================================================================
--- examples/fft.cpp	(revision 144534)
+++ examples/fft.cpp	(working copy)
@@ -24,7 +24,6 @@
   Definitions
 ***********************************************************************/
 
-using namespace std;
 using namespace vsip;
 using namespace vsip_csl;
 
@@ -36,38 +35,34 @@
 void
 fft_example()
 {
-  typedef Fft<const_Vector, cscalar_f, cscalar_f, fft_fwd, by_value, 1, alg_space>
-	f_fft_type;
-  typedef Fft<const_Vector, cscalar_f, cscalar_f, fft_inv, by_value, 1, alg_space>
-	i_fft_type;
-  typedef impl::Cmplx_inter_fmt Complex_format;
+  typedef Fft<const_Vector, cscalar_f, cscalar_f, fft_fwd> f_fft_type;
+  typedef Fft<const_Vector, cscalar_f, cscalar_f, fft_inv> i_fft_type;
 
+  // Create FFT objects
   vsip::length_type N = 1024;
-
   f_fft_type f_fft(Domain<1>(N), 1.0);
   i_fft_type i_fft(Domain<1>(N), 1.0/N);
 
-
-  Vector<cscalar_f> in(N, cscalar_f());
+  // Allocate input and output buffers
+  Vector<cscalar_f> in(N);
+  Vector<cscalar_f> inv(N);
   Vector<cscalar_f> out(N);
   Vector<cscalar_f> ref(N);
-  Vector<cscalar_f> inv(N);
 
-  for ( int n = 0; n < N; ++n )
-    in(n) = sin( 2 * M_PI * n / N );
+  // Create input test data
+  for ( int i = 0; i < N; ++i )
+    in(i) = sin(2 * M_PI * i / N);
 
+  // Compute discrete transform (for reference)
   ref::dft(in, ref, -1);
   
-//  for ( int i = 0; i < 1000; ++i ) {
+  // Compute forward and inverse FFT's
   out = f_fft(in);
-//  }
   inv = i_fft(out);
   
+  // Validate the results (allowing for small numerical errors)
   test_assert(error_db(ref, out) < -100);
-//  test_assert(error_db(inv, in) < -100);
-
-  cout << "fwd = " << f_fft.impl_performance("mflops") << " mflops" << endl;
-  cout << "inv = " << i_fft.impl_performance("mflops") << " mflops" << endl;
+  test_assert(error_db(inv, in) < -100);
 }
 
 
@@ -76,11 +71,9 @@
 {
   vsipl init;
   
-  impl::profile::prof->set_mode( impl::profile::pm_accum );
+  impl::profile::Profile profile("/dev/stdout");
 
   fft_example();
 
-  impl::profile::prof->dump( "/dev/stdout" );
-
   return 0;
 }
Index: examples/GNUmakefile.inc.in
===================================================================
--- examples/GNUmakefile.inc.in	(revision 144534)
+++ examples/GNUmakefile.inc.in	(working copy)
@@ -1,4 +1,4 @@
-########################################################################
+######################################################### -*-Makefile-*-
 #
 # File:   GNUmakefile.inc.in
 # Author: Mark Mitchell 
@@ -34,6 +34,10 @@
 
 examples: $(examples_cxx_exes)
 
+# Object files will be deleted by the parent clean rule.
+clean::
+	rm -f $(examples_cxx_exes)
+
 install::
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)
 	$(INSTALL_DATA) $(examples_cxx_sources) $(DESTDIR)$(pkgdatadir)
