
Index: benchmarks/hpec_kernel/cfar.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/hpec_kernel/cfar.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 cfar.cpp
*** benchmarks/hpec_kernel/cfar.cpp	9 Jun 2006 21:30:57 -0000	1.5
--- benchmarks/hpec_kernel/cfar.cpp	15 Jun 2006 08:56:37 -0000
***************
*** 33,38 ****
--- 33,39 ----
  ***********************************************************************/
  
  #include <iostream>
+ #include <memory>
  
  #include <vsip/initfin.hpp>
  #include <vsip/support.hpp>
*************** using namespace vsip;
*** 54,227 ****
  
  
  /***********************************************************************
!   cfar function tests
  ***********************************************************************/
  
  
  
- template <typename T>
- struct t_cfar_base
- {
-   int ops_per_point(length_type /*size*/)
-   { 
-     int ops = Ops_info<T>::sqr + Ops_info<T>::mul
-         + 4 * Ops_info<T>::add + Ops_info<T>::div; 
-     return (beams_ * dbins_ * ops);
-   }
-   int riob_per_point(length_type) { return -1; }
-   int wiob_per_point(length_type) { return -1; }
-   int mem_per_point(length_type) 
-     { return this->beams_ * this->dbins_ * sizeof(T); }
- 
- #if PARALLEL_CFAR
-   typedef Map<Block_dist, Block_dist, Block_dist>  root_map_type;
-   typedef Dense<3, T, row3_type, root_map_type>    root_block_type;
-   typedef Tensor<T, root_block_type>               root_view_type;
-   typedef typename root_view_type::local_type      local_type;
- #else
-   typedef Dense<3, T, row3_type>       root_block_type;
-   typedef Tensor<T, root_block_type>   root_view_type;
-   typedef root_view_type               local_type;
- #endif
- 
- 
-   void 
-   initialize_cube(root_view_type& root)
-   {
-     length_type const& gates = root.size(2);
- 
- #if PARALLEL_CFAR
-     // The processor set contains only one processor, hence the map 
-     // has only one subblock.
-     Vector<processor_type> pset0(1);
-     pset0(0) = processor_set()(0);
-     root_map_type root_map(pset0, 1, 1);
-     
-     // Create some test data
-     root_view_type root_cube(beams_, dbins_, gates, root_map);
- #else
-     root_view_type root_cube(beams_, dbins_, gates);
- #endif
- 
-     // Only the root processor need initialize the target array
- #if PARALLEL_CFAR
-     if (root_map.subblock() != no_subblock)
- #endif
-     {
-       // First, place a background of uniform noise 
-       index_type seed = 1;
-       T max_val = T(1);
-       T min_val = T(1 / sqrt(T(2)));
-       Rand<T> gen(seed, 0);
-       for ( length_type i = 0; i < beams_; ++i )
-         for ( length_type j = 0; j < dbins_; ++j )
-           for ( length_type k = 0; k < gates; ++k )
-             root_cube.local().put(i, j, k, 
-               T(max_val - min_val) * gen.randu() + min_val);
-       
-       // Place several targets within the data cube
-       Matrix<index_type> placed(ntargets_, 3);
-       for ( length_type t = 0; t < ntargets_; ++t )
-       {
-         int b = static_cast<int>(gen.randu() * (beams_ - 2)) + 1;
-         int d = static_cast<int>(gen.randu() * (dbins_ - 2)) + 1;
-         int r = static_cast<int>(gen.randu() * (gates - 2)) + 1;
-         
-         root_cube.local().put(b, d, r, T(50.0));
-         placed(t, 0) = b;
-         placed(t, 1) = d;
-         placed(t, 2) = r;
-       }
-     }
-     
-     root = root_cube;
-   }
- 
- 
-   template <typename Block>
-   void
-   cfar_verify(
-     Tensor<T, Block>   l_cube,
-     Matrix<Index<2> >  located,
-     length_type        count[])
-   {
-     // Create a vector with one element on each processor.
-     length_type np = num_processors();
-     Vector<length_type, Dense<1, length_type, row1_type, Map<> > >
-       sum(np, Map<>(np));
- 
-     length_type l_total_found = 0;
-     for ( index_type i = 0; i < l_cube.size(2); ++i )
-       for ( index_type j = 0; j < count[i]; ++j )
-       {
- 	test_assert( l_cube.get(located.get(i, j)[0], 
- 				located.get(i, j)[1], i) == T(50.0) );
- 	++l_total_found;
-       }
-     sum.put(local_processor(), l_total_found);
- 
-     // Parallel reduction.
-     length_type total_found = sumval(sum);
- 
-     // Warn if we don't find all the targets.
-     if( total_found != this->ntargets_ && local_processor() == 0 )
-       std::cerr << "only found " << total_found
- 		<< " out of " << this->ntargets_
- 		<< std::endl;
-   }
- 
-   t_cfar_base(length_type beams, length_type bins)
-     : beams_(beams), dbins_(bins), ntargets_(30)
-   {}
- 
- 
- protected:
-   // Member data
-   length_type const beams_;    // Number of beam locations
-   length_type const dbins_;    // Number of doppler bins
-   length_type const ntargets_; // Number of targets
- };
  
  
! template <typename T,
! 	  typename OrderT = tuple<2, 0, 1> >
! struct t_cfar_by_slice : public t_cfar_base<T>
  {
!   char* what() { return "t_cfar_by_slice"; }
! 
! #if PARALLEL_CFAR
!   typedef Map<Block_dist, Block_dist, Block_dist>  root_map_type;
!   typedef Dense<3, T, row3_type, root_map_type>    root_block_type;
!   typedef Tensor<T, root_block_type>               root_view_type;
! #else
!   typedef Dense<3, T, row3_type>       root_block_type;
!   typedef Tensor<T, root_block_type>   root_view_type;
! #endif
! 
  
!   template <typename Block1,
!             typename Block2,
!             typename Block3>
    void
    cfar_detect(
!     Tensor<T, Block1>  cube,
!     Tensor<T, Block1>  cpow,
!     Matrix<T, Block2>  sum,
!     Matrix<T, Block3>  tmp,
!     Matrix<Index<2> >  located,
!     length_type        count[])
    {
!     length_type c = cfar_gates_;
!     length_type g = guard_cells_;
  
-     // The number of range gates must be sufficiently greater than the sum
-     // of CFAR gates and guard cells.  If not, the radar signal processing 
-     // parameters are flawed!
-     length_type gates = cube.size(2);
-     test_assert( 2 * (c + g) < gates );
- 
-     const whole_domain_type dom_1 = whole_domain;
-     const whole_domain_type dom_2 = whole_domain;
      length_type gates_used = 0;
  
      // Compute the square of all values in the data cube.  This is 
--- 55,95 ----
  
  
  /***********************************************************************
!   Definitions
  ***********************************************************************/
  
+ template <typename T,
+ 	  typename ImplTag>
+ struct t_cfar_base;
  
+ struct ImplSlice;          // All range cells processed together
+ struct ImplVector;         // Each range gate vector processed independently
+ struct ImplHybrid;         // A cache-efficient combination of the above approaches
  
  
+ /***********************************************************************
+   CFAR Implementations
+ ***********************************************************************/
  
! template <typename T>
! struct t_cfar_base<T, ImplSlice>
  {
!   char* what() { return "t_cfar_sweep_range<T, ImplSlice>"; }
  
!   template <typename Block>
    void
    cfar_detect(
!     Tensor<T, Block>    cube,
!     Tensor<T, Block>    cpow,
!     Matrix<Index<2> >   located,
!     Vector<length_type> count)
    {
!     length_type const c = cfar_gates_;
!     length_type const g = guard_cells_;
!     length_type const beams = cube.size(0);
!     length_type const dbins = cube.size(1);
!     length_type const gates = cube.size(2);
  
      length_type gates_used = 0;
  
      // Compute the square of all values in the data cube.  This is 
*************** struct t_cfar_by_slice : public t_cfar_b
*** 229,234 ****
--- 97,106 ----
      // (approximately twice as many times as the number of guard cells)
      cpow = sq(cube);
  
+     // Create space to hold sums of squares
+     Matrix<T> sum(beams, dbins);
+     Matrix<T> tmp(beams, dbins);
+ 
      // Clear scratch space used to hold sums of squares
      sum = T();
  
*************** struct t_cfar_by_slice : public t_cfar_b
*** 241,270 ****
        {
          gates_used = c;
          for ( length_type lnd = g; lnd < g + c; ++lnd )
!           sum += cpow(dom_1, dom_2, 1 + lnd);
        }
        // Case 1: No cell included on left side of CFAR; 
        // very close to left boundary 
        else if ( k < (g + 1) )
        {
          gates_used = c;
!         sum += cpow(dom_1, dom_2, k+g+c);
! 	sum -= cpow(dom_1, dom_2, k+g);
        }
        // Case 2: Some cells included on left side of CFAR;
        // close to left boundary 
        else
        {
          gates_used = c + k - (g + 1);
!         sum += cpow(dom_1, dom_2, k+g+c);
! 	sum -= cpow(dom_1, dom_2, k+g);
! 	sum += cpow(dom_1, dom_2, k-(g+1));
        }
        T inv_gates = (1.0 / gates_used);
        tmp = sum * inv_gates;
        tmp = max(tmp, Precision_traits<T>::eps);
!       tmp = cpow(dom_1, dom_2, k) / tmp;
!       count[k] = impl::indexbool( tmp > this->mu_, located.row(k) );
      }
  
      for ( k = (g + c + 1); (k + (g + c)) < gates; ++k )
--- 113,142 ----
        {
          gates_used = c;
          for ( length_type lnd = g; lnd < g + c; ++lnd )
!           sum += cpow(whole_domain, whole_domain, 1 + lnd);
        }
        // Case 1: No cell included on left side of CFAR; 
        // very close to left boundary 
        else if ( k < (g + 1) )
        {
          gates_used = c;
!         sum += cpow(whole_domain, whole_domain, k+g+c);
! 	sum -= cpow(whole_domain, whole_domain, k+g);
        }
        // Case 2: Some cells included on left side of CFAR;
        // close to left boundary 
        else
        {
          gates_used = c + k - (g + 1);
!         sum += cpow(whole_domain, whole_domain, k+g+c);
! 	sum -= cpow(whole_domain, whole_domain, k+g);
! 	sum += cpow(whole_domain, whole_domain, k-(g+1));
        }
        T inv_gates = (1.0 / gates_used);
        tmp = sum * inv_gates;
        tmp = max(tmp, Precision_traits<T>::eps);
!       tmp = cpow(whole_domain, whole_domain, k) / tmp;
!       count(k) = impl::indexbool( tmp > this->mu_, located.row(k) );
      }
  
      for ( k = (g + c + 1); (k + (g + c)) < gates; ++k )
*************** struct t_cfar_by_slice : public t_cfar_b
*** 272,287 ****
        // Case 3: All cells included on left and right side of CFAR
        // somewhere in the middle of the range vector
        gates_used = 2 * c;
!       sum += cpow(dom_1, dom_2, k+g+c);
!       sum -= cpow(dom_1, dom_2, k+g);
!       sum += cpow(dom_1, dom_2, k-(g+1));
!       sum -= cpow(dom_1, dom_2, k-(c+g+1));
  
        T inv_gates = (1.0 / gates_used);
        tmp = sum * inv_gates;
        tmp = max(tmp, Precision_traits<T>::eps);
!       tmp = cpow(dom_1, dom_2, k) / tmp;
!       count[k] = impl::indexbool( tmp > this->mu_, located.row(k) );
      }
  
      for ( k = gates - (g + c); k < gates; ++k )
--- 144,159 ----
        // Case 3: All cells included on left and right side of CFAR
        // somewhere in the middle of the range vector
        gates_used = 2 * c;
!       sum += cpow(whole_domain, whole_domain, k+g+c);
!       sum -= cpow(whole_domain, whole_domain, k+g);
!       sum += cpow(whole_domain, whole_domain, k-(g+1));
!       sum -= cpow(whole_domain, whole_domain, k-(c+g+1));
  
        T inv_gates = (1.0 / gates_used);
        tmp = sum * inv_gates;
        tmp = max(tmp, Precision_traits<T>::eps);
!       tmp = cpow(whole_domain, whole_domain, k) / tmp;
!       count(k) = impl::indexbool( tmp > this->mu_, located.row(k) );
      }
  
      for ( k = gates - (g + c); k < gates; ++k )
