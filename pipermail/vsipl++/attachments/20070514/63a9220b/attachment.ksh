Index: ChangeLog
===================================================================
--- ChangeLog	(revision 171243)
+++ ChangeLog	(working copy)
@@ -1,5 +1,21 @@
 2007-05-14  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/diag/fft.hpp: New file, diagnostics for Fft.
+	* src/vsip/core/fft.hpp (fft_facade): make Diagnose_fft friend.
+	  (fftm_facade): Likewise.
+	* benchmarks/fft.cpp: Have diag function use Diagnose_fft.
+	
+	* tests/fft_ext/fft_ext.cpp: Use test_assert instead of assert.
+	  Return EXIT_FAILURE instead of exit(-1) on failure.  -1 confuses
+	  qmtest.
+	* benchmarks/cell/fastconv.cpp: Add single-line fastconvolution
+	  case.
+	* benchmarks/fftw3/fft.cpp: Add split FFT benchmark case.
+	* benchmarks/fftm.cpp: Compute riob/wiob.  Fix mem_per_point calc.
+	* benchmarks/vmmul.cpp: Add diag function.  Add scaled variants.
+
+2007-05-14  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/simd/threshold.hpp (simd_thresh, simd_thresh0): Fix
 	  compilation error.  Make static inline.
 	* src/vsip/opt/simd/simd.hpp (AltiVec float load_scalar): Fix GHS
Index: src/vsip/core/fft.hpp
===================================================================
--- src/vsip/core/fft.hpp	(revision 171241)
+++ src/vsip/core/fft.hpp	(working copy)
@@ -66,6 +66,12 @@
 
 namespace impl
 {
+
+namespace diag_detail
+{
+struct Diagnose_fft;
+}
+
 namespace fft
 {
 /// The list of evaluators to be tried, in that specific order.
@@ -232,6 +238,7 @@
     return view_type(block);
   }
 #endif
+  friend class vsip::impl::diag_detail::Diagnose_fft;
 private:
   std::auto_ptr<fft::backend<D, I, O, axis, exponent> > backend_;
   workspace workspace_;
@@ -298,6 +305,7 @@
     return inout;
   }
 
+  friend class vsip::impl::diag_detail::Diagnose_fft;
 private:
   std::auto_ptr<impl::fft::backend<D, I, O, axis, exponent> > backend_;
   workspace workspace_;
