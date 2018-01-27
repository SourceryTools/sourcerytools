Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.429
diff -u -r1.429 ChangeLog
--- ChangeLog	12 Apr 2006 13:46:42 -0000	1.429
+++ ChangeLog	12 Apr 2006 13:50:05 -0000
@@ -1,5 +1,9 @@
 2006-04-11  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/impl/solver-svd.hpp: Document flop counts.
+
+2006-04-11  Jules Bergmann  <jules@codesourcery.com>
+
 	* benchmarks/loop.hpp: Add '-single' mode, runs a single benchmark
 	  size with a loop count of 1.  Add centered sweep that scales
 	  problem size so that 2^10 ~ desired size.
Index: src/vsip/impl/solver-svd.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/solver-svd.hpp,v
retrieving revision 1.3
diff -u -r1.3 solver-svd.hpp
--- src/vsip/impl/solver-svd.hpp	10 Feb 2006 22:24:02 -0000	1.3
+++ src/vsip/impl/solver-svd.hpp	12 Apr 2006 13:50:05 -0000
@@ -451,7 +451,8 @@
   }
 
   
-  // Step 2: Generate real orthoganol/unitary matrices Q and P'
+  // Step 2: Generate real orthoganol (complex unitary) matrices Q and P'
+  //         determined by gebrd.
 
   if (ust_ == svd_uvfull || ust_ == svd_uvpart)
   {
@@ -471,6 +472,13 @@
 		ext_q.data(), ext_q.stride(1),	// A, lda
 		&tauq_[0],
 		&work_gbr_[0], lwork);
+    // FLOPS:
+    // scalar : To form full Q:
+    //        :    (4/3) n (3m^2 - 3mn + n^2) for m >= n
+    //        :    (4/3) m^3                  for m < n
+    //        : To form n leading columns of Q when m > n:
+    //        :    (2/3) n^2 (3m - n^2)
+    // complex: 4*
   }
 
 
@@ -492,9 +500,30 @@
 		ext_pt.data(), ext_pt.stride(1),	// A, lda
 		&taup_[0],
 		&work_gbr_[0], lwork);
+    // FLOPS:
+    // scalar : To form full PT:
+    //        :    (4/3) n^3                  for m >= n
+    //        :    (4/3) m (3n^2 - 3mn + n^2) for m < n
+    //        : To form m leading columns of PT when m < n:
+    //        :    (2/3) m^2 (3n - m^2)
+    // complex: 4*
   }
 
 
+  // Step 3: Form singular value decomposition from the bidiagonal matrix B
+  //
+  // Factor bidiagonal matrix B into SVD form:
+  //   B = Q * S * herm(P)
+  //
+  // and optionally apply to Q and PT matrices from step 2
+  //   A = U * B * VT
+  //   A = (U*Q) * S * (herm(P)*VT)
+  //
+  // After this step:
+  //   b_d_ will refer to the singular values,
+  //   q_   will refer to the left singular vectors  (U*Q),
+  //   pt_  will refer to the right singular vectors (herm(P)*VT)
+
   {
     Ext_data<data_block_type> ext_q (q_.block());
     Ext_data<data_block_type> ext_pt(pt_.block());
