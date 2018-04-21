Index: synopsis.py.in
===================================================================
--- synopsis.py.in	(revision 181512)
+++ synopsis.py.in	(working copy)
@@ -11,7 +11,6 @@
 from Synopsis.Formatters import HTML
 from Synopsis.Formatters.HTML.Views import *
 from Synopsis.Formatters import SXR
-import re
 
 srcdir = '@srcdir@'
 # beware filenames containing whitespace !
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 181512)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2007-09-10  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Fix option-default logic for --with-lapack.
+	* src/vsip/core/fft.hpp: Fix typo.
+	* tests/ref-impl/GNUmakefile: Remove as obsoleted.
+	
 2007-08-25  Jules Bergmann  <jules@codesourcery.com>
 
 	Fix bug: dispatch to SAL evaluated A-b*C as A*b-C.
Index: src/vsip/core/fft.hpp
===================================================================
--- src/vsip/core/fft.hpp	(revision 181512)
+++ src/vsip/core/fft.hpp	(working copy)
@@ -207,7 +207,7 @@
 
 #ifdef VSIP_IMPL_REF_IMPL
   template <typename ViewT>
-  typename fft::result<), typename ViewT::block_type>::view_type
+  typename fft::result<O, typename ViewT::block_type>::view_type
   operator()(ViewT in) VSIP_THROW((std::bad_alloc))
   {
     typename base::Scope scope(*this);
Index: src/vsip/opt/numa.cpp
===================================================================
--- src/vsip/opt/numa.cpp	(revision 181512)
+++ src/vsip/opt/numa.cpp	(working copy)
@@ -13,6 +13,7 @@
 #include <vsip/core/argv_utils.hpp>
 #include <vsip/opt/numa.hpp>
 #include <numa.h>
+#include <iostream>
 
 namespace vsip
 {
@@ -22,13 +23,18 @@
 {
 void local_spes_only()
 {
+  if (numa_available() < 0)
+  {
+    std::cerr << "no NUMA support available" << std::endl;
+    return;
+  }
   nodemask_t mask;
   nodemask_zero(&mask);
   nodemask_set(&mask, 1);
   numa_bind(&mask);
 }
 
-void initialize(int argc, char **&argv)
+void initialize(int &argc, char **&argv)
 {
   int count = argc;
   char** value = argv;
Index: src/vsip/opt/numa.hpp
===================================================================
--- src/vsip/opt/numa.hpp	(revision 181512)
+++ src/vsip/opt/numa.hpp	(working copy)
@@ -19,7 +19,7 @@
 {
 namespace numa
 {
-void initialize(int argv, char **&argv);
+void initialize(int &argv, char **&argv);
 }
 }
 }
Index: src/vsip_csl/output.hpp
===================================================================
--- src/vsip_csl/output.hpp	(revision 181512)
+++ src/vsip_csl/output.hpp	(working copy)
@@ -22,6 +22,7 @@
 #include <vsip/domain.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
+#include <vsip/tensor.hpp>
 
 #include <vsip_csl/output/domain.hpp>
 
@@ -73,6 +74,77 @@
   return out;
 }
 
+<<<<<<< .mine
+
+/// Write a tensor to a stream.
+
+template <typename T,
+	  typename Block>
+inline
+std::ostream&
+operator<<(
+  std::ostream&		       out,
+  vsip::const_Tensor<T, Block> v)
+  VSIP_NOTHROW
+{
+  for (vsip::index_type z=0; z<v.size(0); ++z)
+  {
+    out << " plane " << z << ":\n";
+    for (vsip::index_type y=0; y<v.size(1); ++y)
+    {
+      out << "  " << y << ":";
+      for (vsip::index_type x=0; x<v.size(2); ++x)
+        out << "  " << v.get(z, y, x);
+      out << std::endl;
+    }
+  }
+  return out;
+}
+
+
+/// Write an Index to a stream.
+
+template <vsip::dimension_type Dim>
+inline
+std::ostream&
+operator<<(
+  std::ostream&		        out,
+  vsip::Index<Dim> const& idx)
+  VSIP_NOTHROW
+{
+  out << "(";
+  for (vsip::dimension_type d=0; d<Dim; ++d)
+  {
+    if (d > 0) out << ", ";
+    out << idx[d];
+  }
+  out << ")";
+  return out;
+}
+
+
+/// Write a Length to a stream.
+
+template <vsip::dimension_type Dim>
+inline
+std::ostream&
+operator<<(
+  std::ostream&		         out,
+  vsip::impl::Length<Dim> const& idx)
+  VSIP_NOTHROW
+{
+  out << "(";
+  for (vsip::dimension_type d=0; d<Dim; ++d)
+  {
+    if (d > 0) out << ", ";
+    out << idx[d];
+  }
+  out << ")";
+  return out;
+}
+
+=======
+>>>>>>> .r181512
 } // namespace vsip
 
 #endif // VSIP_CSL_OUTPUT_HPP
Index: src/vsip_csl/stencil.hpp
===================================================================
--- src/vsip_csl/stencil.hpp	(revision 181512)
+++ src/vsip_csl/stencil.hpp	(working copy)
@@ -26,10 +26,10 @@
 
 namespace stencil
 {
-template <typename O> struct Inner_loop;
+template <vsip::dimension_type D, typename O> struct Inner_loop;
 
 template <>
-struct Inner_loop<vsip::row2_type>
+struct Inner_loop<2, vsip::row2_type>
 {
   template <typename T1, typename Block1, typename T2, typename Block2,
             typename Op>
@@ -46,7 +46,7 @@
 };
 
 template <>
-struct Inner_loop<vsip::col2_type>
+struct Inner_loop<2, vsip::col2_type>
 {
   template <typename T1, typename Block1, typename T2, typename Block2,
             typename Op>
@@ -62,10 +62,65 @@
   }
 };
 
+template <typename order>
+struct Inner_loop<3, order> // FIXME
+{
+  template <typename T1, typename Block1, typename T2, typename Block2,
+            typename Op>
+  static void apply(vsip::const_Tensor<T1, Block1> input,
+                    vsip::Tensor<T2, Block2> output,
+                    Op const &op,
+                    vsip::length_type prev_z, vsip::length_type next_z,
+                    vsip::length_type prev_y, vsip::length_type next_y,
+                    vsip::length_type prev_x, vsip::length_type next_x)
+  {
+    for (vsip::length_type z = prev_z; z != input.size(0) - next_z; ++z)
+      for (vsip::length_type y = prev_y; y != input.size(1) - next_y; ++y)
+        for (vsip::length_type x = prev_x; x != input.size(2) - next_x; ++x)
+          output.put(z, y, x, op(input, z, y, x));
+  }
+};
+
 } // namespace vsip_csl::stencil
 
 template <typename T1, typename Block1, typename T2, typename Block2,
           typename Op>
