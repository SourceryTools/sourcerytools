Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.479
diff -u -r1.479 ChangeLog
--- ChangeLog	14 May 2006 02:21:04 -0000	1.479
+++ ChangeLog	14 May 2006 05:46:57 -0000
@@ -1,3 +1,12 @@
+2006-05-14  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* src/vsip/impl/fft/dft.hpp: Add 3D support.
+	* src/vsip/impl/fftw3/fft_impl.cpp: Complete 3D support.
+	* tests/fft_be.cpp: Add 3D tests.
+	* src/vsip/impl/ipp/fft.cpp: Remove debug output.
+	* src/vsip/impl/fft/no_fft.cpp: Remove debug output.
+	
+
 2006-05-13  Jules Bergmann  <jules@codesourcery.com>
 
 	* configure.ac: Check if long double is supported before attempting
Index: src/vsip/impl/fft/dft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/dft.hpp,v
retrieving revision 1.3
diff -u -r1.3 dft.hpp
--- src/vsip/impl/fft/dft.hpp	10 May 2006 14:08:53 -0000	1.3
+++ src/vsip/impl/fft/dft.hpp	14 May 2006 05:46:58 -0000
@@ -57,8 +57,8 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<1> &rtl_inout) {}
-  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out) {}
+  virtual void query_layout(Rt_layout<1> &) {}
+  virtual void query_layout(Rt_layout<1> &, Rt_layout<1> &) {}
   virtual void in_place(ctype *inout, stride_type s, length_type l)
   {
     aligned_array<std::complex<T> > tmp(l);
@@ -134,7 +134,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out) {}
+  virtual void query_layout(Rt_layout<1> &, Rt_layout<1> &) {}
   virtual void by_reference(rtype *in, stride_type in_s,
 			    ctype *out, stride_type out_s,
 			    length_type l)
@@ -176,7 +176,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out) {}
+  virtual void query_layout(Rt_layout<1> &, Rt_layout<1> &) {}
   virtual void by_reference(ctype *in, stride_type in_s,
 			    rtype *out, stride_type out_s,
 			    length_type l)
@@ -224,8 +224,8 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<2> &rtl_inout) {}
-  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out) {}
+  virtual void query_layout(Rt_layout<2> &) {}
+  virtual void query_layout(Rt_layout<2> &, Rt_layout<2> &) {}
   virtual void in_place(ctype *inout,
 			stride_type r_stride, stride_type c_stride,
 			length_type rows, length_type cols)
@@ -302,7 +302,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out) {}
+  virtual void query_layout(Rt_layout<2> &, Rt_layout<2> &) {}
   virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    ctype *out,
@@ -382,7 +382,7 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out) {}
+  virtual void query_layout(Rt_layout<2> &, Rt_layout<2> &) {}
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    rtype *out,
@@ -477,8 +477,8 @@
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  virtual void query_layout(Rt_layout<3> &rtl_inout) {}
-  virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out) {}
+  virtual void query_layout(Rt_layout<3> &) {}
+  virtual void query_layout(Rt_layout<3> &, Rt_layout<3> &) {}
   virtual void in_place(ctype *inout,
 			stride_type x_stride,
 			stride_type y_stride,
@@ -487,6 +487,15 @@
 			length_type y_length,
 			length_type z_length)
   {
+    dft<2, ctype, ctype, 0, E> dft_2d;
+    dft<1, ctype, ctype, 0, E> dft_1d;
+    for (index_type x = 0; x != x_length; ++x)
+      dft_2d.in_place(inout + x * x_stride,
+		      y_stride, z_stride, y_length, z_length);
+    for (index_type y = 0; y != y_length; ++y)
+      for (index_type z = 0; z != z_length; ++z)
+	dft_1d.in_place(inout + y * y_stride + z * z_stride,
+			x_stride, x_length);
   }
   virtual void in_place(ztype inout,
 			stride_type x_stride,
@@ -496,6 +505,15 @@
 			length_type y_length,
 			length_type z_length)
   {
+    dft<2, ctype, ctype, 0, E> dft_2d;
+    dft<1, ctype, ctype, 0, E> dft_1d;
+    for (index_type x = 0; x != x_length; ++x)
+      dft_2d.in_place(offset(inout, x * x_stride),
+		      y_stride, z_stride, y_length, z_length);
+    for (index_type y = 0; y != y_length; ++y)
+      for (index_type z = 0; z != z_length; ++z)
+	dft_1d.in_place(offset(inout, y * y_stride + z * z_stride),
+			x_stride, x_length);
   }
   virtual void by_reference(ctype *in,
 			    stride_type in_x_stride,
@@ -509,6 +527,18 @@
 			    length_type y_length,
 			    length_type z_length)
   {
+    dft<2, ctype, ctype, 0, E> dft_2d;
+    dft<1, ctype, ctype, 0, E> dft_1d;
+    for (index_type x = 0; x != x_length; ++x)
+      dft_2d.by_reference(in + x * in_x_stride,
+			  in_y_stride, in_z_stride,
+			  out + x * out_x_stride,
+			  out_y_stride, out_z_stride,
+			  y_length, z_length);
+    for (index_type y = 0; y != y_length; ++y)
+      for (index_type z = 0; z != z_length; ++z)
+	dft_1d.in_place(out + y * out_y_stride + z * out_z_stride,
+			out_x_stride, x_length);
   }
   virtual void by_reference(ztype in,
 			    stride_type in_x_stride,
@@ -522,6 +552,18 @@
 			    length_type y_length,
 			    length_type z_length)
   {
+    dft<2, ctype, ctype, 0, E> dft_2d;
+    dft<1, ctype, ctype, 0, E> dft_1d;
+    for (index_type x = 0; x != x_length; ++x)
+      dft_2d.by_reference(offset(in, x * in_x_stride),
+			  in_y_stride, in_z_stride,
+			  offset(out, x * out_x_stride),
+			  out_y_stride, out_z_stride,
+			  y_length, z_length);
+    for (index_type y = 0; y != y_length; ++y)
+      for (index_type z = 0; z != z_length; ++z)
+	dft_1d.in_place(offset(out, y * out_y_stride + z * out_z_stride),
+			out_x_stride, x_length);
   }
 };
 
