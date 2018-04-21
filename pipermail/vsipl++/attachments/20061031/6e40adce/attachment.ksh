Index: ChangeLog
===================================================================
--- ChangeLog	(revision 153482)
+++ ChangeLog	(working copy)
@@ -1,5 +1,34 @@
 2006-10-31  Jules Bergmann  <jules@codesourcery.com>
 
+	Rename isnan to is_nan (and ilk) since isnan may be a macro.
+	* src/vsip/core/fns_scalar.hpp: Rename is_nan and ilk.
+	* src/vsip/core/fns_elementwise.hpp: Likewise.
+	* src/vsip_csl/error_db.hpp: Likewise.
+
+	Add view_cast for view type conversions.
+	* src/vsip/opt/view_cast.hpp: New file, implement view_cast fcn
+	  and Cast operator.
+	* tests/view_cast.cpp: New file, unit test for view_cast.
+	
+	Add SAL dispatch for view type conversions.
+	* src/vsip/opt/sal/is_op_supported.hpp: Add Op1sup specializations
+	  for supported conversions.
+	* src/vsip/opt/sal/elementwise.hpp: Add vconv wrapper function.
+	* src/vsip/opt/sal/eval_elementwise.hpp: Add dispatch to vconv.
+
+
+	Misc changes.
+	* src/vsip/core/allocation.cpp: Handle 0 return from malloc properly.
+	* src/vsip/map.hpp: Remove old comment.
+	* src/vsip_csl/load_view.hpp: Add missing header.
+	* tests/regressions/ext_subview_split.cpp: Update path to fast_block
+	  header.
+	* doc/GNUmakefile.inc.in (doc2src_noapi): Like doc2src target, but
+	  does not build API docs.  Allows snapshot to be built when
+	  API doc generation is broken.
+	
+2006-10-31  Jules Bergmann  <jules@codesourcery.com>
+
 	PAS for Linux binary package (for testing purposes).
 	* scripts/package.py: Update path to acconfig.hpp.
 	* scripts/config: Add binary package for PAS.  Update x86 test
Index: src/vsip/core/fns_scalar.hpp
===================================================================
--- src/vsip/core/fns_scalar.hpp	(revision 153482)
+++ src/vsip/core/fns_scalar.hpp	(working copy)
@@ -116,41 +116,74 @@
 inline T 
 ite(bool pred, T a, T b) VSIP_NOTHROW { return pred ? a : b;}
 
+// isfinite, isnan, and isnormal are macros provided by C99 <math.h>
+// They are not part of C++ <cmath>.
+//
+// GCC's cmath captures them, removing the macros, and providing
+// functions std::isfinite, std::isnan, and std::isnormal.
+//
+// GreenHills on MCOE only provides macros.
 
-// isfinite -- returns nonzero/true if x is finite not plus or minus inf,
-//             and not NaN (C99).
-
+#if __GNUC__ >= 2
+// Pull isfinite, isnan, and isnormal into fn namespace so Fp_traits
+// can see them.
 using std::isfinite;
+using std::isnan;
+using std::isnormal;
+#endif
 
 template <typename T>
-inline bool isfinite(std::complex<T> const& val)
+struct Fp_traits
 {
-  return isfinite(val.real()) && isnan(val.imag());
-}
+  static bool is_finite(T val) { return isfinite(val); }
+  static bool is_nan(T val)    { return isnan(val);    }
+  static bool is_normal(T val) { return isnormal(val); }
+};
 
+template <typename T>
+ struct Fp_traits<std::complex<T> >
+{
+  static bool is_finite(std::complex<T> const& val)
+  { return isfinite(val.real()) && isfinite(val.imag()); }
 
-// isnan -- returns nonzero/true if x is NaN. (C99).
+  static bool is_nan(std::complex<T> const& val)    
+  { return isnan(val.real()) || isnan(val.imag()); }
 
-using std::isnan;
+  static bool is_normal(std::complex<T> const& val) 
+  { return isnormal(val.real()) && isnormal(val.imag()); }
+};
 
+
+// is_finite -- returns nonzero/true if x is finite not plus or minus inf,
+//              and not NaN.
+
 template <typename T>
