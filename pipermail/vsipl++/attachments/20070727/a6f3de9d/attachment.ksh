Index: ChangeLog
===================================================================
--- ChangeLog	(revision 177479)
+++ ChangeLog	(working copy)
@@ -1,3 +1,20 @@
+2007-07-27  Jules Bergmann  <jules@codesourcery.com>
+
+	Fix bug with distributed matrix and tensor index reductions.
+	* src/vsip/opt/reductions/par_reductions.hpp (generic_par_idx_op):
+	  Remove unused vector
+	* tests/regressions/par_maxval.cpp: Add regressions for distributed
+	  matrices and tensors.
+
+	Split large tests.
+	* tests/coverage_unary.cpp: Split trig and exp/ln into ...
+	* tests/coverage_unary_trig.cpp: ... here, new file.
+	* tests/coverage_unary_exp.cpp: ... here, new file.
+	* tests/fft.cpp: Split common bits, 2D, and block_types into ...
+	* tests/fft_common.hpp: ... here, new file,
+	* tests/fft2d.cpp: ... here, new file.
+	* tests/fft_block_type.cpp: ... here, new file.
+
 2007-07-26  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/layout.hpp (Applied_layout): Make extent parameter
Index: src/vsip/opt/reductions/par_reductions.hpp
===================================================================
--- src/vsip/opt/reductions/par_reductions.hpp	(revision 176624)
+++ src/vsip/opt/reductions/par_reductions.hpp	(working copy)
@@ -5,18 +5,26 @@
     @date    2007-03-14
     @brief   VSIPL++ Library: Parallel index reduction functions.
 	     [math.fns.reductidx].
-
 */
 
 #ifndef VSIP_OPT_REDUCTIONS_PAR_REDUCTIONS_HPP
 #define VSIP_OPT_REDUCTIONS_PAR_REDUCTIONS_HPP
 
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
 
 
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
 namespace vsip
 {
 
@@ -35,10 +43,10 @@
 
 template <typename                  ReduceT,
           typename                  T,
-          dimension_type            dim,
+          dimension_type            Dim,
 	  typename                  Block>
 inline T
-reduce_idx_blk(Block const& b, Index<dim>& idx)
+reduce_idx_blk(Block const& b, Index<Dim>& idx)
 {
   T r;
   typedef typename Block_layout<Block>::order_type
@@ -48,7 +56,7 @@
 		ReduceT,
 		T,
 		impl::Op_list_3<Block const&,
-                                Index<dim>&,
+                                Index<Dim>&,
                                 order_type>,
 		typename Make_type_list<Cvsip_tag, Mercury_sal_tag,
                                         Generic_tag>::type>
@@ -60,19 +68,20 @@
 
 template<template <typename> class ReduceT,
          typename T,
-         typename Block, dimension_type dim>
+         typename Block, dimension_type Dim>
 inline T
-generic_par_idx_op(Block& a, Index<dim>& idx)
+generic_par_idx_op(Block& a, Index<Dim>& idx)
 {
   typedef Map<Block_dist>                          map_type;
   typedef Dense<1,T,row1_type,Map<> >              block_type;
-  typedef Dense<1,Index<dim>,row1_type,Map<> >     block_idx_type;
+  typedef Dense<1,Index<Dim>,row1_type,Map<> >     block_idx_type;
   typedef Dense<1,T,row1_type,Global_map<1> >          g_block_type;
-  typedef Dense<1,Index<dim>,row1_type,Global_map<1> > g_block_idx_type;
+  typedef Dense<1,Index<Dim>,row1_type,Global_map<1> > g_block_idx_type;
   typedef Vector<T,block_type>                     vect_type;
-  typedef Vector<Index<dim>,block_idx_type>        vect_idx_type;
-  Index<dim>                                       my_res_idx;
-  Index<dim>                                       my_g_res_idx;
+  typedef Vector<Index<Dim>,block_idx_type>        vect_idx_type;
+
+  Index<Dim>                                       my_res_idx;
+  Index<Dim>                                       my_g_res_idx;
   Index<1>                                         global_res_idx;
   T                                                global_res;
 
@@ -85,7 +94,6 @@
   vect_type                               results(a_proc_set.size(),map);
   vect_idx_type                           results_idx(a_proc_set.size(),map);
 
-  Vector<typename Block::value_type> temp_vect(get_local_block(a));
   if(a.map().subblock() != no_subblock) 
   {
     typename ReduceT<T>::result_type result = 
@@ -101,7 +109,7 @@
 
   // first, make a vector with a global map that contains all the results
   Vector<T,g_block_type>                  global_results(a_proc_set.size());
-  Vector<Index<dim>,g_block_idx_type>     global_results_idx(a_proc_set.size());
+  Vector<Index<Dim>,g_block_idx_type>     global_results_idx(a_proc_set.size());
   // do broadcast
   global_results     = results;
   global_results_idx = results_idx;
@@ -116,34 +124,34 @@
 }
 
 template <template <typename> class ReduceT,
-          dimension_type            dim,
+          dimension_type            Dim,
           typename                  OrderT>
 struct Reduction_idx_supported
 { static bool const value = false; };
 
 // All suppored reductions here
-template <dimension_type dim, typename OrderT>
-struct Reduction_idx_supported<Max_value, dim, OrderT>
+template <dimension_type Dim, typename OrderT>
+struct Reduction_idx_supported<Max_value, Dim, OrderT>
 { static bool const value = true; };
 
-template <dimension_type dim, typename OrderT>
-struct Reduction_idx_supported<Min_value, dim, OrderT>
+template <dimension_type Dim, typename OrderT>
+struct Reduction_idx_supported<Min_value, Dim, OrderT>
 { static bool const value = true; };
 
-template <dimension_type dim, typename OrderT>
-struct Reduction_idx_supported<Max_mag_value, dim, OrderT>
+template <dimension_type Dim, typename OrderT>
+struct Reduction_idx_supported<Max_mag_value, Dim, OrderT>
 { static bool const value = true; };
 
-template <dimension_type dim, typename OrderT>
-struct Reduction_idx_supported<Min_mag_value, dim, OrderT>
+template <dimension_type Dim, typename OrderT>
+struct Reduction_idx_supported<Min_mag_value, Dim, OrderT>
 { static bool const value = true; };
 
-template <dimension_type dim, typename OrderT>
-struct Reduction_idx_supported<Max_magsq_value, dim, OrderT>
+template <dimension_type Dim, typename OrderT>
+struct Reduction_idx_supported<Max_magsq_value, Dim, OrderT>
 { static bool const value = true; };
 
-template <dimension_type dim, typename OrderT>
-struct Reduction_idx_supported<Min_magsq_value, dim, OrderT>
+template <dimension_type Dim, typename OrderT>
+struct Reduction_idx_supported<Min_magsq_value, Dim, OrderT>
 { static bool const value = true; };
 
 
Index: tests/coverage_unary_trig.cpp
===================================================================
--- tests/coverage_unary_trig.cpp	(revision 0)
+++ tests/coverage_unary_trig.cpp	(revision 0)
@@ -0,0 +1,73 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/coverage_unary_trid.hpp
+    @author  Jules Bergmann
+    @date    2005-09-13
+    @brief   VSIPL++ Library: Coverage tests for trig unary expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include "coverage_common.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+TEST_UNARY(sin,   sin,   sin,   anyval)
+TEST_UNARY(cos,   cos,   cos,   anyval)
+TEST_UNARY(tan,   tan,   tan,   anyval)
+TEST_UNARY(atan,  atan,  atan,  anyval)
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+#if VSIP_IMPL_TEST_LEVEL == 0
+
+  vector_cases2<Test_cos, float>();
+  vector_cases2<Test_atan, float>();
+
+#else
+
+  // Unary operators
+  vector_cases2<Test_cos, float>();
+  vector_cases2<Test_cos, double>();
+
+  vector_cases2<Test_sin, float>();
+  vector_cases2<Test_sin, double>();
+
+  vector_cases2<Test_tan, float>();
+
+  vector_cases2<Test_atan, float>();
+  vector_cases2<Test_atan, double>();
+
+#endif // VSIP_IMPL_TEST_LEVEL > 0
+}
Index: tests/coverage_unary_exp.cpp
===================================================================
--- tests/coverage_unary_exp.cpp	(revision 0)
+++ tests/coverage_unary_exp.cpp	(revision 0)
@@ -0,0 +1,75 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/coverage_unary_exp.hpp
+    @author  Jules Bergmann
+    @date    2005-09-13
+    @brief   VSIPL++ Library: Coverage tests for exponential unary expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include "coverage_common.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+TEST_UNARY(log,   log,   log,   posval)
+TEST_UNARY(log10, log10, log10, posval)
+TEST_UNARY(exp,   exp,   exp,   posval)
+TEST_UNARY(exp10, exp10, exp10, posval)
+
+
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+#if VSIP_IMPL_TEST_LEVEL == 0
+
+  vector_cases2<Test_log, float>();
+  vector_cases2<Test_exp, float>();
+
+#else
+
+  // Unary operators
+  vector_cases2<Test_log, float>();
+  vector_cases2<Test_log, double>();
+
+  vector_cases2<Test_log10, float>();
+  vector_cases2<Test_log10, double>();
+
+  vector_cases2<Test_exp, float>();
+  vector_cases2<Test_exp, double>();
+
+  vector_cases2<Test_exp10, float>();
+  vector_cases2<Test_exp10, double>();
+
+#endif // VSIP_IMPL_TEST_LEVEL > 0
+}
Index: tests/fft_block_type.cpp
===================================================================
--- tests/fft_block_type.cpp	(revision 0)
+++ tests/fft_block_type.cpp	(revision 0)
@@ -0,0 +1,163 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/fft_block_type.cpp
+    @author  Jules Bergmann
+    @date    2005-06-17
+    @brief   VSIPL++ Library: Testcases for Fft with different block types.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+// Set to 1 to enable verbose output.
+#define VERBOSE     0
+// Set to 0 to disble use of random values.
+#define FILL_RANDOM 1
+
+#include <cmath>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip/core/config.hpp>
+#include <vsip/core/metaprogramming.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/error_db.hpp>
+#include <vsip_csl/ref_dft.hpp>
+
+#if VERBOSE
+#  include <iostream>
+#  include <vsip_csl/output.hpp>
+#  include "extdata-output.hpp"
+#endif
+
+#include "fft_common.hpp"
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+
+// Check with different block types.
+
+template <typename T>
+void
+test_block_type()
+{
+#if TEST_2D_CC
+  test_fft<0,1,complex<T>,complex<T>,2,vsip::fft_fwd>();
+  test_fft<1,0,complex<T>,complex<T>,2,vsip::fft_fwd>();
+
+#  if VSIP_IMPL_TEST_LEVEL > 0
+  test_fft<0,2,complex<T>,complex<T>,2,vsip::fft_fwd>();
+  test_fft<1,1,complex<T>,complex<T>,2,vsip::fft_fwd>();
+  test_fft<1,2,complex<T>,complex<T>,2,vsip::fft_fwd>();
+  test_fft<2,0,complex<T>,complex<T>,2,vsip::fft_fwd>();
+  test_fft<2,1,complex<T>,complex<T>,2,vsip::fft_fwd>();
+  test_fft<2,2,complex<T>,complex<T>,2,vsip::fft_fwd>();
+#  endif
+#endif
+
+#if TEST_2D_RC
+  test_fft<0,1,T,complex<T>,2,1>();
+  test_fft<0,1,T,complex<T>,2,0>();
+  test_fft<1,0,T,complex<T>,2,1>();
+  test_fft<1,0,T,complex<T>,2,0>();
+
+#  if VSIP_IMPL_TEST_LEVEL > 0
+  test_fft<0,2,T,complex<T>,2,1>();
+  test_fft<0,2,T,complex<T>,2,0>();
+
+  test_fft<1,1,T,complex<T>,2,1>();
+  test_fft<1,1,T,complex<T>,2,0>();
+  test_fft<1,2,T,complex<T>,2,1>();
+  test_fft<1,2,T,complex<T>,2,0>();
+
+  test_fft<2,0,T,complex<T>,2,1>();
+  test_fft<2,0,T,complex<T>,2,0>();
+  test_fft<2,1,T,complex<T>,2,1>();
+  test_fft<2,1,T,complex<T>,2,0>();
+  test_fft<2,2,T,complex<T>,2,1>();
+  test_fft<2,2,T,complex<T>,2,0>();
+#  endif
+#endif
+
+#if TEST_3D_CC
+  test_fft<0,1,complex<T>,complex<T>,3,vsip::fft_fwd>();
+  test_fft<1,0,complex<T>,complex<T>,3,vsip::fft_fwd>();
+
+#  if VSIP_IMPL_TEST_LEVEL > 0
+  test_fft<0,2,complex<T>,complex<T>,3,vsip::fft_fwd>();
+  test_fft<1,1,complex<T>,complex<T>,3,vsip::fft_fwd>();
+  test_fft<1,2,complex<T>,complex<T>,3,vsip::fft_fwd>();
+  test_fft<2,0,complex<T>,complex<T>,3,vsip::fft_fwd>();
+  test_fft<2,1,complex<T>,complex<T>,3,vsip::fft_fwd>();
+  test_fft<2,2,complex<T>,complex<T>,3,vsip::fft_fwd>();
+#  endif
+#endif
+
+#if TEST_3D_RC
+  test_fft<0,1,T,complex<T>,3,2>();
+  test_fft<0,1,T,complex<T>,3,1>();
+  test_fft<0,1,T,complex<T>,3,0>();
+  test_fft<1,0,T,complex<T>,3,2>();
+  test_fft<1,0,T,complex<T>,3,1>();
+  test_fft<1,0,T,complex<T>,3,0>();
+
+#  if VSIP_IMPL_TEST_LEVEL > 0
+  test_fft<0,2,T,complex<T>,3,2>();
+  test_fft<0,2,T,complex<T>,3,1>();
+  test_fft<0,2,T,complex<T>,3,0>();
+
+  test_fft<1,1,T,complex<T>,3,2>();
+  test_fft<1,1,T,complex<T>,3,1>();
+  test_fft<1,1,T,complex<T>,3,0>();
+  test_fft<1,2,T,complex<T>,3,2>();
+  test_fft<1,2,T,complex<T>,3,1>();
+  test_fft<1,2,T,complex<T>,3,0>();
+
+  test_fft<2,0,T,complex<T>,3,2>();
+  test_fft<2,0,T,complex<T>,3,1>();
+  test_fft<2,0,T,complex<T>,3,0>();
+  test_fft<2,1,T,complex<T>,3,2>();
+  test_fft<2,1,T,complex<T>,3,1>();
+  test_fft<2,1,T,complex<T>,3,0>();
+  test_fft<2,2,T,complex<T>,3,2>();
+  test_fft<2,2,T,complex<T>,3,1>();
+  test_fft<2,2,T,complex<T>,3,0>();
+#  endif
+#endif
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  // show_config();
+
+//
+// check with different block types
+//
+  test_block_type<float>();
+
+  return 0;
+}
Index: tests/regressions/par_maxval.cpp
===================================================================
--- tests/regressions/par_maxval.cpp	(revision 173072)
+++ tests/regressions/par_maxval.cpp	(working copy)
@@ -25,6 +25,7 @@
 #include <vsip/parallel.hpp>
 
 #include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
 
 #include "test_common.hpp"
 
@@ -33,11 +34,11 @@
 using vsip_csl::equal;
 
 
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
 
-
 template <typename MapT>
 void
 test_maxval()
@@ -70,10 +71,23 @@
 
 
 
+template <typename       T,
+	  typename       MapT,
+	  dimension_type Dim>
+void
+test_maxval_nd(Domain<Dim> const& dom)
+{
+  typedef typename Default_order<Dim>::type order_type;
+  Storage<Dim, T, order_type, MapT> stor(dom, T(1));
+  Index<Dim> idx;
 
+  T mv = maxval(stor.view, idx);
 
+  test_assert(mv == T(1));
+}
 
 
+
 /***********************************************************************
   Main
 ***********************************************************************/
@@ -87,5 +101,23 @@
   test_maxval<Map<> >();
   test_maxval<Global_map<1> >();
 
+
+
+  // A bug in generic_par_idx_op prevented index-reductions such as
+  // maxval from working on distributed views with dimension greater
+  // than 1.
+
+  test_maxval_nd<float, Local_map>(Domain<1>(5));		// OK
+  test_maxval_nd<float, Local_map>(Domain<2>(5, 8));		// OK
+  test_maxval_nd<float, Local_map>(Domain<3>(4, 6, 8));		// OK
+
+  test_maxval_nd<float, Map<> >(Domain<1>(5));			// OK
+  test_maxval_nd<float, Map<> >(Domain<2>(5, 8));		// error
+  test_maxval_nd<float, Map<> >(Domain<3>(4, 6, 8));		// error
+
+  test_maxval_nd<float, Global_map<1> >(Domain<1>(5));		// OK
+  test_maxval_nd<float, Global_map<2> >(Domain<2>(5, 8));	// error
+  test_maxval_nd<float, Global_map<3> >(Domain<3>(4, 6, 8));	// error
+
   return 0;
 }