@@ -548,6 +590,47 @@
 			    length_type y_length,
 			    length_type z_length)
   {
+    dft<1, rtype, ctype, 0, -1> rdft_1d;
+    dft<2, ctype, ctype, 0, -1> dft_2d;
+    if (A == 0)
+    {
+      for (length_type y = 0; y != y_length; ++y)
+	for (length_type z = 0; z != z_length; ++z)
+	  rdft_1d.by_reference(in + y * in_y_stride + z * in_z_stride,
+			       in_x_stride,
+			       out + y * out_y_stride + z * out_z_stride,
+			       out_x_stride, x_length);
+      for (length_type x = 0; x != x_length/2 + 1; ++x)
+	dft_2d.in_place(out + x * out_x_stride,
+			out_y_stride, out_z_stride,
+			y_length, z_length);
+    }
+    else if (A == 1)
+    {
+      for (length_type x = 0; x != x_length; ++x)
+	for (length_type z = 0; z != z_length; ++z)
+	  rdft_1d.by_reference(in + x * in_x_stride + z * in_z_stride,
+			       in_y_stride,
+			       out + x * out_x_stride + z * out_z_stride,
+			       out_y_stride, y_length);
+      for (length_type y = 0; y != y_length/2 + 1; ++y)
+	dft_2d.in_place(out + y * out_y_stride,
+			out_x_stride, out_z_stride,
+			x_length, z_length);
+    }
+    else
+    {
+      for (length_type x = 0; x != x_length; ++x)
+	for (length_type y = 0; y != y_length; ++y)
+	  rdft_1d.by_reference(in + x * in_x_stride + y * in_y_stride,
+			       in_z_stride,
+			       out + x * out_x_stride + y * out_y_stride,
+			       out_z_stride, z_length);
+      for (length_type z = 0; z != z_length/2 + 1; ++z)
+	dft_2d.in_place(out + z * out_z_stride,
+			out_x_stride, out_y_stride,
+			x_length, y_length);
+    }
   }
   virtual void by_reference(rtype *in,
 			    stride_type in_x_stride,
@@ -555,12 +638,53 @@
 			    stride_type in_z_stride,
 			    ztype out,
 			    stride_type out_x_stride,
-			    stride_type out_y_stridey,
+			    stride_type out_y_stride,
 			    stride_type out_z_stride,
 			    length_type x_length,
 			    length_type y_length,
 			    length_type z_length)
   {
+    dft<1, rtype, ctype, 0, -1> rdft_1d;
+    dft<2, ctype, ctype, 0, -1> dft_2d;
+    if (A == 0)
+    {
+      for (length_type y = 0; y != y_length; ++y)
+	for (length_type z = 0; z != z_length; ++z)
+	  rdft_1d.by_reference(in + y * in_y_stride + z * in_z_stride,
+			       in_x_stride,
+			       offset(out, y * out_y_stride + z * out_z_stride),
+			       out_x_stride, x_length);
+      for (length_type x = 0; x != x_length/2 + 1; ++x)
+	dft_2d.in_place(offset(out, x * out_x_stride),
+			out_y_stride, out_z_stride,
+			y_length, z_length);
+    }
+    else if (A == 1)
+    {
+      for (length_type x = 0; x != x_length; ++x)
+	for (length_type z = 0; z != z_length; ++z)
+	  rdft_1d.by_reference(in + x * in_x_stride + z * in_z_stride,
+			       in_y_stride,
+			       offset(out, x * out_x_stride + z * out_z_stride),
+			       out_y_stride, y_length);
+      for (length_type y = 0; y != y_length/2 + 1; ++y)
+	dft_2d.in_place(offset(out, y * out_y_stride),
+			out_x_stride, out_z_stride,
+			x_length, z_length);
+    }
+    else
+    {
+      for (length_type x = 0; x != x_length; ++x)
+	for (length_type y = 0; y != y_length; ++y)
+	  rdft_1d.by_reference(in + x * in_x_stride + y * in_y_stride,
+			       in_z_stride,
+			       offset(out, x * out_x_stride + y * out_y_stride),
+			       out_z_stride, z_length);
+      for (length_type z = 0; z != z_length/2 + 1; ++z)
+	dft_2d.in_place(offset(out, z * out_z_stride),
+			out_x_stride, out_y_stride,
+			x_length, y_length);
+    }
   }
 
 };
