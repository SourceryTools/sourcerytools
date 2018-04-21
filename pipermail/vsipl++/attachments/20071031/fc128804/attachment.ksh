Index: ChangeLog
===================================================================
--- ChangeLog	(revision 186104)
+++ ChangeLog	(working copy)
@@ -1,3 +1,28 @@
+2007-10-31  Jules Bergmann  <jules@codesourcery.com>
+
+	Matlab IO cleanup.
+	* src/vsip_csl/matlab_file.hpp (header): New function, return file
+	  header.
+	* src/vsip_csl/matlab.hpp (File_header): Rename class from 'header'.
+	  Add data_type and class_type helper stringify functions.
+	* src/vsip_csl/matlab_bin_formatter.hpp: General cleanup and
+	  commenting.  Straighten out version handling.
+
+	Extend matlab test coverage.
+	* tests/matlab_bin_file/matlab_bin_file.cpp: New location, also
+	  reads pre-canned matlab data files for big- and little- endian.
+	* tests/matlab_bin_file/data/matlab-ref-be.mat: Pre-canned big-endian
+	  data file.
+	* tests/matlab_bin_file/data/matlab-ref-le.mat: Pre-canned
+	  little-endian data file.
+
+	New utility to list contents of matlab file.
+	* apps/utils/lsmat.cpp: New file, lists contents of matlab file.
+	* apps/utils/GNUmakefile.inc.in: New file, integrated makefile for
+	  apps/utils.
+	* apps/utils/GNUmakefile: New file, standalong makefile for apps/utils
+	* GNUmakefile.in: Include apps/utils/GNUmakefile.inc
+	
 2007-10-30  Jules Bergmann  <jules@codesourcery.com>
 
 	* tests/tutorial/matlab_iter_example.cpp (test_write): New function,
Index: GNUmakefile.in
===================================================================
--- GNUmakefile.in	(revision 186094)
+++ GNUmakefile.in	(working copy)
@@ -273,6 +273,7 @@
 # have been processed.
 subdirs := \
 	apps \
+	apps/utils \
 	doc \
 	src \
 	src/vsip \
Index: src/vsip_csl/matlab_file.hpp
===================================================================
--- src/vsip_csl/matlab_file.hpp	(revision 186094)
+++ src/vsip_csl/matlab_file.hpp	(working copy)
@@ -111,6 +111,8 @@
 	      template <typename,typename> class View>
     void read_view(View<T,Block0> view, iterator  &iter);
 
+   Matlab_bin_hdr header() const { return matlab_header_; }
+
   private:
     Matlab_bin_hdr                    matlab_header_;
     std::ifstream                     is_;
Index: src/vsip_csl/matlab.hpp
===================================================================
--- src/vsip_csl/matlab.hpp	(revision 186094)
+++ src/vsip_csl/matlab.hpp	(working copy)
@@ -190,14 +190,17 @@
 
   }
 
-  struct header
-  {
-    char description[116];
-    char subsyt_data[8];
-    char version[2];
-    vsip::impl::uint16_type endian;
-  };
+struct File_header
+{
+  static vsip::length_type const description_size = 116;
+  static vsip::length_type const subsys_data_size = 8;
 
+  char description[description_size];
+  char subsys_data[subsys_data_size];
+  vsip::impl::uint16_type version;
+  vsip::impl::uint16_type endian;
+};
+
   // constants for matlab binary format
 
   // data types
@@ -304,6 +307,61 @@
   };
 
 
+
+// Return Matlab data type as a string.
+
+inline
+char const*
+data_type(int dt)
+{
+  switch (dt)
+  {
+  case miINT8:       return "miINT8";
+  case miUINT8:      return "miUINT8";
+  case miINT16:      return "miINT16";
+  case miUINT16:     return "miUINT16";
+  case miINT32:      return "miINT32";
+  case miUINT32:     return "miUINT32";
+  case miSINGLE:     return "miSINGLE";
+  case miDOUBLE:     return "miDOUBLE";
+  case miINT64:      return "miINT64";
+  case miUINT64:     return "miUINT64";
+  case miMATRIX:     return "miMATRIX";
+  case miCOMPRESSED: return "miCOMPRESSED";
+  case miUTF8:       return "miUTF8";
+  case miUTF16:      return "miUTF16";
+  case miUTF32:      return "miUTF32";
+  }
+  return "*unknown*";
+}
+
+
+
+// Return Matlab class type as a string.
+
+inline
+char const*
+class_type(int ct)
+{
+  switch(ct)
+  {
+  case mxCELL_CLASS:   return "mxCELL_CLASS";
+  case mxSTRUCT_CLASS: return "mxSTRUCT_CLASS";
+  case mxOBJECT_CLASS: return "mxOBJECT_CLASS";
+  case mxCHAR_CLASS:   return "mxCHAR_CLASS";
+  case mxSPARSE_CLASS: return "mxSPARSE_CLASS";
+  case mxDOUBLE_CLASS: return "mxDOUBLE_CLASS";
+  case mxSINGLE_CLASS: return "mxSINGLE_CLASS";
+  case mxINT8_CLASS:   return "mxINT8_CLASS";
+  case mxUINT8_CLASS:  return "mxUINT8_CLASS";
+  case mxINT16_CLASS:  return "mxINT16_CLASS";
+  case mxUINT16_CLASS: return "mxUINT16_CLASS";
+  case mxINT32_CLASS:  return "mxINT32_CLASS";
+  case mxUINT32_CLASS: return "mxUINT32_CLASS";
+  }
+  return "*unknown*";
+}
+
 } // namesapce matlab
 
 } // namespace vsip_csl
