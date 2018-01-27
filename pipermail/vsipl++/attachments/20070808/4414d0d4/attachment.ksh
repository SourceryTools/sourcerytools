Index: ChangeLog
===================================================================
--- ChangeLog	(revision 177867)
+++ ChangeLog	(working copy)
@@ -1,3 +1,40 @@
+2007-08-08  Jules Bergmann  <jules@codesourcery.com>
+
+	* scripts/char.pl: Capture -diag output for each run.
+	* scripts/fmt-profile.pl: Fix typo in options description.
+	* scripts/char.db: Add vmin set.
+	* scripts/datasheet.pl: Add additional cases.
+	* src/vsip/core/signal/conv.hpp: Bump copyright.
+	* src/vsip/opt/sal/bindings.hpp: Add 2D convolution bindings.
+	* src/vsip/opt/sal/conv.hpp: Use 2D SAL conv bindings for 2D V++ conv.
+	* src/vsip/opt/sal/eval_elementwise.hpp: Fix assert to handle scalar
+	  blocks with 0 size.
+	* src/vsip/opt/fftw3/fft_impl.cpp: Force row alignment for FFTM.
+	* src/vsip/opt/simd/simd.hpp: Add min, max, mag functions.
+	* src/vsip/opt/simd/vma_ip_csc.cpp: New file, SIMD optimized
+	  R += real-a * cmplx-B
+	* src/vsip/opt/simd/vma_ip_csc.hpp: New file, likewise.
+	* src/vsip/opt/simd/vaxpy.cpp: New file, SIMD optimized
+	  R += cmplx-a * real-B + cmplx-C
+	* src/vsip/opt/simd/vaxpy.hpp: New file, likewise.
+	* src/vsip/opt/simd/eval_generic.hpp: Fix typo in rt_valid aligment
+	  check.
+	* src/vsip/opt/simd/expr_iterator.hpp: Recognize simd traits that
+	  don't support div.  Add min, max, and mag support.  Fix unaligned
+	  loader.
+	* src/vsip/opt/diag/eval.hpp: Add support for 'A = scalar' exprs.
+	* src/vsip/GNUmakefile.inc.in: Build vaxpy files.
+	* tests/coverage_common.hpp: Add VERBOSE output for TEST_UNARY.
+	* tests/regressions/simd_alignment.cpp: Add coverage for exprs
+	  with different aligment (that require unaligned SIMD load).
+	* tests/coverage_unary.cpp: Split neg tests into ...
+	* tests/coverage_unary_neg.cpp: .. here, new file.
+	* tests/conv-2d.cpp: Add more output on failure.
+	* benchmarks/vdiv.cpp: Add diag output.
+	* benchmarks/conv2d.cpp: Remove debug output.
+	* benchmarks/sal/vthresh.cpp: Add coverage for vthrx.
+	* examples/mercury/mcoe-setup.sh: Suppress GHC warning 175.
+	
 2007-07-31  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/fft/factory.hpp (create): Throw exception when
Index: scripts/char.pl
===================================================================
--- scripts/char.pl	(revision 177867)
+++ scripts/char.pl	(working copy)
@@ -177,7 +177,12 @@
    
    my $cmd = "$runcmd $full_pgm -$x $opt $runopt > $outfile";
    print "CMD $cmd\n";
-   system($cmd) if !$dry;
+   if (!$dry) {
+      system($cmd);
+      system("echo '---' >> $outfile");
+      $cmd = "$runcmd $full_pgm -$x $opt $runopt -diag >> $outfile";
+      system($cmd);
+      }
    }
 
 
Index: scripts/fmt-profile.pl
===================================================================
--- scripts/fmt-profile.pl	(revision 173072)
+++ scripts/fmt-profile.pl	(working copy)
@@ -12,7 +12,7 @@
 #									#
 # Options:								#
 #   -sec	-- convert ticks into seconds				#
-#   -sec	-- sum nested operations for events with 0 ops		#
+#   -sum	-- sum nested operations for events with 0 ops		#
 #   -extra <event>							#
 #		-- create pseudo event for unaccounted-for time		#
 #		   in nested events under <event>			#
Index: scripts/char.db
===================================================================
--- scripts/char.db	(revision 177867)
+++ scripts/char.db	(working copy)
@@ -33,7 +33,7 @@
 # Core characterization
 #########################################################################
 
-macro: core vmul vma fft-est fft-measure vendor-fft maxval sumval copy fastconv conv vthresh vgt_ite vendor-vthresh
+macro: core vmul vma vmin fft-est fft-measure vendor-fft maxval sumval copy fastconv conv vthresh vgt_ite vendor-vthresh
 
 
 
@@ -125,13 +125,17 @@
   pgm: vthresh
   cases: 1 2 3 11
 
+set: vmin
+  pgm: vmin
+  cases: 1
+
 set: vgt_ite
   pgm: vgt_ite
   cases: 1 2 5
 
 set: sal-vthresh
   pgm: sal/vthresh
-  cases: 1 11
+  cases: 1 2 11
   req:   sal
 
 set: sal-lvgt
Index: scripts/datasheet.pl
===================================================================
--- scripts/datasheet.pl	(revision 177867)
+++ scripts/datasheet.pl	(working copy)
@@ -96,7 +96,7 @@
    $x_name = "MB/s"    if ($metric eq 'r_mb_s');
    $x_name = "Mpt/s"   if ($metric eq 'mpts_s');
 
-   printf OUT "  %5s  %7s  %7s  %7s\n", "Size", "usec", "usec/pt", $x_name;
+   printf OUT "  %5s  %7s  %7s  %7s\n", "Size", "us/call", "us/pt", $x_name;
    # printf OUT "  %5s  %7s  %7s  %7s\n", "", "(usec)", "(usec)", "";
 
    foreach my $size (@sizes) {
@@ -118,7 +118,7 @@
       $x = $r_mb_s  if ($metric eq 'r_mb_s');
       $x = $mpts_s  if ($metric eq 'mpts_s');
 
-      printf OUT "  %5d  %7.2f  %7.2f  %7.2f\n", $size, $s, $us_pt, $x;
+      printf OUT "  %5d  %7.1f  %7.5f  %7.2f\n", $size, $s, $us_pt, $x;
       }
    print OUT "\n";
    }
@@ -152,11 +152,20 @@
 read_dat($db, "fft-17-1.dat");
 
 read_dat($db, "ipp-fft-1-1.dat");
+
 read_dat($db, "fftw3-fft-11-1.dat");
 read_dat($db, "fftw3-fft-12-1.dat");
 read_dat($db, "fftw3-fft-51-1.dat");
 read_dat($db, "fftw3-fft-52-1.dat");
 
+read_dat($db, "sal-fft-1-1.dat");
+read_dat($db, "sal-fft-2-1.dat");
+read_dat($db, "sal-fft-5-1.dat");
+read_dat($db, "sal-fft-6-1.dat");
+read_dat($db, "sal-fft-11-1.dat");
+read_dat($db, "sal-fft-12-1.dat");
+read_dat($db, "sal-fft-15-1.dat");
+read_dat($db, "sal-fft-16-1.dat");
 
 read_dat($db, "vma-1-1.dat");
 read_dat($db, "vma-2-1.dat");
@@ -164,6 +173,9 @@
 read_dat($db, "vma-11-1.dat");
 read_dat($db, "vma-12-1.dat");
 read_dat($db, "vma-13-1.dat");
+
+read_dat($db, "vmin-1-1.dat");
+
 read_dat($db, "vmul-1-1.dat");
 read_dat($db, "vmul-2-1.dat");
 
@@ -171,6 +183,12 @@
 read_dat($db, "vthresh-2-1.dat");
 read_dat($db, "vthresh-3-1.dat");
 read_dat($db, "vthresh-11-1.dat");
+
+read_dat($db, "sal-vthresh-1-1.dat");
+read_dat($db, "sal-vthresh-2-1.dat");
+read_dat($db, "sal-lvgt-1-1.dat");
+read_dat($db, "sal-lvgt-2-1.dat");
+
 read_dat($db, "vgt_ite-1-1.dat");
 read_dat($db, "vgt_ite-2-1.dat");
 read_dat($db, "vgt_ite-5-1.dat");
@@ -214,6 +232,15 @@
 
 report_func($db, "ipp-fft-1-1", "fft (vendor-IPP): Out-of-place CC Fwd FFT (inter complex)", optional => 1);
 
+report_func($db, "sal-fft-1-1", "fft (vendor-SAL): Out-of-place CC Fwd FFT (split complex)", optional => 1);
+report_func($db, "sal-fft-2-1", "fft (vendor-SAL): In-place CC Fwd FFT (split complex)", optional => 1);
+report_func($db, "sal-fft-5-1", "fft (vendor-SAL): Out-of-place CC Inv FFT (split complex)", optional => 1);
+report_func($db, "sal-fft-6-1", "fft (vendor-SAL): In-place CC Inv FFT (split complex)", optional => 1);
+report_func($db, "sal-fft-11-1", "fft (vendor-SAL): Out-of-place CC Fwd FFT (inter complex)", optional => 1);
+report_func($db, "sal-fft-12-1", "fft (vendor-SAL): In-place CC Fwd FFT (inter complex)", optional => 1);
+report_func($db, "sal-fft-15-1", "fft (vendor-SAL): Out-of-place CC Inv FFT (inter complex)", optional => 1);
+report_func($db, "sal-fft-16-1", "fft (vendor-SAL): In-place CC Inv FFT (inter complex)", optional => 1);
+
 # Maxval
 header();
 
@@ -232,6 +259,11 @@
 report_func($db, "vma-12-1", "vma: vector fused multiply-add (Z = a * B + C) (complex)");
 report_func($db, "vma-13-1", "vma: vector fused multiply-add (Z = a * B + c) (complex) (aka caxpy)");
 
+# VMIN
+header();
+
+report_func($db, "vmin-1-1", "vmin: vector minima (Z = min(A, B)) (float)");
+
 # VMUL
 header();
 
@@ -246,8 +278,18 @@
 report_func($db, "vthresh-3-1", "vthresh: vector threshold (Z = ite(A >= b, A, c)) (float)");
 report_func($db, "vthresh-11-1", "vthresh: vector threshold (Z = ite(A > B, 1, 0)) (float) lvgt");
 
