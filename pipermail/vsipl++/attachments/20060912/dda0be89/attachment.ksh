Index: src/vsip/impl/fft.hpp
===================================================================
--- src/vsip/impl/fft.hpp	(revision 149092)
+++ src/vsip/impl/fft.hpp	(working copy)
@@ -157,7 +157,7 @@
     VSIP_THROW((std::bad_alloc))
     : base(dom, scale, "Fft", S, by_value),
       backend_(factory::create(dom, scale)),
-      workspace_(this->input_size(), this->output_size(), scale)
+      workspace_(backend_.get(), this->input_size(), this->output_size(), scale)
   {}
 
   template <typename ViewT>
@@ -203,7 +203,7 @@
     VSIP_THROW((std::bad_alloc))
     : base(dom, scale, "Fft", S, by_reference),
       backend_(factory::create(dom, scale)),
-      workspace_(this->input_size(), this->output_size(), scale)
+      workspace_(backend_.get(), this->input_size(), this->output_size(), scale)
   {}
 
   template <typename Block0, typename Block1,
@@ -314,7 +314,7 @@
     VSIP_THROW((std::bad_alloc))
     : base(dom, scale, "Fftm", D, by_reference),
       backend_(factory::create(dom, scale)),
-      workspace_(this->input_size(), this->output_size(), scale)
+      workspace_(backend_.get(), this->input_size(), this->output_size(), scale)
   {}
 
   template <typename Block0, typename Block1>
Index: src/vsip/impl/fft/workspace.hpp
===================================================================
--- src/vsip/impl/fft/workspace.hpp	(revision 149092)
+++ src/vsip/impl/fft/workspace.hpp	(working copy)
@@ -43,46 +43,101 @@
 class workspace<1, std::complex<T>, std::complex<T> >
 {
 public:
-  workspace(Domain<1> const &in, Domain<1> const &out, T scale)
+  template <typename BE>
+  workspace(BE* backend, Domain<1> const &in, Domain<1> const &out, T scale)
     : scale_(scale),
       input_buffer_(in.size()),
       output_buffer_(out.size())
-  {}
+  {
+    // Check if Backend supports interleaved unit-stride fastpath:
+    {
+      Rt_layout<1> ref;
+      ref.pack    = stride_unit_dense;
+      ref.order   = Rt_tuple(row1_type());
+      ref.complex = cmplx_inter_fmt;
+      Rt_layout<1> rtl_in(ref);
+      Rt_layout<1> rtl_out(ref);
+      backend->query_layout(rtl_in, rtl_out);
+      this->inter_fastpath_ok_ = 
+	rtl_in.pack == ref.pack       && rtl_out.pack == ref.pack &&
+	// rtl_in.order == ref.order     && rtl_out.order == ref.order &&
+	rtl_in.complex == ref.complex && rtl_out.complex == ref.complex &&
+	!backend->requires_copy(rtl_in);
+    }
+    // Check if Backend supports split unit-stride fastpath:
+    {
+      Rt_layout<1> ref;
+      ref.pack    = stride_unit_dense;
+      ref.order   = Rt_tuple(row1_type());
+      ref.complex = cmplx_split_fmt;
+      Rt_layout<1> rtl_in(ref);
+      Rt_layout<1> rtl_out(ref);
+      backend->query_layout(rtl_in, rtl_out);
+      this->split_fastpath_ok_ = 
+	rtl_in.pack == ref.pack       && rtl_out.pack == ref.pack &&
+	// rtl_in.order == ref.order     && rtl_out.order == ref.order &&
+	rtl_in.complex == ref.complex && rtl_out.complex == ref.complex &&
+	!backend->requires_copy(rtl_in);
+    }
+  }
   
   template <typename BE, typename Block0, typename Block1>
   void by_reference(BE *backend,
-		    const_Vector<std::complex<T>, Block0> in,
-		    Vector<std::complex<T>, Block1> out)
+		    const_Vector<std::complex<T>, Block0>& in,
+		    Vector<std::complex<T>, Block1>& out)
   {
-    // Find out about the blocks's actual layout.
-    Rt_layout<1> rtl_in = block_layout<1>(in.block()); 
-    Rt_layout<1> rtl_out = block_layout<1>(out.block()); 
-    
-    // Find out about what layout is acceptable for this backend.
-    backend->query_layout(rtl_in, rtl_out);
+    typedef typename Block_layout<Block0>::complex_type complex_type;
+    typedef Layout<1, row1_type, Stride_unit, complex_type> LP;
 
-    // Check whether the input buffer will be destroyed.
-    sync_action_type in_sync = backend->requires_copy(rtl_in)
-      ? SYNC_IN_NOPRESERVE
-      : SYNC_IN; 
+    if (Ext_data_cost<Block0, LP>::value == 0 &&
+	Ext_data_cost<Block1, LP>::value == 0 &&
+	Type_equal<complex_type, Cmplx_inter_fmt>::value ?
+	  this->inter_fastpath_ok_ : this->split_fastpath_ok_)
+    {
+      // Fast-path (using CT Ext_data).
+      typedef typename Block_layout<Block0>::complex_type complex_type;
 
+      Ext_data<Block0, LP> in_ext (in.block(),  SYNC_IN);
+      Ext_data<Block1, LP> out_ext(out.block(), SYNC_OUT);
+
+      backend->by_reference(in_ext.data(),  1,
+			    out_ext.data(), 1,
+			    in_ext.size(0));
+    }
+    else
     {
-      // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync,
-				 input_buffer_.get());
-      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT,
-				  output_buffer_.get());
+      // General-path (using RT Ext_data).
+      // Find out about the blocks's actual layout.
+      Rt_layout<1> rtl_in = block_layout<1>(in.block()); 
+      Rt_layout<1> rtl_out = block_layout<1>(out.block()); 
     
