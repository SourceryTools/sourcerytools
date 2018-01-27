Index: ChangeLog
===================================================================
--- ChangeLog	(revision 146322)
+++ ChangeLog	(working copy)
@@ -1,3 +1,58 @@
+2006-08-01  Jules Bergmann  <jules@codesourcery.com>
+
+	Update SIMD handling to allow both generic functions and loop fusion.
+	* src/vsip/impl/expr_serial_dispatch_fwd.hpp (Simd_loop_fusion_tag):
+	  New dispatch tag for SIMD loop fusion.
+	* src/vsip/impl/simd/expr_evaluator.hpp: Use new Simd_loop_fusion_tag.
+	* src/vsip/impl/expr_serial_dispatch.hpp: Update to include both
+	  SIMD loop fusion and SIMD generic routines.
+	* src/vsip/impl/expr_serial_evaluator.hpp: Add Simd_loop_fusion_tag.
+	  Rename Simd_tag to Simd_builtin_tag.
+	* configure.ac: Rename '--with-simd=WHAT' option to
+	  '--with-builtin-simd-routines=WHAT'.  Add new option for
+	  SIMD loop fusion '--enable-simd-loop-fusion'.
+	* examples/mercury/mcoe-setup.sh: Update to control SIMD generic
+	  routines and SIMD loop fusion.
+
+	Update SIMD support for Altivec, add new routines for logic ops
+	* src/vsip/impl/simd/simd.hpp: Enable altivec traits classes
+	  when using GreenHills.  Add altivec classes for signed char
+	  and float.  Add SSE traits classes for signed char and int.
+	  Add functions for binary operations and packing.
+	* src/vsip/impl/simd/vadd.hpp: New file, generic SIMD addition.
+	* src/vsip/impl/simd/vadd.cpp: New file, generic SIMD addition.
+	* src/vsip/impl/simd/vgt.hpp: New file, generic SIMD gt().
+	* src/vsip/impl/simd/vgt.cpp: New file, generic SIMD gt().
+	* src/vsip/impl/simd/vlogic.hpp: New file, generic SIMD logic ops.
+	* src/vsip/impl/simd/vlogic.cpp: New file, generic SIMD logic ops.
+	* src/vsip/impl/simd/eval-generic.hpp: Dispatch to new add, gt,
+	  and logic operations.
+	* src/vsip/GNUmakefile.inc.in: Add cpp files for new generic SIMD ops.
+	* tests/coverage_common.hpp: Support boolean data.
+	* tests/coverage_binary.cpp: Add coverage for bxor, land, lor, lxor.
+	* tests/coverage_unary.cpp: Add coverage for bnot, lnot.
+
+	Optimize distributed get() performance.
+	* src/vsip/impl/distributed-block.hpp: Optimize get() to avoid
+	  communication when program is single-processor, or when block
+	  is globally replicated.
+	* src/vsip/map_fwd.hpp: Add forward defs for Replicated_map.
+
+	Misc fixes and updates.
+	* src/vsip/impl/profile.hpp: Add is_zero() function to timer
+	  policies.
+	* src/vsip/profile.cpp: Use is_zero().
+	* src/vsip/impl/fft/util.hpp: Fix Wall warning
+	* src/vsip_csl/GNUmakefile.inc.in: Revert change that removed
+	  src_vsip_csl_cxx_sources from cxx_sources.  Necessary for
+	  dependencies.
+	* vendor/GNUmakefile.inc.in: Un-revert change to FFTW rules.
+	* benchmarks/create_map.hpp: New file, common functions to create
+	  maps for benchmarks.
+	* benchmarks/vmul.cpp: Add coverage for scalar-vector multiply
+	  when scalar is a literal value and when constant is generated
+	  with 'get()' from coeff view.
+
 2006-08-04  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/impl/expr_ops_per_point.hpp: New file, expression
