Index: ChangeLog
===================================================================
--- ChangeLog	(revision 176624)
+++ ChangeLog	(working copy)
@@ -1,4 +1,22 @@
+2007-07-26  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/core/layout.hpp (Applied_layout): Make extent parameter
+	  generic.
+	* src/vsip/core/length.hpp (size_of_dim): New function, return length
+	  of dimension.
+	* src/vsip/domain.hpp (size_of_dim): Likewise.
+	* src/vsip/opt/fftw3/create_plan.hpp: Fix Wall warnings.
+	
+	* GNUmakefile.in (install-core): New rule, install non-documentation
+	  part of library.  install depends on install-core, so its behavior
+	  is unchanged.
+	* src/vsip/GNUmakefile.inc.in (install-core): Use it.
+	* src/vsip_csl/GNUmakefile.inc.in (install-core): Use it.
+	* tests/GNUmakefile.inc.in: Link tests in csl directory with
+	  -lvsip_csl.
+	
 2007-07-16  Assem Salama <assem@codesourcery.com>
+	
 	* src/vsip/core/type_list.hpp: Added a new arg to the template list
 	  for a new dispatch.
 	* src/vsip/opt/reductions/par_reductions.hpp: Fixed problem with
Index: src/vsip/core/layout.hpp
===================================================================
--- src/vsip/core/layout.hpp	(revision 176624)
+++ src/vsip/core/layout.hpp	(working copy)
@@ -345,16 +345,12 @@
     size_[0] = size0;
   }
 
-  Applied_layout(Domain<1> const& dom)
+  template <typename ExtentT>
+  Applied_layout(ExtentT const& extent)
   {
-    size_[0] = dom[0].length();
+    size_[0] = size_of_dim(extent, 0);
   }
 
-  Applied_layout(Length<1> const& extent)
-  {
-    size_[0] = extent[0];
-  }
-
   index_type index(index_type idx0)
     const VSIP_NOTHROW
   {
@@ -401,16 +397,12 @@
     size_[0] = size0;
   }
 
-  Applied_layout(Domain<1> const& dom)
+  template <typename ExtentT>
+  Applied_layout(ExtentT const& extent)
   {
-    size_[0] = dom[0].length();
+    size_[0] = size_of_dim(extent, 0);
   }
 
-  Applied_layout(Length<1> const& extent)
-  {
-    size_[0] = extent[0];
-  }
-
   index_type index(index_type idx0)
     const VSIP_NOTHROW
   {
@@ -456,9 +448,10 @@
     size_[0] = size0;
   }
 
-  Applied_layout(Length<1> const& extent)
+  template <typename ExtentT>
+  Applied_layout(ExtentT const& extent)
   {
-    size_[0] = extent[0];
+    size_[0] = size_of_dim(extent, 0);
   }
 
   index_type index(index_type idx0)
@@ -506,18 +499,13 @@
     size_[1] = size1;
   }
 
-  Applied_layout(Domain<2> const& dom)
+  template <typename ExtentT>
+  Applied_layout(ExtentT const& extent)
   {
-    size_[0] = dom[0].length();
-    size_[1] = dom[1].length();
+    size_[0] = size_of_dim(extent, 0);
+    size_[1] = size_of_dim(extent, 1);
   }
 
-  Applied_layout(Length<2> const& extent)
-  {
-    size_[0] = extent[0];
-    size_[1] = extent[1];
-  }
-
   index_type index(index_type idx0, index_type idx1)
     const VSIP_NOTHROW
   {
@@ -563,18 +551,13 @@
     size_[1] = size1;
   }
 
-  Applied_layout(Domain<2> const& dom)
+  template <typename ExtentT>
+  Applied_layout(ExtentT const& extent)
   {
-    size_[0] = dom[0].length();
-    size_[1] = dom[1].length();
+    size_[0] = size_of_dim(extent, 0);
+    size_[1] = size_of_dim(extent, 1);
   }
 
-  Applied_layout(Length<2> const& extent)
-  {
-    size_[0] = extent[0];
-    size_[1] = extent[1];
-  }
-
   index_type index(index_type idx0, index_type idx1)
     const VSIP_NOTHROW
   {
@@ -627,10 +610,11 @@
       stride_ += (Align - stride_%Align);
   }
 
