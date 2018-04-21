// -*- C++ -*-
// ACL:license
// ----------------------------------------------------------------------
// This software and ancillary information (herein called "SOFTWARE")
// called POOMA (Parallel Object-Oriented Methods and Applications) is
// made available under the terms described here.  The SOFTWARE has been
// approved for release with associated LA-CC Number LA-CC-98-65.
// 
// Unless otherwise indicated, this SOFTWARE has been authored by an
// employee or employees of the University of California, operator of the
// Los Alamos National Laboratory under Contract No. W-7405-ENG-36 with
// the U.S. Department of Energy.  The U.S. Government has rights to use,
// reproduce, and distribute this SOFTWARE. The public may copy, distribute,
// prepare derivative works and publicly display this SOFTWARE without 
// charge, provided that this Notice and any statement of authorship are 
// reproduced on all copies.  Neither the Government nor the University 
// makes any warranty, express or implied, or assumes any liability or 
// responsibility for the use of this SOFTWARE.
// 
// If SOFTWARE is modified to produce derivative works, such modified
// SOFTWARE should be clearly marked, so as not to confuse it with the
// version available from LANL.
// 
// For more information about POOMA, send e-mail to pooma@acl.lanl.gov,
// or visit the POOMA web page at http://www.acl.lanl.gov/pooma/.
// ----------------------------------------------------------------------
// ACL:license

#ifndef POOMA_TINY_TENSOR_ELEMENTS_H
#define POOMA_TINY_TENSOR_ELEMENTS_H

//-----------------------------------------------------------------------------
// Class: 
//    TensorElem
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Overview:
// Trait classes for getting elements of Tiny objects at compile time.
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Forward Declarations:
//-----------------------------------------------------------------------------

template<int D, class T, class E> class Tensor;
template<int D, class T, class E> class TensorEngine;
class Antisymmetric;
class Symmetric;
class Diagonal;

//-----------------------------------------------------------------------------
//
// Unwritable
//
// Trivial class for returning something that can't assigned into:
//
//-----------------------------------------------------------------------------
struct Unwritable
{
public:
  // Assignment is not allowed; make it a no-op:
  // 1) Assign from any other type:
  template<class T>
  void operator=(const T&) { }
  // 2) Assign from another Unwritable:
  void operator=(const Unwritable&) { }
};


//-----------------------------------------------------------------------------
//
// Writable
//
// Returns true or false (compile-time value, really an enum = 0 or 1) for
// whether element (I,J) of a Tensor type is writable. In general, for example
// for Tensors using Full for their EngineTag parameter, this is always
// true. For a Diagonal Tensor, for example, it's false except when I=J.
//
//-----------------------------------------------------------------------------

// Generic (EngineTag) case, all elements writable:
template<int D, class E, int I, int J>
class Writable
{
public:
  enum { value = 1 };
};

// Antisymmetric case, only elements (i,j) with i>j writable:
template<int D, int I, int J>
class Writable<D, Antisymmetric, I, J>
{
public:
  enum { value = (I > J) };
};

// Symmetric case, only elements (i,j) with i>=j writable:
template<int D, int I, int J>
class Writable<D, Symmetric, I, J>
{
public:
  enum { value = (I >= J) };
};

// Diagonal case, only elements (i,j) with i=j writable:
template<int D, int I, int J>
class Writable<D, Diagonal, I, J>
{
public:
  enum { value = (I == J) };
};



//-----------------------------------------------------------------------------
//
// Full Description:
//
// The general templates for the class TensorElem.
// VectorElem should be specialized for Tensor-like classes.
//
// The general definition is for scalars which cannot be subscripted.  We also
// have specializations for tensors with arbitrary engines which just use
// operator() with both integers.  This is the fallback if a given engine type
// doesn't specify anything else.
// 
//-----------------------------------------------------------------------------

template<class V, int I, int J>
struct TensorElem
{
  typedef       V  Element_t;
  typedef const V& ConstElementRef_t;
  typedef       V& ElementRef_t;
  static ConstElementRef_t get(const V& x) { return x; }
  static      ElementRef_t get(      V& x) { return x; }
};

// The "boolean" (really an int) parameter "B" in TensorEngineElem<> flags
// whether the I,J element is writable, according to the engine type. For Full
// engines, all are writable, for things like Antisymmetric, only some are
// writable. The external class Writable<> answers the question whether B is
// true or false, down in the TensorElem<> implementation below.

// General template; empty:
template<int D, class T, class E, int I, int J, int B=1>
struct TensorEngineElem
{
};

