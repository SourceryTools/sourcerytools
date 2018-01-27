Index: benchmarks/benchmarks.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/benchmarks.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 benchmarks.hpp
*** benchmarks/benchmarks.hpp	21 Mar 2006 15:53:09 -0000	1.1
--- benchmarks/benchmarks.hpp	2 Apr 2006 20:04:07 -0000
***************
*** 18,29 ****
  // Sourcery VSIPL++ provides certain resources such as system 
  // timers that are needed for running the benchmarks.
  
  #include <vsip/impl/profile.hpp>
! #include <../tests/test.hpp>
  
  #else
  
! // when linking with non-sourcery versions of the lib, the
  // definitions below provide a minimal set of these resources.
  
  #include <time.h>
--- 18,33 ----
  // Sourcery VSIPL++ provides certain resources such as system 
  // timers that are needed for running the benchmarks.
  
+ #include <vsip/impl/par-foreach.hpp>
  #include <vsip/impl/profile.hpp>
! #include <vsip_csl/load_view.hpp>
! #include <vsip_csl/test.hpp>
! 
! using namespace vsip_csl;
  
  #else
  
! // When linking with non-Sourcery versions of the lib, the
  // definitions below provide a minimal set of these resources.
  
  #include <time.h>
*************** typedef P_acc_timer<DefaultTime> Acc_tim
*** 135,141 ****
  
  
  
- 
  /// Compare two floating-point values for equality.
  ///
  /// Algorithm from:
