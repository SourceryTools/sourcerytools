Index: ExpressionTest.cpp
===================================================================
RCS file: /home/pooma/Repository/r2/src/Field/tests/ExpressionTest.cpp,v
retrieving revision 1.2
diff -u -u -r1.2 ExpressionTest.cpp
--- ExpressionTest.cpp	25 Dec 2003 11:26:04 -0000	1.2
+++ ExpressionTest.cpp	19 Jul 2004 15:42:57 -0000
@@ -222,11 +222,26 @@
   tester.check(checkTest(tester, test, a2, a4));
 }
 
-class TwoPt
+template <int Dim>
+struct TwoPt
 {
-public:
+  typedef double OutputElement_t;
   TwoPt() { }
-  TwoPt(const TwoPt &) { }
+  TwoPt(const TwoPt &m) : inputCentering_m(m.inputCentering_m) { }
+  template <class FE>
+  TwoPt(const FE& fe)
+  {
+    inputCentering_m = fe.centering();
+  }
+
+  Centering<Dim> outputCentering() const
+  {
+    return inputCentering_m;
+  }
+  Centering<Dim> inputCentering() const
+  {
+    return inputCentering_m;
+  }
 
   template <class A>
   inline
@@ -239,9 +254,17 @@
   inline int lowerExtent(int) const { return 1; }
   inline int upperExtent(int) const { return 0; }
 
-private:
+  Centering<Dim> inputCentering_m;
 };
 
+template <class M, class T, class E, class Dom>
+typename FieldStencilSimple<TwoPt<M::dimensions>, typename View1<Field<M,T,E>, Dom>::Type_t >::Type_t
+twoPt(const Field<M,T,E>& expr, const Dom &domain)
+{
+  typedef FieldStencilSimple<TwoPt<M::dimensions>, typename View1<Field<M,T,E>, Dom>::Type_t > Ret_t;
+  return Ret_t::make(TwoPt<M::dimensions>(expr), expr(domain));
+}
+
 template<class A1,class A2,class A3,class A4, class AInit>
 void test3(Pooma::Tester& tester, int test,
 	   const A1 &a1, const A2 &a2, const A3 &a3, const A4 &a4,
@@ -255,8 +278,6 @@
   int to = I.last();
   int i;
 
-  Stencil<TwoPt> twoPt;
-
   a1 = initial;
   a2 = initial;
   a3 = initial;
@@ -289,8 +310,6 @@
   int to = I.last();
   int i;
 
-  Stencil<TwoPt> twoPt;
-
   a1 = initial;
   a2 = initial;
   a3 = initial;
@@ -421,8 +440,8 @@
   //  test2(tester, 2, a1, a2, a3, a4, initial, cellInterior);
 
   // Need to replace the stencil code above with Field Stencil code.
-  //  test3(tester, 3, a1, a2, a3, a4, initial, cellInterior);
-  //  test4(tester, 4, a1, a2, a3, a4, initial, cellInterior);
+  test3(tester, 3, a1, a2, a3, a4, initial, cellInterior);
+  //test4(tester, 4, a1, a2, a3, a4, initial, cellInterior);
 
   typedef 
     Field<UniformRectilinearMesh<1>, double, MultiPatch<UniformTag,
@@ -444,8 +463,8 @@
 
   test1(tester, 1, ca1, ca2, ca3, ca4, cinit, cellInterior);
   //  test2(tester, 2, ca1, ca2, ca3, ca4, cinit, cellInterior);
-  //  test3(tester, 3, ca1, ca2, ca3, ca4, cinit, cellInterior);
-  //  test4(tester, 4, ca1, ca2, ca3, ca4, cinit, cellInterior);
+  test3(tester, 3, ca1, ca2, ca3, ca4, cinit, cellInterior);
+  //test4(tester, 4, ca1, ca2, ca3, ca4, cinit, cellInterior);
 
 
   int ret = tester.results("ExpressionTest");
