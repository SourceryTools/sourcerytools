Index: ChangeLog
===================================================================
--- ChangeLog	(revision 166067)
+++ ChangeLog	(working copy)
@@ -1,5 +1,40 @@
 2007-03-16  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/core/fft/dft.hpp (name): New member function to aid Fft
+	  backend debugging.  Fix query_layout to give input and output same
+	  complex format.  Change DFT accumulation type to double to reduce
+	  error.
+	* src/vsip/core/fft/backend.hpp (name): New member function for Fft
+	  backends.
+	* src/vsip/opt/fftw3/fft_impl.cpp: Likewise.
+	* src/vsip/opt/cbe/ppu/fft.cpp: Likewise.
+	* src/vsip/opt/cbe/ppu/fft.cpp: Remove debug printf.
+	* tests/regressions/fft_inter_split.cpp: New file, test FFT with
+	  different complex formats for input and output.
+	
+	* src/vsip/opt/cbe/ppu/bindings.hpp (is_dma_addr_ok): New function,
+	  check if DMA address is properly aligned.  Use in vmul dispatch.
+	* src/vsip/opt/cbe/ppu/bindings.cpp (vmul): Assert that DMA addresses
+	  are properly aligned.
+	
+	* src/vsip/opt/simd/simd.hpp: Update AltiVec SIMD traits to work
+	  with both GreenHills and GCC 4.1+.  Add missing AltiVec
+	  interleaved_from_split functions.
+	* src/vsip/opt/simd/vmul.hpp: Fix split vmul cleanup code to work
+	  when result aliases one of the operands.
+	* tests/simd.cpp: New file, unit tests for SIMD traits.
+
+	* tests/scalar_view_add.cpp: Add library initialization.
+	* tests/scalar_view_sub.cpp: Likewise.
+	* tests/scalar_view_mul.cpp: Likewise.
+	* tests/scalar_view_div.cpp: Likewise.
+	* tests/parallel/fftm.cpp: Add VERBOSE output.
+	
+	* src/vsip/opt/diag/eval.hpp: Add dispatch diagnostics for
+	  Tag_serial_expr.
+	
+2007-03-16  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/cbe/ppu/bindings.hpp (VSIP_IMPL_CBE_DMA_GRANULARITY):
 	  New macro, granularity of DMA size in bytes.
 	  (is_dma_size_ok): New funcion, check if DMA size is OK.
Index: src/vsip/core/fft/dft.hpp
===================================================================
--- src/vsip/core/fft/dft.hpp	(revision 166043)
+++ src/vsip/core/fft/dft.hpp	(working copy)
@@ -57,33 +57,37 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual char const* name() { return "fft-dft-1D-complex"; }
   virtual void query_layout(Rt_layout<1> &) {}
-  virtual void query_layout(Rt_layout<1> &, Rt_layout<1> &) {}
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  { rtl_in.complex = rtl_out.complex; }
   virtual void in_place(ctype *inout, stride_type s, length_type l)
   {
+    typedef double AccT;
     aligned_array<std::complex<T> > tmp(l);
-    T const phi = E * 2.0 * VSIP_IMPL_PI/l;
+    AccT const phi = E * 2.0 * VSIP_IMPL_PI/l;
 
     for (index_type w = 0; w < l; ++w)
     {
-      complex<T> sum;
+      complex<AccT> sum;
       for (index_type k = 0; k < l; ++k)
-	sum += vsip::complex<T>(inout[k * s]) * sin_cos<T>(phi * k * w);
+	sum += vsip::complex<AccT>(inout[k * s]) * sin_cos<AccT>(phi * k * w);
       tmp[w] = sum;
     }
     for (index_type w = 0; w < l; ++w) inout[w * s] = tmp[w];
   }
   virtual void in_place(ztype inout, stride_type s, length_type l)
   {
+    typedef double AccT;
     aligned_array<std::complex<T> > tmp(l);
-    T const phi = E * 2.0 * VSIP_IMPL_PI/l;
+    AccT const phi = E * 2.0 * VSIP_IMPL_PI/l;
 
     for (index_type w = 0; w < l; ++w)
     {
       complex<T> sum;
       for (index_type k = 0; k < l; ++k)
-	sum += vsip::complex<T>(inout.first[k * s], inout.second[k * s])
-	  * sin_cos<T>(phi * k * w);
+	sum += vsip::complex<AccT>(inout.first[k * s], inout.second[k * s])
+	  * sin_cos<AccT>(phi * k * w);
       tmp[w] = sum;
     }
     for (index_type w = 0; w < l; ++w)
@@ -96,28 +100,30 @@
 			    ctype *out, stride_type out_s,
 			    length_type l)
   {
-    T const phi = E * 2.0 * VSIP_IMPL_PI/l;
+    typedef double AccT;
+    AccT const phi = E * 2.0 * VSIP_IMPL_PI/l;
 
     for (index_type w = 0; w < l; ++w)
     {
-      complex<T> sum;
+      complex<AccT> sum;
       for (index_type k = 0; k < l; ++k)
-	sum += vsip::complex<T>(in[k * in_s]) * sin_cos<T>(phi * k * w);
-      out[w * out_s] = sum;
+	sum += vsip::complex<AccT>(in[k * in_s]) * sin_cos<AccT>(phi * k * w);
+      out[w * out_s] = ctype(sum);
     }
   }
   virtual void by_reference(ztype in, stride_type in_s,
 			    ztype out, stride_type out_s,
 			    length_type l)
   {
-    T const phi = E * 2.0 * VSIP_IMPL_PI/l;
+    typedef double AccT;
+    AccT const phi = E * 2.0 * VSIP_IMPL_PI/l;
 
     for (index_type w = 0; w < l; ++w)
     {
-      complex<T> sum;
+      complex<AccT> sum;
       for (index_type k = 0; k < l; ++k)
-	sum += vsip::complex<T>(in.first[k * in_s], in.second[k * in_s])
-	  * sin_cos<T>(phi * k * w);
+	sum += vsip::complex<AccT>(in.first[k * in_s], in.second[k * in_s])
+	  * sin_cos<AccT>(phi * k * w);
       out.first[w * out_s] = sum.real();
       out.second[w * out_s] = sum.imag();
     }
@@ -134,7 +140,9 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<1> &, Rt_layout<1> &) {}
+  virtual char const* name() { return "fft-dft-1D-real-forward"; }
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  { rtl_in.complex = rtl_out.complex; }
   virtual void by_reference(rtype *in, stride_type in_s,
 			    ctype *out, stride_type out_s,
 			    length_type l)
@@ -176,7 +184,9 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<1> &, Rt_layout<1> &) {}
+  virtual char const* name() { return "fft-dft-1D-real-inverse"; }
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  { rtl_in.complex = rtl_out.complex; }
   virtual void by_reference(ctype *in, stride_type in_s,
 			    rtype *out, stride_type out_s,
 			    length_type l)
@@ -224,8 +234,10 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual char const* name() { return "fft-dft-2D-complex"; }
   virtual void query_layout(Rt_layout<2> &) {}
-  virtual void query_layout(Rt_layout<2> &, Rt_layout<2> &) {}
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  { rtl_in.complex = rtl_out.complex; }
   virtual void in_place(ctype *inout,
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
@@ -302,7 +314,9 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<2> &, Rt_layout<2> &) {}
+  virtual char const* name() { return "fft-dft-2D-real-forward"; }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  { rtl_in.complex = rtl_out.complex; }
   virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    ctype *out,
@@ -382,7 +396,9 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<2> &, Rt_layout<2> &) {}
+  virtual char const* name() { return "fft-dft-2D-real-inverse"; }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  { rtl_in.complex = rtl_out.complex; }
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    rtype *out,
@@ -477,8 +493,10 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual char const* name() { return "fft-dft-3D-complex"; }
   virtual void query_layout(Rt_layout<3> &) {}
