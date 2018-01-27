Index: ChangeLog
===================================================================
--- ChangeLog	(revision 196915)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2008-03-26  Jules Bergmann  <jules@codesourcery.com>
+
+	* scripts/datasheet.pl: Move configuration into external file.
+	  Add support for csv output.
+
 2008-03-18  Jules Bergmann  <jules@codesourcery.com>
 
 	Merge 1.4 MCOE updates.
Index: scripts/datasheet.pl
===================================================================
--- scripts/datasheet.pl	(revision 191870)
+++ scripts/datasheet.pl	(working copy)
@@ -12,7 +12,7 @@
    my ($db, $inf) = @_;
 
    if (!-f $inf) {
-      print "No $inf, skipping\n";
+      print "No $inf, SKIPPING\n";
       return;
       }
    open(IN, $inf) || die "Can't read '$inf': $!\n";
@@ -26,13 +26,23 @@
       last if $line[0] eq 'what';
       }
 
-   die 'Could not find leading "what"' if ($line[0] ne 'what');
+   die "Could not find leading 'what' in '$inf'" if ($line[0] ne 'what');
 
-   $line = <IN>; chomp($line); my ($t_nproc, $np) = split(',', $line);
-   $line = <IN>; chomp($line); my @keys           = split(',', $line);
+   my $np = 1;
+   my @keys;
 
-   die 'expected "nproc" on line 2' if ($t_nproc ne "nproc");
+   while ($line = <IN>) {
+      chomp($line);
+      my @l = split(',', $line);
 
+      $np = $l[1]      if ($l[0] eq 'nproc');
+      @keys = @l, last if ($l[0] eq 'size');
+      }
+
+   # $line = <IN>; chomp($line); my ($t_nproc, $np) = split(',', $line);
+   # $line = <IN>; chomp($line); my @keys           = split(',', $line);
+   # die 'expected "nproc" on line 2' if ($t_nproc ne "nproc");
+
    # my $k = "$bench-$case-$np";
    my $k = "$inf";
    $k =~ s/\.dat//;
@@ -41,10 +51,12 @@
    $db->{$k}{data} = {};
    $db->{$k}{file} = $inf;
 
-   print "$inf: $k\n";
+   # print "$inf: $k\n";
 
    while (<IN>) {
       chomp($_);
+      last if /^--/;
+
       my @line = split(',', $_);
 
       my $record = {size    => $line[0] + 0,
@@ -68,7 +80,7 @@
       my $wiob_pt = $line[7];
       my $loop    = $line[8];
       my $time    = $line[9];
-
+     
       $db->{$k}{data}{$size} = $record;
       }
    close(IN);
@@ -81,8 +93,10 @@
    my $metric = $opt{metric} || "mflop_s";
    my $rows   = $opt{rows}   || 1;
 
-   my @sizes = (1024, 8192);
+   my $sizes  = $opt{sizes}  || [1024, 8192];
 
+   my @sizes = @$sizes;
+
    return if (!defined $db->{$k} && $opt{optional});
 
    print OUT "$descr\n";
@@ -91,218 +105,178 @@
       return;
       }
 
-   my $x_name;
-   $x_name = "MFLOP/s" if ($metric eq 'mflop_s');
-   $x_name = "MB/s"    if ($metric eq 'r_mb_s');
-   $x_name = "Mpt/s"   if ($metric eq 'mpts_s');
+   printf OUT "  %5s  %7s  %7s", "Size", "us/call", "us/pt";
 
