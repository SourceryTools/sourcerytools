Index: ChangeLog
===================================================================
--- ChangeLog	(revision 214460)
+++ ChangeLog	(working copy)
@@ -1,3 +1,24 @@
+2008-07-10  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp: Put ALF decls in extern "C"
+	  block.
+	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Turn off unnecessary
+	  C++ features for C++ ALF kernels.
+	* src/vsip/opt/cbe/spu/alf_fconvm_c.c: Add missing ALF EXPORT API.
+	* src/vsip/opt/cbe/cml/transpose.hpp: Disable transpose for
+	  non-unit-stride.  Fix unit-stride+dense check.  Fix Wall warnings.
+	* src/vsip/opt/cbe/cml/matvec.hpp: Fix Wall warnings.
+	* src/vsip/opt/cbe/cml/fir.hpp: Throw on copy constructor.
+	  Disable BE if decimation != 1.
+	* src/vsip/opt/cbe/cml/conv.hpp: Fix Wall warnings.
+	* src/vsip/opt/cbe/cml/corr.hpp: Fix Wall warnings.
+	* src/vsip_csl/stencil/boundary_factory.hpp: Fix Wall warnings.
+	* tests/fft_be.cpp: XFail CML for double precision FFT.
+	* tests/test-prod.hpp: Add adjustable threshold.
+	* tests/ref-impl/signal-fir.cpp: Use equal.
+	* tests/regressions/par_transpose.cpp: Fix conversion.
+	* tests/matvec-prod.cpp: Adjust threshold on CBE.
+
 2008-07-10  Brooks Moses  <brooks@codesourcery.com>
 
 	* README.cbe: New file.
Index: src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp
===================================================================
--- src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp	(revision 214460)
+++ src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp	(working copy)
@@ -716,8 +716,11 @@
   return 0;
 }
 
+extern "C"
+{
 ALF_ACCEL_EXPORT_API_LIST_BEGIN
   ALF_ACCEL_EXPORT_API ("input", input);
   ALF_ACCEL_EXPORT_API ("output", output); 
   ALF_ACCEL_EXPORT_API ("kernel", kernel);
 ALF_ACCEL_EXPORT_API_LIST_END
+}
Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 214460)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -45,7 +45,7 @@
 CPP_SPU_FLAGS += -I $(CBE_SDK_SYSROOT)/usr/spu/include
 CPP_SPU_FLAGS += -I $(CBE_SDK_SYSROOT)/opt/cell/sdk/usr/spu/include
 C_SPU_FLAGS := -O3
-CXX_SPU_FLAGS := -O3
+CXX_SPU_FLAGS := -O3 -fno-threadsafe-statics -fno-rtti -fno-exceptions
 LD_SPU_FLAGS += -Wl,-N -L$(CBE_SDK_SYSROOT)/usr/spu/lib
 LD_SPU_FLAGS += -L$(CBE_SDK_SYSROOT)/opt/cell/sdk/usr/spu/lib
 
Index: src/vsip/opt/cbe/spu/alf_fconvm_c.c
===================================================================
--- src/vsip/opt/cbe/spu/alf_fconvm_c.c	(revision 214460)
+++ src/vsip/opt/cbe/spu/alf_fconvm_c.c	(working copy)
@@ -131,3 +131,9 @@
 
   return 0;
 }
+
+ALF_ACCEL_EXPORT_API_LIST_BEGIN
+  ALF_ACCEL_EXPORT_API ("input", input);
+  ALF_ACCEL_EXPORT_API ("output", output); 
+  ALF_ACCEL_EXPORT_API ("kernel", kernel);
+ALF_ACCEL_EXPORT_API_LIST_END
Index: src/vsip/opt/cbe/cml/transpose.hpp
===================================================================
--- src/vsip/opt/cbe/cml/transpose.hpp	(revision 214460)
+++ src/vsip/opt/cbe/cml/transpose.hpp	(working copy)
@@ -191,7 +191,7 @@
   static int const  lhs_cost      = Ext_data_cost<DstBlock>::value;
   static int const  rhs_cost      = Ext_data_cost<SrcBlock>::value;
 
-  static bool const ct_valid = 
+  static bool const ct_valid =
     // check that CML supports this data type and/or layout
     cml::Cml_supports_block<SrcBlock>::valid &&
     cml::Cml_supports_block<DstBlock>::valid &&