+
+
 report_func($db, "vgt_ite-1-1", "vthresh: vector threshold (Z = ite(A > B, A, 0)) (float) lvgt/vmul");
 report_func($db, "vgt_ite-2-1", "vthresh: vector threshold (Z = ite(A > B, A, 1)) (float)");
 report_func($db, "vgt_ite-5-1", "vthresh: vector threshold (Z = ite(A > B, A, 0)) (float) multi-expr");
 
+header();
+
+report_func($db, "sal-vthresh-1-1", "vthresh (vendor-SAL): vthreshx (Z = ite(A >= b, A, 0)) (float)");
+report_func($db, "sal-vthresh-2-1", "vthresh (vendor-SAL): vthrx (Z = ite(A >= b, A, b)) (float)");
+
+report_func($db, "sal-lvgt-1-1", "vthresh (vendor-SAL): lvgtx (Z = ite(A > B, 1, 0)) (float)");
+report_func($db, "sal-lvgt-2-1", "vthresh (vendor-SAL): lvgtx/vmul (Z = ite(A > B, A, 0)) (float)");
+
 close(OUT);
Index: src/vsip/core/signal/conv.hpp
===================================================================
--- src/vsip/core/signal/conv.hpp	(revision 177858)
+++ src/vsip/core/signal/conv.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005 by CodeSourcery, LLC.  All rights reserved. */
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved. */
 
 /** @file    vsip/core/signal/conv.hpp
     @author  Jules Bergmann
Index: src/vsip/opt/sal/bindings.hpp
===================================================================
--- src/vsip/opt/sal/bindings.hpp	(revision 176624)
+++ src/vsip/opt/sal/bindings.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -22,7 +22,6 @@
   Included Files
 ***********************************************************************/
 
-#include <iostream>
 #include <complex>
 #include <sal.h>
 
@@ -223,22 +222,22 @@
 
 // convolution functions
 
-#define VSIP_IMPL_SAL_CONV( T, SAL_T, SALFCN, STRIDE_X ) \
-inline void                            \
-conv( T *filter, int f_as, int M,      \
-      T *input,  int i_as, int N,      \
-      T *output, int o_as )            \
-{                                      \
-  SALFCN(                              \
-    (SAL_T *) &input[0],      /* input vector, length of A >= N+p-1 */ \
-    i_as * STRIDE_X,          /* address stride for A               */ \
-    (SAL_T *) &filter[M - 1], /* input filter                       */ \
-    -1 * f_as * STRIDE_X,     /* address stride for B               */ \
-    (SAL_T *) &output[0],     /* output vector                      */ \
-    o_as * STRIDE_X,          /* address stride for C               */ \
-    N,                        /* real output count                  */ \
-    M,                        /* filter length (vector B)           */ \
-    0                         /* ESAL flag                          */ \
+#define VSIP_IMPL_SAL_CONV( T, SAL_T, SALFCN, STRIDE_X )		\
+inline void								\
+conv( T *filter, int f_as, int M,					\
+      T *input,  int i_as, int N,					\
+      T *output, int o_as )						\
+{									\
+  SALFCN(								\
+    (SAL_T *) &input[0],      /* input vector, length of A >= N+p-1 */	\
+    i_as * STRIDE_X,          /* address stride for A               */	\
+    (SAL_T *) &filter[M - 1], /* input filter                       */	\
+    -1 * f_as * STRIDE_X,     /* address stride for B               */	\
+    (SAL_T *) &output[0],     /* output vector                      */	\
+    o_as * STRIDE_X,          /* address stride for C               */	\
+    N,                        /* real output count                  */	\
+    M,                        /* filter length (vector B)           */	\
+    0                         /* ESAL flag                          */	\
   );                                   \
 }
 
@@ -267,6 +266,71 @@
 
 VSIP_IMPL_SAL_CONV_SPLIT( float, COMPLEX_SPLIT, zconvx, 1 );
 
+
+
+#define VSIP_IMPL_SAL_CONV_2D(T, SAL_T, SALFCN, STRIDE_X)		\
+inline void								\
+conv2d(									\
+  T*  filter,								\
+  int filter_rows, int filter_cols,					\
+  int filter_row_stride,						\
+  T*  input,								\
+  int input_rows, int input_cols,					\
+  int input_row_stride,							\
+  T*  output,								\
+  int output_rows, int output_cols,					\
+  int output_row_stride,						\
+  int row_dec,								\
+  int col_dec)								\
+{									\
+  assert(filter_row_stride == filter_cols);				\
+  assert(input_rows == (output_rows-1)*row_dec + filter_rows);		\
+  assert(input_cols == (output_cols-1)*col_dec + filter_cols);		\
+  SALFCN(								\
+    (SAL_T*)&input[0],        /* input matrix                       */	\
+    input_row_stride,         /* total columns in input matrix      */	\
+    (SAL_T *)&filter[0],      /* kernel matrix                      */	\
+    (SAL_T *)&output[0],      /* output matrix                      */	\
+    output_row_stride,        /* total columns in output matrix     */	\
+    row_dec,                  /* row decimation factor              */	\
+    col_dec,                  /* column decimation factor           */	\
+    filter_cols,              /* number of filter columns           */	\
+    filter_rows,              /* number of filter rows              */	\
+    output_cols,              /* number of output columns           */	\
+    output_rows,              /* number of output rows              */	\
+    0,                        /* reserved                           */	\
+    0                         /* ESAL flag                          */	\
+    );									\
+}
+
+VSIP_IMPL_SAL_CONV_2D(float, float, conv2dx, 1);
+
+#undef VSIP_IMPL_SAL_CONV_2D
+
+
+
+#define VSIP_IMPL_SAL_CONV_2D_3X3(T, SAL_T, SALFCN, STRIDE_X)		\
+inline void								\
+conv2d_3x3(								\
+  T*  filter,								\
+  T*  input,								\
+  T*  output,								\
+  int rows, int cols)							\
+{									\
+  SALFCN(								\
+    (SAL_T*)&input[0],        /* input matrix                       */	\
+    cols,                     /* number of in/out columns           */	\
+    rows,                     /* number of in/out rows              */	\
+    (SAL_T *)&filter[0],      /* 3x3 filter matrix                  */	\
+    (SAL_T *)&output[0],      /* output matrix                      */	\
+    0                         /* ESAL flag                          */	\
+    );									\
+}
+
+VSIP_IMPL_SAL_CONV_2D_3X3(float, float, f3x3x, 1);
+
+#undef VSIP_IMPL_SAL_CONV_2D_3X3
+
 } // namespace vsip::impl::sal
 } // namespace vsip::impl
 } // namespace vsip
Index: src/vsip/opt/sal/conv.hpp
===================================================================
--- src/vsip/opt/sal/conv.hpp	(revision 177867)
+++ src/vsip/opt/sal/conv.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -54,7 +54,13 @@
   static bool const value = true;
 };
 
+template <>
+struct Is_conv_impl_avail<Mercury_sal_tag, 2, float>
+{
+  static bool const value = true;
+};
 
+
 // These help enforce limits on the length of the kernel
 // when using SAL, which differ for complex values
 template <typename T>
@@ -145,10 +151,14 @@
 	   Matrix<T, Block1>)
     VSIP_NOTHROW;
 
-  typedef vsip::impl::Layout<1, row1_type, vsip::impl::Stride_unit,
-			     complex_type> layout_type;
-  typedef Vector<T> coeff_view_type;
-  typedef impl::Ext_data<typename coeff_view_type::block_type, layout_type> c_ext_type;
+  typedef vsip::impl::Layout<dim,
+			     typename Row_major<dim>::type,
+			     vsip::impl::Stride_unit,
+			     complex_type>
+		layout_type;
+  typedef typename View_of_dim<dim, T, Dense<dim, T> >::type coeff_view_type;
+  typedef impl::Ext_data<typename coeff_view_type::block_type, layout_type>
+		c_ext_type;
 
   // Member data.
 private:
@@ -156,6 +166,10 @@
   c_ext_type      coeff_ext_;
   ptr_type        pcoeff_;
 
+  coeff_view_type sal_coeff_;
+  c_ext_type      sal_coeff_ext_;
+  ptr_type        sal_pcoeff_;
+
   Domain<dim>     kernel_size_;
   Domain<dim>     input_size_;
   Domain<dim>     output_size_;
@@ -174,6 +188,31 @@
   Definitions
 ***********************************************************************/
 
+template <typename T,
+	  typename Block1,
+	  typename Block2>
+inline void
+mirror(
+  const_Vector<T, Block1> src,
+  Vector<T, Block2>       dst)
+{
+  dst(Domain<1>(dst.size()-1, -1, dst.size())) = src;
+}
+
+template <typename T,
+	  typename Block1,
+	  typename Block2>
+inline void
+mirror(
+  const_Matrix<T, Block1> src,
+  Matrix<T, Block2>       dst)
+{
+  dst(Domain<2>(Domain<1>(dst.size(0)-1, -1, dst.size(0)),
+		Domain<1>(dst.size(1)-1, -1, dst.size(1)))) = src;
+}
+
+
+
 /// Construct a convolution object.
 
 template <template <typename, typename> class ConstViewT,
@@ -192,6 +231,9 @@
   : coeff_      (conv_kernel<coeff_view_type>(Symm, filter_coeffs)),
     coeff_ext_  (coeff_.block(), impl::SYNC_IN),
     pcoeff_     (coeff_ext_.data()),
