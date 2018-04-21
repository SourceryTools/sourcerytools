Index: ChangeLog
===================================================================
--- ChangeLog	(revision 189309)
+++ ChangeLog	(working copy)
@@ -1,3 +1,48 @@
+2007-12-13  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/simd/simd_spu.hpp: Fix all sorts of typos!
+	
+2007-12-13  Jules Bergmann  <jules@codesourcery.com>
+
+	Fix error_db to work with unsigned and low-precision types.
+	* src/vsip/core/lvalue_proxy.hpp (Is_lvalue_proxy_type): New trait to
+	  identify an lvalue proxy type.
+	* src/vsip/core/fns_elementwise.hpp: Handle scalar lvalue proxy types.
+	* src/vsip/core/view_cast.hpp: Fix typo in expr block type.
+	* src/vsip/core/fns_scalar.hpp (magsq): avoid using abs (inefficient
+	  for complex, overload ambiguous for integers).
+	* tests/vsip_csl/error_db.cpp: New file, unit test for error_db.
+	
+	* src/vsip/opt/cbe/pwarp_params.h: New file, pwarp ALF kernel
+	  parameter block.
+	* src/vsip/opt/cbe/ppu/pwarp.hpp: New file, pwarp ALF kernel bridge.
+	* src/vsip/opt/cbe/ppu/pwarp.cpp: New file, pwarp ALF kernel bridge.
+	* src/vsip/opt/cbe/spu/alf_pwarp_ub.cpp: New file, pwarp ALF kernel.
+	* src/vsip/opt/cbe/ppu/task_manager.hpp: Add tag for uchar pwarp
+	  ALF task.
+	* src/vsip/opt/cbe/spu/GNUmakefile.inc.in: Add rules for C++ ALF
+	  kernels.
+	* configure.ac (CXX_SPU): Define it.
+	* src/vsip/opt/simd/simd.hpp: Add AltiVec unsigned short and
+	  unsigned int support.  Split common traits into ...
+	* src/vsip/opt/simd/simd_common.hpp: ... here, new file.
+	* src/vsip/opt/simd/simd_spu.hpp: New file, SPU SIMD traits.
+	* src/vsip/GNUmakefile.inc.in (src_vsip_cxx_sources): Add pwarp.cpp
+	* src/vsip_csl/error_db.hpp: Cast difference to double, allows
+	  error_db to be used for unsigned types.
+	* src/vsip_csl/img/impl/pwarp_common.hpp: New file, common bits
+	  for perspective warp.
+	* src/vsip_csl/img/impl/pwarp_cbe.hpp: New file, CBE pwarp BE.
+	* src/vsip_csl/img/impl/pwarp_gen.hpp: New file, generic pwarp BE.
+	* src/vsip_csl/img/impl/pwarp_simd.hpp: New file, SIMD pwarp BE.
+	* src/vsip_csl/img/perspective_warp.hpp: New file, API and functional
+	  pwarp impl.
+	* src/vsip_csl/ref_pwarp.hp: New file, reference version of pwarp
+	  algorithm.
+	* tests/vsip_csl/pwarp.cpp: New file, unit test for pwarp.
+	* benchmarks/pwarp.cpp: New file, benchmark for pwarp.
+	* src/vsip_csl/GNUmakefile.inc.in: Install vsip_csl/img/impl/ headers.
+
 2007-12-13  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* src/vsip_csl/GNUmakefile.inc.in: Install vsip_csl/img/ headers.
Index: src/vsip/opt/simd/simd_spu.hpp
===================================================================
--- src/vsip/opt/simd/simd_spu.hpp	(revision 189310)
+++ src/vsip/opt/simd/simd_spu.hpp	(working copy)
@@ -90,7 +90,7 @@
     // Language Extentions for CBEA, section 1.8
     simd_type x0 = *((simd_type*)addr);
     simd_type x1 = *((simd_type*)addr + 1);
-    unsigned int shift = (unsigned int)(ptr) & 15;
+    unsigned int shift = (unsigned int)(addr) & 15;
     return spu_or(spu_slqwbyte(x0, shift),
 		  spu_rlmaskqwbyte(x1, (signed)(shift - 16)));
   }
@@ -105,7 +105,7 @@
   }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