@@ -588,6 +712,59 @@
 			    length_type y_length,
 			    length_type z_length)
   {
+    dft<2, ctype, ctype, 0, 1> dft_2d;
+    dft<1, ctype, rtype, 0, 1> rdft_1d;
+    if (A == 0)
+    {
+      length_type x2 = x_length/2 + 1;
+      aligned_array<ctype> tmp(x2 * y_length * z_length);
+      for (length_type x = 0; x != x2; ++x)
+	dft_2d.by_reference(in + x * in_x_stride,
+			    in_y_stride, in_z_stride,
+			    tmp.get() + x * y_length * z_length,
+			    1, y_length,
+			    y_length, z_length);
+      for (length_type y = 0; y != y_length; ++y)
+	for (length_type z = 0; z != z_length; ++z)
+	  rdft_1d.by_reference(tmp.get() + y + z * y_length,
+			       y_length * z_length,
+			       out + y * out_y_stride + z * out_z_stride,
+			       out_x_stride, x_length);
+    }
+    else if (A == 1)
+    {
+      length_type y2 = y_length/2 + 1;
+      aligned_array<ctype> tmp(y2 * x_length * z_length);
+      for (length_type y = 0; y != y2; ++y)
+	dft_2d.by_reference(in + y * in_y_stride,
+			    in_x_stride, in_z_stride,
+			    tmp.get() + y * x_length * z_length,
+			    1, x_length,
+			    x_length, z_length);
+      for (length_type x = 0; x != x_length; ++x)
+	for (length_type z = 0; z != z_length; ++z)
+	  rdft_1d.by_reference(tmp.get() + x + z * x_length,
+			       x_length * z_length,
+			       out + x * out_x_stride + z * out_z_stride,
+			       out_y_stride, y_length);
+    }
+    else
+    {
+      length_type z2 = z_length/2 + 1;
+      aligned_array<ctype> tmp(z2 * y_length * x_length);
+      for (length_type z = 0; z != z2; ++z)
+	dft_2d.by_reference(in + z * in_z_stride,
+			    in_y_stride, in_x_stride,
+			    tmp.get() + z * y_length * x_length,
+			    1, y_length,
+			    y_length, x_length);
+      for (length_type y = 0; y != y_length; ++y)
+	for (length_type x = 0; x != x_length; ++x)
+	  rdft_1d.by_reference(tmp.get() + y + x * y_length,
+			       y_length * x_length,
+			       out + y * out_y_stride + x * out_x_stride,
+			       out_z_stride, z_length);
+    }
   }
   virtual void by_reference(ztype in,
 			    stride_type in_x_stride,
@@ -601,6 +778,86 @@
 			    length_type y_length,
 			    length_type z_length)
   {
+    dft<2, ctype, ctype, 0, 1> dft_2d;
+    dft<1, ctype, rtype, 0, 1> rdft_1d;
+    if (A == 0)
+    {
+      length_type x2 = x_length/2 + 1;
+      aligned_array<rtype> tmp_r(x2 * y_length * z_length);
+      aligned_array<rtype> tmp_i(x2 * y_length * z_length);
+      for (length_type x = 0; x != x2; ++x)
+      {
+	ztype line = std::make_pair(tmp_r.get() + x * y_length * z_length,
+				    tmp_i.get() + x * y_length * z_length);
+	dft_2d.by_reference(offset(in, x * in_x_stride),
+			    in_y_stride, in_z_stride,
+			    line,
+			    1, y_length,
+			    y_length, z_length);
+      }
+      for (length_type y = 0; y != y_length; ++y)
+	for (length_type z = 0; z != z_length; ++z)
+	{
+	  ztype line = std::make_pair(tmp_r.get() + y + z * y_length,
+				      tmp_i.get() + y + z * y_length);
+	  rdft_1d.by_reference(line,
+			       y_length * z_length,
+			       out + y * out_y_stride + z * out_z_stride,
+			       out_x_stride, x_length);
+	}
+    }
+    else if (A == 1)
+    {
+      length_type y2 = y_length/2 + 1;
+      aligned_array<rtype> tmp_r(y2 * x_length * z_length);
+      aligned_array<rtype> tmp_i(y2 * x_length * z_length);
+      for (length_type y = 0; y != y2; ++y)
+      {
+	ztype line = std::make_pair(tmp_r.get() + y * x_length * z_length,
+				    tmp_i.get() + y * x_length * z_length);
+	dft_2d.by_reference(offset(in, y * in_y_stride),
+			    in_x_stride, in_z_stride,
+			    line,
+			    1, x_length,
+			    x_length, z_length);
+      }
+      for (length_type x = 0; x != x_length; ++x)
+	for (length_type z = 0; z != z_length; ++z)
+	{
+	  ztype line = std::make_pair(tmp_r.get() + x + z * x_length,
+				      tmp_i.get() + x + z * x_length);
+	  rdft_1d.by_reference(line,
+			       x_length * z_length,
+			       out + x * out_x_stride + z * out_z_stride,
+			       out_y_stride, y_length);
+	}
+    }
+    else
+    {
+      length_type z2 = z_length/2 + 1;
+      aligned_array<rtype> tmp_r(z2 * y_length * x_length);
+      aligned_array<rtype> tmp_i(z2 * y_length * x_length);
+      for (length_type z = 0; z != z2; ++z)
+      {
+	ztype line = std::make_pair(tmp_r.get() + z * y_length * x_length,
+				    tmp_i.get() + z * y_length * x_length);
+	dft_2d.by_reference(offset(in, z * in_z_stride),
+			    in_y_stride, in_x_stride,
+			    line,
+			    1, y_length,
+			    y_length, x_length);
+      }
+      for (length_type y = 0; y != y_length; ++y)
+	for (length_type x = 0; x != x_length; ++x)
+	{
+	  ztype line = std::make_pair(tmp_r.get() + y + x * y_length,
+				      tmp_i.get() + y + x * y_length);
+	  rdft_1d.by_reference(line,
+			       y_length * x_length,
+			       out + y * out_y_stride + x * out_x_stride,
+			       out_z_stride, z_length);
+	}
+    }
   }
 
 };
