Index: ChangeLog
===================================================================
--- ChangeLog	(revision 221472)
+++ ChangeLog	(working copy)
@@ -1,5 +1,11 @@
 2008-09-15  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Install cml_kernels.so.
+	* src/vsip/GNUmakefile.inc.in (install): Add missing ukernel dir.
+	* GNUmakefile.in (hdr): Add missing ukernels headers.
+
+2008-09-15  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/opt/cbe/ppu/bindings.hpp: Fix Wall warning.
 	* src/vsip/opt/cbe/cml/transpose.hpp: Likewise.
 	* benchmarks/cell/fastconv.cpp: Disamiguate impl::
Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 221471)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -96,10 +96,15 @@
 
 all:: $(spe_kernels)
 
+# NOTE: Installing cml_kernels.so is a work-around for SDK 3.0 ALF, which
+#       only accepts 1 directory in ALF_LIBRARY_PATH.  libs/cml_kernels.so
+#       is a link created by configure.
 install-core:: lib/svpp_kernels.so
 	$(INSTALL) -d $(DESTDIR)$(libdir)
 	$(INSTALL_PROGRAM) lib/svpp_kernels.so \
           $(DESTDIR)$(libdir)/svpp_kernels.so
+	$(INSTALL_PROGRAM) lib/cml_kernels.so \
+          $(DESTDIR)$(libdir)/cml_kernels.so
 
 $(spe_kernels): $(src_vsip_opt_cbe_spu_obj)
 	$(link_spu_kernel_dso)
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 221470)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -128,6 +128,7 @@
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/cbe/cml
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/ukernel
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/ukernel/kernels/host
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/ukernel/kernels/params
 endif
 endif
 	for header in $(hdr); do \
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 221471)
+++ GNUmakefile.in	(working copy)
@@ -441,6 +441,8 @@
              $(wildcard $(srcdir)/src/vsip/opt/ukernel/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/ukernel/kernels/host/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/opt/ukernel/kernels/params/*.hpp))
 endif
 endif
 ########################################################################