-inline bool isnan(std::complex<T> const& val)
+inline bool is_finite(T val)
 {
-  return isnan(val.real()) || isnan(val.imag());
+  return Fp_traits<T>::is_finite(val);
 }
 
 
+// is_nan -- returns nonzero/true if x is NaN.
+
+template <typename T>
+inline bool is_nan(T val)
+{
+  return Fp_traits<T>::is_nan(val);
+}
+
+
 // isnormal -- returns nonzero/true if x is finite and normalized. (C99).
 
-using std::isnormal;
-
 template <typename T>
-inline bool isnormal(std::complex<T> const& val)
+inline bool
+is_normal(T val)
 {
-  return isnormal(val.real()) || isnormal(val.imag());
+  return Fp_traits<T>::is_normal(val);
 }
 
 
+
 template <typename T>
 inline T 
 lnot(T t) VSIP_NOTHROW { return !t;}
Index: src/vsip/core/allocation.cpp
===================================================================
--- src/vsip/core/allocation.cpp	(revision 153482)
+++ src/vsip/core/allocation.cpp	(working copy)
@@ -47,6 +47,7 @@
   assert(sizeof(void*) == sizeof(size_t));
 
   void*  ptr  = malloc(size + align);
+  if (ptr == 0) return 0;
   size_t mask = ~(align-1);
   void*  ret  = (void*)(((size_t)ptr + align) & mask);
   *((void**)ret - 1) = ptr;
Index: src/vsip/core/fns_elementwise.hpp
===================================================================
--- src/vsip/core/fns_elementwise.hpp	(revision 153482)
+++ src/vsip/core/fns_elementwise.hpp	(working copy)
@@ -313,9 +313,9 @@
 VSIP_IMPL_UNARY_DISPATCH(imag)
 VSIP_IMPL_UNARY_FUNCTION(imag)
 
-VSIP_IMPL_UNARY_VIEW_FUNC_RETN(isfinite, bool)
-VSIP_IMPL_UNARY_VIEW_FUNC_RETN(isnan, bool)
-VSIP_IMPL_UNARY_VIEW_FUNC_RETN(isnormal, bool)
+VSIP_IMPL_UNARY_VIEW_FUNC_RETN(is_finite, bool)
+VSIP_IMPL_UNARY_VIEW_FUNC_RETN(is_nan, bool)
+VSIP_IMPL_UNARY_VIEW_FUNC_RETN(is_normal, bool)
 
 VSIP_IMPL_UNARY_FUNC_RETN(lnot, bool)
 VSIP_IMPL_UNARY_FUNC(log)
Index: src/vsip/opt/sal/is_op_supported.hpp
===================================================================
--- src/vsip/opt/sal/is_op_supported.hpp	(revision 153482)
+++ src/vsip/opt/sal/is_op_supported.hpp	(working copy)
@@ -14,6 +14,7 @@
 ***********************************************************************/
 
 #include <vsip/core/fns_elementwise.hpp>
+#include <vsip/opt/view_cast.hpp>
 
 
 
@@ -176,8 +177,21 @@
 VSIP_IMPL_OP1SUP(copy_token,    split_double,     complex<double>*);
 VSIP_IMPL_OP1SUP(copy_token,    complex<double>*, split_double);
 
+VSIP_IMPL_OP1SUP(Cast_closure<long          >::Cast, float*, long*);
+VSIP_IMPL_OP1SUP(Cast_closure<short         >::Cast, float*, short*);
+VSIP_IMPL_OP1SUP(Cast_closure<char          >::Cast, float*, char*);
+VSIP_IMPL_OP1SUP(Cast_closure<unsigned long >::Cast, float*, unsigned long*);
+VSIP_IMPL_OP1SUP(Cast_closure<unsigned short>::Cast, float*, unsigned short*);
+VSIP_IMPL_OP1SUP(Cast_closure<unsigned char >::Cast, float*, unsigned char*);
 
+VSIP_IMPL_OP1SUP(Cast_closure<float>::Cast, long*, float*);
+VSIP_IMPL_OP1SUP(Cast_closure<float>::Cast, short*, float*);
+VSIP_IMPL_OP1SUP(Cast_closure<float>::Cast, char*, float*);
+VSIP_IMPL_OP1SUP(Cast_closure<float>::Cast, unsigned long*, float*);
+VSIP_IMPL_OP1SUP(Cast_closure<float>::Cast, unsigned short*, float*);
+VSIP_IMPL_OP1SUP(Cast_closure<float>::Cast, unsigned char*, float*);
 
