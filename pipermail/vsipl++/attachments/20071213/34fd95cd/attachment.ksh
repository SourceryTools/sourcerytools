Index: ChangeLog
===================================================================
--- ChangeLog	(revision 188744)
+++ ChangeLog	(working copy)
@@ -1,5 +1,44 @@
 2007-12-05  Jules Bergmann  <jules@codesourcery.com>
 
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
+
+2007-12-05  Jules Bergmann  <jules@codesourcery.com>
+
 	* src/vsip/core/signal/types.hpp (support_min_zeropad): New
 	  support_region_type.
 	* src/vsip_csl/img/impl/sfilt_common.hpp: New file, common
