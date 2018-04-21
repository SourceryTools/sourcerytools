===== makefile 1.4 vs edited =====
--- 1.4/r2/makefile	2003-12-10 10:59:32 +01:00
+++ edited/makefile	2004-07-11 19:32:40 +02:00
@@ -67,6 +67,7 @@
 EXAMPLEDIRS = examples/Components/Shock \
 	examples/Doof2d \
 	examples/Field/ScalarAdvection \
+	examples/Field/ScalarAdvection1D \
 	examples/GKPoisson \
 	examples/Indirection/FFT \
 	examples/Manual/Doof2d examples/Manual/Sequential \
@@ -84,12 +85,12 @@
 	examples/Solvers/UMPJacobi \
 	examples/Stencil/Laplace examples/Stencil/Life \
 	examples/Tiny \
-	examples/UserFunction/CosTimes
+	examples/UserFunction/CosTimes \
+	examples/Lattice
 # Those dont compile...
 #	examples/Field/Caramana examples/Field/Laplace \
-#	examples/Field/Laplace2 examples/Field/ScalarAdvection1D \
+#	examples/Field/Laplace2 \
 #	examples/Field/StatigraphicFlow \
-#	examples/Lattice \
 #	examples/Particles/PIC2d \
 
 .PHONY: examples examplesclean $(EXAMPLEDIRS)
===== examples/Field/ScalarAdvection1D/ScalarAdvection1D.cpp 1.1 vs edited =====
--- 1.1/r2/examples/Field/ScalarAdvection1D/ScalarAdvection1D.cpp	2002-05-13 17:47:22 +02:00
+++ edited/examples/Field/ScalarAdvection1D/ScalarAdvection1D.cpp	2004-07-11 19:31:18 +02:00
@@ -27,7 +27,7 @@
 // ACL:license
 
 // -----------------------------------------------------------------------------
-// 1D Wave propagation example, illustrating use of Mesh, DiscreteGeometry, and
+// 1D Wave propagation example, illustrating use of Mesh, and
 // Fields.
 // ----------------------------------------------------------------------------
 
@@ -50,20 +50,20 @@
   typedef UniformRectilinearMesh<1> Mesh_t;
   Mesh_t mesh(vertexDomain, origin, spacings);
   
-  // Create two geometry objects - one allowing 1 guard layer to 
+  // Create two layout objects - one allowing 1 guard layer to 
   // account for stencil width and another with no guard layers to support
   // temporaries:
-  typedef DiscreteGeometry<Cell, UniformRectilinearMesh<1> > Geometry_t ;
-  Geometry_t geom1c(mesh, GuardLayers<1>(1));
-  Geometry_t geom1ng(mesh);
+  DomainLayout<1> layout1(vertexDomain, GuardLayers<1>(1));
+  DomainLayout<1> layoutng(vertexDomain);
+  Centering<1> cell = canonicalCentering<1>(CellType, Continuous);
   
   // Create the Fields:
 
   // The flow Field u(x,t):
-  Field<Geometry_t> u(geom1c);
+  Field<Mesh_t> u(cell, layout1, mesh);
   // The same, stored at the previous timestep for staggered leapfrog
   // plus a useful temporary:
-  Field<Geometry_t> uPrev(geom1ng), uTemp(geom1ng);
+  Field<Mesh_t> uPrev(cell, layoutng, mesh), uTemp(cell, layoutng, mesh);
 
   // Initialize flow Field to zero everywhere, even global guard layers:
   u.all() = 0.0;
@@ -79,8 +79,8 @@
   // decaying to zero away from nCells/4 both directions, with a height of 1.0,
   // with a half-width of nCells/8:
   const double pulseWidth = spacings(0)*nCells/8;
-  const double u0 = u.x(nCells/4)(0);
-  u = 1.0*exp(-pow2(u.xComp(0)(pd)-u0)/(2.0*pulseWidth));
+  const double u0 = positions(u).read(nCells/4)(0);
+  u = 1.0*exp(-pow2(positions(u).comp(0).read(pd)-u0)/(2.0*pulseWidth));
 
   // Output the initial field on its physical domain:
   std::cout << "Time = 0:\n";
===== examples/Lattice/Coordinate.cpp 1.1 vs edited =====
--- 1.1/r2/examples/Lattice/Coordinate.cpp	2002-05-13 17:47:23 +02:00
+++ edited/examples/Lattice/Coordinate.cpp	2004-07-11 19:18:06 +02:00
@@ -87,10 +87,8 @@
   typedef UniformRectilinearMesh<2> Mesh_t;
   Mesh_t mesh(domain, origin, spacings);
 
-  typedef DiscreteGeometry<Cell, UniformRectilinearMesh<2> > Geometry_t;
-  Geometry_t geom(mesh, GuardLayers<2>(1));
-
-  Field<Geometry_t> u(geom);
+  Centering<2> cell = canonicalCentering<2>(CellType, Continuous);
+  Field<Mesh_t, double, MultiPatch<UniformTag,Brick> > u(cell, layout, mesh);
 
   Interval<2> d2 = u.physicalDomain();
 