Index: src/vsip/profile.cpp
===================================================================
--- src/vsip/profile.cpp	(revision 146321)
+++ src/vsip/profile.cpp	(working copy)
@@ -134,7 +134,7 @@
   if (mode_ == pm_trace)
   {
     // Obtain a stamp if one is not provided.
-    if (stamp == stamp_type())
+    if (TP::is_zero(stamp))
       TP::sample(stamp);
 
     count_++;
@@ -144,7 +144,7 @@
   else if (mode_ == pm_accum)
   {
     // Obtain a stamp if one is not provided.
-    if (stamp == stamp_type())
+    if (TP::is_zero(stamp))
       TP::sample(stamp);
 
     accum_type::iterator pos = accum_.find(name);
Index: src/vsip/impl/fft/util.hpp
===================================================================
--- src/vsip/impl/fft/util.hpp	(revision 146321)
+++ src/vsip/impl/fft/util.hpp	(working copy)
@@ -98,7 +98,7 @@
 struct description
 { 
   static std::string tag(Domain<D> const &dom, int dir, 
-    return_mechanism_type rm)
+			 return_mechanism_type /*rm*/)
   {
     length_type cols = 1;
     length_type rows = dom[0].size();
Index: src/vsip/impl/expr_serial_dispatch_fwd.hpp
===================================================================
--- src/vsip/impl/expr_serial_dispatch_fwd.hpp	(revision 146321)
+++ src/vsip/impl/expr_serial_dispatch_fwd.hpp	(working copy)
@@ -28,14 +28,18 @@
 {
 
 /// The list of evaluators to be tried, in that specific order.
-typedef Make_type_list<VSIP_IMPL_SIMD_TAG_LIST
-		       Intel_ipp_tag,
+
+/// Note that the VSIP_IMPL_TAG_LIST macro will include its own comma.
+
+typedef Make_type_list<Intel_ipp_tag,
 		       Transpose_tag,
                        Mercury_sal_tag,
+                       VSIP_IMPL_SIMD_TAG_LIST
 #if VSIP_IMPL_ENABLE_EVAL_DENSE_EXPR
 		       Dense_expr_tag,
 #endif
 		       Copy_tag,
+		       Simd_loop_fusion_tag,
 		       Loop_fusion_tag>::type LibraryTagList;
 
 
Index: src/vsip/impl/simd/vadd.cpp
===================================================================
--- src/vsip/impl/simd/vadd.cpp	(revision 0)
+++ src/vsip/impl/simd/vadd.cpp	(revision 0)
@@ -0,0 +1,78 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/simd/vadd.cpp
+    @author  Jules Bergmann
+    @date    2006-06-08
+    @brief   VSIPL++ Library: SIMD element-wise vector multiplication.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/simd/vadd.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace simd
+{
+
+#if !VSIP_IMPL_INLINE_LIBSIMD
+
+template <typename T>
+void
+vadd(
+  T*  op1,
+  T*  op2,
+  T*  res,
+  int size)
+{
+  static bool const Is_vectorized = Is_algorithm_supported<T, false, Alg_vadd>
+                                      ::value;
+  Simd_vadd<T, Is_vectorized>::exec(op1, op2, res, size);
+}
+
+template void vadd(short*, short*, short*, int);
+template void vadd(float*, float*, float*, int);
+template void vadd(double*, double*, double*, int);
+template void vadd(std::complex<float>*, std::complex<float>*,
+		   std::complex<float>*, int);
+template void vadd(std::complex<double>*, std::complex<double>*,
+		   std::complex<double>*, int);
+
+
+
+template <typename T>
+void
+vadd(
+  std::pair<T*,T*>  op1,
+  std::pair<T*,T*>  op2,
+  std::pair<T*,T*>  res,
+  int size)
+{
+  static bool const Is_vectorized = Is_algorithm_supported<T, true, Alg_vadd>
+                                      ::value;
+  Simd_vadd<std::pair<T,T>, Is_vectorized>::exec(op1, op2, res, size);
+}
+
+template void vadd(std::pair<float*,float*>,
+		   std::pair<float*,float*>,
+		   std::pair<float*,float*>, int);
+template void vadd(std::pair<double*,double*>,
+		   std::pair<double*,double*>,
+		   std::pair<double*,double*>, int);
+
+#endif
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
Index: src/vsip/impl/simd/vgt.cpp
===================================================================
--- src/vsip/impl/simd/vgt.cpp	(revision 0)
+++ src/vsip/impl/simd/vgt.cpp	(revision 0)
@@ -0,0 +1,52 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/simd/vgt.cpp
+    @author  Jules Bergmann
+    @date    2006-07-26
+    @brief   VSIPL++ Library: SIMD element-wise vector greater-than.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/simd/vgt.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace simd
+{
+
+#if !VSIP_IMPL_INLINE_LIBSIMD
+
+template <typename T>
+void
+vgt(
+  T const* op1,
+  T const* op2,
+  bool*    res,
+  int      size)
+{
+  static bool const Is_vectorized = Is_algorithm_supported<T, false, Alg_vgt>
+                                      ::value;
+  Simd_vgt<T, Is_vectorized>::exec(op1, op2, res, size);
+}
+
+template void vgt(float const*, float const*, bool*, int);
+
+
+
+#endif
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
Index: src/vsip/impl/simd/simd.hpp
===================================================================
--- src/vsip/impl/simd/simd.hpp	(revision 146321)
+++ src/vsip/impl/simd/simd.hpp	(working copy)
@@ -14,9 +14,14 @@
   Included Files
 ***********************************************************************/
 
-#if defined(__VEC__) && !_TARGET_MC
-// #   define VSIPL_IMPL_SIMD_ALTIVEC
-// #   include <altivec.h>
+#if __VEC__
+#  define VSIPL_IMPL_SIMD_ALTIVEC
+#  if !_MC_EXEC
+#    include <altivec.h>
+#    undef vector
+#    undef pixel
+#    undef bool
+#  endif
 #else
 #  if defined(__SSE__)
 #    include <xmmintrin.h>
@@ -25,6 +30,7 @@
 #endif
 
 #include <complex>
+#include <cassert>
 
 
 
@@ -59,7 +65,7 @@
 //
 // Types:
 //  - value_type - base type (or element type) of SIMD vector
-//  - simd_type - SIMD vector type
+//  - simd_type  - SIMD vector type
 //
 // Alignment Utilities
 //  - alignment_of    - returns 0 if address is aligned, returns
@@ -77,12 +83,27 @@
 //  - sub             - subtract two SIMD vectors
 //  - mul             - multiply two SIMD vectors together
 //
+// Logic Operations:
+//  - band            - bitwise-and two SIMD vectors
+//  - bor             - bitwise-or two SIMD vectors
+//  - bxor            - bitwise-xor two SIMD vectors
+//  - bnot            - bitwise-negation of one SIMD vector
+//
 // Shuffle Operations
 //  - extend                    - extend value in pos 0 to entire SIMD vector.
 //  - real_from_interleaved     - create real SIMD from two interleaved SIMDs
 //  - imag_from_interleaved     - create imag SIMD from two interleaved SIMDs
 //  - interleaved_lo_from_split -
 //  - interleaved_hi_from_split -
+//  - pack                      - pack 2 SIMD vectors into 1, reducing range
+//
+// Architecture/Compiler Notes
+//  - GCC support for Intel SSE is good (3.4, 4.0, 4.1 all work)
+//  - GCC 3.4 is broken for Altivec
+//     - typedefs of vector types are not supported within a struct
+//       (top-level typedefs work fine).
+//  - GHS support for Altivec is good.
+//     - peculiar about order: __vector must come first.
 // -------------------------------------------------------------------- //
 template <typename T>
 struct Simd_traits;
@@ -106,6 +127,9 @@
   static simd_type load(value_type const* addr)
   { return *addr; }
 
+  static simd_type load_scalar_all(value_type value)
+  { return value; }
+
   static void store(value_type* addr, simd_type const& vec)
   { *addr = vec; }
 
@@ -118,47 +142,358 @@
   static simd_type div(simd_type const& v1, simd_type const& v2)
   { return v1 / v2; }
 
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return v1 & v2; }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return v1 | v2; }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return v1 ^ v2; }
+
+  static simd_type bnot(simd_type const& v1)
+  { return ~v1; }
+
+  static simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return (v1 > v2) ? simd_type(1) : simd_type(0); }
+
+  static simd_type pack(simd_type const&, simd_type const&)
+  { assert(0); }
+
   static void enter() {}
   static void exit()  {}
 };
 
 
 
+// Not all compilers support typedefs with altivec vector types:
+// As of 20060727:
+//  - Greenhills supports vector typedefs.
+//  - GCC 3.4.4 does not
+
 #ifdef VSIPL_IMPL_SIMD_ALTIVEC
+#  if __ghs__
+
+// PowerPC AltiVec - signed char
 template <>
-struct Simd_traits<short> {
-   typedef int simd_type __attribute__ ((__mode__(__V8HI__)));
-   // typedef vector signed short	simd_type;
+struct Simd_traits<signed char>
+{
+  typedef signed char          value_type;
+  typedef __vector signed char simd_type;
+  typedef __vector bool char   bool_simd_type;
    
+  static int  const vec_size  = 16;
+  static bool const is_accel  = true;
+  static int  const alignment = 16;
+
+  static int  const scalar_pos = vec_size-1;
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  { return (simd_type)(0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0 ); }
+
+  static simd_type load(value_type const* addr)
+  { return vec_ld(0, (value_type*)addr); }
+
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
+  static void store(value_type* addr, simd_type const& vec)
+  { vec_st(vec, 0, addr); }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return vec_add(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return vec_sub(v1, v2); }
+
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return vec_and(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return vec_or(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return vec_xor(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return vec_nor(v1, v1); }
+
+  static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return vec_cmpgt(v1, v2); }
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+
+
+// PowerPC AltiVec - signed short vector
+template <>
+struct Simd_traits<signed short>
+{
+  typedef signed short          value_type;
+  typedef __vector signed short simd_type;
+  typedef __vector bool short   bool_simd_type;
+  typedef __vector signed char  pack_simd_type;
+   
   static int const  vec_size = 8;
   static bool const is_accel = true;
   static int  const alignment = 16;
 
+  static int  const scalar_pos = vec_size-1;
+
   static intptr_t alignment_of(value_type const* addr)
   { return (intptr_t)addr & (alignment - 1); }
 
-   static simd_type load(value_type const* addr) {
-      vector short res;
-      res = vec_ld(0, (short*)addr);
-      return res;
-   }
+  static simd_type zero()
+  { return (simd_type)(0, 0, 0, 0,  0, 0, 0, 0); }
 
-   static void store(value_type* addr, simd_type const& vec) {
-      vec_st(vec, 0, (void*)addr);
-   }
+  static simd_type load(value_type const* addr)
+  { return vec_ld(0, (short*)addr); }
 
-   static simd_type add(simd_type const& v1, simd_type const& v2) {
-      return vec_add(v1, v2);
-   }
+  static void store(value_type* addr, simd_type const& vec)
+  { vec_st(vec, 0, addr); }
 
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return vec_add(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return vec_sub(v1, v2); }
+
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return vec_and(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return vec_or(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return vec_xor(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return vec_nor(v1, v1); }
+
+  static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return vec_cmpgt(v1, v2); }
+
+  static pack_simd_type pack(simd_type const& v1, simd_type const& v2)
+  { return vec_pack(v1, v2); }
+
   static void enter() {}
   static void exit()  {}
 };
+
+
+
+// PowerPC AltiVec - signed short vector
+template <>
+struct Simd_traits<signed int>
+{
+  typedef signed int            value_type;
+  typedef __vector signed int   simd_type;
+  typedef __vector bool int     bool_simd_type;
+  typedef __vector signed short pack_simd_type;
+   
+  static int const  vec_size = 4;
+  static bool const is_accel = true;
+  static int  const alignment = 16;
+
+  static int  const scalar_pos = vec_size-1;
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  { return (simd_type)(0, 0, 0, 0); }
+
+  static simd_type load(value_type const* addr)
+  { return vec_ld(0, (value_type*)addr); }
+
+  static void store(value_type* addr, simd_type const& vec)
+  { vec_st(vec, 0, addr); }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return vec_add(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return vec_sub(v1, v2); }
+
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return vec_and(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return vec_or(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return vec_xor(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return vec_nor(v1, v1); }
+
+  static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return vec_cmpgt(v1, v2); }
+
+  static pack_simd_type pack(simd_type const& v1, simd_type const& v2)
+  { return vec_pack(v1, v2); }
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+
+
+// PowerPC AltiVec - float vector
+template <>
+struct Simd_traits<float>
+{
+  typedef float             value_type;
+  typedef __vector float    simd_type;
+  typedef __vector bool int bool_simd_type;
+   
+  static int  const vec_size = 4;
+  static bool const is_accel = true;
+  static int  const alignment = 16;
+
+  static int  const scalar_pos = vec_size-1;
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  { return (simd_type)(0.f, 0.f, 0.f, 0.f); }
+
+  static simd_type load(value_type const* addr)
+  { return vec_ld(0, (value_type*)addr); }
+
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
+  static void store(value_type* addr, simd_type const& vec)
+  { vec_st(vec, 0, addr); }
+
+  static void store_stream(value_type* addr, simd_type const& vec)
+  { vec_st(vec, 0, addr); }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return vec_add(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return vec_sub(v1, v2); }
+
+  static simd_type mul(simd_type const& v1, simd_type const& v2)
+  { return vec_madd(v1, v2, zero()); }
+
+  static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return vec_cmpgt(v1, v2); }
+
+  static simd_type real_from_interleaved(simd_type const& v1,
+					 simd_type const& v2)
+  { return zero(); /* return _mm_shuffle_ps(v1, v2, 0x88); */ }
+
+  static simd_type imag_from_interleaved(simd_type const& v1,
+					 simd_type const& v2)
+  { return zero(); /* return _mm_shuffle_ps(v1, v2, 0xDD); */ }
+
+  static simd_type interleaved_lo_from_split(simd_type const& real,
+					     simd_type const& imag)
+  { return vec_mergel(real, imag); }
+
+  static simd_type interleaved_hi_from_split(simd_type const& real,
+					     simd_type const& imag)
+  { return vec_mergeh(real, imag); }
+
+  static void enter() {}
+  static void exit()  {}
+};
+#  endif
 #endif
 
+
+
 #ifdef __SSE__
-#if 0
 template <>
+struct Simd_traits<signed char> {
+  typedef signed char	value_type;
+  typedef __m128i	simd_type;
+   
+  static int const  vec_size = 16;
+  static bool const is_accel = true;
+  static int  const alignment = 16;
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  { return _mm_setzero_si128(); }
+
+  static simd_type load(value_type* addr)
+  { return _mm_load_si128((simd_type*)addr); }
+
+  static simd_type load_scalar(value_type value)
+  { return _mm_set_epi8(value, 0, 0, 0, 0, 0, 0, 0,
+			0, 0, 0, 0, 0, 0, 0, 0); }
+
+  static simd_type load_scalar_all(value_type value)
+  { return _mm_set1_epi8(value); }
+
+  static void store(value_type* addr, simd_type const& vec)
+  { _mm_store_si128((simd_type*)addr, vec); }
+
+  static void store_stream(value_type* addr, simd_type const& vec)
+  { _mm_store_si128((simd_type*)addr, vec); }
+  // { __builtin_ia32_movntps((simd_type*)addr, vec); }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return _mm_add_epi8(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return _mm_sub_epi8(v1, v2); }
+
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return _mm_and_si128(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return _mm_or_si128(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return _mm_xor_si128(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return bxor(v1, load_scalar_all(0xFF)); }
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+
+
+template <>
 struct Simd_traits<short> {
   typedef short		value_type;
   typedef __m128i	simd_type;
@@ -195,10 +530,22 @@
   static simd_type sub(simd_type const& v1, simd_type const& v2)
   { return _mm_sub_epi16(v1, v2); }
 
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return _mm_and_si128(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return _mm_or_si128(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return _mm_xor_si128(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return bxor(v1, load_scalar_all(0xFFFF)); }
+
+#if 0
   static simd_type mul(simd_type const& v1, simd_type const& v2)
   { return _mm_mul_epi16(v1, v2); }
 
-#if 0
   static simd_type extend(simd_type const& v)
   { return _mm_shuffle_ps(v, v, 0x00); }
 
@@ -219,12 +566,97 @@
 					     simd_type const& imag)
   { return _mm_unpackhi_epi16(real, imag); }
 
+  static simd_type pack(simd_type const& v1, simd_type const& v2)
+  { return _mm_packs_epi16(v1, v2); }
+
   static void enter() {}
   static void exit()  {}
 };
+
+
+
+template <>
+struct Simd_traits<int> {
+  typedef int		value_type;
+  typedef __m128i	simd_type;
+   
+  static int const  vec_size = 4;
+  static bool const is_accel = true;
+  static int  const alignment = 16;
+
+  static intptr_t alignment_of(value_type const* addr)
+  { return (intptr_t)addr & (alignment - 1); }
+
+  static simd_type zero()
+  { return _mm_setzero_si128(); }
+
+  static simd_type load(value_type const* addr)
+  { return _mm_load_si128((simd_type*)addr); }
+
+  static simd_type load_scalar(value_type value)
+  { return _mm_set1_epi32(value); }
+
+  static simd_type load_scalar_all(value_type value)
+  { return _mm_set1_epi32(value); }
+
+  static void store(value_type* addr, simd_type const& vec)
+  { _mm_store_si128((simd_type*)addr, vec); }
+
+  static void store_stream(value_type* addr, simd_type const& vec)
+  { _mm_store_si128((simd_type*)addr, vec); }
+  // { __builtin_ia32_movntps((simd_type*)addr, vec); }
+
+  static simd_type add(simd_type const& v1, simd_type const& v2)
+  { return _mm_add_epi32(v1, v2); }
+
+  static simd_type sub(simd_type const& v1, simd_type const& v2)
+  { return _mm_sub_epi32(v1, v2); }
+
+  static simd_type band(simd_type const& v1, simd_type const& v2)
+  { return _mm_and_si128(v1, v2); }
+
+  static simd_type bor(simd_type const& v1, simd_type const& v2)
+  { return _mm_or_si128(v1, v2); }
+
+  static simd_type bxor(simd_type const& v1, simd_type const& v2)
+  { return _mm_xor_si128(v1, v2); }
+
+  static simd_type bnot(simd_type const& v1)
+  { return bxor(v1, load_scalar_all(0xFFFFFFFF)); }
+
+#if 0
+  static simd_type mul(simd_type const& v1, simd_type const& v2)
+  { return _mm_mul_epi32(v1, v2); }
+
+  static simd_type extend(simd_type const& v)
+  { return _mm_shuffle_ps(v, v, 0x00); }
+
+  static simd_type real_from_interleaved(simd_type const& v1,
+					 simd_type const& v2)
+  { return _mm_shuffle_ps(v1, v2, 0x88); }
+
+  static simd_type imag_from_interleaved(simd_type const& v1,
+					 simd_type const& v2)
+  { return _mm_shuffle_ps(v1, v2, 0xDD); }
 #endif
 
+  static simd_type interleaved_lo_from_split(simd_type const& real,
+					     simd_type const& imag)
+  { return _mm_unpacklo_epi32(real, imag); }
 
+  static simd_type interleaved_hi_from_split(simd_type const& real,
+					     simd_type const& imag)
+  { return _mm_unpackhi_epi32(real, imag); }
+
+  static simd_type pack(simd_type const& v1, simd_type const& v2)
+  { return _mm_packs_epi32(v1, v2); }
+
+  static void enter() {}
+  static void exit()  {}
+};
+
+
+
 template <>
 struct Simd_traits<float> {
   typedef float		value_type;
@@ -274,6 +706,12 @@
   static simd_type div(simd_type const& v1, simd_type const& v2)
   { return _mm_div_ps(v1, v2); }
 
+  static simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return _mm_cmpgt_ps(v1, v2); }
+
+  static int sign_mask(simd_type const& v1)
+  { return _mm_movemask_ps(v1); }
+
   static simd_type extend(simd_type const& v)
   { return _mm_shuffle_ps(v, v, 0x00); }
 
@@ -348,6 +786,12 @@
   static simd_type div(simd_type const& v1, simd_type const& v2)
   { return _mm_div_pd(v1, v2); }
 
+  static simd_type gt(simd_type const& v1, simd_type const& v2)
+  { return _mm_cmpgt_pd(v1, v2); }
+
+  static int sign_mask(simd_type const& v1)
+  { return _mm_movemask_pd(v1); }
+
   static simd_type extend(simd_type const& v)
   { return _mm_shuffle_pd(v, v, 0x0); }
 
@@ -376,8 +820,18 @@
 
 
 struct Alg_none;
+struct Alg_vadd;
 struct Alg_vmul;
 struct Alg_rscvmul;	// (scalar real * complex vector)
+struct Alg_vgt;
+struct Alg_vland;
+struct Alg_vlor;
+struct Alg_vlxor;
+struct Alg_vlnot;
+struct Alg_vband;
+struct Alg_vbor;
+struct Alg_vbxor;
+struct Alg_vbnot;
 
 template <typename T,
 	  bool     IsSplit,
Index: src/vsip/impl/simd/vadd.hpp
===================================================================
--- src/vsip/impl/simd/vadd.hpp	(revision 0)
+++ src/vsip/impl/simd/vadd.hpp	(revision 0)
@@ -0,0 +1,296 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/simd/vadd.hpp
+    @author  Jules Bergmann
+    @date    2006-06-08
+    @brief   VSIPL++ Library: SIMD element-wise vector addition.
+
+*/
+
+#ifndef VSIP_IMPL_SIMD_VADD_HPP
+#define VSIP_IMPL_SIMD_VADD_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <complex>
+
+#include <vsip/impl/simd/simd.hpp>
+#include <vsip/impl/metaprogramming.hpp>
+
+#define VSIP_IMPL_INLINE_LIBSIMD 0
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace simd
+{
+
+// Define value_types for which vadd is optimized.
+//  - float
+//  - double
+//  - complex<float>
+//  - complex<double>
+
+template <typename T,
+	  bool     IsSplit>
+struct Is_algorithm_supported<T, IsSplit, Alg_vadd>
+{
+  typedef typename Scalar_of<T>::type scalar_type;
+  static bool const value =
+    Simd_traits<scalar_type>::is_accel &&
+    (Type_equal<scalar_type, float>::value ||
+     Type_equal<scalar_type, double>::value);
+};
+
+
+
+// Class for vadd - vector element-wise addition.
+
+template <typename T,
+	  bool     Is_vectorized>
+struct Simd_vadd;
+
+
+
+// Generic, non-vectorized implementation of vector element-wise addition.
+
+template <typename T>
+struct Simd_vadd<T, false>
+{
+  static void exec(T* A, T* B, T* R, int n)
+  {
+    while (n)
+    {
+      *R = *A + *B;
+      R++; A++; B++;
+      n--;
+    }
+  }
+};
+
+
+
+// Vectorized implementation of vector element-wise addition for scalars
+// (float, double, etc).
+
+template <typename T>
+struct Simd_vadd<T, true>
+{
+  static void exec(T* A, T* B, T* R, int n)
+  {
+    typedef Simd_traits<T> simd;
+    typedef typename simd::simd_type simd_type;
+
+    // handle mis-aligned vectors
+    if (simd::alignment_of(R) != simd::alignment_of(A) ||
+	simd::alignment_of(R) != simd::alignment_of(B))
+    {
+      // PROFILE
+      while (n)
+      {
+	*R = *A + *B;
+	R++; A++; B++;
+	n--;
+      }
+      return;
+    }
+
+    // clean up initial unaligned values
+    while (simd::alignment_of(A) != 0)
+    {
+      *R = *A + *B;
+      R++; A++; B++;
+      n--;
+    }
+  
+    if (n == 0) return;
+
+    simd_type reg0;
+    simd_type reg1;
+    simd_type reg2;
+    simd_type reg3;
+
+    simd::enter();
+
+    while (n >= 2*simd::vec_size)
+    {
+      n -= 2*simd::vec_size;
+
+      reg0 = simd::load(A);
+      reg1 = simd::load(B);
+      
+      reg2 = simd::load(A + simd::vec_size);
+      reg3 = simd::load(B + simd::vec_size);
+      
+      reg1 = simd::add(reg0, reg1);
+      reg3 = simd::add(reg2, reg3);
+      
+      simd::store(R,                  reg1);
+      simd::store(R + simd::vec_size, reg3);
+      
+      A+=2*simd::vec_size; B+=2*simd::vec_size; R+=2*simd::vec_size;
+    }
+    
+    simd::exit();
+
+    while (n)
+    {
+      *R = *A + *B;
+      R++; A++; B++;
+      n--;
+    }
+  }
+};
+
+
+
+// Vectorized implementation of vector element-wise addition for
+// interleaved complex (complex<float>, complex<double>, etc).
+
+template <typename T>
+struct Simd_vadd<std::complex<T>, true>
+{
+  static void exec(
+    std::complex<T>* A,
+    std::complex<T>* B,
+    std::complex<T>* R,
+    int n)
+  {
+    Simd_vadd<T, true>::exec(
+      reinterpret_cast<T*>(A),
+      reinterpret_cast<T*>(B),
+      reinterpret_cast<T*>(R),
+      2*n);
+  }
+};
+
+
+
+// Generic, non-vectorized implementation of vector element-wise addition for
+// split complex (as represented by pair<float*, float*>, etc).
+
+template <typename T>
+struct Simd_vadd<std::pair<T, T>, false>
+{
+  static void exec(
+    std::pair<T*, T*> const& A,
+    std::pair<T*, T*> const& B,
+    std::pair<T*, T*> const& R,
+    int n)
+  {
+    T const* pAr = A.first;
+    T const* pAi = A.second;
+
+    T const* pBr = B.first;
+    T const* pBi = B.second;
+
+    T* pRr = R.first;
+    T* pRi = R.second;
+
+    while (n)
+    {
+      *pRr = *pAr + *pBr;
+      *pRi = *pAi + *pBi;
+      pRr++; pRi++;
+      pAr++; pAi++;
+      pBr++; pBi++;
+      n--;
+    }
+  }
+};
+
+
+
+// Vectorized implementation of vector element-wise addition for
+// split complex (as represented by pair<float*, float*>, etc).
+
+template <typename T>
+struct Simd_vadd<std::pair<T, T>, true>
+{
+  static void exec(
+    std::pair<T*, T*> const& A,
+    std::pair<T*, T*> const& B,
+    std::pair<T*, T*> const& R,
+    int n)
+  {
+    Simd_vadd<T, true>::exec(
+      A.first,
+      B.first,
+      R.first,
+      n);
+    Simd_vadd<T, true>::exec(
+      A.second,
+      B.second,
+      R.second,
+      n);
+  }
+};
+
+
+
+// Depending on VSIP_IMPL_LIBSIMD_INLINE macro, either provide these
+// functions inline, or provide non-inline functions in the libvsip.a.
+
+#if VSIP_IMPL_INLINE_LIBSIMD
+
+template <typename T>
+inline void
+vadd(
+  T*  op1,
+  T*  op2,
+  T*  res,
+  int size)
+{
+  static bool const Is_vectorized = Is_algorithm_supported<T, false, Alg_vadd>
+                                      ::value;
+  Simd_vadd<T, Is_vectorized>::exec(op1, op2, res, size);
+}
+
+template <typename T>
+inline void
+vadd(
+  std::pair<T*,T*>  op1,
+  std::pair<T*,T*>  op2,
+  std::pair<T*,T*>  res,
+  int size)
+{
+  static bool const Is_vectorized = Is_algorithm_supported<T, true, Alg_vadd>
+                                      ::value;
+  Simd_vadd<std::pair<T,T>, Is_vectorized>::exec(op1, op2, res, size);
+}
+
+#else
+
+template <typename T>
+void
+vadd(
+  T*  op1,
+  T*  op2,
+  T*  res,
+  int size);
+
+template <typename T>
+void
+vadd(
+  std::pair<T*,T*>  op1,
+  std::pair<T*,T*>  op2,
+  std::pair<T*,T*>  res,
+  int size);
+
+#endif // VSIP_IMPL_INLINE_LIBSIMD
+
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_SIMD_VMUL_HPP
Index: src/vsip/impl/simd/vlogic.cpp
===================================================================
--- src/vsip/impl/simd/vlogic.cpp	(revision 0)
+++ src/vsip/impl/simd/vlogic.cpp	(revision 0)
@@ -0,0 +1,148 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/simd/vlogic.cpp
+    @author  Jules Bergmann
+    @date    2006-07-28
+    @brief   VSIPL++ Library: SIMD element-wise vector operations.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/impl/simd/vlogic.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace simd
+{
+
+#if !VSIP_IMPL_INLINE_LIBSIMD
+
+template <typename T>
+void
+vband(
+  T const* op1,
+  T const* op2,
+  T*       res,
+  int      size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<T, false, Alg_vband>::value;
+  Simd_vlogic_binary<T, T, Is_vectorized, Fun_vband>::
+    exec(op1, op2, res, size);
+}
+
+template void vband(int const*, int const*, int*, int);
+
+template <typename T>
+void
+vbor(
+  T const* op1,
+  T const* op2,
+  T*       res,
+  int      size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<T, false, Alg_vbor>::value;
+  Simd_vlogic_binary<T, T, Is_vectorized, Fun_vbor>::
+    exec(op1, op2, res, size);
+}
+
+template void vbor(int const*, int const*, int*, int);
+
+template <typename T>
+void
+vbxor(
+  T const* op1,
+  T const* op2,
+  T*       res,
+  int      size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<T, false, Alg_vbxor>::value;
+  Simd_vlogic_binary<T, T, Is_vectorized, Fun_vbxor>::
+    exec(op1, op2, res, size);
+}
+
+template void vbxor(int const*, int const*, int*, int);
+
+template <typename T>
+void
+vbnot(
+  T const* op1,
+  T*       res,
+  int      size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<T, false, Alg_vbnot>::value;
+  Simd_vlogic_unary<T, T, Is_vectorized, Fun_vbnot>::exec(op1, res, size);
+}
+
+template void vbnot(int const*, int*, int);
+
+void
+vland(
+  bool const* op1,
+  bool const* op2,
+  bool*       res,
+  int         size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<bool, false, Alg_vland>::value;
+  Simd_vlogic_binary<bool, signed char, Is_vectorized, Fun_vland>::
+    exec(op1, op2, res, size);
+}
+
+void
+vlor(
+  bool const* op1,
+  bool const* op2,
+  bool*       res,
+  int      size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<bool, false, Alg_vlor>::value;
+  Simd_vlogic_binary<bool, signed char, Is_vectorized, Fun_vlor>::
+    exec(op1, op2, res, size);
+}
+
+void
+vlxor(
+  bool const* op1,
+  bool const* op2,
+  bool*       res,
+  int         size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<bool, false, Alg_vlxor>::value;
+  Simd_vlogic_binary<bool, signed char, Is_vectorized, Fun_vlxor>::
+    exec(op1, op2, res, size);
+}
+
+void
+vlnot(
+  bool const* op1,
+  bool*       res,
+  int         size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<bool, false, Alg_vlnot>::value;
+  Simd_vlogic_unary<bool, signed char, Is_vectorized, Fun_vlnot>::
+    exec(op1, res, size);
+}
+
+#endif
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
Index: src/vsip/impl/simd/expr_evaluator.hpp
===================================================================
--- src/vsip/impl/simd/expr_evaluator.hpp	(revision 146321)
+++ src/vsip/impl/simd/expr_evaluator.hpp	(working copy)
@@ -134,7 +134,7 @@
 
 template <typename LB,
 	  typename RB>
-struct Serial_expr_evaluator<1, LB, RB, Simd_tag>
+struct Serial_expr_evaluator<1, LB, RB, Simd_loop_fusion_tag>
 {
   static bool const ct_valid =
     // Is SIMD supported at all ?
@@ -156,6 +156,7 @@
   
   static void exec(LB& lhs, RB const& rhs)
   {
+    VSIP_IMPL_COVER_BLK("SEE_SIMD_LF", RB);
     typedef typename simd::LValue_access_traits<typename LB::value_type> WAT;
     typedef typename simd::Proxy_factory<RB>::access_traits EAT;
     length_type const vec_size =
Index: src/vsip/impl/simd/vgt.hpp
===================================================================
--- src/vsip/impl/simd/vgt.hpp	(revision 0)
+++ src/vsip/impl/simd/vgt.hpp	(revision 0)
@@ -0,0 +1,211 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/simd/vgt.hpp
+    @author  Jules Bergmann
+    @date    2006-07-26
+    @brief   VSIPL++ Library: SIMD element-wise vector greater-than.
+
+*/
+
+#ifndef VSIP_IMPL_SIMD_VGT_HPP
+#define VSIP_IMPL_SIMD_VGT_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <complex>
+
+#include <vsip/impl/simd/simd.hpp>
+#include <vsip/impl/metaprogramming.hpp>
+
+#define VSIP_IMPL_INLINE_LIBSIMD 0
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace simd
+{
+
+// Define value_types for which vgt is optimized.
+//  - float
+
+template <typename T,
+	  bool     IsSplit>
+struct Is_algorithm_supported<T, IsSplit, Alg_vgt>
+{
+  static bool const value =
+    Simd_traits<T>::is_accel && Type_equal<T, float>::value;
+};
+
+
+
+// Class for vgt - vector element-wise greater-than.
+
+template <typename T,
+	  bool     Is_vectorized>
+struct Simd_vgt;
+
+
+
+// Generic, non-vectorized implementation of vector element-wise greater-than.
+
+template <typename T>
+struct Simd_vgt<T, false>
+{
+  static void exec(T const* A, T const* B, bool* R, int n)
+  {
+    while (n)
+    {
+      *R = *A > *B;
+      R++; A++; B++;
+      n--;
+    }
+  }
+};
+
+
+
+// Vectorized implementation of vector element-wise gt.
+
+// Works under the following combinations:
+//  - mcoe  ppc    altivec GHS,     T=float (060728)
+//  - linux x86_64 sse     GCC 3.4, T=float (060728)
+
+template <>
+struct Simd_vgt<float, true>
+{
+  typedef float T;
+  static void exec(T const* A, T const* B, bool* R, int n)
+  {
+    typedef vsip::impl::simd::Simd_traits<float> simd;
+    typedef simd::simd_type                      simd_type;
+
+    typedef vsip::impl::simd::Simd_traits<short> short_simd;
+    typedef short_simd::simd_type                short_simd_type;
+
+  // handle mis-aligned vectors
+  if (simd::alignment_of((T*)R) != simd::alignment_of(A) ||
+      simd::alignment_of((T*)R) != simd::alignment_of(B))
+  {
+    // PROFILE
+    while (n)
+    {
+      *R = *A > *B;
+      R++; A++; B++;
+      n--;
+    }
+    return;
+  }
+
+  // clean up initial unaligned values
+  while (simd::alignment_of(A) != 0)
+  {
+    *R = *A > *B;
+    R++; A++; B++;
+    n--;
+  }
+  
+  if (n == 0) return;
+
+  simd::enter();
+
+  short_simd_type bool_mask =
+    (short_simd_type)vsip::impl::simd::Simd_traits<signed char>::
+		load_scalar_all(0x01);
+
+  int const unroll = 4;
+  while (n >= unroll*simd::vec_size)
+  {
+    n -= unroll*simd::vec_size;
+
+    simd_type regA0 = simd::load(A);
+    simd_type regA1 = simd::load(A + 1*simd::vec_size);
+    simd_type regA2 = simd::load(A + 2*simd::vec_size);
+    simd_type regA3 = simd::load(A + 3*simd::vec_size);
+      
+    simd_type regB0 = simd::load(B + 0*simd::vec_size);
+    simd_type regB1 = simd::load(B + 1*simd::vec_size);
+    simd_type regB2 = simd::load(B + 2*simd::vec_size);
+    simd_type regB3 = simd::load(B + 3*simd::vec_size);
+      
+    short_simd_type cmp0 = (short_simd_type)simd::gt(regA0, regB0);
+    short_simd_type cmp1 = (short_simd_type)simd::gt(regA1, regB1);
+    short_simd_type cmp2 = (short_simd_type)simd::gt(regA2, regB2);
+    short_simd_type cmp3 = (short_simd_type)simd::gt(regA3, regB3);
+
+#if !__VEC__ || __BIG_ENDIAN__
+    short_simd_type red0 = (short_simd_type)short_simd::pack(cmp0, cmp1);
+    short_simd_type red1 = (short_simd_type)short_simd::pack(cmp2, cmp3);
+    short_simd_type res  = (short_simd_type)short_simd::pack(red0, red1);
+#else
+    short_simd_type red0 = (short_simd_type)short_simd::pack(cmp1, cmp0);
+    short_simd_type red1 = (short_simd_type)short_simd::pack(cmp3, cmp2);
+    short_simd_type res  = (short_simd_type)short_simd::pack(red1, red0);
+#endif
+
+    short_simd_type bool_res = short_simd::band(res, bool_mask);
+
+    short_simd::store((short*)R, bool_res);
+      
+    A += unroll*simd::vec_size;
+    B += unroll*simd::vec_size;
+    R += unroll*simd::vec_size;
+  }
+    
+  simd::exit();
+
+  while (n)
+  {
+    *R = *A > *B;
+    R++; A++; B++;
+    n--;
+  }
+  }
+};
+
+
+
+// Depending on VSIP_IMPL_LIBSIMD_INLINE macro, either provide these
+// functions inline, or provide non-inline functions in the libvsip.a.
+
+#if VSIP_IMPL_INLINE_LIBSIMD
+
+template <typename T>
+inline void
+vgt(
+  T const* op1,
+  T const* op2,
+  bool*    res,
+  int      size)
+{
+  static bool const Is_vectorized = Is_algorithm_supported<T, false, Alg_vgt>
+                                      ::value;
+  Simd_vgt<T, Is_vectorized>::exec(op1, op2, res, size);
+}
+
+#else
+
+template <typename T>
+void
+vgt(
+  T const* op1,
+  T const* op2,
+  bool*    res,
+  int      size);
+
+#endif // VSIP_IMPL_INLINE_LIBSIMD
+
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_SIMD_VMUL_HPP
Index: src/vsip/impl/simd/eval-generic.hpp
===================================================================
--- src/vsip/impl/simd/eval-generic.hpp	(revision 146321)
+++ src/vsip/impl/simd/eval-generic.hpp	(working copy)
@@ -19,11 +19,16 @@
 #include <vsip/impl/expr_scalar_block.hpp>
 #include <vsip/impl/expr_binary_block.hpp>
 #include <vsip/impl/expr_operations.hpp>
+#include <vsip/impl/fns_elementwise.hpp>
 #include <vsip/impl/extdata.hpp>
+#include <vsip/impl/coverage.hpp>
 
 #include <vsip/impl/simd/simd.hpp>
+#include <vsip/impl/simd/vadd.hpp>
 #include <vsip/impl/simd/vmul.hpp>
 #include <vsip/impl/simd/rscvmul.hpp>
+#include <vsip/impl/simd/vgt.hpp>
+#include <vsip/impl/simd/vlogic.hpp>
 
 /***********************************************************************
   Declarations
@@ -43,7 +48,15 @@
 };
 
 template <>
+struct Map_operator_to_algorithm<op::Add>  { typedef Alg_vadd type; };
+template <>
 struct Map_operator_to_algorithm<op::Mult> { typedef Alg_vmul type; };
+template <>
+struct Map_operator_to_algorithm<band_functor> { typedef Alg_vband type; };
+template <>
+struct Map_operator_to_algorithm<bor_functor> { typedef Alg_vbor type; };
+template <>
+struct Map_operator_to_algorithm<bxor_functor> { typedef Alg_vbxor type; };
 
 
 
@@ -93,33 +106,307 @@
 
 
 
+#define VSIP_IMPL_SIMD_V_EXPR(OP, ALG, FCN)				\
+template <typename DstBlock,						\
+	  typename LBlock,						\
+	  typename LType>						\
+struct Serial_expr_evaluator<						\
+  1, DstBlock, 								\
+  const Unary_expr_block<1, OP, LBlock, LType>,				\
+  Simd_builtin_tag>							\
+{									\
+  typedef Unary_expr_block<1, OP, LBlock, LType>			\
+    SrcBlock;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<LBlock>::layout_type>::type		\
+    lblock_lp;								\
+  									\
+  static bool const ct_valid = 						\
+    !Is_expr_block<LBlock>::value &&					\
+    simd::Is_algorithm_supported<					\
+        typename DstBlock::value_type,					\
+        Is_split_block<DstBlock>::value,				\
+	ALG>::value &&							\
+     Type_equal<typename DstBlock::value_type, LType>::value &&		\
+     /* check that direct access is supported */			\
+     Ext_data_cost<DstBlock>::value == 0 &&				\
+     Ext_data_cost<LBlock>::value == 0 &&				\
+     /* Must have same complex interleaved/split format */		\
+     Type_equal<typename Block_layout<DstBlock>::complex_type,		\
+		typename Block_layout<LBlock>::complex_type>::value;	\
+  									\
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)		\
+  {									\
+    /* check if all data is unit stride */				\
+    Ext_data<DstBlock, dst_lp> ext_dst(dst, SYNC_OUT);			\
+    Ext_data<LBlock, lblock_lp> ext_l(src.op(), SYNC_IN);		\
+    return (ext_dst.stride(0) == 1 &&					\
+	    ext_l.stride(0) == 1);					\
+  }									\
+  									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    Ext_data<DstBlock, dst_lp> ext_dst(dst, SYNC_OUT);			\
+    Ext_data<LBlock, lblock_lp> ext_l(src.op(), SYNC_IN);		\
+    VSIP_IMPL_COVER_FCN("eval_SIMD_V", FCN);				\
+    FCN(ext_l.data(), ext_dst.data(), dst.size());			\
+  }									\
+};
+
+#define VSIP_IMPL_SIMD_VV_EXPR(OP, FCN)					\
+template <typename DstBlock,						\
+	  typename LBlock,						\
+	  typename RBlock,						\
+	  typename LType,						\
+	  typename RType>						\
+struct Serial_expr_evaluator<						\
+  1, DstBlock, 								\
+  const Binary_expr_block<1, OP, LBlock, LType, RBlock, RType>,		\
+  Simd_builtin_tag>							\
+{									\
+  typedef Binary_expr_block<1, OP, LBlock, LType, RBlock, RType>	\
+    SrcBlock;								\
+  									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<LBlock>::layout_type>::type		\
+    lblock_lp;								\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<RBlock>::layout_type>::type		\
+    rblock_lp;								\
+  									\
+  static bool const ct_valid = 						\
+    !Is_expr_block<LBlock>::value &&					\
+    !Is_expr_block<RBlock>::value &&					\
+    simd::Is_algorithm_supported<					\
+        typename DstBlock::value_type,					\
+        Is_split_block<DstBlock>::value,				\
+	typename simd::Map_operator_to_algorithm<OP>::type>::value &&	\
+     Type_equal<typename DstBlock::value_type, LType>::value &&		\
+     Type_equal<typename DstBlock::value_type, RType>::value &&		\
+     /* check that direct access is supported */			\
+     Ext_data_cost<DstBlock>::value == 0 &&				\
+     Ext_data_cost<LBlock>::value == 0 &&				\
+     Ext_data_cost<RBlock>::value == 0 &&				\
+     /* Must have same complex interleaved/split format */		\
+     Type_equal<typename Block_layout<DstBlock>::complex_type,		\
+		typename Block_layout<LBlock>::complex_type>::value &&	\
+     Type_equal<typename Block_layout<DstBlock>::complex_type,		\
+		typename Block_layout<RBlock>::complex_type>::value;	\
+  									\
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)		\
+  {									\
+    /* check if all data is unit stride */				\
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst, SYNC_OUT);			\
+    Ext_data<LBlock, lblock_lp> ext_l(src.left(), SYNC_IN);		\
+    Ext_data<RBlock, rblock_lp> ext_r(src.right(), SYNC_IN);		\
+    return (ext_dst.stride(0) == 1 &&					\
+	    ext_l.stride(0) == 1 &&					\
+	    ext_r.stride(0) == 1);					\
+  }									\
+  									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst, SYNC_OUT);			\
+    Ext_data<LBlock, lblock_lp> ext_l(src.left(), SYNC_IN);		\
+    Ext_data<RBlock, rblock_lp> ext_r(src.right(), SYNC_IN);		\
+    VSIP_IMPL_COVER_FCN("eval_SIMD_VV", FCN);				\
+    FCN(ext_l.data(), ext_r.data(), ext_dst.data(), dst.size());	\
+  }									\
+};
+
+
+VSIP_IMPL_SIMD_V_EXPR (bnot_functor, simd::Alg_vbnot, simd::vbnot)
+
+VSIP_IMPL_SIMD_VV_EXPR(op::Mult,     simd::vmul)
+VSIP_IMPL_SIMD_VV_EXPR(op::Add,      simd::vadd)
+VSIP_IMPL_SIMD_VV_EXPR(band_functor, simd::vband)
+VSIP_IMPL_SIMD_VV_EXPR(bor_functor,  simd::vbor)
+VSIP_IMPL_SIMD_VV_EXPR(bxor_functor, simd::vbxor)
+
+#undef VSIP_IMPL_SIMD_V_EXPR
+#undef VSIP_IMPL_SIMD_VV_EXPR
+
+
+
+/***********************************************************************
+  vgt: vector greater-than operator
+***********************************************************************/
+
 template <typename DstBlock,
 	  typename LBlock,
 	  typename RBlock,
 	  typename LType,
 	  typename RType>
 struct Serial_expr_evaluator<
-  1, DstBlock, 
-  const Binary_expr_block<1, op::Mult, LBlock, LType, RBlock, RType>,
-  Simd_tag>
-  : simd::Serial_expr_evaluator_base<op::Mult, DstBlock,
-				    LBlock, RBlock, LType, RType>
+  1, DstBlock,
+  const Binary_expr_block<1, gt_functor, LBlock, LType, RBlock, RType>,
+  Simd_builtin_tag>
 {
-  typedef Binary_expr_block<1, op::Mult, LBlock, LType, RBlock, RType>
+  typedef Binary_expr_block<1, gt_functor, LBlock, LType, RBlock, RType>
     SrcBlock;
+
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<DstBlock>::layout_type>::type
+    dst_lp;
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<LBlock>::layout_type>::type
+    lblock_lp;
+  typedef typename Adjust_layout_dim<
+      1, typename Block_layout<RBlock>::layout_type>::type
+    rblock_lp;
+
+  static bool const ct_valid = 
+    !Is_expr_block<LBlock>::value &&
+    !Is_expr_block<RBlock>::value &&
+     Type_equal<typename DstBlock::value_type, bool>::value &&
+     Type_equal<LType, RType>::value &&
+     simd::Is_algorithm_supported<LType, false, simd::Alg_vgt>::value &&
+     // check that direct access is supported
+     Ext_data_cost<DstBlock>::value == 0 &&
+     Ext_data_cost<LBlock>::value == 0 &&
+     Ext_data_cost<RBlock>::value == 0;
+
   
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)
+  {
+    // check if all data is unit stride
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,         SYNC_OUT);
+    Ext_data<LBlock, lblock_lp> ext_l  (src.left(),  SYNC_IN);
+    Ext_data<RBlock, rblock_lp> ext_r  (src.right(), SYNC_IN);
+    return (ext_dst.stride(0) == 1 &&
+	    ext_l.stride(0) == 1 &&
+	    ext_r.stride(0) == 1);
+  }
+
   static void exec(DstBlock& dst, SrcBlock const& src)
   {
-    Ext_data<DstBlock> ext_dst(dst, SYNC_OUT);
-    Ext_data<LBlock> ext_l(src.left(), SYNC_IN);
-    Ext_data<RBlock> ext_r(src.right(), SYNC_IN);
-    simd::vmul(ext_l.data(), ext_r.data(), ext_dst.data(), dst.size());
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,         SYNC_OUT);
+    Ext_data<LBlock, lblock_lp> ext_l  (src.left(),  SYNC_IN);
+    Ext_data<RBlock, rblock_lp> ext_r  (src.right(), SYNC_IN);
+    VSIP_IMPL_COVER_FCN("eval_SIMD_VV", simd::vgt);
+    simd::vgt(ext_l.data(), ext_r.data(), ext_dst.data(), dst.size());
   }
 };
 
 
 
+/***********************************************************************
+  vector logical operators
+***********************************************************************/
 
+#define VSIP_IMPL_SIMD_LOGIC_V_EXPR(OP, ALG, FCN)			\
+template <typename DstBlock,						\
+	  typename BlockT>						\
+struct Serial_expr_evaluator<						\
+  1, DstBlock,								\
+  const Unary_expr_block<1, OP, BlockT, bool>,				\
+  Simd_builtin_tag>							\
+{									\
+  typedef Unary_expr_block<1, OP, BlockT, bool>				\
+    SrcBlock;								\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<BlockT>::layout_type>::type		\
+    block_lp;								\
+									\
+  static bool const ct_valid = 						\
+    !Is_expr_block<BlockT>::value &&					\
+     Type_equal<typename DstBlock::value_type, bool>::value &&		\
+     simd::Is_algorithm_supported<bool, false, ALG>::value &&		\
+     /* check that direct access is supported */			\
+     Ext_data_cost<DstBlock>::value == 0 &&				\
+     Ext_data_cost<BlockT>::value == 0;					\
+									\
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)		\
+  {									\
+    /* check if all data is unit stride */				\
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,         SYNC_OUT);		\
+    Ext_data<BlockT, block_lp>  ext_l  (src.op(),  SYNC_IN);		\
+    return (ext_dst.stride(0) == 1 &&					\
+	    ext_l.stride(0) == 1);					\
+  }									\
+									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,         SYNC_OUT);		\
+    Ext_data<BlockT, block_lp>  ext_l  (src.op(),  SYNC_IN);		\
+    VSIP_IMPL_COVER_FCN("eval_SIMD_V", FCN);				\
+    FCN(ext_l.data(), ext_dst.data(), dst.size());			\
+  }									\
+};
+
+#define VSIP_IMPL_SIMD_LOGIC_VV_EXPR(OP, ALG, FCN)			\
+template <typename DstBlock,						\
+	  typename LBlock,						\
+	  typename RBlock>						\
+struct Serial_expr_evaluator<						\
+  1, DstBlock,								\
+  const Binary_expr_block<1, OP, LBlock, bool, RBlock, bool>,		\
+  Simd_builtin_tag>							\
+{									\
+  typedef Binary_expr_block<1, OP, LBlock, bool, RBlock, bool>		\
+    SrcBlock;								\
+									\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<DstBlock>::layout_type>::type		\
+    dst_lp;								\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<LBlock>::layout_type>::type		\
+    lblock_lp;								\
+  typedef typename Adjust_layout_dim<					\
+      1, typename Block_layout<RBlock>::layout_type>::type		\
+    rblock_lp;								\
+									\
+  static bool const ct_valid = 						\
+    !Is_expr_block<LBlock>::value &&					\
+    !Is_expr_block<RBlock>::value &&					\
+     Type_equal<typename DstBlock::value_type, bool>::value &&		\
+     simd::Is_algorithm_supported<bool, false, ALG>::value &&\
+     /* check that direct access is supported */			\
+     Ext_data_cost<DstBlock>::value == 0 &&				\
+     Ext_data_cost<LBlock>::value == 0 &&				\
+     Ext_data_cost<RBlock>::value == 0;					\
+									\
+  static bool rt_valid(DstBlock& dst, SrcBlock const& src)		\
+  {									\
+    /* check if all data is unit stride */				\
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,         SYNC_OUT);		\
+    Ext_data<LBlock, lblock_lp> ext_l  (src.left(),  SYNC_IN);		\
+    Ext_data<RBlock, rblock_lp> ext_r  (src.right(), SYNC_IN);		\
+    return (ext_dst.stride(0) == 1 &&					\
+	    ext_l.stride(0) == 1 &&					\
+	    ext_r.stride(0) == 1);					\
+  }									\
+									\
+  static void exec(DstBlock& dst, SrcBlock const& src)			\
+  {									\
+    Ext_data<DstBlock, dst_lp>  ext_dst(dst,         SYNC_OUT);		\
+    Ext_data<LBlock, lblock_lp> ext_l  (src.left(),  SYNC_IN);		\
+    Ext_data<RBlock, rblock_lp> ext_r  (src.right(), SYNC_IN);		\
+    VSIP_IMPL_COVER_FCN("eval_SIMD_VV", FCN);				\
+    FCN(ext_l.data(), ext_r.data(), ext_dst.data(), dst.size());	\
+  }									\
+};
+
+VSIP_IMPL_SIMD_LOGIC_V_EXPR (lnot_functor, simd::Alg_vlnot, simd::vlnot)
+VSIP_IMPL_SIMD_LOGIC_VV_EXPR(land_functor, simd::Alg_vland, simd::vland)
+VSIP_IMPL_SIMD_LOGIC_VV_EXPR(lor_functor,  simd::Alg_vlor,  simd::vlor)
+VSIP_IMPL_SIMD_LOGIC_VV_EXPR(lxor_functor, simd::Alg_vlxor, simd::vlxor)
+
+#undef VSIP_IMPL_SIMD_LOGIC_V_EXPR
+#undef VSIP_IMPL_SIMD_LOGIC_VV_EXPR
+
+
 /***********************************************************************
   Scalar-view element-wise operations
 ***********************************************************************/