-   printf OUT "  %5s  %7s  %7s  %7s\n", "Size", "us/call", "us/pt", $x_name;
-   # printf OUT "  %5s  %7s  %7s  %7s\n", "", "(usec)", "(usec)", "";
+   foreach my $m (split(',', $metric)) {
+      my $x_name;
+      $x_name = "MFLOP/s" if ($m eq 'mflop_s');
+      $x_name = "MB/s"    if ($m eq 'r_mb_s');
+      $x_name = "MB/s"    if ($m eq 't_mb_s');
+      $x_name = "Mpt/s"   if ($m eq 'mpts_s');
+      printf OUT "  %8s", $x_name;
+      }
+   printf OUT "\n";
+   # printf OUT "  %5s  %7s  %7s  %8s\n", "", "(usec)", "(usec)", "";
 
    foreach my $size (@sizes) {
       my $mpts_s  = $db->{$k}{data}{$size}{med};	# median Mpts-sec
       my $ops_pt  = $db->{$k}{data}{$size}{ops_pt};
       my $riob_pt = $db->{$k}{data}{$size}{riob_pt};
-      my $us_pt   = 1 / $mpts_s; # sec/M-point aka usec/point
+      my $wiob_pt = $db->{$k}{data}{$size}{wiob_pt};
+      my $us_pt   = ($mpts_s == 0) ? 0 : 1 / $mpts_s; # sec/M-point aka usec/point
       my $s       = $size * $us_pt;
 
       my $mflop_s = $mpts_s * $ops_pt;
       my $r_mb_s  = $mpts_s * $riob_pt;
+      my $t_mb_s  = $mpts_s * ($riob_pt + $wiob_pt);
 
       # For 2D object, users like to think of point as 1,1 element,
       # rather than a column of elements.
       $us_pt /= $rows;
 
-      my $x;
-      $x = $mflop_s if ($metric eq 'mflop_s');
-      $x = $r_mb_s  if ($metric eq 'r_mb_s');
-      $x = $mpts_s  if ($metric eq 'mpts_s');
+      if ($size >= 1048576) {
+	 printf OUT "  %4.2f%s", ($size / 1048576), "M";
+	 }
+      else {
+	 printf OUT "  %5d", $size;
+	 }
 
-      printf OUT "  %5d  %7.1f  %7.5f  %7.2f\n", $size, $s, $us_pt, $x;
+      printf OUT "  %7.1f  %7.5f", $s, $us_pt;
+
+      foreach my $m (split(',', $metric)) {
+	 my $x;
+	 $x = $mflop_s if ($m eq 'mflop_s');
+	 $x = $r_mb_s  if ($m eq 'r_mb_s');
+	 $x = $t_mb_s  if ($m eq 't_mb_s');
+	 $x = $mpts_s  if ($m eq 'mpts_s');
+	 printf OUT "  %8.2f", $x;
+	 }
+      printf OUT "\n";
       }
    print OUT "\n";
    }
 
 
-sub header {
-   print OUT "=" x 73, "\n";
-   }
 
-   
+sub report_func_csv {
+   my ($db, $k, $descr, %opt) = @_;
 
-my $db = {};
+   my $metric = $opt{metric} || "mflop_s";
+   my $rows   = $opt{rows}   || 1;
 
-read_dat($db, "conv-3-1.dat");
-read_dat($db, "conv-6-1.dat");
-read_dat($db, "conv2d-3x3-3-1.dat");
-read_dat($db, "conv2d-5x5-3-1.dat");
+   my $sizes  = $opt{sizes}  || [1024, 8192];
 
-read_dat($db, "copy-1-1.dat");
-read_dat($db, "copy-5-1.dat");
+   my @sizes = @$sizes;
 
-read_dat($db, "maxval-1-1.dat");
+   return if (!defined $db->{$k} && $opt{optional});
 
-read_dat($db, "sumval-1-1.dat");
+   if (!defined $db->{$k}) {
+      foreach my $size (@sizes) {
+	 printf OUT "$descr, $k, $size\n";
+	 }
+      return;
+      }
 
-read_dat($db, "fft-11-1.dat");
-read_dat($db, "fft-12-1.dat");
-read_dat($db, "fft-13-1.dat");
-read_dat($db, "fft-15-1.dat");
-read_dat($db, "fft-16-1.dat");
-read_dat($db, "fft-17-1.dat");
+   foreach my $size (@sizes) {
+      my $mpts_s  = $db->{$k}{data}{$size}{med};	# median Mpts-sec
+      my $ops_pt  = $db->{$k}{data}{$size}{ops_pt};
+      my $riob_pt = $db->{$k}{data}{$size}{riob_pt};
+      my $wiob_pt = $db->{$k}{data}{$size}{wiob_pt};
+      my $us_pt   = ($mpts_s == 0) ? 0 : 1 / $mpts_s; # sec/M-point aka usec/point
+      my $s       = $size * $us_pt;
 
-read_dat($db, "ipp-fft-1-1.dat");
+      my $mflop_s = $mpts_s * $ops_pt;
+      my $r_mb_s  = $mpts_s * $riob_pt;
+      my $t_mb_s  = $mpts_s * ($riob_pt + $wiob_pt);
 
-read_dat($db, "fftw3-fft-11-1.dat");
-read_dat($db, "fftw3-fft-12-1.dat");
-read_dat($db, "fftw3-fft-51-1.dat");
-read_dat($db, "fftw3-fft-52-1.dat");
+      # For 2D object, users like to think of point as 1,1 element,
+      # rather than a column of elements.
+      $us_pt /= $rows;
 
-read_dat($db, "sal-fft-1-1.dat");
-read_dat($db, "sal-fft-2-1.dat");
-read_dat($db, "sal-fft-5-1.dat");
-read_dat($db, "sal-fft-6-1.dat");
-read_dat($db, "sal-fft-11-1.dat");
-read_dat($db, "sal-fft-12-1.dat");
-read_dat($db, "sal-fft-15-1.dat");
-read_dat($db, "sal-fft-16-1.dat");
+      printf OUT "$descr, $k, $size, $s, $us_pt, $mflop_s, $r_mb_s, $t_mb_s, $mpts_s\n";
+      }
+   }
 
