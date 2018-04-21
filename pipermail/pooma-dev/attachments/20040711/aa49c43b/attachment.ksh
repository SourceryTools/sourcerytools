===== PatchSwapLayout.cpp 1.2 vs edited =====
--- 1.2/r2/src/Particles/PatchSwapLayout.cpp	2004-01-29 10:24:17 +01:00
+++ edited/PatchSwapLayout.cpp	2004-07-11 18:02:48 +02:00
@@ -690,7 +690,7 @@
       POOMA_PATCHSWAPLAYOUT_DBG(dbgmsg << "Invoking swap sync functor ...")
       POOMA_PATCHSWAPLAYOUT_DBG(  << std::endl;)
 
-      Swap_t swapSync( SFun_t(layout_m, particles, SFun_t::syncScan) );
+      Swap_t swapSync( SFun_t(static_cast<Layout_t&>(*this), particles, SFun_t::syncScan) );
       swapSync.block(pos);
     }
 
@@ -709,7 +709,7 @@
     POOMA_PATCHSWAPLAYOUT_DBG(dbgmsg << "Invoking swap scan functor ...")
     POOMA_PATCHSWAPLAYOUT_DBG(  << std::endl;)
 
-    Swap_t swapScan( SFun_t(layout_m, particles, SFun_t::swapScan) );
+    Swap_t swapScan( SFun_t(static_cast<Layout_t&>(*this), particles, SFun_t::swapScan) );
     swapScan.block(pos);
 
     // In case other threads are working on some of the attributes,
@@ -729,7 +729,7 @@
       POOMA_PATCHSWAPLAYOUT_DBG(dbgmsg << "Invoking swap send functor ...")
       POOMA_PATCHSWAPLAYOUT_DBG(  << std::endl;)
 
-      Swap_t swapSend( SFun_t(layout_m, particles, SFun_t::swapSend) );
+      Swap_t swapSend( SFun_t(static_cast<Layout_t&>(*this), particles, SFun_t::swapSend) );
       swapSend.block(pos);
     }
 
@@ -738,7 +738,7 @@
     POOMA_PATCHSWAPLAYOUT_DBG(dbgmsg << "Invoking swap extend functor ...")
     POOMA_PATCHSWAPLAYOUT_DBG(  << std::endl;)
 
-    Swap_t swapExt( SFun_t(layout_m, particles, SFun_t::swapExtend) );
+    Swap_t swapExt( SFun_t(static_cast<Layout_t&>(*this), particles, SFun_t::swapExtend) );
     swapExt.block(pos);
 
     // Now we copy particle data in from our neighboring local patches,
@@ -747,7 +747,7 @@
     POOMA_PATCHSWAPLAYOUT_DBG(dbgmsg << "Invoking swap copy functor ...")
     POOMA_PATCHSWAPLAYOUT_DBG(  << std::endl;)
 
-    Swap_t swapCopy( SFun_t(layout_m, particles, SFun_t::swapCopy) );
+    Swap_t swapCopy( SFun_t(static_cast<Layout_t&>(*this), particles, SFun_t::swapCopy) );
     swapCopy.block(pos);
 
     if (Pooma::contexts() > 1)
@@ -758,7 +758,7 @@
       POOMA_PATCHSWAPLAYOUT_DBG(dbgmsg << "Invoking swap receive functor ...")
       POOMA_PATCHSWAPLAYOUT_DBG(  << std::endl;)
 
-      Swap_t swapReceive( SFun_t(layout_m, particles, SFun_t::swapReceive) );
+      Swap_t swapReceive( SFun_t(static_cast<Layout_t&>(*this), particles, SFun_t::swapReceive) );
       swapReceive.block(pos);
     }
 
@@ -767,7 +767,7 @@
     POOMA_PATCHSWAPLAYOUT_DBG(dbgmsg << "Invoking swap destroy functor ...")
     POOMA_PATCHSWAPLAYOUT_DBG(  << std::endl;)
 
-    Swap_t swapDest( SFun_t(layout_m, particles, SFun_t::swapDestroy) );
+    Swap_t swapDest( SFun_t(static_cast<Layout_t&>(*this), particles, SFun_t::swapDestroy) );
     swapDest.block(pos);
   }
   else if (patchesGlobal == 1 && dosync)