-  Applied_layout(Domain<2> const& dom)
+  template <typename ExtentT>
+  Applied_layout(ExtentT const& extent)
   {
-    size_[0] = dom[0].length();
-    size_[1] = dom[1].length();
+    size_[0] = size_of_dim(extent, 0);
+    size_[1] = size_of_dim(extent, 1);
 
     stride_ = size_[1];
 
@@ -638,17 +622,6 @@
       stride_ += (Align - stride_%Align);
   }
 
-  Applied_layout(Length<2> const& extent)
-  {
-    size_[0] = extent[0];
-    size_[1] = extent[1];
-
-    stride_ = size_[1];
-
-    if (stride_ % Align != 0)
-      stride_ += (Align - stride_%Align);
-  }
-
   index_type index(index_type idx0, index_type idx1)
     const VSIP_NOTHROW
   {
@@ -702,10 +675,11 @@
       stride_ += (Align - stride_%Align);
   }
 
-  Applied_layout(Domain<2> const& dom)
+  template <typename ExtentT>
+  Applied_layout(ExtentT const& extent)
   {
-    size_[0] = dom[0].length();
-    size_[1] = dom[1].length();
+    size_[0] = size_of_dim(extent, 0);
+    size_[1] = size_of_dim(extent, 1);
 
     stride_ = size_[0];
 
@@ -713,17 +687,6 @@
       stride_ += (Align - stride_%Align);
   }
 
