Index: benchmarks/hpec_kernel/firbank.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/hpec_kernel/firbank.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 firbank.cpp
*** benchmarks/hpec_kernel/firbank.cpp	25 May 2006 19:06:49 -0000	1.2
--- benchmarks/hpec_kernel/firbank.cpp	8 Jun 2006 08:27:50 -0000
*************** struct t_local_view
*** 91,96 ****
--- 91,124 ----
    ImplFull: built-in FIR 
  ***********************************************************************/
  
+ template<
+   typename T,
+   typename Block
+   >
+ struct fir_filters
+ {
+   typedef Fir<T, nonsym, state_no_save, 1> fir_type;
+ 
+   fir_filters(length_type M, length_type N, Matrix<T, Block> filters)
+     : num_filters_(M)
+   {
+     bank_ = new fir_type*[M];
+     for ( length_type i = 0; i < M; ++i )
+       bank_[i] = new fir_type(LOCAL(filters).row(i), N, 1);
+   }
+ 
+   ~fir_filters()
+   {
+     for ( length_type i = 0; i < num_filters_; ++i )
+       delete bank_[i];
+     delete[] bank_;
+   }
+ 
+ // data members
+   fir_type** bank_;
+   const length_type num_filters_;
+ };
+ 
  template <typename T>
  struct t_firbank_base<T, ImplFull> : public t_local_view<T>
  {
*************** struct t_firbank_base<T, ImplFull> : pub
*** 121,131 ****
      length_type local_M = LOCAL(inputs).size(0);
      length_type N = inputs.row(0).size();
  
!     typedef Fir<T, nonsym, state_no_save, 1> fir_type;
!     fir_type** fir = new fir_type*[local_M];
!     for ( length_type i = 0; i < local_M; ++i )
!       fir[i] = new fir_type(LOCAL(filters).row(i), N, 1);
! 
  
      vsip::impl::profile::Timer t1;
      
--- 149,156 ----
      length_type local_M = LOCAL(inputs).size(0);
      length_type N = inputs.row(0).size();
  
!     fir_filters<T, Block2> fir(local_M, N, filters);
!     
  
      vsip::impl::profile::Timer t1;
      
*************** struct t_firbank_base<T, ImplFull> : pub
*** 134,151 ****
      {
        // Perform FIR convolutions
        for ( length_type i = 0; i < local_M; ++i )
!         (*fir[i])( LOCAL(inputs).row(i), LOCAL(outputs).row(i) );
      }
      t1.stop();
      time = t1.delta();
  
      // Verify data
      assert( view_equal(LOCAL(outputs), LOCAL(expected)) );
- 
-     // Clean up
-     for ( length_type i = 0; i < local_M; ++i )
-       delete fir[i];
-     delete[] fir;
    }
  
    t_firbank_base(length_type filters, length_type coeffs)
--- 159,171 ----
      {
        // Perform FIR convolutions
        for ( length_type i = 0; i < local_M; ++i )
!         (*fir.bank_[i])( LOCAL(inputs).row(i), LOCAL(outputs).row(i) );
      }
      t1.stop();
      time = t1.delta();
  
      // Verify data
      assert( view_equal(LOCAL(outputs), LOCAL(expected)) );
    }
  
    t_firbank_base(length_type filters, length_type coeffs)
