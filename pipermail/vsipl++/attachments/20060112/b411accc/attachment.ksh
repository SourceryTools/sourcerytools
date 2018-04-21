Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.365
diff -u -r1.365 ChangeLog
--- ChangeLog	11 Jan 2006 16:15:59 -0000	1.365
+++ ChangeLog	12 Jan 2006 05:35:49 -0000
@@ -1,5 +1,14 @@
 2006-01-11 Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/dense.hpp (get_local_block): overload for const Dense.
+	* src/vsip/random.hpp: Return matrices with Local_or_global_map.
+	* src/vsip/impl/expr_binary_block.hpp (Distributed_local_block):
+	  Add specialization for non-const expression block.
+	* src/vsip/impl/expr_ternary_block.hpp: Likewise.
+	* src/vsip/impl/expr_unary_block.hpp: Likewise.
+
+2006-01-11 Jules Bergmann  <jules@codesourcery.com>
+
 	* configure.ac: Check if -lblas is necessary for generic lapack.
 	* src/vsip/map.hpp (impl_subblock_from_global_index): New par
 	  support function to convert from global index to subblock.
Index: src/vsip/dense.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/dense.hpp,v
retrieving revision 1.31
diff -u -r1.31 dense.hpp
--- src/vsip/dense.hpp	22 Dec 2005 01:29:25 -0000	1.31
+++ src/vsip/dense.hpp	12 Jan 2006 05:35:49 -0000
@@ -1044,6 +1044,16 @@
   return block;
 }
 
+template <dimension_type Dim,
+	  typename       T,
+	  typename       OrderT>
+Dense<Dim, T, OrderT, Local_map> const&
+get_local_block(
+  Dense<Dim, T, OrderT, Local_map> const& block)
+{
+  return block;
+}
+
 
 
 /// Overload of get_local_block for Dense with distributed map.
Index: src/vsip/random.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/random.hpp,v
retrieving revision 1.3
diff -u -r1.3 random.hpp
--- src/vsip/random.hpp	11 Jan 2006 16:22:44 -0000	1.3
+++ src/vsip/random.hpp	12 Jan 2006 05:35:49 -0000
@@ -357,8 +357,9 @@
 public:
   // View types [random.rand.view types]
   typedef Dense<1, T, row1_type, Local_or_global_map<1> > block1_type;
+  typedef Dense<2, T, row2_type, Local_or_global_map<2> > block2_type;
   typedef const_Vector<T, block1_type> vector_type;
-  typedef const_Matrix<T> matrix_type;
+  typedef const_Matrix<T, block2_type> matrix_type;
   
   // Constructors, copy, assignment, and destructor 
   //   [random.rand.constructors]
