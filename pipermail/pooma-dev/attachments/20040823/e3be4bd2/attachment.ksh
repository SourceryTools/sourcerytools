Index: ExpressionTest.cpp
===================================================================
RCS file: /home/pooma/Repository/r2/src/Field/tests/ExpressionTest.cpp,v
retrieving revision 1.3
diff -u -u -r1.3 ExpressionTest.cpp
--- ExpressionTest.cpp	19 Jul 2004 18:20:41 -0000	1.3
+++ ExpressionTest.cpp	23 Aug 2004 19:18:50 -0000
@@ -257,12 +257,12 @@
   Centering<Dim> inputCentering_m;
 };
 
-template <class M, class T, class E, class Dom>
-typename FieldStencilSimple<TwoPt<M::dimensions>, typename View1<Field<M,T,E>, Dom>::Type_t >::Type_t
-twoPt(const Field<M,T,E>& expr, const Dom &domain)
+template <class F>
+typename FieldStencilSimple<TwoPt<F::dimensions>, F>::Type_t
+twoPt(const F& expr)
 {
-  typedef FieldStencilSimple<TwoPt<M::dimensions>, typename View1<Field<M,T,E>, Dom>::Type_t > Ret_t;
-  return Ret_t::make(TwoPt<M::dimensions>(expr), expr(domain));
+  typedef FieldStencilSimple<TwoPt<F::dimensions>, F> Ret_t;
+  return Ret_t::make(TwoPt<F::dimensions>(expr), expr);
 }
 
 template<class A1,class A2,class A3,class A4, class AInit>
@@ -290,7 +290,7 @@
     a2(i) = initial(i) + a1(i-1) + a1(i);
   }
 
-  a4(I) = initial(I) + twoPt(a3, I);
+  a4(I) = initial(I) + twoPt(a3)(I);
 
   Pooma::blockAndEvaluate();
 
@@ -322,7 +322,7 @@
     a2(i) = initial(i) + 1.0 + a1(i-1) + 1.0 + a1(i);
   }
 
-  a4(I) = initial(I) + twoPt(1.0 + a3, I);
+  a4(I) = initial(I) + twoPt(1.0 + a3)(I);
 
   Pooma::blockAndEvaluate();
 
@@ -464,7 +464,7 @@
   test1(tester, 1, ca1, ca2, ca3, ca4, cinit, cellInterior);
   //  test2(tester, 2, ca1, ca2, ca3, ca4, cinit, cellInterior);
   test3(tester, 3, ca1, ca2, ca3, ca4, cinit, cellInterior);
-  //test4(tester, 4, ca1, ca2, ca3, ca4, cinit, cellInterior);
+  //  test4(tester, 4, ca1, ca2, ca3, ca4, cinit, cellInterior);
 
 
   int ret = tester.results("ExpressionTest");
