Index: src/vsip/opt/cbe/cml/matvec.hpp
===================================================================
--- src/vsip/opt/cbe/cml/matvec.hpp	(revision 208933)
+++ src/vsip/opt/cbe/cml/matvec.hpp	(working copy)
@@ -37,7 +37,7 @@
 {
 
 
-/// CML evaluator for matrix-matrix products.
+/// CML evaluator for matrix-matrix products
 
 template <typename Block0,
           typename Block1,
@@ -122,7 +122,7 @@
 };
 
 
-/// CML evaluator for matrix-matrix conjugate products.
+/// CML evaluator for matrix-matrix conjugate products
 
 template <typename Block0,
           typename Block1,
@@ -207,6 +207,159 @@
 };
 
 
+/// CML evaluator for matrix-vector products
+
+template <typename Block0,
+          typename Block1,
+          typename Block2>
+struct Evaluator<Op_prod_mv, Block0, Op_list_2<Block1, Block2>,
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
+    // check that direct access is supported
+    Ext_data_cost<Block0>::value == 0 &&
+    Ext_data_cost<Block1>::value == 0 &&
+    Ext_data_cost<Block2>::value == 0;
+
+  static bool rt_valid(Block0& r, Block1 const& a, Block2 const& b)
+  {
+    Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+
+    // For 'a', the dimension with the smallest stride must be one,
+    // which depends on whether it is row- or column-major.
+    bool is_a_row = Type_equal<order1_type, row2_type>::value;
+    stride_type a_stride = is_a_row ? ext_a.stride(1) : ext_a.stride(0);
+
+    return (a_stride == 1);
+  }
+
+  static void exec(Block0& r, Block1 const& a, Block2 const& b)
+  {
+    Ext_data<Block0> ext_r(const_cast<Block0&>(r));
+    Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+    Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+
+    // Either row- or column-major layouts are supported for the input 
+    // matrix by using the identity:
+    //   trans(r) = trans(b) * trans(a)
+    // or just
+    //   r = b * trans(a)  (since r and b are vectors)
+    if (Type_equal<order1_type, row2_type>::value)
+    {
+      cml::mvprod(
+        ext_a.data(), ext_a.stride(0),
+        ext_b.data(), ext_b.stride(0),
+        ext_r.data(), ext_r.stride(0),
+        a.size(2, 0),   // M
+        a.size(2, 1) ); // N
+    }
+    else if (Type_equal<order1_type, col2_type>::value)
+    {
+      cml::vmprod(
+        ext_b.data(), ext_b.stride(0),
+        ext_a.data(), ext_a.stride(1),
+        ext_r.data(), ext_r.stride(0),
+        a.size(2, 1),   // N
+        a.size(2, 0) ); // M
+    }
+    else
+      assert(0);
+  }
+};
+
+
+/// CML evaluator for vector-matrix products
+
+template <typename Block0,
+          typename Block1,
+          typename Block2>
+struct Evaluator<Op_prod_vm, Block0, Op_list_2<Block1, Block2>,
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
+    // check that direct access is supported
+    Ext_data_cost<Block0>::value == 0 &&
+    Ext_data_cost<Block1>::value == 0 &&
+    Ext_data_cost<Block2>::value == 0;
+
+  static bool rt_valid(Block0& r, Block1 const& a, Block2 const& b)
+  {
+    Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+
+    // For 'b', the dimension with the smallest stride must be one,
+    // which depends on whether it is row- or column-major.
+    bool is_b_row = Type_equal<order2_type, row2_type>::value;
+    stride_type b_stride = is_b_row ? ext_b.stride(1) : ext_b.stride(0);
+
+    return (b_stride == 1);
+  }
+
+  static void exec(Block0& r, Block1 const& a, Block2 const& b)
+  {
+    Ext_data<Block0> ext_r(const_cast<Block0&>(r));
+    Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+    Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+
+    // Either row- or column-major layouts are supported for the input 
+    // matrix by using the identity:
+    //   trans(r) = trans(b) * trans(a)
+    // or just
+    //   r = b * trans(a)  (since r and b are vectors)
+    if (Type_equal<order2_type, row2_type>::value)
+    {
+      cml::vmprod(
+        ext_a.data(), ext_a.stride(0),
+        ext_b.data(), ext_b.stride(0),
+        ext_r.data(), ext_r.stride(0),
+        b.size(2, 0),   // M
+        b.size(2, 1) ); // N
+    }
+    else if (Type_equal<order2_type, col2_type>::value)
+    {
+      cml::mvprod(
+        ext_b.data(), ext_b.stride(1),
+        ext_a.data(), ext_a.stride(0),
+        ext_r.data(), ext_r.stride(0),
+        b.size(2, 1),   // N
+        b.size(2, 0) ); // M
+    }
+    else
+      assert(0);
+  }
+};
+
+
+
 } // namespace vsip::impl
 
 } // namespace vsip
