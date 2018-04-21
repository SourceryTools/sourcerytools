Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.480
diff -u -r1.480 ChangeLog
--- ChangeLog	14 May 2006 05:50:38 -0000	1.480
+++ ChangeLog	14 May 2006 06:48:31 -0000
@@ -1,3 +1,18 @@
+2006-05-14  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/rt_extdata.hpp: Fix buggy use of uninitialized value
+	  when deallocating storage.
+	* src/vsip/impl/fftw3/fft_impl.cpp (queury_layout): Set
+	  dimension-order to row-major for 2D and 3D cases.  Add checks
+	  for data layout.
+	* src/vsip/impl/ipp/fft.cpp: Throw unimplemented exception for
+	  2D real->complex and complex->real FFTs.
+	* src/vsip/impl/sal/fft.cpp: Fix handling of distributed FFTMs.
+	* src/vsip/impl/sal/fft.hpp (Is_fftm_avail): Type trait to disable
+	  SAL's FFTM evaluator for unsupported types.
+	* tests/fft.cpp: General cleanup.  Refactor implementation ifdefs
+	  into functionality ifdefs.
+	
 2006-05-14  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* src/vsip/impl/fft/dft.hpp: Add 3D support.
Index: src/vsip/impl/rt_extdata.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/rt_extdata.hpp,v
retrieving revision 1.6
diff -u -r1.6 rt_extdata.hpp
--- src/vsip/impl/rt_extdata.hpp	14 May 2006 02:21:04 -0000	1.6
+++ src/vsip/impl/rt_extdata.hpp	14 May 2006 06:48:31 -0000
@@ -332,7 +332,7 @@
   {}
 
   ~Rt_low_level_data_access()
