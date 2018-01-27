? .matlab.hpp.swp
? generic_reader.hpp
? matlab_temp
? png.cpp
? png.hpp
Index: GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip_csl/GNUmakefile.inc.in,v
retrieving revision 1.1
diff -u -r1.1 GNUmakefile.inc.in
--- GNUmakefile.inc.in	8 May 2006 03:49:44 -0000	1.1
+++ GNUmakefile.inc.in	7 Jun 2006 21:06:53 -0000
@@ -12,13 +12,36 @@
 # Variables
 ########################################################################
 
+VSIP_CSL_HAVE_PNG	:= @HAVE_PNG_H@
+
+src_vsip_csl_CXXINCLUDES := -I$(srcdir)/src
+src_vsip_csl_CXXFLAGS := $(src_vsip_csl_CXXINCLUDES)
+
+ifdef VSIP_CSL_HAVE_PNG
+src_vsip_csl_cxx_sources += $(srcdir)/src/vsip_csl/png.cpp
+endif
+src_vsip_csl_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT),\
+                              $(src_vsip_csl_cxx_sources))
+cxx_sources += $(src_vsip_csl_cxx_sources)
+
+libs += lib/libvsip_csl.a
 
 ########################################################################
 # Rules
 ########################################################################
 
+all:: lib/libvsip_csl.a
+
+clean::
+	rm -f lib/libvsip_csl.a
+
+lib/libvsip_csl.a: $(src_vsip_csl_cxx_objects)
+	$(AR) rc $@ $^ || rm -f $@
+
 # Install the extensions library and its header files.
 install:: 