*************** struct t_cfar_by_slice : public t_cfar_b
*** 291,452 ****
        if ( (k + g) < gates )
        {
          gates_used = c + gates - (k + g);
!         sum -= cpow(dom_1, dom_2, k+g);
! 	sum += cpow(dom_1, dom_2, k-(g+1));
! 	sum -= cpow(dom_1, dom_2, k-(c+g+1));
        }
        // Case 5: No cell included on right side of CFAR; 
        // very close to right boundary 
        else
        {
          gates_used = c;
!         sum += cpow(dom_1, dom_2, k-(g+1));
! 	sum -= cpow(dom_1, dom_2, k-(c+g+1));
        }
        T inv_gates = (1.0 / gates_used);
        tmp = sum * inv_gates;
        tmp = max(tmp, Precision_traits<T>::eps);
!       tmp = cpow(dom_1, dom_2, k) / tmp;
!       count[k] = impl::indexbool( tmp > this->mu_, located.row(k) );
      }    
    }
  
  
!   void operator()(length_type size, length_type loop, float& time)
!   {
!     length_type beams = this->beams_;
!     length_type dbins = this->dbins_;
!     length_type gates = size;
!     
!     // Create a "root" view for each that will give the first
!     // processor access to all of the data.  
!     root_view_type root(beams, dbins, gates);
!     initialize_cube(root);
!     
! #if PARALLEL_CFAR
!     // Create the distributed views that will give each processor a 
!     // subset of the data
!     typedef Map<Block_dist, Block_dist, Whole_dist>  map_type;
!     typedef Dense<3, T, OrderT, map_type>            block_type;
!     typedef Tensor<T, block_type>                    view_type;
!     typedef typename view_type::local_type           local_type;
! 
!     processor_type np = num_processors();
!     map_type map = map_type(Block_dist(np), Block_dist(1), Whole_dist());
! 
!     view_type cube(beams, dbins, gates, map);
!     cube = root;
! 
!     // Create temporary to hold squared values
!     view_type cpow(beams, dbins, gates, map);
! #else
!     typedef Dense<3, T, OrderT>     block_type;
!     typedef Tensor<T, block_type>   view_type;
!     typedef view_type local_type;
!     view_type& cube = root;
! 
!     view_type cpow(beams, dbins, gates);
! #endif
! 
!     local_type l_cube = LOCAL(cube);
!     local_type l_cpow = LOCAL(cpow);
!     length_type l_beams  = l_cube.size(0);
!     length_type l_dbins  = l_cube.size(1);
!     test_assert( gates == l_cube.size(2) );
! 
! 
!     // Create space to hold sums of squares
!     typedef Matrix<T>  sum_view_type;
!     sum_view_type sum(l_beams, l_dbins);
!     sum_view_type tmp(l_beams, l_dbins);
! 
!     // And a place to hold found targets
!     Matrix<Index<2> > located(gates, this->ntargets_, Index<2>());
!     length_type *count = new length_type[gates];
!     
!     // Run the test and time it
!     vsip::impl::profile::Timer t1;
!     t1.start();
!     for (index_type l=0; l<loop; ++l)
!     {
!       cfar_detect(l_cube, l_cpow, sum, tmp, located, count);
!     }
!     t1.stop();
!     time = t1.delta();
! 
!     // Verify targets detected
!     cfar_verify(l_cube, located, count);
! 
!     delete[] count;
!   }
! 
! 
!   t_cfar_by_slice(length_type beams, length_type bins,
!                      length_type cfar_gates, length_type guard_cells)
!    : t_cfar_base<T>(beams, bins),
!      cfar_gates_(cfar_gates), guard_cells_(guard_cells), 
!      mu_(100)
    {}
  
