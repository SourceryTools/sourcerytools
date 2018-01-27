===== Particles/Interpolation.cpp 1.1 vs edited =====
--- 1.1/r2/src/Particles/Interpolation.cpp	2002-05-13 17:47:40 +02:00
+++ edited/Particles/Interpolation.cpp	2004-07-11 16:27:03 +02:00
@@ -178,6 +178,27 @@
   Interp_t::scatterValueCache(value,field,cache);
 }
 
+
+template <class Field>
+void setExternalGuards(const Field& f, typename Field::Element_t v)
+{
+  for (int i=0; i<Field::dimensions; ++i) {
+    int d = f.layout().externalGuards().lower(i);
+    if (d>0) {
+      Interval<Field::dimensions> I(f.totalDomain());
+      I[i] = Interval<1>(I[i].first(), I[i].first() + d-1);
+      f(I) = v;
+    }
+    d = f.layout().externalGuards().upper(i);
+    if (d>0) {
+      Interval<Field::dimensions> I(f.totalDomain());
+      I[i] = Interval<1>(I[i].last() - d+1, I[i].last());
+      f(I) = v;
+    }
+  }
+}
+
+
 // ACL:rcsinfo
 // ----------------------------------------------------------------------
 // $RCSfile: Interpolation.cpp,v $   $Author: swhaney $
===== Particles/Interpolation.h 1.2 vs edited =====
--- 1.2/r2/src/Particles/Interpolation.h	2003-10-26 14:35:24 +01:00
+++ edited/Particles/Interpolation.h	2004-07-11 16:28:45 +02:00
@@ -51,6 +51,8 @@
 // Includes:
 //-----------------------------------------------------------------------------
 
+#include "Evaluator/PatchFunction.h"
+
 //-----------------------------------------------------------------------------
 // Forward Declarations:
 //-----------------------------------------------------------------------------
@@ -220,6 +222,10 @@
 
 template <int Dim, class T, class InterpolatorTag>
 struct Interpolator;
+
+
+template <class Field>
+void setExternalGuards(const Field&, typename Field::Element_t);
 
 
 #include "Particles/Interpolation.cpp"
===== Particles/InterpolatorCIC.h 1.2 vs edited =====
--- 1.2/r2/src/Particles/InterpolatorCIC.h	2003-10-26 14:35:24 +01:00
+++ edited/Particles/InterpolatorCIC.h	2004-07-11 16:17:27 +02:00
@@ -55,7 +55,6 @@
 #include "Tiny/Vector.h"
 #include "Utilities/PAssert.h"
 #include "Utilities/ElementProperties.h"
-#include "Field/FieldFunctions.h"
 
 #include <iostream>
 
@@ -162,7 +161,7 @@
         "Field and Particle Position must have same number of patches!");
 
       // Check that the Field has adequate guard layers for CIC
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -198,7 +197,7 @@
         "Field and Particle Position must have same number of patches!");
 
       // Check that the Field has adequate guard layers for CIC
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -241,7 +240,7 @@
         "Field and Particle Position must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -291,7 +290,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -330,7 +329,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -375,7 +374,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -422,7 +421,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -459,7 +458,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -502,7 +501,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for CIC
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -668,6 +667,7 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -682,9 +682,8 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
-      typedef typename Geometry_t::PointType_t PointType_t;
+      const Mesh_t& mesh = field_m.mesh();
+      typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta;
       int idim;
       for (i=0; i<n; ++i)
@@ -692,7 +691,7 @@
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -702,15 +701,15 @@
           // lower-grid-point (LGP) by comparing grid-point position
           // with particle position and adjusting as needed.
 
-          gpos = geom.indexPoint(indx);
+          gpos = mesh.vertexPosition(indx);
           for (idim=0; idim<Dim; ++idim)
             if (gpos(idim)>pos(i)(idim))
               indx[idim] = indx[idim] - 1;
 
           // now compute position and spacings at the LGP
 
-          gpos = geom.indexPoint(indx);
-          delta = geom.indexPoint(indx+1) - gpos;
+          gpos = mesh.vertexPosition(indx);
+          delta = mesh.vertexPosition(indx+1) - gpos;
 
           // From this, we find the normalized distance between 
           // the particle and LGP positions.