+void apply_stencil(vsip::const_Vector<T1, Block1> input,
+                   vsip::Vector<T2, Block2> output,
+                   Op const &op)
+{
+  using namespace stencil;
+  using namespace vsip;
+
+  index_type const prev = op.origin();
+  index_type const next = op.size() - op.origin() - 1;
+
+  // Compute the inner values.
+  for (vsip::length_type x = prev; x != input.size() - next; ++x)
+    output.put(x, op(input, x));
+
+  if (prev)
+  {
+    // Compute the left boundary values.
+    typedef Boundary_factory<1, Block1, stencil::prev, Op> p_factory;
+    typedef typename p_factory::view_type p_view_type;
+    p_view_type p = p_factory::create(input.block(), op, zero);
+    for (length_type x = 0; x != p.size() - prev - next; ++x)
+      output.put(x, op(p, x + prev));
+  }
+  if (next)
+  {
+    // Compute the right boundary values.
+    typedef Boundary_factory<1, Block1, stencil::next, Op> n_factory;
+    typedef typename n_factory::view_type n_view_type;
+    n_view_type n = n_factory::create(input.block(), op, zero);
+    for (length_type x = 0; x != n.size() - prev - next; ++x)
+      output.put(output.size() - next + x, op(n, x + prev));
+  }
+}
+  
+template <typename T1, typename Block1, typename T2, typename Block2,
+          typename Op>
 void apply_stencil(vsip::const_Matrix<T1, Block1> input,
                    vsip::Matrix<T2, Block2> output,
                    Op const &op)
