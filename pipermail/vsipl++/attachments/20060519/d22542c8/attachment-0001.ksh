
Index: benchmarks/loop.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/loop.hpp,v
retrieving revision 1.17
diff -c -p -r1.17 loop.hpp
*** benchmarks/loop.hpp	13 Apr 2006 19:21:07 -0000	1.17
--- benchmarks/loop.hpp	19 May 2006 23:51:29 -0000
*************** Loop1P::sweep(Functor fcn)
*** 286,292 ****
  
      float factor = goal_sec_ / time;
      if (factor < 1.0) factor += 0.1 * (1.0 - factor);
!     loop = (int)(factor * loop);
  
      if (factor >= 0.75 && factor <= 1.25)
        break;
--- 286,299 ----
  
      float factor = goal_sec_ / time;
      if (factor < 1.0) factor += 0.1 * (1.0 - factor);
!     if ( loop == (size_t)(factor * loop) )
!       break;          // Avoid getting stuck when factor ~= 1 and loop is small
!     else
!       loop = (size_t)(factor * loop);
!     if ( loop == 0 ) 
!       loop = 1; 
!     if ( loop == 1 )  // Quit if loop cannot get smaller
!       break;
  
      if (factor >= 0.75 && factor <= 1.25)
        break;
Index: benchmarks/hpec_kernel/cfar.cpp
===================================================================
RCS file: benchmarks/hpec_kernel/cfar.cpp
diff -N benchmarks/hpec_kernel/cfar.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/hpec_kernel/cfar.cpp	19 May 2006 23:51:29 -0000
***************
*** 0 ****
--- 1,378 ----
+ /* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+ 
+ /** @file    benchmarks/hpec-kernel/cfar.cpp
+     @author  Don McCoy
+     @date    2006-04-21
+     @brief   VSIPL++ Library: Constant False Alarm Rate Detection - High
+              Performance Embedded Computing (HPEC) Kernel-Level Benchmarks
+ 
+     Briefly, this problem involves finding targets based on data within a 
+     three-dimensional cube of 'beam locations', 'range gates' and 'doppler 
+     bins'.  It does this by comparing the signal in a given cell to that of
+     nearby cells in order to avoid false-detection of targets.  The range 
+     gate parameter is varied when considering 'nearby' cells.  A certain 
+     number of guard cells are skipped, resulting in a computation that sums
+     the values from two thick slices of this data cube (one on either side 
+     of the slice for a particular range gate).  The HPEC PCA Kernel-Level 
+     benchmark paper has a diagram that shows one cell under consideration.
+     Please refer to it if needed.
+ 
+     The algorithm involves these basic steps:
+      - compute the squares of all the values in the data cube
+      - for each range gate:
+       - sum the squares of desired values around the current range gate
+       - compute the normalized power for each cell in the slice
+       - search for values that exceed a certain threshold
+ 
+     Some of the code relates to boundary conditions (near either end of the 
+     'range gates' parameter), but otherwise it follows the above description. 
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <cassert>
+ 
+ #include <vsip/initfin.hpp>
+ #include <vsip/support.hpp>
+ #include <vsip/tensor.hpp>
+ #include <vsip/random.hpp>
+ #include <vsip/selgen.hpp>
+ 
+ #include "benchmarks.hpp"
+ #include "../tests/test-precision.hpp"
+ 
+ using namespace vsip;
+ 
+ 
+ #ifdef VSIP_IMPL_SOURCERY_VPP
+ #  define PARALLEL_CFAR 1
+ #else
+ #  define PARALLEL_CFAR 0
+ #endif
+ 
+ 
+ /***********************************************************************
+   cfar function tests
+ ***********************************************************************/
+ 
+ template <typename T>
+ struct t_cfar_sweep_range
+ {
+   float ops(length_type gates, length_type beams, length_type dbins)
+   {
+     float ops_per_pt = Ops_info<T>::sqr + Ops_info<T>::mul
+       + 4 * Ops_info<T>::add + Ops_info<T>::div; 
+     return (beams * dbins * gates * ops_per_pt);
+   }
+ 
+   char* what() { return "t_svd_sweep_fixed_aspect"; }
+   int ops_per_point(length_type size)
+   { 
+     float total_ops = ops(size, this->beams_, this->dbins_);
+     return static_cast<int>(total_ops / size);
+   }
+   int riob_per_point(length_type) { return -1*sizeof(T); }
+   int wiob_per_point(length_type) { return -1*sizeof(T); }
+   int mem_per_point(length_type) 
+     { return this->beams_ * this->dbins_ * sizeof(T); }
+ 
+ 
+   template <typename Block1,
+             typename Block2>
+   void
+   cfar_detect(
+     Tensor<T, Block1>  cube,
+     Tensor<T, Block1>  cpow,
+     Matrix<T, Block2>  sum,
+     Matrix<Index<2> >  located,
+     length_type        count[])
+   {
+     length_type c = cfar_gates_;
+     length_type g = guard_cells_;
+ 
+     // The number of range gates must be sufficiently greater than the sum
+     // of CFAR gates and guard cells.  If not, the radar signal processing 
+     // parameters are flawed!
+     length_type gates = cube.size(0);
+     test_assert( 2 * (c + g) < gates );
+ 
+     const whole_domain_type dom_1 = whole_domain;
+     const whole_domain_type dom_2 = whole_domain;
+     length_type gates_used = 0;
+ 
+     // Compute the square of all values in the data cube.  This is 
+     // done in advance once, as the values are needed many times
+     // (approximately twice as many times as the number of guard cells)
+     cpow = sq(cube);
+ 
+     // Clear scratch space used to hold sums of squares
+     sum = T();
+ 
+ 
+     index_type i;
+     for ( i = 0; i < (g + c + 1); ++i )
+     {
+       // Case 0: Initialize
+       if ( i == 0 )
+       {
+         gates_used = c;
+         for ( length_type lnd = g; lnd < g + c; ++lnd )
+           sum += cpow(1 + lnd, dom_1, dom_2);
+       }
+       // Case 1: No cell included on left side of CFAR; 
+       // very close to left boundary 
+       else if ( i < (g + 1) )
+       {
+         gates_used = c;
+         sum += cpow(i+g+c, dom_1, dom_2)   - cpow(i+g, dom_1, dom_2);
+       }
+       // Case 2: Some cells included on left side of CFAR;
+       // close to left boundary 
+       else
+       {
+         gates_used = c + i - (g + 1);
+         sum += cpow(i+g+c, dom_1, dom_2)   - cpow(i+g, dom_1, dom_2) 
+           + cpow(i-(g+1), dom_1, dom_2);
+       }
+       T inv_gates = (1.0 / gates_used);
+       count[i] = impl::indexbool( (cpow(i, whole_domain, whole_domain) / 
+         max((sum * inv_gates), Precision_traits<T>::eps) > this->mu_), 
+         located.row(i) );
+     }
+ 
+     for ( i = (g + c + 1); (i + (g + c)) < gates; ++i )
+     {
+       // Case 3: All cells included on left and right side of CFAR
+       // somewhere in the middle of the range vector
+       gates_used = 2 * c;
+       sum += cpow(i+g+c, dom_1, dom_2)     - cpow(i+g, dom_1, dom_2) 
+            + cpow(i-(g+1), dom_1, dom_2)   - cpow(i-(c+g+1), dom_1, dom_2);
+ 
+       T inv_gates = (1.0 / gates_used);
+       count[i] = impl::indexbool( (cpow(i, whole_domain, whole_domain) / 
+         max((sum * inv_gates), Precision_traits<T>::eps) > this->mu_), 
+         located.row(i) );
+     }
+ 
+     for ( i = gates - (g + c); i < gates; ++i )
+     {
+       // Case 4: Some cells included on right side of CFAR;
+       // close to right boundary
+       if ( (i + g) < gates )
+       {
+         gates_used = c + gates - (i + g);
+         sum +=                             - cpow(i+g, dom_1, dom_2) 
+              + cpow(i-(g+1), dom_1, dom_2) - cpow(i-(c+g+1), dom_1, dom_2);
+       }
+       // Case 5: No cell included on right side of CFAR; 
+       // very close to right boundary 
+       else
+       {
+         gates_used = c;
+         sum += cpow(i-(g+1), dom_1, dom_2) - cpow(i-(c+g+1), dom_1, dom_2);
+       }
+       T inv_gates = (1.0 / gates_used);
+       count[i] = impl::indexbool( (cpow(i, whole_domain, whole_domain) / 
+         max((sum * inv_gates), Precision_traits<T>::eps) > this->mu_), 
+         located.row(i) );
+     }    
+   }
+ 
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+     length_type gates = size;
+     length_type beams = this->beams_;
+     length_type dbins = this->dbins_;
+ 
+ #if PARALLEL_CFAR
+     // Create a "root" view for each that will give the first
+     // processor access to all of the data.  
+     typedef Map<Block_dist, Block_dist, Block_dist>  root_map_type;
+     typedef Dense<3, T, row3_type, root_map_type>    root_block_type;
+     typedef Tensor<T, root_block_type>               root_view_type;
+ 
+     // A processor set with one processor in it is used to create 
+     // a map with 1 subblock
+     Vector<processor_type> pset0(1);
+     pset0(0) = processor_set()(0);
+     root_map_type root_map(pset0, 1, 1);
+ 
+     // Create some test data
+     root_view_type root_cube(gates, beams, dbins, root_map);
+ #else
+     typedef Dense<3, T, col1_type>  block_type;
+     typedef Tensor<T, block_type>   view_type;
+ 
+     view_type root_cube(gates, beams, dbins);
+ #endif
+ 
+ 
+     // Only the root processor need initialize the target array
+     length_type ntgts = 30;
+ #if PARALLEL_CFAR
+     if (root_map.subblock() != no_subblock)
+ #endif
+     {
+       // First, place a background of uniform noise 
+       Rand<T> gen(0, 0);
+       for ( length_type i = 0; i < gates; ++i )
+         for ( length_type j = 0; j < beams; ++j )
+           for ( length_type k = 0; k < dbins; ++k )
+             root_cube.local().put(i, j, k, T(1e-1) * (1 - gen.randu()));
+ 
+       // Place several targets within the data cube
+       Matrix<index_type> placed(ntgts, 3);
+       for ( length_type t = 0; t < ntgts; ++t )
+       {
+         int r = static_cast<int>(gen.randu() * (gates - 2)) + 1;
+         int b = static_cast<int>(gen.randu() * (beams - 2)) + 1; 
+         int d = static_cast<int>(gen.randu() * (dbins - 2)) + 1;
+       
+         root_cube.local().put(r, b, d, T(50.0));
+         placed(t, 0) = r;
+         placed(t, 1) = b;
+         placed(t, 2) = d;
+       }
+     }
+ 
+ #if PARALLEL_CFAR
+     // Create the distributed views that will give each processor a 
+     // subset of the data
+     typedef Map<Whole_dist, Block_dist, Block_dist>  map_type;
+     typedef Dense<3, T, row3_type, map_type>         block_type;
+     typedef Tensor<T, block_type>                    view_type;
+     typedef typename view_type::local_type           local_type;
+ 
+     processor_type np = num_processors();
+     map_type map = map_type(Whole_dist(), Block_dist(np), Block_dist(np));
+ 
+     view_type cube(gates, beams, dbins, map);
+     cube = root_cube;
+ 
+     // Create temporary to hold squared values
+     view_type cpow(gates, beams, dbins, map);
+ #else
+     typedef view_type local_type;
+     view_type& cube = root_cube;
+ 
+     view_type cpow(gates, beams, dbins);
+ #endif
+ 
+     local_type l_cube = LOCAL(cube);
+     local_type l_cpow = LOCAL(cpow);
+     test_assert( gates == l_cube.size(0) );
+     length_type l_beams  = l_cube.size(1);
+     length_type l_dbins  = l_cube.size(2);
+ 
+ 
+     // Create space to holding sums of squares
+     typedef Matrix<T>  sum_view_type;
+     sum_view_type sum(l_beams, l_dbins);
+ 
+     // And a place to hold found targets
+     Matrix<Index<2> > located(gates, 30, Index<2>());
+     length_type count[gates];
+ 
+     
+     // Run the test and time it
+     vsip::impl::profile::Timer t1;
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+     {
+       cfar_detect(l_cube, l_cpow, sum, located, count);
+     }
+     t1.stop();
+     time = t1.delta();
+ 
+ 
+     // Verify targets detected
+ #if PARALLEL_CFAR
+     if (root_map.subblock() != no_subblock)
+ #endif
+     {
+       local_type l_root_cube = LOCAL(root_cube);
+       for ( index_type i = 0; i < ntgts; ++i )
+         for ( index_type j = 0; j < count[i]; ++j )
+           test_assert( l_root_cube.get(i, 
+             located.row(i)(j)[0], located.row(i)(j)[1]) == T(50.0) );
+     }
+   }
+ 
+ 
+   t_cfar_sweep_range(length_type beams, length_type bins,
+                      length_type cfar_gates, length_type guard_cells)
+    : beams_(beams), dbins_(bins), 
+      cfar_gates_(cfar_gates), guard_cells_(guard_cells), 
+      mu_(100)
+   {}
+ 
+ public:
+   // Member data
+   length_type const beams_;   // Number of beam locations
+   length_type const dbins_;   // Number of doppler bins
+   length_type cfar_gates_;    // Number of ranges gates to consider
+   length_type guard_cells_;   // Number of cells to skip near target
+   length_type mu_;            // Threshold for determining targets
+ };
+ 
+ 
+ void
+ defaults(Loop1P& loop)
+ {
+   loop.loop_start_ = 2;
+   loop.progression_ = linear;
+   loop.prog_scale_ = 100;
+   loop.start_ = 2;
+   loop.stop_ = 9;
+ }
+ 
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
+ /* From PCA Kernel-Level Benchmarks Project Report:
+ 
+                   Parameter sets for the CFAR Kernel Benchmark.
+ Name     Description                     Set 0  Set 1 Set 2 Set 3 Units
+ Nbm      Number of beams                  16     48    48    16   beams
+ Nrg      Number of range gates            64    3500  1909  9900  range gates
+ Ndop     Number of doppler bins           24    128    64    16   doppler bins
+ Ntgts    Number of targets that will be   30     30    30    30   targets
+          pseudo-randomly distributed
+          in Radar data cube
+ Ncfar    Number of CFAR range gates        5     10    10    20   range gates
+ G        CFAR guard cells                  4      8     8    16   range gates
+ mu       Detection sensitivity factor    100    100   100   100
+ W        Workload                        0.17   150    41    18   Mﬂop
+ */
+ 
+   switch (what)
+   {
+   // parameters are number of: beams, doppler bins, CFAR range gates and 
+   // CFAR guard cells respectively
+   case  1: loop(t_cfar_sweep_range<float>(16,  24,  5,  4)); break;
+   case  2: loop(t_cfar_sweep_range<float>(48, 128, 10,  8)); break;
+   case  3: loop(t_cfar_sweep_range<float>(48,  64, 10,  8)); break;
+   case  4: loop(t_cfar_sweep_range<float>(16,  16, 20, 16)); break;
+ 
+   case 11: loop(t_cfar_sweep_range<double>(16,  24,  5,  4)); break;
+   case 12: loop(t_cfar_sweep_range<double>(48, 128, 10,  8)); break;
+   case 13: loop(t_cfar_sweep_range<double>(48,  64, 10,  8)); break;
+   case 14: loop(t_cfar_sweep_range<double>(16,  16, 20, 16)); break;
+ 
+   default: 
+     return 0;
+   }
+   return 1;
+ }
+  
Index: src/vsip_csl/output.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip_csl/output.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 output.hpp
*** src/vsip_csl/output.hpp	3 Apr 2006 19:17:15 -0000	1.1
--- src/vsip_csl/output.hpp	19 May 2006 23:51:29 -0000
***************
*** 17,23 ****
  #include <vsip/domain.hpp>
  #include <vsip/vector.hpp>
  #include <vsip/matrix.hpp>
- #include <vsip/impl/point.hpp>
  
  
  
--- 17,22 ----
*************** operator<<(
*** 115,141 ****
    return out;
  }
  
- 
- /// Write a point to a stream.
- 
- template <vsip::dimension_type Dim>
- inline
- std::ostream&
- operator<<(
-   std::ostream&		        out,
-   vsip::impl::Point<Dim> const& idx)
-   VSIP_NOTHROW
- {
-   out << "(";
-   for (vsip::dimension_type d=0; d<Dim; ++d)
-   {
-     if (d > 0) out << ", ";
-     out << idx[d];
-   }
-   out << ")";
-   return out;
- }
- 
  } // namespace vsip
  
  #endif // VSIP_CSL_OUTPUT_HPP
--- 114,119 ----
