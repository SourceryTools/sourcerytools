Index: ChangeLog
===================================================================
--- ChangeLog	(revision 173218)
+++ ChangeLog	(working copy)
@@ -1,3 +1,53 @@
+2007-06-11  Jules Bergmann  <jules@codesourcery.com>
+
+	Optimize Scalar_block handling.
+	* src/vsip/core/expr/scalar_block.hpp (Scalar_block_shared_map):
+	  New class, holds single shared map for scalar blocks.
+	  (Scalar_block): Use Scalar_block_map (instead of
+	  Local_or_global_map).
+ 	  Do not record block size.
+	* src/vsip/core/expr/scalar_block.cpp: New file.  Definition for
+	  shared map.
+	* src/vsip/core/expr/binary_operators.hpp: Update for sizeless
+	  Scalar_blocks.
+	* src/vsip/core/map_fwd.hpp (Scalar_block_map): Forward decl.
+	* src/vsip/opt/fft/workspace.hpp: Update for sizeless Scalar_blocks.
+
+	Optimize binary and tenary functions to avoid ref-count overhead.
+	* src/vsip/core/expr/functor.hpp: Pass view values by const-ref
+	  (to avoid reference counting overhead).  Update for sizeless
+	  Scalar_blocks.
+	* src/vsip/core/fns_elementwise.hpp: Pass view values by const-ref.
+	  (VSIP_IMPL_BINARY_FUNC_USEOP): New macro for functions that can
+	  share a functor with an existing operation, instead of creating
+	  a redundant one (such as mul and op::Mult).
+	* src/vsip/opt/expr/ops_info.hpp: Remove mul_functor op counts.
+	* src/vsip/GNUmakefile.inc.in (src_vsip_cxx_sources): Add
+	  core/expr/*.cpp files.
+	
+	Misc updates.
+	* src/vsip/core/parallel/global_map.hpp (Global_map): Add missing
+	  initializer for member variable
+	* src/vsip/opt/rt_extdata.hpp (is_alias): Make function inline.
+	* src/vsip/opt/simd/eval_generic.hpp: Add Ext_data_cost check to
+	  threshold evaluator.
+	* src/vsip/opt/diag/fft.hpp: Fix Wall warning.
+	* src/vsip/core/check_config.cpp: Include compiler version info.
+	* tests/coverage_common.hpp: Extend coverage to include distributed
+	  maps.
+	* tests/regressions/vmul_sizes.cpp: Fix missing of cout.
+	* tests/regressions/large_vmul.cpp: Likewise.
+	* benchmarks/loop.hpp: Add start/stop marker functions.
+	* benchmarks/main.cpp: Likewise.
+	* benchmarks/vmul.cpp: Split scalar-vector cases into svmul.cpp.
+	  Add mul() cases.
+	* benchmarks/vmul.hpp: Add classes for 'mul()' function cases.
+	* benchmarks/ipp/vmul.cpp: Use VSIPL++ memory allocation.
+	* benchmarks/sal/vmul.cpp: Fix bug in complex svmul cases.
+	* benchmarks/sal/lvgt.cpp: New file, benchmark for SAL lvgtx.
+	* benchmarks/sal/vthresh.cpp: New file, benchmark for SAL vthresx.
+	* scripts/char.db: Add vmul/vthresh cases.
+
 2007-06-05  Jules Bergmann  <jules@codesourcery.com>
 
 	* tests/coverage_ternary.cpp: Delete file, split into ...
Index: scripts/char.db
===================================================================
--- scripts/char.db	(revision 173072)
+++ scripts/char.db	(working copy)
@@ -37,7 +37,7 @@
 
 set: vmul
   pgm:       vmul
-  cases:     1 2 5 102
+  cases:     1 2 5 51 52 102
   fastcases: 1 2
 
 set: vmul_c
@@ -51,7 +51,7 @@
 
 set: sal-vmul
   pgm:   sal/vmul
-  cases: 1 2
+  cases: 1 2 3
   req:   sal
 
 set: sal-svmul
@@ -115,10 +115,14 @@
   pgm: vmagsq
   cases: 1 2
 
-#set: vthresh
-#  pgm: vthresh
-#  cases: 1 2
+set: vthresh
+  pgm: vthresh
+  cases: 1 2 3 11
 
+set: sal-vthresh
+  pgm: sal/vthresh
+  cases: 1 11
+
 set: sal-lvgt
   pgm: sal/lvgt
   cases: 1 2 11 12
Index: src/vsip/core/expr/scalar_block.cpp
===================================================================
--- src/vsip/core/expr/scalar_block.cpp	(revision 0)
+++ src/vsip/core/expr/scalar_block.cpp	(revision 0)
@@ -0,0 +1,37 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/expr/scalar_block.cpp
+    @author  Jules Bergmann
+    @date    2006-11-27
+    @brief   VSIPL++ Library: Scalar block class definitions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/expr/scalar_block.hpp>
+#include <vsip/core/parallel/global_map.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+
+template <> Scalar_block_shared_map<1>::type
+  Scalar_block_shared_map<1>::map = Scalar_block_shared_map<1>::type();
+
+template <> Scalar_block_shared_map<2>::type
+  Scalar_block_shared_map<2>::map = Scalar_block_shared_map<2>::type();
+
+template <> Scalar_block_shared_map<3>::type
+  Scalar_block_shared_map<3>::map = Scalar_block_shared_map<3>::type();
+
+} // namespace vsip::impl
+} // namespace vsip
Index: src/vsip/core/expr/scalar_block.hpp
===================================================================
--- src/vsip/core/expr/scalar_block.hpp	(revision 173215)
+++ src/vsip/core/expr/scalar_block.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/core/expr/scalar_block.hpp
     @author  Stefan Seefeld
@@ -30,6 +30,15 @@
   Declarations
 ***********************************************************************/
 
+template <dimension_type D>
+struct Scalar_block_shared_map
+{
+  // typedef Local_or_global_map<D> type;
+  typedef Scalar_block_map<D> type;
+  static type map;
+};
+
+
 /// An adapter presenting a scalar as a block. This is useful when constructing
 /// Binary_expr_block objects (which expect two block operands) taking a block and
 /// a scalar.
@@ -43,7 +52,7 @@
   typedef Scalar value_type;
   typedef value_type& reference_type;
   typedef value_type const& const_reference_type;
-  typedef Local_or_global_map<D> map_type;
+  typedef typename Scalar_block_shared_map<D>::type map_type;
 
   static dimension_type const dim = D;
 
@@ -51,13 +60,13 @@
 
   void increment_count() const VSIP_NOTHROW {}
   void decrement_count() const VSIP_NOTHROW {}
-  map_type const& map() const VSIP_NOTHROW { return map_;}
+  map_type const& map() const VSIP_NOTHROW
+  { return Scalar_block_shared_map<D>::map; }
 
   Scalar value() const VSIP_NOTHROW {return value_;}
 
 private:
-  Scalar         value_;
-  map_type          map_;
+  Scalar const         value_;
 };
 
 template <dimension_type D, typename Scalar>
@@ -68,17 +77,14 @@
 class Scalar_block<1, Scalar> : public Scalar_block_base<1, Scalar>
 {
 public:
-  Scalar_block(Scalar s, Length<1> const& l)
-    : Scalar_block_base<1, Scalar>(s), size_(l[0]) {}
-  Scalar_block(Scalar s, length_type x) 
-    : Scalar_block_base<1, Scalar>(s), size_(x) {}
-  length_type size() const VSIP_NOTHROW { return size_;}
+  Scalar_block(Scalar s)
+    : Scalar_block_base<1, Scalar>(s) {}
+  length_type size() const VSIP_NOTHROW { return 0; }
   length_type size(dimension_type block_dim, dimension_type d) const VSIP_NOTHROW;
 
   Scalar get(index_type idx) const VSIP_NOTHROW;
 
-private:
-  length_type const size_;
+  // No member data.
 };
 
 /// Scalar_block specialization for 2-dimension.
@@ -86,12 +92,8 @@
 class Scalar_block<2, Scalar> : public Scalar_block_base<2, Scalar>
 {
 public:
-  Scalar_block(Scalar s, Length<2> const& l)
-    : Scalar_block_base<2, Scalar>(s), size0_(l[0]), size1_(l[1]) {}
-  Scalar_block(Scalar s,
-	      length_type x,
-	      length_type y)
-    : Scalar_block_base<2, Scalar>(s), size0_(x), size1_(y) {}
+  Scalar_block(Scalar s)
+    : Scalar_block_base<2, Scalar>(s) {}
 
   length_type size() const VSIP_NOTHROW;
   length_type size(dimension_type block_dim, dimension_type d) const VSIP_NOTHROW;
@@ -99,9 +101,7 @@
   Scalar get(index_type idx) const VSIP_NOTHROW;
   Scalar get(index_type x, index_type y) const VSIP_NOTHROW;
 
-private:
-  length_type const size0_;
-  length_type const size1_;
+  // No member data.
 };
 
 /// Scalar_block specialization for 3-dimension.
@@ -109,14 +109,8 @@
 class Scalar_block<3, Scalar> : public Scalar_block_base<3, Scalar>
 {
 public:
-  Scalar_block(Scalar s, Length<3> const& l)
-    : Scalar_block_base<3, Scalar>(s),
-      size0_(l[0]), size1_(l[1]), size2_(l[2]) {}
-  Scalar_block(Scalar s,
-	      length_type x,
-	      length_type y,
-	      length_type z)
-    : Scalar_block_base<3, Scalar>(s), size0_(x), size1_(y), size2_(z) {}
+  Scalar_block(Scalar s)
+    : Scalar_block_base<3, Scalar>(s) {}
 
   length_type size() const VSIP_NOTHROW;
   length_type size(dimension_type block_dim, dimension_type d) const VSIP_NOTHROW;
@@ -124,10 +118,7 @@
   Scalar get(index_type idx) const VSIP_NOTHROW;
   Scalar get(index_type x, index_type y, index_type z) const VSIP_NOTHROW;
 
-private:
-  length_type const size0_;
-  length_type const size1_;
-  length_type const size2_;
+  // No member data.
 };
 
 
