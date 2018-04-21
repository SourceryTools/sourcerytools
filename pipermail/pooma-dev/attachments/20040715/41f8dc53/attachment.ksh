Index: examples/Particles/PIC2d/PIC2d.cpp
===================================================================
RCS file: /home/pooma/Repository/r2/examples/Particles/PIC2d/PIC2d.cpp,v
retrieving revision 1.19
diff -u -r1.19 PIC2d.cpp
--- examples/Particles/PIC2d/PIC2d.cpp	21 Sep 2001 20:27:21 -0000	1.19
+++ examples/Particles/PIC2d/PIC2d.cpp	15 Jul 2004 16:33:33 -0000
@@ -33,16 +33,23 @@
 // static electric field using nearest-grid-point interpolation.
 //-----------------------------------------------------------------------------
 
+#include "Field/FieldCentering.h"
+#include "Field/DiffOps/Grad.h"
+#include "Field/DiffOps/Grad.UR.h"
+#include "Particles/InterpolatorNGP.h"
+#include "Particles/Interpolation.h"
 #include "Pooma/Particles.h"
 #include "Pooma/DynamicArrays.h"
 #include "Pooma/Fields.h"
 #include "Utilities/Inform.h"
+#include "Pooma/Indices.h"
+
 #include <iostream>
 #include <stdlib.h>
 #include <math.h>
 
 // Traits class for Particles object
-template <class EngineTag, class Centering, class MeshType, class FL,
+template <class EngineTag, class MeshType, class FL,
           class InterpolatorTag>
 struct PTraits
 {
@@ -50,7 +57,7 @@
   typedef EngineTag AttributeEngineTag_t;
 
   // The type of particle layout to use
-  typedef SpatialLayout<DiscreteGeometry<Centering,MeshType>,FL> 
+  typedef SpatialLayout<MeshType,FL> 
     ParticleLayout_t;
 
   // The type of interpolator to use
@@ -87,6 +94,7 @@
   DynamicArray<PointType_t,AttributeEngineTag_t> R;
   DynamicArray<PointType_t,AttributeEngineTag_t> V;
   DynamicArray<PointType_t,AttributeEngineTag_t> E;
+  DynamicArray<PointType_t,AttributeEngineTag_t> phi;
   DynamicArray<double,     AttributeEngineTag_t> qm;
 };
 
@@ -102,24 +110,25 @@
 #endif
 
 // Mesh type
-typedef UniformRectilinearMesh<PDim,Cartesian<PDim>,double> Mesh_t;
+typedef UniformRectilinearMesh<PDim,/*,Cartesian<PDim>,*/double> Mesh_t;
 
 // Centering of Field elements on mesh
-typedef Cell Centering_t;
+//typedef CanonicalCentering::CellType Centering_t;
+//static const int Centering_t = CanonicalCentering<PDim>::CellType;
 
 // Geometry type for Fields
-typedef DiscreteGeometry<Centering_t,Mesh_t> Geometry_t;
+//typedef DiscreteGeometry<Centering_t,Mesh_t> Geometry_t;
 
 // Field types
 #if POOMA_CHEETAH
-typedef Field< Geometry_t, double,
+typedef Field< Mesh_t, double,
                MultiPatch< UniformTag, Remote<Brick> > > DField_t;
-typedef Field< Geometry_t, Vector<PDim,double>,
+typedef Field< Mesh_t, Vector<PDim,double>,
                MultiPatch< UniformTag, Remote<Brick> > > VecField_t;
 #else
-typedef Field< Geometry_t, double,
+typedef Field< Mesh_t, double,
                MultiPatch<UniformTag,Brick> > DField_t;
-typedef Field< Geometry_t, Vector<PDim,double>,
+typedef Field< Mesh_t, Vector<PDim,double>,
                MultiPatch<UniformTag,Brick> > VecField_t;
 #endif
 
@@ -131,7 +140,7 @@
 typedef NGP InterpolatorTag_t;
 
 // Particle traits class
-typedef PTraits<AttrEngineTag_t,Centering_t,Mesh_t,FLayout_t,
+typedef PTraits<AttrEngineTag_t,Mesh_t,FLayout_t,
                 InterpolatorTag_t> PTraits_t;
 
 // Type of particle layout
