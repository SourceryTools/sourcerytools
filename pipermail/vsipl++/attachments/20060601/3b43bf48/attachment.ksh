Index: src/vsip/impl/ipp/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp/fft.hpp,v
retrieving revision 1.3
diff -u -r1.3 fft.hpp
--- src/vsip/impl/ipp/fft.hpp	14 May 2006 20:57:05 -0000	1.3
+++ src/vsip/impl/ipp/fft.hpp	1 Jun 2006 23:22:18 -0000
@@ -128,6 +128,27 @@
   }
 };
 
+template <int A, int E, return_mechanism_type R, unsigned N>
+struct evaluator<std::complex<long double>, std::complex<long double>,
+		 A, E, R, N, fft::Intel_ipp_tag>
+{
+  static bool const ct_valid = false;
+};
+
+template <int A, int E, return_mechanism_type R, unsigned N>
+struct evaluator<long double, std::complex<long double>,
+		 A, E, R, N, fft::Intel_ipp_tag>
+{
+  static bool const ct_valid = false;
+};
+
+template <int A, int E, return_mechanism_type R, unsigned N>
+struct evaluator<std::complex<long double>, long double,
+		 A, E, R, N, fft::Intel_ipp_tag>
+{
+  static bool const ct_valid = false;
+};
+
 } // namespace vsip::impl::fftm
 } // namespace vsip::impl
 } // namespace vsip
Index: src/vsip/impl/sal/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/fft.hpp,v
retrieving revision 1.10
diff -u -r1.10 fft.hpp
--- src/vsip/impl/sal/fft.hpp	14 May 2006 06:49:54 -0000	1.10
+++ src/vsip/impl/sal/fft.hpp	1 Jun 2006 23:22:19 -0000
@@ -187,7 +187,7 @@
 	  typename I,
 	  typename O,
 	  int S,
-	  vsip::return_mechanism_type R,
+	  return_mechanism_type R,
 	  unsigned N>
 struct evaluator<D, I, O, S, R, N, Mercury_sal_tag>
 {
@@ -216,7 +216,7 @@
 
 template <dimension_type D,
 	  int S,
-	  vsip::return_mechanism_type R,
+	  return_mechanism_type R,
 	  unsigned N>
 struct evaluator<D, std::complex<long double>, std::complex<long double>,
 		 S, R, N, Mercury_sal_tag>
@@ -227,7 +227,7 @@
 
 template <dimension_type D,
 	  int S,
-	  vsip::return_mechanism_type R,
+	  return_mechanism_type R,
 	  unsigned N>
 struct evaluator<D, long double, std::complex<long double>,
 		 S, R, N, Mercury_sal_tag>
@@ -238,7 +238,7 @@
 
 template <dimension_type D,
 	  int S,
-	  vsip::return_mechanism_type R,
+	  return_mechanism_type R,
 	  unsigned N>
 struct evaluator<D, std::complex<long double>, long double,
 		 S, R, N, Mercury_sal_tag>
@@ -250,7 +250,7 @@
 template <typename I,
 	  typename O,
 	  int S,
-	  vsip::return_mechanism_type R,
+	  return_mechanism_type R,
 	  unsigned N>
 struct evaluator<3, I, O, S, R, N, Mercury_sal_tag>
 {
@@ -258,6 +258,36 @@
   static bool const ct_valid = false;
 };
 
+template <int S,
+	  return_mechanism_type R,
+	  unsigned N>
+struct evaluator<3, std::complex<long double>, long double,
+		 S, R, N, Mercury_sal_tag>
+{
+  // No FFT 3D yet.
+  static bool const ct_valid = false;
+};
+
+template <int S,
+	  return_mechanism_type R,
+	  unsigned N>
+struct evaluator<3, long double, std::complex<long double>,
+		 S, R, N, Mercury_sal_tag>
+{
+  // No FFT 3D yet.
+  static bool const ct_valid = false;
+};
+
+template <int S,
+	  return_mechanism_type R,
+	  unsigned N>
+struct evaluator<3, std::complex<long double>, std::complex<long double>,
+		 S, R, N, Mercury_sal_tag>
+{
+  // No FFT 3D yet.
+  static bool const ct_valid = false;
+};
+
 } // namespace vsip::impl::fft
 
 namespace fftm
@@ -266,7 +296,7 @@
 	  typename O,
 	  int A,
 	  int E,
-	  vsip::return_mechanism_type R,
+	  return_mechanism_type R,
 	  unsigned N>
 struct evaluator<I, O, A, E, R, N, fft::Mercury_sal_tag>
 {
@@ -287,6 +317,26 @@
   }
 };
 
+template <int A, int E, return_mechanism_type R, unsigned N>
+struct evaluator<std::complex<long double>, long double,
+		 A, E, R, N, fft::Mercury_sal_tag>
+{
+  static bool const ct_valid = false;
+};
+
+template <int A, int E, return_mechanism_type R, unsigned N>
+struct evaluator<long double, std::complex<long double>,
+		 A, E, R, N, fft::Mercury_sal_tag>
+{
+  static bool const ct_valid = false;
+};
+
+template <int A, int E, return_mechanism_type R, unsigned N>
+struct evaluator<std::complex<long double>, std::complex<long double>,
+		 A, E, R, N, fft::Mercury_sal_tag>
+{
+  static bool const ct_valid = false;
+};
 } // namespace vsip::impl::fftm
 } // namespace vsip::impl
 } // namespace vsip
