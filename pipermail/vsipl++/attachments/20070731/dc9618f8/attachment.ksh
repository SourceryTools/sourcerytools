Index: ChangeLog
===================================================================
--- ChangeLog	(revision 177858)
+++ ChangeLog	(working copy)
@@ -1,5 +1,25 @@
 2007-07-31  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/core/fft/factory.hpp (create): Throw exception when
+	  a suitable FFT BE can't be found.
+	* src/vsip/core/expr/scalar_block.hpp: Add GHS pragmas.
+	* src/vsip/opt/sal/conv.hpp: Fix out of date bits.
+	* src/vsip_csl/test.hpp (Almost_equal): class version of almost_equal.
+	  GreenHills could not disambiguate almost_equal in some cases.
+	* scripts/char.pl: Handle recursive macros.
+	* scripts/char.db: Add additional cases.
+	* scripts/datasheet.pl: New file, script to generate "datasheet".
+	* tests/ref-impl/solvers-lu.cpp: Avoid std::abs, ambiguous with GHS.
+	* tests/ref-impl/signal-fir.cpp: Qualify use of exceptions.
+	* tests/regressions/vmul_sizes.cpp: Use Almose_equal.
+	* tests/regressions/transpose_assign.cpp: Use explicit delete[]
+	  instead of implicit delete.
+	* tests/coverage_binary.cpp: Remove add case.
+	* benchmarks/loop.hpp: Fix usec/pt metric title.
+	* benchmarks/fft.cpp: Fix usage description.
+
+2007-07-31  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/core/signal/conv.hpp: Fix ifdef logic bug.  Optimized
 	  BEs were not being included.
 	* src/vsip/opt/ipp/fir.hpp: Use aligned_array for temporary storage
Index: src/vsip/core/fft/factory.hpp
===================================================================
--- src/vsip/core/fft/factory.hpp	(revision 176624)
+++ src/vsip/core/fft/factory.hpp	(working copy)
@@ -13,6 +13,12 @@
   Included Files
 ***********************************************************************/
 
+#define VSIP_IMPL_VERBOSE_FFT_EXCEPTION 1
+
+#if VSIP_IMPL_VERBOSE_FFT_EXCEPTION
+#  include <sstream>
+#endif
+
 #include <vsip/core/fft/backend.hpp>
 #include <vsip/core/fft/util.hpp>
 #include <vsip/core/metaprogramming.hpp>
@@ -119,7 +125,18 @@
   create(Domain<D> const &dom, typename interface::scalar_type scale)
   {
     if (Eval::rt_valid(dom)) return Eval::create(dom, scale);
-    assert(0);
+#if VSIP_IMPL_VERBOSE_FFT_EXCEPTION
+    std::ostringstream msg;
+    msg << "Requested Fft "
+	<< "(dim: " << D << "  size: " << dom[0].size();
+    for (index_type i=1; i<D; ++i)
+      msg << "," << dom[i].size();
+    msg << ") not supported by available backends";
+    VSIP_IMPL_THROW(std::runtime_error(msg.str()));
+#else
+    VSIP_IMPL_THROW(std::runtime_error(
+		      "Requested Fft not supported by available backends"));
+#endif
     return std::auto_ptr<interface>();
   }
 };
@@ -214,7 +231,16 @@
   create(Domain<2> const &dom, typename interface::scalar_type scale)
   {
     if (Eval::rt_valid(dom)) return Eval::create(dom, scale);
-    assert(0);
+#if VSIP_IMPL_VERBOSE_FFT_EXCEPTION
+    std::ostringstream msg;
+    msg << "Requested Fftm "
+	<< "(size: " << dom[0].size() << "," << dom[1].size() 
+	<< ") not supported by available backends";
+    VSIP_IMPL_THROW(std::runtime_error(msg.str()));
+#else
+    VSIP_IMPL_THROW(std::runtime_error(
+		      "Requested Fftm not supported by available backends"));
+#endif
     return std::auto_ptr<interface>();
   }
 };