Index: src/vsip/opt/diag/fft.hpp
===================================================================
--- src/vsip/opt/diag/fft.hpp	(revision 0)
+++ src/vsip/opt/diag/fft.hpp	(revision 0)
@@ -0,0 +1,210 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/diag/fft.hpp
+    @author  Jules Bergmann
+    @date    2007-03-27
+    @brief   VSIPL++ Library: Diagnostics for Fft.
+*/
+
+#ifndef VSIP_OPT_DIAG_FFT_HPP
+#define VSIP_OPT_DIAG_FFT_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <iomanip>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+
+
+
+namespace diag_detail
+{
+
+// Helper class to return the name corresponding to a dispatch tag.
+
+template <typename T> 
+struct Class_name
+{
+  static std::string name() { return "unknown"; }
+};
+
+#define VSIP_IMPL_CLASS_NAME(TYPE)				\
+  template <>							\
+  struct Class_name<TYPE> {					\
+    static std::string name() { return "" # TYPE; }		\
+  };
+
+VSIP_IMPL_CLASS_NAME(Direct_access_tag)
+VSIP_IMPL_CLASS_NAME(Reorder_access_tag)
+VSIP_IMPL_CLASS_NAME(Copy_access_tag)
+VSIP_IMPL_CLASS_NAME(Flexible_access_tag)
+VSIP_IMPL_CLASS_NAME(Bogus_access_tag)
+VSIP_IMPL_CLASS_NAME(Default_access_tag)
+
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_eq_order_unknown_stride_ok)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_eq_order_unit_stride_ok)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_eq_order_unit_stride_dense_ok)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_eq_order_unit_stride_align_ok)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_eq_order_different_stride)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_different_dim_order_but_both_dense)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_Eq_cmplx_different_dim_order)
+VSIP_IMPL_CLASS_NAME(choose_access::CA_General_different_complex_layout)
+
+VSIP_IMPL_CLASS_NAME(Cmplx_inter_fmt)
+VSIP_IMPL_CLASS_NAME(Cmplx_split_fmt)
+
+
+
+template <typename Fft>
+struct Fft_traits;
+
+template <template <typename, typename> class V,
+	  typename                            I,
+	  typename                            O,
+	  int                                 S,
+	  return_mechanism_type               R,
+	  unsigned                            N,
+	  alg_hint_type                       H>
+struct Fft_traits<Fft<V, I, O, S, R, N, H> >
+{
+  static dimension_type        const dim = impl::Dim_of_view<V>::dim;
+  static return_mechanism_type const rm  = R;
+};
+
+
+
+struct Diagnose_fft
+{
+  template <typename FftT>
+  static void diag(std::string name, FftT const& fft)
+  {
+    using diag_detail::Class_name;
+    using std::cout;
+    using std::endl;
+
+    typedef Fft_traits<FftT> traits;
+
+    bool inter_fp_ok;
+    bool split_fp_ok;
+
+    // Check if Backend supports interleaved unit-stride fastpath:
+    {
+      Rt_layout<1> ref;
+      ref.pack    = stride_unit_dense;
+      ref.order   = Rt_tuple(row1_type());
+      ref.complex = cmplx_inter_fmt;
+      ref.align   = 0;
+      Rt_layout<1> rtl_in(ref);
+      Rt_layout<1> rtl_out(ref);
+      fft.backend_.get()->query_layout(rtl_in, rtl_out);
+      inter_fp_ok = 
+	rtl_in.pack == ref.pack       && rtl_out.pack == ref.pack &&
+	// rtl_in.order == ref.order     && rtl_out.order == ref.order &&
+	rtl_in.complex == ref.complex && rtl_out.complex == ref.complex &&
+	!fft.backend_.get()->requires_copy(rtl_in);
+    }
+    // Check if Backend supports split unit-stride fastpath:
+    {
+      Rt_layout<1> ref;
+      ref.pack    = stride_unit_dense;
+      ref.order   = Rt_tuple(row1_type());
+      ref.complex = cmplx_split_fmt;
+      ref.align   = 0;
+      Rt_layout<1> rtl_in(ref);
+      Rt_layout<1> rtl_out(ref);
+      fft.backend_.get()->query_layout(rtl_in, rtl_out);
+      split_fp_ok = 
+	rtl_in.pack == ref.pack       && rtl_out.pack == ref.pack &&
+	// rtl_in.order == ref.order     && rtl_out.order == ref.order &&
+	rtl_in.complex == ref.complex && rtl_out.complex == ref.complex &&
+	!fft.backend_.get()->requires_copy(rtl_in);
+    }
+
+    cout << "diagnose_fft(" << name << ")" << endl
+	 << "  dim: " << traits::dim << endl
+	 << "  rm : " << (traits::rm == by_value ? "val" : "ref") << endl
+	 << "  be : " << fft.backend_.get()->name() << endl
+	 << "  inter_fastpath_ok : " << (inter_fp_ok ? "yes" : "no") << endl
+	 << "  split_fastpath_ok : " << (split_fp_ok ? "yes" : "no") << endl
+      ;
+  }
+
+  template <typename FftT,
+	    typename T,
+	    typename Block0,
+	    typename Block1>
+  static void diag_call(
+    std::string                            name,
+    FftT const&                            fft,
+    const_Vector<std::complex<T>, Block0>& in,
+    Vector<std::complex<T>, Block1>&       out)
+  {
+    using diag_detail::Class_name;
+    using std::cout;
+    using std::endl;
+
+    typedef Fft_traits<FftT> traits;
+
+    typedef typename Block_layout<Block0>::complex_type complex_type;
+    typedef Layout<1, row1_type, Stride_unit, complex_type> LP;
+
+    diag(name, fft);
+    cout << " Ext_data_cost<Block0, LP> : " 
+	 <<   Ext_data_cost<Block0, LP>::value << endl
+	 << " Ext_data_cost<Block1, LP> : " 
+	 <<   Ext_data_cost<Block1, LP>::value << endl
+      ;
+  }
+};
+
+} // namespace vsip::impl::diag_detail
+
+
+
+template <typename FftT>
+void
+diagnose_fft(std::string name, FftT const& fft)
+{
+  diag_detail::Diagnose_fft::diag<FftT>(name, fft);
+}
+
+
+
+template <typename FftT,
+	  typename InViewT,
+	  typename OutViewT>
+void
+diagnose_fft_call(
+  std::string name,
+  FftT const& fft,
+  InViewT&    in,
+  OutViewT&   out)
+{
+  typedef typename InViewT::value_type T;
+  diag_detail::Diagnose_fft::diag_call<FftT>(name, fft, in, out);
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_DIAG_FFT_HPP
Index: tests/fft_ext/fft_ext.cpp
===================================================================
--- tests/fft_ext/fft_ext.cpp	(revision 171241)
+++ tests/fft_ext/fft_ext.cpp	(working copy)
@@ -24,9 +24,11 @@
 #include <vsip/support.hpp>
 #include <vsip/signal.hpp>
 #include <vsip/math.hpp>
+#include <vsip_csl/test.hpp>
 
 using namespace std;
 using namespace vsip;
+using namespace vsip_csl;
 
 
 /***********************************************************************
@@ -119,7 +121,7 @@
   Vector<T2> out(test.size());
   out = t_fft(in);
 
-  assert(error_db(test, out) < -100);
+  test_assert(error_db(test, out) < -100);
 }
 
 
@@ -131,6 +133,7 @@
   if (ifile.fail()) 
   {
     cerr << "Failed to open file " << filename << endl;
+    test_assert(0);
     return;
   }
 
@@ -180,6 +183,7 @@
   if (ifile.fail()) 
   {
     cerr << "Failed to open file " << filename << endl;
+    test_assert(0);
     return;
   }
 
@@ -191,7 +195,7 @@
   ifile.getline(line, sizeof(line));
   istringstream (line) >> size >> scale >> ntimes; 
 
-  assert( (size / 2) * 2 == size );
+  test_assert( (size / 2) * 2 == size );
 
   Vector<complex<T> > input(size / 2 + 1);
   Vector<T> expected(size);
@@ -229,6 +233,7 @@
   if (ifile.fail()) 
   {
     cerr << "Failed to open file " << filename << endl;
+    test_assert(0);
     return;
   }
 
@@ -240,7 +245,7 @@
   ifile.getline(line, sizeof(line));
   istringstream (line) >> size >> scale >> ntimes; 
 
-  assert( (size / 2) * 2 == size );
+  test_assert( (size / 2) * 2 == size );
 
   Vector<T> input(size);
   Vector<complex<T> > expected(size / 2 + 1);
@@ -328,7 +333,7 @@
   else
   {
     std::cerr << "Invalid number of arguments." << std::endl;
-    exit(-1);
+    return EXIT_FAILURE;
   }
 
 
@@ -369,5 +374,5 @@
   }
 
 
-  exit (0);
+  return EXIT_SUCCESS;
 }
Index: benchmarks/cell/fastconv.cpp
===================================================================
--- benchmarks/cell/fastconv.cpp	(revision 171241)
+++ benchmarks/cell/fastconv.cpp	(working copy)
@@ -22,9 +22,11 @@
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
 #include <vsip/random.hpp>
-#include <vsip_csl/error_db.hpp>
+#include <vsip/opt/diag/eval.hpp>
 #include <vsip/opt/cbe/ppu/fastconv.hpp>
 
+#include <vsip_csl/error_db.hpp>
+
 #include "benchmarks.hpp"
 #include "alloc_block.hpp"
 #include "fastconv.hpp"
@@ -46,6 +48,7 @@
 struct ImplCbe_ip;	// interleaved fast-convolution on Cell, in-place
 template <typename ComplexFmt>
 struct ImplCbe_op;	// interleaved fast-convolution on Cell, out-of-place
+struct Impl4;		// Single-line fast-convolution
 template <bool transform_replica>
 struct ImplCbe_multi;	// interleaved fast-convolution on Cell, multiple
 
@@ -116,7 +119,6 @@
     { // Use scope to control lifetime of view.
 
     // Create the data cube.
-    // view2_type data(npulse, nrange, T(), map);
     view2_type data(*data_block);
     
     // Create the pulse replica
@@ -400,6 +402,168 @@
 
 
 /***********************************************************************
+  Impl4: Single expression fast-convolution.
+         (Identical to fastconv.cpp, but with huge page support).
+***********************************************************************/
+
+template <typename T>
+struct t_fastconv_base<T, Impl4> : fastconv_ops
+{
+  static length_type const num_args = 1;
+
+#if PARALLEL_FASTCONV
+  typedef Global_map<1>                    map1_type;
+  typedef Map<Block_dist, Whole_dist>      map2_type;
+#else
+  typedef Local_map  map1_type;
+  typedef Local_map  map2_type;
+#endif
+  typedef impl::dense_complex_type complex_type;
+
+  typedef typename Alloc_block<1, T, complex_type, map1_type>::block_type
+	  block1_type;
+  typedef typename Alloc_block<2, T, complex_type, map2_type>::block_type
+	  block2_type;
+
+  typedef Vector<T, block1_type> view1_type;
+  typedef Matrix<T, block2_type> view2_type;
+
+  // static int const no_times = 0; // FFTW_PATIENT
+  static int const no_times = 15; // not > 12 = FFT_MEASURE
+    
+  typedef Fftm<T, T, row, fft_fwd, by_value, no_times>
+               for_fftm_type;
+  typedef Fftm<T, T, row, fft_inv, by_value, no_times>
+	       inv_fftm_type;
+
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+#if PARALLEL_FASTCONV
+    processor_type np = num_processors();
+    map1_type map1;
+    map2_type map2 = map2_type(np, 1);
+#else
+    map1_type map1;
+    map2_type map2;
+#endif
+
+    block1_type* repl_block;
+    block2_type* data_block;
+
+    repl_block = alloc_block<1, T, complex_type>(nrange, mem_addr_, 0x0000000,
+					       map1);
+    data_block = alloc_block<2, T, complex_type>(Domain<2>(npulse, nrange),
+					       mem_addr_, nrange*sizeof(T),
+					       map2);
+
+    { // Use scope to control lifetime of view.
+
+    // Create the data cube.
+    view2_type data(*data_block);
+    view2_type chk(npulse, nrange, map2);
+    
+    // Create the pulse replica
+    view1_type replica(*repl_block);
+
+    // Create the FFT objects.
+    for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+    inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/nrange);
+
+    // Initialize
+    data    = T();
+    replica = T();
+
+
+    // Before fast convolution, convert the replica into the
+    // frequency domain
+    // for_fft(replica);
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      data = inv_fftm(vmmul<0>(replica, for_fftm(data)));
+    }
+    t1.stop();
+
+    // CHECK RESULT
+#if 0
+    typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times>
+	  	for_fft_type;
+
+    Rand<T> gen(0, 0);
+    for_fft_type for_fft(Domain<1>(nrange), 1.0);
+
+    data = gen.randu(npulse, nrange);
+    replica.put(0, T(1));
+    for_fft(replica);
+
+    chk = inv_fftm(vmmul<0>(replica, for_fftm(data)));
+
+    double error = error_db(data, chk);
+
+    test_assert(error < -100);
+#endif
+
+    time = t1.delta();
+    }
+
+    // Delete blocks after view has gone out of scope.  If we delete
+    // the blocks while the views are still live, they will corrupt
+    // memory when they try to decrement the blocks' reference counts.
+
+    delete repl_block;
+    delete data_block;
+  }
+
+  void diag()
+  {
+#if PARALLEL_FASTCONV
+    processor_type np = num_processors();
+    map2_type map = map2_type(np, 1);
+#else
+    map2_type map;
+#endif
+
+    length_type npulse = 16;
+    length_type nrange = 2048;
+
+    // Create the data cube.
+    view2_type data(npulse, nrange, map);
+
+    // Create the pulse replica
+    view1_type replica(nrange);
+
+    // Create the FFT objects.
+    for_fftm_type for_fftm(Domain<2>(npulse, nrange), 1.0);
+    inv_fftm_type inv_fftm(Domain<2>(npulse, nrange), 1.0/nrange);
+
+    vsip::impl::diagnose_eval_dispatch(
+      data, inv_fftm(vmmul<0>(replica, for_fftm(data))) );
+  }
+
+  t_fastconv_base()
+    : mem_addr_(0),
+      pages_   (9)
+  {
+    char const* mem_file = "/huge/fastconv.bin";
+
+    if (use_huge_pages_)
+      mem_addr_ = open_huge_pages(mem_file, pages_);
+    else
+      mem_addr_ = 0;
+  }
+
+  char*        mem_addr_;
+  unsigned int pages_;
+};
+
+
+
+/***********************************************************************
   Benchmark Driver
 ***********************************************************************/
 
