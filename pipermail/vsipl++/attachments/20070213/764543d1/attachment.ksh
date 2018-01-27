Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 163132)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -130,68 +130,7 @@
   ctype* W_;
 };
 
-// 1D real -> complex FFT
 
-template <typename T, int A, int E>
-class Fft_impl<1, T, std::complex<T>, A, E>
-  : public fft::backend<1, T, std::complex<T>, A, E>
-{
-  typedef T rtype;
-  typedef std::complex<rtype> ctype;
-  typedef std::pair<rtype*, rtype*> ztype;
-
-public:
-  Fft_impl(Domain<1> const & dom, rtype scale)
-  {
-  }
-
-  virtual bool supports_scale() { return true;}
-  virtual void by_reference(rtype *in, stride_type,
-			    ctype *out, stride_type,
-			    length_type)
-  {
-    // TBD
-  }
-  virtual void by_reference(rtype *, stride_type,
-			    ztype, stride_type,
-			    length_type)
-  {
-  }
-
-};
-
-// 1D complex -> real FFT
-
-template <typename T, int A, int E>
-class Fft_impl<1, std::complex<T>, T, A, E>
-  : public fft::backend<1, std::complex<T>, T, A, E>
-{
-  typedef T rtype;
-  typedef std::complex<rtype> ctype;
-  typedef std::pair<rtype*, rtype*> ztype;
-
-public:
-  Fft_impl(Domain<1> const &dom, rtype scale)
-  {
-    // TBD
-  }
-
-  virtual bool requires_copy(Rt_layout<1> &) { return true;}
-
-  virtual void by_reference(ctype *in, stride_type,
-			    rtype *out, stride_type,
-			    length_type)
-  {
-    // TBD
-  }
-  virtual void by_reference(ztype, stride_type,
-			    rtype *, stride_type,
-			    length_type)
-  {
-  }
-
-};
-
 #define VSIPL_IMPL_PROVIDE(D, I, O, A, E)	                             \
 template <>                                                                  \
 std::auto_ptr<fft::backend<D, I, O, A, E> >	                             \
@@ -201,8 +140,6 @@
     (new Fft_impl<D, I, O, A, E>(dom, scale));                               \
 }
 
-VSIPL_IMPL_PROVIDE(1, float, std::complex<float>, 0, -1)
-VSIPL_IMPL_PROVIDE(1, std::complex<float>, float, 0, 1)
 VSIPL_IMPL_PROVIDE(1, std::complex<float>, std::complex<float>, 0, -1)
 VSIPL_IMPL_PROVIDE(1, std::complex<float>, std::complex<float>, 0, 1)
 
Index: src/vsip/opt/cbe/spu/GNUmakefile.inc.in
===================================================================
--- src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(revision 163132)
+++ src/vsip/opt/cbe/spu/GNUmakefile.inc.in	(working copy)
@@ -34,10 +34,10 @@
 
 CC_SPU := spu-gcc
 CPP_SPU_FLAGS := -I $(CBE_SDK_PREFIX)/sysroot/usr/spu/include -I $(srcdir)/src
-CC_SPU_FLAGS := @CXXFLAGS@
+CC_SPU_FLAGS := 
 LD_SPU_FLAGS := -Wl,-N -L$(CBE_SDK_PREFIX)/sysroot/usr/spu/lib
 CC_EMBED_SPU := ppu-embedspu -m32
-SPU_LIBS := -lalf -lfft
+SPU_LIBS := -lalf
 
 ########################################################################
 # Rules
@@ -45,6 +45,8 @@
 
 all:: $(spe_images)
 
+src/vsip/opt/cbe/spu/alf_fft_c.spe: override SPU_LIBS += -lfft
+
 lib/%.spe: src/vsip/opt/cbe/spu/%.spe
 	cp $< $@
 
Index: ChangeLog
===================================================================
--- ChangeLog	(revision 163132)
+++ ChangeLog	(working copy)
@@ -1,3 +1,9 @@
+2007-02-13  Don McCoy  <don@codesourcery.com>
+	
+	* src/vsip/opt/cbe/ppu/fft.cpp: Removed unimplemented cases.
+	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Adds FFT library
+	  on an as-needed basis, rather than for all kernels.
+
 2007-02-12  Don McCoy  <don@codesourcery.com>
 
 	* src/vsip/opt/cbe/ppu/fft.cpp: Added handlers for 8K point FFTs.
