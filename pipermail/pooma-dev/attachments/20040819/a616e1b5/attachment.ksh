Index: src/Layout/GuardLayers.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Layout/GuardLayers.h,v
retrieving revision 1.10
diff -u -u -r1.10 GuardLayers.h
--- src/Layout/GuardLayers.h	26 Oct 2003 11:28:11 -0000	1.10
+++ src/Layout/GuardLayers.h	19 Aug 2004 21:15:39 -0000
@@ -123,12 +123,16 @@
   
   int lower(int i) const
   { 
+#if POOMA_BOUNDS_CHECK
     PInsist(i<Dim&&i>=0," GuardLayers index out of range ");
+#endif
     return lower_m[i]; 
   }
   int upper(int i) const 
   {   
+#if POOMA_BOUNDS_CHECK
     PInsist(i<Dim&&i>=0," GuardLayers index out of range ");
+#endif
     return upper_m[i]; 
   }
   
@@ -138,12 +142,16 @@
   
   int &lower(int i) 
   {    
+#if POOMA_BOUNDS_CHECK
     PInsist(i<Dim&&i>=0," GuardLayers index out of range ");
+#endif
     return lower_m[i]; 
   }
   int &upper(int i) 
   {    
+#if POOMA_BOUNDS_CHECK
     PInsist(i<Dim&&i>=0," GuardLayers index out of range ");
+#endif
     return upper_m[i]; 
   }
   
