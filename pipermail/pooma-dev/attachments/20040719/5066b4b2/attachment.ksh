Index: FieldStencil.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Field/DiffOps/FieldStencil.h,v
retrieving revision 1.5
diff -u -u -r1.5 FieldStencil.h
--- FieldStencil.h	16 Jan 2004 22:00:59 -0000	1.5
+++ FieldStencil.h	19 Jul 2004 15:53:10 -0000
@@ -28,11 +28,7 @@
 
 //-----------------------------------------------------------------------------
 // Classes: 
-//   ApplyFieldStencil     - Tag class for defining an engine capable of
-//                           applying a Field-based stencil.
-//   FieldStencil          - A wrapper class for a user-defined stencil.
-//   Engine                - Specialization for ApplyFieldStencil
-//   NewEngine             - Specializations for ApplyFieldStencil
+//   FieldStencilSimple    - A wrapper class for a user-defined stencil.
 //-----------------------------------------------------------------------------
 
 #ifndef POOMA_FIELD_DIFFOPS_FIELDSTENCIL_H
@@ -42,7 +38,7 @@
  * @ingroup DiffOps
  * @brief
  * This file contains the equipment required to write differential operators
- * that take the form of stencil objects.
+ * that take the form of stencil objects using Fields.
  */
 
 //-----------------------------------------------------------------------------
@@ -51,358 +47,12 @@
 
 #include "Domain/Interval.h"
 #include "Engine/Engine.h"
+#include "Engine/Stencil.h"
 #include "Layout/INode.h"
 #include "Layout/Node.h"
 #include "PETE/ErrorType.h"
 #include "Field/FieldOffset.h"
 
