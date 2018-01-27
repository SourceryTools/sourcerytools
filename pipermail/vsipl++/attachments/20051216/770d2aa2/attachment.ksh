Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.337
diff -c -p -r1.337 ChangeLog
*** ChangeLog	14 Dec 2005 17:30:31 -0000	1.337
--- ChangeLog	16 Dec 2005 22:10:31 -0000
***************
*** 1,3 ****
--- 1,15 ----
+ 2005-12-16 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	* benchmarks/fastconv.cpp: Add new case using out-of-place FFT to
+ 	  perform in-place FFTM.  Parallel this case and single-loop case.
+ 	* benchmarks/fftm.cpp: New file, benchmarks for Fftm.
+ 	* benchmarks/loop.hpp: Print case number to output.
+ 	* benchmarks/main.cpp: Likewise.
+ 	* benchmarks/vmmul.cpp: New file, benchmarks for vector-matrix mul.
+ 	* benchmarks/vmul_ipp.cpp: Add benchmarks for in-place element-wise
+ 	  vector multiply.
+ 	* src/vsip/impl/dist.hpp: Add constructor taking number of subblocks.
+ 
  2005-12-14  Mark Mitchell  <mark@codesourcery.com>
  
  	* GNUmakefile.in (maintainer_mode): New variable.  Do not define
Index: benchmarks/fastconv.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/fastconv.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 fastconv.cpp
*** benchmarks/fastconv.cpp	5 Dec 2005 19:19:18 -0000	1.1
--- benchmarks/fastconv.cpp	16 Dec 2005 22:10:32 -0000
*************** template <typename T,
*** 41,51 ****
  	  typename ImplTag>
  struct t_fastconv_base;
  
