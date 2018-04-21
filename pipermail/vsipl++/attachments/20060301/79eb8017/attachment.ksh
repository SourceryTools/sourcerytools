Index: src/vsip/impl/signal-fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/signal-fft.hpp,v
retrieving revision 1.31
diff -u -r1.31 signal-fft.hpp
--- src/vsip/impl/signal-fft.hpp	27 Feb 2006 15:07:13 -0000	1.31
+++ src/vsip/impl/signal-fft.hpp	1 Mar 2006 16:27:43 -0000
@@ -436,11 +436,8 @@
 
 #elif defined(VSIP_IMPL_SAL_FFT) 
 
-    // In some contexts, SAL destroys the input data itself, and sometimes
-    // we have to modify it to 'pack' data into the format SAL expects
-    // (see SAL Tutorial for details).
-    // Therefor, we always copy the input.
-    static const bool  force_copy = true;
+    // We must copy for real inverse transforms (c->r).
+    static const bool force_copy = (sizeof(inT) > sizeof(outT));
     // SAL cannot handle non-unit strides properly as 'complex' isn't
     // a real (packed) datatype, so the stride would be applied to the real/imag
     // offset, too.
@@ -792,7 +789,6 @@
 
       static const bool force_copy = true;
       static const vsip::dimension_type  transpose_target = 1;
-
 #else
       static const bool force_copy = false;
       static const vsip::dimension_type  transpose_target = axis;
Index: src/vsip/impl/sal/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/fft.hpp,v
retrieving revision 1.3
diff -u -r1.3 fft.hpp
--- src/vsip/impl/sal/fft.hpp	27 Feb 2006 19:39:27 -0000	1.3
+++ src/vsip/impl/sal/fft.hpp	1 Mar 2006 16:27:43 -0000
@@ -503,9 +503,6 @@
   fft2d_ropx(&setup, in_, 1, N,
 	     out, 1, 1 << self.size_[1],
 	     self.size_[1], self.size_[0], FFT_INVERSE, sal::ESAL);
-  // inverse fft_ropx is scaled up by N.
-//   float N = 1 << self.size_[1] + 2;
-//   vsmul(out, 1, &N, out, 1, (int)N);
 }
 
 inline void
@@ -516,12 +513,12 @@
   FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
   double *in_ = 
     reinterpret_cast<double *>(const_cast<std::complex<double>*>(in));
+  // The size of the output array is (N/2) x M (if measured in std::complex<float>)
   // pack the data (see SAL reference for details).
   int const N = (1 << self.size_[1]) + 2;
-  in_[1] = in_[N - 2];
-  in_[N - 2] = in_[N - 1] = 0.f;
-
-  fft2d_ropdx(&setup, in_, 1, 1 << self.size_[1],
+  unsigned long const M = (1 << self.size_[0]);
+  pack(in_, N, M, self.stride_);
+  fft2d_ropdx(&setup, in_, 1, N,
 	      out, 1, 1 << self.size_[1],
 	      self.size_[1], self.size_[0], FFT_INVERSE, sal::ESAL);
 }
@@ -573,6 +570,17 @@
 }
 
 inline void
