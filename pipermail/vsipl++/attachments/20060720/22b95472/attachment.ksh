Index: doc/tutorial/src/matlab_text_formatter.cpp
===================================================================
--- doc/tutorial/src/matlab_text_formatter.cpp	(revision 0)
+++ doc/tutorial/src/matlab_text_formatter.cpp	(revision 0)
@@ -0,0 +1,16 @@
+
+  std::ofstream ofs("temp.m");      // opens a file
+
+  Matrix<float> a(3,3);
+  for(index_type i=0;i<3;i++)
+    for(index_type j=0;j<3;j++)
+      a.put(i,j,(float)(i*3+j));    // put dummy data in matrix
+
+  ofs << Matlab_text_formatter<Matrix<float> >(a,"a");
+
+  Vector<float> v(3);
+  for(index_type i=0;i<3;i++)
+    v.put(i,(float)(i));            // put dummy data in vector
+
+  ofs << Matlab_text_formatter<Vector<float> >(v,"v");
+
Index: doc/tutorial/src/matlab_bin_formatter.cpp
===================================================================
--- doc/tutorial/src/matlab_bin_formatter.cpp	(revision 0)
+++ doc/tutorial/src/matlab_bin_formatter.cpp	(revision 0)
@@ -0,0 +1,34 @@
+
+  {
+    std::ofstream ofs("temp.mat");
+
+    Matrix<float> a(3,3);
+    for(index_type i=0;i<3;i++)
+      for(index_type j=0;j<3;j++)
+        a.put(i,j,(float)(i*3+j));    // put dummy data in matrix
+
+    // write header
+    ofs << Matlab_bin_hdr("example");
+  
+    // output matrix
+    ofs << Matlab_bin_formatter<Matrix<float> >(a,"a");
+  
+    Vector<float> v(3);
+    for(index_type i=0;i<3;i++)
+      v.put(i,(float)(i));            // put dummy data in vector
+
+    ofs << Matlab_bin_formatter<Vector<float> >(v,"v");
+
+  }
+  // we are finished writing to file, we can now try and read
+  {
+    std::ifstream ifs("temp.mat");
+    Matlab_bin_hder h;
+    Matrix<float> a(3,3);
+    Vector<float> v(3);
+    
+    ifs >> h;
+    ifs >> Matlab_bin_formattoer<Matrix<float> >(a,"a",h);
+    ifs >> Matlab_bin_formattoer<Vector<float> >(v,"v",h);
+  }
+
Index: doc/tutorial/api.xml
===================================================================
--- doc/tutorial/api.xml	(revision 144405)
+++ doc/tutorial/api.xml	(working copy)
@@ -162,4 +162,76 @@
         <remark>Talk about convolution, fft, ...</remark>
     </para>
   </section>-->
+  <section id="matlabio"><title>Matlab IO</title>
+    <para>
+      VSIPL++ provides a few structs to allow input and output Matlab of files.
+      There are two main modes. One is using text mode, the other is binary. The
+      interface is very simmilar for both modes. This interface allows for vector,
+      matrix, and tensor IO operations. Reading of binary files requires knowledge
+      of the views in the file.
+    </para> 
+    <section><title>Output to Matlab .m file</title>
+      <para>
+        In order to output views to Matlab .m files, you must use the
+        Matlab_text_formatter wrapper struct. This struct has an <![CDATA[<<]]> operator to work
+        with output streams. The basic idea is you open a text file using the
+        std::ofstream class. You can then use the <![CDATA[<<]]> operator on the open stream. The
+        Matlab_text_formatter acts as a wrapper template struct that accepts a view and
+        a name to use in the Matlab file. Here is a short example that shows how to use
+        the Matlab_text_formatter:
+      </para>
+    </section>
+    <programlisting><xi:include href="src/matlab_text_formatter.cpp" parse="text"/></programlisting>
+    <para>
+      After this file is created, it is now possible to run this file inside a Matlab
+      console window and load matrix a and vector v.
+    </para>
+    <section><title>Matlab .mat file Interface</title>
+      <para>
+        This format allows for both input and output operations. In order to read or
+        write Matlab binary .mat files the struct Matlab_bin_formatter is provided. This
+        struct has both the <![CDATA[<<]]> operator and <![CDATA[>>]]> operator for streams.
+	Matlab binary files are a little different than Matlab text files. Matlab binary files
+	contain a header section which has a short description of the contents of the file as
+        well as an endian indicator. Another thing to keep in mind when dealing with Matlab files
+	is the data format. In order to read in views stored in a Matlab file, the data types
+	must match along with the dimensions and dimension sizes.  If there is a mismatch between
+	any of these parameters an exception is thrown.  Endian swapping is handled automatically
+	if needed.
+      </para>
+      <section><title>Outputing to Matlab .mat File</title>
+        <para>
+          The use of this struct is very simmilar to the use of the text formatter
+          struct. In order to produce a valid Matlab binary file, a header must be the
+          first thing that you output to the file. After the header is outputed to the
+          file, the views can then follow. Matlab binary files are simmilar to tar files
+          because views can be appended to the file at any time without changing the
+          header information. The header does not contain any information of how many
+          views are in the file or what types of views they are. It is up to you to
+          figure this out. This interface is a low level interface and a higher level
+          interface can be written to make reading in of Matlab files simpler if the
+          views are not known beforehand.
+        </para>
+	<para>
+	  In order to output to a Matlab .mat file, you must use the <![CDATA[<<]]> operator.
+	  The Matlab_bin_formatter struct takes in the view and view name as arguments.
+	</para>
+      </section>
+      <section><title>Reading a Matlab .mat File</title>
+        <para>
+	  In order to read from a Matlab .mat file, you must the >> operator. Make sure
+	  that the views are read in the same that they were written out. An exception will be
+	  thrown if there is a mismatch in dimensions, sizes, or even class type.
+	  The Matlab_bin_formatter struct takes in the view and view name as arguments.
+	</para>
+      </section>
+      <section><title>Example</title>
+	<para>
+         Here is an example of writing and reading a vector and matrix from a Matlab
+         file
+        </para>
+        <programlisting><xi:include href="src/matlab_bin_formatter.cpp" parse="text"/></programlisting>
+      </section>
+    </section>
+  </section>
 </chapter>
