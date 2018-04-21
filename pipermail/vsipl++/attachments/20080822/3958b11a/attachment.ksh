Index: ChangeLog
===================================================================
--- ChangeLog	(revision 218389)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2008-08-22  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/vmmul.hpp: Use vector/matrix value types when
+	  re-dispatching vmmul in terms of vmul.
+	* tests/vmmul.cpp: Add coverage for float/complex vmmul.
+
 2008-08-22  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* m4/fft.m4: Bail out if fftw backend is enabled but no fftw header
Index: src/vsip/core/vmmul.hpp
===================================================================
--- src/vsip/core/vmmul.hpp	(revision 218389)
+++ src/vsip/core/vmmul.hpp	(working copy)
@@ -91,9 +91,9 @@
 
     typedef typename Block_layout<DstBlock>::order_type order_type;
 
-    Matrix<dst_type, DstBlock> m_dst(dst);
-    const_Vector<dst_type, VBlock>  v(const_cast<VBlock&>(vblock));
-    const_Matrix<dst_type, MBlock>  m(const_cast<MBlock&>(mblock));
+    Matrix<dst_type, DstBlock>   m_dst(dst);
+    const_Vector<v_type, VBlock> v(const_cast<VBlock&>(vblock));
+    const_Matrix<m_type, MBlock> m(const_cast<MBlock&>(mblock));
 
     if (Type_equal<order_type, row2_type>::value)
     {
Index: tests/vmmul.cpp
===================================================================
--- tests/vmmul.cpp	(revision 218389)
+++ tests/vmmul.cpp	(working copy)
@@ -43,41 +43,44 @@
 
 template <dimension_type Dim,
 	  typename       OrderT,
-	  typename       T>
+	  typename       T1,		// Vector value type
+	  typename       T2>		// Matrix value type
 void
 test_vmmul(
   length_type rows,
   length_type cols)
 {
-  Matrix<T, Dense<2, T, OrderT> > m(rows, cols);
-  Vector<T> v(Dim == 0 ? cols : rows);
+  Vector<T1> v(Dim == 0 ? cols : rows);
+  Matrix<T2, Dense<2, T2, OrderT> > m(rows, cols);
 
+  typedef typename Promotion<T1, T2>::type result_type;
+
   for (index_type r=0; r<rows; ++r)
     for (index_type c=0; c<cols; ++c)
-      m(r, c) = T(r*cols+c);
+      m(r, c) = T2(r*cols+c);
 
-  v = test_ramp(T(), T(1), v.size());
+  v = test_ramp(T1(), T1(1), v.size());
 
-  Matrix<T> res1 =  vmmul<Dim>(     v,      m);
-  Matrix<T> res2 =  vmmul<Dim>(T(2)*v,      m);
-  Matrix<T> res3 =  vmmul<Dim>(     v, T(3)*m);
-  Matrix<T> res4 = -vmmul<Dim>(     v,      m);
+  Matrix<result_type> res1 =  vmmul<Dim>(      v,       m);
+  Matrix<result_type> res2 =  vmmul<Dim>(T1(2)*v,       m);
+  Matrix<result_type> res3 =  vmmul<Dim>(      v, T2(3)*m);
+  Matrix<result_type> res4 = -vmmul<Dim>(      v,       m);
 
   for (index_type r=0; r<rows; ++r)
     for (index_type c=0; c<cols; ++c)
       if (Dim == 0)
       {
-	test_assert(equal(res1(r, c),  T(c   * (r*cols+c))));
-	test_assert(equal(res2(r, c),  T(2*c * (r*cols+c))));
-	test_assert(equal(res3(r, c),  T(3*c * (r*cols+c))));
-	test_assert(equal(res4(r, c), -T(c   * (r*cols+c))));
+	test_assert(equal(res1(r, c),  result_type(c   * (r*cols+c))));
+	test_assert(equal(res2(r, c),  result_type(2*c * (r*cols+c))));
+	test_assert(equal(res3(r, c),  result_type(3*c * (r*cols+c))));
+	test_assert(equal(res4(r, c), -result_type(c   * (r*cols+c))));
       }
       else
       {
-	test_assert(equal(res1(r, c),  T(r   * (r*cols+c))));
-	test_assert(equal(res2(r, c),  T(2*r * (r*cols+c))));
-	test_assert(equal(res3(r, c),  T(3*r * (r*cols+c))));
-	test_assert(equal(res4(r, c), -T(r   * (r*cols+c))));
+	test_assert(equal(res1(r, c),  result_type(r   * (r*cols+c))));
+	test_assert(equal(res2(r, c),  result_type(2*r * (r*cols+c))));
+	test_assert(equal(res3(r, c),  result_type(3*r * (r*cols+c))));
+	test_assert(equal(res4(r, c), -result_type(r   * (r*cols+c))));
       }
 }
 
@@ -160,25 +163,26 @@
 }
 
 
-template <typename T>
+template <typename T1,
+	  typename T2>
 void
 vmmul_cases()
 {
-  test_vmmul<0, row2_type, T>(5, 7);
-  test_vmmul<0, col2_type, T>(5, 7);
-  test_vmmul<1, row2_type, T>(5, 7);
-  test_vmmul<1, col2_type, T>(5, 7);
+  test_vmmul<0, row2_type, T1, T2>(5, 7);
+  test_vmmul<0, col2_type, T1, T2>(5, 7);
+  test_vmmul<1, row2_type, T1, T2>(5, 7);
+  test_vmmul<1, col2_type, T1, T2>(5, 7);
 
   // This tests the maximum vector length for the Cell BE dispatch.
-  test_vmmul<0, row2_type, complex<float> >(8, 8192);
+  test_vmmul<0, row2_type, T1, T2>(8, 8192);
 
   // Tests various subviews with well-behaved domains (these should
   // still be dispatched to backends that require unit-stride
   // in the major dimension, but not in the minor.
-  test_subview<T, row2_type, row>(Domain<2>(8, 32));
-  test_subview<T, row2_type, row>(Domain<2>(Domain<1>(0, 2, 4), 32));
-  test_subview<T, col2_type, col>(Domain<2>(32, 8));
-  test_subview<T, col2_type, col>(Domain<2>(32, Domain<1>(0, 2, 4)));
+  test_subview<T1, row2_type, row>(Domain<2>(8, 32));
+  test_subview<T1, row2_type, row>(Domain<2>(Domain<1>(0, 2, 4), 32));
+  test_subview<T1, col2_type, col>(Domain<2>(32, 8));
+  test_subview<T1, col2_type, col>(Domain<2>(32, Domain<1>(0, 2, 4)));
 
   // Tests to ensure alignment is checked by the backend.  These
   // are specifically for cases like Cell BE that cannot handle
@@ -187,10 +191,10 @@
   stride_type gap;
 
   align = 0;  gap = 1;
-  test_subview_unaligned<complex<float>, row2_type, row>(align, gap);
+  test_subview_unaligned<T1, row2_type, row>(align, gap);
 
   align = 1;  gap = 1;
-  test_subview_unaligned<complex<float>, row2_type, row>(align, gap);
+  test_subview_unaligned<T1, row2_type, row>(align, gap);
 }
 
 
@@ -321,8 +325,9 @@
 {
   vsipl init(argc, argv);
 
-  vmmul_cases<float>();
-  vmmul_cases<complex<float> >();
+  vmmul_cases<         float,          float >();
+  vmmul_cases<complex<float>, complex<float> >();
+  vmmul_cases<         float, complex<float> >();
 
   par_vmmul_cases<row2_type, float>();
   par_vmmul_cases<col2_type, float>();