@@ -284,14 +275,13 @@
 {
   assert(block_dim == 1);
   assert(d == 0);
-  return size_;
+  return 0;
 }
 
 template <typename Scalar>
 inline Scalar 
-Scalar_block<1, Scalar>::get(index_type idx) const VSIP_NOTHROW
+Scalar_block<1, Scalar>::get(index_type) const VSIP_NOTHROW
 {
-  assert(idx < size_);
   return this->value();
 }
 
@@ -299,7 +289,7 @@
 inline length_type
 Scalar_block<2, Scalar>::size() const VSIP_NOTHROW
 {
-  return size0_ * size1_;
+  return 0;
 }
 
 template <typename Scalar>
@@ -308,8 +298,7 @@
   VSIP_NOTHROW
 {
   assert((block_dim == 1 || block_dim == 2) && d < block_dim);
-  if (block_dim == 1) return size();
-  else return d == 0 ? size0_ : size1_;
+  return 0;
 }
 
 template <typename Scalar>
@@ -322,9 +311,8 @@
 
 template <typename Scalar>
 inline Scalar 
-Scalar_block<2, Scalar>::get(index_type x, index_type y) const VSIP_NOTHROW
+Scalar_block<2, Scalar>::get(index_type, index_type) const VSIP_NOTHROW
 {
-  assert(x < size0_ && y < size1_);
   return this->value();
 }
 
@@ -334,7 +322,7 @@
 inline length_type
 Scalar_block<3, Scalar>::size() const VSIP_NOTHROW
 {
-  return size0_ * size1_ * size2_;
+  return 0;
 }
 
 template <typename Scalar>
@@ -345,10 +333,7 @@
   VSIP_NOTHROW
 {
   assert((block_dim == 1 || block_dim == 3) && d < block_dim);
-  if (block_dim == 1) return size();
-  else return d == 0 ? size0_ :
-              d == 1 ? size1_ :
-                       size2_;
+  return 0;
 }
 
 template <typename Scalar>
@@ -361,10 +346,9 @@
 
 template <typename Scalar>
 inline Scalar
-Scalar_block<3, Scalar>::get(index_type x, index_type y, index_type z)
+Scalar_block<3, Scalar>::get(index_type, index_type, index_type)
   const VSIP_NOTHROW
 {
-  assert(x < size0_ && y < size1_ && z < size2_);
   return this->value();
 }
 
Index: src/vsip/core/expr/functor.hpp
===================================================================
--- src/vsip/core/expr/functor.hpp	(revision 173215)
+++ src/vsip/core/expr/functor.hpp	(working copy)
@@ -143,8 +143,8 @@
   typedef typename type_trait::block_type block_type;
   typedef typename type_trait::view_type view_type;
 
-  static view_type create(View1<Type1, Block1> view1,
-			  View2<Type2, Block2> view2)
+  static view_type create(View1<Type1, Block1> const& view1,
+			  View2<Type2, Block2> const& view2)
   {
     return view_type(block_type(view1.block(), view2.block()));
   }
@@ -167,9 +167,9 @@
   typedef typename type_trait::block_type block_type;
   typedef typename type_trait::view_type view_type;
 
-  static view_type create(View<Type, Block> view, S scalar)
+  static view_type create(View<Type, Block> const& view, S scalar)
   {
-    scalar_block_type sblock(scalar, impl::extent<dim>(view.block()));
+    scalar_block_type sblock(scalar);
     return view_type(block_type(view.block(), sblock));
   }
 };
@@ -191,9 +191,9 @@
   typedef typename type_trait::block_type block_type;
   typedef typename type_trait::view_type view_type;
 
-  static view_type create(S scalar, View<Type, Block> view)
+  static view_type create(S scalar, View<Type, Block> const& view)
   {
-    scalar_block_type sblock(scalar, impl::extent<dim>(view.block()));
+    scalar_block_type sblock(scalar);
     return view_type(block_type(sblock, view.block()));
   }
 };
@@ -222,9 +222,9 @@
   typedef typename type_trait::block_type block_type;
   typedef typename type_trait::view_type view_type;
 
-  static view_type create(View1<Type1, Block1> view1,
-			  View2<Type2, Block2> view2,
-			  View3<Type3, Block3> view3)
+  static view_type create(View1<Type1, Block1> const& view1,
+			  View2<Type2, Block2> const& view2,
+			  View3<Type3, Block3> const& view3)
   {
     return view_type(block_type(view1.block(),
 				view2.block(),
@@ -253,11 +253,11 @@
   typedef typename type_trait::block_type block_type;
   typedef typename type_trait::view_type view_type;
 
-  static view_type create(View1<Type1, Block1> view1,
-			  View2<Type2, Block2> view2,
+  static view_type create(View1<Type1, Block1> const& view1,
+			  View2<Type2, Block2> const& view2,
 			  S scalar)
   {
-    scalar_block_type sblock(scalar, impl::extent<dim>(view1.block()));
+    scalar_block_type sblock(scalar);
     return view_type(block_type(view1.block(),
 				view2.block(),
 				sblock));
@@ -285,11 +285,11 @@
   typedef typename type_trait::block_type block_type;
   typedef typename type_trait::view_type view_type;
 
-  static view_type create(View1<Type1, Block1> view1,
+  static view_type create(View1<Type1, Block1> const& view1,
 			  S scalar,
-			  View2<Type2, Block2> view2)
+			  View2<Type2, Block2> const& view2)
   {
-    scalar_block_type sblock(scalar, impl::extent<dim>(view1.block()));
+    scalar_block_type sblock(scalar);
     return view_type(block_type(view1.block(),
 				sblock,
 				view2.block()));
@@ -318,10 +318,10 @@
   typedef typename type_trait::view_type view_type;
 
   static view_type create(S scalar,
-			  View1<Type1, Block1> view1,
-			  View2<Type2, Block2> view2)
+			  View1<Type1, Block1> const& view1,
+			  View2<Type2, Block2> const& view2)
   {
-    scalar_block_type sblock(scalar, impl::extent<dim>(view1.block()));
+    scalar_block_type sblock(scalar);
     return view_type(block_type(sblock,
 				view1.block(),
 				view2.block()));
@@ -349,12 +349,12 @@
   typedef typename type_trait::block_type block_type;
   typedef typename type_trait::view_type view_type;
 
-  static view_type create(View<Type, Block> view,
+  static view_type create(View<Type, Block> const& view,
 			  S1 scalar1,
 			  S2 scalar2)
   {
-    scalar_block1_type sblock1(scalar1, impl::extent<dim>(view.block()));
-    scalar_block2_type sblock2(scalar2, impl::extent<dim>(view.block()));
+    scalar_block1_type sblock1(scalar1);
+    scalar_block2_type sblock2(scalar2);
     return view_type(block_type(view.block(),
 				sblock1,
 				sblock2));
@@ -383,11 +383,11 @@
   typedef typename type_trait::view_type view_type;
 
   static view_type create(S1 scalar1,
-			  View<Type, Block> view,
+			  View<Type, Block> const& view,
 			  S2 scalar2)
   {
-    scalar_block1_type sblock1(scalar1, impl::extent<dim>(view.block()));
-    scalar_block2_type sblock2(scalar2, impl::extent<dim>(view.block()));
+    scalar_block1_type sblock1(scalar1);
+    scalar_block2_type sblock2(scalar2);
     return view_type(block_type(sblock1,
 				view.block(),
 				sblock2));
@@ -417,10 +417,10 @@
 
   static view_type create(S1 scalar1,
 			  S2 scalar2,
-			  View<Type, Block> view)
+			  View<Type, Block> const& view)
   {
-    scalar_block1_type sblock1(scalar1, impl::extent<dim>(view.block()));
-    scalar_block2_type sblock2(scalar2, impl::extent<dim>(view.block()));
+    scalar_block1_type sblock1(scalar1);
+    scalar_block2_type sblock2(scalar2);
     return view_type(block_type(sblock1,
 				sblock2,
 				view.block()));
@@ -443,7 +443,7 @@
 {
   typedef Binary_func_expr<Func_scalar, T1, T2> expr;
   typedef typename expr::view_type result_type;
-  static result_type apply(T1 value1, T2 value2)
+  static result_type apply(T1 const& value1, T2 const& value2)
   { return expr::create(value1, value2);}
 };
 
@@ -453,7 +453,8 @@
 {
   typedef Ternary_func_expr<Func_scalar, T1, T2, T3> expr;
   typedef typename expr::view_type result_type;
-  static result_type apply(T1 value1, T2 value2, T3 value3)
+  static result_type apply(T1 const& value1, T2 const& value2,
+			   T3 const& value3)
   { return expr::create(value1, value2, value3);}
 };
 
Index: src/vsip/core/expr/binary_operators.hpp
===================================================================
--- src/vsip/core/expr/binary_operators.hpp	(revision 173215)
+++ src/vsip/core/expr/binary_operators.hpp	(working copy)
@@ -111,8 +111,7 @@
   typedef typename type_trait::view_type view_type;
 
   return view_type(block_type(lhs.block(),
-			      scalar_block_type(rhs, 
-					     impl::extent<dim>(lhs.block()))));
+			      scalar_block_type(rhs)));
 }
 
 template <template <typename, typename> class View,
@@ -137,8 +136,7 @@
   typedef Scalar_block<dim, Scalar> scalar_block_type;
   typedef typename type_trait::block_type block_type;
   typedef typename type_trait::view_type view_type;
-  return view_type(block_type(scalar_block_type(lhs, 
-					     impl::extent<dim>(rhs.block())),
+  return view_type(block_type(scalar_block_type(lhs),
 			      rhs.block()));
 }
 
@@ -188,8 +186,7 @@
   typedef typename type_trait::view_type view_type;
 
   return view_type(block_type(lhs.block(),
-			      scalar_block_type(rhs, 
-					     impl::extent<dim>(lhs.block()))));
+			      scalar_block_type(rhs)));
 }
 
 template <template <typename, typename> class View,
@@ -214,8 +211,7 @@
   typedef Scalar_block<dim, Scalar> scalar_block_type;
   typedef typename type_trait::block_type block_type;
   typedef typename type_trait::view_type view_type;
-  return view_type(block_type(scalar_block_type(lhs, 
-					       impl::extent<dim>(rhs.block())),
+  return view_type(block_type(scalar_block_type(lhs),
 			      rhs.block()));
 }
 
@@ -265,8 +261,7 @@
   typedef typename type_trait::view_type view_type;
 
   return view_type(block_type(lhs.block(),
-			      scalar_block_type(rhs, 
-					     impl::extent<dim>(lhs.block()))));
+			      scalar_block_type(rhs)));
 }
 
 template <template <typename, typename> class View,
@@ -291,8 +286,7 @@
   typedef Scalar_block<dim, Scalar> scalar_block_type;
   typedef typename type_trait::block_type block_type;
   typedef typename type_trait::view_type view_type;
-  return view_type(block_type(scalar_block_type(lhs,
-					       impl::extent<dim>(rhs.block())),
+  return view_type(block_type(scalar_block_type(lhs),
 			      rhs.block()));
 }
 
@@ -342,8 +336,7 @@
   typedef typename type_trait::view_type view_type;
 
   return view_type(block_type(lhs.block(),
-			      scalar_block_type(rhs, 
-					     impl::extent<dim>(lhs.block()))));
+			      scalar_block_type(rhs)));
 }
 
 template <template <typename, typename> class View,
