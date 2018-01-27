Index: ../vpp/doc/quickstart/quickstart.xml
===================================================================
--- ../vpp/doc/quickstart/quickstart.xml	(revision 221548)
+++ ../vpp/doc/quickstart/quickstart.xml	(working copy)
@@ -138,7 +138,7 @@
      </varlistentry>
 
      <varlistentry>
-      <term><literal>literal</literal></term>g
+      <term><literal>literal</literal></term>
       <listitem>
        <para>
         Text provided to or received from a computer program.
@@ -736,24 +736,49 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--enable-parallel=mpipro</option></term>
+      <term><option>--enable-parallel</option></term>
       <listitem>
        <para>
-        Use Verari's MPI/Pro.  This option is necessary
-        when using MPI/Pro on the Mercury platform.
+        Search for and use a communications library for support of
+	multi-processor systems for parallel computation.  By default 
+	parallel support will not be included.
        </para>
       </listitem>
      </varlistentry>
 
      <varlistentry>
-      <term><option>--enable-parallel=pas</option></term>
-      <listitem>
+      <term><option>--enable-parallel=<replaceable>lib</replaceable></option>
+      </term><listitem>
        <para>
-        Enable the use of Mercury Parallel Acceleration System (PAS)
-	for parallel services if found.  This option is necessary to
-	use PAS on the Mercury platform, and when using PAS for Linux
-	clusters.  By default PAS support will not be included.
+	Search for and use the parallel communications library 
+	indicated by <replaceable>lib</replaceable>.  Available
+	options are <option>lam</option>, <option>mpich2</option>, 
+	<option>intelmpi</option>, <option>mpipro</option>, 
+	<option>openmpi</option>, and <option>pas</option>.
        </para>
+
+       <para>
+        <option>lam</option> selects the LAM/MPI open-source library.
+       </para>
+       <para>
+        <option>mpich2</option> selects the open-source MPICH2 library.
+       </para>
+       <para>
+        <option>intelmpi</option> selects Intel MPI Library.
+       </para>
+       <para>
+        <option>mpipro</option> selects Verari's MPI/Pro.  This 
+	option is necessary when using MPI/Pro on the Mercury platform.
+       </para>
+       <para>
+        <option>openmpi</option> selects Open MPI library.
+       </para>
+       <para>
+        <option>pas</option> enables the use of Mercury Parallel 
+	Acceleration System (PAS) for parallel services if found.  
+	This option is necessary to use PAS on the Mercury platform, 
+	and when using PAS for Linux clusters.
+       </para>
       </listitem>
      </varlistentry>
 
