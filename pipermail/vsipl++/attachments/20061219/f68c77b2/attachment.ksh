Index: ChangeLog
===================================================================
--- ChangeLog	(revision 157545)
+++ ChangeLog	(working copy)
@@ -1,3 +1,30 @@
+2006-12-19  Jules Bergmann  <jules@codesourcery.com>
+	
+	* src/vsip/core/block_traits.hpp (Proper_type_of): Determine if
+	  block type should be const.  Useful for cases were const is
+	  stripped off expression blocks.
+	* src/vsip/core/cvsip/eval_reductions_idx.hpp: Work around for
+	  loss of const on expression block type.
+	* src/vsip/core/cvsip/eval_reductions.hpp: Likewise.
+	* tests/reductions.cpp: Extend to cover reduction of expression.
+	* src/vsip/opt/extdata_local.hpp: Extend to work with const blocks.
+	  Add ability to allocate buffer for copy.
+	* src/vsip/core/expr/ternary_block.hpp (Distributed_local_block):
+	  Define proxy_type.
+	
+	* src/vsip/core/vmmul.hpp (Is_par_same_map): Recognize Replicated_map.
+	* tests/vmmul.cpp: Extend to cover replicated_map.
+	
+	* scripts/package.py: Fix path to acconfig.hpp.
+	* src/vsip/GNUmakefile.inc.in: Install opt/diag and opt/fft
+	  directories.
+	* GNUmakefile.in: Likewise.  Add FASTMAKE option to avoid
+	  regenerating dependencies.
+	* examples/GNUmakefile.inc.in: Move install of examples into
+	  $pkgdatadir/examples.
+	* examples/makefile.standalone.in: Add rules for fft and png
+	  examples
+	
 2006-12-14  Jules Bergmann  <jules@codesourcery.com>
 
 	* src/vsip_csl/load_view.hpp (load_view_as): Extend to work
@@ -326,11 +353,11 @@
 
 2006-11-26  Don McCoy  <don@codesourcery.com>
 
-        * apps/ssar/kernel1.hpp: Made some data members in constructors local as
+	* apps/ssar/kernel1.hpp: Made some data members in constructors local as
           they did not need to be retained.  Some minor renaming and comment-
           fixing for consistency.  Fixed the two asserts in interpolate to
           check for the correct size.
-        * apps/ssar/ssar.cpp: Added display of setup time, plus max, min and
+	* apps/ssar/ssar.cpp: Added display of setup time, plus max, min and
           std-dev for the mean compute time.
 
 2006-11-22  Don McCoy  <don@codesourcery.com>
Index: src/vsip/core/expr/ternary_block.hpp
===================================================================
--- src/vsip/core/expr/ternary_block.hpp	(revision 157392)
+++ src/vsip/core/expr/ternary_block.hpp	(working copy)
@@ -154,6 +154,11 @@
 		typename Distributed_local_block<Block2>::type, Type2,
 		typename Distributed_local_block<Block3>::type, Type3> const
 		type;
+  typedef Ternary_expr_block<D, Functor,
+		typename Distributed_local_block<Block1>::proxy_type, Type1,
+		typename Distributed_local_block<Block2>::proxy_type, Type2,
+		typename Distributed_local_block<Block3>::proxy_type, Type3>
+          const proxy_type;
 };
 
 template <dimension_type D,
Index: src/vsip/core/vmmul.hpp
===================================================================
--- src/vsip/core/vmmul.hpp	(revision 157392)
+++ src/vsip/core/vmmul.hpp	(working copy)
@@ -243,12 +243,18 @@
     assert(!Is_local_only<MapT>::value);
 
     return 
-      // Case 1: vector is global
+      // Case 1a: vector is global
       (Is_par_same_map<1, Global_map<1>, Block0>::value(
 			Global_map<1>(), block.get_vblk()) &&
        map.num_subblocks(1-VecDim) == 1 &&
        Is_par_same_map<MapDim, MapT, Block1>::value(map, block.get_mblk())) ||
 
