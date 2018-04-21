Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.461
diff -u -r1.461 ChangeLog
--- ChangeLog	9 May 2006 11:24:48 -0000	1.461
+++ ChangeLog	9 May 2006 16:43:23 -0000
@@ -1,3 +1,10 @@
+2006-05-09  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/block-copy.hpp: Remove assertions on complex_format
+	  when value_type is non-complex.
+       * src/vsip/impl/rt_extdata.hpp: Ignore complex format when
+         checking if non-compelx data can be directly accessed.
+	* src/vsip/impl/rt_extdata.hpp: Test accessing non-complex data
+	  in split format.
+
 2006-05-08  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac: Add AC_SUBST for VSIP_IMPL_FFTW3.
Index: src/vsip/impl/block-copy.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/block-copy.hpp,v
retrieving revision 1.13
diff -u -r1.13 block-copy.hpp
--- src/vsip/impl/block-copy.hpp	6 May 2006 21:27:06 -0000	1.13
+++ src/vsip/impl/block-copy.hpp	9 May 2006 16:43:23 -0000
@@ -182,7 +182,6 @@
 
   static void copy_in (Block* block, LP const& layout, rt_ptr_type data)
   {
-    assert(complex_format(layout) == cmplx_inter_fmt);
     copy_in(block, layout, data.as_inter());
   }
 
@@ -196,7 +195,6 @@
 
   static void copy_out(Block* block, LP const& layout, rt_ptr_type data)
   {
-    assert(complex_format(layout) == cmplx_inter_fmt);
     copy_out(block, layout, data.as_inter());
   }
 };
Index: src/vsip/impl/rt_extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/rt_extdata.hpp,v
retrieving revision 1.4
diff -u -r1.4 rt_extdata.hpp
--- src/vsip/impl/rt_extdata.hpp	7 May 2006 19:54:08 -0000	1.4
+++ src/vsip/impl/rt_extdata.hpp	9 May 2006 16:43:23 -0000
@@ -196,7 +196,8 @@
   dimension_type const dim1 = layout_nth_dim(block_layout, 1);
   dimension_type const dim2 = layout_nth_dim(block_layout, 2);
 
-  if (complex_format(block_layout) != complex_format(layout))
+  if (Is_complex<value_type>::value &&
+      complex_format(block_layout) != complex_format(layout))
     return false;
 
   for (dimension_type d=0; d<dim; ++d)
Index: tests/rt_extdata.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/rt_extdata.cpp,v
retrieving revision 1.4
diff -u -r1.4 rt_extdata.cpp
--- tests/rt_extdata.cpp	7 May 2006 19:54:08 -0000	1.4
+++ tests/rt_extdata.cpp	9 May 2006 16:43:23 -0000
@@ -116,43 +116,45 @@
   Domain<Dim> const& dom,
   Rt_tuple           order,
   rt_pack_type       pack,
-  int                cost,
-  bool               alloc)
+  rt_complex_type    cformat,
+  bool               alloc,
+  sync_action_type   sync,
+  int                cost)
 {
-  length_type rows = dom[0].size();
-  length_type cols = dom[1].size();
   typedef impl::Fast_block<Dim, T, LayoutT> block_type;
-  Matrix<T, block_type> mat(rows, cols);
+  typedef typename impl::View_of_dim<Dim, T, block_type>::type view_type;
+
+  view_type view = create_view<view_type>(dom);
 
-  Rt_layout<Dim> blk_rtl = vsip::impl::block_layout<Dim>(mat.block());
+  Rt_layout<Dim> blk_rtl = vsip::impl::block_layout<Dim>(view.block());
   test_layout<LayoutT>(blk_rtl);
 
-  Length<Dim> ext = impl::extent(dom);
-  for (Index<Dim> idx; valid(ext,idx); next(ext, idx))
-    put(mat, idx, T(100*idx[0] + idx[1]));
+  Length<Dim> len = impl::extent(dom);
+  for (Index<Dim> idx; valid(len, idx); next(len, idx))
+    put(view, idx, T(value1(idx)));
 
-  Rt_layout<2>                  rt_layout;
+  Rt_layout<Dim> rt_layout;
 
   rt_layout.pack    = pack;
   rt_layout.order   = order; 
-  rt_layout.complex = cmplx_inter_fmt;
+  rt_layout.complex = cformat;
   rt_layout.align   = (pack == stride_unit_align) ? 16 : 0;
 
   // Pre-allocate temporary buffer.
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
-    Rt_ext_data<block_type> ext(mat.block(), rt_layout, SYNC_INOUT, buffer);
+    Rt_ext_data<block_type> ext(view.block(), rt_layout, SYNC_INOUT, buffer);
 
     T* ptr = ext.data().as_inter();
 
+    test_assert(cost == ext.cost());
     if (alloc && cost != 0)
       test_assert(ptr == buffer);
 
@@ -164,23 +166,27 @@
       std::cout << i << ": " << ptr[i] << std::endl;
 #endif
 
-    test_assert(cost == ext.cost());
 
-    for (index_type r=0; r<rows; ++r)
-      for (index_type c=0; c<cols; ++c)
-      {
-	test_assert(equal(ptr[r*ext.stride(0) + c*ext.stride(1)],
-			  mat.get(r, c)));
-	ptr[r*ext.stride(0) + c*ext.stride(1)] = T(100*c + r);
-      }
+    for (Index<Dim> idx; valid(len,idx); next(len, idx))
+    {
+      test_assert(equal(ptr[offset(idx, ext)], get(view, idx)));
+      ptr[offset(idx, ext)] = T(value2(idx));
+    }
   }
 
   if (alloc)
     delete[] buffer;
 
