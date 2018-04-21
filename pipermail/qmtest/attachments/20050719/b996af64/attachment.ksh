2005-07-19  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/doc/reference.xml: Provide example of SetUp and CleanUp
	methods for resources.

Index: qm/test/doc/reference.xml
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/doc/reference.xml,v
retrieving revision 1.38
diff -c -5 -p -r1.38 reference.xml
*** qm/test/doc/reference.xml	23 Jun 2005 14:07:31 -0000	1.38
--- qm/test/doc/reference.xml	19 Jul 2005 22:37:29 -0000
***************
*** 2337,2368 ****
   <section id="sec-writing-resource-classes">
    <title>Writing Resource Classes</title>
  
    <para>Writing resource classes is similar to writing test classes.
    The requirements are the same except that, instead of a
!   <function>Run</function> function, you must provide two functions
!   named <function>SetUp</function> and
!   <function>CleanUp</function>. The <function>SetUp</function>
!   function must have the same signature as a test classs
!   <function>Run</function>.  The <function>CleanUp</function>
!   function is similar, but does not take a
    <parameter>context</parameter> parameter.</para>
  
!   <para>The setup function may add additional properties to the
!   context.  These properties will be visible only to tests that
!   require this resource.  To add a context property, use Python's
!   dictionary assignment syntax.</para>
! 
!   <para>Below is an example of setup and cleanup functions for a
!   resource which calls <function>create_my_resource</function> and
!   <function>destroy_my_resource</function> to do the work of creating
!   and destroying the resource.  The resource is identified by a
!   string handle, which is inserted into the context under the name
!   <literal>Resource.handle</literal>, where it may be accessed by
!   tests.  Context property names should always have the form
!   <literal>Class.name</literal> so that there is no risk of collision
!   between properties created by different resource classes.</para>
  
   </section> <!-- sec-writing-resource-classes -->
  
   <section id="sec-ref-writing-database-classes">
    <title>Writing Database Classes</title>
--- 2337,2385 ----
   <section id="sec-writing-resource-classes">
    <title>Writing Resource Classes</title>
  
    <para>Writing resource classes is similar to writing test classes.
    The requirements are the same except that, instead of a
!   <function>Run</function> method, you must provide two methods named
!   <function>SetUp</function> and <function>CleanUp</function>. The
!   <function>SetUp</function> method must have the same signature as a
!   test classs <function>Run</function>.  The
!   <function>CleanUp</function> method is similar, but does not take a
    <parameter>context</parameter> parameter.</para>
  
!   <para>The <function>SetUp</function> method may add additional
!   properties to the context by assigning to its
!   <parameter>context</parameter> parameter.  These additional
!   properties will be visible only to tests that require this
!   resource.</para>
! 
!   <para>The example below shows the <function>SetUp</function> and
!   <function>CleanUp</function> from the standard QMTest
!   <classname>TempDirectoryResource</classname> class.  This resource
!   creates a temporary directory for use by the tests that depend on
!   the resource.  The <function>SetUp</function> method creates the
!   temporary directory and records the path to the temporary directory
!   in the context so that tests know where to find the directory.  The
!   <function>CleanUp</function> method removes the temporary directory.
!   <programlisting> 
! <![CDATA[ 
!     def SetUp(self, context, result):
! 
!         # Create a temporary directory.
!         self.__dir = qm.temporary_directory.TemporaryDirectory()
!         # Provide dependent tests with the path to the new directory.
!         context["TemporaryDirectoryResource.temp_dir_path"] 
!           = self.__dir.GetPath()
!     
! 
!     def CleanUp(self, result):
! 
!         # Remove the temporary directory.
!         del self.__dir
! ]]>
!   </programlisting>
!   </para>
  
   </section> <!-- sec-writing-resource-classes -->
  
   <section id="sec-ref-writing-database-classes">
    <title>Writing Database Classes</title>