-    { storage_.deallocate(app_layout_.total_size()); }
+    { if (storage_.is_alloc()) storage_.deallocate(app_layout_.total_size()); }
 
   void begin(Block* blk, bool sync)
   {
Index: src/vsip/impl/fftw3/fft_impl.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fftw3/fft_impl.cpp,v
retrieving revision 1.6
diff -u -r1.6 fft_impl.cpp
--- src/vsip/impl/fftw3/fft_impl.cpp	14 May 2006 05:50:39 -0000	1.6
+++ src/vsip/impl/fftw3/fft_impl.cpp	14 May 2006 06:48:31 -0000
@@ -39,6 +39,10 @@
       : in_buffer_(32, dom.size()),
 	out_buffer_(32, dom.size())
   {
+    // For multi-dimensional transforms, these plans assume both
+    // input and output data is dense, row-major, interleave-complex
+    // format.
+
     for (vsip::dimension_type i = 0; i < D; ++i) size_[i] = dom[i].size();
     plan_in_place_ = FFTW(plan_dft)(D, size_,
       reinterpret_cast<FFTW(complex)*>(in_buffer_.get()),
@@ -258,12 +262,18 @@
   {
     rtl_in.pack = stride_unit_dense;
     rtl_in.complex = cmplx_inter_fmt;
+    rtl_in.order = row2_type();
     rtl_out = rtl_in;
   }
   virtual void in_place(ctype *inout,
-			stride_type, stride_type,
-			length_type, length_type)
+			stride_type r_stride,
+			stride_type c_stride,
+			length_type rows, length_type cols)
   {
+    // Check that data is dense row-major.
+    assert(r_stride == static_cast<stride_type>(cols));
+    assert(c_stride == 1);
+
     FFTW(execute_dft)(plan_in_place_,
 		      reinterpret_cast<FFTW(complex)*>(inout),
 		      reinterpret_cast<FFTW(complex)*>(inout));
@@ -275,11 +285,19 @@
   {
   }
   virtual void by_reference(ctype *in,
-			    stride_type, stride_type,
+			    stride_type in_r_stride,
+			    stride_type in_c_stride,
 			    ctype *out,
-			    stride_type, stride_type,
-			    length_type, length_type)
+			    stride_type out_r_stride,
+			    stride_type out_c_stride,
+			    length_type rows, length_type cols)
   {
+    // Check that data is dense row-major.
+    assert(in_r_stride == static_cast<stride_type>(cols));
+    assert(in_c_stride == 1);
+    assert(out_r_stride == static_cast<stride_type>(cols));
+    assert(out_c_stride == 1);
+
     FFTW(execute_dft)(plan_by_reference_,
 		      reinterpret_cast<FFTW(complex)*>(in), 
 		      reinterpret_cast<FFTW(complex)*>(out));
@@ -406,16 +424,26 @@
   {
     rtl_in.pack = stride_unit_dense;
     rtl_in.complex = cmplx_inter_fmt;
+    rtl_in.order = row3_type();
     rtl_out = rtl_in;
   }
   virtual void in_place(ctype *inout,
-			stride_type,
-			stride_type,
-			stride_type,
-			length_type,
-			length_type,
-			length_type)
-  {
+			stride_type x_length,
+			stride_type y_length,
+			stride_type z_length,
+			length_type x_stride,
+			length_type y_stride,
+			length_type z_stride)
+  {
+    assert(static_cast<int>(x_length) == this->size_[0]);
+    assert(static_cast<int>(y_length) == this->size_[1]);
+    assert(static_cast<int>(z_length) == this->size_[2]);
+
+    // Check that data is dense row-major.
+    assert(x_stride == static_cast<stride_type>(y_length*z_length));
+    assert(y_stride == static_cast<stride_type>(z_length));
+    assert(z_stride == 1);
+
     FFTW(execute_dft)(plan_in_place_,
 		      reinterpret_cast<FFTW(complex)*>(inout),
 		      reinterpret_cast<FFTW(complex)*>(inout));
@@ -430,17 +458,29 @@
   {
   }
   virtual void by_reference(ctype *in,
-			    stride_type,
-			    stride_type,
-			    stride_type,
+			    stride_type in_x_stride,
+			    stride_type in_y_stride,
+			    stride_type in_z_stride,
 			    ctype *out,
-			    stride_type,
-			    stride_type,
-			    stride_type,
-			    length_type,
-			    length_type,
-			    length_type)
-  {
+			    stride_type out_x_stride,
+			    stride_type out_y_stride,
+			    stride_type out_z_stride,
+			    length_type x_length,
+			    length_type y_length,
+			    length_type z_length)
+  {
+    assert(static_cast<int>(x_length) == this->size_[0]);
+    assert(static_cast<int>(y_length) == this->size_[1]);
+    assert(static_cast<int>(z_length) == this->size_[2]);
+
+    // Check that data is dense row-major.
+    assert(in_x_stride == static_cast<stride_type>(y_length*z_length));
+    assert(in_y_stride == static_cast<stride_type>(z_length));
+    assert(in_z_stride == 1);
+    assert(out_x_stride == static_cast<stride_type>(y_length*z_length));
+    assert(out_y_stride == static_cast<stride_type>(z_length));
+    assert(out_z_stride == 1);
+
     FFTW(execute_dft)(plan_by_reference_,
 		      reinterpret_cast<FFTW(complex)*>(in), 
 		      reinterpret_cast<FFTW(complex)*>(out));
@@ -537,7 +577,7 @@
   Fft_impl(Domain<3> const &dom, unsigned number)
     : Fft_base<3, ctype, rtype>(dom, A, convert_NoT(number))
   {}
-
+  
   virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
   {
     rtl_in.pack = stride_unit_dense;
Index: src/vsip/impl/ipp/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp/fft.cpp,v
retrieving revision 1.3
diff -u -r1.3 fft.cpp
--- src/vsip/impl/ipp/fft.cpp	14 May 2006 05:50:39 -0000	1.3
+++ src/vsip/impl/ipp/fft.cpp	14 May 2006 06:48:31 -0000
@@ -544,6 +544,7 @@
   impl(Domain<2> const &dom, rtype scale)
     : Driver<2, T, F>(dom)
   {
+    VSIP_IMPL_THROW(unimplemented("IPP FFT backend does not implement 2D real->complex FFT"));
   }
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
@@ -560,6 +561,7 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
+    assert(0);
   }
   virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
@@ -585,6 +587,7 @@
   impl(Domain<2> const &dom, rtype scale)
     : Driver<2, T, F>(dom)
   {
+    VSIP_IMPL_THROW(unimplemented("IPP FFT backend does not implement 2D complex->real FFT"));
   }
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
@@ -601,6 +604,7 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
+    assert(0);
   }
   virtual void by_reference(ztype,
 			    stride_type in_r_stride, stride_type in_c_stride,
Index: src/vsip/impl/sal/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/fft.cpp,v
retrieving revision 1.6
diff -u -r1.6 fft.cpp
--- src/vsip/impl/sal/fft.cpp	13 May 2006 23:19:34 -0000	1.6
+++ src/vsip/impl/sal/fft.cpp	14 May 2006 06:48:31 -0000
@@ -280,17 +280,21 @@
 		&tmp, l2size_[axis], l2size_[1 - axis], dir, ESAL);
   }
   void cipm(std::complex<rtype> *inout, stride_type stride,
+	    length_type n_fft,
 	    dimension_type axis, long dir)
   {
+    assert(n_fft <= size_[1-axis]);
     fftm_cipx(&setup_, reinterpret_cast<ctype *>(inout),
-	      2, 2 * stride, l2size_[axis], size_[1 - axis], dir, ESAL);
+	      2, 2 * stride, l2size_[axis], n_fft, dir, ESAL);
   }
   void zipm(std::pair<rtype*, rtype*> inout, stride_type stride,
+	    length_type n_fft,
 	    dimension_type axis, long dir)
   {
     ztype data = {inout.first, inout.second};
+    assert(n_fft <= size_[1-axis]);
     fftm_zipx(&setup_, &data, 1, stride,
-	      l2size_[axis], size_[1 - axis], dir, ESAL);
+	      l2size_[axis], n_fft, dir, ESAL);
   }
   void ropm(rtype *in, stride_type in_stride,
 	    std::complex<rtype> *out_arg, stride_type out_stride,
@@ -332,23 +336,27 @@
   }
   void copm(std::complex<rtype> *in, stride_type in_stride,
 	    std::complex<rtype> *out, stride_type out_stride,
+	    length_type n_fft,
 	    dimension_type axis, long dir)
   {
+    assert(n_fft <= size_[1-axis]);
     fftm_coptx(&setup_, reinterpret_cast<ctype *>(in), 2, 2 * in_stride,
 	       reinterpret_cast<ctype *>(out), 2, 2 * out_stride,
 	       reinterpret_cast<ctype *>(buffer_),
-	       l2size_[axis], size_[1 - axis], dir, ESAL);
+	       l2size_[axis], n_fft, dir, ESAL);
   }
   void zopm(std::pair<rtype*,rtype*> in_arg, stride_type in_stride,
 	    std::pair<rtype*,rtype*> out_arg, stride_type out_stride,
+	    length_type n_fft,
 	    dimension_type axis, long dir)
   {
     ztype in = {in_arg.first, in_arg.second};
     ztype out = {out_arg.first, out_arg.second};
     ztype tmp = {reinterpret_cast<rtype*>(buffer_),
 		 reinterpret_cast<rtype*>(buffer_) + size_[0] * size_[1]};
+    assert(n_fft <= size_[1-axis]);
     fftm_zoptx(&setup_, &in, 1, in_stride, &out, 1, out_stride, &tmp,
-	       l2size_[axis], size_[1 - axis], dir, ESAL);
+	       l2size_[axis], n_fft, dir, ESAL);
   }
 
   FFT_setup setup_;
