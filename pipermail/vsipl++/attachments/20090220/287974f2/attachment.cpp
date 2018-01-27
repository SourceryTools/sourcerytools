/* Copyright (c) 2009 by CodeSourcery.  All rights reserved.

   This file is available for license from CodeSourcery, Inc. under the terms
   of a commercial license and under the GPL.  It is not part of the VSIPL++
   reference implementation and is not available under the BSD license.
*/

/** @file    tests/x-pthreads.cpp
    @author  Jules Bergmann
    @date    2009-02-20
    @brief   VSIPL++ Library: Simple pthreads test
             Modified from https://computing.llnl.gov/tutorials/pthread
*/

/***********************************************************************
  Included Files
***********************************************************************/

#include <pthread.h>
#include <cstdio>
#include <cstdlib>

#include <vsip/initfin.hpp>
#include <vsip/support.hpp>
#include <vsip/matrix.hpp>
#include <vsip/signal.hpp>

#include <vsip_csl/test.hpp>

#define NUM_THREADS     5

using namespace std;
using namespace vsip;



/***********************************************************************
  Definitions
***********************************************************************/

typedef Fft<const_Vector, complex<float>, complex<float>, fft_fwd,
	    by_value, 1, alg_space>
	fft_type;

void*
PrintHello(void* threadid)
{
  length_type size = 10;
  long tid;
  tid = (long)threadid;

  Vector<complex<float> > in(size);
  Vector<complex<float> > out(size, complex<float>(-100));
  fft_type fft(Domain<1>(size), 1.f);
  in = complex<float>(1);
  out = fft(in); 
  test_assert(out.get(0) == complex<float>(size));

  printf("Hello World! It's me, thread #%ld! %f\n", tid, out.get(0).real());
  pthread_exit(NULL);
}

int
main(int argc, char **argv)
{
  vsipl init(argc, argv);

  pthread_t threads[NUM_THREADS];
  int rc;
  long t;
  for(t=0; t<NUM_THREADS; t++)
  {
    printf("In main: creating thread %ld\n", t);
    rc = pthread_create(&threads[t], NULL, PrintHello, (void *)t);
    if (rc)
    {
      printf("ERROR; return code from pthread_create() is %d\n", rc);
      exit(-1);
    }
  }
  pthread_exit(NULL);
}
