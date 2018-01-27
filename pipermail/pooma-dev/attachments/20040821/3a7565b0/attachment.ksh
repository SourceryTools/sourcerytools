Index: src/Transform/PETSc.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Transform/PETSc.h,v
retrieving revision 1.1
diff -u -u -r1.1 PETSc.h
--- src/Transform/PETSc.h	24 Mar 2004 18:26:32 -0000	1.1
+++ src/Transform/PETSc.h	21 Aug 2004 19:13:58 -0000
@@ -109,7 +109,7 @@
     int idx=0;
     Interval<1> d(e.domain());
     for (int I=d.first(); I<=d.last(); ++I)
-      pa[idx++] = e(I);
+      pa[idx++] = e.read(I);
     VecRestoreArray(v, &pa);
   }
   template <class T>
@@ -138,7 +138,7 @@
     Interval<2> d(e.domain());
     for (int J=d[1].first(); J<=d[1].last(); ++J)
       for (int I=d[0].first(); I<=d[0].last(); ++I)
-	pa[idx++] = e(I, J);
+	pa[idx++] = e.read(I, J);
     VecRestoreArray(v, &pa);
   }
   template <class T>
@@ -169,7 +169,7 @@
     for (int K=d[2].first(); K<=d[2].last(); ++K)
       for (int J=d[1].first(); J<=d[1].last(); ++J)
 	for (int I=d[0].first(); I<=d[0].last(); ++I)
-	  pa[idx++] = e(I, J, K);
+	  pa[idx++] = e.read(I, J, K);
     VecRestoreArray(v, &pa);
   }
   template <class T>
@@ -197,12 +197,27 @@
 template <int Dim>
 struct PoomaDA {
 
-  /// Creates a PETSc DA from the specified layout.
+  /// Creates a PETSc DA from the specified array/field/layout.
   /// Extra arguments are like DACreateNd, namely the periodicity
   /// and stencil type and the stencil width.
 
+  template <class T, class EngineTag>
+  PoomaDA(const Array<Dim, T, EngineTag> &a, DAPeriodicType pt, DAStencilType st, int sw)
+  {
+    initialize(a.physicalDomain(), pt, st, sw);
+  }
+
+  template <class MeshTag, class T, class EngineTag>
+  PoomaDA(const Field<MeshTag, T, EngineTag> &f, DAPeriodicType pt, DAStencilType st, int sw)
+  {
+    initialize(f.physicalDomain(), pt, st, sw);
+  }
+
   template <class Layout>
-  PoomaDA(const Layout &l, DAPeriodicType pt, DAStencilType st, int sw);
+  PoomaDA(const Layout &l, DAPeriodicType pt, DAStencilType st, int sw)
+  {
+    initialize(l.innerDomain(), pt, st, sw);
+  }
 
   ~PoomaDA()
   {
@@ -216,6 +231,15 @@
   operator DA() const { return da; }
 
 
+  /// Access PeriodicType.
+
+  DAPeriodicType periodicType() const { return info[0].pt; }
+
+  /// Access StencilType.
+
+  DAStencilType stencilType() const { return info[0].st; }
+
+
   /// Assign from POOMA engine to PETSc vector.
 
   template <class T, class EngineTag>
@@ -234,6 +258,7 @@
   template <class MeshTag, class T, class EngineTag>
   void assign(Vec v, const Field<MeshTag, T, EngineTag> &f)
   {
+    forEach(f, PerformUpdateTag(), NullCombine());
     this->assign(v, f.fieldEngine().engine());
   }
 
@@ -257,8 +282,12 @@
   void assign(const Field<MeshTag, T, EngineTag> &f, Vec v)
   {
     this->assign(f.fieldEngine().engine(), v);
+    f.notifyPostWrite();
   }
 
+protected:
+  void initialize(const Interval<Dim> &d, DAPeriodicType pt, DAStencilType st, int sw);
+
 
 private:
   DA da;
@@ -270,11 +299,10 @@
 
 
 template <int Dim>
-template <class Layout>
-PoomaDA<Dim>::PoomaDA(const Layout &l, DAPeriodicType pt, DAStencilType st, int sw)
-  : offset(Loc<Dim>(0))
+void PoomaDA<Dim>::initialize(const Interval<Dim> &d, DAPeriodicType pt, DAStencilType st, int sw)
 {
-  Interval<Dim> domain = l.innerDomain();
+  offset = Loc<Dim>(0);
+  Interval<Dim> domain = d;
   if (pt != DA_XPERIODIC
       && pt != DA_XYPERIODIC
       && pt != DA_XYZPERIODIC
@@ -370,7 +398,7 @@
         Interval<Dim> lPatch(PoomaDAGetDomain<Dim>::innerDomain(this->info[i]));
 	Array<Dim, T, Remote<Brick> > a;
 	a.engine() = Engine<Dim, T, Remote<Brick> >(i, lPatch);
-	Array<Dim, T, typename ViewEngine_t::Tag_t> e_array(ViewEngine_t(e, lPatch - this->offset));
+	Array<Dim, T, typename ViewEngine_t::Tag_t> e_array(ViewEngine_t(e, lPatch + this->offset));
 	a = e_array;
 
 	// remember local engine
@@ -414,7 +442,7 @@
 
 	// distribute the copy
 	Array<Dim, T, typename ViewEngine_t::Tag_t> e_array;
-	e_array.engine() = ViewEngine_t(e, lPatch - this->offset);
+	e_array.engine() = ViewEngine_t(e, lPatch + this->offset);
 	e_array = a;
   }
 }
