Index: ChangeLog
===================================================================
--- ChangeLog	(revision 149073)
+++ ChangeLog	(working copy)
@@ -7,6 +7,8 @@
 
 2006-09-12  Stefan Seefeld  <stefan@codesourcery.com>
 
+	* src/vsip/impl/fns_scalar.hpp: Properly forward-declare hypotf as
+	'extern "C"'. Fall back on ::hypot(double, double) if necessary.
 	* src/vsip_csl/GNUmakefile.inc.in: Re-enable matlab code on Windows.
 	* configure.ac: Remove AC_CONFIG_MACRO_DIR and increment version string.
 	* src/vsip/support.hpp: Disable ICC loop vectorization for Windows.
Index: src/vsip/impl/fns_scalar.hpp
===================================================================
--- src/vsip/impl/fns_scalar.hpp	(revision 149073)
+++ src/vsip/impl/fns_scalar.hpp	(working copy)
@@ -24,7 +24,7 @@
 
 #if !HAVE_DECL_HYPOTF
 #if HAVE_HYPOTF
-extern float hypotf(float, float);
+extern "C" float hypotf(float, float);
 # endif
 #endif
 
@@ -199,7 +199,14 @@
 hypot(double t1, double t2) VSIP_NOTHROW { return ::hypot(t1, t2);}
 
 inline float
-hypot(float t1, float t2) VSIP_NOTHROW { return ::hypotf(t1, t2);}
+hypot(float t1, float t2) VSIP_NOTHROW 
+{
+#if HAVE_HYPOTF
+  return ::hypotf(t1, t2);
+#else
+  return ::hypot((double)t1, (double)t2);
+#endif
+}
 
 template <typename T1, typename T2>
 inline bool
