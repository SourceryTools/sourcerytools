Index: ChangeLog
===================================================================
--- ChangeLog	(revision 164931)
+++ ChangeLog	(working copy)
@@ -1,5 +1,11 @@
 2007-03-06  Jules Bergmann  <jules@codesourcery.com>
 
+	* benchmarks/fastconv.cpp: Split Cbe cases into separate file.
+	* benchmark/cell/fastconv.cpp: New file, Cbe fastconv cases
+	* benchmark/fastconv.hpp: New file, common bits for fastconv.
+	
+2007-03-06  Jules Bergmann  <jules@codesourcery.com>
+
 	* tests/scalar-view.cpp: Rename file to scalar_view.hpp, and split
 	  tests into separate files.
 	* tests/scalar_view.hpp: New file.
Index: benchmarks/cell/fastconv.cpp
===================================================================
--- benchmarks/cell/fastconv.cpp	(revision 0)
+++ benchmarks/cell/fastconv.cpp	(revision 0)
@@ -0,0 +1,334 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    benchmarks/cell/fastconv.cpp
+    @author  Jules Bergmann
+    @date    2007-03-06
+    @brief   VSIPL++ Library: Benchmark for Fast Convolution (Cbe specific).
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/random.hpp>
+#include <vsip_csl/error_db.hpp>
+#include <vsip/opt/cbe/ppu/fastconv.hpp>
+
+#include "benchmarks.hpp"
+#include "alloc_block.hpp"
+#include "fastconv.hpp"
+
+#if !VSIP_IMPL_CBE_SDK
+#  error VSIP_IMPL_CBE_SDK not set
+#endif
+
+using namespace vsip;
+
+
+
+/***********************************************************************
+  Common definitions
+***********************************************************************/
+
+struct ImplCbe;		// interleaved fast-convolution on Cell
+template <typename ComplexFmt>
+struct ImplCbe_ip;	// interleaved fast-convolution on Cell
+template <typename ComplexFmt>
+struct ImplCbe_op;	// interleaved fast-convolution on Cell
+
+
+
+
+/***********************************************************************
+  ImplCbe: interleaved fast-convolution on Cell
+
+  Three versions of the benchmark case are provided:
+
+  ImplCbe: in-place, distributed, split/interleaved format fixed
+           to be library's preferred format.
+
+  Impl
+***********************************************************************/
+bool        use_huge_pages_ = true;
+
+template <typename T>
+struct t_fastconv_base<T, ImplCbe> : fastconv_ops
+{
+  static length_type const num_args = 1;
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+#if PARALLEL_FASTCONV
+    typedef Global_map<1>               map1_type;
+    typedef Map<Block_dist, Whole_dist> map2_type;
+
+    processor_type np = num_processors();
+    map1_type map1;
+    map2_type map2 = map2_type(Block_dist(np), Whole_dist());
+#else
+    typedef Local_map  map1_type;
+    typedef Local_map  map2_type;
+
+    map1_type map1;
+    map2_type map2;
+#endif
+    typedef impl::dense_complex_type complex_type;
+
+    typedef typename Alloc_block<1, T, complex_type, map1_type>::block_type
+	    block1_type;
+    typedef typename Alloc_block<2, T, complex_type, map2_type>::block_type
+	    block2_type;
+
+    typedef Vector<T, block1_type> view1_type;
+    typedef Matrix<T, block2_type> view2_type;
+
+    typedef impl::cbe::Fastconv<T, complex_type>   fconv_type;
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
+    // view2_type data(npulse, nrange, T(), map);
+    view2_type data(*data_block);
+    
+    // Create the pulse replica
+    view1_type replica(*repl_block);
+
+    // Create Fast Convolution object
+    fconv_type fconv(replica, nrange);
+
+    vsip::impl::profile::Timer t1;
+
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      fconv(data, data);
+    t1.stop();
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
+
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
+
+template <typename T,
+	  typename ComplexFmt>
+struct t_fastconv_base<T, ImplCbe_ip<ComplexFmt> > : fastconv_ops
+{
+
+  static length_type const num_args = 1;
+
+  typedef impl::cbe::Fastconv<T, ComplexFmt>   fconv_type;
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+    typedef Local_map map_type;
+    map_type map;
+    typedef typename Alloc_block<1, T, ComplexFmt, map_type>::block_type
+	    block1_type;
+    typedef typename Alloc_block<2, T, ComplexFmt, map_type>::block_type
+	    block2_type;
+
+    block2_type* data_block;
+    block1_type* repl_block;
+
+    repl_block = alloc_block<1, T, ComplexFmt>(nrange, mem_addr_, 0x0000000,
+					       map);
+    data_block = alloc_block<2, T, ComplexFmt>(Domain<2>(npulse, nrange),
+					       mem_addr_, nrange*sizeof(T),
+					       map);
+
+    typedef Matrix<T, block2_type> view_type;
+    typedef Vector<T, block1_type> replica_view_type;
+
+    {
+    // Create the data cube.
+    view_type         data(*data_block);
+    // Create the pulse replica
+    replica_view_type replica(*repl_block);
+    
+    // Create Fast Convolution object
+    fconv_type fconv(replica, nrange);
+
+    vsip::impl::profile::Timer t1;
+
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      fconv(data, data);
+    t1.stop();
+
+    time = t1.delta();
+    }
+    delete repl_block;
+    delete data_block;
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
+template <typename T,
+	  typename ComplexFmt>
+struct t_fastconv_base<T, ImplCbe_op<ComplexFmt> > : fastconv_ops
+{
+  typedef impl::Layout<1, row1_type, impl::Stride_unit_dense, ComplexFmt> LP1;
+  typedef impl::Layout<2, row2_type, impl::Stride_unit_dense, ComplexFmt> LP2;
+  typedef impl::Fast_block<1, T, LP1, Local_map> block1_type;
+  typedef impl::Fast_block<2, T, LP2, Local_map> block2_type;
+
+  static length_type const num_args = 2;
+
+  typedef impl::cbe::Fastconv<T, ComplexFmt>   fconv_type;
+
+  void fastconv(length_type npulse, length_type nrange,
+		length_type loop, float& time)
+  {
+    Rand<T> gen(0, 0);
+
+    // Create the data cube.
+    Matrix<T, block2_type> in (npulse, nrange, T());
+    Matrix<T, block2_type> out(npulse, nrange, T());
+    in = gen.randu(npulse, nrange);
+    
+    // Create the pulse replica
+    Vector<T, block1_type> replica(nrange, T());
+    replica.put(0, T(1));
+
+    // Create Fast Convolution object
+    fconv_type fconv(replica, nrange);
+
+    vsip::impl::profile::Timer t1;
+
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      fconv(in, out);
+    t1.stop();
+
+    time = t1.delta();
+
+    // Check result.
+#if 0
+    // Ideally we would do a full check, using FFT and vmul.
+    // However, those also use the SPE and will bump the fastconv
+    // kernel out.
+    typedef Fft<const_Vector, T, T, fft_fwd, by_reference> for_fft_type;
+    typedef Fft<const_Vector, T, T, fft_inv, by_reference> inv_fft_type;
+
+    Vector<T> f_replica(nrange, T());
+    Vector<T> chk      (nrange, T());
+
+    for_fft_type for_fft(Domain<1>(nrange), 1.0);
+    inv_fft_type inv_fft(Domain<1>(nrange), 1.0/(nrange));
+
+    for_fft(replica, f_replica);
+    for (index_type p=0; p<npulse; ++p)
+    {
+      for_fft(in.row(p), chk);
+      chk *= f_replica;
+      inv_fft(chk);
+      test_assert(error_db(chk, out.row(p)) < -100);
+    }
+#else
+    // Instead, we use a simple identity kernel and check that
+    // in == out.
+    test_assert(error_db(in, out) < -100);
+#endif
+  }
+};
+
+
+
+/***********************************************************************
+  Benchmark Driver
+***********************************************************************/
+
+void
+defaults(Loop1P& loop)
+{
+  loop.cal_        = 4;
+  loop.start_      = 4;
+  loop.stop_       = 16;
+  loop.loop_start_ = 10;
+  loop.user_param_ = 64;
+}
+
+
+
+int
+test(Loop1P& loop, int what)
+{
+  typedef vsip::impl::Cmplx_split_fmt Csf;
+  typedef vsip::impl::Cmplx_inter_fmt Cif;
+
+  length_type param1 = loop.user_param_;
+  switch (what)
+  {
+  case 20: loop(t_fastconv_rf<complex<float>, ImplCbe>(param1)); break;
+  case 21: loop(t_fastconv_rf<complex<float>, ImplCbe_op<Cif> >(param1));break;
+  case 22: loop(t_fastconv_rf<complex<float>, ImplCbe_ip<Cif> >(param1));break;
+  case 23: loop(t_fastconv_rf<complex<float>, ImplCbe_op<Csf> >(param1));break;
+  case 24: loop(t_fastconv_rf<complex<float>, ImplCbe_ip<Csf> >(param1));break;
+
+  default: return 0;
+  }
+  return 1;
+}
Index: benchmarks/fastconv.cpp
===================================================================
--- benchmarks/fastconv.cpp	(revision 164924)
+++ benchmarks/fastconv.cpp	(working copy)
@@ -23,12 +23,9 @@
 #include <vsip/signal.hpp>
 #include <vsip/random.hpp>
 #include <vsip_csl/error_db.hpp>
-#ifdef VSIP_IMPL_CBE_SDK
-#include <vsip/opt/cbe/ppu/fastconv.hpp>
-#endif
 
 #include "benchmarks.hpp"
-#include "alloc_block.hpp"
+#include "fastconv.hpp"
 
 using namespace vsip;
 
@@ -44,10 +41,6 @@
   Common definitions
 ***********************************************************************/
 
-template <typename T,
-	  typename ImplTag>
-struct t_fastconv_base;
-
 struct Impl1op;		// out-of-place, phased fast-convolution
 struct Impl1ip;		// in-place, phased fast-convolution
 struct Impl1pip1;	// psuedo in-place (using in-place Fft), phased
@@ -64,18 +57,8 @@
 
 struct Impl1pip2_nopar;
 
-struct fastconv_ops : Benchmark_base
-{
-  float ops(length_type npulse, length_type nrange) 
-  {
-    float fft_ops = 5 * nrange * std::log((float)nrange) / std::log(2.f);
-    float tot_ops = 2 * npulse * fft_ops + 6 * npulse * nrange;
-    return tot_ops;
-  }
-};
 
 
-
 /***********************************************************************
   Impl1op: out-of-place, phased fast-convolution
 ***********************************************************************/
@@ -752,308 +735,9 @@
 
 
 /***********************************************************************
-  ImplCbe: interleaved fast-convolution on Cell
-
-  Three versions of the benchmark case are provided:
-
-  ImplCbe: in-place, distributed, split/interleaved format fixed
-           to be library's preferred format.
-
-  Impl
+  Benchmark Driver
 ***********************************************************************/
-#ifdef VSIP_IMPL_CBE_SDK
-bool        use_huge_pages_ = true;
 
-template <typename T>
-struct t_fastconv_base<T, ImplCbe> : fastconv_ops
-{
-  static length_type const num_args = 1;
-
-  void fastconv(length_type npulse, length_type nrange,
-		length_type loop, float& time)
-  {
-#if PARALLEL_FASTCONV
-    typedef Global_map<1>               map1_type;
-    typedef Map<Block_dist, Whole_dist> map2_type;
-
-    processor_type np = num_processors();
-    map1_type map1;
-    map2_type map2 = map2_type(Block_dist(np), Whole_dist());
-#else
-    typedef Local_map  map1_type;
-    typedef Local_map  map2_type;
-
-    map1_type map1;
-    map2_type map2;
-#endif
-    typedef impl::dense_complex_type complex_type;
-
-    typedef typename Alloc_block<1, T, complex_type, map1_type>::block_type
-	    block1_type;
-    typedef typename Alloc_block<2, T, complex_type, map2_type>::block_type
-	    block2_type;
-
-    typedef Vector<T, block1_type> view1_type;
-    typedef Matrix<T, block2_type> view2_type;
-
-    typedef impl::cbe::Fastconv<T, complex_type>   fconv_type;
-
-    block1_type* repl_block;
-    block2_type* data_block;
-
-    repl_block = alloc_block<1, T, complex_type>(nrange, mem_addr_, 0x0000000,
-					       map1);
-    data_block = alloc_block<2, T, complex_type>(Domain<2>(npulse, nrange),
-					       mem_addr_, nrange*sizeof(T),
-					       map2);
-
-    { // Use scope to control lifetime of view.
-
-    // Create the data cube.
-    // view2_type data(npulse, nrange, T(), map);
-    view2_type data(*data_block);
-    
-    // Create the pulse replica
-    view1_type replica(*repl_block);
-
-    // Create Fast Convolution object
-    fconv_type fconv(replica, nrange);
-
-    vsip::impl::profile::Timer t1;
-
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      fconv(data, data);
-    t1.stop();
-
-    time = t1.delta();
-    }
-
-    // Delete blocks after view has gone out of scope.  If we delete
-    // the blocks while the views are still live, they will corrupt
-    // memory when they try to decrement the blocks' reference counts.
-
-    delete repl_block;
-    delete data_block;
-
-  }
-
-  t_fastconv_base()
-    : mem_addr_(0),
-      pages_   (9)
-  {
-    char const* mem_file = "/huge/fastconv.bin";
-
-    if (use_huge_pages_)
-      mem_addr_ = open_huge_pages(mem_file, pages_);
-    else
-      mem_addr_ = 0;
-  }
-
-  char*        mem_addr_;
-  unsigned int pages_;
-};
-
-
-
-
-template <typename T,
-	  typename ComplexFmt>
-struct t_fastconv_base<T, ImplCbe_ip<ComplexFmt> > : fastconv_ops
-{
-
-  static length_type const num_args = 1;
-
-  typedef impl::cbe::Fastconv<T, ComplexFmt>   fconv_type;
-
-  void fastconv(length_type npulse, length_type nrange,
-		length_type loop, float& time)
-  {
-    typedef Local_map map_type;
-    map_type map;
-    typedef typename Alloc_block<1, T, ComplexFmt, map_type>::block_type
-	    block1_type;
-    typedef typename Alloc_block<2, T, ComplexFmt, map_type>::block_type
-	    block2_type;
-
-    block2_type* data_block;
-    block1_type* repl_block;
-
-    repl_block = alloc_block<1, T, ComplexFmt>(nrange, mem_addr_, 0x0000000,
-					       map);
-    data_block = alloc_block<2, T, ComplexFmt>(Domain<2>(npulse, nrange),
-					       mem_addr_, nrange*sizeof(T),
-					       map);
-
-    typedef Matrix<T, block2_type> view_type;
-    typedef Vector<T, block1_type> replica_view_type;
-
-    {
-    // Create the data cube.
-    view_type         data(*data_block);
-    // Create the pulse replica
-    replica_view_type replica(*repl_block);
-    
-    // Create Fast Convolution object
-    fconv_type fconv(replica, nrange);
-
-    vsip::impl::profile::Timer t1;
-
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      fconv(data, data);
-    t1.stop();
-
-    time = t1.delta();
-    }
-    delete repl_block;
-    delete data_block;
-  }
-
-  t_fastconv_base()
-    : mem_addr_(0),
-      pages_   (9)
-  {
-    char const* mem_file = "/huge/fastconv.bin";
-
-    if (use_huge_pages_)
-      mem_addr_ = open_huge_pages(mem_file, pages_);
-    else
-      mem_addr_ = 0;
-  }
-
-  char*        mem_addr_;
-  unsigned int pages_;
-};
-
-
-
-template <typename T,
-	  typename ComplexFmt>
-struct t_fastconv_base<T, ImplCbe_op<ComplexFmt> > : fastconv_ops
-{
-  typedef impl::Layout<1, row1_type, impl::Stride_unit_dense, ComplexFmt> LP1;
-  typedef impl::Layout<2, row2_type, impl::Stride_unit_dense, ComplexFmt> LP2;
-  typedef impl::Fast_block<1, T, LP1, Local_map> block1_type;
-  typedef impl::Fast_block<2, T, LP2, Local_map> block2_type;
-
-  static length_type const num_args = 2;
-
-  typedef impl::cbe::Fastconv<T, ComplexFmt>   fconv_type;
-
-  void fastconv(length_type npulse, length_type nrange,
-		length_type loop, float& time)
-  {
-    Rand<T> gen(0, 0);
-
-    // Create the data cube.
-    Matrix<T, block2_type> in (npulse, nrange, T());
-    Matrix<T, block2_type> out(npulse, nrange, T());
-    in = gen.randu(npulse, nrange);
-    
-    // Create the pulse replica
-    Vector<T, block1_type> replica(nrange, T());
-    replica.put(0, T(1));
-
-    // Create Fast Convolution object
-    fconv_type fconv(replica, nrange);
-
-    vsip::impl::profile::Timer t1;
-
-    t1.start();
-    for (index_type l=0; l<loop; ++l)
-      fconv(in, out);
-    t1.stop();
-
-    time = t1.delta();
-
-    // Check result.
-#if 0
-    // Ideally we would do a full check, using FFT and vmul.
-    // However, those also use the SPE and will bump the fastconv
-    // kernel out.
-    typedef Fft<const_Vector, T, T, fft_fwd, by_reference> for_fft_type;
-    typedef Fft<const_Vector, T, T, fft_inv, by_reference> inv_fft_type;
-
-    Vector<T> f_replica(nrange, T());
-    Vector<T> chk      (nrange, T());
-
-    for_fft_type for_fft(Domain<1>(nrange), 1.0);
-    inv_fft_type inv_fft(Domain<1>(nrange), 1.0/(nrange));
-
-    for_fft(replica, f_replica);
-    for (index_type p=0; p<npulse; ++p)
-    {
-      for_fft(in.row(p), chk);
-      chk *= f_replica;
-      inv_fft(chk);
-      test_assert(error_db(chk, out.row(p)) < -100);
-    }
-#else
-    // Instead, we use a simple identity kernel and check that
-    // in == out.
-    test_assert(error_db(in, out) < -100);
-#endif
-  }
-};
-#endif // VSIP_IMPL_CBE_SDK
-
-
-
-/***********************************************************************
-  PF driver: (P)ulse (F)ixed
-***********************************************************************/
-
-template <typename T, typename ImplTag>
-struct t_fastconv_pf : public t_fastconv_base<T, ImplTag>
-{
-  char* what() { return "t_fastconv_pf"; }
-  float ops_per_point(length_type size)
-    { return this->ops(npulse_, size) / size; }
-  int riob_per_point(length_type) { return npulse_*(int)sizeof(T); }
-  int wiob_per_point(length_type) { return npulse_*(int)sizeof(T); }
-  int mem_per_point(length_type)  { return this->num_args*npulse_*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-  {
-    this->fastconv(npulse_, size, loop, time);
-  }
-
-  t_fastconv_pf(length_type npulse) : npulse_(npulse) {}
-
-// Member data
-  length_type npulse_;
-};
-
-
-
-/***********************************************************************
-  RF driver: (R)ange cells (F)ixed
-***********************************************************************/
-
-template <typename T, typename ImplTag>
-struct t_fastconv_rf : public t_fastconv_base<T, ImplTag>
-{
-  char* what() { return "t_fastconv_rf"; }
-  float ops_per_point(length_type size)
-    { return this->ops(size, nrange_) / size; }
-  int riob_per_point(length_type) { return nrange_*(int)sizeof(T); }
-  int wiob_per_point(length_type) { return nrange_*(int)sizeof(T); }
-  int mem_per_point(length_type)  { return this->num_args*nrange_*sizeof(T); }
-
-  void operator()(length_type size, length_type loop, float& time)
-  {
-    this->fastconv(size, nrange_, loop, time);
-  }
-
-  t_fastconv_rf(length_type nrange) : nrange_(nrange) {}
-
-// Member data
-  length_type nrange_;
-};
-
-
-
 void
 defaults(Loop1P& loop)
 {
@@ -1099,14 +783,6 @@
   case 18: loop(t_fastconv_rf<complex<float>, Impl2fv>(param1)); break;
 #endif
 
-#ifdef VSIP_IMPL_CBE_SDK
-  case 20: loop(t_fastconv_rf<complex<float>, ImplCbe>(param1)); break;
-  case 21: loop(t_fastconv_rf<complex<float>, ImplCbe_op<Cif> >(param1));break;
-  case 22: loop(t_fastconv_rf<complex<float>, ImplCbe_ip<Cif> >(param1));break;
-  case 23: loop(t_fastconv_rf<complex<float>, ImplCbe_op<Csf> >(param1));break;
-  case 24: loop(t_fastconv_rf<complex<float>, ImplCbe_ip<Csf> >(param1));break;
-#endif
-
   default: return 0;
   }
   return 1;
Index: benchmarks/fastconv.hpp
===================================================================
--- benchmarks/fastconv.hpp	(revision 0)
+++ benchmarks/fastconv.hpp	(revision 0)
@@ -0,0 +1,103 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    benchmarks/fastconv.hpp
+    @author  Jules Bergmann
+    @date    2005-10-28
+    @brief   VSIPL++ Library: Common bits for Fast Convolution benchmarks.
+*/
+
+#ifndef BENCHMARKS_FASTCONV_HPP
+#define BENCHMARKS_FASTCONV_HPP
+
+/***********************************************************************
+  Macros
+***********************************************************************/
+
+#ifdef VSIP_IMPL_SOURCERY_VPP
+#  define PARALLEL_FASTCONV 1
+#else
+#  define PARALLEL_FASTCONV 0
+#endif
+
+
+
+/***********************************************************************
+  Common definitions
+***********************************************************************/
+
+template <typename T,
+	  typename ImplTag>
+struct t_fastconv_base;
+
+
+
+struct fastconv_ops : Benchmark_base
+{
+  float ops(vsip::length_type npulse, vsip::length_type nrange) 
+  {
+    float fft_ops = 5 * nrange * std::log((float)nrange) / std::log(2.f);
+    float tot_ops = 2 * npulse * fft_ops + 6 * npulse * nrange;
+    return tot_ops;
+  }
+};
+
+
+
+
+/***********************************************************************
+  PF driver: (P)ulse (F)ixed
+***********************************************************************/
+
+template <typename T, typename ImplTag>
+struct t_fastconv_pf : public t_fastconv_base<T, ImplTag>
+{
+  char* what() { return "t_fastconv_pf"; }
+  float ops_per_point(vsip::length_type size)
+    { return this->ops(npulse_, size) / size; }
+  int riob_per_point(vsip::length_type) { return npulse_*(int)sizeof(T); }
+  int wiob_per_point(vsip::length_type) { return npulse_*(int)sizeof(T); }
+  int mem_per_point(vsip::length_type)  { return this->num_args*npulse_*sizeof(T); }
+
+  void operator()(vsip::length_type size, vsip::length_type loop, float& time)
+  {
+    this->fastconv(npulse_, size, loop, time);
+  }
+
+  t_fastconv_pf(vsip::length_type npulse) : npulse_(npulse) {}
+
+// Member data
+  vsip::length_type npulse_;
+};
+
+
+
+/***********************************************************************
+  RF driver: (R)ange cells (F)ixed
+***********************************************************************/
+
+template <typename T, typename ImplTag>
+struct t_fastconv_rf : public t_fastconv_base<T, ImplTag>
+{
+  char* what() { return "t_fastconv_rf"; }
+  float ops_per_point(vsip::length_type size)
+    { return this->ops(size, nrange_) / size; }
+  int riob_per_point(vsip::length_type) { return nrange_*(int)sizeof(T); }
+  int wiob_per_point(vsip::length_type) { return nrange_*(int)sizeof(T); }
+  int mem_per_point(vsip::length_type)  { return this->num_args*nrange_*sizeof(T); }
+
+  void operator()(vsip::length_type size, vsip::length_type loop, float& time)
+  {
+    this->fastconv(size, nrange_, loop, time);
+  }
+
+  t_fastconv_rf(vsip::length_type nrange) : nrange_(nrange) {}
+
+// Member data
+  vsip::length_type nrange_;
+};
+
+#endif // BENCHMARKS_FASTCONV_HPP