! public:
    // Member data
!   length_type cfar_gates_;    // Number of ranges gates to consider
!   length_type guard_cells_;   // Number of cells to skip near target
!   length_type mu_;            // Threshold for determining targets
  };
  
  
- 
- 
  template <typename T>
! struct t_cfar_by_vector : public t_cfar_base<T>
  {
!   char* what() { return "t_cfar_by_vector"; }
! 
! #if PARALLEL_CFAR
!   typedef Map<Block_dist, Block_dist, Block_dist>  root_map_type;
!   typedef Dense<3, T, row3_type, root_map_type>    root_block_type;
!   typedef Tensor<T, root_block_type>               root_view_type;
! #else
!   typedef Dense<3, T, row3_type>       root_block_type;
!   typedef Tensor<T, root_block_type>   root_view_type;
! #endif
!   typedef typename 
!     Tensor<T>::template subvector<0, 1>::impl_type  subvector_type;
! 
  
    template <typename Block>
    void
    cfar_detect(
!     Tensor<T, Block>   cube,
!     Tensor<T, Block>   cpow,
!     Matrix<Index<2> >  located,
!     length_type        count[])
    {
!     length_type c = cfar_gates_;
!     length_type g = guard_cells_;
!     length_type gates_used = 0;
! 
!     // The number of range gates must be sufficiently greater than the sum
!     // of CFAR gates and guard cells.  If not, the radar signal processing 
!     // parameters are flawed!
!     length_type gates = cube.size(2);
!     test_assert( 2 * (c + g) < gates );
! 
! 
!     // Clear scratch space used to hold sums of squares and counts for 
!     // targets found per gate.
!     index_type k;
!     for ( k = 0; k < gates; ++k )
!       count[k] = 0;
! 
      subvector_type cpow_vec = cpow(0, 0, whole_domain);
  
!     length_type l_beams = cube.size(0);
!     length_type l_dbins = cube.size(1);
!     for ( index_type i = 0; i < l_beams; ++i )
!       for ( index_type j = 0; j < l_dbins; ++j )
        {
  	T sum = T();
  
  	// Compute the square of all values in the data cube.  This is 
--- 163,239 ----
        if ( (k + g) < gates )
        {
          gates_used = c + gates - (k + g);
!         sum -= cpow(whole_domain, whole_domain, k+g);
! 	sum += cpow(whole_domain, whole_domain, k-(g+1));
! 	sum -= cpow(whole_domain, whole_domain, k-(c+g+1));
        }
        // Case 5: No cell included on right side of CFAR; 
        // very close to right boundary 
        else
        {
          gates_used = c;
!         sum += cpow(whole_domain, whole_domain, k-(g+1));
! 	sum -= cpow(whole_domain, whole_domain, k-(c+g+1));
        }
        T inv_gates = (1.0 / gates_used);
        tmp = sum * inv_gates;
        tmp = max(tmp, Precision_traits<T>::eps);
!       tmp = cpow(whole_domain, whole_domain, k) / tmp;
!       count(k) = impl::indexbool( tmp > this->mu_, located.row(k) );
      }    
    }
  
  
!   t_cfar_base(length_type beams, length_type bins, 
!     length_type cfar_gates, length_type guard_cells)
!     : beams_(beams), dbins_(bins), cfar_gates_(cfar_gates), 
!       guard_cells_(guard_cells), ntargets_(30), mu_(100)
    {}
  
! protected:
    // Member data
!   length_type const beams_;         // Number of beam locations
!   length_type const dbins_;         //   "   "   doppler bins
!   length_type const cfar_gates_;    //   "   "   ranges gates to consider
!   length_type const guard_cells_;   //   "   "   cells to skip near target
!   length_type const ntargets_;      //   "   "   targets
!   length_type const mu_;            // Threshold for determining targets
  };
  
  
  template <typename T>
