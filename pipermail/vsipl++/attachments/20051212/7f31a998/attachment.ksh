Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.331
diff -c -p -r1.331 ChangeLog
*** ChangeLog	7 Dec 2005 19:22:05 -0000	1.331
--- ChangeLog	12 Dec 2005 13:41:00 -0000
***************
*** 1,3 ****
--- 1,24 ----
+ 2005-12-12 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	Implement 2-D correlation.
+ 	* src/vsip/impl/signal-corr-common.hpp: Extend Is_corr_impl_avail
+ 	  to include dimension.  Compute unbiased scaling factor directly
+ 	  rather than by accumulation.  Implement 2-D correlation.
+ 	* src/vsip/impl/signal-corr-ext.hpp: Implement 2-D correlation.
+ 	* src/vsip/impl/signal-corr-opt.hpp: Update Is_corr_impl_avail.
+ 	* src/vsip/impl/signal-corr.hpp: Implement 2-D correlation.
+ 	* tests/corr-2d.cpp: New file, tests for 2-D correlation.
+ 	* tests/correlation.cpp: Move common functionality into error_db
+ 	  and ref_corr headers.
+ 	* tests/error_db.hpp: New file, common impl of error_db function.
+ 	* tests/ref_corr.hpp: New file, reference implementation of 1-D
+ 	  and 2-D correlation.
+ 	* tests/test.hpp (test_assert): New macro for assertions, not
+ 	  disabled by NDEBUG.
+ 
+ 	* src/vsip/impl/fns_scalar.hpp: Add scalar ite.
+ 	* src/vsip/impl/fns_elementwise.hpp: Add element-wise ite.
+ 
  2005-12-06  Don McCoy  <don@codesourcery.com>
  
  	* src/vsip/signal-window.cpp: replaced ramp, clip and frequency
Index: src/vsip/impl/fns_elementwise.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fns_elementwise.hpp,v
retrieving revision 1.16
diff -c -p -r1.16 fns_elementwise.hpp
*** src/vsip/impl/fns_elementwise.hpp	17 Nov 2005 12:58:39 -0000	1.16
--- src/vsip/impl/fns_elementwise.hpp	12 Dec 2005 13:41:01 -0000
*************** VSIP_IMPL_TERNARY_FUNC(expoavg)
*** 371,376 ****
--- 371,377 ----
  VSIP_IMPL_TERNARY_FUNC(ma)
  VSIP_IMPL_TERNARY_FUNC(msb)
  VSIP_IMPL_TERNARY_FUNC(sbm)
+ VSIP_IMPL_TERNARY_FUNC(ite)
  
  /***********************************************************************
    Unary Operators
Index: src/vsip/impl/fns_scalar.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fns_scalar.hpp,v
retrieving revision 1.14
diff -c -p -r1.14 fns_scalar.hpp
*** src/vsip/impl/fns_scalar.hpp	11 Nov 2005 19:18:52 -0000	1.14
--- src/vsip/impl/fns_scalar.hpp	12 Dec 2005 13:41:01 -0000
*************** using std::imag;
*** 108,113 ****
--- 108,117 ----
  
  template <typename T>
  inline T 
+ ite(bool pred, T a, T b) VSIP_NOTHROW { return pred ? a : b;}
+ 
+ template <typename T>
+ inline T 
  lnot(T t) VSIP_NOTHROW { return !t;}
  
  namespace abs_detail
Index: src/vsip/impl/signal-corr-common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-corr-common.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 signal-corr-common.hpp
*** src/vsip/impl/signal-corr-common.hpp	7 Oct 2005 13:46:46 -0000	1.1
--- src/vsip/impl/signal-corr-common.hpp	12 Dec 2005 13:41:01 -0000
*************** template <template <typename, typename> 
*** 44,51 ****
            typename                            ImplTag>
  class Correlation_impl;
  
! template <typename ImplTag,
! 	  typename T>
  struct Is_corr_impl_avail
  {
    static bool const value = false;
--- 44,52 ----
            typename                            ImplTag>
  class Correlation_impl;
  
! template <typename       ImplTag,
! 	  dimension_type Dim,
! 	  typename       T>
  struct Is_corr_impl_avail
  {
    static bool const value = false;
*************** struct Correlation_accum_trait
*** 61,70 ****
  
  
  /***********************************************************************
!   Definitions
  ***********************************************************************/
  
! /// Perform convolution with full region of support.
  
  template <typename T>
  inline void
--- 62,71 ----
  
  
  /***********************************************************************
!   1-D Definitions
  ***********************************************************************/
  
! /// Perform 1-D correlation with full region of support.
  
  template <typename T>
  inline void
*************** corr_full(
*** 80,91 ****
    length_type out_size,		// P
    stride_type out_stride)
  {
    typedef typename Correlation_accum_trait<T>::sum_type sum_type;
  
    for (index_type n=0; n<out_size; ++n)
    {
      sum_type sum   = sum_type();
-     sum_type scale = sum_type();
        
      for (index_type k=0; k<ref_size; ++k)
      {
--- 81,93 ----
    length_type out_size,		// P
    stride_type out_stride)
  {
+   assert(ref_size <= in_size);
+ 
    typedef typename Correlation_accum_trait<T>::sum_type sum_type;
  
    for (index_type n=0; n<out_size; ++n)
    {
      sum_type sum   = sum_type();
        
      for (index_type k=0; k<ref_size; ++k)
      {
*************** corr_full(
*** 94,111 ****
        if (n+k >= (ref_size-1) && n+k < in_size+(ref_size-1))
        {
  	sum += ref[k * ref_stride] * impl_conj(in[pos * in_stride]);
- 	scale += sum_type(1);
        }
      }
      if (bias == unbiased)
!       sum /= scale;
      out[n * out_stride] = sum;
    }
  }
  
  
  
! /// Perform convolution with same region of support.
  
  template <typename T>
  inline void
--- 96,121 ----
        if (n+k >= (ref_size-1) && n+k < in_size+(ref_size-1))
        {
  	sum += ref[k * ref_stride] * impl_conj(in[pos * in_stride]);
        }
      }
+ 
      if (bias == unbiased)
!     {
!       if (n < ref_size-1)
! 	sum /= sum_type(n+1);
!       else if (n >= in_size)
! 	sum /= sum_type(in_size + ref_size - 1 - n);
!       else
! 	sum /= sum_type(ref_size);
!     }
!       
      out[n * out_stride] = sum;
    }
  }
  
  
  
