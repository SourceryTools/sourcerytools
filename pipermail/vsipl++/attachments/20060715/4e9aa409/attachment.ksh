Index: tests/matlab_bin_file_test.cpp
===================================================================
--- tests/matlab_bin_file_test.cpp	(revision 0)
+++ tests/matlab_bin_file_test.cpp	(revision 0)
@@ -0,0 +1,195 @@
+#include <iostream>
+#include <iomanip>
+#include <fstream>
+
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/tensor.hpp>
+#include <vsip_csl/matlab_text_formatter.hpp>
+#include <vsip_csl/matlab_bin_formatter.hpp>
+#include <vsip_csl/output.hpp>
+
+#define DEBUG 0
+
+using namespace vsip;
+using namespace vsip_csl;
+using namespace std;
+
+float           increment(float v)  { return v+1; }
+double          increment(double v) { return v+1; }
+complex<float>  increment(complex<float>  v) { complex<float> i(1.,1.);
+					       return v+i; }
+complex<double> increment(complex<double> v) { complex<double> i(1.,1.);
+                                               return v+i; }
+
+template <typename T>
+void tensor_test(int m, int n, int o, std::ofstream &ofs, char *name)
+{
+  Tensor<T> a(m,n,o);
+  T         value;
+
+  value = 0;
+  for(int i=0;i<m;i++) {
+    for(int j=0;j<n;j++) {
+      for(int k=0;k<o;k++) {
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
+void matrix_test(int m, int n, std::ofstream &ofs, char *name)
+{
+  Matrix<T> a(m,n);
+  T         value;
+
+  value = 0;
+  for(int i=0;i<m;i++) {
+    for(int j=0;j<n;j++) {
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
+void vector_test(int m, std::ofstream &ofs, char *name)
+{
+  Vector<T> a(m);
+  T         value;
+
+  value = 0;
+  for(int i=0;i<m;i++) {
+    value = increment(value);
+    a.put(i,value);
+  }
+
+  // write it out to file
+  ofs << Matlab_bin_formatter<Vector<T> >(a,name);
+}
+
+template <typename T>
+void vector_input_test(int m, std::ifstream &ifs, char *name,Matlab_bin_hdr &h)
+{
+  Vector<T> a(m);
+  T         value,input_value;
+
+  ifs >> Matlab_bin_formatter<Vector<T> >(a,name,h);
+
+  value = 0;
+  for(int i=0;i<m;i++) {
+    value = increment(value);
+    input_value = a.get(i);
+    assert(value == input_value);
+  }
+#if DEBUG == 1
+  cout << a << endl;
+#endif
+
+}
+
+template <typename T>
+void matrix_input_test(int m, int n, std::ifstream &ifs, char *name,
+  Matlab_bin_hdr &h)
+{
+  Matrix<T> a(m,n);
+  T         value,input_value;
+
+  ifs >> Matlab_bin_formatter<Matrix<T> >(a,name,h);
+
+  value = 0;
+  for(int i=0;i<m;i++) {
+    for(int j=0;j<n;j++) {
+      value = increment(value);
+      input_value = a.get(i,j);
+    }
+  }
+#if DEBUG == 1
+  cout << a << endl;
+#endif
+
+}
+
+template <typename T>
+void tensor_input_test(int m, int n, int o, std::ifstream &ifs, char *name,
+  Matlab_bin_hdr &h)
+{
+  Tensor<T> a(m,n,o);
+  T         value,input_value;
+
+  ifs >> Matlab_bin_formatter<Tensor<T> >(a,name,h);
+
+  value = 0;
+  for(int i=0;i<m;i++) {
+    for(int j=0;j<n;j++) {
+      for(int k=0;k<o;k++) {
+        value = increment(value);
+        input_value = a.get(i,j,k);
+      }
+    }
+  }
+#if DEBUG == 1
+  cout << a << endl;
+#endif
+
+}
+
+int main()
+{
+
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
+  {
+    Matlab_bin_hdr h;
+
+    std::ifstream ifs("temp.mat");
+    ifs >> h;
+    vector_input_test<float>                (5,ifs,"float_vector",h);
+    vector_input_test<double>               (5,ifs,"double_vector",h);
+    vector_input_test<complex<float> >      (5,ifs,"float_vector",h);
+    vector_input_test<complex<double> >     (5,ifs,"double_vector",h);
+
+    matrix_input_test<float>                (2,3,ifs,"float_matrix",h);
+    matrix_input_test<double>               (2,3,ifs,"double_matrix",h);
+    matrix_input_test<complex<float> >      (2,3,ifs,"cplx_float_matrix",h);
+    matrix_input_test<complex<double> >     (2,3,ifs,"cplx_double_matrix",h);
+
+    tensor_input_test<float>                (3,2,3,ifs,"float_tensor",h);
+    tensor_input_test<double>               (3,2,3,ifs,"double_tensor",h);
+    tensor_input_test<complex<float> >      (3,2,3,ifs,"cplx_float_tensor",h);
+    tensor_input_test<complex<double> >     (3,2,3,ifs,"cplx_double_tensor",h);
+  }
+
+  return 0;
+}
Index: src/vsip/tensor.hpp
===================================================================
--- src/vsip/tensor.hpp	(revision 144405)
+++ src/vsip/tensor.hpp	(working copy)
@@ -632,6 +632,17 @@
   return Domain<3>(view.size(0), view.size(1), view.size(2));
 }
 
+/// Get the extent of a tensor view, as a Length.
+
+template <typename T,
+	  typename Block>
+inline Length<3>
+extent(const_Tensor<T, Block> v)
+{
+  return Length<3>(v.size(0), v.size(1), v.size(2));
+}
+
+
 } // namespace vsip::impl
 
 } // namespace vsip
Index: src/vsip/impl/layout.hpp
===================================================================
--- src/vsip/impl/layout.hpp	(revision 144405)
+++ src/vsip/impl/layout.hpp	(working copy)
@@ -1089,6 +1089,12 @@
 
   static type offset(type ptr, stride_type stride)
   { return ptr + stride; }
+
+  static T* get_real_ptr(type ptr)
+    { return ptr; }
+  static T* get_imag_ptr(type ptr)
+    { return ptr; }
+
 };
 
 
@@ -1147,6 +1153,12 @@
 
   static type offset(type ptr, stride_type stride)
   { return type(ptr.first + stride, ptr.second + stride); }
+
+  static T* get_real_ptr(type ptr)
+    { return ptr.first; }
+  static T* get_imag_ptr(type ptr)
+    { return ptr.second; }
+
 };
 
 
Index: src/vsip_csl/matlab_bin_formatter.hpp
===================================================================
--- src/vsip_csl/matlab_bin_formatter.hpp	(revision 144405)
+++ src/vsip_csl/matlab_bin_formatter.hpp	(working copy)
@@ -264,6 +264,7 @@
   typedef typename subview::imagview_type i_v;
   vsip::dimension_type v_dim = vsip::impl::Dim_of_view<View>::dim;
   uint16_t endian = mbf.header.endian;
+  bool swap_value;
 
   if(endian == ('I'<<8 | 'M')) swap_value = true;
   else if(endian == ('M'<<8 | 'I')) swap_value = false;
