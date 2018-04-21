Index: src/vsip/core/general_evaluator.hpp
===================================================================
--- src/vsip/core/general_evaluator.hpp	(revision 208645)
+++ src/vsip/core/general_evaluator.hpp	(working copy)
@@ -27,6 +27,7 @@
 struct Op_prod_vv_dot;    // vector-vector dot-product
 struct Op_prod_vv_outer;  // vector-vector outer-product
 struct Op_prod_mm;        // matrix-matrix product
+struct Op_prod_mm_conj;   // matrix-matrix conjugate product
 struct Op_prod_mv;        // matrix-vector product
 struct Op_prod_vm;        // vector-matrix product
 struct Op_prod_gemp;      // generalized matrix-matrix product
Index: src/vsip/core/matvec_prod.hpp
===================================================================
--- src/vsip/core/matvec_prod.hpp	(revision 208646)
+++ src/vsip/core/matvec_prod.hpp	(working copy)
@@ -106,6 +106,68 @@
 
 
 
+
+// Generic evaluator for matrix-matrix conjugate products.
+
+template <typename Block0,
+	  typename Block1,
+	  typename Block2>
+struct Evaluator<Op_prod_mm_conj, Block0, Op_list_2<Block1, Block2>,
+		 Generic_tag>
+{
+  static bool const ct_valid = true;
+  static bool rt_valid(Block0&, Block1 const&, Block2 const&)
+  { return true; }
+
+  static void exec(Block0& r, Block1 const& a, Block2 const& b)
+  {
+    typedef typename Block0::value_type RT;
+
+    for (index_type i=0; i<r.size(2, 0); ++i)
+      for (index_type j=0; j<r.size(2, 1); ++j)
+      {
+	RT sum = RT();
+	for (index_type k=0; k<a.size(2, 1); ++k)
+	{
+	  sum += a.get(i, k) * conj(b.get(k, j));
+	}
+	r.put(i, j, sum);
+    }
+  }
+};
+
+
+
+/// Matrix-matrix conjugate product.
+
+template <typename T0,
+	  typename T1,
+	  typename T2,
+	  typename Block0,
+	  typename Block1,
+	  typename Block2>
+void
+generic_prodj(
+  const_Matrix<T0, Block0> a,
+  const_Matrix<T1, Block1> b,
+  Matrix<T2, Block2>       r)
+{
+  typedef Op_list_2<Block0, Block1> signature_type;
+
+  assert(r.size(0) == a.size(0));
+  assert(r.size(1) == b.size(1));
+  assert(a.size(1) == b.size(0));
+
+#ifdef VSIP_IMPL_REF_IMPL
+  impl::generic_prod(a, conj(b), r);
+#else
+  General_dispatch<Op_prod_mm_conj, Block2, signature_type>
+    ::exec(r.block(), a.block(), b.block());
+#endif
+}
+
+
+
 // Generic evaluator for matrix-vector products.
 
 template <typename Block0,
@@ -402,9 +464,9 @@
 {
   typedef typename Promotion<complex<T0>, complex<T1> >::type return_type;
 
-  Matrix<return_type> r(m0.size(0), m1.size(1));
+  Matrix<return_type> r(m0.size(0), m1.size(0));
 
-  impl::generic_prod(m0, herm(m1), r);
+  impl::generic_prodj(m0, trans(m1), r);
 
   return r;
 }
@@ -422,12 +484,12 @@
   const_Matrix<complex<T1>, Block1> m1)
     VSIP_NOTHROW
 {
-  typedef typename Promotion<T0, T1>::type return_type;
+  typedef typename Promotion<complex<T0>, complex<T1> >::type return_type;
 
   Matrix<return_type> r(m0.size(0), m1.size(1));
+  
+  impl::generic_prodj(m0, m1, r);
 
-  impl::generic_prod(m0, conj(m1), r);
-
   return r;
 }
 
Index: src/vsip/opt/cbe/cml/matvec.hpp
===================================================================
--- src/vsip/opt/cbe/cml/matvec.hpp	(revision 208646)
+++ src/vsip/opt/cbe/cml/matvec.hpp	(working copy)
@@ -37,7 +37,7 @@
 {
 
 
-// CML evaluator for matrix-matrix products.
+/// CML evaluator for matrix-matrix products.
 
 template <typename Block0,
           typename Block1,
@@ -122,6 +122,91 @@
 };
 
 