+
 /***********************************************************************
   Binary operators and functions provided by SAL
 ***********************************************************************/
Index: src/vsip/opt/sal/elementwise.hpp
===================================================================
--- src/vsip/opt/sal/elementwise.hpp	(revision 153482)
+++ src/vsip/opt/sal/elementwise.hpp	(working copy)
@@ -221,7 +221,39 @@
 
 
 
+// Vector conversion
+#define VSIP_IMPL_SAL_VCONV(FCN, ST, DT, SALFCN)			\
+VSIP_IMPL_SAL_INLINE void						\
+FCN(									\
+  Sal_vector<ST> const& A,						\
+  Sal_vector<DT> const& Z,						\
+  length_type len)							\
+{									\
+  float scale = 1.f;							\
+  float bias  = 0.f;							\
+  VSIP_IMPL_COVER_FCN("SAL_VCONV", SALFCN)				\
+  SALFCN(A.ptr, A.stride, Z.ptr, Z.stride, &scale, &bias, len,		\
+	 SAL_ROUND_ZERO, 0);						\
+}
 
+VSIP_IMPL_SAL_VCONV(vconv, float,          long,  vconvert_f32_s32x);
+VSIP_IMPL_SAL_VCONV(vconv, float,          short, vconvert_f32_s16x);
+VSIP_IMPL_SAL_VCONV(vconv, float,          char,  vconvert_f32_s8x);
+VSIP_IMPL_SAL_VCONV(vconv, float, unsigned long,  vconvert_f32_u32x);
+VSIP_IMPL_SAL_VCONV(vconv, float, unsigned short, vconvert_f32_u16x);
+VSIP_IMPL_SAL_VCONV(vconv, float, unsigned char,  vconvert_f32_u8x);
+
+VSIP_IMPL_SAL_VCONV(vconv,          long,  float, vconvert_s32_f32x);
+VSIP_IMPL_SAL_VCONV(vconv,          short, float, vconvert_s16_f32x);
+VSIP_IMPL_SAL_VCONV(vconv,          char,  float, vconvert_s8_f32x);
+VSIP_IMPL_SAL_VCONV(vconv, unsigned long,  float, vconvert_u32_f32x);
+VSIP_IMPL_SAL_VCONV(vconv, unsigned short, float, vconvert_u16_f32x);
+VSIP_IMPL_SAL_VCONV(vconv, unsigned char,  float, vconvert_u8_f32x);
+
+#undef VSIP_IMPL_SAL_VCONV
+
+
+
 /***********************************************************************
   Binary Functions
 ***********************************************************************/
Index: src/vsip/opt/sal/eval_elementwise.hpp
===================================================================
--- src/vsip/opt/sal/eval_elementwise.hpp	(revision 153482)
+++ src/vsip/opt/sal/eval_elementwise.hpp	(working copy)
@@ -24,6 +24,7 @@
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/opt/sal/eval_util.hpp>
 #include <vsip/core/adjust_layout.hpp>
+#include <vsip/opt/view_cast.hpp>
 #include <vsip/opt/sal/is_op_supported.hpp>
 
 
@@ -212,8 +213,17 @@
 VSIP_IMPL_SAL_V_EXPR(sq_functor,    sal::vsq)
 VSIP_IMPL_SAL_V_EXPR(recip_functor, sal::vrecip)
 
+VSIP_IMPL_SAL_V_EXPR(Cast_closure<long          >::Cast, sal::vconv)
+VSIP_IMPL_SAL_V_EXPR(Cast_closure<short         >::Cast, sal::vconv)
+VSIP_IMPL_SAL_V_EXPR(Cast_closure<char          >::Cast, sal::vconv)
+VSIP_IMPL_SAL_V_EXPR(Cast_closure<unsigned long >::Cast, sal::vconv)
+VSIP_IMPL_SAL_V_EXPR(Cast_closure<unsigned short>::Cast, sal::vconv)
+VSIP_IMPL_SAL_V_EXPR(Cast_closure<unsigned char >::Cast, sal::vconv)
 