! /// Perform 1-D correlation with same region of support.
  
  template <typename T>
  inline void
*************** corr_same(
*** 126,132 ****
    for (index_type n=0; n<out_size; ++n)
    {
      sum_type sum   = sum_type();
-     sum_type scale = sum_type();
        
      for (index_type k=0; k<ref_size; ++k)
      {
--- 136,141 ----
*************** corr_same(
*** 135,152 ****
        if (n+k >= (ref_size/2) && n+k <  in_size + (ref_size/2))
        {
  	sum += ref[k * ref_stride] * impl_conj(in[pos * in_stride]);
- 	scale += sum_type(1);
        }
      }
      if (bias == unbiased)
!       sum /= scale;
      out[n * out_stride] = sum;
    }
  }
  
  
  
! /// Perform convolution with minimal region of support.
  
  template <typename T>
  inline void
--- 144,171 ----
        if (n+k >= (ref_size/2) && n+k <  in_size + (ref_size/2))
        {
  	sum += ref[k * ref_stride] * impl_conj(in[pos * in_stride]);
        }
      }
      if (bias == unbiased)
!     {
!       if (n < ref_size/2)
! 	sum /= sum_type(n + ((ref_size+1)/2));
!       else if (n >= in_size - (ref_size/2))
!       {
! 	sum /= sum_type(in_size + (ref_size/2) - n);
! 	// Definition in C-VSIPL:
! 	// sum /= sum_type(in_size /*- 1*/ + ((ref_size/*+1*/)/2) - n);
!       }
!       else
! 	sum /= sum_type(ref_size);
!     }
      out[n * out_stride] = sum;
    }
  }
  
  
  
! /// Perform correlation with minimal region of support.
  
  template <typename T>
  inline void
*************** corr_min(
*** 182,187 ****
--- 201,393 ----
  
  
  
+ /***********************************************************************
+   2-D Definitions
+ ***********************************************************************/
+ 
+ /// Perform 2-D correlation with full region of support.
+ 
+ template <typename T>
+ inline void
+ corr_base(
+   bias_type   bias,
+ 
+   T*          ref,
+   length_type ref_rows,		// Mr
+   length_type ref_cols,		// Mc
+   stride_type ref_row_stride,
+   stride_type ref_col_stride,
+ 
+   length_type row_shift,
+   length_type col_shift,
+   length_type row_edge,
+   length_type col_edge,
+ 
+   T*          in,
+   length_type in_rows,		// Nr
+   length_type in_cols,		// Nc
+   stride_type in_row_stride,
+   stride_type in_col_stride,
+ 
+   T*          out,
+   length_type out_rows,		// Pr
+   length_type out_cols,		// Pc
+   stride_type out_row_stride,
+   stride_type out_col_stride)
+ {
+   assert(ref_rows <= in_rows);
+   assert(ref_cols <= in_cols);
+ 
+   typedef typename Correlation_accum_trait<T>::sum_type sum_type;
+ 
+   for (index_type r=0; r<out_rows; ++r)
+   {
+     for (index_type c=0; c<out_cols; ++c)
+     {
+       sum_type sum   = sum_type();
+       
+       for (index_type rr=0; rr<ref_rows; ++rr)
+       {
+ 	for (index_type cc=0; cc<ref_cols; ++cc)
+ 	{
+ 	  index_type rpos = r + rr - row_shift;
+ 	  index_type cpos = c + cc - col_shift;
+ 
+ 	  if (r+rr >= row_shift && r+rr < in_rows+row_shift &&
+ 	      c+cc >= col_shift && c+cc < in_cols+col_shift)
+ 	  {
+ 	    sum += ref[rr * ref_row_stride + cc * ref_col_stride] *
+                    impl_conj(in[rpos * in_row_stride + cpos * in_col_stride]);
+ 	  }
+ 	}
+       }
+ 
+       if (bias == unbiased)
+       {
+ 	sum_type scale = sum_type(1);
+ 
+ 	if (r < row_shift)     scale *= sum_type(r+ (ref_rows-row_shift));
+ 	else if (r >= in_rows - row_edge)
+                                scale *= sum_type(in_rows + row_shift - r);
+ 	else                   scale *= sum_type(ref_rows);
+ 
+ 	if (c < col_shift)     scale *= sum_type(c+ (ref_cols-col_shift));
+ 	else if (c >= in_cols - col_edge)
+                                scale *= sum_type(in_cols + col_shift - c);
+ 	else                   scale *= sum_type(ref_cols);
+ 
+ 	sum /= scale;
+       }
+       
+       out[r * out_row_stride + c * out_col_stride] = sum;
+     }
+   }
+ }
+ 
+ 
+ 
+ /// Perform 2-D correlation with full region of support.
+ 
+ template <typename T>
+ inline void
+ corr_full(
+   bias_type   bias,
+ 
+   T*          ref,
+   length_type ref_rows,		// Mr
+   length_type ref_cols,		// Mc
+   stride_type ref_row_stride,
+   stride_type ref_col_stride,
+ 
+   T*          in,
+   length_type in_rows,		// Nr
+   length_type in_cols,		// Nc
+   stride_type in_row_stride,
+   stride_type in_col_stride,
+ 
+   T*          out,
+   length_type out_rows,		// Pr
+   length_type out_cols,		// Pc
+   stride_type out_row_stride,
+   stride_type out_col_stride)
+ {
+   corr_base(bias,
+ 	    ref, ref_rows, ref_cols, ref_row_stride, ref_col_stride,
+ 	    ref_rows-1, ref_cols-1, 0, 0,
+ 	    in, in_rows, in_cols, in_row_stride, in_col_stride,
+ 	    out, out_rows, out_cols, out_row_stride, out_col_stride);
+ }
+ 
+ 
+ 
+ /// Perform 2-D correlation with same region of support.
+ 
+ template <typename T>
+ inline void
+ corr_same(
+   bias_type   bias,
+ 
+   T*          ref,
+   length_type ref_rows,		// Mr
+   length_type ref_cols,		// Mc
+   stride_type ref_row_stride,
+   stride_type ref_col_stride,
+ 
+   T*          in,
+   length_type in_rows,		// Nr
+   length_type in_cols,		// Nc
+   stride_type in_row_stride,
+   stride_type in_col_stride,
+ 
+   T*          out,
+   length_type out_rows,		// Pr
+   length_type out_cols,		// Pc
+   stride_type out_row_stride,
+   stride_type out_col_stride)
+ {
+   corr_base(bias,
+ 	    ref, ref_rows, ref_cols, ref_row_stride, ref_col_stride,
+ 	    ref_rows/2, ref_cols/2, ref_rows/2, ref_cols/2,
+ 	    in, in_rows, in_cols, in_row_stride, in_col_stride,
+ 	    out, out_rows, out_cols, out_row_stride, out_col_stride);
+ }
+ 
+ 
+ 
+ /// Perform 2-D correlation with minimal region of support.
+ 
+ template <typename T>
+ inline void
+ corr_min(
+   bias_type   bias,
+ 
+   T*          ref,
+   length_type ref_rows,		// Mr
+   length_type ref_cols,		// Mc
+   stride_type ref_row_stride,
+   stride_type ref_col_stride,
+ 
+   T*          in,
+   length_type in_rows,		// Nr
+   length_type in_cols,		// Nc
+   stride_type in_row_stride,
+   stride_type in_col_stride,
+ 
+   T*          out,
+   length_type out_rows,		// Pr
+   length_type out_cols,		// Pc
+   stride_type out_row_stride,
+   stride_type out_col_stride)
+ {
+   corr_base(bias,
+ 	    ref, ref_rows, ref_cols, ref_row_stride, ref_col_stride,
+ 	    0, 0, 0, 0,
+ 	    in, in_rows, in_cols, in_row_stride, in_col_stride,
+ 	    out, out_rows, out_cols, out_row_stride, out_col_stride);
+ }
+ 
+ 
+ 
  } // namespace vsip::impl
  
  } // namespace vsip