! struct Impl1op;
! struct Impl1ip;
! struct Impl1pip;
! struct Impl2;
! struct Impl2fv;
  
  struct fastconv_ops
  {
--- 41,54 ----
  	  typename ImplTag>
  struct t_fastconv_base;
  
! struct Impl1op;		// out-of-place, phased fast-convolution
! struct Impl1ip;		// in-place, phased fast-convolution
! struct Impl1pip1;	// psuedo in-place (using in-place Fft), phased
! struct Impl1pip2;	// psuedo in-place (using out-of-place Fft), phased
! struct Impl2;		// out-of-place (tmp), interleaved fast-convolution
! struct Impl2fv;		// foreach_vector, interleaved fast-convolution
! 
! struct Impl1pip2_nopar;
  
  struct fastconv_ops
  {
*************** struct t_fastconv_base<T, Impl1ip> : fas
*** 165,170 ****
--- 168,174 ----
      
      vsip::impl::profile::Timer t1;
      
+     // Impl1 ip
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
*************** struct t_fastconv_base<T, Impl1ip> : fas
*** 182,189 ****
  
  
  
  template <typename T>
! struct t_fastconv_base<T, Impl1pip> : fastconv_ops
  {
    void fastconv(length_type npulse, length_type nrange,
  		length_type loop, float& time)
--- 186,197 ----
  
  
  
+ /***********************************************************************
+   Impl1pip1: psuedo in-place (using in-place Fft), phased fast-convolution
+ ***********************************************************************/
+ 
  template <typename T>
! struct t_fastconv_base<T, Impl1pip1> : fastconv_ops
  {
    void fastconv(length_type npulse, length_type nrange,
  		length_type loop, float& time)
*************** struct t_fastconv_base<T, Impl1pip> : fa
*** 218,223 ****
--- 226,232 ----
      
      vsip::impl::profile::Timer t1;
      
+     // Impl1 pip
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
*************** struct t_fastconv_base<T, Impl1pip> : fa
*** 238,257 ****
  
  
  /***********************************************************************
!   Impl2: out-of-place (tmp), interleaved fast-convolution
  ***********************************************************************/
  
  template <typename T>
! struct t_fastconv_base<T, Impl2> : fastconv_ops
  {
    void fastconv(length_type npulse, length_type nrange,
  		length_type loop, float& time)
    {
      // Create the data cube.
!     Matrix<T> data(npulse, nrange);
      Vector<T> tmp(nrange);
      
      // Create the pulse replica
      Vector<T> replica(nrange);
  
      // int const no_times = 0; // FFTW_PATIENT
--- 247,338 ----
  
  
  /***********************************************************************
!   Impl1pip2: psuedo in-place (using out-of-place Fft), phased fast-convolution
  ***********************************************************************/
  
  template <typename T>
! struct t_fastconv_base<T, Impl1pip2> : fastconv_ops
  {
    void fastconv(length_type npulse, length_type nrange,
  		length_type loop, float& time)
    {
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
      // Create the data cube.
!     view_type data(npulse, nrange, map);
!     
!     // Create the pulse replica
      Vector<T> tmp(nrange);
+     replica_view_type replica(nrange);
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
+     // Impl1 pip2
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+     {
+       typename view_type::local_type         l_data    = data.local();
+       typename replica_view_type::local_type l_replica = replica.local();
+       length_type                            l_npulse  = l_data.size(0);
+       for (index_type p=0; p<l_npulse; ++p)
+       {
+ 	for_fft(l_data.row(p), tmp);
+ 	l_data.row(p) = tmp;
+       }
+       l_data = vmmul<0>(l_replica, l_data);
+       for (index_type p=0; p<l_npulse; ++p)
+       {
+ 	inv_fft(l_data.row(p), tmp);
+ 	l_data.row(p) = tmp;
+       }
+     }
+     t1.stop();
+ 
+     // CHECK RESULT
+     time = t1.delta();
+   }
+ };
+ 
+ template <typename T>
+ struct t_fastconv_base<T, Impl1pip2_nopar> : fastconv_ops
+ {
+   void fastconv(length_type npulse, length_type nrange,
+ 		length_type loop, float& time)
+   {
+     // Create the data cube.
+     Matrix<T> data(npulse, nrange);
      
      // Create the pulse replica
+     Vector<T> tmp(nrange);
      Vector<T> replica(nrange);
  
      // int const no_times = 0; // FFTW_PATIENT
*************** struct t_fastconv_base<T, Impl2> : fastc
*** 277,291 ****
      
      vsip::impl::profile::Timer t1;
      
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
-       // Perform fast convolution:
        for (index_type p=0; p<npulse; ++p)
        {
  	for_fft(data.row(p), tmp);
! 	tmp *= replica;
! 	inv_fft(tmp, data.row(p));
        }
      }
      t1.stop();
--- 358,449 ----
      
      vsip::impl::profile::Timer t1;
      
+     // Impl1 pip2
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
        for (index_type p=0; p<npulse; ++p)
        {
  	for_fft(data.row(p), tmp);
! 	data.row(p) = tmp;
!       }
!       data = vmmul<0>(replica, data);
!       for (index_type p=0; p<npulse; ++p)
!       {
! 	inv_fft(data.row(p), tmp);
! 	data.row(p) = tmp;
!       }
!     }
!     t1.stop();
! 
!     // CHECK RESULT
!     time = t1.delta();
!   }
! };
! 
! 
! 
! /***********************************************************************
!   Impl2: out-of-place (tmp), interleaved fast-convolution
! ***********************************************************************/
! 
! template <typename T>
! struct t_fastconv_base<T, Impl2> : fastconv_ops
! {
!   void fastconv(length_type npulse, length_type nrange,
! 		length_type loop, float& time)
!   {
!     typedef Map<Block_dist, Whole_dist>      map_type;
!     typedef Dense<2, T, row2_type, map_type> block_type;
!     typedef Matrix<T, block_type>            view_type;
! 
!     typedef Dense<1, T, row1_type, Global_map<1> > replica_block_type;
!     typedef Vector<T, replica_block_type>          replica_view_type;
! 
!     processor_type np = num_processors();
!     map_type map = map_type(Block_dist(np), Whole_dist());
! 
!     // Create the data cube.
!     view_type data(npulse, nrange, map);
!     Vector<T> tmp(nrange);
!     
!     // Create the pulse replica
!     replica_view_type replica(nrange);
! 
!     // int const no_times = 0; // FFTW_PATIENT
!     int const no_times = 15; // not > 12 = FFT_MEASURE
!     
!     typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times>
! 	  	for_fft_type;
!     typedef Fft<const_Vector, T, T, fft_inv, by_reference, no_times>
! 	  	inv_fft_type;
! 
!     // Create the FFT objects.
!     for_fft_type for_fft(Domain<1>(nrange), 1.0);
!     inv_fft_type inv_fft(Domain<1>(nrange), 1.0/(nrange));
! 
!     // Initialize
!     data    = T();
!     replica = T();
! 
! 
!     // Before fast convolution, convert the replica into the
!     // frequency domain
!     // for_fft(replica);
!     
!     vsip::impl::profile::Timer t1;
!     
!     t1.start();
!     for (index_type l=0; l<loop; ++l)
!     {
!       typename view_type::local_type         l_data    = data.local();
!       typename replica_view_type::local_type l_replica = replica.local();
!       length_type                            l_npulse  = l_data.size(0);
!       for (index_type p=0; p<l_npulse; ++p)
!       {
! 	for_fft(l_data.row(p), tmp);
! 	tmp *= l_replica;
! 	inv_fft(tmp, l_data.row(p));
        }
      }
      t1.stop();
*************** struct t_fastconv_pf : public t_fastconv
*** 414,420 ****
  
  
  /***********************************************************************
!   RF driver: (R)ulse (F)ixed
  ***********************************************************************/
  
  template <typename T, typename ImplTag>
--- 572,578 ----
  
  
  /***********************************************************************
!   RF driver: (R)ange cells (F)ixed
  ***********************************************************************/
  
  template <typename T, typename ImplTag>
*************** test(Loop1P& loop, int what)
*** 459,467 ****
    {
    case  1: loop(t_fastconv_pf<complex<float>, Impl1op>(param1)); break;
    case  2: loop(t_fastconv_pf<complex<float>, Impl1ip>(param1)); break;
!   case  3: loop(t_fastconv_pf<complex<float>, Impl1pip>(param1)); break;
!   case  4: loop(t_fastconv_pf<complex<float>, Impl2>(param1)); break;
!   case  5: loop(t_fastconv_pf<complex<float>, Impl2fv>(param1)); break;
    default: return 0;
    }
    return 1;
--- 617,636 ----
    {
    case  1: loop(t_fastconv_pf<complex<float>, Impl1op>(param1)); break;
    case  2: loop(t_fastconv_pf<complex<float>, Impl1ip>(param1)); break;
!   case  3: loop(t_fastconv_pf<complex<float>, Impl1pip1>(param1)); break;
!   case  4: loop(t_fastconv_pf<complex<float>, Impl1pip2>(param1)); break;
!   case  5: loop(t_fastconv_pf<complex<float>, Impl2>(param1)); break;
!   case  6: loop(t_fastconv_pf<complex<float>, Impl2fv>(param1)); break;
! 
!   case  9: loop(t_fastconv_pf<complex<float>, Impl1pip2_nopar>(param1)); break;
! 
!   case 11: loop(t_fastconv_rf<complex<float>, Impl1op>(param1)); break;
!   case 12: loop(t_fastconv_rf<complex<float>, Impl1ip>(param1)); break;
!   case 13: loop(t_fastconv_rf<complex<float>, Impl1pip1>(param1)); break;
!   case 14: loop(t_fastconv_rf<complex<float>, Impl1pip2>(param1)); break;
!   case 15: loop(t_fastconv_rf<complex<float>, Impl2>(param1)); break;
!   case 16: loop(t_fastconv_rf<complex<float>, Impl2fv>(param1)); break;
! 
    default: return 0;
    }
    return 1;
Index: benchmarks/fftm.cpp
===================================================================
RCS file: benchmarks/fftm.cpp
diff -N benchmarks/fftm.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/fftm.cpp	16 Dec 2005 22:10:32 -0000
***************
*** 0 ****
--- 1,392 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    benchmarks/fftm.cpp
+     @author  Jules Bergmann
+     @date    2005-12-14
+     @brief   VSIPL++ Library: Benchmark for Fftm.
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
+ 
+ #include "test.hpp"
+ #include "loop.hpp"
+ 
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ int
+ fft_ops(length_type len)
+ {
+   return int(5 * len * std::log(len) / std::log(2));
+ }
+ 
+ 
+ 
+ template <typename T,
+ 	  typename Tag,
+ 	  int      SD>
+ struct t_fftm;
+ 
+ struct Impl_op;
+ struct Impl_ip;
+ struct Impl_pip1;
+ struct Impl_pip2;
+ 
+ 
+ 
+ /***********************************************************************
+   Impl_op: Out-of-place Fftm
+ ***********************************************************************/
+ 
+ template <typename T,
+ 	  int      SD>
+ struct t_fftm<T, Impl_op, SD>
+ {
+   char* what() { return "t_fftm<T, Impl_op, SD>"; }
+   int ops(length_type rows, length_type cols)
+     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
+ 
+   void fftm(length_type rows, length_type cols, length_type loop, float& time)
+   {
+     Matrix<T>   A(rows, cols, T());
+     Matrix<T>   Z(rows, cols);
+ 
+     // int const no_times = 0; // FFTW_PATIENT
+     int const no_times = 15; // not > 12 = FFT_MEASURE
+ 
+     typedef Fftm<T, T, SD, fft_fwd, by_reference, no_times, alg_time>
+       fftm_type;
+ 
+     fftm_type fftm(Domain<2>(rows, cols), 1.f);
+ 
+     A = T(1);
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       fftm(A, Z);
+     t1.stop();
+     
+     if (!equal(Z(0, 0), T(SD == row ? cols : rows)))
+     {
+       std::cout << "t_fftm<T, Impl_op, SD>: ERROR" << std::endl;
+       abort();
+     }
+     
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Impl_ip: In-place Fftm
+ ***********************************************************************/
+ 
+ template <typename T,
+ 	  int      SD>
+ struct t_fftm<T, Impl_ip, SD>
+ {
+   char* what() { return "t_fftm<T, Impl_ip, SD>"; }
+   int ops(length_type rows, length_type cols)
+     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
+ 
+   void fftm(length_type rows, length_type cols, length_type loop, float& time)
+   {
+     Matrix<T>   A(rows, cols, T());
+ 
+     // int const no_times = 0; // FFTW_PATIENT
+     int const no_times = 15; // not > 12 = FFT_MEASURE
+ 
+     typedef Fftm<T, T, SD, fft_fwd, by_reference, no_times, alg_time>
+       fftm_type;
+ 
+     fftm_type fftm(Domain<2>(rows, cols), 1.f);
+ 
+     A = T(0);
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       fftm(A);
+     t1.stop();
+ 
+     A = T(1);
+     fftm(A);
+     
+     if (!equal(A(0, 0), T(SD == row ? cols : rows)))
+     {
+       std::cout << "t_fftm<T, Impl_ip, SD>: ERROR" << std::endl;
+       abort();
+     }
+     
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Impl_pip1: Pseudo In-place Fftm (using in-place Fft)
+ ***********************************************************************/
+ 
+ template <typename T,
+ 	  int      SD>
+ struct t_fftm<T, Impl_pip1, SD>
+ {
+   char* what() { return "t_fftm<T, Impl_ip, SD>"; }
+   int ops(length_type rows, length_type cols)
+     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
+ 
+   void fftm(length_type rows, length_type cols, length_type loop, float& time)
+   {
+     Matrix<T>   A(rows, cols, T());
+ 
+     // int const no_times = 0; // FFTW_PATIENT
+     int const no_times = 15; // not > 12 = FFT_MEASURE
+ 
+     typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times, alg_time>
+       fft_type;
+ 
+     fft_type fft(Domain<1>(SD == row ? cols : rows), 1.f);
+ 
+     A = T(0);
+     
+     vsip::impl::profile::Timer t1;
+     
+     if (SD == row)
+     {
+       t1.start();
+       for (index_type l=0; l<loop; ++l)
+ 	for (index_type i=0; i<rows; ++i)
+ 	  fft(A.row(i));
+       t1.stop();
+ 
+       A = T(1);
+       for (index_type i=0; i<rows; ++i)
+ 	fft(A.row(i));
+     }
+     else
+     {
+       t1.start();
+       for (index_type l=0; l<loop; ++l)
+ 	for (index_type i=0; i<cols; ++i)
+ 	  fft(A.col(i));
+       t1.stop();
+ 
+       A = T(1);
+       for (index_type i=0; i<cols; ++i)
+ 	fft(A.col(i));
+     }
+ 
+     if (!equal(A(0, 0), T(SD == row ? cols : rows)))
+     {
+       std::cout << "t_fftm<T, Impl_ip, SD>: ERROR" << std::endl;
+       abort();
+     }
+     
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Impl_pip2: Pseudo In-place Fftm (using in-place Fft)
+ ***********************************************************************/
+ 
+ template <typename T,
+ 	  int      SD>
+ struct t_fftm<T, Impl_pip2, SD>
+ {
+   char* what() { return "t_fftm<T, Impl_ip, SD>"; }
+   int ops(length_type rows, length_type cols)
+     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
+ 
+   void fftm(length_type rows, length_type cols, length_type loop, float& time)
+   {
+     Matrix<T>   A(rows, cols, T());
+     Vector<T>   tmp(SD == row ? cols : rows);
+ 
+     // int const no_times = 0; // FFTW_PATIENT
+     int const no_times = 15; // not > 12 = FFT_MEASURE
+ 
+     typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times, alg_time>
+       fft_type;
+ 
+     fft_type fft(Domain<1>(SD == row ? cols : rows), 1.f);
+ 
+     A = T(0);
+     
+     vsip::impl::profile::Timer t1;
+     
+     if (SD == row)
+     {
+       t1.start();
+       for (index_type l=0; l<loop; ++l)
+ 	for (index_type i=0; i<rows; ++i)
+ 	{
+ 	  fft(A.row(i), tmp);
+ 	  A.row(i) = tmp;
+ 	}
+       t1.stop();
+ 
+       A = T(1);
+       for (index_type i=0; i<rows; ++i)
+       {
+ 	fft(A.row(i), tmp);
+ 	A.row(i) = tmp;
+       }
+     }
+     else
+     {
+       t1.start();
+       for (index_type l=0; l<loop; ++l)
+ 	for (index_type i=0; i<cols; ++i)
+ 	{
+ 	  fft(A.col(i), tmp);
+ 	  A.col(i) = tmp;
+ 	}
+       t1.stop();
+ 
+       A = T(1);
+       for (index_type i=0; i<cols; ++i)
+       {
+ 	fft(A.col(i), tmp);
+ 	A.col(i) = tmp;
+       }
+     }
+ 
+     if (!equal(A(0, 0), T(SD == row ? cols : rows)))
+     {
+       std::cout << "t_fftm<T, Impl_ip, SD>: ERROR" << std::endl;
+       abort();
+     }
+     
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Fixed rows driver
+ ***********************************************************************/
+ 
+ template <typename T, typename ImplTag, int SD>
+ struct t_fftm_fix_rows : public t_fftm<T, ImplTag, SD>
+ {
+   typedef t_fftm<T, ImplTag, SD> base_type;
+ 
+   char* what() { return "t_fftm_fix_rows"; }
+   int ops_per_point(length_type cols)
+     { return (int)(this->ops(rows_, cols) / cols); }
+   int riob_per_point(length_type) { return -1*sizeof(T); }
+   int wiob_per_point(length_type) { return -1*sizeof(T); }
+ 
+   void operator()(length_type cols, length_type loop, float& time)
+   {
+     this->fftm(rows_, cols, loop, time);
+   }
+ 
+   t_fftm_fix_rows(length_type rows) : rows_(rows) {}
+ 
+ // Member data
+   length_type rows_;
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Fixed cols driver
+ ***********************************************************************/
+ 
+ template <typename T, typename ImplTag, int SD>
+ struct t_fftm_fix_cols : public t_fftm<T, ImplTag, SD>
+ {
+   typedef t_fftm<T, ImplTag, SD> base_type;
+ 
+   char* what() { return "t_fftm_fix_cols"; }
+   int ops_per_point(length_type rows)
+     { return (int)(this->ops(rows, cols_) / rows); }
+   int riob_per_point(length_type) { return -1*sizeof(T); }
+   int wiob_per_point(length_type) { return -1*sizeof(T); }
+ 
+   void operator()(length_type rows, length_type loop, float& time)
+   {
+     this->fftm(rows, cols_, loop, time);
+   }
+ 
+   t_fftm_fix_cols(length_type cols) : cols_(cols) {}
+ 
+ // Member data
+   length_type cols_;
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Fixed cols driver
+ ***********************************************************************/
+ 
+ 
+ void
+ defaults(Loop1P& loop)
+ {
+   loop.start_      = 4;
+   loop.stop_       = 16;
+   loop.loop_start_ = 10;
+   loop.user_param_ = 256;
+ }
+ 
+ 
+ 
+ int
+ test(Loop1P& loop, int what)
+ {
+   length_type p = loop.user_param_;
+ 
+   switch (what)
+   {
+   case  1: loop(t_fftm_fix_rows<complex<float>, Impl_op,   row>(p)); break;
+   case  2: loop(t_fftm_fix_rows<complex<float>, Impl_ip,   row>(p)); break;
+   case  3: loop(t_fftm_fix_rows<complex<float>, Impl_pip1, row>(p)); break;
+   case  4: loop(t_fftm_fix_rows<complex<float>, Impl_pip2, row>(p)); break;
+   case  5: loop(t_fftm_fix_cols<complex<float>, Impl_op,   row>(p)); break;
+   case  6: loop(t_fftm_fix_cols<complex<float>, Impl_ip,   row>(p)); break;
+   case  7: loop(t_fftm_fix_cols<complex<float>, Impl_pip1, row>(p)); break;
+   case  8: loop(t_fftm_fix_cols<complex<float>, Impl_pip2, row>(p)); break;
+ 
+ #if 0
+   case 11: loop(t_fftm_fix_rows<complex<float>, Impl_op,   col>(p)); break;
+   case 12: loop(t_fftm_fix_rows<complex<float>, Impl_ip,   col>(p)); break;
+   case 13: loop(t_fftm_fix_rows<complex<float>, Impl_pip1, col>(p)); break;
+   case 14: loop(t_fftm_fix_rows<complex<float>, Impl_pip2, col>(p)); break;
+   case 15: loop(t_fftm_fix_cols<complex<float>, Impl_op,   col>(p)); break;
+   case 16: loop(t_fftm_fix_cols<complex<float>, Impl_ip,   col>(p)); break;
+   case 17: loop(t_fftm_fix_cols<complex<float>, Impl_pip1, col>(p)); break;
+   case 18: loop(t_fftm_fix_cols<complex<float>, Impl_pip2, col>(p)); break;
+ #endif
+ 
+   default: return 0;
+   }
+   return 1;
+ }
Index: benchmarks/loop.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/loop.hpp,v
retrieving revision 1.7
diff -c -p -r1.7 loop.hpp
*** benchmarks/loop.hpp	13 Dec 2005 20:35:54 -0000	1.7
--- benchmarks/loop.hpp	16 Dec 2005 22:10:32 -0000
*************** public:
*** 55,61 ****
      goal_sec_	(1.0),
      metric_     (pts_per_sec),
      note_       (0),
!     do_prof_    (false)
    {}
  
    template <typename Functor>
--- 55,62 ----
      goal_sec_	(1.0),
      metric_     (pts_per_sec),
      note_       (0),
!     do_prof_    (false),
!     what_       (0)
    {}
  
    template <typename Functor>
*************** public:
*** 77,82 ****
--- 78,84 ----
    char*         note_;
    int           user_param_;
    bool          do_prof_;
+   int           what_;
  };
  
  
*************** Loop1P::operator()(
*** 163,169 ****
  
    if (rank == 0)
    {
!     printf("# what             : %s\n", fcn.what());
      printf("# nproc            : %d\n", nproc);
      printf("# ops_per_point(1) : %d\n", (int)fcn.ops_per_point(1));
      printf("# riob_per_point(1): %d\n", fcn.riob_per_point(1));
--- 165,171 ----
  
    if (rank == 0)
    {
!     printf("# what             : %s (%d)\n", fcn.what(), what_);
      printf("# nproc            : %d\n", nproc);
      printf("# ops_per_point(1) : %d\n", (int)fcn.ops_per_point(1));
      printf("# riob_per_point(1): %d\n", fcn.riob_per_point(1));
Index: benchmarks/main.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/main.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 main.cpp
*** benchmarks/main.cpp	7 Sep 2005 12:19:30 -0000	1.3
--- benchmarks/main.cpp	16 Dec 2005 22:10:32 -0000
*************** main(int argc, char** argv)
*** 76,80 ****
--- 76,82 ----
      std::cout << "sec  = " << loop.goal_sec_ << std::endl;
    }
  
+   loop.what_ = what;
+ 
    test(loop, what);
  }
Index: benchmarks/vmmul.cpp
===================================================================
RCS file: benchmarks/vmmul.cpp
diff -N benchmarks/vmmul.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/vmmul.cpp	16 Dec 2005 22:10:32 -0000
***************
*** 0 ****
--- 1,230 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    benchmarks/vmmul.cpp
+     @author  Jules Bergmann
+     @date    2005-12-14
+     @brief   VSIPL++ Library: Benchmark for vector-matrix multiply.
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
+   Definitions
+ ***********************************************************************/
+ 
+ template <typename T,
+ 	  typename Tag,
+ 	  int      SD>
+ struct t_vmmul;
+ 
+ struct Impl_op;
+ struct Impl_pop;
+ 
+ 
+ 
+ /***********************************************************************
+   Impl_op: Out-of-place vmmul
+ ***********************************************************************/
+ 
+ template <typename T,
+ 	  int      SD>
+ struct t_vmmul<T, Impl_op, SD>
+ {
+   char* what() { return "t_vmmul<T, Impl_op, SD>"; }
+   int ops(length_type rows, length_type cols)
+     { return rows * cols * Ops_info<T>::mul; }
+ 
+   void exec(length_type rows, length_type cols, length_type loop, float& time)
+   {
+     Vector<T>   W(SD == row ? cols : rows);
+     Matrix<T>   A(rows, cols, T());
+     Matrix<T>   Z(rows, cols);
+ 
+     W = ramp(T(1), T(1), W.size());
+     A = T(1);
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       Z = vmmul<SD>(W, A);
+     t1.stop();
+     
+     if (!equal(Z(0, 0), T(1)))
+     {
+       std::cout << "t_vmmul<T, Impl_op, SD>: ERROR" << std::endl;
+       abort();
+     }
+     
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Impl_pop: Psuedo out-of-place vmmul, using vector-multiply
+ ***********************************************************************/
+ 
+ template <typename T,
+ 	  int      SD>
+ struct t_vmmul<T, Impl_pop, SD>
+ {
+   char* what() { return "t_vmmul<T, Impl_op, SD>"; }
+   int ops(length_type rows, length_type cols)
+     { return rows * cols * Ops_info<T>::mul; }
+ 
+   void exec(length_type rows, length_type cols, length_type loop, float& time)
+   {
+     Vector<T>   W(SD == row ? cols : rows);
+     Matrix<T>   A(rows, cols, T());
+     Matrix<T>   Z(rows, cols);
+ 
+     W = ramp(T(1), T(1), W.size());
+     A = T(1);
+     
+     vsip::impl::profile::Timer t1;
+     
+     if (SD == row)
+     {
+       t1.start();
+       for (index_type l=0; l<loop; ++l)
+ 	for (index_type i=0; i<rows; ++i)
+ 	  Z.row(i) = W * A.row(i);
+       t1.stop();
+     }
+     else
+     {
+       t1.start();
+       for (index_type l=0; l<loop; ++l)
+ 	for (index_type i=0; i<cols; ++i)
+ 	  Z.col(i) = W * A.col(i);
+       t1.stop();
+     }
+     
+     if (!equal(Z(0, 0), T(1)))
+     {
+       std::cout << "t_vmmul<T, Impl_op, SD>: ERROR" << std::endl;
+       abort();
+     }
+     
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Fixed rows driver
+ ***********************************************************************/
+ 
+ template <typename T, typename ImplTag, int SD>
+ struct t_vmmul_fix_rows : public t_vmmul<T, ImplTag, SD>
+ {
+   typedef t_vmmul<T, ImplTag, SD> base_type;
+ 
+   char* what() { return "t_vmmul_fix_rows"; }
+   int ops_per_point(length_type cols)
+     { return (int)(this->ops(rows_, cols) / cols); }
+   int riob_per_point(length_type) { return -1*sizeof(T); }
+   int wiob_per_point(length_type) { return -1*sizeof(T); }
+ 
+   void operator()(length_type cols, length_type loop, float& time)
+   {
+     this->exec(rows_, cols, loop, time);
+   }
+ 
+   t_vmmul_fix_rows(length_type rows) : rows_(rows) {}
+ 
+ // Member data
+   length_type rows_;
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Fixed cols driver
+ ***********************************************************************/
+ 
+ template <typename T, typename ImplTag, int SD>
+ struct t_vmmul_fix_cols : public t_vmmul<T, ImplTag, SD>
+ {
+   typedef t_vmmul<T, ImplTag, SD> base_type;
+ 
+   char* what() { return "t_vmmul_fix_cols"; }
+   int ops_per_point(length_type rows)
+     { return (int)(this->ops(rows, cols_) / rows); }
+   int riob_per_point(length_type) { return -1*sizeof(T); }
+   int wiob_per_point(length_type) { return -1*sizeof(T); }
+ 
+   void operator()(length_type rows, length_type loop, float& time)
+   {
+     this->exec(rows, cols_, loop, time);
+   }
+ 
+   t_vmmul_fix_cols(length_type cols) : cols_(cols) {}
+ 
+ // Member data
+   length_type cols_;
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Fixed cols driver
+ ***********************************************************************/
+ 
+ 
+ void
+ defaults(Loop1P& loop)
+ {
+   loop.start_      = 4;
+   loop.stop_       = 16;
+   loop.loop_start_ = 10;
+   loop.user_param_ = 256;
+ }
+ 
+ 
+ 
+ int
+ test(Loop1P& loop, int what)
+ {
+   length_type p = loop.user_param_;
+ 
+   switch (what)
+   {
+   case  1: loop(t_vmmul_fix_rows<complex<float>, Impl_op,   row>(p)); break;
+   case  2: loop(t_vmmul_fix_rows<complex<float>, Impl_pop,  row>(p)); break;
+ 
+   case 11: loop(t_vmmul_fix_cols<complex<float>, Impl_op,   row>(p)); break;
+   case 12: loop(t_vmmul_fix_cols<complex<float>, Impl_pop,  row>(p)); break;
+ 
+   case 21: loop(t_vmmul_fix_rows<complex<float>, Impl_op,   col>(p)); break;
+   case 22: loop(t_vmmul_fix_rows<complex<float>, Impl_pop,  col>(p)); break;
+ 
+   case 31: loop(t_vmmul_fix_cols<complex<float>, Impl_op,   col>(p)); break;
+   case 32: loop(t_vmmul_fix_cols<complex<float>, Impl_pop,  col>(p)); break;
+ 
+   default: return 0;
+   }
+   return 1;
+ }
Index: benchmarks/vmul_ipp.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/vmul_ipp.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 vmul_ipp.cpp
*** benchmarks/vmul_ipp.cpp	28 Aug 2005 02:15:57 -0000	1.1
--- benchmarks/vmul_ipp.cpp	16 Dec 2005 22:10:32 -0000
*************** using namespace vsip;
*** 27,32 ****
--- 27,35 ----
  template <typename T>
  struct t_vmul_ipp;
  
+ template <int X, typename T>
+ struct t_vmul_ipp_ip;
+ 
  template <>
  struct t_vmul_ipp<float>
  {
*************** struct t_vmul_ipp<std::complex<float> >
*** 127,132 ****
--- 130,235 ----
  
  
  
+ template <>
+ struct t_vmul_ipp_ip<1, std::complex<float> >
+ {
+   typedef std::complex<float> T;
+ 
+   char* what() { return "t_vmul_ipp complex<float>"; }
+   int ops_per_point(size_t)  { return Ops_info<T>::mul; }
+   int riob_per_point(size_t) { return 2*sizeof(T); }
+   int wiob_per_point(size_t) { return 1*sizeof(T); }
+ 
+   void operator()(size_t size, size_t loop, float& time)
+   {
+     Ipp32fc* A = ippsMalloc_32fc(size);
+     Ipp32fc* B = ippsMalloc_32fc(size);
+ 
+     if (!A || !B) throw(std::bad_alloc());
+ 
+     for (size_t i=0; i<size; ++i)
+     {
+       A[i].re = 0.f;
+       A[i].im = 0.f;
+       B[i].re = 0.f;
+       B[i].im = 0.f;
+     }
+ 
+     A[0].re = 1.f;
+     B[0].re = 3.f;
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (size_t l=0; l<loop; ++l)
+       ippsMul_32fc(A, B, B, size);
+     t1.stop();
+     
+     if (B[0].re != 3.f)
+     {
+       std::cout << "t_vmul_ipp: ERROR" << std::endl;
+       abort();
+     }
+     
+     time = t1.delta();
+ 
+     ippsFree(B);
+     ippsFree(A);
+   }
+ };
+ 
+ 
+ 
+ template <>
+ struct t_vmul_ipp_ip<2, std::complex<float> >
+ {
+   typedef std::complex<float> T;
+ 
+   char* what() { return "t_vmul_ipp complex<float>"; }
+   int ops_per_point(size_t)  { return Ops_info<T>::mul; }
+   int riob_per_point(size_t) { return 2*sizeof(T); }
+   int wiob_per_point(size_t) { return 1*sizeof(T); }
+ 
+   void operator()(size_t size, size_t loop, float& time)
+   {
+     Ipp32fc* A = ippsMalloc_32fc(size);
+     Ipp32fc* B = ippsMalloc_32fc(size);
+ 
+     if (!A || !B) throw(std::bad_alloc());
+ 
+     for (size_t i=0; i<size; ++i)
+     {
+       A[i].re = 0.f;
+       A[i].im = 0.f;
+       B[i].re = 0.f;
+       B[i].im = 0.f;
+     }
+ 
+     A[0].re = 1.f;
+     B[0].re = 3.f;
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (size_t l=0; l<loop; ++l)
+       ippsMul_32fc_I(A, B, size);
+     t1.stop();
+     
+     if (B[0].re != 3.f)
+     {
+       std::cout << "t_vmul_ipp: ERROR" << std::endl;
+       abort();
+     }
+     
+     time = t1.delta();
+ 
+     ippsFree(B);
+     ippsFree(A);
+   }
+ };
+ 
+ 
+ 
  void
  defaults(Loop1P&)
  {
*************** test(Loop1P& loop, int what)
*** 141,145 ****
--- 244,251 ----
    {
    case  1: loop(t_vmul_ipp<float>()); break;
    case  2: loop(t_vmul_ipp<std::complex<float> >()); break;
+ 
+   case  12: loop(t_vmul_ipp_ip<1, std::complex<float> >()); break;
+   case  22: loop(t_vmul_ipp_ip<2, std::complex<float> >()); break;
    }
  }
Index: src/vsip/impl/dist.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/dist.hpp,v
retrieving revision 1.11
diff -c -p -r1.11 dist.hpp
*** src/vsip/impl/dist.hpp	5 Dec 2005 19:19:18 -0000	1.11
--- src/vsip/impl/dist.hpp	16 Dec 2005 22:10:32 -0000
*************** class Whole_dist
*** 229,234 ****
--- 229,239 ----
    // Constructors and destructor.
  public:
    Whole_dist() VSIP_NOTHROW {}
+ 
+   // This constructor allows users to construct maps without having
+   // explicitly say 'Whole_dist()'.
+   Whole_dist(length_type n_sb) VSIP_NOTHROW { assert(n_sb == 1); }
+ 
    ~Whole_dist() VSIP_NOTHROW {}
    
    // Default copy constructor and assignment are fine.
