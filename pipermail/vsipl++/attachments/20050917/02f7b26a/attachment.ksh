Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.251
diff -c -p -r1.251 ChangeLog
*** ChangeLog	17 Sep 2005 17:08:08 -0000	1.251
--- ChangeLog	17 Sep 2005 20:34:18 -0000
***************
*** 1,5 ****
--- 1,11 ----
  2005-09-17  Jules Bergmann  <jules@codesourcery.com>
  
+ 	* src/vsip/impl/signal-fft.hpp: Fix signatures to allow temporary
+ 	  views as destinations for Fft and Fftm.
+ 	* tests/regr_fft_temp_view.cpp: New file, regression for above bug.
+ 
+ 2005-09-17  Jules Bergmann  <jules@codesourcery.com>
+ 
  	* src/vsip/impl/fft-core.hpp: '-Wall' cleanup.
  	* tests/fft_ext/fft_ext.cpp: Likewise.
  
Index: src/vsip/impl/signal-fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-fft.hpp,v
retrieving revision 1.22
diff -c -p -r1.22 signal-fft.hpp
*** src/vsip/impl/signal-fft.hpp	17 Sep 2005 08:45:35 -0000	1.22
--- src/vsip/impl/signal-fft.hpp	17 Sep 2005 20:34:18 -0000
*************** public:
*** 632,638 ****
  	    template <typename, typename> class View>
      View<outT,Block1>
    operator()(constView<inT,Block0> const& in, 
! 	     View<outT,Block1>& out)
        VSIP_NOTHROW
      {
        assert(in.block().size() == this->in_temp_.size());
--- 632,638 ----
  	    template <typename, typename> class View>
      View<outT,Block1>
    operator()(constView<inT,Block0> const& in, 
! 	     View<outT,Block1> out)
        VSIP_NOTHROW
      {
        assert(in.block().size() == this->in_temp_.size());
*************** public:
*** 647,653 ****
  
    template <typename BlockT, template <typename, typename> class View>
      View<outT,BlockT>
!   operator()(View<outT,BlockT>& inout)
        VSIP_NOTHROW
      {
        assert(inout.block().size() == this->in_temp_.size());
--- 647,653 ----
  
    template <typename BlockT, template <typename, typename> class View>
      View<outT,BlockT>
!   operator()(View<outT,BlockT> inout)
        VSIP_NOTHROW
      {
        assert(inout.block().size() == this->in_temp_.size());
*************** public:
*** 962,968 ****
    template <typename Block0, typename Block1>
    vsip::Matrix<outT,Block1>
    operator()(const_Matrix<inT,Block0> const& in, 
! 	     vsip::Matrix<outT,Block1>& out)
        VSIP_NOTHROW
      {
        assert(in.block().size() == this->in_temp_.size());
--- 962,968 ----
    template <typename Block0, typename Block1>
    vsip::Matrix<outT,Block1>
    operator()(const_Matrix<inT,Block0> const& in, 
! 	     vsip::Matrix<outT,Block1> out)
        VSIP_NOTHROW
      {
        assert(in.block().size() == this->in_temp_.size());
*************** public:
*** 977,983 ****
  
    template <typename BlockT>
      vsip::Matrix<outT,BlockT>
!   operator()(vsip::Matrix<outT,BlockT>& inout)
        VSIP_NOTHROW
      {
        assert(inout.block().size() == this->out_temp_.size());
--- 977,983 ----
  
    template <typename BlockT>
      vsip::Matrix<outT,BlockT>
!   operator()(vsip::Matrix<outT,BlockT> inout)
        VSIP_NOTHROW
      {
        assert(inout.block().size() == this->out_temp_.size());
Index: tests/regr_fft_temp_view.cpp
===================================================================
RCS file: tests/regr_fft_temp_view.cpp
diff -N tests/regr_fft_temp_view.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/regr_fft_temp_view.cpp	17 Sep 2005 20:34:18 -0000
***************
*** 0 ****
--- 1,150 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    tests/regr_fft_temp_view.cpp
+     @author  Jules Bergmann
+     @date    2005-09-17
+     @brief   VSIPL++ Library: Regression test for FFTs/FFTMs into
+ 	     temporary view.
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <iostream>
+ #include <cassert>
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/initfin.hpp>
+ #include <vsip/vector.hpp>
+ #include <vsip/signal.hpp>
+ 
+ #include "test.hpp"
+ 
+ using namespace std;
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ template <typename T>
+ void
+ test_fft(length_type size)
+ {
+   Vector<T>   A(size, T());
+   Vector<T>   Z(size);
+ 
+   int const no_times = 1;
+ 
+   typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times, alg_time>
+       fft_type;
+ 
+   fft_type fft(Domain<1>(size), 1.f);
+ 
+   A = T(1);
+ 
+   // Note: Only a basic check for correctness.  Original regression
+   // was a compilation error.
+ 
+     
+   // FFT: view -> view
+   Z = T();
+   fft(A, Z);
+   assert(equal(Z(0), T(size)));
+ 
+   // FFT: view -> temporary view
+   Z = T();
+   fft(A, Z(Domain<1>(size)));
+   assert(equal(Z(0), T(size)));
+ 
+   // FFT: temporary view -> view
+   Z = T();
+   fft(A(Domain<1>(size)), Z);
+   assert(equal(Z(0), T(size)));
+ 
+   // FFT: temporary view -> temporary view
+   Z = T();
+   fft(A(Domain<1>(size)), Z(Domain<1>(size)));
+   assert(equal(Z(0), T(size)));
+ 
+ 
+   // FFT: in-place into view
+   Z = A;
+   fft(Z);
+   assert(equal(Z(0), T(size)));
+ 
+   // FFT: in-place into temporary view
+   Z = A;
+   fft(Z(Domain<1>(size)));
+   assert(equal(Z(0), T(size)));
+ }
+ 
+ 
+ 
+ template <int      SD,
+ 	  typename T>
+ void
+ test_fftm(length_type rows, length_type cols)
+ {
+   Matrix<T>   A(rows, cols, T());
+   Matrix<T>   Z(rows, cols);
+ 
+   int const no_times = 1;
+ 
+   typedef Fftm<T, T, SD, fft_fwd, by_reference, no_times, alg_time>
+       fftm_type;
+ 
+   fftm_type fftm(Domain<2>(rows, cols), 1.f);
+ 
+   A = T(1);
+ 
+   // Note: Only a basic check for correctness.  Original regression
+   // was a compilation error.
+     
+   // FFTM: view -> view
+   Z = T();
+   fftm(A, Z);
+   assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
+ 
+   // FFTM: view -> temp view
+   Z = T();
+   fftm(A, Z(Domain<2>(rows, cols)));
+   assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
+ 
+   // FFTM: view -> temp view
+   Z = T();
+   fftm(A(Domain<2>(rows, cols)), Z);
+   assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
+ 
+   // FFTM: temp view -> temp view
+   Z = T();
+   fftm(A(Domain<2>(rows, cols)), Z(Domain<2>(rows, cols)));
+   assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
+ 
+ 
+   // FFTM: in-place view
+   Z = A;
+   fftm(Z);
+   assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
+ 
+   // FFTM: in-place temporary view
+   Z = A;
+   fftm(Z(Domain<2>(rows, cols)));
+   assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
+ }
+ 
+ 
+ 
+ 
+ int
+ main()
+ {
+   vsipl init;
+ 
+   test_fft<complex<float> >(32);
+   test_fftm<0, complex<float> >(8, 16);
+   test_fftm<1, complex<float> >(8, 16);
+ }