Index: src/vsip/impl/fft/no_fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft/no_fft.hpp,v
retrieving revision 1.2
diff -u -r1.2 no_fft.hpp
--- src/vsip/impl/fft/no_fft.hpp	10 May 2006 02:54:09 -0000	1.2
+++ src/vsip/impl/fft/no_fft.hpp	14 May 2006 05:46:58 -0000
@@ -32,7 +32,7 @@
 {
   no_fft_base() 
   {
-    std::cout << "constructing no_fft_base" << std::endl;
+//     std::cout << "constructing no_fft_base" << std::endl;
   }
 };
 
Index: src/vsip/impl/fftw3/fft_impl.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fftw3/fft_impl.cpp,v
retrieving revision 1.5
diff -u -r1.5 fft_impl.cpp
--- src/vsip/impl/fftw3/fft_impl.cpp	14 May 2006 02:21:04 -0000	1.5
+++ src/vsip/impl/fftw3/fft_impl.cpp	14 May 2006 05:46:59 -0000
@@ -167,9 +167,9 @@
 		      reinterpret_cast<FFTW(complex)*>(in), 
 		      reinterpret_cast<FFTW(complex)*>(out));
   }
-  virtual void by_reference(ztype, stride_type in_stride,
-			    ztype, stride_type out_stride,
-			    length_type length)
+  virtual void by_reference(ztype, stride_type,
+			    ztype, stride_type,
+			    length_type)
   {
   }
 };
@@ -189,16 +189,16 @@
   Fft_impl(Domain<1> const &dom, unsigned number)
     : Fft_base<1, rtype, ctype>(dom, A, convert_NoT(number))
   {}
-  virtual void by_reference(rtype *in, stride_type in_stride,
-			    ctype *out, stride_type out_stride,
-			    length_type length)
+  virtual void by_reference(rtype *in, stride_type,
+			    ctype *out, stride_type,
+			    length_type)
   {
     FFTW(execute_dft_r2c)(plan_by_reference_, 
 			  in, reinterpret_cast<FFTW(complex)*>(out));
   }
-  virtual void by_reference(rtype *in, stride_type in_stride,
-			    ztype out, stride_type out_stride,
-			    length_type length)
+  virtual void by_reference(rtype *, stride_type,
+			    ztype, stride_type,
+			    length_type)
   {
   }
 
@@ -222,16 +222,16 @@
 
   virtual bool requires_copy(Rt_layout<1> &) { return true;}
 
