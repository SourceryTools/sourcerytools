Index: vendor/GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/vendor/GNUmakefile.inc.in,v
retrieving revision 1.14
diff -u -r1.14 GNUmakefile.inc.in
--- vendor/GNUmakefile.inc.in	28 Apr 2006 21:25:28 -0000	1.14
+++ vendor/GNUmakefile.inc.in	11 May 2006 02:53:47 -0000
@@ -25,8 +25,10 @@
 vendor_PRE_LAPACK = vendor/atlas/lib/libprelapack.a
 vendor_USE_LAPACK = vendor/atlas/lib/liblapack.a
 ifdef USE_FORTRAN_LAPACK
+  vendor_F77BLAS    = vendor/atlas/lib/libf77blas.a
   vendor_REF_LAPACK = $(vendor_FLAPACK)
 else
+  vendor_F77BLAS    = 
   vendor_REF_LAPACK = $(vendor_CLAPACK)
 endif
 
@@ -36,13 +38,12 @@
 vendor_ATLAS_LIBS :=				\
 	vendor/atlas/lib/libatlas.a		\
 	vendor/atlas/lib/libcblas.a		\
-	vendor/atlas/lib/libf77blas.a	\
+	$(vendor_F77BLAS)			\
 	$(vendor_PRE_LAPACK)
 
 vendor_LIBS :=					\
 	vendor/atlas/lib/libatlas.a		\
 	vendor/atlas/lib/libcblas.a		\
-	vendor/atlas/lib/libf77blas.a	\
 	$(vendor_USE_LAPACK)
 
 
@@ -51,9 +52,9 @@
 ########################################################################
 
 ifdef USE_BUILTIN_ATLAS
-all:: $(vendor_LIBS)
+all:: $(vendor_F77BLAS) $(vendor_LIBS)
 
-libs += $(vendor_LIBS)
+libs += $(vendor_F77BLAS) $(vendor_LIBS)
 
 $(vendor_ATLAS_LIBS):
 	@echo "Building ATLAS (see atlas.build.log)"
@@ -111,14 +112,17 @@
 install:: $(vendor_LIBS)
 	@echo "Installing ATLAS (see atlas.install.log)"
 	# @$(MAKE) -C vendor/atlas installinstall > atlas.install.log 2>&1
-	$(INSTALL) -d $(DESTDIR)$(libdir)/atlas
 	$(INSTALL_DATA) vendor/atlas/lib/libatlas.a   $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) vendor/atlas/lib/libcblas.a   $(DESTDIR)$(libdir)
-	$(INSTALL_DATA) vendor/atlas/lib/libf77blas.a $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) vendor/atlas/lib/liblapack.a  $(DESTDIR)$(libdir)
-	$(INSTALL) -d $(DESTDIR)$(includedir)/atlas
 	$(INSTALL_DATA) $(srcdir)/vendor/atlas/include/cblas.h $(DESTDIR)$(includedir)
-endif
+
+ifdef USE_FORTRAN_LAPACK
+install:: $(vendor_F77BLAS)
+	$(INSTALL_DATA) vendor/atlas/lib/libf77blas.a $(DESTDIR)$(libdir)
+endif # USE_FORTRAN_LAPACK
+
+endif # USE_BUILTIN_ATLAS
 
 
 
Index: vendor/atlas/Make.ARCH.in
===================================================================
RCS file: /home/cvs/Repository/atlas/Make.ARCH.in,v
retrieving revision 1.2
diff -u -r1.2 Make.ARCH.in
--- vendor/atlas/Make.ARCH.in	27 Apr 2006 01:23:33 -0000	1.2
+++ vendor/atlas/Make.ARCH.in	11 May 2006 02:53:47 -0000
@@ -99,6 +99,8 @@
    NM = -o
    OJ = -c
 
+   BUILD_FORTRAN_LIBS = @BUILD_FORTRAN_LIBS@
+
    F77         = @F77@
    F77FLAGS    = @FFLAGS@
    FLINKER     = @FLINKER@
Index: vendor/atlas/configure.ac
===================================================================
RCS file: /home/cvs/Repository/atlas/configure.ac,v
retrieving revision 1.4
diff -u -r1.4 configure.ac
--- vendor/atlas/configure.ac	27 Apr 2006 01:23:33 -0000	1.4
+++ vendor/atlas/configure.ac	11 May 2006 02:53:47 -0000
@@ -47,6 +47,11 @@
                  [Specify prefix for libraries. (default is none).]),,
   [with_libprefix=""])
 
