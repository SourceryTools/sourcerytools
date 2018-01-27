Index: ChangeLog
===================================================================
--- ChangeLog	(revision 171526)
+++ ChangeLog	(working copy)
@@ -1,5 +1,13 @@
 2007-05-17  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/simd/simd.hpp (load_unaligned): New function for SIMD
+	  traits.
+	* src/vsip/opt/simd/expr_iterator.hpp: pre-load scalar value into SIMD
+	  register.
+	* tests/simd.cpp: Add tests for load_unaligned.
+
+2007-05-17  Jules Bergmann  <jules@codesourcery.com>
+
 	* scripts/char.db: Document requirements.  Add cell and patience
 	  requirements.
 	* scripts/char.pl: Allow multiple -db options.
Index: src/vsip/opt/simd/simd.hpp
===================================================================
--- src/vsip/opt/simd/simd.hpp	(revision 171526)
+++ src/vsip/opt/simd/simd.hpp	(working copy)
@@ -140,6 +140,9 @@
   static simd_type load(value_type const* addr)
   { return *addr; }
 
+  static simd_type load_unaligned(value_type const* addr)
+  { return *addr; }
+
   static simd_type load_scalar(value_type value)
   { return value; }
 
@@ -251,6 +254,14 @@
   static simd_type load(value_type const* addr)
   { return vec_ld(0, (value_type*)addr); }
 
