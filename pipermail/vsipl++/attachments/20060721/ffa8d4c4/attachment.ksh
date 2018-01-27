Index: ChangeLog
===================================================================
--- ChangeLog	(revision 145319)
+++ ChangeLog	(working copy)
@@ -1,3 +1,10 @@
+2006-07-21  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/impl/par-services-none.hpp (default_communicator):
+	  Return result by reference.
+	* src/vsip_csl/GNUmakefile.inc.in (install): Add missing dependency
+	  on lib/libvsip_csl.a.
+
 2006-07-20  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/impl/ipp/fft.cpp: Make impl namespace explicit to
Index: src/vsip/impl/par-services-none.hpp
===================================================================
--- src/vsip/impl/par-services-none.hpp	(revision 145317)
+++ src/vsip/impl/par-services-none.hpp	(working copy)
@@ -238,7 +238,7 @@
       valid_ = 0;
     }
 
-  static communicator_type default_communicator()
+  static communicator_type& default_communicator()
     {
       return default_communicator_;
     }
Index: src/vsip_csl/GNUmakefile.inc.in
===================================================================
--- src/vsip_csl/GNUmakefile.inc.in	(revision 145317)
+++ src/vsip_csl/GNUmakefile.inc.in	(working copy)
@@ -39,7 +39,7 @@
 	$(AR) rc $@ $^ || rm -f $@
 
 # Install the extensions library and its header files.
-install:: 
+install:: lib/libvsip_csl.a
 	$(INSTALL) -d $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) lib/libvsip_csl.a $(DESTDIR)$(libdir)/libvsip_csl$(suffix).a
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip_csl
