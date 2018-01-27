Index: m4/cbe.m4
===================================================================
--- m4/cbe.m4	(revision 214423)
+++ m4/cbe.m4	(working copy)
@@ -69,6 +69,13 @@
     LDFLAGS="$LDFLAGS -L$with_cml_prefix/lib"
     CPP_SPU_FLAGS="$CPP_SPU_FLAGS -I$with_cml_prefix/include"
     LD_SPU_FLAGS="$LD_SPU_FLAGS -L$with_cml_prefix/lib"
+
+    # ALF_LIBRARY_PATH (ALF 3.0) only supports a single path.
+    # Create link to CML kernels from VSIPL++ directory.
+    # This allows in-tree development.  It will not be copied
+    # on installation.
+    mkdir -p lib
+    ln -sf $with_cml_prefix/lib/cml_kernels.so lib
   fi
 
   if test "$neutral_acconfig" = 'y'; then
Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 214423)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -92,6 +92,11 @@
 
 all:: $(spe_kernels)
 
+install-core:: lib/svpp_kernels.so
+	$(INSTALL) -d $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) lib/svpp_kernels.so \
+          $(DESTDIR)$(libdir)/svpp_kernels.so
+
 $(spe_kernels): $(src_vsip_opt_cbe_spu_obj)
 	$(link_spu_kernel_dso)
 