@@ -498,17 +506,21 @@
 		 &tmp, l2size_[axis], l2size_[1 - axis], dir, ESAL);
   }
   void cipm(std::complex<rtype> *inout, stride_type stride,
+	    length_type n_fft,
 	    dimension_type axis, long dir)
   {
+    assert(n_fft <= size_[1-axis]);
     fftm_cipdx(&setup_, reinterpret_cast<ctype *>(inout),
-	       2, 2 * stride, l2size_[axis], size_[1 - axis], dir, ESAL);
+	       2, 2 * stride, l2size_[axis], n_fft, dir, ESAL);
   }
   void zipm(std::pair<rtype*, rtype*> inout, stride_type stride,
+	    length_type n_fft,
 	    dimension_type axis, long dir)
   {
     ztype data = {inout.first, inout.second};
+    assert(n_fft <= size_[1-axis]);
     fftm_zipdx(&setup_, &data, 1, stride,
-	       l2size_[axis], size_[1 - axis], dir, ESAL);
+	       l2size_[axis], n_fft, dir, ESAL);
   }
   void ropm(rtype *in, stride_type in_stride,
 	    std::complex<rtype> *out_arg, stride_type out_stride,
@@ -550,23 +562,27 @@
   }
   void copm(std::complex<rtype> *in, stride_type in_stride,
 	    std::complex<rtype> *out, stride_type out_stride,
+	    length_type n_fft,
 	    dimension_type axis, long dir)
   {
+    assert(n_fft <= size_[1-axis]);
     fftm_coptdx(&setup_, reinterpret_cast<ctype *>(in), 2, 2 * in_stride,
 		reinterpret_cast<ctype *>(out), 2, 2 * out_stride,
 		reinterpret_cast<ctype *>(buffer_),
-		l2size_[axis], size_[1 - axis], dir, ESAL);
+		l2size_[axis], n_fft, dir, ESAL);
   }
   void zopm(std::pair<rtype*,rtype*> in_arg, stride_type in_stride,
 	    std::pair<rtype*,rtype*> out_arg, stride_type out_stride,
+	    length_type n_fft,
 	    dimension_type axis, long dir)
   {
     ztype in = {in_arg.first, in_arg.second};
     ztype out = {out_arg.first, out_arg.second};
     ztype tmp = {reinterpret_cast<rtype*>(buffer_),
 		 reinterpret_cast<rtype*>(buffer_) + size_[0] * size_[1]};
+    assert(n_fft <= size_[1-axis]);
     fftm_zoptdx(&setup_, &in, 1, in_stride, &out, 1, out_stride, &tmp,
-		l2size_[axis], size_[1 - axis], dir, ESAL);
+		l2size_[axis], n_fft, dir, ESAL);
   }
 
   FFT_setupd setup_;
@@ -1113,22 +1129,25 @@
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
   {
-    assert(rows == this->size_[0] && cols == this->size_[1]);
-    if (A == 0)
+    if (A != 0)
     {
-      assert(r_stride == 1);
-      cipm(inout, c_stride, A, direction);
+      assert(rows <= this->size_[0]); // OK if rows are distributed.
+      assert(cols == this->size_[1]); // Columns must be whole.
+      assert(c_stride == 1);
+      cipm(inout, r_stride, rows, A, direction);
       if (!almost_equal(this->scale_, T(1.)))
-	for (length_type i = 0; i != cols; ++i)
-	  scale(inout + i * c_stride, rows, this->scale_);
+	for (length_type i = 0; i != rows; ++i)
+	  scale(inout + i * r_stride, cols, this->scale_);
     }
     else
     {
-      assert(c_stride == 1);
-      cipm(inout, r_stride, A, direction);
+      assert(rows == this->size_[0]); // Rows must be whole.
+      assert(cols <= this->size_[1]); // OK if columns are distributed.
+      assert(r_stride == 1);
+      cipm(inout, c_stride, cols, A, direction);
       if (!almost_equal(this->scale_, T(1.)))
-	for (length_type i = 0; i != rows; ++i)
-	  scale(inout + i * r_stride, cols, this->scale_);
+	for (length_type i = 0; i != cols; ++i)
+	  scale(inout + i * c_stride, rows, this->scale_);
     }
   }
 
@@ -1136,27 +1155,30 @@
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
   {
-    assert(rows == this->size_[0] && cols == this->size_[1]);
-    if (A == 0)
+    if (A != 0)
     {
-      assert(r_stride == 1);
-      zipm(inout, c_stride, A, direction);
+      assert(rows <= this->size_[0]); // OK if rows are distributed.
+      assert(cols == this->size_[1]); // Columns must be whole.
+      assert(c_stride == 1);
+      zipm(inout, r_stride, rows, A, direction);
       if (!almost_equal(this->scale_, T(1.)))
-	for (length_type i = 0; i != cols; ++i)
+	for (length_type i = 0; i != rows; ++i)
 	{
-	  scale(inout.first + i * c_stride, rows, this->scale_);
-	  scale(inout.second + i * c_stride, rows, this->scale_);
+	  scale(inout.first + i * r_stride, cols, this->scale_);
+	  scale(inout.second + i * r_stride, cols, this->scale_);
 	}
     }
     else
     {
-      assert(c_stride == 1);
-      zipm(inout, r_stride, A, direction);
+      assert(rows == this->size_[0]); // Rows must be whole.
+      assert(cols <= this->size_[1]); // OK if columns are distributed.
+      assert(r_stride == 1);
+      zipm(inout, c_stride, cols, A, direction);
       if (!almost_equal(this->scale_, T(1.)))
-	for (length_type i = 0; i != rows; ++i)
+	for (length_type i = 0; i != cols; ++i)
 	{
-	  scale(inout.first + i * r_stride, cols, this->scale_);
-	  scale(inout.second + i * r_stride, cols, this->scale_);
+	  scale(inout.first + i * c_stride, rows, this->scale_);
+	  scale(inout.second + i * c_stride, rows, this->scale_);
 	}
     }
   }
