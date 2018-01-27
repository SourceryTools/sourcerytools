Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.483
diff -u -r1.483 ChangeLog
--- ChangeLog	14 May 2006 07:47:11 -0000	1.483
+++ ChangeLog	14 May 2006 20:50:26 -0000
@@ -1,5 +1,21 @@
 2006-05-14  Jules Bergmann  <jules@codesourcery.com>
 
+	* configure.ac: Define appropriate VSIP_IMPL_FFT_USE_ macros when
+	  using builtin FFT.
+	* src/vsip/signal-window.cpp: Add GHS instantiation pragmas
+	  for split-complex.
+	* src/vsip/impl/fft/dft.hpp: Wall cleanup (unused parameters).
+	* src/vsip/impl/fft/no_fft.hpp: Likewise.
+	* src/vsip/impl/fftw3/fft.hpp: Likewise.
+	* src/vsip/impl/fftw3/fft_impl.cpp: Likewise.
+	* src/vsip/impl/ipp/fft.cpp: Likewise.
+	* src/vsip/impl/ipp/fft.hpp: Likewise.
+	* src/vsip/impl/sal/solver_svd.hpp: Wall cleanup (unused parameters),
+	  remove non-inline/non-template function from header.
+	
+2006-05-14  Jules Bergmann  <jules@codesourcery.com>
+
 	* README.mcoe: New file, release notes for Mercury/MCOE systems.
 	* src/vsip/impl/fftw3/fft_impl.cpp: Fix typo.
 	* src/vsip/impl/ipp/fft.cpp (fftm): Use rows/cols passed to
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.104
diff -u -r1.104 configure.ac
--- configure.ac	14 May 2006 02:21:04 -0000	1.104
+++ configure.ac	14 May 2006 20:50:26 -0000
@@ -708,14 +708,20 @@
     if test "$enable_fft_float" = yes; then
       ln -s ../../fftw3f/.libs/libfftw3f.a vendor/fftw/lib/libfftw3f.a
       AC_SUBST(USE_BUILTIN_FFTW_FLOAT, 1)
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_FLOAT, 1,
+        [Define to build code for float-precision FFT.])
     fi
     if test "$enable_fft_double" = yes; then
       ln -s ../../fftw3/.libs/libfftw3.a   vendor/fftw/lib/libfftw3.a
       AC_SUBST(USE_BUILTIN_FFTW_DOUBLE, 1)
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_DOUBLE, 1,
+        [Define to build code for double-precision FFT.])
     fi
     if test "$enable_fft_long_double" = yes; then
       ln -s ../../fftw3l/.libs/libfftw3l.a vendor/fftw/lib/libfftw3l.a
       AC_SUBST(USE_BUILTIN_FFTW_LONG_DOUBLE, 1)
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_FFT_USE_LONG_DOUBLE, 1,
+        [Define to build code for long-double-precision FFT.])
     fi
   else
     AC_MSG_RESULT([not found])
Index: src/vsip/signal-window.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/signal-window.cpp,v
retrieving revision 1.7
diff -u -r1.7 signal-window.cpp
--- src/vsip/signal-window.cpp	13 May 2006 18:04:53 -0000	1.7
+++ src/vsip/signal-window.cpp	14 May 2006 20:50:26 -0000
@@ -222,9 +222,13 @@
 
 #pragma instantiate Vector<complex<float>, impl::Fast_block<1, complex<float>, impl::Layout<1, row1_type, impl::Stride_unit_dense, impl::Cmplx_inter_fmt>, Local_map> > vsip::impl::fft::new_view<Vector<complex<float>, impl::Fast_block<1, complex<float>, impl::Layout<1, row1_type, impl::Stride_unit_dense, impl::Cmplx_inter_fmt>, Local_map> > >(const Domain<1>&)
 