Index: tests/fft_common.hpp
===================================================================
--- tests/fft_common.hpp	(revision 0)
+++ tests/fft_common.hpp	(revision 0)
@@ -0,0 +1,726 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/fft_common.hpp
+    @author  Jules Bergmann
+    @date    2007-07-26
+    @brief   VSIPL++ Library: Common bits for Fft testcases.
+*/
+
+#ifndef VSIP_TESTS_FFT_COMMON_HPP
+#define VSIP_TESTS_FFT_COMMON_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip_csl/error_db.hpp>
+
+
+
+/***********************************************************************
+  Macros
+***********************************************************************/
+
+#if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_SAL_FFT)
+#  define TEST_2D_CC 1
+#endif
+
+#if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_SAL_FFT)
+#  define TEST_2D_RC 1
+#endif
+
+#if defined(VSIP_IMPL_FFTW3)
+#  define TEST_3D_CC 1
+#endif
+
+#  define TEST_3D_RC 0
+
+#if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_IPP_FFT)
+#  define TEST_NON_POWER_OF_2 1
+#endif
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <template <typename, typename> class View1,
+	  template <typename, typename> class View2,
+	  typename                            T1,
+	  typename                            T2,
+	  typename                            Block1,
+	  typename                            Block2>
+inline void
+check_error(
+  View1<T1, Block1> v1,
+  View2<T2, Block2> v2,
+  double            epsilon)
+{
+  double error = error_db(v1, v2);
+#if VERBOSE
+  if (error >= epsilon)
+  {
+    std::cout << "check_error: error >= epsilon" << std::endl;
+    std::cout << "  error   = " << error   << std::endl;
+    std::cout << "  epsilon = " << epsilon << std::endl;
+    std::cout << "  v1 =\n" << v1;
+    std::cout << "  v2 =\n" << v2;
+  }
+#endif
+  test_assert(error < epsilon);
+}
+
+
+
+/////////////////////////////////////////////////////////////////////
+//
+// Comprehensive 2D, 3D test
+//
+
+template <unsigned Dim, typename T, unsigned L> struct Arg;
+
+template <unsigned Dim, typename T> 
+struct Arg<Dim,T,0>
+{
+  typedef typename vsip::impl::View_of_dim<Dim,T,
+    vsip::Dense<Dim,T,typename vsip::impl::Row_major<Dim>::type> >::type type;
+};
+
+template <unsigned Dim, typename T> 
+struct Arg<Dim,T,1>
+{
+  typedef typename vsip::impl::View_of_dim<Dim,T,
+    vsip::Dense<Dim,T,typename vsip::impl::Col_major<Dim>::type> >::type type;
+};
+
+template <unsigned Dim, typename T> 
+struct Arg<Dim,T,2>
+{
+  typedef typename vsip::impl::View_of_dim<Dim,T,
+    vsip::impl::Fast_block<Dim,T,
+      vsip::impl::Layout<Dim,
+        typename vsip::impl::Row_major<Dim>::type,
+        vsip::impl::Stride_unit_dense
+  > > >::type type;
+};
+
+inline unsigned 
+adjust_size(unsigned size, bool is_short, bool is_short_dim, bool no_odds)
+{ 
+  // no odd sizes along axis for real->complex
+  if ((size & 1) && no_odds && is_short_dim)
+    ++size;
+  return (is_short && is_short_dim) ? size / 2 + 1 : size;
+}
+
+template <unsigned Dim> vsip::Domain<Dim> make_dom(unsigned*, bool, int, bool);
+template <> vsip::Domain<2> make_dom<2>(
+  unsigned* d, bool is_short, int sd, bool no_odds)
+{
+  return  vsip::Domain<2>(
+    vsip::Domain<1>(adjust_size(d[1], is_short, sd == 0, no_odds)),
+    vsip::Domain<1>(adjust_size(d[2], is_short, sd == 1, no_odds)));
+} 
+template <> vsip::Domain<3> make_dom<3>(
+  unsigned* d, bool is_short, int sd, bool no_odds)
+{
+  return vsip::Domain<3>(
+    vsip::Domain<1>(adjust_size(d[0], is_short, sd == 0, no_odds)),
+    vsip::Domain<1>(adjust_size(d[1], is_short, sd == 1, no_odds)),
+    vsip::Domain<1>(adjust_size(d[2], is_short, sd == 2, no_odds)));
+} 
+
+template <typename T, typename BlockT>
+vsip::Domain<2>
+domain_of(vsip::Matrix<T,BlockT> const& src)
+{
+  return vsip::Domain<2>(vsip::Domain<1>(src.size(0)),
+                         vsip::Domain<1>(src.size(1)));
+} 
+ 
+
+template <typename T, typename BlockT>
+vsip::Domain<3>
+domain_of(vsip::Tensor<T,BlockT> const& src)
+{
+  return vsip::Domain<2>(vsip::Domain<1>(src.size(0)),
+                         vsip::Domain<1>(src.size(1)),
+                         vsip::Domain<1>(src.size(2)));
+} 
+
+//
+
+template <typename T, typename BlockT>
+vsip::Matrix<T,BlockT>
+force_copy_init(vsip::Matrix<T,BlockT> const& src)
+{ 
+  vsip::Matrix<T,BlockT> tmp(src.size(0), src.size(1));
+  tmp = src;
+  return tmp;
+}
+
+template <typename T, typename BlockT>
+vsip::Tensor<T,BlockT>
+force_copy_init(vsip::Tensor<T,BlockT> const& src)
+{ 
+  vsip::Tensor<T,BlockT> tmp(src.size(0), src.size(1), src.size(2));
+  tmp = src;
+  return tmp;
+}
+
+//
+
+template <typename T> void set_values(T& v1, T& v2)
+{ v1 = T(10); v2 = T(20); }
+
+template <typename T> void set_values(std::complex<T>& z1, std::complex<T>& z2)
+{
+  z1 = std::complex<T>(T(10), T(10));
+  z2 = std::complex<T>(T(20), T(20));
+}
+
+#if FILL_RANDOM
+// In normal testing, fill_random fills a view with random values.
+
+// 2D 
+
+template <typename BlockT, typename T>
+void fill_random(
+  vsip::Matrix<T,BlockT> in, vsip::Rand<T>& rander)
+{
+  in = (rander.randu(in.size(0), in.size(1)) * 20.0) - 10.0;
+}
+
+template <typename BlockT, typename T>
+void fill_random(
+  vsip::Matrix<std::complex<T>,BlockT> in,
+  vsip::Rand<std::complex<T> >& rander)
+{
+  in = rander.randu(in.size(0), in.size(1)) * std::complex<T>(20.0) -
+         std::complex<T>(10.0, 10.0);
+}
+
+// 3D 
+
+template <typename BlockT, typename T>
+void fill_random(
+  vsip::Tensor<T,BlockT>& in, vsip::Rand<T>& rander)
+{
+  vsip::Domain<2> sub(vsip::Domain<1>(in.size(1)),
+                      vsip::Domain<1>(in.size(2))); 
+  for (unsigned i = in.size(0); i-- > 0;)
+    fill_random(in(i, vsip::Domain<1>(in.size(1)),
+                      vsip::Domain<1>(in.size(2))), rander);
+}
+
+#else
+// This variant of fill_random is useful for debugging test failures.
+
+// 2D 
+
+template <typename BlockT, typename T>
+void fill_random(
+  vsip::Matrix<T,BlockT> in,
+  vsip::Rand<T>&         /*rander*/)
+{
+  in = T(0);
+  in.block().put(0, 0, T(1.0));
+}
+
+template <typename BlockT, typename T>
+void fill_random(
+  vsip::Matrix<std::complex<T>,BlockT> in,
+  vsip::Rand<std::complex<T> >&        /*rander*/)
+{
+  in = T(0);
+  in.block().put(0, 0, std::complex<T>(1.0, 1.0));
+}
+
+// 3D 
+
+template <typename BlockT, typename T>
+void fill_random(
+  vsip::Tensor<T,BlockT>& in,
+  vsip::Rand<T>&          /*rander*/)
+{
+  in = T(0);
+  in.block().put(0, 0, 0, T(1.0));
+}
+
+#endif
+
+//////
+
+// 2D, cc
+
+template <typename T, typename inBlock, typename outBlock>
+void 
+compute_ref(
+  vsip::Matrix<std::complex<T>,inBlock> const& in,
+  vsip::Domain<2> const& in_dom, 
+  vsip::Matrix<std::complex<T>,outBlock>& ref,
+  vsip::Domain<2> const& out_dom,
+  int (& /* dum */)[1])
+{
+  using vsip::index_type;
+  using vsip::Vector;
+  using vsip::complex;
+
+  assert(in.size(0) == ref.size(0));
+  assert(in.size(1) == ref.size(1));
+  assert(in.size(0) == in_dom[0].size());
+  assert(in.size(1) == in_dom[1].size());
+  assert(ref.size(0) == out_dom[0].size());
+  assert(ref.size(1) == out_dom[1].size());
+
+#if 0
+  // This is faster, but relies on correctness of Fftm.
+  vsip::Fftm<std::complex<T>,std::complex<T>,0,
+             vsip::fft_fwd,vsip::by_reference,1>  fftm_across(in_dom, 1.0);
+  fftm_across(in, ref);
+
+  vsip::Fftm<std::complex<T>,std::complex<T>,1,
+             vsip::fft_fwd,vsip::by_reference,1>  fftm_down(out_dom, 1.0);
+  fftm_down(ref);
+#else
+  // This is slower, but should always be correct.
+  for (index_type r=0; r<in.size(0); ++r)
+    vsip_csl::ref::dft(in.row(r), ref.row(r), -1);
+  Vector<complex<T> > tmp(in.size(0));
+  for (index_type c=0; c<in.size(1); ++c)
+  {
+    tmp = ref.col(c);
+    vsip_csl::ref::dft(tmp, ref.col(c), -1);
+  }
+#endif
+}
+
+// 2D, rc
+
+template <typename T, typename inBlock, typename outBlock>
+void 
+compute_ref(
+  vsip::Matrix<T,inBlock> const& in,
+  vsip::Domain<2> const& in_dom, 
+  vsip::Matrix<std::complex<T>,outBlock>& ref,
+  vsip::Domain<2> const& out_dom,
+  int (& /* dum */)[1])
+{
+  vsip::Fftm<T,std::complex<T>,1,
+    vsip::fft_fwd,vsip::by_reference,1>  fftm_across(in_dom, 1.0);
+  fftm_across(in, ref);
+
+  typedef std::complex<T> CT;
+  vsip::Fftm<CT,CT,0,
+    vsip::fft_fwd,vsip::by_reference,1>  fftm_down(out_dom, 1.0);
+  fftm_down(ref);
+}
+
+// 2D, rc
+
+template <typename T, typename inBlock, typename outBlock>
+void 
+compute_ref(
+  vsip::Matrix<T,inBlock> const& in,
+  vsip::Domain<2> const& in_dom, 
+  vsip::Matrix<std::complex<T>,outBlock>& ref,
+  vsip::Domain<2> const& out_dom,
+  int (& /* dum */)[2])
+{
+  vsip::Fftm<T,std::complex<T>,0,
+    vsip::fft_fwd,vsip::by_reference,1>  fftm_across(in_dom, 1.0);
+  fftm_across(in, ref);
+
+  typedef std::complex<T> CT;
+  vsip::Fftm<CT,CT,1,
+    vsip::fft_fwd,vsip::by_reference,1>  fftm_down(out_dom, 1.0);
+  fftm_down(ref);
+}
+
+// 3D, cc
+
+template <typename T, typename inBlock, typename outBlock>
+void 
+compute_ref(
+  vsip::Tensor<std::complex<T>,inBlock> const& in,
+  vsip::Domain<3> const& in_dom, 
+  vsip::Tensor<std::complex<T>,outBlock>& ref,
+  vsip::Domain<3> const& out_dom, 
+  int (& /* dum */)[1]) 
+{
+  typedef std::complex<T> CT;
+
+  vsip::Fft<vsip::const_Matrix,CT,CT,vsip::fft_fwd,vsip::by_reference,1>  fft_across(
+    vsip::Domain<2>(in_dom[1], in_dom[2]), 1.0);
+  for (unsigned i = in_dom[0].size(); i-- > 0; )
+    fft_across(in(i, in_dom[1], in_dom[2]),
+              ref(i, out_dom[1], out_dom[2]));
+
+  // note: axis ---v--- here is reverse of notation used otherwise.
+  vsip::Fftm<CT,CT,1,vsip::fft_fwd,vsip::by_reference,1>  fftm_down(
+    vsip::Domain<2>(in_dom[0], in_dom[1]), 1.0);
+  for (unsigned k = in_dom[2].size(); k-- > 0; )
+    fftm_down(ref(out_dom[0], out_dom[1], k));
+}
+
+// 3D, rc, shorten bottom-top
+
+template <typename T, typename inBlock, typename outBlock>
+void 
+compute_ref(
+  vsip::Tensor<T,inBlock> const& in,
+  vsip::Domain<3> const& in_dom, 
+  vsip::Tensor<std::complex<T>,outBlock>& ref,
+  vsip::Domain<3> const& out_dom,
+  int (& /* dum */)[1]) 
+{
+  typedef std::complex<T> CT;
+
+  // first, planes left-right, squeeze top-bottom
+  vsip::Fft<vsip::const_Matrix,T,CT,0,vsip::by_reference,1>   fft_across(
+    vsip::Domain<2>(in_dom[0], in_dom[1]), 1.0);
+  for (unsigned k = in_dom[2].size(); k-- > 0; )
+    fft_across(in(in_dom[0], in_dom[1], k),
+            ref(out_dom[0], out_dom[1], k));
+
+  // planes top-bottom, running left-right
+  // note: axis ---v--- here is reverse of notation used otherwise.
+  vsip::Fftm<CT,CT,0,vsip::fft_fwd,vsip::by_reference,1>   fftm_down(
+    vsip::Domain<2>(in_dom[1], in_dom[2]), 1.0);
+  for (unsigned i = out_dom[0].size(); i-- > 0; )
+    fftm_down(ref(i, out_dom[1], out_dom[2]));
+}
+
+// 3D, rc, shorten front->back
+
+template <typename T, typename inBlock, typename outBlock>
+void 
+compute_ref(
+  vsip::Tensor<T,inBlock> const& in,
+  vsip::Domain<3> const& in_dom, 
+  vsip::Tensor<std::complex<T>,outBlock>& ref,
+  vsip::Domain<3> const& out_dom, 
+  int (& /* dum */)[2]) 
+{
+  typedef std::complex<T> CT;
+
+  // planes top-bottom, squeeze front-back
+  vsip::Fft<vsip::const_Matrix,T,CT,0,vsip::by_reference,1>   fft_across(
+    vsip::Domain<2>(in_dom[1], in_dom[2]), 1.0);
+  for (unsigned i = in_dom[0].size(); i-- > 0; )
+    fft_across(in(i, in_dom[1], in_dom[2]),
+              ref(i, out_dom[1], out_dom[2]));
+
+  // planes front-back, running bottom-top
+  // note: axis ---v--- here is reverse of notation used otherwise.
+  vsip::Fftm<CT,CT,1,vsip::fft_fwd,vsip::by_reference,1>   fftm_down(
+    vsip::Domain<2>(in_dom[0], in_dom[2]), 1.0);
+  for (unsigned j = out_dom[1].size(); j-- > 0; )
+    fftm_down(ref(out_dom[0], j, out_dom[2]));
+}
+
+// 3D, rc, shorten left-right
+
+template <typename T, typename inBlock, typename outBlock>
+void 
+compute_ref(
+  vsip::Tensor<T,inBlock> const& in,
+  vsip::Domain<3> const& in_dom, 
+  vsip::Tensor<std::complex<T>,outBlock>& ref,
+  vsip::Domain<3> const& out_dom, 
+  int (& /* dum */)[3])
+{
+  typedef std::complex<T> CT;
+
+  // planes top-bottom, squeeze left-right
+  vsip::Fft<vsip::const_Matrix,T,CT,1,vsip::by_reference,1>   fft_across(
+    vsip::Domain<2>(in_dom[1], in_dom[2]), 1.0);
+  for (unsigned i = in_dom[0].size(); i-- > 0; )
+    fft_across(in(i, in_dom[1], in_dom[2]),
+              ref(i, out_dom[1], out_dom[2]));
+
+  // planes left-right, running bottom-top
+  // note: axis ---v--- here is reverse of notation used otherwise.
+  vsip::Fftm<CT,CT,1,vsip::fft_fwd,vsip::by_reference,1>   fftm_down(
+    vsip::Domain<2>(in_dom[0], in_dom[1]), 1.0);
+  for (unsigned k = out_dom[2].size(); k-- > 0; )
+    fftm_down(ref(out_dom[0], out_dom[1], k));
+}
+
+template <unsigned Dim, typename T1, typename T2,
+	  int sD, vsip::return_mechanism_type How>
+struct Test_fft;
+
+template <typename T1, typename T2, int sD, vsip::return_mechanism_type How>
+struct Test_fft<2,T1,T2,sD,How>
+{ typedef vsip::Fft<vsip::const_Matrix,T1,T2,sD,How,1,vsip::alg_time>  type; };
+
+template <typename T1, typename T2, int sD, vsip::return_mechanism_type How>
+struct Test_fft<3,T1,T2,sD,How>
+{ typedef vsip::Fft<vsip::const_Tensor,T1,T2,sD,How,1,vsip::alg_time>  type; };
+
+
+
+// check_in_place
+//
+
+// there is no in-place for real->complex
+
+template <template <typename,typename> class ViewT1,
+          template <typename,typename> class ViewT2,
+          template <typename,typename> class ViewT3,
+	  typename T, typename Block1, typename Block2, int sDf, int sDi>
+void
+check_in_place(
+  vsip::Fft<ViewT1,T,std::complex<T>,sDf,vsip::by_reference,1,vsip::alg_time>&,
+  vsip::Fft<ViewT1,std::complex<T>,T,sDi,vsip::by_reference,1,vsip::alg_time>&,
+  ViewT2<T,Block1>&, ViewT3<std::complex<T>,Block2>&, double)
+{ }
+
+template <template <typename,typename> class ViewT1,
+          template <typename,typename> class ViewT2,
+          template <typename,typename> class ViewT3,
+	  typename T, typename Block1, typename Block2>
+void
+check_in_place(
+  vsip::Fft<ViewT1,T,T,vsip::fft_fwd,vsip::by_reference,1,vsip::alg_time>&  fwd,
+  vsip::Fft<ViewT1,T,T,vsip::fft_inv,vsip::by_reference,1,vsip::alg_time>&  inv,
+  ViewT2<T,Block1> const&  in,
+  ViewT3<T,Block2> const&  ref,
+  double scalei)
+{
+  typename vsip::impl::View_of_dim<Block1::dim,T,Block1>::type  inout(
+    force_copy_init(in));
+
+  fwd(inout);
+  test_assert(error_db(inout, ref) < -100); 
+
+  inv(inout);
+  inout *= T(scalei);
+  test_assert(error_db(inout, in) < -100); 
+}
+
+
+
+// when testing matrices, will use latter two values
+
+unsigned  sizes[][3] =
+{
+#if TEST_NON_POWER_OF_2
+  { 2, 2, 2 },
+#endif
+  { 8, 8, 8 },
+#if TEST_NON_POWER_OF_2
+  { 1, 1, 1 },
+  { 2, 2, 1 },
+  { 2, 4, 8 },
+  { 2, 8, 128 },
+  { 3, 5, 7 },
+  { 2, 24, 48 },
+  { 24, 1, 5 },
+#endif
+};
+
+
+
+
+
+//   the generic test
+
+template <unsigned InBlockType,
+	  unsigned OutBlockType,
+	  typename InT,
+	  typename OutT,
+          unsigned Dim,
+	  int      sD>
+void 
+test_fft()
+{
+  bool const isReal = !vsip::impl::Is_complex<InT>::value;
+
+  typedef InT  in_elt_type;
+  typedef OutT out_elt_type;
+
+  static const int sdf = (sD < 0) ? vsip::fft_fwd : sD;
+  static const int sdi = (sD < 0) ? vsip::fft_inv : sD;
+  typedef typename Test_fft<Dim,in_elt_type,out_elt_type,
+                    sdf,vsip::by_reference>::type         fwd_by_ref_type;
+  typedef typename Test_fft<Dim,in_elt_type,out_elt_type,
+                    sdf,vsip::by_value>::type             fwd_by_value_type;
+  typedef typename Test_fft<Dim,out_elt_type,in_elt_type,
+                    sdi,vsip::by_reference>::type         inv_by_ref_type;
+  typedef typename Test_fft<Dim,out_elt_type,in_elt_type,
+                    sdi,vsip::by_value>::type             inv_by_value_type;
+
+  typedef typename Arg<Dim,in_elt_type,InBlockType>::type    in_type;
+  typedef typename Arg<Dim,out_elt_type,OutBlockType>::type  out_type;
+
+  for (unsigned i = 0; i < sizeof(sizes)/sizeof(*sizes); ++i)
+  {
+    vsip::Rand<in_elt_type> rander(
+      sizes[i][0] * sizes[i][1] * sizes[i][2] * Dim * (sD+5));
+
+#if VERBOSE
+    std::cout << "test_fft Dim: " << Dim
+	      << "  Size: " << sizes[i][0] << ", "
+	                    << sizes[i][1] << ", "
+	                    << sizes[i][2] << "  "
+	      << Type_name<InT>::name() << " -> "
+	      << Type_name<OutT>::name()
+	      << std::endl;
+#endif
+
+    vsip::Domain<Dim>  in_dom(make_dom<Dim>(sizes[i], false, sD, isReal)); 
+    vsip::Domain<Dim>  out_dom(make_dom<Dim>(sizes[i], isReal, sD, isReal)); 
+
+    typedef typename in_type::block_type   in_block_type;
+    typedef typename out_type::block_type  out_block_type;
+
+    in_block_type  in_block(in_dom);
+    in_type  in(in_block);
+    fill_random(in, rander);
+    in_type  in_copy(force_copy_init(in));
+
+    out_block_type  ref1_block(out_dom);
+    out_type  ref1(ref1_block);
+    int dum[(sD < 0) ? 1 : sD + 1];
+    compute_ref(in, in_dom, ref1, out_dom, dum);
+
+    out_type  ref4(force_copy_init(ref1));
+    ref4 *= out_elt_type(0.25);
+
+    out_type  refN(force_copy_init(ref1));
+    refN /= out_elt_type(in_dom.size());
+
+    test_assert(error_db(in, in_copy) < -200);  // not clobbered
+
+    { fwd_by_ref_type  fft_ref1(in_dom, 1.0);
+      out_block_type  out_block(out_dom);
+      out_type  out(out_block);
+      out_type  other = fft_ref1(in, out);
+      test_assert(&out.block() == &other.block());
+      test_assert(error_db(in, in_copy) < -200);  // not clobbered
+      test_assert(error_db(out, ref1) < -100); 
+
+      inv_by_ref_type  inv_refN(in_dom, 1.0/in_dom.size());
+      in_block_type  in2_block(in_dom);
+      in_type  in2(in2_block);
+      inv_refN(out, in2);
+      check_error(out, ref1, -100);  // not clobbered
+      check_error(in2, in,   -100); 
+
+      check_in_place(fft_ref1, inv_refN, in, ref1, 1.0);
+    }
+    { fwd_by_ref_type  fft_ref4(in_dom, 0.25);
+      out_block_type   out_block(out_dom);
+      out_type         out(out_block);
+      out_type         other = fft_ref4(in, out);
+      test_assert(&out.block() == &other.block());
+      check_error(in, in_copy, -200);  // not clobbered
+      check_error(out, ref4, -100); // XXXXX
+
+      inv_by_ref_type  inv_ref8(in_dom, .125);
+      in_block_type  in2_block(in_dom);
+      in_type  in2(in2_block);
+      inv_ref8(out, in2);
+      test_assert(error_db(out, ref4) < -100);  // not clobbered
+      in2 /= in_elt_type(in_dom.size() / 32.0);
+      test_assert(error_db(in2, in) < -100); 
+
+      check_in_place(fft_ref4, inv_ref8, in, ref4, 32.0/in_dom.size());
+    }
+    { fwd_by_ref_type  fft_refN(in_dom, 1.0/in_dom.size());
+      out_block_type  out_block(out_dom);
+      out_type  out(out_block);
+      out_type  other = fft_refN(in, out);
+      test_assert(&out.block() == &other.block());
+      test_assert(error_db(in, in_copy) < -200);  // not clobbered
+      test_assert(error_db(out, refN) < -100); 
+
+      inv_by_ref_type  inv_ref1(in_dom, 1.0);
+      in_block_type  in2_block(in_dom);
+      in_type  in2(in2_block);
+      inv_ref1(out, in2);
+      test_assert(error_db(out, refN) < -100);  // not clobbered
+      test_assert(error_db(in2, in) < -100); 
+
+      check_in_place(fft_refN, inv_ref1, in, refN, 1.0);
+    }
+    
+
+    { fwd_by_value_type  fwd_val1(in_dom, 1.0);
+      out_type  out(fwd_val1(in));
+      test_assert(error_db(in, in_copy) < -200);  // not clobbered
+      test_assert(error_db(out, ref1) < -100); 
+
+      inv_by_value_type  inv_valN(in_dom, 1.0/in_dom.size());
+      in_type  in2(inv_valN(out));
+      test_assert(error_db(out, ref1) < -100);    // not clobbered
+      test_assert(error_db(in2, in) < -100); 
+    }
+    { fwd_by_value_type  fwd_val4(in_dom, 0.25);
+      out_type  out(fwd_val4(in));
+      test_assert(error_db(in, in_copy) < -200);  // not clobbered
+      test_assert(error_db(out, ref4) < -100); 
+
+      inv_by_value_type  inv_val8(in_dom, 0.125);
+      in_type  in2(inv_val8(out));
+      test_assert(error_db(out, ref4) < -100);    // not clobbered
+      in2 /= in_elt_type(in_dom.size() / 32.0);
+      test_assert(error_db(in2, in) < -100); 
+    }
+    { fwd_by_value_type  fwd_valN(in_dom, 1.0/in_dom.size());
+      out_type  out(fwd_valN(in));
+      test_assert(error_db(in, in_copy) < -200);  // not clobbered
+      test_assert(error_db(out, refN) < -100); 
+
+      inv_by_value_type  inv_val1(in_dom, 1.0);
+      in_type  in2(inv_val1(out));
+      test_assert(error_db(out, refN) < -100);    // not clobbered
+      test_assert(error_db(in2, in) < -100); 
+    }
+  }
+};
+
+
+
+void
+show_config()
+{
+#if VERBOSE
+
+  std::cout << "backends:" << std::endl;
+
+#if defined(VSIP_IMPL_FFTW3)
+  std::cout << " - fftw3:" << std::endl;
+#endif
+#if defined(VSIP_IMPL_IPP_FFT)
+  std::cout << " - ipp" << std::endl;
+#endif
+#if defined(VSIP_IMPL_SAL_FFT)
+  std::cout << " - sal" << std::endl;
+#endif
+
+
+#if TEST_2D_CC
+  std::cout << "test 2D CC" << std::endl;
+#endif
+#if TEST_2D_RC
+  std::cout << "test 2D RC" << std::endl;
+#endif
+#if TEST_3D_CC
+  std::cout << "test 2D CC" << std::endl;
+#endif
+#if TEST_3D_RC
+  std::cout << "test 2D RC" << std::endl;
+#endif
+
+#endif
+}
+
+#endif // VSIP_TESTS_FFT_COMMON_HPP
Index: tests/fft2d.cpp
===================================================================
--- tests/fft2d.cpp	(revision 0)
+++ tests/fft2d.cpp	(revision 0)
@@ -0,0 +1,165 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/fft.cpp
+    @author  Jules Bergmann
+    @date    2005-06-17
+    @brief   VSIPL++ Library: Testcases for Fft.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+// Set to 1 to enable verbose output.
+#define VERBOSE     0
+// Set to 0 to disble use of random values.
+#define FILL_RANDOM 1
+
+#include <cmath>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip/core/config.hpp>
+#include <vsip/core/metaprogramming.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/error_db.hpp>
+#include <vsip_csl/ref_dft.hpp>
+
+#if VERBOSE
+#  include <iostream>
+#  include <vsip_csl/output.hpp>
+#  include "extdata-output.hpp"
+#endif
+
+#include "fft_common.hpp"
+
+
+#if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_SAL_FFT)
+#  define TEST_2D_CC 1
+#endif
+
+#if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_SAL_FFT)
+#  define TEST_2D_RC 1
+#endif
+
+#if defined(VSIP_IMPL_FFTW3)
+#  define TEST_3D_CC 1
+#endif
+
+#  define TEST_3D_RC 0
+
+#if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_IPP_FFT)
+#  define TEST_NON_POWER_OF_2 1
+#endif
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+
+
+// Setup input data for Fft.
+
+template <typename T,
+	  typename Block>
+void
+setup_data(int set, Vector<T, Block> in, float scale = 1)
+{
+  length_type const N = in.size();
+
+  switch(set)
+  {
+  default:
+  case 0:
+    in    = T();
+    break;
+  case 1:
+    in    = T();
+    in(0) = T(scale);
+    break;
+  case 2:
+    in    = T();
+    in(0) = T(1);
+    if (N >  1) in(Domain<1>(0, 1, N))    += T(3);
+    if (N >  4) in(Domain<1>(0, 4, N/4))  += T(-2);
+    if (N > 13) in(Domain<1>(0, 13, N/13)) += T(7);
+    if (N > 27) in(Domain<1>(0, 27, N/27)) += T(-15);
+    if (N > 37) in(Domain<1>(0, 37, N/37)) += T(31);
+    break;
+  case 3:
+    in    = T(scale);
+    break;
+  }
+}
+
+
+
+// check 2D, 3D
+
+template <typename T>
+void
+test_nd()
+{
+#if TEST_2D_CC
+  test_fft<0,0,complex<T>, complex<T> ,2,vsip::fft_fwd>();
+#endif
+
+#if TEST_2D_RC
+  test_fft<0,0,T,complex<T>,2,1>();
+  test_fft<0,0,T,complex<T>,2,0>();
+#endif
+
+#if TEST_3D_CC
+  test_fft<0,0,complex<T>,complex<T>,3,vsip::fft_fwd>();
+#endif
+
+#if TEST_3D_RC
+  test_fft<0,0,T,complex<T>,3,2>();
+  test_fft<0,0,T,complex<T>,3,1>();
+  test_fft<0,0,T,complex<T>,3,0>();
+#endif
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  // show_config();
+
+//
+// check 2D, 3D
+//
+
+#if VSIP_IMPL_PROVIDE_FFT_FLOAT
+  test_nd<float>();
+#endif 
+
+#if VSIP_IMPL_PROVIDE_FFT_DOUBLE && VSIP_IMPL_TEST_DOUBLE
+  test_nd<double>();
+#endif
+
+#if VSIP_IMPL_PROVIDE_FFT_LONG_DOUBLE
+  test_nd<long double>();
+#endif
+
+  return 0;
+}
Index: tests/coverage_unary.cpp
===================================================================
--- tests/coverage_unary.cpp	(revision 173072)
+++ tests/coverage_unary.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -38,14 +38,6 @@
 TEST_UNARY(copy,   ,      ,     anyval)
 TEST_UNARY(neg,   -,     -,     anyval)
 TEST_UNARY(mag,   mag,   mag,   anyval)
