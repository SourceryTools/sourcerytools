Index: src/vsip/core/fft/util.hpp
===================================================================
--- src/vsip/core/fft/util.hpp	(revision 163256)
+++ src/vsip/core/fft/util.hpp	(working copy)
@@ -30,6 +30,21 @@
 namespace fft
 {
 
+/// Determine whether the FFT size is a power of two.
+inline bool 
+is_power_of_two(unsigned size)
+{
+  return (size & (size - 1)) == 0;
+}
+template <dimension_type D>
+inline bool 
+is_power_of_two(Domain<D> const &dom)
+{
+  for (dimension_type d = 0; d != D; ++d)
+    if (!is_power_of_two(dom[d].size())) return false;
+  return true;
+}
+
 /// Determine the exponent (forward or inverse) of a given Fft
 /// from its parameters.
 template <typename I, typename O, int sD> struct exponent;
Index: src/vsip/core/fft.hpp
===================================================================
--- src/vsip/core/fft.hpp	(revision 163256)
+++ src/vsip/core/fft.hpp	(working copy)
@@ -449,10 +449,11 @@
 class Fftm : public impl::fftm_facade<I, O, impl::fft::LibraryTagList,
 				      1 - A, D, R, N, H> 
 {
-  // The S template parameter in 2D Fft is '0' for column-first
-  // and '1' for row-first transformation. As Fftm's Axis parameter
-  // does the inverse, we use '1 - A' here to be able to share the same
-  // logic underneath.
+  // Fftm and 2D Fft share some of the same underlying logic.  
+  // Unfortunately, the latter uses S where '0' stands for column-first 
+  // and '1' for row-first transformations.  Fftm uses A where '0' means 
+  // by-row and '1' means by-column.  As a result, here we use '1 - A'
+  // in order to be consistent in the base class.
   typedef impl::fftm_facade<I, O, impl::fft::LibraryTagList,
 			    1 - A, D, R, N, H> base;
 public:
Index: src/vsip/opt/ipp/fft.hpp
===================================================================
--- src/vsip/opt/ipp/fft.hpp	(revision 163256)
+++ src/vsip/opt/ipp/fft.hpp	(working copy)
@@ -38,20 +38,6 @@
 namespace ipp
 {
 
-inline bool 
-is_power_of_two(unsigned size)
-{
-  return (size & (size - 1)) == 0;
-}
-template <dimension_type D>
-inline bool 
-is_power_of_two(Domain<D> const &dom)
-{
-  for (dimension_type d = 0; d != D; ++d)
-    if (!is_power_of_two(dom[d].size())) return false;
-  return true;
-}
-
 /// These are the entry points into the IPP FFT bridge.
 template <typename I, dimension_type D, typename S>
 std::auto_ptr<I>
@@ -67,7 +53,7 @@
 				    fft::exponent<I, O, S>::value> >
   create(Domain<D> const &dom, typename Scalar_of<I>::type scale)
   {
-    bool fast = is_power_of_two(dom);
+    bool fast = fft::is_power_of_two(dom);
     return ipp::create<fft::backend<D, I, O,
                        fft::axis<I, O, S>::value,
                        fft::exponent<I, O, S>::value> >
@@ -131,7 +117,7 @@
   static std::auto_ptr<fft::fftm<I, O, A, E> > 
   create(Domain<2> const &dom, typename Scalar_of<I>::type scale)
   {
-    bool fast = ipp::is_power_of_two(dom);
+    bool fast = fft::is_power_of_two(dom);
     return ipp::create<fft::fftm<I, O, A, E> >(dom, scale, fast);
   }
 };
Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 163256)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -35,67 +35,125 @@
 {
 
 template <typename T>
-void 
-fft_8K(std::complex<T>* out, std::complex<T> const* in, 
-  std::complex<T> const* twiddle_factors, length_type length, 
-  T scale, int exponent)
+class Fft_base
 {
-  // Note: the twiddle factors require only 1/4 the memory of the input and 
-  // output arrays.
-  Fft_params fftp;
-  fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
-  fftp.elements = length;
-  fftp.scale = scale;
-  Task_manager *mgr = Task_manager::instance();
-  Task task = mgr->reserve<Fft_tag, void(complex<T>,complex<T>)>(
-    sizeof(Fft_params), sizeof(complex<T>)*(length*5/4), 
-    sizeof(complex<T>)*length);
-  Workblock block = task.create_block();
-  block.set_parameters(fftp);
-  block.add_input(in, length);
-  block.add_input(twiddle_factors, length/4);
-  block.add_output(out, length);
-  task.enqueue(block);
-  task.wait();
-}
+  typedef T rtype;
+  typedef std::complex<rtype> ctype;
 
-template<typename T>
-void
-compute_twiddle_factors(std::complex<T>* twiddle_factors, length_type length)
-{
-  unsigned int i = 0;
-  unsigned int n = length;
-  T* W = reinterpret_cast<T*>(twiddle_factors);
-  W[0] = 1.0f;
-  W[1] = 0.0f;
-  for (i = 1; i < n / 4; ++i) 
+public:
+  Fft_base() {}
+  virtual ~Fft_base() {}
+
+  void 
+  fft_8K(std::complex<T>* out, std::complex<T> const* in, 
+    std::complex<T> const* twiddle_factors, length_type length, 
+    T scale, int exponent)
   {
-    W[2*i] = cos(i * 2*M_PI / n);
-    W[2*(n/4 - i)+1] = -W[2*i];
+    // Note: the twiddle factors require only 1/4 the memory of the input and 
+    // output arrays.
+    Fft_params fftp;
+    fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
+    fftp.elements = length;
+    fftp.scale = scale;
+    Task_manager *mgr = Task_manager::instance();
+    Task task = mgr->reserve<Fft_tag, void(complex<T>,complex<T>)>(
+      sizeof(Fft_params), sizeof(complex<T>)*(length*5/4), 
+      sizeof(complex<T>)*length);
+    Workblock block = task.create_block();
+    block.set_parameters(fftp);
+    block.add_input(in, length);
+    block.add_input(twiddle_factors, length/4);
+    block.add_output(out, length);
+    task.enqueue(block);
+    task.wait();
   }
-}
 
+  void 
+  fftm_8K(std::complex<T>* out, std::complex<T> const* in, 
+    std::complex<T> const* twiddle_factors, 
+    stride_type in_r_stride, stride_type in_c_stride,
+    stride_type out_r_stride, stride_type out_c_stride,
+    length_type rows, length_type cols, 
+    T scale, int exponent, int axis)
+  {
+    // Note: the twiddle factors require only 1/4 the memory of the input and 
+    // output arrays.
+    Fft_params fftp;
+    fftp.direction = (exponent == -1 ? fwd_fft : inv_fft);
+    fftp.elements = cols;
+    fftp.scale = scale;
+    length_type num_ffts = rows;
+    length_type in_stride = in_r_stride;
+    length_type out_stride = out_r_stride;
+    if (axis == 0)
+    {
+      num_ffts = cols;
+      in_stride = in_c_stride;
+      out_stride = out_c_stride;
+      fftp.elements = rows;
+    }
+    Task_manager *mgr = Task_manager::instance();
+    Task task = mgr->reserve<Fft_tag, void(complex<T>,complex<T>)>(
+      sizeof(Fft_params), sizeof(complex<T>)*(fftp.elements*5/4), 
+      sizeof(complex<T>)*fftp.elements);
 
-template <dimension_type D, typename I, typename O, int A, int E> 
+    for (length_type i = 0; i < num_ffts; ++i)
+    {
+      Workblock block = task.create_block();
+      block.set_parameters(fftp);
+      block.add_input(in, fftp.elements);
+      block.add_input(twiddle_factors, fftp.elements/4);
+      block.add_output(out, fftp.elements);
+      task.enqueue(block);
+      in += in_stride;
+      out += out_stride;
+    }
+    task.wait();
+
+  }
+
+  void
+  compute_twiddle_factors(std::complex<T>* twiddle_factors, length_type length)
+  {
+    unsigned int i = 0;
+    unsigned int n = length;
+    T* W = reinterpret_cast<T*>(twiddle_factors);
+    W[0] = 1.0f;
+    W[1] = 0.0f;
+    for (i = 1; i < n / 4; ++i) 
+    {
+      W[2*i] = cos(i * 2*M_PI / n);
+      W[2*(n/4 - i)+1] = -W[2*i];
+    }
+  }
+
+};
+
+
+template <dimension_type D, //< Dimension
+          typename I,       //< Input type
+	  typename O,       //< Output type
+	  int A,            //< Axis
+	  int E>            //< Exponent
 class Fft_impl;
 
 // 1D complex -> complex FFT
 
 template <typename T, int A, int E>
 class Fft_impl<1, std::complex<T>, std::complex<T>, A, E>
-  : public fft::backend<1, std::complex<T>, std::complex<T>, A, E>
-
+    : public fft::backend<1, std::complex<T>, std::complex<T>, A, E>,
+      private Fft_base<T>
 {
   typedef T rtype;
   typedef std::complex<rtype> ctype;
   typedef std::pair<rtype*, rtype*> ztype;
 
 public:
-  Fft_impl(Domain<1> const &dom, rtype scale) VSIP_THROW((std::bad_alloc))
+  Fft_impl(Domain<1> const &dom, rtype scale)
       : scale_(scale),
         W_(alloc_align<ctype>(VSIP_IMPL_ALLOC_ALIGNMENT, dom.size()/4))
   {
-    compute_twiddle_factors(W_, dom.size());
+    this->compute_twiddle_factors(W_, dom.size());
   }
   virtual ~Fft_impl()
   {
@@ -106,7 +164,7 @@
   virtual void in_place(ctype *inout, stride_type stride, length_type length)
   {
     assert(stride == 1);
-    fft_8K<T>(inout, inout, W_, length, this->scale_, E);
+    this->fft_8K(inout, inout, W_, length, this->scale_, E);
   }
   virtual void in_place(ztype, stride_type, length_type)
   {
@@ -117,7 +175,7 @@
   {
     assert(in_stride == 1);
     assert(out_stride == 1);
-    fft_8K<T>(out, in, W_, length, this->scale_, E);
+    this->fft_8K(out, in, W_, length, this->scale_, E);
   }
   virtual void by_reference(ztype, stride_type,
 			    ztype, stride_type,
@@ -131,6 +189,109 @@
 };
 
 
+
+
+template <typename I, //< Input type
+	  typename O, //< Output type
+	  int A,      //< Axis
+	  int E>      //< Exponent
+class Fftm_impl;
+
+// complex -> complex FFTM
+template <typename T, int A, int E>
+class Fftm_impl<std::complex<T>, std::complex<T>, A, E>
+    : public fft::fftm<std::complex<T>, std::complex<T>, A, E>,
+      private Fft_base<T>
+{
+  typedef T rtype;
+  typedef std::complex<rtype> ctype;
+  typedef std::pair<rtype*, rtype*> ztype;
+
+public:
+  Fftm_impl(Domain<2> const &dom, rtype scale)
+      : scale_(scale),
+        fft_length_(A ? dom[1].size() : dom[0].size()),
+        W_(alloc_align<ctype>(VSIP_IMPL_ALLOC_ALIGNMENT, fft_length_/4))
+  {
+    this->size_[0] = dom[0].size();
+    this->size_[1] = dom[1].size();
+    compute_twiddle_factors(W_, this->fft_length_);
+  }
+
+  virtual ~Fftm_impl()
+  {
+    delete(W_);
+  }
+
+
+  virtual void in_place(ctype *inout,
+			stride_type r_stride, stride_type c_stride,
+			length_type rows, length_type cols)
+  {
+    if (A != 0)
+    {
+      assert(rows <= this->size_[0]); // OK if rows are distributed.
+      assert(cols == this->size_[1]); // Columns must be whole.
+      assert(c_stride == 1);
+    }
+    else
+    {
+      assert(rows == this->size_[0]); // Rows must be whole.
+      assert(cols <= this->size_[1]); // OK if columns are distributed.
+      assert(r_stride == 1);
+    }
+    fftm_8K(inout, inout, this->W_, 
+      r_stride, c_stride,
+      r_stride, c_stride,
+      rows, cols,
+      this->scale_, E, A);
+  }
+
+  virtual void in_place(ztype, stride_type, stride_type,
+			length_type, length_type)
+  {
+  }
+
+  virtual void by_reference(ctype *in,
+			    stride_type in_r_stride, stride_type in_c_stride,
+			    ctype *out,
+			    stride_type out_r_stride, stride_type out_c_stride,
+			    length_type rows, length_type cols)
+  {
+    if (A != 0)
+    {
+      assert(rows <= this->size_[0]); // OK if rows are distributed.
+      assert(cols == this->size_[1]); // Columns must be whole.
+      assert(in_c_stride == 1 && out_c_stride == 1);
+    }
+    else
+    {
+      assert(rows == this->size_[0]); // Rows must be whole.
+      assert(cols <= this->size_[1]); // OK if columns are distributed.
+      assert(in_r_stride == 1 && out_r_stride == 1);
+    }
+    fftm_8K(out, in, this->W_, 
+      in_r_stride, in_c_stride,
+      out_r_stride, out_c_stride,
+      rows, cols,
+      this->scale_, E, A);
+  }
+  virtual void by_reference(ztype, stride_type, stride_type,
+			    ztype, stride_type, stride_type,
+			    length_type, length_type)
+  {
+  }
+
+private:
+  rtype scale_;
+  length_type fft_length_;
+  ctype* W_;
+
+  length_type size_[2];
+};
+
+
+
 #define VSIPL_IMPL_PROVIDE(D, I, O, A, E)	                             \
 template <>                                                                  \
 std::auto_ptr<fft::backend<D, I, O, A, E> >	                             \
@@ -145,6 +306,28 @@
 
 #undef VSIPL_IMPL_PROVIDE
 
+#define VSIPL_IMPL_PROVIDE(I, O, A, E)			\
+template <>                                             \
+std::auto_ptr<fft::fftm<I, O, A, E> >			\
+create(Domain<2> const &dom,                            \
+       vsip::impl::Scalar_of<I>::type scale)		\
+{                                                       \
+  return std::auto_ptr<fft::fftm<I, O, A, E> >          \
+    (new Fftm_impl<I, O, A, E>(dom, scale));            \
+}
+
+//VSIPL_IMPL_PROVIDE(float, std::complex<float>, 0, -1)
+//VSIPL_IMPL_PROVIDE(float, std::complex<float>, 1, -1)
+//VSIPL_IMPL_PROVIDE(std::complex<float>, float, 0, 1)
+//VSIPL_IMPL_PROVIDE(std::complex<float>, float, 1, 1)
+VSIPL_IMPL_PROVIDE(std::complex<float>, std::complex<float>, 0, -1)
+VSIPL_IMPL_PROVIDE(std::complex<float>, std::complex<float>, 1, -1)
+VSIPL_IMPL_PROVIDE(std::complex<float>, std::complex<float>, 0, 1)
+VSIPL_IMPL_PROVIDE(std::complex<float>, std::complex<float>, 1, 1)
+
+#undef VSIPL_IMPL_PROVIDE
+
+
 } // namespace vsip::impl::cbe
 } // namespace vsip::impl
 } // namespace vsip
Index: src/vsip/opt/cbe/ppu/fft.hpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.hpp	(revision 163256)
+++ src/vsip/opt/cbe/ppu/fft.hpp	(working copy)
@@ -95,11 +95,10 @@
   static bool const ct_valid = true;
   static bool rt_valid(Domain<D> const &dom) 
   { 
-    unsigned int log2_size = static_cast<unsigned int>(log2(dom.size()));
     return
       (dom.size() >= MIN_FFT_1D_SIZE) &&
       (dom.size() <= MAX_FFT_1D_SIZE) &&
-      (dom.size() == static_cast<unsigned int>(1 << log2_size));
+      (fft::is_power_of_two(dom));
   }
   static std::auto_ptr<backend<D, I, O,
  			       axis<I, O, S>::value,
@@ -126,7 +125,14 @@
 struct evaluator<I, O, A, E, R, N, Cbe_sdk_tag>
 {
   static bool const ct_valid = true;
-  static bool rt_valid(Domain<2> const &/*dom*/) { return true;}
+  static bool rt_valid(Domain<2> const &dom) 
+  { 
+    length_type size = A ? dom[1].size() : dom[0].size();
+    return
+      (size >= MIN_FFT_1D_SIZE) &&
+      (size <= MAX_FFT_1D_SIZE) &&
+      (fft::is_power_of_two(size));
+  }
   static std::auto_ptr<fft::fftm<I, O, A, E> > 
   create(Domain<2> const &dom, typename impl::Scalar_of<I>::type scale)
   {
