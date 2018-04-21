Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 221949)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -103,8 +103,10 @@
 	$(INSTALL) -d $(DESTDIR)$(libdir)
 	$(INSTALL_PROGRAM) lib/svpp_kernels.so \
           $(DESTDIR)$(libdir)/svpp_kernels.so
-	$(INSTALL_PROGRAM) lib/cml_kernels.so \
-          $(DESTDIR)$(libdir)/cml_kernels.so
+	if test ! -e $(DESTDIR)$(libdir)/cml_kernels.so; then \
+          $(INSTALL_PROGRAM) lib/cml_kernels.so \
+            $(DESTDIR)$(libdir)/cml_kernels.so \
+        fi
 
 $(spe_kernels): $(src_vsip_opt_cbe_spu_obj)
 	$(link_spu_kernel_dso)
