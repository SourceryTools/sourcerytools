Index: ChangeLog
===================================================================
--- ChangeLog	(revision 218807)
+++ ChangeLog	(working copy)
@@ -1,5 +1,10 @@
 2008-08-26  Jules Bergmann  <jules@codesourcery.com>
 
+	* benchmarks/GNUmakefile.inc.in: Add <benchmark>.prof rule to create
+	  benchmark binaries with profiling enabled.
+
+2008-08-26  Jules Bergmann  <jules@codesourcery.com>
+
 	* README.cbe: Update for binary CML package.
 	* examples/cell/setup.sh: New file, example CBE configury options.
 
Index: benchmarks/GNUmakefile.inc.in
===================================================================
--- benchmarks/GNUmakefile.inc.in	(revision 218695)
+++ benchmarks/GNUmakefile.inc.in	(working copy)
@@ -68,7 +68,13 @@
                                %.static$(EXEEXT), \
                                $(benchmarks_targets))
 
+benchmarks_prof_obj := $(patsubst $(srcdir)/%.cpp, %.prof.$(OBJEXT), $(benchmarks_cxx_sources))
 
+benchmarks_prof_targets := $(patsubst %$(EXEEXT), \
+                               %.prof$(EXEEXT), \
+                               $(benchmarks_targets))
+
+
 ########################################################################
 # Rules
 ########################################################################
@@ -110,4 +116,10 @@
 $(benchmarks_static_targets): %.static$(EXEEXT) : %.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
 	$(CXX) -static $(LDFLAGS) -o $@ $^ -Llib -lsvpp $(LIBS) || rm -f $@
 
+$(benchmarks_prof_obj): %.prof.$(OBJEXT): %.cpp
+	$(CXX) -c $(CXXFLAGS) $(call dir_var,$(dir $<),CXXFLAGS) -DVSIP_IMPL_PROFILER=15 -o $@ $<
+
+$(benchmarks_prof_targets): %.prof$(EXEEXT) : %.prof.$(OBJEXT) benchmarks/main.$(OBJEXT) $(libs)
+	$(link_app)
+
 endif # VSIP_IMPL_REF_IMPL