Index: src/vsip/opt/cbe/cml/prod.hpp
===================================================================
--- src/vsip/opt/cbe/cml/prod.hpp	(revision 208933)
+++ src/vsip/opt/cbe/cml/prod.hpp	(working copy)
@@ -105,6 +105,37 @@
 #undef VSIP_IMPL_CML_ZMPROD
 
 
+// This macro supports scalar and interleaved complex types
+
+#define VSIP_IMPL_CML_MVPROD(T, FCN, CML_FCN)   \
+  inline void                                   \
+  FCN(                                          \
+    T *a, int lda,                              \
+    T *b, int ldb,                              \
+    T *z, int ldz,                              \
+    int m, int n)                               \
+  {                                             \
+    typedef Scalar_of<T>::type CML_T;           \
+    CML_FCN(                                    \
+      reinterpret_cast<CML_T*>(a),              \
+      static_cast<ptrdiff_t>(lda),              \
+      reinterpret_cast<CML_T*>(b),              \
+      static_cast<ptrdiff_t>(ldb),              \
+      reinterpret_cast<CML_T*>(z),              \
+      static_cast<ptrdiff_t>(ldz),              \
+      static_cast<size_t>(m),                   \
+      static_cast<size_t>(n) );                 \
+  }
+
+VSIP_IMPL_CML_MVPROD(float,               mvprod,  cml_mvprod1_f)
+VSIP_IMPL_CML_MVPROD(std::complex<float>, mvprod,  cml_cmvprod1_f)
+VSIP_IMPL_CML_MVPROD(float,               vmprod,  cml_vmprod1_f)
+VSIP_IMPL_CML_MVPROD(std::complex<float>, vmprod,  cml_cvmprod1_f)
+#undef VSIP_IMPL_CML_MVPROD
+
+
+
+
 } // namespace vsip::impl::cml
 
 } // namespace vsip::impl
Index: tests/matvec-prodmv.cpp
===================================================================
--- tests/matvec-prodmv.cpp	(revision 208933)
+++ tests/matvec-prodmv.cpp	(working copy)
@@ -18,6 +18,7 @@
 
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
 #include <vsip/math.hpp>
 
@@ -144,7 +145,138 @@
 }
 
 
+/// Test matrix-matrix products using sub-views
 
