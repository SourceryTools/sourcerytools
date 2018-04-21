? benchmarks/fft_ffmpeg.cpp
? benchmarks/hpec-corner-turn.cpp
? benchmarks/xgs.cpp
Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.499
diff -u -r1.499 ChangeLog
--- ChangeLog	8 Jun 2006 18:54:42 -0000	1.499
+++ ChangeLog	8 Jun 2006 21:27:19 -0000
@@ -1,5 +1,18 @@
 2006-06-08  Jules Bergmann  <jules@codesourcery.com>
 
+	* benchmarks/hpec_kernel/cfar.cpp:
+	  (t_cfar_base): Raise mu to 100, change to error on false-postive,
+	  false-negative OK.
+	  (t_cfar_by_slice): Change multi-op expressions to +=/-= form.
+	  Break large indexbool expression into smaller expressions for
+	  dispatch.  Make cube dim-order a template parameter, use
+	  <2, 0, 1> as default.
+	  (t_cfar_by_vector): Reset sum to zero for each vector, reuse
+	  single vector from cpow for storing sq, use vec.get(i) instead
+	  of vec(i).
+
+2006-06-08  Jules Bergmann  <jules@codesourcery.com>
+
 	* benchmarks/vmul.cpp: Add documentation for benchmark cases.
 	* src/vsip/impl/subblock.hpp: Fix bug in how dimension-order for
 	  a Sliced_block is determined.
Index: benchmarks/hpec_kernel/cfar.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/benchmarks/hpec_kernel/cfar.cpp,v
retrieving revision 1.2
diff -u -r1.2 cfar.cpp
--- benchmarks/hpec_kernel/cfar.cpp	8 Jun 2006 18:21:54 -0000	1.2
+++ benchmarks/hpec_kernel/cfar.cpp	8 Jun 2006 21:27:19 -0000
@@ -32,6 +32,8 @@
   Included Files
 ***********************************************************************/
 
+#include <iostream>
+
 #include <vsip/initfin.hpp>
 #include <vsip/support.hpp>
 #include <vsip/tensor.hpp>
@@ -60,7 +62,7 @@
 template <typename T>
 struct t_cfar_base
 {
-  int ops_per_point(length_type size)
+  int ops_per_point(length_type /*size*/)
   { 
     int ops = Ops_info<T>::sqr + Ops_info<T>::mul
         + 4 * Ops_info<T>::add + Ops_info<T>::div; 
@@ -159,7 +161,11 @@
                          located.row(i)(j)[1], i) == T(50.0) );
           ++total_found;
         }
-      test_assert( total_found == this->ntargets_ );
+      // Warn if we don't find all the targets.
+      if( total_found != this->ntargets_ )
+	std::cerr << "only found " << total_found
+		  << " out of " << this->ntargets_
+		  << std::endl;
     }
   }
 
@@ -176,7 +182,8 @@
 };
 
 
-template <typename T>
+template <typename T,
+	  typename OrderT = tuple<2, 0, 1> >
 struct t_cfar_by_slice : public t_cfar_base<T>
 {
   char* what() { return "t_cfar_by_slice"; }
@@ -192,12 +199,14 @@
 
 
   template <typename Block1,
-            typename Block2>
+            typename Block2,
+            typename Block3>
   void
   cfar_detect(
     Tensor<T, Block1>  cube,
     Tensor<T, Block1>  cpow,
     Matrix<T, Block2>  sum,
+    Matrix<T, Block3>  tmp,
     Matrix<Index<2> >  located,
     length_type        count[])
   {
@@ -238,20 +247,23 @@
       else if ( k < (g + 1) )
       {
         gates_used = c;
-        sum += cpow(dom_1, dom_2, k+g+c)   - cpow(dom_1, dom_2, k+g);
+        sum += cpow(dom_1, dom_2, k+g+c);
+	sum -= cpow(dom_1, dom_2, k+g);
       }
       // Case 2: Some cells included on left side of CFAR;
       // close to left boundary 
       else
       {
         gates_used = c + k - (g + 1);
-        sum += cpow(dom_1, dom_2, k+g+c)   - cpow(dom_1, dom_2, k+g) 
-          + cpow(dom_1, dom_2, k-(g+1));
+        sum += cpow(dom_1, dom_2, k+g+c);
+	sum -= cpow(dom_1, dom_2, k+g);
+	sum += cpow(dom_1, dom_2, k-(g+1));
       }
       T inv_gates = (1.0 / gates_used);
-      count[k] = impl::indexbool( (cpow(dom_1, dom_2, k) / 
-        max((sum * inv_gates), Precision_traits<T>::eps) > this->mu_), 
-        located.row(k) );
+      tmp = sum * inv_gates;
+      tmp = max(tmp, Precision_traits<T>::eps);
+      tmp = cpow(dom_1, dom_2, k) / tmp;
+      count[k] = impl::indexbool( tmp > this->mu_, located.row(k) );
     }
 
     for ( k = (g + c + 1); (k + (g + c)) < gates; ++k )
@@ -259,13 +271,16 @@
       // Case 3: All cells included on left and right side of CFAR
       // somewhere in the middle of the range vector
       gates_used = 2 * c;
-      sum += cpow(dom_1, dom_2, k+g+c)     - cpow(dom_1, dom_2, k+g) 
-           + cpow(dom_1, dom_2, k-(g+1))   - cpow(dom_1, dom_2, k-(c+g+1));
+      sum += cpow(dom_1, dom_2, k+g+c);
+      sum -= cpow(dom_1, dom_2, k+g);
+      sum += cpow(dom_1, dom_2, k-(g+1));
+      sum -= cpow(dom_1, dom_2, k-(c+g+1));
 
       T inv_gates = (1.0 / gates_used);
-      count[k] = impl::indexbool( (cpow(dom_1, dom_2, k) / 
-        max((sum * inv_gates), Precision_traits<T>::eps) > this->mu_), 
-        located.row(k) );
+      tmp = sum * inv_gates;
+      tmp = max(tmp, Precision_traits<T>::eps);
+      tmp = cpow(dom_1, dom_2, k) / tmp;
+      count[k] = impl::indexbool( tmp > this->mu_, located.row(k) );
     }
 
     for ( k = gates - (g + c); k < gates; ++k )
