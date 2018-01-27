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
@@ -17,12 +17,13 @@
 src_vsip_csl_CXXINCLUDES := -I$(srcdir)/src
 src_vsip_csl_CXXFLAGS := $(src_vsip_csl_CXXINCLUDES)
 
+src_vsip_csl_cxx_sources = $(srcdir)/src/vsip_csl/matlab_file.cpp
+
 ifdef VSIP_CSL_HAVE_PNG
 src_vsip_csl_cxx_sources += $(srcdir)/src/vsip_csl/png.cpp
 endif
 src_vsip_csl_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT),\
                               $(src_vsip_csl_cxx_sources))
-cxx_sources += $(src_vsip_csl_cxx_sources)
 
 libs += lib/libvsip_csl.a
 
Index: src/vsip_csl/matlab_file.hpp
===================================================================
--- src/vsip_csl/matlab_file.hpp	(revision 0)
+++ src/vsip_csl/matlab_file.hpp	(revision 0)
@@ -0,0 +1,248 @@
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
+#include <vsip/impl/noncopyable.hpp>
+#include <vsip_csl/matlab_bin_formatter.hpp>
+
+namespace vsip_csl
+{
+
+class Matlab_file : vsip::impl::Non_copyable
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
+        iterator(bool end_iterator,Matlab_file *mf) :
+	  mf_(mf),
+	  end_iterator_(end_iterator) {}
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
+	void read_header() { mf_->is_ >> mf_->view_header_; }
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
+      private:
+        Matlab_file *mf_;
+        bool end_iterator_;
+
+      friend class Matlab_file;
+     
+    };
+    
+  friend class iterator;
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
+  std::istream *is = &(this->is_);
+
+  // make sure that this iterator points to the same Matlab_file pointer
+  assert(iter.mf_ == this);
+
+  // make sure that both the view and the file are both complex or real
+  if(vsip::impl::Is_complex<T>::value && !header->is_complex)
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Trying to read complex view into a real view"));
+
+  // make sure that both the view and the file have the same class
+  if(!(header->class_type == 
+            (matlab::Matlab_header_traits<sizeof(scalar_type),
+                  std::numeric_limits<scalar_type>::is_signed,
+                  std::numeric_limits<scalar_type>::is_integer>::class_type)
+	    ))
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Trying to read a view of a different class"));
+
+  // make sure that both the view and the file have the same dimensions
+  if(v_dim == 1) header->num_dims--; // special case for vectors
+  if(v_dim != header->num_dims)
+    VSIP_IMPL_THROW(std::runtime_error(
+      "Trying to read a view of different dimensions"));
+
+  if(v_dim == 1)  // special case for vectors because they can be 1xN or Nx1
+  {
+    if( (view.size(0) != header->dims[0] && header->dims[1] == 1) ||
+        (view.size(0) != header->dims[1] && header->dims[0] == 1) )
+      VSIP_IMPL_THROW(std::runtime_error(
+        "View dimensions don't agree"));
+  }
+  else
+  {
+    for(vsip::dimension_type i=0;i<v_dim;i++)
+      if(view.size(i) != header->dims[i])
+        VSIP_IMPL_THROW(std::runtime_error(
+          "View dimensions don't agree"));
+  }
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
@@ -0,0 +1,191 @@
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
+    Vector<T> a(std::max(header->dims[0],header->dims[1]));
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
+template <typename T>
+void tensor_test(length_type m, length_type n, length_type o,
+  std::ofstream &ofs, char *name)
+{
+  Tensor<T> a(m,n,o);
+  T         value;
+
+  value = 0;
+  for(length_type i=0;i<m;i++) {
+    for(length_type j=0;j<n;j++) {
+      for(length_type k=0;k<o;k++) {
+        value = increment(value);
+        a.put(i,j,k,value);
+      }
+    }
+  }
+
+  // write it out to file
+  ofs << Matlab_bin_formatter<Tensor<T> >(a,name);
+}
+
+
+template <typename T>
+void matrix_test(length_type m, length_type n, std::ofstream &ofs, char *name)
+{
+  Matrix<T> a(m,n);
+  T         value;
+
+  value = 0;
+  for(length_type i=0;i<m;i++) {
+    for(length_type j=0;j<n;j++) {
+      value = increment(value);
+      a.put(i,j,value);
+    }
+  }
+
+  // write it out to file
+  ofs << Matlab_bin_formatter<Matrix<T> >(a,name);
+}
+
+template <typename T>
+void vector_test(length_type m, std::ofstream &ofs, char *name)
+{
+  Vector<T> a(m);
+  T         value;
+
+  value = 0;
+  for(length_type i=0;i<m;i++) {
+    value = increment(value);
+    a.put(i,value);
+  }
+
+  // write it out to file
+  ofs << Matlab_bin_formatter<Vector<T> >(a,name);
+}
+int main()
+{
+  // We need to generate the matlab file first.
+  {
+    std::ofstream ofs("temp.mat");
+
+    // write header
+    ofs << Matlab_bin_hdr("example");
+
+    // tests
+  
+    vector_test<float>            (5,ofs,"float_vector");
+    vector_test<double>           (5,ofs,"double_vector");
+    vector_test<complex<float> >  (5,ofs,"cplx_float_vector");
+    vector_test<complex<double> > (5,ofs,"cplx_double_vector");
+  
+    matrix_test<float>            (2,3,ofs,"float_matrix");
+    matrix_test<double>           (2,3,ofs,"double_matrix");
+    matrix_test<complex<float> >  (2,3,ofs,"cplx_float_matrix");
+    matrix_test<complex<double> > (2,3,ofs,"cplx_double_matrix");
+
+    tensor_test<float>            (3,2,3,ofs,"float_tensor");
+    tensor_test<double>           (3,2,3,ofs,"double_tensor");
+    tensor_test<complex<float> >  (3,2,3,ofs,"cplx_float_tensor");
+    tensor_test<complex<double> > (3,2,3,ofs,"cplx_double_tensor");
+  }
+  
+  
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
Index: tests/matlab_bin_file_test.cpp
===================================================================
--- tests/matlab_bin_file_test.cpp	(revision 144405)
+++ tests/matlab_bin_file_test.cpp	(working copy)
@@ -1,212 +0,0 @@
-/* Copyright (c) 2006 by CodeSourcery, LLC.  All rights reserved. */
-
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
-#include <test.hpp>
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
