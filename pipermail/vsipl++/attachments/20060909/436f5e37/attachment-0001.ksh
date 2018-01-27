Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 148805)
+++ GNUmakefile.in	(working copy)
@@ -116,8 +116,8 @@
 VSIP_IMPL_SAL_FFT := @VSIP_IMPL_SAL_FFT@
 VSIP_IMPL_IPP_FFT := @VSIP_IMPL_IPP_FFT@
 VSIP_IMPL_FFTW3 := @VSIP_IMPL_FFTW3@
+VSIP_IMPL_MPI_H := @VSIP_IMPL_MPI_H@
 
-
 ### Documentation ### 
 
 # The location of the csl-docbook directory.
Index: tests/extdata-subviews.cpp
===================================================================
--- tests/extdata-subviews.cpp	(revision 148805)
+++ tests/extdata-subviews.cpp	(working copy)
@@ -20,7 +20,7 @@
 #include <vsip/tensor.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "plainblock.hpp"
+#include <vsip_csl/plainblock.hpp>
 #include "extdata-output.hpp"
 
 using namespace std;
Index: tests/reductions-idx.cpp
===================================================================
--- tests/reductions-idx.cpp	(revision 148805)
+++ tests/reductions-idx.cpp	(working copy)
@@ -16,7 +16,7 @@
 #include <vsip/math.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "test-storage.hpp"
+#include <vsip_csl/test-storage.hpp>
 
 
 using namespace vsip;
Index: tests/fns_scalar.cpp
===================================================================
--- tests/fns_scalar.cpp	(revision 148805)
+++ tests/fns_scalar.cpp	(working copy)
@@ -21,7 +21,7 @@
 #include <vsip/math.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "test-storage.hpp"
+#include <vsip_csl/test-storage.hpp>
 
 
 
Index: tests/scalar-view.cpp
===================================================================
--- tests/scalar-view.cpp	(revision 148805)
+++ tests/scalar-view.cpp	(working copy)
@@ -17,7 +17,7 @@
 #include <vsip/math.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "test-storage.hpp"
+#include <vsip_csl/test-storage.hpp>
 
 using namespace std;
 using namespace vsip;
Index: tests/regressions/proxy_lvalue_conv.cpp
===================================================================
--- tests/regressions/proxy_lvalue_conv.cpp	(revision 148805)
+++ tests/regressions/proxy_lvalue_conv.cpp	(working copy)
@@ -21,7 +21,7 @@
 #include <vsip/vector.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "plainblock.hpp"
+#include <vsip_csl/plainblock.hpp>
 
 using namespace std;
 using namespace vsip;
Index: tests/view_lvalue.cpp
===================================================================
--- tests/view_lvalue.cpp	(revision 148805)
+++ tests/view_lvalue.cpp	(working copy)
@@ -15,7 +15,7 @@
 #include <vsip/tensor.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "plainblock.hpp"
+#include <vsip_csl/plainblock.hpp>
 
 using namespace vsip_csl;
 
Index: tests/solver-qr.cpp
===================================================================
--- tests/solver-qr.cpp	(revision 148805)
+++ tests/solver-qr.cpp	(working copy)
@@ -20,8 +20,8 @@
 
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/test-precision.hpp>
+#include <vsip_csl/test-storage.hpp>
 #include "test-random.hpp"
-#include "test-storage.hpp"
 #include "solver-common.hpp"
 
 #define VERBOSE        0
Index: tests/coverage_ternary.cpp
===================================================================
--- tests/coverage_ternary.cpp	(revision 148805)
+++ tests/coverage_ternary.cpp	(working copy)
@@ -19,7 +19,7 @@
 #include <vsip/random.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "test-storage.hpp"
+#include <vsip_csl/test-storage.hpp>
 #include "coverage_common.hpp"
 
 using namespace std;
Index: tests/reductions-bool.cpp
===================================================================
--- tests/reductions-bool.cpp	(revision 148805)
+++ tests/reductions-bool.cpp	(working copy)
@@ -16,7 +16,7 @@
 #include <vsip/math.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "test-storage.hpp"
+#include <vsip_csl/test-storage.hpp>
 
 using namespace vsip;
 using namespace vsip_csl;
Index: tests/extdata-matadd.cpp
===================================================================
--- tests/extdata-matadd.cpp	(revision 148805)
+++ tests/extdata-matadd.cpp	(working copy)
@@ -35,7 +35,7 @@
 #include <vsip/matrix.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "plainblock.hpp"
+#include <vsip_csl/plainblock.hpp>
 
 using namespace std;
 using namespace vsip;
