Index: scripts/char.db
===================================================================
--- scripts/char.db	(revision 0)
+++ scripts/char.db	(revision 0)
@@ -0,0 +1,519 @@
+#########################################################################
+# char.db -- characterization database
+#
+# Format for a "set" entry:
+# 
+#   set: <set name>
+#     pgm:       <executable name: vmul>
+#     cases:     <list of cases: 1 2 5 11>
+#     fastcases: <list of "fast" cases: 1 2>
+#     nps:       <list of supported number of processors: default is "1">
+#     spes:      <list of supported number of SPEs: default is "0 1 8 16">
+#     req:       <required features: sal, ipp, fftw.  default is none>
+#     suffix:    <...>
+#     extra:     <extra command line parameters: -param 2048>
+#
+# Format for a "macro" entry:
+#
+#     macro: <macro name> <list of sets or macros>
+#
+
+
+
+#########################################################################
+# Vector Multiply
+#########################################################################
+
+set: vmul
+  pgm:       vmul
+  cases:     1 2 5 11 12 13 102
+  fastcases: 1 2
+
+set: vmul_c
+  pgm:   vmul_c
+  cases: 1 2
+
+set: sal-vmul
+  pgm:   sal/vmul
+  cases: 1 2
+  req:   sal
+
+set: ipp-vmul
+  pgm:   ipp/vmul
+  cases: 1 2 12 22
+  req:   ipp
+
+
+
+#########################################################################
+# Vector Multiply-Add
+#########################################################################
+
+set: vma
+  pgm:   vma
+  cases: 1 2 3 11 12 13 21 22 31 32
+
+set: sal-vma
+  pgm:   sal/vma
+  cases: 1 11 12 13
+  req:   sal
+
+
+
+#########################################################################
+# Vector-Matrix Multiply
+#########################################################################
+
+set: vmmul-64r
+  pgm:    vmmul
+  suffix: -64r
+  cases:  1 2 3 4 11 12 13 14 21 22 23 24 31 32 33 34
+  extra: -param 64 -stop 16
+
+set: vmmul-1r
+  pgm:    vmmul
+  suffix: -1r
+  cases:  1 2 3 4 11 12 13 14 21 22 23 24 31 32 33 34
+  extra:  -param 1 -stop 16
+
+set: vmmul-2048c
+  pgm:    vmmul
+  suffix: -2048c
+  cases:  11
+  extra:  -param 2048 -start 0 -stop 12
+
+
+
+#########################################################################
+# Elementwise Vector Operations
+#########################################################################
+
+# magsq - magnitude squared
+set: vmagsq
+  pgm: vmagsq
+  cases: 1 2
+
+#set: vthresh
+#  pgm: vthresh
+#  cases: 1 2
+
+
+
+#########################################################################
+# Reductions
+#########################################################################
+
+set: maxval
+  pgm: maxval
+  cases: 1 2 3
+
+set: sumval
+  pgm: sumval
+  cases: 1 21
+
+set: sumval_simd
+  pgm: sumval_simd
+  cases: 1 2 101 102
+
+
+
+#########################################################################
+# Memory Bandwidth
+#########################################################################
+
+set: memread_simd
+  pgm: memread_simd
+  cases: 1 2
+
+set: memwrite
+  pgm: memwrite
+  cases: 1 2
+
+set: memwrite_simd
+  pgm: memwrite_simd
+  cases: 1 2
+
+set: sal-memwrite
+  pgm: sal/memwrite
+  cases: 1
+
+
+
+#########################################################################
+# Data Transfer
+#########################################################################
+
+set: copy
+  pgm: copy
+  cases: 1 2 5
+  extra: -stop 17
+
+set: copy-p2p-core
+  pgm: copy
+  nps: 2
+  cases: 14 24
+  extra: -stop 20 -param 1
+
+set: copy-p2p-pas
+  req: pas
+  pgm: copy
+  nps: 2
+  cases: 204 214 224 254 264 274
+  extra: -stop 20 -param 1
+
+# -ns -- no pre-sync
+set: copy-p2p-core-ns
+  pgm: copy
+  suffix: -ns
+  nps: 2
+  cases: 14 24
+  extra: -stop 20 -param 0
+
+# -ns -- no pre-sync
+set: copy-p2p-pas-ns
+  req: pas
+  pgm: copy
+  suffix: -ns
+  nps: 2
+  cases: 204 214 224 254 264 274
+  extra: -stop 20 -param 0
+
+macro: copy-p2p copy-p2p-core copy-p2p-pas copy-p2p-core-ns copy-p2p-pas-ns
+
+set: copy-scatter
+  pgm: copy
+  nps: 2 3 5 9
+  cases: 15 25 205 215 225 255 265 275
+  extra: -stop 20
+
+set: mcopy-r
+  pgm: mcopy
+  cases: 1 2 3 4
+  extra: -stop 12
+
+set: mcopy-c
+  pgm: mcopy
+  cases: 5 6 7 8
+  extra: -stop 11
+
+
+
+#########################################################################
+# VSIPL++ FFT
+#########################################################################
+
+# FFT single (with number_of_time => estimate mode for FFTW)
+set: fft-est
+  pgm: fft
+  cases: 1 2 3 5 6 7
+  extra: -stop 20
+
+# FFT single (with number_of_time => measure mode for FFTW)
+set: fft-measure
+  pgm: fft
+  cases: 11 12 13 15 16 17
+  extra: -stop 20
+
+# FFT single (with number_of_time => patient mode for FFTW)
+# This takes a long time to run.
+set: fft-patient
+  pgm: fft
+  cases: 21 22 23 25 26 27
+  extra: -stop 20
+
+macro: fft fft-est fft-measure fft-patient
+
+# FFT CC out-of-place cross-section of fft-est, fft-measure, fft-patient
+set: fft-op
+  pgm: fft
+  cases: 1 11 21
+  extra: -stop 20
+
+
+# FFT double (with number_of_time => estimate mode for FFTW)
+set: fftd-est
+  pgm: fft
+  cases: 101 102 103 105 106 107
+  extra: -stop 20
+
+# FFT double (with number_of_time => measure mode for FFTW)
+set: fftd-measure
+  pgm: fft
+  cases: 111 112 113 115 116 117
+  extra: -stop 20
+
+# FFT double (with number_of_time => patient mode for FFTW)
+set: fftd-patient
+  pgm: fft
+  cases: 121 122 123 125 126 127
+  extra: -stop 20
+
+macro: fftd fftd-est fftd-measure fftd-patient
+
+
+
+#########################################################################
+# Vendor FFT
+#########################################################################
+
+set: ipp-fft
+  pgm: ipp/fft
+  cases: 1
+  extra: -stop 20
+  req: ipp
+
+set: sal-fft
+  pgm: sal/fft
+  cases: 1 2 5 6 11 12 15 16
+  extra: -stop 20
+  req: sal
+
+
+# Single-precision FFTW3 ------------------------------------------------
+
+set: fftw3-fft-core
+  pgm: fftw3/fft
+  cases: 1 11 51 61
+  extra: -stop 18
+  req: fftw3
+
+set: fftw3-fft-patient
+  pgm: fftw3/fft
+  cases: 21 71
+  extra: -stop 13
+  req: fftw3
+
+set: fftw3-fft-exhaustive
+  pgm: fftw3/fft
+  cases: 31 81
+  extra: -stop 10
+  req: fftw3
+
+macro: fftw3-fft fftw3-fft-core fftw3-fft-patient fftw3-fft-exhaustive
+
+
+# Double-precision FFTW3 ------------------------------------------------
+
+set: fftw3-fft-core_d
+  pgm: fftw3/fft
+  cases: 101 111
+  extra: -stop 18
+  req: fftw3
+
+set: fftw3-fft-patient_d
+  pgm: fftw3/fft
+  cases: 121
+  extra: -stop 13
+  req: fftw3
+
+macro: fftw3-fft fftw3-fft-core_d fftw3-fft-patient_d
+
+
+
+#########################################################################
+# VSIPL++ FFTM
+#########################################################################
+
+set: fftm64
+  pgm: fftm
+  suffix: -64r
+  fastcases: 1 2 3
+  cases: 1 2 3 4 5 6
+  extra: -param 64 -stop 16
+
+set: fftm32
+  pgm: fftm
+  suffix: -32r
+  fastcases: 1 2 3
+  cases: 1 2 3 4 5 6
+  extra: -param 32 -stop 16
+
+set: fftm16
+  pgm: fftm
+  suffix: -16r
+  fastcases: 1 2 3
+  cases: 1 2 3 4 5 6
+  extra: -param 16 -stop 16
+
+set: fftm8
+  pgm: fftm
+  suffix: -8r
+  fastcases: 1 2 3
+  cases: 1 2 3 4 5 6
+  extra: -param 8 -stop 16
+
+set: fftm4
+  pgm: fftm
+  suffix: -4r
+  fastcases: 1 2 3
+  cases: 1 2 3 4 5 6
+  extra: -param 4 -stop 16
+
+set: fftm2
+  pgm: fftm
+  suffix: -2r
+  fastcases: 1 2 3
+  cases: 1 2 3 4 5 6
+  extra: -param 2 -stop 16
+
+set: fftm1
+  pgm: fftm
+  suffix: -1r
+  fastcases: 1 2 3
+  cases: 1 2 3 4 5 6
+  extra: -param 1 -stop 16
+
+
+
+#########################################################################
+# Vendor FFTM
+#########################################################################
+
+set: fftw3-fftm
+  pgm: fftw3/fftm
+  cases: 1 101
+  extra: -stop 18
+  req: fftw3
+
+
+
+#########################################################################
+# Fast Convolution
+#########################################################################
+
+# fast convolution cases that can only be run in serial.
+# (64 pulses, sweep pulse size)
+set: fastconv-ser
+  pgm: fastconv
+  cases: 2
+  extra: -loop_start 1 -stop 16
+
+# fast convolution cases that can be run in parallel.
+# (64 pulses, sweep pulse size)
+set: fastconv-par
+  pgm: fastconv
+  cases: 1 5 6 8 9
+  nps: all
+  extra: -loop_start 1 -stop 16
+
+macro: fastconv fastconv-ser fastconv-par
+
+
+# fast convolution with fixed pulse size (fc = fixed-column)
+# (pulse size 2048, sweep number of pulses from 2^0=1 to 2^12=4096)
+set: fastconv-fc
+  pgm: fastconv
+  cases: 15 16 19
+  extra: -loop_start 1 -start 0 -stop 12 -param 2048
+
+# fast convolution with fixed pulse size (fc = fixed-column)
+# (pulse size 2048, sweep number of pulses from 2^0=1 to 2^12=4096)
+set: fastconv-fc-par
+  pgm: fastconv
+  nps: 1 2 4 8 16 32
+  cases: 15 16 19
+  extra: -loop_start 1 -start 0 -stop 12 -param 2048
+
+
+# SAL fast convolution
+set: sal-fastconv-fc
+  pgm: sal/fastconv
+  cases: 116 16
+  extra: -loop_start 1 -start 0 -stop 12 -param 2048
+  req: sal
+
+
+
+#########################################################################
+# QR 
+#########################################################################
+
+set: qrd
+  pgm: qrd
+  cases: 11 12 13 1 2 3
+  extra: -stop 8
+
+
+
+#########################################################################
+# Cell Specials 
+#########################################################################
+
+set: cell-fft
+  pgm: fft
+  cases: 11 12
+  extra: -start 5 -stop 12
+
+set: cell-fftm
+  pgm: fftm
+  spes: 0 1 8 16
+  cases: 11
+  extra: -start 0 -stop 12 -param 2048
+
+
+# Bandwidth measurements
+
+set: cell-bw-1-8
+  pgm: cell/bw
+  suffix: -n8
+  spes: 1
+  cases: 21 22 23 31 32 33
+  extra: -p:num 8 -start 0 -stop 12
+
+set: cell-bw-1-64
+  pgm: cell/bw
+  suffix: -n64
+  spes: 1
+  cases: 21 22 23 31 32 33
+  extra: -p:num 64 -start 0 -stop 12
+
+set: cell-bw-1-512
+  pgm: cell/bw
+  suffix: -n512
+  spes: 1
+  cases: 21 22 23 31 32 33
+  extra: -p:num 512 -start 0 -stop 12
+
+set: cell-bw-8-8
+  pgm: cell/bw
+  suffix: -n8
+  spes: 8
+  cases: 21 22 23 31 32 33
+  extra: -p:num 64 -start 0 -stop 12
+
+set: cell-bw-8-64
+  pgm: cell/bw
+  suffix: -n64
+  spes: 8
+  cases: 21 22 23 31 32 33
+  extra: -p:num 512 -start 0 -stop 12
+
+set: cell-bw-8-512
+  pgm: cell/bw
+  suffix: -n512
+  spes: 8
+  cases: 21 22 23 31 32 33
+  extra: -p:num 4096 -start 0 -stop 12
+
+set: cell-bw-16-8
+  pgm: cell/bw
+  suffix: -n8
+  spes: 16
+  cases: 21 22 23 31 32 33
+  extra: -p:num 128 -start 0 -stop 12
+
+set: cell-bw-16-64
+  pgm: cell/bw
+  suffix: -n64
+  spes: 16
+  cases: 21 22 23 31 32 33
+  extra: -p:num 1024 -start 0 -stop 12
+
+set: cell-bw-16-512
+  pgm: cell/bw
+  suffix: -n512
+  spes: 16
+  cases: 21 22 23 31 32 33
+  extra: -p:num 8192 -start 0 -stop 12
+
+macro: cell-bw cell-bw-1-8 cell-bw-1-64 cell-bw-1-512 cell-bw-8-8 cell-bw-8-64 cell-bw-8-512 cell-bw-16-8 cell-bw-16-64 cell-bw-16-512
Index: scripts/char.pl
===================================================================
--- scripts/char.pl	(revision 0)
+++ scripts/char.pl	(revision 0)
@@ -0,0 +1,277 @@
+#! /usr/bin/perl
+# --------------------------------------------------------------------- #
+# scripts/char.pl -- VSIPL++ Characterization Script			#
+# (4 Sep 06) Jules Bergmann						#
+# --------------------------------------------------------------------- #
+
+use strict;
+
+my $exe      = "";
+my $bdir     = "benchmarks";
+my $base_opt = "-samples 3";
+my $make_cmd = "make";
+my $make_opt = "";
+my $db_file  = "char.db";
+my $abs_path = 0;		# if 1, run program using absolute path
+
+my $mode     = 'normal';
+my $force    = 0;
+my $fast     = 0;
+my $dry      = 0;
+my $all      = 0;
+
+
+
+# --------------------------------------------------------------------- #
+sub read_db {
+   my ($file) = @_;
+
+   my $db    = {};
+   my $macro = {};
+
+   open(FILE, $file) || die "Can't read '$file': $!\n";
+
+   while (<FILE>) {
+      if (/^set:\s*([\w_\-]+)/) {
+	 my $set = $1;
+	 $db->{$set} = {};
+	 while (<FILE>) {
+            last if /^\s*$/;
+	    if (/\s+(\w+):\s*(.+)$/) {
+	       $db->{$set}{$1} = $2;
+	    }
+	 }
+      }
+      elsif (/^macro:\s*([\w-]+)\s+(.+)$/) {
+	 $macro->{$1} = [split(/\s+/, $2)];
+      }
+   }
+   close(FILE);
+
+   return $db, $macro;
+}
+
+
+
+# --------------------------------------------------------------------- #
+sub run_set {
+   my ($info, $db, $set) = @_;
+
+   print "run_set: $set\n";
+
+   if (!defined $db->{$set})
+   {
+      print "set $set: not defined\n";
+      return;
+   }
+
+   my $x      = $db->{$set};
+   my $pgm    = $db->{$set}{pgm};
+   my $cases  = $db->{$set}{cases};
+   my $fastc  = $db->{$set}{fastcases};
+   my $nps    = $db->{$set}{nps}  || "1";
+   my $spes   = $db->{$set}{spes} || "0 1 8 16";
+   my $what   = "data"; # $db->{$set}{what} || "ops";
+   my $suffix = $db->{$set}{suffix} || "";
+   my $extra  = $db->{$set}{extra} || "";
+   my $req    = $db->{$set}{req};
+
+   # check reqs
+   foreach my $r (split(/\s+/, $req)) {
+      if (!$info->{req}{$r})
+      {
+	 print "set $set: missing req $req\n";
+	 return;
+      }
+   }
+
+   if ($fast && $fastc) {
+      $cases = $fastc;
+   }
+
+   my $full_pgm = "$bdir/$pgm$exe";
+   my $pwd = `pwd`; $pwd =~ s/[\n\r]//;
+   $full_pgm = "$pwd/$full_pgm" if ($abs_path);
+
+   my $pgm_name = $pgm;
+   $pgm_name =~ s/\//-/;
+
+   my $opt = "-$what $base_opt $extra";
+
+   # 1. make benchmark (if necessary)
+   if (!-f $full_pgm) {
+      my $target = "$bdir/$pgm$exe";
+      print "MAKE $target\n";
+      system("echo $make_cmd $make_opt $target > log.make.$pgm_name");
+      system("$make_cmd $make_opt $target 2>&1 >> log.make.$pgm_name");
+      }
+   die "'$bdir/$pgm$exe' not executable" if (!-x "$bdir/$pgm$exe");
+
+   $nps = join(' ', @{$info->{nps}}) if ($nps eq 'all');
+
+   if ($mode eq 'cell') {
+      foreach my $x (split(/\s+/, $cases)) {
+	 foreach my $np (split(/\s+/, $nps)) {
+	    foreach my $spe (split(/\s+/, $spes)) {
+	       next if !defined $info->{np}{$np};
+	       next if !defined $info->{spe}{$spe};
+	       my $outfile = "$pgm_name$suffix-$x-$np-$spe.dat";
+	    
+	       run_benchmark(full_pgm => $full_pgm,
+			     x        => $x,
+			     np       => $np,
+			     spe      => $spe,
+			     opt      => $opt,
+			     outfile  => $outfile);
+	       }
+	    }
+	 }
+      }
+   else {
+      foreach my $x (split(/\s+/, $cases)) {
+	 foreach my $np (split(/\s+/, $nps)) {
+	    next if !defined $info->{np}{$np};
+	    my $outfile = "$pgm_name$suffix-$x-$np.dat";
+	    
+	    run_benchmark(full_pgm => $full_pgm,
+			  x        => $x,
+			  np       => $np,
+			  opt      => $opt,
+			  outfile  => $outfile);
+	    }
+	 }
+      }
+}
+
+
+
+sub run_benchmark {
+   my (%opt) = @_;
+
+   my $full_pgm = $opt{full_pgm};
+   my $x        = $opt{x};
+   my $np       = $opt{np};
+   my $spe      = $opt{spe};
+   my $opt      = $opt{opt};
+   my $outfile  = $opt{outfile};
+
+   if (-f $outfile && !$force ) {
+      print "$outfile skip\n";
+      next;
+      }
+
+   print "$outfile:\n";
+
+   my $runcmd = "";
+   my $runopt = "";
+   if ($mode eq 'mpi') {
+      $runcmd = "mpirun N -np $np";
+      }
+   elsif ($mode eq 'pas') {
+      $runcmd = "run-pas.sh -np $np";
+      }
+   elsif ($mode eq 'mc') {
+      $runcmd = "run.sh";
+      }
+   elsif ($mode eq 'cell') {
+      $runcmd = "";
+      $runopt = "--svpp-num-spes $spe";
+      }
+   
+   my $cmd = "$runcmd $full_pgm -$x $opt $runopt > $outfile";
+   print "CMD $cmd\n";
+   system($cmd) if !$dry;
+   }
+
+
+
+# --------------------------------------------------------------------- #
+# main
+
+my $info = {};
+$info->{req}  = {};
+$info->{nps}  = [1];
+$info->{spes} = [8];
+
+my @sets = ();
+
+while (@ARGV) {
+   my $arg = shift @ARGV;
+
+   $force    = 1, next if ($arg eq '-force');
+   $fast     = 1, next if ($arg eq '-fast');
+   $dry      = 1, next if ($arg eq '-dry');
+   $all      = 1, next if ($arg eq '-all');
+   $abs_path = 1, next if ($arg eq '-abs_path');
+   $bdir     = shift @ARGV, next if ($arg eq '-bdir');
+   $make_opt = shift @ARGV, next if ($arg eq '-make_opt');
+   $make_cmd = shift @ARGV, next if ($arg eq '-make_cmd');
+   $db_file  = shift @ARGV, next if ($arg eq '-db');
+   $exe      = shift @ARGV, next if ($arg eq '-exe');
+   $base_opt .= " -pool " . shift @ARGV, next if ($arg eq '-pool');
+   if ($arg eq '-mode') {
+      $mode = shift @ARGV;
+      die "Unknown mode: $mode" if ($mode !~ /(mpi|pas|mc|cell|normal)/);
+      next;
+      }
+   if ($arg eq '-np') {
+      my $str = shift @ARGV;
+      if ($str =~ /^(\d+)-(\d+)$/) {
+	  $info->{nps} = [$1 .. $2];
+      }
+      else {
+	  $info->{nps} = [split(',', $str)];
+      }
+      next;
+   }
+   if ($arg eq '-spe')
+   {
+      my $str = shift @ARGV;
+      if ($str =~ /^(\d+)-(\d+)$/) {
+	  $info->{spes} = [$1 .. $2];
+      }
+      else {
+	  $info->{spes} = [split(',', $str)];
+      }
+      next;
+   }
+   if ($arg eq '-have')
+   {
+      my $reqs = shift @ARGV;
+      foreach my $r (split(',', $reqs)) {
+	 $info->{req}{$r} = 1;
+      }
+      next;
+   }
+   push @sets, $arg;
+}
+
+foreach my $np (@{$info->{nps}}) {
+   $info->{np}{$np} = 1;
+   }
+
+foreach my $spe (@{$info->{spes}}) {
+   $info->{spe}{$spe} = 1;
+   }
+
+
+my ($db, $macro) = read_db($db_file);
+
+if ($all)
+{
+   @sets = keys %$db;
+}
+
+
+foreach my $set (@sets) {
+   if ($macro->{$set}) {
+      foreach my $s (@{$macro->{$set}}) {
+	 print "MACRO $set - $s\n";
+	 run_set($info, $db, $s);
+      }
+   }
+   else {
+      run_set($info, $db, $set);
+  }
+}
+

Property changes on: scripts/char.pl
___________________________________________________________________
Name: svn:executable
   + *

