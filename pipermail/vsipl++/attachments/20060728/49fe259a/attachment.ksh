Index: src/vsip/impl/simd/expr_iterator.hpp
===================================================================
--- src/vsip/impl/simd/expr_iterator.hpp	(revision 145925)
+++ src/vsip/impl/simd/expr_iterator.hpp	(working copy)
@@ -141,11 +141,11 @@
 };
 
 // Access trait for unary expressions.
-template <typename T,                  // value_type
+template <typename ProxyT,             // operatory proxy
 	  template <typename> class O> // operator
 struct Unary_access_traits
 {
-  typedef T value_type;
+  typedef typename ProxyT::value_type value_type;
 };
 
 // Access trait for binary expressions. Both operands have the same value_type.
@@ -229,15 +229,15 @@
 };
 
 // Proxy for unary expressions.
-template <typename T, template <typename> class O>
-class Proxy<Unary_access_traits<T, O> >
+template <typename ProxyT, template <typename> class O>
+class Proxy<Unary_access_traits<ProxyT, O> >
 {
 public:
-  typedef Unary_access_traits<T, O> access_traits;
+  typedef Unary_access_traits<ProxyT, O> access_traits;
   typedef typename access_traits::value_type value_type;
   typedef typename Simd_traits<value_type>::simd_type simd_type;
 
-  Proxy(Proxy<T> const &o) : op_(o) {}
+  Proxy(ProxyT const &o) : op_(o) {}
 
   simd_type load() const 
   {
@@ -248,7 +248,7 @@
   void increment() { op_.increment();}
 
 private:
-  Proxy<T> op_;
+  ProxyT op_;
 };
 
 // Proxy for binary expressions. The two proxy operands L and R are 
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 145925)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2006-07-28  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/simd/expr_iterator.hpp: Fix template parameter
+	  usage for Unary_access_traits.
+
 2006-07-27  Assem Salama <assem@codesourcery.com>
 
 	* src/vsip_csl/matlab_file.cpp: New file. Implements some functions of
