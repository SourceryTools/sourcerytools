Index: src/vsip/impl/fftw3/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fftw3/fft.hpp,v
retrieving revision 1.3
diff -u -r1.3 fft.hpp
--- src/vsip/impl/fftw3/fft.hpp	12 May 2006 00:28:24 -0000	1.3
+++ src/vsip/impl/fftw3/fft.hpp	13 May 2006 23:16:14 -0000
@@ -29,14 +29,14 @@
 namespace fftw3
 {
 
-template <typename I, dimension_type D, typename S>
+template <typename I, dimension_type D>
 std::auto_ptr<I>
-create(Domain<D> const &dom, S scale);
+create(Domain<D> const &dom, unsigned);
 
 #define VSIP_IMPL_FFT_DECL(D,I,O,A,E)                          \
 template <>                                                    \
 std::auto_ptr<fft::backend<D,I,O,A,E> >                        \
-create(Domain<D> const &, impl::Scalar_of<I>::type);
+create(Domain<D> const &, unsigned);
 
 #define VSIP_IMPL_FFT_DECL_T(T)				       \
 VSIP_IMPL_FFT_DECL(1, T, std::complex<T>, 0, -1)               \
@@ -74,7 +74,7 @@
 #define VSIP_IMPL_FFT_DECL(I,O,A,E)                            \
 template <>                                                    \
 std::auto_ptr<fft::fftm<I,O,A,E> >                             \
-create(Domain<2> const &, impl::Scalar_of<I>::type);
+create(Domain<2> const &, unsigned);
 
 #define VSIP_IMPL_FFT_DECL_T(T)				       \
 VSIP_IMPL_FFT_DECL(T, std::complex<T>, 0, -1)                  \
@@ -108,11 +108,11 @@
 struct evaluator<D, I, O, S, R, N, Fftw3_tag>
 {
   static bool const ct_valid = true;
-  static bool rt_valid(Domain<D> const &dom) { return true;}
+  static bool rt_valid(Domain<D> const &) { return true;}
   static std::auto_ptr<backend<D, I, O,
  			       axis<I, O, S>::value,
  			       exponent<I, O, S>::value> >
-  create(Domain<D> const &dom, typename Scalar_of<I>::type scale)
+  create(Domain<D> const &dom, typename Scalar_of<I>::type)
   {
     return fftw3::create<backend<D, I, O,
       axis<I, O, S>::value,
Index: src/vsip/impl/ipp/fft.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/ipp/fft.hpp,v
retrieving revision 1.1
diff -u -r1.1 fft.hpp
--- src/vsip/impl/ipp/fft.hpp	6 May 2006 22:09:27 -0000	1.1
+++ src/vsip/impl/ipp/fft.hpp	13 May 2006 23:16:14 -0000
@@ -53,7 +53,7 @@
 struct evaluator
 {
   static bool const ct_valid = true;
-  static bool rt_valid(Domain<D> const &dom) { return true;}
+  static bool rt_valid(Domain<D> const &) { return true;}
   static std::auto_ptr<fft::backend<D, I, O,
 				    fft::axis<I, O, S>::value,
 				    fft::exponent<I, O, S>::value> >
Index: src/vsip/impl/sal/fft.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/sal/fft.cpp,v
retrieving revision 1.5
diff -u -r1.5 fft.cpp
--- src/vsip/impl/sal/fft.cpp	13 May 2006 20:43:26 -0000	1.5
+++ src/vsip/impl/sal/fft.cpp	13 May 2006 23:16:15 -0000
@@ -687,11 +687,11 @@
     rop(in, out);
     T s = this->scale_ * 0.5;
     if (!almost_equal(s, T(1.)))
-      scale(out, this->size_[0]/2 + 1, s);
+      scale(out, size/2 + 1, s);
   }
-  virtual void by_reference(T *in, stride_type in_stride,
-			    std::pair<T *, T *> out, stride_type out_stride,
-			    length_type size)
+  virtual void by_reference(T *, stride_type,
+			    std::pair<T *, T *>, stride_type,
+			    length_type)
   {
   }
 };
@@ -721,7 +721,7 @@
   }
   // SAL requires the input to be packed, so we will modify the input
   // before passing it along.
-  virtual bool requires_copy(Rt_layout<1> &rtl_in) { return true;}
+  virtual bool requires_copy(Rt_layout<1> &) { return true;}
 
   virtual void by_reference(ctype *in, stride_type in_stride,
 			    T *out, stride_type out_stride,
@@ -733,9 +733,9 @@
     if (!almost_equal(this->scale_, T(1.)))
       scale(out, this->size_[0], this->scale_);
   }
-  virtual void by_reference(ztype in, stride_type in_stride,
-			    T *out, stride_type out_stride,
-			    length_type size)
+  virtual void by_reference(ztype, stride_type,
+			    T *, stride_type,
+			    length_type)
   {
   }
 };
@@ -903,10 +903,10 @@
  	  scale(out + i * out_r_stride, cols / 2 + 1, s);
     }
   }
-  virtual void by_reference(T *in, stride_type in_r_stride, stride_type in_c_stride,
-			    std::pair<T *, T *> out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(T *, stride_type, stride_type,
+			    std::pair<T *, T *>,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
 };
@@ -938,7 +938,7 @@
   }
   // SAL requires the input to be packed, so we will modify the input
   // before passing it along.
-  virtual bool requires_copy(Rt_layout<2> &rtl_in) { return true;}
+  virtual bool requires_copy(Rt_layout<2> &) { return true;}
 
   virtual void by_reference(std::complex<T> *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
@@ -964,11 +964,11 @@
 	  scale(out + i * out_r_stride, cols, this->scale_);
     }
   }
-  virtual void by_reference(std::pair<T *, T *> in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    T *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(std::pair<T *, T *>,
+			    stride_type, stride_type,
+			    T *,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
   }
 };
@@ -1017,14 +1017,11 @@
       // Scaling done in ropm()
     }
   }
-  virtual void by_reference(T *in, stride_type in_r_stride, stride_type in_c_stride,
-			    std::pair<T *, T *> out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(T *, stride_type, stride_type,
+			    std::pair<T *, T *>,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
-    if (A != 0) assert(in_c_stride == 1);
-    else assert(in_r_stride == 1);
-    assert(rows == this->size_[0] && cols == this->size_[1]);
   }
 };
 
@@ -1053,7 +1050,7 @@
   }
   // SAL requires the input to be packed, so we will modify the input
   // before passing it along.
-  virtual bool requires_copy(Rt_layout<2> &rtl_in) { return true;}
+  virtual bool requires_copy(Rt_layout<2> &) { return true;}
   virtual void by_reference(std::complex<T> *in,
 			    stride_type in_r_stride, stride_type in_c_stride,
 			    T *out,
@@ -1074,13 +1071,12 @@
       // Scaling done in ropm()
     }
   }
-  virtual void by_reference(std::pair<T *, T *> in,
-			    stride_type in_r_stride, stride_type in_c_stride,
-			    T *out,
-			    stride_type out_r_stride, stride_type out_c_stride,
-			    length_type rows, length_type cols)
+  virtual void by_reference(std::pair<T *, T *>,
+			    stride_type, stride_type,
+			    T *,
+			    stride_type, stride_type,
+			    length_type, length_type)
   {
-    assert(rows == this->size_[0] && cols == this->size_[1]);
   }
 };
 