-TEST_UNARY(sin,   sin,   sin,   anyval)
-TEST_UNARY(cos,   cos,   cos,   anyval)
-TEST_UNARY(tan,   tan,   tan,   anyval)
-TEST_UNARY(atan,  atan,  atan,  anyval)
-TEST_UNARY(log,   log,   log,   posval)
-TEST_UNARY(log10, log10, log10, posval)
-TEST_UNARY(exp,   exp,   exp,   posval)
-TEST_UNARY(exp10, exp10, exp10, posval)
 TEST_UNARY(sqrt,  sqrt,  sqrt,  posval)
 TEST_UNARY(rsqrt, rsqrt, rsqrt, posval)
 TEST_UNARY(sq,    sq,    sq,    anyval)
@@ -72,10 +64,6 @@
   vector_cases2<Test_neg, float>();
   vector_cases2<Test_mag, float>();
   vector_cases2_rt<Test_mag, complex<float>,  float>();
-  vector_cases2<Test_cos, float>();
-  vector_cases2<Test_atan, float>();
-  vector_cases2<Test_log, float>();
-  vector_cases2<Test_exp, float>();
   vector_cases2<Test_sqrt, float>();
   vector_cases2<Test_sq, float>();
   vector_cases2<Test_copy, float>();
@@ -97,29 +85,6 @@
   vector_cases2<Test_mag, double>();
   vector_cases2_rt<Test_mag, complex<float>,  float>();
 