@@ -153,7 +162,7 @@
 const double pi = acos(-1.0);
 
 // Maximum value for particle q/m ratio
-const double qmmax = 1.0;
+const double qmmax = 10;//1.0;
 
 // Timestep
 const double dt = 1.0;
@@ -169,35 +178,61 @@
   out << "-------------------------" << std::endl;
 
   // Create mesh and geometry objects for cell-centered fields.
+    Loc<PDim> blocks(4,4);
+    UniformGridPartition<2> partition(
+	    Loc<2>(1, 1),
+	    GuardLayers<2>(1),  // internal
+	    GuardLayers<2>(0)
+				    ); // external  
   Interval<PDim> meshDomain(nx+1,ny+1);
-  Mesh_t mesh(meshDomain);
-  Geometry_t geometry(mesh);
+  FLayout_t flayout(meshDomain,partition,DistributedTag());
+  Mesh_t mesh(flayout, Vector<2>(0.0), Vector<2>(1.0, 1.0));//(meshDomain);
+  Centering<2> cell =
+    canonicalCentering<2>(CellType, Continuous, AllDim);
+  /*Geometry_t geometry(mesh);*/
 
   // Create a second geometry object that includes a guard layer.
-  GuardLayers<PDim> gl(1);
-  Geometry_t geometryGL(mesh,gl);
+//  GuardLayers<PDim> gl(1);
+//  FLayout_t flayoutGL(meshDomain,partition,DistributedTag());
+  /*Geometry_t geometryGL(mesh,gl);*/
 
   // Create field layout objects for our electrostatic potential
   // and our electric field.  Decomposition is 4 x 4.
-  Loc<PDim> blocks(4,4);
-  FLayout_t flayout(geometry.physicalDomain(),blocks,DistributedTag());
-  FLayout_t flayoutGL(geometryGL.physicalDomain(),blocks,gl,DistributedTag());
+//  Loc<PDim> blocks(4,4);
+//  FLayout_t flayout(mesh.physicalDomain(),blocks,DistributedTag());
+//  FLayout_t flayoutGL(geometryGL.physicalDomain(),blocks,gl,DistributedTag());
 
   // Create and initialize electrostatic potential and electric field.
-  DField_t phi(geometryGL,flayoutGL);
-  VecField_t EFD(geometry,flayout);
+  DField_t phi(cell,flayout,mesh);
+  VecField_t EFD(cell,flayout,mesh);
 
   // potential phi = phi0 * sin(2*pi*x/Lx) * cos(4*pi*y/Ly)
   // Note that phi is a periodic Field
   // Electric field EFD = -grad(phi);
-  Pooma::addAllPeriodicFaceBC(phi, 0.0);
+//  Pooma::addAllPeriodicFaceBC(phi, 0.0);
+  phi.addRelation(new Relation0<DField_t,PeriodicFaceBC<PDim> >(phi,PeriodicFaceBC<PDim>(0)));
+  phi.addRelation(new Relation0<DField_t,PeriodicFaceBC<PDim> >(phi,PeriodicFaceBC<PDim>(1)));
+  phi.addRelation(new Relation0<DField_t,PeriodicFaceBC<PDim> >(phi,PeriodicFaceBC<PDim>(2)));
+  phi.addRelation(new Relation0<DField_t,PeriodicFaceBC<PDim> >(phi,PeriodicFaceBC<PDim>(3)));
   double phi0 = 0.01 * static_cast<double>(nx);
-  phi = phi0 * sin(2.0*pi*phi.x().comp(0)/nx)
-             * cos(4.0*pi*phi.x().comp(1)/ny);
-  EFD = -grad<Centering_t>(phi);
+  phi = phi0 * sin(2.0*pi*iota(1,nx).comp(0)/nx)
+             * cos(4.0*pi*iota(1,ny).comp(1)/ny);
+//    phi = 100;
+  EFD = -gradVertToCell(phi);
+
+  PrintArray pa;
+  out << "potential: " << std::endl;
+  pa.setDataWidth(10);
+  pa.setScientific(true);
+  pa.print(out.stream(),phi);
 
