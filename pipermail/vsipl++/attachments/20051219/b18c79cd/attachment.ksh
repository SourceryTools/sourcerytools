Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.339
diff -c -p -r1.339 ChangeLog
*** ChangeLog	19 Dec 2005 16:08:55 -0000	1.339
--- ChangeLog	19 Dec 2005 18:39:48 -0000
***************
*** 1,5 ****
--- 1,15 ----
  2005-12-19 Jules Bergmann  <jules@codesourcery.com>
  
+ 	* src/vsip/signal.hpp: Include signal-iir.
+ 	* src/vsip/impl/signal-iir.hpp: New file, direct implementation of
+ 	  IIR filter.
+ 	* tests/iir.cpp: New file, unit tests for IIR filter.
+ 
+ 	* src/vsip/impl/signal-fir.hpp: Move obj_state enum to ...
+ 	* src/vsip/impl/signal-types.hpp: ... here.
+ 
+ 2005-12-19 Jules Bergmann  <jules@codesourcery.com>
+ 
  	* benchmarks/fastconv.cpp: Add new case using out-of-place FFT to
  	  perform in-place FFTM.  Parallel this case and single-loop case.
  	* benchmarks/fftm.cpp: New file, benchmarks for Fftm.
Index: src/vsip/signal.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/signal.hpp,v
retrieving revision 1.13
diff -c -p -r1.13 signal.hpp
*** src/vsip/signal.hpp	6 Dec 2005 00:58:40 -0000	1.13
--- src/vsip/signal.hpp	19 Dec 2005 18:39:48 -0000
***************
*** 20,25 ****
--- 20,26 ----
  #include <vsip/impl/signal-corr.hpp>
  #include <vsip/impl/signal-window.hpp>
  #include <vsip/impl/signal-fir.hpp>
+ #include <vsip/impl/signal-iir.hpp>
  #include <vsip/impl/signal-freqswap.hpp>
  #include <vsip/impl/signal-histo.hpp>
  