+#pragma instantiate Vector<complex<float>, impl::Fast_block<1, complex<float>, impl::Layout<1, row1_type, impl::Stride_unit_dense, impl::Cmplx_split_fmt>, Local_map> > vsip::impl::fft::new_view<Vector<complex<float>, impl::Fast_block<1, complex<float>, impl::Layout<1, row1_type, impl::Stride_unit_dense, impl::Cmplx_split_fmt>, Local_map> > >(const Domain<1>&)
+
 #pragma instantiate bool vsip::impl::data_access::is_direct_ok<Dense<1, complex<float>, row1_type, Local_map>, impl::Rt_layout<1> >(const Dense<1, complex<float>, row1_type, Local_map> &, const impl::Rt_layout<1>  &)
 
 #pragma instantiate bool vsip::impl::data_access::is_direct_ok<impl::Fast_block<1, complex<float>, impl::Layout<1, row1_type, impl::Stride_unit_dense, impl::Cmplx_inter_fmt>, Local_map>, impl::Rt_layout<1> >(const impl::Fast_block<1, complex<float>, impl::Layout<1, row1_type, impl::Stride_unit_dense, impl::Cmplx_inter_fmt>, Local_map> &, const impl::Rt_layout<1>&)
+
+#pragma instantiate bool vsip::impl::data_access::is_direct_ok<impl::Fast_block<1, complex<float>, impl::Layout<1, row1_type, impl::Stride_unit_dense, impl::Cmplx_split_fmt>, Local_map>, impl::Rt_layout<1> >(const impl::Fast_block<1, complex<float>, impl::Layout<1, row1_type, impl::Stride_unit_dense, impl::Cmplx_split_fmt>, Local_map> &, const impl::Rt_layout<1>&)
 #endif
 
 } // namespace vsip
Index: src/vsip/impl/fft/dft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/dft.hpp,v
retrieving revision 1.4
diff -u -r1.4 dft.hpp
--- src/vsip/impl/fft/dft.hpp	14 May 2006 05:50:39 -0000	1.4
+++ src/vsip/impl/fft/dft.hpp	14 May 2006 20:50:26 -0000
@@ -577,7 +577,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out) {}
+  virtual void query_layout(Rt_layout<3> &, Rt_layout<3> &) {}
   virtual void by_reference(rtype *in,
 			    stride_type in_x_stride,
 			    stride_type in_y_stride,
@@ -699,7 +699,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out) {}
+  virtual void query_layout(Rt_layout<3> &, Rt_layout<3> &) {}
   virtual void by_reference(ctype *in,
 			    stride_type in_x_stride,
 			    stride_type in_y_stride,
@@ -874,7 +874,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out) {}
+  virtual void query_layout(Rt_layout<2> &, Rt_layout<2> &) {}
   virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    ctype *out,
