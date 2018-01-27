Index: ChangeLog
===================================================================
--- ChangeLog	(revision 186287)
+++ ChangeLog	(working copy)
@@ -1,3 +1,15 @@
+2007-11-02  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/signal/types.hpp (support_min_zeropad): New
+	  support_region_type.
+	* src/vsip_csl/img/impl/sfilt_common.hpp: New file, common
+	  separable filter functions and types.
+	* src/vsip_csl/img/impl/sfilt_ipp.hpp: New file, IPP BE for sfilt.
+	* src/vsip_csl/img/impl/sfilt_gen.hpp: New file, generic BE for sfilt.
+	* src/vsip_csl/img/separable_filter.hpp: New file, FE for sfilt.
+	* tests/vsip_csl/sfilt.cpp: New file, unit test for sfilt.
+	* benchmarks/sfilt.cpp: New file, benchmark for sfilt.
+
 2007-11-01  Jules Bergmann  <jules@codesourcery.com>
 	
 	* scripts/trunk-gpl-snapshot.cfg: Use 'csl/fftw/trunk' for FFTW.
Index: src/vsip/core/signal/types.hpp
===================================================================
--- src/vsip/core/signal/types.hpp	(revision 185668)
+++ src/vsip/core/signal/types.hpp	(working copy)
@@ -28,7 +28,8 @@
 {
   support_full,
   support_same,
-  support_min
+  support_min,
+  support_min_zeropad
 };
 
 enum symmetry_type