-  { return spu_shuffle(x0, x1, spu_and(c, 0x1F)); }
+  { return spu_shuffle(x0, x1, spu_and(sh, 0x1F)); }
 
   static simd_type load_scalar(value_type value)
   { return (simd_type)si_from_float(value); }
@@ -191,7 +191,7 @@
     // Language Extentions for CBEA, section 1.8
     simd_type x0 = *((simd_type*)addr);
     simd_type x1 = *((simd_type*)addr + 1);
-    unsigned int shift = (unsigned int)(ptr) & 15;
+    unsigned int shift = (unsigned int)(addr) & 15;
     return spu_or(spu_slqwbyte(x0, shift),
 		  spu_rlmaskqwbyte(x1, (signed)(shift - 16)));
   }
@@ -206,10 +206,10 @@
   }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
-  { return spu_shuffle(x0, x1, spu_and(c, 0x1F)); }
+  { return spu_shuffle(x0, x1, spu_and(sh, 0x1F)); }
 
   static simd_type load_scalar(value_type value)
-  { return si_from_short(value); }
+  { return (simd_type)si_from_short(value); }
 
   static simd_type load_scalar_all(value_type value)
   { return spu_splats(value); }
@@ -331,7 +331,7 @@
     // Language Extentions for CBEA, section 1.8
     simd_type x0 = *((simd_type*)addr);
     simd_type x1 = *((simd_type*)addr + 1);
-    unsigned int shift = (unsigned int)(ptr) & 15;
+    unsigned int shift = (unsigned int)(addr) & 15;
     return spu_or(spu_slqwbyte(x0, shift),
 		  spu_rlmaskqwbyte(x1, (signed)(shift - 16)));
   }
@@ -346,10 +346,10 @@
   }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
-  { return spu_shuffle(x0, x1, spu_and(c, 0x1F)); }
+  { return spu_shuffle(x0, x1, spu_and(sh, 0x1F)); }
 
   static simd_type load_scalar(value_type value)
-  { return si_from_ushort(value); }
+  { return (simd_type)si_from_ushort(value); }
 
   static simd_type load_scalar_all(value_type value)
   { return spu_splats(value); }
@@ -392,44 +392,56 @@
   }
 
   static simd_type add(simd_type const& v1, simd_type const& v2)
-  { return vec_add(v1, v2); }
+  { return spu_add(v1, v2); }
 
   static simd_type sub(simd_type const& v1, simd_type const& v2)
-  { return vec_sub(v1, v2); }
+  { return spu_sub(v1, v2); }
 
   static simd_type fma(simd_type const& v1, simd_type const& v2,
 		       simd_type const& v3)
-  { return vec_mladd(v1, v2, v3); }
+  { // return vec_mladd(v1, v2, v3);
+    typedef __vector signed short ss_simd_type;
+    typedef __vector signed int   si_simd_type;
+    return ((simd_type)
+	    (spu_shuffle(
+	       spu_madd(
+		 (ss_simd_type)(spu_rl((vec_uint4)(v1), -16)),
+		 (ss_simd_type)(spu_rl((vec_uint4)(v2), -16)),
+		 (si_simd_type)(spu_rl((vec_uint4)(v3), -16))),
+	       spu_madd((ss_simd_type)v1, (ss_simd_type)v2,
+			spu_extend((ss_simd_type)v3)),
+	       ((perm_simd_type){ 2,  3, 18, 19,  6,  7, 22, 23,
+		                 10, 11, 26, 27, 14, 15, 30, 31}))));
+  }
 
+
   static simd_type band(simd_type const& v1, simd_type const& v2)
-  { return vec_and(v1, v2); }
+  { return spu_and(v1, v2); }
 
-  static simd_type band(bool_simd_type const& v1, simd_type const& v2)
-  { return vec_and(v1, v2); }
-
   static simd_type bor(simd_type const& v1, simd_type const& v2)
-  { return vec_or(v1, v2); }
+  { return spu_or(v1, v2); }
 
   static simd_type bxor(simd_type const& v1, simd_type const& v2)
-  { return vec_xor(v1, v2); }
+  { return spu_xor(v1, v2); }
 
   static simd_type bnot(simd_type const& v1)
-  { return vec_nor(v1, v1); }
+  { return spu_nor(v1, v1); }
 
   static bool_simd_type gt(simd_type const& v1, simd_type const& v2)
