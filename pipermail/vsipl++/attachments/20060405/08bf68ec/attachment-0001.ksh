
Index: benchmarks/benchmarks.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/benchmarks.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 benchmarks.hpp
*** benchmarks/benchmarks.hpp	3 Apr 2006 19:17:15 -0000	1.2
--- benchmarks/benchmarks.hpp	5 Apr 2006 14:44:26 -0000
*************** equal(vsip::complex<T> val1, vsip::compl
*** 233,238 ****
--- 233,260 ----
           equal(val1.imag(), val2.imag());
  }
  
+ template <typename T, typename Block1, typename Block2>
+ inline bool
+ view_equal(vsip::const_Vector<T, Block1> v, vsip::const_Vector<T, Block2> w)
+ {
+   if (v.size() != w.size()) return false;
+   for (vsip::length_type i = 0; i != v.size(); ++i)
+     if (!equal(v.get(i), w.get(i)))
+       return false;
+   return true;
+ }
+ 
+ template <typename T, typename Block1, typename Block2>
+ inline bool
+ view_equal(vsip::const_Matrix<T, Block1> v, vsip::const_Matrix<T, Block2> w)
+ {
+   if (v.size(0) != w.size(0) || v.size(1) != w.size(1)) return false;
+   for (vsip::length_type i = 0; i != v.size(0); ++i)
+     for (vsip::length_type j = 0; j != v.size(1); ++j)
+       if (!equal(v.get(i, j), w.get(i, j)))
+ 	return false;
+   return true;
+ }
  
  
  
Index: benchmarks/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/fft.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 fft.cpp
*** benchmarks/fft.cpp	3 Mar 2006 14:30:53 -0000	1.4
--- benchmarks/fft.cpp	5 Apr 2006 14:44:26 -0000
***************
*** 17,26 ****
  #include <vsip/support.hpp>
  #include <vsip/math.hpp>
  #include <vsip/signal.hpp>
- #include <vsip/impl/profile.hpp>
  
! #include "test.hpp"
! #include "loop.hpp"
  
  using namespace vsip;
  
--- 17,24 ----
  #include <vsip/support.hpp>
  #include <vsip/math.hpp>
  #include <vsip/signal.hpp>
  
! #include "benchmarks.hpp"
  
  using namespace vsip;
  
*************** struct t_fft_op
*** 63,69 ****
        fft(A, Z);
      t1.stop();
      
!     if (!equal(Z(0), T(scale_ ? 1 : size)))
      {
        std::cout << "t_fft_op: ERROR" << std::endl;
        abort();
--- 61,67 ----
        fft(A, Z);
      t1.stop();
      
!     if (!equal(Z.get(0), T(scale_ ? 1 : size)))
      {
        std::cout << "t_fft_op: ERROR" << std::endl;
        abort();
*************** struct t_fft_ip
*** 108,114 ****
        fft(A);
      t1.stop();
      
!     if (!equal(A(0), T(0)))
      {
        std::cout << "t_fft_ip: ERROR" << std::endl;
        abort();
--- 106,112 ----
        fft(A);
      t1.stop();
      
!     if (!equal(A.get(0), T(0)))
      {
        std::cout << "t_fft_ip: ERROR" << std::endl;
        abort();
Index: benchmarks/firbank.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/firbank.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 firbank.cpp
*** benchmarks/firbank.cpp	3 Apr 2006 19:17:15 -0000	1.1
--- benchmarks/firbank.cpp	5 Apr 2006 14:44:26 -0000
*************** struct t_firbank_base<T, ImplFast> : pub
*** 243,249 ****
      if ( N > 2*(K-1) )
      {
        vsip::Domain<2> middle( Domain<1>(local_M), Domain<1>(K-1, 1, N-2*(K-1)) );
!       assert( view_equal(outputs.local()(middle), expected.local()(middle)) );
      }
    }
  
--- 243,249 ----
      if ( N > 2*(K-1) )
      {
        vsip::Domain<2> middle( Domain<1>(local_M), Domain<1>(K-1, 1, N-2*(K-1)) );
!       assert( view_equal(LOCAL(outputs)(middle), LOCAL(expected)(middle)) );
      }
    }
  