-  virtual void query_layout(Rt_layout<3> &, Rt_layout<3> &) {}
+  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
+  { rtl_in.complex = rtl_out.complex; }
   virtual void in_place(ctype *inout,
 			stride_type x_stride,
 			stride_type y_stride,
@@ -577,7 +595,9 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<3> &, Rt_layout<3> &) {}
+  virtual char const* name() { return "fft-dft-3D-real-forward"; }
+  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
+  { rtl_in.complex = rtl_out.complex; }
   virtual void by_reference(rtype *in,
 			    stride_type in_x_stride,
 			    stride_type in_y_stride,
@@ -699,7 +719,9 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<3> &, Rt_layout<3> &) {}
+  virtual char const* name() { return "fft-dft-3D-real-inverse"; }
+  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
+  { rtl_in.complex = rtl_out.complex; }
   virtual void by_reference(ctype *in,
 			    stride_type in_x_stride,
 			    stride_type in_y_stride,
@@ -874,7 +896,9 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<2> &, Rt_layout<2> &) {}
+  virtual char const* name() { return "fftm-dft-real-forward"; }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  { rtl_in.complex = rtl_out.complex; }
   virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    ctype *out,
@@ -919,7 +943,9 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<2> &, Rt_layout<2> &) {}
+  virtual char const* name() { return "fftm-dft-real-inverse"; }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  { rtl_in.complex = rtl_out.complex; }
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    rtype *out,
@@ -980,8 +1006,10 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
+  virtual char const* name() { return "fftm-dft-complex"; }
   virtual void query_layout(Rt_layout<2> &) {}
