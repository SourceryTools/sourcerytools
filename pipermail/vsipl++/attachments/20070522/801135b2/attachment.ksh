Index: tests/ref-impl/test.hpp
===================================================================
--- tests/ref-impl/test.hpp	(revision 171918)
+++ tests/ref-impl/test.hpp	(working copy)
@@ -135,7 +135,7 @@
 equal (vsip::scalar_f const& operand1,
        vsip::scalar_f const& operand2) VSIP_NOTHROW
 {
-  return std::abs (operand1 - operand2) < static_cast<vsip::scalar_f>(1.0e-4);
+  return vsip::mag (operand1 - operand2) < static_cast<vsip::scalar_f>(1.0e-4);
 }
 
 /* Consider any two complex point numbers to be equal if their
@@ -146,7 +146,7 @@
 equal (vsip::cscalar_f const& operand1,
        vsip::cscalar_f const& operand2) VSIP_NOTHROW
 {
-  return std::abs (operand1 - operand2) < static_cast<vsip::scalar_f>(1.0e-6);
+  return vsip::mag (operand1 - operand2) < static_cast<vsip::scalar_f>(1.0e-6);
 }
 
 template <typename T,
Index: benchmarks/GNUmakefile.inc.in
===================================================================
--- benchmarks/GNUmakefile.inc.in	(revision 171918)
+++ benchmarks/GNUmakefile.inc.in	(working copy)
@@ -80,7 +80,7 @@
 	rm -f $(benchmarks_targets) $(benchmarks_static_targets)
 
 # Install benchmark source code and executables
-install:: 
+install:: benchmarks
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/lapack
 	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/benchmarks/ipp