-  Applied_layout(Length<2> const& extent)
-  {
-    size_[0] = extent[0];
-    size_[1] = extent[1];
-
-    stride_ = size_[0];
-
-    if (stride_ % Align != 0)
-      stride_ += (Align - stride_%Align);
-  }
-
   index_type index(index_type idx0, index_type idx1)
     const VSIP_NOTHROW
   {
@@ -768,20 +731,14 @@
   typedef ComplexLayout           complex_type;
 
 public:
-  Applied_layout(Domain<3> const& dom)
+  template <typename ExtentT>
+  Applied_layout(ExtentT const& extent)
   {
-    size_[0] = dom[0].length();
-    size_[1] = dom[1].length();
-    size_[2] = dom[2].length();
+    size_[0] = size_of_dim(extent, 0);
+    size_[1] = size_of_dim(extent, 1);
+    size_[2] = size_of_dim(extent, 2);
   }
 
-  Applied_layout(Length<3> const& extent)
-  {
-    size_[0] = extent[0];
-    size_[1] = extent[1];
-    size_[2] = extent[2];
-  }
-
   index_type index(Index<3> idx)
     const VSIP_NOTHROW
   {
@@ -835,11 +792,12 @@
   typedef ComplexLayout            complex_type;
 
 public:
-  Applied_layout(Domain<3> const& dom)
+  template <typename ExtentT>
+  Applied_layout(ExtentT const& extent)
   {
-    size_[0] = dom[0].length();
-    size_[1] = dom[1].length();
-    size_[2] = dom[2].length();
+    size_[0] = size_of_dim(extent, 0);
+    size_[1] = size_of_dim(extent, 1);
+    size_[2] = size_of_dim(extent, 1);
 
     stride_[Dim2] = 1;
     stride_[Dim1] = size_[Dim2];
@@ -848,19 +806,6 @@
     stride_[Dim0] = size_[Dim1] * stride_[Dim1];
   }
 
-  Applied_layout(Length<3> const& extent)
-  {
-    size_[0] = extent[0];
-    size_[1] = extent[1];
-    size_[2] = extent[2];
-
-    stride_[Dim2] = 1;
-    stride_[Dim1] = size_[Dim2];
-    if (stride_[Dim1] % Align != 0)
-      stride_[Dim1] += (Align - stride_[Dim1]%Align);
-    stride_[Dim0] = size_[Dim1] * stride_[Dim1];
-  }
-
   index_type index(Index<3> idx)
     const VSIP_NOTHROW
   {
@@ -919,18 +864,20 @@
   // Requires
   //   LAYOUT to be the run-time layout.
   //   EXTENT to be the extent of the data to layout.
+  //   EXTENTT to be a type capable of encoding an extent (Length or Domain)
   //   ELEM_SIZE to be the size of a data element (in bytes).
 
+  template <typename ExtentT>
   Applied_layout(
     Rt_layout<Dim> const& layout,
-    Length<Dim> const&    extent,
+    ExtentT const&        extent,
     length_type           elem_size = 1)
   : cformat_(layout.complex)
   {
     assert(layout.align == 0 || layout.align % elem_size == 0);
 
     for (dimension_type d=0; d<Dim; ++d)
-      size_[d] = extent[d];
+      size_[d] = size_of_dim(extent, d);
 
     if (Dim == 3)
     {
Index: src/vsip/core/length.hpp
===================================================================
--- src/vsip/core/length.hpp	(revision 176624)
+++ src/vsip/core/length.hpp	(working copy)
@@ -70,6 +70,20 @@
 }
 
 
+
+// Return size of dimension.
+
+// Generic function.  Overloaded for structures that can encode
+// extents (Domain, Length)
+
+template <dimension_type D>
+inline length_type
+size_of_dim(Length<D> const& len, dimension_type d)
+{
+  return len[d];
+}
+
+
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/domain.hpp
===================================================================
--- src/vsip/domain.hpp	(revision 176624)
+++ src/vsip/domain.hpp	(working copy)
@@ -409,6 +409,20 @@
     this->domains_, dom.domains_);
 }
 
+
+
+// Return size of dimension.
+
+// Generic function.  Overloaded for structures that can encode
+// extents (Domain, Length)
+
+template <dimension_type D>
+inline length_type
+size_of_dim(Domain<D> const& len, dimension_type d)
+{
+  return len[d].size();
+}
+
 } // namespace impl
 
 
Index: src/vsip/opt/fftw3/create_plan.hpp
===================================================================
--- src/vsip/opt/fftw3/create_plan.hpp	(revision 176624)
+++ src/vsip/opt/fftw3/create_plan.hpp	(working copy)
@@ -141,16 +141,16 @@
             typename T, dimension_type Dim>
   static PlanT
   create(std::pair<T*,T*> ptr1, std::pair<T*,T*> ptr2,
-         int exp, int flags, Domain<Dim> const& size)
+         int /*exp*/, int flags, Domain<Dim> const& size)
   {
     IodimT iodims[Dim];
-    int i;
+
     Applied_layout<Layout<Dim, typename Row_major<Dim>::type,
                           Stride_unit_align<VSIP_IMPL_ALLOC_ALIGNMENT>,
                           Cmplx_split_fmt> >
     app_layout(size);
 
-    for(i=0;i<Dim;i++) 
+    for (index_type i=0;i<Dim;i++) 
     { 
       iodims[i].n = app_layout.size(i);
       iodims[i].is = iodims[i].os = app_layout.stride(i);
@@ -168,7 +168,7 @@
          int A, int flags, Domain<Dim> const& size)
   {
     IodimT iodims[Dim];
-    int i;
+
     Applied_layout<Rt_layout<Dim> >
        app_layout(Rt_layout<Dim>(stride_unit_align,
                                  tuple_from_axis<Dim>(A),
@@ -176,8 +176,7 @@
                                  0),
               size, sizeof(T));
 
-
-    for(i=0;i<Dim;i++) 
+    for (index_type i=0;i<Dim;i++) 
     { 
       iodims[i].n = app_layout.size(i);
       iodims[i].is = iodims[i].os = app_layout.stride(i); 
@@ -194,7 +193,7 @@
          int A, int flags, Domain<Dim> const& size)
   {
     IodimT iodims[Dim];
-    int i;
+
     Applied_layout<Rt_layout<Dim> >
        app_layout(Rt_layout<Dim>(stride_unit_align,
                                  tuple_from_axis<Dim>(A),
@@ -202,10 +201,7 @@
                                  0),
               size, sizeof(T));
 
-
-
-
-    for(i=0;i<Dim;i++) 
+    for (index_type i=0;i<Dim;i++) 
     { 
       iodims[i].n = app_layout.size(i);
       iodims[i].is = iodims[i].os = app_layout.stride(i);
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 173072)
+++ GNUmakefile.in	(working copy)
@@ -236,6 +236,12 @@
   -Llib -lsvpp $(call dir_var,$(dir $<),LIBS) $(LIBS)
 endef
 
+define link_csl_app
+@echo linking $@
+$(CXX) $(LDFLAGS) $(call dir_var,$(dir $<),LDFLAGS) -o $@ $< \
+  -Llib -lsvpp -lvsip_csl $(call dir_var,$(dir $<),LIBS) $(LIBS)
+endef
+
 endif
 
 ########################################################################
@@ -462,7 +468,7 @@
 clean:: mostlyclean
 
 .PHONY: install
-install:: install-pdf install-html
+install:: install-core install-pdf install-html
 
 .PHONY: install-pdf
 install-pdf:: $(foreach f,$(pdf_manuals),install-pdf-$(notdir $(f)))
@@ -472,6 +478,9 @@
 .PHONY: install-html
 install-html:: $(foreach f,$(html_manuals),install-html-$(notdir $(f))) 
 
+.PHONY: install-core
+install-core::
+
 $(foreach f,$(html_manuals),$(eval $(call install_html_template,$(f))))
 
 .PHONY: dist
@@ -507,7 +516,7 @@
 
 check::
 
-install::
+install-core::
 	$(install_pc)
 	$(INSTALL) -d $(DESTDIR)$(sbindir)
 	$(INSTALL_SCRIPT) $(srcdir)/scripts/set-prefix.sh $(DESTDIR)$(sbindir)
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 176624)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -88,7 +88,7 @@
 # separate $objdir, acconfig.hpp will be generated in the $objdir, so it
 # must be copied explicitly.  By copying it last, we override any
 # stale copy in the $srcdir.
-install:: lib/libsvpp.$(LIBEXT)
+install-core:: lib/libsvpp.$(LIBEXT)
 	$(INSTALL) -d $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) lib/libsvpp.$(LIBEXT) \
           $(DESTDIR)$(libdir)/libsvpp$(suffix).$(LIBEXT)
Index: src/vsip_csl/GNUmakefile.inc.in
===================================================================
--- src/vsip_csl/GNUmakefile.inc.in	(revision 176624)
+++ src/vsip_csl/GNUmakefile.inc.in	(working copy)
@@ -46,7 +46,7 @@
 	$(archive)
 
 # Install the extensions library and its header files.
-install:: lib/libvsip_csl.$(LIBEXT)
+install-core:: lib/libvsip_csl.$(LIBEXT)
 	$(INSTALL) -d $(DESTDIR)$(libdir)
 	$(INSTALL_DATA) lib/libvsip_csl.$(LIBEXT) \
           $(DESTDIR)$(libdir)/libvsip_csl$(suffix).$(LIBEXT)
Index: tests/GNUmakefile.inc.in
===================================================================
--- tests/GNUmakefile.inc.in	(revision 173072)
+++ tests/GNUmakefile.inc.in	(working copy)
@@ -31,8 +31,13 @@
                      $(wildcard $(srcdir)/tests/parallel/*.cpp) \
                      $(wildcard $(srcdir)/tests/regressions/*.cpp)
 
+# These need to be linked with -lvsip_csl
+tests_csl_cxx_sources := $(wildcard $(srcdir)/tests/tutorial/*.cpp)
+
 tests_cxx_exes := \
 	$(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(tests_cxx_sources))
+tests_csl_cxx_exes := \
+	$(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(tests_csl_cxx_sources))
 
 # Add tests/ to include search path for tests/ subdirectories.
 tests_parallel_CXXINCLUDES := -I$(srcdir)/tests
@@ -44,6 +49,9 @@
 $(tests_cxx_exes): %$(EXEEXT): %.$(OBJEXT) $(libs)
 	$(link_app)
 
+$(tests_csl_cxx_exes): %$(EXEEXT): %.$(OBJEXT) $(libs)
+	$(link_csl_app)
+
 check::	$(libs) $(tests_qmtest_extensions)
 	cd tests; $(QMTEST) run $(tests_run_ident) $(tests_ids); \
           result=$$?; test $$tmp=0 || $$tmp=2