+AC_ARG_ENABLE([fortran],
+  AS_HELP_STRING([--disable-fortran],
+                 [don't build Fortan wrappers]),,
+  [enable_fortran=yes])
+
 mach=$with_mach
 
 # disable 3Dnow
@@ -85,7 +90,10 @@
 # Find the compilers.
 # --------------------------------------------------------------------
 AC_PROG_CC
-AC_PROG_F77
+if test "$enable_fortran" = "yes"; then
+  AC_PROG_F77
+  AC_SUBST(BUILD_FORTRAN_LIBS, 1)
+fi
 AC_LANG(C)
 
 #
@@ -200,6 +208,8 @@
       mach="HAMMER64"
     elif test "`echo $model | sed -n '/Athlon(tm) 64/p'`" != ""; then
       mach="HAMMER64"
+    elif test "`echo $model | sed -n '/Opteron/p'`" != ""; then
+      mach="HAMMER64"
     fi
   fi
  elif test "$os_name" = "SunOS"; then
@@ -291,7 +301,7 @@
   for try_cfg in $altivec_cfgs; do
     if test "$try_cfg" = "altivec1"; then
       # gcc
-      CFLAGS="$CFLAGS -maltivec -mabi=altivec"
+      CFLAGS="$CFLAGS -maltivec -mabi=altivec -DATL_AVgcc"
     elif test "$try_cfg" = "altivec2"; then
       # OSX
       CFLAGS="$CFLAGS -faltivec"
@@ -347,6 +357,8 @@
 fi
 
 # --------------------------------------------------------------------
+# Probe for SSE3
+# --------------------------------------------------------------------
 if test "$with_isa" = "probe"; then
   AC_MSG_CHECKING([for SSE3])
 
@@ -417,6 +429,8 @@
 fi
 
 # --------------------------------------------------------------------
+# Probe for SSE2
+# --------------------------------------------------------------------
 if test "$with_isa" = "probe"; then
   AC_MSG_CHECKING([for SSE2])
 
@@ -496,6 +510,8 @@
 
 
 # --------------------------------------------------------------------
+# Probe for SSE1
+# --------------------------------------------------------------------
 if test "$with_isa" = "probe"; then
   AC_MSG_CHECKING([for SSE1])
 
@@ -575,6 +591,8 @@
 fi
 
 # --------------------------------------------------------------------
+# Probe for 3DNow2
+# --------------------------------------------------------------------
 if test "$with_isa" = "probe"; then
   if test "$disable_3dnow" != "yes"; then
   AC_MSG_CHECKING([for 3DNow2])
@@ -663,6 +681,8 @@
 
 
 # --------------------------------------------------------------------
+# Probe for 3DNow1
+# --------------------------------------------------------------------
 if test "$with_isa" = "probe"; then
   if test "$disable_3dnow" != "yes"; then
   AC_MSG_CHECKING([for 3DNow1])
@@ -753,6 +773,16 @@
 fi
 
 
+# --------------------------------------------------------------------
+# Downgrade ISA, if necessary
+# --------------------------------------------------------------------
+if test "$mach" = "HAMMER64"; then
+  if test "$with_isa" = "SSE3"; then
+    with_isa="SSE2"
+  fi
+fi
+
+
 
 # --------------------------------------------------------------------
 # GetUserMM
@@ -813,6 +843,7 @@
 if test $with_isa != "none"; then
   ARCH0="$ARCH0$with_isa"
 fi
+
 ARCH0="$ARCH0$usermm_name"
 
 if test $os_name = "Other"; then
@@ -1032,16 +1063,18 @@
 # Determine Fortran naming strategy
 # --------------------------------------------------------------------
 
-AC_F77_FUNC(C_ROUTINE, [MANGLE])
+if test "$enable_fortran" = "yes"; then
+  AC_F77_FUNC(C_ROUTINE, [MANGLE])
 
-if test "$MANGLE" = "c_routine_"; then
-  f2c_namedef="-DAdd_"
-elif test "$MANGLE" = "c_routine__"; then
-  f2c_namedef="-DAdd__"
-elif test "$MANGLE" = "c_routine"; then
-  f2c_namedef="-DNoChange"
-elif test "$MANGLE" = "C_ROUTINE"; then
-  f2c_namedef="-DUpCase"
+  if test "$MANGLE" = "c_routine_"; then
+    f2c_namedef="-DAdd_"
+  elif test "$MANGLE" = "c_routine__"; then
+    f2c_namedef="-DAdd__"
+  elif test "$MANGLE" = "c_routine"; then
+    f2c_namedef="-DNoChange"
+  elif test "$MANGLE" = "C_ROUTINE"; then
+    f2c_namedef="-DUpCase"
+  fi
 fi
 
 
@@ -1050,17 +1083,18 @@
 # Determine C type corresponding to Fortran integer
 # --------------------------------------------------------------------
 
-if test "$with_int_type" = "probe"; then
-  AC_MSG_CHECKING([for C type corresponding to Fortran integer])
-  with_int_type="none"
-
-  AC_LANG_SAVE()
-  AC_LANG([C])
-  old_CPPFLAGS="$CPPFLAGS"
-  CPPFLAGS="$CPPFLAGS $f2c_namedef"
-  AC_COMPILE_IFELSE([
-      AC_LANG_SOURCE([
-      ])
+if test "$enable_fortran" = "yes"; then
+  if test "$with_int_type" = "probe"; then
+    AC_MSG_CHECKING([for C type corresponding to Fortran integer])
+    with_int_type="none"
+
+    AC_LANG_SAVE()
+    AC_LANG([C])
+    old_CPPFLAGS="$CPPFLAGS"
+    CPPFLAGS="$CPPFLAGS $f2c_namedef"
+    AC_COMPILE_IFELSE([
+        AC_LANG_SOURCE([
+        ])
 #include <stdio.h>
 #if defined(Add_) || defined(Add__)
    #define c2fint c2fint_
@@ -1107,18 +1141,19 @@
          CALL C2FINT(IARR)
          STOP
          END
-       ])
-       LDFLAGS="$old_LDFLAGS"
-       with_int_type=`cat conftestval`
-       rm -f conftestval
-      ])
-  CPPFLAGS="$old_CPPFLAGS"
-  AC_LANG_RESTORE()
-
-  if test "$with_int_type" = "none"; then
-    AC_MSG_ERROR([cannot determine C type for FORTRAN INTEGER.])
-  else
-    AC_MSG_RESULT([$with_int_type.])
+         ])
+         LDFLAGS="$old_LDFLAGS"
+         with_int_type=`cat conftestval`
+         rm -f conftestval
+        ])
+    CPPFLAGS="$old_CPPFLAGS"
+    AC_LANG_RESTORE()
+
+    if test "$with_int_type" = "none"; then
+      AC_MSG_ERROR([cannot determine C type for FORTRAN INTEGER.])
+    else
+      AC_MSG_RESULT([$with_int_type.])
+    fi
   fi
 fi
 