! struct t_cfar_base<T, ImplVector>
  {
!   char* what() { return "t_cfar_sweep_range<T, ImplVector>"; }
  
    template <typename Block>
    void
    cfar_detect(
!     Tensor<T, Block>    cube,
!     Tensor<T, Block>    cpow,
!     Matrix<Index<2> >   located,
!     Vector<length_type> count)
    {
!     length_type const c = cfar_gates_;
!     length_type const g = guard_cells_;
!     length_type const beams = cube.size(0);
!     length_type const dbins = cube.size(1);
!     length_type const gates = cube.size(2);
! 
!     // Clear counts for targets found per gate.
!     count = 0;
! 
!     // Extract a single vectors containing all the range cells for a particular
!     // beam location and doppler bin.
!     typedef typename 
!       Tensor<T, Block>::template subvector<0, 1>::impl_type  subvector_type;
      subvector_type cpow_vec = cpow(0, 0, whole_domain);
  
!     for ( index_type i = 0; i < beams; ++i )
!       for ( index_type j = 0; j < dbins; ++j )
        {
+         length_type gates_used;
+         index_type k;
  	T sum = T();
  
  	// Compute the square of all values in the data cube.  This is 
*************** struct t_cfar_by_vector : public t_cfar_
*** 482,488 ****
            T inv_gates = (1.0 / gates_used);
            if ( cpow_vec.get(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
                 this->mu_ )
!             located.row(k).put(count[k]++, Index<2>(i, j));
          }
  
          gates_used = 2 * c;
--- 269,275 ----
            T inv_gates = (1.0 / gates_used);
            if ( cpow_vec.get(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
                 this->mu_ )
!             located.row(k).put(count(k)++, Index<2>(i, j));
          }
  
          gates_used = 2 * c;
*************** struct t_cfar_by_vector : public t_cfar_
*** 496,502 ****
  
            if ( cpow_vec.get(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
                 this->mu_ )
!             located.row(k).put(count[k]++, Index<2>(i, j));
          }
  
          for ( k = gates - (g + c); k < gates; ++k )
--- 283,289 ----
  
            if ( cpow_vec.get(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
                 this->mu_ )
!             located.row(k).put(count(k)++, Index<2>(i, j));
          }
  
          for ( k = gates - (g + c); k < gates; ++k )
*************** struct t_cfar_by_vector : public t_cfar_
*** 519,614 ****
            T inv_gates = (1.0 / gates_used);
            if ( cpow_vec.get(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
                 this->mu_ )
!             located.row(k).put(count[k]++, Index<2>(i, j));
          }    
        }
    }
  
  
!   void operator()(length_type size, length_type loop, float& time)
!   {
!     length_type beams = this->beams_;
!     length_type dbins = this->dbins_;
!     length_type gates = size;
!     
!     // Create a "root" view for each that will give the first
!     // processor access to all of the data.  
!     root_view_type root(beams, dbins, gates);
!     initialize_cube(root);
!     
! #if PARALLEL_CFAR
!     // Create the distributed views that will give each processor a 
!     // subset of the data
!     typedef Map<Block_dist, Block_dist, Whole_dist>  map_type;
!     typedef Dense<3, T, row3_type, map_type>         block_type;
!     typedef Tensor<T, block_type>                    view_type;
!     typedef typename view_type::local_type           local_type;
! 
!     processor_type np = num_processors();
!     map_type map = map_type(Block_dist(np), Block_dist(1), Whole_dist());
! 
!     view_type cube(beams, dbins, gates, map);
!     cube = root;
! 
!     // Create temporary to hold squared values
!     view_type cpow(beams, dbins, gates, map);
! #else
!     typedef Dense<3, T, col1_type>  block_type;
!     typedef Tensor<T, block_type>   view_type;
!     typedef view_type local_type;
! 
!     view_type& cube = root;
! 
!     view_type cpow(beams, dbins, gates);
! #endif
! 
!     local_type l_cube = LOCAL(cube);
!     local_type l_cpow = LOCAL(cpow);
!     // length_type l_beams  = l_cube.size(0);
!     // length_type l_dbins  = l_cube.size(1);
!     test_assert( gates == l_cube.size(2) );
! 
!     // And a place to hold found targets
!     Matrix<Index<2> > located(gates, this->ntargets_, Index<2>());
!     length_type *count = new length_type[gates];
! 
!     
!     // Run the test and time it
!     vsip::impl::profile::Timer t1;
!     t1.start();
!     for (index_type l=0; l<loop; ++l)
!     {
!       cfar_detect(l_cube, l_cpow, located, count);
!     }
!     t1.stop();
!     time = t1.delta();
! 
! 
!     // Verify targets detected
!     cfar_verify(l_cube, located, count);
! 
!     delete[] count;
!   }
! 
! 
!   t_cfar_by_vector(length_type beams, length_type bins,
!                      length_type cfar_gates, length_type guard_cells)
!    : t_cfar_base<T>(beams, bins),
!      cfar_gates_(cfar_gates), guard_cells_(guard_cells), 
!      mu_(100)
    {}
  
! public:
    // Member data
!   length_type cfar_gates_;    // Number of ranges gates to consider
!   length_type guard_cells_;   // Number of cells to skip near target
!   length_type mu_;            // Threshold for determining targets
  };
  
  
