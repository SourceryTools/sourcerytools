Index: benchmarks/fastconv.cpp
===================================================================
RCS file: benchmarks/fastconv.cpp
diff -N benchmarks/fastconv.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/fastconv.cpp	5 Dec 2005 15:42:10 -0000
***************
*** 0 ****
--- 1,468 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    benchmarks/fastconv.cpp
+     @author  Jules Bergmann
+     @date    2005-10-28
+     @brief   VSIPL++ Library: Benchmark for Fast Convolution.
+ 
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <iostream>
+ 
+ #include <vsip/initfin.hpp>
+ #include <vsip/support.hpp>
+ #include <vsip/math.hpp>
+ #include <vsip/signal.hpp>
+ #include <vsip/impl/profile.hpp>
+ #include <vsip/impl/par-foreach.hpp>
+ 
+ #include "test.hpp"
+ #include "loop.hpp"
+ 
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   Common definitions
+ ***********************************************************************/
+ 
+ int
+ fft_ops(length_type len)
+ {
+   return int(5 * std::log(len) / std::log(2));
+ }
+ 
+ template <typename T,
+ 	  typename ImplTag>
+ struct t_fastconv_base;
+ 
+ struct Impl1op;
+ struct Impl1ip;
+ struct Impl1pip;
+ struct Impl2;
+ struct Impl2fv;
+ 
+ struct fastconv_ops
+ {
+   float ops(length_type npulse, length_type nrange) 
+   {
+     float fft_ops = 5 * nrange * std::log(nrange) / std::log(2);
+     float tot_ops = 2 * npulse * fft_ops + 6 * npulse * nrange;
+     return tot_ops;
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Impl1op: out-of-place, phased fast-convolution
+ ***********************************************************************/
+ 
+ template <typename T>
+ struct t_fastconv_base<T, Impl1op> : fastconv_ops
+ {
+   void fastconv(length_type npulse, length_type nrange,
+ 		length_type loop, float& time)
+   {
+     typedef Map<Block_dist, Whole_dist>      map_type;
+     typedef Dense<2, T, row2_type, map_type> block_type;
+     typedef Matrix<T, block_type>            view_type;
+ 
+     typedef Dense<1, T, row1_type, Global_map<1> > replica_block_type;
+     typedef Vector<T, replica_block_type>          replica_view_type;
+ 
+     processor_type np = num_processors();
+     map_type map = map_type(Block_dist(np), Whole_dist());
+ 
+     // Create the data cube.
+     view_type data(npulse, nrange, map);
+     view_type tmp(npulse, nrange, map);
+     
+     // Create the pulse replica
+     replica_view_type replica(nrange);
+ 
+     // int const no_times = 0; // FFTW_PATIENT
+     int const no_times = 15; // not > 12 = FFT_MEASURE
+     
+     typedef Fftm<T, T, row, fft_fwd, by_reference, no_times>
+ 	  	for_fftm_type;
+     typedef Fftm<T, T, row, fft_inv, by_reference, no_times>
+ 	  	inv_fftm_type;
+ 
+     // Create the FFT objects.
+     for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+     inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange*npulse));
+ 
+     // Initialize
+     data    = T();
+     replica = T();
+ 
+ 
+     // Before fast convolution, convert the replica into the
+     // frequency domain
+     // for_fft(replica);
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+     {
+       // Perform fast convolution:
+       for_fftm(data, tmp);
+       tmp = vmmul<0>(replica, tmp);
+       inv_fftm(tmp, data);
+     }
+     t1.stop();
+ 
+     // CHECK RESULT
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Impl1ip: in-place, phased fast-convolution
+ ***********************************************************************/
+ 
+ template <typename T>
+ struct t_fastconv_base<T, Impl1ip> : fastconv_ops
+ {
+   void fastconv(length_type npulse, length_type nrange,
+ 		length_type loop, float& time)
+   {
+     // Create the data cube.
+     Matrix<T> data(npulse, nrange);
+     
+     // Create the pulse replica
+     Vector<T> replica(nrange);
+ 
+     // int const no_times = 0; // FFTW_PATIENT
+     int const no_times = 15; // not > 12 = FFT_MEASURE
+     
+     typedef Fftm<T, T, row, fft_fwd, by_reference, no_times>
+ 	  	for_fftm_type;
+     typedef Fftm<T, T, row, fft_inv, by_reference, no_times>
+ 	  	inv_fftm_type;
+ 
+     // Create the FFT objects.
+     for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+     inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/(nrange*npulse));
+ 
+     // Initialize
+     data    = T();
+     replica = T();
+ 
+ 
+     // Before fast convolution, convert the replica into the
+     // frequency domain
+     // for_fft(replica);
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+     {
+       // Perform fast convolution:
+       for_fftm(data);
+       data = vmmul<0>(replica, data);
+       inv_fftm(data);
+     }
+     t1.stop();
+ 
+     // CHECK RESULT
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
+ template <typename T>
+ struct t_fastconv_base<T, Impl1pip> : fastconv_ops
+ {
+   void fastconv(length_type npulse, length_type nrange,
+ 		length_type loop, float& time)
+   {
+     // Create the data cube.
+     Matrix<T> data(npulse, nrange);
+     
+     // Create the pulse replica
+     Vector<T> tmp(nrange);
+     Vector<T> replica(nrange);
+ 
+     // int const no_times = 0; // FFTW_PATIENT
+     int const no_times = 15; // not > 12 = FFT_MEASURE
+     
+     typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times>
+ 	  	for_fft_type;
+     typedef Fft<const_Vector, T, T, fft_inv, by_reference, no_times>
+ 	  	inv_fft_type;
+ 
+     // Create the FFT objects.
+     for_fft_type for_fft(Domain<1>(nrange), 1.0);
+     inv_fft_type inv_fft(Domain<1>(nrange), 1.0/(nrange));
+ 
+     // Initialize
+     data    = T();
+     replica = T();
+ 
+ 
+     // Before fast convolution, convert the replica into the
+     // frequency domain
+     // for_fft(replica);
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+     {
+       // Perform fast convolution:
+       for (index_type p=0; p<npulse; ++p)
+ 	for_fft(data.row(p));
+       data = vmmul<0>(replica, data);
+       for (index_type p=0; p<npulse; ++p)
+ 	inv_fft(data.row(p));
+     }
+     t1.stop();
+ 
+     // CHECK RESULT
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Impl2: out-of-place (tmp), interleaved fast-convolution
+ ***********************************************************************/
+ 
+ template <typename T>
+ struct t_fastconv_base<T, Impl2> : fastconv_ops
+ {
+   void fastconv(length_type npulse, length_type nrange,
+ 		length_type loop, float& time)
+   {
+     // Create the data cube.
+     Matrix<T> data(npulse, nrange);
+     Vector<T> tmp(nrange);
+     
+     // Create the pulse replica
+     Vector<T> replica(nrange);
+ 
+     // int const no_times = 0; // FFTW_PATIENT
+     int const no_times = 15; // not > 12 = FFT_MEASURE
+     
+     typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times>
+ 	  	for_fft_type;
+     typedef Fft<const_Vector, T, T, fft_inv, by_reference, no_times>
+ 	  	inv_fft_type;
+ 
+     // Create the FFT objects.
+     for_fft_type for_fft(Domain<1>(nrange), 1.0);
+     inv_fft_type inv_fft(Domain<1>(nrange), 1.0/(nrange));
+ 
+     // Initialize
+     data    = T();
+     replica = T();
+ 
+ 
+     // Before fast convolution, convert the replica into the
+     // frequency domain
+     // for_fft(replica);
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+     {
+       // Perform fast convolution:
+       for (index_type p=0; p<npulse; ++p)
+       {
+ 	for_fft(data.row(p), tmp);
+ 	tmp *= replica;
+ 	inv_fft(tmp, data.row(p));
+       }
+     }
+     t1.stop();
+ 
+     // CHECK RESULT
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Impl2fv: foreach_vector, interleaved fast-convolution
+ ***********************************************************************/
+ 
+ template <typename T>
+ class Fast_convolution
+ {
+   // static int const no_times = 0; // FFTW_PATIENT
+   static int const no_times = 15; // not > 12 = FFT_MEASURE
+ 
+   typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times>
+ 		for_fft_type;
+   typedef Fft<const_Vector, T, T, fft_inv, by_reference, no_times>
+ 		inv_fft_type;
+ 
+ public:
+   template <typename Block>
+   Fast_convolution(
+     Vector<T, Block> replica)
+     : replica_(replica.size()),
+       tmp_    (replica.size()),
+       for_fft_(Domain<1>(replica.size()), 1.0),
+       inv_fft_(Domain<1>(replica.size()), 1.0/replica.size())
+   {
+     replica_ = replica;
+   }
+ 
+   template <typename       Block1,
+ 	    typename       Block2,
+ 	    dimension_type Dim>
+   void operator()(
+     Vector<T, Block1> in,
+     Vector<T, Block2> out,
+     Index<Dim>        /*idx*/)
+   {
+     for_fft_(in, tmp_);
+     tmp_ *= replica_;
+     inv_fft_(tmp_, out);
+   }
+ 
+   // Member data.
+ private:
+   Vector<T>    replica_;
+   Vector<T>    tmp_;
+   for_fft_type for_fft_;
+   inv_fft_type inv_fft_;
+ };
+ 
+ 
+ 
+ template <typename T>
+ struct t_fastconv_base<T, Impl2fv> : fastconv_ops
+ {
+   void fastconv(length_type npulse, length_type nrange,
+ 		length_type loop, float& time)
+   {
+     // Create the data cube.
+     Matrix<T> data(npulse, nrange);
+     
+     // Create the pulse replica
+     Vector<T> replica(nrange);
+ 
+     // Create the FFT objects.
+     Fast_convolution<T> fconv(replica);
+ 
+     // Initialize
+     data    = T();
+     replica = T();
+ 
+ 
+     // Before fast convolution, convert the replica into the
+     // frequency domain
+     // for_fft(replica);
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+     {
+       foreach_vector<tuple<0, 1> >(fconv, data);
+     }
+     t1.stop();
+ 
+     // CHECK RESULT
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   PF driver: (P)ulse (F)ixed
+ ***********************************************************************/
+ 
+ template <typename T, typename ImplTag>
+ struct t_fastconv_pf : public t_fastconv_base<T, ImplTag>
+ {
+   char* what() { return "t_fastconv_pf"; }
+   int ops_per_point(length_type size)
+     { return (int)(this->ops(npulse_, size) / size); }
+   int riob_per_point(length_type) { return -1*sizeof(T); }
+   int wiob_per_point(length_type) { return -1*sizeof(T); }
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+     this->fastconv(npulse_, size, loop, time);
+   }
+ 
+   t_fastconv_pf(length_type npulse) : npulse_(npulse) {}
+ 
+ // Member data
+   length_type npulse_;
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   RF driver: (R)ulse (F)ixed
+ ***********************************************************************/
+ 
+ template <typename T, typename ImplTag>
+ struct t_fastconv_rf : public t_fastconv_base<T, ImplTag>
+ {
+   char* what() { return "t_fastconv_rf"; }
+   int ops_per_point(length_type size)
+     { return (int)(this->ops(size, nrange_) / size); }
+   int riob_per_point(length_type) { return -1*sizeof(T); }
+   int wiob_per_point(length_type) { return -1*sizeof(T); }
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+     this->fastconv(size, nrange_, loop, time);
+   }
+ 
+   t_fastconv_rf(length_type nrange) : nrange_(nrange) {}
+ 
+ // Member data
+   length_type nrange_;
+ };
+ 
+ 
+ 
+ void
+ defaults(Loop1P& loop)
+ {
+   loop.cal_        = 4;
+   loop.start_      = 4;
+   loop.stop_       = 16;
+   loop.loop_start_ = 10;
+   loop.user_param_ = 64;
+ }
+ 
+ 
+ 
+ int
+ test(Loop1P& loop, int what)
+ {
+   length_type param1 = loop.user_param_;
+   switch (what)
+   {
+   case  1: loop(t_fastconv_pf<complex<float>, Impl1op>(param1)); break;
+   case  2: loop(t_fastconv_pf<complex<float>, Impl1ip>(param1)); break;
+   case  3: loop(t_fastconv_pf<complex<float>, Impl1pip>(param1)); break;
+   case  4: loop(t_fastconv_pf<complex<float>, Impl2>(param1)); break;
+   case  5: loop(t_fastconv_pf<complex<float>, Impl2fv>(param1)); break;
+   default: return 0;
+   }
+   return 1;
+ }
Index: benchmarks/loop.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/loop.hpp,v
retrieving revision 1.5
diff -c -p -r1.5 loop.hpp
*** benchmarks/loop.hpp	24 Oct 2005 13:25:30 -0000	1.5
--- benchmarks/loop.hpp	5 Dec 2005 15:42:10 -0000
***************
*** 18,23 ****
--- 18,26 ----
  #include <vector>
  
  #include <vsip/impl/profile.hpp>
+ #include <vsip/vector.hpp>
+ #include <vsip/map.hpp>
+ #include <vsip/impl/global_map.hpp>
  
  
  
*************** inline void
*** 116,129 ****
--- 119,147 ----
  Loop1P::operator()(
    Functor fcn)
  {
+   using vsip::Index;
+   using vsip::Vector;
+   using vsip::Dense;
+   using vsip::Map;
+   using vsip::Global_map;
+   using vsip::row1_type;
+ 
    size_t   loop, M;
    float    time;
    double   growth;
    unsigned const n_time = samples_;
    char     filename[256];
  
+   vsip::impl::Communicator comm  = vsip::impl::default_communicator();
+   vsip::processor_type     rank  = comm.rank();
+   vsip::processor_type     nproc = vsip::num_processors();
+ 
    std::vector<float> mtime(n_time);
  
+   Vector<float, Dense<1, float, row1_type, Map<> > >
+     dist_time(nproc, Map<>(nproc));
+   Vector<float, Dense<1, float, row1_type, Global_map<1> > > glob_time(nproc);
+ 
    loop = (1 << loop_start_);
    M    = (1 << cal_);
  
*************** Loop1P::operator()(
*** 142,158 ****
        break;
    }
  
!   printf("# what             : %s\n", fcn.what());
!   printf("# ops_per_point(1) : %d\n", (int)fcn.ops_per_point(1));
!   printf("# riob_per_point(1): %d\n", fcn.riob_per_point(1));
!   printf("# wiob_per_point(1): %d\n", fcn.wiob_per_point(1));
!   printf("# metric           : %s\n", metric_ == pts_per_sec ? "pts_per_sec" :
  	                              metric_ == ops_per_sec ? "ops_per_sec" :
  	                              metric_ == iob_per_sec ? "iob_per_sec" :
  	                                                       "*unknown*");
!   if (this->note_)
!     printf("# note: %s\n", this->note_);
!   printf("# start_loop       : %lu\n", (unsigned long) loop);
  
    if (this->do_prof_)
      vsip::impl::profile::prof->set_mode(vsip::impl::profile::pm_accum);
--- 160,180 ----
        break;
    }
  
!   if (rank == 0)
!   {
!     printf("# what             : %s\n", fcn.what());
!     printf("# nproc            : %d\n", nproc);
!     printf("# ops_per_point(1) : %d\n", (int)fcn.ops_per_point(1));
!     printf("# riob_per_point(1): %d\n", fcn.riob_per_point(1));
!     printf("# wiob_per_point(1): %d\n", fcn.wiob_per_point(1));
!     printf("# metric           : %s\n", metric_ == pts_per_sec ? "pts_per_sec" :
  	                              metric_ == ops_per_sec ? "ops_per_sec" :
  	                              metric_ == iob_per_sec ? "iob_per_sec" :
  	                                                       "*unknown*");
!     if (this->note_)
!       printf("# note: %s\n", this->note_);
!     printf("# start_loop       : %lu\n", (unsigned long) loop);
!   }
  
    if (this->do_prof_)
      vsip::impl::profile::prof->set_mode(vsip::impl::profile::pm_accum);
*************** Loop1P::operator()(
*** 163,169 ****
      M = (1 << i);
  
      for (unsigned i=0; i<n_time; ++i)
!       fcn(M, loop, mtime[i]);
  
      if (this->do_prof_)
      {
--- 185,202 ----
      M = (1 << i);
  
      for (unsigned i=0; i<n_time; ++i)
!     {
!       comm.barrier();
!       fcn(M, loop, time);
!       comm.barrier();
! 
!       dist_time.local().put(0, time);
!       glob_time = dist_time;
! 
!       Index<1> idx;
! 
!       mtime[i] = maxval(glob_time.local(), idx);
!     }
  
      if (this->do_prof_)
      {
*************** Loop1P::operator()(
*** 173,192 ****
  
      std::sort(mtime.begin(), mtime.end());
  
!     if (this->metric_ == all_per_sec)
!       printf("%7ld %f %f %f\n", (unsigned long) M,
! 	  this->metric(fcn, M, loop, mtime[(n_time-1)/2], pts_per_sec),
! 	  this->metric(fcn, M, loop, mtime[(n_time-1)/2], ops_per_sec),
! 	  this->metric(fcn, M, loop, mtime[(n_time-1)/2], iob_per_sec));
!     else if (n_time > 1)
!       // Note: max time is min op/s, and min time is max op/s
!       printf("%7lu %f %f %f\n", (unsigned long) M,
! 	  this->metric(fcn, M, loop, mtime[(n_time-1)/2], metric_),
! 	  this->metric(fcn, M, loop, mtime[n_time-1],     metric_),
! 	  this->metric(fcn, M, loop, mtime[0],            metric_));
!     else
!       printf("%7lu %f\n", (unsigned long) M,
!               this->metric(fcn, M, loop, mtime[0], metric_));
  
      time = mtime[(n_time-1)/2];
  
--- 206,229 ----
  
      std::sort(mtime.begin(), mtime.end());
  
! 
!     if (rank == 0)
!     {
!       if (this->metric_ == all_per_sec)
! 	printf("%7ld %f %f %f\n", (unsigned long) M,
! 	       this->metric(fcn, M, loop, mtime[(n_time-1)/2], pts_per_sec),
! 	       this->metric(fcn, M, loop, mtime[(n_time-1)/2], ops_per_sec),
! 	       this->metric(fcn, M, loop, mtime[(n_time-1)/2], iob_per_sec));
!       else if (n_time > 1)
! 	// Note: max time is min op/s, and min time is max op/s
! 	printf("%7lu %f %f %f\n", (unsigned long) M,
! 	       this->metric(fcn, M, loop, mtime[(n_time-1)/2], metric_),
! 	       this->metric(fcn, M, loop, mtime[n_time-1],     metric_),
! 	       this->metric(fcn, M, loop, mtime[0],            metric_));
!       else
! 	printf("%7lu %f\n", (unsigned long) M,
! 	       this->metric(fcn, M, loop, mtime[0], metric_));
!     }
  
      time = mtime[(n_time-1)/2];
  
Index: benchmarks/mcopy.cpp
===================================================================
RCS file: benchmarks/mcopy.cpp
diff -N benchmarks/mcopy.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/mcopy.cpp	5 Dec 2005 15:42:10 -0000
***************
*** 0 ****
--- 1,143 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    benchmarks/mcopy.cpp
+     @author  Jules Bergmann
+     @date    2005-10-14
+     @brief   VSIPL++ Library: Benchmark for matrix copy (including transpose).
+ 
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <iostream>
+ 
+ #include <vsip/initfin.hpp>
+ #include <vsip/support.hpp>
+ #include <vsip/math.hpp>
+ #include <vsip/impl/setup-assign.hpp>
+ #include <vsip/impl/par-chain-assign.hpp>
+ #include <vsip/map.hpp>
+ #include <vsip/impl/profile.hpp>
+ 
+ #include "test.hpp"
+ #include "loop.hpp"
+ #include "ops_info.hpp"
+ 
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   Matrix copy - normal assignment
+ ***********************************************************************/
+ 
+ template <typename T,
+ 	  typename SrcOrder,
+ 	  typename DstOrder,
+ 	  typename MapT>
+ struct t_mcopy
+ {
+   char* what() { return "t_mcopy"; }
+   int ops_per_point(length_type size)  { return size; }
+   int riob_per_point(length_type size) { return size*sizeof(T); }
+   int wiob_per_point(length_type size) { return size*sizeof(T); }
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+     length_type const M = size;
+     length_type const N = size;
+ 
+     typedef Dense<2, T, SrcOrder, MapT> src_block_t;
+     typedef Dense<2, T, DstOrder, MapT> dst_block_t;
+ 
+     Matrix<T, src_block_t>   A(M, N, T(), map_);
+     Matrix<T, dst_block_t>   Z(M, N,      map_);
+ 
+     for (index_type m=0; m<M; ++m)
+       for (index_type n=0; n<N; ++n)
+       {
+ 	A.put(m, n, T(m*N + n));
+       }
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       Z = A;
+     t1.stop();
+     
+     for (index_type m=0; m<M; ++m)
+       for (index_type n=0; n<N; ++n)
+       {
+ 	if (!equal(Z(m, n), T(m*N+n)))
+ 	{
+ 	  std::cout << "t_mcopy: ERROR" << std::endl;
+ 	  abort();
+ 	}
+       }
+     
+     time = t1.delta();
+   }
+ 
+   t_mcopy(MapT map) : map_(map) {}
+ 
+   // Member data.
+   MapT	map_;
+ };
+ 
+ 
+ 
+ template <typename T,
+ 	  typename SrcOrder,
+ 	  typename DstOrder>
+ struct t_mcopy_local : t_mcopy<T, SrcOrder, DstOrder, Local_map>
+ {
+   typedef t_mcopy<T, SrcOrder, DstOrder, Local_map> base_type;
+   t_mcopy_local()
+     : base_type(Local_map()) 
+   {}
+ };
+ 
+ template <typename T,
+ 	  typename SrcOrder,
+ 	  typename DstOrder>
+ struct t_mcopy_root : t_mcopy<T, SrcOrder, DstOrder, Map<> >
+ {
+   typedef t_mcopy<T, SrcOrder, DstOrder, Map<> > base_type;
+   t_mcopy_root()
+     : base_type(Map<>()) 
+   {}
+ };
+ 
+ 
+ 
+ void
+ defaults(Loop1P& loop)
+ {
+   loop.stop_ = 12;
+ }
+ 
+ 
+ 
+ int
+ test(Loop1P& loop, int what)
+ {
+   switch (what)
+   {
+   case  1: loop(t_mcopy_local<float, row2_type, row2_type>()); break;
+   case  2: loop(t_mcopy_local<float, row2_type, col2_type>()); break;
+   case  3: loop(t_mcopy_local<float, col2_type, row2_type>()); break;
+   case  4: loop(t_mcopy_local<float, col2_type, col2_type>()); break;
+ 
+   case  5: loop(t_mcopy_local<complex<float>, row2_type, row2_type>()); break;
+   case  6: loop(t_mcopy_local<complex<float>, row2_type, col2_type>()); break;
+   case  7: loop(t_mcopy_local<complex<float>, col2_type, row2_type>()); break;
+   case  8: loop(t_mcopy_local<complex<float>, col2_type, col2_type>()); break;
+ 
+   default:
+     return 0;
+   }
+   return 1;
+ }
Index: benchmarks/prod_var.cpp
===================================================================
RCS file: benchmarks/prod_var.cpp
diff -N benchmarks/prod_var.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/prod_var.cpp	5 Dec 2005 15:42:10 -0000
***************
*** 0 ****
--- 1,419 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    benchmarks/prod_var.cpp
+     @author  Jules Bergmann
+     @date    2005-11-07
+     @brief   VSIPL++ Library: Randy Judd's matrix-matric product variations.
+ 
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <iostream>
+ 
+ #include <vsip/initfin.hpp>
+ #include <vsip/support.hpp>
+ #include <vsip/math.hpp>
+ #include <vsip/signal.hpp>
+ 
+ #include <vsip/impl/profile.hpp>
+ 
+ #include "test.hpp"
+ #include "test-precision.hpp"
+ #include "ref_matvec.hpp"
+ #include "output.hpp"
+ 
+ #include "loop.hpp"
+ #include "ops_info.hpp"
+ 
+ #define VERBOSE 1
+ 
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   Matrix-matrix product variants
+ ***********************************************************************/
+ 
+ // Convenience type to disambiguate between prod() overloads.
+ template <int I> struct Int_type {};
+ 
+ 
+ 
+ // direct matrix product using VSIPL function
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ prod(
+   Int_type<0>,
+   Matrix<T, Block1> A,
+   Matrix<T, Block2> B,
+   Matrix<T, Block3> C)
+ {
+   C = prod(A,B);
+ }
+ 
+ // prod_2: Alg 1.1.8 Outer Product from G&VL
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ prod(
+   Int_type<1>,
+   Matrix<T, Block1> A,
+   Matrix<T, Block2> B,
+   Matrix<T, Block3> C)
+ {
+   index_type p = A.row(0).size();
+ 
+   C = outer<T>(1.0, A.col(0), B.row(0));
+   for(index_type k=1; k < p; k++)
+     C += outer<T>(1.0, A.col(k),B.row(k));
+ }
+  
+ // prod_3: Alg 1.1.7 Saxpy Version G&VL
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ prod(
+   Int_type<2>,
+   Matrix<T, Block1> A,
+   Matrix<T, Block2> B,
+   Matrix<T, Block3> C)
+ {
+   C = T();
+ 
+   index_type n = B.row(0).size();
+   index_type p = A.row(0).size();
+ 
+   for(index_type j=0; j < n; j++)
+     for(index_type k=0; k < p; k++)
+       C.col(j) = A.col(k) * B.get(k,j) + C.col(j);
+ }
+ 
+ // prod_3c
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ prod(
+   Int_type<3>,
+   Matrix<T, Block1> A,
+   Matrix<T, Block2> B,
+   Matrix<T, Block3> C)
+ {
+   C = T();
+ 
+   // index_type n = B.row(0).size();
+   // index_type p = A.row(0).size();
+   index_type const n = B.size(1);
+   index_type const p = A.size(1);
+   for(index_type j=0; j < n; j++)
+     for(index_type k=0; k < p; k++)
+       C.col(j) = A.col(k) * B.get(k,j) + C.col(j);
+ }
+ 
+ // prod_3sv: Alg 1.1.7 Saxpy Version G&VL using subview
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ prod(
+   Int_type<4>,
+   Matrix<T, Block1> A,
+   Matrix<T, Block2> B,
+   Matrix<T, Block3> C)
+ {
+   C = T();
+ 
+   index_type n = B.row(0).size();
+   index_type p = A.row(0).size();
+ 
+   for(index_type j=0; j < n; j++)
+   {
+     typename Matrix<T, Block3>::col_type c_col(C.col(j));
+     typename Matrix<T, Block2>::col_type b_col(B.col(j));
+     for(index_type k=0; k < p; k++)
+       c_col = A.col(k) * b_col.get(k) + c_col;
+   }
+ }
+ 
+ // prod_4: Alg 1.1.5 ijk variant G&VL
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ prod(
+   Int_type<5>,
+   Matrix<T, Block1> A,
+   Matrix<T, Block2> B,
+   Matrix<T, Block3> C)
+ {
+   C = T();
+ 
+   for(index_type i=0; i<A.size(0); i++)
+   {
+     for(index_type j=0; j<B.size(1); j++)
+     {
+       for(index_type k=0; k<A.size(1); k++)
+       {
+ 	C.put(i,j,A.get(i,k)*B.get(k,j) + C.get(i,j));
+       }
+     }
+   }
+ }
+ 
+ // prod_4t: Alg 1.1.5 ijk variant G&VL with tmp storage
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ prod(
+   Int_type<6>,
+   Matrix<T, Block1> A,
+   Matrix<T, Block2> B,
+   Matrix<T, Block3> C)
+ {
+   C = T();
+ 
+   for(index_type i = 0; i<A.size(0); i++){
+     for(index_type j=0; j<B.size(1); j++){
+       T tmp = T();
+       for(index_type k=0; k<A.size(1); k++){
+ 	tmp += A.get(i,k)*B.get(k,j);
+       }
+       C.put(i,j,tmp);
+     }
+   }
+ }
+  
+ // prod_4trc:
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ prod(
+   Int_type<7>,
+   Matrix<T, Block1> A,
+   Matrix<T, Block2> B,
+   Matrix<T, Block3> C)
+ {
+   C = T();
+ 
+   for(index_type i = 0; i<A.size(0); i++){
+     for(index_type j=0; j<B.size(1); j++){
+       T tmp=T();
+       for(index_type k=0; k<A.size(1); k++){
+ 	tmp += A.row(i).get(k)*B.col(j).get(k);
+       }
+       C.put(i,j,tmp);
+     }
+   }
+ }
+  
+ // prod_4tsv:
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ prod(
+   Int_type<8>,
+   Matrix<T, Block1> A,
+   Matrix<T, Block2> B,
+   Matrix<T, Block3> C)
+ {
+   C = T();
+ 
+   for(index_type i = 0; i<A.size(0); i++){
+     typename Matrix<T, Block1>::row_type a_row(A.row(i));
+ 
+     for(index_type j=0; j<B.size(1); j++){
+       typename Matrix<T, Block2>::col_type b_col(B.col(j));
+       T tmp=T();
+       for(index_type k=0; k<A.size(1); k++){
+ 	tmp += a_row.get(k)*b_col.get(k);
+       }
+       C.put(i,j,tmp);
+     }
+   }
+ }
+  
+ // prod_4dot:
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ prod(
+   Int_type<9>,
+   Matrix<T, Block1> A,
+   Matrix<T, Block2> B,
+   Matrix<T, Block3> C)
+ {
+   for(index_type i = 0; i<A.size(0); i++){
+     typename Matrix<T, Block1>::row_type a_row(A.row(i));
+     for(index_type j=0; j<B.size(1); j++){
+       C.put(i, j, dot(a_row, B.col(j)));
+     }
+   }
+ }
+ 
+ 
+ 
+ /***********************************************************************
+   Comparison routine and benchmark driver.
+ ***********************************************************************/
+ 
+ template <typename T0,
+ 	  typename T1,
+           typename T2,
+           typename Block0,
+           typename Block1,
+           typename Block2>
+ void
+ check_prod(
+   Matrix<T0, Block0> test,
+   Matrix<T1, Block1> chk,
+   Matrix<T2, Block2> gauge)
+ {
+   typedef typename Promotion<T0, T1>::type return_type;
+   typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
+ 
+   Index<2> idx;
+   scalar_type err = maxval(((mag(chk - test)
+ 			     / Precision_traits<scalar_type>::eps)
+ 			    / gauge),
+ 			   idx);
+ 
+ #if VERBOSE
+   if (err >= 10.0)
+   {
+     std::cout << "test  =\n" << test;
+     std::cout << "chk   =\n" << chk;
+     std::cout << "gauge =\n" << gauge;
+     std::cout << "err = " << err << std::endl;
+   }
+ #endif
+ 
+   assert(err < 10.0);
+ }
+ 
+ // Matrix-matrix product benchmark class.
+ 
+ template <int ImplI, typename T>
+ struct t_prod1
+ {
+   static length_type const Dec = 1;
+ 
+   char* what() { return "t_prod1"; }
+   float ops_per_point(length_type M)
+   {
+     length_type N = M;
+     length_type P = M;
+ 
+     float ops = /*M * */ P * N * (Ops_info<T>::mul + Ops_info<T>::add);
+ 
+     return ops;
+   }
+ 
+   int riob_per_point(length_type) { return 2*sizeof(T); }
+   int wiob_per_point(length_type) { return 0; }
+ 
+   void operator()(length_type M, length_type loop, float& time)
+   {
+     typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+ 
+     length_type N = M;
+     length_type P = M;
+ 
+     Matrix<T>   A (M, N, T(1));
+     Matrix<T>   B (N, P, T(1));
+     Matrix<T>   Z (M, P, T(1));
+     Matrix<T>   chk(M, P);
+     Matrix<scalar_type> gauge(M, P);
+ 
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       prod(Int_type<ImplI>(), A, B, Z);
+     t1.stop();
+ 
+     chk   = ref::prod(A, B);
+     gauge = ref::prod(mag(A), mag(B));
+ 
+     for (index_type i=0; i<gauge.size(0); ++i)
+       for (index_type j=0; j<gauge.size(1); ++j)
+ 	if (!(gauge(i, j) > scalar_type()))
+ 	  gauge(i, j) = scalar_type(1);
+ 
+     check_prod(Z, chk, gauge );
+     
+     time = t1.delta();
+   }
+ 
+   t_prod1() {}
+ };
+ 
+ 
+ 
+ void
+ defaults(Loop1P& loop)
+ {
+   loop.loop_start_ = 5000;
+   loop.start_ = 4;
+   loop.stop_  = 8;
+ }
+ 
+ 
+ template <> float  Precision_traits<float>::eps = 0.0;
+ template <> double Precision_traits<double>::eps = 0.0;
+ 
+ int
+ test(Loop1P& loop, int what)
+ {
+   Precision_traits<float>::compute_eps();
+   Precision_traits<double>::compute_eps();
+ 
+   switch (what)
+   {
+   case  0: loop(t_prod1<0, float>()); break;
+   case  1: loop(t_prod1<1, float>()); break;
+   case  2: loop(t_prod1<2, float>()); break;
+   case  3: loop(t_prod1<3, float>()); break;
+   case  4: loop(t_prod1<4, float>()); break;
+   case  5: loop(t_prod1<5, float>()); break;
+   case  6: loop(t_prod1<6, float>()); break;
+   case  7: loop(t_prod1<7, float>()); break;
+   case  8: loop(t_prod1<8, float>()); break;
+   case  9: loop(t_prod1<9, float>()); break;
+ 
+   case  10: loop(t_prod1<0, complex<float> >()); break;
+   case  11: loop(t_prod1<1, complex<float> >()); break;
+   case  12: loop(t_prod1<2, complex<float> >()); break;
+   case  13: loop(t_prod1<3, complex<float> >()); break;
+   case  14: loop(t_prod1<4, complex<float> >()); break;
+   case  15: loop(t_prod1<5, complex<float> >()); break;
+   case  16: loop(t_prod1<6, complex<float> >()); break;
+   case  17: loop(t_prod1<7, complex<float> >()); break;
+   case  18: loop(t_prod1<8, complex<float> >()); break;
+   case  19: loop(t_prod1<9, complex<float> >()); break;
+ 
+   default: return 0;
+   }
+   return 1;
+ }
Index: src/vsip/dense.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/dense.hpp,v
retrieving revision 1.29
diff -c -p -r1.29 dense.hpp
*** src/vsip/dense.hpp	27 Sep 2005 22:44:40 -0000	1.29
--- src/vsip/dense.hpp	5 Dec 2005 15:42:10 -0000
*************** template <dimension_type Dim,
*** 1055,1061 ****
  void
  assert_local(
    Dense<Dim, T, OrderT, Local_map> const& block,
!   subblock_type                                  sb)
  {
    assert(sb == 0);
  }
--- 1055,1061 ----
  void
  assert_local(
    Dense<Dim, T, OrderT, Local_map> const& block,
!   index_type                              sb)
  {
    assert(sb == 0);
  }
*************** template <dimension_type Dim,
*** 1071,1077 ****
  void
  assert_local(
    Dense<Dim, T, OrderT, MapT> const& block,
!   subblock_type                      sb)
  {
    block.assert_local(sb);
  }
--- 1071,1077 ----
  void
  assert_local(
    Dense<Dim, T, OrderT, MapT> const& block,
!   index_type                         sb)
  {
    block.assert_local(sb);
  }
Index: src/vsip/map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/map.hpp,v
retrieving revision 1.19
diff -c -p -r1.19 map.hpp
*** src/vsip/map.hpp	14 Nov 2005 22:42:21 -0000	1.19
--- src/vsip/map.hpp	5 Dec 2005 15:42:10 -0000
***************
*** 26,31 ****
--- 26,33 ----
  #include <vsip/impl/domain-utils.hpp>
  #include <vsip/impl/block-traits.hpp>
  
+ #include <vsip/impl/global_map.hpp>
+ 
  
  
  
*************** class Map
*** 106,115 ****
  {
    // Compile-time typedefs.
  public:
-   typedef impl::Value_iterator<subblock_type,  unsigned> subblock_iterator;
    typedef impl::Value_iterator<processor_type, unsigned> processor_iterator;
-   typedef std::vector<processor_type> pvec_type;
  
    static bool const impl_local_only  = false;
    static bool const impl_global_only = true;
  
--- 108,116 ----
  {
    // Compile-time typedefs.
  public:
    typedef impl::Value_iterator<processor_type, unsigned> processor_iterator;
  
+   typedef std::vector<processor_type> impl_pvec_type;
    static bool const impl_local_only  = false;
    static bool const impl_global_only = true;
  
*************** public:
*** 118,125 ****
    Map(Dist0 const& = Dist0(), Dist1 const& = Dist1(), Dist2 const& = Dist2())
      VSIP_NOTHROW;
  
!   Map(Vector<processor_type>&,
!       Dist0 const& = Dist0(), Dist1 const& = Dist1(), Dist2 const& = Dist2())
      VSIP_NOTHROW;
  
    Map(Map const&) VSIP_NOTHROW;
--- 119,129 ----
    Map(Dist0 const& = Dist0(), Dist1 const& = Dist1(), Dist2 const& = Dist2())
      VSIP_NOTHROW;
  
!   template <typename BlockT>
!   Map(const_Vector<processor_type, BlockT>,
!       Dist0 const& = Dist0(),
!       Dist1 const& = Dist1(),
!       Dist2 const& = Dist2())
      VSIP_NOTHROW;
  
    Map(Map const&) VSIP_NOTHROW;
*************** public:
*** 136,173 ****
    length_type       num_subblocks    (dimension_type d) const VSIP_NOTHROW;
    length_type       cyclic_contiguity(dimension_type d) const VSIP_NOTHROW;
  
!   length_type num_subblocks() const VSIP_NOTHROW { return num_subblocks_; }
  
!   subblock_type impl_subblock(processor_type pr) const VSIP_NOTHROW;
!   subblock_type impl_subblock() const VSIP_NOTHROW;
  
-   subblock_iterator subblocks_begin(processor_type pr) const VSIP_NOTHROW;
-   subblock_iterator subblocks_end  (processor_type pr) const VSIP_NOTHROW;
-   processor_iterator processor_begin(subblock_type sb) const VSIP_NOTHROW;
-   processor_iterator processor_end  (subblock_type sb) const VSIP_NOTHROW;
  
    // Applied map functions.
!   length_type num_patches     (subblock_type sb) const VSIP_NOTHROW;
  
    template <dimension_type Dim>
    void apply(Domain<Dim> const& dom) VSIP_NOTHROW;
  
    template <dimension_type Dim>
!   Domain<Dim> get_subblock_dom(subblock_type sb) const VSIP_NOTHROW;
  
    template <dimension_type Dim>
!   Domain<Dim> get_global_dom(subblock_type sb, index_type patch)
      const VSIP_NOTHROW;
  
    template <dimension_type Dim>
!   Domain<Dim> get_local_dom (subblock_type sb, index_type patch)
      const VSIP_NOTHROW;
  
    template <dimension_type Dim>
!   Domain<Dim> applied_dom () const VSIP_NOTHROW;
  
!   // Extensions.
!   pvec_type          impl_pvec() const { return pvec_; }
    impl::Communicator impl_comm() const { return comm_; }
    processor_type     impl_rank() const { return comm_.rank(); }
    length_type        impl_size() const { return comm_.size(); }
--- 140,179 ----
    length_type       num_subblocks    (dimension_type d) const VSIP_NOTHROW;
    length_type       cyclic_contiguity(dimension_type d) const VSIP_NOTHROW;
  
!   length_type num_subblocks()  const VSIP_NOTHROW { return num_subblocks_; }
!   length_type num_processors() const VSIP_NOTHROW { return num_procs_; }
! 
!   index_type subblock(processor_type pr) const VSIP_NOTHROW;
!   index_type subblock() const VSIP_NOTHROW;
! 
!   processor_iterator processor_begin(index_type sb) const VSIP_NOTHROW;
!   processor_iterator processor_end  (index_type sb) const VSIP_NOTHROW;
  
!   const_Vector<processor_type> processor_set() const;
  
  
    // Applied map functions.
!   length_type num_patches     (index_type sb) const VSIP_NOTHROW;
  
    template <dimension_type Dim>
    void apply(Domain<Dim> const& dom) VSIP_NOTHROW;
  
    template <dimension_type Dim>
!   Domain<Dim> subblock_domain(index_type sb) const VSIP_NOTHROW;
  
    template <dimension_type Dim>
!   Domain<Dim> global_domain(index_type sb, index_type patch)
      const VSIP_NOTHROW;
  
    template <dimension_type Dim>
!   Domain<Dim> local_domain (index_type sb, index_type patch)
      const VSIP_NOTHROW;
  
    template <dimension_type Dim>
!   Domain<Dim> applied_domain () const VSIP_NOTHROW;
  
!   // Implementation functions.
!   impl_pvec_type     impl_pvec() const { return pvec_; }
    impl::Communicator impl_comm() const { return comm_; }
    processor_type     impl_rank() const { return comm_.rank(); }
    length_type        impl_size() const { return comm_.size(); }
*************** public:
*** 180,203 ****
  
    // Private implementation functions.
  private:
!   length_type impl_subblock_patches(dimension_type d, subblock_type sb)
      const VSIP_NOTHROW;
!   length_type impl_subblock_size(dimension_type d, subblock_type sb)
      const VSIP_NOTHROW;
!   Domain<1> impl_patch_global_dom(dimension_type d, subblock_type sb,
  				  index_type p)
      const VSIP_NOTHROW;
!   Domain<1> impl_patch_local_dom(dimension_type d, subblock_type sb,
  				 index_type p)
      const VSIP_NOTHROW;
  public:
!   subblock_type impl_subblock_from_index(dimension_type d, index_type idx)
      const VSIP_NOTHROW;
    index_type impl_local_from_global_index(dimension_type d, index_type idx)
      const VSIP_NOTHROW;
  
    template <dimension_type Dim>
!   Domain<Dim> impl_local_from_global_domain(subblock_type sb,
  					    Domain<Dim> const& dom)
      const VSIP_NOTHROW;
  
--- 186,213 ----
  
    // Private implementation functions.
  private:
!   length_type impl_subblock_patches(dimension_type d, index_type sb)
      const VSIP_NOTHROW;
!   length_type impl_subblock_size(dimension_type d, index_type sb)
      const VSIP_NOTHROW;
!   Domain<1> impl_patch_global_dom(dimension_type d, index_type sb,
  				  index_type p)
      const VSIP_NOTHROW;
!   Domain<1> impl_patch_local_dom(dimension_type d, index_type sb,
  				 index_type p)
      const VSIP_NOTHROW;
  public:
!   index_type impl_subblock_from_index(dimension_type d, index_type idx)
      const VSIP_NOTHROW;
    index_type impl_local_from_global_index(dimension_type d, index_type idx)
      const VSIP_NOTHROW;
  
+   index_type global_from_local_index(dimension_type d, index_type sb,
+ 				     index_type idx)
+     const VSIP_NOTHROW;
+ 
    template <dimension_type Dim>
!   Domain<Dim> impl_local_from_global_domain(index_type sb,
  					    Domain<Dim> const& dom)
      const VSIP_NOTHROW;
  
*************** private:
*** 222,228 ****
    Dist2              dist2_;
  
    impl::Communicator comm_;
!   pvec_type          pvec_;		  // Grid function.
  
    length_type	     num_subblocks_;	  // Total number of subblocks.
    length_type	     num_procs_;	  // Total number of processors.
--- 232,238 ----
    Dist2              dist2_;
  
    impl::Communicator comm_;
!   impl_pvec_type     pvec_;		  // Grid function.
  
    length_type	     num_subblocks_;	  // Total number of subblocks.
    length_type	     num_procs_;	  // Total number of processors.
*************** VSIP_NOTHROW
*** 271,285 ****
  
  
  
! template <typename       Dist0,
! 	  typename       Dist1,
! 	  typename       Dist2>
  inline
  Map<Dist0, Dist1, Dist2>::Map(
!   Vector<processor_type>& pvec,
!   Dist0 const&            dist0,
!   Dist1 const&            dist1,
!   Dist2 const&            dist2)
  VSIP_NOTHROW
  : dist0_ (dist0),
    dist1_ (dist1),
--- 281,296 ----
  
  
  
! template <typename Dist0,
! 	  typename Dist1,
! 	  typename Dist2>
! template <typename BlockT>
  inline
  Map<Dist0, Dist1, Dist2>::Map(
!   const_Vector<processor_type, BlockT> pvec,
!   Dist0 const&                         dist0,
!   Dist1 const&                         dist1,
!   Dist2 const&                         dist2)
  VSIP_NOTHROW
  : dist0_ (dist0),
    dist1_ (dist1),
*************** template <typename       Dist0,
*** 442,448 ****
  inline length_type
  Map<Dist0, Dist1, Dist2>::impl_subblock_patches(
    dimension_type d,
!   subblock_type  sb
    )
    const VSIP_NOTHROW
  {
--- 453,459 ----
  inline length_type
  Map<Dist0, Dist1, Dist2>::impl_subblock_patches(
    dimension_type d,
!   index_type  sb
    )
    const VSIP_NOTHROW
  {
*************** template <typename       Dist0,
*** 467,473 ****
  inline length_type
  Map<Dist0, Dist1, Dist2>::impl_subblock_size(
    dimension_type d,
!   subblock_type  sb
    )
    const VSIP_NOTHROW
  {
--- 478,484 ----
  inline length_type
  Map<Dist0, Dist1, Dist2>::impl_subblock_size(
    dimension_type d,
!   index_type  sb
    )
    const VSIP_NOTHROW
  {
*************** template <typename       Dist0,
*** 492,498 ****
  inline Domain<1>
  Map<Dist0, Dist1, Dist2>::impl_patch_global_dom(
    dimension_type d,
!   subblock_type  sb,
    index_type     p
    )
    const VSIP_NOTHROW
--- 503,509 ----
  inline Domain<1>
  Map<Dist0, Dist1, Dist2>::impl_patch_global_dom(
    dimension_type d,
!   index_type  sb,
    index_type     p
    )
    const VSIP_NOTHROW
*************** template <typename       Dist0,
*** 518,524 ****
  inline Domain<1>
  Map<Dist0, Dist1, Dist2>::impl_patch_local_dom(
    dimension_type d,
!   subblock_type  sb,
    index_type     p
    )
    const VSIP_NOTHROW
--- 529,535 ----
  inline Domain<1>
  Map<Dist0, Dist1, Dist2>::impl_patch_local_dom(
    dimension_type d,
!   index_type     sb,
    index_type     p
    )
    const VSIP_NOTHROW
*************** Map<Dist0, Dist1, Dist2>::impl_patch_loc
*** 541,547 ****
  template <typename       Dist0,
  	  typename       Dist1,
  	  typename       Dist2>
! inline subblock_type
  Map<Dist0, Dist1, Dist2>::impl_subblock_from_index(
    dimension_type d,
    index_type     idx
--- 552,558 ----
  template <typename       Dist0,
  	  typename       Dist1,
  	  typename       Dist2>
! inline index_type
  Map<Dist0, Dist1, Dist2>::impl_subblock_from_index(
    dimension_type d,
    index_type     idx
*************** Map<Dist0, Dist1, Dist2>::impl_local_fro
*** 586,598 ****
  
  
  
  template <typename       Dist0,
  	  typename       Dist1,
  	  typename       Dist2>
  template <dimension_type Dim>
  inline Domain<Dim>
  Map<Dist0, Dist1, Dist2>::impl_local_from_global_domain(
!   subblock_type      sb,
    Domain<Dim> const& g_dom
    )
    const VSIP_NOTHROW
--- 597,646 ----
  
  
  
+ /// Determine global index from local index for a single dimension
+ 
+ /// Requires:
+ ///   D to be a dimension for map.
+ ///   SB to be a valid subblock for map.
+ ///   IDX to be an local index within subblock SB.
+ /// Returns:
+ ///   global index corresponding to local index IDX.
+ 
+ template <typename       Dist0,
+ 	  typename       Dist1,
+ 	  typename       Dist2>
+ inline index_type
+ Map<Dist0, Dist1, Dist2>::global_from_local_index(
+   dimension_type d,
+   index_type     sb,
+   index_type     idx
+   )
+   const VSIP_NOTHROW
+ {
+   assert(d < VSIP_MAX_DIMENSION);
+   assert(dim_ != 0 && d < dim_);
+ 
+   index_type dim_sb[VSIP_MAX_DIMENSION];
+   impl::split_tuple(sb, dim_, subblocks_, dim_sb);
+ 
+   switch (d)
+   {
+   case 0: return dist0_.impl_global_from_local_index(dom_[0], dim_sb[0], idx);
+   case 1: return dist1_.impl_global_from_local_index(dom_[1], dim_sb[1], idx);
+   case 2: return dist2_.impl_global_from_local_index(dom_[2], dim_sb[2], idx);
+   default: assert(false);
+   }
+ }
+ 
+ 
+ 
  template <typename       Dist0,
  	  typename       Dist1,
  	  typename       Dist2>
  template <dimension_type Dim>
  inline Domain<Dim>
  Map<Dist0, Dist1, Dist2>::impl_local_from_global_domain(
!   index_type         sb,
    Domain<Dim> const& g_dom
    )
    const VSIP_NOTHROW
*************** template <typename       Dist0,
*** 666,673 ****
  	  typename       Dist1,
  	  typename       Dist2>
  inline
! subblock_type
! Map<Dist0, Dist1, Dist2>::impl_subblock(processor_type pr)
    const VSIP_NOTHROW
  {
    index_type pi = lookup_index(pr);
--- 714,721 ----
  	  typename       Dist1,
  	  typename       Dist2>
  inline
! index_type
! Map<Dist0, Dist1, Dist2>::subblock(processor_type pr)
    const VSIP_NOTHROW
  {
    index_type pi = lookup_index(pr);
*************** template <typename       Dist0,
*** 689,696 ****
  	  typename       Dist1,
  	  typename       Dist2>
  inline
! subblock_type
! Map<Dist0, Dist1, Dist2>::impl_subblock()
    const VSIP_NOTHROW
  {
    processor_type pr = impl_rank();
--- 737,744 ----
  	  typename       Dist1,
  	  typename       Dist2>
  inline
! index_type
! Map<Dist0, Dist1, Dist2>::subblock()
    const VSIP_NOTHROW
  {
    processor_type pr = impl_rank();
*************** Map<Dist0, Dist1, Dist2>::impl_subblock(
*** 704,769 ****
  
  
  
- /// Beginning of range for subblocks held by processor.
- 
- /// Requires:
- ///   PR is a processor in the map's processor set.
- /// Returns:
- ///   An iterator pointing to processor PR's first subblock.
- 
- template <typename       Dist0,
- 	  typename       Dist1,
- 	  typename       Dist2>
- inline
- typename Map<Dist0, Dist1, Dist2>::subblock_iterator
- Map<Dist0, Dist1, Dist2>::subblocks_begin(processor_type pr)
-   const VSIP_NOTHROW
- {
-   index_type pi = lookup_index(pr);
- 
-   if (pi != no_processor && pi < num_subblocks_)
-     return subblock_iterator(pi, num_procs_);
-   else
-     return subblock_iterator(0, 1);
- }
- 
- 
- 
- /// End of range for subblocks held by processor.
- 
- /// Requires:
- ///   PR is a processor in the map's processor set.
- /// Returns:
- ///   An iterator pointing to one past processor PR's last subblock.
- 
- template <typename       Dist0,
- 	  typename       Dist1,
- 	  typename       Dist2>
- inline
- typename Map<Dist0, Dist1, Dist2>::subblock_iterator
- Map<Dist0, Dist1, Dist2>::subblocks_end(processor_type pr)
-   const VSIP_NOTHROW
- {
-   index_type pi = lookup_index(pr);
- 
-   // The number of subblocks given to a single processor is:
-   //    (total number of subblocks) / (number of processors)
-   // If this number doesn't divide evenly, then the first N
-   // processors get an extra subblock, where N is the number
-   // of extra processors above an even multiple, or 
-   //    (total number of subblocks) % (number of processors).
-   index_type num_subblocks_pi =
-     (num_subblocks_ / num_procs_) +
-     (pi < num_subblocks_ % num_procs_ ? 1 : 0);
- 
-   if (pi != no_processor && pi < num_subblocks_)
-     return subblock_iterator(pi + num_subblocks_pi * num_procs_, num_procs_);
-   else
-     return subblock_iterator(0, 1);
- }
- 
- 
- 
  /// Beginning of range for processors holding a subblock.
  
  /// Requires:
--- 752,757 ----
*************** template <typename       Dist0,
*** 781,787 ****
  	  typename       Dist2>
  inline
  typename Map<Dist0, Dist1, Dist2>::processor_iterator
! Map<Dist0, Dist1, Dist2>::processor_begin(subblock_type sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
--- 769,775 ----
  	  typename       Dist2>
  inline
  typename Map<Dist0, Dist1, Dist2>::processor_iterator
! Map<Dist0, Dist1, Dist2>::processor_begin(index_type sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
*************** template <typename       Dist0,
*** 808,814 ****
  	  typename       Dist2>
  inline
  typename Map<Dist0, Dist1, Dist2>::processor_iterator
! Map<Dist0, Dist1, Dist2>::processor_end(subblock_type sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
--- 796,802 ----
  	  typename       Dist2>
  inline
  typename Map<Dist0, Dist1, Dist2>::processor_iterator
! Map<Dist0, Dist1, Dist2>::processor_end(index_type sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
*************** Map<Dist0, Dist1, Dist2>::processor_end(
*** 818,823 ****
--- 806,834 ----
  
  
  
+ /// Map's processor set.
+ 
+ /// Returns:
+ ///   A vector containing the map's processor set.
+ 
+ template <typename       Dist0,
+ 	  typename       Dist1,
+ 	  typename       Dist2>
+ inline
+ const_Vector<processor_type>
+ Map<Dist0, Dist1, Dist2>::processor_set()
+   const
+ {
+   Vector<processor_type> pset(this->num_procs_);
+ 
+   for (index_type i=0; i<this->num_procs_; ++i)
+     pset.put(i, this->pvec_[i]);
+ 
+   return pset;
+ }
+ 
+ 
+ 
  /// Get the number of patches in a subblock.
  
  /// Requires:
*************** template <typename       Dist0,
*** 828,834 ****
  	  typename       Dist2>
  inline
  length_type
! Map<Dist0, Dist1, Dist2>::num_patches(subblock_type sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
--- 839,845 ----
  	  typename       Dist2>
  inline
  length_type
! Map<Dist0, Dist1, Dist2>::num_patches(index_type sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
*************** template <typename       Dist0,
*** 858,864 ****
  template <dimension_type Dim>
  inline
  Domain<Dim>
! Map<Dist0, Dist1, Dist2>::get_subblock_dom(subblock_type sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
--- 869,875 ----
  template <dimension_type Dim>
  inline
  Domain<Dim>
! Map<Dist0, Dist1, Dist2>::subblock_domain(index_type sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
*************** template <typename       Dist0,
*** 889,896 ****
  template <dimension_type Dim>
  inline
  Domain<Dim>
! Map<Dist0, Dist1, Dist2>::get_global_dom(
!   subblock_type sb,
    index_type    p)
  const VSIP_NOTHROW
  {
--- 900,907 ----
  template <dimension_type Dim>
  inline
  Domain<Dim>
! Map<Dist0, Dist1, Dist2>::global_domain(
!   index_type    sb,
    index_type    p)
  const VSIP_NOTHROW
  {
*************** template <typename       Dist0,
*** 939,946 ****
  template <dimension_type Dim>
  inline
  Domain<Dim>
! Map<Dist0, Dist1, Dist2>::get_local_dom(
!   subblock_type sb,
    index_type    p
    )
    const VSIP_NOTHROW
--- 950,957 ----
  template <dimension_type Dim>
  inline
  Domain<Dim>
! Map<Dist0, Dist1, Dist2>::local_domain(
!   index_type    sb,
    index_type    p
    )
    const VSIP_NOTHROW
*************** template <typename       Dist0,
*** 989,995 ****
  template <dimension_type Dim>
  inline
  Domain<Dim>
! Map<Dist0, Dist1, Dist2>::applied_dom()
    const VSIP_NOTHROW
  {
    assert(dim_ == Dim);
--- 1000,1006 ----
  template <dimension_type Dim>
  inline
  Domain<Dim>
! Map<Dist0, Dist1, Dist2>::applied_domain()
    const VSIP_NOTHROW
  {
    assert(dim_ == Dim);
*************** struct Map_project_1<0, Map<Dist0, Dist1
*** 1152,1158 ****
      length_type num_sb_1 = map.num_subblocks(1);
      length_type num_sb_2 = map.num_subblocks(2);
  
!     subblock_type fix_sb_0 = map.impl_subblock_from_index(0, idx);
  
      Vector<processor_type> pvec(num_sb_1*num_sb_2);
  
--- 1163,1169 ----
      length_type num_sb_1 = map.num_subblocks(1);
      length_type num_sb_2 = map.num_subblocks(2);
  
!     index_type fix_sb_0 = map.impl_subblock_from_index(0, idx);
  
      Vector<processor_type> pvec(num_sb_1*num_sb_2);
  
*************** struct Map_project_1<1, Map<Dist0, Dist1
*** 1178,1184 ****
      length_type num_sb_1 = map.num_subblocks(1);
      length_type num_sb_2 = map.num_subblocks(2);
  
!     subblock_type fix_sb_1 = map.impl_subblock_from_index(1, idx);
  
      Vector<processor_type> pvec(num_sb_0*num_sb_2);
  
--- 1189,1195 ----
      length_type num_sb_1 = map.num_subblocks(1);
      length_type num_sb_2 = map.num_subblocks(2);
  
!     index_type fix_sb_1 = map.impl_subblock_from_index(1, idx);
  
      Vector<processor_type> pvec(num_sb_0*num_sb_2);
  
*************** struct Map_project_1<2, Map<Dist0, Dist1
*** 1208,1214 ****
      length_type num_sb_1 = map.num_subblocks(1);
      length_type num_sb_2 = map.num_subblocks(2);
  
!     subblock_type fix_sb_2 = map.impl_subblock_from_index(2, idx);
  
      Vector<processor_type> pvec(num_sb_0*num_sb_1);
  
--- 1219,1225 ----
      length_type num_sb_1 = map.num_subblocks(1);
      length_type num_sb_2 = map.num_subblocks(2);
  
!     index_type fix_sb_2 = map.impl_subblock_from_index(2, idx);
  
      Vector<processor_type> pvec(num_sb_0*num_sb_1);
  
*************** struct Map_project_2<0, 1, Map<Dist0, Di
*** 1247,1254 ****
      length_type num_sb_1 = map.num_subblocks(1);
      length_type num_sb_2 = map.num_subblocks(2);
  
!     subblock_type fix_sb_0 = map.impl_subblock_from_index(0, idx0);
!     subblock_type fix_sb_1 = map.impl_subblock_from_index(1, idx1);
  
      Vector<processor_type> pvec(num_sb_2);
  
--- 1258,1265 ----
      length_type num_sb_1 = map.num_subblocks(1);
      length_type num_sb_2 = map.num_subblocks(2);
  
!     index_type fix_sb_0 = map.impl_subblock_from_index(0, idx0);
!     index_type fix_sb_1 = map.impl_subblock_from_index(1, idx1);
  
      Vector<processor_type> pvec(num_sb_2);
  
*************** struct Map_project_2<0, 2, Map<Dist0, Di
*** 1276,1283 ****
      length_type num_sb_1 = map.num_subblocks(1);
      length_type num_sb_2 = map.num_subblocks(2);
  
!     subblock_type fix_sb_0 = map.impl_subblock_from_index(0, idx0);
!     subblock_type fix_sb_2 = map.impl_subblock_from_index(2, idx2);
  
      Vector<processor_type> pvec(num_sb_1);
  
--- 1287,1294 ----
      length_type num_sb_1 = map.num_subblocks(1);
      length_type num_sb_2 = map.num_subblocks(2);
  
!     index_type fix_sb_0 = map.impl_subblock_from_index(0, idx0);
!     index_type fix_sb_2 = map.impl_subblock_from_index(2, idx2);
  
      Vector<processor_type> pvec(num_sb_1);
  
*************** struct Map_project_2<1, 2, Map<Dist0, Di
*** 1305,1312 ****
      length_type num_sb_1 = map.num_subblocks(1);
      length_type num_sb_2 = map.num_subblocks(2);
  
!     subblock_type fix_sb_1 = map.impl_subblock_from_index(1, idx1);
!     subblock_type fix_sb_2 = map.impl_subblock_from_index(2, idx2);
  
      Vector<processor_type> pvec(num_sb_0);
  
--- 1316,1323 ----
      length_type num_sb_1 = map.num_subblocks(1);
      length_type num_sb_2 = map.num_subblocks(2);
  
!     index_type fix_sb_1 = map.impl_subblock_from_index(1, idx1);
!     index_type fix_sb_2 = map.impl_subblock_from_index(2, idx2);
  
      Vector<processor_type> pvec(num_sb_0);
  
*************** struct Map_subdomain<Dim, Map<Dist0, Dis
*** 1346,1352 ****
        {
  	// If this dimension is distributed, then subdomain must be full
  	if (dom[d].first() != 0 || dom[d].stride() != 1 ||
! 	    dom[d].size() != map.template applied_dom<Dim>()[d].size())
  	  VSIP_IMPL_THROW(
  	    impl::unimplemented(
  	      "Map_subdomain: Subviews must not break up distributed dimensions"));
--- 1357,1363 ----
        {
  	// If this dimension is distributed, then subdomain must be full
  	if (dom[d].first() != 0 || dom[d].stride() != 1 ||
! 	    dom[d].size() != map.template applied_domain<Dim>()[d].size())
  	  VSIP_IMPL_THROW(
  	    impl::unimplemented(
  	      "Map_subdomain: Subviews must not break up distributed dimensions"));
Index: src/vsip/par-services.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/par-services.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 par-services.cpp
*** src/vsip/par-services.cpp	12 Jul 2005 11:58:06 -0000	1.3
--- src/vsip/par-services.cpp	5 Dec 2005 15:42:10 -0000
***************
*** 13,18 ****
--- 13,20 ----
  
  #include <vsip/impl/par-services.hpp>
  
+ #include <vsip/vector.hpp>
+ 
  
  
  /***********************************************************************
*************** vsip::impl::Communicator vsip::impl::Par
*** 30,40 ****
  namespace vsip
  {
  
! processor_type
  num_processors()
! VSIP_NOTHROW
  {
    return impl::default_communicator().size();
  }
  
  } // namespace vsip
--- 32,74 ----
  namespace vsip
  {
  
! /// Return the number of processors in the data parallel clique.
! 
! length_type
  num_processors()
!   VSIP_NOTHROW
  {
    return impl::default_communicator().size();
  }
  
+ 
+ 
+ /// Return the set of processors in the data parallel clique.
+ 
+ const_Vector<processor_type>
+ processor_set()
+ {
+   impl::Communicator::pvec_type pvec;
+ 
+   pvec = impl::default_communicator().pvec(); 
+ 
+   Vector<processor_type> pset(pvec.size());
+   for (index_type i=0; i<pvec.size(); ++i)
+     pset.put(i, pvec[i]);
+ 
+   return pset;
+ }
+ 
+ 
+ 
+ /// Return the local processor.
+ 
+ processor_type
+ local_processor()
+   VSIP_NOTHROW
+ {
+   return impl::default_communicator().rank();
+ }
+ 
+ 
  } // namespace vsip
Index: src/vsip/support.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/support.hpp,v
retrieving revision 1.23
diff -c -p -r1.23 support.hpp
*** src/vsip/support.hpp	16 Nov 2005 13:56:23 -0000	1.23
--- src/vsip/support.hpp	5 Dec 2005 15:42:10 -0000
*************** class Local_map;
*** 206,215 ****
  typedef unsigned int processor_type;
  typedef signed int processor_difference_type;
  
! typedef unsigned int subblock_type;
! typedef signed int subblock_difference_type;
! 
! subblock_type  const no_subblock  = static_cast<subblock_type>(-1);
  processor_type const no_processor = static_cast<processor_type>(-1);
  
  
--- 206,212 ----
  typedef unsigned int processor_type;
  typedef signed int processor_difference_type;
  
! index_type     const no_subblock  = static_cast<index_type>(-1);
  processor_type const no_processor = static_cast<processor_type>(-1);
  
  
*************** enum distribution_type
*** 219,225 ****
  {
    whole,
    block,
!   cyclic 
  };
  
  
--- 216,223 ----
  {
    whole,
    block,
!   cyclic,
!   other
  };
  
  
*************** const dimension_type dim2 = 2;		///< Thi
*** 285,290 ****
--- 283,290 ----
  
  /// Return the total number of processors executing the program.
  processor_type num_processors() VSIP_NOTHROW;
+ //FIXME// Vector<processor_type> processor_set();
+ processor_type local_processor() VSIP_NOTHROW;
  
  } // namespace vsip
  
Index: src/vsip/impl/dist.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/dist.hpp,v
retrieving revision 1.10
diff -c -p -r1.10 dist.hpp
*** src/vsip/impl/dist.hpp	14 Nov 2005 22:32:53 -0000	1.10
--- src/vsip/impl/dist.hpp	5 Dec 2005 15:42:10 -0000
*************** public:
*** 238,244 ****
    distribution_type distribution() const VSIP_NOTHROW
      { return whole; }
  
!   subblock_type num_subblocks() const VSIP_NOTHROW
      { return 1; }
  
    length_type cyclic_contiguity() const VSIP_NOTHROW
--- 238,244 ----
    distribution_type distribution() const VSIP_NOTHROW
      { return whole; }
  
!   index_type num_subblocks() const VSIP_NOTHROW
      { return 1; }
  
    length_type cyclic_contiguity() const VSIP_NOTHROW
*************** public:
*** 246,270 ****
  
    // Implementation specific.
  public:
!   length_type impl_subblock_patches(Domain<1> const&, subblock_type sb)
      const VSIP_NOTHROW
    { assert(sb == 0); return 1; }
  
!   length_type impl_subblock_size(Domain<1> const& dom, subblock_type sb)
      const VSIP_NOTHROW
    { assert(sb == 0); return dom.size(); }
  
!   Domain<1> impl_patch_global_dom(Domain<1> const& dom, subblock_type sb,
  				  index_type p)
      const VSIP_NOTHROW
    { assert(sb == 0 && p == 0); return dom; }
  
!   Domain<1> impl_patch_local_dom(Domain<1> const& dom, subblock_type sb,
  				 index_type p)
      const VSIP_NOTHROW
    { assert(sb == 0 && p == 0); return dom; }
  
!   subblock_type impl_subblock_from_index(Domain<1> const& dom, index_type i)
      const VSIP_NOTHROW
    { assert(i < dom.size()); return 0; }
  
--- 246,270 ----
  
    // Implementation specific.
  public:
!   length_type impl_subblock_patches(Domain<1> const&, index_type sb)
      const VSIP_NOTHROW
    { assert(sb == 0); return 1; }
  
!   length_type impl_subblock_size(Domain<1> const& dom, index_type sb)
      const VSIP_NOTHROW
    { assert(sb == 0); return dom.size(); }
  
!   Domain<1> impl_patch_global_dom(Domain<1> const& dom, index_type sb,
  				  index_type p)
      const VSIP_NOTHROW
    { assert(sb == 0 && p == 0); return dom; }
  
!   Domain<1> impl_patch_local_dom(Domain<1> const& dom, index_type sb,
  				 index_type p)
      const VSIP_NOTHROW
    { assert(sb == 0 && p == 0); return dom; }
  
!   index_type impl_subblock_from_index(Domain<1> const& dom, index_type i)
      const VSIP_NOTHROW
    { assert(i < dom.size()); return 0; }
  
*************** public:
*** 272,277 ****
--- 272,283 ----
      const VSIP_NOTHROW
    { assert(i < dom.size()); return i; }
  
+   index_type impl_global_from_local_index(Domain<1> const& dom,
+ 					  index_type       sb,
+ 					  index_type       i)
+     const VSIP_NOTHROW
+   { assert(i < dom.size() && sb == 0); return i; }
+ 
    // No member data.
  };
  
*************** public:
*** 293,299 ****
    distribution_type distribution() const VSIP_NOTHROW
      { return block; }
  
!   subblock_type num_subblocks() const VSIP_NOTHROW
      { return num_subblocks_; }
  
    length_type cyclic_contiguity() const VSIP_NOTHROW
--- 299,305 ----
    distribution_type distribution() const VSIP_NOTHROW
      { return block; }
  
!   index_type num_subblocks() const VSIP_NOTHROW
      { return num_subblocks_; }
  
    length_type cyclic_contiguity() const VSIP_NOTHROW
*************** public:
*** 301,326 ****
  
    // Implementation specific.
  public:
!   length_type impl_subblock_patches(Domain<1> const& dom, subblock_type sb)
      const VSIP_NOTHROW;
  
!   length_type impl_subblock_size(Domain<1> const& dom, subblock_type sb)
      const VSIP_NOTHROW;
  
!   Domain<1> impl_patch_global_dom(Domain<1> const& dom, subblock_type sb,
  				  index_type p)
      const VSIP_NOTHROW;
  
!   Domain<1> impl_patch_local_dom(Domain<1> const& dom, subblock_type sb,
  				 index_type p)
      const VSIP_NOTHROW;
  
!   subblock_type impl_subblock_from_index(Domain<1> const& dom, index_type i)
      const VSIP_NOTHROW;
  
    index_type impl_local_from_global_index(Domain<1> const& dom, index_type i)
      const VSIP_NOTHROW;
  
    // Member data.
  private:
    length_type num_subblocks_;
--- 307,337 ----
  
    // Implementation specific.
  public:
!   length_type impl_subblock_patches(Domain<1> const& dom, index_type sb)
      const VSIP_NOTHROW;
  
!   length_type impl_subblock_size(Domain<1> const& dom, index_type sb)
      const VSIP_NOTHROW;
  
!   Domain<1> impl_patch_global_dom(Domain<1> const& dom, index_type sb,
  				  index_type p)
      const VSIP_NOTHROW;
  
!   Domain<1> impl_patch_local_dom(Domain<1> const& dom, index_type sb,
  				 index_type p)
      const VSIP_NOTHROW;
  
!   index_type impl_subblock_from_index(Domain<1> const& dom, index_type i)
      const VSIP_NOTHROW;
  
    index_type impl_local_from_global_index(Domain<1> const& dom, index_type i)
      const VSIP_NOTHROW;
  
+   index_type impl_global_from_local_index(Domain<1> const& dom,
+ 					  index_type       sb,
+ 					  index_type       i)
+     const VSIP_NOTHROW;
+ 
    // Member data.
  private:
    length_type num_subblocks_;
*************** public:
*** 345,351 ****
    distribution_type distribution() const VSIP_NOTHROW
      { return cyclic; }
  
!   subblock_type num_subblocks() const VSIP_NOTHROW
      { return num_subblocks_; }
  
    length_type cyclic_contiguity() const VSIP_NOTHROW
--- 356,362 ----
    distribution_type distribution() const VSIP_NOTHROW
      { return cyclic; }
  
!   index_type num_subblocks() const VSIP_NOTHROW
      { return num_subblocks_; }
  
    length_type cyclic_contiguity() const VSIP_NOTHROW
*************** public:
*** 353,378 ****
  
    // Implementation specific functions.
  public:
!   length_type impl_subblock_patches(Domain<1> const& dom, subblock_type sb)
      const VSIP_NOTHROW;
  
!   length_type impl_subblock_size(Domain<1> const& dom, subblock_type sb)
      const VSIP_NOTHROW;
  
!   Domain<1> impl_patch_global_dom(Domain<1> const& dom, subblock_type sb,
  				  index_type p)
      const VSIP_NOTHROW;
  
!   Domain<1> impl_patch_local_dom(Domain<1> const& dom, subblock_type sb,
  				 index_type p)
      const VSIP_NOTHROW;
  
!   subblock_type impl_subblock_from_index(Domain<1> const& dom, index_type i)
      const VSIP_NOTHROW;
  
    index_type impl_local_from_global_index(Domain<1> const& dom, index_type i)
      const VSIP_NOTHROW;
  
    // Members
  private:
    length_type num_subblocks_;
--- 364,394 ----
  
    // Implementation specific functions.
  public:
!   length_type impl_subblock_patches(Domain<1> const& dom, index_type sb)
      const VSIP_NOTHROW;
  
!   length_type impl_subblock_size(Domain<1> const& dom, index_type sb)
      const VSIP_NOTHROW;
  
!   Domain<1> impl_patch_global_dom(Domain<1> const& dom, index_type sb,
  				  index_type p)
      const VSIP_NOTHROW;
  
!   Domain<1> impl_patch_local_dom(Domain<1> const& dom, index_type sb,
  				 index_type p)
      const VSIP_NOTHROW;
  
!   index_type impl_subblock_from_index(Domain<1> const& dom, index_type i)
      const VSIP_NOTHROW;
  
    index_type impl_local_from_global_index(Domain<1> const& dom, index_type i)
      const VSIP_NOTHROW;
  
+   index_type impl_global_from_local_index(Domain<1> const& dom,
+ 					  index_type       sb,
+ 					  index_type       i)
+     const VSIP_NOTHROW;
+ 
    // Members
  private:
    length_type num_subblocks_;
*************** Block_dist::Block_dist(
*** 404,410 ****
  
  
  inline length_type
! Block_dist::impl_subblock_patches(Domain<1> const& /*dom*/, subblock_type sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
--- 420,426 ----
  
  
  inline length_type
! Block_dist::impl_subblock_patches(Domain<1> const& /*dom*/, index_type sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
*************** Block_dist::impl_subblock_patches(Domain
*** 416,422 ****
  inline length_type
  Block_dist::impl_subblock_size(
    Domain<1> const& dom,
!   subblock_type    sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
--- 432,438 ----
  inline length_type
  Block_dist::impl_subblock_size(
    Domain<1> const& dom,
!   index_type       sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
*************** Block_dist::impl_subblock_size(
*** 428,434 ****
  inline Domain<1>
  Block_dist::impl_patch_global_dom(
    Domain<1> const& dom,
!   subblock_type    sb,
    index_type       p)
    const VSIP_NOTHROW
  {
--- 444,450 ----
  inline Domain<1>
  Block_dist::impl_patch_global_dom(
    Domain<1> const& dom,
!   index_type       sb,
    index_type       p)
    const VSIP_NOTHROW
  {
*************** Block_dist::impl_patch_global_dom(
*** 444,450 ****
  inline Domain<1>
  Block_dist::impl_patch_local_dom(
    Domain<1> const& dom,
!   subblock_type    sb,
    index_type       p)
    const VSIP_NOTHROW
  {
--- 460,466 ----
  inline Domain<1>
  Block_dist::impl_patch_local_dom(
    Domain<1> const& dom,
!   index_type       sb,
    index_type       p)
    const VSIP_NOTHROW
  {
*************** Block_dist::impl_patch_local_dom(
*** 463,469 ****
  // cleanly, then the remaining elements (called the "spill_over")
  // are distributed 1 each to first subblocks.
  
! inline subblock_type 
  Block_dist::impl_subblock_from_index(Domain<1> const& dom, index_type i)
    const VSIP_NOTHROW
  {
--- 479,485 ----
  // cleanly, then the remaining elements (called the "spill_over")
  // are distributed 1 each to first subblocks.
  
! inline index_type 
  Block_dist::impl_subblock_from_index(Domain<1> const& dom, index_type i)
    const VSIP_NOTHROW
  {
*************** Block_dist::impl_local_from_global_index
*** 493,498 ****
--- 509,539 ----
  
  
  
+ /// Determine the global index corresponding to a local subblock index
+ 
+ /// Requires:
+ ///   DOM is the full global domain,
+ ///   SB is a valid subblock (SB < number of subblocks).
+ ///   I  is an index into the subblock.
+ /// Returns:
+ 
+ inline index_type 
+ Block_dist::impl_global_from_local_index(
+   Domain<1> const& dom,
+   index_type       sb,
+   index_type       i)
+ const VSIP_NOTHROW
+ {
+   length_type nominal_block_size = dom.length() / num_subblocks_;
+   length_type spill_over         = dom.length() % num_subblocks_;
+ 
+   return sb * nominal_block_size  +
+          std::min(sb, spill_over) +
+          i;
+ }
+ 
+ 
+ 
  // -------------------------------------------------------------------- //
  // Cyclic_dist
  
*************** VSIP_NOTHROW
*** 528,534 ****
  inline length_type
  Cyclic_dist::impl_subblock_patches(
    Domain<1> const& dom,
!   subblock_type    sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
--- 569,575 ----
  inline length_type
  Cyclic_dist::impl_subblock_patches(
    Domain<1> const& dom,
!   index_type       sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
*************** Cyclic_dist::impl_subblock_patches(
*** 548,554 ****
  inline length_type
  Cyclic_dist::impl_subblock_size(
    Domain<1> const& dom,
!   subblock_type    sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
--- 589,595 ----
  inline length_type
  Cyclic_dist::impl_subblock_size(
    Domain<1> const& dom,
!   index_type       sb)
    const VSIP_NOTHROW
  {
    assert(sb < num_subblocks_);
*************** Cyclic_dist::impl_subblock_size(
*** 569,575 ****
  inline Domain<1>
  Cyclic_dist::impl_patch_global_dom(
    Domain<1> const& dom,
!   subblock_type    sb,
    index_type       p)
    const VSIP_NOTHROW
  {
--- 610,616 ----
  inline Domain<1>
  Cyclic_dist::impl_patch_global_dom(
    Domain<1> const& dom,
!   index_type       sb,
    index_type       p)
    const VSIP_NOTHROW
  {
*************** Cyclic_dist::impl_patch_global_dom(
*** 598,604 ****
  inline Domain<1>
  Cyclic_dist::impl_patch_local_dom(
    Domain<1> const& dom,
!   subblock_type    sb,
    index_type       p)
    const VSIP_NOTHROW
  {
--- 639,645 ----
  inline Domain<1>
  Cyclic_dist::impl_patch_local_dom(
    Domain<1> const& dom,
!   index_type       sb,
    index_type       p)
    const VSIP_NOTHROW
  {
*************** Cyclic_dist::impl_patch_local_dom(
*** 615,621 ****
  
  
  
! inline subblock_type 
  Cyclic_dist::impl_subblock_from_index(Domain<1> const& /*dom*/, index_type /*i*/)
    const VSIP_NOTHROW
  {
--- 656,662 ----
  
  
  
! inline index_type 
  Cyclic_dist::impl_subblock_from_index(Domain<1> const& /*dom*/, index_type /*i*/)
    const VSIP_NOTHROW
  {
*************** Cyclic_dist::impl_local_from_global_inde
*** 631,636 ****
--- 672,703 ----
    VSIP_IMPL_THROW(impl::unimplemented("Cyclic_dist::impl_local_from_global_index()"));
  }
  
+ 
+ 
+ /// Determine the global index corresponding to a local subblock index
+ 
+ /// Requires:
+ ///   DOM is the full global domain,
+ ///   SB is a valid subblock (SB < number of subblocks).
+ ///   I  is an index into the subblock.
+ /// Returns:
+ ///   The global index corresponding to subblock SB index I.
+ 
+ inline index_type 
+ Cyclic_dist::impl_global_from_local_index(
+   Domain<1> const& /*dom*/,
+   index_type       sb,
+   index_type       i)
+ const VSIP_NOTHROW
+ {
+   assert(sb < num_subblocks_);
+ 
+   index_type p        = i / contiguity_;
+   index_type p_offset = i % contiguity_;
+ 
+   return (p * num_subblocks_ + sb) * contiguity_ + p_offset;
+ }
+ 
  } // namespace vsip
  
  #endif // VSIP_DIST_HPP
Index: src/vsip/impl/distributed-block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/distributed-block.hpp,v
retrieving revision 1.15
diff -c -p -r1.15 distributed-block.hpp
*** src/vsip/impl/distributed-block.hpp	2 Nov 2005 18:44:03 -0000	1.15
--- src/vsip/impl/distributed-block.hpp	5 Dec 2005 15:42:10 -0000
*************** private:
*** 52,65 ****
    enum private_type {};
    typedef typename impl::Complex_value_type<value_type, private_type>::type uT;
  
-   typedef typename map_type::subblock_iterator subblock_iterator;
- 
    // Constructors and destructor.
  public:
    Distributed_block(Domain<dim> const& dom, Map const& map = Map())
      : map_           (map),
        proc_          (map_.impl_rank()),
!       sb_            (map_.impl_subblock()),
        subblock_      (NULL)
    {
      map_.apply(dom);
--- 52,63 ----
    enum private_type {};
    typedef typename impl::Complex_value_type<value_type, private_type>::type uT;
  
    // Constructors and destructor.
  public:
    Distributed_block(Domain<dim> const& dom, Map const& map = Map())
      : map_           (map),
        proc_          (map_.impl_rank()),
!       sb_            (map_.subblock(proc_)),
        subblock_      (NULL)
    {
      map_.apply(dom);
*************** public:
*** 67,73 ****
        size_[d] = dom[d].length();
  
      Domain<dim> sb_dom = 
!       (sb_ != no_subblock) ? map_.template get_subblock_dom<dim>(sb_)
                             : empty_domain<dim>();
  
      subblock_ = new Block(sb_dom);
--- 65,71 ----
        size_[d] = dom[d].length();
  
      Domain<dim> sb_dom = 
!       (sb_ != no_subblock) ? map_.template subblock_domain<dim>(sb_)
                             : empty_domain<dim>();
  
      subblock_ = new Block(sb_dom);
*************** public:
*** 77,83 ****
  		    Map const& map = Map())
      : map_           (map),
        proc_          (map_.impl_rank()),
!       sb_            (map_.impl_subblock()),
        subblock_      (NULL)
    {
      map_.apply(dom);
--- 75,81 ----
  		    Map const& map = Map())
      : map_           (map),
        proc_          (map_.impl_rank()),
!       sb_            (map_.subblock(proc_)),
        subblock_      (NULL)
    {
      map_.apply(dom);
*************** public:
*** 85,91 ****
        size_[d] = dom[d].length();
  
      Domain<dim> sb_dom = 
!       (sb_ != no_subblock) ? map_.template get_subblock_dom<dim>(sb_)
                             : empty_domain<dim>();
  
      subblock_ = new Block(sb_dom, value);
--- 83,89 ----
        size_[d] = dom[d].length();
  
      Domain<dim> sb_dom = 
!       (sb_ != no_subblock) ? map_.template subblock_domain<dim>(sb_)
                             : empty_domain<dim>();
  
      subblock_ = new Block(sb_dom, value);
*************** public:
*** 97,103 ****
      Map const&         map = Map())
      : map_           (map),
        proc_          (map_.impl_rank()),
!       sb_            (map_.impl_subblock()),
        subblock_      (NULL)
    {
      map_.apply(dom);
--- 95,101 ----
      Map const&         map = Map())
      : map_           (map),
        proc_          (map_.impl_rank()),
!       sb_            (map_.subblock()),
        subblock_      (NULL)
    {
      map_.apply(dom);
*************** public:
*** 105,111 ****
        size_[d] = dom[d].length();
  
      Domain<dim> sb_dom = 
!       (sb_ != no_subblock) ? map_.template get_subblock_dom<dim>(sb_)
                             : empty_domain<dim>();
  
      subblock_ = new Block(sb_dom, ptr);
--- 103,109 ----
        size_[d] = dom[d].length();
  
      Domain<dim> sb_dom = 
!       (sb_ != no_subblock) ? map_.template subblock_domain<dim>(sb_)
                             : empty_domain<dim>();
  
      subblock_ = new Block(sb_dom, ptr);
*************** public:
*** 150,166 ****
      return *subblock_;
    }
  
!   subblock_type subblock() const { return sb_; }
  
!   void assert_local(subblock_type sb) const
      { assert(sb == sb_ && subblock_ != NULL); }
  
-   subblock_iterator subblocks_begin() const VSIP_NOTHROW
-     { return map_.subblocks_begin(proc_); }
- 
-   subblock_iterator subblocks_end  () const VSIP_NOTHROW
-     { return map_.subblocks_end(proc_); }
- 
    // User storage functions.
  public:
    void admit(bool update = true) VSIP_NOTHROW
--- 148,158 ----
      return *subblock_;
    }
  
!   index_type subblock() const { return sb_; }
  
!   void assert_local(index_type sb) const
      { assert(sb == sb_ && subblock_ != NULL); }
  
    // User storage functions.
  public:
    void admit(bool update = true) VSIP_NOTHROW
*************** public:
*** 200,206 ****
  public:
    map_type              map_;
    processor_type	proc_;			// This processor in comm.
!   subblock_type		sb_;
    Block*		subblock_;
    length_type	        size_[dim];
  };
--- 192,198 ----
  public:
    map_type              map_;
    processor_type	proc_;			// This processor in comm.
!   index_type   		sb_;
    Block*		subblock_;
    length_type	        size_[dim];
  };
*************** template <typename BlockT>
*** 347,353 ****
  void
  assert_local(
    BlockT const& /*block*/,
!   subblock_type sb)
  {
    // In general case, we should assume block is not distributed and
    // just return it.
--- 339,345 ----
  void
  assert_local(
    BlockT const& /*block*/,
!   index_type    sb)
  {
    // In general case, we should assume block is not distributed and
    // just return it.
*************** template <typename BlockT,
*** 364,370 ****
  void
  assert_local(
    Distributed_block<BlockT, MapT> const& block,
!   subblock_type                          sb)
  {
    block.assert_local(sb);
  }
--- 356,362 ----
  void
  assert_local(
    Distributed_block<BlockT, MapT> const& block,
!   index_type                             sb)
  {
    block.assert_local(sb);
  }
*************** template <template <typename, typename> 
*** 429,463 ****
  void
  view_assert_local(
    View<T, Block> v,
!   subblock_type  sb)
  {
    assert_local(v.block(), sb);
  }
  
  
  
- // An alternative to implementing parallel helper functions as 
- // members of Distributed_block is to have them as free functions.
- // For example:
- template <typename Block>
- typename Block::map_type::subblock_iterator
- subblocks_begin(
-   Block& block)
- {
-   return block.map().subblocks_begin(block.map().impl_rank());
- }
- 
- template <typename Block>
- typename Block::map_type::subblock_iterator
- subblocks_end(
-   Block& block)
- {
-   return block.map().subblocks_end(block.map().impl_rank());
- }
- 
- 
- 
- 
  } // namespace vsip::impl
  } // namespace vsip
  
--- 421,433 ----
  void
  view_assert_local(
    View<T, Block> v,
!   index_type     sb)
  {
    assert_local(v.block(), sb);
  }
  
  
  
  } // namespace vsip::impl
  } // namespace vsip
  
Index: src/vsip/impl/expr_generator_block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_generator_block.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 expr_generator_block.hpp
*** src/vsip/impl/expr_generator_block.hpp	26 Sep 2005 20:23:29 -0000	1.1
--- src/vsip/impl/expr_generator_block.hpp	5 Dec 2005 15:42:10 -0000
*************** template <dimension_type Dim,
*** 152,158 ****
  void
  assert_local(
    Generator_expr_block<Dim, Generator> const& /*block*/,
!   subblock_type                               /*sb*/)
  {
  }
  
--- 152,158 ----
  void
  assert_local(
    Generator_expr_block<Dim, Generator> const& /*block*/,
!   index_type                                  /*sb*/)
  {
  }
  
Index: src/vsip/impl/global_map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/global_map.hpp,v
retrieving revision 1.7
diff -c -p -r1.7 global_map.hpp
*** src/vsip/impl/global_map.hpp	2 Nov 2005 18:44:03 -0000	1.7
--- src/vsip/impl/global_map.hpp	5 Dec 2005 15:42:10 -0000
*************** class Global_map
*** 32,38 ****
  {
    // Compile-time typedefs.
  public:
-   typedef impl::Value_iterator<subblock_type,  unsigned> subblock_iterator;
    typedef impl::Value_iterator<processor_type, unsigned> processor_iterator;
    typedef impl::Communicator::pvec_type pvec_type;
  
--- 32,37 ----
*************** public:
*** 44,83 ****
  public:
    length_type num_subblocks() const VSIP_NOTHROW { return 1; }
  
!   subblock_type impl_subblock(processor_type pr) const VSIP_NOTHROW
      { return 0; }
!   subblock_type impl_subblock() const VSIP_NOTHROW
      { return 0; }
  
!   subblock_iterator subblocks_begin(processor_type /*pr*/) const VSIP_NOTHROW
!     { return subblock_iterator(0, 1); }
!   subblock_iterator subblocks_end  (processor_type /*pr*/) const VSIP_NOTHROW
!     { return subblock_iterator(1, 1); }
! 
!   processor_iterator processor_begin(subblock_type /*sb*/) const VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Global_map::processor_begin()")); }
!   processor_iterator processor_end  (subblock_type /*sb*/) const VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Global_map::processor_end()")); }
  
    // Applied map functions.
  public:
!   length_type num_patches     (subblock_type sb) const VSIP_NOTHROW
      { assert(sb == 0); return 1; }
  
    void apply(Domain<Dim> const& dom) VSIP_NOTHROW
      { dom_ = dom; }
  
    template <dimension_type Dim2>
!   Domain<Dim2> get_subblock_dom(subblock_type sb) const VSIP_NOTHROW
      { assert(sb == 0); return dom_; }
  
    template <dimension_type Dim2>
!   Domain<Dim2> get_global_dom(subblock_type sb, index_type patch)
      const VSIP_NOTHROW
      { assert(sb == 0 && patch == 0); return dom_; }
  
    template <dimension_type Dim2>
!   Domain<Dim2> get_local_dom (subblock_type sb, index_type patch)
      const VSIP_NOTHROW
      { assert(sb == 0 && patch == 0); return dom_; }
  
--- 43,77 ----
  public:
    length_type num_subblocks() const VSIP_NOTHROW { return 1; }
  
!   index_type subblock(processor_type /*pr*/) const VSIP_NOTHROW
      { return 0; }
!   index_type subblock() const VSIP_NOTHROW
      { return 0; }
  
!   processor_iterator processor_begin(index_type /*sb*/) const VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Global_map::processor_begin()")); }
!   processor_iterator processor_end  (index_type /*sb*/) const VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Global_map::processor_end()")); }
  
    // Applied map functions.
  public:
!   length_type num_patches     (index_type sb) const VSIP_NOTHROW
      { assert(sb == 0); return 1; }
  
    void apply(Domain<Dim> const& dom) VSIP_NOTHROW
      { dom_ = dom; }
  
    template <dimension_type Dim2>
!   Domain<Dim2> subblock_domain(index_type sb) const VSIP_NOTHROW
      { assert(sb == 0); return dom_; }
  
    template <dimension_type Dim2>
!   Domain<Dim2> global_domain(index_type sb, index_type patch)
      const VSIP_NOTHROW
      { assert(sb == 0 && patch == 0); return dom_; }
  
    template <dimension_type Dim2>
!   Domain<Dim2> local_domain (index_type sb, index_type patch)
      const VSIP_NOTHROW
      { assert(sb == 0 && patch == 0); return dom_; }
  
Index: src/vsip/impl/local_map.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/local_map.hpp,v
retrieving revision 1.5
diff -c -p -r1.5 local_map.hpp
*** src/vsip/impl/local_map.hpp	2 Nov 2005 18:44:04 -0000	1.5
--- src/vsip/impl/local_map.hpp	5 Dec 2005 15:42:10 -0000
***************
*** 3,9 ****
  /** @file    vsip/local_map.hpp
      @author  Jules Bergmann
      @date    2005-06-08
!     @brief   VSIPL++ Library: Global_map class.
  
  */
  
--- 3,9 ----
  /** @file    vsip/local_map.hpp
      @author  Jules Bergmann
      @date    2005-06-08
!     @brief   VSIPL++ Library: Local_map class.
  
  */
  
*************** class Local_map
*** 35,41 ****
  {
    // Compile-time typedefs.
  public:
-   typedef impl::Value_iterator<subblock_type,  unsigned> subblock_iterator;
    typedef impl::Value_iterator<processor_type, unsigned> processor_iterator;
    typedef impl::Communicator::pvec_type pvec_type;
  
--- 35,40 ----
*************** public:
*** 51,76 ****
  
    // Accessors.
  public:
    length_type num_subblocks() const VSIP_NOTHROW { return 1; }
  
!   subblock_type impl_subblock(processor_type /*pr*/) const VSIP_NOTHROW
      { return 0; }
-   subblock_type impl_subblock() const VSIP_NOTHROW
-     { return 0; }
- 
-   subblock_iterator subblocks_begin(processor_type /*pr*/) const VSIP_NOTHROW
-     { return subblock_iterator(0, 1); }
-   subblock_iterator subblocks_end  (processor_type /*pr*/) const VSIP_NOTHROW
-     { return subblock_iterator(1, 1); }
  
!   processor_iterator processor_begin(subblock_type /*sb*/) const VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Local_map::processor_begin()")); }
!   processor_iterator processor_end  (subblock_type /*sb*/) const VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Local_map::processor_end()")); }
  
    // Applied map functions.
  public:
!   length_type num_patches     (subblock_type sb) const VSIP_NOTHROW
      { assert(sb == 0); return 1; }
  
    template <dimension_type Dim>
--- 50,77 ----
  
    // Accessors.
  public:
+   distribution_type distribution     (dimension_type) const VSIP_NOTHROW
+     { return whole; }
+   length_type       num_subblocks    (dimension_type) const VSIP_NOTHROW
+     { return 1; }
+   length_type       cyclic_contiguity(dimension_type) const VSIP_NOTHROW
+     { return 0; }
+ 
    length_type num_subblocks() const VSIP_NOTHROW { return 1; }
  
!   index_type subblock(processor_type pr) const VSIP_NOTHROW
!     { return (pr == local_processor()) ? 0 : no_subblock; }
!   index_type subblock() const VSIP_NOTHROW
      { return 0; }
  
!   processor_iterator processor_begin(index_type /*sb*/) const VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Local_map::processor_begin()")); }
!   processor_iterator processor_end  (index_type /*sb*/) const VSIP_NOTHROW
      { VSIP_IMPL_THROW(impl::unimplemented("Local_map::processor_end()")); }
  
    // Applied map functions.
  public:
!   length_type num_patches     (index_type sb) const VSIP_NOTHROW
      { assert(sb == 0); return 1; }
  
    template <dimension_type Dim>
*************** public:
*** 78,93 ****
      {}
  
    template <dimension_type Dim2>
!   Domain<Dim2> get_subblock_dom(subblock_type sb) const VSIP_NOTHROW
      { assert(0); }
  
    template <dimension_type Dim2>
!   Domain<Dim2> get_global_dom(subblock_type /*sb*/, index_type /*patch*/)
      const VSIP_NOTHROW
      { assert(0); }
  
    template <dimension_type Dim2>
!   Domain<Dim2> get_local_dom (subblock_type /*sb*/, index_type /*patch*/)
      const VSIP_NOTHROW
      { assert(0); }
  
--- 79,94 ----
      {}
  
    template <dimension_type Dim2>
!   Domain<Dim2> subblock_domain(index_type sb) const VSIP_NOTHROW
      { assert(0); }
  
    template <dimension_type Dim2>
!   Domain<Dim2> global_domain(index_type /*sb*/, index_type /*patch*/)
      const VSIP_NOTHROW
      { assert(0); }
  
    template <dimension_type Dim2>
!   Domain<Dim2> local_domain (index_type /*sb*/, index_type /*patch*/)
      const VSIP_NOTHROW
      { assert(0); }
  
Index: src/vsip/impl/par-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-assign.hpp,v
retrieving revision 1.9
diff -c -p -r1.9 par-assign.hpp
*** src/vsip/impl/par-assign.hpp	16 Sep 2005 22:03:20 -0000	1.9
--- src/vsip/impl/par-assign.hpp	5 Dec 2005 15:42:10 -0000
*************** public:
*** 116,127 ****
  
  	  for (index_type sp=0; sp<src_am.num_patches(*cur); ++sp)
  	  {
! 	    Domain<dim> src_dom  = src_am.template get_global_dom<dim>(*cur, sp);
! 	    Domain<dim> src_ldom = src_am.template get_local_dom<dim>(*cur, sp);
  
  	    for (index_type dp=0; dp<dst_am.num_patches(*dst_cur); ++dp)
  	    {
! 	      Domain<dim> dst_dom = dst_am.template get_global_dom<dim>(*dst_cur, dp);
  
  	      Domain<dim> intr;
  
--- 116,127 ----
  
  	  for (index_type sp=0; sp<src_am.num_patches(*cur); ++sp)
  	  {
! 	    Domain<dim> src_dom  = src_am.template global_domain<dim>(*cur, sp);
! 	    Domain<dim> src_ldom = src_am.template local_domain<dim>(*cur, sp);
  
  	    for (index_type dp=0; dp<dst_am.num_patches(*dst_cur); ++dp)
  	    {
! 	      Domain<dim> dst_dom = dst_am.template global_domain<dim>(*dst_cur, dp);
  
  	      Domain<dim> intr;
  
*************** public:
*** 177,188 ****
  
  	  for (index_type sp=0; sp<src_am.num_patches(*src_cur); ++sp)
  	  {
! 	    Domain<dim> src_dom = src_am.template get_global_dom<dim>(*src_cur, sp);
  
  	    for (index_type dp=0; dp<dst_am.num_patches(*cur); ++dp)
  	    {
! 	      Domain<dim> dst_dom  = dst_am.template get_global_dom<dim>(*cur, dp);
! 	      Domain<dim> dst_ldom = dst_am.template get_local_dom<dim>(*cur, dp);
  
  
  	      Domain<dim> intr;
--- 177,188 ----
  
  	  for (index_type sp=0; sp<src_am.num_patches(*src_cur); ++sp)
  	  {
! 	    Domain<dim> src_dom = src_am.template global_domain<dim>(*src_cur, sp);
  
  	    for (index_type dp=0; dp<dst_am.num_patches(*cur); ++dp)
  	    {
! 	      Domain<dim> dst_dom  = dst_am.template global_domain<dim>(*cur, dp);
! 	      Domain<dim> dst_ldom = dst_am.template local_domain<dim>(*cur, dp);
  
  
  	      Domain<dim> intr;
*************** public:
*** 289,300 ****
  
  	  for (index_type dp=0; dp<dst_am.num_patches(*dst_cur); ++dp)
  	  {
! 	    Domain<dim> dst_dom = dst_am.template get_global_dom<dim>(*dst_cur, dp);
  
  	    for (index_type sp=0; sp<src_am.num_patches(*cur); ++sp)
  	    {
! 	      Domain<dim> src_dom  = src_am.template get_global_dom<dim>(*cur, sp);
! 	      Domain<dim> src_ldom = src_am.template get_local_dom<dim>(*cur, sp);
  
  	      Domain<dim> intr;
  
--- 289,300 ----
  
  	  for (index_type dp=0; dp<dst_am.num_patches(*dst_cur); ++dp)
  	  {
! 	    Domain<dim> dst_dom = dst_am.template global_domain<dim>(*dst_cur, dp);
  
  	    for (index_type sp=0; sp<src_am.num_patches(*cur); ++sp)
  	    {
! 	      Domain<dim> src_dom  = src_am.template global_domain<dim>(*cur, sp);
! 	      Domain<dim> src_ldom = src_am.template local_domain<dim>(*cur, sp);
  
  	      Domain<dim> intr;
  
*************** public:
*** 348,359 ****
  	{
  	  for (index_type dp=0; dp<dst_am.num_patches(*cur); ++dp)
  	  {
! 	    Domain<dim> dst_dom  = dst_am.template get_global_dom<dim>(*cur, dp);
! 	    Domain<dim> dst_ldom = dst_am.template get_local_dom<dim>(*cur, dp);
  
  	    for (index_type sp=0; sp<src_am.num_patches(*src_cur); ++sp)
  	    {
! 	      Domain<dim> src_dom = src_am.template get_global_dom<dim>(*src_cur, sp);
  
  	      Domain<dim> intr;
  
--- 348,359 ----
  	{
  	  for (index_type dp=0; dp<dst_am.num_patches(*cur); ++dp)
  	  {
! 	    Domain<dim> dst_dom  = dst_am.template global_domain<dim>(*cur, dp);
! 	    Domain<dim> dst_ldom = dst_am.template local_domain<dim>(*cur, dp);
  
  	    for (index_type sp=0; sp<src_am.num_patches(*src_cur); ++sp)
  	    {
! 	      Domain<dim> src_dom = src_am.template global_domain<dim>(*src_cur, sp);
  
  	      Domain<dim> intr;
  
*************** private:
*** 548,559 ****
  
  	  for (index_type dp=0; dp<dst_am.num_patches(*dst_cur); ++dp)
  	  {
! 	    Domain<dim> dst_dom = dst_am.template get_global_dom<dim>(*dst_cur, dp);
  
  	    for (index_type sp=0; sp<src_am.num_patches(*cur); ++sp)
  	    {
! 	      Domain<dim> src_dom  = src_am.template get_global_dom<dim>(*cur, sp);
! 	      Domain<dim> src_ldom = src_am.template get_local_dom<dim>(*cur, sp);
  
  	      Domain<dim> intr;
  
--- 548,559 ----
  
  	  for (index_type dp=0; dp<dst_am.num_patches(*dst_cur); ++dp)
  	  {
! 	    Domain<dim> dst_dom = dst_am.template global_domain<dim>(*dst_cur, dp);
  
  	    for (index_type sp=0; sp<src_am.num_patches(*cur); ++sp)
  	    {
! 	      Domain<dim> src_dom  = src_am.template global_domain<dim>(*cur, sp);
! 	      Domain<dim> src_ldom = src_am.template local_domain<dim>(*cur, sp);
  
  	      Domain<dim> intr;
  
*************** private:
*** 623,634 ****
  	{
  	  for (index_type dp=0; dp<dst_am.num_patches(*cur); ++dp)
  	  {
! 	    Domain<dim> dst_dom  = dst_am.template get_global_dom<dim>(*cur, dp);
! 	    Domain<dim> dst_ldom = dst_am.template get_local_dom<dim>(*cur, dp);
  	    
  	    for (index_type sp=0; sp<src_am.num_patches(*src_cur); ++sp)
  	    {
! 	      Domain<dim> src_dom = src_am.template get_global_dom<dim>(*src_cur, sp);
  
  	      Domain<dim> intr;
  
--- 623,634 ----
  	{
  	  for (index_type dp=0; dp<dst_am.num_patches(*cur); ++dp)
  	  {
! 	    Domain<dim> dst_dom  = dst_am.template global_domain<dim>(*cur, dp);
! 	    Domain<dim> dst_ldom = dst_am.template local_domain<dim>(*cur, dp);
  	    
  	    for (index_type sp=0; sp<src_am.num_patches(*src_cur); ++sp)
  	    {
! 	      Domain<dim> src_dom = src_am.template global_domain<dim>(*src_cur, sp);
  
  	      Domain<dim> intr;
  
Index: src/vsip/impl/par-chain-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-chain-assign.hpp,v
retrieving revision 1.13
diff -c -p -r1.13 par-chain-assign.hpp
*** src/vsip/impl/par-chain-assign.hpp	16 Sep 2005 22:03:20 -0000	1.13
--- src/vsip/impl/par-chain-assign.hpp	5 Dec 2005 15:42:10 -0000
*************** build_ext_array(
*** 123,129 ****
    ExtDataT**                                    array,
    sync_action_type                              sync)
  {
-   typedef typename AppMapT::subblock_iterator iterator;
    typedef typename Distributed_local_block<Block>::type local_block_type;
    typedef typename View_of_dim<Dim, T, local_block_type>::const_type
  		local_view_type;
--- 123,128 ----
*************** build_ext_array(
*** 132,149 ****
  
    // First set all subblock ext pointers to NULL.
    length_type tot_sb = am.num_subblocks();
!   for (subblock_type sb=0; sb<tot_sb; ++sb)
      array[sb] = NULL;
  
    // Then, initialize the subblocks this processor actually owns.
!   iterator cur = am.subblocks_begin(rank);
!   iterator end = am.subblocks_end(rank);
! 
!   if (cur != end)
    {
-     assert(end - cur == 1);
      local_view_type local_view = get_local_view(view);
!     array[*cur] = new ExtDataT(local_view.block(), sync);
    }
  }
  
--- 131,145 ----
  
    // First set all subblock ext pointers to NULL.
    length_type tot_sb = am.num_subblocks();
!   for (index_type sb=0; sb<tot_sb; ++sb)
      array[sb] = NULL;
  
    // Then, initialize the subblocks this processor actually owns.
!   index_type sb = am.subblock(rank);
!   if (sb != no_subblock)
    {
      local_view_type local_view = get_local_view(view);
!     array[sb] = new ExtDataT(local_view.block(), sync);
    }
  }
  
*************** cleanup_ext_array(
*** 155,161 ****
    length_type num_subblocks,
    ExtDataT**  array)
  {
!   for (subblock_type sb=0; sb<num_subblocks; ++sb)
      if (array[sb] != NULL)
        delete array[sb];
  }
--- 151,157 ----
    length_type num_subblocks,
    ExtDataT**  array)
  {
!   for (index_type sb=0; sb<num_subblocks; ++sb)
      if (array[sb] != NULL)
        delete array[sb];
  }
*************** class Chained_parallel_assign
*** 196,204 ****
  
    typedef typename Block_layout<Block1>::order_type dst_order_t;
  
-   typedef typename src_appmap_t::subblock_iterator src_sb_iterator;
-   typedef typename dst_appmap_t::subblock_iterator dst_sb_iterator;
- 
    typedef impl::Communicator::request_type request_type;
    typedef impl::Communicator::chain_type   chain_type;
  
--- 192,197 ----
*************** class Chained_parallel_assign
*** 222,228 ****
  
    struct Msg_record
    {
!     Msg_record(processor_type proc, subblock_type sb, void* data,
  	      chain_type chain)
        : proc_    (proc),
          subblock_(sb),
--- 215,221 ----
  
    struct Msg_record
    {
!     Msg_record(processor_type proc, index_type sb, void* data,
  	      chain_type chain)
        : proc_    (proc),
          subblock_(sb),
*************** class Chained_parallel_assign
*** 232,238 ****
  
    public:
      processor_type proc_;    // destination processor
!     subblock_type  subblock_;
      void*          data_;
      chain_type     chain_;
    };
--- 225,231 ----
  
    public:
      processor_type proc_;    // destination processor
!     index_type     subblock_;
      void*          data_;
      chain_type     chain_;
    };
*************** class Chained_parallel_assign
*** 251,257 ****
  
    struct Copy_record
    {
!     Copy_record(subblock_type src_sb, subblock_type dst_sb,
  	       Domain<Dim> src_dom,
  	       Domain<Dim> dst_dom)
        : src_sb_  (src_sb),
--- 244,250 ----
  
    struct Copy_record
    {
!     Copy_record(index_type src_sb, index_type dst_sb,
  	       Domain<Dim> src_dom,
  	       Domain<Dim> dst_dom)
        : src_sb_  (src_sb),
*************** class Chained_parallel_assign
*** 261,268 ****
        {}
  
    public:
!     subblock_type  src_sb_;    // destination processor
!     subblock_type  dst_sb_;
      Domain<Dim>    src_dom_;
      Domain<Dim>    dst_dom_;
    };
--- 254,261 ----
        {}
  
    public:
!     index_type     src_sb_;    // destination processor
!     index_type     dst_sb_;
      Domain<Dim>    src_dom_;
      Domain<Dim>    dst_dom_;
    };
*************** bool
*** 381,387 ****
  processor_has_block(
    MapT const&    map,
    processor_type proc,
!   subblock_type  sb)
  {
    typedef typename MapT::processor_iterator iterator;
  
--- 374,380 ----
  processor_has_block(
    MapT const&    map,
    processor_type proc,
!   index_type     sb)
  {
    typedef typename MapT::processor_iterator iterator;
  
*************** bool
*** 405,411 ****
  processor_has_block(
    Global_map<Dim> const& /*map*/,
    processor_type         proc,
!   subblock_type          sb)
  {
    assert(sb == 0);
    assert(proc < num_processors());
--- 398,404 ----
  processor_has_block(
    Global_map<Dim> const& /*map*/,
    processor_type         proc,
!   index_type             sb)
  {
    assert(sb == 0);
    assert(proc < num_processors());
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 441,487 ****
  	      << "   dsize = " << dsize << std::endl;
  #endif
  
!   // Iterate over all processors
!   for (index_type pi=0; pi<dsize; ++pi)
    {
!     // Rotate message order so processors don't all send to 0, then 1, etc
!     // (Currently does not work, it needs to take into account the
!     // number of subblocks).
  #if VSIPL_IMPL_PCA_ROTATE
!     processor_type proc = dst_am_.impl_proc((pi + offset) % dsize);
  #else
!     processor_type proc = dst_am_.impl_proc(pi);
  #endif
  
!     // Transfers that stay on this processor is handled by the copy_list.
!     if (!disable_copy && proc == rank)
!       continue;
! 
!     for (dst_sb_iterator dst_cur = dst_am_.subblocks_begin(proc);
! 	 dst_cur != dst_am_.subblocks_end(proc);
! 	 ++dst_cur)
!     {
  
!       for (src_sb_iterator cur = src_am_.subblocks_begin(rank);
! 	   cur != src_am_.subblocks_end(rank);
! 	   ++cur)
        {
  	// Check to see if destination processor already has block
! 	if (!disable_copy && processor_has_block(src_am_, proc, *cur))
  	  continue;
  
  	impl::Chain_builder builder;
! 	src_ext_type* ext = src_ext_[*cur];
  	ext->begin();
  
! 	for (index_type dp=0; dp<dst_am_.num_patches(*dst_cur); ++dp)
  	{
! 	  Domain<dim> dst_dom = dst_am_.template get_global_dom<dim>(*dst_cur, dp);
  
! 	  for (index_type sp=0; sp<src_am_.num_patches(*cur); ++sp)
  	  {
! 	    Domain<dim> src_dom  = src_am_.template get_global_dom<dim>(*cur, sp);
! 	    Domain<dim> src_ldom = src_am_.template get_local_dom<dim>(*cur, sp);
  
  	    Domain<dim> intr;
  
--- 434,479 ----
  	      << "   dsize = " << dsize << std::endl;
  #endif
  
!   index_type src_sb = src_am_.subblock(rank);
! 
!   if (src_sb != no_subblock)
    {
!     // Iterate over all processors
!     for (index_type pi=0; pi<dsize; ++pi)
!     {
!       // Rotate message order so processors don't all send to 0, then 1, etc
!       // (Currently does not work, it needs to take into account the
!       // number of subblocks).
  #if VSIPL_IMPL_PCA_ROTATE
!       processor_type proc = dst_am_.impl_proc((pi + offset) % dsize);
  #else
!       processor_type proc = dst_am_.impl_proc(pi);
  #endif
  
!       // Transfers that stay on this processor is handled by the copy_list.
!       if (!disable_copy && proc == rank)
! 	continue;
! 
!       index_type dst_sb = dst_am_.subblock(proc);
  
!       if (dst_sb != no_subblock)
        {
  	// Check to see if destination processor already has block
! 	if (!disable_copy && processor_has_block(src_am_, proc, src_sb))
  	  continue;
  
  	impl::Chain_builder builder;
! 	src_ext_type* ext = src_ext_[src_sb];
  	ext->begin();
  
! 	for (index_type dp=0; dp<dst_am_.num_patches(dst_sb); ++dp)
  	{
! 	  Domain<dim> dst_dom = dst_am_.template global_domain<dim>(dst_sb, dp);
  
! 	  for (index_type sp=0; sp<src_am_.num_patches(src_sb); ++sp)
  	  {
! 	    Domain<dim> src_dom  = src_am_.template global_domain<dim>(src_sb, sp);
! 	    Domain<dim> src_ldom = src_am_.template local_domain<dim>(src_sb, sp);
  
  	    Domain<dim> intr;
  
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 495,503 ****
  
  #if VSIP_IMPL_PCA_VERBOSE
  	      std::cout << "(" << rank << ") send "
! 			<< rank << "/" << *cur << "/" << sp
  			<< " -> "
! 			<< proc << "/" << *dst_cur << "/" << dp
  			<< " src: " << src_dom
  			<< " dst: " << dst_dom
  			<< " intr: " << intr
--- 487,495 ----
  
  #if VSIP_IMPL_PCA_VERBOSE
  	      std::cout << "(" << rank << ") send "
! 			<< rank << "/" << src_sb << "/" << sp
  			<< " -> "
! 			<< proc << "/" << dst_sb << "/" << dp
  			<< " src: " << src_dom
  			<< " dst: " << dst_dom
  			<< " intr: " << intr
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 509,515 ****
  	  }
  	}
  	if (!builder.is_empty())
! 	  send_list.push_back(Msg_record(proc, *cur, ext->data(),
  					builder.get_chain()));
  	ext->end();
        }
--- 501,507 ----
  	  }
  	}
  	if (!builder.is_empty())
! 	  send_list.push_back(Msg_record(proc, src_sb, ext->data(),
  					builder.get_chain()));
  	ext->end();
        }
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 544,554 ****
  	      << "  ssize = " << ssize << std::endl;
  #endif
  
!   for (dst_sb_iterator cur = dst_am_.subblocks_begin(rank);
!        cur != dst_am_.subblocks_end(rank);
!        ++cur)
    {
!     dst_ext_type* ext = dst_ext_[*cur];
      ext->begin();
        
      // Iterate over all sending processors
--- 536,546 ----
  	      << "  ssize = " << ssize << std::endl;
  #endif
  
!   index_type dst_sb = dst_am_.subblock(rank);
! 
!   if (dst_sb != no_subblock)
    {
!     dst_ext_type* ext = dst_ext_[dst_sb];
      ext->begin();
        
      // Iterate over all sending processors
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 566,587 ****
        
        impl::Chain_builder builder;
        
!       for (src_sb_iterator src_cur = src_am_.subblocks_begin(proc);
! 	   src_cur != src_am_.subblocks_end(proc);
! 	   ++src_cur)
        {
  	// Check to see if destination processor already has block
! 	if (!disable_copy && processor_has_block(src_am_, rank, *src_cur))
  	  continue;
  
! 	for (index_type dp=0; dp<dst_am_.num_patches(*cur); ++dp)
  	{
! 	  Domain<dim> dst_dom  = dst_am_.template get_global_dom<dim>(*cur, dp);
! 	  Domain<dim> dst_ldom = dst_am_.template get_local_dom<dim>(*cur, dp);
  	  
! 	  for (index_type sp=0; sp<src_am_.num_patches(*src_cur); ++sp)
  	  {
! 	    Domain<dim> src_dom = src_am_.template get_global_dom<dim>(*src_cur, sp);
  	    
  	    Domain<dim> intr;
  	    
--- 558,579 ----
        
        impl::Chain_builder builder;
        
!       index_type src_sb = src_am_.subblock(proc);
! 
!       if (src_sb != no_subblock)
        {
  	// Check to see if destination processor already has block
! 	if (!disable_copy && processor_has_block(src_am_, rank, src_sb))
  	  continue;
  
! 	for (index_type dp=0; dp<dst_am_.num_patches(dst_sb); ++dp)
  	{
! 	  Domain<dim> dst_dom  = dst_am_.template global_domain<dim>(dst_sb, dp);
! 	  Domain<dim> dst_ldom = dst_am_.template local_domain<dim>(dst_sb, dp);
  	  
! 	  for (index_type sp=0; sp<src_am_.num_patches(src_sb); ++sp)
  	  {
! 	    Domain<dim> src_dom = src_am_.template global_domain<dim>(src_sb, sp);
  	    
  	    Domain<dim> intr;
  	    
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 595,603 ****
  	      
  #if VSIP_IMPL_PCA_VERBOSE
  	      std::cout << "(" << rank << ") recv "
! 			<< rank << "/" << *cur << "/" << dp
  			<< " <- "
! 			<< proc << "/" << *src_cur << "/" << sp
  			<< " dst: " << dst_dom
  			<< " src: " << src_dom
  			<< " intr: " << intr
--- 587,595 ----
  	      
  #if VSIP_IMPL_PCA_VERBOSE
  	      std::cout << "(" << rank << ") recv "
! 			<< rank << "/" << dst_sb << "/" << dp
  			<< " <- "
! 			<< proc << "/" << src_sb << "/" << sp
  			<< " dst: " << dst_dom
  			<< " src: " << src_dom
  			<< " intr: " << intr
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 610,616 ****
  	}
        }
        if (!builder.is_empty())
! 	recv_list.push_back(Msg_record(proc, *cur, ext->data(),
  				      builder.get_chain()));
      }
      ext->end();
--- 602,608 ----
  	}
        }
        if (!builder.is_empty())
! 	recv_list.push_back(Msg_record(proc, dst_sb, ext->data(),
  				      builder.get_chain()));
      }
      ext->end();
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 636,665 ****
  	    << "   num_procs = " << src_am_.impl_num_procs() << std::endl;
  #endif
  
!   for (dst_sb_iterator dst_cur = dst_am_.subblocks_begin(rank);
!        dst_cur != dst_am_.subblocks_end(rank);
!        ++dst_cur)
    {
  
!     for (src_sb_iterator cur = src_am_.subblocks_begin(rank);
! 	 cur != src_am_.subblocks_end(rank);
! 	 ++cur)
      {
!       for (index_type dp=0; dp<dst_am_.num_patches(*dst_cur); ++dp)
        {
! 	Domain<dim> dst_dom  = dst_am_.template get_global_dom<dim>(*dst_cur, dp);
! 	Domain<dim> dst_ldom = dst_am_.template get_local_dom<dim> (*dst_cur, dp);
  
! 	for (index_type sp=0; sp<src_am_.num_patches(*cur); ++sp)
  	{
! 	  Domain<dim> src_dom  = src_am_.template get_global_dom<dim>(*cur, sp);
! 	  Domain<dim> src_ldom = src_am_.template get_local_dom<dim> (*cur, sp);
  
  	  Domain<dim> intr;
  
  #if VSIP_IMPL_PCA_VERBOSE
! //	  std::cout << " - dst " << *dst_cur << "/" << dp << std::endl
! //		    << "   src " << *cur     << "/" << sp << std::endl
  //	    ;
  #endif
  
--- 628,655 ----
  	    << "   num_procs = " << src_am_.impl_num_procs() << std::endl;
  #endif
  
!   index_type dst_sb = dst_am_.subblock(rank);
!   if (dst_sb != no_subblock)
    {
  
!     index_type src_sb = src_am_.subblock(rank);
!     if (src_sb != no_subblock)
      {
!       for (index_type dp=0; dp<dst_am_.num_patches(dst_sb); ++dp)
        {
! 	Domain<dim> dst_dom  = dst_am_.template global_domain<dim>(dst_sb, dp);
! 	Domain<dim> dst_ldom = dst_am_.template local_domain<dim> (dst_sb, dp);
  
! 	for (index_type sp=0; sp<src_am_.num_patches(src_sb); ++sp)
  	{
! 	  Domain<dim> src_dom  = src_am_.template global_domain<dim>(src_sb, sp);
! 	  Domain<dim> src_ldom = src_am_.template local_domain<dim> (src_sb, sp);
  
  	  Domain<dim> intr;
  
  #if VSIP_IMPL_PCA_VERBOSE
! //	  std::cout << " - dst " << dst_sb << "/" << dp << std::endl
! //		    << "   src " << src_sb     << "/" << sp << std::endl
  //	    ;
  #endif
  
*************** Chained_parallel_assign<Dim, T1, T2, Blo
*** 672,683 ****
  	    Domain<dim> recv_dom    = domain(first(dst_ldom) + recv_offset,
  					     extent_old(intr));
  
! 	    copy_list.push_back(Copy_record(*cur, *dst_cur, send_dom, recv_dom));
  
  #if VSIP_IMPL_PCA_VERBOSE
! 	    std::cout << "copy src: " << *cur << "/" << sp
  		      << " " << send_dom
! 		      << "  dst: " << *dst_cur << "/" << dp
  		      << " " << recv_dom
  		      << std::endl;
  #endif
--- 662,673 ----
  	    Domain<dim> recv_dom    = domain(first(dst_ldom) + recv_offset,
  					     extent_old(intr));
  
! 	    copy_list.push_back(Copy_record(src_sb, dst_sb, send_dom, recv_dom));
  
  #if VSIP_IMPL_PCA_VERBOSE
! 	    std::cout << "copy src: " << src_sb << "/" << sp
  		      << " " << send_dom
! 		      << "  dst: " << dst_sb << "/" << dp
  		      << " " << recv_dom
  		      << std::endl;
  #endif
Index: src/vsip/impl/par-expr.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-expr.hpp,v
retrieving revision 1.6
diff -c -p -r1.6 par-expr.hpp
*** src/vsip/impl/par-expr.hpp	16 Sep 2005 22:03:20 -0000	1.6
--- src/vsip/impl/par-expr.hpp	5 Dec 2005 15:42:11 -0000
*************** class Par_expr
*** 208,214 ****
    typedef typename SrcBlock::value_type value2_type;
  
    typedef typename DstBlock::map_type   dst_map_type;
-   typedef typename dst_map_type::subblock_iterator subblock_iterator;
    typedef typename Distributed_local_block<DstBlock>::type dst_lblock_type;
  
    typedef typename
--- 208,213 ----
*************** public:
*** 241,247 ****
  
      DstBlock&      dst_block = dst_.block();
  
!     if (dst_block.map().impl_subblock() != no_subblock)
      {
        dst_lview_type dst_lview = get_local_view(dst_);
        src_lview_type src_lview = get_local_view(src_remap_);
--- 240,246 ----
  
      DstBlock&      dst_block = dst_.block();
  
!     if (dst_block.map().subblock() != no_subblock)
      {
        dst_lview_type dst_lview = get_local_view(dst_);
        src_lview_type src_lview = get_local_view(src_remap_);
*************** par_expr_simple(
*** 423,429 ****
  {
    VSIP_IMPL_STATIC_ASSERT((View1<T1, Block1>::dim == View2<T2, Block2>::dim));
    typedef typename Block1::map_type         map_t;
-   typedef typename map_t::subblock_iterator subblock_iterator;
  
    typedef typename Distributed_local_block<Block1>::type dst_lblock_type;
    typedef typename Distributed_local_block<Block2>::type src_lblock_type;
--- 422,427 ----
*************** par_expr_simple(
*** 439,445 ****
    // Iterator through subblocks, performing assignment.  Not necessary
    // iterate through patches since blocks have the same distribution.
  
!   if (block.map().impl_subblock() != no_subblock)
    {
      View1<T1, dst_lblock_type> dst_lview = get_local_view(dst);
      View2<T2, src_lblock_type> src_lview = get_local_view(src);
--- 437,443 ----
    // Iterator through subblocks, performing assignment.  Not necessary
    // iterate through patches since blocks have the same distribution.
  
!   if (block.map().subblock() != no_subblock)
    {
      View1<T1, dst_lblock_type> dst_lview = get_local_view(dst);
      View2<T2, src_lblock_type> src_lview = get_local_view(src);
Index: src/vsip/impl/par-foreach.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-foreach.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 par-foreach.hpp
*** src/vsip/impl/par-foreach.hpp	26 Sep 2005 20:11:05 -0000	1.1
--- src/vsip/impl/par-foreach.hpp	5 Dec 2005 15:42:11 -0000
***************
*** 21,26 ****
--- 21,27 ----
  #include <vsip/impl/distributed-block.hpp>
  #include <vsip/impl/point.hpp>
  #include <vsip/impl/point-fcn.hpp>
+ #include <vsip/impl/par-util.hpp>
  
  
  
*************** namespace vsip
*** 34,44 ****
  namespace impl
  {
  
! template <typename Order>
  struct subview;
  
  template <>
! struct subview<tuple<0, 1, 2> >
  {
    template <typename T,
  	    typename BlockT>
--- 35,94 ----
  namespace impl
  {
  
! template <dimension_type Dim,
! 	  typename       Order>
  struct subview;
  
  template <>
! struct subview<2, tuple<0, 1, 2> >
! {
!   template <typename T,
! 	    typename BlockT>
!   static
!   typename Matrix<T, BlockT>::row_type
!   vector(Matrix<T, BlockT> view, index_type i)
!   {
!     return view.row(i);
!   }
! 
!   template <typename T,
! 	    typename BlockT>
!   static
!   typename const_Matrix<T, BlockT>::row_type
!   vector(const_Matrix<T, BlockT> view, index_type i)
!   {
!     return view.row(i);
!   }
! };
! 
! 
! 
! template <>
! struct subview<2, tuple<1, 0, 2> >
! {
!   template <typename T,
! 	    typename BlockT>
!   static
!   typename Matrix<T, BlockT>::col_type
!   vector(Matrix<T, BlockT> view, index_type i)
!   {
!     return view.col(i);
!   }
! 
!   template <typename T,
! 	    typename BlockT>
!   static
!   typename const_Matrix<T, BlockT>::col_type
!   vector(const_Matrix<T, BlockT> view, index_type i)
!   {
!     return view.col(i);
!   }
! };
! 
! 
! 
! template <>
! struct subview<3, tuple<0, 1, 2> >
  {
    template <typename T,
  	    typename BlockT>
*************** struct subview<tuple<0, 1, 2> >
*** 83,89 ****
  
  
  template <>
! struct subview<tuple<0, 2, 1> >
  {
    template <typename T,
  	    typename BlockT>
--- 133,139 ----
  
  
  template <>
! struct subview<3, tuple<0, 2, 1> >
  {
    template <typename T,
  	    typename BlockT>
*************** struct subview<tuple<0, 2, 1> >
*** 130,136 ****
  
  
  template <>
! struct subview<tuple<1, 0, 2> >
  {
    template <typename T,
  	    typename BlockT>
--- 180,186 ----
  
  
  template <>
! struct subview<3, tuple<1, 0, 2> >
  {
    template <typename T,
  	    typename BlockT>
*************** struct subview<tuple<1, 0, 2> >
*** 175,181 ****
  
  
  template <>
! struct subview<tuple<1, 2, 0> >
  {
    template <typename T,
  	    typename BlockT>
--- 225,231 ----
  
  
  template <>
! struct subview<3, tuple<1, 2, 0> >
  {
    template <typename T,
  	    typename BlockT>
*************** struct subview<tuple<1, 2, 0> >
*** 220,226 ****
  
  
  template <>
! struct subview<tuple<2, 0, 1> >
  {
    template <typename T,
  	    typename BlockT>
--- 270,276 ----
  
  
  template <>
! struct subview<3, tuple<2, 0, 1> >
  {
    template <typename T,
  	    typename BlockT>
*************** struct subview<tuple<2, 0, 1> >
*** 267,273 ****
  
  
  template <>
! struct subview<tuple<2, 1, 0> >
  {
    template <typename T,
  	    typename BlockT>
--- 317,323 ----
  
  
  template <>
! struct subview<3, tuple<2, 1, 0> >
  {
    template <typename T,
  	    typename BlockT>
*************** template <typename Order,
*** 326,337 ****
  	  typename InView,
  	  typename OutView,
  	  typename FuncT>
  struct Foreach_vector<3, Order, InView, OutView, FuncT>
  {
    static void exec(
      InView  in,
!     OutView out,
!     FuncT&  fcn)
    {
      typedef typename OutView::block_type::map_type map_t;
  
--- 376,460 ----
  	  typename InView,
  	  typename OutView,
  	  typename FuncT>
+ struct Foreach_vector<2, Order, InView, OutView, FuncT>
+ {
+   static void exec(
+     FuncT&  fcn,
+     InView  in,
+     OutView out)
+   {
+     typedef typename OutView::block_type::map_type map_t;
+ 
+     static dimension_type const Dim0 = Order::impl_dim0;
+     static dimension_type const Dim1 = Order::impl_dim1;
+     // static dimension_type const Dim2 = Order::impl_dim2;
+ 
+     map_t const& map = out.block().map();
+     Domain<2>    dom = global_domain(out);
+ 
+     if (map.num_subblocks(Dim1) != 1)
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
+       {
+ 	index_type global_i = dom[Dim0].impl_nth(i);
+ 	  
+ 	fcn(subview<2, Order>::vector(l_in, i),
+ 	    subview<2, Order>::vector(l_out, i),
+ 	    Index<1>(global_i));
+       }
+     }
+     else
+     {
+       typedef typename InView::value_type             value_type;
+       typedef typename Block_layout<typename InView::block_type>::order_type
+ 	                                              order_type;
+       typedef Dense<2, value_type, order_type, map_t> block_type;
+ 
+       Matrix<value_type, block_type> in_copy(in.size(0), in.size(1), map);
+ 
+       // Rearrange data.
+       in_copy = in;
+ 
+       // Force view to be const.
+       const_Matrix<value_type, block_type> in_const = in_copy;
+ 
+       typename InView::local_type  l_in  = get_local_view(in_const);
+       typename OutView::local_type l_out = get_local_view(out);
+ 
+       for (index_type i=0; i<l_out.size(Dim0); ++i)
+       {
+ 	index_type global_i = dom[Dim0].impl_nth(i);
+ 	  
+ 	fcn(subview<2, Order>::vector(l_in, i),
+ 	    subview<2, Order>::vector(l_out, i),
+ 	    Index<1>(global_i));
+       }
+     }
+   }
+ };
+ 
+ 
+ 
+ template <typename Order,
+ 	  typename InView,
+ 	  typename OutView,
+ 	  typename FuncT>
  struct Foreach_vector<3, Order, InView, OutView, FuncT>
  {
    static void exec(
+     FuncT&  fcn,
      InView  in,
!     OutView out)
    {
      typedef typename OutView::block_type::map_type map_t;
  
*************** struct Foreach_vector<3, Order, InView, 
*** 340,346 ****
      static dimension_type const Dim2 = Order::impl_dim2;
  
      map_t const& map = out.block().map();
!     Domain<3>    dom = impl::my_global_dom(out);
  
      if (map.num_subblocks(Dim2) != 1)
      {
--- 463,469 ----
      static dimension_type const Dim2 = Order::impl_dim2;
  
      map_t const& map = out.block().map();
!     Domain<3>    dom = global_domain(out);
  
      if (map.num_subblocks(Dim2) != 1)
      {
*************** struct Foreach_vector<3, Order, InView, 
*** 360,369 ****
  	  index_type global_i = dom[Dim0].impl_nth(i);
  	  index_type global_j = dom[Dim1].impl_nth(j);
  	  
! 	  fcn(subview<Order>::vector(l_in, i, j),
! 	      subview<Order>::vector(l_out, i, j),
! 	      subview<Order>::first(global_i, global_j),
! 	      subview<Order>::second(global_i, global_j));
  	}
      }
      else
--- 483,492 ----
  	  index_type global_i = dom[Dim0].impl_nth(i);
  	  index_type global_j = dom[Dim1].impl_nth(j);
  	  
! 	  fcn(subview<3, Order>::vector(l_in, i, j),
! 	      subview<3, Order>::vector(l_out, i, j),
! 	      subview<3, Order>::first(global_i, global_j),
! 	      subview<3, Order>::second(global_i, global_j));
  	}
      }
      else
*************** struct Foreach_vector<3, Order, InView, 
*** 391,414 ****
  	  index_type global_i = dom[Dim0].impl_nth(i);
  	  index_type global_j = dom[Dim1].impl_nth(j);
  	  
! 	  fcn(subview<Order>::vector(l_in, i, j),
! 	      subview<Order>::vector(l_out, i, j),
! 	      subview<Order>::first(global_i, global_j),
! 	      subview<Order>::second(global_i, global_j));
  	}
      }
    }
  };
  
! template <dimension_type Dim>
  struct Foreach_order;
  
! template <> struct Foreach_order<0> { typedef tuple<1, 2, 0> type; };
! template <> struct Foreach_order<1> { typedef tuple<0, 2, 1> type; };
! template <> struct Foreach_order<2> { typedef tuple<0, 1, 2> type; };
  
  } // namespace vsip::impl
  
  template <dimension_type                      Dim,
  	  template <typename, typename> class View1,
  	  template <typename, typename> class View2,
--- 514,542 ----
  	  index_type global_i = dom[Dim0].impl_nth(i);
  	  index_type global_j = dom[Dim1].impl_nth(j);
  	  
! 	  fcn(subview<3, Order>::vector(l_in, i, j),
! 	      subview<3, Order>::vector(l_out, i, j),
! 	      subview<3, Order>::first(global_i, global_j),
! 	      subview<3, Order>::second(global_i, global_j));
  	}
      }
    }
  };
  
! template <dimension_type Dim1, dimension_type Dim>
  struct Foreach_order;
  
! template <> struct Foreach_order<3, 0> { typedef tuple<1, 2, 0> type; };
! template <> struct Foreach_order<3, 1> { typedef tuple<0, 2, 1> type; };
! template <> struct Foreach_order<3, 2> { typedef tuple<0, 1, 2> type; };
! 
! template <> struct Foreach_order<2, 0> { typedef tuple<1, 0, 2> type; };
! template <> struct Foreach_order<2, 1> { typedef tuple<0, 1, 2> type; };
  
  } // namespace vsip::impl
  
+ 
+ 
  template <dimension_type                      Dim,
  	  template <typename, typename> class View1,
  	  template <typename, typename> class View2,
*************** template <dimension_type                
*** 419,434 ****
  	  typename                            FuncT>
  void
  foreach_vector(
    View1<T1, Block1> in,
!   View2<T2, Block2> out,
!   FuncT&            fcn)
  {
    dimension_type const dim = View1<T1, Block1>::dim;
  
!   impl::Foreach_vector<dim, typename impl::Foreach_order<Dim>::type,
      View1<T1, Block1>,
      View2<T2, Block2>,
!     FuncT>::exec(in, out, fcn);
  }
  
  } // namespace vsip
--- 547,602 ----
  	  typename                            FuncT>
  void
  foreach_vector(
+   FuncT&            fcn,
    View1<T1, Block1> in,
!   View2<T2, Block2> out)
  {
    dimension_type const dim = View1<T1, Block1>::dim;
  
!   impl::Foreach_vector<dim, typename impl::Foreach_order<dim, Dim>::type,
      View1<T1, Block1>,
      View2<T2, Block2>,
!     FuncT>::exec(fcn, in, out);
! }
! 
! 
! 
! template <dimension_type                      Dim,
! 	  template <typename, typename> class View1,
! 	  typename                            T1,
! 	  typename                            Block1,
! 	  typename                            FuncT>
! void
! foreach_vector(
!   FuncT&            fcn,
!   View1<T1, Block1> inout)
! {
!   dimension_type const dim = View1<T1, Block1>::dim;
! 
!   impl::Foreach_vector<dim, typename impl::Foreach_order<dim, Dim>::type,
!     View1<T1, Block1>,
!     View1<T1, Block1>,
!     FuncT>::exec(fcn, inout, inout);
! }
! 
! 
! 
! template <typename                            TraverseOrder,
! 	  template <typename, typename> class View1,
! 	  typename                            T1,
! 	  typename                            Block1,
! 	  typename                            FuncT>
! void
! foreach_vector(
!   FuncT&            fcn,
!   View1<T1, Block1> inout)
! {
!   dimension_type const dim = View1<T1, Block1>::dim;
! 
!   impl::Foreach_vector<dim, TraverseOrder,
!     View1<T1, Block1>,
!     View1<T1, Block1>,
!     FuncT>::exec(fcn, inout, inout);
  }
  
  } // namespace vsip
Index: src/vsip/impl/par-util.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/par-util.hpp,v
retrieving revision 1.5
diff -c -p -r1.5 par-util.hpp
*** src/vsip/impl/par-util.hpp	16 Sep 2005 21:51:08 -0000	1.5
--- src/vsip/impl/par-util.hpp	5 Dec 2005 15:42:11 -0000
*************** foreach_patch(
*** 62,78 ****
    BlockT&      block = view.block();
    map_t const& am    = view.block().map();
  
!   subblock_iterator psb = block.subblocks_begin();
!   subblock_iterator end = block.subblocks_end();
  
!   for (; psb != end; ++psb)
    {
!     ViewT<T, local_block_t> local_view = get_local_view(view, *psb);
  
!     for (index_type p=0; p<am.num_patches(*psb); ++p)
      {
!       Domain<dim> ldom = am.template get_local_dom<dim>(*psb, p);
!       Domain<dim> gdom = am.template get_global_dom<dim>(*psb, p);
  
        fcn(local_view.get(ldom), gdom);
      }
--- 62,77 ----
    BlockT&      block = view.block();
    map_t const& am    = view.block().map();
  
!   index_type sb = am.subblock();
  
!   if (sb != no_subblock)
    {
!     ViewT<T, local_block_t> local_view = get_local_view(view, sb);
  
!     for (index_type p=0; p<am.num_patches(sb); ++p)
      {
!       Domain<dim> ldom = am.template local_domain<dim>(sb, p);
!       Domain<dim> gdom = am.template global_domain<dim>(sb, p);
  
        fcn(local_view.get(ldom), gdom);
      }
*************** namespace detail
*** 88,97 ****
  
  template <typename ViewT>
  inline Domain<ViewT::dim>
! subblock_dom(
    ViewT const&        view,
    Local_map const&    /*map*/,
!   subblock_type       /*sb*/)
  {
    return block_domain<ViewT::dim>(view.block());
  }
--- 87,96 ----
  
  template <typename ViewT>
  inline Domain<ViewT::dim>
! subblock_domain(
    ViewT const&        view,
    Local_map const&    /*map*/,
!   index_type          /*sb*/)
  {
    return block_domain<ViewT::dim>(view.block());
  }
*************** subblock_dom(
*** 99,110 ****
  template <typename ViewT,
  	  typename MapT>
  inline Domain<ViewT::dim>
! subblock_dom(
    ViewT const&     /*view*/,
    MapT const&      map,
!   subblock_type    sb)
  {
!   return map.template get_subblock_dom<ViewT::dim>(sb);
  }
  
  
--- 98,109 ----
  template <typename ViewT,
  	  typename MapT>
  inline Domain<ViewT::dim>
! subblock_domain(
    ViewT const&     /*view*/,
    MapT const&      map,
!   index_type       sb)
  {
!   return map.template subblock_domain<ViewT::dim>(sb);
  }
  
  
*************** subblock_dom(
*** 113,122 ****
  
  template <typename ViewT>
  inline Domain<ViewT::dim>
! local_dom(
    ViewT const& view,
    Local_map const&    /*map*/,
!   subblock_type       /*sb*/,
    index_type          /*p*/)
  {
    return block_domain<ViewT::dim>(view.block());
--- 112,121 ----
  
  template <typename ViewT>
  inline Domain<ViewT::dim>
! local_domain(
    ViewT const& view,
    Local_map const&    /*map*/,
!   index_type          /*sb*/,
    index_type          /*p*/)
  {
    return block_domain<ViewT::dim>(view.block());
*************** local_dom(
*** 125,137 ****
  template <typename ViewT,
  	  typename MapT>
  inline Domain<ViewT::dim>
! local_dom(
    ViewT const&     /*view*/,
    MapT const&      map,
!   subblock_type    sb,
    index_type       p)
  {
!   return map.template get_local_dom<ViewT::dim>(sb, p);
  }
  
  
--- 124,136 ----
  template <typename ViewT,
  	  typename MapT>
  inline Domain<ViewT::dim>
! local_domain(
    ViewT const&     /*view*/,
    MapT const&      map,
!   index_type       sb,
    index_type       p)
  {
!   return map.template local_domain<ViewT::dim>(sb, p);
  }
  
  
*************** local_dom(
*** 140,149 ****
  
  template <typename ViewT>
  inline Domain<ViewT::dim>
! global_dom(
    ViewT const& view,
    Local_map const&    /*map*/,
!   subblock_type       /*sb*/,
    index_type          /*p*/)
  {
    return block_domain<ViewT::dim>(view.block());
--- 139,148 ----
  
  template <typename ViewT>
  inline Domain<ViewT::dim>
! global_domain(
    ViewT const& view,
    Local_map const&    /*map*/,
!   index_type          /*sb*/,
    index_type          /*p*/)
  {
    return block_domain<ViewT::dim>(view.block());
*************** global_dom(
*** 152,164 ****
  template <typename ViewT,
  	  typename MapT>
  inline Domain<ViewT::dim>
! global_dom(
    ViewT const&     /*view*/,
    MapT const&      map,
!   subblock_type    sb,
    index_type       p)
  {
!   return map.template get_global_dom<ViewT::dim>(sb, p);
  }
  
  } // namespace detail
--- 151,163 ----
  template <typename ViewT,
  	  typename MapT>
  inline Domain<ViewT::dim>
! global_domain(
    ViewT const&     /*view*/,
    MapT const&      map,
!   index_type       sb,
    index_type       p)
  {
!   return map.template global_domain<ViewT::dim>(sb, p);
  }
  
  } // namespace detail
*************** global_dom(
*** 167,247 ****
  
  template <typename ViewT>
  Domain<ViewT::dim>
! subblock_dom(
    ViewT const&  view,
!   subblock_type sb)
  {
!   return detail::subblock_dom(view, view.block().map(), sb);
  }
  
  template <typename ViewT>
  Domain<ViewT::dim>
! local_dom(
    ViewT const&  view,
!   subblock_type sb,
    index_type    p)
  {
!   return detail::local_dom(view, view.block().map(), sb, p);
  }
  
  template <typename ViewT>
  Domain<ViewT::dim>
! global_dom(
    ViewT const&  view,
!   subblock_type sb,
    index_type    p)
  {
!   return detail::global_dom(view, view.block().map(), sb, p);
  }
  
  
  
  template <typename ViewT>
  length_type
! my_patches(
!   ViewT const&  view)
  {
!   return view.block().map().num_patches(view.block().map().impl_subblock());
  }
  
  
  
  template <typename ViewT>
! Domain<ViewT::dim>
! my_subblock_dom(
    ViewT const&  view)
  {
!   return detail::subblock_dom(view, view.block().map(),
! 			      view.block().map().impl_subblock());
  }
  
  
  
  template <typename ViewT>
! Domain<ViewT::dim>
! my_local_dom(
!   ViewT const&  view,
!   index_type    p=0)
  {
!   return detail::local_dom(view, view.block().map(),
! 			   view.block().map().impl_subblock(),
! 			   p);
  }
  
  template <typename ViewT>
! Domain<ViewT::dim>
! my_global_dom(
!   ViewT const&  view,
!   index_type    p=0)
! {
!   return detail::global_dom(view, view.block().map(), 
! 			    view.block().map().impl_subblock(),
! 			    p);
  }
  
  
  
- 
  // Evaluate a function object foreach local element of a distributed view.
  
  // Requires:
--- 166,283 ----
  
  template <typename ViewT>
  Domain<ViewT::dim>
! subblock_domain(
    ViewT const&  view,
!   index_type    sb)
! {
!   return detail::subblock_domain(view, view.block().map(), sb);
! }
! 
! template <typename ViewT>
! Domain<ViewT::dim>
! subblock_domain(
!   ViewT const&  view)
  {
!   return detail::subblock_domain(view, view.block().map(),
! 			      view.block().map().subblock());
  }
  
+ 
+ 
  template <typename ViewT>
  Domain<ViewT::dim>
! local_domain(
    ViewT const&  view,
!   index_type    sb,
    index_type    p)
  {
!   return detail::local_domain(view, view.block().map(), sb, p);
  }
  
  template <typename ViewT>
  Domain<ViewT::dim>
! local_domain(
    ViewT const&  view,
!   index_type    p=0)
! {
!   return detail::local_domain(view, view.block().map(),
! 			      view.block().map().subblock(),
! 			      p);
! }
! 
! 
! 
! template <typename ViewT>
! Domain<ViewT::dim>
! global_domain(
!   ViewT const&  view,
!   index_type    sb,
    index_type    p)
  {
!   return detail::global_domain(view, view.block().map(), sb, p);
! }
! 
! template <typename ViewT>
! Domain<ViewT::dim>
! global_domain(
!   ViewT const&  view,
!   index_type    p=0)
! {
!   return detail::global_domain(view, view.block().map(), 
! 			       view.block().map().subblock(),
! 			       p);
  }
  
  
  
  template <typename ViewT>
  length_type
! num_patches(
!   ViewT const&  view,
!   index_type    sb)
  {
!   return view.block().map().num_patches(sb);
  }
  
  
  
  template <typename ViewT>
! length_type
! num_patches(
    ViewT const&  view)
  {
!   return view.block().map().num_patches(view.block().map().subblock());
  }
  
  
  
  template <typename ViewT>
! inline
! index_type
! global_from_local_index(
!   ViewT const&   view,
!   dimension_type dim,
!   index_type     sb,
!   index_type     idx)
  {
!   return view.block().map().global_from_local_index(dim, sb, idx);
  }
  
  template <typename ViewT>
! inline
! index_type
! global_from_local_index(
!   ViewT const&   view,
!   dimension_type dim,
!   index_type     idx)
! {
!   return view.block().map().global_from_local_index(dim,
! 						    view.block().subblock(),
! 						    idx);
  }
  
  
  
  // Evaluate a function object foreach local element of a distributed view.
  
  // Requires:
*************** foreach_point(
*** 266,280 ****
  
    map_t const& map = view.block().map();
  
!   subblock_type sb = map.impl_subblock();
    if (sb != no_subblock)
    {
      typename ViewT::local_type local_view = get_local_view(view);
  
      for (index_type p=0; p<map.num_patches(sb); ++p)
      {
!       Domain<dim> ldom = local_dom(view, sb, p);
!       Domain<dim> gdom = global_dom(view, sb, p);
  
        for (Point<dim> idx; valid(extent_old(ldom), idx); next(extent_old(ldom), idx))
        {
--- 302,316 ----
  
    map_t const& map = view.block().map();
  
!   index_type sb = map.subblock();
    if (sb != no_subblock)
    {
      typename ViewT::local_type local_view = get_local_view(view);
  
      for (index_type p=0; p<map.num_patches(sb); ++p)
      {
!       Domain<dim> ldom = local_domain(view, sb, p);
!       Domain<dim> gdom = global_domain(view, sb, p);
  
        for (Point<dim> idx; valid(extent_old(ldom), idx); next(extent_old(ldom), idx))
        {
Index: src/vsip/impl/setup-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/setup-assign.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 setup-assign.hpp
*** src/vsip/impl/setup-assign.hpp	16 Sep 2005 21:51:08 -0000	1.1
--- src/vsip/impl/setup-assign.hpp	5 Dec 2005 15:42:11 -0000
*************** public:
*** 209,215 ****
      else if (impl::Is_par_same_map<map1_type, Block2>::value(dst.block().map(),
  						       src.block()))
      {
!       if (dst.block().map().impl_subblock() != no_subblock)
        {
  	typedef typename impl::Distributed_local_block<Block1>::type dst_lblock_type;
  	typedef typename impl::Distributed_local_block<Block2>::type src_lblock_type;
--- 209,215 ----
      else if (impl::Is_par_same_map<map1_type, Block2>::value(dst.block().map(),
  						       src.block()))
      {
!       if (dst.block().map().subblock() != no_subblock)
        {
  	typedef typename impl::Distributed_local_block<Block1>::type dst_lblock_type;
  	typedef typename impl::Distributed_local_block<Block2>::type src_lblock_type;
Index: src/vsip/impl/subblock.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/subblock.hpp,v
retrieving revision 1.36
diff -c -p -r1.36 subblock.hpp
*** src/vsip/impl/subblock.hpp	2 Nov 2005 18:44:04 -0000	1.36
--- src/vsip/impl/subblock.hpp	5 Dec 2005 15:42:11 -0000
*************** get_local_block(
*** 1269,1275 ****
  
    dimension_type const dim = Subset_block<Block>::dim;
  
!   subblock_type sb = block.map().lookup_index(block.map().impl_rank());
  
    Domain<dim> dom = block.impl_block().map().
      impl_local_from_global_domain(sb,
--- 1269,1275 ----
  
    dimension_type const dim = Subset_block<Block>::dim;
  
!   index_type sb = block.map().lookup_index(block.map().impl_rank());
  
    Domain<dim> dom = block.impl_block().map().
      impl_local_from_global_domain(sb,
*************** template <typename Block>
*** 1324,1330 ****
  void
  assert_local(
    Subset_block<Block> const& /*block*/,
!   subblock_type              /*sb*/)
  {
  }
  
--- 1324,1330 ----
  void
  assert_local(
    Subset_block<Block> const& /*block*/,
!   index_type                 /*sb*/)
  {
  }
  
*************** template <typename       Block,
*** 1335,1341 ****
  void
  assert_local(
    Sliced_block<Block, D> const& /*block*/,
!   subblock_type                 /*sb*/)
  {
  }
  
--- 1335,1341 ----
  void
  assert_local(
    Sliced_block<Block, D> const& /*block*/,
!   index_type                    /*sb*/)
  {
  }
  
*************** template <typename       Block,
*** 1347,1353 ****
  void
  assert_local(
    Sliced2_block<Block, D1, D2> const& /*block*/,
!   subblock_type                       /*sb*/)
  {
  }
  
--- 1347,1353 ----
  void
  assert_local(
    Sliced2_block<Block, D1, D2> const& /*block*/,
!   index_type                          /*sb*/)
  {
  }
  
Index: src/vsip/impl/view_traits.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/view_traits.hpp,v
retrieving revision 1.10
diff -c -p -r1.10 view_traits.hpp
*** src/vsip/impl/view_traits.hpp	27 Sep 2005 22:44:41 -0000	1.10
--- src/vsip/impl/view_traits.hpp	5 Dec 2005 15:42:11 -0000
*************** struct ViewConversion;
*** 35,40 ****
--- 35,46 ----
  namespace impl
  {
  
+ template <template <typename, typename> class View,
+ 	  typename                            T,
+ 	  typename                            Block>
+ View<T, typename Distributed_local_block<Block>::type>
+ get_local_view(View<T, Block> v);
+ 
  /// Template class to help instantiate a view of a given dimension.
  
  template <dimension_type Dim,
*************** struct impl_const_View
*** 143,148 ****
--- 149,158 ----
    vsip::length_type size(vsip::dimension_type d) const VSIP_NOTHROW
      { return this->impl_blk->size(Dim, d); }
  
+   // [parview.vector.accessors]
+   local_type local() const VSIP_NOTHROW
+     { return vsip::impl::get_local_view(this->impl_view()); }
+ 
  protected:
     impl_storage_type impl_blk;
  };
*************** struct impl_const_View<View,Block,std::c
*** 205,210 ****
--- 215,224 ----
    vsip::length_type size(vsip::dimension_type d) const VSIP_NOTHROW
      { return this->impl_blk->size(Dim, d); }
  
+   // [parview.vector.accessors]
+   local_type local() const VSIP_NOTHROW
+     { return vsip::impl::get_local_view(this->impl_view()); }
+ 
  protected:
     impl_storage_type impl_blk;
  };
*************** struct impl_View : impl::Const_of_view<V
*** 255,260 ****
--- 269,278 ----
    View<T,Block>& impl_view() { return static_cast<View<T,Block>&>(*this); }
    View<T,Block> const& impl_view() const
      { return static_cast<View<T,Block> const&>(*this); }
+ 
+   // [parview.vector.accessors]
+   local_type local() const VSIP_NOTHROW
+     { return vsip::impl::get_local_view(this->impl_view()); }
  };
  
  // specialize for element type std::complex<T>
*************** struct impl_View<View,Block,std::complex
*** 328,333 ****
--- 346,355 ----
      { return static_cast<View<std::complex<T>,Block>&>(*this); }
    View<std::complex<T>,Block> const& impl_view() const
      { return static_cast<View<std::complex<T>,Block> const&>(*this); }
+ 
+   // [parview.vector.accessors]
+   local_type local() const VSIP_NOTHROW
+     { return vsip::impl::get_local_view(this->impl_view()); }
  };
  
  } // namespace vsip
Index: tests/appmap.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/appmap.cpp,v
retrieving revision 1.7
diff -c -p -r1.7 appmap.cpp
*** tests/appmap.cpp	12 Jul 2005 11:58:06 -0000	1.7
--- tests/appmap.cpp	5 Dec 2005 15:42:11 -0000
*************** dump_appmap(
*** 57,64 ****
    MapT const&            map,
    Vector<processor_type> pvec)
  {
-   typedef typename MapT::subblock_iterator subblock_iterator;
- 
    out << "App_map:\n"
        << "   Dim: (" << map.num_subblocks(0) << " x "
                       << map.num_subblocks(1) << " x "
--- 57,62 ----
*************** dump_appmap(
*** 69,86 ****
    for (index_type pi=0; pi<pvec.size(); ++pi)
    {
      processor_type pr = pvec.get(pi);
! 
!     subblock_iterator begin = map.subblocks_begin(pr);
!     subblock_iterator end   = map.subblocks_end(pr);
      
!     for (subblock_iterator cur = begin; cur != end; ++cur)
      {
-       subblock_type sb = *cur;
- 
        for (index_type p=0; p<map.num_patches(sb); ++p)
        {
! 	Domain<3> gdom = map.template get_global_dom<3>(sb, p);
! 	Domain<3> ldom = map.template get_local_dom<3>(sb, p);
  	out << "  pr=" << pr << "  sb=" << sb << " patch=" << p
  	    << "  gdom=" << gdom
  	    << "  ldom=" << ldom
--- 67,80 ----
    for (index_type pi=0; pi<pvec.size(); ++pi)
    {
      processor_type pr = pvec.get(pi);
!     index_type     sb = map.subblock(pr);
      
!     if (sb != no_subblock)
      {
        for (index_type p=0; p<map.num_patches(sb); ++p)
        {
! 	Domain<3> gdom = map.template global_domain<3>(sb, p);
! 	Domain<3> ldom = map.template local_domain<3>(sb, p);
  	out << "  pr=" << pr << "  sb=" << sb << " patch=" << p
  	    << "  gdom=" << gdom
  	    << "  ldom=" << ldom
*************** dump_appmap(
*** 92,97 ****
--- 86,129 ----
  
  
  
+ // Check that local and global indices within a patch are consistent.
+ 
+ template <dimension_type Dim,
+ 	  typename       MapT>
+ void
+ check_local_vs_global(
+   MapT const&   map,
+   index_type    sb,
+   index_type    p)
+ {
+   Domain<Dim> gdom = map.template global_domain<Dim>(sb, p);
+   Domain<Dim> ldom = map.template local_domain<Dim>(sb, p);
+ 
+   assert(gdom.size() == ldom.size());
+ 
+   for (dimension_type d=0; d<Dim; ++d)
+   {
+     assert(gdom[d].length() == ldom[d].length());
+ 
+     for (index_type i=0; i<ldom[d].length(); ++i)
+     {
+       index_type gi = gdom[d].impl_nth(i);
+       index_type li = ldom[d].impl_nth(i);
+ 
+       if (map.distribution(d) != cyclic)
+       {
+ 	assert(map.impl_local_from_global_index(d, gi) == li);
+ 	// only valid for 1-dim
+ 	// assert(map.impl_subblock_from_index(d, gi) == sb);
+       }
+       assert(map.global_from_local_index(d, sb, li) == gi);
+     }
+   }
+ }
+ 
+ 
+ 
+ 
  // Test 1-dimensional applied map.
  
  // Checks that each index in an applied map's distributed domain is in
*************** tc_appmap(
*** 107,113 ****
    dimension_type const dim = 1;
  
    typedef Map<Dist0> map_t;
-   typedef typename map_t::subblock_iterator subblock_iterator;
  
    Vector<processor_type> pvec = create_pvec(num_proc);
  
--- 139,144 ----
*************** tc_appmap(
*** 119,139 ****
    for (index_type pi=0; pi<pvec.size(); ++pi)
    {
      processor_type pr = pvec.get(pi);
! 
!     subblock_iterator begin = map.subblocks_begin(pr);
!     subblock_iterator end   = map.subblocks_end(pr);
      
!     for (subblock_iterator cur = begin; cur != end; ++cur)
      {
-       subblock_type sb = *cur;
- 
        for (index_type p=0; p<map.num_patches(sb); ++p)
        {
! 	Domain<dim> gdom = map.template get_global_dom<dim>(sb, p);
  
! 	for (index_type i = 0; i<gdom[0].length(); ++i)
! 	  data.put(gdom[0].first() + i*gdom[0].stride(),
! 		   data.get(gdom[0].first() + i*gdom[0].stride()) + 1);
        }
      }
    }
--- 150,167 ----
    for (index_type pi=0; pi<pvec.size(); ++pi)
    {
      processor_type pr = pvec.get(pi);
!     index_type     sb = map.subblock(pr);
      
!     if (sb != no_subblock)
      {
        for (index_type p=0; p<map.num_patches(sb); ++p)
        {
! 	Domain<dim> gdom = map.template global_domain<dim>(sb, p);
! 
! 	if (gdom.size() > 0)
! 	  data(gdom) += 1;
  
! 	check_local_vs_global<dim>(map, sb, p);
        }
      }
    }
*************** tc_appmap(
*** 162,168 ****
    dimension_type const dim = 2;
  
    typedef Map<Dist0, Dist1> map_t;
-   typedef typename map_t::subblock_iterator subblock_iterator;
  
    Vector<processor_type> pvec = create_pvec(num_proc);
  
--- 190,195 ----
*************** tc_appmap(
*** 174,192 ****
    for (index_type pi=0; pi<pvec.size(); ++pi)
    {
      processor_type pr = pvec.get(pi);
! 
!     subblock_iterator begin = map.subblocks_begin(pr);
!     subblock_iterator end   = map.subblocks_end(pr);
      
!     for (subblock_iterator cur = begin; cur != end; ++cur)
      {
-       subblock_type sb = *cur;
- 
        for (index_type p=0; p<map.num_patches(sb); ++p)
        {
! 	Domain<dim> gdom = map.template get_global_dom<dim>(sb, p);
  
  	data(gdom) += 1;
        }
      }
    }
--- 201,217 ----
    for (index_type pi=0; pi<pvec.size(); ++pi)
    {
      processor_type pr = pvec.get(pi);
!     index_type     sb = map.subblock(pr);
      
!     if (sb != no_subblock)
      {
        for (index_type p=0; p<map.num_patches(sb); ++p)
        {
! 	Domain<dim> gdom = map.template global_domain<dim>(sb, p);
  
  	data(gdom) += 1;
+ 
+ 	check_local_vs_global<dim>(map, sb, p);
        }
      }
    }
*************** test_appmap()
*** 273,292 ****
    map.apply(Domain<3>(16, 16, 1));
  
    assert(map.num_patches(0) == 1);
!   assert(map.get_global_dom<3>(0, 0) == Domain<3>(Domain<1>(0, 1, 4),
! 					       Domain<1>(0, 1, 4),
! 					       Domain<1>(0, 1, 1)));
  
    // subblocks are row-major
    assert(map.num_patches(1) == 1);
!   assert(map.get_global_dom<3>(1, 0) == Domain<3>(Domain<1>(0, 1, 4),
! 					       Domain<1>(4, 1, 4),
! 					       Domain<1>(0, 1, 1)));
  
    assert(map.num_patches(15) == 1);
!   assert(map.get_global_dom<3>(15, 0) == Domain<3>(Domain<1>(12, 1, 4),
! 						Domain<1>(12, 1, 4),
! 						Domain<1>(0, 1, 1)));
  }
  
  
--- 298,317 ----
    map.apply(Domain<3>(16, 16, 1));
  
    assert(map.num_patches(0) == 1);
!   assert(map.global_domain<3>(0, 0) == Domain<3>(Domain<1>(0, 1, 4),
! 						 Domain<1>(0, 1, 4),
! 						 Domain<1>(0, 1, 1)));
  
    // subblocks are row-major
    assert(map.num_patches(1) == 1);
!   assert(map.global_domain<3>(1, 0) == Domain<3>(Domain<1>(0, 1, 4),
! 						 Domain<1>(4, 1, 4),
! 						 Domain<1>(0, 1, 1)));
  
    assert(map.num_patches(15) == 1);
!   assert(map.global_domain<3>(15, 0) == Domain<3>(Domain<1>(12, 1, 4),
! 						  Domain<1>(12, 1, 4),
! 						  Domain<1>(0, 1, 1)));
  }
  
  
Index: tests/distributed-block.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/distributed-block.cpp,v
retrieving revision 1.16
diff -c -p -r1.16 distributed-block.cpp
*** tests/distributed-block.cpp	28 Aug 2005 00:22:39 -0000	1.16
--- tests/distributed-block.cpp	5 Dec 2005 15:42:11 -0000
***************
*** 19,30 ****
  #include <vsip/support.hpp>
  #include <vsip/map.hpp>
  #include <vsip/tensor.hpp>
! #include <vsip/impl/point.hpp>
! #include <vsip/impl/point-fcn.hpp>
! #include <vsip/impl/distributed-block.hpp>
! #include <vsip/impl/par-chain-assign.hpp>
! #include <vsip/impl/par-util.hpp>
! #include <vsip/impl/global_map.hpp>
  #if TEST_OLD_PAR_ASSIGN
  #include <vsip/impl/par-assign.hpp>
  #endif
--- 19,26 ----
  #include <vsip/support.hpp>
  #include <vsip/map.hpp>
  #include <vsip/tensor.hpp>
! #include <vsip/parallel.hpp>
! 
  #if TEST_OLD_PAR_ASSIGN
  #include <vsip/impl/par-assign.hpp>
  #endif
*************** check_local_view(
*** 60,75 ****
    typedef typename impl::Distributed_local_block<BlockT>::type local_block_t;
  
    typename BlockT::map_type const& map = view.block().map();
!   typename ViewT<T, BlockT>::local_type lview = get_local_view(view);
  
!   subblock_type sb = map.impl_subblock();
    if (sb == no_subblock)
    {
      assert(lview.size() == 0);
    }
    else
    {
!     Domain<Dim> dom = map.template get_subblock_dom<Dim>(sb);
      assert(lview.size() == impl::size(dom));
      for (dimension_type d=0; d<Dim; ++d)
        assert(lview.size(d) == dom[d].size());
--- 56,71 ----
    typedef typename impl::Distributed_local_block<BlockT>::type local_block_t;
  
    typename BlockT::map_type const& map = view.block().map();
!   typename ViewT<T, BlockT>::local_type lview = view.local();
  
!   index_type sb = map.subblock();
    if (sb == no_subblock)
    {
      assert(lview.size() == 0);
    }
    else
    {
!     Domain<Dim> dom = map.template subblock_domain<Dim>(sb);
      assert(lview.size() == impl::size(dom));
      for (dimension_type d=0; d<Dim; ++d)
        assert(lview.size(d) == dom[d].size());
*************** test_distributed_view(
*** 186,192 ****
    // Check results.
    comm.barrier();
  
!   typename view0_t::local_type local_view = get_local_view(view0);
  
    if (map1.impl_rank() == 0) 
    {
--- 182,188 ----
    // Check results.
    comm.barrier();
  
!   typename view0_t::local_type local_view = view0.local();
  
    if (map1.impl_rank() == 0) 
    {
*************** test_distributed_view_assign(
*** 289,295 ****
  
    if (map1.impl_rank() == 0) 
    {
!     typename view0_t::local_type local_view = get_local_view(view0);
  
      // Check that local_view is in fact the entire view.
      assert(extent_old(local_view) == extent_old(dom));
--- 285,291 ----
  
    if (map1.impl_rank() == 0) 
    {
!     typename view0_t::local_type local_view = view0.local();
  
      // Check that local_view is in fact the entire view.
      assert(extent_old(local_view) == extent_old(dom));
Index: tests/distributed-subviews.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/distributed-subviews.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 distributed-subviews.cpp
*** tests/distributed-subviews.cpp	2 Nov 2005 18:44:04 -0000	1.4
--- tests/distributed-subviews.cpp	5 Dec 2005 15:42:11 -0000
***************
*** 18,33 ****
  #include <vsip/map.hpp>
  #include <vsip/math.hpp>
  #include <vsip/tensor.hpp>
! #include <vsip/impl/point.hpp>
! #include <vsip/impl/point-fcn.hpp>
! #include <vsip/impl/distributed-block.hpp>
! #include <vsip/impl/par-chain-assign.hpp>
! #include <vsip/impl/par-util.hpp>
! #include <vsip/impl/global_map.hpp>
  #include <vsip/impl/profile.hpp>
- #ifdef TEST_OLD_PAR_ASSIGN
- #include <vsip/impl/par-assign.hpp>
- #endif
  
  #include "test.hpp"
  #include "output.hpp"
--- 18,26 ----
  #include <vsip/map.hpp>
  #include <vsip/math.hpp>
  #include <vsip/tensor.hpp>
! #include <vsip/parallel.hpp>
! 
  #include <vsip/impl/profile.hpp>
  
  #include "test.hpp"
  #include "output.hpp"
*************** test_row_sum(
*** 81,88 ****
  
    if (root_map.impl_rank() == 0)
    {
!     typename root_view2_t::local_type local_view = get_local_view(root_view);
!     typename root_view1_t::local_type local_sum  = get_local_view(root_sum);
  
      for (index_type r=0; r<local_view.size(0); ++r)
        for (index_type c=0; c<local_view.size(1); ++c)
--- 74,81 ----
  
    if (root_map.impl_rank() == 0)
    {
!     typename root_view2_t::local_type local_view = root_view.local();
!     typename root_view1_t::local_type local_sum  = root_sum.local();
  
      for (index_type r=0; r<local_view.size(0); ++r)
        for (index_type c=0; c<local_view.size(1); ++c)
*************** test_row_sum(
*** 128,135 ****
      my_sum = my_sum + view.row(r);
    }
  
!   typename global_view1_t::local_type local_my_sum  = get_local_view(my_sum);
!   typename global_view1_t::local_type local_chk_sum = get_local_view(chk_sum);
  
    for (index_type i=0; i<sum_size; ++i)
    {
--- 121,128 ----
      my_sum = my_sum + view.row(r);
    }
  
!   typename global_view1_t::local_type local_my_sum  = my_sum.local();
!   typename global_view1_t::local_type local_chk_sum = chk_sum.local();
  
    for (index_type i=0; i<sum_size; ++i)
    {
*************** test_col_sum(
*** 192,199 ****
  
    if (root_map.impl_rank() == 0)
    {
!     typename root_view2_t::local_type local_view = get_local_view(root_view);
!     typename root_view1_t::local_type local_sum  = get_local_view(root_sum);
  
      for (index_type r=0; r<local_view.size(0); ++r)
        for (index_type c=0; c<local_view.size(1); ++c)
--- 185,192 ----
  
    if (root_map.impl_rank() == 0)
    {
!     typename root_view2_t::local_type local_view = root_view.local();
!     typename root_view1_t::local_type local_sum  = root_sum.local();
  
      for (index_type r=0; r<local_view.size(0); ++r)
        for (index_type c=0; c<local_view.size(1); ++c)
*************** test_col_sum(
*** 239,246 ****
      my_sum = my_sum + view.col(c);
    }
  
!   typename global_view1_t::local_type local_my_sum  = get_local_view(my_sum);
!   typename global_view1_t::local_type local_chk_sum = get_local_view(chk_sum);
  
    for (index_type i=0; i<sum_size; ++i)
    {
--- 232,239 ----
      my_sum = my_sum + view.col(c);
    }
  
!   typename global_view1_t::local_type local_my_sum  = my_sum.local();
!   typename global_view1_t::local_type local_chk_sum = chk_sum.local();
  
    for (index_type i=0; i<sum_size; ++i)
    {
*************** test_tensor_v_sum(
*** 353,360 ****
  
    if (root_map.impl_rank() == 0)
    {
!     typename root_view3_t::local_type local_view = get_local_view(root_view);
!     typename root_view1_t::local_type local_sum  = get_local_view(root_sum);
  
      for (index_type i=0; i<local_view.size(0); ++i)
        for (index_type j=0; j<local_view.size(1); ++j)
--- 346,353 ----
  
    if (root_map.impl_rank() == 0)
    {
!     typename root_view3_t::local_type local_view = root_view.local();
!     typename root_view1_t::local_type local_sum  = root_sum.local();
  
      for (index_type i=0; i<local_view.size(0); ++i)
        for (index_type j=0; j<local_view.size(1); ++j)
*************** test_tensor_v_sum(
*** 407,414 ****
    // ------------------------------------------------------------------ 
    // Check answer
  
!   typename global_view1_t::local_type local_my_sum  = get_local_view(my_sum);
!   typename global_view1_t::local_type local_chk_sum = get_local_view(chk_sum);
  
    for (index_type i=0; i<sum_size; ++i)
    {
--- 400,407 ----
    // ------------------------------------------------------------------ 
    // Check answer
  
!   typename global_view1_t::local_type local_my_sum  = my_sum.local();
!   typename global_view1_t::local_type local_chk_sum = chk_sum.local();
  
    for (index_type i=0; i<sum_size; ++i)
    {
*************** test_tensor_m_sum(
*** 537,544 ****
  
    if (root_map.impl_rank() == 0)
    {
!     typename root_view3_t::local_type local_view = get_local_view(root_view);
!     typename root_view2_t::local_type local_sum  = get_local_view(root_sum);
  
      for (index_type i=0; i<local_view.size(0); ++i)
        for (index_type j=0; j<local_view.size(1); ++j)
--- 530,537 ----
  
    if (root_map.impl_rank() == 0)
    {
!     typename root_view3_t::local_type local_view = root_view.local();
!     typename root_view2_t::local_type local_sum  = root_sum.local();
  
      for (index_type i=0; i<local_view.size(0); ++i)
        for (index_type j=0; j<local_view.size(1); ++j)
*************** test_tensor_m_sum(
*** 585,592 ****
      my_sum = my_sum + slice.subview(view, i);
    }
  
!   typename global_view2_t::local_type local_my_sum  = get_local_view(my_sum);
!   typename global_view2_t::local_type local_chk_sum = get_local_view(chk_sum);
  
    for (index_type i=0; i<sum_rows; ++i)
      for (index_type j=0; j<sum_cols; ++j)
--- 578,585 ----
      my_sum = my_sum + slice.subview(view, i);
    }
  
!   typename global_view2_t::local_type local_my_sum  = my_sum.local();
!   typename global_view2_t::local_type local_chk_sum = chk_sum.local();
  
    for (index_type i=0; i<sum_rows; ++i)
      for (index_type j=0; j<sum_cols; ++j)
*************** main(int argc, char** argv)
*** 677,682 ****
--- 670,676 ----
    if (do_all || do_mrow)
      cases_row_sum<float>(Domain<2>(4, 15));
  
+ #if 1
    if (do_all || do_mcol)
      cases_col_sum<float>(Domain<2>(15, 4));
  
*************** main(int argc, char** argv)
*** 704,709 ****
--- 698,704 ----
      cases_tensor_v_sum<float, 1>(Domain<3>(32, 16, 64));
      cases_tensor_v_sum<float, 2>(Domain<3>(32, 16, 64));
    }
+ #endif
  
    return 0;
  }
Index: tests/distributed-user-storage.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/distributed-user-storage.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 distributed-user-storage.cpp
*** tests/distributed-user-storage.cpp	16 Sep 2005 21:51:08 -0000	1.1
--- tests/distributed-user-storage.cpp	5 Dec 2005 15:42:11 -0000
***************
*** 17,24 ****
  #include <vsip/support.hpp>
  #include <vsip/dense.hpp>
  #include <vsip/map.hpp>
! #include <vsip/impl/par-util.hpp>
! #include <vsip/impl/setup-assign.hpp>
  
  #include "test.hpp"
  #include "util.hpp"
--- 17,23 ----
  #include <vsip/support.hpp>
  #include <vsip/dense.hpp>
  #include <vsip/map.hpp>
! #include <vsip/parallel.hpp>
  
  #include "test.hpp"
  #include "util.hpp"
*************** test1(
*** 74,80 ****
    assert(dist.block().admitted() == false);
  
    // Find out how big the local subdomain is.
!   Domain<Dim> subdom = my_subblock_dom(dist);
  
    // cout << "size: " << subdom.size() << endl;
  
--- 73,79 ----
    assert(dist.block().admitted() == false);
  
    // Find out how big the local subdomain is.
!   Domain<Dim> subdom = subblock_domain(dist);
  
    // cout << "size: " << subdom.size() << endl;
  
*************** test1(
*** 93,102 ****
      dist.block().rebind(data[iter]);
  
      // Put some data in buffer.
!     for (index_type p=0; p<my_patches(dist); ++p)
      {
!       Domain<Dim> l_dom = my_local_dom(dist, p);
!       Domain<Dim> g_dom = my_global_dom(dist, p);
  
        for (index_type i=0; i<l_dom[0].size(); ++i)
        {
--- 92,101 ----
      dist.block().rebind(data[iter]);
  
      // Put some data in buffer.
!     for (index_type p=0; p<num_patches(dist); ++p)
      {
!       Domain<Dim> l_dom = local_domain(dist, p);
!       Domain<Dim> g_dom = global_domain(dist, p);
  
        for (index_type i=0; i<l_dom[0].size(); ++i)
        {
*************** test1(
*** 122,128 ****
      // On the root processor ...
      if (root_map.impl_rank() == 0)
      {
!       typename root_view_t::local_type l_root = get_local_view(root);
  
        // ... check that root is correct.
        for (index_type i=0; i<l_root.size(); ++i)
--- 121,127 ----
      // On the root processor ...
      if (root_map.impl_rank() == 0)
      {
!       typename root_view_t::local_type l_root = root.local();
  
        // ... check that root is correct.
        for (index_type i=0; i<l_root.size(); ++i)
*************** test1(
*** 144,153 ****
      assert(dist.block().admitted() == false);
  
      // Check the data in buffer.
!     for (index_type p=0; p<my_patches(dist); ++p)
      {
!       Domain<Dim> l_dom = my_local_dom(dist, p);
!       Domain<Dim> g_dom = my_global_dom(dist, p);
        
        for (index_type i=0; i<l_dom[0].size(); ++i)
        {
--- 143,152 ----
      assert(dist.block().admitted() == false);
  
      // Check the data in buffer.
!     for (index_type p=0; p<num_patches(dist); ++p)
      {
!       Domain<Dim> l_dom = local_domain(dist, p);
!       Domain<Dim> g_dom = global_domain(dist, p);
        
        for (index_type i=0; i<l_dom[0].size(); ++i)
        {
*************** main(int argc, char** argv)
*** 193,198 ****
    Map<Block_dist>  map1 = Map<Block_dist>(Block_dist(np));
    Map<Cyclic_dist> map2 = Map<Cyclic_dist>(Cyclic_dist(np));
  
!   test1<float>(Domain<1>(10), map1, true);
!   test1<float>(Domain<1>(10), map2, true);
  }
--- 192,197 ----
    Map<Block_dist>  map1 = Map<Block_dist>(Block_dist(np));
    Map<Cyclic_dist> map2 = Map<Cyclic_dist>(Cyclic_dist(np));
  
!   test1<float>(Domain<1>(10), map1, false);
!   test1<float>(Domain<1>(10), map2, false);
  }
Index: tests/map.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/map.cpp,v
retrieving revision 1.8
diff -c -p -r1.8 map.cpp
*** tests/map.cpp	12 Jul 2005 11:58:06 -0000	1.8
--- tests/map.cpp	5 Dec 2005 15:42:11 -0000
*************** count_subblocks(
*** 187,204 ****
  
  template <typename Map>
  void
! check_subblocks(
    Map const&	                  map,
    processor_type                  pr,
!   typename Map::subblock_iterator begin,
!   typename Map::subblock_iterator end)
  {
-   typedef typename Map::subblock_iterator subblock_iterator;
    typedef typename Map::processor_iterator processor_iterator;
  
!   for (subblock_iterator cur = begin; cur != end; ++cur)
    {
-     subblock_type sb = *cur;
      processor_iterator pbegin = map.processor_begin(sb);
      processor_iterator pend   = map.processor_end(sb);
  
--- 187,201 ----
  
  template <typename Map>
  void
! check_subblock(
    Map const&	                  map,
    processor_type                  pr,
!   index_type                      sb)
  {
    typedef typename Map::processor_iterator processor_iterator;
  
!   if (sb != no_subblock)
    {
      processor_iterator pbegin = map.processor_begin(sb);
      processor_iterator pend   = map.processor_end(sb);
  
*************** tc_map_subblocks(
*** 252,258 ****
    Dist1       dist1)
  {
    typedef Map<Dist0, Dist1> map_t;
-   typedef typename map_t::subblock_iterator subblock_iterator;
  
    Vector<processor_type> pvec = create_pvec(num_proc);
  
--- 249,254 ----
*************** tc_map_subblocks(
*** 272,287 ****
      length_type expected_count = num_subblocks/num_proc +
  				 (i < num_subblocks%num_proc ? 1 : 0);
  
!     subblock_iterator begin = map.subblocks_begin(pr);
!     subblock_iterator end   = map.subblocks_end(pr);
  
!     length_type count = count_subblocks(begin, end);
  
      // Check the number of subblocks per processor.
      assert(count == expected_count);
  
      // Check that each subblock is only mapped to this processr.
!     check_subblocks(map, pr, begin, end);
  
      total += count;
    }
--- 268,282 ----
      length_type expected_count = num_subblocks/num_proc +
  				 (i < num_subblocks%num_proc ? 1 : 0);
  
!     index_type sb = map.subblock(pr);
  
!     length_type count = sb == no_subblock ? 0 : 1;
  
      // Check the number of subblocks per processor.
      assert(count == expected_count);
  
      // Check that each subblock is only mapped to this processr.
!     check_subblock(map, pr, sb);
  
      total += count;
    }
Index: tests/par_expr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/par_expr.cpp,v
retrieving revision 1.8
diff -c -p -r1.8 par_expr.cpp
*** tests/par_expr.cpp	2 Nov 2005 18:44:04 -0000	1.8
--- tests/par_expr.cpp	5 Dec 2005 15:42:11 -0000
***************
*** 17,28 ****
  #include <vsip/support.hpp>
  #include <vsip/map.hpp>
  #include <vsip/math.hpp>
! #include <vsip/impl/point.hpp>
! #include <vsip/impl/point-fcn.hpp>
! #include <vsip/impl/distributed-block.hpp>
! #include <vsip/impl/par-chain-assign.hpp>
! #include <vsip/impl/par-util.hpp>
! #include <vsip/impl/global_map.hpp>
  
  #include "test.hpp"
  #include "output.hpp"
--- 17,23 ----
  #include <vsip/support.hpp>
  #include <vsip/map.hpp>
  #include <vsip/math.hpp>
! #include <vsip/parallel.hpp>
  
  #include "test.hpp"
  #include "output.hpp"
*************** test_distributed_expr(
*** 205,211 ****
  
    if (map_res.impl_rank() == 0) // rank(map_res) == 0
    {
!     typename view0_t::local_type local_view = get_local_view(chk1);
  
      // Check that local_view is in fact the entire view.
      assert(extent_old(local_view) == extent_old(dom));
--- 200,206 ----
  
    if (map_res.impl_rank() == 0) // rank(map_res) == 0
    {
!     typename view0_t::local_type local_view = chk1.local();
  
      // Check that local_view is in fact the entire view.
      assert(extent_old(local_view) == extent_old(dom));
*************** test_distributed_expr3(
*** 317,323 ****
  
    if (map_res.impl_rank() == 0) 
    {
!     typename view0_t::local_type local_view = get_local_view(chk1);
  
      // Check that local_view is in fact the entire view.
      assert(extent_old(local_view) == extent_old(dom));
--- 312,318 ----
  
    if (map_res.impl_rank() == 0) 
    {
!     typename view0_t::local_type local_view = chk1.local();
  
      // Check that local_view is in fact the entire view.
      assert(extent_old(local_view) == extent_old(dom));
*************** test_distributed_expr3_capture(
*** 426,432 ****
  
    if (map_res.impl_rank() == 0) 
    {
!     typename view0_t::local_type local_view = get_local_view(chk);
  
      // Check that local_view is in fact the entire view.
      assert(extent_old(local_view) == extent_old(dom));
--- 421,427 ----
  
    if (map_res.impl_rank() == 0) 
    {
!     typename view0_t::local_type local_view = chk.local();
  
      // Check that local_view is in fact the entire view.
      assert(extent_old(local_view) == extent_old(dom));
Index: tests/util-par.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/util-par.hpp,v
retrieving revision 1.6
diff -c -p -r1.6 util-par.hpp
*** tests/util-par.hpp	16 Nov 2005 13:56:23 -0000	1.6
--- tests/util-par.hpp	5 Dec 2005 15:42:11 -0000
*************** dump_view(
*** 114,120 ****
    vsip::Vector<T, Block> view)
  {
    using vsip::index_type;
-   using vsip::subblock_type;
    using vsip::no_subblock;
    using vsip::impl::Distributed_local_block;
  
--- 114,119 ----
*************** dump_view(
*** 130,146 ****
    std::cout << "(" << am.impl_rank() << "):    block "
  	    << Type_name<Block>::name() << "\n";
  
!   subblock_type sb = am.impl_subblock();
    if (sb != no_subblock)
    {
!     vsip::Vector<T, local_block_t> local_view = get_local_view(view);
  
      for (index_type p=0; p<am.num_patches(sb); ++p)
      {
        std::cout << "  subblock: " << sb
  		<< "  patch: " << p << std::endl;
!       vsip::Domain<1> ldom = am.template get_local_dom<1>(sb, p);
!       vsip::Domain<1> gdom = am.template get_global_dom<1>(sb, p);
  
        for (index_type i=0; i<ldom.length(); ++i) 
        {
--- 129,145 ----
    std::cout << "(" << am.impl_rank() << "):    block "
  	    << Type_name<Block>::name() << "\n";
  
!   index_type sb = am.subblock();
    if (sb != no_subblock)
    {
!     vsip::Vector<T, local_block_t> local_view = view.local();
  
      for (index_type p=0; p<am.num_patches(sb); ++p)
      {
        std::cout << "  subblock: " << sb
  		<< "  patch: " << p << std::endl;
!       vsip::Domain<1> ldom = am.template local_domain<1>(sb, p);
!       vsip::Domain<1> gdom = am.template global_domain<1>(sb, p);
  
        for (index_type i=0; i<ldom.length(); ++i) 
        {
*************** dump_view(
*** 172,178 ****
  {
    using vsip::index_type;
    using vsip::dimension_type;
-   using vsip::subblock_type;
    using vsip::no_subblock;
    using vsip::impl::Distributed_local_block;
  
--- 171,176 ----
*************** dump_view(
*** 185,194 ****
    msg(am, std::string(name) + " ------------------------------------------\n");
    std::cout << "(" << am.impl_rank() << "): dump_view(Matrix " << name << ")\n";
  
!   subblock_type sb = am.impl_subblock();
    if (sb != no_subblock)
    {
!     vsip::Matrix<T, local_block_t> local_view = get_local_view(view);
  
      for (index_type p=0; p<am.num_patches(sb); ++p)
      {
--- 183,192 ----
    msg(am, std::string(name) + " ------------------------------------------\n");
    std::cout << "(" << am.impl_rank() << "): dump_view(Matrix " << name << ")\n";
  
!   index_type sb = am.subblock();
    if (sb != no_subblock)
    {
!     vsip::Matrix<T, local_block_t> local_view = view.local();
  
      for (index_type p=0; p<am.num_patches(sb); ++p)
      {
*************** dump_view(
*** 199,206 ****
  	   << "  patch: " << p
  	   << str
  	   << std::endl;
!       vsip::Domain<dim> ldom = am.template get_local_dom<dim>(sb, p);
!       vsip::Domain<dim> gdom = am.template get_global_dom<dim>(sb, p);
  
        for (index_type r=0; r<ldom[0].length(); ++r) 
  	for (index_type c=0; c<ldom[1].length(); ++c) 
--- 197,204 ----
  	   << "  patch: " << p
  	   << str
  	   << std::endl;
!       vsip::Domain<dim> ldom = am.template local_domain<dim>(sb, p);
!       vsip::Domain<dim> gdom = am.template global_domain<dim>(sb, p);
  
        for (index_type r=0; r<ldom[0].length(); ++r) 
  	for (index_type c=0; c<ldom[1].length(); ++c) 
*************** dump_map(MapT const& map)
*** 247,257 ****
  	    << " [" << s.str() << "]"
  	    << std::endl;
  
!   for (vsip::subblock_type sb=0; sb<map.num_subblocks(); ++sb)
    {
      std::cout << "  sub " << sb << ": ";
      if (map.impl_is_applied())
!       std::cout << map.template get_global_dom<Dim>(sb, 0);
      std::cout << " [";
  
      for (p_iter_t p=map.processor_begin(sb); p != map.processor_end(sb); ++p)
--- 245,255 ----
  	    << " [" << s.str() << "]"
  	    << std::endl;
  
!   for (vsip::index_type sb=0; sb<map.num_subblocks(); ++sb)
    {
      std::cout << "  sub " << sb << ": ";
      if (map.impl_is_applied())
!       std::cout << map.template global_domain<Dim>(sb, 0);
      std::cout << " [";
  
      for (p_iter_t p=map.processor_begin(sb); p != map.processor_end(sb); ++p)
Index: tests/vmmul.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/vmmul.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 vmmul.cpp
*** tests/vmmul.cpp	2 Nov 2005 18:44:04 -0000	1.2
--- tests/vmmul.cpp	5 Dec 2005 15:42:11 -0000
***************
*** 17,23 ****
  #include <vsip/initfin.hpp>
  #include <vsip/vector.hpp>
  #include <vsip/map.hpp>
- #include <vsip/impl/global_map.hpp>
  #include <vsip/parallel.hpp>
  #include <vsip/math.hpp>
  
--- 17,22 ----
