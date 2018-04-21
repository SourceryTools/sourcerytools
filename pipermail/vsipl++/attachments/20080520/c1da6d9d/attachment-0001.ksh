Index: src/vsip/core/matvec_prod.hpp
===================================================================
--- src/vsip/core/matvec_prod.hpp	(revision 208077)
+++ src/vsip/core/matvec_prod.hpp	(working copy)
@@ -446,7 +446,7 @@
 {
   typedef typename Promotion<T0, T1>::type return_type;
 
-  Matrix<return_type> r(m0.size(0), m1.size(1));
+  Matrix<return_type> r(m0.size(0), m1.size(0));
 
   impl::generic_prod(m0, trans(m1), r);
 
Index: src/vsip/opt/cbe/ppu/alf.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/alf.hpp	(revision 208077)
+++ src/vsip/opt/cbe/ppu/alf.hpp	(working copy)
@@ -19,10 +19,7 @@
 # error "vsip/opt files cannot be used as part of the reference impl."
 #endif
 
-#ifdef VSIP_IMPL_HAVE_CML
 #include <cml/ppu/cml.h>
-#endif
-
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/support.hpp>
 #include "alf.h"
@@ -149,7 +146,6 @@
   ALF(unsigned int num_accelerators)
     : num_accelerators_(0)
   {
-#ifdef VSIP_IMPL_HAVE_CML
     int   argc = 3;
     char* argv[3];
     char  number[256];
@@ -160,20 +156,10 @@
     cml_init_argv(&argc, argv);
     alf_ = cml_impl_alf_handle();
     num_accelerators_ = cml_impl_alf_num_spes();
-#else
-    int status = alf_init(0, &alf_);
-    assert(status >= 0);
-
-    set_num_accelerators(num_accelerators);
-#endif
   }
   ~ALF()
   {
-#ifdef VSIP_IMPL_HAVE_CML
     cml_fini();
-#else
-    alf_exit(&alf_, ALF_EXIT_POLICY_WAIT, -1);
-#endif
   }
   void set_num_accelerators(unsigned int n)
   {
Index: src/vsip/opt/cbe/cml/matvec.hpp
===================================================================
--- src/vsip/opt/cbe/cml/matvec.hpp	(revision 208077)
+++ src/vsip/opt/cbe/cml/matvec.hpp	(working copy)
@@ -61,10 +61,9 @@
     // check that the complex layouts are equal
     Is_split_block<Block0>::value == Is_split_block<Block1>::value &&
     Is_split_block<Block0>::value == Is_split_block<Block2>::value &&
-    // check that the layout is row-major
+    // check that the layout is row-major for the first input and the output
     Type_equal<order0_type, row2_type>::value && 
     Type_equal<order1_type, row2_type>::value && 
-    Type_equal<order2_type, row2_type>::value && 
     // check that direct access is supported
     Ext_data_cost<Block0>::value == 0 &&
     Ext_data_cost<Block1>::value == 0 &&
@@ -76,28 +75,49 @@
     Ext_data<Block1> ext_a(const_cast<Block1&>(a));
     Ext_data<Block2> ext_b(const_cast<Block2&>(b));
 
+    // For 'b', the dimension with the smallest stride must be one,
+    // which depends on whether it is row- or column-major.
+    bool is_b_row = Type_equal<order2_type, row2_type>::value;
+    stride_type b_stride = is_b_row ? ext_b.stride(1) : ext_b.stride(0);
+
     return
       // ensure the data is unit-stide
       ( ext_r.stride(1) == 1 &&
         ext_a.stride(1) == 1 &&
-        ext_b.stride(1) == 1 );
+        b_stride        == 1 );
   }
 
   static void exec(Block0& r, Block1 const& a, Block2 const& b)
   {
-    typedef typename Block_layout<Block0>::complex_type complex_type;
-
     Ext_data<Block0> ext_r(const_cast<Block0&>(r));
     Ext_data<Block1> ext_a(const_cast<Block1&>(a));
     Ext_data<Block2> ext_b(const_cast<Block2&>(b));
 
-    cml::mprod(
-      ext_a.data(), ext_a.stride(0),
-      ext_b.data(), ext_b.stride(0),
-      ext_r.data(), ext_r.stride(0),
-      a.size(2, 0),   // M
-      a.size(2, 1),   // N
-      b.size(2, 1) ); // P
+    // Either row- or column-major layouts are supported for
+    // the second input by mapping them to the normal product
+    // or transpose product respectively.
+    if (Type_equal<order2_type, row2_type>::value)
+    {
+      cml::mprod(
+        ext_a.data(), ext_a.stride(0),
+        ext_b.data(), ext_b.stride(0),
+        ext_r.data(), ext_r.stride(0),
+        a.size(2, 0),   // M
+        a.size(2, 1),   // N
+        b.size(2, 1) ); // P
+    }
+    else if (Type_equal<order2_type, col2_type>::value)
+    {
+      cml::mprodt(
+        ext_a.data(), ext_a.stride(0),
+        ext_b.data(), ext_b.stride(1),
+        ext_r.data(), ext_r.stride(0),
+        a.size(2, 0),   // M
+        a.size(2, 1),   // N
+        b.size(2, 1) ); // P
+    }
+    else
+      assert(0);
   }
 };
 
