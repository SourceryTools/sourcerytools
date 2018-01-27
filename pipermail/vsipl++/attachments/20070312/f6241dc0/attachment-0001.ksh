Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 165340)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -53,18 +53,16 @@
   fft(std::complex<T> const* in, std::complex<T>* out, 
     length_type length, T scale, int exponent)
   {
-    // Note: the twiddle factors require only 1/4 the memory of the input and 
-    // output arrays.
     Fft_params fftp;
     fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
     fftp.elements = length;
     fftp.scale = scale;
     fftp.ea_twiddle_factors = 
       reinterpret_cast<unsigned long long>(twiddle_factors_.get());
-    fftp.ea_input_buffer    = 0;
-    fftp.ea_output_buffer   = 0;
-    fftp.in_blk_stride      = 0;
-    fftp.out_blk_stride     = 0;
+    fftp.ea_input_buffer    = reinterpret_cast<unsigned long long>(in);
+    fftp.ea_output_buffer   = reinterpret_cast<unsigned long long>(out);
+    fftp.in_blk_stride      = 1;  // not applicable in the single FFT case
+    fftp.out_blk_stride     = 1;
 
     Task_manager *mgr = Task_manager::instance();
     // The stack size is determined by accounting for the *worst case*
@@ -76,11 +74,9 @@
        sizeof(Fft_params),
        sizeof(complex<T>)*length*2, 
        sizeof(complex<T>)*length,
-       false);
-    Workblock block = task.create_block();
+       true);
+    Workblock block = task.create_multi_block(1);
     block.set_parameters(fftp);
-    block.add_input(in, length);
-    block.add_output(out, length);
     task.enqueue(block);
     task.sync();
   }
@@ -92,19 +88,23 @@
     length_type rows, length_type cols, 
     T scale, int exponent, int axis)
   {
-    // Note: the twiddle factors require only 1/4 the memory of the input and 
-    // output arrays.
     Fft_params fftp;
     fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
-    fftp.elements = cols;
     fftp.scale = scale;
     fftp.ea_twiddle_factors = 
       reinterpret_cast<unsigned long long>(twiddle_factors_.get());
-    length_type num_ffts = rows;
-    length_type in_stride = in_r_stride;
-    length_type out_stride = out_r_stride;
-    if (axis == 0)
+    length_type num_ffts;
+    length_type in_stride;
+    length_type out_stride;
+    if (axis != 0)
     {
+      num_ffts = rows;
+      in_stride = in_r_stride;
+      out_stride = out_r_stride;
+      fftp.elements = cols;
+    }
+    else
+    {
       num_ffts = cols;
       in_stride = in_c_stride;
       out_stride = out_c_stride;
@@ -128,19 +128,19 @@
        true);
 
     length_type spes         = mgr->num_spes();
-    length_type rows_per_spe = rows / spes;
+    length_type ffts_per_spe = num_ffts / spes;
 
     for (length_type i = 0; i < spes && i < num_ffts; ++i)
     {
       // If rows don't divide evenly, give the first SPEs one extra.
-      length_type spe_rows = (i < rows % spes) ? rows_per_spe + 1 : rows_per_spe;
+      length_type spe_ffts = (i < num_ffts % spes) ? ffts_per_spe + 1 : ffts_per_spe;
 
-      Workblock block = task.create_multi_block(spe_rows);
+      Workblock block = task.create_multi_block(spe_ffts);
       block.set_parameters(fftp);
       task.enqueue(block);
 
-      fftp.ea_input_buffer  += sizeof(ctype) * spe_rows * in_stride;
-      fftp.ea_output_buffer += sizeof(ctype) * spe_rows * out_stride;
+      fftp.ea_input_buffer  += sizeof(ctype) * spe_ffts * in_stride;
+      fftp.ea_output_buffer += sizeof(ctype) * spe_ffts * out_stride;
     }
     task.sync();
   }
@@ -249,6 +249,7 @@
   virtual ~Fftm_impl()
   {}
 
+  virtual bool supports_scale() { return true;}
   virtual void in_place(ctype *inout,
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
@@ -306,7 +307,26 @@
 			    length_type, length_type)
   {
   }