-  for (index_type r=0; r<rows; ++r)
-    for (index_type c=0; c<cols; ++c)
-      test_assert(equal(mat.get(r, c), T(100*c + r)));
+  if (sync == SYNC_INOUT)
+  {
+    for (Index<Dim> idx; valid(len,idx); next(len, idx))
+      test_assert(equal(get(view, idx), T(value2(idx))));
+  }
+  else if (sync == SYNC_IN_NOPRESERVE)
+  {
+    for (Index<Dim> idx; valid(len,idx); next(len, idx))
+      test_assert(equal(get(view, idx), T(value1(idx))));
+  }
 }
 
 
@@ -253,7 +259,7 @@
       {
 	test_assert(equal(ptr[offset(idx, ext)], get(view, idx)));
 	ptr[offset(idx, ext)] = T(value2(idx));
-	}
+      }
     }
     else /* rt_layout.complex == cmplx_split_fmt */
     {
@@ -304,22 +310,41 @@
   using vsip::impl::Stride_unit_dense;
   using vsip::impl::Cmplx_inter_fmt;
 
+  Rt_tuple r1_v = Rt_tuple(row1_type());
   Rt_tuple r2_v = Rt_tuple(row2_type());
   Rt_tuple c2_v = Rt_tuple(col2_type());
 
+  typedef row1_type r1_t;
   typedef row2_type r2_t;
   typedef col2_type c2_t;
 
   typedef Stride_unit_dense sud_t;
 
   typedef Cmplx_inter_fmt cif_t;
+  typedef Cmplx_split_fmt csf_t;
+
+  rt_complex_type cif_v = cmplx_inter_fmt;
+  rt_complex_type csf_v = cmplx_split_fmt;
 
   rt_pack_type sud_v = stride_unit_dense;
 
-  t_rtex<T, Layout<2, r2_t, sud_t, cif_t> >(d, r2_v, sud_v, 0, a);
-  t_rtex<T, Layout<2, r2_t, sud_t, cif_t> >(d, c2_v, sud_v, 2, a);
-  t_rtex<T, Layout<2, c2_t, sud_t, cif_t> >(d, r2_v, sud_v, 2, a);
-  t_rtex<T, Layout<2, c2_t, sud_t, cif_t> >(d, c2_v, sud_v, 0, a);
+  sync_action_type sio = SYNC_INOUT;
+  // sync_action_type sin = SYNC_IN_NOPRESERVE;
+
+  Domain<1> d1(d[0]);
+
+  // Ask for cmplx_inter_fmt
+  t_rtex<T, Layout<1,r1_t,sud_t,cif_t> >(d1,r1_v,sud_v,cif_v,a,sio,0);
+  t_rtex<T, Layout<1,r1_t,sud_t,csf_t> >(d1,r1_v,sud_v,cif_v,a,sio,0);
+
+  // Check that cmplx_split_fmt is ignored since type is non-complex.
+  t_rtex<T, Layout<1,r1_t,sud_t,cif_t> >(d1,r1_v,sud_v,csf_v,a,sio,0);
+  t_rtex<T, Layout<1,r1_t,sud_t,csf_t> >(d1,r1_v,sud_v,csf_v,a,sio,0);
+
+  t_rtex<T, Layout<2,r2_t,sud_t,cif_t> >(d,r2_v,sud_v,cif_v,a,sio,0);
+  t_rtex<T, Layout<2,r2_t,sud_t,cif_t> >(d,c2_v,sud_v,cif_v,a,sio,2);
+  t_rtex<T, Layout<2,c2_t,sud_t,cif_t> >(d,r2_v,sud_v,cif_v,a,sio,2);
+  t_rtex<T, Layout<2,c2_t,sud_t,cif_t> >(d,c2_v,sud_v,cif_v,a,sio,0);
 }
   
 
