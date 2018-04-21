Index: particle_bench1.cpp
===================================================================
RCS file: /home/pooma/Repository/r2/src/Particles/tests/particle_bench1.cpp,v
retrieving revision 1.9
diff -u -u -r1.9 particle_bench1.cpp
--- particle_bench1.cpp	25 Dec 2003 11:26:04 -0000	1.9
+++ particle_bench1.cpp	14 Jul 2004 19:53:31 -0000
@@ -53,12 +53,10 @@
   typedef MultiPatch<UniformTag, Brick>                FieldEngineTag_t;
 #endif
   typedef UniformRectilinearMesh<2>                    Mesh_t;
-  typedef Vert                                         Centering_t;
 
-  typedef DiscreteGeometry<Centering_t, Mesh_t>        Geometry_t;
-  typedef Field<Geometry_t, double, FieldEngineTag_t>  Field_t;
+  typedef Field<Mesh_t, double, FieldEngineTag_t>  Field_t;
   typedef Field_t::Layout_t                            FieldLayout_t;
-  typedef SpatialLayout<Geometry_t, FieldLayout_t>     ParLayout_t;
+  typedef SpatialLayout<Mesh_t, FieldLayout_t>     ParLayout_t;
   typedef TestParTraits<AttrEngineTag_t, ParLayout_t>  ParTraits_t;
   typedef ParLayout_t::PointType_t                     PointType_t;
 
@@ -68,11 +66,6 @@
   PointType_t meshOrigin(1.0, 2.0);
   PointType_t meshSpacing(0.5, 0.5);
 
-  // Create a Mesh and Geometry.
-
-  Mesh_t mesh(meshDomain, meshOrigin, meshSpacing);
-  Geometry_t geometry(mesh);
-
   // Let things catch up
 
   Pooma::blockAndEvaluate();
@@ -89,14 +82,18 @@
 
   Loc<2> blocks(3, 4);
 #if POOMA_MESSAGING
-  FieldLayout_t flayout(geometry.physicalDomain(), blocks, DistributedTag());
+  FieldLayout_t flayout(meshDomain, blocks, DistributedTag());
 #else
-  FieldLayout_t flayout(geometry.physicalDomain(), blocks, ReplicatedTag());
+  FieldLayout_t flayout(meshDomain, blocks, ReplicatedTag());
 #endif
 
+  // Create a Mesh and Geometry.
+
+  Mesh_t mesh(flayout, meshOrigin, meshSpacing);
+
   // Create a particle layout object.
 
-  ParLayout_t layout(geometry, flayout);
+  ParLayout_t layout(mesh, flayout);
 
   // Create a Particles object, using our special subclass.
 
Index: particle_bench2.cpp
===================================================================
RCS file: /home/pooma/Repository/r2/src/Particles/tests/particle_bench2.cpp,v
retrieving revision 1.7
diff -u -u -r1.7 particle_bench2.cpp
--- particle_bench2.cpp	25 Dec 2003 11:26:04 -0000	1.7
+++ particle_bench2.cpp	14 Jul 2004 19:53:31 -0000
@@ -53,12 +53,10 @@
   typedef MultiPatch<UniformTag, Brick>                FieldEngineTag_t;
 #endif
   typedef RectilinearMesh<2>                           Mesh_t;
-  typedef Vert                                         Centering_t;
 
-  typedef DiscreteGeometry<Centering_t, Mesh_t>        Geometry_t;
-  typedef Field<Geometry_t, double, FieldEngineTag_t>  Field_t;
+  typedef Field<Mesh_t, double, FieldEngineTag_t>  Field_t;
   typedef Field_t::Layout_t                            FieldLayout_t;
-  typedef SpatialLayout<Geometry_t, FieldLayout_t>     ParLayout_t;
+  typedef SpatialLayout<Mesh_t, FieldLayout_t>     ParLayout_t;
   typedef TestParTraits<AttrEngineTag_t, ParLayout_t>  ParTraits_t;
   typedef ParLayout_t::PointType_t                     PointType_t;
 
@@ -68,11 +66,6 @@
   PointType_t meshOrigin(1.0, 2.0);
   PointType_t meshSpacing(0.5, 0.5);
 
-  // Create a Mesh and Geometry.
-
-  Mesh_t mesh(meshDomain, meshOrigin, meshSpacing);
-  Geometry_t geometry(mesh);
-
   // Let things catch up
 
   Pooma::blockAndEvaluate();
@@ -89,14 +82,18 @@
 
   Loc<2> blocks(3, 4);
 #if POOMA_MESSAGING
-  FieldLayout_t flayout(geometry.physicalDomain(), blocks, DistributedTag());
+  FieldLayout_t flayout(meshDomain, blocks, DistributedTag());
 #else
-  FieldLayout_t flayout(geometry.physicalDomain(), blocks, ReplicatedTag());
+  FieldLayout_t flayout(meshDomain, blocks, ReplicatedTag());
 #endif
 
+  // Create a Mesh and Geometry.
+
+  Mesh_t mesh(flayout, meshOrigin, meshSpacing);
+
   // Create a particle layout object.
 
-  ParLayout_t layout(geometry, flayout);
+  ParLayout_t layout(mesh, flayout);
 
   // Create a Particles object, using our special subclass.
 
