Index: configure.ac
===================================================================
--- configure.ac	(revision 146098)
+++ configure.ac	(working copy)
@@ -175,8 +175,9 @@
 		  Library), acml (AMD Core Math Library), atlas (system
 		  ATLAS/LAPACK installation), generic (system generic
 		  LAPACK installation), builtin (Sourcery VSIPL++'s
-		  builtin ATLAS/C-LAPACK), and fortran-builtin (Sourcery
-		  VSIPL++'s builtin ATLAS/Fortran-LAPACK). 
+		  builtin ATLAS/C-LAPACK), fortran-builtin (Sourcery
+		  VSIPL++'s builtin ATLAS/Fortran-LAPACK, and simple-builtin
+                  (Lapack that doesn't require atlas).). 
 		  Specifying 'no' disables search for a LAPACK library.]),,
   [with_lapack=probe])
 
@@ -1286,6 +1287,8 @@
     lapack_packages="atlas generic1 generic2 builtin"
   elif test "$with_lapack" == "generic"; then
     lapack_packages="generic1 generic2"
+  elif test "$with_lapack" == "simple-builtin"; then
+    lapack_packages="simple-builtin";
   else
     lapack_packages="$with_lapack"
   fi
@@ -1493,12 +1496,14 @@
 	  # When using Fortran LAPACK, we need ATLAS' f77blas (it
 	  # provides the Fortran BLAS bindings) and we need libg2c.
           LATE_LIBS="-llapack -lcblas -lf77blas -latlas $use_g2c $LATE_LIBS"
-          AC_SUBST(USE_FORTRAN_LAPACK, 1)
+          AC_SUBST(BUILD_REF_LAPACK, 1)  # Build lapack in vendor/lapack/SRC
         else
 	  # When using C LAPACK, we need libF77 (the builtin equivalent
 	  # of libg2c).
           LATE_LIBS="-llapack -lF77 -lcblas -latlas $LATE_LIBS"
-          AC_SUBST(USE_BUILTIN_LIBF77, 1)
+	  AC_SUBST(BUILD_REF_CLAPACK, 1)  # Build clapack in vendor/clapack/SRC
+	  AC_SUBST(BUILD_LIBF77,      1)  # clapack requires LIBF77
+          ln -s ../../clapack/F2CLIBS/libF77/libF77.a vendor/atlas/lib/libF77.a
         fi
 
 	INT_CPPFLAGS="-I$my_abs_top_srcdir/vendor/atlas/include $INT_CPPFLAGS"
@@ -1537,6 +1542,27 @@
         AC_MSG_RESULT([not present])
 	continue
       fi
+    elif test "$trypkg" == "simple-builtin"; then
+
+      curdir=`pwd`
+      # flags that are used internally
+      INT_CPPFLAGS="$INT_CPPFLAGS -I$srcdir/vendor/clapack/SRC"
+      INT_LDFLAGS="$INT_LDFLAGS -L$curdir/vendor/clapack"
+      INT_LDFLAGS="$INT_LDFLAGS -L$curdir/vendor/clapack/F2CLIBS/libF77"
+
+      # flags that are used after install
+      CPPFLAGS="$keep_CPPFLAGS -I$incdir/lapack"
+      LDFLAGS="$keep_LDFLAGS -L$libdir/lapack"
+      LATE_LIBS="$LATE_LIBS -llapack -lblas -lF77"
+
+      AC_SUBST(BUILD_REF_CLAPACK, 1)   # Build clapack in vendor/clapack/SRC
+      AC_SUBST(BUILD_REF_CLAPACK_BLAS, 1) # Build blas in vendor/clapack/blas
+      AC_SUBST(BUILD_LIBF77,      1)   # clapack requires libF77
+      AC_SUBST(USE_SIMPLE_LAPACK, 1)
+      
+      lapack_use_ilaenv=0
+      lapack_found="simple-builtin"
+      break
     fi
 
 