-      // Call the backend.
-      assert(rtl_in.complex == rtl_out.complex);
-      if (rtl_in.complex == cmplx_inter_fmt) 
-	backend->by_reference(in_ext.data().as_inter(), in_ext.stride(0),
-			      out_ext.data().as_inter(), out_ext.stride(0),
-			      in_ext.size(0));
-      else
-	backend->by_reference(in_ext.data().as_split(), in_ext.stride(0),
-			      out_ext.data().as_split(), out_ext.stride(0),
-			      in_ext.size(0));
+      // Find out about what layout is acceptable for this backend.
+      backend->query_layout(rtl_in, rtl_out);
+
+      // Check whether the input buffer will be destroyed.
+      sync_action_type in_sync = backend->requires_copy(rtl_in)
+	? SYNC_IN_NOPRESERVE
+	: SYNC_IN; 
+
+      {
+	// Create a 'direct data accessor', adjusting the block layout if
+	// necessary.
+	Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync,
+				   input_buffer_.get());
+	Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT,
+				    output_buffer_.get());
+    
+	// Call the backend.
+	assert(rtl_in.complex == rtl_out.complex);
+	if (rtl_in.complex == cmplx_inter_fmt) 
+	  backend->by_reference(in_ext.data().as_inter(), in_ext.stride(0),
+				out_ext.data().as_inter(), out_ext.stride(0),
+				in_ext.size(0));
+	else
+	  backend->by_reference(in_ext.data().as_split(), in_ext.stride(0),
+				out_ext.data().as_split(), out_ext.stride(0),
+				in_ext.size(0));
+      }
     }
     // Scale the data if not already done by the backend.
     if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
@@ -119,13 +174,17 @@
   T scale_;
   aligned_array<std::complex<T> > input_buffer_;
   aligned_array<std::complex<T> > output_buffer_;
+  bool inter_fastpath_ok_;
+  bool split_fastpath_ok_;
 };
 
+
 template <typename T>
 class workspace<1, T, std::complex<T> >
 {
 public:
-  workspace(Domain<1> const &in, Domain<1> const &out, T scale)
+  template <typename BE>
+  workspace(BE*, Domain<1> const &in, Domain<1> const &out, T scale)
     : scale_(scale),
       input_buffer_(in.size()),
       output_buffer_(out.size())
@@ -179,7 +238,8 @@
 class workspace<1, std::complex<T>, T>
 {
 public:
-  workspace(Domain<1> const &in, Domain<1> const &out, T scale)
+  template <typename BE>
+  workspace(BE*, Domain<1> const &in, Domain<1> const &out, T scale)
     : scale_(scale),
       input_buffer_(in.size()),
       output_buffer_(out.size())
@@ -233,7 +293,8 @@
 class workspace<2, std::complex<T>, std::complex<T> >
 {
 public:
-  workspace(Domain<2> const &in, Domain<2> const &out, T scale)
+  template <typename BE>
+  workspace(BE*, Domain<2> const &in, Domain<2> const &out, T scale)
     : scale_(scale),
       input_buffer_(in.size()),
       output_buffer_(out.size())
@@ -320,7 +381,8 @@
 class workspace<2, T, std::complex<T> >
 {
 public:
-  workspace(Domain<2> const &in, Domain<2> const &out, T scale)
+  template <typename BE>
+  workspace(BE*, Domain<2> const &in, Domain<2> const &out, T scale)
     : scale_(scale),
       input_buffer_(in.size()),
       output_buffer_(out.size())
@@ -377,7 +439,8 @@
 class workspace<2, std::complex<T>, T >
 {
 public:
-  workspace(Domain<2> const &in, Domain<2> const &out, T scale)
+  template <typename BE>
+  workspace(BE*, Domain<2> const &in, Domain<2> const &out, T scale)
     : scale_(scale),
       input_buffer_(in.size()),
       output_buffer_(out.size())
@@ -434,7 +497,8 @@
 class workspace<3, std::complex<T>, std::complex<T> >
 {
 public:
-  workspace(Domain<3> const &in, Domain<3> const &out, T scale)
+  template <typename BE>
+  workspace(BE*, Domain<3> const &in, Domain<3> const &out, T scale)
     : scale_(scale),
       input_buffer_(in.size()),
       output_buffer_(out.size())
@@ -541,7 +605,8 @@
 class workspace<3, T, std::complex<T> >
 {
 public:
-  workspace(Domain<3> const &in, Domain<3> const &out, T scale)
+  template <typename BE>
+  workspace(BE*, Domain<3> const &in, Domain<3> const &out, T scale)
     : scale_(scale),
       input_buffer_(in.size()),
       output_buffer_(out.size())
@@ -610,7 +675,8 @@
 class workspace<3, std::complex<T>, T >
 {
 public:
-  workspace(Domain<3> const &in, Domain<3> const &out, T scale)
+  template <typename BE>
+  workspace(BE*, Domain<3> const &in, Domain<3> const &out, T scale)
     : scale_(scale),
       input_buffer_(in.size()),
       output_buffer_(out.size())
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 149093)
+++ ChangeLog	(working copy)
@@ -1,5 +1,11 @@
 2006-09-12  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/impl/fft.hpp: Pass backend to workspace constructor.
+	* src/vsip/impl/workspace.hpp: Fast path optimization for 1-dim
+	  CC unit-stride FFT to use compile-time Ext_data.
+	
+2006-09-12  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/impl/config.hpp: Remove unused macros for SIZEOF_DOUBLE
 	  and SIZEOF_LONG_DOUBLE.  SIZEOF_LONG_DOUBLE differs between
 	  ia32 and em64t/amd64.