+VSIP_IMPL_SAL_V_EXPR(Cast_closure<float>::Cast, sal::vconv)
 
+
+
 /***********************************************************************
   Binary expression evaluators
 ***********************************************************************/
Index: src/vsip/opt/view_cast.hpp
===================================================================
--- src/vsip/opt/view_cast.hpp	(revision 0)
+++ src/vsip/opt/view_cast.hpp	(revision 0)
@@ -0,0 +1,110 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    vsip/core/view_cast.hpp
+    @author  Jules Bergmann
+    @date    2005-06-15
+    @brief   VSIPL++ Library: View cast class.
+
+*/
+
+#ifndef VSIP_CORE_VIEW_CAST_HPP
+#define VSIP_CORE_VIEW_CAST_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/support.hpp>
+#include <vsip/core/block_traits.hpp>
+#include <vsip/core/noncopyable.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+
+namespace impl
+{
+
+// Cast operator 'Cast'.  Return type of cast is set through Cast_closuere.
+
+template <typename T>
+struct Cast_closure
+{
+  template <typename Operand>
+  struct Cast
+  {
+    typedef T result_type;
+
+    static char const* name() { return "cast"; }
+    static result_type apply(Operand op) { return static_cast<result_type>(op); }
+    result_type operator()(Operand op) const { return apply(op); }
+  };
+};
+
+
+
+// Helper class to determine the return type of view_cast function
+// and handle actual casting.
+
+template <typename                            T,
+	  template <typename, typename> class ViewT,
+	  typename                            T1,
+	  typename                            Block1>
+struct View_cast
+{
+  typedef const Unary_expr_block<ViewT<T1, Block1>::dim,
+				 Cast_closure<T>::template Cast,
+				 Block1, T1> block_type;
+
+  typedef typename ViewConversion<ViewT, T1, block_type>::const_view_type
+    view_type;
+
+  static view_type cast(ViewT<T1, Block1> const& view)
+  {
+    block_type blk(view.block());
+    return view_type(blk);
+  }
+};
+
+
+
+/// Specialization to avoid unnecessary cast when T == T1.
+
+template <typename                            T1,
+	  template <typename, typename> class ViewT,
+	  typename                            Block1>
+struct View_cast<T1, ViewT, T1, Block1>
+{
+  typedef ViewT<T1, Block1> view_type;
+
+  static view_type cast(ViewT<T1, Block1> const& v)
+  {
+    return v;
+  }
+};
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <typename                            T,
+	  template <typename, typename> class ViewT,
+	  typename                            T1,
+	  typename                            Block1>
+typename View_cast<T, ViewT, T1, Block1>::view_type
+view_cast(ViewT<T1, Block1> const& view)
+{
+  return View_cast<T, ViewT, T1, Block1>::cast(view);
+}
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_CAST_BLOCK_HPP
Index: src/vsip/map.hpp
===================================================================
--- src/vsip/map.hpp	(revision 153482)
+++ src/vsip/map.hpp	(working copy)
@@ -361,14 +361,6 @@
   Domain<3>	         dom_;		  // Applied domain.
   dimension_type         dim_;		  // Dimension of applied domain.
   impl::par_ll_pset_type applied_pset_;
-
-  // Base map that this map was created from (or this map if created
-  // from scratch).  This is used to optimize a common case of
-  // comparing two maps for equivalence when they are created from the
-  // same source map.  Since non-applied properties of maps cannot be
-  // modified after creation, if two maps have the same base_map_
-  // pointer, they are equivalanet.
-  // Map* const         base_map_;
 };
 
 
Index: src/vsip_csl/error_db.hpp
===================================================================
--- src/vsip_csl/error_db.hpp	(revision 153482)
+++ src/vsip_csl/error_db.hpp	(working copy)
@@ -69,7 +69,7 @@
   using vsip::dimension_type;
 
   // garbage in, garbage out.
-  if (anytrue(isnan(v1)) || anytrue(isnan(v2)))
+  if (anytrue(is_nan(v1)) || anytrue(is_nan(v2)))
     return 201.0;
 
   test_assert(Dim_of_view<View1>::dim == Dim_of_view<View2>::dim);
