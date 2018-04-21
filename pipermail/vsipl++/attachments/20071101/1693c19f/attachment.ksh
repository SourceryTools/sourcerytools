Index: ChangeLog
===================================================================
--- ChangeLog	(revision 186284)
+++ ChangeLog	(working copy)
@@ -1,3 +1,7 @@
+2007-11-01  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip_csl/matlab_bin_formatter.hpp: Fix Wall warnings.
+
 2007-10-31  Brooks Moses  <brooks@codesourcery.com>
 
 	* tests/regressions/matrix_headers.cpp: Define vsip::vsipl object.
Index: src/vsip_csl/matlab_bin_formatter.hpp
===================================================================
--- src/vsip_csl/matlab_bin_formatter.hpp	(revision 186199)
+++ src/vsip_csl/matlab_bin_formatter.hpp	(working copy)
@@ -250,7 +250,7 @@
 
   // read header
   is.read(reinterpret_cast<char*>(&m_hdr),sizeof(m_hdr));
-  if(is.gcount() < sizeof(m_hdr))
+  if(is.gcount() < static_cast<std::streamsize>(sizeof(m_hdr)))
     VSIP_IMPL_THROW(std::runtime_error(
       "Matlab_bin_hdr: Unexpected end of file"));
 
@@ -314,7 +314,7 @@
   //  - type of data element (we can only handle miMATRIX),
   //  - overall size of data element.
   is.read(reinterpret_cast<char*>(&temp_element),sizeof(temp_element));
-  if(is.gcount() < sizeof(temp_element))
+  if(is.gcount() < static_cast<std::streamsize>(sizeof(temp_element)))
     VSIP_IMPL_THROW(std::runtime_error(
       "Matlab_view_header(read): Unexpected end of file"));
   matlab::swap<vsip::impl::int32_type> (&(temp_element.type),swap_bytes);
@@ -340,7 +340,7 @@
 
   // 2. Read the array_flags.
   is.read(reinterpret_cast<char*>(&temp_element),sizeof(temp_element));
-  if(is.gcount() < sizeof(temp_element))
+  if(is.gcount() < static_cast<std::streamsize>(sizeof(temp_element)))
     VSIP_IMPL_THROW(std::runtime_error(
       "Matlab_view_header(read): Unexpected end of file"));
   matlab::swap<vsip::impl::int32_type> (&(temp_element.type),swap_bytes);
@@ -364,7 +364,7 @@
     VSIP_IMPL_THROW(std::runtime_error(
       "Length of array flags is too large"));
   is.read(reinterpret_cast<char*>(&array_flags),temp_element.size);
-  if(is.gcount() < temp_element.size)
+  if(is.gcount() < static_cast<std::streamsize>(temp_element.size))
     VSIP_IMPL_THROW(std::runtime_error(
      "Matlab_view_header(read): Unexpected end of file reading array flags"));
   for(index_type i=0;i<temp_element.size/4;i++)
@@ -377,7 +377,7 @@
 
   // 3. Read dimensions.
   is.read(reinterpret_cast<char*>(&temp_element),sizeof(temp_element));
-  if(is.gcount() < sizeof(temp_element))
+  if(is.gcount() < static_cast<std::streamsize>(sizeof(temp_element)))
     VSIP_IMPL_THROW(std::runtime_error(
       "Matlab_view_header(read): Unexpected end of file reading dimensions (1)"));
   matlab::swap<vsip::impl::int32_type> (&(temp_element.type),swap_bytes);
@@ -399,7 +399,7 @@
   }
 
   is.read(reinterpret_cast<char*>(&dims),temp_element.size);
-  if(is.gcount() < temp_element.size)
+  if(is.gcount() < static_cast<std::streamsize>(temp_element.size))
     VSIP_IMPL_THROW(std::runtime_error(
       "Matlab_view_header(read): Unexpected end of file reading dimensions (2)"));
   skip_padding(is, temp_element.size);
@@ -414,7 +414,7 @@
 
   // 4. Read array name.
   is.read(reinterpret_cast<char*>(&temp_element),sizeof(temp_element));
-  if(is.gcount() < sizeof(temp_element))
+  if(is.gcount() < static_cast<std::streamsize>(sizeof(temp_element)))
     VSIP_IMPL_THROW(std::runtime_error(
       "Matlab_view_header(read): Unexpected end of file reading array name (1)"));
   matlab::swap<vsip::impl::int32_type>(&(temp_element.type),swap_bytes);