// Partial specialization for B=true (B=1); allows getting writable references:
template<int D, class T, class E, int I, int J>
struct TensorEngineElem<D, T, E, I, J, 1>
{
  typedef TensorEngine<D,T,E> V;
  typedef typename V::Element_t         Element_t;
  typedef typename V::CTConstElementRef_t ConstElementRef_t;
  typedef typename V::CTElementRef_t      ElementRef_t;
  static ConstElementRef_t get(const V& x) { return x.template getIJ<I,J>(); }
  static ElementRef_t      get(      V& x) { return x.template getIJ<I,J>(); }
};

// Partial specialization for B=false (B=0); returns dummy unwritable
// references (instances of the trivial Unwritable class, for which
// operator=(T) does nothing:
template<int D, class T, class E, int I, int J>
struct TensorEngineElem<D, T, E, I, J, 0>
{
  typedef TensorEngine<D,T,E> V;
  typedef typename V::Element_t         Element_t;
  typedef typename V::CTConstElementRef_t ConstElementRef_t;
  typedef Unwritable ElementRef_t;
  static ConstElementRef_t get(const V& x) { return x.template getIJ<I,J>(); }
  static ElementRef_t      get(      V& x) { return Unwritable(); }
};


template<int D, class T, class E, int I, int J>
struct TensorElem< Tensor<D,T,E> , I , J>
{
  typedef Tensor<D,T,E> V;
  typedef TensorEngineElem<D,T,E,I,J,Writable<D,E,I,J>::value> TE;
  typedef typename TE::Element_t         Element_t;
  typedef typename TE::ConstElementRef_t ConstElementRef_t;
  typedef typename TE::ElementRef_t      ElementRef_t;
  static ConstElementRef_t get(const V& x) { return TE::get(x.engine()); }
  static      ElementRef_t get(V& x)       { return TE::get(x.engine()); }
};

//-----------------------------------------------------------------------------
//
// TensorAssign
//
// Template metaprogram for copying out of one tensor and into another.
// Input:
//   The tensor we're writing into.
//   Something to copy out of.
//
// Evaluate by recursing on the quadrants of the tensor.
//
//-----------------------------------------------------------------------------

//
// The general case of copying divides the tensor into quadrants
// and calls copy on each quadrant.
// This will be applied if each axis of the tensor is larger than 1.
//

template<class T1, class T2, class Op, int B1, int L1, int B2, int L2>
struct TensorAssign
{
  enum { B11=B1 , L11=L1/2 , B12=B1+L1/2 , L12 = L1-L1/2 };
  enum { B21=B2 , L21=L2/2 , B22=B2+L2/2 , L22 = L2-L2/2 };
  static void apply(T1& x, const T2& y, Op op=Op())
    {
      TensorAssign<T1,T2,Op,B11,L11,B21,L21>::apply(x,y,op);
      TensorAssign<T1,T2,Op,B12,L12,B21,L21>::apply(x,y,op);
      TensorAssign<T1,T2,Op,B11,L11,B22,L22>::apply(x,y,op);
      TensorAssign<T1,T2,Op,B12,L12,B22,L22>::apply(x,y,op);
    }
};

//
// The case for a column.
// Divide the column in two, and recurse.
//

template<class T1, class T2, class Op, int B1, int L1, int B2>
struct TensorAssign<T1,T2,Op,B1,L1,B2,1>
{
  enum { B11=B1 , L11=L1/2 , B12=B1+L1/2 , L12 = L1-L1/2 };
  static void apply(T1& x, const T2& y, Op op=Op())
    {
      TensorAssign<T1,T2,Op,B11,L11,B2,1>::apply(x,y,op);
      TensorAssign<T1,T2,Op,B12,L12,B2,1>::apply(x,y,op);
    }
};

//
// The case for a row.
// Divide the row in two, and recurse.
//

template<class T1, class T2, class Op, int B1, int B2, int L2>
struct TensorAssign<T1,T2,Op,B1,1,B2,L2>
{
  enum { B21=B2 , L21=L2/2 , B22=B2+L2/2 , L22 = L2-L2/2 };
  static void apply(T1& x, const T2& y, Op op=Op())
    {
      TensorAssign<T1,T2,Op,B1,1,B21,L21>::apply(x,y,op);
      TensorAssign<T1,T2,Op,B1,1,B22,L22>::apply(x,y,op);
    }
};

//
// The case for a single element.
// Just do it.
//

template<class T1, class T2, class Op, int B1, int B2>
struct TensorAssign<T1,T2,Op,B1,1,B2,1>
{
  static void apply(T1& x, const T2& y,Op op=Op())
    {
      op(TensorElem<T1,B1,B2>::get(x), TensorElem<T2,B1,B2>::get(y));
    }
};

