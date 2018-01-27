Index: ChangeLog
===================================================================
--- ChangeLog	(revision 191110)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2007-01-09  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip_csl/img/impl/pwarp_gen.hpp: Guard against accesses outside
+	  of source array.
+
+2007-01-09  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/diag/eval.hpp: Include necessary headers.
 	* src/vsip/opt/expr/serial_dispatch_fwd.hpp: Likewise.
 	* src/vsip_csl/img/impl/sfilt_gen.hpp: Use persistent_ext_data to
Index: src/vsip_csl/img/impl/pwarp_gen.hpp
===================================================================
--- src/vsip_csl/img/impl/pwarp_gen.hpp	(revision 191006)
+++ src/vsip_csl/img/impl/pwarp_gen.hpp	(working copy)
@@ -208,6 +208,8 @@
   stride_type in_stride_0            = in_ext.stride(0);
   stride_type out_stride_0_remainder = out_ext.stride(0) - cols;
 
+  stride_type max_offset = in.size(0)*in_stride_0 + in.size(1);
+
   for (index_type r=0; r<rows; ++r)
   {
     CoeffT y = static_cast<CoeffT>(r);
@@ -230,11 +232,17 @@
 	CoeffT v_beta = v - v0;
 	
 	T* p = p_in + v0*in_stride_0 + u0;
+
+	stride_type limit = max_offset - v0*in_stride_0 + u0;
+
+	stride_type off_10 = std::min<stride_type>(in_stride_0,     limit);
+	stride_type off_01 = std::min<stride_type>(              1, limit);
+	stride_type off_11 = std::min<stride_type>(in_stride_0 + 1, limit);
 	
-	T z00 = *p;                     // in.get(v0,   u0);
-	T z10 = *(p + in_stride_0);     // in.get(v0+1, u0+0);
-	T z01 = *(p               + 1); // in.get(v0+0, u0+1);
-	T z11 = *(p + in_stride_0 + 1); // in.get(v0+1, u0+1);
+	T z00 = *p;            // in.get(v0,   u0);
+	T z10 = *(p + off_10); // in.get(v0+1, u0+0);
+	T z01 = *(p + off_01); // in.get(v0+0, u0+1);
+	T z11 = *(p + off_11); // in.get(v0+1, u0+1);
 	
 	AccumT z0 = (AccumT)((1 - u_beta) * z00 + u_beta * z01);
 	AccumT z1 = (AccumT)((1 - u_beta) * z10 + u_beta * z11);
