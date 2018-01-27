Index: matlab_file.cpp
===================================================================
--- matlab_file.cpp	(revision 0)
+++ matlab_file.cpp	(revision 0)
@@ -0,0 +1,39 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip_csl/matlab_file.cpp
+    @author  Assem Salama
+    @date    2006-06-21
+    @brief   VSIPL++ CodeSourcery Library: Matlab_file class functions
+*/
+
+#include "vsip_csl/matlab_bin_formatter.hpp"
+#include "vsip_csl/matlab_file.hpp"
+
+namespace vsip_csl
+{
+
+Matlab_file::Matlab_file(std::string fname) :
+  is_(fname.c_str()),
+  begin_iterator_(&is_,false),
+  end_iterator_(&is_,true)
+
+{
+  // read header to make sure it is matlab file
+  is_ >> matlab_header_;
+
+  // get length of file
+  {
+    std::istream::off_type temp_offset = 0;
+    std::istream::pos_type temp_pos = is_.tellg();
+    is_.seekg(temp_offset,std::ios::end);
+    begin_iterator_.set_length(static_cast<uint32_t>(is_.tellg()));
+    is_.seekg(temp_pos);
+  }
+  begin_iterator_.set_endian(matlab_header_.endian == ('I' << 8|'M'));
+
+  // read first header
+  begin_iterator_.read_header();
+
+}
+
+}
Index: GNUmakefile.inc.in
===================================================================
--- GNUmakefile.inc.in	(revision 144402)
+++ GNUmakefile.inc.in	(working copy)
@@ -22,8 +22,10 @@
 endif
 src_vsip_csl_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT),\
                               $(src_vsip_csl_cxx_sources))
-cxx_sources += $(src_vsip_csl_cxx_sources)
 
+cxx_sources += $(src_vsip_csl_cxx_sources) matlab.cpp
+cxx_objects += $(src_vsip_csl_cxx_objects) matlab.$(OBJEXT)
+
 libs += lib/libvsip_csl.a
 
 ########################################################################
@@ -35,7 +37,7 @@
 clean::
 	rm -f lib/libvsip_csl.a
 
-lib/libvsip_csl.a: $(src_vsip_csl_cxx_objects)
+lib/libvsip_csl.a: $(cxx_objects)
 	$(AR) rc $@ $^ || rm -f $@
 
 # Install the extensions library and its header files.