//
// The case for a two by two block.
// Just do it.
//

template<class T1, class T2, class Op, int B1, int B2>
struct TensorAssign<T1,T2,Op,B1,2,B2,2>
{
  static void apply(T1& x, const T2& y, Op op=Op())
    {
      op(TensorElem<T1,B1  ,B2  >::get(x), TensorElem<T2,B1  ,B2  >::get(y));
      op(TensorElem<T1,B1+1,B2  >::get(x), TensorElem<T2,B1+1,B2  >::get(y));
      op(TensorElem<T1,B1  ,B2+1>::get(x), TensorElem<T2,B1  ,B2+1>::get(y));
      op(TensorElem<T1,B1+1,B2+1>::get(x), TensorElem<T2,B1+1,B2+1>::get(y));
    }
};

//
// The case for a three by three block.
// Just do it.
//

template<class T1, class T2, class Op, int B1, int B2>
struct TensorAssign<T1,T2,Op,B1,3,B2,3>
{
  static void apply(T1& x, const T2& y, Op op=Op())
    {
      op(TensorElem<T1,B1  ,B2  >::get(x), TensorElem<T2,B1  ,B2  >::get(y));
      op(TensorElem<T1,B1+1,B2  >::get(x), TensorElem<T2,B1+1,B2  >::get(y));
      op(TensorElem<T1,B1+2,B2  >::get(x), TensorElem<T2,B1+2,B2  >::get(y));
      op(TensorElem<T1,B1  ,B2+1>::get(x), TensorElem<T2,B1  ,B2+1>::get(y));
      op(TensorElem<T1,B1+1,B2+1>::get(x), TensorElem<T2,B1+1,B2+1>::get(y));
      op(TensorElem<T1,B1+2,B2+1>::get(x), TensorElem<T2,B1+2,B2+1>::get(y));
      op(TensorElem<T1,B1  ,B2+2>::get(x), TensorElem<T2,B1  ,B2+2>::get(y));
      op(TensorElem<T1,B1+1,B2+2>::get(x), TensorElem<T2,B1+1,B2+2>::get(y));
      op(TensorElem<T1,B1+2,B2+2>::get(x), TensorElem<T2,B1+2,B2+2>::get(y));
    }
};

//-----------------------------------------------------------------------------
//
// TensorBinaryCombine
//
// The template parameters are:
// T0: The type for the destination tensor.
// T1: The type for the first source tensor.
// T2: The type for the second source tensor.
// Op: The type for the operator tag.
// B1: The beginning element for the first dimension.
// E1: The ending element for the first dimension
// B2: The beginning element for the second dimension.
// E2: The ending element for the second dimension
//
// The operator tag must have an operator() defined which
// takes in an element from each of the two source vectors
// and returns the element to be stored in the destination.
//
// The number of elements must be > 0.
//
// This metaprogram operates in D dimensions by recursing on the 
// quadrants of the tensor.
//
//-----------------------------------------------------------------------------

//
// The general case divides the tensor into quadrants.
// This will be applied if each axis of the tensor is larger than 1.
//

template<class X, class Y, class Z, class Op, int B1, int L1, int B2, int L2>
struct TensorBinaryCombine
{
  enum { B11=B1 , L11=L1/2 , B12=B1+L1/2 , L12 = L1-L1/2 };
  enum { B21=B2 , L21=L2/2 , B22=B2+L2/2 , L22 = L2-L2/2 };
  static void apply(X& x, const Y& y, const Z& z, Op op)
    {
      TensorBinaryCombine<X,Y,Z,Op,B11,L11,B21,L21>::apply(x,y,z,op);
      TensorBinaryCombine<X,Y,Z,Op,B12,L12,B21,L21>::apply(x,y,z,op);
      TensorBinaryCombine<X,Y,Z,Op,B11,L11,B22,L22>::apply(x,y,z,op);
      TensorBinaryCombine<X,Y,Z,Op,B12,L12,B22,L22>::apply(x,y,z,op);
    }
};

//
// The case for a column.
// Divide the column in two, and recurse.
//

template<class X, class Y, class Z, class Op, int B1, int L1, int B2>
struct TensorBinaryCombine<X,Y,Z,Op,B1,L1,B2,1>
{
  enum { B11=B1 , L11=L1/2 , B12=B1+L1/2 , L12 = L1-L1/2 };
  static void apply(X& x, const Y& y, const Z& z, Op op)
    {
      TensorBinaryCombine<X,Y,Z,Op,B11,L11,B2,1>::apply(x,y,z,op);
      TensorBinaryCombine<X,Y,Z,Op,B12,L12,B2,1>::apply(x,y,z,op);
    }
};

