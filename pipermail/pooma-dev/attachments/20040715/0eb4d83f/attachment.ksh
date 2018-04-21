Index: src/Field/DiffOps/Grad.UR.h
===================================================================
RCS file: src/Field/DiffOps/Grad.UR.h
diff -N src/Field/DiffOps/Grad.UR.h
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/Field/DiffOps/Grad.UR.h	15 Jul 2004 21:28:53 -0000
@@ -0,0 +1,375 @@
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
+//-----------------------------------------------------------------------------
+// Classes:
+// 
+// Grad
+//-----------------------------------------------------------------------------
+
+#ifndef POOMA_FIELD_DIFFOPS_GRAD_UR_H
+#define POOMA_FIELD_DIFFOPS_GRAD_UR_H
+
+/** @file
+ * @ingroup DiffOps
+ * @brief
+ * Gradient operator on Fields, using 2nd-order centered differences
+ * These are used by the grad() template function.
+ *
+ * See Grad.h for
+ * details, and the grad() function template definition.
+ */
+
+//-----------------------------------------------------------------------------
+// Typedefs:
+//-----------------------------------------------------------------------------
+
+//-----------------------------------------------------------------------------
+// Includes:
+//-----------------------------------------------------------------------------
+
+#include "Tiny/Vector.h"
+#include "Field/DiffOps/FieldStencil.h"
+#include "Field/Mesh/UniformRectilinearMesh.h"
+
+//-----------------------------------------------------------------------------
+// Forward Declarations:
+//-----------------------------------------------------------------------------
+
+/**
+ * Partial specializations of the generic Grad (gradient) functor. See Grad.h
+ * for general comments. These are for UniformRectilinear-based 
+ * DiscreteGeometry.
+ * 
+ * Grad is a functor class serving as the "Functor" template parameter for
+ * FieldStencil<Functor>. Its operator() functions implement 2nd
+ * centered differences on an input Field and return output elements of an
+ * output Field.  The types of the input and output Field differ in two ways:
+ *	-# The input centering is (possibly) different than the output 
+ *	   centering.
+ *	-# The input element type is Vector<Dim,T2> (or Tensor<Dim,T2>) and
+ *         the output type is a scalar type T2 (or Vector<Dim,T2>).
+ * Partial specializations implement various combinations of input and output
+ * centerings, for specific coordinate systems.
+ * 
+ * Exported typedefs:
+ *  - OutputElement_t: Type of the elements in the output ConstField; 
+ *                     restricted to a scalar type (vector input) or vector
+ *                     (tensor input)
+ * 
+ * Accessors:
+ *  - inputCentering(): Returns the centering of the input field.  This
+ *                      function is just provided as a sanity check for when
+ *                      the stencil is created.
+ *  - outputCentering(): The centering of the output field. This centering is
+ *                      used to construct the return value of the stencil.
+ *  - lowerExtent(int d): Returns the stencil width in direction d, at the "low"
+ *                      end of the (logically) rectilinear mesh. This is the
+ *                      maximum positive integer offset from the element 
+ *                      indexed by integer i in the input Field's index space
+ *                      along dimension d used in outputting the element
+ *                      indexed by integer i in the output Field's index space
+ *                      along dimension d
+ *  - upperExtent(int d): Same as lowerExtent(), but for the "high" end of the 
+ *                      mesh. That is, the maximum (magnitude) *negative*
+ *                      offset from i in direction d.
+ * 
+ * Other methods:
+ *  - operator()(...): The actual implementation for the stencil. This acts on a 
+ *                   set of scalar-indexed values in the input Field's index
+ *                   space making up the stencil, as offset from the fixed
+ *                   index point specified by the function's input arguments
+ *                   (list of scalar index values).  The stencil must be
+ *                   written so that the same fixed index point specified by
+ *                   the input arguments where the values are to be assigned in
+ *                   the index space of the output Field. This means, for
+ *                   example, that if the operator is going from one centering
+ *                   to a different output centering, the index bookkeeping
+ *                   must be done correctly by this operator()() function
+ *                   implementation.
+ */
+
+// ----------------------------------------------------------------------------
+// Partial specializations of GradVertToCell
+// ----------------------------------------------------------------------------
+
+// ----------------------------------------------------------------------------
+// Gradient Vector/Vert -> Scalar/Cell
+// ----------------------------------------------------------------------------
+
+template<class T2, class Mesh>
+class GradVertToCell;
+
+template<class T2, int Dim, class TM>
+class GradVertToCell< T2, UniformRectilinearMesh<Dim, TM> >
+{
+public:
+
+  typedef Vector<Dim, T2> OutputElement_t;
+
+  Centering<Dim> outputCentering() const
+  {
+    return canonicalCentering<Dim>(CellType, Continuous);
+  }
+
+  Centering<Dim> inputCentering() const
+  {
+    return canonicalCentering<Dim>(VertexType, Continuous);
+  }
+
+  // 
+  // Constructors.
+  // 
+
+  // default version is required by default stencil engine constructor.
+
+  GradVertToCell()
+  {
+    for (int d = 0; d < Dim; ++d)
+    {
+      fact_m(d) = 1.0;
+    }
+  }
+
+  template<class FE>
+  GradVertToCell(const FE &fieldEngine)
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
+  int lowerExtent(int d) const { return 0; }
+  int upperExtent(int d) const { return 1; }
+
+  template<class F>
+  inline OutputElement_t
+  operator()(const F &f, int i1) const
+  {
+    return OutputElement_t(fact_m(0)*(f.read(i1 + 1) - f.read(i1)));
+  }
+
+  template<class F>
+  inline OutputElement_t
+  operator()(const F &f, int i1, int i2) const
+  {
+    return OutputElement_t(fact_m(0)*(f.read(i1+1,i2)-f.read(i1,i2)),
+			   fact_m(1)*(f.read(i1,i2+1)-f.read(i1,i2)));
+  }
+
+  template<class F>
+  inline OutputElement_t
+  operator()(const F &f, int i1, int i2, int i3) const
+  {
+    return OutputElement_t(fact_m(0)*(f.read(i1+1,i2,i3)-f.read(i1,i2,i3)),
+			   fact_m(1)*(f.read(i1,i2+1,i3)-f.read(i1,i2,i3)),
+			   fact_m(2)*(f.read(i1,i2,i3+1)-f.read(i1,i2,i3)));
+  }
+
+private:
+
+  Vector<Dim, TM> fact_m;
+};
+
+
+template<class T2, class Mesh>
+class GradCellToVert;
+
+template<class T2, int Dim, class TM>
+class GradCellToVert< T2, UniformRectilinearMesh<Dim, TM> >
+{
+public:
+
+  typedef Vector<Dim, T2> OutputElement_t;
+
+  Centering<Dim> outputCentering() const
+  {
+    return canonicalCentering<Dim>(VertexType, Continuous);
+  }
+
+  Centering<Dim> inputCentering() const
+  {
+    return canonicalCentering<Dim>(CellType, Continuous);
+  }
+
+  // 
+  // Constructors.
+  // 
+
+  // default version is required by default stencil engine constructor.
+
+  GradCellToVert()
+  {
+    for (int d = 0; d < Dim; ++d)
+    {
+      fact_m(d) = 1.0;
+    }
+  }
+
+  template<class FE>
+  GradCellToVert(const FE &fieldEngine)
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
+    return OutputElement_t(fact_m(0)*(f.read(i1) - f.read(i1-1)));
+  }
+
+  template<class F>
+  inline OutputElement_t
+  operator()(const F &f, int i1, int i2) const
+  {
+    return OutputElement_t(fact_m(0)*(f.read(i1,i2)-f.read(i1-1,i2)),
+			   fact_m(1)*(f.read(i1,i2)-f.read(i1,i2-1)));
+  }
+
+  template<class F>
+  inline OutputElement_t
+  operator()(const F &f, int i1, int i2, int i3) const
+  {
+    return OutputElement_t(fact_m(0)*(f.read(i1,i2,i3)-f.read(i1-1,i2,i3)),
+			   fact_m(1)*(f.read(i1,i2,i3)-f.read(i1,i2-1,i3)),
+			   fact_m(2)*(f.read(i1,i2,i3)-f.read(i1,i2,i3-1)));
+  }
+
+private:
+
+  Vector<Dim, TM> fact_m;
+};
+
+
+template<class T2, class Mesh, CenteringType OC>
+class GradSameToSame;
+
+template<class T2, int Dim, class TM, CenteringType OC>
+class GradSameToSame<T2, UniformRectilinearMesh<Dim, TM>, OC>
+{
+public:
+
+  typedef Vector<Dim, T2>  OutputElement_t;
+
+  Centering<Dim> outputCentering() const
+  {
+    return canonicalCentering<Dim>(OC, Continuous);
+  }
+
+  Centering<Dim> inputCentering() const
+  {
+    return canonicalCentering<Dim>(OC, Continuous);
+  }
+
+  // 
+  // Constructors.
+  // 
+
+  // default version is required by default stencil engine constructor.
+
+  GradSameToSame()
+  {
+    for (int d = 0; d < Dim; ++d)
+    {
+      fact_m(d) = 0.5;
+    }
+  }
+
+  template<class FE>
+  GradSameToSame(const FE &fieldEngine)
+  {
+    for (int d = 0; d < Dim; ++d)
+    {
+      fact_m(d) = 0.5 / fieldEngine.mesh().spacings()(d);
+    }
+  }
+
+  //
+  // Methods.
+  //
+
+  int lowerExtent(int d) const { return 1; }
+  int upperExtent(int d) const { return 1; }
+      
+  template<class F>
+  inline OutputElement_t
+  operator()(const F &f, int i1) const
+  {
+    return OutputElement_t
+      (fact_m(0) * (f.read(i1 + 1) - f.read(i1 - 1)));
+  }
+
+  template<class F>
+  inline OutputElement_t
+  operator()(const F &f, int i1, int i2) const
+  {
+    return OutputElement_t
+      (fact_m(0) * (f.read(i1 + 1, i2    ) - f.read(i1 - 1, i2    )),
+       fact_m(1) * (f.read(i1    , i2 + 1) - f.read(i1    , i2 - 1)));
+  }
+
+  template<class F>
+  inline OutputElement_t
+  operator()(const F &f, int i1, int i2, int i3) const
+  {
+    return OutputElement_t
+      (fact_m(0) * (f.read(i1+1, i2  , i3  ) - f.read(i1-1, i2  , i3  )),
+       fact_m(1) * (f.read(i1  , i2+1, i3  ) - f.read(i1  , i2-1, i3  )),
+       fact_m(2) * (f.read(i1  , i2  , i3+1) - f.read(i1  , i2  , i3-1)));
+  }
+
+private:
+
+  Vector<Dim, TM> fact_m;
+};
+
+
+#endif     // POOMA_FIELD_DIFFOPS_DIV_UR_H
+
+// ACL:rcsinfo
+// ----------------------------------------------------------------------
+// $RCSfile: Grad.UR.h,v $   $Author: pooma $
+// $Revision: 1.3 $   $Date: 2003/10/25 13:26:56 $
+// ----------------------------------------------------------------------
+// ACL:rcsinfo
Index: src/Field/DiffOps/Grad.h
===================================================================
RCS file: src/Field/DiffOps/Grad.h
diff -N src/Field/DiffOps/Grad.h
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ src/Field/DiffOps/Grad.h	15 Jul 2004 21:28:55 -0000
@@ -0,0 +1,152 @@
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
+//-----------------------------------------------------------------------------
+// Classes:
+//   Div
+// Global Function Templates:
+//   div
+//-----------------------------------------------------------------------------
+
+#ifndef POOMA_FIELD_DIFFOPS_GRAD_H
+#define POOMA_FIELD_DIFFOPS_GRAD_H
+
+//////////////////////////////////////////////////////////////////////
+
+/** @file
+ * @ingroup DiffOps
+ * @brief
+ * Gradient operator (functor) on discrete Fields.
+ *
+ * Wrapper function around FieldStencil<Grad>::operator() . The Div
+ * functors actually used are partial specializations of the generic
+ * Grad that come from Grad.UR for example.
+ *
+ * Grad is a functor class serving as the "Functor" template parameter for
+ * FieldStencil<Functor,Expression>, which implements a discrete 
+ * gradient operator.
+ * Partial specializations implement various combinations of input and output
+ * centerings, for specific coordinate systems, and different finite-difference
+ * orders, are defined in other headers like Grad.[URM,RM].h .
+ * 
+ * grad(): Gradient. Takes a scalar Field a 
+ * discrete geometry with one centering and returns a Field of
+ * vectors on a geometry that's the same except
+ * (possibly) for the centering. All the work happens in the embedded
+ * Grad functor partial specialization, in its operator() methods.
+ */
+
+//-----------------------------------------------------------------------------
+// Typedefs:
+//-----------------------------------------------------------------------------
+
+//-----------------------------------------------------------------------------
+// Includes:
+//-----------------------------------------------------------------------------
+
+#include "Field/Field.h"
+#include "Field/FieldCentering.h"
+#include "Field/DiffOps/FieldStencil.h"
+
+//-----------------------------------------------------------------------------
+// Forward Declarations:
+//-----------------------------------------------------------------------------
+
+// ----------------------------------------------------------------------------
+// General Grad template
+// ----------------------------------------------------------------------------
+
+template<class T2, class Mesh>
+class GradCellToVert;
+
+template<class T2, class Mesh>
+class GradVertToCell;
+
+template<class T2, class Mesh, CenteringType OC>
+class GradSameToSame;
+
+
+// ----------------------------------------------------------------------------
+// 
+// Global Function Templates:
+//
+// ----------------------------------------------------------------------------
+
+template<class Mesh, class T, class EngineTag>
+typename
+FieldStencilSimple<GradVertToCell<T, Mesh>,
+  Field<Mesh, T, EngineTag> >::Type_t
+gradVertToCell(const Field<Mesh, T, EngineTag> &f)
+{
+  typedef GradVertToCell<T, Mesh> Grad_t;
+  typedef FieldStencilSimple<Grad_t, Field<Mesh, T, EngineTag> > Ret_t;
+  return Ret_t::make(Grad_t(f.fieldEngine()), f);
+}
+
+template<class Mesh, class T, class EngineTag>
+typename
+FieldStencilSimple<GradCellToVert<T, Mesh>,
+  Field<Mesh, T, EngineTag> >::Type_t
+gradCellToVert(const Field<Mesh, T, EngineTag> &f)
+{
+  typedef GradCellToVert<T, Mesh> Grad_t;
+  typedef FieldStencilSimple<Grad_t, Field<Mesh, T, EngineTag> > Ret_t;
+  return Ret_t::make(Grad_t(f.fieldEngine()), f);
+}
+
+template<class Mesh, class T, class EngineTag>
+typename
+FieldStencilSimple<GradSameToSame<T, Mesh, CellType>,
+  Field<Mesh, T, EngineTag> >::Type_t
+gradCellToCell(const Field<Mesh, T, EngineTag> &f)
+{
+  typedef GradSameToSame<T, Mesh, CellType> Grad_t;
+  typedef FieldStencilSimple<Grad_t, Field<Mesh, T, EngineTag> > Ret_t;
+  return Ret_t::make(Grad_t(f.fieldEngine()), f);
+}
+
+template<class Mesh, class T, class EngineTag>
+typename
+FieldStencilSimple<GradSameToSame<T, Mesh, VertexType>,
+  Field<Mesh, T, EngineTag> >::Type_t
+gradVertToVert(const Field<Mesh, T, EngineTag> &f)
+{
+  typedef GradSameToSame<T, Mesh, VertexType> Grad_t;
+  typedef FieldStencilSimple<Grad_t, Field<Mesh, T, EngineTag> > Ret_t;
+  return Ret_t::make(Grad_t(f.fieldEngine()), f);
+}
+
+
+#endif     // POOMA_FIELD_DIFFOPS_GRAD_H
+
+// ACL:rcsinfo
+// ----------------------------------------------------------------------
+// $RCSfile: Grad.h,v $   $Author: pooma $
+// $Revision: 1.10 $   $Date: 2003/10/25 13:26:56 $
+// ----------------------------------------------------------------------
+// ACL:rcsinfo