+    sal_coeff_     (conv_kernel<coeff_view_type>(Symm, filter_coeffs)),
+    sal_coeff_ext_ (sal_coeff_.block(), impl::SYNC_IN),
+    sal_pcoeff_    (sal_coeff_ext_.data()),
     kernel_size_(impl::view_domain(coeff_)),
     input_size_ (input_size),
     output_size_(impl::conv_output_size(Supp, kernel_size_, input_size,
@@ -199,6 +241,7 @@
     decimation_ (decimation),
     pm_non_opt_calls_ (0)
 {
+  mirror(coeff_, sal_coeff_);
   in_buffer_  = storage_type::allocate(input_size_.size());
   if (storage_type::is_null(in_buffer_))
     VSIP_IMPL_THROW(std::bad_alloc());
@@ -382,8 +425,124 @@
   Matrix<T, Block1>       out)
 VSIP_NOTHROW
 {
-  VSIP_IMPL_THROW(vsip::impl::unimplemented(
-		    "Convolution_impl<... Mercury_sal_tag> does not support Matrix"));
+  length_type const Mr = this->coeff_.size(0);
+  length_type const Mc = this->coeff_.size(1);
+
+  length_type const Nr = this->input_size_[0].size();
+  length_type const Nc = this->input_size_[1].size();
+
+  length_type const Pr = this->output_size_[0].size();
+  length_type const Pc = this->output_size_[1].size();
+
+  assert(Pr == out.size(0) && Pc == out.size(1));
+
+  typedef vsip::impl::Ext_data<Block0> in_ext_type;
+  typedef vsip::impl::Ext_data<Block1> out_ext_type;
+
+  in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
+  out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
+
+  VSIP_IMPL_PROFILE(pm_in_ext_cost_  += in_ext.cost());
+  VSIP_IMPL_PROFILE(pm_out_ext_cost_ += out_ext.cost());
+
+  T* pin    = in_ext.data();
+  T* pout   = out_ext.data();
+
+  stride_type coeff_row_stride = coeff_ext_.stride(0);
+  stride_type coeff_col_stride = coeff_ext_.stride(1);
+  stride_type in_row_stride    = in_ext.stride(0);
+  stride_type in_col_stride    = in_ext.stride(1);
+  stride_type out_row_stride   = out_ext.stride(0);
+  stride_type out_col_stride   = out_ext.stride(1);
+
+  if (Supp == support_full)
+  {
+#if 0
+    // Full support not implemented yet.
+    if (decimation_ == 1 && coeff_col_stride == 1 &&
+	in_ext.stride(1) == 1 && out_ext.stride(1) == 1)
+    {
+      impl::sal::conv2d_full(
+	pcoeff_, Mr, Mc, coeff_row_stride,
+	pin, Nr, Nc, in_row_stride,
+	pout, out_row_stride);
+    }
+    else
+#endif
+    {
+      conv_full<T>(pcoeff_, Mr, Mc, coeff_row_stride, coeff_col_stride,
+		   pin, Nr, Nc, in_row_stride, in_col_stride,
+		   pout, Pr, Pc, out_row_stride, out_col_stride,
+		   decimation_);
+    }
+  }
+  else if (Supp == support_same)
+  {
+    if (decimation_ == 1 && coeff_col_stride == 1 &&
+	in_ext.stride(1) == 1 && out_ext.stride(1) == 1)
+    {
+      if (Mr == 3 && Mc == 3 &&
+	  coeff_row_stride == (stride_type)Mc &&
+	  in_row_stride    == (stride_type)Nc &&
+	  out_row_stride   == (stride_type)Nc)
+      {
+	impl::sal::conv2d_3x3(sal_pcoeff_, pin, pout, Nr, Nc);
+      }
+      else
+      {
+	index_type n0_r = (Mr - 1) - (Mr/2);
+	index_type n0_c = (Mc - 1) - (Mc/2);
+	index_type n1_r = Nr - (Mr/2);
+	index_type n1_c = Nc - (Mc/2);
+
+	T* pout_adj = pout + (n0_r)*out_row_stride
+			   + (n0_c)*out_col_stride;
+
+	if (n1_r > n0_r && n1_c > n0_c)
+	  impl::sal::conv2d(
+	    sal_pcoeff_, Mr, Mc, coeff_row_stride,
+	    pin,         Nr, Nc, in_row_stride,
+	    pout_adj,    Pr - (Mr-1), Pc - (Mc-1), out_row_stride,
+	    decimation_, decimation_);
+      }
+
+      // SAL conv2d (conv2dx) is min-support, while SAL conv2d_3x3
+      // (f3x3x) leaves a strip of 0 around the edge of the output.
+      //
+      // Implement same-support by filling out the edges.
+
+      conv_same_edge<T>(pcoeff_, Mr, Mc, coeff_row_stride, coeff_col_stride,
+			pin, Nr, Nc, in_row_stride, in_col_stride,
+			pout, Pr, Pc, out_row_stride, out_col_stride,
+			decimation_);
+    }
+    else
+    {
+      conv_same<T>(pcoeff_, Mr, Mc, coeff_row_stride, coeff_col_stride,
+		   pin, Nr, Nc, in_row_stride, in_col_stride,
+		   pout, Pr, Pc, out_row_stride, out_col_stride,
+		   decimation_);
+    }
+  }
+  else // (Supp == support_min)
+  {
+    if (decimation_ == 1 && coeff_col_stride == 1 &&
+	in_ext.stride(1) == 1 && out_ext.stride(1) == 1)
+    {
+      impl::sal::conv2d(
+	sal_pcoeff_, Mr, Mc, coeff_row_stride,
+	pin,         Nr, Nc, in_row_stride,
+	pout,        Pr, Pc, out_row_stride,
+	decimation_, decimation_);
+    }
+    else
+    {
+      conv_min<T>(pcoeff_, Mr, Mc, coeff_row_stride, coeff_col_stride,
+		  pin, Nr, Nc, in_row_stride, in_col_stride,
+		  pout, Pr, Pc, out_row_stride, out_col_stride,
+		  decimation_);
+    }
+  }
 }
 
 } // namespace vsip::impl
Index: src/vsip/opt/sal/eval_elementwise.hpp
===================================================================
--- src/vsip/opt/sal/eval_elementwise.hpp	(revision 176624)
+++ src/vsip/opt/sal/eval_elementwise.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -273,8 +273,8 @@
     sal::Ext_wrapper<LBlock, lblock_lp> ext_l(src.left(),  SYNC_IN);	\
     sal::Ext_wrapper<RBlock, rblock_lp> ext_r(src.right(), SYNC_IN);	\
 									\
-    assert(dst.size() <= src.left().size());				\
-    assert(dst.size() <= src.right().size());				\
+    assert(dst.size() <= src.left().size()  || src.left().size() == 0);	\
+    assert(dst.size() <= src.right().size() || src.right().size() == 0); \
 									\
     VSIP_IMPL_COVER_BLK("SAL_VV", SrcBlock);				\
     FUN(								\
Index: src/vsip/opt/fftw3/fft_impl.cpp
===================================================================
--- src/vsip/opt/fftw3/fft_impl.cpp	(revision 177858)
+++ src/vsip/opt/fftw3/fft_impl.cpp	(working copy)
@@ -1051,12 +1051,13 @@
   virtual void query_layout(Rt_layout<2> &rtl_inout)
   {
     // By default use unit_stride,
-    rtl_inout.pack = stride_unit;
+    rtl_inout.pack = stride_unit_align;
     // an ordering that gives unit strides on the axis perpendicular to A,
     if (A == 0) rtl_inout.order = tuple<1, 0, 2>();
     else rtl_inout.order = tuple<0, 1, 2>();
     // make default based on library
     rtl_inout.complex = Create_plan<fftw3_complex_type>::format;
+    rtl_inout.align = VSIP_IMPL_ALLOC_ALIGNMENT;
   }
 
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
Index: src/vsip/opt/simd/simd.hpp
===================================================================
--- src/vsip/opt/simd/simd.hpp	(revision 176624)
+++ src/vsip/opt/simd/simd.hpp	(working copy)
@@ -90,6 +90,8 @@
 //  - add             - add two SIMD vectors together
 //  - sub             - subtract two SIMD vectors
 //  - mul             - multiply two SIMD vectors together
+//  - fma
+//  - mag	      - magnitude (aka absolute value) of a SIMD vector
 //
 // Logic Operations:
 //  - band            - bitwise-and two SIMD vectors
@@ -129,6 +131,7 @@
   static int const  vec_size   = 1;
   static bool const is_accel   = false;
   static bool const has_perm   = false;
+  static bool const has_div    = true;
   static int  const alignment  = 1;
   static unsigned int const scalar_pos = 0;
 
@@ -162,10 +165,19 @@
   static simd_type div(simd_type const& v1, simd_type const& v2)
   { return v1 / v2; }
 
+  static simd_type mag(simd_type const& v1)
+  { return mag(v1); }
+
   static simd_type fma(simd_type const& v1, simd_type const& v2,
 		       simd_type const& v3)
   { return v1 * v2 + v3; }
 
+  static simd_type min(simd_type const& v1, simd_type const& v2)
+  { return (v1 < v2) ? v1 : v2; }
+
+  static simd_type max(simd_type const& v1, simd_type const& v2)
+  { return (v1 > v2) ? v1 : v2; }
+
   // These functions return ints and operate on ints
   static simd_itype band(simd_itype const& v1, simd_itype const& v2)
   { return v1 & v2; }
@@ -240,6 +252,7 @@
   static int  const vec_size   = 16;
   static bool const is_accel   = true;
   static bool const has_perm   = true;
+  static bool const has_div    = false;
   static int  const alignment  = 16;
 
   static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
@@ -265,7 +278,7 @@
     return vec_perm(x0, x1, sh);
   }
   
-  static perm_simd_type shift_for_addr(value_type* addr)
+  static perm_simd_type shift_for_addr(value_type const* addr)
   { return vec_lvsl(0, addr); }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
@@ -335,9 +348,10 @@
   typedef __vector VSIP_IMPL_AV_BOOL short bool_simd_type;
   typedef __vector signed char        pack_simd_type;
    
-  static int const  vec_size = 8;
-  static bool const is_accel = true;
-  static bool const has_perm = true;
+  static int const  vec_size  = 8;
+  static bool const is_accel  = true;
+  static bool const has_perm  = true;
+  static bool const has_div   = false;
   static int  const alignment = 16;
 
   static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
@@ -361,7 +375,7 @@
     return vec_perm(x0, x1, sh);
   }
 
-  static perm_simd_type shift_for_addr(value_type* addr)
+  static perm_simd_type shift_for_addr(value_type const* addr)
   { return vec_lvsl(0, addr); }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
@@ -434,9 +448,10 @@
   typedef __vector VSIP_IMPL_AV_BOOL int bool_simd_type;
   typedef __vector signed short          pack_simd_type;
    