-
+  virtual void query_layout(Rt_layout<2> &rtl_inout)
+  {
+    // must have unit stride, but does not have to be dense
+    if (A != 0)
+      rtl_inout.order = tuple<0, 1, 2>();
+    else
+      rtl_inout.order = tuple<1, 0, 2>();
+    rtl_inout.pack = stride_unit;
+    rtl_inout.complex = cmplx_inter_fmt;
+  }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    // must have unit stride, but does not have to be dense
+    if (A != 0)
+      rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    else
+      rtl_in.order = rtl_out.order = tuple<1, 0, 2>();
+    rtl_in.pack = rtl_out.pack = stride_unit;
+    rtl_in.complex = rtl_out.complex = cmplx_inter_fmt;
+  }
 private:
   rtype scale_;
   length_type fft_length_;
Index: tests/fft_be.cpp
===================================================================
--- tests/fft_be.cpp	(revision 165340)
+++ tests/fft_be.cpp	(working copy)
@@ -82,6 +82,16 @@
     impl::fft::No_FFT_tag>::type
   list;
 };
+struct cbe
+{
+  typedef 
+  impl::Make_type_list<
+#if VSIP_IMPL_CBE_SDK
+    impl::Cbe_sdk_tag,
+#endif
+    impl::fft::No_FFT_tag>::type
+  list;
+};
 struct dft
 {
   typedef 
@@ -92,13 +102,14 @@
 typedef impl::Cmplx_inter_fmt inter;
 typedef impl::Cmplx_split_fmt split;
 
-template <typename T, typename F, int E, int A = 0>
+template <typename T, typename F, int E, int A = 0, typename OrderT = row1_type>
 struct cfft_type
 {
   typedef std::complex<T> I;
   typedef std::complex<T> O;
   typedef F i_format;
   typedef F o_format;
+  typedef OrderT order_type;
   static int const axis = A;
   static int const direction = E == -1 ? fft_fwd : fft_inv;
   static int const s = direction;
@@ -108,14 +119,16 @@
   static Domain<D> out_dom(Domain<D> const &dom) { return dom;}
 };
 
-template <typename T, typename F, int E, int A = 0> struct rfft_type;
-template <typename T, typename F, int A>
-struct rfft_type<T, F, -1, A>
+template <typename T, typename F, int E, int A = 0, typename OrderT = row1_type> 
+struct rfft_type;
+template <typename T, typename F, int A, typename OrderT>
+struct rfft_type<T, F, -1, A, OrderT>
 {
   typedef T I;
   typedef std::complex<T> O;
   typedef inter i_format;
   typedef F o_format;
+  typedef OrderT order_type;
   static int const axis = A;
   static int const direction = fft_fwd;
   static int const s = A;
@@ -130,13 +143,14 @@
     return retn;
   }
 };
-template <typename T, typename F, int A>
-struct rfft_type<T, F, 1, A>
+template <typename T, typename F, int A, typename OrderT>
+struct rfft_type<T, F, 1, A, OrderT>
 {
   typedef std::complex<T> I;
   typedef T O;
   typedef F i_format;
   typedef inter o_format;
+  typedef OrderT order_type;
   static int const axis = A;
   static int const direction = fft_inv;
   static int const s = A;
@@ -152,24 +166,33 @@
   static Domain<D> out_dom(Domain<D> const &dom) { return dom;}
 };
 
-template <typename T>
+template <typename T,
+          typename OrderT>
 const_Vector<T, impl::Generator_expr_block<1, impl::Ramp_generator<T> > const>
 ramp(Domain<1> const &dom) 
 { return vsip::ramp(T(0.), T(1.), dom.length() * dom.stride());}
 
-template <typename T>
-Matrix<T>
+template <typename T,
+          typename OrderT>
+Matrix<T, Dense<2, T, OrderT> >
 ramp(Domain<2> const &dom) 
 {
+  typedef OrderT order_type;
+  typedef Dense<2, T, order_type> block_type;
   length_type rows = dom[0].length() * dom[0].stride();
   length_type cols = dom[1].length() * dom[1].stride();
-  Matrix<T> m(rows, cols);
-  for (size_t r = 0; r != rows; ++r)
-    m.row(r) = ramp(T(r), T(1.), m.size(1));
+  Matrix<T, block_type> m(rows, cols);
+  if (impl::Type_equal<row2_type, order_type>::value)
+    for (size_t r = 0; r != rows; ++r)
+      m.row(r) = ramp(T(r), T(1.), m.size(1));
+  else
+    for (size_t c = 0; c != cols; ++c)
+      m.col(c) = ramp(T(c), T(1.), m.size(0));
   return m;
 }
 