Index: src/vsip/impl/signal-corr-ext.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-corr-ext.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 signal-corr-ext.hpp
*** src/vsip/impl/signal-corr-ext.hpp	7 Oct 2005 13:46:46 -0000	1.1
--- src/vsip/impl/signal-corr-ext.hpp	12 Dec 2005 13:41:01 -0000
*************** namespace vsip
*** 35,42 ****
  namespace impl
  {
  
! template <typename T>
! struct Is_corr_impl_avail<Generic_tag, T>
  {
    static bool const value = true;
  };
--- 35,42 ----
  namespace impl
  {
  
! template <dimension_type Dim, typename T>
! struct Is_corr_impl_avail<Generic_tag, Dim, T>
  {
    static bool const value = true;
  };
*************** public:
*** 111,120 ****
  	    Matrix<T, Block2>       out)
      VSIP_NOTHROW;
  
-   typedef vsip::impl::Layout<1, row1_type, vsip::impl::Stride_unit, vsip::impl::Cmplx_inter_fmt> layout_type;
-   typedef Vector<T> coeff_view_type;
-   typedef impl::Ext_data<typename coeff_view_type::block_type, layout_type> c_ext_type;
- 
    // Member data.
  private:
    Domain<dim>     ref_size_;
--- 111,116 ----
*************** Correlation_impl<ConstViewT, Supp, T, n_
*** 192,198 ****
  
  
  
! // Perform 1-D convolution.
  
  template <template <typename, typename> class ConstViewT,
  	  support_region_type Supp,
--- 188,194 ----
  
  
  
! // Perform 1-D correlation.
  
  template <template <typename, typename> class ConstViewT,
  	  support_region_type Supp,
*************** VSIP_NOTHROW
*** 255,261 ****
  
  
  
! // Perform 2-D convolution.
  
  template <template <typename, typename> class ConstViewT,
  	  support_region_type                 Supp,
--- 251,257 ----
  
  
  
! // Perform 2-D correlation.
  
  template <template <typename, typename> class ConstViewT,
  	  support_region_type                 Supp,
*************** impl_correlate(
*** 274,281 ****
    Matrix<T, Block2>       out)
  VSIP_NOTHROW
  {
!   VSIP_IMPL_THROW(vsip::impl::unimplemented(
!     "Correlation_impl<Generic_tag>: 2D correlation not implemented."));
  }
  
  } // namespace vsip::impl
