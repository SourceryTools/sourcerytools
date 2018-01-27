Index: ChangeLog
===================================================================
--- ChangeLog	(revision 178932)
+++ ChangeLog	(working copy)
@@ -1,3 +1,22 @@
+2007-08-20  Jules Bergmann  <jules@codesourcery.com>
+
+	* scripts/config (MondoTestSerial): New test package, since
+	  MPI is broken on build server.
+	* scripts/datasheet.pl: Make vendor data optional.
+	* src/vsip/vector.hpp: Pass vector fill through dispatch.
+	* src/vsip/matrix.hpp: Pass matrix fill through dispatch.
+	* src/vsip/opt/sal/is_op_supported.hpp: Add dispatch for SAL 
+	  unsigned {long, short} -> float conversions
+	* src/vsip/opt/sal/elementwise.hpp: Likewise.
+	* src/vsip/opt/simd/expr_evaluator.hpp: Bump copyright.
+	* src/vsip/opt/simd/expr_iterator.hpp: Pre-splat scalar constants
+	  into SIMD reg.
+	* src/vsip/opt/diag/eval.hpp: Handle scalar expressions.
+	* src/vsip/opt/expr/serial_evaluator.hpp: Skip transpose evaluator
+	  on non-transpose type conversions.
+	* configure.ac: Fix bug in SAL cfg defines.
+	* benchmarks/memwrite.cpp: Add diag.
+
 2007-08-09  Jules Bergmann  <jules@codesourcery.com>
 
 	* vendor/GNUmakefile.inc.in: Add missing INSTALL -d's.
Index: src/vsip/vector.hpp
===================================================================
--- src/vsip/vector.hpp	(revision 176624)
+++ src/vsip/vector.hpp	(working copy)
@@ -232,13 +232,15 @@
 
   Vector& operator=(const_reference_type val) VSIP_NOTHROW
   {
-    vsip::impl::Block_fill<1, Block>::exec(this->block(), val);
+    impl::Scalar_block<1, T> scalar(val);
+    impl::assign<1>(this->block(), scalar);
     return *this;
   }
   template <typename T0>
   Vector& operator=(T0 const& val) VSIP_NOTHROW
   {
-    vsip::impl::Block_fill<1, Block>::exec(this->block(), val);
+    impl::Scalar_block<1, T0> scalar(val);
+    impl::assign<1>(this->block(), scalar);
     return *this;
   }
   template <typename T0, typename Block0>
Index: src/vsip/matrix.hpp
===================================================================
--- src/vsip/matrix.hpp	(revision 176624)
+++ src/vsip/matrix.hpp	(working copy)
@@ -244,13 +244,15 @@
 
   Matrix& operator=(const_reference_type val) VSIP_NOTHROW
   {
-    vsip::impl::Block_fill<2, Block>::exec(this->block(), val);
+    impl::Scalar_block<2, T> scalar(val);
+    impl::assign<2>(this->block(), scalar);
     return *this;
   }
   template <typename T0>
   Matrix& operator=(T0 const& val) VSIP_NOTHROW
   {
-    vsip::impl::Block_fill<2, Block>::exec(this->block(), val);
+    impl::Scalar_block<2, T0> scalar(val);
+    impl::assign<2>(this->block(), scalar);
     return *this;
   }
   template <typename T0, typename Block0>
Index: src/vsip/opt/sal/is_op_supported.hpp
===================================================================
--- src/vsip/opt/sal/is_op_supported.hpp	(revision 178911)
+++ src/vsip/opt/sal/is_op_supported.hpp	(working copy)
@@ -162,6 +162,9 @@
 VSIP_IMPL_OP1SUP(copy_token,    split_float,      complex<float>*);
 VSIP_IMPL_OP1SUP(copy_token,    complex<float>*,  split_float);
 
+VSIP_IMPL_OP1SUP(copy_token,    unsigned long*,   float*);
+VSIP_IMPL_OP1SUP(copy_token,    unsigned short*,  float*);
+
 VSIP_IMPL_OP1SUP(Cast_closure<long          >::Cast, float*, long*);
 VSIP_IMPL_OP1SUP(Cast_closure<short         >::Cast, float*, short*);
 VSIP_IMPL_OP1SUP(Cast_closure<char          >::Cast, float*, char*);