@@ -134,7 +421,7 @@
          const Binary_expr_block<1, op::Mult,
                                  Scalar_block<1, T>, T,
                                  VBlock, std::complex<T> >,
-         Simd_tag>
+         Simd_builtin_tag>
 {
   typedef Binary_expr_block<1, op::Mult,
 			    Scalar_block<1, T>, T,
@@ -185,7 +472,7 @@
          const Binary_expr_block<1, op::Mult,
                                  VBlock, std::complex<T>,
                                  Scalar_block<1, T>, T>,
-         Simd_tag>
+         Simd_builtin_tag>
 {
   typedef Binary_expr_block<1, op::Mult,
 			    VBlock, std::complex<T>,
Index: src/vsip/impl/simd/vlogic.hpp
===================================================================
--- src/vsip/impl/simd/vlogic.hpp	(revision 0)
+++ src/vsip/impl/simd/vlogic.hpp	(revision 0)
@@ -0,0 +1,594 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/impl/simd/vlogic.hpp
+    @author  Jules Bergmann
+    @date    2006-07-28
+    @brief   VSIPL++ Library: SIMD element-wise vector logic operations.
+
+*/
+
+#ifndef VSIP_IMPL_SIMD_VLOGIC_HPP
+#define VSIP_IMPL_SIMD_VLOGIC_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <complex>
+
+#include <vsip/impl/simd/simd.hpp>
+#include <vsip/impl/metaprogramming.hpp>
+
+#define VSIP_IMPL_INLINE_LIBSIMD 0
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+namespace simd
+{
+
+// Define value_types for which vband is optimized.
+//  - float
+
+template <typename T>
+struct Is_algorithm_supported<T, false, Alg_vband>
+{
+  static bool const value = Simd_traits<T>::is_accel;
+};
+
+template <typename T>
+struct Is_algorithm_supported<T, false, Alg_vbor>
+{
+  static bool const value = Simd_traits<T>::is_accel;
+};
+
+template <typename T>
+struct Is_algorithm_supported<T, false, Alg_vbxor>
+{
+  static bool const value = Simd_traits<T>::is_accel;
+};
+
+template <typename T>
+struct Is_algorithm_supported<T, false, Alg_vbnot>
+{
+  static bool const value = Simd_traits<T>::is_accel;
+};
+
+template <>
+struct Is_algorithm_supported<bool, false, Alg_vland>
+{
+  static bool const value = Simd_traits<signed char>::is_accel;
+};
+
+template <>
+struct Is_algorithm_supported<bool, false, Alg_vlor>
+{
+  static bool const value = Simd_traits<signed char>::is_accel;
+};
+
+template <>
+struct Is_algorithm_supported<bool, false, Alg_vlxor>
+{
+  static bool const value = Simd_traits<signed char>::is_accel;
+};
+
+template <>
+struct Is_algorithm_supported<bool, false, Alg_vlnot>
+{
+  static bool const value = Simd_traits<signed char>::is_accel;
+};
+
+
+
+
+
+// bitwise-and operation
+
+struct Fun_vband
+{
+  template <typename T>
+  static T exec(T const& A, T const& B)
+  { return A & B; }
+
+  template <typename SimdTraits, typename SimdValueT>
+  static SimdValueT exec_simd(SimdValueT const& A, SimdValueT const& B)
+  { return SimdTraits::band(A, B); }
+};
+
+
+
+// bitwise-or operation
+
+struct Fun_vbor
+{
+  template <typename T>
+  static T exec(T const& A, T const& B)
+  { return A | B; }
+
+  template <typename SimdTraits, typename SimdValueT>
+  static SimdValueT exec_simd(SimdValueT const& A, SimdValueT const& B)
+  { return SimdTraits::bor(A, B); }
+};
+
+
+
+// bitwise-xor operation
+
+struct Fun_vbxor
+{
+  template <typename T>
+  static T exec(T const& A, T const& B)
+  { return A ^ B; }
+
+  template <typename SimdTraits, typename SimdValueT>
+  static SimdValueT exec_simd(SimdValueT const& A, SimdValueT const& B)
+  { return SimdTraits::bxor(A, B); }
+};
+
+
+
+// bitwise-not operation
+
+struct Fun_vbnot
+{
+  template <typename T>
+  static T exec(T const& A)
+  { return ~A; }
+
+  template <typename SimdTraits, typename SimdValueT>
+  static SimdValueT exec_simd(SimdValueT const& A)
+  { return SimdTraits::bnot(A); }
+};
+
+
+
+// logical-and operation
+
+struct Fun_vland
+{
+  static bool exec(bool A, bool B)
+  { return A && B; }
+
+  template <typename SimdTraits, typename SimdValueT>
+  static SimdValueT exec_simd(SimdValueT const& A, SimdValueT const& B)
+  { return SimdTraits::band(A, B); }
+};
+
+
+
+// logical-or operation
+
+struct Fun_vlor
+{
+  static bool exec(bool A, bool B)
+  { return A || B; }
+
+  template <typename SimdTraits, typename SimdValueT>
+  static SimdValueT exec_simd(SimdValueT const& A, SimdValueT const& B)
+  { return SimdTraits::bor(A, B); }
+};
+
+
+
+// logical-xor operation
+
+struct Fun_vlxor
+{
+  static bool exec(bool A, bool B)
+  { return A ^ B; }
+
+  template <typename SimdTraits, typename SimdValueT>
+  static SimdValueT exec_simd(SimdValueT const& A, SimdValueT const& B)
+  { return SimdTraits::bxor(A, B); }
+};
+
+
+
+// logical-not operation
+
+struct Fun_vlnot
+{
+  static bool exec(bool A)
+  { return !A; }
+
+  template <typename SimdTraits, typename SimdValueT>
+  static SimdValueT exec_simd(SimdValueT const& A)
+  { return SimdTraits::bxor(A, SimdTraits::load_scalar_all(0x01)); }
+};
+
+
+
+/***********************************************************************
+  Definitions -- Generic unary logical operations (boolean and bitwise)
+***********************************************************************/
+
+// General class template for unary logical operations
+
+template <typename T,
+	  typename SimdValueT,
+	  bool     Is_vectorized,
+	  typename FunctionT>
+struct Simd_vlogic_unary;
+
+
+
+// Generic, non-vectorized implementation of logical operations.
+
+template <typename T,
+	  typename SimdValueT,
+          typename FunctionT>
+struct Simd_vlogic_unary<T, SimdValueT, false, FunctionT>
+{
+  static void exec(T const* A, T* R, int n)
+  {
+    while (n)
+    {
+      *R = FunctionT::exec(*A);
+      R++; A++;
+      n--;
+    }
+  }
+};
+
+
+
+// Vectorized implementation of logical operations.
+
+// Works under the following combinations:
+//  - Fun_bnot: linux ia32   sse     GCC 3.4, T=int  (060728)
+//  - Fun_lnot: linux ia32   sse     GCC 3.4, T=bool (060730)
+
+template <typename T,
+	  typename SimdValueT,
+          typename FunctionT>
+struct Simd_vlogic_unary<T, SimdValueT, true, FunctionT>
+{
+  static void exec(T const* A, T* R, int n)
+  {
+    typedef vsip::impl::simd::Simd_traits<SimdValueT> traits;
+    typedef typename traits::simd_type                simd_type;
+
+    // handle mis-aligned vectors
+    if (   traits::alignment_of((SimdValueT*)R) !=
+	   traits::alignment_of((SimdValueT*)A))
+    {
+      // PROFILE
+      while (n)
+      {
+	*R = FunctionT::exec(*A);
+	R++; A++;
+	n--;
+      }
+      return;
+    }
+
+    // clean up initial unaligned values
+    while (traits::alignment_of((SimdValueT*)A) != 0)
+    {
+      *R = FunctionT::exec(*A);
+      R++; A++;
+      n--;
+    }
+  
+    if (n == 0) return;
+
+    traits::enter();
+
+    int const unroll = 1;
+    while (n >= unroll*traits::vec_size)
+    {
+      n -= unroll*traits::vec_size;
+
+      simd_type regA0 = traits::load((SimdValueT*)A);
+      simd_type res   = FunctionT::template exec_simd<traits>(regA0);
+      traits::store((SimdValueT*)R, res);
+      
+      A += unroll*traits::vec_size;
+      R += unroll*traits::vec_size;
+    }
+    
+    traits::exit();
+
+    while (n)
+    {
+      *R = FunctionT::exec(*A);
+      R++; A++;
+      n--;
+    }
+  }
+};
+
+
+
+/***********************************************************************
+  Definitions -- Generic binary logical operations (boolean and bitwise)
+***********************************************************************/
+
+// General class template for binary logical operations
+
+template <typename T,
+	  typename SimdValueT,
+	  bool     Is_vectorized,
+	  typename FunctionT>
+struct Simd_vlogic_binary;
+
+
+
+// Generic, non-vectorized implementation of logical operations.
+
+template <typename T,
+	  typename SimdValueT,
+          typename FunctionT>
+struct Simd_vlogic_binary<T, SimdValueT, false, FunctionT>
+{
+  static void exec(T const* A, T const* B, T* R, int n)
+  {
+    while (n)
+    {
+      *R = FunctionT::exec(*A, *B);
+      R++; A++; B++;
+      n--;
+    }
+  }
+};
+
+
+
+// Vectorized implementation of logical operations.
+
+// Works under the following combinations:
+//  - Fun_band: linux ia32   sse     GCC 3.4, T=int  (060728)
+//  - Fun_bor : linux ia32   sse     GCC 3.4, T=int  (060728)
+//  - Fun_bxor: linux ia32   sse     GCC 3.4, T=int  (060728) ?????
+//  - Fun_land: linux ia32   sse     GCC 3.4, T=bool (060730)
+//  - Fun_lor : linux ia32   sse     GCC 3.4, T=bool (060730)
+//  - Fun_lxor: linux ia32   sse     GCC 3.4, T=bool (060730) ?????
+
+template <typename T,
+	  typename SimdValueT,
+          typename FunctionT>
+struct Simd_vlogic_binary<T, SimdValueT, true, FunctionT>
+{
+  static void exec(T const* A, T const* B, T* R, int n)
+  {
+    typedef vsip::impl::simd::Simd_traits<SimdValueT> traits;
+    typedef typename traits::simd_type                simd_type;
+
+    // handle mis-aligned vectors
+    if (   traits::alignment_of((SimdValueT*)R) !=
+	   traits::alignment_of((SimdValueT*)A)
+	|| traits::alignment_of((SimdValueT*)R) !=
+	   traits::alignment_of((SimdValueT*)B))
+    {
+      // PROFILE
+      while (n)
+      {
+	*R = FunctionT::exec(*A, *B);
+	R++; A++; B++;
+	n--;
+      }
+      return;
+    }
+
+    // clean up initial unaligned values
+    while (traits::alignment_of((SimdValueT*)A) != 0)
+    {
+      *R = FunctionT::exec(*A, *B);
+      R++; A++; B++;
+      n--;
+    }
+  
+    if (n == 0) return;
+
+    traits::enter();
+
+    int const unroll = 1;
+    while (n >= unroll*traits::vec_size)
+    {
+      n -= unroll*traits::vec_size;
+
+      simd_type regA0 = traits::load((SimdValueT*)A);
+      simd_type regB0 = traits::load((SimdValueT*)B);
+      simd_type res   = FunctionT::template exec_simd<traits>(regA0, regB0);
+      traits::store((SimdValueT*)R, res);
+      
+      A += unroll*traits::vec_size;
+      B += unroll*traits::vec_size;
+      R += unroll*traits::vec_size;
+    }
+    
+    traits::exit();
+
+    while (n)
+    {
+      *R = FunctionT::exec(*A, *B);
+      R++; A++; B++;
+      n--;
+    }
+  }
+};
+
+
+
+/***********************************************************************
+  Definitions -- Specific gateway functions.
+***********************************************************************/
+
+// Depending on VSIP_IMPL_LIBSIMD_INLINE macro, either provide these
+// functions inline, or provide non-inline functions in the libvsip.a.
+
+#if VSIP_IMPL_INLINE_LIBSIMD
+template <typename T>
+inline void
+vband(
+  T const* op1,
+  T const* op2,
+  T*       res,
+  int      size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<T, false, Alg_vband>::value;
+  Simd_vlogic_binary<T, T, Is_vectorized, Fun_vband>::exec(op1, op2, res, size);
+}
+
+template <typename T>
+inline void
+vbor(
+  T const* op1,
+  T const* op2,
+  T*       res,
+  int      size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<T, false, Alg_vbor>::value;
+  Simd_vlogic_binary<T, T, Is_vectorized, Fun_vbor>::exec(op1, op2, res, size);
+}
+
+template <typename T>
+inline void
+vbxor(
+  T const* op1,
+  T const* op2,
+  T*       res,
+  int      size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<T, false, Alg_vbxor>::value;
+  Simd_vlogic_binary<T, T, Is_vectorized, Fun_vbxor>::exec(op1, op2, res, size);
+}
+
+template <typename T>
+inline void
+vbnot(
+  T const* op1,
+  T*       res,
+  int      size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<T, false, Alg_vbnot>::value;
+  Simd_vlogic_unary<T, T, Is_vectorized, Fun_vbnot>::exec(op1, res, size);
+}
+
+inline void
+vland(
+  bool const* op1,
+  bool const* op2,
+  bool*       res,
+  int         size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<bool, false, Alg_vland>::value;
+  Simd_vlogic_binary<bool, signed char, Is_vectorized, Fun_vland>::
+    exec(op1, op2, res, size);
+}
+
+inline void
+vlor(
+  bool const* op1,
+  bool const* op2,
+  bool*       res,
+  int      size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<bool, false, Alg_vlor>::value;
+  Simd_vlogic_binary<bool, signed char, Is_vectorized, Fun_vlor>::
+    exec(op1, op2, res, size);
+}
+
+inline void
+vlxor(
+  bool const* op1,
+  bool const* op2,
+  bool*       res,
+  int         size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<bool, false, Alg_vlxor>::value;
+  Simd_vlogic_binary<bool, signed char, Is_vectorized, Fun_vlxor>::
+    exec(op1, op2, res, size);
+}
+
+inline void
+vlnot(
+  bool const* op1,
+  bool*       res,
+  int         size)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<bool, false, Alg_vlnot>::value;
+  Simd_vlogic_binary<bool, signed char, Is_vectorized, Fun_vlnot>::
+    exec(op1, res, size);
+}
+#else
+template <typename T>
+void
+vband(
+  T const* op1,
+  T const* op2,
+  T*       res,
+  int      size);
+
+template <typename T>
+void
+vbor(
+  T const* op1,
+  T const* op2,
+  T*       res,
+  int      size);
+
+template <typename T>
+void
+vbxor(
+  T const* op1,
+  T const* op2,
+  T*       res,
+  int      size);
+
+template <typename T>
+void
+vbnot(
+  T const* op1,
+  T*       res,
+  int      size);
+
+void
+vland(
+  bool const* op1,
+  bool const* op2,
+  bool*       res,
+  int         size);
+
+void
+vlor(
+  bool const* op1,
+  bool const* op2,
+  bool*       res,
+  int         size);
+
+void
+vlxor(
+  bool const* op1,
+  bool const* op2,
+  bool*       res,
+  int         size);
+
+void
+vlnot(
+  bool const* op1,
+  bool*       res,
+  int         size);
+#endif // VSIP_IMPL_INLINE_LIBSIMD
+
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_SIMD_VLOGIC_HPP
Index: src/vsip/impl/simd/rscvmul.cpp
===================================================================
--- src/vsip/impl/simd/rscvmul.cpp	(revision 146321)
+++ src/vsip/impl/simd/rscvmul.cpp	(working copy)
@@ -29,7 +29,7 @@
 #if !VSIP_IMPL_INLINE_LIBSIMD
 
 template <typename T>
-inline void
+void
 rscvmul(
   T                op1,
   std::complex<T>* op2,
@@ -48,7 +48,7 @@
 
 
 template <typename T>
-inline void
+void
 rscvmul(
   T                op1,
   std::pair<T*,T*> op2,
Index: src/vsip/impl/distributed-block.hpp
===================================================================
--- src/vsip/impl/distributed-block.hpp	(revision 146321)
+++ src/vsip/impl/distributed-block.hpp	(working copy)
@@ -15,6 +15,7 @@
 ***********************************************************************/
 
 #include <vsip/support.hpp>
+#include <vsip/map_fwd.hpp>
 #include <vsip/impl/block-traits.hpp>
 #include <vsip/impl/domain-utils.hpp>
 
@@ -131,6 +132,13 @@
   // the data parallel group.
   value_type get(index_type idx) const VSIP_NOTHROW
   {
+    // Optimize uni-processor and replicated cases.
+    if (    Type_equal<Map, Global_map<1> >::value
+        ||  vsip::num_processors() == 1
+	|| (   Type_equal<Map, Replicated_map<1> >::value
+	    && map_.subblock() != no_subblock))
+      return subblock_->get(idx);
+
     index_type     sb = map_.impl_subblock_from_global_index(Index<1>(idx));
     processor_type pr = *(map_.processor_begin(sb));
     value_type     val = value_type(); // avoid -Wall 'may not be initialized'
@@ -149,6 +157,13 @@
 
   value_type get(index_type idx0, index_type idx1) const VSIP_NOTHROW
   {
+    // Optimize uni-processor and replicated cases.
+    if (    Type_equal<Map, Global_map<2> >::value
+        ||  vsip::num_processors() == 1
+	|| (   Type_equal<Map, Replicated_map<2> >::value
+	    && map_.subblock() != no_subblock))
+      return subblock_->get(idx0, idx1);
+
     index_type     sb = map_.impl_subblock_from_global_index(
 				Index<2>(idx0, idx1));
     processor_type pr = *(map_.processor_begin(sb));
@@ -170,6 +185,13 @@
   value_type get(index_type idx0, index_type idx1, index_type idx2)
     const VSIP_NOTHROW
   {
+    // Optimize uni-processor and replicated cases.
+    if (    Type_equal<Map, Global_map<3> >::value
+        ||  vsip::num_processors() == 1
+	|| (   Type_equal<Map, Replicated_map<3> >::value
+	    && map_.subblock() != no_subblock))
+      return subblock_->get(idx0, idx1, idx2);
+
     index_type     sb = map_.impl_subblock_from_global_index(
 				Index<3>(idx0, idx1, idx2));
     processor_type pr = *(map_.processor_begin(sb));
Index: src/vsip/impl/expr_serial_dispatch.hpp
===================================================================
--- src/vsip/impl/expr_serial_dispatch.hpp	(revision 146321)
+++ src/vsip/impl/expr_serial_dispatch.hpp	(working copy)
@@ -27,9 +27,12 @@
 #include <vsip/impl/sal.hpp>
 #endif
 
-#ifdef VSIP_IMPL_HAVE_SIMD_GENERIC
+#ifdef VSIP_IMPL_HAVE_SIMD_LOOP_FUSION
 #  include <vsip/impl/simd/expr_evaluator.hpp>
 #endif
+#ifdef VSIP_IMPL_HAVE_SIMD_GENERIC
+#  include <vsip/impl/simd/eval-generic.hpp>
+#endif
 #ifdef VSIP_IMPL_HAVE_SIMD_3DNOWEXT
 #  include <vsip/impl/simd/eval-simd-3dnowext.hpp>
 #endif
Index: src/vsip/impl/expr_serial_evaluator.hpp
===================================================================
--- src/vsip/impl/expr_serial_evaluator.hpp	(revision 146321)
+++ src/vsip/impl/expr_serial_evaluator.hpp	(working copy)
@@ -31,14 +31,19 @@
 namespace impl
 {
 
-struct Loop_fusion_tag;
-struct Intel_ipp_tag;
-struct Mercury_sal_tag;
-struct Simd_tag;
-struct Transpose_tag;
-struct Copy_tag;
-struct Dense_expr_tag;
+// Evaluator tags.  These are placed in LibraryTagList and
+// determine the order in which expression evaluators are tried.
+// (The order here approximates LibraryTagList)
 
+struct Simd_builtin_tag;	// Builtin SIMD routines (non loop fusion)
+struct Intel_ipp_tag;		// Intel IPP Library
+struct Transpose_tag;		// Optimized Matrix Transpose
+struct Mercury_sal_tag;		// Mercury SAL Library
+struct Dense_expr_tag;		// Dense multi-dim expr reduction
+struct Copy_tag;		// Optimized Copy
+struct Simd_loop_fusion_tag;	// SIMD Loop Fusion.
+struct Loop_fusion_tag;		// Generic Loop Fusion (base case).
+
 /// Serial_expr_evaluator template.
 /// This needs to be provided for each tag in the LibraryTagList.
 template <dimension_type Dim,
Index: src/vsip/impl/profile.hpp
===================================================================
--- src/vsip/impl/profile.hpp	(revision 146321)
+++ src/vsip/impl/profile.hpp	(working copy)
@@ -16,6 +16,7 @@
 #include <string>
 #include <vector>
 #include <map>
+#include <string>
 
 #include <vsip/impl/config.hpp>
 #include <vsip/impl/noncopyable.hpp>
@@ -78,6 +79,8 @@
   static stamp_type sub(stamp_type , stamp_type) { return 0; }
   static float seconds(stamp_type) { return 0.f; }
   static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static bool is_zero(stamp_type const& stamp)
+    { return stamp == 0; }
 
   static stamp_type clocks_per_sec;
 };
@@ -99,6 +102,8 @@
   static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
   static float seconds(stamp_type time) { return (float)time / CLOCKS_PER_SEC; }
   static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static bool is_zero(stamp_type const& stamp)
+    { return stamp == stamp_type(); }
 
   static stamp_type clocks_per_sec;
 };
@@ -151,6 +156,8 @@
 
   static unsigned long ticks(stamp_type time)
     { return (unsigned long)(time.tv_sec * 1e9) + (unsigned long)time.tv_nsec; }
+  static bool is_zero(stamp_type const& stamp)
+    { return stamp.tv_nsec == 0 && stamp.tv_sec == 0; }
 
   static stamp_type clocks_per_sec;
 };
@@ -173,6 +180,8 @@
   static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
   static float seconds(stamp_type time) { return (float)time / (float)clocks_per_sec; }
   static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static bool is_zero(stamp_type const& stamp)
+    { return stamp == stamp_type(); }
 
   static stamp_type clocks_per_sec;
 };
@@ -197,6 +206,8 @@
   static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
   static float seconds(stamp_type time) { return (float)time / (float)clocks_per_sec; }
   static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static bool is_zero(stamp_type const& stamp)
+    { return stamp == stamp_type(); }
 
   static stamp_type clocks_per_sec;
 };
Index: src/vsip/map_fwd.hpp
===================================================================
--- src/vsip/map_fwd.hpp	(revision 146321)
+++ src/vsip/map_fwd.hpp	(working copy)
@@ -31,6 +31,9 @@
 class Global_map;
 
 template <dimension_type Dim>
+class Replicated_map;
+
+template <dimension_type Dim>
 class Local_or_global_map;
 
 namespace impl
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 146321)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -32,7 +32,10 @@
 src_vsip_cxx_sources += $(srcdir)/src/vsip/impl/fftw3/fft.cpp
 endif
 src_vsip_cxx_sources += $(srcdir)/src/vsip/impl/simd/vmul.cpp \
-			$(srcdir)/src/vsip/impl/simd/rscvmul.cpp
+			$(srcdir)/src/vsip/impl/simd/rscvmul.cpp \
+			$(srcdir)/src/vsip/impl/simd/vadd.cpp \
+			$(srcdir)/src/vsip/impl/simd/vgt.cpp \
+			$(srcdir)/src/vsip/impl/simd/vlogic.cpp
 src_vsip_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(src_vsip_cxx_sources))
 cxx_sources += $(src_vsip_cxx_sources)
 
Index: src/vsip_csl/GNUmakefile.inc.in
===================================================================
--- src/vsip_csl/GNUmakefile.inc.in	(revision 146321)
+++ src/vsip_csl/GNUmakefile.inc.in	(working copy)
@@ -24,6 +24,7 @@
 endif
 src_vsip_csl_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT),\
                               $(src_vsip_csl_cxx_sources))
