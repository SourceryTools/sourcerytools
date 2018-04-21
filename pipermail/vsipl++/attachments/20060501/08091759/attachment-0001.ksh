
Index: benchmarks/cfar.cpp
===================================================================
RCS file: benchmarks/cfar.cpp
diff -N benchmarks/cfar.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/cfar.cpp	2 May 2006 00:26:12 -0000
***************
*** 0 ****
--- 1,371 ----
+ /* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+ 
+ /** @file    benchmarks/hpec-kernel/cfar.cpp
+     @author  Don McCoy
+     @date    2006-04-21
+     @brief   VSIPL++ Library: Constant False Alarm Rate Detection - High
+              Performance Embedded Computing (HPEC) Kernel-Level Benchmarks
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
+ #include <vsip_csl/output.hpp>
+ 
+ #include "benchmarks.hpp"
+ #include "../tests/test-precision.hpp"
+ 
+ using namespace std;
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   Support
+ ***********************************************************************/
+ 
+ template <typename T,
+           typename Block1,
+           typename Block2> 
+ inline
+ void
+ cfar_find_targets(
+   const_Matrix<T, Block1> sum,       // Sum of values in Cfar gates
+   length_type             gates,     // Total number of Cfar gates used
+   const_Matrix<T, Block2> pow_slice, // A set of squared values of range gates
+   const length_type       mu,        // Threshold for determining targets
+   Matrix<index_type>      targets,   // All of the targets detected so far. 
+   index_type&             next,      // the next empty slot in targets
+   const length_type       j)         // Current range gate number. 
+ {
+   if ( next >= targets.size(0) )  // full, nothing to do.
+     return;
+ 
+   // Compute the local noise estimate.  The inverse is calculated in advance
+   // for efficiency.
+   T inv_gates = (1.0 / gates);
+   Matrix<T> tl = sum * inv_gates;
+ 
+   // Make sure we don't divide by zero!  We take advantage of a
+   // reduction function here, knowing the values are positive.
+   Index<const_Matrix<T>::dim> idx;
+   if ( minval(tl, idx) == T() )
+   {
+     for ( index_type k = 0; k < tl.size(1); ++k )
+       for ( index_type i = 0; i < tl.size(0); ++i )
+         if ( tl(i,k) == 0.0 ) {
+           tl(i,k) = Precision_traits<T>::eps;
+           cout << "! " << i << " " << k << endl;
+         }
+   }
+ 
+   // Compute the normalized power in the cell
+   Matrix<T> normalized_power = pow_slice / tl;
+ 
+ 
+   // If the normalized power is larger than mu record the coordinates.  The
+   // list of target are held in a [N x 3] matrix, with each row containing 
+   // the beam location, range gate and doppler bin location of each target. 
+   //
+   for ( index_type k = 0; k < tl.size(1); ++k )
+     for ( index_type i = 0; i < tl.size(0); ++i )
+     {
+       if ( normalized_power(i,k) > mu )
+       {
+         targets(next,0) = i;
+         targets(next,1) = j;
+         targets(next,2) = k;
+         if ( ++next == targets.size(0) )  // full, nothing else to do.
+           return;
+       }
+     }
+ }
+ 
+ 
+ template <typename T,
+           typename Block>
+ void
+ cfar_detect(
+   Tensor<T, Block>   cube,
+   Matrix<index_type> found,
+   length_type        cfar_gates,
+   length_type        guard_cells,
+   length_type        mu)
+ {
+ // Description:
+ //   Main computational routine for the Cfar Kernel Benchmark. Determines 
+ //   targets by finding SNR signal data points that are greater than the 
+ //   noise threshold mu
+ //
+ // Inputs:
+ //    cube: [beams x gates x bins] The radar datacube
+ //
+ // Note: this function assumes that second dimension of input cube C  
+ // has length (range gates) greater than 2(cfar gates + guard cells).
+ // If this were not the case, then the parameters of the radar signal 
+ // processing would be flawed! 
+ 
+   length_type beams = cube.size(0);
+   length_type gates = cube.size(1);
+   length_type dbins = cube.size(2);
+   test_assert( 2*(cfar_gates+guard_cells) < gates );
+ 
+   Tensor<T> cpow = pow(cube, 2);
+ 
+   Domain<1> dom0(beams);
+   Domain<1> dom2(dbins);
+   Matrix<T> sum(beams, dbins, T());
+   for ( length_type lnd = guard_cells; lnd < guard_cells+cfar_gates; ++lnd )
+     sum += cpow(dom0, 1+lnd, dom2);
+ 
+   Matrix<T> pow_slice = cpow(dom0, 0, dom2);
+ 
+   index_type next_found = 0;
+   cfar_find_targets(sum, cfar_gates, pow_slice, mu, found, next_found, 0);
+ 
+   for ( index_type j = 1; j < gates; ++j )
+   {
+     length_type gates_used = 0;
+     length_type c = cfar_gates;
+     length_type g = guard_cells;
+ 
+     // Case 1: No cell included on left side of CFAR; 
+     // very close to left boundary 
+     if ( j < (g + 1) ) 
+     {
+       gates_used = c;
+       sum += cpow(dom0, j+g+c, dom2)   - cpow(dom0, j+g, dom2);
+     }
+     // Case 2: Some cells included on left side of CFAR;
+     // close to left boundary 
+     else if ( (j >= (g + 1)) & (j < (g + c + 1)) )
+     {
+       gates_used = c + j - (g + 1);
+       sum += cpow(dom0, j+g+c, dom2)   - cpow(dom0, j+g, dom2) 
+            + cpow(dom0, j-(g+1), dom2);
+     }
+     // Case 3: All cells included on left and right side of CFAR
+     // somewhere in the middle of the range vector
+     else if ( (j >= (g + c + 1)) & ((j + (g + c)) < gates) )
+     {
+       gates_used = 2 * c;
+       sum += cpow(dom0, j+g+c, dom2)   - cpow(dom0, j+g, dom2) 
+            + cpow(dom0, j-(g+1), dom2) - cpow(dom0, j-(c+g+1), dom2);
+     }
+     // Case 4: Some cells included on right side of CFAR;
+     // close to right boundary
+     else if ( (j + (g + c) >= gates) & ((j + g) < gates) )
+     {
+       gates_used = c + gates - (j + g);
+       sum +=                           - cpow(dom0, j+g, dom2) 
+            + cpow(dom0, j-(g+1), dom2) - cpow(dom0, j-(c+g+1), dom2);
+     }
+     // Case 5: No cell included on right side of CFAR; 
+     // very close to right boundary 
+     else if (j + g >= gates)
+     {
+       gates_used = c;
+       sum += cpow(dom0, j-(g+1), dom2) - cpow(dom0, j-(c+g+1), dom2);
+     }    
+     else
+     {
+       cerr << "Error: fell through if statements in Cfar detection - " << 
+         j << endl;
+       test_assert(0);
+     }
+ 
+     pow_slice = cpow(dom0, j, dom2);
+     cfar_find_targets(sum, gates_used, pow_slice, mu, found, next_found, j);
+   }
+ }
+ 
+ 
+ 
+ /***********************************************************************
+   cfar function tests
+ ***********************************************************************/
+ 
+ template <typename T>
+ struct t_cfar_base
+ {
+   float ops(length_type beams, length_type gates, length_type dbins)
+   {
+     float ops_per_pt = Ops_info<T>::sqr + Ops_info<T>::mul
+                  + 4 * Ops_info<T>::add + Ops_info<T>::div; 
+     return (beams * gates * dbins * ops_per_pt);
+   }
+ 
+   template <typename Block>
+   void
+   test_cfar(
+     Tensor<T, Block>   cube,
+     Matrix<index_type> targets,
+     length_type        loop,
+     float&             time)
+   {
+     Matrix<index_type> found(targets.size(0), targets.size(1), index_type());
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+     {
+       cfar_detect(cube, found, cfar_gates_, guard_cells_, mu_);
+     }
+     t1.stop();
+     time = t1.delta();
+ 
+     // Verify targets detected
+     for ( index_type i = 0; i < targets.size(0); ++i )
+     {
+       // As is, this looks up the targets and makes sure the value indicates
+       // it actually *is* a target.  A better test would be to sort these and 
+       // compare actual coordinates to see that they match one-for-one.
+       test_assert( cube(found(i,0), found(i,1), found(i,2)) == T(50.0) );
+       test_assert( cube(targets(i,0), targets(i,1), targets(i,2)) == T(50.0) );
+ 
+       // Take advantage of the fact that the targets should be sorted by
+       // the range index (the middle one).  As such, the indices should 
+       // generally increase.
+       if ( i > 0 ) 
+         test_assert( found(i,1) >= found(i-1,1) );
+     }
+   }
+ 
+ 
+   t_cfar_base(length_type cfar_gates, length_type guard_cells)
+    : cfar_gates_(cfar_gates), guard_cells_(guard_cells), mu_(100) {}
+ 
+ public:
+   // Member data
+   length_type cfar_gates_;
+   length_type guard_cells_;
+   length_type mu_;
+ };
+ 
+ 
+ template <typename T>
+ struct t_cfar_sweep_range : public t_cfar_base<T>
+ {
+   char* what() { return "t_svd_sweep_fixed_aspect"; }
+   int ops_per_point(length_type size)
+   { 
+     float total_ops = this->ops(this->beams_, size, this->dbins_);
+     return static_cast<int>(total_ops / size);
+   }
+   int riob_per_point(length_type) { return -1*sizeof(T); }
+   int wiob_per_point(length_type) { return -1*sizeof(T); }
+   int mem_per_point(length_type) 
+     { return this->beams_ * this->dbins_ * sizeof(T); }
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+     typedef Tensor<T>  view_type;
+     length_type beams = this->beams_;
+     length_type gates = size;
+     length_type dbins = this->dbins_;
+ 
+     // Create some test data
+     view_type cube(beams, gates, dbins, T());
+ 
+     // First, place a background of uniform noise 
+     Rand<T> gen(0, 0);
+     for ( length_type k = 0; k < dbins; ++k )
+       for ( length_type j = 0; j < gates; ++j )
+         for ( length_type i = 0; i < beams; ++i )
+           cube(i,j,k) = T(1e-1) * gen.randu();
+ 
+     // place ntgts targets within the data cube
+     length_type ntgts = 30;
+     Matrix<index_type> placed(ntgts, 3);
+     for ( length_type t = 0; t < ntgts; ++t )
+     {
+       int d = static_cast<int>(gen.randu() * (dbins - 2)) + 1;
+       int r = static_cast<int>(gen.randu() * (gates - 2)) + 1;
+       int b = static_cast<int>(gen.randu() * (beams - 2)) + 1; 
+       
+       cube(b,r,d) = T(50.0);
+       placed(t, 0) = b;
+       placed(t, 1) = r;
+       placed(t, 2) = d;
+     }
+ 
+     // Run the test and time it
+     this->test_cfar( cube, placed, loop, time );
+   }
+ 
+ 
+   t_cfar_sweep_range(length_type beams, length_type bins,
+                      length_type cfar_gates, length_type guard_cells)
+    : t_cfar_base<T>(cfar_gates, guard_cells), beams_(beams), dbins_(bins) {}
+ 
+ public:
+   // Member data
+   length_type const beams_;
+   length_type const dbins_;
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
Index: benchmarks/loop.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/loop.hpp,v
retrieving revision 1.17
diff -c -p -r1.17 loop.hpp
*** benchmarks/loop.hpp	13 Apr 2006 19:21:07 -0000	1.17
--- benchmarks/loop.hpp	2 May 2006 00:26:12 -0000
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
!     if ( loop == (int)(factor * loop) )
!       break;          // Avoid getting stuck when factor ~= 1 and loop is small
!     else
!       loop = (int)(factor * loop);
!     if ( loop == 0 ) 
!       loop = 1; 
!     if ( loop == 1 )  // Quit if loop cannot get smaller
!       break;
  
      if (factor >= 0.75 && factor <= 1.25)
        break;
Index: benchmarks/ops_info.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/ops_info.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 ops_info.hpp
*** benchmarks/ops_info.hpp	28 Aug 2005 02:15:57 -0000	1.1
--- benchmarks/ops_info.hpp	2 May 2006 00:26:12 -0000
***************
*** 1,4 ****
! /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
  
  /** @file    benchmarks/ops_info.cpp
      @author  Jules Bergmann
--- 1,4 ----
! /* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
  
  /** @file    benchmarks/ops_info.cpp
      @author  Jules Bergmann
***************
*** 15,20 ****
--- 15,22 ----
  template <typename T>
  struct Ops_info
  {
+   static int const div = 1;
+   static int const sqr = 1;
    static int const mul = 1;
    static int const add = 1;
  };
*************** struct Ops_info
*** 22,28 ****
  template <typename T>
  struct Ops_info<std::complex<T> >
  {
!   static int const mul = 6;
    static int const add = 2;
  };
  
--- 24,32 ----
  template <typename T>
  struct Ops_info<std::complex<T> >
  {
!   static int const div = 6 + 3 + 2; // mul + add + div
!   static int const sqr = 2 + 1;     // mul + add
!   static int const mul = 4 + 2;     // mul + add
    static int const add = 2;
  };
  

