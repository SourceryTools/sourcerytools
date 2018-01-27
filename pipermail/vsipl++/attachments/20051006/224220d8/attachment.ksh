Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.287
diff -c -p -r1.287 ChangeLog
*** ChangeLog	5 Oct 2005 11:41:03 -0000	1.287
--- ChangeLog	6 Oct 2005 20:30:53 -0000
***************
*** 1,3 ****
--- 1,27 ----
+ 2005-10-06  Jules Bergmann  <jules@codesourcery.com>
+ 
+ 	Implement 1-D correlation.
+ 	* src/vsip/impl/signal-conv-common.hpp (Opt_tag): Add optimized
+ 	  implementation tag.
+ 	* src/vsip/impl/signal-corr-common.hpp: New file, common routines
+ 	  and decls for correlation.
+ 	* src/vsip/impl/signal-corr-ext.hpp: New file, generic correlation
+ 	  implementation using Ext_data interface.
+ 	* src/vsip/impl/signal-corr-opt.hpp: New file, optimized correlation
+ 	  implementation using FFT overlap-add.
+ 	* src/vsip/impl/signal-corr.hpp: New file, correlation class.
+ 	* src/vsip/signal.hpp: Include signal-corr.hpp.
+ 	* src/vsip/impl/signal-types.hpp (bias_type): New type for correlation.
+ 	* src/vsip/matrix.hpp: Pass view by value to op-assign operators.
+ 	* src/vsip/tensor.hpp: Likewise.
+ 	* src/vsip/vector.hpp: Likewise.
+ 	* src/vsip/impl/domain-utils.hpp (normalize): New functions to
+ 	  normalize a domain to offset=0, stride=1, and length=same.
+ 	* src/vsip/impl/metaprogramming.hpp (Complex_of): Convert a type
+ 	  to complex.
+ 	* tests/correlation.cpp: New file, unit tests for correlation.
+ 	* benchmarks/corr.cpp: New file, benchmark correlation cases.
+ 
  2005-10-05  Jules Bergmann  <jules@codesourcery.com>
  
  	Support symmetric convolution kernels.