- 
  /***********************************************************************
!   cfar_by_hybrid (using SIMD)
  ***********************************************************************/
  
  // This uses GCC's vector extensions, in particular the builtin operators
--- 306,336 ----
            T inv_gates = (1.0 / gates_used);
            if ( cpow_vec.get(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
                 this->mu_ )
!             located.row(k).put(count(k)++, Index<2>(i, j));
          }    
        }
    }
  
  
!   t_cfar_base(length_type beams, length_type bins, 
!     length_type cfar_gates, length_type guard_cells)
!     : beams_(beams), dbins_(bins), cfar_gates_(cfar_gates), 
!       guard_cells_(guard_cells), ntargets_(30), mu_(100)
    {}
  
! protected:
    // Member data
!   length_type const beams_;         // Number of beam locations
!   length_type const dbins_;         //   "   "   doppler bins
!   length_type const cfar_gates_;    //   "   "   ranges gates to consider
!   length_type const guard_cells_;   //   "   "   cells to skip near target
!   length_type const ntargets_;      //   "   "   targets
!   length_type const mu_;            // Threshold for determining targets
  };
  
  
  /***********************************************************************
!   t_cfar_base<T, ImplHybrid>  (using SIMD)
  ***********************************************************************/
  
  // This uses GCC's vector extensions, in particular the builtin operators
*************** gt(v4sf a, v4sf b)
*** 645,708 ****
  }
  
  template <typename T>
! struct t_cfar_by_hybrid : public t_cfar_base<T>
  {
!   char* what() { return "t_cfar_by_hybrid"; }
  
! #if PARALLEL_CFAR
!   typedef Map<Block_dist, Block_dist, Block_dist>  root_map_type;
!   typedef Dense<3, T, row3_type, root_map_type>    root_block_type;
!   typedef Tensor<T, root_block_type>               root_view_type;
! #else
!   typedef Dense<3, T, row3_type>       root_block_type;
!   typedef Tensor<T, root_block_type>   root_view_type;
! #endif
!   typedef typename 
!     Tensor<T>::template subvector<0, 1>::impl_type  subvector_type;
! 
! 
!   template <typename Block1,
! 	    typename Block2>
    void
    cfar_detect(
!     Tensor<T, Block1>    cube,
!     Vector<v4sf, Block2> strip,
!     Matrix<Index<2> >    located,
!     length_type          count[])
    {
!     length_type c = cfar_gates_;
!     length_type g = guard_cells_;
!     length_type gates_used = 0;
! 
!     // The number of range gates must be sufficiently greater than the sum
!     // of CFAR gates and guard cells.  If not, the radar signal processing 
!     // parameters are flawed!
!     length_type gates = cube.size(2);
!     test_assert( 2 * (c + g) < gates );
! 
! 
!     // Compute the square of all values in the data cube.  This is 
!     // done in advance once, as the values are needed many times
!     // (approximately twice as many times as the number of guard cells)
!     // cpow = sq(cube);
  
!     // Clear scratch space used to hold sums of squares and counts for 
!     // targets found per gate.
!     index_type k;
!     for ( k = 0; k < gates; ++k )
!       count[k] = 0;
  
  
      T eps = Precision_traits<T>::eps;
      T fmu = this->mu_;
      v4sf v_eps  = load_scalar(eps);
      v4sf v_mu   = load_scalar(fmu);
  
!     length_type l_beams = cube.size(0);
!     length_type l_dbins = cube.size(1);
!     for ( index_type i = 0; i < l_beams; ++i )
!       for ( index_type j = 0; j < l_dbins; j+=4 )
        {
  	v4sf sum = *(__v4sf*)zero;
  
  	for (index_type aa=0; aa<gates; ++aa)
--- 367,405 ----
  }
  
  template <typename T>
! struct t_cfar_base<T, ImplHybrid>
  {
!   char* what() { return "t_cfar_sweep_range<T, ImplHybrid>"; }
  
!   template <typename Block>
    void
    cfar_detect(
!     Tensor<T, Block>    cube,
!     Tensor<T, Block> /* cpow */,
!     Matrix<Index<2> >   located,
!     Vector<length_type> count)
    {
!     length_type const c = cfar_gates_;
!     length_type const g = guard_cells_;
!     length_type const beams = cube.size(0);
!     length_type const dbins = cube.size(1);
!     length_type const gates = cube.size(2);
  
!     // Clear counts for targets found per gate.
!     count = 0;
  
+     Vector<v4sf> strip(gates);
  
      T eps = Precision_traits<T>::eps;
      T fmu = this->mu_;
      v4sf v_eps  = load_scalar(eps);
      v4sf v_mu   = load_scalar(fmu);
  
!     for ( index_type i = 0; i < beams; ++i )
!       for ( index_type j = 0; j < dbins; j+=4 )
        {
+         length_type gates_used;
+         index_type k;
  	v4sf sum = *(__v4sf*)zero;
  
  	for (index_type aa=0; aa<gates; ++aa)
*************** struct t_cfar_by_hybrid : public t_cfar_
*** 752,758 ****
  	    for (int aa=0; aa<4; ++aa)
  	    {
  	      if (vsum[aa])
! 		located.row(k).put(count[k]++, Index<2>(i, j+aa));
  	    }
  	  }
          }
--- 449,455 ----
  	    for (int aa=0; aa<4; ++aa)
  	    {
  	      if (vsum[aa])
! 		located.row(k).put(count(k)++, Index<2>(i, j+aa));
  	    }
  	  }
          }
*************** struct t_cfar_by_hybrid : public t_cfar_
*** 774,780 ****
  	    for (int aa=0; aa<4; ++aa)
  	    {
  	      if (vsum[aa])
! 		located.row(k).put(count[k]++, Index<2>(i, j+aa));
  	    }
  	  }
          }