Index: src/vsip_csl/load_view.hpp
===================================================================
--- src/vsip_csl/load_view.hpp	(revision 153482)
+++ src/vsip_csl/load_view.hpp	(working copy)
@@ -13,6 +13,7 @@
   Included Files
 ***********************************************************************/
 
+#include <iostream>
 #include <string.h>
 #include <errno.h>
 #include <memory>
Index: tests/regressions/ext_subview_split.cpp
===================================================================
--- tests/regressions/ext_subview_split.cpp	(revision 153482)
+++ tests/regressions/ext_subview_split.cpp	(working copy)
@@ -14,7 +14,7 @@
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
 #include <vsip/tensor.hpp>
-#include <vsip/opt/fast_block.hpp>
+#include <vsip/core/fast_block.hpp>
 
 #include <vsip_csl/test.hpp>
 
Index: tests/view_cast.cpp
===================================================================
--- tests/view_cast.cpp	(revision 0)
+++ tests/view_cast.cpp	(revision 0)
@@ -0,0 +1,95 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    tests/view_cast.cpp
+    @author  Jules Bergmann
+    @date    2006-10-31
+    @brief   VSIPL++ Library: Test View_cast.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/random.hpp>
+#include <vsip/selgen.hpp>
+#include <vsip/opt/view_cast.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+using vsip_csl::equal;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+
+template <typename T1,
+	  typename T2>
+void
+test_view_cast(length_type size)
+{
+  Vector<T1> src(size);
+  Vector<T2> dst(size);
+
+  Rand<T1> rand(0);
+
+  src = T1(100) * rand.randu(size);
+
+  dst = vsip::impl::view_cast<T2>(src);
+
+  for (index_type i=0; i<size; ++i)
+    test_assert(equal(dst.get(i),
+		      static_cast<T2>(src.get(i))));
+
+  src = ramp(T1(0), T1(1), size);
+
+  dst = vsip::impl::view_cast<T2>(src);
+
+  for (index_type i=0; i<size; ++i)
+    test_assert(equal(dst.get(i),
+		      static_cast<T2>(src.get(i))));
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
+  test_view_cast<float, int>(100);
+
+  // SAL dispatch exists for these
+  test_view_cast<float, long>(100);
+  test_view_cast<float, short>(100);
+  test_view_cast<float, char>(100);
+  test_view_cast<float, signed long>(100);
+  test_view_cast<float, signed short>(100);
+  test_view_cast<float, signed char>(100);
+  test_view_cast<float, unsigned long>(100);
+  test_view_cast<float, unsigned short>(100);
+  test_view_cast<float, unsigned char>(100);
+
+  // these too.
+  test_view_cast<long,           float>(100);
+  test_view_cast<short,          float>(100);
+  test_view_cast<char,           float>(100);
+  test_view_cast<signed long,    float>(100);
+  test_view_cast<signed short,   float>(100);
+  test_view_cast<signed char,    float>(100);
+  test_view_cast<unsigned long,  float>(100);
+  test_view_cast<unsigned short, float>(100);
+  test_view_cast<unsigned char,  float>(100);
+
+  return 0;
+}
Index: doc/GNUmakefile.inc.in
===================================================================
--- doc/GNUmakefile.inc.in	(revision 153482)
+++ doc/GNUmakefile.inc.in	(working copy)
@@ -121,6 +121,21 @@
 	rm -rf $(srcdir)/doc/reference
 	mkdir -p $(srcdir)/doc/reference
 	cp -r doc/reference/reference $(srcdir)/doc/reference
+
+# Lite version of doc2src, does not generate API docs.
+doc2src_noapi: $(html_manuals) $(pdf_manuals)
+	for f in quickstart tutorial; do \
+	  if test -d doc/$$f/$$f; then \
+            mkdir -p $(srcdir)/doc/$$f; \
+            rm -rf $(srcdir)/doc/$$f/$$f; \
+            cp -r doc/$$f/$$f $(srcdir)/doc/$$f; \
+            cp doc/$$f/$$f.html $(srcdir)/doc/$$f; \
+          fi; \
+	  if test -r doc/$$f/$$f.pdf; then \
+            mkdir -p $(srcdir)/doc/$$f; \
+            cp -r doc/$$f/$$f.pdf $(srcdir)/doc/$$f; \
+          fi; \
+        done
 endif
 
 mostlyclean::
