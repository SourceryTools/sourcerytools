Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.506
diff -u -r1.506 ChangeLog
--- ChangeLog	16 Jun 2006 02:29:12 -0000	1.506
+++ ChangeLog	16 Jun 2006 02:35:30 -0000
@@ -1,5 +1,12 @@
 2006-06-15  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/impl/sal/elementwise.hpp: Fix bug with synthetic
+	  complex scalar-vector multiply.
+	* tests/coverage_binary.cpp: Extend coverage to catch bug.
+	* tests/coverage_common.hpp: Likewise.
+
+2006-06-15  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/impl/domain-utils.hpp (next): Add dimension-order template
 	  parameter.  Add overload so that existing users of next() continue
 	  to work.
Index: src/vsip/impl/sal/elementwise.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/elementwise.hpp,v
retrieving revision 1.1
diff -u -r1.1 elementwise.hpp
--- src/vsip/impl/sal/elementwise.hpp	2 Jun 2006 02:21:51 -0000	1.1
+++ src/vsip/impl/sal/elementwise.hpp	16 Jun 2006 02:35:30 -0000
@@ -1102,8 +1102,10 @@
   if (A.stride == 1 && Z.stride == 1)					\
     SALFCN((T*)A.ptr, A.stride, &real, (T*)Z.ptr, Z.stride, 2*len, 0);	\
   else									\
+  {									\
     SALFCN((T*)A.ptr,   2*A.stride, &real, (T*)Z.ptr,   2*Z.stride, len, 0);\
     SALFCN((T*)A.ptr+1, 2*A.stride, &real, (T*)Z.ptr+1, 2*Z.stride, len, 0);\
+  }									\
 }
 
 #define VSIP_IMPL_CRSV_MUL_SYN(FCN, T, SALFCN)				\
@@ -1121,8 +1123,10 @@
   if (B.stride == 1 && Z.stride == 1)					\
     SALFCN((T*)B.ptr, B.stride, &real, (T*)Z.ptr, Z.stride, 2*len, 0);	\
   else									\
+  {									\
     SALFCN((T*)B.ptr,   2*B.stride, &real, (T*)Z.ptr,   2*Z.stride, len, 0);\
     SALFCN((T*)B.ptr+1, 2*B.stride, &real, (T*)Z.ptr+1, 2*Z.stride, len, 0);\
+  }									\
 }
 
 // complex-real scalar-vector add
Index: tests/coverage_binary.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/coverage_binary.cpp,v
retrieving revision 1.1
diff -u -r1.1 coverage_binary.cpp
--- tests/coverage_binary.cpp	2 Jun 2006 02:21:51 -0000	1.1
+++ tests/coverage_binary.cpp	16 Jun 2006 02:35:30 -0000
@@ -137,6 +137,10 @@
     typedef typename Value_type_of<View2>::type T2;
     typedef typename Value_type_of<View3>::type T3;
   
+    // Initialize result first, in case we're doing an in-place operation.
+    for (index_type i=0; i<get_size(view3); ++i)
+      put_nth(view3, i, T3());
+
     for (index_type i=0; i<get_size(view1); ++i)
       put_nth(view1, i, Get_value<T1>::at(0, i));
     for (index_type i=0; i<get_size(view2); ++i)
Index: tests/coverage_common.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/coverage_common.hpp,v
retrieving revision 1.1
diff -u -r1.1 coverage_common.hpp
--- tests/coverage_common.hpp	2 Jun 2006 02:21:51 -0000	1.1
+++ tests/coverage_common.hpp	16 Jun 2006 02:35:30 -0000
@@ -16,6 +16,7 @@
 #include <vsip/support.hpp>
 #include <vsip/complex.hpp>
 #include <vsip/random.hpp>
+#include <vsip/impl/metaprogramming.hpp>
 
 
 
@@ -183,6 +184,94 @@
 	  typename       Stor1,
 	  typename       Stor2,
 	  typename       Stor3,
