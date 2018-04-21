#include <vsip/initfin.hpp>
#include <vsip/support.hpp>
#include <vsip/map.hpp>
#include <vsip/vector.hpp>
#include <vsip/selgen.hpp>
#include <vsip_csl/output.hpp>
#include <vsip/opt/general_dispatch.hpp>
#include <vsip/core/reductions/reductions_idx.hpp>

using namespace vsip;
using namespace vsip::impl;
using namespace vsip_csl;

#define DEBUG 1

int main(int argc, char **argv)
{
  // init vsip lib
  vsipl vpp(argc,argv);
  int const size = 256;
  int i;

  // Determine number of processors to map to.
  // We will take the ceiling of the number of processors/2. This will
  // ensure that we will map to at least one processor
  int num_procs_to_map = (int)ceil((float)num_processors()/2.);

  Vector<processor_type> pvec(num_procs_to_map);
  for(i=0;i<num_procs_to_map;i++) pvec(i) = i;
  Map<> map(pvec,num_procs_to_map);

  Vector<float,Dense<1,float,row1_type,Map<> > > my_test_vector(size, map);

  // also make vector that contains ramp function
  Vector<processor_type> pvec_in(1); pvec_in(0) = processor_set()(0);
  Map<> map_in(pvec_in);
  Vector<float,Dense<1,float,row1_type,Map<> > > vec_in(size,map_in);
  if(map_in.subblock() != no_subblock)
  {
    vec_in.local() = ramp(float(0), float(1), size);
  }
  my_test_vector = vec_in;

#if DEBUG == 1
  std::cout << my_test_vector.local();
#endif

  float max;
  Index<1> max_idx;
  max = maxval(my_test_vector,max_idx);

#if DEBUG == 1
  std::cout << "Max "<<max<<" at "<<max_idx<<"\n";
#endif

  if(max == float(size-1) && max_idx[0] == size-1)
  {
#if DEBUG == 1
    std::cout << "Test passed\n";
#endif
    return 0;
  } else
  {
#if DEBUG == 1
    std::cout << "Test failed\n";
#endif
    return -1;
  }

}