+cxx_sources += $(src_vsip_csl_cxx_sources)
 
 libs += lib/libvsip_csl.a
 
Index: vendor/GNUmakefile.inc.in
===================================================================
--- vendor/GNUmakefile.inc.in	(revision 146321)
+++ vendor/GNUmakefile.inc.in	(working copy)
@@ -140,66 +140,59 @@
 endif
 
 
+
 ########################################################################
+# FFTW Rules
+########################################################################
 
-
 USE_BUILTIN_FFTW  := @USE_BUILTIN_FFTW@
 USE_BUILTIN_FFTW_FLOAT := @USE_BUILTIN_FFTW_FLOAT@
 USE_BUILTIN_FFTW_DOUBLE := @USE_BUILTIN_FFTW_DOUBLE@
 USE_BUILTIN_FFTW_LONG_DOUBLE := @USE_BUILTIN_FFTW_LONG_DOUBLE@
 
-########################################################################
-# FFTW Rules
-########################################################################
+vpath %.h src:$(srcdir)
 
-ifdef USE_BUILTIN_FFTW
-
-ifdef USE_BUILTIN_FFTW_FLOAT
-LIBFFTW_FLOAT := vendor/fftw3f/.libs/libfftw3f.a
-$(LIBFFTW_FLOAT):
+lib/libfftw3f.a: vendor/fftw3f/.libs/libfftw3f.a
+	cp $< $@
+ 
+vendor/fftw3f/.libs/libfftw3f.a:
 	@echo "Building FFTW float (see fftw-f.build.log)"
 	@$(MAKE) -C vendor/fftw3f > fftw-f.build.log 2>&1