Index: src/vsip_csl/img/impl/sfilt_common.hpp
===================================================================
--- src/vsip_csl/img/impl/sfilt_common.hpp	(revision 0)
+++ src/vsip_csl/img/impl/sfilt_common.hpp	(revision 0)
@@ -0,0 +1,196 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip_csl/img/impl/sfilt_common.hpp
+    @author  Jules Bergmann
+    @date    2007-10-05
+    @brief   VSIPL++ Library: Generic separable filter.
+*/
+
+#ifndef VSIP_CSL_IMG_IMPL_SFILT_COMMON_HPP
+#define VSIP_CSL_IMG_IMPL_SFILT_COMMON_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/core/signal/types.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip_csl
+{
+
+namespace img
+{
+
+enum edge_handling_type
+{
+  edge_zero,
+  edge_mirror,
+  edge_wrap,
+  edge_scale
+};
+
+
+namespace impl
+{
+
+template <typename             ImplTag,
+	  vsip::dimension_type Dim,
+	  typename             T>
+struct Is_sfilt_impl_avail
+{
+  static bool const value = false;
+};
+
+
+
+template <typename                  T,
+	  vsip::support_region_type SuppT,
+	  edge_handling_type        EdgeT,
+	  unsigned                  n_times,
+          vsip::alg_hint_type       a_hint,
+	  typename                  ImplTag>
+class Sfilt_impl;
+
+
+inline vsip::Domain<2>
+sfilt_output_size(
+  vsip::support_region_type supp_ct,
+  vsip::Domain<2>           kernel_size,
+  vsip::Domain<2>           input_size)
+{
+  (void)kernel_size;
+  if (supp_ct == vsip::support_min_zeropad)
+    return input_size;
+  else
+    VSIP_IMPL_THROW(std::runtime_error(
+      "sfilt_output_size: support not implemented"));
+}
+
+
+
+// Separable filter, minimum support size, zero-pad output
+//
+// Operations:
+//   rows * (cols - nk0 + 1) * 2 * nk0 +
+//   cols * (rows - nk1 + 1) * 2 * nk1
+
+template <typename T>
+inline void
+sfilt_min_zeropad(
+  T const*          k0,		// coeff vector for 0-dim (stride 1)
+  vsip::length_type nk0,	// number of k0's
+  T const*          k1,		// coeff vector for 1-dim (stride 1)
+  vsip::length_type nk1,	// number of k1's
+
+  T*	            in,
+  vsip::stride_type in_row_stride,
+  vsip::stride_type in_col_stride,
+
+  T*          	    out,
+  vsip::stride_type out_row_stride,
+  vsip::stride_type out_col_stride,
+
+  T*                tmp,		// rows * cols
+
+  vsip::length_type rows,		// Pr
+  vsip::length_type cols)		// Pc
+{
+  assert(in_col_stride == 1);
+  using vsip::index_type;
+  using vsip::length_type;
+
+  length_type b_nk0 = (nk0)/2, e_nk0 = nk0 - b_nk0 - 1;
+  length_type b_nk1 = (nk1)/2, e_nk1 = nk1 - b_nk1 - 1;
+
+  T* ptmp = tmp;
+
+  // Filter horizontally along rows.
+  for (index_type r=0; r < rows; r++)
+  {
+    // 1D convolution
+    for (index_type c=b_nk1; c<cols-e_nk1; c++)  
+    {
+      T sum = T();
+      index_type i = c-b_nk1;
+      for (index_type j=0; j<nk1; j++)
+	sum += in[i+j] * k1[j];
+      tmp[c] = sum;
+    }
+
+    // Advance to next row.
+    tmp += cols;
+    in  += in_row_stride;	     
+  }
+
+  tmp = ptmp;
+
+  // Filter vertically along columns.
+
+  // Zero Top
+  for(index_type r = 0; r < b_nk0; r++)  
+    for(index_type c = 0; c < cols; c++)
+      out[r*out_row_stride + c] = 0;
+
+  // Zero Bottom
+  for(index_type r = rows-e_nk0; r < rows; r++)  
+    for(index_type c = 0; c < cols; c++)
+      out[r*out_row_stride+c] = 0;
+
+  // Zero LHS
+  for(index_type c = 0; c < b_nk1; c++)
+  {
+    for(index_type r = b_nk0; r < rows-e_nk0; r++)  
+      out[r*out_row_stride] = 0;
+    // Advance to next column.
+    tmp += 1;
+    out += out_col_stride;	  	  
+  }
+
+  for(index_type c = b_nk1; c < cols-e_nk1; c++)
+  {
+    // 1D convolution
+    for (index_type r = b_nk0; r<rows-e_nk0; r++)  
+    {
+      T sum = T();
+      index_type i = (r-b_nk0)*cols;
+      
+      for (index_type j=0; j<nk0; j++)
+	sum += tmp[i+j*cols]*k0[j];
+      out[r*out_row_stride] = sum;            
+    }
+
+    // Advance to next column.
+    tmp += 1;
+    out += out_col_stride;	  	  
+  }
+
+  // Zero RHS
+  for(index_type c = cols-e_nk1; c < cols; c++)
+  {
+    for(index_type r = b_nk0; r < rows-e_nk0; r++)  
+      out[r*out_row_stride] = 0;
+
+    // Advance to next column.
+    out += out_col_stride;	  	  
+  }
+}
+
+
+
+} // namespace vsip_csl::img::impl
+} // namespace vsip_csl::img
+} // namespace vsip
+
+#endif // VSIP_CSL_IMG_IMPL_SFILT_COMMON_HPP
Index: src/vsip_csl/img/impl/sfilt_ipp.hpp
===================================================================
--- src/vsip_csl/img/impl/sfilt_ipp.hpp	(revision 0)
+++ src/vsip_csl/img/impl/sfilt_ipp.hpp	(revision 0)
@@ -0,0 +1,348 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip_csl/img/impl/sfilt_ipp.hpp
+    @author  Jules Bergmann
+    @date    2007-10-08
+    @brief   VSIPL++ Library: IPP separable filter.
+*/
+
+#ifndef VSIP_CSL_IMG_IMPL_SFILT_IPP_HPP
+#define VSIP_CSL_IMG_IMPL_SFILT_IPP_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/core/domain_utils.hpp>
+#include <vsip/core/signal/types.hpp>
+#include <vsip/core/profile.hpp>
+#include <vsip/core/signal/conv_common.hpp>
+#include <vsip/core/extdata_dist.hpp>
+
+#include <vsip_csl/img/impl/sfilt_common.hpp>
+
+#include <ippi.h>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip_csl
+{
+
+namespace img
+{
+
+namespace impl
+{
+
+template <>
+struct Is_sfilt_impl_avail<vsip::impl::Intel_ipp_tag, 2, float>
+{
+  static bool const value = true;
+};
+
+/// Specialize Sfilt_impl for using ext data.
+
+template <typename                  T,
+	  vsip::support_region_type SuppT,
+	  edge_handling_type        EdgeT,
+	  unsigned                  n_times,
+          vsip::alg_hint_type       a_hint>
+class Sfilt_impl<T, SuppT, EdgeT, n_times, a_hint, vsip::impl::Intel_ipp_tag>
+{
+  static vsip::dimension_type const dim = 2;
+
+  // Compile-time constants.
+public:
+  static vsip::support_region_type const support_tv = SuppT;
+  static edge_handling_type        const edge_tv    = EdgeT;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  template <typename Block1,
+            typename Block2>
+  Sfilt_impl(
+    vsip::const_Vector<T, Block1>  coeff0,	// coeffs for dimension 0
+    vsip::const_Vector<T, Block2>  coeff1,	// coeffs for dimension 1
+    vsip::Domain<dim> const&       input_size)
+    VSIP_THROW((std::bad_alloc));
+
+  Sfilt_impl(Sfilt_impl const&) VSIP_NOTHROW;
+  Sfilt_impl& operator=(Sfilt_impl const&) VSIP_NOTHROW;
+  ~Sfilt_impl() VSIP_NOTHROW;
+
+  // Accessors.
+public:
+  vsip::Domain<dim> const& kernel_size() const VSIP_NOTHROW
+    { return kernel_size_; }
+  vsip::Domain<dim> const& filter_order() const VSIP_NOTHROW
+    { return kernel_size_; }
+  vsip::Domain<dim> const& input_size() const VSIP_NOTHROW
+    { return input_size_; }
+  vsip::Domain<dim> const& output_size() const VSIP_NOTHROW
+    { return output_size_; }
+  vsip::support_region_type support() const VSIP_NOTHROW
+    { return SuppT; }
+
+  float impl_performance(char const *what) const
+  {
+    if (!strcmp(what, "in_ext_cost"))        return pm_in_ext_cost_;
+    else if (!strcmp(what, "out_ext_cost"))  return pm_out_ext_cost_;
+    else if (!strcmp(what, "non-opt-calls")) return pm_non_opt_calls_;
+    else return 0.f;
+  }
+
+  // Implementation functions.
+protected:
+  template <typename Block0,
+	    typename Block1>
+  void
+  filter(vsip::const_Matrix<T, Block0>,
+	 vsip::Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  typedef vsip::impl::Layout<1,
+			     typename vsip::impl::Row_major<dim>::type,
+			     vsip::impl::Stride_unit,
+			     vsip::impl::Cmplx_inter_fmt>
+		layout_type;
+  typedef typename vsip::impl::View_of_dim<1, T, vsip::Dense<1, T> >::type
+		coeff_view_type;
+  typedef vsip::impl::Ext_data<typename coeff_view_type::block_type,
+			       layout_type>
+		c_ext_type;
+
+  // Member data.
+private:
+  coeff_view_type coeff0_;
+  coeff_view_type coeff1_;
+  c_ext_type      coeff0_ext_;
+  c_ext_type      coeff1_ext_;
+  T*              pcoeff0_;
+  T*              pcoeff1_;
+
+  vsip::Domain<dim>     kernel_size_;
+  vsip::Domain<dim>     input_size_;
+  vsip::Domain<dim>     output_size_;
+
+  T*              in_buffer_;
+  T*              out_buffer_;
+  T*              tmp_buffer_;
+
+  int             pm_non_opt_calls_;
+  size_t          pm_in_ext_cost_;
+  size_t          pm_out_ext_cost_;
+};
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+/// Construct a convolution object.
+
+template <typename            T,
+	  vsip::support_region_type SuppT,
+	  edge_handling_type  EdgeT,
+	  unsigned            n_times,
+          vsip::alg_hint_type       a_hint>
+template <typename Block1,
+	  typename Block2>
+Sfilt_impl<T, SuppT, EdgeT, n_times, a_hint, vsip::impl::Intel_ipp_tag>::
+Sfilt_impl(
+  vsip::const_Vector<T, Block1> coeff0,	// coeffs for dimension 0
+  vsip::const_Vector<T, Block2> coeff1,	// coeffs for dimension 1
+  vsip::Domain<dim> const&      input_size)
+VSIP_THROW((std::bad_alloc))
+  : coeff0_     (coeff0.size()),
+    coeff1_     (coeff1.size()),
+    coeff0_ext_ (coeff0_.block(), vsip::impl::SYNC_IN),
+    coeff1_ext_ (coeff1_.block(), vsip::impl::SYNC_IN),
+    pcoeff0_    (coeff0_ext_.data()),
+    pcoeff1_    (coeff1_ext_.data()),
+
+    kernel_size_(vsip::Domain<2>(coeff0.size(), coeff1.size())),
+    input_size_ (input_size),
+    output_size_(sfilt_output_size(SuppT, kernel_size_, input_size)),
+    pm_non_opt_calls_ (0)
+{
+  coeff0_ = coeff0(vsip::Domain<1>(coeff0.length()-1, -1, coeff0.length()));
+  coeff1_ = coeff1(vsip::Domain<1>(coeff1.length()-1, -1, coeff1.length()));
+
+  in_buffer_  = new T[input_size_.size()];
+  out_buffer_ = new T[output_size_.size()];
+  tmp_buffer_ = new T[output_size_.size()];
+}
+
+
+
+/// Destroy a generic Convolution_impl object.
+
+template <typename            T,
+	  vsip::support_region_type SuppT,
+	  edge_handling_type  EdgeT,
+	  unsigned            n_times,
+          vsip::alg_hint_type       a_hint>
+Sfilt_impl<T, SuppT, EdgeT, n_times, a_hint, vsip::impl::Intel_ipp_tag>::
+~Sfilt_impl()
+  VSIP_NOTHROW
+{
+  delete[] tmp_buffer_;
+  delete[] out_buffer_;
+  delete[] in_buffer_;
+}
+
+
+
+// Perform 2-D separable filter.
+
+template <typename            T,
+	  vsip::support_region_type SuppT,
+	  edge_handling_type  EdgeT,
+	  unsigned            n_times,
+          vsip::alg_hint_type       a_hint>
+template <typename Block0,
+	  typename Block1>
+void
+Sfilt_impl<T, SuppT, EdgeT, n_times, a_hint, vsip::impl::Intel_ipp_tag>::
+filter(
+  vsip::const_Matrix<T, Block0> in,
+  vsip::Matrix<T, Block1>       out)
+VSIP_NOTHROW
+{
+  using vsip::impl::Any_type;
+  using vsip::impl::SYNC_IN;
+  using vsip::impl::SYNC_OUT;
+  using vsip::index_type;
+  using vsip::length_type;
+  using vsip::stride_type;
+  using vsip::impl::Layout;
+  using vsip::impl::Ext_data_dist;
+  using vsip::impl::Block_layout;
+  using vsip::impl::Cmplx_inter_fmt;
+  using vsip::impl::Adjust_layout;
+
+  // PROFILE: Warn if arguments are not entirely on single processor
+  // (either as undistributed views or as local views of distr obj).
+
+  length_type const Mr = this->coeff0_.size();
+  length_type const Mc = this->coeff1_.size();
+
+  length_type const Nr = this->input_size_[0].size();
+  length_type const Nc = this->input_size_[1].size();
+
+  length_type const Pr = this->output_size_[0].size();
+  length_type const Pc = this->output_size_[1].size();
+
+  assert(Pr == out.size(0) && Pc == out.size(1));
+
+  typedef typename Block_layout<Block0>::layout_type LP0;
+  typedef typename Block_layout<Block1>::layout_type LP1;
+
+  typedef Layout<2, Any_type, Any_type, Cmplx_inter_fmt> req_LP;
+
+  typedef typename Adjust_layout<T, req_LP, LP0>::type use_LP0;
+  typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
+
+  typedef Ext_data_dist<Block0, SYNC_IN,  use_LP0>  in_ext_type;
+  typedef Ext_data_dist<Block1, SYNC_OUT, use_LP1> out_ext_type;
+
+  in_ext_type  in_ext (in.block(),  in_buffer_);
+  out_ext_type out_ext(out.block(), out_buffer_);
+
+  VSIP_IMPL_PROFILE(pm_in_ext_cost_  += in_ext.cost());
+  VSIP_IMPL_PROFILE(pm_out_ext_cost_ += out_ext.cost());
+
+  T* pin    = in_ext.data();
+  T* pout   = out_ext.data();
+
+  stride_type in_row_stride    = in_ext.stride(0);
+  stride_type in_col_stride    = in_ext.stride(1);
+  stride_type out_row_stride   = out_ext.stride(0);
+  stride_type out_col_stride   = out_ext.stride(1);
+
+  if (SuppT == vsip::support_full)
+  {
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Separable_filter IPP BE does not implement support_full"));
+  }
+  else if (SuppT == vsip::support_same)
+  {
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Separable_filter IPP BE does not implement support_same"));
+  }
+  else if (SuppT == vsip::support_min_zeropad)
+  {
+    assert(Nr == Pr && Nc == Pc);
+
+    if (in_col_stride == 1 && out_col_stride == 1)
+    {
+      index_type ro = Mr/2;
+      index_type co = Mc/2;
+
+      IppiSize tmp_size = { Pc, Pr - Mr + 1 };
+      ippiFilterColumn_32f_C1R(
+	pin + ro*in_row_stride,         in_row_stride  * sizeof(float),
+	tmp_buffer_ + ro*Pc, Pc * sizeof(float),
+	tmp_size,
+	pcoeff0_, Mr,
+	ro - (Mr % 2 == 0 ? 1 : 0));
+
+      IppiSize out_size = { Pc - Mc + 1, Pr - Mr + 1 };
+      ippiFilterRow_32f_C1R(
+	tmp_buffer_ + ro*Pc + co, Pc * sizeof(float),
+	pout + ro*out_row_stride + co, out_row_stride  * sizeof(float),
+	out_size,
+	pcoeff1_, Mc,
+	co - (Mc % 2 == 0 ? 1 : 0));
+
+      // Zero out boundary
+      for (index_type r=0; r<ro; ++r)
+	for (index_type c=0; c<Pc; ++c)
+	  pout[r*out_row_stride+c] = 0.;
+      for (index_type r=Pr-(Mr-ro-1); r<Pr; ++r)
+	for (index_type c=0; c<Pc; ++c)
+	  pout[r*out_row_stride+c] = 0.;
+
+      for (index_type c=0; c<co; ++c)
+	for (index_type r=0; r<Pr; ++r)
+	  pout[r*out_row_stride+c] = 0.;
+      for (index_type c=Pc-(Mc-co-1); c<Pc; ++c)
+	for (index_type r=0; r<Pr; ++r)
+	  pout[r*out_row_stride+c] = 0.;
+    }
+    else
+    {
+      sfilt_min_zeropad<T>(
+	pcoeff0_, Mr,
+	pcoeff1_, Mc,
+	pin,  in_row_stride, in_col_stride,
+	pout, out_row_stride, out_col_stride,
+	tmp_buffer_,
+	Nr, Nc);
+    }
+  }
+  else // (SuppT == support_min)
+  {
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Separable_filter IPP BE does not implement support_min"));
+  }
+}
+
+} // namespace vsip_csl::img::impl
+} // namespace vsip_csl::img
+} // namespace vsip
+
+#endif // VSIP_CSL_IMG_IMPL_SFILT_IPP_HPP
Index: src/vsip_csl/img/impl/sfilt_gen.hpp
===================================================================
--- src/vsip_csl/img/impl/sfilt_gen.hpp	(revision 0)
+++ src/vsip_csl/img/impl/sfilt_gen.hpp	(revision 0)
@@ -0,0 +1,315 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip_csl/img/impl/sfilt_gen.hpp
+    @author  Jules Bergmann
+    @date    2007-10-04
+    @brief   VSIPL++ Library: Generic separable filter.
+*/
+
+#ifndef VSIP_CSL_IMG_IMPL_SFILT_GEN_HPP
+#define VSIP_CSL_IMG_IMPL_SFILT_GEN_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/core/domain_utils.hpp>
+#include <vsip/core/signal/types.hpp>
+#include <vsip/core/profile.hpp>
+#include <vsip/core/signal/conv_common.hpp>
+#include <vsip/core/extdata_dist.hpp>
+
+#include <vsip_csl/img/impl/sfilt_common.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip_csl
+{
+
+namespace img
+{
+
+namespace impl
+{
+
+template <vsip::dimension_type Dim,
+	  typename             T>
+struct Is_sfilt_impl_avail<vsip::impl::Generic_tag, Dim, T>
+{
+  static bool const value = true;
+};
+
+
+
+/// Specialize Sfilt_impl for using ext data.
+
+template <typename                  T,
+	  vsip::support_region_type SuppT,
+	  edge_handling_type        EdgeT,
+	  unsigned                  n_times,
+          vsip::alg_hint_type       a_hint>
+class Sfilt_impl<T, SuppT, EdgeT, n_times, a_hint, vsip::impl::Generic_tag>
+{
+  static vsip::dimension_type const dim = 2;
+
+  // Compile-time constants.
+public:
+  static vsip::support_region_type const support_tv = SuppT;
+  static edge_handling_type        const edge_tv    = EdgeT;
+
+  // Constructors, copies, assignments, and destructors.
+public:
+  template <typename Block1,
+            typename Block2>
+  Sfilt_impl(
+    vsip::const_Vector<T, Block1>  coeff0,	// coeffs for dimension 0
+    vsip::const_Vector<T, Block2>  coeff1,	// coeffs for dimension 1
+    vsip::Domain<dim> const&       input_size)
+    VSIP_THROW((std::bad_alloc));
+
+  Sfilt_impl(Sfilt_impl const&) VSIP_NOTHROW;
+  Sfilt_impl& operator=(Sfilt_impl const&) VSIP_NOTHROW;
+  ~Sfilt_impl() VSIP_NOTHROW;
+
+  // Accessors.
+public:
+  vsip::Domain<dim> const& kernel_size() const VSIP_NOTHROW
+    { return kernel_size_; }
+  vsip::Domain<dim> const& filter_order() const VSIP_NOTHROW
+    { return kernel_size_; }
+  vsip::Domain<dim> const& input_size() const VSIP_NOTHROW
+    { return input_size_; }
+  vsip::Domain<dim> const& output_size() const VSIP_NOTHROW
+    { return output_size_; }
+  vsip::support_region_type support() const VSIP_NOTHROW
+    { return SuppT; }
+
+  float impl_performance(char const *what) const
+  {
+    if (!strcmp(what, "in_ext_cost"))        return pm_in_ext_cost_;
+    else if (!strcmp(what, "out_ext_cost"))  return pm_out_ext_cost_;
+    else if (!strcmp(what, "non-opt-calls")) return pm_non_opt_calls_;
+    else return 0.f;
+  }
+
+  // Implementation functions.
+protected:
+  template <typename Block0,
+	    typename Block1>
+  void
+  filter(vsip::const_Matrix<T, Block0>,
+	 vsip::Matrix<T, Block1>)
+    VSIP_NOTHROW;
+
+  typedef vsip::impl::Layout<1,
+			     typename vsip::impl::Row_major<dim>::type,
+			     vsip::impl::Stride_unit,
+			     vsip::impl::Cmplx_inter_fmt>
+		layout_type;
+  typedef typename vsip::impl::View_of_dim<1, T, vsip::Dense<1, T> >::type
+		coeff_view_type;
+  typedef vsip::impl::Ext_data<typename coeff_view_type::block_type,
+			       layout_type>
+		c_ext_type;
+
+  // Member data.
+private:
+  coeff_view_type   coeff0_;
+  coeff_view_type   coeff1_;
+  c_ext_type        coeff0_ext_;
+  c_ext_type        coeff1_ext_;
+  T*                pcoeff0_;
+  T*                pcoeff1_;
+
+  vsip::Domain<dim> kernel_size_;
+  vsip::Domain<dim> input_size_;
+  vsip::Domain<dim> output_size_;
+
+  T*                in_buffer_;
+  T*                out_buffer_;
+  T*                tmp_buffer_;
+
+  int               pm_non_opt_calls_;
+  size_t            pm_in_ext_cost_;
+  size_t            pm_out_ext_cost_;
+};
+
+
+
+/***********************************************************************
+  Utility Definitions
+***********************************************************************/
+
+
+
+/***********************************************************************
+  Utility Definitions
+***********************************************************************/
+
+/// Construct a convolution object.
+
+template <typename            T,
+	  vsip::support_region_type SuppT,
+	  edge_handling_type  EdgeT,
+	  unsigned            n_times,
+          vsip::alg_hint_type       a_hint>
+template <typename Block1,
+	  typename Block2>
+Sfilt_impl<T, SuppT, EdgeT, n_times, a_hint, vsip::impl::Generic_tag>::
+Sfilt_impl(
+  vsip::const_Vector<T, Block1> coeff0,	// coeffs for dimension 0
+  vsip::const_Vector<T, Block2> coeff1,	// coeffs for dimension 1
+  vsip::Domain<dim> const&      input_size)
+VSIP_THROW((std::bad_alloc))
+  : coeff0_     (coeff0.size()),
+    coeff1_     (coeff1.size()),
+    coeff0_ext_ (coeff0_.block(), vsip::impl::SYNC_IN),
+    coeff1_ext_ (coeff1_.block(), vsip::impl::SYNC_IN),
+    pcoeff0_    (coeff0_ext_.data()),
+    pcoeff1_    (coeff1_ext_.data()),
+
+    kernel_size_(vsip::Domain<2>(coeff0.size(), coeff1.size())),
+    input_size_ (input_size),
+    output_size_(sfilt_output_size(SuppT, kernel_size_, input_size)),
+    pm_non_opt_calls_ (0)
+{
+  coeff0_ = coeff0;
+  coeff1_ = coeff1;
+
+  in_buffer_  = new T[input_size_.size()];
+  out_buffer_ = new T[output_size_.size()];
+  tmp_buffer_ = new T[output_size_.size()];
+}
+
+
+
+/// Destroy a generic Convolution_impl object.
+
+template <typename            T,
+	  vsip::support_region_type SuppT,
+	  edge_handling_type  EdgeT,
+	  unsigned            n_times,
+          vsip::alg_hint_type       a_hint>
+Sfilt_impl<T, SuppT, EdgeT, n_times, a_hint, vsip::impl::Generic_tag>::
+~Sfilt_impl()
+  VSIP_NOTHROW
+{
+  delete[] tmp_buffer_;
+  delete[] out_buffer_;
+  delete[] in_buffer_;
+}
+
+
+
+// Perform 2-D separable filter.
+
+template <typename            T,
+	  vsip::support_region_type SuppT,
+	  edge_handling_type  EdgeT,
+	  unsigned            n_times,
+          vsip::alg_hint_type       a_hint>
+template <typename Block0,
+	  typename Block1>
+void
+Sfilt_impl<T, SuppT, EdgeT, n_times, a_hint, vsip::impl::Generic_tag>::
+filter(
+  vsip::const_Matrix<T, Block0> in,
+  vsip::Matrix<T, Block1>       out)
+VSIP_NOTHROW
+{
+  using vsip::impl::Any_type;
+  using vsip::impl::SYNC_IN;
+  using vsip::impl::SYNC_OUT;
+  using vsip::length_type;
+  using vsip::stride_type;
+  using vsip::impl::Layout;
+  using vsip::impl::Ext_data_dist;
+  using vsip::impl::Block_layout;
+  using vsip::impl::Cmplx_inter_fmt;
+  using vsip::impl::Adjust_layout;
+
+  // PROFILE: Warn if arguments are not entirely on single processor
+  // (either as undistributed views or as local views of distr obj).
+
+  length_type const Mr = this->coeff0_.size();
+  length_type const Mc = this->coeff1_.size();
+
+  length_type const Nr = this->input_size_[0].size();
+  length_type const Nc = this->input_size_[1].size();
+
+  length_type const Pr = this->output_size_[0].size();
+  length_type const Pc = this->output_size_[1].size();
+
+  assert(Pr == out.size(0) && Pc == out.size(1));
+
+  typedef typename Block_layout<Block0>::layout_type LP0;
+  typedef typename Block_layout<Block1>::layout_type LP1;
+
+  typedef Layout<2, Any_type, Any_type, Cmplx_inter_fmt> req_LP;
+
+  typedef typename Adjust_layout<T, req_LP, LP0>::type use_LP0;
+  typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
+
+  typedef Ext_data_dist<Block0, SYNC_IN,  use_LP0>  in_ext_type;
+  typedef Ext_data_dist<Block1, SYNC_OUT, use_LP1> out_ext_type;
+
+  in_ext_type  in_ext (in.block(),  in_buffer_);
+  out_ext_type out_ext(out.block(), out_buffer_);
+
+  VSIP_IMPL_PROFILE(pm_in_ext_cost_  += in_ext.cost());
+  VSIP_IMPL_PROFILE(pm_out_ext_cost_ += out_ext.cost());
+
+  T* pin    = in_ext.data();
+  T* pout   = out_ext.data();
+
+  stride_type in_row_stride    = in_ext.stride(0);
+  stride_type in_col_stride    = in_ext.stride(1);
+  stride_type out_row_stride   = out_ext.stride(0);
+  stride_type out_col_stride   = out_ext.stride(1);
+
+  if (SuppT == vsip::support_full)
+  {
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Separable_filter generic BE does not implement support_full"));
+  }
+  else if (SuppT == vsip::support_same)
+  {
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Separable_filter generic BE does not implement support_same"));
+  }
+  else if (SuppT == vsip::support_min_zeropad)
+  {
+    assert(Nr == Pr && Nc == Pc);
+
+    sfilt_min_zeropad<T>(
+      pcoeff0_, Mr,
+      pcoeff1_, Mc,
+      pin,  in_row_stride, in_col_stride,
+      pout, out_row_stride, out_col_stride,
+      tmp_buffer_,
+      Nr, Nc);
+  }
+  else // (SuppT == support_min)
+  {
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Separable_filter generic BE does not implement support_min"));
+  }
+}
+
+} // namespace vsip_csl::img::impl
+} // namespace vsip_csl::img
+} // namespace vsip
+
+#endif // VSIP_CSL_IMG_IMPL_SFILT_GEN_HPP
Index: src/vsip_csl/img/separable_filter.hpp
===================================================================
--- src/vsip_csl/img/separable_filter.hpp	(revision 0)
+++ src/vsip_csl/img/separable_filter.hpp	(revision 0)
@@ -0,0 +1,117 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip_csl/img/separable_filter.hpp
+    @author  Jules Bergmann
+    @date    2005-05-20
+    @brief   VSIPL++ Library: Image-processing separable filter.
+
+*/
+
+#ifndef VSIP_CSL_IMG_SEPARABLE_FILTER_HPP
+#define VSIP_CSL_IMG_SEPARABLE_FILTER_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/impl_tags.hpp>
+
+#include <vsip_csl/img/impl/sfilt_gen.hpp>
+#if VSIP_IMPL_HAVE_IPP
+#  include <vsip_csl/img/impl/sfilt_ipp.hpp>
+#endif
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip_csl
+{
+
+namespace img
+{
+
+namespace impl
+{
+
+template <vsip::dimension_type Dim,
+	  typename             T>
+struct Choose_sfilt_impl
+{
+  typedef vsip::impl::Intel_ipp_tag   Intel_ipp_tag;
+  typedef vsip::impl::Mercury_sal_tag Mercury_sal_tag;
+  typedef vsip::impl::Generic_tag     Generic_tag;
+
+  typedef typename
+  vsip::impl::ITE_Type<Is_sfilt_impl_avail<Intel_ipp_tag, Dim, T>::value,
+		       vsip::impl::As_type<Intel_ipp_tag>, 
+  vsip::impl::ITE_Type<Is_sfilt_impl_avail<Mercury_sal_tag, Dim, T>::value,
+		       vsip::impl::As_type<Mercury_sal_tag>, 
+		       vsip::impl::As_type<Generic_tag> > >::type type;
+};
+
+} // namespace vsip_csl::img::impl
+
+template <typename                  T,
+	  vsip::support_region_type SuppT,
+	  edge_handling_type        EdgeT,
+	  unsigned                  N_times = 0,
+	  vsip::alg_hint_type       A_hint = vsip::alg_time>
+class Separable_filter
+  : public impl::Sfilt_impl<T, SuppT, EdgeT, N_times, A_hint,
+			    typename impl::Choose_sfilt_impl<2, T>::type>
+{
+  typedef impl::Sfilt_impl<T, SuppT, EdgeT, N_times, A_hint,
+			   typename impl::Choose_sfilt_impl<2, T>::type>
+		base_type;
+  static vsip::dimension_type const dim = 2;
+
+// Constructors, copies, assignments, and destructor.
+public:
+  template <typename Block1,
+            typename Block2>
+  Separable_filter(
+    vsip::Vector<T, Block1> coeff0,	// coeffs for dimension 0
+    vsip::Vector<T, Block2> coeff1,	// coeffs for dimension 1
+    vsip::Domain<2> const&  input_size)
+  VSIP_THROW((std::bad_alloc))
+    : base_type(coeff0, coeff1, input_size)
+    {}
+
+  Separable_filter(Separable_filter const&) VSIP_NOTHROW;
+  Separable_filter& operator=(Separable_filter const&) VSIP_NOTHROW;
+  ~Separable_filter() VSIP_NOTHROW {}
+
+// Operator
+public:
+  template <typename Block1,
+            typename Block2>
+  vsip::Matrix<T, Block2>
+  operator()(
+    vsip::const_Matrix<T, Block1> in,
+    vsip::Matrix<T, Block2>       out)
+    VSIP_NOTHROW
+  {
+    filter(in, out);
+    return out;
+  }
+
+// Accessors
+public:
+  vsip::Domain<dim> const& kernel_size() const VSIP_NOTHROW;
+  vsip::Domain<dim> const& filter_order() const VSIP_NOTHROW;
+  vsip::Domain<dim> const& input_size() const VSIP_NOTHROW;
+  vsip::Domain<dim> const& output_size() const VSIP_NOTHROW;
+};
+
+} // namespace vsip_csl::img
+
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_IMG_SEPARABLE_FILTER_HPP
Index: tests/vsip_csl/sfilt.cpp
===================================================================
--- tests/vsip_csl/sfilt.cpp	(revision 0)
+++ tests/vsip_csl/sfilt.cpp	(revision 0)
@@ -0,0 +1,165 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/vsip_csl/sfilt.cpp
+    @author  Jules Bergmann
+    @date    2007-10-04
+    @brief   VSIPL++ Library: Extra unit tests for separable filters.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#define VERBOSE 0
+
+#if VERBOSE
+#  include <iostream>
+#endif
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/domain.hpp>
+#include <vsip/random.hpp>
+#include <vsip/signal.hpp>
+
+#include <vsip_csl/img/separable_filter.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/error_db.hpp>
+#if VERBOSE
+#  include <vsip_csl/output.hpp>
+#endif
+
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Definitions - Utility Functions
+***********************************************************************/
+
+template <typename Vector1T,
+	  typename Vector2T,
+	  typename MatrixT>
+void
+test_sfilt(
+  Vector1T k0,
+  Vector2T k1,
+  MatrixT  in)
+
+{
+  using vsip_csl::img::Separable_filter;
+  using vsip_csl::img::edge_zero;
+
+  typedef typename MatrixT::value_type T;
+
+  typedef Separable_filter<T, support_min_zeropad, edge_zero> filt_type;
+
+  length_type nk0  = k0.size();
+  length_type nk1  = k1.size();
+  length_type rows = in.size(0);
+  length_type cols = in.size(1);
+
+  filt_type filt(k0, k1, Domain<2>(rows, cols));
+
+  Matrix<T> out(rows, cols);
+
+  for (index_type r=0; r<rows; ++r)
+    in.row(r) = ramp<T>(r, 1, cols);
+
+  out = T(-1);
+
+  filt(in, out);
+
+
+  Matrix<T> ref_k(nk0, nk1);
+ 
+  for (index_type i=0; i<nk0; ++i)
+    for (index_type j=0; j<nk1; ++j)
+      ref_k(nk0-i-1, nk1-j-1) = k0(i) * k1(j);
+
+  typedef Convolution<const_Matrix, nonsym, support_min, T>
+    conv_type;
+
+  conv_type conv(ref_k, Domain<2>(rows, cols), 1);
+
+  Matrix<T> ref_out(rows, cols);
+  ref_out = T(); // zero-pad
+
+  conv(in, ref_out(Domain<2>(Domain<1>(nk0/2, 1, rows - nk0 + 1),
+			     Domain<1>(nk1/2, 1, cols - nk1 + 1))));
+
+  float error = error_db(out, ref_out);
+
+#if VERBOSE
+  std::cout << "error: " << error << std::endl;
+  if (error >= -100)
+  {
+    std::cout << "k0:\n" << k0;
+    std::cout << "k1:\n" << k1;
+    std::cout << "ref_k:\n" << ref_k;
+    std::cout << "out:\n" << out;
+    std::cout << "ref_out:\n" << ref_out;
+  }
+#endif
+
+  test_assert(error < -100);
+}
+
+template <typename T>
+void
+test_ident(
+  length_type nk0,
+  length_type nk1,
+  index_type  pk0,
+  index_type  pk1,
+  length_type rows,
+  length_type cols)
+{
+  Vector<T> k0(nk0);
+  Vector<T> k1(nk1);
+
+  k0 = T(); k0(pk0) = T(1);
+  k1 = T(); k1(pk1) = T(1);
+
+  Matrix<T> in (rows, cols);
+
+  test_sfilt(k0, k1, in);
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_ident<float>(3, 3, 0, 0, 16, 16);
+  test_ident<float>(4, 4, 0, 0, 16, 16);
+  test_ident<float>(5, 3, 0, 0, 16, 16);
+  test_ident<float>(3, 5, 0, 0, 16, 16);
+  test_ident<float>(5, 3, 1, 2, 16, 16);
+  test_ident<float>(3, 5, 1, 1, 16, 16);
+  test_ident<float>(5, 4, 0, 0, 16, 16);
+  test_ident<float>(4, 6, 0, 0, 16, 16);
+
+  test_ident<float>(3, 3, 0, 0, 16, 24);
+  test_ident<float>(4, 4, 0, 0, 16, 24);
+  test_ident<float>(5, 3, 0, 0, 16, 24);
+  test_ident<float>(3, 5, 0, 0, 16, 24);
+  test_ident<float>(5, 3, 1, 2, 16, 24);
+  test_ident<float>(3, 5, 1, 1, 16, 24);
+  test_ident<float>(5, 4, 0, 0, 16, 24);
+  test_ident<float>(4, 6, 0, 0, 16, 24);
+
+  test_ident<float>(3, 3, 0, 0, 15, 17);
+  test_ident<float>(4, 4, 0, 0, 17, 15);
+  test_ident<float>(5, 3, 0, 0, 15, 17);
+  test_ident<float>(3, 5, 0, 0, 15, 17);
+  test_ident<float>(5, 3, 1, 2, 15, 17);
+  test_ident<float>(3, 5, 1, 1, 15, 17);
+  test_ident<float>(5, 4, 0, 0, 15, 17);
+  test_ident<float>(4, 6, 0, 0, 15, 17);
+}
Index: benchmarks/sfilt.cpp
===================================================================
--- benchmarks/sfilt.cpp	(revision 0)
+++ benchmarks/sfilt.cpp	(revision 0)
@@ -0,0 +1,184 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    benchmarks/sfilt.cpp
+    @author  Jules Bergmann
+    @date    2007-10-08
+    @brief   VSIPL++ Library: Benchmark for 2D Separable Filter.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+#include <vsip/signal.hpp>
+
+#include <vsip_csl/img/separable_filter.hpp>
+
+#include <vsip/opt/diag/eval.hpp>
+
+#include <vsip_csl/test.hpp>
+#include "loop.hpp"
+
+using namespace vsip;
+using namespace vsip_csl::img;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <support_region_type Supp,
+	  typename            T>
+struct t_sfilt : Benchmark_base
+{
+  char* what() { return "t_sfilt"; }
+
+  void output_size(
+    length_type  rows,   length_type  cols,
+    length_type& o_rows, length_type& o_cols)
+  {
+    if      (Supp == support_full)
+    {
+      o_rows = (rows + m_ - 2) + 1;
+      o_cols = (cols + n_ - 2) + 1;
+    }
+    else if (Supp == support_same)
+    {
+      o_rows = (rows - 1) + 1;
+      o_cols = (cols - 1) + 1;
+    }
+    else if (Supp == support_min_zeropad)
+    {
+      o_rows = rows;
+      o_cols = cols;
+    }
+    else /* (Supp == support_min) */
+    {
+      o_rows = (rows-1) - (m_-1) + 1;
+      o_cols = (cols-1) - (n_-1) + 1;
+    }
+  }
+  
+  float ops_per_point(length_type cols)
+  {
+    length_type o_rows, o_cols;
+
+    output_size(rows_, cols, o_rows, o_cols);
+
+    float ops = 
+      ( (o_rows * o_cols * n_) +
+	(o_cols * o_rows * m_) ) *
+      (vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add);
+
+    return ops / cols;
+  }
+
+  int riob_per_point(length_type) { return -1; }
+  int wiob_per_point(length_type) { return -1; }
+  int mem_per_point(length_type)  { return 2*sizeof(T); }
+
+  void operator()(length_type cols, length_type loop, float& time)
+  {
+    length_type o_rows, o_cols;
+
+    output_size(rows_, cols, o_rows, o_cols);
+
+    Matrix<T>   in (rows_, cols, T());
+    Matrix<T>   out(o_rows, o_cols);
+    Vector<T>   coeff0(m_, T());
+    Vector<T>   coeff1(n_, T());
+
+    coeff0 = T(1);
+    coeff1 = T(1);
+
+    typedef Separable_filter<T, Supp, edge_zero> filt_type;
+
+    filt_type filt(coeff0, coeff1, Domain<2>(rows_, cols));
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      filt(in, out);
+    t1.stop();
+    
+    time = t1.delta();
+  }
+
+  t_sfilt(length_type rows, length_type m, length_type n)
+    : rows_(rows), m_(m), n_(n)
+  {}
+
+  void diag()
+  {
+    using vsip::impl::diag_detail::Dispatch_name;
+    typedef typename vsip_csl::img::impl::Choose_sfilt_impl<2, T>::type impl_tag;
+    std::cout << "BE: " << Dispatch_name<impl_tag>::name() << std::endl;
+  }
+
+  length_type rows_;
+  length_type m_;
+  length_type n_;
+};
+
+
+
+void
+defaults(Loop1P& loop)
+{
+  loop.loop_start_ = 5000;
+  loop.start_ = 4;
+
+  loop.param_["rows"] = "16";
+  loop.param_["mn"]   = "0";
+  loop.param_["m"]    = "3";
+  loop.param_["n"]    = "3";
+}
+
+
+
+int
+test(Loop1P& loop, int what)
+{
+  typedef complex<float> cf_type;
+
+  length_type rows = atoi(loop.param_["rows"].c_str());
+  length_type MN   = atoi(loop.param_["mn"].c_str());
+  length_type M    = atoi(loop.param_["m"].c_str());
+  length_type N    = atoi(loop.param_["n"].c_str());
+
+  if (MN != 0)
+    M = N = MN;
+
+  switch (what)
+  {
+  case  1: loop(t_sfilt<support_min_zeropad, float> (rows, M, N)); break;
+
+  case  0:
+    std::cout
+      << "sfilt -- Separable_filter\n"
+      << "   -1 -- float (min_zeropad)\n"
+      << "\n"
+      << "Parameters:\n"
+      << "   -p:m M       -- set filter size M (default 3)\n"
+      << "   -p:n N       -- set filter size N (default 3)\n"
+      << "   -p:mn MN     -- set filter sizes M and N at once\n"
+      << "   -p:rows ROWS -- set image rows (default 16)\n"
+      ;
+    
+
+  default: return 0;
+  }
+  return 1;
+}
