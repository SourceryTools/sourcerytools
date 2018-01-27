/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */

/** @file    benchmarks/hpec-kernel/cfar.cpp
    @author  Don McCoy
    @date    2006-04-21
    @brief   VSIPL++ Library: Constant False Alarm Rate Detection - High
             Performance Embedded Computing (HPEC) Kernel-Level Benchmarks

    Briefly, this problem involves finding targets based on data within a 
    three-dimensional cube of 'beam locations', 'range gates' and 'doppler 
    bins'.  It does this by comparing the signal in a given cell to that of
    nearby cells in order to avoid false-detection of targets.  The range 
    gate parameter is varied when considering 'nearby' cells.  A certain 
    number of guard cells are skipped, resulting in a computation that sums
    the values from two thick slices of this data cube (one on either side 
    of the slice for a particular range gate).  The HPEC PCA Kernel-Level 
    benchmark paper has a diagram that shows one cell under consideration.
    Please refer to it if needed.

    The algorithm involves these basic steps:
     - compute the squares of all the values in the data cube
     - for each range gate:
      - sum the squares of desired values around the current range gate
      - compute the normalized power for each cell in the slice
      - search for values that exceed a certain threshold

    Some of the code relates to boundary conditions (near either end of the 
    'range gates' parameter), but otherwise it follows the above description. 
*/

/***********************************************************************
  Included Files
***********************************************************************/

//#include <cassert>

#include <vsip/initfin.hpp>
#include <vsip/support.hpp>
#include <vsip/tensor.hpp>
#include <vsip/random.hpp>
#include <vsip/selgen.hpp>
#include <vsip_csl/test-precision.hpp>

#include "benchmarks.hpp"

using namespace vsip;


#ifdef VSIP_IMPL_SOURCERY_VPP
#  define PARALLEL_CFAR 1
#else
#  define PARALLEL_CFAR 0
#endif


/***********************************************************************
  cfar function tests
***********************************************************************/



template <typename T>
struct t_cfar_base
{
  int ops_per_point(length_type size)
  { 
    int ops = Ops_info<T>::sqr + Ops_info<T>::mul
        + 4 * Ops_info<T>::add + Ops_info<T>::div; 
    return (beams_ * dbins_ * ops);
  }
  int riob_per_point(length_type) { return -1; }
  int wiob_per_point(length_type) { return -1; }
  int mem_per_point(length_type) 
    { return this->beams_ * this->dbins_ * sizeof(T); }

#if PARALLEL_CFAR
  typedef Map<Block_dist, Block_dist, Block_dist>  root_map_type;
  typedef Dense<3, T, row3_type, root_map_type>    root_block_type;
  typedef Tensor<T, root_block_type>               root_view_type;
  typedef typename root_view_type::local_type      local_type;
#else
  typedef Dense<3, T, row3_type>       root_block_type;
  typedef Tensor<T, root_block_type>   root_view_type;
  typedef root_view_type               local_type;
#endif


  void 
  initialize_cube(root_view_type& root)
  {
    length_type const& gates = root.size(2);

#if PARALLEL_CFAR
    // The processor set contains only one processor, hence the map 
    // has only one subblock.
    Vector<processor_type> pset0(1);
    pset0(0) = processor_set()(0);
    root_map_type root_map(pset0, 1, 1);
    
    // Create some test data
    root_view_type root_cube(beams_, dbins_, gates, root_map);
#else
    root_view_type root_cube(beams_, dbins_, gates);
#endif

    // Only the root processor need initialize the target array
#if PARALLEL_CFAR
    if (root_map.subblock() != no_subblock)
#endif
    {
      // First, place a background of uniform noise 
      index_type seed = 1;
      T max_val = T(1);
      T min_val = T(1 / sqrt(T(2)));
      Rand<T> gen(seed, 0);
      for ( length_type i = 0; i < beams_; ++i )
        for ( length_type j = 0; j < dbins_; ++j )
          for ( length_type k = 0; k < gates; ++k )
            root_cube.local().put(i, j, k, 
              T(max_val - min_val) * gen.randu() + min_val);
      
      // Place several targets within the data cube
      Matrix<index_type> placed(ntargets_, 3);
      for ( length_type t = 0; t < ntargets_; ++t )
      {
        int b = static_cast<int>(gen.randu() * (beams_ - 2)) + 1;
        int d = static_cast<int>(gen.randu() * (dbins_ - 2)) + 1;
        int r = static_cast<int>(gen.randu() * (gates - 2)) + 1;
        
        root_cube.local().put(b, d, r, T(50.0));
        placed(t, 0) = b;
        placed(t, 1) = d;
        placed(t, 2) = r;
      }
    }
    
    root = root_cube;
  }