+  out << "electric field(to test does grad(phi) work): " << std::endl;
+  pa.setDataWidth(10);
+  pa.setScientific(true);
+  pa.print(out.stream(),EFD);
+  
   // Create a particle layout object for our use
-  PLayout_t layout(geometry,flayout);
+  PLayout_t layout(mesh,flayout);
 
   // Create a Particles object and set periodic boundary conditions
   Particles_t P(layout);
@@ -233,7 +268,6 @@
   out << "---------------------" << std::endl;
 
   // Display the initial particle positions, velocities and qm values.
-  PrintArray pa;
   pa.setCarReturn(5);
   out << "Initial particle data:" << std::endl;
   out << "Particle positions: " << std::endl;
@@ -244,6 +278,11 @@
   pa.setDataWidth(10);
   pa.setScientific(true);
   pa.print(out.stream(),P.V);
+  out << "Field: " << std::endl;
+  pa.setDataWidth(10);
+  pa.setScientific(true);
+  pa.print(out.stream(),P.V);
+
   out << "Particle charge-to-mass ratios: " << std::endl;
   pa.print(out.stream(),P.qm);
 
@@ -266,6 +305,7 @@
     out << "Advance particle velocities ..." << std::endl;
     P.V = P.V + dt * P.qm * P.E;
   }
+//    gather( P.phi, phi, P.R, Particles_t::InterpolatorTag_t() );//joke :0
 
   // Display the final particle positions, velocities and qm values.
   out << "PIC2d timestep loop complete!" << std::endl;
@@ -281,6 +321,11 @@
   pa.print(out.stream(),P.V);
   out << "Particle charge-to-mass ratios: " << std::endl;
   pa.print(out.stream(),P.qm);
+
+  out << "Field: " << std::endl;
+  pa.setDataWidth(10);
+  pa.setScientific(true);
+  pa.print(out.stream(),phi);
 
   // Shut down POOMA and exit
   out << "End PIC2d example code." << std::endl;
Index: src/Particles/Interpolation.cpp
===================================================================
RCS file: /home/pooma/Repository/r2/src/Particles/Interpolation.cpp,v
retrieving revision 1.10
diff -u -r1.10 Interpolation.cpp
--- src/Particles/Interpolation.cpp	14 Jul 2004 15:43:46 -0000	1.10
+++ src/Particles/Interpolation.cpp	15 Jul 2004 16:33:38 -0000
@@ -178,30 +178,9 @@
   Interp_t::scatterValueCache(value,field,cache);
 }
 
-
-template <class Field>
-void setExternalGuards(const Field& f, typename Field::Element_t v)
-{
-  for (int i=0; i<Field::dimensions; ++i) {
-    int d = f.layout().externalGuards().lower(i);
-    if (d>0) {
-      Interval<Field::dimensions> I(f.totalDomain());
-      I[i] = Interval<1>(I[i].first(), I[i].first() + d-1);
-      f(I) = v;
-    }
-    d = f.layout().externalGuards().upper(i);
-    if (d>0) {
-      Interval<Field::dimensions> I(f.totalDomain());
-      I[i] = Interval<1>(I[i].last() - d+1, I[i].last());
-      f(I) = v;
-    }
-  }
-}
-
-
 // ACL:rcsinfo
 // ----------------------------------------------------------------------
-// $RCSfile: Interpolation.cpp,v $   $Author: pooma $
-// $Revision: 1.10 $   $Date: 2004/07/14 15:43:46 $
+// $RCSfile: Interpolation.cpp,v $   $Author: swhaney $
+// $Revision: 1.9 $   $Date: 2000/03/07 13:17:47 $
 // ----------------------------------------------------------------------
 // ACL:rcsinfo
Index: src/Particles/Interpolation.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Particles/Interpolation.h,v
retrieving revision 1.8
diff -u -r1.8 Interpolation.h
--- src/Particles/Interpolation.h	14 Jul 2004 15:43:46 -0000	1.8
+++ src/Particles/Interpolation.h	15 Jul 2004 16:33:38 -0000
@@ -47,18 +47,10 @@
  * and ask it to do the gather or scatter operation.
  */
 
