? .GNUmakefile.inc.in.swp
? .matlab.hpp.swp
? .matlab_bin_formatter.hpp.swo
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
+++ GNUmakefile.inc.in	26 May 2006 00:17:31 -0000
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
+++ matlab.hpp	26 May 2006 00:17:31 -0000
@@ -0,0 +1,232 @@
+#ifndef VSIP_CSL_MATLAB_HPP
+#define VSIP_CSL_MATLAB_HPP
+
+#include <iostream>
+#include <vsip/impl/metaprogramming.hpp>
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
+    int32_t dim[Dim + Dim%2];
+    data_element array_name_header;
+  };
+
+  // some structures to helps determine if a type is single precision
+  template <typename T>
+  struct Is_single
+  { static bool const value = false; };
+
+  template <>
+  struct Is_single<float>
+  { static bool const value = true; };
+
+  template <>
+  struct Is_single<std::complex<float> >
+  { static bool const value = true; };
+
+  // a generic reader that allows us to read a generic type and cast to another
+  template<typename T1,typename T2>
+  struct Generic_reader
+  {
+    // the read function
+    template <typename T,
+	      typename Block0>
+    void read(std::istream& is,vsip::Matrix<T,Block0> m)
+    {
+      for(int i=0;i<m.size(1);i++) {
+        for(int j=0;j<m.size(0);j++) {
+          is.read(reinterpret_cast<char*>(&data),sizeof(data));
+	  converted_data = data;
+	  m.put(j,i,converted_data);
+	}
+      }
+    }
+
+    T1 data;
+    T2 converted_data;
+  };
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
+  const int miINT8           = 1;
+  const int miUINT8          = 2;
+  const int miINT16          = 3;
+  const int miUINT16         = 4;
+  const int miINT32          = 5;
+  const int miUINT32         = 6;
+  const int miSINGLE         = 7;
+  const int miDOUBLE         = 9;
+  const int miINT64          = 12;
+  const int miUINT64         = 13;
+  const int miMATRIX         = 14;
+  const int miCOMPRESSED     = 15;
+  const int miUTF8           = 16;
+  const int miUTF16          = 17;
+  const int miUTF32          = 18;
+  
+  // class types
+  const int mxCELL_CLASS     = 1;
+  const int mxSTRUCT_CLASS   = 2;
+  const int mxOBJECT_CLASS   = 3;
+  const int mxCHAR_CLASS     = 4;
+  const int mxSPARSE_CLASS   = 5;
+  const int mxDOUBLE_CLASS   = 6;
+  const int mxSINGLE_CLASS   = 7;
+  const int mxINT8_CLASS     = 8;
+  const int mxUINT8_CLASS    = 9;
+  const int mxINT16_CLASS    = 10;
+  const int mxUINT16_CLASS   = 11;
+  const int mxINT32_CLASS    = 12;
+  const int mxUINT32_CLASS   = 13;
+
+  // matlab header traits
+  template <int size,bool is_signed,bool is_int>
+  struct Matlab_header_traits
+  { 
+    static int const value_type = 0;
+    static int const class_type = 0;
+  };
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
+  inline T* get_real_ptr(std::pair<T*,T*> ptr,vsip::impl::Bool_type<true>) 
+    { return ptr.first; }
+  template<typename T>
+  inline T* get_real_ptr(T* ptr,vsip::impl::Bool_type<false>)
+    { return ptr; }
+
+  template<typename T>
+  inline T* get_imag_ptr(std::pair<T*,T*> ptr,vsip::impl::Bool_type<true>) 
+    { return ptr.second; }
+  template<typename T>
+  inline T* get_imag_ptr(T* ptr,vsip::impl::Bool_type<false>)
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
+++ matlab_bin_formatter.hpp	26 May 2006 00:17:32 -0000
@@ -0,0 +1,217 @@
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
+      v(v), view_name(name)  {}
+
+    ViewT v;
+    std::string view_name;
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
+  memset(&(m_hdr),0,sizeof(m_hdr));
+  strncpy(m_hdr.description, h.version.data(), h.version.length());
+  strncpy(m_hdr.description+h.version.length(), h.description.data(),
+    h.description.length());
+  for(int i=(h.version.length()+h.description.length()); i<128;i++)
+    m_hdr.description[i] = ' ';
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
+    m_view.dim[i] = mbf.v.size(i);
+    num_points *= mbf.v.size(i);
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
+  m_view.array_name_header.size = mbf.view_name.length();
+
+
+  // calculate size
+  sz = sizeof(m_view)-8;
+  sz += mbf.view_name.length();
+  sz += (8-mbf.view_name.length())&0x7;
+  sz += 8; // 8 bytes of header for real data
+  if(vsip::impl::Is_complex<T>::value) sz += 8; // 8 more for complex data
+  sz += num_points*sizeof(T);
+  m_view.header.size = sz;
+
+  o.write(reinterpret_cast<char*>(&m_view),sizeof(m_view));
+
+  // write array name
+  o.write(mbf.view_name.c_str(),mbf.view_name.length());
+  // pad
+  { 
+    char c=0;
+    for(int i=0;i < ((8-mbf.view_name.length())&0x7);i++) o.write(&c,1);
+  }
+
+  // write real part
+  {
+    
+
+    vsip::impl::Ext_data<Block0,
+	                 typename matlab::Matlab_desired_LP<const_View>::type >
+	     
+	     m_ext(mbf.v.block());
+
+    temp_data_element.type = matlab::Matlab_header_traits<sizeof(scalar_type),
+                  std::numeric_limits<scalar_type>::is_signed,
+                  std::numeric_limits<scalar_type>::is_integer>::value_type;
+
+    temp_data_element.size = num_points*sizeof(scalar_type);
+    o.write(reinterpret_cast<char*>(&temp_data_element),
+              sizeof(temp_data_element));
+    o.write(reinterpret_cast<char*>
+         (matlab::get_real_ptr<scalar_type>(m_ext.data(),
+            vsip::impl::Bool_type<vsip::impl::Is_complex<T>::value>())),
+              num_points*sizeof(scalar_type));
+  }
+
+  if(!vsip::impl::Is_complex<T>::value) return o; //we are done here
+
+  // write imaginary part
+  {
+    
+
+    vsip::impl::Ext_data<Block0,
+	                 typename matlab::Matlab_desired_LP<const_View>::type >
+	     
+	     m_ext(mbf.v.block());
+
+    temp_data_element.type = matlab::Matlab_header_traits<sizeof(scalar_type),
+                  std::numeric_limits<scalar_type>::is_signed,
+                  std::numeric_limits<scalar_type>::is_integer>::value_type;
+
+    temp_data_element.size = num_points*sizeof(scalar_type);
+    o.write(reinterpret_cast<char*>(&temp_data_element),
+              sizeof(temp_data_element));
+    o.write(reinterpret_cast<char*>
+         (matlab::get_imag_ptr<scalar_type>(m_ext.data(),
+            vsip::impl::Bool_type<vsip::impl::Is_complex<T>::value>())),
+              num_points*sizeof(scalar_type));
+  }
+
+
+  return o;
+}
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
+++ matlab_text_formatter.hpp	26 May 2006 00:17:32 -0000
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
+++ output.hpp	26 May 2006 00:17:32 -0000
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
