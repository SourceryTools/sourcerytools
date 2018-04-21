Index: src/vsip/impl/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft.hpp,v
retrieving revision 1.2
diff -u -r1.2 fft.hpp
--- src/vsip/impl/fft.hpp	6 May 2006 22:09:27 -0000	1.2
+++ src/vsip/impl/fft.hpp	9 May 2006 19:38:16 -0000
@@ -206,9 +206,9 @@
 template <typename I,                       //< Input type
 	  typename O,                       //< Output type
 	  typename L,                       //< Library type-list
-	  int A = row,                      //< Axis
-	  int D = fft_fwd,                  //< Direction
-	  return_mechanism_type = by_value, //< Return mechanism
+	  int A,                            //< Axis
+	  int D,                            //< Direction
+	  return_mechanism_type,            //< Return mechanism
 	  unsigned N = 0,                   //< Number of times
 	  alg_hint_type = alg_time>         //< algorithm Hint
 class fftm_facade;
@@ -221,19 +221,13 @@
 	  unsigned N,
 	  alg_hint_type H>
 class fftm_facade<I, O, L, A, D, by_value, N, H>
-  : public fft::base_interface<2, I, O, 1 - A, D == -2 ? -1 : 1>
+  : public fft::base_interface<2, I, O, A, D == -2 ? -1 : 1>
 {
-  // The D template parameter in 2D Fft is '0' for column-first
-  // and '1' for row-first transformation. As Fftm's Axis parameter
-  // does the inverse, we use '1 - A' here to be able to share the same
-  // logic underneath.
-  static int const axis = 1 - A;
+  static int const axis = A;
   static int const exponent = D == -2 ? -1 : 1;
   typedef fft::base_interface<2, I, O, axis, exponent> base;
-  typedef typename ITE_Type<axis == 0,
-    As_type<fft::transpose_workspace<I, O> >,
-    As_type<fft::direct_workspace<I, O> > >::type workspace;
-  typedef fftm::factory<I, O, A, exponent, by_value, N, L> factory;
+  typedef fft::workspace<2, I, O, axis> workspace;
+  typedef fftm::factory<I, O, axis, exponent, by_value, N, L> factory;
 public:
   fftm_facade(Domain<2> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
@@ -265,18 +259,12 @@
 	  unsigned N,
 	  alg_hint_type H>
 class fftm_facade<I, O, L, A, D, vsip::by_reference, N, H>
-  : public fft::base_interface<2, I, O, 1 - A, D == -2 ? -1 : 1>
+  : public fft::base_interface<2, I, O, A, D == -2 ? -1 : 1>
 {
-  // The D template parameter in 2D Fft is '0' for column-first
-  // and '1' for row-first transformation. As Fftm's Axis parameter
-  // does the inverse, we use '1 - A' here to be able to share the same
-  // logic underneath.
-  static int const axis = 1 - A;
+  static int const axis = A;
   static int const exponent = D == -2 ? -1 : 1;
   typedef fft::base_interface<2, I, O, axis, exponent> base;
-  typedef typename ITE_Type<axis == 0,
-    As_type<fft::transpose_workspace<I, O> >,
-    As_type<fft::direct_workspace<I, O> > >::type workspace;
+  typedef fft::workspace<2, I, O, axis> workspace;
   typedef fftm::factory<I, O, axis, exponent, by_value, N, L> factory;
 public:
   fftm_facade(Domain<2> const& dom, typename base::scalar_type scale)
@@ -337,9 +325,14 @@
 	  unsigned N = 0,
 	  alg_hint_type H = alg_time>
 class Fftm : public impl::fftm_facade<I, O, impl::fft::LibraryTagList,
-				      A, D, R, N, H> 
+				      1 - A, D, R, N, H> 
 {
-  typedef impl::fftm_facade<I, O, impl::fft::LibraryTagList, A, D, R, N, H> base;
+  // The S template parameter in 2D Fft is '0' for column-first
+  // and '1' for row-first transformation. As Fftm's Axis parameter
+  // does the inverse, we use '1 - A' here to be able to share the same
+  // logic underneath.
+  typedef impl::fftm_facade<I, O, impl::fft::LibraryTagList,
+			    1 - A, D, R, N, H> base;
 public:
   Fftm(Domain<2> const& dom, typename base::scalar_type scale)
     VSIP_THROW((std::bad_alloc))
Index: src/vsip/impl/layout.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/layout.hpp,v
retrieving revision 1.21
diff -u -r1.21 layout.hpp
--- src/vsip/impl/layout.hpp	6 May 2006 21:27:06 -0000	1.21
+++ src/vsip/impl/layout.hpp	9 May 2006 19:38:19 -0000
@@ -53,6 +53,7 @@
 
   // Accessors.
 public:
+  T*               as_real() { return ptr_; }
   T*               as_inter() { return ptr_; }
   std::pair<T*,T*> as_split() { assert(0); return std::pair<T*,T*>(0,0); }
 
@@ -88,6 +89,7 @@
 
   // Acccessors
 public:
+  T*               as_real() { assert(0); return 0; }
   complex<T>*       as_inter() { return reinterpret_cast<complex<T>*>(ptr0_); }
   std::pair<T*, T*> as_split() { return std::pair<T*,T*>(ptr0_, ptr1_); }
 
@@ -1227,7 +1229,7 @@
     length_type     size,
     rt_complex_type cformat)
   {
-    if (cformat == cmplx_inter_fmt)
+    if (!Is_complex<T>::value || cformat == cmplx_inter_fmt)
     {
       return Rt_pointer<T>(alloc_align<T>(VSIP_IMPL_ALLOC_ALIGNMENT, size));
     }
Index: src/vsip/impl/fft/backend.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/backend.hpp,v
retrieving revision 1.1
diff -u -r1.1 backend.hpp
--- src/vsip/impl/fft/backend.hpp	1 May 2006 19:12:03 -0000	1.1
+++ src/vsip/impl/fft/backend.hpp	9 May 2006 19:38:31 -0000
@@ -17,6 +17,7 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
+#include <vsip/impl/layout.hpp>
 #include <vsip/impl/metaprogramming.hpp>
 
 namespace vsip
@@ -47,7 +48,14 @@
 public:
   virtual ~backend() {}
   virtual bool supports_scale() { return false;}
-//   virtual bool require_copy(in_stride, out_stride);
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    rtl_out.complex = cmplx_inter_fmt;
+  }
+  virtual bool requires_copy(Rt_layout<1> &) { return false;}
   /// real -> complex (interleaved)
   virtual void by_reference(T *in, stride_type in_stride,
 			    std::complex<T> *out, stride_type out_stride,
@@ -66,6 +74,14 @@
 public:
   virtual ~backend() {}
   virtual bool supports_scale() { return false;}
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+  }
+  virtual bool requires_copy(Rt_layout<1> &) { return false;}
   /// complex (interleaved) -> real
   virtual void by_reference(std::complex<T> *in, stride_type in_stride,
 			    T *out, stride_type out_stride,
@@ -84,6 +100,21 @@
 public:
   virtual ~backend() {}
   virtual bool supports_scale() { return false;}
+  virtual void query_layout(Rt_layout<1> &rtl_inout)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_inout.pack = stride_unit_dense;
+    rtl_inout.order = tuple<0, 1, 2>();
+    rtl_inout.complex = cmplx_inter_fmt;
+  }
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    rtl_in.complex = rtl_out.complex = cmplx_inter_fmt;
+  }
+  virtual bool requires_copy(Rt_layout<1> &) { return false;}
   /// complex (interleaved) in-place
   virtual void in_place(std::complex<T> *, stride_type, length_type) = 0;
   /// complex (split) in-place
@@ -106,6 +137,14 @@
 public:
   virtual ~backend() {}
   virtual bool supports_scale() { return false;}
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    rtl_out.complex = cmplx_inter_fmt;
+  }
+  virtual bool requires_copy(Rt_layout<2> &) { return false;}
   /// real -> complex (interleaved) by-reference
   virtual void by_reference(T *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
@@ -128,6 +167,14 @@
 public:
   virtual ~backend() {}
   virtual bool supports_scale() { return false;}
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+  }
+  virtual bool requires_copy(Rt_layout<2> &) { return false;}
   /// complex (interleaved) -> real by-reference
   virtual void by_reference(std::complex<T> *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
@@ -150,6 +197,21 @@
 public:
   virtual ~backend() {}
   virtual bool supports_scale() { return false;}
+  virtual void query_layout(Rt_layout<2> &rtl_inout)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_inout.pack = stride_unit_dense;
+    rtl_inout.order = tuple<0, 1, 2>();
+    rtl_inout.complex = cmplx_inter_fmt;
+  }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    rtl_in.complex = rtl_out.complex = cmplx_inter_fmt;
+  }
+  virtual bool requires_copy(Rt_layout<2> &) { return false;}
   /// complex (interleaved) in-place
   virtual void in_place(std::complex<T> *inout,
 			stride_type r_stride, stride_type c_stride,
@@ -180,6 +242,14 @@
 public:
   virtual ~backend() {}
   virtual bool supports_scale() { return false;}
+  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    rtl_out.complex = cmplx_inter_fmt;
+  }
+  virtual bool requires_copy(Rt_layout<3> &) { return false;}
   /// real -> complex (interleaved) by-reference
   virtual void by_reference(T *in,
 			    stride_type in_x_stride,
@@ -214,6 +284,14 @@
 public:
   virtual ~backend() {}
   virtual bool supports_scale() { return false;}
+  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+  }
+  virtual bool requires_copy(Rt_layout<3> &) { return false;}
   /// complex (interleaved) -> real by-reference
   virtual void by_reference(std::complex<T> *in,
 			    stride_type in_x_stride,
@@ -248,6 +326,21 @@
 public:
   virtual ~backend() {}
   virtual bool supports_scale() { return false;}
+  virtual void query_layout(Rt_layout<3> &rtl_inout)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_inout.pack = stride_unit_dense;
+    rtl_inout.order = tuple<0, 1, 2>();
+    rtl_inout.complex = cmplx_inter_fmt;
+  }
+  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    rtl_in.complex = rtl_out.complex = cmplx_inter_fmt;
+  }
+  virtual bool requires_copy(Rt_layout<3> &) { return false;}
   /// complex (interleaved) in-place
   virtual void in_place(std::complex<T> *inout,
 			stride_type x_stride,
@@ -301,6 +394,18 @@
 public:
   virtual ~fftm() {}
   virtual bool supports_scale() { return false;}
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    // By default use unit_stride,
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    // an ordering that gives unit strides on the axis perpendicular to A,
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else rtl_in.order = tuple<0, 1, 2>();
+    rtl_out.order = rtl_in.order;
+    // and interleaved complex.
+    rtl_out.complex = cmplx_inter_fmt;
+  }
+  virtual bool requires_copy(Rt_layout<2> &) { return false;}
   /// real -> complex (interleaved) by-reference
   virtual void by_reference(T *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
@@ -323,6 +428,18 @@
 public:
   virtual ~fftm() {}
   virtual bool supports_scale() { return false;}
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    // By default use unit_stride,
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    // an ordering that gives unit strides on the axis perpendicular to A,
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else rtl_in.order = tuple<0, 1, 2>();
+    rtl_out.order = rtl_in.order;
+    // and interleaved complex.
+    rtl_in.complex = cmplx_inter_fmt;
+  }
+  virtual bool requires_copy(Rt_layout<2> &) { return false;}
   /// complex (interleaved) -> real by-reference
   virtual void by_reference(std::complex<T> *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
@@ -345,6 +462,28 @@
 public:
   virtual ~fftm() {}
   virtual bool supports_scale() { return false;}
+  virtual void query_layout(Rt_layout<2> &rtl_inout)
+  {
+    // By default use unit_stride,
+    rtl_inout.pack = stride_unit_dense;
+    // an ordering that gives unit strides on the axis perpendicular to A,
+    if (A == 0) rtl_inout.order = tuple<1, 0, 2>();
+    else rtl_inout.order = tuple<0, 1, 2>();
+    // and interleaved complex.
+    rtl_inout.complex = cmplx_inter_fmt;
+  }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    // By default use unit_stride,
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    // an ordering that gives unit strides on the axis perpendicular to A,
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else rtl_in.order = tuple<0, 1, 2>();
+    rtl_out.order = rtl_in.order;
+    // and interleaved complex.
+    rtl_in.complex = rtl_out.complex = cmplx_inter_fmt;
+  }
+  virtual bool requires_copy(Rt_layout<2> &) { return false;}
   /// complex (interleaved) in-place
   virtual void in_place(std::complex<T> *inout,
 			stride_type r_stride, stride_type c_stride,
Index: src/vsip/impl/fft/dft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/dft.hpp,v
retrieving revision 1.1
diff -u -r1.1 dft.hpp
--- src/vsip/impl/fft/dft.hpp	6 May 2006 22:09:27 -0000	1.1
+++ src/vsip/impl/fft/dft.hpp	9 May 2006 19:38:33 -0000
@@ -28,6 +28,8 @@
 {
 namespace fft
 {
+namespace
+{
 template <typename T>
 inline vsip::complex<T>
 sin_cos(double phi)
@@ -35,6 +37,13 @@
   return vsip::complex<T>(cos(phi), sin(phi));
 }
 
+template <typename T>
+std::pair<T*,T*> offset(std::pair<T*,T*> data, int o)
+{
+  return std::make_pair(data.first + o, data.second + o);
+}
+
+}
 template <dimension_type D, typename I, typename O, int A, int E> class dft;
 
 // 1D complex -> complex DFT
@@ -48,6 +57,8 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual void query_layout(Rt_layout<1> &rtl_inout) {}
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out) {}
   virtual void in_place(ctype *inout, stride_type s, length_type l)
   {
     aligned_array<std::complex<T> > tmp(l);
@@ -123,6 +134,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out) {}
   virtual void by_reference(rtype *in, stride_type in_s,
 			    ctype *out, stride_type out_s,
 			    length_type l)
@@ -164,6 +176,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out) {}
   virtual void by_reference(ctype *in, stride_type in_s,
 			    rtype *out, stride_type out_s,
 			    length_type l)
@@ -189,11 +202,13 @@
     for (index_type w = 0; w < l; ++w)
     {
       complex<T> sum;
-      for (index_type k = 0; k < l; ++k)
-	sum += vsip::complex<T>(in.first[k * in_s], in.second[k * in_s])
+      for (index_type k = 0; k < l/2 + 1; ++k)
+	sum += complex<T>(in.first[k * in_s], in.second[k * in_s])
 	  * sin_cos<T>(phi * k * w);
+      for (index_type k = l/2 + 1; k < l; ++k)
+	sum += complex<T>(in.first[(l - k) * in_s], -in.second[(l - k) * in_s])
+	  * sin_cos<T>(phi * (l - k) * w);
       out[w * out_s] = sum.real();
-      //     out.second[w * out_s] = sum.imag();
     }
   }
 };
@@ -209,6 +224,8 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual void query_layout(Rt_layout<2> &rtl_inout) {}
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out) {}
   virtual void in_place(ctype *inout,
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
@@ -219,10 +236,23 @@
     for (length_type c = 0; c != cols; ++c)
       dft_1d.in_place(inout + c * c_stride, r_stride, rows);
   }