@@ -79,13 +134,13 @@
   index_type const next_x = op.size(1) - op.origin(1) - 1;
 
   // Compute the inner values.
-  Inner_loop<typename impl::Block_layout<Block1>::order_type>::apply
+  Inner_loop<2, typename impl::Block_layout<Block1>::order_type>::apply
     (input, output, op, prev_y, next_y, prev_x, next_x);
 
   if (prev_x)
   {
     // Compute the left boundary values.
-    typedef Boundary_factory<Block1, left, Op> lb_factory;
+    typedef Boundary_factory<2, Block1, left, Op> lb_factory;
     typedef typename lb_factory::view_type lb_view_type;
     lb_view_type lb = lb_factory::create(input.block(), op, zero);
     for (length_type y = prev_y; y != lb.size(0) - next_y; ++y)
@@ -95,7 +150,7 @@
   if (next_x)
   {
     // Compute the right boundary values.
-    typedef Boundary_factory<Block1, right, Op> rb_factory;
+    typedef Boundary_factory<2, Block1, right, Op> rb_factory;
     typedef typename rb_factory::view_type rb_view_type;
     rb_view_type rb = rb_factory::create(input.block(), op, zero);
     for (length_type y = prev_y; y != rb.size(0) - next_y; ++y)
@@ -106,7 +161,7 @@
   if (prev_y)
   {
     // Compute the top boundary values.
-    typedef Boundary_factory<Block1, top, Op> tb_factory;
+    typedef Boundary_factory<2, Block1, top, Op> tb_factory;
     typedef typename tb_factory::view_type tb_view_type;
     tb_view_type tb = tb_factory::create(input.block(), op, zero);
     for (length_type x = prev_x; x != tb.size(1) - next_x; ++x)
@@ -116,7 +171,7 @@
   if (next_y)
   {
     // Compute the bottom boundary values.
-    typedef Boundary_factory<Block1, bottom, Op> bb_factory;
+    typedef Boundary_factory<2, Block1, bottom, Op> bb_factory;
     typedef typename bb_factory::view_type bb_view_type;
     bb_view_type bb = bb_factory::create(input.block(), op, zero);
     for (length_type x = prev_x; x != bb.size(1) - next_x; ++x)
@@ -127,7 +182,7 @@
   if (prev_x && prev_y)
   {
     // Compute the top-left corner values.
-    typedef Boundary_factory<Block1, top_left, Op> tlb_factory;
+    typedef Boundary_factory<2, Block1, top_left, Op> tlb_factory;
     typedef typename tlb_factory::view_type tlb_view_type;
     tlb_view_type tlb = tlb_factory::create(input.block(), op, zero);
     for (length_type y = 0; y != tlb.size(0) - prev_y - next_y; ++y)
@@ -137,7 +192,7 @@
   if (next_y && prev_y)
   {
     // Compute the top-right corner values.
-    typedef Boundary_factory<Block1, top_right, Op> trb_factory;
+    typedef Boundary_factory<2, Block1, top_right, Op> trb_factory;
     typedef typename trb_factory::view_type trb_view_type;
     trb_view_type trb = trb_factory::create(input.block(), op, zero);
     for (length_type y = 0; y != trb.size(0) - prev_y - next_y; ++y)
@@ -148,7 +203,7 @@
   if (prev_x && next_y)
   {
     // Compute the bottom-left corner values.
-    typedef Boundary_factory<Block1, bottom_left, Op> blb_factory;
+    typedef Boundary_factory<2, Block1, bottom_left, Op> blb_factory;
     typedef typename blb_factory::view_type blb_view_type;
     blb_view_type blb = blb_factory::create(input.block(), op, zero);
     for (length_type y = 0; y != blb.size(0) - prev_y - next_y; ++y)
@@ -159,7 +214,7 @@
   if (next_y && next_x)
   {
     // Compute the bottom-right corner values.
-    typedef Boundary_factory<Block1, bottom_right, Op> brb_factory;
+    typedef Boundary_factory<2, Block1, bottom_right, Op> brb_factory;
     typedef typename brb_factory::view_type brb_view_type;
     brb_view_type brb = brb_factory::create(input.block(), op, zero);
     for (length_type y = 0; y != brb.size(0) - prev_y - next_y; ++y)
@@ -169,6 +224,116 @@
                    op(brb, y + prev_y, x + prev_x));
   }
 }
+
+template <typename T1, typename Block1, typename T2, typename Block2,
+          typename Op>
+void apply_stencil(vsip::const_Tensor<T1, Block1> input,
+                   vsip::Tensor<T2, Block2> output,
+                   Op const &op)
+{
+  using namespace stencil;
+  using namespace vsip;
+
+  index_type const prev_z = op.origin(0);
+  index_type const prev_y = op.origin(1);
+  index_type const prev_x = op.origin(2);
+  index_type const next_z = op.size(0) - op.origin(0) - 1;
+  index_type const next_y = op.size(1) - op.origin(1) - 1;
+  index_type const next_x = op.size(2) - op.origin(2) - 1;
+
+  // Compute the inner values.
+  Inner_loop<3, typename impl::Block_layout<Block1>::order_type>::apply
+    (input, output, op, prev_z, next_z, prev_y, next_y, prev_x, next_x);
+
+#if 0
+  if (prev_x)
+  {
+    // Compute the left boundary values.
+    typedef Boundary_factory<2, Block1, left, Op> lb_factory;
+    typedef typename lb_factory::view_type lb_view_type;
+    lb_view_type lb = lb_factory::create(input.block(), op, zero);
+    for (length_type y = prev_y; y != lb.size(0) - next_y; ++y)
+      for (length_type x = 0; x != lb.size(1) - prev_x - next_x; ++x)
+        output.put(y, x, op(lb, y, x + prev_x));
+  }
+  if (next_x)
+  {
+    // Compute the right boundary values.
+    typedef Boundary_factory<2, Block1, right, Op> rb_factory;
+    typedef typename rb_factory::view_type rb_view_type;
+    rb_view_type rb = rb_factory::create(input.block(), op, zero);
+    for (length_type y = prev_y; y != rb.size(0) - next_y; ++y)
+      for (length_type x = 0; x != rb.size(1) - prev_x - next_x; ++x)
+        output.put(y, output.size(1) - next_x + x,
+                   op(rb, y, x + prev_x));
+  }
+  if (prev_y)
+  {
+    // Compute the top boundary values.
+    typedef Boundary_factory<2, Block1, top, Op> tb_factory;
+    typedef typename tb_factory::view_type tb_view_type;
+    tb_view_type tb = tb_factory::create(input.block(), op, zero);
+    for (length_type x = prev_x; x != tb.size(1) - next_x; ++x)
+      for (length_type y = 0; y != tb.size(0) - prev_y - next_y; ++y)
+        output.put(y, x, op(tb, y + prev_y, x));
+  }
+  if (next_y)
+  {
+    // Compute the bottom boundary values.
+    typedef Boundary_factory<2, Block1, bottom, Op> bb_factory;
+    typedef typename bb_factory::view_type bb_view_type;
+    bb_view_type bb = bb_factory::create(input.block(), op, zero);
+    for (length_type x = prev_x; x != bb.size(1) - next_x; ++x)
+      for (length_type y = 0; y != bb.size(0) - prev_y - next_y; ++y)
+        output.put(output.size(0) - next_y + y, x,
+                   op(bb, y + prev_y, x));
+  }
+  if (prev_x && prev_y)
+  {
+    // Compute the top-left corner values.
+    typedef Boundary_factory<2, Block1, top_left, Op> tlb_factory;
+    typedef typename tlb_factory::view_type tlb_view_type;
+    tlb_view_type tlb = tlb_factory::create(input.block(), op, zero);
+    for (length_type y = 0; y != tlb.size(0) - prev_y - next_y; ++y)
+      for (length_type x = 0; x != tlb.size(1) - prev_x - next_x; ++x)
+        output.put(y, x, op(tlb, y + prev_y, x + prev_x));
+  }
+  if (next_y && prev_y)
+  {
+    // Compute the top-right corner values.
+    typedef Boundary_factory<2, Block1, top_right, Op> trb_factory;
+    typedef typename trb_factory::view_type trb_view_type;
+    trb_view_type trb = trb_factory::create(input.block(), op, zero);
+    for (length_type y = 0; y != trb.size(0) - prev_y - next_y; ++y)
+      for (length_type x = 0; x != trb.size(1) - prev_x - next_x; ++x)
+        output.put(y, output.size(1) - next_x + x,
+                   op(trb, y + prev_y, x + prev_x));
+  }
+  if (prev_x && next_y)
+  {
+    // Compute the bottom-left corner values.
+    typedef Boundary_factory<2, Block1, bottom_left, Op> blb_factory;
+    typedef typename blb_factory::view_type blb_view_type;
+    blb_view_type blb = blb_factory::create(input.block(), op, zero);
+    for (length_type y = 0; y != blb.size(0) - prev_y - next_y; ++y)
+      for (length_type x = 0; x != blb.size(1) - prev_x - next_x; ++x)
+        output.put(output.size(0) - next_y + y, x,
+                   op(blb, y + prev_y, x + prev_x));
+  }
+  if (next_y && next_x)
+  {
+    // Compute the bottom-right corner values.
+    typedef Boundary_factory<2, Block1, bottom_right, Op> brb_factory;
+    typedef typename brb_factory::view_type brb_view_type;
+    brb_view_type brb = brb_factory::create(input.block(), op, zero);
+    for (length_type y = 0; y != brb.size(0) - prev_y - next_y; ++y)
+      for (length_type x = 0; x != brb.size(1) - prev_x - next_x; ++x)
+        output.put(output.size(0) - next_y + y,
+                   output.size(1) - next_x + x,
+                   op(brb, y + prev_y, x + prev_x));
+  }
+#endif
+}
   
 namespace stencil
 {
Index: src/vsip_csl/test-precision.hpp
===================================================================
--- src/vsip_csl/test-precision.hpp	(revision 181512)
+++ src/vsip_csl/test-precision.hpp	(working copy)
@@ -18,9 +18,9 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/core/promote.hpp>
 
-
-
 namespace vsip_csl
 {
 
@@ -28,13 +28,16 @@
   Declarations
 ***********************************************************************/
 
-template <typename T>
+template <typename T0, typename T1 = T0>
 struct Precision_traits
 {
-  typedef T type;
-  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+  // Choose the type with lesser precision.
+  typedef vsip::impl::ITE_Type<
+    vsip::impl::Type_equal<T0, typename vsip::Promotion<T0, T1>::type>::value,
+    vsip::impl::As_type<T1>, vsip::impl::As_type<T0> >::type type;
+  typedef typename vsip::impl::Scalar_of<type>::type scalar_type;
 
-  static T eps;
+  static scalar_type eps;
 
   // Determine the lowest bit of precision.
 
@@ -55,6 +58,9 @@
   }
 };
 
+template <typename T0, typename T1>
+Precision_traits<T0, T1>::scalar_type Precision_traits<T0, T1>::eps = 0.;
+
 } // namespace vsip_csl
 
 #endif // VSIP_CSL_TEST_PRECISION_HPP
Index: src/vsip_csl/stencil/boundary_factory.hpp
===================================================================
--- src/vsip_csl/stencil/boundary_factory.hpp	(revision 181512)
+++ src/vsip_csl/stencil/boundary_factory.hpp	(working copy)
@@ -30,13 +30,55 @@
 namespace stencil
 {
 
-enum Position { left, right, top, bottom,
-                top_left, top_right, bottom_left, bottom_right};
+enum Position { prev, next,
+                left, right, top, bottom,
+                top_left, top_right, bottom_left, bottom_right,
+                f_000, f_001, f_010, f_011, f_100, f_101, f_110, f_111,
+                e_x_00, e_x_01, e_x_10, e_x_11,
+                e_y_00, e_y_01, e_y_10, e_y_11,
+                e_z_00, e_z_01, e_z_10, e_z_11};
 enum Padding { zero, constant};
 
 template <typename B, Position P, typename K> struct Boundary_traits;
 
 template <typename B, typename K>
+struct Boundary_traits<B, prev, K>
+{
+  typedef typename vsip::impl::Block_layout<B>::order_type order_type;
+  typedef vsip::impl::Layout<1, order_type, vsip::impl::Stride_unit_dense> 
+    layout_type;
+  
+  // the size of the boundary block
+  static vsip::Domain<1> size(B const &block, K const &k)
+  { return vsip::Domain<1>(k.size() + k.origin() - 1);}
+  // the subblock the boundary block needs to mirror
+  static vsip::Domain<1> src_sub_domain(B const &b, K const &k)
+  { return vsip::Domain<1>(k.size() - 1);}
+  // the destination subblock containing the mirror.
+  static vsip::Domain<1> dst_sub_domain(B const &b, K const &k)
+  { return vsip::Domain<1>(k.origin(), 1, k.size() - 1);}
+};
+
+
+template <typename B, typename K>
+struct Boundary_traits<B, next, K>
+{
+  typedef typename vsip::impl::Block_layout<B>::order_type order_type;
+  typedef vsip::impl::Layout<1, order_type, vsip::impl::Stride_unit_dense> 
+    layout_type;
+  
+  // the size of the boundary block
+  static vsip::Domain<1> size(B const &block, K const &k)
+  { return vsip::Domain<1>(2 * (k.size() - 1) - k.origin());}
+  // the subblock the boundary block needs to mirror
+  static vsip::Domain<1> src_sub_domain(B const &b, K const &k)
+  { return vsip::Domain<1> (b.size(1, 0) - k.size() + 1, 1, k.size() - 1);}
+  // the destination subblock containing the mirror.
+  static vsip::Domain<1> dst_sub_domain(B const &b, K const &k)
+  { return vsip::Domain<1>(k.size() - 1);}
+};
+
+template <typename B, typename K>
 struct Boundary_traits<B, left, K>
 {
   typedef typename vsip::impl::Block_layout<B>::order_type order_type;
@@ -247,10 +289,79 @@
   }
 };
 
+template <typename B, typename K>
+struct Boundary_traits<B, f_000, K>
+{
+  typedef typename vsip::impl::Block_layout<B>::order_type order_type;
+  typedef vsip::impl::Layout<3, order_type, vsip::impl::Stride_unit_dense> 
+    layout_type;
+  
+  // the size of the boundary block
+  static vsip::Domain<3> size(B const &block, K const &k)
+  { return vsip::Domain<3>(k.size() + k.origin() - 1);}
+  // the subblock the boundary block needs to mirror
+  static vsip::Domain<3> src_sub_domain(B const &b, K const &k)
+  { return vsip::Domain<3>(k.size() - 1);}
+  // the destination subblock containing the mirror.
+  static vsip::Domain<3> dst_sub_domain(B const &b, K const &k)
+  { return vsip::Domain<3>(k.origin(), 1, k.size() - 1);}
+};
+
+template <vsip::dimension_type D, typename B, Position P, typename K> 
+struct Boundary_factory;
+
 template <typename B, Position P, typename K>
-struct Boundary_factory
+struct Boundary_factory<1, B, P, K>
 {
   typedef Boundary_traits<B, P, K> traits;
+  typedef vsip::impl::Fast_block<1, typename B::value_type,
+                           typename traits::layout_type> block_type;
+  typedef vsip::Vector<typename B::value_type, block_type> view_type;
+
+  static view_type
+  create(B const &b, K const &k, Padding p)
+  {
+    using namespace vsip;
+
+    Domain<1> size = traits::size(b, k);
+    view_type view(size.length());
+    // set self to 0
+    if (p == zero)
+      impl::Block_fill<1, block_type>::exec(view.block(), 0);
+
+    // assign boundary values
+#if 0
+    std::cout << "size " << size.length() << std::endl;
+    std::cout << "src subdomain: "
+              << traits::src_sub_domain(b, k).first() << ' ' 
+              << traits::src_sub_domain(b, k).length() << std::endl;
+    std::cout << "dst subdomain: " 
+              << traits::dst_sub_domain(b, k).first() << ' '
+              << traits::dst_sub_domain(b, k).length() << std::endl;
+    std::cout << "input " << b.size(1, 0) << std::endl;
+    std::cout << "boundary " << view.block().size(1, 0) << std::endl;
+#endif
+    impl::Subset_block<B> src(traits::src_sub_domain(b, k), const_cast<B &>(b));
+    impl::Subset_block<block_type> dst(traits::dst_sub_domain(b, k), view.block());
+    impl::assign<1>(dst, src);
+
+    // TODO: handle constant padding
+    if (p == constant)
+      ;
+
+#if 0
+    for (unsigned int y = 0; y != size(2, 0); ++y)
+      std::cout << get(y) << std::endl;
+#endif
+
+    return view;
+  }
+};
+
+template <typename B, Position P, typename K>
+struct Boundary_factory<2, B, P, K>
+{
+  typedef Boundary_traits<B, P, K> traits;
   typedef vsip::impl::Fast_block<2, typename B::value_type,
                            typename traits::layout_type> block_type;
   typedef vsip::Matrix<typename B::value_type, block_type> view_type;
Index: tests/ref-impl/GNUmakefile
===================================================================
--- tests/ref-impl/GNUmakefile	(revision 181512)
+++ tests/ref-impl/GNUmakefile	(working copy)
@@ -1,142 +0,0 @@
-######################################################### -*-Makefile-*-
-#
-# File:   Makefile
-# Author: Jeffrey D. Oldham, CodeSourcery, LLC.
-# Date:   07/09/2002
-#
-# Contents:
-#   Makefile to build the VSIPL++ Library unit tests.
-# 
-# Copyright 2005 Georgia Tech Research Corporation, all rights reserved.
-# 
-# A non-exclusive, non-royalty bearing license is hereby granted to all
-# Persons to copy, distribute and produce derivative works for any
-# purpose, provided that this copyright notice and following disclaimer
-# appear on All copies: THIS LICENSE INCLUDES NO WARRANTIES, EXPRESSED
-# OR IMPLIED, WHETHER ORAL OR WRITTEN, WITH RESPECT TO THE SOFTWARE OR
-# OTHER MATERIAL INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES
-# OF MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE, OR ARISING
-# FROM A COURSE OF PERFORMANCE OR DEALING, OR FROM USAGE OR TRADE, OR OF
-# NON-INFRINGEMENT OF ANY PATENTS OF THIRD PARTIES. THE INFORMATION IN
-# THIS DOCUMENT SHOULD NOT BE CONSTRUED AS A COMMITMENT OF DEVELOPMENT
-# BY ANY OF THE ABOVE PARTIES.
-# 
-# The US Government has a license under these copyrights, and this
-# Material may be reproduced by or for the US Government.
-#
-########################################################################
-
-########################################################################
-# Configuration Section
-########################################################################
-
-# The root of the implementation tree.
-IMPLEMENTATION_ROOT =	..
-
-include $(IMPLEMENTATION_ROOT)/GNUmakefile.inc
-
-########################################################################
-# Definition Section
-########################################################################
-
-# All the unit tests
-UNIT_TESTS = admitrelease complex dense math math-matvec math-reductions \
-	     math-scalarview matrix matrix-math matrix-const \
-	     random selgen \
-	     signal signal-convolution signal-correlation \
-	     signal-fft signal-fir signal-histogram signal-windows \
-	     fft-coverage \
-	     solvers-chol solvers-lu solvers-qr solvers-covsol \
-	     vector vector-math vector-const \
-	     view-math dim-order
-
-########################################################################
-# Specific Rule Section
-########################################################################
-
-# Create all the unit tests.
-all: $(UNIT_TESTS)
-
-admitrelease: admitrelease.o
-
-complex: complex.o
-
-dense: dense.o
-
-init: init.o
-
-math: math.o
-
-math-matvec: math-matvec.o
-
-math-reductions: math-reductions.o
-
-math-scalarview: math-scalarview.o
-
-matrix: matrix.o
-
-matrix-math: matrix-math.o
-
-matrix-const: matrix-const.o
-
-random: random.o
-
-selgen: selgen.o
-
-signal: signal.o
-
-signal-convolution: signal-convolution.o
-
-signal-correlation: signal-correlation.o
-
-signal-fir: signal-fir.o
-
-signal-fft: signal-fft.o
-
-signal-histogram: signal-histogram.o
-
-signal-windows: signal-windows.o
-
-fft-coverage: fft-coverage.o
-
-solvers-chol: solvers-chol.o
-
-solvers-lu: solvers-lu.o
-
-solvers-qr: solvers-qr.o
-
-solvers-covsol: solvers-covsol.o
-
-vector: vector.o
-
-vector-math: vector-math.o
-
-vector-const: vector-const.o
-
-dim-order: dim-order.o
-
-view-math: view-math.o
-
-regr-1: regr-1.o
-regr-2: regr-2.o
-
-# Run all the unit tests.
-check: all
-	./complex && ./dense && ./math && ./math-matvec && \
-	./math-reductions && ./math-scalarview && \
-	./matrix && ./matrix-math && ./matrix-const && \
-	./random && ./selgen && \
-	./signal && ./signal-convolution && ./signal-correlation && \
-	./signal-fft && ./signal-fir && \
-	./signal-histogram && ./signal-windows && \
-	./solvers-chol && ./solvers-lu && \
-	./solvers-qr && \
-	./vector && ./vector-math && ./vector-const \
-	./dim-order && ./view-math
-
-# Remove unnecessary files.
-clean:
-	-rm -f *.o *.s *.ii
-
-realclean: clean
-	-rm -f $(UNIT_TESTS)
Index: configure.ac
===================================================================
--- configure.ac	(revision 181512)
+++ configure.ac	(working copy)
@@ -1999,7 +1999,8 @@
 if test "$ref_impl" = "1"; then
   if test "$with_lapack" == "probe"; then
     with_lapack="no"
-  else
+  fi
+  if test "$with_lapack" != "no"; then
     AC_MSG_ERROR([Cannot use LAPACK with reference implementation.])
   fi
 fi
