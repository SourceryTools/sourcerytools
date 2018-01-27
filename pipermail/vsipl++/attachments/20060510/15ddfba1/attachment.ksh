Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.464
diff -u -r1.464 ChangeLog
--- ChangeLog	10 May 2006 02:54:09 -0000	1.464
+++ ChangeLog	10 May 2006 13:12:08 -0000
@@ -1,3 +1,10 @@
+2006-05-10  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/fft.hpp: Let workspace pre-allocate buffers.
+	* src/vsip/impl/fft/workspace.hpp: Likewise.
+	* src/vsip/impl/fft/dft.hpp: Fix 1D c->r dft computation.
+	* tests/fft_be.cpp: Likewise.
+	
 2006-05-09  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* configure.ac: Fix generation of VSIP_IMPL_FFTM3 macro, and add support
Index: src/vsip/impl/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft.hpp,v
retrieving revision 1.3
diff -u -r1.3 fft.hpp
--- src/vsip/impl/fft.hpp	10 May 2006 02:54:09 -0000	1.3
+++ src/vsip/impl/fft.hpp	10 May 2006 13:12:09 -0000
@@ -134,7 +134,7 @@
     VSIP_THROW((std::bad_alloc))
     : base(dom, scale),
       backend_(factory::create(dom, scale)),
-      workspace_(dom, scale)
+      workspace_(this->input_size(), this->output_size(), scale)
   {}
 
   template <typename ViewT>
@@ -177,7 +177,7 @@
     VSIP_THROW((std::bad_alloc))
     : base(dom, scale),
       backend_(factory::create(dom, scale)),
-      workspace_(dom, scale)
+      workspace_(this->input_size(), this->output_size(), scale)
   {}
 
   template <typename Block0, typename Block1,
@@ -233,8 +233,8 @@
     VSIP_THROW((std::bad_alloc))
     : base(dom, scale),
       backend_(factory::create(dom, scale)),
-      workspace_(dom, scale) {}
-
+      workspace_(this->input_size(), this->output_size(), scale)
+  {}
   template <typename BlockT>  
   typename impl::fft::result<O,BlockT>::view_type
   operator()(const_Matrix<I,BlockT> in)
@@ -271,7 +271,8 @@
     VSIP_THROW((std::bad_alloc))
     : base(dom, scale),
       backend_(factory::create(dom, scale)),
-      workspace_(dom, scale) {}
+      workspace_(this->input_size(), this->output_size(), scale)
+  {}
 
   template <typename Block0, typename Block1>
   Matrix<O,Block1>
Index: src/vsip/impl/fft/dft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/dft.hpp,v
retrieving revision 1.2
diff -u -r1.2 dft.hpp
--- src/vsip/impl/fft/dft.hpp	10 May 2006 02:54:09 -0000	1.2
+++ src/vsip/impl/fft/dft.hpp	10 May 2006 13:12:09 -0000
@@ -189,7 +189,7 @@
       for (index_type k = 0; k < l/2 + 1; ++k)
 	sum += in[k * in_s] * sin_cos<T>(phi * k * w);
       for (index_type k = l/2 + 1; k < l; ++k)
-	sum += conj(in[(l - k) * in_s]) * sin_cos<T>(phi * (l - k) * w);
+	sum += conj(in[(l - k) * in_s]) * sin_cos<T>(phi * k * w);
       out[w * out_s] = sum.real();
     }
   }
@@ -207,7 +207,7 @@
 	  * sin_cos<T>(phi * k * w);
       for (index_type k = l/2 + 1; k < l; ++k)
 	sum += complex<T>(in.first[(l - k) * in_s], -in.second[(l - k) * in_s])
-	  * sin_cos<T>(phi * (l - k) * w);
+	  * sin_cos<T>(phi * k * w);
       out[w * out_s] = sum.real();
     }
   }