Index: tests/test-storage.hpp
===================================================================
--- tests/test-storage.hpp	(revision 148805)
+++ tests/test-storage.hpp	(working copy)
@@ -1,953 +0,0 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    tests/test-storage.hpp
-    @author  Jules Bergmann
-    @date    03/24/2005
-    @brief   VSIPL++ Library: Generalized view storage for tests.
-*/
-
-#ifndef VSIP_TESTS_TEST_STORAGE_HPP
-#define VSIP_TESTS_TEST_STORAGE_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <vsip/support.hpp>
-#include <vsip/vector.hpp>
-#include <vsip/matrix.hpp>
-#include <vsip/tensor.hpp>
-
-
-
-/* -------------------------------------------------------------------- *
- * The Storage class templates define storage views that simplify
- * the creation of general testcases.
- *
- * The following class templates exist:
- *   Vector_storage	- standard vector views
- *   Matrix_storage	- standard matrix views
- *   Vector12Storage	- vector view of a 1,2-dimension block
- *   Sub_vector_storage	- vector subview of a vector
- *   Col_vector_storage	- column vector subview of a matrix
- *
- * The following class templates exist but rely on functionality
- * not required by the VSIPL++ specification.
- *   Vector12_subview_storage
- *			- vector view of a 1,2-dimension matrix
- *			  subview block.
- *
- * Example: a general test case to test addition of two views might
- * look like:
- *
- *    template <typename                  T,
- *	        template <typename> class ViewStorage>
- *    void
- *    test_add()
- *    {
- *       using namespace vsip;
- * 
- *       int const	N = 7;
- * 
- *       ViewStorage<T> data(N);
- * 
- *       scalar_f	alpha = 0.25;
- * 
- *       data.viewR = data.view1 + data.view2;
- * 
- *       insist(equal(get_origin(data.viewR),
- *                      Test_rig<T>::test_value1()
- *                    + Test_rig<T>::test_value2() ));
- *    }
- *
- * The following calls would test standard vector, standard matrix, and
- * matrix column sub-vector additions:
- *
- *    test_add<scalar_f, Vector_storage>();
- *    test_add<scalar_f, Matrix_storage>();
- *    test_add<scalar_f, Col_vector_storage>();
- * -------------------------------------------------------------------- */
-
-
-template <vsip::dimension_type Dim,
-	  typename             MapT>
-struct Create_map {};
-
-template <vsip::dimension_type Dim>
-struct Create_map<Dim, vsip::Local_map>
-{
-  typedef vsip::Local_map type;
-  static type exec() { return type(); }
-};
-
-template <vsip::dimension_type Dim>
-struct Create_map<Dim, vsip::Global_map<Dim> >
-{
-  typedef vsip::Global_map<Dim> type;
-  static type exec() { return type(); }
-};
-
-template <typename Dist0, typename Dist1, typename Dist2>
-struct Create_map<1, vsip::Map<Dist0, Dist1, Dist2> >
-{
-  typedef vsip::Map<Dist0, Dist1, Dist2> type;
-  static type exec() { return type(vsip::num_processors()); }
-};
-
-template <typename Dist0, typename Dist1, typename Dist2>
-struct Create_map<2, vsip::Map<Dist0, Dist1, Dist2> >
-{
-  typedef vsip::Map<Dist0, Dist1, Dist2> type;
-
-  static type exec()
-  {
-    using vsip::processor_type;
-
-    processor_type np = vsip::num_processors();
-    processor_type nr = (processor_type)floor(sqrt((double)np));
-    processor_type nc = (processor_type)floor((double)np/nr);
-
-    return type(nr, nc);
-  }
-};
-
-template <vsip::dimension_type Dim,
-	  typename             MapT>
-MapT
-create_map()
-{
-  return Create_map<Dim, MapT>::exec();
-}
-
-
-
-
-// -------------------------------------------------------------------- //
-// Scalar_storage -- provide default vector storage.
-template <typename T>
-struct Scalar_storage {
-   static vsip::dimension_type const
-		dim = 0;
-   
-   typedef T	value_type;
-   
-   typedef T	view_type;
-
-   view_type	view;
-
-   Scalar_storage(int N)
-    : view(T())
-   {}
-
-   Scalar_storage(int , T val)
-    : view(val)
-   {}
-};
-
-template <vsip::dimension_type Dim>
-struct Default_order;
-
-template <> struct Default_order<0> { typedef vsip::row1_type type; };
-template <> struct Default_order<1> { typedef vsip::row1_type type; };
-template <> struct Default_order<2> { typedef vsip::row2_type type; };
-template <> struct Default_order<3> { typedef vsip::row3_type type; };
-
-
-
-// Indicate that "default" complex format should be used.
-
-// When using Storage, specifying Cmplx_default_fmt causes
-// a Dense block to be used.  Specifying a specific format,
-// CmplInterFmt or CmplxSplitFmt, will cause a Fast_block to
-// be used with an explicit layout policy.
-
-struct Cmplx_default_fmt;
-
-
-
-template <vsip::dimension_type Dim,
-	  typename             T,
-	  typename             Order      = typename Default_order<Dim>::type,
-          typename             MapT       = vsip::Local_map,
-	  typename             ComplexFmt = Cmplx_default_fmt>
-class Storage;
-
-template <vsip::dimension_type Dim,
-	  typename             T,
-	  typename             Order = typename Default_order<Dim>::type>
-class Const_storage;
-
-
-
-template <vsip::dimension_type Dim,
-	  typename             T,
-	  typename             Order,
-          typename             MapT,
-	  typename             ComplexFmt>
-struct Storage_block
-{
-  typedef vsip::impl::Stride_unit_dense                  ST;
-  typedef vsip::impl::Layout<Dim, Order, ST, ComplexFmt> LP;
-  typedef vsip::impl::Fast_block<Dim, T, LP, MapT>       type;
-};
-
-template <vsip::dimension_type Dim,
-	  typename             T,
-	  typename             Order,
-          typename             MapT>
-struct Storage_block<Dim, T, Order, MapT, Cmplx_default_fmt>
-{
-  typedef vsip::Dense<Dim, T, Order, MapT> type;
-};
-
-
-
-// -------------------------------------------------------------------- //
-// Scalar_storage -- provide default scalar storage.
-template <typename T,
-	  typename Order,
-	  typename MapT>
-class Storage<0, T, Order, MapT> {
-public:
-   static vsip::dimension_type const
-		dim = 0;
-   
-   typedef T	value_type;
-   
-   typedef T	view_type;
-
-  // Constructors.
-public:
-  Storage() : view(T()) {}
-
-  template <vsip::dimension_type Dim>
-  Storage(vsip::Domain<Dim> const&)
-    : view(T())
-  {}
-
-  template <vsip::dimension_type Dim>
-  Storage(vsip::Domain<Dim> const&, T val)
-    : view(val)
-  {}
-
-  // Public member data.
-public:
-  view_type	view;
-};
-
-
-
-template <typename T,
-	  typename Order>
-class Const_storage<0, T, Order> {
-public:
-   static vsip::dimension_type const
-		dim = 0;
-   
-   typedef T	value_type;
-   
-   typedef T const	view_type;
-
-  // Constructors.
-public:
-  Const_storage(int N)
-   : view(T())
-  {}
-
-  Const_storage(int , T val)
-    : view(val)
-  {}
-
-  // Public member data.
-public:
-  view_type	view;
-};
-
-
-
-// -------------------------------------------------------------------- //
-// Storage<1, ...> -- provide default vector storage.
-
-template <typename T,
-	  typename Order,
-	  typename MapT,
-	  typename ComplexFmt>
-class Storage<1, T, Order, MapT, ComplexFmt>
-{
-  // Compile-time values and typedefs.
-public:
-  static vsip::dimension_type const
-		dim = 1;
-   
-  typedef T	                                            value_type;
-  typedef MapT                                              map_type;
-  typedef typename Storage_block<dim, T, Order, MapT, ComplexFmt>::type
-                                                            block_type;
-  typedef vsip::Vector<T, block_type>                       view_type;
-
-
-  // Constructors.
-public:
-  Storage()
-    : map(create_map<1, map_type>()), view(5, map)
-  {}
-
-  Storage(vsip::Domain<dim> const& dom)
-    : map(create_map<1, map_type>()), view(dom.length(), map)
-  {}
-
-  Storage(vsip::Domain<dim> const& dom, T val)
-    : map(create_map<1, map_type>()), view(dom.length(), val, map)
-  {}
-
-
-  // Accessor.
-public:
-  block_type& block()
-   { return view.block(); }
-
-  // Public member data.
-public:
-  map_type      map;
-  view_type	view;
-};
-
-
-
-// -------------------------------------------------------------------- //
-// Cnst_vector_storage -- provide default const_Vector storage.
-template <typename T,
-	  typename Order>
-class Const_storage<1, T, Order>
-{
-  // Compile-time values and typedefs.
-public:
-  static vsip::dimension_type const
-		dim = 1;
-   
-  typedef T	value_type;
-
-  typedef vsip::Dense<dim, T, Order>
-		block_type;
-
-  typedef vsip::const_Vector<T, block_type>
-		view_type;
-
-
-  // Constructors and destructor.
-public:
-  Const_storage(vsip::Domain<dim> const& dom)
-    : block_	(new block_type(dom))
-    , view	(*block_)
-    {}
-
-  Const_storage(vsip::Domain<dim> const& dom, T val)
-    : block_	(new block_type(dom, val))
-    , view	(*block_)
-    {}
-
-  ~Const_storage()
-    { block_->decrement_count(); }
-
-
-  // Accessor.
-public:
-  block_type& block()
-    { return *block_; }
-
-
-  // Member data.
-private:
-   block_type*	block_;
-
-public:
-   view_type	view;
-};
-
-
-
-// -------------------------------------------------------------------- //
-// Matrix_storage -- provide default vector storage.
-template <typename T,
-	  typename Order,
-	  typename MapT,
-	  typename ComplexFmt>
-class Storage<2, T, Order, MapT, ComplexFmt>
-{
-  // Compile-time values and typedefs.
-public:
-  static vsip::dimension_type const
-		dim = 2;
-
-  typedef T	                                            value_type;
-  typedef MapT                                              map_type;
-  typedef typename Storage_block<dim, T, Order, MapT, ComplexFmt>::type
-                                                            block_type;
-  typedef vsip::Matrix<T, block_type>                       view_type;
-
-
-  // Constructors.
-public:
-  Storage() : view(5, 7) {}
-
-  Storage(vsip::Domain<dim> const& dom)
-    : view(dom[0].length(), dom[1].length())
-  {}
-
-  Storage(vsip::Domain<dim> const& dom, T val)
-    : view(dom[0].length(), dom[1].length(), val)
-  {}
-
-  // Accessor.
-public:
-  block_type& block()
-    { return view.block(); }
-
-  // Public member data.
-public:
-  view_type	view;
-
-};
-
-
-
-// -------------------------------------------------------------------- //
-// Const_matrix_storage -- provide default const_Vector storage.
-template <typename T,
-	  typename Order>
-class Const_storage<2, T, Order>
-{
-  // Compile-time values and typedefs.
-public:
-  static vsip::dimension_type const
-		dim = 2;
-
-  typedef T	value_type;
-
-  typedef vsip::Dense<dim, T, Order>
-		block_type;
-
-  typedef vsip::const_Matrix<T, block_type>
-		view_type;
-
-
-  // Constructors and destructor.
-public:
-  Const_storage(vsip::Domain<dim> const& dom)
-    : block_	(new block_type(dom))
-    , view	(*block_)
-  {}
-
-  Const_storage(vsip::Domain<dim> const& dom, T val)
-    : block_	(new block_type(dom, val))
-    , view	(*block_)
-  {}
-
-  ~Const_storage()
-    { block_->decrement_count(); }
-
-
-  // Accessor.
-public:
-  block_type& block()
-    { return *block_; }
-
-
-  // Member data.
-private:
-  block_type*	block_;
-
-public:
-  view_type	view;
-};
-
-
-
-/// Storage specialization for Tensors.
-
-template <typename T,
-	  typename Order,
-	  typename MapT,
-	  typename ComplexFmt>
-class Storage<3, T, Order, MapT, ComplexFmt>
-{
-  // Compile-time values and typedefs.
-public:
-  static vsip::dimension_type const dim = 3;
-
-  typedef T	                                            value_type;
-  typedef MapT                                              map_type;
-  typedef typename Storage_block<dim, T, Order, MapT, ComplexFmt>::type
-                                                            block_type;
-  typedef vsip::Tensor<T, block_type>                       view_type;
-
-  // Constructors.
-public:
-  Storage() : view(5, 7, 3) {}
-
-  Storage(vsip::Domain<dim> const& dom)
-    : view(dom[0].length(), dom[1].length(), dom[2].length())
-  {}
-
-  Storage(vsip::Domain<dim> const& dom, T val)
-    : view(dom[0].length(), dom[1].length(), dom[2].length(), val)
-  {}
-
-  // Accessor.
-public:
-  block_type& block()
-    { return view.block(); }
-
-  // Public member data.
-public:
-  view_type	view;
-
-};
-
-
-
-// -------------------------------------------------------------------- //
-// Const_storage -- provide default const_Tensor storage.
-template <typename T,
-	  typename Order>
-class Const_storage<3, T, Order>
-{
-  // Compile-time values and typedefs.
-public:
-  static vsip::dimension_type const dim = 3;
-
-  typedef T	                            value_type;
-  typedef vsip::Dense<dim, T, Order>        block_type;
-  typedef vsip::const_Tensor<T, block_type> view_type;
-
-  // Constructors and destructor.
-public:
-  Const_storage(vsip::Domain<dim> const& dom)
-    : block_	(new block_type(dom))
-    , view	(*block_)
-  {}
-
-  Const_storage(vsip::Domain<dim> const& dom, T val)
-    : block_	(new block_type(dom, val))
-    , view	(*block_)
-  {}
-
-  ~Const_storage()
-    { block_->decrement_count(); }
-
-
-  // Accessor.
-public:
-  block_type& block()
-    { return *block_; }
-
-
-  // Member data.
-private:
-  block_type*	block_;
-
-public:
-  view_type	view;
-};
-
-
-
-// -------------------------------------------------------------------- //
-// Additional storage types.
-
-template <typename T,
-	  typename Order>
-class Row_vector
-{
-  // Compile-time values and typedefs.
-public:
-  static vsip::dimension_type const
-		dim = 1;
-   
-  typedef T value_type;
-
-  typedef vsip::Matrix<T, vsip::Dense<2, T, Order> > parent_type;
-  typedef typename parent_type::row_type             view_type;
-  typedef typename view_type::block_type             block_type;
-
-  // Constructors.
-public:
-  // 5 rows and 1st row are arbitrary
-  Row_vector(vsip::Domain<dim> const& dom)
-    : parent_view(5, dom.length()),
-      view       (parent_view.row(1))
-  {}
-
-  Row_vector(vsip::Domain<dim> const& dom, T val)
-    : parent_view(5, dom.length(), val),
-      view       (parent_view.row(1))
-  {}
-
-  // Accessor.
-public:
-  block_type& block()
-  { return view.block(); }
-
-  // Member data.
-private:
-  parent_type parent_view;
-public:
-  view_type   view;
-};
-
-
-
-template <typename T,
-	  typename Order>
-class Diag_vector
-{
-  // Compile-time values and typedefs.
-public:
-  static vsip::dimension_type const
-		dim = 1;
-   
-  typedef T value_type;
-
-  typedef vsip::Matrix<T, vsip::Dense<2, T, Order> > parent_type;
-  typedef typename parent_type::diag_type            view_type;
-  typedef typename view_type::block_type             block_type;
-
-  // Constructors.
-public:
-  Diag_vector(vsip::Domain<dim> const& dom)
-    : parent_view(dom.length(), dom.length()),
-      view       (parent_view.diag(0))
-  {}
-
-  Diag_vector(vsip::Domain<dim> const& dom, T val)
-    : parent_view(dom.length(), dom.length(), val),
-      view       (parent_view.diag(0))
-  {}
-
-  // Accessor.
-public:
-  block_type& block()
-  { return view.block(); }
-
-  // Member data.
-private:
-  parent_type parent_view;
-public:
-  view_type   view;
-};
-
-
-
-template <typename T,
-	  typename Order>
-class Transpose_matrix
-{
-  // Compile-time values and typedefs.
-public:
-  static vsip::dimension_type const
-		dim = 2;
-
-  typedef T	value_type;
-
-  typedef vsip::Matrix<T, vsip::Dense<2, T, Order> > parent_type;
-  typedef typename parent_type::transpose_type       view_type;
-  typedef typename view_type::block_type             block_type;
-
-  // Constructors.
-public:
-  Transpose_matrix(vsip::Domain<dim> const& dom)
-    : parent_view(dom[1].length(), dom[0].length()),
-      view       (parent_view.transpose())
-  {}
-
-  Transpose_matrix(vsip::Domain<dim> const& dom, T val)
-    : parent_view(dom[1].length(), dom[0].length(), val),
-      view       (parent_view.transpose())
-  {}
-
-  // Accessor.
-public:
-  block_type& block()
-    { return view.block(); }
-
-  // Member data.
-private:
-  parent_type	parent_view;
-public:
-  view_type	view;
-};
-
-
-
-// get_size -- get size of a view.
-
-template <typename T>
-inline vsip::length_type
-get_size(T const&)
-{
-  return 1;
-}
-
-template <typename T,
-	  typename Block>
-inline vsip::length_type
-get_size(
-   vsip::Vector<T, Block> view)
-{
-   return view.size();
-}
-
-template <typename T,
-	  typename Block>
-inline vsip::length_type
-get_size(
-   vsip::Matrix<T, Block> view)
-{
-  return view.size();
-}
-
-template <typename T,
-	  typename Block>
-inline vsip::length_type
-get_size(
-   vsip::Tensor<T, Block> view)
-{
-  return view.size();
-}
-
-
-// -------------------------------------------------------------------- //
-// get_nth -- get n-th element of a scalar.
-template <typename T>
-inline T
-get_nth(
-  T&  view,
-  vsip::index_type)
-{
-  return view;
-}
-
-
-
-// -------------------------------------------------------------------- //
-// get_nth -- get n-th element of a vector.
-template <typename T,
-	  typename Block>
-inline T
-get_nth(
-   vsip::Vector<T, Block> view,
-   vsip::index_type	  n)
-{
-   return view.get(n);
-}
-
-
-
-// -------------------------------------------------------------------- //
-// get_nth -- get n-th element of a matrix.
-template <typename T,
-	  typename Block>
-inline T
-get_nth(
-   vsip::Matrix<T, Block> view,
-   vsip::index_type	  n)
-{
-   return view.get(n/view.size(1), n%view.size(1));
-}
-
-
-
-// Get the n'th element of a tensor.
-
-template <typename T,
-	  typename Block>
-inline T
-get_nth(
-   vsip::Tensor<T, Block> view,
-   vsip::index_type	  n)
-{
-  unsigned orig = n;
-  vsip::index_type k = n % view.size(2); n = (n-k) / view.size(2);
-  vsip::index_type j = n % view.size(1); n = (n-j) / view.size(1);
-  vsip::index_type i = n;
-
-  assert((i * view.size(1) + j) * view.size(2) + k == orig);
-
-  return view.get(i, j, k);
-}
-
-
-
-// -------------------------------------------------------------------- //
-// put_nth -- put n-th element of a scalar.
-template <typename T>
-inline void
-put_nth(
-  T&               view,
-  vsip::index_type /*n*/,
-  T const&         value)
-{
-  view = value;
-}
-
-
-
-// -------------------------------------------------------------------- //
-// put_nth -- put n-th element of a vector.
-template <typename T,
-	  typename Block>
-inline void
-put_nth(
-  vsip::Vector<T, Block> view,
-  vsip::index_type       n,
-  T const&		 value)
-{
-   view.put(n, value);
-}
-
-
-
-// -------------------------------------------------------------------- //
-// put_nth -- put n-th element of a matrix.
-template <typename T,
-	  typename Block>
-inline void
-put_nth(
-  vsip::Matrix<T, Block> view,
-  vsip::index_type       n,
-  T const&		 value)
-{
-   view.put(n/view.size(1), n%view.size(1), value);
-}
-
-
-
-// put_nth -- put n-th element of a tensor.
-
-template <typename T,
-	  typename Block>
-inline void
-put_nth(
-  vsip::Tensor<T, Block> view,
-  vsip::index_type       n,
-  T const&		 value)
-{
-  unsigned orig = n;
-  vsip::index_type k = n % view.size(2); n = (n-k) / view.size(2);
-  vsip::index_type j = n % view.size(1); n = (n-j) / view.size(1);
-  vsip::index_type i = n;
-
-  assert((i * view.size(1) + j) * view.size(2) + k == orig);
-
-  view.put(i, j, k, value);
-}
-
-
-
-// -------------------------------------------------------------------- //
-// put_nth -- put nth element 0,0 of a Dense<2,T> block.
-template <typename T,
-	  typename Order,
-	  typename Map>
-inline void
-put_nth(
-  vsip::Dense<2, T, Order, Map>& block,
-  vsip::index_type               n,
-  T const&		         value)
-{
-   block->put(n/block->size(2, 1), n%block->size(2, 1), value);
-}
-
-
-template <typename T,
-	  typename Block>
-inline vsip::index_type
-nth_from_index(
-   vsip::const_Vector<T, Block>,
-   vsip::Index<1> const&        idx)
-{
-  return idx[0];
-}
-
-
-
-template <typename T,
-	  typename Block>
-inline vsip::index_type
-nth_from_index(
-   vsip::const_Matrix<T, Block> view,
-   vsip::Index<2> const&        idx)
-{
-  return idx[0] * view.size(1) + idx[1];
-}
-
-
-
-template <typename T,
-	  typename Block>
-inline vsip::index_type
-nth_from_index(
-   vsip::const_Tensor<T, Block> view,
-   vsip::Index<3> const&        idx)
-{
-  return (idx[0] * view.size(1) + idx[1]) * view.size(2) + idx[2];
-}
-
-
-template <typename T>
-struct Is_scalar
-{
-  static bool const value = true;
-};
-
-template <typename T,
-	  typename Block>
-struct Is_scalar<vsip::Vector<T, Block> >
-{
-  static bool const value = false;
-};
-
-template <typename T,
-	  typename Block>
-struct Is_scalar<vsip::Matrix<T, Block> >
-{
-  static bool const value = false;
-};
-
-template <typename T,
-	  typename Block>
-struct Is_scalar<vsip::Tensor<T, Block> >
-{
-  static bool const value = false;
-};
-
-
-
-template <typename T>
-struct Value_type_of
-{
-  typedef T type;
-};
-
-template <typename T,
-	  typename Block>
-struct Value_type_of<vsip::Vector<T, Block> >
-{
-  typedef T type;
-};
-
-template <typename T,
-	  typename Block>
-struct Value_type_of<vsip::Matrix<T, Block> >
-{
-  typedef T type;
-};
-
-template <typename T,
-	  typename Block>
-struct Value_type_of<vsip::Tensor<T, Block> >
-{
-  typedef T type;
-};
-
-#endif // VSIP_TESTS_TEST_STORAGE_HPP
Index: tests/view.cpp
===================================================================
--- tests/view.cpp	(revision 148805)
+++ tests/view.cpp	(working copy)
@@ -24,7 +24,7 @@
 #include <vsip/impl/length.hpp>
 #include <vsip/impl/domain-utils.hpp>
 #include <vsip_csl/test.hpp>
