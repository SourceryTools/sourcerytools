Index: matlab_bin_formatter.hpp
===================================================================
RCS file: matlab_bin_formatter.hpp
diff -N matlab_bin_formatter.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ matlab_bin_formatter.hpp	22 May 2006 16:04:01 -0000
@@ -0,0 +1,229 @@
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
+#include <vsip_csl/matlab_defines.h>
+#include <vsip/impl/fns_scalar.hpp>
+#include <vsip/impl/metaprogramming.hpp>
+#include <netinet/in.h>
+
+namespace vsip_csl
+{
+
+  struct matlab_data_el_struct
+  {
+    int32_t data_el_type;
+    int32_t data_el_size;
+  };
+
+  struct matlab_mtrx_struct
+  {
+    struct matlab_data_el_struct mtrx_hdr;
+    struct matlab_data_el_struct array_flags_hdr;
+    char array_flags[8];
+    struct matlab_data_el_struct dim_hdr;
+    int32_t dim1;
+    int32_t dim2;
+    struct matlab_data_el_struct array_name_hdr;
+  };
+
+  template <typename ViewT>
+  struct Matlab_bin_formatter
+  {
+    Matlab_bin_formatter(ViewT v) : v_(v), view_name_("a")  {}
+    Matlab_bin_formatter(ViewT v,std::string name) :
+      v_(v), view_name_(name)  {}
+
+    ViewT v_;
+    std::string view_name_;
+
+    struct matlab_mtrx_struct m_mtrx;
+  };
+
+  struct matlab_hdr_struct
+  {
+    char descr[116];
+    char subsyt_data[8];
+    char version[2];
+    char endian[2];
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
+    struct matlab_hdr_struct m_hdr;
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
+  Matlab_bin_hdr          h)
+{
+  // set hdr to spaces
+  memset(&(h.m_hdr),0,sizeof(h.m_hdr));
+  strcat(h.m_hdr.descr, h.ver_.c_str());
+  strcat(h.m_hdr.descr, h.descr_.c_str());
+  for(int i=(h.ver_.length()+h.descr_.length()); i<128;i++)
+    h.m_hdr.descr[i] = ' ';
+  h.m_hdr.version[1] = 0x01; h.m_hdr.version[0] = 0x00;
+  strcpy(h.m_hdr.endian,h.end_.c_str());
+
+  // write header
+  o.write((char*) &h.m_hdr,sizeof(h.m_hdr));
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
+  std::ostream&                                    o,
+  Matlab_bin_formatter<vsip::Matrix<T,Block0> >    mbf)
+{
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+  struct matlab_data_el_struct temp_data_el;
+  int    num_points = mbf.v_.size(0)*mbf.v_.size(1);
+  int    sz;
+
+  memset(&mbf.m_mtrx,0,sizeof(mbf.m_mtrx));
+
+  // matrix data type
+  mbf.m_mtrx.mtrx_hdr.data_el_type = miMATRIX;
+  mbf.m_mtrx.mtrx_hdr.data_el_size = 1; // TEMP
+
+  // array flags
+  mbf.m_mtrx.array_flags_hdr.data_el_type = miUINT32;
+  mbf.m_mtrx.array_flags_hdr.data_el_size = 8;
+  if(vsip::impl::Is_complex<T>::value) 
+    mbf.m_mtrx.array_flags[1] |= 0x8; // Complex
+  if(Is_single<T>::value)
+    mbf.m_mtrx.array_flags[0] = mxSINGLE_CLASS; // single precision
+  else
+    mbf.m_mtrx.array_flags[0] = mxDOUBLE_CLASS; // single precision
+  
+  // dimension sizes
+  mbf.m_mtrx.dim_hdr.data_el_type = miINT32;
+  mbf.m_mtrx.dim_hdr.data_el_size = 8;
+  mbf.m_mtrx.dim1 = mbf.v_.size(0);
+  mbf.m_mtrx.dim2 = mbf.v_.size(1);
+
+  // array name
+  mbf.m_mtrx.array_name_hdr.data_el_type = miINT8;
+  mbf.m_mtrx.array_name_hdr.data_el_size = mbf.view_name_.length();
+
+
+  // calculate size
+  sz = sizeof(mbf.m_mtrx)-8;
+  sz += mbf.view_name_.length();
+  sz += (8-mbf.view_name_.length())&0x7;
+  sz += 8; // 8 bytes of header for real data
+  if(vsip::impl::Is_complex<T>::value) sz += 8; // 8 more for complex data
+  sz += mbf.v_.size(0)*mbf.v_.size(1)*sizeof(T);
+  mbf.m_mtrx.mtrx_hdr.data_el_size = sz;
+
+  o.write((char*)&mbf.m_mtrx,sizeof(mbf.m_mtrx));
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
+  if(Is_single<T>::value)
+    temp_data_el.data_el_type = miSINGLE;
+  else
+    temp_data_el.data_el_type = miDOUBLE;
+
+  temp_data_el.data_el_size = sizeof(scalar_type)*num_points;
+  o.write((char*)&temp_data_el,sizeof(temp_data_el));
+  
+  {
+    scalar_type real_data;
+
+    // Matlab wants data in col major format
+    for(vsip::length_type i=0;i<mbf.v_.size(1);i++) {
+      for(vsip::length_type j=0;j<mbf.v_.size(0);j++) {
+        real_data = vsip::impl::fn::impl_real(mbf.v_.get(j,i));
+        o.write((char*)&real_data,sizeof(real_data));
+      }
+    }
+  }
+
+  if(!vsip::impl::Is_complex<T>::value) return o; // we are done here
+
+  // write imaginary data
+  if(Is_single<T>::value)
+    temp_data_el.data_el_type = miSINGLE;
+  else
+    temp_data_el.data_el_type = miDOUBLE;
+
+  temp_data_el.data_el_size = sizeof(scalar_type)*num_points;
+  o.write((char*)&temp_data_el,sizeof(temp_data_el));
+
+  {
+    scalar_type imag_data;
+
+    // Matlab wants data in col major format
+    for(vsip::length_type i=0;i<mbf.v_.size(1);i++) {
+      for(vsip::length_type j=0;j<mbf.v_.size(0);j++) {
+        imag_data = vsip::impl::fn::impl_imag(mbf.v_.get(j,i));
+        o.write((char*)&imag_data,sizeof(imag_data));
+      }
+    }
+  }
+
+  return o;
+}
+
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_MATLAB_BIN_FORMATTER_HPP
Index: matlab_defines.h
===================================================================
RCS file: matlab_defines.h
diff -N matlab_defines.h
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ matlab_defines.h	22 May 2006 16:04:01 -0000
@@ -0,0 +1,44 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip_csl/matlab_defines.h
+    @author  Assem Salama
+    @date    2006-05-22
+    @brief   VSIPL++ CodeSourcery Library: Matlab defines used by bin formatter
+*/
+
+#ifndef VSIP_CSL_MATLAB_DEFINES_H
+#define VSIP_CSL_MATLAB_DEFINES_H
+
+// data types
+#define miINT8            1
+#define miUINT8           2
+#define miINT16           3
+#define miUINT16          4
+#define miINT32           5
+#define miUINT32          6
+#define miSINGLE          7
+#define miDOUBLE          9
+#define miINT64           12
+#define miUINT64          13
+#define miMATRIX          14
+#define miCOMPRESSED      15
+#define miUTF8            16
+#define miUTF16           17
+#define miUTF32           18
+
+// class types
+#define mxCELL_CLASS      1
+#define mxSTRUCT_CLASS    2
+#define mxOBJECT_CLASS    3
+#define mxCHAR_CLASS      4
+#define mxSPARSE_CLASS    5
+#define mxDOUBLE_CLASS    6
+#define mxSINGLE_CLASS    7
+#define mxINT8_CLASS      8
+#define mxUINT8_CLASS     9
+#define mxINT16_CLASS     10
+#define mxUINT16_CLASS    11
+#define mxINT32_CLASS     12
+#define mxUINT32_CLASS    13
+
+#endif // VSIP_CSL_MATLAB_DEFINES_H
Index: matlab_text_formatter.hpp
===================================================================
RCS file: matlab_text_formatter.hpp
diff -N matlab_text_formatter.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ matlab_text_formatter.hpp	22 May 2006 16:04:01 -0000
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
+++ output.hpp	22 May 2006 16:04:01 -0000
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
