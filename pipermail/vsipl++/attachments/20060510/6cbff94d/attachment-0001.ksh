/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */

/** @file    tests/x-fft.cpp
    @author  Jules Bergmann
    @date    2006-04-10
    @brief   VSIPL++ Library: Test Fft with const_view and View.
*/

/***********************************************************************
  Included Files
***********************************************************************/

#include <vsip/initfin.hpp>
#include <vsip/support.hpp>
#include <vsip/matrix.hpp>
#include <vsip/signal.hpp>

#include "test.hpp"

using namespace std;
using namespace vsip;


/***********************************************************************
  Definitions
***********************************************************************/


template <typename T>
void
test_fft()
{
  typedef Fft<const_Vector, T, T, fft_fwd, by_reference, 1, alg_space>
	fft_type;

  length_type size = 64;

  fft_type fft(Domain<1>(size), 1.f);

  Vector<T> in(size);
  Vector<T> out(size);

  in = T(1);

  const_Vector<T> c_in(in);

  fft(c_in, out);

  test_assert(out.get(0) == T(size));
}



/***********************************************************************
  Main
***********************************************************************/

int
main(int argc, char** argv)
{
  vsipl init(argc, argv);

  test_fft<complex<float> >();

  return 0;
}