Index: src/vsip/opt/sal/elementwise.hpp
===================================================================
--- src/vsip/opt/sal/elementwise.hpp	(revision 178911)
+++ src/vsip/opt/sal/elementwise.hpp	(working copy)
@@ -111,6 +111,25 @@
 
 
 
+// type conversion (vector) -> vector
+
+#define VSIP_IMPL_SAL_V_CONVERT(FCN, ST, DT, SALFCN)			\
+VSIP_IMPL_SAL_INLINE void						\
+FCN(									\
+  Sal_vector<ST> const& A,						\
+  Sal_vector<DT> const& Z,						\
+  length_type len)							\
+{									\
+  VSIP_IMPL_COVER_FCN("SAL_V_CONVERT", SALFCN)				\
+  SALFCN(A.ptr, A.stride, Z.ptr, Z.stride,				\
+	 0 /* scale 1.0 */, 0 /* bias 0.0 */,				\
+	 len, SAL_ROUND_ZERO, 0);					\
+}
+
+VSIP_IMPL_SAL_V_CONVERT(vcopy, unsigned long,  float, vconvert_u32_f32x)
+VSIP_IMPL_SAL_V_CONVERT(vcopy, unsigned short, float, vconvert_u16_f32x)
+
+
 // (complex vector) -> complex vector
 
 #define VSIP_IMPL_SAL_CV(FCN, T, SALFCN)				\
Index: src/vsip/opt/simd/expr_evaluator.hpp
===================================================================
--- src/vsip/opt/simd/expr_evaluator.hpp	(revision 177792)
+++ src/vsip/opt/simd/expr_evaluator.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
Index: src/vsip/opt/simd/expr_iterator.hpp
===================================================================
--- src/vsip/opt/simd/expr_iterator.hpp	(revision 178505)
+++ src/vsip/opt/simd/expr_iterator.hpp	(working copy)
@@ -470,16 +470,18 @@
   typedef T value_type;
   typedef typename Simd_traits<value_type>::simd_type simd_type;
 
-  Proxy(value_type value) : value_(value) {}
+  Proxy(value_type value)
+    : value_(Simd_traits<value_type>::load_scalar_all(value))
+  {}
 
   simd_type load() const 
-  { return Simd_traits<value_type>::load_scalar_all(value_);}
+  { return value_; }
 
-  void increment(length_type) {}
+  void increment(length_type = 1) {}
   void increment_by_element(length_type) {}
 
 private:
-  value_type value_;
+  simd_type value_;
 };
 
 // Proxy for unary expressions.
Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 178911)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -106,17 +106,19 @@
 // Helper class to determine the block type of a view.  Handles non-view
 // types (which occur in simple expressions, such as A = 5).
 
-template <typename ViewT>
+template <dimension_type Dim,
+	  typename       T>
 struct Block_of
 {
-  typedef Unknown_type type;
-  static type block(ViewT) { return type(); }
+  typedef Scalar_block<Dim, T> type;
+  static type block(T val) { return type(val); }
 };
 
-template <template <typename, typename> class View,
+template <dimension_type Dim,
+	  template <typename, typename> class View,
 	  typename T,
 	  typename BlockT>
-struct Block_of<View<T, BlockT> >
+struct Block_of<Dim, View<T, BlockT> >
 {
   typedef BlockT type;
   static type& block(View<T, BlockT> view) { return view.block(); }
@@ -620,18 +622,18 @@
   DstViewT dst,
   SrcViewT src)
 {
-  typedef typename diag_detail::Block_of<DstViewT>::type dst_block_type;
-  typedef typename diag_detail::Block_of<SrcViewT>::type src_block_type;
+  dimension_type const dim = DstViewT::dim;
+
+  typedef typename diag_detail::Block_of<dim, DstViewT>::type dst_block_type;
+  typedef typename diag_detail::Block_of<dim, SrcViewT>::type src_block_type;
   using vsip::impl::diag_detail::Diag_eval_list_helper;
 
-  dimension_type const dim = DstViewT::dim;
-
   std::cout << "diagnose_eval_list" << std::endl
 	    << "  dst expr: " << typeid(dst_block_type).name() << std::endl
 	    << "  src expr: " << typeid(src_block_type).name() << std::endl;
   Diag_eval_list_helper<dim, dst_block_type, src_block_type, TagList>
-    ::exec(diag_detail::Block_of<DstViewT>::block(dst),
-	   diag_detail::Block_of<SrcViewT>::block(src));
+    ::exec(diag_detail::Block_of<dim, DstViewT>::block(dst),
+	   diag_detail::Block_of<dim, SrcViewT>::block(src));
 }
 
 
