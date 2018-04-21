? benchmarks/fft_ffmpeg.cpp
? benchmarks/hpec-corner-turn.cpp
? benchmarks/xgs.cpp
Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.501
diff -u -r1.501 ChangeLog
--- ChangeLog	9 Jun 2006 13:50:47 -0000	1.501
+++ ChangeLog	9 Jun 2006 21:30:11 -0000
@@ -1,3 +1,11 @@
+2006-06-09  Jules Bergmann  <jules@codesourcery.com>
+
+	* benchmarks/hpec_kernel/cfar.cpp: Fix cfar_verify to work in
+	  parallel: have each processor verify their own results, then use
+	  parallel reduction to get total count.  Fix vector and hybrid
+	  versions to process local view only.
+	* benchmarks/hpec_kernel/cfar_c.cpp: Likewise.
+
 2006-06-08  Jules Bergmann  <jules@codesourcery.com>
 
 	* benchmarks/hpec_kernel/cfar.cpp (t_cfar_by_hybrid): New
Index: benchmarks/hpec_kernel/cfar.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/hpec_kernel/cfar.cpp,v
retrieving revision 1.4
diff -u -r1.4 cfar.cpp
--- benchmarks/hpec_kernel/cfar.cpp	9 Jun 2006 13:50:47 -0000	1.4
+++ benchmarks/hpec_kernel/cfar.cpp	9 Jun 2006 21:30:11 -0000
@@ -138,35 +138,36 @@
   }
 
 
+  template <typename Block>
   void
   cfar_verify(
-    root_view_type&    root,
+    Tensor<T, Block>   l_cube,
     Matrix<Index<2> >  located,
     length_type        count[])
   {
-#if PARALLEL_CFAR
-    Vector<processor_type> pset0(1);
-    pset0(0) = processor_set()(0);
-    root_map_type root_map(pset0, 1, 1);
+    // Create a vector with one element on each processor.
+    length_type np = num_processors();
+    Vector<length_type, Dense<1, length_type, row1_type, Map<> > >
+      sum(np, Map<>(np));
+
+    length_type l_total_found = 0;
+    for ( index_type i = 0; i < l_cube.size(2); ++i )
+      for ( index_type j = 0; j < count[i]; ++j )
+      {
+	test_assert( l_cube.get(located.get(i, j)[0], 
+				located.get(i, j)[1], i) == T(50.0) );
+	++l_total_found;
+      }
+    sum.put(local_processor(), l_total_found);
 
-    if (root_map.subblock() != no_subblock)
-#endif
-    {
-      local_type l_root = LOCAL(root);
-      length_type total_found = 0;
-      for ( index_type i = 0; i < l_root.size(2); ++i )
-        for ( index_type j = 0; j < count[i]; ++j )
-        {
-          test_assert( l_root.get(located.get(i, j)[0], 
-                         located.row(i)(j)[1], i) == T(50.0) );
-          ++total_found;
-        }
-      // Warn if we don't find all the targets.
-      if( total_found != this->ntargets_ )
-	std::cerr << "only found " << total_found
-		  << " out of " << this->ntargets_
-		  << std::endl;
-    }
+    // Parallel reduction.
+    length_type total_found = sumval(sum);
+
+    // Warn if we don't find all the targets.
+    if( total_found != this->ntargets_ && local_processor() == 0 )
+      std::cerr << "only found " << total_found
+		<< " out of " << this->ntargets_
+		<< std::endl;
   }
 
   t_cfar_base(length_type beams, length_type bins)
@@ -331,7 +332,7 @@
     typedef typename view_type::local_type           local_type;
 
     processor_type np = num_processors();
-    map_type map = map_type(Block_dist(np), Block_dist(np), Whole_dist());
+    map_type map = map_type(Block_dist(np), Block_dist(1), Whole_dist());
 
     view_type cube(beams, dbins, gates, map);
     cube = root;
@@ -374,7 +375,7 @@
     time = t1.delta();
 
     // Verify targets detected
-    cfar_verify(root, located, count);
+    cfar_verify(l_cube, located, count);
 
     delete[] count;
   }
@@ -441,8 +442,10 @@
 
     subvector_type cpow_vec = cpow(0, 0, whole_domain);
 
-    for ( index_type i = 0; i < this->beams_; ++i )
-      for ( index_type j = 0; j < this->dbins_; ++j )
+    length_type l_beams = cube.size(0);
+    length_type l_dbins = cube.size(1);
+    for ( index_type i = 0; i < l_beams; ++i )
+      for ( index_type j = 0; j < l_dbins; ++j )
       {
 	T sum = T();
 
@@ -542,7 +545,7 @@
     typedef typename view_type::local_type           local_type;
 
     processor_type np = num_processors();
-    map_type map = map_type(Block_dist(np), Block_dist(np), Whole_dist());
+    map_type map = map_type(Block_dist(np), Block_dist(1), Whole_dist());
 
     view_type cube(beams, dbins, gates, map);
     cube = root;
@@ -582,7 +585,7 @@
 
 
     // Verify targets detected
-    cfar_verify(root, located, count);
+    cfar_verify(l_cube, located, count);
 
     delete[] count;
   }
