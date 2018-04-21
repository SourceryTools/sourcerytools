Index: vendor/clapack/F2CLIBS/libF77/f2c.h
===================================================================
--- vendor/clapack/F2CLIBS/libF77/f2c.h	(revision 206238)
+++ vendor/clapack/F2CLIBS/libF77/f2c.h	(working copy)
@@ -7,10 +7,9 @@
 #ifndef F2C_INCLUDE
 #define F2C_INCLUDE
 
-// We don't want integer to be 64 bits!!
-// integer was originally defined as long int, this causes some problems
-// on 64bit machines because a long int is 64 bits. The FORTRAN 'integer' was
-// originally 32 bits
+// Use 'int' to represent a FORTRAN integer, since the standard
+// requires it to have the same storage space as a single
+// precision float.
 typedef int integer;
 typedef unsigned long uinteger;
 typedef char *address;
Index: vendor/clapack/F2CLIBS/libF77/ChangeLog.csl
===================================================================
--- vendor/clapack/F2CLIBS/libF77/ChangeLog.csl	(revision 206238)
+++ vendor/clapack/F2CLIBS/libF77/ChangeLog.csl	(working copy)
@@ -1,3 +1,8 @@
+2008-05-01  Don McCoy  <don@codesourcery.com>
+
+	* f2c.h: Fix comment above definition of 'integer' to be consistent 
+	  with the other two copies of f2c.h in the clapack source tree.
+
 2007-04-22  Jules Bergmann  <jules@codesourcery.com>
 
 	* GNUmakefile.in: Use $OBJEXT.  Use $AR.  Update default .c.o rule.
Index: vendor/clapack/SRC/f2c.h
===================================================================
--- vendor/clapack/SRC/f2c.h	(revision 206238)
+++ vendor/clapack/SRC/f2c.h	(working copy)
@@ -7,10 +7,9 @@
 #ifndef F2C_INCLUDE
 #define F2C_INCLUDE
 
-// We don't want integer to be 64 bits!!
-// integer was originally defined as long int, this causes some problems
-// on 64bit machines because a long int is 64 bits. The FORTRAN 'integer' was
-// originally 32 bits
+// Use 'int' to represent a FORTRAN integer, since the standard
+// requires it to have the same storage space as a single
+// precision float.
 typedef int integer;
 typedef unsigned long uinteger;
 typedef char *address;
Index: vendor/clapack/SRC/ChangeLog.csl
===================================================================
--- vendor/clapack/SRC/ChangeLog.csl	(revision 206238)
+++ vendor/clapack/SRC/ChangeLog.csl	(working copy)
@@ -1,3 +1,8 @@
+2008-05-01  Don McCoy  <don@codesourcery.com>
+
+	* f2c.h: Fix comment above definition of 'integer' to be consistent 
+	  with the other two copies of f2c.h in the clapack source tree.
+
 2007-04-22  Jules Bergmann  <jules@codesourcery.com>
 
 	* GNUmakefile.in: Use $OBJEXT.  Update default .c.o rule.  Don't