@@ -919,7 +919,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out) {}
+  virtual void query_layout(Rt_layout<2> &, Rt_layout<2> &) {}
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    rtype *out,
@@ -980,8 +980,8 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<2> &rtl_inout) {}
-  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out) {}
+  virtual void query_layout(Rt_layout<2> &) {}
+  virtual void query_layout(Rt_layout<2> &, Rt_layout<2> &) {}
   virtual void in_place(ctype *inout,
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
@@ -1073,11 +1073,11 @@
 struct evaluator<D, I, O, S, R, N, DFT_tag>
 {
   static bool const ct_valid = true;
-  static bool rt_valid(Domain<D> const &dom) { return true;}
+  static bool rt_valid(Domain<D> const &/*dom*/) { return true;}
   static std::auto_ptr<backend<D, I, O,
  			       axis<I, O, S>::value,
  			       exponent<I, O, S>::value> >
-  create(Domain<D> const &dom, typename Scalar_of<I>::type scale)
+  create(Domain<D> const &/*dom*/, typename Scalar_of<I>::type /*scale*/)
   {
     static int const A = axis<I, O, S>::value;
     static int const E = exponent<I, O, S>::value;
@@ -1098,9 +1098,9 @@
 struct evaluator<I, O, A, E, R, N, fft::DFT_tag>
 {
   static bool const ct_valid = true;
-  static bool rt_valid(Domain<2> const &dom) { return true;}
+  static bool rt_valid(Domain<2> const &/*dom*/) { return true;}
   static std::auto_ptr<fft::fftm<I, O, A, E> > 
-  create(Domain<2> const &dom, typename Scalar_of<I>::type scale)
+  create(Domain<2> const &/*dom*/, typename Scalar_of<I>::type /*scale*/)
   {
     return std::auto_ptr<fft::fftm<I, O, A, E> > (new fft::dftm<I, O, A, E>());
   }
Index: src/vsip/impl/fft/no_fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/no_fft.hpp,v
retrieving revision 1.3
diff -u -r1.3 no_fft.hpp
--- src/vsip/impl/fft/no_fft.hpp	14 May 2006 05:50:39 -0000	1.3
+++ src/vsip/impl/fft/no_fft.hpp	14 May 2006 20:50:26 -0000
@@ -51,20 +51,20 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void in_place(ctype *inout, stride_type s, length_type l)
+  virtual void in_place(ctype *, stride_type, length_type)
   {
   }
-  virtual void in_place(ztype inout, stride_type s, length_type l)
+  virtual void in_place(ztype, stride_type, length_type)
   {
   }
-  virtual void by_reference(ctype *in, stride_type in_s,
-			    ctype *out, stride_type out_s,
-			    length_type l)
+  virtual void by_reference(ctype *, stride_type,
+			    ctype *, stride_type,
+			    length_type)
   {
   }
-  virtual void by_reference(ztype in, stride_type in_s,
-			    ztype out, stride_type out_s,
-			    length_type l)
+  virtual void by_reference(ztype, stride_type,
+			    ztype, stride_type,
+			    length_type)
   {
   }
 };
@@ -80,14 +80,14 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void by_reference(rtype *in, stride_type in_s,
-			    ctype *out, stride_type out_s,
-			    length_type l)
+  virtual void by_reference(rtype *, stride_type,
+			    ctype *, stride_type,
+			    length_type)
   {
   }
-  virtual void by_reference(rtype *in, stride_type in_s,
-			    ztype out, stride_type out_s,
-			    length_type l)
+  virtual void by_reference(rtype *, stride_type,
+			    ztype, stride_type,
+			    length_type)
   {
   }
 };
@@ -103,14 +103,14 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void by_reference(ctype *in, stride_type in_s,
-			    rtype *out, stride_type out_s,
-			    length_type l)
+  virtual void by_reference(ctype *, stride_type,
+			    rtype *, stride_type,
+			    length_type)
   {
   }
-  virtual void by_reference(ztype in, stride_type in_s,
-			    rtype *out, stride_type out_s,
-			    length_type l)
+  virtual void by_reference(ztype, stride_type,
+			    rtype *, stride_type,
+			    length_type)
   {
   }
 };
@@ -126,28 +126,28 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void in_place(ctype *inout,
-			stride_type r_stride, stride_type c_stride,
-			length_type rows, length_type cols)
+  virtual void in_place(ctype *,
+			stride_type, stride_type,
+			length_type, length_type)
   {
   }
   virtual void in_place(ztype,
-			stride_type r_stride, stride_type c_stride,
-			length_type rows, length_type cols)
+			stride_type, stride_type,
+			length_type, length_type)
   {
   }