@@ -368,8 +361,7 @@
   typedef Scalar_block<dim, Scalar> scalar_block_type;
   typedef typename type_trait::block_type block_type;
   typedef typename type_trait::view_type view_type;
-  return view_type(block_type(scalar_block_type(lhs, 
-					       impl::extent<dim>(rhs.block())),
+  return view_type(block_type(scalar_block_type(lhs),
 			      rhs.block()));
 }
 
Index: src/vsip/core/check_config.cpp
===================================================================
--- src/vsip/core/check_config.cpp	(revision 173215)
+++ src/vsip/core/check_config.cpp	(working copy)
@@ -92,6 +92,21 @@
   cfg << "  _MC_EXEC                        - 0\n";
 #endif
 
+
+  cfg << "Sourcery VSIPL++ Compiler Configuration\n";
+
+#if __GNUC__
+  cfg << "  __GNUC__                        - " << __GNUC__ << "\n";
+#endif
+
+#if __ghs__
+  cfg << "  __ghs__                         - " << __ghs__ << "\n";
+#endif
+
+#if __ICL
+  cfg << "  __ICL                           - " << __ICL << "\n";
+#endif
+
   return cfg.str();
 }
 
Index: src/vsip/core/fns_elementwise.hpp
===================================================================
--- src/vsip/core/fns_elementwise.hpp	(revision 173215)
+++ src/vsip/core/fns_elementwise.hpp	(working copy)
@@ -139,6 +139,15 @@
 {                                                                         \
 };
 
+#define VSIP_IMPL_BINARY_DISPATCH_USEOP(fname, opname)			  \
+template <typename T1, typename T2>                                       \
+struct Dispatch_##fname :                                                 \
+  ITE_Type<Is_view_type<T1>::value || Is_view_type<T2>::value,            \
+           As_type<Binary_func_view<opname, T1, T2> >,			  \
+           As_type<opname<T1, T2> > >::type				  \
+{                                                                         \
+};
+
 // Define a dispatcher that only matches if at least one of the arguments
 // is a view type.
 #define VSIP_IMPL_BINARY_OP_DISPATCH(fname)                               \
@@ -153,27 +162,29 @@
 template <typename T1, typename T2>                                       \
 inline                                                                    \
 typename Dispatch_##fname<T1, T2>::result_type                            \
