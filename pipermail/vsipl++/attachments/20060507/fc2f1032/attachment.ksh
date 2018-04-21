
Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.454
diff -c -p -r1.454 ChangeLog
*** ChangeLog	7 May 2006 17:13:51 -0000	1.454
--- ChangeLog	7 May 2006 19:33:45 -0000
***************
*** 1,3 ****
--- 1,14 ----
+ 2006-05-07  Don McCoy  <don@codesourcery.com>
+ 
+ 	* src/vsip/impl/sal/solver_lu.hpp: Added support for
+ 	  double by using older SAL functions matlud, vrecip and 
+ 	  matfbs.  A compile-time switch enables a choice between
+ 	  the new and the old functions.  The new ones support
+ 	  transpose options (A' x = b) but only work for single-
+ 	  precision values.  When using the old set of functions,
+ 	  an exception will be thrown if the transpose option is
+ 	  anything but 'mat_ntrans'.
+ 	
  2006-05-07  Jules Bergmann  <jules@codesourcery.com>
  
  	* src/vsip/impl/rt_extdata.hpp (block_layout): New function,
Index: src/vsip/impl/sal/solver_lu.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/solver_lu.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 solver_lu.hpp
*** src/vsip/impl/sal/solver_lu.hpp	14 Apr 2006 21:42:08 -0000	1.1
--- src/vsip/impl/sal/solver_lu.hpp	7 May 2006 19:33:45 -0000
***************
*** 1,4 ****
! /* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
  
  /** @file    vsip/impl/sal/solver_lu.hpp
      @author  Assem Salama
--- 1,4 ----
! /* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
  
  /** @file    vsip/impl/sal/solver_lu.hpp
      @author  Assem Salama
***************
*** 26,31 ****
--- 26,38 ----
  
  #include <sal.h>
  
+ // This switch chooses between two sets of LUD-related functions provided 
+ // by SAL.  Setting to '1' will select the newer mat_lud_sol/dec() variants 
+ // and setting it to '0' will select the older matlud() and matfbs() pair.
+ 
+ #define VSIP_IMPL_SAL_USE_MAT_LUD  0
+ 
+ 
  
  /***********************************************************************
    Declarations
*************** struct Is_lud_impl_avail<Mercury_sal_tag
*** 51,56 ****
--- 58,77 ----
    static bool const value = true;
  };
  
+ #if !VSIP_IMPL_SAL_USE_MAT_LUD
+ template <>
+ struct Is_lud_impl_avail<Mercury_sal_tag, double>
+ {
+   static bool const value = true;
+ };
+ 
+ template <>
+ struct Is_lud_impl_avail<Mercury_sal_tag, complex<double> >
+ {
+   static bool const value = true;
+ };
+ #endif
+ 
  // SAL LUD decomposition functions
  #define VSIP_IMPL_SAL_LUD_DEC( T, D_T, SAL_T, SALFCN ) \
  inline bool                          \
*************** VSIP_IMPL_SAL_LUD_DEC(complex<float>,   
*** 81,86 ****
--- 102,108 ----
  VSIP_IMPL_SAL_LUD_DEC_SPLIT(float,             int,COMPLEX_SPLIT,zmat_lud_dec)
  
  #undef VSIP_IMPL_SAL_LUD_DEC
+ #undef VSIP_IMPL_SAL_LUD_DEC_SPLIT
  
  
  // SAL LUD solver functions
*************** sal_mat_lud_sol(                        
*** 109,120 ****
     (D_T*) d,(SAL_T*)&b,(SAL_T*)&w,                 \
     n,flag) == SAL_SUCCESS);                        \
  }
! // Declare LUD decomposition functions
  VSIP_IMPL_SAL_LUD_SOL(float,         int,float,        mat_lud_sol)
  VSIP_IMPL_SAL_LUD_SOL(complex<float>,int,COMPLEX,      cmat_lud_sol)
  VSIP_IMPL_SAL_LUD_SOL_SPLIT(float,   int,COMPLEX_SPLIT,zmat_lud_sol)
  
  #undef VSIP_IMPL_SAL_LUD_SOL
  
  
  /// LU factorization implementation class.  Common functionality
--- 131,262 ----
     (D_T*) d,(SAL_T*)&b,(SAL_T*)&w,                 \
     n,flag) == SAL_SUCCESS);                        \
  }
! // Declare LUD solver functions
  VSIP_IMPL_SAL_LUD_SOL(float,         int,float,        mat_lud_sol)
  VSIP_IMPL_SAL_LUD_SOL(complex<float>,int,COMPLEX,      cmat_lud_sol)
  VSIP_IMPL_SAL_LUD_SOL_SPLIT(float,   int,COMPLEX_SPLIT,zmat_lud_sol)
  
  #undef VSIP_IMPL_SAL_LUD_SOL
+ #undef VSIP_IMPL_SAL_LUD_SOL_SPLIT
+ 
+ 
+ 
+ // "Legacy" SAL functions - The single-precision versions are listed
+ // in the Appendix of the SAL Reference manual.  Although the double-
+ // precision ones are still part of the normal API, we refer to both 
+ // sets of functions as legacy functions just for ease of naming.
+ 
+ // This function is not provided by SAL but is similar to
+ // vrecip() which works on floats.
+ inline void 
+ vrecipd( double *A, int I, double *C, int K, int N )
+ {
+   while ( N-- )
+   {
+     *C = 1.0 / *A;
+     A += I;
+     C += K;
+   }
+ }
+ 
+ // Legacy SAL LUD decomposition functions
+ // Note that the stride may be passed to the reciprocal function,
+ // however, the decomposition functions work only with unit strides.
+ 
+ #define VSIP_IMPL_SAL_LUD_DEC( T, SAL_T, SALRECP, SALFCN ) \
+ inline void                  \
+ sal_matlud(                  \
+   T *r,                      \
+   T *c,                      \
+   int *d, int n)             \
+ {                            \
+   SALFCN((SAL_T*) c, d, n);  \
+   SALRECP((SAL_T*) c, n+1,   \
+           (SAL_T*) r, 1, n); \
+ }
+ 
+ #define VSIP_IMPL_SAL_LUD_DEC_CPLX( T, SAL_T, SALRECP, SALFCN ) \
+ inline void                    \
+ sal_matlud(                    \
+   T *r,                        \
+   T *c,                        \
+   int *d, int n)               \
+ {                              \
+   SALFCN((SAL_T*) c, d, n);    \
+   SALRECP((SAL_T*) c, 2*(n+1), \
+           (SAL_T*) r, 2, n);   \
+ }
+ 
+ #define VSIP_IMPL_SAL_LUD_DEC_SPLIT( T, SAL_T, SALRECP, SALFCN ) \
+ inline void                   \
+ sal_matlud(                   \
+   std::pair<T*,T*> r,         \
+   std::pair<T*,T*> c,         \
+   int *p, int n)              \
+ {                             \
+   SALFCN((SAL_T*) &c, p, n);  \
+   SALRECP((SAL_T*) &c, n+1,   \
+           (SAL_T*) &r, 1, n); \
+ }
+ // Declare LUD decomposition functions
+ VSIP_IMPL_SAL_LUD_DEC(float,           float,                vrecip,  matlud)
+ VSIP_IMPL_SAL_LUD_DEC(double,          double,               vrecipd, matludd)
+ VSIP_IMPL_SAL_LUD_DEC(complex<float>,  COMPLEX,              cvrcip,  cmatlud)
+ VSIP_IMPL_SAL_LUD_DEC(complex<double>, DOUBLE_COMPLEX,       cvrcipd, cmatludd)
+ VSIP_IMPL_SAL_LUD_DEC_SPLIT(float,     COMPLEX_SPLIT,        zvrcip,  zmatlud)
+ VSIP_IMPL_SAL_LUD_DEC_SPLIT(double,    DOUBLE_COMPLEX_SPLIT, zvrcipd, zmatludd)
+ 
+ #undef VSIP_IMPL_SAL_LUD_DEC
+ #undef VSIP_IMPL_SAL_LUD_DEC_CPLX
+ #undef VSIP_IMPL_SAL_LUD_DEC_SPLIT
+ 
+ 
+ // Legacy LUD solver functions
+ // Note that the stride may be passed when using complex types, 
+ // but not with scalar types.  As a result, complex types are 
+ // restricted to "dense" equivalents (2 for complex interleaved
+ // and 1 for complex split in SAL terms).
+ 
+ #define VSIP_IMPL_SAL_LUD_SOL( T, SAL_T, SALFCN ) \
+ inline void                           \
+ sal_matfbs(                           \
+   T *a, T *b, int *p,                 \
+   T *c, T *d, int n )                 \
+ {                                     \
+   SALFCN( (SAL_T*) a, (SAL_T*) b, p,  \
+           (SAL_T*) c, (SAL_T*) d, n); \
+ }
+ #define VSIP_IMPL_SAL_LUD_SOL_CPLX( T, SAL_T, SALFCN ) \
+ inline void                              \
+ sal_matfbs(                              \
+   T *a, T *b, int *p,                    \
+   T *c, T *d, int n )                    \
+ {                                        \
+   SALFCN( (SAL_T*) a, (SAL_T*) b, p,     \
+           (SAL_T*) c, (SAL_T*) d, 2, n); \
+ }
+ #define VSIP_IMPL_SAL_LUD_SOL_SPLIT( T, SAL_T, SALFCN ) \
+ inline void                                        \
+ sal_matfbs(                                        \
+   std::pair<T*,T*> a, std::pair<T*,T*> b, int *p,  \
+   std::pair<T*,T*> c, std::pair<T*,T*> d, int n )  \
+ {                                                  \
+   SALFCN( (SAL_T*) &a, (SAL_T*) &b, p,             \
+           (SAL_T*) &c, (SAL_T*) &d, 1, n);         \
+ }
+ // Declare LUD solver functions
+ VSIP_IMPL_SAL_LUD_SOL(float,                float,                matfbs)
+ VSIP_IMPL_SAL_LUD_SOL(double,               double,               matfbsd)
+ VSIP_IMPL_SAL_LUD_SOL_CPLX(complex<float>,  COMPLEX,              cmatfbs)
+ VSIP_IMPL_SAL_LUD_SOL_CPLX(complex<double>, DOUBLE_COMPLEX,       cmatfbsd)
+ VSIP_IMPL_SAL_LUD_SOL_SPLIT(float,          COMPLEX_SPLIT,        zmatfbs)
+ VSIP_IMPL_SAL_LUD_SOL_SPLIT(double,         DOUBLE_COMPLEX_SPLIT, zmatfbsd)
+ 
+ #undef VSIP_IMPL_SAL_LUD_SOL
+ #undef VSIP_IMPL_SAL_LUD_SOL_CPLX
+ #undef VSIP_IMPL_SAL_LUD_SOL_SPLIT
+ 
+ 
  
  
  /// LU factorization implementation class.  Common functionality
*************** class Lud_impl<T,Mercury_sal_tag>
*** 138,143 ****
--- 280,287 ----
    typedef Layout<2, col2_type, Stride_unit_dense, complex_type> b_data_LP;
    typedef Fast_block<2, T, b_data_LP> b_data_block_type;
  
+   typedef Dense<1, T> reciprocals_block_type;
+ 
    // Constructors, copies, assignments, and destructors.
  public:
    Lud_impl(length_type)
*************** public:
*** 159,179 ****
  
  protected:
    template <mat_op_type tr,
! 	    typename    Block0,
! 	    typename    Block1>
    bool impl_solve(const_Matrix<T, Block0>, Matrix<T, Block1>)
      VSIP_NOTHROW;
  
    // Member data.
  private:
    typedef std::vector<int, Aligned_allocator<int> > vector_type;
  
!   length_type  length_;			// Order of A.
!   vector_type  ipiv_;			// Pivot table for Q. This gets
!                                         // generated from the decompose and
! 					// gets used in the solve
! 
!   Matrix<T, data_block_type> data_;	// Factorized matrix (A)
  };
  
  
--- 303,326 ----
  
  protected:
    template <mat_op_type tr,
!             typename    Block0,
!             typename    Block1>
    bool impl_solve(const_Matrix<T, Block0>, Matrix<T, Block1>)
      VSIP_NOTHROW;
  
+   length_type max_decompose_size();
+ 
    // Member data.
  private:
    typedef std::vector<int, Aligned_allocator<int> > vector_type;
  
!   length_type  length_;                      // Order of A.
!   vector_type  ipiv_;                        // Pivot table for Q. This gets
!                                              // generated from the decompose and
!                                              // gets used in the solve
!   Vector<T, reciprocals_block_type> recip_;  // Vector of reciprocals used
!                                              // with legacy solvers
!   Matrix<T, data_block_type> data_;          // Factorized matrix (A)
  };
  
  
*************** Lud_impl<T,Mercury_sal_tag>::Lud_impl(
*** 191,196 ****
--- 338,344 ----
  VSIP_THROW((std::bad_alloc))
    : length_ (length),
      ipiv_   (length_),
+     recip_  (length_),
      data_   (length_, length_)
  {
    assert(length_ > 0);
*************** Lud_impl<T,Mercury_sal_tag>::Lud_impl(Lu
*** 203,213 ****
--- 351,365 ----
  VSIP_THROW((std::bad_alloc))
    : length_ (lu.length_),
      ipiv_   (length_),
+     recip_  (length_),
      data_   (length_, length_)
  {
    data_ = lu.data_;
    for (index_type i=0; i<length_; ++i)
+   {
      ipiv_[i] = lu.ipiv_[i];
+     recip_ = lu.recip_;
+   }
  }
  
  
*************** Lud_impl<T,Mercury_sal_tag>::~Lud_impl()
*** 219,224 ****
--- 371,384 ----
  }
  
  
+ template <typename T>
+ length_type
+ Lud_impl<T, Mercury_sal_tag>::max_decompose_size()
+ {
+   return (impl::Is_complex<T>::value ? 512 : 1024);
+ }
+ 
+ 
  
  /// Form LU factorization of matrix A
  ///
*************** Lud_impl<T,Mercury_sal_tag>::decompose(M
*** 239,254 ****
  
    assign_local(data_, m);
  
!   Ext_data<data_block_type> ext(data_.block());
! 
    bool success;
  
    if(length_ > 1) 
    {
      success = sal_mat_lud_dec(
!                      ext.data(),ext.stride(0),
!       		     &ipiv_[0], length_);
! 
    }
    else 
    {
--- 399,421 ----
  
    assign_local(data_, m);
  
!   Ext_data<data_block_type> a_ext(data_.block());
!   Ext_data<reciprocals_block_type> r_ext(recip_.block());
    bool success;
  
    if(length_ > 1) 
    {
+ #if VSIP_IMPL_SAL_USE_MAT_LUD
      success = sal_mat_lud_dec(
!                      a_ext.data(),a_ext.stride(0),
!                      &ipiv_[0], length_);
! #else
!     if (length_ > max_decompose_size())
!       VSIP_IMPL_THROW(unimplemented(
!         "Lud_impl<T,Mercury_sal_tag>::decompose - exceeds maximum size"));
!     success = true;
!     sal_matlud(r_ext.data(), a_ext.data(), &ipiv_[0], length_);
! #endif
    }
    else 
    {
*************** Lud_impl<T,Mercury_sal_tag>::decompose(M
*** 274,281 ****
  
  template <typename T>
  template <mat_op_type tr,
! 	  typename    Block0,
! 	  typename    Block1>
  bool
  Lud_impl<T,Mercury_sal_tag>::impl_solve(
    const_Matrix<T, Block0> b,
--- 441,448 ----
  
  template <typename T>
  template <mat_op_type tr,
!           typename    Block0,
!           typename    Block1>
  bool
  Lud_impl<T,Mercury_sal_tag>::impl_solve(
    const_Matrix<T, Block0> b,
*************** Lud_impl<T,Mercury_sal_tag>::impl_solve(
*** 315,334 ****
      }
      Ext_data<data_block_type>   a_ext((tr == mat_trans)?
                                          data_int.block():data_.block());
  
      // sal_mat_lud_sol only takes vectors, so, we have to do this for each
      // column in the matrix
      ptr_type b_ptr = b_ext.data();
      ptr_type x_ptr = x_ext.data();
!     for(index_type i=0;i<b.size(1);i++) {
        sal_mat_lud_sol(a_ext.data(), a_ext.stride(0),
                        &ipiv_[0],
! 		      storage_type::offset(b_ptr,i*length_),
! 	   	      storage_type::offset(x_ptr,i*length_),
! 		      length_,trans);
      }
  
- 
      assign_local(x, x_int);
    }
    else 
--- 482,513 ----
      }
      Ext_data<data_block_type>   a_ext((tr == mat_trans)?
                                          data_int.block():data_.block());
+     Ext_data<reciprocals_block_type>  r_ext(recip_.block());
  
      // sal_mat_lud_sol only takes vectors, so, we have to do this for each
      // column in the matrix
      ptr_type b_ptr = b_ext.data();
      ptr_type x_ptr = x_ext.data();
!     for(index_type i=0;i<b.size(1);i++) 
!     {
! #if VSIP_IMPL_SAL_USE_MAT_LUD
        sal_mat_lud_sol(a_ext.data(), a_ext.stride(0),
                        &ipiv_[0],
!                       storage_type::offset(b_ptr,i*length_),
!                       storage_type::offset(x_ptr,i*length_),
!                       length_,trans);
! #else
!       if (tr == mat_ntrans)
!         sal_matfbs(a_ext.data(), r_ext.data(), &ipiv_[0],
!                    storage_type::offset(b_ptr, i*length_),
!                    storage_type::offset(x_ptr, i*length_),
!                    length_);
!       else
!         VSIP_IMPL_THROW(unimplemented(
!           "Lud_impl<mat_op_type!=mat_ntrans>::impl_solve - unimplemented"));
! #endif
      }
  
      assign_local(x, x_int);
    }
    else 
