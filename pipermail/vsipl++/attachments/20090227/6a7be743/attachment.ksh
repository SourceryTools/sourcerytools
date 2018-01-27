Index: configure.ac
===================================================================
--- configure.ac	(revision 236492)
+++ configure.ac	(working copy)
@@ -364,6 +364,23 @@
   AC_SUBST(enable_cvsip_bindings, 1)
 fi
 
+AC_ARG_ENABLE(shared-lib,
+  AS_HELP_STRING([--enable-shared-lib],
+                 [Build VSIPL++ as a shared library.]),
+  [case x"$enableval" in
+    xyes) BUILD_SHARED_LIB=1 ;;
+    xno)  BUILD_SHARED_LIB= ;;
+    *)   AC_MSG_ERROR([Invalid argument to --enable-shared-lib.])
+   esac],
+  [BUILD_SHARED_LIB=]) 
+
+AC_SUBST(BUILD_SHARED_LIB)
+
+if test "x$BUILD_SHARED_LIB" != "x"; then
+  CXXFLAGS="-fPIC $CXXFLAGS"
+  CFLAGS="-fPIC $CFLAGS"
+fi
+
 #
 # Files to generate.
 #
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 236492)
+++ GNUmakefile.in	(working copy)
@@ -88,8 +88,6 @@
 AR := @AR@
 # The path to the C compiler.
 CC := @CC@
-# C compilation flags.
-CFLAGS := @CFLAGS@
 # C preprocessor flags.
 CPPFLAGS := @CPPFLAGS@
 # The path to the C compiler.
@@ -136,6 +134,8 @@
 PYTHON_EXT := @PYTHON_EXT@
 # The QMTest command to use for testing.
 QMTEST := @QMTEST@
+# Are we building a shared library (1: yes, undef: no)?
+BUILD_SHARED_LIB := @BUILD_SHARED_LIB@
 
 ### Third-party package availability ###
 
@@ -217,6 +217,7 @@
 xilib /nologo /out:$@ $^ || rm -f $@
 endef
 
+# Used for linking a shared object for python (see scripting/GNUmakefile.inc)
 define link_dso
 @echo linking $@
 $(CXX) /nologo /LD -o $@ $^ \
@@ -225,6 +226,26 @@
     $(call dir_var,$(dir $<),LIBS) $(LIBS)))
 endef
 
+# Used for linking a shared libsvpp.so and libvsip_csl.so libraries.
+define link_lib_dso
+@echo linking $@
+$(CXX) /nologo /LD -o $@ $^ \
+  $(subst -L,/libpath:, $(call dir_var,$(dir $<),LDFLAGS))) \
+  $(patsubst -l%,lib%.lib, $(subst -L,/libpath:, \
+    $(call dir_var,$(dir $<),LIBS) ))
+endef
+
+debuglib:
+	echo LIBS: $LIBS
+
+define link_benchmark
+@echo linking $@
+xilink /nologo /out:$@ $< benchmarks/main.$(OBJEXT) /libpath:lib libsvpp.lib \
+  $(subst -L,/libpath:, $(call dir_var,$(dir $<),LDFLAGS)) \
+  $(patsubst -l%,lib%.lib, \
+    $(subst -L,/libpath:, $(call dir_var,$(dir $<),LIBS) $(LIBS)))
+endef
+
 define link_app
 @echo linking $@
 xilink /nologo /out:$@ $^ /libpath:lib libsvpp.lib \
@@ -286,6 +307,7 @@
 $(AR) rc $@ $^ || rm -f $@
 endef
 
+# Used for linking a shared object for python (see scripting/GNUmakefile.inc)
 define link_dso
 @echo linking $@
 $(LDSHARED) $(LDFLAGS) $(call dir_var,$(dir $<),LDFLAGS) -o $@ $^ \
@@ -293,16 +315,34 @@
   strip --strip-unneeded $@
 endef
 
+# Used for linking a shared libsvpp.so and libvsip_csl.so libraries.
+define link_lib_dso
+@echo linking $@
+$(LDSHARED) $(LDFLAGS) $(call dir_var,$(dir $<),LDFLAGS) -o $@ $^ \
+  $(call dir_var,$(dir $<),LIBS)
+  strip --strip-unneeded $@
+endef
+
+# Used for building benchmarks.  By manually giving '-Llib -lsvpp'
+# arguments to $(CXX) instead of using $^, this macro avoids creating
+# a shared library reference to "lib/libsvpp.so."
+define link_benchmark
+@echo linking $@
+$(CXX) $(LDFLAGS) $(call dir_var,$(dir $<),LDFLAGS) -o $@ $< \
+  benchmarks/main.$(OBJEXT) -Llib -lsvpp \
+  $(call dir_var,$(dir $<),LIBS) $(LIBS)
+endef
+
 define link_app
 @echo linking $@
 $(CXX) $(LDFLAGS) $(call dir_var,$(dir $<),LDFLAGS) -o $@ $^ \
