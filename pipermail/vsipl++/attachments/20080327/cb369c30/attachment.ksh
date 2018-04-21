Index: ChangeLog
===================================================================
--- ChangeLog	(revision 197775)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2008-03-27  Jules Bergmann  <jules@codesourcery.com>
+
+	* scripts/datasheet.pl: Add support for w_mb_s metric.  Allow lists
+	  to be space separated.
+
 2008-03-26  Jules Bergmann  <jules@codesourcery.com>
 
 	* scripts/datasheet.pl: Move configuration into external file.
Index: scripts/datasheet.pl
===================================================================
--- scripts/datasheet.pl	(revision 197775)
+++ scripts/datasheet.pl	(working copy)
@@ -107,11 +107,12 @@
 
    printf OUT "  %5s  %7s  %7s", "Size", "us/call", "us/pt";
 
-   foreach my $m (split(',', $metric)) {
+   foreach my $m (split(/[, ]/, $metric)) {
       my $x_name;
       $x_name = "MFLOP/s" if ($m eq 'mflop_s');
-      $x_name = "MB/s"    if ($m eq 'r_mb_s');
-      $x_name = "MB/s"    if ($m eq 't_mb_s');
+      $x_name = "R MB/s"  if ($m eq 'r_mb_s');
+      $x_name = "W MB/s"  if ($m eq 'w_mb_s');
+      $x_name = "T MB/s"  if ($m eq 't_mb_s');
       $x_name = "Mpt/s"   if ($m eq 'mpts_s');
       printf OUT "  %8s", $x_name;
       }
@@ -128,6 +129,7 @@
 
       my $mflop_s = $mpts_s * $ops_pt;
       my $r_mb_s  = $mpts_s * $riob_pt;
+      my $w_mb_s  = $mpts_s * $wiob_pt;
       my $t_mb_s  = $mpts_s * ($riob_pt + $wiob_pt);
 
       # For 2D object, users like to think of point as 1,1 element,
@@ -143,10 +145,11 @@
 
       printf OUT "  %7.1f  %7.5f", $s, $us_pt;
 
-      foreach my $m (split(',', $metric)) {
+      foreach my $m (split(/[, ]/, $metric)) {
 	 my $x;
 	 $x = $mflop_s if ($m eq 'mflop_s');
 	 $x = $r_mb_s  if ($m eq 'r_mb_s');
+	 $x = $w_mb_s  if ($m eq 'w_mb_s');
 	 $x = $t_mb_s  if ($m eq 't_mb_s');
 	 $x = $mpts_s  if ($m eq 'mpts_s');
 	 printf OUT "  %8.2f", $x;
@@ -187,13 +190,14 @@
 
       my $mflop_s = $mpts_s * $ops_pt;
       my $r_mb_s  = $mpts_s * $riob_pt;
+      my $w_mb_s  = $mpts_s * $wiob_pt;
       my $t_mb_s  = $mpts_s * ($riob_pt + $wiob_pt);
 
       # For 2D object, users like to think of point as 1,1 element,
       # rather than a column of elements.
       $us_pt /= $rows;
 
-      printf OUT "$descr, $k, $size, $s, $us_pt, $mflop_s, $r_mb_s, $t_mb_s, $mpts_s\n";
+      printf OUT "$descr, $k, $size, $s, $us_pt, $mflop_s, $r_mb_s, $w_mb_s, $t_mb_s, $mpts_s\n";
       }
    }
 
@@ -261,13 +265,13 @@
 
 open(OUT, "> $ofile");
 if ($fmt eq 'csv') {
-   printf OUT "descr, k, size, time (s), us/pt, MF/s, R MB/s, T MB/s, MPt/s\n";
+   printf OUT "descr, k, size, time (s), us/pt, MF/s, R MB/s, W MB/s, T MB/s, MPt/s\n";
    }
 
 foreach my $k (@$order) {
    my @opt;
    if ($descr->{$k}{sizes}) {
-      push @opt, sizes => [split(",", $descr->{$k}{sizes})];
+      push @opt, sizes => [split(/[, ]/, $descr->{$k}{sizes})];
       }
    if ($descr->{$k}{metric}) {
       push @opt, metric => $descr->{$k}{metric};
