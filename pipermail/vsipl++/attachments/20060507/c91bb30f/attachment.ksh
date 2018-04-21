Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.454
diff -u -r1.454 ChangeLog
--- ChangeLog	7 May 2006 17:13:51 -0000	1.454
+++ ChangeLog	7 May 2006 18:23:26 -0000
@@ -1,5 +1,12 @@
 2006-05-07  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/impl/extdata.hpp: Redefine SYNC_IN_NOPRESERVE in
+	  terms of SYNC_NOPRESERVE_impl.
+	* src/vsip/impl/rt_extdata.hpp: Force copy when SYNC_IN_NOPRESERVE.
+	* tests/rt_extdata.cpp: Test SYNC_IN_NOPRESERVE.
+	
+2006-05-07  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/impl/rt_extdata.hpp (block_layout): New function,
 	  construct Rt_layout corresponding to a block.  Fix bug with
 	  hard-coded dimensions.
Index: src/vsip/impl/extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/extdata.hpp,v
retrieving revision 1.20
diff -u -r1.20 extdata.hpp
--- src/vsip/impl/extdata.hpp	6 May 2006 21:27:06 -0000	1.20
+++ src/vsip/impl/extdata.hpp	7 May 2006 18:23:26 -0000
@@ -93,16 +93,20 @@
 /// Enum to indicate data interface syncronization necessary for
 /// correctness.
 ///
-/// SYNC_IN    - syncronize data interface on creation,
-/// SYNC_OUT   - syncronize data interface on destruction,
-/// SYNC_INOUT - syncronize data interface on creation and destruction.
+/// SYNC_IN            - syncronize data interface on creation,
+/// SYNC_OUT           - syncronize data interface on destruction,
+/// SYNC_INOUT         - syncronize data interface on creation and destruction,
+/// SYNC_IN_NOPRESERVE - syncronize data interface on creation
+///                      with guarantee that changes are not preserved
+///                      (usually by forcing a copy).
 
 enum sync_action_type
 {
-  SYNC_IN            = 0x01,
-  SYNC_OUT           = 0x02,
-  SYNC_INOUT         = 0x03,
-  SYNC_IN_NOPRESERVE = 0x05
+  SYNC_IN              = 0x01,
+  SYNC_OUT             = 0x02,
+  SYNC_INOUT           = SYNC_IN | SYNC_OUT,		// 0x03
+  SYNC_NOPRESERVE_impl = 0x04,
+  SYNC_IN_NOPRESERVE   = SYNC_IN | SYNC_NOPRESERVE_impl	// 0x05
 };
 
 
Index: src/vsip/impl/rt_extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/rt_extdata.hpp,v
retrieving revision 1.2
diff -u -r1.2 rt_extdata.hpp
--- src/vsip/impl/rt_extdata.hpp	7 May 2006 17:13:51 -0000	1.2
+++ src/vsip/impl/rt_extdata.hpp	7 May 2006 18:23:26 -0000
@@ -321,8 +321,9 @@
   Rt_low_level_data_access(
     Block&                blk,
     Rt_layout<Dim> const& rtl,
+    bool                  no_preserve,
     raw_ptr_type          buffer = NULL)
-  : use_direct_(is_direct_ok(blk, rtl)),
+  : use_direct_(!no_preserve && is_direct_ok(blk, rtl)),
     app_layout_(rtl, extent<dim>(blk), sizeof(value_type)),
     storage_   (use_direct_ ? 0 : app_layout_.total_size(), rtl.complex, buffer)
   {}
@@ -400,7 +401,7 @@
 	      raw_ptr_type          buffer = 0 /*storage_type::null()*/)
     : blk_    (&block),
       rtl_    (rtl),
-      ext_    (block, rtl_, buffer),
+      ext_    (block, rtl_, sync & SYNC_NOPRESERVE_impl, buffer),
       sync_   (sync)
     { ext_.begin(blk_.get(), sync_ & SYNC_IN); }
 
@@ -409,8 +410,9 @@
 	      sync_action_type      sync,
 	      raw_ptr_type          buffer = 0 /*storage_type::null()*/)
     : blk_ (&const_cast<Block&>(block)),