+/// CML evaluator for matrix-matrix conjugate products.
+
+template <typename Block0,
+          typename Block1,
+          typename Block2>
+struct Evaluator<Op_prod_mm_conj, Block0, Op_list_2<Block1, Block2>,
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
+    // check that the layout is row-major for the first input and the output
+    Type_equal<order0_type, row2_type>::value && 
+    Type_equal<order1_type, row2_type>::value && 
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
+    // For 'b', the dimension with the smallest stride must be one,
+    // which depends on whether it is row- or column-major.
+    bool is_b_row = Type_equal<order2_type, row2_type>::value;
+    stride_type b_stride = is_b_row ? ext_b.stride(1) : ext_b.stride(0);
+
+    return
+      // ensure the data is unit-stide
+      ( ext_r.stride(1) == 1 &&
+        ext_a.stride(1) == 1 &&
+        b_stride        == 1 );
+  }
+
+  static void exec(Block0& r, Block1 const& a, Block2 const& b)
+  {
+    Ext_data<Block0> ext_r(const_cast<Block0&>(r));
+    Ext_data<Block1> ext_a(const_cast<Block1&>(a));
+    Ext_data<Block2> ext_b(const_cast<Block2&>(b));
+
+    // Either row- or column-major layouts are supported for
+    // the second input by mapping them to the normal product
+    // or transpose product respectively.
+    if (Type_equal<order2_type, row2_type>::value)
+    {
+      cml::mprodj(
+        ext_a.data(), ext_a.stride(0),
+        ext_b.data(), ext_b.stride(0),
+        ext_r.data(), ext_r.stride(0),
+        a.size(2, 0),   // M
+        a.size(2, 1),   // N
+        b.size(2, 1) ); // P
+    }
+    else if (Type_equal<order2_type, col2_type>::value)
+    {
+      cml::mprodh(
+        ext_a.data(), ext_a.stride(0),
+        ext_b.data(), ext_b.stride(1),
+        ext_r.data(), ext_r.stride(0),
+        a.size(2, 0),   // M
+        a.size(2, 1),   // N
+        b.size(2, 1) ); // P
+    }
+    else
+      assert(0);
+  }
+};
+
+
 } // namespace vsip::impl
 
 } // namespace vsip
Index: src/vsip/opt/cbe/cml/prod.hpp
===================================================================
--- src/vsip/opt/cbe/cml/prod.hpp	(revision 208646)
+++ src/vsip/opt/cbe/cml/prod.hpp	(working copy)
@@ -71,6 +71,8 @@
 VSIP_IMPL_CML_MPROD(float,               mprodt, cml_mprodt1_f)
 VSIP_IMPL_CML_MPROD(std::complex<float>, mprod,  cml_cmprod1_f)
 VSIP_IMPL_CML_MPROD(std::complex<float>, mprodt, cml_cmprodt1_f)
+VSIP_IMPL_CML_MPROD(std::complex<float>, mprodj, cml_cmprodj1_f)
+VSIP_IMPL_CML_MPROD(std::complex<float>, mprodh, cml_cmprodh1_f)
 #undef VSIP_IMPL_CML_MPROD
 
 
@@ -98,6 +100,8 @@
 
 VSIP_IMPL_CML_ZMPROD(float, mprod,  cml_zmprod1_f)
 VSIP_IMPL_CML_ZMPROD(float, mprodt, cml_zmprodt1_f)
+VSIP_IMPL_CML_ZMPROD(float, mprodj, cml_zmprodj1_f)
+VSIP_IMPL_CML_ZMPROD(float, mprodh, cml_zmprodh1_f)
 #undef VSIP_IMPL_CML_ZMPROD
 
 
diff -u tests/matvec-prodjh.cpp tests/matvec-prodjh.cpp
--- tests/matvec-prodjh.cpp	(working copy)
+++ tests/matvec-prodjh.cpp	(working copy)
@@ -56,7 +56,7 @@
   randm(b);
 
   // Test matrix-matrix prod for hermitian
-  res1   = prod(a, herm(b));
+  res1   = prodh(a, b);
 
   chk   = ref::prod(a, herm(b));
   gauge = ref::prod(mag(a), mag(herm(b)));
@@ -94,7 +94,7 @@
   randm(b);
 
   // Test matrix-matrix prod for hermitian
-  res1   = prod(a, conj(b));
+  res1   = prodj(a, b);
 
   chk   = ref::prod(a, conj(b));
   gauge = ref::prod(mag(a), mag(conj(b)));
