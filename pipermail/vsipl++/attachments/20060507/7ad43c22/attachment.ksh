Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.456
diff -u -r1.456 ChangeLog
--- ChangeLog	7 May 2006 19:51:33 -0000	1.456
+++ ChangeLog	7 May 2006 19:53:45 -0000
@@ -1,5 +1,12 @@
 2006-05-07  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/impl/rt_extdata.hpp: Make data, stride, size, and
+	  cost member functions const.
+	* tests/rt_extdata.cpp: Extend test coverage to Vector and
+	  Tensor views.
+
+2006-05-07  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/impl/extdata.hpp: Redefine SYNC_IN_NOPRESERVE in
 	  terms of SYNC_NOPRESERVE_impl.
 	* src/vsip/impl/rt_extdata.hpp: Force copy when SYNC_IN_NOPRESERVE.
Index: src/vsip/impl/rt_extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/rt_extdata.hpp,v
retrieving revision 1.3
diff -u -r1.3 rt_extdata.hpp
--- src/vsip/impl/rt_extdata.hpp	7 May 2006 19:51:33 -0000	1.3
+++ src/vsip/impl/rt_extdata.hpp	7 May 2006 19:53:45 -0000
@@ -347,11 +347,13 @@
 
   // Direct data acessors.
 public:
-  raw_ptr_type	data(Block* blk)
-  { return use_direct_ ? raw_ptr_type(blk->impl_data()) : storage_.data(); }
-  stride_type	stride(Block* blk, dimension_type d)
+  raw_ptr_type data(Block* blk) const
+    { return use_direct_ ? raw_ptr_type(blk->impl_data()) : storage_.data(); }
+
+  stride_type stride(Block* blk, dimension_type d) const
     { return use_direct_ ? blk->impl_stride(dim, d) : app_layout_.stride(d);  }
-  length_type	size  (Block* blk, dimension_type d)
+
+  length_type size(Block* blk, dimension_type d) const
     { return use_direct_ ? blk->size(dim, d) : blk->size(Block::dim, d); }
 
   // Member data.
@@ -424,11 +426,17 @@
 
   // Direct data acessors.
 public:
-  raw_ptr_type	data  ()                 { return ext_.data  (blk_.get()); }
-  stride_type	stride(dimension_type d) { return ext_.stride(blk_.get(), d); }
-  length_type	size  (dimension_type d) { return ext_.size  (blk_.get(), d); }
+  raw_ptr_type data() const
+    { return ext_.data(blk_.get()); }
+
+  stride_type  stride(dimension_type d) const
+    { return ext_.stride(blk_.get(), d); }
+
+  length_type  size(dimension_type d) const
+    { return ext_.size(blk_.get(), d); }
 
-  int           cost  ()                 { return ext_.cost(); }
+  int           cost  () const
+    { return ext_.cost(); }
 
   // Member data.
 private:
Index: tests/rt_extdata.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/rt_extdata.cpp,v
retrieving revision 1.3
diff -u -r1.3 rt_extdata.cpp
--- tests/rt_extdata.cpp	7 May 2006 19:51:33 -0000	1.3
+++ tests/rt_extdata.cpp	7 May 2006 19:53:46 -0000
@@ -18,6 +18,7 @@
 #include <vsip/impl/rt_extdata.hpp>
 
 #include "test.hpp"
+#include "util.hpp"
 
 using namespace vsip;
 
@@ -48,6 +49,36 @@
   Definitions
 ***********************************************************************/
 
+// Utility functions to return a unique value for each index in
+// a view.  Overloaded so that tests can work for any-dimension view.
+
+inline index_type value1(Index<1> const& idx) { return idx[0]; }
+inline index_type value1(Index<2> const& idx) { return 100*idx[0] + idx[1]; }
+inline index_type value1(Index<3> const& idx)
+{ return 10000*idx[0] + 100*idx[1] + idx[2]; }
+
+inline index_type value2(Index<1> const& idx) { return 2*idx[0]; }
+inline index_type value2(Index<2> const& idx) { return 100*idx[1] + idx[0]; }
+inline index_type value2(Index<3> const& idx)
+{ return 10000*idx[2] + 100*idx[0] + idx[1]; }
+
+
+template <dimension_type Dim,
+          typename       ExtDataT>
+inline stride_type
+offset(Index<Dim> const& idx,
+       ExtDataT const&   ext)
+{
+  stride_type off = stride_type();
+
+  for (dimension_type d=0; d<Dim; ++d)
+    off += idx[d] * ext.stride(d);
+
+  return off;
+}
+
+
+
 // Test that Rt_layout matches Layout.
 template <typename       LayoutT,
 	  dimension_type Dim>
