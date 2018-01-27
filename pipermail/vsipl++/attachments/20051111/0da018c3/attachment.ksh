Index: src/vsip/impl/fns_elementwise.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fns_elementwise.hpp,v
retrieving revision 1.14
diff -u -r1.14 fns_elementwise.hpp
--- src/vsip/impl/fns_elementwise.hpp	3 Oct 2005 12:49:42 -0000	1.14
+++ src/vsip/impl/fns_elementwise.hpp	11 Nov 2005 18:10:41 -0000
@@ -73,8 +73,9 @@
 // is already defined.
 #define VSIP_IMPL_UNARY_OP(op, name)           			          \
 template <typename T>	 				                  \
-typename Dispatch_##name<T>::result_type			          \
-operator op(T t) { return Dispatch_##name<T>::apply(t);}
+typename Dispatch_##name<typename Is_view_type<T>::type>::result_type     \
+operator op(T t)                             \
+{ return Dispatch_##name<T>::apply(t);}
 
 /// Macro to define a binary function on views in terms of
 /// its homologe on scalars.
Index: tests/vector.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/vector.cpp,v
retrieving revision 1.8
diff -u -r1.8 vector.cpp
--- tests/vector.cpp	18 Jun 2005 16:40:45 -0000	1.8
+++ tests/vector.cpp	11 Nov 2005 18:10:42 -0000
@@ -672,4 +672,17 @@
   VSIP_TEST_ELEMENTWISE_VECTOR(4, |=, 2)
   VSIP_TEST_ELEMENTWISE_VECTOR(4, ^=, 3)
   VSIP_TEST_ELEMENTWISE_VECTOR(4, ^=, 2)
+
+  // operator!
+  {
+    Vector<bool> v(1, true);
+    Vector<bool>  w = !v;
+    assert(w.get(0) == false);
+  }
+  // operator~
+  {
+    Vector<int> v(1, 3);
+    Vector<int>  w = ~v;
+    assert(w.get(0) == ~3);
+  }
 }