+      // Case 1b: vector is replicated
+      (Is_par_same_map<1, Replicated_map<1>, Block0>::value(
+			Replicated_map<1>(), block.get_vblk()) &&
+       map.num_subblocks(1-VecDim) == 1 &&
+       Is_par_same_map<MapDim, MapT, Block1>::value(map, block.get_mblk())) ||
+
       // Case 2:
       (map.num_subblocks(VecDim) == 1 &&
        Is_par_same_map<1, typename Map_project_1<VecDim, MapT>::type, Block0>
Index: src/vsip/core/cvsip/eval_reductions_idx.hpp
===================================================================
--- src/vsip/core/cvsip/eval_reductions_idx.hpp	(revision 157392)
+++ src/vsip/core/cvsip/eval_reductions_idx.hpp	(working copy)
@@ -160,7 +160,8 @@
 
   static void exec(T& r, Block const& blk, Index<Dim>& idx, OrderT)
   {
-    Ext_data_local<Block> ext(blk, SYNC_IN);
+    typedef typename Proper_type_of<Block>::type block_type;
+    Ext_data_local<block_type> ext(blk, SYNC_IN);
     cvsip::View_from_ext<Dim, value_type> view(ext);
     
     r = cvsip::Reduce_idx_class<ReduceT, Dim, value_type>::exec(
Index: src/vsip/core/cvsip/eval_reductions.hpp
===================================================================
--- src/vsip/core/cvsip/eval_reductions.hpp	(revision 157392)
+++ src/vsip/core/cvsip/eval_reductions.hpp	(working copy)
@@ -170,7 +170,8 @@
 
   static void exec(T& r, Block const& blk, OrderT, Int_type<Dim>)
   {
-    Ext_data_local<Block> ext(blk, SYNC_IN);
+    typedef typename Proper_type_of<Block>::type block_type;
+    Ext_data_local<block_type> ext(blk, SYNC_IN);
     cvsip::View_from_ext<Dim, value_type> view(ext);
     
     r = cvsip::Reduce_class<ReduceT, Dim, value_type>::exec(view.view_.ptr());
Index: src/vsip/core/block_traits.hpp
===================================================================
--- src/vsip/core/block_traits.hpp	(revision 157392)
+++ src/vsip/core/block_traits.hpp	(working copy)
@@ -232,6 +232,24 @@
 
 
 
+/// Temporary trait to determine "proper" type of block.
+///
+/// Dispatch templates can sometimes strip the 'const'
+/// off of a block type.  This causes problems for exprssion
+/// block, which *must* be const.
+
+template <typename BlockT>
+struct Proper_type_of
+{
+  typedef typename
+          ITE_Type<Is_expr_block<BlockT>::value,
+                   As_type<BlockT const>,
+                   Non_const_of<BlockT> >::type
+          type;
+};
+
+
+
 /// Traits class to determine if block is a scalar block.
 
 template <typename Block>
Index: src/vsip/opt/extdata_local.hpp
===================================================================
--- src/vsip/opt/extdata_local.hpp	(revision 157392)
+++ src/vsip/opt/extdata_local.hpp	(working copy)
@@ -121,6 +121,7 @@
 class Ext_data_local<BlockT, LP, RP, AT, edl_details::Impl_use_direct>
   : public Ext_data<BlockT, LP, RP, AT>
 {
+  typedef typename Non_const_of<BlockT>::type non_const_block_type;
   typedef Ext_data<BlockT, LP, RP, AT> base_type;
 
   typedef typename base_type::storage_type storage_type;
@@ -128,9 +129,9 @@
 
   // Constructor and destructor.
 public:
-  Ext_data_local(BlockT&            block,
-		 sync_action_type   sync,
-		 raw_ptr_type       buffer = raw_ptr_type())
+  Ext_data_local(non_const_block_type& block,
+		 sync_action_type      sync,
+		 raw_ptr_type          buffer = raw_ptr_type())
     : base_type(block, sync, buffer)
   {}
 
@@ -155,6 +156,7 @@
 class Ext_data_local<BlockT, LP, RP, AT, edl_details::Impl_use_local>
   : public Ext_data<typename Distributed_local_block<BlockT>::type, LP, RP, AT>
 {
+  typedef typename Non_const_of<BlockT>::type non_const_block_type;
   typedef typename Distributed_local_block<BlockT>::type local_block_type;
   typedef Ext_data<local_block_type, LP, RP, AT> base_type;
 
@@ -163,9 +165,9 @@
 
   // Constructor and destructor.
 public:
-  Ext_data_local(BlockT&            block,
-		 sync_action_type   sync,
-		 raw_ptr_type       buffer = raw_ptr_type())
+  Ext_data_local(non_const_block_type& block,
+		 sync_action_type      sync,
+		 raw_ptr_type          buffer = raw_ptr_type())
     : base_type(get_local_block(block), sync, buffer)
   {}
 
@@ -189,6 +191,7 @@
 	  typename AT>
 class Ext_data_local<BlockT, LP, RP, AT, edl_details::Impl_remap>
 {
+  typedef typename Non_const_of<BlockT>::type non_const_block_type;
   static dimension_type const dim = BlockT::dim;
   typedef typename BlockT::value_type value_type;
   typedef Us_block<dim, value_type, LP, Local_map> block_type;
@@ -204,9 +207,9 @@
 
   // Constructor and destructor.
 public:
-  Ext_data_local(BlockT&            block,
-		 sync_action_type   sync,
-		 raw_ptr_type       buffer = raw_ptr_type())
+  Ext_data_local(non_const_block_type& block,
+		 sync_action_type      sync,
+		 raw_ptr_type          buffer = raw_ptr_type())
     : src_     (block),
       storage_ (block.size(), buffer),
       block_   (block_domain<dim>(block), storage_.data()),
Index: src/vsip/GNUmakefile.inc.in
===================================================================
--- src/vsip/GNUmakefile.inc.in	(revision 157392)
+++ src/vsip/GNUmakefile.inc.in	(working copy)
@@ -78,7 +78,9 @@
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/core/solver
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/core/cvsip
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/diag
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/expr
+	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/fft
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/fftw3
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/ipp
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip/opt/lapack
Index: tests/vmmul.cpp
===================================================================
--- tests/vmmul.cpp	(revision 157392)
+++ tests/vmmul.cpp	(working copy)
@@ -163,7 +163,7 @@
 
   // -------------------------------------------------------------------
   // If vector is global (replicated on all processors),
-  // The matrix must not be distributed in the along the vector
+  // The matrix must not be distributed along the vector
 
   Global_map<1> gmap;
   Map<Block_dist, Block_dist> row_map(np, 1);
@@ -179,6 +179,12 @@
   // test_par_vmmul<0, OrderT, T>(gmap, chk_map, 5, 7); // dist along vector
   // test_par_vmmul<1, OrderT, T>(gmap, chk_map, 5, 7); // dist along vector
 
+  // Likewise for replicated_map
+  Replicated_map<1> rmap;
+  test_par_vmmul<0, OrderT, T>(rmap, row_map, 5, 7);
+  test_par_vmmul<1, OrderT, T>(rmap, col_map, 5, 7);
+
+
   // -------------------------------------------------------------------
   // If vector is distributed (not replicated),
   // The matrix must
Index: tests/reductions.cpp
===================================================================
--- tests/reductions.cpp	(revision 157392)
+++ tests/reductions.cpp	(working copy)
@@ -39,6 +39,8 @@
   test_assert(equal(sumsqval(vec), 14.0f));
   test_assert(equal(meansqval(vec), 3.5f));
 
+  test_assert(equal(sumval(vec+vec), 12.0f));
+
   Matrix<double> mat(2, 2);
 
   mat(0, 0) = 1.;
Index: examples/GNUmakefile.inc.in
===================================================================
--- examples/GNUmakefile.inc.in	(revision 157392)
+++ examples/GNUmakefile.inc.in	(working copy)
@@ -43,10 +43,10 @@
 	rm -f $(examples_cxx_exes)
 
 install::
-	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)
-	$(INSTALL_DATA) $(examples_cxx_sources) $(DESTDIR)$(pkgdatadir)
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/examples
+	$(INSTALL_DATA) $(examples_cxx_sources) $(DESTDIR)$(pkgdatadir)/examples
 	$(INSTALL_DATA) examples/makefile.standalone \
-	  $(DESTDIR)$(pkgdatadir)/Makefile
+	  $(DESTDIR)$(pkgdatadir)/examples/Makefile
 
 $(examples_cxx_exes): %$(EXEEXT): %.$(OBJEXT) $(libs)
 	$(link_app)
Index: examples/makefile.standalone.in
===================================================================
--- examples/makefile.standalone.in	(revision 157392)
+++ examples/makefile.standalone.in	(working copy)
@@ -39,3 +39,11 @@
 example1: example1.o
 	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
 
+fft: fft.o
+	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
+
+fft.o: fft.cpp
+	$(CXX) $(CXXFLAGS) -DVSIP_IMPL_PROFILER=15 -c -o $@ $^
+
+png: png.o
+	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
Index: scripts/package.py
===================================================================
--- scripts/package.py	(revision 157392)
+++ scripts/package.py	(working copy)
@@ -194,7 +194,7 @@
             spawn(['sh', '-c', 'make install DESTDIR=%s'%abs_distdir])
 
             # Make copy of acconfig for later perusal.
-            spawn(['sh', '-c', 'cp %s/usr/local/include/vsip/core/acconfig.hpp ../acconfig%s%s.hpp'%(abs_distdir,suffix,s)])
+            spawn(['sh', '-c', 'cp %s/%s/include/vsip/core/acconfig.hpp ../acconfig%s%s.hpp'%(abs_distdir,prefix,suffix,s)])
 
             # Make symlink to variant' vsipl++.pc.
             os.chdir(pkgconfig_dir)
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 157392)
+++ GNUmakefile.in	(working copy)
@@ -202,6 +202,7 @@
 
 else # not intel-win
 
+# (This recipe is taken from the GNU Make manual.)
 define make_dep
 @echo generating dependencies for $(@D)/$(<F)
 $(SHELL) -ec '$(CXXDEP) $(CXXFLAGS) \
@@ -311,8 +312,12 @@
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/opt/diag/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/expr/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
+             $(wildcard $(srcdir)/src/vsip/opt/fft/*.hpp))
+hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/fftw3/*.hpp))
 hdr	+= $(patsubst $(srcdir)/src/%, %, \
              $(wildcard $(srcdir)/src/vsip/opt/ipp/*.hpp))
@@ -386,9 +391,16 @@
 	$(compile)
 
 # Generate a dependency Makefile fragment for a C++ source file.
-# (This recipe is taken from the GNU Make manual.)
+ifdef FASTMAKE
+# If FASTMAKE is defined, freshen up current dependencies instead
+# of regenerating them.  Useful when a header is modified in a way
+# that dependencies are preserved.
 %.d: %.cpp
+	@touch $@
+else
+%.d: %.cpp
 	$(make_dep)
+endif
 
 ########################################################################
 # Standard Targets
