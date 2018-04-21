Index: PatchSwapLayout.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Particles/PatchSwapLayout.h,v
retrieving revision 1.21
diff -u -u -r1.21 PatchSwapLayout.h
--- PatchSwapLayout.h	14 Jul 2004 15:44:59 -0000	1.21
+++ PatchSwapLayout.h	14 Jul 2004 20:19:21 -0000
@@ -587,7 +587,10 @@
   //============================================================
 
   PatchSwapLayout()
-    : patchInfo_m(0) {}
+    : patchInfo_m(0)
+    {
+      contextSizes_m.initialize(Pooma::contexts());
+    }
 
   // The main constructor takes a reference to the Layout_t type
   // that we will use in the swap() routine.
