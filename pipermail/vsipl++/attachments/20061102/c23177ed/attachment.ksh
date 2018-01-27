Index: ChangeLog
===================================================================
--- ChangeLog	(revision 153720)
+++ ChangeLog	(working copy)
@@ -1,5 +1,15 @@
 2006-11-01  Jules Bergmann  <jules@codesourcery.com>
 
+	Support nested event names for profile accumulate mode.
+	* configure.ac (--diable-profile-accum-nest-events): New option,
+	  disables nested event names.
+	* src/vsip/opt/profile.cpp: Create nested event names for accum
+	  mode when VSIP_IMPL_PROFILE_ACCUM_NEST_EVENTS set.
+	* src/vsip/opt/profile.hpp: Add stack for nested event names.
+	* scripts/fmt-profile.pl: Support nested event names.
+	
+2006-11-01  Jules Bergmann  <jules@codesourcery.com>
+
 	* scripts/fmt-profile.pl: New file, script for formatting profiler
 	  output.
 	
Index: configure.ac
===================================================================
--- configure.ac	(revision 153680)
+++ configure.ac	(working copy)
@@ -323,6 +323,11 @@
   ,
   [with_alignment=probe])
 
+AC_ARG_ENABLE([profile_accum_nest_events],
+  AS_HELP_STRING([--disable-profile-accum-nest-events],
+                 [Disable nesting of events for profile accumulate mode
+                  (enabled by default)]),,
+  [enable_profile_accum_nest_events=yes])
 
 AC_ARG_ENABLE([timer],
   AS_HELP_STRING([--enable-timer=type],
@@ -2016,6 +2021,16 @@
                    [Alignment for allocated memory (in bytes)])
 
 #
+# Configure profile mode
+#
+if test "$enable_profile_accum_nest_events" = "yes"; then
+  AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILE_ACCUM_NEST_EVENTS, 1,
+                     [Define to nest events in profile accum mode.])
+fi 
+
+
+
+#
 # Configure profile timer
 #
 if test "$enable_timer" == "none" \
Index: src/vsip/opt/profile.cpp
===================================================================
--- src/vsip/opt/profile.cpp	(revision 153680)
+++ src/vsip/opt/profile.cpp	(working copy)
@@ -132,6 +132,19 @@
 }
 
 