-else
-LIBFFTW_LONG_FLOAT :=
-endif
-ifdef USE_BUILTIN_FFTW_DOUBLE
-LIBFFTW_DOUBLE := vendor/fftw3/.libs/libfftw3.a
-$(LIBFFTW_DOUBLE):
+
+lib/libfftw3.a: vendor/fftw3/.libs/libfftw3.a
+	cp $< $@
+
+vendor/fftw3/.libs/libfftw3.a:
 	@echo "Building FFTW double (see fftw-d.build.log)"
 	@$(MAKE) -C vendor/fftw3 > fftw-d.build.log 2>&1
-else
-LIBFFTW_DOUBLE :=
-endif
 
-ifdef USE_BUILTIN_FFTW_LONG_DOUBLE
-LIBFFTW_LONG_DOUBLE := vendor/fftw3l/.libs/libfftw3l.a
-$(LIBFFTW_LONG_DOUBLE):
+lib/libfftw3l.a: vendor/fftw3l/.libs/libfftw3l.a
+	cp $< $@
+
+vendor/fftw3l/.libs/libfftw3l.a:
 	@echo "Building FFTW long double (see fftw-l.build.log)"
 	@$(MAKE) -C vendor/fftw3l > fftw-l.build.log 2>&1
-else
-LIBFFTW_LONG_DOUBLE :=
-endif
 