@@ -426,7 +590,8 @@
   length_type param1 = loop.user_param_;
   switch (what)
   {
-  case  1: loop(t_fastconv_rf<T, ImplCbe>(param1)); break;
+  case  1: loop(t_fastconv_rf<T, Impl4>(param1)); break;
+  case  2: loop(t_fastconv_rf<T, ImplCbe>(param1)); break;
 
   case 11: loop(t_fastconv_rf<T, ImplCbe_op<Cif> >(param1));break;
   case 12: loop(t_fastconv_rf<T, ImplCbe_ip<Cif, true> >(param1));break;
@@ -443,7 +608,8 @@
     std::cout
       << "fastconv -- fast convolution benchmark for Cell BE\n"
       << " Sweeping pulse size:\n"
-      << "    -1 -- IP, native complex, distributed\n"
+      << "    -1 -- IP, native complex, distributed, single-expr\n"
+      << "    -2 -- IP, native complex, distributed, Fastconv object\n"
       << "\n"
       << "   -11 -- OP, inter complex,  non-dist\n"
       << "   -12 -- IP, inter complex,  non-dist, single FC\n"
Index: benchmarks/fftw3/fft.cpp
===================================================================
--- benchmarks/fftw3/fft.cpp	(revision 171241)
+++ benchmarks/fftw3/fft.cpp	(working copy)
@@ -1,6 +1,6 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved. */
 
-/** @file    benchmarks/fft_fftw3.cpp
+/** @file    benchmarks/fftw3/fft.cpp
     @author  Jules Bergmann
     @date    2006-10-19
     @brief   VSIPL++ Library: Benchmark for FFTW3 FFT.
@@ -68,6 +68,7 @@
 {
   typedef fftwf_plan plan_type;
 
+  // Plan 1-D interleaved-complex FFT
   static plan_type
   plan_dft_1d(
     length_type           size,
@@ -82,7 +83,24 @@
 			   dir, flags);
   }
 
+  // Plan N-D interleaved-complex FFT
   static plan_type
+  plan_dft(
+    dimension_type        D,
+    int const*            size,
+    complex<float> const* in,
+    complex<float>*       out,
+    int                   dir,
+    int                   flags)
+  {
+    return fftwf_plan_dft(D, size,
+			   (fftwf_complex*)in,
+			   (fftwf_complex*)out,
+			   dir, flags);
+  }
+
+  // Plan 1-D split-complex FFT
+  static plan_type
   plan_dft_1d(
     length_type                size,
     std::pair<float*, float*> const& in,
@@ -391,6 +409,90 @@
 
 
 /***********************************************************************
+  Out-of-place Benchmark driver (variant -- use N-D planner)
+***********************************************************************/
+
+template <typename T,
+	  typename ComplexFmt>
+struct t_fft_op_nd;
+
+template <typename T>
+struct t_fft_op_nd<T, Cmplx_inter_fmt> : Benchmark_base, fft_base<T>
+{
+  typedef Cmplx_inter_fmt ComplexFmt;
+
+  typedef Fftw_traits<T> traits;
+
+  char const* what() { return "t_fft_op_nd"; }
+  float ops_per_point(length_type len)  { return fft_ops(len); }
+  int riob_per_point(length_type) { return 1*(int)sizeof(T); }
+  int wiob_per_point(length_type) { return 1*(int)sizeof(T); }
+  int mem_per_point(length_type)  { return 2*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, ComplexFmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   A  (size, T());
+    Vector<T, block_type>   Z  (size);
+
+    
+    vsip::impl::profile::Timer t1;
+
+    this->reset();
+    {
+      Ext_data<block_type> ext_A(A.block(), SYNC_IN);
+      Ext_data<block_type> ext_Z(Z.block(), SYNC_OUT);
+
+      typename traits::plan_type p;
+
+      int size_array[1];
+      size_array[0] = size;
+
+      p = traits::plan_dft(1, size_array,
+			   ext_A.data(),
+			   ext_Z.data(),
+			   FFTW_FORWARD, flags_);
+
+      // FFTW3 may scribble
+
+      A = T(1);
+    
+      t1.start();
+      for (index_type l=0; l<loop; ++l)
+	traits::execute(p);
+      t1.stop();
+
+      traits::destroy_plan(p);
+    }
+    this->save(size);
+    
+    if (!equal(Z.get(0), T(scale_ ? 1 : size)))
+    {
+      std::cout << "t_fft_op_nd: ERROR" << std::endl;
+      std::cout << "  got      : " << Z.get(0) << std::endl;
+      std::cout << "  expected : " << T(scale_ ? 1 : size) << std::endl;
+    }
+    test_assert(equal(Z.get(0), T(scale_ ? 1 : size)));
+    
+    time = t1.delta();
+  }
+
+  t_fft_op_nd(bool scale, int flags, bool save_wisdom)
+    : fft_base<T>(save_wisdom),
+      scale_(scale),
+      flags_(flags)
+  {}
+
+  // Member data
+  bool scale_;
+  int  flags_;
+};
+
+
+
+/***********************************************************************
   In-place Benchmark driver
 ***********************************************************************/
 
@@ -568,7 +670,7 @@
   int pnt = FFTW_PATIENT;
   int exh = FFTW_EXHAUSTIVE;
 
-  bool sw = loop.user_param_ == 1;
+  bool sw = loop.user_param_ == 1; // save wisdom
 
   switch (what)
   {
@@ -582,6 +684,8 @@
   case  11: loop(t_fft_op<Cf, Cif>(false, msr, sw)); break;
   case  12: loop(t_fft_ip<Cf, Cif>(false, msr, sw)); break;
   case  14: loop(t_fft_op<Cf, Cif>(false, msr | FFTW_UNALIGNED, sw)); break;
+  case  15: loop(t_fft_op<Cf, Cif>(false, msr | FFTW_PRESERVE_INPUT, sw)); break;
+  case  16: loop(t_fft_op_nd<Cf, Cif>(false, msr | FFTW_PRESERVE_INPUT, sw)); break;
 
   case  21: loop(t_fft_op<Cf, Cif>(false, pnt, sw)); break;
   case  22: loop(t_fft_ip<Cf, Cif>(false, pnt, sw)); break;
@@ -614,6 +718,41 @@
   case 134: loop(t_fft_op<Cd, Cif>(false, exh | FFTW_UNALIGNED, sw)); break;
 #endif // VSIP_IMPL_PROVIDE_FFT_DOUBLE
 
+  case 0:
+    std::cout
+      << "fftw3/fft -- FFTW3 Fft (fast fourier transform)\n"
+      << "Single precision, Interleaved complex\n"
+      << " Planning effor: estimate:\n"
+      << "   -1 -- op: out-of-place CC fwd fft\n"
+      << "   -2 -- ip: in-place     CC fwd fft\n"
+      << "   -4 -- op: out-of-place CC fwd fft + UNALIGNED\n"
+      << " Planning effor: measure:\n"
+      << "  -11 -- op: out-of-place CC fwd fft\n"
+      << "  -12 -- ip: in-place     CC fwd fft\n"
+      << "  -14 -- op: out-of-place CC fwd fft + UNALIGNED\n"
+      << "  -15 -- op: out-of-place CC fwd fft + PRESERVE_INPUT\n"
+      << "  -16 -- op: out-of-place CC fwd fft + PRESERVE_INPUT + ND\n"
+      << " Planning effor: patient:\n"
+      << "  -21 -- op: out-of-place CC fwd fft\n"
+      << "  -22 -- ip: in-place     CC fwd fft\n"
+      << "  -24 -- op: out-of-place CC fwd fft + UNALIGNED\n"
+      << " Planning effor: exhaustive:\n"
+      << "  -31 -- op: out-of-place CC fwd fft\n"
+      << "  -32 -- ip: in-place     CC fwd fft\n"
+      << "  -34 -- op: out-of-place CC fwd fft + UNALIGNED\n"
+      << "\n"
+      << "Single precision, Split complex\n"
+      << " Planning effor: estimate:\n"
+      << "  -51 -- op: out-of-place CC fwd fft\n"
+      << "  -52 -- ip: in-place     CC fwd fft\n"
+      << " Planning effor: measure:\n"
+      << "  -61 -- op: out-of-place CC fwd fft\n"
+      << "  -62 -- ip: in-place     CC fwd fft\n"
+      << " Planning effor: patient:\n"
+      << "  -71 -- op: out-of-place CC fwd fft\n"
+      << "  -72 -- ip: in-place     CC fwd fft\n"
+      ;
+
   default: return 0;
   }
 
Index: benchmarks/fftm.cpp
===================================================================
--- benchmarks/fftm.cpp	(revision 171241)
+++ benchmarks/fftm.cpp	(working copy)
@@ -450,10 +450,11 @@
   char* what() { return "t_fftm_fix_rows"; }
   float ops_per_point(length_type cols)
     { return (int)(this->ops(rows_, cols) / cols); }
-  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
-  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
-  int mem_per_point(length_type cols) { return cols*elem_per_point*sizeof(T); }
 
+  int riob_per_point(length_type) { return rows_*sizeof(T); }
+  int wiob_per_point(length_type) { return rows_*sizeof(T); }
+  int mem_per_point (length_type) { return rows_*elem_per_point*sizeof(T); }
+
   void operator()(length_type cols, length_type loop, float& time)
   {
     this->fftm(rows_, cols, loop, time);
@@ -482,9 +483,9 @@
   char* what() { return "t_fftm_fix_cols"; }
   float ops_per_point(length_type rows)
     { return (int)(this->ops(rows, cols_) / rows); }
-  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
-  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
-  int mem_per_point(length_type cols) { return cols*elem_per_point*sizeof(T); }
+  int riob_per_point(length_type) { return cols_*sizeof(T); }
+  int wiob_per_point(length_type) { return cols_*sizeof(T); }
+  int mem_per_point (length_type) { return cols_*elem_per_point*sizeof(T); }
 
   void operator()(length_type rows, length_type loop, float& time)
   {
Index: benchmarks/vmmul.cpp
===================================================================
--- benchmarks/vmmul.cpp	(revision 171241)
+++ benchmarks/vmmul.cpp	(working copy)
@@ -22,6 +22,7 @@
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
 #include <vsip/core/profile.hpp>
+#include <vsip/opt/diag/eval.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
@@ -39,8 +40,10 @@
 	  int      SD>
 struct t_vmmul;
 
-struct Impl_op;
-struct Impl_pop;
+struct Impl_op;		// Out-of-place vmmul
+struct Impl_pop;	// Psuedo out-of-place vmmul, using vector-multiply
+struct Impl_s_op;	// Scaled, Out-of-place vmmul
+struct Impl_s_pop;	// Scaled, psuedo out-of-place vmmul, using vmul
 
 
 
@@ -72,14 +75,22 @@
       Z = vmmul<SD>(W, A);
     t1.stop();
     
-    if (!equal(Z(0, 0), T(1)))
-    {
-      std::cout << "t_vmmul<T, Impl_op, SD>: ERROR" << std::endl;
-      abort();
-    }
+    test_assert(equal(Z(0, 0), T(1)));
     
     time = t1.delta();
   }
+
+  void diag()
+  {
+    length_type const rows = 32;
+    length_type const cols = 256;
+
+    Vector<T>   W(SD == row ? cols : rows);
+    Matrix<T>   A(rows, cols, T());
+    Matrix<T>   Z(rows, cols);
+
+    vsip::impl::diagnose_eval_list_std(Z, vmmul<SD>(W, A));
+  }
 };
 
 
@@ -124,12 +135,92 @@
       t1.stop();
     }
     
