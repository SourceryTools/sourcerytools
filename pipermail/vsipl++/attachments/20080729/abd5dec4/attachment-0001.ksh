Index: src/vsip/opt/cbe/cml/conv.hpp
===================================================================
--- src/vsip/opt/cbe/cml/conv.hpp	(revision 215849)
+++ src/vsip/opt/cbe/cml/conv.hpp	(working copy)
@@ -60,7 +60,7 @@
   float*       out,   length_type o_size, stride_type s_out,
   length_type decimation)
 {
-  cml_conv1d_min_f(coeff,1,in,s_in,out,s_out,decimation,o_size,c_size);
+  cml_conv1d_min_f(coeff,1,in,s_in,out,s_out,decimation,c_size,o_size);
 }
 
 inline
@@ -74,7 +74,7 @@
   float const* fcoeff = reinterpret_cast<float const*>(coeff);
   float const* fin    = reinterpret_cast<float const*>(in);
   float*       fout   = reinterpret_cast<float*>(out);
-  cml_cconv1d_min_f(fcoeff,1,fin,s_in,fout,s_out,decimation,o_size,c_size);
+  cml_cconv1d_min_f(fcoeff,1,fin,s_in,fout,s_out,decimation,c_size,o_size);
 }
 
 inline
@@ -89,7 +89,7 @@
     coeff.first,coeff.second,1,
     in.first,in.second,s_in,
     out.first,out.second,s_out,
-    decimation,o_size,c_size
+    decimation,c_size,o_size
     );
 }
 
@@ -99,10 +99,10 @@
   float const* coeff, stride_type s_coeff,
   float const* in,    stride_type s_in,
   float*       out,   stride_type s_out,
+  length_type nkr,
+  length_type nkc,
   length_type nr,
   length_type nc,
-  length_type nkr,
-  length_type nkc,
   length_type decimation
   )
 {
@@ -111,8 +111,8 @@
     in,s_in,
     out,s_out,
     decimation, decimation,
-    nr, nc,
-    nkr, nkc);
+    nkr, nkc,
+    nr, nc);
 }
 
 inline
@@ -121,10 +121,10 @@
   std::complex<float> const* coeff, stride_type s_coeff,
   std::complex<float> const* in,    stride_type s_in,
   std::complex<float>*       out,   stride_type s_out,
+  length_type nkr,
+  length_type nkc,
   length_type nr,
   length_type nc,
-  length_type nkr,
-  length_type nkc,
   length_type decimation
   )
 {
@@ -136,8 +136,8 @@
     fin,s_in,
     fout,s_out,
     decimation, decimation,
-    nr, nc,
-    nkr, nkc);
+    nkr, nkc,
+    nr, nc);
 }
 
 inline
@@ -146,10 +146,10 @@
   std::pair<float*,float*> coeff, stride_type s_coeff,
   std::pair<float*,float*> in,    stride_type s_in,
   std::pair<float*,float*> out,   stride_type s_out,
+  length_type nkr,
+  length_type nkc,
   length_type nr,
   length_type nc,
-  length_type nkr,
-  length_type nkc,
   length_type decimation
   )
 {
@@ -158,8 +158,8 @@
     in.first,   in.second,    s_in,
     out.first,  out.second,   s_out,
     decimation, decimation,
-    nr, nc,
-    nkr, nkc);
+    nkr, nkc,
+    nr, nc);
 }
 
 // Wrappers for "same" support.
@@ -209,8 +209,8 @@
       coeff,   s_coeff,
       in_adj,  s_in,
       out_adj, s_out,
+      nkr, nkc,
       n1_r-n0_r, n1_c-n0_c,
-      nkr, nkc,
       decimation
     );
 
@@ -269,8 +269,8 @@
       coeff,   s_coeff,
       std::pair<T*,T*>(in_adj_re,in_adj_im),  s_in,
       std::pair<T*,T*>(out_adj_re,out_adj_im), s_out,
+      nkr, nkc,
       n1_r-n0_r, n1_c-n0_c,
-      nkr, nkc,
       decimation
     );
   }
@@ -463,7 +463,7 @@
   else if (Supp == support_same)
   {
     VSIP_IMPL_PROFILE(pm_non_opt_calls_++);
-    conv_same(pcoeff_, M, in_ext.data(), N, s_in, out_ext.data(), P, s_out, decimation_);
+    vsip::impl::conv_same(pcoeff_, M, in_ext.data(), N, s_in, out_ext.data(), P, s_out, decimation_);
   }
   else // (Supp == support_min)
   {
@@ -529,8 +529,8 @@
 	  pcoeff_,        coeff_row_stride,
 	  in_ext.data(),     in_row_stride,
 	  out_ext.data(),   out_row_stride,
+	  Mr, Mc,
 	  Pr, Pc,
-	  Mr, Mc,
 	  decimation_
 	);
 	return;