Index: src/vsip/opt/expr/serial_evaluator.hpp
===================================================================
--- src/vsip/opt/expr/serial_evaluator.hpp	(revision 176624)
+++ src/vsip/opt/expr/serial_evaluator.hpp	(working copy)
@@ -161,6 +161,9 @@
   typedef typename Block_layout<DstBlock>::order_type dst_order_type;
 
   static bool const ct_valid =
+    // Skip evaluator if expression is non-transpose type-conversion
+    !(! Type_equal<src_value_type, dst_value_type>::value &&
+        Type_equal<src_order_type, dst_order_type>::value) &&
     !is_rhs_expr &&
     lhs_cost == 0 && rhs_cost == 0 &&
     !is_lhs_split && !is_rhs_split;
Index: scripts/config
===================================================================
--- scripts/config	(revision 173072)
+++ scripts/config	(working copy)
@@ -244,7 +244,82 @@
     par_64_refimpl_release    = Par64RefImplRelease
 
 
+class MondoTestSerial(Package):
 
+    class Ser32IntelDebug(Configuration):
+	builtin_libdir = 'ia32'
+	libdir = 'ia32/ser-intel-debug'
+        suffix = '-ser-intel-32-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug + m32),
+                   'CFLAGS="%s"'%' '.join(m32),
+                   'FFLAGS="%s"'%' '.join(m32),
+                   'LDFLAGS="%s"'%' '.join(m32),
+                   '--with-g2c-copy=%s'%g2c32,
+                   '--with-ipp-prefix=%s/ia32_itanium'%ipp_dir,
+	           '--enable-fft=ipp,builtin'
+		  ] + builtin_fft_32_opts + mkl_32 + nompi + common_32 + simd
+
+    class Ser64IntelRelease(Configuration):
+	builtin_libdir = 'em64t'
+	libdir         = 'em64t/ser-intel'
+        suffix = '-ser-intel-64'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_generic),
+                   '--with-g2c-copy=%s'%g2c64,
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir,
+	           '--enable-fft=ipp,builtin'
+		  ] + builtin_fft_em64t_opts + mkl_64 + nompi + common_64 + simd
+
+    class Ser64IntelDebug(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/ser-intel-debug'
+        suffix = '-ser-intel-64-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   '--with-g2c-copy=%s'%g2c64,
+                   '--with-ipp-prefix=%s/em64t'%ipp_dir,
+	           '--enable-fft=ipp,builtin'
+		  ] + builtin_fft_em64t_opts + mkl_64 + nompi + common_64 + simd
+
+    class Ser32BuiltinRelease(Configuration):
+	builtin_libdir = 'ia32'
+	libdir = 'ia32/ser-builtin'
+        suffix = '-ser-builtin-32'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_32_p4sse2),
+                   'CFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   'FFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   'LDFLAGS="%s"'%' '.join(flags_32_p4sse2),
+                   '--with-g2c-copy=%s'%g2c32
+                  ] + builtin_fft_32 + builtin_lapack_32 + nompi + common_32 + simd
+
+    class SerEM64TBuiltinRelease(Configuration):
+	builtin_libdir = 'em64t'
+	libdir         = 'em64t/ser-builtin'
+        suffix = '-ser-builtin-em64t'
+        options = ['CXXFLAGS="%s"'%' '.join(release + flags_64_em64t),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_em64t + builtin_lapack_em64t + nompi + common_64 + simd
+
+    class SerEM64TBuiltinDebug(Configuration):
+	builtin_libdir = 'em64t'
+	libdir = 'em64t/ser-builtin-debug'
+        suffix = '-ser-builtin-em64t-debug'
+        options = ['CXXFLAGS="%s"'%' '.join(debug),
+                   '--with-g2c-copy=%s'%g2c64,
+                  ] + builtin_fft_em64t + builtin_lapack_em64t + nompi + common_64 + simd
+
+
+    suffix = '-linux'
+    host = 'x86'
+  
+    ser_32_intel_debug        = Ser32IntelDebug
+    ser_64_intel_release      = Ser64IntelRelease
+    ser_64_intel_debug        = Ser64IntelDebug
+
+    ser_32_builtin_release    = Ser32BuiltinRelease
+    ser_em64t_builtin_release = SerEM64TBuiltinRelease
+    ser_em64t_builtin_debug   = SerEM64TBuiltinDebug
+
+
+
 # Binary package for C-VSIP backends.
 #
 # This binary package is for test purposes only.  It depends on
Index: scripts/datasheet.pl
===================================================================
--- scripts/datasheet.pl	(revision 178911)
+++ scripts/datasheet.pl	(working copy)
@@ -279,8 +279,8 @@
 report_func($db, "vmul-31-1", "vmul: vector multiply IP (Z *= A) (float)");
 report_func($db, "svmul-1-1", "svmul: scalar-vector multiply (Z = a * B) (float)");
 
-report_func($db, "sal-vmul-11-1", "vmul (vendor-SAL): scalar-vector multiply (Z = a * B) (float)");
-report_func($db, "sal-vmul-31-1", "vmul (vendor-SAL): vector multiply IP (Z *= A) (float)");
+report_func($db, "sal-vmul-11-1", "vmul (vendor-SAL): scalar-vector multiply (Z = a * B) (float)", optional => 1);
+report_func($db, "sal-vmul-31-1", "vmul (vendor-SAL): vector multiply IP (Z *= A) (float)", optional => 1);
 
 # VTHRESH
 header();
@@ -299,10 +299,10 @@
 
 header();
 
-report_func($db, "sal-vthresh-1-1", "vthresh (vendor-SAL): vthreshx (Z = ite(A >= b, A, 0)) (float)");
-report_func($db, "sal-vthresh-2-1", "vthresh (vendor-SAL): vthrx (Z = ite(A >= b, A, b)) (float)");
+report_func($db, "sal-vthresh-1-1", "vthresh (vendor-SAL): vthreshx (Z = ite(A >= b, A, 0)) (float)", optional => 1);
+report_func($db, "sal-vthresh-2-1", "vthresh (vendor-SAL): vthrx (Z = ite(A >= b, A, b)) (float)", optional => 1);
 
-report_func($db, "sal-lvgt-1-1", "vthresh (vendor-SAL): lvgtx (Z = ite(A > B, 1, 0)) (float)");
-report_func($db, "sal-lvgt-2-1", "vthresh (vendor-SAL): lvgtx/vmul (Z = ite(A > B, A, 0)) (float)");
+report_func($db, "sal-lvgt-1-1", "vthresh (vendor-SAL): lvgtx (Z = ite(A > B, 1, 0)) (float)", optional => 1);
+report_func($db, "sal-lvgt-2-1", "vthresh (vendor-SAL): lvgtx/vmul (Z = ite(A > B, A, 0)) (float)", optional => 1);
 
 close(OUT);
Index: configure.ac
===================================================================
--- configure.ac	(revision 178911)
+++ configure.ac	(working copy)
@@ -1603,9 +1603,9 @@
     else
       AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SAL, 1,
         [Define to set whether or not to use Mercury's SAL library.])
-      AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SAL_FLOAT, 1,
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SAL_FLOAT, $sal_have_float,
         [Define if Mercury's SAL library provides float support.])
-      AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SAL_DOUBLE, 1,
+      AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SAL_DOUBLE, $sal_have_double,
         [Define if Mercury's SAL library provides double support.])
     fi
 
Index: benchmarks/memwrite.cpp
===================================================================
--- benchmarks/memwrite.cpp	(revision 173215)
+++ benchmarks/memwrite.cpp	(working copy)
@@ -20,6 +20,7 @@
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
 #include <vsip/opt/profile.hpp>
+#include <vsip/opt/diag/eval.hpp>
 
 #include <vsip_csl/test.hpp>
 #include "loop.hpp"
@@ -49,16 +50,28 @@
     
     vsip::impl::profile::Timer t1;
     
+    marker1_start();
     t1.start();
     for (index_type l=0; l<loop; ++l)
       view = val;
     t1.stop();
+    marker1_stop();
 
     for(index_type i=0; i<size; ++i)
       test_assert(equal(view.get(i), val));
     
     time = t1.delta();
   }
+
+  void diag()
+  {
+    length_type const size = 256;
+
+    Vector<T>   view(size, T());
+    T           val = T(1);
+
+    vsip::impl::diagnose_eval_list_std(view, val);
+  }
 };
 
 
