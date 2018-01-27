
#include <iostream>
#include <vsip/domain.hpp>
#include <vsip/vector.hpp>
#include <vsip/matrix.hpp>
#include <vsip/domain.hpp>

namespace vsip
{

template <typename T,
          typename Block>
inline
std::ostream&
operator<<(
  std::ostream&		 out,
  vsip::Matrix<T,Block>  mat)
  VSIP_NOTHROW
{
  int i,j;
  out << "Matrix SIZE("<<mat.size(0)<<"x"<<mat.size(1)<<")\n";
  out <<"[\n";
  for(i=0;i<mat.size(0);i++) {
    for(j=0;j<mat.size(1);j++) {
      out << " ";
      out << mat.get(i,j);
      out << " ";
    }
    out <<";\n";
  }
  out <<"]\n";
  return out;
}

template <typename T,
          typename Block>
inline
std::ostream&
operator<<(
  std::ostream&		       out,
  vsip::const_Matrix<T,Block>  mat)
  VSIP_NOTHROW
{
  int i,j;
  out << "Matrix SIZE("<<mat.size(0)<<"x"<<mat.size(1)<<")\n";
  out <<"[\n";
  for(i=0;i<mat.size(0);i++) {
    for(j=0;j<mat.size(1);j++) {
      out << " ";
      out << mat.get(i,j);
      out << " ";
    }
    out <<";\n";
  }
  out <<"]\n";
  return out;
}

}
