Index: ChangeLog
===================================================================
--- ChangeLog	(revision 198068)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2008-04-15  Jules Bergmann  <jules@codesourcery.com>
+
+	* scripts/char.pl (-extra): Extra args for all benchmarks.
+	* scripts/datasheet.pl: Add section headers, prettier printing
+	  of time/call and time/point.
+
 2008-03-28  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/opt/sal/svd.hpp: Remove extaneous scalar_type defn.
Index: scripts/char.pl
===================================================================
--- scripts/char.pl	(revision 191870)
+++ scripts/char.pl	(working copy)
@@ -9,6 +9,7 @@
 my $exe      = "";
 my $bdir     = "benchmarks";
 my $base_opt = "-samples 3";
+my $base_extra = "";
 my $make_cmd = "make";
 my $make_opt = "";
 my @db_files = ();
@@ -93,7 +94,7 @@
    my $pgm_name = $pgm;
    $pgm_name =~ s/\//-/;
 
-   my $opt = "-$what $base_opt $extra";
+   my $opt = "-$what $base_opt $base_extra $extra";
 
    if (-f "log.cannot_build.$pgm") {
       print "'$bdir/$pgm$exe' previously failed to build - SKIP\n";
@@ -116,7 +117,7 @@
 
    $nps = join(' ', @{$info->{nps}}) if ($nps eq 'all');
 
-   if ($mode eq 'cell') {
+   if ($mode eq 'cell' || $mode eq 'cml') {
       foreach my $x (split(/\s+/, $cases)) {
 	 foreach my $np (split(/\s+/, $nps)) {
 	    foreach my $spe (split(/\s+/, $spes)) {
@@ -184,6 +185,10 @@
       $runcmd = "";
       $runopt = "--svpp-num-spes $spe";
       }
+   elsif ($mode eq 'cml') {
+      $runcmd = "";
+      $runopt = "--cml-num-spes $spe";
+      }
    
    my $cmd = "$runcmd $full_pgm -$x $opt $runopt > $outfile";
    print "CMD $cmd\n";
@@ -243,12 +248,13 @@
    $make_opt = shift @ARGV, next if ($arg eq '-make_opt');
    $make_cmd = shift @ARGV, next if ($arg eq '-make_cmd');
    push(@db_files, shift @ARGV), next if ($arg eq '-db');
-   $exe      = shift @ARGV, next if ($arg eq '-exe');
+   $exe        = shift @ARGV, next if ($arg eq '-exe');
+   $base_extra = shift @ARGV, next if ($arg eq '-extra');
    $base_opt .= " -ms " . shift @ARGV, next if ($arg eq '-ms');
    $base_opt .= " -pool " . shift @ARGV, next if ($arg eq '-pool');
    if ($arg eq '-mode') {
       $mode = shift @ARGV;
-      die "Unknown mode: $mode" if ($mode !~ /(mpi|pas|mc|cell|normal)/);
+      die "Unknown mode: $mode" if ($mode !~ /(mpi|pas|mc|cell|cml|normal)/);
       next;
       }
    if ($arg eq '-np') {
Index: scripts/datasheet.pl
===================================================================
--- scripts/datasheet.pl	(revision 198067)
+++ scripts/datasheet.pl	(working copy)
@@ -90,8 +90,9 @@
 sub report_func {
    my ($db, $k, $descr, %opt) = @_;
 
-   my $metric = $opt{metric} || "mflop_s";
-   my $rows   = $opt{rows}   || 1;
+   my $metric   = $opt{metric}   || "mflop_s";
+   my $timeunit = $opt{timeunit} || "us";
+   my $rows     = $opt{rows}     || 1;
 
    my $sizes  = $opt{sizes}  || [1024, 8192];
 
@@ -105,15 +106,22 @@
       return;
       }
 
-   printf OUT "  %5s  %7s  %7s", "Size", "us/call", "us/pt";
+   my $time_factor = 1;
+   $time_factor = 1       if $timeunit eq 'us';
+   $time_factor = 1000    if $timeunit eq 'ms';
+   $time_factor = 1000000 if $timeunit eq 's';
 
+   printf OUT "  %5s  %7s  %7s", "Size", "$timeunit/call", "$timeunit/pt";
+
    foreach my $m (split(/[, ]/, $metric)) {
       my $x_name;
       $x_name = "MFLOP/s" if ($m eq 'mflop_s');
+      $x_name = "MOP/s"   if ($m eq 'mop_s');
       $x_name = "R MB/s"  if ($m eq 'r_mb_s');
       $x_name = "W MB/s"  if ($m eq 'w_mb_s');
       $x_name = "T MB/s"  if ($m eq 't_mb_s');
       $x_name = "Mpt/s"   if ($m eq 'mpts_s');
+      next                if ($m eq 'none');
       printf OUT "  %8s", $x_name;
       }
    printf OUT "\n";
@@ -125,9 +133,13 @@
       my $riob_pt = $db->{$k}{data}{$size}{riob_pt};
       my $wiob_pt = $db->{$k}{data}{$size}{wiob_pt};
       my $us_pt   = ($mpts_s == 0) ? 0 : 1 / $mpts_s; # sec/M-point aka usec/point
+
+      $us_pt /= $time_factor;
+
       my $s       = $size * $us_pt;
 
       my $mflop_s = $mpts_s * $ops_pt;
+      my $mop_s   = $mpts_s * $ops_pt;
       my $r_mb_s  = $mpts_s * $riob_pt;
       my $w_mb_s  = $mpts_s * $wiob_pt;
       my $t_mb_s  = $mpts_s * ($riob_pt + $wiob_pt);
@@ -143,15 +155,33 @@
 	 printf OUT "  %5d", $size;
 	 }
 
-      printf OUT "  %7.1f  %7.5f", $s, $us_pt;
+      my $s_str = sprintf "%7.1f", $s;
+      if (length($s_str) > 7) {
+	$s_str = sprintf "%7f", $s;
+	}
+      if (length($s_str) > 7) {
+	$s_str = sprintf "%7.2g", $s;
+	}
 
+      my $us_pt_str = sprintf "%7.5f", $us_pt;
+      if (length($us_pt_str) > 7) {
+	$us_pt_str = sprintf "%7f", $us_pt;
+	}
+      if (length($us_pt_str) > 7) {
+	$us_pt_str = sprintf "%7.2g", $us_pt;
+	}
+
+      printf OUT "  %7s  %7s", $s_str, $us_pt_str;
+
       foreach my $m (split(/[, ]/, $metric)) {
 	 my $x;
 	 $x = $mflop_s if ($m eq 'mflop_s');
+	 $x = $mop_s   if ($m eq 'mop_s');
 	 $x = $r_mb_s  if ($m eq 'r_mb_s');
 	 $x = $w_mb_s  if ($m eq 'w_mb_s');
 	 $x = $t_mb_s  if ($m eq 't_mb_s');
 	 $x = $mpts_s  if ($m eq 'mpts_s');
+	 next          if ($m eq 'none');
 	 printf OUT "  %8.2f", $x;
 	 }
       printf OUT "\n";
@@ -203,7 +233,13 @@
 
 
 sub header {
-   print OUT "=" x 73, "\n";
+   my ($name) = @_;
+
+   print  OUT "\n";
+   print  OUT "=" x 73, "\n";
+   printf OUT "= %-69s =\n", $name;
+   print  OUT "=" x 73, "\n";
+   print  OUT "\n";
    }
 
 
@@ -212,6 +248,7 @@
 sub read_db {
    my ($db, $macro, $order, $file) = @_;
 
+   my $scnt = 0;
 
    open(FILE, $file) || die "Can't read '$file': $!\n";
 
@@ -227,6 +264,14 @@
 	       }
 	    }
 	 }
+      elsif (/^section:\s*(.+)/) {
+	 my $set = "section-$scnt";
+	 $scnt++;
+	 push @$order, $set;
+	 $db->{$set} = {};
+	 $db->{$set}{header} = $1;
+	 }
+	       
       elsif (/^macro:\s*([\w-]+)\s+(.+)$/) {
 	 $macro->{$1} = [split(/\s+/, $2)];
 	 }
@@ -260,6 +305,7 @@
 read_db($descr, $macro, $order, $dsinfo);
 
 foreach my $k (keys %$descr) {
+   next if $descr->{$k}{header};
    read_dat($db, "$k.dat");
    }
 
@@ -270,12 +316,21 @@
 
 foreach my $k (@$order) {
    my @opt;
+
+   if ($descr->{$k}{header}) {
+      header($descr->{$k}{header});
+      next;
+      }
+
    if ($descr->{$k}{sizes}) {
       push @opt, sizes => [split(/[, ]/, $descr->{$k}{sizes})];
       }
    if ($descr->{$k}{metric}) {
       push @opt, metric => $descr->{$k}{metric};
       }
+   if ($descr->{$k}{timeunit}) {
+      push @opt, timeunit => $descr->{$k}{timeunit};
+      }
    if ($fmt eq 'csv') {
       report_func_csv($db, $k, $descr->{$k}{text}, @opt);
       }
