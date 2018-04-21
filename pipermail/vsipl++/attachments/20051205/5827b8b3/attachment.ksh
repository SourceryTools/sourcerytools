Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.321
diff -c -p -r1.321 ChangeLog
*** ChangeLog	5 Dec 2005 19:19:18 -0000	1.321
--- ChangeLog	5 Dec 2005 19:21:31 -0000
***************
*** 1,5 ****
--- 1,11 ----
  2005-12-05 Jules Bergmann  <jules@codesourcery.com>
  
+ 	Fix issue #95
+ 	* src/vsip/impl/eval-blas.hpp: Perform row-major outer product
+ 	  without changing input vectors.
+ 
+ 2005-12-05 Jules Bergmann  <jules@codesourcery.com>
+ 
  	Update parallel support functions to match parallel specification
  	version 0.9.
  	* src/vsip/map.hpp: Include global_map.  Change map interface
Index: src/vsip/impl/eval-blas.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/eval-blas.hpp,v
retrieving revision 1.4
diff -c -p -r1.4 eval-blas.hpp
*** src/vsip/impl/eval-blas.hpp	5 Dec 2005 15:16:17 -0000	1.4
--- src/vsip/impl/eval-blas.hpp	5 Dec 2005 19:21:31 -0000
*************** struct Evaluator<Op_prod_vv_outer, Block
*** 144,170 ****
        // BLAS does not have a function that will conjugate the first 
        // vector and allow us to take advantage of the identity:
        //   R = A B*     <=>     trans(R) = trans(B*) trans(A)
!       // This must be done manually prior to calling the library 
!       // function and undone prior to returning.
  
!       std::complex<T1> *p_src = ext_b.data();
!       std::complex<T1> *p_dst = ext_b.data();
!       for ( index_type i = 0; i < b.size(1, 0); ++i )
!         *p_dst++ = conj(*p_src++);
! 
!       blas::geru( 
          b.size(1, 0), a.size(1, 0),     // int m, int n,
!         alpha,                          // T alpha,
          ext_b.data(), ext_b.stride(0),  // T *x, int incx,
          ext_a.data(), ext_a.stride(0),  // T *y, int incy,
          ext_r.data(), r.size(2, 1)      // T *a, int lda
        );
  
!       // undo the conjugation
!       p_src = ext_b.data();
!       p_dst = ext_b.data();
!       for ( index_type i = 0; i < b.size(1, 0); ++i )
!         *p_dst++ = conj(*p_src++);
  
      }
      else if (Type_equal<order0_type, col2_type>::value)
--- 144,163 ----
        // BLAS does not have a function that will conjugate the first 
        // vector and allow us to take advantage of the identity:
        //   R = A B*     <=>     trans(R) = trans(B*) trans(A)
!       // This requires a manual conjugation after calling the library 
!       // function.
  
!       blas::gerc( 
          b.size(1, 0), a.size(1, 0),     // int m, int n,
!         std::complex<T1>(1),            // T alpha,
          ext_b.data(), ext_b.stride(0),  // T *x, int incx,
          ext_a.data(), ext_a.stride(0),  // T *y, int incy,
          ext_r.data(), r.size(2, 1)      // T *a, int lda
        );
  
!       for ( index_type i = 0; i < r.size(2, 0); ++i )
! 	for ( index_type j = 0; j < r.size(2, 1); ++j )
! 	  r.put(i, j, alpha * conj(r.get(i, j)));
  
      }
      else if (Type_equal<order0_type, col2_type>::value)