+in_place(Fft_core<2, std::complex<double>, std::complex<double>, true>& self,
+	 std::complex<double> *inout) VSIP_NOTHROW
+{
+  FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
+  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
+  fftm_cipdx(&setup, reinterpret_cast<DOUBLE_COMPLEX *>(inout),
+	    2, 2 << self.size_[1], self.size_[1], self.runs_,
+	    direction, sal::ESAL);
+}
+
+inline void
 from_to(Fft_core<2, std::complex<float>, std::complex<float>, true>& self,
 	std::complex<float> const *in, std::complex<float> *out_arg) VSIP_NOTHROW
 {
@@ -581,7 +589,7 @@
     reinterpret_cast<COMPLEX *>(const_cast<std::complex<float>*>(in));
   COMPLEX *out = reinterpret_cast<COMPLEX *>(out_arg);
   long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
-  fftm_coptx(&setup, in_, self.stride_, self.dist_,
+  fftm_coptx(&setup, in_, 2, 2 << self.size_[1],
 	     out, 2, 2 << self.size_[1],
 	     reinterpret_cast<COMPLEX*>(self.buffer_),
 	     self.size_[1], self.runs_,
@@ -594,12 +602,11 @@
 {
   FFT_setup setup = reinterpret_cast<FFT_setup>(self.plan_);
   float *out = reinterpret_cast<float*>(out_arg);
-  long direction = self.is_forward_ ? FFT_FORWARD : FFT_INVERSE;
   fftm_roptx(&setup, const_cast<float *>(in), self.stride_, self.dist_,
 	     out, self.stride_, self.dist_ + 2,
 	     reinterpret_cast<float*>(self.buffer_),
 	     self.size_[1], self.runs_,
-	     direction, sal::ESAL);
+	     FFT_FORWARD, sal::ESAL);
   // Unpack the data (see SAL reference for details), and scale back by 1/2.
   int const N = (1 << self.size_[1]) + 2;
   float scale = 0.5f;
@@ -613,6 +620,29 @@
 }
 
 inline void
+from_to(Fft_core<2, double, std::complex<double>, true>& self,
+	double const *in, std::complex<double> *out_arg) VSIP_NOTHROW
+{
+  FFT_setupd setup = reinterpret_cast<FFT_setupd>(self.plan_);
+  double *out = reinterpret_cast<double*>(out_arg);
+  fftm_roptdx(&setup, const_cast<double *>(in), self.stride_, self.dist_,
+	     out, self.stride_, self.dist_ + 2,
+	     reinterpret_cast<double*>(self.buffer_),
+	     self.size_[1], self.runs_,
+	     FFT_FORWARD, sal::ESAL);
+  // Unpack the data (see SAL reference for details), and scale back by 1/2.
+  int const N = (1 << self.size_[1]) + 2;
+  double scale = 0.5f;
+  for (unsigned int i = 0; i != self.runs_; ++i, out += self.dist_ + 2)
+  {
+    out[(N - 2) * self.stride_] = out[self.stride_];
+    out[self.stride_] = 0.f;
+    out[(N - 1) * self.stride_] = 0.f;
+    vsmuldx(out, self.stride_, &scale, out, self.stride_, N, sal::ESAL);
+  }
+}
+
+inline void
 from_to(Fft_core<2, std::complex<double>, std::complex<double>, true>& self,
 	std::complex<double> const *in, std::complex<double> *out_arg) VSIP_NOTHROW
 {
@@ -625,7 +655,7 @@
   fftm_coptdx(&setup, in_, stride, stride << self.size_[1],
 	      out, stride, stride << self.size_[1],
 	      reinterpret_cast<DOUBLE_COMPLEX*>(self.buffer_),
-	      self.size_[1], 1 << self.size_[0],
+	      self.size_[1], self.runs_,
 	      direction, sal::ESAL);
 }
 
Index: tests/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft.cpp,v
retrieving revision 1.12
diff -u -r1.12 fft.cpp
--- tests/fft.cpp	27 Feb 2006 15:07:13 -0000	1.12
+++ tests/fft.cpp	1 Mar 2006 16:27:44 -0000
@@ -779,9 +779,7 @@
   { 1, 1, 1 },
   { 2, 2, 1 },
   { 2, 8, 128 },
-#endif
   { 3, 5, 7 },
-#if !defined(VSIP_IMPL_SAL_FFT)
   { 2, 24, 48 },
   { 24, 1, 5 },
 #endif
@@ -811,7 +809,7 @@
   typedef typename Arg<Dim,in_elt_type,inL>::type    in_type;
   typedef typename Arg<Dim,out_elt_type,outL>::type  out_type;
 
-  for (unsigned i = 0; i < sizeof(sizes)/(sizeof(*sizes)*3); ++i)
+  for (unsigned i = 0; i < sizeof(sizes)/sizeof(*sizes); ++i)
   {
     vsip::Rand<in_elt_type> rander(
       sizes[i][0] * sizes[i][1] * sizes[i][2] * Dim * (sD+5) * (isReal+1));
@@ -1141,7 +1139,7 @@
   test_fft<2,2,SCALAR,true,2,1>();
   test_fft<2,2,SCALAR,true,2,0>();
 
-#if ! defined(VSIP_IMPL_SAL_FFT)
+#if 0//! defined(VSIP_IMPL_SAL_FFT)
   test_fft<0,1,SCALAR,false,3,vsip::fft_fwd>();
   test_fft<0,2,SCALAR,false,3,vsip::fft_fwd>();
   test_fft<1,0,SCALAR,false,3,vsip::fft_fwd>();
Index: tests/output.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/output.hpp,v
retrieving revision 1.2
diff -u -r1.2 output.hpp
--- tests/output.hpp	20 Dec 2005 12:48:41 -0000	1.2
+++ tests/output.hpp	1 Mar 2006 16:27:44 -0000
@@ -116,6 +116,21 @@
 }
 
 
+/// Pretend to write a tensor to a stream.
+
+template <typename T,
+	  typename Block>
+inline
+std::ostream&
+operator<<(
+  std::ostream&		       out,
+  vsip::const_Tensor<T, Block> v)
+  VSIP_NOTHROW
+{
+  return out;
+}
+
+
 /// Write a point to a stream.
 
 template <vsip::dimension_type Dim>
Index: tests/QMTest/vpp_database.py
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/QMTest/vpp_database.py,v
retrieving revision 1.6
diff -u -r1.6 vpp_database.py
--- tests/QMTest/vpp_database.py	16 Feb 2006 15:59:52 -0000	1.6
+++ tests/QMTest/vpp_database.py	1 Mar 2006 16:27:44 -0000
@@ -139,7 +139,7 @@
 
         dirname = os.path.join(self.GetRoot(), directory)
         if not os.path.isdir(dirname):
-            raise qm.test.database.NoSuchSuiteError, directory
+            raise NoSuchSuiteError, directory
 
         if kind == Database.TEST:
             datadir = os.path.join(dirname, 'data')
@@ -242,7 +242,7 @@
                 # There must be exactly one source file, which
                 # is our resource.
                 if len(src) > 1:
-                    raise database.DatabaseError,\
+                    raise DatabaseError,\
                           'multiple source files found in %s'%dirname
                 resources.append(self.JoinLabels(*(id_components[:-1] + src)))
 