@@ -210,16 +210,25 @@
 
     // If performing a copy, both source and destination blocks
     // must be unit stride and dense.
-    if (Type_equal<src_order_type, dst_order_type>::value)
+    //
+    // 080710: CML cannot handle non-unit stride transpose
+    //         (regressions/transpose-nonunit.cpp fails),
+    //         temporarily enforce unit-stride requirement.
+    //
+    // if (Type_equal<src_order_type, dst_order_type>::value)
     {
       Ext_data<DstBlock> dst_ext(dst, SYNC_OUT);
       Ext_data<SrcBlock> src_ext(src, SYNC_IN);
 
+      dimension_type const s_dim0 = src_order_type::impl_dim0;
       dimension_type const s_dim1 = src_order_type::impl_dim1;
+      dimension_type const d_dim0 = dst_order_type::impl_dim0;
       dimension_type const d_dim1 = dst_order_type::impl_dim1;
 
-      if (dst_ext.stride(d_dim1) != 1 || dst_ext.stride(0) != dst.size(2, 1) ||
-          src_ext.stride(s_dim1) != 1 || src_ext.stride(0) != src.size(2, 1))
+      if (dst_ext.stride(d_dim1) != 1 ||
+	  dst_ext.stride(d_dim0) != static_cast<stride_type>(dst.size(2, d_dim1)) ||
+	  src_ext.stride(s_dim1) != 1 ||
+	  src_ext.stride(s_dim0) != static_cast<stride_type>(src.size(2, s_dim1)))
         rt = false;
     }
 