-  virtual void by_reference(ctype *in, stride_type in_stride,
-			    rtype *out, stride_type out_stride,
-			    length_type length)
+  virtual void by_reference(ctype *in, stride_type,
+			    rtype *out, stride_type,
+			    length_type)
   {
     FFTW(execute_dft_c2r)(plan_by_reference_,
 			  reinterpret_cast<FFTW(complex)*>(in), out);
   }
-  virtual void by_reference(ztype in, stride_type in_stride,
-			    rtype *out, stride_type out_stride,
-			    length_type length)
+  virtual void by_reference(ztype, stride_type,
+			    rtype *, stride_type,
+			    length_type)
   {
   }
 
@@ -261,8 +261,8 @@
     rtl_out = rtl_in;
   }
   virtual void in_place(ctype *inout,
-			stride_type r_stride, stride_type c_stride,
-			length_type rows, length_type cols)
+			stride_type, stride_type,
+			length_type, length_type)
   {
     FFTW(execute_dft)(plan_in_place_,
 		      reinterpret_cast<FFTW(complex)*>(inout),
@@ -270,25 +270,25 @@
   }
   /// complex (split) in-place
   virtual void in_place(ztype,
-			stride_type r_stride, stride_type c_stride,
-			length_type rows, length_type cols)
+			stride_type, stride_type,
+			length_type, length_type)
   {
   }
   virtual void by_reference(ctype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
+			    stride_type, stride_type,
 			    ctype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
     FFTW(execute_dft)(plan_by_reference_,
 		      reinterpret_cast<FFTW(complex)*>(in), 
 		      reinterpret_cast<FFTW(complex)*>(out));
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
@@ -321,19 +321,19 @@
   virtual bool requires_copy(Rt_layout<2> &) { return true;}
 
   virtual void by_reference(rtype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
+			    stride_type, stride_type,
 			    ctype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
     FFTW(execute_dft_r2c)(plan_by_reference_,
 			  in, reinterpret_cast<FFTW(complex)*>(out));
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
 
@@ -367,19 +367,19 @@
   virtual bool requires_copy(Rt_layout<2> &) { return true;}
 
   virtual void by_reference(ctype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
+			    stride_type, stride_type,
 			    rtype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
     FFTW(execute_dft_c2r)(plan_by_reference_, 
 			  reinterpret_cast<FFTW(complex)*>(in), out);
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
 
@@ -409,57 +409,53 @@
     rtl_out = rtl_in;
   }
   virtual void in_place(ctype *inout,
-			stride_type x_stride,
-			stride_type y_stride,
-			stride_type z_stride,
-			length_type x_length,
-			length_type y_length,
-			length_type z_length)
+			stride_type,
+			stride_type,
+			stride_type,
+			length_type,
+			length_type,
+			length_type)
   {
-    // TODO: assert correct layout
     FFTW(execute_dft)(plan_in_place_,
 		      reinterpret_cast<FFTW(complex)*>(inout),
 		      reinterpret_cast<FFTW(complex)*>(inout));
   }
-  virtual void in_place(ztype inout,
-			stride_type x_stride,
-			stride_type y_stride,
-			stride_type z_stride,
-			length_type x_length,
-			length_type y_length,
-			length_type z_length)
+  virtual void in_place(ztype,
+			stride_type,
+			stride_type,
+			stride_type,
+			length_type,
+			length_type,
+			length_type)
   {
   }
   virtual void by_reference(ctype *in,
-			    stride_type in_x_stride,
-			    stride_type in_y_stride,
-			    stride_type in_z_stride,
+			    stride_type,
+			    stride_type,
+			    stride_type,
 			    ctype *out,
-			    stride_type out_x_stride,
-			    stride_type out_y_stride,
-			    stride_type out_z_stride,
-			    length_type x_length,
-			    length_type y_length,
-			    length_type z_length)
-  {
-    std::cout << "3D c->c by ref" << std::endl;
-    // TODO: Make sure the layout is identical to the one used
-    //       during plan construction.
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    length_type,
+			    length_type,
+			    length_type)
+  {
     FFTW(execute_dft)(plan_by_reference_,
 		      reinterpret_cast<FFTW(complex)*>(in), 
 		      reinterpret_cast<FFTW(complex)*>(out));
   }
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
@@ -496,30 +492,31 @@
   virtual bool requires_copy(Rt_layout<3> &) { return true;}
 
   virtual void by_reference(rtype *in,
-			    stride_type in_x_stride,
-			    stride_type in_y_stride,
-			    stride_type in_z_stride,
+			    stride_type,
+			    stride_type,
+			    stride_type,
 			    ctype *out,
-			    stride_type out_x_stride,
-			    stride_type out_y_stride,
-			    stride_type out_z_stride,
-			    length_type x_length,
-			    length_type y_length,
-			    length_type z_length)
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    length_type,
+			    length_type,
+			    length_type)
   {
-    std::cout << "3D r->c by_ref" << std::endl;
+    FFTW(execute_dft_r2c)(plan_by_reference_,
+			  in, reinterpret_cast<FFTW(complex)*>(out));
   }
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
+			    ztype,
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    length_type,
+			    length_type,
+			    length_type)
   {
   }
 