-#include "Evaluator/PatchFunction.h"
-
 //-----------------------------------------------------------------------------
 // Includes:
 //-----------------------------------------------------------------------------
-
-#include "Evaluator/PatchFunction.h"
-
 #include "Evaluator/PatchFunction.h"
-
-#include "Evaluator/PatchFunction.h"
-
 //-----------------------------------------------------------------------------
 // Forward Declarations:
 //-----------------------------------------------------------------------------
@@ -230,10 +222,6 @@
 struct Interpolator;
 
 
-template <class Field>
-void setExternalGuards(const Field&, typename Field::Element_t);
-
-
 #include "Particles/Interpolation.cpp"
 
 
@@ -242,6 +230,6 @@
 // ACL:rcsinfo
 // ----------------------------------------------------------------------
 // $RCSfile: Interpolation.h,v $   $Author: pooma $
-// $Revision: 1.8 $   $Date: 2004/07/14 15:43:46 $
+// $Revision: 1.7 $   $Date: 2003/10/26 12:27:36 $
 // ----------------------------------------------------------------------
 // ACL:rcsinfo
Index: src/Particles/InterpolatorCIC.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Particles/InterpolatorCIC.h,v
retrieving revision 1.11
diff -u -r1.11 InterpolatorCIC.h
--- src/Particles/InterpolatorCIC.h	14 Jul 2004 15:43:46 -0000	1.11
+++ src/Particles/InterpolatorCIC.h	15 Jul 2004 16:33:41 -0000
@@ -55,6 +55,7 @@
 #include "Tiny/Vector.h"
 #include "Utilities/PAssert.h"
 #include "Utilities/ElementProperties.h"
+//#include "Field/FieldFunctions.h"
 
 #include <iostream>
 
@@ -161,7 +162,7 @@
         "Field and Particle Position must have same number of patches!");
 
       // Check that the Field has adequate guard layers for CIC
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.fieldEngine().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -197,7 +198,7 @@
         "Field and Particle Position must have same number of patches!");
 
       // Check that the Field has adequate guard layers for CIC
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.fieldEngine().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -207,7 +208,7 @@
       // Zero out the guard layers before scattering
       typename FC::Element_t zero(0);
       field.engine().setGuards(zero);
-      setExternalGuards(field,zero);
+      //setExternalGuards(field,zero);
 
       // Make sure setExternalGuards has completed before scattering
       Pooma::blockAndEvaluate();
@@ -240,7 +241,7 @@
         "Field and Particle Position must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.mesh().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -290,7 +291,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.mesh().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -329,7 +330,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.mesh().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -374,7 +375,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.mesh().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -421,7 +422,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.mesh().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -458,7 +459,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.mesh().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -501,7 +502,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.mesh().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -667,7 +668,6 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -682,6 +682,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta;
@@ -774,7 +775,6 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -789,6 +789,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta;
@@ -882,7 +883,6 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -896,7 +896,8 @@
       // value into the field elements.
 
       Size_t i;
-      Loc<Dim> indx; 
+      Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta;
@@ -999,7 +1000,6 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -1014,6 +1014,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta;
@@ -1112,7 +1113,6 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -1127,6 +1127,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta;
@@ -1225,7 +1226,6 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -1240,6 +1240,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta;
@@ -1509,6 +1510,6 @@
 // ACL:rcsinfo
 // ----------------------------------------------------------------------
 // $RCSfile: InterpolatorCIC.h,v $   $Author: pooma $
-// $Revision: 1.11 $   $Date: 2004/07/14 15:43:46 $
+// $Revision: 1.10 $   $Date: 2003/10/26 12:27:36 $
 // ----------------------------------------------------------------------
 // ACL:rcsinfo