--- 139,144 ----
Index: benchmarks/firbank.cpp
===================================================================
RCS file: benchmarks/firbank.cpp
diff -N benchmarks/firbank.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/firbank.cpp	2 Apr 2006 20:04:22 -0000
***************
*** 0 ****
--- 1,489 ----
+ /* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+ 
+ /** @file    firbank.cpp
+     @author  Don McCoy
+     @date    2006-01-26
+     @brief   VSIPL++ Library: FIR Filter Bank - High Performance 
+              Embedded Computing (HPEC) Kernel-Level Benchmarks
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <iostream>
+ #include <string>
+ 
+ #include <vsip/initfin.hpp>
+ #include <vsip/support.hpp>
+ #include <vsip/map.hpp>
+ #include <vsip/math.hpp>
+ #include <vsip/signal.hpp>
+ 
+ #include "benchmarks.hpp"
+ 
+ using namespace vsip;
+ 
+ 
+ #ifdef VSIP_IMPL_SOURCERY_VPP
+ #  define PARALLEL_FIRBANK 1
+ #else
+ #  define PARALLEL_FIRBANK 0
+ #endif
+ 
+ 
+ /***********************************************************************
+   Common definitions
+ ***********************************************************************/
+ 
+ template <typename T,
+ 	  typename ImplTag>
+ struct t_firbank_base;
+ 
+ struct ImplFull;	   // Time-domain convolution using Fir class
+ struct ImplFast;	   // Fast convolution using FFT's
+ 
+ 
+ template <typename T>
+ struct t_local_view
+ {
+   template <
+     typename Block1,
+     typename Block2,
+     typename Block3,
+     typename Block4
+     >
+   void verify_views(
+     Matrix<T, Block1> inputs,
+     Matrix<T, Block2> filters,
+     Matrix<T, Block3> outputs,
+     Matrix<T, Block4> expected )
+   {
+ #if PARALLEL_FIRBANK
+     // Check that dim-1 is not distributed
+     typename Block1::map_type const& map1 = inputs.block().map();
+     typename Block2::map_type const& map2 = filters.block().map();
+     typename Block3::map_type const& map3 = outputs.block().map();
+     typename Block4::map_type const& map4 = outputs.block().map();
+ 
+     assert(map1.num_subblocks(1) == 1);
+     assert(map2.num_subblocks(1) == 1);
+     assert(map3.num_subblocks(1) == 1);
+     assert(map4.num_subblocks(1) == 1);
+ 
+     // Check that mappings are the same
+     assert(map1.distribution(0) == map2.distribution(0));
+     assert(map2.distribution(0) == map3.distribution(0));
+     assert(map3.distribution(0) == map4.distribution(0));
+     assert(map4.distribution(0) == map1.distribution(0));
+ #endif
+ 
+     // Also check that local views are the same size
+     assert(LOCAL(inputs).size(0) == LOCAL(filters).size(0)); 
+     assert(LOCAL(filters).size(0) == LOCAL(outputs).size(0)); 
+     assert(LOCAL(outputs).size(0) == LOCAL(expected).size(0)); 
+     assert(LOCAL(expected).size(0) == LOCAL(inputs).size(0)); 
+   }
+ };
+ 
+ 
+ /***********************************************************************
+   ImplFull: built-in FIR 
+ ***********************************************************************/
+ 
+ template <typename T>
+ struct t_firbank_base<T, ImplFull> : public t_local_view<T>
+ {
+   float ops(length_type filters, length_type points, length_type coeffs)
+   {
+     float total_ops = filters * points * coeffs *
+                   (Ops_info<T>::mul + Ops_info<T>::add); 
+     return total_ops;
+   }
+ 
+   template <
+     typename Block1,
+     typename Block2,
+     typename Block3,
+     typename Block4
+     >
+   void firbank(
+     Matrix<T, Block1> inputs,
+     Matrix<T, Block2> filters,
+     Matrix<T, Block3> outputs,
+     Matrix<T, Block4> expected,
+     length_type       loop,
+     float&            time)
+   {
+     this->verify_views(inputs, filters, outputs, expected);
+ 
+     // Create fir filters
+     length_type local_M = LOCAL(inputs).size(0);
+     length_type N = inputs.row(0).size();
+ 
+     typedef Fir<T, nonsym, state_no_save, 1> fir_type;
+     fir_type* fir[local_M];
+     for ( length_type i = 0; i < local_M; ++i )
+       fir[i] = new fir_type(LOCAL(filters).row(i), N, 1);
+ 
+ 
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+     {
+       // Perform FIR convolutions
+       for ( length_type i = 0; i < local_M; ++i )
+         (*fir[i])( LOCAL(inputs).row(i), LOCAL(outputs).row(i) );
+     }
+     t1.stop();
+     time = t1.delta();
+ 
+     // Verify data
+     assert( view_equal(LOCAL(outputs), LOCAL(expected)) );
+ 
+     // Clean up
+     for ( length_type i = 0; i < local_M; ++i )
+       delete fir[i];
+   }
+ 
+   t_firbank_base(length_type filters, length_type coeffs)
+    : m_(filters), k_(coeffs) {}
+ 
+ public:
+   // Member data
+   length_type const m_;
+   length_type const k_;
+ };
+ 
+ 
+ /***********************************************************************
+   ImplFast: fast convolution using FFT's
+ ***********************************************************************/
+ 
+ template <typename T>
+ struct t_firbank_base<T, ImplFast> : public t_local_view<T>
+ {
+   float fft_ops(length_type len)
+   {
+     return float(5 * len * std::log(float(len)) / std::log(float(2)));
+   }
+ 
+   float ops(length_type filters, length_type points, length_type coeffs)
+   {
+     // This not used because the coefficients are zero-padded to the 
+     // length of the inputs.
+     coeffs = 0;
+ 
+     return float(
+       filters * ( 
+         2 * fft_ops(points) +       // one forward, one reverse FFT
+         Ops_info<T>::mul * points   // element-wise vector multiply
+       )
+     );
+   }
+ 
+   template <
+     typename Block1,
+     typename Block2,
+     typename Block3,
+     typename Block4
+     >
+   void firbank(
+     Matrix<T, Block1> inputs,
+     Matrix<T, Block2> filters,
+     Matrix<T, Block3> outputs,
+     Matrix<T, Block4> expected,
+     length_type       loop,
+     float&            time)
+   {
+     this->verify_views(inputs, filters, outputs, expected);
+ 
+     // Create FFT objects
+     length_type N = inputs.row(0).size();
+     length_type scale = 1;
+ 
+     typedef Fft<const_Vector, T, T, fft_fwd, by_reference> fwd_fft_type;
+     typedef Fft<const_Vector, T, T, fft_inv, by_reference> inv_fft_type;
+ 
+     fwd_fft_type fwd_fft(Domain<1>(N), scale);
+     inv_fft_type inv_fft(Domain<1>(N), scale / float(N));
+ 
+     // Copy the filters and zero pad to same length as inputs
+     length_type K = this->k_;
+     length_type local_M = LOCAL(inputs).size(0);
+ 
+     Matrix<T> response(local_M, N, T());
+     response(Domain<2>(local_M, K)) = LOCAL(filters); 
+ 
+     // Pre-compute the FFT on the filters
+     for ( length_type i = 0; i < local_M; ++i )
+       fwd_fft(response.row(i));
+ 
+ 
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+     {
+       // Perform FIR convolutions
+       Vector<T> tmp(N);
+       for ( length_type i = 0; i < local_M; ++i )
+       {
+         fwd_fft(LOCAL(inputs).row(i), tmp);
+         tmp *= response.row(0);    // assume fft already done on response
+         inv_fft(tmp, LOCAL(outputs).row(i)); 
+       }
+     }
+     t1.stop();
+     time = t1.delta();
+ 
+     // Verify data - ignore values that overlap due to circular convolution. 
+     // This means 'k-1' values at either end of each vector.
+     if ( N > 2*(K-1) )
+     {
+       vsip::Domain<2> middle( Domain<1>(local_M), Domain<1>(K-1, 1, N-2*(K-1)) );
+       assert( view_equal(outputs.local()(middle), expected.local()(middle)) );
+     }
+   }
+ 
+   t_firbank_base(length_type filters, length_type coeffs)
+    : m_(filters), k_(coeffs) {}
+ 
+ public:
+   // Member data
+   length_type const m_;
+   length_type const k_;
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Generic front-end for varying input vector lengths 
+ ***********************************************************************/
+ 
+ template <typename T, typename ImplTag>
+ struct t_firbank_sweep_n : public t_firbank_base<T, ImplTag>
+ {
+   char* what() { return "t_firbank_sweep_n"; }
+   int ops_per_point(length_type size)
+     { return (int)(this->ops(this->m_, size, this->k_) / size); }
+   int riob_per_point(length_type) { return -1*sizeof(T); }
+   int wiob_per_point(length_type) { return -1*sizeof(T); }
+   int mem_per_point(length_type)  { return 2*sizeof(T); }
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+ #if PARALLEL_FIRBANK
+     typedef Map<Block_dist, Whole_dist>      map_type;
+     typedef Dense<2, T, row2_type, map_type> block_type;
+     typedef Matrix<T, block_type>            view_type;
+ 
+     processor_type np = num_processors();
+     map_type map = map_type(Block_dist(np), Whole_dist());
+ 
+     view_type inputs(this->m_, size, map);
+     view_type filters(this->m_, this->k_, map);
+     view_type outputs(this->m_, size, map);
+     view_type expected(this->m_, size, map);
+ #else
+     typedef Matrix<T>  view_type;
+ 
+     view_type inputs(this->m_, size);
+     view_type filters(this->m_, this->k_);
+     view_type outputs(this->m_, size);
+     view_type expected(this->m_, size);
+ #endif
+ 
+     // Initialize
+     inputs = T();
+     filters = T();
+     outputs = T();
+     expected = T();
+ 
+     // Create some test data
+     inputs.row(0).put(0, 1);       filters.row(0).put(0, 1);
+     inputs.row(0).put(1, 2);       filters.row(0).put(1, 1);
+     inputs.row(0).put(2, 3);
+     inputs.row(0).put(3, 4);
+ 
+     expected.row(0).put(0, 1);
+     expected.row(0).put(1, 3);
+     expected.row(0).put(2, 5);
+     expected.row(0).put(3, 7);
+     expected.row(0).put(4, 4);
+ 
+ 
+     // Run the test and time it
+     this->firbank( LOCAL(inputs), LOCAL(filters), LOCAL(outputs),
+       LOCAL(expected), loop, time );
+   }
+ 
+   t_firbank_sweep_n(length_type filters, length_type coeffs)
+    : t_firbank_base<T, ImplTag>::t_firbank_base(filters, coeffs) {}
+ };
+ 
+ 
+ #if PARALLEL_FIRBANK
+ /***********************************************************************
+   Generic front-end for using external data
+ ***********************************************************************/
+ 
+ template <typename T, typename ImplTag>
+ struct t_firbank_from_file : public t_firbank_base<T, ImplTag>
+ {
+   char* what() { return "t_firbank_from_file"; }
+   int ops_per_point(length_type size)
+     { return (int)(this->ops(this->m_, size, this->k_) / size); }
+   int riob_per_point(length_type) { return -1*sizeof(T); }
+   int wiob_per_point(length_type) { return -1*sizeof(T); }
+   int mem_per_point(length_type)  { return 2*sizeof(T); }
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+     // Perform file I/O to obtain input data, the filter (one copy 
+     // is replicated for each row) and the output data.  Output
+     // data is compared against the calculated convolution data
+     // after the benchmark has been run.
+ 
+     // Create a "root" view for each that will give the first
+     // processor access to all of the data.  
+     typedef Map<Block_dist, Block_dist>           root_map_type;
+     typedef Dense<2, T, row2_type, root_map_type> root_block_type;
+     typedef Matrix<T, root_block_type>            root_view_type;
+ 
+     // A processor set with one processor in it is used to create 
+     // a map with 1 subblock
+     Vector<processor_type> pset0(1);
+     pset0(0) = processor_set()(0);
+     root_map_type root_map(pset0, 1, 1);
+ 
+     root_view_type inputs_root (this->m_, size,     root_map);
+     root_view_type filters_root(this->m_, this->k_, root_map);
+     root_view_type expected_root(this->m_, size,     root_map);
+ 
+ 
+     // Only the root processor need perform file I/O
+     if (root_map.subblock() != no_subblock)
+     {
+       // Initialize
+       inputs_root.local() = T();
+       filters_root.local() = T();
+       expected_root.local() = T();
+       
+       // read in inputs, filters and outputs
+       std::ostringstream input_file;
+       std::ostringstream filter_file;
+       std::ostringstream output_file;
+ 
+       length_type log2_size = 1;
+       while ( ++log2_size < 32 )
+         if ( static_cast<length_type>(1 << log2_size) == size )
+           break;
+ 
+       input_file << this->directory_ << "/inputs_" << log2_size << ".matrix";
+       filter_file << this->directory_ << "/filters.matrix";
+       output_file << this->directory_ << "/outputs_" << log2_size << ".matrix";
+     
+       Load_view<2, T> load_inputs (input_file.str().c_str(), 
+         Domain<2>(this->m_, size));
+       Load_view<2, T> load_filters(filter_file.str().c_str(), 
+         Domain<2>(this->m_, this->k_));
+       Load_view<2, T> load_outputs(output_file.str().c_str(), 
+         Domain<2>(this->m_, size));
+ 
+       inputs_root.local() = load_inputs.view();
+       filters_root.local() = load_filters.view();
+       expected_root.local() = load_outputs.view();
+     }
+ 
+ 
+     // Create the distributed views that will give each processor a 
+     // subset of the data
+     typedef Map<Block_dist, Whole_dist>      map_type;
+     typedef Dense<2, T, row2_type, map_type> block_type;
+     typedef Matrix<T, block_type>            view_type;
+ 
+     processor_type np = num_processors();
+     map_type map = map_type(Block_dist(np), Whole_dist());
+ 
+     view_type inputs  (this->m_, size,     map);
+     view_type filters (this->m_, this->k_, map);
+     view_type outputs (this->m_, size,     map);
+     view_type expected(this->m_, size,     map);
+ 
+     inputs = inputs_root;
+     filters = filters_root;
+     outputs = T();
+     expected = expected_root; 
+ 
+ 
+     // Run the test and time it
+     this->firbank( inputs.local(), filters.local(), outputs.local(), 
+       expected.local(), loop, time );
+   }
+ 
+   t_firbank_from_file(length_type m, length_type k, char * directory )
+    : t_firbank_base<T, ImplTag>::t_firbank_base(m, k),
+      directory_(directory)
+     {}
+ 
+   // data
+ private:
+   char * directory_;
+ };
+ #endif // PARALLEL_FIRBANK
+ 
+ 
+ 
+ void
+ defaults(Loop1P& loop)
+ {
+   loop.cal_        = 7;
+   loop.start_      = 7;
+   loop.stop_       = 15;
+   loop.loop_start_ = 100;
+   loop.user_param_ = 64;
+ }
+ 
+ 
+ 
+ int
+ test(Loop1P& loop, int what)
+ {
+   switch (what)
+   {
+   case  1: loop(
+     t_firbank_sweep_n<complex<float>, ImplFull>(64, 128));
+     break;
+   case  2: loop(
+     t_firbank_sweep_n<complex<float>, ImplFull>(20,  12));
+     break;
+   case  11: loop(
+     t_firbank_sweep_n<complex<float>, ImplFast>(64, 128));
+     break;
+   case  12: loop(
+     t_firbank_sweep_n<complex<float>, ImplFast>(20,  12));
+     break;
+ 
+ #if PARALLEL_FIRBANK
+   case  21: loop(
+     t_firbank_from_file<complex<float>, ImplFull> (64, 128, "data/set1"));
+     break;
+   case  22: loop(
+     t_firbank_from_file<complex<float>, ImplFull> (20,  12, "data/set2"));
+     break;
+   case  31: loop(
+     t_firbank_from_file<complex<float>, ImplFast> (64, 128, "data/set1"));
+     break;
+   case  32: loop(
+     t_firbank_from_file<complex<float>, ImplFast> (20,  12, "data/set2"));
+     break;
+ #endif
+ 
+   default: 
+     return 0;
+   }
+   return 1;
+ }
+  
Index: benchmarks/loop.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/loop.hpp,v
retrieving revision 1.13
diff -c -p -r1.13 loop.hpp
*** benchmarks/loop.hpp	24 Mar 2006 12:36:05 -0000	1.13
--- benchmarks/loop.hpp	2 Apr 2006 20:04:33 -0000
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
*** tests/test.hpp	2006-03-06 18:15:23.000000000 -0800
--- src/vsip_csl/test.hpp	2006-04-02 11:46:56.337799000 -0700
***************
*** 1,14 ****
! /* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
  
! /** @file    tests/test.hpp
      @author  Jules Bergmann
!     @date    01/25/2005
!     @brief   VSIPL++ Library: Common declarations and defintions for
!              testing.
  */
  