@@ -398,7 +399,7 @@
   matrix_type randu(length_type rows, length_type columns) 
       VSIP_NOTHROW
     {
-      Matrix<T> m(rows, columns);
+      Matrix<T, block2_type> m(rows, columns);
       for ( index_type i = 0; i < rows; ++i )
         for ( index_type j = 0; j < columns; ++j )
           m.put( i, j, randu() );
@@ -415,7 +416,7 @@
   matrix_type randn(length_type rows, length_type columns) 
       VSIP_NOTHROW
     {
-      Matrix<T> m(rows, columns);
+      Matrix<T, block2_type> m(rows, columns);
       for ( index_type i = 0; i < rows; ++i )
         for ( index_type j = 0; j < columns; ++j )
           m.put( i, j, randn() );
Index: src/vsip/impl/expr_binary_block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_binary_block.hpp,v
retrieving revision 1.17
diff -u -r1.17 expr_binary_block.hpp
--- src/vsip/impl/expr_binary_block.hpp	2 Nov 2005 18:44:03 -0000	1.17
+++ src/vsip/impl/expr_binary_block.hpp	12 Jan 2006 05:35:49 -0000
@@ -124,9 +124,6 @@
 
 
 
-// NOTE: Distributed_local_block needs to be defined for const
-// Binary_expr_block, not regular Binary_expr_block.
-
 template <dimension_type                      D,
 	  template <typename, typename> class Operator,
 	  typename                            LBlock,
@@ -152,6 +149,26 @@
 	  typename                            LType,
 	  typename                            RBlock,
 	  typename                            RType>
+struct Distributed_local_block<
+  Binary_expr_block<D, Operator, LBlock, LType, RBlock, RType> >
+{
+  typedef Binary_expr_block<D, Operator,
+			    typename Distributed_local_block<LBlock>::type,
+			    LType,
+			    typename Distributed_local_block<RBlock>::type,
+			    RType>
+		type;
+};
+
+
+
+
+template <dimension_type                      D,
+	  template <typename, typename> class Operator,
+	  typename                            LBlock,
+	  typename                            LType,
+	  typename                            RBlock,
+	  typename                            RType>
 Binary_expr_block<D, Operator,
 		  typename Distributed_local_block<LBlock>::type, LType,
 		  typename Distributed_local_block<RBlock>::type, RType>
Index: src/vsip/impl/expr_scalar_block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_scalar_block.hpp,v
retrieving revision 1.11
diff -u -r1.11 expr_scalar_block.hpp
--- src/vsip/impl/expr_scalar_block.hpp	11 Jan 2006 16:22:44 -0000	1.11
+++ src/vsip/impl/expr_scalar_block.hpp	12 Jan 2006 05:35:49 -0000
@@ -114,9 +114,6 @@
 
 
 
-// NOTE: Distributed_local_block needs to be defined for const
-// Scalar_block, not regular Scalar_block.
-
 template <dimension_type D,
 	  typename       Scalar>
 struct Distributed_local_block<Scalar_block<D, Scalar> const>
@@ -124,6 +121,13 @@
   typedef Scalar_block<D, Scalar> const type;
 };
 
+template <dimension_type D,
+	  typename       Scalar>
+struct Distributed_local_block<Scalar_block<D, Scalar> >
+{
+  typedef Scalar_block<D, Scalar> type;
+};
+
 
 
 template <dimension_type D,
Index: src/vsip/impl/expr_ternary_block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_ternary_block.hpp,v
retrieving revision 1.8
diff -u -r1.8 expr_ternary_block.hpp
--- src/vsip/impl/expr_ternary_block.hpp	2 Nov 2005 18:44:03 -0000	1.8
+++ src/vsip/impl/expr_ternary_block.hpp	12 Jan 2006 05:35:49 -0000
@@ -156,6 +156,24 @@
 		type;
 };
 
+template <dimension_type D,
+	  template <typename, typename, typename> class Functor,
+	  typename Block1, typename Type1,
+	  typename Block2, typename Type2,
+	  typename Block3, typename Type3>
+struct Distributed_local_block<
+  Ternary_expr_block<D, Functor,
+		     Block1, Type1,
+		     Block2, Type2,
+		     Block3, Type3> >
+{
+  typedef Ternary_expr_block<D, Functor,
+		typename Distributed_local_block<Block1>::type, Type1,
+		typename Distributed_local_block<Block2>::type, Type2,
+		typename Distributed_local_block<Block3>::type, Type3>
+		type;
+};
+
 
 
 template <dimension_type D,
Index: src/vsip/impl/expr_unary_block.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/expr_unary_block.hpp,v
retrieving revision 1.13
diff -u -r1.13 expr_unary_block.hpp
--- src/vsip/impl/expr_unary_block.hpp	2 Nov 2005 18:44:03 -0000	1.13
+++ src/vsip/impl/expr_unary_block.hpp	12 Jan 2006 05:35:49 -0000
@@ -125,6 +125,19 @@
 		type;
 };
 
+template <dimension_type            Dim,
+	  template <typename> class Op,
+	  typename                  Block,
+	  typename                  Type>
+struct Distributed_local_block<
+  Unary_expr_block<Dim, Op, Block, Type> >
+{
+  typedef Unary_expr_block<Dim, Op,
+			   typename Distributed_local_block<Block>::type,
+			   Type> 
+		type;
+};
+
 
 
 template <dimension_type            Dim,