-  static int const  vec_size = 4;
-  static bool const is_accel = true;
-  static bool const has_perm = true;
+  static int const  vec_size  = 4;
+  static bool const is_accel  = true;
+  static bool const has_perm  = true;
+  static bool const has_div   = false;
   static int  const alignment = 16;
 
   static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
@@ -460,7 +475,7 @@
     return vec_perm(x0, x1, sh);
   }
 
-  static perm_simd_type shift_for_addr(value_type* addr)
+  static perm_simd_type shift_for_addr(value_type const* addr)
   { return vec_lvsl(0, addr); }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
@@ -532,9 +547,10 @@
   typedef __vector unsigned char         perm_simd_type;
   typedef __vector VSIP_IMPL_AV_BOOL int bool_simd_type;
    
-  static int  const vec_size = 4;
-  static bool const is_accel = true;
-  static bool const has_perm = true;
+  static int  const vec_size  = 4;
+  static bool const is_accel  = true;
+  static bool const has_perm  = true;
+  static bool const has_div   = false;
   static int  const alignment = 16;
 
   static unsigned int  const scalar_pos = VSIP_IMPL_SCALAR_POS(vec_size);
@@ -558,7 +574,7 @@
     return vec_perm(x0, x1, sh);
   }
 
-  static perm_simd_type shift_for_addr(value_type* addr)
+  static perm_simd_type shift_for_addr(value_type const* addr)
   { return vec_lvsl(0, addr); }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
@@ -602,6 +618,15 @@
 		       simd_type const& v3)
   { return vec_madd(v1, v2, v3); }
 
+  static simd_type mag(simd_type const& v1)
+  { return vec_abs(v1); }
+
+  static simd_type min(simd_type const& v1, simd_type const& v2)
+  { return vec_min(v1, v2); }
+
+  static simd_type max(simd_type const& v1, simd_type const& v2)
+  { return vec_max(v1, v2); }
+
   static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
   { return vec_cmpgt(v1, v2); }
 
@@ -614,7 +639,7 @@
   // 070505: ppu-g++ 4.1.1 confused by return type for vec_cmple
   //         (but regular g++ 4.1.1 OK).  Use vec_cmpgt instead.
   static bool_simd_type le(simd_type const& v1, simd_type const& v2)
-  { return vec_cmpgt(v2, v1); }
+  { return vec_cmpge(v2, v1); }
 
   static simd_type real_from_interleaved(simd_type const& v1,
 					 simd_type const& v2)
@@ -667,6 +692,7 @@
   static int const  vec_size   = 16;
   static bool const is_accel   = true;
   static bool const has_perm   = false;
+  static bool const has_div    = false;
   static int  const alignment  = 16;
   static unsigned int  const scalar_pos = 0;
 
@@ -728,6 +754,7 @@
   static int const  vec_size   = 8;
   static bool const is_accel   = true;
   static bool const has_perm   = false;
+  static bool const has_div    = false;
   static int  const alignment  = 16;
   static unsigned int  const scalar_pos = 0;
 
@@ -830,6 +857,7 @@
   static int const  vec_size   = 4;
   static bool const is_accel   = true;
   static bool const has_perm   = false;
+  static bool const has_div    = false;
   static int  const alignment  = 16;
   static unsigned int  const scalar_pos = 0;
 
@@ -918,6 +946,7 @@
   static int const  vec_size   = 4;
   static bool const is_accel   = true;
   static bool const has_perm   = false;
+  static bool const has_div    = true;
   static int  const alignment  = 16;
   static unsigned int  const scalar_pos = 0;
 
@@ -968,6 +997,18 @@
 		       simd_type const& v3)
   { return add(mul(v1,v2),v3); }
 
+  static simd_type mag(simd_type const& v1)
+  {
+    simd_type mask = (simd_type)Simd_traits<int>::load_scalar_all(0x7fffffff);
+    return _mm_and_ps(mask, v1);
+  }
+
+  static simd_type min(simd_type const& v1, simd_type const& v2)
+  { return _mm_min_ps(v1, v2); }
+
+  static simd_type max(simd_type const& v1, simd_type const& v2)
+  { return _mm_max_ps(v1, v2); }
+
   static simd_type gt(simd_type const& v1, simd_type const& v2)
   { return _mm_cmpgt_ps(v1, v2); }
 
@@ -1017,6 +1058,7 @@
   static int const  vec_size   = 2;
   static bool const is_accel   = true;
   static bool const has_perm   = false;
+  static bool const has_div    = true;
   static int  const alignment  = 16;
   static unsigned int  const scalar_pos = 0;
 
@@ -1067,6 +1109,19 @@
 		       simd_type const& v3)
   { return add(mul(v1,v2),v3); }
 
+  static simd_type mag(simd_type const& v1)
+  {
+    simd_type mask = (simd_type)_mm_set_epi32(0x7ffffff, 0xfffffff,
+					      0x7ffffff, 0xfffffff);
+    return _mm_and_pd((simd_type)mask, v1);
+  }
+
+  static simd_type min(simd_type const& v1, simd_type const& v2)
+  { return _mm_min_pd(v1, v2); }
+
+  static simd_type max(simd_type const& v1, simd_type const& v2)
+  { return _mm_max_pd(v1, v2); }
+
   static simd_type gt(simd_type const& v1, simd_type const& v2)
   { return _mm_cmpgt_pd(v1, v2); }
 
@@ -1125,7 +1180,8 @@
    
   static int const  vec_size  = Simd_traits<T>::vec_size;
   static bool const is_accel  = Simd_traits<T>::is_accel;
-  static bool const has_perm  = Simd_traits<T>::has_perm;
+  static bool const has_perm  = false;
+  static bool const has_div   = Simd_traits<T>::has_div;
   static int  const alignment = Simd_traits<T>::alignment;
 
   static intptr_t alignment_of(value_type const* addr)
@@ -1332,6 +1388,8 @@
 struct Alg_vbxor;
 struct Alg_vbnot;
 struct Alg_threshold;
+struct Alg_vma_cSC;
+struct Alg_vma_ip_cSC;
 
 template <typename T,
 	  bool     IsSplit,