  void
  cfar_verify(
    root_view_type&    root,
    Matrix<Index<2> >  located,
    length_type        count[])
  {
#if PARALLEL_CFAR
    Vector<processor_type> pset0(1);
    pset0(0) = processor_set()(0);
    root_map_type root_map(pset0, 1, 1);

    if (root_map.subblock() != no_subblock)
#endif
    {
      local_type l_root = LOCAL(root);
      length_type total_found = 0;
      for ( index_type i = 0; i < l_root.size(2); ++i )
        for ( index_type j = 0; j < count[i]; ++j )
        {
          test_assert( l_root.get(located.get(i, j)[0], 
                         located.row(i)(j)[1], i) == T(50.0) );
          ++total_found;
        }
      test_assert( total_found == this->ntargets_ );
    }
  }

  t_cfar_base(length_type beams, length_type bins)
    : beams_(beams), dbins_(bins), ntargets_(30)
  {}


protected:
  // Member data
  length_type const beams_;    // Number of beam locations
  length_type const dbins_;    // Number of doppler bins
  length_type const ntargets_; // Number of targets
};


template <typename T>
struct t_cfar_by_slice : public t_cfar_base<T>
{
  char* what() { return "t_cfar_by_slice"; }

#if PARALLEL_CFAR
  typedef Map<Block_dist, Block_dist, Block_dist>  root_map_type;
  typedef Dense<3, T, row3_type, root_map_type>    root_block_type;
  typedef Tensor<T, root_block_type>               root_view_type;
#else
  typedef Dense<3, T, row3_type>       root_block_type;
  typedef Tensor<T, root_block_type>   root_view_type;
#endif


  template <typename Block1,
            typename Block2>
  void
  cfar_detect(
    Tensor<T, Block1>  cube,
    Tensor<T, Block1>  cpow,
    Matrix<T, Block2>  sum,
    Matrix<Index<2> >  located,
    length_type        count[])
  {
    length_type c = cfar_gates_;
    length_type g = guard_cells_;

    // The number of range gates must be sufficiently greater than the sum
    // of CFAR gates and guard cells.  If not, the radar signal processing 
    // parameters are flawed!
    length_type gates = cube.size(2);
    test_assert( 2 * (c + g) < gates );

    const whole_domain_type dom_1 = whole_domain;
    const whole_domain_type dom_2 = whole_domain;
    length_type gates_used = 0;

    // Compute the square of all values in the data cube.  This is 
    // done in advance once, as the values are needed many times
    // (approximately twice as many times as the number of guard cells)
    cpow = sq(cube);

    // Clear scratch space used to hold sums of squares
    sum = T();


    index_type k;
    for ( k = 0; k < (g + c + 1); ++k )
    {
      // Case 0: Initialize
      if ( k == 0 )
      {
        gates_used = c;
        for ( length_type lnd = g; lnd < g + c; ++lnd )
          sum += cpow(dom_1, dom_2, 1 + lnd);
      }
      // Case 1: No cell included on left side of CFAR; 
      // very close to left boundary 
      else if ( k < (g + 1) )
      {
        gates_used = c;
        sum += cpow(dom_1, dom_2, k+g+c)   - cpow(dom_1, dom_2, k+g);
      }
      // Case 2: Some cells included on left side of CFAR;
      // close to left boundary 
      else
      {
        gates_used = c + k - (g + 1);
        sum += cpow(dom_1, dom_2, k+g+c)   - cpow(dom_1, dom_2, k+g) 
          + cpow(dom_1, dom_2, k-(g+1));
      }
      T inv_gates = (1.0 / gates_used);
      count[k] = impl::indexbool( (cpow(dom_1, dom_2, k) / 
        max((sum * inv_gates), Precision_traits<T>::eps) > this->mu_), 
        located.row(k) );
    }

    for ( k = (g + c + 1); (k + (g + c)) < gates; ++k )
    {
      // Case 3: All cells included on left and right side of CFAR
      // somewhere in the middle of the range vector
      gates_used = 2 * c;
      sum += cpow(dom_1, dom_2, k+g+c)     - cpow(dom_1, dom_2, k+g) 
           + cpow(dom_1, dom_2, k-(g+1))   - cpow(dom_1, dom_2, k-(c+g+1));

      T inv_gates = (1.0 / gates_used);
      count[k] = impl::indexbool( (cpow(dom_1, dom_2, k) / 
        max((sum * inv_gates), Precision_traits<T>::eps) > this->mu_), 
        located.row(k) );
    }

    for ( k = gates - (g + c); k < gates; ++k )
    {
      // Case 4: Some cells included on right side of CFAR;
      // close to right boundary
      if ( (k + g) < gates )
      {
        gates_used = c + gates - (k + g);
        sum +=                             - cpow(dom_1, dom_2, k+g) 
             + cpow(dom_1, dom_2, k-(g+1)) - cpow(dom_1, dom_2, k-(c+g+1));
      }
      // Case 5: No cell included on right side of CFAR; 
      // very close to right boundary 
      else
      {
        gates_used = c;
        sum += cpow(dom_1, dom_2, k-(g+1)) - cpow(dom_1, dom_2, k-(c+g+1));
      }
      T inv_gates = (1.0 / gates_used);
      count[k] = impl::indexbool( (cpow(dom_1, dom_2, k) / 
        max((sum * inv_gates), Precision_traits<T>::eps) > this->mu_), 
        located.row(k) );
    }    
  }


