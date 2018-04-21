Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.271
diff -c -p -r1.271 ChangeLog
*** ChangeLog	23 Sep 2005 19:21:36 -0000	1.271
--- ChangeLog	23 Sep 2005 19:57:51 -0000
***************
*** 1,5 ****
--- 1,26 ----
  2005-09-23  Jules Bergmann  <jules@codesourcery.com>
  
+ 	* apps/sarsim/sarsim.hpp: Align frame buffers.  Report signal
+ 	  processing object performance.
+ 	* benchmarks/conv.cpp: Make kernel length a command-line parameter.
+ 	* benchmarks/fft.cpp: Benchmark in-place vs out-of-place FFTs.
+ 	* src/vsip/parallel.hpp: New file, single header to pull in
+ 	  parallel bits.
+ 	* src/vsip/vector.hpp: Have op-assigns go through dispatch
+ 	  when possible.
+ 	* src/vsip/impl/par-foreach.hpp: New file, implement parallel
+ 	  foreach.
+ 	* src/vsip/impl/signal-conv.hpp: Add 'time' query to impl_perf.
+ 	* src/vsip/impl/signal-fft.hpp: Likewise.
+ 	* src/vsip/impl/solver-covsol.hpp: Throw computation error
+ 	  if decomposition fails.
+ 	* src/vsip/impl/subblock.hpp (get_local_block): Properly handle
+ 	  a Subset_block with a by-value superblock.
+ 	* tests/extdata-output.hpp: Specializations for subblocks and
+ 	  layout.
+ 
+ 2005-09-23  Jules Bergmann  <jules@codesourcery.com>
+ 
  	* VERSIONS: New file, describes varius CVS tagged versions of
  	  the software.  Recorded V_0_9 tag.
  
Index: apps/sarsim/sarsim.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/apps/sarsim/sarsim.hpp,v
retrieving revision 1.8
diff -c -p -r1.8 sarsim.hpp
*** apps/sarsim/sarsim.hpp	12 Sep 2005 13:11:25 -0000	1.8
--- apps/sarsim/sarsim.hpp	23 Sep 2005 19:57:51 -0000
*************** SarSim<T>::SarSim(index_type nrange,
*** 242,261 ****
  template <typename T>
  void
  SarSim<T>::init_io(index_type nframe) {
    input_frame_buffer_  = new cval_type*[nframe];
    output_frame_buffer_ = new cval_type*[nframe];
  
    assert(cube_in_.block().admitted() == false);
  
    for (index_type frame = 0; frame < nframe; ++frame) {
!     input_frame_buffer_[frame] = new cval_type[cube_in_.size()];
  
      cube_in_.block().rebind(input_frame_buffer_[frame]);
      cube_in_.block().admit(false);
      read_frame<cube_in_block_type>(cube_in_, frame == 0);
      cube_in_.block().release(true);
  
!     output_frame_buffer_[frame] = new cval_type[cube_out_.size()];
    }
  }
  
--- 242,269 ----
  template <typename T>
  void
  SarSim<T>::init_io(index_type nframe) {
+   using vsip::impl::alloc_align;
+ 
+   int align = 256;
+ 
    input_frame_buffer_  = new cval_type*[nframe];
    output_frame_buffer_ = new cval_type*[nframe];
  
    assert(cube_in_.block().admitted() == false);
  
    for (index_type frame = 0; frame < nframe; ++frame) {
!     input_frame_buffer_[frame] =
!       static_cast<cval_type*>(alloc_align(align,
! 				cube_in_.size() * sizeof(cval_type)));
  
      cube_in_.block().rebind(input_frame_buffer_[frame]);
      cube_in_.block().admit(false);
      read_frame<cube_in_block_type>(cube_in_, frame == 0);
      cube_in_.block().release(true);
  
!     output_frame_buffer_[frame] =
!       static_cast<cval_type*>(alloc_align(align,
! 				cube_out_.size() * sizeof(cval_type)));
    }
  }
  
*************** SarSim<T>::fini_io(index_type nframe) {
*** 277,284 ****
  
    // Free up resources allocated in init_io.
    for (index_type frame = 0; frame < nframe; ++frame) {
!     delete[] input_frame_buffer_[frame];
!     delete[] output_frame_buffer_[frame];
    }
  
    delete[] input_frame_buffer_;
--- 285,292 ----
  
    // Free up resources allocated in init_io.
    for (index_type frame = 0; frame < nframe; ++frame) {
!     vsip::impl::free_align((void*)input_frame_buffer_[frame]);
!     vsip::impl::free_align((void*)output_frame_buffer_[frame]);
    }
  
    delete[] input_frame_buffer_;
*************** SarSim<T>::report_performance() const
*** 518,534 ****
  
    printf("Range Processing  : %7.2f mflops (%6.2f s)\n",
  	 rp_mflops, rp_time_.total());
!   printf("   range fft      : %7.2f mflops\n",
! 	 range_fft_.impl_performance("mflops"));
!   printf("   iconv          : %7.2f mflops\n",
! 	 iconv_.impl_performance("mflops"));
!   printf("   qconv          : %7.2f mflops\n",
! 	 qconv_.impl_performance("mflops"));
  
    printf("Azimuth Processing: %7.2f mflops (%6.2f s)\n",
  	 ap_mflops, ap_time_.total());
!   printf("   az for fft     : %7.2f mflops\n",
! 	 az_for_fft_.impl_performance("mflops"));
!   printf("   az inv fft     : %7.2f mflops\n",
! 	 az_inv_fft_.impl_performance("mflops"));
  }
--- 526,547 ----
  
    printf("Range Processing  : %7.2f mflops (%6.2f s)\n",
  	 rp_mflops, rp_time_.total());
!   printf("   range fft      : %7.2f mflops (%6.2f s)\n",
! 	 range_fft_.impl_performance("mflops"),
! 	 range_fft_.impl_performance("time"));
!   printf("   iconv          : %7.2f mflops (%6.2f s)\n",
! 	 iconv_.impl_performance("mflops"),
! 	 iconv_.impl_performance("time"));
!   printf("   qconv          : %7.2f mflops (%6.2f s)\n",
! 	 qconv_.impl_performance("mflops"),
! 	 qconv_.impl_performance("time"));
  
    printf("Azimuth Processing: %7.2f mflops (%6.2f s)\n",
  	 ap_mflops, ap_time_.total());
!   printf("   az for fft     : %7.2f mflops (%6.2f s)\n",
! 	 az_for_fft_.impl_performance("mflops"),
! 	 az_for_fft_.impl_performance("time"));
!   printf("   az inv fft     : %7.2f mflops (%6.2f s)\n",
! 	 az_inv_fft_.impl_performance("mflops"),
! 	 az_inv_fft_.impl_performance("time"));
  }
