Index: src/vsip/core/fns_scalar.hpp
===================================================================
--- src/vsip/core/fns_scalar.hpp	(revision 152397)
+++ src/vsip/core/fns_scalar.hpp	(working copy)
@@ -116,7 +116,42 @@
 inline T 
 ite(bool pred, T a, T b) VSIP_NOTHROW { return pred ? a : b;}
 
+
+// isfinite -- returns nonzero/true if x is finite not plus or minus inf,
+//             and not NaN (C99).
+
+using std::isfinite;
+
 template <typename T>
+inline bool isfinite(std::complex<T> const& val)
+{
+  return isfinite(val.real()) && isnan(val.imag());
+}
+
+
+// isnan -- returns nonzero/true if x is NaN. (C99).
+
+using std::isnan;
+
+template <typename T>
+inline bool isnan(std::complex<T> const& val)
+{
+  return isnan(val.real()) || isnan(val.imag());
+}
+
+
+// isnormal -- returns nonzero/true if x is finite and normalized. (C99).
+
+using std::isnormal;
+
+template <typename T>
+inline bool isnormal(std::complex<T> const& val)
+{
+  return isnormal(val.real()) || isnormal(val.imag());
+}
+
+
+template <typename T>
 inline T 
 lnot(T t) VSIP_NOTHROW { return !t;}
 
Index: src/vsip/core/fns_elementwise.hpp
===================================================================
--- src/vsip/core/fns_elementwise.hpp	(revision 152397)
+++ src/vsip/core/fns_elementwise.hpp	(working copy)
@@ -62,6 +62,18 @@
 typename Dispatch_##fname<T>::result_type                                 \
 fname(T t) { return Dispatch_##fname<T>::apply(t);}
 
+// This function gateway is roughly specialized to VSIPL++ view types.
+// This prevents it from competing with more general function overloads.
+// For example, cmath defines template <typename T> bool isnan(T& t)
+// which is ambiguous with the normal VSIP_IMPL_UNARY_FUNCTION.
+#define VSIP_IMPL_UNARY_VIEW_FUNCTION(fname)				  \
+template <template <typename, typename> class V,                          \
+          typename T, typename B>                                         \
+inline                                                                    \
+typename Dispatch_##fname<V<T,B> >::result_type				  \
+fname(V<T,B> t)								  \
+{ return Dispatch_##fname<V<T,B> >::apply(t);}
+
 #define VSIP_IMPL_UNARY_FUNC(fname)                                       \
 VSIP_IMPL_UNARY_FUNCTOR(fname)                                            \
 VSIP_IMPL_UNARY_DISPATCH(fname)                                           \
@@ -72,6 +84,11 @@
 VSIP_IMPL_UNARY_DISPATCH(fname)                                           \
 VSIP_IMPL_UNARY_FUNCTION(fname)
 
+#define VSIP_IMPL_UNARY_VIEW_FUNC_RETN(fname, retn)                       \
+VSIP_IMPL_UNARY_FUNCTOR_RETN(fname, retn)                                 \
+VSIP_IMPL_UNARY_DISPATCH(fname)                                           \
+VSIP_IMPL_UNARY_VIEW_FUNCTION(fname)
+
 // Define a unary operator. Assume the associated Dispatch 
 // is already defined.
 #define VSIP_IMPL_UNARY_OP(op, fname)                                     \
@@ -296,6 +313,10 @@
 VSIP_IMPL_UNARY_DISPATCH(imag)
 VSIP_IMPL_UNARY_FUNCTION(imag)
 
+VSIP_IMPL_UNARY_VIEW_FUNC_RETN(isfinite, bool)
+VSIP_IMPL_UNARY_VIEW_FUNC_RETN(isnan, bool)
+VSIP_IMPL_UNARY_VIEW_FUNC_RETN(isnormal, bool)
+
 VSIP_IMPL_UNARY_FUNC_RETN(lnot, bool)
 VSIP_IMPL_UNARY_FUNC(log)
 VSIP_IMPL_UNARY_FUNC(log10)
Index: src/vsip_csl/error_db.hpp
===================================================================
--- src/vsip_csl/error_db.hpp	(revision 152397)
+++ src/vsip_csl/error_db.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip_csl/error_db.cpp
     @author  Jules Bergmann
@@ -14,6 +14,8 @@
   Included Files
 ***********************************************************************/
 
+#include <algorithm>
+
 #include <vsip/math.hpp>
 #include <vsip_csl/test.hpp>
 
@@ -25,6 +27,33 @@
   Definitions
 ***********************************************************************/
 
+// Compute the distance between two views in terms of relative magsq
+// difference in decibels.
+//
+// Requires
+//   V1 and V2 to be VSIPL++ views of the same dimensionality
+//      and same value type.
+//
+// Returns
+//   The result is computed by the equation:
+//
+//                            max(magsq(v1 - v2)
+//     error_db = 10 * log10( ------------------ )
+//                               2 * refmax
+//
+//   Smaller (more negative) error dBs are better.  An error dB of -201
+//   indicates that the two views are practically equal.  An error dB of
+//   0 indicates that the views have elements that are negated
+//   (v1(idx) == -v2(idx)).
+//
+//   If either input contains a NaN value, an error dB of 201 is returned.
+//
+//   For example, an error dB of -50 indicates that
+//
+//       max(magsq(v1 - v2)
+//     ( ------------------ ) < 10^-5
+//          2 * refmax
+
 template <template <typename, typename> class View1,
 	  template <typename, typename> class View2,
 	  typename                            T1,
@@ -39,16 +68,22 @@
   using vsip::impl::Dim_of_view;
   using vsip::dimension_type;
 
+  // garbage in, garbage out.
+  if (anytrue(isnan(v1)) || anytrue(isnan(v2)))
+    return 201.0;
+
   test_assert(Dim_of_view<View1>::dim == Dim_of_view<View2>::dim);
   dimension_type const dim = Dim_of_view<View2>::dim;
 
   vsip::Index<dim> idx;
 
-  double refmax = maxval(magsq(v1), idx);
-  double maxsum = maxval(ite(magsq(v1 - v2) < 1.e-20,
-			     -201.0,
-			     10.0 * log10(magsq(v1 - v2)/(2.0*refmax)) ),
-			 idx);
+  double refmax1 = maxval(magsq(v1), idx);
+  double refmax2 = maxval(magsq(v2), idx);
+  double refmax  = std::max(refmax1, refmax2);
+  double maxsum  = maxval(ite(magsq(v1 - v2) < 1.e-20,
+			      -201.0,
+			      10.0 * log10(magsq(v1 - v2)/(2.0*refmax)) ),
+			  idx);
   return maxsum;
 }
 