Index: src/vsip/core/expr/scalar_block.hpp
===================================================================
--- src/vsip/core/expr/scalar_block.hpp	(revision 176624)
+++ src/vsip/core/expr/scalar_block.hpp	(working copy)
@@ -38,7 +38,14 @@
   static type map;
 };
 
+// These are explicitly instantiated in scalar_block.cpp
+#if defined (__ghs__)
+#pragma do_not_instantiate Scalar_block_shared_map<1>::map
+#pragma do_not_instantiate Scalar_block_shared_map<2>::map
+#pragma do_not_instantiate Scalar_block_shared_map<3>::map
+#endif
 
+
 /// An adapter presenting a scalar as a block. This is useful when constructing
 /// Binary_expr_block objects (which expect two block operands) taking a block and
 /// a scalar.
Index: src/vsip/core/parallel/scalar_block_map.hpp
===================================================================
--- src/vsip/core/parallel/scalar_block_map.hpp	(revision 177792)
+++ src/vsip/core/parallel/scalar_block_map.hpp	(working copy)
@@ -81,7 +81,7 @@
 
   const_Vector<processor_type> processor_set() const
     { return vsip::processor_set(); }
-  
+
   // Applied map functions.
 public:
   length_type impl_num_patches(index_type sb) const VSIP_NOTHROW
Index: src/vsip/opt/sal/conv.hpp
===================================================================
--- src/vsip/opt/sal/conv.hpp	(revision 176624)
+++ src/vsip/opt/sal/conv.hpp	(working copy)
@@ -262,14 +262,14 @@
   typedef typename Adjust_layout<T, req_LP, LP0>::type use_LP0;
   typedef typename Adjust_layout<T, req_LP, LP1>::type use_LP1;
 
-  typedef vsip::impl::Ext_data_dist<Block0, use_LP0>  in_ext_type;
-  typedef vsip::impl::Ext_data_dist<Block1, use_LP1> out_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block0, SYNC_IN,  use_LP0>  in_ext_type;
+  typedef vsip::impl::Ext_data_dist<Block1, SYNC_OUT, use_LP1> out_ext_type;
 
-  in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
-  out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
+  in_ext_type  in_ext (in.block(),  in_buffer_);
+  out_ext_type out_ext(out.block(), out_buffer_);
 
-  VSIP_IMPL_PROFILE_FEATURE(pm_in_ext_cost_  += in_ext.cost());
-  VSIP_IMPL_PROFILE_FEATURE(pm_out_ext_cost_ += out_ext.cost());
+  VSIP_IMPL_PROFILE(pm_in_ext_cost_  += in_ext.cost());
+  VSIP_IMPL_PROFILE(pm_out_ext_cost_ += out_ext.cost());
 
   ptr_type pin    = in_ext.data();
   ptr_type pout   = out_ext.data();
