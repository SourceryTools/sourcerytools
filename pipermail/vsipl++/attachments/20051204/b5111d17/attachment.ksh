Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.319
diff -c -p -r1.319 ChangeLog
*** ChangeLog	4 Dec 2005 21:36:59 -0000	1.319
--- ChangeLog	4 Dec 2005 21:47:38 -0000
***************
*** 1,3 ****
--- 1,35 ----
+ 2005-12-04 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* autogen.sh: check if vendor/atlas/autogen.sh is present before
+ 	  running.
+ 	* configure.ac: Always pull in IPP image-processing library
+ 	  when IPP enabled.  Fix typo: with-atlas-libdir should enable
+ 	  lapack.  Fix -I.../vendor/atlas/include for INT_CPPFLAGS to
+ 	  be correct when srcdir is relative.
+ 	* src/vsip/matrix.hpp (view_domain): New function, return domain
+ 	  of view.
+ 	* src/vsip/tensor.hpp: Likewise.
+ 	* src/vsip/impl/ipp.cpp (conv_full_2d, conv_valid_2d): New
+ 	  functions, wrappers for 2-D IPP convolutions.
+ 	* src/vsip/impl/ipp.hpp: Likewise.
+ 	* src/vsip/impl/signal-conv-common.hpp (Is_conv_impl_avail):
+ 	  Add template parameter for convolution dimension.
+ 	  (conv_kernel): New function overload for 2D kernels.
+ 	  (conv_full, conv_same, conv_min): New functions, generic
+ 	  2D convolutions for different regions of support.
+ 	  (conv_same_edge): New function, perform edge portion of
+ 	  same-support convolution.
+ 	  (conv_same_example): New function, example of using
+ 	  conv_min and conv_same_edge to perform conv_same.
+ 	* src/vsip/impl/signal-conv-ext.hpp: Implement 2-D convolution.
+ 	* src/vsip/impl/signal-conv-ipp.hpp: Likewise.
+ 	* src/vsip/impl/signal-conv-sal.hpp: Update Is_conv_impl_avail.
+ 	* src/vsip/impl/signal-conv.hpp: Likewise.
+ 	* tests/conv-2d.cpp: Unit tests for 2-D convolution.
+ 	
+ 	* src/vsip/impl/eval-blas.hpp: Fix Wall warnings.
+ 	* src/vsip/impl/matvec.hpp: Likewise.
+ 	
  2005-12-02 Jules Bergmann  <jules@codesourcery.com>
  
  	* configure.ac: Cleanup handling of lapack options by
Index: autogen.sh
===================================================================
RCS file: /home/cvs/Repository/vpp/autogen.sh,v
retrieving revision 1.2
diff -c -p -r1.2 autogen.sh
*** autogen.sh	1 Dec 2005 14:43:17 -0000	1.2
--- autogen.sh	4 Dec 2005 21:47:38 -0000
*************** autoheader
*** 6,11 ****
  # Generate 'configure' from 'configure.ac'
  autoconf
  
! cd vendor/atlas
! autogen.sh
! cd ../..
--- 6,13 ----
  # Generate 'configure' from 'configure.ac'
  autoconf
  
! if test -f "vendor/atlas/autogen.sh"; then
!   cd vendor/atlas
!   ./autogen.sh
!   cd ../..
! fi
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.54
diff -c -p -r1.54 configure.ac
*** configure.ac	4 Dec 2005 21:37:00 -0000	1.54
--- configure.ac	4 Dec 2005 21:47:39 -0000
*************** int main(int, char **)
*** 733,754 ****
  [AC_MSG_RESULT(yes)],
  [AC_MSG_ERROR([std::complex-incompatible IPP-types detected!])])
  
      if test "$enable_ipp_fft" != "no"; then 
!       save_LDFLAGS="$LDFLAGS"
!       LDFLAGS="$LDFLAGS $IPP_FFT_LDFLAGS"
!       
!       AC_SEARCH_LIBS(
! 	  [ippiFFTFwd_CToC_32fc_C1R], [$ippi_search],
! 	[
! 	  AC_SUBST(VSIP_IMPL_IPP_FFT, 1)
! 	  AC_DEFINE_UNQUOTED(VSIP_IMPL_IPP_FFT, 1,
  	    [Define to use Intel's IPP library to perform FFTs.])
! 	  AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_FLOAT, $vsip_impl_use_float,
  	    [Define to build code with support for FFT on float types.])
! 	  AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_DOUBLE, $vsip_impl_use_double,
  	    [Define to build code with support for FFT on double types.])
- 	],
- 	[LD_FLAGS="$save_LDFLAGS"])
      fi
    fi
  fi
--- 733,755 ----
  [AC_MSG_RESULT(yes)],
  [AC_MSG_ERROR([std::complex-incompatible IPP-types detected!])])
  
+     save_LDFLAGS="$LDFLAGS"
+     LDFLAGS="$LDFLAGS $IPP_FFT_LDFLAGS"
+ 
+     AC_SEARCH_LIBS(
+ 	[ippiFFTFwd_CToC_32fc_C1R], [$ippi_search],
+ 	[have_ippi="yes"],
+ 	[have_ippi="no"
+          LD_FLAGS="$save_LDFLAGS"])
+ 
      if test "$enable_ipp_fft" != "no"; then 
!       AC_SUBST(VSIP_IMPL_IPP_FFT, 1)
!       AC_DEFINE_UNQUOTED(VSIP_IMPL_IPP_FFT, 1,
  	    [Define to use Intel's IPP library to perform FFTs.])
!       AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_FLOAT, $vsip_impl_use_float,
  	    [Define to build code with support for FFT on float types.])
!       AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_DOUBLE, $vsip_impl_use_double,
  	    [Define to build code with support for FFT on double types.])
      fi
    fi
  fi
*************** fi
*** 820,826 ****
  # Check to see if any options have implied with_lapack
  #
  if test "$with_lapack" == "no"; then
!   if test "$with_atlas_prefix" != "" -o "$with_atlas_prefix" != ""; then
      if test "$with_mkl_prefix" != ""; then
        AC_MSG_ERROR([Prefixes given for both MKL and ATLAS])
      fi
--- 821,827 ----
  # Check to see if any options have implied with_lapack
  #
  if test "$with_lapack" == "no"; then
!   if test "$with_atlas_prefix" != "" -o "$with_atlas_libdir" != ""; then
      if test "$with_mkl_prefix" != ""; then
        AC_MSG_ERROR([Prefixes given for both MKL and ATLAS])
      fi
*************** if test "$with_lapack" != "no"; then
*** 957,962 ****
--- 958,968 ----
          AC_SUBST(USE_BUILTIN_ATLAS, 1)
  
  	curdir=`pwd`
+ 	if test "`echo $srcdir | sed -n '/^\\\\/p'`" != ""; then
+ 	  my_abs_top_srcdir="$srcdir"
+         else
+ 	  my_abs_top_srcdir="$curdir/$srcdir"
+         fi
  	
  	# These libraries have not been built yet so we have to wait before
  	# adding the to LIBS (otherwise subsequent AC_LINK_IFELSE's will
*************** if test "$with_lapack" != "no"; then
*** 965,971 ****
  
          LATE_LIBS="$LATE_LIBS -lcsl_lapack -lcsl_cblas -lcsl_f77blas -lcsl_atlas $use_g2c"
  
! 	INT_CPPFLAGS="$INT_CPPFLAGS -I$srcdir/vendor/atlas/include"
  	INT_LDFLAGS="$INT_LDFLAGS -L$curdir/vendor/atlas/lib"
          CPPFLAGS="$keep_CPPFLAGS -I$includedir/atlas"
          LDFLAGS="$keep_LDFLAGS -L$libdir/atlas"
--- 971,977 ----
  
          LATE_LIBS="$LATE_LIBS -lcsl_lapack -lcsl_cblas -lcsl_f77blas -lcsl_atlas $use_g2c"
  
! 	INT_CPPFLAGS="$INT_CPPFLAGS -I$my_abs_top_srcdir/vendor/atlas/include"
  	INT_LDFLAGS="$INT_LDFLAGS -L$curdir/vendor/atlas/lib"
          CPPFLAGS="$keep_CPPFLAGS -I$includedir/atlas"
          LDFLAGS="$keep_LDFLAGS -L$libdir/atlas"
Index: src/vsip/matrix.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/matrix.hpp,v
retrieving revision 1.28
diff -c -p -r1.28 matrix.hpp
*** src/vsip/matrix.hpp	7 Oct 2005 13:46:46 -0000	1.28
--- src/vsip/matrix.hpp	4 Dec 2005 21:47:39 -0000
*************** put(Matrix<T, Block> view, Index<2> cons
*** 384,389 ****
--- 384,399 ----
    view.put(i[0], i[1], value);
  }
  
+ // Return the view extent as a domain.
+ 
+ template <typename T,
+ 	  typename Block>
+ inline Domain<2>
+ view_domain(const_Matrix<T, Block> const& view)
+ {
+   return Domain<2>(view.size(0), view.size(1));
+ }
+ 
  } // namespace vsip::impl
  
  } // namespace vsip
Index: src/vsip/tensor.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/tensor.hpp,v
retrieving revision 1.21
diff -c -p -r1.21 tensor.hpp
*** src/vsip/tensor.hpp	7 Oct 2005 13:46:46 -0000	1.21
--- src/vsip/tensor.hpp	4 Dec 2005 21:47:39 -0000
*************** put(Tensor<T, Block> view, Index<3> cons
*** 615,620 ****
--- 615,630 ----
    view.put(i[0], i[1], i[2], value);
  }
  