Index: src/vsip/opt/simd/vma_ip_csc.cpp
===================================================================
--- src/vsip/opt/simd/vma_ip_csc.cpp	(revision 0)
+++ src/vsip/opt/simd/vma_ip_csc.cpp	(revision 0)
@@ -0,0 +1,53 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/simd/vma_ip_csc.cpp
+    @author  Jules Bergmann
+    @date    2006-11-17
+    @brief   VSIPL++ Library: SIMD element-wise vector multiplication.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/simd/vma_ip_csc.hpp>
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
+vma_ip_cSC(
+  std::complex<T> const& a,
+  T const*               B,
+  std::complex<T>*       R,
+  int                    n)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<std::complex<T>, false, Alg_vma_ip_cSC>::value;
+  Simd_vma_ip_cSC<std::complex<T>, Is_vectorized>::exec(a, B, R, n);
+}
+
+template void vma_ip_cSC(std::complex<float> const&, float const*,
+			 std::complex<float>*, int);
+template void vma_ip_cSC(std::complex<double> const&, double const*,
+			 std::complex<double>*, int);
+
+#endif
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
Index: src/vsip/opt/simd/vaxpy.cpp
===================================================================
--- src/vsip/opt/simd/vaxpy.cpp	(revision 0)
+++ src/vsip/opt/simd/vaxpy.cpp	(revision 0)
@@ -0,0 +1,54 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/simd/vma.cpp
+    @author  Jules Bergmann
+    @date    2006-11-17
+    @brief   VSIPL++ Library: SIMD element-wise vector multiplication.
+
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/opt/simd/vaxpy.hpp>
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
+vma_cSC(
+  std::complex<T> const& a,
+  T const*               B,
+  std::complex<T> const* C,
+  std::complex<T>*       R,
+  int                    n)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<std::complex<T>, false, Alg_vma_cSC>::value;
+  Simd_vma_cSC<std::complex<T>, Is_vectorized>::exec(a, B, C, R, n);
+}
+
+template void vma_cSC(std::complex<float> const&, float const*,
+		      std::complex<float> const*, std::complex<float>*, int);
+template void vma_cSC(std::complex<double> const&, double const*,
+		   std::complex<double> const*, std::complex<double>*, int);
+
+#endif
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
Index: src/vsip/opt/simd/vma_ip_csc.hpp
===================================================================
--- src/vsip/opt/simd/vma_ip_csc.hpp	(revision 0)
+++ src/vsip/opt/simd/vma_ip_csc.hpp	(revision 0)
@@ -0,0 +1,272 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/simd/vma_ip_csc.hpp
+    @author  Jules Bergmann
+    @date    2006-11-17
+    @brief   VSIPL++ Library: SIMD element-wise AXPY.
+
+*/
+
+#ifndef VSIP_OPT_SIMD_VMA_IP_CSC_HPP
+#define VSIP_OPT_SIMD_VMA_IP_CSC_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <complex>
+
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip/core/metaprogramming.hpp>
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
+// Define value_types for which vma_ip is optimized.
+//  - float
+//  - double
+
+template <typename T,
+	  bool     IsSplit>
+struct Is_algorithm_supported<T, IsSplit, Alg_vma_ip_cSC>
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
+// Class for vma_ip - vector element-wise multiplication.
+
+template <typename T,
+	  bool     Is_vectorized>
+struct Simd_vma_ip_cSC;
+
+
+
+// Generic, non-vectorized implementation of vector element-wise multiply.
+// C += c*S
+// R += A*B 
+
+template <typename T>
+struct Simd_vma_ip_cSC<std::complex<T>, false>
+{
+  static void exec(
+    std::complex<T> const& a,
+    T const*               B,
+    std::complex<T>*       R,
+    int                    n)
+  {
+    while (n)
+    {
+      *R += a * *B;
+      R++; B++;
+      n--;
+    }
+  }
+};
+
+
+
+// Vectorized implementation of vector element-wise multiply for scalars
+// (float, double, etc).
+
+template <typename T>
+struct Simd_vma_ip_cSC<std::complex<T>, true>
+{
+  static void exec(
+    std::complex<T> const& a,
+    T const*               B,
+    std::complex<T>*       R,
+    int                    n)
+  {
+    typedef Simd_traits<T> simd;
+
+    typedef typename simd::simd_type simd_type;
+
+    // handle mis-aligned vectors
+    if (simd::alignment_of((T*)R) != simd::alignment_of(B))
+    {
+      // PROFILE
+      while (n)
+      {
+	*R += a * *B;
+	R++; B++;
+	n--;
+      }
+      return;
+    }
+
+    // clean up initial unaligned values
+    while (simd::alignment_of((T*)R) != 0)
+    {
+      *R += a * *B;
+      R++; B++;
+      n--;
+    }
+  
+    if (n == 0) return;
+
+    simd::enter();
+
+
+#if 0
+    simd_type reg_Ar = simd::load_scalar_all(a.real());
+    simd_type reg_Ai = simd::load_scalar_all(a.imag());
+
+    while (n >= 1*simd::vec_size)
+    {
+      simd_type reg_B = simd::load((T*)B);
+
+      simd_type reg_C0 = simd::load((T*)R);
+      simd_type reg_C1 = simd::load((T*)R + simd::vec_size);
+
+      simd_type reg_ABr = simd::mul(reg_Ar, reg_B);
+      simd_type reg_ABi = simd::mul(reg_Ai, reg_B);
+
+      simd_type reg_Cr = simd::real_from_interleaved(reg_C0, reg_C1);
+      simd_type reg_Ci = simd::imag_from_interleaved(reg_C0, reg_C1);
+
+      simd_type reg_Rr = simd::add(reg_Cr, reg_ABr);
+      simd_type reg_Ri = simd::add(reg_Ci, reg_ABi);
+
+      simd_type reg_R1 = simd::interleaved_lo_from_split(reg_Rr, reg_Ri);
+      simd_type reg_R2 = simd::interleaved_hi_from_split(reg_Rr, reg_Ri);
+      
+      simd::store((T*)R,                  reg_R1);
+      simd::store((T*)R + simd::vec_size, reg_R2);
+      
+      B += simd::vec_size; C += simd::vec_size; R += simd::vec_size;
+      n -= 1*simd::vec_size;
+    }
+#elif 0
+    simd_type reg_Ar = simd::load_scalar_all(a.real());
+    simd_type reg_Ai = simd::load_scalar_all(a.imag());
+    simd_type reg_A  = simd::interleaved_lo_from_split(reg_Ar, reg_Ai);
+
+    while (n >= 1*simd::vec_size)
+    {
+      simd_type reg_B = simd::load((T*)B);
+
+      simd_type reg_C1 = simd::load((T*)R);
+      simd_type reg_C2 = simd::load((T*)R + simd::vec_size);
+
+      simd_type reg_B1 = simd::interleaved_lo_from_split(reg_B, reg_B);
+      simd_type reg_B2 = simd::interleaved_hi_from_split(reg_B, reg_B);
+
+      simd_type reg_AB1 = simd::mul(reg_A, reg_B1);
+      simd_type reg_AB2 = simd::mul(reg_A, reg_B2);
+
+      simd_type reg_R1 = simd::add(reg_C1, reg_AB1);
+      simd_type reg_R2 = simd::add(reg_C2, reg_AB2);
+
+      simd::store((T*)R,                  reg_R1);
+      simd::store((T*)R + simd::vec_size, reg_R2);
+      
+      B += simd::vec_size; C += simd::vec_size; R += simd::vec_size;
+      n -= 1*simd::vec_size;
+    }
+#else
+    simd_type reg_Ar = simd::load_scalar_all(a.real());
+    simd_type reg_Ai = simd::load_scalar_all(a.imag());
+    simd_type reg_A  = simd::interleaved_lo_from_split(reg_Ar, reg_Ai);
+
+    while (n >= 2*simd::vec_size)
+    {
+      simd_type reg_B01 = simd::load((T*)B);
+      simd_type reg_B23 = simd::load((T*)B + simd::vec_size);
+
+      simd_type reg_C0 = simd::load((T*)R);
+      simd_type reg_C1 = simd::load((T*)R + simd::vec_size);
+      simd_type reg_C2 = simd::load((T*)R + 2*simd::vec_size);
+      simd_type reg_C3 = simd::load((T*)R + 3*simd::vec_size);
+
+      simd_type reg_B0 = simd::interleaved_lo_from_split(reg_B01, reg_B01);
+      simd_type reg_B1 = simd::interleaved_hi_from_split(reg_B01, reg_B01);
+      simd_type reg_B2 = simd::interleaved_hi_from_split(reg_B23, reg_B23);
+      simd_type reg_B3 = simd::interleaved_hi_from_split(reg_B23, reg_B23);
+
+      simd_type reg_AB0 = simd::mul(reg_A, reg_B0);
+      simd_type reg_AB1 = simd::mul(reg_A, reg_B1);
+      simd_type reg_AB2 = simd::mul(reg_A, reg_B2);
+      simd_type reg_AB3 = simd::mul(reg_A, reg_B3);
+
+      simd_type reg_R0 = simd::add(reg_C0, reg_AB0);
+      simd_type reg_R1 = simd::add(reg_C1, reg_AB1);
+      simd_type reg_R2 = simd::add(reg_C2, reg_AB2);
+      simd_type reg_R3 = simd::add(reg_C3, reg_AB3);
+
+      simd::store((T*)R,                    reg_R0);
+      simd::store((T*)R + 1*simd::vec_size, reg_R1);
+      simd::store((T*)R + 2*simd::vec_size, reg_R2);
+      simd::store((T*)R + 3*simd::vec_size, reg_R3);
+      
+      B += 2*simd::vec_size; R += 2*simd::vec_size;
+      n -= 2*simd::vec_size;
+    }
+#endif
+    
+    simd::exit();
+
+    while (n)
+    {
+      *R += a * *B;
+      R++; B++;
+      n--;
+    }
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
+vma_ip_cSC(
+  std::complex<T> const& a,
+  T const*               B,
+  std::complex<T>*       R,
+  int                    n)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<std::complex<T>, false, Alg_vma_ip_cSC>::value;
+  Simd_vma_ip_cSC<std::complex<T>, Is_vectorized>::exec(a, B, R, n);
+}
+
+#else
+
+template <typename T>
+void
+vma_ip_cSC(
+  std::complex<T> const& a,
+  T const*               B,
+  std::complex<T>*       R,
+  int                    n);
+
+#endif // VSIP_IMPL_INLINE_LIBSIMD
+
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_SIMD_VMA_IP_CSC_HPP
Index: src/vsip/opt/simd/vaxpy.hpp
===================================================================
--- src/vsip/opt/simd/vaxpy.hpp	(revision 0)
+++ src/vsip/opt/simd/vaxpy.hpp	(revision 0)
@@ -0,0 +1,277 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip/opt/simd/vma_cSC.hpp
+    @author  Jules Bergmann
+    @date    2006-11-17
+    @brief   VSIPL++ Library: SIMD element-wise AXPY.
+
+*/
+
+#ifndef VSIP_OPT_SIMD_VMA_CSC_HPP
+#define VSIP_OPT_SIMD_VMA_CSC_HPP
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <complex>
+
+#include <vsip/opt/simd/simd.hpp>
+#include <vsip/core/metaprogramming.hpp>
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
+// Define value_types for which vma is optimized.
+//  - float
+//  - double
+
+template <typename T,
+	  bool     IsSplit>
+struct Is_algorithm_supported<T, IsSplit, Alg_vma_cSC>
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
+// Class for vma - vector element-wise multiplication.
+
+template <typename T,
+	  bool     Is_vectorized>
+struct Simd_vma_cSC;
+
+
+
+// Generic, non-vectorized implementation of vector element-wise multiply.
+// C = c*S + C
+// R = A*B + C
+
+template <typename T>
+struct Simd_vma_cSC<std::complex<T>, false>
+{
+  static void exec(
+    std::complex<T> const& a,
+    T const*               B,
+    std::complex<T> const* C,
+    std::complex<T>*       R,
+    int                    n)
+  {
+    while (n)
+    {
+      *R = a * *B + *C;
+      R++; B++; C++;
+      n--;
+    }
+  }
+};
+
+
+
+// Vectorized implementation of vector element-wise multiply for scalars
+// (float, double, etc).
+
+template <typename T>
+struct Simd_vma_cSC<std::complex<T>, true>
+{
+  static void exec(
+    std::complex<T> const& a,
+    T const*               B,
+    std::complex<T> const* C,
+    std::complex<T>*       R,
+    int                    n)
+  {
+    typedef Simd_traits<T> simd;
+
+    typedef typename simd::simd_type simd_type;
+
+    // handle mis-aligned vectors
+    if (simd::alignment_of((T*)R) != simd::alignment_of(B) ||
+	simd::alignment_of((T*)R) != simd::alignment_of((T*)C))
+    {
+      // PROFILE
+      while (n)
+      {
+	*R = a * *B + *C;
+	R++; B++; C++;
+	n--;
+      }
+      return;
+    }
+
+    // clean up initial unaligned values
+    while (simd::alignment_of((T*)R) != 0)
+    {
+      *R = a * *B + *C;
+      R++; B++; C++;
+      n--;
+    }
+  
+    if (n == 0) return;
+
+    simd::enter();
+
+
+#if 0
+    simd_type reg_Ar = simd::load_scalar_all(a.real());
+    simd_type reg_Ai = simd::load_scalar_all(a.imag());
+
+    while (n >= 1*simd::vec_size)
+    {
+      simd_type reg_B = simd::load((T*)B);
+
+      simd_type reg_C0 = simd::load((T*)C);
+      simd_type reg_C1 = simd::load((T*)C + simd::vec_size);
+
+      simd_type reg_ABr = simd::mul(reg_Ar, reg_B);
+      simd_type reg_ABi = simd::mul(reg_Ai, reg_B);
+
+      simd_type reg_Cr = simd::real_from_interleaved(reg_C0, reg_C1);
+      simd_type reg_Ci = simd::imag_from_interleaved(reg_C0, reg_C1);
+
+      simd_type reg_Rr = simd::add(reg_Cr, reg_ABr);
+      simd_type reg_Ri = simd::add(reg_Ci, reg_ABi);
+
+      simd_type reg_R1 = simd::interleaved_lo_from_split(reg_Rr, reg_Ri);
+      simd_type reg_R2 = simd::interleaved_hi_from_split(reg_Rr, reg_Ri);
+      
+      simd::store((T*)R,                  reg_R1);
+      simd::store((T*)R + simd::vec_size, reg_R2);
+      
+      B += simd::vec_size; C += simd::vec_size; R += simd::vec_size;
+      n -= 1*simd::vec_size;
+    }
+#elif 0
+    simd_type reg_Ar = simd::load_scalar_all(a.real());
+    simd_type reg_Ai = simd::load_scalar_all(a.imag());
+    simd_type reg_A  = simd::interleaved_lo_from_split(reg_Ar, reg_Ai);
+
+    while (n >= 1*simd::vec_size)
+    {
+      simd_type reg_B = simd::load((T*)B);
+
+      simd_type reg_C1 = simd::load((T*)C);
+      simd_type reg_C2 = simd::load((T*)C + simd::vec_size);
+
+      simd_type reg_B1 = simd::interleaved_lo_from_split(reg_B, reg_B);
+      simd_type reg_B2 = simd::interleaved_hi_from_split(reg_B, reg_B);
+
+      simd_type reg_AB1 = simd::mul(reg_A, reg_B1);
+      simd_type reg_AB2 = simd::mul(reg_A, reg_B2);
+
+      simd_type reg_R1 = simd::add(reg_C1, reg_AB1);
+      simd_type reg_R2 = simd::add(reg_C2, reg_AB2);
+
+      simd::store((T*)R,                  reg_R1);
+      simd::store((T*)R + simd::vec_size, reg_R2);
+      
+      B += simd::vec_size; C += simd::vec_size; R += simd::vec_size;
+      n -= 1*simd::vec_size;
+    }
+#else
+    simd_type reg_Ar = simd::load_scalar_all(a.real());
+    simd_type reg_Ai = simd::load_scalar_all(a.imag());
+    simd_type reg_A  = simd::interleaved_lo_from_split(reg_Ar, reg_Ai);
+
+    while (n >= 2*simd::vec_size)
+    {
+      simd_type reg_B01 = simd::load((T*)B);
+      simd_type reg_B23 = simd::load((T*)B + simd::vec_size);
+
+      simd_type reg_C0 = simd::load((T*)C);
+      simd_type reg_C1 = simd::load((T*)C + simd::vec_size);
+      simd_type reg_C2 = simd::load((T*)C + 2*simd::vec_size);
+      simd_type reg_C3 = simd::load((T*)C + 3*simd::vec_size);
+
+      simd_type reg_B0 = simd::interleaved_lo_from_split(reg_B01, reg_B01);
+      simd_type reg_B1 = simd::interleaved_hi_from_split(reg_B01, reg_B01);
+      simd_type reg_B2 = simd::interleaved_hi_from_split(reg_B23, reg_B23);
+      simd_type reg_B3 = simd::interleaved_hi_from_split(reg_B23, reg_B23);
+
+      simd_type reg_AB0 = simd::mul(reg_A, reg_B0);
+      simd_type reg_AB1 = simd::mul(reg_A, reg_B1);
+      simd_type reg_AB2 = simd::mul(reg_A, reg_B2);
+      simd_type reg_AB3 = simd::mul(reg_A, reg_B3);
+
+      simd_type reg_R0 = simd::add(reg_C0, reg_AB0);
+      simd_type reg_R1 = simd::add(reg_C1, reg_AB1);
+      simd_type reg_R2 = simd::add(reg_C2, reg_AB2);
+      simd_type reg_R3 = simd::add(reg_C3, reg_AB3);
+
+      simd::store((T*)R,                    reg_R0);
+      simd::store((T*)R + 1*simd::vec_size, reg_R1);
+      simd::store((T*)R + 2*simd::vec_size, reg_R2);
+      simd::store((T*)R + 3*simd::vec_size, reg_R3);
+      
+      B += 2*simd::vec_size; C += 2*simd::vec_size; R += 2*simd::vec_size;
+      n -= 2*simd::vec_size;
+    }
+#endif
+    
+    simd::exit();
+
+    while (n)
+    {
+      *R = a * *B + *C;
+      R++; B++; C++;
+      n--;
+    }
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
+vma_cSC(
+  std::complex<T> const& a,
+  T const*               B,
+  std::complex<T> const* C,
+  std::complex<T>*       R,
+  int                    n)
+{
+  static bool const Is_vectorized =
+    Is_algorithm_supported<std::complex<T>, false, Alg_vma_cSC>::value;
+  Simd_vma_cSC<std::complex<T>, Is_vectorized>::exec(a, B, R, C, n);
+}
+
+#else
+
+template <typename T>
+void
+vma_cSC(
+  std::complex<T> const& a,
+  T const*               B,
+  std::complex<T> const* C,
+  std::complex<T>*       R,
+  int                    n);
+
+#endif // VSIP_IMPL_INLINE_LIBSIMD
+
+
+} // namespace vsip::impl::simd
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_IMPL_SIMD_VMA_CSC_HPP
Index: src/vsip/opt/simd/eval_generic.hpp
===================================================================
--- src/vsip/opt/simd/eval_generic.hpp	(revision 176624)
+++ src/vsip/opt/simd/eval_generic.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -677,7 +677,8 @@
 	   (&(src.first().left()) == &(src.second())) &&
 	   // make sure everyting has same alignment
            (simd::alignment_of(ext_dst.data()) ==
-	    simd::alignment_of(ext_a.data()) ==
+	    simd::alignment_of(ext_a.data())) &&
+           (simd::alignment_of(ext_dst.data()) ==
 	    simd::alignment_of(ext_b.data())));
   }
 