-  vector_cases2<Test_cos, float>();
-  vector_cases2<Test_cos, double>();
-
-  vector_cases2<Test_sin, float>();
-  vector_cases2<Test_sin, double>();
-
-  vector_cases2<Test_tan, float>();
-
-  vector_cases2<Test_atan, float>();
-  vector_cases2<Test_atan, double>();
-
-  vector_cases2<Test_log, float>();
-  vector_cases2<Test_log, double>();
-
-  vector_cases2<Test_log10, float>();
-  vector_cases2<Test_log10, double>();
-
-  vector_cases2<Test_exp, float>();
-  vector_cases2<Test_exp, double>();
-
-  vector_cases2<Test_exp10, float>();
-  vector_cases2<Test_exp10, double>();
-
   vector_cases2<Test_sqrt, float>();
   vector_cases2<Test_sqrt, double>();
   vector_cases2<Test_sqrt, complex<float> >();
Index: tests/fft.cpp
===================================================================
--- tests/fft.cpp	(revision 174264)
+++ tests/fft.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -40,27 +40,9 @@
 #  include "extdata-output.hpp"
 #endif
 
+#include "fft_common.hpp"
 
-#if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_SAL_FFT)
-#  define TEST_2D_CC 1
-#endif
 
-#if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_SAL_FFT)
-#  define TEST_2D_RC 1
-#endif
-
-#if defined(VSIP_IMPL_FFTW3)
-#  define TEST_3D_CC 1
-#endif
-
-#  define TEST_3D_RC 0
-
-#if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_IPP_FFT)
-#  define TEST_NON_POWER_OF_2 1
-#endif
-
-
-
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -71,32 +53,6 @@
 
 
 