Index: src/Particles/InterpolatorNGP.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Particles/InterpolatorNGP.h,v
retrieving revision 1.14
diff -u -r1.14 InterpolatorNGP.h
--- src/Particles/InterpolatorNGP.h	14 Jul 2004 15:43:46 -0000	1.14
+++ src/Particles/InterpolatorNGP.h	15 Jul 2004 16:33:44 -0000
@@ -160,7 +160,7 @@
 
       // Create a PatchFunction using this functor
       PatchFunction< NGPGather<FC,Dim>,
-                     PatchParticle2<true,false> > patchfun(intfun);
+        PatchParticle2<true,false> > patchfun(intfun);
       
       // Apply the PatchFunction to the attribute using the
       // particle position attribute
@@ -430,7 +430,6 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -445,7 +444,10 @@
 
       Size_t i;
       Loc<Dim> indx;
-      const Mesh_t& mesh = field_m.mesh();
+        typedef typename Field_t::Mesh_t Mesh_t;
+//      typedef typename Field_t::Mesh_t Mesh_t;
+//      const Mesh_t& geom = field_m.mesh();
+	const Mesh_t& mesh = field_m.mesh();
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
@@ -514,7 +516,6 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -529,6 +530,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       for (i=0; i<n; ++i)
         {
@@ -598,7 +600,6 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -613,6 +614,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       for (i=0; i<n; ++i)
         {
@@ -691,7 +693,6 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -706,6 +707,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       for (i=0; i<n; ++i)
         {
@@ -780,7 +782,6 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -795,6 +796,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       for (i=0; i<n; ++i)
         {
@@ -868,7 +870,6 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -883,6 +884,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       for (i=0; i<n; ++i)
         {
@@ -1125,6 +1127,6 @@
 // ACL:rcsinfo
 // ----------------------------------------------------------------------
 // $RCSfile: InterpolatorNGP.h,v $   $Author: pooma $
-// $Revision: 1.14 $   $Date: 2004/07/14 15:43:46 $
+// $Revision: 1.13 $   $Date: 2003/10/26 12:27:36 $
 // ----------------------------------------------------------------------
 // ACL:rcsinfo
Index: src/Particles/InterpolatorSUDS.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Particles/InterpolatorSUDS.h,v
retrieving revision 1.11
diff -u -r1.11 InterpolatorSUDS.h
--- src/Particles/InterpolatorSUDS.h	14 Jul 2004 15:43:46 -0000	1.11
+++ src/Particles/InterpolatorSUDS.h	15 Jul 2004 16:33:45 -0000
@@ -56,6 +56,7 @@
 #include "Tiny/Vector.h"
 #include "Utilities/PAssert.h"
 #include "Utilities/ElementProperties.h"
+//#include "Field/FieldFunctions.h"
 
 #include <iostream>
 
@@ -162,7 +163,7 @@
         "Field and Particle Position must have same number of patches!");
 
       // Check that the Field has adequate guard layers for SUDS
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.fieldEngine().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -198,7 +199,7 @@
         "Field and Particle Position must have same number of patches!");
 
       // Check that the Field has adequate guard layers for SUDS
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.fieldEngine().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -208,7 +209,7 @@
       // Zero out the guard layers before scattering
       typename FC::Element_t zero(0);
       field.engine().setGuards(zero);
-      setExternalGuards(field,zero);
+//      setExternalGuards(field,zero);
 
       // Make sure setExternalGuards has completed before scattering
       Pooma::blockAndEvaluate();
@@ -241,7 +242,7 @@
         "Field and Particle Position must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.fieldEngine().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -251,7 +252,7 @@
       // Zero out the guard layers before scattering
       typename FC::Element_t zero(0);
       field.engine().setGuards(zero);
-      setExternalGuards(field,zero);
+//      setExternalGuards(field,zero);
 
       // Make sure setExternalGuards has completed before scattering
       Pooma::blockAndEvaluate();
@@ -291,7 +292,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.fieldEngine().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -330,7 +331,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.fieldEngine().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -340,7 +341,7 @@
       // Zero out the guard layers before scattering
       typename FC::Element_t zero(0);
       field.engine().setGuards(zero);
-      setExternalGuards(field,zero);
+//      setExternalGuards(field,zero);
 
       // Make sure setExternalGuards has completed before scattering
       Pooma::blockAndEvaluate();
@@ -375,7 +376,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.fieldEngine().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -385,7 +386,7 @@
       // Zero out the guard layers before scattering
       typename FC::Element_t zero(0);
       field.engine().setGuards(zero);
-      setExternalGuards(field,zero);
+//      setExternalGuards(field,zero);
 
       // Make sure setExternalGuards has completed before scattering
       Pooma::blockAndEvaluate();
@@ -422,7 +423,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.fieldEngine().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -459,7 +460,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.fieldEngine().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -469,7 +470,7 @@
       // Zero out the guard layers before scattering
       typename FC::Element_t zero(0);
       field.engine().setGuards(zero);
-      setExternalGuards(field,zero);
+//      setExternalGuards(field,zero);
 
       // Make sure setExternalGuards has completed before scattering
       Pooma::blockAndEvaluate();
@@ -502,7 +503,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.layout().internalGuards();
+      const GuardLayers<Dim>& gl = field.fieldEngine().guardLayers();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -512,7 +513,7 @@
       // Zero out the guard layers before scattering
       typename FC::Element_t zero(0);
       field.engine().setGuards(zero);
-      setExternalGuards(field,zero);
+//      setExternalGuards(field,zero);
 
       // Make sure setExternalGuards has completed before scattering
       Pooma::blockAndEvaluate();
@@ -661,7 +662,6 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -676,6 +676,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta, lpos, upos;
@@ -763,7 +764,6 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -778,6 +778,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta, lpos, upos;
@@ -866,7 +867,6 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -881,6 +881,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta, lpos, upos;
@@ -978,7 +979,6 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -993,6 +993,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta, lpos, upos;
@@ -1086,7 +1087,6 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -1101,6 +1101,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta, lpos, upos;
@@ -1194,7 +1195,6 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
-      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -1209,6 +1209,7 @@
 
       Size_t i;
       Loc<Dim> indx;
+      typedef typename Field_t::Mesh_t Mesh_t;
       const Mesh_t& mesh = field_m.mesh();
       typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta, lpos, upos;
@@ -1473,6 +1474,6 @@
 // ACL:rcsinfo
 // ----------------------------------------------------------------------
 // $RCSfile: InterpolatorSUDS.h,v $   $Author: pooma $
-// $Revision: 1.11 $   $Date: 2004/07/14 15:43:46 $
+// $Revision: 1.10 $   $Date: 2003/10/26 12:27:36 $
 // ----------------------------------------------------------------------
 // ACL:rcsinfo
Index: src/Particles/tests/interpolate.cpp
===================================================================
RCS file: /home/pooma/Repository/r2/src/Particles/tests/interpolate.cpp,v
retrieving revision 1.22
diff -u -r1.22 interpolate.cpp
--- src/Particles/tests/interpolate.cpp	14 Jul 2004 15:43:46 -0000	1.22
+++ src/Particles/tests/interpolate.cpp	15 Jul 2004 16:33:47 -0000
@@ -38,7 +38,10 @@
 #include "Pooma/UMPArrays.h"
 #include "Pooma/Fields.h"
 #include "Pooma/Tiny.h"
-
+#include "Particles/Interpolation.h"
+#include "Particles/InterpolatorNGP.h"
+#include "Particles/InterpolatorCIC.h"
+#include "Particles/InterpolatorSUDS.h"
 #include <iostream>
 #include <stdlib.h>
 
Index: src/Pooma/Particles.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Pooma/Particles.h,v
retrieving revision 1.11
diff -u -r1.11 Particles.h
--- src/Pooma/Particles.h	14 Jul 2004 15:43:46 -0000	1.11
+++ src/Pooma/Particles.h	15 Jul 2004 16:33:47 -0000
@@ -63,9 +63,9 @@
 
 // Interpolators
 
-#include "Particles/InterpolatorNGP.h"
-#include "Particles/InterpolatorCIC.h"
-#include "Particles/InterpolatorSUDS.h"
+//#include "Particles/InterpolatorNGP.h"
+//#include "Particles/InterpolatorCIC.h"
+//#include "Particles/InterpolatorSUDS.h"
 
 #endif
 