Index: src/vsip_csl/matlab_bin_formatter.hpp
===================================================================
--- src/vsip_csl/matlab_bin_formatter.hpp	(revision 186094)
+++ src/vsip_csl/matlab_bin_formatter.hpp	(working copy)
@@ -13,28 +13,37 @@
 #ifndef VSIP_CSL_MATLAB_BIN_FORMATTER_HPP
 #define VSIP_CSL_MATLAB_BIN_FORMATTER_HPP
 
+#include <sstream>
+#include <string>
+#include <limits>
+
 #include <vsip_csl/matlab.hpp>
 #include <vsip/core/fns_scalar.hpp>
 #include <vsip/core/fns_elementwise.hpp>
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/view_traits.hpp>
 #include <vsip/core/extdata.hpp>
-#include <string>
-#include <limits>
 
 namespace vsip_csl
 {
 
   struct Matlab_bin_hdr
   {
-    Matlab_bin_hdr(std::string const& descr) : 
-      description(descr),version("MATLAB 5.0 : ") {}
-    Matlab_bin_hdr() : 
-      description(" "),version("MATLAB 5.0 : ") {}
+    Matlab_bin_hdr(std::string const& user_descr)
+      : description     ("MATLAB 5.0 : "),
+	version         (0x100)
+    {
+      description.append(user_descr);
+    }
 
+    Matlab_bin_hdr()
+      : description     ("MATLAB 5.0 : "),
+	version         (0x100)
+    {}
+
     // description
-    std::string description;
-    std::string version;
+    std::string             description;
+    vsip::impl::uint16_type version;
     vsip::impl::uint16_type endian;
 
   };
@@ -75,21 +84,19 @@
 namespace vsip_csl
 {
 
-// operator to write matlab header
+// Write matlab file header.
 inline
 std::ostream&
 operator<<(
   std::ostream&           o,
   Matlab_bin_hdr const&   h)
 {
-  matlab::header m_hdr;
+  matlab::File_header m_hdr;
 
   // set hdr to spaces
   memset(&(m_hdr),' ',sizeof(m_hdr));
-  strncpy(m_hdr.description, h.version.data(), h.version.length());
-  strncpy(m_hdr.description+h.version.length(), h.description.data(),
-    h.description.length());
-  m_hdr.version[1] = 0x01; m_hdr.version[0] = 0x00;
+  strncpy(m_hdr.description, h.description.data(), h.description.length());
+  m_hdr.version = 0x0100;
   m_hdr.endian = 'M' << 8 | 'I';
 
   // write header
@@ -230,35 +237,70 @@
   return o;
 }
 
-// operator to read matlab header
+
+
+// Read matlab file header.
 inline
 std::istream&
 operator>>(
   std::istream&           is,
-  Matlab_bin_hdr          &h)
+  Matlab_bin_hdr&         h)
 {
-  matlab::header m_hdr;
+  matlab::File_header m_hdr;
 
   // read header
   is.read(reinterpret_cast<char*>(&m_hdr),sizeof(m_hdr));
   if(is.gcount() < sizeof(m_hdr))
-    VSIP_IMPL_THROW(std::runtime_error("Unexpected end of file"));
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Matlab_bin_hdr: Unexpected end of file"));
 
-  h.version[1] = m_hdr.version[1];
-  h.version[0] = m_hdr.version[0];
-  h.endian = m_hdr.endian;
+  m_hdr.description[matlab::File_header::description_size-1] = '\0';
+  h.description = std::string(m_hdr.description);
 
+  h.version = m_hdr.version;
+  h.endian  = m_hdr.endian;
+
   return is;
 }
 
-// a function to read a matlab view header into a Matlab_view_header class
+
+
+inline void
+skip_padding(std::istream& is, vsip::length_type length)
+{
+  is.ignore((8-length)&0x7);
+}
+
+
+
+// Read a matlab view header into a Matlab_view_header class
+//
+// On disk:
+//   |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |
+//   |-----+-----+-----+-----+-----+-----+-----+-----|
+//   |  miMATRIX             |  <size>               |  < data element header
+//
+//   |  miUINT32             |      8                |  < ARRAY FLAGS
+//   |  undef    | <F> | <C> |  undef                | 
+//
+//   |  miUINT32             |      12               | < DIMENSIONS ARRAY
+//   |  dim0                 |      dim1             |   (3-dim shown)
+//   |  dim2                 |      padding          | 
+
+//   |        3  | miINT8    | 'a' | 'r' | 'r' | pad | < ARRAY NAME
+//                                                       
+//
+//   Array Data.
+//
+// Notes:
+//   <C> is the class_type, i.e. mxDOUBLE_CLASS, etc.
+//
 inline
 std::istream&
 operator>>(
   std::istream&           is,
-  Matlab_view_header      &h)
+  Matlab_view_header&     h)
 {
-
   vsip::impl::uint32_type array_flags[2];
   vsip::impl::uint32_type dims[3];
   matlab::data_element temp_element;
@@ -268,11 +310,26 @@
 
   swap_bytes = h.swap_bytes;
 
-  // header
+  // 1. Read overall data element header for the object.  Identifies:
+  //  - type of data element (we can only handle miMATRIX),
+  //  - overall size of data element.
   is.read(reinterpret_cast<char*>(&temp_element),sizeof(temp_element));
   if(is.gcount() < sizeof(temp_element))
-    VSIP_IMPL_THROW(std::runtime_error("Unexpected end of file"));
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Matlab_view_header(read): Unexpected end of file"));
+  matlab::swap<vsip::impl::int32_type> (&(temp_element.type),swap_bytes);
   matlab::swap<vsip::impl::uint32_type>(&(temp_element.size),swap_bytes);
+
+  if (temp_element.type != matlab::miMATRIX)
+  {
+    std::ostringstream msg;
+    msg << "Matlab_view_header(read): Unsupported data_element type: ";
+    msg << "got " << matlab::data_type(temp_element.type)
+	<< " (" << temp_element.type << ")"
+	<< ", can only handl miMATRIX (" << matlab::miMATRIX << ")";
+    VSIP_IMPL_THROW(std::runtime_error(msg.str()));
+  }
+
   // store the file position of next header
   {
     std::istream::pos_type curr_pos = is.tellg();
@@ -280,78 +337,127 @@
     h.next_header          = curr_pos;
   }
 
-  // array_flags
+
+  // 2. Read the array_flags.
   is.read(reinterpret_cast<char*>(&temp_element),sizeof(temp_element));
   if(is.gcount() < sizeof(temp_element))
-    VSIP_IMPL_THROW(std::runtime_error("Unexpected end of file"));
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Matlab_view_header(read): Unexpected end of file"));
+  matlab::swap<vsip::impl::int32_type> (&(temp_element.type),swap_bytes);
   matlab::swap<vsip::impl::uint32_type>(&(temp_element.size),swap_bytes);
+
+  if (temp_element.type != matlab::miUINT32)
+  {
+    std::ostringstream msg;
+    msg << "Matlab_view_header(read): Unexpected type for array flags: ";
+    msg << "got " << temp_element.type << " bytes, expected miUINT32 (6)";
+    VSIP_IMPL_THROW(std::runtime_error(msg.str()));
+  }
+  if (temp_element.size > 8)
+  {
+    std::ostringstream msg;
+    msg << "Matlab_view_header(read): Length of array flags is too large: ";
+    msg << "got " << temp_element.size << " bytes, expected " << 8 << " bytes";
+    VSIP_IMPL_THROW(std::runtime_error(msg.str()));
+  }
   if(temp_element.size > 8)
     VSIP_IMPL_THROW(std::runtime_error(
       "Length of array flags is too large"));
   is.read(reinterpret_cast<char*>(&array_flags),temp_element.size);
   if(is.gcount() < temp_element.size)
-    VSIP_IMPL_THROW(std::runtime_error("Unexpected end of file"));
+    VSIP_IMPL_THROW(std::runtime_error(
+     "Matlab_view_header(read): Unexpected end of file reading array flags"));
   for(index_type i=0;i<temp_element.size/4;i++)
-    matlab::swap<vsip::impl::uint32_type>(&(dims[i]),swap_bytes);
+    matlab::swap<vsip::impl::uint32_type>(&(array_flags[i]),swap_bytes);
 
-  // read dimensions
+  // is this complex?
+  h.is_complex  = ((array_flags[0]&(1<<11)) == 1);
+  h.class_type  = (array_flags[0]&0xff);
+
+
+  // 3. Read dimensions.
   is.read(reinterpret_cast<char*>(&temp_element),sizeof(temp_element));
   if(is.gcount() < sizeof(temp_element))
-    VSIP_IMPL_THROW(std::runtime_error("Unexpected end of file"));
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Matlab_view_header(read): Unexpected end of file reading dimensions (1)"));
+  matlab::swap<vsip::impl::int32_type> (&(temp_element.type),swap_bytes);
   matlab::swap<vsip::impl::uint32_type>(&(temp_element.size),swap_bytes);
-  if(temp_element.size > 12)
-    VSIP_IMPL_THROW(std::runtime_error(
-      "Length of dims is too large"));
+
+  if ((temp_element.type & 0x0000ffff) != matlab::miINT32)
+  {
+    std::ostringstream msg;
+    msg << "Matlab_view_header(read): Unexpected type for dimensions array: ";
+    msg << "got " << temp_element.type << ", expected miINT32 (5)";
+    VSIP_IMPL_THROW(std::runtime_error(msg.str()));
+  }
+  if (temp_element.size > 12)
+  {
+    std::ostringstream msg;
+    msg << "Matlab_view_header(read): Number of dimensions is too large: ";
+    msg << "got " << temp_element.size/4 << ", can only handle 3";
+    VSIP_IMPL_THROW(std::runtime_error(msg.str()));
+  }
+
   is.read(reinterpret_cast<char*>(&dims),temp_element.size);
   if(is.gcount() < temp_element.size)
-    VSIP_IMPL_THROW(std::runtime_error("Unexpected end of file"));
-  for(index_type i=0;i<temp_element.size/4;i++)
-    matlab::swap<vsip::impl::uint32_type>(&(dims[i]),swap_bytes);
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Matlab_view_header(read): Unexpected end of file reading dimensions (2)"));
+  skip_padding(is, temp_element.size);
 
-  // read padding
-  is.ignore((8-temp_element.size)&0x7);
-
   h.num_dims = temp_element.size/4;
   for(index_type i=0;i<temp_element.size/4;i++)
+  {
+    matlab::swap<vsip::impl::uint32_type>(&(dims[i]),swap_bytes);
     h.dims[i] = dims[i];
+  }
 
-  // is this complex?
-  h.is_complex  = ((array_flags[0]&(1<<11)) == 1);
-  h.class_type  = (array_flags[0]&0xff);
 
-  // read array name
+  // 4. Read array name.
   is.read(reinterpret_cast<char*>(&temp_element),sizeof(temp_element));
   if(is.gcount() < sizeof(temp_element))
-    VSIP_IMPL_THROW(std::runtime_error("Unexpected end of file"));
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Matlab_view_header(read): Unexpected end of file reading array name (1)"));
   matlab::swap<vsip::impl::int32_type>(&(temp_element.type),swap_bytes);
-  matlab::swap<vsip::impl::uint32_type>(&(temp_element.size),swap_bytes);
+  // Don't swab the length yet, it may be a string.
+
+  if ((temp_element.type & 0x0000ffff) != matlab::miINT8)
+  {
+    std::ostringstream msg;
+    msg << "Matlab_view_header(read): Unexpected type for array name: ";
+    msg << "got " << matlab::data_type(temp_element.type)
+	<< " (" << temp_element.type << "),"
+	<< " expected miINT8 (" << matlab::miINT8 << ")";
+    VSIP_IMPL_THROW(std::runtime_error(msg.str()));
+  }
+
   if(temp_element.type & 0xffff0000)
   {
+    int length = (temp_element.type & 0xffff0000) >> 16;
     // array name is short
-    strcpy(h.array_name,
-      reinterpret_cast<char*>(&temp_element.size));
-
+    strncpy(h.array_name, reinterpret_cast<char*>(&temp_element.size), length);
+    h.array_name[length] = 0;
   }
   else
   {
+    matlab::swap<vsip::impl::uint32_type>(&(temp_element.size),swap_bytes);
     int length = temp_element.size;
     // the name is longer than 4 bytes
     if(length > 128)
-      VSIP_IMPL_THROW(std::runtime_error(
-        "Name of view is too large"));
+      VSIP_IMPL_THROW(std::runtime_error("Name of view is too large"));
 
     is.read(h.array_name,length);
     if(is.gcount() < length)
-      VSIP_IMPL_THROW(std::runtime_error("Unexpected end of file"));
+      VSIP_IMPL_THROW(std::runtime_error(
+	"Matlab_view_header(read): Unexpected end of file reading array name (2)"));
     h.array_name[length] = 0;
-    // read padding
-    is.ignore((8-length)&0x7);
+    skip_padding(is, length);
   }
 
   return is;
 }
 
 
