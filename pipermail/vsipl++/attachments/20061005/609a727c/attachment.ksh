Index: ChangeLog
===================================================================
--- ChangeLog	(revision 150673)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2006-10-05  Jules Bergmann  <jules@codesourcery.com>
+
+	* doc/quickstart/quickstart.xml: Document --with-{obj,lib,exe}-ext
+	  options.
+
 2006-10-04  Stefan Seefeld  <stefan@codesourcery.com>
 
 	* configure.ac: Add --enable-scripting, --with-python, and 
Index: doc/quickstart/quickstart.xml
===================================================================
--- doc/quickstart/quickstart.xml	(revision 150673)
+++ doc/quickstart/quickstart.xml	(working copy)
@@ -1111,6 +1111,44 @@
       </listitem>
      </varlistentry>
 
+     <varlistentry>
+      <term><option>--with-obj-ext=<replaceable>EXT</replaceable></option></term>
+      <listitem>
+       <para>
+        Specify <replaceable>EXT</replaceable> as the file extension
+        to be used for object files.  Object files will be
+        named <filename>file.<replaceable>EXT</replaceable></filename>.
+	Default value is determined heuristically by configure.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><option>--with-lib-ext=<replaceable>EXT</replaceable></option></term>
+      <listitem>
+       <para>
+        Specify <replaceable>EXT</replaceable> as the file extension
+        to be used for library archive files.  Library archive files will be
+        named <filename>file.<replaceable>EXT</replaceable></filename>.
+	Default value is determined heuristically by configure.
+       </para>
+      </listitem>
+     </varlistentry>
+
+     <varlistentry>
+      <term><option>--with-exe-ext=<replaceable>EXT</replaceable></option></term>
+      <listitem>
+       <para>
+        Specify <replaceable>EXT</replaceable> as the file extension
+        to be used for executable files.  Executable files will be
+        named <filename>file<replaceable>EXT</replaceable></filename>.
+	Unlike <option>--with-obj-ext</option> and
+	<option>--with-lib-ext</option>, no &quot;.&quot; is implied.
+	Default value is determined heuristically by configure.
+       </para>
+      </listitem>
+     </varlistentry>
+
     </variablelist>
    </para>
 
