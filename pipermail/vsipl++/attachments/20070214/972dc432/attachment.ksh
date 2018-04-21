Index: benchmarks/vmagsq.cpp
===================================================================
--- benchmarks/vmagsq.cpp	(revision 163254)
+++ benchmarks/vmagsq.cpp	(working copy)
@@ -22,6 +22,7 @@
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
 #include <vsip/core/metaprogramming.hpp>
+#include <vsip/opt/diag/eval.hpp>
 
 #include "benchmarks.hpp"
 
@@ -33,7 +34,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_vmagsq1
+struct t_vmagsq1 : Benchmark_base
 {
   typedef typename impl::Scalar_of<T>::type scalar_type;
 
@@ -73,10 +74,73 @@
     
     time = t1.delta();
   }
+
+  void diag()
+  {
+    length_type size = 256;
+    Vector<T>           A(size, T());
+    Vector<scalar_type> Z(size);
+
+    vsip::impl::diagnose_eval_list_std(Z, magsq(A));
+  }
 };
 
 
 
+template <typename T>
+struct t_vmag1 : Benchmark_base
+{
+  typedef typename impl::Scalar_of<T>::type scalar_type;
+
+  char* what() { return "t_vmag1"; }
+  int ops_per_point(length_type)
+  {
+    if (impl::Is_complex<T>::value)
+      return 2*vsip::impl::Ops_info<scalar_type>::mul + 
+        vsip::impl::Ops_info<scalar_type>::add;
+    else
+      return vsip::impl::Ops_info<T>::mul;
+  }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    Vector<T>           A(size, T());
+    Vector<scalar_type> Z(size);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+
+    A.put(0, T(3));
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      Z = mag(A);
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(Z.get(i), mag(A.get(i))));
+    
+    time = t1.delta();
+  }
+
+  void diag()
+  {
+    length_type size = 256;
+    Vector<T>           A(size, T());
+    Vector<scalar_type> Z(size);
+
+    vsip::impl::diagnose_eval_list_std(Z, mag(A));
+  }
+};
+
+
+
 void
 defaults(Loop1P&)
 {
@@ -89,9 +153,16 @@
 {
   switch (what)
   {
-  case  1: loop(t_vmagsq1<float>()); break;
-  case  2: loop(t_vmagsq1<complex<float> >()); break;
+  case  1: loop(t_vmagsq1<        float   >()); break;
+  case  2: loop(t_vmagsq1<complex<float > >()); break;
+  case  3: loop(t_vmagsq1<        double  >()); break;
+  case  4: loop(t_vmagsq1<complex<double> >()); break;
 
+  case 11: loop(t_vmag1<        float   >()); break;
+  case 12: loop(t_vmag1<complex<float > >()); break;
+  case 13: loop(t_vmag1<        double  >()); break;
+  case 14: loop(t_vmag1<complex<double> >()); break;
+
   default:
     return 0;
   }
Index: benchmarks/copy.cpp
===================================================================
--- benchmarks/copy.cpp	(revision 163254)
+++ benchmarks/copy.cpp	(working copy)
@@ -25,6 +25,7 @@
 #include <vsip/map.hpp>
 #include <vsip/parallel.hpp>
 #include <vsip/core/profile.hpp>
+#include <vsip/opt/diag/eval.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
@@ -41,6 +42,7 @@
 
 struct Impl_assign;				// normal assignment
 struct Impl_sa;					// Setup_assign object
+struct Impl_memcpy;				// use memcpy
 template <typename Impl> struct Impl_pa;	// Par_assign<Impl> object
 template <typename Impl> struct Impl_pa_na;	//  " " (not amortized)
 
@@ -59,8 +61,11 @@
 template <typename T,
 	  typename SrcMapT,
 	  typename DstMapT>
-struct t_vcopy<T, SrcMapT, DstMapT, Impl_assign>
+struct t_vcopy<T, SrcMapT, DstMapT, Impl_assign> : Benchmark_base
 {
+  typedef Dense<1, T, row1_type, SrcMapT> src_block_t;
+  typedef Dense<1, T, row1_type, DstMapT> dst_block_t;
+  
   char* what() { return "t_vcopy<..., Impl_assign>"; }
   int ops_per_point(length_type)  { return 1; }
   int riob_per_point(length_type) { return 1*sizeof(T); }
@@ -69,8 +74,6 @@
 
   void operator()(length_type size, length_type loop, float& time)
   {
-    typedef Dense<1, T, row1_type, SrcMapT> src_block_t;
-    typedef Dense<1, T, row1_type, DstMapT> dst_block_t;
     Vector<T, src_block_t>   A(size, T(), src_map_);
     Vector<T, dst_block_t>   Z(size,      dst_map_);
 
@@ -99,6 +102,16 @@
     time = t1.delta();
   }
 
+  void diag()
+  {
+    length_type const size = 256;
+
+    Vector<T, src_block_t>   A(size, T(), src_map_);
+    Vector<T, dst_block_t>   Z(size,      dst_map_);
+
+    vsip::impl::diagnose_eval_list_std(Z, A);
+  }
+
   t_vcopy(SrcMapT src_map, DstMapT dst_map, bool pre_sync)
     : src_map_(src_map), dst_map_(dst_map), pre_sync_(pre_sync)
   {}
@@ -119,7 +132,7 @@
 	  typename SrcMapT,
 	  typename DstMapT,
 	  typename ParAssignImpl>
-struct t_vcopy<T, SrcMapT, DstMapT, Impl_pa<ParAssignImpl> >
+struct t_vcopy<T, SrcMapT, DstMapT, Impl_pa<ParAssignImpl> > : Benchmark_base
 {
   char* what() { return "t_vcopy<..., Impl_pa>"; }
   int ops_per_point(length_type)  { return 1; }
@@ -187,6 +200,7 @@
 	  typename DstMapT,
 	  typename ParAssignImpl>
 struct t_vcopy<T, SrcMapT, DstMapT, Impl_pa_na<ParAssignImpl> >
+  : Benchmark_base
 {
   char* what() { return "t_vcopy<..., Impl_pa_na>"; }
   int ops_per_point(length_type)  { return 1; }
@@ -251,7 +265,7 @@
 template <typename T,
 	  typename SrcMapT,
 	  typename DstMapT>
-struct t_vcopy<T, SrcMapT, DstMapT, Impl_sa>
+struct t_vcopy<T, SrcMapT, DstMapT, Impl_sa> : Benchmark_base
 {
   char* what() { return "t_vcopy<..., Impl_sa>"; }
   int ops_per_point(length_type)  { return 1; }
@@ -306,6 +320,75 @@
 
 
 /***********************************************************************
+  Vector copy - use memcpy
+***********************************************************************/
+
+template <typename T>
+struct t_vcopy<T, Local_map, Local_map, Impl_memcpy> : Benchmark_base
+{
+  typedef Local_map SrcMapT;
+  typedef Local_map DstMapT;
+  typedef Dense<1, T, row1_type, SrcMapT> src_block_t;
+  typedef Dense<1, T, row1_type, DstMapT> dst_block_t;
+  
+  char* what() { return "t_vcopy<..., Impl_memcpy>"; }
+  int ops_per_point(length_type)  { return 1; }
+  int riob_per_point(length_type) { return 1*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 1*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    Vector<T, src_block_t>   A(size, T(), src_map_);
+    Vector<T, dst_block_t>   Z(size,      dst_map_);
+
+    for (index_type i=0; i<A.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(A, 0, i);
+      A.local().put(i, T(g_i));
+    }
+    
+    vsip::impl::profile::Timer t1;
+
+    if (pre_sync_)
+      vsip::impl::default_communicator().barrier();
+
+    {
+      impl::Ext_data<src_block_t> src_ext(A.block());
+      impl::Ext_data<dst_block_t> dst_ext(Z.block());
+    
+      t1.start();
+      for (index_type l=0; l<loop; ++l)
+	memcpy(dst_ext.data(), src_ext.data(), size*sizeof(T));
+      t1.stop();
+    }
+
+    for (index_type i=0; i<Z.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(Z, 0, i);
+      test_assert(equal(Z.local().get(i), T(g_i)));
+    }
+    
+    time = t1.delta();
+  }
+
+  void diag()
+  {
+  }
+
+  t_vcopy(SrcMapT src_map, DstMapT dst_map, bool pre_sync)
+    : src_map_(src_map), dst_map_(dst_map), pre_sync_(pre_sync)
+  {}
+
+  // Member data.
+  SrcMapT	src_map_;
+  DstMapT	dst_map_;
+  bool          pre_sync_;
+};
+
+
+
+/***********************************************************************
   Local/Distributed wrappers
 ***********************************************************************/
 
@@ -378,6 +461,7 @@
 #elif VSIP_IMPL_PAR_SERVICE == 2
   case  4: loop(t_vcopy_root<float, Impl_pa<Pa> >()); break;
 #endif
+  case  5: loop(t_vcopy_local<float, Impl_memcpy>()); break;
 
   case 10: loop(t_vcopy_redist<float, Impl_assign>('1', '1', ps)); break;
   case 11: loop(t_vcopy_redist<float, Impl_assign>('1', 'a', ps));  break;
@@ -476,6 +560,8 @@
   case 0:
     std::cout
       << "copy -- vector copy\n"
+      << "   -1 -- local copy (A = B))\n"
+      << "   -5 -- local copy (memcpy))\n"
       << " Using assignment (A = B):\n"
       << "  -10 -- float root copy      (root -> root)\n"
       << "  -11 -- float scatter        (root -> all)\n"
Index: benchmarks/loop.hpp
===================================================================
--- benchmarks/loop.hpp	(revision 163254)
+++ benchmarks/loop.hpp	(working copy)
@@ -81,7 +81,8 @@
 {
   steady_mode,
   sweep_mode,
-  single_mode
+  single_mode,
+  diag_mode
 };
 
 enum range_type
@@ -93,7 +94,8 @@
 enum prog_type
 {
   geometric,
-  linear
+  linear,
+  userfile
 };
 
 
@@ -126,7 +128,8 @@
     what_        (0),
     show_loop_   (false),
     show_time_   (false),
-    mode_        (sweep_mode)
+    mode_        (sweep_mode),
+    m_array_     ()
   {}
 
   template <typename Functor>
@@ -139,6 +142,9 @@
   void single(Functor func);
 
   template <typename Functor>
+  void diag(Functor func);
+
+  template <typename Functor>
   void operator()(Functor func);
 
   template <typename Functor>
@@ -150,8 +156,8 @@
 
   // Member data.
 public:
-  unsigned	start_;		// loop start power-of-two
-  unsigned	stop_;		// loop stop power-of-two
+  unsigned	start_;		// loop start "i-value"
+  unsigned	stop_;		// loop stop "i-value"
   int	 	cal_;		// calibration power-of-two
   bool          do_cal_;	// perform calibration
   bool          fix_loop_;	// use fixed loop count for each size.
@@ -171,10 +177,24 @@
   bool          show_loop_;
   bool          show_time_;
   bench_mode    mode_;
+  std::vector<unsigned> m_array_;
 };
 
 
 
+struct Benchmark_base
+{
+  char const* what() { return "*unknown*"; }
+  int ops_per_point(vsip::length_type) { return -1; }
+  int riob_per_point(vsip::length_type) { return -1; }
+  int wiob_per_point(vsip::length_type) { return -1; }
+  int mem_per_point(vsip::length_type) { return -1; }
+
+  void diag() { std::cout << "no diag\n"; }
+};
+
+
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -230,11 +250,15 @@
   unsigned mid = (start_ + stop_) / 2;
   switch ( progression_ )
   {
+  case userfile:
+    return m_array_[i];
+
   case linear:
     if (range_ == centered_range)
       return center_ + prog_scale_ * (i-mid);
     else 
       return prog_scale_ * i;
+
   case geometric:
   default:
     if (range_ == centered_range)
@@ -286,8 +310,11 @@
   {
     float factor;
     float factor_thresh = 1.05;
+    
+    size_t old_loop;
     do 
     {
+      old_loop = loop;
       BARRIER(comm);
       fcn(M, loop, time);
       BARRIER(comm);
@@ -306,7 +333,7 @@
       // printf("%d: time: %f  factor: %f  loop: %d\n", rank,time,factor,loop);
       if ( loop == 0 ) 
         loop = 1; 
-    } while (factor >= factor_thresh);
+    } while (factor >= factor_thresh && loop > old_loop);
   }
 
   if (rank == 0)
@@ -565,6 +592,19 @@
 
 template <typename Functor>
 inline void
+Loop1P::diag(Functor fcn)
+{
+  COMMUNICATOR_TYPE& comm  = DEFAULT_COMMUNICATOR();
+
+  BARRIER(comm);
+  fcn.diag();
+  BARRIER(comm);
+}
+
+
+
+template <typename Functor>
+inline void
 Loop1P::operator()(
   Functor fcn)
 {
@@ -572,6 +612,8 @@
     this->steady(fcn);
   else if (mode_ == single_mode)
     this->single(fcn);
+  else if (mode_ == diag_mode)
+    this->diag(fcn);
   else
     this->sweep(fcn);
 }
Index: benchmarks/vmul.cpp
===================================================================
--- benchmarks/vmul.cpp	(revision 163254)
+++ benchmarks/vmul.cpp	(working copy)
@@ -67,9 +67,27 @@
   case  31: loop(t_vmul_ip1<float>()); break;
   case  32: loop(t_vmul_ip1<complex<float> >()); break;
 
+  // Double-precision
+
+  case 101: loop(t_vmul1<double>()); break;
+  case 102: loop(t_vmul1<complex<double> >()); break;
+#ifdef VSIP_IMPL_SOURCERY_VPP
+  case 103: loop(t_vmul2<complex<double>, impl::Cmplx_inter_fmt>()); break;
+  case 104: loop(t_vmul2<complex<double>, impl::Cmplx_split_fmt>()); break;
+#endif
+  case 105: loop(t_rcvmul1<double>()); break;
+
+  case 111: loop(t_svmul1<double,          double>()); break;
+  case 112: loop(t_svmul1<double,          complex<double> >()); break;
+  case 113: loop(t_svmul1<complex<double>, complex<double> >()); break;
+
+  case 131: loop(t_vmul_ip1<double>()); break;
+  case 132: loop(t_vmul_ip1<complex<double> >()); break;
+
   case 0:
     std::cout
       << "vmul -- vector multiplication\n"
+      << "single-precision:\n"
       << " Vector-Vector:\n"
       << "   -1 -- Vector<        float > * Vector<        float >\n"
       << "   -2 -- Vector<complex<float>> * Vector<complex<float>>\n"
@@ -88,6 +106,9 @@
       << "  -22 -- t_vmul_dom1\n"
       << "  -31 -- t_vmul_ip1\n"
       << "  -32 -- t_vmul_ip1\n"
+      << "\ndouble-precision:\n"
+      << "  (101-113)\n"
+      << "  (131-132)\n"
       ;
 
   default:
Index: benchmarks/vma.cpp
===================================================================
--- benchmarks/vma.cpp	(revision 163254)
+++ benchmarks/vma.cpp	(working copy)
@@ -22,6 +22,9 @@
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip/opt/simd/vaxpy.hpp>
+#include <vsip/opt/diag/eval.hpp>
 
 #include <vsip_csl/test-storage.hpp>
 #include "benchmarks.hpp"
@@ -34,11 +37,51 @@
   Definitions - vector element-wise fused multiply-add
 ***********************************************************************/
 
+template <typename T1,
+	  typename T2>
+struct Ops2_info
+{
+  static unsigned int const div = 1;
+  static unsigned int const sqr = 1;
+  static unsigned int const mul = 1;
+  static unsigned int const add = 1;
+};
+
+
+
+template <typename T>
+struct Ops2_info<T, complex<T> >
+{
+  static unsigned int const div = 6 + 3 + 2;
+  static unsigned int const mul = 2;
+  static unsigned int const add = 1;
+};
+
+
+
+template <typename T>
+struct Ops2_info<complex<T>, T >
+{
+  static unsigned int const div = 2;
+  static unsigned int const mul = 2;
+  static unsigned int const add = 1;
+};
+
+template <typename T>
+struct Ops2_info<complex<T>, complex<T> >
+{
+  static unsigned int const div = 6 + 3 + 2;
+  static unsigned int const mul = 4 + 2;
+  static unsigned int const add = 2;
+};
+
+
+
 template <typename T,
 	  dimension_type DimA,
 	  dimension_type DimB,
 	  dimension_type DimC>
-struct t_vma
+struct t_vma : Benchmark_base
 {
   char* what() { return "t_vma"; }
   int ops_per_point(length_type)
@@ -67,20 +110,36 @@
     
     time = t1.delta();
   }
+
+  void diag()
+  {
+    length_type const size = 256;
+
+    Storage<DimA, T> A(Domain<1>(size), T(3));
+    Storage<DimB, T> B(Domain<1>(size), T(4));
+    Storage<DimC, T> C(Domain<1>(size), T(5));
+    Vector<T>        X(size, T(0));
+
+    vsip::impl::diagnose_eval_list_std(X, A.view * B.view + C.view);
+  }
 };
 
 
 
 // In-place multiply-add, aka AXPY (Y = A*X + Y)
 
-template <typename T,
+template <typename TA,
+	  typename TB,
 	  dimension_type DimA,
 	  dimension_type DimB>
-struct t_vma_ip
+struct t_vma_ip : Benchmark_base
 {
+  typedef typename Promotion<TA, TB>::type T;
+
   char* what() { return "t_vma_ip"; }
   int ops_per_point(length_type)
-    { return vsip::impl::Ops_info<T>::mul + vsip::impl::Ops_info<T>::add; }
+  { return Ops2_info<TA, TB>::mul + Ops2_info<T, T>::add; }
+
   int riob_per_point(length_type) { return 2*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 3*sizeof(T); }
@@ -88,9 +147,9 @@
   void operator()(length_type size, length_type loop, float& time)
     VSIP_IMPL_NOINLINE
   {
-    Storage<DimA, T> A(Domain<1>(size), T(0));
-    Storage<DimB, T> B(Domain<1>(size), T(0));
-    Vector<T>        X(size, T(5));
+    Storage<DimA, TA> A(Domain<1>(size), TA(0));
+    Storage<DimB, TB> B(Domain<1>(size), TB(0));
+    Vector<T>         X(size, T(5));
 
     vsip::impl::profile::Timer t1;
     
@@ -99,8 +158,8 @@
       X += A.view * B.view;
     t1.stop();
 
-    A.view = T(3);
-    B.view = T(4);
+    A.view = TA(3);
+    B.view = TB(4);
 
     X += A.view * B.view;
     
@@ -109,10 +168,137 @@
     
     time = t1.delta();
   }
+
+  void diag()
+  {
+    length_type const size = 256;
+
+    Storage<DimA, TA> A(Domain<1>(size), TA(0));
+    Storage<DimB, TB> B(Domain<1>(size), TB(0));
+    Vector<T>         X(size, T(5));
+
+    vsip::impl::diagnose_eval_list_std(X, X + A.view * B.view);
+  }
 };
 
 
 
+
+template <typename T>
+struct t_vma_cSC : Benchmark_base
+{
+  char* what() { return "t_vma_cSC"; }
+  int ops_per_point(length_type)
+  {
+    return Ops2_info<T, complex<T> >::mul +
+	   Ops2_info<complex<T>, complex<T> >::add;
+  }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    complex<T>          a = complex<T>(3, 0);
+    Vector<T>           B(size, T(4));
+    Vector<complex<T> > C(size, complex<T>(5, 0));
+    Vector<complex<T> > X(size, complex<T>(0, 0));
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      X = a * B + C;
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(X.get(i), complex<T>(3*4+5, 0)));
+    
+    time = t1.delta();
+  }
+
+  void diag()
+  {
+    length_type const size = 256;
+
+    complex<T>          a = complex<T>(3, 0);
+    Vector<T>           B(size, T(4));
+    Vector<complex<T> > C(size, complex<T>(5, 0));
+    Vector<complex<T> > X(size, complex<T>(0, 0));
+
+    vsip::impl::diagnose_eval_list_std(X, a * B + C);
+  }
+};
+
+
+
+template <typename T>
+struct t_vma_cSC_simd : Benchmark_base
+{
+  char* what() { return "t_vma_cSC_simd"; }
+  int ops_per_point(length_type)
+  {
+    return Ops2_info<T, complex<T> >::mul +
+	   Ops2_info<complex<T>, complex<T> >::add;
+  }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    using vsip::impl::Ext_data;
+
+    typedef Dense<1, T>           sblock_type;
+    typedef Dense<1, complex<T> > cblock_type;
+
+    complex<T>          a = complex<T>(3, 0);
+    Vector<T, sblock_type>          B(size, T(4));
+    Vector<complex<T>, cblock_type> C(size, complex<T>(5, 0));
+    Vector<complex<T>, cblock_type> X(size, complex<T>(0, 0));
+
+    vsip::impl::profile::Timer t1;
+
+    {
+      Ext_data<sblock_type> B_ext(B.block());
+      Ext_data<cblock_type> C_ext(C.block());
+      Ext_data<cblock_type> X_ext(X.block());
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      vsip::impl::simd::vma_cSC(a, B_ext.data(), C_ext.data(), X_ext.data(),
+				size);
+    t1.stop();
+    }
+    
+    for (index_type i=0; i<size; ++i)
+    {
+      if (!equal(X.get(i), complex<T>(3*4+5, 0)))
+	std::cout << i << " = " << X.get(i) << std::endl;
+      test_assert(equal(X.get(i), complex<T>(3*4+5, 0)));
+    }
+    
+    time = t1.delta();
+  }
+
+  void diag()
+  {
+    using vsip::impl::simd::Is_algorithm_supported;
+    using vsip::impl::simd::Alg_vma_cSC;
+
+    static bool const Is_vectorized =
+      Is_algorithm_supported<std::complex<T>, false, Alg_vma_cSC>::value;
+
+    std::cout << "is_vectorized: "
+	      << (Is_vectorized ? "yes" : "no")
+	      << std::endl;
+  }
+};
+
+
+
 void
 defaults(Loop1P&)
 {
@@ -123,22 +309,36 @@
 int
 test(Loop1P& loop, int what)
 {
+  typedef float           SF;
+  typedef complex<float>  CF;
+  typedef double          SD;
+  typedef complex<double> CD;
+
   switch (what)
   {
-  case  1: loop(t_vma<float, 1, 1, 1>()); break;
-  case  2: loop(t_vma<float, 0, 1, 1>()); break;
-  case  3: loop(t_vma<float, 0, 1, 0>()); break;
+  case   1: loop(t_vma<SF, 1, 1, 1>()); break;
+  case   2: loop(t_vma<SF, 0, 1, 1>()); break;
+  case   3: loop(t_vma<SF, 0, 1, 0>()); break;
 
-  case 11: loop(t_vma<complex<float>, 1, 1, 1>()); break;
-  case 12: loop(t_vma<complex<float>, 0, 1, 1>()); break;
-  case 13: loop(t_vma<complex<float>, 0, 1, 0>()); break;
+  case  11: loop(t_vma<CF, 1, 1, 1>()); break;
+  case  12: loop(t_vma<CF, 0, 1, 1>()); break;
+  case  13: loop(t_vma<CF, 0, 1, 0>()); break;
 
-  case 21: loop(t_vma_ip<float, 1, 1>()); break;
-  case 22: loop(t_vma_ip<float, 0, 1>()); break;
+  case  21: loop(t_vma_ip<SF, SF, 1, 1>()); break;
+  case  22: loop(t_vma_ip<SF, SF, 0, 1>()); break;
 
-  case 31: loop(t_vma_ip<complex<float>, 1, 1>()); break;
-  case 32: loop(t_vma_ip<complex<float>, 0, 1>()); break;
+  case  31: loop(t_vma_ip<CF, CF, 1, 1>()); break;
+  case  32: loop(t_vma_ip<CF, CF, 0, 1>()); break;
 
+  case  41: loop(t_vma_ip<CF, SF, 0, 1>()); break;
+
+  case 141: loop(t_vma_ip<CD, SD, 0, 1>()); break;
+
+  case 201: loop(t_vma_cSC<SF>()); break;
+  case 202: loop(t_vma_cSC_simd<SF>()); break;
+  case 203: loop(t_vma_cSC<SD>()); break;
+  case 204: loop(t_vma_cSC_simd<SD>()); break;
+
   default:
     return 0;
   }
Index: benchmarks/main.cpp
===================================================================
--- benchmarks/main.cpp	(revision 163254)
+++ benchmarks/main.cpp	(working copy)
@@ -15,6 +15,7 @@
   Included Files
 ***********************************************************************/
 
+#include <fstream>
 #include <iostream>
 #if defined(_MC_EXEC)
 #  include <unistd.h>
@@ -97,6 +98,8 @@
       loop.metric_ = data_per_sec;
     else if (!strcmp(argv[i], "-lat"))
       loop.metric_ = secs_per_pt;
+    else if (!strcmp(argv[i], "-geom"))
+      loop.progression_ = geometric;
     else if (!strcmp(argv[i], "-linear"))
     {
       loop.progression_ = linear;
@@ -107,6 +110,18 @@
       loop.range_ = centered_range;
       loop.center_ = atoi(argv[++i]);
     }
+    else if (!strcmp(argv[i], "-mfile"))
+    {
+      loop.progression_ = userfile;
+      char const* filename = argv[++i];
+      std::ifstream file(filename);
+      unsigned value;
+      while (file >> value)
+	loop.m_array_.push_back(value);
+      loop.cal_   = 0;
+      loop.start_ = 0;
+      loop.stop_  = loop.m_array_.size()-1;
+    }
     else if (!strcmp(argv[i], "-mem"))
       loop.lhs_ = lhs_mem;
     else if (!strcmp(argv[i], "-prof"))
@@ -117,6 +132,8 @@
       loop.show_time_ = true;
     else if (!strcmp(argv[i], "-steady"))
       loop.mode_ = steady_mode;
+    else if (!strcmp(argv[i], "-diag"))
+      loop.mode_ = diag_mode;
     else if (!strcmp(argv[i], "-nocal"))
       loop.do_cal_ = false;
     else if (!strcmp(argv[i], "-single"))
Index: benchmarks/vmul.hpp
===================================================================
--- benchmarks/vmul.hpp	(revision 163254)
+++ benchmarks/vmul.hpp	(working copy)
@@ -23,6 +23,7 @@
 #include <vsip/random.hpp>
 #include <vsip/selgen.hpp>
 #include <vsip/core/setup_assign.hpp>
+#include <vsip/opt/diag/eval.hpp>
 
 #include "benchmarks.hpp"
 
@@ -102,7 +103,7 @@
 // This is equivalent to t_vmul1<T, Local_map>.
 
 template <typename T>
-struct t_vmul1_nonglobal
+struct t_vmul1_nonglobal : Benchmark_base
 {
   char* what() { return "t_vmul1_nonglobal"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
@@ -148,8 +149,10 @@
 template <typename T,
 	  typename MapT = Local_map,
 	  typename SP   = No_barrier>
-struct t_vmul1
+struct t_vmul1 : Benchmark_base
 {
+  typedef Dense<1, T, row1_type, MapT> block_type;
+
   char* what() { return "t_vmul1"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
   int riob_per_point(length_type) { return 2*sizeof(T); }
@@ -159,8 +162,6 @@
   void operator()(length_type size, length_type loop, float& time)
     VSIP_IMPL_NOINLINE
   {
-    typedef Dense<1, T, row1_type, MapT> block_type;
-
     MapT map = create_map<1, MapT>();
 
     Vector<T, block_type> A(size, T(), map);
@@ -193,6 +194,19 @@
     
     time = t1.delta();
   }
+
+  void diag()
+  {
+    length_type const size = 256;
+
+    MapT map = create_map<1, MapT>();
+
+    Vector<T, block_type> A(size, T(), map);
+    Vector<T, block_type> B(size, T(), map);
+    Vector<T, block_type> C(size,      map);
+
+    vsip::impl::diagnose_eval_list_std(C, A * B);
+  }
 };
 
 
@@ -204,7 +218,7 @@
 template <typename T,
 	  typename MapT = Local_map,
 	  typename SP   = No_barrier>
-struct t_vmul1_local
+struct t_vmul1_local : Benchmark_base
 {
   char* what() { return "t_vmul1"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
@@ -255,7 +269,7 @@
 template <typename T,
 	  typename MapT = Local_map,
 	  typename SP   = No_barrier>
-struct t_vmul1_early_local
+struct t_vmul1_early_local : Benchmark_base
 {
   char* what() { return "t_vmul1_early_local"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
@@ -309,7 +323,7 @@
 template <typename T,
 	  typename MapT = Local_map,
 	  typename SP   = No_barrier>
-struct t_vmul1_sa
+struct t_vmul1_sa : Benchmark_base
 {
   char* what() { return "t_vmul1_sa"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
@@ -357,7 +371,7 @@
 
 
 template <typename T>
-struct t_vmul_ip1
+struct t_vmul_ip1 : Benchmark_base
 {
   char* what() { return "t_vmul_ip1"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
@@ -393,7 +407,7 @@
 
 
 template <typename T>
-struct t_vmul_dom1
+struct t_vmul_dom1 : Benchmark_base
 {
   char* what() { return "t_vmul_dom1"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
@@ -434,7 +448,7 @@
 
 #ifdef VSIP_IMPL_SOURCERY_VPP
 template <typename T, typename ComplexFmt>
-struct t_vmul2
+struct t_vmul2 : Benchmark_base
 {
   char* what() { return "t_vmul2"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
@@ -476,7 +490,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_rcvmul1
+struct t_rcvmul1 : Benchmark_base
 {
   char* what() { return "t_rcvmul1"; }
   int ops_per_point(length_type)  { return 2*vsip::impl::Ops_info<T>::mul; }
@@ -509,6 +523,17 @@
     
     time = t1.delta();
   }
+
+  void diag()
+  {
+    length_type const size = 256;
+
+    Vector<complex<T> > A(size);
+    Vector<T>           B(size);
+    Vector<complex<T> > C(size);
+
+    vsip::impl::diagnose_eval_list_std(C, B * A);
+  }
 };
 
 
@@ -517,7 +542,7 @@
 
 template <typename ScalarT,
 	  typename T>
-struct t_svmul1
+struct t_svmul1 : Benchmark_base
 {
   char* what() { return "t_svmul1"; }
   int ops_per_point(length_type)
@@ -553,6 +578,18 @@
     
     time = t1.delta();
   }
+
+  void diag()
+  {
+    length_type const size = 256;
+
+    Vector<T>   A(size, T());
+    Vector<T>   C(size);
+
+    ScalarT alpha = ScalarT(3);
+
+    vsip::impl::diagnose_eval_list_std(C, alpha * A);
+  }
 };
 
 
@@ -560,7 +597,7 @@
 // Benchmark scalar-view vector multiply (Scalar * View)
 
 template <typename T>
-struct t_svmul2
+struct t_svmul2 : Benchmark_base
 {
   char* what() { return "t_svmul2"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
@@ -595,7 +632,7 @@
 // Benchmark scalar-view vector multiply w/literal (Scalar * View)
 
 template <typename T>
-struct t_svmul3
+struct t_svmul3 : Benchmark_base
 {
   char* what() { return "t_svmul3"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
@@ -631,7 +668,7 @@
 	  typename DataMapT  = Local_map,
 	  typename CoeffMapT = Local_map,
 	  typename SP        = No_barrier>
-struct t_svmul4
+struct t_svmul4 : Benchmark_base
 {
   char* what() { return "t_svmul4"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
Index: benchmarks/fftm.cpp
===================================================================
--- benchmarks/fftm.cpp	(revision 163254)
+++ benchmarks/fftm.cpp	(working copy)
@@ -45,10 +45,10 @@
 
 
 
-int
+float
 fft_ops(length_type len)
 {
-  return int(5 * len * std::log((float)len) / std::log(2.f));
+  return 5.0 * len * std::log((double)len) / std::log(2.0);
 }
 
 
@@ -73,12 +73,12 @@
 
 template <typename T,
 	  int      SD>
-struct t_fftm<T, Impl_op, SD>
+struct t_fftm<T, Impl_op, SD> : Benchmark_base
 {
   static int const elem_per_point = 2;
 
   char* what() { return "t_fftm<T, Impl_op, SD>"; }
-  int ops(length_type rows, length_type cols)
+  float ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
 
   void fftm(length_type rows, length_type cols, length_type loop, float& time)
@@ -125,12 +125,12 @@
 
 template <typename T,
 	  int      SD>
-struct t_fftm<T, Impl_ip, SD>
+struct t_fftm<T, Impl_ip, SD> : Benchmark_base
 {
   static int const elem_per_point = 1;
 
   char* what() { return "t_fftm<T, Impl_ip, SD>"; }
-  int ops(length_type rows, length_type cols)
+  float ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
 
   void fftm(length_type rows, length_type cols, length_type loop, float& time)
@@ -177,12 +177,12 @@
 
 template <typename T,
 	  int      SD>
-struct t_fftm<T, Impl_pop, SD>
+struct t_fftm<T, Impl_pop, SD> : Benchmark_base
 {
   static int const elem_per_point = 1;
 
   char* what() { return "t_fftm<T, Impl_pop, SD>"; }
-  int ops(length_type rows, length_type cols)
+  float ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
 
   void fftm(length_type rows, length_type cols, length_type loop, float& time)
@@ -244,12 +244,12 @@
 
 template <typename T,
 	  int      SD>
-struct t_fftm<T, Impl_pip1, SD>
+struct t_fftm<T, Impl_pip1, SD> : Benchmark_base
 {
   static int const elem_per_point = 1;
 
   char* what() { return "t_fftm<T, Impl_ip, SD>"; }
-  int ops(length_type rows, length_type cols)
+  float ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
 
   void fftm(length_type rows, length_type cols, length_type loop, float& time)
@@ -313,12 +313,12 @@
 
 template <typename T,
 	  int      SD>
-struct t_fftm<T, Impl_pip2, SD>
+struct t_fftm<T, Impl_pip2, SD> : Benchmark_base
 {
   static int const elem_per_point = 1;
 
   char* what() { return "t_fftm<T, Impl_ip, SD>"; }
-  int ops(length_type rows, length_type cols)
+  float ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
 
   void fftm(length_type rows, length_type cols, length_type loop, float& time)
@@ -395,12 +395,12 @@
 
 template <typename T,
 	  int      SD>
-struct t_fftm<T, Impl_bv, SD>
+struct t_fftm<T, Impl_bv, SD> : Benchmark_base
 {
   static int const elem_per_point = 2;
 
   char* what() { return "t_fftm<T, Impl_bv, SD>"; }
-  int ops(length_type rows, length_type cols)
+  float ops(length_type rows, length_type cols)
     { return SD == row ? rows * fft_ops(cols) : cols * fft_ops(rows); }
 
   void fftm(length_type rows, length_type cols, length_type loop, float& time)
@@ -448,7 +448,7 @@
   static int const elem_per_point = base_type::elem_per_point;
 
   char* what() { return "t_fftm_fix_rows"; }
-  int ops_per_point(length_type cols)
+  float ops_per_point(length_type cols)
     { return (int)(this->ops(rows_, cols) / cols); }
   int riob_per_point(length_type) { return -1*(int)sizeof(T); }
   int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
@@ -480,7 +480,7 @@
   static int const elem_per_point = base_type::elem_per_point;
 
   char* what() { return "t_fftm_fix_cols"; }
-  int ops_per_point(length_type rows)
+  float ops_per_point(length_type rows)
     { return (int)(this->ops(rows, cols_) / rows); }
   int riob_per_point(length_type) { return -1*sizeof(T); }
   int wiob_per_point(length_type) { return -1*sizeof(T); }
@@ -522,7 +522,8 @@
 {
   length_type p = loop.user_param_;
 
-  typedef complex<float> Cf;
+  typedef complex<float>  Cf;
+  typedef complex<double> Cd;
 
   switch (what)
   {
@@ -553,6 +554,20 @@
 
   case 21: loop(t_fftm_fix_rows<Cf, Impl_op,   row>(p, true)); break;
 
+  case 101: loop(t_fftm_fix_rows<Cd, Impl_op,   row>(p, false)); break;
+  case 102: loop(t_fftm_fix_rows<Cd, Impl_ip,   row>(p, false)); break;
+  case 103: loop(t_fftm_fix_rows<Cd, Impl_pop,  row>(p, false)); break;
+  case 104: loop(t_fftm_fix_rows<Cd, Impl_pip1, row>(p, false)); break;
+  case 105: loop(t_fftm_fix_rows<Cd, Impl_pip2, row>(p, false)); break;
+  case 106: loop(t_fftm_fix_rows<Cd, Impl_bv,   row>(p, false)); break;
+
+  case 111: loop(t_fftm_fix_cols<Cd, Impl_op,   row>(p, false)); break;
+  case 112: loop(t_fftm_fix_cols<Cd, Impl_ip,   row>(p, false)); break;
+  case 113: loop(t_fftm_fix_cols<Cd, Impl_pop,  row>(p, false)); break;
+  case 114: loop(t_fftm_fix_cols<Cd, Impl_pip1, row>(p, false)); break;
+  case 115: loop(t_fftm_fix_cols<Cd, Impl_pip2, row>(p, false)); break;
+  case 116: loop(t_fftm_fix_cols<Cd, Impl_bv,   row>(p, false)); break;
+
   default: return 0;
   }
   return 1;
Index: benchmarks/fft.cpp
===================================================================
--- benchmarks/fft.cpp	(revision 163254)
+++ benchmarks/fft.cpp	(working copy)
@@ -27,10 +27,10 @@
 using namespace vsip;
 
 
-int
+float
 fft_ops(length_type len)
 {
-  return int(5 * std::log((float)len) / std::log(2.f));
+  return 5.0 * std::log((double)len) / std::log(2.0);
 }
 
 
@@ -41,10 +41,10 @@
 
 template <typename T,
 	  int      no_times>
-struct t_fft_op
+struct t_fft_op : Benchmark_base
 {
-  char* what() { return "t_fft_op"; }
-  int ops_per_point(length_type len)  { return fft_ops(len); }
+  char const* what() { return "t_fft_op"; }
+  float ops_per_point(length_type len)  { return fft_ops(len); }
   int riob_per_point(length_type) { return -1*(int)sizeof(T); }
   int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
   int mem_per_point(length_type)  { return 1*sizeof(T); }
@@ -91,10 +91,10 @@
 
 template <typename T,
 	  int      no_times>
-struct t_fft_ip
+struct t_fft_ip : Benchmark_base
 {
-  char* what() { return "t_fft_ip"; }
-  int ops_per_point(length_type len)  { return fft_ops(len); }
+  char const* what() { return "t_fft_ip"; }
+  float ops_per_point(length_type len)  { return fft_ops(len); }
   int riob_per_point(length_type) { return -1*(int)sizeof(T); }
   int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
   int mem_per_point(length_type)  { return 1*sizeof(T); }
@@ -138,10 +138,10 @@
 
 template <typename T,
 	  int      no_times>
-struct t_fft_bv
+struct t_fft_bv : Benchmark_base
 {
-  char* what() { return "t_fft_bv"; }
-  int ops_per_point (length_type len) { return fft_ops(len); }
+  char const* what() { return "t_fft_bv"; }
+  float ops_per_point (length_type len) { return fft_ops(len); }
   int riob_per_point(length_type)     { return -1*(int)sizeof(T); }
   int wiob_per_point(length_type)     { return -1*(int)sizeof(T); }
   int mem_per_point (length_type)     { return 1*sizeof(T); }
@@ -216,6 +216,50 @@
   case 26: loop(t_fft_ip<complex<float>, patient>(true)); break;
   case 27: loop(t_fft_bv<complex<float>, patient>(true)); break;
 
+  // Double precision cases.
+
+  case 101: loop(t_fft_op<complex<double>, estimate>(false)); break;
+  case 102: loop(t_fft_ip<complex<double>, estimate>(false)); break;
+  case 103: loop(t_fft_bv<complex<double>, estimate>(false)); break;
+  case 105: loop(t_fft_op<complex<double>, estimate>(true)); break;
+  case 106: loop(t_fft_ip<complex<double>, estimate>(true)); break;
+  case 107: loop(t_fft_bv<complex<double>, estimate>(true)); break;
+
+  case 111: loop(t_fft_op<complex<double>, measure>(false)); break;
+  case 112: loop(t_fft_ip<complex<double>, measure>(false)); break;
+  case 113: loop(t_fft_bv<complex<double>, measure>(false)); break;
+  case 115: loop(t_fft_op<complex<double>, measure>(true)); break;
+  case 116: loop(t_fft_ip<complex<double>, measure>(true)); break;
+  case 117: loop(t_fft_bv<complex<double>, measure>(true)); break;
+
+  case 121: loop(t_fft_op<complex<double>, patient>(false)); break;
+  case 122: loop(t_fft_ip<complex<double>, patient>(false)); break;
+  case 123: loop(t_fft_bv<complex<double>, patient>(false)); break;
+  case 125: loop(t_fft_op<complex<double>, patient>(true)); break;
+  case 126: loop(t_fft_ip<complex<double>, patient>(true)); break;
+  case 127: loop(t_fft_bv<complex<double>, patient>(true)); break;
+
+  case 0:
+    std::cout
+      << "fft -- Fft (fast fourier transform)\n"
+      << "Single precision\n"
+      << " Planning effor: estimate (number of times = 1):\n"
+      << "   -1 -- op: out-of-place CC fwd fft\n"
+      << "   -2 -- ip: in-place     CC fwd fft\n"
+      << "   -3 -- bv: by-value     CC fwd fft\n"
+      << "   -4 -- op: out-of-place CC inv fft (w/scaling)\n"
+      << "   -5 -- ip: in-place     CC inv fft (w/scaling)\n"
+      << "   -6 -- bv: by-value     CC inv fft (w/scaling)\n"
+
+      << " Planning effor: measure (number of times = 15): 11-16\n"
+      << " Planning effor: pateint (number of times = 0): 21-26\n"
+
+      << "\nDouble precision\n"
+      << " Planning effor: estimate (number of times = 1): 101-106\n"
+      << " Planning effor: measure (number of times = 15): 111-116\n"
+      << " Planning effor: pateint (number of times = 0): 121-126\n"
+      ;
+
   default: return 0;
   }
   return 1;
Index: benchmarks/vmul_c.cpp
===================================================================
--- benchmarks/vmul_c.cpp	(revision 163254)
+++ benchmarks/vmul_c.cpp	(working copy)
@@ -24,6 +24,7 @@
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
+#include "benchmarks.hpp"
 
 using namespace vsip;
 using namespace vsip_csl;
@@ -79,7 +80,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_vmul1
+struct t_vmul1 : Benchmark_base
 {
   char* what() { return "t_vmul1"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
@@ -137,7 +138,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_vmul2
+struct t_vmul2 : Benchmark_base
 {
   char* what() { return "t_vmul2"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
@@ -192,7 +193,7 @@
 ***********************************************************************/
 
 template <typename T>
-struct t_svmul1
+struct t_svmul1 : Benchmark_base
 {
   char* what() { return "t_svmul1"; }
   int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
Index: benchmarks/mcopy.cpp
===================================================================
--- benchmarks/mcopy.cpp	(revision 163254)
+++ benchmarks/mcopy.cpp	(working copy)
@@ -25,6 +25,7 @@
 #include <vsip/map.hpp>
 #include <vsip/core/profile.hpp>
 #include <vsip/core/metaprogramming.hpp>
+#include <vsip/opt/diag/eval.hpp>
 
 #include <vsip_csl/plainblock.hpp>
 #include <vsip_csl/test.hpp>
@@ -73,7 +74,7 @@
 template <typename T,
 	  typename SrcBlock,
 	  typename DstBlock>
-struct t_mcopy<T, SrcBlock, DstBlock, Impl_assign>
+struct t_mcopy<T, SrcBlock, DstBlock, Impl_assign> : Benchmark_base
 {
   typedef typename SrcBlock::map_type src_map_type;
   typedef typename DstBlock::map_type dst_map_type;
@@ -90,7 +91,6 @@
     length_type const M = size;
     length_type const N = size;
 
-
     Matrix<T, SrcBlock>   A(M, N, T(), src_map_);
     Matrix<T, DstBlock>   Z(M, N,      dst_map_);
 
@@ -120,6 +120,17 @@
     time = t1.delta();
   }
 
+  void diag()
+  {
+    length_type const M = 256;
+    length_type const N = 256;
+
+    Matrix<T, SrcBlock>   A(M, N, T(), src_map_);
+    Matrix<T, DstBlock>   Z(M, N,      dst_map_);
+
+    vsip::impl::diagnose_eval_list_std(Z, A);
+  }
+
   t_mcopy(src_map_type src_map, dst_map_type dst_map)
     : src_map_(src_map),
       dst_map_(dst_map)
@@ -139,7 +150,7 @@
 template <typename T,
 	  typename SrcBlock,
 	  typename DstBlock>
-struct t_mcopy<T, SrcBlock, DstBlock, Impl_sa>
+struct t_mcopy<T, SrcBlock, DstBlock, Impl_sa> : Benchmark_base
 {
   typedef typename SrcBlock::map_type src_map_type;
   typedef typename DstBlock::map_type dst_map_type;
@@ -206,7 +217,7 @@
 template <typename T,
 	  typename SrcBlock,
 	  typename DstBlock>
-struct t_mcopy<T, SrcBlock, DstBlock, Impl_memcpy>
+struct t_mcopy<T, SrcBlock, DstBlock, Impl_memcpy> : Benchmark_base
 {
   typedef typename SrcBlock::map_type src_map_type;
   typedef typename DstBlock::map_type dst_map_type;