Index: benchmarks/conv.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/conv.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 conv.cpp
*** benchmarks/conv.cpp	7 Sep 2005 12:19:30 -0000	1.2
--- benchmarks/conv.cpp	23 Sep 2005 19:57:51 -0000
*************** test(Loop1P& loop, int what)
*** 143,153 ****
  {
    switch (what)
    {
!   case  1: loop(t_conv1<support_full, float>(16)); break;
!   case  2: loop(t_conv1<support_same, float>(16)); break;
!   case  3: loop(t_conv1<support_min,  float>(16)); break;
  
!   case  4: loop(t_conv1<support_full, complex<float> >(16)); break;
    default: return 0;
    }
    return 1;
--- 143,153 ----
  {
    switch (what)
    {
!   case  1: loop(t_conv1<support_full, float>(loop.user_param_)); break;
!   case  2: loop(t_conv1<support_same, float>(loop.user_param_)); break;
!   case  3: loop(t_conv1<support_min,  float>(loop.user_param_)); break;
  
!   case  4: loop(t_conv1<support_full, complex<float> >(loop.user_param_)); break;
    default: return 0;
    }
    return 1;
Index: benchmarks/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/fft.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 fft.cpp
*** benchmarks/fft.cpp	7 Sep 2005 12:19:30 -0000	1.2
--- benchmarks/fft.cpp	23 Sep 2005 19:57:51 -0000
*************** fft_ops(length_type len)
*** 33,41 ****
  
  
  template <typename T>
! struct t_fft
  {
!   char* what() { return "t_fft"; }
    int ops_per_point(length_type len)  { return fft_ops(len); }
    int riob_per_point(length_type) { return -1*sizeof(T); }
    int wiob_per_point(length_type) { return -1*sizeof(T); }
--- 33,41 ----
  
  
  template <typename T>
! struct t_fft_op
  {
!   char* what() { return "t_fft_op"; }
    int ops_per_point(length_type len)  { return fft_ops(len); }
    int riob_per_point(length_type) { return -1*sizeof(T); }
    int wiob_per_point(length_type) { return -1*sizeof(T); }
*************** struct t_fft
*** 64,70 ****
      
      if (!equal(Z(0), T(size)))
      {
!       std::cout << "t_fft: ERROR" << std::endl;
        abort();
      }
      
--- 64,109 ----
      
      if (!equal(Z(0), T(size)))
      {
!       std::cout << "t_fft_op: ERROR" << std::endl;
!       abort();
!     }
!     
!     time = t1.delta();
!   }
! };
! 
! 
! 
! template <typename T>
! struct t_fft_ip
! {
!   char* what() { return "t_fft_ip"; }
!   int ops_per_point(length_type len)  { return fft_ops(len); }
!   int riob_per_point(length_type) { return -1*sizeof(T); }
!   int wiob_per_point(length_type) { return -1*sizeof(T); }
! 
!   void operator()(length_type size, length_type loop, float& time)
!   {
!     Vector<T>   A(size, T(0));
! 
!     // int const no_times = 0; // FFTW_PATIENT
!     int const no_times = 15; // not > 12 = FFT_MEASURE
! 
!     typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times, alg_time>
!       fft_type;
! 
!     fft_type fft(Domain<1>(size), 1.f);
! 
!     vsip::impl::profile::Timer t1;
!     
!     t1.start();
!     for (index_type l=0; l<loop; ++l)
!       fft(A);
!     t1.stop();
!     
!     if (!equal(A(0), T(0)))
!     {
!       std::cout << "t_fft_ip: ERROR" << std::endl;
        abort();
      }
      
*************** test(Loop1P& loop, int what)
*** 87,93 ****
  {
    switch (what)
    {
!   case  1: loop(t_fft<complex<float> >()); break;
    default: return 0;
    }
    return 1;
--- 126,133 ----
  {
    switch (what)
    {
!   case  1: loop(t_fft_op<complex<float> >()); break;
!   case  2: loop(t_fft_ip<complex<float> >()); break;
    default: return 0;
    }
    return 1;
Index: src/vsip/parallel.hpp
===================================================================
RCS file: src/vsip/parallel.hpp
diff -N src/vsip/parallel.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/parallel.hpp	23 Sep 2005 19:57:51 -0000
***************
*** 0 ****
--- 1,20 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/parallel.hpp
+     @author  Jules Bergmann
+     @date    2005-03-31
+     @brief   VSIPL++ Library: Parallel support functions and operations.
+ 
+ */
+ 
+ #ifndef VSIP_PARALLEL_HPP
+ #define VSIP_PARALLEL_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/impl/setup-assign.hpp>
+ #include <vsip/impl/par-util.hpp>
+ 
+ #endif // VSIP_PARALLEL_HPP
Index: src/vsip/vector.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/vector.hpp,v
retrieving revision 1.30
diff -c -p -r1.30 vector.hpp
*** src/vsip/vector.hpp	16 Sep 2005 22:03:20 -0000	1.30
--- src/vsip/vector.hpp	23 Sep 2005 19:57:51 -0000
*************** public:
*** 121,129 ****
    for (index_type i = 0; i < this->size(); i++) \
      this->put(i, this->get(i) op val)
  
! #define VSIP_IMPL_ELEMENTWISE_VECTOR(op)                        \
!   for (index_type i = (assert(this->size() == v.size()), 0);    \
!        i < this->size(); i++)                                   \
      this->put(i, this->get(i) op v.get(i))
    
  #define VSIP_IMPL_ASSIGN_OP(asop, op)			   	   \
--- 121,132 ----
    for (index_type i = 0; i < this->size(); i++) \
      this->put(i, this->get(i) op val)
  
! #define VSIP_IMPL_ELEMENTWISE_VECTOR(op)	                   \
!   *this = *this op v;
! 
! #define VSIP_IMPL_ELEMENTWISE_VECTOR_NOFWD(op)			   \
!   for (index_type i = (assert(this->size() == v.size()), 0);	   \
!        i < this->size(); i++)					   \
      this->put(i, this->get(i) op v.get(i))
    
  #define VSIP_IMPL_ASSIGN_OP(asop, op)			   	   \
*************** public:
*** 137,142 ****
--- 140,156 ----
    Vector& operator asop(const Vector<T0, Block0>& v) VSIP_NOTHROW  \
    { VSIP_IMPL_ELEMENTWISE_VECTOR(op); return *this;}
  
+ #define VSIP_IMPL_ASSIGN_OP_NOFWD(asop, op)			   \
+   template <typename T0>                                           \
+   Vector& operator asop(T0 const& val) VSIP_NOTHROW                \
+   { VSIP_IMPL_ELEMENTWISE_SCALAR(op); return *this;}               \
+   template <typename T0, typename Block0>                          \
+   Vector& operator asop(const_Vector<T0, Block0>& v) VSIP_NOTHROW  \
+   { VSIP_IMPL_ELEMENTWISE_VECTOR_NOFWD(op); return *this;}	   \
+   template <typename T0, typename Block0>                          \
+   Vector& operator asop(const Vector<T0, Block0>& v) VSIP_NOTHROW  \
+   { VSIP_IMPL_ELEMENTWISE_VECTOR_NOFWD(op); return *this;}
+ 
  
  /// View which appears as a one-dimensional, modifiable vector.  This
  /// inherits from const_Vector, so only the members that const_Vector
*************** public:
*** 255,267 ****
    VSIP_IMPL_ASSIGN_OP(/=, /)
    VSIP_IMPL_ASSIGN_OP(&=, &)
    VSIP_IMPL_ASSIGN_OP(|=, |)
!   VSIP_IMPL_ASSIGN_OP(^=, ^)
  
  };
  
  #undef VSIP_IMPL_ASSIGN_OP
  #undef VSIP_IMPL_ELEMENTWISE_SCALAR
  #undef VSIP_IMPL_ELEMENTWISE_VECTOR
  
  // [view.vector.convert]
  template <typename T, typename Block>
--- 269,283 ----
    VSIP_IMPL_ASSIGN_OP(/=, /)
    VSIP_IMPL_ASSIGN_OP(&=, &)
    VSIP_IMPL_ASSIGN_OP(|=, |)
!   VSIP_IMPL_ASSIGN_OP_NOFWD(^=, ^) // Remove NOFWD when operator^ implented
  
  };
  
  #undef VSIP_IMPL_ASSIGN_OP
  #undef VSIP_IMPL_ELEMENTWISE_SCALAR
  #undef VSIP_IMPL_ELEMENTWISE_VECTOR
+ #undef VSIP_IMPL_ASSIGN_OP_NOFWD
+ #undef VSIP_IMPL_ELEMENTWISE_VECTOR_NOFWD
  
  // [view.vector.convert]
  template <typename T, typename Block>
Index: src/vsip/impl/par-foreach.hpp
===================================================================
RCS file: src/vsip/impl/par-foreach.hpp
diff -N src/vsip/impl/par-foreach.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/par-foreach.hpp	23 Sep 2005 19:57:51 -0000
***************
*** 0 ****
--- 1,436 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/par-foreach.hpp
+     @author  Jules Bergmann
+     @date    2005-06-08
+     @brief   VSIPL++ Library: Parallel foreach.
+ 
+ */
+ 
+ #ifndef VSIP_IMPL_PAR_FOREACH_HPP
+ #define VSIP_IMPL_PAR_FOREACH_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/impl/par-services.hpp>
+ #include <vsip/support.hpp>
+ #include <vsip/vector.hpp>
+ #include <vsip/matrix.hpp>
+ #include <vsip/impl/distributed-block.hpp>
+ #include <vsip/impl/point.hpp>
+ #include <vsip/impl/point-fcn.hpp>
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ namespace vsip
+ {
+ 
+ namespace impl
+ {
+ 
+ template <typename Order>
+ struct subview;
+ 
+ template <>
+ struct subview<tuple<0, 1, 2> >
+ {
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename Tensor<T, BlockT>::template subvector<0, 1>::impl_type
+   vector(Tensor<T, BlockT> view, index_type i, index_type j)
+   {
+     return view(i, j, whole_domain);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template subvector<0, 1>::impl_type
+   vector(const_Tensor<T, BlockT> view, index_type i, index_type j)
+   {
+     return view(i, j, whole_domain);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename Tensor<T, BlockT>::template submatrix<1, 2>::impl_type
+   matrix(Tensor<T, BlockT> view, index_type i)
+   {
+     return view(i, whole_domain, whole_domain);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template submatrix<1, 2>::impl_type
+   matrix(const_Tensor<T, BlockT> view, index_type i)
+   {
+     return view(i, whole_domain, whole_domain);
+   }
+ 
+   static index_type first (index_type i, index_type) { return i; }
+   static index_type second(index_type, index_type j) { return j; }
+ };
+ 
+ 
+ 
+ template <>
+ struct subview<tuple<0, 2, 1> >
+ {
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename Tensor<T, BlockT>::template subvector<0, 2>::impl_type
+   vector(Tensor<T, BlockT> view, index_type i, index_type j)
+   {
+     return view(i, whole_domain, j);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template subvector<0, 2>::impl_type
+   vector(const_Tensor<T, BlockT> view, index_type i, index_type j)
+   {
+     return view(i, whole_domain, j);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename Tensor<T, BlockT>::template submatrix<2, 1>::impl_type
+   matrix(Tensor<T, BlockT> view, index_type i)
+   {
+     assert(0);
+     // return view(i, whole_domain, whole_domain).transpose();
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template submatrix<2, 1>::impl_type
+   matrix(const_Tensor<T, BlockT> view, index_type i)
+   {
+     assert(0);
+     // return view(i, whole_domain, whole_domain).transpose();
+   }
+ 
+   static index_type first (index_type i, index_type) { return i; }
+   static index_type second(index_type, index_type j) { return j; }
+ };
+ 
+ 
+ 
+ template <>
+ struct subview<tuple<1, 0, 2> >
+ {
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename Tensor<T, BlockT>::template subvector<0, 1>::impl_type
+   vector(Tensor<T, BlockT> view, index_type i, index_type j)
+   {
+     return view(j, i, whole_domain);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template subvector<0, 1>::impl_type
+   vector(const_Tensor<T, BlockT> view, index_type i, index_type j)
+   {
+     return view(j, i, whole_domain);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename Tensor<T, BlockT>::template submatrix<0, 2>::impl_type
+   matrix(Tensor<T, BlockT> view, index_type i)
+   {
+     return view(whole_domain, i, whole_domain);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template submatrix<0, 2>::impl_type
+   matrix(const_Tensor<T, BlockT> view, index_type i)
+   {
+     return view(whole_domain, i, whole_domain);
+   }
+ 
+   static index_type first (index_type, index_type j) { return j; }
+   static index_type second(index_type i, index_type) { return i; }
+ };
+ 
+ 
+ 
+ template <>
+ struct subview<tuple<1, 2, 0> >
+ {
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename Tensor<T, BlockT>::template subvector<0, 2>::impl_type
+   vector(Tensor<T, BlockT> view, index_type i, index_type j)
+   {
+     return view(j, whole_domain, i);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template subvector<0, 2>::impl_type
+   vector(const_Tensor<T, BlockT> view, index_type i, index_type j)
+   {
+     return view(j, whole_domain, i);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename Tensor<T, BlockT>::template submatrix<0, 1>::impl_type
+   matrix(Tensor<T, BlockT> view, index_type i)
+   {
+     return view(whole_domain, whole_domain, i);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template submatrix<0, 1>::impl_type
+   matrix(const_Tensor<T, BlockT> view, index_type i)
+   {
+     return view(whole_domain, whole_domain, i);
+   }
+ 
+   static index_type first (index_type, index_type j) { return j; }
+   static index_type second(index_type i, index_type) { return i; }
+ };
+ 
+ 
+ 
+ template <>
+ struct subview<tuple<2, 0, 1> >
+ {
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename Tensor<T, BlockT>::template subvector<1, 2>::impl_type
+   vector(Tensor<T, BlockT> view, index_type i, index_type j)
+   {
+     return view(whole_domain, i, j);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template subvector<1, 2>::impl_type
+   vector(const_Tensor<T, BlockT> view, index_type i, index_type j)
+   {
+     return view(whole_domain, i, j);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template submatrix<2, 0>::impl_type
+   matrix(Tensor<T, BlockT> view, index_type i)
+   {
+     assert(0);
+     // return view(whole_domain, i, whole_domain).transpose();
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template submatrix<2, 0>::impl_type
+   matrix(const_Tensor<T, BlockT> view, index_type i)
+   {
+     assert(0);
+     // return view(whole_domain, i, whole_domain).transpose();
+   }
+ 
+   static index_type first (index_type i, index_type) { return i; }
+   static index_type second(index_type, index_type j) { return j; }
+ };
+ 
+ 
+ 
+ template <>
+ struct subview<tuple<2, 1, 0> >
+ {
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template subvector<1, 2>::impl_type
+   vector(Tensor<T, BlockT> view, index_type i, index_type j)
+   {
+     return view(whole_domain, j, i);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template subvector<1, 2>::impl_type
+   vector(const_Tensor<T, BlockT> view, index_type i, index_type j)
+   {
+     return view(whole_domain, j, i);
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template submatrix<2, 1>::impl_type
+   matrix(Tensor<T, BlockT> view, index_type i)
+   {
+     assert(0);
+     // return view(whole_domain, whole_domain, i).transpose();
+   }
+ 
+   template <typename T,
+ 	    typename BlockT>
+   static
+   typename const_Tensor<T, BlockT>::template submatrix<2, 1>::impl_type
+   matrix(const_Tensor<T, BlockT> view, index_type i)
+   {
+     assert(0);
+     // return view(whole_domain, whole_domain, i).transpose();
+   }
+   
+   static index_type first (index_type, index_type j) { return j; }
+   static index_type second(index_type i, index_type) { return i; }
+ };
+ 
+ 
+ 
+ template <dimension_type Dim,
+ 	  typename       Order,
+ 	  typename       InView,
+ 	  typename       OutView,
+ 	  typename       FuncT>
+ struct Foreach_vector;
+ 
+ 
+ 
+ template <typename Order,
+ 	  typename InView,
+ 	  typename OutView,
+ 	  typename FuncT>
+ struct Foreach_vector<3, Order, InView, OutView, FuncT>
+ {
+   static void exec(
+     InView  in,
+     OutView out,
+     FuncT&  fcn)
+   {
+     typedef typename OutView::block_type::map_type map_t;
+ 
+     static dimension_type const Dim0 = Order::impl_dim0;
+     static dimension_type const Dim1 = Order::impl_dim1;
+     static dimension_type const Dim2 = Order::impl_dim2;
+ 
+     map_t const& map = out.block().map();
+     Domain<3>    dom = impl::my_global_dom(out);
+ 
+     if (map.num_subblocks(Dim2) != 1)
+     {
+       VSIP_IMPL_THROW(impl::unimplemented(
+         "foreach_vector requires the dimension being processed to be undistributed"));
+     }
+ 
+     if (Is_par_same_map<map_t, typename InView::block_type>
+ 	::value(map, in.block()))
+     {
+       typename InView::local_type  l_in  = get_local_view(in);
+       typename OutView::local_type l_out = get_local_view(out);
+ 
+       for (index_type i=0; i<l_out.size(Dim0); ++i)
+ 	for (index_type j=0; j<l_out.size(Dim1); ++j)
+ 	{
+ 	  index_type global_i = dom[Dim0].impl_nth(i);
+ 	  index_type global_j = dom[Dim1].impl_nth(j);
+ 	  
+ 	  fcn(subview<Order>::vector(l_in, i, j),
+ 	      subview<Order>::vector(l_out, i, j),
+ 	      subview<Order>::first(global_i, global_j),
+ 	      subview<Order>::second(global_i, global_j));
+ 	}
+     }
+     else
+     {
+       typedef typename InView::value_type             value_type;
+       typedef typename Block_layout<typename InView::block_type>::order_type
+ 	                                              order_type;
+       typedef Dense<3, value_type, order_type, map_t> block_type;
+ 
+       Tensor<value_type, block_type> in_copy(in.size(0),in.size(1),in.size(2),
+ 					     map);
+ 
+       // Rearrange data.
+       in_copy = in;
+ 
+       // Force view to be const.
+       const_Tensor<value_type, block_type> in_const = in_copy;
+ 
+       typename InView::local_type  l_in  = get_local_view(in_const);
+       typename OutView::local_type l_out = get_local_view(out);
+ 
+       for (index_type i=0; i<l_out.size(Dim0); ++i)
+ 	for (index_type j=0; j<l_out.size(Dim1); ++j)
+ 	{
+ 	  index_type global_i = dom[Dim0].impl_nth(i);
+ 	  index_type global_j = dom[Dim1].impl_nth(j);
+ 	  
+ 	  fcn(subview<Order>::vector(l_in, i, j),
+ 	      subview<Order>::vector(l_out, i, j),
+ 	      subview<Order>::first(global_i, global_j),
+ 	      subview<Order>::second(global_i, global_j));
+ 	}
+     }
+   }
+ };
+ 
+ template <dimension_type Dim>
+ struct Foreach_order;
+ 
+ template <> struct Foreach_order<0> { typedef tuple<1, 2, 0> type; };
+ template <> struct Foreach_order<1> { typedef tuple<0, 2, 1> type; };
+ template <> struct Foreach_order<2> { typedef tuple<0, 1, 2> type; };
+ 
+ } // namespace vsip::impl
+ 
+ template <dimension_type                      Dim,
+ 	  template <typename, typename> class View1,
+ 	  template <typename, typename> class View2,
+ 	  typename                            T1,
+ 	  typename                            T2,
+ 	  typename                            Block1,
+ 	  typename                            Block2,
+ 	  typename                            FuncT>
+ void
+ foreach_vector(
+   View1<T1, Block1> in,
+   View2<T2, Block2> out,
+   FuncT&            fcn)
+ {
+   dimension_type const dim = View1<T1, Block1>::dim;
+ 
+   impl::Foreach_vector<dim, typename impl::Foreach_order<Dim>::type,
+     View1<T1, Block1>,
+     View2<T2, Block2>,
+     FuncT>::exec(in, out, fcn);
+ }
+ 
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_PAR_FOREACH_HPP
Index: src/vsip/impl/signal-conv.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv.hpp,v
retrieving revision 1.9
diff -c -p -r1.9 signal-conv.hpp
*** src/vsip/impl/signal-conv.hpp	19 Sep 2005 03:39:54 -0000	1.9
--- src/vsip/impl/signal-conv.hpp	23 Sep 2005 19:57:51 -0000
*************** public:
*** 147,152 ****
--- 147,156 ----
      {
        return timer_.count();
      }
+     else if (!strcmp(what, "time"))
+     {
+       return timer_.total();
+     }
      else
        return base_type::impl_performance(what);
    }
Index: src/vsip/impl/signal-fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-fft.hpp,v
retrieving revision 1.25
diff -c -p -r1.25 signal-fft.hpp
*** src/vsip/impl/signal-fft.hpp	21 Sep 2005 06:45:07 -0000	1.25
--- src/vsip/impl/signal-fft.hpp	23 Sep 2005 19:57:51 -0000
*************** public:
*** 489,494 ****
--- 489,498 ----
        if (sizeof(inT) != sizeof(outT)) ops /= 2.f;
        return (this->timer_.count() * ops) / (1e6 * this->timer_.total());
      }
+     else if (!strcmp(what, "time"))
+     {
+       return this->timer_.total();
+     }
      return 0.f;
    }
  
Index: src/vsip/impl/solver-covsol.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-covsol.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 solver-covsol.hpp
*** src/vsip/impl/solver-covsol.hpp	7 Sep 2005 15:06:36 -0000	1.1
--- src/vsip/impl/solver-covsol.hpp	23 Sep 2005 19:57:51 -0000
*************** covsol(
*** 43,48 ****
--- 43,49 ----
    Matrix<T, Block0>       a,
    const_Matrix<T, Block1> b,
    Matrix<T, Block2>       x)
+ VSIP_THROW((std::bad_alloc, computation_error))
  {
    length_type m = a.size(0);
    length_type n = a.size(1);
*************** covsol(
*** 60,74 ****
      
    qrd<T, by_reference> qr(m, n, qrd_saveq);
      
!   qr.decompose(a);
      
    Matrix<T> b_1(n, p);
      
    // 1: solve R' b_1 = b
!   qr.template rsol<tr>(b, T(1), b_1);
      
    // 2: solve R x = b_1 
!   qr.template rsol<mat_ntrans>(b_1, T(1), x);
      
    return x;
  }
--- 61,78 ----
      
    qrd<T, by_reference> qr(m, n, qrd_saveq);
      
!   if (!qr.decompose(a))
!     VSIP_IMPL_THROW(computation_error("covsol - qr.decompose failed"));
      
    Matrix<T> b_1(n, p);
      
    // 1: solve R' b_1 = b
!   if (!qr.template rsol<tr>(b, T(1), b_1))
!     VSIP_IMPL_THROW(computation_error("covsol - qr.rsol (1) failed"));
      
    // 2: solve R x = b_1 
!   if (!qr.template rsol<mat_ntrans>(b_1, T(1), x))
!     VSIP_IMPL_THROW(computation_error("covsol - qr.rsol (2) failed"));
      
    return x;
  }
Index: src/vsip/impl/subblock.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/subblock.hpp,v
retrieving revision 1.32
diff -c -p -r1.32 subblock.hpp
*** src/vsip/impl/subblock.hpp	16 Sep 2005 22:03:20 -0000	1.32
--- src/vsip/impl/subblock.hpp	23 Sep 2005 19:57:51 -0000
*************** Subset_block<typename Distributed_local_
*** 1264,1271 ****
  get_local_block(
    Subset_block<Block> const& block)
  {
!   typedef Subset_block<typename Distributed_local_block<Block>::type>
! 	local_block_type;
    dimension_type const dim = Subset_block<Block>::dim;
  
    subblock_type sb = block.map().lookup_index(block.map().impl_rank());
--- 1264,1272 ----
  get_local_block(
    Subset_block<Block> const& block)
  {
!   typedef typename Distributed_local_block<Block>::type local_subblock_type;
!   typedef Subset_block<local_subblock_type>             local_block_type;
! 
    dimension_type const dim = Subset_block<Block>::dim;
  
    subblock_type sb = block.map().lookup_index(block.map().impl_rank());
*************** get_local_block(
*** 1274,1280 ****
      impl_local_from_global_domain(sb,
  				  block.impl_domain());
  
!   return local_block_type(dom, get_local_block(block.impl_block()));
  }
  
  
--- 1275,1284 ----
      impl_local_from_global_domain(sb,
  				  block.impl_domain());
  
!   typename View_block_storage<local_subblock_type>::plain_type
!     sub_block = get_local_block(block.impl_block());
! 
!   return local_block_type(dom, sub_block);
  }
  
  
Index: tests/extdata-output.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/extdata-output.hpp,v
retrieving revision 1.5
diff -c -p -r1.5 extdata-output.hpp
*** tests/extdata-output.hpp	4 Aug 2005 11:53:03 -0000	1.5
--- tests/extdata-output.hpp	23 Sep 2005 19:57:51 -0000
***************
*** 9,18 ****
--- 9,28 ----
  #ifndef VSIP_TESTS_EXTDATA_OUTPUT_HPP
  #define VSIP_TESTS_EXTDATA_OUTPUT_HPP
  
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
  #include <string>
  #include <sstream>
  #include <complex>
  
+ 
+ 
+ /***********************************************************************
+   Defintions
+ ***********************************************************************/
+ 
  template <typename T>
  struct Type_name
  {
*************** TYPE_NAME(vsip::impl::Cmplx_split_fmt,  
*** 61,68 ****
  
  TYPE_NAME(vsip::row1_type,   "tuple<0, 1, 2>")
  
! // Blocks
!  template <typename Block, vsip::dimension_type D>
  struct Type_name<vsip::impl::Sliced_block<Block, D> >
  {
    static std::string name()
--- 71,101 ----
  
  TYPE_NAME(vsip::row1_type,   "tuple<0, 1, 2>")
  
! /***********************************************************************
!   Storage Type
! ***********************************************************************/
! 
! template <typename ComplexFmt,
! 	  typename T>
! struct Type_name<vsip::impl::Storage<ComplexFmt, T> >
! {
!   static std::string name()
!   {
!     std::ostringstream s;
!     s << "Storage<"
!       << Type_name<ComplexFmt>::name() << ", "
!       << Type_name<T>::name() << ">";
!     return s.str();
!   }
! };
! 
! 
! 
! /***********************************************************************
!   Blocks
! ***********************************************************************/
! 
! template <typename Block, vsip::dimension_type D>
  struct Type_name<vsip::impl::Sliced_block<Block, D> >
  {
    static std::string name()
*************** struct Type_name<vsip::impl::Sliced_bloc
*** 73,78 ****
--- 106,133 ----
    }
  };
  
+ template <typename                  Block,
+           template <typename> class Extractor>
+ struct Type_name<vsip::impl::Component_block<Block, Extractor> >
+ {
+   static std::string name()
+   {
+     std::ostringstream s;
+     s << "Component_block<"
+       << Type_name<Block>::name() << ", "
+       << Type_name<Extractor<typename Block::value_type> >::name() << ">";
+     return s.str();
+   }
+ };
+ 
+ template <typename Cplx>
+ struct Type_name<vsip::impl::Real_extractor<Cplx> >
+ { static std::string name() { return std::string("Real_extractor"); } };
+ 
+ template <typename Cplx>
+ struct Type_name<vsip::impl::Imag_extractor<Cplx> >
+ { static std::string name() { return std::string("Imag_extractor"); } };
+ 
  template <vsip::dimension_type Dim,
  	  typename    T,
  	  typename    Order,
*************** struct Type_name<vsip::Dense<Dim, T, Ord
*** 82,87 ****
--- 137,152 ----
    static std::string name() { return std::string("Dense<>"); }
  };
  
+ template <vsip::dimension_type Dim,
+ 	  typename             T,
+ 	  typename             LP,
+ 	  typename             Map>
+ struct Type_name<vsip::impl::Fast_block<Dim, T, LP, Map> >
+ {
+   static std::string name() { return std::string("Fast_block<>"); }
+ };
+ 
+ 
  TYPE_NAME(vsip::Block_dist,  "Block_dist")
  TYPE_NAME(vsip::Cyclic_dist, "Cyclic_dist")
  
