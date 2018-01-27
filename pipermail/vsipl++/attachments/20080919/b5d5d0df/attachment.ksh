Index: ChangeLog
===================================================================
--- ChangeLog	(revision 222098)
+++ ChangeLog	(working copy)
@@ -1,5 +1,9 @@
 2008-09-19  Jules Bergmann  <jules@codesourcery.com>
 
+	* m4/cbe.m4: Fix typo.
+
+2008-09-19  Jules Bergmann  <jules@codesourcery.com>
+
 	Document matvec functions.
 	* doc/manual/functions.xml: Include matvec functions.
 	* doc/manual/dot.xml: New file.
Index: m4/cbe.m4
===================================================================
--- m4/cbe.m4	(revision 222098)
+++ m4/cbe.m4	(working copy)
@@ -79,9 +79,9 @@
   LIBS="-lcml -lalf -lspe2 -ldl $LIBS"
 
   if test "$with_cml_include" != ""; then
-    cml_incdir="-I$with_cml_include"
+    cml_incdir="$with_cml_include"
   elif test "$with_cml_prefix" != ""; then
-    cml_incdir="-I$with_cml_prefix/include"
+    cml_incdir="$with_cml_prefix/include"
   else
     cml_incdir=""
   fi
@@ -96,7 +96,7 @@
 
   if test -n "$cml_incdir" -o -n "$cml_libdirs"; then
     CPPFLAGS="$CPPFLAGS -I$cml_incdir"
-    CPP_SPU_FLAGS="$CPP_SPU_FLAGS $cml_incdir"
+    CPP_SPU_FLAGS="$CPP_SPU_FLAGS -I$cml_incdir"
 
     orig_LDFLAGS=$LDFLAGS
     orig_LD_SPU_FLAGS=$LD_SPU_FLAGS