-    if (!equal(Z(0, 0), T(1)))
+    test_assert(equal(Z(0, 0), T(1)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+/***********************************************************************
+  Impl_s_op: Scaled out-of-place vmmul
+***********************************************************************/
+
+template <typename T,
+	  int      SD>
+struct t_vmmul<T, Impl_s_op, SD> : Benchmark_base
+{
+  char* what() { return "t_vmmul<T, Impl_s_op, SD>"; }
+  int ops(length_type rows, length_type cols)
+    { return rows * cols * vsip::impl::Ops_info<T>::mul; }
+
+  void exec(length_type rows, length_type cols, length_type loop, float& time)
+  {
+    Vector<T>   W(SD == row ? cols : rows);
+    Matrix<T>   A(rows, cols, T());
+    Matrix<T>   Z(rows, cols);
+
+    W = ramp(T(1), T(1), W.size());
+    A = T(1);
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      Z = T(2) * vmmul<SD>(W, A);
+    t1.stop();
+    
+    test_assert(equal(Z(0, 0), T(2)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+/***********************************************************************
+  Impl_s_pop: Scaled, psuedo out-of-place vmmul, using vector-multiply
+***********************************************************************/
+
+template <typename T,
+	  int      SD>
+struct t_vmmul<T, Impl_s_pop, SD> : Benchmark_base
+{
+  char* what() { return "t_vmmul<T, Impl_s_pop, SD>"; }
+  int ops(length_type rows, length_type cols)
+    { return rows * cols * vsip::impl::Ops_info<T>::mul; }
+
+  void exec(length_type rows, length_type cols, length_type loop, float& time)
+  {
+    Vector<T>   W(SD == row ? cols : rows);
+    Matrix<T>   A(rows, cols, T());
+    Matrix<T>   Z(rows, cols);
+
+    W = ramp(T(1), T(1), W.size());
+    A = T(1);
+    
+    vsip::impl::profile::Timer t1;
+    
+    if (SD == row)
     {
-      std::cout << "t_vmmul<T, Impl_op, SD>: ERROR" << std::endl;
-      abort();
+      t1.start();
+      for (index_type l=0; l<loop; ++l)
+	for (index_type i=0; i<rows; ++i)
+	  Z.row(i) = T(2) * W * A.row(i);
+      t1.stop();
     }
+    else
+    {
+      t1.start();
+      for (index_type l=0; l<loop; ++l)
+	for (index_type i=0; i<cols; ++i)
+	  Z.col(i) = T(2) * W * A.col(i);
+      t1.stop();
+    }
     
+    test_assert(equal(Z(0, 0), T(2)));
+    
     time = t1.delta();
   }
 };
@@ -146,10 +237,17 @@
   typedef t_vmmul<T, ImplTag, SD> base_type;
 
   char* what() { return "t_vmmul_fix_rows"; }
-  int ops_per_point(length_type cols)
-    { return (int)(this->ops(rows_, cols) / cols); }
-  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
-  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
+  float ops_per_point(length_type cols)
+    { return this->ops(rows_, cols) / cols; }
+
+  int riob_per_point(length_type cols)
+    { return SD == row ? (rows_+1         )*sizeof(T)
+                       : (rows_+rows_/cols)*sizeof(T); }
+
+  int wiob_per_point(length_type cols)
+    { return SD == row ? (rows_+1         )*sizeof(T)
+                       : (rows_+rows_/cols)*sizeof(T); }
+
   int mem_per_point(length_type cols)
   { return SD == row ? (2*rows_+1)*sizeof(T)
                      : (2*rows_+rows_/cols)*sizeof(T); }
@@ -177,10 +275,17 @@
   typedef t_vmmul<T, ImplTag, SD> base_type;
 
   char* what() { return "t_vmmul_fix_cols"; }
-  int ops_per_point(length_type rows)
-    { return (int)(this->ops(rows, cols_) / rows); }
-  int riob_per_point(length_type) { return -1*(int)sizeof(T); }
-  int wiob_per_point(length_type) { return -1*(int)sizeof(T); }
+  float ops_per_point(length_type rows)
+    { return this->ops(rows, cols_) / rows; }
+
+  int riob_per_point(length_type rows)
+    { return SD == row ? (cols_+cols_/rows)*sizeof(T)
+                       : (cols_+1         )*sizeof(T); }
+
+  int wiob_per_point(length_type rows)
+    { return SD == row ? (cols_+cols_/rows)*sizeof(T)
+                       : (cols_+1         )*sizeof(T); }
+
   int mem_per_point(length_type rows)
   { return SD == row ? (2*cols_+cols_/rows)*sizeof(T)
                      : (2*cols_+1)*sizeof(T); }
@@ -221,17 +326,25 @@
 
   switch (what)
   {
-  case  1: loop(t_vmmul_fix_rows<complex<float>, Impl_op,   row>(p)); break;
-  case  2: loop(t_vmmul_fix_rows<complex<float>, Impl_pop,  row>(p)); break;
+  case  1: loop(t_vmmul_fix_rows<complex<float>, Impl_op,    row>(p)); break;
+  case  2: loop(t_vmmul_fix_rows<complex<float>, Impl_pop,   row>(p)); break;
+  case  3: loop(t_vmmul_fix_rows<complex<float>, Impl_s_op,  row>(p)); break;
+  case  4: loop(t_vmmul_fix_rows<complex<float>, Impl_s_pop, row>(p)); break;
 
-  case 11: loop(t_vmmul_fix_cols<complex<float>, Impl_op,   row>(p)); break;
-  case 12: loop(t_vmmul_fix_cols<complex<float>, Impl_pop,  row>(p)); break;
+  case 11: loop(t_vmmul_fix_cols<complex<float>, Impl_op,    row>(p)); break;
+  case 12: loop(t_vmmul_fix_cols<complex<float>, Impl_pop,   row>(p)); break;
+  case 13: loop(t_vmmul_fix_cols<complex<float>, Impl_s_op,  row>(p)); break;
+  case 14: loop(t_vmmul_fix_cols<complex<float>, Impl_s_pop, row>(p)); break;
 
-  case 21: loop(t_vmmul_fix_rows<complex<float>, Impl_op,   col>(p)); break;
-  case 22: loop(t_vmmul_fix_rows<complex<float>, Impl_pop,  col>(p)); break;
+  case 21: loop(t_vmmul_fix_rows<complex<float>, Impl_op,    col>(p)); break;
+  case 22: loop(t_vmmul_fix_rows<complex<float>, Impl_pop,   col>(p)); break;
+  case 23: loop(t_vmmul_fix_rows<complex<float>, Impl_s_op,  col>(p)); break;
+  case 24: loop(t_vmmul_fix_rows<complex<float>, Impl_s_pop, col>(p)); break;
 
-  case 31: loop(t_vmmul_fix_cols<complex<float>, Impl_op,   col>(p)); break;
-  case 32: loop(t_vmmul_fix_cols<complex<float>, Impl_pop,  col>(p)); break;
+  case 31: loop(t_vmmul_fix_cols<complex<float>, Impl_op,    col>(p)); break;
+  case 32: loop(t_vmmul_fix_cols<complex<float>, Impl_pop,   col>(p)); break;
+  case 33: loop(t_vmmul_fix_cols<complex<float>, Impl_s_op,  col>(p)); break;
+  case 34: loop(t_vmmul_fix_cols<complex<float>, Impl_s_pop, col>(p)); break;
 
   default: return 0;
   }
Index: benchmarks/fft.cpp
===================================================================
--- benchmarks/fft.cpp	(revision 171241)
+++ benchmarks/fft.cpp	(working copy)
@@ -21,6 +21,7 @@
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 #include <vsip/signal.hpp>
+#include <vsip/opt/diag/fft.hpp>
 
 #include "benchmarks.hpp"
 
@@ -77,6 +78,21 @@
     time = t1.delta();
   }
 
+  void diag()
+  {
+    length_type size = 1024;
+
+    Vector<T>   A(size, T());
+    Vector<T>   Z(size);
+
+    typedef Fft<const_Vector, T, T, fft_fwd, by_reference, no_times, alg_time>
+      fft_type;
+
+    fft_type fft(Domain<1>(size), scale_ ? (1.f/size) : 1.f);
+
+    diagnose_fft_call("fft_op", fft, A, Z);
+  }
+
   t_fft_op(bool scale) : scale_(scale) {}
 
   // Member data