-vendor_FFTW_LIBS := $(LIBFFTW_FLOAT) $(LIBFFTW_DOUBLE) $(LIBFFTW_LONG_DOUBLE)
+ifdef USE_BUILTIN_FFTW
+  ifdef USE_BUILTIN_FFTW_FLOAT
+    vendor_FFTW_LIBS += lib/libfftw3f.a
+  endif
+  ifdef USE_BUILTIN_FFTW_DOUBLE
+    vendor_FFTW_LIBS += lib/libfftw3.a
+  endif
+  ifdef USE_BUILTIN_FFTW_LONG_DOUBLE
+    vendor_FFTW_LIBS += lib/libfftw3l.a
+  endif
+
 libs += $(vendor_FFTW_LIBS) 
 
-all:: $(vendor_FFTW_LIBS)
-	@rm -rf vendor/fftw/include
-	@mkdir -p vendor/fftw/include
-	@ln -s $(srcdir)/vendor/fftw/api/fftw3.h vendor/fftw/include/fftw3.h
-	@rm -rf vendor/fftw/lib
-	@mkdir -p vendor/fftw/lib
-	@for lib in $(vendor_FFTW_LIBS); do \
-          ln -s `pwd`/$$lib vendor/fftw/lib/`basename $$lib`; \
-          done
-
 clean::
 	@echo "Cleaning FFTW (see fftw.clean.log)"