-  virtual void in_place(ztype,
+  virtual void in_place(ztype inout,
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
   {
+    dft<1, ctype, ctype, 0, E> dft_1d;
+    for (length_type r = 0; r != rows; ++r)
+    {
+      ztype line = std::make_pair(inout.first + r * r_stride,
+				  inout.second + r * r_stride);
+      dft_1d.in_place(line, c_stride, cols);
+    }
+    for (length_type c = 0; c != cols; ++c)
+    {
+      ztype line = std::make_pair(inout.first + c * c_stride,
+				  inout.second + c * c_stride);
+      dft_1d.in_place(line, r_stride, rows);
+    }
   }
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
@@ -243,6 +273,22 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
+    dft<1, ctype, ctype, 0, E> dft_1d;
+    for (length_type r = 0; r != rows; ++r)
+    {
+      ztype in_line = std::make_pair(in.first + r * in_r_stride,
+				     in.second + r * in_r_stride);
+      ztype out_line = std::make_pair(out.first + r * out_r_stride,
+				      out.second + r * out_r_stride);
+      dft_1d.by_reference(in_line, in_c_stride,
+			  out_line, out_c_stride, cols);
+    }
+    for (length_type c = 0; c != cols; ++c)
+    {
+      ztype line = std::make_pair(out.first + c * out_c_stride,
+				  out.second + c * out_c_stride);
+      dft_1d.in_place(line, out_r_stride, rows);
+    }
   }
 };
 
@@ -256,6 +302,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out) {}
   virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    ctype *out,
@@ -283,10 +330,44 @@
   }
   virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
-			    ztype,
+			    ztype out,
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
+    dft<1, rtype, ctype, 0, -1> rdft_1d;
+    dft<1, ctype, ctype, 0, -1> dft_1d;
+    if (A == 0)
+    {
+      for (length_type c = 0; c != cols; ++c)
+      {
+	ztype line = std::make_pair(out.first + c * out_c_stride,
+				    out.second + c * out_c_stride);
+	rdft_1d.by_reference(in + c * in_c_stride, in_r_stride,
+			     line, out_r_stride, rows);
+      }
+      for (length_type r = 0; r != rows/2 + 1; ++r)
+      {
+	ztype line = std::make_pair(out.first + r * out_r_stride,
+				    out.second + r * out_r_stride);
+	dft_1d.in_place(line, out_c_stride, cols);
+      }
+    }
+    else
+    {
+      for (length_type r = 0; r != rows; ++r)
+      {
+	ztype line = std::make_pair(out.first + r * out_r_stride,
+				    out.second + r * out_r_stride);
+	rdft_1d.by_reference(in + r * in_r_stride, in_c_stride,
+			     line, out_c_stride, cols);
+      }
+      for (length_type c = 0; c != cols/2 + 1; ++c)
+      {
+	ztype line = std::make_pair(out.first + c * out_c_stride,
+				    out.second + c * out_c_stride);
+	dft_1d.in_place(line, out_r_stride, rows);
+      }
+    }
   }
 
 };
@@ -301,6 +382,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out) {}
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    rtype *out,
@@ -309,14 +391,10 @@
   {
     dft<1, ctype, ctype, 0, 1> dft_1d;
     dft<1, ctype, rtype, 0, 1> rdft_1d;
-    std::cout << "axis " << A << std::endl;
-    std::cout << in_r_stride << ' ' << in_c_stride << ' '
-	      << out_r_stride << ' ' << out_c_stride << ' '
-	      << rows << ' ' << cols << std::endl;
     if (A == 0)
     {
       length_type rows2 = rows/2 + 1;
-      aligned_array<ctype> tmp(rows2 * cols); // col-major temp matrix.
+      aligned_array<ctype> tmp(rows2 * cols); // row-major temp matrix.
       for (length_type r = 0; r != rows2; ++r)
 	dft_1d.by_reference(in + r * in_r_stride, in_c_stride,
 			    tmp.get() + r * cols, 1, cols);
@@ -327,7 +405,7 @@
     else
     {
       length_type cols2 = cols/2 + 1;
-      aligned_array<ctype> tmp(rows * cols2); // row-major temp matrix.
+      aligned_array<ctype> tmp(rows * cols2); // col-major temp matrix.
       for (length_type c = 0; c != cols2; ++c)
 	dft_1d.by_reference(in + c * in_c_stride, in_r_stride,
 			    tmp.get() + c * rows, 1, rows);
@@ -336,12 +414,54 @@
 			     out + r * out_r_stride, out_c_stride, cols);
     }
   }
-  virtual void by_reference(ztype,
+  virtual void by_reference(ztype in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    rtype *out,
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
+    dft<1, ctype, ctype, 0, 1> dft_1d;
+    dft<1, ctype, rtype, 0, 1> rdft_1d;
+    if (A == 0)
+    {
+      length_type rows2 = rows/2 + 1;
+      aligned_array<rtype> tmp_r(rows2 * cols); // col-major temp real matrix.
+      aligned_array<rtype> tmp_i(rows2 * cols); // col-major temp imag matrix.
+      for (length_type r = 0; r != rows2; ++r)
+      {
+	ztype line = std::make_pair(tmp_r.get() + r * cols,
+				    tmp_i.get() + r * cols);
+	dft_1d.by_reference(offset(in, r * in_r_stride), in_c_stride,
+			    line, 1, cols);
+      }
+      for (length_type c = 0; c != cols; ++c)
+      {
+	ztype line = std::make_pair(tmp_r.get() + c,
+				    tmp_i.get() + c);
+	rdft_1d.by_reference(line, cols,
+			     out + c * out_c_stride, out_r_stride, rows);
+      }
+    }
+    else
+    {
+      length_type cols2 = cols/2 + 1;
+      aligned_array<rtype> tmp_r(rows * cols2); // col-major temp real matrix.
+      aligned_array<rtype> tmp_i(rows * cols2); // col-major temp imag matrix.
+      for (length_type c = 0; c != cols2; ++c)
+      {
+	ztype line = std::make_pair(tmp_r.get() + c * rows,
+				    tmp_i.get() + c * rows);
+	dft_1d.by_reference(offset(in, c * in_c_stride), in_r_stride,
+			    line, 1, rows);
+      }
+      for (length_type r = 0; r != rows; ++r)
+      {
+	ztype line = std::make_pair(tmp_r.get() + r,
+				    tmp_i.get() + r);
+	rdft_1d.by_reference(line, rows,
+			     out + r * out_r_stride, out_c_stride, cols);
+      }
+    }
   }
 
 };
@@ -357,6 +477,8 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual void query_layout(Rt_layout<3> &rtl_inout) {}
+  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out) {}
   virtual void in_place(ctype *inout,
 			stride_type x_stride,
 			stride_type y_stride,
@@ -413,6 +535,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out) {}
   virtual void by_reference(rtype *in,
 			    stride_type in_x_stride,
 			    stride_type in_y_stride,
@@ -452,6 +575,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out) {}
   virtual void by_reference(ctype *in,
 			    stride_type in_x_stride,
 			    stride_type in_y_stride,
@@ -493,6 +617,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out) {}
   virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    ctype *out,
@@ -515,6 +640,15 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
+    dft<1, rtype, ctype, 0, -1> rdft;
+    if (A == 0)
+      for (length_type c = 0; c != cols; ++c)
+	rdft.by_reference(in + c * in_c_stride, in_r_stride,
+			  offset(out, c * out_c_stride), out_r_stride, rows);
+    else
+      for (length_type r = 0; r != rows; ++r)
+	rdft.by_reference(in + r * in_r_stride, in_c_stride,
+			  offset(out, r * out_r_stride), out_c_stride, cols);
   }
 };
 
@@ -528,6 +662,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out) {}
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    rtype *out,
@@ -554,6 +689,27 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
+    dft<1, ctype, rtype, 0, 1> rdft;
+    if (A == 0)
+    {
+      for (length_type c = 0; c != cols; ++c)
+      {
+	ztype line = std::make_pair(in.first + c * in_c_stride,
+				    in.second + c * in_c_stride);
+	rdft.by_reference(line, in_r_stride,
+			  out + c * out_c_stride, out_r_stride, rows);
+      }
+    }
+    else
+    {
+      for (length_type r = 0; r != rows; ++r)
+      {
+	ztype line = std::make_pair(in.first + r * in_r_stride,
+				    in.second + r * in_r_stride);
+	rdft.by_reference(line, in_c_stride,
+			  out + r * out_r_stride, out_c_stride, cols);
+      }
+    }
   }
 };
 
@@ -567,6 +723,8 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual void query_layout(Rt_layout<2> &rtl_inout) {}
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out) {}
   virtual void in_place(ctype *inout,
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
@@ -584,6 +742,21 @@
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
   {
+    dft<1, ctype, ctype, 0, E> dft_1d;
+    if (A == 0)
+      for (length_type c = 0; c != cols; ++c)
+      {
+	ztype line = std::make_pair(inout.first + c * c_stride,
+				    inout.second + c * c_stride);
+	dft_1d.in_place(line, r_stride, rows);
+      }
+    else
+      for (length_type r = 0; r != rows; ++r)
+      {
+	ztype line = std::make_pair(inout.first + r * r_stride,
+				    inout.second + r * r_stride);
+	dft_1d.in_place(line, c_stride, cols);
+      }
   }
 
   virtual void by_reference(ctype *in,
@@ -608,6 +781,27 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
+    dft<1, ctype, ctype, 0, E> dft_1d;
+    if (A == 0)
+      for (length_type c = 0; c != cols; ++c)
+      {
+	ztype in_line = std::make_pair(in.first + c * in_c_stride,
+				       in.second + c * in_c_stride);
+	ztype out_line = std::make_pair(out.first + c * out_c_stride,
+					out.second + c * out_c_stride);
+	dft_1d.by_reference(in_line, in_r_stride,
+			    out_line, out_r_stride, rows);
+      }
+    else
+      for (length_type r = 0; r != rows; ++r)
+      {
+	ztype in_line = std::make_pair(in.first + r * in_r_stride,
+				       in.second + r * in_r_stride);
+	ztype out_line = std::make_pair(out.first + r * out_r_stride,
+					out.second + r * out_r_stride);
+	dft_1d.by_reference(in_line, in_c_stride,
+			    out_line, out_c_stride, cols);
+      }
   }
 };
 
Index: src/vsip/impl/fft/no_fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/no_fft.hpp,v
retrieving revision 1.1
diff -u -r1.1 no_fft.hpp
--- src/vsip/impl/fft/no_fft.hpp	6 May 2006 22:09:27 -0000	1.1
+++ src/vsip/impl/fft/no_fft.hpp	9 May 2006 19:38:56 -0000
@@ -32,7 +32,7 @@
 {
   no_fft_base() 
   {
-//     std::cout << "constructing no_fft_base" << std::endl;
+    std::cout << "constructing no_fft_base" << std::endl;
   }
 };
 
Index: src/vsip/impl/fft/workspace.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/workspace.hpp,v
retrieving revision 1.2
diff -u -r1.2 workspace.hpp
--- src/vsip/impl/fft/workspace.hpp	6 May 2006 22:09:27 -0000	1.2
+++ src/vsip/impl/fft/workspace.hpp	9 May 2006 19:38:56 -0000
@@ -20,6 +20,7 @@
 #include <vsip/impl/adjust-layout.hpp>
 #include <vsip/impl/allocation.hpp>
 #include <vsip/impl/equal.hpp>
