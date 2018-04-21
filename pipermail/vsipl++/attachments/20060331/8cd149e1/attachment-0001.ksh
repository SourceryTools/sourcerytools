Index: benchmarks/fastconv.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/fastconv.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 fastconv.cpp
*** benchmarks/fastconv.cpp	7 Mar 2006 20:09:35 -0000	1.4
--- benchmarks/fastconv.cpp	31 Mar 2006 18:38:33 -0000
***************
*** 17,42 ****
  #include <vsip/support.hpp>
  #include <vsip/math.hpp>
  #include <vsip/signal.hpp>
- #include <vsip/impl/profile.hpp>
- #include <vsip/impl/par-foreach.hpp>
  
! #include "test.hpp"
! #include "loop.hpp"
  
  using namespace vsip;
  
  
  
  /***********************************************************************
    Common definitions
  ***********************************************************************/
  
- int
- fft_ops(length_type len)
- {
-   return int(5 * std::log((float)len) / std::log(2.f));
- }
- 
  template <typename T,
  	  typename ImplTag>
  struct t_fastconv_base;
--- 17,39 ----
  #include <vsip/support.hpp>
  #include <vsip/math.hpp>
  #include <vsip/signal.hpp>
  
! #include "benchmarks.hpp"
  
  using namespace vsip;
  
  
+ #ifdef VSIP_IMPL_SOURCERY_VPP
+ #  define PARALLEL_FASTCONV 1
+ #else
+ #  define PARALLEL_FASTCONV 0
+ #endif
+ 
  
  /***********************************************************************
    Common definitions
  ***********************************************************************/
  
  template <typename T,
  	  typename ImplTag>
  struct t_fastconv_base;
*************** struct t_fastconv_base<T, Impl1op> : fas
*** 74,79 ****
--- 71,77 ----
    void fastconv(length_type npulse, length_type nrange,
  		length_type loop, float& time)
    {
+ #if PARALLEL_FASTCONV
      typedef Map<Block_dist, Whole_dist>      map_type;
      typedef Dense<2, T, row2_type, map_type> block_type;
      typedef Matrix<T, block_type>            view_type;
*************** struct t_fastconv_base<T, Impl1op> : fas
*** 87,92 ****
--- 85,97 ----
      // Create the data cube.
      view_type data(npulse, nrange, map);
      view_type tmp(npulse, nrange, map);
+ #else
+     typedef Matrix<T>  view_type;
+     typedef Vector<T>  replica_view_type;
+ 
+     view_type data(npulse, nrange);
+     view_type tmp(npulse, nrange);
+ #endif
      
      // Create the pulse replica
      replica_view_type replica(nrange);
*************** struct t_fastconv_base<T, Impl1pip2> : f
*** 258,263 ****
--- 263,269 ----
    void fastconv(length_type npulse, length_type nrange,
  		length_type loop, float& time)
    {
+ #if PARALLEL_FASTCONV
      typedef Map<Block_dist, Whole_dist>      map_type;
      typedef Dense<2, T, row2_type, map_type> block_type;
      typedef Matrix<T, block_type>            view_type;
*************** struct t_fastconv_base<T, Impl1pip2> : f
*** 270,276 ****
  
      // Create the data cube.
      view_type data(npulse, nrange, map);
!     
      // Create the pulse replica
      Vector<T> tmp(nrange);
      replica_view_type replica(nrange);
--- 276,288 ----
  
      // Create the data cube.
      view_type data(npulse, nrange, map);
! #else
!     typedef Matrix<T>  view_type;
!     typedef Vector<T>  replica_view_type;
! 
!     view_type data(npulse, nrange);
! #endif
! 
      // Create the pulse replica
      Vector<T> tmp(nrange);
      replica_view_type replica(nrange);
*************** struct t_fastconv_base<T, Impl1pip2> : f
*** 302,320 ****
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
!       typename view_type::local_type         l_data    = data.local();
!       typename replica_view_type::local_type l_replica = replica.local();
!       length_type                            l_npulse  = l_data.size(0);
        for (index_type p=0; p<l_npulse; ++p)
        {
! 	for_fft(l_data.row(p), tmp);
! 	l_data.row(p) = tmp;
        }
!       l_data = vmmul<0>(l_replica, l_data);
        for (index_type p=0; p<l_npulse; ++p)
        {
! 	inv_fft(l_data.row(p), tmp);
! 	l_data.row(p) = tmp;
        }
      }
      t1.stop();
--- 314,330 ----
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
!       length_type l_npulse  = LOCAL(data).size(0);
        for (index_type p=0; p<l_npulse; ++p)
        {
! 	for_fft(LOCAL(data).row(p), tmp);
! 	LOCAL(data).row(p) = tmp;
        }
!       LOCAL(data) = vmmul<0>(LOCAL(replica), LOCAL(data));
        for (index_type p=0; p<l_npulse; ++p)
        {
! 	inv_fft(LOCAL(data).row(p), tmp);
! 	LOCAL(data).row(p) = tmp;
        }
      }
      t1.stop();