@@ -1167,19 +1189,22 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    assert(rows == this->size_[0] && cols == this->size_[1]);
     if (A != 0)
     {
+      assert(rows <= this->size_[0]); // OK if rows are distributed.
+      assert(cols == this->size_[1]); // Columns must be whole.
       assert(in_c_stride == 1 && out_c_stride == 1);
-      copm(in, in_r_stride, out, out_r_stride, 1, direction);
+      copm(in, in_r_stride, out, out_r_stride, rows, 1, direction);
       if (!almost_equal(this->scale_, T(1.)))
 	for (length_type i = 0; i != rows; ++i)
 	  scale(out + i * out_r_stride, cols, this->scale_);
     }
     else
     {
+      assert(rows == this->size_[0]); // Rows must be whole.
+      assert(cols <= this->size_[1]); // OK if columns are distributed.
       assert(in_r_stride == 1 && out_r_stride == 1);
-      copm(in, in_c_stride, out, out_c_stride, 0, direction);
+      copm(in, in_c_stride, out, out_c_stride, cols, 0, direction);
       if (!almost_equal(this->scale_, T(1.)))
 	for (length_type i = 0; i != cols; ++i)
 	  scale(out + i * out_c_stride, rows, this->scale_);
@@ -1191,11 +1216,12 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    assert(rows == this->size_[0] && cols == this->size_[1]);
     if (A != 0)
     {
+      assert(rows <= this->size_[0]); // OK if rows are distributed.
+      assert(cols == this->size_[1]); // Columns must be whole.
       assert(in_c_stride == 1 && out_c_stride == 1);
-      zopm(in, in_r_stride, out, out_r_stride, 1, direction);
+      zopm(in, in_r_stride, out, out_r_stride, rows, 1, direction);
       if (!almost_equal(this->scale_, T(1.)))
 	for (length_type i = 0; i != rows; ++i)
 	{
@@ -1205,8 +1231,10 @@
     }
     else
     {
+      assert(rows == this->size_[0]); // Rows must be whole.
+      assert(cols <= this->size_[1]); // OK if columns are distributed.
       assert(in_r_stride == 1 && out_r_stride == 1);
-      zopm(in, in_c_stride, out, out_c_stride, 0, direction);
+      zopm(in, in_c_stride, out, out_c_stride, cols, 0, direction);
       if (!almost_equal(this->scale_, T(1.)))
 	for (length_type i = 0; i != cols; ++i)
 	{
Index: src/vsip/impl/sal/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/fft.hpp,v
retrieving revision 1.9
diff -u -r1.9 fft.hpp
--- src/vsip/impl/sal/fft.hpp	11 May 2006 19:12:27 -0000	1.9
+++ src/vsip/impl/sal/fft.hpp	14 May 2006 06:48:31 -0000
@@ -157,6 +157,25 @@
 create(Domain<2> const &, double);
 
 
+
+// Traits class to indicate whether SAL FFTM supports a given type for
+// input and output.
+
+template <typename T> struct Is_fftm_avail
+{ static bool const value = false; };
+
+template <> struct Is_fftm_avail<float>
+{ static bool const value = true; };
+
+template <> struct Is_fftm_avail<double>
+{ static bool const value = true; };
+
+template <> struct Is_fftm_avail<complex<float> >
+{ static bool const value = true; };
+
+template <> struct Is_fftm_avail<complex<double> >
+{ static bool const value = true; };
+
 } // namespace vsip::impl::sal
 
 
@@ -251,13 +270,14 @@
 	  unsigned N>
 struct evaluator<I, O, A, E, R, N, fft::Mercury_sal_tag>
 {
-  static bool const ct_valid = true;
+  static bool const ct_valid = sal::Is_fftm_avail<I>::value &&
+                               sal::Is_fftm_avail<O>::value;
   static bool rt_valid(Domain<2> const &dom)
   {
     // SAL can only deal with powers of 2.
     if (dom[A].size() & (dom[A].size() - 1)) return false;
     // SAL requires a minimum block size.
-    if (dom[0].size() < 8 || dom[1].size() < 8) return false;
+    if (dom[A].size() < 8) return false;
     else return true;
   }
   static std::auto_ptr<fft::fftm<I, O, A, E> > 
Index: tests/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft.cpp,v
retrieving revision 1.15
diff -u -r1.15 fft.cpp
--- tests/fft.cpp	7 Mar 2006 02:15:23 -0000	1.15
+++ tests/fft.cpp	14 May 2006 06:48:31 -0000
@@ -19,6 +19,8 @@
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
 
+#include <vsip/impl/metaprogramming.hpp>
+
 #include "test.hpp"
 #include "output.hpp"
 #include "error_db.hpp"
@@ -26,6 +28,26 @@
 
 
 
+#if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_SAL_FFT)
+#  define TEST_2D_CC 1
+#endif
+
+#if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_SAL_FFT)
+#  define TEST_2D_RC 1
+#endif
+
+#if defined(VSIP_IMPL_FFTW3)
+#  define TEST_3D_CC 1
+#endif
+
+#  define TEST_3D_RC 0
+
+#if defined(VSIP_IMPL_FFTW3) || defined(VSIP_IMPL_IPP_FFT)
+#  define TEST_NON_POWER_OF_2 1
+#endif
+
+
+
 /***********************************************************************
   Definitions
 ***********************************************************************/
@@ -220,20 +242,6 @@
 // Comprehensive 2D, 3D test
 //
 
-// Elt: unsigned -> element type
-
-template <typename T, bool realV> struct Elt;
-template <typename T> struct Elt<T,true>
-{
-  typedef T in_type;
-  typedef std::complex<T> out_type;
-};
-template <typename T> struct Elt<T,false>
-{
-  typedef std::complex<T> in_type;
-  typedef std::complex<T> out_type;
-};
-
 template <unsigned Dim, typename T, unsigned L> struct Arg;
 
 template <unsigned Dim, typename T> 
@@ -337,6 +345,7 @@
 }
 
 #if 1
+// In normal testing, fill_random fills a view with random values.
 
 // 2D 
 
@@ -370,7 +379,7 @@
 }
 
 #else
-// debug -- keep this.
+// This variant of fill_random is useful for debugging test failures.
 
 // 2D 
 
@@ -643,11 +652,11 @@
 
 unsigned  sizes[][3] =
 {
-#if !defined(VSIP_IMPL_SAL_FFT)
+#if TEST_NON_POWER_OF_2
   { 2, 2, 2 },
 #endif
   { 8, 8, 8 },
-#if !defined(VSIP_IMPL_SAL_FFT)
+#if TEST_NON_POWER_OF_2
   { 1, 1, 1 },
   { 2, 2, 1 },
   { 2, 4, 8 },
@@ -660,13 +669,19 @@
 
 //   the generic test
 
-template <unsigned inL, unsigned outL, typename F, bool isReal,
-          unsigned Dim, int sD>
+template <unsigned InBlockType,
+	  unsigned OutBlockType,
+	  typename InT,
+	  typename OutT,
+          unsigned Dim,
+	  int      sD>
 void 
 test_fft()
 {
-  typedef typename Elt<F,isReal>::in_type in_elt_type;
-  typedef typename Elt<F,false>::out_type out_elt_type;
+  bool const isReal = !impl::Is_complex<InT>::value;
+
+  typedef InT  in_elt_type;
+  typedef OutT out_elt_type;
 
   static const int sdf = (sD < 0) ? vsip::fft_fwd : sD;
   static const int sdi = (sD < 0) ? vsip::fft_inv : sD;
@@ -679,13 +694,13 @@
   typedef typename Test_fft<Dim,out_elt_type,in_elt_type,
                     sdi,vsip::by_value>::type             inv_by_value_type;
 
-  typedef typename Arg<Dim,in_elt_type,inL>::type    in_type;
-  typedef typename Arg<Dim,out_elt_type,outL>::type  out_type;
+  typedef typename Arg<Dim,in_elt_type,InBlockType>::type    in_type;
+  typedef typename Arg<Dim,out_elt_type,OutBlockType>::type  out_type;
 
   for (unsigned i = 0; i < sizeof(sizes)/sizeof(*sizes); ++i)
   {
     vsip::Rand<in_elt_type> rander(
-      sizes[i][0] * sizes[i][1] * sizes[i][2] * Dim * (sD+5) * (isReal+1));
+      sizes[i][0] * sizes[i][1] * sizes[i][2] * Dim * (sD+5));
 
     Domain<Dim>  in_dom(make_dom<Dim>(sizes[i], false, sD, isReal)); 
     Domain<Dim>  out_dom(make_dom<Dim>(sizes[i], isReal, sD, isReal)); 
@@ -799,262 +814,241 @@
   }
 };
 
-int
-main()
-{
-  vsipl init;
 
-//
-// First check 1D 
-//
-#if defined(VSIP_IMPL_FFT_USE_FLOAT)
 
-  test_complex_by_ref<float, impl::Cmplx_inter_fmt>(2, 64);
-  test_complex_by_ref<float, impl::Cmplx_split_fmt>(2, 64);
-#if !defined(VSIP_IMPL_SAL_FFT)
-  test_complex_by_ref<float, impl::Cmplx_inter_fmt>(1, 68);
-  test_complex_by_ref<float, impl::Cmplx_split_fmt>(1, 68);
-#endif
-  test_complex_by_ref<float, impl::Cmplx_inter_fmt>(2, 256);
-  test_complex_by_ref<float, impl::Cmplx_split_fmt>(2, 256);
-#if !defined(VSIP_IMPL_SAL_FFT)
-  test_complex_by_ref<float, impl::Cmplx_inter_fmt>(2, 252);
-  test_complex_by_ref<float, impl::Cmplx_split_fmt>(2, 252);
-  test_complex_by_ref<float, impl::Cmplx_inter_fmt>(3, 17);
-  test_complex_by_ref<float, impl::Cmplx_split_fmt>(3, 17);
-#endif
-
-  test_complex_by_val<float, impl::Cmplx_inter_fmt>(1, 128);
-  test_complex_by_val<float, impl::Cmplx_split_fmt>(1, 128);
-  test_complex_by_val<float, impl::Cmplx_inter_fmt>(2, 256);
-  test_complex_by_val<float, impl::Cmplx_split_fmt>(2, 256);
-  test_complex_by_val<float, impl::Cmplx_inter_fmt>(3, 512);
-  test_complex_by_val<float, impl::Cmplx_split_fmt>(3, 512);
-
-  test_real<float>(1, 128);
-#if !defined(VSIP_IMPL_SAL_FFT)
-  test_real<float>(2, 242);
-#endif
-  test_real<float>(3, 16);
+// Check 1D 
 
-#endif 
+template <typename T>
+void
+test_1d()
+{
+  test_complex_by_ref<T, impl::Cmplx_inter_fmt>(2, 64);
+  test_complex_by_ref<T, impl::Cmplx_split_fmt>(2, 64);
 
-#if defined(VSIP_IMPL_FFT_USE_DOUBLE)
+  test_complex_by_ref<T, impl::Cmplx_inter_fmt>(2, 256);
+  test_complex_by_ref<T, impl::Cmplx_split_fmt>(2, 256);
 
-  test_complex_by_ref<double, impl::Cmplx_inter_fmt>(2, 64);
-  test_complex_by_ref<double, impl::Cmplx_split_fmt>(2, 64);
-#if !defined(VSIP_IMPL_SAL_FFT)
-  test_complex_by_ref<double, impl::Cmplx_inter_fmt>(1, 68);
-  test_complex_by_ref<double, impl::Cmplx_split_fmt>(1, 68);
-#endif
-  test_complex_by_ref<double, impl::Cmplx_inter_fmt>(2, 256);
-  test_complex_by_ref<double, impl::Cmplx_split_fmt>(2, 256);
-#if !defined(VSIP_IMPL_SAL_FFT)
-  test_complex_by_ref<double, impl::Cmplx_inter_fmt>(2, 252);
-  test_complex_by_ref<double, impl::Cmplx_split_fmt>(2, 252);
-  test_complex_by_ref<double, impl::Cmplx_inter_fmt>(3, 17);
-  test_complex_by_ref<double, impl::Cmplx_split_fmt>(3, 17);
-#endif
-
-  test_complex_by_val<double, impl::Cmplx_inter_fmt>(1, 128);
-  test_complex_by_val<double, impl::Cmplx_split_fmt>(1, 128);
-  test_complex_by_val<double, impl::Cmplx_inter_fmt>(2, 256);
-  test_complex_by_val<double, impl::Cmplx_split_fmt>(2, 256);
-  test_complex_by_val<double, impl::Cmplx_inter_fmt>(3, 512);
-  test_complex_by_val<double, impl::Cmplx_split_fmt>(3, 512);
-
-  test_real<double>(1, 128);
-#if !defined(VSIP_IMPL_SAL_FFT)
-  test_real<double>(2, 242);
+  test_complex_by_val<T, impl::Cmplx_inter_fmt>(1, 128);
+  test_complex_by_val<T, impl::Cmplx_split_fmt>(1, 128);
+  test_complex_by_val<T, impl::Cmplx_inter_fmt>(2, 256);
+  test_complex_by_val<T, impl::Cmplx_split_fmt>(2, 256);
+  test_complex_by_val<T, impl::Cmplx_inter_fmt>(3, 512);
+  test_complex_by_val<T, impl::Cmplx_split_fmt>(3, 512);
+
+  test_real<T>(1, 128);
+  test_real<T>(3, 16);
+
+#if TEST_NON_POWER_OF_2
+  test_complex_by_ref<T, impl::Cmplx_inter_fmt>(1, 68);
+  test_complex_by_ref<T, impl::Cmplx_split_fmt>(1, 68);
+  test_complex_by_ref<T, impl::Cmplx_inter_fmt>(2, 252);
+  test_complex_by_ref<T, impl::Cmplx_split_fmt>(2, 252);
+  test_complex_by_ref<T, impl::Cmplx_inter_fmt>(3, 17);
+  test_complex_by_ref<T, impl::Cmplx_split_fmt>(3, 17);
+  test_real<T>(2, 242);
 #endif
-  test_real<double>(3, 16);
+}
 
-#endif 
 
-#if defined(VSIP_IMPL_FFT_USE_LONG_DOUBLE)
 
-#if ! defined(VSIP_IMPL_IPP_FFT)
-#if !defined(VSIP_IMPL_SAL_FFT)
-  test_complex_by_ref<long double, impl::Cmplx_inter_fmt>(2, 64);
-  test_complex_by_ref<long double, impl::Cmplx_split_fmt>(2, 64);
-#endif 
-  test_complex_by_ref<long double, impl::Cmplx_inter_fmt>(1, 68);
-  test_complex_by_ref<long double, impl::Cmplx_split_fmt>(1, 68);
-  test_complex_by_ref<long double, impl::Cmplx_inter_fmt>(2, 256);
-  test_complex_by_ref<long double, impl::Cmplx_split_fmt>(2, 256);
-#if !defined(VSIP_IMPL_SAL_FFT)
-  test_complex_by_ref<long double, impl::Cmplx_inter_fmt>(2, 252);
-  test_complex_by_ref<long double, impl::Cmplx_split_fmt>(2, 252);
-  test_complex_by_ref<long double, impl::Cmplx_inter_fmt>(3, 17);
-  test_complex_by_ref<long double, impl::Cmplx_split_fmt>(3, 17);
-#endif 
+// check 2D, 3D
 
-  test_complex_by_val<long double, impl::Cmplx_inter_fmt>(1, 128);
-  test_complex_by_val<long double, impl::Cmplx_split_fmt>(1, 128);
-  test_complex_by_val<long double, impl::Cmplx_inter_fmt>(2, 256);
-  test_complex_by_val<long double, impl::Cmplx_split_fmt>(2, 256);
-  test_complex_by_val<long double, impl::Cmplx_inter_fmt>(3, 512);
-  test_complex_by_val<long double, impl::Cmplx_split_fmt>(3, 512);
-
-  test_real<long double>(1, 128);
-#if !defined(VSIP_IMPL_SAL_FFT)
-  test_real<long double>(2, 242);
-#endif 
-  test_real<long double>(3, 16);
+template <typename T>
+void
+test_nd()
+{
+#if TEST_2D_CC
+  test_fft<0,0,complex<T>, complex<T> ,2,vsip::fft_fwd>();
 #endif
 
-#endif 
+#if TEST_2D_RC
+  test_fft<0,0,float,complex<float>,2,1>();
+  test_fft<0,0,float,complex<float>,2,0>();
+#endif
 
+#if TEST_3D_CC
+  test_fft<0,0,complex<T>,complex<T>,3,vsip::fft_fwd>();
+#endif
 
+#if TEST_3D_RC
+  test_fft<0,0,T,complex<T>,3,2>();
+  test_fft<0,0,T,complex<T>,3,1>();
+  test_fft<0,0,T,complex<T>,3,0>();
+#endif
+}
 
-//
-// check 2D, 3D
-//
 
-#if VSIP_IMPL_TEST_LEVEL > 0
 
-#if defined(VSIP_IMPL_FFT_USE_FLOAT)
+// Check with different block types.
 
-  test_fft<0,0,float,false,2,vsip::fft_fwd>();
+template <typename T>
+void
+test_block_type()
+{
+#if TEST_2D_CC
+  test_fft<0,1,complex<T>,complex<T>,2,vsip::fft_fwd>();
+  test_fft<1,0,complex<T>,complex<T>,2,vsip::fft_fwd>();
+
+#  if VSIP_IMPL_TEST_LEVEL > 0
+  test_fft<0,2,complex<T>,complex<T>,2,vsip::fft_fwd>();
+  test_fft<1,1,complex<T>,complex<T>,2,vsip::fft_fwd>();
+  test_fft<1,2,complex<T>,complex<T>,2,vsip::fft_fwd>();
+  test_fft<2,0,complex<T>,complex<T>,2,vsip::fft_fwd>();
+  test_fft<2,1,complex<T>,complex<T>,2,vsip::fft_fwd>();
+  test_fft<2,2,complex<T>,complex<T>,2,vsip::fft_fwd>();
+#  endif
+#endif
+
+#if TEST_2D_RC
+  test_fft<0,1,T,complex<T>,2,1>();
+  test_fft<0,1,T,complex<T>,2,0>();
+  test_fft<1,0,T,complex<T>,2,1>();
+  test_fft<1,0,T,complex<T>,2,0>();
+
+#  if VSIP_IMPL_TEST_LEVEL > 0
+  test_fft<0,2,T,complex<T>,2,1>();
+  test_fft<0,2,T,complex<T>,2,0>();
+
+  test_fft<1,1,T,complex<T>,2,1>();
+  test_fft<1,1,T,complex<T>,2,0>();
+  test_fft<1,2,T,complex<T>,2,1>();
+  test_fft<1,2,T,complex<T>,2,0>();
+
+  test_fft<2,0,T,complex<T>,2,1>();
+  test_fft<2,0,T,complex<T>,2,0>();
+  test_fft<2,1,T,complex<T>,2,1>();
+  test_fft<2,1,T,complex<T>,2,0>();
+  test_fft<2,2,T,complex<T>,2,1>();
+  test_fft<2,2,T,complex<T>,2,0>();
+#  endif
+#endif
+
+#if TEST_3D_CC
+  test_fft<0,1,complex<T>,complex<T>,3,vsip::fft_fwd>();
+  test_fft<1,0,complex<T>,complex<T>,3,vsip::fft_fwd>();
+
+#  if VSIP_IMPL_TEST_LEVEL > 0
+  test_fft<0,2,complex<T>,complex<T>,3,vsip::fft_fwd>();
+  test_fft<1,1,complex<T>,complex<T>,3,vsip::fft_fwd>();
+  test_fft<1,2,complex<T>,complex<T>,3,vsip::fft_fwd>();
+  test_fft<2,0,complex<T>,complex<T>,3,vsip::fft_fwd>();
+  test_fft<2,1,complex<T>,complex<T>,3,vsip::fft_fwd>();
+  test_fft<2,2,complex<T>,complex<T>,3,vsip::fft_fwd>();
+#  endif
+#endif
+
+#if TEST_3D_RC
+  test_fft<0,1,T,complex<T>,3,2>();
+  test_fft<0,1,T,complex<T>,3,1>();
+  test_fft<0,1,T,complex<T>,3,0>();
+  test_fft<1,0,T,complex<T>,3,2>();
+  test_fft<1,0,T,complex<T>,3,1>();
+  test_fft<1,0,T,complex<T>,3,0>();
+
+#  if VSIP_IMPL_TEST_LEVEL > 0
+  test_fft<0,2,T,complex<T>,3,2>();
+  test_fft<0,2,T,complex<T>,3,1>();
+  test_fft<0,2,T,complex<T>,3,0>();
+
+  test_fft<1,1,T,complex<T>,3,2>();
+  test_fft<1,1,T,complex<T>,3,1>();
+  test_fft<1,1,T,complex<T>,3,0>();
+  test_fft<1,2,T,complex<T>,3,2>();
+  test_fft<1,2,T,complex<T>,3,1>();
+  test_fft<1,2,T,complex<T>,3,0>();
+
+  test_fft<2,0,T,complex<T>,3,2>();
+  test_fft<2,0,T,complex<T>,3,1>();
+  test_fft<2,0,T,complex<T>,3,0>();
+  test_fft<2,1,T,complex<T>,3,2>();
+  test_fft<2,1,T,complex<T>,3,1>();
+  test_fft<2,1,T,complex<T>,3,0>();
+  test_fft<2,2,T,complex<T>,3,2>();
+  test_fft<2,2,T,complex<T>,3,1>();
+  test_fft<2,2,T,complex<T>,3,0>();
+#  endif
+#endif
+}
+
+
+void
+show_config()
+{
+  cout << "backends:" << endl;
 
-#if ! defined(VSIP_IMPL_IPP_FFT)
-#if ! defined(VSIP_IMPL_SAL_FFT)
-  test_fft<0,0,float,false,3,vsip::fft_fwd>();
+#if defined(VSIP_IMPL_FFTW3)
+  cout << " - fftw3:" << endl;
+#endif
+#if defined(VSIP_IMPL_IPP_FFT)
+  cout << " - ipp" << endl;
 #endif
-  test_fft<0,0,float,true,2,1>();
-  test_fft<0,0,float,true,2,0>();
+#if defined(VSIP_IMPL_SAL_FFT)
+  cout << " - sal" << endl;
+#endif
+
 
-#if ! defined(VSIP_IMPL_SAL_FFT)
-  test_fft<0,0,float,true,3,2>();
-  test_fft<0,0,float,true,3,1>();
-  test_fft<0,0,float,true,3,0>();
+#if TEST_2D_CC
+  cout << "test 2D CC" << endl;
+#endif
+#if TEST_2D_RC
+  cout << "test 2D RC" << endl;
 #endif
-#endif   /* VSIP_IMPL_IPP_FFT */
+#if TEST_3D_CC
+  cout << "test 2D CC" << endl;
+#endif
+#if TEST_3D_RC
+  cout << "test 2D RC" << endl;
+#endif
+}
 
-#endif 
 
-#if defined(VSIP_IMPL_FFT_USE_DOUBLE)
 
-#if ! defined(VSIP_IMPL_IPP_FFT)
-  test_fft<0,0,double,false,2,vsip::fft_fwd>();
-#if ! defined(VSIP_IMPL_SAL_FFT)
-  test_fft<0,0,double,false,3,vsip::fft_fwd>();
-#endif
-  test_fft<0,0,double,true,2,1>();
-  test_fft<0,0,double,true,2,0>();
-
-#if ! defined(VSIP_IMPL_SAL_FFT)
-  test_fft<0,0,double,true,3,2>();
-  test_fft<0,0,double,true,3,1>();
-  test_fft<0,0,double,true,3,0>();
-#endif
-#endif  /* VSIP_IMPL_IPP_FFT */
+int
+main()
+{
+  vsipl init;
 
-#endif
+  // show_config();
 
-#if defined(VSIP_IMPL_FFT_USE_LONG_DOUBLE)
+//
+// First check 1D 
+//
+#if defined(VSIP_IMPL_FFT_USE_FLOAT)
+  test_1d<float>();
+#endif 
 
-#if ! defined(VSIP_IMPL_IPP_FFT)
-  test_fft<0,0,double,false,2,vsip::fft_fwd>();
-#if ! defined(VSIP_IMPL_SAL_FFT)
-  test_fft<0,0,double,false,3,vsip::fft_fwd>();
-#endif
-  test_fft<0,0,double,true,2,1>();
-  test_fft<0,0,double,true,2,0>();
-
-#if ! defined(VSIP_IMPL_SAL_FFT)
-  test_fft<0,0,double,true,3,2>();
-  test_fft<0,0,double,true,3,1>();
-  test_fft<0,0,double,true,3,0>();
-#endif
-#endif  /* VSIP_IMPL_IPP_FFT */
+#if defined(VSIP_IMPL_FFT_USE_DOUBLE)
+  test_1d<double>();
+#endif 
 
+#if defined(VSIP_IMPL_FFT_USE_LONG_DOUBLE)
+  test_1d<long double>();
 #endif
 
+
 //
-// check with different block types
+// check 2D, 3D
 //
 
+#if VSIP_IMPL_TEST_LEVEL > 0
+
 #if defined(VSIP_IMPL_FFT_USE_FLOAT)
-# define SCALAR float
-#elif defined(VSIP_IMPL_FFT_USE_DOUBLE)
-# define SCALAR double
-#elif defined(VSIP_IMPL_FFT_USE_LONG_DOUBLE)
-# define SCALAR long double
-#endif
-
-#if defined(SCALAR)
-
-  test_fft<0,1,SCALAR,false,2,vsip::fft_fwd>();
-  test_fft<0,2,SCALAR,false,2,vsip::fft_fwd>();
-  test_fft<1,0,SCALAR,false,2,vsip::fft_fwd>();
-  test_fft<1,1,SCALAR,false,2,vsip::fft_fwd>();
-  test_fft<1,2,SCALAR,false,2,vsip::fft_fwd>();
-  test_fft<2,0,SCALAR,false,2,vsip::fft_fwd>();
-  test_fft<2,1,SCALAR,false,2,vsip::fft_fwd>();
-  test_fft<2,2,SCALAR,false,2,vsip::fft_fwd>();
-
-#if ! defined(VSIP_IMPL_IPP_FFT)
-  test_fft<0,1,SCALAR,true,2,1>();
-  test_fft<0,1,SCALAR,true,2,0>();
-  test_fft<0,2,SCALAR,true,2,1>();
-  test_fft<0,2,SCALAR,true,2,0>();
-
-  test_fft<1,0,SCALAR,true,2,1>();
-  test_fft<1,0,SCALAR,true,2,0>();
-  test_fft<1,1,SCALAR,true,2,1>();
-  test_fft<1,1,SCALAR,true,2,0>();
-  test_fft<1,2,SCALAR,true,2,1>();
-  test_fft<1,2,SCALAR,true,2,0>();
-
-  test_fft<2,0,SCALAR,true,2,1>();
-  test_fft<2,0,SCALAR,true,2,0>();
-  test_fft<2,1,SCALAR,true,2,1>();
-  test_fft<2,1,SCALAR,true,2,0>();
-  test_fft<2,2,SCALAR,true,2,1>();
-  test_fft<2,2,SCALAR,true,2,0>();
-
-#if ! defined(VSIP_IMPL_SAL_FFT)
-  test_fft<0,1,SCALAR,false,3,vsip::fft_fwd>();
-  test_fft<0,2,SCALAR,false,3,vsip::fft_fwd>();
-  test_fft<1,0,SCALAR,false,3,vsip::fft_fwd>();
-  test_fft<1,1,SCALAR,false,3,vsip::fft_fwd>();
-  test_fft<1,2,SCALAR,false,3,vsip::fft_fwd>();
-  test_fft<2,0,SCALAR,false,3,vsip::fft_fwd>();
-  test_fft<2,1,SCALAR,false,3,vsip::fft_fwd>();
-  test_fft<2,2,SCALAR,false,3,vsip::fft_fwd>();
-
-  test_fft<0,1,SCALAR,true,3,2>();
-  test_fft<0,1,SCALAR,true,3,1>();
-  test_fft<0,1,SCALAR,true,3,0>();
-  test_fft<0,2,SCALAR,true,3,2>();
-  test_fft<0,2,SCALAR,true,3,1>();
-  test_fft<0,2,SCALAR,true,3,0>();
-
-  test_fft<1,0,SCALAR,true,3,2>();
-  test_fft<1,0,SCALAR,true,3,1>();
-  test_fft<1,0,SCALAR,true,3,0>();
-  test_fft<1,1,SCALAR,true,3,2>();
-  test_fft<1,1,SCALAR,true,3,1>();
-  test_fft<1,1,SCALAR,true,3,0>();
-  test_fft<1,2,SCALAR,true,3,2>();
-  test_fft<1,2,SCALAR,true,3,1>();
-  test_fft<1,2,SCALAR,true,3,0>();
-
-  test_fft<2,0,SCALAR,true,3,2>();
-  test_fft<2,0,SCALAR,true,3,1>();
-  test_fft<2,0,SCALAR,true,3,0>();
-  test_fft<2,1,SCALAR,true,3,2>();
-  test_fft<2,1,SCALAR,true,3,1>();
-  test_fft<2,1,SCALAR,true,3,0>();
-  test_fft<2,2,SCALAR,true,3,2>();
-  test_fft<2,2,SCALAR,true,3,1>();
-  test_fft<2,2,SCALAR,true,3,0>();
+  test_nd<float>();
+#endif 
+
+#if defined(VSIP_IMPL_FFT_USE_DOUBLE)
+  test_nd<double>();
 #endif
-#endif  /* VSIP_IMPL_IPP_FFT */
 
+#if defined(VSIP_IMPL_FFT_USE_LONG_DOUBLE)
+  test_nd<long double>();
 #endif
 
+//
+// check with different block types
+//
+  test_block_type<float>();
+
 #endif // VSIP_IMPL_TEST_LEVEL > 0
   return 0;
 }