+#include <vsip/impl/rt_extdata.hpp>
 #include <iostream>
 
 /***********************************************************************
@@ -39,228 +40,357 @@
 template <dimension_type D, typename I, typename O, int A>
 class workspace;
 
-template <typename I, typename O>
-class workspace<1, I, O, 0>
+template <typename T>
+class workspace<1, std::complex<T>, std::complex<T>, 0>
 {
-  typedef typename Scalar_of<I>::type scalar_type;
 public:
-  workspace(Domain<1> const &, scalar_type scale)
+  workspace(Domain<1> const &, T scale)
     : scale_(scale)
   {}
   
   template <typename BE, typename Block0, typename Block1>
   void by_reference(BE *backend,
-		    const_Vector<I, Block0> in, Vector<O, Block1> out)
+		    const_Vector<std::complex<T>, Block0> in,
+		    Vector<std::complex<T>, Block1> out)
   {
-//       typedef typename Block_layout<Block0>::layout_type in_layout;
-//       typedef typename Block_layout<Block1>::layout_type out_layout;
-    typedef impl::Layout<1, tuple<0,1,2>, Stride_unit, Cmplx_inter_fmt> in_layout;
-    typedef impl::Layout<1, tuple<0,1,2>, Stride_unit, Cmplx_inter_fmt> out_layout;
-
-//     static bool const is_split  =
-//       impl::Type_equal<typename impl::Block_layout<Block0>::complex_type,
-//                        impl::Cmplx_split_fmt>::value;
-    {
-      Ext_data<Block0, in_layout,No_count_policy,Copy_access_tag> 
-	in_ext(in.block(), SYNC_IN);
-      Ext_data<Block1, out_layout,No_count_policy,Copy_access_tag>
-	out_ext(out.block(), SYNC_OUT);
-      // If this is a real FFT we need to make sure we pass N, not N/2+1 as size.
-      length_type size = std::max(in_ext.size(0), out_ext.size(0));
-      if (in_ext.stride(0) == 1 && out_ext.stride(0) == 1)
-	backend->by_reference(in_ext.data(), in_ext.stride(0),
-			      out_ext.data(), out_ext.stride(0), size);
+    // Find out about the blocks's actual layout.
+    Rt_layout<1> rtl_in = block_layout<1>(in.block()); 
+    Rt_layout<1> rtl_out = block_layout<1>(out.block()); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN; 
 
+    {
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+    
+      // Call the backend.
+      assert(rtl_in.complex == rtl_out.complex);
+      if (rtl_in.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_inter(), in_ext.stride(0),
+			      out_ext.data().as_inter(), out_ext.stride(0),
+			      in_ext.size(0));
+      else
+	backend->by_reference(in_ext.data().as_split(), in_ext.stride(0),
+			      out_ext.data().as_split(), out_ext.stride(0),
+			      in_ext.size(0));
     }
-    if (!backend->supports_scale() && !almost_equal(scale_, scalar_type(1.)))
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
       out *= scale_;
   }
 
   template <typename BE, typename BlockT>
-  void in_place(BE *backend, Vector<I,BlockT> inout)
+  void in_place(BE *backend, Vector<std::complex<T>,BlockT> inout)
   {
-    typedef impl::Layout<1, tuple<0,1,2>, Stride_unit, Cmplx_inter_fmt> layout;
+    // Find out about the block's actual layout.
+    Rt_layout<1> rtl_inout = block_layout<1>(inout.block()); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_inout);
     {
-      vsip::impl::Ext_data<BlockT, layout,No_count_policy,Copy_access_tag>
-	inout_ext(inout.block(), vsip::impl::SYNC_INOUT);
-      if (inout_ext.stride(0) == 1)
-	backend->in_place(inout_ext.data(), inout_ext.stride(0), inout_ext.size(0));
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<BlockT> inout_ext(inout.block(), rtl_inout, SYNC_INOUT);
+    
+      // Call the backend.
+      if (rtl_inout.complex == cmplx_inter_fmt) 
+	backend->in_place(inout_ext.data().as_inter(),
+			  inout_ext.stride(0), inout_ext.size(0));
+      else
+	backend->in_place(inout_ext.data().as_split(),
+			  inout_ext.stride(0), inout_ext.size(0));
     }
-    if (!backend->supports_scale() && !almost_equal(scale_, scalar_type(1.)))
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
       inout *= scale_;
   }
 
 private:
-  scalar_type scale_;
+  T scale_;
 };
 
-/// workspace for column-wise FFTMs (and column-first 2D FFTs). As all backends
-/// support unit-stride in the major dimension, this is optimized for col-major
-/// storage.
-template <typename I, typename O>
-class transpose_workspace
+template <typename T>
+class workspace<1, T, std::complex<T>, 0>
 {
-  typedef typename Scalar_of<I>::type scalar_type;
-
 public:
-  transpose_workspace(Domain<2> const &dom, scalar_type scale)
-    : input_buffer_(io_size<2, I, O, 0>::size(dom).size()),
-      output_buffer_(io_size<2, O, I, 0>::size(dom).size()),
-      scale_(scale) 
+  workspace(Domain<1> const &, T scale)
+    : scale_(scale)
   {}
   
   template <typename BE, typename Block0, typename Block1>
   void by_reference(BE *backend,
-		    const_Matrix<I,Block0> in, Matrix<O,Block1> out)
+		    const_Vector<T, Block0> in,
+		    Vector<std::complex<T>, Block1> out)
   {
-//     typedef typename Block_layout<Block0>::layout_type in_l;
-//     typedef typename Block_layout<Block1>::layout_type out_l;
-
-    typedef Layout<2, tuple<1,0,2>, Stride_unit, Cmplx_inter_fmt>
-      in_layout;
-    typedef Layout<2, tuple<1,0,2>, Stride_unit, Cmplx_inter_fmt>
-      out_layout;
-
-//     typedef typename Adjust_layout<typename Block0::value_type,
-//       in_trans_layout, in_l>::type
-//       in_layout;
-//     typedef typename Adjust_layout<typename Block0::value_type,
-//       out_trans_layout, out_l>::type
-//       out_layout;
-
+    // Find out about the blocks's actual layout.
+    Rt_layout<1> rtl_in = block_layout<1>(in.block()); 
+    Rt_layout<1> rtl_out = block_layout<1>(out.block()); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN; 
     {
-//       std::cout << "transpose 2D column-wise by-reference" << std::endl;
-      Ext_data<Block0, in_layout,No_count_policy,Copy_access_tag>
-	in_ext(in.block(), SYNC_IN, input_buffer_.get());
-      Ext_data<Block1, out_layout,No_count_policy,Copy_access_tag>
-	out_ext(out.block(), SYNC_OUT, output_buffer_.get());
-      // If this is a real FFT we need to make sure we pass N, not N/2+1 as size.
-      length_type rows = std::max(in_ext.size(0), out_ext.size(0));
-      length_type cols = std::max(in_ext.size(1), out_ext.size(1));
-      // These blocks are col-major, so we always accept them if their rows have
-      // unit-stride.
-      if (in_ext.stride(0) == 1 && out_ext.stride(0) == 1)
-	backend->by_reference(in_ext.data(), in_ext.stride(0), in_ext.stride(1),
-			      out_ext.data(), out_ext.stride(0), out_ext.stride(1),
-			      rows, cols);
-      else std::cout << "TBD" << std::endl;
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+    
+      // Call the backend.
+      if (rtl_out.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_real(), in_ext.stride(0),
+			      out_ext.data().as_inter(), out_ext.stride(0),
+			      in_ext.size(0));
+      else
+	backend->by_reference(in_ext.data().as_real(), in_ext.stride(0),
+			      out_ext.data().as_split(), out_ext.stride(0),
+			      in_ext.size(0));
     }
-    if (!backend->supports_scale() && !almost_equal(scale_, scalar_type(1.)))
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
       out *= scale_;
   }
-  template <typename BE, typename BlockT>
-  void in_place(BE *backend, Matrix<I,BlockT> inout)
+
+private:
+  T scale_;
+};
+
+template <typename T>
+class workspace<1, std::complex<T>, T, 0>
+{
+public:
+  workspace(Domain<1> const &, T scale)
+    : scale_(scale)
+  {}
+  
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference(BE *backend,
+		    const_Vector<std::complex<T>, Block0> in,
+		    Vector<T, Block1> out)
   {
-//     std::cout << "transpose 2D column-wise in-place " << inout.block().size(2, 0) << ' ' << inout.block().size(2, 1) << std::endl;
-//     typedef typename Block_layout<BlockT>::layout_type l;
-    typedef Layout<2, tuple<1,0,2>, Stride_unit, Cmplx_inter_fmt> layout;
-//     typedef typename Adjust_layout<typename BlockT::value_type,
-//       trans_layout, l>::type
-//       layout;
-    {
-      Ext_data<BlockT, layout, No_count_policy,Copy_access_tag> 
-	inout_ext(inout.block(), SYNC_INOUT, input_buffer_.get());
-      // This block is col-major, so we always accept it if its rows have
-      // unit-stride.
-      if (inout_ext.stride(0) == 1)
-	backend->in_place(inout_ext.data(), inout_ext.stride(0), inout_ext.stride(1),
-			  inout_ext.size(0), inout_ext.size(1));
+    // Find out about the blocks's actual layout.
+    Rt_layout<1> rtl_in = block_layout<1>(in.block()); 
+    Rt_layout<1> rtl_out = block_layout<1>(out.block()); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN;
+    { 
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+    
+      // Call the backend.
+      if (rtl_in.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_inter(), in_ext.stride(0),
+			      out_ext.data().as_real(), out_ext.stride(0),
+			      out_ext.size(0));
+      else
+	backend->by_reference(in_ext.data().as_split(), in_ext.stride(0),
+			      out_ext.data().as_real(), out_ext.stride(0),
+			      out_ext.size(0));
     }
-    if (!backend->supports_scale() && !almost_equal(scale_, scalar_type(1.)))
-      inout *= scale_;
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      out *= scale_;
   }
 
 private:
-  aligned_array<I> input_buffer_;
-  aligned_array<O> output_buffer_;
-  scalar_type scale_;
+  T scale_;
 };
 
-/// workspace for row-wise FFTMs (and row-first 2D FFTs). As all backends
-/// support unit-stride in the major dimension, this is optimized for row-major
-/// storage.
-template <typename I, typename O>
-class direct_workspace
+template <typename T, int A>
+class workspace<2, std::complex<T>, std::complex<T>, A>
 {
-  typedef typename Scalar_of<I>::type scalar_type;
-
 public:
-  direct_workspace(Domain<2> const &dom, scalar_type scale)
-    : input_buffer_(32, io_size<2, I, O, 1>::size(dom).size()),
-      output_buffer_(32, io_size<2, O, I, 1>::size(dom).size()),
-      scale_(scale)
+  workspace(Domain<2> const &, T scale)
+    : scale_(scale)
   {}
   
   template <typename BE, typename Block0, typename Block1>
   void by_reference(BE *backend,
-		    const_Matrix<I,Block0> in, Matrix<O,Block1> out)
+		    const_Matrix<std::complex<T>, Block0> in,
+		    Matrix<std::complex<T>, Block1> out)
   {
-    typedef Layout<2, tuple<0,1,2>, Stride_unit, Cmplx_inter_fmt> layout;
+    // Find out about the blocks's actual layout.
+    Rt_layout<2> rtl_in = block_layout<2>(in.block()); 
+    Rt_layout<2> rtl_out = block_layout<2>(out.block()); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN; 
     {
-      Ext_data<Block0, layout,No_count_policy,Copy_access_tag> 
-	in_ext(in.block(), SYNC_IN, input_buffer_.get());
-      Ext_data<Block1, layout,No_count_policy,Copy_access_tag> 
-	out_ext(out.block(), SYNC_OUT, output_buffer_.get());
-      // If this is a real FFT we need to make sure we pass N, not N/2+1 as size.
-      length_type rows = std::max(in_ext.size(0), out_ext.size(0));
-      length_type cols = std::max(in_ext.size(1), out_ext.size(1));
-      if (in_ext.stride(1) == 1 && out_ext.stride(1) == 1)
-	backend->by_reference(in_ext.data(), in_ext.stride(0), in_ext.stride(1),
-			      out_ext.data(), out_ext.stride(0), out_ext.stride(1),
-			      rows, cols);
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+    
+      // Call the backend.
+      assert(rtl_in.complex == rtl_out.complex);
+      if (rtl_in.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_inter(),
+			      in_ext.stride(0), in_ext.stride(1),
+			      out_ext.data().as_inter(),
+			      out_ext.stride(0), out_ext.stride(1),
+			      in_ext.size(0), in_ext.size(1));
+      else
+	backend->by_reference(in_ext.data().as_split(),
+			      in_ext.stride(0), in_ext.stride(1),
+			      out_ext.data().as_split(),
+			      out_ext.stride(0), out_ext.stride(1),
+			      in_ext.size(0), in_ext.size(1));
     }
-    if (!backend->supports_scale() && !almost_equal(scale_, scalar_type(1.)))
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
       out *= scale_;
   }
+
   template <typename BE, typename BlockT>
-  void in_place(BE *backend, Matrix<I,BlockT> inout)
+  void in_place(BE *backend, Matrix<std::complex<T>,BlockT> inout)
   {
-    typedef Layout<2, tuple<0,1,2>, Stride_unit, Cmplx_inter_fmt> layout;
+    // Find out about the block's actual layout.
+    Rt_layout<2> rtl_inout = block_layout<2>(inout.block()); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_inout);
     {
-      Ext_data<BlockT, layout,No_count_policy,Copy_access_tag>
-	inout_ext(inout.block(), SYNC_INOUT, input_buffer_.get());
-      if (inout_ext.stride(1) == 1)
-	backend->in_place(inout_ext.data(),
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<BlockT> inout_ext(inout.block(), rtl_inout, SYNC_INOUT);
+    
+      // Call the backend.
+      if (rtl_inout.complex == cmplx_inter_fmt) 
+	backend->in_place(inout_ext.data().as_inter(),
+			  inout_ext.stride(0), inout_ext.stride(1), 
+			  inout_ext.size(0), inout_ext.size(1));
+      else
+	backend->in_place(inout_ext.data().as_split(),
 			  inout_ext.stride(0), inout_ext.stride(1),
 			  inout_ext.size(0), inout_ext.size(1));
     }
-    if (!backend->supports_scale() && !almost_equal(scale_, scalar_type(1.)))
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
       inout *= scale_;
   }
 
 private:
-  aligned_array<I> input_buffer_;
-  aligned_array<O> output_buffer_;
-  scalar_type scale_;
+  T scale_;
 };
 
-// In the general case for column-wise ffts we have to transpose.
-template <typename I, typename O> 
-struct workspace<2, I, O, 0> : transpose_workspace<I, O> 
-{
-  workspace(Domain<2> const &dom, typename Scalar_of<I>::type scale)
-    : transpose_workspace<I,O>(dom, scale) {}
-};
-// In the general case for row-wise ffts we don't need to transpose.
-template <typename I, typename O> 
-struct workspace<2, I, O, 1> : direct_workspace<I, O> 
-{
-  workspace(Domain<2> const &dom, typename Scalar_of<I>::type scale)
-    : direct_workspace<I,O>(dom, scale) {}
-};
-// For complex transforms we don't transpose, no matter the axis.
-template <typename T> 
-struct workspace<2, T, T, 0> : direct_workspace<T, T> 
+template <typename T, int A>
+class workspace<2, T, std::complex<T>, A>
 {
-  workspace(Domain<2> const &dom, typename Scalar_of<T>::type scale)
-    : direct_workspace<T,T>(dom, scale) {}
+public:
+  workspace(Domain<2> const &, T scale)
+    : scale_(scale)
+  {}
+  
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference(BE *backend,
+		    const_Matrix<T, Block0> in,
+		    Matrix<std::complex<T>, Block1> out)
+  {
+    // Find out about the blocks's actual layout.
+    Rt_layout<2> rtl_in = block_layout<2>(in.block()); 
+    Rt_layout<2> rtl_out = block_layout<2>(out.block()); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN; 
+    {
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+    
+      // Call the backend.
+      if (rtl_out.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_real(),
+			      in_ext.stride(0), in_ext.stride(1),
+			      out_ext.data().as_inter(),
+			      out_ext.stride(0), out_ext.stride(1),
+			      in_ext.size(0), in_ext.size(1));
+      else
+	backend->by_reference(in_ext.data().as_real(),
+			      in_ext.stride(0), in_ext.stride(1),
+			      out_ext.data().as_split(),
+			      out_ext.stride(0), out_ext.stride(1),
+			      in_ext.size(0), in_ext.size(1));
+    }
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      out *= scale_;
+  }
+
+private:
+  T scale_;
 };
-// For complex transforms we don't transpose, no matter the axis.
-template <typename T> 
-struct workspace<2, T, T, 1> : direct_workspace<T, T> 
+
+template <typename T, int A>
+class workspace<2, std::complex<T>, T, A>
 {
-  workspace(Domain<2> const &dom, typename Scalar_of<T>::type scale)
-    : direct_workspace<T,T>(dom, scale) {}
+public:
+  workspace(Domain<2> const &, T scale)
+    : scale_(scale)
+  {}
+  
+  template <typename BE, typename Block0, typename Block1>
+  void by_reference(BE *backend,
+		    const_Matrix<std::complex<T>, Block0> in,
+		    Matrix<T, Block1> out)
+  {
+    // Find out about the blocks's actual layout.
+    Rt_layout<2> rtl_in = block_layout<2>(in.block()); 
+    Rt_layout<2> rtl_out = block_layout<2>(out.block()); 
+    
+    // Find out about what layout is acceptable for this backend.
+    backend->query_layout(rtl_in, rtl_out);
+    // Check whether the input buffer will be destroyed.
+    sync_action_type in_sync = backend->requires_copy(rtl_in)
+      ? SYNC_IN_NOPRESERVE
+      : SYNC_IN;
+    { 
+      // Create a 'direct data accessor', adjusting the block layout if necessary.
+      Rt_ext_data<Block0> in_ext(in.block(), rtl_in, in_sync);
+      Rt_ext_data<Block1> out_ext(out.block(), rtl_out, SYNC_OUT);
+    
+      // Call the backend.
+      if (rtl_in.complex == cmplx_inter_fmt) 
+	backend->by_reference(in_ext.data().as_inter(),
+			      in_ext.stride(0), in_ext.stride(1),
+			      out_ext.data().as_real(),
+			      out_ext.stride(0), out_ext.stride(1),
+			      out_ext.size(0), out_ext.size(1));
+      else
+	backend->by_reference(in_ext.data().as_split(),
+			      in_ext.stride(0), in_ext.stride(1),
+			      out_ext.data().as_real(),
+			      out_ext.stride(0), out_ext.stride(1),
+			      out_ext.size(0), out_ext.size(1));
+    }
+    // Scale the data if not already done by the backend.
+    if (!backend->supports_scale() && !almost_equal(scale_, T(1.)))
+      out *= scale_;
+  }
+
+private:
+  T scale_;
 };
 
 template <typename I, typename O, int A>
Index: src/vsip/impl/fftw3/fft_impl.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fftw3/fft_impl.cpp,v
retrieving revision 1.1
diff -u -r1.1 fft_impl.cpp
--- src/vsip/impl/fftw3/fft_impl.cpp	1 May 2006 19:12:04 -0000	1.1
+++ src/vsip/impl/fftw3/fft_impl.cpp	9 May 2006 19:38:57 -0000
@@ -39,8 +39,7 @@
       : in_buffer_(32, dom.size()),
 	out_buffer_(32, dom.size())
   {
-    for (vsip::dimension_type i = 0; i < D; ++i)
-      size_[i] = dom[i].size();
+    for (vsip::dimension_type i = 0; i < D; ++i) size_[i] = dom[i].size();
     plan_in_place_ = FFTW(plan_dft)(D, size_,
       reinterpret_cast<FFTW(complex)*>(in_buffer_.get()),
       reinterpret_cast<FFTW(complex)*>(in_buffer_.get()),
@@ -79,10 +78,10 @@
     : in_buffer_(32, dom.size()),
       out_buffer_(32, dom.size())
   { 
-    for (vsip::dimension_type i = 0; i < D; ++i) size_[i] = dom[i].size();
-    if (A != D - 1)   // FFTW3 assumes sd == D - 1
-      std::swap(size_[A], size_[D - 1]);
-  
+    for (vsip::dimension_type i = 0; i < D; ++i) size_[i] = dom[i].size();  
+    // FFTW3 assumes A == D - 1.
+    // See also query_layout().
+    if (A != D - 1) std::swap(size_[A], size_[D - 1]);
     plan_by_reference_ = FFTW(plan_dft_r2c)(
       D, size_,
       in_buffer_.get(), reinterpret_cast<FFTW(complex)*>(out_buffer_.get()),
@@ -104,16 +103,15 @@
 template <vsip::dimension_type D>
 struct fft_base<D, std::complex<SCALAR_TYPE>, SCALAR_TYPE>
 {
-  fft_base(Domain<D> const& dom, int sd, int flags)
+  fft_base(Domain<D> const& dom, int A, int flags)
     VSIP_THROW((std::bad_alloc))
     : in_buffer_(32, dom.size()),
       out_buffer_(32, dom.size())
   {
     for (vsip::dimension_type i = 0; i < D; ++i) size_[i] = dom[i].size();
-    if (sd != D - 1)   // FFTW3 assumes sd == D - 1
-      std::swap(size_[sd], size_[D - 1]);
-  
-    // NB: This scribbles on its input, so we have to force a copy.
+    // FFTW3 assumes A == D - 1.
+    // See also query_layout().
+    if (A != D - 1) std::swap(size_[A], size_[D - 1]);
     plan_by_reference_ = FFTW(plan_dft_c2r)(
       D, size_,
       reinterpret_cast<FFTW(complex)*>(in_buffer_.get()), out_buffer_.get(),
@@ -141,9 +139,9 @@
 			A, E>
 
 {
-  typedef SCALAR_TYPE stype;
-  typedef std::complex<stype> ctype;
-  typedef std::pair<stype*, stype*> ztype;
+  typedef SCALAR_TYPE rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
 
 public:
   impl(Domain<1> const &dom, unsigned number)
@@ -158,7 +156,6 @@
   }
   virtual void in_place(ztype, stride_type, length_type)
   {
-    assert(0);
   }
   virtual void by_reference(ctype *in, stride_type in_stride,
 			    ctype *out, stride_type out_stride,
@@ -173,7 +170,6 @@
 			    ztype, stride_type out_stride,
 			    length_type length)
   {
-    assert(0);
   }
 };
 
@@ -184,26 +180,25 @@
   : private fft_base<1, SCALAR_TYPE, std::complex<SCALAR_TYPE> >,
     public fft::backend<1, SCALAR_TYPE, std::complex<SCALAR_TYPE>, A, E>
 {
-  typedef SCALAR_TYPE stype;
-  typedef std::complex<stype> ctype;
-  typedef std::pair<stype*, stype*> ztype;
+  typedef SCALAR_TYPE rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
 
 public:
   impl(Domain<1> const &dom, unsigned number)
-    : fft_base<1, stype, ctype>(dom, A, convert_NoT(number))
+    : fft_base<1, rtype, ctype>(dom, A, convert_NoT(number))
   {}
-  virtual void by_reference(stype *in, stride_type in_stride,
+  virtual void by_reference(rtype *in, stride_type in_stride,
 			    ctype *out, stride_type out_stride,
 			    length_type length)
   {
     FFTW(execute_dft_r2c)(plan_by_reference_, 
 			  in, reinterpret_cast<FFTW(complex)*>(out));
   }
-  virtual void by_reference(stype *in, stride_type in_stride,
+  virtual void by_reference(rtype *in, stride_type in_stride,
 			    ztype out, stride_type out_stride,
 			    length_type length)
   {
-    assert(0);
   }
 
 };
@@ -215,27 +210,28 @@
   : fft_base<1, std::complex<SCALAR_TYPE>, SCALAR_TYPE>,
     public fft::backend<1, std::complex<SCALAR_TYPE>, SCALAR_TYPE, A, E>
 {
-  typedef SCALAR_TYPE stype;
-  typedef std::complex<stype> ctype;
-  typedef std::pair<stype*, stype*> ztype;
+  typedef SCALAR_TYPE rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
 
 public:
   impl(Domain<1> const &dom, unsigned number)
-    : fft_base<1, ctype, stype>(dom, A, convert_NoT(number))
+    : fft_base<1, ctype, rtype>(dom, A, convert_NoT(number))
   {}
 
+  virtual bool requires_copy(Rt_layout<1> &) { return true;}
+
   virtual void by_reference(ctype *in, stride_type in_stride,
-			    stype *out, stride_type out_stride,
+			    rtype *out, stride_type out_stride,
 			    length_type length)
   {
     FFTW(execute_dft_c2r)(plan_by_reference_,
 			  reinterpret_cast<FFTW(complex)*>(in), out);
   }
   virtual void by_reference(ztype in, stride_type in_stride,
-			    stype *out, stride_type out_stride,
+			    rtype *out, stride_type out_stride,
 			    length_type length)
   {
-    assert(0);
   }
 
 };
@@ -249,19 +245,24 @@
 			A, E>
 
 {
-  typedef SCALAR_TYPE stype;
-  typedef std::complex<stype> ctype;
-  typedef std::pair<stype*, stype*> ztype;
+  typedef SCALAR_TYPE rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
 
 public:
   impl(Domain<2> const &dom, unsigned number)
     : fft_base<2, ctype, ctype>(dom, E, convert_NoT(number))
   {}
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out = rtl_in;
+  }
   virtual void in_place(ctype *inout,
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
   {
-    // TODO: assert correct layout
     FFTW(execute_dft)(plan_in_place_,
 		      reinterpret_cast<FFTW(complex)*>(inout),
 		      reinterpret_cast<FFTW(complex)*>(inout));
@@ -271,7 +272,6 @@
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
   {
-    assert(0);
   }
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
@@ -289,7 +289,6 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    assert(0);
   }
 };
 
@@ -300,15 +299,27 @@
   : private fft_base<2, SCALAR_TYPE, std::complex<SCALAR_TYPE> >,
     public fft::backend<2, SCALAR_TYPE, std::complex<SCALAR_TYPE>, A, E>
 {
-  typedef SCALAR_TYPE stype;
-  typedef std::complex<stype> ctype;
-  typedef std::pair<stype*, stype*> ztype;
+  typedef SCALAR_TYPE rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
 
 public:
   impl(Domain<2> const &dom, unsigned number)
-    : fft_base<2, stype, ctype>(dom, A, convert_NoT(number))
+    : fft_base<2, rtype, ctype>(dom, A, convert_NoT(number))
   {}
-  virtual void by_reference(stype *in,
+
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    // FFTW3 assumes A is the last dimension.
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else rtl_in.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out = rtl_in;
+  }
+  virtual bool requires_copy(Rt_layout<2> &) { return true;}
+
+  virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    ctype *out,
 			    stride_type out_r_stride, stride_type out_c_stride,
@@ -317,13 +328,12 @@
     FFTW(execute_dft_r2c)(plan_by_reference_,
 			  in, reinterpret_cast<FFTW(complex)*>(out));
   }
-  virtual void by_reference(stype *in,
+  virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    ztype,
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    assert(0);
   }
 
 };
@@ -335,18 +345,29 @@
   : fft_base<2, std::complex<SCALAR_TYPE>, SCALAR_TYPE>,
     public fft::backend<2, std::complex<SCALAR_TYPE>, SCALAR_TYPE, A, E>
 {
-  typedef SCALAR_TYPE stype;
-  typedef std::complex<stype> ctype;
-  typedef std::pair<stype*, stype*> ztype;
+  typedef SCALAR_TYPE rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
 
 public:
   impl(Domain<2> const &dom, unsigned number)
-    : fft_base<2, ctype, stype>(dom, A, convert_NoT(number))
+    : fft_base<2, ctype, rtype>(dom, A, convert_NoT(number))
   {}
 
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    // FFTW3 assumes A is the last dimension.
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else rtl_in.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out = rtl_in;
+  }
+  virtual bool requires_copy(Rt_layout<2> &) { return true;}
+
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
-			    stype *out,
+			    rtype *out,
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
@@ -355,11 +376,10 @@
   }
   virtual void by_reference(ztype,
 			    stride_type in_r_stride, stride_type in_c_stride,
-			    stype *out,
+			    rtype *out,
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    assert(0);
   }
 
 };
@@ -373,14 +393,20 @@
 			A, E>
 
 {
-  typedef SCALAR_TYPE stype;
-  typedef std::complex<stype> ctype;
-  typedef std::pair<stype*, stype*> ztype;
+  typedef SCALAR_TYPE rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
 
 public:
   impl(Domain<3> const &dom, unsigned number)
     : fft_base<3, ctype, ctype>(dom, E, convert_NoT(number))
   {}
+  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out = rtl_in;
+  }
   virtual void in_place(ctype *inout,
 			stride_type x_stride,
 			stride_type y_stride,
@@ -402,7 +428,6 @@
 			length_type y_length,
 			length_type z_length)
   {
-    assert(0);
   }
   virtual void by_reference(ctype *in,
 			    stride_type in_x_stride,
@@ -435,7 +460,6 @@
 			    length_type y_length,
 			    length_type z_length)
   {
-    assert(0);
   }
 };
 
@@ -446,15 +470,31 @@
   : private fft_base<3, SCALAR_TYPE, std::complex<SCALAR_TYPE> >,
     public fft::backend<3, SCALAR_TYPE, std::complex<SCALAR_TYPE>, A, E>
 {
-  typedef SCALAR_TYPE stype;
-  typedef std::complex<stype> ctype;
-  typedef std::pair<stype*, stype*> ztype;
+  typedef SCALAR_TYPE rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
 
 public:
   impl(Domain<3> const &dom, unsigned number)
-    : fft_base<3, stype, ctype>(dom, A, convert_NoT(number))
+    : fft_base<3, rtype, ctype>(dom, A, convert_NoT(number))
   {}
-  virtual void by_reference(stype *in,
+
+  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    // FFTW3 assumes A is the last dimension.
+    switch (A)
+    {
+      case 0: rtl_in.order = tuple<2, 1, 0>(); break;
+      case 1: rtl_in.order = tuple<0, 2, 1>(); break;
+      default: rtl_in.order = tuple<0, 1, 2>(); break;
+    }
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out = rtl_in;
+  }
+  virtual bool requires_copy(Rt_layout<3> &) { return true;}
+
+  virtual void by_reference(rtype *in,
 			    stride_type in_x_stride,
 			    stride_type in_y_stride,
 			    stride_type in_z_stride,
@@ -468,7 +508,7 @@
   {
     std::cout << "3D r->c by_ref" << std::endl;
   }
-  virtual void by_reference(stype *in,
+  virtual void by_reference(rtype *in,
 			    stride_type in_x_stride,
 			    stride_type in_y_stride,
 			    stride_type in_z_stride,
@@ -480,7 +520,6 @@
 			    length_type y_length,
 			    length_type z_length)
   {
-    assert(0);
   }
 
 };
@@ -492,20 +531,35 @@
   : fft_base<3, std::complex<SCALAR_TYPE>, SCALAR_TYPE>,
     public fft::backend<3, std::complex<SCALAR_TYPE>, SCALAR_TYPE, A, E>
 {
-  typedef SCALAR_TYPE stype;
-  typedef std::complex<stype> ctype;
-  typedef std::pair<stype*, stype*> ztype;
+  typedef SCALAR_TYPE rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
 
 public:
   impl(Domain<3> const &dom, unsigned number)
-    : fft_base<3, ctype, stype>(dom, A, convert_NoT(number))
+    : fft_base<3, ctype, rtype>(dom, A, convert_NoT(number))
   {}
 
+  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    // FFTW3 assumes A is the last dimension.
+    switch (A)
+    {
+      case 0: rtl_in.order = tuple<2, 1, 0>(); break;
+      case 1: rtl_in.order = tuple<0, 2, 1>(); break;
+      default: rtl_in.order = tuple<0, 1, 2>(); break;
+    }
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out = rtl_in;
+  }
+  virtual bool requires_copy(Rt_layout<3> &) { return true;}
+
   virtual void by_reference(ctype *in,
 			    stride_type in_x_stride,
 			    stride_type in_y_stride,
 			    stride_type in_z_stride,
-			    stype *out,
+			    rtype *out,
 			    stride_type out_x_stride,
 			    stride_type out_y_stride,
 			    stride_type out_z_stride,
@@ -519,7 +573,7 @@
 			    stride_type in_x_stride,
 			    stride_type in_y_stride,
 			    stride_type in_z_stride,
-			    stype *out,
+			    rtype *out,
 			    stride_type out_x_stride,
 			    stride_type out_y_stride,
 			    stride_type out_z_stride,
@@ -527,7 +581,6 @@
 			    length_type y_length,
 			    length_type z_length)
   {
-    assert(0);
   }
 
 };
@@ -539,18 +592,26 @@
   : private fft_base<1, SCALAR_TYPE, std::complex<SCALAR_TYPE> >,
     public fft::fftm<SCALAR_TYPE, std::complex<SCALAR_TYPE>, A, -1>
 {
-  typedef SCALAR_TYPE stype;
-  typedef std::complex<stype> ctype;
-  typedef std::pair<stype*, stype*> ztype;
+  typedef SCALAR_TYPE rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
 
 public:
   fftm(Domain<2> const &dom, unsigned number)
     : fft_base<1, SCALAR_TYPE, std::complex<SCALAR_TYPE> >
-        (dom[A], 0, convert_NoT(number) | FFTW_UNALIGNED),
+      (dom[A], 0, convert_NoT(number) | FFTW_UNALIGNED),
       mult_(dom[1-A].size()) 
   {
   }
-  virtual void by_reference(stype *in,
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else  rtl_in.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out = rtl_in;
+  }
+  virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    ctype *out,
 			    stride_type out_r_stride, stride_type out_c_stride,
@@ -566,13 +627,12 @@
       out += size_[0]/2 + 1;
     }
   }
-  virtual void by_reference(stype *in,
+  virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    ztype out,
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    assert(-1);
   }
 
 private:
@@ -586,18 +646,31 @@
   : private fft_base<1, std::complex<SCALAR_TYPE>, SCALAR_TYPE>,
     public fft::fftm<std::complex<SCALAR_TYPE>, SCALAR_TYPE, A, 1>
 {
-  typedef SCALAR_TYPE stype;
-  typedef std::complex<stype> ctype;
-  typedef std::pair<stype*, stype*> ztype;
+  typedef SCALAR_TYPE rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
 
 public:
   fftm(Domain<2> const &dom, unsigned number)
     : fft_base<1, std::complex<SCALAR_TYPE>, SCALAR_TYPE>
-        (dom[A], 0, convert_NoT(number) | FFTW_UNALIGNED),
-      mult_(dom[1-A].size()) {}
+      (dom[A], 0, convert_NoT(number) | FFTW_UNALIGNED),
+      mult_(dom[1-A].size()) 
+  {
+  }
+
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else  rtl_in.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out = rtl_in;
+  }
+  virtual bool requires_copy(Rt_layout<2> &) { return true;}
+
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
-			    stype *out,
+			    rtype *out,
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
@@ -613,11 +686,10 @@
   }
   virtual void by_reference(ztype in,
 			    stride_type in_r_stride, stride_type in_c_stride,
-			    stype *out,
+			    rtype *out,
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    assert(0);
   }
 
 private:
@@ -631,17 +703,24 @@
   : private fft_base<1, std::complex<SCALAR_TYPE>, std::complex<SCALAR_TYPE> >,
     public fft::fftm<std::complex<SCALAR_TYPE>, std::complex<SCALAR_TYPE>, A, E>
 {
-  typedef SCALAR_TYPE stype;
-  typedef std::complex<stype> ctype;
-  typedef std::pair<stype*, stype*> ztype;
+  typedef SCALAR_TYPE rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
 
 public:
   fftm(Domain<2> const &dom, int number)
-    : fft_base<1,
-	       std::complex<SCALAR_TYPE>,
-	       std::complex<SCALAR_TYPE> >(dom[A], E, convert_NoT(number) | FFTW_UNALIGNED),
+    : fft_base<1, ctype, ctype>
+  (dom[A], E, convert_NoT(number) | FFTW_UNALIGNED),
       mult_(dom[1-A].size()) {}
 
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else  rtl_in.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out = rtl_in;
+  }
   virtual void in_place(ctype *inout,
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
@@ -661,7 +740,6 @@
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
   {
-    assert(0);
   }
 
   virtual void by_reference(ctype *in,
@@ -687,7 +765,6 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    assert(0);
   }
 
 private:
Index: src/vsip/impl/ipp/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp/fft.cpp,v
retrieving revision 1.1
diff -u -r1.1 fft.cpp
--- src/vsip/impl/ipp/fft.cpp	6 May 2006 22:09:27 -0000	1.1
+++ src/vsip/impl/ipp/fft.cpp	9 May 2006 19:38:57 -0000
@@ -545,6 +545,15 @@
     : Driver<2, T, F>(dom)
   {
   }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    // IPP assumes A is the final dimension.
+    if (A == 0) rtl_in.order = tuple<0, 1, 2>();
+    else rtl_in.order = tuple<1, 0, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out = rtl_in;
+  }
   virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    ctype *out,
@@ -575,10 +584,19 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  impl(Domain<1> const &dom, rtype scale)
+  impl(Domain<2> const &dom, rtype scale)
     : Driver<2, T, F>(dom)
   {
   }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    // IPP assumes A is the final dimension.
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else rtl_in.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out = rtl_in;
+  }
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    rtype *out,
@@ -778,19 +796,19 @@
   length_type mult_;
 };
 
-#define VSIPL_IMPL_PROVIDE(D, I, O, A, E)				     \
-template <>                                                                  \
-std::auto_ptr<fft::backend<D, I, O, A, E> >				     \
-create(Domain<D> const &dom,                                                 \
-       fft::backend<D, I, O, A, E>::scalar_type scale,                       \
-       bool fast)                                                            \
-{                                                                            \
-  if (fast)								     \
-    return std::auto_ptr<fft::backend<D, I, O, A, E> >			     \
-      (new impl<D, I, O, A, E, true>(dom, scale));			     \
-  else                                                                       \
-    return std::auto_ptr<fft::backend<D, I, O, A, E> >			     \
-      (new impl<D, I, O, A, E, false>(dom, scale));			     \
+#define VSIPL_IMPL_PROVIDE(D, I, O, A, E)		\
+template <>                                             \
+std::auto_ptr<fft::backend<D, I, O, A, E> >		\
+create(Domain<D> const &dom,                            \
+       fft::backend<D, I, O, A, E>::scalar_type scale,  \
+       bool fast)                                       \
+{                                                       \
+  if (fast)						\
+    return std::auto_ptr<fft::backend<D, I, O, A, E> >	\
+      (new impl<D, I, O, A, E, true>(dom, scale));	\
+  else                                                  \
+    return std::auto_ptr<fft::backend<D, I, O, A, E> >	\
+      (new impl<D, I, O, A, E, false>(dom, scale));	\
 }
 
 VSIPL_IMPL_PROVIDE(1, float, std::complex<float>, 0, -1)
@@ -824,19 +842,19 @@
 
 #undef VSIPL_IMPL_PROVIDE
 
-#define VSIPL_IMPL_PROVIDE(I, O, A, E)				  \
-template <>                                                       \
-std::auto_ptr<fft::fftm<I, O, A, E> >				  \
-create(Domain<2> const &dom,                                      \
-       impl::Scalar_of<I>::type scale,                            \
-       bool fast)						  \
-{                                                                 \
-  if (fast)                                                       \
-    return std::auto_ptr<fft::fftm<I, O, A, E> >		  \
-      (new fftm<I, O, A, E, true>(dom, scale));			  \
-  else                                                            \
-    return std::auto_ptr<fft::fftm<I, O, A, E> >		  \
-      (new fftm<I, O, A, E, false>(dom, scale));       		  \
+#define VSIPL_IMPL_PROVIDE(I, O, A, E)			\
+template <>                                             \
+std::auto_ptr<fft::fftm<I, O, A, E> >			\
+create(Domain<2> const &dom,                            \
+       impl::Scalar_of<I>::type scale,                  \
+       bool fast)					\
+{                                                       \
+  if (fast)                                             \
+    return std::auto_ptr<fft::fftm<I, O, A, E> >	\
+      (new fftm<I, O, A, E, true>(dom, scale));		\
+  else                                                  \
+    return std::auto_ptr<fft::fftm<I, O, A, E> >	\
+      (new fftm<I, O, A, E, false>(dom, scale));       	\
 }
 
 VSIPL_IMPL_PROVIDE(float, std::complex<float>, 0, -1)
Index: src/vsip/impl/sal/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/fft.cpp,v
retrieving revision 1.2
diff -u -r1.2 fft.cpp
--- src/vsip/impl/sal/fft.cpp	6 May 2006 22:09:27 -0000	1.2
+++ src/vsip/impl/sal/fft.cpp	9 May 2006 19:38:57 -0000
@@ -165,6 +165,11 @@
     rtype *d = reinterpret_cast<rtype*>(data);
     vsmulx(d, 1, &s, d, 1, 2 * size, ESAL);
   }
+  void scale(std::pair<rtype*, rtype*> data, length_type size, rtype s)
+  {
+    vsmulx(data.first, 1, &s, data.first, 1, size, ESAL);
+    vsmulx(data.second, 1, &s, data.second, 1, size, ESAL);
+  }
   void scale(rtype *data, length_type size, rtype s)
   {
     vsmulx(data, 1, &s, data, 1, size, ESAL);
@@ -186,6 +191,14 @@
     fft2d_cipx(&setup_, reinterpret_cast<ctype *>(data), 2, 0,
 	       l2size_[1 - axis], l2size_[axis], dir, ESAL);
   }
+  void zip2d(std::pair<rtype*, rtype*> inout, dimension_type axis, long dir)
+  {
+    ztype data = {inout.first, inout.second};
+    ztype tmp = {reinterpret_cast<rtype*>(buffer_),
+		 reinterpret_cast<rtype*>(buffer_) + size_[0] * size_[1]};
+    fft2d_ziptx(&setup_, &data, 1, 0, &tmp,
+		l2size_[1 - axis], l2size_[axis], dir, ESAL);
+  }
   void rop(rtype *in, std::complex<rtype> *out)
   {
     rtype *data = reinterpret_cast<rtype*>(out);
@@ -259,24 +272,23 @@
     ztype in = {in_arg.first, in_arg.second};
     ztype out = {out_arg.first, out_arg.second};
     ztype tmp = {reinterpret_cast<rtype*>(buffer_),
-		 reinterpret_cast<rtype*>(buffer_) + size_[0]};
+		 reinterpret_cast<rtype*>(buffer_) +  size_[0] * size_[1]};
     fft2d_zoptx(&setup_, &in, in_r_stride, in_c_stride,
 		&out, out_r_stride, out_c_stride,
-		&tmp, l2size_[1], l2size_[0], dir, ESAL);
+		&tmp, l2size_[0], l2size_[1], dir, ESAL);
   }
   void cipm(std::complex<rtype> *inout, stride_type stride,
 	    dimension_type axis, long dir)
   {
     fftm_cipx(&setup_, reinterpret_cast<ctype *>(inout),
-	      2, 2 * stride, l2size_[1 - axis], size_[axis], dir, ESAL);
+	      2, 2 * stride, l2size_[axis], size_[1 - axis], dir, ESAL);
   }
-  void zipm(std::pair<rtype*, rtype*> inout,
-	    stride_type r_stride, stride_type c_stride,
+  void zipm(std::pair<rtype*, rtype*> inout, stride_type stride,
 	    dimension_type axis, long dir)
   {
     ztype data = {inout.first, inout.second};
-    fftm_zipx(&setup_, &data, r_stride, c_stride,
-	      l2size_[1 - axis], size_[axis], dir, ESAL);
+    fftm_zipx(&setup_, &data, 1, stride,
+	      l2size_[axis], size_[1 - axis], dir, ESAL);
   }
   void ropm(rtype *in, stride_type in_stride,
 	    std::complex<rtype> *out_arg, stride_type out_stride,
@@ -323,6 +335,17 @@
 	       reinterpret_cast<ctype *>(buffer_),
 	       l2size_[axis], size_[1 - axis], dir, ESAL);
   }
+  void zopm(std::pair<rtype*,rtype*> in_arg, stride_type in_stride,
+	    std::pair<rtype*,rtype*> out_arg, stride_type out_stride,
+	    dimension_type axis, long dir)
+  {
+    ztype in = {in_arg.first, in_arg.second};
+    ztype out = {out_arg.first, out_arg.second};
+    ztype tmp = {reinterpret_cast<rtype*>(buffer_),
+		 reinterpret_cast<rtype*>(buffer_) + size_[0] * size_[1]};
+    fftm_zoptx(&setup_, &in, 1, in_stride, &out, 1, out_stride, &tmp,
+	       l2size_[axis], size_[1 - axis], dir, ESAL);
+  }
 
   FFT_setup setup_;
   length_type size_[D];
@@ -356,6 +379,11 @@
     rtype *d = reinterpret_cast<rtype*>(data);
     vsmuldx(d, 1, &s, d, 1, 2 * size, ESAL);
   }
+  void scale(std::pair<rtype*, rtype*> data, length_type size, rtype s)
+  {
+    vsmuldx(data.first, 1, &s, data.first, 1, size, ESAL);
+    vsmuldx(data.second, 1, &s, data.second, 1, size, ESAL);
+  }
   void scale(rtype *data, length_type size, rtype s)
   {
     vsmuldx(data, 1, &s, data, 1, size, ESAL);
@@ -377,6 +405,14 @@
     fft2d_cipdx(&setup_, reinterpret_cast<ctype *>(data), 2, 0,
 		l2size_[1 - axis], l2size_[axis], dir, ESAL);
   }
+  void zip2d(std::pair<rtype*, rtype*> inout, dimension_type axis, long dir)
+  {
+    ztype data = {inout.first, inout.second};
+    ztype tmp = {reinterpret_cast<rtype*>(buffer_),
+		 reinterpret_cast<rtype*>(buffer_) + size_[0] * size_[1]};
+    fft2d_ziptdx(&setup_, &data, 1, 0, &tmp,
+		 l2size_[1 - axis], l2size_[axis], dir, ESAL);
+  }
   void rop(rtype *in, std::complex<rtype> *out)
   {
     rtype *data = reinterpret_cast<rtype*>(out);
@@ -403,7 +439,7 @@
   {
     ctype *in = reinterpret_cast<ctype*>(in_arg);
     ctype *out = reinterpret_cast<ctype*>(out_arg);
-    fft_copdx(&setup_, in, 2, out, 2, l2size_[0], dir, ESAL);
+    fft_coptdx(&setup_, in, 2, out, 2, buffer_, l2size_[0], dir, ESAL);
   }
   void zop(std::pair<rtype*, rtype*> in_arg, stride_type in_stride,
 	   std::pair<rtype*, rtype*> out_arg, stride_type out_stride, long dir)
@@ -452,24 +488,23 @@
     ztype in = {in_arg.first, in_arg.second};
     ztype out = {out_arg.first, out_arg.second};
     ztype tmp = {reinterpret_cast<rtype*>(buffer_),
-		 reinterpret_cast<rtype*>(buffer_) + size_[0]};
+		 reinterpret_cast<rtype*>(buffer_) + size_[0] * size_[1]};
     fft2d_zoptdx(&setup_, &in, in_r_stride, in_c_stride,
 		 &out, out_r_stride, out_c_stride,
-		 &tmp, l2size_[1], l2size_[0], dir, ESAL);
+		 &tmp, l2size_[0], l2size_[1], dir, ESAL);
   }
   void cipm(std::complex<rtype> *inout, stride_type stride,
 	    dimension_type axis, long dir)
   {
     fftm_cipdx(&setup_, reinterpret_cast<ctype *>(inout),
-	       2, 2 * stride, l2size_[1 - axis], size_[axis], dir, ESAL);
+	       2, 2 * stride, l2size_[axis], size_[1 - axis], dir, ESAL);
   }
-  void zipm(std::pair<rtype*, rtype*> inout,
-	    stride_type r_stride, stride_type c_stride,
+  void zipm(std::pair<rtype*, rtype*> inout, stride_type stride,
 	    dimension_type axis, long dir)
   {
     ztype data = {inout.first, inout.second};
-    fftm_zipdx(&setup_, &data, r_stride, c_stride,
-	       l2size_[1 - axis], size_[axis], dir, ESAL);
+    fftm_zipdx(&setup_, &data, 1, stride,
+	       l2size_[axis], size_[1 - axis], dir, ESAL);
   }
   void ropm(rtype *in, stride_type in_stride,
 	    std::complex<rtype> *out_arg, stride_type out_stride,
@@ -516,6 +551,17 @@
 		reinterpret_cast<ctype *>(buffer_),
 		l2size_[axis], size_[1 - axis], dir, ESAL);
   }
+  void zopm(std::pair<rtype*,rtype*> in_arg, stride_type in_stride,
+	    std::pair<rtype*,rtype*> out_arg, stride_type out_stride,
+	    dimension_type axis, long dir)
+  {
+    ztype in = {in_arg.first, in_arg.second};
+    ztype out = {out_arg.first, out_arg.second};
+    ztype tmp = {reinterpret_cast<rtype*>(buffer_),
+		 reinterpret_cast<rtype*>(buffer_) + size_[0] * size_[1]};
+    fftm_zoptdx(&setup_, &in, 1, in_stride, &out, 1, out_stride, &tmp,
+		l2size_[axis], size_[1 - axis], dir, ESAL);
+  }
 
   FFT_setupd setup_;
   length_type size_[D];
@@ -535,15 +581,30 @@
   : private fft_base<1, precision<T>::single>,
     public fft::backend<1, std::complex<T>, std::complex<T>, A, E>
 {
+  typedef T rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
   static int const direction = E == -1 ? FFT_FORWARD : FFT_INVERSE;
+
 public:
   impl(Domain<1> const &dom, T scale)
     : fft_base<1, precision<T>::single>(dom, 0, scale) {}
 
   virtual bool supports_scale() { return true;}
+  virtual void query_layout(Rt_layout<1> &rtl_inout)
+  {
+    rtl_inout.pack = stride_unit_dense;
+    rtl_inout.order = tuple<0, 1, 2>();
+  }
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    rtl_in.order = tuple<0, 1, 2>();
+    rtl_out.pack = stride_unit_dense;
+    rtl_out.order = tuple<0, 1, 2>();
+  }
 
-  virtual void in_place(std::complex<T> *data,
-			stride_type stride, length_type size)
+  virtual void in_place(ctype *data, stride_type stride, length_type size)
   {
     assert(stride == 1);
     assert(size == this->size_[0]);
@@ -552,8 +613,7 @@
       scale(data, this->size_[0], this->scale_);
   }
 
-  virtual void in_place(std::pair<T *, T *> data,
-			stride_type stride, length_type size)
+  virtual void in_place(ztype data, stride_type stride, length_type size)
   {
     assert(size == this->size_[0]);
     zip(data, stride, direction);
@@ -564,8 +624,8 @@
     }
   }
 
-  virtual void by_reference(std::complex<T> *in, stride_type in_stride,
-			    std::complex<T> *out, stride_type out_stride,
+  virtual void by_reference(ctype *in, stride_type in_stride,
+			    ctype *out, stride_type out_stride,
 			    length_type size)
   {
     assert(in_stride == 1 && out_stride == 1);
@@ -574,8 +634,8 @@
     if (!almost_equal(this->scale_, T(1.)))
       scale(out, this->size_[0], this->scale_);
   }
-  virtual void by_reference(std::pair<T *, T *> in, stride_type in_stride,
-			    std::pair<T *, T *> out, stride_type out_stride,
+  virtual void by_reference(ztype in, stride_type in_stride,
+			    ztype out, stride_type out_stride,
 			    length_type size)
   {
     assert(size == this->size_[0]);
@@ -593,11 +653,24 @@
   : private fft_base<1, precision<T>::single>,
     public fft::backend<1, T, std::complex<T>, A, -1>
 {
+  typedef T rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
+
 public:
   impl(Domain<1> const &dom, T scale)
     : fft_base<1, precision<T>::single>(dom, 0, scale) {}
 
   virtual bool supports_scale() { return true;}
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    rtl_in.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out.pack = stride_unit_dense;
+    rtl_out.order = tuple<0, 1, 2>();
+    rtl_out.complex = cmplx_inter_fmt;
+  }
 
   virtual void by_reference(T *in, stride_type in_stride,
 			    std::complex<T> *out, stride_type out_stride,
@@ -621,13 +694,29 @@
   : private fft_base<1, precision<T>::single>,
     public fft::backend<1, std::complex<T>, T, A, 1>
 {
+  typedef T rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
+
 public:
   impl(Domain<1> const &dom, T scale)
     : fft_base<1, precision<T>::single>(dom, 0, scale) {}
 
   virtual bool supports_scale() { return true;}
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    rtl_in.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out.pack = stride_unit_dense;
+    rtl_out.order = tuple<0, 1, 2>();
+    rtl_out.complex = cmplx_inter_fmt;
+  }
+  // SAL requires the input to be packed, so we will modify the input
+  // before passing it along.
+  virtual bool requires_copy(Rt_layout<1> &rtl_in) { return true;}
 
-  virtual void by_reference(std::complex<T> *in, stride_type in_stride,
+  virtual void by_reference(ctype *in, stride_type in_stride,
 			    T *out, stride_type out_stride,
 			    length_type size)
   {
@@ -637,7 +726,7 @@
     if (!almost_equal(this->scale_, T(1.)))
       scale(out, this->size_[0], this->scale_);
   }
-  virtual void by_reference(std::pair<T *, T *> in, stride_type in_stride,
+  virtual void by_reference(ztype in, stride_type in_stride,
 			    T *out, stride_type out_stride,
 			    length_type size)
   {
@@ -649,12 +738,28 @@
   : private fft_base<2, precision<T>::single>,
     public fft::backend<2, std::complex<T>, std::complex<T>, A, E>
 {
+  typedef T rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
   static int const direction = E == -1 ? FFT_FORWARD : FFT_INVERSE;
+
 public:
   impl(Domain<2> const &dom, T scale)
     : fft_base<2, precision<T>::single>(dom, 0, scale) {}
 
   virtual bool supports_scale() { return true;}
+  virtual void query_layout(Rt_layout<2> &rtl_inout)
+  {
+    rtl_inout.pack = stride_unit_dense;
+    rtl_inout.order = tuple<0, 1, 2>();
+  }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    rtl_in.order = tuple<0, 1, 2>();
+    rtl_out.pack = stride_unit_dense;
+    rtl_out.order = tuple<0, 1, 2>();
+  }
 
   virtual void in_place(std::complex<T> *inout,
 			stride_type r_stride, stride_type c_stride,
@@ -674,6 +779,20 @@
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
   {
+    zip2d(inout, A, direction);
+    if (!almost_equal(this->scale_, T(1.)))
+      if (A == 0)
+	for (length_type i = 0; i != cols; ++i)
+	{
+	  scale(inout.first + i * c_stride, this->size_[0], this->scale_);
+	  scale(inout.second + i * c_stride, this->size_[0], this->scale_);
+	}
+      else // A == 1
+	for (length_type i = 0; i != rows; ++i)
+	{
+	  scale(inout.first + i * r_stride, this->size_[1], this->scale_);    
+	  scale(inout.second + i * r_stride, this->size_[1], this->scale_);    
+	}
   }
 
   virtual void by_reference(std::complex<T> *in,
@@ -723,11 +842,26 @@
   : private fft_base<2, precision<T>::single>,
     public fft::backend<2, T, std::complex<T>, A, -1>
 {
+  typedef T rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
+
 public:
   impl(Domain<2> const &dom, T scale)
     : fft_base<2, precision<T>::single>(dom, 0, scale) {}
 
   virtual bool supports_scale() { return true;}
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    // SAL always does the first FFT over rows, so we have to
+    // generate a row-major matrix to obtain the desired effect.
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else rtl_in.order = tuple<0, 1, 2>();
+    rtl_out.pack = stride_unit_dense;
+    rtl_out.order = rtl_in.order;
+    rtl_out.complex = cmplx_inter_fmt;
+  }
 
   virtual void by_reference(T *in, stride_type in_r_stride, stride_type in_c_stride,
 			    std::complex<T> *out,
@@ -766,11 +900,29 @@
   : private fft_base<2, precision<T>::single>,
     public fft::backend<2, std::complex<T>, T, A, 1>
 {
+  typedef T rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
+
 public:
   impl(Domain<2> const &dom, T scale)
     : fft_base<2, precision<T>::single>(dom, 0, scale) {}
 
   virtual bool supports_scale() { return true;}
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    // SAL always does the first FFT over rows, so we have to
+    // generate a row-major matrix to obtain the desired effect.
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else rtl_in.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out.pack = stride_unit_dense;
+    rtl_out.order = rtl_in.order;
+  }
+  // SAL requires the input to be packed, so we will modify the input
+  // before passing it along.
+  virtual bool requires_copy(Rt_layout<2> &rtl_in) { return true;}
 
   virtual void by_reference(std::complex<T> *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
@@ -782,18 +934,18 @@
     if (A == 0)
     {
       assert(in_r_stride == 1 && out_r_stride == 1);
-      rop2d(in, in_c_stride, out, out_c_stride, 0);
+      rop2d(in, in_c_stride, out, out_c_stride, A);
       if (!almost_equal(this->scale_, T(1.)))
 	for (length_type i = 0; i != cols; ++i)
-	  scale(out + i * out_c_stride, this->size_[0], this->scale_);
+	  scale(out + i * out_c_stride, this->size_[A], this->scale_);
     }
     else
     {
       assert(in_c_stride == 1 && out_c_stride == 1);
-      rop2d(in, in_r_stride, out, out_r_stride, 0);
+      rop2d(in, in_r_stride, out, out_r_stride, A);
       if (!almost_equal(this->scale_, T(1.)))
 	for (length_type i = 0; i != rows; ++i)
-	  scale(out + i * out_r_stride, this->size_[1], this->scale_);
+	  scale(out + i * out_r_stride, this->size_[A], this->scale_);
     }
   }
   virtual void by_reference(std::pair<T *, T *> in,
@@ -812,10 +964,23 @@
   : private fft_base<2, precision<T>::single>,
     public fft::fftm<T, std::complex<T>, A, -1>
 {
+  typedef T rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
+
 public:
   fftm(Domain<2> const &dom, T scale)
     : fft_base<2, precision<T>::single>(dom, 0, scale) {}
 
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else rtl_in.order = tuple<0, 1, 2>();
+    rtl_out.pack = stride_unit_dense;
+    rtl_out.order = rtl_in.order;
+    rtl_out.complex = cmplx_inter_fmt;
+  }
   virtual void by_reference(T *in, stride_type in_r_stride, stride_type in_c_stride,
 			    std::complex<T> *out,
 			    stride_type out_r_stride, stride_type out_c_stride,
@@ -851,10 +1016,26 @@
   : private fft_base<2, precision<T>::single>,
     public fft::fftm<std::complex<T>, T, A, 1>
 {
+  typedef T rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
+
 public:
   fftm(Domain<2> const &dom, T scale)
     : fft_base<2, precision<T>::single>(dom, 0, scale) {}
 
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else rtl_in.order = tuple<0, 1, 2>();
+    rtl_in.complex = cmplx_inter_fmt;
+    rtl_out.pack = stride_unit_dense;
+    rtl_out.order = rtl_in.order;
+  }
+  // SAL requires the input to be packed, so we will modify the input
+  // before passing it along.
+  virtual bool requires_copy(Rt_layout<2> &rtl_in) { return true;}
   virtual void by_reference(std::complex<T> *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    T *out,
@@ -891,11 +1072,29 @@
   : private fft_base<2, precision<T>::single>,
     public fft::fftm<std::complex<T>, std::complex<T>, A, E>
 {
+  typedef T rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
   static int const direction = E == -1 ? FFT_FORWARD : FFT_INVERSE;
+
 public:
   fftm(Domain<2> const &dom, T scale)
     : fft_base<2, precision<T>::single>(dom, 0, scale) {}
 
+  virtual void query_layout(Rt_layout<2> &rtl_inout)
+  {
+    rtl_inout.pack = stride_unit_dense;
+    if (A == 0) rtl_inout.order = tuple<1, 0, 2>();
+    else rtl_inout.order = tuple<0, 1, 2>();
+  }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    rtl_in.pack = stride_unit_dense;
+    if (A == 0) rtl_in.order = tuple<1, 0, 2>();
+    else rtl_in.order = tuple<0, 1, 2>();
+    rtl_out.pack = stride_unit_dense;
+    rtl_out.order = rtl_in.order;
+  }
   virtual void in_place(std::complex<T> *inout,
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
@@ -904,7 +1103,7 @@
     if (A != 0)
     {
       assert(c_stride == 1);
-      cipm(inout, r_stride, 0, direction);
+      cipm(inout, r_stride, A, direction);
       if (!almost_equal(this->scale_, T(1.)))
 	for (length_type i = 0; i != rows; ++i)
 	  scale(inout + i * r_stride, cols, this->scale_);
@@ -912,7 +1111,7 @@
     else
     {
       assert(r_stride == 1);
-      cipm(inout, c_stride, 1, direction);
+      cipm(inout, c_stride, A, direction);
       if (!almost_equal(this->scale_, T(1.)))
 	for (length_type i = 0; i != cols; ++i)
 	  scale(inout + i * c_stride, rows, this->scale_);
@@ -927,7 +1126,7 @@
     if (A != 0)
     {
       assert(c_stride == 1);
-      zipm(inout, r_stride, c_stride, 0, direction);
+      zipm(inout, r_stride, A, direction);
       if (!almost_equal(this->scale_, T(1.)))
 	for (length_type i = 0; i != rows; ++i)
 	{
@@ -938,7 +1137,7 @@
     else
     {
       assert(r_stride == 1);
-      zipm(inout, r_stride, c_stride, 1, direction);
+      zipm(inout, c_stride, A, direction);
       if (!almost_equal(this->scale_, T(1.)))
 	for (length_type i = 0; i != cols; ++i)
 	{
@@ -978,6 +1177,29 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
+    assert(rows == this->size_[0] && cols == this->size_[1]);
+    if (A != 0)
+    {
+      assert(in_c_stride == 1 && out_c_stride == 1);
+      zopm(in, in_r_stride, out, out_r_stride, 1, direction);
+      if (!almost_equal(this->scale_, T(1.)))
+	for (length_type i = 0; i != rows; ++i)
+	{
+	  scale(out.first + i * out_r_stride, cols, this->scale_);
+	  scale(out.second + i * out_r_stride, cols, this->scale_);
+	}
+    }
+    else
+    {
+      assert(in_r_stride == 1 && out_r_stride == 1);
+      zopm(in, in_c_stride, out, out_c_stride, 0, direction);
+      if (!almost_equal(this->scale_, T(1.)))
+	for (length_type i = 0; i != cols; ++i)
+	{
+	  scale(out.first + i * out_c_stride, rows, this->scale_);
+	  scale(out.second + i * out_c_stride, rows, this->scale_);
+	}
+    }
   }
 };
 
Index: tests/fft_be.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft_be.cpp,v
retrieving revision 1.1
diff -u -r1.1 fft_be.cpp
--- tests/fft_be.cpp	6 May 2006 22:09:27 -0000	1.1
+++ tests/fft_be.cpp	9 May 2006 19:38:58 -0000
@@ -13,6 +13,7 @@
 #include <vsip/impl/fft/no_fft.hpp>
 #include <vsip/impl/type_list.hpp>
 #include <vsip/impl/fft.hpp>
+#include "test.hpp"
 #include "error_db.hpp"
 #include "output.hpp"
 
@@ -50,13 +51,15 @@
 {
   typedef std::complex<T> I;
   typedef std::complex<T> O;
-  typedef F format;
+  typedef F i_format;
+  typedef F o_format;
   static int const axis = A;
   static int const direction = E == -1 ? fft_fwd : fft_inv;
   static int const s = direction;
   template <dimension_type D>
-  static Domain<D> const &dom(Domain<D> const &in, Domain<D> const &out)
-  { return in;}
+  static Domain<D> in_dom(Domain<D> const &dom) { return dom;}
+  template <dimension_type D>
+  static Domain<D> out_dom(Domain<D> const &dom) { return dom;}
 };
 
 template <typename T, typename F, int E, int A = 0> struct rfft_type;
@@ -65,39 +68,57 @@
 {
   typedef T I;
   typedef std::complex<T> O;
-  typedef F format;
+  typedef inter i_format;
+  typedef F o_format;
   static int const axis = A;
   static int const direction = fft_fwd;
   static int const s = A;
   template <dimension_type D>
-  static Domain<D> const &dom(Domain<D> const &in, Domain<D> const &out)
-  { return in;}
+  static Domain<D> in_dom(Domain<D> const &dom) { return dom;}
+  template <dimension_type D>
+  static Domain<D> out_dom(Domain<D> const &dom) 
+  {
+    Domain<D> retn(dom);
+    Domain<1> &mod = retn.impl_at(axis);
+    mod = Domain<1>(mod.first(), mod.stride(), mod.size() / 2 + 1); 
+    return retn;
+  }
 };
 template <typename T, typename F, int A>
 struct rfft_type<T, F, 1, A>
 {
   typedef std::complex<T> I;
   typedef T O;
-  typedef F format;
+  typedef F i_format;
+  typedef inter o_format;
   static int const axis = A;
   static int const direction = fft_inv;
   static int const s = A;
   template <dimension_type D>
-  static Domain<D> const &dom(Domain<D> const &in, Domain<D> const &out)
-  { return out;}
+  static Domain<D> in_dom(Domain<D> const &dom) 
+  {
+    Domain<D> retn(dom);
+    Domain<1> &mod = retn.impl_at(axis);
+    mod = Domain<1>(mod.first(), mod.stride(), mod.size() / 2 + 1); 
+    return retn;
+  }
+  template <dimension_type D>
+  static Domain<D> out_dom(Domain<D> const &dom) { return dom;}
 };
 
 template <typename T>
 const_Vector<T, impl::Generator_expr_block<1, impl::Ramp_generator<T> > const>
 ramp(Domain<1> const &dom) 
-{ return vsip::ramp(T(0.), T(1.), dom.length());}
+{ return vsip::ramp(T(0.), T(1.), dom.length() * dom.stride());}
 
 template <typename T>
 Matrix<T>
 ramp(Domain<2> const &dom) 
 {
-  Matrix<T> m(dom[0].length(), dom[1].length());
-  for (size_t r = 0; r != dom[0].length(); ++r)
+  length_type rows = dom[0].length() * dom[0].stride();
+  length_type cols = dom[1].length() * dom[1].stride();
+  Matrix<T> m(rows, cols);
+  for (size_t r = 0; r != rows; ++r)
     m.row(r) = ramp(T(r), T(1.), m.size(1));
   return m;
 }
@@ -106,7 +127,10 @@
 Tensor<T>
 ramp(Domain<3> const &dom) 
 {
-  Tensor<T> t(dom[0].length(), dom[1].length(), dom[2].length());
+  length_type x_length = dom[0].length() * dom[0].stride();
+  length_type y_length = dom[1].length() * dom[1].stride();
+  length_type z_length = dom[2].length() * dom[2].stride();
+  Tensor<T> t(x_length, y_length, z_length);
   for (size_t x = 0; x != t.size(0); ++x)
     for (size_t y = 0; y != t.size(1); ++y)
       t(x, y, whole_domain) = ramp(T(x), T(y), t.size(2));
@@ -116,52 +140,77 @@
 template <typename T>
 Vector<T>
 empty(Domain<1> const &dom) 
-{ return Vector<T>(dom.length());}
+{ return Vector<T>(dom.length() * dom.stride(), T(0.));}
 
 template <typename T>
 Matrix<T>
 empty(Domain<2> const &dom) 
-{ return Matrix<T>(dom[0].length(), dom[1].length());}
+{
+  length_type rows = dom[0].length() * dom[0].stride();
+  length_type cols = dom[1].length() * dom[1].stride();
+  return Matrix<T>(rows, cols, T(0.));
+}
 
 template <typename T>
 Tensor<T>
 empty(Domain<3> const &dom) 
-{ return Tensor<T>(dom[0].length(), dom[1].length(), dom[2].length());}
+{
+  length_type x_length = dom[0].length() * dom[0].stride();
+  length_type y_length = dom[1].length() * dom[1].stride();
+  length_type z_length = dom[2].length() * dom[2].stride();
+  return Tensor<T>(x_length, y_length, z_length, T(0.));
+}
 
 
 template <typename T, typename B, dimension_type D>
-void fft_by_ref(Domain<D> const &in, Domain<D> const &out)
+void fft_by_ref(Domain<D> const &dom)
 {
   typedef typename T::I I;
   typedef typename T::O O;
   typedef typename impl::Layout<D, row1_type,
-    impl::Stride_unit_dense, typename T::format> layout_type;
+    impl::Stride_unit_dense, typename T::i_format> i_layout_type;
+  typedef typename impl::Layout<D, row1_type,
+    impl::Stride_unit_dense, typename T::o_format> o_layout_type;
   return_mechanism_type const r = by_reference;
 
-  typedef impl::Fast_block<D, I, layout_type> Iblock;
-  typedef impl::Fast_block<D, O, layout_type> Oblock;
+  typedef impl::Fast_block<D, I, i_layout_type> Iblock;
+  typedef impl::Fast_block<D, O, o_layout_type> Oblock;
   typedef typename impl::View_of_dim<D, I, Iblock>::type Iview;
   typedef typename impl::View_of_dim<D, O, Oblock>::type Oview;
 
-  Iview input = ramp<I>(in);
-  typename Iview::subview_type sub_input = input(in);
+  Domain<D> in_dom = T::in_dom(dom);
+  Domain<D> out_dom = T::out_dom(dom);
 
-  Oview output = empty<O>(out);
-  typename Oview::subview_type sub_output = output(out);
-  Domain<D> const &dom = T::dom(in, out);
+  // Set up some input data.
+  Iview input = ramp<I>(in_dom);
+  // Preserve it to validate that input isn't destroyed during the FFT.
+  Iview orig = empty<I>(in_dom);
+  orig = input;
+  // Set up subview to be used as input (helpful for testing non-unit-strides).
+  typename Iview::subview_type sub_input = input(in_dom);
+
+  // Set up the output data...
+  Oview output = empty<O>(out_dom);
+  // ...with possibly non-unit-stride.
+  typename Oview::subview_type sub_output = output(out_dom);
+  // Create the FFT object...
   typename impl::fft_facade<D, I, O, typename B::list, T::s, r> fft(dom, 1.);
+  // ...and call it.
   fft(sub_input, sub_output);
 
-  Oview ref = empty<O>(out);
-  typename Oview::subview_type sub_ref = ref(out);
+  // Test that input is preserved.
+  test_assert(error_db(input, orig) < -200);
+
+  Oview ref = empty<O>(out_dom);
+  typename Oview::subview_type sub_ref = ref(out_dom);
   typename impl::fft_facade<D, I, O, dft::list, T::s, r> ref_fft(dom, 1.);
   ref_fft(sub_input, sub_ref);
 
   if (error_db(output, ref) > -100)
   {
     std::cout << "error." << std::endl;
-//     std::cout << "out " << output << std::endl;
-//     std::cout << "ref  " << ref << std::endl;
+//     std::cout << "out " << sub_output << std::endl;
+//     std::cout << "ref  " << sub_ref << std::endl;
   }
   else std::cout << "ok." << std::endl;
 }
@@ -200,33 +249,37 @@
 }
 
 template <typename T, typename B>
-void fftm_by_ref(Domain<2> const &in, Domain<2> const &out)
+void fftm_by_ref(Domain<2> const &dom)
 {
   typedef typename T::I I;
   typedef typename T::O O;
   typedef typename impl::Layout<2, row1_type,
-    impl::Stride_unit_dense, typename T::format> layout_type;
+    impl::Stride_unit_dense, typename T::i_format> i_layout_type;
+  typedef typename impl::Layout<2, row1_type,
+    impl::Stride_unit_dense, typename T::o_format> o_layout_type;
   return_mechanism_type const r = by_reference;
 
-  typedef impl::Fast_block<2, I, layout_type> Iblock;
-  typedef impl::Fast_block<2, O, layout_type> Oblock;
+  typedef impl::Fast_block<2, I, i_layout_type> Iblock;
+  typedef impl::Fast_block<2, O, o_layout_type> Oblock;
   typedef Matrix<I, Iblock> Iview;
   typedef Matrix<O, Oblock> Oview;
 
-  Iview input = ramp<I>(in);
-  typename Iview::subview_type sub_input = input(in);
+  Domain<2> in_dom = T::in_dom(dom);
+  Domain<2> out_dom = T::out_dom(dom);
+
+  Iview input = ramp<I>(in_dom);
+  typename Iview::subview_type sub_input = input(in_dom);
 
-  Oview output = empty<O>(out);
-  typename Oview::subview_type sub_output = output(out);
-  Domain<2> const &dom = T::dom(in, out);
+  Oview output = empty<O>(out_dom);
+  typename Oview::subview_type sub_output = output(out_dom);
   typename impl::fftm_facade<I, O, typename B::list,
-			     1 - T::axis, T::direction, r> fftm(dom, 1.);
+			     T::axis, T::direction, r> fftm(dom, 1.);
   fftm(sub_input, sub_output);
 
-  Oview ref = empty<O>(out);
-  typename Oview::subview_type sub_ref = ref(out);
+  Oview ref = empty<O>(out_dom);
+  typename Oview::subview_type sub_ref = ref(out_dom);
   typename impl::fftm_facade<I, O, dft::list,
-			     1 - T::axis, T::direction, r> ref_fftm(dom, 1.);
+			     T::axis, T::direction, r> ref_fftm(dom, 1.);
   ref_fftm(sub_input, sub_ref);
 
   if (error_db(output, ref) > -100)
@@ -265,8 +318,8 @@
   if (error_db(data, ref) > -100)
   {
     std::cout << "error." << std::endl;
-    std::cout << "data " << data << std::endl;
-    std::cout << "ref  " << ref << std::endl;
+//     std::cout << "data " << data << std::endl;
+//     std::cout << "ref  " << ref << std::endl;
   }
   else std::cout << "ok." << std::endl;
 }
@@ -275,46 +328,64 @@
 void test_fft1d()
 {
   std::cout << "testing fwd in_place fftw...";
-  fft_in_place<T, F, -1, fftw>(Domain<1>(8));
+  fft_in_place<T, F, -1, fftw>(Domain<1>(16));
+  fft_in_place<T, F, -1, fftw>(Domain<1>(0, 2, 8));
   std::cout << "testing inv in_place fftw...";
-  fft_in_place<T, F, 1, fftw>(Domain<1>(8));
+  fft_in_place<T, F, 1, fftw>(Domain<1>(16));
+  fft_in_place<T, F, 1, fftw>(Domain<1>(0, 2, 8));
 
   std::cout << "testing fwd in_place sal...";
-  fft_in_place<T, F, -1, sal>(Domain<1>(8));
+  fft_in_place<T, F, -1, sal>(Domain<1>(16));
+  fft_in_place<T, F, -1, sal>(Domain<1>(0, 2, 8));
   std::cout << "testing inv in_place sal...";
-  fft_in_place<T, F, 1, sal>(Domain<1>(8));
+  fft_in_place<T, F, 1, sal>(Domain<1>(16));
+  fft_in_place<T, F, 1, sal>(Domain<1>(0, 2, 8));
 
   std::cout << "testing fwd in_place ipp...";
-  fft_in_place<T, F, -1, ipp>(Domain<1>(8));
+  fft_in_place<T, F, -1, ipp>(Domain<1>(16));
+  fft_in_place<T, F, -1, ipp>(Domain<1>(0, 2, 8));
   std::cout << "testing inv in_place ipp...";
-  fft_in_place<T, F, 1, ipp>(Domain<1>(8));
+  fft_in_place<T, F, 1, ipp>(Domain<1>(16));
+  fft_in_place<T, F, 1, ipp>(Domain<1>(0, 2, 8));
 
   std::cout << "testing c->c fwd by_ref fftw...";
-  fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<1>(8), Domain<1>(8));
+  fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<1>(16));
+  fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<1>(0, 2, 8));
   std::cout << "testing c->c inv by_ref fftw...";
-  fft_by_ref<cfft_type<T, F, 1>, fftw>(Domain<1>(8), Domain<1>(8));
+  fft_by_ref<cfft_type<T, F, 1>, fftw>(Domain<1>(16));
+  fft_by_ref<cfft_type<T, F, 1>, fftw>(Domain<1>(0, 2, 8));
   std::cout << "testing r->c fwd 0 by_ref fftw...";
-  fft_by_ref<rfft_type<T, F, -1, 0>, fftw>(Domain<1>(8), Domain<1>(5));
+  fft_by_ref<rfft_type<T, F, -1, 0>, fftw>(Domain<1>(16));
+  fft_by_ref<rfft_type<T, F, -1, 0>, fftw>(Domain<1>(0, 2, 8));
   std::cout << "testing c->r inv 0 by_ref fftw...";
-  fft_by_ref<rfft_type<T, F, 1, 0>, fftw>(Domain<1>(5), Domain<1>(8));
+  fft_by_ref<rfft_type<T, F, 1, 0>, fftw>(Domain<1>(16));
+  fft_by_ref<rfft_type<T, F, 1, 0>, fftw>(Domain<1>(0, 2, 8));
 
   std::cout << "testing c->c fwd by_ref sal...";
-  fft_by_ref<cfft_type<T, F, -1>, sal>(Domain<1>(8), Domain<1>(8));
+  fft_by_ref<cfft_type<T, F, -1>, sal>(Domain<1>(16));
+  fft_by_ref<cfft_type<T, F, -1>, sal>(Domain<1>(0, 2, 8));
   std::cout << "testing c->c inv by_ref sal...";
-  fft_by_ref<cfft_type<T, F, 1>, sal>(Domain<1>(8), Domain<1>(8));
+  fft_by_ref<cfft_type<T, F, 1>, sal>(Domain<1>(16));
+  fft_by_ref<cfft_type<T, F, 1>, sal>(Domain<1>(0, 2, 8));
   std::cout << "testing r->c fwd 0 by_ref sal...";
-  fft_by_ref<rfft_type<T, F, -1, 0>, sal>(Domain<1>(8), Domain<1>(5));
+  fft_by_ref<rfft_type<T, F, -1, 0>, sal>(Domain<1>(16));
+  fft_by_ref<rfft_type<T, F, -1, 0>, sal>(Domain<1>(0, 2, 8));
   std::cout << "testing c->r inv 0 by_ref sal...";
-  fft_by_ref<rfft_type<T, F, 1, 0>, sal>(Domain<1>(5), Domain<1>(8));
+  fft_by_ref<rfft_type<T, F, 1, 0>, sal>(Domain<1>(16));
+  fft_by_ref<rfft_type<T, F, 1, 0>, sal>(Domain<1>(0, 2, 8));
 
   std::cout << "testing c->c fwd by_ref ipp...";
-  fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<1>(8), Domain<1>(8));
+  fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<1>(16));
+  fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<1>(0, 2, 8));
   std::cout << "testing c->c inv by_ref ipp...";
-  fft_by_ref<cfft_type<T, F, 1>, ipp>(Domain<1>(8), Domain<1>(8));
+  fft_by_ref<cfft_type<T, F, 1>, ipp>(Domain<1>(16));
+  fft_by_ref<cfft_type<T, F, 1>, ipp>(Domain<1>(0, 2, 8));
   std::cout << "testing r->c fwd 0 by_ref ipp...";
-  fft_by_ref<rfft_type<T, F, -1, 0>, ipp>(Domain<1>(8), Domain<1>(5));
+  fft_by_ref<rfft_type<T, F, -1, 0>, ipp>(Domain<1>(16));
+  fft_by_ref<rfft_type<T, F, -1, 0>, ipp>(Domain<1>(0, 2, 8));
   std::cout << "testing c->r inv 0 by_ref ipp...";
-  fft_by_ref<rfft_type<T, F, 1, 0>, ipp>(Domain<1>(5), Domain<1>(8));
+  fft_by_ref<rfft_type<T, F, 1, 0>, ipp>(Domain<1>(16));
+  fft_by_ref<rfft_type<T, F, 1, 0>, ipp>(Domain<1>(0, 2, 8));
 }
 
 template <typename T, typename F>
@@ -322,50 +393,104 @@
 {
   std::cout << "testing fwd in_place fftw...";
   fft_in_place<T, F, -1, fftw>(Domain<2>(8, 16));
+  fft_in_place<T, F, -1, fftw>(Domain<2>(Domain<1>(0, 2, 9),
+					 Domain<1>(0, 2, 16)));
   std::cout << "testing inv in_place fftw...";
   fft_in_place<T, F, 1, fftw>(Domain<2>(8, 16));
+  fft_in_place<T, F, 1, fftw>(Domain<2>(Domain<1>(0, 2, 9),
+					Domain<1>(0, 2, 16)));
   std::cout << "testing fwd in_place sal...";
   fft_in_place<T, F, -1, sal>(Domain<2>(8, 16));
+  fft_in_place<T, F, -1, sal>(Domain<2>(Domain<1>(0, 2, 8),
+					Domain<1>(0, 2, 16)));
   std::cout << "testing inv in_place sal...";
   fft_in_place<T, F, 1, sal>(Domain<2>(8, 16));
+  fft_in_place<T, F, 1, sal>(Domain<2>(Domain<1>(0, 2, 8),
+				       Domain<1>(0, 2, 16)));
   std::cout << "testing fwd in_place ipp...";
   fft_in_place<T, F, -1, ipp>(Domain<2>(8, 16));
+  fft_in_place<T, F, -1, ipp>(Domain<2>(Domain<1>(0, 2, 9),
+					Domain<1>(0, 2, 16)));
   std::cout << "testing inv in_place ipp...";
   fft_in_place<T, F, 1, ipp>(Domain<2>(8, 17));
+  fft_in_place<T, F, 1, ipp>(Domain<2>(Domain<1>(0, 2, 9),
+				       Domain<1>(0, 2, 16)));
 
   std::cout << "testing c->c fwd by_ref fftw...";
-  fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<2>(8, 16));
+  fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<2>(Domain<1>(0, 2, 9),
+						  Domain<1>(0, 2, 16)));
   std::cout << "testing c->c inv by_ref fftw...";
-  fft_by_ref<cfft_type<T, F, 1>, fftw>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fft_by_ref<cfft_type<T, F, 1>, fftw>(Domain<2>(8, 16));
+  fft_by_ref<cfft_type<T, F, 1>, fftw>(Domain<2>(Domain<1>(0, 2, 9),
+						 Domain<1>(0, 2, 16)));
   std::cout << "testing r->c fwd 0 by_ref fftw...";
-  fft_by_ref<rfft_type<T, F, -1, 0>, fftw>(Domain<2>(8, 16), Domain<2>(5, 16));
+  fft_by_ref<rfft_type<T, F, -1, 0>, fftw>(Domain<2>(8, 16));
+  fft_by_ref<rfft_type<T, F, -1, 0>, fftw>(Domain<2>(Domain<1>(0, 2, 9),
+						     Domain<1>(0, 2, 16)));
   std::cout << "testing r->c fwd 1 by_ref fftw...";
-  fft_by_ref<rfft_type<T, F, -1, 1>, fftw>(Domain<2>(8, 16), Domain<2>(8, 9));
+  fft_by_ref<rfft_type<T, F, -1, 1>, fftw>(Domain<2>(8, 16));
+  fft_by_ref<rfft_type<T, F, -1, 1>, fftw>(Domain<2>(Domain<1>(0, 2, 9),
+						     Domain<1>(0, 2, 16)));
   // FIXME: DFT still buggy...
-//   std::cout << "testing c->r inv by_ref fftw...";
-//   fft_by_ref<rfft_type<T, F, 1, 0>, fftw> (Domain<2>(5, 8), Domain<2>(8, 8));
+//   std::cout << "testing c->r inv 0 by_ref fftw...";
+//   fft_by_ref<rfft_type<T, F, 1, 0>, fftw> (Domain<2>(4, 5));
+//   fft_by_ref<rfft_type<T, F, 1, 0>, fftw> (Domain<2>(Domain<1>(0, 2, 9),
+//                                                      Domain<1>(0, 2, 16)));
+//   std::cout << "testing c->r inv 1 by_ref fftw...";
+//   fft_by_ref<rfft_type<T, F, 1, 1>, fftw> (Domain<2>(8, 16));
+//   fft_by_ref<rfft_type<T, F, 1, 1>, fftw> (Domain<2>(Domain<1>(0, 2, 9),
+//                                                      Domain<1>(0, 2, 16)));
   std::cout << "testing c->c fwd by_ref sal...";
-  fft_by_ref<cfft_type<T, F, -1>, sal>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fft_by_ref<cfft_type<T, F, -1>, sal>(Domain<2>(8, 16));
+  fft_by_ref<cfft_type<T, F, -1>, sal>(Domain<2>(Domain<1>(0, 2, 8),
+						 Domain<1>(0, 2, 16)));
   std::cout << "testing c->c inv by_ref sal...";
-  fft_by_ref<cfft_type<T, F, 1>, sal>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fft_by_ref<cfft_type<T, F, 1>, sal>(Domain<2>(8, 16));
+  fft_by_ref<cfft_type<T, F, 1>, sal>(Domain<2>(Domain<1>(0, 2, 8),
+						Domain<1>(0, 2, 16)));
   std::cout << "testing r->c fwd 0 by_ref sal...";
-  fft_by_ref<rfft_type<T, F, -1, 0>, sal>(Domain<2>(8, 16), Domain<2>(5, 16));
+  fft_by_ref<rfft_type<T, F, -1, 0>, sal>(Domain<2>(8, 16));
+  fft_by_ref<rfft_type<T, F, -1, 0>, sal>(Domain<2>(Domain<1>(0, 2, 8),
+						    Domain<1>(0, 2, 16)));
   std::cout << "testing r->c fwd 1 by_ref sal...";
-  fft_by_ref<rfft_type<T, F, -1, 1>, sal>(Domain<2>(8, 16), Domain<2>(8, 9));
+  fft_by_ref<rfft_type<T, F, -1, 1>, sal>(Domain<2>(8, 16));
+  fft_by_ref<rfft_type<T, F, -1, 1>, sal>(Domain<2>(Domain<1>(0, 2, 8),
+						    Domain<1>(0, 2, 16)));
   // FIXME: DFT still buggy...
 //   std::cout << "testing c->r inv 0 by_ref sal...";
-//   fft_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(5, 8), Domain<2>(8, 8));
+//   fft_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(8, 16));
+//   fft_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(Domain<1>(0, 2, 9),
+//                                                     Domain<1>(0, 2, 16)));
+//   std::cout << "testing c->r inv 1 by_ref sal...";
+//   fft_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(8, 16));
+//   fft_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(Domain<1>(0, 2, 9),
+//                                                     Domain<1>(0, 2, 16)));
   std::cout << "testing c->c fwd by_ref ipp...";
-  fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<2>(8, 16));
+  fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<2>(Domain<1>(0, 2, 9),
+						 Domain<1>(0, 2, 16)));
   std::cout << "testing c->c inv by_ref ipp...";
-  fft_by_ref<cfft_type<T, F, 1>, ipp>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fft_by_ref<cfft_type<T, F, 1>, ipp>(Domain<2>(8, 16));
+  fft_by_ref<cfft_type<T, F, 1>, ipp>(Domain<2>(Domain<1>(0, 2, 9),
+						Domain<1>(0, 2, 16)));
   std::cout << "testing r->c fwd 0 by_ref ipp...";
-  fft_by_ref<rfft_type<T, F, -1, 0>, ipp>(Domain<2>(8, 16), Domain<2>(5, 16));
+  fft_by_ref<rfft_type<T, F, -1, 0>, ipp>(Domain<2>(8, 16));
+  fft_by_ref<rfft_type<T, F, -1, 0>, ipp>(Domain<2>(Domain<1>(0, 2, 9),
+						    Domain<1>(0, 2, 16)));
   std::cout << "testing r->c fwd 1 by_ref ipp...";
-  fft_by_ref<rfft_type<T, F, -1, 1>, ipp>(Domain<2>(8, 16), Domain<2>(8, 9));
+  fft_by_ref<rfft_type<T, F, -1, 1>, ipp>(Domain<2>(8, 16));
+  fft_by_ref<rfft_type<T, F, -1, 1>, ipp>(Domain<2>(Domain<1>(0, 2, 9),
+						    Domain<1>(0, 2, 16)));
   // FIXME: DFT still buggy...
 //   std::cout << "testing c->r inv 0 by_ref ipp...";
-//   fft_by_ref<rfft_type<T, F, 1, 0>, ipp> (Domain<2>(5, 8), Domain<2>(8, 8));
+//   fft_by_ref<rfft_type<T, F, 1, 0>, ipp> (Domain<2>(8, 16));
+//   fft_by_ref<rfft_type<T, F, 1, 0>, ipp> (Domain<2>(Domain<1>(0, 2, 9),
+//                                                     Domain<1>(0, 2, 16)));
+//   std::cout << "testing c->r inv 1 by_ref ipp...";
+//   fft_by_ref<rfft_type<T, F, 1, 1>, ipp> (Domain<2>(8, 16));
+//   fft_by_ref<rfft_type<T, F, 1, 1>, ipp> (Domain<2>(Domain<1>(0, 2, 9),
+//                                                     Domain<1>(0, 2, 16)));
 }
 
 template <typename T, typename F>
@@ -399,55 +524,55 @@
   fftm_in_place<T, F, 1, 1, ipp>(Domain<2>(8, 16));
 
   std::cout << "testing c->c fwd 0 by_ref fftw...";
-  fftm_by_ref<cfft_type<T, F, -1, 0>, fftw>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fftm_by_ref<cfft_type<T, F, -1, 0>, fftw>(Domain<2>(8, 16));
   std::cout << "testing c->c fwd 1 by_ref fftw...";
-  fftm_by_ref<cfft_type<T, F, -1, 1>, fftw>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fftm_by_ref<cfft_type<T, F, -1, 1>, fftw>(Domain<2>(8, 16));
   std::cout << "testing c->c inv 0 by_ref fftw...";
-  fftm_by_ref<cfft_type<T, F, 1, 0>, fftw>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fftm_by_ref<cfft_type<T, F, 1, 0>, fftw>(Domain<2>(8, 16));
   std::cout << "testing c->c inv 1 by_ref fftw...";
-  fftm_by_ref<cfft_type<T, F, 1, 1>, fftw>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fftm_by_ref<cfft_type<T, F, 1, 1>, fftw>(Domain<2>(8, 16));
   std::cout << "testing r->c fwd 0 by_ref fftw...";
-  fftm_by_ref<rfft_type<T, F, -1, 0>, fftw>(Domain<2>(8, 16), Domain<2>(5, 16));
+  fftm_by_ref<rfft_type<T, F, -1, 0>, fftw>(Domain<2>(8, 16));
   std::cout << "testing r->c fwd 1 by_ref fftw...";
-  fftm_by_ref<rfft_type<T, F, -1, 1>, fftw>(Domain<2>(8, 16), Domain<2>(8, 9));
+  fftm_by_ref<rfft_type<T, F, -1, 1>, fftw>(Domain<2>(8, 16));
   std::cout << "testing c->r inv 0 by_ref fftw...";
-  fftm_by_ref<rfft_type<T, F, 1, 0>, fftw>(Domain<2>(5, 16), Domain<2>(8, 16));
+  fftm_by_ref<rfft_type<T, F, 1, 0>, fftw>(Domain<2>(8, 16));
   std::cout << "testing c->r inv 1 by_ref fftw...";
-  fftm_by_ref<rfft_type<T, F, 1, 1>, fftw>(Domain<2>(8, 9), Domain<2>(8, 16));
+  fftm_by_ref<rfft_type<T, F, 1, 1>, fftw>(Domain<2>(8, 16));
 
   std::cout << "testing c->c fwd 0 by_ref sal...";
-  fftm_by_ref<cfft_type<T, F, -1, 0>, sal>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fftm_by_ref<cfft_type<T, F, -1, 0>, sal>(Domain<2>(8, 16));
   std::cout << "testing c->c fwd 1 by_ref sal...";
-  fftm_by_ref<cfft_type<T, F, -1, 1>, sal>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fftm_by_ref<cfft_type<T, F, -1, 1>, sal>(Domain<2>(8, 16));
   std::cout << "testing c->c inv 0 by_ref sal...";
-  fftm_by_ref<cfft_type<T, F, 1, 0>, sal>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fftm_by_ref<cfft_type<T, F, 1, 0>, sal>(Domain<2>(8, 16));
   std::cout << "testing c->c inv 1 by_ref sal...";
-  fftm_by_ref<cfft_type<T, F, 1, 1>, sal>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fftm_by_ref<cfft_type<T, F, 1, 1>, sal>(Domain<2>(8, 16));
   std::cout << "testing r->c fwd 0 by_ref sal...";
-  fftm_by_ref<rfft_type<T, F, -1, 0>, sal>(Domain<2>(8, 16), Domain<2>(5, 16));
+  fftm_by_ref<rfft_type<T, F, -1, 0>, sal>(Domain<2>(8, 16));
   std::cout << "testing r->c fwd 1 by_ref sal...";
-  fftm_by_ref<rfft_type<T, F, -1, 1>, sal>(Domain<2>(8, 16), Domain<2>(8, 9));
+  fftm_by_ref<rfft_type<T, F, -1, 1>, sal>(Domain<2>(8, 16));
   std::cout << "testing c->r inv 0 by_ref sal...";
-  fftm_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(5, 16), Domain<2>(8, 16));
+  fftm_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(8, 16));
   std::cout << "testing c->r inv 1 by_ref sal...";
-  fftm_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(8, 9), Domain<2>(8, 16));
+  fftm_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(8, 16));
 
   std::cout << "testing c->c fwd 0 by_ref ipp...";
-  fftm_by_ref<cfft_type<T, F, -1, 0>, ipp>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fftm_by_ref<cfft_type<T, F, -1, 0>, ipp>(Domain<2>(8, 16));
   std::cout << "testing c->c fwd 1 by_ref ipp...";
-  fftm_by_ref<cfft_type<T, F, -1, 1>, ipp>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fftm_by_ref<cfft_type<T, F, -1, 1>, ipp>(Domain<2>(8, 16));
   std::cout << "testing c->c inv 0 by_ref ipp...";
-  fftm_by_ref<cfft_type<T, F, 1, 0>, ipp>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fftm_by_ref<cfft_type<T, F, 1, 0>, ipp>(Domain<2>(8, 16));
   std::cout << "testing c->c inv 1 by_ref ipp...";
-  fftm_by_ref<cfft_type<T, F, 1, 1>, ipp>(Domain<2>(8, 16), Domain<2>(8, 16));
+  fftm_by_ref<cfft_type<T, F, 1, 1>, ipp>(Domain<2>(8, 16));
   std::cout << "testing r->c fwd 0 by_ref ipp...";
-  fftm_by_ref<rfft_type<T, F, -1, 0>, ipp>(Domain<2>(8, 16), Domain<2>(5, 16));
+  fftm_by_ref<rfft_type<T, F, -1, 0>, ipp>(Domain<2>(8, 16));
   std::cout << "testing r->c fwd 1 by_ref ipp...";
-  fftm_by_ref<rfft_type<T, F, -1, 1>, ipp>(Domain<2>(8, 16), Domain<2>(8, 9));
+  fftm_by_ref<rfft_type<T, F, -1, 1>, ipp>(Domain<2>(8, 16));
   std::cout << "testing c->r inv 0 by_ref ipp...";
-  fftm_by_ref<rfft_type<T, F, 1, 0>, ipp> (Domain<2>(5, 16), Domain<2>(8, 16));
+  fftm_by_ref<rfft_type<T, F, 1, 0>, ipp> (Domain<2>(8, 16));
   std::cout << "testing c->r inv 1 by_ref ipp...";
-  fftm_by_ref<rfft_type<T, F, 1, 1>, ipp> (Domain<2>(8, 9), Domain<2>(8, 16));
+  fftm_by_ref<rfft_type<T, F, 1, 1>, ipp> (Domain<2>(8, 16));
 }
 
 int main(int, char **)