@@ -775,6 +774,7 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -789,9 +789,8 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
-      typedef typename Geometry_t::PointType_t PointType_t;
+      const Mesh_t& mesh = field_m.mesh();
+      typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta;
       int idim;
       for (i=0; i<n; ++i)
@@ -799,7 +798,7 @@
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -809,15 +808,15 @@
           // lower-grid-point (LGP) by comparing grid-point position
           // with particle position and adjusting as needed.
 
-          gpos = geom.indexPoint(indx);
+          gpos = mesh.vertexPosition(indx);
           for (idim=0; idim<Dim; ++idim)
             if (gpos(idim)>pos(i)(idim))
               indx[idim] = indx[idim] - 1;
 
           // now compute position and spacings at the LGP
 
-          gpos = geom.indexPoint(indx);
-          delta = geom.indexPoint(indx+1) - gpos;
+          gpos = mesh.vertexPosition(indx);
+          delta = mesh.vertexPosition(indx+1) - gpos;
 
           // From this, we find the normalized distance between 
           // the particle and LGP positions.
@@ -883,6 +882,7 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -896,10 +896,9 @@
       // value into the field elements.
 
       Size_t i;
-      Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
-      typedef typename Geometry_t::PointType_t PointType_t;
+      Loc<Dim> indx; 
+      const Mesh_t& mesh = field_m.mesh();
+      typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta;
       int idim;
       for (i=0; i<n; ++i)
@@ -907,7 +906,7 @@
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -917,15 +916,15 @@
           // lower-grid-point (LGP) by comparing grid-point position
           // with particle position and adjusting as needed.
 
-          gpos = geom.indexPoint(indx);
+          gpos = mesh.vertexPosition(indx);
           for (idim=0; idim<Dim; ++idim)
             if (gpos(idim)>pos(i)(idim))
               indx[idim] = indx[idim] - 1;
 
           // now compute position and spacings at the LGP
 
-          gpos = geom.indexPoint(indx);
-          delta = geom.indexPoint(indx+1) - gpos;
+          gpos = mesh.vertexPosition(indx);
+          delta = mesh.vertexPosition(indx+1) - gpos;
 
           // From this, we find the normalized distance between 
           // the particle and LGP positions.
@@ -1000,6 +999,7 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -1014,9 +1014,8 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
-      typedef typename Geometry_t::PointType_t PointType_t;
+      const Mesh_t& mesh = field_m.mesh();
+      typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta;
       int idim;
       for (i=0; i<n; ++i)
@@ -1024,7 +1023,7 @@
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
 
           // check we are on the right patch
           
@@ -1034,15 +1033,15 @@
           // lower-grid-point (LGP) by comparing grid-point position
           // with particle position and adjusting as needed.
 
-          gpos = geom.indexPoint(indx);
+          gpos = mesh.vertexPosition(indx);
           for (idim=0; idim<Dim; ++idim)
             if (gpos(idim)>pos(i)(idim))
               indx[idim] = indx[idim] - 1;
 
           // now compute position and spacings at the LGP
 
-          gpos = geom.indexPoint(indx);
-          delta = geom.indexPoint(indx+1) - gpos;
+          gpos = mesh.vertexPosition(indx);
+          delta = mesh.vertexPosition(indx+1) - gpos;
 
           // From this, we find the normalized distance between 
           // the particle and LGP positions.
@@ -1113,6 +1112,7 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -1127,9 +1127,8 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
-      typedef typename Geometry_t::PointType_t PointType_t;
+      const Mesh_t& mesh = field_m.mesh();
+      typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta;
       int idim;
       for (i=0; i<n; ++i)
@@ -1137,7 +1136,7 @@
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -1147,15 +1146,15 @@
           // lower-grid-point (LGP) by comparing grid-point position
           // with particle position and adjusting as needed.
 
-          gpos = geom.indexPoint(indx);
+          gpos = mesh.vertexPosition(indx);
           for (idim=0; idim<Dim; ++idim)
             if (gpos(idim)>pos(i)(idim))
               indx[idim] = indx[idim] - 1;
 
           // now compute position and spacings at the LGP
 
-          gpos = geom.indexPoint(indx);
-          delta = geom.indexPoint(indx+1) - gpos;
+          gpos = mesh.vertexPosition(indx);
+          delta = mesh.vertexPosition(indx+1) - gpos;
 
           // From this, we find the normalized distance between 
           // the particle and LGP positions.
