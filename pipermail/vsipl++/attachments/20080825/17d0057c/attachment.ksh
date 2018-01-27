Index: m4/cbe.m4
===================================================================
--- m4/cbe.m4	(revision 218695)
+++ m4/cbe.m4	(working copy)
@@ -64,11 +64,47 @@
     fi
   fi
 
+  LIBS="-lcml -lalf -lspe2 -ldl $LIBS"
+
   if test "$with_cml_prefix" != ""; then
-    CPPFLAGS="$CPPFLAGS -I$with_cml_prefix/include"
-    LDFLAGS="$LDFLAGS -L$with_cml_prefix/lib"
-    CPP_SPU_FLAGS="$CPP_SPU_FLAGS -I$with_cml_prefix/include"
-    LD_SPU_FLAGS="$LD_SPU_FLAGS -L$with_cml_prefix/lib"
+    orig_CPPFLAGS=$CPPFLAGS
+    orig_LDFLAGS=$LDFLAGS
+    orig_CPU_SPU_FLAGS=$CPP_SPU_FLAGS
+    orig_LD_SPU_FLAGS=$LD_SPU_FLAGS
+
+    libdirs="lib lib64"
+    cml_libdir_found=no
+
+    for trylibdir in $libdirs; do
+      AC_MSG_CHECKING([for CML libdir: $with_cml_prefix/$trylibdir])
+
+      CPPFLAGS="$orig_CPPFLAGS -I$with_cml_prefix/include"
+      LDFLAGS="$orig_LDFLAGS -L$with_cml_prefix/$trylibdir"
+      CPP_SPU_FLAGS="$orig_CPP_SPU_FLAGS -I$with_cml_prefix/include"
+      LD_SPU_FLAGS="$orig_LD_SPU_FLAGS -L$with_cml_prefix/$trylibdir"
+
+      AC_LINK_IFELSE(
+        [AC_LANG_PROGRAM(
+	  [[#include <cml/ppu/cml.h>]],
+	  [[cml_init(); cml_fini();]]
+          )],
+        [cml_libdir_found=$trylibdir
+         AC_MSG_RESULT([found])
+         break],
+        [AC_MSG_RESULT([not found]) ])
+
+    done
+
+    if test "$cml_libdir_found" = "no"; then
+      AC_MSG_ERROR([Cannot find CML libdir])
+    fi
+
+    # ALF_LIBRARY_PATH (ALF 3.0) only supports a single path.
+    # Create link to CML kernels from VSIPL++ directory.
+    # This allows in-tree development.  It will not be copied
+    # on installation.
+    mkdir -p lib
+    ln -sf $with_cml_prefix/$cml_libdir_found/cml_kernels.so lib
   fi
 
   if test "$neutral_acconfig" = 'y'; then
@@ -79,8 +115,6 @@
           [Cell SDK version.])
   fi
 
-  LIBS="-lcml -lalf -lspe2 -ldl $LIBS"
-
   AC_SUBST(CPP_SPU_FLAGS, $CPP_SPU_FLAGS)
   AC_SUBST(LD_SPU_FLAGS, $LD_SPU_FLAGS)
 else
Index: m4/fft.m4
===================================================================
--- m4/fft.m4	(revision 218695)
+++ m4/fft.m4	(working copy)
@@ -343,9 +343,6 @@
 
 fi
 
-echo "fftw_has_float: $fftw_has_float"
-echo "fftw_has_double: $fftw_has_double"
-echo "fftw_has_long_double: $fftw_has_long_double"
 if test "x$provide_fft_float" = "x"
 then provide_fft_float=$fftw_has_float
 fi