-fname(T1 t1, T2 t2) { return Dispatch_##fname<T1, T2>::apply(t1, t2);}
+fname(T1 const& t1, T2 const& t2)					  \
+{ return Dispatch_##fname<T1, T2>::apply(t1, t2); }
 
 #define VSIP_IMPL_BINARY_OPERATOR_ONE(op, fname)                          \
 template <typename T1, typename T2>                                       \
 inline                                                                    \
 typename Dispatch_op_##fname<T1, T2>::result_type                         \
-operator op(T1 t1, T2 t2) { return Dispatch_op_##fname<T1, T2>::apply(t1, t2);}
+operator op(T1 const& t1, T2 const& t2)					  \
+{ return Dispatch_op_##fname<T1, T2>::apply(t1, t2);}
 
 #define VSIP_IMPL_BINARY_OPERATOR_TWO(op, fname)                          \
 template <template <typename, typename> class View,                       \
           typename T1, typename Block1, typename T2>                      \
 inline                                                                    \
 typename Dispatch_op_##fname<View<T1, Block1>, T2>::result_type           \
-operator op(View<T1, Block1> t1, T2 t2)                                   \
+operator op(View<T1, Block1> const& t1, T2 t2)				  \
 { return Dispatch_op_##fname<View<T1, Block1>, T2>::apply(t1, t2);}       \
                                                                           \
 template <template <typename, typename> class View,                       \
           typename T1, typename T2, typename Block2>                      \
 inline                                                                    \
 typename Dispatch_op_##fname<T1, View<T2, Block2> >::result_type          \
-operator op(T1 t1, View<T2, Block2> t2)                                   \
+operator op(T1 t1, View<T2, Block2> const& t2)				  \
 { return Dispatch_op_##fname<T1, View<T2, Block2> >::apply(t1, t2);}      \
                                                                           \
 template <template <typename, typename> class LView,                      \
@@ -183,7 +194,7 @@
 inline                                                                    \
 typename Dispatch_op_##fname<LView<T1, Block1>,                           \
                              RView<T2, Block2> >::result_type             \
-operator op(LView<T1, Block1> t1, RView<T2, Block2> t2)                   \
+operator op(LView<T1, Block1> const& t1, RView<T2, Block2> const& t2)	  \
 { return Dispatch_op_##fname<LView<T1, Block1>,                           \
                              RView<T2, Block2> >::apply(t1, t2);}
 
@@ -201,7 +212,7 @@
           typename T, typename B>                                         \
 inline                                                                    \
 typename Dispatch_##fname<V<T,B>, V<T,B> >::result_type                   \
-fname(V<T,B> t1, V<T,B> t2)                                               \
+fname(V<T,B> const& t1, V<T,B> const& t2)				  \
 { return Dispatch_##fname<V<T,B>, V<T,B> >::apply(t1, t2);}
 
 #define VSIP_IMPL_BINARY_FUNC(fname)                                      \
@@ -210,6 +221,13 @@
 VSIP_IMPL_BINARY_FUNCTION(fname)                                          \
 VSIP_IMPL_BINARY_VIEW_FUNCTION(fname)
 
+// Binary function that can use an existing op instead of a functor
+// For example, arithmetic operations like mul() can us op::Mult.
+#define VSIP_IMPL_BINARY_FUNC_USEOP(fname, opname)			  \
+VSIP_IMPL_BINARY_DISPATCH_USEOP(fname, opname) 				  \
+VSIP_IMPL_BINARY_FUNCTION(fname)                                          \
+VSIP_IMPL_BINARY_VIEW_FUNCTION(fname)
+
 #define VSIP_IMPL_BINARY_FUNC_RETN(fname, retn)                           \
 VSIP_IMPL_BINARY_FUNCTOR_RETN(fname, retn)                                \
 VSIP_IMPL_BINARY_DISPATCH(fname)                                          \
@@ -250,8 +268,9 @@
 };                                                                        \
                                                                           \
 template <typename T1, typename T2, typename T3>                          \
+inline									  \
 typename Dispatch_##fname<T1, T2, T3>::result_type                        \
-fname(T1 t1, T2 t2, T3 t3)                                                \
+fname(T1 const& t1, T2 const& t2, T3 const& t3)				  \
 { return Dispatch_##fname<T1, T2, T3>::apply(t1, t2, t3);}
 
 
@@ -408,7 +427,7 @@
 VSIP_IMPL_BINARY_FUNC_RETN(lt, bool)
 VSIP_IMPL_BINARY_FUNC_RETN(lor, bool)
 VSIP_IMPL_BINARY_FUNC_RETN(lxor, bool)
-VSIP_IMPL_BINARY_FUNC(mul)
+VSIP_IMPL_BINARY_FUNC_USEOP(mul, op::Mult)
 VSIP_IMPL_BINARY_FUNC(max)
 VSIP_IMPL_BINARY_FUNC(maxmg)
 VSIP_IMPL_BINARY_FUNC_SCALAR_RETN(maxmgsq)
Index: src/vsip/core/parallel/global_map.hpp
===================================================================
--- src/vsip/core/parallel/global_map.hpp	(revision 173215)
+++ src/vsip/core/parallel/global_map.hpp	(working copy)
@@ -18,6 +18,7 @@
 #include <vsip/core/parallel/services.hpp>
 #include <vsip/core/parallel/map_traits.hpp>
 #include <vsip/core/parallel/support.hpp>
+#include <vsip/core/parallel/scalar_block_map.hpp>
 #include <vsip/core/domain_utils.hpp>
 #include <vsip/core/map_fwd.hpp>
 
@@ -41,6 +42,7 @@
   // Constructor.
 public:
   Global_map()
+    : dom_()
   {}
 
   ~Global_map()
@@ -170,6 +172,8 @@
   Local_or_global_map() {}
 };
 
+
+
 namespace impl
 {
 
Index: src/vsip/core/parallel/scalar_block_map.hpp
===================================================================
--- src/vsip/core/parallel/scalar_block_map.hpp	(revision 0)
+++ src/vsip/core/parallel/scalar_block_map.hpp	(revision 0)
@@ -0,0 +1,178 @@
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/core/parallel/scalar_block_map.hpp
+    @author  Jules Bergmann
+    @date    2006-11-27
+    @brief   VSIPL++ Library: Scalar_block_map class.
+
+*/
+
+#ifndef VSIP_CORE_PARALLEL_SCALAR_BLOCK_MAP_HPP
+#define VSIP_CORE_PARALLEL_SCALAR_BLOCK_MAP_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/vector_iterator.hpp>
+#include <vsip/core/parallel/map_traits.hpp>
+#include <vsip/core/map_fwd.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+/// Scalar_block_map class for Scalar_block.
+
+/// Similar to Local_or_global_map, but with fixed size.
+
+template <dimension_type Dim>
+class Scalar_block_map
+{
+  // Compile-time typedefs.
+public:
+  typedef impl::Vector_iterator<Vector<processor_type> > processor_iterator;
+  typedef impl::Communicator::pvec_type impl_pvec_type;
+
+  // Constructor.
+public:
+  Scalar_block_map() {}
+
+  ~Scalar_block_map() {}
+
+  // Accessors.
+public:
+  // Information on individual distributions.
+  distribution_type distribution     (dimension_type) const VSIP_NOTHROW
+    { return whole; }
+  length_type       num_subblocks    (dimension_type) const VSIP_NOTHROW
+    { return 1; }
+  length_type       cyclic_contiguity(dimension_type) const VSIP_NOTHROW
+    { return 0; }
+
+  length_type num_subblocks()  const VSIP_NOTHROW { return 1; }
+  length_type num_processors() const VSIP_NOTHROW
+    { return vsip::num_processors(); }
+
+  index_type subblock(processor_type /*pr*/) const VSIP_NOTHROW
+    { return 0; }
+  index_type subblock() const VSIP_NOTHROW
+    { return 0; }
+
+  processor_iterator processor_begin(index_type sb) const VSIP_NOTHROW
+  {
+    assert(sb == 0);
+    return processor_iterator(vsip::processor_set(), 0);
+  }
+
+  processor_iterator processor_end  (index_type sb) const VSIP_NOTHROW
+  {
+    assert(sb == 0);
+    return processor_iterator(vsip::processor_set(), vsip::num_processors());
+  }
+
+  const_Vector<processor_type> processor_set() const
+    { return vsip::processor_set(); }
+
+  // Applied map functions.
+public:
+  length_type impl_num_patches(index_type sb) const VSIP_NOTHROW
+    { assert(sb == 0); return 1; }
+
+  void impl_apply(Domain<Dim> const& dom) VSIP_NOTHROW
+    { assert(0); }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_subblock_domain(index_type sb) const VSIP_NOTHROW
+    { assert(sb == 0); return Domain<Dim>(); }
+
+  template <dimension_type Dim2>
+  impl::Length<Dim2> impl_subblock_extent(index_type sb) const VSIP_NOTHROW
+    { assert(sb == 0); return impl::extent(Domain<Dim>()); }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_global_domain(index_type sb, index_type patch)
+    const VSIP_NOTHROW
+    { assert(sb == 0 && patch == 0); return Domain<Dim>(); }
+
+  template <dimension_type Dim2>
+  Domain<Dim2> impl_local_domain (index_type sb, index_type patch)
+    const VSIP_NOTHROW
+    { assert(sb == 0 && patch == 0); return Domain<Dim>(); }
+
+  index_type impl_global_from_local_index(dimension_type /*d*/, index_type sb,
+				     index_type idx)
+    const VSIP_NOTHROW
+  { assert(sb == 0); return idx; }
+
+  index_type impl_local_from_global_index(dimension_type /*d*/, index_type idx)
+    const VSIP_NOTHROW
+  { return idx; }
+
+  template <dimension_type Dim2>
+  index_type impl_subblock_from_global_index(Index<Dim2> const& /*idx*/)
+    const VSIP_NOTHROW
+  { return 0; }
+
+  template <dimension_type Dim2>
+  Domain<Dim> impl_local_from_global_domain(index_type /*sb*/,
+					    Domain<Dim2> const& dom)
+    const VSIP_NOTHROW
+  {
+    VSIP_IMPL_STATIC_ASSERT(Dim == Dim2);
+    return dom;
+  }
+
+  // Extensions.
+public:
+  impl::par_ll_pset_type impl_ll_pset() const VSIP_NOTHROW
+    { return impl::default_communicator().impl_ll_pset(); }
+  impl::Communicator&    impl_comm() const
+    { return impl::default_communicator(); }
+  impl_pvec_type const&  impl_pvec() const
+    { return impl::default_communicator().pvec(); }
+
+  length_type            impl_working_size() const
+    { return this->num_processors(); }
+
+  processor_type         impl_proc_from_rank(index_type idx) const
+    { return this->impl_pvec()[idx]; }
+
+  index_type impl_rank_from_proc(processor_type pr) const
+  {
+    for (index_type i=0; i<this->num_processors(); ++i)
+      if (this->impl_pvec()[i] == pr) return i;
+    return no_rank;
+  }
+
+  // No member data.
+};
+
+
+
+/***********************************************************************
+  Map traits
+***********************************************************************/
+
+template <dimension_type Dim>
+struct Is_local_map<Scalar_block_map<Dim> >
+{ static bool const value = true; };
+
+template <dimension_type Dim>
+struct Is_global_map<Scalar_block_map<Dim> >
+{ static bool const value = true; };
+
+
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_CORE_PARALLEL_SCALAR_BLOCK_MAP_HPP
Index: src/vsip/core/map_fwd.hpp
===================================================================
--- src/vsip/core/map_fwd.hpp	(revision 173215)
+++ src/vsip/core/map_fwd.hpp	(working copy)
@@ -40,6 +40,9 @@
 {
 
 template <dimension_type Dim>
+class Scalar_block_map;
+
+template <dimension_type Dim>
 class Subset_map;
 
 template <dimension_type Dim,
Index: src/vsip/opt/fft/workspace.hpp
===================================================================
--- src/vsip/opt/fft/workspace.hpp	(revision 173215)
+++ src/vsip/opt/fft/workspace.hpp	(working copy)
@@ -42,54 +42,10 @@
 namespace fft
 {
 
-/// Utility for scaling values in a block.
-
 template <dimension_type Dim,
-	  typename       T>
-struct Create_scalar_block;
-
-template <typename       T>
-struct Create_scalar_block<1, T>
-{
-  typedef Scalar_block<1, T> type;
-
-  template <typename BlockT>
-  static type create(T scalar, BlockT const& block)
-  {
-    return type(scalar, block.size(1, 0));
-  }
-};
-
-template <typename       T>
-struct Create_scalar_block<2, T>
-{
-  typedef Scalar_block<2, T> type;
-
-  template <typename BlockT>
-  static type create(T scalar, BlockT const& block)
-  {
-    return type(scalar, block.size(2, 0), block.size(2, 1));
-  }
-};
-
-template <typename       T>
-struct Create_scalar_block<3, T>
-{
-  typedef Scalar_block<3, T> type;
-
-  template <typename BlockT>
-  static type create(T scalar, BlockT const& block)
-  {
-    return type(scalar, block.size(3, 0), block.size(3, 1), block.size(3, 2));
-  }
-};
-
-
-
-template <dimension_type Dim,
 	  typename       T,
 	  typename       BlockT>
-void
+inline void
 scale_block(
   T       scalar,
   BlockT& block)
@@ -101,8 +57,7 @@
 	                scalar_block_type, T>
           expr_block_type;
 
-  scalar_block_type scalar_block(Create_scalar_block<Dim, T>
-				   ::create(scalar, block));
+  scalar_block_type scalar_block(scalar);
   expr_block_type   expr_block(block, scalar_block);
       
   Serial_dispatch<Dim, BlockT, expr_block_type, vsip::impl::LibraryTagList>
Index: src/vsip/opt/rt_extdata.hpp
===================================================================
--- src/vsip/opt/rt_extdata.hpp	(revision 173215)
+++ src/vsip/opt/rt_extdata.hpp	(working copy)
@@ -218,7 +218,7 @@
 
 template <typename Block1T,
 	  typename Block2T>
-bool
+inline bool
 is_alias(
   Block1T const& blk1,
   Block2T const& blk2)
Index: src/vsip/opt/simd/eval_generic.hpp
===================================================================
--- src/vsip/opt/simd/eval_generic.hpp	(revision 173215)
+++ src/vsip/opt/simd/eval_generic.hpp	(working copy)
@@ -652,9 +652,15 @@
   b_lp;
 
   static bool const ct_valid = 
+    // Check that LHS & RHS have same type.
+    Type_equal<typename DstBlock::value_type, T>::value &&
+    // Make sure algorithm/op is supported.
     simd::Is_algorithm_supported<T, false, simd::Alg_threshold>::value &&
-    // make sure op is supported
-   simd::Binary_operator_map<T,O>::is_supported;
+    simd::Binary_operator_map<T,O>::is_supported &&
+    // Check that direct access is supported.
+    Ext_data_cost<DstBlock>::value == 0 &&
+    Ext_data_cost<Block1>::value == 0 &&
+    Ext_data_cost<Block2>::value == 0;
   
   static bool rt_valid(DstBlock& dst, SrcBlock const& src)
   {
Index: src/vsip/opt/diag/fft.hpp
===================================================================
--- src/vsip/opt/diag/fft.hpp	(revision 173215)
+++ src/vsip/opt/diag/fft.hpp	(working copy)
@@ -156,8 +156,8 @@
   static void diag_call(
     std::string                            name,
     FftT const&                            fft,
-    const_Vector<std::complex<T>, Block0>& in,
-    Vector<std::complex<T>, Block1>&       out)
+    const_Vector<std::complex<T>, Block0>& /*in*/,
+    Vector<std::complex<T>, Block1>&       /*out*/)
   {
     using diag_detail::Class_name;
     using std::cout;
Index: src/vsip/opt/expr/ops_info.hpp
===================================================================
--- src/vsip/opt/expr/ops_info.hpp	(revision 173215)
+++ src/vsip/opt/expr/ops_info.hpp	(working copy)
@@ -214,10 +214,6 @@
 VSIP_IMPL_BINARY_OPS_FUNCTOR(lt,      T1,          T2,           1)
 VSIP_IMPL_BINARY_OPS_FUNCTOR(lor,     T1,          T2,           1)
 VSIP_IMPL_BINARY_OPS_FUNCTOR(lxor,    T1,          T2,           1)
-VSIP_IMPL_BINARY_OPS_FUNCTOR(mul,     T1,          T2,           1)
-VSIP_IMPL_BINARY_OPS_FUNCTOR(mul,     T1,          complex<T2>,  2)
-VSIP_IMPL_BINARY_OPS_FUNCTOR(mul,     complex<T1>, T2,           2)
-VSIP_IMPL_BINARY_OPS_FUNCTOR(mul,     complex<T1>, complex<T2>,  6)
 VSIP_IMPL_BINARY_OPS_FUNCTOR(max,     T1,          T2,           1)
 VSIP_IMPL_BINARY_OPS_FUNCTOR(maxmg,   T1,          T2,           1)
 VSIP_IMPL_BINARY_OPS_FUNCTOR(maxmg,   complex<T1>, complex<T2>, 27)
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 173215)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -24,6 +24,7 @@
 endif
 
 ifndef VSIP_IMPL_REF_IMPL
+src_vsip_cxx_sources += $(wildcard $(srcdir)/src/vsip/core/expr/*.cpp)
 src_vsip_cxx_sources += $(wildcard $(srcdir)/src/vsip/opt/*.cpp)
 ifndef VSIP_IMPL_HAVE_NUMA
 src_vsip_cxx_sources := $(filter-out %/numa.cpp, $(src_vsip_cxx_sources))
Index: tests/coverage_common.hpp
===================================================================
--- tests/coverage_common.hpp	(revision 173218)
+++ tests/coverage_common.hpp	(working copy)
@@ -428,6 +428,12 @@
   typedef Storage<1, T1>            vec1_t;
   typedef Storage<1, T2>            vec2_t;
 
+  typedef Storage<1, T1, row1_type, Global_map<1> > gvec1_t;
+  typedef Storage<1, T2, row1_type, Global_map<1> > gvec2_t;
+
+  typedef Storage<1, T1, row1_type, Map<> >         dvec1_t;
+  typedef Storage<1, T2, row1_type, Map<> >         dvec2_t;
+
   typedef Storage<1, T1, row1_type, Local_map, Cmplx_split_fmt> spl1_t;
   typedef Storage<1, T2, row1_type, Local_map, Cmplx_split_fmt> spl2_t;
 
@@ -449,6 +455,16 @@
   do_case2<Test_class, dia1_t, vec2_t>(dom);
   
   do_case2<Test_class, spl1_t, spl2_t>(dom);
+
+  // distributed cases
+  do_case2<Test_class, gvec1_t, gvec2_t>(dom);
+  do_case2<Test_class,  sca1_t, gvec2_t>(dom);
+
+  do_case2<Test_class, dvec1_t, dvec2_t>(dom);
+  do_case2<Test_class,  sca1_t, dvec2_t>(dom);
+
+  do_case2<Test_class, gvec1_t, dvec2_t>(dom);
+  do_case2<Test_class, dvec1_t, gvec2_t>(dom);
 }
 
 
@@ -507,6 +523,14 @@
   typedef Storage<1, T2>            vec2_t;
   typedef Storage<1, T3>            vec3_t;
 
+  typedef Storage<1, T1, row1_type, Global_map<1> > gvec1_t;
+  typedef Storage<1, T2, row1_type, Global_map<1> > gvec2_t;
+  typedef Storage<1, T3, row1_type, Global_map<1> > gvec3_t;
+
+  typedef Storage<1, T1, row1_type, Map<> > dvec1_t;
+  typedef Storage<1, T2, row1_type, Map<> > dvec2_t;
+  typedef Storage<1, T3, row1_type, Map<> > dvec3_t;
+
   typedef Row_vector<T1, col2_type> row1_t;
   typedef Row_vector<T2, col2_type> row2_t;
   typedef Row_vector<T3, col2_type> row3_t;
@@ -514,6 +538,7 @@
   vsip::Domain<1> dom(11);
   
   do_case3<Test_class, vec1_t, vec2_t, vec3_t>(dom);
+
   do_case3_left_ip <Test_class, vec1_t, vec2_t, vec3_t>(dom);
   do_case3_right_ip<Test_class, vec1_t, vec2_t, vec3_t>(dom);
 
@@ -532,6 +557,15 @@
 
   do_case3_right_ip<Test_class, row1_t, sca2_t, vec3_t>(dom);
   do_case3_left_ip <Test_class, sca1_t, row2_t, vec3_t>(dom);
+
+  // distributed cases
+  do_case3<Test_class, gvec1_t, gvec2_t, gvec3_t>(dom);
+  do_case3<Test_class,  sca1_t, gvec2_t, gvec3_t>(dom);
+  do_case3<Test_class, gvec1_t,  sca2_t, gvec3_t>(dom);
+
+  do_case3<Test_class, dvec1_t, dvec2_t, dvec3_t>(dom);
+  do_case3<Test_class,  sca1_t, dvec2_t, dvec3_t>(dom);
+  do_case3<Test_class, dvec1_t,  sca2_t, dvec3_t>(dom);
 }
 
 
Index: tests/regressions/vmul_sizes.cpp
===================================================================
--- tests/regressions/vmul_sizes.cpp	(revision 173072)
+++ tests/regressions/vmul_sizes.cpp	(working copy)
@@ -10,6 +10,12 @@
   Included Files
 ***********************************************************************/
 
+#define VERBOSE 0
+
+#if VERBOSE
+#  include <iostream>
+#endif
+
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
@@ -49,12 +55,14 @@
 
   for (index_type i=0; i<len; ++i)
   {
+#if VERBOSE
     if (!equal(Z.get(i), A.get(i) * B.get(i)))
     {
       std::cout << "Z(" << i << ")        = " << Z(i) << std::endl;
       std::cout << "A(" << i << ") * B(" << i << ") = "
 		<< A(i) * B(i) << std::endl;
     }
+#endif
     test_assert(almost_equal(Z.get(i), A.get(i) * B.get(i)));
   }
 }
Index: tests/regressions/large_vmul.cpp
===================================================================
--- tests/regressions/large_vmul.cpp	(revision 173072)
+++ tests/regressions/large_vmul.cpp	(working copy)
@@ -12,6 +12,12 @@
   Included Files
 ***********************************************************************/
 
+#define VERBOSE 0
+
+#if VERBOSE
+#  include <iostream>
+#endif
+
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/vector.hpp>
@@ -48,11 +54,13 @@
   {
     // Note: almost_equal is necessary for Cbe since SPE and PPE will not
     //       compute idential results.
+#if VERBOSE
     if (!almost_equal(Z(i), A(i) * B(i)))
     {
       std::cout << "Z(i)        = " << Z(i) << std::endl;
       std::cout << "A(i) * B(i) = " << A(i) * B(i) << std::endl;
     }
+#endif
     test_assert(almost_equal(Z(i), A(i) * B(i)));
   }
 }
Index: benchmarks/svmul.cpp
===================================================================
--- benchmarks/svmul.cpp	(revision 0)
+++ benchmarks/svmul.cpp	(revision 0)
@@ -0,0 +1,85 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    benchmarks/svmul.cpp
+    @author  Jules Bergmann
+    @date    2005-07-11
+    @brief   VSIPL++ Library: Benchmark for scalar-vector multiply.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/initfin.hpp>
+
+#include "vmul.hpp"
+
+using namespace vsip;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+void
+defaults(Loop1P&)
+{
+}
+
+
+
+int
+test(Loop1P& loop, int what)
+{
+  length_type footprint = 1 << loop.stop_;
+
+  switch (what)
+  {
+  case   1: loop(t_svmul1<float,          float>()); break;
+  case   2: loop(t_svmul1<float,          complex<float> >()); break;
+  case   3: loop(t_svmul1<complex<float>, complex<float> >()); break;
+
+  case  11: loop(t_svmul_dom<float,          float>()); break;
+  case  12: loop(t_svmul_dom<float,          complex<float> >()); break;
+  case  13: loop(t_svmul_dom<complex<float>, complex<float> >()); break;
+
+  case  21: loop(t_svmul_cc<float, float>(footprint)); break;
+
+/*
+  case  99: loop(t_svmul3<float>()); break;
+
+  // Double-precision
+
+  case 101: loop(t_svmul1<double,          double>()); break;
+  case 102: loop(t_svmul1<double,          complex<double> >()); break;
+  case 103: loop(t_svmul1<complex<double>, complex<double> >()); break;
+*/
+
+  case 0:
+    std::cout
+      << "svmul -- scalar-vector multiplication\n"
+      << "single-precision:\n"
+      << " Scalar-Vector:\n"
+      << "   -1 --                float   * Vector<        float >\n"
+      << "   -2 --                float   * Vector<complex<float>>\n"
+      << "   -3 --        complex<float>  * Vector<complex<float>>\n"
+      << "  -15 -- t_svmul3\n"
+      << "  -15 -- t_svmul4\n"
+      << "\ndouble-precision:\n"
+      << "  (101-113)\n"
+      << "  (131-132)\n"
+      ;
+
+  default:
+    return 0;
+  }
+  return 1;
+}
Index: benchmarks/ipp/vmul.cpp
===================================================================
--- benchmarks/ipp/vmul.cpp	(revision 173215)
+++ benchmarks/ipp/vmul.cpp	(working copy)
@@ -1,10 +1,10 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    benchmarks/vmul_ipp.cpp
+/** @file    benchmarks/ipp/vmul.cpp
     @author  Jules Bergmann
     @date    2005-08-24
     @brief   VSIPL++ Library: Benchmark for IPP vector multiply.
@@ -21,6 +21,7 @@
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
+#include <vsip/random.hpp>
 
 #include <vsip/opt/profile.hpp>
 #include <vsip/core/ops_info.hpp>
@@ -28,10 +29,181 @@
 #include <ipps.h>
 
 #include "loop.hpp"
+#include "benchmarks.hpp"
 
 using namespace vsip;
 
+using impl::Stride_unit_dense;
+using impl::Cmplx_inter_fmt;
+using impl::Cmplx_split_fmt;
 
+
+
+/***********************************************************************
+  IPP Vector Multiply (VSIPL++ memory allocation)
+***********************************************************************/
+
+template <typename T,
+	  typename ComplexFmt = Cmplx_inter_fmt>
+struct t_vmul_ipp_vm;
+
+template <typename ComplexFmt>
+struct t_vmul_ipp_vm<float, ComplexFmt> : Benchmark_base
+{
+  typedef float T;
+
+  char* what() { return "t_vmul_ipp_vm"; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<float>::mul; }
+  int riob_per_point(size_t) { return 2*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 3*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   A(size, T());
+    Vector<T, block_type>   B(size, T());
+    Vector<T, block_type>   C(size);
+
+    A(0) = T(3);
+    B(0) = T(4);
+
+    impl::Ext_data<block_type> ext_a(A.block(), impl::SYNC_IN);
+    impl::Ext_data<block_type> ext_b(B.block(), impl::SYNC_IN);
+    impl::Ext_data<block_type> ext_c(C.block(), impl::SYNC_OUT);
+    
+    T* pA = ext_a.data();
+    T* pB = ext_b.data();
+    T* pC = ext_c.data();
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (size_t l=0; l<loop; ++l)
+      ippsMul_32f(pA, pB, pC, size);
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+template <>
+struct t_vmul_ipp_vm<complex<float>, Cmplx_inter_fmt> : Benchmark_base
+{
+  typedef complex<float> T;
+
+  char* what() { return "t_vmul_ipp_vm complex<float> inter"; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(size_t) { return 2*sizeof(T); }
+  int wiob_per_point(size_t) { return 1*sizeof(T); }
+  int mem_per_point(size_t)  { return 3*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   A(size, T());
+    Vector<T, block_type>   B(size, T());
+    Vector<T, block_type>   C(size);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size); A(0) = T(3);
+    B = gen.randu(size); B(0) = T(4);
+
+    vsip::impl::profile::Timer t1;
+
+    {
+    impl::Ext_data<block_type> ext_a(A.block(), impl::SYNC_IN);
+    impl::Ext_data<block_type> ext_b(B.block(), impl::SYNC_IN);
+    impl::Ext_data<block_type> ext_c(C.block(), impl::SYNC_OUT);
+    
+    T* pA = ext_a.data();
+    T* pB = ext_b.data();
+    T* pC = ext_c.data();
+    
+    int conj_flag = 1;  // don't conjugate
+    t1.start();
+    for (size_t l=0; l<loop; ++l)
+      ippsMul_32fc((Ipp32fc*)pA, (Ipp32fc*)pB, (Ipp32fc*)pC, size);
+    t1.stop();
+    }
+
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+#if 0
+// IPP Does not provide split complex multiply.
+template <>
+struct t_vmul_ipp_vm<complex<float>, Cmplx_split_fmt> : Benchmark_base
+{
+  typedef complex<float> T;
+
+  char* what() { return "t_vmul_ipp_vm complex<float> split"; }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(size_t) { return 2*sizeof(T); }
+  int wiob_per_point(size_t) { return 1*sizeof(T); }
+  int mem_per_point(size_t)  { return 3*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_split_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+    typedef impl::Ext_data<block_type>::raw_ptr_type ptr_type;
+
+    Vector<T, block_type>   A(size, T());
+    Vector<T, block_type>   B(size, T());
+    Vector<T, block_type>   C(size);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size); A(0) = T(3);
+    B = gen.randu(size); B(0) = T(4);
+
+    vsip::impl::profile::Timer t1;
+    
+    {
+    impl::Ext_data<block_type> ext_a(A.block(), impl::SYNC_IN);
+    impl::Ext_data<block_type> ext_b(B.block(), impl::SYNC_IN);
+    impl::Ext_data<block_type> ext_c(C.block(), impl::SYNC_OUT);
+    
+    ptr_type pA = ext_a.data();
+    ptr_type pB = ext_b.data();
+    ptr_type pC = ext_c.data();
+
+    int conj_flag = 1;  // don't conjugate
+    t1.start();
+    for (size_t l=0; l<loop; ++l)
+      ; // NO IPP split complex multiply
+    t1.stop();
+    }
+
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), A.get(i) * B.get(i)));
+    
+    time = t1.delta();
+  }
+};
+#endif
+
+
+
+/***********************************************************************
+  IPP Vector Multiply (IPP memory allocation)
+***********************************************************************/
+
 template <typename T>
 struct t_vmul_ipp;
 
@@ -243,6 +415,10 @@
 
 
 
+/***********************************************************************
+  Benchmark Main
+***********************************************************************/
+
 void
 defaults(Loop1P&)
 {
@@ -255,10 +431,13 @@
 {
   switch (what)
   {
-  case  1: loop(t_vmul_ipp<float>()); break;
-  case  2: loop(t_vmul_ipp<std::complex<float> >()); break;
+  case  1: loop(t_vmul_ipp_vm<float>()); break;
+  case  2: loop(t_vmul_ipp_vm<std::complex<float> >()); break;
 
   case  12: loop(t_vmul_ipp_ip<1, std::complex<float> >()); break;
   case  22: loop(t_vmul_ipp_ip<2, std::complex<float> >()); break;
+
+  case 101: loop(t_vmul_ipp<float>()); break;
+  case 102: loop(t_vmul_ipp<std::complex<float> >()); break;
   }
 }
Index: benchmarks/loop.hpp
===================================================================
--- benchmarks/loop.hpp	(revision 173215)
+++ benchmarks/loop.hpp	(working copy)
@@ -624,4 +624,13 @@
     this->sweep(fcn);
 }
 
+extern void marker1_start();
+extern void marker1_stop();
+extern void marker2_start();
+extern void marker2_stop();
+extern void marker3_start();
+extern void marker3_stop();
+extern void marker4_start();
+extern void marker4_stop();
+
 #endif // CSL_LOOP_HPP
Index: benchmarks/vmul.cpp
===================================================================
--- benchmarks/vmul.cpp	(revision 173215)
+++ benchmarks/vmul.cpp	(working copy)
@@ -49,24 +49,16 @@
 #endif
   case   5: loop(t_rcvmul1<float>()); break;
 
-  case  11: loop(t_svmul1<float,          float>()); break;
-  case  12: loop(t_svmul1<float,          complex<float> >()); break;
-  case  13: loop(t_svmul1<complex<float>, complex<float> >()); break;
-
-  case  14: loop(t_svmul2<float>()); break;
-  case  15: loop(t_svmul2<complex<float> >()); break;
-  case  16: loop(t_svmul3<float>()); break;
-
-  case  17: loop(t_svmul4<float>()); break;
-  case  18: loop(t_svmul4<float, Map<>, Map<> >()); break;
-  case  19: loop(t_svmul4<float, Map<>, Global_map<1> >()); break;
-
   case  21: loop(t_vmul_dom1<float>()); break;
   case  22: loop(t_vmul_dom1<complex<float> >()); break;
 
   case  31: loop(t_vmul_ip1<float>()); break;
   case  32: loop(t_vmul_ip1<complex<float> >()); break;
 
+    // Using function
+  case  51: loop(t_vmul_func<float>()); break;
+  case  52: loop(t_vmul_func<complex<float> >()); break;
+
   // Double-precision
 
   case 101: loop(t_vmul1<double>()); break;
@@ -77,10 +69,6 @@
 #endif
   case 105: loop(t_rcvmul1<double>()); break;
 
-  case 111: loop(t_svmul1<double,          double>()); break;
-  case 112: loop(t_svmul1<double,          complex<double> >()); break;
-  case 113: loop(t_svmul1<complex<double>, complex<double> >()); break;
-
   case 131: loop(t_vmul_ip1<double>()); break;
   case 132: loop(t_vmul_ip1<complex<double> >()); break;
 
@@ -94,18 +82,14 @@
       << "   -3 -- Vector<complex<float>> * Vector<complex<float>> (SPLIT)\n"
       << "   -4 -- Vector<complex<float>> * Vector<complex<float>> (INTER)\n"
       << "   -5 -- Vector<        float > * Vector<complex<float>>\n"
-      << " Scalar-Vector:\n"
-      << "  -11 --                float   * Vector<        float >\n"
-      << "  -12 --                float   * Vector<complex<float>>\n"
-      << "  -13 --        complex<float>  * Vector<complex<float>>\n"
-      << "  -14 -- t_svmul2\n"
-      << "  -15 -- t_svmul2\n"
-      << "  -15 -- t_svmul3\n"
-      << "  -15 -- t_svmul4\n"
+      << "\n"
       << "  -21 -- t_vmul_dom1\n"
       << "  -22 -- t_vmul_dom1\n"
       << "  -31 -- t_vmul_ip1\n"
       << "  -32 -- t_vmul_ip1\n"
+      << " Vector-Vector (using mul() function):\n"
+      << "  -51 -- mul(Vector<        float >, Vector<        float >)\n"
+      << "  -52 -- mul(Vector<complex<float>>, Vector<complex<float>>)\n"
       << "\ndouble-precision:\n"
       << "  (101-113)\n"
       << "  (131-132)\n"
Index: benchmarks/main.cpp
===================================================================
--- benchmarks/main.cpp	(revision 173215)
+++ benchmarks/main.cpp	(working copy)
@@ -190,3 +190,14 @@
 
   test(loop, what);
 }
+
+
+
+void marker1_start() {}
+void marker1_stop() {}
+void marker2_start() {}
+void marker2_stop() {}
+void marker3_start() {}
+void marker3_stop() {}
+void marker4_start() {}
+void marker4_stop() {}
Index: benchmarks/vmul.hpp
===================================================================
--- benchmarks/vmul.hpp	(revision 173215)
+++ benchmarks/vmul.hpp	(working copy)
@@ -211,7 +211,75 @@
 
 
 
+// Element-wise vector-multiply (using mul() instead operator*()).
+// Supports distributed views, using implicit data-parallelism.
 
+template <typename T,
+	  typename MapT = Local_map,
+	  typename SP   = No_barrier>
+struct t_vmul_func : Benchmark_base
+{
+  typedef Dense<1, T, row1_type, MapT> block_type;
+
+  char* what() { return "t_vmul1"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 2*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 3*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+    VSIP_IMPL_NOINLINE
+  {
+    MapT map = create_map<1, MapT>();
+
+    Vector<T, block_type> A(size, T(), map);
+    Vector<T, block_type> B(size, T(), map);
+    Vector<T, block_type> C(size,      map);
+
+    Rand<T> gen(0, 0);
+    // A, B, and C have the same map.
+    for (index_type i=0; i<C.local().size(); ++i)
+    {
+      A.local().put(i, gen.randu());
+      B.local().put(i, gen.randu());
+    }
+    A.put(0, T(3));
+    B.put(0, T(4));
+
+    vsip::impl::profile::Timer t1;
+    SP sp;
+    
+    t1.start();
+    sp.sync();
+    for (index_type l=0; l<loop; ++l)
+      C = mul(A, B);
+    sp.sync();
+    t1.stop();
+    
+    for (index_type i=0; i<C.local().size(); ++i)
+      test_assert(equal(C.local().get(i),
+			A.local().get(i) * B.local().get(i)));
+    
+    time = t1.delta();
+  }
+
+  void diag()
+  {
+    length_type const size = 256;
+
+    MapT map = create_map<1, MapT>();
+
+    Vector<T, block_type> A(size, T(), map);
+    Vector<T, block_type> B(size, T(), map);
+    Vector<T, block_type> C(size,      map);
+
+    vsip::impl::diagnose_eval_list_std(C, mul(A, B));
+  }
+};
+
+
+
+
 // Element-wise vector-multiply.  Supports distributed views, using
 // in-loop local views.
 
@@ -594,13 +662,19 @@
 
 
 
-// Benchmark scalar-view vector multiply (Scalar * View)
+// Benchmark scalar-view vector multiply (Scalar * View), w/subdomain
 
-template <typename T>
-struct t_svmul2 : Benchmark_base
+template <typename ScalarT,
+	  typename T>
+struct t_svmul_dom : Benchmark_base
 {
-  char* what() { return "t_svmul2"; }
-  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  char* what() { return "t_svmul_dom"; }
+  int ops_per_point(length_type)
+  { if (sizeof(ScalarT) == sizeof(T))
+      return vsip::impl::Ops_info<T>::mul;
+    else
+      return 2*vsip::impl::Ops_info<ScalarT>::mul;
+  }
   int riob_per_point(length_type) { return 1*sizeof(T); }
   int wiob_per_point(length_type) { return 1*sizeof(T); }
   int mem_per_point(length_type)  { return 2*sizeof(T); }
@@ -610,21 +684,103 @@
     Vector<T>   A(size, T());
     Vector<T>   C(size);
 
-    T alpha = T(3);
+    ScalarT alpha = ScalarT(3);
 
+    Rand<T>     gen(0, 0);
+    A = gen.randu(size);
     A.put(0, T(4));
-    
+
+    Domain<1> dom(size);
+
     vsip::impl::profile::Timer t1;
     
     t1.start();
     for (index_type l=0; l<loop; ++l)
-      C = A * alpha;
+      C(dom) = alpha * A(dom);
     t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      test_assert(equal(C.get(i), alpha * A.get(i)));
+    
+    time = t1.delta();
+  }
 
-    test_assert(equal(C.get(0), T(12)));
+  void diag()
+  {
+    length_type const size = 256;
+
+    Vector<T>   A(size, T());
+    Vector<T>   C(size);
+
+    ScalarT alpha = ScalarT(3);
+
+    Domain<1> dom(size);
+
+    vsip::impl::diagnose_eval_list_std(C(dom), alpha * A(dom));
+  }
+};
+
+
+
+// Benchmark scalar-view vector multiply (Scalar * View), w/cold cache.
+
+template <typename ScalarT,
+	  typename T>
+struct t_svmul_cc : Benchmark_base
+{
+  char* what() { return "t_svmul_cc (cold cache)"; }
+  int ops_per_point(length_type)
+  { if (sizeof(ScalarT) == sizeof(T))
+      return vsip::impl::Ops_info<T>::mul;
+    else
+      return 2*vsip::impl::Ops_info<ScalarT>::mul;
+  }
+  int riob_per_point(length_type) { return 1*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 2*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    length_type rows = footprint_ / size;
+    Matrix<T>   A(rows, size, T());
+    Matrix<T>   C(rows, size);
+
+    ScalarT alpha = ScalarT(3);
+
+    Rand<T>     gen(0, 0);
+    A = gen.randu(rows, size);
+    A.put(0, 0, T(4));
+
+    vsip::impl::profile::Timer t1;
     
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      C.row(l%rows) = alpha * A.row(l%rows);
+    t1.stop();
+    
+    for (index_type i=0; i<size; ++i)
+      for (index_type r=0; r<rows && r<loop; ++r)
+	test_assert(equal(C.get(r, i), alpha * A.get(r, i)));
+    
     time = t1.delta();
   }
+
+  void diag()
+  {
+    length_type const size = 256;
+    length_type rows = footprint_ / size;
+
+    Matrix<T>   A(rows, size, T());
+    Matrix<T>   C(rows, size);
+
+    ScalarT alpha = ScalarT(3);
+
+    vsip::impl::diagnose_eval_list_std(C.row(0), alpha * A.row(0));
+  }
+
+  t_svmul_cc(length_type footprint) : footprint_(footprint) {}
+
+  length_type footprint_;
 };
 
 
Index: benchmarks/sal/vmul.cpp
===================================================================
--- benchmarks/sal/vmul.cpp	(revision 173215)
+++ benchmarks/sal/vmul.cpp	(working copy)
@@ -1,10 +1,10 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    benchmarks/vmul_sal.cpp
+/** @file    benchmarks/sal/vmul.cpp
     @author  Don McCoy
     @date    2005-01-23
     @brief   VSIPL++ Library: Benchmark for SAL vector multiply.
@@ -364,13 +364,13 @@
 struct t_svmul_sal<complex<float>, complex<float>, Cmplx_inter_fmt>
   : Benchmark_base
 {
-  typedef float T;
+  typedef complex<float> T;
 
   char* what() { return "t_svmul_sal"; }
-  int ops_per_point(size_t)  { return vsip::impl::Ops_info<float>::mul; }
-  int riob_per_point(size_t) { return 2*sizeof(float); }
-  int wiob_per_point(size_t) { return 1*sizeof(float); }
-  int mem_per_point(size_t)  { return 3*sizeof(float); }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(size_t) { return 2*sizeof(T); }
+  int wiob_per_point(size_t) { return 1*sizeof(T); }
+  int mem_per_point(size_t)  { return 3*sizeof(T); }
 
   void operator()(size_t size, size_t loop, float& time)
   {
@@ -418,13 +418,13 @@
 struct t_svmul_sal<complex<float>, complex<float>, Cmplx_split_fmt>
   : Benchmark_base
 {
-  typedef float T;
+  typedef complex<float> T;
 
   char* what() { return "t_svmul_sal"; }
-  int ops_per_point(size_t)  { return vsip::impl::Ops_info<float>::mul; }
-  int riob_per_point(size_t) { return 2*sizeof(float); }
-  int wiob_per_point(size_t) { return 1*sizeof(float); }
-  int mem_per_point(size_t)  { return 3*sizeof(float); }
+  int ops_per_point(size_t)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(size_t) { return 2*sizeof(T); }
+  int wiob_per_point(size_t) { return 1*sizeof(T); }
+  int mem_per_point(size_t)  { return 3*sizeof(T); }
 
   void operator()(size_t size, size_t loop, float& time)
   {
Index: benchmarks/sal/vthresh.cpp
===================================================================
--- benchmarks/sal/vthresh.cpp	(revision 0)
+++ benchmarks/sal/vthresh.cpp	(revision 0)
@@ -0,0 +1,172 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    benchmarks/sal/vthresh.cpp
+    @author  Jules Bergmann
+    @date    2007-06-05
+    @brief   VSIPL++ Library: Benchmark for vthresh
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <sal.h>
+
+#include <vsip/random.hpp>
+#include <vsip/opt/profile.hpp>
+#include <vsip/core/extdata.hpp>
+#include <vsip/core/ops_info.hpp>
+
+#include "loop.hpp"
+#include "benchmarks.hpp"
+
+using namespace std;
+using namespace vsip;
+
+using impl::Stride_unit_dense;
+using impl::Cmplx_inter_fmt;
+using impl::Cmplx_split_fmt;
+
+
+
+/***********************************************************************
+  Definitions - vector element-wise multiply
+***********************************************************************/
+
+template <typename T>
+struct t_vthres_sal;
+
+template <>
+struct t_vthres_sal<float> : Benchmark_base
+{
+  typedef float T;
+
+  char* what() { return "t_vthres_sal"; }
+  int ops_per_point(size_t)  { return 1; }
+
+  int riob_per_point(size_t) { return 1*sizeof(T); }
+  int wiob_per_point(size_t) { return 1*sizeof(T); }
+  int mem_per_point(size_t)  { return 2*sizeof(T); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   A     (size, T());
+    Vector<T, block_type>   result(size, T());
+    T                       b = T(0.5);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+
+    vsip::impl::profile::Timer t1;
+
+    { // Control Ext_data scope.
+      impl::Ext_data<block_type> ext_A     (A.block(),      impl::SYNC_IN);
+      impl::Ext_data<block_type> ext_result(result.block(), impl::SYNC_OUT);
+    
+      T* p_A      = ext_A.data();
+      T* p_result = ext_result.data();
+      
+      t1.start();
+      marker_start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	vthresx(p_A,1, &b, p_result,1, size, 0);
+      }
+      marker_stop();
+      t1.stop();
+    }
+    
+    for (index_type i=0; i<size; ++i)
+    {
+      test_assert(equal<T>(result.get(i), (A(i) >= b) ? A(i) : 0.f));
+    }
+    
+    time = t1.delta();
+  }
+};
+
+
+
+template <typename T>
+struct t_vthres_c : Benchmark_base
+{
+  char* what() { return "t_vthres_c"; }
+  int ops_per_point(size_t)  { return 1; }
+
+  int riob_per_point(size_t) { return 2*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 3*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   A     (size, T());
+    T                       b = T(0.5);
+    Vector<T, block_type>   result(size, T());
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+
+    vsip::impl::profile::Timer t1;
+
+    { // Control Ext_data scope.
+      impl::Ext_data<block_type> ext_A     (A.block(),      impl::SYNC_IN);
+      impl::Ext_data<block_type> ext_result(result.block(), impl::SYNC_OUT);
+    
+      T* p_A      = ext_A.data();
+      T* p_result = ext_result.data();
+      
+      t1.start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	for (index_type i=0; i<size; ++i)
+	  p_result[i] = (p_A[i] >= b) ? p_A[i] : 0.f;
+      }
+      t1.stop();
+    }
+    
+    for (index_type i=0; i<size; ++i)
+    {
+      test_assert(equal<T>(result.get(i), (A(i) >= b) ? A(i) : 0.f));
+    }
+    
+    time = t1.delta();
+  }
+};
+
+
+
+void
+defaults(Loop1P&)
+{
+}
+
+
+
+void
+test(Loop1P& loop, int what)
+{
+  typedef complex<float> cf_type;
+  switch (what)
+  {
+  case  1: loop(t_vthres_sal<float>()); break;
+  case 11: loop(t_vthres_c<float>()); break;
+  case  0:
+    std::cout
+      << "SAL vthres\n"
+      << "  -1 -- SAL vthresx (float) Z(i) = A(i) > b ? A(i) : 0\n"
+      << " -11 -- C           (float) Z(i) = A(i) > b ? A(i) : 0\n"
+      ;
+  }
+}
Index: benchmarks/sal/lvgt.cpp
===================================================================
--- benchmarks/sal/lvgt.cpp	(revision 0)
+++ benchmarks/sal/lvgt.cpp	(revision 0)
@@ -0,0 +1,293 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    benchmarks/sal/lvgt.cpp
+    @author  Jules Bergmann
+    @date    2007-05-15
+    @brief   VSIPL++ Library: Benchmark for lvgt
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <sal.h>
+
+#include <vsip/random.hpp>
+#include <vsip/opt/profile.hpp>
+#include <vsip/core/extdata.hpp>
+#include <vsip/core/ops_info.hpp>
+
+#include "loop.hpp"
+#include "benchmarks.hpp"
+
+using namespace std;
+using namespace vsip;
+
+using impl::Stride_unit_dense;
+using impl::Cmplx_inter_fmt;
+using impl::Cmplx_split_fmt;
+
+
+
+/***********************************************************************
+  Definitions - vector element-wise multiply
+***********************************************************************/
+
+template <typename T>
+struct t_lvgt_sal;
+
+template <>
+struct t_lvgt_sal<float> : Benchmark_base
+{
+  typedef float T;
+
+  char* what() { return "t_lvgt_sal"; }
+  int ops_per_point(size_t)  { return 1; }
+
+  int riob_per_point(size_t) { return 2*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 3*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   A     (size, T());
+    Vector<T, block_type>   B     (size, T());
+    Vector<T, block_type>   result(size, T());
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    vsip::impl::profile::Timer t1;
+
+    { // Control Ext_data scope.
+      impl::Ext_data<block_type> ext_A     (A.block(),      impl::SYNC_IN);
+      impl::Ext_data<block_type> ext_B     (B.block(),      impl::SYNC_IN);
+      impl::Ext_data<block_type> ext_result(result.block(), impl::SYNC_OUT);
+    
+      T* p_A      = ext_A.data();
+      T* p_B      = ext_B.data();
+      T* p_result = ext_result.data();
+      
+      t1.start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	lvgtx (p_A,1, p_B,1, p_result,1, size, 0);
+      }
+      t1.stop();
+    }
+    
+    for (index_type i=0; i<size; ++i)
+    {
+      test_assert(equal<T>(result.get(i), (A(i) > B(i)) ? 1.f : 0.f));
+    }
+    
+    time = t1.delta();
+  }
+};
+
+
+
+template <typename T>
+struct t_threshold_sal;
+
+template <>
+struct t_threshold_sal<float> : Benchmark_base
+{
+  typedef float T;
+
+  char* what() { return "t_threshold_sal"; }
+  int ops_per_point(size_t)  { return 1; }
+
+  int riob_per_point(size_t) { return 2*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 3*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   A     (size, T());
+    Vector<T, block_type>   B     (size, T());
+    Vector<T, block_type>   result(size, T());
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    vsip::impl::profile::Timer t1;
+
+    { // Control Ext_data scope.
+      impl::Ext_data<block_type> ext_A     (A.block(),      impl::SYNC_IN);
+      impl::Ext_data<block_type> ext_B     (B.block(),      impl::SYNC_IN);
+      impl::Ext_data<block_type> ext_result(result.block(), impl::SYNC_OUT);
+    
+      T* p_A      = ext_A.data();
+      T* p_B      = ext_B.data();
+      T* p_result = ext_result.data();
+      
+      t1.start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	lvgtx (p_A,1, p_B,1,      p_result,1, size, 0);
+	vmulx (p_A,1, p_result,1, p_result,1, size, 0);
+      }
+      t1.stop();
+    }
+    
+    for (index_type i=0; i<size; ++i)
+    {
+      test_assert(equal<T>(result.get(i), (A(i) > B(i)) ? A(i) : 0.f));
+    }
+    
+    time = t1.delta();
+  }
+};
+
+
+
+template <typename T>
+struct t_lvgt_c : Benchmark_base
+{
+  char* what() { return "t_lvgt_c"; }
+  int ops_per_point(size_t)  { return 1; }
+
+  int riob_per_point(size_t) { return 2*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 3*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   A     (size, T());
+    Vector<T, block_type>   B     (size, T());
+    Vector<T, block_type>   result(size, T());
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    vsip::impl::profile::Timer t1;
+
+    { // Control Ext_data scope.
+      impl::Ext_data<block_type> ext_A     (A.block(),      impl::SYNC_IN);
+      impl::Ext_data<block_type> ext_B     (B.block(),      impl::SYNC_IN);
+      impl::Ext_data<block_type> ext_result(result.block(), impl::SYNC_OUT);
+    
+      T* p_A      = ext_A.data();
+      T* p_B      = ext_B.data();
+      T* p_result = ext_result.data();
+      
+      t1.start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	for (index_type i=0; i<size; ++i)
+	  p_result[i] = (p_A[i] > p_B[i]) ? 1.f : 0.f;
+      }
+      t1.stop();
+    }
+    
+    for (index_type i=0; i<size; ++i)
+    {
+      test_assert(equal<T>(result.get(i), (A(i) > B(i)) ? 1.f : 0.f));
+    }
+    
+    time = t1.delta();
+  }
+};
+
+
+
+template <typename T>
+struct t_threshold_c : Benchmark_base
+{
+  char* what() { return "t_threshold_c"; }
+  int ops_per_point(size_t)  { return 1; }
+
+  int riob_per_point(size_t) { return 2*sizeof(float); }
+  int wiob_per_point(size_t) { return 1*sizeof(float); }
+  int mem_per_point(size_t)  { return 3*sizeof(float); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   A     (size, T());
+    Vector<T, block_type>   B     (size, T());
+    Vector<T, block_type>   result(size, T());
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+    B = gen.randu(size);
+
+    vsip::impl::profile::Timer t1;
+
+    { // Control Ext_data scope.
+      impl::Ext_data<block_type> ext_A     (A.block(),      impl::SYNC_IN);
+      impl::Ext_data<block_type> ext_B     (B.block(),      impl::SYNC_IN);
+      impl::Ext_data<block_type> ext_result(result.block(), impl::SYNC_OUT);
+    
+      T* p_A      = ext_A.data();
+      T* p_B      = ext_B.data();
+      T* p_result = ext_result.data();
+      
+      t1.start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	for (index_type i=0; i<size; ++i)
+	  p_result[i] = (p_A[i] > p_B[i]) ? p_A[i] : 0.f;
+      }
+      t1.stop();
+    }
+    
+    for (index_type i=0; i<size; ++i)
+    {
+      test_assert(equal<T>(result.get(i), (A(i) > B(i)) ? A(i) : 0.f));
+    }
+    
+    time = t1.delta();
+  }
+};
+
+
+
+void
+defaults(Loop1P&)
+{
+}
+
+
+
+void
+test(Loop1P& loop, int what)
+{
+  typedef complex<float> cf_type;
+  switch (what)
+  {
+  case  1: loop(t_lvgt_sal<float>()); break;
+  case  2: loop(t_threshold_sal<float>()); break;
+  case 11: loop(t_lvgt_c<float>()); break;
+  case 12: loop(t_threshold_c<float>()); break;
+  case  0:
+    std::cout
+      << "SAL lvgt\n"
+      << "  -1 -- SAL lvgtx      (float) Z(i) = A(i) > B(i) ? 1    : 0\n"
+      << "  -2 -- SAL lvgtx/vmul (float) Z(i) = A(i) > B(i) ? A(i) : 0\n"
+      << " -11 -- C (float) Z(i) = A(i) > B(i) ? 1    : 0\n"
+      << " -12 -- C (float) Z(i) = A(i) > B(i) ? A(i) : 0\n"
+      ;
+  }
+}