===== PatchSwapLayout.h 1.3 vs edited =====
--- 1.3/r2/src/Particles/PatchSwapLayout.h	2004-01-07 09:54:07 +01:00
+++ edited/PatchSwapLayout.h	2004-07-11 18:06:32 +02:00
@@ -586,11 +586,14 @@
   // Constructors
   //============================================================
 
+  PatchSwapLayout()
+    : patchInfo_m(0) {}
+
   // The main constructor takes a reference to the Layout_t type
   // that we will use in the swap() routine.
 
   PatchSwapLayout(Layout_t &layout)
-    : layout_m(layout), patchInfo_m(0)
+    : patchInfo_m(0)
     {
       contextSizes_m.initialize(Pooma::contexts());
     }
@@ -598,7 +601,7 @@
   // Copy constructor.
 
   PatchSwapLayout(const This_t &p)
-    : layout_m(p.layout_m), patchInfo_m(0)
+    : patchInfo_m(0)
     {
       contextSizes_m.initialize(Pooma::contexts());
     }
@@ -703,11 +706,6 @@
   //============================================================
   // Private data storage
   //============================================================
-
-  // A reference to the layout object that is using this as
-  // a base class.
-
-  Layout_t &layout_m;
 
   // Information about the patches, used in swapping
 
===== UniformLayout.h 1.2 vs edited =====
--- 1.2/r2/src/Particles/UniformLayout.h	2003-10-26 14:35:25 +01:00
+++ edited/UniformLayout.h	2004-07-11 18:07:27 +02:00
@@ -107,8 +107,7 @@
   // The default constructor 
 
   UniformLayout()
-    : Base_t(*this),
-      numPatches_m(Pooma::contexts()),
+    : numPatches_m(Pooma::contexts()),
       numLocalPatches_m(1)
     {
     }
@@ -116,8 +115,7 @@
   // The main constructor, which takes the number of patches.
 
   UniformLayout(int numPatches)
-    : Base_t(*this),
-      numPatches_m(numPatches),
+    : numPatches_m(numPatches),
       numLocalPatches_m(numPatches / Pooma::contexts())
     {
       int remainder = numPatches_m % Pooma::contexts();
@@ -128,8 +126,7 @@
   // Copy constructor.
 
   UniformLayout(const This_t &s)
-    : Base_t(*this),
-      numPatches_m(s.numPatches_m),
+    : numPatches_m(s.numPatches_m),
       numLocalPatches_m(s.numLocalPatches_m)
     {
     }
===== SpatialLayout.h 1.2 vs edited =====
--- 1.2/r2/src/Particles/SpatialLayout.h	2003-10-26 14:35:25 +01:00
+++ edited/SpatialLayout.h	2004-07-11 18:07:03 +02:00
@@ -138,7 +138,6 @@
   // Default constructor.  Initialize with assignment operator.
 
   SpatialLayout()
-    : Base_t(*this)
     {
       // The Mesh and Layout dimensions must be consistent
 
@@ -149,8 +148,7 @@
   // This class will make copies of these objects.
 
   SpatialLayout(const Mesh_t &mesh, const FieldLayout_t &layout)
-    : Base_t(*this), 
-      mesh_m(mesh),
+    : mesh_m(mesh),
       fieldLayout_m(layout)
     {
       // The Mesh and Layout dimensions must be consistent
@@ -161,8 +159,7 @@
   // Copy constructor.
 
   SpatialLayout(const This_t &s)
-    : Base_t(*this), 
-      mesh_m(s.mesh()),
+    : mesh_m(s.mesh()),
       fieldLayout_m(s.layout())
     {
       // The Mesh and Layout dimensions must be consistent
@@ -180,6 +177,22 @@
       return *this;
     }
 
+  void initialize(const This_t &s)
+    {
+      mesh_m = s.mesh();
+      fieldLayout_m = s.layout();
+    }
+
+  void initialize(const Mesh_t &mesh, const FieldLayout_t &layout)
+    {
+      mesh_m = mesh;
+      fieldLayout_m = layout;
+    }
+
+  bool initialized() const
+    {
+      return fieldLayout_m.initialized();
+    }
 
   //============================================================
   // Destructor