-  virtual void query_layout(Rt_layout<2> &, Rt_layout<2> &) {}
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  { rtl_in.complex = rtl_out.complex; }
   virtual void in_place(ctype *inout,
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
Index: src/vsip/core/fft/backend.hpp
===================================================================
--- src/vsip/core/fft/backend.hpp	(revision 166043)
+++ src/vsip/core/fft/backend.hpp	(working copy)
@@ -47,6 +47,7 @@
 {
 public:
   virtual ~backend() {}
+  virtual char const* name() { return "fft-backend-1D-real-forward"; }
   virtual bool supports_scale() { return false;}
   virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
   {
@@ -73,6 +74,7 @@
 {
 public:
   virtual ~backend() {}
+  virtual char const* name() { return "fft-backend-1D-real-inverse"; }
   virtual bool supports_scale() { return false;}
   virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
   {
@@ -99,6 +101,7 @@
 {
 public:
   virtual ~backend() {}
+  virtual char const* name() { return "fft-backend-1D-complex"; }
   virtual bool supports_scale() { return false;}
   virtual void query_layout(Rt_layout<1> &rtl_inout)
   {
@@ -136,6 +139,7 @@
 {
 public:
   virtual ~backend() {}
+  virtual char const* name() { return "fft-backend-2D-real-forward"; }
   virtual bool supports_scale() { return false;}
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
@@ -166,6 +170,7 @@
 {
 public:
   virtual ~backend() {}
+  virtual char const* name() { return "fft-backend-2D-real-inverse"; }
   virtual bool supports_scale() { return false;}
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
@@ -196,6 +201,7 @@
 {
 public:
   virtual ~backend() {}
+  virtual char const* name() { return "fft-backend-2D-complex"; }
   virtual bool supports_scale() { return false;}
   virtual void query_layout(Rt_layout<2> &rtl_inout)
   {
@@ -241,6 +247,7 @@
 {
 public:
   virtual ~backend() {}
+  virtual char const* name() { return "fft-backend-2D-real-forward"; }
   virtual bool supports_scale() { return false;}
   virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
   {
@@ -283,6 +290,7 @@
 {
 public:
   virtual ~backend() {}
+  virtual char const* name() { return "fft-backend-2D-real-inverse"; }
   virtual bool supports_scale() { return false;}
   virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
   {
@@ -325,6 +333,7 @@
 {
 public:
   virtual ~backend() {}
+  virtual char const* name() { return "fft-backend-2D-complex"; }
   virtual bool supports_scale() { return false;}
   virtual void query_layout(Rt_layout<3> &rtl_inout)
   {
@@ -393,6 +402,7 @@
 {
 public:
   virtual ~fftm() {}
+  virtual char const* name() { return "fftm-backend-real-forward"; }
   virtual bool supports_scale() { return false;}
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
@@ -427,6 +437,7 @@
 {
 public:
   virtual ~fftm() {}
+  virtual char const* name() { return "fftm-backend-real-inverse"; }
   virtual bool supports_scale() { return false;}
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
@@ -461,6 +472,7 @@
 {
 public:
   virtual ~fftm() {}
+  virtual char const* name() { return "fftm-backend-complex"; }
   virtual bool supports_scale() { return false;}
   virtual void query_layout(Rt_layout<2> &rtl_inout)
   {
Index: src/vsip/opt/fftw3/fft_impl.cpp
===================================================================
--- src/vsip/opt/fftw3/fft_impl.cpp	(revision 166043)
+++ src/vsip/opt/fftw3/fft_impl.cpp	(working copy)
@@ -155,6 +155,7 @@
   Fft_impl(Domain<1> const &dom, unsigned number)
     : Fft_base<1, ctype, ctype>(dom, E, convert_NoT(number))
   {}
+  virtual char const* name() { return "fft-fftw3-1D-complex"; }
   virtual void in_place(ctype *inout, stride_type s, length_type l)
   {
     assert(s == 1 && static_cast<int>(l) == this->size_[0]);
@@ -197,6 +198,7 @@
   Fft_impl(Domain<1> const &dom, unsigned number)
     : Fft_base<1, rtype, ctype>(dom, A, convert_NoT(number))
   {}
+  virtual char const* name() { return "fft-fftw3-1D-real-forward"; }
   virtual void by_reference(rtype *in, stride_type,
 			    ctype *out, stride_type,
 			    length_type)
@@ -228,6 +230,8 @@
     : Fft_base<1, ctype, rtype>(dom, A, convert_NoT(number))
   {}
 
+  virtual char const* name() { return "fft-fftw3-1D-real-inverse"; }
+
   virtual bool requires_copy(Rt_layout<1> &) { return true;}
 
   virtual void by_reference(ctype *in, stride_type,
@@ -262,6 +266,7 @@
   Fft_impl(Domain<2> const &dom, unsigned number)
     : Fft_base<2, ctype, ctype>(dom, E, convert_NoT(number))
   {}
+  virtual char const* name() { return "fft-fftw3-2D-complex"; }
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
     rtl_in.pack = stride_unit_dense;
@@ -331,6 +336,8 @@
     : Fft_base<2, rtype, ctype>(dom, A, convert_NoT(number))
   {}
 
+  virtual char const* name() { return "fft-fftw3-2D-real-forward"; }
+
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
     rtl_in.pack = stride_unit_dense;
@@ -377,6 +384,8 @@
     : Fft_base<2, ctype, rtype>(dom, A, convert_NoT(number))
   {}
 
+  virtual char const* name() { return "fft-fftw3-2D-real-inverse"; }
+
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
     rtl_in.pack = stride_unit_dense;
@@ -424,6 +433,7 @@
   Fft_impl(Domain<3> const &dom, unsigned number)
     : Fft_base<3, ctype, ctype>(dom, E, convert_NoT(number))
   {}
+  virtual char const* name() { return "fft-fftw3-3D-complex"; }
   virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
   {
     rtl_in.pack = stride_unit_dense;
@@ -520,6 +530,8 @@
     : Fft_base<3, rtype, ctype>(dom, A, convert_NoT(number))
   {}
 
+  virtual char const* name() { return "fft-fftw3-3D-real-forward"; }
+
   virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
   {
     rtl_in.pack = stride_unit_dense;
@@ -581,6 +593,8 @@
   Fft_impl(Domain<3> const &dom, unsigned number)
     : Fft_base<3, ctype, rtype>(dom, A, convert_NoT(number))
   {}
+
+  virtual char const* name() { return "fft-fftw3-3D-real-inverse"; }
   
   virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
   {
@@ -646,6 +660,7 @@
       mult_(dom[1-A].size()) 
   {
   }
+  virtual char const* name() { return "fftm-fftw3-real-forward"; }
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
     rtl_in.pack = stride_unit_dense;
@@ -702,6 +717,8 @@
   {
   }
 
+  virtual char const* name() { return "fftm-fftw3-real-inverse"; }
+
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
     rtl_in.pack = stride_unit_dense;
@@ -758,6 +775,8 @@
   (dom[A], E, convert_NoT(number) | FFTW_UNALIGNED),
       mult_(dom[1-A].size()) {}
 
+  virtual char const* name() { return "fftm-fftw3-complex"; }
+
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
     rtl_in.pack = stride_unit_dense;
Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 166066)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -216,7 +216,6 @@
 			    ctype *out, stride_type out_stride,
 			    length_type length)
   {
-    printf("by_reference\n");
     assert(in_stride == 1);
     assert(out_stride == 1);
     this->fft(in, out, length, this->scale_, E);
Index: src/vsip/opt/cbe/ppu/bindings.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/bindings.hpp	(revision 166066)
+++ src/vsip/opt/cbe/ppu/bindings.hpp	(working copy)
@@ -36,9 +36,13 @@
   Macros
 ***********************************************************************/
 
-// DMA size granularity in bytes (although DMAs of fixed size 1, 2, 4,
-// and 8 bytes are also allowed)
+// DMA starting address alignment (in bytes).
 
+#define VSIP_IMPL_CBE_DMA_ALIGNMENT 16
+
+// Bulk DMA size granularity (in bytes) 
+// (Note that DMAs of fixed size 1, 2, 4, and 8 bytes are also allowed.)
+
 #define VSIP_IMPL_CBE_DMA_GRANULARITY 16
 
 
@@ -54,7 +58,8 @@
 namespace cbe
 {
 
-// Determine if size in bytes is valid for a Cbe DMA.
+// Determine if DMA size (in bytes) is valid for a bulk DMA.
+
 inline bool
 is_dma_size_ok(length_type size_in_bytes)
 {
@@ -66,7 +71,27 @@
 }
 
 
+// Determine if DMA address is properly aligned.
 
+template <typename T>
+inline bool
+is_dma_addr_ok(T const* addr)
+{
+  return ((intptr_t)addr & (VSIP_IMPL_CBE_DMA_ALIGNMENT - 1)) == 0;
+}
+
+
+
+template <typename T>
+inline bool
+is_dma_addr_ok(std::pair<T*, T*> const& addr)
+{
+  return is_dma_addr_ok(addr.first) && is_dma_addr_ok(addr.second);
+}
+
+
+
+
 template <typename T> void vmul(T const *A, T const *B, T *R, length_type len);
 
 template <template <typename, typename> class Operator,
@@ -115,8 +140,11 @@
     Ext_data<LBlock,   lblock_lp> ext_l(src.left(),  SYNC_IN);
     Ext_data<RBlock,   rblock_lp> ext_r(src.right(), SYNC_IN);
     return (ext_dst.stride(0) == 1 &&
-	    ext_l.stride(0) == 1 &&
-	    ext_r.stride(0) == 1);
+	    ext_l.stride(0) == 1   &&
+	    ext_r.stride(0) == 1   &&
+	    is_dma_addr_ok(ext_dst.data()) &&
+	    is_dma_addr_ok(ext_l.data())   &&
+	    is_dma_addr_ok(ext_r.data()) );
   }
 };
 
Index: src/vsip/opt/cbe/ppu/bindings.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/bindings.cpp	(revision 166066)
+++ src/vsip/opt/cbe/ppu/bindings.cpp	(working copy)
@@ -41,6 +41,10 @@
 
   length_type orig_len = len;
 
+  assert(is_dma_addr_ok(A));
+  assert(is_dma_addr_ok(B));
+  assert(is_dma_addr_ok(R));
+
   Vmul_params params;
   params.length = chunk_size;
   params.a_blk_stride = chunk_size;
Index: src/vsip/opt/simd/simd.hpp
===================================================================
--- src/vsip/opt/simd/simd.hpp	(revision 166043)
+++ src/vsip/opt/simd/simd.hpp	(working copy)
@@ -23,7 +23,7 @@
 ***********************************************************************/
 
 #if __VEC__
-#  define VSIPL_IMPL_SIMD_ALTIVEC
+#  define VSIP_IMPL_SIMD_ALTIVEC
 #  if !_MC_EXEC
 #    include <altivec.h>
 #    undef vector
@@ -68,6 +68,8 @@
 //              - false if default trait is used (simd_type == value_type)
 //  - alignment - alignment required for SIMD types (in bytes).
 //                (If alignment == 1, then no special alignment required).
+//  - scalar_pos - the position of the scalar value if SIMD vector is
+//                 written to array in memory.
 //
 // Types:
 //  - value_type - base type (or element type) of SIMD vector
@@ -123,16 +125,23 @@
   typedef T	value_type;
   typedef T	simd_type;
    
-  static int const  vec_size = 1;
-  static bool const is_accel = false;
-  static int  const alignment = 1;
+  static int const  vec_size   = 1;
+  static bool const is_accel   = false;
+  static int  const alignment  = 1;
+  static unsigned int const scalar_pos = 0;
 
   static intptr_t alignment_of(value_type const* addr)
   { return (intptr_t)addr & (alignment - 1); }
 
+  static simd_type zero()
+  { return simd_type(0); }
+
   static simd_type load(value_type const* addr)
   { return *addr; }
 
+  static simd_type load_scalar(value_type value)
+  { return value; }
+
   static simd_type load_scalar_all(value_type value)
   { return value; }
 
@@ -176,33 +185,56 @@
 
 
 
+/***********************************************************************
+  AltiVec
+***********************************************************************/
+
 // Not all compilers support typedefs with altivec vector types:
-// As of 20060727:
-//  - Greenhills supports vector typedefs.
-//  - GCC 3.4.4 does not
+// As of (date):
+//  - Greenhills supports vector typedefs (20060727)
+//  - GCC 3.4.4 does not (20060727)
+//  - GCC 4.1.1 does not (20061108)
 
-#ifdef VSIPL_IMPL_SIMD_ALTIVEC
-#  if __ghs__
+#ifdef VSIP_IMPL_SIMD_ALTIVEC
+#  if __ghs__ || __GNUC__ >= 4
 
+#    if __ghs__
+#      define VSIP_IMPL_AV_BOOL bool
+#      define VSIP_IMPL_AV_LITERAL(_type_, ...) ((_type_)(__VA_ARGS__))
+#    else
+#      define VSIP_IMPL_AV_BOOL __bool
+#      define VSIP_IMPL_AV_LITERAL(_type_, ...) ((_type_){__VA_ARGS__})
+#    endif
+
+#if __BIG_ENDIAN__
+#  define VSIP_IMPL_SCALAR_POS(VS) 0
+#else
+#  define VSIP_IMPL_SCALAR_POS(VS) VS-1
+#endif
+
 // PowerPC AltiVec - signed char
 template <>
 struct Simd_traits<signed char>
 {
-  typedef signed char          value_type;
-  typedef __vector signed char simd_type;
-  typedef __vector bool char   bool_simd_type;
+  typedef signed char                     value_type;
+  typedef __vector signed char            simd_type;
+  typedef __vector VSIP_IMPL_AV_BOOL char bool_simd_type;
    
-  static int  const vec_size  = 16;
-  static bool const is_accel  = true;
-  static int  const alignment = 16;
+  static int  const vec_size   = 16;
+  static bool const is_accel   = true;
+  static int  const alignment  = 16;
 
-  static int  const scalar_pos = vec_size-1;
+  static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
 
   static intptr_t alignment_of(value_type const* addr)
   { return (intptr_t)addr & (alignment - 1); }
 
   static simd_type zero()
-  { return (simd_type)(0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0 ); }
+  {
+    return VSIP_IMPL_AV_LITERAL(simd_type,
+				0, 0, 0, 0,  0, 0, 0, 0,
+				0, 0, 0, 0,  0, 0, 0, 0 );
+  }
 
   static simd_type load(value_type const* addr)
   { return vec_ld(0, (value_type*)addr); }
@@ -256,26 +288,43 @@
 template <>
 struct Simd_traits<signed short>
 {
-  typedef signed short          value_type;
-  typedef __vector signed short simd_type;
-  typedef __vector bool short   bool_simd_type;
-  typedef __vector signed char  pack_simd_type;
+  typedef signed short                value_type;
+  typedef __vector signed short       simd_type;
+  typedef __vector VSIP_IMPL_AV_BOOL short bool_simd_type;
+  typedef __vector signed char        pack_simd_type;
    
   static int const  vec_size = 8;
   static bool const is_accel = true;
   static int  const alignment = 16;
 
-  static int  const scalar_pos = vec_size-1;
+  static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
 
   static intptr_t alignment_of(value_type const* addr)
   { return (intptr_t)addr & (alignment - 1); }
 
   static simd_type zero()
-  { return (simd_type)(0, 0, 0, 0,  0, 0, 0, 0); }
+  {
+    return VSIP_IMPL_AV_LITERAL(simd_type, 0, 0, 0, 0,  0, 0, 0, 0);
+  }
 
   static simd_type load(value_type const* addr)
   { return vec_ld(0, (short*)addr); }
 
+  static simd_type load_scalar(value_type value)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec    = zero();
+    u.val[0] = value;
+    return u.vec;
+  }
+
+  static simd_type load_scalar_all(value_type value)
+  { return vec_splat(load_scalar(value), scalar_pos); }
+
   static void store(value_type* addr, simd_type const& vec)
   { vec_st(vec, 0, addr); }
 
@@ -313,26 +362,43 @@
 template <>
 struct Simd_traits<signed int>
 {
-  typedef signed int            value_type;
-  typedef __vector signed int   simd_type;
-  typedef __vector bool int     bool_simd_type;
-  typedef __vector signed short pack_simd_type;
+  typedef signed int                     value_type;
+  typedef __vector signed int            simd_type;
+  typedef __vector VSIP_IMPL_AV_BOOL int bool_simd_type;
+  typedef __vector signed short          pack_simd_type;
    
   static int const  vec_size = 4;
   static bool const is_accel = true;
   static int  const alignment = 16;
 
-  static int  const scalar_pos = vec_size-1;
+  static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
 
   static intptr_t alignment_of(value_type const* addr)
   { return (intptr_t)addr & (alignment - 1); }
 
   static simd_type zero()
-  { return (simd_type)(0, 0, 0, 0); }
+  {
+    return VSIP_IMPL_AV_LITERAL(simd_type, 0, 0, 0, 0);
+  }
 
   static simd_type load(value_type const* addr)
   { return vec_ld(0, (value_type*)addr); }
 
+  static simd_type load_scalar(value_type value)
+  {
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u;
+    u.vec    = zero();
+    u.val[0] = value;
+    return u.vec;
+  }
+
+  static simd_type load_scalar_all(value_type value)
+  { return vec_splat(load_scalar(value), scalar_pos); }
+
   static void store(value_type* addr, simd_type const& vec)
   { vec_st(vec, 0, addr); }
 
@@ -370,35 +436,30 @@
 template <>
 struct Simd_traits<float>
 {
-  typedef float             value_type;
-  typedef __vector float    simd_type;
-  typedef __vector bool int bool_simd_type;
+  typedef float                          value_type;
+  typedef __vector float                 simd_type;
+  typedef __vector VSIP_IMPL_AV_BOOL int bool_simd_type;
    
   static int  const vec_size = 4;
   static bool const is_accel = true;
   static int  const alignment = 16;
 
-  static int  const scalar_pos = vec_size-1;
+  static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
 
   static intptr_t alignment_of(value_type const* addr)
   { return (intptr_t)addr & (alignment - 1); }
 
   static simd_type zero()
-  { return (simd_type)(0.f, 0.f, 0.f, 0.f); }
+  {
+    return VSIP_IMPL_AV_LITERAL(simd_type, 0.f, 0.f, 0.f, 0.f);
+  }
 
   static simd_type load(value_type const* addr)
   { return vec_ld(0, (value_type*)addr); }
 
   static simd_type load_scalar(value_type value)
   {
-    union
-    {
-      simd_type  vec;
-      value_type val[vec_size];
-    } u;
-    u.vec    = zero();
-    u.val[0] = value;
-    return u.vec;
+    return VSIP_IMPL_AV_LITERAL(simd_type, value, 0.f, 0.f, 0.f);
   }
 
   static simd_type load_scalar_all(value_type value)
@@ -428,37 +489,56 @@
 
   static simd_type real_from_interleaved(simd_type const& v1,
 					 simd_type const& v2)
-  { return zero(); /* return _mm_shuffle_ps(v1, v2, 0x88); */ }
+  {
+    static __vector unsigned char shuf = 
+      VSIP_IMPL_AV_LITERAL(__vector unsigned char,
+			   0,   1,  2,  3,  8,  9, 10, 11,
+			   16, 17, 18, 19, 24, 25, 26, 27);
+    return vec_perm(v1, v2, shuf);
+  }
 
   static simd_type imag_from_interleaved(simd_type const& v1,
 					 simd_type const& v2)
-  { return zero(); /* return _mm_shuffle_ps(v1, v2, 0xDD); */ }
+  {
+    static __vector unsigned char shuf = 
+      VSIP_IMPL_AV_LITERAL(__vector unsigned char,
+			    4,  5,  6,  7, 12, 13, 14, 15,
+			   20, 21, 22, 23, 28, 29, 30, 31);
+    return vec_perm(v1, v2, shuf);
+  }
 
   static simd_type interleaved_lo_from_split(simd_type const& real,
 					     simd_type const& imag)
-  { return vec_mergel(real, imag); }
+  { return vec_mergeh(real, imag); }
 
   static simd_type interleaved_hi_from_split(simd_type const& real,
 					     simd_type const& imag)
-  { return vec_mergeh(real, imag); }
+  { return vec_mergel(real, imag); }
 
   static void enter() {}
   static void exit()  {}
 };
+#    undef VSIP_IMPL_AV_BOOL
+#    undef VSIP_IMPL_AV_LITERAL
 #  endif
 #endif
 
 
 
+/***********************************************************************
+  SSE
+***********************************************************************/
+
 #ifdef __SSE__
 template <>
 struct Simd_traits<signed char> {
   typedef signed char	value_type;
   typedef __m128i	simd_type;
    
-  static int const  vec_size = 16;
-  static bool const is_accel = true;
-  static int  const alignment = 16;
+  static int const  vec_size   = 16;
+  static bool const is_accel   = true;
+  static int  const alignment  = 16;
+  static unsigned int  const scalar_pos = 0;
 
   static intptr_t alignment_of(value_type const* addr)
   { return (intptr_t)addr & (alignment - 1); }
@@ -512,9 +592,10 @@
   typedef short		value_type;
   typedef __m128i	simd_type;
    
-  static int const  vec_size = 8;
-  static bool const is_accel = true;
-  static int  const alignment = 16;
+  static int const  vec_size   = 8;
+  static bool const is_accel   = true;
+  static int  const alignment  = 16;
+  static unsigned int  const scalar_pos = 0;
 
   static intptr_t alignment_of(value_type const* addr)
   { return (intptr_t)addr & (alignment - 1); }
@@ -544,6 +625,24 @@
   static simd_type sub(simd_type const& v1, simd_type const& v2)
   { return _mm_sub_epi16(v1, v2); }
 
+  static simd_type mul(simd_type const& v1, simd_type const& v2)
+  { return _mm_mullo_epi16(v1, v2); }
+
+  static simd_type div(simd_type const& v1, simd_type const& v2)
+  {
+    // PROFILE - EXPENSIVE
+    union
+    {
+      simd_type  vec;
+      value_type val[vec_size];
+    } u1, u2, r;
+    u1.vec = v1;
+    u2.vec = v2;
+    for (int i=0; i<vec_size; ++i)
+      r.val[i] = u1.val[i]/u2.val[i];
+    return r.vec;
+  }
+
   static simd_type band(simd_type const& v1, simd_type const& v2)
   { return _mm_and_si128(v1, v2); }
 
@@ -557,9 +656,6 @@
   { return bxor(v1, load_scalar_all(0xFFFF)); }
 
 #if 0
-  static simd_type mul(simd_type const& v1, simd_type const& v2)
-  { return _mm_mul_epi16(v1, v2); }
-
   static simd_type extend(simd_type const& v)
   { return _mm_shuffle_ps(v, v, 0x00); }
 
@@ -594,9 +690,10 @@
   typedef int		value_type;
   typedef __m128i	simd_type;
    
-  static int const  vec_size = 4;
-  static bool const is_accel = true;
-  static int  const alignment = 16;
+  static int const  vec_size   = 4;
+  static bool const is_accel   = true;
+  static int  const alignment  = 16;
+  static unsigned int  const scalar_pos = 0;
 
   static intptr_t alignment_of(value_type const* addr)
   { return (intptr_t)addr & (alignment - 1); }
@@ -677,9 +774,10 @@
   typedef float		value_type;
   typedef __m128	simd_type;
    
-  static int const  vec_size = 4;
-  static bool const is_accel = true;
-  static int  const alignment = 16;
+  static int const  vec_size   = 4;
+  static bool const is_accel   = true;
+  static int  const alignment  = 16;
+  static unsigned int  const scalar_pos = 0;
 
   static intptr_t alignment_of(value_type const* addr)
   { return (intptr_t)addr & (alignment - 1); }
@@ -762,9 +860,10 @@
   typedef double	value_type;
   typedef __m128d	simd_type;
    
-  static int const  vec_size = 2;
-  static bool const is_accel = true;
-  static int  const alignment = 16;
+  static int const  vec_size   = 2;
+  static bool const is_accel   = true;
+  static int  const alignment  = 16;
+  static unsigned int  const scalar_pos = 0;
 
   static intptr_t alignment_of(value_type const* addr)
   { return (intptr_t)addr & (alignment - 1); }
@@ -846,6 +945,8 @@
 {
   typedef Simd_traits<T> base_traits;
 
+  static unsigned int  const scalar_pos = 0;
+
   typedef typename Simd_traits<T>::simd_type base_simd_type;
 
   typedef std::complex<T> value_type;
Index: src/vsip/opt/simd/vmul.hpp
===================================================================
--- src/vsip/opt/simd/vmul.hpp	(revision 166043)
+++ src/vsip/opt/simd/vmul.hpp	(working copy)
@@ -317,8 +317,9 @@
       // PROFILE
       while (n)
       {
-	*pRr = *pAr * *pBr - *pAi * *pBi;
+	T rr = *pAr * *pBr - *pAi * *pBi;
 	*pRi = *pAr * *pBi + *pAi * *pBr;
+	*pRr = rr;
 	pRr++; pRi++;
 	pAr++; pAi++;
 	pBr++; pBi++;
@@ -330,8 +331,9 @@
     // clean up initial unaligned values
     while (simd::alignment_of(pRr) != 0)
     {
-      *pRr = *pAr * *pBr - *pAi * *pBi;
+      T rr = *pAr * *pBr - *pAi * *pBi;
       *pRi = *pAr * *pBi + *pAi * *pBr;
+      *pRr = rr;
       pRr++; pRi++;
       pAr++; pAi++;
       pBr++; pBi++;
@@ -372,8 +374,9 @@
 
     while (n)
     {
-      *pRr = *pAr * *pBr - *pAi * *pBi;
+      T rr = *pAr * *pBr - *pAi * *pBi;
       *pRi = *pAr * *pBi + *pAi * *pBr;
+      *pRr = rr;
       pRr++; pRi++;
       pAr++; pAi++;
       pBr++; pBi++;
Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 166043)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -270,6 +270,27 @@
 template <dimension_type Dim,
 	  typename       Block1,
 	  typename       Block2>
+struct Diag_eval_dispatch_helper<Dim, Block1, Block2, Tag_serial_expr>
+{
+  static void info(
+    Block1&       blk1,
+    Block2 const& blk2)
+  {
+    // Equivalent to:
+    //   diagnose_eval_list_std(dst, src);
+    std::cout << "diagnose_eval_list" << std::endl
+	      << "  dst expr: " << typeid(Block1).name() << std::endl
+	      << "  src expr: " << typeid(Block2).name() << std::endl;
+    Diag_eval_list_helper<Dim, Block1, Block2, vsip::impl::LibraryTagList>
+	::exec(blk1, blk2);
+  }
+};
+
+
+
+template <dimension_type Dim,
+	  typename       Block1,
+	  typename       Block2>
 struct Diag_eval_dispatch_helper<Dim, Block1, Block2, Tag_par_expr_noreorg>
 {
   typedef typename Block1::map_type map1_type;
@@ -383,54 +404,6 @@
 
 
 
-// Diagnose Dispatch_assign.
-
-template <typename       DstViewT,
-          typename       SrcViewT>
-void
-diagnose_eval_dispatch(
-  DstViewT dst,
-  SrcViewT src)
-{
-  using std::cout;
-  using std::endl;
-
-  using vsip::impl::diag_detail::Dispatch_name;
-
-  typedef typename DstViewT::block_type dst_block_type;
-  typedef typename SrcViewT::block_type src_block_type;
-  dimension_type const dim = SrcViewT::dim;
-
-  typedef Dispatch_assign_helper<dim, dst_block_type, src_block_type, false>
-    dah;
-
-  typedef typename dah::type dispatch_type;
-
-  cout << "--------------------------------------------------------\n";
-  cout << "diagnose_eval_dispatch:" << std::endl
-       << "  dim: " << dim << std::endl
-       << "  DstBlockT    : " << typeid(dst_block_type).name() << endl
-       << "  SrcBlockT    : " << typeid(src_block_type).name() << endl
-       << "  is_illegal   : " << (dah::is_illegal ? "true" : "false") << endl
-       << "  is_rhs_expr  : " << (dah::is_rhs_expr ? "true" : "false") << endl
-       << "  is_rhs_simple: " << (dah::is_rhs_simple ? "true" : "false") <<endl
-       << "  is_rhs_reorg : " << (dah::is_rhs_reorg ? "true" : "false") << endl
-       << "  is_lhs_split : " << (dah::is_lhs_split ? "true" : "false") << endl
-       << "  is_rhs_split : " << (dah::is_rhs_split ? "true" : "false") << endl
-       << "  lhs_cost     : " << dah::lhs_cost << endl
-       << "  rhs_cost     : " << dah::rhs_cost << endl
-       << "  TYPE         : " << Dispatch_name<dispatch_type>::name() << endl
-    ;
-  cout << "--------------------------------------------------------\n";
-
-  diag_detail::Diag_eval_dispatch_helper<dim, dst_block_type, src_block_type,
-    dispatch_type>::info(dst.block(), src.block());
-
-  cout << "--------------------------------------------------------\n";
-}
-
-
-
 // Diagnose evaluation of an expression 'dst = src' with a list of
 // dispatch tags.
 //
@@ -518,6 +491,57 @@
   diagnose_eval_list<LibraryTagList>(dst, src);
 }
 
+
+
+// Diagnose Dispatch_assign.
+
+template <typename       DstViewT,
+          typename       SrcViewT>
+void
+diagnose_eval_dispatch(
+  DstViewT dst,
+  SrcViewT src)
+{
+  using std::cout;
+  using std::endl;
+
+  using vsip::impl::diag_detail::Dispatch_name;
+
+  typedef typename DstViewT::block_type dst_block_type;
+  typedef typename SrcViewT::block_type src_block_type;
+  dimension_type const dim = SrcViewT::dim;
+
+  typedef Dispatch_assign_helper<dim, dst_block_type, src_block_type, false>
+    dah;
+
+  typedef typename dah::type dispatch_type;
+
+  cout << "--------------------------------------------------------\n";
+  cout << "diagnose_eval_dispatch:" << std::endl
+       << "  dim: " << dim << std::endl
+       << "  DstBlockT    : " << typeid(dst_block_type).name() << endl
+       << "  SrcBlockT    : " << typeid(src_block_type).name() << endl
+       << "  is_illegal   : " << (dah::is_illegal ? "true" : "false") << endl
+       << "  is_rhs_expr  : " << (dah::is_rhs_expr ? "true" : "false") << endl
+       << "  is_rhs_simple: " << (dah::is_rhs_simple ? "true" : "false") <<endl
+       << "  is_rhs_reorg : " << (dah::is_rhs_reorg ? "true" : "false") << endl
+       << "  is_lhs_split : " << (dah::is_lhs_split ? "true" : "false") << endl
+       << "  is_rhs_split : " << (dah::is_rhs_split ? "true" : "false") << endl
+       << "  lhs_cost     : " << dah::lhs_cost << endl
+       << "  rhs_cost     : " << dah::rhs_cost << endl
+       << "  TYPE         : " << Dispatch_name<dispatch_type>::name() << endl
+    ;
+  cout << "--------------------------------------------------------\n";
+
+  diag_detail::Diag_eval_dispatch_helper<dim, dst_block_type, src_block_type,
+    dispatch_type>::info(dst.block(), src.block());
+
+  cout << "--------------------------------------------------------\n";
+}
+
+
+
+
 } // namespace vsip::impl::diag_detail
 } // namespace vsip
 
Index: tests/regressions/fft_inter_split.cpp
===================================================================
--- tests/regressions/fft_inter_split.cpp	(revision 0)
+++ tests/regressions/fft_inter_split.cpp	(revision 0)
@@ -0,0 +1,170 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/fft_inter_split.cpp
+    @author  Jules Bergmann
+    @date    2007-03-16
+    @brief   VSIPL++ Library: Test Fft between split and interleaved views.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <algorithm>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/signal.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+
+// Test FFT by-reference
+
+template <typename T,
+	  typename SrcComplexFmt,
+	  typename DstComplexFmt>
+void
+test_fft_br(length_type size)
+{
+  typedef impl::Stride_unit_dense sud_type;
+  typedef impl::Layout<1, row1_type, sud_type, SrcComplexFmt> src_lp_type;
+  typedef impl::Layout<1, row1_type, sud_type, DstComplexFmt> dst_lp_type;
+
+  typedef impl::Fast_block<1, T, src_lp_type> src_block_type;
+  typedef impl::Fast_block<1, T, dst_lp_type> dst_block_type;
+
+  typedef Fft<const_Vector, T, T, fft_fwd, by_reference, 1, alg_space>
+	fft_type;
+
+  fft_type fft(Domain<1>(size), 1.f);
+
+  Vector<T, src_block_type> in(size);
+  Vector<T, dst_block_type> out(size);
+
+  in = T(1);
+
+  fft(in, out);
+
+  test_assert(out.get(0) == T(size));
+}
+
+
+
+// Test FFT by-value
+
+template <typename T,
+	  typename SrcComplexFmt,
+	  typename DstComplexFmt>
+void
+test_fft_bv(length_type size)
+{
+  typedef impl::Stride_unit_dense sud_type;
+  typedef impl::Layout<1, row1_type, sud_type, SrcComplexFmt> src_lp_type;
+  typedef impl::Layout<1, row1_type, sud_type, DstComplexFmt> dst_lp_type;
+
+  typedef impl::Fast_block<1, T, src_lp_type> src_block_type;
+  typedef impl::Fast_block<1, T, dst_lp_type> dst_block_type;
+
+  typedef Fft<const_Vector, T, T, fft_fwd, by_value, 1, alg_space>
+	fft_type;
+
+  fft_type fft(Domain<1>(size), 1.f);
+
+  Vector<T, src_block_type> in(size);
+  Vector<T, dst_block_type> out(size);
+
+  in = T(1);
+
+  out = fft(in);
+
+  test_assert(out.get(0) == T(size));
+}
+
+
+
+// Test FFT by-value in an expression
+
+template <typename T,
+	  typename SrcComplexFmt,
+	  typename DstComplexFmt>
+void
+test_fft_bv_expr(length_type size)
+{
+  typedef impl::Stride_unit_dense sud_type;
+  typedef impl::Layout<1, row1_type, sud_type, SrcComplexFmt> src_lp_type;
+  typedef impl::Layout<1, row1_type, sud_type, DstComplexFmt> dst_lp_type;
+
+  typedef impl::Fast_block<1, T, src_lp_type> src_block_type;
+  typedef impl::Fast_block<1, T, dst_lp_type> dst_block_type;
+
+  typedef Fft<const_Vector, T, T, fft_fwd, by_value, 1, alg_space>
+	fft_type;
+
+  fft_type fft(Domain<1>(size), 1.f);
+
+  Vector<T, src_block_type> in(size);
+  Vector<T, dst_block_type> out(size);
+
+  in = T(1);
+  out = T(0);
+
+  out = out + fft(in);
+
+  test_assert(out.get(0) == T(size));
+}
+
+
+template <typename T>
+void
+test_set(length_type size)
+{
+  typedef impl::Cmplx_inter_fmt Cif;
+  typedef impl::Cmplx_split_fmt Csf;
+
+  test_fft_br<complex<float>, Cif, Cif>(size);
+  test_fft_br<complex<float>, Csf, Csf>(size);
+  test_fft_br<complex<float>, Cif, Csf>(size);
+  test_fft_br<complex<float>, Csf, Cif>(size);
+
+  test_fft_bv<complex<float>, Cif, Cif>(size);
+  test_fft_bv<complex<float>, Csf, Csf>(size);
+  test_fft_bv<complex<float>, Cif, Csf>(size);
+  test_fft_bv<complex<float>, Csf, Cif>(size);
+
+  test_fft_bv_expr<complex<float>, Cif, Cif>(size);
+  test_fft_bv_expr<complex<float>, Csf, Csf>(size);
+  test_fft_bv_expr<complex<float>, Cif, Csf>(size);
+  test_fft_bv_expr<complex<float>, Csf, Cif>(size);
+}
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  // test_set<complex<float> >(16);
+  test_set<complex<float> >(256);
+
+  return 0;
+}
Index: tests/simd.cpp
===================================================================
--- tests/simd.cpp	(revision 0)
+++ tests/simd.cpp	(revision 0)
@@ -0,0 +1,400 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    simd.cpp
+    @author  Jules Bergmann
+    @date    2005-07-28
+    @brief   VSIPL++ Library: Unit tests for generic simd traits classes.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#define VERBOSE 0
+
+#if VERBOSE
+#  include <iostream>
+#endif
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip/core/metaprogramming.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+using vsip::impl::Bool_type;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename T>
+void
+test_zero()
+{
+  typedef vsip::impl::simd::Simd_traits<T> traits;
+
+  typedef typename traits::value_type value_type;
+  typedef typename traits::simd_type  simd_type;
+
+  length_type const vec_size = traits::vec_size;
+
+  union
+  {
+    simd_type  vec;
+    value_type val[vec_size];
+  } u;
+
+  u.vec = traits::zero();
+
+  for (index_type i=0; i<vec_size; ++i)
+    test_assert(u.val[i] == value_type());
+}
+
+
+
+template <typename T>
+void
+test_load_scalar()
+{
+  typedef vsip::impl::simd::Simd_traits<T> traits;
+
+  typedef typename traits::value_type value_type;
+  typedef typename traits::simd_type  simd_type;
+
+  length_type const vec_size = traits::vec_size;
+
+  union
+  {
+    simd_type  vec;
+    value_type val[vec_size];
+  } u;
+
+  // Zero out the vector.
+  u.vec = traits::zero();
+
+  // Confirm it has been zero'd.
+  for (index_type i=0; i<vec_size; ++i)
+    test_assert(u.val[i] == value_type());
+
+  // Load a scalar.
+  u.vec = traits::load_scalar(value_type(1));
+
+#if VERBOSE
+  std::cout << "load_test_scalar<" << typeid(T).name() << ">\n";
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "u.val[" << i << "]: " << u.val[i] << std::endl;
+#endif
+
+  // Check that value is loaded into the 'scalar position'.
+  test_assert(u.val[traits::scalar_pos] == value_type(1));
+  for (index_type i=0; i<vec_size; ++i)
+    if (i != traits::scalar_pos)
+      test_assert(u.val[i] == value_type());
+}
+
+
+
+template <typename T>
+void
+test_load_scalar_all()
+{
+  typedef vsip::impl::simd::Simd_traits<T> traits;
+
+  typedef typename traits::value_type value_type;
+  typedef typename traits::simd_type  simd_type;
+
+  length_type const vec_size = traits::vec_size;
+
+  union
+  {
+    simd_type  vec;
+    value_type val[vec_size];
+  } u;
+
+  u.vec = traits::load_scalar_all(value_type(1));
+
+  for (index_type i=0; i<vec_size; ++i)
+    test_assert(u.val[i] == value_type(1));
+}
+
+
+
+template <typename T>
+void
+test_interleaved(Bool_type<true>)
+{
+  typedef vsip::impl::simd::Simd_traits<T> traits;
+
+  typedef typename traits::value_type value_type;
+  typedef typename traits::simd_type  simd_type;
+
+  length_type const vec_size = traits::vec_size;
+
+  union
+  {
+    simd_type  vec;
+    value_type val[vec_size];
+  } ri1, ri2, rr, ii, new_ri1, new_ri2;
+
+  for (index_type i=0; i<vec_size/2; ++i)
+  {
+    ri1.val[2*i]   = (2*i);
+    ri1.val[2*i+1] = (3*i+1);
+    ri2.val[2*i]   = (2*(i+vec_size/2));
+    ri2.val[2*i+1] = (3*(i+vec_size/2)+1);
+  }
+
+  rr.vec = traits::real_from_interleaved(ri1.vec, ri2.vec);
+  ii.vec = traits::imag_from_interleaved(ri1.vec, ri2.vec);
+  new_ri1.vec = traits::interleaved_lo_from_split(rr.vec, ii.vec);
+  new_ri2.vec = traits::interleaved_hi_from_split(rr.vec, ii.vec);
+
+#if VERBOSE
+  std::cout << "------------------------------------------------" << std::endl;
+  std::cout << "test_interleaved: " << std::endl;
+  std::cout << "  vec_size: " << vec_size << std::endl;
+  std::cout << "  accelerated: " << (traits::is_accel ? "yes" : "no") << std::endl;
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "ri1.val[" << i << "]: " << ri1.val[i] << std::endl;
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "ri2.val[" << i << "]: " << ri2.val[i] << std::endl;
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "rr.val[" << i << "]: " << rr.val[i] << std::endl;
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "ii.val[" << i << "]: " << ii.val[i] << std::endl;
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "new_ri1.val[" << i << "]: " << new_ri1.val[i] << std::endl;
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "new_ri2.val[" << i << "]: " << new_ri2.val[i] << std::endl;
+#endif
+
+  for (index_type i=0; i<vec_size; ++i)
+  {
+    test_assert(rr.val[i] == value_type(2*i));
+    test_assert(ii.val[i] == value_type(3*i)+1);
+  }
+
+  for (index_type i=0; i<vec_size/2; ++i)
+  {
+    test_assert(new_ri1.val[2*i]   == (2*i));
+    test_assert(new_ri1.val[2*i+1] == (3*i+1));
+    test_assert(new_ri2.val[2*i]   == (2*(i+vec_size/2)));
+    test_assert(new_ri2.val[2*i+1] == (3*(i+vec_size/2)+1));
+  }
+}
+
+
+
+template <typename T>
+void
+test_interleaved(Bool_type<false>)
+{
+}
+
+
+
+template <typename T>
+void
+test_complex(Bool_type<true>)
+{
+  typedef vsip::impl::simd::Simd_traits<T> traits;
+
+  typedef typename traits::value_type value_type;
+  typedef typename traits::simd_type  simd_type;
+
+  length_type const vec_size = traits::vec_size;
+
+  union
+  {
+    simd_type           vec;
+    value_type          val[vec_size];
+  } ri1, ri2, rr, ii, new_ri1, new_ri2;
+
+  complex<value_type> cval1[vec_size/2];
+  complex<value_type> cval2[vec_size/2];
+
+  for (index_type i=0; i<vec_size/2; ++i)
+  {
+    cval1[i] = complex<value_type>(2*i, 3*i+1);
+    cval2[i] = complex<value_type>(2*(i+vec_size/2), 3*(i+vec_size/2)+1);
+  }
+
+  ri1.vec = traits::load((value_type*)cval1);
+  ri2.vec = traits::load((value_type*)cval2);
+
+  for (index_type i=0; i<vec_size/2; ++i)
+  {
+    test_assert(ri1.val[2*i]   == (2*i));
+    test_assert(ri1.val[2*i+1] == (3*i+1));
+    test_assert(ri2.val[2*i]   == (2*(i+vec_size/2)));
+    test_assert(ri2.val[2*i+1] == (3*(i+vec_size/2)+1));
+  }
+
+  rr.vec = traits::real_from_interleaved(ri1.vec, ri2.vec);
+  ii.vec = traits::imag_from_interleaved(ri1.vec, ri2.vec);
+  new_ri1.vec = traits::interleaved_lo_from_split(rr.vec, ii.vec);
+  new_ri2.vec = traits::interleaved_hi_from_split(rr.vec, ii.vec);
+
+#if VERBOSE
+  std::cout << "------------------------------------------------" << std::endl;
+  std::cout << "test_complex: " << std::endl;
+  std::cout << "  vec_size: " << vec_size << std::endl;
+  std::cout << "  accelerated: " << (traits::is_accel ? "yes" : "no") << std::endl;
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "ri1.val[" << i << "]: " << ri1.val[i] << std::endl;
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "ri2.val[" << i << "]: " << ri2.val[i] << std::endl;
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "rr.val[" << i << "]: " << rr.val[i] << std::endl;
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "ii.val[" << i << "]: " << ii.val[i] << std::endl;
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "new_ri1.val[" << i << "]: " << new_ri1.val[i] << std::endl;
+  for (index_type i=0; i<vec_size; ++i)
+    std::cout << "new_ri2.val[" << i << "]: " << new_ri2.val[i] << std::endl;
+#endif
+
+  for (index_type i=0; i<vec_size; ++i)
+  {
+    test_assert(rr.val[i] == value_type(2*i));
+    test_assert(ii.val[i] == value_type(3*i)+1);
+  }
+
+  for (index_type i=0; i<vec_size/2; ++i)
+  {
+    test_assert(new_ri1.val[2*i]   == (2*i));
+    test_assert(new_ri1.val[2*i+1] == (3*i+1));
+    test_assert(new_ri2.val[2*i]   == (2*(i+vec_size/2)));
+    test_assert(new_ri2.val[2*i+1] == (3*(i+vec_size/2)+1));
+  }
+}
+
+
+
+template <typename T>
+void
+test_complex(Bool_type<false>)
+{
+}
+
+
+
+template <typename T>
+void
+test_add()
+{
+  typedef vsip::impl::simd::Simd_traits<T> traits;
+
+  typedef typename traits::value_type value_type;
+  typedef typename traits::simd_type  simd_type;
+
+  length_type const vec_size = traits::vec_size;
+
+  union
+  {
+    simd_type  vec;
+    value_type val[vec_size];
+  } u, a, b;
+
+  for (index_type i=0; i<vec_size; ++i)
+  {
+    a.val[i] = T(2*i);
+    b.val[i] = T(3*i);
+  }
+
+  u.vec = traits::add(a.vec, b.vec);
+
+  for (index_type i=1; i<vec_size; ++i)
+    test_assert(u.val[i] == a.val[i] + b.val[i]);
+}
+
+
+
+template <typename T>
+void
+test_mul()
+{
+  typedef vsip::impl::simd::Simd_traits<T> traits;
+
+  typedef typename traits::value_type value_type;
+  typedef typename traits::simd_type  simd_type;
+
+  length_type const vec_size = traits::vec_size;
+
+  union
+  {
+    simd_type  vec;
+    value_type val[vec_size];
+  } u, a, b;
+
+  for (index_type i=0; i<vec_size; ++i)
+  {
+    a.val[i] = T(2*i);
+    b.val[i] = T(3*i);
+  }
+
+  u.vec = traits::mul(a.vec, b.vec);
+
+  for (index_type i=1; i<vec_size; ++i)
+    test_assert(u.val[i] == a.val[i] * b.val[i]);
+}
+
+
+
+template <typename T>
+void
+test_all()
+{
+  using vsip::impl::Type_equal;
+
+  typedef vsip::impl::simd::Simd_traits<T> traits;
+
+  bool const do_complex = traits::is_accel && 
+    (Type_equal<T, float>::value || Type_equal<T, double>::value);
+
+  test_zero<T>();
+  test_load_scalar<T>();
+  test_load_scalar_all<T>();
+  test_add<T>();
+
+  test_interleaved<T>(Bool_type<do_complex>());
+  test_complex<T>(Bool_type<do_complex>());
+}
+
+
+
+template <typename T>
+void
+test_arith()
+{
+  typedef vsip::impl::simd::Simd_traits<T> traits;
+  // test_assert(traits::is_accel);
+  test_add<T>();
+  test_mul<T>();
+}
+
+
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  test_all<signed char>();
+  test_all<short>();
+  test_all<int>();
+  test_all<float>();
+  test_all<double>();
+
+  // test_all<complex<float> >();
+
+  test_arith<float>();
+  test_arith<double>();
+}
Index: tests/scalar_view_div.cpp
===================================================================
--- tests/scalar_view_div.cpp	(revision 166043)
+++ tests/scalar_view_div.cpp	(working copy)
@@ -15,6 +15,8 @@
   Included Files
 ***********************************************************************/
 
+#include <vsip/initfin.hpp>
+
 #include "scalar_view.hpp"
 
 
@@ -24,8 +26,10 @@
 ***********************************************************************/
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
 #if VSIP_IMPL_TEST_LEVEL == 0
   test_lite<op_div>();
 #else
Index: tests/scalar_view_add.cpp
===================================================================
--- tests/scalar_view_add.cpp	(revision 166043)
+++ tests/scalar_view_add.cpp	(working copy)
@@ -15,6 +15,8 @@
   Included Files
 ***********************************************************************/
 
+#include <vsip/initfin.hpp>
+
 #include "scalar_view.hpp"
 
 
@@ -24,8 +26,10 @@
 ***********************************************************************/
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
 #if VSIP_IMPL_TEST_LEVEL == 0
   test_lite<op_add>();
 #else
Index: tests/scalar_view_sub.cpp
===================================================================
--- tests/scalar_view_sub.cpp	(revision 166043)
+++ tests/scalar_view_sub.cpp	(working copy)
@@ -15,6 +15,8 @@
   Included Files
 ***********************************************************************/
 
+#include <vsip/initfin.hpp>
+
 #include "scalar_view.hpp"
 
 
@@ -24,8 +26,10 @@
 ***********************************************************************/
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
 #if VSIP_IMPL_TEST_LEVEL == 0
   test_lite<op_sub>();
 #else
Index: tests/parallel/fftm.cpp
===================================================================
--- tests/parallel/fftm.cpp	(revision 166043)
+++ tests/parallel/fftm.cpp	(working copy)
@@ -33,7 +33,7 @@
 #include <vsip_csl/error_db.hpp>
 #include <vsip_csl/ref_dft.hpp>
 
-#define VERBOSE 0
+#define VERBOSE 1
 
 #if VSIP_IMPL_SAL_FFT
 #  define TEST_NON_REALCOMPLEX 0
@@ -176,16 +176,36 @@
   f_fftm(in, out);
   i_fftm(out, inv);
 
-  test_assert(error_db(ref, out) < -100);
-  test_assert(error_db(inv, in) < -100);
+  double error_ref_out = error_db(ref, out);
+  double error_inv_in  = error_db(inv, in);
 
+#if VERBOSE
+  std::cout << "out-of-place: 5 x " << N 
+	    << "  ref_out: " << error_ref_out
+	    << "  inv_in: " << error_inv_in
+	    << std::endl;
+#endif
+
+  test_assert(error_ref_out < -100);
+  test_assert(error_inv_in  < -100);
+
   out = in;
   f_fftm(out);
   inv = out;
   i_fftm(inv);
 
-  test_assert(error_db(ref, out) < -100);
-  test_assert(error_db(inv, in) < -100);
+  error_ref_out = error_db(ref, out);
+  error_inv_in  = error_db(inv, in);
+
+#if VERBOSE
+  std::cout << "in-place    : 5 x " << N 
+	    << "  ref_out: " << error_ref_out
+	    << "  inv_in: " << error_inv_in
+	    << std::endl;
+#endif
+
+  test_assert(error_ref_out < -100);
+  test_assert(error_inv_in  < -100);
 }
 
 
@@ -312,26 +332,26 @@
   setup_data_y(in);
   ref::dft_y(in, ref, -1);
 
-#if VERBOSE
+#if VERBOSE >= 2
   cout.precision(3);
   cout.setf(ios_base::fixed);
 #endif
 
-#if VERBOSE
+#if VERBOSE >= 2
   dump_matrix(in.block(), N, 1);
   dump_matrix(ref.block(), N, 1);
 #endif
 
   f_fftm(in, out);
 
-#if VERBOSE
+#if VERBOSE >= 2
   dump_matrix(in.block(), N, 1);
   dump_matrix(out.block(), N, 1);
 #endif
 
   i_fftm(out, inv);
 
-#if VERBOSE
+#if VERBOSE >= 2
   dump_matrix(out.block(), N, 1);
   dump_matrix(inv.block(), N, 1);
 #endif
Index: tests/scalar_view_mul.cpp
===================================================================
--- tests/scalar_view_mul.cpp	(revision 166043)
+++ tests/scalar_view_mul.cpp	(working copy)
@@ -15,6 +15,8 @@
   Included Files
 ***********************************************************************/
 
+#include <vsip/initfin.hpp>
+
 #include "scalar_view.hpp"
 
 
@@ -24,8 +26,10 @@
 ***********************************************************************/
 
 int
-main()
+main(int argc, char** argv)
 {
+  vsip::vsipl init(argc, argv);
+
 #if VSIP_IMPL_TEST_LEVEL == 0
   test_lite<op_mul>();
 #else