@@ -644,7 +647,7 @@
 template <typename T>
 struct t_cfar_by_hybrid : public t_cfar_base<T>
 {
-  char* what() { return "t_cfar_by_vector"; }
+  char* what() { return "t_cfar_by_hybrid"; }
 
 #if PARALLEL_CFAR
   typedef Map<Block_dist, Block_dist, Block_dist>  root_map_type;
@@ -695,8 +698,10 @@
     v4sf v_eps  = load_scalar(eps);
     v4sf v_mu   = load_scalar(fmu);
 
-    for ( index_type i = 0; i < this->beams_; ++i )
-      for ( index_type j = 0; j < this->dbins_; j+=4 )
+    length_type l_beams = cube.size(0);
+    length_type l_dbins = cube.size(1);
+    for ( index_type i = 0; i < l_beams; ++i )
+      for ( index_type j = 0; j < l_dbins; j+=4 )
       {
 	v4sf sum = *(__v4sf*)zero;
 
@@ -831,7 +836,7 @@
     typedef typename view_type::local_type           local_type;
 
     processor_type np = num_processors();
-    map_type map = map_type(Block_dist(np), Block_dist(np), Whole_dist());
+    map_type map = map_type(Block_dist(np), Block_dist(1), Whole_dist());
 
     view_type cube(beams, dbins, gates, map);
     cube = root;
@@ -869,7 +874,7 @@
 
 
     // Verify targets detected
-    cfar_verify(root, located, count);
+    cfar_verify(l_cube, located, count);
 
     delete[] count;
   }
Index: benchmarks/hpec_kernel/cfar_c.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/hpec_kernel/cfar_c.cpp,v
retrieving revision 1.1
diff -u -r1.1 cfar_c.cpp
--- benchmarks/hpec_kernel/cfar_c.cpp	9 Jun 2006 13:50:47 -0000	1.1
+++ benchmarks/hpec_kernel/cfar_c.cpp	9 Jun 2006 21:30:11 -0000
@@ -138,35 +138,36 @@
   }
 
 
+  template <typename Block>
   void
   cfar_verify(
-    root_view_type&    root,
+    Tensor<T, Block>   l_cube,
     Matrix<Index<2> >  located,
     length_type        count[])
   {
-#if PARALLEL_CFAR
-    Vector<processor_type> pset0(1);
-    pset0(0) = processor_set()(0);
-    root_map_type root_map(pset0, 1, 1);
+    // Create a vector with one element on each processor.
+    length_type np = num_processors();
+    Vector<length_type, Dense<1, length_type, row1_type, Map<> > >
+      sum(np, Map<>(np));
+
+    length_type l_total_found = 0;
+    for ( index_type i = 0; i < l_cube.size(2); ++i )
+      for ( index_type j = 0; j < count[i]; ++j )
+      {
+	test_assert( l_cube.get(located.get(i, j)[0], 
+				located.get(i, j)[1], i) == T(50.0) );
+	++l_total_found;
+      }
+    sum.put(local_processor(), l_total_found);
 
-    if (root_map.subblock() != no_subblock)
-#endif
-    {
-      local_type l_root = LOCAL(root);
-      length_type total_found = 0;
-      for ( index_type i = 0; i < l_root.size(2); ++i )
-        for ( index_type j = 0; j < count[i]; ++j )
-        {
-          test_assert( l_root.get(located.get(i, j)[0], 
-                         located.row(i)(j)[1], i) == T(50.0) );
-          ++total_found;
-        }
-      // Warn if we don't find all the targets.
-      if( total_found != this->ntargets_ )
-	std::cerr << "only found " << total_found
-		  << " out of " << this->ntargets_
-		  << std::endl;
-    }
+    // Parallel reduction.
+    length_type total_found = sumval(sum);
+
+    // Warn if we don't find all the targets.
+    if( total_found != this->ntargets_ && local_processor() == 0 )
+      std::cerr << "only found " << total_found
+		<< " out of " << this->ntargets_
+		<< std::endl;
   }
 
   t_cfar_base(length_type beams, length_type bins)
@@ -244,9 +245,11 @@
     float* p_cube = ext_cube.data();
     float* p_cpow = ext_cpow_vec.data();
 
-    for ( index_type i = 0; i < this->beams_; ++i )
+    length_type l_beams = cube.size(0);
+    length_type l_dbins = cube.size(1);
+    for ( index_type i = 0; i < l_beams; ++i )
     {
-      for ( index_type j = 0; j < this->dbins_; ++j )
+      for ( index_type j = 0; j < l_dbins; ++j )
       {
 	sum = T();
 
@@ -346,7 +349,7 @@
     typedef typename view_type::local_type           local_type;
 
     processor_type np = num_processors();
-    map_type map = map_type(Block_dist(np), Block_dist(np), Whole_dist());
+    map_type map = map_type(Block_dist(np), Block_dist(1), Whole_dist());
 
     view_type cube(beams, dbins, gates, map);
     cube = root;
@@ -384,7 +387,7 @@
 
 
     // Verify targets detected
-    cfar_verify(root, located, count);
+    cfar_verify(l_cube, located, count);
 
     delete[] count;
   }
@@ -468,9 +471,11 @@
     float* p_cube = ext_cube.data();
     float* p_cpow = ext_cpow.data();
 
-    for ( index_type i = 0; i < this->beams_; ++i )
+    length_type l_beams = cube.size(0);
+    length_type l_dbins = cube.size(1);
+    for ( index_type i = 0; i < l_beams; ++i )
     {
-      for ( index_type j = 0; j < this->dbins_; j += 4 )
+      for ( index_type j = 0; j < l_dbins; j += 4 )
       {
 	__m128 sum = *(__m128*)zero;
 
@@ -630,7 +635,7 @@
     typedef typename view_type::local_type           local_type;
 
     processor_type np = num_processors();
-    map_type map = map_type(Block_dist(np), Block_dist(np), Whole_dist());
+    map_type map = map_type(Block_dist(np), Block_dist(1), Whole_dist());
 
     view_type cube(beams, dbins, gates, map);
     cube = root;
@@ -668,7 +673,7 @@
 
 
     // Verify targets detected
-    cfar_verify(root, located, count);
+    cfar_verify(l_cube, located, count);
 
     delete[] count;
   }