+  static simd_type load_unaligned(value_type const* addr)
+  {
+    simd_type              x0 = vec_ld(0,  (value_type*)addr);
+    simd_type              x1 = vec_ld(16, (value_type*)addr);
+    __vector unsigned char sh = vec_lvsl(0, (value_type*)addr);
+    return vec_perm(x0, x1, sh);
+  }
+
   static simd_type load_scalar(value_type value)
   {
     union
@@ -331,6 +342,14 @@
   static simd_type load(value_type const* addr)
   { return vec_ld(0, (short*)addr); }
 
+  static simd_type load_unaligned(value_type const* addr)
+  {
+    simd_type              x0 = vec_ld(0,  (value_type*)addr);
+    simd_type              x1 = vec_ld(16, (value_type*)addr);
+    __vector unsigned char sh = vec_lvsl(0, (value_type*)addr);
+    return vec_perm(x0, x1, sh);
+  }
+
   static simd_type load_scalar(value_type value)
   {
     union
@@ -414,6 +433,14 @@
   static simd_type load(value_type const* addr)
   { return vec_ld(0, (value_type*)addr); }
 
+  static simd_type load_unaligned(value_type const* addr)
+  {
+    simd_type              x0 = vec_ld(0,  (value_type*)addr);
+    simd_type              x1 = vec_ld(16, (value_type*)addr);
+    __vector unsigned char sh = vec_lvsl(0, (value_type*)addr);
+    return vec_perm(x0, x1, sh);
+  }
+
   static simd_type load_scalar(value_type value)
   {
     union
@@ -496,6 +523,14 @@
   static simd_type load(value_type const* addr)
   { return vec_ld(0, (value_type*)addr); }
 
+  static simd_type load_unaligned(value_type const* addr)
+  {
+    simd_type              x0 = vec_ld(0,  (value_type*)addr);
+    simd_type              x1 = vec_ld(16, (value_type*)addr);
+    __vector unsigned char sh = vec_lvsl(0, (value_type*)addr);
+    return vec_perm(x0, x1, sh);
+  }
+
   static simd_type load_scalar(value_type value)
   {
 #if __ghs__
@@ -608,6 +643,9 @@
   static simd_type load(value_type* addr)
   { return _mm_load_si128((simd_type*)addr); }
 
+  static simd_type load_unaligned(value_type* addr)
+  { return _mm_loadu_si128((simd_type*)addr); }
+
   static simd_type load_scalar(value_type value)
   { return _mm_set_epi8(0, 0, 0, 0, 0, 0, 0, 0,
 			0, 0, 0, 0, 0, 0, 0, value); }
@@ -665,6 +703,9 @@
   static simd_type load(value_type const* addr)
   { return _mm_load_si128((simd_type*)addr); }
 
+  static simd_type load_unaligned(value_type const* addr)
+  { return _mm_loadu_si128((simd_type*)addr); }
+
   static simd_type load_scalar(value_type value)
   { return _mm_set_epi16(0, 0, 0, 0, 0, 0, 0, value); }
 
@@ -763,6 +804,9 @@
   static simd_type load(value_type const* addr)
   { return _mm_load_si128((simd_type*)addr); }
 
+  static simd_type load_unaligned(value_type const* addr)
+  { return _mm_loadu_si128((simd_type*)addr); }
+
   static simd_type load_scalar(value_type value)
   { return _mm_set_epi32(0, 0, 0, value); }
 
@@ -847,6 +891,9 @@
   static simd_type load(value_type const* addr)
   { return _mm_load_ps(addr); }
 
+  static simd_type load_unaligned(value_type const* addr)
+  { return _mm_loadu_ps(addr); }
+
   static simd_type load_scalar(value_type value)
   { return _mm_load_ss(&value); }
 
@@ -942,6 +989,9 @@
   static simd_type load(value_type const* addr)
   { return _mm_load_pd(addr); }
 
+  static simd_type load_unaligned(value_type const* addr)
+  { return _mm_loadu_pd(addr); }
+
   static simd_type load_scalar(value_type value)
   { return _mm_load_sd(&value); }
 
Index: src/vsip/opt/simd/expr_iterator.hpp
===================================================================
--- src/vsip/opt/simd/expr_iterator.hpp	(revision 171526)
+++ src/vsip/opt/simd/expr_iterator.hpp	(working copy)
@@ -301,15 +301,17 @@
   typedef T value_type;
   typedef typename Simd_traits<value_type>::simd_type simd_type;
 
-  Proxy(value_type value) : value_(value) {}
+  Proxy(value_type value)
+    : simd_value_(Simd_traits<value_type>::load_scalar_all(value))
+  {}
 
   simd_type load() const 
-  { return Simd_traits<value_type>::load_scalar_all(value_);}
+  { return simd_value_; }
 
   void increment(length_type) {}
 
 private:
-  value_type value_;
+  simd_type simd_value_;
 };
 
 // Proxy for unary expressions.
Index: tests/simd.cpp
===================================================================
--- tests/simd.cpp	(revision 171526)
+++ tests/simd.cpp	(working copy)
@@ -128,6 +128,47 @@
 
 template <typename T>
 void
+test_load_unaligned()
+{
+  typedef vsip::impl::simd::Simd_traits<T> traits;
+
+  typedef typename traits::value_type value_type;
+  typedef typename traits::simd_type  simd_type;
+
+  length_type const vec_size = traits::vec_size;
+
+  union
+  {
+    simd_type  vec;
+    value_type val[vec_size];
+  } u;
+
+  value_type val[8*vec_size];
+
+  for (index_type i=0; i<8*vec_size; ++i)
+    val[i] = value_type(i);
+
+  for (index_type i=0; i<1*vec_size; ++i)
+  {
+    u.vec = traits::load_unaligned(val + i);
+
+#if VERBOSE
+    std::cout << "unaligned load offset: " << i << std::endl;
+    for (index_type j=0; j<vec_size; ++j)
+      std::cout  << "  - " << j << ": "
+		 << u.val[j] << "  " << value_type(i+j)
+		 << std::endl;
+#endif
+
+    for (index_type j=0; j<vec_size; ++j)
+      test_assert(u.val[j] == value_type(i+j));
+  }
+}
+
+
+
+template <typename T>
+void
 test_interleaved(Bool_type<true>)
 {
   typedef vsip::impl::simd::Simd_traits<T> traits;
@@ -362,6 +403,7 @@
   test_zero<T>();
   test_load_scalar<T>();
   test_load_scalar_all<T>();
+  test_load_unaligned<T>();
   test_add<T>();
 
   test_interleaved<T>(Bool_type<do_complex>());