@@ -1128,19 +1163,20 @@
 # Determine Fortran string calling convention
 # --------------------------------------------------------------------
 
-if test "$with_string_convention" = "probe"; then
-  AC_MSG_CHECKING([for Fortran string calling convention.])
-  string_conventions="-DSunStyle -DCrayStyle -DStringStructVal -DStringStructPtr"
-
-  use_conv="none"
-  AC_LANG_SAVE()
-  old_CPPFLAGS="$CPPFLAGS"
-  for try_conv in $string_conventions; do
-    AC_LANG([C])
-    CPPFLAGS="$old_CPPFLAGS $f2c_namedef $try_conv -DF77_INTEGER=$with_int_type"
-    res="no"
-    AC_COMPILE_IFELSE([
-        AC_LANG_SOURCE([[
+if test "$enable_fortran" = "yes"; then
+  if test "$with_string_convention" = "probe"; then
+    AC_MSG_CHECKING([for Fortran string calling convention.])
+    string_conventions="-DSunStyle -DCrayStyle -DStringStructVal -DStringStructPtr"
+
+    use_conv="none"
+    AC_LANG_SAVE()
+    old_CPPFLAGS="$CPPFLAGS"
+    for try_conv in $string_conventions; do
+      AC_LANG([C])
+      CPPFLAGS="$old_CPPFLAGS $f2c_namedef $try_conv -DF77_INTEGER=$with_int_type"
+      res="no"
+      AC_COMPILE_IFELSE([
+          AC_LANG_SOURCE([[
 #include <stdio.h>
 #if defined(Add_) || defined(Add__)
    #define crout crout_
@@ -1222,51 +1258,54 @@
    fclose(f);
 }
 #endif
-        ]])
-      ],[
-        AC_LANG([Fortran 77])
-        old_LDFLAGS="$LDFLAGS"
-        LDFLAGS="conftest.$ac_objext $LDFLAGS"
-        AC_TRY_RUN([
-        PROGRAM CHARTST
-        EXTERNAL CROUT
-        CALL CROUT('123', -1, '12345', -2)
-        STOP
-        END
-       ])
-       LDFLAGS="$old_LDFLAGS"
-       res=`cat conftestval`
-       rm -f conftestval
-      ])
-    if test "$res" = "yes"; then
-      use_conv="$try_conv"
-      break
+          ]])
+        ],[
+          AC_LANG([Fortran 77])
+          old_LDFLAGS="$LDFLAGS"
+          LDFLAGS="conftest.$ac_objext $LDFLAGS"
+          AC_TRY_RUN([
+          PROGRAM CHARTST
+          EXTERNAL CROUT
+          CALL CROUT('123', -1, '12345', -2)
+          STOP
+          END
+         ])
+         LDFLAGS="$old_LDFLAGS"
+         res=`cat conftestval`
+         rm -f conftestval
+        ])
+      if test "$res" = "yes"; then
+        use_conv="$try_conv"
+        break
+      fi
+    done
+    CPPFLAGS="$old_CPPFLAGS"
+    AC_LANG_RESTORE()
+
+    if test "$use_conv" = "none"; then
+      AC_MSG_ERROR([unknown FORTRAN string convention.])
+    else
+      AC_MSG_RESULT([using $use_conv.])
     fi