+ // Return the view extent as a domain.
+ 
+ template <typename T,
+ 	  typename Block>
+ inline Domain<3>
+ view_domain(const_Tensor<T, Block> const& view)
+ {
+   return Domain<3>(view.size(0), view.size(1), view.size(2));
+ }
+ 
  } // namespace vsip::impl
  
  } // namespace vsip
Index: src/vsip/impl/eval-blas.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/eval-blas.hpp,v
retrieving revision 1.3
diff -c -p -r1.3 eval-blas.hpp
*** src/vsip/impl/eval-blas.hpp	1 Dec 2005 14:43:17 -0000	1.3
--- src/vsip/impl/eval-blas.hpp	4 Dec 2005 21:47:39 -0000
*************** struct Evaluator<Op_prod_vv_outer, Block
*** 48,54 ****
      Ext_data_cost<Block1>::value == 0 &&
      Ext_data_cost<Block2>::value == 0;
  
!   static bool rt_valid(Block0& r, T1 alpha, Block1 const& a, Block2 const& b)
    {
      typedef typename Block_layout<Block1>::order_type order1_type;
  
--- 48,55 ----
      Ext_data_cost<Block1>::value == 0 &&
      Ext_data_cost<Block2>::value == 0;
  
!   static bool rt_valid(Block0& /*r*/, T1 /*alpha*/,
!     Block1 const& a, Block2 const& b)
    {
      typedef typename Block_layout<Block1>::order_type order1_type;
  
*************** struct Evaluator<Op_prod_vv_outer, Block
*** 113,119 ****
      Ext_data_cost<Block1>::value == 0 &&
      Ext_data_cost<Block2>::value == 0;
  
!   static bool rt_valid(Block0& r, std::complex<T1> alpha, 
      Block1 const& a, Block2 const& b)
    {
      typedef typename Block_layout<Block1>::order_type order1_type;
--- 114,120 ----
      Ext_data_cost<Block1>::value == 0 &&
      Ext_data_cost<Block2>::value == 0;
  
!   static bool rt_valid(Block0& /*r*/, std::complex<T1> /*alpha*/, 
      Block1 const& a, Block2 const& b)
    {
      typedef typename Block_layout<Block1>::order_type order1_type;
*************** struct Evaluator<Op_prod_mv, Block0, Op_
*** 278,284 ****
      Ext_data_cost<Block1>::value == 0 &&
      Ext_data_cost<Block2>::value == 0;
  
!   static bool rt_valid(Block0& r, Block1 const& a, Block2 const& b)
    {
      typedef typename Block_layout<Block1>::order_type order1_type;
  
--- 279,285 ----
      Ext_data_cost<Block1>::value == 0 &&
      Ext_data_cost<Block2>::value == 0;
  
!   static bool rt_valid(Block0& /*r*/, Block1 const& a, Block2 const& b)
    {
      typedef typename Block_layout<Block1>::order_type order1_type;
  
*************** struct Evaluator<Op_prod_vm, Block0, Op_
*** 363,369 ****
      Ext_data_cost<Block1>::value == 0 &&
      Ext_data_cost<Block2>::value == 0;
  
!   static bool rt_valid(Block0& r, Block1 const& a, Block2 const& b)
    {
      typedef typename Block_layout<Block2>::order_type order2_type;
  
--- 364,370 ----
      Ext_data_cost<Block1>::value == 0 &&
      Ext_data_cost<Block2>::value == 0;
  
!   static bool rt_valid(Block0& /*r*/, Block1 const& a, Block2 const& b)
    {
      typedef typename Block_layout<Block2>::order_type order2_type;
  
*************** struct Evaluator<Op_prod_mm, Block0, Op_
*** 466,472 ****
      Ext_data_cost<Block1>::value == 0 &&
      Ext_data_cost<Block2>::value == 0;
  
!   static bool rt_valid(Block0& r, Block1 const& a, Block2 const& b)
    {
      typedef typename Block_layout<Block1>::order_type order1_type;
      typedef typename Block_layout<Block2>::order_type order2_type;
--- 467,473 ----
      Ext_data_cost<Block1>::value == 0 &&
      Ext_data_cost<Block2>::value == 0;
  
!   static bool rt_valid(Block0& /*r*/, Block1 const& a, Block2 const& b)
    {
      typedef typename Block_layout<Block1>::order_type order1_type;
      typedef typename Block_layout<Block2>::order_type order2_type;
*************** struct Evaluator<Op_prod_mm, Block0, Op_
*** 563,569 ****
      Ext_data_cost<Block1>::value == 0 &&
      Ext_data_cost<Block2>::value == 0;
  
!   static bool rt_valid(Block0& r, T1, Block1 const& a, Block2 const& b, T2)
    {
      typedef typename Block_layout<Block1>::order_type order1_type;
      typedef typename Block_layout<Block2>::order_type order2_type;
--- 564,570 ----
      Ext_data_cost<Block1>::value == 0 &&
      Ext_data_cost<Block2>::value == 0;
  
!   static bool rt_valid(Block0&, T1, Block1 const& a, Block2 const& b, T2)
    {
      typedef typename Block_layout<Block1>::order_type order1_type;
      typedef typename Block_layout<Block2>::order_type order2_type;
Index: src/vsip/impl/ipp.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp.cpp,v
retrieving revision 1.7
diff -c -p -r1.7 ipp.cpp
*** src/vsip/impl/ipp.cpp	27 Oct 2005 17:50:50 -0000	1.7
--- src/vsip/impl/ipp.cpp	4 Dec 2005 21:47:39 -0000
***************
*** 14,19 ****
--- 14,20 ----
  #include <vsip/signal.hpp>
  #include <vsip/impl/ipp.hpp>
  #include <ipps.h>
+ #include <ippi.h>
  
  /***********************************************************************
    Declarations
*************** void conv(double* coeff, length_type coe
*** 194,199 ****
--- 195,290 ----
    ippsConv_64f(coeff, coeff_size, in, in_size, out);
  }
  
+ void
+ conv_full_2d(
+   short*      coeff,
+   length_type coeff_rows,
+   length_type coeff_cols,
+   length_type coeff_row_stride,
+   short*      in,
+   length_type in_rows,
+   length_type in_cols,
+   length_type in_row_stride,
+   short*      out,
+   length_type out_row_stride)
+ {
+   IppiSize coeff_size = { coeff_cols, coeff_rows };
+   IppiSize in_size    = { in_cols,    in_rows };
+   
+   ippiConvFull_16s_C1R(
+     coeff, coeff_row_stride*sizeof(short), coeff_size,
+     in,    in_row_stride   *sizeof(short),    in_size,
+     out,   out_row_stride  *sizeof(short),
+     1);
+ }
+ 
+ void
+ conv_full_2d(
+   float*      coeff,
+   length_type coeff_rows,
+   length_type coeff_cols,
+   length_type coeff_row_stride,
+   float*      in,
+   length_type in_rows,
+   length_type in_cols,
+   length_type in_row_stride,
+   float*      out,
+   length_type out_row_stride)
+ {
+   IppiSize coeff_size = { coeff_cols, coeff_rows };
+   IppiSize in_size    = { in_cols,    in_rows };
+   
+   ippiConvFull_32f_C1R(
+     coeff, coeff_row_stride*sizeof(float), coeff_size,
+     in,    in_row_stride   *sizeof(float),    in_size,
+     out,   out_row_stride  *sizeof(float));
+ }
+ 
+ void
+ conv_valid_2d(
+   float*      coeff,
+   length_type coeff_rows,
+   length_type coeff_cols,
+   length_type coeff_row_stride,
+   float*      in,
+   length_type in_rows,
+   length_type in_cols,
+   length_type in_row_stride,
+   float*      out,
+   length_type out_row_stride)
+ {
+   IppiSize coeff_size = { coeff_cols, coeff_rows };
+   IppiSize in_size    = { in_cols,    in_rows };
+   
+   ippiConvValid_32f_C1R(
+     coeff, coeff_row_stride*sizeof(float), coeff_size,
+     in,    in_row_stride   *sizeof(float),    in_size,
+     out,   out_row_stride  *sizeof(float));
+ }
+ 
+ void
+ conv_valid_2d(
+   short*      coeff,
+   length_type coeff_rows,
+   length_type coeff_cols,
+   length_type coeff_row_stride,
+   short*      in,
+   length_type in_rows,
+   length_type in_cols,
+   length_type in_row_stride,
+   short*      out,
+   length_type out_row_stride)
+ {
+   IppiSize coeff_size = { coeff_cols, coeff_rows };
+   IppiSize in_size    = { in_cols,    in_rows };
+   
+   ippiConvValid_16s_C1R(
+     coeff, coeff_row_stride*sizeof(short), coeff_size,
+     in,    in_row_stride   *sizeof(short),    in_size,
+     out,   out_row_stride  *sizeof(short),
+     1);
+ }
+ 
  //
  // FIR support
  //
Index: src/vsip/impl/ipp.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp.hpp,v
retrieving revision 1.5
diff -c -p -r1.5 ipp.hpp
*** src/vsip/impl/ipp.hpp	14 Oct 2005 16:00:47 -0000	1.5
--- src/vsip/impl/ipp.hpp	4 Dec 2005 21:47:39 -0000
*************** void conv(double* coeff, length_type coe
*** 101,106 ****
--- 101,158 ----
  	  double* in,    length_type in_size,
  	  double* out);
  
+ void
+ conv_full_2d(
+   float*      coeff,
+   length_type coeff_rows,
+   length_type coeff_cols,
+   length_type coeff_row_stride,
+   float*      in,
+   length_type in_rows,
+   length_type in_cols,
+   length_type in_row_stride,
+   float*      out,
+   length_type out_row_stride);
+ 
+ void
+ conv_full_2d(
+   short*      coeff,
+   length_type coeff_rows,
+   length_type coeff_cols,
+   length_type coeff_row_stride,
+   short*      in,
+   length_type in_rows,
+   length_type in_cols,
+   length_type in_row_stride,
+   short*      out,
+   length_type out_row_stride);
+ 
+ void
+ conv_valid_2d(
+   float*      coeff,
+   length_type coeff_rows,
+   length_type coeff_cols,
+   length_type coeff_row_stride,
+   float*      in,
+   length_type in_rows,
+   length_type in_cols,
+   length_type in_row_stride,
+   float*      out,
+   length_type out_row_stride);
+ 
+ void
+ conv_valid_2d(
+   short*      coeff,
+   length_type coeff_rows,
+   length_type coeff_cols,
+   length_type coeff_row_stride,
+   short*      in,
+   length_type in_rows,
+   length_type in_cols,
+   length_type in_row_stride,
+   short*      out,
+   length_type out_row_stride);
+ 
  template <template <typename, typename> class Operator,
  	  typename DstBlock,
  	  typename LBlock,
Index: src/vsip/impl/matvec.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/matvec.hpp,v
retrieving revision 1.8
diff -c -p -r1.8 matvec.hpp
*** src/vsip/impl/matvec.hpp	30 Nov 2005 18:21:11 -0000	1.8
--- src/vsip/impl/matvec.hpp	4 Dec 2005 21:47:39 -0000
*************** struct Evaluator<Op_prod_vv_outer, Block
*** 43,49 ****
  		 Generic_tag>
  {
    static bool const ct_valid = true;
!   static bool rt_valid(Block0&, T1 alpha, Block1 const&, Block2 const&) 
      { return true; }
  
    static void exec(Block0& r, T1 alpha, Block1 const& a, Block2 const& b)
--- 43,49 ----
  		 Generic_tag>
  {
    static bool const ct_valid = true;
!   static bool rt_valid(Block0&, T1, Block1 const&, Block2 const&) 
      { return true; }
  
    static void exec(Block0& r, T1 alpha, Block1 const& a, Block2 const& b)
*************** struct Evaluator<Op_prod_vv_outer, Block
*** 67,73 ****
  		 Generic_tag>
  {
    static bool const ct_valid = true;
!   static bool rt_valid(Block0&, std::complex<T1> alpha, Block1 const&, Block2 const&) 
      { return true; }
  
    static void exec(Block0& r, std::complex<T1> alpha, Block1 const& a, Block2 const& b)
--- 67,73 ----
  		 Generic_tag>
  {
    static bool const ct_valid = true;
!   static bool rt_valid(Block0&, std::complex<T1>, Block1 const&, Block2 const&) 
      { return true; }
  
    static void exec(Block0& r, std::complex<T1> alpha, Block1 const& a, Block2 const& b)
Index: src/vsip/impl/signal-conv-common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv-common.hpp,v
retrieving revision 1.5
diff -c -p -r1.5 signal-conv-common.hpp
*** src/vsip/impl/signal-conv-common.hpp	12 Oct 2005 12:45:05 -0000	1.5
--- src/vsip/impl/signal-conv-common.hpp	4 Dec 2005 21:47:39 -0000
*************** template <template <typename, typename> 
*** 68,75 ****
            typename                            ImplTag>
  class Convolution_impl;
  
! template <typename ImplTag,
! 	  typename T>
  struct Is_conv_impl_avail
  {
    static bool const value = false;
--- 68,76 ----
            typename                            ImplTag>
  class Convolution_impl;
  
! template <typename       ImplTag,
! 	  dimension_type Dim,
! 	  typename       T>
  struct Is_conv_impl_avail
  {
    static bool const value = false;
*************** conv_output_size(
*** 135,141 ****
  
  
  
! /// Helper function to determine a convolution's kernel from its
  /// symmetry and coefficients.
  
  template <typename CoeffViewT,
--- 136,142 ----
  
  
  
! /// Helper function to determine a 1-D convolution's kernel from its
  /// symmetry and coefficients.
  
  template <typename CoeffViewT,
*************** conv_kernel(symmetry_type sym, const_Vec
*** 171,177 ****
  
  
  
! /// Perform convolution with full region of support.
  
  template <typename T>
  inline void
--- 172,237 ----
  
  
  
! /// Helper function to determine a 2-D convolution's kernel from its
! /// symmetry and coefficients.
! 
! template <typename CoeffViewT,
! 	  typename T,
! 	  typename BlockT>
! CoeffViewT
! conv_kernel(symmetry_type sym, const_Matrix<T, BlockT> coeff)
! {
!   if (sym == sym_even_len_odd)
!   {
!     length_type Mr = coeff.size(0);
!     length_type Mc = coeff.size(1);
!     CoeffViewT full_coeff(2*Mr-1, 2*Mc-1);
! 
!     // fill upper-left
!     full_coeff(Domain<2>(Domain<1>(0, 1, Mr), Domain<1>(0, 1, Mc))) = coeff;
! 
!     // fill upper-right
!     full_coeff(Domain<2>(Domain<1>(0, 1, Mr), Domain<1>(Mc, 1, Mc-1))) =
!       coeff(Domain<2>(Mr, Domain<1>(Mc-2, -1, Mc-1)));
! 
!     // fill lower-right (by folding over)
!     full_coeff(Domain<2>(Domain<1>(Mr, 1, Mr-1), 2*Mc-1)) =
!       full_coeff(Domain<2>(Domain<1>(Mr-2, -1, Mr-1), 2*Mc-1));
! 
!     return full_coeff;
!   }
!   else if (sym == sym_even_len_even)
!   {
!     length_type Mr = coeff.size(0);
!     length_type Mc = coeff.size(1);
!     CoeffViewT full_coeff(2*Mr, 2*Mc);
! 
!     // fill upper-left
!     full_coeff(Domain<2>(Mr, Mc)) = coeff;
! 
!     // fill upper-right
!     full_coeff(Domain<2>(Mr, Domain<1>(Mc, 1, Mc))) =
!       coeff(Domain<2>(Mr, Domain<1>(Mc-1, -1, Mc)));
! 
!     // fill lower-right (by folding over)
!     full_coeff(Domain<2>(Domain<1>(Mr, 1, Mr), 2*Mc)) =
!       full_coeff(Domain<2>(Domain<1>(Mr-1, -1, Mr), 2*Mc));
! 
!     return full_coeff;
!   }
!   else /* (sym == nonsym) */
!   {
!     length_type Mr = coeff.size(0);
!     length_type Mc = coeff.size(1);
!     CoeffViewT full_coeff(Mr, Mc);
!     full_coeff = coeff;
!     return full_coeff;
!   }
! }
! 
! 
! 
! /// Perform 1-D convolution with full region of support.
  
  template <typename T>
  inline void
*************** conv_min(
*** 285,290 ****
--- 345,653 ----
  
  
  
+ /// Perform 2-D convolution with full region of support.
+ 
+ template <typename T>
+ inline void
+ conv_full(
+   T*          coeff,
+   length_type coeff_rows,	// Mr
+   length_type coeff_cols,	// Mc
+   stride_type coeff_row_stride,
+   stride_type coeff_col_stride,
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
+   stride_type out_col_stride,
+ 
+   length_type decimation)
+ {
+   typedef typename Convolution_accum_trait<T>::sum_type sum_type;
+ 
+   for (index_type r=0; r<out_rows; ++r)
+   {
+     for (index_type c=0; c<out_cols; ++c)
+     {
+       sum_type sum = sum_type();
+ 
+       for (index_type rr=0; rr<coeff_rows; ++rr)
+       {
+ 	for (index_type cc=0; cc<coeff_cols; ++cc)
+ 	{
+ 	  if (r*decimation >= rr && r*decimation-rr < in_rows &&
+ 	      c*decimation >= cc && c*decimation-cc < in_cols)
+ 	  {
+ 	    sum += coeff[rr*coeff_row_stride + cc*coeff_col_stride] *
+                    in[(r*decimation-rr) * in_row_stride +
+ 		      (c*decimation-cc) * in_col_stride];
+ 	  }
+ 	}
+       }
+       out[r * out_row_stride + c * out_col_stride] = sum;
+     }
+   }
+ }
+ 
+ 
+ 
+ /// Perform 2-D convolution with same region of support.
+ 
+ template <typename T>
+ inline void
+ conv_same(
+   T*          coeff,
+   length_type coeff_rows,	// Mr
+   length_type coeff_cols,	// Mc
+   stride_type coeff_row_stride,
+   stride_type coeff_col_stride,
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
+   stride_type out_col_stride,
+ 
+   length_type decimation)
+ {
+   typedef typename Convolution_accum_trait<T>::sum_type sum_type;
+ 
+   for (index_type r=0; r<out_rows; ++r)
+   {
+     index_type ir = r*decimation + (coeff_rows/2);
+ 
+     for (index_type c=0; c<out_cols; ++c)
+     {
+       index_type ic = c*decimation + (coeff_cols/2);
+ 
+       sum_type sum = sum_type();
+ 
+       for (index_type rr=0; rr<coeff_rows; ++rr)
+       {
+ 	for (index_type cc=0; cc<coeff_cols; ++cc)
+ 	{
+ 
+ 	  if (ir >= rr && ir-rr < in_rows && ic >= cc && ic-cc < in_cols) 
+ 	  {
+ 	    sum += coeff[rr*coeff_row_stride + cc*coeff_col_stride] *
+ 	           in[(ir-rr) * in_row_stride + (ic-cc) * in_col_stride];
+ 	  }
+ 	}
+       }
+       out[r * out_row_stride + c * out_col_stride] = sum;
+     }
+   }
+ }
+ 
+ 
+ 
+ /// Perform 2-D convolution with minimal region of support.
+ 
+ template <typename T>
+ inline void
+ conv_min(
+   T*          coeff,
+   length_type coeff_rows,	// Mr
+   length_type coeff_cols,	// Mc
+   stride_type coeff_row_stride,
+   stride_type coeff_col_stride,
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
+   stride_type out_col_stride,
+ 
+   length_type decimation)
+ {
+   typedef typename Convolution_accum_trait<T>::sum_type sum_type;
+ 
+ #if VSIP_IMPL_CONV_CORRECT_MIN_SUPPORT_SIZE
+   VSIP_IMPL_THROW(vsip::impl::unimplemented(
+ 	   "conv_min not implemented for Matrix CORRECT_MIN_SUPPORT_SIZE"));
+ #else
+   for (index_type r=0; r<out_rows; ++r)
+   {
+     index_type ir = r*decimation + (coeff_rows-1);
+     for (index_type c=0; c<out_cols; ++c)
+     {
+       index_type ic = c*decimation + (coeff_cols-1);
+ 
+       sum_type sum = sum_type();
+ 
+       for (index_type rr=0; rr<coeff_rows; ++rr)
+       {
+ 	for (index_type cc=0; cc<coeff_cols; ++cc)
+ 	{
+ 	  if (ir-rr < in_rows && ic-cc < in_cols)
+ 	  {
+ 	    sum += coeff[rr*coeff_row_stride + cc*coeff_col_stride] *
+ 	           in[(ir-rr) * in_row_stride + (ic-cc) * in_col_stride];
+ 	  }
+ 	}
+       }
+       out[r * out_row_stride + c * out_col_stride] = sum;
+     }
+   }
+ #endif
+ }
+ 
+ 
+ 
+ /// Perform edge portion of 2-D convolution with same region of support.
+ 
+ /// conv_same = conv_min + conv_same_edge
+ 
+ template <typename T>
+ inline void
+ conv_same_edge(
+   T*          coeff,
+   length_type coeff_rows,	// Mr
+   length_type coeff_cols,	// Mc
+   stride_type coeff_row_stride,
+   stride_type coeff_col_stride,
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
+   stride_type out_col_stride,
+ 
+   length_type decimation)
+ {
+   typedef typename Convolution_accum_trait<T>::sum_type sum_type;
+ 
+   for (index_type r=0; r<out_rows; ++r)
+   {
+     index_type ir = r*decimation + (coeff_rows/2);
+ 
+     for (index_type c=0; c<out_cols; ++c)
+     {
+       index_type ic = c*decimation + (coeff_cols/2);
+ 
+       if ((r < coeff_rows/2 || r >= out_rows-(coeff_rows/2)) ||
+ 	  (c < coeff_cols/2 || c >= out_cols-(coeff_cols/2)))
+       {
+ 	sum_type sum = sum_type();
+ 
+ 	for (index_type rr=0; rr<coeff_rows; ++rr)
+ 	{
+ 	  for (index_type cc=0; cc<coeff_cols; ++cc)
+ 	  {
+ 
+ 	    if (ir >= rr && ir-rr < in_rows && ic >= cc && ic-cc < in_cols) 
+ 	    {
+ 	      sum += coeff[rr*coeff_row_stride + cc*coeff_col_stride] *
+ 		     in[(ir-rr) * in_row_stride + (ic-cc) * in_col_stride];
+ 	    }
+ 	  }
+ 	}
+ 	out[r * out_row_stride + c * out_col_stride] = sum;
+       }
+     }
+   }
+ }
+ 
+ 
+ /// Example of how to combine conv_min and conv_same_edge to achieve
+ /// conv_same.
+ 
+ template <typename T>
+ inline void
+ conv_same_example(
+   T*          coeff,
+   length_type coeff_rows,	// Mr
+   length_type coeff_cols,	// Mc
+   stride_type coeff_row_stride,
+   stride_type coeff_col_stride,
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
+   stride_type out_col_stride,
+ 
+   length_type decimation)
+ {
+   // Determine the first element computed by conv_min.
+   index_type n0_r  = ( (coeff_rows - 1) - (coeff_rows/2) ) / decimation;
+   index_type n0_c  = ( (coeff_cols - 1) - (coeff_cols/2) ) / decimation;
+   index_type res_r = ( (coeff_rows - 1) - (coeff_rows/2) ) % decimation;
+   index_type res_c = ( (coeff_cols - 1) - (coeff_cols/2) ) % decimation;
+   if (res_r > 0) n0_r += 1;
+   if (res_c > 0) n0_c += 1;
+ 
+   // Determine the phase of the input given to conv_min.
+   index_type phase_r = (res_r == 0) ? 0 : (decimation - res_r);
+   index_type phase_c = (res_c == 0) ? 0 : (decimation - res_c);
+ 
+ 
+   // Determine the last element + 1 computed by conv_min.
+   index_type n1_r = (in_rows - (coeff_rows/2)) / decimation;
+   index_type n1_c = (in_cols - (coeff_cols/2)) / decimation;
+   if ((in_rows - (coeff_rows/2)) % decimation > 0) n1_r++;
+   if ((in_cols - (coeff_cols/2)) % decimation > 0) n1_c++;
+ 
+ 
+   T* out_adj = out + (n0_r)*out_row_stride
+ 		   + (n0_c)*out_col_stride;
+   T* in_adj  = in  + (phase_r)*in_row_stride
+ 		   + (phase_c)*in_col_stride;
+ 
+   if (n1_r > n0_r && n1_c > n0_c)
+     conv_min<T>(coeff,
+ 		coeff_rows, coeff_cols,
+ 		coeff_row_stride, coeff_col_stride,
+ 
+ 		in_adj,
+ 		in_rows - phase_r, in_cols - phase_c,
+ 		in_row_stride, in_col_stride,
+ 
+ 		out_adj,
+ 		n1_r - n0_r, n1_c - n0_c,
+ 		out_row_stride, out_col_stride,
+ 		decimation);
+ 
+   conv_same_edge<T>(
+     coeff, coeff_rows, coeff_cols, coeff_row_stride, coeff_col_stride,
+     in, in_rows, in_cols, in_row_stride, in_col_stride,
+     out, out_rows, out_cols, out_row_stride, out_col_stride,
+     decimation);
+ }
+ 
+ 
+ 
  } // namespace vsip::impl
  
  } // namespace vsip
Index: src/vsip/impl/signal-conv-ext.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv-ext.hpp,v
retrieving revision 1.7
diff -c -p -r1.7 signal-conv-ext.hpp
*** src/vsip/impl/signal-conv-ext.hpp	5 Oct 2005 11:41:03 -0000	1.7
--- src/vsip/impl/signal-conv-ext.hpp	4 Dec 2005 21:47:39 -0000
*************** namespace vsip
*** 34,41 ****
  namespace impl
  {
  
! template <typename T>
! struct Is_conv_impl_avail<Generic_tag, T>
  {
    static bool const value = true;
  };
--- 34,42 ----
  namespace impl
  {
  
! template <dimension_type Dim,
! 	  typename       T>
! struct Is_conv_impl_avail<Generic_tag, Dim, T>
  {
    static bool const value = true;
  };
*************** protected:
*** 114,122 ****
  	   Matrix<T, Block1>)
      VSIP_NOTHROW;
  
!   typedef vsip::impl::Layout<1, row1_type, vsip::impl::Stride_unit, vsip::impl::Cmplx_inter_fmt> layout_type;
!   typedef Vector<T> coeff_view_type;
!   typedef impl::Ext_data<typename coeff_view_type::block_type, layout_type> c_ext_type;
  
    // Member data.
  private:
--- 115,128 ----
  	   Matrix<T, Block1>)
      VSIP_NOTHROW;
  
!   typedef vsip::impl::Layout<dim,
! 			     typename Row_major<dim>::type,
! 			     vsip::impl::Stride_unit,
! 			     vsip::impl::Cmplx_inter_fmt>
! 		layout_type;
!   typedef typename View_of_dim<dim, T, Dense<dim, T> >::type coeff_view_type;
!   typedef impl::Ext_data<typename coeff_view_type::block_type, layout_type>
! 		c_ext_type;
  
    // Member data.
  private:
*************** VSIP_THROW((std::bad_alloc))
*** 190,196 ****
  
  
  
! /// Destroy a IPP Convolution_impl object.
  
  template <template <typename, typename> class ConstViewT,
  	  symmetry_type                       Symm,
--- 196,202 ----
  
  
  
! /// Destroy a generic Convolution_impl object.
  
  template <template <typename, typename> class ConstViewT,
  	  symmetry_type                       Symm,
*************** convolve(
*** 280,287 ****
    Matrix<T, Block1>       out)
  VSIP_NOTHROW
  {
!   VSIP_IMPL_THROW(vsip::impl::unimplemented(
! 		    "Convolution_impl<... Generic_tag> does not support Matrix"));
  }
  
  } // namespace vsip::impl
--- 286,342 ----
    Matrix<T, Block1>       out)
  VSIP_NOTHROW
  {
!   length_type const Mr = this->coeff_.size(0);
!   length_type const Mc = this->coeff_.size(1);
! 
!   length_type const Nr = this->input_size_[0].size();
!   length_type const Nc = this->input_size_[1].size();
! 
!   length_type const Pr = this->output_size_[0].size();
!   length_type const Pc = this->output_size_[1].size();
! 
!   assert(Pr == out.size(0) && Pc == out.size(1));
! 
!   typedef vsip::impl::Ext_data<Block0> in_ext_type;
!   typedef vsip::impl::Ext_data<Block1> out_ext_type;
! 
!   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
!   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
! 
!   pm_in_ext_cost_  += in_ext.cost();
!   pm_out_ext_cost_ += out_ext.cost();
! 
!   T* pin    = in_ext.data();
!   T* pout   = out_ext.data();
! 
!   stride_type coeff_row_stride = coeff_ext_.stride(0);
!   stride_type coeff_col_stride = coeff_ext_.stride(1);
!   stride_type in_row_stride    = in_ext.stride(0);
!   stride_type in_col_stride    = in_ext.stride(1);
!   stride_type out_row_stride   = out_ext.stride(0);
!   stride_type out_col_stride   = out_ext.stride(1);
! 
!   if (Supp == support_full)
!   {
!     conv_full<T>(pcoeff_, Mr, Mc, coeff_row_stride, coeff_col_stride,
! 		 pin, Nr, Nc, in_row_stride, in_col_stride,
! 		 pout, Pr, Pc, out_row_stride, out_col_stride,
! 		 decimation_);
!   }
!   else if (Supp == support_same)
!   {
!     conv_same<T>(pcoeff_, Mr, Mc, coeff_row_stride, coeff_col_stride,
! 		 pin, Nr, Nc, in_row_stride, in_col_stride,
! 		 pout, Pr, Pc, out_row_stride, out_col_stride,
! 		 decimation_);
!   }
!   else // (Supp == support_min)
!   {
!     conv_min<T>(pcoeff_, Mr, Mc, coeff_row_stride, coeff_col_stride,
! 		pin, Nr, Nc, in_row_stride, in_col_stride,
! 		pout, Pr, Pc, out_row_stride, out_col_stride,
! 		decimation_);
!   }
  }
  
  } // namespace vsip::impl
Index: src/vsip/impl/signal-conv-ipp.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv-ipp.hpp,v
retrieving revision 1.4
diff -c -p -r1.4 signal-conv-ipp.hpp
*** src/vsip/impl/signal-conv-ipp.hpp	5 Oct 2005 11:41:03 -0000	1.4
--- src/vsip/impl/signal-conv-ipp.hpp	4 Dec 2005 21:47:39 -0000
*************** namespace impl
*** 36,48 ****
  {
  
  template <>
! struct Is_conv_impl_avail<Intel_ipp_tag, float>
  {
    static bool const value = true;
  };
  
  template <>
! struct Is_conv_impl_avail<Intel_ipp_tag, double>
  {
    static bool const value = true;
  };
--- 36,60 ----
  {
  
  template <>
! struct Is_conv_impl_avail<Intel_ipp_tag, 1, float>
  {
    static bool const value = true;
  };
  
  template <>
! struct Is_conv_impl_avail<Intel_ipp_tag, 1, double>
! {
!   static bool const value = true;
! };
! 
! template <>
! struct Is_conv_impl_avail<Intel_ipp_tag, 2, short>
! {
!   static bool const value = true;
! };
! 
! template <>
! struct Is_conv_impl_avail<Intel_ipp_tag, 2, float>
  {
    static bool const value = true;
  };
*************** protected:
*** 121,129 ****
  	   Matrix<T, Block1>)
      VSIP_NOTHROW;
  
!   typedef vsip::impl::Layout<1, row1_type, vsip::impl::Stride_unit, vsip::impl::Cmplx_inter_fmt> layout_type;
!   typedef Vector<T> coeff_view_type;
!   typedef impl::Ext_data<typename coeff_view_type::block_type, layout_type> c_ext_type;
  
    // Member data.
  private:
--- 133,146 ----
  	   Matrix<T, Block1>)
      VSIP_NOTHROW;
  
!   typedef vsip::impl::Layout<dim,
! 			     typename Row_major<dim>::type,
! 			     vsip::impl::Stride_unit,
! 			     vsip::impl::Cmplx_inter_fmt>
! 		layout_type;
!   typedef typename View_of_dim<dim, T, Dense<dim, T> >::type coeff_view_type;
!   typedef impl::Ext_data<typename coeff_view_type::block_type, layout_type>
! 		c_ext_type;
  
    // Member data.
  private:
*************** convolve(
*** 315,322 ****
    Matrix<T, Block1>       out)
  VSIP_NOTHROW
  {
!   VSIP_IMPL_THROW(vsip::impl::unimplemented(
! 		    "Convolution_impl<... Intel_ipp_tag> does not support Matrix"));
  }
  
  } // namespace vsip::impl
--- 332,439 ----
    Matrix<T, Block1>       out)
  VSIP_NOTHROW
  {
!   length_type const Mr = this->coeff_.size(0);
!   length_type const Mc = this->coeff_.size(1);
! 
!   length_type const Nr = this->input_size_[0].size();
!   length_type const Nc = this->input_size_[1].size();
! 
!   length_type const Pr = this->output_size_[0].size();
!   length_type const Pc = this->output_size_[1].size();
! 
!   assert(Pr == out.size(0) && Pc == out.size(1));
! 
!   typedef vsip::impl::Ext_data<Block0> in_ext_type;
!   typedef vsip::impl::Ext_data<Block1> out_ext_type;
! 
!   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
!   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
! 
!   pm_in_ext_cost_  += in_ext.cost();
!   pm_out_ext_cost_ += out_ext.cost();
! 
!   T* pin    = in_ext.data();
!   T* pout   = out_ext.data();
! 
!   stride_type coeff_row_stride = coeff_ext_.stride(0);
!   stride_type coeff_col_stride = coeff_ext_.stride(1);
!   stride_type in_row_stride    = in_ext.stride(0);
!   stride_type in_col_stride    = in_ext.stride(1);
!   stride_type out_row_stride   = out_ext.stride(0);
!   stride_type out_col_stride   = out_ext.stride(1);
! 
!   if (Supp == support_full)
!   {
!     if (decimation_ == 1 && coeff_col_stride == 1 &&
! 	in_ext.stride(1) == 1 && out_ext.stride(1) == 1)
!     {
!       impl::ipp::conv_full_2d(
! 	pcoeff_, Mr, Mc, coeff_row_stride,
! 	pin, Nr, Nc, in_row_stride,
! 	pout, out_row_stride);
!     }
!     else
!     {
!       conv_full<T>(pcoeff_, Mr, Mc, coeff_row_stride, coeff_col_stride,
! 		   pin, Nr, Nc, in_row_stride, in_col_stride,
! 		   pout, Pr, Pc, out_row_stride, out_col_stride,
! 		   decimation_);
!     }
!   }
!   else if (Supp == support_same)
!   {
!     if (decimation_ == 1 && coeff_col_stride == 1 &&
! 	in_ext.stride(1) == 1 && out_ext.stride(1) == 1)
!     {
!       // IPP only provides full- and min-support convolutions.
!       // We implement same-support by doing a min-support and
!       // then filling out the edges.
! 
!       index_type n0_r = (Mr - 1) - (Mr/2);
!       index_type n0_c = (Mc - 1) - (Mc/2);
!       index_type n1_r = Nr - (Mr/2);
!       index_type n1_c = Nc - (Mc/2);
! 
!       T* pout_adj = pout + (n0_r)*out_row_stride
! 			 + (n0_c)*out_col_stride;
! 
!       if (n1_r > n0_r && n1_c > n0_c)
! 	impl::ipp::conv_valid_2d(
! 	  pcoeff_, Mr, Mc, coeff_row_stride,
! 	  pin, Nr, Nc, in_row_stride,
! 	  pout_adj, out_row_stride);
! 
!       conv_same_edge<T>(pcoeff_, Mr, Mc, coeff_row_stride, coeff_col_stride,
! 		   pin, Nr, Nc, in_row_stride, in_col_stride,
! 		   pout, Pr, Pc, out_row_stride, out_col_stride,
! 		   decimation_);
!     }
!     else
!     {
!       conv_same<T>(pcoeff_, Mr, Mc, coeff_row_stride, coeff_col_stride,
! 		   pin, Nr, Nc, in_row_stride, in_col_stride,
! 		   pout, Pr, Pc, out_row_stride, out_col_stride,
! 		   decimation_);
!     }
!   }
!   else // (Supp == support_min)
!   {
!     if (decimation_ == 1 && coeff_col_stride == 1 &&
! 	in_ext.stride(1) == 1 && out_ext.stride(1) == 1)
!     {
!       impl::ipp::conv_valid_2d(
! 	pcoeff_, Mr, Mc, coeff_row_stride,
! 	pin, Nr, Nc, in_row_stride,
! 	pout, out_row_stride);
!     }
!     else
!     {
!       conv_min<T>(pcoeff_, Mr, Mc, coeff_row_stride, coeff_col_stride,
! 		  pin, Nr, Nc, in_row_stride, in_col_stride,
! 		  pout, Pr, Pc, out_row_stride, out_col_stride,
! 		  decimation_);
!     }
!   }
  }
  
  } // namespace vsip::impl
Index: src/vsip/impl/signal-conv-sal.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv-sal.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 signal-conv-sal.hpp
*** src/vsip/impl/signal-conv-sal.hpp	28 Nov 2005 20:44:55 -0000	1.1
--- src/vsip/impl/signal-conv-sal.hpp	4 Dec 2005 21:47:39 -0000
*************** namespace impl
*** 36,48 ****
  {
  
  template <>
! struct Is_conv_impl_avail<Mercury_sal_tag, float>
  {
    static bool const value = true;
  };
  
  template <>
! struct Is_conv_impl_avail<Mercury_sal_tag, std::complex<float> >
  {
    static bool const value = true;
  };
--- 36,48 ----
  {
  
  template <>
! struct Is_conv_impl_avail<Mercury_sal_tag, 1, float>
  {
    static bool const value = true;
  };
  
  template <>
! struct Is_conv_impl_avail<Mercury_sal_tag, 1, std::complex<float> >
  {
    static bool const value = true;
  };
Index: src/vsip/impl/signal-conv.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv.hpp,v
retrieving revision 1.11
diff -c -p -r1.11 signal-conv.hpp
*** src/vsip/impl/signal-conv.hpp	28 Nov 2005 20:44:55 -0000	1.11
--- src/vsip/impl/signal-conv.hpp	4 Dec 2005 21:47:39 -0000
*************** namespace impl
*** 44,56 ****
  {
  
  
! template <typename T>
  struct Choose_conv_impl
  {
    typedef typename
!   ITE_Type<Is_conv_impl_avail<Intel_ipp_tag, T>::value,
  	   As_type<Intel_ipp_tag>, 
!            ITE_Type<Is_conv_impl_avail<Mercury_sal_tag, T>::value,
                      As_type<Mercury_sal_tag>, 
                      As_type<Generic_tag> >
            >::type type;
--- 44,57 ----
  {
  
  
! template <dimension_type Dim,
! 	  typename       T>
  struct Choose_conv_impl
  {
    typedef typename
!   ITE_Type<Is_conv_impl_avail<Intel_ipp_tag, Dim, T>::value,
  	   As_type<Intel_ipp_tag>, 
!            ITE_Type<Is_conv_impl_avail<Mercury_sal_tag, Dim, T>::value,
                      As_type<Mercury_sal_tag>, 
                      As_type<Generic_tag> >
            >::type type;
*************** template <template <typename, typename> 
*** 66,81 ****
            alg_hint_type                       A_hint = alg_time>
  class Convolution
    : public impl::Convolution_impl<ConstViewT, Symm, Supp, T, N_times, A_hint,
! 				  typename impl::Choose_conv_impl<T>::type>
  {
-   typedef impl::Convolution_impl<ConstViewT, Symm, Supp, T, N_times, A_hint,
- 				 typename impl::Choose_conv_impl<T>::type>
- 		base_type;
- 
    // Implementation compile-time constants.
  private:
    static dimension_type const dim = impl::Dim_of_view<ConstViewT>::dim;
  
    // Constructors, copies, assignments, and destructors.
  public:
    template <typename Block>
--- 67,84 ----
            alg_hint_type                       A_hint = alg_time>
  class Convolution
    : public impl::Convolution_impl<ConstViewT, Symm, Supp, T, N_times, A_hint,
!              typename impl::Choose_conv_impl<
!                impl::Dim_of_view<ConstViewT>::dim, T>::type>
  {
    // Implementation compile-time constants.
  private:
    static dimension_type const dim = impl::Dim_of_view<ConstViewT>::dim;
  
+   typedef impl::Convolution_impl<ConstViewT, Symm, Supp, T, N_times, A_hint,
+ 				 typename impl::Choose_conv_impl<dim, T>::type>
+ 		base_type;
+ 
+ 
    // Constructors, copies, assignments, and destructors.
  public:
    template <typename Block>
*************** public:
*** 86,93 ****
        : base_type(filter_coeffs, input_size, decimation)
    {
      assert(decimation >= 1);
!     assert(Symm == nonsym ? (filter_coeffs.size() <=   input_size.length())
! 			  : (filter_coeffs.size() <= 2*input_size.length()));
    }
  
    Convolution(Convolution const&) VSIP_NOTHROW;
--- 89,96 ----
        : base_type(filter_coeffs, input_size, decimation)
    {
      assert(decimation >= 1);
!     assert(Symm == nonsym ? (filter_coeffs.size() <=   input_size.size())
! 			  : (filter_coeffs.size() <= 2*input_size.size()));
    }
  
    Convolution(Convolution const&) VSIP_NOTHROW;
*************** public:
*** 140,145 ****
--- 143,169 ----
  
      return out;
    }
+ 
+   template <typename Block1,
+ 	    typename Block2>
+   Matrix<T, Block2>
+   operator()(
+     const_Matrix<T, Block1> in,
+     Matrix<T, Block2>       out)
+     VSIP_NOTHROW
+   {
+     timer_.start();
+     for (dimension_type d=0; d<dim; ++d)
+       assert(in.size(d) == this->input_size()[d].size());
+ 
+     for (dimension_type d=0; d<dim; ++d)
+       assert(out.size(d) == this->output_size()[d].size());
+ 
+     convolve(in, out);
+     timer_.stop();
+ 
+     return out;
+   }
  #endif
  
    float impl_performance(char* what) const
Index: tests/conv-2d.cpp
===================================================================
RCS file: tests/conv-2d.cpp
diff -N tests/conv-2d.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/conv-2d.cpp	4 Dec 2005 21:47:39 -0000
***************
*** 0 ****
--- 1,564 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    conv-2d.cpp
+     @author  Jules Bergmann
+     @date    2005-12-02
+     @brief   VSIPL++ Library: Unit tests for 2D [signal.convolution] items.
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
+ 
+ #include "test.hpp"
+ #include "output.hpp"
+ 
+ #define VERBOSE 1
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
+ length_type expected_output_size(
+   support_region_type supp,
+   length_type         M,    // kernel length
+   length_type         N,    // input  length
+   length_type         D)    // decimation factor
+ {
+   if      (supp == support_full)
+     return ((N + M - 2)/D) + 1;
+   else if (supp == support_same)
+     return ((N - 1)/D) + 1;
+   else //(supp == support_min)
+   {
+ #if VSIP_IMPL_CONV_CORRECT_MIN_SUPPORT_SIZE
+     return ((N - M + 1) / D) + ((N - M + 1) % D == 0 ? 0 : 1);
+ #else
+     return ((N - 1)/D) - ((M-1)/D) + 1;
+ #endif
+   }
+ }
+ 
+ 
+ 
+ length_type expected_shift(
+   support_region_type supp,
+   length_type         M,     // kernel length
+   length_type         /*D*/) // decimation factor
+ {
+   if      (supp == support_full)
+     return 0;
+   else if (supp == support_same)
+     return (M/2);
+   else //(supp == support_min)
+     return (M-1);
+ }
+ 
+ 
+ template <typename T,
+ 	  typename Block>
+ void
+ init_in(Matrix<T, Block> in, int k)
+ {
+   for (index_type i=0; i<in.size(0); ++i)
+     for (index_type j=0; j<in.size(1); ++j)
+       in(i, j) = T(i*in.size(0)+j+k);
+ }
+ 
+ 
+ 
+ /// Test general 2-D convolution.
+ 
+ template <typename            T,
+ 	  symmetry_type       symmetry,
+ 	  support_region_type support,
+ 	  dimension_type      Dim,
+ 	  typename            T1,
+ 	  typename            Block1>
+ void
+ test_conv(
+   Domain<Dim> const&       dom_in,
+   length_type              D,		// decimation
+   const_Matrix<T1, Block1> coeff,	// coefficients
+   length_type const        n_loop = 2,
+   stride_type const        stride = 1)
+ {
+   length_type Nr = dom_in[0].size();	// input rows
+   length_type Nc = dom_in[1].size();	// input cols
+ 
+   typedef Convolution<const_Matrix, symmetry, support, T> conv_type;
+   typedef typename Matrix<T>::subview_type matrix_subview_type;
+ 
+   length_type M2r = coeff.size(0);
+   length_type M2c = coeff.size(1);
+   length_type Mr, Mc;
+ 
+   if (symmetry == nonsym)
+   {
+     Mr = coeff.size(0);
+     Mc = coeff.size(1);
+   }
+   else if (symmetry == sym_even_len_odd)
+   {
+     Mr = 2*coeff.size(0)-1;
+     Mc = 2*coeff.size(1)-1;
+   }
+   else /* (symmetry == sym_even_len_even) */
+   {
+     Mr = 2*coeff.size(0);
+     Mc = 2*coeff.size(1);
+   }
+ 
+   length_type const Pr = expected_output_size(support, Mr, Nr, D);
+   length_type const Pc = expected_output_size(support, Mc, Nc, D);
+ 
+   int shift_r = expected_shift(support, Mr, D);
+   int shift_c = expected_shift(support, Mc, D);
+ 
+   Matrix<T> kernel(Mr, Mc, T());
+ 
+   // Apply symmetry (if any) to get kernel form coefficients.
+   if (symmetry == nonsym)
+   {
+     kernel = coeff;
+   }
+   else if (symmetry == sym_even_len_odd)
+   {
+     kernel(Domain<2>(M2r, M2c))   = coeff;
+     kernel(Domain<2>(M2r, Domain<1>(M2c, 1, M2c-1))) =
+       coeff(Domain<2>(M2r, Domain<1>(M2c-2, -1, M2c-1)));
+ 
+     kernel(Domain<2>(Domain<1>(M2r, 1, M2r-1), 2*M2c-1)) = 
+       kernel(Domain<2>(Domain<1>(M2r-2, -1, M2r-1), 2*M2c-1));
+   }
+   else /* (symmetry == sym_even_len_even) */
+   {
+     kernel(Domain<2>(M2r, M2c))   = coeff;
+     kernel(Domain<2>(M2r, Domain<1>(M2c, 1, M2c))) =
+       coeff(Domain<2>(M2r, Domain<1>(M2c-1, -1, M2c)));
+     kernel(Domain<2>(Domain<1>(M2r, 1, M2r), 2*M2c)) = 
+       kernel(Domain<2>(Domain<1>(M2r-1, -1, M2r), 2*M2c));
+   }
+ 
+ 
+   conv_type conv(coeff, Domain<2>(Nr, Nc), D);
+ 
+   assert(conv.symmetry() == symmetry);
+   assert(conv.support()  == support);
+ 
+   assert(conv.kernel_size()[0].size()  == Mr);
+   assert(conv.kernel_size()[1].size()  == Mc);
+ 
+   assert(conv.filter_order()[0].size() == Mr);
+   assert(conv.filter_order()[1].size() == Mc);
+ 
+   assert(conv.input_size()[0].size()   == Nr);
+   assert(conv.input_size()[1].size()   == Nc);
+ 
+   assert(conv.output_size()[0].size()  == Pr);
+   assert(conv.output_size()[1].size()  == Pc);
+ 
+   Matrix<T> in_base(Nr * stride, Nc * stride);
+   Matrix<T> out_base(Pr * stride, Pc * stride, T(100));
+   Matrix<T> ex(Pr, Pc, T(101));
+ 
+   matrix_subview_type in  = in_base (Domain<2>(
+ 				       Domain<1>(0, stride, Nr),
+ 				       Domain<1>(0, stride, Nc)));
+   matrix_subview_type out = out_base(Domain<2>(
+ 				       Domain<1>(0, stride, Pr),
+ 				       Domain<1>(0, stride, Pc)));
+ 
+   Matrix<T> sub(Mr, Mc);
+ 
+   for (index_type loop=0; loop<n_loop; ++loop)
+   {
+     init_in(in, 3*loop);
+ 
+     conv(in, out);
+ 
+     // Check result
+     bool good = true;
+     for (index_type i=0; i<Pr; ++i)
+       for (index_type j=0; j<Pc; ++j)
+       {
+ 	sub = T();
+ 	index_type ii = i*D + shift_r;
+ 	index_type jj = j*D + shift_c;
+ 
+ 	Domain<1> sub_d0, sub_d1;
+ 	Domain<1> rhs_d0, rhs_d1;
+ 
+ 	// Determine rows to copy
+ 	if (ii+1 < Mr)
+ 	{
+ 	  sub_d0 = Domain<1>(0, 1, ii+1);
+ 	  rhs_d0 = Domain<1>(ii, -1, ii+1);
+ 	}
+ 	else if (ii >= Nr)
+ 	{
+ 	  index_type start = ii - Nr + 1;
+ 	  sub_d0 = Domain<1>(start, 1, Mr-start);
+ 	  rhs_d0 = Domain<1>(Nr-1, -1, Mr-start);
+ 	}
+ 	else
+ 	{
+ 	  sub_d0 = Domain<1>(0, 1, Mr);
+ 	  rhs_d0 = Domain<1>(ii, -1, Mr);
+ 	}
+ 
+ 	// Determine cols to copy
+ 	if (jj+1 < Mc)
+ 	{
+ 	  sub_d1 = Domain<1>(0, 1, jj+1);
+ 	  rhs_d1 = Domain<1>(jj, -1, jj+1);
+ 	}
+ 	else if (jj >= Nc)
+ 	{
+ 	  index_type start = jj - Nc + 1;
+ 	  sub_d1 = Domain<1>(start, 1, Mc-start);
+ 	  rhs_d1 = Domain<1>(Nc-1, -1, Mc-start);
+ 	}
+ 	else
+ 	{
+ 	  sub_d1 = Domain<1>(0, 1, Mc);
+ 	  rhs_d1 = Domain<1>(jj, -1, Mc);
+ 	}
+ 
+ 	sub(Domain<2>(sub_d0, sub_d1)) = in(Domain<2>(rhs_d0, rhs_d1));
+ 	  
+ 	T val = out(i, j);
+ 	T chk = sumval(kernel * sub);
+ 
+ 	ex(i, j) = chk;
+ 
+ 	// assert(equal(val, chk));
+ 	if (!equal(val, chk))
+ 	  good = false;
+       }
+ 
+     if (!good)
+     {
+ #if VERBOSE
+       cout << "in = ("       << Nr << ", " << Nc
+ 	   << ")  coeff = (" << Mr << ", " << Mc << ")  D=" << D << endl;
+       cout << "out =\n" << out << endl;
+       cout << "ex =\n" << ex << endl;
+ #endif
+       assert(0);
+     }
+   }
+ }
+ 
+ 
+ 
+ /// Test convolution with nonsym symmetry.
+ 
+ template <typename            T,
+ 	  support_region_type support>
+ void
+ test_conv_nonsym(
+   length_type Nr,	// input rows
+   length_type Nc,	// input cols
+   length_type Mr,	// coeff rows
+   length_type Mc,	// coeff cols
+   index_type  r,
+   index_type  c,
+   int         k1)
+ {
+   symmetry_type const        symmetry = nonsym;
+ 
+   typedef Convolution<const_Matrix, symmetry, support, T> conv_type;
+ 
+   length_type const D = 1;				// decimation
+ 
+   length_type const Pr = expected_output_size(support, Mr, Nr, D);
+   length_type const Pc = expected_output_size(support, Mc, Nc, D);
+ 
+   int shift_r = expected_shift(support, Mr, D);
+   int shift_c = expected_shift(support, Mc, D);
+ 
+   Matrix<T> coeff(Mr, Mc, T());
+ 
+   coeff(r, c) = T(k1);
+ 
+   conv_type conv(coeff, Domain<2>(Nr, Nc), D);
+ 
+   assert(conv.symmetry() == symmetry);
+   assert(conv.support()  == support);
+ 
+   assert(conv.kernel_size()[0].size()  == Mr);
+   assert(conv.kernel_size()[1].size()  == Mc);
+ 
+   assert(conv.filter_order()[0].size() == Mr);
+   assert(conv.filter_order()[1].size() == Mc);
+ 
+   assert(conv.input_size()[0].size()   == Nr);
+   assert(conv.input_size()[1].size()   == Nc);
+ 
+   assert(conv.output_size()[0].size()  == Pr);
+   assert(conv.output_size()[1].size()  == Pc);
+ 
+ 
+   Matrix<T> in(Nr, Nc);
+   Matrix<T> out(Pr, Pc, T(100));
+   Matrix<T> ex(Pr, Pc, T(100));
+ 
+   init_in(in, 0);
+ 
+   conv(in, out);
+ 
+   bool good = true;
+   for (index_type i=0; i<Pr; ++i)
+   {
+     for (index_type j=0; j<Pc; ++j)
+     {
+       T val;
+ 
+       if ((int)i + shift_r - (int)r < 0 || i + shift_r - r >= Nr ||
+ 	  (int)j + shift_c - (int)c < 0 || j + shift_c - c >= Nc)
+ 	val = T();
+       else
+ 	val = in(i + shift_r - r, j + shift_c - c);
+ 
+       ex(i, j) = T(k1) * val;
+       if (!equal(out(i, j), ex(i, j)))
+ 	good = false;
+     }
+   }
+ 
+   if (!good)
+   {
+ #if VERBOSE
+     cout << "out =\n" << out << endl;
+     cout << "ex =\n" << ex << endl;
+ #endif
+     assert(0);
+   }
+ }
+ 
+ 
+ 
+ // Run a set of convolutions for given type and size
+ //   (with symmetry = nonsym and decimation = 1).
+ 
+ template <typename T>
+ void
+ cases_nonsym(
+   length_type i_r,	// input rows
+   length_type i_c,	// input cols
+   length_type k_r,	// kernel rows
+   length_type k_c)	// kernel cols
+ {
+   test_conv_nonsym<T, support_min>(i_r, i_c, k_r, k_c,     0,     0, +1);
+   test_conv_nonsym<T, support_min>(i_r, i_c, k_r, k_c, k_r/2, k_c/2, -2);
+   test_conv_nonsym<T, support_min>(i_r, i_c, k_r, k_c,     0, k_c-1, +3);
+   test_conv_nonsym<T, support_min>(i_r, i_c, k_r, k_c, k_r-1,     0, -4);
+   test_conv_nonsym<T, support_min>(i_r, i_c, k_r, k_c, k_r-1, k_c-1, +5);
+ 
+   test_conv_nonsym<T, support_same>(i_r, i_c, k_r, k_c,     0,     0, +1);
+   test_conv_nonsym<T, support_same>(i_r, i_c, k_r, k_c, k_r/2, k_c/2, -2);
+   test_conv_nonsym<T, support_same>(i_r, i_c, k_r, k_c,     0, k_c-1, +3);
+   test_conv_nonsym<T, support_same>(i_r, i_c, k_r, k_c, k_r-1,     0, -4);
+   test_conv_nonsym<T, support_same>(i_r, i_c, k_r, k_c, k_r-1, k_c-1, +5);
+ 
+   test_conv_nonsym<T, support_full>(i_r, i_c, k_r, k_c,     0,     0, +1);
+   test_conv_nonsym<T, support_full>(i_r, i_c, k_r, k_c, k_r/2, k_c/2, -2);
+   test_conv_nonsym<T, support_full>(i_r, i_c, k_r, k_c,     0, k_c-1, +3);
+   test_conv_nonsym<T, support_full>(i_r, i_c, k_r, k_c, k_r-1,     0, -4);
+   test_conv_nonsym<T, support_full>(i_r, i_c, k_r, k_c, k_r-1, k_c-1, +5);
+ }
+ 
+ 
+ 
+ // Run a set of convolutions for given type and size
+ //   (using vectors with strides other than one).
+ 
+ template <typename       T,
+ 	  dimension_type Dim>
+ void
+ cases_nonunit_stride(Domain<Dim> const& size)
+ {
+   length_type const n_loop = 2;
+   length_type const D      = 1;
+ 
+   Rand<T> rgen(0);
+   Matrix<T> coeff33(3, 3, T()); coeff33 = rgen.randu(3, 3);
+   Matrix<T> coeff23(2, 3, T()); coeff23 = rgen.randu(2, 3);
+   Matrix<T> coeff32(3, 2, T()); coeff32 = rgen.randu(3, 2);
+ 
+   test_conv<T, nonsym, support_min>(size, D, coeff33, n_loop, 3);
+   test_conv<T, nonsym, support_min>(size, D, coeff33, n_loop, 2);
+ 
+   test_conv<T, nonsym, support_full>(size, D, coeff32, n_loop, 3);
+   test_conv<T, nonsym, support_full>(size, D, coeff23, n_loop, 2);
+ 
+   test_conv<T, nonsym, support_same>(size, D, coeff23, n_loop, 3);
+   test_conv<T, nonsym, support_same>(size, D, coeff32, n_loop, 2);
+ }
+ 
+ 
+ 
+ // Run a set of convolutions for given type, symmetry, input size, coeff size
+ // and decmiation.
+ 
+ template <typename       T,
+ 	  symmetry_type  Sym,
+ 	  dimension_type Dim>
+ void
+ cases_conv(
+   Domain<Dim> const& size,
+   Domain<Dim> const& M,
+   length_type        D,
+   bool               rand)
+ {
+   typename impl::View_of_dim<Dim, T, Dense<Dim, T> >::type
+ 		coeff(M[0].size(), M[1].size(), T());
+ 
+   if (rand)
+   {
+     Rand<T> rgen(0);
+     coeff = rgen.randu(M[0].size(), M[1].size());
+   }
+   else
+   {
+     coeff(0, 0)                         = T(-1);
+     coeff(M[0].size()-1, M[1].size()-1) = T(2);
+   }
+ 
+   test_conv<T, Sym, support_min> (size, D, coeff);
+   test_conv<T, Sym, support_same>(size, D, coeff);
+   test_conv<T, Sym, support_full>(size, D, coeff);
+ }
+ 
+ 
+ 
+ // Run a single convolutions for given type, symmetry, support, input
+ // size, coeff size and decmiation.
+ 
+ template <typename            T,
+ 	  symmetry_type       Sym,
+ 	  support_region_type Sup,
+ 	  dimension_type      Dim>
+ void
+ single_conv(
+   Domain<Dim> const& size, 
+   Domain<Dim> const& M,
+   length_type        D,
+   length_type        n_loop,
+   bool               rand)
+ {
+   typename impl::View_of_dim<Dim, T, Dense<Dim, T> >::type
+ 		coeff(M[0].size(), M[1].size(), T());
+ 
+   if (rand)
+   {
+     Rand<T> rgen(0);
+     coeff = rgen.randu(M[0].size(), M[1].size());
+   }
+   else
+   {
+     coeff(0, 0)                         = T(-1);
+     coeff(M[0].size()-1, M[1].size()-1) = T(2);
+   }
+ 
+   test_conv<T, Sym, Sup>(size, D, coeff, n_loop);
+ }
+ 
+ 
+ 
+ template <typename T>
+ void
+ cases(bool rand)
+ {
+   // check that M == N works
+   cases_conv<T, nonsym>(Domain<2>(8, 8), Domain<2>(8, 8), 1, rand);
+   cases_conv<T, nonsym>(Domain<2>(5, 5), Domain<2>(5, 5), 1, rand);
+   cases_conv<T, sym_even_len_even>(Domain<2>(8, 8), Domain<2>(4, 4), 1, rand);
+   cases_conv<T, sym_even_len_odd> (Domain<2>(7, 7), Domain<2>(4, 4), 1, rand);
+ 
+   cases_conv<T, nonsym>(Domain<2>(5, 5), Domain<2>(4, 4), 1, rand);
+   cases_conv<T, nonsym>(Domain<2>(5, 5), Domain<2>(4, 4), 2, rand);
+   cases_conv<T, nonsym>(Domain<2>(5, 5), Domain<2>(4, 4), 3, rand);
+   cases_conv<T, nonsym>(Domain<2>(5, 5), Domain<2>(4, 4), 4, rand);
+ 
+   for (length_type size=8; size<=256; size *= 8)
+   {
+     cases_nonsym<T>(size,     size, 3, 3);
+     cases_nonsym<T>(size+3, size-1, 3, 2);
+ 
+     cases_nonunit_stride<T>(Domain<2>(size, size));
+ 
+     cases_conv<T, nonsym>(Domain<2>(size,   size),   Domain<2>(3, 3), 1, rand);
+     cases_conv<T, nonsym>(Domain<2>(2*size, size-1), Domain<2>(4, 3), 2, rand);
+   }
+ 
+   length_type fixed_size = 64;
+ 
+   cases_conv<T, sym_even_len_even>(Domain<2>(fixed_size, fixed_size),
+ 				   Domain<2>(2, 3), 1, rand);
+   cases_conv<T, sym_even_len_even>(Domain<2>(fixed_size-1, fixed_size+2),
+ 				   Domain<2>(3, 2), 2, rand);
+ 
+   cases_conv<T, sym_even_len_odd>(Domain<2>(fixed_size, fixed_size),
+ 				  Domain<2>(2, 3), 3, rand);
+   cases_conv<T, sym_even_len_odd>(Domain<2>(fixed_size+3, fixed_size-2),
+ 				  Domain<2>(3, 2), 4, rand);
+ }
+ 
+ 
+ 
+ int
+ main()
+ {
+ #if 1
+   // General tests.
+   bool rand = true;
+   cases<short>(rand);
+   cases<int>(rand);
+   cases<float>(rand);
+   cases<double>(rand);
+   // cases<complex<int> >(rand);
+   cases<complex<float> >(rand);
+   // cases<complex<double> >(rand);
+ 
+   cases_nonsym<complex<int> >(8, 8, 3, 3);
+   cases_nonsym<complex<float> >(8, 8, 3, 3);
+   cases_nonsym<complex<double> >(8, 8, 3, 3);
+ #endif
+ 
+ #if 0
+   // small sets of tests, covered by 'cases()' above
+   cases_nonsym<int>(8, 8, 3, 3);
+   cases_nonsym<float>(8, 8, 3, 3);
+   cases_nonsym<double>(8, 8, 3, 3);
+   cases_nonsym<complex<int> >(8, 8, 3, 3);
+   cases_nonsym<complex<float> >(8, 8, 3, 3);
+   cases_nonsym<complex<double> >(8, 8, 3, 3);
+ 
+   // individual tests, covered by 'cases()' above
+   test_conv_nonsym<int, support_min>(8, 8, 3, 3, 1, 1, 1);
+   test_conv_nonsym<int, support_min>(8, 8, 3, 3, 0, 2, -1);
+   test_conv_nonsym<int, support_min>(8, 8, 3, 3, 2, 0, 2);
+   test_conv_nonsym<int, support_min>(8, 8, 3, 3, 2, 2, -2);
+ 
+   test_conv_nonsym<int, support_same>(8, 8, 3, 3, 1, 1, 1);
+   test_conv_nonsym<int, support_same>(8, 8, 3, 3, 0, 2, -1);
+   test_conv_nonsym<int, support_same>(8, 8, 3, 3, 2, 0, 2);
+ 
+   test_conv_nonsym<int, support_full>(8, 8, 3, 3, 1, 1, 1);
+   test_conv_nonsym<int, support_full>(8, 8, 3, 3, 0, 0, 2);
+   test_conv_nonsym<int, support_full>(8, 8, 3, 3, 2, 2, -1);
+ #endif
+ }