Index: src/vsip/opt/simd/expr_iterator.hpp
===================================================================
--- src/vsip/opt/simd/expr_iterator.hpp	(revision 177792)
+++ src/vsip/opt/simd/expr_iterator.hpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -128,14 +128,59 @@
   typedef T value_type;
   typedef T return_type;
   typedef typename Simd_traits<T>::simd_type simd_type;
-  static bool const is_supported = true;
+  static bool const is_supported = Simd_traits<T>::has_div;
   static simd_type 
   apply(simd_type const &left, simd_type const &right)
   { return Simd_traits<T>::div(left, right);}
 };
 
+
+
+#define VSIP_OPT_DECL_UNARY_OP(FCN, OP)					\
+template <typename T>							\
+struct Unary_operator_map<T, OP>					\
+{									\
+  typedef typename Simd_traits<T>::simd_type simd_type;			\
+  typedef T                             return_type;			\
+  typedef T                             value_type;			\
+  									\
+  static bool const is_supported = true;				\
+  static inline simd_type						\
+  apply(simd_type const &arg)						\
+  {									\
+    return Simd_traits<T>::FCN(arg);					\
+  }									\
+};
+
+#define VSIP_OPT_DECL_UNARY_OP_COMPLEX_BLOCK(OP)			\
+template <typename T>							\
+struct Unary_operator_map<complex<T>, OP>				\
+{									\
+  static bool const is_supported = false;				\
+};
+
+
+
+#define VSIP_OPT_DECL_BINARY_OP(FCN,OP)					\
+template <typename T>							\
+struct Binary_operator_map<T, OP>					\
+{									\
+  typedef typename Simd_traits<T>::simd_type simd_type;			\
+  typedef T                             return_type;			\
+  typedef T                             value_type;			\
+  									\
+  static bool const is_supported = true;				\
+  static inline simd_type						\
+  apply(simd_type const &left, simd_type const &right)			\
+  {									\
+    return Simd_traits<T>::FCN(left, right);				\
+  }									\
+};
+
+
+
 // Binary operators that return different type than type of operands
-#define VSIP_OPT_DECL_BINARY_OP(FCN,O) \
+#define VSIP_OPT_DECL_BINARY_CMP_OP(FCN,O) \
 template <typename T> \
 struct Binary_operator_map<T, O> \
 { \
@@ -153,12 +198,24 @@
   }                                                        \
 };
 
-VSIP_OPT_DECL_BINARY_OP(gt,  gt_functor)
-VSIP_OPT_DECL_BINARY_OP(lt,  lt_functor)
-VSIP_OPT_DECL_BINARY_OP(ge,  ge_functor)
-VSIP_OPT_DECL_BINARY_OP(le,  le_functor)
 
+
+
+VSIP_OPT_DECL_BINARY_CMP_OP(gt,  gt_functor)
+VSIP_OPT_DECL_BINARY_CMP_OP(lt,  lt_functor)
+VSIP_OPT_DECL_BINARY_CMP_OP(ge,  ge_functor)
+VSIP_OPT_DECL_BINARY_CMP_OP(le,  le_functor)
+
+VSIP_OPT_DECL_BINARY_OP(max, max_functor)
+VSIP_OPT_DECL_BINARY_OP(min, min_functor)
+
+VSIP_OPT_DECL_UNARY_OP(mag, mag_functor)
+VSIP_OPT_DECL_UNARY_OP_COMPLEX_BLOCK(mag_functor)
+
+#undef VSIP_OPT_DECL_BINARY_CMP_OP
 #undef VSIP_OPT_DECL_BINARY_OP
+#undef VSIP_OPT_DECL_UNARY_OP
+#undef VSIP_OPT_DECL_UNARY_OP_COMPLEX_BLOCK
 
 // Support for ternary maps
 template <typename T>
@@ -244,6 +301,20 @@
   typedef typename P1::value_type value_type;
 };
 
+
+
+// Helper class for loading SIMD values.
+//
+// Two specializatons are provided:
+//   - has_perm=true is for SIMD instruction sets that have a permute
+//                   instruction (and no unaligned load), such as
+//                   AltiVec.
+//   - has_perm=false is for SIMD instruction sets that do not have
+//                   a permute instruction, but allow unaligned loads,
+//                   such as SSE.
+//
+// The SIMD traits class has a 'has_perm' trait.
+
 template <typename T,
           bool has_perm = Simd_traits<T>::has_perm>
 struct Simd_unaligned_loader;