*************** struct t_fastconv_base<T, Impl2op> : fas
*** 395,400 ****
--- 405,411 ----
    void fastconv(length_type npulse, length_type nrange,
  		length_type loop, float& time)
    {
+ #if PARALLEL_FASTCONV
      typedef Map<Block_dist, Whole_dist>      map_type;
      typedef Dense<2, T, row2_type, map_type> block_type;
      typedef Matrix<T, block_type>            view_type;
*************** struct t_fastconv_base<T, Impl2op> : fas
*** 407,412 ****
--- 418,429 ----
  
      // Create the data cube.
      view_type data(npulse, nrange, map);
+ #else
+     typedef Matrix<T>  view_type;
+     typedef Vector<T>  replica_view_type;
+ 
+     view_type data(npulse, nrange);
+ #endif
      Vector<T> tmp(nrange);
      
      // Create the pulse replica
*************** struct t_fastconv_base<T, Impl2op> : fas
*** 438,451 ****
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
!       typename view_type::local_type         l_data    = data.local();
!       typename replica_view_type::local_type l_replica = replica.local();
!       length_type                            l_npulse  = l_data.size(0);
        for (index_type p=0; p<l_npulse; ++p)
        {
! 	for_fft(l_data.row(p), tmp);
! 	tmp *= l_replica;
! 	inv_fft(tmp, l_data.row(p));
        }
      }
      t1.stop();
--- 455,466 ----
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
!       length_type l_npulse  = LOCAL(data).size(0);
        for (index_type p=0; p<l_npulse; ++p)
        {
! 	for_fft(LOCAL(data).row(p), tmp);
! 	tmp *= LOCAL(replica);
! 	inv_fft(tmp, LOCAL(data).row(p));
        }
      }
      t1.stop();
*************** struct t_fastconv_base<T, Impl2ip> : fas
*** 467,472 ****
--- 482,488 ----
    void fastconv(length_type npulse, length_type nrange,
  		length_type loop, float& time)
    {
+ #if PARALLEL_FASTCONV
      typedef Map<Block_dist, Whole_dist>      map_type;
      typedef Dense<2, T, row2_type, map_type> block_type;
      typedef Matrix<T, block_type>            view_type;
*************** struct t_fastconv_base<T, Impl2ip> : fas
*** 479,486 ****
  
      // Create the data cube.
      view_type data(npulse, nrange, map);
-     // Vector<T> tmp(nrange);
      
      // Create the pulse replica
      replica_view_type replica(nrange);
  
--- 495,508 ----
  
      // Create the data cube.
      view_type data(npulse, nrange, map);
      
+ #else
+     typedef Matrix<T>  view_type;
+     typedef Vector<T>  replica_view_type;
+ 
+     view_type data(npulse, nrange);
+ #endif
+ 
      // Create the pulse replica
      replica_view_type replica(nrange);
  
*************** struct t_fastconv_base<T, Impl2ip> : fas
*** 510,523 ****
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
!       typename view_type::local_type         l_data    = data.local();
!       typename replica_view_type::local_type l_replica = replica.local();
!       length_type                            l_npulse  = l_data.size(0);
        for (index_type p=0; p<l_npulse; ++p)
        {
! 	for_fft(l_data.row(p));
! 	l_data.row(p) *= l_replica;
! 	inv_fft(l_data.row(p));
        }
      }
      t1.stop();
--- 532,543 ----
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
!       length_type l_npulse  = LOCAL(data).size(0);
        for (index_type p=0; p<l_npulse; ++p)
        {
! 	for_fft(LOCAL(data).row(p));
! 	LOCAL(data).row(p) *= LOCAL(replica);
! 	inv_fft(LOCAL(data).row(p));
        }
      }
      t1.stop();
*************** struct t_fastconv_base<T, Impl2ip_tmp> :
*** 539,544 ****
--- 559,565 ----
    void fastconv(length_type npulse, length_type nrange,
  		length_type loop, float& time)
    {
+ #if PARALLEL_FASTCONV
      typedef Map<Block_dist, Whole_dist>      map_type;
      typedef Dense<2, T, row2_type, map_type> block_type;
      typedef Matrix<T, block_type>            view_type;
*************** struct t_fastconv_base<T, Impl2ip_tmp> :
*** 551,556 ****
--- 572,584 ----
  
      // Create the data cube.
      view_type data(npulse, nrange, map);
+ 
+ #else
+     typedef Matrix<T>  view_type;
+     typedef Vector<T>  replica_view_type;
+ 
+     view_type data(npulse, nrange);
+ #endif
      Vector<T> tmp(nrange);
      
      // Create the pulse replica
*************** struct t_fastconv_base<T, Impl2ip_tmp> :
*** 582,597 ****
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
!       typename view_type::local_type         l_data    = data.local();
!       typename replica_view_type::local_type l_replica = replica.local();
!       length_type                            l_npulse  = l_data.size(0);
        for (index_type p=0; p<l_npulse; ++p)
        {
! 	tmp = l_data.row(p);
  	for_fft(tmp);
! 	tmp *= l_replica;
  	inv_fft(tmp);
! 	l_data.row(p) = tmp;
        }
      }
      t1.stop();