Index: matlab_file.hpp
===================================================================
--- matlab_file.hpp	(revision 0)
+++ matlab_file.hpp	(revision 0)
@@ -0,0 +1,217 @@
+/* Copyright (c) 2005, 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip_csl/matlab_file.hpp
+    @author  Assem Salama
+    @date    2006-06-21
+    @brief   VSIPL++ CodeSourcery Library: Matlab file class that handles
+             Matlab files using an iterator.
+*/
+
+#ifndef VSIP_CSL_MATLAB_FILE_HPP
+#define VSIP_CSL_MATLAB_FILE_HPP
+
+#include <iostream>
+#include <fstream>
+#include "vsip_csl/matlab_bin_formatter.hpp"
+
+namespace vsip_csl
+{
+
+class Matlab_file
+{
+  public:
+    // Constructors
+    Matlab_file(std::string fname);
+
+  // classes
+  public:
+    class iterator
+    {
+      public:
+        iterator(std::ifstream *ifs,bool end_of_file) :
+	  ifs_(ifs), end_of_file_(end_of_file),
+	  read_data_(false) {}
+        
+	bool is_eof() { return end_of_file_; }
+	void set_endian(bool swap_bytes) 
+	  { view_header_.swap_bytes = swap_bytes;}
+	void set_length(uint32_t length) { length_ = length; }
+	void read_header() { (*ifs_) >> view_header_; }
+	std::istream *get_stream() { return ifs_; }
+
+      // operators
+      public:
+        iterator& operator++()
+	{
+	  if(!read_data_)
+	  {
+	    // advance file pointer to next header
+	    // make sure that we don't go beyond the end of file!
+	    if(view_header_.next_header >= length_)
+	      end_of_file_ = true;
+	    else 
+	      ifs_->seekg(view_header_.next_header);
+
+	  }
+	  if(!end_of_file_) // read next header
+	    (*ifs_) >> view_header_;
+
+	  read_data_ = false;
+	  return *this;
+	}
+
+	bool operator==(iterator &i1)
+	{
+	  return i1.is_eof() == end_of_file_;
+	}
+
+	bool operator!=(iterator &i1)
+	{
+	  return i1.is_eof() != end_of_file_;
+	}
+
+	Matlab_view_header*
+	operator*()
+	{
+	  return &view_header_;
+	}
+
+     
+      private:
+        Matlab_view_header view_header_;
+	std::ifstream *ifs_;
+	bool end_of_file_;
+	bool read_data_;
+	uint32_t length_;
+    };
+
+  public:
+    // iterator functions
+    iterator begin() { return begin_iterator_; };
+    iterator end() { return end_iterator_; };
+
+    // read a view from a matlab file after reading the header
+    template <typename T,
+	      typename Block0,
+	      template <typename,typename> class View>
+    void read_view(View<T,Block0> view, iterator  &iter);
+
+  private:
+    Matlab_bin_hdr                    matlab_header_;
+    std::ifstream                     is_;
+    iterator                          begin_iterator_;
+    iterator                          end_iterator_;
+
+
+};
+
+
+/*****************************************************************************
+ * Definitions
+ *****************************************************************************/
+
+// read a view from a matlab file after reading the header
+template <typename T,
+	  typename Block0,
+	  template <typename,typename> class View>
+void Matlab_file::read_view(View<T,Block0> view, iterator  &iter)
+{
+  typedef typename vsip::impl::Scalar_of<T>::type scalar_type;
+  vsip::dimension_type v_dim = vsip::impl::Dim_of_view<View>::dim;
+  Matlab_view_header *header = *iter;
+  std::istream *is = iter.get_stream();
+
+  // is this complex?
+  if(vsip::impl::Is_complex<T>::value && !header->is_complex)
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Trying to read complex view into a real view"));
+
+  // is the class ok?
+  if(!(header->class_type == 
+            (matlab::Matlab_header_traits<sizeof(scalar_type),
+                  std::numeric_limits<scalar_type>::is_signed,
+                  std::numeric_limits<scalar_type>::is_integer>::class_type)
+	    ))
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Trying to read a view of a different class"));
+
+  // do dimensions agree?
+  if(v_dim == 1) header->num_dims--; // special case for vectors
+  if(v_dim != header->num_dims)
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Trying to read a view of different dimensions"));
+
+  for(vsip::dimension_type i=0;i<v_dim;i++)
+    if(view.size(i) != header->dims[i])
+      VSIP_IMPL_THROW(std::runtime_error(
+        "View dimensions don't agree"));
+
+  // read data, we will go in this loop twice if we have complex data
+  for (int i=0;i <= vsip::impl::Is_complex<T>::value;i++)
+  {
+    typedef matlab::Subview_helper<View<T,Block0> > subview;
+    typedef typename subview::realview_type r_v;
+    typedef typename subview::imagview_type i_v;
+    bool     swap_value = header->swap_bytes;
+    matlab::data_element temp_data_element;
+
+    // read data header
+    is->read(reinterpret_cast<char*>(&temp_data_element),
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
+      if(i==0)matlab::read<int8_t,r_v>(*is,subview::real(view),swap_value);
+      else    matlab::read<int8_t,i_v>(*is,subview::imag(view),swap_value);
+    }
+    else if(temp_data_element.type == matlab::miUINT8) 
+    {
+      if(i==0)matlab::read<uint8_t,r_v>(*is,subview::real(view),swap_value);
+      else    matlab::read<uint8_t,i_v>(*is,subview::imag(view),swap_value);
+    }
+    else if(temp_data_element.type == matlab::miINT16) 
+    {
+      if(i==0)matlab::read<int16_t,r_v>(*is,subview::real(view),swap_value);
+      else    matlab::read<int16_t,i_v>(*is,subview::imag(view),swap_value);
+    }
+    else if(temp_data_element.type == matlab::miUINT16) 
+    {
+      if(i==0)matlab::read<uint16_t,r_v>(*is,subview::real(view),swap_value);
+      else    matlab::read<uint16_t,i_v>(*is,subview::imag(view),swap_value);
+    }
+    else if(temp_data_element.type == matlab::miINT32) 
+    {
+      if(i==0)matlab::read<int32_t,r_v>(*is,subview::real(view),swap_value);
+      else    matlab::read<int32_t,i_v>(*is,subview::imag(view),swap_value);
+    }
+    else if(temp_data_element.type == matlab::miUINT32) 
+    {
+      if(i==0)matlab::read<uint32_t,r_v>(*is,subview::real(view),swap_value);
+      else    matlab::read<uint32_t,i_v>(*is,subview::imag(view),swap_value);
+    }
+    else if(temp_data_element.type == matlab::miSINGLE) 
+    {
+      if(i==0)matlab::read<float,r_v>(*is,subview::real(view),swap_value);
+      else    matlab::read<float,i_v>(*is,subview::imag(view),swap_value);
+    }
+    else
+    {
+      if(i==0)matlab::read<double,r_v>(*is,subview::real(view),swap_value);
+      else    matlab::read<double,i_v>(*is,subview::imag(view),swap_value);
+    }
+
+  }
+
+
+}
+
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_MATLAB_FILE_HPP