-	@for ldir in $(subst /.libs/,,$(dir $(vendor_FFTW_LIBS))); do \
-	  echo "$(MAKE) -C $$ldir clean "; \
-	  $(MAKE) -C $$ldir clean; done  > fftw.clean.log 2>&1
+	@rm -f fftw.clean.log
+	@for ldir in $(subst .a,,$(subst lib/lib,,$(vendor_FFTW_LIBS))); do \
+	  $(MAKE) -C vendor/$$ldir clean >> fftw.clean.log 2>&1; \
+	  echo "$(MAKE) -C vendor/$$ldir clean "; done
 
-        # note: configure script constructs vendor/fftw/ symlinks used here.
 install:: $(vendor_FFTW_LIBS)
 	@echo "Installing FFTW"
 	$(INSTALL) -d $(DESTDIR)$(libdir)
@@ -207,5 +200,5 @@
 	  echo "$(INSTALL_DATA) $$lib  $(DESTDIR)$(libdir)"; \
 	  $(INSTALL_DATA) $$lib  $(DESTDIR)$(libdir); done
 	$(INSTALL) -d $(DESTDIR)$(includedir)
-	$(INSTALL_DATA) $(srcdir)/vendor/fftw/api/fftw3.h $(DESTDIR)$(includedir)
+	$(INSTALL_DATA) src/fftw3.h $(DESTDIR)$(includedir)
 endif
Index: tests/coverage_common.hpp
===================================================================
--- tests/coverage_common.hpp	(revision 146321)
+++ tests/coverage_common.hpp	(working copy)
@@ -63,8 +63,21 @@
   }
 };
 
+template <>
+struct Get_value<bool>
+{
+  static bool at(
+    vsip::index_type arg,
+    vsip::index_type i,
+    range_type =anyval)
+  {
+    vsip::Rand<float> rand(5*i + arg);
+    return rand.randu() > 0.5;
+  }
+};
 
 
+
 /***********************************************************************
   Unary Operator Tests
 ***********************************************************************/
Index: tests/coverage_binary.cpp
===================================================================
--- tests/coverage_binary.cpp	(revision 146321)
+++ tests/coverage_binary.cpp	(working copy)
@@ -35,6 +35,10 @@
 TEST_BINARY_FUNC(min,  min,  min,  anyval)
 TEST_BINARY_FUNC(band, band, band, anyval)
 TEST_BINARY_FUNC(bor,  bor,  bor,  anyval)
+TEST_BINARY_FUNC(bxor, bxor, bxor, anyval)
+TEST_BINARY_FUNC(land, land, land, anyval)
+TEST_BINARY_FUNC(lor,  lor,  lor,  anyval)
+TEST_BINARY_FUNC(lxor, lxor, lxor, anyval)
 
 
 
@@ -258,7 +262,12 @@
 
   vector_cases3<Test_band, int,           int>();
   vector_cases3<Test_bor,  int,           int>();
+  vector_cases3<Test_bxor, int,           int>();
 
+  vector_cases3<Test_land, bool,          bool>();
+  vector_cases3<Test_lor,  bool,          bool>();
+  vector_cases3<Test_lxor, bool,          bool>();
 
+
   matrix_cases3<Test_add, float, float>();
 }
Index: tests/coverage_unary.cpp
===================================================================
--- tests/coverage_unary.cpp	(revision 146321)
+++ tests/coverage_unary.cpp	(working copy)
@@ -47,6 +47,8 @@
 TEST_UNARY(sq,    sq,    sq,    anyval)
 TEST_UNARY(recip, recip, recip, nonzero)
 
+TEST_UNARY(bnot,  bnot,  bnot,  anyval)
+TEST_UNARY(lnot,  lnot,  lnot,  anyval)
 
 
 
@@ -116,4 +118,7 @@
 
   vector_cases2_mix<Test_copy, complex<float> >();
   vector_cases2_mix<Test_copy, complex<double> >();
+
+  vector_cases2<Test_bnot, int>();
+  vector_cases2<Test_lnot, bool>();
 }
Index: configure.ac
===================================================================
--- configure.ac	(revision 146321)
+++ configure.ac	(working copy)
@@ -268,11 +268,16 @@
                  [set CPU speed in MHz.  Only necessary for TSC and if /proc/cpuinfo does not exist or is wrong]),,
   [enable_cpu_mhz=none])
 
-AC_ARG_WITH([simd],
-  AS_HELP_STRING([--with-simd=WHAT],
-                 [set SIMD extensions]),,
-  [with_simd=none])
+AC_ARG_ENABLE([simd_loop_fusion],
+  AS_HELP_STRING([--enable-simd-loop-fusion],
+                 [Enable SIMD loop-fusion]),,
+  [enable_simd_loop_fusion=no])
 