-template <template <typename, typename> class View1,
-	  template <typename, typename> class View2,
-	  typename                            T1,
-	  typename                            T2,
-	  typename                            Block1,
-	  typename                            Block2>
-inline void
-check_error(
-  View1<T1, Block1> v1,
-  View2<T2, Block2> v2,
-  double            epsilon)
-{
-  double error = error_db(v1, v2);
-#if VERBOSE
-  if (error >= epsilon)
-  {
-    std::cout << "check_error: error >= epsilon" << std::endl;
-    std::cout << "  error   = " << error   << std::endl;
-    std::cout << "  epsilon = " << epsilon << std::endl;
-    std::cout << "  v1 =\n" << v1;
-    std::cout << "  v2 =\n" << v2;
-  }
-#endif
-  test_assert(error < epsilon);
-}
-
 // Setup input data for Fft.
 
 template <typename T,
@@ -277,606 +233,8 @@
   test_assert(error_db(ref,out) < -100);
 }
 
-/////////////////////////////////////////////////////////////////////
-//
-// Comprehensive 2D, 3D test
-//
 
-template <unsigned Dim, typename T, unsigned L> struct Arg;
 
-template <unsigned Dim, typename T> 
-struct Arg<Dim,T,0>
-{
-  typedef typename vsip::impl::View_of_dim<Dim,T,
-    vsip::Dense<Dim,T,typename vsip::impl::Row_major<Dim>::type> >::type type;
-};
-
-template <unsigned Dim, typename T> 
-struct Arg<Dim,T,1>
-{
-  typedef typename vsip::impl::View_of_dim<Dim,T,
-    vsip::Dense<Dim,T,typename vsip::impl::Col_major<Dim>::type> >::type type;
-};
-
-template <unsigned Dim, typename T> 
-struct Arg<Dim,T,2>
-{
-  typedef typename vsip::impl::View_of_dim<Dim,T,
-    vsip::impl::Fast_block<Dim,T,
-      vsip::impl::Layout<Dim,
-        typename vsip::impl::Row_major<Dim>::type,
-        vsip::impl::Stride_unit_dense
-  > > >::type type;
-};
-
-inline unsigned 
-adjust_size(unsigned size, bool is_short, bool is_short_dim, bool no_odds)
-{ 
-  // no odd sizes along axis for real->complex
-  if ((size & 1) && no_odds && is_short_dim)
-    ++size;
-  return (is_short && is_short_dim) ? size / 2 + 1 : size;
-}
-
-template <unsigned Dim> vsip::Domain<Dim> make_dom(unsigned*, bool, int, bool);
-template <> vsip::Domain<2> make_dom<2>(
-  unsigned* d, bool is_short, int sd, bool no_odds)
-{
-  return  vsip::Domain<2>(
-    vsip::Domain<1>(adjust_size(d[1], is_short, sd == 0, no_odds)),
-    vsip::Domain<1>(adjust_size(d[2], is_short, sd == 1, no_odds)));
-} 
-template <> vsip::Domain<3> make_dom<3>(
-  unsigned* d, bool is_short, int sd, bool no_odds)
-{
-  return vsip::Domain<3>(
-    vsip::Domain<1>(adjust_size(d[0], is_short, sd == 0, no_odds)),
-    vsip::Domain<1>(adjust_size(d[1], is_short, sd == 1, no_odds)),
-    vsip::Domain<1>(adjust_size(d[2], is_short, sd == 2, no_odds)));
-} 
-
-template <typename T, typename BlockT>
-vsip::Domain<2>
-domain_of(vsip::Matrix<T,BlockT> const& src)
-{
-  return vsip::Domain<2>(vsip::Domain<1>(src.size(0)),
-                         vsip::Domain<1>(src.size(1)));
-} 
- 
-
-template <typename T, typename BlockT>
-vsip::Domain<3>
-domain_of(vsip::Tensor<T,BlockT> const& src)
-{
-  return vsip::Domain<2>(vsip::Domain<1>(src.size(0)),
-                         vsip::Domain<1>(src.size(1)),
-                         vsip::Domain<1>(src.size(2)));
-} 
-
-//
-
-template <typename T, typename BlockT>
-vsip::Matrix<T,BlockT>
-force_copy_init(vsip::Matrix<T,BlockT> const& src)
-{ 
-  vsip::Matrix<T,BlockT> tmp(src.size(0), src.size(1));
-  tmp = src;
-  return tmp;
-}
-
-template <typename T, typename BlockT>
-vsip::Tensor<T,BlockT>
-force_copy_init(vsip::Tensor<T,BlockT> const& src)
-{ 
-  vsip::Tensor<T,BlockT> tmp(src.size(0), src.size(1), src.size(2));
-  tmp = src;
-  return tmp;
-}
-
-//
-
-template <typename T> void set_values(T& v1, T& v2)
-{ v1 = T(10); v2 = T(20); }
-
-template <typename T> void set_values(std::complex<T>& z1, std::complex<T>& z2)
-{
-  z1 = std::complex<T>(T(10), T(10));
-  z2 = std::complex<T>(T(20), T(20));
-}
-
-#if FILL_RANDOM
-// In normal testing, fill_random fills a view with random values.
-
-// 2D 
-
-template <typename BlockT, typename T>
-void fill_random(
-  vsip::Matrix<T,BlockT> in, vsip::Rand<T>& rander)
-{
-  in = (rander.randu(in.size(0), in.size(1)) * 20.0) - 10.0;
-}
-
-template <typename BlockT, typename T>
-void fill_random(
-  vsip::Matrix<std::complex<T>,BlockT> in,
-  vsip::Rand<std::complex<T> >& rander)
-{
-  in = rander.randu(in.size(0), in.size(1)) * std::complex<T>(20.0) -
-         std::complex<T>(10.0, 10.0);
-}
-
-// 3D 
-
-template <typename BlockT, typename T>
-void fill_random(
-  vsip::Tensor<T,BlockT>& in, vsip::Rand<T>& rander)
-{
-  vsip::Domain<2> sub(vsip::Domain<1>(in.size(1)),
-                      vsip::Domain<1>(in.size(2))); 
-  for (unsigned i = in.size(0); i-- > 0;)
-    fill_random(in(i, vsip::Domain<1>(in.size(1)),
-                      vsip::Domain<1>(in.size(2))), rander);
-}
-
-#else
-// This variant of fill_random is useful for debugging test failures.
-
-// 2D 
-
-template <typename BlockT, typename T>
-void fill_random(
-  vsip::Matrix<T,BlockT> in,
-  vsip::Rand<T>&         /*rander*/)
-{
-  in = T(0);
-  in.block().put(0, 0, T(1.0));
-}
-
-template <typename BlockT, typename T>
-void fill_random(
-  vsip::Matrix<std::complex<T>,BlockT> in,
-  vsip::Rand<std::complex<T> >&        /*rander*/)
-{
-  in = T(0);
-  in.block().put(0, 0, std::complex<T>(1.0, 1.0));
-}
-
-// 3D 
-
-template <typename BlockT, typename T>
-void fill_random(
-  vsip::Tensor<T,BlockT>& in,
-  vsip::Rand<T>&          /*rander*/)
-{
-  in = T(0);
-  in.block().put(0, 0, 0, T(1.0));
-}
-
-#endif
-
-//////
-
-// 2D, cc
-
-template <typename T, typename inBlock, typename outBlock>
-void 
-compute_ref(
-  vsip::Matrix<std::complex<T>,inBlock> const& in,
-  vsip::Domain<2> const& in_dom, 
-  vsip::Matrix<std::complex<T>,outBlock>& ref,
-  vsip::Domain<2> const& out_dom,
-  int (& /* dum */)[1])
-{
-  assert(in.size(0) == ref.size(0));
-  assert(in.size(1) == ref.size(1));
-  assert(in.size(0) == in_dom[0].size());
-  assert(in.size(1) == in_dom[1].size());
-  assert(ref.size(0) == out_dom[0].size());
-  assert(ref.size(1) == out_dom[1].size());
-
-#if 0
-  // This is faster, but relies on correctness of Fftm.
-  vsip::Fftm<std::complex<T>,std::complex<T>,0,
-             vsip::fft_fwd,vsip::by_reference,1>  fftm_across(in_dom, 1.0);
-  fftm_across(in, ref);
-
-  vsip::Fftm<std::complex<T>,std::complex<T>,1,
-             vsip::fft_fwd,vsip::by_reference,1>  fftm_down(out_dom, 1.0);
-  fftm_down(ref);
-#else
-  // This is slower, but should always be correct.
-  for (index_type r=0; r<in.size(0); ++r)
-    ref::dft(in.row(r), ref.row(r), -1);
-  Vector<complex<T> > tmp(in.size(0));
-  for (index_type c=0; c<in.size(1); ++c)
-  {
-    tmp = ref.col(c);
-    ref::dft(tmp, ref.col(c), -1);
-  }
-#endif
-}
-
-// 2D, rc
-
-template <typename T, typename inBlock, typename outBlock>
-void 
-compute_ref(
-  vsip::Matrix<T,inBlock> const& in,
-  vsip::Domain<2> const& in_dom, 
-  vsip::Matrix<std::complex<T>,outBlock>& ref,
-  vsip::Domain<2> const& out_dom,
-  int (& /* dum */)[1])
-{
-  vsip::Fftm<T,std::complex<T>,1,
-    vsip::fft_fwd,vsip::by_reference,1>  fftm_across(in_dom, 1.0);
-  fftm_across(in, ref);
-
-  typedef std::complex<T> CT;
-  vsip::Fftm<CT,CT,0,
-    vsip::fft_fwd,vsip::by_reference,1>  fftm_down(out_dom, 1.0);
-  fftm_down(ref);
-}
-
-// 2D, rc
-
-template <typename T, typename inBlock, typename outBlock>
-void 
-compute_ref(
-  vsip::Matrix<T,inBlock> const& in,
-  vsip::Domain<2> const& in_dom, 
-  vsip::Matrix<std::complex<T>,outBlock>& ref,
-  vsip::Domain<2> const& out_dom,
-  int (& /* dum */)[2])
-{
-  vsip::Fftm<T,std::complex<T>,0,
-    vsip::fft_fwd,vsip::by_reference,1>  fftm_across(in_dom, 1.0);
-  fftm_across(in, ref);
-
-  typedef std::complex<T> CT;
-  vsip::Fftm<CT,CT,1,
-    vsip::fft_fwd,vsip::by_reference,1>  fftm_down(out_dom, 1.0);
-  fftm_down(ref);
-}
-
-// 3D, cc
-
-template <typename T, typename inBlock, typename outBlock>
-void 
-compute_ref(
-  vsip::Tensor<std::complex<T>,inBlock> const& in,
-  vsip::Domain<3> const& in_dom, 
-  vsip::Tensor<std::complex<T>,outBlock>& ref,
-  vsip::Domain<3> const& out_dom, 
-  int (& /* dum */)[1]) 
-{
-  typedef std::complex<T> CT;
-
-  vsip::Fft<vsip::const_Matrix,CT,CT,vsip::fft_fwd,vsip::by_reference,1>  fft_across(
-    vsip::Domain<2>(in_dom[1], in_dom[2]), 1.0);
-  for (unsigned i = in_dom[0].size(); i-- > 0; )
-    fft_across(in(i, in_dom[1], in_dom[2]),
-              ref(i, out_dom[1], out_dom[2]));
-
-  // note: axis ---v--- here is reverse of notation used otherwise.
-  vsip::Fftm<CT,CT,1,vsip::fft_fwd,vsip::by_reference,1>  fftm_down(
-    vsip::Domain<2>(in_dom[0], in_dom[1]), 1.0);
-  for (unsigned k = in_dom[2].size(); k-- > 0; )
-    fftm_down(ref(out_dom[0], out_dom[1], k));
-}
-
-// 3D, rc, shorten bottom-top
-
-template <typename T, typename inBlock, typename outBlock>
-void 
-compute_ref(
-  vsip::Tensor<T,inBlock> const& in,
-  vsip::Domain<3> const& in_dom, 
-  vsip::Tensor<std::complex<T>,outBlock>& ref,
-  vsip::Domain<3> const& out_dom,
-  int (& /* dum */)[1]) 
-{
-  typedef std::complex<T> CT;
-
-  // first, planes left-right, squeeze top-bottom
-  vsip::Fft<vsip::const_Matrix,T,CT,0,vsip::by_reference,1>   fft_across(
-    vsip::Domain<2>(in_dom[0], in_dom[1]), 1.0);
-  for (unsigned k = in_dom[2].size(); k-- > 0; )
-    fft_across(in(in_dom[0], in_dom[1], k),
-            ref(out_dom[0], out_dom[1], k));
-
-  // planes top-bottom, running left-right
-  // note: axis ---v--- here is reverse of notation used otherwise.
-  vsip::Fftm<CT,CT,0,vsip::fft_fwd,vsip::by_reference,1>   fftm_down(
-    vsip::Domain<2>(in_dom[1], in_dom[2]), 1.0);
-  for (unsigned i = out_dom[0].size(); i-- > 0; )
-    fftm_down(ref(i, out_dom[1], out_dom[2]));
-}
-
-// 3D, rc, shorten front->back
-
-template <typename T, typename inBlock, typename outBlock>
-void 
-compute_ref(
-  vsip::Tensor<T,inBlock> const& in,
-  vsip::Domain<3> const& in_dom, 
-  vsip::Tensor<std::complex<T>,outBlock>& ref,
-  vsip::Domain<3> const& out_dom, 
-  int (& /* dum */)[2]) 
-{
-  typedef std::complex<T> CT;
-
-  // planes top-bottom, squeeze front-back
-  vsip::Fft<vsip::const_Matrix,T,CT,0,vsip::by_reference,1>   fft_across(
-    vsip::Domain<2>(in_dom[1], in_dom[2]), 1.0);
-  for (unsigned i = in_dom[0].size(); i-- > 0; )
-    fft_across(in(i, in_dom[1], in_dom[2]),
-              ref(i, out_dom[1], out_dom[2]));
-
-  // planes front-back, running bottom-top
-  // note: axis ---v--- here is reverse of notation used otherwise.
-  vsip::Fftm<CT,CT,1,vsip::fft_fwd,vsip::by_reference,1>   fftm_down(
-    vsip::Domain<2>(in_dom[0], in_dom[2]), 1.0);
-  for (unsigned j = out_dom[1].size(); j-- > 0; )
-    fftm_down(ref(out_dom[0], j, out_dom[2]));
-}
-
-// 3D, rc, shorten left-right
-
-template <typename T, typename inBlock, typename outBlock>
-void 
-compute_ref(
-  vsip::Tensor<T,inBlock> const& in,
-  vsip::Domain<3> const& in_dom, 
-  vsip::Tensor<std::complex<T>,outBlock>& ref,
-  vsip::Domain<3> const& out_dom, 
-  int (& /* dum */)[3])
-{
-  typedef std::complex<T> CT;
-
-  // planes top-bottom, squeeze left-right
-  vsip::Fft<vsip::const_Matrix,T,CT,1,vsip::by_reference,1>   fft_across(
-    vsip::Domain<2>(in_dom[1], in_dom[2]), 1.0);
-  for (unsigned i = in_dom[0].size(); i-- > 0; )
-    fft_across(in(i, in_dom[1], in_dom[2]),
-              ref(i, out_dom[1], out_dom[2]));
-
-  // planes left-right, running bottom-top
-  // note: axis ---v--- here is reverse of notation used otherwise.
-  vsip::Fftm<CT,CT,1,vsip::fft_fwd,vsip::by_reference,1>   fftm_down(
-    vsip::Domain<2>(in_dom[0], in_dom[1]), 1.0);
-  for (unsigned k = out_dom[2].size(); k-- > 0; )
-    fftm_down(ref(out_dom[0], out_dom[1], k));
-}
-
-template <unsigned Dim, typename T1, typename T2,
-	  int sD, vsip::return_mechanism_type How>
-struct Test_fft;
-
-template <typename T1, typename T2, int sD, vsip::return_mechanism_type How>
-struct Test_fft<2,T1,T2,sD,How>
-{ typedef vsip::Fft<vsip::const_Matrix,T1,T2,sD,How,1,vsip::alg_time>  type; };
-
-template <typename T1, typename T2, int sD, vsip::return_mechanism_type How>
-struct Test_fft<3,T1,T2,sD,How>
-{ typedef vsip::Fft<vsip::const_Tensor,T1,T2,sD,How,1,vsip::alg_time>  type; };
-
-// check_in_place
-//
-
-// there is no in-place for real->complex
-
-template <template <typename,typename> class ViewT1,
-          template <typename,typename> class ViewT2,
-          template <typename,typename> class ViewT3,
-	  typename T, typename Block1, typename Block2, int sDf, int sDi>
-void
-check_in_place(
-  vsip::Fft<ViewT1,T,std::complex<T>,sDf,vsip::by_reference,1,vsip::alg_time>&,
-  vsip::Fft<ViewT1,std::complex<T>,T,sDi,vsip::by_reference,1,vsip::alg_time>&,
-  ViewT2<T,Block1>&, ViewT3<std::complex<T>,Block2>&, double)
-{ }
-
-template <template <typename,typename> class ViewT1,
-          template <typename,typename> class ViewT2,
-          template <typename,typename> class ViewT3,
-	  typename T, typename Block1, typename Block2>
-void
-check_in_place(
-  vsip::Fft<ViewT1,T,T,vsip::fft_fwd,vsip::by_reference,1,vsip::alg_time>&  fwd,
-  vsip::Fft<ViewT1,T,T,vsip::fft_inv,vsip::by_reference,1,vsip::alg_time>&  inv,
-  ViewT2<T,Block1> const&  in,
-  ViewT3<T,Block2> const&  ref,
-  double scalei)
-{
-  typename vsip::impl::View_of_dim<Block1::dim,T,Block1>::type  inout(
-    force_copy_init(in));
-
-  fwd(inout);
-  test_assert(error_db(inout, ref) < -100); 
-
-  inv(inout);
-  inout *= T(scalei);
-  test_assert(error_db(inout, in) < -100); 
-}
-
-// when testing matrices, will use latter two values
-
-unsigned  sizes[][3] =
-{
-#if TEST_NON_POWER_OF_2
-  { 2, 2, 2 },
-#endif
-  { 8, 8, 8 },
-#if TEST_NON_POWER_OF_2
-  { 1, 1, 1 },
-  { 2, 2, 1 },
-  { 2, 4, 8 },
-  { 2, 8, 128 },
-  { 3, 5, 7 },
-  { 2, 24, 48 },
-  { 24, 1, 5 },
-#endif
-};
-
-//   the generic test
-
-template <unsigned InBlockType,
-	  unsigned OutBlockType,
-	  typename InT,
-	  typename OutT,
-          unsigned Dim,
-	  int      sD>
-void 
-test_fft()
-{
-  bool const isReal = !impl::Is_complex<InT>::value;
-
-  typedef InT  in_elt_type;
-  typedef OutT out_elt_type;
-
-  static const int sdf = (sD < 0) ? vsip::fft_fwd : sD;
-  static const int sdi = (sD < 0) ? vsip::fft_inv : sD;
-  typedef typename Test_fft<Dim,in_elt_type,out_elt_type,
-                    sdf,vsip::by_reference>::type         fwd_by_ref_type;
-  typedef typename Test_fft<Dim,in_elt_type,out_elt_type,
-                    sdf,vsip::by_value>::type             fwd_by_value_type;
-  typedef typename Test_fft<Dim,out_elt_type,in_elt_type,
-                    sdi,vsip::by_reference>::type         inv_by_ref_type;
-  typedef typename Test_fft<Dim,out_elt_type,in_elt_type,
-                    sdi,vsip::by_value>::type             inv_by_value_type;
-
-  typedef typename Arg<Dim,in_elt_type,InBlockType>::type    in_type;
-  typedef typename Arg<Dim,out_elt_type,OutBlockType>::type  out_type;
-
-  for (unsigned i = 0; i < sizeof(sizes)/sizeof(*sizes); ++i)
-  {
-    vsip::Rand<in_elt_type> rander(
-      sizes[i][0] * sizes[i][1] * sizes[i][2] * Dim * (sD+5));
-
-#if VERBOSE
-    std::cout << "test_fft Dim: " << Dim
-	      << "  Size: " << sizes[i][0] << ", "
-	                    << sizes[i][1] << ", "
-	                    << sizes[i][2] << "  "
-	      << Type_name<InT>::name() << " -> "
-	      << Type_name<OutT>::name()
-	      << std::endl;
-#endif
-
-    Domain<Dim>  in_dom(make_dom<Dim>(sizes[i], false, sD, isReal)); 
-    Domain<Dim>  out_dom(make_dom<Dim>(sizes[i], isReal, sD, isReal)); 
-
-    typedef typename in_type::block_type   in_block_type;
-    typedef typename out_type::block_type  out_block_type;
-
-    in_block_type  in_block(in_dom);
-    in_type  in(in_block);
-    fill_random(in, rander);
-    in_type  in_copy(force_copy_init(in));
-
-    out_block_type  ref1_block(out_dom);
-    out_type  ref1(ref1_block);
-    int dum[(sD < 0) ? 1 : sD + 1];
-    compute_ref(in, in_dom, ref1, out_dom, dum);
-
-    out_type  ref4(force_copy_init(ref1));
-    ref4 *= out_elt_type(0.25);
-
-    out_type  refN(force_copy_init(ref1));
-    refN /= out_elt_type(in_dom.size());
-
-    test_assert(error_db(in, in_copy) < -200);  // not clobbered
-
-    { fwd_by_ref_type  fft_ref1(in_dom, 1.0);
-      out_block_type  out_block(out_dom);
-      out_type  out(out_block);
-      out_type  other = fft_ref1(in, out);
-      test_assert(&out.block() == &other.block());
-      test_assert(error_db(in, in_copy) < -200);  // not clobbered
-      test_assert(error_db(out, ref1) < -100); 
-
-      inv_by_ref_type  inv_refN(in_dom, 1.0/in_dom.size());
-      in_block_type  in2_block(in_dom);
-      in_type  in2(in2_block);
-      inv_refN(out, in2);
-      check_error(out, ref1, -100);  // not clobbered
-      check_error(in2, in,   -100); 
-
-      check_in_place(fft_ref1, inv_refN, in, ref1, 1.0);
-    }
-    { fwd_by_ref_type  fft_ref4(in_dom, 0.25);
-      out_block_type   out_block(out_dom);
-      out_type         out(out_block);
-      out_type         other = fft_ref4(in, out);
-      test_assert(&out.block() == &other.block());
-      check_error(in, in_copy, -200);  // not clobbered
-      check_error(out, ref4, -100); // XXXXX
-
-      inv_by_ref_type  inv_ref8(in_dom, .125);
-      in_block_type  in2_block(in_dom);
-      in_type  in2(in2_block);
-      inv_ref8(out, in2);
-      test_assert(error_db(out, ref4) < -100);  // not clobbered
-      in2 /= in_elt_type(in_dom.size() / 32.0);
-      test_assert(error_db(in2, in) < -100); 
-
-      check_in_place(fft_ref4, inv_ref8, in, ref4, 32.0/in_dom.size());
-    }
-    { fwd_by_ref_type  fft_refN(in_dom, 1.0/in_dom.size());
-      out_block_type  out_block(out_dom);
-      out_type  out(out_block);
-      out_type  other = fft_refN(in, out);
-      test_assert(&out.block() == &other.block());
-      test_assert(error_db(in, in_copy) < -200);  // not clobbered
-      test_assert(error_db(out, refN) < -100); 
-
-      inv_by_ref_type  inv_ref1(in_dom, 1.0);
-      in_block_type  in2_block(in_dom);
-      in_type  in2(in2_block);
-      inv_ref1(out, in2);
-      test_assert(error_db(out, refN) < -100);  // not clobbered
-      test_assert(error_db(in2, in) < -100); 
-
-      check_in_place(fft_refN, inv_ref1, in, refN, 1.0);
-    }
-    
-
-    { fwd_by_value_type  fwd_val1(in_dom, 1.0);
-      out_type  out(fwd_val1(in));
-      test_assert(error_db(in, in_copy) < -200);  // not clobbered
-      test_assert(error_db(out, ref1) < -100); 
-
-      inv_by_value_type  inv_valN(in_dom, 1.0/in_dom.size());
-      in_type  in2(inv_valN(out));
-      test_assert(error_db(out, ref1) < -100);    // not clobbered
-      test_assert(error_db(in2, in) < -100); 
-    }
-    { fwd_by_value_type  fwd_val4(in_dom, 0.25);
-      out_type  out(fwd_val4(in));
-      test_assert(error_db(in, in_copy) < -200);  // not clobbered
-      test_assert(error_db(out, ref4) < -100); 
-
-      inv_by_value_type  inv_val8(in_dom, 0.125);
-      in_type  in2(inv_val8(out));
-      test_assert(error_db(out, ref4) < -100);    // not clobbered
-      in2 /= in_elt_type(in_dom.size() / 32.0);
-      test_assert(error_db(in2, in) < -100); 
-    }
-    { fwd_by_value_type  fwd_valN(in_dom, 1.0/in_dom.size());
-      out_type  out(fwd_valN(in));
-      test_assert(error_db(in, in_copy) < -200);  // not clobbered
-      test_assert(error_db(out, refN) < -100); 
-
-      inv_by_value_type  inv_val1(in_dom, 1.0);
-      in_type  in2(inv_val1(out));
-      test_assert(error_db(out, refN) < -100);    // not clobbered
-      test_assert(error_db(in2, in) < -100); 
-    }
-  }
-};
-
-
-
 // Check 1D 
 
 template <typename T>