@@ -233,8 +242,8 @@
 
     if (dst_ext.stride(1) == 1 && src_ext.stride(1) == 1)
     {
-      assert(dst_ext.stride(0) == dst.size(2, 1));
-      assert(src_ext.stride(0) == src.size(2, 1));
+      assert(dst_ext.stride(0) == static_cast<stride_type>(dst.size(2, 1)));
+      assert(src_ext.stride(0) == static_cast<stride_type>(src.size(2, 1)));
 
       cml::vcopy(
         src_ext.data(), 1,
@@ -252,8 +261,8 @@
 
     if (dst_ext.stride(0) == 1 && src_ext.stride(0) == 1)
     {
-      assert(dst_ext.stride(1) == dst.size(2, 0));
-      assert(src_ext.stride(1) == src.size(2, 0));
+      assert(dst_ext.stride(1) == static_cast<stride_type>(dst.size(2, 0)));
+      assert(src_ext.stride(1) == static_cast<stride_type>(src.size(2, 0)));
 
       cml::vcopy(
         src_ext.data(), 1,
Index: src/vsip/opt/cbe/cml/matvec.hpp
===================================================================
--- src/vsip/opt/cbe/cml/matvec.hpp	(revision 214460)
+++ src/vsip/opt/cbe/cml/matvec.hpp	(working copy)
@@ -362,7 +362,7 @@
     Ext_data_cost<Block1>::value == 0 &&
     Ext_data_cost<Block2>::value == 0;
 
-  static bool rt_valid(Block0& r, Block1 const& a, Block2 const& b)
+  static bool rt_valid(Block0& /*r*/, Block1 const& /*a*/, Block2 const& b)
   {
     Ext_data<Block2> ext_b(const_cast<Block2&>(b));
 
Index: src/vsip/opt/cbe/cml/fir.hpp
===================================================================
--- src/vsip/opt/cbe/cml/fir.hpp	(revision 214460)
+++ src/vsip/opt/cbe/cml/fir.hpp	(working copy)
@@ -129,6 +129,8 @@
       fir_obj_ptr_(NULL),
       filter_state_(fir.filter_state_)
   {
+    VSIP_IMPL_THROW(vsip::impl::unimplemented
+                    ("CML BE copy-construction broken."));
     fir_create(
       &fir_obj_ptr_,
       fir.fir_obj_ptr_->K,
@@ -200,6 +202,9 @@
     assert(o + 1 > d); // M >= decimation
     assert(i >= o);    // input_size >= M 
 
+    // 080710: CML BE has trouble with D != 1 (fir.cpp)
+    if (d != 1) return false;
+
     // CML FIR objects have fixed output size, whereas VSIPL++ FIR objects
     // have fixed input size.  If input size is not a multiple of the
     // decimation, output size will vary from frame to frame.  The 
Index: src/vsip/opt/cbe/cml/conv.hpp
===================================================================
--- src/vsip/opt/cbe/cml/conv.hpp	(revision 214460)
+++ src/vsip/opt/cbe/cml/conv.hpp	(working copy)
@@ -56,7 +56,7 @@
 void
 conv(
   float const* coeff, length_type c_size,
-  float const* in,    length_type i_size, stride_type s_in,
+  float const* in,    length_type /*i_size*/, stride_type s_in,
   float*       out,   length_type o_size, stride_type s_out,
   length_type decimation)
 {
@@ -67,7 +67,7 @@
 void
 conv(
   std::complex<float> const* coeff, length_type c_size,
-  std::complex<float> const* in,    length_type i_size, stride_type s_in,
+  std::complex<float> const* in,    length_type /*i_size*/, stride_type s_in,
   std::complex<float>*       out,   length_type o_size, stride_type s_out,
   length_type decimation)
 {
@@ -81,7 +81,7 @@
 void
 conv(
   std::pair<float*,float*> coeff, length_type c_size,
-  std::pair<float*,float*> in,    length_type i_size, stride_type s_in,
+  std::pair<float*,float*> in,    length_type /*i_size*/, stride_type s_in,
   std::pair<float*,float*> out,   length_type o_size, stride_type s_out,
   length_type decimation)
 {
Index: src/vsip/opt/cbe/cml/corr.hpp
===================================================================
--- src/vsip/opt/cbe/cml/corr.hpp	(revision 214460)
+++ src/vsip/opt/cbe/cml/corr.hpp	(working copy)
@@ -56,7 +56,7 @@
 void
 corr(
   float const* coeff, length_type c_size,
-  float const* in,    length_type i_size, stride_type s_in,
+  float const* in,    length_type /*i_size*/, stride_type s_in,
   float*       out,   length_type o_size, stride_type s_out,
   length_type decimation)
 {
@@ -67,7 +67,7 @@
 void
 corr(
   std::complex<float> const* coeff, length_type c_size,
-  std::complex<float> const* in,    length_type i_size, stride_type s_in,
+  std::complex<float> const* in,    length_type /*i_size*/, stride_type s_in,
   std::complex<float>*       out,   length_type o_size, stride_type s_out,
   length_type decimation)
 {
@@ -81,7 +81,7 @@
 void
 corr(
   std::pair<float*,float*> coeff, length_type c_size,
-  std::pair<float*,float*> in,    length_type i_size, stride_type s_in,
+  std::pair<float*,float*> in,    length_type /*i_size*/, stride_type s_in,
   std::pair<float*,float*> out,   length_type o_size, stride_type s_out,
   length_type decimation)
 {
Index: src/vsip_csl/stencil/boundary_factory.hpp
===================================================================
--- src/vsip_csl/stencil/boundary_factory.hpp	(revision 214460)
+++ src/vsip_csl/stencil/boundary_factory.hpp	(working copy)
@@ -241,7 +241,7 @@
        vsip::Domain<1>(b.size(2, 1) - k.size(1) + 1, 1, k.size(1) - 1));
   }
   // the destination subblock containing the mirror.
-  static vsip::Domain<2> dst_sub_domain(B const &b, K const &k)
+  static vsip::Domain<2> dst_sub_domain(B const& /*b*/, K const &k)
   {
     return vsip::Domain<2>(k.size(0) - 1, k.size(1) - 1);
   }
Index: tests/fft_be.cpp
===================================================================
--- tests/fft_be.cpp	(revision 214460)
+++ tests/fft_be.cpp	(working copy)
@@ -305,6 +305,12 @@
 template <typename F, return_mechanism_type R, typename O, unsigned int S>
 struct XFail<ipp, F, 2, R, std::complex<double>, O, S> { static bool const value = true;};
 
+// CBE doesn't support double FFTs
+template <typename F, return_mechanism_type R, typename O, unsigned int S>
+struct XFail<cbe, F, 1, R, double, O, S> { static bool const value = true;};
+template <typename F, return_mechanism_type R, typename O, unsigned int S>
+struct XFail<cbe, F, 1, R, complex<double>, O, S> { static bool const value = true;};
+
 bool has_errors = false;
 
 template <typename T, typename B, dimension_type D>
Index: tests/test-prod.hpp
===================================================================
--- tests/test-prod.hpp	(revision 214460)
+++ tests/test-prod.hpp	(working copy)
@@ -45,7 +45,8 @@
 check_prod(
   vsip::Matrix<T0, Block0> test,
   vsip::Matrix<T1, Block1> chk,
-  vsip::Matrix<T2, Block2> gauge)
+  vsip::Matrix<T2, Block2> gauge,
+  float                    threshold = 10.0)
 {
   typedef typename vsip::Promotion<T0, T1>::type return_type;
   typedef typename vsip::impl::Scalar_of<return_type>::type scalar_type;
@@ -56,14 +57,17 @@
 			    / gauge),
 			   idx);
 
-#if VERBOSE
-  std::cout << "test  =\n" << test;
-  std::cout << "chk   =\n" << chk;
-  std::cout << "gauge =\n" << gauge;
-  std::cout << "err = " << err << std::endl;
+#if 1 || VERBOSE
+  if (err >= threshold)
+  {
+    std::cout << "test  =\n" << test;
+    std::cout << "chk   =\n" << chk;
+    std::cout << "gauge =\n" << gauge;
+    std::cout << "err = " << err << std::endl;
+  }
 #endif
 
-  test_assert(err < 10.0);
+  test_assert(err < threshold);
 }
 
 
Index: tests/ref-impl/signal-fir.cpp
===================================================================
--- tests/ref-impl/signal-fir.cpp	(revision 214460)
+++ tests/ref-impl/signal-fir.cpp	(working copy)
@@ -65,7 +65,7 @@
     return false;
 
   for (vsip::index_type idx = 0; idx < vec.size (); ++idx)
-    if (answer.get (idx) != vec.get (idx))
+    if (!equal(answer.get (idx), vec.get (idx)))
       return false;
 
   return true;
Index: tests/regressions/par_transpose.cpp
===================================================================
--- tests/regressions/par_transpose.cpp	(revision 214460)
+++ tests/regressions/par_transpose.cpp	(working copy)
@@ -89,10 +89,10 @@
   for (row = 0; row < rows; row++)
     for (col = 0; col < cols; col++)
     {
-      test_assert(in1.get(row, col).real() == +(100*row + 1*col));
-      test_assert(in1.get(row, col).imag() == -(100*row + 1*col));
-      test_assert(in2.get(row, col).real() == +(1*row + 100*col));
-      test_assert(in2.get(row, col).imag() == -(1*row + 100*col));
+      test_assert(in1.get(row, col).real() == +(100.0*row + 1.0*col));
+      test_assert(in1.get(row, col).imag() == -(100.0*row + 1.0*col));
+      test_assert(in2.get(row, col).real() == +(1.0*row + 100.0*col));
+      test_assert(in2.get(row, col).imag() == -(1.0*row + 100.0*col));
 
       test_assert(tp1.get(col, row) == in1.get(row, col));
       test_assert(tp2.get(col, row) == 
Index: tests/matvec-prod.cpp
===================================================================
--- tests/matvec-prod.cpp	(revision 214460)
+++ tests/matvec-prod.cpp	(working copy)
@@ -33,7 +33,14 @@
 using namespace vsip;
 using namespace vsip_csl;
 
+// 070810: CML has larger precision differeneces for large matrices.
+#ifdef VSIP_IMPL_CBE_SDK
+#  define THRESHOLD 15.0
+#else
+#  define THRESHOLD 10.0
+#endif
 
+
 /***********************************************************************
   Test Definitions
 ***********************************************************************/
@@ -92,9 +99,9 @@
   cout << "b     =\n" << b;
 #endif
 
-  check_prod( res1, chk, gauge );
-  check_prod( res2, chk, gauge );
-  check_prod( res3, chk, gauge );
+  check_prod( res1, chk, gauge, THRESHOLD );
+  check_prod( res2, chk, gauge, THRESHOLD );
+  check_prod( res3, chk, gauge, THRESHOLD );
 }
 
 
@@ -140,7 +147,6 @@
   Precision_traits<float>::compute_eps();
   Precision_traits<double>::compute_eps();
 
-
   prod_cases_with_order<float,  float>();
 
   prod_cases_with_order<complex<float>, complex<float> >();