-template <typename T>
+template <typename T,
+          typename OrderT>
 Tensor<T>
 ramp(Domain<3> const &dom) 
 {
@@ -207,12 +230,13 @@
   return Tensor<T>(x_length, y_length, z_length, T(0.));
 }
 
-template <typename T, dimension_type D> 
+template <typename T, dimension_type D, typename OrderT = row2_type> 
 struct input_creator
 {
   typedef typename T::I I;
-  static typename impl::View_of_dim<D, I, Dense<D, I> >::type
-  create(Domain<D> const &dom) { return ramp<I>(dom);}
+  typedef OrderT order_type;
+  static typename impl::View_of_dim<D, I, Dense<D, I, order_type> >::type
+  create(Domain<D> const &dom) { return ramp<I, order_type>(dom);}
 };
 
 // Real inverse FFT
@@ -222,7 +246,7 @@
   typedef typename rfft_type<T, F, 1, A>::I I;
   static typename impl::View_of_dim<D, I, Dense<D, I> >::type
   create(Domain<D> const &dom) 
-  { return ramp<I>(rfft_type<T, F, 1, A>::in_dom(dom));}
+    { return ramp<I, row1_type>(rfft_type<T, F, 1, A>::in_dom(dom));}
 };
 
 // Real inverse 2D FFT.
@@ -238,7 +262,7 @@
     length_type rows2 = rows/2+1;
     length_type cols2 = cols/2+1;
 
-    Matrix<I> input = ramp<I>(rfft_type<T, F, 1, A>::in_dom(dom));
+    Matrix<I> input = ramp<I, row1_type>(rfft_type<T, F, 1, A>::in_dom(dom));
     if (rfft_type<T, F, 1, A>::axis == 0)
     {
       // Necessary symmetry:
@@ -330,8 +354,8 @@
   typedef impl::Fast_block<D, CT, layout_type> block_type;
   typedef typename impl::View_of_dim<D, CT, block_type>::type View;
 
-  View data = ramp<T>(dom);
-  View ref = ramp<T>(dom);
+  View data = ramp<T, row1_type>(dom);
+  View ref = ramp<T, row1_type>(dom);
 
   typename View::subview_type sub_data = data(dom);
 
@@ -357,9 +381,10 @@
 {
   typedef typename T::I I;
   typedef typename T::O O;
-  typedef typename impl::Layout<2, row1_type,
+  typedef typename T::order_type order_type;
+  typedef typename impl::Layout<2, order_type,
     impl::Stride_unit_dense, typename T::i_format> i_layout_type;
-  typedef typename impl::Layout<2, row1_type,
+  typedef typename impl::Layout<2, order_type,
     impl::Stride_unit_dense, typename T::o_format> o_layout_type;
   return_mechanism_type const r = by_reference;
 
@@ -371,7 +396,7 @@
   Domain<2> in_dom = T::in_dom(dom);
   Domain<2> out_dom = T::out_dom(dom);
 
-  Iview input = input_creator<T, 2>::create(dom);
+  Iview input = input_creator<T, 2, order_type>::create(dom);
   typename Iview::subview_type sub_input = input(in_dom);
 
   Oview output = empty<O>(out_dom);
@@ -408,8 +433,8 @@
   typedef impl::Fast_block<2, CT, layout_type> block_type;
   typedef Matrix<CT, block_type> View;
 
-  View data = ramp<T>(dom);
-  View ref = ramp<T>(dom);
+  View data = ramp<T, row1_type>(dom);
+  View ref = ramp<T, row1_type>(dom);
 
   typename View::subview_type sub_data = data(dom);
 
@@ -498,6 +523,13 @@
   fft_in_place<T, F, 1, cvsip>(Domain<1>(0, 2, 8));
 #endif
 
+#if VSIP_IMPL_CBE_SDK
+  std::cout << "testing fwd in_place cbe...";
+  fft_in_place<T, F, -1, cbe>(Domain<1>(32));
+  std::cout << "testing inv in_place cbe...";
+  fft_in_place<T, F, 1, cbe>(Domain<1>(32));
+#endif
+
 #if VSIP_IMPL_FFTW3
   std::cout << "testing c->c fwd by_ref fftw...";
   fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<1>(16));
@@ -558,7 +590,14 @@
   fft_by_ref<rfft_type<T, F, 1, 0>, cvsip>(Domain<1>(0, 2, 8));
 #endif
 
+#if VSIP_IMPL_CBE_SDK
+  std::cout << "testing c->c fwd by_ref cbe...";
+  fft_by_ref<cfft_type<T, F, -1>, cbe>(Domain<1>(32));
+  std::cout << "testing c->c inv by_ref cbe...";
+  fft_by_ref<cfft_type<T, F, 1>, cbe>(Domain<1>(32));
 #endif
+
+#endif
 }
 
 template <typename T, typename F>
