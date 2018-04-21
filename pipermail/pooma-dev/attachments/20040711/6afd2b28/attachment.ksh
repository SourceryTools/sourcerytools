===== particle_test1.cpp 1.1 vs edited =====
--- 1.1/r2/src/Particles/tests/particle_test1.cpp	2002-05-13 17:47:41 +02:00
+++ edited/particle_test1.cpp	2004-07-11 17:31:14 +02:00
@@ -47,12 +47,10 @@
   typedef MultiPatch<DynamicTag,Dynamic>               AttrEngineTag_t;
   typedef MultiPatch<GridTag,Brick>                    FieldEngineTag_t;
   typedef UniformRectilinearMesh<2>                    Mesh_t;
-  typedef Cell                                         Centering_t;
 
-  typedef DiscreteGeometry<Centering_t,Mesh_t>         Geometry_t;
-  typedef Field<Geometry_t,double,FieldEngineTag_t>    Field_t;
+  typedef Field<Mesh_t,double,FieldEngineTag_t>    Field_t;
   typedef Field_t::Layout_t                            FieldLayout_t;
-  typedef SpatialLayout<Geometry_t,FieldLayout_t>      ParLayout_t;
+  typedef SpatialLayout<Mesh_t,FieldLayout_t>      ParLayout_t;
   typedef TestParTraits<AttrEngineTag_t,ParLayout_t>   ParTraits_t;
   typedef ParLayout_t::PointType_t                     PointType_t;
 
@@ -65,7 +63,6 @@
   // Create a Mesh and Geometry.
 
   Mesh_t mesh(meshDomain, meshOrigin, meshSpacing);
-  Geometry_t geometry(mesh);
 
   // Let things catch up
 
@@ -82,11 +79,11 @@
   // this example, though, just the layout.
 
   Loc<2> blocks(3, 4);
-  FieldLayout_t flayout(geometry.physicalDomain(), blocks, ReplicatedTag());
+  FieldLayout_t flayout(meshDomain, blocks, ReplicatedTag());
 
   // Create a particle layout object.
 
-  ParLayout_t layout(geometry, flayout);
+  ParLayout_t layout(mesh, flayout);
 
   // Create a Particles object, using our special subclass.
 
===== particle_test2.cpp 1.1 vs edited =====
--- 1.1/r2/src/Particles/tests/particle_test2.cpp	2002-05-13 17:47:41 +02:00
+++ edited/particle_test2.cpp	2004-07-11 18:09:25 +02:00
@@ -47,12 +47,10 @@
   typedef MultiPatch<DynamicTag,Dynamic>               AttrEngineTag_t;
   typedef MultiPatch<GridTag,Brick>                    FieldEngineTag_t;
   typedef RectilinearMesh<2>                           Mesh_t;
-  typedef Vert                                         Centering_t;
 
-  typedef DiscreteGeometry<Centering_t,Mesh_t>         Geometry_t;
-  typedef Field<Geometry_t,double,FieldEngineTag_t>    Field_t;
+  typedef Field<Mesh_t,double,FieldEngineTag_t>    Field_t;
   typedef Field_t::Layout_t                            FieldLayout_t;
-  typedef SpatialLayout<Geometry_t,FieldLayout_t>      ParLayout_t;
+  typedef SpatialLayout<Mesh_t,FieldLayout_t>      ParLayout_t;
   typedef TestParTraits<AttrEngineTag_t,ParLayout_t>   ParTraits_t;
   typedef ParLayout_t::PointType_t                     PointType_t;
 
@@ -65,7 +63,6 @@
   // Create a Mesh and Geometry.
 
   Mesh_t mesh(meshDomain, meshOrigin, meshSpacing);
-  Geometry_t geometry(mesh);
 
   // Let things catch up
 
@@ -82,11 +79,11 @@
   // this example, though, just the layout.
 
   Loc<2> blocks(3, 4);
-  FieldLayout_t flayout(geometry.physicalDomain(), blocks, ReplicatedTag());
+  FieldLayout_t flayout(meshDomain, blocks, ReplicatedTag());
 
   // Create a particle layout object.
 
-  ParLayout_t layout(geometry, flayout);
+  ParLayout_t layout(mesh, flayout);
 
   // Create a Particles object, using our special subclass.
 