+	  vsip::dimension_type Dim>
+void
+do_case3_left_ip_helper(vsip::Domain<Dim> dom, vsip::impl::Bool_type<true>)
+{
+  Stor1 stor1(dom);
+  Stor2 stor2(dom);
+
+  Test_class::exec(stor1.view, stor2.view, stor1.view);
+}
+
+
+template <typename       Test_class,
+	  typename       Stor1,
+	  typename       Stor2,
+	  typename       Stor3,
+	  vsip::dimension_type Dim>
+void
+do_case3_left_ip_helper(vsip::Domain<Dim>, vsip::impl::Bool_type<false>)
+{
+}
+
+
+
+// Test left operand in-place (A op B -> A).
+
+template <typename       Test_class,
+	  typename       Stor1,
+	  typename       Stor2,
+	  typename       Stor3,
+	  vsip::dimension_type Dim>
+void
+do_case3_left_ip(vsip::Domain<Dim> dom)
+{
+  do_case3_left_ip_helper<Test_class, Stor1, Stor2, Stor3, Dim>(
+	dom,
+	vsip::impl::Bool_type<vsip::impl::Type_equal<Stor1, Stor3>::value>());
+}
+
+
+
+template <typename       Test_class,
+	  typename       Stor1,
+	  typename       Stor2,
+	  typename       Stor3,
+	  vsip::dimension_type Dim>
+void
+do_case3_right_ip_helper(vsip::Domain<Dim> dom, vsip::impl::Bool_type<true>)
+{
+  Stor1 stor1(dom);
+  Stor2 stor2(dom);
+
+  Test_class::exec(stor1.view, stor2.view, stor2.view);
+}
+
+
+template <typename       Test_class,
+	  typename       Stor1,
+	  typename       Stor2,
+	  typename       Stor3,
+	  vsip::dimension_type Dim>
+void
+do_case3_right_ip_helper(vsip::Domain<Dim>, vsip::impl::Bool_type<false>)
+{
+}
+
+
+
+// Test right operand in-place (A op B -> A).
+
+template <typename       Test_class,
+	  typename       Stor1,
+	  typename       Stor2,
+	  typename       Stor3,
+	  vsip::dimension_type Dim>
+void
+do_case3_right_ip(vsip::Domain<Dim> dom)
+{
+  do_case3_right_ip_helper<Test_class, Stor1, Stor2, Stor3, Dim>(
+	dom,
+	vsip::impl::Bool_type<vsip::impl::Type_equal<Stor2, Stor3>::value>());
+}
+
+
+
+template <typename       Test_class,
+	  typename       Stor1,
+	  typename       Stor2,
+	  typename       Stor3,
 	  typename       Stor4,
 	  vsip::dimension_type Dim>
 void
@@ -272,6 +361,8 @@
 
 
 
+// Vector 2-operand -> 1 result cases, with specified return type.
+
 template <typename Test_class,
 	  typename T1,
 	  typename T2,
@@ -289,24 +380,37 @@
   typedef Storage<1, T2>            vec2_t;
   typedef Storage<1, T3>            vec3_t;
 
-  typedef Row_vector<T1, row2_type> row1_t;
-  typedef Row_vector<T2, row2_type> row2_t;
-  typedef Row_vector<T3, row2_type> row3_t;
+  typedef Row_vector<T1, col2_type> row1_t;
+  typedef Row_vector<T2, col2_type> row2_t;
+  typedef Row_vector<T3, col2_type> row3_t;
 
   vsip::Domain<1> dom(11);
   
   do_case3<Test_class, vec1_t, vec2_t, vec3_t>(dom);
+  do_case3_left_ip <Test_class, vec1_t, vec2_t, vec3_t>(dom);
+  do_case3_right_ip<Test_class, vec1_t, vec2_t, vec3_t>(dom);
 
   do_case3<Test_class, sca1_t, vec2_t, vec3_t>(dom);
   do_case3<Test_class, vec1_t, sca2_t, vec3_t>(dom);
 
+  do_case3_right_ip<Test_class, sca1_t, vec2_t, vec3_t>(dom);
+  do_case3_left_ip <Test_class, vec1_t, sca2_t, vec3_t>(dom);
+
   do_case3<Test_class, row1_t, vec2_t, vec3_t>(dom);
   do_case3<Test_class, vec1_t, row2_t, vec3_t>(dom);
   do_case3<Test_class, vec1_t, vec2_t, row3_t>(dom);
+
+  do_case3<Test_class, row1_t, sca2_t, vec3_t>(dom);
+  do_case3<Test_class, sca1_t, row2_t, vec3_t>(dom);
+
+  do_case3_right_ip<Test_class, row1_t, sca2_t, vec3_t>(dom);
+  do_case3_left_ip <Test_class, sca1_t, row2_t, vec3_t>(dom);
 }
 
 
 
+// Vector 2-operand -> 1 result cases, with promotion return type.
+
 template <typename Test_class,
 	  typename T1,
 	  typename T2>
