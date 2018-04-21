===== Div.h 1.2 vs edited =====
--- 1.2/r2/src/Field/DiffOps/Div.h	2003-10-26 14:35:20 +01:00
+++ edited/Div.h	2004-07-15 23:07:09 +02:00
@@ -54,8 +54,8 @@
  * centerings, for specific coordinate systems, and different finite-difference
  * orders, are defined in other headers like Div.[URM,RM].h .
  * 
- * div(): Divergence. Takes a ConstField of Vectors (or Tensors) on a 
- * discrete geometry with one centering and returns a ConstField of
+ * div(): Divergence. Takes a Field of Vectors (or Tensors) on a 
+ * discrete geometry with one centering and returns a Field of
  * scalars (or Vectors) on a geometry that's the same except
  * (possibly) for the centering. All the work happens in the embedded
  * Div functor partial specialization, in its operator() methods.
===== Div.UR.h 1.2 vs edited =====
--- 1.2/r2/src/Field/DiffOps/Div.UR.h	2003-10-26 14:35:20 +01:00
+++ edited/Div.UR.h	2004-07-15 23:49:19 +02:00
@@ -150,8 +150,7 @@
 
   DivVertToCell()
   {
-    int d;
-    for (d = 0; d < Dim; ++d)
+    for (int d = 0; d < Dim; ++d)
     {
       fact_m(d) = 1.0;
     }
@@ -160,8 +159,7 @@
   template<class FE>
   DivVertToCell(const FE &fieldEngine)
   {
-    int d;
-    for (d = 0; d < Dim; ++d)
+    for (int d = 0; d < Dim; ++d)
     {
       fact_m(d) = 1 / fieldEngine.mesh().spacings()(d);
     }
@@ -178,51 +176,27 @@
   inline OutputElement_t
   operator()(const F &f, int i1) const
   {
-    return
-      fact_m(0) *
-      (f(i1 + 1)(0) - f(i1)(0));
+    return OutputElement_t
+      (fact_m(0) * (f.read(i1+1)(0) - f.read(i1)(0)));
   }
 
   template<class F>
   inline OutputElement_t
   operator()(const F &f, int i1, int i2) const
   {
-    return 0.5 *
-      (fact_m(0) *
-       (f(i1 + 1, i2    )(0) - f(i1    , i2    )(0) +
-	f(i1 + 1, i2 + 1)(0) - f(i1    , i2 + 1)(0)
-	) +
-       fact_m(1) *
-       (f(i1    , i2 + 1)(1) - f(i1    , i2    )(1) +
-	f(i1 + 1, i2 + 1)(1) - f(i1 + 1, i2    )(1)
-	)
-       );
+    return OutputElement_t
+      (fact_m(0) * (f.read(i1+1, i2)(0) - f.read(i1, i2)(0))
+       + fact_m(1) * (f.read(i1, i2+1)(1) - f.read(i1, i2)(1)));
   }
 
   template<class F>
   inline OutputElement_t
   operator()(const F &f, int i1, int i2, int i3) const
   {
-    return 0.25 *
-      (fact_m(0) *
-       (f(i1 + 1, i2    , i3    )(0) - f(i1    , i2    , i3    )(0) +
-	f(i1 + 1, i2 + 1, i3    )(0) - f(i1    , i2 + 1, i3    )(0) +
-	f(i1 + 1, i2    , i3 + 1)(0) - f(i1    , i2    , i3 + 1)(0) +
-	f(i1 + 1, i2 + 1, i3 + 1)(0) - f(i1    , i2 + 1, i3 + 1)(0)
-	) +
-       fact_m(1) *
-       (f(i1    , i2 + 1, i3    )(1) - f(i1    , i2    , i3    )(1) +
-	f(i1 + 1, i2 + 1, i3    )(1) - f(i1 + 1, i2    , i3    )(1) +
-	f(i1    , i2 + 1, i3 + 1)(1) - f(i1    , i2    , i3 + 1)(1) +
-	f(i1 + 1, i2 + 1, i3 + 1)(1) - f(i1 + 1, i2    , i3 + 1)(1)
-	) +
-       fact_m(2) *
-       (f(i1    , i2    , i3 + 1)(2) - f(i1    , i2    , i3    )(2) +
-	f(i1 + 1, i2    , i3 + 1)(2) - f(i1 + 1, i2    , i3    )(2) +
-	f(i1    , i2 + 1, i3 + 1)(2) - f(i1    , i2 + 1, i3    )(2) +
-	f(i1 + 1, i2 + 1, i3 + 1)(2) - f(i1 + 1, i2 + 1, i3    )(2)
-	)
-       );
+    return OutputElement_t
+      (fact_m(0) * (f.read(i1+1, i2, i3)(0) - f.read(i1, i2, i3)(0))
+       + fact_m(1) * (f.read(i1, i2+1, i3)(1) - f.read(i1, i2, i3)(1))
+       + fact_m(1) * (f.read(i1, i2, i3+1)(2) - f.read(i1, i2, i3)(2)));
   }
 
 private:
@@ -230,6 +204,90 @@
   Vector<Dim, TM> fact_m;
 };
 
+
+template<class T2, class Mesh>
+class DivCellToVert;
+
+template<class T2, int Dim, class TM>
+class DivCellToVert<Vector<Dim, T2>, UniformRectilinearMesh<Dim, TM> >
+{
+public:
+
+  typedef T2   OutputElement_t;
+
+  Centering<Dim> outputCentering() const
+  {
+    return canonicalCentering<Dim>(VertexType, Continuous, AllDim);
+  }
+
+  Centering<Dim> inputCentering() const
+  {
+    return canonicalCentering<Dim>(CellType, Continuous, AllDim);
+  }
+
+  // 
+  // Constructors.
+  // 
+
+  // default version is required by default stencil engine constructor.
+
+  DivCellToVert()
+  {
+    for (int d = 0; d < Dim; ++d)
+    {
+      fact_m(d) = 1.0;
+    }
+  }
+
+  template<class FE>
+  DivCellToVert(const FE &fieldEngine)
+  {
+    for (int d = 0; d < Dim; ++d)
+    {
+      fact_m(d) = 1 / fieldEngine.mesh().spacings()(d);
+    }
+  }
+
+  //
+  // Methods.
+  //
+
+  int lowerExtent(int d) const { return 1; }
+  int upperExtent(int d) const { return 0; }
+      
+  template<class F>
+  inline OutputElement_t
+  operator()(const F &f, int i1) const
+  {
+    return OutputElement_t
+      (fact_m(0) * (f.read(i1)(0) - f.read(i1-1)(0)));
+  }
+
+  template<class F>
+  inline OutputElement_t
+  operator()(const F &f, int i1, int i2) const
+  {
+    return OutputElement_t
+      (fact_m(0) * (f.read(i1, i2)(0) - f.read(i1-1, i2)(0))
+       + fact_m(1) * (f.read(i1, i2)(1) - f.read(i1, i2-1)(1)));
+  }
+
+  template<class F>
+  inline OutputElement_t
+  operator()(const F &f, int i1, int i2, int i3) const
+  {
+    return OutputElement_t
+      (fact_m(0) * (f.read(i1, i2, i3)(0) - f.read(i1-1, i2, i3)(0))
+       + fact_m(1) * (f.read(i1, i2, i3)(1) - f.read(i1, i2-1, i3)(1))
+       + fact_m(1) * (f.read(i1, i2, i3)(2) - f.read(i1, i2, i3-1)(2)));
+  }
+
+private:
+
+  Vector<Dim, TM> fact_m;
+};
+
+
 template<class T2, class Mesh, CenteringType OC>
 class DivSameToSame;
 
@@ -247,7 +305,7 @@
 
   Centering<Dim> inputCentering() const
   {
-    return inputCentering_m;
+    return canonicalCentering<Dim>(OC, Continuous);
   }
 
   // 
@@ -258,8 +316,7 @@
 
   DivSameToSame()
   {
-    int d;
-    for (d = 0; d < Dim; ++d)
+    for (int d = 0; d < Dim; ++d)
     {
       fact_m(d) = 0.5;
     }
@@ -268,15 +325,10 @@
   template<class FE>
   DivSameToSame(const FE &fieldEngine)
   {
-    int d;
-    for (d = 0; d < Dim; ++d)
+    for (int d = 0; d < Dim; ++d)
     {
       fact_m(d) = 0.5 / fieldEngine.mesh().spacings()(d);
     }
-    inputCentering_m = fieldEngine.centering();
-
-    // FIXME: need operator== for centerings
-    //PAssert(inputCentering_m == outputCentering);
   }
 
   //
@@ -290,41 +342,32 @@
   inline OutputElement_t
   operator()(const F &f, int i1) const
   {
-    return
-      fact_m(0) *
-      (f(i1 + 1)(0) - f(i1 - 1)(0));
+    return OutputElement_t
+      (fact_m(0) * (f.read(i1+1)(0) - f.read(i1-1)(0)));
   }
 
   template<class F>
   inline OutputElement_t
   operator()(const F &f, int i1, int i2) const
   {
-    return
-      (fact_m(0) *
-       (f(i1 + 1, i2    )(0) - f(i1 - 1, i2    )(0)) +
-       fact_m(1) *
-       (f(i1    , i2 + 1)(1) - f(i1    , i2 - 1)(1))
-       );
+    return OutputElement_t
+      (fact_m(0) * (f.read(i1+1, i2)(0) - f.read(i1-1, i2)(0))
+       + fact_m(1) * (f.read(i1, i2+1)(1) - f.read(i1, i2-1)(1)));
   }
 
   template<class F>
   inline OutputElement_t
   operator()(const F &f, int i1, int i2, int i3) const
   {
-    return
-      (fact_m(0) *
-       (f(i1 + 1, i2    , i3    )(0) - f(i1 - 1, i2    , i3    )(0)) +
-       fact_m(1) *
-       (f(i1    , i2 + 1, i3    )(1) - f(i1    , i2 - 1, i3    )(1)) +
-       fact_m(2) *
-       (f(i1    , i2    , i3 + 1)(2) - f(i1    , i2    , i3 - 1)(2))
-       );
+    return OutputElement_t
+      (fact_m(0) * (f.read(i1+1, i2, i3)(0) - f.read(i1-1, i2, i3)(0))
+       + fact_m(1) * (f.read(i1, i2+1, i3)(1) - f.read(i1, i2-1, i3)(1))
+       + fact_m(2) * (f.read(i1, i2, i3+1)(2) - f.read(i1, i2, i3-1)(2)));
   }
 
 private:
 
   Vector<Dim, TM> fact_m;
-  Centering<Dim> inputCentering_m;
 };
 
 #endif     // POOMA_FIELD_DIFFOPS_DIV_UR_H