Index: src/vsip/opt/cbe/cml/prod.hpp
===================================================================
--- src/vsip/opt/cbe/cml/prod.hpp	(revision 208077)
+++ src/vsip/opt/cbe/cml/prod.hpp	(working copy)
@@ -46,55 +46,58 @@
 
 // This macro supports scalar and interleaved complex types
 
-#define VSIP_IMPL_CML_MPROD(T, FCN)     \
-inline void                             \
-mprod(                                  \
-  T *a, int lda,                        \
-  T *b, int ldb,                        \
-  T *z, int ldz,                        \
-  int m, int n, int p)                  \
-{                                       \
-  typedef Scalar_of<T>::type CML_T;     \
-  FCN(                                  \
-    reinterpret_cast<CML_T*>(a),        \
-    static_cast<ptrdiff_t>(lda),        \
-    reinterpret_cast<CML_T*>(b),        \
-    static_cast<ptrdiff_t>(ldb),        \
-    reinterpret_cast<CML_T*>(z),        \
-    static_cast<ptrdiff_t>(ldz),        \
-    static_cast<size_t>(m),             \
-    static_cast<size_t>(n),             \
-    static_cast<size_t>(p) );           \
-}
+#define VSIP_IMPL_CML_MPROD(T, FCN, CML_FCN)    \
+  inline void                                   \
+  FCN(                                          \
+    T *a, int lda,                              \
+    T *b, int ldb,                              \
+    T *z, int ldz,                              \
+    int m, int n, int p)                        \
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
+      static_cast<size_t>(n),                   \
+      static_cast<size_t>(p) );                 \
+  }
 
-VSIP_IMPL_CML_MPROD(float,                cml_mprod1_f)
-VSIP_IMPL_CML_MPROD(std::complex<float>,  cml_cmprod1_f)
+VSIP_IMPL_CML_MPROD(float,               mprod,  cml_mprod1_f)
+VSIP_IMPL_CML_MPROD(float,               mprodt, cml_mprodt1_f)
+VSIP_IMPL_CML_MPROD(std::complex<float>, mprod,  cml_cmprod1_f)
+VSIP_IMPL_CML_MPROD(std::complex<float>, mprodt, cml_cmprodt1_f)
 #undef VSIP_IMPL_CML_MPROD
 
 
 // This version is for split complex only.
 
