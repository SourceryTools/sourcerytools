===== PIC2d.cpp 1.1 vs edited =====
--- 1.1/r2/examples/Particles/PIC2d/PIC2d.cpp	2002-05-13 17:47:24 +02:00
+++ edited/PIC2d.cpp	2004-07-15 23:32:09 +02:00
@@ -36,22 +36,22 @@
 #include "Pooma/Particles.h"
 #include "Pooma/DynamicArrays.h"
 #include "Pooma/Fields.h"
+#include "Field/DiffOps/Grad.h"
+#include "Field/DiffOps/Grad.UR.h"
 #include "Utilities/Inform.h"
 #include <iostream>
 #include <stdlib.h>
 #include <math.h>
 
 // Traits class for Particles object
-template <class EngineTag, class Centering, class MeshType, class FL,
-          class InterpolatorTag>
+template <class EngineTag, class FL, class Mesh, class InterpolatorTag>
 struct PTraits
 {
   // The type of engine to use in the attributes
   typedef EngineTag AttributeEngineTag_t;
 
   // The type of particle layout to use
-  typedef SpatialLayout<DiscreteGeometry<Centering,MeshType>,FL> 
-    ParticleLayout_t;
+  typedef SpatialLayout<Mesh, FL> ParticleLayout_t;
 
   // The type of interpolator to use
   typedef InterpolatorTag InterpolatorTag_t;
@@ -95,32 +95,26 @@
 static const int PDim = 2;
 
 // Engine tag type for attributes
-#if POOMA_CHEETAH
+#if POOMA_MESSAGING
 typedef MultiPatch< DynamicTag, Remote<Dynamic> > AttrEngineTag_t;
 #else
 typedef MultiPatch<DynamicTag,Dynamic> AttrEngineTag_t;
 #endif
 
 // Mesh type
-typedef UniformRectilinearMesh<PDim,Cartesian<PDim>,double> Mesh_t;
-
-// Centering of Field elements on mesh
-typedef Cell Centering_t;
-
-// Geometry type for Fields
-typedef DiscreteGeometry<Centering_t,Mesh_t> Geometry_t;
+typedef UniformRectilinearMesh<PDim,double> Mesh_t;
 
 // Field types
-#if POOMA_CHEETAH
-typedef Field< Geometry_t, double,
-               MultiPatch< UniformTag, Remote<Brick> > > DField_t;
-typedef Field< Geometry_t, Vector<PDim,double>,
-               MultiPatch< UniformTag, Remote<Brick> > > VecField_t;
+#if POOMA_MESSAGING
+typedef Field< Mesh_t, double,
+               MultiPatch< GridTag, Remote<Brick> > > DField_t;
+typedef Field< Mesh_t, Vector<PDim,double>,
+               MultiPatch< GridTag, Remote<Brick> > > VecField_t;
 #else
-typedef Field< Geometry_t, double,
-               MultiPatch<UniformTag,Brick> > DField_t;
-typedef Field< Geometry_t, Vector<PDim,double>,
-               MultiPatch<UniformTag,Brick> > VecField_t;
+typedef Field< Mesh_t, double,
+               MultiPatch<GridTag,Brick> > DField_t;
+typedef Field< Mesh_t, Vector<PDim,double>,
+               MultiPatch<GridTag,Brick> > VecField_t;
 #endif
 
 // Field layout type, derived from Engine type
@@ -131,7 +125,7 @@
 typedef NGP InterpolatorTag_t;
 
 // Particle traits class
-typedef PTraits<AttrEngineTag_t,Centering_t,Mesh_t,FLayout_t,
+typedef PTraits<AttrEngineTag_t,FLayout_t,Mesh_t,
                 InterpolatorTag_t> PTraits_t;
 
 // Type of particle layout
@@ -170,34 +164,35 @@
 
   // Create mesh and geometry objects for cell-centered fields.
   Interval<PDim> meshDomain(nx+1,ny+1);
-  Mesh_t mesh(meshDomain);
-  Geometry_t geometry(mesh);
 
   // Create a second geometry object that includes a guard layer.
   GuardLayers<PDim> gl(1);
-  Geometry_t geometryGL(mesh,gl);
 
   // Create field layout objects for our electrostatic potential
   // and our electric field.  Decomposition is 4 x 4.
   Loc<PDim> blocks(4,4);
-  FLayout_t flayout(geometry.physicalDomain(),blocks,DistributedTag());
-  FLayout_t flayoutGL(geometryGL.physicalDomain(),blocks,gl,DistributedTag());
+  FLayout_t flayout(meshDomain,blocks,DistributedTag());
+  FLayout_t flayoutGL(meshDomain,blocks,gl,DistributedTag());
+
+  Mesh_t mesh(flayout);
+
+  Centering<PDim> cell = canonicalCentering<PDim>(CellType, Continuous);
 
   // Create and initialize electrostatic potential and electric field.
-  DField_t phi(geometryGL,flayoutGL);
-  VecField_t EFD(geometry,flayout);
+  DField_t phi(cell,flayoutGL,mesh);
+  VecField_t EFD(cell,flayout,mesh);
 
   // potential phi = phi0 * sin(2*pi*x/Lx) * cos(4*pi*y/Ly)
   // Note that phi is a periodic Field
   // Electric field EFD = -grad(phi);
-  Pooma::addAllPeriodicFaceBC(phi, 0.0);
+  Pooma::addAllPeriodicFaceBC(phi);
   double phi0 = 0.01 * static_cast<double>(nx);
-  phi = phi0 * sin(2.0*pi*phi.x().comp(0)/nx)
-             * cos(4.0*pi*phi.x().comp(1)/ny);
-  EFD = -grad<Centering_t>(phi);
+  phi = phi0 * sin(2.0*pi*iota(phi.physicalDomain()).comp(0)/nx)
+             * cos(4.0*pi*iota(phi.physicalDomain()).comp(1)/ny);
+  EFD = -gradCellToCell(phi);
 
   // Create a particle layout object for our use
-  PLayout_t layout(geometry,flayout);
+  PLayout_t layout(mesh,flayout);
 
   // Create a Particles object and set periodic boundary conditions
   Particles_t P(layout);