-  { return vec_cmpgt(v1, v2); }
+  { return spu_cmpgt(v1, v2); }
 
   static bool_simd_type lt(simd_type const& v1, simd_type const& v2)
-  { return vec_cmplt(v1, v2); }
+  { return spu_cmpgt(v2, v1); }
 
   static bool_simd_type ge(simd_type const& v1, simd_type const& v2)
-  { return vec_cmplt(v2, v1); }
+  {
+    bool_simd_type is_lt = spu_cmpgt(v2, v1);
+    return spu_nand(is_lt, is_lt);
+  }
 
   static bool_simd_type le(simd_type const& v1, simd_type const& v2)
-  { return vec_cmpgt(v2, v1); }
+  { return ge(v2, v1); }
 
-#endif
-
   static pack_simd_type pack(simd_type const& v1, simd_type const& v2)
   { // return vec_pack(v1, v2);
     static __vector unsigned char shuf = 
@@ -482,7 +494,7 @@
     // Language Extentions for CBEA, section 1.8
     simd_type x0 = *((simd_type*)addr);
     simd_type x1 = *((simd_type*)addr + 1);
-    unsigned int shift = (unsigned int)(ptr) & 15;
+    unsigned int shift = (unsigned int)(addr) & 15;
     return spu_or(spu_slqwbyte(x0, shift),
 		  spu_rlmaskqwbyte(x1, (signed)(shift - 16)));
   }
@@ -497,10 +509,10 @@
   }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
-  { return spu_shuffle(x0, x1, spu_and(c, 0x1F)); }
+  { return spu_shuffle(x0, x1, spu_and(sh, 0x1F)); }
 
   static simd_type load_scalar(value_type value)
-  { return si_from_int(value); }
+  { return (simd_type)si_from_int(value); }
 
   static simd_type load_scalar_all(value_type value)
   { return spu_splats(value); }
@@ -610,7 +622,7 @@
     // Language Extentions for CBEA, section 1.8
     simd_type x0 = *((simd_type*)addr);
     simd_type x1 = *((simd_type*)addr + 1);
-    unsigned int shift = (unsigned int)(ptr) & 15;
+    unsigned int shift = (unsigned int)(addr) & 15;
     return spu_or(spu_slqwbyte(x0, shift),
 		  spu_rlmaskqwbyte(x1, (signed)(shift - 16)));
   }
@@ -625,10 +637,10 @@
   }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
-  { return spu_shuffle(x0, x1, spu_and(c, 0x1F)); }
+  { return spu_shuffle(x0, x1, spu_and(sh, 0x1F)); }
 
   static simd_type load_scalar(value_type value)
-  { return si_from_uint(value); }
+  { return (simd_type)si_from_uint(value); }
 
   static simd_type load_scalar_all(value_type value)
   { return spu_splats(value); }
@@ -748,7 +760,7 @@
     // Language Extentions for CBEA, section 1.8
     simd_type x0 = *((simd_type*)addr);
     simd_type x1 = *((simd_type*)addr + 1);
-    unsigned int shift = (unsigned int)(ptr) & 15;
+    unsigned int shift = (unsigned int)(addr) & 15;
     return spu_or(spu_slqwbyte(x0, shift),
 		  spu_rlmaskqwbyte(x1, (signed)(shift - 16)));
   }
@@ -763,7 +775,7 @@
   }
 
   static simd_type perm(simd_type x0, simd_type x1, perm_simd_type sh)
-  { return spu_shuffle(x0, x1, spu_and(c, 0x1F)); }
+  { return spu_shuffle(x0, x1, spu_and(sh, 0x1F)); }
 
   static simd_type load_scalar(value_type value)
   { return (simd_type)si_from_float(value); }
@@ -828,8 +840,7 @@
   }
 
   static simd_type mag(simd_type const& v1)
-  { return ((simd_type)(spu_rlmask(spu_sl((uint_simd_type)(a), 1), -1))); }
-  // { uint_simd_type mask = si_from_uint(0x7fff); return spu_and(mask, v1); }
+  { return ((simd_type)(spu_rlmask(spu_sl((uint_simd_type)(v1), 1), -1))); }
 
   static simd_type min(simd_type const& v1, simd_type const& v2)
   { return spu_sel(v1, v2, spu_cmpgt(v1, v2)); }
