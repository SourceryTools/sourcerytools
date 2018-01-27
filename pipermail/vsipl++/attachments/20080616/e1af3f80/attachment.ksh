Index: ChangeLog
===================================================================
--- ChangeLog	(revision 211943)
+++ ChangeLog	(working copy)
@@ -1,3 +1,7 @@
+2008-06-16  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/ipp/fir.hpp (apply): Fix strides to 'stride_type'.
+
 2008-06-12  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* cvsip/window_api.hpp: Implement window functions.
Index: src/vsip/opt/ipp/fir.hpp
===================================================================
--- src/vsip/opt/ipp/fir.hpp	(revision 211569)
+++ src/vsip/opt/ipp/fir.hpp	(working copy)
@@ -131,8 +131,8 @@
   }
   virtual Fir_impl *clone() { return new Fir_impl(*this);}
 
-  length_type apply(T *in, length_type in_stride, length_type in_length,
-                    T *out, length_type out_stride, length_type out_length)
+  length_type apply(T *in, stride_type in_stride, length_type in_length,
+                    T *out, stride_type out_stride, length_type out_length)
   {
     length_type const d = this->decimation();
     length_type const m = this->filter_order() - 1;