Index: src/vsip/impl/signal-fir.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-fir.hpp,v
retrieving revision 1.6
diff -c -p -r1.6 signal-fir.hpp
*** src/vsip/impl/signal-fir.hpp	27 Oct 2005 17:50:50 -0000	1.6
--- src/vsip/impl/signal-fir.hpp	19 Dec 2005 18:39:48 -0000
***************
*** 22,29 ****
  namespace vsip
  {
  
- enum obj_state { state_no_save, state_save };
- 
  namespace impl
  {
  
--- 22,27 ----
Index: src/vsip/impl/signal-iir.hpp
===================================================================
RCS file: src/vsip/impl/signal-iir.hpp
diff -N src/vsip/impl/signal-iir.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/signal-iir.hpp	19 Dec 2005 18:39:48 -0000
***************
*** 0 ****
--- 1,235 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/signal-iir.hpp
+     @author  Jules Bergmann
+     @date    2005-12-17
+     @brief   VSIPL++ Library: IIR class [signal.iir].
+ */
+ 
+ #ifndef VSIP_IMPL_SIGNAL_IIR_HPP
+ #define VSIP_IMPL_SIGNAL_IIR_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/impl/signal-types.hpp>
+ 
+ 
+ 
+ /***********************************************************************
+   Declarations
+ ***********************************************************************/
+ 
+ namespace vsip
+ {
+ 
+ namespace impl
+ {
+ 
+ } // namespace vsip::impl
+ 
+ template <typename      T     = VSIP_DEFAULT_VALUE_TYPE,
+ 	  obj_state     c_f   = state_save,
+ 	  unsigned      n_o_t = 0,
+ 	  alg_hint_type a_h   = alg_time>
+ class Iir
+ {
+   // Compile-time constants
+ public:
+   static obj_state const continuous_filtering = c_f;
+ 
+   // Constructor, copy, assignment, and destructor.
+ public:
+   template <typename Block0,
+ 	    typename Block1>
+   Iir(const_Matrix<T, Block0>,
+       const_Matrix<T, Block1>,
+       length_type)
+     VSIP_THROW((std::bad_alloc));
+ 
+   Iir(Iir const&) 
+     VSIP_THROW((std::bad_alloc));
+ 
+   Iir& operator=(Iir const&) 
+     VSIP_THROW((std::bad_alloc));
+ 
+   ~Iir() VSIP_NOTHROW {}
+ 
+   // Accessors.
+ public:
+   length_type kernel_size()  const VSIP_NOTHROW { return 2 * a_.size(0); }
+   length_type filter_order() const VSIP_NOTHROW { return 2 * a_.size(0); }
+   length_type input_size()   const VSIP_NOTHROW { return input_size_; }
+   length_type output_size()  const VSIP_NOTHROW { return input_size_; }
+ 
+   // Specification has both member function and member static const
+   // variable with same name, which is not allowed in C++.  Since the
+   // member variable can be used in constant expressions (such as
+   // template parameters), as well as in situations where the function
+   // can be used, we implement the variable.
+   //
+   // obj_state continuous_filtering() const VSIP_NOTHROW;
+ 
+   // Operators.
+ public:
+   template <typename Block0, typename Block1>
+   Vector<T, Block1> operator()(
+     const_Vector<T, Block0>,
+     Vector<T, Block1>)
+     VSIP_NOTHROW;
+ 
+   void reset() VSIP_NOTHROW;
+ 
+   // Member data.
+ private:
+   Matrix<T>   b_;
+   Matrix<T>   a_;
+   Matrix<T>   w_;
+   length_type input_size_;
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ template <typename      T,
+ 	  obj_state     c_f,
+ 	  unsigned      n_o_t,
+ 	  alg_hint_type a_h>
+ template <typename      Block0,
+ 	  typename      Block1>
+ Iir<T, c_f, n_o_t, a_h>::Iir(
+   const_Matrix<T, Block0> B,
+   const_Matrix<T, Block1> A,
+   length_type             input_size)
+     VSIP_THROW((std::bad_alloc))
+   : b_         (B.size(0), B.size(1)),
+     a_         (A.size(0), A.size(1)),
+     w_         (b_.size(0), 2, T()),
+     input_size_(input_size)
+ {
+   assert(b_.size(0) == a_.size(0));
+   assert(b_.size(1) == 3);
+   assert(a_.size(1) == 2);
+ 
+   b_ = B;
+   a_ = A;
+ }
+ 
+ 
+ 
+ template <typename      T,
+ 	  obj_state     c_f,
+ 	  unsigned      n_o_t,
+ 	  alg_hint_type a_h>
+ Iir<T, c_f, n_o_t, a_h>::Iir(Iir const& iir)
+   VSIP_THROW((std::bad_alloc))
+   : b_         (iir.b_.size(0), 3),
+     a_         (iir.a_.size(0), 2),
+     w_         (b_.size(0), 2),
+     input_size_(iir.input_size_)
+ {
+   b_ = iir.b_;
+   a_ = iir.a_;
+   w_ = iir.w_;
+ }
+ 
+ 
+ 
+ template <typename      T,
+ 	  obj_state     c_f,
+ 	  unsigned      n_o_t,
+ 	  alg_hint_type a_h>
+ Iir<T, c_f, n_o_t, a_h>&
+ Iir<T, c_f, n_o_t, a_h>::operator=(Iir const& iir)
+   VSIP_THROW((std::bad_alloc))
+ {
+   assert(this->kernel_size() == iir.kernel_size());
+ 
+   b_ = iir.b_;
+   a_ = iir.a_;
+   w_ = iir.w_;
+ 
+   input_size_ = iir.input_size_;
+ 
+   return *this;
+ }
+ 
+ 
+ 
+ template <typename      T,
+ 	  obj_state     c_f,
+ 	  unsigned      n_o_t,
+ 	  alg_hint_type a_h>
+ template <typename      Block0,
+ 	  typename      Block1>
+ Vector<T, Block1>
+ Iir<T, c_f, n_o_t, a_h>::operator()(
+   const_Vector<T, Block0> data,
+   Vector<T, Block1>       out)
+   VSIP_NOTHROW
+ {
+   index_type const A1 = 0;
+   index_type const A2 = 1;
+ 
+   index_type const B0 = 0;
+   index_type const B1 = 1;
+   index_type const B2 = 2;
+ 
+   index_type const W1 = 0;
+   index_type const W2 = 1;
+ 
+   assert(data.size() == this->input_size());
+   assert(out.size()  == this->output_size());
+ 
+   length_type const M = a_.size(0);
+ 
+   for (index_type i=0; i<out.size(); ++i)
+   {
+     T val = data(i);
+ 
+     for (index_type m=0; m<M; ++m)
+     {
+       T w0 = val
+            - a_(m, A1) * w_(m, W1)
+            - a_(m, A2) * w_(m, W2);
+ 
+       val  = b_(m, B0) * w0
+            + b_(m, B1) * w_(m, W1)
+            + b_(m, B2) * w_(m, W2);
+ 
+       w_(m, W2) = w_(m, W1);
+       w_(m, W1) = w0;
+     }
+ 
+     out(i) = val;
+   }
+ 
+   if (c_f == state_no_save)
+     this->reset();
+ 
+   return out;
+ }
+ 
+ 
+ 
+ // Reset the filter state.
+ 
+ template <typename      T,
+ 	  obj_state     c_f,
+ 	  unsigned      n_o_t,
+ 	  alg_hint_type a_h>
+ inline void
+ Iir<T, c_f, n_o_t, a_h>::reset()
+   VSIP_NOTHROW
+ {
+   w_ = T();
+ }
+ 
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_SIGNAL_IIR_HPP
Index: src/vsip/impl/signal-types.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-types.hpp,v
retrieving revision 1.6
diff -c -p -r1.6 signal-types.hpp
*** src/vsip/impl/signal-types.hpp	7 Oct 2005 13:46:46 -0000	1.6
--- src/vsip/impl/signal-types.hpp	19 Dec 2005 18:39:48 -0000
*************** enum bias_type
*** 44,49 ****
--- 44,55 ----
    unbiased
  };
  
+ enum obj_state {
+   state_no_save,
+   state_save
+ };
+ 
+ 
  
  } // namespace vsip
  
Index: tests/iir.cpp
===================================================================
RCS file: tests/iir.cpp
diff -N tests/iir.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/iir.cpp	19 Dec 2005 18:39:48 -0000
***************
*** 0 ****
--- 1,312 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    iir.cpp
+     @author  Jules Bergmann
+     @date    2005-12-19
+     @brief   VSIPL++ Library: Unit tests for [signal.iir] items.
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ 
+ #include <cassert>
+ 
+ #include <vsip/vector.hpp>
+ #include <vsip/signal.hpp>
+ #include <vsip/initfin.hpp>
+ 
+ #include "test.hpp"
+ #include "error_db.hpp"
+ 
+ #define VERBOSE 0
+ 
+ #ifdef VERBOSE
+ #  include "output.hpp"
+ #endif
+ 
+ 
+ using namespace std;
+ using namespace vsip;
+ 
+ 
+ 
+ /***********************************************************************
+   Test IIR as single FIR -- no recursion
+ ***********************************************************************/
+ 
+ template <obj_state State,
+ 	  typename  T,
+ 	  typename  Block>
+ void
+ single_iir_as_fir_case(
+   length_type      size,
+   length_type      chunk,
+   Vector<T, Block> weights)
+ {
+   Matrix<T> b(1, 3);
+   Matrix<T> a(1, 2);
+ 
+   assert(weights.size() == 3);	// IIR is only 2nd order
+ 
+   assert(chunk <= size);
+   assert(size % chunk == 0);
+ 
+   b.row(0) = weights;
+ 
+   a(0, 0) = T(0);
+   a(0, 1) = T(0);
+ 
+   Iir<T, State> iir(b, a, chunk);
+ 
+   Fir<T, nonsym, State> fir(weights, chunk, 1);
+ 
+   Vector<T> data(size);
+   Vector<T> out_iir(size);
+   Vector<T> out_fir(size);
+ 
+   data = ramp(T(1), T(1), size);
+ 
+   index_type pos = 0;
+   while (pos < size)
+   {
+     iir(data(Domain<1>(pos, 1, chunk)), out_iir(Domain<1>(pos, 1, chunk)));
+     fir(data(Domain<1>(pos, 1, chunk)), out_fir(Domain<1>(pos, 1, chunk)));
+     pos += chunk;
+   }
+ 
+   float error = error_db(out_iir, out_fir);
+ 
+ #if VERBOSE
+   if (error >= -150)
+   {
+     std::cout << "iir =\n" << out_iir;
+     std::cout << "fir =\n" << out_fir;
+   }
+ #endif
+ 
+   assert(error < -150);
+ }
+ 
+ 
+ 
+ template <obj_state State,
+ 	  typename  T,
+ 	  typename  Block>
+ void
+ iir_as_fir_case(
+   length_type      size,
+   length_type      chunk,
+   Matrix<T, Block> b)
+ {
+   Matrix<T> a(b.size(0), 2, T());
+ 
+   assert(b.size(1) == 3);	// IIR is only 2nd order
+ 
+   assert(chunk <= size);
+   assert(size % chunk == 0);
+ 
+   length_type order = b.size(0);
+ 
+   Iir<T, State> iir(b, a, chunk);
+ 
+   Fir<T, nonsym, State>** fir;
+ 
+   fir = new Fir<T, nonsym, State>*[order];
+ 
+   for (length_type m=0; m<order; ++m)
+     fir[m] = new Fir<T, nonsym, State>(b.row(m), chunk, 1);
+ 
+   Vector<T> data(size);
+   Vector<T> out_iir(size);
+   Vector<T> out_fir(size);
+   Vector<T> tmp(chunk);
+ 
+   data = ramp(T(1), T(1), size);
+ 
+   index_type pos = 0;
+   while (pos < size)
+   {
+     iir(data(Domain<1>(pos, 1, chunk)), out_iir(Domain<1>(pos, 1, chunk)));
+ 
+     tmp = data(Domain<1>(pos, 1, chunk));
+ 
+     for (index_type m=0; m<order; ++m)
+     {
+       fir[m]->operator()(tmp, out_fir(Domain<1>(pos, 1, chunk)));
+       tmp = out_fir(Domain<1>(pos, 1, chunk));
+     }
+ 
+     pos += chunk;
+   }
+ 
+   float error = error_db(out_iir, out_fir);
+ 
+ #if VERBOSE
+   if (error >= -150)
+   {
+     std::cout << "iir =\n" << out_iir;
+     std::cout << "fir =\n" << out_fir;
+   }
+ #endif
+ 
+   assert(error < -150);
+ 
+   for (length_type m=0; m<order; ++m)
+     delete fir[m];
+   delete[] fir;
+ }
+ 
+ 
+ 
+ template <typename T>
+ void
+ test_iir_as_fir()
+ {
+   Matrix<T> w(4, 3);
+ 
+   w(0, 0) = T(1);
+   w(0, 1) = T(-2);
+   w(0, 2) = T(3);
+ 
+   w(1, 0) = T(3);
+   w(1, 1) = T(-1);
+   w(1, 2) = T(1);
+ 
+   w(2, 0) = T(1);
+   w(2, 1) = T(0);
+   w(2, 2) = T(-1);
+ 
+   w(3, 0) = T(-1);
+   w(3, 1) = T(2);
+   w(3, 2) = T(-2);
+ 
+   length_type size = 128;
+ 
+   iir_as_fir_case<state_save>(size, size, w);
+   iir_as_fir_case<state_save>(size, size/2, w);
+   iir_as_fir_case<state_save>(size, size/4, w);
+ 
+   iir_as_fir_case<state_no_save>(size, size, w);
+   iir_as_fir_case<state_no_save>(size, size/2, w);
+   iir_as_fir_case<state_no_save>(size, size/4, w);
+ }
+ 
+ 
+ 
+ /***********************************************************************
+   Test IIR as summation
+ ***********************************************************************/
+ 
+ ///
+ // Test:
+ //  [1] iir copy cons
+ //  [2] iir assignment
+ template <typename  T>
+ void
+ sum_case(
+   length_type      size,
+   length_type      chunk)
+ {
+   assert(chunk <= size);
+   assert(size % chunk == 0);
+ 
+   Matrix<T> b(1, 3);
+   Matrix<T> a(1, 2);
+   Matrix<T> b3(1, 3, T());
+   Matrix<T> a3(1, 2, T());
+ 
+   b(0, 0) = T(1);
+   b(0, 1) = T(0);
+   b(0, 2) = T(0);
+ 
+   a(0, 0) = T(-1);
+   a(0, 1) = T(0);
+ 
+   Iir<T, state_save> iir1(b, a, chunk);
+   Iir<T, state_save> iir2 = iir1;
+   Iir<T, state_save> iir3(b3, a3, chunk); // [1]
+ 
+   Vector<T> data(size);
+   Vector<T> out1(size);
+   Vector<T> out2(size);
+   Vector<T> out3(size);
+   Vector<T> exp(size);
+ 
+   data = ramp(T(1), T(1), size);
+ 
+   index_type pos = 0;
+   while (pos < size)
+   {
+     iir1(data(Domain<1>(pos, 1, chunk)), out1(Domain<1>(pos, 1, chunk)));
+     iir2(data(Domain<1>(pos, 1, chunk)), out2(Domain<1>(pos, 1, chunk)));
+ 
+     if (pos == 0)
+     {
+       out3(Domain<1>(pos, 1, chunk)) = out2(Domain<1>(pos, 1, chunk));
+       iir3 = iir1; // [2]
+     }
+     else
+       iir3(data(Domain<1>(pos, 1, chunk)), out3(Domain<1>(pos, 1, chunk)));
+ 
+     pos += chunk;
+   }
+ 
+   iir1.reset();
+ 
+   T accum = T();
+   for (index_type i=0; i<size; ++i)
+   {
+     accum += data(i);
+     exp(i) = accum;
+   }
+ 
+   float error1 = error_db(out1, exp);
+   float error2 = error_db(out2, exp);
+   float error3 = error_db(out3, exp);
+ 
+ #if VERBOSE
+   if (error1 >= -150 || error2 >= -150 || error3 >= -150)
+   {
+     std::cout << "out1 =\n" << out1;
+     std::cout << "out2 =\n" << out2;
+     std::cout << "out3 =\n" << out3;
+     std::cout << "exp  =\n" << exp;
+   }
+ #endif
+ 
+   assert(error1 < -150);
+   assert(error2 < -150);
+   assert(error3 < -150);
+ }
+ 
+ 
+ 
+ template <typename T>
+ void
+ test_sum()
+ {
+   sum_case<T>(128, 32);
+   sum_case<T>(16, 16);
+ }
+ 
+ 
+ 
+ /***********************************************************************
+   main
+ ***********************************************************************/
+ 
+ int
+ main()
+ {
+   vsipl init;
+ 
+   test_iir_as_fir<int>();
+   test_iir_as_fir<float>();
+   test_iir_as_fir<complex<float> >();
+ 
+   test_sum<int>();
+   test_sum<float>();
+   test_sum<complex<float> >();
+ }
