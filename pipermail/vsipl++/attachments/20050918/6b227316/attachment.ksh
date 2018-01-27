Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.37
diff -c -p -r1.37 configure.ac
*** configure.ac	17 Sep 2005 20:36:49 -0000	1.37
--- configure.ac	19 Sep 2005 03:33:49 -0000
*************** if test "$enable_fftw2" != "no" ; then
*** 275,281 ****
    vsip_impl_use_float=1
    vsip_impl_fftw2=1
  
-   # FIXME: this will need rework to support double
    FFT_CPPFLAGS=
    FFT_LDFLAGS=
    if test -n "$with_fftw2_prefix"; then
--- 275,280 ----
Index: src/vsip/copy_chain.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/copy_chain.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 copy_chain.cpp
*** src/vsip/copy_chain.cpp	16 Sep 2005 21:51:08 -0000	1.3
--- src/vsip/copy_chain.cpp	19 Sep 2005 03:33:49 -0000
*************** Copy_chain::copy_into(void* dest, size_t
*** 107,115 ****
  // Requires:
  //   CHAIN to be copy chain with the same number of bytes and same
  //     element sizes as this chain.
! //
! // FIXME-050729-jpb: Remove restriction that source and destination must
! //                   have same element size.
  void
  Copy_chain::copy_into(Copy_chain dst_chain) const
  {
--- 107,113 ----
  // Requires:
  //   CHAIN to be copy chain with the same number of bytes and same
  //     element sizes as this chain.
! //   In addition, Source and destination must have same element size.
  void
  Copy_chain::copy_into(Copy_chain dst_chain) const
  {
Index: src/vsip/domain.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/domain.hpp,v
retrieving revision 1.14
diff -c -p -r1.14 domain.hpp
*** src/vsip/domain.hpp	25 Aug 2005 19:40:48 -0000	1.14
--- src/vsip/domain.hpp	19 Sep 2005 03:33:49 -0000
*************** public:
*** 34,41 ****
  inline bool 
  operator==(Index<1> const& i, Index<1> const& j) VSIP_NOTHROW
  {
-   // FIXME: The following line would fail to compile. Why ?
-   //   return operator==<index_type>(i, j);
    return 
      static_cast<Vertex<index_type, 1> >(i) == 
      static_cast<Vertex<index_type, 1> >(j);
--- 34,39 ----
Index: src/vsip/impl/fft-core.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft-core.hpp,v
retrieving revision 1.14
diff -c -p -r1.14 fft-core.hpp
*** src/vsip/impl/fft-core.hpp	17 Sep 2005 17:08:08 -0000	1.14
--- src/vsip/impl/fft-core.hpp	19 Sep 2005 03:33:49 -0000
*************** convert_flags(unsigned will_call)
*** 498,509 ****
    return FFTW_ESTIMATE;
  }
  
- // FIXME: it appears FFTW3 is capable of using Fast_block;
- //   i.e. its inembed/onembed arguments to fftw_plan_many_dft()
- //   allow for internal alignment padding.
- // 
- //   Also, for complex<->complex xforms, FFTW3 can operate on 
- //   transposed views by playing stride games.
  
  
  // FFTW3 complex -> complex, plan FFT
--- 498,503 ----
*************** struct Ipp_DFT_base
*** 1002,1008 ****
    forward(void* plan, void const* in, void* out, void* buffer, bool f)
        VSIP_NOTHROW
    {
-     // FIXME: is sizeof(T) correct, or should it be 2*sizeof(T) some places?
      IppStatus result = (f ?
        (*forwardFFun1)(
  	reinterpret_cast<T const*>(in),
--- 996,1001 ----
*************** struct Ipp_DFT_base
*** 1018,1024 ****
    static void
    forward2(void* plan, void const* in, void* out, void* buffer, bool f) VSIP_NOTHROW
    {
-     // FIXME: is sizeof(T) correct, or should it be 2*sizeof(T) some places?
      IppStatus result = (f ?
        (*forwardFFun2)(
  	reinterpret_cast<T const*>(in), sizeof(T),
--- 1011,1016 ----
*************** struct Ipp_DFT_base
*** 1034,1040 ****
    static void
    inverse(void* plan, void const* in, void* out, void* buffer, bool f) VSIP_NOTHROW
    {
-     // FIXME: is sizeof(T) correct, or should it be 2*sizeof(T) some places?
      IppStatus result = (f ?
        (*inverseFFun1)(
  	reinterpret_cast<T const*>(in), 
--- 1026,1031 ----
*************** struct Ipp_DFT_base
*** 1050,1056 ****
    static void
    inverse2(void* plan, void const* in, void* out, void* buffer, bool f) VSIP_NOTHROW
    {
-     // FIXME: is sizeof(T) correct, or should it be 2*sizeof(T) some places?
      IppStatus result = (f ?
        (*inverseFFun2)(
  	reinterpret_cast<T const*>(in), sizeof(T),
--- 1041,1046 ----
*************** struct Ipp_DFT<1,float>
*** 1164,1170 ****
  
  // 2D, R to C, float
  
- // FIXME: need unpack adapter
  template <>
  struct Ipp_DFT<2,float>
    : Ipp_DFT_base<
--- 1154,1159 ----
*************** from_to(
*** 1414,1426 ****
    SCALAR_TYPE const* /*in*/, std::complex<SCALAR_TYPE>* /*out*/)
      VSIP_NOTHROW
  {  
-   // FIXME: not implemented yet.
    VSIP_IMPL_THROW(impl::unimplemented(
  		    "IPP FFT-2D real->complex not implemented"));
  #if 0  
    Ipp_DFT<1,SCALAR_TYPE>::forward2(
      self.plan_from_to_, in, out, self.p_buffer_, self.use_fft_) ;
!   // FIXME: unpack in place
    if (self.doing_scaling_)
      self.scale_ = 1.0;
  #endif
--- 1403,1414 ----
    SCALAR_TYPE const* /*in*/, std::complex<SCALAR_TYPE>* /*out*/)
      VSIP_NOTHROW
  {  
    VSIP_IMPL_THROW(impl::unimplemented(
  		    "IPP FFT-2D real->complex not implemented"));
  #if 0  
    Ipp_DFT<1,SCALAR_TYPE>::forward2(
      self.plan_from_to_, in, out, self.p_buffer_, self.use_fft_) ;
!   // unpack in place
    if (self.doing_scaling_)
      self.scale_ = 1.0;
  #endif
*************** from_to(
*** 1455,1465 ****
    std::complex<SCALAR_TYPE> const* /*in*/, SCALAR_TYPE* /*out*/)
       VSIP_NOTHROW
  {
-   // FIXME: not implemented yet
    VSIP_IMPL_THROW(impl::unimplemented(
  		    "IPP FFT-2D complex->real not implemented"));
  #if 0  
!   // FIXME: pack in place; maybe this must happen in
    //   fft_by_ref, where _in_, just copied into, is writeable.
    Ipp_DFT<1,SCALAR_TYPE>::inverse2(
      self.plan_from_to_, in, out, self.p_buffer_, self.use_fft_) ;
--- 1443,1452 ----
    std::complex<SCALAR_TYPE> const* /*in*/, SCALAR_TYPE* /*out*/)
       VSIP_NOTHROW
  {
    VSIP_IMPL_THROW(impl::unimplemented(
  		    "IPP FFT-2D complex->real not implemented"));
  #if 0  
!   // pack in place; maybe this must happen in
    //   fft_by_ref, where _in_, just copied into, is writeable.
    Ipp_DFT<1,SCALAR_TYPE>::inverse2(
      self.plan_from_to_, in, out, self.p_buffer_, self.use_fft_) ;
*************** Fft_core<Dim,inT,outT,doFftm>::~Fft_core
*** 1560,1566 ****
                std::complex<SCALAR_TYPE>,std::complex<SCALAR_TYPE>,false>;
  
  #if ! defined(VSIP_IMPL_IPP_FFT)
-   // FIXME: for IPP, need pack/unpack code
    template class Fft_core<2,SCALAR_TYPE,std::complex<SCALAR_TYPE>,false>;
    template class Fft_core<2,std::complex<SCALAR_TYPE>,SCALAR_TYPE,false>;
  #endif
--- 1547,1552 ----
Index: src/vsip/impl/global_map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/global_map.hpp,v
retrieving revision 1.5
diff -c -p -r1.5 global_map.hpp
*** src/vsip/impl/global_map.hpp	16 Sep 2005 21:51:08 -0000	1.5
--- src/vsip/impl/global_map.hpp	19 Sep 2005 03:33:49 -0000
*************** public:
*** 53,61 ****
    subblock_iterator subblocks_end  (processor_type /*pr*/) const VSIP_NOTHROW
      { return subblock_iterator(1, 1); }
  
!   // FIXME: Implement processor_begin/end for Global_map
!   // processor_iterator processor_begin(subblock_type sb) const VSIP_NOTHROW;
!   // processor_iterator processor_end  (subblock_type sb) const VSIP_NOTHROW;
  
    // Applied map functions.
  public:
--- 53,62 ----
    subblock_iterator subblocks_end  (processor_type /*pr*/) const VSIP_NOTHROW
      { return subblock_iterator(1, 1); }
  
!   processor_iterator processor_begin(subblock_type /*sb*/) const VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Global_map::processor_begin()")); }
!   processor_iterator processor_end  (subblock_type /*sb*/) const VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Global_map::processor_end()")); }
  
    // Applied map functions.
  public:
Index: src/vsip/impl/local_map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/local_map.hpp,v
retrieving revision 1.3
diff -c -p -r1.3 local_map.hpp
*** src/vsip/impl/local_map.hpp	16 Sep 2005 21:51:08 -0000	1.3
--- src/vsip/impl/local_map.hpp	19 Sep 2005 03:33:49 -0000
*************** public:
*** 62,70 ****
    subblock_iterator subblocks_end  (processor_type /*pr*/) const VSIP_NOTHROW
      { return subblock_iterator(1, 1); }
  
!   // FIXME: Implement processor_begin/end for Global_map
!   // processor_iterator processor_begin(subblock_type sb) const VSIP_NOTHROW;
!   // processor_iterator processor_end  (subblock_type sb) const VSIP_NOTHROW;
  
    // Applied map functions.
  public:
--- 62,71 ----
    subblock_iterator subblocks_end  (processor_type /*pr*/) const VSIP_NOTHROW
      { return subblock_iterator(1, 1); }
  
!   processor_iterator processor_begin(subblock_type /*sb*/) const VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Local_map::processor_begin()")); }
!   processor_iterator processor_end  (subblock_type /*sb*/) const VSIP_NOTHROW
!     { VSIP_IMPL_THROW(impl::unimplemented("Local_map::processor_end()")); }
  
    // Applied map functions.
  public:
Index: src/vsip/impl/signal-conv.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv.hpp,v
retrieving revision 1.8
diff -c -p -r1.8 signal-conv.hpp
*** src/vsip/impl/signal-conv.hpp	12 Sep 2005 11:57:16 -0000	1.8
--- src/vsip/impl/signal-conv.hpp	19 Sep 2005 03:33:49 -0000
*************** public:
*** 87,95 ****
  
    // Convolution operators.
  public:
! #if FIXME_USE_IMPL_VIEWS
!   // Need to fix problem identified in impl_views.cpp testcase with
!   // passing real() or imag() subviews to Convolution.
    template <template <typename, typename> class V1,
  	    template <typename, typename> class V2,
  	    typename Block1,
--- 87,93 ----
  
    // Convolution operators.
  public:
! #if USE_IMPL_VIEWS
    template <template <typename, typename> class V1,
  	    template <typename, typename> class V2,
  	    typename Block1,
Index: src/vsip/impl/signal-fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-fft.hpp,v
retrieving revision 1.23
diff -c -p -r1.23 signal-fft.hpp
*** src/vsip/impl/signal-fft.hpp	18 Sep 2005 22:03:43 -0000	1.23
--- src/vsip/impl/signal-fft.hpp	19 Sep 2005 03:33:49 -0000
*************** struct Fft_aligned
*** 162,168 ****
      vsip::Dense<Dim,T,vsip::tuple<0,1,2>,Map_type>
  #else
  
!     // FIXME: Need to use the correct stride (to get to the next
      // row/column) given the padding before we can use Fast_block 
      // for FFTs.  This will require making the interface to the
      // FFT engines a little more complicated.
--- 162,168 ----
      vsip::Dense<Dim,T,vsip::tuple<0,1,2>,Map_type>
  #else
  
!     // Need to use the correct stride (to get to the next
      // row/column) given the padding before we can use Fast_block 
      // for FFTs.  This will require making the interface to the
      // FFT engines a little more complicated.
*************** protected:
*** 458,466 ****
      void
    impl_fft_in_place(View<outT,BlockT>& inout) VSIP_NOTHROW
    {
-     // FIXME: don't bother transposing between two axes that
-     // have the same size -- the result's the same either way.
-  
      typedef impl::Layout<
          Fft_imp::dim,vsip::tuple<0,1,2>,impl::Stride_unit,impl::Cmplx_inter_fmt>
        layout_type;
--- 458,463 ----
*************** public:
*** 486,495 ****
    {
      if (!strcmp(what, "mflops"))
      {
!       // FIXME: equation is correct for c-to-c of all dimensions,
!       //        but only close for r-to-c and c-to-r.  FFTW3 can
!       //        report exactly.
! 
        float sz  = size(this->input_size_);
        float ops = 5 * sz * logf(sz)/logf(2.f);
        if (sizeof(inT) != sizeof(outT)) ops /= 2.f;
--- 483,489 ----
    {
      if (!strcmp(what, "mflops"))
      {
!       // Compute rough estimate of flop-count.
        float sz  = size(this->input_size_);
        float ops = 5 * sz * logf(sz)/logf(2.f);
        if (sizeof(inT) != sizeof(outT)) ops /= 2.f;
*************** protected:
*** 754,762 ****
        static const vsip::dimension_type  transpose_target = axis;
  #endif
  
-     // FIXME: avoid copying for transposed subview or column-major input;
-     //   Extract and use the native-order view of the underlying data.
- 
      typedef typename vsip::const_Matrix<inT,Block0>::local_type const
        local_in_type;
  
--- 748,753 ----
*************** protected:
*** 824,831 ****
          "Fftm requires the dimension being processed to be undistributed"));
  
      { 
-       // FIXME: avoid copying for transposed subview input;
-       //   Extract and use the native-order view of the underlying data.
  
  #if defined(VSIP_IMPL_FFTW3)
        static const bool  must_copy = (sD == vsip::col);
--- 815,820 ----
Index: tests/distributed-subviews.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/distributed-subviews.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 distributed-subviews.cpp
*** tests/distributed-subviews.cpp	5 Aug 2005 15:43:48 -0000	1.2
--- tests/distributed-subviews.cpp	19 Sep 2005 03:33:49 -0000
*************** test_row_sum(
*** 160,167 ****
        dump_map<1>(view.row(r).block().map());
        comm.barrier();
      }
!     // my_sum += view.row(r); // FIXME
!     my_sum = my_sum + view.row(r); // FIXME
    }
  
    typename global_view1_t::local_type local_my_sum  = get_local_view(my_sum);
--- 160,166 ----
        dump_map<1>(view.row(r).block().map());
        comm.barrier();
      }
!     my_sum = my_sum + view.row(r);
    }
  
    typename global_view1_t::local_type local_my_sum  = get_local_view(my_sum);
Index: tests/expression.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/expression.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 expression.cpp
*** tests/expression.cpp	11 May 2005 04:53:15 -0000	1.5
--- tests/expression.cpp	19 Sep 2005 03:33:49 -0000
*************** using namespace impl;
*** 26,34 ****
    Definitions
  ***********************************************************************/
  
- // FIXME: Put Zack's ramp utility into a common tests/header
- //        and use it here. (or something similar)
- //
  // initialize elements according to block(i) = a * i + b
  template <typename Block>
  void ramp(Block& block, index_type a = 1, index_type b = 1)
--- 26,31 ----
Index: tests/extdata-matadd.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/extdata-matadd.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 extdata-matadd.cpp
*** tests/extdata-matadd.cpp	18 Jun 2005 16:40:45 -0000	1.3
--- tests/extdata-matadd.cpp	19 Sep 2005 03:33:49 -0000
*************** struct Matrix_add<TR, T1, T2, BlockR, Bl
*** 351,357 ****
      typedef typename BlockR::layout_type layout_type;
      typedef impl::No_count_policy RP;
  
!     // FIXME:
      // assert((impl::Ext_data<BlockR, layout_type>::CT_Mem_not_req));
      // assert((impl::Ext_data<Block1, layout_type>::CT_Mem_not_req));
      // assert((impl::Ext_data<Block2, layout_type>::CT_Mem_not_req));
--- 351,357 ----
      typedef typename BlockR::layout_type layout_type;
      typedef impl::No_count_policy RP;
  
!     // Check that no memory is required.
      // assert((impl::Ext_data<BlockR, layout_type>::CT_Mem_not_req));
      // assert((impl::Ext_data<Block1, layout_type>::CT_Mem_not_req));
      // assert((impl::Ext_data<Block2, layout_type>::CT_Mem_not_req));
Index: tests/extdata-subviews.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/extdata-subviews.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 extdata-subviews.cpp
*** tests/extdata-subviews.cpp	1 Sep 2005 20:02:16 -0000	1.5
--- tests/extdata-subviews.cpp	19 Sep 2005 03:33:50 -0000
*************** void
*** 785,791 ****
  test_matrix_transpose(
    Matrix<T, BlockT> /*view*/)
  {
-   // FIXME when matrix transpose subview implemented.
  }
  
  
--- 785,790 ----
Index: tests/extdata.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/extdata.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 extdata.cpp
*** tests/extdata.cpp	18 Jun 2005 16:40:45 -0000	1.4
--- tests/extdata.cpp	19 Sep 2005 03:33:50 -0000
*************** template <typename T1,
*** 219,232 ****
  	  typename T2,
  	  typename Block1,
  	  typename Block2>
! // FIXME: typename Promotion<T1, T2>::type
! T1
  dotp_view(
    const_Vector<T1, Block1> op1,
    const_Vector<T2, Block2> op2)
  {
!   // typedef typename Promotion<T1, T2>::type value_type;
!   typedef T1 value_type;
  
    assert(op1.size() == op2.size());
  
--- 219,230 ----
  	  typename T2,
  	  typename Block1,
  	  typename Block2>
! typename Promotion<T1, T2>::type
  dotp_view(
    const_Vector<T1, Block1> op1,
    const_Vector<T2, Block2> op2)
  {
!   typedef typename Promotion<T1, T2>::type value_type;
  
    assert(op1.size() == op2.size());
  
*************** template <typename T1,
*** 248,261 ****
  	  typename T2,
  	  typename Block1,
  	  typename Block2>
! // FIXME: typename Promotion<T1, T2>::type
! T1
  dotp_ext(
    const_Vector<T1, Block1> op1,
    const_Vector<T2, Block2> op2)
  {
!   // typedef typename Promotion<T1, T2>::type value_type;
!   typedef T1 value_type;
  
    assert(op1.size() == op2.size());
  
--- 246,257 ----
  	  typename T2,
  	  typename Block1,
  	  typename Block2>
! typename Promotion<T1, T2>::type
  dotp_ext(
    const_Vector<T1, Block1> op1,
    const_Vector<T2, Block2> op2)
  {
!   typedef typename Promotion<T1, T2>::type value_type;
  
    assert(op1.size() == op2.size());
  
*************** main()
*** 604,610 ****
  
    test_dense_2();
  
!   // FIXME-050413-jpb: Make 1-dim direct data views of N-dim blocks work.
    // test_dense_12<float, row2_type>();
    // test_dense_12<float, col2_type>();
    // test_dense_12<int,   row2_type>();
--- 600,606 ----
  
    test_dense_2();
  
!   // Test 1-dim direct data views of N-dim blocks.
    // test_dense_12<float, row2_type>();
    // test_dense_12<float, col2_type>();
    // test_dense_12<int,   row2_type>();
Index: tests/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 fft.cpp
*** tests/fft.cpp	8 Aug 2005 06:19:21 -0000	1.5
--- tests/fft.cpp	19 Sep 2005 03:33:50 -0000
*************** error_db(
*** 112,123 ****
  
    for (index_type i=0; i<v1.size(); ++i)
    {
- #if FIXME_USE_MAGSQ
      double val = magsq(v1.get(i));
- #else
-     double tmp = std::abs(v1.get(i));
-     double val = tmp*tmp;
- #endif
      if (val > refmax)
        refmax = val;
    }
--- 112,118 ----
*************** error_db(
*** 125,136 ****
  
    for (index_type i=0; i<v1.size(); ++i)
    {
- #if FIXME_USE_MAGSQ
      double val = magsq(v1.get(i) - v2.get(i));
- #else
-     double tmp = std::abs(v1.get(i) - v2.get(i));
-     double val = tmp*tmp;
- #endif
  
      if (val < 1.e-20)
        sum = -201.;
--- 120,126 ----
Index: tests/fftm-par.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fftm-par.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 fftm-par.cpp
*** tests/fftm-par.cpp	18 Sep 2005 01:45:02 -0000	1.2
--- tests/fftm-par.cpp	19 Sep 2005 03:33:50 -0000
*************** main(int argc, char** argv)
*** 750,756 ****
    test_by_val_y<complex<float> >(256);
  
  #if 0
!   // FIXME: implement tests for test r->c, c->r
    test_real<float>(128);
    test_real<float>(242);
    test_real<float>(16);
--- 750,756 ----
    test_by_val_y<complex<float> >(256);
  
  #if 0
!   // Tests for test r->c, c->r.
    test_real<float>(128);
    test_real<float>(242);
    test_real<float>(16);
Index: tests/fftm.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fftm.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 fftm.cpp
*** tests/fftm.cpp	10 Sep 2005 10:18:43 -0000	1.5
--- tests/fftm.cpp	19 Sep 2005 03:33:50 -0000
*************** error_db(
*** 125,136 ****
    for (index_type j=0; j < v1.size(0); ++j)
      for (index_type i=0; i < v1.size(1); ++i)
      {
-   #if FIXME_USE_MAGSQ
        double val = magsq(v1.get(j,i));
-   #else
-       double tmp = std::abs(v1.get(j,i));
-       double val = tmp*tmp;
-   #endif
        if (val > refmax)
  	refmax = val;
      }
--- 125,131 ----
*************** error_db(
*** 138,149 ****
    for (index_type j=0; j < v1.size(0); ++j)
      for (index_type i=0; i < v1.size(1); ++i)
      {
-   #if FIXME_USE_MAGSQ
        double val = magsq(v1.get(j,i) - v2.get(j,i));
-   #else
-       double tmp = std::abs(v1.get(j,i) - v2.get(j,i));
-       double val = tmp*tmp;
-   #endif
  
        if (val < 1.e-20)
  	sum = -201.;
--- 133,139 ----
*************** main()
*** 504,510 ****
    test_by_val_y<complex<float> >(256);
  
  #if 0
!   // FIXME: implement tests for test r->c, c->r
    test_real<float>(128);
    test_real<float>(242);
    test_real<float>(16);
--- 494,500 ----
    test_by_val_y<complex<float> >(256);
  
  #if 0
!   // Tests for test r->c, c->r.
    test_real<float>(128);
    test_real<float>(242);
    test_real<float>(16);
Index: tests/initfini.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/initfini.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 initfini.cpp
*** tests/initfini.cpp	18 Jun 2005 16:40:45 -0000	1.4
--- tests/initfini.cpp	19 Sep 2005 03:33:50 -0000
*************** using namespace vsip;
*** 26,32 ****
  static void
  use_the_library ()
  {
!   // FIXME: This routine should attempt to use the library in some
    // relatively simple way (say, create a couple of vectors and add
    // them) to check that it is properly initialized at this point.
    // We cannot do this until more of the library is written.
--- 26,32 ----
  static void
  use_the_library ()
  {
!   // This routine should attempt to use the library in some
    // relatively simple way (say, create a couple of vectors and add
    // them) to check that it is properly initialized at this point.
    // We cannot do this until more of the library is written.
Index: tests/solver-cholesky.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-cholesky.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 solver-cholesky.cpp
*** tests/solver-cholesky.cpp	13 Sep 2005 16:39:45 -0000	1.2
--- tests/solver-cholesky.cpp	19 Sep 2005 03:33:50 -0000
*************** using namespace vsip;
*** 42,49 ****
    Load_view utility.
  ***********************************************************************/
  
! // FIXME: This is nearly same as sarsim LoadView, but doesn't include
! //        byte ordering.  Move this into common location.
  
  template <typename T>
  struct Load_view_traits
--- 42,49 ----
    Load_view utility.
  ***********************************************************************/
  
! // This is nearly same as sarsim LoadView, but doesn't include byte
! // ordering.  Move this into common location.
  
  template <typename T>
  struct Load_view_traits
Index: tests/solver-common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-common.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 solver-common.hpp
*** tests/solver-common.hpp	13 Sep 2005 16:39:45 -0000	1.2
--- tests/solver-common.hpp	19 Sep 2005 03:33:50 -0000
***************
*** 24,31 ****
    Definitions
  ***********************************************************************/
  
- // FIXME: Remove this when selgen.hpp gets checked in.
- 
  template <typename T>
  vsip::const_Vector<T>
  test_ramp(
--- 24,29 ----
Index: tests/solver-llsqsol.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-llsqsol.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 solver-llsqsol.cpp
*** tests/solver-llsqsol.cpp	13 Sep 2005 16:39:45 -0000	1.2
--- tests/solver-llsqsol.cpp	19 Sep 2005 03:33:50 -0000
*************** test_llsqsol_random(
*** 102,112 ****
    randm(a);
    randm(b);
  
!   // FIXME:
!   //   If m > n, min || AX - B || may not be zero,
!   //   Need way to check that X is best solution
    //
!   //   In the meantime, limit rank of A, B to produce zero minimum.
  
    for (index_type i=n; i<m; ++i)
    {
--- 102,111 ----
    randm(a);
    randm(b);
  
!   // If m > n, min || AX - B || may not be zero,
!   // Need way to check that X is best solution
    //
!   // In the meantime, limit rank of A, B to produce zero minimum.
  
    for (index_type i=n; i<m; ++i)
    {
Index: tests/solver-qr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-qr.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 solver-qr.cpp
*** tests/solver-qr.cpp	13 Sep 2005 16:39:45 -0000	1.3
--- tests/solver-qr.cpp	19 Sep 2005 03:33:50 -0000
*************** test_lsqsol_random(
*** 256,266 ****
    randm(a);
    randm(b);
  
!   // FIXME:
!   //   If m > n, min || AX - B || may not be zero,
!   //   Need way to check that X is best solution
    //
!   //   In the meantime, limit rank of A, B to produce zero minimum.
  
    for (index_type i=n; i<m; ++i)
    {
--- 256,265 ----
    randm(a);
    randm(b);
  
!   // If m > n, min || AX - B || may not be zero,
!   // Need way to check that X is best solution
    //
!   // In the meantime, limit rank of A, B to produce zero minimum.
  
    for (index_type i=n; i<m; ++i)
    {
*************** test_f_lsqsol_random(
*** 909,919 ****
    randm(a);
    randm(b);
  
!   // FIXME:
!   //   If m > n, min || AX - B || may not be zero,
!   //   Need way to check that X is best solution
    //
!   //   In the meantime, limit rank of A, B to produce zero minimum.
  
    for (index_type i=n; i<m; ++i)
    {
--- 908,917 ----
    randm(a);
    randm(b);
  
!   // If m > n, min || AX - B || may not be zero,
!   // Need way to check that X is best solution
    //
!   // In the meantime, limit rank of A, B to produce zero minimum.
  
    for (index_type i=n; i<m; ++i)
    {
Index: tests/static_assert.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/static_assert.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 static_assert.cpp
*** tests/static_assert.cpp	18 Jun 2005 16:40:45 -0000	1.5
--- tests/static_assert.cpp	19 Sep 2005 03:33:50 -0000
***************
*** 21,30 ****
    Macros
  ***********************************************************************/
  
! // FIXME: eventually we will need a way to have negative-compile
! //        test cases, i.e. ones that pass when compilation fails.
! //        For now, enable failing tests manually and check that the
! //        compilation fails.
  
  #define ILLEGAL1 0
  #define ILLEGAL2 0
--- 21,28 ----
    Macros
  ***********************************************************************/
  
! // This test contains negative-compile test cases.  To test, enable
! // one of the tests manually and check that the compilation fails.
  
  #define ILLEGAL1 0
  #define ILLEGAL2 0
Index: tests/tensor_subview.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/tensor_subview.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 tensor_subview.cpp
*** tests/tensor_subview.cpp	8 Jul 2005 21:27:18 -0000	1.1
--- tests/tensor_subview.cpp	19 Sep 2005 03:33:50 -0000
*************** t_subvector(
*** 212,219 ****
    check_v(vec1, obj1);
    check_v(vec2, obj1);
    check_v(vec3, obj1);
- 
-   // FIXME: Test Ext_data 
  }
  
  
--- 212,217 ----
*************** test_tensor_matrix()
*** 316,323 ****
  
    assert(ten(0, whole, whole).size(0) == N);
    assert(ten(0, whole, whole).size(1) == P);
- 
-   // FIXME: Test matrix subview values.
  }
    
  
--- 314,319 ----
Index: tests/fft_ext/fft_ext.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft_ext/fft_ext.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 fft_ext.cpp
*** tests/fft_ext/fft_ext.cpp	17 Sep 2005 17:08:08 -0000	1.2
--- tests/fft_ext/fft_ext.cpp	19 Sep 2005 03:33:50 -0000
*************** error_db(
*** 149,160 ****
  
    for (index_type i=0; i<v1.size(); ++i)
    {
- #if FIXME_USE_MAGSQ
      double val = magsq(v1.get(i));
- #else
-     double tmp = std::abs(v1.get(i));
-     double val = tmp*tmp;
- #endif
      if (val > refmax)
        refmax = val;
    }
--- 149,155 ----
*************** error_db(
*** 162,173 ****
  
    for (index_type i=0; i<v1.size(); ++i)
    {
- #if FIXME_USE_MAGSQ
      double val = magsq(v1.get(i) - v2.get(i));
- #else
-     double tmp = std::abs(v1.get(i) - v2.get(i));
-     double val = tmp*tmp;
- #endif
  
      if (val < 1.e-20)
        sum = -201.;
--- 157,163 ----
