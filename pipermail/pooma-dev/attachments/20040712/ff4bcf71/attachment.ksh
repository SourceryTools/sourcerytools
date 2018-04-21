Index: Pooma/Fields.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Pooma/Fields.h,v
retrieving revision 1.16
diff -u -u -r1.16 Fields.h
--- Pooma/Fields.h	21 Nov 2003 17:36:10 -0000	1.16
+++ Pooma/Fields.h	11 Jul 2004 17:05:25 -0000
@@ -55,6 +55,7 @@
 
 #include "Field/Mesh/NoMesh.h"
 #include "Field/Mesh/UniformRectilinearMesh.h"
+#include "Field/Mesh/RectilinearMesh.h"
 #include "Field/Mesh/MeshFunctions.h"
 #include "Field/Mesh/PositionFunctions.h"
 
Index: Field/Mesh/RectilinearMesh.h
===================================================================
RCS file: Field/Mesh/RectilinearMesh.h
diff -N Field/Mesh/RectilinearMesh.h
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ Field/Mesh/RectilinearMesh.h	11 Jul 2004 17:05:27 -0000
@@ -0,0 +1,904 @@
+// -*- C++ -*-
+// ACL:license
+// ----------------------------------------------------------------------
+// This software and ancillary information (herein called "SOFTWARE")
+// called POOMA (Parallel Object-Oriented Methods and Applications) is
+// made available under the terms described here.  The SOFTWARE has been
+// approved for release with associated LA-CC Number LA-CC-98-65.
+// 
+// Unless otherwise indicated, this SOFTWARE has been authored by an
+// employee or employees of the University of California, operator of the
+// Los Alamos National Laboratory under Contract No. W-7405-ENG-36 with
+// the U.S. Department of Energy.  The U.S. Government has rights to use,
+// reproduce, and distribute this SOFTWARE. The public may copy, distribute,
+// prepare derivative works and publicly display this SOFTWARE without 
+// charge, provided that this Notice and any statement of authorship are 
+// reproduced on all copies.  Neither the Government nor the University 
+// makes any warranty, express or implied, or assumes any liability or 
+// responsibility for the use of this SOFTWARE.
+// 
+// If SOFTWARE is modified to produce derivative works, such modified
+// SOFTWARE should be clearly marked, so as not to confuse it with the
+// version available from LANL.
+// 
+// For more information about POOMA, send e-mail to pooma@acl.lanl.gov,
+// or visit the POOMA web page at http://www.acl.lanl.gov/pooma/.
+// ----------------------------------------------------------------------
+// ACL:license
+
+/** @file
+ * @ingroup Mesh
+ * @brief
+ * A rectilinear mesh without uniform spacing between vertices.
+ */
+
+#ifndef POOMA_FIELD_MESH_RECTILINEARMESH_H
+#define POOMA_FIELD_MESH_RECTILINEARMESH_H
+
+//-----------------------------------------------------------------------------
+// Includes:
+//-----------------------------------------------------------------------------
+
+#include <iostream>
+
+#include "Engine/ConstantFunctionEngine.h"         // Used in functors
+#include "Engine/IndexFunctionEngine.h"            // Used in functors
+#include "Layout/INode.h"                          // Used in ctors
+#include "Field/FieldEngine/FieldEnginePatch.h" // Used in ctors
+#include "Field/Mesh/NoMesh.h"                  // Base class
+#include "Field/FieldCentering.h"               // Centering<Dim> inline
+#include "Tiny/Vector.h"                        // Class member
+#include "Field/Mesh/MeshTraits.h"              // Template parameter
+
+
+//-----------------------------------------------------------------------------
+/// Holds the data for a rectilinear mesh. That class has a ref-counted
+/// instance of this class.
+//-----------------------------------------------------------------------------
+
+template <class MeshTraits>
+class RectilinearMeshData : public NoMeshData<MeshTraits::dimensions>
+{
+public:
+
+  // shortcuts to MeshTraits types
+  typedef typename MeshTraits::Domain_t Domain_t;
+  typedef typename MeshTraits::MeshData_t MeshData_t;
+  typedef typename MeshTraits::Scalar_t Scalar_t;
+  typedef typename MeshTraits::PointType_t PointType_t;
+  typedef typename MeshTraits::VectorType_t VectorType_t;
+  typedef typename MeshTraits::SpacingsType_t SpacingsType_t;
+  typedef typename MeshTraits::PositionsType_t PositionsType_t;
+
+  enum { dimensions = MeshTraits::dimensions };
+
+
+  //---------------------------------------------------------------------------
+  // Constructors.
+
+  /// We provide a default constructor that creates the object with empty
+  /// domains. To be useful, this object must be replaced by another 
+  /// version via assignment.
+  
+  RectilinearMeshData()
+    { 
+      // This space intentionally left blank.
+    }
+
+  /// This constructor fully constructs the object. It uses the layout to
+  /// compute domains and also initializes the origin and the spacings in each
+  /// coordinate direction. The indices in the layout refer to VERTEX
+  /// positions.
+
+  template<class Layout, class EngineTag>
+  RectilinearMeshData(
+    const Layout &layout,
+    const PointType_t &origin,
+    const Vector<dimensions, Array<1, Scalar_t, EngineTag> > &spacings)
+  : NoMeshData<dimensions>(layout), 
+    origin_m(origin)
+    //spacings_m(spacings)
+    {
+      for (int i=0; i<dimensions; i++) {
+	spacings_m(i).engine() = spacings(i).engine(); // init
+	spacings_m(i).engine().makeOwnCopy(); // FIXME? Do we want this?
+	Interval<1> I(layout.domain()[i]);
+	positions_m(i).engine() = Engine<1, Scalar_t, Brick>(I);
+	positions_m(i)(0) = origin_m(i);
+	// initialize from origin downward the ghost cells
+	for (int j=-1; j>=I.min(); j--)
+	  positions_m(i)(j) = positions_m(i).read(j+1) - spacings_m(i).read(j);
+	// initialize from origin upward
+	for (int j=1; j<=I.max(); j++)
+	  positions_m(i)(j) = positions_m(i).read(j-1) + spacings_m(i).read(j-1);
+      }
+    }
+
+  /// Constructor for constructing evenly spaced rectilinear meshes just
+  /// like UniformRectilinearMesh does.
+
+  template<class Layout>
+  RectilinearMeshData(
+    const Layout &layout,
+    const PointType_t &origin,
+    const VectorType_t &spacings)
+  : NoMeshData<dimensions>(layout), 
+    origin_m(origin)
+    {
+      // for each dimension we allocate engines for spacings & positions
+      // and initialize them according to origin/spacings
+      for (int i=0; i<dimensions; i++) {
+	Interval<1> I(layout.domain()[i]);
+	// allocate and assign spacings
+	spacings_m(i).engine() = Engine<1, Scalar_t, Brick>(I);
+	spacings_m(i)(I) = spacings(i); // no Array.all()
+	Pooma::blockAndEvaluate();
+	// allocate positions, assign origin
+	positions_m(i).engine() = Engine<1, Scalar_t, Brick>(I);
+	positions_m(i)(0) = origin_m(i);
+	// initialize from origin downward the ghost cells
+	for (int j=-1; j>=I.min(); j--)
+	  positions_m(i)(j) = positions_m(i).read(j+1) - spacings_m(i).read(j);
+	// initialize from origin upward
+	for (int j=1; j<=I.max(); j++)
+	  positions_m(i)(j) = positions_m(i).read(j-1) + spacings_m(i).read(j-1);
+      }
+    }
+    
+  /// Copy constructor.
+
+  RectilinearMeshData(const MeshData_t &model)
+  : NoMeshData<dimensions>(model), 
+    origin_m(model.origin_m)
+    //spacings_m(model.spacings_m),
+    //positions_m(model.positions_m)
+    {
+      for (int i=0; i<dimensions; i++) {
+	spacings_m(i).engine() = model.spacings_m(i).engine();
+	positions_m(i).engine() = model.positions_m(i).engine();
+      }
+      // This space intentionally left blank.
+    } 
+    
+  /// @name View constructors.
+  //@{
+  
+  /// Interval view. This means that we simply need to adjust the
+  /// origin by the amount the view is offset from the model's physical
+  /// cell domain. We rely on the base class to do the heavy lifting
+  /// with respect to figuring out the domains correctly.
+  ///
+  /// The Interval supplied must refer to VERTEX positions.
+  
+  RectilinearMeshData(const MeshData_t &model, 
+		      const Interval<dimensions> &d)
+  : NoMeshData<dimensions>(d)
+    {
+      for (int i = 0; i < dimensions; i++) {
+	// FIXME: Wheeee ;) (we cant store a BrickView...
+	// and still dont want to copy)
+	spacings_m(i).engine() = Engine<1, Scalar_t, Brick>(&model.spacings_m(i)(d[i])(0), d[i]);
+	positions_m(i).engine() = Engine<1, Scalar_t, Brick>(&model.positions_m(i)(d[i])(0), d[i]);
+	origin_m(i) = positions_m(i)(d[i].min());
+      }
+    }
+#if 0  
+  /// FieldEnginePatch view. We don't fiddle with the origin because we are not
+  /// making the domain zero-based.
+  ///
+  /// The domain supplied by the FieldEnginePatch must refer to VERTEX
+  /// positions.
+  
+  RectilinearMeshData(const MeshData_t &model, 
+		      const FieldEnginePatch<dimensions> &p)
+  : NoMeshData<dimensions>(model, p),
+    origin_m(model.origin_m),
+    spacings_m(model.spacings_m),
+    positions_m(model.spacings_m)
+    {
+      std::cerr << "RectilinearMeshData(FieldEnginePatch) constructor called" << std::endl;
+      abort();
+      // FIXME: what does FieldEnginePatch do???
+      for (int i=0; i<dimensions; i++) {
+	spacings_m(i).engine() = model.spacings_m(i).engine();
+	positions_m(i).engine() = model.positions_m(i).engine();
+      }
+    }
+#endif
+  //@}
+
+  //---------------------------------------------------------------------------
+  /// Copy assignment operator.
+  
+  MeshData_t &
+  operator=(const MeshData_t &rhs)
+    {
+      if (this != &rhs)
+        {
+          NoMeshData<dimensions>::operator=(rhs);
+          origin_m = rhs.origin_m;
+	  for (int i=0; i<dimensions; i++) {
+	    spacings_m(i).engine() = rhs.spacings_m(i).engine();
+	    positions_m(i).engine() = rhs.positions_m(i).engine();
+	  }
+        }
+        
+      return *this;
+    }
+
+  //---------------------------------------------------------------------------
+  /// Empty destructor is fine. Note, however, that NoMeshData does not have
+  /// a virtual destructor. We must be careful to delete these puppies as
+  /// RectilinearMeshData.
+
+  ~RectilinearMeshData() { }
+
+  //---------------------------------------------------------------------------
+  /// @name General accessors.
+  //@{
+
+  /// The mesh spacing.
+  
+  inline const SpacingsType_t &spacings() const 
+    { 
+      return spacings_m; 
+    }
+
+  /// The mesh vertex positions.
+  
+  inline const PositionsType_t &positions() const 
+    { 
+      return positions_m; 
+    }
+
+  /// The mesh origin.
+
+  inline const PointType_t &origin() const 
+    { 
+      return origin_m; 
+    }
+
+  //@}
+
+private:
+
+  /// Origin of mesh (coordinate vector of first vertex).
+
+  PointType_t origin_m;
+
+  /// Spacings between vertices.
+
+  SpacingsType_t spacings_m;
+
+  /// Vertex positions.
+
+  PositionsType_t positions_m;
+
+};
+
+
+
+
+///
+/// RectilinearMesh is a rectilinear mesh sometimes called a 
+/// "cartesian product" or "tensor product" mesh. Each dimension has a
+/// spacing value between every pair of vertices along that dimension;
+/// these spacings can all be different.
+///
+template<class MeshTraits>
+class RectilinearMesh : public MeshTraits::CoordinateSystem_t
+{
+public:
+
+  //---------------------------------------------------------------------------
+  // Exported typedefs and enumerations.
+
+  typedef MeshTraits MeshTraits_t;
+
+  /// The type of the mesh class.
+
+  typedef typename MeshTraits::Mesh_t Mesh_t;
+
+  /// The type of the mesh data class.
+
+  typedef typename MeshTraits::MeshData_t MeshData_t;
+
+  /// The type of the coordinate system.
+
+  typedef typename MeshTraits::CoordinateSystem_t CoordinateSystem_t;
+
+  /// The type of domains.
+
+  typedef typename MeshTraits::Domain_t Domain_t;
+
+  /// The type of locations.
+
+  typedef typename MeshTraits::Loc_t Loc_t;
+
+  /// The type T, used to represent, for example, volumes & areas, etc.
+
+  typedef typename MeshTraits::T_t T_t;
+
+  /// The type of scalars.
+
+  typedef typename MeshTraits::Scalar_t Scalar_t;
+
+  /// The type of mesh points.
+    
+  typedef typename MeshTraits::PointType_t PointType_t;
+
+  /// The type of vectors used to represent, for example, normals.
+  
+  typedef typename MeshTraits::VectorType_t VectorType_t;
+
+  /// The type used to store spacings.
+
+  typedef typename MeshTraits::SpacingsType_t SpacingsType_t;
+
+  /// The type used to store positions.
+
+  typedef typename MeshTraits::PositionsType_t PositionsType_t;
+
+  /// The number of indices required to select a point in this mesh.
+
+  enum { dimensions = MeshTraits::dimensions };
+
+  /// The number of components of a position vector inside the mesh.
+
+  enum { coordinateDimensions = MeshTraits::coordinateDimensions };
+
+
+  //---------------------------------------------------------------------------
+  // Constructors.
+  
+  /// We supply a default constructor, but it doesn't generate a useful mesh.
+  /// This is accomplished through assignment.
+  
+  RectilinearMesh() 
+  : data_m(new MeshData_t)
+    { 
+      // This space intentionally left blank.
+    }
+
+  /// This constructor fully constructs the object. It uses the layout to
+  /// compute domains and also initializes the origin and the spacings in each
+  /// coordinate direction.
+  ///
+  /// The Layout supplied must refer to VERTEX positions.
+  
+  template<class Layout, class EngineTag>
+  inline RectilinearMesh(const Layout &layout, 
+			 const PointType_t &origin,
+			 const Vector<coordinateDimensions, Array<1, T_t, EngineTag> > &spacings)
+  : data_m(new MeshData_t(layout, origin, spacings))
+    { 
+    }
+
+  /// Constructor compatible to UniformRectilinearMesh.
+
+  template<class Layout>
+  inline RectilinearMesh(const Layout &layout,
+			 const PointType_t &origin,
+			 const PointType_t &spacings)
+  : data_m(new MeshData_t(layout, origin, spacings))
+    { 
+    }
+
+  template<class Layout>
+  inline explicit RectilinearMesh(const Layout &layout)
+  : data_m(new MeshData_t(layout, 
+					   PointType_t(0), 
+					   PointType_t(1)))
+    { 
+    }
+
+  /// Copy constructor. 
+  
+  inline RectilinearMesh(const Mesh_t &model)
+  : data_m(model.data_m)
+    {
+    }
+    
+  /// @name View constructors
+  /// These are the only possible views of this
+  /// mesh. Other views will make a NoMesh.
+  //@{ 
+  
+  /// Interval view.
+  ///
+  /// The Interval supplied must refer to VERTEX positions.
+  
+  inline RectilinearMesh(const Mesh_t &model, 
+			 const Domain_t &d)
+  : data_m(new MeshData_t(*model.data_m, d))
+    {
+    }
+  
+  /// INode view.
+  ///
+  /// The INode supplied must refer to VERTEX positions.
+  
+  inline RectilinearMesh(const Mesh_t &model, 
+			 const INode<dimensions> &i)
+  : data_m(new MeshData_t(*model.data_m, i.domain()))
+    {
+    }
+#if 0
+  /// FieldEnginePatch view.
+  ///
+  /// The FieldEnginePatch supplied must refer to VERTEX positions.
+  
+  inline RectilinearMesh(const Mesh_t &model, 
+			 const FieldEnginePatch<dimensions> &p)
+  : data_m(new MeshData_t(*model.data_m, p))
+    {
+    }
+#endif
+  //@}
+
+  //---------------------------------------------------------------------------
+  /// Copy assignment operator.
+  
+  inline Mesh_t &
+  operator=(const Mesh_t &rhs)
+    {
+      if (&rhs != this)
+        {
+          data_m = rhs.data_m;
+        }
+      
+      return *this;
+    }
+
+  //---------------------------------------------------------------------------
+  /// Empty destructor is fine. The pointer to the data is ref-counted so its
+  /// lifetime is correctly managed.
+  
+  ~RectilinearMesh()
+    {
+    }
+
+  /// Data member access.
+  const MeshData_t& data() const
+    {
+      return *data_m;
+    }
+  
+  //---------------------------------------------------------------------------
+  /// @name Domain functions.
+  //@{
+  
+  /// The vertex domain, as the mesh was constructed with.
+
+  inline const Domain_t &physicalVertexDomain() const
+    {
+      return data_m->physicalVertexDomain(); 
+    }
+
+  /// Function that returns a domain adjusted to give the indices of the cells.
+
+  inline const Domain_t &physicalCellDomain() const
+    {
+      return data_m->physicalCellDomain(); 
+    }
+
+  /// The total vertex domain, including mesh guard vertices.
+
+  inline const Domain_t &totalVertexDomain() const
+    {
+      return data_m->totalVertexDomain(); 
+    }
+
+  /// The total cell domain, including mesh guard cells.
+
+  inline const Domain_t &totalCellDomain() const
+    {
+      return data_m->totalCellDomain(); 
+    }
+
+  //@}
+
+  //---------------------------------------------------------------------------
+  /// @name General accessors.
+  //@{
+
+  /// The mesh origin.
+
+  inline const PointType_t &origin() const 
+    { 
+      return data_m->origin();
+    }
+
+  /// The mesh spacing. Return type is dependend on mesh type.
+
+  inline const SpacingsType_t &spacings() const 
+    { 
+      return data_m->spacings();
+    }
+
+  /// The mesh positions. Return type is dependend on mesh type.
+
+  inline const PositionsType_t &positions() const 
+    { 
+      return data_m->positions();
+    }
+
+  /// The cell containing a particular point.
+
+  inline Loc_t cellContaining(const PointType_t &point) const
+    {
+      /// FIXME
+      Loc_t loc((0, Pooma::NoInit()));	// Avoid a g++ parse error.
+      for (int i = 0; i < dimensions; i++)
+	{
+	  const T_t *start = &positions()(i)(0);
+	  const T_t *finish = start + positions()(i).physicalDomain()[i].length();
+	  const T_t *p = std::lower_bound(start, finish, point(i));
+#if POOMA_BOUNDS_CHECK
+	  PInsist(p != finish,
+		  "Rectilinear::cellContaining(): point is outside mesh.");
+#endif
+	  // The lower_bound function returns the first element that is not
+	  // less than the point we're searching for.
+	  int j = static_cast<int>(std::distance(start, p));
+	  if (*p == point(i))
+	    loc[i] = j;
+	  else
+	    loc[i] = j-1;
+	}
+
+      return loc;
+    }
+
+  /// The lower-left vertex associated with a given cell location.
+    
+  inline PointType_t vertexPosition(const Loc_t &loc) const
+    {
+      PointType_t point;
+      for (int i = 0; i < dimensions; i++)
+        point(i) = positions()(i)(loc[i]); 
+      return point;
+    }
+
+  inline Scalar_t vertexPosition(int dim, int i) const
+    {
+      return positions()(dim)(i);
+    }
+
+  /// The position of a given cell location for canonical cell centering.
+
+  inline PointType_t cellPosition(const Loc_t &loc) const
+    {
+      PointType_t point;
+
+      for (int i=0; i<dimensions; i++)
+	point(i) = positions()(i)(loc[i]) + 0.5*spacings()(i)(loc[i]);
+
+      return point;
+    }
+
+  inline Scalar_t cellPosition(int dim, int i) const
+    {
+      return positions()(dim)(i) + 0.5*spacings()(dim)(i);
+    }
+
+  /// The vertex spacing for a given cell location.
+
+  inline VectorType_t vertexSpacing(const Loc_t &loc) const
+    {
+      VectorType_t delta;
+
+      for (int i=0; i<dimensions; i++)
+	delta(i) = spacings()(i)(loc[i]);
+
+      return delta;
+    }
+
+  inline Scalar_t vertexSpacing(int dim, int i) const
+    {
+      return spacings()(dim)(i);
+    }
+
+  /// The cell spacing for a given cell location.
+
+  inline VectorType_t cellSpacing(const Loc_t &loc) const
+    {
+      VectorType_t delta;
+
+      for (int i=0; i<dimensions; i++)
+	delta(i) = 0.5 * (spacings()(i)(loc[i]) + spacings()(i)(loc[i]+1));
+
+      return delta;
+    }
+
+  inline Scalar_t cellSpacing(int dim, int i) const
+    {
+      return 0.5*(spacings()(dim)(i) + spacings()(dim)(i+1));
+    }
+
+  //@}
+
+
+private:
+
+  /// Our data, stored as a ref-counted pointer to simplify memory management.
+  
+  RefCountedPtr<MeshData_t> data_m;
+};
+
+
+
+///
+/// GenericRM contains mesh functions related functors that are applicapble
+/// regardless of the coordinate system type.
+///
+template <class MeshTraits>
+struct GenericRM {
+
+  /// The coordinate type.
+
+  typedef typename MeshTraits::T_t T_t;
+
+  /// The mesh data class.
+
+  typedef typename MeshTraits::Mesh_t Mesh_t;
+
+  /// The type to represent points.
+
+  typedef typename MeshTraits::PointType_t PointType_t;
+
+  /// The type to represent vectors.
+
+  typedef typename MeshTraits::VectorType_t VectorType_t;
+
+  /// The type to represent the spacings.
+
+  typedef typename MeshTraits::SpacingsType_t SpacingsType_t;
+
+  /// The type used to store positions.
+
+  typedef typename MeshTraits::PositionsType_t PositionsType_t;
+
+  /// The type of locations.
+
+  typedef typename MeshTraits::Loc_t Loc_t;
+
+  /// Dimensionality of the mesh.
+
+  enum { dimensions = MeshTraits::dimensions };
+  enum { coordinateDimensions = MeshTraits::coordinateDimensions };
+
+
+  //---------------------------------------------------------------------------
+  /// Support for the positions() function. We need to provide a functor for
+  /// use with IndexFunction-engine. We also need to export the
+  /// PositionsEngineTag_t typedef and the positionsFunctor() member function,
+  /// which computes the positions using the centering point positions.
+  /// The indices passed in refer to cells.
+  
+  class PositionsFunctor {
+  public:
+  
+    /// Need to be able to default construct since we fill in the details
+    /// after the fact.
+
+    // WARNING! For Arrays to be initialized (copy constructed, assigned,
+    //          etc.) correctly, even in the case of uninitialized targets
+    //          we need to copy the engines explicitly rather than rely
+    //          on the compiler generating correct copy constructors and
+    //          assignment operators.
+    // FIXME! Technically we either can dump the copy constructor or the
+    //        assignment operator.
+
+    PositionsFunctor() { }
+    
+    PositionsFunctor(const Mesh_t &m, 
+                     const Centering<dimensions> &c)
+      : centering_m(c.position(0))
+      {
+	for (int i=0; i<dimensions; i++) {
+	  positions_m(i).engine() = m.positions()(i).engine();
+	  spacings_m(i).engine() = m.spacings()(i).engine();
+	}
+      }
+
+    PositionsFunctor(const PositionsFunctor &m)
+      :	centering_m(m.centering_m)
+    {
+      for (int i=0; i<dimensions; i++) {
+	positions_m(i).engine() = m.positions_m(i).engine();
+	spacings_m(i).engine() = m.spacings_m(i).engine();
+      }
+    }
+
+    PositionsFunctor& operator=(const PositionsFunctor &m)
+    {
+      centering_m = m.centering_m;
+      for (int i=0; i<dimensions; i++) {
+	positions_m(i).engine() = m.positions_m(i).engine();
+	spacings_m(i).engine() = m.spacings_m(i).engine();
+      }
+
+      return *this;
+    }
+
+    inline PointType_t operator()(int i0) const
+      {
+        return PointType_t(positions_m(0).read(i0) + spacings_m(0).read(i0)*centering_m(0));
+      }
+      
+    inline PointType_t operator()(int i0, int i1) const
+      {
+        return PointType_t(positions_m(0).read(i0) + spacings_m(0).read(i0)*centering_m(0),
+			   positions_m(1).read(i1) + spacings_m(1).read(i1)*centering_m(1));
+      }
+
+    inline PointType_t operator()(int i0, int i1, int i2) const
+      {
+        return PointType_t(positions_m(0).read(i0) + spacings_m(0).read(i0)*centering_m(0),
+			   positions_m(1).read(i1) + spacings_m(1).read(i1)*centering_m(1),
+			   positions_m(2).read(i2) + spacings_m(2).read(i2)*centering_m(2));
+      }
+
+  private:
+
+    PositionsType_t positions_m;
+    SpacingsType_t spacings_m;
+    typename Centering<dimensions>::Position centering_m;
+
+  };
+  
+  typedef IndexFunction<PositionsFunctor> PositionsEngineTag_t;
+
+  template <class PositionsEngineTag>
+  void initializePositions(
+    Engine<dimensions, PointType_t, PositionsEngineTag> &e, 
+    const Centering<dimensions> &c) const
+    {
+      e.setFunctor(typename PositionsEngineTag::Functor_t(static_cast<const Mesh_t&>(*this), c));
+    }
+
+
+  //---------------------------------------------------------------------------
+  /// Support for the spacings() function. We need to provide a functor for
+  /// use with IndexFunction-engine. We also need to export the
+  /// SpacingsEngineTag_t typedef and the spacingsFunctor() member function,
+  /// which computes the spacings using the centering point positions.
+  /// The indices passed in refer to cells.
+  
+  class SpacingsFunctor {
+  public:
+  
+    /// Need to be able to default construct since we fill in the details
+    /// after the fact.
+
+    // WARNING! For Arrays to be initialized (copy constructed, assigned,
+    //          etc.) correctly, even in the case of uninitialized targets
+    //          we need to copy the engines explicitly rather than rely
+    //          on the compiler generating correct copy constructors and
+    //          assignment operators.
+    // FIXME! Technically we either can dump the copy constructor or the
+    //        assignment operator.
+
+    SpacingsFunctor() { }
+    
+    SpacingsFunctor(const Mesh_t &m, 
+		    const Centering<dimensions> &c)
+      : centering_m(c.position(0))
+      {
+	for (int i=0; i<dimensions; i++)
+	  spacings_m(i).engine() = m.spacings()(i).engine();
+      }
+
+    SpacingsFunctor(const SpacingsFunctor &m)
+      :	centering_m(m.centering_m)
+    {
+      for (int i=0; i<dimensions; i++)
+	spacings_m(i).engine() = m.spacings_m(i).engine();
+    }
+
+    SpacingsFunctor& operator=(const SpacingsFunctor &m)
+    {
+      centering_m = m.centering_m;
+      for (int i=0; i<dimensions; i++)
+	spacings_m(i).engine() = m.spacings_m(i).engine();
+
+      return *this;
+    }
+
+    /* FIXME: the following may cause an out of bound condition, if
+     *        the spacings is queried for the last cell - spacings
+     *        for non-existing cells are used then.
+     */
+
+    inline VectorType_t operator()(int i0) const
+      {
+        return VectorType_t(spacings_m(0).read(i0)
+			   + (spacings_m(0).read(i0+1)-spacings_m(0).read(i0))*centering_m(0));
+      }
+      
+    inline VectorType_t operator()(int i0, int i1) const
+      {
+        return VectorType_t(spacings_m(0).read(i0)
+			   + (spacings_m(0).read(i0+1)-spacings_m(0).read(i0))*centering_m(0),
+			   spacings_m(1).read(i1)
+			   + (spacings_m(1).read(i1+1)-spacings_m(1).read(i1))*centering_m(1));
+      }
+
+    inline VectorType_t operator()(int i0, int i1, int i2) const
+      {
+        return VectorType_t(spacings_m(0).read(i0)
+			   + (spacings_m(0).read(i0+1)-spacings_m(0).read(i0))*centering_m(0),
+			   spacings_m(1).read(i1)
+			   + (spacings_m(1).read(i1+1)-spacings_m(1).read(i1))*centering_m(1),
+			   spacings_m(2).read(i2)
+			   + (spacings_m(2).read(i2+1)-spacings_m(2).read(i2))*centering_m(2));
+      }
+
+  private:
+
+    SpacingsType_t spacings_m;
+    typename Centering<dimensions>::Position centering_m;
+
+  };
+  
+  typedef IndexFunction<SpacingsFunctor> SpacingsEngineTag_t;
+  
+  void initializeSpacings(
+    Engine<dimensions, PointType_t, SpacingsEngineTag_t> &e, 
+    const Centering<dimensions> &c) const
+    {
+      e.setFunctor(SpacingsFunctor(static_cast<const Mesh_t&>(*this), c));
+    }
+
+  
+  //---------------------------------------------------------------------------
+  /// Support for the outwardNormals() and coordinateNormals() functions. 
+  /// We also need to export the NormalsEngineTag_t typedef and the 
+  /// initializeNormals() member function, which sets the appropriate constant 
+  /// value (since the normals exactly align with the coordinate axes).
+  /// The boolean value passed is true if we are asking for outward normals,
+  /// as opposed to coordinate normals. The indices passed in refer to cells.
+
+  typedef ConstantFunction NormalsEngineTag_t;
+  
+  void initializeNormals(
+    Engine<dimensions, VectorType_t, NormalsEngineTag_t> &e, 
+    const Centering<dimensions> &c,
+    bool outward = true) const
+    {
+      // Check some pre-conditions. We need there to be a single centering
+      // point and it must be face-centered.
+      
+      PAssert(c.size() == 1);
+      PAssert(c.centeringType() == FaceType);
+      
+      // Generate the normals. The coordinate normals are computed from
+      // 1 - orientation. Then, if we are on the near face, indicated by
+      // position == 0.0, we need to multiply by -1.0 if we are doing
+      // outward normals.
+      
+      VectorType_t normal;
+      for (int i = 0; i < dimensions; i++)
+        {
+          normal(i) = static_cast<T_t>(1 - c.orientation(0)[i].first());
+          if (outward && c.position(0)(i) == 0.0)
+            normal(i) *= static_cast<T_t>(-1);
+        }
+        
+      e.setConstant(normal);
+    }
+
+};
+
+
+
+#endif // POOMA_FIELD_MESH_RECTILINEARMESH_H
+
+// ACL:rcsinfo
+// ----------------------------------------------------------------------
+// $RCSfile: RectilinearMesh.h,v $   $Author: oldham $
+// $Revision: 1.4 $   $Date: 2001/12/11 20:43:30 $
+// ----------------------------------------------------------------------
+// ACL:rcsinfo
+