Index: benchmarks/corr.cpp
===================================================================
RCS file: benchmarks/corr.cpp
diff -N benchmarks/corr.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- benchmarks/corr.cpp	6 Oct 2005 20:30:53 -0000
***************
*** 0 ****
--- 1,269 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    benchmarks/corr.cpp
+     @author  Jules Bergmann
+     @date    2005-10-06
+     @brief   VSIPL++ Library: Benchmark for Correlation.
+ 
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <iostream>
+ 
+ #include <vsip/initfin.hpp>
+ #include <vsip/support.hpp>
+ #include <vsip/math.hpp>
+ #include <vsip/signal.hpp>
+ 
+ #include <vsip/impl/profile.hpp>
+ 
+ #include "test.hpp"
+ #include "loop.hpp"
+ #include "ops_info.hpp"
+ 
+ using namespace vsip;
+ 
+ 
+ /// Return a random value between -0.5 and +0.5
+ 
+ template <typename T>
+ struct Random
+ {
+   static T value() { return T(1.f * rand()/(RAND_MAX+1.0)) - T(0.5); }
+ };
+ 
+ /// Specialization for random complex value.
+ 
+ template <typename T>
+ struct Random<complex<T> >
+ {
+   static complex<T> value() {
+     return complex<T>(Random<T>::value(), Random<T>::value());
+   }
+ };
+ 
+ 
+ 
+ /// Fill a matrix with random values.
+ 
+ template <typename T,
+ 	  typename Block>
+ void
+ randm(Matrix<T, Block> m)
+ {
+   for (index_type r=0; r<m.size(0); ++r)
+     for (index_type c=0; c<m.size(1); ++c)
+       m(r, c) = Random<T>::value();
+ }
+ 
+ 
+ template <support_region_type Supp,
+ 	  typename            T>
+ struct t_corr1
+ {
+   char* what() { return "t_corr1"; }
+   float ops_per_point(length_type size)
+   {
+     length_type output_size = this->my_output_size(size);
+     float ops = ref_size_ * output_size *
+       (Ops_info<T>::mul + Ops_info<T>::add);
+ 
+     return ops / size;
+   }
+ 
+   int riob_per_point(length_type) { return -1*sizeof(T); }
+   int wiob_per_point(length_type) { return -1*sizeof(T); }
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+     length_type output_size = this->my_output_size(size);
+ 
+     Vector<T>   in (size, T());
+     Vector<T>   out(output_size);
+     Vector<T>   ref(ref_size_, T());
+ 
+     ref(0) = T(1);
+     ref(1) = T(2);
+ 
+     typedef Correlation<const_Vector, Supp, T> corr_type;
+ 
+     corr_type corr((Domain<1>(ref_size_)), Domain<1>(size));
+ 
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+      corr(bias_, ref, in, out);
+     t1.stop();
+     
+     time = t1.delta();
+   }
+ 
+   t_corr1(length_type ref_size, bias_type bias)
+     : ref_size_(ref_size),
+       bias_    (bias)
+   {}
+ 
+   
+   length_type my_output_size(length_type size)
+   {
+     if      (Supp == support_full)
+       return size + ref_size_ - 1;
+     else if (Supp == support_same)
+       return size;
+     else /* (Supp == support_min) */
+       return size - ref_size_ + 1;
+   }
+   
+ 
+   length_type ref_size_;
+   bias_type   bias_;
+ };
+ 
+ 
+ 
+ template <typename            Tag,
+ 	  support_region_type Supp,
+ 	  typename            T>
+ struct t_corr2
+ {
+   char* what() { return "t_corr2"; }
+   float ops_per_point(length_type size)
+   {
+     length_type output_size = this->my_output_size(size);
+     float ops = ref_size_ * output_size *
+       (Ops_info<T>::mul + Ops_info<T>::add);
+ 
+     return ops / size;
+   }
+ 
+   int riob_per_point(length_type) { return -1*sizeof(T); }
+   int wiob_per_point(length_type) { return -1*sizeof(T); }
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+     length_type output_size = this->my_output_size(size);
+ 
+     Vector<T>   in (size, T());
+     Vector<T>   out(output_size);
+     Vector<T>   ref(ref_size_, T());
+ 
+     ref(0) = T(1);
+     ref(1) = T(2);
+ 
+     typedef impl::Correlation_impl<const_Vector, Supp, T, 0, alg_time, Tag>
+ 		corr_type;
+ 
+     corr_type corr((Domain<1>(ref_size_)), Domain<1>(size));
+ 
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+      corr.impl_correlate(bias_, ref, in, out);
+     t1.stop();
+     
+     time = t1.delta();
+   }
+ 
+   t_corr2(length_type ref_size, bias_type bias)
+     : ref_size_(ref_size),
+       bias_    (bias)
+   {}
+ 
+   
+   length_type my_output_size(length_type size)
+   {
+     if      (Supp == support_full)
+       return size + ref_size_ - 1;
+     else if (Supp == support_same)
+       return size;
+     else /* (Supp == support_min) */
+       return size - ref_size_ + 1;
+   }
+   
+ 
+   length_type ref_size_;
+   bias_type   bias_;
+ };
+ 
+ 
+ 
+ void
+ defaults(Loop1P& loop)
+ {
+   loop.loop_start_ = 5000;
+   loop.start_ = 4;
+   loop.user_param_ = 16;
+ }
+ 
+ 
+ 
+ int
+ test(Loop1P& loop, int what)
+ {
+   length_type M = loop.user_param_;
+   using vsip::impl::Opt_tag;
+   using vsip::impl::Generic_tag;
+ 
+   typedef float T;
+   typedef complex<float> CT;
+ 
+   switch (what)
+   {
+   case  1: loop(t_corr1<support_full, T>(M, biased)); break;
+   case  2: loop(t_corr1<support_same, T>(M, biased)); break;
+   case  3: loop(t_corr1<support_min,  T>(M, biased)); break;
+ 
+   case  4: loop(t_corr1<support_full, T>(M, unbiased)); break;
+   case  5: loop(t_corr1<support_same, T>(M, unbiased)); break;
+   case  6: loop(t_corr1<support_min,  T>(M, unbiased)); break;
+ 
+   case  7: loop(t_corr1<support_full, CT >(M, biased)); break;
+   case  8: loop(t_corr1<support_same, CT >(M, biased)); break;
+   case  9: loop(t_corr1<support_min,  CT >(M, biased)); break;
+ 
+   case  10: loop(t_corr1<support_full, CT >(M, unbiased)); break;
+   case  11: loop(t_corr1<support_same, CT >(M, unbiased)); break;
+   case  12: loop(t_corr1<support_min,  CT >(M, unbiased)); break;
+ 
+   case  13: loop(t_corr2<Opt_tag, support_full, T>(M, biased)); break;
+   case  14: loop(t_corr2<Opt_tag, support_same, T>(M, biased)); break;
+   case  15: loop(t_corr2<Opt_tag, support_min,  T>(M, biased)); break;
+ 
+   case  16: loop(t_corr2<Opt_tag, support_full, T>(M, unbiased)); break;
+   case  17: loop(t_corr2<Opt_tag, support_same, T>(M, unbiased)); break;
+   case  18: loop(t_corr2<Opt_tag, support_min,  T>(M, unbiased)); break;
+ 
+   case  19: loop(t_corr2<Opt_tag, support_full, CT >(M, biased)); break;
+   case  20: loop(t_corr2<Opt_tag, support_same, CT >(M, biased)); break;
+   case  21: loop(t_corr2<Opt_tag, support_min,  CT >(M, biased)); break;
+ 
+   case  22: loop(t_corr2<Opt_tag, support_full, CT >(M, unbiased)); break;
+   case  23: loop(t_corr2<Opt_tag, support_same, CT >(M, unbiased)); break;
+   case  24: loop(t_corr2<Opt_tag, support_min,  CT >(M, unbiased)); break;
+ 
+   case  25: loop(t_corr2<Generic_tag, support_full, T>(M, biased)); break;
+   case  26: loop(t_corr2<Generic_tag, support_same, T>(M, biased)); break;
+   case  27: loop(t_corr2<Generic_tag, support_min,  T>(M, biased)); break;
+ 
+   case  28: loop(t_corr2<Generic_tag, support_full, T>(M, unbiased)); break;
+   case  29: loop(t_corr2<Generic_tag, support_same, T>(M, unbiased)); break;
+   case  30: loop(t_corr2<Generic_tag, support_min,  T>(M, unbiased)); break;
+ 
+   case  31: loop(t_corr2<Generic_tag, support_full, CT >(M, biased)); break;
+   case  32: loop(t_corr2<Generic_tag, support_same, CT >(M, biased)); break;
+   case  33: loop(t_corr2<Generic_tag, support_min,  CT >(M, biased)); break;
+ 
+   case  34: loop(t_corr2<Generic_tag, support_full, CT >(M, unbiased)); break;
+   case  35: loop(t_corr2<Generic_tag, support_same, CT >(M, unbiased)); break;
+   case  36: loop(t_corr2<Generic_tag, support_min,  CT >(M, unbiased)); break;
+ 
+ 
+   default: return 0;
+   }
+   return 1;
+ }
Index: src/vsip/matrix.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/matrix.hpp,v
retrieving revision 1.27
diff -c -p -r1.27 matrix.hpp
*** src/vsip/matrix.hpp	27 Sep 2005 22:44:40 -0000	1.27
--- src/vsip/matrix.hpp	6 Oct 2005 20:30:54 -0000
*************** public:
*** 307,316 ****
    Matrix& operator asop(T0 const& val) VSIP_NOTHROW                \
    { VSIP_IMPL_ELEMENTWISE_SCALAR(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Matrix& operator asop(const_Matrix<T0, Block0>& m) VSIP_NOTHROW  \
    { VSIP_IMPL_ELEMENTWISE_MATRIX(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Matrix& operator asop(const Matrix<T0, Block0>& m) VSIP_NOTHROW  \
    { VSIP_IMPL_ELEMENTWISE_MATRIX(op); return *this;}
  
    // [view.matrix.assign]
--- 307,316 ----
    Matrix& operator asop(T0 const& val) VSIP_NOTHROW                \
    { VSIP_IMPL_ELEMENTWISE_SCALAR(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Matrix& operator asop(const_Matrix<T0, Block0> m) VSIP_NOTHROW   \
    { VSIP_IMPL_ELEMENTWISE_MATRIX(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Matrix& operator asop(const Matrix<T0, Block0> m) VSIP_NOTHROW   \
    { VSIP_IMPL_ELEMENTWISE_MATRIX(op); return *this;}
  
    // [view.matrix.assign]
Index: src/vsip/signal.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/signal.hpp,v
retrieving revision 1.9
diff -c -p -r1.9 signal.hpp
*** src/vsip/signal.hpp	20 Sep 2005 12:38:57 -0000	1.9
--- src/vsip/signal.hpp	6 Oct 2005 20:30:54 -0000
***************
*** 15,22 ****
  ***********************************************************************/
  
  #include <vsip/impl/signal-types.hpp>
- #include <vsip/impl/signal-conv.hpp>
  #include <vsip/impl/signal-fft.hpp>
  #include <vsip/impl/signal-window.hpp>
  
  
--- 15,23 ----
  ***********************************************************************/
  
  #include <vsip/impl/signal-types.hpp>
  #include <vsip/impl/signal-fft.hpp>
+ #include <vsip/impl/signal-conv.hpp>
+ #include <vsip/impl/signal-corr.hpp>
  #include <vsip/impl/signal-window.hpp>
  
  
Index: src/vsip/tensor.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/tensor.hpp,v
retrieving revision 1.20
diff -c -p -r1.20 tensor.hpp
*** src/vsip/tensor.hpp	27 Sep 2005 22:44:40 -0000	1.20
--- src/vsip/tensor.hpp	6 Oct 2005 20:30:54 -0000
*************** public:
*** 540,549 ****
    Tensor& operator asop(T0 const& val) VSIP_NOTHROW                \
    { VSIP_IMPL_ELEMENTWISE_SCALAR(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Tensor& operator asop(const_Tensor<T0, Block0>& m) VSIP_NOTHROW  \
    { VSIP_IMPL_ELEMENTWISE_TENSOR(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Tensor& operator asop(const Tensor<T0, Block0>& m) VSIP_NOTHROW  \
    { VSIP_IMPL_ELEMENTWISE_TENSOR(op); return *this;}
  
    // [view.tensor.assign]
--- 540,549 ----
    Tensor& operator asop(T0 const& val) VSIP_NOTHROW                \
    { VSIP_IMPL_ELEMENTWISE_SCALAR(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Tensor& operator asop(const_Tensor<T0, Block0> m) VSIP_NOTHROW   \
    { VSIP_IMPL_ELEMENTWISE_TENSOR(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Tensor& operator asop(const Tensor<T0, Block0> m) VSIP_NOTHROW   \
    { VSIP_IMPL_ELEMENTWISE_TENSOR(op); return *this;}
  
    // [view.tensor.assign]
Index: src/vsip/vector.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/vector.hpp,v
retrieving revision 1.32
diff -c -p -r1.32 vector.hpp
*** src/vsip/vector.hpp	27 Sep 2005 22:44:41 -0000	1.32
--- src/vsip/vector.hpp	6 Oct 2005 20:30:54 -0000
*************** public:
*** 132,141 ****
    Vector& operator asop(T0 const& val) VSIP_NOTHROW                \
    { VSIP_IMPL_ELEMENTWISE_SCALAR(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Vector& operator asop(const_Vector<T0, Block0>& v) VSIP_NOTHROW  \
    { VSIP_IMPL_ELEMENTWISE_VECTOR(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Vector& operator asop(const Vector<T0, Block0>& v) VSIP_NOTHROW  \
    { VSIP_IMPL_ELEMENTWISE_VECTOR(op); return *this;}
  
  #define VSIP_IMPL_ASSIGN_OP_NOFWD(asop, op)			   \
--- 132,141 ----
    Vector& operator asop(T0 const& val) VSIP_NOTHROW                \
    { VSIP_IMPL_ELEMENTWISE_SCALAR(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Vector& operator asop(const_Vector<T0, Block0> v) VSIP_NOTHROW  \
    { VSIP_IMPL_ELEMENTWISE_VECTOR(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Vector& operator asop(const Vector<T0, Block0> v) VSIP_NOTHROW  \
    { VSIP_IMPL_ELEMENTWISE_VECTOR(op); return *this;}
  
  #define VSIP_IMPL_ASSIGN_OP_NOFWD(asop, op)			   \
*************** public:
*** 143,152 ****
    Vector& operator asop(T0 const& val) VSIP_NOTHROW                \
    { VSIP_IMPL_ELEMENTWISE_SCALAR(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Vector& operator asop(const_Vector<T0, Block0>& v) VSIP_NOTHROW  \
    { VSIP_IMPL_ELEMENTWISE_VECTOR_NOFWD(op); return *this;}	   \
    template <typename T0, typename Block0>                          \
!   Vector& operator asop(const Vector<T0, Block0>& v) VSIP_NOTHROW  \
    { VSIP_IMPL_ELEMENTWISE_VECTOR_NOFWD(op); return *this;}
  
  
--- 143,152 ----
    Vector& operator asop(T0 const& val) VSIP_NOTHROW                \
    { VSIP_IMPL_ELEMENTWISE_SCALAR(op); return *this;}               \
    template <typename T0, typename Block0>                          \
!   Vector& operator asop(const_Vector<T0, Block0> v) VSIP_NOTHROW   \
    { VSIP_IMPL_ELEMENTWISE_VECTOR_NOFWD(op); return *this;}	   \
    template <typename T0, typename Block0>                          \
!   Vector& operator asop(const Vector<T0, Block0> v) VSIP_NOTHROW   \
    { VSIP_IMPL_ELEMENTWISE_VECTOR_NOFWD(op); return *this;}
  
  
Index: src/vsip/impl/domain-utils.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/domain-utils.hpp,v
retrieving revision 1.7
diff -c -p -r1.7 domain-utils.hpp
*** src/vsip/impl/domain-utils.hpp	28 Aug 2005 02:15:57 -0000	1.7
--- src/vsip/impl/domain-utils.hpp	6 Oct 2005 20:30:54 -0000
*************** empty_domain()
*** 312,317 ****
--- 312,342 ----
    return construct_domain<Dim>(dom);
  }
  
+ 
+ 
+ /// Normalize a domain -- return a new domain with the same length
+ /// in each dimension, but with offset = 0 and stride = 1.
+ 
+ inline Domain<1>
+ normalize(Domain<1> const& dom)
+ {
+   return Domain<1>(dom.size());
+ }
+ 
+ inline Domain<2>
+ normalize(Domain<2> const& dom)
+ {
+   return Domain<2>(dom[0].size(), dom[1].size());
+ }
+ 
+ inline Domain<3>
+ normalize(Domain<3> const& dom)
+ {
+   return Domain<3>(dom[0].size(), dom[1].size(), dom[2].size());
+ }
+ 
+ 
+ 
  } // namespace vsip::impl
  
  } // namespace vsip
Index: src/vsip/impl/metaprogramming.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/metaprogramming.hpp,v
retrieving revision 1.9
diff -c -p -r1.9 metaprogramming.hpp
*** src/vsip/impl/metaprogramming.hpp	27 Sep 2005 21:30:17 -0000	1.9
--- src/vsip/impl/metaprogramming.hpp	6 Oct 2005 20:30:54 -0000
*************** template <typename T> struct Scalar_of<s
*** 101,106 ****
--- 101,114 ----
    { typedef typename Scalar_of<T>::type type; };
  
  template <typename T>
+ struct Complex_of 
+ { typedef std::complex<T> type; };
+ 
+ template <typename T>
+ struct Complex_of<std::complex<T> >
+ { typedef std::complex<T> type; };
+ 
+ template <typename T>
  struct Is_complex
  { static bool const value = false; };
  
Index: src/vsip/impl/signal-conv-common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-conv-common.hpp,v
retrieving revision 1.3
diff -c -p -r1.3 signal-conv-common.hpp
*** src/vsip/impl/signal-conv-common.hpp	5 Oct 2005 11:41:03 -0000	1.3
--- src/vsip/impl/signal-conv-common.hpp	6 Oct 2005 20:30:54 -0000
*************** namespace impl
*** 57,62 ****
--- 57,63 ----
  {
  
  struct Generic_tag {};
+ struct Opt_tag {};
  
  template <template <typename, typename> class ConstViewT,
  	  symmetry_type                       Symm,
Index: src/vsip/impl/signal-corr-common.hpp
===================================================================
RCS file: src/vsip/impl/signal-corr-common.hpp
diff -N src/vsip/impl/signal-corr-common.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/signal-corr-common.hpp	6 Oct 2005 20:30:54 -0000
***************
*** 0 ****
--- 1,189 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/signal-corr-common.hpp
+     @author  Jules Bergmann
+     @date    2005-10-05
+     @brief   VSIPL++ Library: Common decls and functions for correlation.
+ */
+ 
+ #ifndef VSIP_IMPL_SIGNAL_CORR_COMMON_HPP
+ #define VSIP_IMPL_SIGNAL_CORR_COMMON_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/domain.hpp>
+ #include <vsip/vector.hpp>
+ #include <vsip/matrix.hpp>
+ #include <vsip/impl/domain-utils.hpp>
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
+ /***********************************************************************
+   Base class
+ ***********************************************************************/
+ 
+ namespace impl
+ {
+ 
+ template <template <typename, typename> class ConstViewT,
+ 	  support_region_type                 Supp,
+ 	  typename                            T,
+ 	  unsigned                            n_times,
+           alg_hint_type                       a_hint,
+           typename                            ImplTag>
+ class Correlation_impl;
+ 
+ template <typename ImplTag,
+ 	  typename T>
+ struct Is_corr_impl_avail
+ {
+   static bool const value = false;
+ };
+ 
+ 
+ template <typename T>
+ struct Correlation_accum_trait
+ {
+   typedef T sum_type;
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ /// Perform convolution with full region of support.
+ 
+ template <typename T>
+ inline void
+ corr_full(
+   bias_type   bias,
+   T*          ref,
+   length_type ref_size,		// M
+   stride_type ref_stride,
+   T*          in,
+   length_type in_size,		// N
+   stride_type in_stride,
+   T*          out,
+   length_type out_size,		// P
+   stride_type out_stride)
+ {
+   typedef typename Correlation_accum_trait<T>::sum_type sum_type;
+ 
+   for (index_type n=0; n<out_size; ++n)
+   {
+     sum_type sum   = sum_type();
+     sum_type scale = sum_type();
+       
+     for (index_type k=0; k<ref_size; ++k)
+     {
+       index_type pos = n + k - (ref_size-1);
+ 
+       if (n+k >= (ref_size-1) && n+k < in_size+(ref_size-1))
+       {
+ 	sum += ref[k * ref_stride] * impl_conj(in[pos * in_stride]);
+ 	scale += sum_type(1);
+       }
+     }
+     if (bias == unbiased)
+       sum /= scale;
+     out[n * out_stride] = sum;
+   }
+ }
+ 
+ 
+ 
+ /// Perform convolution with same region of support.
+ 
+ template <typename T>
+ inline void
+ corr_same(
+   bias_type   bias,
+   T*          ref,
+   length_type ref_size,		// M
+   stride_type ref_stride,
+   T*          in,
+   length_type in_size,		// N
+   stride_type in_stride,
+   T*          out,
+   length_type out_size,		// P
+   stride_type out_stride)
+ {
+   typedef typename Correlation_accum_trait<T>::sum_type sum_type;
+ 
+   for (index_type n=0; n<out_size; ++n)
+   {
+     sum_type sum   = sum_type();
+     sum_type scale = sum_type();
+       
+     for (index_type k=0; k<ref_size; ++k)
+     {
+       index_type pos = n + k - (ref_size/2);
+ 
+       if (n+k >= (ref_size/2) && n+k <  in_size + (ref_size/2))
+       {
+ 	sum += ref[k * ref_stride] * impl_conj(in[pos * in_stride]);
+ 	scale += sum_type(1);
+       }
+     }
+     if (bias == unbiased)
+       sum /= scale;
+     out[n * out_stride] = sum;
+   }
+ }
+ 
+ 
+ 
+ /// Perform convolution with minimal region of support.
+ 
+ template <typename T>
+ inline void
+ corr_min(
+   bias_type   bias,
+   T*          ref,
+   length_type ref_size,		// M
+   stride_type ref_stride,
+   T*          in,
+   length_type /*in_size*/,	// N
+   stride_type in_stride,
+   T*          out,
+   length_type out_size,		// P
+   stride_type out_stride)
+ {
+   typedef typename Correlation_accum_trait<T>::sum_type sum_type;
+ 
+   for (index_type n=0; n<out_size; ++n)
+   {
+     sum_type sum = sum_type();
+       
+     for (index_type k=0; k<ref_size; ++k)
+     {
+       sum += ref[k*ref_stride] * impl_conj(in[(n+k) * in_stride]);
+     }
+ 
+     if (bias == unbiased)
+       sum /= sum_type(ref_size);
+ 
+     out[n * out_stride] = sum;
+   }
+ }
+ 
+ 
+ 
+ } // namespace vsip::impl
+ 
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_SIGNAL_CORR_COMMON_HPP
Index: src/vsip/impl/signal-corr-ext.hpp
===================================================================
RCS file: src/vsip/impl/signal-corr-ext.hpp
diff -N src/vsip/impl/signal-corr-ext.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/signal-corr-ext.hpp	6 Oct 2005 20:30:54 -0000
***************
*** 0 ****
--- 1,285 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/signal-corr-ext.hpp
+     @author  Jules Bergmann
+     @date    2005-10-05
+     @brief   VSIPL++ Library: Correlation class implementation using Ext_data.
+ */
+ 
+ #ifndef VSIP_IMPL_SIGNAL_CORR_EXT_HPP
+ #define VSIP_IMPL_SIGNAL_CORR_EXT_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/domain.hpp>
+ #include <vsip/vector.hpp>
+ #include <vsip/matrix.hpp>
+ #include <vsip/impl/domain-utils.hpp>
+ #include <vsip/impl/signal-types.hpp>
+ #include <vsip/impl/profile.hpp>
+ #include <vsip/impl/signal-conv-common.hpp>
+ #include <vsip/impl/signal-corr-common.hpp>
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
+ template <typename T>
+ struct Is_corr_impl_avail<Generic_tag, T>
+ {
+   static bool const value = true;
+ };
+ 
+ 
+ 
+ /// Specialize Correlation_impl for using IPP.
+ 
+ template <template <typename, typename> class ConstViewT,
+ 	  support_region_type Supp,
+ 	  typename            T,
+ 	  unsigned            n_times,
+           alg_hint_type       a_hint>
+ class Correlation_impl<ConstViewT, Supp, T, n_times, a_hint,
+ 		       Generic_tag>
+ {
+   static dimension_type const dim = impl::Dim_of_view<ConstViewT>::dim;
+ 
+   // Compile-time constants.
+ public:
+   static support_region_type const supprt  = Supp;
+ 
+   // Constructors, copies, assignments, and destructors.
+ public:
+   Correlation_impl(
+     Domain<dim> const&   ref_size,
+     Domain<dim> const&   input_size)
+     VSIP_THROW((std::bad_alloc));
+ 
+   Correlation_impl(Correlation_impl const&) VSIP_NOTHROW;
+   Correlation_impl& operator=(Correlation_impl const&) VSIP_NOTHROW;
+   ~Correlation_impl() VSIP_NOTHROW;
+ 
+   // Accessors.
+ public:
+   Domain<dim> const& reference_size() const VSIP_NOTHROW  { return ref_size_; }
+   Domain<dim> const& input_size() const VSIP_NOTHROW   { return input_size_; }
+   Domain<dim> const& output_size() const VSIP_NOTHROW  { return output_size_; }
+ 
+   float impl_performance(char* what) const
+   {
+     if      (!strcmp(what, "in_ext_cost"))
+     {
+       return pm_in_ext_cost_;
+     }
+     else if (!strcmp(what, "out_ext_cost"))
+     {
+       return pm_out_ext_cost_;
+     }
+     return 0.f;
+   }
+ 
+   // Implementation functions.
+ public:
+   template <typename Block0,
+ 	    typename Block1,
+ 	    typename Block2>
+   void
+   impl_correlate(bias_type               bias,
+ 	    const_Vector<T, Block0> ref,
+ 	    const_Vector<T, Block1> in,
+ 	    Vector<T, Block2>       out)
+     VSIP_NOTHROW;
+ 
+   template <typename Block0,
+ 	    typename Block1,
+ 	    typename Block2>
+   void
+   impl_correlate(bias_type               bias,
+ 	    const_Matrix<T, Block0> ref,
+ 	    const_Matrix<T, Block1> in,
+ 	    Matrix<T, Block2>       out)
+     VSIP_NOTHROW;
+ 
+   typedef vsip::impl::Layout<1, row1_type, vsip::impl::Stride_unit, vsip::impl::Cmplx_inter_fmt> layout_type;
+   typedef Vector<T> coeff_view_type;
+   typedef impl::Ext_data<typename coeff_view_type::block_type, layout_type> c_ext_type;
+ 
+   // Member data.
+ private:
+   Domain<dim>     ref_size_;
+   Domain<dim>     input_size_;
+   Domain<dim>     output_size_;
+ 
+   T*              in_buffer_;
+   T*              out_buffer_;
+   T*              ref_buffer_;
+ 
+   size_t          pm_ref_ext_cost_;
+   size_t          pm_in_ext_cost_;
+   size_t          pm_out_ext_cost_;
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ /// Construct a correlation object.
+ 
+ template <template <typename, typename> class ConstViewT,
+ 	  support_region_type                 Supp,
+ 	  typename                            T,
+ 	  unsigned                            n_times,
+           alg_hint_type                       a_hint>
+ Correlation_impl<ConstViewT, Supp, T, n_times, a_hint, Generic_tag>::
+ Correlation_impl(
+   Domain<dim> const&   ref_size,
+   Domain<dim> const&   input_size)
+ VSIP_THROW((std::bad_alloc))
+   : ref_size_   (normalize(ref_size)),
+     input_size_ (normalize(input_size)),
+     output_size_(conv_output_size(Supp, ref_size_, input_size_, 1))
+ {
+   in_buffer_  = new T[input_size_.size()];
+   if (in_buffer_ == NULL)
+     VSIP_IMPL_THROW(std::bad_alloc());
+ 
+   out_buffer_ = new T[output_size_.size()];
+   if (out_buffer_ == NULL)
+   {
+     delete[] in_buffer_;
+     VSIP_IMPL_THROW(std::bad_alloc());
+   }
+ 
+   ref_buffer_ = new T[ref_size_.size()];
+   if (ref_buffer_ == NULL)
+   {
+     delete[] out_buffer_;
+     delete[] in_buffer_;
+     VSIP_IMPL_THROW(std::bad_alloc());
+   }
+ }
+ 
+ 
+ 
+ /// Destroy a generic Correlation_impl object.
+ 
+ template <template <typename, typename> class ConstViewT,
+ 	  support_region_type                 Supp,
+ 	  typename                            T,
+ 	  unsigned                            n_times,
+           alg_hint_type                       a_hint>
+ Correlation_impl<ConstViewT, Supp, T, n_times, a_hint, Generic_tag>::
+ ~Correlation_impl()
+   VSIP_NOTHROW
+ {
+   delete[] ref_buffer_;
+   delete[] out_buffer_;
+   delete[] in_buffer_;
+ }
+ 
+ 
+ 
+ // Perform 1-D convolution.
+ 
+ template <template <typename, typename> class ConstViewT,
+ 	  support_region_type Supp,
+ 	  typename            T,
+ 	  unsigned            n_times,
+           alg_hint_type       a_hint>
+ template <typename Block0,
+ 	  typename Block1,
+ 	  typename Block2>
+ void
+ Correlation_impl<ConstViewT, Supp, T, n_times, a_hint, Generic_tag>::
+ impl_correlate(
+   bias_type               bias,
+   const_Vector<T, Block0> ref,
+   const_Vector<T, Block1> in,
+   Vector<T, Block2>       out)
+ VSIP_NOTHROW
+ {
+   length_type const M = this->ref_size_[0].size();
+   length_type const N = this->input_size_[0].size();
+   length_type const P = this->output_size_[0].size();
+ 
+   assert(M == ref.size());
+   assert(N == in.size());
+   assert(P == out.size());
+ 
+   typedef vsip::impl::Ext_data<Block0> ref_ext_type;
+   typedef vsip::impl::Ext_data<Block1> in_ext_type;
+   typedef vsip::impl::Ext_data<Block2> out_ext_type;
+ 
+   ref_ext_type ref_ext(ref.block(), vsip::impl::SYNC_IN,  ref_buffer_);
+   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
+   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
+ 
+   pm_ref_ext_cost_ += ref_ext.cost();
+   pm_in_ext_cost_  += in_ext.cost();
+   pm_out_ext_cost_ += out_ext.cost();
+ 
+   T* pref   = ref_ext.data();
+   T* pin    = in_ext.data();
+   T* pout   = out_ext.data();
+ 
+   stride_type s_ref = ref_ext.stride(0);
+   stride_type s_in  = in_ext.stride(0);
+   stride_type s_out = out_ext.stride(0);
+ 
+   if (Supp == support_full)
+   {
+     corr_full<T>(bias, pref, M, s_ref, pin, N, s_in, pout, P, s_out);
+   }
+   else if (Supp == support_same)
+   {
+     corr_same<T>(bias, pref, M, s_ref, pin, N, s_in, pout, P, s_out);
+   }
+   else // (Supp == support_min)
+   {
+     corr_min<T>(bias, pref, M, s_ref, pin, N, s_in, pout, P, s_out);
+   }
+ }
+ 
+ 
+ 
+ // Perform 2-D convolution.
+ 
+ template <template <typename, typename> class ConstViewT,
+ 	  support_region_type                 Supp,
+ 	  typename                            T,
+ 	  unsigned                            n_times,
+           alg_hint_type                       a_hint>
+ template <typename Block0,
+ 	  typename Block1,
+ 	  typename Block2>
+ void
+ Correlation_impl<ConstViewT, Supp, T, n_times, a_hint, Generic_tag>::
+ impl_correlate(
+   bias_type               bias,
+   const_Matrix<T, Block0> ref,
+   const_Matrix<T, Block1> in,
+   Matrix<T, Block2>       out)
+ VSIP_NOTHROW
+ {
+   VSIP_IMPL_THROW(vsip::impl::unimplemented(
+     "Correlation_impl<Generic_tag>: 2D correlation not implemented."));
+ }
+ 
+ } // namespace vsip::impl
+ 
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_SIGNAL_CORR_EXT_HPP
Index: src/vsip/impl/signal-corr-opt.hpp
===================================================================
RCS file: src/vsip/impl/signal-corr-opt.hpp
diff -N src/vsip/impl/signal-corr-opt.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/signal-corr-opt.hpp	6 Oct 2005 20:30:54 -0000
***************
*** 0 ****
--- 1,396 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/signal-corr-opt.hpp
+     @author  Jules Bergmann
+     @date    2005-10-05
+     @brief   VSIPL++ Library: Correlation class implementation using 
+ 			      FFT overlap and add algorithm.
+ */
+ 
+ #ifndef VSIP_IMPL_SIGNAL_CORR_OPT_HPP
+ #define VSIP_IMPL_SIGNAL_CORR_OPT_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <algorithm>
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/domain.hpp>
+ #include <vsip/vector.hpp>
+ #include <vsip/matrix.hpp>
+ #include <vsip/selgen.hpp>
+ #include <vsip/impl/domain-utils.hpp>
+ #include <vsip/impl/signal-types.hpp>
+ #include <vsip/impl/profile.hpp>
+ #include <vsip/impl/signal-conv-common.hpp>
+ #include <vsip/impl/signal-corr-common.hpp>
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
+ template <typename T>
+ struct Is_corr_impl_avail<Opt_tag, T>
+ {
+   static bool const value = true;
+ };
+ 
+ 
+ 
+ /// Compute next power of 2 after len.
+ 
+ inline length_type
+ next_power_of_2(length_type len)
+ {
+   length_type pow2 = 1;
+   while (pow2 < len)
+     pow2 *= 2;
+   return pow2;
+ }
+ 
+ 
+ 
+ // Choose FFT size for overlap and add.
+ 
+ inline length_type
+ choose_fft_size(length_type M, length_type N)
+ {
+   if (M+N < 1024)
+     return next_power_of_2(M+N);
+   if (4*next_power_of_2(M) > 1024)
+     return 4*next_power_of_2(M);
+   return 1024;
+ }
+ 
+ 
+ 
+ /// Specialize Correlation_impl for FFT overlap and add algorithm.
+ 
+ template <template <typename, typename> class ConstViewT,
+ 	  support_region_type Supp,
+ 	  typename            T,
+ 	  unsigned            n_times,
+           alg_hint_type       a_hint>
+ class Correlation_impl<ConstViewT, Supp, T, n_times, a_hint,
+ 		       Opt_tag>
+ {
+   typedef typename Complex_of<T>::type complex_type;
+ 
+   static dimension_type const dim = impl::Dim_of_view<ConstViewT>::dim;
+ 
+   // Compile-time constants.
+ public:
+   static support_region_type const supprt  = Supp;
+ 
+   // Constructors, copies, assignments, and destructors.
+ public:
+   Correlation_impl(
+     Domain<dim> const&   ref_size,
+     Domain<dim> const&   input_size)
+     VSIP_THROW((std::bad_alloc));
+ 
+   Correlation_impl(Correlation_impl const&) VSIP_NOTHROW;
+   Correlation_impl& operator=(Correlation_impl const&) VSIP_NOTHROW;
+   ~Correlation_impl() VSIP_NOTHROW;
+ 
+   // Accessors.
+ public:
+   Domain<dim> const& reference_size() const VSIP_NOTHROW  { return ref_size_; }
+   Domain<dim> const& input_size() const VSIP_NOTHROW   { return input_size_; }
+   Domain<dim> const& output_size() const VSIP_NOTHROW  { return output_size_; }
+   //TODO// support_region_type support() const VSIP_NOTHROW     { return Supp; }
+ 
+   float impl_performance(char* what) const
+   {
+     if      (!strcmp(what, "in_ext_cost"))
+     {
+       return pm_in_ext_cost_;
+     }
+     else if (!strcmp(what, "out_ext_cost"))
+     {
+       return pm_out_ext_cost_;
+     }
+     else if (!strcmp(what, "non-opt-calls"))
+     {
+       return pm_non_opt_calls_;
+     }
+     return 0.f;
+   }
+ 
+   // Implementation functions.
+ public:
+   template <typename Block0,
+ 	    typename Block1,
+ 	    typename Block2>
+   void
+   impl_correlate(bias_type               bias,
+ 	    const_Vector<T, Block0> ref,
+ 	    const_Vector<T, Block1> in,
+ 	    Vector<T, Block2>       out)
+     VSIP_NOTHROW;
+ 
+   template <typename Block0,
+ 	    typename Block1,
+ 	    typename Block2>
+   void
+   impl_correlate(bias_type               bias,
+ 	    const_Matrix<T, Block0> ref,
+ 	    const_Matrix<T, Block1> in,
+ 	    Matrix<T, Block2>       out)
+     VSIP_NOTHROW;
+ 
+   typedef vsip::impl::Layout<1, row1_type, vsip::impl::Stride_unit, vsip::impl::Cmplx_inter_fmt> layout_type;
+   typedef Vector<T> coeff_view_type;
+   typedef impl::Ext_data<typename coeff_view_type::block_type, layout_type> c_ext_type;
+ 
+   // Member data.
+ private:
+   Domain<dim>     ref_size_;
+   Domain<dim>     input_size_;
+   Domain<dim>     output_size_;
+ 
+   length_type	  n_fft_;	// length of fft to overlap
+   length_type	  N2_;		// legnth of zero-pad in overlap
+   length_type	  N1_;		// length of real-data in overlap
+ 
+   Fft<const_Vector, T, complex_type,
+       Type_equal<T, complex_type>::value ? fft_fwd : 0, by_reference>
+ 		f_fft_;
+ 
+   Fft<const_Vector, complex_type, T,
+       Type_equal<T, complex_type>::value ? fft_inv : 0, by_reference>
+ 		i_fft_;
+ 
+   length_type	  fft_fd_size_;
+ 
+   Vector<T>            t_in_;	// temporary input - time domain
+   Vector<T>            t_ref_;	// temporary ref   - time domain
+   Vector<complex_type> f_in_;	// temporary input - freq domain
+   Vector<complex_type> f_ref_;	// temporary ref   - freq domain
+ 
+   int             pm_non_opt_calls_;
+   size_t          pm_ref_ext_cost_;
+   size_t          pm_in_ext_cost_;
+   size_t          pm_out_ext_cost_;
+ };
+ 
+ 
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ /// Construct a correlation object.
+ 
+ template <template <typename, typename> class ConstViewT,
+ 	  support_region_type                 Supp,
+ 	  typename                            T,
+ 	  unsigned                            n_times,
+           alg_hint_type                       a_hint>
+ Correlation_impl<ConstViewT, Supp, T, n_times, a_hint, Opt_tag>::
+ Correlation_impl(
+   Domain<dim> const&   ref_size,
+   Domain<dim> const&   input_size)
+ VSIP_THROW((std::bad_alloc))
+   : ref_size_   (normalize(ref_size)),
+     input_size_ (normalize(input_size)),
+     output_size_(conv_output_size(Supp, ref_size_, input_size_, 1)),
+ 
+     n_fft_      (choose_fft_size(ref_size_.size(), input_size_.size())),
+     N2_         (ref_size_.size()),
+     N1_	        (n_fft_-N2_),
+ 
+     f_fft_      (n_fft_, 1.0),
+     i_fft_      (n_fft_, 1.0/n_fft_),
+     fft_fd_size_(f_fft_.output_size().size()),
+     t_in_       (n_fft_),
+     t_ref_      (n_fft_),
+     f_in_       (fft_fd_size_),
+     f_ref_      (fft_fd_size_),
+ 
+     pm_non_opt_calls_ (0)
+ {
+ }
+ 
+ 
+ 
+ /// Destroy a generic Correlation_impl object.
+ 
+ template <template <typename, typename> class ConstViewT,
+ 	  support_region_type                 Supp,
+ 	  typename                            T,
+ 	  unsigned                            n_times,
+           alg_hint_type                       a_hint>
+ Correlation_impl<ConstViewT, Supp, T, n_times, a_hint, Opt_tag>::
+ ~Correlation_impl()
+   VSIP_NOTHROW
+ {}
+ 
+ 
+ 
+ // Perform 1-D convolution.
+ 
+ template <template <typename, typename> class ConstViewT,
+ 	  support_region_type Supp,
+ 	  typename            T,
+ 	  unsigned            n_times,
+           alg_hint_type       a_hint>
+ template <typename Block0,
+ 	  typename Block1,
+ 	  typename Block2>
+ void
+ Correlation_impl<ConstViewT, Supp, T, n_times, a_hint, Opt_tag>::
+ impl_correlate(
+   bias_type               bias,
+   const_Vector<T, Block0> ref,
+   const_Vector<T, Block1> in,
+   Vector<T, Block2>       out)
+ VSIP_NOTHROW
+ {
+   length_type const M = this->ref_size_[0].size();
+   length_type const N = this->input_size_[0].size();
+   length_type const P = this->output_size_[0].size();
+ 
+   assert(M == ref.size());
+   assert(N == in.size());
+   assert(P == out.size());
+ 
+ 
+   // Transform the reference
+   t_ref_(Domain<1>(0, 1, M))      = ref;
+   t_ref_(Domain<1>(M, 1, n_fft_-M)) = T();
+   f_fft_(t_ref_, f_ref_);
+ 
+ 
+   // Determine how much to "shift" the output vector.
+   length_type shift;
+ 
+   if (Supp == support_full)
+     shift = N2_-(M-1);
+   else if (Supp == support_same)
+     shift = N2_-(M/2);
+   else
+     shift = N2_-0;
+ 
+   
+   // Perform correlation using overlap and add
+ 
+   for (index_type i=0; i*N1_ < N; ++i)
+   {
+     // Copy input
+     if (N1_ > N - i*N1_)
+     {
+       length_type n_copy = N - i*N1_;
+       t_in_(Domain<1>(0,  1, N2_))     = T();
+       t_in_(Domain<1>(N2_, 1, n_copy)) = in(Domain<1>(i*N1_, 1, n_copy));
+       t_in_(Domain<1>(N2_+n_copy, 1, N1_-n_copy)) = T();
+     }
+     else
+     {
+       t_in_(Domain<1>(0,  1, N2_))  = T();
+       t_in_(Domain<1>(N2_, 1, N1_)) = in(Domain<1>(i*N1_, 1, N1_));
+     }
+ 
+     // Perform correlation
+     f_fft_(t_in_,  f_in_);
+ 
+     f_in_ = f_in_ * impl_conj(f_ref_);
+     i_fft_(f_in_, t_in_);
+     t_in_ = impl_conj(t_in_);
+ 
+     // Copy output (with overlap-add)
+     if (i == 0)
+     {
+       length_type len = std::min(N1_+N2_-shift, P);
+       out(Domain<1>(0, 1, len)) = t_in_(Domain<1>(shift, 1, len));
+     }
+     else if (i*N1_+N1_+N2_-shift < P)
+     {
+       out(Domain<1>(i*N1_-shift,     1, N2_)) += t_in_(Domain<1>(0,   1, N2_));
+       out(Domain<1>(i*N1_+N2_-shift, 1, N1_))  = t_in_(Domain<1>(N2_, 1, N1_));
+     }
+     else
+     {
+       length_type len1 = std::min(P - (i*N1_-shift), N2_);
+       if (len1 > 0)
+ 	out(Domain<1>(i*N1_-shift, 1, len1)) += t_in_(Domain<1>(0, 1, len1));
+ 
+       length_type len2 = std::min(P - (i*N1_+N2_-shift), N1_);
+       if (len2 > 0)
+ 	out(Domain<1>(i*N1_+N2_-shift, 1, len2)) =
+ 	  t_in_(Domain<1>(N2_, 1, len2));
+     }
+   }
+ 
+ 
+   // Unbias the result (if requested).
+ 
+   if (bias == unbiased)
+   {
+     if (Supp == support_full)
+     {
+       if (M > 1)
+       {
+ 	out(Domain<1>(0, 1, M-1))     /= ramp(T(1), T(1), M-1);
+ 	out(Domain<1>(P-M+1, 1, M-1)) /= ramp(T(M-1), T(-1), M-1);
+       }
+       out(Domain<1>(M-1, 1, P-2*M+2)) /= T(M);
+     }
+     else if (Supp == support_same)
+     {
+       length_type edge  = M - (M/2);
+ 
+       if (edge > 0)
+       {
+ 	out(Domain<1>(0, 1, edge))      /= ramp(T(M/2 + (M%2)), T(1), edge);
+ 	out(Domain<1>(P-edge, 1, edge)) /= ramp(T(M), T(-1), edge);
+       }
+       out(Domain<1>(edge, 1, P - 2*edge)) /= T(M);
+     }
+     else // (Supp == support_min)
+     {
+       out /= T(M);
+     }
+   }
+ }
+ 
+ 
+ 
+ // Perform 2-D convolution.
+ 
+ template <template <typename, typename> class ConstViewT,
+ 	  support_region_type                 Supp,
+ 	  typename                            T,
+ 	  unsigned                            n_times,
+           alg_hint_type                       a_hint>
+ template <typename Block0,
+ 	  typename Block1,
+ 	  typename Block2>
+ void
+ Correlation_impl<ConstViewT, Supp, T, n_times, a_hint, Opt_tag>::
+ impl_correlate(
+   bias_type               bias,
+   const_Matrix<T, Block0> ref,
+   const_Matrix<T, Block1> in,
+   Matrix<T, Block2>       out)
+ VSIP_NOTHROW
+ {
+   VSIP_IMPL_THROW(vsip::impl::unimplemented(
+     "Correlation_impl<Opt_tag>: 2D correlation not implemented."));
+ }
+ 
+ } // namespace vsip::impl
+ 
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_SIGNAL_CORR_OPT_HPP
Index: src/vsip/impl/signal-corr.hpp
===================================================================
RCS file: src/vsip/impl/signal-corr.hpp
diff -N src/vsip/impl/signal-corr.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/signal-corr.hpp	6 Oct 2005 20:30:54 -0000
***************
*** 0 ****
--- 1,143 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/signal-corr.hpp
+     @author  Jules Bergmann
+     @date    2005-10-05
+     @brief   VSIPL++ Library: Correlation class [signal.correl].
+ */
+ 
+ #ifndef VSIP_IMPL_SIGNAL_CORR_HPP
+ #define VSIP_IMPL_SIGNAL_CORR_HPP
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/domain.hpp>
+ #include <vsip/vector.hpp>
+ #include <vsip/matrix.hpp>
+ #include <vsip/impl/signal-types.hpp>
+ #include <vsip/impl/profile.hpp>
+ #include <vsip/impl/signal-corr-common.hpp>
+ #include <vsip/impl/signal-corr-ext.hpp>
+ #include <vsip/impl/signal-corr-opt.hpp>
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
+ template <typename T>
+ struct Choose_corr_impl
+ {
+   typedef typename
+   ITE_Type<Is_corr_impl_avail<Opt_tag, T>::value,
+ 	   As_type<Opt_tag>, As_type<Generic_tag> >::type type;
+ };
+ 
+ } // namespace impl
+ 
+ 
+ 
+ /// Correlation class
+ 
+ template <template <typename, typename> class ConstViewT,
+ 	  support_region_type                 Supp,
+ 	  typename                            T = VSIP_DEFAULT_VALUE_TYPE,
+ 	  unsigned                            N_times = 0,
+           alg_hint_type                       A_hint = alg_time>
+ class Correlation
+   : public impl::Correlation_impl<ConstViewT, Supp, T, N_times, A_hint,
+ 				  typename impl::Choose_corr_impl<T>::type>
+ {
+   typedef impl::Correlation_impl<ConstViewT, Supp, T, N_times, A_hint,
+ 				 typename impl::Choose_corr_impl<T>::type>
+ 		base_type;
+ 
+   // Implementation compile-time constants.
+ private:
+   static dimension_type const dim = impl::Dim_of_view<ConstViewT>::dim;
+ 
+   // Constructors, copies, assignments, and destructors.
+ public:
+   Correlation(Domain<dim> const&   ref_size,
+ 	      Domain<dim> const&   input_size)
+     VSIP_THROW((std::bad_alloc))
+       : base_type(ref_size, input_size)
+   {}
+ 
+   Correlation(Correlation const& corr) VSIP_NOTHROW;
+   Correlation& operator=(Correlation const&) VSIP_NOTHROW;
+   ~Correlation() VSIP_NOTHROW {}
+ 
+ 
+   // Accessors
+ public:
+   support_region_type support() const VSIP_NOTHROW     { return Supp; }
+ 
+ 
+   // Correlation operators.
+ public:
+   template <typename Block0,
+ 	    typename Block1,
+ 	    typename Block2>
+   Vector<T, Block2>
+   operator()(
+     bias_type               bias,
+     const_Vector<T, Block0> ref,
+     const_Vector<T, Block1> in,
+     Vector<T, Block2>       out)
+     VSIP_NOTHROW
+   {
+     impl::profile::Scope_timer t(timer_);
+ 
+     for (dimension_type d=0; d<dim; ++d)
+     {
+       assert(ref.size(d) == this->reference_size()[d].size());
+       assert(in.size(d)  == this->input_size()[d].size());
+       assert(out.size(d) == this->output_size()[d].size());
+     }
+ 
+     impl_correlate(bias, ref, in, out);
+ 
+     return out;
+   }
+ 
+   float impl_performance(char* what) const
+   {
+     if (!strcmp(what, "mflops"))
+     {
+       int count = timer_.count();
+       length_type const M = this->kernel_size()[0].size();
+       length_type const P = this->output_size()[0].size();
+       float ops = 2.f * count * P * M;
+       return ops / (1e6*timer_.total());
+     }
+     else if (!strcmp(what, "count"))
+     {
+       return timer_.count();
+     }
+     else if (!strcmp(what, "time"))
+     {
+       return timer_.total();
+     }
+     else
+       return base_type::impl_performance(what);
+   }
+ 
+   // Member data.
+ private:
+   vsip::impl::profile::Acc_timer timer_;
+ };
+ 
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_SIGNAL_CORR_HPP
Index: src/vsip/impl/signal-types.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-types.hpp,v
retrieving revision 1.5
diff -c -p -r1.5 signal-types.hpp
*** src/vsip/impl/signal-types.hpp	7 Sep 2005 12:19:31 -0000	1.5
--- src/vsip/impl/signal-types.hpp	6 Oct 2005 20:30:54 -0000
*************** enum symmetry_type
*** 38,43 ****
--- 38,49 ----
    sym_even_len_even
  };
  
+ enum bias_type
+ {
+   biased,
+   unbiased
+ };
+ 
  
  } // namespace vsip
  
Index: tests/correlation.cpp
===================================================================
RCS file: tests/correlation.cpp
diff -N tests/correlation.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/correlation.cpp	6 Oct 2005 20:30:54 -0000
***************
*** 0 ****
--- 1,417 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    correlation.cpp
+     @author  Jules Bergmann
+     @date    2005-10-05
+     @brief   VSIPL++ Library: Unit tests for [signal.correl] items.
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <cassert>
+ 
+ #include <vsip/vector.hpp>
+ #include <vsip/signal.hpp>
+ #include <vsip/random.hpp>
+ #include <vsip/selgen.hpp>
+ 
+ #include "test.hpp"
+ 
+ #define VERBOSE 0
+ 
+ #if VERBOSE
+ #  include <iostream>
+ #  include "output.hpp"
+ #endif
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
+ template <typename T1,
+ 	  typename T2,
+ 	  typename Block1,
+ 	  typename Block2>
+ double
+ error_db(
+   const_Vector<T1, Block1> v1,
+   const_Vector<T2, Block2> v2)
+ {
+   double refmax = 0.0;
+   double maxsum = -250;
+   double sum;
+ 
+   Index<1> idx;
+ 
+   refmax = maxval(magsq(v1), idx);
+ 
+   for (index_type i=0; i<v1.size(); ++i)
+   {
+     double val = magsq(v1.get(i) - v2.get(i));
+ 
+     if (val < 1.e-20)
+       sum = -201.;
+     else
+       sum = 10.0 * log10(val/(2.0*refmax));
+ 
+     if (sum > maxsum)
+       maxsum = sum;
+   }
+ 
+   return maxsum;
+ }
+ 
+ 
+ 
+ length_type expected_output_size(
+   support_region_type supp,
+   length_type         M,    // kernel length
+   length_type         N)    // input  length
+ {
+   if      (supp == support_full)
+     return (N + M - 1);
+   else if (supp == support_same)
+     return N;
+   else //(supp == support_min)
+     return (N - M + 1);
+ }
+ 
+ 
+ 
+ stride_type
+ expected_shift(
+   support_region_type supp,
+   length_type         M)     // kernel length
+ {
+   if      (supp == support_full)
+     return -(M-1);
+   else if (supp == support_same)
+     return -(M/2);
+   else //(supp == support_min)
+     return 0;
+ }
+ 
+ 
+ template <typename T,
+ 	  typename Block1,
+ 	  typename Block2,
+ 	  typename Block3>
+ void
+ ref_correlation(
+   bias_type               bias,
+   support_region_type     sup,
+   const_Vector<T, Block1> ref,
+   const_Vector<T, Block2> in,
+   Vector<T, Block3>       out)
+ {
+   typedef typename impl::Scalar_of<T>::type scalar_type;
+ 
+   length_type M = ref.size(0);
+   length_type N = in.size(0);
+   length_type P = out.size(0);
+ 
+   length_type expected_P = expected_output_size(sup, M, N);
+   stride_type shift      = expected_shift(sup, M);
+ 
+   assert(expected_P == P);
+ 
+   Vector<T> sub(M);
+ 
+   // compute correlation
+   for (index_type i=0; i<P; ++i)
+   {
+     sub = T();
+     stride_type pos = static_cast<stride_type>(i) + shift;
+     scalar_type scale;
+ 
+     if (pos < 0)
+     {
+       sub(Domain<1>(-pos, 1, M + pos)) = in(Domain<1>(0, 1, M+pos));
+       scale = scalar_type(M + pos);
+     }
+     else if (pos + M > N)
+     {
+       sub(Domain<1>(0, 1, N-pos)) = in(Domain<1>(pos, 1, N-pos));
+       scale = scalar_type(N - pos);
+     }
+     else
+     {
+       sub = in(Domain<1>(pos, 1, M));
+       scale = scalar_type(M);
+     }
+       
+     T val = dot(ref, impl_conj(sub));
+     if (bias == unbiased)
+       val /= scale;
+ 
+     out(i) = val;
+   }
+ }
+ 
+ 
+ 
+ /// Test general 1-D correlation.
+ 
+ template <typename            T,
+ 	  support_region_type support>
+ void
+ test_corr(
+   bias_type                bias,
+   length_type              M,		// reference size
+   length_type              N,		// input size
+   length_type const        n_loop = 3)
+ {
+   typedef typename impl::Scalar_of<T>::type scalar_type;
+   typedef Correlation<const_Vector, support, T> corr_type;
+ 
+   length_type const P = expected_output_size(support, M, N);
+ 
+   corr_type corr((Domain<1>(M)), Domain<1>(N));
+ 
+   assert(corr.support()  == support);
+ 
+   assert(corr.reference_size().size() == M);
+   assert(corr.input_size().size()     == N);
+   assert(corr.output_size().size()    == P);
+ 
+   Rand<T> rand(0);
+ 
+   Vector<T> ref(M);
+   Vector<T> in(N);
+   Vector<T> out(P, T(100));
+   Vector<T> chk(P, T(101));
+ 
+   for (index_type loop=0; loop<n_loop; ++loop)
+   {
+     if (loop == 0)
+     {
+       ref = T(1);
+       in  = ramp(T(0), T(1), N);
+     }
+     else if (loop == 1)
+     {
+       ref = rand.randu(M);
+       in  = ramp(T(0), T(1), N);
+     }
+     else
+     {
+       ref = rand.randu(M);
+       in  = rand.randu(N);
+     }
+ 
+     corr(bias, ref, in, out);
+ 
+     ref_correlation(bias, support, ref, in, chk);
+ 
+     double error = error_db(out, chk);
+ 
+ #if VERBOSE
+     if (error > -120)
+     {
+       for (index_type i=0; i<P; ++i)
+       {
+ 	cout << i << ":  out = " << out(i)
+ 	     << "  chk = " << chk(i)
+ 	     << endl;
+       }
+       cout << "error = " << error << endl;
+     }
+ #endif
+ 
+     assert(error < -100);
+   }
+ }
+ 
+ 
+ 
+ /// Test general 1-D correlation.
+ 
+ template <typename            Tag,
+ 	  typename            T,
+ 	  support_region_type support>
+ void
+ test_impl_corr(
+   bias_type                bias,
+   length_type              M,		// reference size
+   length_type              N,		// input size
+   length_type const        n_loop = 3)
+ {
+   typedef typename impl::Scalar_of<T>::type scalar_type;
+   typedef impl::Correlation_impl<const_Vector, support, T, 0, alg_time, Tag>
+ 		corr_type;
+ 
+   length_type const P = expected_output_size(support, M, N);
+ 
+   corr_type corr((Domain<1>(M)), Domain<1>(N));
+ 
+   // Correlation_impl doesn't define support():
+   // assert(corr.support()  == support);
+ 
+   assert(corr.reference_size().size() == M);
+   assert(corr.input_size().size()     == N);
+   assert(corr.output_size().size()    == P);
+ 
+   Rand<T> rand(0);
+ 
+   Vector<T> ref(M);
+   Vector<T> in(N);
+   Vector<T> out(P, T(100));
+   Vector<T> chk(P, T(101));
+ 
+   for (index_type loop=0; loop<n_loop; ++loop)
+   {
+     if (loop == 0)
+     {
+       ref = T(1);
+       in  = ramp(T(0), T(1), N);
+     }
+     else if (loop == 1)
+     {
+       ref = rand.randu(M);
+       in  = ramp(T(0), T(1), N);
+     }
+     else
+     {
+       ref = rand.randu(M);
+       in  = rand.randu(N);
+     }
+ 
+     corr.impl_correlate(bias, ref, in, out);
+ 
+     ref_correlation(bias, support, ref, in, chk);
+ 
+     double error = error_db(out, chk);
+ 
+ #if VERBOSE
+     if (error > -120)
+     {
+       for (index_type i=0; i<P; ++i)
+       {
+ 	cout << i << ":  out = " << out(i)
+ 	     << "  chk = " << chk(i)
+ 	     << endl;
+       }
+       cout << "error = " << error << endl;
+     }
+ #endif
+ 
+     assert(error < -100);
+   }
+ }
+ 
+ 
+ 
+ template <typename T>
+ void
+ corr_cases(length_type M, length_type N)
+ {
+   test_corr<T, support_min>(biased,   M, N);
+   test_corr<T, support_min>(unbiased, M, N);
+ 
+   test_corr<T, support_same>(biased,   M, N);
+   test_corr<T, support_same>(unbiased, M, N);
+ 
+   test_corr<T, support_full>(biased,   M, N);
+   test_corr<T, support_full>(unbiased, M, N);
+ }
+ 
+ 
+ template <typename T>
+ void
+ corr_cover()
+ {
+   corr_cases<T>(8, 8);
+ 
+   corr_cases<T>(1, 128);
+   corr_cases<T>(7, 128);
+   corr_cases<T>(8, 128);
+   corr_cases<T>(9, 128);
+ 
+   corr_cases<T>(7, 127);
+   corr_cases<T>(8, 127);
+   corr_cases<T>(9, 127);
+ 
+   corr_cases<T>(7, 129);
+   corr_cases<T>(8, 129);
+   corr_cases<T>(9, 129);
+ }
+ 
+ 
+ 
+ template <typename Tag,
+ 	  typename T>
+ void
+ impl_corr_cases(length_type M, length_type N)
+ {
+   test_impl_corr<Tag, T, support_min>(biased,   M, N);
+   test_impl_corr<Tag, T, support_min>(unbiased, M, N);
+ 
+   test_impl_corr<Tag, T, support_same>(biased,   M, N);
+   test_impl_corr<Tag, T, support_same>(unbiased, M, N);
+ 
+   test_impl_corr<Tag, T, support_full>(biased,   M, N);
+   test_impl_corr<Tag, T, support_full>(unbiased, M, N);
+ }
+ 
+ 
+ 
+ template <typename Tag,
+ 	  typename T>
+ void
+ impl_corr_cover()
+ {
+   impl_corr_cases<Tag, T>(8, 8);
+ 
+   impl_corr_cases<Tag, T>(1, 128);
+   impl_corr_cases<Tag, T>(7, 128);
+   impl_corr_cases<Tag, T>(8, 128);
+   impl_corr_cases<Tag, T>(9, 128);
+ 
+   impl_corr_cases<Tag, T>(32, 128);
+   impl_corr_cases<Tag, T>(64, 128);
+   impl_corr_cases<Tag, T>(96, 128);
+ 
+   impl_corr_cases<Tag, T>(7, 127);
+   impl_corr_cases<Tag, T>(8, 127);
+   impl_corr_cases<Tag, T>(9, 127);
+ 
+   impl_corr_cases<Tag, T>(7, 129);
+   impl_corr_cases<Tag, T>(8, 129);
+   impl_corr_cases<Tag, T>(9, 129);
+ 
+   impl_corr_cases<Tag, T>(12, 96);
+   impl_corr_cases<Tag, T>(12, 97);
+   impl_corr_cases<Tag, T>(11, 97);
+   impl_corr_cases<Tag, T>(12, 98);
+ }
+ 
+ 
+ 
+ int
+ main()
+ {
+   // Test user-visible correlation
+   corr_cover<float>();
+   corr_cover<complex<float> >();
+   corr_cover<double>();
+   corr_cover<complex<double> >();
+ 
+   // Test optimized implementation
+   impl_corr_cover<impl::Opt_tag, float>();
+   impl_corr_cover<impl::Opt_tag, complex<float> >();
+   impl_corr_cover<impl::Opt_tag, double>();
+   impl_corr_cover<impl::Opt_tag, complex<double> >();
+ 
+   // Test generic implementation
+   impl_corr_cover<impl::Generic_tag, float>();
+   impl_corr_cover<impl::Generic_tag, complex<float> >();
+   impl_corr_cover<impl::Generic_tag, double>();
+   impl_corr_cover<impl::Generic_tag, complex<double> >();
+ }