@@ -911,163 +269,6 @@
 }
 
 
-
-// check 2D, 3D
-
-template <typename T>
-void
-test_nd()
-{
-#if TEST_2D_CC
-  test_fft<0,0,complex<T>, complex<T> ,2,vsip::fft_fwd>();
-#endif
-
-#if TEST_2D_RC
-  test_fft<0,0,T,complex<T>,2,1>();
-  test_fft<0,0,T,complex<T>,2,0>();
-#endif
-
-#if TEST_3D_CC
-  test_fft<0,0,complex<T>,complex<T>,3,vsip::fft_fwd>();
-#endif
-
-#if TEST_3D_RC
-  test_fft<0,0,T,complex<T>,3,2>();
-  test_fft<0,0,T,complex<T>,3,1>();
-  test_fft<0,0,T,complex<T>,3,0>();
-#endif
-}
-
-
-
-// Check with different block types.
-
-template <typename T>
-void
-test_block_type()
-{
-#if TEST_2D_CC
-  test_fft<0,1,complex<T>,complex<T>,2,vsip::fft_fwd>();
-  test_fft<1,0,complex<T>,complex<T>,2,vsip::fft_fwd>();
-
-#  if VSIP_IMPL_TEST_LEVEL > 0
-  test_fft<0,2,complex<T>,complex<T>,2,vsip::fft_fwd>();
-  test_fft<1,1,complex<T>,complex<T>,2,vsip::fft_fwd>();
-  test_fft<1,2,complex<T>,complex<T>,2,vsip::fft_fwd>();
-  test_fft<2,0,complex<T>,complex<T>,2,vsip::fft_fwd>();
-  test_fft<2,1,complex<T>,complex<T>,2,vsip::fft_fwd>();
-  test_fft<2,2,complex<T>,complex<T>,2,vsip::fft_fwd>();
-#  endif
-#endif
-
-#if TEST_2D_RC
-  test_fft<0,1,T,complex<T>,2,1>();
-  test_fft<0,1,T,complex<T>,2,0>();
-  test_fft<1,0,T,complex<T>,2,1>();
-  test_fft<1,0,T,complex<T>,2,0>();
-
-#  if VSIP_IMPL_TEST_LEVEL > 0
-  test_fft<0,2,T,complex<T>,2,1>();
-  test_fft<0,2,T,complex<T>,2,0>();
-
-  test_fft<1,1,T,complex<T>,2,1>();
-  test_fft<1,1,T,complex<T>,2,0>();
-  test_fft<1,2,T,complex<T>,2,1>();
-  test_fft<1,2,T,complex<T>,2,0>();
-
-  test_fft<2,0,T,complex<T>,2,1>();
-  test_fft<2,0,T,complex<T>,2,0>();
-  test_fft<2,1,T,complex<T>,2,1>();
-  test_fft<2,1,T,complex<T>,2,0>();
-  test_fft<2,2,T,complex<T>,2,1>();
-  test_fft<2,2,T,complex<T>,2,0>();
-#  endif
-#endif
-
-#if TEST_3D_CC
-  test_fft<0,1,complex<T>,complex<T>,3,vsip::fft_fwd>();
-  test_fft<1,0,complex<T>,complex<T>,3,vsip::fft_fwd>();
-
-#  if VSIP_IMPL_TEST_LEVEL > 0
-  test_fft<0,2,complex<T>,complex<T>,3,vsip::fft_fwd>();
-  test_fft<1,1,complex<T>,complex<T>,3,vsip::fft_fwd>();
-  test_fft<1,2,complex<T>,complex<T>,3,vsip::fft_fwd>();
-  test_fft<2,0,complex<T>,complex<T>,3,vsip::fft_fwd>();
-  test_fft<2,1,complex<T>,complex<T>,3,vsip::fft_fwd>();
-  test_fft<2,2,complex<T>,complex<T>,3,vsip::fft_fwd>();
-#  endif
-#endif
-
-#if TEST_3D_RC
-  test_fft<0,1,T,complex<T>,3,2>();
-  test_fft<0,1,T,complex<T>,3,1>();
-  test_fft<0,1,T,complex<T>,3,0>();
-  test_fft<1,0,T,complex<T>,3,2>();
-  test_fft<1,0,T,complex<T>,3,1>();
-  test_fft<1,0,T,complex<T>,3,0>();
-
-#  if VSIP_IMPL_TEST_LEVEL > 0
-  test_fft<0,2,T,complex<T>,3,2>();
-  test_fft<0,2,T,complex<T>,3,1>();
-  test_fft<0,2,T,complex<T>,3,0>();
-
-  test_fft<1,1,T,complex<T>,3,2>();
-  test_fft<1,1,T,complex<T>,3,1>();
-  test_fft<1,1,T,complex<T>,3,0>();
-  test_fft<1,2,T,complex<T>,3,2>();
-  test_fft<1,2,T,complex<T>,3,1>();
-  test_fft<1,2,T,complex<T>,3,0>();
-
-  test_fft<2,0,T,complex<T>,3,2>();
-  test_fft<2,0,T,complex<T>,3,1>();
-  test_fft<2,0,T,complex<T>,3,0>();
-  test_fft<2,1,T,complex<T>,3,2>();
-  test_fft<2,1,T,complex<T>,3,1>();
-  test_fft<2,1,T,complex<T>,3,0>();
-  test_fft<2,2,T,complex<T>,3,2>();
-  test_fft<2,2,T,complex<T>,3,1>();
-  test_fft<2,2,T,complex<T>,3,0>();
-#  endif
-#endif
-}
-
-
-void
-show_config()
-{
-#if VERBOSE
-
-  std::cout << "backends:" << std::endl;
-
-#if defined(VSIP_IMPL_FFTW3)
-  std::cout << " - fftw3:" << std::endl;
-#endif
-#if defined(VSIP_IMPL_IPP_FFT)
-  std::cout << " - ipp" << std::endl;
-#endif
-#if defined(VSIP_IMPL_SAL_FFT)
-  std::cout << " - sal" << std::endl;
-#endif
-
-
-#if TEST_2D_CC
-  std::cout << "test 2D CC" << std::endl;
-#endif
-#if TEST_2D_RC
-  std::cout << "test 2D RC" << std::endl;
-#endif
-#if TEST_3D_CC
-  std::cout << "test 2D CC" << std::endl;
-#endif
-#if TEST_3D_RC
-  std::cout << "test 2D RC" << std::endl;
-#endif
-
-#endif
-}
-
-
-
 int
 main(int argc, char** argv)
 {
@@ -1075,9 +276,6 @@
 
   // show_config();
 
-//
-// First check 1D 
-//
 #if VSIP_IMPL_PROVIDE_FFT_FLOAT
   test_1d<float>();
 #endif 
@@ -1090,30 +288,5 @@
   test_1d<long double>();
 #endif
 
-
-//
-// check 2D, 3D
-//
-
-#if VSIP_IMPL_TEST_LEVEL > 0
-
-#if VSIP_IMPL_PROVIDE_FFT_FLOAT
-  test_nd<float>();
-#endif 
-
-#if VSIP_IMPL_PROVIDE_FFT_DOUBLE && VSIP_IMPL_TEST_DOUBLE
-  test_nd<double>();
-#endif
-
-#if VSIP_IMPL_PROVIDE_FFT_LONG_DOUBLE
-  test_nd<long double>();
-#endif
-
-//
-// check with different block types
-//
-  test_block_type<float>();
-
-#endif // VSIP_IMPL_TEST_LEVEL > 0
   return 0;
 }
