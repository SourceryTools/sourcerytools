Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.453
diff -u -r1.453 ChangeLog
--- ChangeLog	6 May 2006 23:17:56 -0000	1.453
+++ ChangeLog	7 May 2006 17:13:14 -0000
@@ -1,3 +1,10 @@
+2006-05-07  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/rt_extdata.hpp (block_layout): New function,
+	  construct Rt_layout corresponding to a block.  Fix bug with
+	  hard-coded dimensions.
+	* tests/rt_extdata.cpp: Test block_layout.
+
 2006-05-06  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* configure.ac: Allow multiple FFT backends.
Index: src/vsip/impl/rt_extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/rt_extdata.hpp,v
retrieving revision 1.1
diff -u -r1.1 rt_extdata.hpp
--- src/vsip/impl/rt_extdata.hpp	6 May 2006 21:27:06 -0000	1.1
+++ src/vsip/impl/rt_extdata.hpp	7 May 2006 17:13:14 -0000
@@ -28,6 +28,17 @@
 namespace impl
 {
 
+template <typename ComplexType>
+inline rt_complex_type
+complex_format()
+{
+  if (Type_equal<ComplexType, Cmplx_inter_fmt>::value)
+    return cmplx_inter_fmt;
+  else
+    return cmplx_split_fmt;
+}
+
+
 template <dimension_type D,
 	  typename       Order,
 	  typename       PackType,
@@ -35,10 +46,7 @@
 inline rt_complex_type
 complex_format(Layout<D, Order, PackType, ComplexType>)
 {
-  if (Type_equal<ComplexType, Cmplx_inter_fmt>::value)
-    return cmplx_inter_fmt;
-  else
-    return cmplx_split_fmt;
+  return complex_format<ComplexType>();
 }
 
 
@@ -61,12 +69,9 @@
 
 
 
-template <dimension_type D,
-	  typename       Order,
-	  typename       PackType,
-	  typename	 ComplexType>
+template <typename PackType>
 inline rt_pack_type
-pack_format(Layout<D, Order, PackType, ComplexType>)
+pack_format()
 {
   if      (Type_equal<PackType, Stride_unknown>::value)
     return stride_unknown;
@@ -78,6 +83,16 @@
     return stride_unit_align;
 }
 
+template <dimension_type D,
+	  typename       Order,
+	  typename       PackType,
+	  typename	 ComplexType>
+inline rt_pack_type
+pack_format(Layout<D, Order, PackType, ComplexType>)
+{
+  return pack_format<PackType>();
+}
+
 
 
 template <dimension_type D>
@@ -136,6 +151,28 @@
 
 
 
+template <dimension_type D,
+	  typename       Block>
+inline Rt_layout<D>
+block_layout(Block const&)
+{
+  Rt_layout<D> rtl;
+
+  typedef typename Block_layout<Block>::access_type  access_type;
+  typedef typename Block_layout<Block>::order_type   order_type;
+  typedef typename Block_layout<Block>::pack_type    pack_type;
+  typedef typename Block_layout<Block>::complex_type complex_type;
+
+  rtl.pack    = pack_format<pack_type>();
+  rtl.order   = Rt_tuple(order_type());
+  rtl.complex = complex_format<complex_type>();
+  rtl.align   = Is_stride_unit_align<pack_type>::align;
+
+  return rtl;
+}
+
+
+
 namespace data_access
 {
 
@@ -296,13 +333,13 @@
   void begin(Block* blk, bool sync)
   {
     if (!use_direct_ && sync)
-      Rt_block_copy<2, Block>::copy_in(blk, app_layout_, storage_.data());
+      Rt_block_copy<Dim, Block>::copy_in(blk, app_layout_, storage_.data());
   }
 
   void end(Block* blk, bool sync)
   {
     if (!use_direct_ && sync)
-      Rt_block_copy<2, Block>::copy_out(blk, app_layout_, storage_.data());
+      Rt_block_copy<Dim, Block>::copy_out(blk, app_layout_, storage_.data());
   }
 
   int cost() const { return use_direct_ ? 0 : 2; }
@@ -336,7 +373,7 @@
 ///   RP is a reference counting policy.
 
 template <typename       Block,
-	  dimension_type Dim,
+	  dimension_type Dim = Block_layout<Block>::dim,
 	  typename       RP  = No_count_policy>
 class Rt_ext_data
 {
Index: tests/rt_extdata.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/rt_extdata.cpp,v
retrieving revision 1.1
diff -u -r1.1 rt_extdata.cpp
--- tests/rt_extdata.cpp	6 May 2006 21:27:06 -0000	1.1
+++ tests/rt_extdata.cpp	7 May 2006 17:13:14 -0000
@@ -46,24 +46,54 @@
   Definitions
 ***********************************************************************/
 
+// Test that Rt_layout matches Layout.
+template <typename       LayoutT,
+	  dimension_type Dim>
+void
+test_layout(Rt_layout<Dim> rtl)
+{
+  using vsip::impl::pack_format;
+  using vsip::impl::complex_format;
+  using vsip::impl::Is_stride_unit_align;
+
+  typedef typename LayoutT::pack_type pack_type;
+  typedef typename LayoutT::complex_type complex_type;
+  typedef typename LayoutT::order_type order_type;
+  typedef typename LayoutT::pack_type pack_type;
+
+  test_assert(rtl.dim     == LayoutT::dim);
+  test_assert(rtl.pack    == pack_format<pack_type>());
+  test_assert(rtl.complex == complex_format<complex_type>());
+  test_assert(rtl.order.impl_dim0 == LayoutT::order_type::impl_dim0);
+  test_assert(rtl.order.impl_dim1 == LayoutT::order_type::impl_dim1);
+  test_assert(rtl.order.impl_dim2 == LayoutT::order_type::impl_dim2);
+  test_assert(rtl.align == Is_stride_unit_align<pack_type>::align);
+}
+
+
+
 // Test run-time external data access (assuming that data is either
 // not complex or is interleaved-complex).
 
-template <typename T,
-	  typename LayoutT>
+template <typename       T,
+	  typename       LayoutT,
+	  dimension_type Dim>
 void
 t_rtex(
-  Domain<2> const& dom,
-  Rt_tuple         order,
-  rt_pack_type     pack,
-  int              cost,
-  bool             alloc)
+  Domain<Dim> const& dom,
+  Rt_tuple           order,
+  rt_pack_type       pack,
+  int                cost,
+  bool               alloc)
 {
   length_type rows = dom[0].size();
   length_type cols = dom[1].size();
-  typedef impl::Fast_block<2, T, LayoutT> block_type;
+  typedef impl::Fast_block<Dim, T, LayoutT> block_type;
   Matrix<T, block_type> mat(rows, cols);
 
+  Rt_layout<Dim> blk_rtl = vsip::impl::block_layout<Dim>(mat.block());
+  test_layout<LayoutT>(blk_rtl);
+
   for (index_type r=0; r<rows; ++r)
     for (index_type c=0; c<cols; ++c)
       mat(r, c) = T(100*r + c);
@@ -79,14 +109,14 @@
   T* buffer = 0;
   if (alloc)
   {
-    vsip::impl::Length<2> ext = extent<2>(mat.block());
-    Applied_layout<Rt_layout<2> > app_layout(rt_layout, ext, sizeof(T));
+    vsip::impl::Length<Dim> ext = extent<Dim>(mat.block());
+    Applied_layout<Rt_layout<Dim> > app_layout(rt_layout, ext, sizeof(T));
     length_type size = app_layout.total_size();
     buffer = new T[size];
   }
 
   {
-    Rt_ext_data<block_type, 2> ext(mat.block(), rt_layout, SYNC_INOUT, buffer);
+    Rt_ext_data<block_type> ext(mat.block(), rt_layout, SYNC_INOUT, buffer);
 
     T* ptr = ext.data().as_inter();
 
@@ -125,27 +155,32 @@
 // Test run-time external data access (assuming that data is complex,
 // either interleaved or split).
 
-template <typename T,
-	  typename LayoutT>
+template <typename       T,
+	  typename       LayoutT,
+	  dimension_type Dim>
 void
 t_rtex_c(
-  Domain<2> const& dom,
-  Rt_tuple         order,
-  rt_pack_type     pack,
-  rt_complex_type  cformat,
-  int              cost,
-  bool             alloc)
+  Domain<Dim> const& dom,
+  Rt_tuple           order,
+  rt_pack_type       pack,
+  rt_complex_type    cformat,
+  int                cost,
+  bool               alloc)
 {
+  assert(Dim == 2);
   length_type rows = dom[0].size();
   length_type cols = dom[1].size();
-  typedef impl::Fast_block<2, T, LayoutT> block_type;
+  typedef impl::Fast_block<Dim, T, LayoutT> block_type;
   Matrix<T, block_type> mat(rows, cols);
 
+  Rt_layout<Dim> blk_rtl = vsip::impl::block_layout<Dim>(mat.block());
+  test_layout<LayoutT>(blk_rtl);
+
   for (index_type r=0; r<rows; ++r)
     for (index_type c=0; c<cols; ++c)
       mat(r, c) = T(100*r + c);
 
-  Rt_layout<2>                  rt_layout;
+  Rt_layout<Dim> rt_layout;
 
   rt_layout.pack    = pack;
   rt_layout.order   = order; 
@@ -156,14 +191,14 @@
   T* buffer = 0;
   if (alloc)
   {
-    vsip::impl::Length<2> ext = extent<2>(mat.block());
-    Applied_layout<Rt_layout<2> > app_layout(rt_layout, ext, sizeof(T));
+    vsip::impl::Length<Dim> ext = extent<Dim>(mat.block());
+    Applied_layout<Rt_layout<Dim> > app_layout(rt_layout, ext, sizeof(T));
     length_type size = app_layout.total_size();
     buffer = new T[size];
   }
 
   {
-    Rt_ext_data<block_type, 2> ext(mat.block(), rt_layout, SYNC_INOUT, buffer);
+    Rt_ext_data<block_type> ext(mat.block(), rt_layout, SYNC_INOUT, buffer);
 
 #if VERBOSE
     std::cout << "-----------------------------------------------" << std::endl;
