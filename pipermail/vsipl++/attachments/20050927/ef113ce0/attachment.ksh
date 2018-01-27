Index: src/vsip/dense.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/dense.hpp,v
retrieving revision 1.28
diff -u -r1.28 dense.hpp
--- src/vsip/dense.hpp	16 Sep 2005 21:51:08 -0000	1.28
+++ src/vsip/dense.hpp	27 Sep 2005 12:53:17 -0000
@@ -23,7 +23,6 @@
 #include <vsip/impl/layout.hpp>
 #include <vsip/impl/extdata.hpp>
 #include <vsip/impl/block-traits.hpp>
-#include <vsip/impl/view_traits.hpp>
 #include <vsip/impl/point.hpp>
 
 /// Complex storage format for dense blocks.
Index: src/vsip/matrix.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/matrix.hpp,v
retrieving revision 1.26
diff -u -r1.26 matrix.hpp
--- src/vsip/matrix.hpp	16 Sep 2005 22:03:20 -0000	1.26
+++ src/vsip/matrix.hpp	27 Sep 2005 12:53:17 -0000
@@ -40,11 +40,9 @@
 {
 
 /// View which appears as a two-dimensional, read-only matrix.
-template <typename T = VSIP_DEFAULT_VALUE_TYPE,
-	  typename Block = Dense<2, T> >
-class const_Matrix :
-  public impl::Non_assignable,
-  public  vsip::impl_const_View<vsip::const_Matrix,Block>
+template <typename T, typename Block>
+class const_Matrix : public impl::Non_assignable,
+		     public  vsip::impl_const_View<vsip::const_Matrix,Block>
 {
   typedef vsip::impl_const_View<vsip::const_Matrix,Block> impl_base_type;
   typedef typename impl::Lvalue_factory_type<Block>::type impl_factory_type;
@@ -156,10 +154,8 @@
 /// inherits from const_Matrix, so only the members that const_Matrix
 /// does not carry, or that are different, need be specified.
 
-template <typename T = VSIP_DEFAULT_VALUE_TYPE,
-	  typename Block = Dense<2, T> >
-class Matrix : 
-  public vsip::impl_View<vsip::Matrix,Block>
+template <typename T, typename Block>
+class Matrix : public vsip::impl_View<vsip::Matrix,Block>
 {
   typedef vsip::impl_View<vsip::Matrix,Block> impl_base_type;
   typedef typename impl::Lvalue_factory_type<Block>::type impl_factory_type;
Index: src/vsip/tensor.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/tensor.hpp,v
retrieving revision 1.19
diff -u -r1.19 tensor.hpp
--- src/vsip/tensor.hpp	16 Sep 2005 22:03:20 -0000	1.19
+++ src/vsip/tensor.hpp	27 Sep 2005 12:53:18 -0000
@@ -42,11 +42,9 @@
 enum whole_domain_type { whole_domain};
 
 /// View which appears as a three-dimensional, read-only tensor.
-template <typename T = VSIP_DEFAULT_VALUE_TYPE,
-	  typename Block = Dense<3, T> >
-class const_Tensor :
-  public impl::Non_assignable,
-  public  vsip::impl_const_View<vsip::const_Tensor,Block>
+template <typename T, typename Block>
+class const_Tensor : public impl::Non_assignable,
+		     public  vsip::impl_const_View<vsip::const_Tensor,Block>
 {
   typedef vsip::impl_const_View<vsip::const_Tensor,Block> impl_base_type;
   typedef typename impl::Lvalue_factory_type<Block>::type impl_factory_type;
@@ -263,8 +261,7 @@
 /// inherits from const_Tensor, so only the members that const_Tensor
 /// does not carry, or that are different, need be specified.
 
-template <typename T = VSIP_DEFAULT_VALUE_TYPE,
-	  typename Block = Dense<3, T> >
+template <typename T, typename Block>
 class Tensor : public vsip::impl_View<vsip::Tensor, Block>
 {
   typedef vsip::impl_View<vsip::Tensor, Block> impl_base_type;
Index: src/vsip/vector.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/vector.hpp,v
retrieving revision 1.31
diff -u -r1.31 vector.hpp
--- src/vsip/vector.hpp	26 Sep 2005 20:11:05 -0000	1.31
+++ src/vsip/vector.hpp	27 Sep 2005 12:53:18 -0000
@@ -39,11 +39,9 @@
 {
 
 /// View which appears as a one-dimensional, read-only vector.
-template <typename T = VSIP_DEFAULT_VALUE_TYPE,
-	  typename Block = Dense<1, T> >
-class const_Vector :
-	public impl::Non_assignable,
-	public vsip::impl_const_View<vsip::const_Vector,Block>
+template <typename T, typename Block>
+class const_Vector : public impl::Non_assignable,
+		     public vsip::impl_const_View<vsip::const_Vector,Block>
 {
   typedef vsip::impl_const_View<vsip::const_Vector,Block> impl_base_type;
   typedef typename impl::Lvalue_factory_type<Block>::type impl_factory_type;
@@ -156,8 +154,7 @@
 /// inherits from const_Vector, so only the members that const_Vector
 /// does not carry, or that are different, need be specified.
 
-template <typename T = VSIP_DEFAULT_VALUE_TYPE,
-	  typename Block = Dense<1, T> >
+template <typename T, typename Block>
 class Vector : public vsip::impl_View<vsip::Vector,Block>
 {
   typedef vsip::impl_View<vsip::Vector,Block> impl_base_type;
Index: src/vsip/impl/expr_functor.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_functor.hpp,v
retrieving revision 1.6
diff -u -r1.6 expr_functor.hpp
--- src/vsip/impl/expr_functor.hpp	15 Sep 2005 14:49:25 -0000	1.6
+++ src/vsip/impl/expr_functor.hpp	27 Sep 2005 12:53:18 -0000
@@ -18,6 +18,7 @@
 #include <vsip/impl/expr_unary_block.hpp>
 #include <vsip/impl/expr_binary_block.hpp>
 #include <vsip/impl/expr_ternary_block.hpp>
+#include <vsip/impl/expr_binary_operators.hpp>
 
 namespace vsip
 {
Index: src/vsip/impl/matvec.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/matvec.hpp,v
retrieving revision 1.1
diff -u -r1.1 matvec.hpp
--- src/vsip/impl/matvec.hpp	19 Sep 2005 21:06:46 -0000	1.1
+++ src/vsip/impl/matvec.hpp	27 Sep 2005 12:53:18 -0000
@@ -17,6 +17,8 @@
 
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
+#include <vsip/impl/promote.hpp>
+#include <vsip/impl/fns_elementwise.hpp>
 
 
 namespace vsip
Index: src/vsip/impl/view_traits.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/view_traits.hpp,v
retrieving revision 1.9
diff -u -r1.9 view_traits.hpp
--- src/vsip/impl/view_traits.hpp	28 Aug 2005 00:22:39 -0000	1.9
+++ src/vsip/impl/view_traits.hpp	27 Sep 2005 12:53:18 -0000
@@ -15,6 +15,7 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
+#include <vsip/dense.hpp>
 #include <vsip/impl/subblock.hpp>
 #include <complex>
 
@@ -51,12 +52,18 @@
 
 } // impl
 
-template <typename T, typename B> struct Vector;
-template <typename T, typename B> struct Matrix;
-template <typename T, typename B> struct Tensor;
-template <typename T, typename B> struct const_Vector;
-template <typename T, typename B> struct const_Matrix;
-template <typename T, typename B> struct const_Tensor;
+template <typename T = VSIP_DEFAULT_VALUE_TYPE,
+	  typename B = Dense<1, T> > struct Vector;
+template <typename T = VSIP_DEFAULT_VALUE_TYPE,
+	  typename B = Dense<2, T> > struct Matrix;
+template <typename T = VSIP_DEFAULT_VALUE_TYPE,
+	  typename B = Dense<3, T> > struct Tensor;
+template <typename T = VSIP_DEFAULT_VALUE_TYPE,
+	  typename B = Dense<1, T> > struct const_Vector;
+template <typename T = VSIP_DEFAULT_VALUE_TYPE,
+	  typename B = Dense<2, T> > struct const_Matrix;
+template <typename T = VSIP_DEFAULT_VALUE_TYPE,
+	  typename B = Dense<3, T> > struct const_Tensor;
 
 namespace impl
 {
