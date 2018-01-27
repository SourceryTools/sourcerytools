Index: ChangeLog
===================================================================
--- ChangeLog	(revision 236550)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2009-02-13  Jules Bergmann  <jules@codesourcery.com>
 
+	* m4/parallel.m4: Only define VSIP_IMPL_HAVE_MPI when we actually
+	  have MPI.
+
+2009-02-13  Jules Bergmann  <jules@codesourcery.com>
+
 	* doc/getting-started/getting-started.xml: Fix description for 
 	  building a program manually.
 
Index: m4/parallel.m4
===================================================================
--- m4/parallel.m4	(revision 236492)
+++ m4/parallel.m4	(working copy)
@@ -322,16 +322,6 @@
   # Second step: Test the found compiler flags and set output variables.
   ############################################################################
 
-  # Right now we are unaware of any platform using <mpi/mpi.h>, thus
-  # vsipl_mpi_h_type is unconditionally set to 1.
-  vsipl_mpi_h_type=1
-  if test "$neutral_acconfig" = 'y'
-  then CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_MPI_H_TYPE=$vsipl_mpi_h_type"
-  else
-    AC_DEFINE_UNQUOTED([VSIP_IMPL_MPI_H_TYPE], $vsipl_mpi_h_type,
-      [The name of the header to include for the MPI interface, with <> quotes.])
-  fi
-
   # Find the applet names to boot / halt the parallel service.
   case "$PAR_SERVICE" in
     lam)
@@ -350,8 +340,24 @@
   then vsipl_par_service=0
   elif test "$PAR_SERVICE" = "pas"
   then vsipl_par_service=2
-  else vsipl_par_service=1
+  else
+    # must be MPI
+    vsipl_par_service=1
+
+    # Set other MPI specific flags:
+
+    # Right now we are unaware of any platform using <mpi/mpi.h>, thus
+    # vsipl_mpi_h_type is unconditionally set to 1.
+    vsipl_mpi_h_type=1
+    if test "$neutral_acconfig" = 'y'
+    then CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_MPI_H_TYPE=$vsipl_mpi_h_type"
+    else
+      AC_DEFINE_UNQUOTED([VSIP_IMPL_MPI_H_TYPE], $vsipl_mpi_h_type,
+        [The name of the header to include for the MPI interface, with <> quotes.])
+    fi
+    AC_SUBST(VSIP_IMPL_HAVE_MPI, 1)
   fi
+
   if test "$neutral_acconfig" = 'y'
   then CPPFLAGS="$CPPFLAGS -DVSIP_IMPL_PAR_SERVICE=$vsipl_par_service"
   else
@@ -362,7 +368,6 @@
   CPPFLAGS="$CPPFLAGS $MPI_CPPFLAGS"
   LIBS="$LIBS $MPI_LIBS"
   AC_SUBST(PAR_SERVICE)
-  AC_SUBST(VSIP_IMPL_HAVE_MPI, 1)
 
   if test -n "$vsip_impl_avoid_posix_memalign"
   then if test "$neutral_acconfig" = 'y'
