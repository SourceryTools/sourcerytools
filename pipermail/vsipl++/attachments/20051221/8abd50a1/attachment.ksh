Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.346
diff -c -p -r1.346 ChangeLog
*** ChangeLog	21 Dec 2005 18:26:37 -0000	1.346
--- ChangeLog	21 Dec 2005 20:49:13 -0000
***************
*** 1,5 ****
--- 1,37 ----
  2005-12-21 Jules Bergmann  <jules@codesourcery.com>
  
+ 	* benchmarks/main.cpp: Add sanity check if library is configured
+ 	  with usable profile timer.
+ 	* benchmarks/mcopy.cpp: Add plainblock case.
+ 	* benchmarks/prod.cpp: Add plainblock case.
+ 	* benchmarks/prod_var.cpp: Renumber benchmark cases from (not 0).
+ 	* benchmarks/vmul.cpp: Add scalar*vector case.
+ 	* src/vsip/dense.hpp: Implement 2-arg and 3-arg get/put directly
+ 	  instead of abstracting through Point. 
+ 	* src/vsip/impl/dispatch-assign.hpp: Use Serial_dispatch for
+ 	  matrices.  Decompose tensor assignment to matrix when dimension
+ 	  ordering consistent.
+ 	* src/vsip/impl/expr_serial_dispatch.hpp: Add transpose tag to
+ 	  LibraryTagList.
+ 	* src/vsip/impl/expr_serial_evaluator.hpp: Add general loop-fusion
+ 	  matrix expression evaluator.  Add matrix transpose evaluator.
+ 	* src/vsip/impl/fast-transpose.hpp: New file, cache-oblivious
+ 	  transpose algorithm.
+ 	* src/vsip/impl/ipp.cpp: Add wrappers for IPP scalar-view add, sub,
+ 	  mul, div.
+ 	* src/vsip/impl/ipp.hpp: Add evaluators for IPP scalar-view add, sub
+ 	  mul, div.
+ 	* src/vsip/impl/profile.hpp: Define DefaultTime::valid to indicate
+ 	  if profile timer is enabled.
+ 	* src/vsip/impl/vmmul.hpp: Add general evaluator for vector-matrix
+ 	  multiply.  Decomposes into individual vector-vector or scalar-vector
+ 	  multiplies.
+ 	* tests/matvec-prod.cpp: Remove unnecessary include.
+ 	* tests/scalar-view.cpp: New file, coverage tests for scalar-view
+ 	  operators (+, -, *, /).
+ 
+ 2005-12-21 Jules Bergmann  <jules@codesourcery.com>
+ 
  	* configure.ac: Done build builtin FFTW3 when asked to use another
  	  FFT library than FFTW3.
  
Index: benchmarks/main.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/main.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 main.cpp
*** benchmarks/main.cpp	19 Dec 2005 16:08:55 -0000	1.4
--- benchmarks/main.cpp	21 Dec 2005 20:49:13 -0000
***************
*** 14,19 ****
--- 14,20 ----
  #include <iostream>
  
  #include <vsip/initfin.hpp>
+ #include <vsip/impl/profile.hpp>
  
  #include "test.hpp"
  #include "loop.hpp"
