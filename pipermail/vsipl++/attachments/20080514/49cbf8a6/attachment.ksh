Index: src/vsip/core/matvec_prod.hpp
===================================================================
--- src/vsip/core/matvec_prod.hpp	(revision 207717)
+++ src/vsip/core/matvec_prod.hpp	(working copy)
@@ -20,7 +20,10 @@
 #if VSIP_IMPL_CVSIP_FFT
 # include <vsip/core/cvsip/matvec.hpp>
 #endif
-#ifdef VSIP_IMPL_REF_IMPL
+#ifndef VSIP_IMPL_REF_IMPL
+# ifdef VSIP_IMPL_CBE_SDK
+#  include <vsip/opt/cbe/cml/matvec.hpp>
+# endif
 # ifdef VSIP_IMPL_HAVE_BLAS
 #  include <vsip/opt/lapack/matvec.hpp>
 # endif
Index: src/vsip/core/impl_tags.hpp
===================================================================
--- src/vsip/core/impl_tags.hpp	(revision 207717)
+++ src/vsip/core/impl_tags.hpp	(working copy)
@@ -36,6 +36,7 @@
 struct Transpose_tag {};	// Optimized Matrix Transpose
 struct Mercury_sal_tag {};	// Mercury SAL Library
 struct Cbe_sdk_tag {};          // IBM CBE SDK.
+struct Cml_tag {};              // IBM Cell Math Library
 struct Simd_builtin_tag {};	// Builtin SIMD routines (non loop fusion)
 struct Dense_expr_tag {};	// Dense multi-dim expr reduction
 struct Copy_tag {};		// Optimized Copy
Index: src/vsip/opt/general_dispatch.hpp
===================================================================
--- src/vsip/opt/general_dispatch.hpp	(revision 207717)
+++ src/vsip/opt/general_dispatch.hpp	(working copy)
@@ -42,7 +42,7 @@
 struct Dispatch_order
 {
   typedef typename Make_type_list<
-    Blas_tag, Mercury_sal_tag, Cvsip_tag, Generic_tag 
+    Cml_tag, Blas_tag, Mercury_sal_tag, Cvsip_tag, Generic_tag 
     >::type type;
 };
 