@@ -258,7 +329,7 @@
 
   Simd_unaligned_loader(value_type const* ptr) : ptr_unaligned_(ptr) 
   {
-    ptr_aligned_    = (simd_type*)((intptr_t)ptr & ~(simd::alignment-1));
+    ptr_aligned_    = (value_type*)((intptr_t)ptr & ~(simd::alignment-1));
 
     x0_  = simd::load((value_type*)ptr_aligned_);
     x1_  = simd::load((value_type*)(ptr_aligned_+simd::vec_size));
@@ -270,8 +341,8 @@
 
   void increment(length_type n = 1)
   {
-    ptr_unaligned_ += n * Simd_traits<value_type>::vec_size;
-    ptr_aligned_   += n;
+    ptr_unaligned_ += n * simd::vec_size;
+    ptr_aligned_   += n * simd::vec_size;
   
     // update x0
     x0_ = (n == 1) ? x1_ : simd::load((value_type*)ptr_aligned_);
@@ -281,7 +352,7 @@
   }
 
   value_type const*            ptr_unaligned_;
-  simd_type const*             ptr_aligned_;
+  value_type const*            ptr_aligned_;
   simd_type                    x0_;
   simd_type                    x1_;
   perm_simd_type               sh_;
Index: src/vsip/opt/diag/eval.hpp
===================================================================
--- src/vsip/opt/diag/eval.hpp	(revision 177858)
+++ src/vsip/opt/diag/eval.hpp	(working copy)
@@ -37,6 +37,7 @@
 
 
 
+
 namespace diag_detail
 {
 
@@ -48,12 +49,18 @@
   static std::string name() { return "unknown"; }
 };
 
-#define VSIP_IMPL_DISPATCH_NAME(TYPE)		\
+#define VSIP_IMPL_DISPATCH_NAME(TYPE)			\
   template <>						\
   struct Dispatch_name<TYPE> {				\
     static std::string name() { return "" # TYPE; }	\
   };
 
+#define VSIP_IMPL_DISPATCH_NAME_AS(TYPE, ASTYPE)	\
+  template <>						\
+  struct Dispatch_name<TYPE> {				\
+    static std::string name() { return "" # ASTYPE; }	\
+  };
+
 VSIP_IMPL_DISPATCH_NAME(Intel_ipp_tag)
 VSIP_IMPL_DISPATCH_NAME(Transpose_tag)
 VSIP_IMPL_DISPATCH_NAME(Mercury_sal_tag)
@@ -63,6 +70,7 @@
 VSIP_IMPL_DISPATCH_NAME(Op_expr_tag)
 VSIP_IMPL_DISPATCH_NAME(Simd_builtin_tag)
 VSIP_IMPL_DISPATCH_NAME(Simd_loop_fusion_tag)
+VSIP_IMPL_DISPATCH_NAME_AS(Simd_unaligned_loop_fusion_tag, Simd_ulf_tag)
 VSIP_IMPL_DISPATCH_NAME(Fc_expr_tag)
 VSIP_IMPL_DISPATCH_NAME(Rbo_expr_tag)
 VSIP_IMPL_DISPATCH_NAME(Loop_fusion_tag)
@@ -77,6 +85,34 @@
 
 
 
+// Represent an unknown type.  Used when a non-view is the RHS of an
+// assignment.
+
+struct Unknown_type {};
+
+
+
+// Helper class to determine the block type of a view.  Handles non-view
+// types (which occur in simple expressions, such as A = 5).
+
+template <typename ViewT>
+struct Block_of
+{
+  typedef Unknown_type type;
+  static type block(ViewT) { return type(); }
+};
+
+template <template <typename, typename> class View,
+	  typename T,
+	  typename BlockT>
+struct Block_of<View<T, BlockT> >
+{
+  typedef BlockT type;
+  static type& block(View<T, BlockT> view) { return view.block(); }
+};
+
+
+
 // Helper class to conditionally call to Serial_expr_evaluator's
 // rt_valid() method, when ct_valid is true.  If ct_valid is false,
 // the call may not be valid.
@@ -254,9 +290,29 @@
   }
 };
 
+// Specialization for Unknown_type RHS.
 
 template <dimension_type Dim,
 	  typename       DstBlock,
+	  typename       TagList,
+	  typename       Tag,
+	  typename       Rest>
+struct Diag_eval_list_helper<Dim, DstBlock, Unknown_type, TagList, Tag, Rest>
+{
+  static void exec(
+    DstBlock&           /*dst*/,
+    Unknown_type const& /*src*/)
+  {
+    std::cout << "Delh: unknown type\n";
+  }
+};
+
+
+
+// Helper class for diag_eval_dispatch.
+
+template <dimension_type Dim,
+	  typename       DstBlock,
 	  typename       SrcBlock,
 	  typename       DaTag>
 struct Diag_eval_dispatch_helper
@@ -466,8 +522,8 @@
   DstViewT dst,
   SrcViewT src)
 {
-  typedef typename DstViewT::block_type dst_block_type;
-  typedef typename SrcViewT::block_type src_block_type;
+  typedef typename diag_detail::Block_of<DstViewT>::type dst_block_type;
+  typedef typename diag_detail::Block_of<SrcViewT>::type src_block_type;
   using vsip::impl::diag_detail::Diag_eval_list_helper;
 
   dimension_type const dim = DstViewT::dim;
@@ -476,7 +532,8 @@
 	    << "  dst expr: " << typeid(dst_block_type).name() << std::endl
 	    << "  src expr: " << typeid(src_block_type).name() << std::endl;
   Diag_eval_list_helper<dim, dst_block_type, src_block_type, TagList>
-    ::exec(dst.block(), src.block());
+    ::exec(diag_detail::Block_of<DstViewT>::block(dst),
+	   diag_detail::Block_of<SrcViewT>::block(src));
 }
 
 
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 177479)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -56,7 +56,9 @@
 			$(srcdir)/src/vsip/opt/simd/vadd.cpp \
 			$(srcdir)/src/vsip/opt/simd/vgt.cpp \
 			$(srcdir)/src/vsip/opt/simd/vlogic.cpp \
-			$(srcdir)/src/vsip/opt/simd/threshold.cpp
+			$(srcdir)/src/vsip/opt/simd/threshold.cpp \
+			$(srcdir)/src/vsip/opt/simd/vaxpy.cpp \
+			$(srcdir)/src/vsip/opt/simd/vma_ip_csc.cpp
 endif # VSIP_IMPL_REF_IMPL
 
 src_vsip_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(src_vsip_cxx_sources))
Index: tests/coverage_common.hpp
===================================================================
--- tests/coverage_common.hpp	(revision 174331)
+++ tests/coverage_common.hpp	(working copy)
@@ -93,6 +93,21 @@
   Unary Operator Tests
 ***********************************************************************/
 
+#if VERBOSE
+#  define DEBUG_UNARY(NAME, OP)						\
+  {									\
+    std::cout << "Test"#NAME << std::endl				\
+	      << "  at pos  : " << i << std::endl			\
+	      << "  expected: " << expected << std::endl		\
+	      << "  got     : " << get_nth(view2, i) << std::endl	\
+      ;									\
+    vsip::impl::diagnose_eval_list_std(view2, OP (view1));		\
+  }
+#else
+#  define DEBUG_UNARY(NAME, OP)						\
+  {}
+#endif
+
 // Test structure for Unary operator
 //
 // Where
@@ -126,6 +141,8 @@
     {									\
       T2 expected = 							\
         CHKOP (Get_value<T1>::at(0, Is_scalar<View1>::value ? 0 : i, RT));\
+      if (!(equal(get_nth(view2, i), expected)))			\
+	DEBUG_UNARY(NAME, OP)						\
       test_assert(equal(get_nth(view2, i), expected));			\
     }									\
   }									\
Index: tests/regressions/simd_alignment.cpp
===================================================================
--- tests/regressions/simd_alignment.cpp	(revision 177792)
+++ tests/regressions/simd_alignment.cpp	(working copy)
@@ -30,8 +30,6 @@
 #include <vsip_csl/test.hpp>
 #include <vsip_csl/output.hpp>
 
-#include "test_common.hpp"
-
 using namespace std;
 using namespace vsip;
 using namespace vsip_csl;
@@ -40,12 +38,19 @@
 
 
 /***********************************************************************
-  Definitions
+  Definitions - Misaligned
 ***********************************************************************/
 
+// Test an unaligned negation, where all views have same relative
+// alignment.
+//
+// Source and destination are not SIMD aligned, but they both have the
+// same relative alignement.  Hence they can be processed with aligned
+// SIMD code after the initial misalignment is cleaned up.
+
 template <typename T>
 void