! #ifndef VSIP_TESTS_TEST_HPP
! #define VSIP_TESTS_TEST_HPP
  
  /***********************************************************************
    Included Files
--- 1,14 ----
! /* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
  
! /** @file    vsip_csl/test.hpp
      @author  Jules Bergmann
!     @date    2005-01-25
!     @brief   VSIPL++ CodeSourcery Library: Common declarations and 
!              defintions for testing.
  */
  
! #ifndef VSIP_CSL_TEST_HPP
! #define VSIP_CSL_TEST_HPP
  
  /***********************************************************************
    Included Files
***************
*** 24,29 ****
--- 24,33 ----
  #include <vsip/tensor.hpp>
  
  
+ 
+ namespace vsip_csl
+ {
+ 
  /***********************************************************************
    Definitions
  ***********************************************************************/
*************** test_assert_fail(
*** 264,269 ****
  		     (test_assert_fail(__TEST_STRING(expr), __FILE__, __LINE__, \
  				       TEST_ASSERT_FUNCTION), 0)))
  
  
! 
! #endif // VSIP_TESTS_TEST_HPP
--- 268,273 ----
  		     (test_assert_fail(__TEST_STRING(expr), __FILE__, __LINE__, \
  				       TEST_ASSERT_FUNCTION), 0)))
  