+AC_ARG_WITH([builtin_simd_routines],
+  AS_HELP_STRING([--with-builtin-simd-routines=WHAT],
+                 [Use builtin SIMD routines]),,
+  [with_builtin_simd_routines=none])
+
 AC_ARG_WITH([test_level],
   AS_HELP_STRING([--with-test-level=WHAT],
                  [set effort level for test-suite.  0 for low-level
@@ -1465,21 +1470,6 @@
 	fi
         fi # test "x$with_atlas_tarball" != "x"
 
-        # AC_SUBST(USE_BUILTIN_ATLAS, 1)
-        AC_SUBST(BUILD_ATLAS, 1)
-        if test "$trypkg" == "fortran-builtin"; then
-          AC_SUBST(BUILD_REF_LAPACK,  1)
-          AC_SUBST(BUILD_REF_CLAPACK, "")
-          AC_SUBST(BUILD_LIBF77,      "")
-        else
-          AC_SUBST(BUILD_REF_LAPACK,  "")
-          AC_SUBST(BUILD_REF_CLAPACK, 1)
-          AC_SUBST(BUILD_LIBF77,      1)
-        fi
-        AC_SUBST(BUILD_REF_CLAPACK_BLAS, "")
-        AC_SUBST(USE_ATLAS_LAPACK,       1)
-        AC_SUBST(USE_SIMPLE_LAPACK,      "")
-
 	curdir=`pwd`
 	if test "`echo $srcdir | sed -n '/^\//p'`" != ""; then
 	  my_abs_top_srcdir="$srcdir"
@@ -1492,15 +1482,22 @@
 	# fail).  Instead we add them to LATE_LIBS, which gets added to
 	# LIBS just before AC_OUTPUT.
 
+        AC_SUBST(BUILD_ATLAS,            1)
+        AC_SUBST(BUILD_REF_CLAPACK_BLAS, "")
+        AC_SUBST(USE_ATLAS_LAPACK,       1)
+        AC_SUBST(USE_SIMPLE_LAPACK,      "")
 	if test "$trypkg" == "fortran-builtin"; then
 	  # When using Fortran LAPACK, we need ATLAS' f77blas (it
 	  # provides the Fortran BLAS bindings) and we need libg2c.
           LATE_LIBS="-llapack -lcblas -lf77blas -latlas $use_g2c $LATE_LIBS"
-          AC_SUBST(BUILD_REF_LAPACK, 1)  # Build lapack in vendor/lapack/SRC
+          AC_SUBST(BUILD_REF_LAPACK,  1)  # Build lapack in vendor/lapack/SRC
+          AC_SUBST(BUILD_REF_CLAPACK, "")
+          AC_SUBST(BUILD_LIBF77,      "")
         else
 	  # When using C LAPACK, we need libF77 (the builtin equivalent
 	  # of libg2c).
           LATE_LIBS="-llapack -lF77 -lcblas -latlas $LATE_LIBS"
+          AC_SUBST(BUILD_REF_LAPACK,  "")
 	  AC_SUBST(BUILD_REF_CLAPACK, 1)  # Build clapack in vendor/clapack/SRC
 	  AC_SUBST(BUILD_LIBF77,      1)  # clapack requires LIBF77
         fi
@@ -1696,16 +1693,28 @@
     [Hardcoded CPU Speed (in MHz).])
 fi
 
+
+
 #
-# Configure SIMD extensions
+# Configure use of SIMD loop-fusion
 #
-if test "$with_simd" != "none"; then
+if test "$enable_simd_loop_fusion" = "yes"; then
+  AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SIMD_LOOP_FUSION, 1,
+    [Define whether to use SIMD loop-fusion in expr dispatch.])
+fi
+
+
+
+#
+# Configure use of builtin SIMD routines
+#
+if test "$with_builtin_simd_routines" != "none"; then
   keep_IFS=$IFS
   IFS=","
 
   taglist=""
 
-  for simd_type in $with_simd; do
+  for simd_type in $with_builtin_simd_routines; do
     AC_MSG_CHECKING([SIMD Tag $simd_type])
     if test "$simd_type" == "3dnowext-32"; then
       taglist="${taglist}Simd_3dnowext_tag,"
@@ -1736,7 +1745,7 @@
       AC_MSG_RESULT([ok])
 
     elif test "$simd_type" == "generic"; then
-      taglist="${taglist}Simd_tag,"
+      taglist="${taglist}Simd_builtin_tag,"
       AC_DEFINE_UNQUOTED(VSIP_IMPL_HAVE_SIMD_GENERIC, 1,
           [Define whether to use Generic SIMD routines in expr dispatch.])
       AC_MSG_RESULT([ok])
Index: benchmarks/create_map.hpp
===================================================================
--- benchmarks/create_map.hpp	(revision 0)
+++ benchmarks/create_map.hpp	(revision 0)
@@ -0,0 +1,82 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    benchmarks/create_map.hpp
+    @author  Jules Bergmann
+    @date    2006-07-26
+    @brief   VSIPL++ Library: Benchmark utilities for creating maps.
+
+*/
+
+#ifndef VSIP_BENCHMARKS_CREATE_MAP_HPP
+#define VSIP_BENCHMARKS_CREATE_MAP_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/map.hpp>
+#include <vsip/parallel.hpp>
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <vsip::dimension_type Dim,
+	  typename             MapT>
+struct Create_map {};
+
+template <vsip::dimension_type Dim>
+struct Create_map<Dim, vsip::Local_map>
+{
+  typedef vsip::Local_map type;
+  static type exec() { return type(); }
+};
+
+template <vsip::dimension_type Dim>
+struct Create_map<Dim, vsip::Global_map<Dim> >
+{
+  typedef vsip::Global_map<Dim> type;
+  static type exec() { return type(); }
+};
+
+template <typename Dist0, typename Dist1, typename Dist2>
+struct Create_map<1, vsip::Map<Dist0, Dist1, Dist2> >
+{
+  typedef vsip::Map<Dist0, Dist1, Dist2> type;
+  static type exec() { return type(vsip::num_processors()); }
+};
+
+template <vsip::dimension_type Dim,
+	  typename             MapT>
+MapT
+create_map()
+{
+  return Create_map<Dim, MapT>::exec();
+}
+
+
+// Sync Policy: use barrier.
+
+struct Barrier
+{
+  Barrier() : comm_(DEFAULT_COMMUNICATOR()) {}
+
+  void sync() { BARRIER(comm_); }
+
+  COMMUNICATOR_TYPE comm_;
+};
+
+
+
+// Sync Policy: no barrier.
+
+struct No_barrier
+{
+  No_barrier() {}
+
+  void sync() {}
+};
+
+#endif // VSIP_BENCHMARKS_CREATE_MAP_HPP
Index: benchmarks/vmul.cpp
===================================================================
--- benchmarks/vmul.cpp	(revision 146321)
+++ benchmarks/vmul.cpp	(working copy)
@@ -17,6 +17,7 @@
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
+#include <vsip/selgen.hpp>
 #include <vsip/impl/setup-assign.hpp>
 #include "benchmarks.hpp"
 
@@ -581,6 +582,103 @@
 
 
 
+// Benchmark scalar-view vector multiply w/literal (Scalar * View)
+
+template <typename T>
+struct t_svmul3
+{
+  char* what() { return "t_svmul3"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 1*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 2*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    Vector<T>   A(size, T());
+    Vector<T>   C(size);
+
+    A.put(0, T(4));
+    
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+      C = 3.f * A;
+    t1.stop();
+
+    test_assert(equal(C.get(0), T(12)));
+    
+    time = t1.delta();
+  }
+};
+
+
+
+// Benchmark scalar-view vector multiply w/literal (Scalar * View)
+
+template <typename T,
+	  typename DataMapT  = Local_map,
+	  typename CoeffMapT = Local_map,
+	  typename SP        = No_barrier>
+struct t_svmul4
+{
+  char* what() { return "t_svmul4"; }
+  int ops_per_point(length_type)  { return vsip::impl::Ops_info<T>::mul; }
+  int riob_per_point(length_type) { return 1*sizeof(T); }
+  int wiob_per_point(length_type) { return 1*sizeof(T); }
+  int mem_per_point(length_type)  { return 2*sizeof(T); }
+
+  void operator()(length_type size, length_type loop, float& time)
+  {
+    typedef Dense<1, T, row1_type, DataMapT>  block_type;
+    typedef Dense<1, T, row1_type, CoeffMapT> coeff_block_type;
+
+    DataMapT  map_data  = create_map<1, DataMapT>();
+    CoeffMapT map_coeff = create_map<1, CoeffMapT>();
+
+    Vector<T, block_type>       A(size, T(), map_data);
+    Vector<T, block_type>       C(size,      map_data);
+    Vector<T, coeff_block_type> K(size, T(), map_coeff);
+
+    // ramp does not work for distributed assignments (060726)
+    // A = cos(ramp(0.f, 0.15f*3.14159f, size));
+    for (index_type i=0; i<A.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(A, 0, i);
+      A.local().put(i, cos(T(g_i)*0.15f*3.14159f));
+    }
+
+    // ramp does not work for distributed assignments (060726)
+    // K = cos(ramp(0.f, 0.25f*3.14159f, size));
+    for (index_type i=0; i<K.local().size(); ++i)
+    {
+      index_type g_i = global_from_local_index(K, 0, i);
+      K.local().put(i, cos(T(g_i)*0.25f*3.14159f));
+    }
+
+    T alpha;
+
+    vsip::impl::profile::Timer t1;
+    
+    t1.start();
+    for (index_type l=0; l<loop; ++l)
+    {
+      alpha = K.get(1);
+      C = alpha * A;
+    }
+    t1.stop();
+
+    alpha = K.get(1);
+    for (index_type i=0; i<C.local().size(); ++i)
+      test_assert(equal(C.local().get(i), A.local().get(i) * alpha));
+    
+    time = t1.delta();
+  }
+};
+
+
+
 void
 defaults(Loop1P&)
 {
@@ -607,7 +705,12 @@
 
   case  14: loop(t_svmul2<float>()); break;
   case  15: loop(t_svmul2<complex<float> >()); break;
+  case  16: loop(t_svmul3<float>()); break;
 
+  case  17: loop(t_svmul4<float>()); break;
+  case  18: loop(t_svmul4<float, Map<>, Map<> >()); break;
+  case  19: loop(t_svmul4<float, Map<>, Global_map<1> >()); break;
+
   case  21: loop(t_vmul_dom1<float>()); break;
   case  22: loop(t_vmul_dom1<complex<float> >()); break;
 
@@ -635,18 +738,20 @@
   case 0:
     std::cout
       << "vmul -- vector multiplication\n"
+      << " Vector-Vector:\n"
       << "   -1 -- Vector<        float > * Vector<        float >\n"
       << "   -2 -- Vector<complex<float>> * Vector<complex<float>>\n"
-      << "   -1 --         float  vector *         float  vector\n"
-      << "   -2 -- complex<float> vector * complex<float> vector\n"
-      << "   -3 -- complex<float> vector * complex<float> vector (split)\n"
-      << "   -4 -- complex<float> vector * complex<float> vector (inter)\n"
-      << "   -5 --         float  vector * complex<float> vector\n"
-      << "  -11 --         float  scalar *         float  vector\n"
-      << "  -12 --         float  scalar * complex<float> vector\n"
-      << "  -13 -- complex<float> scalar * complex<float> vector\n"
+      << "   -3 -- Vector<complex<float>> * Vector<complex<float>> (SPLIT)\n"
+      << "   -4 -- Vector<complex<float>> * Vector<complex<float>> (INTER)\n"
+      << "   -5 -- Vector<        float > * Vector<complex<float>>\n"
+      << " Scalar-Vector:\n"
+      << "  -11 --                float   * Vector<        float >\n"
+      << "  -12 --                float   * Vector<complex<float>>\n"
+      << "  -13 --        complex<float>  * Vector<complex<float>>\n"
       << "  -14 -- t_svmul2\n"
       << "  -15 -- t_svmul2\n"
+      << "  -15 -- t_svmul3\n"
+      << "  -15 -- t_svmul4\n"
       << "  -21 -- t_vmul_dom1\n"
       << "  -22 -- t_vmul_dom1\n"
       << "  -31 -- t_vmul_ip1\n"
Index: examples/mercury/mcoe-setup.sh
===================================================================
--- examples/mercury/mcoe-setup.sh	(revision 146321)
+++ examples/mercury/mcoe-setup.sh	(working copy)
@@ -23,6 +23,7 @@
 #   comm="ser"			# set to (ser)ial or (par)allel.
 #   fmt="inter"			# set to (inter)leaved or (split).
 #   opt="y"			# (y) for optimized flags, (n) for debug flags.
+#   builtin_simd="y"		# (y) for builtin SIMD routines, (n) for not.
 #   pflags="-t ppc7400_le"	# processor architecture
 #   fft="sal,builtin"		# FFT backend(s)
 #   testlevel="0"		# Test level
@@ -47,6 +48,10 @@
   opt="y"			# (y) for optimized flags, (n) for debug flags.
 fi
 
+if test "x$builtin_simd" = x; then
+  builtin_simd="y"			# (y) for builtin SIMD, (n) for not.
+fi
+
 if test "x$exceptions" = x; then
   exceptions="n"		# (y) for exceptions, (n) for not.
 fi
@@ -107,6 +112,10 @@
   cxxflags="$cxxflags -g"
 fi
 
+if test $builtin_simd = "y"; then
+  cfg_flags="$cfg_flags --with-builtin-simd-routines=generic"
+fi
+
 if test $exceptions = "n"; then
   cxxflags="$cxxflags --no_exceptions"
   cfg_flags="$cfg_flags --disable-exceptions"
@@ -130,6 +139,7 @@
 	--with-fftw3-cflags="-O2"		\
 	--with-complex=$fmt			\
 	--with-lapack=no			\
+	--disable-simd-loop-fusion		\
 	$cfg_flags				\
 	--with-test-level=$testlevel		\
 	--enable-profile-timer=realtime