-#include "test-storage.hpp"
+#include <vsip_csl/test-storage.hpp>
 
 using namespace std;
 using namespace vsip;
Index: tests/plainblock.hpp
===================================================================
--- tests/plainblock.hpp	(revision 148805)
+++ tests/plainblock.hpp	(working copy)
@@ -1,681 +0,0 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
-
-/** @file    tests/plainblock.hpp
-    @author  Jules Bergmann
-    @date    02/11/2005
-    @brief   VSIPL++ Library: Plain block class.
-
-    Plain block class. similar to Dense, but does not provide
-    admit/release and may not implement Direct_data (depending on
-    PLAINBLOCK_ENABLE_DIERCT_DATA define).
-*/
-
-#ifndef VSIP_PLAINBLOCK_HPP
-#define VSIP_PLAINBLOCK_HPP
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-#include <stdexcept>
-#include <string>
-
-#include <vsip/support.hpp>
-#include <vsip/domain.hpp>
-#include <vsip/impl/refcount.hpp>
-#include <vsip/impl/layout.hpp>
-#include <vsip/impl/extdata.hpp>
-#include <vsip/impl/block-traits.hpp>
-
-
-
-/***********************************************************************
-  Macros
-***********************************************************************/
-
-/// Control whether Direct_data access is supported.
-#ifndef PLAINBLOCK_ENABLE_DIRECT_DATA
-#  define PLAINBLOCK_ENABLE_DIRECT_DATA 0
-#endif
-
-/// Control whether impl_ref() is supported.
-#ifndef PLAINBLOCK_ENABLE_IMPL_REF
-#  define PLAINBLOCK_ENABLE_IMPL_REF 0
-#endif
-
-
-
-/***********************************************************************
-  Declarations
-***********************************************************************/
-
-namespace vsip
-{
-
-/// Plain block, as defined in standard [view.dense].
-
-/// "A Plain block is a modifiable, allocatable 1-dimensional block
-/// or 1,x-dimensional block, for a fixed x, that explicitly stores
-/// one value for each Index in its domain."
-
-template <dimension_type Dim   = 1,
-	  typename    T        = VSIP_DEFAULT_VALUE_TYPE,
-	  typename    Order    = typename impl::Row_major<Dim>::type,
-	  typename    Map      = Local_map>
-class Plain_block;
-
-
-
-/// Partial specialization of Plain_block class template for 1-dimension.
-
-/// Note: This declaration is incomplete.  The following items
-///       required by the spec are not declared (and not defined)
-///         - User defined storage, including user storage
-///           constructors, admit, release, find, and rebind.
-///
-///       The following items required by the spec are declared
-///       but not implemented:
-///         - The user_storage() and admitted() accessors.
-///
-
-template <typename    T,
-	  typename    Order,
-	  typename    DenseMap>
-class Plain_block<1, T, Order, DenseMap>
-  : public impl::Ref_count<Plain_block<1, T, Order, DenseMap> >
-{
-  // Compile-time values and types.
-public:
-  static dimension_type const dim = 1;
-
-  typedef T        value_type;
-  typedef T&       reference_type;
-  typedef T const& const_reference_type;
-
-  typedef Order    order_type;
-  typedef DenseMap map_type;
-
-  // Enable Direct_data access to data.
-  template <typename, typename, typename>
-  friend class impl::data_access::Low_level_data_access;
-
-  // Implementation types.
-public:
-  typedef impl::Layout<dim, order_type, impl::Stride_unit_dense, impl::Cmplx_inter_fmt>
-		layout_type;
-  typedef impl::Applied_layout<layout_type>
-		applied_layout_type;
-  typedef impl::Allocated_storage<typename layout_type::complex_type, T> storage_type;
-
-  // Constructors and destructor.
-public:
-  Plain_block(Domain<1> const& dom, DenseMap const& = DenseMap())
-    VSIP_THROW((std::bad_alloc));
-
-  Plain_block(Domain<1> const& dom, T value, DenseMap const& = DenseMap())
-    VSIP_THROW((std::bad_alloc));
-
-  ~Plain_block() VSIP_NOTHROW;
-
-  // Data accessors.
-public:
-  T get(index_type idx) const VSIP_NOTHROW;
-  void put(index_type idx, T val) VSIP_NOTHROW;
-
-#if PLAINBLOCK_ENABLE_IMPL_REF
-  reference_type       impl_ref(index_type idx) VSIP_NOTHROW;
-  const_reference_type impl_ref(index_type idx) const VSIP_NOTHROW;
-#endif
-
-  // Accessors.
-public:
-  length_type size() const VSIP_NOTHROW;
-  length_type size(dimension_type Dim, dimension_type d) const VSIP_NOTHROW;
-  DenseMap const& map() const VSIP_NOTHROW { return map_;}
-
-  // Support Direct_data interface.
-public:
-  typedef typename storage_type::type       data_type;
-  typedef typename storage_type::const_type const_data_type;
-
-  data_type       impl_data()       VSIP_NOTHROW { return storage_.data(); }
-  const_data_type impl_data() const VSIP_NOTHROW { return storage_.data(); }
-  stride_type impl_stride(dimension_type Dim, dimension_type d)
-    const VSIP_NOTHROW;
-
-  // Hidden copy constructor and assignment.
-private:
-  Plain_block(Plain_block const&);
-  Plain_block& operator=(Plain_block const&);
-
-  // Member Data
-private:
-  applied_layout_type layout_;
-  storage_type        storage_;
-  map_type            map_;
-};
-
-
-
-/// Partial specialization of Plain_block class template for 1,2-dimension.
-
-/// Note: This declaration is incomplete.  The following items
-///       required by the spec are not declared (and not defined)
-///         - User defined storage, including user storage
-///           constructors, admit, release, find, and rebind.
-///
-///       The following items required by the spec are declared
-///       but not implemented:
-///         - The user_storage() and admitted() accessors.
-///
-
-template <typename    T,
-	  typename    Order,
-	  typename    DenseMap>
-class Plain_block<2, T, Order, DenseMap>
-  : public impl::Ref_count<Plain_block<2, T, Order, DenseMap> >
-{
-  // Compile-time values and types.
-public:
-  static dimension_type const dim = 2;
-
-  typedef T        value_type;
-  typedef T&       reference_type;
-  typedef T const& const_reference_type;
-
-  typedef Order    order_type;
-  typedef DenseMap map_type;
-
-  // Implementation types.
-public:
-  typedef impl::Layout<dim, order_type, impl::Stride_unit_dense, impl::Cmplx_inter_fmt>
-		layout_type;
-  typedef impl::Applied_layout<layout_type>
-		applied_layout_type;
-  typedef impl::Allocated_storage<typename layout_type::complex_type, T> storage_type;
-
-  // Constructors and destructor.
-public:
-  Plain_block(Domain<2> const& dom, DenseMap const& = DenseMap())
-    VSIP_THROW((std::bad_alloc));
-
-  Plain_block(Domain<2> const& dom, T value, DenseMap const& = DenseMap())
-    VSIP_THROW((std::bad_alloc));
-
-  ~Plain_block() VSIP_NOTHROW;
-
-  // Data Accessors.
-public:
-  T get(index_type idx) const VSIP_NOTHROW;
-  void put(index_type idx, T val) VSIP_NOTHROW;
-
-  T get(index_type idx0, index_type idx1) const VSIP_NOTHROW;
-  void put(index_type idx0, index_type idx1, T val) VSIP_NOTHROW;
-
-#if PLAINBLOCK_ENABLE_IMPL_REF
-  reference_type       impl_ref(index_type idx) VSIP_NOTHROW;
-  const_reference_type impl_ref(index_type idx) const VSIP_NOTHROW;
-  reference_type       impl_ref(index_type idx0, index_type idx1) VSIP_NOTHROW;
-  const_reference_type impl_ref(index_type idx0, index_type idx1) const VSIP_NOTHROW;
-#endif
-
-  // Accessors.
-public:
-  length_type size() const VSIP_NOTHROW;
-  length_type size(dimension_type, dimension_type) const VSIP_NOTHROW;
-  DenseMap const& map() const VSIP_NOTHROW { return map_;}
-
-  // Support Direct_data interface.
-public:
-  typedef typename storage_type::type       data_type;
-  typedef typename storage_type::const_type const_data_type;
-
-  data_type       impl_data()       VSIP_NOTHROW { return storage_.data(); }
-  const_data_type impl_data() const VSIP_NOTHROW { return storage_.data(); }
-  stride_type impl_stride(dimension_type Dim, dimension_type d)
-    const VSIP_NOTHROW;
-
-  // Hidden copy constructor and assignment.
-private:
-  Plain_block(Plain_block const&);
-  Plain_block& operator=(Plain_block const&);
-
-  // Member data.
-private:
-  applied_layout_type layout_;
-  storage_type        storage_;
-  map_type            map_;
-};
-
-
-
-namespace impl
-{
-
-template <dimension_type Dim,
-	  typename       T,
-	  typename       Order,
-	  typename       Map>
-struct Block_layout<Plain_block<Dim, T, Order, Map> >
-{
-  static dimension_type const dim = Dim;
-
-  typedef Direct_access_tag access_type;
-  typedef Order           order_type;
-  typedef Stride_unit_dense pack_type;
-  typedef Cmplx_inter_fmt   complex_type;
-
-  typedef Layout<dim, order_type, pack_type, complex_type> layout_type;
-};
-
-#if PLAINBLOCK_ENABLE_IMPL_REF
-template <dimension_type Dim,
-          typename       T,
-          typename       Order,
-          typename       Map>
-struct Lvalue_factory_type<Plain_block<Dim, T, Order, Map> >
-{
-  typedef True_lvalue_factory<Plain_block<Dim, T, Order, Map> > type;
-  template <typename OtherBlock>
-  struct Rebind {
-    typedef True_lvalue_factory<OtherBlock> type;
-  };
-};
-#endif
-
-} // namespace vsip::impl
-
-
-
-/***********************************************************************
-  Definitions
-***********************************************************************/
-
-// Plain_block<1, T, Order, Map>
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-Plain_block<1, T, Order, Map>::Plain_block(Domain<1> const& dom, Map const& map)
-  VSIP_THROW((std::bad_alloc))
-  : layout_    (dom),
-    storage_   (layout_.total_size()),
-    map_       (map)
-{
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-Plain_block<1, T, Order, Map>::Plain_block(Domain<1> const& dom, T val, Map const& map)
-  VSIP_THROW((std::bad_alloc))
-  : layout_    (dom),
-    storage_   (layout_.total_size(), val),
-    map_       (map)
-{
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-Plain_block<1, T, Order, Map>::~Plain_block()
-  VSIP_NOTHROW
-{
-  storage_.deallocate(layout_.total_size());
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map >
-inline
-T
-Plain_block<1, T, Order, Map>::get(
-  index_type idx)
-  const VSIP_NOTHROW
-{
-  assert(idx < size());
-  return storage_.get(idx);
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-void
-Plain_block<1, T, Order, Map>::put(
-  index_type idx,
-  T       val)
-  VSIP_NOTHROW
-{
-  assert(idx < size());
-  storage_.put(idx, val);
-}
-
-
-#if PLAINBLOCK_ENABLE_IMPL_REF
-template <typename    T,
-	  typename    Order,
-	  typename    Map >
-inline
-typename Plain_block<1, T, Order, Map>::reference_type
-Plain_block<1, T, Order, Map>::impl_ref(index_type idx) VSIP_NOTHROW
-{
-  assert(idx < size());
-  return storage_.ref(idx);
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map >
-inline
-typename Plain_block<1, T, Order, Map>::const_reference_type
-Plain_block<1, T, Order, Map>::impl_ref(index_type idx) const VSIP_NOTHROW
-{
-  assert(idx < size());
-  return storage_.ref(idx);
-}
-#endif
-
-
-/// Return the total size of the block.
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-length_type
-Plain_block<1, T, Order, Map>::size() const VSIP_NOTHROW
-{
-  return layout_.size(0);
-}
-
-
-
-/// Return the size of the block in a specific dimension.
-
-/// Requires:
-///   BLOCK_DIM selects which block-dimensionality (BLOCK_DIM == 1).
-///   DIM is the dimension whose length to return (0 <= DIM < BLOCK_DIM).
-/// Returns:
-///   The size of dimension DIM.
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-length_type
-Plain_block<1, T, Order, Map>::size(
-  dimension_type block_dim,
-  dimension_type dim)
-  const VSIP_NOTHROW
-{
-  assert(block_dim == 1);
-  assert(dim == 0);
-  return layout_.size(0);
-}
-
-
-
-// Requires:
-//   DIM is a valid dimensionality supported by block (DIM must be 1).
-//   D is a dimension, less than DIM (D must be 0).
-// Returns
-//   The stride in dimension D, for dimensionality DIM.
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-stride_type
-Plain_block<1, T, Order, Map>::impl_stride(dimension_type Dim, dimension_type d)
-  const VSIP_NOTHROW
-{
-  assert(Dim == dim && d == 0);
-  return 1;
-}
-
-
-
-/**********************************************************************/
-// Plain_block<2, T, Order, Map>
-
-/// Construct a 1,2-dimensional Plain_block block.
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-Plain_block<2, T, Order, Map>::Plain_block(Domain<2> const& dom, Map const& map)
-  VSIP_THROW((std::bad_alloc))
-  : layout_ (dom[0].size(), dom[1].size()),
-    storage_(layout_.total_size()),
-    map_    (map)
-{
-}
-
-
-
-/// Construct a 1,2-dimensional Plain_block block and initialize data.
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-Plain_block<2, T, Order, Map>::Plain_block(Domain<2> const& dom, T val, Map const& map)
-  VSIP_THROW((std::bad_alloc))
-  : layout_ (dom[0].size(), dom[1].size()),
-    storage_(layout_.total_size(), val),
-    map_    (map)
-{
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-Plain_block<2, T, Order, Map>::~Plain_block()
-  VSIP_NOTHROW
-{
-  storage_.deallocate(layout_.total_size());
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map >
-inline
-T
-Plain_block<2, T, Order, Map>::get(
-  index_type idx)
-  const VSIP_NOTHROW
-{
-  assert(idx < size());
-  return storage_.get(idx);
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-void
-Plain_block<2, T, Order, Map>::put(
-  index_type idx,
-  T       val)
-  VSIP_NOTHROW
-{
-  assert(idx < size());
-  return storage_.put(idx, val);
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map >
-inline
-T
-Plain_block<2, T, Order, Map>::get(
-  index_type idx0,
-  index_type idx1)
-  const VSIP_NOTHROW
-{
-  assert((idx0 < layout_.size(0)) && (idx1 < layout_.size(1)));
-  return storage_.get(layout_.index(idx0, idx1));
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-void
-Plain_block<2, T, Order, Map>::put(
-  index_type idx0,
-  index_type idx1,
-  T       val)
-  VSIP_NOTHROW
-{
-  assert((idx0 < layout_.size(0)) && (idx1 < layout_.size(1)));
-  storage_.put(layout_.index(idx0, idx1), val);
-}
-
-
-#if PLAINBLOCK_ENABLE_IMPL_REF
-template <typename    T,
-	  typename    Order,
-	  typename    Map >
-inline
-typename Plain_block<2, T, Order, Map>::reference_type
-Plain_block<2, T, Order, Map>::impl_ref(index_type idx) VSIP_NOTHROW
-{
-  assert(idx < size());
-  return storage_.ref(idx);
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map >
-inline
-typename Plain_block<2, T, Order, Map>::const_reference_type
-Plain_block<2, T, Order, Map>::impl_ref(index_type idx) const VSIP_NOTHROW
-{
-  assert(idx < size());
-  return storage_.ref(idx);
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map >
-inline
-typename Plain_block<2, T, Order, Map>::reference_type
-Plain_block<2, T, Order, Map>::impl_ref(
-  index_type idx0,
-  index_type idx1) VSIP_NOTHROW
-{
-  assert((idx0 < layout_.size(0)) && (idx1 < layout_.size(1)));
-  return storage_.ref(layout_.index(idx0, idx1));
-}
-
-
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map >
-inline
-typename Plain_block<2, T, Order, Map>::const_reference_type
-Plain_block<2, T, Order, Map>::impl_ref(
-  index_type idx0,
-  index_type idx1) const VSIP_NOTHROW
-{
-  assert((idx0 < layout_.size(0)) && (idx1 < layout_.size(1)));
-  return storage_.ref(layout_.index(idx0, idx1));
-}
-#endif
-
-
-/// Return the total size of the block.
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-length_type
-Plain_block<2, T, Order, Map>::size() const VSIP_NOTHROW
-{
-  return layout_.size(0) * layout_.size(1);
-}
-
-
-
-/// Return the size of the block in a specific dimension.
-
-/// Requires:
-///   BLOCK_DIM selects which block-dimensionality (BLOCK_DIM <= 2).
-///   DIM is the dimension whose length to return (0 <= DIM < BLOCK_DIM).
-/// Returns:
-///   The size of dimension DIM.
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-length_type
-Plain_block<2, T, Order, Map>::size(
-  dimension_type block_dim,
-  dimension_type dim)
-  const VSIP_NOTHROW
-{
-  assert((block_dim == 1 || block_dim == 2) && (dim < block_dim));
-
-  if (block_dim == 1)
-    return size();
-  else
-    return (dim == 0) ? layout_.size(0) : layout_.size(1);
-}
-
-
-
-// Requires:
-//   DIM is a valid dimensionality supported by block (DIM == 1 or 2)
-//   D is a dimension, less than DIM.
-// Returns
-//   The stride in dimension D, for dimensionality DIM.
-
-template <typename    T,
-	  typename    Order,
-	  typename    Map>
-inline
-stride_type
-Plain_block<2, T, Order, Map>::impl_stride(dimension_type Dim, dimension_type d)
-  const VSIP_NOTHROW
-{
-  assert(Dim == 1 || Dim == dim);
-  assert(d < Dim);
-
-  if (Dim == 1)
-    return 1;
-  else
-    return layout_.stride(d);
-}
-
-
-
-} // namespace vsip
-
-#endif // VSIP_DENSE_HPP
Index: tests/extdata.cpp
===================================================================
--- tests/extdata.cpp	(revision 148805)
+++ tests/extdata.cpp	(working copy)
@@ -17,7 +17,7 @@
 #include <vsip/vector.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "plainblock.hpp"
+#include <vsip_csl/plainblock.hpp>
 
 using namespace std;
 using namespace vsip;
Index: tests/coverage_binary.cpp
===================================================================
--- tests/coverage_binary.cpp	(revision 148805)
+++ tests/coverage_binary.cpp	(working copy)
@@ -19,7 +19,7 @@
 #include <vsip/random.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "test-storage.hpp"
+#include <vsip_csl/test-storage.hpp>
 #include "coverage_common.hpp"
 
 using namespace std;
Index: tests/extdata-fft.cpp
===================================================================
--- tests/extdata-fft.cpp	(revision 148805)
+++ tests/extdata-fft.cpp	(working copy)
@@ -21,7 +21,7 @@
 #include <vsip/impl/fast-block.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "plainblock.hpp"
+#include <vsip_csl/plainblock.hpp>
 #include "extdata-output.hpp"
 
 using namespace std;
Index: tests/coverage_unary.cpp
===================================================================
--- tests/coverage_unary.cpp	(revision 148805)
+++ tests/coverage_unary.cpp	(working copy)
@@ -19,7 +19,7 @@
 #include <vsip/random.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "test-storage.hpp"
+#include <vsip_csl/test-storage.hpp>
 #include "coverage_common.hpp"
 
 using namespace std;
Index: tests/extdata-runtime.cpp
===================================================================
--- tests/extdata-runtime.cpp	(revision 148805)
+++ tests/extdata-runtime.cpp	(working copy)
@@ -21,7 +21,7 @@
 #include <vsip/tensor.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "plainblock.hpp"
+#include <vsip_csl/plainblock.hpp>
 #include "extdata-output.hpp"
 
 using namespace std;
Index: tests/reductions.cpp
===================================================================
--- tests/reductions.cpp	(revision 148805)
+++ tests/reductions.cpp	(working copy)
@@ -18,7 +18,7 @@
 #include <vsip/parallel.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "test-storage.hpp"
+#include <vsip_csl/test-storage.hpp>
 
 using namespace vsip;
 using namespace vsip_csl;
Index: tests/coverage_comparison.cpp
===================================================================
--- tests/coverage_comparison.cpp	(revision 148805)
+++ tests/coverage_comparison.cpp	(working copy)
@@ -18,7 +18,7 @@
 #include <vsip/math.hpp>
 
 #include <vsip_csl/test.hpp>
-#include "test-storage.hpp"
+#include <vsip_csl/test-storage.hpp>
 #include "coverage_common.hpp"
 
 using namespace std;
Index: configure.ac
===================================================================
--- configure.ac	(revision 148805)
+++ configure.ac	(working copy)
@@ -858,7 +858,8 @@
       vsipl_par_service=0
       CPPFLAGS="$save_CPPFLAGS"
     fi
-  else
+  else 
+    AC_SUBST(VSIP_IMPL_MPI_H, 1)
     AC_DEFINE_UNQUOTED([VSIP_IMPL_MPI_H], $vsipl_mpi_h_name,
     [The name of the header to include for the MPI interface, with <> quotes.])
 
Index: benchmarks/mcopy_ipp.cpp
===================================================================
--- benchmarks/mcopy_ipp.cpp	(revision 148805)
+++ benchmarks/mcopy_ipp.cpp	(working copy)
@@ -27,9 +27,9 @@
 
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/output.hpp>
+#include <vsip_csl/plainblock.hpp>
 #include "loop.hpp"
 
-#include "plainblock.hpp"
 
 using namespace vsip;
 using namespace vsip_csl;
Index: benchmarks/prod.cpp
===================================================================
--- benchmarks/prod.cpp	(revision 148805)
+++ benchmarks/prod.cpp	(working copy)
@@ -21,10 +21,10 @@
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/ops_info.hpp>
 
+#include <vsip_csl/plainblock.hpp>
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
 
-#include "plainblock.hpp"
 
 using namespace vsip;
 
Index: benchmarks/conv_ipp.cpp
===================================================================
--- benchmarks/conv_ipp.cpp	(revision 148805)
+++ benchmarks/conv_ipp.cpp	(working copy)
@@ -15,6 +15,11 @@
 #include <cmath>
 #include <complex>
 
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+#include <vsip/signal.hpp>
+
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/ops_info.hpp>
 
Index: benchmarks/vma.cpp
===================================================================
--- benchmarks/vma.cpp	(revision 148805)
+++ benchmarks/vma.cpp	(working copy)
@@ -19,9 +19,10 @@
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
 
+#include <vsip_csl/test-storage.hpp>
 #include "benchmarks.hpp"
-#include "../tests/test-storage.hpp"
 
+
 using namespace vsip;
 
 
Index: benchmarks/vmul_ipp.cpp
===================================================================
--- benchmarks/vmul_ipp.cpp	(revision 148805)
+++ benchmarks/vmul_ipp.cpp	(working copy)
@@ -14,6 +14,10 @@
 #include <iostream>
 #include <complex>
 
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/ops_info.hpp>
 
Index: benchmarks/make.standalone
===================================================================
--- benchmarks/make.standalone	(revision 148805)
+++ benchmarks/make.standalone	(working copy)
@@ -90,12 +90,15 @@
 srcs_lapack := $(wildcard *_lapack.cpp) qrd.cpp
 srcs_ipp    := $(wildcard *_ipp.cpp) 
 srcs_sal    := $(wildcard *_sal.cpp) 
+srcs_mpi    := $(wildcard *_mpi.cpp) 
 
 exes_lapack := $(patsubst %.cpp, %$(EXEEXT),  $(srcs_lapack))
 exes_ipp    := $(patsubst %.cpp, %$(EXEEXT),  $(srcs_ipp))
 exes_sal    := $(patsubst %.cpp, %$(EXEEXT),  $(srcs_sal))
+exes_mpi    := $(patsubst %.cpp, %$(EXEEXT),  $(srcs_mpi))
 
-exes_special   := main$(EXEEXT) $(exes_lapack) $(exes_ipp) $(exes_sal)
+exes_special   := main$(EXEEXT) $(exes_lapack) $(exes_ipp) \
+                                $(exes_sal) $(exes_mpi)
 exes_def_build := $(filter-out $(exes_special), $(exes)) 
 
 
Index: benchmarks/mcopy.cpp
===================================================================
--- benchmarks/mcopy.cpp	(revision 148805)
+++ benchmarks/mcopy.cpp	(working copy)
@@ -23,10 +23,10 @@
 #include <vsip/impl/metaprogramming.hpp>
 #include <vsip/impl/ops_info.hpp>
 
+#include <vsip_csl/plainblock.hpp>
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
 
-#include "plainblock.hpp"
 
 using namespace vsip;
 using namespace vsip_csl;
Index: benchmarks/fft_ipp.cpp
===================================================================
--- benchmarks/fft_ipp.cpp	(revision 148805)
+++ benchmarks/fft_ipp.cpp	(working copy)
@@ -15,6 +15,11 @@
 #include <cmath>
 #include <complex>
 
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/math.hpp>
+#include <vsip/signal.hpp>
+
 #include <vsip/impl/profile.hpp>
 
 #include <ipps.h>
