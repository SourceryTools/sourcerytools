Index: src/Engine/RemoteEngine.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Engine/RemoteEngine.h,v
retrieving revision 1.42
diff -u -u -r1.42 RemoteEngine.h
--- src/Engine/RemoteEngine.h	19 Jan 2004 22:04:33 -0000	1.42
+++ src/Engine/RemoteEngine.h	21 Aug 2004 20:10:06 -0000
@@ -2065,6 +2065,11 @@
     Pooma::scheduler().endGeneration();
 
     csem.wait();
+#if POOMA_MPI
+    // The above single thread waiting has the same problem as with
+    // the MultiPatch variant.  So fix it.
+    Pooma::blockAndEvaluate();
+#endif
 
     RemoteProxy<T> globalRet(ret, computationContext);
     ret = globalRet;  
@@ -2186,6 +2191,27 @@
 
     Pooma::scheduler().endGeneration();
     csem.wait();
+#if POOMA_MPI
+    // We need to wait for Reductions on _all_ contexts to complete
+    // here, as we may else miss to issue a igc update send iterate that a
+    // remote context waits for.  Consider the 2-patch setup
+    //  a,b     |         g|  |          g|
+    // with the expressions
+    //  a(I) = b(I+1);
+    //  bool res = all(a(I) == 0);
+    // here we issue the following iterates:
+    //  0: guard receive from 1 (write request b)
+    //  1: guard send to 0      (read request b)
+    //  0/1: expression iterate (read request b, write request a)
+    //  0/1: reduction (read request a)
+    //  0/1: blocking MPI_XXX
+    // here the guard send from 1 to 0 can be skipped starting the
+    // blocking MPI operation prematurely while context 0 needs to
+    // wait for this send to complete in order to execute the expression.
+    //
+    // The easiest way (and the only available) is to blockAndEvaluate().
+    Pooma::blockAndEvaluate();
+#endif
 
     if (n > 0)
       {
