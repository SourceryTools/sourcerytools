Index: ChangeLog
===================================================================
--- ChangeLog	(revision 170780)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2007-05-09  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/simd/simd.hpp: Fix faux-complex trait to work
+	  around GHS internal error.
+
+2007-05-09  Jules Bergmann  <jules@codesourcery.com>
+
 	* configure.ac: Fix typo in check for std::isfinite.
 	* examples/mercury/mcoe-setup.sh: Enable exceptions (rather than
 	  probe) when exceptions="y".
Index: src/vsip/opt/simd/simd.hpp
===================================================================
--- src/vsip/opt/simd/simd.hpp	(revision 170216)
+++ src/vsip/opt/simd/simd.hpp	(working copy)
@@ -872,31 +872,51 @@
   {
     base_simd_type v0 = Simd_traits<T>::load(((T const*)addr)+0);
     base_simd_type v1 = Simd_traits<T>::load(((T const*)addr)+vec_size);
+#if __ghs__
+    simd_type t;
+    t.r = Simd_traits<T>::real_from_interleaved(v0, v1);
+    t.i = Simd_traits<T>::imag_from_interleaved(v0, v1);
+#else
+    // 070509: This causes an internal error with GHS:
+    //         "type-change_constant: integer to bad type"
     simd_type t = 
       {
 	Simd_traits<T>::real_from_interleaved(v0, v1),
 	Simd_traits<T>::imag_from_interleaved(v0, v1)
       };
+#endif
     return t;
   }
 
   static simd_type load_scalar(value_type value)
   {
+#if __ghs__
+    simd_type t;
+    t.r = Simd_traits<T>::load_scalar(value.real());
+    t.i = Simd_traits<T>::load_scalar(value.imag());
+#else
     simd_type t =
       {
 	Simd_traits<T>::load_scalar(value.real()),
 	Simd_traits<T>::load_scalar(value.imag())
       };
+#endif
     return t;
   }
 
   static simd_type load_scalar_all(value_type value)
   {
+#if __ghs__
+    simd_type t;
+    t.r = Simd_traits<T>::load_scalar_all(value.real());
+    t.i = Simd_traits<T>::load_scalar_all(value.imag());
+#else
     simd_type t =
       {
 	Simd_traits<T>::load_scalar_all(value.real()),
 	Simd_traits<T>::load_scalar_all(value.imag())
       };
+#endif
     return t;
   }
 
@@ -913,21 +933,33 @@
 
   static simd_type add(simd_type const& v1, simd_type const& v2)
   {
+#if __ghs__
+    simd_type t;
+    t.r = Simd_traits<T>::add(v1.r, v2.r);
+    t.i = Simd_traits<T>::add(v1.i, v2.i);
+#else
     simd_type t =
       {
 	Simd_traits<T>::add(v1.r, v2.r),
 	Simd_traits<T>::add(v1.i, v2.i)
       };
+#endif
     return t;
   }
 
   static simd_type sub(simd_type const& v1, simd_type const& v2)
   {
+#if __ghs__
+    simd_type t;
+    t.r = Simd_traits<T>::sub(v1.r, v2.r);
+    t.i = Simd_traits<T>::sub(v1.i, v2.i);
+#else
     simd_type t =
       {
 	Simd_traits<T>::sub(v1.r, v2.r),
 	Simd_traits<T>::sub(v1.i, v2.i)
       };
+#endif
     return t;
   }
 
@@ -940,7 +972,13 @@
     base_simd_type ir = Simd_traits<T>::mul(v1.i, v2.r);
     base_simd_type i  = Simd_traits<T>::add(ri, ir);
 
+#if __ghs__
+    simd_type t;
+    t.r = r;
+    t.i = i;
+#else
     simd_type t = { r, i };
+#endif
     return t;
   }
 
@@ -955,7 +993,13 @@
     base_simd_type r = Simd_traits<T>::div(Simd_traits<T>::add(rr,ii),n);
     base_simd_type i = Simd_traits<T>::div(Simd_traits<T>::sub(ri, ir),n);
 
+#if __ghs__
+    simd_type t;
+    t.r = r;
+    t.i = i;
+#else
     simd_type t = { r, i };
+#endif
     return t;
   }
 