@@ -275,20 +290,23 @@
       if ( (k + g) < gates )
       {
         gates_used = c + gates - (k + g);
-        sum +=                             - cpow(dom_1, dom_2, k+g) 
-             + cpow(dom_1, dom_2, k-(g+1)) - cpow(dom_1, dom_2, k-(c+g+1));
+        sum -= cpow(dom_1, dom_2, k+g);
+	sum += cpow(dom_1, dom_2, k-(g+1));
+	sum -= cpow(dom_1, dom_2, k-(c+g+1));
       }
       // Case 5: No cell included on right side of CFAR; 
       // very close to right boundary 
       else
       {
         gates_used = c;
-        sum += cpow(dom_1, dom_2, k-(g+1)) - cpow(dom_1, dom_2, k-(c+g+1));
+        sum += cpow(dom_1, dom_2, k-(g+1));
+	sum -= cpow(dom_1, dom_2, k-(c+g+1));
       }
       T inv_gates = (1.0 / gates_used);
-      count[k] = impl::indexbool( (cpow(dom_1, dom_2, k) / 
-        max((sum * inv_gates), Precision_traits<T>::eps) > this->mu_), 
-        located.row(k) );
+      tmp = sum * inv_gates;
+      tmp = max(tmp, Precision_traits<T>::eps);
+      tmp = cpow(dom_1, dom_2, k) / tmp;
+      count[k] = impl::indexbool( tmp > this->mu_, located.row(k) );
     }    
   }
 
@@ -308,7 +326,7 @@
     // Create the distributed views that will give each processor a 
     // subset of the data
     typedef Map<Block_dist, Block_dist, Whole_dist>  map_type;
-    typedef Dense<3, T, row3_type, map_type>         block_type;
+    typedef Dense<3, T, OrderT, map_type>            block_type;
     typedef Tensor<T, block_type>                    view_type;
     typedef typename view_type::local_type           local_type;
 
@@ -321,7 +339,7 @@
     // Create temporary to hold squared values
     view_type cpow(beams, dbins, gates, map);
 #else
-    typedef Dense<3, T, col1_type>  block_type;
+    typedef Dense<3, T, OrderT>     block_type;
     typedef Tensor<T, block_type>   view_type;
     typedef view_type local_type;
     view_type& cube = root;
@@ -339,23 +357,22 @@
     // Create space to hold sums of squares
     typedef Matrix<T>  sum_view_type;
     sum_view_type sum(l_beams, l_dbins);
+    sum_view_type tmp(l_beams, l_dbins);
 
     // And a place to hold found targets
     Matrix<Index<2> > located(gates, this->ntargets_, Index<2>());
     length_type *count = new length_type[gates];
-
     
     // Run the test and time it
     vsip::impl::profile::Timer t1;
     t1.start();
     for (index_type l=0; l<loop; ++l)
     {
-      cfar_detect(l_cube, l_cpow, sum, located, count);
+      cfar_detect(l_cube, l_cpow, sum, tmp, located, count);
     }
     t1.stop();
     time = t1.delta();
 
-
     // Verify targets detected
     cfar_verify(root, located, count);
 
@@ -367,7 +384,7 @@
                      length_type cfar_gates, length_type guard_cells)
    : t_cfar_base<T>(beams, bins),
      cfar_gates_(cfar_gates), guard_cells_(guard_cells), 
-     mu_(2)
+     mu_(100)
   {}
 
 public:
@@ -416,23 +433,24 @@
     test_assert( 2 * (c + g) < gates );
 
 
-    // Compute the square of all values in the data cube.  This is 
-    // done in advance once, as the values are needed many times
-    // (approximately twice as many times as the number of guard cells)
-    cpow = sq(cube);
-
     // Clear scratch space used to hold sums of squares and counts for 
     // targets found per gate.
-    T sum = T();
     index_type k;
     for ( k = 0; k < gates; ++k )
       count[k] = 0;
 
+    subvector_type cpow_vec = cpow(0, 0, whole_domain);
 
     for ( index_type i = 0; i < this->beams_; ++i )
       for ( index_type j = 0; j < this->dbins_; ++j )
       {
-        subvector_type cpow_vec = cpow(i, j, whole_domain);
+	T sum = T();
+
+	// Compute the square of all values in the data cube.  This is 
+	// done in advance for each vector once, as the values are needed
+	// many times (approximately twice as many times as the number of
+	// guard cells)
+	cpow_vec = sq(cube(i, j, whole_domain));
 
         for ( k = 0; k < (g + c + 1); ++k )
         {
@@ -441,25 +459,25 @@
           {
             gates_used = c;
             for ( length_type lnd = g; lnd < g + c; ++lnd )
-              sum += cpow_vec(1 + lnd);
+              sum += cpow_vec.get(1 + lnd);
           }
           // Case 1: No cell included on left side of CFAR; 
           // very close to left boundary 
           else if ( k < (g + 1) )
           {
             gates_used = c;
-            sum += cpow_vec(k+g+c)   - cpow_vec(k+g);
+            sum += cpow_vec.get(k+g+c)   - cpow_vec.get(k+g);
           }
           // Case 2: Some cells included on left side of CFAR;
           // close to left boundary 
           else
           {
             gates_used = c + k - (g + 1);
-            sum += cpow_vec(k+g+c)   - cpow_vec(k+g) 
-                 + cpow_vec(k-(g+1));
+            sum += cpow_vec.get(k+g+c)   - cpow_vec.get(k+g) 
+                 + cpow_vec.get(k-(g+1));
           }
           T inv_gates = (1.0 / gates_used);
-          if ( cpow_vec(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
+          if ( cpow_vec.get(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
                this->mu_ )
             located.row(k).put(count[k]++, Index<2>(i, j));
         }
@@ -470,10 +488,10 @@
         {
           // Case 3: All cells included on left and right side of CFAR;
           // somewhere in the middle of the range vector
-          sum += cpow_vec(k+g+c)     - cpow_vec(k+g) 
-               + cpow_vec(k-(g+1))   - cpow_vec(k-(c+g+1));
+          sum += cpow_vec.get(k+g+c)     - cpow_vec.get(k+g) 
+               + cpow_vec.get(k-(g+1))   - cpow_vec.get(k-(c+g+1));
 
-          if ( cpow_vec(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
+          if ( cpow_vec.get(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
                this->mu_ )
             located.row(k).put(count[k]++, Index<2>(i, j));
         }
@@ -485,18 +503,18 @@
           if ( (k + g) < gates )
           {
             gates_used = c + gates - (k + g);
-            sum +=                             - cpow_vec(k+g) 
-                 + cpow_vec(k-(g+1)) - cpow_vec(k-(c+g+1));
+            sum +=                             - cpow_vec.get(k+g) 
+                 + cpow_vec.get(k-(g+1)) - cpow_vec.get(k-(c+g+1));
           }
           // Case 5: No cell included on right side of CFAR; 
           // very close to right boundary 
           else
           {
             gates_used = c;
-            sum += cpow_vec(k-(g+1)) - cpow_vec(k-(c+g+1));
+            sum += cpow_vec.get(k-(g+1)) - cpow_vec.get(k-(c+g+1));
           }
           T inv_gates = (1.0 / gates_used);
-          if ( cpow_vec(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
+          if ( cpow_vec.get(k) / max((sum * inv_gates), Precision_traits<T>::eps) >
                this->mu_ )
             located.row(k).put(count[k]++, Index<2>(i, j));
         }    
@@ -543,8 +561,8 @@
 
     local_type l_cube = LOCAL(cube);
     local_type l_cpow = LOCAL(cpow);
-    length_type l_beams  = l_cube.size(0);
-    length_type l_dbins  = l_cube.size(1);
+    // length_type l_beams  = l_cube.size(0);
+    // length_type l_dbins  = l_cube.size(1);
     test_assert( gates == l_cube.size(2) );
 
     // And a place to hold found targets
@@ -574,7 +592,7 @@
                      length_type cfar_gates, length_type guard_cells)
    : t_cfar_base<T>(beams, bins),
      cfar_gates_(cfar_gates), guard_cells_(guard_cells), 
-     mu_(2)
+     mu_(100)
   {}
 
 public:
