Index: src/vsip/opt/cbe/alf/src/ppu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/alf/src/ppu/GNUmakefile.inc.in	(revision 171903)
+++ src/vsip/opt/cbe/alf/src/ppu/GNUmakefile.inc.in	(working copy)
@@ -19,8 +19,9 @@
 ALF_CPPFLAGS := $(ALF_INCLUDES) -include altivec.h
 ALF_CFLAGS := -mabi=altivec -maltivec $(CFLAGS)
 
-alf_src := $(wildcard $(srcdir)/src/vsip/opt/cbe/alf/src/ppu/*.c)
-alf_obj := $(patsubst $(srcdir)/%.c, %.$(OBJEXT), $(alf_src))
+alf_src  := $(wildcard $(srcdir)/src/vsip/opt/cbe/alf/src/ppu/*.c)
+alf_obj  := $(patsubst $(srcdir)/%.c, %.$(OBJEXT), $(alf_src))
+alf_deps := $(patsubst $(srcdir)/%.c, %.d, $(alf_src))
 
 c_sources += $(alf_src)
 
@@ -43,7 +44,7 @@
 # Rules
 ########################################################################
 
-%.d: %.c
+$(alf_deps): %.d: %.c
 	$(make_alf_dep)
 
 $(alf_obj): %.$(OBJEXT): %.c
Index: src/vsip/opt/simd/simd.hpp
===================================================================
--- src/vsip/opt/simd/simd.hpp	(revision 171903)
+++ src/vsip/opt/simd/simd.hpp	(working copy)
@@ -305,10 +305,10 @@
   { return vec_cmplt(v1, v2); }
 
   static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
-  { return vec_cmpge(v1, v2); }
+  { return vec_cmplt(v2, v1); }
 
   static bool_simd_type le(simd_type const& v1, simd_type const& v2)
-  { return vec_cmple(v1, v2); }
+  { return vec_cmpgt(v2, v1); }
 
   static void enter() {}
   static void exit()  {}
@@ -393,10 +393,10 @@
   { return vec_cmplt(v1, v2); }
 
   static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
-  { return vec_cmpge(v1, v2); }
+  { return vec_cmplt(v2, v1); }
 
   static bool_simd_type le(simd_type const& v1, simd_type const& v2)
-  { return vec_cmple(v1, v2); }
+  { return vec_cmpgt(v2, v1); }
 
   static pack_simd_type pack(simd_type const& v1, simd_type const& v2)
   { return vec_pack(v1, v2); }
@@ -484,10 +484,10 @@
   { return vec_cmplt(v1, v2); }
 
   static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
-  { return vec_cmpge(v1, v2); }
+  { return vec_cmplt(v2, v1); }
 
   static bool_simd_type le(simd_type const& v1, simd_type const& v2)
-  { return vec_cmple(v1, v2); }
+  { return vec_cmpgt(v2, v1); }
 
   static pack_simd_type pack(simd_type const& v1, simd_type const& v2)
   { return vec_pack(v1, v2); }
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 171903)
+++ ChangeLog	(working copy)
@@ -1,3 +1,12 @@
+2007-05-22  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/cbe/alf/src/ppu/GNUmakefile.inc.in: Guard dependency
+	  rule for ALF C files only.
+	* src/vsip/opt/simd/simd.hpp: Fix use of unavailable comparisons.
+	* GNUmakefile.in: Fix dependency generation for MCOE/GreenHills.
+	* configure.ac: Report mpi probe status.  Update generic lapack
+	  trypkg names.  Add support for Ubuntu 7.04's lapack/atlas.
+
 2007-05-17  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/opt/cbe/alf/src/ppu/GNUmakefile.inc.in: Added rule to 
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 171903)
+++ GNUmakefile.in	(working copy)
@@ -201,11 +201,15 @@
 
 else # not intel-win
 
-# (This recipe is taken from the GNU Make manual.)
+# Generate dependencies (This recipe is modified from the GNU Make manual.)
+#  - The first sed converts .o files to .$(OBJEXT).  This is a work
+#    around for MCOE/GreenHills which uses .o for dependencies but
+#    .oppc for actual files.  It is a no-op if OBJEXT == .o .
 define make_dep
 @echo generating dependencies for $(@D)/$(<F)
 $(SHELL) -ec '$(CXXDEP) $(CXXFLAGS) \
 	      $(call dir_var,$(dir $<),CXXFLAGS) $< \
+	      | sed "s|$(*F)\\.o[ :]*|$*\\.$(OBJEXT) : |g" \
 	      | sed "s|$(*F)\\.$(OBJEXT)[ :]*|$*\\.d $*\\.$(OBJEXT) : |g" > $@'
 endef
 
Index: configure.ac
===================================================================
--- configure.ac	(revision 171903)
+++ configure.ac	(working copy)
@@ -430,8 +430,7 @@
 AC_ARG_ENABLE(eval-dense-expr,
   AS_HELP_STRING([--enable-eval-dense-expr],
                  [Activate evaluation of dense matrix and tensor expressions
-		  as vector expressions when possible.  Experimental
-		  feature, enabled by default]),
+		  as vector expressions when possible.  Enabled by default]),
   [case x"$enableval" in
     xyes) eval_dense_expr=1 ;;
     xno)  eval_dense_expr=0 ;;
@@ -633,12 +632,12 @@
 
 if test "$enable_exceptions" = "probe"; then
   if test "$has_exceptions" = "1"; then
-    exception_status="probe -- found"
+    status_exceptions="probe -- found"
   else
-    exception_status="probe -- not found"
+    status_exceptions="probe -- not found"
   fi
 else
-  exception_status=$enable_exceptions
+  status_exceptions=$enable_exceptions
 fi
 
 AC_DEFINE_UNQUOTED(VSIP_HAS_EXCEPTIONS, $has_exceptions,
@@ -1438,8 +1437,18 @@
     [Define to parallel service provided (0 == no service, 1 = MPI, 2 = PAS).])
 fi
 
+if test "$enable_mpi" = "probe"; then
+  if test "$PAR_SERVICE" = "none"; then
+    status_mpi="probe -- not found"
+  else
+    status_mpi="probe -- found"
+  fi
+else
+  status_mpi=$enable_mpi
+fi
 
 
+
 # These values are not used if PAS is not enabled (i.e. if PAR_SERVICE != 2).
 # They are always defined for binary packaging convenience.  This allows
 # the same acconfig.hpp to be used with/without PAS.
@@ -1976,12 +1985,12 @@
     echo "HOST: $host  BUILD: $build"
     if test "$host" != "$build"; then
       # Can't cross-compile builtin atlas
-      lapack_packages="atlas generic1 generic2 simple-builtin"
+      lapack_packages="atlas generic_wo_blas generic_with_blas generic_v3_wo_blas generic_v3_with_blas simple-builtin"
     else
-      lapack_packages="atlas generic1 generic2 builtin"
+      lapack_packages="atlas generic_wo_blas generic_with_blas generic_v3_wo_blas generic_v3_with_blas builtin"
     fi
   elif test "$with_lapack" == "generic"; then
-    lapack_packages="generic1 generic2"
+    lapack_packages="generic_wo_blas generic_with_blas generic_v3_wo_blas generic_v3_with_blas"
   elif test "$with_lapack" == "simple-builtin"; then
     lapack_packages="simple-builtin";
   else
@@ -2055,7 +2064,7 @@
 
       lapack_use_ilaenv=0
     elif test "$trypkg" == "atlas"; then
-      AC_MSG_CHECKING([for LAPACK/ATLAS library (w/CBLAS])
+      AC_MSG_CHECKING([for LAPACK/ATLAS library ($trypkg w/CBLAS)])
 
       if test "$with_atlas_libdir" != ""; then
 	atlas_libdir=" -L$with_atlas_libdir"
@@ -2104,16 +2113,32 @@
       fi
 
       lapack_use_ilaenv=0
-    elif test "$trypkg" == "generic1"; then
+
+    elif test "$trypkg" == "generic_wo_blas"; then
       AC_MSG_CHECKING([for LAPACK/Generic library (w/o blas)])
       LIBS="$keep_LIBS -llapack"
       cblas_style="0"	# no cblas.h
       lapack_use_ilaenv=0
-    elif test "$trypkg" == "generic2"; then
+    elif test "$trypkg" == "generic_with_blas"; then
       AC_MSG_CHECKING([for LAPACK/Generic library (w/blas)])
       LIBS="$keep_LIBS -llapack -lblas"
       cblas_style="0"	# no cblas.h
       lapack_use_ilaenv=0
+
+    elif test "$trypkg" == "generic_v3_wo_blas"; then
+      AC_MSG_CHECKING([for LAPACK/Generic v3 library (w/o blas)])
+      LIBS="$keep_LIBS -llapack-3"
+      cblas_style="0"	# no cblas.h
+      lapack_use_ilaenv=0
+
+    elif test "$trypkg" == "generic_v3_with_blas"; then
+      # This configuration is found on ubuntu 7.04 (Zelda)
+
+      AC_MSG_CHECKING([for LAPACK/Generic v3 library (w/blas)])
+      LIBS="$keep_LIBS -llapack-3 -lblas-3"
+      cblas_style="0"	# no cblas.h
+      lapack_use_ilaenv=0
+
     elif test "$trypkg" == "builtin" -o "$trypkg" == "fortran-builtin"; then
 
       if test "$trypkg" == "fortran-builtin"; then
@@ -2297,6 +2322,8 @@
       lapack_use_ilaenv=0
       lapack_found="simple-builtin"
       break
+    else
+      AC_MSG_ERROR([Unknown lapack trypkg: $trypkg])
     fi
 
 
@@ -2662,8 +2689,8 @@
 AC_MSG_NOTICE(Summary)
 AC_MSG_RESULT([Build in maintainer-mode:                $maintainer_mode])
 AC_MSG_RESULT([Using config suffix:                     $suffix])
-AC_MSG_RESULT([Exceptions enabled:                      $exception_status])
-AC_MSG_RESULT([With mpi enabled:                        $enable_mpi])
+AC_MSG_RESULT([Exceptions enabled:                      $status_exceptions])
+AC_MSG_RESULT([With mpi enabled:                        $status_mpi])
 AC_MSG_RESULT([With PAS enabled:                        $enable_pas])
 if test "$PAR_SERVICE" != "none"; then
   AC_MSG_RESULT([With parallel service:                   $PAR_SERVICE])
