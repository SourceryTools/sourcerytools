? generic_reader.hpp
? matlab_file.cpp
? matlab_file.hpp
? matlab_temp
? temp
Index: matlab.hpp
===================================================================
RCS file: matlab.hpp
diff -N matlab.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ matlab.hpp	6 Jul 2006 16:29:40 -0000
@@ -0,0 +1,302 @@
+#ifndef VSIP_CSL_MATLAB_HPP
+#define VSIP_CSL_MATLAB_HPP
+
+#include <stdint.h>
+#include <iostream>
+#include <vsip/support.hpp>
+#include <vsip/impl/metaprogramming.hpp>
+#include <vsip/impl/fns_elementwise.hpp>
+#include <vsip/impl/length.hpp>
+#include <vsip/impl/domain-utils.hpp>
+
+namespace vsip_csl
+{
+
+namespace matlab
+{
+  struct data_element
+  {
+    int32_t type;
+    uint32_t size;
+  };
+
+  template <vsip::dimension_type Dim>
+  struct view_header
+  {
+    data_element header;
+    data_element array_flags_header;
+    uint32_t array_flags[2];
+    data_element dim_header;
+    uint32_t dim[Dim + Dim%2]; //the dim has to be aligned to an 8 byte boundary
+    data_element array_name_header;
+  };
+
+  // helper struct to get the imaginary part of a view.
+  template <typename ViewT,
+            bool IsComplex =
+	      vsip::impl::Is_complex<typename ViewT::value_type>::value>
+  struct Subview_helper;
+
+  template <typename ViewT>
+  struct Subview_helper<ViewT,true>
+  {
+    typedef typename ViewT::realview_type realview_type;
+    typedef typename ViewT::imagview_type imagview_type;
+
+    static realview_type real(ViewT v) { return v.real(); }
+    static imagview_type imag(ViewT v) { return v.imag(); }
+  };
+
+  template <typename ViewT>
+  struct Subview_helper<ViewT,false>
+  {
+    typedef ViewT realview_type;
+    typedef ViewT imagview_type;
+
+    static realview_type real(ViewT v) { return v; }
+    static imagview_type imag(ViewT v) { return v; }
+  };
+
+  template <typename T = char,
+	    bool to_swap_or_not_to_swap = false,
+	    size_t type_size = sizeof(T)>
+  struct Swap_value 
+  { 
+    static void swap(T *d) {d=d;} 
+  };
+
+  template <typename T>
+  struct Swap_value<T,true,2>
+  {
+    static void swap(T* d)
+    {
+      char *p = reinterpret_cast<char*>(d);
+      std::swap(p[0],p[1]);
+    }
+  };
+
+  template <typename T>
+  struct Swap_value<T,true,4>
+  {
+    static void swap(T* d)
+    {
+      char *p = reinterpret_cast<char*>(d);
+      std::swap(p[0],p[3]);
+      std::swap(p[1],p[2]);
+    }
+  };
+
+  template <typename T>
+  struct Swap_value<T,true,8>
+  {
+    static void swap(T* d)
+    {
+      char *p = reinterpret_cast<char*>(d);
+      std::swap(p[0],p[7]);
+      std::swap(p[1],p[6]);
+      std::swap(p[2],p[5]);
+      std::swap(p[3],p[4]);
+    }
+  };
+
+  // a swap wrapper function
+  template <typename T>
+  void swap(T *data, bool swap_bytes)
+  {
+    if(swap_bytes)
+      Swap_value<T,true>::swap(data);
+  }
+
+  // swaps the header of a view
+  template <vsip::dimension_type dim>
+  void swap_header(view_header<dim> &header, bool swap_bytes)
+  {
+    if(swap_bytes)
+    {
+      // swap all fields
+      Swap_value<int32_t,true>::swap(&(header.header.type));
+      Swap_value<uint32_t,true>::swap(&(header.header.size));
+      Swap_value<int32_t,true>::swap(&(header.array_flags_header.type));
+      Swap_value<uint32_t,true>::swap(&(header.array_flags_header.size));
+      Swap_value<int32_t,true>::swap(&(header.dim_header.type));
+      Swap_value<uint32_t,true>::swap(&(header.dim_header.size));
+      Swap_value<int32_t,true>::swap(&(header.array_name_header.type));
+      Swap_value<uint32_t,true>::swap(&(header.array_name_header.size));
+      for(vsip::index_type i=0;i<dim;i++)
+        Swap_value<uint32_t,true>::swap(&(header.dim[i]));
+      for(vsip::index_type i=0;i<2;i++)
+        Swap_value<uint32_t,true>::swap(&(header.array_flags[i]));
+    }
+  }
+
+  // generic reader that allows us to read a generic type and cast to another
+  
+  // the read function for real or complex depending of the view that was
+  // passed in
+  template <typename T1,
+	    typename ViewT>
+  void read(std::istream& is,ViewT v,bool swap_bytes)
+  {
+    vsip::dimension_type const View_dim = ViewT::dim;
+    vsip::Index<View_dim> my_index;
+    vsip::impl::Length<View_dim> v_extent = extent(v);
+    T1 data;
+    typedef typename ViewT::value_type scalar_type;
+
+    // get num_points
+    vsip::length_type num_points = v.size();
+
+    // read all the points
+    for(vsip::index_type i=0;i<num_points;i++) {
+      is.read(reinterpret_cast<char*>(&data),sizeof(data));
+      swap<T1>(&data,swap_bytes);
+      put(v,my_index,scalar_type(data));
+
+      // increment index
+      my_index = vsip::impl::next(v_extent,my_index);
+    }
+
+  }
+
+  // a write function to output a view to a matlab file.
+  template <typename ViewT>
+  void write(std::ostream& os,ViewT v)
+  {
+    vsip::dimension_type const View_dim = ViewT::dim;
+    vsip::Index<View_dim> my_index;
+    vsip::impl::Length<View_dim> v_extent = extent(v);
+    typename ViewT::value_type data;
+
+    // get num_points
+    vsip::length_type num_points = v.size();
+
+    // write all the points
+    for(vsip::index_type i=0;i<num_points;i++) {
+      data = get(v,my_index);
+      os.write(reinterpret_cast<char*>(&data),sizeof(data));
+
+      // increment index
+      my_index = vsip::impl::next(v_extent,my_index);
+    }
+
+  }
+
+  struct header
+  {
+    char description[116];
+    char subsyt_data[8];
+    char version[2];
+    uint16_t endian;
+  };
+
+  // constants for matlab binary format
+
+  // data types
+  static int const miINT8           = 1;
+  static int const miUINT8          = 2;
+  static int const miINT16          = 3;
+  static int const miUINT16         = 4;
+  static int const miINT32          = 5;
+  static int const miUINT32         = 6;
+  static int const miSINGLE         = 7;
+  static int const miDOUBLE         = 9;
+  static int const miINT64          = 12;
+  static int const miUINT64         = 13;
+  static int const miMATRIX         = 14;
+  static int const miCOMPRESSED     = 15;
+  static int const miUTF8           = 16;
+  static int const miUTF16          = 17;
+  static int const miUTF32          = 18;
+  
+  // class types
+  static int const mxCELL_CLASS     = 1;
+  static int const mxSTRUCT_CLASS   = 2;
+  static int const mxOBJECT_CLASS   = 3;
+  static int const mxCHAR_CLASS     = 4;
+  static int const mxSPARSE_CLASS   = 5;
+  static int const mxDOUBLE_CLASS   = 6;
+  static int const mxSINGLE_CLASS   = 7;
+  static int const mxINT8_CLASS     = 8;
+  static int const mxUINT8_CLASS    = 9;
+  static int const mxINT16_CLASS    = 10;
+  static int const mxUINT16_CLASS   = 11;
+  static int const mxINT32_CLASS    = 12;
+  static int const mxUINT32_CLASS   = 13;
+
+  // matlab header traits
+  template <int size,bool is_signed,bool is_int>
+  struct Matlab_header_traits;
+
+  template <>
+  struct Matlab_header_traits<1, true, true> // char
+  { 
+    static int const value_type = miINT8;
+    static uint8_t const class_type = mxINT8_CLASS; 
+  };
+
+  template <>
+  struct Matlab_header_traits<1, false, true> // unsigned char
+  { 
+    static int const value_type = miUINT8;
+    static uint8_t const class_type = mxUINT8_CLASS; 
+  };
+
+  template <>
+  struct Matlab_header_traits<2, true, true> // short
+  { 
+    static int const value_type = miINT16;
+    static uint8_t const class_type = mxINT16_CLASS; 
+  };
+
+  template <>
+  struct Matlab_header_traits<2, false, true> // unsigned short
+  { 
+    static int const value_type = miUINT16;
+    static uint8_t const class_type = mxUINT16_CLASS; 
+  };
+
+  template <>
+  struct Matlab_header_traits<4, true, true> // int
+  { 
+    static int const value_type= miINT32;
+    static uint8_t const class_type= mxINT32_CLASS;
+  };
+
+  template <>
+  struct Matlab_header_traits<4, false, true> // unsigned int
+  { 
+    static int const value_type= miUINT32;
+    static uint8_t const class_type= mxUINT32_CLASS;
+  };
+
+  template <>
+  struct Matlab_header_traits<4, true, false> // float
+  { 
+    static int const value_type= miSINGLE;
+    static uint8_t const class_type= mxSINGLE_CLASS;
+  };
+
+  template <>
+  struct Matlab_header_traits<8, true, false> // double
+  { 
+    static int const value_type= miDOUBLE;
+    static uint8_t const class_type= mxDOUBLE_CLASS;
+  };
+
+  // matlab desired layouts
+  template <template <typename,typename> class View>
+  struct Matlab_desired_LP
+  {
+    static vsip::dimension_type const dim = vsip::impl::Dim_of_view<View>::dim;
+    typedef vsip::impl::Layout<dim,
+                     typename vsip::impl::Col_major<dim>::type,
+                     vsip::impl::Stride_unit_dense,
+		     vsip::impl::Cmplx_split_fmt> type;
+  };
+
+
+} // namesapce matlab
+
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_MATLAB_HPP
Index: matlab_bin_formatter.hpp
===================================================================
RCS file: matlab_bin_formatter.hpp
diff -N matlab_bin_formatter.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ matlab_bin_formatter.hpp	6 Jul 2006 16:29:40 -0000
@@ -0,0 +1,389 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip_csl/matlab_bin_formatter.hpp
+    @author  Assem Salama
+    @date    2006-05-22
+    @brief   VSIPL++ CodeSourcery Library: Matlab binary formatter
+*/
+
+#ifndef VSIP_CSL_MATLAB_BIN_FORMATTER_HPP
+#define VSIP_CSL_MATLAB_BIN_FORMATTER_HPP
+
+#include <stdint.h>
+#include <string>
+#include <limits>
+#include <vsip_csl/matlab.hpp>
+#include <vsip/impl/fns_scalar.hpp>
+#include <vsip/impl/fns_elementwise.hpp>
+#include <vsip/impl/metaprogramming.hpp>
+#include <vsip/impl/view_traits.hpp>
+#include <vsip/impl/extdata.hpp>
+
+namespace vsip_csl
+{
+
+  struct Matlab_bin_hdr
+  {
+    Matlab_bin_hdr(std::string const& descr) : 
+      description(descr),version("MATLAB 5.0 : ") {}
+    Matlab_bin_hdr() : 
+      description(" "),version("MATLAB 5.0 : ") {}
+
+    // description
+    std::string description;
+    std::string version;
+    uint16_t endian;
+
+  };
+
+  template <typename ViewT>
+  struct Matlab_bin_formatter
+  {
+    Matlab_bin_formatter(ViewT v,std::string const& name) :
+      view(v), name(name), header()  {}
+    Matlab_bin_formatter(ViewT v,std::string const& name,
+      Matlab_bin_hdr &h) :
+        view(v), name(name), header(h)  {}
+
+    ViewT view;
+    std::string name;
+    Matlab_bin_hdr header;
+
+  };
+
+  struct Matlab_view_header
+  {
+    bool        swap_bytes;
+    char        array_name[128];
+    bool        is_complex;
+    uint8_t     class_type;
+    uint32_t    num_dims;
+    uint32_t    dims[3]; // max dimensions
+    std::istream::pos_type next_header;
+  };
+
+
+} // namespace vsip_csl
+
+/****************************************************************************
+ * Definitions
+ ***************************************************************************/
+
+namespace vsip_csl
+{
+
+// operator to write matlab header
+inline
+std::ostream&
+operator<<(
+  std::ostream&           o,
+  Matlab_bin_hdr const&   h)
+{
+  matlab::header m_hdr;
+
+  // set hdr to spaces
+  memset(&(m_hdr),' ',sizeof(m_hdr));
+  strncpy(m_hdr.description, h.version.data(), h.version.length());
+  strncpy(m_hdr.description+h.version.length(), h.description.data(),
+    h.description.length());
+  m_hdr.version[1] = 0x01; m_hdr.version[0] = 0x00;
+  m_hdr.endian = 'M' << 8 | 'I';
+
+  // write header
+  o.write(reinterpret_cast<char*>(&m_hdr),sizeof(m_hdr));
+
+  return o;
+}
+// operator to write a view to a matlab file
+template <typename T,
+          typename Block0,
+	  template <typename,typename> class const_View>
+inline
+std::ostream&
+operator<<(
+  std::ostream&                                       o,
+  Matlab_bin_formatter<const_View<T,Block0> > const&  mbf)
+{
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+  matlab::data_element temp_data_element;
+  size_t    sz;
+  matlab::view_header<vsip::impl::Dim_of_view<const_View>::dim > m_view;
+  vsip::length_type num_points = mbf.view.size();
+  vsip::dimension_type v_dims = vsip::impl::Dim_of_view<const_View>::dim;
+
+  memset(&m_view,0,sizeof(m_view));
+
+  // matrix data type
+  m_view.header.type = matlab::miMATRIX;
+  m_view.header.size = 1; // TEMP
+
+  // array flags
+  m_view.array_flags_header.type = matlab::miUINT32;
+  m_view.array_flags_header.size = 8;
+  if(vsip::impl::Is_complex<T>::value) 
+    m_view.array_flags[0] |= (1<<11); // Complex
+
+  // fill in class
+  m_view.array_flags[0] |= 
+    (matlab::Matlab_header_traits<sizeof(scalar_type),
+                  std::numeric_limits<scalar_type>::is_signed,
+                  std::numeric_limits<scalar_type>::is_integer>::class_type);
+
+  // dimension sizes
+  m_view.dim_header.type = matlab::miINT32;
+  m_view.dim_header.size = v_dims*4; // 4 bytes per dimension
+  // fill in dimension
+  for(vsip::dimension_type i =0;i<v_dims;i++)
+  {
+    m_view.dim[i] = mbf.view.size(i);
+  }
+
+  // if this view is a vector, we need to make second dimension a one
+  if(v_dims == 1)
+  {
+    m_view.dim_header.size += 4;
+    m_view.dim[1] = 1;
+  }
+
+  // array name
+  m_view.array_name_header.type = matlab::miINT8;
+  m_view.array_name_header.size = mbf.name.length();
+
+
+  // calculate size
+  sz = sizeof(m_view)-8;
+  sz += mbf.name.length();
+  sz += (8-mbf.name.length())&0x7;
+  sz += 8; // 8 bytes of header for real data
+  if(vsip::impl::Is_complex<T>::value) sz += 8; // 8 more for complex data
+  sz += num_points*sizeof(T);
+  m_view.header.size = sz;
+
+  o.write(reinterpret_cast<char*>(&m_view),sizeof(m_view));
+
+  // write array name
+  o.write(mbf.name.c_str(),mbf.name.length());
+  // pad
+  { 
+    char c=0;
+    for(vsip::length_type i=0;i<((8-mbf.name.length())&0x7);i++) o.write(&c,1);
+  }
+
+  // write data
+  {
+  
+    // make sure we don't need a copy if we use Ext data
+    if(vsip::impl::Ext_data_cost<Block0,
+      typename matlab::Matlab_desired_LP<const_View>::type >::value==0)
+    {
+      vsip::impl::Ext_data<Block0,
+	                 typename matlab::Matlab_desired_LP<const_View>::type >
+	     
+	       m_ext(mbf.view.block());
+
+      typedef typename vsip::impl::Ext_data<Block0,
+	typename matlab::Matlab_desired_LP<const_View>::type >::storage_type
+		storage_type;
+
+      temp_data_element.type = matlab::Matlab_header_traits<sizeof(scalar_type),
+                  std::numeric_limits<scalar_type>::is_signed,
+                  std::numeric_limits<scalar_type>::is_integer>::value_type;
+
+      temp_data_element.size = num_points*sizeof(scalar_type);
+      for(int i=0;i<=vsip::impl::Is_complex<T>::value;i++)
+      {
+        o.write(reinterpret_cast<char*>(&temp_data_element),
+                  sizeof(temp_data_element));
+        if(i==0) o.write(reinterpret_cast<char*>
+             (storage_type::get_real_ptr(m_ext.data())),
+                  num_points*sizeof(scalar_type));
+        else o.write(reinterpret_cast<char*>
+             (storage_type::get_imag_ptr(m_ext.data())),
+                  num_points*sizeof(scalar_type));
+      }
+    }
+    else
+    {
+      typedef matlab::Subview_helper<const_View<T,Block0> > subview;
+      typedef typename subview::realview_type r_v;
+      typedef typename subview::imagview_type i_v;
+
+      // conventional way
+      temp_data_element.type = matlab::Matlab_header_traits<sizeof(scalar_type),
+                  std::numeric_limits<scalar_type>::is_signed,
+                  std::numeric_limits<scalar_type>::is_integer>::value_type;
+
+      temp_data_element.size = num_points*sizeof(scalar_type);
+      for(int i=0;i<=vsip::impl::Is_complex<T>::value;i++)
+      {
+        o.write(reinterpret_cast<char*>(&temp_data_element),
+                  sizeof(temp_data_element));
+        if(i==0) matlab::write<r_v>(o,subview::real(mbf.view));
+        else     matlab::write<i_v>(o,subview::imag(mbf.view));
+      }
+    }
+  }
+
+  return o;
+}
+
+// operator to read matlab header
+inline
+std::istream&
+operator>>(
+  std::istream&           is,
+  Matlab_bin_hdr          &h)
+{
+  matlab::header m_hdr;
+
+  // read header
+  is.read(reinterpret_cast<char*>(&m_hdr),sizeof(m_hdr));
+
+  h.version[1] = m_hdr.version[1];
+  h.version[0] = m_hdr.version[0];
+  h.endian = m_hdr.endian;
+
+  return is;
+}
+
+// operator to read view from matlab file
+template <typename T,
+          typename Block0,
+	  template <typename,typename> class View>
+inline
+std::istream&
+operator>>(
+  std::istream&                                       is,
+  Matlab_bin_formatter<View<T,Block0> >               mbf)
+{
+  matlab::data_element temp_data_element;
+  matlab::view_header<vsip::impl::Dim_of_view<View>::dim> m_view;
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+  typedef matlab::Subview_helper<View<T,Block0> > subview;
+  typedef typename subview::realview_type r_v;
+  typedef typename subview::imagview_type i_v;
+  vsip::dimension_type v_dim = vsip::impl::Dim_of_view<View>::dim;
+
+
+  // read header
+  is.read(reinterpret_cast<char*>(&m_view),sizeof(m_view));
+
+  // do we need to swap fields?
+  matlab::swap_header(m_view,mbf.header.endian);
+
+  // is this complex?
+  if(vsip::impl::Is_complex<T>::value && !(m_view.array_flags[0]&(1<<11)))
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Trying to read complex matrix into a real matrix"));
+
+
+  // is this the same class?
+  if(!((m_view.array_flags[0] & 0xff) == 
+            (matlab::Matlab_header_traits<sizeof(scalar_type),
+                  std::numeric_limits<scalar_type>::is_signed,
+                  std::numeric_limits<scalar_type>::is_integer>::class_type)
+	    ))
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Trying to read a matrix of a different class"));
+
+  // do dimensions agree?
+  if(v_dim == 1) m_view.dim_header.size -= 4; // special case for vectors
+  if(v_dim != (m_view.dim_header.size/4))
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Trying to read a matrix of different dimensions"));
+
+  for(vsip::dimension_type i=0;i<v_dim;i++)
+    if(mbf.view.size(i) != m_view.dim[i])
+      VSIP_IMPL_THROW(std::runtime_error(
+        "Matrix dimensions don't agree"));
+
+  // read array name
+  if(m_view.array_name_header.type & 0xffff0000)
+  {
+    // array name is short
+
+  }
+  else
+  {
+    int length = m_view.array_name_header.size;
+    char c;
+    char c_array[128];
+    // the name is longer than 4 bytes
+    if(length > 128)
+      VSIP_IMPL_THROW(std::runtime_error(
+        "Name of matrix is too large"));
+
+    is.read(c_array,length);
+    c_array[length] = 0;
+    // read padding
+    for(int i=0;i<((8-length)&0x7);i++) is.read(&c,1);
+  }
+
+  // read data, we will go in this loop twice if we have complex data
+  for (int i=0;i <= vsip::impl::Is_complex<T>::value;i++)
+  {
+    uint16_t endian = mbf.header.endian;
+    bool     swap_value = endian == ('I'<<8 | 'M');
+
+    // read data header
+    is.read(reinterpret_cast<char*>(&temp_data_element),
+            sizeof(temp_data_element));
+
+    // should we swap this field?
+    matlab::swap<int32_t>(&(temp_data_element.type),swap_value);
+    matlab::swap<uint32_t>(&(temp_data_element.size),swap_value);
+
+
+    // Because we don't know how the data was stored, we need to instantiate
+    // generic_reader which can read a type and cast into a different one
+    if(temp_data_element.type == matlab::miINT8) 
+    {
+      if(i==0)matlab::read<int8_t,r_v>(is,subview::real(mbf.view),swap_value);
+      else    matlab::read<int8_t,i_v>(is,subview::imag(mbf.view),swap_value);
+    }
+    else if(temp_data_element.type == matlab::miUINT8) 
+    {
+      if(i==0)matlab::read<uint8_t,r_v>(is,subview::real(mbf.view),swap_value);
+      else    matlab::read<uint8_t,i_v>(is,subview::imag(mbf.view),swap_value);
+    }
+    else if(temp_data_element.type == matlab::miINT16) 
+    {
+      if(i==0)matlab::read<int16_t,r_v>(is,subview::real(mbf.view),swap_value);
+      else    matlab::read<int16_t,i_v>(is,subview::imag(mbf.view),swap_value);
+    }
+    else if(temp_data_element.type == matlab::miUINT16) 
+    {
+      if(i==0)matlab::read<uint16_t,r_v>(is,subview::real(mbf.view),swap_value);
+      else    matlab::read<uint16_t,i_v>(is,subview::imag(mbf.view),swap_value);
+    }
+    else if(temp_data_element.type == matlab::miINT32) 
+    {
+      if(i==0)matlab::read<int32_t,r_v>(is,subview::real(mbf.view),swap_value);
+      else    matlab::read<int32_t,i_v>(is,subview::imag(mbf.view),swap_value);
+    }
+    else if(temp_data_element.type == matlab::miUINT32) 
+    {
+      if(i==0)matlab::read<uint32_t,r_v>(is,subview::real(mbf.view),swap_value);
+      else    matlab::read<uint32_t,i_v>(is,subview::imag(mbf.view),swap_value);
+    }
+    else if(temp_data_element.type == matlab::miSINGLE) 
+    {
+      if(i==0)matlab::read<float,r_v>(is,subview::real(mbf.view),swap_value);
+      else    matlab::read<float,i_v>(is,subview::imag(mbf.view),swap_value);
+    }
+    else
+    {
+      if(i==0)matlab::read<double,r_v>(is,subview::real(mbf.view),swap_value);
+      else    matlab::read<double,i_v>(is,subview::imag(mbf.view),swap_value);
+    }
+
+  }
+
+  return is;
+}
+
+
+
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_MATLAB_BIN_FORMATTER_HPP
Index: matlab_text_formatter.hpp
===================================================================
RCS file: matlab_text_formatter.hpp
diff -N matlab_text_formatter.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ matlab_text_formatter.hpp	6 Jul 2006 16:29:40 -0000
@@ -0,0 +1,91 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip_csl/matlab_text_formatter.hpp
+    @author  Assem Salama
+    @date    2006-05-22
+    @brief   VSIPL++ CodeSourcery Library: Matlab text formatter
+*/
+
+#ifndef VSIP_CSL_MATLAB_TEXT_FORMATTER_HPP
+#define VSIP_CSL_MATLAB_TEXT_FORMATTER_HPP
+
+#include <string>
+#include <vsip/support.hpp>
+
+namespace vsip_csl
+{
+
+  /// This struct is just used as a wrapper so that we can overload the
+  /// << operator
+  template <typename ViewT>
+  struct Matlab_text_formatter
+  {
+    Matlab_text_formatter(ViewT v) : v_(v), view_name_("a")  {}
+    Matlab_text_formatter(ViewT v,std::string name) :
+      v_(v), view_name_(name)  {}
+
+    ViewT v_;
+    std::string view_name_;
+  };
+
+
+} // namespace vsip_csl
+
+
+/****************************************************************************
+ * Definitions
+ ***************************************************************************/
+
+namespace vsip_csl
+{
+
+/// Write a matrix to a stream using a Matlab_text_formatter
+
+template <typename T,
+          typename Block0>
+inline
+std::ostream&
+operator<<(
+  std::ostream&		                                out,
+  Matlab_text_formatter<vsip::Matrix<T,Block0> >        mf)
+  VSIP_NOTHROW
+
+{
+  out << mf.view_name_ << " = " << std::endl;
+  out << "[" << std::endl;
+  for(vsip::index_type i=0;i<mf.v_.size(0);i++) {
+    out << "  [ ";
+    for(vsip::index_type j=0;j<mf.v_.size(1);j++)
+      out << mf.v_.get(i,j) << " ";
+    out << "]" << std::endl;
+  }
+  out << "];" << std::endl;
+
+  return out;
+}
+
+/// Write a vector to a stream using a Matlab_text_formatter
+
+template <typename T,
+          typename Block0>
+inline
+std::ostream&
+operator<<(
+  std::ostream&		                          out,
+  Matlab_text_formatter<vsip::Vector<T,Block0> >  mf)
+  VSIP_NOTHROW
+
+{
+  out << mf.view_name_ << " = " << std::endl;
+  out << "[ "; 
+  for(vsip::index_type i=0;i<mf.v_.size(0);i++) {
+    out << mf.v_.get(i) << " ";
+  }
+  out << "];" << std::endl;
+
+  return out;
+}
+
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_MATLAB_TEXT_FORMATTER_HPP
Index: output.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip_csl/output.hpp,v
retrieving revision 1.2
diff -u -r1.2 output.hpp
--- output.hpp	25 May 2006 19:06:49 -0000	1.2
+++ output.hpp	6 Jul 2006 16:29:40 -0000
@@ -114,6 +114,6 @@
   return out;
 }
 
-} // namespace vsip
+} // namespace vsip_csl
 
 #endif // VSIP_CSL_OUTPUT_HPP