-      rtl_    (rtl),
-      ext_ (const_cast<Block&>(block), rtl_, buffer),
+      rtl_ (rtl),
+      ext_ (const_cast<Block&>(block), rtl_,
+	    sync & SYNC_NOPRESERVE_impl, buffer),
       sync_(sync)
   {
     assert(sync != SYNC_OUT && sync != SYNC_INOUT);
Index: tests/rt_extdata.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/rt_extdata.cpp,v
retrieving revision 1.2
diff -u -r1.2 rt_extdata.cpp
--- tests/rt_extdata.cpp	7 May 2006 17:13:51 -0000	1.2
+++ tests/rt_extdata.cpp	7 May 2006 18:23:26 -0000
@@ -31,12 +31,14 @@
 using vsip::impl::Rt_ext_data;
 using vsip::impl::Applied_layout;
 using vsip::impl::Length;
+using vsip::impl::sync_action_type;
 
 using vsip::impl::stride_unit_dense;
 using vsip::impl::stride_unit_align;
 using vsip::impl::cmplx_inter_fmt;
 using vsip::impl::cmplx_split_fmt;
 using vsip::impl::SYNC_INOUT;
+using vsip::impl::SYNC_IN_NOPRESERVE;
 
 using vsip::impl::extent;
 
@@ -165,7 +167,8 @@
   rt_pack_type       pack,
   rt_complex_type    cformat,
   int                cost,
-  bool               alloc)
+  bool               alloc,
+  sync_action_type   sync)
 {
   assert(Dim == 2);
   length_type rows = dom[0].size();
@@ -198,7 +201,7 @@
   }
 
   {
-    Rt_ext_data<block_type> ext(mat.block(), rt_layout, SYNC_INOUT, buffer);
+    Rt_ext_data<block_type> ext(mat.block(), rt_layout, sync, buffer);
 
 #if VERBOSE
     std::cout << "-----------------------------------------------" << std::endl;
@@ -253,10 +256,18 @@
   if (alloc)
     delete[] buffer;
 
-  for (index_type r=0; r<rows; ++r)
-    for (index_type c=0; c<cols; ++c)
-      test_assert(equal(mat.get(r, c), T(100*c + r)));
-
+  if (sync == SYNC_INOUT)
+  {
+    for (index_type r=0; r<rows; ++r)
+      for (index_type c=0; c<cols; ++c)
+	test_assert(equal(mat.get(r, c), T(100*c + r)));
+  }
+  else if (sync == SYNC_IN_NOPRESERVE)
+  {
+    for (index_type r=0; r<rows; ++r)
+      for (index_type c=0; c<cols; ++c)
+	test_assert(equal(mat.get(r, c), T(100*r + c)));
+  }
 }
 			
 
@@ -290,30 +301,54 @@
   rt_complex_type cif_v = cmplx_inter_fmt;
   rt_complex_type csf_v = cmplx_split_fmt;
 
+  sync_action_type sio = SYNC_INOUT;
+  sync_action_type sin = SYNC_IN_NOPRESERVE;
+
   t_rtex<T, Layout<2, r2_t, sud_t, cif_t> >(d, r2_v, sud_v, 0, a);
   t_rtex<T, Layout<2, r2_t, sud_t, cif_t> >(d, c2_v, sud_v, 2, a);
   t_rtex<T, Layout<2, c2_t, sud_t, cif_t> >(d, r2_v, sud_v, 2, a);
   t_rtex<T, Layout<2, c2_t, sud_t, cif_t> >(d, c2_v, sud_v, 0, a);
 