@@ -1226,6 +1225,7 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -1240,9 +1240,8 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
-      typedef typename Geometry_t::PointType_t PointType_t;
+      const Mesh_t& mesh = field_m.mesh();
+      typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta;
       int idim;
       for (i=0; i<n; ++i)
@@ -1250,7 +1249,7 @@
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -1260,15 +1259,15 @@
           // lower-grid-point (LGP) by comparing grid-point position
           // with particle position and adjusting as needed.
 
-          gpos = geom.indexPoint(indx);
+          gpos = mesh.vertexPosition(indx);
           for (idim=0; idim<Dim; ++idim)
             if (gpos(idim)>pos(i)(idim))
               indx[idim] = indx[idim] - 1;
 
           // now compute position and spacings at the LGP
 
-          gpos = geom.indexPoint(indx);
-          delta = geom.indexPoint(indx+1) - gpos;
+          gpos = mesh.vertexPosition(indx);
+          delta = mesh.vertexPosition(indx+1) - gpos;
 
           // From this, we find the normalized distance between 
           // the particle and LGP positions.
===== Particles/InterpolatorNGP.h 1.2 vs edited =====
--- 1.2/r2/src/Particles/InterpolatorNGP.h	2003-10-26 14:35:24 +01:00
+++ edited/Particles/InterpolatorNGP.h	2004-07-11 14:01:41 +02:00
@@ -430,6 +430,7 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -444,14 +445,13 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
+      const Mesh_t& mesh = field_m.mesh();
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -514,6 +514,7 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -528,14 +529,13 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
+      const Mesh_t& mesh = field_m.mesh();
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -598,6 +598,7 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -612,14 +613,13 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
+      const Mesh_t& mesh = field_m.mesh();
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -691,6 +691,7 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -705,14 +706,13 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
+      const Mesh_t& mesh = field_m.mesh();
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
 
           // check we are on the right patch
           
@@ -780,6 +780,7 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -794,14 +795,13 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
+      const Mesh_t& mesh = field_m.mesh();
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -868,6 +868,7 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -882,14 +883,13 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
+      const Mesh_t& mesh = field_m.mesh();
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
===== Particles/InterpolatorSUDS.h 1.2 vs edited =====
--- 1.2/r2/src/Particles/InterpolatorSUDS.h	2003-10-26 14:35:24 +01:00
+++ edited/Particles/InterpolatorSUDS.h	2004-07-11 16:28:04 +02:00
@@ -56,7 +56,6 @@
 #include "Tiny/Vector.h"
 #include "Utilities/PAssert.h"
 #include "Utilities/ElementProperties.h"
-#include "Field/FieldFunctions.h"
 
 #include <iostream>
 
@@ -163,7 +162,7 @@
         "Field and Particle Position must have same number of patches!");
 
       // Check that the Field has adequate guard layers for SUDS
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -199,7 +198,7 @@
         "Field and Particle Position must have same number of patches!");
 
       // Check that the Field has adequate guard layers for SUDS
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -242,7 +241,7 @@
         "Field and Particle Position must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -292,7 +291,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -331,7 +330,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -376,7 +375,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -423,7 +422,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -460,7 +459,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -503,7 +502,7 @@
         "Field and Particle CacheData must have same number of patches!");
 
       // Check that the Field has adequate GuardLayers for SUDS