Index: src/vsip/opt/cbe/cml/matvec.hpp
===================================================================
--- src/vsip/opt/cbe/cml/matvec.hpp	(revision 0)
+++ src/vsip/opt/cbe/cml/matvec.hpp	(revision 0)
@@ -0,0 +1,109 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/cml/matvec.hpp
+    @author  Don McCoy
+    @date    2008-05-07
+    @brief   VSIPL++ Library: CML matrix product evaluators.
+*/
+
+#ifndef VSIP_OPT_CBE_CML_MATVEC_HPP
+#define VSIP_OPT_CBE_CML_MATVEC_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/general_dispatch.hpp>
+#include <vsip/opt/cbe/cml/prod.hpp>
+#include <vsip/opt/cbe/cml/traits.hpp>
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+
+// CML evaluator for matrix-matrix products.
+
+template <typename Block0,
+          typename Block1,
+          typename Block2>
+struct Evaluator<Op_prod_mm, Block0, Op_list_2<Block1, Block2>,
+                 Cml_tag>
+{
+  typedef typename Block0::value_type T;
+  typedef typename Block_layout<Block0>::order_type order0_type;
+  typedef typename Block_layout<Block1>::order_type order1_type;
+  typedef typename Block_layout<Block2>::order_type order2_type;
+
+  static bool const ct_valid = 
+    // check that CML supports this data type and/or layout
+    impl::cml::Cml_supports_block<Block0>::valid &&
+    impl::cml::Cml_supports_block<Block1>::valid &&
+    impl::cml::Cml_supports_block<Block2>::valid &&
+    // check that all data types are equal
+    Type_equal<T, typename Block1::value_type>::value &&
+    Type_equal<T, typename Block2::value_type>::value &&
+    // check that the complex layouts are equal
+    Is_split_block<Block0>::value == Is_split_block<Block1>::value &&
+    Is_split_block<Block0>::value == Is_split_block<Block2>::value &&
+    // check that the layout is row-major
+    Type_equal<order0_type, row2_type>::value && 
+    Type_equal<order1_type, row2_type>::value && 
+    Type_equal<order2_type, row2_type>::value && 
+    // check that direct access is supported
+    Ext_data_cost<Block0>::value == 0 &&
+    Ext_data_cost<Block1>::value == 0 &&
+    Ext_data_cost<Block2>::value == 0;
+
+  static bool rt_valid(Block0& r, Block1 const& a, Block2 const& b)
+  {
+    Ext_data<Block0> ext_r(const_cast<Block0&>(r));
+    Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+    Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+
+    return
+      // ensure the data is unit-stide
+      ( ext_r.stride(1) == 1 &&
+        ext_a.stride(1) == 1 &&
+        ext_b.stride(1) == 1 );
+  }
+
+  static void exec(Block0& r, Block1 const& a, Block2 const& b)
+  {
+    typedef typename Block_layout<Block0>::complex_type complex_type;
+
+    Ext_data<Block0> ext_r(const_cast<Block0&>(r));
+    Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+    Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+
+    cml::mprod(
+      ext_a.data(), ext_a.stride(0),
+      ext_b.data(), ext_b.stride(0),
+      ext_r.data(), ext_r.stride(0),
+      a.size(2, 0),   // M
+      a.size(2, 1),   // N
+      b.size(2, 1) ); // P
+  }
+};
+
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_OPT_CBE_CML_MATVEC_HPP
Index: src/vsip/opt/cbe/cml/prod.hpp
===================================================================
--- src/vsip/opt/cbe/cml/prod.hpp	(revision 0)
+++ src/vsip/opt/cbe/cml/prod.hpp	(revision 0)
@@ -0,0 +1,107 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/cml/prod.hpp
+    @author  Don McCoy
+    @date    2008-05-07
+    @brief   VSIPL++ Library: Bindings for CML matrix product routines.
+*/
+
+#ifndef VSIP_OPT_CBE_CML_PROD_HPP
+#define VSIP_OPT_CBE_CML_PROD_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <complex>
+
+#include <vsip/support.hpp>
+#include <vsip/core/config.hpp>
+#include <vsip/core/metaprogramming.hpp>
+
+#include <cml/ppu/cml.h>
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+namespace cml
+{
+
+
+// This macro supports scalar and interleaved complex types
+
+#define VSIP_IMPL_CML_MPROD(T, FCN)     \
+inline void                             \
+mprod(                                  \
+  T *a, int lda,                        \
+  T *b, int ldb,                        \
+  T *z, int ldz,                        \
+  int m, int n, int p)                  \
+{                                       \
+  typedef Scalar_of<T>::type CML_T;     \
+  FCN(                                  \
+    reinterpret_cast<CML_T*>(a),        \
+    static_cast<ptrdiff_t>(lda),        \
+    reinterpret_cast<CML_T*>(b),        \
+    static_cast<ptrdiff_t>(ldb),        \
+    reinterpret_cast<CML_T*>(z),        \
+    static_cast<ptrdiff_t>(ldz),        \
+    static_cast<size_t>(m),             \
+    static_cast<size_t>(n),             \
+    static_cast<size_t>(p) );           \
+}
+
+VSIP_IMPL_CML_MPROD(float,                cml_mprod1_f)
+VSIP_IMPL_CML_MPROD(std::complex<float>,  cml_cmprod1_f)
+#undef VSIP_IMPL_CML_MPROD
+
+
+// This version is for split complex only.
+
+#define VSIP_IMPL_CML_ZMPROD(T, FCN)    \
+inline void                             \
+mprod(                                  \
+  std::pair<T*, T*> a, int lda,         \
+  std::pair<T*, T*> b, int ldb,         \
+  std::pair<T*, T*> z, int ldz,         \
+  int m, int n, int p)                  \
+{                                       \
+  FCN(                                  \
+    a.first, a.second,                  \
+    static_cast<ptrdiff_t>(lda),        \
+    b.first, b.second,                  \
+    static_cast<ptrdiff_t>(ldb),        \
+    z.first, z.second,                  \
+    static_cast<ptrdiff_t>(ldz),        \
+    static_cast<size_t>(m),             \
+    static_cast<size_t>(n),             \
+    static_cast<size_t>(p) );           \
+}
+
+VSIP_IMPL_CML_ZMPROD(float, cml_zmprod1_f)
+#undef VSIP_IMPL_CML_ZMPROD
+
+
+} // namespace vsip::impl::cml
+
+} // namespace vsip::impl
+
+} // namespace vsip
+
+#endif // VSIP_OPT_CBE_CML_PROD_HPP
Index: src/vsip/opt/cbe/cml/traits.hpp
===================================================================
--- src/vsip/opt/cbe/cml/traits.hpp	(revision 0)
+++ src/vsip/opt/cbe/cml/traits.hpp	(revision 0)
@@ -0,0 +1,47 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/cbe/cml/traits.hpp
+    @author  Don McCoy
+    @date    2008-05-07
+    @brief   VSIPL++ Library: Traits for CML evaluators.
+*/
+
+#ifndef VSIP_OPT_CBE_CML_TRAITS_HPP
+#define VSIP_OPT_CBE_CML_TRAITS_HPP
+
+
+namespace vsip
+{
+namespace impl
+{
+namespace cml
+{
+
+// At present, this traits class helps determine whether or not
+// CML supports a given block's value_type simply by checking
+// whether or not the underlying scalar type is a single-precision 
+// floating point type.  This makes it valid for scalar floats,
+// or complex floats (regardless of the layout being split or 
+// interleaved).
+template <typename BlockT>
+struct Cml_supports_block
+{
+private:
+  typedef typename BlockT::value_type value_type;
+
+public:
+  static bool const valid =
+    Type_equal<typename Scalar_of<value_type>::type, float>::value;
+};
+
+
+} // namespace vsip::impl::cml
+} // namespace vsip::impl
+} // namespace vsip
+
+
+#endif // VSIP_OPT_CBE_CML_TRAITS_HPP
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 207717)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -125,6 +125,7 @@
 ifdef VSIP_IMPL_HAVE_CBE_SDK
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/cbe
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/cbe/ppu
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/cbe/cml
 endif
 endif
 	for header in $(hdr); do \
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 207717)
+++ ChangeLog	(working copy)
@@ -1,3 +1,22 @@
+2008-05-14  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/core/matvec_prod.hpp: Fixes a typo affecting the headers
+	  included when building the reference implementation.  Adds include
+	  for new CML backend for matrix products.
+	* src/vsip/core/impl_tags.hpp: New tag for CML backend.
+	* src/vsip/opt/general_dispatch.hpp: Adds CML tag to typelist.
+	* src/vsip/opt/cbe/cml/matvec.hpp: New file.  Handles matrix product
+	  dispatch to CML backend.
+	* src/vsip/opt/cbe/cml/prod.hpp: Wrappers (bindings) for matrix
+	  produt functions in CML.
+	* src/vsip/opt/cbe/cml/traits.hpp: Helper traits classes that pertain
+	  strictly to CML.
+	* src/vsip/GNUmakefile.inc.in: Adds new install directory.
+	* GNUmakefile.in: Adds new header include directory.
+	* examples/mprod.cpp: New file.  Demonstrates matrix product API.
+	* examples/GNUmakefile.inc.in: Exclude mprod example for reference 
+	  build (due to include from vsip_csl/).
+
 2008-05-14  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/cbe/ppu/alf.hpp: Queury ALF handle from CML.  Allow
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 207717)
+++ GNUmakefile.in	(working copy)
@@ -380,6 +380,8 @@
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/cbe/ppu/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/opt/cbe/cml/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/cbe/*.h))
 endif
 endif
Index: examples/mprod.cpp
===================================================================
--- examples/mprod.cpp	(revision 0)
+++ examples/mprod.cpp	(revision 0)
@@ -0,0 +1,68 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved. */
+
+/** @file    mprod.cpp
+    @author  Don McCoy
+    @date    2008-05-08
+    @brief   VSIPL++ Library: Simple demonstation of matrix products.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/math.hpp>
+#include <vsip/matrix.hpp>
+
+#include <vsip_csl/output.hpp>
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+using namespace vsip;
+using namespace vsip_csl;
+
+
+int
+main(int argc, char **argv)
+{
+  vsipl init(argc, argv);
+
+  {  
+    typedef vsip::scalar_f   T;
+    Matrix<T> a(5, 4, T(2));
+    Matrix<T> b(4, 3, T(3));
+    Matrix<T> c(5, 3, T());
+    
+    c = prod(a, b);
+
+    std::cout << "c = " << std::endl << c << std::endl;
+  }
+
+  {  
+    typedef vsip::cscalar_f   T;
+    Matrix<T> a(5, 4, T(2));
+    Matrix<T> b(4, 3, T(3));
+    Matrix<T> c(5, 3, T());
+    
+    c = prod(a, b);
+
+    std::cout << "c = " << std::endl << c << std::endl;
+  }
+
+  {  
+    typedef vsip::scalar_f   T;
+    typedef vsip::cscalar_f  CT;
+    Matrix<T> a(5, 4, T(2));
+    Matrix<CT> b(4, 3, CT(3));
+    Matrix<CT> c(5, 3, CT());
+    
+    c = prod(a, b);
+
+    std::cout << "c = " << std::endl << c << std::endl;
+  }
+
+  return 0;
+}
Index: examples/GNUmakefile.inc.in
===================================================================
--- examples/GNUmakefile.inc.in	(revision 207717)
+++ examples/GNUmakefile.inc.in	(working copy)
@@ -22,6 +22,7 @@
 endif
 ifdef VSIP_IMPL_REF_IMPL
 examples_cxx_sources := $(filter-out %extdata.cpp, $(examples_cxx_sources))
+examples_cxx_sources := $(filter-out %mprod.cpp, $(examples_cxx_sources))
 endif
 examples_cxx_objects := \
 	$(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(examples_cxx_sources))
