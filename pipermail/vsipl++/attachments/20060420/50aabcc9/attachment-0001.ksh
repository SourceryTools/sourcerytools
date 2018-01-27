#include <iostream.h>
#include <vsip/support.hpp>
#include <vsip/matrix.hpp>
#include <vsip/impl/layout.hpp>
#include <vsip/impl/working-view.hpp>
#include <vsip/impl/fast-block.hpp>
#include <vsip/impl/math-enum.hpp>

#include "output.hpp"

using namespace vsip;
using namespace vsip::impl;
//using namespace sal_impl;

main()
{
  typedef Layout<2, col2_type, Stride_unit_dense, Cmplx_inter_fmt> t_data_LP;
  typedef Fast_block<2, float, t_data_LP> t_data_block_type;

  int m = 3;
  int n = 3;
  float a_mat_data[] = { 1.0, 1.0, 1.0,
                         1.0, 2.0, 3.0,
	  	         9.0, 2.0, 3.0}; // A matrix data

  Matrix<float> a(m,n);      // A matrix, we will decompose this matrix
  Matrix<float, t_data_block_type> a_mirror(m,n);
  float *a_block_ptr = a.block().impl_data();

  memcpy(a_block_ptr,a_mat_data,m*n*sizeof(float));

  a_mirror = a(Domain<2>(Domain<1>(m-1, -1, m),
                         Domain<1>(n-1, -1, n)));

  cout << "A Matrix"<< endl;
  cout << a << endl;
  cout << "A mirror Matrix"<< endl;
  cout << a_mirror << endl;

}