  void operator()(length_type size, length_type loop, float& time)
  {
    length_type beams = this->beams_;
    length_type dbins = this->dbins_;
    length_type gates = size;
    
    // Create a "root" view for each that will give the first
    // processor access to all of the data.  
    root_view_type root(beams, dbins, gates);
    initialize_cube(root);
    
#if PARALLEL_CFAR
    // Create the distributed views that will give each processor a 
    // subset of the data
    typedef Map<Block_dist, Block_dist, Whole_dist>  map_type;
    typedef Dense<3, T, row3_type, map_type>         block_type;
    typedef Tensor<T, block_type>                    view_type;
    typedef typename view_type::local_type           local_type;

    processor_type np = num_processors();
    map_type map = map_type(Block_dist(np), Block_dist(np), Whole_dist());

    view_type cube(beams, dbins, gates, map);
    cube = root;

    // Create temporary to hold squared values
    view_type cpow(beams, dbins, gates, map);
#else
    typedef Dense<3, T, col1_type>  block_type;
    typedef Tensor<T, block_type>   view_type;
    typedef view_type local_type;
    view_type& cube = root;

    view_type cpow(beams, dbins, gates);
#endif

    local_type l_cube = LOCAL(cube);
    local_type l_cpow = LOCAL(cpow);
    length_type l_beams  = l_cube.size(0);
    length_type l_dbins  = l_cube.size(1);
    test_assert( gates == l_cube.size(2) );


    // Create space to hold sums of squares
    typedef Matrix<T>  sum_view_type;
    sum_view_type sum(l_beams, l_dbins);

    // And a place to hold found targets
    Matrix<Index<2> > located(gates, this->ntargets_, Index<2>());
    length_type *count = new length_type[gates];

    
    // Run the test and time it
    vsip::impl::profile::Timer t1;
    t1.start();
    for (index_type l=0; l<loop; ++l)
    {
      cfar_detect(l_cube, l_cpow, sum, located, count);
    }
    t1.stop();
    time = t1.delta();


    // Verify targets detected
    cfar_verify(root, located, count);

    delete[] count;
  }


  t_cfar_by_slice(length_type beams, length_type bins,
                     length_type cfar_gates, length_type guard_cells)
   : t_cfar_base<T>(beams, bins),
     cfar_gates_(cfar_gates), guard_cells_(guard_cells), 
     mu_(2)
  {}

public:
  // Member data
  length_type cfar_gates_;    // Number of ranges gates to consider
  length_type guard_cells_;   // Number of cells to skip near target
  length_type mu_;            // Threshold for determining targets
};




template <typename T>
struct t_cfar_by_vector : public t_cfar_base<T>
{
  char* what() { return "t_cfar_by_vector"; }

#if PARALLEL_CFAR
  typedef Map<Block_dist, Block_dist, Block_dist>  root_map_type;
  typedef Dense<3, T, row3_type, root_map_type>    root_block_type;
  typedef Tensor<T, root_block_type>               root_view_type;
#else
  typedef Dense<3, T, row3_type>       root_block_type;
  typedef Tensor<T, root_block_type>   root_view_type;
#endif
  typedef typename 
    Tensor<T>::template subvector<0, 1>::impl_type  subvector_type;


