Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.259
diff -c -p -r1.259 ChangeLog
*** ChangeLog	18 Sep 2005 22:03:43 -0000	1.259
--- ChangeLog	18 Sep 2005 22:06:52 -0000
***************
*** 1,5 ****
--- 1,14 ----
  2005-09-18  Jules Bergmann  <jules@codesourcery.com>
  
+ 	* tests/tensor-tranpose.cpp (USE_TRANSPOSE_VIEW_TYPEDEF): Work
+ 	  around conflicting GCC/ICC requirements for 'typename' keyword.
+ 	  (HAVE_TRANSPOSE): remove it.
+ 	* tests/test-precision.hpp: Make temporaries volatile to avoid
+ 	  ICC FP optimization that artificially increases precision
+ 	  while measuring precision.
+ 
+ 2005-09-18  Jules Bergmann  <jules@codesourcery.com>
+ 
  	* src/vsip/impl/signal-fft.hpp: Fix signatures to allow temporary
  	  views as destinations for Fft and Fftm.
  	* tests/regr_fft_temp_view.cpp: New file, regression for above bug.
Index: tests/tensor-transpose.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/tensor-transpose.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 tensor-transpose.cpp
*** tests/tensor-transpose.cpp	29 Aug 2005 01:56:18 -0000	1.3
--- tests/tensor-transpose.cpp	18 Sep 2005 22:06:53 -0000
***************
*** 19,25 ****
  
  #include "test.hpp"
  
! #define HAVE_TRANSPOSE 1
  
  
  
--- 19,25 ----
  
  #include "test.hpp"
  
! #define USE_TRANSPOSE_VIEW_TYPEDEF 1
  
  
  
*************** test_transpose_readonly(TensorT view)
*** 89,105 ****
    // Check that view is initialized
    check_tensor(view, 0);
  
- #if HAVE_TRANSPOSE
    length_type const size1 = view.size(1);
    length_type const size2 = view.size(2);
  
    typename TensorT::template transpose_view<D0, D1, D2>::type trans =
      view.template transpose<D0, D1, D2>();
  
    assert(trans.size(0) == view.size(D0));
    assert(trans.size(1) == view.size(D1));
    assert(trans.size(2) == view.size(D2));
- #endif
  
    // Build a reverse dimension map
    dimension_type R0, R1, R2;
--- 89,109 ----
    // Check that view is initialized
    check_tensor(view, 0);
  
    length_type const size1 = view.size(1);
    length_type const size2 = view.size(2);
  
+ #if USE_TRANSPOSE_VIEW_TYPEDEF
+   typedef typename TensorT::template transpose_view<D0, D1, D2>::type trans_t;
+   trans_t trans = view.template transpose<D0, D1, D2>();
+ #else
+   // ICC-9.0 does not like initial 'typename'.
    typename TensorT::template transpose_view<D0, D1, D2>::type trans =
      view.template transpose<D0, D1, D2>();
+ #endif
  
    assert(trans.size(0) == view.size(D0));
    assert(trans.size(1) == view.size(D1));
    assert(trans.size(2) == view.size(D2));
  
    // Build a reverse dimension map
    dimension_type R0, R1, R2;
*************** test_transpose_readonly(TensorT view)
*** 116,122 ****
    else if (D2 == 1) R1 = 2;
    else if (D2 == 2) R2 = 2;
  
- #if HAVE_TRANSPOSE
    // Sanity check reverse map
    assert(trans.size(R0) == view.size(0));
    assert(trans.size(R1) == view.size(1));
--- 120,125 ----
*************** test_transpose_readonly(TensorT view)
*** 139,145 ****
  
    // Check that view is unchanged
    check_tensor(view, 0);
- #endif
  }
  
  
--- 142,147 ----
*************** test_transpose(TensorT view)
*** 156,172 ****
    // Check that view is initialized
    check_tensor(view, 0);
  
- #if HAVE_TRANSPOSE
    length_type const size1 = view.size(1);
    length_type const size2 = view.size(2);
  
    typename TensorT::template transpose_view<D0, D1, D2>::type trans =
      view.template transpose<D0, D1, D2>();
  
    assert(trans.size(0) == view.size(D0));
    assert(trans.size(1) == view.size(D1));
    assert(trans.size(2) == view.size(D2));
- #endif
  
    // Build a reverse dimension map
    dimension_type R0, R1, R2;
--- 158,178 ----
    // Check that view is initialized
    check_tensor(view, 0);
  
    length_type const size1 = view.size(1);
    length_type const size2 = view.size(2);
  
+ #if USE_TRANSPOSE_VIEW_TYPEDEF
+   typedef typename TensorT::template transpose_view<D0, D1, D2>::type trans_t;
+   trans_t trans = view.template transpose<D0, D1, D2>();
+ #else
+   // ICC-9.0 does not like initial 'typename'.
    typename TensorT::template transpose_view<D0, D1, D2>::type trans =
      view.template transpose<D0, D1, D2>();
+ #endif
  
    assert(trans.size(0) == view.size(D0));
    assert(trans.size(1) == view.size(D1));
    assert(trans.size(2) == view.size(D2));
  
    // Build a reverse dimension map
    dimension_type R0, R1, R2;
*************** test_transpose(TensorT view)
*** 183,189 ****
    else if (D2 == 1) R1 = 2;
    else if (D2 == 2) R2 = 2;
  
- #if HAVE_TRANSPOSE
    // Sanity check reverse map
    assert(trans.size(R0) == view.size(0));
    assert(trans.size(R1) == view.size(1));
--- 189,194 ----
*************** test_transpose(TensorT view)
*** 214,220 ****
  
    // Check that view is changed
    check_tensor(view, 1);
- #endif
  }
  
  
--- 219,224 ----
Index: tests/test-precision.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/test-precision.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 test-precision.hpp
*** tests/test-precision.hpp	13 Sep 2005 16:39:45 -0000	1.1
--- tests/test-precision.hpp	18 Sep 2005 22:06:53 -0000
*************** struct Precision_traits
*** 35,42 ****
    {
      eps = scalar_type(1);
  
!     scalar_type a = 1.0 + eps;
!     scalar_type b = 1.0;
  
      while (a - b != scalar_type())
      {
--- 35,44 ----
    {
      eps = scalar_type(1);
  
!     // Without 'volatile', ICC avoid rounding and compute precision of
!     // long double for all types.
!     volatile scalar_type a = 1.0 + eps;
!     volatile scalar_type b = 1.0;
  
      while (a - b != scalar_type())
      {