-      const GuardLayers<Dim>& gl = field.geometry().guardLayers();
+      const GuardLayers<Dim>& gl = field.layout().internalGuards();
       for (int d=0; d<Dim; ++d)
         {
           PInsist(gl.lower(d)>=1 && gl.upper(d)>=1,
@@ -662,6 +661,7 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -676,16 +676,15 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
-      typedef typename Geometry_t::PointType_t PointType_t;
+      const Mesh_t& mesh = field_m.mesh();
+      typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta, lpos, upos;
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -694,9 +693,9 @@
           // now compute position at the NGP and the normalized
           // distance between the particle and NGP positions
 
-          gpos = geom.indexPoint(indx);
-          lpos = geom.indexPoint(indx-1);
-          upos = geom.indexPoint(indx+1);
+          gpos = mesh.vertexPosition(indx);
+          lpos = mesh.vertexPosition(indx-1);
+          upos = mesh.vertexPosition(indx+1);
           for (int idim=0; idim<Dim; ++idim)
             {
               if (pos(i)(idim) > gpos(idim))
@@ -764,6 +763,7 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -778,16 +778,15 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
-      typedef typename Geometry_t::PointType_t PointType_t;
+      const Mesh_t& mesh = field_m.mesh();
+      typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta, lpos, upos;
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -796,9 +795,9 @@
           // now compute position at the NGP and the normalized
           // distance between the particle and NGP positions
 
-          gpos = geom.indexPoint(indx);
-          lpos = geom.indexPoint(indx-1);
-          upos = geom.indexPoint(indx+1);
+          gpos = mesh.vertexPosition(indx);
+          lpos = mesh.vertexPosition(indx-1);
+          upos = mesh.vertexPosition(indx+1);
           for (int idim=0; idim<Dim; ++idim)
             {
               if (pos(i)(idim) > gpos(idim))
@@ -867,6 +866,7 @@
       // Get the global patch ID for this patch
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -881,16 +881,15 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
-      typedef typename Geometry_t::PointType_t PointType_t;
+      const Mesh_t& mesh = field_m.mesh();
+      typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta, lpos, upos;
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -899,9 +898,9 @@
           // now compute position at the NGP and the normalized
           // distance between the particle and NGP positions
 
-          gpos = geom.indexPoint(indx);
-          lpos = geom.indexPoint(indx-1);
-          upos = geom.indexPoint(indx+1);
+          gpos = mesh.vertexPosition(indx);
+          lpos = mesh.vertexPosition(indx-1);
+          upos = mesh.vertexPosition(indx+1);
           for (int idim=0; idim<Dim; ++idim)
             {
               if (pos(i)(idim) > gpos(idim))
@@ -979,6 +978,7 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -993,16 +993,15 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
-      typedef typename Geometry_t::PointType_t PointType_t;
+      const Mesh_t& mesh = field_m.mesh();
+      typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta, lpos, upos;
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
 
           // check we are on the right patch
           
@@ -1011,9 +1010,9 @@
           // now compute position at the NGP and the normalized
           // distance between the particle and NGP positions
 
-          gpos = geom.indexPoint(indx);
-          lpos = geom.indexPoint(indx-1);
-          upos = geom.indexPoint(indx+1);
+          gpos = mesh.vertexPosition(indx);
+          lpos = mesh.vertexPosition(indx-1);
+          upos = mesh.vertexPosition(indx+1);
           for (int idim=0; idim<Dim; ++idim)
             {
               if (pos(i)(idim) > gpos(idim))
@@ -1087,6 +1086,7 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -1101,16 +1101,15 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
-      typedef typename Geometry_t::PointType_t PointType_t;
+      const Mesh_t& mesh = field_m.mesh();
+      typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta, lpos, upos;
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -1119,9 +1118,9 @@
           // now compute position at the NGP and the normalized
           // distance between the particle and NGP positions
 
-          gpos = geom.indexPoint(indx);
-          lpos = geom.indexPoint(indx-1);
-          upos = geom.indexPoint(indx+1);
+          gpos = mesh.vertexPosition(indx);
+          lpos = mesh.vertexPosition(indx-1);
+          upos = mesh.vertexPosition(indx+1);
           for (int idim=0; idim<Dim; ++idim)
             {
               if (pos(i)(idim) > gpos(idim))
@@ -1195,6 +1194,7 @@
       // Get the global patch ID for this patch.
 
       typedef typename Field_t::Engine_t Engine_t;
+      typedef typename Field_t::Mesh_t Mesh_t;
       typedef typename Engine_t::Layout_t Layout_t;
       const Layout_t& layout = field_m.engine().layout();
       PatchID_t gid = layout.nodeListLocal()[pid]->globalID();
@@ -1209,16 +1209,15 @@
 
       Size_t i;
       Loc<Dim> indx;
-      typedef typename Field_t::Geometry_t Geometry_t;
-      const Geometry_t& geom = field_m.geometry();
-      typedef typename Geometry_t::PointType_t PointType_t;
+      const Mesh_t& mesh = field_m.mesh();
+      typedef typename Mesh_t::PointType_t PointType_t;
       PointType_t gpos, delta, lpos, upos;
       for (i=0; i<n; ++i)
         {
           // Convert the particle position to an index into the Field's
           // domain using the Geometry.
           
-          indx = geom.pointIndex(pos(i));
+          indx = mesh.cellContaining(pos(i));
           
           // check we are on the right patch
           
@@ -1227,9 +1226,9 @@
           // now compute position at the NGP and the normalized
           // distance between the particle and NGP positions
 
-          gpos = geom.indexPoint(indx);
-          lpos = geom.indexPoint(indx-1);
-          upos = geom.indexPoint(indx+1);
+          gpos = mesh.vertexPosition(indx);
+          lpos = mesh.vertexPosition(indx-1);
+          upos = mesh.vertexPosition(indx+1);
           for (int idim=0; idim<Dim; ++idim)
             {
               if (pos(i)(idim) > gpos(idim))
===== Pooma/Particles.h 1.2 vs edited =====
--- 1.2/r2/src/Pooma/Particles.h	2003-10-23 14:41:03 +02:00
+++ edited/Pooma/Particles.h	2004-07-11 14:02:24 +02:00
@@ -61,6 +61,12 @@
 #include "Particles/ReflectBC.h"
 #include "Particles/ReverseBC.h"
 
+// Interpolators
+
+#include "Particles/InterpolatorNGP.h"
+#include "Particles/InterpolatorCIC.h"
+#include "Particles/InterpolatorSUDS.h"
+
 #endif
 
 // ACL:rcsinfo
===== Particles/tests/interpolate.cpp 1.2 vs edited =====
--- 1.2/r2/src/Particles/tests/interpolate.cpp	2004-01-07 09:54:08 +01:00
+++ edited/Particles/tests/interpolate.cpp	2004-07-11 16:34:38 +02:00
@@ -47,7 +47,7 @@
 // A traits class for a Particles object
 //-----------------------------------------------------------------------------
 
-template <class EngineTag, class Center, class Mesh, class FL,
+template <class EngineTag, class Mesh, class FL,
           class Interpolator>
 struct PTraits
 {
@@ -57,7 +57,7 @@
 
   // The type of particle layout to use
 
-  typedef SpatialLayout< DiscreteGeometry<Center,Mesh>, FL > ParticleLayout_t;
+  typedef SpatialLayout< Mesh, FL > ParticleLayout_t;
 
   // The type of interpolator to use
   
@@ -127,27 +127,18 @@
 
 // Mesh type
 
-typedef UniformRectilinearMesh< PDim, Cartesian<PDim>, double > Mesh_t;
-
-// Centering type
-
-typedef Cell Center_t;
-// typedef Vert Center_t;
-
-// DiscreteGeometry type
-
-typedef DiscreteGeometry<Center_t,Mesh_t> Geometry_t;
+typedef UniformRectilinearMesh< PDim, double > Mesh_t;
 
 // Field type
 
 #if POOMA_MESSAGING
-typedef Field< Geometry_t, double, MultiPatch< UniformTag, Remote<Brick> > > 
+typedef Field< Mesh_t, double, MultiPatch< UniformTag, Remote<Brick> > > 
   DField_t;
-typedef Field< Geometry_t, Vector<PDim,double>,
+typedef Field< Mesh_t, Vector<PDim,double>,
                MultiPatch< UniformTag, Remote<Brick> > > VecDField_t;
 #else
-typedef Field< Geometry_t, double, MultiPatch<UniformTag,Brick> > DField_t;
-typedef Field< Geometry_t, Vector<PDim,double>,
+typedef Field< Mesh_t, double, MultiPatch<UniformTag,Brick> > DField_t;
+typedef Field< Mesh_t, Vector<PDim,double>,
                MultiPatch<UniformTag,Brick> > VecDField_t;
 #endif
 
@@ -164,7 +155,7 @@
 
 // The particle traits class we'll use
 
-typedef PTraits<AttrEngineTag_t,Center_t,Mesh_t,FLayout_t,NGPInterpolator_t>
+typedef PTraits<AttrEngineTag_t,Mesh_t,FLayout_t,NGPInterpolator_t>
   PTraits_t;
 
 // The particle layout type
@@ -191,26 +182,24 @@
   tester.out() << "------------------------------------------------"
                << std::endl;
 
-  // Create a Mesh and DiscreteGeometry object for a
-  // cell-centered DiscreteGeometry
+  // Create a cell-centered Mesh and Layout object
 
   tester.out() << "Creating URM object ..." << std::endl;
   
   Particles_t::PointType_t meshOrigin(-1.5, -2.0);
   Particles_t::PointType_t meshSpacing(0.5, 0.5);
-  Interval<PDim>           meshDomain(7, 9);
+  Interval<PDim>           meshDomain(8, 12);
   Mesh_t mesh(meshDomain, meshOrigin, meshSpacing);
 
-  tester.out() << "Creating DiscreteGeometry object ..." << std::endl;
-
-  GuardLayers<PDim> gl(1);
-  Geometry_t geometry(mesh, gl);
-
   // Create a FieldLayout object. 
 
   tester.out() << "Creating Field layout object ..." << std::endl;
+
+  GuardLayers<PDim> gl(1);
+  Centering<PDim> cell = canonicalCentering<PDim>(CellType, Continuous);
+
   Loc<PDim> blocks(2,4);
-  FLayout_t flayout(geometry.physicalDomain(), blocks, gl, DistributedTag());
+  FLayout_t flayout(meshDomain, blocks, gl, DistributedTag());
 
   // Create a couple of Fields using this layout.
   // One is an electric field that the particles will gather.
@@ -218,17 +207,17 @@
 
   tester.out() << "Creating electric field and charge density field ..."
                << std::endl;
-  VecDField_t electric(geometry,flayout);
-  DField_t    chargeDensity(geometry,flayout);
+  VecDField_t electric(cell,flayout, mesh);
+  DField_t    chargeDensity(cell,flayout, mesh);
 
   // Add boundary conditions that will manage the external guard layer values
 
-  electric.addBoundaryConditions(AllLinearExtrapolateFaceBC());
+  //FIXME: electric.addBoundaryConditions(AllLinearExtrapolateFaceBC());
 
   // Create a spatial layout object for the particles.
 
   tester.out() << "Creating SpatialLayout object ..." << std::endl;
-  PLayout_t layout(geometry, flayout);
+  PLayout_t layout(mesh, flayout);
 
   // Create a Particles object, using our special subclass
 
@@ -301,7 +290,7 @@
 
   // Apply field boundary conditions
 
-  electric.applyBoundaryConditions();
+  electric.applyRelations(true);
 
   // Print initial field values
 
@@ -328,8 +317,8 @@
                << sum(chargeDensity)
 	       << std::endl;
   tester.check("chargeDensity(NGP,attrib) == numparticles",
-               abs(sum(chargeDensity) -
-                   static_cast<double>(createnum))<1.0e-5);
+               fabs(sum(chargeDensity) -
+		    static_cast<double>(createnum))<1.0e-5);
 
   // Print out the particle efield
 
@@ -365,8 +354,8 @@
                << sum(chargeDensity)
 	       << std::endl;
   tester.check("chargeDensity(NGP,value) == numparticles",
-               abs(sum(chargeDensity) -
-                   static_cast<double>(createnum))<1.0e-5);
+               fabs(sum(chargeDensity) -
+		    static_cast<double>(createnum))<1.0e-5);
 
   // Print out the particle efield
 
@@ -401,11 +390,11 @@
   // Check that the sum of the charge density is correct
 
   tester.out() << "Sum of charge density field = "
-               << sum(chargeDensity(geometry.totalDomain()))
+               << sum(chargeDensity(chargeDensity.totalDomain()))
 	       << std::endl;
   tester.check("chargeDensity(CIC,attrib) == numparticles",
-	       abs(sum(chargeDensity(geometry.totalDomain())) -
-                   static_cast<double>(createnum))<1.0e-5);
+	       fabs(sum(chargeDensity(chargeDensity.totalDomain())) -
+		    static_cast<double>(createnum))<1.0e-5);
 
   // Print out the particle efield
 
@@ -440,11 +429,11 @@
   // Check that the sum of the charge density is correct
 
   tester.out() << "Sum of charge density field = "
-               << sum(chargeDensity(geometry.totalDomain()))
+               << sum(chargeDensity(chargeDensity.totalDomain()))
 	       << std::endl;
   tester.check("chargeDensity(SUDS,attrib) == numparticles",
-	       abs(sum(chargeDensity(geometry.totalDomain())) -
-                   static_cast<double>(createnum))<1.0e-5);
+	       fabs(sum(chargeDensity(chargeDensity.totalDomain())) -
+		    static_cast<double>(createnum))<1.0e-5);
 
   // Print out the particle efield
 