  template <typename Block>
  void
  cfar_detect(
    Tensor<T, Block>   cube,
    Tensor<T, Block>   cpow,
    Matrix<Index<2> >  located,
    length_type        count[])
  {
    length_type c = cfar_gates_;
    length_type g = guard_cells_;
    length_type gates_used = 0;

    // The number of range gates must be sufficiently greater than the sum
    // of CFAR gates and guard cells.  If not, the radar signal processing 
    // parameters are flawed!
    length_type gates = cube.size(2);
    test_assert( 2 * (c + g) < gates );


    // Compute the square of all values in the data cube.  This is 
    // done in advance once, as the values are needed many times
    // (approximately twice as many times as the number of guard cells)
    cpow = sq(cube);

    // Clear scratch space used to hold sums of squares and counts for 
    // targets found per gate.
    T sum = T();
    index_type k;
    for ( k = 0; k < gates; ++k )
      count[k] = 0;


    for ( index_type i = 0; i < this->beams_; ++i )
      for ( index_type j = 0; j < this->dbins_; ++j )
      {
        subvector_type cpow_vec = cpow(i, j, whole_domain);

        for ( k = 0; k < (g + c + 1); ++k )
        {
          // Case 0: Initialize
          if ( k == 0 )
          {
            gates_used = c;
            for ( length_type lnd = g; lnd < g + c; ++lnd )
              sum += cpow_vec(1 + lnd);
          }
          // Case 1: No cell included on left side of CFAR; 
          // very close to left boundary 
          else if ( k < (g + 1) )
          {
            gates_used = c;
            sum += cpow_vec(k+g+c)   - cpow_vec(k+g);
          }
          // Case 2: Some cells included on left side of CFAR;
          // close to left boundary 
          else
          {
            gates_used = c + k - (g + 1);
            sum += cpow_vec(k+g+c)   - cpow_vec(k+g) 
                 + cpow_vec(k-(g+1));
          }
          T inv_gates = (1.0 / gates_used);
          if ( cpow_vec(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
               this->mu_ )
            located.row(k).put(count[k]++, Index<2>(i, j));
        }

        gates_used = 2 * c;
        T inv_gates = (1.0 / gates_used);
        for ( k = (g + c + 1); (k + (g + c)) < gates; ++k )
        {
          // Case 3: All cells included on left and right side of CFAR;
          // somewhere in the middle of the range vector
          sum += cpow_vec(k+g+c)     - cpow_vec(k+g) 
               + cpow_vec(k-(g+1))   - cpow_vec(k-(c+g+1));

          if ( cpow_vec(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
               this->mu_ )
            located.row(k).put(count[k]++, Index<2>(i, j));
        }

        for ( k = gates - (g + c); k < gates; ++k )
        {
          // Case 4: Some cells included on right side of CFAR;
          // close to right boundary
          if ( (k + g) < gates )
          {
            gates_used = c + gates - (k + g);
            sum +=                             - cpow_vec(k+g) 
                 + cpow_vec(k-(g+1)) - cpow_vec(k-(c+g+1));
          }
          // Case 5: No cell included on right side of CFAR; 
          // very close to right boundary 
          else
          {
            gates_used = c;
            sum += cpow_vec(k-(g+1)) - cpow_vec(k-(c+g+1));
          }
          T inv_gates = (1.0 / gates_used);
          if ( cpow_vec(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
               this->mu_ )
            located.row(k).put(count[k]++, Index<2>(i, j));
        }    
      }
  }


  void operator()(length_type size, length_type loop, float& time)
  {
    length_type beams = this->beams_;
    length_type dbins = this->dbins_;
    length_type gates = size;
    
    // Create a "root" view for each that will give the first
    // processor access to all of the data.  
    root_view_type root(beams, dbins, gates);
    initialize_cube(root);
    
#if PARALLEL_CFAR
    // Create the distributed views that will give each processor a 
    // subset of the data
    typedef Map<Block_dist, Block_dist, Whole_dist>  map_type;
    typedef Dense<3, T, row3_type, map_type>         block_type;
    typedef Tensor<T, block_type>                    view_type;
    typedef typename view_type::local_type           local_type;

    processor_type np = num_processors();
    map_type map = map_type(Block_dist(np), Block_dist(np), Whole_dist());

    view_type cube(beams, dbins, gates, map);
    cube = root;

    // Create temporary to hold squared values
    view_type cpow(beams, dbins, gates, map);
#else
    typedef Dense<3, T, col1_type>  block_type;
    typedef Tensor<T, block_type>   view_type;
    typedef view_type local_type;

    view_type& cube = root;

    view_type cpow(beams, dbins, gates);
#endif

    local_type l_cube = LOCAL(cube);
    local_type l_cpow = LOCAL(cpow);
    length_type l_beams  = l_cube.size(0);
    length_type l_dbins  = l_cube.size(1);
    test_assert( gates == l_cube.size(2) );

    // And a place to hold found targets
    Matrix<Index<2> > located(gates, this->ntargets_, Index<2>());
    length_type *count = new length_type[gates];

    
    // Run the test and time it
    vsip::impl::profile::Timer t1;
    t1.start();
    for (index_type l=0; l<loop; ++l)
    {
      cfar_detect(l_cube, l_cpow, located, count);
    }
    t1.stop();
    time = t1.delta();


    // Verify targets detected
    cfar_verify(root, located, count);

    delete[] count;
  }


  t_cfar_by_vector(length_type beams, length_type bins,
                     length_type cfar_gates, length_type guard_cells)
   : t_cfar_base<T>(beams, bins),
     cfar_gates_(cfar_gates), guard_cells_(guard_cells), 
     mu_(2)
  {}

public:
  // Member data
  length_type cfar_gates_;    // Number of ranges gates to consider
  length_type guard_cells_;   // Number of cells to skip near target
  length_type mu_;            // Threshold for determining targets
};



void
defaults(Loop1P& loop)
{
  loop.loop_start_ = 2;
  loop.progression_ = linear;
  loop.prog_scale_ = 100;
  loop.start_ = 2;
  loop.stop_ = 9;
}



template <> float  Precision_traits<float>::eps = 0.0;
template <> double Precision_traits<double>::eps = 0.0;

int
test(Loop1P& loop, int what)
{
  Precision_traits<float>::compute_eps();
  Precision_traits<double>::compute_eps();

/* From PCA Kernel-Level Benchmarks Project Report:

                  Parameter sets for the CFAR Kernel Benchmark.
Name     Description                     Set 0  Set 1 Set 2 Set 3 Units
Nbm      Number of beams                  16     48    48    16   beams
Nrg      Number of range gates            64    3500  1909  9900  range gates
Ndop     Number of doppler bins           24    128    64    16   doppler bins
Ntgts    Number of targets that will be   30     30    30    30   targets
         pseudo-randomly distributed
         in Radar data cube
Ncfar    Number of CFAR range gates        5     10    10    20   range gates
G        CFAR guard cells                  4      8     8    16   range gates
mu       Detection sensitivity factor    100    100   100   100
W        Workload                        0.17   150    41    18   Mﬂop
*/

  switch (what)
  {
  // parameters are number of: beams, doppler bins, CFAR range gates and 
  // CFAR guard cells respectively
  case  1: loop(t_cfar_by_slice<float>(16,  24,  5,  4)); break;
  case  2: loop(t_cfar_by_slice<float>(48, 128, 10,  8)); break;
  case  3: loop(t_cfar_by_slice<float>(48,  64, 10,  8)); break;
  case  4: loop(t_cfar_by_slice<float>(16,  16, 20, 16)); break;

  case 11: loop(t_cfar_by_slice<double>(16,  24,  5,  4)); break;
  case 12: loop(t_cfar_by_slice<double>(48, 128, 10,  8)); break;
  case 13: loop(t_cfar_by_slice<double>(48,  64, 10,  8)); break;
  case 14: loop(t_cfar_by_slice<double>(16,  16, 20, 16)); break;

  case 21: loop(t_cfar_by_vector<float>(16,  24,  5,  4)); break;
  case 22: loop(t_cfar_by_vector<float>(48, 128, 10,  8)); break;
  case 23: loop(t_cfar_by_vector<float>(48,  64, 10,  8)); break;
  case 24: loop(t_cfar_by_vector<float>(16,  16, 20, 16)); break;

  case 31: loop(t_cfar_by_vector<double>(16,  24,  5,  4)); break;
  case 32: loop(t_cfar_by_vector<double>(48, 128, 10,  8)); break;
  case 33: loop(t_cfar_by_vector<double>(48,  64, 10,  8)); break;
  case 34: loop(t_cfar_by_vector<double>(16,  16, 20, 16)); break;

  default: 
    return 0;
  }
  return 1;
}
 
