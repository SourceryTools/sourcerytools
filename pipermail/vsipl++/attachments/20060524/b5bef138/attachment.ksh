? png.cpp
? png.hpp
Index: GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip_csl/GNUmakefile.inc.in,v
retrieving revision 1.1
diff -u -r1.1 GNUmakefile.inc.in
--- GNUmakefile.inc.in	8 May 2006 03:49:44 -0000	1.1
+++ GNUmakefile.inc.in	24 May 2006 10:25:04 -0000
@@ -12,13 +12,59 @@
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
+VSIP_CSL_HAVE_PNG	:= @HAVE_PNG_H@
+
+src_vsip_csl_CXXINCLUDES := -I$(srcdir)/src
+src_vsip_csl_CXXFLAGS := $(src_vsip_csl_CXXINCLUDES)
+
+all:: lib/libvsip_csl.a
+
+clean::
+	rm -f lib/libvsip_csl.a
+
+lib/libvsip_csl.a: $(src_vsip_csl_cxx_objects)
+	$(AR) rc $@ $^ || rm -f $@
+
+ifdef VSIP_CSL_HAVE_PNG
+src_vsip_csl_cxx_sources += $(srcdir)/src/vsip_csl/png.cpp
+	$(INSTALL) -d $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) lib/libvsip_csl.a $(DESTDIR)$(libdir)/libvsip_csl$(suffix).a
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
+++ matlab.hpp	24 May 2006 10:25:04 -0000
@@ -0,0 +1,98 @@
+#ifndef VSIP_CSL_MATLAB_HPP
+#define VSIP_CSL_MATLAB_HPP
+
+namespace vsip_csl
+{
+
+namespace matlab
+{
+  struct data_element
+  {
+    int32_t data_el_type;
+    int32_t data_el_size;
+  };
+
+  struct matrix
+  {
+    data_element mtrx_hdr;
+    data_element array_flags_hdr;
+    char array_flags[8];
+    data_element dim_hdr;
+    int32_t dim1;
+    int32_t dim2;
+    data_element array_name_hdr;
+  };
+
+  struct tensor
+  {
+    data_element mtrx_hdr;
+    data_element array_flags_hdr;
+    char array_flags[8];
+    data_element dim_hdr;
+    int32_t dim1;
+    int32_t dim2;
+    int32_t dim3;
+    int32_t pad;
+    data_element array_name_hdr;
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
+  struct header
+  {
+    char descr[116];
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
+++ matlab_bin_formatter.hpp	24 May 2006 10:25:04 -0000
@@ -0,0 +1,357 @@
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
+#include <vsip_csl/matlab.hpp>
+#include <vsip/impl/fns_scalar.hpp>
+#include <vsip/impl/metaprogramming.hpp>
+
+namespace vsip_csl
+{
+
+  template <typename ViewT>
+  struct Matlab_bin_formatter
+  {
+    Matlab_bin_formatter(ViewT v,std::string name) :
+      v_(v), view_name_(name)  {}
+
+    ViewT v_;
+    std::string view_name_;
+
+  };
+
+  struct Matlab_bin_hdr
+  {
+    Matlab_bin_hdr(std::string descr, std::string end) : 
+      descr_(descr),ver_("MATLAB 5.0 : "),end_(end) {}
+    Matlab_bin_hdr(std::string descr) : 
+      descr_(descr),ver_("MATLAB 5.0 : "),end_("MI") {}
+    Matlab_bin_hdr() : descr_(" "),ver_("MATLAB 5.0 : "),end_("MI") {}
+
+    // description
+    std::string ver_;
+    std::string descr_;
+    std::string end_;
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
+  strncpy(m_hdr.descr, h.ver_.data(), h.ver_.length());
+  strncpy(m_hdr.descr+h.ver_.length(), h.descr_.data(), h.descr_.length());
+  for(int i=(h.ver_.length()+h.descr_.length()); i<128;i++)
+    m_hdr.descr[i] = ' ';
+  m_hdr.version[1] = 0x01; m_hdr.version[0] = 0x00;
+  m_hdr.endian[0]=h.end_[0];
+  m_hdr.endian[1]=h.end_[1];
+
+  // write header
+  o.write(reinterpret_cast<char*>(&m_hdr),sizeof(m_hdr));
+
+  return o;
+}
+
+// operator to write tensor to matlab file
+template <typename T,
+          typename Block0>
+inline
+std::ostream&
+operator<<(
+  std::ostream&                                               o,
+  Matlab_bin_formatter<vsip::const_Tensor<T,Block0> >const&   mbf)
+{
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+  matlab::data_element temp_data_el;
+  int    num_points = mbf.v_.size(0)*mbf.v_.size(1)*mbf.v_.size(2);
+  int    sz;
+  matlab::tensor m_tensor;
+
+  memset(&m_tensor,0,sizeof(m_tensor));
+
+  // matrix data type
+  m_tensor.mtrx_hdr.data_el_type = matlab::miMATRIX;
+  m_tensor.mtrx_hdr.data_el_size = 1; // TEMP
+
+  // array flags
+  m_tensor.array_flags_hdr.data_el_type = matlab::miUINT32;
+  m_tensor.array_flags_hdr.data_el_size = 8;
+  if(vsip::impl::Is_complex<T>::value) 
+    m_tensor.array_flags[1] |= 0x8; // Complex
+  if(matlab::Is_single<T>::value)
+    m_tensor.array_flags[0] = matlab::mxSINGLE_CLASS; // single precision
+  else
+    m_tensor.array_flags[0] = matlab::mxDOUBLE_CLASS; // double precision
+  
+  // dimension sizes
+  m_tensor.dim_hdr.data_el_type = matlab::miINT32;
+  m_tensor.dim_hdr.data_el_size = 12;
+  m_tensor.dim1 = mbf.v_.size(0);
+  m_tensor.dim2 = mbf.v_.size(1);
+  m_tensor.dim3 = mbf.v_.size(2);
+
+  // array name
+  m_tensor.array_name_hdr.data_el_type = matlab::miINT8;
+  m_tensor.array_name_hdr.data_el_size = mbf.view_name_.length();
+
+
+  // calculate size
+  sz = sizeof(m_tensor)-8;
+  sz += mbf.view_name_.length();
+  sz += (8-mbf.view_name_.length())&0x7;
+  sz += 8; // 8 bytes of header for real data
+  if(vsip::impl::Is_complex<T>::value) sz += 8; // 8 more for complex data
+  sz += num_points*sizeof(T);
+  m_tensor.mtrx_hdr.data_el_size = sz;
+
+  o.write(reinterpret_cast<char*>(&m_tensor),sizeof(m_tensor));
+
+  // write array name
+  o.write(mbf.view_name_.c_str(),mbf.view_name_.length());
+  // pad
+  { 
+    char c=0;
+    for(int i=0;i < ((8-mbf.view_name_.length())&0x7);i++) o.write(&c,1);
+  }
+
+  // write real data
+  if(matlab::Is_single<T>::value)
+    temp_data_el.data_el_type = matlab::miSINGLE;
+  else
+    temp_data_el.data_el_type = matlab::miDOUBLE;
+
+  temp_data_el.data_el_size = sizeof(scalar_type)*num_points;
+  o.write(reinterpret_cast<char*>(&temp_data_el),sizeof(temp_data_el));
+  
+  {
+    scalar_type real_data;
+
+    // Matlab wants data in col major format
+    for(vsip::length_type i=0;i<mbf.v_.size(2);i++) {
+      for(vsip::length_type j=0;j<mbf.v_.size(1);j++) {
+        for(vsip::length_type k=0;k<mbf.v_.size(0);k++) {
+          real_data = vsip::impl::fn::impl_real(mbf.v_.get(k,j,i));
+          o.write(reinterpret_cast<char*>(&real_data),sizeof(real_data));
+	}
+      }
+    }
+  }
+
+  if(!vsip::impl::Is_complex<T>::value) return o; // we are done here
+
+  // write imaginary data
+  if(matlab::Is_single<T>::value)
+    temp_data_el.data_el_type = matlab::miSINGLE;
+  else
+    temp_data_el.data_el_type = matlab::miDOUBLE;
+
+  temp_data_el.data_el_size = sizeof(scalar_type)*num_points;
+  o.write(reinterpret_cast<char*>(&temp_data_el),sizeof(temp_data_el));
+
+  {
+    scalar_type imag_data;
+
+    // Matlab wants data in col major format
+    for(vsip::length_type i=0;i<mbf.v_.size(2);i++) {
+      for(vsip::length_type j=0;j<mbf.v_.size(1);j++) {
+        for(vsip::length_type k=0;k<mbf.v_.size(0);k++) {
+          imag_data = vsip::impl::fn::impl_imag(mbf.v_.get(k,j,i));
+          o.write(reinterpret_cast<char*>(&imag_data),sizeof(imag_data));
+	}
+      }
+    }
+  }
+
+  return o;
+}
+
+// operator to write matrix to matlab file
+template <typename T,
+          typename Block0>
+inline
+std::ostream&
+operator<<(
+  std::ostream&                                               o,
+  Matlab_bin_formatter<vsip::const_Matrix<T,Block0> >const&   mbf)
+{
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+  matlab::data_element temp_data_el;
+  int    num_points = mbf.v_.size(0)*mbf.v_.size(1);
+  int    sz;
+  matlab::matrix m_mtrx;
+
+  memset(&m_mtrx,0,sizeof(m_mtrx));
+
+  // matrix data type
+  m_mtrx.mtrx_hdr.data_el_type = matlab::miMATRIX;
+  m_mtrx.mtrx_hdr.data_el_size = 1; // TEMP
+
+  // array flags
+  m_mtrx.array_flags_hdr.data_el_type = matlab::miUINT32;
+  m_mtrx.array_flags_hdr.data_el_size = 8;
+  if(vsip::impl::Is_complex<T>::value) 
+    m_mtrx.array_flags[1] |= 0x8; // Complex
+  if(matlab::Is_single<T>::value)
+    m_mtrx.array_flags[0] = matlab::mxSINGLE_CLASS; // single precision
+  else
+    m_mtrx.array_flags[0] = matlab::mxDOUBLE_CLASS; // double precision
+  
+  // dimension sizes
+  m_mtrx.dim_hdr.data_el_type = matlab::miINT32;
+  m_mtrx.dim_hdr.data_el_size = 8;
+  m_mtrx.dim1 = mbf.v_.size(0);
+  m_mtrx.dim2 = mbf.v_.size(1);
+
+  // array name
+  m_mtrx.array_name_hdr.data_el_type = matlab::miINT8;
+  m_mtrx.array_name_hdr.data_el_size = mbf.view_name_.length();
+
+
+  // calculate size
+  sz = sizeof(m_mtrx)-8;
+  sz += mbf.view_name_.length();
+  sz += (8-mbf.view_name_.length())&0x7;
+  sz += 8; // 8 bytes of header for real data
+  if(vsip::impl::Is_complex<T>::value) sz += 8; // 8 more for complex data
+  sz += num_points*sizeof(T);
+  m_mtrx.mtrx_hdr.data_el_size = sz;
+
+  o.write(reinterpret_cast<char*>(&m_mtrx),sizeof(m_mtrx));
+
+  // write array name
+  o.write(mbf.view_name_.c_str(),mbf.view_name_.length());
+  // pad
+  { 
+    char c=0;
+    for(int i=0;i < ((8-mbf.view_name_.length())&0x7);i++) o.write(&c,1);
+  }
+
+  // write real data
+  if(matlab::Is_single<T>::value)
+    temp_data_el.data_el_type = matlab::miSINGLE;
+  else
+    temp_data_el.data_el_type = matlab::miDOUBLE;
+
+  temp_data_el.data_el_size = sizeof(scalar_type)*num_points;
+  o.write(reinterpret_cast<char*>(&temp_data_el),sizeof(temp_data_el));
+  
+  {
+    scalar_type real_data;
+
+    // Matlab wants data in col major format
+    for(vsip::length_type i=0;i<mbf.v_.size(1);i++) {
+      for(vsip::length_type j=0;j<mbf.v_.size(0);j++) {
+        real_data = vsip::impl::fn::impl_real(mbf.v_.get(j,i));
+        o.write(reinterpret_cast<char*>(&real_data),sizeof(real_data));
+      }
+    }
+  }
+
+  if(!vsip::impl::Is_complex<T>::value) return o; // we are done here
+
+  // write imaginary data
+  if(matlab::Is_single<T>::value)
+    temp_data_el.data_el_type = matlab::miSINGLE;
+  else
+    temp_data_el.data_el_type = matlab::miDOUBLE;
+
+  temp_data_el.data_el_size = sizeof(scalar_type)*num_points;
+  o.write(reinterpret_cast<char*>(&temp_data_el),sizeof(temp_data_el));
+
+  {
+    scalar_type imag_data;
+
+    // Matlab wants data in col major format
+    for(vsip::length_type i=0;i<mbf.v_.size(1);i++) {
+      for(vsip::length_type j=0;j<mbf.v_.size(0);j++) {
+        imag_data = vsip::impl::fn::impl_imag(mbf.v_.get(j,i));
+        o.write(reinterpret_cast<char*>(&imag_data),sizeof(imag_data));
+      }
+    }
+  }
+
+  return o;
+}
+
+// operator to write vector to matlab file
+template <typename T,
+          typename Block0>
+inline
+std::ostream&
+operator<<(
+  std::ostream&                                               o,
+  Matlab_bin_formatter<vsip::const_Vector<T,Block0> > const&  mbf)
+{
+  // A vector is treated like a mx1 matrix
+  vsip::Matrix<T> m(1,mbf.v_.size(0));
+  m.row(0) = mbf.v_;
+  return o << Matlab_bin_formatter<vsip::Matrix<T> >(m,mbf.view_name_);
+}
+
+
+// operators to write when non-constant Tensor,Matrix, and Vector are passed
+template <typename T,
+          typename Block0>
+inline
+std::ostream&
+operator<<(
+  std::ostream&                                 o,
+  Matlab_bin_formatter<vsip::Tensor<T,Block0> > mbf)
+{
+  return o << 
+    Matlab_bin_formatter<vsip::const_Tensor<T,Block0> >(mbf.v_,mbf.view_name_);
+}
+
+template <typename T,
+          typename Block0>
+inline
+std::ostream&
+operator<<(
+  std::ostream&                                 o,
+  Matlab_bin_formatter<vsip::Matrix<T,Block0> > mbf)
+{
+  return o << 
+    Matlab_bin_formatter<vsip::const_Matrix<T,Block0> >(mbf.v_,mbf.view_name_);
+}
+
+template <typename T,
+          typename Block0>
+inline
+std::ostream&
+operator<<(
+  std::ostream&                                 o,
+  Matlab_bin_formatter<vsip::Vector<T,Block0> > mbf)
+{
+  return o << 
+    Matlab_bin_formatter<vsip::const_Vector<T,Block0> >(mbf.v_,mbf.view_name_);
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
+++ matlab_text_formatter.hpp	24 May 2006 10:25:04 -0000
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
+++ output.hpp	24 May 2006 10:25:04 -0000
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