--- 471,477 ----
  	    for (int aa=0; aa<4; ++aa)
  	    {
  	      if (vsum[aa])
! 		located.row(k).put(count(k)++, Index<2>(i, j+aa));
  	    }
  	  }
          }
*************** struct t_cfar_by_hybrid : public t_cfar_
*** 808,814 ****
  	    for (int aa=0; aa<4; ++aa)
  	    {
  	      if (vsum[aa])
! 		located.row(k).put(count[k]++, Index<2>(i, j+aa));
  	    }
  	  }
          }    
--- 505,511 ----
  	    for (int aa=0; aa<4; ++aa)
  	    {
  	      if (vsum[aa])
! 		located.row(k).put(count(k)++, Index<2>(i, j+aa));
  	    }
  	  }
          }    
*************** struct t_cfar_by_hybrid : public t_cfar_
*** 816,906 ****
    }
  
  
    void operator()(length_type size, length_type loop, float& time)
    {
      length_type beams = this->beams_;
      length_type dbins = this->dbins_;
      length_type gates = size;
      
!     // Create a "root" view for each that will give the first
!     // processor access to all of the data.  
      root_view_type root(beams, dbins, gates);
      initialize_cube(root);
!     
  #if PARALLEL_CFAR
-     // Create the distributed views that will give each processor a 
-     // subset of the data
      typedef Map<Block_dist, Block_dist, Whole_dist>  map_type;
!     typedef Dense<3, T, row3_type, map_type>         block_type;
      typedef Tensor<T, block_type>                    view_type;
      typedef typename view_type::local_type           local_type;
  
      processor_type np = num_processors();
      map_type map = map_type(Block_dist(np), Block_dist(1), Whole_dist());
  
!     view_type cube(beams, dbins, gates, map);
!     cube = root;
  
!     // Create temporary to hold squared values
!     view_type cpow(beams, dbins, gates, map);
  #else
!     typedef Dense<3, T, col1_type>  block_type;
      typedef Tensor<T, block_type>   view_type;
      typedef view_type local_type;
  
      view_type& cube = root;
- 
      view_type cpow(beams, dbins, gates);
  #endif
  
-     local_type l_cube = LOCAL(cube);
-     local_type l_cpow = LOCAL(cpow);
-     // length_type l_beams  = l_cube.size(0);
  
!     // And a place to hold found targets
      Matrix<Index<2> > located(gates, this->ntargets_, Index<2>());
!     length_type *count = new length_type[gates];
!     Vector<v4sf> strip(gates);
      
!     // Run the test and time it
      vsip::impl::profile::Timer t1;
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
!       cfar_detect(l_cube, strip, located, count);
      }
      t1.stop();
      time = t1.delta();
  
- 
      // Verify targets detected
!     cfar_verify(l_cube, located, count);
! 
!     delete[] count;
    }
  
  
!   t_cfar_by_hybrid(length_type beams, length_type bins,
!                      length_type cfar_gates, length_type guard_cells)
!    : t_cfar_base<T>(beams, bins),
!      cfar_gates_(cfar_gates), guard_cells_(guard_cells), 
!      mu_(100)
    {}
- 
- public:
-   // Member data
-   length_type cfar_gates_;    // Number of ranges gates to consider
-   length_type guard_cells_;   // Number of cells to skip near target
-   length_type mu_;            // Threshold for determining targets
  };
- #endif // __GNUC__ >= 4
- 
  
  
- /***********************************************************************
-   Benchmark driver defintions.
- ***********************************************************************/
- 
  void
  defaults(Loop1P& loop)
  {
--- 513,732 ----
    }
  
  
