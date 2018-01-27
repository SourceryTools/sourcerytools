Index: benchmarks/cell/bw.cpp
===================================================================
--- benchmarks/cell/bw.cpp	(revision 172149)
+++ benchmarks/cell/bw.cpp	(working copy)
@@ -85,11 +85,9 @@
 
     assert(len % chunk_size == 0);
     length_type chunks = len / chunk_size;
-    length_type spes = mgr->num_spes();
 
     for (index_type i=0; i<repeat; ++i)
     {
-      params.spe = i%spes;
       Workblock block = task.create_multi_block(chunks);
       block.set_parameters(params);
       task.enqueue(block);
@@ -112,7 +110,6 @@
       params.a_ptr        = (float*)A;
       params.b_ptr        = (float*)B;
       params.r_ptr        = (float*)R;
-      params.spe          = i%spes;
       for (index_type chunk=0; chunk<chunks; chunk += chunks_per_spe)
       {
 	Workblock block = task.create_multi_block(chunks_per_spe);
@@ -174,7 +171,6 @@
 {
   typedef float T;
   typedef std::pair<T*, T*> RT;
-  //  std::cout << "vmul(len " << len << ", repeat " << repeat << ")\n";
 
   using vsip::impl::cbe::Task_manager;
   using vsip::impl::cbe::Task;
@@ -412,7 +408,6 @@
 {
   length_type num  = atoi(loop.param_["num"].c_str());
   length_type size = atoi(loop.param_["size"].c_str());
-  // bool huge = atoi(loop.param_["huge"].c_str()) == 1;
   std::cout << "num chunks (p:num)  = " << num << ::std::endl;
   std::cout << "chunk size (p:size) = " << size << ::std::endl;
 
Index: benchmarks/makefile.standalone.in
===================================================================
--- benchmarks/makefile.standalone.in	(revision 172149)
+++ benchmarks/makefile.standalone.in	(working copy)
@@ -38,7 +38,7 @@
 #
 #  make PREFIX=/path/to/library
 #
-PREFIX   := 
+PREFIX   := @prefix@
 
 # Package to use.  For binary packages, this should either be 'vsipl++'
 # to use the release version of the library, or 'vsipl++-debug' to
@@ -48,10 +48,10 @@
 PKG      := vsipl++
 
 # Object file extension
-OBJEXT   := o
+OBJEXT   := @OBJEXT@
 
 # Executable file extension
-EXEEXT   :=  
+EXEEXT   :=  @EXEEXT@
 
 
 ########################################################################
Index: benchmarks/hpec_kernel/GNUmakefile.inc.in
===================================================================
--- benchmarks/hpec_kernel/GNUmakefile.inc.in	(revision 172149)
+++ benchmarks/hpec_kernel/GNUmakefile.inc.in	(working copy)
@@ -23,6 +23,11 @@
 hpec_cxx_sources := $(wildcard $(srcdir)/benchmarks/hpec_kernel/*.cpp)
 hpec_cxx_headers := $(wildcard $(srcdir)/benchmarks/hpec_kernel/*.hpp)
 
+ifndef VSIP_IMPL_HAVE_LAPACK
+hpec_cxx_sources := $(patsubst \
+	$(srcdir)/benchmarks/hpec_kernel/svd.cpp, , $(hpec_cxx_sources))
+endif
+
 hpec_obj := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(hpec_cxx_sources))
 hpec_exe := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(hpec_cxx_sources))
 hpec_targets := $(filter-out benchmarks/main$(EXEEXT), $(hpec_exe)) 
