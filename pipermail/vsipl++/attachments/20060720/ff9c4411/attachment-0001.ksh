Index: src/vsip_csl/matlab_file.cpp
===================================================================
--- src/vsip_csl/matlab_file.cpp	(revision 0)
+++ src/vsip_csl/matlab_file.cpp	(revision 0)
@@ -0,0 +1,42 @@
+/* Copyright (c) 2006 by CodeSourcery.  All rights reserved. */
+
+/** @file    vsip_csl/matlab_file.cpp
+    @author  Assem Salama
+    @date    2006-06-21
+    @brief   VSIPL++ CodeSourcery Library: Matlab_file class functions
+*/
+
+#include <vsip_csl/matlab_bin_formatter.hpp>
+#include <vsip_csl/matlab_file.hpp>
+
+namespace vsip_csl
+{
+
+Matlab_file::Matlab_file(std::string fname) :
+  is_(fname.c_str()),
+  begin_iterator_(false,this),
+  end_iterator_(true,this)
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
+    length_ = static_cast<uint32_t>(is_.tellg());
+    is_.seekg(temp_pos);
+  }
+  view_header_.swap_bytes = matlab_header_.endian == ('I' << 8|'M');
+
+  // read first header
+  begin_iterator_.read_header();
+  // set the end_of_file_ flag
+  end_of_file_ = false;
+  read_data_ = false;
+
+}
+
+}
Index: src/vsip_csl/matlab_bin_formatter.hpp
===================================================================
--- src/vsip_csl/matlab_bin_formatter.hpp	(revision 145188)
+++ src/vsip_csl/matlab_bin_formatter.hpp	(working copy)
@@ -246,6 +246,95 @@
   return is;
 }
 
+// a function to read a matlab view header into a Matlab_view_header class
+inline
+std::istream&
+operator>>(
+  std::istream&           is,
+  Matlab_view_header      &h)
+{
+
+  uint32_t array_flags[2];
+  uint32_t dims[3];
+  matlab::data_element temp_element;
+  bool swap_bytes;
+  typedef vsip::index_type index_type;
+  typedef vsip::length_type length_type;
+  char temp_c;
+
+  swap_bytes = h.swap_bytes;
+
+  // header
+  is.read(reinterpret_cast<char*>(&temp_element),sizeof(temp_element));
+  matlab::swap<uint32_t>(&(temp_element.size),swap_bytes);
+  // store the file position of next header
+  {
+    std::istream::pos_type curr_pos = is.tellg();
+    curr_pos               += temp_element.size;
+    h.next_header          = curr_pos;
+  }
+
+  // array_flags
+  is.read(reinterpret_cast<char*>(&temp_element),sizeof(temp_element));
+  matlab::swap<uint32_t>(&(temp_element.size),swap_bytes);
+  if(temp_element.size > 8)
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Lenght of array flags is too large"));
+  is.read(reinterpret_cast<char*>(&array_flags),temp_element.size);
+  for(index_type i=0;i<temp_element.size/4;i++)
+    matlab::swap<uint32_t>(&(dims[i]),swap_bytes);
+
+  // read dimensions
+  is.read(reinterpret_cast<char*>(&temp_element),sizeof(temp_element));
+  matlab::swap<uint32_t>(&(temp_element.size),swap_bytes);
+  if(temp_element.size > 12)
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Lenght of dims is too large"));
+  is.read(reinterpret_cast<char*>(&dims),temp_element.size);
+  for(index_type i=0;i<temp_element.size/4;i++)
+    matlab::swap<uint32_t>(&(dims[i]),swap_bytes);
+
+  // read padding
+  for(length_type i=0;i< ((8-temp_element.size)&0x7);i++)
+    is.read(&temp_c,1);
+  h.num_dims = temp_element.size/4;
+  for(index_type i=0;i<temp_element.size/4;i++)
+    h.dims[i] = dims[i];
+
+  // is this complex?
+  h.is_complex  = ((array_flags[0]&(1<<11)) == 1);
+  h.class_type  = (array_flags[0]&0xff);
+
+  // read array name
+  is.read(reinterpret_cast<char*>(&temp_element),sizeof(temp_element));
+  matlab::swap<int32_t>(&(temp_element.type),swap_bytes);
+  matlab::swap<uint32_t>(&(temp_element.size),swap_bytes);
+  if(temp_element.type & 0xffff0000)
+  {
+    // array name is short
+    strcpy(h.array_name,
+      reinterpret_cast<char*>(&temp_element.size));
+
+  }
+  else
+  {
+    int length = temp_element.size;
+    char c;
+    // the name is longer than 4 bytes
+    if(length > 128)
+      VSIP_IMPL_THROW(std::runtime_error(
+        "Name of view is too large"));
+
+    is.read(h.array_name,length);
+    h.array_name[length] = 0;
+    // read padding
+    for(int i=0;i<((8-length)&0x7);i++) is.read(&c,1);
+  }
+
+  return is;
+}
+
+
 // operator to read view from matlab file
 template <typename T,
           typename Block0,