-//-----------------------------------------------------------------------------
-// Forward declarations
-//-----------------------------------------------------------------------------
-
-template <int Dim>
-class DomainLayout;
-
-template<class Functor> class FieldStencil;
-
-/**
- * ApplyFieldStencil is just a tag class for the field-stencil-application
- * engine.
- */
-
-template <class Functor, class Expression>
-struct ApplyFieldStencil;
-
-
-/**
- * Engine<Dim, T, ApplyFieldStencil<Functor, Expression> > is a specialization
- * of Engine for ApplyFieldStencil<Functor>. It uses the supplied stencil 
- * object to apply an arbitrary operation to the input field.
- */
-
-template<int Dim, class T, class Functor, class Expression>
-class Engine<Dim, T, ApplyFieldStencil<Functor, Expression> >
-{
-public:
-
-  //---------------------------------------------------------------------------
-  // Exported typedefs and constants
-
-  typedef ApplyFieldStencil<Functor, Expression>   Tag_t;
-  typedef Functor                                  Functor_t;
-  typedef Expression                               Expression_t;
-  typedef Engine<Dim, T, Tag_t>                    This_t;
-  typedef This_t                                   Engine_t;
-  typedef Interval<Dim>                            Domain_t;
-  typedef T                                        Element_t;
-  typedef ErrorType                                ElementRef_t;
-  typedef typename Expression_t::Engine_t          ExprEngine_t;
-  typedef DomainLayout<Dim>                        Layout_t;
-
-  enum { dimensions = Dim };
-  enum { hasDataObject = ExprEngine_t::hasDataObject };
-  enum { dynamic = false };
-  enum { zeroBased = ExprEngine_t::zeroBased };
-  enum { multiPatch = ExprEngine_t::multiPatch };
-
-  //---------------------------------------------------------------------------
-  // Construct uninitialized Field stencil objects.  It's an error to use an
-  // uninitialized engine, but we need to be able to create uninitialized
-  // engines as placeholders to enable deferred initialization of fields.
-
-  Engine()
-    : domain_m(Pooma::NoInit()), field_m(), functor_m()
-  {
-  }
-
-  //---------------------------------------------------------------------------
-  // Generic layout constructor lets you build an empty stencil object that
-  // has a given domain.
-
-  template<class Layout2>
-  explicit Engine(const Layout2 &layout)
-    : domain_m(layout.domain()), field_m(), functor_m()
-  {
-  }
-
-
-  //---------------------------------------------------------------------------
-  // Construct from a stencil, an input field, and a new total domain.
-  // Note: the way domains work with FieldStencils is a little screwy.
-  // When originally constructing a FieldStencil, the domain of the engine
-  // must match the total domain of the stenciled field in order for the
-  // indexing to work. This is why the zeroBased trait above is false.
-
-  Engine(const Functor_t &functor, const Expression_t &f, 
-	 const Interval<Dim> &domain)
-    : domain_m(domain), field_m(f), functor_m(functor)
-    {
-      for (int d = 0; d < Dim; ++d)
-        {
-          firsts_m[d] = domain[d].first();
-          offset_m[d] = 0;
-        }
-    }
-
-  //---------------------------------------------------------------------------
-  // Construct from another ApplyFieldStencil and an Interval. This is 
-  // simpler than with other domains since we just need to bump the offset.
-
-  Engine(const This_t &e, const Interval<Dim> &domain)
-    : domain_m(Pooma::NoInit()), field_m(e.field()), functor_m(e.functor())
-    {
-      for (int d = 0; d < Dim; ++d)
-        {
-          domain_m[d] = Interval<1>(domain[d].length());
-          offset_m[d] = e.offset_m[d] + domain[d].first();
-          firsts_m[d] = 0;
-        }   
-    }    
-
-  //---------------------------------------------------------------------------
-  // Construct from a new expression and another ApplyFieldStencil.
-
-  template<class OtherExp>
-  Engine(const Expression &f,
-	 const Engine<Dim, T, ApplyFieldStencil<Functor, OtherExp> > &e)
-    : domain_m(e.domain()),
-      field_m(f),
-      functor_m(e.functor())
-  {
-    for (int d = 0; d < Dim; ++d)
-    {
-      offset_m[d] = e.offset(d);
-      firsts_m[d] = e.first(d);
-    }   
-  }    
-
-  //---------------------------------------------------------------------------
-  // Construct from an ApplyFieldStencilNew with a different expression
-  // and an INode.
-
-  template<class OtherExp>
-  Engine(const Engine<Dim, T, ApplyFieldStencil<Functor, OtherExp> > &e,
-	 const INode<Dim> &inode)
-    : domain_m(Pooma::NoInit()),
-      field_m(e.field()(e.viewDomain(inode))),
-      functor_m(e.functor())
-  {
-    for (int d = 0; d < Dim; ++d)
-    {
-      domain_m[d] = Interval<1>(inode.domain()[d].length());
-      offset_m[d] = e.functor().lowerExtent(d);
-      firsts_m[d] = 0;
-    }   
-  }    
-
-  //---------------------------------------------------------------------------
-  // Copy constructor.
-
-  Engine(const This_t &model)
-    : domain_m(model.domain()), field_m(model.field()), 
-      functor_m(model.functor())
-    {
-      for (int d = 0; d < Dim; ++d)
-        {
-          offset_m[d] = model.offset_m[d];
-          firsts_m[d] = model.firsts_m[d];
-        }   
-    }    
-
-  //---------------------------------------------------------------------------
-  // Shallow assignment.
-  
-  This_t &operator=(const This_t &model)
-  {
-    domain_m = model.domain();
-    functor_m = model.functor();
-    field_m.fieldEngine() = model.field().fieldEngine();
-
-    for (int d = 0; d < Dim; ++d)
-    {
-      offset_m[d] = model.offset_m[d];
-      firsts_m[d] = model.firsts_m[d];
-    }   
-
-    return *this;
-  }    
-
-  //---------------------------------------------------------------------------
-  // Element access via ints for speed.
-
-  inline Element_t read(int i) const 
-    {
-      return functor_m(field(),
-		       i + offset_m[0]
-		       );
-    }
-  inline Element_t read(int i, int j) const 
-    {
-      return functor_m(field(),
-		       i + offset_m[0],
-		       j + offset_m[1]
-		       );
-    }
-  inline Element_t read(int i, int j, int k) const 
-    {
-      return functor_m(field(),
-		       i + offset_m[0],
-		       j + offset_m[1],
-		       k + offset_m[2]
-		       );
-    }
-
-  inline Element_t read(const Loc<1> &loc) const 
-    {
-      return functor_m(field(),
-		       loc[0].first() + offset_m[0]
-		       );
-    }
-  inline Element_t read(const Loc<2> &loc) const 
-    {
-      return functor_m(field(),
-		       loc[0].first() + offset_m[0],
-		       loc[1].first() + offset_m[1]
-		       );
-    }
-  inline Element_t read(const Loc<3> &loc) const 
-    {
-      return functor_m(field(),
-		       loc[0].first() + offset_m[0],
-		       loc[1].first() + offset_m[1],
-		       loc[2].first() + offset_m[2]
-		       );
-    }
-
-  inline Element_t operator()(int i) const 
-    {
-      return read(i);
-    }
-  inline Element_t operator()(int i, int j) const 
-    {
-      return read(i, j);
-    }
-  inline Element_t operator()(int i, int j, int k) const 
-    {
-      return read(i, j, k);
-    }
-  inline Element_t operator()(const Loc<Dim> &loc) const 
-    {
-      return read(loc);
-    }
-
-  //---------------------------------------------------------------------------
-  // Return the domain.
-
-  inline const Domain_t &domain() const { return domain_m; }
-
-  //---------------------------------------------------------------------------
-  // Return the first value for the specified direction.
-  
-  inline int first(int i) const
-  {
-    PAssert(i >= 0 && i < Dim);
-    return firsts_m[i];
-  }
-
-  inline int offset(int i) const
-  {
-    PAssert(i >= 0 && i < Dim);
-    return offset_m[i];
-  }
-  
-  //---------------------------------------------------------------------------
-  // Accessors.
-
-  inline const Expression_t &field() const { return field_m; }
-  inline const Functor_t &functor() const { return functor_m; }
-
-  //---------------------------------------------------------------------------
-  // Need to pass lock requests to the contained engine.
-
-  template<class RequestType>
-  inline
-  typename DataObjectRequest<RequestType>::Type_t
-  dataObjectRequest(const DataObjectRequest<RequestType> &req) const
-    {
-      return field().engine().dataObjectRequest(req);
-    }
-
-  //---------------------------------------------------------------------------
-  // viewDomain() gives the region of the expression needed to compute a given
-  // region of the stencil.
-  //---------------------------------------------------------------------------
-
-  inline
-  Interval<Dim> viewDomain(const Interval<Dim> &domain) const
-  {
-    Interval<Dim> ret;
-    int d;
-    for (d = 0; d < Dim; ++d)
-    {
-      ret[d] =
-	Interval<1>(
-		    domain[d].first() + offset_m[d] - functor().lowerExtent(d),
-		    domain[d].last() + offset_m[d] + functor().upperExtent(d)
-		    );
-    }
-
-    return ret;
-  }
-
-  inline
-  INode<Dim> viewDomain(const INode<Dim> &inode) const
-  {
-    return INode<Dim>(inode, viewDomain(inode.domain()));
-  }
-
-  inline
-  Interval<Dim> intersectDomain() const
-  {
-    Interval<Dim> ret;
-    int d;
-    for (d = 0; d < Dim; ++d)
-    {
-      ret[d] =
-	Interval<1>(
-		    domain_m[d].first() + offset_m[d],
-		    domain_m[d].last() + offset_m[d]
-		    );
-    }
-
-    return ret;
-  }
-
-private:
-
-  Interval<Dim> domain_m;
-  Expression_t field_m;
-  Functor_t functor_m;
-  int offset_m[Dim];
-  int firsts_m[Dim];
-};
-
-/**
- * NewEngine<Engine,SubDomain>
- *
- * Specializations of NewEngine for subsetting a constant-function-engine with
- * an arbitrary domain. 
- */
-
-template <int Dim, class T, class F, class E>
-struct NewEngine<Engine<Dim, T, ApplyFieldStencil<F,E> >, Interval<Dim> >
-{
-  typedef Engine<Dim, T, ApplyFieldStencil<F,E> > Type_t;
-};
-
-template <int Dim, class T, class F, class E>
-struct NewEngine<Engine<Dim, T, ApplyFieldStencil<F,E> >, INode<Dim> >
-{
-  typedef typename View1<E, INode<Dim> >::Type_t NewExpr_t;
-  typedef ApplyFieldStencil<F, NewExpr_t> NewTag_t;
-  typedef Engine<Dim, T, NewTag_t > Type_t;
-};
-
 
 /**
  * There are potentially many ways to construct field stencils.
@@ -494,7 +144,7 @@
 
   typedef typename Functor::OutputElement_t OutputElement_t;
 
-  typedef ApplyFieldStencil<Functor, Expression> OutputEngineTag_t;
+  typedef StencilEngine<Functor, Expression> OutputEngineTag_t;
   typedef Field<MeshTag_t, OutputElement_t, OutputEngineTag_t> Type_t;
 
   typedef Engine<outputDim, OutputElement_t, OutputEngineTag_t> SEngine_t;
@@ -574,220 +224,6 @@
   }
 };
 
-/**
- * Specializations for selecting the appropriate evaluator for the Stencil
- * engine.  We just get the appropriate types from the Expression's engine.
- */
-
-template<class Functor, class Expression>
-struct EvaluatorEngineTraits<ApplyFieldStencil<Functor, Expression> >
-{
-  typedef typename CreateLeaf<Expression>::Leaf_t Expr_t;
-  typedef typename
-    ForEach<Expr_t, EvaluatorTypeTag, EvaluatorCombineTag>::Type_t
-      Evaluator_t;
-};
-
-
-/**
- * FieldStencilIntersector is a special intersector that gets used when we come
- * across a stencil object in an expression.
- */
-
-template<int Dim, class Intersect>
-class FieldStencilIntersector
-{
-public:
-
-  //---------------------------------------------------------------------------
-  // Exported typedefs and constants
-
-  typedef typename Intersect::IntersectorData_t         IntersectorData_t;
-  typedef FieldStencilIntersector<Dim, Intersect>       This_t;
-  typedef typename IntersectorData_t::const_iterator    const_iterator;
-  typedef RefCountedPtr<IntersectorData_t>              DataPtr_t;
-  typedef Interval<Dim>                                 Domain_t;
-  
-  enum { dimensions = Intersect::dimensions };
-  
-  //---------------------------------------------------------------------------
-  // Constructors
-
-  FieldStencilIntersector(const This_t &model)
-    : domain_m(model.domain_m), stencilExtent_m(model.stencilExtent_m),
-      intersector_m(model.intersector_m)
-  { }
-
-  FieldStencilIntersector(const Domain_t &dom, const Intersect &intersect,
-		  const GuardLayers<Dim> &stencilExtent)
-    : domain_m(dom), stencilExtent_m(stencilExtent), intersector_m(intersect)
-  { }
-
-  This_t &operator=(const This_t &model)
-  {
-    if (this != &model)
-    {
-      domain_m = model.domain_m;
-      stencilExtent_m = model.stencilExtent_m;
-      intersector_m = model.intersector_m;
-    }
-    return *this;
-  }
-
-  ~FieldStencilIntersector() { }
-
-  inline DataPtr_t &data() { return intersector_m.data(); }
-  inline const DataPtr_t &data() const { return intersector_m.data(); }
-
-  //---------------------------------------------------------------------------
-  // Accessors
-
-  // STL iterator support.
-  
-  inline const_iterator begin() const { return data()->inodes_m.begin(); }
-  inline const_iterator end() const { return data()->inodes_m.end(); }
-
-  //---------------------------------------------------------------------------
-  // Intersect routines
-
-  // All domains.
-  
-  template<class Engine>
-  inline void intersect(const Engine &engine) 
-  {
-    typedef typename NewEngine<Engine, Interval<Dim> >::Type_t NewEngine_t;
-
-    NewEngine_t newEngine(engine, domain_m);
-
-    intersector_m.intersect(newEngine);
-
-    data()->shared(engine.layout().ID(), newEngine.layout().ID());
-  }
-
-  template<class Engine, int Dim2>
-  inline bool intersect(const Engine &engine, const GuardLayers<Dim2> &,
-		        GuardLayers<Dim> &usedGuards) 
-  {
-    intersect(engine);
-    // FIXME: accumulate used guards from intersect above and
-    // stencil extent? I.e. allow  Stencil<>(a(i-1)+a(i+1))?
-    usedGuards = stencilExtent_m;
-    return true;
-  }
-
-private:
-
-  
-  Interval<Dim> domain_m;
-  GuardLayers<Dim> stencilExtent_m;
-  Intersect     intersector_m;
-};
-
-
-/**
- * IntersectEngine specialization
- */
-
-template <int Dim, class T, class Functor, class Expression, class Intersect>
-struct LeafFunctor<Engine<Dim, T, ApplyFieldStencil<Functor,Expression> >,
-  ExpressionApply<IntersectorTag<Intersect> > >
-{
-  typedef int Type_t;
-
-  static
-  int apply(const Engine<Dim, T, ApplyFieldStencil<Functor,Expression> > 
-	    &engine, const ExpressionApply<IntersectorTag<Intersect> > &tag)
-  {
-    // We offset the domain to get a domain in the viewed engine that
-    // the stencil looks at.  The intersection is performed with a view
-    // of the contained engine over this domain.  The resulting answer works
-    // even though the stencil looks beyond this domain, because the viewed
-    // field guarantees enough guard layers for the stencil to work.
-    // (Presently this assumption isn't checked anywhere, so a lack of guard
-    // cells results in an error in the multipatch inode view.)
-
-    typedef FieldStencilIntersector<Dim, Intersect> NewIntersector_t;
-    GuardLayers<Dim> stencilExtent;
-    for (int i=0; i<Dim; ++i) {
-      stencilExtent.lower(i) = engine.functor().lowerExtent(i);
-      stencilExtent.upper(i) = engine.functor().upperExtent(i);
-    }
-    NewIntersector_t newIntersector(engine.intersectDomain(),
-				    tag.tag().intersector_m,
-				    stencilExtent);
-
-    expressionApply(engine.field(),
-		    IntersectorTag<NewIntersector_t>(newIntersector));
-
-    return 0;
-  }
-};
-
-
-template<class RequestType> class DataObjectRequest;
-
-/**
- * Specialization of DataObjectRequest engineFunctor to pass the request to
- * the contained engine.
- */
-
-template <int Dim, class T, class Functor, class Expression, class RequestType>
-struct EngineFunctor<Engine<Dim, T, ApplyFieldStencil<Functor,Expression> >,
-  DataObjectRequest<RequestType> >
-{
-  typedef typename DataObjectRequest<RequestType>::Type_t Type_t;
-
-  static Type_t
-  apply(const Engine<Dim, T, ApplyFieldStencil<Functor, Expression> > &engine,
-	const DataObjectRequest<RequestType> &tag)
-  {
-    return engineFunctor(engine.field().engine(), tag);
-  }
-};
-
-/**
- * The generic version of EngineView just accesses the contained engine and
- * applies EngineView to it.
- *
- * The default version doesn't fiddle with the domain, since it is assumed
- * that the typical view doesn't need to.  Specializations will be required
- * for INode views etc...  Probably we should come up with a generic approach.
- */
-
-template <int Dim, class T, class Functor, class Expression, class Tag>
-struct LeafFunctor<Engine<Dim, T, ApplyFieldStencil<Functor,Expression> >,
-  EngineView<Tag> >
-{
-  typedef LeafFunctor<Expression, EngineView<Tag> > LeafFunctor_t;
-  typedef typename LeafFunctor_t::Type_t NewViewed_t;
-  typedef Engine<Dim, T, ApplyFieldStencil<Functor, NewViewed_t> > Type_t;
-
-  static
-  Type_t apply(const Engine<Dim, T,
-	       ApplyFieldStencil<Functor, Expression> > &engine,
-	       const EngineView<Tag> &tag)
-  {
-    return Type_t(LeafFunctor_t::apply(engine.field(), tag),
-		  engine
-		  );
-  }
-};
-
-template <int Dim, class T, class Functor, class Expression, class Tag>
-struct LeafFunctor<Engine<Dim, T, ApplyFieldStencil<Functor,Expression> >,
-  ExpressionApply<Tag> >
-{
-  typedef LeafFunctor<Expression, ExpressionApply<Tag> > LeafFunctor_t;
-  typedef int Type_t;
-
-  static
-  Type_t apply(const Engine<Dim, T,
-	       ApplyFieldStencil<Functor, Expression> > &engine,
-	       const ExpressionApply<Tag> &tag)
-  {
-    return LeafFunctor_t::apply(engine.field(), tag);
-  }
-};
 
 #endif // POOMA_FIELD_DIFFOPS_FIELDSTENCIL_H
 