-read_dat($db, "vma-1-1.dat");
-read_dat($db, "vma-2-1.dat");
-read_dat($db, "vma-3-1.dat");
-read_dat($db, "vma-11-1.dat");
-read_dat($db, "vma-12-1.dat");
-read_dat($db, "vma-13-1.dat");
 
-read_dat($db, "vmin-1-1.dat");
+sub header {
+   print OUT "=" x 73, "\n";
+   }
 
-read_dat($db, "vmul-1-1.dat");
-read_dat($db, "vmul-2-1.dat");
-read_dat($db, "vmul-31-1.dat");
 
-read_dat($db, "sal-vmul-11-1.dat");
-read_dat($db, "sal-vmul-31-1.dat");
 
-read_dat($db, "svmul-1-1.dat");
+# --------------------------------------------------------------------- #
+sub read_db {
+   my ($db, $macro, $order, $file) = @_;
 
-read_dat($db, "vthresh-1-1.dat");
-read_dat($db, "vthresh-2-1.dat");
-read_dat($db, "vthresh-3-1.dat");
-read_dat($db, "vthresh-5-1.dat");
-read_dat($db, "vthresh-11-1.dat");
 
-read_dat($db, "sal-vthresh-1-1.dat");
-read_dat($db, "sal-vthresh-2-1.dat");
-read_dat($db, "sal-lvgt-1-1.dat");
-read_dat($db, "sal-lvgt-2-1.dat");
+   open(FILE, $file) || die "Can't read '$file': $!\n";
 
-read_dat($db, "vgt_ite-1-1.dat");
-read_dat($db, "vgt_ite-2-1.dat");
-read_dat($db, "vgt_ite-5-1.dat");
+   while (<FILE>) {
+      if (/^set:\s*([\w_\d\-]+)/) {
+	 my $set = $1;
+	 push @$order, $set;
+	 $db->{$set} = {};
+	 while (<FILE>) {
+            last if /^\s*$/;
+	    if (/\s+(\w+):\s*(.+)$/) {
+	       $db->{$set}{$1} = $2;
+	       }
+	    }
+	 }
+      elsif (/^macro:\s*([\w-]+)\s+(.+)$/) {
+	 $macro->{$1} = [split(/\s+/, $2)];
+	 }
+      }
+   close(FILE);
 
-open(OUT, "> report");
+   return $db, $macro;
+}
 
-# Conv
-header();
+my $dsinfo = "/home/jules/ds.info";
+my $fmt    = "text";
+my $ofile  = "report";
 
-report_func($db, "conv-3-1", "conv: 1D min-support convolution (16 point kernel) (float)");
-report_func($db, "conv-6-1", "conv: 1D min-support convolution (16 point kernel) (complex-float)");
+while (@ARGV) {
+   my $arg = shift @ARGV;
+   
+   $dsinfo = shift @ARGV, next if ($arg eq '-db');
+   $fmt    = shift @ARGV, next if ($arg eq '-fmt');
+   $ofile  = shift @ARGV, next if ($arg eq '-o');
+   }
 