*************** main(int argc, char** argv)
*** 30,42 ****
  {
    vsip::vsipl init(argc, argv);
  
    Loop1P loop;
    bool   verbose = false;
  
    loop.goal_sec_ = 0.25;
    defaults(loop);
  
!   int what = 1;
  
    for (int i=1; i<argc; ++i)
    {
--- 31,52 ----
  {
    vsip::vsipl init(argc, argv);
  
+   if (!vsip::impl::profile::DefaultTime::valid)
+   {
+     std::cerr << argv[0] << ": timer "
+ 	      << vsip::impl::profile::DefaultTime::name()
+ 	      << " not valid for benchmarking"
+ 	      << std::endl;
+     exit(-1);
+   }
+ 
    Loop1P loop;
    bool   verbose = false;
  
    loop.goal_sec_ = 0.25;
    defaults(loop);
  
!   int what = 0;
  
    for (int i=1; i<argc; ++i)
    {
Index: benchmarks/mcopy.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/mcopy.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 mcopy.cpp
*** benchmarks/mcopy.cpp	5 Dec 2005 19:19:18 -0000	1.1
--- benchmarks/mcopy.cpp	21 Dec 2005 20:49:13 -0000
***************
*** 25,30 ****
--- 25,32 ----
  #include "loop.hpp"
  #include "ops_info.hpp"
  
+ #include "plainblock.hpp"
+ 
  using namespace vsip;
  
  
*************** using namespace vsip;
*** 34,44 ****
  ***********************************************************************/
  
  template <typename T,
! 	  typename SrcOrder,
! 	  typename DstOrder,
! 	  typename MapT>
  struct t_mcopy
  {
    char* what() { return "t_mcopy"; }
    int ops_per_point(length_type size)  { return size; }
    int riob_per_point(length_type size) { return size*sizeof(T); }
--- 36,48 ----
  ***********************************************************************/
  
  template <typename T,
! 	  typename SrcBlock,
! 	  typename DstBlock>
  struct t_mcopy
  {
+   typedef typename SrcBlock::map_type src_map_type;
+   typedef typename DstBlock::map_type dst_map_type;
+ 
    char* what() { return "t_mcopy"; }
    int ops_per_point(length_type size)  { return size; }
    int riob_per_point(length_type size) { return size*sizeof(T); }
*************** struct t_mcopy
*** 49,59 ****
      length_type const M = size;
      length_type const N = size;
  
-     typedef Dense<2, T, SrcOrder, MapT> src_block_t;
-     typedef Dense<2, T, DstOrder, MapT> dst_block_t;
  
!     Matrix<T, src_block_t>   A(M, N, T(), map_);
!     Matrix<T, dst_block_t>   Z(M, N,      map_);
  
      for (index_type m=0; m<M; ++m)
        for (index_type n=0; n<N; ++n)
--- 53,61 ----
      length_type const M = size;
      length_type const N = size;
  
  
!     Matrix<T, SrcBlock>   A(M, N, T(), src_map_);
!     Matrix<T, DstBlock>   Z(M, N,      dst_map_);
  
      for (index_type m=0; m<M; ++m)
        for (index_type n=0; n<N; ++n)
*************** struct t_mcopy
*** 71,77 ****
      for (index_type m=0; m<M; ++m)
        for (index_type n=0; n<N; ++n)
        {
! 	if (!equal(Z(m, n), T(m*N+n)))
  	{
  	  std::cout << "t_mcopy: ERROR" << std::endl;
  	  abort();
--- 73,79 ----
      for (index_type m=0; m<M; ++m)
        for (index_type n=0; n<N; ++n)
        {
! 	if (!equal(Z.get(m, n), T(m*N+n)))
  	{
  	  std::cout << "t_mcopy: ERROR" << std::endl;
  	  abort();
*************** struct t_mcopy
*** 81,90 ****
      time = t1.delta();
    }
  
!   t_mcopy(MapT map) : map_(map) {}
  
    // Member data.
!   MapT	map_;
  };
  
  
--- 83,96 ----
      time = t1.delta();
    }
  
!   t_mcopy(src_map_type src_map, dst_map_type dst_map)
!     : src_map_(src_map),
!       dst_map_(dst_map)
!     {}
  
    // Member data.
!   src_map_type	src_map_;
!   dst_map_type	dst_map_;
  };
  
  
*************** struct t_mcopy
*** 92,115 ****
  template <typename T,
  	  typename SrcOrder,
  	  typename DstOrder>
! struct t_mcopy_local : t_mcopy<T, SrcOrder, DstOrder, Local_map>
  {
!   typedef t_mcopy<T, SrcOrder, DstOrder, Local_map> base_type;
    t_mcopy_local()
!     : base_type(Local_map()) 
    {}
  };
  
  template <typename T,
  	  typename SrcOrder,
  	  typename DstOrder>
! struct t_mcopy_root : t_mcopy<T, SrcOrder, DstOrder, Map<> >
  {
    typedef t_mcopy<T, SrcOrder, DstOrder, Map<> > base_type;
    t_mcopy_root()
      : base_type(Map<>()) 
    {}
  };
  
  
  
--- 98,150 ----
  template <typename T,
  	  typename SrcOrder,
  	  typename DstOrder>
! struct t_mcopy_local : t_mcopy<T,
! 			       Dense<2, T, SrcOrder, Local_map>,
! 			       Dense<2, T, DstOrder, Local_map> >
  {
!   typedef t_mcopy<T,
! 		  Dense<2, T, SrcOrder, Local_map>,
! 		  Dense<2, T, DstOrder, Local_map> > base_type;
    t_mcopy_local()
!     : base_type(Local_map(), Local_map()) 
    {}
  };
  
+ 
  template <typename T,
  	  typename SrcOrder,
  	  typename DstOrder>
! struct t_mcopy_pb : t_mcopy<T,
! 			    Plain_block<2, T, SrcOrder, Local_map>,
! 			    Plain_block<2, T, DstOrder, Local_map> >
! {
!   typedef t_mcopy<T,
! 		  Plain_block<2, T, SrcOrder, Local_map>,
! 		  Plain_block<2, T, DstOrder, Local_map> > base_type;
!   t_mcopy_pb()
!     : base_type(Local_map(), Local_map()) 
!   {}
! };
! 
! #if 0
! template <typename T,
! 	  typename SrcOrder,
! 	  typename DstOrder>
! struct t_mcopy_root : t_mcopy<T,
! 			       Dense<2, T, SrcOrder, MapT>,
! 			       Dense<2, T, DstOrder, MapT>,
! 			       Local_map>
  {
    typedef t_mcopy<T, SrcOrder, DstOrder, Map<> > base_type;
+   typedef t_mcopy<T,
+ 		  Dense<2, T, SrcOrder, MapT>,
+ 		  Dense<2, T, DstOrder, MapT>,
+ 		  Map<> > base_type;
    t_mcopy_root()
      : base_type(Map<>()) 
    {}
  };
+ #endif
  
  
  
*************** test(Loop1P& loop, int what)
*** 136,141 ****
--- 171,182 ----
    case  7: loop(t_mcopy_local<complex<float>, col2_type, row2_type>()); break;
    case  8: loop(t_mcopy_local<complex<float>, col2_type, col2_type>()); break;
  
+     
+   case  20: loop(t_mcopy_pb<float, row2_type, row2_type>()); break;
+   case  21: loop(t_mcopy_pb<float, row2_type, col2_type>()); break;
+   case  22: loop(t_mcopy_pb<float, col2_type, row2_type>()); break;
+   case  23: loop(t_mcopy_pb<float, col2_type, col2_type>()); break;
+ 
    default:
      return 0;
    }
Index: benchmarks/prod.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/prod.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 prod.cpp
*** benchmarks/prod.cpp	12 Oct 2005 12:45:05 -0000	1.1
--- benchmarks/prod.cpp	21 Dec 2005 20:49:13 -0000
***************
*** 24,29 ****
--- 24,31 ----
  #include "loop.hpp"
  #include "ops_info.hpp"
  
+ #include "plainblock.hpp"
+ 
  using namespace vsip;
  
  
*************** struct t_prod2
*** 223,228 ****
--- 225,284 ----
  
  
  
+ template <typename ImplTag,
+ 	  typename T>
+ struct t_prod2pb
+ {
+   static length_type const Dec = 1;
+ 
+   char* what() { return "t_prod2"; }
+   float ops_per_point(length_type M)
+   {
+     length_type N = M;
+     length_type P = M;
+ 
+     float ops = /*M * */ P * N * (Ops_info<T>::mul + Ops_info<T>::add);
+ 
+     return ops;
+   }
+ 
+   int riob_per_point(length_type) { return 2*sizeof(T); }
+   int wiob_per_point(length_type) { return 0; }
+ 
+   void operator()(length_type M, length_type loop, float& time)
+   {
+     length_type N = M;
+     length_type P = M;
+ 
+     typedef Plain_block<2, T, row2_type> a_block_type;
+     typedef Plain_block<2, T, row2_type> b_block_type;
+     typedef Plain_block<2, T, row2_type> z_block_type;
+ 
+     Matrix<T, a_block_type>   A(M, N, T());
+     Matrix<T, b_block_type>   B(N, P, T());
+     Matrix<T, z_block_type>   Z(M, P, T());
+ 
+ 
+     typedef impl::Evaluator<impl::Op_prod_mm, z_block_type,
+                             impl::Op_list_2<a_block_type, a_block_type>,
+ 			    ImplTag>
+ 		Eval;
+ 
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       Eval::exec(Z.block(), A.block(), B.block());
+     t1.stop();
+     
+     time = t1.delta();
+   }
+ 
+   t_prod2pb() {}
+ };
+ 
+ 
+ 
  void
  defaults(Loop1P& loop)
  {
*************** test(Loop1P& loop, int what)
*** 253,258 ****
--- 309,318 ----
    case  12: loop(t_prodt1<complex<float> >()); break;
    case  13: loop(t_prodh1<complex<float> >()); break;
  
+     
+   case  103: loop(t_prod2pb<impl::Generic_tag, float>()); break;
+   case  104: loop(t_prod2pb<impl::Generic_tag, complex<float> >()); break;
+ 
    default: return 0;
    }
    return 1;
Index: benchmarks/prod_var.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/prod_var.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 prod_var.cpp
*** benchmarks/prod_var.cpp	5 Dec 2005 19:19:18 -0000	1.1
--- benchmarks/prod_var.cpp	21 Dec 2005 20:49:13 -0000
*************** template <typename T,
*** 50,56 ****
  	  typename Block3>
  void
  prod(
!   Int_type<0>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
--- 50,56 ----
  	  typename Block3>
  void
  prod(
!   Int_type<1>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
*************** template <typename T,
*** 65,71 ****
  	  typename Block3>
  void
  prod(
!   Int_type<1>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
--- 65,71 ----
  	  typename Block3>
  void
  prod(
!   Int_type<2>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
*************** template <typename T,
*** 84,90 ****
  	  typename Block3>
  void
  prod(
!   Int_type<2>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
--- 84,90 ----
  	  typename Block3>
  void
  prod(
!   Int_type<3>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
*************** template <typename T,
*** 106,112 ****
  	  typename Block3>
  void
  prod(
!   Int_type<3>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
--- 106,112 ----
  	  typename Block3>
  void
  prod(
!   Int_type<4>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
*************** template <typename T,
*** 129,135 ****
  	  typename Block3>
  void
  prod(
!   Int_type<4>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
--- 129,135 ----
  	  typename Block3>
  void
  prod(
!   Int_type<5>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
*************** template <typename T,
*** 155,161 ****
  	  typename Block3>
  void
  prod(
!   Int_type<5>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
--- 155,161 ----
  	  typename Block3>
  void
  prod(
!   Int_type<6>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
*************** template <typename T,
*** 181,187 ****
  	  typename Block3>
  void
  prod(
!   Int_type<6>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
--- 181,187 ----
  	  typename Block3>
  void
  prod(
!   Int_type<7>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
*************** template <typename T,
*** 206,212 ****
  	  typename Block3>
  void
  prod(
!   Int_type<7>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
--- 206,212 ----
  	  typename Block3>
  void
  prod(
!   Int_type<8>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
*************** template <typename T,
*** 231,237 ****
  	  typename Block3>
  void
  prod(
!   Int_type<8>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
--- 231,237 ----
  	  typename Block3>
  void
  prod(
!   Int_type<9>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
*************** template <typename T,
*** 259,265 ****
  	  typename Block3>
  void
  prod(
!   Int_type<9>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
--- 259,265 ----
  	  typename Block3>
  void
  prod(
!   Int_type<10>,
    Matrix<T, Block1> A,
    Matrix<T, Block2> B,
    Matrix<T, Block3> C)
*************** check_prod(
*** 309,315 ****
    }
  #endif
  
!   assert(err < 10.0);
  }
  
  // Matrix-matrix product benchmark class.
--- 309,315 ----
    }
  #endif
  
!   test_assert(err < 10.0);
  }
  
  // Matrix-matrix product benchmark class.
*************** test(Loop1P& loop, int what)
*** 391,417 ****
  
    switch (what)
    {
!   case  0: loop(t_prod1<0, float>()); break;
!   case  1: loop(t_prod1<1, float>()); break;
!   case  2: loop(t_prod1<2, float>()); break;
!   case  3: loop(t_prod1<3, float>()); break;
!   case  4: loop(t_prod1<4, float>()); break;
!   case  5: loop(t_prod1<5, float>()); break;
!   case  6: loop(t_prod1<6, float>()); break;
!   case  7: loop(t_prod1<7, float>()); break;
!   case  8: loop(t_prod1<8, float>()); break;
!   case  9: loop(t_prod1<9, float>()); break;
! 
!   case  10: loop(t_prod1<0, complex<float> >()); break;
!   case  11: loop(t_prod1<1, complex<float> >()); break;
!   case  12: loop(t_prod1<2, complex<float> >()); break;
!   case  13: loop(t_prod1<3, complex<float> >()); break;
!   case  14: loop(t_prod1<4, complex<float> >()); break;
!   case  15: loop(t_prod1<5, complex<float> >()); break;
!   case  16: loop(t_prod1<6, complex<float> >()); break;
!   case  17: loop(t_prod1<7, complex<float> >()); break;
!   case  18: loop(t_prod1<8, complex<float> >()); break;
!   case  19: loop(t_prod1<9, complex<float> >()); break;
  
    default: return 0;
    }
--- 391,417 ----
  
    switch (what)
    {
!   case  1: loop(t_prod1< 1, float>()); break;
!   case  2: loop(t_prod1< 2, float>()); break;
!   case  3: loop(t_prod1< 3, float>()); break;
!   case  4: loop(t_prod1< 4, float>()); break;
!   case  5: loop(t_prod1< 5, float>()); break;
!   case  6: loop(t_prod1< 6, float>()); break;
!   case  7: loop(t_prod1< 7, float>()); break;
!   case  8: loop(t_prod1< 8, float>()); break;
!   case  9: loop(t_prod1< 9, float>()); break;
!   case 10: loop(t_prod1<10, float>()); break;
! 
!   case 11: loop(t_prod1< 1, complex<float> >()); break;
!   case 12: loop(t_prod1< 2, complex<float> >()); break;
!   case 13: loop(t_prod1< 3, complex<float> >()); break;
!   case 14: loop(t_prod1< 4, complex<float> >()); break;
!   case 15: loop(t_prod1< 5, complex<float> >()); break;
!   case 16: loop(t_prod1< 6, complex<float> >()); break;
!   case 17: loop(t_prod1< 7, complex<float> >()); break;
!   case 18: loop(t_prod1< 8, complex<float> >()); break;
!   case 19: loop(t_prod1< 9, complex<float> >()); break;
!   case 20: loop(t_prod1<10, complex<float> >()); break;
  
    default: return 0;
    }
Index: benchmarks/vmul.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/vmul.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 vmul.cpp
*** benchmarks/vmul.cpp	7 Sep 2005 12:19:30 -0000	1.4
--- benchmarks/vmul.cpp	21 Dec 2005 20:49:13 -0000
*************** struct t_vmul1
*** 62,67 ****
--- 62,135 ----
  
  
  
+ // Benchmark scalar-view vector multiply (Scalar * View)
+ 
+ template <typename T>
+ struct t_svmul1
+ {
+   char* what() { return "t_svmul1"; }
+   int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+   int riob_per_point(length_type) { return 1*sizeof(T); }
+   int wiob_per_point(length_type) { return 1*sizeof(T); }
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+     Vector<T>   A(size, T());
+     Vector<T>   C(size);
+ 
+     T alpha = T(3);
+ 
+     A(0) = T(4);
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       C = alpha * A;
+     t1.stop();
+     
+     test_assert(equal(C(0), T(12)));
+     
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
+ // Benchmark scalar-view vector multiply (Scalar * View)
+ 
+ template <typename T>
+ struct t_svmul2
+ {
+   char* what() { return "t_svmul2"; }
+   int ops_per_point(length_type)  { return Ops_info<T>::mul; }
+   int riob_per_point(length_type) { return 1*sizeof(T); }
+   int wiob_per_point(length_type) { return 1*sizeof(T); }
+ 
+   void operator()(length_type size, length_type loop, float& time)
+   {
+     Vector<T>   A(size, T());
+     Vector<T>   C(size);
+ 
+     T alpha = T(3);
+ 
+     A(0) = T(4);
+     
+     vsip::impl::profile::Timer t1;
+     
+     t1.start();
+     for (index_type l=0; l<loop; ++l)
+       C = A * alpha;
+     t1.stop();
+ 
+     test_assert(equal(C(0), T(12)));
+     
+     time = t1.delta();
+   }
+ };
+ 
+ 
+ 
  void
  defaults(Loop1P&)
  {
*************** test(Loop1P& loop, int what)
*** 76,81 ****
--- 144,154 ----
    {
    case  1: loop(t_vmul1<float>()); break;
    case  2: loop(t_vmul1<complex<float> >()); break;
+ 
+   case 11: loop(t_svmul1<float>()); break;
+   case 12: loop(t_svmul1<complex<float> >()); break;
+   case 13: loop(t_svmul2<float>()); break;
+   case 14: loop(t_svmul2<complex<float> >()); break;
    default:
      return 0;
    }
Index: src/vsip/dense.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/dense.hpp,v
retrieving revision 1.30
diff -c -p -r1.30 dense.hpp
*** src/vsip/dense.hpp	5 Dec 2005 19:19:18 -0000	1.30
--- src/vsip/dense.hpp	21 Dec 2005 20:49:14 -0000
*************** protected:
*** 525,530 ****
--- 525,544 ----
    T    get(Point<Dim> const& idx) const VSIP_NOTHROW;
    void put(Point<Dim> const& idx, T val) VSIP_NOTHROW;
  
+   // 2-diminsional get/put
+   T    impl_get(index_type idx0, index_type idx1) const VSIP_NOTHROW
+     { return this->get(layout_.index(idx0, idx1)); }
+   void impl_put(index_type idx0, index_type idx1, T val) VSIP_NOTHROW
+     { this->put(layout_.index(idx0, idx1), val); }
+ 
+   // 3-diminsional get/put
+   T    impl_get(index_type idx0, index_type idx1, index_type idx2)
+     const VSIP_NOTHROW
+     { return this->get(layout_.index(idx0, idx1, idx2)); }
+   void impl_put(index_type idx0, index_type idx1, index_type idx2, T val)
+     VSIP_NOTHROW
+     { this->put(layout_.index(idx0, idx1, idx2), val); }
+ 
  public:
    using storage_type::impl_ref;
  
*************** public:
*** 744,753 ****
    // 2-dim Data Accessors.
  public:
    T get(index_type idx0, index_type idx1) const VSIP_NOTHROW
!     { return base_type::get(impl::Point<2>(idx0, idx1)); }
  
    void put(index_type idx0, index_type idx1, T val) VSIP_NOTHROW
!     { base_type::put(impl::Point<2>(idx0, idx1), val); }
  
    reference_type impl_ref(index_type idx0, index_type idx1)
      VSIP_NOTHROW
--- 758,767 ----
    // 2-dim Data Accessors.
  public:
    T get(index_type idx0, index_type idx1) const VSIP_NOTHROW
!     { return base_type::impl_get(idx0, idx1); }
  
    void put(index_type idx0, index_type idx1, T val) VSIP_NOTHROW
!     { return base_type::impl_put(idx0, idx1, val); }
  
    reference_type impl_ref(index_type idx0, index_type idx1)
      VSIP_NOTHROW
*************** public:
*** 865,875 ****
  public:
    T get(index_type idx0, index_type idx1, index_type idx2)
      const VSIP_NOTHROW
!     { return base_type::get(impl::Point<3>(idx0, idx1, idx2)); }
  
    void put(index_type idx0, index_type idx1, index_type idx2, T val)
      VSIP_NOTHROW
!     { base_type::put(impl::Point<3>(idx0, idx1, idx2), val); }
  
    reference_type impl_ref(index_type idx0, index_type idx1, index_type idx2)
      VSIP_NOTHROW
--- 879,889 ----
  public:
    T get(index_type idx0, index_type idx1, index_type idx2)
      const VSIP_NOTHROW
!     { return base_type::impl_get(idx0, idx1, idx2); }
  
    void put(index_type idx0, index_type idx1, index_type idx2, T val)
      VSIP_NOTHROW
!     { base_type::impl_put(idx0, idx1, idx2, val); }
  
    reference_type impl_ref(index_type idx0, index_type idx1, index_type idx2)
      VSIP_NOTHROW
Index: src/vsip/impl/dispatch-assign.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/dispatch-assign.hpp,v
retrieving revision 1.12
diff -c -p -r1.12 dispatch-assign.hpp
*** src/vsip/impl/dispatch-assign.hpp	2 Nov 2005 18:44:03 -0000	1.12
--- src/vsip/impl/dispatch-assign.hpp	21 Dec 2005 20:49:14 -0000
*************** struct Dispatch_assign<2, Block1, Block2
*** 186,192 ****
  {
    static void exec(Block1& blk1, Block2 const& blk2)
    {
!     Dispatch_assign<2, Block1, Block2, Tag_serial_expr>::exec(blk1, blk2);
    }
  };
  
--- 186,193 ----
  {
    static void exec(Block1& blk1, Block2 const& blk2)
    {
!     Serial_dispatch_helper<2, Block1, Block2, LibraryTagList>
!       ::exec(blk1, blk2);
    }
  };
  
*************** template <typename       Block1,
*** 198,221 ****
  	  typename       Block2>
  struct Dispatch_assign<2, Block1, Block2, Tag_serial_expr>
  {
-   static void exec(Block1& blk1, Block2 const& blk2, row2_type)
-   {
-     for (index_type r=0; r<blk1.size(2, 0); ++r)
-       for (index_type c=0; c<blk1.size(2, 1); ++c)
- 	blk1.put(r, c, blk2.get(r, c));
-   }
- 
-   static void exec(Block1& blk1, Block2 const& blk2, col2_type)
-   {
-     for (index_type c=0; c<blk1.size(2, 1); ++c)
-       for (index_type r=0; r<blk1.size(2, 0); ++r)
- 	blk1.put(r, c, blk2.get(r, c));
-   }
- 
    static void exec(Block1& blk1, Block2 const& blk2)
    {
!     typedef typename Block_layout<Block1>::order_type order_type;
!     exec(blk1, blk2, order_type());
    }
  };
  
--- 199,208 ----
  	  typename       Block2>
  struct Dispatch_assign<2, Block1, Block2, Tag_serial_expr>
  {
    static void exec(Block1& blk1, Block2 const& blk2)
    {
!     Serial_dispatch_helper<2, Block1, Block2, LibraryTagList>
!       ::exec(blk1, blk2);
    }
  };
  
*************** struct Dispatch_assign<3, Block1, Block2
*** 229,236 ****
  {
    static void exec(Block1& blk1, Block2 const& blk2)
    {
!     // Forward to Tag_serial_expr
!     Dispatch_assign<3, Block1, Block2, Tag_serial_expr>::exec(blk1, blk2);
    }
  };
  
--- 216,243 ----
  {
    static void exec(Block1& blk1, Block2 const& blk2)
    {
!     typedef typename Block_layout<Block1>::order_type order1_type;
!     typedef typename Block_layout<Block2>::order_type order2_type;
! 
!     if (order1_type::impl_dim0 == order2_type::impl_dim0)
!     {
!       // If leading dimensions is same, decompose to matrix assignment.
!       dimension_type const dim = order1_type::impl_dim0;
! 
!       for (index_type i=0; i<blk1.size(3, dim); ++i)
!       {
! 	Sliced_block<Block1, dim> sub_blk1(blk1, i);
! 	Sliced_block<Block2, dim> sub_blk2(const_cast<Block2&>(blk2), i);
! 	Dispatch_assign<2, Sliced_block<Block1, dim>,
! 	                   Sliced_block<Block2, dim>,
!                            Tag_serial_assign>::exec(sub_blk1, sub_blk2);
!       }
!     }
!     else
!     {
!       // Forward to Tag_serial_expr
!       Dispatch_assign<3, Block1, Block2, Tag_serial_expr>::exec(blk1, blk2);
!     }
    }
  };
  
*************** template <dimension_type Dim,
*** 305,310 ****
--- 312,319 ----
  	  typename       Block2>
  struct Dispatch_assign<Dim, Block1, Block2, Tag_par_assign>
  {
+   typedef typename Block1::map_type map1_type;
+ 
    typedef typename View_of_dim<Dim, typename Block1::value_type,
  			     Block1>::type dst_type;
    typedef typename View_of_dim<Dim, typename Block2::value_type,
*************** struct Dispatch_assign<Dim, Block1, Bloc
*** 315,327 ****
      dst_type dst(blk1);
      src_type src(const_cast<Block2&>(blk2));
  
!     Chained_parallel_assign<Dim,
!       typename Block1::value_type,
!       typename Block2::value_type,
!       Block1,
!       Block2> pa(dst, src);
  
!     pa();
    }
  };
  
--- 324,343 ----
      dst_type dst(blk1);
      src_type src(const_cast<Block2&>(blk2));
  
!     if (Is_par_same_map<map1_type, Block2>::value(blk1.map(), blk2))
!     {
!       par_expr_simple(dst, src);
!     }
!     else
!     {
!       Chained_parallel_assign<Dim,
! 	typename Block1::value_type,
! 	typename Block2::value_type,
! 	Block1,
! 	Block2> pa(dst, src);
  
!       pa();
!     }
    }
  };
  
Index: src/vsip/impl/expr_serial_dispatch.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_serial_dispatch.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 expr_serial_dispatch.hpp
*** src/vsip/impl/expr_serial_dispatch.hpp	14 Oct 2005 14:07:45 -0000	1.2
--- src/vsip/impl/expr_serial_dispatch.hpp	21 Dec 2005 20:49:14 -0000
*************** namespace impl
*** 36,41 ****
--- 36,42 ----
  
  /// The list of evaluators to be tried, in that specific order.
  typedef Make_type_list<Intel_ipp_tag,
+ 		       Transpose_tag,
                         Mercury_sal_tag,
  		       Loop_fusion_tag>::type LibraryTagList;
  
Index: src/vsip/impl/expr_serial_evaluator.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_serial_evaluator.hpp,v
retrieving revision 1.3
diff -c -p -r1.3 expr_serial_evaluator.hpp
*** src/vsip/impl/expr_serial_evaluator.hpp	14 Oct 2005 14:07:45 -0000	1.3
--- src/vsip/impl/expr_serial_evaluator.hpp	21 Dec 2005 20:49:14 -0000
***************
*** 13,18 ****
--- 13,24 ----
    Included Files
  ***********************************************************************/
  
+ #include <vsip/impl/metaprogramming.hpp>
+ #include <vsip/impl/block-traits.hpp>
+ #include <vsip/impl/extdata.hpp>
+ #include <vsip/impl/fast-transpose.hpp>
+ 
+ 
  
  /***********************************************************************
    Declarations
*************** namespace impl
*** 26,31 ****
--- 32,38 ----
  struct Loop_fusion_tag;
  struct Intel_ipp_tag;
  struct Mercury_sal_tag;
+ struct Transpose_tag;
  
  /// Serial_expr_evaluator template.
  /// This needs to be provided for each tag in the LibraryTagList.
*************** template <dimension_type Dim,
*** 33,39 ****
  	  typename DstBlock,
  	  typename SrcBlock,
  	  typename Tag>
! struct Serial_expr_evaluator;
  
  template <typename DstBlock,
  	  typename SrcBlock>
--- 40,49 ----
  	  typename DstBlock,
  	  typename SrcBlock,
  	  typename Tag>
! struct Serial_expr_evaluator
! {
!   static bool const ct_valid = false;
! };
  
  template <typename DstBlock,
  	  typename SrcBlock>
*************** struct Serial_expr_evaluator<1, DstBlock
*** 50,55 ****
--- 60,182 ----
    }
  };
  
+ 
+ 
+ template <typename DstBlock,
+ 	  typename SrcBlock>
+ struct Serial_expr_evaluator<2, DstBlock, SrcBlock, Transpose_tag>
+ {
+   static bool const is_rhs_expr   = Is_expr_block<SrcBlock>::value;
+ 
+   static bool const is_rhs_simple =
+     Is_simple_distributed_block<SrcBlock>::value;
+ 
+   static bool const is_lhs_split  =
+     Type_equal<typename Block_layout<DstBlock>::complex_type,
+ 	       Cmplx_split_fmt>::value;
+ 
+   static bool const is_rhs_split  =
+     Type_equal<typename Block_layout<SrcBlock>::complex_type,
+ 	       Cmplx_split_fmt>::value;
+ 
+   static int const  lhs_cost      = Ext_data_cost<DstBlock>::value;
+   static int const  rhs_cost      = Ext_data_cost<SrcBlock>::value;
+ 
+   typedef typename Block_layout<SrcBlock>::order_type src_order_type;
+   typedef typename Block_layout<DstBlock>::order_type dst_order_type;
+ 
+   static bool const ct_valid =
+     !is_rhs_expr &&
+     lhs_cost == 0 && rhs_cost == 0 &&
+     !is_lhs_split && !is_rhs_split &&
+     !Type_equal<src_order_type, dst_order_type>::value;
+ 
+   static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
+   { return true; }
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src, col2_type, row2_type)
+   {
+     vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
+     vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
+ 
+     if (dst_ext.stride(0) == 1 && src_ext.stride(1) == 1)
+     {
+       transpose_unit(dst_ext.data(), src_ext.data(),
+ 		     dst.size(2, 0), dst.size(2, 1), // rows, cols
+ 		     dst_ext.stride(1),		     // dst_col_stride
+ 		     src_ext.stride(0));	     // src_row_stride
+     }
+     else
+     {
+       transpose(dst_ext.data(), src_ext.data(),
+ 		dst.size(2, 0), dst.size(2, 1),		// rows, cols
+ 		dst_ext.stride(0), dst_ext.stride(1),	// dst strides
+ 		src_ext.stride(0), src_ext.stride(1));	// srd strides
+     }
+   }
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src, row2_type, col2_type)
+   {
+     vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
+     vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
+ 
+     if (dst_ext.stride(1) == 1 && src_ext.stride(0) == 1)
+     {
+       transpose_unit(dst_ext.data(), src_ext.data(),
+ 		     dst.size(2, 1), dst.size(2, 0), // rows, cols
+ 		     dst_ext.stride(0),	  // dst_col_stride
+ 		     src_ext.stride(1));	  // src_row_stride
+     }
+     else
+     {
+       transpose(dst_ext.data(), src_ext.data(),
+ 		dst.size(2, 1), dst.size(2, 0), // rows, cols
+ 		dst_ext.stride(1), dst_ext.stride(0),	// dst strides
+ 		src_ext.stride(1), src_ext.stride(0));	// srd strides
+     }
+   }
+ 
+   static void exec(DstBlock& blk1, SrcBlock const& blk2)
+   {
+     exec(blk1, blk2, dst_order_type(), src_order_type());
+   }
+   
+ };
+ 
+ 
+ 
+ 
+ template <typename DstBlock,
+ 	  typename SrcBlock>
+ struct Serial_expr_evaluator<2, DstBlock, SrcBlock, Loop_fusion_tag>
+ {
+   static bool const ct_valid = true;
+   static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
+   { return true; }
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src, row2_type)
+   {
+     for (index_type i=0; i<dst.size(2, 0); ++i)
+       for (index_type j=0; j<dst.size(2, 1); ++j)
+ 	dst.put(i, j, src.get(i, j));
+   }
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src, col2_type)
+   {
+     for (index_type j=0; j<dst.size(2, 1); ++j)
+       for (index_type i=0; i<dst.size(2, 0); ++i)
+ 	dst.put(i, j, src.get(i, j));
+   }
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src)
+   {
+     typedef typename Block_layout<DstBlock>::order_type dst_order_type;
+     exec(dst, src, dst_order_type());
+   }
+ };
+ 
+ 
+ 
  /// A general expression evaluator for IPP that doesn't match
  /// anything and thus should be skipped by the dispatcher.
  template <typename DstBlock,
Index: src/vsip/impl/fast-transpose.hpp
===================================================================
RCS file: src/vsip/impl/fast-transpose.hpp
diff -N src/vsip/impl/fast-transpose.hpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- src/vsip/impl/fast-transpose.hpp	21 Dec 2005 20:49:14 -0000
***************
*** 0 ****
--- 1,124 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    vsip/impl/fast-transpose.hpp
+     @author  Jules Bergmann
+     @date    2005-05-10
+     @brief   VSIPL++ Library: Fast matrix tranpose algorithms.
+ 
+ */
+ 
+ #ifndef VSIP_IMPL_FAST_TRANSPOSE_HPP
+ #define VSIP_IMPL_FAST_TRANSPOSE_HPP
+ 
+ /***********************************************************************
+   Definitions
+ ***********************************************************************/
+ 
+ namespace vsip
+ {
+ 
+ namespace impl
+ {
+ 
+ // Transpose for unit-strides.
+ 
+ // Algorithm based on "Cache-Oblivious Algorithms (Extended Abstract)"
+ // by M. Frigo, C. Leiseron, H. Prokop, S. Ramachandran.
+ // citeseer.csail.mit.edu/307799.html.
+ 
+ template <typename T1,
+ 	  typename T2>
+ void
+ transpose_unit(
+   T1* dst, T2* src,
+   unsigned const rows,		// dst rows
+   unsigned const cols,		// dst cols
+   unsigned const dst_col_stride,
+   unsigned const src_row_stride)
+ {
+   unsigned const thresh = 16;
+   if (rows <= thresh && cols <= thresh)
+   {
+     for (unsigned r=0; r<rows; ++r)
+       for (unsigned c=0; c<cols; ++c)
+ 	dst[r+c*dst_col_stride] = src[r*src_row_stride+c];
+   }
+   else if (cols >= rows)
+   {
+     transpose_unit(dst,          src,
+ 		   rows, cols/2,
+ 		   dst_col_stride, src_row_stride);
+ 
+     transpose_unit(dst + (cols/2)*dst_col_stride, src + (cols/2),
+ 		   rows, cols/2 + cols%2,
+ 		   dst_col_stride, src_row_stride);
+   }
+   else
+   {
+     transpose_unit(dst,          src,
+ 		   rows/2, cols,
+ 		   dst_col_stride, src_row_stride);
+ 
+     transpose_unit(dst + (rows/2), src + (rows/2)*src_row_stride,
+ 		   rows/2 + rows%2, cols,
+ 		   dst_col_stride, src_row_stride);
+   }
+ }
+ 
+ 
+ 
+ // Transpose for matrices with arbitrary strides.
+ 
+ // Algorithm based on "Cache-Oblivious Algorithms (Extended Abstract)"
+ // by M. Frigo, C. Leiseron, H. Prokop, S. Ramachandran.
+ // citeseer.csail.mit.edu/307799.html.
+ 
+ template <typename T1,
+ 	  typename T2>
+ void
+ transpose(
+   T1* dst, T2* src,
+   unsigned const rows,		// dst rows
+   unsigned const cols,		// dst cols
+   unsigned const dst_stride0,
+   unsigned const dst_stride1,	// eq. to dst_col_stride
+   unsigned const src_stride0,	// eq. to src_row_stride
+   unsigned const src_stride1)
+ {
+   unsigned const thresh = 16;
+   if (rows <= thresh && cols <= thresh)
+   {
+     for (unsigned r=0; r<rows; ++r)
+       for (unsigned c=0; c<cols; ++c)
+ 	dst[r*dst_stride0+c*dst_stride1] = src[r*src_stride0+c*src_stride1];
+   }
+   else if (cols >= rows)
+   {
+     transpose(dst,          src,
+ 	      rows, cols/2,
+ 	      dst_stride0, dst_stride1,
+ 	      src_stride0, src_stride1);
+ 
+     transpose(dst + (cols/2)*dst_stride1, src + (cols/2),
+ 	      rows, cols/2 + cols%2,
+ 	      dst_stride0, dst_stride1,
+ 	      src_stride0, src_stride1);
+   }
+   else
+   {
+     transpose(dst,          src,
+ 	      rows/2, cols,
+ 	      dst_stride0, dst_stride1,
+ 	      src_stride0, src_stride1);
+ 
+     transpose(dst + (rows/2), src + (rows/2)*src_stride0,
+ 	      rows/2 + rows%2, cols,
+ 	      dst_stride0, dst_stride1,
+ 	      src_stride0, src_stride1);
+   }
+ }
+ 
+ } // namespace vsip::impl
+ } // namespace vsip
+ 
+ #endif // VSIP_IMPL_FAST_TRANSPOSE_HPP
Index: src/vsip/impl/ipp.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp.cpp,v
retrieving revision 1.8
diff -c -p -r1.8 ipp.cpp
*** src/vsip/impl/ipp.cpp	5 Dec 2005 15:16:17 -0000	1.8
--- src/vsip/impl/ipp.cpp	21 Dec 2005 20:49:14 -0000
*************** void vdiv(std::complex<double> const* A,
*** 180,185 ****
--- 180,385 ----
    assert(status == ippStsNoErr);
  }
  
+ 
+ 
+ // Scalar-vector functions
+ 
+ void svadd(float A, float const* B, float* Z, length_type len)
+ {
+   IppStatus status = ippsAddC_32f(B, A, Z, static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svadd(double A, double const* B, double* Z, length_type len)
+ {
+   IppStatus status = ippsAddC_64f(B, A, Z, static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svadd(std::complex<float> A, std::complex<float> const* B,
+ 	   std::complex<float>* Z, length_type len)
+ {
+   IppStatus status = ippsAddC_32fc(
+     reinterpret_cast<Ipp32fc const*>(B),
+     *reinterpret_cast<Ipp32fc*>(&A),
+     reinterpret_cast<Ipp32fc*>(Z),
+     static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svadd(std::complex<double> A, std::complex<double> const* B,
+ 	   std::complex<double>* Z, length_type len)
+ {
+   IppStatus status = ippsAddC_64fc(
+     reinterpret_cast<Ipp64fc const*>(B),
+     *reinterpret_cast<Ipp64fc*>(&A),
+     reinterpret_cast<Ipp64fc*>(Z),
+     static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ 
+ /// scalar-vector subtraction: scalar - vector
+ 
+ void svsub(float A, float const* B, float* Z, length_type len)
+ {
+   IppStatus status = ippsSubCRev_32f(B, A, Z, static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svsub(double A, double const* B, double* Z, length_type len)
+ {
+   IppStatus status = ippsSubCRev_64f(B, A, Z, static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svsub(std::complex<float> A, std::complex<float> const* B,
+ 	   std::complex<float>* Z, length_type len)
+ {
+   IppStatus status = ippsSubCRev_32fc(
+     reinterpret_cast<Ipp32fc const*>(B),
+     *reinterpret_cast<Ipp32fc*>(&A),
+     reinterpret_cast<Ipp32fc*>(Z),
+     static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svsub(std::complex<double> A, std::complex<double> const* B,
+ 	   std::complex<double>* Z, length_type len)
+ {
+   IppStatus status = ippsSubCRev_64fc(
+     reinterpret_cast<Ipp64fc const*>(B),
+     *reinterpret_cast<Ipp64fc*>(&A),
+     reinterpret_cast<Ipp64fc*>(Z),
+     static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ 
+ 
+ /// scalar-view subtraction: vector - scalar
+ 
+ void svsub(float const* A, float B, float* Z, length_type len)
+ {
+   IppStatus status = ippsSubC_32f(A, B, Z, static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svsub(double const* A, double B, double* Z, length_type len)
+ {
+   IppStatus status = ippsSubC_64f(A, B, Z, static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svsub(std::complex<float> const* A, std::complex<float> B,
+ 	   std::complex<float>* Z, length_type len)
+ {
+   IppStatus status = ippsSubC_32fc(
+     reinterpret_cast<Ipp32fc const*>(A),
+     *reinterpret_cast<Ipp32fc*>(&B),
+     reinterpret_cast<Ipp32fc*>(Z),
+     static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svsub(std::complex<double> const* A, std::complex<double> B,
+ 	   std::complex<double>* Z, length_type len)
+ {
+   IppStatus status = ippsSubC_64fc(
+     reinterpret_cast<Ipp64fc const*>(A),
+     *reinterpret_cast<Ipp64fc*>(&B),
+     reinterpret_cast<Ipp64fc*>(Z),
+     static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ 
+ 
+ void svmul(float A, float const* B, float* Z, length_type len)
+ {
+   IppStatus status = ippsMulC_32f(B, A, Z, static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svmul(double A, double const* B, double* Z, length_type len)
+ {
+   IppStatus status = ippsMulC_64f(B, A, Z, static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svmul(std::complex<float> A, std::complex<float> const* B,
+ 	   std::complex<float>* Z, length_type len)
+ {
+   IppStatus status = ippsMulC_32fc(
+     reinterpret_cast<Ipp32fc const*>(B),
+     *reinterpret_cast<Ipp32fc*>(&A),
+     reinterpret_cast<Ipp32fc*>(Z),
+     static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svmul(std::complex<double> A, std::complex<double> const* B,
+ 	   std::complex<double>* Z, length_type len)
+ {
+   IppStatus status = ippsMulC_64fc(
+     reinterpret_cast<Ipp64fc const*>(B),
+     *reinterpret_cast<Ipp64fc*>(&A),
+     reinterpret_cast<Ipp64fc*>(Z),
+     static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ 
+ 
+ /// scalar-vector division: scalar / vector
+ 
+ void svdiv(float A, float const* B, float* Z, length_type len)
+ {
+   IppStatus status = ippsDivCRev_32f(B, A, Z, static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ 
+ 
+ /// scalar-view division: vector / scalar
+ 
+ void svdiv(float const* A, float B, float* Z, length_type len)
+ {
+   IppStatus status = ippsDivC_32f(A, B, Z, static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svdiv(double const* A, double B, double* Z, length_type len)
+ {
+   IppStatus status = ippsDivC_64f(A, B, Z, static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svdiv(std::complex<float> const* A, std::complex<float> B,
+ 	   std::complex<float>* Z, length_type len)
+ {
+   IppStatus status = ippsDivC_32fc(
+     reinterpret_cast<Ipp32fc const*>(A),
+     *reinterpret_cast<Ipp32fc*>(&B),
+     reinterpret_cast<Ipp32fc*>(Z),
+     static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ void svdiv(std::complex<double> const* A, std::complex<double> B,
+ 	   std::complex<double>* Z, length_type len)
+ {
+   IppStatus status = ippsDivC_64fc(
+     reinterpret_cast<Ipp64fc const*>(A),
+     *reinterpret_cast<Ipp64fc*>(&B),
+     reinterpret_cast<Ipp64fc*>(Z),
+     static_cast<int>(len));
+   assert(status == ippStsNoErr);
+ }
+ 
+ 
+ 
+ 
  // Convolution
  void conv(float* coeff, length_type coeff_size,
  	  float* in,    length_type in_size,
Index: src/vsip/impl/ipp.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp.hpp,v
retrieving revision 1.6
diff -c -p -r1.6 ipp.hpp
*** src/vsip/impl/ipp.hpp	5 Dec 2005 15:16:17 -0000	1.6
--- src/vsip/impl/ipp.hpp	21 Dec 2005 20:49:14 -0000
***************
*** 16,21 ****
--- 16,22 ----
  #include <vsip/support.hpp>
  #include <vsip/impl/block-traits.hpp>
  #include <vsip/impl/expr_serial_evaluator.hpp>
+ #include <vsip/impl/expr_scalar_block.hpp>
  #include <vsip/impl/expr_binary_block.hpp>
  #include <vsip/impl/expr_operations.hpp>
  #include <vsip/impl/extdata.hpp>
*************** void vmul(std::complex<float> const* A, 
*** 85,90 ****
--- 86,132 ----
  void vmul(std::complex<double> const* A, std::complex<double> const* B,
            std::complex<double>* Z, length_type len);
  
+ void svadd(float A, float const* B, float* Z, length_type len);
+ void svadd(double A, double const* B, double* Z, length_type len);
+ void svadd(complex<float> A, complex<float> const* B,
+ 	   complex<float>* Z, length_type len);
+ void svadd(complex<double> A, complex<double> const* B,
+ 	   complex<double>* Z, length_type len);
+ 
+ // sub: scalar - vector
+ void svsub(float A, float const* B, float* Z, length_type len);
+ void svsub(double A, double const* B, double* Z, length_type len);
+ void svsub(complex<float> A, complex<float> const* B,
+ 	   complex<float>* Z, length_type len);
+ void svsub(complex<double> A, complex<double> const* B,
+ 	   complex<double>* Z, length_type len);
+ 
+ // sub: vector - scalar
+ void svsub(float const* A, float B, float* Z, length_type len);
+ void svsub(double const* A, double B, double* Z, length_type len);
+ void svsub(complex<float> const* A, complex<float> B,
+ 	   complex<float>* Z, length_type len);
+ void svsub(complex<double> const* A, complex<double> B,
+ 	   complex<double>* Z, length_type len);
+ 
+ void svmul(float A, float const* B, float* Z, length_type len);
+ void svmul(double A, double const* B, double* Z, length_type len);
+ void svmul(complex<float> A, complex<float> const* B,
+ 	   complex<float>* Z, length_type len);
+ void svmul(complex<double> A, complex<double> const* B,
+ 	   complex<double>* Z, length_type len);
+ 
+ // functions for scalar-view division: scalar / vector
+ void svdiv(float A, float const* B, float* Z, length_type len);
+ 
+ // functions for scalar-view division: vector / scalar
+ void svdiv(float const* A, float B, float* Z, length_type len);
+ void svdiv(double const* A, double B, double* Z, length_type len);
+ void svdiv(complex<float> const* A, complex<float> B,
+ 	   complex<float>* Z, length_type len);
+ void svdiv(complex<double> const* A, complex<double> B,
+ 	   complex<double>* Z, length_type len);
+ 
  // functions for vector division
  void vdiv(float const* A, float const* B, float* Z, length_type len);
  void vdiv(double const* A, double const* B, double* Z, length_type len);
*************** struct Serial_expr_evaluator<
*** 295,300 ****
--- 337,649 ----
    }
  };
  
+ /***********************************************************************
+   Scalar-view element-wise operations
+ ***********************************************************************/
+ 
+ namespace ipp
+ {
+ 
+ template <template <typename, typename> class Operator,
+ 	  typename DstBlock,
+ 	  typename SType,
+ 	  typename VBlock,
+ 	  typename VType,
+ 	  bool     Right>
+ struct Scalar_view_evaluator_base
+ {
+   typedef Binary_expr_block<1, Operator,
+ 			    Scalar_block<1, SType>, SType,
+ 			    VBlock, VType>
+ 	SrcBlock;
+ 
+   static bool const ct_valid = 
+     !Is_expr_block<VBlock>::value &&
+      ipp::Is_type_supported<typename DstBlock::value_type>::value &&
+      Type_equal<typename DstBlock::value_type, SType>::value &&
+      Type_equal<typename DstBlock::value_type, VType>::value &&
+      // check that direct access is supported
+      Ext_data_cost<DstBlock>::value == 0 &&
+      Ext_data_cost<VBlock>::value == 0 &&
+      // Complex split format is not supported.
+      Type_equal<typename Block_layout<DstBlock>::complex_type,
+ 		Cmplx_inter_fmt>::value;
+ 
+   static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+   {
+     // check if all data is unit stride
+     Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+     Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
+     return (ext_dst.stride(0) == 1 &&
+ 	    ext_r.stride(0) == 1);
+   }
+ 
+ };
+ 
+ 
+ 
+ template <template <typename, typename> class Operator,
+ 	  typename DstBlock,
+ 	  typename SType,
+ 	  typename VBlock,
+ 	  typename VType>
+ struct Scalar_view_evaluator_base<Operator, DstBlock, SType, VBlock, VType,
+ 				  false>
+ {
+   typedef Binary_expr_block<1, Operator,
+ 			    VBlock, VType,
+ 			    Scalar_block<1, SType>, SType>
+ 	SrcBlock;
+ 
+   static bool const ct_valid = 
+     !Is_expr_block<VBlock>::value &&
+      ipp::Is_type_supported<typename DstBlock::value_type>::value &&
+      Type_equal<typename DstBlock::value_type, SType>::value &&
+      Type_equal<typename DstBlock::value_type, VType>::value &&
+      // check that direct access is supported
+      Ext_data_cost<DstBlock>::value == 0 &&
+      Ext_data_cost<VBlock>::value == 0 &&
+      // Complex split format is not supported.
+      Type_equal<typename Block_layout<DstBlock>::complex_type,
+ 		Cmplx_inter_fmt>::value;
+ 
+   static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+   {
+     // check if all data is unit stride
+     Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+     Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
+     return (ext_dst.stride(0) == 1 &&
+ 	    ext_l.stride(0) == 1);
+   }
+ 
+ };
+ 
+ } // namespace vsip::impl::ipp
+ 
+ 
+ 
+ template <typename DstBlock,
+ 	  typename SType,
+ 	  typename VBlock,
+ 	  typename VType>
+ struct Serial_expr_evaluator<
+          1, DstBlock, 
+          const Binary_expr_block<1, op::Add,
+                                  Scalar_block<1, SType>, SType,
+                                  VBlock, VType>,
+          Intel_ipp_tag>
+   : ipp::Scalar_view_evaluator_base<op::Add, DstBlock, SType, VBlock, VType,
+ 				    true>
+ {
+   typedef Binary_expr_block<1, op::Add,
+ 			    Scalar_block<1, SType>, SType,
+ 			    VBlock, VType>
+ 	SrcBlock;
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src)
+   {
+     Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+     Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
+     ipp::svadd(src.left().value(), ext_r.data(), ext_dst.data(), dst.size());
+   }
+ };
+ 
+ 
+ 
+ template <typename DstBlock,
+ 	  typename SType,
+ 	  typename VBlock,
+ 	  typename VType>
+ struct Serial_expr_evaluator<
+          1, DstBlock, 
+          const Binary_expr_block<1, op::Add,
+                                  VBlock, VType,
+                                  Scalar_block<1, SType>, SType>,
+          Intel_ipp_tag>
+   : ipp::Scalar_view_evaluator_base<op::Add, DstBlock, SType, VBlock, VType,
+ 				    false>
+ {
+   typedef Binary_expr_block<1, op::Add,
+ 			    VBlock, VType,
+ 			    Scalar_block<1, SType>, SType>
+ 	SrcBlock;
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src)
+   {
+     Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+     Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
+     ipp::svadd(src.right().value(), ext_l.data(), ext_dst.data(), dst.size());
+   }
+ };
+ 
+ 
+ 
+ template <typename DstBlock,
+ 	  typename SType,
+ 	  typename VBlock,
+ 	  typename VType>
+ struct Serial_expr_evaluator<
+          1, DstBlock, 
+          const Binary_expr_block<1, op::Sub,
+                                  Scalar_block<1, SType>, SType,
+                                  VBlock, VType>,
+          Intel_ipp_tag>
+   : ipp::Scalar_view_evaluator_base<op::Sub, DstBlock, SType, VBlock, VType,
+ 				    true>
+ {
+   typedef Binary_expr_block<1, op::Sub,
+ 			    Scalar_block<1, SType>, SType,
+ 			    VBlock, VType>
+ 	SrcBlock;
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src)
+   {
+     Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+     Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
+     ipp::svsub(src.left().value(), ext_r.data(), ext_dst.data(), dst.size());
+   }
+ };
+ 
+ 
+ 
+ template <typename DstBlock,
+ 	  typename SType,
+ 	  typename VBlock,
+ 	  typename VType>
+ struct Serial_expr_evaluator<
+          1, DstBlock, 
+          const Binary_expr_block<1, op::Sub,
+                                  VBlock, VType,
+                                  Scalar_block<1, SType>, SType>,
+          Intel_ipp_tag>
+   : ipp::Scalar_view_evaluator_base<op::Sub, DstBlock, SType, VBlock, VType,
+ 				    false>
+ {
+   typedef Binary_expr_block<1, op::Sub,
+ 			    VBlock, VType,
+ 			    Scalar_block<1, SType>, SType>
+ 	SrcBlock;
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src)
+   {
+     Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+     Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
+     ipp::svsub(ext_l.data(), src.right().value(), ext_dst.data(), dst.size());
+   }
+ };
+ 
+ 
+ 
+ template <typename DstBlock,
+ 	  typename SType,
+ 	  typename VBlock,
+ 	  typename VType>
+ struct Serial_expr_evaluator<
+          1, DstBlock, 
+          const Binary_expr_block<1, op::Mult,
+                                  Scalar_block<1, SType>, SType,
+                                  VBlock, VType>,
+          Intel_ipp_tag>
+   : ipp::Scalar_view_evaluator_base<op::Mult, DstBlock, SType, VBlock, VType,
+ 				    true>
+ {
+   typedef Binary_expr_block<1, op::Mult,
+ 			    Scalar_block<1, SType>, SType,
+ 			    VBlock, VType>
+ 	SrcBlock;
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src)
+   {
+     Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+     Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
+     ipp::svmul(src.left().value(), ext_r.data(), ext_dst.data(), dst.size());
+   }
+ };
+ 
+ 
+ 
+ template <typename DstBlock,
+ 	  typename SType,
+ 	  typename VBlock,
+ 	  typename VType>
+ struct Serial_expr_evaluator<
+          1, DstBlock, 
+          const Binary_expr_block<1, op::Mult,
+                                  VBlock, VType,
+                                  Scalar_block<1, SType>, SType>,
+          Intel_ipp_tag>
+   : ipp::Scalar_view_evaluator_base<op::Mult, DstBlock, SType, VBlock, VType,
+ 				    false>
+ {
+   typedef Binary_expr_block<1, op::Mult,
+ 			    VBlock, VType,
+ 			    Scalar_block<1, SType>, SType>
+ 	SrcBlock;
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src)
+   {
+     Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+     Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
+     ipp::svmul(src.right().value(), ext_l.data(), ext_dst.data(), dst.size());
+   }
+ };
+ 
+ 
+ 
+ template <typename DstBlock,
+ 	  typename VBlock>
+ struct Serial_expr_evaluator<
+          1, DstBlock, 
+          const Binary_expr_block<1, op::Div,
+                                  Scalar_block<1, float>, float,
+                                  VBlock, float>,
+          Intel_ipp_tag>
+   : ipp::Scalar_view_evaluator_base<op::Div, DstBlock, float, VBlock, float,
+ 				    true>
+ {
+   typedef float SType;
+   typedef float VType;
+   typedef Binary_expr_block<1, op::Div,
+ 			    Scalar_block<1, SType>, SType,
+ 			    VBlock, VType>
+ 	SrcBlock;
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src)
+   {
+     Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+     Ext_data<VBlock> ext_r(src.right(), SYNC_IN);
+     ipp::svdiv(src.left().value(), ext_r.data(), ext_dst.data(), dst.size());
+   }
+ };
+ 
+ 
+ 
+ template <typename DstBlock,
+ 	  typename SType,
+ 	  typename VBlock,
+ 	  typename VType>
+ struct Serial_expr_evaluator<
+          1, DstBlock, 
+          const Binary_expr_block<1, op::Div,
+                                  VBlock, VType,
+                                  Scalar_block<1, SType>, SType>,
+          Intel_ipp_tag>
+   : ipp::Scalar_view_evaluator_base<op::Div, DstBlock, SType, VBlock, VType,
+ 				    false>
+ {
+   typedef Binary_expr_block<1, op::Div,
+ 			    VBlock, VType,
+ 			    Scalar_block<1, SType>, SType>
+ 	SrcBlock;
+ 
+   static void exec(DstBlock& dst, SrcBlock const& src)
+   {
+     Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
+     Ext_data<VBlock> ext_l(src.left(), SYNC_IN);
+     ipp::svdiv(ext_l.data(), src.right().value(), ext_dst.data(), dst.size());
+   }
+ };
+ 
  } // namespace vsip::impl
  } // namespace vsip
  
Index: src/vsip/impl/profile.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/profile.hpp,v
retrieving revision 1.10
diff -c -p -r1.10 profile.hpp
*** src/vsip/impl/profile.hpp	7 Sep 2005 12:19:31 -0000	1.10
--- src/vsip/impl/profile.hpp	21 Dec 2005 20:49:16 -0000
*************** namespace profile
*** 64,69 ****
--- 64,70 ----
  
  struct No_time
  {
+   static bool const valid = false; 
    static char* name() { return "No_time"; }
    static void init() {}
  
*************** struct No_time
*** 82,87 ****
--- 83,89 ----
  #if (VSIP_IMPL_PROFILE_TIMER == 1)
  struct Posix_time
  {
+   static bool const valid = true; 
    static char* name() { return "Posix_time"; }
    static void init() { clocks_per_sec = CLOCKS_PER_SEC; }
  
*************** struct Posix_time
*** 100,105 ****
--- 102,108 ----
  #if (VSIP_IMPL_PROFILE_TIMER == 2)
  struct Posix_real_time
  {
+   static bool const valid = true; 
    static char* name() { return "Posix_real_time"; }
    static void init() {}
  
*************** struct Posix_real_time
*** 148,153 ****
--- 151,157 ----
  #if (VSIP_IMPL_PROFILE_TIMER == 3)
  struct Pentium_tsc_time
  {
+   static bool const valid = true; 
    static char* name() { return "Pentium_tsc_time"; }
    static void init();
  
*************** struct Pentium_tsc_time
*** 167,172 ****
--- 171,177 ----
  #if (VSIP_IMPL_PROFILE_TIMER == 4)
  struct X86_64_tsc_time
  {
+   static bool const valid = true; 
    static char* name() { return "x86_64_tsc_time"; }
    static void init();
  
Index: src/vsip/impl/vmmul.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/vmmul.hpp,v
retrieving revision 1.2
diff -c -p -r1.2 vmmul.hpp
*** src/vsip/impl/vmmul.hpp	2 Nov 2005 18:44:04 -0000	1.2
--- src/vsip/impl/vmmul.hpp	21 Dec 2005 20:49:16 -0000
*************** struct Vmmul_traits
*** 277,282 ****
--- 277,354 ----
    typedef Matrix<value_type, block_type>              view_type;
  };
  
+ 
+ 
+ /// Evaluator for vector-matrix multiply.
+ 
+ /// Reduces vmmul into either vector element-wise multipy, or
+ /// scalar-vector multiply, depending on the dimension-ordering and
+ /// requested orientation.  These reduced cases are then
+ /// re-dispatched, allowing them to be handled by a vendor library,
+ 
+ template <typename DstBlock,
+ 	  typename VBlock,
+ 	  typename MBlock,
+ 	  dimension_type SD>
+ struct Serial_expr_evaluator<2, DstBlock,
+ 			     const Vmmul_expr_block<SD, VBlock, MBlock>,
+ 			     Loop_fusion_tag>
+ {
+   typedef Vmmul_expr_block<SD, VBlock, MBlock> SrcBlock;
+ 
+   typedef typename DstBlock::value_type dst_type;
+   typedef typename VBlock::value_type v_type;
+   typedef typename MBlock::value_type m_type;
+ 
+   static bool const ct_valid = 
+     !Is_expr_block<VBlock>::value &&
+     !Is_expr_block<MBlock>::value;
+ 
+   static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
+   {
+     return true;
+   }
+   
+   static void exec(DstBlock& dst, SrcBlock const& src)
+   {
+     VBlock const& vblock = src.get_vblk();
+     MBlock const& mblock = src.get_mblk();
+ 
+     typedef typename Block_layout<DstBlock>::order_type order_type;
+ 
+     Matrix<dst_type, DstBlock> m_dst(dst);
+     const_Vector<dst_type, VBlock>  v(const_cast<VBlock&>(vblock));
+     const_Matrix<dst_type, MBlock>  m(const_cast<MBlock&>(mblock));
+ 
+     if (Type_equal<order_type, row2_type>::value)
+     {
+       if (SD == row)
+       {
+ 	for (index_type r=0; r<dst.size(2, 0); ++r)
+ 	  m_dst.row(r) = v * m.row(r);
+       }
+       else
+       {
+ 	for (index_type r=0; r<dst.size(2, 0); ++r)
+ 	  m_dst.row(r) = v.get(r) * m.row(r);
+       }
+     }
+     else // col2_type
+     {
+       if (SD == row)
+       {
+ 	for (index_type c=0; c<dst.size(2, 1); ++c)
+ 	  m_dst.col(c) = v.get(c) * m.col(c);
+       }
+       else
+       {
+ 	for (index_type c=0; c<dst.size(2, 1); ++c)
+ 	  m_dst.col(c) = v * m.col(c);
+       }
+     }
+   }
+ };
+ 
  } // namespace vsip::impl
  
  
Index: tests/matvec-prod.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/matvec-prod.cpp,v
retrieving revision 1.6
diff -c -p -r1.6 matvec-prod.cpp
*** tests/matvec-prod.cpp	20 Dec 2005 12:48:41 -0000	1.6
--- tests/matvec-prod.cpp	21 Dec 2005 20:49:16 -0000
***************
*** 11,17 ****
    Included Files
  ***********************************************************************/
  
- #include <cassert>
  #include <iostream>
  
  #include <vsip/initfin.hpp>
--- 11,16 ----
Index: tests/scalar-view.cpp
===================================================================
RCS file: tests/scalar-view.cpp
diff -N tests/scalar-view.cpp
*** /dev/null	1 Jan 1970 00:00:00 -0000
--- tests/scalar-view.cpp	21 Dec 2005 20:49:16 -0000
***************
*** 0 ****
--- 1,255 ----
+ /* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+ 
+ /** @file    tests/scalar-view.cpp
+     @author  Jules Bergmann
+     @date    2005-12-19
+     @brief   VSIPL++ Library: Coverage tests for scalar-view expressions.
+ 
+ */
+ 
+ /***********************************************************************
+   Included Files
+ ***********************************************************************/
+ 
+ #include <vsip/support.hpp>
+ #include <vsip/vector.hpp>
+ #include <vsip/selgen.hpp>
+ #include <vsip/math.hpp>
+ 
+ #include "test.hpp"
+ #include "test-storage.hpp"
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
+ enum Op_type
+ {
+   op_add,
+   op_sub,
+   op_mul,
+   op_div
+ };
+ 
+ /// Utility class to hold an Op_type value as a distinct type.
+ template <Op_type Type> struct Op_holder {};
+ 
+ 
+ /// Trait to determine value type of a type.
+ 
+ /// For general types, type is value type.
+ template <typename T>
+ struct Value_type
+ {
+   typedef T type;
+ };
+ 
+ /// For views, element type is value type.
+ template <typename T, typename Block>
+ struct Value_type<Vector<T, Block> >
+ {
+   typedef T type;
+ };
+ 
+ 
+ 
+ /// Overload of test_case for add expression: res = a + b.
+ 
+ template <typename T1,
+ 	  typename T2,
+ 	  typename T3>
+ void
+ test_case(
+   Op_holder<op_add>,
+   T1 res,
+   T2 a,
+   T3 b)
+ {
+   typedef typename Value_type<T1>::type value_type;
+ 
+   res = a + b;
+   
+   for (index_type i=0; i<get_size(res); ++i)
+   {
+     test_assert(equal(get_nth(res, i),
+ 		       value_type(get_nth(a, i) + get_nth(b, i))));
+   }
+ }
+ 
+ 
+ 
+ /// Overload of test_case for subtract expression: res = a - b.
+ 
+ template <typename T1,
+ 	  typename T2,
+ 	  typename T3>
+ void
+ test_case(
+   Op_holder<op_sub>,
+   T1 res,
+   T2 a,
+   T3 b)
+ {
+   typedef typename Value_type<T1>::type value_type;
+ 
+   res = a - b;
+   
+   for (index_type i=0; i<get_size(res); ++i)
+   {
+     test_assert(equal(get_nth(res, i),
+ 		       value_type(get_nth(a, i) - get_nth(b, i))));
+   }
+ }
+ 
+ 
+ 
+ /// Overload of test_case for multiply expression: res = a * b.
+ 
+ template <typename T1,
+ 	  typename T2,
+ 	  typename T3>
+ void
+ test_case(
+   Op_holder<op_mul>,
+   T1 res,
+   T2 a,
+   T3 b)
+ {
+   typedef typename Value_type<T1>::type value_type;
+ 
+   res = a * b;
+   
+   for (index_type i=0; i<get_size(res); ++i)
+   {
+     test_assert(equal(get_nth(res, i),
+ 		       value_type(get_nth(a, i) * get_nth(b, i))));
+   }
+ }
+ 
+ 
+ 
+ /// Overload of test_case for divide expression: res = a / b.
+ 
+ template <typename T1,
+ 	  typename T2,
+ 	  typename T3>
+ void
+ test_case(
+   Op_holder<op_div>,
+   T1 res,
+   T2 a,
+   T3 b)
+ {
+   typedef typename Value_type<T1>::type value_type;
+ 
+   res = a / b;
+   
+   for (index_type i=0; i<get_size(res); ++i)
+   {
+     test_assert(equal(get_nth(res, i),
+ 		       value_type(get_nth(a, i) / get_nth(b, i))));
+   }
+ }
+ 
+ 
+ 
+ // Test given expression with various combinations of scalar vs view
+ // operands and stride-1 vs stride-N operands.
+ 
+ template <Op_type  op,
+ 	  typename T1,
+ 	  typename T2,
+ 	  typename T3>
+ void
+ test_type()
+ {
+   length_type size = 8;
+ 
+   Vector<T1> big_res(2 * size);
+   Vector<T2> big_a(2 * size);
+   Vector<T3> big_b(2 * size);
+ 
+   Vector<T1> res(size);
+   Vector<T2> a(size);
+   Vector<T3> b(size);
+ 
+   typename Vector<T1>::subview_type res2 = big_res(Domain<1>(0, 2, size));
+   typename Vector<T2>::subview_type a2   = big_a(Domain<1>(0, 2, size));
+   typename Vector<T3>::subview_type b2   = big_b(Domain<1>(0, 2, size));
+ 
+   T2 alpha = T2(2);
+   T3 beta  = T3(3);
+ 
+   a  = ramp(T2(1), T2(1),  size);
+   b  = ramp(T3(1), T3(-2), size);
+   a2 = ramp(T2(1), T2(1),  size);
+   b2 = ramp(T3(1), T3(-2), size);
+ 
+   test_case(Op_holder<op>(), res, a, b);
+   test_case(Op_holder<op>(), res, alpha, b);
+   test_case(Op_holder<op>(), res, a, beta);
+ 
+   test_case(Op_holder<op>(), res, a2, b);
+   test_case(Op_holder<op>(), res, a, b2);
+   test_case(Op_holder<op>(), res, alpha, b2);
+   test_case(Op_holder<op>(), res, a2, beta);
+ 
+   test_case(Op_holder<op>(), res2, a, b);
+   test_case(Op_holder<op>(), res2, a2, b);
+   test_case(Op_holder<op>(), res2, a, b2);
+   test_case(Op_holder<op>(), res2, alpha, b);
+   test_case(Op_holder<op>(), res2, a, beta);
+ 
+   test_case(Op_holder<op>(), res2, a2, b2);
+   test_case(Op_holder<op>(), res2, alpha, b2);
+   test_case(Op_holder<op>(), res2, a2, beta);
+ }
+ 
+ 
+ 
+ // Test an operation for various types.
+ 
+ template <Op_type op>
+ void
+ test()
+ {
+   test_type<op, short, short, short>();
+   test_type<op, int, short, short>();
+   test_type<op, int, int, short>();
+   test_type<op, int, short, int>();
+   test_type<op, int, int, int>();
+ 
+   test_type<op, float, float, float>();
+   test_type<op, float, double, float>();
+   test_type<op, float, float, double>();
+ 
+   test_type<op, double, double, double>();
+   test_type<op, double, double, float>();
+   test_type<op, double, float,  double>();
+   test_type<op, double, float,  float>();
+ 
+   test_type<op, complex<float>,         float,  complex<float> >();
+   test_type<op, complex<float>, complex<float>,         float  >();
+   test_type<op, complex<float>, complex<float>, complex<float> >();
+ 
+   test_type<op, complex<double>,         double,  complex<double> >();
+   test_type<op, complex<double>, complex<double>,         double  >();
+   test_type<op, complex<double>, complex<double>, complex<double> >();
+ 
+ }
+ 
+ 
+ 
+ int
+ main()
+ {
+   test<op_mul>();
+   test<op_add>();
+   test<op_sub>();
+   test<op_div>();
+ }
