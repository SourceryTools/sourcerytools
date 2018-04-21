Index: Tiny/Tensor.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Tiny/Tensor.h,v
retrieving revision 1.46
diff -u -u -r1.46 Tensor.h
--- Tiny/Tensor.h	21 Oct 2003 19:50:04 -0000	1.46
+++ Tiny/Tensor.h	25 May 2004 18:08:09 -0000
@@ -337,7 +337,7 @@
 
 
   // Output to a stream.
-  // The format is: ((t(0,0) t(1,0),... ) ( t(0,1) t(1,1) ... ) ... ))
+  // The format is: ((t(0,0) t(0,1),... ) ( t(1,0) t(1,1) ... ) ... ))
 
   template<class Out>
   void print(Out &out) const
@@ -379,7 +379,7 @@
 
 
 /// Output to a stream.
-/// The format is: ( ( t(0,0) t(1,0),... ) ( t(0,1) t(1,1) ... ) ... )
+/// The format is: ( ( t(0,0) t(0,1),... ) ( t(1,0) t(1,1) ... ) ... )
 
 template<int D, class T, class E>
 std::ostream &operator<<(std::ostream &out, const Tensor<D,T,E> &t)
Index: Tiny/TinyMatrix.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Tiny/TinyMatrix.h,v
retrieving revision 1.16
diff -u -u -r1.16 TinyMatrix.h
--- Tiny/TinyMatrix.h	21 Oct 2003 19:50:04 -0000	1.16
+++ Tiny/TinyMatrix.h	25 May 2004 18:08:09 -0000
@@ -213,7 +213,7 @@
 
 
   // Output to a stream.
-  // The format is: ((t(0,0) t(1,0),... ) (t(0,1) t(1,1) ... ) ... ))
+  // The format is: ((t(0,0) t(0,1),... ) (t(1,0) t(1,1) ... ) ... ))
 
   template<class Out>
   void print(Out &out) const
@@ -225,18 +225,18 @@
     long precision = out.precision();
     out.width(0);
     out << "(";
-    for (int i = 0; i < D2; i++) {
+    for (int i = 0; i < D1; i++) {
       out << "(";
       out.flags(incomingFormatFlags);
       out.width(width);
       out.precision(precision);
-      out << (*this)(0, i);
-      for (int j = 1; j < D1; j++) {
+      out << (*this)(i, 0);
+      for (int j = 1; j < D2; j++) {
         out << " ";
         out.flags(incomingFormatFlags);
         out.width(width);
         out.precision(precision);
-        out << (*this)(j, i);
+        out << (*this)(i, j);
       }
       out << ")";
     }
@@ -255,7 +255,7 @@
 
 
 /// Output to a stream.
-/// The format is: ( ( t(0,0) t(1,0),... ) ( t(0,1) t(1,1) ... ) ... )
+/// The format is: ( ( t(0,0) t(0,1),... ) ( t(1,0) t(1,1) ... ) ... )
 
 template<int D1, int D2, class T, class E>
 std::ostream &operator<<(std::ostream &out, const TinyMatrix<D1,D2,T,E> &t)
