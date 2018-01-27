Index: ChangeLog
===================================================================
--- ChangeLog	(revision 154746)
+++ ChangeLog	(working copy)
@@ -1,5 +1,15 @@
 2006-11-14  Jules Bergmann  <jules@codesourcery.com>
 
+	* scripts/fmt-profile.pl: Add new options to set output file,
+	  sum nested operations, and show extra time.
+	* src/vsip/core/fft.hpp: Pass axis A to fft::Description.
+	* src/vsip/opt/ops_info.hpp: Use axis A to determine if Fftm is by
+	  row or by col.
+	* src/vsip/opt/expr/serial_evaluator.hpp: Distinguish between copy
+	  and transpose in Expr_trans.
+	
+2006-11-14  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/ipp/bindings.hpp: Add dispatch for mag.
 	* src/vsip/opt/ipp/bindings.cpp: Add bindings for mag and magsq
 	  (magsq is real only).
Index: scripts/fmt-profile.pl
===================================================================
--- scripts/fmt-profile.pl	(revision 154623)
+++ scripts/fmt-profile.pl	(working copy)
@@ -7,10 +7,18 @@
 # date:   2006-11-01							#
 #									#
 # Usage:								#
-#   fmt-profile.pl [-sec] <profile.txt>					#
+#   fmt-profile.pl [-sec] [-sum] [-extra <event>] [-o <out.txt>]	#
+#                  <profile.txt>					#
 #									#
 # Options:								#
-#   -sec -- convert ticks into seconds					#
+#   -sec	-- convert ticks into seconds				#
+#   -sec	-- sum nested operations for events with 0 ops		#
+#   -extra <event>							#
+#		-- create pseudo event for unaccounted-for time		#
+#		   in nested events under <event>			#
+#   -o <out.txt>							#
+#		-- write output to <out.txt> (instead of overwriting	#
+#		   <profile.txt).					#
 #########################################################################
 
 use strict;
@@ -157,16 +165,76 @@
    }
    print OUT "#" . join(":", @line) . "\n";
 
+   sum_tree($data) if ($opt{sum});
+   find_extra_time($data, $opt{extra});
+
    # Entries
    dump_tree($info, $data, 0);
 
    close(OUT);
-   system("mv $tmp_file $file");
+
+   my $outfile = $opt{o} || $file;
+   print "OUTFILE: $outfile\n";
+   system("mv $tmp_file $outfile");
 }
 
 
 
 # --------------------------------------------------------------------- #