Index: Stencil.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Engine/Stencil.h,v
retrieving revision 1.50
diff -u -u -r1.50 Stencil.h
--- Stencil.h	16 Jan 2004 22:00:59 -0000	1.50
+++ Stencil.h	19 Jul 2004 15:54:04 -0000
@@ -155,6 +155,7 @@
 #include "Utilities/WrappedInt.h"
 
 template<int D, class T, class E> class Array;
+template<class M, class T, class E> class Field;
 template<class ST> class Stencil;
 
 /**
@@ -246,6 +247,22 @@
   enum { multiPatch = ExprEngine_t::multiPatch };
   enum { zeroBased = true };
 
+  // FIXME: using any of the two below disables using of
+  // expression engines as Expression type, because these
+  // are not default-constructible.
+  // Only FieldEngine ever default-constructs these, though.
+
+  Engine()
+    : function_m(), expression_m(), domain_m(Pooma::NoInit())
+  {
+  }
+
+  template <class Layout2>
+  explicit Engine(const Layout2 &layout)
+    : function_m(), expression_m(), domain_m(layout.domain())
+  {
+  }
+
   //============================================================
   // Construct from a Function object (effectively a stencil)
   // and an expression (effectively the input array), and
@@ -307,6 +324,30 @@
     }
   }
 
+  template <int Dim, class Tx, class EngineTag>
+  void initExpressionFromModel(const Array<Dim, Tx, EngineTag>& model)
+  {
+    expression_m.engine() = model.engine();
+  }
+
+  template <class Mesh, class Tx, class EngineTag>
+  void initExpressionFromModel(const Field<Mesh, Tx, EngineTag>& model)
+  {
+    expression_m.fieldEngine() = model.fieldEngine();
+  }
+
+  This_t &operator=(const This_t &model)
+  {
+    domain_m = model.domain();
+    function_m = model.function();
+    initExpressionFromModel(model.expression());
+    for (int d = 0; d < D; ++d)
+    {
+      domain_m[d] = model.domain()[d];
+      offset_m[d] = model.offset(d);
+    }
+  }
+
   //============================================================
   // Element access via ints for speed.  The arguments correspond to
   // output elements, not input elements.
@@ -452,6 +493,7 @@
 
   inline const Function   &function() const   { return function_m; }
   inline const Expression &expression() const { return expression_m; }
+  int offset(int d) const { return offset_m[d]; }
 
 private:
 
@@ -612,6 +654,9 @@
     : function_m(init)
   { }
 
+  /// @name Array apply
+  //@{
+
   template<int D, class T, class E>
   typename View1<Stencil<Function>,Array<D,T,E> >::Type_t
   operator()(const Array<D,T,E>& expr) const
@@ -628,6 +673,8 @@
     typedef View2<Stencil<Function>,Array<D,T,E>,Dom> Ret_t;
     return Ret_t::make(*this,expr,domain);
   }
+
+  //@}
 
   template<int D>
   inline