@@ -346,17 +346,17 @@
   {
     if (Supp == support_full)
     {
-      VSIP_IMPL_PROFILE_FEATURE(pm_non_opt_calls_++);
+      VSIP_IMPL_PROFILE(pm_non_opt_calls_++);
       conv_full(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
     }
     else if (Supp == support_same)
     {
-      VSIP_IMPL_PROFILE_FEATURE(pm_non_opt_calls_++);
+      VSIP_IMPL_PROFILE(pm_non_opt_calls_++);
       conv_same(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
     }
     else // (Supp == support_min)
     {
-      VSIP_IMPL_PROFILE_FEATURE(pm_non_opt_calls_++);
+      VSIP_IMPL_PROFILE(pm_non_opt_calls_++);
       conv_min(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
     }
   }
Index: src/vsip_csl/test.hpp
===================================================================
--- src/vsip_csl/test.hpp	(revision 176624)
+++ src/vsip_csl/test.hpp	(working copy)
@@ -71,6 +71,54 @@
 ///    www.cygnus-software.com/papers/comparingfloats/comparingfloats.htm
 
 template <typename T>
+struct Almost_equal
+{
+  static bool eq(
+    T	A,
+    T	B,
+    T	rel_epsilon = 1e-4,
+    T	abs_epsilon = 1e-6)
+  {
+    if (vsip::mag(A - B) < abs_epsilon)
+      return true;
+    
+    T relative_error;
+    
+    if (vsip::mag(B) > vsip::mag(A))
+      relative_error = vsip::mag((A - B) / B);
+    else
+      relative_error = vsip::mag((B - A) / A);
+    
+    return (relative_error <= rel_epsilon);
+  }
+};
+
+template <typename T>
+struct Almost_equal<std::complex<T> >
+{
+  static bool eq(
+    std::complex<T>	A,
+    std::complex<T>	B,
+    T	rel_epsilon = 1e-4,
+    T	abs_epsilon = 1e-6)
+  {
+    if (vsip::mag(A - B) < abs_epsilon)
+      return true;
+
+    T relative_error;
+    
+    if (vsip::mag(B) > vsip::mag(A))
+      relative_error = vsip::mag((A - B) / B);
+    else
+      relative_error = vsip::mag((B - A) / A);
+    
+    return (relative_error <= rel_epsilon);
+  }
+};
+
+
+
+template <typename T>
 bool
 almost_equal(
   T	A,
Index: scripts/char.pl
===================================================================
--- scripts/char.pl	(revision 173072)
+++ scripts/char.pl	(working copy)
@@ -181,7 +181,26 @@
    }
 
 
+sub expand {
+   my ($macro, @sets) = @_;
 
+   my @rsets = ();
+
+   foreach my $set (@sets) {
+      if ($macro->{$set}) {
+	 print "MACRO $set\n";
+	 push @rsets, expand($macro, @{$macro->{$set}});
+	 }
+      else {
+	 push @rsets, $set;
+	 }
+      }
+   return @rsets;
+   }
+      
+	   
+
+
 # --------------------------------------------------------------------- #
 # main
 
@@ -265,15 +284,8 @@
    }
 
 
-foreach my $set (@sets) {
-   if ($macro->{$set}) {
-      foreach my $s (@{$macro->{$set}}) {
-	 print "MACRO $set - $s\n";
-	 run_set($info, $db, $s);
-	 }
-      }
-   else {
-      run_set($info, $db, $set);
-      }
+my @rsets = expand($macro, @sets);
+
+foreach my $set (@rsets) {
+   run_set($info, $db, $set);
    }
-
Index: scripts/char.db
===================================================================
--- scripts/char.db	(revision 173072)
+++ scripts/char.db	(working copy)
@@ -29,15 +29,21 @@
 #                  used for extremely long running benchmarks, such
 #                  as FFT in patient or exhaustive planning mode.
 
+#########################################################################
+# Core characterization
+#########################################################################
 
+macro: core vmul vma fft-est fft-measure vendor-fft maxval sumval copy fastconv conv vthresh vgt_ite vendor-vthresh
 
+
+
 #########################################################################
 # Vector Multiply
 #########################################################################
 
 set: vmul
   pgm:       vmul
-  cases:     1 2 5 102
+  cases:     1 2 5 51 52 102
   fastcases: 1 2
 
 set: vmul_c
@@ -51,7 +57,7 @@
 
 set: sal-vmul
   pgm:   sal/vmul
-  cases: 1 2
+  cases: 1 2 3
   req:   sal
 
 set: sal-svmul
@@ -115,14 +121,25 @@
   pgm: vmagsq
   cases: 1 2
 
-#set: vthresh
-#  pgm: vthresh
-#  cases: 1 2
+set: vthresh
+  pgm: vthresh
+  cases: 1 2 3 11
 
+set: vgt_ite
+  pgm: vgt_ite
+  cases: 1 2 5
+
+set: sal-vthresh
+  pgm: sal/vthresh
+  cases: 1 11
+  req:   sal
+
 set: sal-lvgt
   pgm: sal/lvgt
   cases: 1 2 11 12
+  req:   sal
 
+macro: vendor-vthresh sal-vthresh sal-lvgt
 
 
 #########################################################################
@@ -301,7 +318,7 @@
 
 set: fftw3-fft-core
   pgm: fftw3/fft
-  cases: 1 11 51 61
+  cases: 1 11 12 51 61 62
   extra: -stop 18
   req: fftw3
 
@@ -317,7 +334,7 @@
   extra: -stop 10
   req: fftw3 patience
 
-macro: fftw3-fft fftw3-fft-core fftw3-fft-patient fftw3-fft-exhaustive
+macro: fftw3-fft fftw3-fft-core fftw3-fft-patient
 
 
 # Double-precision FFTW3 ------------------------------------------------
@@ -334,10 +351,12 @@
   extra: -stop 13
   req: fftw3 patience
 
-macro: fftw3-fft fftw3-fft-core_d fftw3-fft-patient_d
+macro: fftw3-fft_d fftw3-fft-core_d fftw3-fft-patient_d
 
+macro: vendor-fft ipp-fft sal-fft fftw3-fft
 
 
+
 #########################################################################
 # VSIPL++ FFTM
 #########################################################################
@@ -464,6 +483,30 @@
 
 
 #########################################################################
+# Convolution 
+#########################################################################
+
+set: conv1d
+  pgm: conv
+  cases: 1 2 3 4 5 6
+
+set: conv2d-3x3
+  pgm: conv2d
+  suffix: -3x3
+  cases: 3
+  extra: -p:rows 256 -p:mn 3 -stop 16
+
+set: conv2d-5x5
+  pgm: conv2d
+  suffix: -5x5
+  cases: 3
+  extra: -p:rows 256 -p:mn 5 -stop 16
+
+macro: conv conv1d conv2d-3x3 conv2d-5x5
+
+
+
+#########################################################################
 # Cell Specials 
 #########################################################################
 
@@ -556,3 +599,4 @@
   req:   cell
 
 macro: cell-bw cell-bw-1-8 cell-bw-1-64 cell-bw-1-512 cell-bw-8-8 cell-bw-8-64 cell-bw-8-512 cell-bw-16-8 cell-bw-16-64 cell-bw-16-512
+
Index: scripts/datasheet.pl
===================================================================
--- scripts/datasheet.pl	(revision 0)
+++ scripts/datasheet.pl	(revision 0)
@@ -0,0 +1,253 @@
+#! /usr/bin/perl
+# --------------------------------------------------------------------- #
+# scripts/datasheet.pl -- VSIPL++ Datasheet Script			#
+# (31 Jul 07) Jules Bergmann						#
+# --------------------------------------------------------------------- #
+
+use strict;
+
+# --------------------------------------------------------------------- #
+# read_dat -- read .dat file generated by char.pl
+sub read_dat {
+   my ($db, $inf) = @_;
+
+   if (!-f $inf) {
+      print "No $inf, skipping\n";
+      return;
+      }
+   open(IN, $inf) || die "Can't read '$inf': $!\n";
+
+   my $line;
+   my @line;
+
+   while (<IN>) {
+      chomp($_);
+      @line = split(',', $_);
+      last if $line[0] eq 'what';
+      }
+
+   die 'Could not find leading "what"' if ($line[0] ne 'what');
+
+   $line = <IN>; chomp($line); my ($t_nproc, $np) = split(',', $line);
+   $line = <IN>; chomp($line); my @keys           = split(',', $line);
+
+   die 'expected "nproc" on line 2' if ($t_nproc ne "nproc");
+
+   # my $k = "$bench-$case-$np";
+   my $k = "$inf";
+   $k =~ s/\.dat//;
+
+   $db->{$k}       = {};
+   $db->{$k}{data} = {};
+   $db->{$k}{file} = $inf;
+
+   print "$inf: $k\n";
+
+   while (<IN>) {
+      chomp($_);
+      my @line = split(',', $_);
+
+      my $record = {size    => $line[0] + 0,
+		    med     => $line[1],
+		    min     => $line[2],
+		    max     => $line[3],
+		    mem_pt  => $line[4],
+		    ops_pt  => $line[5],
+		    riob_pt => $line[6],
+		    wiob_pt => $line[7],
+		    loop    => $line[8],
+		    time    => $line[9]};
+
+      my $size    = $line[0] + 0;
+      my $med     = $line[1];
+      my $min     = $line[2];
+      my $max     = $line[3];
+      my $mem_pt  = $line[4];
+      my $ops_pt  = $line[5];
+      my $riob_pt = $line[6];
+      my $wiob_pt = $line[7];
+      my $loop    = $line[8];
+      my $time    = $line[9];
+
+      $db->{$k}{data}{$size} = $record;
+      }
+   close(IN);
+   }
+
+
+sub report_func {
+   my ($db, $k, $descr, %opt) = @_;
+
+   my $metric = $opt{metric} || "mflop_s";
+   my $rows   = $opt{rows}   || 1;
+
+   my @sizes = (1024, 8192);
+
+   return if (!defined $db->{$k} && $opt{optional});
+
+   print OUT "$descr\n";
+   if (!defined $db->{$k}) {
+      print OUT "   (not generated)\n\n";
+      return;
+      }
+
+   my $x_name;
+   $x_name = "MFLOP/s" if ($metric eq 'mflop_s');
+   $x_name = "MB/s"    if ($metric eq 'r_mb_s');
+   $x_name = "Mpt/s"   if ($metric eq 'mpts_s');
+
+   printf OUT "  %5s  %7s  %7s  %7s\n", "Size", "usec", "usec/pt", $x_name;
+   # printf OUT "  %5s  %7s  %7s  %7s\n", "", "(usec)", "(usec)", "";
+
+   foreach my $size (@sizes) {
+      my $mpts_s  = $db->{$k}{data}{$size}{med};	# median Mpts-sec
+      my $ops_pt  = $db->{$k}{data}{$size}{ops_pt};
+      my $riob_pt = $db->{$k}{data}{$size}{riob_pt};
+      my $us_pt   = 1 / $mpts_s; # sec/M-point aka usec/point
+      my $s       = $size * $us_pt;
+
+      my $mflop_s = $mpts_s * $ops_pt;
+      my $r_mb_s  = $mpts_s * $riob_pt;
+
+      # For 2D object, users like to think of point as 1,1 element,
+      # rather than a column of elements.
+      $us_pt /= $rows;
+
+      my $x;
+      $x = $mflop_s if ($metric eq 'mflop_s');
+      $x = $r_mb_s  if ($metric eq 'r_mb_s');
+      $x = $mpts_s  if ($metric eq 'mpts_s');
+
+      printf OUT "  %5d  %7.2f  %7.2f  %7.2f\n", $size, $s, $us_pt, $x;
+      }
+   print OUT "\n";
+   }
+
+
+sub header {
+   print OUT "=" x 73, "\n";
+   }
+
+   
+
+my $db = {};
+
+read_dat($db, "conv-3-1.dat");
+read_dat($db, "conv-6-1.dat");
+read_dat($db, "conv2d-3x3-3-1.dat");
+read_dat($db, "conv2d-5x5-3-1.dat");
+
+read_dat($db, "copy-1-1.dat");
+read_dat($db, "copy-5-1.dat");
+
+read_dat($db, "maxval-1-1.dat");
+
+read_dat($db, "sumval-1-1.dat");
+
+read_dat($db, "fft-11-1.dat");
+read_dat($db, "fft-12-1.dat");
+read_dat($db, "fft-13-1.dat");
+read_dat($db, "fft-15-1.dat");
+read_dat($db, "fft-16-1.dat");
+read_dat($db, "fft-17-1.dat");
+
+read_dat($db, "ipp-fft-1-1.dat");
+read_dat($db, "fftw3-fft-11-1.dat");
+read_dat($db, "fftw3-fft-12-1.dat");
+read_dat($db, "fftw3-fft-51-1.dat");
+read_dat($db, "fftw3-fft-52-1.dat");
+
+
+read_dat($db, "vma-1-1.dat");
+read_dat($db, "vma-2-1.dat");
+read_dat($db, "vma-3-1.dat");
+read_dat($db, "vma-11-1.dat");
+read_dat($db, "vma-12-1.dat");
+read_dat($db, "vma-13-1.dat");
+read_dat($db, "vmul-1-1.dat");
+read_dat($db, "vmul-2-1.dat");
+
+read_dat($db, "vthresh-1-1.dat");
+read_dat($db, "vthresh-2-1.dat");
+read_dat($db, "vthresh-3-1.dat");
+read_dat($db, "vthresh-11-1.dat");
+read_dat($db, "vgt_ite-1-1.dat");
+read_dat($db, "vgt_ite-2-1.dat");
+read_dat($db, "vgt_ite-5-1.dat");
+
+open(OUT, "> report");
+
+# Conv
+header();
+
+report_func($db, "conv-3-1", "conv: 1D min-support convolution (16 point kernel) (float)");
+report_func($db, "conv-6-1", "conv: 1D min-support convolution (16 point kernel) (complex-float)");
+
+report_func($db, "conv2d-3x3-3-1", "conv: 2D min-support convolution (3x3 kernel, 256 rows) (float)", rows => 256);
+report_func($db, "conv2d-5x5-3-1", "conv: 2D min-support convolution (5x5 kernel, 256 rows) (float)", rows => 256);
+
+# Copy
+header();
+
+report_func($db, "copy-1-1", "copy: vector copy (Z = A) (float)", metric => "r_mb_s");
+report_func($db, "copy-5-1", "copy (vendor): vector copy (memcpy) (float)", metric => "r_mb_s");
+
+# Fastconv
+
+# FFT
+header();
+
+report_func($db, "fft-11-1", "fft: Out-of-place CC Fwd FFT (fft(A, Z))");
+report_func($db, "fft-12-1", "fft: In-place CC Fwd FFT (fft(AZ))");
+report_func($db, "fft-13-1", "fft: By-value CC Fwd FFT (Z = fft(A))");
+report_func($db, "fft-15-1", "fft: Out-of-place CC Inv FFT (fft(A, Z))");
+report_func($db, "fft-16-1", "fft: In-place CC Inv FFT (fft(AZ))");
+report_func($db, "fft-17-1", "fft: By-value CC Inv FFT (Z = fft(A))");
+
+# Vendor FFT
+header();
+
+report_func($db, "fftw3-fft-11-1", "fft (vendor-fftw3): Out-of-place CC Fwd FFT (inter complex)", optional => 1);
+report_func($db, "fftw3-fft-12-1", "fft (vendor-fftw3): In-place CC Fwd FFT (inter complex)", optional => 1);
+report_func($db, "fftw3-fft-51-1", "fft (vendor-fftw3): Out-of-place CC Fwd FFT (split complex)", optional => 1);
+report_func($db, "fftw3-fft-51-1", "fft (vendor-fftw3): In-place CC Fwd FFT (split complex)", optional => 1);
+
+report_func($db, "ipp-fft-1-1", "fft (vendor-IPP): Out-of-place CC Fwd FFT (inter complex)", optional => 1);
+
+# Maxval
+header();
+
+report_func($db, "maxval-1-1", "maxval: vector max (z = maxval(A, idx)) (float)", metric => "mpts_s");
+
+# Sumval
+report_func($db, "sumval-1-1", "sumval: vector sum (z = sumval(A)) (float)");
+
+# VMA
+header();
+
+report_func($db, "vma-1-1", "vma: vector fused multiply-add (Z = A * B + C) (float)");
+report_func($db, "vma-2-1", "vma: vector fused multiply-add (Z = a * B + C) (float)");
+report_func($db, "vma-3-1", "vma: vector fused multiply-add (Z = a * B + c) (float) (aka saxpy)");
+report_func($db, "vma-11-1", "vma: vector fused multiply-add (Z = A * B + C) (complex-float)");
+report_func($db, "vma-12-1", "vma: vector fused multiply-add (Z = a * B + C) (complex)");
+report_func($db, "vma-13-1", "vma: vector fused multiply-add (Z = a * B + c) (complex) (aka caxpy)");
+
+# VMUL
+header();
+
+report_func($db, "vmul-1-1", "vmul: vector multiply (Z = A * B) (float)");
+report_func($db, "vmul-2-1", "vmul: vector multiply (Z = A * B) (complex-float)");
+
+# VTHRESH
+header();
+
+report_func($db, "vthresh-1-1", "vthresh: vector threshold (Z = ite(A >= b, A, b)) (float) vthr");
+report_func($db, "vthresh-2-1", "vthresh: vector threshold (Z = ite(A >= b, A, 0)) (float) vthres");
+report_func($db, "vthresh-3-1", "vthresh: vector threshold (Z = ite(A >= b, A, c)) (float)");
+report_func($db, "vthresh-11-1", "vthresh: vector threshold (Z = ite(A > B, 1, 0)) (float) lvgt");
+
+report_func($db, "vgt_ite-1-1", "vthresh: vector threshold (Z = ite(A > B, A, 0)) (float) lvgt/vmul");
+report_func($db, "vgt_ite-2-1", "vthresh: vector threshold (Z = ite(A > B, A, 1)) (float)");
+report_func($db, "vgt_ite-5-1", "vthresh: vector threshold (Z = ite(A > B, A, 0)) (float) multi-expr");
+
+close(OUT);

Property changes on: scripts/datasheet.pl
___________________________________________________________________
Name: svn:executable
   + *

Index: tests/ref-impl/solvers-lu.cpp
===================================================================
--- tests/ref-impl/solvers-lu.cpp	(revision 173072)
+++ tests/ref-impl/solvers-lu.cpp	(working copy)
@@ -201,7 +201,7 @@
 		difference (vsip::prod (sA2, X) - sB);
   for (vsip::index_type i = 0; i < 6; ++i)
     for (vsip::index_type j = 0; j < 3; ++j) {
-      if (std::abs (difference.get (i,j)) > 0.01)
+      if (vsip::mag (difference.get (i,j)) > 0.01)
 	return EXIT_FAILURE;
     }
 
Index: tests/ref-impl/signal-fir.cpp
===================================================================
--- tests/ref-impl/signal-fir.cpp	(revision 173072)
+++ tests/ref-impl/signal-fir.cpp	(working copy)
@@ -145,17 +145,21 @@
 
   /* Test assignment operator and copy constructor.  */
 
+#if VSIP_HAS_EXCEPTIONS
   try
   {
+#endif
     vsip::Fir<> 	fir2 (fir1);
     out_length = fir2 (input0, output0);
     insist (checkVector (out_length, output0, answer2));
     fir2 = fir0;
     out_length = fir2 (input0, output0);
     insist (checkVector (out_length, output0, answer0));
+#if VSIP_HAS_EXCEPTIONS
   }
   // C-VSIPL doesn't provide state-preserving assignment.
   catch (vsip::impl::unimplemented const &) {}
+#endif
   /* Test decimations equaling 1 and 2.  */
 
   input_length = 5;
Index: tests/regressions/vmul_sizes.cpp
===================================================================
--- tests/regressions/vmul_sizes.cpp	(revision 173875)
+++ tests/regressions/vmul_sizes.cpp	(working copy)
@@ -63,7 +63,7 @@
 		<< A(i) * B(i) << std::endl;
     }
 #endif
-    test_assert(almost_equal(Z.get(i), A.get(i) * B.get(i)));
+    test_assert(Almost_equal<T>::eq(Z.get(i), A.get(i) * B.get(i)));
   }
 }
 