-report_func($db, "conv2d-3x3-3-1", "conv: 2D min-support convolution (3x3 kernel, 256 rows) (float)", rows => 256);
-report_func($db, "conv2d-5x5-3-1", "conv: 2D min-support convolution (5x5 kernel, 256 rows) (float)", rows => 256);
+if (!-f $dsinfo) {
+   die "ERROR: Can't find dsinfo '$dsinfo'\n";
+   }
 
-# Copy
-header();
+my $db = {};
+my $descr = {};
+my $macro = {};
+my $order = [];
+print "read_db: $dsinfo\n";
+read_db($descr, $macro, $order, $dsinfo);
 
-report_func($db, "copy-1-1", "copy: vector copy (Z = A) (float)", metric => "r_mb_s");
-report_func($db, "copy-5-1", "copy (vendor): vector copy (memcpy) (float)", metric => "r_mb_s");
+foreach my $k (keys %$descr) {
+   read_dat($db, "$k.dat");
+   }
 
-# Fastconv
+open(OUT, "> $ofile");
+if ($fmt eq 'csv') {
+   printf OUT "descr, k, size, time (s), us/pt, MF/s, R MB/s, T MB/s, MPt/s\n";
+   }
 
-# FFT
-header();
-
-report_func($db, "fft-11-1", "fft: Out-of-place CC Fwd FFT (fft(A, Z))");
-report_func($db, "fft-12-1", "fft: In-place CC Fwd FFT (fft(AZ))");
-report_func($db, "fft-13-1", "fft: By-value CC Fwd FFT (Z = fft(A))");
-report_func($db, "fft-15-1", "fft: Out-of-place CC Inv FFT (fft(A, Z))");
-report_func($db, "fft-16-1", "fft: In-place CC Inv FFT (fft(AZ))");
-report_func($db, "fft-17-1", "fft: By-value CC Inv FFT (Z = fft(A))");
-
-# Vendor FFT
-header();
-
-report_func($db, "fftw3-fft-11-1", "fft (vendor-fftw3): Out-of-place CC Fwd FFT (inter complex)", optional => 1);
-report_func($db, "fftw3-fft-12-1", "fft (vendor-fftw3): In-place CC Fwd FFT (inter complex)", optional => 1);
-report_func($db, "fftw3-fft-51-1", "fft (vendor-fftw3): Out-of-place CC Fwd FFT (split complex)", optional => 1);
-report_func($db, "fftw3-fft-51-1", "fft (vendor-fftw3): In-place CC Fwd FFT (split complex)", optional => 1);
-
-report_func($db, "ipp-fft-1-1", "fft (vendor-IPP): Out-of-place CC Fwd FFT (inter complex)", optional => 1);
-
-report_func($db, "sal-fft-1-1", "fft (vendor-SAL): Out-of-place CC Fwd FFT (split complex)", optional => 1);
-report_func($db, "sal-fft-2-1", "fft (vendor-SAL): In-place CC Fwd FFT (split complex)", optional => 1);
-report_func($db, "sal-fft-5-1", "fft (vendor-SAL): Out-of-place CC Inv FFT (split complex)", optional => 1);
-report_func($db, "sal-fft-6-1", "fft (vendor-SAL): In-place CC Inv FFT (split complex)", optional => 1);
-report_func($db, "sal-fft-11-1", "fft (vendor-SAL): Out-of-place CC Fwd FFT (inter complex)", optional => 1);
-report_func($db, "sal-fft-12-1", "fft (vendor-SAL): In-place CC Fwd FFT (inter complex)", optional => 1);
-report_func($db, "sal-fft-15-1", "fft (vendor-SAL): Out-of-place CC Inv FFT (inter complex)", optional => 1);
-report_func($db, "sal-fft-16-1", "fft (vendor-SAL): In-place CC Inv FFT (inter complex)", optional => 1);
-
-# Maxval
-header();
-
-report_func($db, "maxval-1-1", "maxval: vector max (z = maxval(A, idx)) (float)", metric => "mpts_s");
-
-# Sumval
-report_func($db, "sumval-1-1", "sumval: vector sum (z = sumval(A)) (float)");
-
-# VMA
-header();
-
-report_func($db, "vma-1-1", "vma: vector fused multiply-add (Z = A * B + C) (float)");
-report_func($db, "vma-2-1", "vma: vector fused multiply-add (Z = a * B + C) (float)");
-report_func($db, "vma-3-1", "vma: vector fused multiply-add (Z = a * B + c) (float) (aka saxpy)");
-report_func($db, "vma-11-1", "vma: vector fused multiply-add (Z = A * B + C) (complex-float)");
-report_func($db, "vma-12-1", "vma: vector fused multiply-add (Z = a * B + C) (complex)");
-report_func($db, "vma-13-1", "vma: vector fused multiply-add (Z = a * B + c) (complex) (aka caxpy)");
-
-# VMIN
-header();
-
-report_func($db, "vmin-1-1", "vmin: vector minima (Z = min(A, B)) (float)");
-
-# VMUL
-header();
-
-report_func($db, "vmul-1-1", "vmul: vector multiply (Z = A * B) (float)");
-report_func($db, "vmul-2-1", "vmul: vector multiply (Z = A * B) (complex-float)");
-report_func($db, "vmul-31-1", "vmul: vector multiply IP (Z *= A) (float)");
-report_func($db, "svmul-1-1", "svmul: scalar-vector multiply (Z = a * B) (float)");
-
-report_func($db, "sal-vmul-11-1", "vmul (vendor-SAL): scalar-vector multiply (Z = a * B) (float)", optional => 1);
-report_func($db, "sal-vmul-31-1", "vmul (vendor-SAL): vector multiply IP (Z *= A) (float)", optional => 1);
-
-# VTHRESH
-header();
-
-report_func($db, "vthresh-1-1", "vthresh: vector threshold (Z = ite(A >= b, A, b)) (float) vthr");
-report_func($db, "vthresh-2-1", "vthresh: vector threshold (Z = ite(A >= b, A, 0)) (float) vthres");
-report_func($db, "vthresh-3-1", "vthresh: vector threshold (Z = ite(A >= b, A, c)) (float)");
-report_func($db, "vthresh-5-1", "vthresh: vector threshold (Z = ite(A >= b, 1, 0)) (float)");
-report_func($db, "vthresh-11-1", "vthresh: vector threshold (Z = ite(A > B, 1, 0)) (float) lvgt");
-
-
-
-report_func($db, "vgt_ite-1-1", "vthresh: vector threshold (Z = ite(A > B, A, 0)) (float) single-expr");
-report_func($db, "vgt_ite-2-1", "vthresh: vector threshold (Z = ite(A > B, A, 1)) (float)");
-report_func($db, "vgt_ite-5-1", "vthresh: vector threshold (Z = ite(A > B, A, 0)) (float) multi-expr");
-
-header();
-
-report_func($db, "sal-vthresh-1-1", "vthresh (vendor-SAL): vthreshx (Z = ite(A >= b, A, 0)) (float)", optional => 1);
-report_func($db, "sal-vthresh-2-1", "vthresh (vendor-SAL): vthrx (Z = ite(A >= b, A, b)) (float)", optional => 1);
-
-report_func($db, "sal-lvgt-1-1", "vthresh (vendor-SAL): lvgtx (Z = ite(A > B, 1, 0)) (float)", optional => 1);
-report_func($db, "sal-lvgt-2-1", "vthresh (vendor-SAL): lvgtx/vmul (Z = ite(A > B, A, 0)) (float)", optional => 1);
-
+foreach my $k (@$order) {
+   my @opt;
+   if ($descr->{$k}{sizes}) {
+      push @opt, sizes => [split(",", $descr->{$k}{sizes})];
+      }
+   if ($descr->{$k}{metric}) {
+      push @opt, metric => $descr->{$k}{metric};
+      }
+   if ($fmt eq 'csv') {
+      report_func_csv($db, $k, $descr->{$k}{text}, @opt);
+      }
+   else {
+      report_func($db, $k, $descr->{$k}{text} . "  ($k)", @opt);
+      }
+   }
 close(OUT);