+	$(INSTALL) -d $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) lib/libvsip_csl.a $(DESTDIR)$(libdir)/libvsip_csl$(suffix).a
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip_csl
 	for header in $(wildcard $(srcdir)/src/vsip_csl/*.hpp); do \
           $(INSTALL_DATA) $$header $(DESTDIR)$(includedir)/vsip_csl; \
Index: matlab.hpp
===================================================================
RCS file: matlab.hpp
diff -N matlab.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ matlab.hpp	7 Jun 2006 21:06:54 -0000
@@ -0,0 +1,277 @@
+#ifndef VSIP_CSL_MATLAB_HPP
+#define VSIP_CSL_MATLAB_HPP
+
+#include <iostream>
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
+    int32_t size;
+  };
+
+  template <int Dim>
+  struct view_header
+  {
+    data_element header;
+    data_element array_flags_header;
+    char array_flags[8];
+    data_element dim_header;
+    int32_t dim[Dim + Dim%2]; //the dim has to be aligned to an 8 byte boundary
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
+
+  // generic reader that allows us to read a generic type and cast to another
+  
+  // the read function for real or complex depending of the view that was
+  // passed in
+  template <typename T1,
+            typename T2,
+	    typename ViewT>
+  void read(std::istream& is,ViewT v)
+  {
+    vsip::dimension_type const View_dim = ViewT::dim;
+    vsip::Index<View_dim> my_index;
+    vsip::impl::Length<View_dim> v_extent = extent(v);
+    typedef typename vsip::impl::Scalar_of<T2>::type scalar_type;
+    T1 data;
+
+    // get num_points
+    vsip::length_type num_points = v.size();
+
+    // read all the points
+    for(int i=0;i<num_points;i++) {
+      is.read(reinterpret_cast<char*>(&data),sizeof(data));
+      put(v,my_index,scalar_type(data));
+
+      // increment index
+      my_index = vsip::impl::next(v_extent,my_index);
+    }
+
+  }
+
+  // a write function to output a view to a matlab file.
+  template <typename T,
+	    typename ViewT>
+  void write(std::ostream& os,ViewT v)
+  {
+    vsip::dimension_type const View_dim = ViewT::dim;
+    vsip::Index<View_dim> my_index;
+    vsip::impl::Length<View_dim> v_extent = extent(v);
+    typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+    scalar_type data;
+
+    // get num_points
+    vsip::length_type num_points = v.size();
+
+    // write all the points
+    for(int i=0;i<num_points;i++) {
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
+    char endian[2];
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
+    static int const class_type = mxINT8_CLASS; 
+  };
+
+  template <>
+  struct Matlab_header_traits<1, false, true> // unsigned char
+  { 
+    static int const value_type = miUINT8;
+    static int const class_type = mxUINT8_CLASS; 
+  };
+
+  template <>
+  struct Matlab_header_traits<2, true, true> // short
+  { 
+    static int const value_type = miINT16;
+    static int const class_type = mxINT16_CLASS; 
+  };
+
+  template <>
+  struct Matlab_header_traits<2, false, true> // unsigned short
+  { 
+    static int const value_type = miUINT16;
+    static int const class_type = mxUINT16_CLASS; 
+  };
+
+  template <>
+  struct Matlab_header_traits<4, true, true> // int
+  { 
+    static int const value_type= miINT32;
+    static int const class_type= mxINT32_CLASS;
+  };
+
+  template <>
+  struct Matlab_header_traits<4, false, true> // unsigned int
+  { 
+    static int const value_type= miUINT32;
+    static int const class_type= mxUINT32_CLASS;
+  };
+
+  template <>
+  struct Matlab_header_traits<4, true, false> // float
+  { 
+    static int const value_type= miSINGLE;
+    static int const class_type= mxSINGLE_CLASS;
+  };
+
+  template <>
+  struct Matlab_header_traits<8, true, false> // double
+  { 
+    static int const value_type= miDOUBLE;
+    static int const class_type= mxDOUBLE_CLASS;
+  };
+
+  // matlab desired layouts
+  template <template <typename,typename> class View>
+  struct Matlab_desired_LP;
+
+  template<> struct Matlab_desired_LP<vsip::const_Vector>
+  { typedef vsip::impl::Layout<1,vsip::col1_type,
+                     vsip::impl::Stride_unit_dense,vsip::impl::Cmplx_split_fmt>
+      type; 
+  };
+
+  template<> struct Matlab_desired_LP<vsip::const_Matrix>
+  { typedef vsip::impl::Layout<2,vsip::col2_type,
+                     vsip::impl::Stride_unit_dense,vsip::impl::Cmplx_split_fmt>
+      type; 
+  };
+  
+  template<> struct Matlab_desired_LP<vsip::const_Tensor>
+  { typedef vsip::impl::Layout<3,vsip::col3_type,
+                     vsip::impl::Stride_unit_dense,vsip::impl::Cmplx_split_fmt>
+      type; 
+  };
+
+  template<> struct Matlab_desired_LP<vsip::Vector>
+  { typedef vsip::impl::Layout<1,vsip::col1_type,
+                     vsip::impl::Stride_unit_dense,vsip::impl::Cmplx_split_fmt>
+      type; 
+  };
+
+  template<> struct Matlab_desired_LP<vsip::Matrix>
+  { typedef vsip::impl::Layout<2,vsip::col2_type,
+                     vsip::impl::Stride_unit_dense,vsip::impl::Cmplx_split_fmt>
+      type; 
+  };
+  
+  template<> struct Matlab_desired_LP<vsip::Tensor>
+  { typedef vsip::impl::Layout<3,vsip::col3_type,
+                     vsip::impl::Stride_unit_dense,vsip::impl::Cmplx_split_fmt>
+      type; 
+  };
+
+  // helper function to return the real and imaginary part of a pointer
+  
+  template<typename T>
+  inline T* get_real_ptr(std::pair<T*,T*> ptr)
+    { return ptr.first; }
+  template<typename T>
+  inline T* get_real_ptr(T* ptr)
+    { return ptr; }
+
+  template<typename T>
+  inline T* get_imag_ptr(std::pair<T*,T*> ptr)
+    { return ptr.second; }
+  template<typename T>
+  inline T* get_imag_ptr(T* ptr)
+    { return ptr; }
+
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
+++ matlab_bin_formatter.hpp	7 Jun 2006 21:06:54 -0000
@@ -0,0 +1,366 @@
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
+  template <typename ViewT>
+  struct Matlab_bin_formatter
+  {
+    Matlab_bin_formatter(ViewT v,std::string const& name) :
+      view(v), name(name)  {}
+
+    ViewT view;
+    std::string name;
+
+  };
+
+  struct Matlab_bin_hdr
+  {
+    Matlab_bin_hdr(std::string const& descr, std::string const& end) : 
+      description(descr),version("MATLAB 5.0 : "),endian(end) {}
+    Matlab_bin_hdr(std::string const& descr) : 
+      description(descr),version("MATLAB 5.0 : "),endian("MI") {}
+    Matlab_bin_hdr() : 
+      description(" "),version("MATLAB 5.0 : "),endian("MI") {}
+
+    // description
+    std::string version;
+    std::string description;
+    std::string endian;
+
+  };
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
+  m_hdr.endian[0]=h.endian[0];
+  m_hdr.endian[1]=h.endian[1];
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
+  int    sz;
+  matlab::view_header<vsip::impl::Dim_of_view<const_View>::dim > m_view;
+  int    num_points = 1;
+  int    v_dims = vsip::impl::Dim_of_view<const_View>::dim;
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
+    m_view.array_flags[1] |= 0x8; // Complex
+
+  // fill in class
+  m_view.array_flags[0] = 
+    matlab::Matlab_header_traits<sizeof(scalar_type),
+                  std::numeric_limits<scalar_type>::is_signed,
+                  std::numeric_limits<scalar_type>::is_integer>::class_type;
+
+  // make sure we found a matching trait
+  assert(m_view.array_flags[0] != 0);
+  
+  // dimension sizes
+  m_view.dim_header.type = matlab::miINT32;
+  m_view.dim_header.size = v_dims*4; // 4 bytes per dimension
+  // fill in dimension
+  for(int i =0;i<v_dims;i++)
+  {
+    m_view.dim[i] = mbf.view.size(i);
+    num_points *= mbf.view.size(i);
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
+    for(int i=0;i < ((8-mbf.name.length())&0x7);i++) o.write(&c,1);
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
+             (matlab::get_real_ptr<scalar_type>(m_ext.data())),
+                  num_points*sizeof(scalar_type));
+        else o.write(reinterpret_cast<char*>
+             (matlab::get_imag_ptr<scalar_type>(m_ext.data())),
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
+        if(i==0) matlab::write<T,r_v>(o,subview::real(mbf.view));
+        else     matlab::write<T,i_v>(o,subview::imag(mbf.view));
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
+  std::istream&           o,
+  Matlab_bin_hdr          h)
+{
+  matlab::header m_hdr;
+
+  // read header
+  o.read(reinterpret_cast<char*>(&m_hdr),sizeof(m_hdr));
+
+  h.version[1] = m_hdr.version[1];
+  h.version[0] = m_hdr.version[0];
+  h.endian[1] = m_hdr.endian[1];
+  h.endian[0] = m_hdr.endian[0];
+
+  return o;
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
+  int v_dim = vsip::impl::Dim_of_view<View>::dim;
+
+
+  // read header
+  is.read(reinterpret_cast<char*>(&m_view),sizeof(m_view));
+
+  // is this complex?
+  if(vsip::impl::Is_complex<T>::value && !(m_view.array_flags[1]&0x8))
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Trying to read complex matrix into a real matrix"));
+
+
+  // is this the same class?
+  if(!(m_view.array_flags[0] == 
+            (matlab::Matlab_header_traits<sizeof(scalar_type),
+                  std::numeric_limits<scalar_type>::is_signed,
+                  std::numeric_limits<scalar_type>::is_integer>::class_type)))
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Trying to read a matrix of a different class"));
+
+  // do dimensions agree?
+  if(v_dim == 1) m_view.dim_header.size -= 4; // special case for vectors
+  if(v_dim != (m_view.dim_header.size/4))
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Trying to read a matrix of different dimensions"));
+
+  for(int i=0;i<v_dim;i++)
+    if(mbf.view.size(i) != m_view.dim[i])
+      VSIP_IMPL_THROW(std::runtime_error(
+        "Matrix dimensions don't agree"));
+
+  // read array name
+  if(m_view.array_name_header.type & 0xffff0000)
+  {
+    // array name is short
+
+    int length = m_view.array_name_header.type >> 16;
+  }
+  else
+  {
+    int length = m_view.array_name_header.size;
+    char c;
+    char c_array[128];
+    // the name is longer than 4 bytes
+    //
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
+
+    // read data header
+    is.read(reinterpret_cast<char*>(&temp_data_element),
+            sizeof(temp_data_element));
+
+    // Because we don't know how the data was stored, we need to instantiate
+    // generic_reader which can read a type and cast into a different one
+    if(temp_data_element.type == matlab::miINT8) 
+    {
+      if(i==0)matlab::read<int8_t,T,r_v>(is,subview::real(mbf.view));
+      else    matlab::read<int8_t,T,i_v>(is,subview::imag(mbf.view));
+    }
+    else if(temp_data_element.type == matlab::miUINT8) 
+    {
+      if(i==0)matlab::read<uint8_t,T,r_v>(is,subview::real(mbf.view));
+      else    matlab::read<uint8_t,T,i_v>(is,subview::imag(mbf.view));
+    }
+    else if(temp_data_element.type == matlab::miINT16) 
+    {
+      if(i==0)matlab::read<int16_t,T,r_v>(is,subview::real(mbf.view));
+      else    matlab::read<int16_t,T,i_v>(is,subview::imag(mbf.view));
+    }
+    else if(temp_data_element.type == matlab::miUINT16) 
+    {
+      if(i==0)matlab::read<uint16_t,T,r_v>(is,subview::real(mbf.view));
+      else    matlab::read<uint16_t,T,i_v>(is,subview::imag(mbf.view));
+    }
+    else if(temp_data_element.type == matlab::miINT32) 
+    {
+      if(i==0)matlab::read<int32_t,T,r_v>(is,subview::real(mbf.view));
+      else    matlab::read<int32_t,T,i_v>(is,subview::imag(mbf.view));
+    }
+    else if(temp_data_element.type == matlab::miUINT32) 
+    {
+      if(i==0)matlab::read<uint32_t,T,r_v>(is,subview::real(mbf.view));
+      else    matlab::read<uint32_t,T,i_v>(is,subview::imag(mbf.view));
+    }
+    else if(temp_data_element.type == matlab::miSINGLE) 
+    {
+      if(i==0)matlab::read<float,T,r_v>(is,subview::real(mbf.view));
+      else    matlab::read<float,T,i_v>(is,subview::imag(mbf.view));
+    }
+    else
+    {
+      if(i==0)matlab::read<double,T,r_v>(is,subview::real(mbf.view));
+      else    matlab::read<double,T,i_v>(is,subview::imag(mbf.view));
+    }
+
+  }
+
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
+++ matlab_text_formatter.hpp	7 Jun 2006 21:06:54 -0000
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
retrieving revision 1.1
diff -u -r1.1 output.hpp
--- output.hpp	3 Apr 2006 19:17:15 -0000	1.1
+++ output.hpp	7 Jun 2006 21:06:54 -0000
@@ -17,9 +17,6 @@
 #include <vsip/domain.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
-#include <vsip/impl/point.hpp>
-
-
 
 namespace vsip_csl
 {
@@ -75,7 +72,6 @@
 }
 
 
-
 /// Write a vector to a stream.
 
 template <typename T,
@@ -116,26 +112,8 @@
 }
 
 
-/// Write a point to a stream.
 
-template <vsip::dimension_type Dim>
-inline
-std::ostream&
-operator<<(
-  std::ostream&		        out,
-  vsip::impl::Point<Dim> const& idx)
-  VSIP_NOTHROW
-{
-  out << "(";
-  for (vsip::dimension_type d=0; d<Dim; ++d)
-  {
-    if (d > 0) out << ", ";
-    out << idx[d];
-  }
-  out << ")";
-  return out;
-}
 
-} // namespace vsip
+} // namespace vsip_csl
 
 #endif // VSIP_CSL_OUTPUT_HPP
