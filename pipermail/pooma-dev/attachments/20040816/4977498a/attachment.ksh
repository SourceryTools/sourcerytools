--- configure	Thu Jan 29 11:49:41 2004
+++ ../../pooma-mpi3/r2/configure	Mon Aug 16 17:37:12 2004
@@ -497,6 +497,8 @@
 $cppopt_app = "";
 $cppdbg_lib = "";
 $cppdbg_app = "";
+$overridecpp = 0;
+$forcedcpp = "";
 
 ### the name and arguments for the C compiler
 $c = "";
@@ -839,7 +842,9 @@
   # reset names of compilers and applications, if necessary
   if (scalar @{$arghash{$cppnm}} > 1)
     {
+      $overridecpp = 1;
       $cpp = $arghash{$cppnm}[1];
+      $forcedcpp = $cpp;
       # if no link cmd is specified, use $cpp
       if (scalar @{$arghash{$linknm}} <= 1)
         {
@@ -1333,34 +1325,40 @@
     }
   elsif ($mpi)
     {
-      my $mpiCC = "\$(MPICH_ROOT)/bin/mpiCC";
-      if (system("test -x $MPICH_ROOT/bin/mpiCC") == 0)
+      my $mpiCC = "";
+      my $mpicc = "";
+      my $mpichroot = $ENV{"MPICH_ROOT"};
+      if (system("test -x $mpichroot/bin/mpiCC") == 0)
         {
-          $mpiCC = "\$(MPICH_ROOT)/bin/mpiCC";
+          $mpiCC = "$mpichroot/bin/mpiCC";
+          $mpicc = "$mpichroot/bin/mpicc";
         }
-      elsif (system("test -x $MPICH_ROOT/bin/mpic++") == 0)
+      elsif (system("test -x $mpichroot/bin/mpic++") == 0)
         {
-          $mpiCC = "\$(MPICH_ROOT)/bin/mpic++";
+          $mpiCC = "$mpichroot/bin/mpic++";
+          $mpicc = "$mpichroot/bin/mpicc";
         }
       elsif (system("which mpiCC") == 0)
         {
           $mpiCC = "mpiCC";
+          $mpicc = "mpicc";
         }
       elsif (system("which mpic++") == 0)
         {
           $mpiCC = "mpic++";
+          $mpicc = "mpicc";
         }
       else
         {
           die "There is no known MPI location.  Select one by setting MPICH_ROOT or adjusting your PATH.\n";
         }
 
-      $defmpi = 1;
-      $scheduler = "serialAsync";
-
       # use special compiler script for MPI.
       $cpp  = $mpiCC;
       $link = $mpiCC;
+
+      $defmpi = 1;
+      $scheduler = "serialAsync";
     }
   add_yesno_define("POOMA_MESSAGING", $defmessaging);
   add_yesno_define("POOMA_CHEETAH", $defcheetah);
@@ -2004,6 +1995,13 @@
 
   # write out the necessary suite file settings
   print FSUITE "### names of applications\n";
+  if ($overridecpp && $mpi)
+    {
+	print FSUITE "export LAMHCP       = $forcedcpp\n";
+	print FSUITE "export LAMHCC       = $forcedcpp\n";
+	print FSUITE "export MPICH_CCC    = $forcedcpp\n";
+	print FSUITE "export MPICH_CCLINKER = $forcedcpp\n";
+    }
   print FSUITE "CXX                 = $cpp\n";
   print FSUITE "CC                  = $c\n";
   print FSUITE "F77                 = $f77\n";
@@ -2360,6 +2340,13 @@
 
   # write out the necessary suite file settings
   print MFILE "### names of applications\n";
+  if ($overridecpp && $mpi)
+    {
+	print MFILE "export LAMHCP       = $forcedcpp\n";
+	print MFILE "export LAMHCC       = $forcedcpp\n";
+	print MFILE "export MPICH_CCC    = $forcedcpp\n";
+	print MFILE "export MPICH_CCLINKER = $forcedcpp\n";
+    }
   print MFILE "POOMA_CXX                 = $cpp\n";
   print MFILE "POOMA_CC                  = $c\n";
   print MFILE "POOMA_F77                 = $f77\n";
@@ -2398,7 +2385,12 @@
   unlink("config.cache");
 
   # run configure
-  system("env CC=$c CFLAGS=\"$cargs\" CXX=$cpp CXXFLAGS=\"$cppargs\" ../../scripts/configure") == 0
+  my $extrampiargs = "";
+  if ($overridecpp && $mpi)
+    {
+      $extrampiargs = "LAMHCP=$forcedcpp LAMHCC=$forcedcpp MPICH_CCC=$forcedcpp MPICH_CCLINKER=$forcedcpp";
+    }
+  system("env CC=$c CFLAGS=\"$cargs\" CXX=$cpp CXXFLAGS=\"$cppargs\" $extrampiargs ../../scripts/configure") == 0
     or die "Autoconf configuration failed: $?\n";
 
   # move generated files to their place
