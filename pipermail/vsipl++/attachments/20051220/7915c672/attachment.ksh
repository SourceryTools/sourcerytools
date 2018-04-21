Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.340
diff -c -p -r1.340 ChangeLog
*** ChangeLog	20 Dec 2005 03:01:32 -0000	1.340
--- ChangeLog	20 Dec 2005 12:39:18 -0000
***************
*** 1,3 ****
--- 1,14 ----
+ 2005-12-20 Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	Add missing conversions for Lvalue_proxy.  Fixes issue #51.
+ 	* src/vsip/impl/lvalue-proxy.hpp: Add operator= specializations
+ 	  for lvalues of complex.
+ 	* tests/test.hpp: Add equal specialization for Lvalue_proxies.
+ 
+ 	* tests/*.{hpp,cpp}: Use test_assert() instead of assert().
+ 	* tests/output.hpp: Move definitions into vsip namespace.
+ 	* src/vsip/impl/signal-fir.hpp: Fix Wall warnings.
+ 
  2005-12-19 Jules Bergmann  <jules@codesourcery.com>
  
  	* src/vsip/signal.hpp: Include signal-iir.
Index: src/vsip/impl/lvalue-proxy.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/lvalue-proxy.hpp,v
retrieving revision 1.4
diff -c -p -r1.4 lvalue-proxy.hpp
*** src/vsip/impl/lvalue-proxy.hpp	16 Sep 2005 22:03:20 -0000	1.4
--- src/vsip/impl/lvalue-proxy.hpp	20 Dec 2005 12:39:18 -0000
*************** struct Modify_operators
*** 52,58 ****
  /// The generic lvalue proxy class.  All the meat is in per-dimension
  /// specializations.  Note that the default copy constructor and
  /// destructor are correct for this class.
! template <typename Block, int Dim = Block::dim> class Lvalue_proxy;
  
  /// Lvalue proxy for 1-dimensional blocks.
  template <typename Block>
--- 52,58 ----
  /// The generic lvalue proxy class.  All the meat is in per-dimension
  /// specializations.  Note that the default copy constructor and
  /// destructor are correct for this class.
! template <typename Block, dimension_type Dim = Block::dim> class Lvalue_proxy;
  
  /// Lvalue proxy for 1-dimensional blocks.
  template <typename Block>
*************** public:
*** 213,218 ****
--- 213,242 ----
      { return block_.impl_ref(i, j, k); }
  };
  
+ template <typename       Block,
+ 	  dimension_type Dim,
+ 	  typename       T>
+ bool
+ operator==(
+   Lvalue_proxy<Block, Dim> v1,
+   std::complex<T>          v2)
+ {
+   typedef typename Lvalue_proxy<Block, Dim>::value_type value_type;
+   return static_cast<value_type>(v1) == v2;
+ }
+ 
+ template <typename       Block,
+ 	  dimension_type Dim,
+ 	  typename       T>
+ bool
+ operator==(
+   std::complex<T>          v1,
+   Lvalue_proxy<Block, Dim> v2)
+ {
+   typedef typename Lvalue_proxy<Block, Dim>::value_type value_type;
+   return static_cast<value_type>(v2) == v1;
+ }
+ 
  } // namespace vsip::impl
  } // namespace vsip
  
Index: src/vsip/impl/signal-fir.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-fir.hpp,v
retrieving revision 1.7
diff -c -p -r1.7 signal-fir.hpp
*** src/vsip/impl/signal-fir.hpp	20 Dec 2005 03:01:32 -0000	1.7
--- src/vsip/impl/signal-fir.hpp	20 Dec 2005 12:39:19 -0000
*************** struct Fir_driver
*** 54,62 ****
    // code that calls this should be elided by the optimizer.
    static void
    run_fir(
!       T const* xin, T* xout, vsip::length_type outsize,
!       T const* xkernel, vsip::length_type ksize,  
!       T* xstate, vsip::length_type* xstate_ix, vsip::length_type dec)
      { assert(false); }
  };
  
--- 54,63 ----
    // code that calls this should be elided by the optimizer.
    static void
    run_fir(
!      T const* /*xin*/, T* /*xout*/, vsip::length_type /*outsize*/,
!      T const* /*xkernel*/, vsip::length_type /*ksize*/,  
!      T* /*xstate*/, vsip::length_type* /*xstate_ix*/,
!      vsip::length_type /*dec*/)
      { assert(false); }
  };
  
Index: tests/appmap.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/appmap.cpp,v
retrieving revision 1.8
diff -c -p -r1.8 appmap.cpp
*** tests/appmap.cpp	5 Dec 2005 19:19:19 -0000	1.8
--- tests/appmap.cpp	20 Dec 2005 12:39:19 -0000
***************
*** 10,16 ****
    Included Files
  ***********************************************************************/
  
- #include <cassert>
  #include <vsip/support.hpp>
  #include <vsip/map.hpp>
  #include <vsip/matrix.hpp>
--- 10,15 ----
*************** check_local_vs_global(
*** 99,109 ****
    Domain<Dim> gdom = map.template global_domain<Dim>(sb, p);
    Domain<Dim> ldom = map.template local_domain<Dim>(sb, p);
  
!   assert(gdom.size() == ldom.size());
  
    for (dimension_type d=0; d<Dim; ++d)
    {
!     assert(gdom[d].length() == ldom[d].length());
  
      for (index_type i=0; i<ldom[d].length(); ++i)
      {
--- 98,108 ----
    Domain<Dim> gdom = map.template global_domain<Dim>(sb, p);
    Domain<Dim> ldom = map.template local_domain<Dim>(sb, p);
  
!   test_assert(gdom.size() == ldom.size());
  
    for (dimension_type d=0; d<Dim; ++d)
    {
!     test_assert(gdom[d].length() == ldom[d].length());
  
      for (index_type i=0; i<ldom[d].length(); ++i)
      {
*************** check_local_vs_global(
*** 112,122 ****
  
        if (map.distribution(d) != cyclic)
        {
! 	assert(map.impl_local_from_global_index(d, gi) == li);
  	// only valid for 1-dim
! 	// assert(map.impl_subblock_from_index(d, gi) == sb);
        }
!       assert(map.global_from_local_index(d, sb, li) == gi);
      }
    }
  }
--- 111,121 ----
  
        if (map.distribution(d) != cyclic)
        {
! 	test_assert(map.impl_local_from_global_index(d, gi) == li);
  	// only valid for 1-dim
! 	// test_assert(map.impl_subblock_from_index(d, gi) == sb);
        }
!       test_assert(map.global_from_local_index(d, sb, li) == gi);
      }
    }
  }
*************** tc_appmap(
*** 168,174 ****
  
    // Check that every element in vector was marked, once.
    for (index_type i=0; i<data.size(); ++i)
!     assert(data.get(i) == 1);
  }
  
  
--- 167,173 ----
  
    // Check that every element in vector was marked, once.
    for (index_type i=0; i<data.size(); ++i)
!     test_assert(data.get(i) == 1);
  }
  
  
*************** tc_appmap(
*** 221,227 ****
    // Check that every element in vector was marked, once.
    for (index_type r=0; r<data.size(0); ++r)
      for (index_type c=0; c<data.size(1); ++c)
!       assert(data.get(r, c) == 1);
  }
  
  
--- 220,226 ----
    // Check that every element in vector was marked, once.
    for (index_type r=0; r<data.size(0); ++r)
      for (index_type c=0; c<data.size(1); ++c)
!       test_assert(data.get(r, c) == 1);
  }
  
  
*************** test_appmap()
*** 297,317 ****
    map_t map(pvec, Block_dist(4), Block_dist(4));
    map.apply(Domain<3>(16, 16, 1));
  
!   assert(map.num_patches(0) == 1);
!   assert(map.global_domain<3>(0, 0) == Domain<3>(Domain<1>(0, 1, 4),
! 						 Domain<1>(0, 1, 4),
! 						 Domain<1>(0, 1, 1)));
  
    // subblocks are row-major
!   assert(map.num_patches(1) == 1);
!   assert(map.global_domain<3>(1, 0) == Domain<3>(Domain<1>(0, 1, 4),
! 						 Domain<1>(4, 1, 4),
! 						 Domain<1>(0, 1, 1)));
! 
!   assert(map.num_patches(15) == 1);
!   assert(map.global_domain<3>(15, 0) == Domain<3>(Domain<1>(12, 1, 4),
! 						  Domain<1>(12, 1, 4),
! 						  Domain<1>(0, 1, 1)));
  }
  
  
--- 296,316 ----
    map_t map(pvec, Block_dist(4), Block_dist(4));
    map.apply(Domain<3>(16, 16, 1));
  
!   test_assert(map.num_patches(0) == 1);
!   test_assert(map.global_domain<3>(0, 0) == Domain<3>(Domain<1>(0, 1, 4),
! 						      Domain<1>(0, 1, 4),
! 						      Domain<1>(0, 1, 1)));
  
    // subblocks are row-major
!   test_assert(map.num_patches(1) == 1);
!   test_assert(map.global_domain<3>(1, 0) == Domain<3>(Domain<1>(0, 1, 4),
! 						      Domain<1>(4, 1, 4),
! 						      Domain<1>(0, 1, 1)));
! 
!   test_assert(map.num_patches(15) == 1);
!   test_assert(map.global_domain<3>(15, 0) == Domain<3>(Domain<1>(12, 1, 4),
! 						       Domain<1>(12, 1, 4),
! 						       Domain<1>(0, 1, 1)));
  }
  
  
Index: tests/complex.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/complex.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 complex.cpp
*** tests/complex.cpp	17 Nov 2005 12:58:40 -0000	1.5
--- tests/complex.cpp	20 Dec 2005 12:39:19 -0000
***************
*** 13,20 ****
    Included Files
  ***********************************************************************/
  
- #include <cassert>
- 
  #include <vsip/complex.hpp>
  
  #include "test.hpp"
--- 13,18 ----
***************
*** 44,65 ****
    z = sqrt(a);								\
    z = tan(a);								\
    z = tanh(a);								\
!   z = conj(a); assert(equal(z, complex<float>(3.f, 4.f)));		\
!   s = real(a); assert(equal(s,  3.f));					\
!   s = imag(a); assert(equal(s, -4.f));					\
!   s = abs(a);  assert(equal(s,  5.f));					\
    s = arg(a);								\
!   s = norm(a); assert(equal(s,  25.f));					\
!   z = pow(a, i); assert(equal(z, a));					\
!   z = pow(a, b); assert(equal(z, a));					\
!   z = pow(a, f); assert(equal(z, a));					\
!   z = pow(f, b); assert(equal(z, b));					\
!   z = operator+(a, b); assert(equal(z, complex<float>(4.f, -4.f)));	\
!   z = operator-(a, b); assert(equal(z, complex<float>(2.f, -4.f)));	\
!   z = operator*(a, b); assert(equal(z, complex<float>(3.f, -4.f)));	\
!   z = operator/(a, b); assert(equal(z, complex<float>(3.f, -4.f)));	\
!   x = operator==(a, b); assert(x == false);				\
!   x = operator!=(a, b); assert(x == true);				\
  									\
    z = vsip::cos(a);							\
    z = vsip::cosh(a);							\
--- 42,63 ----
    z = sqrt(a);								\
    z = tan(a);								\
    z = tanh(a);								\
!   z = conj(a); test_assert(equal(z, complex<float>(3.f, 4.f)));		\
!   s = real(a); test_assert(equal(s,  3.f));				\
!   s = imag(a); test_assert(equal(s, -4.f));				\
!   s = abs(a);  test_assert(equal(s,  5.f));				\
    s = arg(a);								\
!   s = norm(a); test_assert(equal(s,  25.f));				\
!   z = pow(a, i); test_assert(equal(z, a));				\
!   z = pow(a, b); test_assert(equal(z, a));				\
!   z = pow(a, f); test_assert(equal(z, a));				\
!   z = pow(f, b); test_assert(equal(z, b));				\
!   z = operator+(a, b); test_assert(equal(z, complex<float>(4.f, -4.f)));\
!   z = operator-(a, b); test_assert(equal(z, complex<float>(2.f, -4.f)));\
!   z = operator*(a, b); test_assert(equal(z, complex<float>(3.f, -4.f)));\
!   z = operator/(a, b); test_assert(equal(z, complex<float>(3.f, -4.f)));\
!   x = operator==(a, b); test_assert(x == false);			\
!   x = operator!=(a, b); test_assert(x == true);				\
  									\
    z = vsip::cos(a);							\
    z = vsip::cosh(a);							\
***************
*** 71,92 ****
    z = vsip::sqrt(a);							\
    z = vsip::tan(a);							\
    z = vsip::tanh(a);							\
!   z = vsip::conj(a); assert(equal(z, complex<float>(3.f, 4.f)));	\
!   s = vsip::real(a); assert(equal(s,  3.f));				\
!   s = vsip::imag(a); assert(equal(s, -4.f));				\
!   s = vsip::abs(a);  assert(equal(s,  5.f));				\
    s = vsip::arg(a);							\
!   s = vsip::norm(a); assert(equal(s, 25.f));				\
!   z = vsip::pow(a, i); assert(equal(z, a));				\
!   z = vsip::pow(a, b); assert(equal(z, a));				\
!   z = vsip::pow(a, f); assert(equal(z, a));				\
!   z = vsip::pow(f, b); assert(equal(z, b));				\
!   z = vsip::operator+(a, b); assert(equal(z, complex<float>(4.f, -4.f))); \
!   z = vsip::operator-(a, b); assert(equal(z, complex<float>(2.f, -4.f))); \
!   z = vsip::operator*(a, b); assert(equal(z, complex<float>(3.f, -4.f))); \
!   z = vsip::operator/(a, b); assert(equal(z, complex<float>(3.f, -4.f))); \
!   x = vsip::operator==(a, b); assert(x == false);			\
!   x = vsip::operator!=(a, b); assert(x == true);			\
  									\
    z = std::cos(a);							\
    z = std::cosh(a);							\
--- 69,90 ----
    z = vsip::sqrt(a);							\
    z = vsip::tan(a);							\
    z = vsip::tanh(a);							\
!   z = vsip::conj(a); test_assert(equal(z, complex<float>(3.f, 4.f)));	\
!   s = vsip::real(a); test_assert(equal(s,  3.f));			\
!   s = vsip::imag(a); test_assert(equal(s, -4.f));			\
!   s = vsip::abs(a);  test_assert(equal(s,  5.f));			\
    s = vsip::arg(a);							\
!   s = vsip::norm(a); test_assert(equal(s, 25.f));			\
!   z = vsip::pow(a, i); test_assert(equal(z, a));			\
!   z = vsip::pow(a, b); test_assert(equal(z, a));			\
!   z = vsip::pow(a, f); test_assert(equal(z, a));			\
!   z = vsip::pow(f, b); test_assert(equal(z, b));			\
!   z = vsip::operator+(a, b); test_assert(equal(z, complex<float>(4.f, -4.f))); \
!   z = vsip::operator-(a, b); test_assert(equal(z, complex<float>(2.f, -4.f))); \
!   z = vsip::operator*(a, b); test_assert(equal(z, complex<float>(3.f, -4.f))); \
!   z = vsip::operator/(a, b); test_assert(equal(z, complex<float>(3.f, -4.f))); \
!   x = vsip::operator==(a, b); test_assert(x == false);			\
!   x = vsip::operator!=(a, b); test_assert(x == true);			\
  									\
    z = std::cos(a);							\
    z = std::cosh(a);							\
***************
*** 99,120 ****
    z = std::tan(a);							\
    z = std::tanh(a);							\
    z = std::conj(a);							\
!   z = std::conj(a); assert(equal(z, complex<float>(3.f, 4.f)));		\
!   s = std::real(a); assert(equal(s,  3.f));				\
!   s = std::imag(a); assert(equal(s, -4.f));				\
!   s = std::abs(a);  assert(equal(s,  5.f));				\
    s = std::arg(a);							\
!   s = std::norm(a); assert(equal(s, 25.f));				\
!   z = std::pow(a, i); assert(equal(z, a));				\
!   z = std::pow(a, b); assert(equal(z, a));				\
!   z = std::pow(a, f); assert(equal(z, a));				\
!   z = std::pow(f, b); assert(equal(z, b));				\
!   z = std::operator+(a, b); assert(equal(z, complex<float>(4.f, -4.f))); \
!   z = std::operator-(a, b); assert(equal(z, complex<float>(2.f, -4.f))); \
!   z = std::operator*(a, b); assert(equal(z, complex<float>(3.f, -4.f))); \
!   z = std::operator/(a, b); assert(equal(z, complex<float>(3.f, -4.f))); \
!   x = std::operator==(a, b); assert(x == false);			\
!   x = std::operator!=(a, b); assert(x == true);				\
    /* last */
  
  
--- 97,118 ----
    z = std::tan(a);							\
    z = std::tanh(a);							\
    z = std::conj(a);							\
!   z = std::conj(a); test_assert(equal(z, complex<float>(3.f, 4.f)));	\
!   s = std::real(a); test_assert(equal(s,  3.f));			\
!   s = std::imag(a); test_assert(equal(s, -4.f));			\
!   s = std::abs(a);  test_assert(equal(s,  5.f));			\
    s = std::arg(a);							\
!   s = std::norm(a); test_assert(equal(s, 25.f));			\
!   z = std::pow(a, i); test_assert(equal(z, a));				\
!   z = std::pow(a, b); test_assert(equal(z, a));				\
!   z = std::pow(a, f); test_assert(equal(z, a));				\
!   z = std::pow(f, b); test_assert(equal(z, b));				\
!   z = std::operator+(a, b); test_assert(equal(z, complex<float>(4.f, -4.f))); \
!   z = std::operator-(a, b); test_assert(equal(z, complex<float>(2.f, -4.f))); \
!   z = std::operator*(a, b); test_assert(equal(z, complex<float>(3.f, -4.f))); \
!   z = std::operator/(a, b); test_assert(equal(z, complex<float>(3.f, -4.f))); \
!   x = std::operator==(a, b); test_assert(x == false);			\
!   x = std::operator!=(a, b); test_assert(x == true);				\
    /* last */
  
  
*************** test_complex()
*** 193,210 ****
    T		imag = T(2);
    complex<T>	c1(real, imag);
  
!   assert(equal(c1.real(), real));
!   assert(equal(c1.imag(), imag));
  
    complex<T>	c2 = c1 + T(1);
  
!   assert(equal(c2.real(), T(real + 1)));
!   assert(equal(c2.imag(), imag));
  
    complex<T>	c3 = c1 + complex<T>(T(0), T(1));
  
!   assert(equal(c3.real(), real));
!   assert(equal(c3.imag(), T(imag + 1)));
  }
  
  
--- 191,208 ----
    T		imag = T(2);
    complex<T>	c1(real, imag);
  
!   test_assert(equal(c1.real(), real));
!   test_assert(equal(c1.imag(), imag));
  
    complex<T>	c2 = c1 + T(1);
  
!   test_assert(equal(c2.real(), T(real + 1)));
!   test_assert(equal(c2.imag(), imag));
  
    complex<T>	c3 = c1 + complex<T>(T(0), T(1));
  
!   test_assert(equal(c3.real(), real));
!   test_assert(equal(c3.imag(), T(imag + 1)));
  }
  
  
*************** test_polar()
*** 228,255 ****
  
    c1 = complex<T>(T(1), T(0));
    recttopolar(c1, mag, phase);
!   assert(equal(mag,   T(1)));
!   assert(equal(phase, T(0)));
    c2 = polartorect(mag, phase);
!   assert(equal(c1, c2));
  
    c1 = complex<T>(T(0), T(1));
    recttopolar(c1, mag, phase);
!   assert(equal(mag,   T(1)));
!   assert(equal(phase, pi/2));
    c2 = polartorect(mag, phase);
!   assert(equal(c1, c2));
  
    c1 = complex<T>(T(1), T(1));
    vsip::recttopolar(c1, mag, phase);
!   assert(equal(mag,   std::sqrt(T(2))));
!   assert(equal(phase, pi/4));
    c2 = polartorect(mag, phase);
!   assert(equal(c1, c2));
  
  
    c2 = polartorect(T(3));
!   assert(equal(c2, complex<T>(T(3), T(0))));
  }
  
  template <typename T>
--- 226,253 ----
  
    c1 = complex<T>(T(1), T(0));
    recttopolar(c1, mag, phase);
!   test_assert(equal(mag,   T(1)));
!   test_assert(equal(phase, T(0)));
    c2 = polartorect(mag, phase);
!   test_assert(equal(c1, c2));
  
    c1 = complex<T>(T(0), T(1));
    recttopolar(c1, mag, phase);
!   test_assert(equal(mag,   T(1)));
!   test_assert(equal(phase, pi/2));
    c2 = polartorect(mag, phase);
!   test_assert(equal(c1, c2));
  
    c1 = complex<T>(T(1), T(1));
    vsip::recttopolar(c1, mag, phase);
!   test_assert(equal(mag,   std::sqrt(T(2))));
!   test_assert(equal(phase, pi/4));
    c2 = polartorect(mag, phase);
!   test_assert(equal(c1, c2));
  
  
    c2 = polartorect(T(3));
!   test_assert(equal(c2, complex<T>(T(3), T(0))));
  }
  
  template <typename T>
*************** test_polar_view(vsip::length_type size)
*** 267,294 ****
  
    v1 = complex<T>(T(1), T(0));
    recttopolar(v1, mag, phase);
!   assert(equal(mag(0),   T(1)));
!   assert(equal(phase(0), T(0)));
    v2 = polartorect(mag, phase);
!   assert(view_equal(v1, v2));
  
    v1 = complex<T>(T(0), T(1));
    recttopolar(v1, mag, phase);
!   assert(equal(mag(0),   T(1)));
!   assert(equal(phase(0), pi/2));
    v2 = polartorect(mag, phase);
!   assert(view_equal(v1, v2));
  
    v1 = complex<T>(T(1), T(1));
    recttopolar(v1, mag, phase);
!   assert(equal(mag(0),   std::sqrt(T(2))));
!   assert(equal(phase(0), pi/4));
    v2 = polartorect(mag, phase);
!   assert(view_equal(v1, v2));
  
  
    v2 = polartorect(T(3));
!   assert(equal(v2(0), complex<T>(T(3), T(0))));
  }
  
  template <typename T1, typename T2>
--- 265,292 ----
  
    v1 = complex<T>(T(1), T(0));
    recttopolar(v1, mag, phase);
!   test_assert(equal(mag(0),   T(1)));
!   test_assert(equal(phase(0), T(0)));
    v2 = polartorect(mag, phase);
!   test_assert(view_equal(v1, v2));
  
    v1 = complex<T>(T(0), T(1));
    recttopolar(v1, mag, phase);
!   test_assert(equal(mag(0),   T(1)));
!   test_assert(equal(phase(0), pi/2));
    v2 = polartorect(mag, phase);
!   test_assert(view_equal(v1, v2));
  
    v1 = complex<T>(T(1), T(1));
    recttopolar(v1, mag, phase);
!   test_assert(equal(mag(0),   std::sqrt(T(2))));
!   test_assert(equal(phase(0), pi/4));
    v2 = polartorect(mag, phase);
!   test_assert(view_equal(v1, v2));
  
  
    v2 = polartorect(T(3));
!   test_assert(equal(v2(0), complex<T>(T(3), T(0))));
  }
  
  template <typename T1, typename T2>
*************** test_cmplx(vsip::length_type size)
*** 299,306 ****
    vsip::Vector<vsip::complex<T1> > c = vsip::cmplx(v1, v2);
    typename vsip::Vector<vsip::complex<T1> >::realview_type r = c.real();
    typename vsip::Vector<vsip::complex<T1> >::imagview_type i = c.imag();
!   assert(view_equal(r, v1));
!   assert(view_equal(i, v2));
  }
  
  /// Test that functions such as exp, cos, etc. are available for complex.
--- 297,304 ----
    vsip::Vector<vsip::complex<T1> > c = vsip::cmplx(v1, v2);
    typename vsip::Vector<vsip::complex<T1> >::realview_type r = c.real();
    typename vsip::Vector<vsip::complex<T1> >::imagview_type i = c.imag();
!   test_assert(view_equal(r, v1));
!   test_assert(view_equal(i, v2));
  }
  
  /// Test that functions such as exp, cos, etc. are available for complex.
*************** test_exp(T x, T y)
*** 318,328 ****
    c1 = complex<T>(x, y);
    c2 = exp(c1);
  
!   assert(equal(c2.real(), T(exp(x)*cos(y))));
!   assert(equal(c2.imag(), T(exp(x)*sin(y))));
  
!   assert(equal(exp(complex<T>(0, pi)) + T(1),
! 	       complex<T>(0)));
  }
    
  
--- 316,326 ----
    c1 = complex<T>(x, y);
    c2 = exp(c1);
  
!   test_assert(equal(c2.real(), T(exp(x)*cos(y))));
!   test_assert(equal(c2.imag(), T(exp(x)*sin(y))));
  
!   test_assert(equal(exp(complex<T>(0, pi)) + T(1),
! 	            complex<T>(0)));
  }
    
  
Index: tests/conv-2d.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/conv-2d.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 conv-2d.cpp
*** tests/conv-2d.cpp	5 Dec 2005 15:16:18 -0000	1.1
--- tests/conv-2d.cpp	20 Dec 2005 12:39:19 -0000
***************
*** 10,17 ****
    Included Files
  ***********************************************************************/
  
- #include <cassert>
- 
  #include <vsip/vector.hpp>
  #include <vsip/signal.hpp>
  #include <vsip/random.hpp>
--- 10,15 ----
*************** test_conv(
*** 154,173 ****
  
    conv_type conv(coeff, Domain<2>(Nr, Nc), D);
  
!   assert(conv.symmetry() == symmetry);
!   assert(conv.support()  == support);
  
!   assert(conv.kernel_size()[0].size()  == Mr);
!   assert(conv.kernel_size()[1].size()  == Mc);
  
!   assert(conv.filter_order()[0].size() == Mr);
!   assert(conv.filter_order()[1].size() == Mc);
  
!   assert(conv.input_size()[0].size()   == Nr);
!   assert(conv.input_size()[1].size()   == Nc);
  
!   assert(conv.output_size()[0].size()  == Pr);
!   assert(conv.output_size()[1].size()  == Pc);
  
    Matrix<T> in_base(Nr * stride, Nc * stride);
    Matrix<T> out_base(Pr * stride, Pc * stride, T(100));
--- 152,171 ----
  
    conv_type conv(coeff, Domain<2>(Nr, Nc), D);
  
!   test_assert(conv.symmetry() == symmetry);
!   test_assert(conv.support()  == support);
  
!   test_assert(conv.kernel_size()[0].size()  == Mr);
!   test_assert(conv.kernel_size()[1].size()  == Mc);
  
!   test_assert(conv.filter_order()[0].size() == Mr);
!   test_assert(conv.filter_order()[1].size() == Mc);
  
!   test_assert(conv.input_size()[0].size()   == Nr);
!   test_assert(conv.input_size()[1].size()   == Nc);
  
!   test_assert(conv.output_size()[0].size()  == Pr);
!   test_assert(conv.output_size()[1].size()  == Pc);
  
    Matrix<T> in_base(Nr * stride, Nc * stride);
    Matrix<T> out_base(Pr * stride, Pc * stride, T(100));
*************** test_conv(
*** 243,249 ****
  
  	ex(i, j) = chk;
  
! 	// assert(equal(val, chk));
  	if (!equal(val, chk))
  	  good = false;
        }
--- 241,247 ----
  
  	ex(i, j) = chk;
  
! 	// test_assert(equal(val, chk));
  	if (!equal(val, chk))
  	  good = false;
        }
*************** test_conv(
*** 256,262 ****
        cout << "out =\n" << out << endl;
        cout << "ex =\n" << ex << endl;
  #endif
!       assert(0);
      }
    }
  }
--- 254,260 ----
        cout << "out =\n" << out << endl;
        cout << "ex =\n" << ex << endl;
  #endif
!       test_assert(0);
      }
    }
  }
*************** test_conv_nonsym(
*** 295,314 ****
  
    conv_type conv(coeff, Domain<2>(Nr, Nc), D);
  
!   assert(conv.symmetry() == symmetry);
!   assert(conv.support()  == support);
  
!   assert(conv.kernel_size()[0].size()  == Mr);
!   assert(conv.kernel_size()[1].size()  == Mc);
  
!   assert(conv.filter_order()[0].size() == Mr);
!   assert(conv.filter_order()[1].size() == Mc);
  
!   assert(conv.input_size()[0].size()   == Nr);
!   assert(conv.input_size()[1].size()   == Nc);
  
!   assert(conv.output_size()[0].size()  == Pr);
!   assert(conv.output_size()[1].size()  == Pc);
  
  
    Matrix<T> in(Nr, Nc);
--- 293,312 ----
  
    conv_type conv(coeff, Domain<2>(Nr, Nc), D);
  
!   test_assert(conv.symmetry() == symmetry);
!   test_assert(conv.support()  == support);
  
!   test_assert(conv.kernel_size()[0].size()  == Mr);
!   test_assert(conv.kernel_size()[1].size()  == Mc);
  
!   test_assert(conv.filter_order()[0].size() == Mr);
!   test_assert(conv.filter_order()[1].size() == Mc);
  
!   test_assert(conv.input_size()[0].size()   == Nr);
!   test_assert(conv.input_size()[1].size()   == Nc);
  
!   test_assert(conv.output_size()[0].size()  == Pr);
!   test_assert(conv.output_size()[1].size()  == Pc);
  
  
    Matrix<T> in(Nr, Nc);
*************** test_conv_nonsym(
*** 344,350 ****
      cout << "out =\n" << out << endl;
      cout << "ex =\n" << ex << endl;
  #endif
!     assert(0);
    }
  }
  
--- 342,348 ----
      cout << "out =\n" << out << endl;
      cout << "ex =\n" << ex << endl;
  #endif
!     test_assert(0);
    }
  }
  
Index: tests/convolution.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/convolution.cpp,v
retrieving revision 1.7
diff -c -p -r1.7 convolution.cpp
*** tests/convolution.cpp	28 Nov 2005 20:44:55 -0000	1.7
--- tests/convolution.cpp	20 Dec 2005 12:39:19 -0000
***************
*** 10,17 ****
    Included Files
  ***********************************************************************/
  
- #include <cassert>
- 
  #include <vsip/vector.hpp>
  #include <vsip/signal.hpp>
  #include <vsip/random.hpp>
--- 10,15 ----
*************** test_conv_nonsym(
*** 96,108 ****
  
    conv_type conv(coeff, Domain<1>(N), D);
  
!   assert(conv.symmetry() == symmetry);
!   assert(conv.support()  == support);
  
!   assert(conv.kernel_size().size()  == M);
!   assert(conv.filter_order().size() == M);
!   assert(conv.input_size().size()   == N);
!   assert(conv.output_size().size()  == P);
  
  
    Vector<T> in(N);
--- 94,106 ----
  
    conv_type conv(coeff, Domain<1>(N), D);
  
!   test_assert(conv.symmetry() == symmetry);
!   test_assert(conv.support()  == support);
  
!   test_assert(conv.kernel_size().size()  == M);
!   test_assert(conv.filter_order().size() == M);
!   test_assert(conv.input_size().size()   == N);
!   test_assert(conv.output_size().size()  == P);
  
  
    Vector<T> in(N);
*************** test_conv_nonsym(
*** 127,133 ****
      else
        val2 = in(i + shift - c2);
  
!     assert(equal(out(i), T(k1) * val1 + T(k2) * val2));
    }
  }
  
--- 125,131 ----
      else
        val2 = in(i + shift - c2);
  
!     test_assert(equal(out(i), T(k1) * val1 + T(k2) * val2));
    }
  }
  
*************** test_conv_nonunit_stride(
*** 158,170 ****
  
    conv_type conv(kernel, Domain<1>(N), D);
  
!   assert(conv.symmetry() == symmetry);
!   assert(conv.support()  == support);
  
!   assert(conv.kernel_size().size()  == M);
!   assert(conv.filter_order().size() == M);
!   assert(conv.input_size().size()   == N);
!   assert(conv.output_size().size()  == P);
  
  
    Vector<T> in_base(N * stride);
--- 156,168 ----
  
    conv_type conv(kernel, Domain<1>(N), D);
  
!   test_assert(conv.symmetry() == symmetry);
!   test_assert(conv.support()  == support);
  
!   test_assert(conv.kernel_size().size()  == M);
!   test_assert(conv.filter_order().size() == M);
!   test_assert(conv.input_size().size()   == N);
!   test_assert(conv.output_size().size()  == P);
  
  
    Vector<T> in_base(N * stride);
*************** test_conv_nonunit_stride(
*** 201,207 ****
      T val = out(i);
      T chk = dot(kernel, sub);
  
!     assert(equal(val, chk));
    }
  }
  
--- 199,205 ----
      T val = out(i);
      T chk = dot(kernel, sub);
  
!     test_assert(equal(val, chk));
    }
  }
  
*************** test_conv(
*** 257,269 ****
  
    conv_type conv(coeff, Domain<1>(N), D);
  
!   assert(conv.symmetry() == symmetry);
!   assert(conv.support()  == support);
  
!   assert(conv.kernel_size().size()  == M);
!   assert(conv.filter_order().size() == M);
!   assert(conv.input_size().size()   == N);
!   assert(conv.output_size().size()  == P);
  
  
    Vector<T> in(N);
--- 255,267 ----
  
    conv_type conv(coeff, Domain<1>(N), D);
  
!   test_assert(conv.symmetry() == symmetry);
!   test_assert(conv.support()  == support);
  
!   test_assert(conv.kernel_size().size()  == M);
!   test_assert(conv.filter_order().size() == M);
!   test_assert(conv.input_size().size()   == N);
!   test_assert(conv.output_size().size()  == P);
  
  
    Vector<T> in(N);
*************** test_conv(
*** 296,302 ****
        T val = out(i);
        T chk = dot(kernel, sub);
  
!       assert(equal(val, chk));
      }
    }
  }
--- 294,300 ----
        T val = out(i);
        T chk = dot(kernel, sub);
  
!       test_assert(equal(val, chk));
      }
    }
  }
Index: tests/corr-2d.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/corr-2d.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 corr-2d.cpp
*** tests/corr-2d.cpp	12 Dec 2005 17:47:50 -0000	1.1
--- tests/corr-2d.cpp	20 Dec 2005 12:39:19 -0000
***************
*** 10,17 ****
    Included Files
  ***********************************************************************/
  
- #include <cassert>
- 
  #include <vsip/vector.hpp>
  #include <vsip/signal.hpp>
  #include <vsip/random.hpp>
--- 10,15 ----
Index: tests/correlation.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/correlation.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 correlation.cpp
*** tests/correlation.cpp	12 Dec 2005 17:47:50 -0000	1.2
--- tests/correlation.cpp	20 Dec 2005 12:39:19 -0000
***************
*** 10,17 ****
    Included Files
  ***********************************************************************/
  
- #include <cassert>
- 
  #include <vsip/vector.hpp>
  #include <vsip/signal.hpp>
  #include <vsip/random.hpp>
--- 10,15 ----
Index: tests/counter.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/counter.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 counter.cpp
*** tests/counter.cpp	18 Jun 2005 16:40:45 -0000	1.5
--- tests/counter.cpp	20 Dec 2005 12:39:19 -0000
***************
*** 10,18 ****
  #include <stdexcept>
  #include <typeinfo>
  #include <limits>
- #include <cassert>
  #include <vsip/impl/counter.hpp>
  
  using vsip::impl::Checked_counter;
  
  /// Exercise all relational operators on Checked_counters.
--- 10,19 ----
  #include <stdexcept>
  #include <typeinfo>
  #include <limits>
  #include <vsip/impl/counter.hpp>
  
+ #include "test.hpp"
+ 
  using vsip::impl::Checked_counter;
  
  /// Exercise all relational operators on Checked_counters.
*************** using vsip::impl::Checked_counter;
*** 22,69 ****
  static void
  test_relational()
  {
!   Checked_counter a = 0;         assert(a.value() == 0);
!   Checked_counter b = 27;        assert(b.value() == 27);
!   Checked_counter c = 27;        assert(c.value() == 27);
!   Checked_counter d = 40;        assert(d.value() == 40);
  
    // Equality.
!   assert(b == c);
!   assert(c == 27);
!   assert(40 == d);
!   assert(!(a == b));
  
    // Inequality.
!   assert(a != b);
!   assert(0 != c);
!   assert(d != 27);
!   assert(!(b != c));
  
    // Less than.
!   assert(a < b);
!   assert(10 < b);
!   assert(d < 99);
!   assert(!(b < c));
  
    // Greater than.
!   assert(d > c);
!   assert(90 > c);
!   assert(c > 10);
!   assert(!(b > c));
    
    // Less or equal.
!   assert(a <= b);
!   assert(b <= c);
!   assert(d <= 41);
!   assert(40 <= d);
!   assert(!(b <= a));
  
    // Greater or equal.
!   assert(b >= a);
!   assert(b >= c);
!   assert(d >= 39);
!   assert(40 >= d);
!   assert(!(a >= c));
  }
  
  /// Exercise all forms of non-over/underflowing addition.
--- 23,70 ----
  static void
  test_relational()
  {
!   Checked_counter a = 0;         test_assert(a.value() == 0);
!   Checked_counter b = 27;        test_assert(b.value() == 27);
!   Checked_counter c = 27;        test_assert(c.value() == 27);
!   Checked_counter d = 40;        test_assert(d.value() == 40);
  
    // Equality.
!   test_assert(b == c);
!   test_assert(c == 27);
!   test_assert(40 == d);
!   test_assert(!(a == b));
  
    // Inequality.
!   test_assert(a != b);
!   test_assert(0 != c);
!   test_assert(d != 27);
!   test_assert(!(b != c));
  
    // Less than.
!   test_assert(a < b);
!   test_assert(10 < b);
!   test_assert(d < 99);
!   test_assert(!(b < c));
  
    // Greater than.
!   test_assert(d > c);
!   test_assert(90 > c);
!   test_assert(c > 10);
!   test_assert(!(b > c));
    
    // Less or equal.
!   test_assert(a <= b);
!   test_assert(b <= c);
!   test_assert(d <= 41);
!   test_assert(40 <= d);
!   test_assert(!(b <= a));
  
    // Greater or equal.
!   test_assert(b >= a);
!   test_assert(b >= c);
!   test_assert(d >= 39);
!   test_assert(40 >= d);
!   test_assert(!(a >= c));
  }
  
  /// Exercise all forms of non-over/underflowing addition.
*************** test_addition()
*** 73,92 ****
    Checked_counter a;      // default initialized to 0
    Checked_counter b = 23;
  
!   a += 1; assert(a == 1);
  
!   assert((a += 2) == 3); assert(a == 3);
  
!   assert(a + 4 == 7); assert(a == 3);
!   assert(4 + a == 7); assert(a == 3);
  
!   assert(++a == 4); assert(a == 4);
  
!   assert(a++ == 4); assert(a == 5);
  
!   assert(b + a == 28); assert(b == 23); assert(a == 5);
  
!   a += b; assert(a == 28); assert(b == 23);
  }
  
  /// Exercise all forms of non-over/underflowing subtraction.
--- 74,93 ----
    Checked_counter a;      // default initialized to 0
    Checked_counter b = 23;
  
!   a += 1; test_assert(a == 1);
  
!   test_assert((a += 2) == 3); test_assert(a == 3);
  
!   test_assert(a + 4 == 7); test_assert(a == 3);
!   test_assert(4 + a == 7); test_assert(a == 3);
  
!   test_assert(++a == 4); test_assert(a == 4);
  
!   test_assert(a++ == 4); test_assert(a == 5);
  
!   test_assert(b + a == 28); test_assert(b == 23); test_assert(a == 5);
  
!   a += b; test_assert(a == 28); test_assert(b == 23);
  }
  
  /// Exercise all forms of non-over/underflowing subtraction.
*************** test_subtraction()
*** 96,115 ****
    Checked_counter a = 99;
    Checked_counter b = 23;
  
!   a -= 1; assert(a == 98);
  
!   assert((a -= 2) == 96); assert(a == 96);
  
!   assert(a - 4 == 92); assert(a == 96);
!   assert(100 - a == 4); assert(a == 96);
  
!   assert(--a == 95); assert(a == 95);
  
!   assert(a-- == 95); assert(a == 94);
  
!   assert(a - b == 71); assert(b == 23); assert(a == 94);
  
!   a -= b; assert(a == 71); assert(b == 23);
  }
  
  /// Underflow - minimal test.
--- 97,116 ----
    Checked_counter a = 99;
    Checked_counter b = 23;
  
!   a -= 1; test_assert(a == 98);
  
!   test_assert((a -= 2) == 96); test_assert(a == 96);
  
!   test_assert(a - 4 == 92); test_assert(a == 96);
!   test_assert(100 - a == 4); test_assert(a == 96);
  
!   test_assert(--a == 95); test_assert(a == 95);
  
!   test_assert(a-- == 95); test_assert(a == 94);
  
!   test_assert(a - b == 71); test_assert(b == 23); test_assert(a == 94);
  
!   a -= b; test_assert(a == 71); test_assert(b == 23);
  }
  
  /// Underflow - minimal test.
*************** test_under()
*** 126,132 ****
    {
      return;
    }
!   assert (!"0-- failed to throw std::underflow_error\n");
  #endif
  }
  
--- 127,133 ----
    {
      return;
    }
!   test_assert (!"0-- failed to throw std::underflow_error\n");
  #endif
  }
  
*************** test_over()
*** 144,150 ****
    {
      return;
    }
!   assert(!"UINT_MAX++ failed to throw std::overflow_error\n");
  #endif
  }
  
--- 145,151 ----
    {
      return;
    }
!   test_assert(!"UINT_MAX++ failed to throw std::overflow_error\n");
  #endif
  }
  
*************** main(void)
*** 163,168 ****
    {
      std::cerr << "unexpected exception " << typeid(E).name()
                << ": " << E.what() << std::endl;
!     assert(0);
    }
  }
--- 164,169 ----
    {
      std::cerr << "unexpected exception " << typeid(E).name()
                << ": " << E.what() << std::endl;
!     test_assert(0);
    }
  }
Index: tests/dense.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/dense.cpp,v
retrieving revision 1.8
diff -c -p -r1.8 dense.cpp
*** tests/dense.cpp	4 Jul 2005 14:28:50 -0000	1.8
--- tests/dense.cpp	20 Dec 2005 12:39:19 -0000
***************
*** 11,17 ****
  ***********************************************************************/
  
  #include <iostream>
- #include <cassert>
  #include <vsip/support.hpp>
  #include <vsip/dense.hpp>
  #include "test.hpp"
--- 11,16 ----
*************** check_order(Dense<2, T, Order>& block)
*** 64,77 ****
      for (index_type j=0; j<block.size(2, 1); ++j)
      {
        index_type idx = linear_index<Order>(i, j, block.size(2, 0), block.size(2, 1));
!       assert(equal(block.get(idx), T(100*i + j)));
        block.put(idx, T(i + 1000*j));
      }
    }
  
    for (index_type i=0; i<block.size(2, 0); ++i)
      for (index_type j=0; j<block.size(2, 1); ++j)
!       assert(equal(block.get(i, j), T(i + 1000*j)));
  }
  
  
--- 63,76 ----
      for (index_type j=0; j<block.size(2, 1); ++j)
      {
        index_type idx = linear_index<Order>(i, j, block.size(2, 0), block.size(2, 1));
!       test_assert(equal(block.get(idx), T(100*i + j)));
        block.put(idx, T(i + 1000*j));
      }
    }
  
    for (index_type i=0; i<block.size(2, 0); ++i)
      for (index_type j=0; j<block.size(2, 1); ++j)
!       test_assert(equal(block.get(i, j), T(i + 1000*j)));
  }
  
  
*************** check_block_const(Dense<1, T> const& blo
*** 87,93 ****
    block.increment_count();
  
    for (index_type i=0; i<block.size(); ++i)
!     assert(equal(block.get(i), T(2*i)));
  
    block.decrement_count();
  }
--- 86,92 ----
    block.increment_count();
  
    for (index_type i=0; i<block.size(); ++i)
!     test_assert(equal(block.get(i), T(2*i)));
  
    block.decrement_count();
  }
*************** check_block_gp(Dense<1, T>& block)
*** 103,109 ****
      block.put(i, T(2*i));
  
    for (index_type i=0; i<block.size(); ++i)
!     assert(equal(block.get(i), T(2*i)));
  
    check_block_const(block);
  }
--- 102,108 ----
      block.put(i, T(2*i));
  
    for (index_type i=0; i<block.size(); ++i)
!     test_assert(equal(block.get(i), T(2*i)));
  
    check_block_const(block);
  }
*************** check_block_gp(Dense<2, T, Order>& block
*** 123,129 ****
  
    for (index_type i=0; i<block.size(2, 0); ++i)
      for (index_type j=0; j<block.size(2, 1); ++j)
!       assert(equal(block.get(i, j), T(100*i + j)));
  
    check_order(block);
  }
--- 122,128 ----
  
    for (index_type i=0; i<block.size(2, 0); ++i)
      for (index_type j=0; j<block.size(2, 1); ++j)
!       test_assert(equal(block.get(i, j), T(100*i + j)));
  
    check_order(block);
  }
*************** check_block_gp(Dense<3, T, Order>& block
*** 145,151 ****
    for (index_type i=0; i<block.size(3, 0); ++i)
      for (index_type j=0; j<block.size(3, 1); ++j)
        for (index_type k=0; k<block.size(3, 2); ++k)
!       assert(equal(block.get(i, j, k),  T(1000*i + 100*j + k)));
  
    // check_order(block);
  }
--- 144,150 ----
    for (index_type i=0; i<block.size(3, 0); ++i)
      for (index_type j=0; j<block.size(3, 1); ++j)
        for (index_type k=0; k<block.size(3, 2); ++k)
!       test_assert(equal(block.get(i, j, k),  T(1000*i + 100*j + k)));
  
    // check_order(block);
  }
*************** check_block_at(Dense<1, T>& block)
*** 161,167 ****
      block.impl_ref(i) = T(2*i);
  
    for (index_type i=0; i<block.size(); ++i)
!     assert(equal(block.impl_ref(i), T(2*i)));
  }
  
  
--- 160,166 ----
      block.impl_ref(i) = T(2*i);
  
    for (index_type i=0; i<block.size(); ++i)
!     test_assert(equal(block.impl_ref(i), T(2*i)));
  }
  
  
*************** check_block_at(Dense<2, T, Order>& block
*** 178,184 ****
  
    for (index_type i=0; i<block.size(2, 0); ++i)
      for (index_type j=0; j<block.size(2, 1); ++j)
!       assert(equal(block.impl_ref(i, j), T(100*i + j)));
  }
  
  
--- 177,183 ----
  
    for (index_type i=0; i<block.size(2, 0); ++i)
      for (index_type j=0; j<block.size(2, 1); ++j)
!       test_assert(equal(block.impl_ref(i, j), T(100*i + j)));
  }
  
  
*************** check_block_at(Dense<3, T, Order>& block
*** 197,203 ****
    for (index_type i=0; i<block.size(3, 0); ++i)
      for (index_type j=0; j<block.size(3, 1); ++j)
        for (index_type k=0; k<block.size(3, 2); ++k)
! 	assert(equal(block.impl_ref(i, j, k), T(1000*i + 100*j + k)));
  }
  
  
--- 196,202 ----
    for (index_type i=0; i<block.size(3, 0); ++i)
      for (index_type j=0; j<block.size(3, 1); ++j)
        for (index_type k=0; k<block.size(3, 2); ++k)
! 	test_assert(equal(block.impl_ref(i, j, k), T(1000*i + 100*j + k)));
  }
  
  
*************** test_stack_dense(Domain<Dim> const& dom)
*** 215,236 ****
  
    // Check out user-storage functions
  
!   assert(block.admitted()     == true);
!   assert(block.user_storage() == no_user_format);
  
    T* ptr;
    block.find(ptr);
!   assert(ptr == NULL);
  
    // Check that block dimension sizes match domain.
    length_type total_size = 1;
    for (dimension_type d=0; d<Dim; ++d)
    {
!     assert(block.size(Dim, d) == dom[d].size());
      total_size *= block.size(Dim, d);
    }
  
!   assert(total_size == block.size());
  
    check_block_gp(block);
    check_block_at(block);
--- 214,235 ----
  
    // Check out user-storage functions
  
!   test_assert(block.admitted()     == true);
!   test_assert(block.user_storage() == no_user_format);
  
    T* ptr;
    block.find(ptr);
!   test_assert(ptr == NULL);
  
    // Check that block dimension sizes match domain.
    length_type total_size = 1;
    for (dimension_type d=0; d<Dim; ++d)
    {
!     test_assert(block.size(Dim, d) == dom[d].size());
      total_size *= block.size(Dim, d);
    }
  
!   test_assert(total_size == block.size());
  
    check_block_gp(block);
    check_block_at(block);
*************** test_heap_dense(Domain<Dim> const& dom)
*** 251,272 ****
  
    // Check out user-storage functions
  
!   assert(block->admitted()     == true);
!   assert(block->user_storage() == no_user_format);
  
    T* ptr;
    block->find(ptr);
!   assert(ptr == NULL);
  
    // Check that block dimension sizes match domain.
    length_type total_size = 1;
    for (dimension_type d=0; d<Dim; ++d)
    {
!     assert(block->size(Dim, d) == dom[d].size());
      total_size *= block->size(Dim, d);
    }
  
!   assert(total_size == block->size());
  
    check_block_gp(*block);
    check_block_at(*block);
--- 250,271 ----
  
    // Check out user-storage functions
  
!   test_assert(block->admitted()     == true);
!   test_assert(block->user_storage() == no_user_format);
  
    T* ptr;
    block->find(ptr);
!   test_assert(ptr == NULL);
  
    // Check that block dimension sizes match domain.
    length_type total_size = 1;
    for (dimension_type d=0; d<Dim; ++d)
    {
!     test_assert(block->size(Dim, d) == dom[d].size());
      total_size *= block->size(Dim, d);
    }
  
!   test_assert(total_size == block->size());
  
    check_block_gp(*block);
    check_block_at(*block);
Index: tests/distributed-block.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/distributed-block.cpp,v
retrieving revision 1.17
diff -c -p -r1.17 distributed-block.cpp
*** tests/distributed-block.cpp	5 Dec 2005 19:19:19 -0000	1.17
--- tests/distributed-block.cpp	20 Dec 2005 12:39:19 -0000
***************
*** 13,19 ****
  #define TEST_OLD_PAR_ASSIGN 0
  
  #include <iostream>
- #include <cassert>
  
  #include <vsip/initfin.hpp>
  #include <vsip/support.hpp>
--- 13,18 ----
*************** check_local_view(
*** 61,74 ****
    index_type sb = map.subblock();
    if (sb == no_subblock)
    {
!     assert(lview.size() == 0);
    }
    else
    {
      Domain<Dim> dom = map.template subblock_domain<Dim>(sb);
!     assert(lview.size() == impl::size(dom));
      for (dimension_type d=0; d<Dim; ++d)
!       assert(lview.size(d) == dom[d].size());
    }
  }
  
--- 60,73 ----
    index_type sb = map.subblock();
    if (sb == no_subblock)
    {
!     test_assert(lview.size() == 0);
    }
    else
    {
      Domain<Dim> dom = map.template subblock_domain<Dim>(sb);
!     test_assert(lview.size() == impl::size(dom));
      for (dimension_type d=0; d<Dim; ++d)
!       test_assert(lview.size(d) == dom[d].size());
    }
  }
  
*************** test_distributed_view(
*** 187,193 ****
    if (map1.impl_rank() == 0) 
    {
      // On processor 0, local_view should be entire view.
!     assert(extent_old(local_view) == extent_old(dom));
  
      // Check that each value is correct.
      bool good = true;
--- 186,192 ----
    if (map1.impl_rank() == 0) 
    {
      // On processor 0, local_view should be entire view.
!     test_assert(extent_old(local_view) == extent_old(dom));
  
      // Check that each value is correct.
      bool good = true;
*************** test_distributed_view(
*** 213,224 ****
      }
  
      // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
!     assert(good);
    }
    else
    {
      // Otherwise, local_view should be empty:
!     assert(local_view.size() == 0);
    }
  }
  
--- 212,223 ----
      }
  
      // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
!     test_assert(good);
    }
    else
    {
      // Otherwise, local_view should be empty:
!     test_assert(local_view.size() == 0);
    }
  }
  
*************** test_distributed_view_assign(
*** 288,294 ****
      typename view0_t::local_type local_view = view0.local();
  
      // Check that local_view is in fact the entire view.
!     assert(extent_old(local_view) == extent_old(dom));
  
      // Check that each value is correct.
      bool good = true;
--- 287,293 ----
      typename view0_t::local_type local_view = view0.local();
  
      // Check that local_view is in fact the entire view.
!     test_assert(extent_old(local_view) == extent_old(dom));
  
      // Check that each value is correct.
      bool good = true;
*************** test_distributed_view_assign(
*** 314,320 ****
      }
  
      // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
!     assert(good);
    }
  }
  
--- 313,319 ----
      }
  
      // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
!     test_assert(good);
    }
  }
  
Index: tests/distributed-subviews.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/distributed-subviews.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 distributed-subviews.cpp
*** tests/distributed-subviews.cpp	5 Dec 2005 19:19:19 -0000	1.5
--- tests/distributed-subviews.cpp	20 Dec 2005 12:39:20 -0000
***************
*** 11,17 ****
  ***********************************************************************/
  
  #include <iostream>
- #include <cassert>
  
  #include <vsip/initfin.hpp>
  #include <vsip/support.hpp>
--- 11,16 ----
*************** test_row_sum(
*** 126,132 ****
  
    for (index_type i=0; i<sum_size; ++i)
    {
!     assert(local_my_sum(i) == local_chk_sum(i));
    }
  
  }
--- 125,131 ----
  
    for (index_type i=0; i<sum_size; ++i)
    {
!     test_assert(local_my_sum(i) == local_chk_sum(i));
    }
  
  }
*************** test_col_sum(
*** 237,243 ****
  
    for (index_type i=0; i<sum_size; ++i)
    {
!     assert(local_my_sum(i) == local_chk_sum(i));
    }
  
  }
--- 236,242 ----
  
    for (index_type i=0; i<sum_size; ++i)
    {
!     test_assert(local_my_sum(i) == local_chk_sum(i));
    }
  
  }
*************** test_tensor_v_sum(
*** 405,411 ****
  
    for (index_type i=0; i<sum_size; ++i)
    {
!     assert(local_my_sum(i) == local_chk_sum(i));
    }
  }
  
--- 404,410 ----
  
    for (index_type i=0; i<sum_size; ++i)
    {
!     test_assert(local_my_sum(i) == local_chk_sum(i));
    }
  }
  
*************** test_tensor_m_sum(
*** 584,590 ****
    for (index_type i=0; i<sum_rows; ++i)
      for (index_type j=0; j<sum_cols; ++j)
      {
!       assert(local_my_sum(i, j) == local_chk_sum(i, j));
      }
  }
  
--- 583,589 ----
    for (index_type i=0; i<sum_rows; ++i)
      for (index_type j=0; j<sum_cols; ++j)
      {
!       test_assert(local_my_sum(i, j) == local_chk_sum(i, j));
      }
  }
  
Index: tests/distributed-user-storage.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/distributed-user-storage.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 distributed-user-storage.cpp
*** tests/distributed-user-storage.cpp	5 Dec 2005 19:19:19 -0000	1.2
--- tests/distributed-user-storage.cpp	20 Dec 2005 12:39:20 -0000
***************
*** 11,17 ****
  ***********************************************************************/
  
  #include <iostream>
- #include <cassert>
  
  #include <vsip/initfin.hpp>
  #include <vsip/support.hpp>
--- 11,16 ----
*************** test1(
*** 70,76 ****
    Setup_assign dist_root(dist, root);
  
    // Initially, dist is not admitted.
!   assert(dist.block().admitted() == false);
  
    // Find out how big the local subdomain is.
    Domain<Dim> subdom = subblock_domain(dist);
--- 69,75 ----
    Setup_assign dist_root(dist, root);
  
    // Initially, dist is not admitted.
!   test_assert(dist.block().admitted() == false);
  
    // Find out how big the local subdomain is.
    Domain<Dim> subdom = subblock_domain(dist);
*************** test1(
*** 110,116 ****
  
      // admit the block
      dist.block().admit(true);
!     assert(dist.block().admitted() == true);
  
      // assign to root
      if (use_sa)
--- 109,115 ----
  
      // admit the block
      dist.block().admit(true);
!     test_assert(dist.block().admitted() == true);
  
      // assign to root
      if (use_sa)
*************** test1(
*** 125,131 ****
  
        // ... check that root is correct.
        for (index_type i=0; i<l_root.size(); ++i)
! 	assert(equal(l_root(i), T(iter*i)));
  
        // ... set values for the round trip
        for (index_type i=0; i<l_root.size(); ++i)
--- 124,130 ----
  
        // ... check that root is correct.
        for (index_type i=0; i<l_root.size(); ++i)
! 	test_assert(equal(l_root(i), T(iter*i)));
  
        // ... set values for the round trip
        for (index_type i=0; i<l_root.size(); ++i)
*************** test1(
*** 140,146 ****
  
      // release the block
      dist.block().release(true);
!     assert(dist.block().admitted() == false);
  
      // Check the data in buffer.
      for (index_type p=0; p<num_patches(dist); ++p)
--- 139,145 ----
  
      // release the block
      dist.block().release(true);
!     test_assert(dist.block().admitted() == false);
  
      // Check the data in buffer.
      for (index_type p=0; p<num_patches(dist); ++p)
*************** test1(
*** 153,159 ****
  	index_type li = l_dom.impl_nth(i);
  	index_type gi = g_dom.impl_nth(i);
  	
! 	assert(equal(data[iter][li], T(iter*gi+1)));
        }
      }
    }
--- 152,158 ----
  	index_type li = l_dom.impl_nth(i);
  	index_type gi = g_dom.impl_nth(i);
  	
! 	test_assert(equal(data[iter][li], T(iter*gi+1)));
        }
      }
    }
Index: tests/domain.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/domain.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 domain.cpp
*** tests/domain.cpp	18 Apr 2005 20:57:49 -0000	1.4
--- tests/domain.cpp	20 Dec 2005 12:39:20 -0000
***************
*** 14,22 ****
  ***********************************************************************/
  
  #include <iostream>
- #include <cassert>
  #include <vsip/domain.hpp>
  
  using namespace std;
  using namespace vsip;
  
--- 14,23 ----
  ***********************************************************************/
  
  #include <iostream>
  #include <vsip/domain.hpp>
  
+ #include "test.hpp"
+ 
  using namespace std;
  using namespace vsip;
  
*************** void
*** 29,67 ****
  test_domain_1()
  {
    Domain<1> d1;
!   assert(d1.first() == 0 && d1.stride() == 1 && d1.length() == 1);
    d1 = Domain<1>(0, 1, 2);
!   assert(d1.size() == d1.length());
    Domain<1> d2(1, -1, 2);
!   assert(d2.first() == 1 && d2.stride() == -1 && d2.length() == 2);
!   assert(d1 == d2);
    d1 = Domain<1>(100, 2, 2);
!   assert(d1 != d2);
    d2 = d1;
!   assert(d1.element_conformant(d2));
    d1.impl_add_in(10);
!   assert(d1.element_conformant(d2));
!   assert(d1 != d2);
    Domain<2> x;
!   assert(!d1.product_conformant(x));
    // operator + (Domain<>, index_difference_type)
    d2 = d1 + 5;
!   assert(d2.first() == d1.first() + 5);
    // operator + (index_difference_type, Domain<>)
    d2 = 5 + d2;
!   assert(d2.first() == d1.first() + 10);
    // operator - (Domain<>, index_difference_type)
    d2 = d2 - 10;
!   assert(d2.first() == d1.first());
    // operator * (Domain<>, stride_scalar_type)
    d2 = d2 * 5;
!   assert(d2.stride() == d1.stride() * 5);
    // operator * (stride_scalar_type, Domain<>)
    d2 = 2 * d2;
!   assert(d2.stride() == d1.stride() * 10);
    // operator / (Domain<>, stride_scalar_type)
    d2 = d2 / 10;
!   assert(d2.stride() == d1.stride());
  }
  
  /// Test Domain<2> interface conformance.
--- 30,68 ----
  test_domain_1()
  {
    Domain<1> d1;
!   test_assert(d1.first() == 0 && d1.stride() == 1 && d1.length() == 1);
    d1 = Domain<1>(0, 1, 2);
!   test_assert(d1.size() == d1.length());
    Domain<1> d2(1, -1, 2);
!   test_assert(d2.first() == 1 && d2.stride() == -1 && d2.length() == 2);
!   test_assert(d1 == d2);
    d1 = Domain<1>(100, 2, 2);
!   test_assert(d1 != d2);
    d2 = d1;
!   test_assert(d1.element_conformant(d2));
    d1.impl_add_in(10);
!   test_assert(d1.element_conformant(d2));
!   test_assert(d1 != d2);
    Domain<2> x;
!   test_assert(!d1.product_conformant(x));
    // operator + (Domain<>, index_difference_type)
    d2 = d1 + 5;
!   test_assert(d2.first() == d1.first() + 5);
    // operator + (index_difference_type, Domain<>)
    d2 = 5 + d2;
!   test_assert(d2.first() == d1.first() + 10);
    // operator - (Domain<>, index_difference_type)
    d2 = d2 - 10;
!   test_assert(d2.first() == d1.first());
    // operator * (Domain<>, stride_scalar_type)
    d2 = d2 * 5;
!   test_assert(d2.stride() == d1.stride() * 5);
    // operator * (stride_scalar_type, Domain<>)
    d2 = 2 * d2;
!   test_assert(d2.stride() == d1.stride() * 10);
    // operator / (Domain<>, stride_scalar_type)
    d2 = d2 / 10;
!   test_assert(d2.stride() == d1.stride());
  }
  
  /// Test Domain<2> interface conformance.
*************** test_domain_2()
*** 71,113 ****
    Domain<1> a(1, 1, 5);
    Domain<1> b(1, 1, 5);
    Domain<2> d1(a, b);
!   assert(d1.size() == 25);
    Domain<2> d2(d1);
!   assert (d1 == d2);
    Domain<2> d3;
    d3 = d1;
!   assert (d1 == d3);
!   assert(d1.element_conformant(d2));
!   assert(d1.product_conformant(d2));
    d1.impl_add_in(10);
!   assert(d1.element_conformant(d2));
!   assert(d1 != d2);
    d3 = Domain<2>(a, Domain<1>(1, 1, 1));
!   assert(!d3.product_conformant(d1));
    // operator + (Domain<>, index_difference_type)
    d2 = d1 + 5;
!   assert(d2[0].first() == d1[0].first() + 5);
!   assert(d2[1].first() == d1[1].first() + 5);
    // operator + (index_difference_type, Domain<>)
    d2 = 5 + d2;
!   assert(d2[0].first() == d1[0].first() + 10);
!   assert(d2[1].first() == d1[1].first() + 10);
    // operator - (Domain<>, index_difference_type)
    d2 = d2 - 10;
!   assert(d2[0].first() == d1[0].first());
!   assert(d2[1].first() == d1[1].first());
    // operator * (Domain<>, stride_scalar_type)
    d2 = d2 * 5;
!   assert(d2[0].stride() == d1[0].stride() * 5);
!   assert(d2[1].stride() == d1[1].stride() * 5);
    // operator * (stride_scalar_type, Domain<>)
    d2 = 2 * d2;
!   assert(d2[0].stride() == d1[0].stride() * 10);
!   assert(d2[1].stride() == d1[1].stride() * 10);
    // operator / (Domain<>, stride_scalar_type)
    d2 = d2 / 10;
!   assert(d2[0].stride() == d1[0].stride());
!   assert(d2[1].stride() == d1[1].stride());
  }
  
  /// Test Domain<3> interface conformance.
--- 72,114 ----
    Domain<1> a(1, 1, 5);
    Domain<1> b(1, 1, 5);
    Domain<2> d1(a, b);
!   test_assert(d1.size() == 25);
    Domain<2> d2(d1);
!   test_assert (d1 == d2);
    Domain<2> d3;
    d3 = d1;
!   test_assert (d1 == d3);
!   test_assert(d1.element_conformant(d2));
!   test_assert(d1.product_conformant(d2));
    d1.impl_add_in(10);
!   test_assert(d1.element_conformant(d2));
!   test_assert(d1 != d2);
    d3 = Domain<2>(a, Domain<1>(1, 1, 1));
!   test_assert(!d3.product_conformant(d1));
    // operator + (Domain<>, index_difference_type)
    d2 = d1 + 5;
!   test_assert(d2[0].first() == d1[0].first() + 5);
!   test_assert(d2[1].first() == d1[1].first() + 5);
    // operator + (index_difference_type, Domain<>)
    d2 = 5 + d2;
!   test_assert(d2[0].first() == d1[0].first() + 10);
!   test_assert(d2[1].first() == d1[1].first() + 10);
    // operator - (Domain<>, index_difference_type)
    d2 = d2 - 10;
!   test_assert(d2[0].first() == d1[0].first());
!   test_assert(d2[1].first() == d1[1].first());
    // operator * (Domain<>, stride_scalar_type)
    d2 = d2 * 5;
!   test_assert(d2[0].stride() == d1[0].stride() * 5);
!   test_assert(d2[1].stride() == d1[1].stride() * 5);
    // operator * (stride_scalar_type, Domain<>)
    d2 = 2 * d2;
!   test_assert(d2[0].stride() == d1[0].stride() * 10);
!   test_assert(d2[1].stride() == d1[1].stride() * 10);
    // operator / (Domain<>, stride_scalar_type)
    d2 = d2 / 10;
!   test_assert(d2[0].stride() == d1[0].stride());
!   test_assert(d2[1].stride() == d1[1].stride());
  }
  
  /// Test Domain<3> interface conformance.
*************** test_domain_3()
*** 118,165 ****
    Domain<1> b(1, 1, 5);
    Domain<1> c(1, 1, 5);
    Domain<3> d1(a, b, c);
!   assert(d1.size() == 125);
    Domain<3> d2(d1);
!   assert (d1 == d2);
    Domain<3> d3;
    d3 = d1;
!   assert (d1 == d3);
!   assert(d1.element_conformant(d2));
    d1.impl_add_in(10);
!   assert(d1.element_conformant(d2));
!   assert(d1 != d2);
    Domain<2> x;
!   assert(!d1.product_conformant(x));
    // operator + (Domain<>, index_difference_type)
    d2 = d1 + 5;
!   assert(d2[0].first() == d1[0].first() + 5);
!   assert(d2[1].first() == d1[1].first() + 5);
!   assert(d2[2].first() == d1[2].first() + 5);
    // operator + (index_difference_type, Domain<>)
    d2 = 5 + d2;
!   assert(d2[0].first() == d1[0].first() + 10);
!   assert(d2[1].first() == d1[1].first() + 10);
!   assert(d2[2].first() == d1[2].first() + 10);
    // operator - (Domain<>, index_difference_type)
    d2 = d2 - 10;
!   assert(d2[0].first() == d1[0].first());
!   assert(d2[1].first() == d1[1].first());
!   assert(d2[2].first() == d1[2].first());
    // operator * (Domain<>, stride_scalar_type)
    d2 = d2 * 5;
!   assert(d2[0].stride() == d1[0].stride() * 5);
!   assert(d2[1].stride() == d1[1].stride() * 5);
!   assert(d2[2].stride() == d1[2].stride() * 5);
    // operator * (stride_scalar_type, Domain<>)
    d2 = 2 * d2;
!   assert(d2[0].stride() == d1[0].stride() * 10);
!   assert(d2[1].stride() == d1[1].stride() * 10);
!   assert(d2[2].stride() == d1[2].stride() * 10);
    // operator / (Domain<>, stride_scalar_type)
    d2 = d2 / 10;
!   assert(d2[0].stride() == d1[0].stride());
!   assert(d2[1].stride() == d1[1].stride());
!   assert(d2[2].stride() == d1[2].stride());
  }
  
  int
--- 119,166 ----
    Domain<1> b(1, 1, 5);
    Domain<1> c(1, 1, 5);
    Domain<3> d1(a, b, c);
!   test_assert(d1.size() == 125);
    Domain<3> d2(d1);
!   test_assert (d1 == d2);
    Domain<3> d3;
    d3 = d1;
!   test_assert (d1 == d3);
!   test_assert(d1.element_conformant(d2));
    d1.impl_add_in(10);
!   test_assert(d1.element_conformant(d2));
!   test_assert(d1 != d2);
    Domain<2> x;
!   test_assert(!d1.product_conformant(x));
    // operator + (Domain<>, index_difference_type)
    d2 = d1 + 5;
!   test_assert(d2[0].first() == d1[0].first() + 5);
!   test_assert(d2[1].first() == d1[1].first() + 5);
!   test_assert(d2[2].first() == d1[2].first() + 5);
    // operator + (index_difference_type, Domain<>)
    d2 = 5 + d2;
!   test_assert(d2[0].first() == d1[0].first() + 10);
!   test_assert(d2[1].first() == d1[1].first() + 10);
!   test_assert(d2[2].first() == d1[2].first() + 10);
    // operator - (Domain<>, index_difference_type)
    d2 = d2 - 10;
!   test_assert(d2[0].first() == d1[0].first());
!   test_assert(d2[1].first() == d1[1].first());
!   test_assert(d2[2].first() == d1[2].first());
    // operator * (Domain<>, stride_scalar_type)
    d2 = d2 * 5;
!   test_assert(d2[0].stride() == d1[0].stride() * 5);
!   test_assert(d2[1].stride() == d1[1].stride() * 5);
!   test_assert(d2[2].stride() == d1[2].stride() * 5);
    // operator * (stride_scalar_type, Domain<>)
    d2 = 2 * d2;
!   test_assert(d2[0].stride() == d1[0].stride() * 10);
!   test_assert(d2[1].stride() == d1[1].stride() * 10);
!   test_assert(d2[2].stride() == d1[2].stride() * 10);
    // operator / (Domain<>, stride_scalar_type)
    d2 = d2 / 10;
!   test_assert(d2[0].stride() == d1[0].stride());
!   test_assert(d2[1].stride() == d1[1].stride());
!   test_assert(d2[2].stride() == d1[2].stride());
  }
  
  int
Index: tests/error_db.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/error_db.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 error_db.hpp
*** tests/error_db.hpp	12 Dec 2005 17:47:50 -0000	1.1
--- tests/error_db.hpp	20 Dec 2005 12:39:20 -0000
*************** error_db(
*** 35,41 ****
    using vsip::impl::Dim_of_view;
    using vsip::dimension_type;
  
!   assert(Dim_of_view<View1>::dim == Dim_of_view<View2>::dim);
    dimension_type const dim = Dim_of_view<View2>::dim;
  
    vsip::Index<dim> idx;
--- 35,41 ----
    using vsip::impl::Dim_of_view;
    using vsip::dimension_type;
  
!   test_assert(Dim_of_view<View1>::dim == Dim_of_view<View2>::dim);
    dimension_type const dim = Dim_of_view<View2>::dim;
  
    vsip::Index<dim> idx;
Index: tests/expr-coverage.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/expr-coverage.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 expr-coverage.cpp
*** tests/expr-coverage.cpp	15 Sep 2005 14:49:26 -0000	1.2
--- tests/expr-coverage.cpp	20 Dec 2005 12:39:20 -0000
***************
*** 11,17 ****
  ***********************************************************************/
  
  #include <iostream>
- #include <cassert>
  
  #include <vsip/support.hpp>
  #include <vsip/initfin.hpp>
--- 11,16 ----
*************** struct Test_add
*** 44,51 ****
      View3 view3)
    {
      length_type size = get_size(view3);
!     assert(Is_scalar<View1>::value || get_size(view1) == size);
!     assert(Is_scalar<View2>::value || get_size(view2) == size);
  
      typedef typename Value_type_of<View1>::type T1;
      typedef typename Value_type_of<View2>::type T2;
--- 43,50 ----
      View3 view3)
    {
      length_type size = get_size(view3);
!     test_assert(Is_scalar<View1>::value || get_size(view1) == size);
!     test_assert(Is_scalar<View2>::value || get_size(view2) == size);
  
      typedef typename Value_type_of<View1>::type T1;
      typedef typename Value_type_of<View2>::type T2;
*************** struct Test_add
*** 62,68 ****
      {
        int expected = (Is_scalar<View1>::value ? (2*0+1) : (2*i+1))
  	           + (Is_scalar<View2>::value ? (3*0+2) : (3*i+2));
!       assert(equal(get_nth(view3, i), T3(expected)));
      }
    }
  };
--- 61,67 ----
      {
        int expected = (Is_scalar<View1>::value ? (2*0+1) : (2*i+1))
  	           + (Is_scalar<View2>::value ? (3*0+2) : (3*i+2));
!       test_assert(equal(get_nth(view3, i), T3(expected)));
      }
    }
  };
*************** struct Test_ma
*** 85,93 ****
      View4 view4)	// Result
    {
      length_type size = get_size(view4);
!     assert(Is_scalar<View1>::value || get_size(view1) == size);
!     assert(Is_scalar<View2>::value || get_size(view2) == size);
!     assert(Is_scalar<View3>::value || get_size(view3) == size);
  
      typedef typename Value_type_of<View1>::type T1;
      typedef typename Value_type_of<View2>::type T2;
--- 84,92 ----
      View4 view4)	// Result
    {
      length_type size = get_size(view4);
!     test_assert(Is_scalar<View1>::value || get_size(view1) == size);
!     test_assert(Is_scalar<View2>::value || get_size(view2) == size);
!     test_assert(Is_scalar<View3>::value || get_size(view3) == size);
  
      typedef typename Value_type_of<View1>::type T1;
      typedef typename Value_type_of<View2>::type T2;
*************** struct Test_ma
*** 108,114 ****
        int expected = (Is_scalar<View1>::value ? (2*0+1) : (2*i+1))
  	           * (Is_scalar<View2>::value ? (3*0+2) : (3*i+2))
  	           + (Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
!       assert(equal(get_nth(view4, i), T4(expected)));
      }
      
      view4 = T4();
--- 107,113 ----
        int expected = (Is_scalar<View1>::value ? (2*0+1) : (2*i+1))
  	           * (Is_scalar<View2>::value ? (3*0+2) : (3*i+2))
  	           + (Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
!       test_assert(equal(get_nth(view4, i), T4(expected)));
      }
      
      view4 = T4();
*************** struct Test_ma
*** 119,125 ****
        int expected = (Is_scalar<View1>::value ? (2*0+1) : (2*i+1))
  	           * (Is_scalar<View2>::value ? (3*0+2) : (3*i+2))
  	           + (Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
!       assert(equal(get_nth(view4, i), T4(expected)));
      }
    }
  };
--- 118,124 ----
        int expected = (Is_scalar<View1>::value ? (2*0+1) : (2*i+1))
  	           * (Is_scalar<View2>::value ? (3*0+2) : (3*i+2))
  	           + (Is_scalar<View3>::value ? (5*0+3) : (5*i+3));
!       test_assert(equal(get_nth(view4, i), T4(expected)));
      }
    }
  };
Index: tests/expr-test.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/expr-test.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 expr-test.cpp
*** tests/expr-test.cpp	10 Aug 2005 15:57:55 -0000	1.5
--- tests/expr-test.cpp	20 Dec 2005 12:39:20 -0000
***************
*** 12,18 ****
  ***********************************************************************/
  
  #include <iostream>
! #include <cassert>
  #include <vsip/dense.hpp>
  #include <vsip/vector.hpp>
  #include <vsip/math.hpp>
--- 12,18 ----
  ***********************************************************************/
  
  #include <iostream>
! 
  #include <vsip/dense.hpp>
  #include <vsip/vector.hpp>
  #include <vsip/math.hpp>
*************** test_neg()
*** 219,225 ****
  
    v2 = t_neg(v1);
  
!   assert(v2.get(0) == -1.f);
  }
  
    
--- 219,225 ----
  
    v2 = t_neg(v1);
  
!   test_assert(v2.get(0) == -1.f);
  }
  
    
*************** test_expr()
*** 248,257 ****
    Vector<T> z5(len);
    z5           = t_mul(v2, v3);
  
!   assert(equal(z1.get(1), T(6)));
!   assert(equal(z2.get(1), T(4)));
!   assert(equal(z3.get(1), T(-4)));
!   assert(equal(z4.get(1), T(2)));
  
  }
  
--- 248,257 ----
    Vector<T> z5(len);
    z5           = t_mul(v2, v3);
  
!   test_assert(equal(z1.get(1), T(6)));
!   test_assert(equal(z2.get(1), T(4)));
!   test_assert(equal(z3.get(1), T(-4)));
!   test_assert(equal(z4.get(1), T(2)));
  
  }
  
*************** test_funcall()
*** 288,297 ****
    T s5 = vector_sum(t_add(t_mul(v2, v3), t_neg(t_add(v1, v3))));
  #endif
  
!   assert(equal(s1, T(1)));
!   assert(equal(s2, T(3)));
!   assert(equal(s3, T(3)));
!   assert(equal(s4, T(2)));
  }
  
  
--- 288,297 ----
    T s5 = vector_sum(t_add(t_mul(v2, v3), t_neg(t_add(v1, v3))));
  #endif
  
!   test_assert(equal(s1, T(1)));
!   test_assert(equal(s2, T(3)));
!   test_assert(equal(s3, T(3)));
!   test_assert(equal(s4, T(2)));
  }
  
  
Index: tests/expression.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/expression.cpp,v
retrieving revision 1.6
diff -c -p -r1.6 expression.cpp
*** tests/expression.cpp	19 Sep 2005 03:39:54 -0000	1.6
--- tests/expression.cpp	20 Dec 2005 12:39:20 -0000
***************
*** 12,18 ****
    Included Files
  ***********************************************************************/
  
- #include <cassert>
  #include <vsip/math.hpp>
  #include <vsip/dense.hpp>
  #include "test.hpp"
--- 12,17 ----
*************** test_unary_expr_1d()
*** 48,54 ****
    Unary_expr_block<1, Operation, Block, typename Block::value_type> expr(o);
  
    for (index_type i = 0; i != size; ++i)
!     assert(equal(expr.get(i),
  		 Operation<typename Block::value_type>::apply(o.get(i))));
  }
  
--- 47,53 ----
    Unary_expr_block<1, Operation, Block, typename Block::value_type> expr(o);
  
    for (index_type i = 0; i != size; ++i)
!     test_assert(equal(expr.get(i),
  		 Operation<typename Block::value_type>::apply(o.get(i))));
  }
  
*************** test_binary_expr_1d()
*** 74,80 ****
  		  RBlock, value_type> expr(d1, d2);
  
    for (index_type i = 0; i != size; ++i)
!     assert(equal(expr.get(i),
  		 Operation<typename LBlock::value_type,
  		           typename RBlock::value_type>::apply(d1.get(i),
  							       d2.get(i))));
--- 73,79 ----
  		  RBlock, value_type> expr(d1, d2);
  
    for (index_type i = 0; i != size; ++i)
!     test_assert(equal(expr.get(i),
  		 Operation<typename LBlock::value_type,
  		           typename RBlock::value_type>::apply(d1.get(i),
  							       d2.get(i))));
*************** test_1d()
*** 131,140 ****
  
    block_1d_interface_test(scalar);
  
!   assert(scalar.size() == 3);
!   assert(scalar.get(0) == 5.);
!   assert(scalar.get(1) == 5.);
!   assert(scalar.get(2) == 5.);
  }
  
  int
--- 130,139 ----
  
    block_1d_interface_test(scalar);
  
!   test_assert(scalar.size() == 3);
!   test_assert(scalar.get(0) == 5.);
!   test_assert(scalar.get(1) == 5.);
!   test_assert(scalar.get(2) == 5.);
  }
  
  int
Index: tests/extdata-fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/extdata-fft.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 extdata-fft.cpp
*** tests/extdata-fft.cpp	28 Sep 2005 04:32:54 -0000	1.4
--- tests/extdata-fft.cpp	20 Dec 2005 12:39:20 -0000
*************** public:
*** 106,113 ****
  
      // Important to check size.  If vectors are too large, our
      // buffers will overflow.
!     assert(vin.size()  == size_);
!     assert(vout.size() == size_);
  
      if (verbose_)
      {
--- 106,113 ----
  
      // Important to check size.  If vectors are too large, our
      // buffers will overflow.
!     test_assert(vin.size()  == size_);
!     test_assert(vout.size() == size_);
  
      if (verbose_)
      {
*************** public:
*** 131,147 ****
  	   <<    impl::mem_required<LP>(vout.block()) << endl;
      }
  
!     assert(impl::mem_required<LP>(vin.block())  <= sizeof(T)*size_);
!     assert(impl::mem_required<LP>(vout.block()) <= sizeof(T)*size_);
  
      layout1 rin (vin.block(),  impl::SYNC_IN,  buffer_ + 0);
      layout2 rout(vout.block(), impl::SYNC_OUT, buffer_ + size_);
  
!     assert(rin.stride(0) == 1);
!     assert(rin.size(0) == size_);
  
!     assert(rout.stride(0) == 1);
!     assert(rout.size(0) == size_);
  
      fft_unit_stride(rin.data(), rout.data(), size_);
    }
--- 131,147 ----
  	   <<    impl::mem_required<LP>(vout.block()) << endl;
      }
  
!     test_assert(impl::mem_required<LP>(vin.block())  <= sizeof(T)*size_);
!     test_assert(impl::mem_required<LP>(vout.block()) <= sizeof(T)*size_);
  
      layout1 rin (vin.block(),  impl::SYNC_IN,  buffer_ + 0);
      layout2 rout(vout.block(), impl::SYNC_OUT, buffer_ + size_);
  
!     test_assert(rin.stride(0) == 1);
!     test_assert(rin.size(0) == size_);
  
!     test_assert(rout.stride(0) == 1);
!     test_assert(rout.size(0) == size_);
  
      fft_unit_stride(rin.data(), rout.data(), size_);
    }
*************** public:
*** 187,194 ****
  
      // Important to check size.  If vectors are too large, our
      // buffers will overflow.
!     assert(vin.size()  == size_);
!     assert(vout.size() == size_);
  
      if (verbose_)
      {
--- 187,194 ----
  
      // Important to check size.  If vectors are too large, our
      // buffers will overflow.
!     test_assert(vin.size()  == size_);
!     test_assert(vout.size() == size_);
  
      if (verbose_)
      {
*************** public:
*** 212,230 ****
  	   <<    impl::mem_required<LP>(vout.block()) << endl;
      }
  
!     assert(impl::mem_required<LP>(vin.block())  <= sizeof(T)*size_);
!     assert(impl::mem_required<LP>(vout.block()) <= sizeof(T)*size_);
  
      layout1 rin (vin.block(),  impl::SYNC_IN,  
  		 make_pair(buffer_ + 0, buffer_ + size_));
      layout2 rout(vout.block(), impl::SYNC_OUT,
  		 make_pair(buffer_ + 2*size_, buffer_ + 3*size_));
  
!     assert(rin.stride(0) == 1);
!     assert(rin.size(0) == size_);
  
!     assert(rout.stride(0) == 1);
!     assert(rout.size(0) == size_);
  
      fft_unit_stride_split(rin.data().first,  rin.data().second,
  			  rout.data().first, rout.data().second,
--- 212,230 ----
  	   <<    impl::mem_required<LP>(vout.block()) << endl;
      }
  
!     test_assert(impl::mem_required<LP>(vin.block())  <= sizeof(T)*size_);
!     test_assert(impl::mem_required<LP>(vout.block()) <= sizeof(T)*size_);
  
      layout1 rin (vin.block(),  impl::SYNC_IN,  
  		 make_pair(buffer_ + 0, buffer_ + size_));
      layout2 rout(vout.block(), impl::SYNC_OUT,
  		 make_pair(buffer_ + 2*size_, buffer_ + 3*size_));
  
!     test_assert(rin.stride(0) == 1);
!     test_assert(rin.size(0) == size_);
  
!     test_assert(rout.stride(0) == 1);
!     test_assert(rout.size(0) == size_);
  
      fft_unit_stride_split(rin.data().first,  rin.data().second,
  			  rout.data().first, rout.data().second,
*************** test_view(const_Vector<complex<T>, Block
*** 290,296 ****
  	   << "       Got      = " << vec.get(i) << endl
  	   << "       expected = " << vec.get(i) << endl;
      }
!     assert(equal(vec.get(i), complex<T>(T(k*i+1), T(k*i+2))));
    }
  }
  
--- 290,296 ----
  	   << "       Got      = " << vec.get(i) << endl
  	   << "       expected = " << vec.get(i) << endl;
      }
!     test_assert(equal(vec.get(i), complex<T>(T(k*i+1), T(k*i+2))));
    }
  }
  
Index: tests/extdata-matadd.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/extdata-matadd.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 extdata-matadd.cpp
*** tests/extdata-matadd.cpp	19 Sep 2005 03:39:54 -0000	1.4
--- tests/extdata-matadd.cpp	20 Dec 2005 12:39:20 -0000
*************** struct Matrix_add<TR, T1, T2, BlockR, Bl
*** 352,360 ****
      typedef impl::No_count_policy RP;
  
      // Check that no memory is required.
!     // assert((impl::Ext_data<BlockR, layout_type>::CT_Mem_not_req));
!     // assert((impl::Ext_data<Block1, layout_type>::CT_Mem_not_req));
!     // assert((impl::Ext_data<Block2, layout_type>::CT_Mem_not_req));
  
      impl::Ext_data<BlockR, layout_type, RP> raw_res(res.block(), impl::SYNC_OUT);
      impl::Ext_data<Block1, layout_type, RP> raw1(op1.block(), impl::SYNC_IN);
--- 352,360 ----
      typedef impl::No_count_policy RP;
  
      // Check that no memory is required.
!     // test_assert((impl::Ext_data<BlockR, layout_type>::CT_Mem_not_req));
!     // test_assert((impl::Ext_data<Block1, layout_type>::CT_Mem_not_req));
!     // test_assert((impl::Ext_data<Block2, layout_type>::CT_Mem_not_req));
  
      impl::Ext_data<BlockR, layout_type, RP> raw_res(res.block(), impl::SYNC_OUT);
      impl::Ext_data<Block1, layout_type, RP> raw1(op1.block(), impl::SYNC_IN);
*************** test_matrix_add()
*** 425,445 ****
  
    for (index_type r=0; r<num_rows; ++r)
      for (index_type c=0; c<num_cols; ++c)
!       assert(equal(res.get(r, c), view1.get(r, c) + view2.get(r, c)));
  
  
    matrix_add_2(res, view1, view2);
  
    for (index_type r=0; r<num_rows; ++r)
      for (index_type c=0; c<num_cols; ++c)
!       assert(equal(res.get(r, c), view1.get(r, c) + view2.get(r, c)));
  
  
    matrix_add(res, view1, view2);
  
    for (index_type r=0; r<num_rows; ++r)
      for (index_type c=0; c<num_cols; ++c)
!       assert(equal(res.get(r, c), view1.get(r, c) + view2.get(r, c)));
  }
  
  
--- 425,445 ----
  
    for (index_type r=0; r<num_rows; ++r)
      for (index_type c=0; c<num_cols; ++c)
!       test_assert(equal(res.get(r, c), view1.get(r, c) + view2.get(r, c)));
  
  
    matrix_add_2(res, view1, view2);
  
    for (index_type r=0; r<num_rows; ++r)
      for (index_type c=0; c<num_cols; ++c)
!       test_assert(equal(res.get(r, c), view1.get(r, c) + view2.get(r, c)));
  
  
    matrix_add(res, view1, view2);
  
    for (index_type r=0; r<num_rows; ++r)
      for (index_type c=0; c<num_cols; ++c)
!       test_assert(equal(res.get(r, c), view1.get(r, c) + view2.get(r, c)));
  }
  
  
Index: tests/extdata-runtime.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/extdata-runtime.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 extdata-runtime.cpp
*** tests/extdata-runtime.cpp	4 Aug 2005 11:53:03 -0000	1.1
--- tests/extdata-runtime.cpp	20 Dec 2005 12:39:20 -0000
*************** test_vector(
*** 143,165 ****
        ;
  #endif
      
!     assert((ct_cost == impl::Ext_data_cost<BlockT, LP>::value));
!     assert(rt_cost == ext.cost());
  
!     assert(ext.size(0) == view.size(0));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
  
      for (index_type i=0; i<ext.size(0); ++i)
      {
!       assert(equal(ptr[i*stride0], T(i)));
        ptr[i*stride0] = T(i+100);
        }
    }
  
    for (index_type i=0; i<view.size(0); ++i)
!     assert(equal(view.get(i), T(i+100)));
  }
  
  
--- 143,165 ----
        ;
  #endif
      
!     test_assert((ct_cost == impl::Ext_data_cost<BlockT, LP>::value));
!     test_assert(rt_cost == ext.cost());
  
!     test_assert(ext.size(0) == view.size(0));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
  
      for (index_type i=0; i<ext.size(0); ++i)
      {
!       test_assert(equal(ptr[i*stride0], T(i)));
        ptr[i*stride0] = T(i+100);
        }
    }
  
    for (index_type i=0; i<view.size(0); ++i)
!     test_assert(equal(view.get(i), T(i+100)));
  }
  
  
*************** test_matrix(
*** 275,285 ****
        ;
  #endif
      
!     assert((ct_cost == impl::Ext_data_cost<BlockT, LP>::value));
!     assert(rt_cost == ext.cost());
  
!     assert(ext.size(0) == view.size(0));
!     assert(ext.size(1) == view.size(1));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
--- 275,285 ----
        ;
  #endif
      
!     test_assert((ct_cost == impl::Ext_data_cost<BlockT, LP>::value));
!     test_assert(rt_cost == ext.cost());
  
!     test_assert(ext.size(0) == view.size(0));
!     test_assert(ext.size(1) == view.size(1));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
*************** test_matrix(
*** 288,301 ****
      for (index_type i=0; i<ext.size(0); ++i)
        for (index_type j=0; j<ext.size(1); ++j)
        {
! 	assert(equal(ptr[i*stride0 + j*stride1], T(i*view.size(1)+j)));
  	ptr[i*stride0 + j*stride1] = T(i+j*view.size(0));
        }
    }
  
    for (index_type i=0; i<view.size(0); ++i)
      for (index_type j=0; j<view.size(1); ++j)
!       assert(equal(view.get(i, j), T(i+j*view.size(0))));
  }
  
  
--- 288,301 ----
      for (index_type i=0; i<ext.size(0); ++i)
        for (index_type j=0; j<ext.size(1); ++j)
        {
! 	test_assert(equal(ptr[i*stride0 + j*stride1], T(i*view.size(1)+j)));
  	ptr[i*stride0 + j*stride1] = T(i+j*view.size(0));
        }
    }
  
    for (index_type i=0; i<view.size(0); ++i)
      for (index_type j=0; j<view.size(1); ++j)
!       test_assert(equal(view.get(i, j), T(i+j*view.size(0))));
  }
  
  
*************** test_tensor(
*** 437,448 ****
        ;
  #endif
      
!     assert((ct_cost == impl::Ext_data_cost<BlockT, LP>::value));
!     assert(rt_cost == ext.cost());
  
!     assert(ext.size(0) == view.size(0));
!     assert(ext.size(1) == view.size(1));
!     assert(ext.size(2) == view.size(2));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
--- 437,448 ----
        ;
  #endif
      
!     test_assert((ct_cost == impl::Ext_data_cost<BlockT, LP>::value));
!     test_assert(rt_cost == ext.cost());
  
!     test_assert(ext.size(0) == view.size(0));
!     test_assert(ext.size(1) == view.size(1));
!     test_assert(ext.size(2) == view.size(2));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
*************** test_tensor(
*** 453,459 ****
        for (index_type j=0; j<ext.size(1); ++j)
  	for (index_type k=0; k<ext.size(2); ++k)
  	{
! 	  assert(equal(ptr[i*stride0 + j*stride1 + k*stride2],
  		       T(i*view.size(1)*view.size(2) + j*view.size(2) + k)));
  	  ptr[i*stride0 + j*stride1 + k*stride2] =
  	    T(i+j*view.size(0)+k*view.size(0)*view.size(1));
--- 453,459 ----
        for (index_type j=0; j<ext.size(1); ++j)
  	for (index_type k=0; k<ext.size(2); ++k)
  	{
! 	  test_assert(equal(ptr[i*stride0 + j*stride1 + k*stride2],
  		       T(i*view.size(1)*view.size(2) + j*view.size(2) + k)));
  	  ptr[i*stride0 + j*stride1 + k*stride2] =
  	    T(i+j*view.size(0)+k*view.size(0)*view.size(1));
*************** test_tensor(
*** 463,469 ****
    for (index_type i=0; i<view.size(0); ++i)
      for (index_type j=0; j<view.size(1); ++j)
        for (index_type k=0; k<view.size(2); ++k)
! 	assert(equal(view.get(i, j, k),
  		     T(i+j*view.size(0)+k*view.size(0)*view.size(1))));
  }
  
--- 463,469 ----
    for (index_type i=0; i<view.size(0); ++i)
      for (index_type j=0; j<view.size(1); ++j)
        for (index_type k=0; k<view.size(2); ++k)
! 	test_assert(equal(view.get(i, j, k),
  		     T(i+j*view.size(0)+k*view.size(0)*view.size(1))));
  }
  
*************** matrix_tests()
*** 742,760 ****
    // compile-time.
  
    // Row-major is not aligned.
!   assert(g_cols * sizeof(float) % 16 != 0);
    Tm<row_t, Full, Full, Stride_unit_align<16>, Same, Same>::test(2, 2);
  
    // Every fourth column is aligned, for row-major:
!   assert(4 * g_cols * sizeof(float) % 16 == 0);
    Tm<row_t, Spar4, Full, Stride_unit_align<16>, Same, Same>::test(2, 0);
  
    // Column-major is not aligned.
!   assert(g_rows * sizeof(float) % 16 != 0);
    Tm<col_t, Full, Full, Stride_unit_align<16>, Same, Same>::test(2, 2);
  
    // Every other row is aligned, for column-major:
!   assert(2 * g_rows * sizeof(float) % 16 == 0);
    Tm<col_t, Full, Spar, Stride_unit_align<16>, Same, Same>::test(2, 0);
  }
  
--- 742,760 ----
    // compile-time.
  
    // Row-major is not aligned.
!   test_assert(g_cols * sizeof(float) % 16 != 0);
    Tm<row_t, Full, Full, Stride_unit_align<16>, Same, Same>::test(2, 2);
  
    // Every fourth column is aligned, for row-major:
!   test_assert(4 * g_cols * sizeof(float) % 16 == 0);
    Tm<row_t, Spar4, Full, Stride_unit_align<16>, Same, Same>::test(2, 0);
  
    // Column-major is not aligned.
!   test_assert(g_rows * sizeof(float) % 16 != 0);
    Tm<col_t, Full, Full, Stride_unit_align<16>, Same, Same>::test(2, 2);
  
    // Every other row is aligned, for column-major:
!   test_assert(2 * g_rows * sizeof(float) % 16 == 0);
    Tm<col_t, Full, Spar, Stride_unit_align<16>, Same, Same>::test(2, 0);
  }
  
*************** tensor_tests()
*** 801,808 ****
    Tt<col_t, Full, Cont, Cont, Stride_unit_dense, Same, Same>::test(2, 2);
    Tt<col_t, Full, Cont, Sing, Stride_unit_dense, Same, Same>::test(2, 0);
  
!   assert(g_dim2 * sizeof(float) % 16 != 0); // row_t is not aligned
!   assert(g_dim0 * sizeof(float) % 16 == 0); // col_t is     aligned
  
    Tt<row_t, Full, Full, Full, Stride_unit_align<16>, Same, Same>::test(2, 2);
    Tt<col_t, Full, Full, Full, Stride_unit_align<16>, Same, Same>::test(2, 0);
--- 801,808 ----
    Tt<col_t, Full, Cont, Cont, Stride_unit_dense, Same, Same>::test(2, 2);
    Tt<col_t, Full, Cont, Sing, Stride_unit_dense, Same, Same>::test(2, 0);
  
!   test_assert(g_dim2 * sizeof(float) % 16 != 0); // row_t is not aligned
!   test_assert(g_dim0 * sizeof(float) % 16 == 0); // col_t is     aligned
  
    Tt<row_t, Full, Full, Full, Stride_unit_align<16>, Same, Same>::test(2, 2);
    Tt<col_t, Full, Full, Full, Stride_unit_align<16>, Same, Same>::test(2, 0);
Index: tests/extdata-subviews.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/extdata-subviews.cpp,v
retrieving revision 1.6
diff -c -p -r1.6 extdata-subviews.cpp
*** tests/extdata-subviews.cpp	19 Sep 2005 03:39:54 -0000	1.6
--- tests/extdata-subviews.cpp	20 Dec 2005 12:39:20 -0000
*************** test_vector_subview(
*** 110,117 ****
  
    view = T();
  
!   assert(impl::Ext_data_cost<BlockT>::value == 0);
!   assert(impl::Ext_data_cost<subblock_type>::value == 0);
  
    subview_type subv = view(subdom);
  
--- 110,117 ----
  
    view = T();
  
!   test_assert(impl::Ext_data_cost<BlockT>::value == 0);
!   test_assert(impl::Ext_data_cost<subblock_type>::value == 0);
  
    subview_type subv = view(subdom);
  
*************** test_vector_subview(
*** 119,136 ****
      impl::Ext_data<subblock_type> ext(subv.block());
  
      // This should be direct access
!     assert(ext.CT_Cost         == 0);
!     assert(ext.CT_Mem_not_req  == true);
!     assert(ext.CT_Xfer_not_req == true);
  
!     assert(ext.size(0) == subdom[0].size());
  
      ptr_type    ptr     = ext.data();
      stride_type stride0 = ext.stride(0);
      
      for (index_type i=0; i<ext.size(0); ++i)
      {
!       assert(equal(storage_type::get(ptr, i*stride0), T()));
        storage_type::put(ptr, i*stride0, T(i));
      }
    }
--- 119,136 ----
      impl::Ext_data<subblock_type> ext(subv.block());
  
      // This should be direct access
!     test_assert(ext.CT_Cost         == 0);
!     test_assert(ext.CT_Mem_not_req  == true);
!     test_assert(ext.CT_Xfer_not_req == true);
  
!     test_assert(ext.size(0) == subdom[0].size());
  
      ptr_type    ptr     = ext.data();
      stride_type stride0 = ext.stride(0);
      
      for (index_type i=0; i<ext.size(0); ++i)
      {
!       test_assert(equal(storage_type::get(ptr, i*stride0), T()));
        storage_type::put(ptr, i*stride0, T(i));
      }
    }
*************** test_vector_subview(
*** 139,145 ****
    {
      index_type ni = subdom[0].impl_nth(i);
  
!     assert(equal(view.get(ni), T(i)));
      view.put(ni, T(i + 100));
    }
  
--- 139,145 ----
    {
      index_type ni = subdom[0].impl_nth(i);
  
!     test_assert(equal(view.get(ni), T(i)));
      view.put(ni, T(i + 100));
    }
  
*************** test_vector_subview(
*** 147,164 ****
      impl::Ext_data<subblock_type> ext(subv.block());
  
      // This should be direct access
!     assert(ext.CT_Cost         == 0);
!     assert(ext.CT_Mem_not_req  == true);
!     assert(ext.CT_Xfer_not_req == true);
  
!     assert(ext.size(0) == subdom[0].size());
  
      ptr_type    ptr     = ext.data();
      stride_type stride0 = ext.stride(0);
      
      for (index_type i=0; i<ext.size(0); ++i)
      {
!       assert(equal(storage_type::get(ptr, i*stride0), T(i + 100)));
      }
    }
  }
--- 147,164 ----
      impl::Ext_data<subblock_type> ext(subv.block());
  
      // This should be direct access
!     test_assert(ext.CT_Cost         == 0);
!     test_assert(ext.CT_Mem_not_req  == true);
!     test_assert(ext.CT_Xfer_not_req == true);
  
!     test_assert(ext.size(0) == subdom[0].size());
  
      ptr_type    ptr     = ext.data();
      stride_type stride0 = ext.stride(0);
      
      for (index_type i=0; i<ext.size(0); ++i)
      {
!       test_assert(equal(storage_type::get(ptr, i*stride0), T(i + 100)));
      }
    }
  }
*************** test_vector_realimag(
*** 210,218 ****
  
    view = complex<T>();
  
!   assert(impl::Ext_data_cost<BlockT>::value == 0);
!   assert(impl::Ext_data_cost<realblock_type>::value == 0);
!   assert(impl::Ext_data_cost<imagblock_type>::value == 0);
  
    realview_type real = view.real();
    imagview_type imag = view.imag();
--- 210,218 ----
  
    view = complex<T>();
  
!   test_assert(impl::Ext_data_cost<BlockT>::value == 0);
!   test_assert(impl::Ext_data_cost<realblock_type>::value == 0);
!   test_assert(impl::Ext_data_cost<imagblock_type>::value == 0);
  
    realview_type real = view.real();
    imagview_type imag = view.imag();
*************** test_vector_realimag(
*** 222,239 ****
      impl::Ext_data<realblock_type> ext(real.block());
  
      // This should be direct access
!     assert(ext.CT_Cost         == 0);
!     assert(ext.CT_Mem_not_req  == true);
!     assert(ext.CT_Xfer_not_req == true);
  
!     assert(ext.size(0) == view.size(0));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
      
      for (index_type i=0; i<ext.size(0); ++i)
      {
!       assert(equal(ptr[i*stride0], T()));
        ptr[i*stride0] = T(3*i+1);
      }
    }
--- 222,239 ----
      impl::Ext_data<realblock_type> ext(real.block());
  
      // This should be direct access
!     test_assert(ext.CT_Cost         == 0);
!     test_assert(ext.CT_Mem_not_req  == true);
!     test_assert(ext.CT_Xfer_not_req == true);
  
!     test_assert(ext.size(0) == view.size(0));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
      
      for (index_type i=0; i<ext.size(0); ++i)
      {
!       test_assert(equal(ptr[i*stride0], T()));
        ptr[i*stride0] = T(3*i+1);
      }
    }
*************** test_vector_realimag(
*** 243,260 ****
      impl::Ext_data<imagblock_type> ext(imag.block());
  
      // This should be direct access
!     assert(ext.CT_Cost         == 0);
!     assert(ext.CT_Mem_not_req  == true);
!     assert(ext.CT_Xfer_not_req == true);
  
!     assert(ext.size(0) == view.size(0));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
      
      for (index_type i=0; i<ext.size(0); ++i)
      {
!       assert(equal(ptr[i*stride0], T()));
        ptr[i*stride0] = T(4*i+1);
      }
    }
--- 243,260 ----
      impl::Ext_data<imagblock_type> ext(imag.block());
  
      // This should be direct access
!     test_assert(ext.CT_Cost         == 0);
!     test_assert(ext.CT_Mem_not_req  == true);
!     test_assert(ext.CT_Xfer_not_req == true);
  
!     test_assert(ext.size(0) == view.size(0));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
      
      for (index_type i=0; i<ext.size(0); ++i)
      {
!       test_assert(equal(ptr[i*stride0], T()));
        ptr[i*stride0] = T(4*i+1);
      }
    }
*************** test_vector_realimag(
*** 262,270 ****
    // Check the original views using get/put.
    for (index_type i=0; i<view.size(0); ++i)
    {
!     assert(equal(real.get(i), T(3*i+1)));
!     assert(equal(imag.get(i), T(4*i+1)));
!     assert(equal(view.get(i), complex<T>(3*i+1, 4*i+1)));
  
      view.put(i, complex<T>(5*i+1, 7*i+1));
    }
--- 262,270 ----
    // Check the original views using get/put.
    for (index_type i=0; i<view.size(0); ++i)
    {
!     test_assert(equal(real.get(i), T(3*i+1)));
!     test_assert(equal(imag.get(i), T(4*i+1)));
!     test_assert(equal(view.get(i), complex<T>(3*i+1, 4*i+1)));
  
      view.put(i, complex<T>(5*i+1, 7*i+1));
    }
*************** test_vector_realimag(
*** 274,281 ****
      impl::Ext_data<realblock_type> rext(real.block());
      impl::Ext_data<imagblock_type> iext(imag.block());
  
!     assert(rext.size(0) == view.size(0));
!     assert(iext.size(0) == view.size(0));
  
      T* rptr              = rext.data();
      T* iptr              = iext.data();
--- 274,281 ----
      impl::Ext_data<realblock_type> rext(real.block());
      impl::Ext_data<imagblock_type> iext(imag.block());
  
!     test_assert(rext.size(0) == view.size(0));
!     test_assert(iext.size(0) == view.size(0));
  
      T* rptr              = rext.data();
      T* iptr              = iext.data();
*************** test_vector_realimag(
*** 284,291 ****
      
      for (index_type i=0; i<view.size(0); ++i)
      {
!       assert(equal(rptr[i*rstride0], T(5*i+1)));
!       assert(equal(iptr[i*istride0], T(7*i+1)));
  
        rptr[i*rstride0] = T(3*i+2);
        iptr[i*istride0] = T(2*i+1);
--- 284,291 ----
      
      for (index_type i=0; i<view.size(0); ++i)
      {
!       test_assert(equal(rptr[i*rstride0], T(5*i+1)));
!       test_assert(equal(iptr[i*istride0], T(7*i+1)));
  
        rptr[i*rstride0] = T(3*i+2);
        iptr[i*istride0] = T(2*i+1);
*************** test_vector_realimag(
*** 295,303 ****
    // Check the original views using get/put.
    for (index_type i=0; i<view.size(0); ++i)
    {
!     assert(equal(real.get(i), T(3*i+2)));
!     assert(equal(imag.get(i), T(2*i+1)));
!     assert(equal(view.get(i), complex<T>(3*i+2, 2*i+1)));
    }
  }
  
--- 295,303 ----
    // Check the original views using get/put.
    for (index_type i=0; i<view.size(0); ++i)
    {
!     test_assert(equal(real.get(i), T(3*i+2)));
!     test_assert(equal(imag.get(i), T(2*i+1)));
!     test_assert(equal(view.get(i), complex<T>(3*i+2, 2*i+1)));
    }
  }
  
*************** test_row_subview(
*** 341,348 ****
  
    mat = T();
  
!   assert(impl::Ext_data_cost<BlockT>::value == 0);
!   assert(impl::Ext_data_cost<row_block_type>::value == 0);
  
    // Initialize the matrix using DDA by row subview.
    for (index_type r=0; r<rows; ++r)
--- 341,348 ----
  
    mat = T();
  
!   test_assert(impl::Ext_data_cost<BlockT>::value == 0);
!   test_assert(impl::Ext_data_cost<row_block_type>::value == 0);
  
    // Initialize the matrix using DDA by row subview.
    for (index_type r=0; r<rows; ++r)
*************** test_row_subview(
*** 352,369 ****
      {
        impl::Ext_data<row_block_type> ext(row.block());
  
!       assert(ext.CT_Cost         == 0);
!       assert(ext.CT_Mem_not_req  == true);
!       assert(ext.CT_Xfer_not_req == true);
        
!       assert(ext.size(0) == cols);
  
        T* ptr             = ext.data();
        stride_type stride = ext.stride(0);
  
        for (index_type i=0; i<ext.size(0); ++i)
        {
! 	assert(equal(ptr[i*stride], T()));
  	ptr[i*stride] = T(r*cols+i);
        }
      }
--- 352,369 ----
      {
        impl::Ext_data<row_block_type> ext(row.block());
  
!       test_assert(ext.CT_Cost         == 0);
!       test_assert(ext.CT_Mem_not_req  == true);
!       test_assert(ext.CT_Xfer_not_req == true);
        
!       test_assert(ext.size(0) == cols);
  
        T* ptr             = ext.data();
        stride_type stride = ext.stride(0);
  
        for (index_type i=0; i<ext.size(0); ++i)
        {
! 	test_assert(equal(ptr[i*stride], T()));
  	ptr[i*stride] = T(r*cols+i);
        }
      }
*************** test_row_subview(
*** 373,379 ****
    for (index_type r=0; r<rows; ++r)
      for (index_type c=0; c<cols; ++c)
      {
!       assert(equal(mat(r, c), T(r*cols+c)));
        mat(r, c) += T(1);
      }
  
--- 373,379 ----
    for (index_type r=0; r<rows; ++r)
      for (index_type c=0; c<cols; ++c)
      {
!       test_assert(equal(mat(r, c), T(r*cols+c)));
        mat(r, c) += T(1);
      }
  
*************** test_row_subview(
*** 385,401 ****
      {
        impl::Ext_data<row_block_type> ext(row.block());
  
!       assert(ext.CT_Cost         == 0);
!       assert(ext.CT_Mem_not_req  == true);
!       assert(ext.CT_Xfer_not_req == true);
        
!       assert(ext.size(0) == cols);
  
        T* ptr             = ext.data();
        stride_type stride = ext.stride(0);
  
        for (index_type i=0; i<ext.size(0); ++i)
! 	assert(equal(ptr[i*stride], T(r*cols+i + 1)));
      }
    }
  }
--- 385,401 ----
      {
        impl::Ext_data<row_block_type> ext(row.block());
  
!       test_assert(ext.CT_Cost         == 0);
!       test_assert(ext.CT_Mem_not_req  == true);
!       test_assert(ext.CT_Xfer_not_req == true);
        
!       test_assert(ext.size(0) == cols);
  
        T* ptr             = ext.data();
        stride_type stride = ext.stride(0);
  
        for (index_type i=0; i<ext.size(0); ++i)
! 	test_assert(equal(ptr[i*stride], T(r*cols+i + 1)));
      }
    }
  }
*************** test_col_subview(
*** 417,424 ****
  
    mat = T();
  
!   assert(impl::Ext_data_cost<BlockT>::value == 0);
!   assert(impl::Ext_data_cost<col_block_type>::value == 0);
  
    // Initialize the matrix using DDA by col subview.
    for (index_type c=0; c<cols; ++c)
--- 417,424 ----
  
    mat = T();
  
!   test_assert(impl::Ext_data_cost<BlockT>::value == 0);
!   test_assert(impl::Ext_data_cost<col_block_type>::value == 0);
  
    // Initialize the matrix using DDA by col subview.
    for (index_type c=0; c<cols; ++c)
*************** test_col_subview(
*** 428,445 ****
      {
        impl::Ext_data<col_block_type> ext(col.block());
  
!       assert(ext.CT_Cost         == 0);
!       assert(ext.CT_Mem_not_req  == true);
!       assert(ext.CT_Xfer_not_req == true);
        
!       assert(ext.size(0) == rows);
  
        T* ptr             = ext.data();
        stride_type stride = ext.stride(0);
  
        for (index_type i=0; i<ext.size(0); ++i)
        {
! 	assert(equal(ptr[i*stride], T()));
  	ptr[i*stride] = T(c*rows+i);
        }
      }
--- 428,445 ----
      {
        impl::Ext_data<col_block_type> ext(col.block());
  
!       test_assert(ext.CT_Cost         == 0);
!       test_assert(ext.CT_Mem_not_req  == true);
!       test_assert(ext.CT_Xfer_not_req == true);
        
!       test_assert(ext.size(0) == rows);
  
        T* ptr             = ext.data();
        stride_type stride = ext.stride(0);
  
        for (index_type i=0; i<ext.size(0); ++i)
        {
! 	test_assert(equal(ptr[i*stride], T()));
  	ptr[i*stride] = T(c*rows+i);
        }
      }
*************** test_col_subview(
*** 449,455 ****
    for (index_type r=0; r<rows; ++r)
      for (index_type c=0; c<cols; ++c)
      {
!       assert(equal(mat(r, c), T(c*rows+r)));
        mat(r, c) += T(1);
      }
  
--- 449,455 ----
    for (index_type r=0; r<rows; ++r)
      for (index_type c=0; c<cols; ++c)
      {
!       test_assert(equal(mat(r, c), T(c*rows+r)));
        mat(r, c) += T(1);
      }
  
*************** test_col_subview(
*** 461,477 ****
      {
        impl::Ext_data<col_block_type> ext(col.block());
  
!       assert(ext.CT_Cost         == 0);
!       assert(ext.CT_Mem_not_req  == true);
!       assert(ext.CT_Xfer_not_req == true);
        
!       assert(ext.size(0) == rows);
  
        T* ptr             = ext.data();
        stride_type stride = ext.stride(0);
  
        for (index_type i=0; i<ext.size(0); ++i)
! 	assert(equal(ptr[i*stride], T(c*rows+i + 1)));
      }
    }
  }
--- 461,477 ----
      {
        impl::Ext_data<col_block_type> ext(col.block());
  
!       test_assert(ext.CT_Cost         == 0);
!       test_assert(ext.CT_Mem_not_req  == true);
!       test_assert(ext.CT_Xfer_not_req == true);
        
!       test_assert(ext.size(0) == rows);
  
        T* ptr             = ext.data();
        stride_type stride = ext.stride(0);
  
        for (index_type i=0; i<ext.size(0); ++i)
! 	test_assert(equal(ptr[i*stride], T(c*rows+i + 1)));
      }
    }
  }
*************** test_diag_subview(
*** 493,502 ****
  
    mat = T();
  
!   assert(impl::Ext_data_cost<BlockT>::value == 0);
    // If the access cost to diagview_type::block_type is 0,
    // then direct access is being used.
!   assert(impl::Ext_data_cost<subblock_type>::value == 0);
  
    // Initialize the matrix using put with count
    for (index_type r=0; r<rows; ++r) {
--- 493,502 ----
  
    mat = T();
  
!   test_assert(impl::Ext_data_cost<BlockT>::value == 0);
    // If the access cost to diagview_type::block_type is 0,
    // then direct access is being used.
!   test_assert(impl::Ext_data_cost<subblock_type>::value == 0);
  
    // Initialize the matrix using put with count
    for (index_type r=0; r<rows; ++r) {
*************** test_diag_subview(
*** 521,529 ****
        for (index_type i = 0; i < size; ++i )
        {
          if ( d >= 0 )
!           assert( equal(ptr[i*str], T(i * cols + i + d) ) );
          else
!           assert( equal(ptr[i*str], T(i * cols + i - (d * cols)) ) );
  
          ptr[i*str] = T(M_PI + i);
        }
--- 521,529 ----
        for (index_type i = 0; i < size; ++i )
        {
          if ( d >= 0 )
!           test_assert( equal(ptr[i*str], T(i * cols + i + d) ) );
          else
!           test_assert( equal(ptr[i*str], T(i * cols + i - (d * cols)) ) );
  
          ptr[i*str] = T(M_PI + i);
        }
*************** test_diag_subview(
*** 533,541 ****
      for ( index_type i = 0; i < size; i++ )
      {
        if ( d >= 0 )
!         assert( equal( mat(i, i + d), T(M_PI + i) ) );
        else
!         assert( equal( mat(i - d, i), T(M_PI + i) ) );
      }
    }
  }
--- 533,541 ----
      for ( index_type i = 0; i < size; i++ )
      {
        if ( d >= 0 )
!         test_assert( equal( mat(i, i + d), T(M_PI + i) ) );
        else
!         test_assert( equal( mat(i - d, i), T(M_PI + i) ) );
      }
    }
  }
*************** test_matrix_subview(
*** 556,563 ****
  
    view = T();
  
!   assert(impl::Ext_data_cost<BlockT>::value == 0);
!   assert(impl::Ext_data_cost<subblock_type>::value == 0);
  
    subview_type subv = view(subdom);
  
--- 556,563 ----
  
    view = T();
  
!   test_assert(impl::Ext_data_cost<BlockT>::value == 0);
!   test_assert(impl::Ext_data_cost<subblock_type>::value == 0);
  
    subview_type subv = view(subdom);
  
*************** test_matrix_subview(
*** 565,576 ****
      impl::Ext_data<subblock_type> ext(subv.block());
  
      // This should be direct access
!     assert(ext.CT_Cost         == 0);
!     assert(ext.CT_Mem_not_req  == true);
!     assert(ext.CT_Xfer_not_req == true);
  
!     assert(ext.size(0) == subdom[0].size());
!     assert(ext.size(1) == subdom[1].size());
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
--- 565,576 ----
      impl::Ext_data<subblock_type> ext(subv.block());
  
      // This should be direct access
!     test_assert(ext.CT_Cost         == 0);
!     test_assert(ext.CT_Mem_not_req  == true);
!     test_assert(ext.CT_Xfer_not_req == true);
  
!     test_assert(ext.size(0) == subdom[0].size());
!     test_assert(ext.size(1) == subdom[1].size());
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
*************** test_matrix_subview(
*** 579,585 ****
      for (index_type i=0; i<ext.size(0); ++i)
        for (index_type j=0; j<ext.size(1); ++j)
        {
! 	assert(equal(ptr[i*stride0 + j*stride1], T()));
  	ptr[i*stride0 + j*stride1] = T(i*ext.size(1)+j);
        }
    }
--- 579,585 ----
      for (index_type i=0; i<ext.size(0); ++i)
        for (index_type j=0; j<ext.size(1); ++j)
        {
! 	test_assert(equal(ptr[i*stride0 + j*stride1], T()));
  	ptr[i*stride0 + j*stride1] = T(i*ext.size(1)+j);
        }
    }
*************** test_matrix_subview(
*** 590,596 ****
        index_type ni = subdom[0].impl_nth(i);
        index_type nj = subdom[1].impl_nth(j);
  
!       assert(view.get(ni, nj) == T(i*subdom[1].size()+j));
        view.put(ni, nj, T(i + j*subdom[0].size() + 100));
      }
  
--- 590,596 ----
        index_type ni = subdom[0].impl_nth(i);
        index_type nj = subdom[1].impl_nth(j);
  
!       test_assert(view.get(ni, nj) == T(i*subdom[1].size()+j));
        view.put(ni, nj, T(i + j*subdom[0].size() + 100));
      }
  
*************** test_matrix_subview(
*** 598,609 ****
      impl::Ext_data<subblock_type> ext(subv.block());
  
      // This should be direct access
!     assert(ext.CT_Cost         == 0);
!     assert(ext.CT_Mem_not_req  == true);
!     assert(ext.CT_Xfer_not_req == true);
  
!     assert(ext.size(0) == subdom[0].size());
!     assert(ext.size(1) == subdom[1].size());
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
--- 598,609 ----
      impl::Ext_data<subblock_type> ext(subv.block());
  
      // This should be direct access
!     test_assert(ext.CT_Cost         == 0);
!     test_assert(ext.CT_Mem_not_req  == true);
!     test_assert(ext.CT_Xfer_not_req == true);
  
!     test_assert(ext.size(0) == subdom[0].size());
!     test_assert(ext.size(1) == subdom[1].size());
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
*************** test_matrix_subview(
*** 612,618 ****
      for (index_type i=0; i<ext.size(0); ++i)
        for (index_type j=0; j<ext.size(1); ++j)
        {
! 	assert(equal(ptr[i*stride0 + j*stride1], T(i + j*ext.size(0) + 100)));
        }
    }
  }
--- 612,618 ----
      for (index_type i=0; i<ext.size(0); ++i)
        for (index_type j=0; j<ext.size(1); ++j)
        {
! 	test_assert(equal(ptr[i*stride0 + j*stride1], T(i + j*ext.size(0) + 100)));
        }
    }
  }
*************** test_matrix_realimag(
*** 668,676 ****
  
    view = complex<T>();
  
!   assert(impl::Ext_data_cost<BlockT>::value == 0);
!   assert(impl::Ext_data_cost<realblock_type>::value == 0);
!   assert(impl::Ext_data_cost<imagblock_type>::value == 0);
  
    realview_type real = view.real();
    imagview_type imag = view.imag();
--- 668,676 ----
  
    view = complex<T>();
  
!   test_assert(impl::Ext_data_cost<BlockT>::value == 0);
!   test_assert(impl::Ext_data_cost<realblock_type>::value == 0);
!   test_assert(impl::Ext_data_cost<imagblock_type>::value == 0);
  
    realview_type real = view.real();
    imagview_type imag = view.imag();
*************** test_matrix_realimag(
*** 680,691 ****
      impl::Ext_data<realblock_type> ext(real.block());
  
      // This should be direct access
!     assert(ext.CT_Cost         == 0);
!     assert(ext.CT_Mem_not_req  == true);
!     assert(ext.CT_Xfer_not_req == true);
  
!     assert(ext.size(0) == view.size(0));
!     assert(ext.size(1) == view.size(1));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
--- 680,691 ----
      impl::Ext_data<realblock_type> ext(real.block());
  
      // This should be direct access
!     test_assert(ext.CT_Cost         == 0);
!     test_assert(ext.CT_Mem_not_req  == true);
!     test_assert(ext.CT_Xfer_not_req == true);
  
!     test_assert(ext.size(0) == view.size(0));
!     test_assert(ext.size(1) == view.size(1));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
*************** test_matrix_realimag(
*** 695,701 ****
        for (index_type j=0; j<ext.size(1); ++j)
        {
  	index_type idx = (i*ext.size(1)+j);
! 	assert(equal(ptr[i*stride0 + j*stride1], T()));
  	ptr[i*stride0 + j*stride1] = T(3*idx+1);
        }
    }
--- 695,701 ----
        for (index_type j=0; j<ext.size(1); ++j)
        {
  	index_type idx = (i*ext.size(1)+j);
! 	test_assert(equal(ptr[i*stride0 + j*stride1], T()));
  	ptr[i*stride0 + j*stride1] = T(3*idx+1);
        }
    }
*************** test_matrix_realimag(
*** 705,716 ****
      impl::Ext_data<imagblock_type> ext(imag.block());
  
      // This should be direct access
!     assert(ext.CT_Cost         == 0);
!     assert(ext.CT_Mem_not_req  == true);
!     assert(ext.CT_Xfer_not_req == true);
  
!     assert(ext.size(0) == view.size(0));
!     assert(ext.size(1) == view.size(1));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
--- 705,716 ----
      impl::Ext_data<imagblock_type> ext(imag.block());
  
      // This should be direct access
!     test_assert(ext.CT_Cost         == 0);
!     test_assert(ext.CT_Mem_not_req  == true);
!     test_assert(ext.CT_Xfer_not_req == true);
  
!     test_assert(ext.size(0) == view.size(0));
!     test_assert(ext.size(1) == view.size(1));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
*************** test_matrix_realimag(
*** 720,726 ****
        for (index_type j=0; j<ext.size(1); ++j)
        {
  	index_type idx = (i*ext.size(1)+j);
! 	assert(equal(ptr[i*stride0 + j*stride1], T()));
  	ptr[i*stride0 + j*stride1] = T(4*idx+1);
        }
    }
--- 720,726 ----
        for (index_type j=0; j<ext.size(1); ++j)
        {
  	index_type idx = (i*ext.size(1)+j);
! 	test_assert(equal(ptr[i*stride0 + j*stride1], T()));
  	ptr[i*stride0 + j*stride1] = T(4*idx+1);
        }
    }
*************** test_matrix_realimag(
*** 731,739 ****
      {
        index_type idx = (i*view.size(1)+j);
  
!       assert(equal(real.get(i, j), T(3*idx+1)));
!       assert(equal(imag.get(i, j), T(4*idx+1)));
!       assert(equal(view.get(i, j), complex<T>(3*idx+1, 4*idx+1)));
  
        view.put(i, j, complex<T>(5*idx+1, 7*idx+1));
    }
--- 731,739 ----
      {
        index_type idx = (i*view.size(1)+j);
  
!       test_assert(equal(real.get(i, j), T(3*idx+1)));
!       test_assert(equal(imag.get(i, j), T(4*idx+1)));
!       test_assert(equal(view.get(i, j), complex<T>(3*idx+1, 4*idx+1)));
  
        view.put(i, j, complex<T>(5*idx+1, 7*idx+1));
    }
*************** test_matrix_realimag(
*** 755,762 ****
        {
  	index_type idx = (i*view.size(1)+j);
  
! 	assert(equal(rptr[i*rstride0+j*rstride1], T(5*idx+1)));
! 	assert(equal(iptr[i*istride0+j*istride1], T(7*idx+1)));
  
  	rptr[i*rstride0+j*rstride1] = T(3*idx+2);
  	iptr[i*istride0+j*rstride1] = T(2*idx+1);
--- 755,762 ----
        {
  	index_type idx = (i*view.size(1)+j);
  
! 	test_assert(equal(rptr[i*rstride0+j*rstride1], T(5*idx+1)));
! 	test_assert(equal(iptr[i*istride0+j*istride1], T(7*idx+1)));
  
  	rptr[i*rstride0+j*rstride1] = T(3*idx+2);
  	iptr[i*istride0+j*rstride1] = T(2*idx+1);
*************** test_matrix_realimag(
*** 769,777 ****
      {
        index_type idx = (i*view.size(1)+j);
  
!       assert(equal(real.get(i, j), T(3*idx+2)));
!       assert(equal(imag.get(i, j), T(2*idx+1)));
!       assert(equal(view.get(i, j), complex<T>(3*idx+2, 2*idx+1)));
      }
  }
  
--- 769,777 ----
      {
        index_type idx = (i*view.size(1)+j);
  
!       test_assert(equal(real.get(i, j), T(3*idx+2)));
!       test_assert(equal(imag.get(i, j), T(2*idx+1)));
!       test_assert(equal(view.get(i, j), complex<T>(3*idx+2, 2*idx+1)));
      }
  }
  
*************** test_tensor_vector_subview(
*** 939,946 ****
  
    view = T();
  
!   assert(impl::Ext_data_cost<BlockT>::value == 0);
!   // assert(impl::Ext_data_cost<subv_block_type>::value == 0);
  
    // dump_access_details<BlockT>();
    // dump_access_details<subv_block_type>();
--- 939,946 ----
  
    view = T();
  
!   test_assert(impl::Ext_data_cost<BlockT>::value == 0);
!   // test_assert(impl::Ext_data_cost<subv_block_type>::value == 0);
  
    // dump_access_details<BlockT>();
    // dump_access_details<subv_block_type>();
*************** test_tensor_vector_subview(
*** 954,971 ****
      {
        impl::Ext_data<subv_block_type> ext(subv.block());
  
!       assert(ext.CT_Cost         == 0);
!       assert(ext.CT_Mem_not_req  == true);
!       assert(ext.CT_Xfer_not_req == true);
        
!       assert(ext.size(0) == view.size(FreeDim));
  
        T* ptr             = ext.data();
        stride_type stride = ext.stride(0);
  
        for (index_type i=0; i<ext.size(0); ++i)
        {
! 	assert(equal(ptr[i*stride], T()));
  	ptr[i*stride] = info_type::value(view, i, j, k);
        }
      }
--- 954,971 ----
      {
        impl::Ext_data<subv_block_type> ext(subv.block());
  
!       test_assert(ext.CT_Cost         == 0);
!       test_assert(ext.CT_Mem_not_req  == true);
!       test_assert(ext.CT_Xfer_not_req == true);
        
!       test_assert(ext.size(0) == view.size(FreeDim));
  
        T* ptr             = ext.data();
        stride_type stride = ext.stride(0);
  
        for (index_type i=0; i<ext.size(0); ++i)
        {
! 	test_assert(equal(ptr[i*stride], T()));
  	ptr[i*stride] = info_type::value(view, i, j, k);
        }
      }
*************** test_tensor_vector_subview(
*** 976,982 ****
      for (index_type j=0; j<view.size(D1); ++j)
        for (index_type k=0; k<view.size(D2); ++k)
        {
! 	assert(equal(info_type::get(view, i, j, k),
  		     info_type::value(view, i, j, k)));
  	info_type::put(view, i, j, k,
  		       info_type::value(view, i, j, k) + T(1));
--- 976,982 ----
      for (index_type j=0; j<view.size(D1); ++j)
        for (index_type k=0; k<view.size(D2); ++k)
        {
! 	test_assert(equal(info_type::get(view, i, j, k),
  		     info_type::value(view, i, j, k)));
  	info_type::put(view, i, j, k,
  		       info_type::value(view, i, j, k) + T(1));
*************** test_tensor_vector_subview(
*** 991,1008 ****
      {
        impl::Ext_data<subv_block_type> ext(subv.block());
  
!       assert(ext.CT_Cost         == 0);
!       assert(ext.CT_Mem_not_req  == true);
!       assert(ext.CT_Xfer_not_req == true);
        
!       assert(ext.size(0) == view.size(FreeDim));
  
        T* ptr             = ext.data();
        stride_type stride = ext.stride(0);
  
        for (index_type i=0; i<ext.size(0); ++i)
        {
! 	assert(equal(ptr[i*stride],
  		     info_type::value(view, i, j, k) + T(1) ));
        }
      }
--- 991,1008 ----
      {
        impl::Ext_data<subv_block_type> ext(subv.block());
  
!       test_assert(ext.CT_Cost         == 0);
!       test_assert(ext.CT_Mem_not_req  == true);
!       test_assert(ext.CT_Xfer_not_req == true);
        
!       test_assert(ext.size(0) == view.size(FreeDim));
  
        T* ptr             = ext.data();
        stride_type stride = ext.stride(0);
  
        for (index_type i=0; i<ext.size(0); ++i)
        {
! 	test_assert(equal(ptr[i*stride],
  		     info_type::value(view, i, j, k) + T(1) ));
        }
      }
*************** test_tensor_subview(
*** 1026,1033 ****
  
    view = T();
  
!   assert(impl::Ext_data_cost<BlockT>::value == 0);
!   assert(impl::Ext_data_cost<subblock_type>::value == 0);
  
    subview_type subv = view(subdom);
  
--- 1026,1033 ----
  
    view = T();
  
!   test_assert(impl::Ext_data_cost<BlockT>::value == 0);
!   test_assert(impl::Ext_data_cost<subblock_type>::value == 0);
  
    subview_type subv = view(subdom);
  
*************** test_tensor_subview(
*** 1035,1047 ****
      impl::Ext_data<subblock_type> ext(subv.block());
  
      // This should be direct access
!     assert(ext.CT_Cost         == 0);
!     assert(ext.CT_Mem_not_req  == true);
!     assert(ext.CT_Xfer_not_req == true);
! 
!     assert(ext.size(0) == subdom[0].size());
!     assert(ext.size(1) == subdom[1].size());
!     assert(ext.size(2) == subdom[2].size());
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
--- 1035,1047 ----
      impl::Ext_data<subblock_type> ext(subv.block());
  
      // This should be direct access
!     test_assert(ext.CT_Cost         == 0);
!     test_assert(ext.CT_Mem_not_req  == true);
!     test_assert(ext.CT_Xfer_not_req == true);
! 
!     test_assert(ext.size(0) == subdom[0].size());
!     test_assert(ext.size(1) == subdom[1].size());
!     test_assert(ext.size(2) == subdom[2].size());
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
*************** test_tensor_subview(
*** 1052,1058 ****
        for (index_type j=0; j<ext.size(1); ++j)
  	for (index_type k=0; k<ext.size(2); ++k)
  	{
! 	  assert(equal(ptr[i*stride0 + j*stride1 + k*stride2], T()));
  	  ptr[i*stride0 + j*stride1 + k*stride2] =
  	    T(i*ext.size(1)*ext.size(2)+j*ext.size(2)+k);
  	}
--- 1052,1058 ----
        for (index_type j=0; j<ext.size(1); ++j)
  	for (index_type k=0; k<ext.size(2); ++k)
  	{
! 	  test_assert(equal(ptr[i*stride0 + j*stride1 + k*stride2], T()));
  	  ptr[i*stride0 + j*stride1 + k*stride2] =
  	    T(i*ext.size(1)*ext.size(2)+j*ext.size(2)+k);
  	}
*************** test_tensor_subview(
*** 1066,1072 ****
  	index_type nj = subdom[1].impl_nth(j);
  	index_type nk = subdom[2].impl_nth(k);
  
! 	assert(equal(view.get(ni, nj, nk),
  		     T(i*subdom[1].size()*subdom[2].size() +
  		       j*subdom[2].size()+k)));
  	view.put(ni, nj, nk,
--- 1066,1072 ----
  	index_type nj = subdom[1].impl_nth(j);
  	index_type nk = subdom[2].impl_nth(k);
  
! 	test_assert(equal(view.get(ni, nj, nk),
  		     T(i*subdom[1].size()*subdom[2].size() +
  		       j*subdom[2].size()+k)));
  	view.put(ni, nj, nk,
*************** test_tensor_subview(
*** 1079,1091 ****
      impl::Ext_data<subblock_type> ext(subv.block());
  
      // This should be direct access
!     assert(ext.CT_Cost         == 0);
!     assert(ext.CT_Mem_not_req  == true);
!     assert(ext.CT_Xfer_not_req == true);
! 
!     assert(ext.size(0) == subdom[0].size());
!     assert(ext.size(1) == subdom[1].size());
!     assert(ext.size(2) == subdom[2].size());
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
--- 1079,1091 ----
      impl::Ext_data<subblock_type> ext(subv.block());
  
      // This should be direct access
!     test_assert(ext.CT_Cost         == 0);
!     test_assert(ext.CT_Mem_not_req  == true);
!     test_assert(ext.CT_Xfer_not_req == true);
! 
!     test_assert(ext.size(0) == subdom[0].size());
!     test_assert(ext.size(1) == subdom[1].size());
!     test_assert(ext.size(2) == subdom[2].size());
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
*************** test_tensor_subview(
*** 1096,1102 ****
        for (index_type j=0; j<ext.size(1); ++j)
  	for (index_type k=0; k<ext.size(2); ++k)
  	{
! 	  assert(equal(ptr[i*stride0 + j*stride1 + k*stride2],
  		       T(i +
  			 j*ext.size(0) +
  			 k*ext.size(0)*ext.size(1) + 100)));
--- 1096,1102 ----
        for (index_type j=0; j<ext.size(1); ++j)
  	for (index_type k=0; k<ext.size(2); ++k)
  	{
! 	  test_assert(equal(ptr[i*stride0 + j*stride1 + k*stride2],
  		       T(i +
  			 j*ext.size(0) +
  			 k*ext.size(0)*ext.size(1) + 100)));
*************** test_tensor_realimag(
*** 1150,1158 ****
  
    view = complex<T>();
  
!   assert(impl::Ext_data_cost<BlockT>::value == 0);
!   assert(impl::Ext_data_cost<realblock_type>::value == 0);
!   assert(impl::Ext_data_cost<imagblock_type>::value == 0);
  
    realview_type real = view.real();
    imagview_type imag = view.imag();
--- 1150,1158 ----
  
    view = complex<T>();
  
!   test_assert(impl::Ext_data_cost<BlockT>::value == 0);
!   test_assert(impl::Ext_data_cost<realblock_type>::value == 0);
!   test_assert(impl::Ext_data_cost<imagblock_type>::value == 0);
  
    realview_type real = view.real();
    imagview_type imag = view.imag();
*************** test_tensor_realimag(
*** 1162,1174 ****
      impl::Ext_data<realblock_type> ext(real.block());
  
      // This should be direct access
!     assert(ext.CT_Cost         == 0);
!     assert(ext.CT_Mem_not_req  == true);
!     assert(ext.CT_Xfer_not_req == true);
! 
!     assert(ext.size(0) == view.size(0));
!     assert(ext.size(1) == view.size(1));
!     assert(ext.size(2) == view.size(2));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
--- 1162,1174 ----
      impl::Ext_data<realblock_type> ext(real.block());
  
      // This should be direct access
!     test_assert(ext.CT_Cost         == 0);
!     test_assert(ext.CT_Mem_not_req  == true);
!     test_assert(ext.CT_Xfer_not_req == true);
! 
!     test_assert(ext.size(0) == view.size(0));
!     test_assert(ext.size(1) == view.size(1));
!     test_assert(ext.size(2) == view.size(2));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
*************** test_tensor_realimag(
*** 1180,1186 ****
  	for (index_type k=0; k<ext.size(2); ++k)
  	{
  	  index_type idx = (i*view.size(1)*view.size(2)+j*view.size(2)+k);
! 	  assert(equal(ptr[i*stride0 + j*stride1 + k*stride2], T()));
  	  ptr[i*stride0 + j*stride1 + k*stride2] = T(3*idx+1);
  	}
    }
--- 1180,1186 ----
  	for (index_type k=0; k<ext.size(2); ++k)
  	{
  	  index_type idx = (i*view.size(1)*view.size(2)+j*view.size(2)+k);
! 	  test_assert(equal(ptr[i*stride0 + j*stride1 + k*stride2], T()));
  	  ptr[i*stride0 + j*stride1 + k*stride2] = T(3*idx+1);
  	}
    }
*************** test_tensor_realimag(
*** 1190,1202 ****
      impl::Ext_data<imagblock_type> ext(imag.block());
  
      // This should be direct access
!     assert(ext.CT_Cost         == 0);
!     assert(ext.CT_Mem_not_req  == true);
!     assert(ext.CT_Xfer_not_req == true);
! 
!     assert(ext.size(0) == view.size(0));
!     assert(ext.size(1) == view.size(1));
!     assert(ext.size(2) == view.size(2));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
--- 1190,1202 ----
      impl::Ext_data<imagblock_type> ext(imag.block());
  
      // This should be direct access
!     test_assert(ext.CT_Cost         == 0);
!     test_assert(ext.CT_Mem_not_req  == true);
!     test_assert(ext.CT_Xfer_not_req == true);
! 
!     test_assert(ext.size(0) == view.size(0));
!     test_assert(ext.size(1) == view.size(1));
!     test_assert(ext.size(2) == view.size(2));
  
      T* ptr              = ext.data();
      stride_type stride0 = ext.stride(0);
*************** test_tensor_realimag(
*** 1208,1214 ****
  	for (index_type k=0; k<ext.size(2); ++k)
  	{
  	  index_type idx = (i*view.size(1)*view.size(2)+j*view.size(2)+k);
! 	  assert(equal(ptr[i*stride0 + j*stride1 + k*stride2], T()));
  	  ptr[i*stride0 + j*stride1 + k*stride2] = T(4*idx+1);
  	}
    }
--- 1208,1214 ----
  	for (index_type k=0; k<ext.size(2); ++k)
  	{
  	  index_type idx = (i*view.size(1)*view.size(2)+j*view.size(2)+k);
! 	  test_assert(equal(ptr[i*stride0 + j*stride1 + k*stride2], T()));
  	  ptr[i*stride0 + j*stride1 + k*stride2] = T(4*idx+1);
  	}
    }
*************** test_tensor_realimag(
*** 1220,1228 ****
        {
  	index_type idx = (i*view.size(1)*view.size(2)+j*view.size(2)+k);
  
! 	assert(equal(real.get(i, j, k), T(3*idx+1)));
! 	assert(equal(imag.get(i, j, k), T(4*idx+1)));
! 	assert(equal(view.get(i, j, k), complex<T>(3*idx+1, 4*idx+1)));
  
  	view.put(i, j, k, complex<T>(5*idx+1, 7*idx+1));
        }
--- 1220,1228 ----
        {
  	index_type idx = (i*view.size(1)*view.size(2)+j*view.size(2)+k);
  
! 	test_assert(equal(real.get(i, j, k), T(3*idx+1)));
! 	test_assert(equal(imag.get(i, j, k), T(4*idx+1)));
! 	test_assert(equal(view.get(i, j, k), complex<T>(3*idx+1, 4*idx+1)));
  
  	view.put(i, j, k, complex<T>(5*idx+1, 7*idx+1));
        }
*************** test_tensor_realimag(
*** 1247,1254 ****
  	{
  	  index_type idx = (i*view.size(1)*view.size(2)+j*view.size(2)+k);
  
! 	  assert(equal(rptr[i*rstride0+j*rstride1+k*rstride2], T(5*idx+1)));
! 	  assert(equal(iptr[i*istride0+j*istride1+k*istride2], T(7*idx+1)));
  
  	  rptr[i*rstride0+j*rstride1+k*rstride2] = T(3*idx+2);
  	  iptr[i*istride0+j*rstride1+k*istride2] = T(2*idx+1);
--- 1247,1254 ----
  	{
  	  index_type idx = (i*view.size(1)*view.size(2)+j*view.size(2)+k);
  
! 	  test_assert(equal(rptr[i*rstride0+j*rstride1+k*rstride2], T(5*idx+1)));
! 	  test_assert(equal(iptr[i*istride0+j*istride1+k*istride2], T(7*idx+1)));
  
  	  rptr[i*rstride0+j*rstride1+k*rstride2] = T(3*idx+2);
  	  iptr[i*istride0+j*rstride1+k*istride2] = T(2*idx+1);
*************** test_tensor_realimag(
*** 1262,1270 ****
        {
  	index_type idx = (i*view.size(1)*view.size(2)+j*view.size(2)+k);
  
! 	assert(equal(real.get(i, j, k), T(3*idx+2)));
! 	assert(equal(imag.get(i, j, k), T(2*idx+1)));
! 	assert(equal(view.get(i, j, k), complex<T>(3*idx+2, 2*idx+1)));
        }
  }
  
--- 1262,1270 ----
        {
  	index_type idx = (i*view.size(1)*view.size(2)+j*view.size(2)+k);
  
! 	test_assert(equal(real.get(i, j, k), T(3*idx+2)));
! 	test_assert(equal(imag.get(i, j, k), T(2*idx+1)));
! 	test_assert(equal(view.get(i, j, k), complex<T>(3*idx+2, 2*idx+1)));
        }
  }
  
Index: tests/extdata.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/extdata.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 extdata.cpp
*** tests/extdata.cpp	19 Sep 2005 03:39:54 -0000	1.5
--- tests/extdata.cpp	20 Dec 2005 12:39:20 -0000
*************** dotp_view(
*** 226,232 ****
  {
    typedef typename Promotion<T1, T2>::type value_type;
  
!   assert(op1.size() == op2.size());
  
    value_type sum = value_type();
    
--- 226,232 ----
  {
    typedef typename Promotion<T1, T2>::type value_type;
  
!   test_assert(op1.size() == op2.size());
  
    value_type sum = value_type();
    
*************** dotp_ext(
*** 253,259 ****
  {
    typedef typename Promotion<T1, T2>::type value_type;
  
!   assert(op1.size() == op2.size());
  
    impl::Ext_data<Block1> raw1(op1.block());
    T1*      p1   = raw1.data();
--- 253,259 ----
  {
    typedef typename Promotion<T1, T2>::type value_type;
  
!   test_assert(op1.size() == op2.size());
  
    impl::Ext_data<Block1> raw1(op1.block());
    T1*      p1   = raw1.data();
*************** test_block_sum()
*** 297,310 ****
  
    float sum = 1.f + 3.14f + 2.78f;
  
!   assert(equal(sum, raw_sum(block)));
!   assert(equal(sum, ext_sum(block)));
!   assert(equal(sum, blk_sum(block)));
! 
!   assert(equal(sum, gen_ext_sum(block)));
!   assert(equal(sum, gen_blk_sum(block)));
!   assert(equal(sum, gen_ext_sum(pb)));
!   assert(equal(sum, gen_blk_sum(pb)));
  }
  
  
--- 297,310 ----
  
    float sum = 1.f + 3.14f + 2.78f;
  
!   test_assert(equal(sum, raw_sum(block)));
!   test_assert(equal(sum, ext_sum(block)));
!   test_assert(equal(sum, blk_sum(block)));
! 
!   test_assert(equal(sum, gen_ext_sum(block)));
!   test_assert(equal(sum, gen_blk_sum(block)));
!   test_assert(equal(sum, gen_ext_sum(pb)));
!   test_assert(equal(sum, gen_blk_sum(pb)));
  }
  
  
*************** test_1_low()
*** 342,356 ****
  		raw(block);
  
      // Check properties of LLDI.
!     assert(raw.stride(&block, 0) == 1);
!     assert(raw.size(&block, 0) == size);
  
      float* data = raw.data(&block);
      raw.begin(&block, true);
  
      // Check that block values are reflected.
!     assert(equal(data[0], val0));
!     assert(equal(data[1], val1));
  
      // Place values in raw data.
      data[1] = val2;
--- 342,356 ----
  		raw(block);
  
      // Check properties of LLDI.
!     test_assert(raw.stride(&block, 0) == 1);
!     test_assert(raw.size(&block, 0) == size);
  
      float* data = raw.data(&block);
      raw.begin(&block, true);
  
      // Check that block values are reflected.
!     test_assert(equal(data[0], val0));
!     test_assert(equal(data[1], val1));
  
      // Place values in raw data.
      data[1] = val2;
*************** test_1_low()
*** 360,367 ****
    }
  
    // Check that raw data values are reflected.
!   assert(equal(block.get(1), val2));
!   assert(equal(block.get(2), val3));
  }
  
  
--- 360,367 ----
    }
  
    // Check that raw data values are reflected.
!   test_assert(equal(block.get(1), val2));
!   test_assert(equal(block.get(2), val3));
  }
  
  
*************** test_1_ext()
*** 392,405 ****
      impl::Ext_data<Block> raw(block);
  
      // Check properties of DDI.
!     assert(raw.stride(0) == 1);
!     assert(raw.size(0) == size);
  
      float* data = raw.data();
  
      // Check that block values are reflected.
!     assert(equal(data[0], val0));
!     assert(equal(data[1], val1));
  
      // Place values in raw data.
      data[1] = val2;
--- 392,405 ----
      impl::Ext_data<Block> raw(block);
  
      // Check properties of DDI.
!     test_assert(raw.stride(0) == 1);
!     test_assert(raw.size(0) == size);
  
      float* data = raw.data();
  
      // Check that block values are reflected.
!     test_assert(equal(data[0], val0));
!     test_assert(equal(data[1], val1));
  
      // Place values in raw data.
      data[1] = val2;
*************** test_1_ext()
*** 407,414 ****
    }
  
    // Check that raw data values are reflected.
!   assert(equal(block.get(1), val2));
!   assert(equal(block.get(2), val3));
  }
  
  
--- 407,414 ----
    }
  
    // Check that raw data values are reflected.
!   test_assert(equal(block.get(1), val2));
!   test_assert(equal(block.get(2), val3));
  }
  
  
*************** test_dense_2()
*** 430,444 ****
    impl::Ext_data<Row_major_block> row_raw(row_blk);
    impl::Ext_data<Col_major_block> col_raw(col_blk);
  
!   assert(row_raw.stride(0) == static_cast<stride_type>(num_cols));
!   assert(row_raw.stride(1) == 1U);
!   assert(row_raw.size(0) == num_rows);
!   assert(row_raw.size(1) == num_cols);
! 
!   assert(col_raw.stride(0) == 1U);
!   assert(col_raw.stride(1) == static_cast<stride_type>(num_rows));
!   assert(col_raw.size(0) == num_rows);
!   assert(col_raw.size(1) == num_cols);
  }
  
  
--- 430,444 ----
    impl::Ext_data<Row_major_block> row_raw(row_blk);
    impl::Ext_data<Col_major_block> col_raw(col_blk);
  
!   test_assert(row_raw.stride(0) == static_cast<stride_type>(num_cols));
!   test_assert(row_raw.stride(1) == 1U);
!   test_assert(row_raw.size(0) == num_rows);
!   test_assert(row_raw.size(1) == num_cols);
! 
!   test_assert(col_raw.stride(0) == 1U);
!   test_assert(col_raw.stride(1) == static_cast<stride_type>(num_rows));
!   test_assert(col_raw.size(0) == num_rows);
!   test_assert(col_raw.size(1) == num_cols);
  }
  
  
*************** test_dense_12()
*** 474,494 ****
        typename Block::pack_type,
        typename Block::complex_type>, RP> raw(block, SYNC_IN);
  
!     assert(raw.stride(Order::Dim0) == 
  	   static_cast<stride_type>(Order::Dim0 == 0 ? num_cols : num_rows));
!     assert(raw.stride(Order::Dim1) == 1);
  
!     assert(raw.size(0) == num_rows);
!     assert(raw.size(1) == num_cols);
  
      // Cost should be zero:
      //  - Block is Dense, supports Direct_data,
      //  - Requested layout is same as blocks.
!     assert(raw.CT_cost == 0);
  
      for (index_type r=0; r<raw.size(0); ++r)
        for (index_type c=0; c<raw.size(1); ++c)
! 	assert(equal(raw.data()[r*raw.stride(0) + c*raw.stride(1)],
  		     T(r*num_cols + c)));
    }
  
--- 474,494 ----
        typename Block::pack_type,
        typename Block::complex_type>, RP> raw(block, SYNC_IN);
  
!     test_assert(raw.stride(Order::Dim0) == 
  	   static_cast<stride_type>(Order::Dim0 == 0 ? num_cols : num_rows));
!     test_assert(raw.stride(Order::Dim1) == 1);
  
!     test_assert(raw.size(0) == num_rows);
!     test_assert(raw.size(1) == num_cols);
  
      // Cost should be zero:
      //  - Block is Dense, supports Direct_data,
      //  - Requested layout is same as blocks.
!     test_assert(raw.CT_cost == 0);
  
      for (index_type r=0; r<raw.size(0); ++r)
        for (index_type c=0; c<raw.size(1); ++c)
! 	test_assert(equal(raw.data()[r*raw.stride(0) + c*raw.stride(1)],
  		     T(r*num_cols + c)));
    }
  
*************** test_dense_12()
*** 500,513 ****
        typename Block::pack_type,
        typename Block::complex_type>, RP> raw(block, SYNC_IN);
  
!     assert(raw.stride(0) == 1);
  
!     assert(raw.size(0) == num_rows*num_cols);
  
      // Cost should be zero:
      //  - Block is Dense, supports Direct_data,
      //  - Requested 1-dim layout is supported.
!     assert(raw.CT_cost == 0);
  
      for (index_type r=0; r<num_rows; ++r)
      {
--- 500,513 ----
        typename Block::pack_type,
        typename Block::complex_type>, RP> raw(block, SYNC_IN);
  
!     test_assert(raw.stride(0) == 1);
  
!     test_assert(raw.size(0) == num_rows*num_cols);
  
      // Cost should be zero:
      //  - Block is Dense, supports Direct_data,
      //  - Requested 1-dim layout is supported.
!     test_assert(raw.CT_cost == 0);
  
      for (index_type r=0; r<num_rows; ++r)
      {
*************** test_dense_12()
*** 517,523 ****
  	            ? (r * num_cols + c)	// row-major
  	            : (r + c * num_rows);	// col-major
  
! 	assert(equal(raw.data()[idx], T(r*num_cols + c)));
        }
      }
    }
--- 517,523 ----
  	            ? (r * num_cols + c)	// row-major
  	            : (r + c * num_rows);	// col-major
  
! 	test_assert(equal(raw.data()[idx], T(r*num_cols + c)));
        }
      }
    }
*************** test_view_functions()
*** 540,552 ****
      view2.put(i, float(2*i+1));
    }
  
!   assert(equal(sum_view(view1), sum_ext(view1)));
!   assert(equal(sum_view(view2), sum_ext(view2)));
  
    float prod_v = dotp_view(view1, view2);
    float prod_e  = dotp_ext(view1, view2);
  
!   assert(equal(prod_v, prod_e));
  }
  
  
--- 540,552 ----
      view2.put(i, float(2*i+1));
    }
  
!   test_assert(equal(sum_view(view1), sum_ext(view1)));
!   test_assert(equal(sum_view(view2), sum_ext(view2)));
  
    float prod_v = dotp_view(view1, view2);
    float prod_e  = dotp_ext(view1, view2);
  
!   test_assert(equal(prod_v, prod_e));
  }
  
  
*************** test_vector_add()
*** 571,577 ****
  
    for (index_type i=0; i<size; ++i)
    {
!     assert(equal(res.get(i), view1.get(i) + view2.get(i)));
    }
  }
  
--- 571,577 ----
  
    for (index_type i=0; i<size; ++i)
    {
!     test_assert(equal(res.get(i), view1.get(i) + view2.get(i)));
    }
  }
  
Index: tests/fast-block.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fast-block.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 fast-block.cpp
*** tests/fast-block.cpp	5 Aug 2005 15:43:48 -0000	1.5
--- tests/fast-block.cpp	20 Dec 2005 12:39:20 -0000
*************** check_block(Block& blk, int k)
*** 83,89 ****
    Point<Dim> ex = extent_old<Dim>(blk);
    for (Point<Dim> idx; idx != ex; next(ex, idx))
    {
!     assert(equal( get(blk, idx),
  		  identity<value_type>(ex, idx, k)));
    }
  }
--- 83,89 ----
    Point<Dim> ex = extent_old<Dim>(blk);
    for (Point<Dim> idx; idx != ex; next(ex, idx))
    {
!     test_assert(equal( get(blk, idx),
  		  identity<value_type>(ex, idx, k)));
    }
  }
Index: tests/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft.cpp,v
retrieving revision 1.8
diff -c -p -r1.8 fft.cpp
*** tests/fft.cpp	29 Sep 2005 02:01:10 -0000	1.8
--- tests/fft.cpp	20 Dec 2005 12:39:20 -0000
*************** void dft(
*** 76,82 ****
    int                                    idir)
  {
    length_type const size = in.size();
!   assert(in.size() == out.size());
  #if HAVE_SINL
    typedef long double AccT;
  #else
--- 76,82 ----
    int                                    idir)
  {
    length_type const size = in.size();
!   test_assert(in.size() == out.size());
  #if HAVE_SINL
    typedef long double AccT;
  #else
*************** test_by_ref(int set, length_type N)
*** 233,243 ****
    f_fft_type f_fft(Domain<1>(N), 1.0);
    i_fft_type i_fft(Domain<1>(N), 1.0/N);
  
!   assert(f_fft.input_size().size() == N);
!   assert(f_fft.output_size().size() == N);
  
!   assert(i_fft.input_size().size() == N);
!   assert(i_fft.output_size().size() == N);
  
    Vector<T> in(N, T());
    Vector<T> out(N);
--- 233,243 ----
    f_fft_type f_fft(Domain<1>(N), 1.0);
    i_fft_type i_fft(Domain<1>(N), 1.0/N);
  
!   test_assert(f_fft.input_size().size() == N);
!   test_assert(f_fft.output_size().size() == N);
  
!   test_assert(i_fft.input_size().size() == N);
!   test_assert(i_fft.output_size().size() == N);
  
    Vector<T> in(N, T());
    Vector<T> out(N);
*************** test_by_ref(int set, length_type N)
*** 250,263 ****
    f_fft(in, out);
    i_fft(out, inv);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  
    out = in;  f_fft(out);
    inv = out; i_fft(inv);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  }
  
  
--- 250,263 ----
    f_fft(in, out);
    i_fft(out, inv);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  
    out = in;  f_fft(out);
    inv = out; i_fft(inv);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  }
  
  
*************** test_by_val(int set, length_type N)
*** 276,286 ****
    f_fft_type f_fft(Domain<1>(N), 1.0);
    i_fft_type i_fft(Domain<1>(N), 1.0/N);
  
!   assert(f_fft.input_size().size() == N);
!   assert(f_fft.output_size().size() == N);
  
!   assert(i_fft.input_size().size() == N);
!   assert(i_fft.output_size().size() == N);
  
    Vector<T> in(N, T());
    Vector<T> out(N);
--- 276,286 ----
    f_fft_type f_fft(Domain<1>(N), 1.0);
    i_fft_type i_fft(Domain<1>(N), 1.0/N);
  
!   test_assert(f_fft.input_size().size() == N);
!   test_assert(f_fft.output_size().size() == N);
  
!   test_assert(i_fft.input_size().size() == N);
!   test_assert(i_fft.output_size().size() == N);
  
    Vector<T> in(N, T());
    Vector<T> out(N);
*************** test_by_val(int set, length_type N)
*** 293,300 ****
    out = f_fft(in);
    inv = i_fft(out);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  }
  
  
--- 293,300 ----
    out = f_fft(in);
    inv = i_fft(out);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  }
  
  
*************** test_real(const int set, const length_ty
*** 314,329 ****
    f_fft_type f_fft(Domain<1>(N), 1.0);
    i_fft_type i_fft(Domain<1>(N), 1.0/(N));
  
!   assert(f_fft.input_size().size() == N);
!   assert(f_fft.output_size().size() == N2);
  
!   assert(i_fft.input_size().size() == N2);
!   assert(i_fft.output_size().size() == N);
  
!   assert(f_fft.scale() == 1.0);  // can represent exactly
!   assert(i_fft.scale() > 1.0/(N + 1) && i_fft.scale() < 1.0/(N - 1));
!   assert(f_fft.forward() == true);
!   assert(i_fft.forward() == false);
  
    Vector<T> in(N, T());
    Vector<std::complex<T> > out(N2);
--- 314,329 ----
    f_fft_type f_fft(Domain<1>(N), 1.0);
    i_fft_type i_fft(Domain<1>(N), 1.0/(N));
  
!   test_assert(f_fft.input_size().size() == N);
!   test_assert(f_fft.output_size().size() == N2);
  
!   test_assert(i_fft.input_size().size() == N2);
!   test_assert(i_fft.output_size().size() == N);
  
!   test_assert(f_fft.scale() == 1.0);  // can represent exactly
!   test_assert(i_fft.scale() > 1.0/(N + 1) && i_fft.scale() < 1.0/(N - 1));
!   test_assert(f_fft.forward() == true);
!   test_assert(i_fft.forward() == false);
  
    Vector<T> in(N, T());
    Vector<std::complex<T> > out(N2);
*************** test_real(const int set, const length_ty
*** 337,357 ****
    if (set == 1)
    {
      setup_data(3, ref, 3.0);
!     assert(error_db(ref, out) < -100);
    }
    if (set == 3)
    {
      setup_data(1, ref, 3.0 * N);
!     assert(error_db(ref, out) < -100);
    }
  
    ref = out;
    inv = i_fft(out);
  
!   assert(error_db(inv, in) < -100);
  
    // make sure out has not been scribbled in during the conversion.
!   assert(error_db(ref,out) < -100);
  }
  
  /////////////////////////////////////////////////////////////////////
--- 337,357 ----
    if (set == 1)
    {
      setup_data(3, ref, 3.0);
!     test_assert(error_db(ref, out) < -100);
    }
    if (set == 3)
    {
      setup_data(1, ref, 3.0 * N);
!     test_assert(error_db(ref, out) < -100);
    }
  
    ref = out;
    inv = i_fft(out);
  
!   test_assert(error_db(inv, in) < -100);
  
    // make sure out has not been scribbled in during the conversion.
!   test_assert(error_db(ref,out) < -100);
  }
  
  /////////////////////////////////////////////////////////////////////
*************** check_in_place(
*** 751,761 ****
      force_copy_init(in));
  
    fwd(inout);
!   assert(error_db(inout, ref) < -100); 
  
    inv(inout);
    inout *= T(scalei);
!   assert(error_db(inout, in) < -100); 
  }
  
  // when testing matrices, will use latter two values
--- 751,761 ----
      force_copy_init(in));
  
    fwd(inout);
!   test_assert(error_db(inout, ref) < -100); 
  
    inv(inout);
    inout *= T(scalei);
!   test_assert(error_db(inout, in) < -100); 
  }
  
  // when testing matrices, will use latter two values
*************** test_fft()
*** 823,844 ****
      out_type  refN(force_copy_init(ref1));
      refN /= out_elt_type(in_dom.size());
  
!     assert(error_db(in, in_copy) < -200);  // not clobbered
  
      { fwd_by_ref_type  fft_ref1(in_dom, 1.0);
        out_block_type  out_block(out_dom);
        out_type  out(out_block);
        out_type  other = fft_ref1(in, out);
!       assert(&out.block() == &other.block());
!       assert(error_db(in, in_copy) < -200);  // not clobbered
!       assert(error_db(out, ref1) < -100); 
  
        inv_by_ref_type  inv_refN(in_dom, 1.0/in_dom.size());
        in_block_type  in2_block(in_dom);
        in_type  in2(in2_block);
        inv_refN(out, in2);
!       assert(error_db(out, ref1) < -100);  // not clobbered
!       assert(error_db(in2, in) < -100); 
  
        check_in_place(fft_ref1, inv_refN, in, ref1, 1.0);
      }
--- 823,844 ----
      out_type  refN(force_copy_init(ref1));
      refN /= out_elt_type(in_dom.size());
  
!     test_assert(error_db(in, in_copy) < -200);  // not clobbered
  
      { fwd_by_ref_type  fft_ref1(in_dom, 1.0);
        out_block_type  out_block(out_dom);
        out_type  out(out_block);
        out_type  other = fft_ref1(in, out);
!       test_assert(&out.block() == &other.block());
!       test_assert(error_db(in, in_copy) < -200);  // not clobbered
!       test_assert(error_db(out, ref1) < -100); 
  
        inv_by_ref_type  inv_refN(in_dom, 1.0/in_dom.size());
        in_block_type  in2_block(in_dom);
        in_type  in2(in2_block);
        inv_refN(out, in2);
!       test_assert(error_db(out, ref1) < -100);  // not clobbered
!       test_assert(error_db(in2, in) < -100); 
  
        check_in_place(fft_ref1, inv_refN, in, ref1, 1.0);
      }
*************** test_fft()
*** 846,862 ****
        out_block_type  out_block(out_dom);
        out_type  out(out_block);
        out_type  other = fft_ref4(in, out);
!       assert(&out.block() == &other.block());
!       assert(error_db(in, in_copy) < -200);  // not clobbered
!       assert(error_db(out, ref4) < -100); 
  
        inv_by_ref_type  inv_ref8(in_dom, .125);
        in_block_type  in2_block(in_dom);
        in_type  in2(in2_block);
        inv_ref8(out, in2);
!       assert(error_db(out, ref4) < -100);  // not clobbered
        in2 /= in_elt_type(in_dom.size() / 32.0);
!       assert(error_db(in2, in) < -100); 
  
        check_in_place(fft_ref4, inv_ref8, in, ref4, 32.0/in_dom.size());
      }
--- 846,862 ----
        out_block_type  out_block(out_dom);
        out_type  out(out_block);
        out_type  other = fft_ref4(in, out);
!       test_assert(&out.block() == &other.block());
!       test_assert(error_db(in, in_copy) < -200);  // not clobbered
!       test_assert(error_db(out, ref4) < -100); 
  
        inv_by_ref_type  inv_ref8(in_dom, .125);
        in_block_type  in2_block(in_dom);
        in_type  in2(in2_block);
        inv_ref8(out, in2);
!       test_assert(error_db(out, ref4) < -100);  // not clobbered
        in2 /= in_elt_type(in_dom.size() / 32.0);
!       test_assert(error_db(in2, in) < -100); 
  
        check_in_place(fft_ref4, inv_ref8, in, ref4, 32.0/in_dom.size());
      }
*************** test_fft()
*** 864,879 ****
        out_block_type  out_block(out_dom);
        out_type  out(out_block);
        out_type  other = fft_refN(in, out);
!       assert(&out.block() == &other.block());
!       assert(error_db(in, in_copy) < -200);  // not clobbered
!       assert(error_db(out, refN) < -100); 
  
        inv_by_ref_type  inv_ref1(in_dom, 1.0);
        in_block_type  in2_block(in_dom);
        in_type  in2(in2_block);
        inv_ref1(out, in2);
!       assert(error_db(out, refN) < -100);  // not clobbered
!       assert(error_db(in2, in) < -100); 
  
        check_in_place(fft_refN, inv_ref1, in, refN, 1.0);
      }
--- 864,879 ----
        out_block_type  out_block(out_dom);
        out_type  out(out_block);
        out_type  other = fft_refN(in, out);
!       test_assert(&out.block() == &other.block());
!       test_assert(error_db(in, in_copy) < -200);  // not clobbered
!       test_assert(error_db(out, refN) < -100); 
  
        inv_by_ref_type  inv_ref1(in_dom, 1.0);
        in_block_type  in2_block(in_dom);
        in_type  in2(in2_block);
        inv_ref1(out, in2);
!       test_assert(error_db(out, refN) < -100);  // not clobbered
!       test_assert(error_db(in2, in) < -100); 
  
        check_in_place(fft_refN, inv_ref1, in, refN, 1.0);
      }
*************** test_fft()
*** 881,914 ****
  
      { fwd_by_value_type  fwd_val1(in_dom, 1.0);
        out_type  out(fwd_val1(in));
!       assert(error_db(in, in_copy) < -200);  // not clobbered
!       assert(error_db(out, ref1) < -100); 
  
        inv_by_value_type  inv_valN(in_dom, 1.0/in_dom.size());
        in_type  in2(inv_valN(out));
!       assert(error_db(out, ref1) < -100);    // not clobbered
!       assert(error_db(in2, in) < -100); 
      }
      { fwd_by_value_type  fwd_val4(in_dom, 0.25);
        out_type  out(fwd_val4(in));
!       assert(error_db(in, in_copy) < -200);  // not clobbered
!       assert(error_db(out, ref4) < -100); 
  
        inv_by_value_type  inv_val8(in_dom, 0.125);
        in_type  in2(inv_val8(out));
!       assert(error_db(out, ref4) < -100);    // not clobbered
        in2 /= in_elt_type(in_dom.size() / 32.0);
!       assert(error_db(in2, in) < -100); 
      }
      { fwd_by_value_type  fwd_valN(in_dom, 1.0/in_dom.size());
        out_type  out(fwd_valN(in));
!       assert(error_db(in, in_copy) < -200);  // not clobbered
!       assert(error_db(out, refN) < -100); 
  
        inv_by_value_type  inv_val1(in_dom, 1.0);
        in_type  in2(inv_val1(out));
!       assert(error_db(out, refN) < -100);    // not clobbered
!       assert(error_db(in2, in) < -100); 
      }
    }
  };
--- 881,914 ----
  
      { fwd_by_value_type  fwd_val1(in_dom, 1.0);
        out_type  out(fwd_val1(in));
!       test_assert(error_db(in, in_copy) < -200);  // not clobbered
!       test_assert(error_db(out, ref1) < -100); 
  
        inv_by_value_type  inv_valN(in_dom, 1.0/in_dom.size());
        in_type  in2(inv_valN(out));
!       test_assert(error_db(out, ref1) < -100);    // not clobbered
!       test_assert(error_db(in2, in) < -100); 
      }
      { fwd_by_value_type  fwd_val4(in_dom, 0.25);
        out_type  out(fwd_val4(in));
!       test_assert(error_db(in, in_copy) < -200);  // not clobbered
!       test_assert(error_db(out, ref4) < -100); 
  
        inv_by_value_type  inv_val8(in_dom, 0.125);
        in_type  in2(inv_val8(out));
!       test_assert(error_db(out, ref4) < -100);    // not clobbered
        in2 /= in_elt_type(in_dom.size() / 32.0);
!       test_assert(error_db(in2, in) < -100); 
      }
      { fwd_by_value_type  fwd_valN(in_dom, 1.0/in_dom.size());
        out_type  out(fwd_valN(in));
!       test_assert(error_db(in, in_copy) < -200);  // not clobbered
!       test_assert(error_db(out, refN) < -100); 
  
        inv_by_value_type  inv_val1(in_dom, 1.0);
        in_type  in2(inv_val1(out));
!       test_assert(error_db(out, refN) < -100);    // not clobbered
!       test_assert(error_db(in2, in) < -100); 
      }
    }
  };
Index: tests/fftm-par.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fftm-par.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 fftm-par.cpp
*** tests/fftm-par.cpp	28 Sep 2005 04:32:55 -0000	1.4
--- tests/fftm-par.cpp	20 Dec 2005 12:39:20 -0000
*************** void dft_x(
*** 56,63 ****
    vsip::Matrix<vsip::complex<T>, Block2> out)
  {
    length_type const xsize = in.size(1);
!   assert(in.size(0) == out.size(0));
!   assert(in.size(1) == out.size(1));
  
    typedef vsip::complex<T> CT;
  
--- 56,63 ----
    vsip::Matrix<vsip::complex<T>, Block2> out)
  {
    length_type const xsize = in.size(1);
!   test_assert(in.size(0) == out.size(0));
!   test_assert(in.size(1) == out.size(1));
  
    typedef vsip::complex<T> CT;
  
*************** void dft_y(
*** 133,140 ****
  {
    length_type const xsize = in.size(1);
    length_type const ysize = in.size(0);
!   assert(in.size(0) == out.size(0));
!   assert(in.size(1) == out.size(1));
  
    typedef vsip::complex<T> CT;
  
--- 133,140 ----
  {
    length_type const xsize = in.size(1);
    length_type const ysize = in.size(0);
!   test_assert(in.size(0) == out.size(0));
!   test_assert(in.size(1) == out.size(1));
  
    typedef vsip::complex<T> CT;
  
*************** error_db(
*** 249,255 ****
      return maxsum;
    }
  
!   return -200;  // only root can assert failure.
   
  }
  
--- 249,255 ----
      return maxsum;
    }
  
!   return -200;  // only root can test_assert failure.
   
  }
  
*************** template <typename T,
*** 262,268 ****
  void
  setup_data_x(Matrix<T, Block> in, float scale = 1)
  {
!   assert(in.size(0) == 5);
    length_type const N = in.size(1);
  
    Block& block = in.block();
--- 262,268 ----
  void
  setup_data_x(Matrix<T, Block> in, float scale = 1)
  {
!   test_assert(in.size(0) == 5);
    length_type const N = in.size(1);
  
    Block& block = in.block();
*************** test_by_ref_x(length_type N)
*** 329,343 ****
    f_fftm_type f_fftm(domain, 1.0);
    i_fftm_type i_fftm(domain, 1.0/N);
  
!   assert(f_fftm.input_size().size() == 5*N);
!   assert(f_fftm.input_size()[1].size() == N);
!   assert(f_fftm.output_size().size() == 5*N);
!   assert(f_fftm.output_size()[1].size() == N);
! 
!   assert(i_fftm.input_size().size() == 5*N);
!   assert(i_fftm.input_size()[1].size() == N);
!   assert(i_fftm.output_size().size() == 5*N);
!   assert(i_fftm.output_size()[1].size() == N);
  
    typedef Map<Block_dist,Block_dist>  map_type;
    map_type  map(Block_dist(::number_of_processors), Block_dist(1));
--- 329,343 ----
    f_fftm_type f_fftm(domain, 1.0);
    i_fftm_type i_fftm(domain, 1.0/N);
  
!   test_assert(f_fftm.input_size().size() == 5*N);
!   test_assert(f_fftm.input_size()[1].size() == N);
!   test_assert(f_fftm.output_size().size() == 5*N);
!   test_assert(f_fftm.output_size()[1].size() == N);
! 
!   test_assert(i_fftm.input_size().size() == 5*N);
!   test_assert(i_fftm.input_size()[1].size() == N);
!   test_assert(i_fftm.output_size().size() == 5*N);
!   test_assert(i_fftm.output_size()[1].size() == N);
  
    typedef Map<Block_dist,Block_dist>  map_type;
    map_type  map(Block_dist(::number_of_processors), Block_dist(1));
*************** test_by_ref_x(length_type N)
*** 360,375 ****
    f_fftm(in, out);
    i_fftm(out, inv);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  
    out = in;
    f_fftm(out);
    inv = out;
    i_fftm(inv);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  }
  
  
--- 360,375 ----
    f_fftm(in, out);
    i_fftm(out, inv);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  
    out = in;
    f_fftm(out);
    inv = out;
    i_fftm(inv);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  }
  
  
*************** test_by_val_x(length_type N)
*** 390,400 ****
    f_fftm_type f_fftm(domain, 1.0);
    i_fftm_type i_fftm(domain, 1.0/N);
  
!   assert(f_fftm.input_size().size() == 5*N);
!   assert(f_fftm.output_size().size() == 5*N);
  
!   assert(i_fftm.input_size().size() == 5*N);
!   assert(i_fftm.output_size().size() == 5*N);
  
    typedef Map<Block_dist,Block_dist>  map_type;
    map_type  map(Block_dist(::number_of_processors), Block_dist(1));
--- 390,400 ----
    f_fftm_type f_fftm(domain, 1.0);
    i_fftm_type i_fftm(domain, 1.0/N);
  
!   test_assert(f_fftm.input_size().size() == 5*N);
!   test_assert(f_fftm.output_size().size() == 5*N);
  
!   test_assert(i_fftm.input_size().size() == 5*N);
!   test_assert(i_fftm.output_size().size() == 5*N);
  
    typedef Map<Block_dist,Block_dist>  map_type;
    map_type  map(Block_dist(::number_of_processors), Block_dist(1));
*************** test_by_val_x(length_type N)
*** 417,424 ****
    out = f_fftm(in);
    inv = i_fftm(out);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  }
  
  
--- 417,424 ----
    out = f_fftm(in);
    inv = i_fftm(out);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  }
  
  
*************** template <typename T,
*** 430,436 ****
  void
  setup_data_y(Matrix<T, Block> in, float scale = 1)
  {
!   assert(in.size(1) == 5);
    length_type const N = in.size(0);
  
  #if 0
--- 430,436 ----
  void
  setup_data_y(Matrix<T, Block> in, float scale = 1)
  {
!   test_assert(in.size(1) == 5);
    length_type const N = in.size(0);
  
  #if 0
*************** test_by_ref_y(length_type N)
*** 542,552 ****
    f_fftm_type  f_fftm(domain, 1.0);
    i_fftm_type  i_fftm(domain, 1.0/N);
  
!   assert(f_fftm.input_size().size() == 5*N);
!   assert(f_fftm.output_size().size() == 5*N);
  
!   assert(i_fftm.input_size().size() == 5*N);
!   assert(i_fftm.output_size().size() == 5*N);
  
    typedef Map<Block_dist,Block_dist>  map_type;
    map_type  map(Block_dist(1), Block_dist(::number_of_processors));
--- 542,552 ----
    f_fftm_type  f_fftm(domain, 1.0);
    i_fftm_type  i_fftm(domain, 1.0/N);
  
!   test_assert(f_fftm.input_size().size() == 5*N);
!   test_assert(f_fftm.output_size().size() == 5*N);
  
!   test_assert(i_fftm.input_size().size() == 5*N);
!   test_assert(i_fftm.output_size().size() == 5*N);
  
    typedef Map<Block_dist,Block_dist>  map_type;
    map_type  map(Block_dist(1), Block_dist(::number_of_processors));
*************** test_by_ref_y(length_type N)
*** 590,603 ****
    dump_matrix(inv.block(), N, 1);
  #endif
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  
    out = in;  f_fftm(out);
    inv = out; i_fftm(inv);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  }
  
  
--- 590,603 ----
    dump_matrix(inv.block(), N, 1);
  #endif
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  
    out = in;  f_fftm(out);
    inv = out; i_fftm(inv);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  }
  
  
*************** test_by_val_y(length_type N)
*** 618,628 ****
    f_fftm_type  f_fftm(domain, 1.0);
    i_fftm_type  i_fftm(domain, 1.0/N);
  
!   assert(f_fftm.input_size().size() == 5*N);
!   assert(f_fftm.output_size().size() == 5*N);
  
!   assert(i_fftm.input_size().size() == 5*N);
!   assert(i_fftm.output_size().size() == 5*N);
  
    typedef Map<Block_dist,Block_dist>  map_type;
    map_type  map(Block_dist(1), Block_dist(::number_of_processors));
--- 618,628 ----
    f_fftm_type  f_fftm(domain, 1.0);
    i_fftm_type  i_fftm(domain, 1.0/N);
  
!   test_assert(f_fftm.input_size().size() == 5*N);
!   test_assert(f_fftm.output_size().size() == 5*N);
  
!   test_assert(i_fftm.input_size().size() == 5*N);
!   test_assert(i_fftm.output_size().size() == 5*N);
  
    typedef Map<Block_dist,Block_dist>  map_type;
    map_type  map(Block_dist(1), Block_dist(::number_of_processors));
*************** test_by_val_y(length_type N)
*** 645,652 ****
    out = f_fftm(in);
    inv = i_fftm(out);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  }
  
  
--- 645,652 ----
    out = f_fftm(in);
    inv = i_fftm(out);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  }
  
  
*************** test_real(const int set, const length_ty
*** 667,682 ****
    f_fftm_type f_fftm(Domain<1>(N), 1.0);
    i_fftm_type i_fftm(Domain<1>(N), 1.0/(N));
  
!   assert(f_fftm.input_size().size() == N);
!   assert(f_fftm.output_size().size() == N2);
  
!   assert(i_fftm.input_size().size() == N2);
!   assert(i_fftm.output_size().size() == N);
  
!   assert(f_fftm.scale() == 1.0);  // can represent exactly
!   assert(i_fftm.scale() > 1.0/(N + 1) && i_fftm.scale() < 1.0/(N - 1));
!   assert(f_fftm.forward() == true);
!   assert(i_fftm.forward() == false);
  
    Matrix<T> in(N, T());
    Matrix<std::complex<T> > out(N2);
--- 667,682 ----
    f_fftm_type f_fftm(Domain<1>(N), 1.0);
    i_fftm_type i_fftm(Domain<1>(N), 1.0/(N));
  
!   test_assert(f_fftm.input_size().size() == N);
!   test_assert(f_fftm.output_size().size() == N2);
  
!   test_assert(i_fftm.input_size().size() == N2);
!   test_assert(i_fftm.output_size().size() == N);
  
!   test_assert(f_fftm.scale() == 1.0);  // can represent exactly
!   test_assert(i_fftm.scale() > 1.0/(N + 1) && i_fftm.scale() < 1.0/(N - 1));
!   test_assert(f_fftm.forward() == true);
!   test_assert(i_fftm.forward() == false);
  
    Matrix<T> in(N, T());
    Matrix<std::complex<T> > out(N2);
*************** test_real(const int set, const length_ty
*** 690,710 ****
    if (set == 1)
    {
      setup_data(3, ref, 3.0);
!     assert(error_db(ref, out) < -100);
    }
    if (set == 3)
    {
      setup_data(1, ref, 3.0 * N);
!     assert(error_db(ref, out) < -100);
    }
  
    ref = out;
    inv = i_fftm(out);
  
!   assert(error_db(inv, in) < -100);
  
    // make sure out has not been scribbled in during the conversion.
!   assert(error_db(ref,out) < -100);
  }
  
  #endif
--- 690,710 ----
    if (set == 1)
    {
      setup_data(3, ref, 3.0);
!     test_assert(error_db(ref, out) < -100);
    }
    if (set == 3)
    {
      setup_data(1, ref, 3.0 * N);
!     test_assert(error_db(ref, out) < -100);
    }
  
    ref = out;
    inv = i_fftm(out);
  
!   test_assert(error_db(inv, in) < -100);
  
    // make sure out has not been scribbled in during the conversion.
!   test_assert(error_db(ref,out) < -100);
  }
  
  #endif
Index: tests/fftm.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fftm.cpp,v
retrieving revision 1.8
diff -c -p -r1.8 fftm.cpp
*** tests/fftm.cpp	29 Sep 2005 02:01:10 -0000	1.8
--- tests/fftm.cpp	20 Dec 2005 12:39:20 -0000
*************** void dft_x(
*** 63,70 ****
  {
    length_type const xsize = in.size(1);
    length_type const ysize = in.size(0);
!   assert(in.size(0) == out.size(0));
!   assert(in.size(1) == out.size(1));
    typedef long double AccT;
  
    AccT const phi = idir * 2.0 * M_PI/xsize;
--- 63,70 ----
  {
    length_type const xsize = in.size(1);
    length_type const ysize = in.size(0);
!   test_assert(in.size(0) == out.size(0));
!   test_assert(in.size(1) == out.size(1));
    typedef long double AccT;
  
    AccT const phi = idir * 2.0 * M_PI/xsize;
*************** void dft_y(
*** 90,97 ****
  {
    length_type const xsize = in.size(1);
    length_type const ysize = in.size(0);
!   assert(in.size(0) == out.size(0));
!   assert(in.size(1) == out.size(1));
    typedef long double AccT;
  
    AccT const phi = idir * 2.0 * M_PI/ysize;
--- 90,97 ----
  {
    length_type const xsize = in.size(1);
    length_type const ysize = in.size(0);
!   test_assert(in.size(0) == out.size(0));
!   test_assert(in.size(1) == out.size(1));
    typedef long double AccT;
  
    AccT const phi = idir * 2.0 * M_PI/ysize;
*************** void dft_y_real(
*** 116,123 ****
  {
    length_type const xsize = in.size(1);
    length_type const ysize = in.size(0);
!   assert(in.size(0)/2 + 1 == out.size(0));
!   assert(in.size(1) == out.size(1));
    typedef long double AccT;
  
    AccT const phi = -2.0 * M_PI/ysize;
--- 116,123 ----
  {
    length_type const xsize = in.size(1);
    length_type const ysize = in.size(0);
!   test_assert(in.size(0)/2 + 1 == out.size(0));
!   test_assert(in.size(1) == out.size(1));
    typedef long double AccT;
  
    AccT const phi = -2.0 * M_PI/ysize;
*************** template <typename T,
*** 182,188 ****
  void
  setup_data_x(Matrix<T, Block> in, float scale = 1)
  {
!   assert(in.size(0) == 5);
    length_type const N = in.size(1);
  
    in.row(0)    = T();
--- 182,188 ----
  void
  setup_data_x(Matrix<T, Block> in, float scale = 1)
  {
!   test_assert(in.size(0) == 5);
    length_type const N = in.size(1);
  
    in.row(0)    = T();
*************** test_by_ref_x(length_type N)
*** 223,237 ****
    f_fftm_type f_fftm(Domain<2>(Domain<1>(5),Domain<1>(N)), 1.0);
    i_fftm_type i_fftm(Domain<2>(Domain<1>(5),Domain<1>(N)), 1.0/N);
  
!   assert(f_fftm.input_size().size() == 5*N);
!   assert(f_fftm.input_size()[1].size() == N);
!   assert(f_fftm.output_size().size() == 5*N);
!   assert(f_fftm.output_size()[1].size() == N);
! 
!   assert(i_fftm.input_size().size() == 5*N);
!   assert(i_fftm.input_size()[1].size() == N);
!   assert(i_fftm.output_size().size() == 5*N);
!   assert(i_fftm.output_size()[1].size() == N);
  
    Matrix<T> in(5, N, T());
    Matrix<T> out(5, N, T());
--- 223,237 ----
    f_fftm_type f_fftm(Domain<2>(Domain<1>(5),Domain<1>(N)), 1.0);
    i_fftm_type i_fftm(Domain<2>(Domain<1>(5),Domain<1>(N)), 1.0/N);
  
!   test_assert(f_fftm.input_size().size() == 5*N);
!   test_assert(f_fftm.input_size()[1].size() == N);
!   test_assert(f_fftm.output_size().size() == 5*N);
!   test_assert(f_fftm.output_size()[1].size() == N);
! 
!   test_assert(i_fftm.input_size().size() == 5*N);
!   test_assert(i_fftm.input_size()[1].size() == N);
!   test_assert(i_fftm.output_size().size() == 5*N);
!   test_assert(i_fftm.output_size()[1].size() == N);
  
    Matrix<T> in(5, N, T());
    Matrix<T> out(5, N, T());
*************** test_by_ref_x(length_type N)
*** 255,268 ****
  
    i_fftm(out, inv);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  
    out = in;  f_fftm(out);
    inv = out; i_fftm(inv);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  }
  
  
--- 255,268 ----
  
    i_fftm(out, inv);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  
    out = in;  f_fftm(out);
    inv = out; i_fftm(inv);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  }
  
  
*************** test_by_val_x(length_type N)
*** 281,291 ****
    f_fftm_type f_fftm(Domain<2>(Domain<1>(5),Domain<1>(N)), 1.0);
    i_fftm_type i_fftm(Domain<2>(Domain<1>(5),Domain<1>(N)), 1.0/N);
  
!   assert(f_fftm.input_size().size() == 5*N);
!   assert(f_fftm.output_size().size() == 5*N);
  
!   assert(i_fftm.input_size().size() == 5*N);
!   assert(i_fftm.output_size().size() == 5*N);
  
    Matrix<T> in(5, N, T());
    Matrix<T> out(5, N);
--- 281,291 ----
    f_fftm_type f_fftm(Domain<2>(Domain<1>(5),Domain<1>(N)), 1.0);
    i_fftm_type i_fftm(Domain<2>(Domain<1>(5),Domain<1>(N)), 1.0/N);
  
!   test_assert(f_fftm.input_size().size() == 5*N);
!   test_assert(f_fftm.output_size().size() == 5*N);
  
!   test_assert(i_fftm.input_size().size() == 5*N);
!   test_assert(i_fftm.output_size().size() == 5*N);
  
    Matrix<T> in(5, N, T());
    Matrix<T> out(5, N);
*************** test_by_val_x(length_type N)
*** 298,305 ****
    out = f_fftm(in);
    inv = i_fftm(out);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  }
  
  
--- 298,305 ----
    out = f_fftm(in);
    inv = i_fftm(out);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  }
  
  
*************** template <typename T,
*** 311,317 ****
  void
  setup_data_y(Matrix<T, Block> in, float scale = 1)
  {
!   assert(in.size(1) == 5);
    length_type const N = in.size(0);
  
    in.col(0)    = T();
--- 311,317 ----
  void
  setup_data_y(Matrix<T, Block> in, float scale = 1)
  {
!   test_assert(in.size(1) == 5);
    length_type const N = in.size(0);
  
    in.col(0)    = T();
*************** test_by_ref_y(length_type N)
*** 351,361 ****
    f_fftm_type f_fftm(Domain<2>(Domain<1>(N),Domain<1>(5)), 1.0);
    i_fftm_type i_fftm(Domain<2>(Domain<1>(N),Domain<1>(5)), 1.0/N);
  
!   assert(f_fftm.input_size().size() == 5*N);
!   assert(f_fftm.output_size().size() == 5*N);
  
!   assert(i_fftm.input_size().size() == 5*N);
!   assert(i_fftm.output_size().size() == 5*N);
  
    Matrix<T> in(N, 5, T());
    Matrix<T> out(N, 5);
--- 351,361 ----
    f_fftm_type f_fftm(Domain<2>(Domain<1>(N),Domain<1>(5)), 1.0);
    i_fftm_type i_fftm(Domain<2>(Domain<1>(N),Domain<1>(5)), 1.0/N);
  
!   test_assert(f_fftm.input_size().size() == 5*N);
!   test_assert(f_fftm.output_size().size() == 5*N);
  
!   test_assert(i_fftm.input_size().size() == 5*N);
!   test_assert(i_fftm.output_size().size() == 5*N);
  
    Matrix<T> in(N, 5, T());
    Matrix<T> out(N, 5);
*************** test_by_ref_y(length_type N)
*** 391,404 ****
    f_fftm(in, out);
    i_fftm(out, inv);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  
    out = in;  f_fftm(out);
    inv = out; i_fftm(inv);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  }
  
  
--- 391,404 ----
    f_fftm(in, out);
    i_fftm(out, inv);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  
    out = in;  f_fftm(out);
    inv = out; i_fftm(inv);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  }
  
  
*************** test_by_val_y(length_type N)
*** 417,427 ****
    f_fftm_type f_fftm(Domain<2>(Domain<1>(N),Domain<1>(5)), 1.0);
    i_fftm_type i_fftm(Domain<2>(Domain<1>(N),Domain<1>(5)), 1.0/N);
  
!   assert(f_fftm.input_size().size() == 5*N);
!   assert(f_fftm.output_size().size() == 5*N);
  
!   assert(i_fftm.input_size().size() == 5*N);
!   assert(i_fftm.output_size().size() == 5*N);
  
    Matrix<T> in(N, 5, T());
    Matrix<T> out(N, 5);
--- 417,427 ----
    f_fftm_type f_fftm(Domain<2>(Domain<1>(N),Domain<1>(5)), 1.0);
    i_fftm_type i_fftm(Domain<2>(Domain<1>(N),Domain<1>(5)), 1.0/N);
  
!   test_assert(f_fftm.input_size().size() == 5*N);
!   test_assert(f_fftm.output_size().size() == 5*N);
  
!   test_assert(i_fftm.input_size().size() == 5*N);
!   test_assert(i_fftm.output_size().size() == 5*N);
  
    Matrix<T> in(N, 5, T());
    Matrix<T> out(N, 5);
*************** test_by_val_y(length_type N)
*** 433,440 ****
    out = f_fftm(in);
    inv = i_fftm(out);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  }
  
  
--- 433,440 ----
    out = f_fftm(in);
    inv = i_fftm(out);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  }
  
  
*************** test_real(const length_type N)
*** 454,469 ****
    f_fftm_type f_fftm(Domain<2>(Domain<1>(N),Domain<1>(5)), 1.0);
    i_fftm_type i_fftm(Domain<2>(Domain<1>(N),Domain<1>(5)), 1.0/N);
  
!   assert(f_fftm.input_size().size() == 5*N);
!   assert(f_fftm.output_size().size() == 5*N2);
  
!   assert(i_fftm.input_size().size() == 5*N2);
!   assert(i_fftm.output_size().size() == 5*N);
  
!   assert(f_fftm.scale() == 1.0);  // can represent exactly
!   assert(i_fftm.scale() > 1.0/(N + 1) && i_fftm.scale() < 1.0/(N - 1));
!   assert(f_fftm.forward() == true);
!   assert(i_fftm.forward() == false);
  
    Matrix<T> in(N, 5, T());
    Matrix<std::complex<T> > out(N2, 5);
--- 454,469 ----
    f_fftm_type f_fftm(Domain<2>(Domain<1>(N),Domain<1>(5)), 1.0);
    i_fftm_type i_fftm(Domain<2>(Domain<1>(N),Domain<1>(5)), 1.0/N);
  
!   test_assert(f_fftm.input_size().size() == 5*N);
!   test_assert(f_fftm.output_size().size() == 5*N2);
  
!   test_assert(i_fftm.input_size().size() == 5*N2);
!   test_assert(i_fftm.output_size().size() == 5*N);
  
!   test_assert(f_fftm.scale() == 1.0);  // can represent exactly
!   test_assert(i_fftm.scale() > 1.0/(N + 1) && i_fftm.scale() < 1.0/(N - 1));
!   test_assert(f_fftm.forward() == true);
!   test_assert(i_fftm.forward() == false);
  
    Matrix<T> in(N, 5, T());
    Matrix<std::complex<T> > out(N2, 5);
*************** test_real(const length_type N)
*** 475,482 ****
    out = f_fftm(in);
    inv = i_fftm(out);
  
!   assert(error_db(ref, out) < -100);
!   assert(error_db(inv, in) < -100);
  }
  
  
--- 475,482 ----
    out = f_fftm(in);
    inv = i_fftm(out);
  
!   test_assert(error_db(ref, out) < -100);
!   test_assert(error_db(inv, in) < -100);
  }
  
  
Index: tests/fir.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fir.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 fir.cpp
*** tests/fir.cpp	24 Oct 2005 13:25:30 -0000	1.4
--- tests/fir.cpp	20 Dec 2005 12:39:20 -0000
*************** test_fir(
*** 94,124 ****
  
    vsip::Fir<>  dummy(
      vsip::const_Vector<>(vsip::length_type(3),vsip::scalar_f(1)), N*10);
!   assert(dummy.decimation() == 1);
    vsip::Fir<T,sym,vsip::state_save,1>  fir1a(kernel, N, D);
    vsip::Fir<T,sym,vsip::state_save,1>  fir1b(fir1a);
    vsip::Fir<T,sym,vsip::state_no_save,1>  fir2(kernel, N, D);
  
!   assert(fir1a.symmetry == sym);
!   assert(fir2.symmetry == sym);
!   assert(fir1a.continuous_filter == vsip::state_save);
!   assert(fir2.continuous_filter == vsip::state_no_save);
   
    const vsip::length_type  order = (sym == vsip::nonsym) ? M :
      (sym == vsip::sym_even_len_even) ? 2 * M : (2 * M) - 1;
!   assert(fir1a.kernel_size() == order);
!   assert(fir1b.kernel_size() == order);
!   assert(fir1a.filter_order() == order);
!   assert(fir1b.filter_order() == order);
!   // assert(fir1a.symmetry()
!   assert(fir1a.input_size() == N);
!   assert(fir1b.input_size() == N);
!   assert(fir1a.output_size() == (N+D-1)/D);
!   assert(fir1b.output_size() == (N+D-1)/D);
!   assert(fir1a.continuous_filtering() == fir1a.continuous_filter);
!   assert(fir2.continuous_filtering() == fir2.continuous_filter);
!   assert(fir1a.decimation() == D);
!   assert(fir1b.decimation() == D);
  
    vsip::length_type got = 0;
    for (vsip::length_type i = 0; i < 2 * M; ++i) // chained
--- 94,124 ----
  
    vsip::Fir<>  dummy(
      vsip::const_Vector<>(vsip::length_type(3),vsip::scalar_f(1)), N*10);
!   test_assert(dummy.decimation() == 1);
    vsip::Fir<T,sym,vsip::state_save,1>  fir1a(kernel, N, D);
    vsip::Fir<T,sym,vsip::state_save,1>  fir1b(fir1a);
    vsip::Fir<T,sym,vsip::state_no_save,1>  fir2(kernel, N, D);
  
!   test_assert(fir1a.symmetry == sym);
!   test_assert(fir2.symmetry == sym);
!   test_assert(fir1a.continuous_filter == vsip::state_save);
!   test_assert(fir2.continuous_filter == vsip::state_no_save);
   
    const vsip::length_type  order = (sym == vsip::nonsym) ? M :
      (sym == vsip::sym_even_len_even) ? 2 * M : (2 * M) - 1;
!   test_assert(fir1a.kernel_size() == order);
!   test_assert(fir1b.kernel_size() == order);
!   test_assert(fir1a.filter_order() == order);
!   test_assert(fir1b.filter_order() == order);
!   // test_assert(fir1a.symmetry()
!   test_assert(fir1a.input_size() == N);
!   test_assert(fir1b.input_size() == N);
!   test_assert(fir1a.output_size() == (N+D-1)/D);
!   test_assert(fir1b.output_size() == (N+D-1)/D);
!   test_assert(fir1a.continuous_filtering() == fir1a.continuous_filter);
!   test_assert(fir2.continuous_filtering() == fir2.continuous_filter);
!   test_assert(fir1a.decimation() == D);
!   test_assert(fir1b.decimation() == D);
  
    vsip::length_type got = 0;
    for (vsip::length_type i = 0; i < 2 * M; ++i) // chained
*************** test_fir(
*** 145,168 ****
    vsip::Vector<T>  reference(convout(vsip::Domain<1>(got)));
    vsip::Vector<T>  result(output1(vsip::Domain<1>(got)));
  
!   assert(outsize - got <= 1);
    if (got > 256)
    {
      double error = error_db(result, reference);
!     assert(error < -100);
    }
    else
!     assert(view_equal(result, reference));
  
!   assert(got1b == got2);
    if (got > 256)
    {
      double error = error_db(output2(vsip::Domain<1>(got1b)),
                              output3(vsip::Domain<1>(got1b)));
!     assert(error < -100);
    }
    else
!     assert(view_equal(output2(vsip::Domain<1>(got1b)),
                        output3(vsip::Domain<1>(got1b))));
  }
    
--- 145,168 ----
    vsip::Vector<T>  reference(convout(vsip::Domain<1>(got)));
    vsip::Vector<T>  result(output1(vsip::Domain<1>(got)));
  
!   test_assert(outsize - got <= 1);
    if (got > 256)
    {
      double error = error_db(result, reference);
!     test_assert(error < -100);
    }
    else
!     test_assert(view_equal(result, reference));
  
!   test_assert(got1b == got2);
    if (got > 256)
    {
      double error = error_db(output2(vsip::Domain<1>(got1b)),
                              output3(vsip::Domain<1>(got1b)));
!     test_assert(error < -100);
    }
    else
!     test_assert(view_equal(output2(vsip::Domain<1>(got1b)),
                        output3(vsip::Domain<1>(got1b))));
  }
    
Index: tests/fns_scalar.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fns_scalar.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 fns_scalar.cpp
*** tests/fns_scalar.cpp	16 Sep 2005 18:57:29 -0000	1.3
--- tests/fns_scalar.cpp	20 Dec 2005 12:39:20 -0000
*************** test_magsq()
*** 45,51 ****
  
    Z.view = vsip::magsq(A.view);
  
!   assert(equal(get_nth(Z.view, 0), T1(3*3)));
  }
  
  
--- 45,51 ----
  
    Z.view = vsip::magsq(A.view);
  
!   test_assert(equal(get_nth(Z.view, 0), T1(3*3)));
  }
  
  
*************** test_mag()
*** 63,69 ****
  
    Z.view = vsip::mag(A.view);
  
!   assert(equal(get_nth(Z.view, 0), T1(3)));
  }
  
  
--- 63,69 ----
  
    Z.view = vsip::mag(A.view);
  
!   test_assert(equal(get_nth(Z.view, 0), T1(3)));
  }
  
  
*************** test_maxmgsq()
*** 84,90 ****
  
    Z.view = vsip::maxmgsq(A.view, B.view);
  
!   assert(equal(get_nth(Z.view, 0), T1(4*4)));
  }
  
  
--- 84,90 ----
  
    Z.view = vsip::maxmgsq(A.view, B.view);
  
!   test_assert(equal(get_nth(Z.view, 0), T1(4*4)));
  }
  
  
*************** test_minmgsq()
*** 105,111 ****
  
    Z.view = vsip::minmgsq(A.view, B.view);
  
!   assert(equal(get_nth(Z.view, 0), T1(3*3)));
  }
  
  
--- 105,111 ----
  
    Z.view = vsip::minmgsq(A.view, B.view);
  
!   test_assert(equal(get_nth(Z.view, 0), T1(3*3)));
  }
  
  
*************** test_arg()
*** 125,131 ****
  
    Z.view = vsip::arg(A.view);
  
!   assert(equal(get_nth(Z.view, 0), std::arg(input)));
  }
  
  
--- 125,131 ----
  
    Z.view = vsip::arg(A.view);
  
!   test_assert(equal(get_nth(Z.view, 0), std::arg(input)));
  }
  
  
Index: tests/fns_userelt.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fns_userelt.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 fns_userelt.cpp
*** tests/fns_userelt.cpp	2 Aug 2005 09:53:32 -0000	1.1
--- tests/fns_userelt.cpp	20 Dec 2005 12:39:20 -0000
*************** void unary_funptr()
*** 57,83 ****
  {
    DVector input(3, 1.5);
    DVector result = unary(my_unary, input);
!   assert(result.get(0) == my_unary(input(0)));
!   assert(result.get(1) == my_unary(input(1)));
!   assert(result.get(2) == my_unary(input(2)));
  }
  
  void unary_stdfunc()
  {
    DVector input(3, 1.5);
    DVector result = unary<int>(std::ptr_fun(my_unary), input);
!   assert(result.get(0) == my_unary(input(0)));
!   assert(result.get(1) == my_unary(input(1)));
!   assert(result.get(2) == my_unary(input(2)));
  }
  
  void unary_func()
  {
    DVector input(3, 1.5);
    DVector result = unary<int>(my_func_obj(), input);
!   assert(result.get(0) == my_unary(input(0)));
!   assert(result.get(1) == my_unary(input(1)));
!   assert(result.get(2) == my_unary(input(2)));
  }
  
  /***********************************************************************
--- 57,83 ----
  {
    DVector input(3, 1.5);
    DVector result = unary(my_unary, input);
!   test_assert(result.get(0) == my_unary(input(0)));
!   test_assert(result.get(1) == my_unary(input(1)));
!   test_assert(result.get(2) == my_unary(input(2)));
  }
  
  void unary_stdfunc()
  {
    DVector input(3, 1.5);
    DVector result = unary<int>(std::ptr_fun(my_unary), input);
!   test_assert(result.get(0) == my_unary(input(0)));
!   test_assert(result.get(1) == my_unary(input(1)));
!   test_assert(result.get(2) == my_unary(input(2)));
  }
  
  void unary_func()
  {
    DVector input(3, 1.5);
    DVector result = unary<int>(my_func_obj(), input);
!   test_assert(result.get(0) == my_unary(input(0)));
!   test_assert(result.get(1) == my_unary(input(1)));
!   test_assert(result.get(2) == my_unary(input(2)));
  }
  
  /***********************************************************************
*************** void binary_funptr()
*** 89,97 ****
    DVector input1(3, 1.5);
    DVector input2(3, .6);
    DVector result = binary(my_binary, input1, input2);
!   assert(result.get(0) == my_binary(input1(0), input2(0)));
!   assert(result.get(1) == my_binary(input1(1), input2(1)));
!   assert(result.get(2) == my_binary(input1(2), input2(2)));
  }
  
  void binary_stdfunc()
--- 89,97 ----
    DVector input1(3, 1.5);
    DVector input2(3, .6);
    DVector result = binary(my_binary, input1, input2);
!   test_assert(result.get(0) == my_binary(input1(0), input2(0)));
!   test_assert(result.get(1) == my_binary(input1(1), input2(1)));
!   test_assert(result.get(2) == my_binary(input1(2), input2(2)));
  }
  
  void binary_stdfunc()
*************** void binary_stdfunc()
*** 99,107 ****
    DVector input1(3, 1.5);
    DVector input2(3, .6);
    DVector result = binary<int>(std::ptr_fun(my_binary), input1, input2);
!   assert(result.get(0) == my_binary(input1(0), input2(0)));
!   assert(result.get(1) == my_binary(input1(1), input2(1)));
!   assert(result.get(2) == my_binary(input1(2), input2(2)));
  }
  
  void binary_func()
--- 99,107 ----
    DVector input1(3, 1.5);
    DVector input2(3, .6);
    DVector result = binary<int>(std::ptr_fun(my_binary), input1, input2);
!   test_assert(result.get(0) == my_binary(input1(0), input2(0)));
!   test_assert(result.get(1) == my_binary(input1(1), input2(1)));
!   test_assert(result.get(2) == my_binary(input1(2), input2(2)));
  }
  
  void binary_func()
*************** void binary_func()
*** 109,117 ****
    DVector input1(3, 1.5);
    DVector input2(3, .6);
    DVector result = binary<int>(my_func_obj(), input1, input2);
!   assert(result.get(0) == my_binary(input1(0), input2(0)));
!   assert(result.get(1) == my_binary(input1(1), input2(1)));
!   assert(result.get(2) == my_binary(input1(2), input2(2)));
  }
  
  /***********************************************************************
--- 109,117 ----
    DVector input1(3, 1.5);
    DVector input2(3, .6);
    DVector result = binary<int>(my_func_obj(), input1, input2);
!   test_assert(result.get(0) == my_binary(input1(0), input2(0)));
!   test_assert(result.get(1) == my_binary(input1(1), input2(1)));
!   test_assert(result.get(2) == my_binary(input1(2), input2(2)));
  }
  
  /***********************************************************************
*************** void ternary_funptr()
*** 124,132 ****
    DVector input2(3, .6);
    DVector input3(3, .9);
    DVector result = ternary(my_ternary, input1, input2, input3);
!   assert(result.get(0) == my_ternary(input1(0), input2(0), input3(0)));
!   assert(result.get(1) == my_ternary(input1(1), input2(1), input3(1)));
!   assert(result.get(2) == my_ternary(input1(2), input2(2), input3(2)));
  }
  
  void ternary_func()
--- 124,132 ----
    DVector input2(3, .6);
    DVector input3(3, .9);
    DVector result = ternary(my_ternary, input1, input2, input3);
!   test_assert(result.get(0) == my_ternary(input1(0), input2(0), input3(0)));
!   test_assert(result.get(1) == my_ternary(input1(1), input2(1), input3(1)));
!   test_assert(result.get(2) == my_ternary(input1(2), input2(2), input3(2)));
  }
  
  void ternary_func()
*************** void ternary_func()
*** 135,143 ****
    DVector input2(3, .6);
    DVector input3(3, .9);
    DVector result = ternary<int>(my_func_obj(), input1, input2, input3);
!   assert(result.get(0) == my_ternary(input1(0), input2(0), input3(0)));
!   assert(result.get(1) == my_ternary(input1(1), input2(1), input3(1)));
!   assert(result.get(2) == my_ternary(input1(2), input2(2), input3(2)));
  }
  
  int main(int, char **)
--- 135,143 ----
    DVector input2(3, .6);
    DVector input3(3, .9);
    DVector result = ternary<int>(my_func_obj(), input1, input2, input3);
!   test_assert(result.get(0) == my_ternary(input1(0), input2(0), input3(0)));
!   test_assert(result.get(1) == my_ternary(input1(1), input2(1), input3(1)));
!   test_assert(result.get(2) == my_ternary(input1(2), input2(2), input3(2)));
  }
  
  int main(int, char **)
Index: tests/freqswap.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/freqswap.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 freqswap.cpp
*** tests/freqswap.cpp	5 Dec 2005 21:12:39 -0000	1.1
--- tests/freqswap.cpp	20 Dec 2005 12:39:20 -0000
*************** test_vector_freqswap( length_type m )
*** 36,42 ****
    b = vsip::freqswap(a);
  
    for ( index_type i = 0; i < m; i++ )
!     assert(equal( b.get(i), a.get(((m+1)/2 + i) % m ) ));
  }
  
  
--- 36,42 ----
    b = vsip::freqswap(a);
  
    for ( index_type i = 0; i < m; i++ )
!     test_assert(equal( b.get(i), a.get(((m+1)/2 + i) % m ) ));
  }
  
  
*************** test_matrix_freqswap( length_type m, len
*** 54,60 ****
  
    for ( index_type i = 0; i < m; i++ )
      for ( index_type j = 0; j < n; j++ )
!       assert(equal( b.get(i, j),
                 a.get(((m+1)/2 + i) % m, ((n+1)/2 + j) % n ) ));
  }
  
--- 54,60 ----
  
    for ( index_type i = 0; i < m; i++ )
      for ( index_type j = 0; j < n; j++ )
!       test_assert(equal( b.get(i, j),
                 a.get(((m+1)/2 + i) % m, ((n+1)/2 + j) % n ) ));
  }
  
Index: tests/histogram.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/histogram.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 histogram.cpp
*** tests/histogram.cpp	6 Dec 2005 00:58:40 -0000	1.1
--- tests/histogram.cpp	20 Dec 2005 12:39:20 -0000
*************** test_vector_histogram( length_type size 
*** 47,53 ****
        for ( index_type i = 0; i < size; ++i )
          if ( (T(b * 2) <= v(i)) && (v(i) < T((b + 1) * 2)) )
            ++count;
!       assert( q(b) == count );
      }
    }
  
--- 47,53 ----
        for ( index_type i = 0; i < size; ++i )
          if ( (T(b * 2) <= v(i)) && (v(i) < T((b + 1) * 2)) )
            ++count;
!       test_assert( q(b) == count );
      }
    }
  
*************** test_vector_histogram( length_type size 
*** 64,82 ****
        for ( index_type i = 0; i < size; ++i )
          if ( (T(b) <= v(i)) && (v(i) < T(b + 1)) )
            ++count;
!       assert( q(b+1) == count );
      }
!     assert( q(0) == 0 );
!     assert( q(9) == 0 );
  
      // verify it can accumulate results
      Vector<scalar_i> q2(10);
      q2 = h(v, true);
  
      for ( index_type b = 0; b < 8; ++b )
!       assert( q2(b+1) == 2 * q(b+1) );
!     assert( q2(0) == 0 );
!     assert( q2(9) == 0 );
    }
  }
  
--- 64,82 ----
        for ( index_type i = 0; i < size; ++i )
          if ( (T(b) <= v(i)) && (v(i) < T(b + 1)) )
            ++count;
!       test_assert( q(b+1) == count );
      }
!     test_assert( q(0) == 0 );
!     test_assert( q(9) == 0 );
  
      // verify it can accumulate results
      Vector<scalar_i> q2(10);
      q2 = h(v, true);
  
      for ( index_type b = 0; b < 8; ++b )
!       test_assert( q2(b+1) == 2 * q(b+1) );
!     test_assert( q2(0) == 0 );
!     test_assert( q2(9) == 0 );
    }
  }
  
*************** test_matrix_histogram( length_type rows,
*** 108,114 ****
          for ( index_type j = 0; j < cols; ++j )
            if ( (T(b * 2) <= m(i, j)) && (m(i, j) < T((b + 1) * 2)) )
              ++count;
!       assert( q(b) == count );
      }
    }
  
--- 108,114 ----
          for ( index_type j = 0; j < cols; ++j )
            if ( (T(b * 2) <= m(i, j)) && (m(i, j) < T((b + 1) * 2)) )
              ++count;
!       test_assert( q(b) == count );
      }
    }
  
*************** test_matrix_histogram( length_type rows,
*** 126,144 ****
          for ( index_type j = 0; j < cols; ++j )
            if ( (T(b) <= m(i, j)) && (m(i, j) < T(b + 1)) )
              ++count;
!       assert( q(b+1) == count );
      }
!     assert( q(0) == 0 );
!     assert( q(9) == 0 );
  
      // verify it can accumulate results
      Vector<scalar_i> q2(10);
      q2 = h(m, true);
  
      for ( index_type b = 0; b < 8; ++b )
!       assert( q2(b+1) == 2 * q(b+1) );
!     assert( q2(0) == 0 );
!     assert( q2(9) == 0 );
    }
  }
  
--- 126,144 ----
          for ( index_type j = 0; j < cols; ++j )
            if ( (T(b) <= m(i, j)) && (m(i, j) < T(b + 1)) )
              ++count;
!       test_assert( q(b+1) == count );
      }
!     test_assert( q(0) == 0 );
!     test_assert( q(9) == 0 );
  
      // verify it can accumulate results
      Vector<scalar_i> q2(10);
      q2 = h(m, true);
  
      for ( index_type b = 0; b < 8; ++b )
!       test_assert( q2(b+1) == 2 * q(b+1) );
!     test_assert( q2(0) == 0 );
!     test_assert( q2(9) == 0 );
    }
  }
  
Index: tests/iir.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/iir.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 iir.cpp
*** tests/iir.cpp	20 Dec 2005 03:01:32 -0000	1.1
--- tests/iir.cpp	20 Dec 2005 12:39:20 -0000
***************
*** 10,18 ****
    Included Files
  ***********************************************************************/
  
- 
- #include <cassert>
- 
  #include <vsip/vector.hpp>
  #include <vsip/signal.hpp>
  #include <vsip/initfin.hpp>
--- 10,15 ----
*************** single_iir_as_fir_case(
*** 45,57 ****
    length_type      chunk,
    Vector<T, Block> weights)
  {
!   Matrix<T> b(1, 3);
!   Matrix<T> a(1, 2);
  
!   assert(weights.size() == 3);	// IIR is only 2nd order
  
!   assert(chunk <= size);
!   assert(size % chunk == 0);
  
    b.row(0) = weights;
  
--- 42,56 ----
    length_type      chunk,
    Vector<T, Block> weights)
  {
!   length_type order = 1;
! 
!   Matrix<T> b(order, 3);
!   Matrix<T> a(order, 2);
  
!   test_assert(weights.size() == 3);	// IIR is only 2nd order
  
!   test_assert(chunk <= size);
!   test_assert(size % chunk == 0);
  
    b.row(0) = weights;
  
*************** single_iir_as_fir_case(
*** 60,65 ****
--- 59,70 ----
  
    Iir<T, State> iir(b, a, chunk);
  
+   test_assert(iir.kernel_size()  == 2*order);
+   test_assert(iir.filter_order() == 2*order);
+   test_assert(iir.input_size()   == chunk);
+   test_assert(iir.output_size()  == chunk);
+   test_assert(iir.continuous_filtering == State);
+ 
    Fir<T, nonsym, State> fir(weights, chunk, 1);
  
    Vector<T> data(size);
*************** single_iir_as_fir_case(
*** 86,92 ****
    }
  #endif
  
!   assert(error < -150);
  }
  
  
--- 91,97 ----
    }
  #endif
  
!   test_assert(error < -150);
  }
  
  
*************** iir_as_fir_case(
*** 100,116 ****
    length_type      chunk,
    Matrix<T, Block> b)
  {
!   Matrix<T> a(b.size(0), 2, T());
  
!   assert(b.size(1) == 3);	// IIR is only 2nd order
  
!   assert(chunk <= size);
!   assert(size % chunk == 0);
  
!   length_type order = b.size(0);
  
    Iir<T, State> iir(b, a, chunk);
  
    Fir<T, nonsym, State>** fir;
  
    fir = new Fir<T, nonsym, State>*[order];
--- 105,127 ----
    length_type      chunk,
    Matrix<T, Block> b)
  {
!   length_type order = b.size(0);
  
!   Matrix<T> a(order, 2, T());
  
!   test_assert(b.size(1) == 3);	// IIR is only 2nd order
  
!   test_assert(chunk <= size);
!   test_assert(size % chunk == 0);
  
    Iir<T, State> iir(b, a, chunk);
  
+   test_assert(iir.kernel_size()  == 2*order);
+   test_assert(iir.filter_order() == 2*order);
+   test_assert(iir.input_size()   == chunk);
+   test_assert(iir.output_size()  == chunk);
+   test_assert(iir.continuous_filtering == State);
+ 
    Fir<T, nonsym, State>** fir;
  
    fir = new Fir<T, nonsym, State>*[order];
*************** iir_as_fir_case(
*** 151,157 ****
    }
  #endif
  
!   assert(error < -150);
  
    for (length_type m=0; m<order; ++m)
      delete fir[m];
--- 162,168 ----
    }
  #endif
  
!   test_assert(error < -150);
  
    for (length_type m=0; m<order; ++m)
      delete fir[m];
*************** sum_case(
*** 209,221 ****
    length_type      size,
    length_type      chunk)
  {
!   assert(chunk <= size);
!   assert(size % chunk == 0);
  
!   Matrix<T> b(1, 3);
!   Matrix<T> a(1, 2);
!   Matrix<T> b3(1, 3, T());
!   Matrix<T> a3(1, 2, T());
  
    b(0, 0) = T(1);
    b(0, 1) = T(0);
--- 220,234 ----
    length_type      size,
    length_type      chunk)
  {
!   test_assert(chunk <= size);
!   test_assert(size % chunk == 0);
  
!   length_type order = 1;
! 
!   Matrix<T> b(order, 3);
!   Matrix<T> a(order, 2);
!   Matrix<T> b3(order, 3, T());
!   Matrix<T> a3(order, 2, T());
  
    b(0, 0) = T(1);
    b(0, 1) = T(0);
*************** sum_case(
*** 228,233 ****
--- 241,264 ----
    Iir<T, state_save> iir2 = iir1;
    Iir<T, state_save> iir3(b3, a3, chunk); // [1]
  
+   test_assert(iir1.kernel_size()  == 2*order);
+   test_assert(iir1.filter_order() == 2*order);
+   test_assert(iir1.input_size()   == chunk);
+   test_assert(iir1.output_size()  == chunk);
+   test_assert(iir1.continuous_filtering == state_save);
+ 
+   test_assert(iir2.kernel_size()  == 2*order);
+   test_assert(iir2.filter_order() == 2*order);
+   test_assert(iir2.input_size()   == chunk);
+   test_assert(iir2.output_size()  == chunk);
+   test_assert(iir2.continuous_filtering == state_save);
+ 
+   test_assert(iir3.kernel_size()  == 2*order);
+   test_assert(iir3.filter_order() == 2*order);
+   test_assert(iir3.input_size()   == chunk);
+   test_assert(iir3.output_size()  == chunk);
+   test_assert(iir3.continuous_filtering == state_save);
+ 
    Vector<T> data(size);
    Vector<T> out1(size);
    Vector<T> out2(size);
*************** sum_case(
*** 246,251 ****
--- 277,287 ----
      {
        out3(Domain<1>(pos, 1, chunk)) = out2(Domain<1>(pos, 1, chunk));
        iir3 = iir1; // [2]
+       test_assert(iir3.kernel_size()  == 2*order);
+       test_assert(iir3.filter_order() == 2*order);
+       test_assert(iir3.input_size()   == chunk);
+       test_assert(iir3.output_size()  == chunk);
+       test_assert(iir3.continuous_filtering == state_save);
      }
      else
        iir3(data(Domain<1>(pos, 1, chunk)), out3(Domain<1>(pos, 1, chunk)));
*************** sum_case(
*** 276,284 ****
    }
  #endif
  
!   assert(error1 < -150);
!   assert(error2 < -150);
!   assert(error3 < -150);
  }
  
  
--- 312,320 ----
    }
  #endif
  
!   test_assert(error1 < -150);
!   test_assert(error2 < -150);
!   test_assert(error3 < -150);
  }
  
  
Index: tests/index.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/index.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 index.cpp
*** tests/index.cpp	8 Aug 2005 09:14:59 -0000	1.2
--- tests/index.cpp	20 Dec 2005 12:39:20 -0000
***************
*** 17,22 ****
--- 17,24 ----
  #include <cassert>
  #include <vsip/domain.hpp>
  
+ #include "test.hpp"
+ 
  using namespace std;
  using namespace vsip;
  
*************** void
*** 29,42 ****
  test_index_1()
  {
    Index<1> a;
!   assert(a[0] == 0);
    Index<1> b(1);
    a = b;
!   assert(a == b);
    Index<1> c(2);
!   assert(b != c);
    Index<1> d(c);
!   assert(d == c);
  }
  
  /// Test Index<1> interface conformance.
--- 31,44 ----
  test_index_1()
  {
    Index<1> a;
!   test_assert(a[0] == 0);
    Index<1> b(1);
    a = b;
!   test_assert(a == b);
    Index<1> c(2);
!   test_assert(b != c);
    Index<1> d(c);
!   test_assert(d == c);
  }
  
  /// Test Index<1> interface conformance.
*************** void
*** 44,58 ****
  test_index_2()
  {
    Index<2> a;
!   assert(a[0] == 0 && a[1] == 0);
    Index<2> b(0, 1);
!   assert(b[0] == 0 && b[1] == 1);
    a = b;
!   assert(a == b);
    Index<2> c(2, 2);
!   assert(b != c);
    Index<2> d(c);
!   assert(d == c);
  }
  
  /// Test Index<1> interface conformance.
--- 46,60 ----
  test_index_2()
  {
    Index<2> a;
!   test_assert(a[0] == 0 && a[1] == 0);
    Index<2> b(0, 1);
!   test_assert(b[0] == 0 && b[1] == 1);
    a = b;
!   test_assert(a == b);
    Index<2> c(2, 2);
!   test_assert(b != c);
    Index<2> d(c);
!   test_assert(d == c);
  }
  
  /// Test Index<1> interface conformance.
*************** void
*** 60,74 ****
  test_index_3()
  {
    Index<3> a;
!   assert(a[0] == 0 && a[1] == 0 && a[2] == 0);
    Index<3> b(0, 1, 2);
!   assert(b[0] == 0 && b[1] == 1 && b[2] == 2);
    a = b;
!   assert(a == b);
    Index<3> c(2, 2, 2);
!   assert(b != c);
    Index<3> d(c);
!   assert(d == c);
  }
  
  int
--- 62,76 ----
  test_index_3()
  {
    Index<3> a;
!   test_assert(a[0] == 0 && a[1] == 0 && a[2] == 0);
    Index<3> b(0, 1, 2);
!   test_assert(b[0] == 0 && b[1] == 1 && b[2] == 2);
    a = b;
!   test_assert(a == b);
    Index<3> c(2, 2, 2);
!   test_assert(b != c);
    Index<3> d(c);
!   test_assert(d == c);
  }
  
  int
Index: tests/initfini.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/initfini.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 initfini.cpp
*** tests/initfini.cpp	19 Sep 2005 03:39:54 -0000	1.5
--- tests/initfini.cpp	20 Dec 2005 12:39:20 -0000
***************
*** 16,21 ****
--- 16,23 ----
  #include <iostream>
  #include <vsip/initfin.hpp>
  
+ #include "test.hpp"
+ 
  using namespace std;
  using namespace vsip;
  
*************** main (int argc, char** argv)
*** 113,118 ****
      test_cmdline_options ();
      break;
    default:
!     assert(0);
    }
  }
--- 115,120 ----
      test_cmdline_options ();
      break;
    default:
!     test_assert(0);
    }
  }
Index: tests/lvalue-proxy.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/lvalue-proxy.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 lvalue-proxy.cpp
*** tests/lvalue-proxy.cpp	13 Sep 2005 16:49:28 -0000	1.3
--- tests/lvalue-proxy.cpp	20 Dec 2005 12:39:20 -0000
***************
*** 13,19 ****
  #include <vsip/impl/static_assert.hpp>
  #include <vsip/impl/metaprogramming.hpp>
  #include <vsip/dense.hpp>
- #include <cassert>
  
  using namespace vsip;
  
--- 13,18 ----
*************** test_1d (void)
*** 22,63 ****
  {
    Dense<1> d(Domain<1>(3), 42);
    impl::Lvalue_proxy<Dense<1> > p(d, 1);
!   assert (p == 42);
  
    p = 4;
!   assert (d.get(0) == 42);
!   assert (d.get(1) ==  4);
!   assert (d.get(2) == 42);
  
    p += 3;
!   assert (d.get(0) == 42);
!   assert (d.get(1) ==  7);
!   assert (d.get(2) == 42);
  
    p -= 5;
!   assert (d.get(0) == 42);
!   assert (d.get(1) ==  2);
!   assert (d.get(2) == 42);
  
    p *= 3;
!   assert (d.get(0) == 42);
!   assert (d.get(1) ==  6);
!   assert (d.get(2) == 42);
  
    p /= 2;
!   assert (d.get(0) == 42);
!   assert (d.get(1) ==  3);
!   assert (d.get(2) == 42);
  
    (p = 12) = 10;
!   assert (d.get(0) == 42);
!   assert (d.get(1) == 10);
!   assert (d.get(2) == 42);
  
    p = impl::Lvalue_proxy<Dense<1> >(d, 0);
!   assert (d.get(0) == 42);
!   assert (d.get(1) == 42);
!   assert (d.get(2) == 42);
  }
  
  static void
--- 21,62 ----
  {
    Dense<1> d(Domain<1>(3), 42);
    impl::Lvalue_proxy<Dense<1> > p(d, 1);
!   test_assert (p == 42);
  
    p = 4;
!   test_assert (d.get(0) == 42);
!   test_assert (d.get(1) ==  4);
!   test_assert (d.get(2) == 42);
  
    p += 3;
!   test_assert (d.get(0) == 42);
!   test_assert (d.get(1) ==  7);
!   test_assert (d.get(2) == 42);
  
    p -= 5;
!   test_assert (d.get(0) == 42);
!   test_assert (d.get(1) ==  2);
!   test_assert (d.get(2) == 42);
  
    p *= 3;
!   test_assert (d.get(0) == 42);
!   test_assert (d.get(1) ==  6);
!   test_assert (d.get(2) == 42);
  
    p /= 2;
!   test_assert (d.get(0) == 42);
!   test_assert (d.get(1) ==  3);
!   test_assert (d.get(2) == 42);
  
    (p = 12) = 10;
!   test_assert (d.get(0) == 42);
!   test_assert (d.get(1) == 10);
!   test_assert (d.get(2) == 42);
  
    p = impl::Lvalue_proxy<Dense<1> >(d, 0);
!   test_assert (d.get(0) == 42);
!   test_assert (d.get(1) == 42);
!   test_assert (d.get(2) == 42);
  }
  
  static void
*************** test_2d (void)
*** 65,106 ****
  {
    Dense<2> d(Domain<2>(3, 3), 42);
    impl::Lvalue_proxy<Dense<2> > p(d, 0, 1);
!   assert (p == 42);
  
    p = 4;
!   assert(d.get(0,0) == 42); assert(d.get(0,1) ==  4); assert(d.get(0,2) == 42);
!   assert(d.get(1,0) == 42); assert(d.get(1,1) == 42); assert(d.get(1,2) == 42);
!   assert(d.get(2,0) == 42); assert(d.get(2,1) == 42); assert(d.get(2,2) == 42);
  
    p += 3;
!   assert(d.get(0,0) == 42); assert(d.get(0,1) ==  7); assert(d.get(0,2) == 42);
!   assert(d.get(1,0) == 42); assert(d.get(1,1) == 42); assert(d.get(1,2) == 42);
!   assert(d.get(2,0) == 42); assert(d.get(2,1) == 42); assert(d.get(2,2) == 42);
  
    p -= 5;
!   assert(d.get(0,0) == 42); assert(d.get(0,1) ==  2); assert(d.get(0,2) == 42);
!   assert(d.get(1,0) == 42); assert(d.get(1,1) == 42); assert(d.get(1,2) == 42);
!   assert(d.get(2,0) == 42); assert(d.get(2,1) == 42); assert(d.get(2,2) == 42);
  
    p *= 3;
!   assert(d.get(0,0) == 42); assert(d.get(0,1) ==  6); assert(d.get(0,2) == 42);
!   assert(d.get(1,0) == 42); assert(d.get(1,1) == 42); assert(d.get(1,2) == 42);
!   assert(d.get(2,0) == 42); assert(d.get(2,1) == 42); assert(d.get(2,2) == 42);
  
    p /= 2;
!   assert(d.get(0,0) == 42); assert(d.get(0,1) ==  3); assert(d.get(0,2) == 42);
!   assert(d.get(1,0) == 42); assert(d.get(1,1) == 42); assert(d.get(1,2) == 42);
!   assert(d.get(2,0) == 42); assert(d.get(2,1) == 42); assert(d.get(2,2) == 42);
  
    (p = 12) = 10;
!   assert(d.get(0,0) == 42); assert(d.get(0,1) == 10); assert(d.get(0,2) == 42);
!   assert(d.get(1,0) == 42); assert(d.get(1,1) == 42); assert(d.get(1,2) == 42);
!   assert(d.get(2,0) == 42); assert(d.get(2,1) == 42); assert(d.get(2,2) == 42);
  
    p = impl::Lvalue_proxy<Dense<2> >(d, 0, 0);
!   assert(d.get(0,0) == 42); assert(d.get(0,1) == 42); assert(d.get(0,2) == 42);
!   assert(d.get(1,0) == 42); assert(d.get(1,1) == 42); assert(d.get(1,2) == 42);
!   assert(d.get(2,0) == 42); assert(d.get(2,1) == 42); assert(d.get(2,2) == 42);
  }
  
  static void
--- 64,105 ----
  {
    Dense<2> d(Domain<2>(3, 3), 42);
    impl::Lvalue_proxy<Dense<2> > p(d, 0, 1);
!   test_assert (p == 42);
  
    p = 4;
!   test_assert(d.get(0,0) == 42); test_assert(d.get(0,1) ==  4); test_assert(d.get(0,2) == 42);
!   test_assert(d.get(1,0) == 42); test_assert(d.get(1,1) == 42); test_assert(d.get(1,2) == 42);
!   test_assert(d.get(2,0) == 42); test_assert(d.get(2,1) == 42); test_assert(d.get(2,2) == 42);
  
    p += 3;
!   test_assert(d.get(0,0) == 42); test_assert(d.get(0,1) ==  7); test_assert(d.get(0,2) == 42);
!   test_assert(d.get(1,0) == 42); test_assert(d.get(1,1) == 42); test_assert(d.get(1,2) == 42);
!   test_assert(d.get(2,0) == 42); test_assert(d.get(2,1) == 42); test_assert(d.get(2,2) == 42);
  
    p -= 5;
!   test_assert(d.get(0,0) == 42); test_assert(d.get(0,1) ==  2); test_assert(d.get(0,2) == 42);
!   test_assert(d.get(1,0) == 42); test_assert(d.get(1,1) == 42); test_assert(d.get(1,2) == 42);
!   test_assert(d.get(2,0) == 42); test_assert(d.get(2,1) == 42); test_assert(d.get(2,2) == 42);
  
    p *= 3;
!   test_assert(d.get(0,0) == 42); test_assert(d.get(0,1) ==  6); test_assert(d.get(0,2) == 42);
!   test_assert(d.get(1,0) == 42); test_assert(d.get(1,1) == 42); test_assert(d.get(1,2) == 42);
!   test_assert(d.get(2,0) == 42); test_assert(d.get(2,1) == 42); test_assert(d.get(2,2) == 42);
  
    p /= 2;
!   test_assert(d.get(0,0) == 42); test_assert(d.get(0,1) ==  3); test_assert(d.get(0,2) == 42);
!   test_assert(d.get(1,0) == 42); test_assert(d.get(1,1) == 42); test_assert(d.get(1,2) == 42);
!   test_assert(d.get(2,0) == 42); test_assert(d.get(2,1) == 42); test_assert(d.get(2,2) == 42);
  
    (p = 12) = 10;
!   test_assert(d.get(0,0) == 42); test_assert(d.get(0,1) == 10); test_assert(d.get(0,2) == 42);
!   test_assert(d.get(1,0) == 42); test_assert(d.get(1,1) == 42); test_assert(d.get(1,2) == 42);
!   test_assert(d.get(2,0) == 42); test_assert(d.get(2,1) == 42); test_assert(d.get(2,2) == 42);
  
    p = impl::Lvalue_proxy<Dense<2> >(d, 0, 0);
!   test_assert(d.get(0,0) == 42); test_assert(d.get(0,1) == 42); test_assert(d.get(0,2) == 42);
!   test_assert(d.get(1,0) == 42); test_assert(d.get(1,1) == 42); test_assert(d.get(1,2) == 42);
!   test_assert(d.get(2,0) == 42); test_assert(d.get(2,1) == 42); test_assert(d.get(2,2) == 42);
  }
  
  static void
*************** test_3d (void)
*** 108,191 ****
  {
    Dense<3> d(Domain<3>(3, 3, 3), 42);
    impl::Lvalue_proxy<Dense<3> > p(d, 0, 1, 2);
!   assert (p == 42);
  
    p = 4;
!   assert(d.get(0,0,0)==42); assert(d.get(0,0,1)==42); assert(d.get(0,0,2)==42);
!   assert(d.get(0,1,0)==42); assert(d.get(0,1,1)==42); assert(d.get(0,1,2)== 4);
!   assert(d.get(0,2,0)==42); assert(d.get(0,2,1)==42); assert(d.get(0,2,2)==42);
!   assert(d.get(1,0,0)==42); assert(d.get(1,0,1)==42); assert(d.get(1,0,2)==42);
!   assert(d.get(1,1,0)==42); assert(d.get(1,1,1)==42); assert(d.get(1,1,2)==42);
!   assert(d.get(1,2,0)==42); assert(d.get(1,2,1)==42); assert(d.get(1,2,2)==42);
!   assert(d.get(2,0,0)==42); assert(d.get(2,0,1)==42); assert(d.get(2,0,2)==42);
!   assert(d.get(2,1,0)==42); assert(d.get(2,1,1)==42); assert(d.get(2,1,2)==42);
!   assert(d.get(2,2,0)==42); assert(d.get(2,2,1)==42); assert(d.get(2,2,2)==42);
  
    p += 3;
!   assert(d.get(0,0,0)==42); assert(d.get(0,0,1)==42); assert(d.get(0,0,2)==42);
!   assert(d.get(0,1,0)==42); assert(d.get(0,1,1)==42); assert(d.get(0,1,2)== 7);
!   assert(d.get(0,2,0)==42); assert(d.get(0,2,1)==42); assert(d.get(0,2,2)==42);
!   assert(d.get(1,0,0)==42); assert(d.get(1,0,1)==42); assert(d.get(1,0,2)==42);
!   assert(d.get(1,1,0)==42); assert(d.get(1,1,1)==42); assert(d.get(1,1,2)==42);
!   assert(d.get(1,2,0)==42); assert(d.get(1,2,1)==42); assert(d.get(1,2,2)==42);
!   assert(d.get(2,0,0)==42); assert(d.get(2,0,1)==42); assert(d.get(2,0,2)==42);
!   assert(d.get(2,1,0)==42); assert(d.get(2,1,1)==42); assert(d.get(2,1,2)==42);
!   assert(d.get(2,2,0)==42); assert(d.get(2,2,1)==42); assert(d.get(2,2,2)==42);
  
    p -= 5;
!   assert(d.get(0,0,0)==42); assert(d.get(0,0,1)==42); assert(d.get(0,0,2)==42);
!   assert(d.get(0,1,0)==42); assert(d.get(0,1,1)==42); assert(d.get(0,1,2)== 2);
!   assert(d.get(0,2,0)==42); assert(d.get(0,2,1)==42); assert(d.get(0,2,2)==42);
!   assert(d.get(1,0,0)==42); assert(d.get(1,0,1)==42); assert(d.get(1,0,2)==42);
!   assert(d.get(1,1,0)==42); assert(d.get(1,1,1)==42); assert(d.get(1,1,2)==42);
!   assert(d.get(1,2,0)==42); assert(d.get(1,2,1)==42); assert(d.get(1,2,2)==42);
!   assert(d.get(2,0,0)==42); assert(d.get(2,0,1)==42); assert(d.get(2,0,2)==42);
!   assert(d.get(2,1,0)==42); assert(d.get(2,1,1)==42); assert(d.get(2,1,2)==42);
!   assert(d.get(2,2,0)==42); assert(d.get(2,2,1)==42); assert(d.get(2,2,2)==42);
  
    p *= 3;
!   assert(d.get(0,0,0)==42); assert(d.get(0,0,1)==42); assert(d.get(0,0,2)==42);
!   assert(d.get(0,1,0)==42); assert(d.get(0,1,1)==42); assert(d.get(0,1,2)== 6);
!   assert(d.get(0,2,0)==42); assert(d.get(0,2,1)==42); assert(d.get(0,2,2)==42);
!   assert(d.get(1,0,0)==42); assert(d.get(1,0,1)==42); assert(d.get(1,0,2)==42);
!   assert(d.get(1,1,0)==42); assert(d.get(1,1,1)==42); assert(d.get(1,1,2)==42);
!   assert(d.get(1,2,0)==42); assert(d.get(1,2,1)==42); assert(d.get(1,2,2)==42);
!   assert(d.get(2,0,0)==42); assert(d.get(2,0,1)==42); assert(d.get(2,0,2)==42);
!   assert(d.get(2,1,0)==42); assert(d.get(2,1,1)==42); assert(d.get(2,1,2)==42);
!   assert(d.get(2,2,0)==42); assert(d.get(2,2,1)==42); assert(d.get(2,2,2)==42);
  
    p /= 2;
!   assert(d.get(0,0,0)==42); assert(d.get(0,0,1)==42); assert(d.get(0,0,2)==42);
!   assert(d.get(0,1,0)==42); assert(d.get(0,1,1)==42); assert(d.get(0,1,2)== 3);
!   assert(d.get(0,2,0)==42); assert(d.get(0,2,1)==42); assert(d.get(0,2,2)==42);
!   assert(d.get(1,0,0)==42); assert(d.get(1,0,1)==42); assert(d.get(1,0,2)==42);
!   assert(d.get(1,1,0)==42); assert(d.get(1,1,1)==42); assert(d.get(1,1,2)==42);
!   assert(d.get(1,2,0)==42); assert(d.get(1,2,1)==42); assert(d.get(1,2,2)==42);
!   assert(d.get(2,0,0)==42); assert(d.get(2,0,1)==42); assert(d.get(2,0,2)==42);
!   assert(d.get(2,1,0)==42); assert(d.get(2,1,1)==42); assert(d.get(2,1,2)==42);
!   assert(d.get(2,2,0)==42); assert(d.get(2,2,1)==42); assert(d.get(2,2,2)==42);
  
    (p = 12) = 10;
!   assert(d.get(0,0,0)==42); assert(d.get(0,0,1)==42); assert(d.get(0,0,2)==42);
!   assert(d.get(0,1,0)==42); assert(d.get(0,1,1)==42); assert(d.get(0,1,2)==10);
!   assert(d.get(0,2,0)==42); assert(d.get(0,2,1)==42); assert(d.get(0,2,2)==42);
!   assert(d.get(1,0,0)==42); assert(d.get(1,0,1)==42); assert(d.get(1,0,2)==42);
!   assert(d.get(1,1,0)==42); assert(d.get(1,1,1)==42); assert(d.get(1,1,2)==42);
!   assert(d.get(1,2,0)==42); assert(d.get(1,2,1)==42); assert(d.get(1,2,2)==42);
!   assert(d.get(2,0,0)==42); assert(d.get(2,0,1)==42); assert(d.get(2,0,2)==42);
!   assert(d.get(2,1,0)==42); assert(d.get(2,1,1)==42); assert(d.get(2,1,2)==42);
!   assert(d.get(2,2,0)==42); assert(d.get(2,2,1)==42); assert(d.get(2,2,2)==42);
  
    p = impl::Lvalue_proxy<Dense<3> >(d, 0, 0, 0);
!   assert(d.get(0,0,0)==42); assert(d.get(0,0,1)==42); assert(d.get(0,0,2)==42);
!   assert(d.get(0,1,0)==42); assert(d.get(0,1,1)==42); assert(d.get(0,1,2)==42);
!   assert(d.get(0,2,0)==42); assert(d.get(0,2,1)==42); assert(d.get(0,2,2)==42);
!   assert(d.get(1,0,0)==42); assert(d.get(1,0,1)==42); assert(d.get(1,0,2)==42);
!   assert(d.get(1,1,0)==42); assert(d.get(1,1,1)==42); assert(d.get(1,1,2)==42);
!   assert(d.get(1,2,0)==42); assert(d.get(1,2,1)==42); assert(d.get(1,2,2)==42);
!   assert(d.get(2,0,0)==42); assert(d.get(2,0,1)==42); assert(d.get(2,0,2)==42);
!   assert(d.get(2,1,0)==42); assert(d.get(2,1,1)==42); assert(d.get(2,1,2)==42);
!   assert(d.get(2,2,0)==42); assert(d.get(2,2,1)==42); assert(d.get(2,2,2)==42);
  }
  
  // Pseudo-block for testing static type equalities that should hold for
--- 107,190 ----
  {
    Dense<3> d(Domain<3>(3, 3, 3), 42);
    impl::Lvalue_proxy<Dense<3> > p(d, 0, 1, 2);
!   test_assert (p == 42);
  
    p = 4;
!   test_assert(d.get(0,0,0)==42); test_assert(d.get(0,0,1)==42); test_assert(d.get(0,0,2)==42);
!   test_assert(d.get(0,1,0)==42); test_assert(d.get(0,1,1)==42); test_assert(d.get(0,1,2)== 4);
!   test_assert(d.get(0,2,0)==42); test_assert(d.get(0,2,1)==42); test_assert(d.get(0,2,2)==42);
!   test_assert(d.get(1,0,0)==42); test_assert(d.get(1,0,1)==42); test_assert(d.get(1,0,2)==42);
!   test_assert(d.get(1,1,0)==42); test_assert(d.get(1,1,1)==42); test_assert(d.get(1,1,2)==42);
!   test_assert(d.get(1,2,0)==42); test_assert(d.get(1,2,1)==42); test_assert(d.get(1,2,2)==42);
!   test_assert(d.get(2,0,0)==42); test_assert(d.get(2,0,1)==42); test_assert(d.get(2,0,2)==42);
!   test_assert(d.get(2,1,0)==42); test_assert(d.get(2,1,1)==42); test_assert(d.get(2,1,2)==42);
!   test_assert(d.get(2,2,0)==42); test_assert(d.get(2,2,1)==42); test_assert(d.get(2,2,2)==42);
  
    p += 3;
!   test_assert(d.get(0,0,0)==42); test_assert(d.get(0,0,1)==42); test_assert(d.get(0,0,2)==42);
!   test_assert(d.get(0,1,0)==42); test_assert(d.get(0,1,1)==42); test_assert(d.get(0,1,2)== 7);
!   test_assert(d.get(0,2,0)==42); test_assert(d.get(0,2,1)==42); test_assert(d.get(0,2,2)==42);
!   test_assert(d.get(1,0,0)==42); test_assert(d.get(1,0,1)==42); test_assert(d.get(1,0,2)==42);
!   test_assert(d.get(1,1,0)==42); test_assert(d.get(1,1,1)==42); test_assert(d.get(1,1,2)==42);
!   test_assert(d.get(1,2,0)==42); test_assert(d.get(1,2,1)==42); test_assert(d.get(1,2,2)==42);
!   test_assert(d.get(2,0,0)==42); test_assert(d.get(2,0,1)==42); test_assert(d.get(2,0,2)==42);
!   test_assert(d.get(2,1,0)==42); test_assert(d.get(2,1,1)==42); test_assert(d.get(2,1,2)==42);
!   test_assert(d.get(2,2,0)==42); test_assert(d.get(2,2,1)==42); test_assert(d.get(2,2,2)==42);
  
    p -= 5;
!   test_assert(d.get(0,0,0)==42); test_assert(d.get(0,0,1)==42); test_assert(d.get(0,0,2)==42);
!   test_assert(d.get(0,1,0)==42); test_assert(d.get(0,1,1)==42); test_assert(d.get(0,1,2)== 2);
!   test_assert(d.get(0,2,0)==42); test_assert(d.get(0,2,1)==42); test_assert(d.get(0,2,2)==42);
!   test_assert(d.get(1,0,0)==42); test_assert(d.get(1,0,1)==42); test_assert(d.get(1,0,2)==42);
!   test_assert(d.get(1,1,0)==42); test_assert(d.get(1,1,1)==42); test_assert(d.get(1,1,2)==42);
!   test_assert(d.get(1,2,0)==42); test_assert(d.get(1,2,1)==42); test_assert(d.get(1,2,2)==42);
!   test_assert(d.get(2,0,0)==42); test_assert(d.get(2,0,1)==42); test_assert(d.get(2,0,2)==42);
!   test_assert(d.get(2,1,0)==42); test_assert(d.get(2,1,1)==42); test_assert(d.get(2,1,2)==42);
!   test_assert(d.get(2,2,0)==42); test_assert(d.get(2,2,1)==42); test_assert(d.get(2,2,2)==42);
  
    p *= 3;
!   test_assert(d.get(0,0,0)==42); test_assert(d.get(0,0,1)==42); test_assert(d.get(0,0,2)==42);
!   test_assert(d.get(0,1,0)==42); test_assert(d.get(0,1,1)==42); test_assert(d.get(0,1,2)== 6);
!   test_assert(d.get(0,2,0)==42); test_assert(d.get(0,2,1)==42); test_assert(d.get(0,2,2)==42);
!   test_assert(d.get(1,0,0)==42); test_assert(d.get(1,0,1)==42); test_assert(d.get(1,0,2)==42);
!   test_assert(d.get(1,1,0)==42); test_assert(d.get(1,1,1)==42); test_assert(d.get(1,1,2)==42);
!   test_assert(d.get(1,2,0)==42); test_assert(d.get(1,2,1)==42); test_assert(d.get(1,2,2)==42);
!   test_assert(d.get(2,0,0)==42); test_assert(d.get(2,0,1)==42); test_assert(d.get(2,0,2)==42);
!   test_assert(d.get(2,1,0)==42); test_assert(d.get(2,1,1)==42); test_assert(d.get(2,1,2)==42);
!   test_assert(d.get(2,2,0)==42); test_assert(d.get(2,2,1)==42); test_assert(d.get(2,2,2)==42);
  
    p /= 2;
!   test_assert(d.get(0,0,0)==42); test_assert(d.get(0,0,1)==42); test_assert(d.get(0,0,2)==42);
!   test_assert(d.get(0,1,0)==42); test_assert(d.get(0,1,1)==42); test_assert(d.get(0,1,2)== 3);
!   test_assert(d.get(0,2,0)==42); test_assert(d.get(0,2,1)==42); test_assert(d.get(0,2,2)==42);
!   test_assert(d.get(1,0,0)==42); test_assert(d.get(1,0,1)==42); test_assert(d.get(1,0,2)==42);
!   test_assert(d.get(1,1,0)==42); test_assert(d.get(1,1,1)==42); test_assert(d.get(1,1,2)==42);
!   test_assert(d.get(1,2,0)==42); test_assert(d.get(1,2,1)==42); test_assert(d.get(1,2,2)==42);
!   test_assert(d.get(2,0,0)==42); test_assert(d.get(2,0,1)==42); test_assert(d.get(2,0,2)==42);
!   test_assert(d.get(2,1,0)==42); test_assert(d.get(2,1,1)==42); test_assert(d.get(2,1,2)==42);
!   test_assert(d.get(2,2,0)==42); test_assert(d.get(2,2,1)==42); test_assert(d.get(2,2,2)==42);
  
    (p = 12) = 10;
!   test_assert(d.get(0,0,0)==42); test_assert(d.get(0,0,1)==42); test_assert(d.get(0,0,2)==42);
!   test_assert(d.get(0,1,0)==42); test_assert(d.get(0,1,1)==42); test_assert(d.get(0,1,2)==10);
!   test_assert(d.get(0,2,0)==42); test_assert(d.get(0,2,1)==42); test_assert(d.get(0,2,2)==42);
!   test_assert(d.get(1,0,0)==42); test_assert(d.get(1,0,1)==42); test_assert(d.get(1,0,2)==42);
!   test_assert(d.get(1,1,0)==42); test_assert(d.get(1,1,1)==42); test_assert(d.get(1,1,2)==42);
!   test_assert(d.get(1,2,0)==42); test_assert(d.get(1,2,1)==42); test_assert(d.get(1,2,2)==42);
!   test_assert(d.get(2,0,0)==42); test_assert(d.get(2,0,1)==42); test_assert(d.get(2,0,2)==42);
!   test_assert(d.get(2,1,0)==42); test_assert(d.get(2,1,1)==42); test_assert(d.get(2,1,2)==42);
!   test_assert(d.get(2,2,0)==42); test_assert(d.get(2,2,1)==42); test_assert(d.get(2,2,2)==42);
  
    p = impl::Lvalue_proxy<Dense<3> >(d, 0, 0, 0);
!   test_assert(d.get(0,0,0)==42); test_assert(d.get(0,0,1)==42); test_assert(d.get(0,0,2)==42);
!   test_assert(d.get(0,1,0)==42); test_assert(d.get(0,1,1)==42); test_assert(d.get(0,1,2)==42);
!   test_assert(d.get(0,2,0)==42); test_assert(d.get(0,2,1)==42); test_assert(d.get(0,2,2)==42);
!   test_assert(d.get(1,0,0)==42); test_assert(d.get(1,0,1)==42); test_assert(d.get(1,0,2)==42);
!   test_assert(d.get(1,1,0)==42); test_assert(d.get(1,1,1)==42); test_assert(d.get(1,1,2)==42);
!   test_assert(d.get(1,2,0)==42); test_assert(d.get(1,2,1)==42); test_assert(d.get(1,2,2)==42);
!   test_assert(d.get(2,0,0)==42); test_assert(d.get(2,0,1)==42); test_assert(d.get(2,0,2)==42);
!   test_assert(d.get(2,1,0)==42); test_assert(d.get(2,1,1)==42); test_assert(d.get(2,1,2)==42);
!   test_assert(d.get(2,2,0)==42); test_assert(d.get(2,2,1)==42); test_assert(d.get(2,2,2)==42);
  }
  
  // Pseudo-block for testing static type equalities that should hold for
*************** main(void)
*** 211,217 ****
                        PseudoBlock::reference_type
      >::value == true));
  
!   // Some static assertions about the traits class.
    // For the pseudo-block above, it should make the conservative assumption
    // that a proxy lvalue must be used.
    VSIP_IMPL_STATIC_ASSERT((
--- 210,216 ----
                        PseudoBlock::reference_type
      >::value == true));
  
!   // Some static test_assertions about the traits class.
    // For the pseudo-block above, it should make the conservative assumption
    // that a proxy lvalue must be used.
    VSIP_IMPL_STATIC_ASSERT((
Index: tests/map.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/map.cpp,v
retrieving revision 1.9
diff -c -p -r1.9 map.cpp
*** tests/map.cpp	5 Dec 2005 19:19:19 -0000	1.9
--- tests/map.cpp	20 Dec 2005 12:39:20 -0000
*************** check_distribution(
*** 36,44 ****
    length_type num_subblocks,
    length_type contiguity)
  {
!   assert(dist.distribution()      == type);
!   assert(dist.num_subblocks()     == num_subblocks);
!   assert(dist.cyclic_contiguity() == contiguity);
  }
  
  
--- 36,44 ----
    length_type num_subblocks,
    length_type contiguity)
  {
!   test_assert(dist.distribution()      == type);
!   test_assert(dist.num_subblocks()     == num_subblocks);
!   test_assert(dist.cyclic_contiguity() == contiguity);
  }
  
  
*************** test_map_basic()
*** 117,166 ****
    // Each dimension should default to 1 subblock.
    Map<Block_dist, Block_dist> map1;
  
!   assert(map1.distribution(0)      == block);
!   assert(map1.num_subblocks(0)     == 1);
!   assert(map1.cyclic_contiguity(0) == 0);
! 
!   assert(map1.distribution(1)      == block);
!   assert(map1.num_subblocks(1)     == 1);
!   assert(map1.cyclic_contiguity(1) == 0);
! 
!   assert(map1.distribution(2)      == block);
!   assert(map1.num_subblocks(2)     == 1);
!   assert(map1.cyclic_contiguity(2) == 0);
  
  
  
    Map<Block_dist, Cyclic_dist> map2;
  
!   assert(map2.distribution(0)      == block);
!   assert(map2.num_subblocks(0)     == 1);
!   assert(map2.cyclic_contiguity(0) == 0);
! 
!   assert(map2.distribution(1)      == cyclic);
!   assert(map2.num_subblocks(1)     == 1);
!   assert(map2.cyclic_contiguity(1) == 1);
! 
!   assert(map2.distribution(2)      == block);
!   assert(map2.num_subblocks(2)     == 1);
!   assert(map2.cyclic_contiguity(2) == 0);
  
  
  
    Vector<processor_type> pvec(12); pvec = 0;
    Map<Block_dist, Cyclic_dist> map3(pvec, Block_dist(3), Cyclic_dist(4, 2));
  
!   assert(map3.distribution(0)      == block);
!   assert(map3.num_subblocks(0)     == 3);
!   assert(map3.cyclic_contiguity(0) == 0);
! 
!   assert(map3.distribution(1)      == cyclic);
!   assert(map3.num_subblocks(1)     == 4);
!   assert(map3.cyclic_contiguity(1) == 2);
! 
!   assert(map3.distribution(2)      == block);
!   assert(map3.num_subblocks(2)     == 1);
!   assert(map3.cyclic_contiguity(2) == 0);
  }
  
  
--- 117,166 ----
    // Each dimension should default to 1 subblock.
    Map<Block_dist, Block_dist> map1;
  
!   test_assert(map1.distribution(0)      == block);
!   test_assert(map1.num_subblocks(0)     == 1);
!   test_assert(map1.cyclic_contiguity(0) == 0);
! 
!   test_assert(map1.distribution(1)      == block);
!   test_assert(map1.num_subblocks(1)     == 1);
!   test_assert(map1.cyclic_contiguity(1) == 0);
! 
!   test_assert(map1.distribution(2)      == block);
!   test_assert(map1.num_subblocks(2)     == 1);
!   test_assert(map1.cyclic_contiguity(2) == 0);
  
  
  
    Map<Block_dist, Cyclic_dist> map2;
  
!   test_assert(map2.distribution(0)      == block);
!   test_assert(map2.num_subblocks(0)     == 1);
!   test_assert(map2.cyclic_contiguity(0) == 0);
! 
!   test_assert(map2.distribution(1)      == cyclic);
!   test_assert(map2.num_subblocks(1)     == 1);
!   test_assert(map2.cyclic_contiguity(1) == 1);
! 
!   test_assert(map2.distribution(2)      == block);
!   test_assert(map2.num_subblocks(2)     == 1);
!   test_assert(map2.cyclic_contiguity(2) == 0);
  
  
  
    Vector<processor_type> pvec(12); pvec = 0;
    Map<Block_dist, Cyclic_dist> map3(pvec, Block_dist(3), Cyclic_dist(4, 2));
  
!   test_assert(map3.distribution(0)      == block);
!   test_assert(map3.num_subblocks(0)     == 3);
!   test_assert(map3.cyclic_contiguity(0) == 0);
! 
!   test_assert(map3.distribution(1)      == cyclic);
!   test_assert(map3.num_subblocks(1)     == 4);
!   test_assert(map3.cyclic_contiguity(1) == 2);
! 
!   test_assert(map3.distribution(2)      == block);
!   test_assert(map3.num_subblocks(2)     == 1);
!   test_assert(map3.cyclic_contiguity(2) == 0);
  }
  
  
*************** count_subblocks(
*** 177,183 ****
    for (SubblockIterator cur = begin; cur != end; ++cur)
      ++count;
    // SubblockIterator is Random Access Iterator
!   assert(end - begin == count);
    return count;
  }
  
--- 177,183 ----
    for (SubblockIterator cur = begin; cur != end; ++cur)
      ++count;
    // SubblockIterator is Random Access Iterator
!   test_assert(end - begin == count);
    return count;
  }
  
*************** check_subblock(
*** 203,212 ****
      for (processor_iterator pcur = pbegin; pcur != pend; ++pcur)
      {
        ++pr_count;
!       assert(*pcur == pr);
      }
!     assert(pr_count == 1);
!     assert(pend - pbegin == 1);
  
    }
  }
--- 203,212 ----
      for (processor_iterator pcur = pbegin; pcur != pend; ++pcur)
      {
        ++pr_count;
!       test_assert(*pcur == pr);
      }
!     test_assert(pr_count == 1);
!     test_assert(pend - pbegin == 1);
  
    }
  }
*************** tc_map_subblocks(
*** 273,279 ****
      length_type count = sb == no_subblock ? 0 : 1;
  
      // Check the number of subblocks per processor.
!     assert(count == expected_count);
  
      // Check that each subblock is only mapped to this processr.
      check_subblock(map, pr, sb);
--- 273,279 ----
      length_type count = sb == no_subblock ? 0 : 1;
  
      // Check the number of subblocks per processor.
!     test_assert(count == expected_count);
  
      // Check that each subblock is only mapped to this processr.
      check_subblock(map, pr, sb);
*************** tc_map_subblocks(
*** 282,288 ****
    }
  
    // Check that number of subblocks iterated over equals expected.
!   assert(total == num_subblocks);
  }
  
  
--- 282,288 ----
    }
  
    // Check that number of subblocks iterated over equals expected.
!   test_assert(total == num_subblocks);
  }
  
  
*************** test_segment_size()
*** 311,375 ****
    // should be the same size.
    for (index_type i=0; i<5; ++i)
    {
!     assert(impl::segment_size(10, 5, i) == 2);
!     assert(impl::segment_size(10, 5, 1, i) == 2);
    }
  
    // Extra elements should be spread across the first segements.
!   assert(impl::segment_size(11, 5, 0) == 3);
!   assert(impl::segment_size(11, 5, 1) == 2);
!   assert(impl::segment_size(11, 5, 2) == 2);
!   assert(impl::segment_size(11, 5, 3) == 2);
!   assert(impl::segment_size(11, 5, 4) == 2);
  
    // Extra elements should be spread across the first segements.
!   assert(impl::segment_size(13, 5, 0) == 3);
!   assert(impl::segment_size(13, 5, 1) == 3);
!   assert(impl::segment_size(13, 5, 2) == 3);
!   assert(impl::segment_size(13, 5, 3) == 2);
!   assert(impl::segment_size(13, 5, 4) == 2);
  
    // Extra elements should be spread across the first segements.
!   assert(impl::segment_size(13, 5, 1, 0) == 3);
!   assert(impl::segment_size(13, 5, 1, 1) == 3);
!   assert(impl::segment_size(13, 5, 1, 2) == 3);
!   assert(impl::segment_size(13, 5, 1, 3) == 2);
!   assert(impl::segment_size(13, 5, 1, 4) == 2);
  
    // Check how chunksize of 2 is handled
!   assert(impl::segment_size(16, 5, 2, 0) == 4);
!   assert(impl::segment_size(16, 5, 2, 1) == 4);
!   assert(impl::segment_size(16, 5, 2, 2) == 4);
!   assert(impl::segment_size(16, 5, 2, 3) == 2);
!   assert(impl::segment_size(16, 5, 2, 4) == 2);
! 
!   assert(impl::segment_size(14, 5, 2, 0) == 4);
!   assert(impl::segment_size(14, 5, 2, 1) == 4);
!   assert(impl::segment_size(14, 5, 2, 2) == 2);
!   assert(impl::segment_size(14, 5, 2, 3) == 2);
!   assert(impl::segment_size(14, 5, 2, 4) == 2);
  
    // Check how odd partial chunk is handled:
!   assert(impl::segment_size(15, 5, 2, 0) == 4);
!   assert(impl::segment_size(15, 5, 2, 1) == 4);
!   assert(impl::segment_size(15, 5, 2, 2) == 3);
!   assert(impl::segment_size(15, 5, 2, 3) == 2);
!   assert(impl::segment_size(15, 5, 2, 4) == 2);
! 
!   assert(impl::segment_size(15, 4, 4, 0) == 4);
!   assert(impl::segment_size(15, 4, 4, 1) == 4);
!   assert(impl::segment_size(15, 4, 4, 2) == 4);
!   assert(impl::segment_size(15, 4, 4, 3) == 3);
! 
!   assert(impl::segment_size(11, 4, 4, 0) == 4);
!   assert(impl::segment_size(11, 4, 4, 1) == 4);
!   assert(impl::segment_size(11, 4, 4, 2) == 3);
!   assert(impl::segment_size(11, 4, 4, 3) == 0);
! 
!   assert(impl::segment_size(6, 4, 4, 0) == 4);
!   assert(impl::segment_size(6, 4, 4, 1) == 2);
!   assert(impl::segment_size(6, 4, 4, 2) == 0);
!   assert(impl::segment_size(6, 4, 4, 3) == 0);
  }
  
  
--- 311,375 ----
    // should be the same size.
    for (index_type i=0; i<5; ++i)
    {
!     test_assert(impl::segment_size(10, 5, i) == 2);
!     test_assert(impl::segment_size(10, 5, 1, i) == 2);
    }
  
    // Extra elements should be spread across the first segements.
!   test_assert(impl::segment_size(11, 5, 0) == 3);
!   test_assert(impl::segment_size(11, 5, 1) == 2);
!   test_assert(impl::segment_size(11, 5, 2) == 2);
!   test_assert(impl::segment_size(11, 5, 3) == 2);
!   test_assert(impl::segment_size(11, 5, 4) == 2);
  
    // Extra elements should be spread across the first segements.
!   test_assert(impl::segment_size(13, 5, 0) == 3);
!   test_assert(impl::segment_size(13, 5, 1) == 3);
!   test_assert(impl::segment_size(13, 5, 2) == 3);
!   test_assert(impl::segment_size(13, 5, 3) == 2);
!   test_assert(impl::segment_size(13, 5, 4) == 2);
  
    // Extra elements should be spread across the first segements.
!   test_assert(impl::segment_size(13, 5, 1, 0) == 3);
!   test_assert(impl::segment_size(13, 5, 1, 1) == 3);
!   test_assert(impl::segment_size(13, 5, 1, 2) == 3);
!   test_assert(impl::segment_size(13, 5, 1, 3) == 2);
!   test_assert(impl::segment_size(13, 5, 1, 4) == 2);
  
    // Check how chunksize of 2 is handled
!   test_assert(impl::segment_size(16, 5, 2, 0) == 4);
!   test_assert(impl::segment_size(16, 5, 2, 1) == 4);
!   test_assert(impl::segment_size(16, 5, 2, 2) == 4);
!   test_assert(impl::segment_size(16, 5, 2, 3) == 2);
!   test_assert(impl::segment_size(16, 5, 2, 4) == 2);
! 
!   test_assert(impl::segment_size(14, 5, 2, 0) == 4);
!   test_assert(impl::segment_size(14, 5, 2, 1) == 4);
!   test_assert(impl::segment_size(14, 5, 2, 2) == 2);
!   test_assert(impl::segment_size(14, 5, 2, 3) == 2);
!   test_assert(impl::segment_size(14, 5, 2, 4) == 2);
  
    // Check how odd partial chunk is handled:
!   test_assert(impl::segment_size(15, 5, 2, 0) == 4);
!   test_assert(impl::segment_size(15, 5, 2, 1) == 4);
!   test_assert(impl::segment_size(15, 5, 2, 2) == 3);
!   test_assert(impl::segment_size(15, 5, 2, 3) == 2);
!   test_assert(impl::segment_size(15, 5, 2, 4) == 2);
! 
!   test_assert(impl::segment_size(15, 4, 4, 0) == 4);
!   test_assert(impl::segment_size(15, 4, 4, 1) == 4);
!   test_assert(impl::segment_size(15, 4, 4, 2) == 4);
!   test_assert(impl::segment_size(15, 4, 4, 3) == 3);
! 
!   test_assert(impl::segment_size(11, 4, 4, 0) == 4);
!   test_assert(impl::segment_size(11, 4, 4, 1) == 4);
!   test_assert(impl::segment_size(11, 4, 4, 2) == 3);
!   test_assert(impl::segment_size(11, 4, 4, 3) == 0);
! 
!   test_assert(impl::segment_size(6, 4, 4, 0) == 4);
!   test_assert(impl::segment_size(6, 4, 4, 1) == 2);
!   test_assert(impl::segment_size(6, 4, 4, 2) == 0);
!   test_assert(impl::segment_size(6, 4, 4, 3) == 0);
  }
  
  
Index: tests/matrix-transpose.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/matrix-transpose.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 matrix-transpose.cpp
*** tests/matrix-transpose.cpp	18 Aug 2005 16:17:24 -0000	1.1
--- tests/matrix-transpose.cpp	20 Dec 2005 12:39:20 -0000
*************** check_matrix(MatrixT view, int offset=0)
*** 60,66 ****
    for (index_type idx0=0; idx0<view.size(0); ++idx0)
      for (index_type idx1=0; idx1<view.size(1); ++idx1)
      {
!       assert(equal(view.get(idx0, idx1),
  		   T(idx0 * size1 + idx1 + offset)));
      }
  }
--- 60,66 ----
    for (index_type idx0=0; idx0<view.size(0); ++idx0)
      for (index_type idx1=0; idx1<view.size(1); ++idx1)
      {
!       test_assert(equal(view.get(idx0, idx1),
  		   T(idx0 * size1 + idx1 + offset)));
      }
  }
*************** test_transpose_readonly(MatrixT view)
*** 80,94 ****
  
    typename MatrixT::const_transpose_type trans = view.transpose();
  
!   assert(trans.size(0) == view.size(1));
!   assert(trans.size(1) == view.size(0));
  
    for (index_type idx0=0; idx0<trans.size(0); ++idx0)
      for (index_type idx1=0; idx1<trans.size(1); ++idx1)
      {
        T expected = T(idx1 * size1 + idx0 + 0);
!       assert(equal(trans.get(idx0, idx1), expected));
!       assert(equal(trans.get(idx0,  idx1),
  		   view. get(idx1, idx0)));
        }
  
--- 80,94 ----
  
    typename MatrixT::const_transpose_type trans = view.transpose();
  
!   test_assert(trans.size(0) == view.size(1));
!   test_assert(trans.size(1) == view.size(0));
  
    for (index_type idx0=0; idx0<trans.size(0); ++idx0)
      for (index_type idx1=0; idx1<trans.size(1); ++idx1)
      {
        T expected = T(idx1 * size1 + idx0 + 0);
!       test_assert(equal(trans.get(idx0, idx1), expected));
!       test_assert(equal(trans.get(idx0,  idx1),
  		   view. get(idx1, idx0)));
        }
  
*************** test_transpose(MatrixT view)
*** 111,131 ****
  
    typename MatrixT::transpose_type trans = view.transpose();
  
!   assert(trans.size(0) == view.size(1));
!   assert(trans.size(1) == view.size(0));
  
    for (index_type idx0=0; idx0<trans.size(0); ++idx0)
      for (index_type idx1=0; idx1<trans.size(1); ++idx1)
      {
        T expected = T(idx1 * size1 + idx0 + 0);
!       assert(equal(trans.get(idx0, idx1), expected));
!       assert(equal(trans.get(idx0,  idx1),
  		   view. get(idx1, idx0)));
  
        T new_value = T(idx1 * size1 + idx0 + 1);
        trans.put(idx0, idx1, new_value);
  
!       assert(equal(trans.get(idx0,  idx1),
  		   view. get(idx1, idx0)));
        }
  
--- 111,131 ----
  
    typename MatrixT::transpose_type trans = view.transpose();
  
!   test_assert(trans.size(0) == view.size(1));
!   test_assert(trans.size(1) == view.size(0));
  
    for (index_type idx0=0; idx0<trans.size(0); ++idx0)
      for (index_type idx1=0; idx1<trans.size(1); ++idx1)
      {
        T expected = T(idx1 * size1 + idx0 + 0);
!       test_assert(equal(trans.get(idx0, idx1), expected));
!       test_assert(equal(trans.get(idx0,  idx1),
  		   view. get(idx1, idx0)));
  
        T new_value = T(idx1 * size1 + idx0 + 1);
        trans.put(idx0, idx1, new_value);
  
!       test_assert(equal(trans.get(idx0,  idx1),
  		   view. get(idx1, idx0)));
        }
  
Index: tests/matrix.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/matrix.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 matrix.cpp
*** tests/matrix.cpp	28 Apr 2005 19:04:10 -0000	1.3
--- tests/matrix.cpp	20 Dec 2005 12:39:20 -0000
*************** template <typename T,
*** 50,58 ****
  void
  check_size(const_Matrix<T, Block> matrix, length_type cols, length_type rows)
  {
!   assert(matrix.size() == cols * rows);
!   assert(matrix.size(0) == cols);
!   assert(matrix.size(1) == rows);
  }
  
  
--- 50,58 ----
  void
  check_size(const_Matrix<T, Block> matrix, length_type cols, length_type rows)
  {
!   test_assert(matrix.size() == cols * rows);
!   test_assert(matrix.size(0) == cols);
!   test_assert(matrix.size(1) == rows);
  }
  
  
*************** test_matrix(const_Matrix<T, Block> matri
*** 102,108 ****
  {
    for (index_type c = 0; c < matrix.size(0); ++c)
      for (index_type r = 0; r < matrix.size(1); ++r)
!       assert(equal(matrix.get(c, r), T(k * c * r + 1)));
  }
  
  
--- 102,108 ----
  {
    for (index_type c = 0; c < matrix.size(0); ++c)
      for (index_type r = 0; r < matrix.size(1); ++r)
!       test_assert(equal(matrix.get(c, r), T(k * c * r + 1)));
  }
  
  
*************** test_matrix(const_Matrix<T, Block> matri
*** 111,118 ****
  //
  // Checks that matrix values match those generated by a call to
  // fill_matrix or fill_block with the same k value.  Rather than
! // triggering assertion failure, check_matrix returns a boolean
! // pass/fail that can be used to cause an assertion failure in
  // the caller.
  
  template <typename T,
--- 111,118 ----
  //
  // Checks that matrix values match those generated by a call to
  // fill_matrix or fill_block with the same k value.  Rather than
! // triggering test_assertion failure, check_matrix returns a boolean
! // pass/fail that can be used to cause an test_assertion failure in
  // the caller.
  
  template <typename T,
*************** check_not_alias(
*** 148,158 ****
    fill_block(matrix2.block(), 3);
  
    // Make sure that updates to matrix2 do not affect matrix1.
!   assert(check_matrix(matrix1, 2));
  
    // And visa-versa.
    fill_block(matrix1.block(), 4);
!   assert(check_matrix(matrix2, 3));
  }
  
  
--- 148,158 ----
    fill_block(matrix2.block(), 3);
  
    // Make sure that updates to matrix2 do not affect matrix1.
!   test_assert(check_matrix(matrix1, 2));
  
    // And visa-versa.
    fill_block(matrix1.block(), 4);
!   test_assert(check_matrix(matrix2, 3));
  }
  
  
*************** check_alias(
*** 173,184 ****
    View2<T2, Block2>& matrix2)
  {
    fill_block(matrix1.block(), 2);
!   assert(check_matrix(matrix1, 2));
!   assert(check_matrix(matrix2, 2));
  
    fill_block(matrix2.block(), 3);
!   assert(check_matrix(matrix1, 3));
!   assert(check_matrix(matrix2, 3));
  }
  
  
--- 173,184 ----
    View2<T2, Block2>& matrix2)
  {
    fill_block(matrix1.block(), 2);
!   test_assert(check_matrix(matrix1, 2));
!   test_assert(check_matrix(matrix2, 2));
  
    fill_block(matrix2.block(), 3);
!   test_assert(check_matrix(matrix1, 3));
!   test_assert(check_matrix(matrix2, 3));
  }
  
  
*************** tc_assign(length_type col, length_type r
*** 328,334 ****
  
    matrix2 = matrix1;
  
!   assert(check_matrix(matrix2, k));
  
    check_not_alias(matrix1, matrix2);
  }
--- 328,334 ----
  
    matrix2 = matrix1;
  
!   test_assert(check_matrix(matrix2, k));
  
    check_not_alias(matrix1, matrix2);
  }
*************** tc_call_sum_const(length_type col, lengt
*** 406,412 ****
    fill_block(matrix1.block(), k);
    T sum = tc_sum_const(matrix1);
  
!   assert(equal(sum, T(k*col*(col-1)*row*(row-1)/4+col*row)));
  }
  
  
--- 406,412 ----
    fill_block(matrix1.block(), k);
    T sum = tc_sum_const(matrix1);
  
!   test_assert(equal(sum, T(k*col*(col-1)*row*(row-1)/4+col*row)));
  }
  
  
*************** tc_call_sum(length_type col, length_type
*** 423,429 ****
    fill_block(matrix1.block(), k);
    T sum = tc_sum(matrix1);
  
!   assert(equal(sum, T(k*col*(col-1)*row*(row-1)/4+col*row)));
  }
  
  
--- 423,429 ----
    fill_block(matrix1.block(), k);
    T sum = tc_sum(matrix1);
  
!   test_assert(equal(sum, T(k*col*(col-1)*row*(row-1)/4+col*row)));
  }
  
  
*************** tc_assign_return(length_type col, length
*** 478,488 ****
    typedef Dense<2, T> block_type;
    View1<T, block_type> matrix1(col, row, T());
  
!   assert(matrix1.get(0, 0) != val || val == T());
  
    matrix1 = return_view<View2, T, block_type>(col, row, val);
  
!   assert(matrix1.get(0, 0) == val);
  }
  
  
--- 478,488 ----
    typedef Dense<2, T> block_type;
    View1<T, block_type> matrix1(col, row, T());
  
!   test_assert(matrix1.get(0, 0) != val || val == T());
  
    matrix1 = return_view<View2, T, block_type>(col, row, val);
  
!   test_assert(matrix1.get(0, 0) == val);
  }
  
  
*************** tc_cons_return(length_type col, length_t
*** 499,505 ****
  
    View1<T, block_type> vec1(return_view<View2, T, block_type>(col, row, val));
  
!   assert(vec1.get(0, 0) == val);
  }
  
  
--- 499,505 ----
  
    View1<T, block_type> vec1(return_view<View2, T, block_type>(col, row, val));
  
!   test_assert(vec1.get(0, 0) == val);
  }
  
  
*************** tc_subview(Domain<2> const& dom, Domain<
*** 542,559 ****
        index_type parent_c = sub[0].impl_nth(c);
        index_type parent_r = sub[1].impl_nth(r);
  
!       assert(view.get(parent_c, parent_r) ==  subv.get(c, r));
!       assert(view.get(parent_c, parent_r) == csubv.get(c, r));
  
        view.put(parent_c, parent_r, view.get(parent_c, parent_r) + T(1));
  
!       assert(view.get(parent_c, parent_r) ==  subv.get(c, r));
!       assert(view.get(parent_c, parent_r) == csubv.get(c, r));
  
        subv.put(c, r, subv.get(c, r) + T(1));
  
!       assert(view.get(parent_c, parent_r) ==  subv.get(c, r));
!       assert(view.get(parent_c, parent_r) == csubv.get(c, r));
      }
  }
  
--- 542,559 ----
        index_type parent_c = sub[0].impl_nth(c);
        index_type parent_r = sub[1].impl_nth(r);
  
!       test_assert(view.get(parent_c, parent_r) ==  subv.get(c, r));
!       test_assert(view.get(parent_c, parent_r) == csubv.get(c, r));
  
        view.put(parent_c, parent_r, view.get(parent_c, parent_r) + T(1));
  
!       test_assert(view.get(parent_c, parent_r) ==  subv.get(c, r));
!       test_assert(view.get(parent_c, parent_r) == csubv.get(c, r));
  
        subv.put(c, r, subv.get(c, r) + T(1));
  
!       test_assert(view.get(parent_c, parent_r) ==  subv.get(c, r));
!       test_assert(view.get(parent_c, parent_r) == csubv.get(c, r));
      }
  }
  
*************** test_complex()
*** 628,637 ****
    cm.put(1, 0, 5.);
    cm.put(0, 1, 5.);
    cm.put(1, 1, 5.);
!   assert(equal(20., tc_sum(rm)));
!   assert(equal(0., tc_sum(im)));
!   assert(equal(20., tc_sum_const(crm)));
!   assert(equal(0., tc_sum_const(cim)));
    rm.put(0, 0, 0.);
    rm.put(1, 0, 0.);
    rm.put(0, 1, 0.);
--- 628,637 ----
    cm.put(1, 0, 5.);
    cm.put(0, 1, 5.);
    cm.put(1, 1, 5.);
!   test_assert(equal(20., tc_sum(rm)));
!   test_assert(equal(0., tc_sum(im)));
!   test_assert(equal(20., tc_sum_const(crm)));
!   test_assert(equal(0., tc_sum_const(cim)));
    rm.put(0, 0, 0.);
    rm.put(1, 0, 0.);
    rm.put(0, 1, 0.);
*************** test_complex()
*** 640,649 ****
    im.put(1, 0, 5.);
    im.put(0, 1, 5.);
    im.put(1, 1, 5.);
!   assert(equal(0., tc_sum(rm)));
!   assert(equal(20., tc_sum(im)));
!   assert(equal(0., tc_sum_const(crm)));
!   assert(equal(20., tc_sum_const(cim)));
  }
  
  void
--- 640,649 ----
    im.put(1, 0, 5.);
    im.put(0, 1, 5.);
    im.put(1, 1, 5.);
!   test_assert(equal(0., tc_sum(rm)));
!   test_assert(equal(20., tc_sum(im)));
!   test_assert(equal(0., tc_sum_const(crm)));
!   test_assert(equal(20., tc_sum_const(cim)));
  }
  
  void
*************** test_const_complex()
*** 653,660 ****
    CMatrix cm(2, 2, 5.);
    CMatrix::const_realview_type crm = cm.real();
    CMatrix::const_imagview_type cim = cm.imag();
!   assert(equal(20., tc_sum_const(crm)));
!   assert(equal(0., tc_sum_const(cim)));
  }
  
  void
--- 653,660 ----
    CMatrix cm(2, 2, 5.);
    CMatrix::const_realview_type crm = cm.real();
    CMatrix::const_imagview_type cim = cm.imag();
!   test_assert(equal(20., tc_sum_const(crm)));
!   test_assert(equal(0., tc_sum_const(cim)));
  }
  
  void
*************** test_col()
*** 667,682 ****
    m.put(1, 0, 2.);
    m.put(0, 1, 3.);
    m.put(1, 1, 4.);
!   assert(equal(1., cm.get(0)));  // m(0, 0)
!   assert(equal(2., cm.get(1)));  // m(1, 0)
!   assert(equal(3., ccm.get(0))); // m(0, 1)
!   assert(equal(4., ccm.get(1))); // m(1, 1)
    cm.put(0, 0.);
    cm.put(1, 0.);
!   assert(equal(0., cm.get(0)));
!   assert(equal(0., cm.get(1)));
!   assert(equal(3., ccm.get(0)));
!   assert(equal(4., ccm.get(1)));
  
  
    length_type const num_rows = 8;
--- 667,682 ----
    m.put(1, 0, 2.);
    m.put(0, 1, 3.);
    m.put(1, 1, 4.);
!   test_assert(equal(1., cm.get(0)));  // m(0, 0)
!   test_assert(equal(2., cm.get(1)));  // m(1, 0)
!   test_assert(equal(3., ccm.get(0))); // m(0, 1)
!   test_assert(equal(4., ccm.get(1))); // m(1, 1)
    cm.put(0, 0.);
    cm.put(1, 0.);
!   test_assert(equal(0., cm.get(0)));
!   test_assert(equal(0., cm.get(1)));
!   test_assert(equal(3., ccm.get(0)));
!   test_assert(equal(4., ccm.get(1)));
  
  
    length_type const num_rows = 8;
*************** test_col()
*** 687,694 ****
    Matrix<double>::const_col_type ccm2 =
      const_cast<Matrix<double> const&>(m2).col(1);
  
!   assert(cm2.length()  == num_rows); // column length == number of rows
!   assert(ccm2.length() == num_rows); // column length == number of rows
  
    for (index_type r=0; r<num_rows; ++r)
      for (index_type c=0; c<num_rows; ++c)
--- 687,694 ----
    Matrix<double>::const_col_type ccm2 =
      const_cast<Matrix<double> const&>(m2).col(1);
  
!   test_assert(cm2.length()  == num_rows); // column length == number of rows
!   test_assert(ccm2.length() == num_rows); // column length == number of rows
  
    for (index_type r=0; r<num_rows; ++r)
      for (index_type c=0; c<num_rows; ++c)
*************** test_col()
*** 696,703 ****
  
    for (index_type i=0; i<num_rows; ++i)
    {
!     assert(cm2.get(i)  == m2.get(i, 0));
!     assert(ccm2.get(i) == m2.get(i, 1));
    }
  }
  
--- 696,703 ----
  
    for (index_type i=0; i<num_rows; ++i)
    {
!     test_assert(cm2.get(i)  == m2.get(i, 0));
!     test_assert(ccm2.get(i) == m2.get(i, 1));
    }
  }
  
*************** test_const_col()
*** 707,716 ****
    const_Matrix<double> m(2, 2, 3.);
    const_Matrix<double>::const_col_type cm1 = m.col(0);
    const_Matrix<double>::const_col_type cm2 = m.col(1);
!   assert(equal(3., cm1.get(0)));
!   assert(equal(3., cm1.get(1)));
!   assert(equal(3., cm2.get(0)));
!   assert(equal(3., cm2.get(1)));
  }
  
  void
--- 707,716 ----
    const_Matrix<double> m(2, 2, 3.);
    const_Matrix<double>::const_col_type cm1 = m.col(0);
    const_Matrix<double>::const_col_type cm2 = m.col(1);
!   test_assert(equal(3., cm1.get(0)));
!   test_assert(equal(3., cm1.get(1)));
!   test_assert(equal(3., cm2.get(0)));
!   test_assert(equal(3., cm2.get(1)));
  }
  
  void
*************** test_row()
*** 723,738 ****
    m.put(1, 0, 2.);
    m.put(0, 1, 3.);
    m.put(1, 1, 4.);
!   assert(equal(1., rm.get(0)));  // m(0, 0)
!   assert(equal(3., rm.get(1)));  // m(0, 1)
!   assert(equal(2., crm.get(0))); // m(1, 0)
!   assert(equal(4., crm.get(1))); // m(1, 1)
    rm.put(0, 0.);
    rm.put(1, 0.);
!   assert(equal(0., rm.get(0)));
!   assert(equal(0., rm.get(1)));
!   assert(equal(2., crm.get(0)));
!   assert(equal(4., crm.get(1)));
  
  
    length_type const num_rows = 8;
--- 723,738 ----
    m.put(1, 0, 2.);
    m.put(0, 1, 3.);
    m.put(1, 1, 4.);
!   test_assert(equal(1., rm.get(0)));  // m(0, 0)
!   test_assert(equal(3., rm.get(1)));  // m(0, 1)
!   test_assert(equal(2., crm.get(0))); // m(1, 0)
!   test_assert(equal(4., crm.get(1))); // m(1, 1)
    rm.put(0, 0.);
    rm.put(1, 0.);
!   test_assert(equal(0., rm.get(0)));
!   test_assert(equal(0., rm.get(1)));
!   test_assert(equal(2., crm.get(0)));
!   test_assert(equal(4., crm.get(1)));
  
  
    length_type const num_rows = 8;
*************** test_row()
*** 743,750 ****
    Matrix<double>::const_row_type crm2 =
      const_cast<Matrix<double> const&>(m2).row(1);
  
!   assert(rm2.length()  == num_cols); // row length == number of columns
!   assert(crm2.length() == num_cols); // row length == number of columns
  
    for (index_type r=0; r<num_rows; ++r)
      for (index_type c=0; c<num_rows; ++c)
--- 743,750 ----
    Matrix<double>::const_row_type crm2 =
      const_cast<Matrix<double> const&>(m2).row(1);
  
!   test_assert(rm2.length()  == num_cols); // row length == number of columns
!   test_assert(crm2.length() == num_cols); // row length == number of columns
  
    for (index_type r=0; r<num_rows; ++r)
      for (index_type c=0; c<num_rows; ++c)
*************** test_row()
*** 752,759 ****
  
    for (index_type i=0; i<num_rows; ++i)
    {
!     assert(rm2.get(i)  == m2.get(0, i));
!     assert(crm2.get(i) == m2.get(1, i));
    }
  
  }
--- 752,759 ----
  
    for (index_type i=0; i<num_rows; ++i)
    {
!     test_assert(rm2.get(i)  == m2.get(0, i));
!     test_assert(crm2.get(i) == m2.get(1, i));
    }
  
  }
*************** test_const_row()
*** 764,773 ****
    const_Matrix<double> m(2, 2, 3.);
    const_Matrix<double>::const_row_type rm1 = m.row(0);
    const_Matrix<double>::const_row_type rm2 = m.row(1);
!   assert(equal(3., rm1.get(0)));
!   assert(equal(3., rm1.get(1)));
!   assert(equal(3., rm2.get(0)));
!   assert(equal(3., rm2.get(1)));
  }
  
  #define VSIP_TEST_ELEMENTWISE_SCALAR(x, op, y) \
--- 764,773 ----
    const_Matrix<double> m(2, 2, 3.);
    const_Matrix<double>::const_row_type rm1 = m.row(0);
    const_Matrix<double>::const_row_type rm2 = m.row(1);
!   test_assert(equal(3., rm1.get(0)));
!   test_assert(equal(3., rm1.get(1)));
!   test_assert(equal(3., rm2.get(0)));
!   test_assert(equal(3., rm2.get(1)));
  }
  
  #define VSIP_TEST_ELEMENTWISE_SCALAR(x, op, y) \
*************** test_const_row()
*** 776,782 ****
    Matrix<int> &m1 = (m op y);		       \
    int r = x;                                   \
    r op y;                                      \
!   assert(&m1 == &m && equal(m1.get(0, 0), r)); \
  }
  
  #define VSIP_TEST_ELEMENTWISE_MATRIX(x, op, y) \
--- 776,782 ----
    Matrix<int> &m1 = (m op y);		       \
    int r = x;                                   \
    r op y;                                      \
!   test_assert(&m1 == &m && equal(m1.get(0, 0), r)); \
  }
  
  #define VSIP_TEST_ELEMENTWISE_MATRIX(x, op, y) \
*************** test_const_row()
*** 786,792 ****
    Matrix<int> &m1 = (m op n);		       \
    int r = x;                                   \
    r op y;                                      \
!   assert(&m1 == &m && equal(m1.get(0, 0), r)); \
  }
  
  int
--- 786,792 ----
    Matrix<int> &m1 = (m op n);		       \
    int r = x;                                   \
    r op y;                                      \
!   test_assert(&m1 == &m && equal(m1.get(0, 0), r)); \
  }
  
  int
Index: tests/matvec-dot.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/matvec-dot.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 matvec-dot.cpp
*** tests/matvec-dot.cpp	12 Oct 2005 12:45:05 -0000	1.1
--- tests/matvec-dot.cpp	20 Dec 2005 12:39:20 -0000
*************** test_dot_rand(length_type m)
*** 60,66 ****
    return_type val = dot(a, b);
    return_type chk = ref::dot(a, b);
  
!   assert(equal(val, chk));
  }
  
  
--- 60,66 ----
    return_type val = dot(a, b);
    return_type chk = ref::dot(a, b);
  
!   test_assert(equal(val, chk));
  }
  
  
*************** test_cvjdot_rand(length_type m)
*** 86,93 ****
    return_type chk1 = dot(a, conj(b));
    return_type chk2 = ref::dot(a, conj(b));
  
!   assert(equal(val, chk1));
!   assert(equal(val, chk2));
  }
  
  
--- 86,93 ----
    return_type chk1 = dot(a, conj(b));
    return_type chk2 = ref::dot(a, conj(b));
  
!   test_assert(equal(val, chk1));
!   test_assert(equal(val, chk2));
  }
  
  
Index: tests/matvec-prod.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/matvec-prod.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 matvec-prod.cpp
*** tests/matvec-prod.cpp	15 Nov 2005 21:01:01 -0000	1.5
--- tests/matvec-prod.cpp	20 Dec 2005 12:39:20 -0000
*************** check_prod(
*** 64,70 ****
    cout << "err = " << err << endl;
  #endif
  
!   assert(err < 10.0);
  }
  
  
--- 64,70 ----
    cout << "err = " << err << endl;
  #endif
  
!   test_assert(err < 10.0);
  }
  
  
*************** check_prod(
*** 96,102 ****
    cout << "err = " << err << endl;
  #endif
  
!   assert(err < 10.0);
  }
  
  
--- 96,102 ----
    cout << "err = " << err << endl;
  #endif
  
!   test_assert(err < 10.0);
  }
  
  
Index: tests/matvec.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/matvec.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 matvec.cpp
*** tests/matvec.cpp	30 Nov 2005 18:21:11 -0000	1.5
--- tests/matvec.cpp	20 Dec 2005 12:39:20 -0000
*************** Check_gem_results( Matrix<T> actual, Mat
*** 95,101 ****
  {
    for ( index_type row = 0; row < actual.size(0); ++row )
      for ( index_type col = 0; col < actual.size(1); ++col )
!       assert( equal( actual.get(row, col), expected.get(row, col) ) );
  }
  
  
--- 95,101 ----
  {
    for ( index_type row = 0; row < actual.size(0); ++row )
      for ( index_type col = 0; col < actual.size(1); ++col )
!       test_assert( equal( actual.get(row, col), expected.get(row, col) ) );
  }
  
  
*************** Test_cumsum()
*** 338,344 ****
    }
  
    cumsum<0>( v1, v2 );
!   assert( equal( sum, v2.get(len - 1) ) );
  
  
    // simple sum of a vector containing complex<scalars>
--- 338,344 ----
    }
  
    cumsum<0>( v1, v2 );
!   test_assert( equal( sum, v2.get(len - 1) ) );
  
  
    // simple sum of a vector containing complex<scalars>
*************** Test_cumsum()
*** 353,359 ****
    }
  
    cumsum<0>( cv1, cv2 );
!   assert( equal( csum, cv2.get(len - 1) ) );
  
  
    // sum of a matrix using scalars
--- 353,359 ----
    }
  
    cumsum<0>( cv1, cv2 );
!   test_assert( equal( csum, cv2.get(len - 1) ) );
  
  
    // sum of a matrix using scalars
*************** Test_cumsum()
*** 384,396 ****
    // sum across rows of a matrix
    cumsum<0>( m1, m2 );
    for ( index_type i = 0; i < rows; ++i )
!     assert( equal( rowsum[i], m2.get(i, cols - 1) ) );
  
  
    // sum across columns of a matrix
    cumsum<1>( m1, m2 );
    for ( index_type j = 0; j < cols; ++j )
!     assert( equal( colsum[j], m2.get(rows - 1, j) ) );
  }  
  
  
--- 384,396 ----
    // sum across rows of a matrix
    cumsum<0>( m1, m2 );
    for ( index_type i = 0; i < rows; ++i )
!     test_assert( equal( rowsum[i], m2.get(i, cols - 1) ) );
  
  
    // sum across columns of a matrix
    cumsum<1>( m1, m2 );
    for ( index_type j = 0; j < cols; ++j )
!     test_assert( equal( colsum[j], m2.get(rows - 1, j) ) );
  }  
  
  
*************** Test_modulate( const length_type m )
*** 418,424 ****
        r.put( i, j, v.get(i, j) * exp(complex<T3>(0, (i * m + j) * nu + phi)) );
    }
  
!   assert( error_db(r, w) < -100 );
  }
  
  
--- 418,424 ----
        r.put( i, j, v.get(i, j) * exp(complex<T3>(0, (i * m + j) * nu + phi)) );
    }
  
!   test_assert( error_db(r, w) < -100 );
  }
  
  
*************** Test_outer( T alpha, const length_type m
*** 443,450 ****
      for ( vsip::index_type i = 0; i < r.size(0); ++i )
        for ( vsip::index_type j = 0; j < r.size(1); ++j )
        {
!         assert( equal( r.get(i, j), c1.get(i, j) ) );
!         assert( equal( r.get(i, j), c2.get(i, j) ) );
        }
    }
  }
--- 443,450 ----
      for ( vsip::index_type i = 0; i < r.size(0); ++i )
        for ( vsip::index_type j = 0; j < r.size(1); ++j )
        {
!         test_assert( equal( r.get(i, j), c1.get(i, j) ) );
!         test_assert( equal( r.get(i, j), c2.get(i, j) ) );
        }
    }
  }
*************** main(int argc, char** argv)
*** 478,489 ****
    Matrix<>
      kron_mn(kron (static_cast<scalar_f>(2.0), matrix_m, matrix_n));
  
!   assert( kron_mn.size(0) == 2 * 4 );
!   assert( kron_mn.size(1) == 3 * 5 );
  
    for ( index_type a = 2 * 4; a-- > 0; )
      for ( index_type b = 3 * 5; b-- > 0; )
!       assert( equal( kron_mn.get( a, b ),
                  static_cast<scalar_f>(7 * 11 * 2.0) ) );
  
  
--- 478,489 ----
    Matrix<>
      kron_mn(kron (static_cast<scalar_f>(2.0), matrix_m, matrix_n));
  
!   test_assert( kron_mn.size(0) == 2 * 4 );
!   test_assert( kron_mn.size(1) == 3 * 5 );
  
    for ( index_type a = 2 * 4; a-- > 0; )
      for ( index_type b = 3 * 5; b-- > 0; )
!       test_assert( equal( kron_mn.get( a, b ),
                  static_cast<scalar_f>(7 * 11 * 2.0) ) );
  
  
Index: tests/output.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/output.hpp,v
retrieving revision 1.1
diff -c -p -r1.1 output.hpp
*** tests/output.hpp	1 Apr 2005 21:25:15 -0000	1.1
--- tests/output.hpp	20 Dec 2005 12:39:20 -0000
***************
*** 27,32 ****
--- 27,35 ----
  
  /// Write a Domain<1> object to an output stream.
  
+ namespace vsip
+ {
+ 
  inline
  std::ostream&
  operator<<(
*************** operator<<(
*** 133,136 ****
--- 136,141 ----
    return out;
  }
  
+ } // namespace vsip
+ 
  #endif // VSIP_OUTPUT_HPP
Index: tests/par_expr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/par_expr.cpp,v
retrieving revision 1.9
diff -c -p -r1.9 par_expr.cpp
*** tests/par_expr.cpp	5 Dec 2005 19:19:19 -0000	1.9
--- tests/par_expr.cpp	20 Dec 2005 12:39:20 -0000
*************** test_distributed_expr(
*** 186,209 ****
  
    Check_identity<Dim> checker1(dom, 5, 3);
    foreach_point(chk1, checker1);
!   assert(checker1.good());
  
    Check_identity<Dim> checker2(dom, 1, 1);
    foreach_point(chk2, checker2);
    foreach_point(Z2, checker2);
    foreach_point(Z4, checker2);
!   assert(checker2.good());
  
    Check_identity<Dim> checker3(dom, -2, -1);
    foreach_point(Z3, checker3);
!   assert(checker3.good());
  
    if (map_res.impl_rank() == 0) // rank(map_res) == 0
    {
      typename view0_t::local_type local_view = chk1.local();
  
      // Check that local_view is in fact the entire view.
!     assert(extent_old(local_view) == extent_old(dom));
  
      // Check that each value is correct.
      bool good = true;
--- 186,209 ----
  
    Check_identity<Dim> checker1(dom, 5, 3);
    foreach_point(chk1, checker1);
!   test_assert(checker1.good());
  
    Check_identity<Dim> checker2(dom, 1, 1);
    foreach_point(chk2, checker2);
    foreach_point(Z2, checker2);
    foreach_point(Z4, checker2);
!   test_assert(checker2.good());
  
    Check_identity<Dim> checker3(dom, -2, -1);
    foreach_point(Z3, checker3);
!   test_assert(checker3.good());
  
    if (map_res.impl_rank() == 0) // rank(map_res) == 0
    {
      typename view0_t::local_type local_view = chk1.local();
  
      // Check that local_view is in fact the entire view.
!     test_assert(extent_old(local_view) == extent_old(dom));
  
      // Check that each value is correct.
      bool good = true;
*************** test_distributed_expr(
*** 230,236 ****
      }
  
      // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
!     assert(good);
    }
  }
  
--- 230,236 ----
      }
  
      // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
!     test_assert(good);
    }
  }
  
*************** test_distributed_expr3(
*** 315,321 ****
      typename view0_t::local_type local_view = chk1.local();
  
      // Check that local_view is in fact the entire view.
!     assert(extent_old(local_view) == extent_old(dom));
  
      // Check that each value is correct.
      bool good = true;
--- 315,321 ----
      typename view0_t::local_type local_view = chk1.local();
  
      // Check that local_view is in fact the entire view.
!     test_assert(extent_old(local_view) == extent_old(dom));
  
      // Check that each value is correct.
      bool good = true;
*************** test_distributed_expr3(
*** 344,350 ****
      }
  
      // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
!     assert(good);
    }
  }
  
--- 344,350 ----
      }
  
      // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
!     test_assert(good);
    }
  }
  
*************** test_distributed_expr3_capture(
*** 424,430 ****
      typename view0_t::local_type local_view = chk.local();
  
      // Check that local_view is in fact the entire view.
!     assert(extent_old(local_view) == extent_old(dom));
  
      // Check that each value is correct.
      bool good = true;
--- 424,430 ----
      typename view0_t::local_type local_view = chk.local();
  
      // Check that local_view is in fact the entire view.
!     test_assert(extent_old(local_view) == extent_old(dom));
  
      // Check that each value is correct.
      bool good = true;
*************** test_distributed_expr3_capture(
*** 453,459 ****
      }
  
      // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
!     assert(good);
    }
  }
  
--- 453,459 ----
      }
  
      // cout << "CHECK: " << (good ? "good" : "BAD") << endl;
!     test_assert(good);
    }
  }
  
Index: tests/random.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/random.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 random.cpp
*** tests/random.cpp	14 Sep 2005 18:01:32 -0000	1.1
--- tests/random.cpp	20 Dec 2005 12:39:20 -0000
*************** main ()
*** 358,364 ****
      {
        double a = rgen.randn();
        double b = vsip_randn_d( rstate );
!       assert( equal( a, b ) );
      }
    }
  
--- 358,364 ----
      {
        double a = rgen.randn();
        double b = vsip_randn_d( rstate );
!       test_assert( equal( a, b ) );
      }
    }
  
*************** main ()
*** 371,377 ****
      {
        double a = rgen.randn();
        double b = vsip_randn_d( rstate );
!       assert( equal( a, b ) );
      }
    }
  
--- 371,377 ----
      {
        double a = rgen.randn();
        double b = vsip_randn_d( rstate );
!       test_assert( equal( a, b ) );
      }
    }
  
*************** main ()
*** 384,390 ****
      {
        double a = rgen.randu();
        double b = vsip_randu_d( rstate );
!       assert( equal( a, b ) );
      }
    }
  
--- 384,390 ----
      {
        double a = rgen.randu();
        double b = vsip_randu_d( rstate );
!       test_assert( equal( a, b ) );
      }
    }
  
*************** main ()
*** 397,403 ****
      {
        double a = rgen.randu();
        double b = vsip_randu_d( rstate );
!       assert( equal( a, b ) );
      }
    }
  
--- 397,403 ----
      {
        double a = rgen.randu();
        double b = vsip_randu_d( rstate );
!       test_assert( equal( a, b ) );
      }
    }
  
*************** main ()
*** 414,420 ****
        complex<double> a = rgen.randn();
        vsip_cscalar_d z = vsip_crandn_d( rstate );
        complex<double> b(z.r, z.i);
!       assert( equal( a, b ) );
      }
    }
  
--- 414,420 ----
        complex<double> a = rgen.randn();
        vsip_cscalar_d z = vsip_crandn_d( rstate );
        complex<double> b(z.r, z.i);
!       test_assert( equal( a, b ) );
      }
    }
  
*************** main ()
*** 428,434 ****
        complex<double> a = rgen.randn();
        vsip_cscalar_d z = vsip_crandn_d( rstate );
        complex<double> b(z.r, z.i);
!       assert( equal( a, b ) );
      }
    }
  
--- 428,434 ----
        complex<double> a = rgen.randn();
        vsip_cscalar_d z = vsip_crandn_d( rstate );
        complex<double> b(z.r, z.i);
!       test_assert( equal( a, b ) );
      }
    }
  
*************** main ()
*** 442,448 ****
        complex<double> a = rgen.randu();
        vsip_cscalar_d z = vsip_crandu_d( rstate );
        complex<double> b(z.r, z.i);
!       assert( equal( a, b ) );
      }
    }
  
--- 442,448 ----
        complex<double> a = rgen.randu();
        vsip_cscalar_d z = vsip_crandu_d( rstate );
        complex<double> b(z.r, z.i);
!       test_assert( equal( a, b ) );
      }
    }
  
*************** main ()
*** 456,462 ****
        complex<double> a = rgen.randu();
        vsip_cscalar_d z = vsip_crandu_d( rstate );
        complex<double> b(z.r, z.i);
!       assert( equal( a, b ) );
      }
    }
  
--- 456,462 ----
        complex<double> a = rgen.randu();
        vsip_cscalar_d z = vsip_crandu_d( rstate );
        complex<double> b(z.r, z.i);
!       test_assert( equal( a, b ) );
      }
    }
  
*************** main ()
*** 475,481 ****
  
    for ( index_type i = 0; i < m1.size(0); ++i )
      for ( index_type j = 0; j < m1.size(1); ++j )
!       assert( equal( v1.get(i * m1.size(1) + j), m1.get(i, j) ) );
  
    // Normal
    vsip::Rand<>::vector_type v2 = vgen.randn(3 * 9);
--- 475,481 ----
  
    for ( index_type i = 0; i < m1.size(0); ++i )
      for ( index_type j = 0; j < m1.size(1); ++j )
!       test_assert( equal( v1.get(i * m1.size(1) + j), m1.get(i, j) ) );
  
    // Normal
    vsip::Rand<>::vector_type v2 = vgen.randn(3 * 9);
*************** main ()
*** 483,489 ****
  
    for ( index_type i = 0; i < m2.size(0); ++i )
      for ( index_type j = 0; j < m2.size(1); ++j )
!       assert( equal( v2.get(i * m2.size(1) + j), m2.get(i, j) ) );
  
  
    return EXIT_SUCCESS;
--- 483,489 ----
  
    for ( index_type i = 0; i < m2.size(0); ++i )
      for ( index_type j = 0; j < m2.size(1); ++j )
!       test_assert( equal( v2.get(i * m2.size(1) + j), m2.get(i, j) ) );
  
  
    return EXIT_SUCCESS;
Index: tests/reductions-bool.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/reductions-bool.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 reductions-bool.cpp
*** tests/reductions-bool.cpp	22 Jul 2005 17:51:13 -0000	1.1
--- tests/reductions-bool.cpp	20 Dec 2005 12:39:20 -0000
*************** simple_tests()
*** 27,46 ****
  {
    Vector<bool> bvec(4, true);
  
!   assert(alltrue(bvec) == true);
!   assert(anytrue(bvec) == true);
  
    bvec(2) = false;
  
!   assert(alltrue(bvec) == false);
!   assert(anytrue(bvec) == true);
  
    bvec(0) = false;
    bvec(1) = false;
    bvec(3) = false;
  
!   assert(alltrue(bvec) == false);
!   assert(anytrue(bvec) == false);
  
    Vector<int> vec(3);
  
--- 27,46 ----
  {
    Vector<bool> bvec(4, true);
  
!   test_assert(alltrue(bvec) == true);
!   test_assert(anytrue(bvec) == true);
  
    bvec(2) = false;
  
!   test_assert(alltrue(bvec) == false);
!   test_assert(anytrue(bvec) == true);
  
    bvec(0) = false;
    bvec(1) = false;
    bvec(3) = false;
  
!   test_assert(alltrue(bvec) == false);
!   test_assert(anytrue(bvec) == false);
  
    Vector<int> vec(3);
  
*************** simple_tests()
*** 48,55 ****
    vec(1) = 0x119f;
    vec(2) = 0x92f7;
  
!   assert(alltrue(vec) == 0x0097);
!   assert(anytrue(vec) == 0x93ff);
  }
  
  
--- 48,55 ----
    vec(1) = 0x119f;
    vec(2) = 0x92f7;
  
!   test_assert(alltrue(vec) == 0x0097);
!   test_assert(anytrue(vec) == 0x93ff);
  }
  
  
*************** test_bool(Domain<Dim> const& dom)
*** 69,88 ****
    StoreT      false_store(dom, false);
    length_type size = true_store.view.size();
  
!   assert(alltrue(true_store.view) == true);
!   assert(anytrue(true_store.view) == true);
  
!   assert(alltrue(false_store.view) == false);
!   assert(anytrue(false_store.view) == false);
  
    put_nth(true_store.view, size-1, false);
    put_nth(false_store.view, size-1, true);
  
!   assert(alltrue(true_store.view) == false);
!   assert(anytrue(true_store.view) == true);
  
!   assert(alltrue(false_store.view) == false);
!   assert(anytrue(false_store.view) == true);
  }
  
  
--- 69,88 ----
    StoreT      false_store(dom, false);
    length_type size = true_store.view.size();
  
!   test_assert(alltrue(true_store.view) == true);
!   test_assert(anytrue(true_store.view) == true);
  
!   test_assert(alltrue(false_store.view) == false);
!   test_assert(anytrue(false_store.view) == false);
  
    put_nth(true_store.view, size-1, false);
    put_nth(false_store.view, size-1, true);
  
!   test_assert(alltrue(true_store.view) == false);
!   test_assert(anytrue(true_store.view) == true);
  
!   test_assert(alltrue(false_store.view) == false);
!   test_assert(anytrue(false_store.view) == true);
  }
  
  
Index: tests/reductions-idx.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/reductions-idx.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 reductions-idx.cpp
*** tests/reductions-idx.cpp	22 Jul 2005 17:51:13 -0000	1.1
--- tests/reductions-idx.cpp	20 Dec 2005 12:39:20 -0000
*************** test_maxval_v(Domain<1> const& dom, leng
*** 46,53 ****
      vec(i) = nval;
      
      val = maxval(vec, idx);
!     assert(equal(val, nval));
!     assert(idx == i);
    }
  }
  
--- 46,53 ----
      vec(i) = nval;
      
      val = maxval(vec, idx);
!     test_assert(equal(val, nval));
!     test_assert(idx == i);
    }
  }
  
*************** test_maxval(Domain<Dim> const& dom, leng
*** 75,82 ****
      put_nth(store.view, i, nval);
      
      val = maxval(store.view, idx);
!     assert(equal(val, nval));
!     assert(nth_from_index(store.view, idx) == i);
    }
  }
  
--- 75,82 ----
      put_nth(store.view, i, nval);
      
      val = maxval(store.view, idx);
!     test_assert(equal(val, nval));
!     test_assert(nth_from_index(store.view, idx) == i);
    }
  }
  
*************** test_minval(Domain<Dim> const& dom, leng
*** 129,136 ****
      put_nth(store.view, i, nval);
      
      val = minval(store.view, idx);
!     assert(equal(val, nval));
!     assert(nth_from_index(store.view, idx) == i);
    }
  }
  
--- 129,136 ----
      put_nth(store.view, i, nval);
      
      val = minval(store.view, idx);
!     test_assert(equal(val, nval));
!     test_assert(nth_from_index(store.view, idx) == i);
    }
  }
  
*************** test_mgval(Domain<Dim> const& dom, lengt
*** 187,198 ****
      put_nth(store.view, j, small);
      
      scalar_type lval = maxmgval(store.view, idx);
!     assert(equal(lval, mag(large)));
!     assert(nth_from_index(store.view, idx) == i);
  
      scalar_type sval = minmgval(store.view, idx);
!     assert(equal(sval, mag(small)));
!     assert(nth_from_index(store.view, idx) == j);
    }
  }
  
--- 187,198 ----
      put_nth(store.view, j, small);
      
      scalar_type lval = maxmgval(store.view, idx);
!     test_assert(equal(lval, mag(large)));
!     test_assert(nth_from_index(store.view, idx) == i);
  
      scalar_type sval = minmgval(store.view, idx);
!     test_assert(equal(sval, mag(small)));
!     test_assert(nth_from_index(store.view, idx) == j);
    }
  }
  
*************** test_mgsqval(Domain<Dim> const& dom, len
*** 249,260 ****
      put_nth(store.view, j, small);
      
      scalar_type lval = maxmgsqval(store.view, idx);
!     assert(equal(lval, magsq(large)));
!     assert(nth_from_index(store.view, idx) == i);
  
      scalar_type sval = minmgsqval(store.view, idx);
!     assert(equal(sval, magsq(small)));
!     assert(nth_from_index(store.view, idx) == j);
    }
  }
  
--- 249,260 ----
      put_nth(store.view, j, small);
      
      scalar_type lval = maxmgsqval(store.view, idx);
!     test_assert(equal(lval, magsq(large)));
!     test_assert(nth_from_index(store.view, idx) == i);
  
      scalar_type sval = minmgsqval(store.view, idx);
!     test_assert(equal(sval, magsq(small)));
!     test_assert(nth_from_index(store.view, idx) == j);
    }
  }
  
*************** simple_mgval_c()
*** 291,314 ****
     T                   val;
  
     val = maxmgval(vec, idx);
!    assert(equal(val, T(5)));
!    // assert(idx == 0);
  
     val = minmgval(vec, idx);
!    assert(equal(val, T(5)));
!    // assert(idx == 0);
  
  
     vec(1) = complex<T>(6, 8);
     vec(2) = complex<T>(0.3, 0.4);
  
     val = maxmgval(vec, idx);
!    assert(equal(val, T(10)));
!    assert(idx == 1);
  
     val = minmgval(vec, idx);
!    assert(equal(val, T(0.5)));
!    assert(idx == 2);
  }
  
  
--- 291,314 ----
     T                   val;
  
     val = maxmgval(vec, idx);
!    test_assert(equal(val, T(5)));
!    // test_assert(idx == 0);
  
     val = minmgval(vec, idx);
!    test_assert(equal(val, T(5)));
!    // test_assert(idx == 0);
  
  
     vec(1) = complex<T>(6, 8);
     vec(2) = complex<T>(0.3, 0.4);
  
     val = maxmgval(vec, idx);
!    test_assert(equal(val, T(10)));
!    test_assert(idx == 1);
  
     val = minmgval(vec, idx);
!    test_assert(equal(val, T(0.5)));
!    test_assert(idx == 2);
  }
  
  
Index: tests/reductions.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/reductions.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 reductions.cpp
*** tests/reductions.cpp	28 Jul 2005 20:39:17 -0000	1.3
--- tests/reductions.cpp	20 Dec 2005 12:39:20 -0000
*************** simple_tests()
*** 32,41 ****
    vec(2) = 2.;
    vec(3) = 3.;
  
!   assert(equal(sumval(vec),    6.0f));
!   assert(equal(meanval(vec),   1.5f));
!   assert(equal(sumsqval(vec), 14.0f));
!   assert(equal(meansqval(vec), 3.5f));
  
    Matrix<double> mat(2, 2);
  
--- 32,41 ----
    vec(2) = 2.;
    vec(3) = 3.;
  
!   test_assert(equal(sumval(vec),    6.0f));
!   test_assert(equal(meanval(vec),   1.5f));
!   test_assert(equal(sumsqval(vec), 14.0f));
!   test_assert(equal(meansqval(vec), 3.5f));
  
    Matrix<double> mat(2, 2);
  
*************** simple_tests()
*** 44,53 ****
    mat(1, 0) = 3.;
    mat(1, 1) = 4.;
  
!   assert(equal(sumval(mat),   10.0));
!   assert(equal(meanval(mat),   2.5));
!   assert(equal(sumsqval(mat), 30.0));
!   assert(equal(meansqval(mat), 7.5));
  
    Tensor<float> ten(2, 1, 2);
  
--- 44,53 ----
    mat(1, 0) = 3.;
    mat(1, 1) = 4.;
  
!   test_assert(equal(sumval(mat),   10.0));
!   test_assert(equal(meanval(mat),   2.5));
!   test_assert(equal(sumsqval(mat), 30.0));
!   test_assert(equal(meansqval(mat), 7.5));
  
    Tensor<float> ten(2, 1, 2);
  
*************** simple_tests()
*** 56,75 ****
    ten(1, 0, 0) = 4.;
    ten(1, 0, 1) = 5.;
  
!   assert(equal(sumval(ten),    14.0f));
!   assert(equal(meanval(ten),    3.5f));
!   assert(equal(sumsqval(ten),  54.0f));
!   assert(equal(meansqval(ten), 13.5f));
  
    Vector<complex<float> > cvec(2);
  
    cvec(0) = complex<float>(3.f,  4.f); // -7 + 24i
    cvec(1) = complex<float>(3.f, -4.f); // -7 - 24i
  
!   assert(equal(sumval(cvec),    complex<float>(6.0f, 0.0f)));
!   // assert(equal(meanval(cvec), complex<float>(3.f, 0.f)));
!   assert(equal(sumsqval(cvec),  complex<float>(-14.0f, 0.0f)));
!   assert(equal(meansqval(cvec), 25.0f));
  
  
    Vector<bool> bvec(4);
--- 56,75 ----
    ten(1, 0, 0) = 4.;
    ten(1, 0, 1) = 5.;
  
!   test_assert(equal(sumval(ten),    14.0f));
!   test_assert(equal(meanval(ten),    3.5f));
!   test_assert(equal(sumsqval(ten),  54.0f));
!   test_assert(equal(meansqval(ten), 13.5f));
  
    Vector<complex<float> > cvec(2);
  
    cvec(0) = complex<float>(3.f,  4.f); // -7 + 24i
    cvec(1) = complex<float>(3.f, -4.f); // -7 - 24i
  
!   test_assert(equal(sumval(cvec),    complex<float>(6.0f, 0.0f)));
!   // test_assert(equal(meanval(cvec), complex<float>(3.f, 0.f)));
!   test_assert(equal(sumsqval(cvec),  complex<float>(-14.0f, 0.0f)));
!   test_assert(equal(meansqval(cvec), 25.0f));
  
  
    Vector<bool> bvec(4);
*************** simple_tests()
*** 79,85 ****
    bvec(2) = false;
    bvec(3) = true;
  
!   assert(equal(sumval(bvec), static_cast<length_type>(3)));
  }
  
  
--- 79,85 ----
    bvec(2) = false;
    bvec(3) = true;
  
!   test_assert(equal(sumval(bvec), static_cast<length_type>(3)));
  }
  
  
*************** test_sumval(Domain<Dim> const& dom, leng
*** 112,118 ****
      put_nth(store.view, i, nval);
      
      T val = sumval(store.view);
!     assert(equal(val, expected));
    }
  }
  
--- 112,118 ----
      put_nth(store.view, i, nval);
      
      T val = sumval(store.view);
!     test_assert(equal(val, expected));
    }
  }
  
*************** test_sumval_bool(Domain<Dim> const& dom,
*** 166,172 ****
      put_nth(store.view, i, nval);
      
      length_type val = sumval(store.view);
!     assert(equal(val, expected));
    }
  }
  
--- 166,172 ----
      put_nth(store.view, i, nval);
      
      length_type val = sumval(store.view);
!     test_assert(equal(val, expected));
    }
  }
  
*************** test_sumsqval(Domain<Dim> const& dom, le
*** 223,229 ****
      put_nth(store.view, i, nval);
      
      T val = sumsqval(store.view);
!     assert(equal(val, expected));
    }
  }
  
--- 223,229 ----
      put_nth(store.view, i, nval);
      
      T val = sumsqval(store.view);
!     test_assert(equal(val, expected));
    }
  }
  
*************** test_meanval(Domain<Dim> const& dom, len
*** 277,284 ****
      
      T sval = sumval(store.view);
      T mval = meanval(store.view);
!     assert(equal(sval, expected));
!     assert(equal(mval, expected/static_cast<T>(store.view.size())));
    }
  }
  
--- 277,284 ----
      
      T sval = sumval(store.view);
      T mval = meanval(store.view);
!     test_assert(equal(sval, expected));
!     test_assert(equal(mval, expected/static_cast<T>(store.view.size())));
    }
  }
  
*************** test_meansqval(Domain<Dim> const& dom, l
*** 334,340 ****
      put_nth(store.view, i, nval);
      
      result_type mval = meansqval(store.view);
!     assert(equal(mval, expected/static_cast<result_type>(store.view.size())));
    }
  }
  
--- 334,340 ----
      put_nth(store.view, i, nval);
      
      result_type mval = meansqval(store.view);
!     test_assert(equal(mval, expected/static_cast<result_type>(store.view.size())));
    }
  }
  
Index: tests/refcount.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/refcount.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 refcount.cpp
*** tests/refcount.cpp	18 Jun 2005 16:40:45 -0000	1.4
--- tests/refcount.cpp	20 Dec 2005 12:39:21 -0000
***************
*** 11,18 ****
  ***********************************************************************/
  
  #include <iostream>
- #include <cassert>
  #include <vsip/impl/refcount.hpp>
  
  using namespace std;
  using namespace vsip;
--- 11,18 ----
  ***********************************************************************/
  
  #include <iostream>
  #include <vsip/impl/refcount.hpp>
+ #include "test.hpp"
  
  using namespace std;
  using namespace vsip;
*************** int Test_class::count_ = 0;
*** 59,78 ****
  void 
  test_simple()
  {
!   assert(Test_class::count_ == 0);
  
    Test_class* tc1 = new Test_class(); // tc1 refcount starts at 1
    Test_class* tc2 = new Test_class(); // tc2 refcount starts at 1
  
!   assert(Test_class::count_ == 2);
  
    tc1->decrement_count();
  
!   assert(Test_class::count_ == 1);
  
    tc2->decrement_count();
  
!   assert(Test_class::count_ == 0);
  }
  
  
--- 59,78 ----
  void 
  test_simple()
  {
!   test_assert(Test_class::count_ == 0);
  
    Test_class* tc1 = new Test_class(); // tc1 refcount starts at 1
    Test_class* tc2 = new Test_class(); // tc2 refcount starts at 1
  
!   test_assert(Test_class::count_ == 2);
  
    tc1->decrement_count();
  
!   test_assert(Test_class::count_ == 1);
  
    tc2->decrement_count();
  
!   test_assert(Test_class::count_ == 0);
  }
  
  
*************** deref(Test_class*& tc)
*** 96,102 ****
  void 
  test_chain_1()
  {
!   assert(Test_class::count_ == 0);
  
    Test_class* tc_0 = new Test_class();
    Test_class* tc_1 = new Test_class(tc_0); deref(tc_0);
--- 96,102 ----
  void 
  test_chain_1()
  {
!   test_assert(Test_class::count_ == 0);
  
    Test_class* tc_0 = new Test_class();
    Test_class* tc_1 = new Test_class(tc_0); deref(tc_0);
*************** test_chain_1()
*** 106,116 ****
  
    // tc_4 reference count is 1
  
!   assert(Test_class::count_ == 5);
  
    tc_4->decrement_count();
  
!   assert(Test_class::count_ == 0);
  }
  
  
--- 106,116 ----
  
    // tc_4 reference count is 1
  
!   test_assert(Test_class::count_ == 5);
  
    tc_4->decrement_count();
  
!   test_assert(Test_class::count_ == 0);
  }
  
  
*************** test_chain_1()
*** 120,126 ****
  void 
  test_chain_2(int tc)
  {
!   assert(Test_class::count_ == 0);
  
    Test_class* tc_0 = new Test_class();
    Test_class* tc_1 = new Test_class(tc_0); deref(tc_0);
--- 120,126 ----
  void 
  test_chain_2(int tc)
  {
!   test_assert(Test_class::count_ == 0);
  
    Test_class* tc_0 = new Test_class();
    Test_class* tc_1 = new Test_class(tc_0); deref(tc_0);
*************** test_chain_2(int tc)
*** 130,162 ****
  
    // tc_4 reference count is 1
  
!   assert(Test_class::count_ == 5);
  
    Test_class* tc_2x = new Test_class(tc_1); deref(tc_1);
    // tc_2x reference count is 1
  
!   assert(Test_class::count_ == 6);
  
  
    if (tc == 0)
    {
      tc_4->decrement_count();
  
!     assert(Test_class::count_ == 3);
  
      tc_2x->decrement_count();
  
!     assert(Test_class::count_ == 0);
    }
    else
    {
      tc_2x->decrement_count();
  
!     assert(Test_class::count_ == 5);
  
      tc_4->decrement_count();
  
!     assert(Test_class::count_ == 0);
    }
  }
  
--- 130,162 ----
  
    // tc_4 reference count is 1
  
!   test_assert(Test_class::count_ == 5);
  
    Test_class* tc_2x = new Test_class(tc_1); deref(tc_1);
    // tc_2x reference count is 1
  
!   test_assert(Test_class::count_ == 6);
  
  
    if (tc == 0)
    {
      tc_4->decrement_count();
  
!     test_assert(Test_class::count_ == 3);
  
      tc_2x->decrement_count();
  
!     test_assert(Test_class::count_ == 0);
    }
    else
    {
      tc_2x->decrement_count();
  
!     test_assert(Test_class::count_ == 5);
  
      tc_4->decrement_count();
  
!     test_assert(Test_class::count_ == 0);
    }
  }
  
*************** test_chain_2(int tc)
*** 169,182 ****
  void 
  test_copy_cons()
  {
!   assert(Test_class::count_ == 0);
    {
      Test_class tc1;	// create object on stack
  #ifdef ILLEGAL_1
      Test_class tc2(tc1);	// copy it
  #endif
    }
!   assert(Test_class::count_ == 0);
  }
  
  
--- 169,182 ----
  void 
  test_copy_cons()
  {
!   test_assert(Test_class::count_ == 0);
    {
      Test_class tc1;	// create object on stack
  #ifdef ILLEGAL_1
      Test_class tc2(tc1);	// copy it
  #endif
    }
!   test_assert(Test_class::count_ == 0);
  }
  
  
*************** test_copy_cons()
*** 188,201 ****
  void 
  test_assign()
  {
!   assert(Test_class::count_ == 0);
    {
      Test_class tc1;	// create object on stack
  #ifdef ILLEGAL_2
      Test_class tc2 = tc1;	// assign it
  #endif
    }
!   assert(Test_class::count_ == 0);
  }
  
  
--- 188,201 ----
  void 
  test_assign()
  {
!   test_assert(Test_class::count_ == 0);
    {
      Test_class tc1;	// create object on stack
  #ifdef ILLEGAL_2
      Test_class tc2 = tc1;	// assign it
  #endif
    }
!   test_assert(Test_class::count_ == 0);
  }
  
  
Index: tests/regr_const_view_at_op.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/regr_const_view_at_op.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 regr_const_view_at_op.cpp
*** tests/regr_const_view_at_op.cpp	13 Sep 2005 16:49:28 -0000	1.1
--- tests/regr_const_view_at_op.cpp	20 Dec 2005 12:39:21 -0000
*************** check_view(Vector<T, Block> view)
*** 61,67 ****
  
    T sum = sum_view(view);
  
!   assert(equal(sum, value_type(view.size())));
  }
  
  
--- 61,67 ----
  
    T sum = sum_view(view);
  
!   test_assert(equal(sum, value_type(view.size())));
  }
  
  
*************** check_view(Matrix<T, Block> view)
*** 114,120 ****
  
    T sum = sum_view(view);
  
!   assert(equal(sum, value_type(view.size())));
  }
  
  
--- 114,120 ----
  
    T sum = sum_view(view);
  
!   test_assert(equal(sum, value_type(view.size())));
  }
  
  
*************** check_view(Tensor<T, Block> view)
*** 169,175 ****
  
    T sum = sum_view(view);
  
!   assert(equal(sum, value_type(view.size())));
  }
  
  
--- 169,175 ----
  
    T sum = sum_view(view);
  
!   test_assert(equal(sum, value_type(view.size())));
  }
  
  
Index: tests/regr_conv_to_subview.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/regr_conv_to_subview.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 regr_conv_to_subview.cpp
*** tests/regr_conv_to_subview.cpp	5 Aug 2005 21:33:00 -0000	1.1
--- tests/regr_conv_to_subview.cpp	20 Dec 2005 12:39:21 -0000
*************** test_conv_nonsym_split(
*** 94,112 ****
    conv_type conv1(coeff1, Domain<1>(N), D);
    conv_type conv2(coeff2, Domain<1>(N), D);
  
!   assert(conv1.symmetry() == symmetry);
!   assert(conv1.support()  == support);
!   assert(conv1.kernel_size().size()  == M);
!   assert(conv1.filter_order().size() == M);
!   assert(conv1.input_size().size()   == N);
!   assert(conv1.output_size().size()  == P);
! 
!   assert(conv2.symmetry() == symmetry);
!   assert(conv2.support()  == support);
!   assert(conv2.kernel_size().size()  == M);
!   assert(conv2.filter_order().size() == M);
!   assert(conv2.input_size().size()   == N);
!   assert(conv2.output_size().size()  == P);
  
  
    Vector<T> in(N);
--- 94,112 ----
    conv_type conv1(coeff1, Domain<1>(N), D);
    conv_type conv2(coeff2, Domain<1>(N), D);
  
!   test_assert(conv1.symmetry() == symmetry);
!   test_assert(conv1.support()  == support);
!   test_assert(conv1.kernel_size().size()  == M);
!   test_assert(conv1.filter_order().size() == M);
!   test_assert(conv1.input_size().size()   == N);
!   test_assert(conv1.output_size().size()  == P);
! 
!   test_assert(conv2.symmetry() == symmetry);
!   test_assert(conv2.support()  == support);
!   test_assert(conv2.kernel_size().size()  == M);
!   test_assert(conv2.filter_order().size() == M);
!   test_assert(conv2.input_size().size()   == N);
!   test_assert(conv2.output_size().size()  == P);
  
  
    Vector<T> in(N);
*************** test_conv_nonsym_split(
*** 132,138 ****
      else
        val2 = in(i + shift - c2);
  
!     assert(equal(out(i), complex<T>(T(k1) * val1, T(k2) * val2)));
    }
  }
  
--- 132,138 ----
      else
        val2 = in(i + shift - c2);
  
!     test_assert(equal(out(i), complex<T>(T(k1) * val1, T(k2) * val2)));
    }
  }
  
Index: tests/regr_ext_subview_split.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/regr_ext_subview_split.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 regr_ext_subview_split.cpp
*** tests/regr_ext_subview_split.cpp	1 Sep 2005 20:02:16 -0000	1.1
--- tests/regr_ext_subview_split.cpp	20 Dec 2005 12:39:21 -0000
***************
*** 11,20 ****
    Included Files
  ***********************************************************************/
  
- #include <vsip/impl/fast-block.hpp>
  #include <vsip/vector.hpp>
  #include <vsip/matrix.hpp>
  #include <vsip/tensor.hpp>
  
  using namespace std;
  using namespace vsip;
--- 11,22 ----
    Included Files
  ***********************************************************************/
  
  #include <vsip/vector.hpp>
  #include <vsip/matrix.hpp>
  #include <vsip/tensor.hpp>
+ #include <vsip/impl/fast-block.hpp>
+ 
+ #include "test.hpp"
  
  using namespace std;
  using namespace vsip;
*************** test(stride_type        component_stride
*** 43,55 ****
  
  
    impl::Ext_data<block_t> ext(view.block());
!   assert(ext.cost()        == 0);
!   assert(ext.stride(Dim-1) == 1);
  
    stride_type str = 1;
    for (dimension_type d=0; d<Dim; ++d)
    {
!     assert(ext.stride(Dim-d-1) == str);
      str *= dom[Dim-d-1].size();
    }
  
--- 45,57 ----
  
  
    impl::Ext_data<block_t> ext(view.block());
!   test_assert(ext.cost()        == 0);
!   test_assert(ext.stride(Dim-1) == 1);
  
    stride_type str = 1;
    for (dimension_type d=0; d<Dim; ++d)
    {
!     test_assert(ext.stride(Dim-d-1) == str);
      str *= dom[Dim-d-1].size();
    }
  
*************** test(stride_type        component_stride
*** 59,71 ****
    impl::Ext_data<typename view_t::realview_type::block_type>
      extr(real.block());
  
!   assert(extr.cost()    == 0);
!   assert(extr.stride(Dim-1) == component_stride);
  
    str = component_stride;
    for (dimension_type d=0; d<Dim; ++d)
    {
!     assert(extr.stride(Dim-d-1) == str);
      str *= dom[Dim-d-1].size();
    }
  
--- 61,73 ----
    impl::Ext_data<typename view_t::realview_type::block_type>
      extr(real.block());
  
!   test_assert(extr.cost()    == 0);
!   test_assert(extr.stride(Dim-1) == component_stride);
  
    str = component_stride;
    for (dimension_type d=0; d<Dim; ++d)
    {
!     test_assert(extr.stride(Dim-d-1) == str);
      str *= dom[Dim-d-1].size();
    }
  
*************** test(stride_type        component_stride
*** 76,88 ****
    impl::Ext_data<typename view_t::imagview_type::block_type>
      exti(imag.block());
  
!   assert(exti.cost()    == 0);
!   assert(exti.stride(Dim-1) == component_stride);
  
    str = component_stride;
    for (dimension_type d=0; d<Dim; ++d)
    {
!     assert(exti.stride(Dim-d-1) == str);
      str *= dom[Dim-d-1].size();
    }
  }
--- 78,90 ----
    impl::Ext_data<typename view_t::imagview_type::block_type>
      exti(imag.block());
  
!   test_assert(exti.cost()    == 0);
!   test_assert(exti.stride(Dim-1) == component_stride);
  
    str = component_stride;
    for (dimension_type d=0; d<Dim; ++d)
    {
!     test_assert(exti.stride(Dim-d-1) == str);
      str *= dom[Dim-d-1].size();
    }
  }
Index: tests/regr_fft_temp_view.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/regr_fft_temp_view.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 regr_fft_temp_view.cpp
*** tests/regr_fft_temp_view.cpp	18 Sep 2005 22:03:43 -0000	1.1
--- tests/regr_fft_temp_view.cpp	20 Dec 2005 12:39:21 -0000
*************** test_fft(length_type size)
*** 53,85 ****
    // FFT: view -> view
    Z = T();
    fft(A, Z);
!   assert(equal(Z(0), T(size)));
  
    // FFT: view -> temporary view
    Z = T();
    fft(A, Z(Domain<1>(size)));
!   assert(equal(Z(0), T(size)));
  
    // FFT: temporary view -> view
    Z = T();
    fft(A(Domain<1>(size)), Z);
!   assert(equal(Z(0), T(size)));
  
    // FFT: temporary view -> temporary view
    Z = T();
    fft(A(Domain<1>(size)), Z(Domain<1>(size)));
!   assert(equal(Z(0), T(size)));
  
  
    // FFT: in-place into view
    Z = A;
    fft(Z);
!   assert(equal(Z(0), T(size)));
  
    // FFT: in-place into temporary view
    Z = A;
    fft(Z(Domain<1>(size)));
!   assert(equal(Z(0), T(size)));
  }
  
  
--- 53,85 ----
    // FFT: view -> view
    Z = T();
    fft(A, Z);
!   test_assert(equal(Z(0), T(size)));
  
    // FFT: view -> temporary view
    Z = T();
    fft(A, Z(Domain<1>(size)));
!   test_assert(equal(Z(0), T(size)));
  
    // FFT: temporary view -> view
    Z = T();
    fft(A(Domain<1>(size)), Z);
!   test_assert(equal(Z(0), T(size)));
  
    // FFT: temporary view -> temporary view
    Z = T();
    fft(A(Domain<1>(size)), Z(Domain<1>(size)));
!   test_assert(equal(Z(0), T(size)));
  
  
    // FFT: in-place into view
    Z = A;
    fft(Z);
!   test_assert(equal(Z(0), T(size)));
  
    // FFT: in-place into temporary view
    Z = A;
    fft(Z(Domain<1>(size)));
!   test_assert(equal(Z(0), T(size)));
  }
  
  
*************** test_fftm(length_type rows, length_type 
*** 107,139 ****
    // FFTM: view -> view
    Z = T();
    fftm(A, Z);
!   assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
  
    // FFTM: view -> temp view
    Z = T();
    fftm(A, Z(Domain<2>(rows, cols)));
!   assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
  
    // FFTM: view -> temp view
    Z = T();
    fftm(A(Domain<2>(rows, cols)), Z);
!   assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
  
    // FFTM: temp view -> temp view
    Z = T();
    fftm(A(Domain<2>(rows, cols)), Z(Domain<2>(rows, cols)));
!   assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
  
  
    // FFTM: in-place view
    Z = A;
    fftm(Z);
!   assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
  
    // FFTM: in-place temporary view
    Z = A;
    fftm(Z(Domain<2>(rows, cols)));
!   assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
  }
  
  
--- 107,139 ----
    // FFTM: view -> view
    Z = T();
    fftm(A, Z);
!   test_assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
  
    // FFTM: view -> temp view
    Z = T();
    fftm(A, Z(Domain<2>(rows, cols)));
!   test_assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
  
    // FFTM: view -> temp view
    Z = T();
    fftm(A(Domain<2>(rows, cols)), Z);
!   test_assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
  
    // FFTM: temp view -> temp view
    Z = T();
    fftm(A(Domain<2>(rows, cols)), Z(Domain<2>(rows, cols)));
!   test_assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
  
  
    // FFTM: in-place view
    Z = A;
    fftm(Z);
!   test_assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
  
    // FFTM: in-place temporary view
    Z = A;
    fftm(Z(Domain<2>(rows, cols)));
!   test_assert(equal(Z(0, 0), SD == 0 ? T(cols) : T(rows)));
  }
  
  
Index: tests/regr_proxy_lvalue_conv.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/regr_proxy_lvalue_conv.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 regr_proxy_lvalue_conv.cpp
*** tests/regr_proxy_lvalue_conv.cpp	23 Aug 2005 19:32:52 -0000	1.2
--- tests/regr_proxy_lvalue_conv.cpp	20 Dec 2005 12:39:21 -0000
*************** test_equal_op(
*** 45,52 ****
  
    for (index_type i=0; i<view.size(); ++i)
    {
!     assert(view(i) == static_cast<T>(i));
!     assert(view(i) == T(i));
    }
  }
  
--- 45,53 ----
  
    for (index_type i=0; i<view.size(); ++i)
    {
!     test_assert(static_cast<T>(i) == view(i));
!     test_assert(view(i) == static_cast<T>(i));
!     test_assert(view(i) == T(i));
    }
  }
  
*************** test_equal_fn(
*** 62,69 ****
  
    for (index_type i=0; i<view.size(); ++i)
    {
!     assert(equal(view(i), static_cast<T>(i)));
!     assert(equal(view(i), T(i)));
    }
  }
  
--- 63,71 ----
  
    for (index_type i=0; i<view.size(); ++i)
    {
!     test_assert(equal(view(i), static_cast<T>(i)));
!     test_assert(equal(static_cast<T>(i), view(i)));
!     test_assert(equal(view(i), T(i)));
    }
  }
  
Index: tests/regr_subview_exprs.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/regr_subview_exprs.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 regr_subview_exprs.cpp
*** tests/regr_subview_exprs.cpp	15 Sep 2005 11:14:57 -0000	1.1
--- tests/regr_subview_exprs.cpp	20 Dec 2005 12:39:21 -0000
*************** test_a1(length_type m, length_type n)
*** 42,48 ****
  
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<n; ++j)
!       assert(equal(dst(i, j), T(1)));
  }
  
  
--- 42,48 ----
  
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<n; ++j)
!       test_assert(equal(dst(i, j), T(1)));
  }
  
  
*************** test_a2(length_type m, length_type n)
*** 61,67 ****
  
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<n; ++j)
!       assert(equal(dst(i, j), T(1)));
  }
  
  
--- 61,67 ----
  
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<n; ++j)
!       test_assert(equal(dst(i, j), T(1)));
  }
  
  
*************** test_a3(length_type m, length_type n)
*** 80,86 ****
  
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<n; ++j)
!       assert(equal(dst(i, j), T(1)));
  }
  
  
--- 80,86 ----
  
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<n; ++j)
!       test_assert(equal(dst(i, j), T(1)));
  }
  
  
*************** test_a4(length_type m, length_type n)
*** 99,105 ****
  
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<n; ++j)
!       assert(equal(dst(i, j), T(1)));
  }
  
  
--- 99,105 ----
  
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<n; ++j)
!       test_assert(equal(dst(i, j), T(1)));
  }
  
  
*************** test_a5(length_type m, length_type n)
*** 121,127 ****
  
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<n; ++j)
!       assert(equal(dst(i, j), T(1)));
  }
  
  
--- 121,127 ----
  
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<n; ++j)
!       test_assert(equal(dst(i, j), T(1)));
  }
  
  
*************** test_b1(length_type m)
*** 138,144 ****
    dst = mag(src);
  
    for (index_type i=0; i<m; ++i)
!     assert(equal(dst(i), T(1)));
  }
  
  
--- 138,144 ----
    dst = mag(src);
  
    for (index_type i=0; i<m; ++i)
!     test_assert(equal(dst(i), T(1)));
  }
  
  
*************** test_b2(length_type m)
*** 155,161 ****
    dst = mag(-src);
  
    for (index_type i=0; i<m; ++i)
!     assert(equal(dst(i), T(1)));
  }
  
  
--- 155,161 ----
    dst = mag(-src);
  
    for (index_type i=0; i<m; ++i)
!     test_assert(equal(dst(i), T(1)));
  }
  
  
Index: tests/regr_view_index.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/regr_view_index.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 regr_view_index.cpp
*** tests/regr_view_index.cpp	14 Jul 2005 20:23:59 -0000	1.1
--- tests/regr_view_index.cpp	20 Dec 2005 12:39:21 -0000
*************** test_vector()
*** 33,39 ****
    Vector<T> vec(5, T());
  
    for (index_type i=0; i<vec.size(); ++i)
!     assert(equal(vec(i), T()));
  }
  
  
--- 33,39 ----
    Vector<T> vec(5, T());
  
    for (index_type i=0; i<vec.size(); ++i)
!     test_assert(equal(vec(i), T()));
  }
  
  
*************** test_matrix()
*** 46,52 ****
  
    for (index_type i=0; i<mat.size(0); ++i)
      for (index_type j=0; j<mat.size(1); ++j)
!       assert(equal(mat(i, j), T()));
  }
  
  
--- 46,52 ----
  
    for (index_type i=0; i<mat.size(0); ++i)
      for (index_type j=0; j<mat.size(1); ++j)
!       test_assert(equal(mat(i, j), T()));
  }
  
  
*************** test_tensor()
*** 60,66 ****
    for (index_type i=0; i<ten.size(0); ++i)
      for (index_type j=0; j<ten.size(1); ++j)
        for (index_type k=0; k<ten.size(2); ++k)
! 	assert(equal(ten(i, j, k), T()));
  }
  
  
--- 60,66 ----
    for (index_type i=0; i<ten.size(0); ++i)
      for (index_type j=0; j<ten.size(1); ++j)
        for (index_type k=0; k<ten.size(2); ++k)
! 	test_assert(equal(ten(i, j, k), T()));
  }
  
  
Index: tests/sal-assumptions.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/sal-assumptions.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 sal-assumptions.cpp
*** tests/sal-assumptions.cpp	11 Nov 2005 17:07:32 -0000	1.2
--- tests/sal-assumptions.cpp	20 Dec 2005 12:39:21 -0000
*************** check_split_layout()
*** 36,45 ****
      std::pair<float *, float *> p(real_value, imag_value);
      COMPLEX_SPLIT *pcs = (COMPLEX_SPLIT *) &p;
      
!     assert( pcs->realp == p.first );
!     assert( pcs->imagp == p.second );
!     assert( *pcs->realp == *p.first );
!     assert( *pcs->imagp == *p.second );
    }
  
    {
--- 36,45 ----
      std::pair<float *, float *> p(real_value, imag_value);
      COMPLEX_SPLIT *pcs = (COMPLEX_SPLIT *) &p;
      
!     test_assert( pcs->realp == p.first );
!     test_assert( pcs->imagp == p.second );
!     test_assert( *pcs->realp == *p.first );
!     test_assert( *pcs->imagp == *p.second );
    }
  
    {
*************** check_split_layout()
*** 48,57 ****
      std::pair<double *, double *> p(real_value, imag_value);
      DOUBLE_COMPLEX_SPLIT *pcs = (DOUBLE_COMPLEX_SPLIT *) &p;
      
!     assert( pcs->realp == p.first );
!     assert( pcs->imagp == p.second );
!     assert( *pcs->realp == *p.first );
!     assert( *pcs->imagp == *p.second );
    }
  }
  #endif
--- 48,57 ----
      std::pair<double *, double *> p(real_value, imag_value);
      DOUBLE_COMPLEX_SPLIT *pcs = (DOUBLE_COMPLEX_SPLIT *) &p;
      
!     test_assert( pcs->realp == p.first );
!     test_assert( pcs->imagp == p.second );
!     test_assert( *pcs->realp == *p.first );
!     test_assert( *pcs->imagp == *p.second );
    }
  }
  #endif
Index: tests/selgen-ramp.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/selgen-ramp.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 selgen-ramp.cpp
*** tests/selgen-ramp.cpp	26 Sep 2005 20:23:29 -0000	1.1
--- tests/selgen-ramp.cpp	20 Dec 2005 12:39:21 -0000
*************** test_ramp(T a, T b, length_type len)
*** 36,42 ****
    Vector<T> vec = ramp(a, b, len);
  
    for (index_type i=0; i<len; ++i)
!     assert(equal(a + T(i)*b,
  		 vec.get(i)));
  }
  
--- 36,42 ----
    Vector<T> vec = ramp(a, b, len);
  
    for (index_type i=0; i<len; ++i)
!     test_assert(equal(a + T(i)*b,
  		 vec.get(i)));
  }
  
Index: tests/selgen.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/selgen.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 selgen.cpp
*** tests/selgen.cpp	27 Sep 2005 22:44:40 -0000	1.1
--- tests/selgen.cpp	20 Dec 2005 12:39:21 -0000
*************** test_first()
*** 27,35 ****
    Vector<float> v1 = ramp(3.f, 2.f, 3);
    Vector<float> v2 = ramp(0.f, 3.f, 3);
    index_type i = first(0, std::less<float>(), v1, v2);
!   assert(equal(i, static_cast<index_type>(3)));
    i = first(5, std::less<float>(), v1, v2);
!   assert(equal(i, static_cast<index_type>(5)));
  }
  
  void 
--- 27,35 ----
    Vector<float> v1 = ramp(3.f, 2.f, 3);
    Vector<float> v2 = ramp(0.f, 3.f, 3);
    index_type i = first(0, std::less<float>(), v1, v2);
!   test_assert(equal(i, static_cast<index_type>(3)));
    i = first(5, std::less<float>(), v1, v2);
!   test_assert(equal(i, static_cast<index_type>(5)));
  }
  
  void 
*************** test_indexbool()
*** 41,47 ****
    v.put(4, true);
    Vector<Index<1> > indices1(5);
    length_type length = indexbool(v, indices1);
!   assert(length == 3 && 
  	 indices1.get(0) == Index<1>(0) && 
  	 indices1.get(1) == Index<1>(2) &&
  	 indices1.get(2) == Index<1>(4));
--- 41,47 ----
    v.put(4, true);
    Vector<Index<1> > indices1(5);
    length_type length = indexbool(v, indices1);
!   test_assert(length == 3 && 
  	 indices1.get(0) == Index<1>(0) && 
  	 indices1.get(1) == Index<1>(2) &&
  	 indices1.get(2) == Index<1>(4));
*************** test_indexbool()
*** 52,58 ****
    m.put(4, 2, true);
    Vector<Index<2> > indices2(5);
    length = indexbool(m, indices2);
!   assert(length == 3 && 
  	 indices2.get(0) == Index<2>(0, 2) && 
  	 indices2.get(1) == Index<2>(2, 3) &&
  	 indices2.get(2) == Index<2>(4, 2));
--- 52,58 ----
    m.put(4, 2, true);
    Vector<Index<2> > indices2(5);
    length = indexbool(m, indices2);
!   test_assert(length == 3 && 
  	 indices2.get(0) == Index<2>(0, 2) && 
  	 indices2.get(1) == Index<2>(2, 3) &&
  	 indices2.get(2) == Index<2>(4, 2));
*************** void test_gather_scatter()
*** 72,85 ****
    put(m, indices.get(3), 4.f);
  
    Vector<float> v = gather(m, indices);
!   assert(equal(v.get(0), 1.f));
!   assert(equal(v.get(1), 2.f));
!   assert(equal(v.get(2), 3.f));
!   assert(equal(v.get(3), 4.f));
  
    Matrix<float> m2(5, 5, 0.);
    scatter(v, indices, m2);
!   assert(view_equal(m, m2));
  }
  
  void
--- 72,85 ----
    put(m, indices.get(3), 4.f);
  
    Vector<float> v = gather(m, indices);
!   test_assert(equal(v.get(0), 1.f));
!   test_assert(equal(v.get(1), 2.f));
!   test_assert(equal(v.get(2), 3.f));
!   test_assert(equal(v.get(3), 4.f));
  
    Matrix<float> m2(5, 5, 0.);
    scatter(v, indices, m2);
!   test_assert(view_equal(m, m2));
  }
  
  void
*************** test_clip()
*** 87,97 ****
  {
    Vector<float> v = ramp(0.f, 1.f, 5);
    Vector<float> result = clip(v, 1.1f, 2.9f, 1.1f, 2.9f);
!   assert(equal(result.get(0), 1.1f));
!   assert(equal(result.get(1), 1.1f));
!   assert(equal(result.get(2), 2.f));
!   assert(equal(result.get(3), 2.9f));
!   assert(equal(result.get(4), 2.9f));
  }
  
  void
--- 87,97 ----
  {
    Vector<float> v = ramp(0.f, 1.f, 5);
    Vector<float> result = clip(v, 1.1f, 2.9f, 1.1f, 2.9f);
!   test_assert(equal(result.get(0), 1.1f));
!   test_assert(equal(result.get(1), 1.1f));
!   test_assert(equal(result.get(2), 2.f));
!   test_assert(equal(result.get(3), 2.9f));
!   test_assert(equal(result.get(4), 2.9f));
  }
  
  void
*************** test_invclip()
*** 99,109 ****
  {
    Vector<float> v = ramp(0.f, 1.f, 5);
    Vector<float> result = invclip(v, 1.1f, 2.1f, 3.1f, 1.1f, 3.1f);
!   assert(equal(result.get(0), 0.f));
!   assert(equal(result.get(1), 1.f));
!   assert(equal(result.get(2), 1.1f));
!   assert(equal(result.get(3), 3.1f));
!   assert(equal(result.get(4), 4.f));
  }
  
  void
--- 99,109 ----
  {
    Vector<float> v = ramp(0.f, 1.f, 5);
    Vector<float> result = invclip(v, 1.1f, 2.1f, 3.1f, 1.1f, 3.1f);
!   test_assert(equal(result.get(0), 0.f));
!   test_assert(equal(result.get(1), 1.f));
!   test_assert(equal(result.get(2), 1.1f));
!   test_assert(equal(result.get(3), 3.1f));
!   test_assert(equal(result.get(4), 4.f));
  }
  
  void
*************** test_swap()
*** 117,124 ****
    Matrix<float> t2(5, 5);
    t2 = m2;
    vsip::swap(t1, t2);
!   assert(view_equal(t1, m2));
!   assert(view_equal(t2, m1));
  }
  
  int 
--- 117,124 ----
    Matrix<float> t2(5, 5);
    t2 = m2;
    vsip::swap(t1, t2);
!   test_assert(view_equal(t1, m2));
!   test_assert(view_equal(t2, m1));
  }
  
  int 
Index: tests/solver-cholesky.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-cholesky.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 solver-cholesky.cpp
*** tests/solver-cholesky.cpp	19 Sep 2005 03:39:54 -0000	1.3
--- tests/solver-cholesky.cpp	20 Dec 2005 12:39:21 -0000
*************** test_chold_diag(
*** 175,186 ****
  
    chold<T, by_reference> chol(uplo, n);
  
!   assert(chol.uplo()   == uplo);
!   assert(chol.length() == n);
  
    bool success = chol.decompose(a);
  
!   assert(success);
  
    for (index_type i=0; i<p; ++i)
      b.col(i) = test_ramp(T(1), T(i), n);
--- 175,186 ----
  
    chold<T, by_reference> chol(uplo, n);
  
!   test_assert(chol.uplo()   == uplo);
!   test_assert(chol.length() == n);
  
    bool success = chol.decompose(a);
  
!   test_assert(success);
  
    for (index_type i=0; i<p; ++i)
      b.col(i) = test_ramp(T(1), T(i), n);
*************** test_chold_diag(
*** 197,203 ****
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       assert(equal(b(r, c), a(r, r) * x(r, c)));
  }
  
  
--- 197,203 ----
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       test_assert(equal(b(r, c), a(r, r) * x(r, c)));
  }
  
  
*************** test_chold_random(
*** 226,234 ****
    // Check A symmetric/hermetian.
    for (index_type i=0; i<n; ++i)
    {
!     assert(is_positive(a(i, i)));
      for (index_type j=0; j<i; ++j)
!       assert(equal(a(i, j), tconj(a(j, i))));
    }
    
  
--- 226,234 ----
    // Check A symmetric/hermetian.
    for (index_type i=0; i<n; ++i)
    {
!     test_assert(is_positive(a(i, i)));
      for (index_type j=0; j<i; ++j)
!       test_assert(equal(a(i, j), tconj(a(j, i))));
    }
    
  
*************** test_chold_random(
*** 237,248 ****
  
    chold<T, by_reference> chol(uplo, n);
  
!   assert(chol.uplo()   == uplo);
!   assert(chol.length() == n);
  
    bool success = chol.decompose(a);
  
!   assert(success);
  
  
    // 3. Solve A X = B.
--- 237,248 ----
  
    chold<T, by_reference> chol(uplo, n);
  
!   test_assert(chol.uplo()   == uplo);
!   test_assert(chol.length() == n);
  
    bool success = chol.decompose(a);
  
!   test_assert(success);
  
  
    // 3. Solve A X = B.
*************** test_chold_random(
*** 274,280 ****
    {
      for (index_type r=0; r<n; ++r)
        for (index_type c=0; c<p; ++c)
! 	assert(equal(b(r, c), chk(r, c)));
    }
  }
  
--- 274,280 ----
    {
      for (index_type r=0; r<n; ++r)
        for (index_type c=0; c<p; ++c)
! 	test_assert(equal(b(r, c), chk(r, c)));
    }
  }
  
*************** test_chold_file(
*** 305,313 ****
    // Check A symmetric/hermetian.
    for (index_type i=0; i<n; ++i)
    {
!     assert(is_positive(a(i, i)));
      for (index_type j=0; j<i; ++j)
!       assert(equal(a(i, j), tconj(a(j, i))));
    }
    
  
--- 305,313 ----
    // Check A symmetric/hermetian.
    for (index_type i=0; i<n; ++i)
    {
!     test_assert(is_positive(a(i, i)));
      for (index_type j=0; j<i; ++j)
!       test_assert(equal(a(i, j), tconj(a(j, i))));
    }
    
  
*************** test_chold_file(
*** 316,327 ****
  
    chold<T, by_reference> chol(uplo, n);
  
!   assert(chol.uplo()   == uplo);
!   assert(chol.length() == n);
  
    bool success = chol.decompose(a);
  
!   assert(success);
  
  
  
--- 316,327 ----
  
    chold<T, by_reference> chol(uplo, n);
  
!   test_assert(chol.uplo()   == uplo);
!   test_assert(chol.length() == n);
  
    bool success = chol.decompose(a);
  
!   test_assert(success);
  
  
  
*************** test_chold_file(
*** 353,359 ****
    {
      for (index_type r=0; r<n; ++r)
        for (index_type c=0; c<p; ++c)
! 	assert(equal(b(r, c), chk(r, c)));
    }
  }
  
--- 353,359 ----
    {
      for (index_type r=0; r<n; ++r)
        for (index_type c=0; c<p; ++c)
! 	test_assert(equal(b(r, c), chk(r, c)));
    }
  }
  
Index: tests/solver-common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-common.hpp,v
retrieving revision 1.5
diff -c -p -r1.5 solver-common.hpp
*** tests/solver-common.hpp	27 Sep 2005 21:30:17 -0000	1.5
--- tests/solver-common.hpp	20 Dec 2005 12:39:21 -0000
*************** compare_view(
*** 200,206 ****
    if (err > thresh)
    {
      for (vsip::index_type r=0; r<a.size(0); ++r)
! 	assert(equal(a.get(r), b.get(r)));
    }
  }
  
--- 200,206 ----
    if (err > thresh)
    {
      for (vsip::index_type r=0; r<a.size(0); ++r)
! 	test_assert(equal(a.get(r), b.get(r)));
    }
  }
  
*************** compare_view(
*** 229,235 ****
      std::cout << "b = \n" << b;
      for (vsip::index_type r=0; r<a.size(0); ++r)
        for (vsip::index_type c=0; c<a.size(1); ++c)
! 	assert(equal(a.get(r, c), b.get(r, c)));
    }
  }
  
--- 229,235 ----
      std::cout << "b = \n" << b;
      for (vsip::index_type r=0; r<a.size(0); ++r)
        for (vsip::index_type c=0; c<a.size(1); ++c)
! 	test_assert(equal(a.get(r, c), b.get(r, c)));
    }
  }
  
Index: tests/solver-covsol.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-covsol.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 solver-covsol.cpp
*** tests/solver-covsol.cpp	13 Sep 2005 16:39:45 -0000	1.2
--- tests/solver-covsol.cpp	20 Dec 2005 12:39:21 -0000
*************** test_covsol_diag(
*** 56,62 ****
    length_type n,
    length_type p)
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> b(n, p);
--- 56,62 ----
    length_type n,
    length_type p)
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> b(n, p);
*************** test_covsol_diag(
*** 88,94 ****
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       assert(equal(b(r, c),
  		   Test_traits<T>::conj(a(r, r)) * a(r, r) * x(r, c)));
  }
  
--- 88,94 ----
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       test_assert(equal(b(r, c),
  		   Test_traits<T>::conj(a(r, r)) * a(r, r) * x(r, c)));
  }
  
*************** test_covsol_random(
*** 102,108 ****
    length_type n,
    length_type p)
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> b(n, p);
--- 102,108 ----
    length_type n,
    length_type p)
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> b(n, p);
*************** test_covsol_random(
*** 137,143 ****
    {
      for (index_type r=0; r<n; ++r)
        for (index_type c=0; c<p; ++c)
! 	assert(equal(b(r, c), chk(r, c)));
    }
  }
  
--- 137,143 ----
    {
      for (index_type r=0; r<n; ++r)
        for (index_type c=0; c<p; ++c)
! 	test_assert(equal(b(r, c), chk(r, c)));
    }
  }
  
Index: tests/solver-llsqsol.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-llsqsol.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 solver-llsqsol.cpp
*** tests/solver-llsqsol.cpp	19 Sep 2005 03:39:54 -0000	1.3
--- tests/solver-llsqsol.cpp	20 Dec 2005 12:39:21 -0000
*************** test_llsqsol_diag(
*** 48,54 ****
    length_type n,
    length_type p)
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
--- 48,54 ----
    length_type n,
    length_type p)
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
*************** test_llsqsol_diag(
*** 78,84 ****
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       assert(equal(b(r, c),
  		   a(r, r) * x(r, c)));
  }
  
--- 78,84 ----
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       test_assert(equal(b(r, c),
  		   a(r, r) * x(r, c)));
  }
  
*************** test_llsqsol_random(
*** 92,98 ****
    length_type n,
    length_type p)
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
--- 92,98 ----
    length_type n,
    length_type p)
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
*************** test_llsqsol_random(
*** 134,140 ****
    {
      for (index_type r=0; r<m; ++r)
        for (index_type c=0; c<p; ++c)
! 	assert(equal(b(r, c), chk(r, c)));
    }
  }
  
--- 134,140 ----
    {
      for (index_type r=0; r<m; ++r)
        for (index_type c=0; c<p; ++c)
! 	test_assert(equal(b(r, c), chk(r, c)));
    }
  }
  
Index: tests/solver-lu.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-lu.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 solver-lu.cpp
*** tests/solver-lu.cpp	30 Sep 2005 21:43:07 -0000	1.1
--- tests/solver-lu.cpp	20 Dec 2005 12:39:21 -0000
*************** solve_lu(
*** 78,85 ****
    length_type n = a.size(0);
    length_type p = b.size(1);
  
!   assert(n == a.size(1));
!   assert(n == b.size(0));
  
    Matrix<T> x1(n, p);
    Matrix<T> x2(n, p);
--- 78,85 ----
    length_type n = a.size(0);
    length_type p = b.size(1);
  
!   test_assert(n == a.size(1));
!   test_assert(n == b.size(0));
  
    Matrix<T> x1(n, p);
    Matrix<T> x2(n, p);
*************** solve_lu(
*** 89,98 ****
    {
      // 1. Build solver and factor A.
      lud<T, by_reference> lu(n);
!     assert(lu.length() == n);
  
      bool success = lu.decompose(a);
!     assert(success);
  
      // 2. Solve A X = B.
      lu.template solve<mat_ntrans>(b, x1);
--- 89,98 ----
    {
      // 1. Build solver and factor A.
      lud<T, by_reference> lu(n);
!     test_assert(lu.length() == n);
  
      bool success = lu.decompose(a);
!     test_assert(success);
  
      // 2. Solve A X = B.
      lu.template solve<mat_ntrans>(b, x1);
*************** solve_lu(
*** 103,112 ****
    {
      // 1. Build solver and factor A.
      lud<T, by_value> lu(n);
!     assert(lu.length() == n);
  
      bool success = lu.decompose(a);
!     assert(success);
  
      // 2. Solve A X = B.
      x1 = lu.template solve<mat_ntrans>(b);
--- 103,112 ----
    {
      // 1. Build solver and factor A.
      lud<T, by_value> lu(n);
!     test_assert(lu.length() == n);
  
      bool success = lu.decompose(a);
!     test_assert(success);
  
      // 2. Solve A X = B.
      x1 = lu.template solve<mat_ntrans>(b);
*************** solve_lu(
*** 167,175 ****
  	 << endl;
  #endif
  
!     assert(err1 < p_limit);
!     assert(err2 < p_limit);
!     assert(err3 < p_limit);
  
      if (err1 > max_err1) max_err1 = err1;
      if (err2 > max_err2) max_err2 = err2;
--- 167,175 ----
  	 << endl;
  #endif
  
!     test_assert(err1 < p_limit);
!     test_assert(err2 < p_limit);
!     test_assert(err3 < p_limit);
  
      if (err1 > max_err1) max_err1 = err1;
      if (err2 > max_err2) max_err2 = err2;
Index: tests/solver-qr.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-qr.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 solver-qr.cpp
*** tests/solver-qr.cpp	19 Sep 2005 03:39:55 -0000	1.4
--- tests/solver-qr.cpp	20 Dec 2005 12:39:21 -0000
*************** test_covsol_diag(
*** 50,56 ****
    length_type p = 2
    )
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> b(n, p);
--- 50,56 ----
    length_type p = 2
    )
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> b(n, p);
*************** test_covsol_diag(
*** 64,72 ****
  
    qrd<T, by_reference> qr(m, n, qrd_saveq);
  
!   assert(qr.rows()     == m);
!   assert(qr.columns()  == n);
!   assert(qr.qstorage() == qrd_saveq);
  
    qr.decompose(a);
  
--- 64,72 ----
  
    qrd<T, by_reference> qr(m, n, qrd_saveq);
  
!   test_assert(qr.rows()     == m);
!   test_assert(qr.columns()  == n);
!   test_assert(qr.qstorage() == qrd_saveq);
  
    qr.decompose(a);
  
*************** test_covsol_diag(
*** 85,91 ****
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       assert(equal(b(r, c),
  		   Test_traits<T>::conj(a(r, r)) * a(r, r) * x(r, c)));
  }
  
--- 85,91 ----
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       test_assert(equal(b(r, c),
  		   Test_traits<T>::conj(a(r, r)) * a(r, r) * x(r, c)));
  }
  
*************** test_covsol_random(
*** 98,104 ****
    length_type n,
    length_type p)
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> b(n, p);
--- 98,104 ----
    length_type n,
    length_type p)
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> b(n, p);
*************** test_covsol_random(
*** 108,116 ****
  
    qrd<T, by_reference> qr(m, n, qrd_saveq);
  
!   assert(qr.rows()     == m);
!   assert(qr.columns()  == n);
!   assert(qr.qstorage() == qrd_saveq);
  
    qr.decompose(a);
  
--- 108,116 ----
  
    qrd<T, by_reference> qr(m, n, qrd_saveq);
  
!   test_assert(qr.rows()     == m);
!   test_assert(qr.columns()  == n);
!   test_assert(qr.qstorage() == qrd_saveq);
  
    qr.decompose(a);
  
*************** test_covsol_random(
*** 140,146 ****
    {
      for (index_type r=0; r<n; ++r)
        for (index_type c=0; c<p; ++c)
! 	assert(equal(b(r, c), chk(r, c)));
    }
  }
  
--- 140,146 ----
    {
      for (index_type r=0; r<n; ++r)
        for (index_type c=0; c<p; ++c)
! 	test_assert(equal(b(r, c), chk(r, c)));
    }
  }
  
*************** test_lsqsol_diag(
*** 198,204 ****
    length_type n,
    length_type p)
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
--- 198,204 ----
    length_type n,
    length_type p)
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
*************** test_lsqsol_diag(
*** 212,220 ****
  
    qrd<T, by_reference> qr(m, n, qrd_saveq);
  
!   assert(qr.rows()     == m);
!   assert(qr.columns()  == n);
!   assert(qr.qstorage() == qrd_saveq);
  
    qr.decompose(a);
  
--- 212,220 ----
  
    qrd<T, by_reference> qr(m, n, qrd_saveq);
  
!   test_assert(qr.rows()     == m);
!   test_assert(qr.columns()  == n);
!   test_assert(qr.qstorage() == qrd_saveq);
  
    qr.decompose(a);
  
*************** test_lsqsol_diag(
*** 233,239 ****
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       assert(equal(b(r, c),
  		   a(r, r) * x(r, c)));
  }
  
--- 233,239 ----
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       test_assert(equal(b(r, c),
  		   a(r, r) * x(r, c)));
  }
  
*************** test_lsqsol_random(
*** 246,252 ****
    length_type n,
    length_type p)
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
--- 246,252 ----
    length_type n,
    length_type p)
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
*************** test_lsqsol_random(
*** 269,277 ****
  
    qrd<T, by_reference> qr(m, n, qrd_saveq);
  
!   assert(qr.rows()     == m);
!   assert(qr.columns()  == n);
!   assert(qr.qstorage() == qrd_saveq);
  
    qr.decompose(a);
  
--- 269,277 ----
  
    qrd<T, by_reference> qr(m, n, qrd_saveq);
  
!   test_assert(qr.rows()     == m);
!   test_assert(qr.columns()  == n);
!   test_assert(qr.qstorage() == qrd_saveq);
  
    qr.decompose(a);
  
*************** test_lsqsol_random(
*** 294,303 ****
    {
      for (index_type r=0; r<m; ++r)
        for (index_type c=0; c<p; ++c)
! 	assert(equal(b(r, c), chk(r, c)));
    }
  
!   // assert(err < 10.0);
  }
  
  
--- 294,303 ----
    {
      for (index_type r=0; r<m; ++r)
        for (index_type c=0; c<p; ++c)
! 	test_assert(equal(b(r, c), chk(r, c)));
    }
  
!   // test_assert(err < 10.0);
  }
  
  
*************** test_rsol_diag(
*** 354,360 ****
    length_type n,
    length_type p)
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
--- 354,360 ----
    length_type n,
    length_type p)
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
*************** test_rsol_diag(
*** 368,376 ****
  
    qrd<T, by_reference> qr(m, n, qrd_saveq);
  
!   assert(qr.rows()     == m);
!   assert(qr.columns()  == n);
!   assert(qr.qstorage() == qrd_saveq);
  
    qr.decompose(a);
  
--- 368,376 ----
  
    qrd<T, by_reference> qr(m, n, qrd_saveq);
  
!   test_assert(qr.rows()     == m);
!   test_assert(qr.columns()  == n);
!   test_assert(qr.qstorage() == qrd_saveq);
  
    qr.decompose(a);
  
*************** test_rsol_diag(
*** 392,400 ****
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<m; ++j)
        if (i == j)
! 	assert(equal(qi(i, j) * tconj(qi(i, j)), T(1)));
        else
! 	assert(equal(qi(i, j), T()));
  
    // Next, check multiply w/identity from right-side:
    //   I Q = iq
--- 392,400 ----
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<m; ++j)
        if (i == j)
! 	test_assert(equal(qi(i, j) * tconj(qi(i, j)), T(1)));
        else
! 	test_assert(equal(qi(i, j), T()));
  
    // Next, check multiply w/identity from right-side:
    //   I Q = iq
*************** test_rsol_diag(
*** 405,414 ****
      for (index_type j=0; j<m; ++j)
      {
        if (i == j)
! 	assert(equal(iq(i, j) * tconj(qi(i, j)), T(1)));
        else
! 	assert(equal(iq(i, j), T()));
!       assert(equal(iq(i, j), qi(i, j)));
      }
  
    // Next, check hermitian multiply w/Q from left-side:
--- 405,414 ----
      for (index_type j=0; j<m; ++j)
      {
        if (i == j)
! 	test_assert(equal(iq(i, j) * tconj(qi(i, j)), T(1)));
        else
! 	test_assert(equal(iq(i, j), T()));
!       test_assert(equal(iq(i, j), qi(i, j)));
      }
  
    // Next, check hermitian multiply w/Q from left-side:
*************** test_rsol_diag(
*** 420,426 ****
    // Result should be I
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<m; ++j)
!       assert(equal(qtq(i, j), I(i, j)));
  
    
    // -------------------------------------------------------------------
--- 420,426 ----
    // Result should be I
    for (index_type i=0; i<m; ++i)
      for (index_type j=0; j<m; ++j)
!       test_assert(equal(qtq(i, j), I(i, j)));
  
    
    // -------------------------------------------------------------------
*************** test_rsol_diag(
*** 445,451 ****
  
    for (index_type i=0; i<b.size(0); ++i)
      for (index_type j=0; j<b.size(1); ++j)
!       assert(equal(alpha * qi(i, i) * b(i, j),
  		   a(i, i) * x(i, j)));
  }
  
--- 445,451 ----
  
    for (index_type i=0; i<b.size(0); ++i)
      for (index_type j=0; j<b.size(1); ++j)
!       test_assert(equal(alpha * qi(i, i) * b(i, j),
  		   a(i, i) * x(i, j)));
  }
  
*************** struct Covsol_class<by_reference>
*** 497,508 ****
      mat_op_type const tr = impl::Is_complex<T>::value ? mat_herm : mat_trans;
      
      // b should be (n, p)
!     assert(b.size(0) == n);
!     assert(b.size(1) == p);
      
      // x should be (n, p)
!     assert(x.size(0) == n);
!     assert(x.size(1) == p);
      
      qrd<T, by_reference> qr(m, n, qrd_saveq);
      
--- 497,508 ----
      mat_op_type const tr = impl::Is_complex<T>::value ? mat_herm : mat_trans;
      
      // b should be (n, p)
!     test_assert(b.size(0) == n);
!     test_assert(b.size(1) == p);
      
      // x should be (n, p)
!     test_assert(x.size(0) == n);
!     test_assert(x.size(1) == p);
      
      qrd<T, by_reference> qr(m, n, qrd_saveq);
      
*************** struct Covsol_class<by_value>
*** 543,554 ****
      mat_op_type const tr = impl::Is_complex<T>::value ? mat_herm : mat_trans;
      
      // b should be (n, p)
!     assert(b.size(0) == n);
!     assert(b.size(1) == p);
      
      // x should be (n, p)
!     assert(x.size(0) == n);
!     assert(x.size(1) == p);
      
      qrd<T, by_value> qr(m, n, qrd_saveq);
      
--- 543,554 ----
      mat_op_type const tr = impl::Is_complex<T>::value ? mat_herm : mat_trans;
      
      // b should be (n, p)
!     test_assert(b.size(0) == n);
!     test_assert(b.size(1) == p);
      
      // x should be (n, p)
!     test_assert(x.size(0) == n);
!     test_assert(x.size(1) == p);
      
      qrd<T, by_value> qr(m, n, qrd_saveq);
      
*************** struct Covsol_class<by_value>
*** 562,573 ****
  
      Matrix<T> x_chk = qr.covsol(b);
  
!     assert(x_chk.size(0) == x.size(0));
!     assert(x_chk.size(1) == x.size(1));
  
      for (index_type i=0; i<x.size(0); ++i)
        for (index_type j=0; j<x.size(1); ++j)
! 	assert(equal(x(i,j), x_chk(i,j)));
      
      return x;
    }
--- 562,573 ----
  
      Matrix<T> x_chk = qr.covsol(b);
  
!     test_assert(x_chk.size(0) == x.size(0));
!     test_assert(x_chk.size(1) == x.size(1));
  
      for (index_type i=0; i<x.size(0); ++i)
        for (index_type j=0; j<x.size(1); ++j)
! 	test_assert(equal(x(i,j), x_chk(i,j)));
      
      return x;
    }
*************** test_f_covsol_diag(
*** 599,605 ****
    length_type n,
    length_type p)
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> b(n, p);
--- 599,605 ----
    length_type n,
    length_type p)
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> b(n, p);
*************** test_f_covsol_diag(
*** 628,634 ****
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       assert(equal(b(r, c),
  		   Test_traits<T>::conj(a(r, r)) * a(r, r) * x(r, c)));
  }
  
--- 628,634 ----
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       test_assert(equal(b(r, c),
  		   Test_traits<T>::conj(a(r, r)) * a(r, r) * x(r, c)));
  }
  
*************** test_f_covsol_random(
*** 642,648 ****
    length_type n,
    length_type p)
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> b(n, p);
--- 642,648 ----
    length_type n,
    length_type p)
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> b(n, p);
*************** test_f_covsol_random(
*** 674,680 ****
    {
      for (index_type r=0; r<n; ++r)
        for (index_type c=0; c<p; ++c)
! 	assert(equal(b(r, c), chk(r, c)));
    }
  }
  
--- 674,680 ----
    {
      for (index_type r=0; r<n; ++r)
        for (index_type c=0; c<p; ++c)
! 	test_assert(equal(b(r, c), chk(r, c)));
    }
  }
  
*************** struct Lsqsol_class<by_reference>
*** 751,762 ****
  
  
      // b should be (m, p)
!     assert(b.size(0) == m);
!     assert(b.size(1) == p);
      
      // x should be (n, p)
!     assert(x.size(0) == n);
!     assert(x.size(1) == p);
      
      qrd<T, by_reference> qr(m, n, qrd_saveq);
      
--- 751,762 ----
  
  
      // b should be (m, p)
!     test_assert(b.size(0) == m);
!     test_assert(b.size(1) == p);
      
      // x should be (n, p)
!     test_assert(x.size(0) == n);
!     test_assert(x.size(1) == p);
      
      qrd<T, by_reference> qr(m, n, qrd_saveq);
      
*************** struct Lsqsol_class<by_value>
*** 798,809 ****
  
  
      // b should be (m, p)
!     assert(b.size(0) == m);
!     assert(b.size(1) == p);
      
      // x should be (n, p)
!     assert(x.size(0) == n);
!     assert(x.size(1) == p);
      
      qrd<T, by_value> qr(m, n, qrd_saveq);
      
--- 798,809 ----
  
  
      // b should be (m, p)
!     test_assert(b.size(0) == m);
!     test_assert(b.size(1) == p);
      
      // x should be (n, p)
!     test_assert(x.size(0) == n);
!     test_assert(x.size(1) == p);
      
      qrd<T, by_value> qr(m, n, qrd_saveq);
      
*************** struct Lsqsol_class<by_value>
*** 820,831 ****
  
      Matrix<T> x_chk = qr.lsqsol(b);
  
!     assert(x_chk.size(0) == x.size(0));
!     assert(x_chk.size(1) == x.size(1));
  
      for (index_type i=0; i<x.size(0); ++i)
        for (index_type j=0; j<x.size(1); ++j)
! 	assert(equal(x(i,j), x_chk(i,j)));
      
      return x;
    }
--- 820,831 ----
  
      Matrix<T> x_chk = qr.lsqsol(b);
  
!     test_assert(x_chk.size(0) == x.size(0));
!     test_assert(x_chk.size(1) == x.size(1));
  
      for (index_type i=0; i<x.size(0); ++i)
        for (index_type j=0; j<x.size(1); ++j)
! 	test_assert(equal(x(i,j), x_chk(i,j)));
      
      return x;
    }
*************** test_f_lsqsol_diag(
*** 857,863 ****
    length_type n,
    length_type p)
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
--- 857,863 ----
    length_type n,
    length_type p)
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
*************** test_f_lsqsol_diag(
*** 884,890 ****
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       assert(equal(b(r, c),
  		   a(r, r) * x(r, c)));
  }
  
--- 884,890 ----
  
    for (index_type c=0; c<p; ++c)
      for (index_type r=0; r<n; ++r)
!       test_assert(equal(b(r, c),
  		   a(r, r) * x(r, c)));
  }
  
*************** test_f_lsqsol_random(
*** 898,904 ****
    length_type n,
    length_type p)
  {
!   assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
--- 898,904 ----
    length_type n,
    length_type p)
  {
!   test_assert(m >= n);
  
    Matrix<T> a(m, n);
    Matrix<T> x(n, p);
*************** test_f_lsqsol_random(
*** 937,943 ****
    {
      for (index_type r=0; r<m; ++r)
        for (index_type c=0; c<p; ++c)
! 	assert(equal(b(r, c), chk(r, c)));
    }
  }
  
--- 937,943 ----
    {
      for (index_type r=0; r<m; ++r)
        for (index_type c=0; c<p; ++c)
! 	test_assert(equal(b(r, c), chk(r, c)));
    }
  }
  
Index: tests/solver-svd.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-svd.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 solver-svd.cpp
*** tests/solver-svd.cpp	27 Sep 2005 21:30:17 -0000	1.1
--- tests/solver-svd.cpp	20 Dec 2005 12:39:21 -0000
*************** test_svd(
*** 223,229 ****
    length_type n = a.size(1);
  
    length_type p = std::min(m, n);
!   assert(m > 0 && n > 0);
  
    length_type u_cols = ustorage == svd_uvfull ? m : p;
    length_type v_cols = vstorage == svd_uvfull ? n : p;
--- 223,229 ----
    length_type n = a.size(1);
  
    length_type p = std::min(m, n);
!   test_assert(m > 0 && n > 0);
  
    length_type u_cols = ustorage == svd_uvfull ? m : p;
    length_type v_cols = vstorage == svd_uvfull ? n : p;
*************** test_svd(
*** 234,243 ****
  
    svd<T, RtM> sv(m, n, ustorage, vstorage);
  
!   assert(sv.rows()     == m);
!   assert(sv.columns()  == n);
!   assert(sv.ustorage() == ustorage);
!   assert(sv.vstorage() == vstorage);
  
    for (index_type i=0; i<loop; ++i)
    {
--- 234,243 ----
  
    svd<T, RtM> sv(m, n, ustorage, vstorage);
  
!   test_assert(sv.rows()     == m);
!   test_assert(sv.columns()  == n);
!   test_assert(sv.ustorage() == ustorage);
!   test_assert(sv.vstorage() == vstorage);
  
    for (index_type i=0; i<loop; ++i)
    {
*************** test_svd(
*** 245,251 ****
  
      // Check that sv_sv is non-increasing.
      for (index_type i=0; i<p-1; ++i)
!       assert(sv_s(i) >= sv_s(i+1));
  
      // Check that product of u, s, v equals a.
      if (ustorage != svd_uvnos && vstorage != svd_uvnos)
--- 245,251 ----
  
      // Check that sv_sv is non-increasing.
      for (index_type i=0; i<p-1; ++i)
!       test_assert(sv_s(i) >= sv_s(i+1));
  
      // Check that product of u, s, v equals a.
      if (ustorage != svd_uvnos && vstorage != svd_uvnos)
*************** test_svd(
*** 292,298 ****
        {
  	for (index_type r=0; r<m; ++r)
  	  for (index_type c=0; c<n; ++c)
! 	    assert(equal(chk(r, c), a(r, c)));
        }
      }
  
--- 292,298 ----
        {
  	for (index_type r=0; r<m; ++r)
  	  for (index_type c=0; c<n; ++c)
! 	    test_assert(equal(chk(r, c), a(r, c)));
        }
      }
  
*************** test_svd_ident(
*** 410,416 ****
    length_type  loop)
  {
    length_type p = std::min(m, n);
!   assert(m > 0 && n > 0);
  
    Matrix<T>     a(m, n);
    Vector<float> sv_s(p);	// singular values
--- 410,416 ----
    length_type  loop)
  {
    length_type p = std::min(m, n);
!   test_assert(m > 0 && n > 0);
  
    Matrix<T>     a(m, n);
    Vector<float> sv_s(p);	// singular values
*************** test_svd_rand(
*** 442,448 ****
    typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
  
    length_type p = std::min(m, n);
!   assert(m > 0 && n > 0);
  
    Matrix<T>     a(m, n);
    Vector<float> sv_s(p);	// singular values
--- 442,448 ----
    typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
  
    length_type p = std::min(m, n);
!   test_assert(m > 0 && n > 0);
  
    Matrix<T>     a(m, n);
    Vector<float> sv_s(p);	// singular values
Index: tests/solver-toepsol.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/solver-toepsol.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 solver-toepsol.cpp
*** tests/solver-toepsol.cpp	30 Sep 2005 15:19:16 -0000	1.1
--- tests/solver-toepsol.cpp	20 Dec 2005 12:39:21 -0000
*************** test_toepsol(
*** 103,109 ****
    cout << "err = " << err  << endl;
  #endif
  
!   assert(err < 5.0);
  }
  
  
--- 103,109 ----
    cout << "err = " << err  << endl;
  #endif
  
!   test_assert(err < 5.0);
  }
  
  
*************** test_toepsol_illformed(
*** 223,229 ****
        pass = 1;
    }
  
!   assert(pass == 1);
  }
  
  
--- 223,229 ----
        pass = 1;
    }
  
!   test_assert(pass == 1);
  }
  
  
Index: tests/subblock.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/subblock.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 subblock.cpp
*** tests/subblock.cpp	18 Jun 2005 16:40:45 -0000	1.4
--- tests/subblock.cpp	20 Dec 2005 12:39:21 -0000
*************** struct B<Block, 1>
*** 45,51 ****
    static void verify_ramp(Block const& block, Domain<1> dom)
      {
        for (index_type i = 0; i < dom[0].length(); i++)
!         assert(equal(block.get(i), T(dom[0].impl_nth(i))));
      }
  };
  
--- 45,51 ----
    static void verify_ramp(Block const& block, Domain<1> dom)
      {
        for (index_type i = 0; i < dom[0].length(); i++)
!         test_assert(equal(block.get(i), T(dom[0].impl_nth(i))));
      }
  };
  
*************** struct B<Block, 2>
*** 63,69 ****
      {
        for (index_type i = 0; i < dom[0].length(); i++)
          for (index_type j = 0; j < dom[1].length(); j++)
!           assert(equal(block.get(i, j),
                         T(dom[0].impl_nth(i)*100 + dom[1].impl_nth(j))));
      }
  
--- 63,69 ----
      {
        for (index_type i = 0; i < dom[0].length(); i++)
          for (index_type j = 0; j < dom[1].length(); j++)
!           test_assert(equal(block.get(i, j),
                         T(dom[0].impl_nth(i)*100 + dom[1].impl_nth(j))));
      }
  
*************** void test_subset_write_1d(void)
*** 105,111 ****
    B<SD1T>::ramp(s2);
  
    for (index_type i = 0; i < block.size(); i++)
!     assert(equal(block.get(i), T((i % 2) ? 1 : i/2)));
  }
    
  int
--- 105,111 ----
    B<SD1T>::ramp(s2);
  
    for (index_type i = 0; i < block.size(); i++)
!     test_assert(equal(block.get(i), T((i % 2) ? 1 : i/2)));
  }
    
  int
Index: tests/support.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/support.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 support.cpp
*** tests/support.cpp	18 Jun 2005 16:40:45 -0000	1.3
--- tests/support.cpp	20 Dec 2005 12:39:21 -0000
***************
*** 14,22 ****
  ***********************************************************************/
  
  #include <iostream>
- #include <cassert>
  #include <vsip/support.hpp>
  
  using namespace std;
  using namespace vsip;
  
--- 14,23 ----
  ***********************************************************************/
  
  #include <iostream>
  #include <vsip/support.hpp>
  
+ #include "test.hpp"
+ 
  using namespace std;
  using namespace vsip;
  
*************** test_computation_error()
*** 36,42 ****
    try
    {
      VSIP_THROW(computation_error("TEST: throw exception"));
!     assert(0);
    }
    catch (const std::exception& error)
    {
--- 37,43 ----
    try
    {
      VSIP_THROW(computation_error("TEST: throw exception"));
!     test_assert(0);
    }
    catch (const std::exception& error)
    {
*************** test_computation_error()
*** 45,51 ****
        pass = 1;
    }
  
!   assert(pass);
  #else
    // Could report untested or not-applicable.
  #endif
--- 46,52 ----
        pass = 1;
    }
  
!   test_assert(pass);
  #else
    // Could report untested or not-applicable.
  #endif
Index: tests/tensor-transpose.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/tensor-transpose.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 tensor-transpose.cpp
*** tests/tensor-transpose.cpp	18 Sep 2005 22:07:34 -0000	1.4
--- tests/tensor-transpose.cpp	20 Dec 2005 12:39:21 -0000
*************** check_tensor(TensorT view, int offset=0)
*** 68,74 ****
      for (index_type idx1=0; idx1<view.size(1); ++idx1)
        for (index_type idx2=0; idx2<view.size(2); ++idx2)
        {
! 	assert(equal(view.get(idx0, idx1, idx2),
  		     T(idx0 * size1 * size2 +
  		       idx1 * size2         +
  		       idx2 + offset)));
--- 68,74 ----
      for (index_type idx1=0; idx1<view.size(1); ++idx1)
        for (index_type idx2=0; idx2<view.size(2); ++idx2)
        {
! 	test_assert(equal(view.get(idx0, idx1, idx2),
  		     T(idx0 * size1 * size2 +
  		       idx1 * size2         +
  		       idx2 + offset)));
*************** test_transpose_readonly(TensorT view)
*** 101,109 ****
      view.template transpose<D0, D1, D2>();
  #endif
  
!   assert(trans.size(0) == view.size(D0));
!   assert(trans.size(1) == view.size(D1));
!   assert(trans.size(2) == view.size(D2));
  
    // Build a reverse dimension map
    dimension_type R0, R1, R2;
--- 101,109 ----
      view.template transpose<D0, D1, D2>();
  #endif
  
!   test_assert(trans.size(0) == view.size(D0));
!   test_assert(trans.size(1) == view.size(D1));
!   test_assert(trans.size(2) == view.size(D2));
  
    // Build a reverse dimension map
    dimension_type R0, R1, R2;
*************** test_transpose_readonly(TensorT view)
*** 121,129 ****
    else if (D2 == 2) R2 = 2;
  
    // Sanity check reverse map
!   assert(trans.size(R0) == view.size(0));
!   assert(trans.size(R1) == view.size(1));
!   assert(trans.size(R2) == view.size(2));
  
    index_type idx[3];
  
--- 121,129 ----
    else if (D2 == 2) R2 = 2;
  
    // Sanity check reverse map
!   test_assert(trans.size(R0) == view.size(0));
!   test_assert(trans.size(R1) == view.size(1));
!   test_assert(trans.size(R2) == view.size(2));
  
    index_type idx[3];
  
*************** test_transpose_readonly(TensorT view)
*** 134,142 ****
  	T expected = T(idx[R0] * size1 * size2 +
  		       idx[R1] * size2         +
  		       idx[R2]);
! 	assert(equal(trans.get(idx[0], idx[1], idx[2]),
  		     expected));
! 	assert(equal(trans.get(idx[0],  idx[1],  idx[2]),
  		     view. get(idx[R0], idx[R1], idx[R2])));
        }
  
--- 134,142 ----
  	T expected = T(idx[R0] * size1 * size2 +
  		       idx[R1] * size2         +
  		       idx[R2]);
! 	test_assert(equal(trans.get(idx[0], idx[1], idx[2]),
  		     expected));
! 	test_assert(equal(trans.get(idx[0],  idx[1],  idx[2]),
  		     view. get(idx[R0], idx[R1], idx[R2])));
        }
  
*************** test_transpose(TensorT view)
*** 170,178 ****
      view.template transpose<D0, D1, D2>();
  #endif
  
!   assert(trans.size(0) == view.size(D0));
!   assert(trans.size(1) == view.size(D1));
!   assert(trans.size(2) == view.size(D2));
  
    // Build a reverse dimension map
    dimension_type R0, R1, R2;
--- 170,178 ----
      view.template transpose<D0, D1, D2>();
  #endif
  
!   test_assert(trans.size(0) == view.size(D0));
!   test_assert(trans.size(1) == view.size(D1));
!   test_assert(trans.size(2) == view.size(D2));
  
    // Build a reverse dimension map
    dimension_type R0, R1, R2;
*************** test_transpose(TensorT view)
*** 190,198 ****
    else if (D2 == 2) R2 = 2;
  
    // Sanity check reverse map
!   assert(trans.size(R0) == view.size(0));
!   assert(trans.size(R1) == view.size(1));
!   assert(trans.size(R2) == view.size(2));
  
    index_type idx[3];
  
--- 190,198 ----
    else if (D2 == 2) R2 = 2;
  
    // Sanity check reverse map
!   test_assert(trans.size(R0) == view.size(0));
!   test_assert(trans.size(R1) == view.size(1));
!   test_assert(trans.size(R2) == view.size(2));
  
    index_type idx[3];
  
*************** test_transpose(TensorT view)
*** 203,211 ****
  	T expected = T(idx[R0] * size1 * size2 +
  		       idx[R1] * size2         +
  		       idx[R2]);
! 	assert(equal(trans.get(idx[0], idx[1], idx[2]),
  		     expected));
! 	assert(equal(trans.get(idx[0],  idx[1],  idx[2]),
  		     view. get(idx[R0], idx[R1], idx[R2])));
  
  	T new_value = T(idx[R0] * size1 * size2 +
--- 203,211 ----
  	T expected = T(idx[R0] * size1 * size2 +
  		       idx[R1] * size2         +
  		       idx[R2]);
! 	test_assert(equal(trans.get(idx[0], idx[1], idx[2]),
  		     expected));
! 	test_assert(equal(trans.get(idx[0],  idx[1],  idx[2]),
  		     view. get(idx[R0], idx[R1], idx[R2])));
  
  	T new_value = T(idx[R0] * size1 * size2 +
*************** test_transpose(TensorT view)
*** 213,219 ****
  			idx[R2] + 1);
  	trans.put(idx[0], idx[1], idx[2], new_value);
  
! 	assert(equal(trans.get(idx[0],  idx[1],  idx[2]),
  		     view. get(idx[R0], idx[R1], idx[R2])));
        }
  
--- 213,219 ----
  			idx[R2] + 1);
  	trans.put(idx[0], idx[1], idx[2], new_value);
  
! 	test_assert(equal(trans.get(idx[0],  idx[1],  idx[2]),
  		     view. get(idx[R0], idx[R1], idx[R2])));
        }
  
Index: tests/tensor.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/tensor.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 tensor.cpp
*** tests/tensor.cpp	2 Jun 2005 21:41:57 -0000	1.2
--- tests/tensor.cpp	20 Dec 2005 12:39:21 -0000
*************** void
*** 51,60 ****
  check_size(const_Tensor<T, Block> tensor,
  	   length_type i, length_type j, length_type k)
  {
!   assert(tensor.size() == i * j * k);
!   assert(tensor.size(0) == i);
!   assert(tensor.size(1) == j);
!   assert(tensor.size(2) == k);
  }
  
  
--- 51,60 ----
  check_size(const_Tensor<T, Block> tensor,
  	   length_type i, length_type j, length_type k)
  {
!   test_assert(tensor.size() == i * j * k);
!   test_assert(tensor.size(0) == i);
!   test_assert(tensor.size(1) == j);
!   test_assert(tensor.size(2) == k);
  }
  
  
*************** test_tensor(const_Tensor<T, Block> tenso
*** 107,113 ****
    for (index_type i = 0; i < tensor.size(0); ++i)
      for (index_type j = 0; j < tensor.size(1); ++j)
        for (index_type k = 0; k < tensor.size(2); ++k)
! 	assert(equal(tensor.get(i, j, k), T(kk * i * j * k + 1)));
  }
  
  
--- 107,113 ----
    for (index_type i = 0; i < tensor.size(0); ++i)
      for (index_type j = 0; j < tensor.size(1); ++j)
        for (index_type k = 0; k < tensor.size(2); ++k)
! 	test_assert(equal(tensor.get(i, j, k), T(kk * i * j * k + 1)));
  }
  
  
*************** test_tensor(const_Tensor<T, Block> tenso
*** 116,123 ****
  //
  // Checks that tensor values match those generated by a call to
  // fill_tensor or fill_block with the same k value.  Rather than
! // triggering assertion failure, check_tensor returns a boolean
! // pass/fail that can be used to cause an assertion failure in
  // the caller.
  
  template <typename T,
--- 116,123 ----
  //
  // Checks that tensor values match those generated by a call to
  // fill_tensor or fill_block with the same k value.  Rather than
! // triggering test_assertion failure, check_tensor returns a boolean
! // pass/fail that can be used to cause an test_assertion failure in
  // the caller.
  
  template <typename T,
*************** check_not_alias(
*** 154,164 ****
    fill_block(tensor2.block(), 3);
  
    // Make sure that updates to tensor2 do not affect tensor1.
!   assert(check_tensor(tensor1, 2));
  
    // And visa-versa.
    fill_block(tensor1.block(), 4);
!   assert(check_tensor(tensor2, 3));
  }
  
  
--- 154,164 ----
    fill_block(tensor2.block(), 3);
  
    // Make sure that updates to tensor2 do not affect tensor1.
!   test_assert(check_tensor(tensor1, 2));
  
    // And visa-versa.
    fill_block(tensor1.block(), 4);
!   test_assert(check_tensor(tensor2, 3));
  }
  
  
*************** check_alias(
*** 179,190 ****
    View2<T2, Block2>& tensor2)
  {
    fill_block(tensor1.block(), 2);
!   assert(check_tensor(tensor1, 2));
!   assert(check_tensor(tensor2, 2));
  
    fill_block(tensor2.block(), 3);
!   assert(check_tensor(tensor1, 3));
!   assert(check_tensor(tensor2, 3));
  }
  
  
--- 179,190 ----
    View2<T2, Block2>& tensor2)
  {
    fill_block(tensor1.block(), 2);
!   test_assert(check_tensor(tensor1, 2));
!   test_assert(check_tensor(tensor2, 2));
  
    fill_block(tensor2.block(), 3);
!   test_assert(check_tensor(tensor1, 3));
!   test_assert(check_tensor(tensor2, 3));
  }
  
  
*************** tc_assign(length_type i, length_type j, 
*** 334,340 ****
  
    tensor2 = tensor1;
  
!   assert(check_tensor(tensor2, v));
  
    check_not_alias(tensor1, tensor2);
  }
--- 334,340 ----
  
    tensor2 = tensor1;
  
!   test_assert(check_tensor(tensor2, v));
  
    check_not_alias(tensor1, tensor2);
  }
*************** tc_call_sum_const(length_type i, length_
*** 414,420 ****
    fill_block(tensor1.block(), v);
    T sum = tc_sum_const(tensor1);
  
!   assert(equal(sum, T(v*i*(i-1)*j*(j-1)*k*(k-1)/8+i*j*k)));
  }
  
  
--- 414,420 ----
    fill_block(tensor1.block(), v);
    T sum = tc_sum_const(tensor1);
  
!   test_assert(equal(sum, T(v*i*(i-1)*j*(j-1)*k*(k-1)/8+i*j*k)));
  }
  
  
*************** tc_call_sum(length_type i, length_type j
*** 431,437 ****
    fill_block(tensor1.block(), v);
    T sum = tc_sum(tensor1);
  
!   assert(equal(sum, T(v*i*(i-1)*j*(j-1)*k*(k-1)/8+i*j*k)));
  }
  
  
--- 431,437 ----
    fill_block(tensor1.block(), v);
    T sum = tc_sum(tensor1);
  
!   test_assert(equal(sum, T(v*i*(i-1)*j*(j-1)*k*(k-1)/8+i*j*k)));
  }
  
  
*************** tc_assign_return(length_type i, length_t
*** 486,496 ****
    typedef Dense<3, T> block_type;
    View1<T, block_type> tensor1(i, j, k, T());
  
!   assert(tensor1.get(0, 0, 0) != val || val == T());
  
    tensor1 = return_view<View2, T, block_type>(i, j, k, val);
  
!   assert(tensor1.get(0, 0, 0) == val);
  }
  
  
--- 486,496 ----
    typedef Dense<3, T> block_type;
    View1<T, block_type> tensor1(i, j, k, T());
  
!   test_assert(tensor1.get(0, 0, 0) != val || val == T());
  
    tensor1 = return_view<View2, T, block_type>(i, j, k, val);
  
!   test_assert(tensor1.get(0, 0, 0) == val);
  }
  
  
*************** tc_cons_return(length_type i, length_typ
*** 507,513 ****
  
    View1<T, block_type> vec1(return_view<View2, T, block_type>(i, j, k, val));
  
!   assert(vec1.get(0, 0, 0) == val);
  }
  
  
--- 507,513 ----
  
    View1<T, block_type> vec1(return_view<View2, T, block_type>(i, j, k, val));
  
!   test_assert(vec1.get(0, 0, 0) == val);
  }
  
  
*************** tc_subview(Domain<3> const& dom, Domain<
*** 552,570 ****
  	index_type parent_j = sub[1].impl_nth(j);
  	index_type parent_k = sub[2].impl_nth(k);
  
! 	assert(view.get(parent_i, parent_j, parent_k) ==  subv.get(i, j, k));
! 	assert(view.get(parent_i, parent_j, parent_k) == csubv.get(i, j, k));
  
  	view.put(parent_i, parent_j, parent_k,
  		 view.get(parent_i, parent_j, parent_k) + T(1));
  
! 	assert(view.get(parent_i, parent_j, parent_k) ==  subv.get(i, j, k));
! 	assert(view.get(parent_i, parent_j, parent_k) == csubv.get(i, j, k));
  
  	subv.put(i, j, k, subv.get(i, j, k) + T(1));
  
! 	assert(view.get(parent_i, parent_j, parent_k) ==  subv.get(i, j, k));
! 	assert(view.get(parent_i, parent_j, parent_k) == csubv.get(i, j, k));
        }
  }
  
--- 552,570 ----
  	index_type parent_j = sub[1].impl_nth(j);
  	index_type parent_k = sub[2].impl_nth(k);
  
! 	test_assert(view.get(parent_i, parent_j, parent_k) ==  subv.get(i, j, k));
! 	test_assert(view.get(parent_i, parent_j, parent_k) == csubv.get(i, j, k));
  
  	view.put(parent_i, parent_j, parent_k,
  		 view.get(parent_i, parent_j, parent_k) + T(1));
  
! 	test_assert(view.get(parent_i, parent_j, parent_k) ==  subv.get(i, j, k));
! 	test_assert(view.get(parent_i, parent_j, parent_k) == csubv.get(i, j, k));
  
  	subv.put(i, j, k, subv.get(i, j, k) + T(1));
  
! 	test_assert(view.get(parent_i, parent_j, parent_k) ==  subv.get(i, j, k));
! 	test_assert(view.get(parent_i, parent_j, parent_k) == csubv.get(i, j, k));
        }
  }
  
*************** test_complex()
*** 693,702 ****
    cm.put(1, 0, 1, 5.);
    cm.put(0, 1, 1, 5.);
    cm.put(1, 1, 1, 5.);
!   assert(equal(40., tc_sum(rm)));
!   assert(equal(0., tc_sum(im)));
!   assert(equal(40., tc_sum_const(crm)));
!   assert(equal(0., tc_sum_const(cim)));
    rm.put(0, 0, 0, 0.);
    rm.put(1, 0, 0, 0.);
    rm.put(0, 1, 0, 0.);
--- 693,702 ----
    cm.put(1, 0, 1, 5.);
    cm.put(0, 1, 1, 5.);
    cm.put(1, 1, 1, 5.);
!   test_assert(equal(40., tc_sum(rm)));
!   test_assert(equal(0., tc_sum(im)));
!   test_assert(equal(40., tc_sum_const(crm)));
!   test_assert(equal(0., tc_sum_const(cim)));
    rm.put(0, 0, 0, 0.);
    rm.put(1, 0, 0, 0.);
    rm.put(0, 1, 0, 0.);
*************** test_complex()
*** 705,714 ****
    im.put(1, 0, 0, 5.);
    im.put(0, 1, 0, 5.);
    im.put(1, 1, 0, 5.);
!   assert(equal(20., tc_sum(rm)));
!   assert(equal(20., tc_sum(im)));
!   assert(equal(20., tc_sum_const(crm)));
!   assert(equal(20., tc_sum_const(cim)));
  }
  
  void
--- 705,714 ----
    im.put(1, 0, 0, 5.);
    im.put(0, 1, 0, 5.);
    im.put(1, 1, 0, 5.);
!   test_assert(equal(20., tc_sum(rm)));
!   test_assert(equal(20., tc_sum(im)));
!   test_assert(equal(20., tc_sum_const(crm)));
!   test_assert(equal(20., tc_sum_const(cim)));
  }
  
  void
*************** test_const_complex()
*** 718,725 ****
    CTensor cm(2, 2, 2, 5.);
    CTensor::const_realview_type crm = cm.real();
    CTensor::const_imagview_type cim = cm.imag();
!   assert(equal(40., tc_sum_const(crm)));
!   assert(equal(0., tc_sum_const(cim)));
  }
  
  void
--- 718,725 ----
    CTensor cm(2, 2, 2, 5.);
    CTensor::const_realview_type crm = cm.real();
    CTensor::const_imagview_type cim = cm.imag();
!   test_assert(equal(40., tc_sum_const(crm)));
!   test_assert(equal(0., tc_sum_const(cim)));
  }
  
  void
*************** test_subvector0()
*** 729,738 ****
    Tensor<double>::subvector<1, 2>::type v0 = m(Domain<1>(2), 0, 0);
    Tensor<double> const &cm = const_cast<Tensor<double> const&>(m);
    Tensor<double>::subvector<1, 2>::const_type cv0 = cm(Domain<1>(2), 1, 1);
!   assert(equal(3., v0.get(0)));
!   assert(equal(3., v0.get(1)));
!   assert(equal(3., cv0.get(0)));
!   assert(equal(3., cv0.get(1)));
    m.put(0, 0, 0, 0.);
    m.put(1, 0, 0, 1.);
    m.put(0, 1, 0, 2.);
--- 729,738 ----
    Tensor<double>::subvector<1, 2>::type v0 = m(Domain<1>(2), 0, 0);
    Tensor<double> const &cm = const_cast<Tensor<double> const&>(m);
    Tensor<double>::subvector<1, 2>::const_type cv0 = cm(Domain<1>(2), 1, 1);
!   test_assert(equal(3., v0.get(0)));
!   test_assert(equal(3., v0.get(1)));
!   test_assert(equal(3., cv0.get(0)));
!   test_assert(equal(3., cv0.get(1)));
    m.put(0, 0, 0, 0.);
    m.put(1, 0, 0, 1.);
    m.put(0, 1, 0, 2.);
*************** test_subvector0()
*** 741,756 ****
    m.put(1, 0, 1, 5.);
    m.put(0, 1, 1, 6.);
    m.put(1, 1, 1, 7.);
!   assert(equal(0., v0.get(0)));
!   assert(equal(1., v0.get(1)));
!   assert(equal(6., cv0.get(0)));
!   assert(equal(7., cv0.get(1)));
    v0.put(0, 0.);
    v0.put(1, 0.);
!   assert(equal(0., m.get(0, 0, 0)));
!   assert(equal(0., m.get(1, 0, 0)));
!   assert(equal(6., cv0.get(0)));
!   assert(equal(7., cv0.get(1)));
  }
  
  void
--- 741,756 ----
    m.put(1, 0, 1, 5.);
    m.put(0, 1, 1, 6.);
    m.put(1, 1, 1, 7.);
!   test_assert(equal(0., v0.get(0)));
!   test_assert(equal(1., v0.get(1)));
!   test_assert(equal(6., cv0.get(0)));
!   test_assert(equal(7., cv0.get(1)));
    v0.put(0, 0.);
    v0.put(1, 0.);
!   test_assert(equal(0., m.get(0, 0, 0)));
!   test_assert(equal(0., m.get(1, 0, 0)));
!   test_assert(equal(6., cv0.get(0)));
!   test_assert(equal(7., cv0.get(1)));
  }
  
  void
*************** test_const_subvector0()
*** 759,768 ****
    const_Tensor<double> t(2, 2, 2, 3.);
    const_Tensor<double>::subvector<1, 2>::const_type cv1 = t(Domain<1>(2), 0, 0);
    const_Tensor<double>::subvector<1, 2>::const_type cv2 = t(Domain<1>(2), 1, 1);
!   assert(equal(3., cv1.get(0)));
!   assert(equal(3., cv1.get(1)));
!   assert(equal(3., cv2.get(0)));
!   assert(equal(3., cv2.get(1)));
  }
  
  void
--- 759,768 ----
    const_Tensor<double> t(2, 2, 2, 3.);
    const_Tensor<double>::subvector<1, 2>::const_type cv1 = t(Domain<1>(2), 0, 0);
    const_Tensor<double>::subvector<1, 2>::const_type cv2 = t(Domain<1>(2), 1, 1);
!   test_assert(equal(3., cv1.get(0)));
!   test_assert(equal(3., cv1.get(1)));
!   test_assert(equal(3., cv2.get(0)));
!   test_assert(equal(3., cv2.get(1)));
  }
  
  void
*************** test_subvector1()
*** 772,781 ****
    Tensor<double>::subvector<0, 2>::type v0 = m(0, Domain<1>(2), 0);
    Tensor<double> const &cm = const_cast<Tensor<double> const&>(m);
    Tensor<double>::subvector<0, 2>::const_type cv0 = cm(1, Domain<1>(2), 1);
!   assert(equal(3., v0.get(0)));
!   assert(equal(3., v0.get(1)));
!   assert(equal(3., cv0.get(0)));
!   assert(equal(3., cv0.get(1)));
    m.put(0, 0, 0, 0.);
    m.put(1, 0, 0, 1.);
    m.put(0, 1, 0, 2.);
--- 772,781 ----
    Tensor<double>::subvector<0, 2>::type v0 = m(0, Domain<1>(2), 0);
    Tensor<double> const &cm = const_cast<Tensor<double> const&>(m);
    Tensor<double>::subvector<0, 2>::const_type cv0 = cm(1, Domain<1>(2), 1);
!   test_assert(equal(3., v0.get(0)));
!   test_assert(equal(3., v0.get(1)));
!   test_assert(equal(3., cv0.get(0)));
!   test_assert(equal(3., cv0.get(1)));
    m.put(0, 0, 0, 0.);
    m.put(1, 0, 0, 1.);
    m.put(0, 1, 0, 2.);
*************** test_subvector1()
*** 784,799 ****
    m.put(1, 0, 1, 5.);
    m.put(0, 1, 1, 6.);
    m.put(1, 1, 1, 7.);
!   assert(equal(0., v0.get(0)));
!   assert(equal(2., v0.get(1)));
!   assert(equal(5., cv0.get(0)));
!   assert(equal(7., cv0.get(1)));
    v0.put(0, 0.);
    v0.put(1, 0.);
!   assert(equal(0., m.get(0, 0, 0)));
!   assert(equal(0., m.get(0, 1, 0)));
!   assert(equal(5., cv0.get(0)));
!   assert(equal(7., cv0.get(1)));
  }
  
  void
--- 784,799 ----
    m.put(1, 0, 1, 5.);
    m.put(0, 1, 1, 6.);
    m.put(1, 1, 1, 7.);
!   test_assert(equal(0., v0.get(0)));
!   test_assert(equal(2., v0.get(1)));
!   test_assert(equal(5., cv0.get(0)));
!   test_assert(equal(7., cv0.get(1)));
    v0.put(0, 0.);
    v0.put(1, 0.);
!   test_assert(equal(0., m.get(0, 0, 0)));
!   test_assert(equal(0., m.get(0, 1, 0)));
!   test_assert(equal(5., cv0.get(0)));
!   test_assert(equal(7., cv0.get(1)));
  }
  
  void
*************** test_const_subvector1()
*** 802,811 ****
    const_Tensor<double> t(2, 2, 2, 3.);
    const_Tensor<double>::subvector<0, 2>::const_type cv1 = t(0, Domain<1>(2), 0);
    const_Tensor<double>::subvector<0, 2>::const_type cv2 = t(1, Domain<1>(2), 1);
!   assert(equal(3., cv1.get(0)));
!   assert(equal(3., cv1.get(1)));
!   assert(equal(3., cv2.get(0)));
!   assert(equal(3., cv2.get(1)));
  }
  
  void
--- 802,811 ----
    const_Tensor<double> t(2, 2, 2, 3.);
    const_Tensor<double>::subvector<0, 2>::const_type cv1 = t(0, Domain<1>(2), 0);
    const_Tensor<double>::subvector<0, 2>::const_type cv2 = t(1, Domain<1>(2), 1);
!   test_assert(equal(3., cv1.get(0)));
!   test_assert(equal(3., cv1.get(1)));
!   test_assert(equal(3., cv2.get(0)));
!   test_assert(equal(3., cv2.get(1)));
  }
  
  void
*************** test_subvector2()
*** 815,824 ****
    Tensor<double>::subvector<0, 1>::type v0 = m(0, 0, Domain<1>(2));
    Tensor<double> const &cm = const_cast<Tensor<double> const&>(m);
    Tensor<double>::subvector<0, 1>::const_type cv0 = cm(1, 1, Domain<1>(2));
!   assert(equal(3., v0.get(0)));
!   assert(equal(3., v0.get(1)));
!   assert(equal(3., cv0.get(0)));
!   assert(equal(3., cv0.get(1)));
    m.put(0, 0, 0, 0.);
    m.put(1, 0, 0, 1.);
    m.put(0, 1, 0, 2.);
--- 815,824 ----
    Tensor<double>::subvector<0, 1>::type v0 = m(0, 0, Domain<1>(2));
    Tensor<double> const &cm = const_cast<Tensor<double> const&>(m);
    Tensor<double>::subvector<0, 1>::const_type cv0 = cm(1, 1, Domain<1>(2));
!   test_assert(equal(3., v0.get(0)));
!   test_assert(equal(3., v0.get(1)));
!   test_assert(equal(3., cv0.get(0)));
!   test_assert(equal(3., cv0.get(1)));
    m.put(0, 0, 0, 0.);
    m.put(1, 0, 0, 1.);
    m.put(0, 1, 0, 2.);
*************** test_subvector2()
*** 827,842 ****
    m.put(1, 0, 1, 5.);
    m.put(0, 1, 1, 6.);
    m.put(1, 1, 1, 7.);
!   assert(equal(0., v0.get(0)));
!   assert(equal(4., v0.get(1)));
!   assert(equal(3., cv0.get(0)));
!   assert(equal(7., cv0.get(1)));
    v0.put(0, 0.);
    v0.put(1, 0.);
!   assert(equal(0., m.get(0, 0, 0)));
!   assert(equal(0., m.get(0, 0, 1)));
!   assert(equal(3., cv0.get(0)));
!   assert(equal(7., cv0.get(1)));
  }
  
  void
--- 827,842 ----
    m.put(1, 0, 1, 5.);
    m.put(0, 1, 1, 6.);
    m.put(1, 1, 1, 7.);
!   test_assert(equal(0., v0.get(0)));
!   test_assert(equal(4., v0.get(1)));
!   test_assert(equal(3., cv0.get(0)));
!   test_assert(equal(7., cv0.get(1)));
    v0.put(0, 0.);
    v0.put(1, 0.);
!   test_assert(equal(0., m.get(0, 0, 0)));
!   test_assert(equal(0., m.get(0, 0, 1)));
!   test_assert(equal(3., cv0.get(0)));
!   test_assert(equal(7., cv0.get(1)));
  }
  
  void
*************** test_const_subvector2()
*** 845,854 ****
    const_Tensor<double> t(2, 2, 2, 3.);
    const_Tensor<double>::subvector<0, 1>::const_type cv1 = t(0, 0, Domain<1>(2));
    const_Tensor<double>::subvector<0, 1>::const_type cv2 = t(1, 1, Domain<1>(2));
!   assert(equal(3., cv1.get(0)));
!   assert(equal(3., cv1.get(1)));
!   assert(equal(3., cv2.get(0)));
!   assert(equal(3., cv2.get(1)));
  }
  
  void
--- 845,854 ----
    const_Tensor<double> t(2, 2, 2, 3.);
    const_Tensor<double>::subvector<0, 1>::const_type cv1 = t(0, 0, Domain<1>(2));
    const_Tensor<double>::subvector<0, 1>::const_type cv2 = t(1, 1, Domain<1>(2));
!   test_assert(equal(3., cv1.get(0)));
!   test_assert(equal(3., cv1.get(1)));
!   test_assert(equal(3., cv2.get(0)));
!   test_assert(equal(3., cv2.get(1)));
  }
  
  void
*************** test_submatrix0()
*** 860,873 ****
    Tensor<double>::submatrix<0>::const_type cm0 = ct(1,
  						    Domain<1>(2),
  						    Domain<1>(2));
!   assert(equal(3., m0.get(0, 0)));
!   assert(equal(3., m0.get(1, 0)));
!   assert(equal(3., m0.get(0, 1)));
!   assert(equal(3., m0.get(1, 1)));
!   assert(equal(3., cm0.get(0, 0)));
!   assert(equal(3., cm0.get(1, 0)));
!   assert(equal(3., cm0.get(0, 1)));
!   assert(equal(3., cm0.get(1, 1)));
    t.put(0, 0, 0, 0.);
    t.put(1, 0, 0, 1.);
    t.put(0, 1, 0, 2.);
--- 860,873 ----
    Tensor<double>::submatrix<0>::const_type cm0 = ct(1,
  						    Domain<1>(2),
  						    Domain<1>(2));
!   test_assert(equal(3., m0.get(0, 0)));
!   test_assert(equal(3., m0.get(1, 0)));
!   test_assert(equal(3., m0.get(0, 1)));
!   test_assert(equal(3., m0.get(1, 1)));
!   test_assert(equal(3., cm0.get(0, 0)));
!   test_assert(equal(3., cm0.get(1, 0)));
!   test_assert(equal(3., cm0.get(0, 1)));
!   test_assert(equal(3., cm0.get(1, 1)));
    t.put(0, 0, 0, 0.);
    t.put(1, 0, 0, 1.);
    t.put(0, 1, 0, 2.);
*************** test_submatrix0()
*** 876,893 ****
    t.put(1, 0, 1, 5.);
    t.put(0, 1, 1, 6.);
    t.put(1, 1, 1, 7.);
!   assert(equal(0., m0.get(0, 0)));
!   assert(equal(2., m0.get(1, 0)));
!   assert(equal(4., m0.get(0, 1)));
!   assert(equal(6., m0.get(1, 1)));
!   assert(equal(1., cm0.get(0, 0)));
!   assert(equal(3., cm0.get(1, 0)));
!   assert(equal(5., cm0.get(0, 1)));
!   assert(equal(7., cm0.get(1, 1)));
    m0.put(0, 0, 0.);
    m0.put(1, 0, 0.);
!   assert(equal(0., t.get(0, 0, 0)));
!   assert(equal(0., t.get(0, 1, 0)));
  }
  
  void
--- 876,893 ----
    t.put(1, 0, 1, 5.);
    t.put(0, 1, 1, 6.);
    t.put(1, 1, 1, 7.);
!   test_assert(equal(0., m0.get(0, 0)));
!   test_assert(equal(2., m0.get(1, 0)));
!   test_assert(equal(4., m0.get(0, 1)));
!   test_assert(equal(6., m0.get(1, 1)));
!   test_assert(equal(1., cm0.get(0, 0)));
!   test_assert(equal(3., cm0.get(1, 0)));
!   test_assert(equal(5., cm0.get(0, 1)));
!   test_assert(equal(7., cm0.get(1, 1)));
    m0.put(0, 0, 0.);
    m0.put(1, 0, 0.);
!   test_assert(equal(0., t.get(0, 0, 0)));
!   test_assert(equal(0., t.get(0, 1, 0)));
  }
  
  void
*************** test_const_submatrix0()
*** 900,909 ****
    const_Tensor<double>::submatrix<0>::const_type cm2 = ct(1,
  							  Domain<1>(2),
  							  Domain<1>(2));
!   assert(equal(3., cm1.get(0, 0)));
!   assert(equal(3., cm1.get(1, 0)));
!   assert(equal(3., cm2.get(0, 0)));
!   assert(equal(3., cm2.get(1, 0)));
  }
  
  void
--- 900,909 ----
    const_Tensor<double>::submatrix<0>::const_type cm2 = ct(1,
  							  Domain<1>(2),
  							  Domain<1>(2));
!   test_assert(equal(3., cm1.get(0, 0)));
!   test_assert(equal(3., cm1.get(1, 0)));
!   test_assert(equal(3., cm2.get(0, 0)));
!   test_assert(equal(3., cm2.get(1, 0)));
  }
  
  void
*************** test_submatrix1()
*** 915,928 ****
    Tensor<double>::submatrix<1>::const_type cm0 = ct(Domain<1>(2),
  						    1, 
  						    Domain<1>(2));
!   assert(equal(3., m0.get(0, 0)));
!   assert(equal(3., m0.get(1, 0)));
!   assert(equal(3., m0.get(0, 1)));
!   assert(equal(3., m0.get(1, 1)));
!   assert(equal(3., cm0.get(0, 0)));
!   assert(equal(3., cm0.get(1, 0)));
!   assert(equal(3., cm0.get(0, 1)));
!   assert(equal(3., cm0.get(1, 1)));
    t.put(0, 0, 0, 0.);
    t.put(1, 0, 0, 1.);
    t.put(0, 1, 0, 2.);
--- 915,928 ----
    Tensor<double>::submatrix<1>::const_type cm0 = ct(Domain<1>(2),
  						    1, 
  						    Domain<1>(2));
!   test_assert(equal(3., m0.get(0, 0)));
!   test_assert(equal(3., m0.get(1, 0)));
!   test_assert(equal(3., m0.get(0, 1)));
!   test_assert(equal(3., m0.get(1, 1)));
!   test_assert(equal(3., cm0.get(0, 0)));
!   test_assert(equal(3., cm0.get(1, 0)));
!   test_assert(equal(3., cm0.get(0, 1)));
!   test_assert(equal(3., cm0.get(1, 1)));
    t.put(0, 0, 0, 0.);
    t.put(1, 0, 0, 1.);
    t.put(0, 1, 0, 2.);
*************** test_submatrix1()
*** 931,948 ****
    t.put(1, 0, 1, 5.);
    t.put(0, 1, 1, 6.);
    t.put(1, 1, 1, 7.);
!   assert(equal(0., m0.get(0, 0)));
!   assert(equal(1., m0.get(1, 0)));
!   assert(equal(4., m0.get(0, 1)));
!   assert(equal(5., m0.get(1, 1)));
!   assert(equal(2., cm0.get(0, 0)));
!   assert(equal(3., cm0.get(1, 0)));
!   assert(equal(6., cm0.get(0, 1)));
!   assert(equal(7., cm0.get(1, 1)));
    m0.put(0, 0, 0.);
    m0.put(1, 0, 0.);
!   assert(equal(0., t.get(0, 0, 0)));
!   assert(equal(0., t.get(1, 0, 0)));
  }
  
  void
--- 931,948 ----
    t.put(1, 0, 1, 5.);
    t.put(0, 1, 1, 6.);
    t.put(1, 1, 1, 7.);
!   test_assert(equal(0., m0.get(0, 0)));
!   test_assert(equal(1., m0.get(1, 0)));
!   test_assert(equal(4., m0.get(0, 1)));
!   test_assert(equal(5., m0.get(1, 1)));
!   test_assert(equal(2., cm0.get(0, 0)));
!   test_assert(equal(3., cm0.get(1, 0)));
!   test_assert(equal(6., cm0.get(0, 1)));
!   test_assert(equal(7., cm0.get(1, 1)));
    m0.put(0, 0, 0.);
    m0.put(1, 0, 0.);
!   test_assert(equal(0., t.get(0, 0, 0)));
!   test_assert(equal(0., t.get(1, 0, 0)));
  }
  
  void
*************** test_const_submatrix1()
*** 955,964 ****
    const_Tensor<double>::submatrix<1>::const_type cm2 = ct(Domain<1>(2),
  							  1,
  							  Domain<1>(2));
!   assert(equal(3., cm1.get(0, 0)));
!   assert(equal(3., cm1.get(1, 0)));
!   assert(equal(3., cm2.get(0, 0)));
!   assert(equal(3., cm2.get(1, 0)));
  }
  
  void
--- 955,964 ----
    const_Tensor<double>::submatrix<1>::const_type cm2 = ct(Domain<1>(2),
  							  1,
  							  Domain<1>(2));
!   test_assert(equal(3., cm1.get(0, 0)));
!   test_assert(equal(3., cm1.get(1, 0)));
!   test_assert(equal(3., cm2.get(0, 0)));
!   test_assert(equal(3., cm2.get(1, 0)));
  }
  
  void
*************** test_submatrix2()
*** 970,983 ****
    Tensor<double>::submatrix<2>::const_type cm0 = ct(Domain<1>(2),
  						    Domain<1>(2),
  						    1);
!   assert(equal(3., m0.get(0, 0)));
!   assert(equal(3., m0.get(1, 0)));
!   assert(equal(3., m0.get(0, 1)));
!   assert(equal(3., m0.get(1, 1)));
!   assert(equal(3., cm0.get(0, 0)));
!   assert(equal(3., cm0.get(1, 0)));
!   assert(equal(3., cm0.get(0, 1)));
!   assert(equal(3., cm0.get(1, 1)));
    t.put(0, 0, 0, 0.);
    t.put(1, 0, 0, 1.);
    t.put(0, 1, 0, 2.);
--- 970,983 ----
    Tensor<double>::submatrix<2>::const_type cm0 = ct(Domain<1>(2),
  						    Domain<1>(2),
  						    1);
!   test_assert(equal(3., m0.get(0, 0)));
!   test_assert(equal(3., m0.get(1, 0)));
!   test_assert(equal(3., m0.get(0, 1)));
!   test_assert(equal(3., m0.get(1, 1)));
!   test_assert(equal(3., cm0.get(0, 0)));
!   test_assert(equal(3., cm0.get(1, 0)));
!   test_assert(equal(3., cm0.get(0, 1)));
!   test_assert(equal(3., cm0.get(1, 1)));
    t.put(0, 0, 0, 0.);
    t.put(1, 0, 0, 1.);
    t.put(0, 1, 0, 2.);
*************** test_submatrix2()
*** 986,1003 ****
    t.put(1, 0, 1, 5.);
    t.put(0, 1, 1, 6.);
    t.put(1, 1, 1, 7.);
!   assert(equal(0., m0.get(0, 0)));
!   assert(equal(1., m0.get(1, 0)));
!   assert(equal(2., m0.get(0, 1)));
!   assert(equal(3., m0.get(1, 1)));
!   assert(equal(4., cm0.get(0, 0)));
!   assert(equal(5., cm0.get(1, 0)));
!   assert(equal(6., cm0.get(0, 1)));
!   assert(equal(7., cm0.get(1, 1)));
    m0.put(0, 0, 0.);
    m0.put(1, 0, 0.);
!   assert(equal(0., t.get(0, 0, 0)));
!   assert(equal(0., t.get(1, 0, 0)));
  }
  
  void
--- 986,1003 ----
    t.put(1, 0, 1, 5.);
    t.put(0, 1, 1, 6.);
    t.put(1, 1, 1, 7.);
!   test_assert(equal(0., m0.get(0, 0)));
!   test_assert(equal(1., m0.get(1, 0)));
!   test_assert(equal(2., m0.get(0, 1)));
!   test_assert(equal(3., m0.get(1, 1)));
!   test_assert(equal(4., cm0.get(0, 0)));
!   test_assert(equal(5., cm0.get(1, 0)));
!   test_assert(equal(6., cm0.get(0, 1)));
!   test_assert(equal(7., cm0.get(1, 1)));
    m0.put(0, 0, 0.);
    m0.put(1, 0, 0.);
!   test_assert(equal(0., t.get(0, 0, 0)));
!   test_assert(equal(0., t.get(1, 0, 0)));
  }
  
  void
*************** test_const_submatrix2()
*** 1010,1019 ****
    const_Tensor<double>::submatrix<2>::const_type cm2 = ct(Domain<1>(2),
  							  Domain<1>(2),
  							  1);
!   assert(equal(3., cm1.get(0, 0)));
!   assert(equal(3., cm1.get(1, 0)));
!   assert(equal(3., cm2.get(0, 0)));
!   assert(equal(3., cm2.get(1, 0)));
  }
  
  #define VSIP_TEST_ELEMENTWISE_SCALAR(x, op, y)    \
--- 1010,1019 ----
    const_Tensor<double>::submatrix<2>::const_type cm2 = ct(Domain<1>(2),
  							  Domain<1>(2),
  							  1);
!   test_assert(equal(3., cm1.get(0, 0)));
!   test_assert(equal(3., cm1.get(1, 0)));
!   test_assert(equal(3., cm2.get(0, 0)));
!   test_assert(equal(3., cm2.get(1, 0)));
  }
  
  #define VSIP_TEST_ELEMENTWISE_SCALAR(x, op, y)    \
*************** test_const_submatrix2()
*** 1022,1028 ****
    Tensor<int> &m1 = (m op y);		          \
    int r = x;                                      \
    r op y;                                         \
!   assert(&m1 == &m && equal(m1.get(0, 0, 0), r)); \
  }
  
  #define VSIP_TEST_ELEMENTWISE_TENSOR(x, op, y)    \
--- 1022,1028 ----
    Tensor<int> &m1 = (m op y);		          \
    int r = x;                                      \
    r op y;                                         \
!   test_assert(&m1 == &m && equal(m1.get(0, 0, 0), r)); \
  }
  
  #define VSIP_TEST_ELEMENTWISE_TENSOR(x, op, y)    \
*************** test_const_submatrix2()
*** 1032,1038 ****
    Tensor<int> &m1 = (m op n);		          \
    int r = x;                                      \
    r op y;                                         \
!   assert(&m1 == &m && equal(m1.get(0, 0, 0), r)); \
  }
  
  int
--- 1032,1038 ----
    Tensor<int> &m1 = (m op n);		          \
    int r = x;                                      \
    r op y;                                         \
!   test_assert(&m1 == &m && equal(m1.get(0, 0, 0), r)); \
  }
  
  int
Index: tests/tensor_subview.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/tensor_subview.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 tensor_subview.cpp
*** tests/tensor_subview.cpp	19 Sep 2005 03:39:55 -0000	1.2
--- tests/tensor_subview.cpp	20 Dec 2005 12:39:21 -0000
*************** check_v(
*** 102,108 ****
    IndexObj const& obj)
  {
    for (index_type p=0; p<vec.size(); ++p)
!     assert(vec(p) == obj(p));
  }
  
  
--- 102,108 ----
    IndexObj const& obj)
  {
    for (index_type p=0; p<vec.size(); ++p)
!     test_assert(vec(p) == obj(p));
  }
  
  
*************** check_ext_v(
*** 140,146 ****
  
    for (index_type p=0; p<size; ++p)
    {
!     assert(*ptr == obj(p));
      ptr += stride;
    }
  }
--- 140,146 ----
  
    for (index_type p=0; p<size; ++p)
    {
!     test_assert(*ptr == obj(p));
      ptr += stride;
    }
  }
*************** t_subvector(
*** 179,190 ****
    // Check vector lengths.
    length_type size = vec1.size();
  
!   assert(vec1.size() == size);
!   assert(vec2.size() == size);
!   assert(vec3.size() == size);
!   assert(vec1.size(0) == size);
!   assert(vec2.size(0) == size);
!   assert(vec3.size(0) == size);
  
    // Test vector assignment.
    Vector<T> new1(size); set_v(new1, obj1);
--- 179,190 ----
    // Check vector lengths.
    length_type size = vec1.size();
  
!   test_assert(vec1.size() == size);
!   test_assert(vec2.size() == size);
!   test_assert(vec3.size() == size);
!   test_assert(vec1.size(0) == size);
!   test_assert(vec2.size(0) == size);
!   test_assert(vec3.size(0) == size);
  
    // Test vector assignment.
    Vector<T> new1(size); set_v(new1, obj1);
*************** test_tensor_vector()
*** 241,253 ****
        for (index_type p=0; p<P; ++p)
  	ten(m, n, p) = val1(m,n,p);
  
!   assert(ten(whole, 0, 0).size() == M);
!   assert(ten(0, whole, 0).size() == N);
!   assert(ten(0, 0, whole).size() == P);
! 
!   assert(ten(whole, 0, 0).size(0) == M);
!   assert(ten(0, whole, 0).size(0) == N);
!   assert(ten(0, 0, whole).size(0) == P);
  
  
    for (index_type m=0; m<M; ++m)
--- 241,253 ----
        for (index_type p=0; p<P; ++p)
  	ten(m, n, p) = val1(m,n,p);
  
!   test_assert(ten(whole, 0, 0).size() == M);
!   test_assert(ten(0, whole, 0).size() == N);
!   test_assert(ten(0, 0, whole).size() == P);
! 
!   test_assert(ten(whole, 0, 0).size(0) == M);
!   test_assert(ten(0, whole, 0).size(0) == N);
!   test_assert(ten(0, 0, whole).size(0) == P);
  
  
    for (index_type m=0; m<M; ++m)
*************** test_tensor_matrix()
*** 302,319 ****
        for (index_type p=0; p<P; ++p)
  	ten(m, n, p) = val1(m,n,p);
  
!   assert(ten(whole, whole, 0).size() == M*N);
!   assert(ten(whole, 0, whole).size() == M*P);
!   assert(ten(0, whole, whole).size() == N*P);
  
!   assert(ten(whole, whole, 0).size(0) == M);
!   assert(ten(whole, whole, 0).size(1) == N);
  
!   assert(ten(whole, 0, whole).size(0) == M);
!   assert(ten(whole, 0, whole).size(1) == P);
  
!   assert(ten(0, whole, whole).size(0) == N);
!   assert(ten(0, whole, whole).size(1) == P);
  }
    
  
--- 302,319 ----
        for (index_type p=0; p<P; ++p)
  	ten(m, n, p) = val1(m,n,p);
  
!   test_assert(ten(whole, whole, 0).size() == M*N);
!   test_assert(ten(whole, 0, whole).size() == M*P);
!   test_assert(ten(0, whole, whole).size() == N*P);
  
!   test_assert(ten(whole, whole, 0).size(0) == M);
!   test_assert(ten(whole, whole, 0).size(1) == N);
  
!   test_assert(ten(whole, 0, whole).size(0) == M);
!   test_assert(ten(whole, 0, whole).size(1) == P);
  
!   test_assert(ten(0, whole, whole).size(0) == N);
!   test_assert(ten(0, whole, whole).size(1) == P);
  }
    
  
Index: tests/test.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/test.hpp,v
retrieving revision 1.10
diff -c -p -r1.10 test.hpp
*** tests/test.hpp	13 Dec 2005 20:35:54 -0000	1.10
--- tests/test.hpp	20 Dec 2005 12:39:21 -0000
*************** equal(T val1, T val2)
*** 87,92 ****
--- 87,112 ----
    return val1 == val2;
  }
  
+ template <typename             Block,
+ 	  vsip::dimension_type Dim>
+ inline bool
+ equal(
+   vsip::impl::Lvalue_proxy<Block, Dim> const&               val1, 
+   typename vsip::impl::Lvalue_proxy<Block, Dim>::value_type val2)
+ {
+   return val1 == val2;
+ }
+ 
+ template <typename             Block,
+ 	  vsip::dimension_type Dim>
+ inline bool
+ equal(
+   typename vsip::impl::Lvalue_proxy<Block, Dim>::value_type val1,
+   vsip::impl::Lvalue_proxy<Block, Dim> const&               val2) 
+ {
+   return val1 == val2;
+ }
+ 
  
  
  /// Compare two floating point values for equality within epsilon.
Index: tests/user_storage.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/user_storage.cpp,v
retrieving revision 1.5
diff -c -p -r1.5 user_storage.cpp
*** tests/user_storage.cpp	5 Aug 2005 15:43:48 -0000	1.5
--- tests/user_storage.cpp	20 Dec 2005 12:39:21 -0000
*************** rebind_array(
*** 272,294 ****
  
    block.rebind(data);
  
!   assert(block.admitted()     == false);
!   assert(block.user_storage() == array_format); // rebind could change format
  
    block.find(ptr);
!   assert(ptr == data);
  
    block.admit(true);
!   assert(block.admitted() == true);
  
!   assert(check_block<Order>(block, dom, Filler<T>(k, 1)));
  
    fill_block<Order>(block, dom, Filler<T>(k+1, 1));
  
    block.release(true);
!   assert(block.admitted() == false);
  
!   assert(check_array<Order>(data, dom, Filler<T>(k+1, 1)));
  
    delete[] data;
  }
--- 272,294 ----
  
    block.rebind(data);
  
!   test_assert(block.admitted()     == false);
!   test_assert(block.user_storage() == array_format); // rebind could change format
  
    block.find(ptr);
!   test_assert(ptr == data);
  
    block.admit(true);
!   test_assert(block.admitted() == true);
  
!   test_assert(check_block<Order>(block, dom, Filler<T>(k, 1)));
  
    fill_block<Order>(block, dom, Filler<T>(k+1, 1));
  
    block.release(true);
!   test_assert(block.admitted() == false);
  
!   test_assert(check_array<Order>(data, dom, Filler<T>(k+1, 1)));
  
    delete[] data;
  }
*************** rebind_split(
*** 316,338 ****
  
    block.rebind(real, imag);
  
!   assert(block.admitted()     == false);
!   assert(block.user_storage() == split_format); // rebind could change format
  
    block.find(real_ptr, imag_ptr);
!   assert(real_ptr == real);
!   assert(imag_ptr == imag);
  
    block.admit(true);
!   assert(block.admitted() == true);
  
!   assert(check_block<Order>(block, dom, CFiller<T>(k, 0, 1)));
    fill_block<Order>(block, dom, CFiller<T>(k+1, 0, 1));
  
    block.release(true);
!   assert(block.admitted() == false);
  
!   assert(check_split_array<Order>(real, imag, dom, CFiller<T>(k+1, 0, 1)));
  
    delete[] real;
    delete[] imag;
--- 316,338 ----
  
    block.rebind(real, imag);
  
!   test_assert(block.admitted()     == false);
!   test_assert(block.user_storage() == split_format); // rebind could change format
  
    block.find(real_ptr, imag_ptr);
!   test_assert(real_ptr == real);
!   test_assert(imag_ptr == imag);
  
    block.admit(true);
!   test_assert(block.admitted() == true);
  
!   test_assert(check_block<Order>(block, dom, CFiller<T>(k, 0, 1)));
    fill_block<Order>(block, dom, CFiller<T>(k+1, 0, 1));
  
    block.release(true);
!   test_assert(block.admitted() == false);
  
!   test_assert(check_split_array<Order>(real, imag, dom, CFiller<T>(k+1, 0, 1)));
  
    delete[] real;
    delete[] imag;
*************** rebind_interleaved(
*** 358,379 ****
  
    block.rebind(data);
    
!   assert(block.admitted()     == false);
!   assert(block.user_storage() == interleaved_format);
  
    block.find(ptr);
!   assert(ptr == data);
  
    block.admit(true);
!   assert(block.admitted() == true);
  
!   assert(check_block<Order>(block, dom, CFiller<T>(k, 0, 1)));
    fill_block<Order>(block, dom, CFiller<T>(k+1, 0, 1));
  
    block.release(true);
!   assert(block.admitted() == false);
  
!   assert(check_interleaved_array<Order>(data, dom, CFiller<T>(k+1, 0, 1)));
  
    delete[] data;
  }
--- 358,379 ----
  
    block.rebind(data);
    
!   test_assert(block.admitted()     == false);
!   test_assert(block.user_storage() == interleaved_format);
  
    block.find(ptr);
!   test_assert(ptr == data);
  
    block.admit(true);
!   test_assert(block.admitted() == true);
  
!   test_assert(check_block<Order>(block, dom, CFiller<T>(k, 0, 1)));
    fill_block<Order>(block, dom, CFiller<T>(k+1, 0, 1));
  
    block.release(true);
!   test_assert(block.admitted() == false);
  
!   test_assert(check_interleaved_array<Order>(data, dom, CFiller<T>(k+1, 0, 1)));
  
    delete[] data;
  }
*************** test_array_format(
*** 403,434 ****
  
    Dense<Dim, T, Order> block(dom, data);
  
!   assert(block.admitted()     == false);
!   assert(block.user_storage() == array_format);
  
    // Check find()
    block.find(ptr);
!   assert(ptr == data);
  
    fill_array<Order>(data, dom, Filler<T>(3, 0));
  
    block.admit(true);
!   assert(block.admitted() == true);
  
!   assert(check_block<Order>(block, dom, Filler<T>(3, 0)));
  
    fill_block<Order>(block, dom, Filler<T>(3, 1));
  
    block.release(true);
!   assert(block.admitted() == false);
  
!   assert(check_array<Order>(data, dom, Filler<T>(3, 1)));
  
    // Check release with pointer
    block.admit(true);
    block.release(true, ptr);
  
!   assert(ptr == data);
  
    delete[] data;
  
--- 403,434 ----
  
    Dense<Dim, T, Order> block(dom, data);
  
!   test_assert(block.admitted()     == false);
!   test_assert(block.user_storage() == array_format);
  
    // Check find()
    block.find(ptr);
!   test_assert(ptr == data);
  
    fill_array<Order>(data, dom, Filler<T>(3, 0));
  
    block.admit(true);
!   test_assert(block.admitted() == true);
  
!   test_assert(check_block<Order>(block, dom, Filler<T>(3, 0)));
  
    fill_block<Order>(block, dom, Filler<T>(3, 1));
  
    block.release(true);
!   test_assert(block.admitted() == false);
  
!   test_assert(check_array<Order>(data, dom, Filler<T>(3, 1)));
  
    // Check release with pointer
    block.admit(true);
    block.release(true, ptr);
  
!   test_assert(ptr == data);
  
    delete[] data;
  
*************** test_interleaved_format(
*** 456,485 ****
  
    Dense<Dim, complex<T>, Order> block(dom, data);
  
!   assert(block.admitted()     == false);
!   assert(block.user_storage() == interleaved_format);
  
    block.find(ptr);
!   assert(ptr == data);
  
    fill_interleaved_array<Order>(data, dom, CFiller<T>(3, 0, 2));
  
    block.admit(true);
!   assert(block.admitted() == true);
  
!   assert(check_block<Order>(block, dom, CFiller<T>(3, 0, 2)));
    fill_block<Order>(block, dom, CFiller<T>(3, 2, 1));
  
    block.release(true);
!   assert(block.admitted() == false);
  
!   assert(check_interleaved_array<Order>(data, dom, CFiller<T>(3, 2, 1)));
  
    // Check release with pointer
    block.admit(true);
    block.release(true, ptr);
  
!   assert(ptr == data);
  
    delete[] data;
  
--- 456,485 ----
  
    Dense<Dim, complex<T>, Order> block(dom, data);
  
!   test_assert(block.admitted()     == false);
!   test_assert(block.user_storage() == interleaved_format);
  
    block.find(ptr);
!   test_assert(ptr == data);
  
    fill_interleaved_array<Order>(data, dom, CFiller<T>(3, 0, 2));
  
    block.admit(true);
!   test_assert(block.admitted() == true);
  
!   test_assert(check_block<Order>(block, dom, CFiller<T>(3, 0, 2)));
    fill_block<Order>(block, dom, CFiller<T>(3, 2, 1));
  
    block.release(true);
!   test_assert(block.admitted() == false);
  
!   test_assert(check_interleaved_array<Order>(data, dom, CFiller<T>(3, 2, 1)));
  
    // Check release with pointer
    block.admit(true);
    block.release(true, ptr);
  
!   test_assert(ptr == data);
  
    delete[] data;
  
*************** test_split_format(
*** 511,542 ****
  
    Dense<Dim, complex<T>, Order> block(dom, real, imag);
  
!   assert(block.admitted()     == false);
!   assert(block.user_storage() == split_format);
  
    block.find(real_ptr, imag_ptr);
!   assert(real_ptr == real);
!   assert(imag_ptr == imag);
  
    fill_split_array<Order>(real, imag, dom, CFiller<T>(3, 0, 2));
  
    block.admit(true);
!   assert(block.admitted() == true);
  
!   assert(check_block<Order>(block, dom, CFiller<T>(3, 0, 2)));
    fill_block<Order>(block, dom, CFiller<T>(3, 2, 1));
  
    block.release(true);
!   assert(block.admitted() == false);
  
!   assert(check_split_array<Order>(real, imag, dom, CFiller<T>(3, 2, 1)));
  
    // Check release with pointer
    block.admit(true);
    block.release(true, real_ptr, imag_ptr);
  
!   assert(real_ptr == real);
!   assert(imag_ptr == imag);
  
    delete[] real;
    delete[] imag;
--- 511,542 ----
  
    Dense<Dim, complex<T>, Order> block(dom, real, imag);
  
!   test_assert(block.admitted()     == false);
!   test_assert(block.user_storage() == split_format);
  
    block.find(real_ptr, imag_ptr);
!   test_assert(real_ptr == real);
!   test_assert(imag_ptr == imag);
  
    fill_split_array<Order>(real, imag, dom, CFiller<T>(3, 0, 2));
  
    block.admit(true);
!   test_assert(block.admitted() == true);
  
!   test_assert(check_block<Order>(block, dom, CFiller<T>(3, 0, 2)));
    fill_block<Order>(block, dom, CFiller<T>(3, 2, 1));
  
    block.release(true);
!   test_assert(block.admitted() == false);
  
!   test_assert(check_split_array<Order>(real, imag, dom, CFiller<T>(3, 2, 1)));
  
    // Check release with pointer
    block.admit(true);
    block.release(true, real_ptr, imag_ptr);
  
!   test_assert(real_ptr == real);
!   test_assert(imag_ptr == imag);
  
    delete[] real;
    delete[] imag;
Index: tests/vector.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/vector.cpp,v
retrieving revision 1.9
diff -c -p -r1.9 vector.cpp
*** tests/vector.cpp	11 Nov 2005 21:36:13 -0000	1.9
--- tests/vector.cpp	20 Dec 2005 12:39:21 -0000
*************** template <typename T,
*** 50,58 ****
  void
  check_length(const_Vector<T, Block> vec, length_type len)
  {
!   assert(vec.length() == len);
!   assert(vec.size() == len);
!   assert(vec.size(0) == len);
  }
  
  
--- 50,58 ----
  void
  check_length(const_Vector<T, Block> vec, length_type len)
  {
!   test_assert(vec.length() == len);
!   test_assert(vec.size() == len);
!   test_assert(vec.size(0) == len);
  }
  
  
*************** void
*** 99,105 ****
  test_vector(const_Vector<T, Block> vec, int k)
  {
    for (index_type i=0; i<vec.size(0); ++i)
!     assert(equal(vec.get(i), T(k*i+1)));
  }
  
  
--- 99,105 ----
  test_vector(const_Vector<T, Block> vec, int k)
  {
    for (index_type i=0; i<vec.size(0); ++i)
!     test_assert(equal(vec.get(i), T(k*i+1)));
  }
  
  
*************** test_vector(const_Vector<T, Block> vec, 
*** 108,115 ****
  //
  // Checks that vector values match those generated by a call to
  // fill_vector or fill_block with the same k value.  Rather than
! // triggering assertion failure, check_vector returns a boolean
! // pass/fail that can be used to cause an assertion failure in
  // the caller.
  
  template <typename T,
--- 108,115 ----
  //
  // Checks that vector values match those generated by a call to
  // fill_vector or fill_block with the same k value.  Rather than
! // triggering test_assertion failure, check_vector returns a boolean
! // pass/fail that can be used to cause an test_assertion failure in
  // the caller.
  
  template <typename T,
*************** check_not_alias(
*** 144,154 ****
    fill_block(vec2.block(), 3);
  
    // Make sure that updates to vec2 do not affect vec1.
!   assert(check_vector(vec1, 2));
  
    // And visa-versa.
    fill_block(vec1.block(), 4);
!   assert(check_vector(vec2, 3));
  }
  
  
--- 144,154 ----
    fill_block(vec2.block(), 3);
  
    // Make sure that updates to vec2 do not affect vec1.
!   test_assert(check_vector(vec1, 2));
  
    // And visa-versa.
    fill_block(vec1.block(), 4);
!   test_assert(check_vector(vec2, 3));
  }
  
  
*************** check_alias(
*** 169,180 ****
    View2<T2, Block2>& vec2)
  {
    fill_block(vec1.block(), 2);
!   assert(check_vector(vec1, 2));
!   assert(check_vector(vec2, 2));
  
    fill_block(vec2.block(), 3);
!   assert(check_vector(vec1, 3));
!   assert(check_vector(vec2, 3));
  }
  
  
--- 169,180 ----
    View2<T2, Block2>& vec2)
  {
    fill_block(vec1.block(), 2);
!   test_assert(check_vector(vec1, 2));
!   test_assert(check_vector(vec2, 2));
  
    fill_block(vec2.block(), 3);
!   test_assert(check_vector(vec1, 3));
!   test_assert(check_vector(vec2, 3));
  }
  
  
*************** tc_assign(length_type len, int k)
*** 330,336 ****
  
    vec2 = vec1;
  
!   assert(check_vector(vec2, k));
  
    check_not_alias(vec1, vec2);
  }
--- 330,336 ----
  
    vec2 = vec1;
  
!   test_assert(check_vector(vec2, k));
  
    check_not_alias(vec1, vec2);
  }
*************** tc_call_sum_const(length_type len, int k
*** 408,414 ****
    fill_block(vec1.block(), k);
    T sum = tc_sum_const(vec1);
  
!   assert(equal(sum, T(k*len*(len-1)/2+len)));
  }
  
  
--- 408,414 ----
    fill_block(vec1.block(), k);
    T sum = tc_sum_const(vec1);
  
!   test_assert(equal(sum, T(k*len*(len-1)/2+len)));
  }
  
  
*************** tc_call_sum(length_type len, int k)
*** 425,431 ****
    fill_block(vec1.block(), k);
    T sum = tc_sum(vec1);
  
!   assert(equal(sum, T(k*len*(len-1)/2+len)));
  }
  
  
--- 425,431 ----
    fill_block(vec1.block(), k);
    T sum = tc_sum(vec1);
  
!   test_assert(equal(sum, T(k*len*(len-1)/2+len)));
  }
  
  
*************** tc_assign_return(length_type len, T val)
*** 482,492 ****
    typedef Dense<1, T> block_type;
    View1<T, block_type> vec1(len, T());
  
!   assert(vec1.get(0) != val || val == T());
  
    vec1 = return_view<View2, T, block_type>(len, val);
  
!   assert(vec1.get(0) == val);
  }
  
  
--- 482,492 ----
    typedef Dense<1, T> block_type;
    View1<T, block_type> vec1(len, T());
  
!   test_assert(vec1.get(0) != val || val == T());
  
    vec1 = return_view<View2, T, block_type>(len, val);
  
!   test_assert(vec1.get(0) == val);
  }
  
  
*************** tc_cons_return(length_type len, T val)
*** 503,509 ****
  
    View1<T, block_type> vec1(return_view<View2, T, block_type>(len, val));
  
!   assert(vec1.get(0) == val);
  }
  
  
--- 503,509 ----
  
    View1<T, block_type> vec1(return_view<View2, T, block_type>(len, val));
  
!   test_assert(vec1.get(0) == val);
  }
  
  
*************** tc_subview(Domain<1> const& dom, Domain<
*** 544,561 ****
    {
      index_type parent_i = sub.impl_nth(i);
  
!     assert(view.get(parent_i) ==  subv.get(i));
!     assert(view.get(parent_i) == csubv.get(i));
  
      view.put(parent_i, view.get(parent_i) + T(1));
  
!     assert(view.get(parent_i) ==  subv.get(i));
!     assert(view.get(parent_i) == csubv.get(i));
  
      subv.put(i, subv.get(i) + T(1));
  
!     assert(view.get(parent_i) ==  subv.get(i));
!     assert(view.get(parent_i) == csubv.get(i));
    }
  }
  
--- 544,561 ----
    {
      index_type parent_i = sub.impl_nth(i);
  
!     test_assert(view.get(parent_i) ==  subv.get(i));
!     test_assert(view.get(parent_i) == csubv.get(i));
  
      view.put(parent_i, view.get(parent_i) + T(1));
  
!     test_assert(view.get(parent_i) ==  subv.get(i));
!     test_assert(view.get(parent_i) == csubv.get(i));
  
      subv.put(i, subv.get(i) + T(1));
  
!     test_assert(view.get(parent_i) ==  subv.get(i));
!     test_assert(view.get(parent_i) == csubv.get(i));
    }
  }
  
*************** test_complex()
*** 591,608 ****
    CVector::const_imagview_type civ = const_cast<CVector const&>(cv).imag();
    cv.put(0, 5.);
    cv.put(1, 5.);
!   assert(equal(10., tc_sum(rv)));
!   assert(equal(0., tc_sum(iv)));
!   assert(equal(10., tc_sum_const(crv)));
!   assert(equal(0., tc_sum_const(civ)));
    rv.put(0, 0.);
    rv.put(1, 0.);
    iv.put(0, 5.);
    iv.put(1, 5.);
!   assert(equal(0., tc_sum(rv)));
!   assert(equal(10., tc_sum(iv)));
!   assert(equal(0., tc_sum_const(crv)));
!   assert(equal(10., tc_sum_const(civ)));
  }
  
  void
--- 591,608 ----
    CVector::const_imagview_type civ = const_cast<CVector const&>(cv).imag();
    cv.put(0, 5.);
    cv.put(1, 5.);
!   test_assert(equal(10., tc_sum(rv)));
!   test_assert(equal(0., tc_sum(iv)));
!   test_assert(equal(10., tc_sum_const(crv)));
!   test_assert(equal(0., tc_sum_const(civ)));
    rv.put(0, 0.);
    rv.put(1, 0.);
    iv.put(0, 5.);
    iv.put(1, 5.);
!   test_assert(equal(0., tc_sum(rv)));
!   test_assert(equal(10., tc_sum(iv)));
!   test_assert(equal(0., tc_sum_const(crv)));
!   test_assert(equal(10., tc_sum_const(civ)));
  }
  
  void
*************** test_const_complex()
*** 612,619 ****
    CVector cv(2, 5.);
    CVector::const_realview_type crv = cv.real();
    CVector::const_imagview_type civ = cv.imag();
!   assert(equal(10., tc_sum_const(crv)));
!   assert(equal(0., tc_sum_const(civ)));
  }
  
  #define VSIP_TEST_ELEMENTWISE_SCALAR(x, op, y) \
--- 612,619 ----
    CVector cv(2, 5.);
    CVector::const_realview_type crv = cv.real();
    CVector::const_imagview_type civ = cv.imag();
!   test_assert(equal(10., tc_sum_const(crv)));
!   test_assert(equal(0., tc_sum_const(civ)));
  }
  
  #define VSIP_TEST_ELEMENTWISE_SCALAR(x, op, y) \
*************** test_const_complex()
*** 622,628 ****
    Vector<int> &v1 = (v op y);		       \
    int r = x;                                   \
    r op y;                                      \
!   assert(&v1 == &v && equal(v1.get(0), r));    \
  }
  
  #define VSIP_TEST_ELEMENTWISE_VECTOR(x, op, y) \
--- 622,628 ----
    Vector<int> &v1 = (v op y);		       \
    int r = x;                                   \
    r op y;                                      \
!   test_assert(&v1 == &v && equal(v1.get(0), r));    \
  }
  
  #define VSIP_TEST_ELEMENTWISE_VECTOR(x, op, y) \
*************** test_const_complex()
*** 632,638 ****
    Vector<int> &v1 = (v op w);		       \
    int r = x;                                   \
    r op y;                                      \
!   assert(&v1 == &v && equal(v1.get(0), r));    \
  }
  
  int
--- 632,638 ----
    Vector<int> &v1 = (v op w);		       \
    int r = x;                                   \
    r op y;                                      \
!   test_assert(&v1 == &v && equal(v1.get(0), r));    \
  }
  
  int
*************** main()
*** 677,688 ****
    {
      Vector<bool> v(1, true);
      Vector<bool>  w = !v;
!     assert(w.get(0) == false);
    }
    // operator~
    {
      Vector<int> v(1, 3);
      Vector<int>  w = ~v;
!     assert(w.get(0) == ~3);
    }
  }
--- 677,688 ----
    {
      Vector<bool> v(1, true);
      Vector<bool>  w = !v;
!     test_assert(w.get(0) == false);
    }
    // operator~
    {
      Vector<int> v(1, 3);
      Vector<int>  w = ~v;
!     test_assert(w.get(0) == ~3);
    }
  }
Index: tests/view.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/view.cpp,v
retrieving revision 1.9
diff -c -p -r1.9 view.cpp
*** tests/view.cpp	8 Aug 2005 09:14:59 -0000	1.9
--- tests/view.cpp	20 Dec 2005 12:39:21 -0000
*************** check_size(
*** 88,96 ****
    const_Vector<T, Block> view,
    Domain<1> const&       dom)
  {
!   assert(view.length() == dom.length());
!   assert(view.size()   == dom.length());
!   assert(view.size(0)  == dom.length());
  }
  
  
--- 88,96 ----
    const_Vector<T, Block> view,
    Domain<1> const&       dom)
  {
!   test_assert(view.length() == dom.length());
!   test_assert(view.size()   == dom.length());
!   test_assert(view.size(0)  == dom.length());
  }
  
  
*************** check_size(
*** 104,112 ****
    const_Matrix<T, Block> view,
    Domain<2> const&       dom)
  {
!   assert(view.size()  == dom[0].length() * dom[1].length());
!   assert(view.size(0) == dom[0].length());
!   assert(view.size(1) == dom[1].length());
  }
  
  
--- 104,112 ----
    const_Matrix<T, Block> view,
    Domain<2> const&       dom)
  {
!   test_assert(view.size()  == dom[0].length() * dom[1].length());
!   test_assert(view.size(0) == dom[0].length());
!   test_assert(view.size(1) == dom[1].length());
  }
  
  
*************** void
*** 258,264 ****
  test_view(const_Vector<T, Block> vec, int k)
  {
    for (index_type i=0; i<vec.size(0); ++i)
!     assert(equal(vec.get(i), T(k*i+1)));
  }
  
  
--- 258,264 ----
  test_view(const_Vector<T, Block> vec, int k)
  {
    for (index_type i=0; i<vec.size(0); ++i)
!     test_assert(equal(vec.get(i), T(k*i+1)));
  }
  
  
*************** test_view(const_Matrix<T, Block> v, int 
*** 277,283 ****
      for (index_type c=0; c<v.size(1); ++c)
      {
        index_type i = r*v.size(1) + c;
!       assert(equal(v.get(r, c), T(k*i+1)));
      }
  }
  
--- 277,283 ----
      for (index_type c=0; c<v.size(1); ++c)
      {
        index_type i = r*v.size(1) + c;
!       test_assert(equal(v.get(r, c), T(k*i+1)));
      }
  }
  
*************** test_view(const_Matrix<T, Block> v, int 
*** 287,294 ****
  //
  // Checks that vector values match those generated by a call to
  // fill_vector or fill_block with the same k value.  Rather than
! // triggering assertion failure, check_vector returns a boolean
! // pass/fail that can be used to cause an assertion failure in
  // the caller.
  
  template <typename T,
--- 287,294 ----
  //
  // Checks that vector values match those generated by a call to
  // fill_vector or fill_block with the same k value.  Rather than
! // triggering test_assertion failure, check_vector returns a boolean
! // pass/fail that can be used to cause an test_assertion failure in
  // the caller.
  
  template <typename T,
*************** check_view(const_Vector<T, Block> vec, i
*** 308,315 ****
  //
  // Checks that view values match those generated by a call to
  // fill_view or fill_block with the same k value.  Rather than
! // triggering assertion failure, check_view returns a boolean
! // pass/fail that can be used to cause an assertion failure in
  // the caller.
  
  template <typename T,
--- 308,315 ----
  //
  // Checks that view values match those generated by a call to
  // fill_view or fill_block with the same k value.  Rather than
! // triggering test_assertion failure, check_view returns a boolean
! // pass/fail that can be used to cause an test_assertion failure in
  // the caller.
  
  template <typename T,
*************** check_not_alias(
*** 380,397 ****
    View1<T1, Block1>& view1,
    View2<T2, Block2>& view2)
  {
!   assert((View1<T1, Block1>::dim == View2<T2, Block2>::dim));
    dimension_type const dim = View1<T1, Block1>::dim;
  
    fill_block<dim>(view1.block(), 2);
    fill_block<dim>(view2.block(), 3);
  
    // Make sure that updates to view2 do not affect view1.
!   assert(check_view(view1, 2));
  
    // And visa-versa.
    fill_block<dim>(view1.block(), 4);
!   assert(check_view(view2, 3));
  }
  
  
--- 380,397 ----
    View1<T1, Block1>& view1,
    View2<T2, Block2>& view2)
  {
!   test_assert((View1<T1, Block1>::dim == View2<T2, Block2>::dim));
    dimension_type const dim = View1<T1, Block1>::dim;
  
    fill_block<dim>(view1.block(), 2);
    fill_block<dim>(view2.block(), 3);
  
    // Make sure that updates to view2 do not affect view1.
!   test_assert(check_view(view1, 2));
  
    // And visa-versa.
    fill_block<dim>(view1.block(), 4);
!   test_assert(check_view(view2, 3));
  }
  
  
*************** check_alias(
*** 411,426 ****
    View1<T1, Block1>& view1,
    View2<T2, Block2>& view2)
  {
!   assert((View1<T1, Block1>::dim == View2<T2, Block2>::dim));
    dimension_type const dim = View1<T1, Block1>::dim;
  
    fill_block<dim>(view1.block(), 2);
!   assert(check_view(view1, 2));
!   assert(check_view(view2, 2));
  
    fill_block<dim>(view2.block(), 3);
!   assert(check_view(view1, 3));
!   assert(check_view(view2, 3));
  }
  
  
--- 411,426 ----
    View1<T1, Block1>& view1,
    View2<T2, Block2>& view2)
  {
!   test_assert((View1<T1, Block1>::dim == View2<T2, Block2>::dim));
    dimension_type const dim = View1<T1, Block1>::dim;
  
    fill_block<dim>(view1.block(), 2);
!   test_assert(check_view(view1, 2));
!   test_assert(check_view(view2, 2));
  
    fill_block<dim>(view2.block(), 3);
!   test_assert(check_view(view1, 3));
!   test_assert(check_view(view2, 3));
  }
  
  
*************** tc_assign(Domain<Dim> const& dom, int k)
*** 607,621 ****
  
    stor2.view = stor1.view;
  
!   assert(check_view(stor2.view, k));
  
    check_not_alias(stor1.view, stor2.view);
  
  
    fill_block<Dim>(stor1.block(), k+1);
    stor2b.view = stor2.view = stor1.view;
!   assert(check_view(stor2.view,  k+1));
!   assert(check_view(stor2b.view, k+1));
  }
  
  
--- 607,621 ----
  
    stor2.view = stor1.view;
  
!   test_assert(check_view(stor2.view, k));
  
    check_not_alias(stor1.view, stor2.view);
  
  
    fill_block<Dim>(stor1.block(), k+1);
    stor2b.view = stor2.view = stor1.view;
!   test_assert(check_view(stor2.view,  k+1));
!   test_assert(check_view(stor2b.view, k+1));
  }
  
  
*************** tc_assign_scalar(
*** 680,691 ****
  
    stor1.view = T(k);
  
!   assert(check_view_const(stor1.view, T(k)));
  
    stor1.view = stor2.view = T(k+1);
  
!   assert(check_view_const(stor1.view, T(k+1)));
!   assert(check_view_const(stor2.view, T(k+1)));
  }
  
  
--- 680,691 ----
  
    stor1.view = T(k);
  
!   test_assert(check_view_const(stor1.view, T(k)));
  
    stor1.view = stor2.view = T(k+1);
  
!   test_assert(check_view_const(stor1.view, T(k+1)));
!   test_assert(check_view_const(stor2.view, T(k+1)));
  }
  
  
*************** tc_call_sum_const(Domain<Dim> const& dom
*** 807,813 ****
  	 << "  expected: " << T(k*len*(len-1)/2+len) << endl
  	 << "  got     : " << sum << endl;
    }
!   assert(equal(sum, T(k*len*(len-1)/2+len)));
  }
  
  
--- 807,813 ----
  	 << "  expected: " << T(k*len*(len-1)/2+len) << endl
  	 << "  got     : " << sum << endl;
    }
!   test_assert(equal(sum, T(k*len*(len-1)/2+len)));
  }
  
  
*************** tc_call_sum(Domain<Dim> const& dom, int 
*** 825,831 ****
    T sum = tc_sum(stor1.view);
  
    length_type len = stor1.view.size(); // dom[0].length() * dom[1].length();
!   assert(equal(sum, T(k*len*(len-1)/2+len)));
  }
  
  
--- 825,831 ----
    T sum = tc_sum(stor1.view);
  
    length_type len = stor1.view.size(); // dom[0].length() * dom[1].length();
!   test_assert(equal(sum, T(k*len*(len-1)/2+len)));
  }
  
  
*************** tc_assign_return(Domain<Dim> const& dom,
*** 907,917 ****
  {
    Storage1 stor1(dom, typename Storage1::value_type());
  
!   // assert(view1.get(0, 0) != val || val == T());
  
    stor1.view = return_view<Storage2>(dom, k);
  
!   assert(check_view(stor1.view, k));
  }
  
  
--- 907,917 ----
  {
    Storage1 stor1(dom, typename Storage1::value_type());
  
!   // test_assert(view1.get(0, 0) != val || val == T());
  
    stor1.view = return_view<Storage2>(dom, k);
  
!   test_assert(check_view(stor1.view, k));
  }
  
  
*************** tc_cons_return(Domain<Dim> const& dom, i
*** 926,932 ****
  {
    typename Storage1::view_type view1(return_view<Storage2>(dom, k));
  
!   assert(check_view(view1, k));
  }
  
  
--- 926,932 ----
  {
    typename Storage1::view_type view1(return_view<Storage2>(dom, k));
  
!   test_assert(check_view(view1, k));
  }
  
  
*************** tc_subview(
*** 994,1001 ****
  
    for (dimension_type d=0; d<dim; ++d)
    {
!     assert(sub[d].first()     >= dom[d].first());
!     assert(sub[d].impl_last() <= dom[d].impl_last());
    }
  
    Storage stor(dom);
--- 994,1001 ----
  
    for (dimension_type d=0; d<dim; ++d)
    {
!     test_assert(sub[d].first()     >= dom[d].first());
!     test_assert(sub[d].impl_last() <= dom[d].impl_last());
    }
  
    Storage stor(dom);
*************** tc_subview(
*** 1009,1023 ****
    {
      index_type parent_i = sub.impl_nth(i);
  
!     assert(stor.view.get(parent_i) ==  subv.get(i));
!     assert(stor.view.get(parent_i) == csubv.get(i));
  
      T val = stor.view.get(parent_i) + T(1);
      stor.block().put(parent_i, val);
  
!     assert(stor.view.get(parent_i) ==  val);
!     assert(stor.view.get(parent_i) ==  subv.get(i));
!     assert(stor.view.get(parent_i) == csubv.get(i));
    }
  }
  
--- 1009,1023 ----
    {
      index_type parent_i = sub.impl_nth(i);
  
!     test_assert(stor.view.get(parent_i) ==  subv.get(i));
!     test_assert(stor.view.get(parent_i) == csubv.get(i));
  
      T val = stor.view.get(parent_i) + T(1);
      stor.block().put(parent_i, val);
  
!     test_assert(stor.view.get(parent_i) ==  val);
!     test_assert(stor.view.get(parent_i) ==  subv.get(i));
!     test_assert(stor.view.get(parent_i) == csubv.get(i));
    }
  }
  
*************** tc_subview(
*** 1035,1042 ****
  
    for (dimension_type d=0; d<dim; ++d)
    {
!     assert(sub[d].first()     >= dom[d].first());
!     assert(sub[d].impl_last() <= dom[d].impl_last());
    }
  
    Storage stor(dom);
--- 1035,1042 ----
  
    for (dimension_type d=0; d<dim; ++d)
    {
!     test_assert(sub[d].first()     >= dom[d].first());
!     test_assert(sub[d].impl_last() <= dom[d].impl_last());
    }
  
    Storage stor(dom);
*************** tc_subview(
*** 1053,1067 ****
        index_type par_r = sub[0].impl_nth(r);
        index_type par_c = sub[1].impl_nth(c);
  
!       assert(stor.view.get(par_r, par_c) ==  subv.get(r, c));
!       assert(stor.view.get(par_r, par_c) == csubv.get(r, c));
  
        T val = stor.view.get(par_r, par_c) + T(1);
        stor.block().put(par_r, par_c, val);
        
!       assert(stor.view.get(par_r, par_c) ==  val);
!       assert(stor.view.get(par_r, par_c) ==  subv.get(r, c));
!       assert(stor.view.get(par_r, par_c) == csubv.get(r, c));
      }
    }
  }
--- 1053,1067 ----
        index_type par_r = sub[0].impl_nth(r);
        index_type par_c = sub[1].impl_nth(c);
  
!       test_assert(stor.view.get(par_r, par_c) ==  subv.get(r, c));
!       test_assert(stor.view.get(par_r, par_c) == csubv.get(r, c));
  
        T val = stor.view.get(par_r, par_c) + T(1);
        stor.block().put(par_r, par_c, val);
        
!       test_assert(stor.view.get(par_r, par_c) ==  val);
!       test_assert(stor.view.get(par_r, par_c) ==  subv.get(r, c));
!       test_assert(stor.view.get(par_r, par_c) == csubv.get(r, c));
      }
    }
  }
Index: tests/view_functions.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/view_functions.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 view_functions.cpp
*** tests/view_functions.cpp	2 Jun 2005 17:13:40 -0000	1.3
--- tests/view_functions.cpp	20 Dec 2005 12:39:21 -0000
*************** using namespace impl;
*** 30,36 ****
    {                                                \
      Vector<type, Dense<1, type> > v1(3, value);    \
      Vector<type, Dense<1, type> > v2 = func(v1);   \
!     assert(equal(v2.get(0), func(v1.get(0))));     \
    }
  
  // Unary func(View) call.
--- 30,36 ----
    {                                                \
      Vector<type, Dense<1, type> > v1(3, value);    \
      Vector<type, Dense<1, type> > v2 = func(v1);   \
!     test_assert(equal(v2.get(0), func(v1.get(0))));     \
    }
  
  // Unary func(View) call.
*************** using namespace impl;
*** 38,44 ****
    {                                                \
      Vector<type, Dense<1, type> > v1(3, value);    \
      Vector<type, Dense<1, retn> > v2 = func(v1);   \
!     assert(equal(v2.get(0), func(v1.get(0))));     \
    }
  
  // Binary func(View, View) call.
--- 38,44 ----
    {                                                \
      Vector<type, Dense<1, type> > v1(3, value);    \
      Vector<type, Dense<1, retn> > v2 = func(v1);   \
!     test_assert(equal(v2.get(0), func(v1.get(0))));     \
    }
  
  // Binary func(View, View) call.
*************** using namespace impl;
*** 47,53 ****
      Vector<type, Dense<1, type> > v1(2, value1);          \
      Vector<type, Dense<1, type> > v2(2, value2);          \
      Vector<type, Dense<1, type> > v3 = func(v1, v2);      \
!     assert(equal(v3.get(0), func(v1.get(0), v2.get(0)))); \
    }
  
  // Binary func(View, View) call.
--- 47,53 ----
      Vector<type, Dense<1, type> > v1(2, value1);          \
      Vector<type, Dense<1, type> > v2(2, value2);          \
      Vector<type, Dense<1, type> > v3 = func(v1, v2);      \
!     test_assert(equal(v3.get(0), func(v1.get(0), v2.get(0)))); \
    }
  
  // Binary func(View, View) call.
*************** using namespace impl;
*** 56,62 ****
      Vector<type, Dense<1, type> > v1(2, value1);          \
      Vector<type, Dense<1, type> > v2(2, value2);          \
      Vector<retn, Dense<1, retn> > v3 = func(v1, v2);      \
!     assert(equal(v3.get(0), func(v1.get(0), v2.get(0)))); \
    }
  
  // Binary func(View, Scalar) call.
--- 56,62 ----
      Vector<type, Dense<1, type> > v1(2, value1);          \
      Vector<type, Dense<1, type> > v2(2, value2);          \
      Vector<retn, Dense<1, retn> > v3 = func(v1, v2);      \
!     test_assert(equal(v3.get(0), func(v1.get(0), v2.get(0)))); \
    }
  
  // Binary func(View, Scalar) call.
*************** using namespace impl;
*** 64,70 ****
    {                                                       \
      Vector<type, Dense<1, type> > v1(2, value1);          \
      Vector<type, Dense<1, type> > v2 = func(v1, value2);  \
!     assert(equal(v2.get(0), func(v1.get(0), value2)));    \
    }
  
  // Binary func(View, Scalar) call.
--- 64,70 ----
    {                                                       \
      Vector<type, Dense<1, type> > v1(2, value1);          \
      Vector<type, Dense<1, type> > v2 = func(v1, value2);  \
!     test_assert(equal(v2.get(0), func(v1.get(0), value2)));    \
    }
  
  // Binary func(View, Scalar) call.
*************** using namespace impl;
*** 72,78 ****
    {                                                       \
      Vector<type, Dense<1, type> > v1(2, value1);          \
      Vector<retn, Dense<1, retn> > v2 = func(v1, value2);  \
!     assert(equal(v2.get(0), func(v1.get(0), value2)));    \
    }
  
  // Binary func(Scalar, View) call.
--- 72,78 ----
    {                                                       \
      Vector<type, Dense<1, type> > v1(2, value1);          \
      Vector<retn, Dense<1, retn> > v2 = func(v1, value2);  \
!     test_assert(equal(v2.get(0), func(v1.get(0), value2)));    \
    }
  
  // Binary func(Scalar, View) call.
*************** using namespace impl;
*** 80,86 ****
    {                                                       \
      Vector<type, Dense<1, type> > v1(2, value1);          \
      Vector<type, Dense<1, type> > v2 = func(value2, v1);  \
!     assert(equal(v2.get(0), func(value2, v1.get(0))));    \
    }
  
  // Binary func(Scalar, View) call.
--- 80,86 ----
    {                                                       \
      Vector<type, Dense<1, type> > v1(2, value1);          \
      Vector<type, Dense<1, type> > v2 = func(value2, v1);  \
!     test_assert(equal(v2.get(0), func(value2, v1.get(0))));    \
    }
  
  // Binary func(Scalar, View) call.
*************** using namespace impl;
*** 88,94 ****
    {                                                       \
      Vector<type, Dense<1, type> > v1(2, value1);          \
      Vector<retn, Dense<1, retn> > v2 = func(value2, v1);  \
!     assert(equal(v2.get(0), func(value2, v1.get(0))));    \
    }
  
  // Ternary func(View, View, View) call.
--- 88,94 ----
    {                                                       \
      Vector<type, Dense<1, type> > v1(2, value1);          \
      Vector<retn, Dense<1, retn> > v2 = func(value2, v1);  \
!     test_assert(equal(v2.get(0), func(value2, v1.get(0))));    \
    }
  
  // Ternary func(View, View, View) call.
*************** using namespace impl;
*** 98,105 ****
      Vector<type, Dense<1, type> > v2(2, value2);                     \
      Vector<type, Dense<1, type> > v3(2, value3);                     \
      Vector<type, Dense<1, type> > v4 = func(v1, v2, v3);             \
!     assert(equal(v4.get(0), func(v1.get(0), v2.get(0), v3.get(0)))); \
!     assert(equal(v4.get(1), func(v1.get(1), v2.get(1), v3.get(1)))); \
    }
  
  // Ternary func(Scalar, View, View) call.
--- 98,105 ----
      Vector<type, Dense<1, type> > v2(2, value2);                     \
      Vector<type, Dense<1, type> > v3(2, value3);                     \
      Vector<type, Dense<1, type> > v4 = func(v1, v2, v3);             \
!     test_assert(equal(v4.get(0), func(v1.get(0), v2.get(0), v3.get(0)))); \
!     test_assert(equal(v4.get(1), func(v1.get(1), v2.get(1), v3.get(1)))); \
    }
  
  // Ternary func(Scalar, View, View) call.
*************** using namespace impl;
*** 109,116 ****
      Vector<type, Dense<1, type> > v1(2, value2);                     \
      Vector<type, Dense<1, type> > v2(2, value3);                     \
      Vector<type, Dense<1, type> > v3 = func(scalar, v1, v2);         \
!     assert(equal(v3.get(0), func(scalar, v1.get(0), v2.get(0))));    \
!     assert(equal(v3.get(1), func(scalar, v1.get(1), v2.get(1))));    \
    }
  
  // Ternary func(View, Scalar, View) call.
--- 109,116 ----
      Vector<type, Dense<1, type> > v1(2, value2);                     \
      Vector<type, Dense<1, type> > v2(2, value3);                     \
      Vector<type, Dense<1, type> > v3 = func(scalar, v1, v2);         \
!     test_assert(equal(v3.get(0), func(scalar, v1.get(0), v2.get(0))));    \
!     test_assert(equal(v3.get(1), func(scalar, v1.get(1), v2.get(1))));    \
    }
  
  // Ternary func(View, Scalar, View) call.
*************** using namespace impl;
*** 120,127 ****
      Vector<type, Dense<1, type> > v1(2, value2);                     \
      Vector<type, Dense<1, type> > v2(2, value3);                     \
      Vector<type, Dense<1, type> > v3 = func(v1, scalar, v2);         \
!     assert(equal(v3.get(0), func(v1.get(0), scalar, v2.get(0))));    \
!     assert(equal(v3.get(1), func(v1.get(1), scalar, v2.get(1))));    \
    }
  
  // Ternary func(View, View, Scalar) call.
--- 120,127 ----
      Vector<type, Dense<1, type> > v1(2, value2);                     \
      Vector<type, Dense<1, type> > v2(2, value3);                     \
      Vector<type, Dense<1, type> > v3 = func(v1, scalar, v2);         \
!     test_assert(equal(v3.get(0), func(v1.get(0), scalar, v2.get(0))));    \
!     test_assert(equal(v3.get(1), func(v1.get(1), scalar, v2.get(1))));    \
    }
  
  // Ternary func(View, View, Scalar) call.
*************** using namespace impl;
*** 131,138 ****
      Vector<type, Dense<1, type> > v1(2, value2);                     \
      Vector<type, Dense<1, type> > v2(2, value3);                     \
      Vector<type, Dense<1, type> > v3 = func(v1, v2, scalar);         \
!     assert(equal(v3.get(0), func(v1.get(0), v2.get(0), scalar)));    \
!     assert(equal(v3.get(1), func(v1.get(1), v2.get(1), scalar)));    \
    }
  
  // Ternary func(View, Scalar, Scalar) call.
--- 131,138 ----
      Vector<type, Dense<1, type> > v1(2, value2);                     \
      Vector<type, Dense<1, type> > v2(2, value3);                     \
      Vector<type, Dense<1, type> > v3 = func(v1, v2, scalar);         \
!     test_assert(equal(v3.get(0), func(v1.get(0), v2.get(0), scalar)));    \
!     test_assert(equal(v3.get(1), func(v1.get(1), v2.get(1), scalar)));    \
    }
  
  // Ternary func(View, Scalar, Scalar) call.
*************** using namespace impl;
*** 142,149 ****
      type scalar2 = value2;                                           \
      Vector<type, Dense<1, type> > v(2, value3);                      \
      Vector<type, Dense<1, type> > v2 = func(v, scalar1, scalar2);    \
!     assert(equal(v2.get(0), func(v.get(0), scalar1, scalar2)));      \
!     assert(equal(v2.get(1), func(v.get(1), scalar1, scalar2)));      \
    }
  
  // Ternary func(Scalar, View, Scalar) call.
--- 142,149 ----
      type scalar2 = value2;                                           \
      Vector<type, Dense<1, type> > v(2, value3);                      \
      Vector<type, Dense<1, type> > v2 = func(v, scalar1, scalar2);    \
!     test_assert(equal(v2.get(0), func(v.get(0), scalar1, scalar2)));      \
!     test_assert(equal(v2.get(1), func(v.get(1), scalar1, scalar2)));      \
    }
  
  // Ternary func(Scalar, View, Scalar) call.
*************** using namespace impl;
*** 153,160 ****
      type scalar2 = value2;                                           \
      Vector<type, Dense<1, type> > v(2, value3);                      \
      Vector<type, Dense<1, type> > v2 = func(scalar1, v, scalar2);    \
!     assert(equal(v2.get(0), func(scalar1, v.get(0), scalar2)));      \
!     assert(equal(v2.get(1), func(scalar1, v.get(1), scalar2)));      \
    }
  
  // Ternary func(Scalar, Scalar, View) call.
--- 153,160 ----
      type scalar2 = value2;                                           \
      Vector<type, Dense<1, type> > v(2, value3);                      \
      Vector<type, Dense<1, type> > v2 = func(scalar1, v, scalar2);    \
!     test_assert(equal(v2.get(0), func(scalar1, v.get(0), scalar2)));      \
!     test_assert(equal(v2.get(1), func(scalar1, v.get(1), scalar2)));      \
    }
  
  // Ternary func(Scalar, Scalar, View) call.
*************** using namespace impl;
*** 164,171 ****
      type scalar2 = value2;                                           \
      Vector<type, Dense<1, type> > v(2, value3);                      \
      Vector<type, Dense<1, type> > v2 = func(scalar1, scalar2, v);    \
!     assert(equal(v2.get(0), func(scalar1, scalar2, v.get(0))));      \
!     assert(equal(v2.get(1), func(scalar1, scalar2, v.get(1))));      \
    }
  
  #define TEST_BINARY(name, type, value1, value2) \
--- 164,171 ----
      type scalar2 = value2;                                           \
      Vector<type, Dense<1, type> > v(2, value3);                      \
      Vector<type, Dense<1, type> > v2 = func(scalar1, scalar2, v);    \
!     test_assert(equal(v2.get(0), func(scalar1, scalar2, v.get(0))));      \
!     test_assert(equal(v2.get(1), func(scalar1, scalar2, v.get(1))));      \
    }
  
  #define TEST_BINARY(name, type, value1, value2) \
Index: tests/view_lvalue.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/view_lvalue.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 view_lvalue.cpp
*** tests/view_lvalue.cpp	14 Jun 2005 02:36:23 -0000	1.2
--- tests/view_lvalue.cpp	20 Dec 2005 12:39:21 -0000
***************
*** 9,19 ****
      the view contents.  These are roughly the same tests that appear in
      lvalue-proxy.cpp, but using the high-level view interfaces.  */
  
- #include <cassert>
  #include <vsip/initfin.hpp>
  #include <vsip/vector.hpp>
  #include <vsip/matrix.hpp>
  #include <vsip/tensor.hpp>
  #include "plainblock.hpp"
  
  template <typename View>
--- 9,20 ----
      the view contents.  These are roughly the same tests that appear in
      lvalue-proxy.cpp, but using the high-level view interfaces.  */
  
  #include <vsip/initfin.hpp>
  #include <vsip/vector.hpp>
  #include <vsip/matrix.hpp>
  #include <vsip/tensor.hpp>
+ 
+ #include "test.hpp"
  #include "plainblock.hpp"
  
  template <typename View>
*************** static void
*** 21,59 ****
  probe_vector (View v)
  {
    v(1) = 4;
!   assert (v.get(0) == 42);
!   assert (v.get(1) ==  4);
!   assert (v.get(2) == 42);
  
    v(1) += 3;
!   assert (v.get(0) == 42);
!   assert (v.get(1) ==  7);
!   assert (v.get(2) == 42);
  
    v(1) -= 5;
!   assert (v.get(0) == 42);
!   assert (v.get(1) ==  2);
!   assert (v.get(2) == 42);
  
    v(1) *= 3;
!   assert (v.get(0) == 42);
!   assert (v.get(1) ==  6);
!   assert (v.get(2) == 42);
  
    v(1) /= 2;
!   assert (v.get(0) == 42);
!   assert (v.get(1) ==  3);
!   assert (v.get(2) == 42);
  
    (v(1) = 12) = 10;
!   assert (v.get(0) == 42);
!   assert (v.get(1) == 10);
!   assert (v.get(2) == 42);
  
    v(1) = v(0);
!   assert (v.get(0) == 42);
!   assert (v.get(1) == 42);
!   assert (v.get(2) == 42);
  }
  
  template <typename View>
--- 22,60 ----
  probe_vector (View v)
  {
    v(1) = 4;
!   test_assert (v.get(0) == 42);
!   test_assert (v.get(1) ==  4);
!   test_assert (v.get(2) == 42);
  
    v(1) += 3;
!   test_assert (v.get(0) == 42);
!   test_assert (v.get(1) ==  7);
!   test_assert (v.get(2) == 42);
  
    v(1) -= 5;
!   test_assert (v.get(0) == 42);
!   test_assert (v.get(1) ==  2);
!   test_assert (v.get(2) == 42);
  
    v(1) *= 3;
!   test_assert (v.get(0) == 42);
!   test_assert (v.get(1) ==  6);
!   test_assert (v.get(2) == 42);
  
    v(1) /= 2;
!   test_assert (v.get(0) == 42);
!   test_assert (v.get(1) ==  3);
!   test_assert (v.get(2) == 42);
  
    (v(1) = 12) = 10;
!   test_assert (v.get(0) == 42);
!   test_assert (v.get(1) == 10);
!   test_assert (v.get(2) == 42);
  
    v(1) = v(0);
!   test_assert (v.get(0) == 42);
!   test_assert (v.get(1) == 42);
!   test_assert (v.get(2) == 42);
  }
  
  template <typename View>
*************** static void
*** 61,99 ****
  probe_matrix(View m)
  {
    m(0,1) = 4;
!   assert(m.get(0,0) == 42); assert(m.get(0,1) ==  4); assert(m.get(0,2) == 42);
!   assert(m.get(1,0) == 42); assert(m.get(1,1) == 42); assert(m.get(1,2) == 42);
!   assert(m.get(2,0) == 42); assert(m.get(2,1) == 42); assert(m.get(2,2) == 42);
  
    m(0,1) += 3;
!   assert(m.get(0,0) == 42); assert(m.get(0,1) ==  7); assert(m.get(0,2) == 42);
!   assert(m.get(1,0) == 42); assert(m.get(1,1) == 42); assert(m.get(1,2) == 42);
!   assert(m.get(2,0) == 42); assert(m.get(2,1) == 42); assert(m.get(2,2) == 42);
  
    m(0,1) -= 5;
!   assert(m.get(0,0) == 42); assert(m.get(0,1) ==  2); assert(m.get(0,2) == 42);
!   assert(m.get(1,0) == 42); assert(m.get(1,1) == 42); assert(m.get(1,2) == 42);
!   assert(m.get(2,0) == 42); assert(m.get(2,1) == 42); assert(m.get(2,2) == 42);
  
    m(0,1) *= 3;
!   assert(m.get(0,0) == 42); assert(m.get(0,1) ==  6); assert(m.get(0,2) == 42);
!   assert(m.get(1,0) == 42); assert(m.get(1,1) == 42); assert(m.get(1,2) == 42);
!   assert(m.get(2,0) == 42); assert(m.get(2,1) == 42); assert(m.get(2,2) == 42);
  
    m(0,1) /= 2;
!   assert(m.get(0,0) == 42); assert(m.get(0,1) ==  3); assert(m.get(0,2) == 42);
!   assert(m.get(1,0) == 42); assert(m.get(1,1) == 42); assert(m.get(1,2) == 42);
!   assert(m.get(2,0) == 42); assert(m.get(2,1) == 42); assert(m.get(2,2) == 42);
  
    (m(0,1) = 12) = 10;
!   assert(m.get(0,0) == 42); assert(m.get(0,1) == 10); assert(m.get(0,2) == 42);
!   assert(m.get(1,0) == 42); assert(m.get(1,1) == 42); assert(m.get(1,2) == 42);
!   assert(m.get(2,0) == 42); assert(m.get(2,1) == 42); assert(m.get(2,2) == 42);
  
    m(0,1) = m(0,0);
!   assert(m.get(0,0) == 42); assert(m.get(0,1) == 42); assert(m.get(0,2) == 42);
!   assert(m.get(1,0) == 42); assert(m.get(1,1) == 42); assert(m.get(1,2) == 42);
!   assert(m.get(2,0) == 42); assert(m.get(2,1) == 42); assert(m.get(2,2) == 42);
  }
  
  template <typename View>
--- 62,100 ----
  probe_matrix(View m)
  {
    m(0,1) = 4;
!   test_assert(m.get(0,0) == 42); test_assert(m.get(0,1) ==  4); test_assert(m.get(0,2) == 42);
!   test_assert(m.get(1,0) == 42); test_assert(m.get(1,1) == 42); test_assert(m.get(1,2) == 42);
!   test_assert(m.get(2,0) == 42); test_assert(m.get(2,1) == 42); test_assert(m.get(2,2) == 42);
  
    m(0,1) += 3;
!   test_assert(m.get(0,0) == 42); test_assert(m.get(0,1) ==  7); test_assert(m.get(0,2) == 42);
!   test_assert(m.get(1,0) == 42); test_assert(m.get(1,1) == 42); test_assert(m.get(1,2) == 42);
!   test_assert(m.get(2,0) == 42); test_assert(m.get(2,1) == 42); test_assert(m.get(2,2) == 42);
  
    m(0,1) -= 5;
!   test_assert(m.get(0,0) == 42); test_assert(m.get(0,1) ==  2); test_assert(m.get(0,2) == 42);
!   test_assert(m.get(1,0) == 42); test_assert(m.get(1,1) == 42); test_assert(m.get(1,2) == 42);
!   test_assert(m.get(2,0) == 42); test_assert(m.get(2,1) == 42); test_assert(m.get(2,2) == 42);
  
    m(0,1) *= 3;
!   test_assert(m.get(0,0) == 42); test_assert(m.get(0,1) ==  6); test_assert(m.get(0,2) == 42);
!   test_assert(m.get(1,0) == 42); test_assert(m.get(1,1) == 42); test_assert(m.get(1,2) == 42);
!   test_assert(m.get(2,0) == 42); test_assert(m.get(2,1) == 42); test_assert(m.get(2,2) == 42);
  
    m(0,1) /= 2;
!   test_assert(m.get(0,0) == 42); test_assert(m.get(0,1) ==  3); test_assert(m.get(0,2) == 42);
!   test_assert(m.get(1,0) == 42); test_assert(m.get(1,1) == 42); test_assert(m.get(1,2) == 42);
!   test_assert(m.get(2,0) == 42); test_assert(m.get(2,1) == 42); test_assert(m.get(2,2) == 42);
  
    (m(0,1) = 12) = 10;
!   test_assert(m.get(0,0) == 42); test_assert(m.get(0,1) == 10); test_assert(m.get(0,2) == 42);
!   test_assert(m.get(1,0) == 42); test_assert(m.get(1,1) == 42); test_assert(m.get(1,2) == 42);
!   test_assert(m.get(2,0) == 42); test_assert(m.get(2,1) == 42); test_assert(m.get(2,2) == 42);
  
    m(0,1) = m(0,0);
!   test_assert(m.get(0,0) == 42); test_assert(m.get(0,1) == 42); test_assert(m.get(0,2) == 42);
!   test_assert(m.get(1,0) == 42); test_assert(m.get(1,1) == 42); test_assert(m.get(1,2) == 42);
!   test_assert(m.get(2,0) == 42); test_assert(m.get(2,1) == 42); test_assert(m.get(2,2) == 42);
  }
  
  template <typename View>
*************** static void
*** 101,181 ****
  probe_tensor(View t)
  {
    t(0,1,2) = 4;
!   assert(t.get(0,0,0)==42); assert(t.get(0,0,1)==42); assert(t.get(0,0,2)==42);
!   assert(t.get(0,1,0)==42); assert(t.get(0,1,1)==42); assert(t.get(0,1,2)== 4);
!   assert(t.get(0,2,0)==42); assert(t.get(0,2,1)==42); assert(t.get(0,2,2)==42);
!   assert(t.get(1,0,0)==42); assert(t.get(1,0,1)==42); assert(t.get(1,0,2)==42);
!   assert(t.get(1,1,0)==42); assert(t.get(1,1,1)==42); assert(t.get(1,1,2)==42);
!   assert(t.get(1,2,0)==42); assert(t.get(1,2,1)==42); assert(t.get(1,2,2)==42);
!   assert(t.get(2,0,0)==42); assert(t.get(2,0,1)==42); assert(t.get(2,0,2)==42);
!   assert(t.get(2,1,0)==42); assert(t.get(2,1,1)==42); assert(t.get(2,1,2)==42);
!   assert(t.get(2,2,0)==42); assert(t.get(2,2,1)==42); assert(t.get(2,2,2)==42);
  
    t(0,1,2) += 3;
!   assert(t.get(0,0,0)==42); assert(t.get(0,0,1)==42); assert(t.get(0,0,2)==42);
!   assert(t.get(0,1,0)==42); assert(t.get(0,1,1)==42); assert(t.get(0,1,2)== 7);
!   assert(t.get(0,2,0)==42); assert(t.get(0,2,1)==42); assert(t.get(0,2,2)==42);
!   assert(t.get(1,0,0)==42); assert(t.get(1,0,1)==42); assert(t.get(1,0,2)==42);
!   assert(t.get(1,1,0)==42); assert(t.get(1,1,1)==42); assert(t.get(1,1,2)==42);
!   assert(t.get(1,2,0)==42); assert(t.get(1,2,1)==42); assert(t.get(1,2,2)==42);
!   assert(t.get(2,0,0)==42); assert(t.get(2,0,1)==42); assert(t.get(2,0,2)==42);
!   assert(t.get(2,1,0)==42); assert(t.get(2,1,1)==42); assert(t.get(2,1,2)==42);
!   assert(t.get(2,2,0)==42); assert(t.get(2,2,1)==42); assert(t.get(2,2,2)==42);
  
    t(0,1,2) -= 5;
!   assert(t.get(0,0,0)==42); assert(t.get(0,0,1)==42); assert(t.get(0,0,2)==42);
!   assert(t.get(0,1,0)==42); assert(t.get(0,1,1)==42); assert(t.get(0,1,2)== 2);
!   assert(t.get(0,2,0)==42); assert(t.get(0,2,1)==42); assert(t.get(0,2,2)==42);
!   assert(t.get(1,0,0)==42); assert(t.get(1,0,1)==42); assert(t.get(1,0,2)==42);
!   assert(t.get(1,1,0)==42); assert(t.get(1,1,1)==42); assert(t.get(1,1,2)==42);
!   assert(t.get(1,2,0)==42); assert(t.get(1,2,1)==42); assert(t.get(1,2,2)==42);
!   assert(t.get(2,0,0)==42); assert(t.get(2,0,1)==42); assert(t.get(2,0,2)==42);
!   assert(t.get(2,1,0)==42); assert(t.get(2,1,1)==42); assert(t.get(2,1,2)==42);
!   assert(t.get(2,2,0)==42); assert(t.get(2,2,1)==42); assert(t.get(2,2,2)==42);
  
    t(0,1,2) *= 3;
!   assert(t.get(0,0,0)==42); assert(t.get(0,0,1)==42); assert(t.get(0,0,2)==42);
!   assert(t.get(0,1,0)==42); assert(t.get(0,1,1)==42); assert(t.get(0,1,2)== 6);
!   assert(t.get(0,2,0)==42); assert(t.get(0,2,1)==42); assert(t.get(0,2,2)==42);
!   assert(t.get(1,0,0)==42); assert(t.get(1,0,1)==42); assert(t.get(1,0,2)==42);
!   assert(t.get(1,1,0)==42); assert(t.get(1,1,1)==42); assert(t.get(1,1,2)==42);
!   assert(t.get(1,2,0)==42); assert(t.get(1,2,1)==42); assert(t.get(1,2,2)==42);
!   assert(t.get(2,0,0)==42); assert(t.get(2,0,1)==42); assert(t.get(2,0,2)==42);
!   assert(t.get(2,1,0)==42); assert(t.get(2,1,1)==42); assert(t.get(2,1,2)==42);
!   assert(t.get(2,2,0)==42); assert(t.get(2,2,1)==42); assert(t.get(2,2,2)==42);
  
    t(0,1,2) /= 2;
!   assert(t.get(0,0,0)==42); assert(t.get(0,0,1)==42); assert(t.get(0,0,2)==42);
!   assert(t.get(0,1,0)==42); assert(t.get(0,1,1)==42); assert(t.get(0,1,2)== 3);
!   assert(t.get(0,2,0)==42); assert(t.get(0,2,1)==42); assert(t.get(0,2,2)==42);
!   assert(t.get(1,0,0)==42); assert(t.get(1,0,1)==42); assert(t.get(1,0,2)==42);
!   assert(t.get(1,1,0)==42); assert(t.get(1,1,1)==42); assert(t.get(1,1,2)==42);
!   assert(t.get(1,2,0)==42); assert(t.get(1,2,1)==42); assert(t.get(1,2,2)==42);
!   assert(t.get(2,0,0)==42); assert(t.get(2,0,1)==42); assert(t.get(2,0,2)==42);
!   assert(t.get(2,1,0)==42); assert(t.get(2,1,1)==42); assert(t.get(2,1,2)==42);
!   assert(t.get(2,2,0)==42); assert(t.get(2,2,1)==42); assert(t.get(2,2,2)==42);
  
    (t(0,1,2) = 12) = 10;
!   assert(t.get(0,0,0)==42); assert(t.get(0,0,1)==42); assert(t.get(0,0,2)==42);
!   assert(t.get(0,1,0)==42); assert(t.get(0,1,1)==42); assert(t.get(0,1,2)==10);
!   assert(t.get(0,2,0)==42); assert(t.get(0,2,1)==42); assert(t.get(0,2,2)==42);
!   assert(t.get(1,0,0)==42); assert(t.get(1,0,1)==42); assert(t.get(1,0,2)==42);
!   assert(t.get(1,1,0)==42); assert(t.get(1,1,1)==42); assert(t.get(1,1,2)==42);
!   assert(t.get(1,2,0)==42); assert(t.get(1,2,1)==42); assert(t.get(1,2,2)==42);
!   assert(t.get(2,0,0)==42); assert(t.get(2,0,1)==42); assert(t.get(2,0,2)==42);
!   assert(t.get(2,1,0)==42); assert(t.get(2,1,1)==42); assert(t.get(2,1,2)==42);
!   assert(t.get(2,2,0)==42); assert(t.get(2,2,1)==42); assert(t.get(2,2,2)==42);
  
    t(0,1,2) = t(0,0,0);
!   assert(t.get(0,0,0)==42); assert(t.get(0,0,1)==42); assert(t.get(0,0,2)==42);
!   assert(t.get(0,1,0)==42); assert(t.get(0,1,1)==42); assert(t.get(0,1,2)==42);
!   assert(t.get(0,2,0)==42); assert(t.get(0,2,1)==42); assert(t.get(0,2,2)==42);
!   assert(t.get(1,0,0)==42); assert(t.get(1,0,1)==42); assert(t.get(1,0,2)==42);
!   assert(t.get(1,1,0)==42); assert(t.get(1,1,1)==42); assert(t.get(1,1,2)==42);
!   assert(t.get(1,2,0)==42); assert(t.get(1,2,1)==42); assert(t.get(1,2,2)==42);
!   assert(t.get(2,0,0)==42); assert(t.get(2,0,1)==42); assert(t.get(2,0,2)==42);
!   assert(t.get(2,1,0)==42); assert(t.get(2,1,1)==42); assert(t.get(2,1,2)==42);
!   assert(t.get(2,2,0)==42); assert(t.get(2,2,1)==42); assert(t.get(2,2,2)==42);
  }
  
  
--- 102,182 ----
  probe_tensor(View t)
  {
    t(0,1,2) = 4;
!   test_assert(t.get(0,0,0)==42); test_assert(t.get(0,0,1)==42); test_assert(t.get(0,0,2)==42);
!   test_assert(t.get(0,1,0)==42); test_assert(t.get(0,1,1)==42); test_assert(t.get(0,1,2)== 4);
!   test_assert(t.get(0,2,0)==42); test_assert(t.get(0,2,1)==42); test_assert(t.get(0,2,2)==42);
!   test_assert(t.get(1,0,0)==42); test_assert(t.get(1,0,1)==42); test_assert(t.get(1,0,2)==42);
!   test_assert(t.get(1,1,0)==42); test_assert(t.get(1,1,1)==42); test_assert(t.get(1,1,2)==42);
!   test_assert(t.get(1,2,0)==42); test_assert(t.get(1,2,1)==42); test_assert(t.get(1,2,2)==42);
!   test_assert(t.get(2,0,0)==42); test_assert(t.get(2,0,1)==42); test_assert(t.get(2,0,2)==42);
!   test_assert(t.get(2,1,0)==42); test_assert(t.get(2,1,1)==42); test_assert(t.get(2,1,2)==42);
!   test_assert(t.get(2,2,0)==42); test_assert(t.get(2,2,1)==42); test_assert(t.get(2,2,2)==42);
  
    t(0,1,2) += 3;
!   test_assert(t.get(0,0,0)==42); test_assert(t.get(0,0,1)==42); test_assert(t.get(0,0,2)==42);
!   test_assert(t.get(0,1,0)==42); test_assert(t.get(0,1,1)==42); test_assert(t.get(0,1,2)== 7);
!   test_assert(t.get(0,2,0)==42); test_assert(t.get(0,2,1)==42); test_assert(t.get(0,2,2)==42);
!   test_assert(t.get(1,0,0)==42); test_assert(t.get(1,0,1)==42); test_assert(t.get(1,0,2)==42);
!   test_assert(t.get(1,1,0)==42); test_assert(t.get(1,1,1)==42); test_assert(t.get(1,1,2)==42);
!   test_assert(t.get(1,2,0)==42); test_assert(t.get(1,2,1)==42); test_assert(t.get(1,2,2)==42);
!   test_assert(t.get(2,0,0)==42); test_assert(t.get(2,0,1)==42); test_assert(t.get(2,0,2)==42);
!   test_assert(t.get(2,1,0)==42); test_assert(t.get(2,1,1)==42); test_assert(t.get(2,1,2)==42);
!   test_assert(t.get(2,2,0)==42); test_assert(t.get(2,2,1)==42); test_assert(t.get(2,2,2)==42);
  
    t(0,1,2) -= 5;
!   test_assert(t.get(0,0,0)==42); test_assert(t.get(0,0,1)==42); test_assert(t.get(0,0,2)==42);
!   test_assert(t.get(0,1,0)==42); test_assert(t.get(0,1,1)==42); test_assert(t.get(0,1,2)== 2);
!   test_assert(t.get(0,2,0)==42); test_assert(t.get(0,2,1)==42); test_assert(t.get(0,2,2)==42);
!   test_assert(t.get(1,0,0)==42); test_assert(t.get(1,0,1)==42); test_assert(t.get(1,0,2)==42);
!   test_assert(t.get(1,1,0)==42); test_assert(t.get(1,1,1)==42); test_assert(t.get(1,1,2)==42);
!   test_assert(t.get(1,2,0)==42); test_assert(t.get(1,2,1)==42); test_assert(t.get(1,2,2)==42);
!   test_assert(t.get(2,0,0)==42); test_assert(t.get(2,0,1)==42); test_assert(t.get(2,0,2)==42);
!   test_assert(t.get(2,1,0)==42); test_assert(t.get(2,1,1)==42); test_assert(t.get(2,1,2)==42);
!   test_assert(t.get(2,2,0)==42); test_assert(t.get(2,2,1)==42); test_assert(t.get(2,2,2)==42);
  
    t(0,1,2) *= 3;
!   test_assert(t.get(0,0,0)==42); test_assert(t.get(0,0,1)==42); test_assert(t.get(0,0,2)==42);
!   test_assert(t.get(0,1,0)==42); test_assert(t.get(0,1,1)==42); test_assert(t.get(0,1,2)== 6);
!   test_assert(t.get(0,2,0)==42); test_assert(t.get(0,2,1)==42); test_assert(t.get(0,2,2)==42);
!   test_assert(t.get(1,0,0)==42); test_assert(t.get(1,0,1)==42); test_assert(t.get(1,0,2)==42);
!   test_assert(t.get(1,1,0)==42); test_assert(t.get(1,1,1)==42); test_assert(t.get(1,1,2)==42);
!   test_assert(t.get(1,2,0)==42); test_assert(t.get(1,2,1)==42); test_assert(t.get(1,2,2)==42);
!   test_assert(t.get(2,0,0)==42); test_assert(t.get(2,0,1)==42); test_assert(t.get(2,0,2)==42);
!   test_assert(t.get(2,1,0)==42); test_assert(t.get(2,1,1)==42); test_assert(t.get(2,1,2)==42);
!   test_assert(t.get(2,2,0)==42); test_assert(t.get(2,2,1)==42); test_assert(t.get(2,2,2)==42);
  
    t(0,1,2) /= 2;
!   test_assert(t.get(0,0,0)==42); test_assert(t.get(0,0,1)==42); test_assert(t.get(0,0,2)==42);
!   test_assert(t.get(0,1,0)==42); test_assert(t.get(0,1,1)==42); test_assert(t.get(0,1,2)== 3);
!   test_assert(t.get(0,2,0)==42); test_assert(t.get(0,2,1)==42); test_assert(t.get(0,2,2)==42);
!   test_assert(t.get(1,0,0)==42); test_assert(t.get(1,0,1)==42); test_assert(t.get(1,0,2)==42);
!   test_assert(t.get(1,1,0)==42); test_assert(t.get(1,1,1)==42); test_assert(t.get(1,1,2)==42);
!   test_assert(t.get(1,2,0)==42); test_assert(t.get(1,2,1)==42); test_assert(t.get(1,2,2)==42);
!   test_assert(t.get(2,0,0)==42); test_assert(t.get(2,0,1)==42); test_assert(t.get(2,0,2)==42);
!   test_assert(t.get(2,1,0)==42); test_assert(t.get(2,1,1)==42); test_assert(t.get(2,1,2)==42);
!   test_assert(t.get(2,2,0)==42); test_assert(t.get(2,2,1)==42); test_assert(t.get(2,2,2)==42);
  
    (t(0,1,2) = 12) = 10;
!   test_assert(t.get(0,0,0)==42); test_assert(t.get(0,0,1)==42); test_assert(t.get(0,0,2)==42);
!   test_assert(t.get(0,1,0)==42); test_assert(t.get(0,1,1)==42); test_assert(t.get(0,1,2)==10);
!   test_assert(t.get(0,2,0)==42); test_assert(t.get(0,2,1)==42); test_assert(t.get(0,2,2)==42);
!   test_assert(t.get(1,0,0)==42); test_assert(t.get(1,0,1)==42); test_assert(t.get(1,0,2)==42);
!   test_assert(t.get(1,1,0)==42); test_assert(t.get(1,1,1)==42); test_assert(t.get(1,1,2)==42);
!   test_assert(t.get(1,2,0)==42); test_assert(t.get(1,2,1)==42); test_assert(t.get(1,2,2)==42);
!   test_assert(t.get(2,0,0)==42); test_assert(t.get(2,0,1)==42); test_assert(t.get(2,0,2)==42);
!   test_assert(t.get(2,1,0)==42); test_assert(t.get(2,1,1)==42); test_assert(t.get(2,1,2)==42);
!   test_assert(t.get(2,2,0)==42); test_assert(t.get(2,2,1)==42); test_assert(t.get(2,2,2)==42);
  
    t(0,1,2) = t(0,0,0);
!   test_assert(t.get(0,0,0)==42); test_assert(t.get(0,0,1)==42); test_assert(t.get(0,0,2)==42);
!   test_assert(t.get(0,1,0)==42); test_assert(t.get(0,1,1)==42); test_assert(t.get(0,1,2)==42);
!   test_assert(t.get(0,2,0)==42); test_assert(t.get(0,2,1)==42); test_assert(t.get(0,2,2)==42);
!   test_assert(t.get(1,0,0)==42); test_assert(t.get(1,0,1)==42); test_assert(t.get(1,0,2)==42);
!   test_assert(t.get(1,1,0)==42); test_assert(t.get(1,1,1)==42); test_assert(t.get(1,1,2)==42);
!   test_assert(t.get(1,2,0)==42); test_assert(t.get(1,2,1)==42); test_assert(t.get(1,2,2)==42);
!   test_assert(t.get(2,0,0)==42); test_assert(t.get(2,0,1)==42); test_assert(t.get(2,0,2)==42);
!   test_assert(t.get(2,1,0)==42); test_assert(t.get(2,1,1)==42); test_assert(t.get(2,1,2)==42);
!   test_assert(t.get(2,2,0)==42); test_assert(t.get(2,2,1)==42); test_assert(t.get(2,2,2)==42);
  }
  
  
Index: tests/view_operators.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/view_operators.cpp,v
retrieving revision 1.7
diff -c -p -r1.7 view_operators.cpp
*** tests/view_operators.cpp	26 Sep 2005 14:09:24 -0000	1.7
--- tests/view_operators.cpp	20 Dec 2005 12:39:21 -0000
*************** add_numeric_test(BT1 p, BT2 q)
*** 49,55 ****
    Block1 b1(domain, p);
    Block2 b2(domain, q);
    Result result = View1(b1) + View2(b2);
!   assert(equal(result.get(0), static_cast<VT1>(p) + static_cast<VT2>(q)));
  }
  
  template <typename View>
--- 49,55 ----
    Block1 b1(domain, p);
    Block2 b2(domain, q);
    Result result = View1(b1) + View2(b2);
!   test_assert(equal(result.get(0), static_cast<VT1>(p) + static_cast<VT2>(q)));
  }
  
  template <typename View>
*************** add_test()
*** 66,74 ****
    Vector<float, Dense<1, float> > v2(3, 10.);
  
    Vector<float, Dense<1, float> > v3 = 5.f + v1 + v2 + v2 + 5.f;
!   assert(equal(v3.get(0), 5.f + v1.get(0) + v2.get(0) + v2.get(0) + 5.f));
!   assert(equal(v3.get(1), 5.f + v1.get(1) + v2.get(1) + v2.get(1) + 5.f));
!   assert(equal(v3.get(2), 5.f + v1.get(2) + v2.get(2) + v2.get(2) + 5.f));
  }
  
  void
--- 66,74 ----
    Vector<float, Dense<1, float> > v2(3, 10.);
  
    Vector<float, Dense<1, float> > v3 = 5.f + v1 + v2 + v2 + 5.f;
!   test_assert(equal(v3.get(0), 5.f + v1.get(0) + v2.get(0) + v2.get(0) + 5.f));
!   test_assert(equal(v3.get(1), 5.f + v1.get(1) + v2.get(1) + v2.get(1) + 5.f));
!   test_assert(equal(v3.get(2), 5.f + v1.get(2) + v2.get(2) + v2.get(2) + 5.f));
  }
  
  void
*************** sub_test()
*** 78,86 ****
    Vector<float, Dense<1, float> > v2(3, 10.);
  
    Vector<float, Dense<1, float> > v3 = 5.f - v1 - v2 - v2 - 5.f;
!   assert(equal(v3.get(0), 5.f - v1.get(0) - v2.get(0) - v2.get(0) - 5.f));
!   assert(equal(v3.get(1), 5.f - v1.get(1) - v2.get(1) - v2.get(1) - 5.f));
!   assert(equal(v3.get(2), 5.f - v1.get(2) - v2.get(2) - v2.get(2) - 5.f));
  }
  
  void
--- 78,86 ----
    Vector<float, Dense<1, float> > v2(3, 10.);
  
    Vector<float, Dense<1, float> > v3 = 5.f - v1 - v2 - v2 - 5.f;
!   test_assert(equal(v3.get(0), 5.f - v1.get(0) - v2.get(0) - v2.get(0) - 5.f));
!   test_assert(equal(v3.get(1), 5.f - v1.get(1) - v2.get(1) - v2.get(1) - 5.f));
!   test_assert(equal(v3.get(2), 5.f - v1.get(2) - v2.get(2) - v2.get(2) - 5.f));
  }
  
  void
*************** mult_test()
*** 90,98 ****
    Vector<float, Dense<1, float> > v2(3, 10.);
  
    Vector<float, Dense<1, float> > v3 = 5.f * v1 * v2 * v2 * 5.f;
!   assert(equal(v3.get(0), 5.f * v1.get(0) * v2.get(0) * v2.get(0) * 5.f));
!   assert(equal(v3.get(1), 5.f * v1.get(1) * v2.get(1) * v2.get(1) * 5.f));
!   assert(equal(v3.get(2), 5.f * v1.get(2) * v2.get(2) * v2.get(2) * 5.f));
  }
  
  void
--- 90,98 ----
    Vector<float, Dense<1, float> > v2(3, 10.);
  
    Vector<float, Dense<1, float> > v3 = 5.f * v1 * v2 * v2 * 5.f;
!   test_assert(equal(v3.get(0), 5.f * v1.get(0) * v2.get(0) * v2.get(0) * 5.f));
!   test_assert(equal(v3.get(1), 5.f * v1.get(1) * v2.get(1) * v2.get(1) * 5.f));
!   test_assert(equal(v3.get(2), 5.f * v1.get(2) * v2.get(2) * v2.get(2) * 5.f));
  }
  
  void
*************** div_test()
*** 102,131 ****
    Vector<float, Dense<1, float> > v2(3, 10.);
  
    Vector<float, Dense<1, float> > v3 = 5.f / v1 / v2 / v2 / 5.f;
!   assert(equal(v3.get(0), 5.f / v1.get(0) / v2.get(0) / v2.get(0) / 5.f));
!   assert(equal(v3.get(1), 5.f / v1.get(1) / v2.get(1) / v2.get(1) / 5.f));
!   assert(equal(v3.get(2), 5.f / v1.get(2) / v2.get(2) / v2.get(2) / 5.f));
  }
  
  #define COMPARE_VV_TEST(v1, v2, op)                       \
  {                                                         \
    Vector<bool, Dense<1, bool> > result = v1 op v2;        \
    for (length_type i = 0; i != result.length(); ++i)      \
!     assert(equal(result.get(i), v1.get(i) op v2.get(i))); \
  }
  
  #define COMPARE_VS_TEST(v, s, op)                         \
  {                                                         \
    Vector<bool, Dense<1, bool> > result = v op s;          \
    for (length_type i = 0; i != result.length(); ++i)      \
!     assert(equal(result.get(i), v.get(i) op s));          \
  }
  
  #define COMPARE_SV_TEST(s, v, op)                         \
  {                                                         \
    Vector<bool, Dense<1, bool> > result = s op v;          \
    for (length_type i = 0; i != result.length(); ++i)      \
!     assert(equal(result.get(i), s op v.get(i)));          \
  }
  
  void comparison_test()
--- 102,131 ----
    Vector<float, Dense<1, float> > v2(3, 10.);
  
    Vector<float, Dense<1, float> > v3 = 5.f / v1 / v2 / v2 / 5.f;
!   test_assert(equal(v3.get(0), 5.f / v1.get(0) / v2.get(0) / v2.get(0) / 5.f));
!   test_assert(equal(v3.get(1), 5.f / v1.get(1) / v2.get(1) / v2.get(1) / 5.f));
!   test_assert(equal(v3.get(2), 5.f / v1.get(2) / v2.get(2) / v2.get(2) / 5.f));
  }
  
  #define COMPARE_VV_TEST(v1, v2, op)                       \
  {                                                         \
    Vector<bool, Dense<1, bool> > result = v1 op v2;        \
    for (length_type i = 0; i != result.length(); ++i)      \
!     test_assert(equal(result.get(i), v1.get(i) op v2.get(i))); \
  }
  
  #define COMPARE_VS_TEST(v, s, op)                         \
  {                                                         \
    Vector<bool, Dense<1, bool> > result = v op s;          \
    for (length_type i = 0; i != result.length(); ++i)      \
!     test_assert(equal(result.get(i), v.get(i) op s));          \
  }
  
  #define COMPARE_SV_TEST(s, v, op)                         \
  {                                                         \
    Vector<bool, Dense<1, bool> > result = s op v;          \
    for (length_type i = 0; i != result.length(); ++i)      \
!     test_assert(equal(result.get(i), s op v.get(i)));          \
  }
  
  void comparison_test()
*************** void comparison_test()
*** 200,220 ****
  {                                                         \
    Vector<int, Dense<1, int> > result = v1 op v2;          \
    for (length_type i = 0; i != result.length(); ++i)      \
!     assert(equal(result.get(i), v1.get(i) op v2.get(i))); \
  }
  
  #define BINARY_OP_VS_TEST(v, s, op)                       \
  {                                                         \
    Vector<int, Dense<1, int> > result = v op s;            \
    for (length_type i = 0; i != result.length(); ++i)      \
!     assert(equal(result.get(i), v.get(i) op s));          \
  }
  
  #define BINARY_OP_SV_TEST(s, v, op)                       \
  {                                                         \
    Vector<int, Dense<1, int> > result = s op v;            \
    for (length_type i = 0; i != result.length(); ++i)      \
!     assert(equal(result.get(i), s op v.get(i)));          \
  }
  
  void
--- 200,220 ----
  {                                                         \
    Vector<int, Dense<1, int> > result = v1 op v2;          \
    for (length_type i = 0; i != result.length(); ++i)      \
!     test_assert(equal(result.get(i), v1.get(i) op v2.get(i))); \
  }
  
  #define BINARY_OP_VS_TEST(v, s, op)                       \
  {                                                         \
    Vector<int, Dense<1, int> > result = v op s;            \
    for (length_type i = 0; i != result.length(); ++i)      \
!     test_assert(equal(result.get(i), v.get(i) op s));          \
  }
  
  #define BINARY_OP_SV_TEST(s, v, op)                       \
  {                                                         \
    Vector<int, Dense<1, int> > result = s op v;            \
    for (length_type i = 0; i != result.length(); ++i)      \
!     test_assert(equal(result.get(i), s op v.get(i)));          \
  }
  
  void
*************** binary_lxor_test()
*** 249,267 ****
    {
      Vector<bool, Dense<1, bool> > result = v1 ^ v2;
      for (length_type i = 0; i != result.length(); ++i)
!       assert(equal(result.get(i), bool(v1.get(i) ^ v2.get(i))));
    }
    {
      bool const s = false;
      Vector<bool, Dense<1, bool> > result = v1 ^ s;
      for (length_type i = 0; i != result.length(); ++i)
!       assert(equal(result.get(i), bool(v1.get(i) ^ s)));
    }
    {
      bool const s = true;
      Vector<bool, Dense<1, bool> > result = s ^ v1;
      for (length_type i = 0; i != result.length(); ++i)
!       assert(equal(result.get(i), bool(s ^ v1.get(i))));
    }
  }
  
--- 249,267 ----
    {
      Vector<bool, Dense<1, bool> > result = v1 ^ v2;
      for (length_type i = 0; i != result.length(); ++i)
!       test_assert(equal(result.get(i), bool(v1.get(i) ^ v2.get(i))));
    }
    {
      bool const s = false;
      Vector<bool, Dense<1, bool> > result = v1 ^ s;
      for (length_type i = 0; i != result.length(); ++i)
!       test_assert(equal(result.get(i), bool(v1.get(i) ^ s)));
    }
    {
      bool const s = true;
      Vector<bool, Dense<1, bool> > result = s ^ v1;
      for (length_type i = 0; i != result.length(); ++i)
!       test_assert(equal(result.get(i), bool(s ^ v1.get(i))));
    }
  }
  
*************** subblock_test()
*** 277,288 ****
    Real_block real(block);
    Vector<float, Real_block> realview(real);
    Vector<float, Dense<1, float> > v2 = v1 + realview;
!   assert(equal(v2.get(0), v1.get(0) + realview.get(0)));
  
    Imag_block imag(block);
    Vector<float, Imag_block> imagview(imag);
    Vector<float, Dense<1, float> > v3 = v1 + imagview;
!   assert(equal(v3.get(0), v1.get(0) + imagview.get(0)));
  }
  
  int
--- 277,288 ----
    Real_block real(block);
    Vector<float, Real_block> realview(real);
    Vector<float, Dense<1, float> > v2 = v1 + realview;
!   test_assert(equal(v2.get(0), v1.get(0) + realview.get(0)));
  
    Imag_block imag(block);
    Vector<float, Imag_block> imagview(imag);
    Vector<float, Dense<1, float> > v3 = v1 + imagview;
!   test_assert(equal(v3.get(0), v1.get(0) + imagview.get(0)));
  }
  
  int
Index: tests/vmmul.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/vmmul.cpp,v
retrieving revision 1.3
diff -c -p -r1.3 vmmul.cpp
*** tests/vmmul.cpp	5 Dec 2005 19:19:19 -0000	1.3
--- tests/vmmul.cpp	20 Dec 2005 12:39:21 -0000
***************
*** 12,18 ****
  
  
  #include <iostream>
! #include <cassert>
  #include <vsip/support.hpp>
  #include <vsip/initfin.hpp>
  #include <vsip/vector.hpp>
--- 12,18 ----
  
  
  #include <iostream>
! 
  #include <vsip/support.hpp>
  #include <vsip/initfin.hpp>
  #include <vsip/vector.hpp>
*************** test_vmmul(
*** 56,64 ****
    for (index_type r=0; r<rows; ++r)
      for (index_type c=0; c<cols; ++c)
        if (Dim == 0)
! 	assert(equal(res(r, c), T(c * (r*cols+c))));
        else
! 	assert(equal(res(r, c), T(r * (r*cols+c))));
  }
  
  
--- 56,64 ----
    for (index_type r=0; r<rows; ++r)
      for (index_type c=0; c<cols; ++c)
        if (Dim == 0)
! 	test_assert(equal(res(r, c), T(c * (r*cols+c))));
        else
! 	test_assert(equal(res(r, c), T(r * (r*cols+c))));
  }
  
  
Index: tests/window.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/window.cpp,v
retrieving revision 1.2
diff -c -p -r1.2 window.cpp
*** tests/window.cpp	23 Sep 2005 16:11:43 -0000	1.2
--- tests/window.cpp	20 Dec 2005 12:39:21 -0000
*************** main ()
*** 99,105 ****
      const_Vector<scalar_f> v = blackman(N);
  
      for ( unsigned int n = 0; n < N; ++n )
!       assert( equal( v.get(n), testvec_blackman[n] ) );
    }
  
  #if defined(VSIP_IMPL_FFT_USE_FLOAT)
--- 99,105 ----
      const_Vector<scalar_f> v = blackman(N);
  
      for ( unsigned int n = 0; n < N; ++n )
!       test_assert( equal( v.get(n), testvec_blackman[n] ) );
    }
  
  #if defined(VSIP_IMPL_FFT_USE_FLOAT)
*************** main ()
*** 110,116 ****
      const_Vector<scalar_f> v = cheby(N, ripple);
  
      for ( unsigned int n = 0; n < N; ++n )
!       assert( equal( v.get(n), testvec_cheby[n] ) );
    }
  
  
--- 110,116 ----
      const_Vector<scalar_f> v = cheby(N, ripple);
  
      for ( unsigned int n = 0; n < N; ++n )
!       test_assert( equal( v.get(n), testvec_cheby[n] ) );
    }
  
  
*************** main ()
*** 121,127 ****
      const_Vector<scalar_f> v = cheby(N, ripple);
  
      for ( unsigned int n = 0; n < N; ++n )
!       assert( equal( v.get(n), testvec_cheby_odd[n] ) );
    }
  #endif
  
--- 121,127 ----
      const_Vector<scalar_f> v = cheby(N, ripple);
  
      for ( unsigned int n = 0; n < N; ++n )
!       test_assert( equal( v.get(n), testvec_cheby_odd[n] ) );
    }
  #endif
  
*************** main ()
*** 131,137 ****
      const_Vector<scalar_f> v = hanning(N);
  
      for ( unsigned int n = 0; n < N; ++n )
!       assert( equal( v.get(n), testvec_hanning[n] ) );
    }
  
    // Kaiser
--- 131,137 ----
      const_Vector<scalar_f> v = hanning(N);
  
      for ( unsigned int n = 0; n < N; ++n )
!       test_assert( equal( v.get(n), testvec_hanning[n] ) );
    }
  
    // Kaiser
*************** main ()
*** 141,147 ****
      const_Vector<scalar_f> v = kaiser(N, beta);
  
      for ( unsigned int n = 0; n < N; ++n )
!       assert( equal( v.get(n), testvec_kaiser[n] ) );
    }
  
    return EXIT_SUCCESS;
--- 141,147 ----
      const_Vector<scalar_f> v = kaiser(N, beta);
  
      for ( unsigned int n = 0; n < N; ++n )
!       test_assert( equal( v.get(n), testvec_kaiser[n] ) );
    }
  
    return EXIT_SUCCESS;