+template <typename T>
+void
+test_mv_prod_subview( const length_type m, 
+                      const length_type n )
+{
+  typedef typename Matrix<T>::subview_type matrix_subview_type;
+  typedef typename Vector<T>::subview_type vector_subview_type;
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+
+  {
+    // non-unit strides - non-dense rows/vectors, dense columns
+    Matrix<T> aa(m*2, n, T());
+    Vector<T> bb(n*3, T());
+    matrix_subview_type a = aa(Domain<2>(
+                                Domain<1>(0, 2, m), Domain<1>(0, 1, n)));
+    vector_subview_type b = bb(Domain<1>(0, 3, n));
+
+    randm(a);
+    randv(b);
+
+    Vector<T> res(m);
+    Vector<T> chk(m);
+    Vector<scalar_type> gauge(m);
+
+    res = prod( a, b );
+    chk = ref::prod( a, b );
+    gauge = ref::prod(mag(a), mag(b));
+
+    for (index_type i=0; i<gauge.size(0); ++i)
+      if (!(gauge(i) > scalar_type()))
+        gauge(i) = scalar_type(1);
+
+    check_prod( res, chk, gauge );
+  }
+
+  {
+    // non-unit strides - dense rows, non-dense columns/vectors
+    Matrix<T> aa(m*2, n, T());
+    Vector<T> bb(m*3, T());
+    matrix_subview_type a = aa(Domain<2>(
+                                Domain<1>(0, 2, m), Domain<1>(0, 1, n)));
+    vector_subview_type b = bb(Domain<1>(0, 3, m));
+
+    randm(a);
+    randv(b);
+
+    Vector<T> res(n);
+    Vector<T> chk(n);
+    Vector<scalar_type> gauge(n);
+
+    res = prod( trans(a), b );
+    chk = ref::prod( trans(a), b );
+    gauge = ref::prod(mag(trans(a)), mag(b));
+
+    for (index_type i=0; i<gauge.size(0); ++i)
+      if (!(gauge(i) > scalar_type()))
+        gauge(i) = scalar_type(1);
+
+    check_prod( res, chk, gauge );
+  }
+}
+
+
+/// Test matrix-matrix products using sub-views
+
+template <typename T>
+void
+test_vm_prod_subview( const length_type m, 
+                      const length_type n )
+{
+  typedef typename Matrix<T>::subview_type matrix_subview_type;
+  typedef typename Vector<T>::subview_type vector_subview_type;
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+
+  {
+    // non-unit strides - non-dense rows/vectors, dense columns
+    Vector<T> aa(m*3, T());
+    Matrix<T> bb(m*2, n, T());
+    vector_subview_type a = aa(Domain<1>(0, 3, m));
+    matrix_subview_type b = bb(Domain<2>(
+                                Domain<1>(0, 2, m), Domain<1>(0, 1, n)));
+
+    randv(a);
+    randm(b);
+
+    Vector<T> res(n);
+    Vector<T> chk(n);
+    Vector<scalar_type> gauge(n);
+
+    res = prod( a, b );
+    chk = ref::prod( a, b );
+    gauge = ref::prod(mag(a), mag(b));
+
+    for (index_type i=0; i<gauge.size(0); ++i)
+      if (!(gauge(i) > scalar_type()))
+        gauge(i) = scalar_type(1);
+
+    check_prod( res, chk, gauge );
+  }
+
+  {
+    // non-unit strides - dense rows, non-dense columns/vectors
+    Vector<T> aa(n*3, T());
+    Matrix<T> bb(m*2, n, T());
+    vector_subview_type a = aa(Domain<1>(0, 3, n));
+    matrix_subview_type b = bb(Domain<2>(
+                                Domain<1>(0, 2, m), Domain<1>(0, 1, n)));
+
+    randv(a);
+    randm(b);
+
+    Vector<T> res(m);
+    Vector<T> chk(m);
+    Vector<scalar_type> gauge(m);
+
+    res = prod( a, trans(b) );
+    chk = ref::prod( a, trans(b) );
+    gauge = ref::prod(mag(a), mag(trans(b)));
+
+    for (index_type i=0; i<gauge.size(0); ++i)
+      if (!(gauge(i) > scalar_type()))
+        gauge(i) = scalar_type(1);
+
+    check_prod( res, chk, gauge );
+  }
+}
+
+
+
+
 template <typename T0,
 	  typename T1>
 void
@@ -155,7 +287,16 @@
 }
 
 
+template <typename T>
+void
+prod_subview_cases()
+{
+  test_mv_prod_subview<T>(5, 7);
+  test_vm_prod_subview<T>(5, 7);
+}
 
+
+
 /***********************************************************************
   Main
 ***********************************************************************/
@@ -175,6 +316,9 @@
   prod_cases<float,          complex<float> >();
   prod_cases<complex<float>, float          >();
 
+  prod_subview_cases<float>();
+  prod_subview_cases<complex<float> >();
+
 #if VSIP_IMPL_TEST_DOUBLE
   prod_cases<double, double>();
   prod_cases<float,  double>();