@@ -96,9 +127,9 @@
   Rt_layout<Dim> blk_rtl = vsip::impl::block_layout<Dim>(mat.block());
   test_layout<LayoutT>(blk_rtl);
 
-  for (index_type r=0; r<rows; ++r)
-    for (index_type c=0; c<cols; ++c)
-      mat(r, c) = T(100*r + c);
+  Length<Dim> ext = impl::extent(dom);
+  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
+    put(mat, idx, T(100*idx[0] + idx[1]));
 
   Rt_layout<2>                  rt_layout;
 
@@ -170,18 +201,17 @@
   bool               alloc,
   sync_action_type   sync)
 {
-  assert(Dim == 2);
-  length_type rows = dom[0].size();
-  length_type cols = dom[1].size();
-  typedef impl::Fast_block<Dim, T, LayoutT> block_type;
-  Matrix<T, block_type> mat(rows, cols);
+  typedef impl::Fast_block<Dim, T, LayoutT>              block_type;
+  typedef typename impl::View_of_dim<Dim, T, block_type>::type view_type;
 
-  Rt_layout<Dim> blk_rtl = vsip::impl::block_layout<Dim>(mat.block());
+  view_type view = create_view<view_type>(dom);
+
+  Rt_layout<Dim> blk_rtl = vsip::impl::block_layout<Dim>(view.block());
   test_layout<LayoutT>(blk_rtl);
 
-  for (index_type r=0; r<rows; ++r)
-    for (index_type c=0; c<cols; ++c)
-      mat(r, c) = T(100*r + c);
+  Length<Dim> len = impl::extent(dom);
+  for (Index<Dim> idx; valid(len, idx); next(len, idx))
+    put(view, idx, T(value1(idx)));
 
   Rt_layout<Dim> rt_layout;
 
@@ -194,14 +224,13 @@
   T* buffer = 0;
   if (alloc)
   {
-    vsip::impl::Length<Dim> ext = extent<Dim>(mat.block());
-    Applied_layout<Rt_layout<Dim> > app_layout(rt_layout, ext, sizeof(T));
-    length_type size = app_layout.total_size();
-    buffer = new T[size];
+    Applied_layout<Rt_layout<Dim> > app_layout(rt_layout, len, sizeof(T));
+    length_type total_size = app_layout.total_size();
+    buffer = new T[total_size];
   }
 
   {
-    Rt_ext_data<block_type> ext(mat.block(), rt_layout, sync, buffer);
+    Rt_ext_data<block_type> ext(view.block(), rt_layout, sync, buffer);
 
 #if VERBOSE
     std::cout << "-----------------------------------------------" << std::endl;
@@ -220,12 +249,10 @@
       if (alloc && cost != 0)
 	test_assert(ptr == buffer);
 
-      for (index_type r=0; r<rows; ++r)
-	for (index_type c=0; c<cols; ++c)
-	{
-	  test_assert(equal(ptr[r*ext.stride(0) + c*ext.stride(1)],
-			    mat.get(r, c)));
-	  ptr[r*ext.stride(0) + c*ext.stride(1)] = T(100*c + r);
+      for (Index<Dim> idx; valid(len,idx); next(len, idx))
+      {
+	test_assert(equal(ptr[offset(idx, ext)], get(view, idx)));
+	ptr[offset(idx, ext)] = T(value2(idx));
 	}
     }
     else /* rt_layout.complex == cmplx_split_fmt */
@@ -241,14 +268,11 @@
       if (alloc && cost != 0) 
 	test_assert(reinterpret_cast<T*>(ptr.first) == buffer);
 
-      for (index_type r=0; r<rows; ++r)
-	for (index_type c=0; c<cols; ++c)
-	{
-	  test_assert(
-	    equal(storage_type::get(ptr, r*ext.stride(0) + c*ext.stride(1)),
-		  mat.get(r, c)));
-	  storage_type::put(ptr, r*ext.stride(0) + c*ext.stride(1),
-			    T(100*c + r));
+      for (Index<Dim> idx; valid(len,idx); next(len, idx))
+      {
+	test_assert(
+	  equal(storage_type::get(ptr, offset(idx, ext)), get(view, idx)));
+	storage_type::put(ptr, offset(idx, ext), T(value2(idx)));
 	}
     }
   }
@@ -258,29 +282,24 @@
 
   if (sync == SYNC_INOUT)
   {
-    for (index_type r=0; r<rows; ++r)
-      for (index_type c=0; c<cols; ++c)
-	test_assert(equal(mat.get(r, c), T(100*c + r)));
+    for (Index<Dim> idx; valid(len,idx); next(len, idx))
+      test_assert(equal(get(view, idx), T(value2(idx))));
   }
   else if (sync == SYNC_IN_NOPRESERVE)
   {
-    for (index_type r=0; r<rows; ++r)
-      for (index_type c=0; c<cols; ++c)
-	test_assert(equal(mat.get(r, c), T(100*r + c)));
+    for (Index<Dim> idx; valid(len,idx); next(len, idx))
+      test_assert(equal(get(view, idx), T(value1(idx))));
   }
 }
 			
 