--- 610,623 ----
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
!       length_type l_npulse  = LOCAL(data).size(0);
        for (index_type p=0; p<l_npulse; ++p)
        {
! 	tmp = LOCAL(data).row(p);
  	for_fft(tmp);
! 	tmp *= LOCAL(replica);
  	inv_fft(tmp);
! 	LOCAL(data).row(p) = tmp;
        }
      }
      t1.stop();
*************** struct t_fastconv_base<T, Impl2ip_tmp> :
*** 606,611 ****
--- 632,638 ----
  /***********************************************************************
    Impl2fv: foreach_vector, interleaved fast-convolution
  ***********************************************************************/
+ #if PARALLEL_FASTCONV
  
  template <typename T>
  class Fast_convolution
*************** private:
*** 652,658 ****
  };
  
  
- 
  template <typename T>
  struct t_fastconv_base<T, Impl2fv> : fastconv_ops
  {
--- 679,684 ----
*************** struct t_fastconv_base<T, Impl2fv> : fas
*** 681,696 ****
      
      t1.start();
      for (index_type l=0; l<loop; ++l)
-     {
        foreach_vector<tuple<0, 1> >(fconv, data);
-     }
      t1.stop();
  
      // CHECK RESULT
      time = t1.delta();
    }
  };
! 
  
  
  /***********************************************************************
--- 707,720 ----
      
      t1.start();
      for (index_type l=0; l<loop; ++l)
        foreach_vector<tuple<0, 1> >(fconv, data);
      t1.stop();
  
      // CHECK RESULT
      time = t1.delta();
    }
  };
! #endif // PARALLEL_FASTCONV
  
  
  /***********************************************************************
*************** test(Loop1P& loop, int what)
*** 772,778 ****
--- 796,804 ----
    case  5: loop(t_fastconv_pf<complex<float>, Impl2op>(param1)); break;
    case  6: loop(t_fastconv_pf<complex<float>, Impl2ip>(param1)); break;
    case  7: loop(t_fastconv_pf<complex<float>, Impl2ip_tmp>(param1)); break;
+ #if PARALLEL_FASTCONV
    case  8: loop(t_fastconv_pf<complex<float>, Impl2fv>(param1)); break;
+ #endif
  
    case  9: loop(t_fastconv_pf<complex<float>, Impl1pip2_nopar>(param1)); break;
  
*************** test(Loop1P& loop, int what)
*** 783,789 ****
--- 809,817 ----
    case 15: loop(t_fastconv_rf<complex<float>, Impl2op>(param1)); break;
    case 16: loop(t_fastconv_rf<complex<float>, Impl2ip>(param1)); break;
    case 17: loop(t_fastconv_rf<complex<float>, Impl2ip_tmp>(param1)); break;
+ #if PARALLEL_FASTCONV
    case 18: loop(t_fastconv_rf<complex<float>, Impl2fv>(param1)); break;
+ #endif
  
    default: return 0;
    }
Index: benchmarks/loop.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/loop.hpp,v
retrieving revision 1.13
diff -c -p -r1.13 loop.hpp
*** benchmarks/loop.hpp	24 Mar 2006 12:36:05 -0000	1.13
--- benchmarks/loop.hpp	31 Mar 2006 18:39:10 -0000
***************
*** 17,23 ****
  #include <algorithm>
  #include <vector>
  
- //#include <vsip/impl/profile.hpp>
  #include <vsip/vector.hpp>
  #include <vsip/math.hpp>
  
--- 17,22 ----
*************** Loop1P::sweep(Functor fcn)
*** 182,189 ****
    using vsip::Index;
    using vsip::Vector;
    using vsip::Dense;
-   using vsip::Map;
-   using vsip::Global_map;
    using vsip::row1_type;
  
    size_t   loop, M;
--- 181,186 ----
*************** Loop1P::sweep(Functor fcn)
*** 198,203 ****
--- 195,202 ----
    std::vector<float> mtime(n_time);
  
  #if PARALLEL_LOOP
+   using vsip::Map;
+   using vsip::Global_map;
    Vector<float, Dense<1, float, row1_type, Map<> > >
      dist_time(nproc, Map<>(nproc));
    Vector<float, Dense<1, float, row1_type, Global_map<1> > > glob_time(nproc);
*************** Loop1P::steady(Functor fcn)
*** 342,349 ****
    using vsip::Index;
    using vsip::Vector;
    using vsip::Dense;
-   using vsip::Map;
-   using vsip::Global_map;
    using vsip::row1_type;
  
    size_t   loop, M;
--- 341,346 ----
*************** Loop1P::steady(Functor fcn)
*** 354,359 ****
--- 351,358 ----
    PROCESSOR_TYPE    nproc = NUM_PROCESSORS();
  
  #if PARALLEL_LOOP
+   using vsip::Map;
+   using vsip::Global_map;
    Vector<float, Dense<1, float, row1_type, Map<> > >
      dist_time(nproc, Map<>(nproc));
    Vector<float, Dense<1, float, row1_type, Global_map<1> > > glob_time(nproc);