@@ -557,30 +554,31 @@
   virtual bool requires_copy(Rt_layout<3> &) { return true;}
 
   virtual void by_reference(ctype *in,
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
-    std::cout << "3D c->r by_ref" << std::endl;
-  }
-  virtual void by_reference(ztype in,
-			    stride_type in_x_stride,
-			    stride_type in_y_stride,
-			    stride_type in_z_stride,
+			    stride_type,
+			    stride_type,
+			    stride_type,
 			    rtype *out,
-			    stride_type out_x_stride,
-			    stride_type out_y_stride,
-			    stride_type out_z_stride,
-			    length_type x_length,
-			    length_type y_length,
-			    length_type z_length)
+			    stride_type,
+			    stride_type,
+			    stride_type,
+			    length_type,
+			    length_type,
+			    length_type)
+  {
+    FFTW(execute_dft_c2r)(plan_by_reference_,
+			  reinterpret_cast<FFTW(complex)*>(in), out);
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
 
@@ -613,9 +611,9 @@
     rtl_out = rtl_in;
   }
   virtual void by_reference(rtype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
+			    stride_type, stride_type,
 			    ctype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
+			    stride_type, stride_type,
 			    length_type rows, length_type cols)
   {
     length_type const n_fft = (A == 1) ? rows : cols;
@@ -629,11 +627,11 @@
       out += size_[0]/2 + 1;
     }
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
 
@@ -671,9 +669,9 @@
   virtual bool requires_copy(Rt_layout<2> &) { return true;}
 
   virtual void by_reference(ctype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
+			    stride_type, stride_type,
 			    rtype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
+			    stride_type, stride_type,
 			    length_type rows, length_type cols)
   {
     length_type const n_fft = (A == 1) ? rows : cols;
@@ -687,11 +685,11 @@
       out += size_[0];
     }
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
 
@@ -725,7 +723,7 @@
     rtl_out = rtl_in;
   }
   virtual void in_place(ctype *inout,
-			stride_type r_stride, stride_type c_stride,
+			stride_type, stride_type,
 			length_type rows, length_type cols)
   {
     length_type const n_fft = (A == 1) ? rows : cols;
@@ -740,16 +738,16 @@
     }
   }
 
-  virtual void in_place(ztype inout,
-			stride_type r_stride, stride_type c_stride,
-			length_type rows, length_type cols)
+  virtual void in_place(ztype,
+			stride_type, stride_type,
+			length_type, length_type)
   {
   }
 
   virtual void by_reference(ctype *in,
-			    stride_type in_r_stride, stride_type in_c_stride,
+			    stride_type, stride_type,
 			    ctype *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
+			    stride_type, stride_type,
 			    length_type rows, length_type cols)
   {
     // If the inputs to the Fftm are distributed, the number of FFTs may
@@ -766,11 +764,11 @@
       out += size_[0];
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
 
Index: src/vsip/impl/ipp/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp/fft.cpp,v
retrieving revision 1.2
diff -u -r1.2 fft.cpp
--- src/vsip/impl/ipp/fft.cpp	10 May 2006 02:54:10 -0000	1.2
+++ src/vsip/impl/ipp/fft.cpp	14 May 2006 05:46:59 -0000
@@ -560,8 +560,6 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    std::cout << "2D by_ref " << std::endl;
-    assert(0);
   }
   virtual void by_reference(rtype *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
@@ -603,8 +601,6 @@
 			    stride_type out_r_stride, stride_type out_c_stride,
 			    length_type rows, length_type cols)
   {
-    std::cout << "2D by_ref " << std::endl;
-    assert(0);
   }
   virtual void by_reference(ztype,
 			    stride_type in_r_stride, stride_type in_c_stride,
Index: tests/fft_be.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft_be.cpp,v
retrieving revision 1.5
diff -u -r1.5 fft_be.cpp
--- tests/fft_be.cpp	13 May 2006 20:43:26 -0000	1.5
+++ tests/fft_be.cpp	14 May 2006 05:46:59 -0000
@@ -179,6 +179,59 @@
   return Tensor<T>(x_length, y_length, z_length, T(0.));
 }
 
