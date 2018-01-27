Index: src/vsip/core/matvec.hpp
===================================================================
--- src/vsip/core/matvec.hpp	(revision 209885)
+++ src/vsip/core/matvec.hpp	(working copy)
@@ -21,6 +21,9 @@
 #include <vsip/core/fns_elementwise.hpp>
 #ifndef VSIP_IMPL_REF_IMPL
 # include <vsip/opt/general_dispatch.hpp>
+# ifdef VSIP_IMPL_CBE_SDK
+#  include <vsip/opt/cbe/cml/matvec.hpp>
+# endif
 # ifdef VSIP_IMPL_HAVE_BLAS
 #  include <vsip/opt/lapack/matvec.hpp>
 # endif
Index: src/vsip/opt/cbe/cml/matvec.hpp
===================================================================
--- src/vsip/opt/cbe/cml/matvec.hpp	(revision 209886)
+++ src/vsip/opt/cbe/cml/matvec.hpp	(working copy)
@@ -37,6 +37,230 @@
 {
 
 
+/// CML evaluator for vector dot products (non-conjugated)
+
+template <typename T,
+          typename Block1,
+          typename Block2>
+struct Evaluator<Op_prod_vv_dot, Return_scalar<T>, Op_list_2<Block1, Block2>,
+                 Cml_tag>
+{
+  typedef typename Block_layout<Block1>::complex_type complex1_type;
+  typedef typename Block_layout<Block2>::complex_type complex2_type;
+
+  static bool const ct_valid = 
+    // check that CML supports this data type and/or layout
+    impl::cml::Cml_supports_block<Block1>::valid &&
+    impl::cml::Cml_supports_block<Block2>::valid &&
+    // check that all data types are equal
+    Type_equal<T, typename Block1::value_type>::value &&
+    Type_equal<T, typename Block2::value_type>::value &&
+    // check that direct access is supported
+    Ext_data_cost<Block1>::value == 0 &&
+    Ext_data_cost<Block2>::value == 0 &&
+    // check complex layout is consistent
+    Is_split_block<Block1>::value == Is_split_block<Block2>::value;
+
+  static bool rt_valid(Block1 const&, Block2 const&) { return true; }
+
+  static T exec(Block1 const& a, Block2 const& b)
+  {
+    assert(a.size(1, 0) == b.size(1, 0));
+
+    Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+    Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+
+    T r = T();
+    cml::dot( ext_a.data(), ext_a.stride(0),
+              ext_b.data(), ext_b.stride(0),
+              &r, a.size(1, 0) );
+
+    return r;
+  }
+};
+
+
+
+/// CML evaluator for vector dot products (conjugated)
+
+template <typename T,
+          typename Block1,
+          typename Block2>
+struct Evaluator<Op_prod_vv_dot, Return_scalar<complex<T> >,
+                 Op_list_2<Block1, 
+                           Unary_expr_block<1, impl::conj_functor,
+                                            Block2, complex<T> > const>,
+                 Cml_tag>
+{
+  typedef typename Block_layout<Block1>::complex_type complex1_type;
+  typedef typename Block_layout<Block2>::complex_type complex2_type;
+
+  static bool const ct_valid = 
+    // check that CML supports this data type and/or layout
+    impl::cml::Cml_supports_block<Block1>::valid &&
+    impl::cml::Cml_supports_block<Block2>::valid &&
+    // check that types are complex
+    Is_complex<typename Block1::value_type>::value &&
+    Is_complex<typename Block2::value_type>::value &&
+    // check that direct access is supported
+    Ext_data_cost<Block1>::value == 0 &&
+    Ext_data_cost<Block2>::value == 0 &&
+    // check complex layout is consistent
+    Is_split_block<Block1>::value == Is_split_block<Block2>::value;
+
+  static bool rt_valid(
+    Block1 const&, 
+    Unary_expr_block<1, impl::conj_functor, Block2, complex<T> > const&)
+  { return true; }
+
+  static complex<T> exec(
+    Block1 const& a, 
+    Unary_expr_block<1, impl::conj_functor, Block2, complex<T> > const& b)
+  {
+    assert(a.size(1, 0) == b.size(1, 0));
+
+    Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+    Ext_data<Block2> ext_b(const_cast<Block2&>(b.op()));
+
+    complex<T> r = complex<T>();
+    cml::dotc( ext_a.data(), ext_a.stride(0),
+               ext_b.data(), ext_b.stride(0),
+               &r, a.size(1, 0) );
+
+    return r;
+  }
+};
+
+
+/// CML evaluator for outer products
+
+template <typename T1,
+          typename Block0,
+          typename Block1,
+          typename Block2>
+struct Evaluator<Op_prod_vv_outer, Block0,
+		 Op_list_3<T1, Block1 const&, Block2 const&>,
+                 Cml_tag>
+{
+  typedef typename Block_layout<Block0>::order_type order0_type;
+
+  static bool const ct_valid = 
+    // check that CML supports this data type and/or layout
+    impl::cml::Cml_supports_block<Block0>::valid &&
+    impl::cml::Cml_supports_block<Block1>::valid &&
+    impl::cml::Cml_supports_block<Block2>::valid &&
+    // check that the output is row-major 
+    Type_equal<order0_type, row2_type>::value &&
+    // check that all data types are equal
+    Type_equal<T1, typename Block0::value_type>::value &&
+    Type_equal<T1, typename Block1::value_type>::value &&
+    Type_equal<T1, typename Block2::value_type>::value &&
+    // check that the complex layouts are equal
+    Is_split_block<Block0>::value == Is_split_block<Block1>::value &&
+    Is_split_block<Block0>::value == Is_split_block<Block2>::value &&
+    // check that direct access is supported
+    Ext_data_cost<Block0>::value == 0 &&
+    Ext_data_cost<Block1>::value == 0 &&
+    Ext_data_cost<Block2>::value == 0;
+
+  static bool rt_valid(Block0& r, T1, Block1 const& a, Block2 const& b)
+  {
+    Ext_data<Block0> ext_r(const_cast<Block0&>(r));
+    Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+    Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+
+    bool unit_stride =
+      (ext_r.stride(1) == 1) &&
+      (ext_a.stride(0) == 1) && 
+      (ext_b.stride(0) == 1);
+
+    return unit_stride;
+  }
+
+  static void exec(Block0& r, T1 alpha, Block1 const& a, Block2 const& b)
+  {
+    assert(a.size(1, 0) == r.size(2, 0));
+    assert(b.size(1, 0) == r.size(2, 1));
+
+    Ext_data<Block0> ext_r(const_cast<Block0&>(r));
+    Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+    Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+
+    // CML does not support a scaling parameter, so it is built into the
+    // wrapper function.
+    cml::outer( alpha, 
+                ext_a.data(), ext_a.stride(0),
+                ext_b.data(), ext_b.stride(0),
+                ext_r.data(), ext_r.stride(0),
+                a.size(1, 0), b.size(1, 0) );
+  }
+};
+
+
+template <typename T1,
+          typename Block0,
+          typename Block1,
+          typename Block2>
+struct Evaluator<Op_prod_vv_outer, Block0,
+		 Op_list_3<std::complex<T1>, Block1 const&, Block2 const&>,
+                 Cml_tag>
+{
+  typedef typename Block_layout<Block0>::order_type order0_type;
+
+  static bool const ct_valid = 
+    // check that CML supports this data type and/or layout
+    impl::cml::Cml_supports_block<Block0>::valid &&
+    impl::cml::Cml_supports_block<Block1>::valid &&
+    impl::cml::Cml_supports_block<Block2>::valid &&
+    // check that the output is row-major 
+    Type_equal<order0_type, row2_type>::value &&
+    // check that all data types are equal
+    Type_equal<std::complex<T1>, typename Block0::value_type>::value &&
+    Type_equal<std::complex<T1>, typename Block1::value_type>::value &&
+    Type_equal<std::complex<T1>, typename Block2::value_type>::value &&
+    // check that the complex layouts are equal
+    Is_split_block<Block0>::value == Is_split_block<Block1>::value &&
+    Is_split_block<Block0>::value == Is_split_block<Block2>::value &&
+    // check that direct access is supported
+    Ext_data_cost<Block0>::value == 0 &&
+    Ext_data_cost<Block1>::value == 0 &&
+    Ext_data_cost<Block2>::value == 0;
+
+  static bool rt_valid(Block0& r, std::complex<T1>, Block1 const& a, Block2 const& b)
+  {
+    Ext_data<Block0> ext_r(const_cast<Block0&>(r));
+    Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+    Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+
+    bool unit_stride =
+      (ext_r.stride(1) == 1) &&
+      (ext_a.stride(0) == 1) && 
+      (ext_b.stride(0) == 1);
+
+    return unit_stride;
+  }
+
+  static void exec(Block0& r, std::complex<T1> alpha, Block1 const& a, Block2 const& b)
+  {
+    assert(a.size(1, 0) == r.size(2, 0));
+    assert(b.size(1, 0) == r.size(2, 1));
+
+    Ext_data<Block0> ext_r(const_cast<Block0&>(r));
+    Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+    Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+
+    // CML does not support a scaling parameter, so it is built into the
+    // wrapper function.
+    cml::outer( alpha, 
+                ext_a.data(), ext_a.stride(0),
+                ext_b.data(), ext_b.stride(0),
+                ext_r.data(), ext_r.stride(0),
+                a.size(1, 0), b.size(1, 0) );
+  }
+};
+
+
+
 /// CML evaluator for matrix-vector products
 
 template <typename Block0,
Index: src/vsip/opt/cbe/cml/prod.hpp
===================================================================
--- src/vsip/opt/cbe/cml/prod.hpp	(revision 209886)
+++ src/vsip/opt/cbe/cml/prod.hpp	(working copy)
@@ -43,8 +43,131 @@
 namespace cml
 {
 
+
 // This macro supports scalar and interleaved complex types
 
+#define VSIP_IMPL_CML_VDOT(T, FCN, CML_FCN)     \
+  inline void                                   \
+  FCN(                                          \
+    T *a, int lda,                              \
+    T *b, int ldb,                              \
+    T *z,                                       \
+    int n)                                      \
+  {                                             \
+    typedef Scalar_of<T>::type CML_T;           \
+    CML_FCN(                                    \
+      reinterpret_cast<CML_T*>(a),              \
+      static_cast<ptrdiff_t>(lda),              \
+      reinterpret_cast<CML_T*>(b),              \
+      static_cast<ptrdiff_t>(ldb),              \
+      reinterpret_cast<CML_T*>(z),              \
+      static_cast<size_t>(n) );                 \
+  }
+
+VSIP_IMPL_CML_VDOT(float,               dot,  cml_vdot_f)
+VSIP_IMPL_CML_VDOT(std::complex<float>, dot,  cml_cvdot_f)
+VSIP_IMPL_CML_VDOT(std::complex<float>, dotc, cml_cvdotj_f)
+#undef VSIP_IMPL_CML_VDOT
+
+// This version is for split complex only.
+
+#define VSIP_IMPL_CML_ZVDOT(T, FCN, CML_FCN)    \
+  inline void                                   \
+  FCN(                                          \
+    std::pair<T*, T*> a, int lda,               \
+    std::pair<T*, T*> b, int ldb,               \
+    std::complex<T>*  z,                        \
+    int n)                                      \
+  {                                             \
+    T z_real, z_imag;                           \
+    CML_FCN(                                    \
+      a.first, a.second,                        \
+      static_cast<ptrdiff_t>(lda),              \
+      b.first, b.second,                        \
+      static_cast<ptrdiff_t>(ldb),              \
+      &z_real, &z_imag,                         \
+      static_cast<size_t>(n) );                 \
+    *z = std::complex<T>(z_real, z_imag);       \
+  }
+
+VSIP_IMPL_CML_ZVDOT(float, dot,  cml_zvdot_f)
+VSIP_IMPL_CML_ZVDOT(float, dotc, cml_zvdotj_f)
+#undef VSIP_IMPL_CML_ZVDOT
+
+
+// This macro supports scalar and interleaved complex types
+
+#define VSIP_IMPL_CML_VOUTER(T, FCN, CML_FCN)   \
+  inline void                                   \
+  FCN(                                          \
+    T  alpha,                                   \
+    T* a, int lda,                              \
+    T* b, int ldb,                              \
+    T* z, int ldz,                              \
+    int m,                                      \
+    int n)                                      \
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
+    T* pz = z;                                  \
+    for (int i = 0; i < m; ++i)                 \
+      for (int j = 0; j < n; ++j)               \
+        pz[i*ldz + j] *= alpha;                 \
+  }
+
+VSIP_IMPL_CML_VOUTER(float,               outer,  cml_vouter_f)
+VSIP_IMPL_CML_VOUTER(std::complex<float>, outer,  cml_cvouter_f)
+#undef VSIP_IMPL_CML_VOUTER
+
+// This version is for split complex only.
+
+#define VSIP_IMPL_CML_ZVOUTER(T, FCN, CML_FCN)  \
+  inline void                                   \
+  FCN(                                          \
+    std::complex<T>   alpha,                    \
+    std::pair<T*, T*> a, int lda,               \
+    std::pair<T*, T*> b, int ldb,               \
+    std::pair<T*, T*> z, int ldz,               \
+    int m,                                      \
+    int n)                                      \
+  {                                             \
+    CML_FCN(                                    \
+      a.first, a.second,                        \
+      static_cast<ptrdiff_t>(lda),              \
+      b.first, b.second,                        \
+      static_cast<ptrdiff_t>(ldb),              \
+      z.first, z.second,                        \
+      static_cast<ptrdiff_t>(ldz),              \
+      static_cast<size_t>(m),                   \
+      static_cast<size_t>(n) );                 \
+    T* zr = z.first;                            \
+    T* zi = z.second;                           \
+    for (int i = 0; i < m; ++i)                 \
+      for (int j = 0; j < n; ++j)               \
+      {                                         \
+        T real = alpha.real() * zr[i*ldz + j]   \
+               - alpha.imag() * zi[i*ldz + j];  \
+        T imag = alpha.real() * zi[i*ldz + j]   \
+               + alpha.imag() * zr[i*ldz + j];  \
+        zr[i*ldz + j] = real;                   \
+        zi[i*ldz + j] = imag;                   \
+      }                                         \
+  }
+
+VSIP_IMPL_CML_ZVOUTER(float, outer, cml_zvouter_f)
+#undef VSIP_IMPL_CML_ZVOUTER
+
+
+// This macro supports scalar and interleaved complex types
+
 #define VSIP_IMPL_CML_MVPROD(T, FCN, CML_FCN)   \
   inline void                                   \
   FCN(                                          \