-do_negate(length_type size, length_type align, length_type cleanup)
+do_negate_same(length_type size, length_type align, length_type cleanup)
 {
   Vector<T> src(size);
   Vector<T> dst(size);
@@ -73,30 +78,85 @@
 
 template <typename T>
 void
-test()
+test_unaligned_same()
 {
-  do_negate<T>(16, 0, 0);
+  do_negate_same<T>(16, 0, 0);
 
-  do_negate<T>(16, 1, 0);
-  do_negate<T>(16, 2, 0);
-  do_negate<T>(16, 3, 0);
+  do_negate_same<T>(16, 1, 0);
+  do_negate_same<T>(16, 2, 0);
+  do_negate_same<T>(16, 3, 0);
 
-  do_negate<T>(16, 1, 1);
-  do_negate<T>(16, 2, 1);
-  do_negate<T>(16, 3, 1);
+  do_negate_same<T>(16, 1, 1);
+  do_negate_same<T>(16, 2, 1);
+  do_negate_same<T>(16, 3, 1);
 
-  do_negate<T>(16, 1, 2);
-  do_negate<T>(16, 2, 2);
-  do_negate<T>(16, 3, 2);
+  do_negate_same<T>(16, 1, 2);
+  do_negate_same<T>(16, 2, 2);
+  do_negate_same<T>(16, 3, 2);
 
-  do_negate<T>(16, 1, 3);
-  do_negate<T>(16, 2, 3);
-  do_negate<T>(16, 3, 3);
+  do_negate_same<T>(16, 1, 3);
+  do_negate_same<T>(16, 2, 3);
+  do_negate_same<T>(16, 3, 3);
 }
 
 
 
 /***********************************************************************
+  Unaligned test
+***********************************************************************/
+
+// Test an "unaligned" negation, with different relative alignment.
+//
+// Source and destination are not SIMD aligned, and they have the
+// different relative alignement.  They must be processed with
+// unaligned SIMD code.
+
+template <typename T>
+void
+do_negate_diff(
+  length_type total_size,
+  length_type process_size,
+  index_type  offset1,
+  index_type  offset2)
+{
+  Vector<T> src(total_size);
+  Vector<T> dst(total_size);
+
+  Domain<1> dom1(offset1, 1, process_size);
+  Domain<1> dom2(offset2, 1, process_size);
+
+  src = ramp(T(0), T(1), total_size);
+
+  dst(dom1) = -src(dom2);
+
+  for (index_type i=0; i<process_size; ++i)
+  {
+#if VERBOSE
+    if (!(dst(dom1)(i) == -src(dom2)(i)))
+    {
+      cout << "src:\n" << src << endl;
+      cout << "dst:\n" << dst << endl;
+    }
+#endif
+    test_assert(dst(dom1)(i) == -src(dom2)(i));
+  }
+}
+
+
+
+template <typename T>
+void
+test_unaligned_diff()
+{
+  do_negate_diff<T>(32, 16, 0, 0);
+  do_negate_diff<T>(32, 16, 1, 1);
+  do_negate_diff<T>(32, 16, 0, 1);
+  do_negate_diff<T>(32, 16, 1, 2); // doesn't dispatch to SIMD UALF
+}
+
+
+
+/***********************************************************************
   Main
 ***********************************************************************/
 
@@ -105,7 +165,8 @@
 {
   vsipl init(argc, argv);
 
-  test<float>();
+  test_unaligned_same<float>();
+  test_unaligned_diff<float>();
 
   return 0;
 }
Index: tests/coverage_unary_neg.cpp
===================================================================
--- tests/coverage_unary_neg.cpp	(revision 0)
+++ tests/coverage_unary_neg.cpp	(revision 0)
@@ -0,0 +1,67 @@
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    tests/coverage_unary_neg.hpp
+    @author  Jules Bergmann
+    @date    2005-09-13
+    @brief   VSIPL++ Library: Coverage tests for neg unary expressions.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#define VERBOSE 1
+
+#include <iostream>
+
+#include <vsip/support.hpp>
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/math.hpp>
+#include <vsip/random.hpp>
+
+#include <vsip_csl/test.hpp>
+#include <vsip_csl/test-storage.hpp>
+#include "coverage_common.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+TEST_UNARY(neg,   -,     -,     anyval)
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
+#if VSIP_IMPL_TEST_LEVEL == 0
+
+  vector_cases2<Test_neg, float>();
+
+#else
+
+  // Unary operators
+  vector_cases2<Test_neg, int>();
+  vector_cases2<Test_neg, float>();
+  vector_cases2<Test_neg, double>();
+  vector_cases2<Test_neg, complex<float> >();
+  vector_cases2<Test_neg, complex<double> >();
+
+#endif // VSIP_IMPL_TEST_LEVEL > 0
+}
Index: tests/conv-2d.cpp
===================================================================
--- tests/conv-2d.cpp	(revision 173072)
+++ tests/conv-2d.cpp	(working copy)
@@ -344,6 +344,8 @@
   if (!good)
   {
 #if VERBOSE
+    cout << "in =\n" << in << endl;
+    cout << "coeff =\n" << coeff << endl;
     cout << "out =\n" << out << endl;
     cout << "ex =\n" << ex << endl;
 #endif
Index: tests/coverage_unary.cpp
===================================================================
--- tests/coverage_unary.cpp	(revision 177533)
+++ tests/coverage_unary.cpp	(working copy)
@@ -36,7 +36,6 @@
 ***********************************************************************/
 
 TEST_UNARY(copy,   ,      ,     anyval)
-TEST_UNARY(neg,   -,     -,     anyval)
 TEST_UNARY(mag,   mag,   mag,   anyval)
 TEST_UNARY(sqrt,  sqrt,  sqrt,  posval)
 TEST_UNARY(rsqrt, rsqrt, rsqrt, posval)
@@ -61,7 +60,6 @@
 
 #if VSIP_IMPL_TEST_LEVEL == 0
 
-  vector_cases2<Test_neg, float>();
   vector_cases2<Test_mag, float>();
   vector_cases2_rt<Test_mag, complex<float>,  float>();
   vector_cases2<Test_sqrt, float>();
@@ -74,12 +72,6 @@
 #else
 
   // Unary operators
-  vector_cases2<Test_neg, int>();
-  vector_cases2<Test_neg, float>();
-  vector_cases2<Test_neg, double>();
-  vector_cases2<Test_neg, complex<float> >();
-  vector_cases2<Test_neg, complex<double> >();
-
   vector_cases2<Test_mag, int>();
   vector_cases2<Test_mag, float>();
   vector_cases2<Test_mag, double>();
Index: benchmarks/vdiv.cpp
===================================================================
--- benchmarks/vdiv.cpp	(revision 173215)
+++ benchmarks/vdiv.cpp	(working copy)
@@ -1,4 +1,4 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2005, 2006, 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
@@ -21,6 +21,8 @@
 #include <vsip/support.hpp>
 #include <vsip/math.hpp>
 #include <vsip/random.hpp>
+#include <vsip/opt/diag/eval.hpp>
+
 #include "benchmarks.hpp"
 
 using namespace vsip;
@@ -71,6 +73,17 @@
     
     time = t1.delta();
   }
+
+  void diag()
+  {
+    length_type const size = 256;
+
+    Vector<T>   A(size, T());
+    Vector<T>   B(size, T());
+    Vector<T>   C(size);
+
+    vsip::impl::diagnose_eval_list_std(C, A / B);
+  }
 };
 
 
Index: benchmarks/conv2d.cpp
===================================================================
--- benchmarks/conv2d.cpp	(revision 177858)
+++ benchmarks/conv2d.cpp	(working copy)
@@ -1,13 +1,13 @@
-/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved.
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
 
    This file is available for license from CodeSourcery, Inc. under the terms
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    benchmarks/conv.cpp
+/** @file    benchmarks/conv2d.cpp
     @author  Jules Bergmann
     @date    2005-07-11
-    @brief   VSIPL++ Library: Benchmark for Convolution.
+    @brief   VSIPL++ Library: Benchmark for 2D Convolution.
 
 */
 
@@ -151,8 +151,6 @@
   length_type M    = atoi(loop.param_["m"].c_str());
   length_type N    = atoi(loop.param_["n"].c_str());
 
-  std::cout << "MN: " << MN << std::endl;
-
   if (MN != 0)
     M = N = MN;
 
Index: benchmarks/sal/vthresh.cpp
===================================================================
--- benchmarks/sal/vthresh.cpp	(revision 173875)
+++ benchmarks/sal/vthresh.cpp	(working copy)
@@ -42,6 +42,9 @@
 template <typename T>
 struct t_vthres_sal;
 
+template <typename T>
+struct t_vthr_sal;
+
 template <>
 struct t_vthres_sal<float> : Benchmark_base
 {
@@ -76,12 +79,12 @@
       T* p_result = ext_result.data();
       
       t1.start();
-      marker_start();
+      marker1_start();
       for (size_t l=0; l<loop; ++l)
       {
 	vthresx(p_A,1, &b, p_result,1, size, 0);
       }
-      marker_stop();
+      marker1_stop();
       t1.stop();
     }
     
@@ -96,6 +99,60 @@
 
 
 
+template <>
+struct t_vthr_sal<float> : Benchmark_base
+{
+  typedef float T;
+
+  char* what() { return "t_vthr_sal"; }
+  int ops_per_point(size_t)  { return 1; }
+
+  int riob_per_point(size_t) { return 1*sizeof(T); }
+  int wiob_per_point(size_t) { return 1*sizeof(T); }
+  int mem_per_point(size_t)  { return 2*sizeof(T); }
+
+  void operator()(size_t size, size_t loop, float& time)
+  {
+    typedef impl::Layout<1, row1_type, Stride_unit_dense, Cmplx_inter_fmt> LP;
+    typedef impl::Fast_block<1, T, LP, Local_map> block_type;
+
+    Vector<T, block_type>   A     (size, T());
+    Vector<T, block_type>   result(size, T());
+    T                       b = T(0.5);
+
+    Rand<T> gen(0, 0);
+    A = gen.randu(size);
+
+    vsip::impl::profile::Timer t1;
+
+    { // Control Ext_data scope.
+      impl::Ext_data<block_type> ext_A     (A.block(),      impl::SYNC_IN);
+      impl::Ext_data<block_type> ext_result(result.block(), impl::SYNC_OUT);
+    
+      T* p_A      = ext_A.data();
+      T* p_result = ext_result.data();
+      
+      t1.start();
+      marker1_start();
+      for (size_t l=0; l<loop; ++l)
+      {
+	vthrx(p_A,1, &b, p_result,1, size, 0);
+      }
+      marker1_stop();
+      t1.stop();
+    }
+    
+    for (index_type i=0; i<size; ++i)
+    {
+      test_assert(equal<T>(result.get(i), (A(i) >= b) ? A(i) : b));
+    }
+    
+    time = t1.delta();
+  }
+};
+
+
+
 template <typename T>
 struct t_vthres_c : Benchmark_base
 {
@@ -161,11 +218,13 @@
   switch (what)
   {
   case  1: loop(t_vthres_sal<float>()); break;
+  case  2: loop(t_vthr_sal<float>()); break;
   case 11: loop(t_vthres_c<float>()); break;
   case  0:
     std::cout
       << "SAL vthres\n"
       << "  -1 -- SAL vthresx (float) Z(i) = A(i) > b ? A(i) : 0\n"
+      << "  -2 -- SAL vthrx   (float) Z(i) = A(i) > b ? A(i) : b\n"
       << " -11 -- C           (float) Z(i) = A(i) > b ? A(i) : 0\n"
       ;
   }
Index: examples/mercury/mcoe-setup.sh
===================================================================
--- examples/mercury/mcoe-setup.sh	(revision 173215)
+++ examples/mercury/mcoe-setup.sh	(working copy)
@@ -132,7 +132,7 @@
   cxxflags="$pflags $toolset_flag --no_implicit_include"
  
   opt_flags="-Ospeed -Onotailrecursion --max_inlining"
-  opt_flags="$opt_flags -DNDEBUG --diag_suppress 177,550"
+  opt_flags="$opt_flags -DNDEBUG --diag_suppress 175,177,550"
   dbg_flags="-g"
 
   ex_off_flags="--no_exceptions"