Index: src/vsip_csl/GNUmakefile.inc.in
===================================================================
--- src/vsip_csl/GNUmakefile.inc.in	(revision 144405)
+++ src/vsip_csl/GNUmakefile.inc.in	(working copy)
@@ -22,8 +22,10 @@
 endif
 src_vsip_csl_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT),\
                               $(src_vsip_csl_cxx_sources))
-cxx_sources += $(src_vsip_csl_cxx_sources)
 
+cxx_sources += $(src_vsip_csl_cxx_sources) matlab_file.cpp
+cxx_objects += $(src_vsip_csl_cxx_objects) matlab_file.$(OBJEXT)
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
Index: src/vsip_csl/matlab_file.hpp
===================================================================
--- src/vsip_csl/matlab_file.hpp	(revision 0)
+++ src/vsip_csl/matlab_file.hpp	(revision 0)
@@ -0,0 +1,245 @@
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
+        iterator() {}
+        iterator(bool end_iterator,Matlab_file *mf) :
+	  mf_(mf),
+	  end_iterator_(end_iterator) {}
+        
+	void read_header() { mf_->is_ >> mf_->view_header_; }
+	std::istream *get_stream() { return &(mf_->is_); }
+
+      // operators
+      public:
+        iterator& operator++()
+	{
+	  if(!mf_->read_data_)
+	  {
+	    // advance file pointer to next header
+	    // make sure that we don't go beyond the end of file!
+	    if(mf_->view_header_.next_header >= mf_->length_)
+	      mf_->end_of_file_ = true;
+	    else 
+	      mf_->is_.seekg(mf_->view_header_.next_header);
+
+	  }
+	  if(!mf_->end_of_file_) // read next header
+            read_header();
+
+	  mf_->read_data_ = false;
+	  return *this;
+	}
+
+	bool operator==(iterator &i1)
+	{
+	  return mf_->end_of_file_ == i1.end_iterator_;
+	}
+
+	bool operator!=(iterator &i1)
+	{
+	  return mf_->end_of_file_ != i1.end_iterator_;
+	}
+
+	Matlab_view_header*
+	operator*()
+	{
+	  return &(mf_->view_header_);
+	}
+
+      public:
+	// copy constructors
+	iterator(iterator const &obj) : 
+          mf_(obj.mf_), end_iterator_(obj.end_iterator_) {}
+
+        // = operator
+	iterator&
+	operator=(iterator &src)
+	{
+	  this->mf_           = src.mf_;
+	  this->end_iterator_ = src.end_iterator_;
+	  return *this;
+	}
+
+      private:
+        Matlab_file *mf_;
+        bool end_iterator_;
+
+     
+    };
+    
+    friend class iterator;
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
+  // these variables are used for the iterator
+  private:
+    Matlab_view_header view_header_;
+    bool read_data_;
+    bool end_of_file_;
+    uint32_t length_;
+
+  // make a private copy constructor and assignment
+  private:
+    Matlab_file(Matlab_file const & /*obj*/) {}
+    Matlab_file& operator=(Matlab_file & /*src*/) 
+      { 
+        VSIP_IMPL_THROW(std::runtime_error(
+          "Trying to use Matlab_file assignment operator"));
+        return *this; 
+      }
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
Index: tests/matlab_iterator_test.cpp
===================================================================
--- tests/matlab_iterator_test.cpp	(revision 0)
+++ tests/matlab_iterator_test.cpp	(revision 0)
@@ -0,0 +1,112 @@
+/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
+
+/** @file    tests/matlab_bin_file_test.cpp
+    @author  Assem Salama
+    @date    2006-07-18
+    @brief   VSIPL++ Library: Test for reading and writing Matlab .mat files 
+             using iterators
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <iostream>
+
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/tensor.hpp>
+#include <vsip_csl/matlab_file.hpp>
+#include <vsip_csl/output.hpp>
+
+#include "test.hpp"
+
+using namespace std;
+using namespace vsip;
+using namespace vsip_csl;
+
+#define MAX(a,b) ( (a>b)? a:b)
+
+float           increment(float v)  { return v+1; }
+double          increment(double v) { return v+1; }
+complex<float>  increment(complex<float>  v) { complex<float> i(1.,1.);
+					       return v+i; }
+complex<double> increment(complex<double> v) { complex<double> i(1.,1.);
+                                               return v+i; }
+
+template <typename T,
+	  typename Block0,
+	  template <typename,typename> class View>
+
+void view_test(View<T,Block0> view)
+{
+  dimension_type const View_dim = View<T,Block0>::dim;
+  impl::Length<View_dim> v_extent = extent(view);
+  Index<View_dim> my_index;
+  T view_data,comp_data;
+
+  comp_data = 0;
+  for(index_type i=0;i<view.size();i++)
+  {
+    comp_data=increment(comp_data);
+    view_data = get(view,my_index);
+    
+    test_assert(comp_data == view_data);
+      
+    my_index = next(v_extent,my_index);
+  }
+}	
+
+template <typename T>
+void read_view_test(Matlab_file::iterator iterator, Matlab_file &mf)
+{
+  Matlab_view_header *header = *iterator;
+  if(header->num_dims == 2 && (header->dims[0] == 1 | header->dims[1] == 1))
+  {
+    // vector
+    Vector<T> a(MAX(header->dims[0],header->dims[1]));
+    mf.read_view(a,iterator);
+    view_test(a);
+  } else if(header->num_dims == 2)
+  {
+    // matrix
+    Matrix<T> a(header->dims[0],header->dims[1]);
+    mf.read_view(a,iterator);
+    view_test(a);
+  } else if(header->num_dims == 3)
+  {
+    // tensor
+    Tensor<T> a(header->dims[0],header->dims[1],header->dims[2]);
+    mf.read_view(a,iterator);
+    view_test(a);
+  }
+}
+
+int main()
+{
+  Matlab_file mf("temp.mat");
+  Matlab_file::iterator begin = mf.begin();
+  Matlab_file::iterator end   = mf.end();
+  Matlab_view_header *temp_p;
+
+  while(begin != end)
+  {
+    temp_p = *begin;
+    if(temp_p->is_complex) 
+    {
+      if(temp_p->class_type == matlab::mxSINGLE_CLASS)
+        read_view_test<complex<float> >(begin,mf);
+      if(temp_p->class_type == matlab::mxDOUBLE_CLASS)
+        read_view_test<complex<double> >(begin,mf);
+    }
+    else
+    {
+      if(temp_p->class_type == matlab::mxSINGLE_CLASS)
+        read_view_test<float>(begin,mf);
+      if(temp_p->class_type == matlab::mxDOUBLE_CLASS)
+        read_view_test<double>(begin,mf);
+    }
+    ++begin;
+  }
+  return 0;
+}