--- 270,333 ----
    Matrix<T, Block2>       out)
  VSIP_NOTHROW
  {
!   length_type const Mr = this->ref_size_[0].size();
!   length_type const Mc = this->ref_size_[1].size();
!   length_type const Nr = this->input_size_[0].size();
!   length_type const Nc = this->input_size_[1].size();
!   length_type const Pr = this->output_size_[0].size();
!   length_type const Pc = this->output_size_[1].size();
! 
!   assert(Mr == ref.size(0));
!   assert(Mc == ref.size(1));
!   assert(Nr == in.size(0));
!   assert(Nc == in.size(1));
!   assert(Pr == out.size(0));
!   assert(Pc == out.size(1));
! 
!   typedef vsip::impl::Ext_data<Block0> ref_ext_type;
!   typedef vsip::impl::Ext_data<Block1> in_ext_type;
!   typedef vsip::impl::Ext_data<Block2> out_ext_type;
! 
!   ref_ext_type ref_ext(ref.block(), vsip::impl::SYNC_IN,  ref_buffer_);
!   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
!   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
! 
!   pm_ref_ext_cost_ += ref_ext.cost();
!   pm_in_ext_cost_  += in_ext.cost();
!   pm_out_ext_cost_ += out_ext.cost();
! 
!   T* p_ref   = ref_ext.data();
!   T* p_in    = in_ext.data();
!   T* p_out   = out_ext.data();
! 
!   stride_type ref_row_stride = ref_ext.stride(0);
!   stride_type ref_col_stride = ref_ext.stride(1);
!   stride_type in_row_stride  = in_ext.stride(0);
!   stride_type in_col_stride  = in_ext.stride(1);
!   stride_type out_row_stride = out_ext.stride(0);
!   stride_type out_col_stride = out_ext.stride(1);
! 
!   if (Supp == support_full)
!   {
!     corr_full<T>(bias,
! 		 p_ref, Mr, Mc, ref_row_stride, ref_col_stride,
! 		 p_in, Nr, Nc, in_row_stride, in_col_stride,
! 		 p_out, Pr, Pc, out_row_stride, out_col_stride);
!   }
!   else if (Supp == support_same)
!   {
!     corr_same<T>(bias,
! 		 p_ref, Mr, Mc, ref_row_stride, ref_col_stride,
! 		 p_in, Nr, Nc, in_row_stride, in_col_stride,
! 		 p_out, Pr, Pc, out_row_stride, out_col_stride);
!   }
!   else // (Supp == support_min)
!   {
!     corr_min<T>(bias,
! 		p_ref, Mr, Mc, ref_row_stride, ref_col_stride,
! 		p_in, Nr, Nc, in_row_stride, in_col_stride,
! 		p_out, Pr, Pc, out_row_stride, out_col_stride);
!   }
  }
  
  } // namespace vsip::impl
