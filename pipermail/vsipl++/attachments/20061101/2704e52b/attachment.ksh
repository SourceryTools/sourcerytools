Index: ChangeLog
===================================================================
--- ChangeLog	(revision 153680)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2006-11-01  Jules Bergmann  <jules@codesourcery.com>
 
+	* scripts/fmt-profile.pl: New file, script for formatting profiler
+	  output.
+	
+2006-11-01  Jules Bergmann  <jules@codesourcery.com>
+
 	Rename isnan to is_nan (and ilk) since isnan may be a macro.
 	* src/vsip/core/fns_scalar.hpp: Rename is_nan and ilk.
 	* src/vsip/core/fns_elementwise.hpp: Likewise.
Index: scripts/fmt-profile.pl
===================================================================
--- scripts/fmt-profile.pl	(revision 0)
+++ scripts/fmt-profile.pl	(revision 0)
@@ -0,0 +1,163 @@
+#! /usr/bin/perl
+
+#########################################################################
+# fmt-profile.pl -- Format VSIPL++ profiler output			#
+#									#
+# author: Jules Bergmann						#
+# date:   2006-11-01							#
+#									#
+# Usage:								#
+#   fmt-profile.pl [-sec] <profile.txt>					#
+#									#
+# Options:								#
+#   -sec -- convert ticks into seconds					#
+#########################################################################
+
+use strict;
+
+# --------------------------------------------------------------------- #
+# get_info -- get format info
+# --------------------------------------------------------------------- #
+sub get_info {
+    my $info = {};
+
+    $info->{0} = {fmt => '%-${len}s' };
+    $info->{1} = {fmt => '%${len}d' };
+    $info->{2} = {fmt => '%${len}d' };
+    $info->{3} = {fmt => '%${len}d' };
+    $info->{4} = {fmt => '%${len}f' };
+
+    return $info;
+}
+
+
+
+# --------------------------------------------------------------------- #
+# fmt_profile -- format a profile file
+# --------------------------------------------------------------------- #
+sub fmt_profile {
+   my ($file, %opt) = @_;
+
+   my $tmp_file = "$file.tmp";
+
+   open(IN, $file)           || die "Can't read '$file': $!\n";
+
+   my @key;
+   my @maxlen;
+   my $clocks_per_sec = 1;
+   my $conv_tick = 0;
+
+   my $info = get_info();
+
+   # ------------------------------------------------------------------
+   # Pass 1: determine column widths
+   # ------------------------------------------------------------------
+   while (<IN>) {
+      chomp;
+
+      if (/# clocks_per_sec: (\d+)/) {
+	 $clocks_per_sec = $1;
+	 next;
+      }
+      elsif (/#\s*(tag\s*:.*)$/) {
+	 my $keys = $1;
+         $keys = "tag:ticks:calls:ops:mop/s" if ($keys =~ /total ticks/);
+	 @key = split(':', $keys);
+	 foreach my $i (0 .. $#key) {
+	     $key[$i] =~ s/^\s+//;
+	     $key[$i] =~ s/\s+$//;
+	     my $len = length($key[$i]);
+	     $maxlen[$i] = $len if ($len > $maxlen[$i])
+	 }
+
+	 if ($key[1] eq "ticks") {
+	     if ($opt{conv_tick}) {
+		 $conv_tick = 1;
+		 $key[1] = "secs";
+		 $info->{1} = {fmt => '%${len}f' };
+	     }
+	     else {
+		 $info->{1} = {fmt => '%${len}d' };
+	     }
+	 }
+	 else {
+	     $info->{1} = {fmt => '%${len}f' };
+	 }
+	 next;
+      }
+
+      next if (/^\s*\#/);
+
+      s/::/NOT_A_COLON/g;
+      my @val = split(':');
+
+      $val[1] = sprintf("%f", $val[1] / $clocks_per_sec) if ($conv_tick);
+
+      foreach my $i (0 .. $#val) {
+	 $val[$i] =~ s/NOT_A_COLON/::/g;
+	 $val[$i] =~ s/^\s+//;
+	 $val[$i] =~ s/\s+$//;
+	 my $len = length($val[$i]);
+	 $maxlen[$i] = $len if ($len > $maxlen[$i])
+	 }
+   }
+
+   close(IN);
+
+
+   # ------------------------------------------------------------------
+   # Pass 2: pretty-print
+   # ------------------------------------------------------------------
+
+   open(IN, $file)           || die "Can't read '$file': $!\n";
+   open(OUT, ">> $tmp_file") || die "Can't write '$tmp_file': $!\n";
+
+   while (<IN>) {
+      chomp;
+      if (/#\s*tag\s*:/) {
+	  my @line;
+	  foreach my $i (0 .. $#key) {
+	      my $len = $maxlen[$i];
+	      $len -= 1 if ($i == 0);
+	      my $str = sprintf(" %${len}s ", $key[$i]);
+	      push @line, $str;
+	  }
+	  print OUT "#" . join(":", @line) . "\n";
+	  next;
+      }
+      print(OUT "$_\n"), next if (/^\s*\#/);
+      
+      s/::/NOT_A_COLON/g;
+      my @val = split(':');
+      $val[1] = $val[1] / $clocks_per_sec if ($conv_tick);
+      my @result;
+      foreach my $i (0 .. $#val) {
+	 $val[$i] =~ s/NOT_A_COLON/::/g;
+	 $val[$i] =~ s/^\s+//;
+	 $val[$i] =~ s/\s+$//;
+	 my $len = $maxlen[$i];
+	 my $fmt = eval('"' . $info->{$i}{fmt} . '"');
+	 my $str = sprintf(" ${fmt} ", $val[$i]);
+	 push @result, $str;
+      }
+
+      print OUT join(":", @result) . "\n";
+   }
+   close(OUT);
+   close(IN);
+   system("mv $tmp_file $file");
+}
+
+
+# --------------------------------------------------------------------- #
+my %opt;
+
+foreach my $arg (@ARGV) {
+   if ($arg eq '-sec') {
+      $opt{conv_tick} = 1;
+      next;
+      }
+   else {
+      fmt_profile($arg, %opt);
+   }
+}

Property changes on: scripts/fmt-profile.pl
___________________________________________________________________
Name: svn:executable
   + *