+   t_cfar_base(length_type beams, length_type bins, 
+     length_type cfar_gates, length_type guard_cells)
+     : beams_(beams), dbins_(bins), cfar_gates_(cfar_gates), 
+       guard_cells_(guard_cells), ntargets_(30), mu_(100)
+   {}
+ 
+ protected:
+   // Member data
+   length_type const beams_;         // Number of beam locations
+   length_type const dbins_;         //   "   "   doppler bins
+   length_type const cfar_gates_;    //   "   "   ranges gates to consider
+   length_type const guard_cells_;   //   "   "   cells to skip near target
+   length_type const ntargets_;      //   "   "   targets
+   length_type const mu_;            // Threshold for determining targets
+ };
+ 
+ 
+ #endif // __GNUC__ >= 4
+ 
+ 
+ 
+ 
+ /***********************************************************************
+   Benchmark driver defintions.
+ ***********************************************************************/
+ 
+ template <typename T,
+           typename ImplTag,
+  	  typename OrderT = tuple<2, 0, 1> >
+ struct t_cfar_sweep_range : public t_cfar_base<T, ImplTag>
+ {
+   int ops_per_point(length_type /*size*/)
+   { 
+     int ops = Ops_info<T>::sqr + Ops_info<T>::mul
+         + 4 * Ops_info<T>::add + Ops_info<T>::div; 
+     return (this->beams_ * this->dbins_ * ops);
+   }
+   int riob_per_point(length_type) { return -1; }
+   int wiob_per_point(length_type) { return -1; }
+   int mem_per_point(length_type) 
+     { return this->beams_ * this->dbins_ * sizeof(T); }
+ 
+ #if PARALLEL_CFAR
+     typedef Map<Block_dist, Block_dist, Block_dist>  root_map_type;
+     typedef Dense<3, T, OrderT, root_map_type>       root_block_type;
+     typedef Tensor<T, root_block_type>               root_view_type;
+ #else
+     typedef Dense<3, T, OrderT>         root_block_type;
+     typedef Tensor<T, root_block_type>  root_view_type;
+ #endif
+ 
+   void 
+   initialize_cube(root_view_type& root)
+   {
+     length_type const gates = root.size(2);
+ 
+ #if PARALLEL_CFAR
+     // The processor set contains only one processor, hence the map 
+     // has only one subblock.
+     Vector<processor_type> pset0(1);
+     pset0(0) = processor_set()(0);
+     root_map_type root_map(pset0, 1, 1);
+     
+     // Create some test data
+     root_view_type root_cube(this->beams_, this->dbins_, gates, root_map);
+ #else
+     root_view_type root_cube(this->beams_, this->dbins_, gates);
+ #endif
+ 
+     // Only the root processor need initialize the target array
+ #if PARALLEL_CFAR
+     if (root_map.subblock() != no_subblock)
+ #endif
+     {
+       // First, place a background of uniform noise 
+       index_type seed = 1;
+       T max_val = T(1);
+       T min_val = T(1 / sqrt(T(2)));
+       Rand<T> gen(seed, 0);
+       for ( length_type i = 0; i < this->beams_; ++i )
+         for ( length_type j = 0; j < this->dbins_; ++j )
+           for ( length_type k = 0; k < gates; ++k )
+             root_cube.local().put(i, j, k, 
+               T(max_val - min_val) * gen.randu() + min_val);
+       
+       // Place several targets within the data cube
+       Matrix<index_type> placed(this->ntargets_, 3);
+       for ( length_type t = 0; t < this->ntargets_; ++t )
+       {
+         int b = static_cast<int>(gen.randu() * (this->beams_ - 2)) + 1;
+         int d = static_cast<int>(gen.randu() * (this->dbins_ - 2)) + 1;
+         int r = static_cast<int>(gen.randu() * (gates - 2)) + 1;
+         
+         root_cube.local().put(b, d, r, T(50.0));
+         placed(t, 0) = b;
+         placed(t, 1) = d;
+         placed(t, 2) = r;
+       }
+     }
+     
+     root = root_cube;
+   }
+ 
+ 
+   template <typename Block>
+   void
+   cfar_verify(
+     Tensor<T, Block>    cube,
+     Matrix<Index<2> >   located,
+     Vector<length_type> count)
+   {
+     // Sum all the targets found on each processor
+     length_type l_total_found = 0;
+     for ( index_type i = 0; i < cube.size(2); ++i )
+       for ( index_type j = 0; j < count(i); ++j )
+       {
+ 	test_assert( cube.get(located.get(i, j)[0], 
+                               located.get(i, j)[1], i) == T(50.0) );
+ 	++l_total_found;
+       }
+ 
+ #if PARALLEL_CFAR
+     // Create a vector with one element on each processor.
+     length_type np = num_processors();
+     length_type lp = local_processor();
+     Vector<length_type, Dense<1, length_type, row1_type, Map<> > >
+       sum(np, Map<>(np));
+     sum.put(lp, l_total_found);
+ 
+     // Parallel reduction.
+     length_type total_found = sumval(sum);
+ #else
+     length_type lp = 0;
+     length_type total_found = l_total_found;
+ #endif
+ 
+     // Warn if we don't find all the targets.
+     if( total_found != this->ntargets_ && lp == 0 )
+       std::cerr << "only found " << total_found
+ 		<< " out of " << this->ntargets_
+ 		<< std::endl;
+   }
+ 
+ 
    void operator()(length_type size, length_type loop, float& time)
    {
      length_type beams = this->beams_;
      length_type dbins = this->dbins_;
      length_type gates = size;
+ 
+     // The number of range gates must be sufficiently greater than the sum
+     // of CFAR gates and guard cells.  If not, the radar signal processing 
+     // parameters are flawed!
+     test_assert( 2 * (this->cfar_gates_ + this->guard_cells_) < gates );
      
!     // Create a "root" view for initialization.  Only the first processor
!     // will access the data.
      root_view_type root(beams, dbins, gates);
      initialize_cube(root);
! 
!     // Create a (possibly distributed) view for computation.  Also create a 
!     // temporary cube with an identical map to hold squared values.
  #if PARALLEL_CFAR
      typedef Map<Block_dist, Block_dist, Whole_dist>  map_type;
!     typedef Dense<3, T, OrderT, map_type>            block_type;
      typedef Tensor<T, block_type>                    view_type;
      typedef typename view_type::local_type           local_type;
  
      processor_type np = num_processors();
      map_type map = map_type(Block_dist(np), Block_dist(1), Whole_dist());
  
!     view_type dist_cube(beams, dbins, gates, map);
!     view_type dist_cpow(beams, dbins, gates, map);
! 
!     dist_cube = root;
  
!     local_type cube = dist_cube.local();
!     local_type cpow = dist_cpow.local();
  #else
!     typedef Dense<3, T, OrderT>     block_type;
      typedef Tensor<T, block_type>   view_type;
      typedef view_type local_type;
  
      view_type& cube = root;
      view_type cpow(beams, dbins, gates);
  #endif
  
  
!     // Create a place to store the locations of targets that are found
      Matrix<Index<2> > located(gates, this->ntargets_, Index<2>());
!     Vector<length_type> count(gates);
      
!     // Process the data cube and time it
      vsip::impl::profile::Timer t1;
      t1.start();
      for (index_type l=0; l<loop; ++l)
      {
!       cfar_detect(cube, cpow, located, count);
      }
      t1.stop();
      time = t1.delta();
  
      // Verify targets detected
!     cfar_verify(cube, located, count);
    }
  
  
!   t_cfar_sweep_range(length_type beams, length_type bins,
!                  length_type cfar_gates, length_type guard_cells)
!    : t_cfar_base<T, ImplTag>(beams, bins, cfar_gates, guard_cells)
    {}
  };
  
  
  void
  defaults(Loop1P& loop)
  {
*************** defaults(Loop1P& loop)
*** 912,918 ****
  }
  
  