-  
 
 template <typename T>
 void
-test(
+test_noncomplex(
   Domain<2> const& d,		// size of matrix
   bool             a)		// pre-allocate buffer or not.
 {
-  typedef complex<T> CT;
-
   using vsip::impl::Layout;
   using vsip::impl::Stride_unit_dense;
   using vsip::impl::Cmplx_inter_fmt;
@@ -294,6 +313,38 @@
   typedef Stride_unit_dense sud_t;
 
   typedef Cmplx_inter_fmt cif_t;
+
+  rt_pack_type sud_v = stride_unit_dense;
+
+  t_rtex<T, Layout<2, r2_t, sud_t, cif_t> >(d, r2_v, sud_v, 0, a);
+  t_rtex<T, Layout<2, r2_t, sud_t, cif_t> >(d, c2_v, sud_v, 2, a);
+  t_rtex<T, Layout<2, c2_t, sud_t, cif_t> >(d, r2_v, sud_v, 2, a);
+  t_rtex<T, Layout<2, c2_t, sud_t, cif_t> >(d, c2_v, sud_v, 0, a);
+}
+  
+
+template <typename       T,
+	  dimension_type D>
+void
+test(
+  Domain<D> const& d,		// size of matrix
+  bool             a)		// pre-allocate buffer or not.
+{
+  typedef complex<T> CT;
+
+  using vsip::impl::Layout;
+  using vsip::impl::Stride_unit_dense;
+  using vsip::impl::Cmplx_inter_fmt;
+
+  typedef typename impl::Row_major<D>::type r_t;
+  typedef typename impl::Col_major<D>::type c_t;
+
+  Rt_tuple r_v = Rt_tuple(r_t());
+  Rt_tuple c_v = Rt_tuple(c_t());
+
+  typedef Stride_unit_dense sud_t;
+
+  typedef Cmplx_inter_fmt cif_t;
   typedef Cmplx_split_fmt csf_t;
 
   rt_pack_type sud_v = stride_unit_dense;
@@ -304,51 +355,72 @@
   sync_action_type sio = SYNC_INOUT;
   sync_action_type sin = SYNC_IN_NOPRESERVE;
 
-  t_rtex<T, Layout<2, r2_t, sud_t, cif_t> >(d, r2_v, sud_v, 0, a);
-  t_rtex<T, Layout<2, r2_t, sud_t, cif_t> >(d, c2_v, sud_v, 2, a);
-  t_rtex<T, Layout<2, c2_t, sud_t, cif_t> >(d, r2_v, sud_v, 2, a);
-  t_rtex<T, Layout<2, c2_t, sud_t, cif_t> >(d, c2_v, sud_v, 0, a);
+  // SYNC_IN_OUT cases --------------------------------------------------
+
+  t_rtex_c<CT, Layout<D,r_t,sud_t,cif_t> > (d,r_v,sud_v,cif_v,0,a,sio);
+  t_rtex_c<CT, Layout<D,r_t,sud_t,cif_t> > (d,r_v,sud_v,csf_v,2,a,sio);
+  t_rtex_c<CT, Layout<D,r_t,sud_t,csf_t> > (d,r_v,sud_v,cif_v,2,a,sio);
+  t_rtex_c<CT, Layout<D,r_t,sud_t,csf_t> > (d,r_v,sud_v,csf_v,0,a,sio);
+
+  if (D > 1)
+  {
+  // These tests only make sense if r_t and c_t are different.
+  t_rtex_c<CT, Layout<D,r_t,sud_t,cif_t> > (d,c_v,sud_v,cif_v,2,a,sio);
+  t_rtex_c<CT, Layout<D,r_t,sud_t,cif_t> > (d,c_v,sud_v,csf_v,2,a,sio);
+  t_rtex_c<CT, Layout<D,r_t,sud_t,csf_t> > (d,c_v,sud_v,cif_v,2,a,sio);
+  t_rtex_c<CT, Layout<D,r_t,sud_t,csf_t> > (d,c_v,sud_v,csf_v,2,a,sio);
+
+  t_rtex_c<CT, Layout<D,c_t,sud_t,cif_t> > (d,c_v,sud_v,cif_v,0,a,sio);
+  t_rtex_c<CT, Layout<D,c_t,sud_t,cif_t> > (d,c_v,sud_v,csf_v,2,a,sio);
+  t_rtex_c<CT, Layout<D,c_t,sud_t,csf_t> > (d,c_v,sud_v,cif_v,2,a,sio);
+  t_rtex_c<CT, Layout<D,c_t,sud_t,csf_t> > (d,c_v,sud_v,csf_v,0,a,sio);
+
+  t_rtex_c<CT, Layout<D,c_t,sud_t,cif_t> > (d,r_v,sud_v,cif_v,2,a,sio);
+  t_rtex_c<CT, Layout<D,c_t,sud_t,cif_t> > (d,r_v,sud_v,csf_v,2,a,sio);
+  t_rtex_c<CT, Layout<D,c_t,sud_t,csf_t> > (d,r_v,sud_v,cif_v,2,a,sio);
+  t_rtex_c<CT, Layout<D,c_t,sud_t,csf_t> > (d,r_v,sud_v,csf_v,2,a,sio);
+  }
+
+
+  // SYNC_IN_NOPRESERVE cases -------------------------------------------
+
+  t_rtex_c<CT, Layout<D,r_t,sud_t,cif_t> > (d,r_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<D,r_t,sud_t,cif_t> > (d,r_v,sud_v,csf_v,2,a,sin);
+  t_rtex_c<CT, Layout<D,r_t,sud_t,csf_t> > (d,r_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<D,r_t,sud_t,csf_t> > (d,r_v,sud_v,csf_v,2,a,sin);
+
+  if (D > 1)
+  {
+  // These tests only make sense if r_t and c_t are different.
+  t_rtex_c<CT, Layout<D,r_t,sud_t,cif_t> > (d,c_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<D,r_t,sud_t,cif_t> > (d,c_v,sud_v,csf_v,2,a,sin);
+  t_rtex_c<CT, Layout<D,r_t,sud_t,csf_t> > (d,c_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<D,r_t,sud_t,csf_t> > (d,c_v,sud_v,csf_v,2,a,sin);
+
+  t_rtex_c<CT, Layout<D,c_t,sud_t,cif_t> > (d,c_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<D,c_t,sud_t,cif_t> > (d,c_v,sud_v,csf_v,2,a,sin);
+  t_rtex_c<CT, Layout<D,c_t,sud_t,csf_t> > (d,c_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<D,c_t,sud_t,csf_t> > (d,c_v,sud_v,csf_v,2,a,sin);
+
+  t_rtex_c<CT, Layout<D,c_t,sud_t,cif_t> > (d,r_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<D,c_t,sud_t,cif_t> > (d,r_v,sud_v,csf_v,2,a,sin);
+  t_rtex_c<CT, Layout<D,c_t,sud_t,csf_t> > (d,r_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<D,c_t,sud_t,csf_t> > (d,r_v,sud_v,csf_v,2,a,sin);
+  }
+}
+
 
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,r2_v,sud_v,cif_v,0,a,sio);
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,c2_v,sud_v,cif_v,2,a,sio);
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,r2_v,sud_v,csf_v,2,a,sio);
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,c2_v,sud_v,csf_v,2,a,sio);
-
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,r2_v,sud_v,cif_v,2,a,sio);
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,c2_v,sud_v,cif_v,2,a,sio);
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,r2_v,sud_v,csf_v,0,a,sio);
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,c2_v,sud_v,csf_v,2,a,sio);
-
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,r2_v,sud_v,cif_v,2,a,sio);
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,c2_v,sud_v,cif_v,0,a,sio);
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,r2_v,sud_v,csf_v,2,a,sio);
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,c2_v,sud_v,csf_v,2,a,sio);
-
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,r2_v,sud_v,cif_v,2,a,sio);
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,c2_v,sud_v,cif_v,2,a,sio);
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,r2_v,sud_v,csf_v,2,a,sio);
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,c2_v,sud_v,csf_v,0,a,sio);
-
-
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,r2_v,sud_v,cif_v,2,a,sin);
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,c2_v,sud_v,cif_v,2,a,sin);
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,r2_v,sud_v,csf_v,2,a,sin);
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,c2_v,sud_v,csf_v,2,a,sin);
-
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,r2_v,sud_v,cif_v,2,a,sin);
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,c2_v,sud_v,cif_v,2,a,sin);
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,r2_v,sud_v,csf_v,2,a,sin);
-  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,c2_v,sud_v,csf_v,2,a,sin);
-
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,r2_v,sud_v,cif_v,2,a,sin);
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,c2_v,sud_v,cif_v,2,a,sin);
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,r2_v,sud_v,csf_v,2,a,sin);
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,c2_v,sud_v,csf_v,2,a,sin);
-
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,r2_v,sud_v,cif_v,2,a,sin);
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,c2_v,sud_v,cif_v,2,a,sin);
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,r2_v,sud_v,csf_v,2,a,sin);
-  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,c2_v,sud_v,csf_v,2,a,sin);
+
+template <dimension_type D>
+void
+test_types(Domain<D> const& dom, bool alloc)
+{
+  test<float> (dom, alloc);
+#if VSIP_IMPL_TEST_LEVEL > 0
+  test<short> (dom, alloc);
+  test<int>   (dom, alloc);
+  test<double>(dom, alloc);
+#endif
 }
 
 
@@ -358,14 +430,16 @@
 {
   vsipl init(argc, argv);
 
-  test<short>(Domain<2>(4, 8),  true);
-  test<int>(Domain<2>(4, 8),    true);
-  test<float>(Domain<2>(4, 8),  true);
-  test<double>(Domain<2>(4, 8), true);
-
-  test<short>(Domain<2>(4, 8),  false);
-  test<int>(Domain<2>(4, 8),    false);
-  test<float>(Domain<2>(4, 8),  false);
-  test<double>(Domain<2>(4, 8), false);
+  test_noncomplex<float>(Domain<2>(4, 8), true);
+  test_noncomplex<float>(Domain<2>(4, 8), false);
+
+  test_types(Domain<1>(4), true);
+  test_types(Domain<1>(4), false);
+
+  test_types(Domain<2>(4, 8), true);
+  test_types(Domain<2>(4, 8), false);
+
+  test_types(Domain<3>(6, 8, 12), true);
+  test_types(Domain<3>(6, 8, 12), false);
 }
 