Index: tests/regressions/transpose_assign.cpp
===================================================================
--- tests/regressions/transpose_assign.cpp	(revision 173072)
+++ tests/regressions/transpose_assign.cpp	(working copy)
@@ -18,7 +18,6 @@
   Included Files
 ***********************************************************************/
 
-#include <iostream>
 #include <memory>
 
 #include <vsip/initfin.hpp>
@@ -121,6 +120,9 @@
   for (index_type r=0; r<rows; r++)
     for (index_type c=0; c<cols; c++)
       test_assert(dst.get()[r + c*rows] == T(100*r + c));
+
+  delete[] dst.release();
+  delete[] src.release();
 }
 
 
@@ -163,4 +165,6 @@
 
   cover_ll<float>();
   cover_ll<complex<float> >();
+
+  return 0;
 }
Index: tests/coverage_binary.cpp
===================================================================
--- tests/coverage_binary.cpp	(revision 173218)
+++ tests/coverage_binary.cpp	(working copy)
@@ -60,7 +60,6 @@
   vector_cases3<Test_min,  float,  float>();
   vector_cases3<Test_band, int,    int>();
   vector_cases3<Test_lxor, bool,   bool>();
-  matrix_cases3<Test_add,  float,  float>();
 #else
 
   vector_cases3<Test_max, float,   float>();