//
// The case for a row.
// Divide the row in two, and recurse.
//

template<class X, class Y, class Z, class Op, int B1, int B2, int L2>
struct TensorBinaryCombine<X,Y,Z,Op,B1,1,B2,L2>
{
  enum { B21=B2 , L21=L2/2 , B22=B2+L2/2 , L22 = L2-L2/2 };
  static void apply(X& x, const Y& y, const Z& z, Op op)
    {
      TensorBinaryCombine<X,Y,Z,Op,B1,1,B21,L21>::apply(x,y,z,op);
      TensorBinaryCombine<X,Y,Z,Op,B1,1,B22,L22>::apply(x,y,z,op);
    }
};

//
// The case for a single element.
// Just do it.
//

template<class X, class Y, class Z, class Op, int B1, int B2>
struct TensorBinaryCombine<X,Y,Z,Op,B1,1,B2,1>
{
  static void apply(X& x, const Y& y, const Z& z, Op op)
    {
      TensorElem<X,B1,B2>::get(x) =
        op(TensorElem<Y,B1,B2>::get(y),TensorElem<Z,B1,B2>::get(z));
    }
};

//
// The case of two by two elements.
// Just do it.
//

template<class X, class Y, class Z, class Op, int B1, int B2>
struct TensorBinaryCombine<X,Y,Z,Op,B1,2,B2,2>
{
  static void apply(X& x, const Y& y, const Z& z, Op op)
    {
      TensorElem<X,B1  ,B2  >::get(x) = 
        op(TensorElem<Y,B1  ,B2  >::get(y),TensorElem<Z,B1  ,B2  >::get(z));
      TensorElem<X,B1+1,B2  >::get(x) = 
        op(TensorElem<Y,B1+1,B2  >::get(y),TensorElem<Z,B1+1,B2  >::get(z));
      TensorElem<X,B1  ,B2+1>::get(x) = 
        op(TensorElem<Y,B1  ,B2+1>::get(y),TensorElem<Z,B1  ,B2+1>::get(z));
      TensorElem<X,B1+1,B2+1>::get(x) = 
        op(TensorElem<Y,B1+1,B2+1>::get(y),TensorElem<Z,B1+1,B2+1>::get(z));
    }
};

//
// The case of three by three elements.
// Just do it.
//

template<class X, class Y, class Z, class Op, int B1, int B2>
struct TensorBinaryCombine<X,Y,Z,Op,B1,3,B2,3>
{
  static void apply(X& x, const Y& y, const Z& z, Op op)
    {
      TensorElem<X,B1  ,B2  >::get(x) = 
        op(TensorElem<Y,B1  ,B2  >::get(y),TensorElem<Z,B1  ,B2  >::get(z));
      TensorElem<X,B1+1,B2  >::get(x) = 
        op(TensorElem<Y,B1+1,B2  >::get(y),TensorElem<Z,B1+1,B2  >::get(z));
      TensorElem<X,B1+2,B2  >::get(x) = 
        op(TensorElem<Y,B1+2,B2  >::get(y),TensorElem<Z,B1+2,B2  >::get(z));
      TensorElem<X,B1  ,B2+1>::get(x) = 
        op(TensorElem<Y,B1  ,B2+1>::get(y),TensorElem<Z,B1  ,B2+1>::get(z));
      TensorElem<X,B1+1,B2+1>::get(x) = 
        op(TensorElem<Y,B1+1,B2+1>::get(y),TensorElem<Z,B1+1,B2+1>::get(z));
      TensorElem<X,B1+2,B2+1>::get(x) = 
        op(TensorElem<Y,B1+2,B2+1>::get(y),TensorElem<Z,B1+2,B2+1>::get(z));
      TensorElem<X,B1  ,B2+2>::get(x) = 
        op(TensorElem<Y,B1  ,B2+2>::get(y),TensorElem<Z,B1  ,B2+2>::get(z));
      TensorElem<X,B1+1,B2+2>::get(x) = 
        op(TensorElem<Y,B1+1,B2+2>::get(y),TensorElem<Z,B1+1,B2+2>::get(z));
      TensorElem<X,B1+2,B2+2>::get(x) = 
        op(TensorElem<Y,B1+2,B2+2>::get(y),TensorElem<Z,B1+2,B2+2>::get(z));
    }
};

#endif

// ACL:rcsinfo
// ----------------------------------------------------------------------
// $RCSfile: TensorElements.h,v $   $Author: cummings $
// $Revision: 1.15 $   $Date: 2001/04/20 20:01:26 $
// ----------------------------------------------------------------------
// ACL:rcsinfo