- 
  template <> float  Precision_traits<float>::eps = 0.0;
  template <> double Precision_traits<double>::eps = 0.0;
  
--- 738,743 ----
*************** test(Loop1P& loop, int what)
*** 925,931 ****
  /* From PCA Kernel-Level Benchmarks Project Report:
  
                    Parameter sets for the CFAR Kernel Benchmark.
! Name     Description                     Set 0  Set 1 Set 2 Set 3 Units
  Nbm      Number of beams                  16     48    48    16   beams
  Nrg      Number of range gates            64    3500  1909  9900  range gates
  Ndop     Number of doppler bins           24    128    64    16   doppler bins
--- 750,756 ----
  /* From PCA Kernel-Level Benchmarks Project Report:
  
                    Parameter sets for the CFAR Kernel Benchmark.
! Name     Description                     Set 1  Set 2 Set 3 Set 4 Units
  Nbm      Number of beams                  16     48    48    16   beams
  Nrg      Number of range gates            64    3500  1909  9900  range gates
  Ndop     Number of doppler bins           24    128    64    16   doppler bins
*************** W        Workload                       
*** 942,972 ****
    {
    // parameters are number of: beams, doppler bins, CFAR range gates and 
    // CFAR guard cells respectively
!   case  1: loop(t_cfar_by_slice<float>(16,  24,  5,  4)); break;
!   case  2: loop(t_cfar_by_slice<float>(48, 128, 10,  8)); break;
!   case  3: loop(t_cfar_by_slice<float>(48,  64, 10,  8)); break;
!   case  4: loop(t_cfar_by_slice<float>(16,  16, 20, 16)); break;
! 
!   case 11: loop(t_cfar_by_slice<double>(16,  24,  5,  4)); break;
!   case 12: loop(t_cfar_by_slice<double>(48, 128, 10,  8)); break;
!   case 13: loop(t_cfar_by_slice<double>(48,  64, 10,  8)); break;
!   case 14: loop(t_cfar_by_slice<double>(16,  16, 20, 16)); break;
! 
!   case 21: loop(t_cfar_by_vector<float>(16,  24,  5,  4)); break;
!   case 22: loop(t_cfar_by_vector<float>(48, 128, 10,  8)); break;
!   case 23: loop(t_cfar_by_vector<float>(48,  64, 10,  8)); break;
!   case 24: loop(t_cfar_by_vector<float>(16,  16, 20, 16)); break;
! 
!   case 31: loop(t_cfar_by_vector<double>(16,  24,  5,  4)); break;
!   case 32: loop(t_cfar_by_vector<double>(48, 128, 10,  8)); break;
!   case 33: loop(t_cfar_by_vector<double>(48,  64, 10,  8)); break;
!   case 34: loop(t_cfar_by_vector<double>(16,  16, 20, 16)); break;
  
  #if __GNUC__ >= 4
!   case 41: loop(t_cfar_by_hybrid<float>(16,  24,  5,  4)); break;
!   case 42: loop(t_cfar_by_hybrid<float>(48, 128, 10,  8)); break;
!   case 43: loop(t_cfar_by_hybrid<float>(48,  64, 10,  8)); break;
!   case 44: loop(t_cfar_by_hybrid<float>(16,  16, 20, 16)); break;
  #endif // __GNUC__ >= 4
  
    default: 
--- 767,797 ----
    {
    // parameters are number of: beams, doppler bins, CFAR range gates and 
    // CFAR guard cells respectively
!   case  1: loop(t_cfar_sweep_range<float, ImplSlice>(16,  24,  5,  4)); break;
!   case  2: loop(t_cfar_sweep_range<float, ImplSlice>(48, 128, 10,  8)); break;
!   case  3: loop(t_cfar_sweep_range<float, ImplSlice>(48,  64, 10,  8)); break;
!   case  4: loop(t_cfar_sweep_range<float, ImplSlice>(16,  16, 20, 16)); break;
! 
!   case 11: loop(t_cfar_sweep_range<double, ImplSlice>(16,  24,  5,  4)); break;
!   case 12: loop(t_cfar_sweep_range<double, ImplSlice>(48, 128, 10,  8)); break;
!   case 13: loop(t_cfar_sweep_range<double, ImplSlice>(48,  64, 10,  8)); break;
!   case 14: loop(t_cfar_sweep_range<double, ImplSlice>(16,  16, 20, 16)); break;
! 
!   case 21: loop(t_cfar_sweep_range<float, ImplVector>(16,  24,  5,  4)); break;
!   case 22: loop(t_cfar_sweep_range<float, ImplVector>(48, 128, 10,  8)); break;
!   case 23: loop(t_cfar_sweep_range<float, ImplVector>(48,  64, 10,  8)); break;
!   case 24: loop(t_cfar_sweep_range<float, ImplVector>(16,  16, 20, 16)); break;
! 
!   case 31: loop(t_cfar_sweep_range<double, ImplVector>(16,  24,  5,  4)); break;
!   case 32: loop(t_cfar_sweep_range<double, ImplVector>(48, 128, 10,  8)); break;
!   case 33: loop(t_cfar_sweep_range<double, ImplVector>(48,  64, 10,  8)); break;
!   case 34: loop(t_cfar_sweep_range<double, ImplVector>(16,  16, 20, 16)); break;
  
  #if __GNUC__ >= 4
!   case 41: loop(t_cfar_sweep_range<float, ImplHybrid>(16,  24,  5,  4)); break;
!   case 42: loop(t_cfar_sweep_range<float, ImplHybrid>(48, 128, 10,  8)); break;
!   case 43: loop(t_cfar_sweep_range<float, ImplHybrid>(48,  64, 10,  8)); break;
!   case 44: loop(t_cfar_sweep_range<float, ImplHybrid>(16,  16, 20, 16)); break;
  #endif // __GNUC__ >= 4
  
    default: 
