Index: ChangeLog
===================================================================
--- ChangeLog	(revision 174171)
+++ ChangeLog	(working copy)
@@ -1,3 +1,11 @@
+2007-06-17  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/fftw3/fft_impl.cpp: Respect aligned when planning for
+	  R-to-C and C-to-R transforms.
+	* src/vsip_csl/GNUmakefile.inc.in (install): Install stencil headers.
+	* tests/fft.cpp: Fix template typo.
+	* benchmarks/fftw3/fft.cpp: Fix Wall warning.
+
 2007-06-16  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip/core/layout.hpp (Applied_layout<Rt_layout<Dim> >): Check
Index: src/vsip/opt/fftw3/fft_impl.cpp
===================================================================
--- src/vsip/opt/fftw3/fft_impl.cpp	(revision 174171)
+++ src/vsip/opt/fftw3/fft_impl.cpp	(working copy)
@@ -90,6 +90,7 @@
       out_buffer_(dom.size()),
       aligned_(aligned)
   { 
+    if (!aligned) flags |= FFTW_UNALIGNED;
     for (vsip::dimension_type i = 0; i < D; ++i) size_[i] = dom[i].size();  
     // FFTW3 assumes A == D - 1.
     // See also query_layout().
@@ -120,6 +121,7 @@
       out_buffer_(32, dom.size()),
       aligned_(aligned)
   {
+    if (!aligned) flags |= FFTW_UNALIGNED;
     for (vsip::dimension_type i = 0; i < D; ++i) size_[i] = dom[i].size();
     // FFTW3 assumes A == D - 1.
     // See also query_layout().
Index: src/vsip_csl/GNUmakefile.inc.in
===================================================================
--- src/vsip_csl/GNUmakefile.inc.in	(revision 174122)
+++ src/vsip_csl/GNUmakefile.inc.in	(working copy)
@@ -51,8 +51,12 @@
 	$(INSTALL_DATA) lib/libvsip_csl.$(LIBEXT) \
           $(DESTDIR)$(libdir)/libvsip_csl$(suffix).$(LIBEXT)
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip_csl
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip_csl/stencil
 	for header in $(wildcard $(srcdir)/src/vsip_csl/*.hpp); do \
           $(INSTALL_DATA) $$header $(DESTDIR)$(includedir)/vsip_csl; \
 	done
+	for header in $(wildcard $(srcdir)/src/vsip_csl/stencil/*.hpp); do \
+          $(INSTALL_DATA) $$header $(DESTDIR)$(includedir)/vsip_csl/stencil; \
+	done
 
 endif
Index: tests/fft.cpp
===================================================================
--- tests/fft.cpp	(revision 173072)
+++ tests/fft.cpp	(working copy)
@@ -923,8 +923,8 @@
 #endif
 
 #if TEST_2D_RC
-  test_fft<0,0,float,complex<float>,2,1>();
-  test_fft<0,0,float,complex<float>,2,0>();
+  test_fft<0,0,T,complex<T>,2,1>();
+  test_fft<0,0,T,complex<T>,2,0>();
 #endif
 
 #if TEST_3D_CC
Index: benchmarks/fftw3/fft.cpp
===================================================================
--- benchmarks/fftw3/fft.cpp	(revision 173215)
+++ benchmarks/fftw3/fft.cpp	(working copy)
@@ -242,7 +242,7 @@
     if (save_wisdom_)
     {
       char file[80];
-      sprintf(file, "wisdom.%d", size);
+      sprintf(file, "wisdom.%d", (int)size);
       FILE* fd = fopen(file, "w");
       Fftw_traits<T>::export_wisdom_to_file(fd);
       fclose(fd);
