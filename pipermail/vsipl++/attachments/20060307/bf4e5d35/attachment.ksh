Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.406
diff -u -r1.406 ChangeLog
--- ChangeLog	7 Mar 2006 20:09:35 -0000	1.406
+++ ChangeLog	8 Mar 2006 01:10:10 -0000
@@ -1,5 +1,9 @@
 2006-03-07  Jules Bergmann  <jules@codesourcery.com>
 
+	* configure.ac: Probe for MPI by default.
+
+2006-03-07  Jules Bergmann  <jules@codesourcery.com>
+
 	* benchmarks/corr.cpp: Remove unused function/classes.  Add
 	  mem_per_points() function.
 	* benchmarks/dot.cpp: Add mem_per_points() function.
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.85
diff -u -r1.85 configure.ac
--- configure.ac	7 Mar 2006 02:14:07 -0000	1.85
+++ configure.ac	8 Mar 2006 01:10:10 -0000
@@ -61,10 +61,23 @@
   AS_HELP_STRING([--disable-exceptions],
                  [don't use C++ exceptions]),,
   [enable_exceptions=yes])
+
+# By default we will probe for MPI and use it if it exists.  If it
+# does not exist, we will configure a serial VSIPL++ library.
+#
+# If the user specifies that MPI should be used (either by an explicit
+# --enable-mpi or by specifying the prefix to MPI), then we search for
+# MPI and issue an error if it does not exist.
+#
+# If the user specifies that MPI should not be used (with --disable-mpi),
+# then we do not search for it and configure a serial VSIPL++ library.
+
+enable_mpi=probe
 AC_ARG_ENABLE([mpi],
   AS_HELP_STRING([--disable-mpi],
                  [don't use MPI (default is to use it if found)]),,
   [enable_mpi=no])
+
 AC_ARG_WITH(mpi_prefix,
   AS_HELP_STRING([--with-mpi-prefix=PATH],
                  [Specify the installation prefix of the MPI library.  Headers
