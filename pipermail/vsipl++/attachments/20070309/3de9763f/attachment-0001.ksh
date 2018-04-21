Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 165340)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -53,8 +53,6 @@
   fft(std::complex<T> const* in, std::complex<T>* out, 
     length_type length, T scale, int exponent)
   {
-    // Note: the twiddle factors require only 1/4 the memory of the input and 
-    // output arrays.
     Fft_params fftp;
     fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
     fftp.elements = length;
@@ -92,19 +90,23 @@
     length_type rows, length_type cols, 
     T scale, int exponent, int axis)
   {
-    // Note: the twiddle factors require only 1/4 the memory of the input and 
-    // output arrays.
     Fft_params fftp;
     fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
-    fftp.elements = cols;
     fftp.scale = scale;
     fftp.ea_twiddle_factors = 
       reinterpret_cast<unsigned long long>(twiddle_factors_.get());
-    length_type num_ffts = rows;
-    length_type in_stride = in_r_stride;
-    length_type out_stride = out_r_stride;
-    if (axis == 0)
+    length_type num_ffts;
+    length_type in_stride;
+    length_type out_stride;
+    if (axis != 0)
     {
+      num_ffts = rows;
+      in_stride = in_r_stride;
+      out_stride = out_r_stride;
+      fftp.elements = cols;
+    }
+    else
+    {
       num_ffts = cols;
       in_stride = in_c_stride;
       out_stride = out_c_stride;
@@ -128,19 +130,19 @@
        true);
 
     length_type spes         = mgr->num_spes();
-    length_type rows_per_spe = rows / spes;
+    length_type ffts_per_spe = num_ffts / spes;
 
     for (length_type i = 0; i < spes && i < num_ffts; ++i)
     {
       // If rows don't divide evenly, give the first SPEs one extra.
-      length_type spe_rows = (i < rows % spes) ? rows_per_spe + 1 : rows_per_spe;
+      length_type spe_ffts = (i < num_ffts % spes) ? ffts_per_spe + 1 : ffts_per_spe;
 
-      Workblock block = task.create_multi_block(spe_rows);
+      Workblock block = task.create_multi_block(spe_ffts);
       block.set_parameters(fftp);
       task.enqueue(block);
 
-      fftp.ea_input_buffer  += sizeof(ctype) * spe_rows * in_stride;
-      fftp.ea_output_buffer += sizeof(ctype) * spe_rows * out_stride;
+      fftp.ea_input_buffer  += sizeof(ctype) * spe_ffts * in_stride;
+      fftp.ea_output_buffer += sizeof(ctype) * spe_ffts * out_stride;
     }
     task.sync();
   }
@@ -306,7 +308,26 @@
 			    length_type, length_type)
   {
   }
-
+  virtual void query_layout(Rt_layout<2> &rtl_inout)
+  {
+    // must have unit stride, but does not have to be dense
+    if (A != 0)
+      rtl_inout.order = tuple<0, 1, 2>();
+    else
+      rtl_inout.order = tuple<1, 0, 2>();
+    rtl_inout.pack = stride_unit;
+    rtl_inout.complex = cmplx_inter_fmt;
+  }
+  virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
+  {
+    // must have unit stride, but does not have to be dense
+    if (A != 0)
+      rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    else
+      rtl_in.order = rtl_out.order = tuple<1, 0, 2>();
+    rtl_in.pack = rtl_out.pack = stride_unit;
+    rtl_in.complex = rtl_out.complex = cmplx_inter_fmt;
+  }
 private:
   rtype scale_;
   length_type fft_length_;
