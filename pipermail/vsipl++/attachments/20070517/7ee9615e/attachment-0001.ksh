Index: src/vsip/opt/cbe/alf/src/ppu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/alf/src/ppu/GNUmakefile.inc.in	(revision 171302)
+++ src/vsip/opt/cbe/alf/src/ppu/GNUmakefile.inc.in	(working copy)
@@ -33,9 +33,18 @@
 $(CC) -c $(ALF_CPPFLAGS) $(ALF_CFLAGS) -o $@ $<
 endef
 
+define make_alf_dep
+@echo generating ALF dependencies for $(@D)/$(<F)
+$(SHELL) -ec '$(CXXDEP) $(ALF_CPPFLAGS) $(ALF_CFLAGS) $< \
+	      | sed "s|$(*F)\\.$(OBJEXT)[ :]*|$*\\.d $*\\.$(OBJEXT) : |g" > $@'
+endef
+
 ########################################################################
 # Rules
 ########################################################################
 
+%.d: %.c
+	$(make_alf_dep)
+
 $(alf_obj): %.$(OBJEXT): %.c
 	$(compile_alf)
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 171302)
+++ GNUmakefile.in	(working copy)
@@ -417,15 +417,9 @@
 # that dependencies are preserved.
 %.d: %.cpp
 	@touch $@
-
-%.d: %.c
-	@touch $@
 else
 %.d: %.cpp
 	$(make_dep)
-
-%.d: %.c
-	$(make_dep)
 endif
 
 ########################################################################