-  -Llib -lsvpp $(call dir_var,$(dir $<),LIBS) $(LIBS)
+  $(call dir_var,$(dir $<),LIBS) $(LIBS)
 endef
 
 define link_csl_app
 @echo linking $@
 $(CXX) $(LDFLAGS) $(call dir_var,$(dir $<),LDFLAGS) -o $@ $^ \
-  -Llib -lvsip_csl -lsvpp $(call dir_var,$(dir $<),LIBS) $(LIBS)
+  $(call dir_var,$(dir $<),LIBS) $(LIBS)
 endef
 
 define link_cvsip_app
@@ -404,8 +444,6 @@
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
-             $(wildcard $(srcdir)/src/vsip/opt/cuda/*.hpp))
-hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/diag/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/expr/*.hpp))
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 236492)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -1,4 +1,4 @@
-########################################################################
+######################################################### -*-Makefile-*-
 #
 # File:   GNUmakefile.inc
 # Author: Mark Mitchell 
@@ -82,6 +82,13 @@
 
 libs += lib/libsvpp.$(LIBEXT)
 
+ifdef BUILD_SHARED_LIB
+libs += lib/libsvpp.so
+lib_svpp := lib/libsvpp.so
+else
+lib_svpp := lib/libsvpp.$(LIBEXT)
+endif
+
 ########################################################################
 # Rules
 ########################################################################
@@ -94,6 +101,16 @@
 	$(INSTALL_DATA) lib/libsvpp.$(LIBEXT) \
           $(DESTDIR)$(libdir)/libsvpp$(suffix).$(LIBEXT)
 
+ifdef BUILD_SHARED_LIB
+lib/libsvpp.so: $(src_vsip_cxx_objects)
+	$(link_lib_dso)
+
+install-core:: lib/libsvpp.$(LIBEXT)
+	$(INSTALL) -d $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) lib/libsvpp.$(LIBEXT) \
+          $(DESTDIR)$(libdir)/libsvpp$(suffix).$(LIBEXT)
+endif
+
 # Install the SV++ header files.  When building with
 # separate $objdir, acconfig.hpp will be generated in the $objdir, so it
 # must be copied explicitly.  By copying it last, we override any
Index: src/vsip_csl/GNUmakefile.inc.in
===================================================================
--- src/vsip_csl/GNUmakefile.inc.in	(revision 236492)
+++ src/vsip_csl/GNUmakefile.inc.in	(working copy)
@@ -33,6 +33,10 @@
 
 libs += lib/libvsip_csl.$(LIBEXT)
 
+ifdef BUILD_SHARED_LIB
+libs += lib/libvsip_csl.so
+endif
+
 ########################################################################
 # Rules
 ########################################################################
@@ -46,6 +50,16 @@
 	$(INSTALL_DATA) lib/libvsip_csl.$(LIBEXT) \
           $(DESTDIR)$(libdir)/libvsip_csl$(suffix).$(LIBEXT)
 
+ifdef BUILD_SHARED_LIB
+lib/libvsip_csl.so: $(src_vsip_csl_cxx_objects)
+	$(link_lib_dso)
+
+install-core:: lib/libvsip_csl.so
+	$(INSTALL) -d $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) lib/libvsip_csl.$(LIBEXT) \
+          $(DESTDIR)$(libdir)/libvsip_csl$(suffix).so
+endif
+
 install-svxx:: install-core
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip_csl
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip_csl/img
Index: benchmarks/GNUmakefile.inc.in
===================================================================
--- benchmarks/GNUmakefile.inc.in	(revision 236492)
+++ benchmarks/GNUmakefile.inc.in	(working copy)
@@ -110,8 +110,8 @@
 	  $(INSTALL) $$binfile $(DESTDIR)$(benchmarks_exec_prefix)/`dirname $$binfile`; \
 	done
 
-$(benchmarks_targets): %$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
-	$(link_app)
+$(benchmarks_targets): %$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(lib_svpp)
+	$(link_benchmark)
 
 $(benchmarks_static_targets): %.static$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
 	$(CXX) -static $(LDFLAGS) -o $@ $^ -Llib -lsvpp $(LIBS) || rm -f $@
Index: doc/getting-started/getting-started.xml
===================================================================
--- doc/getting-started/getting-started.xml	(revision 237124)
+++ doc/getting-started/getting-started.xml	(working copy)
@@ -1398,6 +1398,17 @@
       </listitem>
      </varlistentry>
 
+     <varlistentry>
+      <term><option>--enable-shared-lib</option></term>
+      <listitem>
+       <para>
+        Build shared libraries as well as static libraries.  This
+        requires that position independent code be generated,
+        which may reduce performance.
+       </para>
+      </listitem>
+     </varlistentry>
+
     </variablelist>
    </para>
 