@@ -902,6 +941,23 @@
   fftm_in_place<T, F, 1, 1, cvsip>(Domain<2>(8, 16));
 #endif
 
+#if VSIP_IMPL_CBE_SDK
+// Note: column-wise FFTs need to be performed on
+// col-major data in this case.  These are commented
+// out until fftm_in_place is changed to be like
+// fftm_by_ref, where the cfft_type<> template allows
+// the dimension order to be specified.
+
+//  std::cout << "testing fwd on cols in_place cbe...";
+//  fftm_in_place<T, F, -1, 0, cbe>(Domain<2>(64, 32));
+  std::cout << "testing fwd on rows in_place cbe...";
+  fftm_in_place<T, F, -1, 1, cbe>(Domain<2>(32, 64));
+//  std::cout << "testing inv on cols in_place cbe...";
+//  fftm_in_place<T, F, 1, 0, cbe>(Domain<2>(64, 32));
+  std::cout << "testing inv on rows in_place cbe...";
+  fftm_in_place<T, F, 1, 1, cbe>(Domain<2>(32, 64));
+#endif
+
 #if VSIP_IMPL_FFTW3
   std::cout << "testing c->c fwd 0 by_ref fftw...";
   fftm_by_ref<cfft_type<T, F, -1, 0>, fftw>(Domain<2>(8, 16));
@@ -978,7 +1034,24 @@
   fftm_by_ref<rfft_type<T, F, 1, 1>, cvsip> (Domain<2>(4, 16));
 #endif
 
+#if VSIP_IMPL_CBE_SDK
+  std::cout << "testing c->c fwd on cols by_ref cbe...";
+  fftm_by_ref<cfft_type<T, F, -1, 0, col2_type>, cbe>(Domain<2>(32, 64));
+  fftm_by_ref<cfft_type<T, F, -1, 0, col2_type>, cbe>(Domain<2>(Domain<1>(32), Domain<1>(0, 2, 32)));
+  std::cout << "testing c->c fwd on rows by_ref cbe...";
+  fftm_by_ref<cfft_type<T, F, -1, 1, row2_type>, cbe>(Domain<2>(32, 64));
+  fftm_by_ref<cfft_type<T, F, -1, 1, row2_type>, cbe>(Domain<2>(Domain<1>(0, 2, 32), Domain<1>(64)));
+  std::cout << "testing c->c inv 0 by_ref cbe...";
+  fftm_by_ref<cfft_type<T, F, 1, 0, col2_type>, cbe>(Domain<2>(32, 64));
+  fftm_by_ref<cfft_type<T, F, 1, 0, col2_type>, cbe>(Domain<2>(Domain<1>(32), Domain<1>(0, 2, 32)));
+  std::cout << "testing c->c inv 1 by_ref cbe...";
+  fftm_by_ref<cfft_type<T, F, 1, 1, row2_type>, cbe>(Domain<2>(32, 64));
+  fftm_by_ref<cfft_type<T, F, 1, 1, row2_type>, cbe>(Domain<2>(Domain<1>(0, 2, 32), Domain<1>(64)));
 #endif
+
+
+
+#endif
 }
 
 int main(int argc, char **argv)
@@ -1010,6 +1083,7 @@
   std::cout << "testing split double 2D fft" << std::endl;
   test_fft2d<double, split>();
 #endif
+
   std::cout << "testing interleaved float fftm" << std::endl;
   test_fftm<float, inter>();
   std::cout << "testing split float fftm" << std::endl;