===== particle_test3.cpp 1.1 vs edited =====
--- 1.1/r2/src/Particles/tests/particle_test3.cpp	2002-05-13 17:47:41 +02:00
+++ edited/particle_test3.cpp	2004-07-11 18:10:13 +02:00
@@ -49,12 +49,10 @@
   typedef MultiPatch< DynamicTag, Remote<Dynamic> >    AttrEngineTag_t;
   typedef MultiPatch< GridTag, Remote<Brick> >         FieldEngineTag_t;
   typedef UniformRectilinearMesh<2>                    Mesh_t;
-  typedef Cell                                         Centering_t;
 
-  typedef DiscreteGeometry<Centering_t,Mesh_t>         Geometry_t;
-  typedef Field<Geometry_t,double,FieldEngineTag_t>    Field_t;
+  typedef Field<Mesh_t,double,FieldEngineTag_t>    Field_t;
   typedef Field_t::Layout_t                            FieldLayout_t;
-  typedef SpatialLayout<Geometry_t,FieldLayout_t>      ParLayout_t;
+  typedef SpatialLayout<Mesh_t,FieldLayout_t>      ParLayout_t;
   typedef TestParTraits<AttrEngineTag_t,ParLayout_t>   ParTraits_t;
   typedef ParLayout_t::PointType_t                     PointType_t;
 
@@ -67,7 +65,6 @@
   // Create a Mesh and Geometry.
 
   Mesh_t mesh(meshDomain, meshOrigin, meshSpacing);
-  Geometry_t geometry(mesh);
 
   // Let things catch up
 
@@ -84,11 +81,11 @@
   // this example, though, just the layout.
 
   Loc<2> blocks(3, 4);
-  FieldLayout_t flayout(geometry.physicalDomain(), blocks, DistributedTag());
+  FieldLayout_t flayout(meshDomain, blocks, DistributedTag());
 
   // Create a particle layout object.
 
-  ParLayout_t layout(geometry, flayout);
+  ParLayout_t layout(mesh, flayout);
 
   // Create a Particles object, using our special subclass.
 
===== particle_test4.cpp 1.1 vs edited =====
--- 1.1/r2/src/Particles/tests/particle_test4.cpp	2002-05-13 17:47:41 +02:00
+++ edited/particle_test4.cpp	2004-07-11 18:10:48 +02:00
@@ -49,12 +49,10 @@
   typedef MultiPatch< DynamicTag, Remote<Dynamic> >    AttrEngineTag_t;
   typedef MultiPatch< GridTag, Remote<Brick> >         FieldEngineTag_t;
   typedef RectilinearMesh<2>                           Mesh_t;
-  typedef Vert                                         Centering_t;
 
-  typedef DiscreteGeometry<Centering_t,Mesh_t>         Geometry_t;
-  typedef Field<Geometry_t,double,FieldEngineTag_t>    Field_t;
+  typedef Field<Mesh_t,double,FieldEngineTag_t>    Field_t;
   typedef Field_t::Layout_t                            FieldLayout_t;
-  typedef SpatialLayout<Geometry_t,FieldLayout_t>      ParLayout_t;
+  typedef SpatialLayout<Mesh_t,FieldLayout_t>      ParLayout_t;
   typedef TestParTraits<AttrEngineTag_t,ParLayout_t>   ParTraits_t;
   typedef ParLayout_t::PointType_t                     PointType_t;
 
@@ -67,7 +65,6 @@
   // Create a Mesh and Geometry.
 
   Mesh_t mesh(meshDomain, meshOrigin, meshSpacing);
-  Geometry_t geometry(mesh);
 
   // Let things catch up
 
@@ -84,11 +81,11 @@
   // this example, though, just the layout.
 
   Loc<2> blocks(3, 4);
-  FieldLayout_t flayout(geometry.physicalDomain(), blocks,DistributedTag());
+  FieldLayout_t flayout(meshDomain, blocks,DistributedTag());
 
   // Create a particle layout object.
 
-  ParLayout_t layout(geometry, flayout);
+  ParLayout_t layout(mesh, flayout);
 
   // Create a Particles object, using our special subclass.
 