-  done
-  CPPFLAGS="$old_CPPFLAGS"
-  AC_LANG_RESTORE()
+  elif test "$with_string_convention" = "sun"; then
+    use_conv="-DSunStyle"
+  elif test "$with_string_convention" = "cray"; then
+    use_conv="-DCrayStyle"
+  elif test "$with_string_convention" = "structval"; then
+    use_conv="-DStringStructVal"
+  elif test "$with_string_convention" = "structptr"; then
+    use_conv="-DStringStructPtr"
+  fi
+fi  
 
-  if test "$use_conv" = "none"; then
-    AC_MSG_ERROR([unknown FORTRAN string convention.])
+if test "$enable_fortran" = "yes"; then
+  if test "$with_int_type" = "int"; then
+    # If F77_INTEGER == int, leave it undefined here so that it will be
+    # defined by atlas_f77.h ... otherwise FunkyInts will get defined too.
+    F2CDEFS="$f2c_namedef $use_conv"
   else
-    AC_MSG_RESULT([using $use_conv.])
+    F2CDEFS="$f2c_namedef -DF77_INTEGER=$with_int_type $use_conv"
   fi
-elif test "$with_string_convention" = "sun"; then
-  use_conv="-DSunStyle"
-elif test "$with_string_convention" = "cray"; then
-  use_conv="-DCrayStyle"
-elif test "$with_string_convention" = "structval"; then
-  use_conv="-DStringStructVal"
-elif test "$with_string_convention" = "structptr"; then
-  use_conv="-DStringStructPtr"
-fi
-
-if test "$with_int_type" = "int"; then
-  # If F77_INTEGER == int, leave it undefined here so that it will be
-  # defined by atlas_f77.h ... otherwise FunkyInts will get defined too.
-  F2CDEFS="$f2c_namedef $use_conv"
-else
-  F2CDEFS="$f2c_namedef -DF77_INTEGER=$with_int_type $use_conv"
 fi
 LIBdir='$(TOPdir)/lib'
 
Index: vendor/atlas/makes/Make.bin
===================================================================
RCS file: /home/cvs/Repository/atlas/makes/Make.bin,v
retrieving revision 1.2
diff -u -r1.2 Make.bin
--- vendor/atlas/makes/Make.bin	1 Dec 2005 14:43:18 -0000	1.2
+++ vendor/atlas/makes/Make.bin	11 May 2006 02:53:47 -0000
@@ -43,7 +43,7 @@
 	cd $(TOPdir)/interfaces/blas/C/src/$(ARCH) ; $(MAKE) ptlib
 	- cd $(TOPdir)/interfaces/blas/F77/src/$(ARCH) ; $(MAKE) ptlib
 
-IBuildLibs:
+IBuildLibsCore:
 	cd $(TOPdir)/src/auxil/$(ARCH) ; $(MAKE) lib
 	cd $(TOPdir)/src/blas/gemm/$(ARCH) ; $(MAKE) lib
 	cd $(TOPdir)/src/blas/gemv/$(ARCH) ; $(MAKE) lib
@@ -55,9 +55,17 @@
 	cd $(TOPdir)/src/blas/reference/level3/$(ARCH) ; $(MAKE) lib
 	cd $(TOPdir)/src/lapack/$(ARCH) ; $(MAKE) lib
 	cd $(TOPdir)/interfaces/blas/C/src/$(ARCH) ; $(MAKE) all
-	- cd $(TOPdir)/interfaces/blas/F77/src/$(ARCH) ; $(MAKE) lib
 	cd $(TOPdir)/interfaces/lapack/C/src/$(ARCH) ; $(MAKE) lib
-	- cd $(TOPdir)/interfaces/lapack/F77/src/$(ARCH) ; $(MAKE) lib
+
+ifdef BUILD_FORTRAN_LIBS
+IBuildLibsF77:
+	cd $(TOPdir)/interfaces/blas/F77/src/$(ARCH) ; $(MAKE) lib
+	cd $(TOPdir)/interfaces/lapack/F77/src/$(ARCH) ; $(MAKE) lib
+else
+IBuildLibsF77:
+endif
+
+IBuildLibs: IBuildLibsCore IBuildLibsF77
 
 IPostTune:
 	cd $(L3Tdir) ; $(MAKE) res/atlas_trsmNB.h
