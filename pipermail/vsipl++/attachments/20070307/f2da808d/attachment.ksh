Index: ChangeLog
===================================================================
--- ChangeLog	(revision 165069)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2007-03-05  Don McCoy  <don@codesourcery.com>
+
+	* src/vsip/opt/cbe/ppu/fft.cpp: Added support for non-unit
+	  stride between rows or columns.
+	
 2007-03-06  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* configure.ac: New --enable-numa option.
Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 165069)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -306,7 +306,20 @@
 			    length_type, length_type)
   {
   }
-
+  virtual void query_layout(Rt_layout<2> &rtl_inout)
+  {
+    // must have unit stride, but does not have to be dense
+    rtl_inout.pack = stride_unit;
+    rtl_inout.order = tuple<0, 1, 2>();
+    rtl_inout.complex = cmplx_inter_fmt;
+  }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    // must have unit stride, but does not have to be dense
+    rtl_in.pack = rtl_out.pack = stride_unit;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    rtl_in.complex = rtl_out.complex = cmplx_inter_fmt;
+  }
 private:
   rtype scale_;
   length_type fft_length_;
