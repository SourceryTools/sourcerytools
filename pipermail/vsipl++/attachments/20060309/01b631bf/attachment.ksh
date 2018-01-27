Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.408
diff -u -r1.408 ChangeLog
--- ChangeLog	8 Mar 2006 16:22:34 -0000	1.408
+++ ChangeLog	9 Mar 2006 05:44:06 -0000
@@ -1,3 +1,7 @@
+2006-03-09  Stefan Seefeld  <stefan@codesourcery.com>
+
+	* configure.ac: Fix MPI config logic.
+
 2006-03-08  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* doc/GNUmakefile.inc.in: Copy images into the html tutorial
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.86
diff -u -r1.86 configure.ac
--- configure.ac	8 Mar 2006 01:14:05 -0000	1.86
+++ configure.ac	9 Mar 2006 05:44:07 -0000
@@ -72,11 +72,10 @@
 # If the user specifies that MPI should not be used (with --disable-mpi),
 # then we do not search for it and configure a serial VSIPL++ library.
 
-enable_mpi=probe
 AC_ARG_ENABLE([mpi],
   AS_HELP_STRING([--disable-mpi],
                  [don't use MPI (default is to use it if found)]),,
-  [enable_mpi=no])
+  [enable_mpi=probe])
 
 AC_ARG_WITH(mpi_prefix,
   AS_HELP_STRING([--with-mpi-prefix=PATH],
@@ -1673,7 +1672,7 @@
 AC_MSG_RESULT([Exceptions enabled:                      $enable_exceptions])
 AC_MSG_RESULT([With mpi enabled:                        $enable_mpi])
 if test "$enable_mpi" != "no"; then
-  AC_MSG_RESULT([With parallel servicetation:             $PAR_SERVICE])
+  AC_MSG_RESULT([With parallel service:                   $PAR_SERVICE])
 fi
 AC_MSG_RESULT([With SAL:                                $enable_sal])
 AC_MSG_RESULT([With IPP:                                $enable_ipp])