-  virtual void by_reference(ctype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    ctype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
-  {
-  }
-  virtual void by_reference(ztype in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    ztype out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(ctype *,
+			    stride_type, stride_type,
+			    ctype *,
+			    stride_type, stride_type,
+			    length_type, length_type)
+  {
+  }
+  virtual void by_reference(ztype,
+			    stride_type, stride_type,
+			    ztype,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
 };
@@ -163,18 +163,18 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void by_reference(rtype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    ctype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(rtype *,
+			    stride_type, stride_type,
+			    ctype *,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
-  virtual void by_reference(rtype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
+  virtual void by_reference(rtype *,
+			    stride_type, stride_type,
 			    ztype,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
 
@@ -191,18 +191,18 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void by_reference(ctype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    rtype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(ctype *,
+			    stride_type, stride_type,
+			    rtype *,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
   virtual void by_reference(ztype,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    rtype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+			    stride_type, stride_type,
+			    rtype *,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
 
@@ -219,48 +219,48 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void in_place(ctype *inout,
-			stride_type x_stride,
-			stride_type y_stride,
-			stride_type z_stride,
-			length_type x_length,
-			length_type y_length,
-			length_type z_length)
-  {
-  }
-  virtual void in_place(ztype inout,
-			stride_type x_stride,
-			stride_type y_stride,
-			stride_type z_stride,
-			length_type x_length,
-			length_type y_length,
-			length_type z_length)
-  {
-  }
-  virtual void by_reference(ctype *in,
-			    stride_type in_x_stride,
-			    stride_type in_y_stride,
-			    stride_type in_z_stride,
-			    ctype *out,
-			    stride_type out_x_stride,
-			    stride_type out_y_stride,
-			    stride_type out_z_stride,
-			    length_type x_length,
-			    length_type y_length,
-			    length_type z_length)
-  {
-  }
-  virtual void by_reference(ztype in,
-			    stride_type in_x_stride,
-			    stride_type in_y_stride,
-			    stride_type in_z_stride,
-			    ztype out,
-			    stride_type out_x_stride,
-			    stride_type out_y_stride,
-			    stride_type out_z_stride,
-			    length_type x_length,
-			    length_type y_length,
-			    length_type z_length)
+  virtual void in_place(ctype *,
+			stride_type,
+			stride_type,
+			stride_type,
+			length_type,
+			length_type,
+			length_type)
+  {
+  }
+  virtual void in_place(ztype,
+			stride_type,
+			stride_type,
+			stride_type,
+			length_type,
+			length_type,
+			length_type)
+  {
+  }
+  virtual void by_reference(ctype *,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    ctype *,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    length_type,
+			    length_type,
+			    length_type)
+  {
+  }
+  virtual void by_reference(ztype,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    ztype,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    length_type,
+			    length_type,
+			    length_type)
   {
   }
 };
@@ -276,30 +276,30 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void by_reference(rtype *in,
-			    stride_type in_x_stride,
-			    stride_type in_y_stride,
-			    stride_type in_z_stride,
-			    ctype *out,
-			    stride_type out_x_stride,
-			    stride_type out_y_stride,
-			    stride_type out_z_stride,
-			    length_type x_length,
-			    length_type y_length,
-			    length_type z_length)
-  {
-  }
-  virtual void by_reference(rtype *in,
-			    stride_type in_x_stride,
-			    stride_type in_y_stride,
-			    stride_type in_z_stride,
-			    ztype out,
-			    stride_type out_x_stride,
-			    stride_type out_y_stridey,
-			    stride_type out_z_stride,
-			    length_type x_length,
-			    length_type y_length,
-			    length_type z_length)
+  virtual void by_reference(rtype *,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    ctype *,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    length_type,
+			    length_type,
+			    length_type)
+  {
+  }
+  virtual void by_reference(rtype *,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    ztype,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    length_type,
+			    length_type,
+			    length_type)
   {
   }
 
@@ -316,30 +316,30 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void by_reference(ctype *in,
-			    stride_type in_x_stride,
-			    stride_type in_y_stride,
-			    stride_type in_z_stride,
-			    rtype *out,
-			    stride_type out_x_stride,
-			    stride_type out_y_stride,
-			    stride_type out_z_stride,
-			    length_type x_length,
-			    length_type y_length,
-			    length_type z_length)
-  {
-  }
-  virtual void by_reference(ztype in,
-			    stride_type in_x_stride,
-			    stride_type in_y_stride,
-			    stride_type in_z_stride,
-			    rtype *out,
-			    stride_type out_x_stride,
-			    stride_type out_y_stride,
-			    stride_type out_z_stride,
-			    length_type x_length,
-			    length_type y_length,
-			    length_type z_length)
+  virtual void by_reference(ctype *,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    rtype *,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    length_type,
+			    length_type,
+			    length_type)
+  {
+  }
+  virtual void by_reference(ztype,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    rtype *,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    length_type,
+			    length_type,
+			    length_type)
   {
   }
 
@@ -358,18 +358,18 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void by_reference(rtype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    ctype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(rtype *,
+			    stride_type, stride_type,
+			    ctype *,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
-  virtual void by_reference(rtype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    ztype out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(rtype *,
+			    stride_type, stride_type,
+			    ztype,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
 };
@@ -385,18 +385,18 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void by_reference(ctype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    rtype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(ctype *,
+			    stride_type, stride_type,
+			    rtype *,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
-  virtual void by_reference(ztype in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    rtype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(ztype,
+			    stride_type, stride_type,
+			    rtype *,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
 };
@@ -412,30 +412,30 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void in_place(ctype *inout,
-			stride_type r_stride, stride_type c_stride,
-			length_type rows, length_type cols)
+  virtual void in_place(ctype *,
+			stride_type, stride_type,
+			length_type, length_type)
   {
   }
 
-  virtual void in_place(ztype inout,
-			stride_type r_stride, stride_type c_stride,
-			length_type rows, length_type cols)
+  virtual void in_place(ztype,
+			stride_type, stride_type,
+			length_type, length_type)
   {
   }
 
-  virtual void by_reference(ctype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    ctype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(ctype *,
+			    stride_type, stride_type,
+			    ctype *,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
-  virtual void by_reference(ztype in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    ztype out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(ztype,
+			    stride_type, stride_type,
+			    ztype,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
 };
@@ -451,11 +451,11 @@
 struct evaluator<D, I, O, S, R, N, No_FFT_tag>
 {
   static bool const ct_valid = true;
-  static bool rt_valid(Domain<D> const &dom) { return true;}
+  static bool rt_valid(Domain<D> const &) { return true;}
   static std::auto_ptr<backend<D, I, O,
  			       axis<I, O, S>::value,
  			       exponent<I, O, S>::value> >
-  create(Domain<D> const &dom, typename Scalar_of<I>::type scale)
+  create(Domain<D> const &/*dom*/, typename Scalar_of<I>::type /*scale*/)
   {
     static int const A = axis<I, O, S>::value;
     static int const E = exponent<I, O, S>::value;
@@ -476,9 +476,9 @@
 struct evaluator<I, O, A, E, R, N, fft::No_FFT_tag>
 {
   static bool const ct_valid = true;
-  static bool rt_valid(Domain<2> const &dom) { return true;}
+  static bool rt_valid(Domain<2> const &/*dom*/) { return true;}
   static std::auto_ptr<fft::fftm<I, O, A, E> > 
-  create(Domain<2> const &dom, typename Scalar_of<I>::type scale)
+  create(Domain<2> const &/*dom*/, typename Scalar_of<I>::type /*scale*/)
   {
     return std::auto_ptr<fft::fftm<I, O, A, E> >
       (new fft::no_fftm<I, O, A, E>());
Index: src/vsip/impl/fftw3/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fftw3/fft.hpp,v
retrieving revision 1.4
diff -u -r1.4 fft.hpp
--- src/vsip/impl/fftw3/fft.hpp	13 May 2006 23:19:34 -0000	1.4
+++ src/vsip/impl/fftw3/fft.hpp	14 May 2006 20:50:26 -0000
@@ -134,9 +134,9 @@
 struct evaluator<I, O, A, E, R, N, fft::Fftw3_tag>
 {
   static bool const ct_valid = true;
-  static bool rt_valid(Domain<2> const &dom) { return true;}
+  static bool rt_valid(Domain<2> const &/*dom*/) { return true;}
   static std::auto_ptr<fft::fftm<I, O, A, E> > 
-  create(Domain<2> const &dom, typename impl::Scalar_of<I>::type scale)
+  create(Domain<2> const &dom, typename impl::Scalar_of<I>::type /*scale*/)
   {
     return fftw3::create<fft::fftm<I, O, A, E> >(dom, N);
   }
Index: src/vsip/impl/fftw3/fft_impl.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fftw3/fft_impl.cpp,v
retrieving revision 1.8
diff -u -r1.8 fft_impl.cpp
--- src/vsip/impl/fftw3/fft_impl.cpp	14 May 2006 07:36:03 -0000	1.8
+++ src/vsip/impl/fftw3/fft_impl.cpp	14 May 2006 20:50:26 -0000
@@ -268,7 +268,7 @@
   virtual void in_place(ctype *inout,
 			stride_type r_stride,
 			stride_type c_stride,
-			length_type rows, length_type cols)
+			length_type /*rows*/, length_type cols)
   {
     // Check that data is dense row-major.
     assert(r_stride == static_cast<stride_type>(cols));
@@ -290,7 +290,7 @@
 			    ctype *out,
 			    stride_type out_r_stride,
 			    stride_type out_c_stride,
-			    length_type rows, length_type cols)
+			    length_type /*rows*/, length_type cols)
   {
     // Check that data is dense row-major.
     assert(in_r_stride == static_cast<stride_type>(cols));
Index: src/vsip/impl/ipp/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp/fft.cpp,v
retrieving revision 1.5
diff -u -r1.5 fft.cpp
--- src/vsip/impl/ipp/fft.cpp	14 May 2006 07:36:03 -0000	1.5
+++ src/vsip/impl/ipp/fft.cpp	14 May 2006 20:50:26 -0000
@@ -377,30 +377,30 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  impl(Domain<1> const &dom, rtype scale)
+  impl(Domain<1> const &dom, rtype /*scale*/)
     : Driver<1, std::complex<T>, F>(dom)
   {
   }
-  virtual void in_place(ctype *inout, stride_type s, length_type l)
+  virtual void in_place(ctype *inout, stride_type s, length_type /*l*/)
   {
     assert(s == 1);
     if (E == -1) this->forward(inout, inout);
     else this->inverse(inout, inout);
   }
-  virtual void in_place(ztype inout, stride_type s, length_type l)
+  virtual void in_place(ztype, stride_type, length_type)
   {
   }
   virtual void by_reference(ctype *in, stride_type in_s,
 			    ctype *out, stride_type out_s,
-			    length_type l)
+			    length_type /*l*/)
   {
     assert(in_s == 1 && out_s == 1);
     if (E == -1) this->forward(in, out);
     else this->inverse(in, out);
   }
-  virtual void by_reference(ztype in, stride_type in_s,
-			    ztype out, stride_type out_s,
-			    length_type l)
+  virtual void by_reference(ztype, stride_type,
+			    ztype, stride_type,
+			    length_type)
   {
   }
 };
@@ -416,21 +416,21 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  impl(Domain<1> const &dom, rtype scale)
+  impl(Domain<1> const &dom, rtype /*scale*/)
     : Driver<1, T, F>(dom)
   {
   }
   virtual void by_reference(rtype *in, stride_type in_s,
 			    ctype *out, stride_type out_s,
-			    length_type l)
+			    length_type /*l*/)
   {
     assert(in_s == 1 && out_s == 1);
     if (E == -1) this->forward(in, reinterpret_cast<rtype*>(out));
     else this->inverse(in, reinterpret_cast<rtype*>(out));
   }
-  virtual void by_reference(rtype *in, stride_type in_s,
-			    ztype out, stride_type out_s,
-			    length_type l)
+  virtual void by_reference(rtype */*in*/, stride_type /*in_s*/,
+			    ztype /*out*/, stride_type /*out_s*/,
+			    length_type /*l*/)
   {
   }
 };
@@ -446,21 +446,21 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  impl(Domain<1> const &dom, rtype scale)
+  impl(Domain<1> const &dom, rtype /*scale*/)
     : Driver<1, T, F>(dom)
   {
   }
   virtual void by_reference(ctype *in, stride_type in_s,
 			    rtype *out, stride_type out_s,
-			    length_type l)
+			    length_type /*l*/)
   {
     assert(in_s == 1 && out_s == 1);
     if (E == -1) this->forward(reinterpret_cast<rtype*>(in), out);
     else this->inverse(reinterpret_cast<rtype*>(in), out);
   }
-  virtual void by_reference(ztype in, stride_type in_s,
-			    rtype *out, stride_type out_s,
-			    length_type l)
+  virtual void by_reference(ztype, stride_type,
+			    rtype*, stride_type,
+			    length_type)
   {
   }
 };
@@ -476,13 +476,13 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  impl(Domain<2> const &dom, rtype scale)
+  impl(Domain<2> const &dom, rtype /*scale*/)
     : Driver<2, std::complex<T>, F>(dom)
   {
   }
   virtual void in_place(ctype *inout,
 			stride_type r_stride, stride_type c_stride,
-			length_type rows, length_type cols)
+			length_type /*rows*/, length_type /*cols*/)
   {
     if (A == 0)
     {
@@ -498,15 +498,15 @@
     }
   }
   virtual void in_place(ztype,
-			stride_type r_stride, stride_type c_stride,
-			length_type rows, length_type cols)
+			stride_type, stride_type,
+			length_type, length_type)
   {
   }
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    ctype *out,
 			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+			    length_type /*rows*/, length_type /*cols*/)
   {
     if (A == 0)
     {
@@ -521,11 +521,11 @@
       else this->inverse(in, in_c_stride, out, out_c_stride);
     }
   }
-  virtual void by_reference(ztype in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    ztype out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(ztype,
+			    stride_type, stride_type,
+			    ztype,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
 };
@@ -634,7 +634,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  fftm(Domain<2> const &dom, rtype scalar)
+  fftm(Domain<2> const &dom, rtype /*scalar*/)
     : Driver<1, T, F>(dom[A]),
       mult_(dom[1 - A].size())
   {
@@ -660,11 +660,9 @@
 	this->forward(in, reinterpret_cast<rtype*>(out));
     }
   }
-  virtual void by_reference(rtype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    ztype out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(rtype*, stride_type, stride_type,
+			    ztype, stride_type, stride_type,
+			    length_type, length_type)
   {
   }
 
@@ -682,7 +680,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  fftm(Domain<2> const &dom, rtype scalar)
+  fftm(Domain<2> const &dom, rtype /*scalar*/)
     : Driver<1, T, F>(dom[A]),
       mult_(dom[1 - A].size())
   {
@@ -708,11 +706,9 @@
 	this->inverse(reinterpret_cast<rtype*>(in), out);
     }
   }
-  virtual void by_reference(ztype in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    rtype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(ztype, stride_type, stride_type,
+			    rtype *, stride_type, stride_type,
+			    length_type, length_type)
   {
   }
 
@@ -730,7 +726,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  fftm(Domain<2> const &dom, rtype scale)
+  fftm(Domain<2> const &dom, rtype /*scale*/)
     : Driver<1, std::complex<T>, F>(dom[A]),
       mult_(dom[1 - A].size())
   {
@@ -756,9 +752,8 @@
     }
   }
 
-  virtual void in_place(ztype inout,
-			stride_type r_stride, stride_type c_stride,
-			length_type rows, length_type cols)
+  virtual void in_place(ztype, stride_type, stride_type,
+			length_type, length_type)
   {
   }
 
@@ -785,11 +780,9 @@
 	else this->inverse(in, out);
     }
   }
-  virtual void by_reference(ztype in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    ztype out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(ztype, stride_type, stride_type,
+			    ztype, stride_type, stride_type,
+			    length_type, length_type)
   {
   }
 
Index: src/vsip/impl/ipp/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp/fft.hpp,v
retrieving revision 1.2
diff -u -r1.2 fft.hpp
--- src/vsip/impl/ipp/fft.hpp	13 May 2006 23:19:34 -0000	1.2
+++ src/vsip/impl/ipp/fft.hpp	14 May 2006 20:50:26 -0000
@@ -119,7 +119,7 @@
 struct evaluator<I, O, A, E, R, N, fft::Intel_ipp_tag>
 {
   static bool const ct_valid = true;
-  static bool rt_valid(Domain<2> const &dom) { return true;}
+  static bool rt_valid(Domain<2> const &) { return true;}
   static std::auto_ptr<fft::fftm<I, O, A, E> > 
   create(Domain<2> const &dom, typename Scalar_of<I>::type scale)
   {
Index: src/vsip/impl/sal/solver_svd.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/solver_svd.hpp,v
retrieving revision 1.2
diff -u -r1.2 solver_svd.hpp
--- src/vsip/impl/sal/solver_svd.hpp	13 May 2006 18:04:53 -0000	1.2
+++ src/vsip/impl/sal/solver_svd.hpp	14 May 2006 20:50:26 -0000
@@ -35,10 +35,6 @@
 namespace impl
 {
 
-COMPLEX_SPLIT *get_ptr(float *a,float *z,COMPLEX_SPLIT *temp_ptr)
-                                         { temp_ptr->realp = a; 
-                                           temp_ptr->imagp = z; 
-				           return temp_ptr; }
 // SAL SVD decomposition
 // SAL only supports SVD decomposition using COMPLEX SPLIT format. If we are
 // dealing with real numbers, we assign the imaginary part of the pointer to
@@ -55,9 +51,9 @@
   int flag)                                                 \
 {                                                           \
   int rank;                                                 \
-  COMPLEX_SPLIT temp_ptr;                                   \
+  COMPLEX_SPLIT temp_ptr = {a, z};			    \
                                                             \
-  return(SALFCN(get_ptr(a,z,&temp_ptr), tcols_a,            \
+  return(SALFCN(&temp_ptr, tcols_a,			    \
          D,                                                 \
 	 (COMPLEX_SPLIT*)&u, tcols_u,                       \
 	 (COMPLEX_SPLIT*)&v, tcols_v,                       \
@@ -68,7 +64,7 @@
 #define VSIP_IMPL_SAL_SVD_DEC_CPLX( T, D_T, SALFCN )        \
 inline bool                                                 \
 sal_mat_svd_dec(                                            \
-  T* z,                                                     \
+  T* /*z*/,						    \
   std::pair<T*,T*> a, int tcols_a,                          \
   std::pair<float*,float*> u, int tcols_u,                  \
   std::pair<float*,float*> v, int tcols_v,                  \