Index: src/vsip/impl/signal-corr-opt.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-corr-opt.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 signal-corr-opt.hpp
*** src/vsip/impl/signal-corr-opt.hpp	7 Oct 2005 13:46:46 -0000	1.1
--- src/vsip/impl/signal-corr-opt.hpp	12 Dec 2005 13:41:01 -0000
*************** namespace impl
*** 40,46 ****
  {
  
  template <typename T>
! struct Is_corr_impl_avail<Opt_tag, T>
  {
    static bool const value = true;
  };
--- 40,46 ----
  {
  
  template <typename T>
! struct Is_corr_impl_avail<Opt_tag, 1, T>
  {
    static bool const value = true;
  };
*************** Correlation_impl<ConstViewT, Supp, T, n_
*** 237,243 ****
  
  
  
! // Perform 1-D convolution.
  
  template <template <typename, typename> class ConstViewT,
  	  support_region_type Supp,
--- 237,243 ----
  
  
  
! // Perform 1-D correlation.
  
  template <template <typename, typename> class ConstViewT,
  	  support_region_type Supp,
*************** VSIP_NOTHROW
*** 365,371 ****
  
  
  
! // Perform 2-D convolution.
  
  template <template <typename, typename> class ConstViewT,
  	  support_region_type                 Supp,
--- 365,371 ----
  
  
  
! // Perform 2-D correlation.
  
  template <template <typename, typename> class ConstViewT,
  	  support_region_type                 Supp,
Index: src/vsip/impl/signal-corr.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-corr.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 signal-corr.hpp
*** src/vsip/impl/signal-corr.hpp	7 Oct 2005 13:46:46 -0000	1.1
--- src/vsip/impl/signal-corr.hpp	12 Dec 2005 13:41:01 -0000
*************** namespace vsip
*** 35,45 ****
  namespace impl
  {
  
! template <typename T>
  struct Choose_corr_impl
  {
    typedef typename
!   ITE_Type<Is_corr_impl_avail<Opt_tag, T>::value,
  	   As_type<Opt_tag>, As_type<Generic_tag> >::type type;
  };
  
--- 35,46 ----
  namespace impl
  {
  
! template <dimension_type Dim,
! 	  typename       T>
  struct Choose_corr_impl
  {
    typedef typename
!   ITE_Type<Is_corr_impl_avail<Opt_tag, Dim, T>::value,
  	   As_type<Opt_tag>, As_type<Generic_tag> >::type type;
  };
  
*************** template <template <typename, typename> 
*** 56,71 ****
            alg_hint_type                       A_hint = alg_time>
  class Correlation
    : public impl::Correlation_impl<ConstViewT, Supp, T, N_times, A_hint,
! 				  typename impl::Choose_corr_impl<T>::type>
  {
-   typedef impl::Correlation_impl<ConstViewT, Supp, T, N_times, A_hint,
- 				 typename impl::Choose_corr_impl<T>::type>
- 		base_type;
- 
    // Implementation compile-time constants.
  private:
    static dimension_type const dim = impl::Dim_of_view<ConstViewT>::dim;
  
    // Constructors, copies, assignments, and destructors.
  public:
    Correlation(Domain<dim> const&   ref_size,
--- 57,73 ----
            alg_hint_type                       A_hint = alg_time>
  class Correlation
    : public impl::Correlation_impl<ConstViewT, Supp, T, N_times, A_hint,
!        typename impl::Choose_corr_impl<
!           impl::Dim_of_view<ConstViewT>::dim, T>::type>
  {
    // Implementation compile-time constants.
  private:
    static dimension_type const dim = impl::Dim_of_view<ConstViewT>::dim;
  
+   typedef impl::Correlation_impl<ConstViewT, Supp, T, N_times, A_hint,
+ 				 typename impl::Choose_corr_impl<dim, T>::type>
+ 		base_type;
+ 
    // Constructors, copies, assignments, and destructors.
  public:
    Correlation(Domain<dim> const&   ref_size,
*************** public:
*** 111,116 ****
--- 113,143 ----
      return out;
    }
  
+   template <typename Block0,
+ 	    typename Block1,
+ 	    typename Block2>
+   Matrix<T, Block2>
+   operator()(
+     bias_type               bias,
+     const_Matrix<T, Block0> ref,
+     const_Matrix<T, Block1> in,
+     Matrix<T, Block2>       out)
+     VSIP_NOTHROW
+   {
+     impl::profile::Scope_timer t(timer_);
+ 
+     for (dimension_type d=0; d<dim; ++d)
+     {
+       assert(ref.size(d) == this->reference_size()[d].size());
+       assert(in.size(d)  == this->input_size()[d].size());
+       assert(out.size(d) == this->output_size()[d].size());
+     }
+ 
+     impl_correlate(bias, ref, in, out);
+ 
+     return out;
+   }
+ 
    float impl_performance(char* what) const
    {
      if (!strcmp(what, "mflops"))
Index: tests/corr-2d.cpp
===================================================================
RCS file: tests/corr-2d.cpp
diff -N tests/corr-2d.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/corr-2d.cpp	12 Dec 2005 13:41:01 -0000
***************
*** 0 ****
--- 1,174 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    corr-2d.cpp
+     @author  Jules Bergmann
+     @date    2005-12-09
+     @brief   VSIPL++ Library: Unit tests for [signal.correl] 2-D items.
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <cassert>
+ 
+ #include <vsip/vector.hpp>
+ #include <vsip/signal.hpp>
+ #include <vsip/random.hpp>
+ #include <vsip/selgen.hpp>
+ 
+ #include "test.hpp"
+ #include "ref_corr.hpp"
+ #include "error_db.hpp"
+ 
+ #define VERBOSE 0
+ 
+ #if VERBOSE
+ #  include <iostream>
+ #  include "output.hpp"
+ #endif
+ 
+ using namespace std;
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ /// Test general 1-D correlation.
+ 
+ template <typename            T,
+ 	  support_region_type support>
+ void
+ test_corr(
+   bias_type                bias,
+   Domain<2> const&         M,		// reference size
+   Domain<2> const&         N,		// input size
+   length_type const        n_loop = 3)
+ {
+   typedef typename impl::Scalar_of<T>::type scalar_type;
+   typedef Correlation<const_Matrix, support, T> corr_type;
+ 
+   length_type Mr = M[0].size();
+   length_type Mc = M[1].size();
+   length_type Nr = N[0].size();
+   length_type Nc = N[1].size();
+ 
+   length_type const Pr = ref::corr_output_size(support, Mr, Nr);
+   length_type const Pc = ref::corr_output_size(support, Mc, Nc);
+ 
+   corr_type corr(M, N);
+ 
+   test_assert(corr.support()  == support);
+ 
+   test_assert(corr.reference_size()[0].size() == Mr);
+   test_assert(corr.reference_size()[1].size() == Mc);
+ 
+   test_assert(corr.input_size()[0].size()     == Nr);
+   test_assert(corr.input_size()[1].size()     == Nc);
+ 
+   test_assert(corr.output_size()[0].size()    == Pr);
+   test_assert(corr.output_size()[1].size()    == Pc);
+ 
+   Rand<T> rand(0);
+ 
+   Matrix<T> ref(Mr, Mc);
+   Matrix<T> in(Nr, Nc);
+   Matrix<T> out(Pr, Pc, T(100));
+   Matrix<T> chk(Pr, Pc, T(101));
+ 
+   for (index_type loop=0; loop<n_loop; ++loop)
+   {
+     if (loop == 0)
+     {
+       ref = T(1);
+       for (index_type r=0; r<Nr; ++r)
+ 	in.row(r) = ramp(T(0), T(1), Nc);
+     }
+     else if (loop == 1)
+     {
+       ref = rand.randu(Mr, Mc);
+       for (index_type r=0; r<Nr; ++r)
+ 	in.row(r) = ramp(T(0), T(1), Nc);
+     }
+     else
+     {
+       ref = rand.randu(Mr, Mc);
+       in  = rand.randu(Nr, Nc);
+     }
+ 
+     corr(bias, ref, in, out);
+ 
+     ref::corr(bias, support, ref, in, chk);
+ 
+     double error = error_db(out, chk);
+ 
+ #if VERBOSE
+     if (error > -120)
+     {
+       for (index_type i=0; i<P; ++i)
+       {
+ 	cout << i << ":  out = " << out(i)
+ 	     << "  chk = " << chk(i)
+ 	     << endl;
+       }
+       cout << "error = " << error << endl;
+     }
+ #endif
+ 
+     test_assert(error < -100);
+   }
+ }
+ 
+ 
+ 
+ template <typename T>
+ void
+ corr_cases(Domain<2> const& M, Domain<2> const& N)
+ {
+   test_corr<T, support_min>(biased,   M, N);
+   test_corr<T, support_min>(unbiased, M, N);
+ 
+   test_corr<T, support_same>(biased,   M, N);
+   test_corr<T, support_same>(unbiased, M, N);
+ 
+   test_corr<T, support_full>(biased,   M, N);
+   test_corr<T, support_full>(unbiased, M, N);
+ }
+ 
+ 
+ template <typename T>
+ void
+ corr_cover()
+ {
+   corr_cases<T>(Domain<2>(8, 8), Domain<2>(8, 8));
+ 
+   corr_cases<T>(Domain<2>(1, 1), Domain<2>(32, 32));
+   corr_cases<T>(Domain<2>(2, 4), Domain<2>(32, 32));
+   corr_cases<T>(Domain<2>(2, 3), Domain<2>(32, 32));
+   corr_cases<T>(Domain<2>(3, 2), Domain<2>(32, 32));
+ 
+   corr_cases<T>(Domain<2>(1, 1), Domain<2>(16, 13));
+   corr_cases<T>(Domain<2>(2, 4), Domain<2>(16, 13));
+   corr_cases<T>(Domain<2>(2, 3), Domain<2>(16, 13));
+   corr_cases<T>(Domain<2>(3, 2), Domain<2>(16, 13));
+ 
+   corr_cases<T>(Domain<2>(1, 1), Domain<2>(13, 16));
+   corr_cases<T>(Domain<2>(2, 4), Domain<2>(13, 16));
+   corr_cases<T>(Domain<2>(2, 3), Domain<2>(13, 16));
+   corr_cases<T>(Domain<2>(3, 2), Domain<2>(13, 16));
+ }
+ 
+ 
+ 
+ int
+ main()
+ {
+   // Test user-visible correlation
+   corr_cover<float>();
+   corr_cover<complex<float> >();
+   corr_cover<double>();
+   corr_cover<complex<double> >();
+ }
Index: tests/correlation.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/correlation.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 correlation.cpp
*** tests/correlation.cpp	7 Oct 2005 13:46:46 -0000	1.1
--- tests/correlation.cpp	12 Dec 2005 13:41:01 -0000
***************
*** 18,23 ****
--- 18,25 ----
  #include <vsip/selgen.hpp>
  
  #include "test.hpp"
+ #include "ref_corr.hpp"
+ #include "error_db.hpp"
  
  #define VERBOSE 0
  
*************** using namespace vsip;
*** 35,162 ****
    Definitions
  ***********************************************************************/
  
- template <typename T1,
- 	  typename T2,
- 	  typename Block1,
- 	  typename Block2>
- double
- error_db(
-   const_Vector<T1, Block1> v1,
-   const_Vector<T2, Block2> v2)
- {
-   double refmax = 0.0;
-   double maxsum = -250;
-   double sum;
- 
-   Index<1> idx;
- 
-   refmax = maxval(magsq(v1), idx);
- 
-   for (index_type i=0; i<v1.size(); ++i)
-   {
-     double val = magsq(v1.get(i) - v2.get(i));
- 
-     if (val < 1.e-20)
-       sum = -201.;
-     else
-       sum = 10.0 * log10(val/(2.0*refmax));
- 
-     if (sum > maxsum)
-       maxsum = sum;
-   }
- 
-   return maxsum;
- }
- 
- 
- 
- length_type expected_output_size(
-   support_region_type supp,
-   length_type         M,    // kernel length
-   length_type         N)    // input  length
- {
-   if      (supp == support_full)
-     return (N + M - 1);
-   else if (supp == support_same)
-     return N;
-   else //(supp == support_min)
-     return (N - M + 1);
- }
- 
- 
- 
- stride_type
- expected_shift(
-   support_region_type supp,
-   length_type         M)     // kernel length
- {
-   if      (supp == support_full)
-     return -(M-1);
-   else if (supp == support_same)
-     return -(M/2);
-   else //(supp == support_min)
-     return 0;
- }
- 
- 
- template <typename T,
- 	  typename Block1,
- 	  typename Block2,
- 	  typename Block3>
- void
- ref_correlation(
-   bias_type               bias,
-   support_region_type     sup,
-   const_Vector<T, Block1> ref,
-   const_Vector<T, Block2> in,
-   Vector<T, Block3>       out)
- {
-   typedef typename impl::Scalar_of<T>::type scalar_type;
- 
-   length_type M = ref.size(0);
-   length_type N = in.size(0);
-   length_type P = out.size(0);
- 
-   length_type expected_P = expected_output_size(sup, M, N);
-   stride_type shift      = expected_shift(sup, M);
- 
-   assert(expected_P == P);
- 
-   Vector<T> sub(M);
- 
-   // compute correlation
-   for (index_type i=0; i<P; ++i)
-   {
-     sub = T();
-     stride_type pos = static_cast<stride_type>(i) + shift;
-     scalar_type scale;
- 
-     if (pos < 0)
-     {
-       sub(Domain<1>(-pos, 1, M + pos)) = in(Domain<1>(0, 1, M+pos));
-       scale = scalar_type(M + pos);
-     }
-     else if (pos + M > N)
-     {
-       sub(Domain<1>(0, 1, N-pos)) = in(Domain<1>(pos, 1, N-pos));
-       scale = scalar_type(N - pos);
-     }
-     else
-     {
-       sub = in(Domain<1>(pos, 1, M));
-       scale = scalar_type(M);
-     }
-       
-     T val = dot(ref, impl_conj(sub));
-     if (bias == unbiased)
-       val /= scale;
- 
-     out(i) = val;
-   }
- }
- 
- 
- 
  /// Test general 1-D correlation.
  
  template <typename            T,
--- 37,42 ----
*************** test_corr(
*** 171,185 ****
    typedef typename impl::Scalar_of<T>::type scalar_type;
    typedef Correlation<const_Vector, support, T> corr_type;
  
!   length_type const P = expected_output_size(support, M, N);
  
    corr_type corr((Domain<1>(M)), Domain<1>(N));
  
!   assert(corr.support()  == support);
  
!   assert(corr.reference_size().size() == M);
!   assert(corr.input_size().size()     == N);
!   assert(corr.output_size().size()    == P);
  
    Rand<T> rand(0);
  
--- 51,65 ----
    typedef typename impl::Scalar_of<T>::type scalar_type;
    typedef Correlation<const_Vector, support, T> corr_type;
  
!   length_type const P = ref::corr_output_size(support, M, N);
  
    corr_type corr((Domain<1>(M)), Domain<1>(N));
  
!   test_assert(corr.support()  == support);
  
!   test_assert(corr.reference_size().size() == M);
!   test_assert(corr.input_size().size()     == N);
!   test_assert(corr.output_size().size()    == P);
  
    Rand<T> rand(0);
  
*************** test_corr(
*** 208,214 ****
  
      corr(bias, ref, in, out);
  
!     ref_correlation(bias, support, ref, in, chk);
  
      double error = error_db(out, chk);
  
--- 88,94 ----
  
      corr(bias, ref, in, out);
  
!     ref::corr(bias, support, ref, in, chk);
  
      double error = error_db(out, chk);
  
*************** test_corr(
*** 225,231 ****
      }
  #endif
  
!     assert(error < -100);
    }
  }
  
--- 105,111 ----
      }
  #endif
  
!     test_assert(error < -100);
    }
  }
  
*************** test_impl_corr(
*** 247,262 ****
    typedef impl::Correlation_impl<const_Vector, support, T, 0, alg_time, Tag>
  		corr_type;
  
!   length_type const P = expected_output_size(support, M, N);
  
    corr_type corr((Domain<1>(M)), Domain<1>(N));
  
    // Correlation_impl doesn't define support():
!   // assert(corr.support()  == support);
  
!   assert(corr.reference_size().size() == M);
!   assert(corr.input_size().size()     == N);
!   assert(corr.output_size().size()    == P);
  
    Rand<T> rand(0);
  
--- 127,142 ----
    typedef impl::Correlation_impl<const_Vector, support, T, 0, alg_time, Tag>
  		corr_type;
  
!   length_type const P = ref::corr_output_size(support, M, N);
  
    corr_type corr((Domain<1>(M)), Domain<1>(N));
  
    // Correlation_impl doesn't define support():
!   // test_assert(corr.support()  == support);
  
!   test_assert(corr.reference_size().size() == M);
!   test_assert(corr.input_size().size()     == N);
!   test_assert(corr.output_size().size()    == P);
  
    Rand<T> rand(0);
  
*************** test_impl_corr(
*** 285,291 ****
  
      corr.impl_correlate(bias, ref, in, out);
  
!     ref_correlation(bias, support, ref, in, chk);
  
      double error = error_db(out, chk);
  
--- 165,171 ----
  
      corr.impl_correlate(bias, ref, in, out);
  
!     ref::corr(bias, support, ref, in, chk);
  
      double error = error_db(out, chk);
  
*************** test_impl_corr(
*** 302,308 ****
      }
  #endif
  
!     assert(error < -100);
    }
  }
  
--- 182,188 ----
      }
  #endif
  
!     test_assert(error < -100);
    }
  }
  
Index: tests/error_db.hpp
===================================================================
RCS file: tests/error_db.hpp
diff -N tests/error_db.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/error_db.hpp	12 Dec 2005 13:41:01 -0000
***************
*** 0 ****
--- 1,51 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    error_db.cpp
+     @author  Jules Bergmann
+     @date    2005-12-12
+     @brief   VSIPL++ Library: Measure difference between views in decibels.
+ */
+ 
+ #ifndef VSIP_TESTS_ERROR_DB_HPP
+ #define VSIP_TESTS_ERROR_DB_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/math.hpp>
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ template <template <typename, typename> class View1,
+ 	  template <typename, typename> class View2,
+ 	  typename                            T1,
+ 	  typename                            T2,
+ 	  typename                            Block1,
+ 	  typename                            Block2>
+ inline double
+ error_db(
+   View1<T1, Block1> v1,
+   View2<T2, Block2> v2)
+ {
+   using vsip::impl::Dim_of_view;
+   using vsip::dimension_type;
+ 
+   assert(Dim_of_view<View1>::dim == Dim_of_view<View2>::dim);
+   dimension_type const dim = Dim_of_view<View2>::dim;
+ 
+   vsip::Index<dim> idx;
+ 
+   double refmax = maxval(magsq(v1), idx);
+   double maxsum = maxval(ite(magsq(v1 - v2) < 1.e-20,
+ 			     -201.0,
+ 			     10.0 * log10(magsq(v1 - v2)/(2.0*refmax)) ),
+ 			 idx);
+   return maxsum;
+ }
+ 
+ #endif // VSIP_TESTS_ERROR_DB_HPP
Index: tests/ref_corr.hpp
===================================================================
RCS file: tests/ref_corr.hpp
diff -N tests/ref_corr.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/ref_corr.hpp	12 Dec 2005 13:41:01 -0000
***************
*** 0 ****
--- 1,226 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    ref_corr.cpp
+     @author  Jules Bergmann
+     @date    2005-12-09
+     @brief   VSIPL++ Library: Reference implementation of correlation
+ */
+ 
+ #ifndef VSIP_REF_CORR_HPP
+ #define VSIP_REF_CORR_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/vector.hpp>
+ #include <vsip/signal.hpp>
+ #include <vsip/random.hpp>
+ #include <vsip/selgen.hpp>
+ 
+ namespace ref
+ {
+ 
+ vsip::length_type
+ corr_output_size(
+   vsip::support_region_type supp,
+   vsip::length_type         M,    // kernel length
+   vsip::length_type         N)    // input  length
+ {
+   if      (supp == vsip::support_full)
+     return (N + M - 1);
+   else if (supp == vsip::support_same)
+     return N;
+   else //(supp == vsip::support_min)
+     return (N - M + 1);
+ }
+ 
+ 
+ 
+ vsip::stride_type
+ expected_shift(
+   vsip::support_region_type supp,
+   vsip::length_type         M)     // kernel length
+ {
+   if      (supp == vsip::support_full)
+     return -(M-1);
+   else if (supp == vsip::support_same)
+     return -(M/2);
+   else //(supp == vsip::support_min)
+     return 0;
+ }
+ 
+ 
+ 
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ corr(
+   vsip::bias_type               bias,
+   vsip::support_region_type     sup,
+   vsip::const_Vector<T, Block1> ref,
+   vsip::const_Vector<T, Block2> in,
+   vsip::Vector<T, Block3>       out)
+ {
+   using vsip::index_type;
+   using vsip::length_type;
+   using vsip::stride_type;
+   using vsip::Vector;
+   using vsip::Domain;
+   using vsip::unbiased;
+ 
+   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+ 
+   length_type M = ref.size(0);
+   length_type N = in.size(0);
+   length_type P = out.size(0);
+ 
+   length_type expected_P = corr_output_size(sup, M, N);
+   stride_type shift      = expected_shift(sup, M);
+ 
+   assert(expected_P == P);
+ 
+   Vector<T> sub(M);
+ 
+   // compute correlation
+   for (index_type i=0; i<P; ++i)
+   {
+     sub = T();
+     stride_type pos = static_cast<stride_type>(i) + shift;
+     scalar_type scale;
+ 
+     if (pos < 0)
+     {
+       sub(Domain<1>(-pos, 1, M + pos)) = in(Domain<1>(0, 1, M+pos));
+       scale = scalar_type(M + pos);
+     }
+     else if (pos + M > N)
+     {
+       sub(Domain<1>(0, 1, N-pos)) = in(Domain<1>(pos, 1, N-pos));
+       scale = scalar_type(N - pos);
+     }
+     else
+     {
+       sub = in(Domain<1>(pos, 1, M));
+       scale = scalar_type(M);
+     }
+       
+     T val = dot(ref, impl_conj(sub));
+     if (bias == vsip::unbiased)
+       val /= scale;
+ 
+     out(i) = val;
+   }
+ }
+ 
+ 
+ 
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ corr(
+   vsip::bias_type               bias,
+   vsip::support_region_type     sup,
+   vsip::const_Matrix<T, Block1> ref,
+   vsip::const_Matrix<T, Block2> in,
+   vsip::Matrix<T, Block3>       out)
+ {
+   using vsip::index_type;
+   using vsip::length_type;
+   using vsip::stride_type;
+   using vsip::Matrix;
+   using vsip::Domain;
+   using vsip::unbiased;
+ 
+   typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+ 
+   length_type Mr = ref.size(0);
+   length_type Mc = ref.size(1);
+   length_type Nr = in.size(0);
+   length_type Nc = in.size(1);
+   length_type Pr = out.size(0);
+   length_type Pc = out.size(1);
+ 
+   length_type expected_Pr = corr_output_size(sup, Mr, Nr);
+   length_type expected_Pc = corr_output_size(sup, Mc, Nc);
+   stride_type shift_r     = expected_shift(sup, Mr);
+   stride_type shift_c     = expected_shift(sup, Mc);
+ 
+   assert(expected_Pr == Pr);
+   assert(expected_Pc == Pc);
+ 
+   Matrix<T> sub(Mr, Mc);
+   Domain<1> sub_dom_r;
+   Domain<1> sub_dom_c;
+   Domain<1> in_dom_r;
+   Domain<1> in_dom_c;
+ 
+   // compute correlation
+   for (index_type r=0; r<Pr; ++r)
+   {
+     stride_type pos_r = static_cast<stride_type>(r) + shift_r;
+ 
+     for (index_type c=0; c<Pc; ++c)
+     {
+ 
+       stride_type pos_c = static_cast<stride_type>(c) + shift_c;
+ 
+       scalar_type scale = scalar_type(1);
+ 
+       if (pos_r < 0)
+       {
+ 	sub_dom_r = Domain<1>(-pos_r, 1, Mr + pos_r); 
+ 	in_dom_r  = Domain<1>(0, 1, Mr+pos_r);
+ 	scale *= scalar_type(Mr + pos_r);
+       }
+       else if (pos_r + Mr > Nr)
+       {
+ 	sub_dom_r = Domain<1>(0, 1, Nr-pos_r);
+ 	in_dom_r  = Domain<1>(pos_r, 1, Nr-pos_r);
+ 	scale *= scalar_type(Nr - pos_r);
+       }
+       else
+       {
+ 	sub_dom_r = Domain<1>(0, 1, Mr);
+ 	in_dom_r  = Domain<1>(pos_r, 1, Mr);
+ 	scale *= scalar_type(Mr);
+       }
+ 
+       if (pos_c < 0)
+       {
+ 	sub_dom_c = Domain<1>(-pos_c, 1, Mc + pos_c); 
+ 	in_dom_c  = Domain<1>(0, 1, Mc+pos_c);
+ 	scale *= scalar_type(Mc + pos_c);
+       }
+       else if (pos_c + Mc > Nc)
+       {
+ 	sub_dom_c = Domain<1>(0, 1, Nc-pos_c);
+ 	in_dom_c  = Domain<1>(pos_c, 1, Nc-pos_c);
+ 	scale *= scalar_type(Nc - pos_c);
+       }
+       else
+       {
+ 	sub_dom_c = Domain<1>(0, 1, Mc);
+ 	in_dom_c  = Domain<1>(pos_c, 1, Mc);
+ 	scale *= scalar_type(Mc);
+       }
+ 
+       sub = T();
+       sub(Domain<2>(sub_dom_r, sub_dom_c)) = in(Domain<2>(in_dom_r, in_dom_c));
+       
+       T val = sumval(ref * impl_conj(sub));
+       if (bias == unbiased)
+ 	val /= scale;
+       
+       out(r, c) = val;
+     }
+   }
+ }
+ 
+ } // namespace ref
+ 
+ #endif // VSIP_REF_CORR_HPP
Index: tests/test.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/test.hpp,v
retrieving revision 1.8
diff -c -p -r1.8 test.hpp
*** tests/test.hpp	11 Nov 2005 19:18:52 -0000	1.8
--- tests/test.hpp	12 Dec 2005 13:41:01 -0000
***************
*** 15,20 ****
--- 15,21 ----
  ***********************************************************************/
  
  #include <cstdlib>
+ #include <cassert>
  
  #include <vsip/support.hpp>
  #include <vsip/complex.hpp>
*************** use_variable(T const& /*t*/)
*** 170,173 ****
--- 171,203 ----
  }
  
  
+ void inline
+ test_assert_fail(
+   const char*  assertion,
+   const char*  file,
+   unsigned int line,
+   const char*  function)
+ {
+   fprintf(stderr, "TEST ASSERT FAIL: %s %s %d %s\n",
+ 	  assertion, file, line, function);
+   abort();
+ }
+ 
+ # if defined __cplusplus ? __GNUC_PREREQ (2, 6) : __GNUC_PREREQ (2, 4)
+ #   define TEST_ASSERT_FUNCTION    __PRETTY_FUNCTION__
+ # else
+ #  if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
+ #   define TEST_ASSERT_FUNCTION    __func__
+ #  else
+ #   define TEST_ASSERT_FUNCTION    ((__const char *) 0)
+ #  endif
+ # endif
+ 
+ #define test_assert(expr)						\
+   (static_cast<void>((expr) ? 0 :					\
+ 		     (test_assert_fail(__STRING(expr), __FILE__, __LINE__, \
+ 				       TEST_ASSERT_FUNCTION), 0)))
+ 
+ 
+ 
  #endif // VSIP_TESTS_TEST_HPP