+// Create a profiler event.
+//
+// Requires
+//   NAME to be the event name.
+//   VALUE to be a value associated with the event (such as number of
+//      operations, number of bytes, etc).
+//   OPEN_ID to be event's start ID if this is the close of an event.
+//      This should be 0 if this is the start of the event.
+//   STAMP
+//
+// Returns:
+//   The ID of the event.
+//
 int
 Profiler::event(const char* name, int value, int open_id, stamp_type stamp)
 {
@@ -147,16 +160,35 @@
   }
   else if (mode_ == pm_accum)
   {
+#if VSIP_IMPL_PROFILE_ACCUM_NEST_EVENTS
+    // Push event onto stack if this is start of event.
+    if (open_id == 0)
+      event_stack_.push_back(std::string(name));
+
+    // Build nested event name from stack.
+    std::string event_name(event_stack_[0]);
+    for (int i=1; i<event_stack_.size(); ++i)
+    {
+      event_name += std::string("\\,");
+      event_name += event_stack_[i];
+    }
+
+    // Pop event from stack if this is end of event.
+    if (open_id != 0)
+      event_stack_.pop_back();
+#else
+    std::string event_name(name);
+#endif
     // Obtain a stamp if one is not provided.
     if (TP::is_zero(stamp))
       TP::sample(stamp);
 
-    accum_type::iterator pos = accum_.find(name);
+    accum_type::iterator pos = accum_.find(event_name);
     if (pos == accum_.end())
     {
-      accum_.insert(std::make_pair(std::string(name), 
+      accum_.insert(std::make_pair(event_name, 
                       Accum_entry(TP::zero(), 0, value)));
-      pos = accum_.find(name);
+      pos = accum_.find(event_name);
     }
 
     // The value of 'open_id' determines if it is entering scope or exiting 
Index: src/vsip/opt/profile.hpp
===================================================================
--- src/vsip/opt/profile.hpp	(revision 153680)
+++ src/vsip/opt/profile.hpp	(working copy)
@@ -397,6 +397,11 @@
   int                        count_;
   trace_type                 data_;
   accum_type                 accum_;
+
+#if VSIP_IMPL_PROFILE_ACCUM_NEST_EVENTS
+  typedef std::vector<std::string> event_stack_type;
+  event_stack_type           event_stack_;
+#endif
 };
 
 
Index: scripts/fmt-profile.pl
===================================================================
--- scripts/fmt-profile.pl	(revision 153720)
+++ scripts/fmt-profile.pl	(working copy)
@@ -15,17 +15,19 @@
 
 use strict;
 
+use vars qw($indent); $indent = 2;
+
 # --------------------------------------------------------------------- #
 # get_info -- get format info
 # --------------------------------------------------------------------- #
 sub get_info {
     my $info = {};
 
-    $info->{0} = {fmt => '%-${len}s' };
-    $info->{1} = {fmt => '%${len}d' };
-    $info->{2} = {fmt => '%${len}d' };
-    $info->{3} = {fmt => '%${len}d' };
-    $info->{4} = {fmt => '%${len}f' };
+    $info->{0} = {fmt => '%-${len}s ', maxlen => 0 };
+    $info->{1} = {fmt => '%${len}d',  maxlen => 0 };
+    $info->{2} = {fmt => '%${len}d',  maxlen => 0 };
+    $info->{3} = {fmt => '%${len}d',  maxlen => 0 };
+    $info->{4} = {fmt => '%${len}f',  maxlen => 0 };
 
     return $info;
 }
@@ -43,12 +45,14 @@
    open(IN, $file)           || die "Can't read '$file': $!\n";
 
    my @key;
-   my @maxlen;
    my $clocks_per_sec = 1;
    my $conv_tick = 0;
 
    my $info = get_info();
 
+   my @hdr;
+   my $data = { sub => {} };
+
    # ------------------------------------------------------------------
    # Pass 1: determine column widths
    # ------------------------------------------------------------------
@@ -57,6 +61,7 @@
 
       if (/# clocks_per_sec: (\d+)/) {
 	 $clocks_per_sec = $1;
+	 push @hdr, $_;
 	 next;
       }
       elsif (/#\s*(tag\s*:.*)$/) {
@@ -66,8 +71,11 @@
 	 foreach my $i (0 .. $#key) {
 	     $key[$i] =~ s/^\s+//;
 	     $key[$i] =~ s/\s+$//;
-	     my $len = length($key[$i]);
-	     $maxlen[$i] = $len if ($len > $maxlen[$i])
+	     my $fmt = "%s";
+	     $fmt = ($i == 0) ? "$fmt " : " $fmt ";
+	     my $str = sprintf("$fmt", $key[$i]);
+	     my $len = length($str);
+	     $info->{$i}{maxlen} = $len if ($len > $info->{$i}{maxlen})
 	 }
 
 	 if ($key[1] eq "ticks") {
@@ -86,20 +94,42 @@
 	 next;
       }
 
-      next if (/^\s*\#/);
+      push(@hdr, $_), next if (/^\s*\#/);
 
       s/::/NOT_A_COLON/g;
       my @val = split(':');
 
-      $val[1] = sprintf("%f", $val[1] / $clocks_per_sec) if ($conv_tick);
-
       foreach my $i (0 .. $#val) {
 	 $val[$i] =~ s/NOT_A_COLON/::/g;
 	 $val[$i] =~ s/^\s+//;
 	 $val[$i] =~ s/\s+$//;
-	 my $len = length($val[$i]);
-	 $maxlen[$i] = $len if ($len > $maxlen[$i])
+     }
+
+      my @path = split(/\\,/, $val[0]);
+      my $depth = scalar(@path) * 2;
+      $val[0] = (" " x $depth) . $path[$#path];
+
+      $val[1] = sprintf("%f", $val[1] / $clocks_per_sec) if ($conv_tick);
+
+      foreach my $i (0 .. $#val) {
+	 my $len = ""; # $info->{$i}{maxlen};
+	 my $fmt = eval('"' . $info->{$i}{fmt} . '"');
+	 $fmt = ($i == 0) ? "$fmt " : " $fmt ";
+	 my $str = sprintf("$fmt", $val[$i]);
+
+	 $len = length($str);
+	 $info->{$i}{maxlen} = $len if ($len > $info->{$i}{maxlen})
 	 }
+
+      my $x = $data;
+      foreach my $k (@path) {
+	  if (!defined $x->{sub}{$k}) {
+	      $x->{sub}{$k} = { name => $k, sub => {}, entry => [] };
+	  }
+	  $x = $x->{sub}{$k};
+      }
+
+      $x->{entry} = \@val;
    }
 
    close(IN);
@@ -109,47 +139,63 @@
    # Pass 2: pretty-print
    # ------------------------------------------------------------------
 
-   open(IN, $file)           || die "Can't read '$file': $!\n";
-   open(OUT, ">> $tmp_file") || die "Can't write '$tmp_file': $!\n";
+   open(OUT, "> $tmp_file") || die "Can't write '$tmp_file': $!\n";
 
-   while (<IN>) {
-      chomp;
-      if (/#\s*tag\s*:/) {
-	  my @line;
-	  foreach my $i (0 .. $#key) {
-	      my $len = $maxlen[$i];
-	      $len -= 1 if ($i == 0);
-	      my $str = sprintf(" %${len}s ", $key[$i]);
-	      push @line, $str;
-	  }
-	  print OUT "#" . join(":", @line) . "\n";
-	  next;
-      }
-      print(OUT "$_\n"), next if (/^\s*\#/);
-      
-      s/::/NOT_A_COLON/g;
-      my @val = split(':');
-      $val[1] = $val[1] / $clocks_per_sec if ($conv_tick);
-      my @result;
-      foreach my $i (0 .. $#val) {
-	 $val[$i] =~ s/NOT_A_COLON/::/g;
-	 $val[$i] =~ s/^\s+//;
-	 $val[$i] =~ s/\s+$//;
-	 my $len = $maxlen[$i];
-	 my $fmt = eval('"' . $info->{$i}{fmt} . '"');
-	 my $str = sprintf(" ${fmt} ", $val[$i]);
-	 push @result, $str;
-      }
+   # header
+   foreach my $line (@hdr) {
+       print OUT "$line\n";
+   }
 
-      print OUT join(":", @result) . "\n";
+   # column keys
+   my @line;
+   foreach my $i (0 .. $#key) {
+       my $len = $info->{$i}{maxlen};
+       my $fmt = "%${len}s";
+       $fmt = ($i == 0) ? "$fmt " : " $fmt ";
+       my $str = sprintf("$fmt", $key[$i]);
+       push @line, $str;
    }
+   print OUT "#" . join(":", @line) . "\n";
+
+   # Entries
+   dump_tree($info, $data, 0);
+
    close(OUT);
-   close(IN);
    system("mv $tmp_file $file");
 }
 
 
+
 # --------------------------------------------------------------------- #
+# dump_tree -- dump accum tree
+# --------------------------------------------------------------------- #
+sub dump_tree {
+    my ($info, $data, $depth) = @_;
+
+    if (defined $data->{entry}) {
+	my @entry = @{$data->{entry}};
+	$entry[0] = (' ' x $depth) . $data->{name};
+	my @result;
+	foreach my $i (0 .. $#entry) {
+	    my $len = $info->{$i}{maxlen};
+	    my $fmt = eval('"' . $info->{$i}{fmt} . '"');
+	    $fmt = ($i == 0) ? "$fmt " : " $fmt ";
+	    my $str = sprintf("$fmt", $entry[$i]);
+	    push @result, $str;
+	}
+	print OUT join(":", @result) . "\n";
+    }
+
+    foreach my $k (sort { $data->{sub}{$b}{entry}[1] <=>
+			  $data->{sub}{$a}{entry}[1] }
+		   keys %{$data->{sub}}) {
+	dump_tree($info, $data->{sub}{$k}, $depth + $indent);
+    }
+}
+
+
+
+# --------------------------------------------------------------------- #
 my %opt;
 
 foreach my $arg (@ARGV) {