+template <typename T, dimension_type D> 
+struct input_creator
+{
+  typedef typename T::I I;
+  static typename impl::View_of_dim<D, I, Dense<D, I> >::type
+  create(Domain<D> const &dom) { return ramp<I>(dom);}
+};
+
+// Real inverse FFT
+template <typename T, typename F, int A, dimension_type D> 
+struct input_creator<rfft_type<T, F, 1, A>, D>
+{
+  typedef typename rfft_type<T, F, 1, A>::I I;
+  static typename impl::View_of_dim<D, I, Dense<D, I> >::type
+  create(Domain<D> const &dom) 
+  { return ramp<I>(rfft_type<T, F, 1, A>::in_dom(dom));}
+};
+
+// Real inverse 2D FFT.
+template <typename T, typename F, int A>
+struct input_creator<rfft_type<T, F, 1, A>, 2>
+{
+  typedef typename rfft_type<T, F, 1, A>::I I;
+  static Matrix<I> 
+  create(Domain<2> const &dom) 
+  {
+    length_type rows  = dom[0].size();
+    length_type cols  = dom[1].size();
+    length_type rows2 = rows/2+1;
+    length_type cols2 = cols/2+1;
+
+    Matrix<I> input = ramp<I>(rfft_type<T, F, 1, A>::in_dom(dom));
+    if (rfft_type<T, F, 1, A>::axis == 0)
+    {
+      // Necessary symmetry:
+      for (index_type cc=cols2; cc<cols; ++cc)
+      {
+	input(0, cc) = conj(input.get(0, cols-cc));
+	input(rows2-1, cc) = conj(input.get(rows2-1, cols-cc));
+      }
+    }
+    else
+    {
+      // Necessary symmetry:
+      for (index_type rr=rows2; rr<rows; ++rr)
+      {
+	input(rr, 0) = conj(input.get(rows-rr, 0));
+	input(rr, cols2-1) = conj(input.get(rows-rr, cols2-1));
+      }
+    }
+    return input;
+  }
+};
 
 template <typename T, typename B, dimension_type D>
 void fft_by_ref(Domain<D> const &dom)
@@ -200,7 +253,7 @@
   Domain<D> out_dom = T::out_dom(dom);
 
   // Set up some input data.
-  Iview input = ramp<I>(in_dom);
+  Iview input = input_creator<T, D>::create(dom);
 
   // Preserve it to validate that input isn't destroyed during the FFT.
   Iview orig = empty<I>(in_dom);
@@ -208,38 +261,6 @@
   // Set up subview to be used as input (helpful for testing non-unit-strides).
   typename Iview::subview_type sub_input = input(in_dom);
 
-#if 0
-  if (T::s == 0)
-  {
-    length_type rows  = out_dom[0].size();
-    length_type cols  = out_dom[1].size();
-    length_type rows2 = rows/2+1;
-    length_type cols2 = cols/2+1;
-
-    // Necessary symmetry:
-    for (index_type cc=cols2; cc<cols; ++cc)
-    {
-      sub_input(0, cc) = conj(sub_input.get(0, cols-cc));
-      sub_input(rows2-1, cc) = conj(sub_input.get(rows2-1, cols-cc));
-    }
-  }
-  else
-  {
-    length_type rows  = out_dom[0].size();
-    length_type cols  = out_dom[1].size();
-    length_type rows2 = rows/2+1;
-    length_type cols2 = cols/2+1;
-
-    // Necessary symmetry:
-    for (index_type rr=rows2; rr<rows; ++rr)
-    {
-      sub_input(rr, 0) = conj(sub_input.get(rows-rr, 0));
-      sub_input(rr, cols2-1) = conj(sub_input.get(rows-rr, cols2-1));
-    }
-  }
-  orig = input;
-#endif
-
   // Set up the output data...
   Oview output = empty<O>(out_dom);
   // ...with possibly non-unit-stride.
@@ -318,7 +339,7 @@
   Domain<2> in_dom = T::in_dom(dom);
   Domain<2> out_dom = T::out_dom(dom);
 
-  Iview input = ramp<I>(in_dom);
+  Iview input = input_creator<T, 2>::create(dom);
   typename Iview::subview_type sub_input = input(in_dom);
 
   Oview output = empty<O>(out_dom);
@@ -510,12 +531,12 @@
 						    Domain<1>(0, 2, 16)));
   std::cout << "testing c->r inv 0 by_ref sal...";
   fft_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(8, 16));
-  fft_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(Domain<1>(0, 2, 8),
-						    Domain<1>(0, 2, 16)));
+//   fft_by_ref<rfft_type<T, F, 1, 0>, sal> (Domain<2>(Domain<1>(0, 2, 8),
+// 						    Domain<1>(0, 2, 16)));
   std::cout << "testing c->r inv 1 by_ref sal...";
   fft_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(8, 16));