+# sum_tree -- sum accum tree
+# --------------------------------------------------------------------- #
+sub sum_tree {
+    my ($data) = @_;
+
+    my $sum_ops  = 0;
+    foreach my $k (keys %{$data->{sub}}) {
+	sum_tree($data->{sub}{$k});
+	$sum_ops += $data->{sub}{$k}{entry}[3];
+    }
+
+    if ($data->{entry}[3] == 0) {
+	$data->{entry}[3] = $sum_ops;
+	if ($data->{entry}[1] != 0) {
+	    $data->{entry}[4] = $sum_ops / (1e6 * $data->{entry}[1]);
+	}
+	else {
+	    $data->{entry}[4] = 0;
+	}
+    }
+}
+
+
+
+# --------------------------------------------------------------------- #
+# find_extra_time -- Find extra time in tree nodes
+#
+# Args:
+#  data		- tree
+#  nodes	- nodes to find extra time in
+# --------------------------------------------------------------------- #
+sub find_extra_time {
+    my ($data, $nodes) = @_;
+
+    my $sum_time  = 0;
+    foreach my $k (keys %{$data->{sub}}) {
+	find_extra_time($data->{sub}{$k}, $nodes);
+	$sum_time += $data->{sub}{$k}{entry}[1];
+    }
+
+    # printf "check: $data->{entry}[0]\n";
+    printf "check: $data->{name}\n";
+    if (defined $nodes->{$data->{name}}) {
+	$data->{sub}{extra} = { name => "*extra-time*",
+				sub  => {},
+				entry => ["*extra-time*",
+					  $data->{entry}[1] - $sum_time,
+					  0, 0, 0] };
+    }
+}
+
+
+
+# --------------------------------------------------------------------- #
 # dump_tree -- dump accum tree
 # --------------------------------------------------------------------- #
 sub dump_tree {
@@ -197,13 +265,42 @@
 
 # --------------------------------------------------------------------- #
 my %opt;
+my @files;
+$opt{extra} = {};
 
-foreach my $arg (@ARGV) {
+while (@ARGV) {
+   my $arg = shift @ARGV;
+
    if ($arg eq '-sec') {
       $opt{conv_tick} = 1;
       next;
       }
+   elsif ($arg eq '-sum') {
+      $opt{sum} = 1;
+      next;
+      }
+   elsif ($arg eq '-extra') {
+      $opt{extra}{shift @ARGV} = 1;
+      next;
+      }
+   elsif ($arg eq '-o') {
+      $opt{o} = shift @ARGV;
+      next;
+      }
    else {
-      fmt_profile($arg, %opt);
+       push @files, $arg;
    }
 }
+
+if ($opt{o}) {
+    if (scalar(@files) > 1) {
+	die "Too many files specified with -o option.";
+    }
+    fmt_profile($files[0], %opt);
+}
+else {
+    foreach my $file (@files) {
+	fmt_profile($file, %opt);
+    }
+}
+	
Index: src/vsip/core/fft.hpp
===================================================================
--- src/vsip/core/fft.hpp	(revision 154746)
+++ src/vsip/core/fft.hpp	(working copy)
@@ -90,7 +90,7 @@
     : input_size_(io_size<D, I, O, A>::size(dom)),
       output_size_(io_size<D, O, I, A>::size(dom)),
       scale_(scale), 
-      event_( fft::Description<D, I, O>::tag(name, dom, dir, rm),
+      event_( fft::Description<D, I, O>::tag(name, dom, dir, rm, A),
         fft::Op_count<I, O>::value(io_size<D, O, I, A>::size(dom).size()) )
   {}
 
Index: src/vsip/opt/ops_info.hpp
===================================================================
--- src/vsip/opt/ops_info.hpp	(revision 154746)
+++ src/vsip/opt/ops_info.hpp	(working copy)
@@ -75,10 +75,11 @@
 struct Description
 { 
   static std::string tag(const char* op, Domain<D> const &dom, int dir, 
-    return_mechanism_type rm)
+    return_mechanism_type rm, dimension_type axis)
   {
     std::ostringstream   st;
     st << op << " "
+       << (!strcmp(op, "Fftm") ? (axis == 1 ? "row " : "col ") : "")
        << (dir == -1 ? "Inv " : "Fwd ")
        << Desc_datatype<I>::value() << "-"
        << Desc_datatype<O>::value() << " "
Index: src/vsip/opt/expr/serial_evaluator.hpp
===================================================================
--- src/vsip/opt/expr/serial_evaluator.hpp	(revision 154746)
+++ src/vsip/opt/expr/serial_evaluator.hpp	(working copy)
@@ -135,7 +135,15 @@
 	  typename SrcBlock>
 struct Serial_expr_evaluator<2, DstBlock, SrcBlock, Transpose_tag>
 {
-  static char const* name() { return "Expr_Trans"; }
+  static char const* name()
+  {
+    char s = Type_equal<src_order_type, row2_type>::value ? 'r' : 'c';
+    char d = Type_equal<dst_order_type, row2_type>::value ? 'r' : 'c';
+    if      (s == 'r' && d == 'r') return "Expr_Trans (rr copy)";
+    else if (s == 'r' && d == 'c') return "Expr_Trans (rc trans)";
+    else if (s == 'c' && d == 'r') return "Expr_Trans (cr trans)";
+    else if (s == 'c' && d == 'c') return "Expr_Trans (cc copy)";
+  }
 
   typedef typename DstBlock::value_type dst_value_type;
   typedef typename SrcBlock::value_type src_value_type;
@@ -145,14 +153,9 @@
   static bool const is_rhs_simple =
     Is_simple_distributed_block<SrcBlock>::value;
 
-  static bool const is_lhs_split  =
-    Type_equal<typename Block_layout<DstBlock>::complex_type,
-	       Cmplx_split_fmt>::value;
+  static bool const is_lhs_split  = Is_split_block<DstBlock>::value;
+  static bool const is_rhs_split  = Is_split_block<SrcBlock>::value;
 
-  static bool const is_rhs_split  =
-    Type_equal<typename Block_layout<SrcBlock>::complex_type,
-	       Cmplx_split_fmt>::value;
-
   static int const  lhs_cost      = Ext_data_cost<DstBlock>::value;
   static int const  rhs_cost      = Ext_data_cost<SrcBlock>::value;
 