-  t_rtex_c<CT, Layout<2, r2_t, sud_t, cif_t> > (d, r2_v, sud_v, cif_v, 0, a);
-  t_rtex_c<CT, Layout<2, r2_t, sud_t, cif_t> > (d, c2_v, sud_v, cif_v, 2, a);
-  t_rtex_c<CT, Layout<2, r2_t, sud_t, cif_t> > (d, r2_v, sud_v, csf_v, 2, a);
-  t_rtex_c<CT, Layout<2, r2_t, sud_t, cif_t> > (d, c2_v, sud_v, csf_v, 2, a);
-
-  t_rtex_c<CT, Layout<2, r2_t, sud_t, csf_t> > (d, r2_v, sud_v, cif_v, 2, a);
-  t_rtex_c<CT, Layout<2, r2_t, sud_t, csf_t> > (d, c2_v, sud_v, cif_v, 2, a);
-  t_rtex_c<CT, Layout<2, r2_t, sud_t, csf_t> > (d, r2_v, sud_v, csf_v, 0, a);
-  t_rtex_c<CT, Layout<2, r2_t, sud_t, csf_t> > (d, c2_v, sud_v, csf_v, 2, a);
-
-  t_rtex_c<CT, Layout<2, c2_t, sud_t, cif_t> > (d, r2_v, sud_v, cif_v, 2, a);
-  t_rtex_c<CT, Layout<2, c2_t, sud_t, cif_t> > (d, c2_v, sud_v, cif_v, 0, a);
-  t_rtex_c<CT, Layout<2, c2_t, sud_t, cif_t> > (d, r2_v, sud_v, csf_v, 2, a);
-  t_rtex_c<CT, Layout<2, c2_t, sud_t, cif_t> > (d, c2_v, sud_v, csf_v, 2, a);
-
-  t_rtex_c<CT, Layout<2, c2_t, sud_t, csf_t> > (d, r2_v, sud_v, cif_v, 2, a);
-  t_rtex_c<CT, Layout<2, c2_t, sud_t, csf_t> > (d, c2_v, sud_v, cif_v, 2, a);
-  t_rtex_c<CT, Layout<2, c2_t, sud_t, csf_t> > (d, r2_v, sud_v, csf_v, 2, a);
-  t_rtex_c<CT, Layout<2, c2_t, sud_t, csf_t> > (d, c2_v, sud_v, csf_v, 0, a);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,r2_v,sud_v,cif_v,0,a,sio);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,c2_v,sud_v,cif_v,2,a,sio);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,r2_v,sud_v,csf_v,2,a,sio);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,c2_v,sud_v,csf_v,2,a,sio);
+
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,r2_v,sud_v,cif_v,2,a,sio);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,c2_v,sud_v,cif_v,2,a,sio);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,r2_v,sud_v,csf_v,0,a,sio);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,c2_v,sud_v,csf_v,2,a,sio);
+
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,r2_v,sud_v,cif_v,2,a,sio);
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,c2_v,sud_v,cif_v,0,a,sio);
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,r2_v,sud_v,csf_v,2,a,sio);
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,c2_v,sud_v,csf_v,2,a,sio);
+
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,r2_v,sud_v,cif_v,2,a,sio);
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,c2_v,sud_v,cif_v,2,a,sio);
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,r2_v,sud_v,csf_v,2,a,sio);
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,c2_v,sud_v,csf_v,0,a,sio);
+
+
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,r2_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,c2_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,r2_v,sud_v,csf_v,2,a,sin);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,cif_t> > (d,c2_v,sud_v,csf_v,2,a,sin);
+
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,r2_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,c2_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,r2_v,sud_v,csf_v,2,a,sin);
+  t_rtex_c<CT, Layout<2,r2_t,sud_t,csf_t> > (d,c2_v,sud_v,csf_v,2,a,sin);
+
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,r2_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,c2_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,r2_v,sud_v,csf_v,2,a,sin);
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,cif_t> > (d,c2_v,sud_v,csf_v,2,a,sin);
+
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,r2_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,c2_v,sud_v,cif_v,2,a,sin);
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,r2_v,sud_v,csf_v,2,a,sin);
+  t_rtex_c<CT, Layout<2,c2_t,sud_t,csf_t> > (d,c2_v,sud_v,csf_v,2,a,sin);
 }
 
 
@@ -323,9 +358,14 @@
 {
   vsipl init(argc, argv);
 
-  test<short>(Domain<2>(4, 8), true);
-  test<int>(Domain<2>(4, 8), true);
-  test<float>(Domain<2>(4, 8), true);
+  test<short>(Domain<2>(4, 8),  true);
+  test<int>(Domain<2>(4, 8),    true);
+  test<float>(Domain<2>(4, 8),  true);
   test<double>(Domain<2>(4, 8), true);
+
+  test<short>(Domain<2>(4, 8),  false);
+  test<int>(Domain<2>(4, 8),    false);
+  test<float>(Domain<2>(4, 8),  false);
+  test<double>(Domain<2>(4, 8), false);
 }
 