Index: benchmarks/loop.hpp
===================================================================
--- benchmarks/loop.hpp	(revision 173875)
+++ benchmarks/loop.hpp	(working copy)
@@ -365,7 +365,7 @@
 	     metric_ == wiob_per_sec ? "wiob_per_sec" :
 	     metric_ == data_per_sec ? "data_per_sec" :
 	     metric_ == all_per_sec  ? "all_per_sec" :
-	     metric_ == secs_per_pt  ? "secs_per_pt" :
+	     metric_ == secs_per_pt  ? "usecs_per_pt" :
 	                               "*unknown*");
       if (this->note_)
 	printf("# note: %s\n", this->note_);
@@ -514,7 +514,7 @@
 	   metric_ == riob_per_sec ? "riob_per_sec" :
 	   metric_ == wiob_per_sec ? "wiob_per_sec" :
 	   metric_ == data_per_sec ? "data_per_sec" :
-	   metric_ == secs_per_pt  ? "secs_per_pt" :
+	   metric_ == secs_per_pt  ? "usecs_per_pt" :
 	                             "*unknown*");
     if (this->note_)
       printf("# note: %s\n", this->note_);
Index: benchmarks/fft.cpp
===================================================================
--- benchmarks/fft.cpp	(revision 173215)
+++ benchmarks/fft.cpp	(working copy)
@@ -263,9 +263,9 @@
       << "   -1 -- op: out-of-place CC fwd fft\n"
       << "   -2 -- ip: in-place     CC fwd fft\n"
       << "   -3 -- bv: by-value     CC fwd fft\n"
-      << "   -4 -- op: out-of-place CC inv fft (w/scaling)\n"
-      << "   -5 -- ip: in-place     CC inv fft (w/scaling)\n"
-      << "   -6 -- bv: by-value     CC inv fft (w/scaling)\n"
+      << "   -5 -- op: out-of-place CC inv fft (w/scaling)\n"
+      << "   -6 -- ip: in-place     CC inv fft (w/scaling)\n"
+      << "   -7 -- bv: by-value     CC inv fft (w/scaling)\n"
 
       << " Planning effor: measure (number of times = 15): 11-16\n"
       << " Planning effor: pateint (number of times = 0): 21-26\n"