-#define VSIP_IMPL_CML_ZMPROD(T, FCN)    \
-inline void                             \
-mprod(                                  \
-  std::pair<T*, T*> a, int lda,         \
-  std::pair<T*, T*> b, int ldb,         \
-  std::pair<T*, T*> z, int ldz,         \
-  int m, int n, int p)                  \
-{                                       \
-  FCN(                                  \
-    a.first, a.second,                  \
-    static_cast<ptrdiff_t>(lda),        \
-    b.first, b.second,                  \
-    static_cast<ptrdiff_t>(ldb),        \
-    z.first, z.second,                  \
-    static_cast<ptrdiff_t>(ldz),        \
-    static_cast<size_t>(m),             \
-    static_cast<size_t>(n),             \
-    static_cast<size_t>(p) );           \
-}
+#define VSIP_IMPL_CML_ZMPROD(T, FCN, CML_FCN)   \
+  inline void                                   \
+  FCN(                                          \
+    std::pair<T*, T*> a, int lda,               \
+    std::pair<T*, T*> b, int ldb,               \
+    std::pair<T*, T*> z, int ldz,               \
+    int m, int n, int p)                        \
+  {                                             \
+    CML_FCN(                                    \
+      a.first, a.second,                        \
+      static_cast<ptrdiff_t>(lda),              \
+      b.first, b.second,                        \
+      static_cast<ptrdiff_t>(ldb),              \
+      z.first, z.second,                        \
+      static_cast<ptrdiff_t>(ldz),              \
+      static_cast<size_t>(m),                   \
+      static_cast<size_t>(n),                   \
+      static_cast<size_t>(p) );                 \
+  }
 
-VSIP_IMPL_CML_ZMPROD(float, cml_zmprod1_f)
+VSIP_IMPL_CML_ZMPROD(float, mprod,  cml_zmprod1_f)
+VSIP_IMPL_CML_ZMPROD(float, mprodt, cml_zmprodt1_f)
 #undef VSIP_IMPL_CML_ZMPROD
 
 
Index: tests/matvec-prod.cpp
===================================================================
--- tests/matvec-prod.cpp	(revision 208077)
+++ tests/matvec-prod.cpp	(working copy)
@@ -557,24 +557,31 @@
 
 
 template <typename T0,
-	  typename T1>
+          typename T1,
+          typename OrderR,
+          typename Order0,
+          typename Order1>
 void
 test_prodt_rand(length_type m, length_type n, length_type k)
 {
   typedef typename Promotion<T0, T1>::type return_type;
   typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
 
-  Matrix<T0> a(m, n);
-  Matrix<T1> b(k, n);
-  Matrix<return_type> res1(m, k);
-  Matrix<return_type> chk(m, k);
+  typedef Dense<2, T0, Order0>          block0_type;
+  typedef Dense<2, T1, Order1>          block1_type;
+  typedef Dense<2, return_type, OrderR> blockR_type;
+
+  Matrix<T0, block0_type> a(m, n);
+  Matrix<T1, block1_type> b(k, n);
+  Matrix<return_type, blockR_type> res1(m, k);
+  Matrix<return_type, blockR_type> chk(m, k);
   Matrix<scalar_type> gauge(m, k);
 
   randm(a);
   randm(b);
 
   // Test matrix-matrix prod for transpose
-  res1   = prod(a, trans(b));
+  res1 = prodt(a, b);
 
   chk   = ref::prod(a, trans(b));
   gauge = ref::prod(mag(a), mag(trans(b)));
@@ -624,8 +631,33 @@
 
 
 template <typename T0,
+	  typename T1,
+	  typename OrderR,
+	  typename Order0,
+	  typename Order1>
+void
+prodt_types_with_order()
+{
+  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 5, 5);
+  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(5, 7, 9);
+  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(9, 5, 7);
+  test_prodt_rand<T0, T1, OrderR, Order0, Order1>(9, 7, 5);
+}
+
+
+template <typename T0,
 	  typename T1>
 void
+prodt_cases_with_order()
+{
+  prodt_types_with_order<T0, T1, row2_type, row2_type, row2_type>();
+  prodt_types_with_order<T0, T1, row2_type, row2_type, col2_type>();
+}
+
+
+template <typename T0,
+	  typename T1>
+void
 prod_cases()
 {
   test_prod_mv<T0, T1>(5, 7);
@@ -633,12 +665,9 @@
 
   test_prod3_rand<T0, T1>();
   test_prod4_rand<T0, T1>();
-  test_prodt_rand<T0, T1>(5, 5, 5);
-  test_prodt_rand<T0, T1>(5, 7, 9);
-  test_prodt_rand<T0, T1>(9, 5, 7);
-  test_prodt_rand<T0, T1>(9, 7, 5);
 
   prod_cases_with_order<T0, T1>();
+  prodt_cases_with_order<T0, T1>();
 }
 
 
@@ -669,7 +698,6 @@
 
 
 
-
 /***********************************************************************
   Main
 ***********************************************************************/