Index: particle_bench3.cpp
===================================================================
RCS file: /home/pooma/Repository/r2/src/Particles/tests/particle_bench3.cpp,v
retrieving revision 1.6
diff -u -u -r1.6 particle_bench3.cpp
--- particle_bench3.cpp	25 Dec 2003 11:26:04 -0000	1.6
+++ particle_bench3.cpp	14 Jul 2004 19:53:31 -0000
@@ -53,12 +53,10 @@
   typedef MultiPatch<GridTag,    Brick>                FieldEngineTag_t;
 #endif
   typedef UniformRectilinearMesh<2>                    Mesh_t;
-  typedef Cell                                         Centering_t;
 
-  typedef DiscreteGeometry<Centering_t, Mesh_t>        Geometry_t;
-  typedef Field<Geometry_t, double, FieldEngineTag_t>  Field_t;
+  typedef Field<Mesh_t, double, FieldEngineTag_t>  Field_t;
   typedef Field_t::Layout_t                            FieldLayout_t;
-  typedef SpatialLayout<Geometry_t, FieldLayout_t>     ParLayout_t;
+  typedef SpatialLayout<Mesh_t, FieldLayout_t>     ParLayout_t;
   typedef TestParTraits<AttrEngineTag_t, ParLayout_t>  ParTraits_t;
   typedef ParLayout_t::PointType_t                     PointType_t;
 
@@ -68,11 +66,6 @@
   PointType_t meshOrigin(1.0, 2.0);
   PointType_t meshSpacing(0.5, 0.5);
 
-  // Create a Mesh and Geometry.
-
-  Mesh_t mesh(meshDomain, meshOrigin, meshSpacing);
-  Geometry_t geometry(mesh);
-
   // Let things catch up
 
   Pooma::blockAndEvaluate();
@@ -89,14 +82,18 @@
 
   Loc<2> blocks(3, 4);
 #if POOMA_MESSAGING
-  FieldLayout_t flayout(geometry.physicalDomain(), blocks, DistributedTag());
+  FieldLayout_t flayout(meshDomain, blocks, DistributedTag());
 #else
-  FieldLayout_t flayout(geometry.physicalDomain(), blocks, ReplicatedTag());
+  FieldLayout_t flayout(meshDomain, blocks, ReplicatedTag());
 #endif
 
+  // Create a Mesh and Geometry.
+
+  Mesh_t mesh(flayout, meshOrigin, meshSpacing);
+
   // Create a particle layout object.
 
-  ParLayout_t layout(geometry, flayout);
+  ParLayout_t layout(mesh, flayout);
 
   // Create a Particles object, using our special subclass.
 
Index: particle_bench4.cpp
===================================================================
RCS file: /home/pooma/Repository/r2/src/Particles/tests/particle_bench4.cpp,v
retrieving revision 1.7
diff -u -u -r1.7 particle_bench4.cpp
--- particle_bench4.cpp	25 Dec 2003 11:26:04 -0000	1.7
+++ particle_bench4.cpp	14 Jul 2004 19:53:31 -0000
@@ -53,12 +53,10 @@
   typedef MultiPatch<GridTag,    Brick>                FieldEngineTag_t;
 #endif
   typedef RectilinearMesh<2>                           Mesh_t;
-  typedef Vert                                         Centering_t;
 
-  typedef DiscreteGeometry<Centering_t, Mesh_t>        Geometry_t;
-  typedef Field<Geometry_t, double, FieldEngineTag_t>  Field_t;
+  typedef Field<Mesh_t, double, FieldEngineTag_t>  Field_t;
   typedef Field_t::Layout_t                            FieldLayout_t;
-  typedef SpatialLayout<Geometry_t, FieldLayout_t>     ParLayout_t;
+  typedef SpatialLayout<Mesh_t, FieldLayout_t>     ParLayout_t;
   typedef TestParTraits<AttrEngineTag_t, ParLayout_t>  ParTraits_t;
   typedef ParLayout_t::PointType_t                     PointType_t;
 
@@ -68,11 +66,6 @@
   PointType_t meshOrigin(1.0, 2.0);
   PointType_t meshSpacing(0.5, 0.5);
 
-  // Create a Mesh and Geometry.
-
-  Mesh_t mesh(meshDomain, meshOrigin, meshSpacing);
-  Geometry_t geometry(mesh);
-
   // Let things catch up
 
   Pooma::blockAndEvaluate();
@@ -89,14 +82,18 @@
 
   Loc<2> blocks(3, 4);
 #if POOMA_MESSAGING
-  FieldLayout_t flayout(geometry.physicalDomain(), blocks, DistributedTag());
+  FieldLayout_t flayout(meshDomain, blocks, DistributedTag());
 #else
-  FieldLayout_t flayout(geometry.physicalDomain(), blocks, ReplicatedTag());
+  FieldLayout_t flayout(meshDomain, blocks, ReplicatedTag());
 #endif
 
+  // Create a Mesh and Geometry.
+
+  Mesh_t mesh(flayout, meshOrigin, meshSpacing);
+
   // Create a particle layout object.
 
-  ParLayout_t layout(geometry, flayout);
+  ParLayout_t layout(mesh, flayout);
 
   // Create a Particles object, using our special subclass.
 
