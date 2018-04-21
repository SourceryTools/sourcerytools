Index: m4/lapack.m4
===================================================================
--- m4/lapack.m4	(revision 206238)
+++ m4/lapack.m4	(working copy)
@@ -664,7 +664,18 @@
         AC_SUBST(BUILD_REF_CLAPACK_BLAS, 1) # Build blas in vendor/clapack/blas
         AC_SUBST(BUILD_LIBF77,      1)   # clapack requires libF77
         AC_SUBST(USE_SIMPLE_LAPACK, 1)
-      
+
+        # Determine flags for CLAPACK_NOOPT, used for compiling with no
+        # optimization
+         if expr "$CFLAGS" : ".*-m32" > /dev/null; then
+          CLAPACK_NOOPT="-m32"
+         elif expr "$CFLAGS" : ".*-m64" > /dev/null; then
+          CLAPACK_NOOPT="-m64"
+        else
+          CLAPACK_NOOPT=""
+        fi
+        AC_SUBST(CLAPACK_NOOPT)
+ 
         lapack_use_ilaenv=0
         lapack_found="simple-builtin"
         break
Index: vendor/clapack/blas/SRC/f2c.h
===================================================================
--- vendor/clapack/blas/SRC/f2c.h	(revision 206238)
+++ vendor/clapack/blas/SRC/f2c.h	(working copy)
@@ -7,7 +7,10 @@
 #ifndef F2C_INCLUDE
 #define F2C_INCLUDE
 
-typedef long int integer;
+// Use 'int' to represent a FORTRAN integer, since the standard
+// requires it to have the same storage space as a single
+// precision float.
+typedef int integer;
 typedef unsigned long uinteger;
 typedef char *address;
 typedef short int shortint;