+ } // namespace vsip_csl
  
! #endif // VSIP_CSL_TEST_HPP
*** tests/output.hpp	2005-12-20 04:48:41.000000000 -0800
--- src/vsip_csl/output.hpp	2006-03-30 16:17:30.512766000 -0800
***************
*** 1,13 ****
! /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
  
! /** @file    tests/output.hpp
      @author  Jules Bergmann
!     @date    03/22/2005
!     @brief   VSIPL++ Library: Output utilities.
  */
  
! #ifndef VSIP_TESTS_OUTPUT_HPP
! #define VSIP_TESTS_OUTPUT_HPP
  
  /***********************************************************************
    Included Files
--- 1,13 ----
! /* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
  
! /** @file    vsip_csl/output.hpp
      @author  Jules Bergmann
!     @date    2005-03-22
!     @brief   VSIPL++ CodeSourcery Library: Output utilities.
  */
  
! #ifndef VSIP_CSL_OUTPUT_HPP
! #define VSIP_CSL_OUTPUT_HPP
  
  /***********************************************************************
    Included Files
***************
*** 21,35 ****
  
  
  
  /***********************************************************************
    Definitions
  ***********************************************************************/
  
  /// Write a Domain<1> object to an output stream.
  
- namespace vsip
- {
- 
  inline
  std::ostream&
  operator<<(
--- 21,35 ----
  
  
  
+ namespace vsip_csl
+ {
+ 
  /***********************************************************************
    Definitions
  ***********************************************************************/
  
  /// Write a Domain<1> object to an output stream.
  
  inline
  std::ostream&
  operator<<(
*************** operator<<(
*** 138,141 ****
  
  } // namespace vsip
  
! #endif // VSIP_OUTPUT_HPP
--- 138,141 ----
  
  } // namespace vsip
  
! #endif // VSIP_CSL_OUTPUT_HPP
*** tests/load_view.hpp	2005-09-30 14:43:07.000000000 -0700
--- src/vsip_csl/load_view.hpp	2006-03-30 16:05:52.524151000 -0800
***************
*** 1,13 ****
! /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
  
! /** @file    tests/load_view.hpp
      @author  Jules Bergmann
      @date    2005-09-30
!     @brief   VSIPL++ Library: Utility to load a view from disk.
  */
  
! #ifndef VSIP_TEST_LOAD_VIEW_HPP
! #define VSIP_TEST_LOAD_VIEW_HPP
  
  /***********************************************************************
    Included Files
--- 1,13 ----
! /* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
  
! /** @file    vsip_csl/load_view.hpp
      @author  Jules Bergmann
      @date    2005-09-30
!     @brief   VSIPL++ CodeSourcery Library: Utility to load a view from disk.
  */
  
! #ifndef VSIP_CSL_LOAD_VIEW_HPP
! #define VSIP_CSL_LOAD_VIEW_HPP
  
  /***********************************************************************
    Included Files
***************
*** 19,24 ****
--- 19,27 ----
  
  
  
+ namespace vsip_csl
+ {
+ 
  /***********************************************************************
    Definitions
  ***********************************************************************/
*************** public:
*** 53,59 ****
    typedef typename vsip::impl::View_of_dim<Dim, T, block_t>::type view_t;
  
  public:
!   Load_view(char*                    filename,
  	    vsip::Domain<Dim> const& dom)
      : data_  (new base_t[factor*dom.size()]),
        block_ (dom, data_),
--- 56,62 ----
    typedef typename vsip::impl::View_of_dim<Dim, T, block_t>::type view_t;
  
  public:
!   Load_view(char const*              filename,
  	    vsip::Domain<Dim> const& dom)
      : data_  (new base_t[factor*dom.size()]),
        block_ (dom, data_),
*************** private:
*** 110,113 ****
    view_t        view_;
  };
  
! #endif // VSIP_TEST_LOAD_VIEW_HPP
--- 113,118 ----
    view_t        view_;
  };
  
! } // namespace vsip_csl
! 
! #endif // VSIP_CSL_LOAD_VIEW_HPP