-  fft_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(Domain<1>(0, 2, 8),
-						    Domain<1>(0, 2, 16)));
+//   fft_by_ref<rfft_type<T, F, 1, 1>, sal> (Domain<2>(Domain<1>(0, 2, 8),
+// 						    Domain<1>(0, 2, 16)));
   std::cout << "testing c->c fwd by_ref ipp...";
   fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<2>(8, 16));
   fft_by_ref<cfft_type<T, F, -1>, ipp>(Domain<2>(Domain<1>(0, 2, 8),
@@ -543,6 +564,62 @@
 }
 
 template <typename T, typename F>
+void test_fft3d()
+{
+  std::cout << "testing fwd in_place fftw...";
+  fft_in_place<T, F, -1, fftw>(Domain<3>(8, 16, 32));
+  fft_in_place<T, F, -1, fftw>(Domain<3>(Domain<1>(0, 2, 8),
+					 Domain<1>(0, 2, 16),
+					 Domain<1>(0, 2, 32)));
+  std::cout << "testing inv in_place fftw...";
+  fft_in_place<T, F, 1, fftw>(Domain<3>(8, 16, 32));
+  fft_in_place<T, F, 1, fftw>(Domain<3>(Domain<1>(0, 2, 8),
+					Domain<1>(0, 2, 16),
+					Domain<1>(0, 2, 32)));
+
+  std::cout << "testing c->c fwd by_ref fftw...";
+  fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<3>(8, 16, 32));
+  fft_by_ref<cfft_type<T, F, -1>, fftw>(Domain<3>(Domain<1>(0, 2, 8),
+						  Domain<1>(0, 2, 16),
+						  Domain<1>(0, 2, 32)));
+  std::cout << "testing c->c inv by_ref fftw...";
+  fft_by_ref<cfft_type<T, F, 1>, fftw>(Domain<3>(8, 16, 32));
+  fft_by_ref<cfft_type<T, F, 1>, fftw>(Domain<3>(Domain<1>(0, 2, 8),
+						 Domain<1>(0, 2, 16),
+						 Domain<1>(0, 2, 32)));
+  std::cout << "testing r->c fwd 0 by_ref fftw...";
+  fft_by_ref<rfft_type<T, F, -1, 0>, fftw>(Domain<3>(8, 16, 32));
+  fft_by_ref<rfft_type<T, F, -1, 0>, fftw>(Domain<3>(Domain<1>(0, 2, 8),
+						     Domain<1>(0, 2, 16),
+						     Domain<1>(0, 2, 32)));
+  std::cout << "testing r->c fwd 1 by_ref fftw...";
+  fft_by_ref<rfft_type<T, F, -1, 1>, fftw>(Domain<3>(8, 16, 32));
+  fft_by_ref<rfft_type<T, F, -1, 1>, fftw>(Domain<3>(Domain<1>(0, 2, 8),
+						     Domain<1>(0, 2, 16),
+						     Domain<1>(0, 2, 32)));
+  std::cout << "testing r->c fwd 2 by_ref fftw...";
+  fft_by_ref<rfft_type<T, F, -1, 2>, fftw>(Domain<3>(8, 16, 32));
+  fft_by_ref<rfft_type<T, F, -1, 2>, fftw>(Domain<3>(Domain<1>(0, 2, 8),
+						     Domain<1>(0, 2, 16),
+						     Domain<1>(0, 2, 32)));
+  std::cout << "testing c->r inv 0 by_ref fftw...";
+  fft_by_ref<rfft_type<T, F, 1, 0>, fftw> (Domain<3>(8, 16, 32));
+  fft_by_ref<rfft_type<T, F, 1, 0>, fftw> (Domain<3>(Domain<1>(0, 2, 8),
+						     Domain<1>(0, 2, 16),
+						     Domain<1>(0, 2, 32)));
+  std::cout << "testing c->r inv 1 by_ref fftw...";
+  fft_by_ref<rfft_type<T, F, 1, 1>, fftw> (Domain<3>(8, 16, 32));
+  fft_by_ref<rfft_type<T, F, 1, 1>, fftw> (Domain<3>(Domain<1>(0, 2, 8),
+						     Domain<1>(0, 2, 16),
+						     Domain<1>(0, 2, 32)));
+  std::cout << "testing c->r inv 2 by_ref fftw...";
+  fft_by_ref<rfft_type<T, F, 1, 2>, fftw> (Domain<3>(8, 16, 32));
+  fft_by_ref<rfft_type<T, F, 1, 2>, fftw> (Domain<3>(Domain<1>(0, 2, 8),
+						     Domain<1>(0, 2, 16),
+						     Domain<1>(0, 2, 32)));
+}
+
+template <typename T, typename F>
 void test_fftm()
 {
   std::cout << "testing fwd 0 in_place fftw...";
@@ -656,4 +733,13 @@
   test_fftm<double, inter>();
   std::cout << "testing split double fftm" << std::endl;
   test_fftm<double, split>();
+
+  std::cout << "testing interleaved float 3D fft" << std::endl;
+  test_fft3d<float, inter>();
+  std::cout << "testing split float 3D fft" << std::endl;
+  test_fft3d<float, split>();
+  std::cout << "testing interleaved double 3D fft" << std::endl;
+  test_fft3d<double, inter>();
+  std::cout << "testing split double 3D fft" << std::endl;
+  test_fft3d<double, split>();
 }