Index: src/vsip/impl/fft/workspace.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/workspace.hpp,v
retrieving revision 1.3
diff -u -r1.3 workspace.hpp
--- src/vsip/impl/fft/workspace.hpp	10 May 2006 02:54:09 -0000	1.3
+++ src/vsip/impl/fft/workspace.hpp	10 May 2006 13:12:09 -0000
@@ -44,8 +44,10 @@
 class workspace<1, std::complex<T>, std::complex<T> >
 {
 public:
-  workspace(Domain<1> const &, T scale)
-    : scale_(scale)
+  workspace(Domain<1> const &in, Domain<1> const &out, T scale)
+    : scale_(scale),
+      input_buffer_(in.size()),
+      output_buffer_(out.size())
   {}
   
   template <typename BE, typename Block0, typename Block1>
@@ -67,8 +69,10 @@
 
     {
       // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
-      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT,
+				  output_buffer_.get());
     
       // Call the backend.
       assert(rtl_in.complex == rtl_out.complex);
@@ -96,7 +100,8 @@
     backend->query_layout(rtl_inout);
     {
       // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<BlockT> inout_ext(inout.block(), rtl_inout, SYNC_INOUT);
+      Rt_ext_data<BlockT> inout_ext(inout.block(), rtl_inout, SYNC_INOUT,
+				    input_buffer_.get());
     
       // Call the backend.
       if (rtl_inout.complex == cmplx_inter_fmt) 
@@ -113,14 +118,18 @@
 
 private:
   T scale_;
+  aligned_array<std::complex<T> > input_buffer_;
+  aligned_array<std::complex<T> > output_buffer_;
 };
 
 template <typename T>
 class workspace<1, T, std::complex<T> >
 {
 public:
-  workspace(Domain<1> const &, T scale)
-    : scale_(scale)
+  workspace(Domain<1> const &in, Domain<1> const &out, T scale)
+    : scale_(scale),
+      input_buffer_(in.size()),
+      output_buffer_(out.size())
   {}
   
   template <typename BE, typename Block0, typename Block1>
@@ -141,8 +150,10 @@
       : SYNC_IN; 
     {
       // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
-      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT,
+				  output_buffer_.get());
     
       // Call the backend.
       if (rtl_out.complex == cmplx_inter_fmt) 
@@ -161,14 +172,18 @@
 
 private:
   T scale_;
+  aligned_array<T> input_buffer_;
+  aligned_array<std::complex<T> > output_buffer_;
 };
 
 template <typename T>
 class workspace<1, std::complex<T>, T>
 {
 public:
-  workspace(Domain<1> const &, T scale)
-    : scale_(scale)
+  workspace(Domain<1> const &in, Domain<1> const &out, T scale)
+    : scale_(scale),
+      input_buffer_(in.size()),
+      output_buffer_(out.size())
   {}
   
   template <typename BE, typename Block0, typename Block1>
@@ -189,8 +204,10 @@
       : SYNC_IN;
     { 
       // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
-      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT,
+				  output_buffer_.get());
     
       // Call the backend.
       if (rtl_in.complex == cmplx_inter_fmt) 
@@ -209,14 +226,18 @@
 
 private:
   T scale_;
+  aligned_array<std::complex<T> > input_buffer_;
+  aligned_array<T> output_buffer_;
 };
 
 template <typename T>
 class workspace<2, std::complex<T>, std::complex<T> >
 {
 public:
-  workspace(Domain<2> const &, T scale)
-    : scale_(scale)
+  workspace(Domain<2> const &in, Domain<2> const &out, T scale)
+    : scale_(scale),
+      input_buffer_(in.size()),
+      output_buffer_(out.size())
   {}
   
   template <typename BE, typename Block0, typename Block1>
@@ -237,8 +258,10 @@
       : SYNC_IN; 
     {
       // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
-      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT,
+				  output_buffer_.get());
     
       // Call the backend.
       assert(rtl_in.complex == rtl_out.complex);
@@ -270,7 +293,8 @@
     backend->query_layout(rtl_inout);
     {
       // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<BlockT> inout_ext(inout.block(), rtl_inout, SYNC_INOUT);
+      Rt_ext_data<BlockT> inout_ext(inout.block(), rtl_inout, SYNC_INOUT,
+				    input_buffer_.get());
     
       // Call the backend.
       if (rtl_inout.complex == cmplx_inter_fmt) 
@@ -289,14 +313,18 @@
 
 private:
   T scale_;
+  aligned_array<std::complex<T> > input_buffer_;
+  aligned_array<std::complex<T> > output_buffer_;
 };
 
 template <typename T>
 class workspace<2, T, std::complex<T> >
 {
 public:
-  workspace(Domain<2> const &, T scale)
-    : scale_(scale)
+  workspace(Domain<2> const &in, Domain<2> const &out, T scale)
+    : scale_(scale),
+      input_buffer_(in.size()),
+      output_buffer_(out.size())
   {}
   
   template <typename BE, typename Block0, typename Block1>
@@ -316,8 +344,10 @@
       : SYNC_IN; 
     {
       // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
-      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync, 
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT,
+				  output_buffer_.get());
     
       // Call the backend.
       if (rtl_out.complex == cmplx_inter_fmt) 
@@ -340,14 +370,18 @@
 
 private:
   T scale_;
+  aligned_array<T> input_buffer_;
+  aligned_array<std::complex<T> > output_buffer_;
 };
 
 template <typename T>
 class workspace<2, std::complex<T>, T >
 {
 public:
-  workspace(Domain<2> const &, T scale)
-    : scale_(scale)
+  workspace(Domain<2> const &in, Domain<2> const &out, T scale)
+    : scale_(scale),
+      input_buffer_(in.size()),
+      output_buffer_(out.size())
   {}
   
   template <typename BE, typename Block0, typename Block1>
@@ -367,8 +401,10 @@
       : SYNC_IN;
     { 
       // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
-      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT,
+				  output_buffer_.get());
     
       // Call the backend.
       if (rtl_in.complex == cmplx_inter_fmt) 
@@ -391,14 +427,18 @@
 
 private:
   T scale_;
+  aligned_array<std::complex<T> > input_buffer_;
+  aligned_array<T> output_buffer_;
 };
 
 template <typename T>
 class workspace<3, std::complex<T>, std::complex<T> >
 {
 public:
-  workspace(Domain<3> const &, T scale)
-    : scale_(scale)
+  workspace(Domain<3> const &in, Domain<3> const &out, T scale)
+    : scale_(scale),
+      input_buffer_(in.size()),
+      output_buffer_(out.size())
   {}
   
   template <typename BE, typename Block0, typename Block1>
@@ -419,8 +459,10 @@
       : SYNC_IN; 
     {
       // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
-      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT,
+				  output_buffer_.get());
     
       // Call the backend.
       assert(rtl_in.complex == rtl_out.complex);
@@ -464,7 +506,8 @@
     backend->query_layout(rtl_inout);
     {
       // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<BlockT> inout_ext(inout.block(), rtl_inout, SYNC_INOUT);
+      Rt_ext_data<BlockT> inout_ext(inout.block(), rtl_inout, SYNC_INOUT,
+				    input_buffer_.get());
     
       // Call the backend.
       if (rtl_inout.complex == cmplx_inter_fmt) 
@@ -491,14 +534,18 @@
 
 private:
   T scale_;
+  aligned_array<std::complex<T> > input_buffer_;
+  aligned_array<std::complex<T> > output_buffer_;
 };
 
 template <typename T>
 class workspace<3, T, std::complex<T> >
 {
 public:
-  workspace(Domain<3> const &, T scale)
-    : scale_(scale)
+  workspace(Domain<3> const &in, Domain<3> const &out, T scale)
+    : scale_(scale),
+      input_buffer_(in.size()),
+      output_buffer_(out.size())
   {}
   
   template <typename BE, typename Block0, typename Block1>
@@ -518,8 +565,10 @@
       : SYNC_IN; 
     {
       // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
-      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT,
+				  output_buffer_.get());
     
       // Call the backend.
       if (rtl_out.complex == cmplx_inter_fmt) 
@@ -554,14 +603,18 @@
 
 private:
   T scale_;
+  aligned_array<T> input_buffer_;
+  aligned_array<std::complex<T> > output_buffer_;
 };
 
 template <typename T>
 class workspace<3, std::complex<T>, T >
 {
 public:
-  workspace(Domain<3> const &, T scale)
-    : scale_(scale)
+  workspace(Domain<3> const &in, Domain<3> const &out, T scale)
+    : scale_(scale),
+      input_buffer_(in.size()),
+      output_buffer_(out.size())
   {}
   
   template <typename BE, typename Block0, typename Block1>
@@ -581,8 +634,10 @@
       : SYNC_IN;
     { 
       // Create a 'direct data accessor', adjusting the block layout if necessary.
-      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
-      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync,
+				 input_buffer_.get());
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT,
+				  output_buffer_.get());
     
       // Call the backend.
       if (rtl_in.complex == cmplx_inter_fmt) 
@@ -617,6 +672,8 @@
 
 private:
   T scale_;
+  aligned_array<std::complex<T> > input_buffer_;
+  aligned_array<T> output_buffer_;
 };
 
 } // namespace vsip::impl::fft
Index: tests/fft_be.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft_be.cpp,v
retrieving revision 1.2
diff -u -r1.2 fft_be.cpp
--- tests/fft_be.cpp	10 May 2006 02:54:09 -0000	1.2
+++ tests/fft_be.cpp	10 May 2006 13:12:10 -0000
@@ -432,15 +432,14 @@
   fft_by_ref<rfft_type<T, F, -1, 1>, fftw>(Domain<2>(8, 16));
   fft_by_ref<rfft_type<T, F, -1, 1>, fftw>(Domain<2>(Domain<1>(0, 2, 9),
 						     Domain<1>(0, 2, 16)));
-  // FIXME: DFT still buggy...
-//   std::cout << "testing c->r inv 0 by_ref fftw...";
-//   fft_by_ref<rfft_type<T, F, 1, 0>, fftw> (Domain<2>(4, 5));
-//   fft_by_ref<rfft_type<T, F, 1, 0>, fftw> (Domain<2>(Domain<1>(0, 2, 9),
-//                                                      Domain<1>(0, 2, 16)));
-//   std::cout << "testing c->r inv 1 by_ref fftw...";
-//   fft_by_ref<rfft_type<T, F, 1, 1>, fftw> (Domain<2>(8, 16));
-//   fft_by_ref<rfft_type<T, F, 1, 1>, fftw> (Domain<2>(Domain<1>(0, 2, 9),
-//                                                      Domain<1>(0, 2, 16)));
+  std::cout << "testing c->r inv 0 by_ref fftw...";
+  fft_by_ref<rfft_type<T, F, 1, 0>, fftw> (Domain<2>(4, 5));
+  fft_by_ref<rfft_type<T, F, 1, 0>, fftw> (Domain<2>(Domain<1>(0, 2, 9),
+						     Domain<1>(0, 2, 16)));
+  std::cout << "testing c->r inv 1 by_ref fftw...";
+  fft_by_ref<rfft_type<T, F, 1, 1>, fftw> (Domain<2>(8, 16));
+  fft_by_ref<rfft_type<T, F, 1, 1>, fftw> (Domain<2>(Domain<1>(0, 2, 9),
+						     Domain<1>(0, 2, 16)));
   std::cout << "testing c->c fwd by_ref sal...";
   fft_by_ref<cfft_type<T, F, -1>, sal>(Domain<2>(8, 16));
   fft_by_ref<cfft_type<T, F, -1>, sal>(Domain<2>(Domain<1>(0, 2, 8),
@@ -457,15 +456,14 @@
   fft_by_ref<rfft_type<T, F, -1, 1>, sal>(Domain<2>(8, 16));
   fft_by_ref<rfft_type<T, F, -1, 1>, sal>(Domain<2>(Domain<1>(0, 2, 8),
 						    Domain<1>(0, 2, 16)));
-  // FIXME: DFT still buggy...
-//   std::cout << "testing c->r inv 0 by_ref sal...";
-//   fft_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(8, 16));
-//   fft_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(Domain<1>(0, 2, 9),
-//                                                     Domain<1>(0, 2, 16)));
-//   std::cout << "testing c->r inv 1 by_ref sal...";
-//   fft_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(8, 16));
-//   fft_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(Domain<1>(0, 2, 9),
-//                                                     Domain<1>(0, 2, 16)));
+  std::cout << "testing c->r inv 0 by_ref sal...";
+  fft_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(8, 16));
+  fft_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(Domain<1>(0, 2, 9),
+						    Domain<1>(0, 2, 16)));
+  std::cout << "testing c->r inv 1 by_ref sal...";
+  fft_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(8, 16));
+  fft_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(Domain<1>(0, 2, 9),
+						    Domain<1>(0, 2, 16)));
   std::cout << "testing c->c fwd by_ref ipp...";
   fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<2>(8, 16));
   fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<2>(Domain<1>(0, 2, 9),
@@ -482,15 +480,14 @@
   fft_by_ref<rfft_type<T, F, -1, 1>, ipp>(Domain<2>(8, 16));
   fft_by_ref<rfft_type<T, F, -1, 1>, ipp>(Domain<2>(Domain<1>(0, 2, 9),
 						    Domain<1>(0, 2, 16)));
-  // FIXME: DFT still buggy...
-//   std::cout << "testing c->r inv 0 by_ref ipp...";
-//   fft_by_ref<rfft_type<T, F, 1, 0>, ipp> (Domain<2>(8, 16));
-//   fft_by_ref<rfft_type<T, F, 1, 0>, ipp> (Domain<2>(Domain<1>(0, 2, 9),
-//                                                     Domain<1>(0, 2, 16)));
-//   std::cout << "testing c->r inv 1 by_ref ipp...";
-//   fft_by_ref<rfft_type<T, F, 1, 1>, ipp> (Domain<2>(8, 16));
-//   fft_by_ref<rfft_type<T, F, 1, 1>, ipp> (Domain<2>(Domain<1>(0, 2, 9),
-//                                                     Domain<1>(0, 2, 16)));
+  std::cout << "testing c->r inv 0 by_ref ipp...";
+  fft_by_ref<rfft_type<T, F, 1, 0>, ipp> (Domain<2>(8, 16));
+  fft_by_ref<rfft_type<T, F, 1, 0>, ipp> (Domain<2>(Domain<1>(0, 2, 9),
+						    Domain<1>(0, 2, 16)));
+  std::cout << "testing c->r inv 1 by_ref ipp...";
+  fft_by_ref<rfft_type<T, F, 1, 1>, ipp> (Domain<2>(8, 16));
+  fft_by_ref<rfft_type<T, F, 1, 1>, ipp> (Domain<2>(Domain<1>(0, 2, 9),
+						    Domain<1>(0, 2, 16)));
 }
 
 template <typename T, typename F>
