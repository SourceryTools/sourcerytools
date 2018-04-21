? png.cpp
? png.hpp
Index: GNUmakefile.inc.in
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip_csl/GNUmakefile.inc.in,v
retrieving revision 1.1
diff -u -r1.1 GNUmakefile.inc.in
--- GNUmakefile.inc.in	8 May 2006 03:49:44 -0000	1.1
+++ GNUmakefile.inc.in	19 May 2006 15:59:06 -0000
@@ -12,13 +12,59 @@
 # Variables
 ########################################################################
 
+VSIP_CSL_HAVE_PNG	:= @HAVE_PNG_H@
+
+src_vsip_csl_CXXINCLUDES := -I$(srcdir)/src
+src_vsip_csl_CXXFLAGS := $(src_vsip_csl_CXXINCLUDES)
+
+ifdef VSIP_CSL_HAVE_PNG
+src_vsip_csl_cxx_sources += $(srcdir)/src/vsip_csl/png.cpp
+endif
+src_vsip_csl_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT),\
+                              $(src_vsip_csl_cxx_sources))
+cxx_sources += $(src_vsip_csl_cxx_sources)
+
+libs += lib/libvsip_csl.a
+VSIP_CSL_HAVE_PNG	:= @HAVE_PNG_H@
+
+src_vsip_csl_CXXINCLUDES := -I$(srcdir)/src
+src_vsip_csl_CXXFLAGS := $(src_vsip_csl_CXXINCLUDES)
+
+all:: lib/libvsip_csl.a
+
+clean::
+	rm -f lib/libvsip_csl.a
+
+lib/libvsip_csl.a: $(src_vsip_csl_cxx_objects)
+	$(AR) rc $@ $^ || rm -f $@
+
+ifdef VSIP_CSL_HAVE_PNG
+src_vsip_csl_cxx_sources += $(srcdir)/src/vsip_csl/png.cpp
+	$(INSTALL) -d $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) lib/libvsip_csl.a $(DESTDIR)$(libdir)/libvsip_csl$(suffix).a
+endif
+src_vsip_csl_cxx_objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT),\
+                              $(src_vsip_csl_cxx_sources))
+cxx_sources += $(src_vsip_csl_cxx_sources)
+
+libs += lib/libvsip_csl.a
 
 ########################################################################
 # Rules
 ########################################################################
 
+all:: lib/libvsip_csl.a
+
+clean::
+	rm -f lib/libvsip_csl.a
+
+lib/libvsip_csl.a: $(src_vsip_csl_cxx_objects)
+	$(AR) rc $@ $^ || rm -f $@
+
 # Install the extensions library and its header files.
 install:: 
+	$(INSTALL) -d $(DESTDIR)$(libdir)
+	$(INSTALL_DATA) lib/libvsip_csl.a $(DESTDIR)$(libdir)/libvsip_csl$(suffix).a
 	$(INSTALL) -d $(DESTDIR)$(includedir)/vsip_csl
 	for header in $(wildcard $(srcdir)/src/vsip_csl/*.hpp); do \
           $(INSTALL_DATA) $$header $(DESTDIR)$(includedir)/vsip_csl; \
Index: matlabformatter.hpp
===================================================================
RCS file: matlabformatter.hpp
diff -N matlabformatter.hpp
--- /dev/null	1 Jan 1970 00:00:00 -0000
+++ matlabformatter.hpp	19 May 2006 15:59:06 -0000
@@ -0,0 +1,103 @@
+#ifndef VSIP_CSL_MATLABFORMATTER_HPP
+#define VSIP_CSL_MATLABFORMATTER_HPP
+
+#include <string>
+#include <vsip/support.hpp>
+
+/* Declare our classes that we will use for formatting stream output. Note that
+ * these classes will only work for ascii streams
+ */
+namespace vsip_csl
+{
+
+  //template <template <typename,typename> class ViewT>
+  template <typename ViewT>
+  class MatlabFormatter
+  {
+    /* Constructors */
+    public:
+      MatlabFormatter(ViewT v) : v_(v), view_name_("a")  {}
+      MatlabFormatter(ViewT v,std::string name) 
+        : v_(v), view_name_(name)  {}
+
+
+      MatlabFormatter() {}
+
+      ~MatlabFormatter() {}
+
+    /* Accessors */
+    public:
+      ViewT get_view() { return v_; }
+      std::string get_name() { return view_name_; }
+
+
+
+    /* Private data */
+    private:
+      ViewT v_;
+      std::string view_name_;
+  };
+
+
+} // namespace vsip_csl
+
+
+/****************************************************************************
+ * Definitions
+ ***************************************************************************/
+
+namespace vsip_csl
+{
+
+/// Write a matrix to a stream using a MatlabFormatter
+
+template <typename T,
+          typename Block0>
+inline
+std::ostream&
+operator<<(
+  std::ostream&		                          out,
+  MatlabFormatter<vsip::Matrix<T,Block0> >        mf)
+  VSIP_NOTHROW
+
+{
+  vsip::Matrix<T,Block0> v = mf.get_view();
+
+  out << mf.get_name() << " = " << std::endl;
+  out << "[" << std::endl;
+  for(vsip::index_type i=0;i<v.size(0);i++) {
+    out << "[ ";
+    for(vsip::index_type j=0;j<v.size(1);j++)
+      out << v.get(i,j) << " ";
+    out << "]" << std::endl;
+  }
+  out << "];" << std::endl;
+
+  return out;
+}
+
+/// Write a vector to a stream using a MatlabFormatter
+
+template <typename T,
+          typename Block0>
+inline
+std::ostream&
+operator<<(
+  std::ostream&		               out,
+  MatlabFormatter<vsip::Vector<T,Block0> > const& mf)
+  VSIP_NOTHROW
+
+{
+  vsip::Vector<T,Block0>  v = mf.get_view();
+
+  out << mf.get_name() << " = " << std::endl;
+  out << "[" << std::endl;
+  for(vsip::index_type i=0;i<v.size(0);i++) {
+    out << v.get(i) << " ";
+  }
+  out << "]" << std::endl;
+}
+
+} // namespace vsip_csl
+
+#endif // VSIP_CSL_MATLABFORMATTER_HPP
Index: output.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip_csl/output.hpp,v
retrieving revision 1.1
diff -u -r1.1 output.hpp
--- output.hpp	3 Apr 2006 19:17:15 -0000	1.1
+++ output.hpp	19 May 2006 15:59:06 -0000
@@ -17,9 +17,6 @@
 #include <vsip/domain.hpp>
 #include <vsip/vector.hpp>
 #include <vsip/matrix.hpp>
-#include <vsip/impl/point.hpp>
-
-
 
 namespace vsip_csl
 {
@@ -75,7 +72,6 @@
 }
 
 
-
 /// Write a vector to a stream.
 
 template <typename T,
@@ -116,26 +112,8 @@
 }
 
 
-/// Write a point to a stream.
 
-template <vsip::dimension_type Dim>
-inline
-std::ostream&
-operator<<(
-  std::ostream&		        out,
-  vsip::impl::Point<Dim> const& idx)
-  VSIP_NOTHROW
-{
-  out << "(";
-  for (vsip::dimension_type d=0; d<Dim; ++d)
-  {
-    if (d > 0) out << ", ";
-    out << idx[d];
-  }
-  out << ")";
-  return out;
-}
 
-} // namespace vsip
+} // namespace vsip_csl
 
 #endif // VSIP_CSL_OUTPUT_HPP