+
 // operator to read view from matlab file
 template <typename T,
           typename Block0,
@@ -382,7 +488,8 @@
   // read header
   is.read(reinterpret_cast<char*>(&m_view),sizeof(m_view));
   if(is.gcount() < sizeof(m_view))
-    VSIP_IMPL_THROW(std::runtime_error("Unexpected end of file"));
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Matlab_bin_formatter(read): Unexpected end of file (1)"));
 
   // do we need to swap fields?
   matlab::swap_header(m_view,swap_value);
@@ -443,7 +550,8 @@
     is.read(reinterpret_cast<char*>(&temp_data_element),
             sizeof(temp_data_element));
     if(is.gcount() < sizeof(temp_data_element))
-      VSIP_IMPL_THROW(std::runtime_error("Unexpected end of file"));
+      VSIP_IMPL_THROW(std::runtime_error(
+        "Matlab_bin_formatter(read): Unexpected end of file (2)"));
 
     // should we swap this field?
     matlab::swap<vsip::impl::int32_type>(&(temp_data_element.type),swap_value);
Index: apps/utils/lsmat.cpp
===================================================================
--- apps/utils/lsmat.cpp	(revision 0)
+++ apps/utils/lsmat.cpp	(revision 0)
@@ -0,0 +1,148 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    apps/utils/lsmat.cpp
+    @author  Jules Bergmann
+    @date    2007-07-13
+    @brief   VSIPL++ Library: List views contained in .mat file.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+#include <fstream>
+
+#include <vsip/initfin.hpp>
+#include <vsip/vector.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/tensor.hpp>
+#include <vsip/selgen.hpp>
+#include <vsip/map.hpp>
+
+#include <vsip_csl/matlab_file.hpp>
+#include <vsip_csl/output.hpp>
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+template <dimension_type Dim,
+	  typename       T>
+void
+load_view(
+  Matlab_file&           mf,
+  Matlab_file::iterator& iter,
+  Domain<Dim> const&     dom)
+{
+  typedef Dense<Dim, T> block_type;
+  typedef typename impl::View_of_dim<Dim, T, block_type>::type view_type;
+
+  block_type block(dom);
+  view_type  view(block);
+
+  mf.read_view(view, iter);
+
+  cout << view;
+}
+
+
+
+void
+lsmat(char const* fname)
+{
+  // Create Matlab_file object for 'sample.mat' file.
+  Matlab_file mf(fname);
+  Matlab_file::iterator cur = mf.begin();
+  Matlab_file::iterator end = mf.end();
+
+  Matlab_bin_hdr hdr = mf.header();
+
+  cout << "Matlab file: " << fname << endl;
+  cout << "  descr  : " << hdr.description << endl;
+  cout << "  version: " << hdr.version << endl;
+  cout << "  endian : " << hdr.endian 
+       << " (swap: " 
+       << (hdr.endian == ('I'<<8 | 'M') ? "yes" :
+	   hdr.endian == ('M'<<8 | 'I') ? "no"  : "*unknown*")
+       << ")" << endl;
+
+
+  // Iterate through views in file.
+  while (cur != end)
+  {
+    Matlab_view_header* hdr = *cur;
+
+    cout << "view: " << hdr->array_name << endl;
+
+    // Dump array_name out by byte
+    // for (int i=0; hdr->array_name[i] != 0 && i<128; ++i)
+    //   cout << "  [" << i << "]: " << (int)hdr->array_name[i] << endl;
+
+    cout << "  dim       : " << hdr->num_dims;
+    if (hdr->num_dims > 0)
+    {
+      char* sep = " (";
+      for (index_type i=0; i<hdr->num_dims; ++i)
+      {
+	cout << sep << hdr->dims[i];
+	sep = ", ";
+      }
+      cout << ")";
+    }
+    cout << endl;
+
+    cout << "  is_complex: " << (hdr->is_complex ? "true" : "false") << endl;
+    cout << "  class_type: " << vsip_csl::matlab::class_type(hdr->class_type);
+    cout << " (" << (int)hdr->class_type << ")" << endl;
+
+    if (hdr->class_type == vsip_csl::matlab::mxDOUBLE_CLASS)
+    {
+      if (hdr->num_dims == 2 && hdr->dims[0] == 1)
+	load_view<1, double>(mf, cur, Domain<1>(hdr->dims[1]));
+      else if (hdr->num_dims == 2 && hdr->dims[1] == 1)
+	load_view<1, double>(mf, cur, Domain<1>(hdr->dims[0]));
+      else if (hdr->num_dims == 2)
+	load_view<2, double>(mf, cur, Domain<2>(hdr->dims[0], hdr->dims[1]));
+//      else if (hdr->num_dims == 3)
+//	load_view<3, double>(mf, cur, Domain<3>(hdr->dims[0], hdr->dims[1],
+//						hdr->dims[2]));
+    }
+    else if (hdr->class_type == vsip_csl::matlab::mxSINGLE_CLASS)
+    {
+      if (hdr->num_dims == 2 && hdr->dims[0] == 1)
+	load_view<1, float>(mf, cur, Domain<1>(hdr->dims[1]));
+      else if (hdr->num_dims == 2 && hdr->dims[1] == 1)
+	load_view<1, float>(mf, cur, Domain<1>(hdr->dims[0]));
+      else if (hdr->num_dims == 2)
+	load_view<2, float>(mf, cur, Domain<2>(hdr->dims[0], hdr->dims[1]));
+//      else if (hdr->num_dims == 3)
+//	load_view<3, float>(mf, cur, Domain<3>(hdr->dims[0], hdr->dims[1],
+//						hdr->dims[2]));
+    }
+
+    ++cur; // Move to next view stored in the file.
+  }
+}
+
+
+int
+main(int argc, char** argv)
+{
+  (void)argc;
+  char* fname = argv[1];
+
+  lsmat(fname);
+} 
+
Index: apps/utils/GNUmakefile.inc.in
===================================================================
--- apps/utils/GNUmakefile.inc.in	(revision 0)
+++ apps/utils/GNUmakefile.inc.in	(revision 0)
@@ -0,0 +1,71 @@
+######################################################### -*-Makefile-*-
+#
+# File:   GNUmakefile.inc
+# Author: Jules Bergmann
+# Date:   2007-10-30
+#
+# Contents: Makefile fragment for apps/utils.
+#
+########################################################################
+
+# Files in this directory are not available under the BSD license, so
+# avoid putting them into cxx_sources, building them, installing them,
+# etc. when building the reference implementation.
+ifndef VSIP_IMPL_REF_IMPL
+
+########################################################################
+# Variables
+########################################################################
+
+apps_utils_CXXINCLUDES := -I$(srcdir)/src -I$(srcdir)/tests	\
+			  -I$(srcdir)/apps/utils
+apps_utils_CXXFLAGS := $(apps_utils_CXXINCLUDES)
+
+apps_utils_cxx_sources := $(wildcard $(srcdir)/apps/utils/*.cpp)
+apps_utils_cxx_headers := $(wildcard $(srcdir)/apps/utils/*.hpp)
+
+apps_utils_obj := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(apps_utils_cxx_sources))
+apps_utils_exe := $(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(apps_utils_cxx_sources))
+apps_utils_targets := $(apps_utils_exe)
+
+cxx_sources += $(apps_utils_cxx_sources)
+
+apps_utils_install_sources := $(apps_utils_cxx_sources) $(apps_utils_cxx_headers)
+
+apps_utils_install_targets := $(patsubst $(srcdir)/%, %, $(apps_utils_install_sources))
+
+apps_utils_static_targets := $(patsubst %$(EXEEXT), \
+                               %.static$(EXEEXT), \
+                               $(apps_utils_targets))
+
+
+########################################################################
+# Rules
+########################################################################
+
+apps_utils:: $(apps_utils_targets)
+
+# Object files will be deleted by the parent clean rule.
+clean::
+	rm -f $(apps_utils_targets) $(apps_utils_static_targets)
+
+# Install benchmark source code and executables
+install-apps_utils:: apps_utils
+	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/apps/utils
+	$(INSTALL_DATA) apps/utils/GNUmakefile \
+	  $(DESTDIR)$(pkgdatadir)/apps/utils/GNUmakefile
+	for sourcefile in $(apps_utils_install_targets); do \
+          $(INSTALL_DATA) $(srcdir)/$$sourcefile $(DESTDIR)$(pkgdatadir)/`dirname $$sourcefile`; \
+	done
+	$(INSTALL) -d $(DESTDIR)$(exec_prefix)/apps/utils
+	for binfile in $(apps_utils_targets); do \
+	  $(INSTALL) $$binfile $(DESTDIR)$(exec_prefix)/`dirname $$binfile`; \
+	done
+
+$(apps_utils_targets): %$(EXEEXT) : %.$(OBJEXT) $(libs)
+	$(CXX) $(LDFLAGS) -o $@ $^ -Llib -lsvpp -lvsip_csl $(LIBS) || rm -f $@
+
+$(apps_utils_static_targets): %.static$(EXEEXT) : %.$(OBJEXT) $(libs)
+	$(CXX) -static $(LDFLAGS) -o $@ $^ -Llib -lsvpp -lvsip_csl $(LIBS) || rm -f $@
+
+endif # VSIP_IMPL_REF_IMPL
Index: apps/utils/GNUmakefile
===================================================================
--- apps/utils/GNUmakefile	(revision 0)
+++ apps/utils/GNUmakefile	(revision 0)
@@ -0,0 +1,76 @@
+########################################################################
+#
+# File:   GNUmakefile
+# Author: Jules Bergmann
+# Date:   2007-07-13
+#
+# Contents: Standalone Makefile for VSIPL++ apps/utils.
+#
+########################################################################
+
+PKG = vsipl++
+
+CXX      := $(shell pkg-config --variable=cxx $(PKG))
+OPT      := $(shell pkg-config --variable=cxxflags $(PKG))
+CXXFLAGS := $(shell pkg-config --cflags $(PKG)) $(OPT)
+CFLAGS   := $(CXXFLAGS)
+LIBS     := $(shell pkg-config --libs   $(PKG))
+
+OBJEXT   := o
+
+cxx_sources := $(wildcard *.cpp)
+c_sources   := $(wildcard *.c)
+
+objects     := $(patsubst %.cpp, %.$(OBJEXT), $(cxx_sources))	\
+	       $(patsubst %.c, %.$(OBJEXT), $(c_sources))
+deps        := $(patsubst %.cpp, %.d, $(cxx_sources))
+
+
+
+########################################################################
+# Standard Targets
+########################################################################
+
+all::
+
+depend:: $(deps)
+
+clean::
+
+ifeq (,$(filter $(MAKECMDGOALS), depend doc clean))
+include $(deps)
+endif
+
+ifneq (,$(findstring depend, $(MAKECMDGOALS)))
+$(deps): %.d:	.FORCE
+endif
+
+
+
+########################################################################
+# Application Targets
+########################################################################
+
+all:: $(APPS)
+
+lsmat: lsmat.o
+	$(CXX) $(OPT) -o $@ $^ $(LIBS)
+
+clean::
+	rm -f $(objects)
+	rm -f $(deps)
+	rm -f *.raw
+
+
+
+########################################################################
+# Implicit Rules
+########################################################################
+
+# Generate a dependency Makefile fragment for a C++ source file.
+# (This recipe is taken from the GNU Make manual.)
+%.d: %.cpp
+	$(SHELL) -ec '$(CXX) -M $(CXXFLAGS) \
+		      $(call dir_var,$(dir $<),CXXFLAGS) $< \
+		      | sed "s|$(*F)\\.$(OBJEXT)[ :]*|$*\\.d $*\\.$(OBJEXT) : |g" > $@'
+
Index: tests/matlab_bin_file/matlab_bin_file.cpp
===================================================================
--- tests/matlab_bin_file/matlab_bin_file.cpp	(revision 0)
+++ tests/matlab_bin_file/matlab_bin_file.cpp	(working copy)
@@ -4,7 +4,7 @@
    of a commercial license and under the GPL.  It is not part of the VSIPL++
    reference implementation and is not available under the BSD license.
 */
-/** @file    tests/matlab_bin_file_test.cpp
+/** @file    tests/matlab_bin_file/matlab_bin_file.cpp
     @author  Assem Salama
     @date    2006-07-18
     @brief   VSIPL++ Library: Test for reading and writing Matlab .mat files
@@ -161,55 +161,75 @@
 #if DEBUG == 1
   cout << a << endl;
 #endif
-
 }
 
-int main()
+
+void
+write_file(char const* name)
 {
+  std::ofstream ofs(name);
 
-  {
-    std::ofstream ofs("temp.mat");
+  // write header
+  ofs << Matlab_bin_hdr("example");
 
-    // write header
-    ofs << Matlab_bin_hdr("example");
-
-    // tests
+  // tests
+  vector_test<float>            (5,ofs,"float_vector");
+  vector_test<double>           (5,ofs,"double_vector");
+  vector_test<complex<float> >  (5,ofs,"cplx_float_vector");
+  vector_test<complex<double> > (5,ofs,"cplx_double_vector");
   
-    vector_test<float>            (5,ofs,"float_vector");
-    vector_test<double>           (5,ofs,"double_vector");
-    vector_test<complex<float> >  (5,ofs,"cplx_float_vector");
-    vector_test<complex<double> > (5,ofs,"cplx_double_vector");
+  matrix_test<float>            (2,3,ofs,"float_matrix");
+  matrix_test<double>           (2,3,ofs,"double_matrix");
+  matrix_test<complex<float> >  (2,3,ofs,"cplx_float_matrix");
+  matrix_test<complex<double> > (2,3,ofs,"cplx_double_matrix");
   
-    matrix_test<float>            (2,3,ofs,"float_matrix");
-    matrix_test<double>           (2,3,ofs,"double_matrix");
-    matrix_test<complex<float> >  (2,3,ofs,"cplx_float_matrix");
-    matrix_test<complex<double> > (2,3,ofs,"cplx_double_matrix");
+  tensor_test<float>            (3,2,3,ofs,"float_tensor");
+  tensor_test<double>           (3,2,3,ofs,"double_tensor");
+  tensor_test<complex<float> >  (3,2,3,ofs,"cplx_float_tensor");
+  tensor_test<complex<double> > (3,2,3,ofs,"cplx_double_tensor");
+}
 
-    tensor_test<float>            (3,2,3,ofs,"float_tensor");
-    tensor_test<double>           (3,2,3,ofs,"double_tensor");
-    tensor_test<complex<float> >  (3,2,3,ofs,"cplx_float_tensor");
-    tensor_test<complex<double> > (3,2,3,ofs,"cplx_double_tensor");
-  }
+
+
+void
+read_file(char const* name)
+{
+  std::ifstream ifs(name);
+
+  // Skip header
+  Matlab_bin_hdr h;
+  ifs >> h;
+
+  vector_input_test<float>                (5,ifs,"float_vector",h);
+  vector_input_test<double>               (5,ifs,"double_vector",h);
+  vector_input_test<complex<float> >      (5,ifs,"float_vector",h);
+  vector_input_test<complex<double> >     (5,ifs,"double_vector",h);
+
+  matrix_input_test<float>                (2,3,ifs,"float_matrix",h);
+  matrix_input_test<double>               (2,3,ifs,"double_matrix",h);
+  matrix_input_test<complex<float> >      (2,3,ifs,"cplx_float_matrix",h);
+  matrix_input_test<complex<double> >     (2,3,ifs,"cplx_double_matrix",h);
   
-  {
-    Matlab_bin_hdr h;
+  tensor_input_test<float>                (3,2,3,ifs,"float_tensor",h);
+  tensor_input_test<double>               (3,2,3,ifs,"double_tensor",h);
+  tensor_input_test<complex<float> >      (3,2,3,ifs,"cplx_float_tensor",h);
+  tensor_input_test<complex<double> >     (3,2,3,ifs,"cplx_double_tensor",h);
+}
 
-    std::ifstream ifs("temp.mat");
-    ifs >> h;
-    vector_input_test<float>                (5,ifs,"float_vector",h);
-    vector_input_test<double>               (5,ifs,"double_vector",h);
-    vector_input_test<complex<float> >      (5,ifs,"float_vector",h);
-    vector_input_test<complex<double> >     (5,ifs,"double_vector",h);
 
-    matrix_input_test<float>                (2,3,ifs,"float_matrix",h);
-    matrix_input_test<double>               (2,3,ifs,"double_matrix",h);
-    matrix_input_test<complex<float> >      (2,3,ifs,"cplx_float_matrix",h);
-    matrix_input_test<complex<double> >     (2,3,ifs,"cplx_double_matrix",h);
 
-    tensor_input_test<float>                (3,2,3,ifs,"float_tensor",h);
-    tensor_input_test<double>               (3,2,3,ifs,"double_tensor",h);
-    tensor_input_test<complex<float> >      (3,2,3,ifs,"cplx_float_tensor",h);
-    tensor_input_test<complex<double> >     (3,2,3,ifs,"cplx_double_tensor",h);
+int main(int ac, char** av)
+{
+  write_file("temp.mat");
+
+  // Read what we just wrote.
+  read_file("temp.mat");		
+
+  // Read a reference file if given.
+  if (ac == 2)
+  {
+    char const* file = av[1];
+    read_file(file);
   }
 
   return 0;
Index: tests/matlab_bin_file/data/matlab-ref-le.mat
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: tests/matlab_bin_file/data/matlab-ref-le.mat
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: tests/matlab_bin_file/data/matlab-ref-be.mat
===================================================================
Cannot display: file marked as a binary type.
svn:mime-type = application/octet-stream

Property changes on: tests/matlab_bin_file/data/matlab-ref-be.mat
___________________________________________________________________
Name: svn:mime-type
   + application/octet-stream

Index: tests/matlab_bin_file.cpp
===================================================================
--- tests/matlab_bin_file.cpp	(revision 185668)
+++ tests/matlab_bin_file.cpp	(working copy)
@@ -1,216 +0,0 @@
-/* Copyright (c) 2006 by CodeSourcery.  All rights reserved.
-
-   This file is available for license from CodeSourcery, Inc. under the terms
-   of a commercial license and under the GPL.  It is not part of the VSIPL++
-   reference implementation and is not available under the BSD license.
-*/
-/** @file    tests/matlab_bin_file_test.cpp
-    @author  Assem Salama
-    @date    2006-07-18
-    @brief   VSIPL++ Library: Test for reading and writing Matlab .mat files
-*/
-
-/***********************************************************************
-  Included Files
-***********************************************************************/
-
-#include <iostream>
-#include <iomanip>
-#include <fstream>
-
-#include <vsip/support.hpp>
-#include <vsip/matrix.hpp>
-#include <vsip/tensor.hpp>
-#include <vsip_csl/matlab_text_formatter.hpp>
-#include <vsip_csl/matlab_bin_formatter.hpp>
-#include <vsip_csl/output.hpp>
-#include <vsip_csl/test.hpp>
-
-#define DEBUG 0
-
-using namespace vsip;
-using namespace vsip_csl;
-using namespace std;
-
-float           increment(float v)  { return v+1; }
-double          increment(double v) { return v+1; }
-complex<float>  increment(complex<float>  v) { complex<float> i(1.,1.);
-					       return v+i; }
-complex<double> increment(complex<double> v) { complex<double> i(1.,1.);
-                                               return v+i; }
-
-template <typename T>
-void tensor_test(length_type m, length_type n, length_type o,
-  std::ofstream &ofs, char *name)
-{
-  Tensor<T> a(m,n,o);
-  T         value;
-
-  value = 0;
-  for(length_type i=0;i<m;i++) {
-    for(length_type j=0;j<n;j++) {
-      for(length_type k=0;k<o;k++) {
-        value = increment(value);
-        a.put(i,j,k,value);
-      }
-    }
-  }
-
-  // write it out to file
-  ofs << Matlab_bin_formatter<Tensor<T> >(a,name);
-}
-
-
-template <typename T>
-void matrix_test(length_type m, length_type n, std::ofstream &ofs, char *name)
-{
-  Matrix<T> a(m,n);
-  T         value;
-
-  value = 0;
-  for(length_type i=0;i<m;i++) {
-    for(length_type j=0;j<n;j++) {
-      value = increment(value);
-      a.put(i,j,value);
-    }
-  }
-
-  // write it out to file
-  ofs << Matlab_bin_formatter<Matrix<T> >(a,name);
-}
-
-template <typename T>
-void vector_test(length_type m, std::ofstream &ofs, char *name)
-{
-  Vector<T> a(m);
-  T         value;
-
-  value = 0;
-  for(length_type i=0;i<m;i++) {
-    value = increment(value);
-    a.put(i,value);
-  }
-
-  // write it out to file
-  ofs << Matlab_bin_formatter<Vector<T> >(a,name);
-}
-
-template <typename T>
-void vector_input_test(length_type m, std::ifstream &ifs,
-  char *name,Matlab_bin_hdr &h)
-{
-  Vector<T> a(m);
-  T         value,input_value;
-
-  ifs >> Matlab_bin_formatter<Vector<T> >(a,name,h);
-
-  value = 0;
-  for(length_type i=0;i<m;i++) {
-    value = increment(value);
-    input_value = a.get(i);
-    test_assert(value == input_value);
-  }
-#if DEBUG == 1
-  cout << a << endl;
-#endif
-
-}
-
-template <typename T>
-void matrix_input_test(length_type m, length_type n, std::ifstream &ifs,
-  char *name, Matlab_bin_hdr &h)
-{
-  Matrix<T> a(m,n);
-  T         value,input_value;
-
-  ifs >> Matlab_bin_formatter<Matrix<T> >(a,name,h);
-
-  value = 0;
-  for(length_type i=0;i<m;i++) {
-    for(length_type j=0;j<n;j++) {
-      value = increment(value);
-      input_value = a.get(i,j);
-      test_assert(value == input_value);
-    }
-  }
-#if DEBUG == 1
-  cout << a << endl;
-#endif
-
-}
-
-template <typename T>
-void tensor_input_test(length_type m, length_type n, length_type o,
-  std::ifstream &ifs, char *name, Matlab_bin_hdr &h)
-{
-  Tensor<T> a(m,n,o);
-  T         value,input_value;
-
-  ifs >> Matlab_bin_formatter<Tensor<T> >(a,name,h);
-
-  value = 0;
-  for(length_type i=0;i<m;i++) {
-    for(length_type j=0;j<n;j++) {
-      for(length_type k=0;k<o;k++) {
-        value = increment(value);
-        input_value = a.get(i,j,k);
-        test_assert(value == input_value);
-      }
-    }
-  }
-#if DEBUG == 1
-  cout << a << endl;
-#endif
-
-}
-
-int main()
-{
-
-  {
-    std::ofstream ofs("temp.mat");
-
-    // write header
-    ofs << Matlab_bin_hdr("example");
-
-    // tests
-  
-    vector_test<float>            (5,ofs,"float_vector");
-    vector_test<double>           (5,ofs,"double_vector");
-    vector_test<complex<float> >  (5,ofs,"cplx_float_vector");
-    vector_test<complex<double> > (5,ofs,"cplx_double_vector");
-  
-    matrix_test<float>            (2,3,ofs,"float_matrix");
-    matrix_test<double>           (2,3,ofs,"double_matrix");
-    matrix_test<complex<float> >  (2,3,ofs,"cplx_float_matrix");
-    matrix_test<complex<double> > (2,3,ofs,"cplx_double_matrix");
-
-    tensor_test<float>            (3,2,3,ofs,"float_tensor");
-    tensor_test<double>           (3,2,3,ofs,"double_tensor");
-    tensor_test<complex<float> >  (3,2,3,ofs,"cplx_float_tensor");
-    tensor_test<complex<double> > (3,2,3,ofs,"cplx_double_tensor");
-  }
-  
-  {
-    Matlab_bin_hdr h;
-
-    std::ifstream ifs("temp.mat");
-    ifs >> h;
-    vector_input_test<float>                (5,ifs,"float_vector",h);
-    vector_input_test<double>               (5,ifs,"double_vector",h);
-    vector_input_test<complex<float> >      (5,ifs,"float_vector",h);
-    vector_input_test<complex<double> >     (5,ifs,"double_vector",h);
-
-    matrix_input_test<float>                (2,3,ifs,"float_matrix",h);
-    matrix_input_test<double>               (2,3,ifs,"double_matrix",h);
-    matrix_input_test<complex<float> >      (2,3,ifs,"cplx_float_matrix",h);
-    matrix_input_test<complex<double> >     (2,3,ifs,"cplx_double_matrix",h);
-
-    tensor_input_test<float>                (3,2,3,ifs,"float_tensor",h);
-    tensor_input_test<double>               (3,2,3,ifs,"double_tensor",h);
-    tensor_input_test<complex<float> >      (3,2,3,ifs,"cplx_float_tensor",h);
-    tensor_input_test<complex<double> >     (3,2,3,ifs,"cplx_double_tensor",h);
-  }
-
-  return 0;
-}
