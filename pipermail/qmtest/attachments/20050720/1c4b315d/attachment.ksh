2005-07-20  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/doc/reference.xml: Add documentation about
	prerequisites.

Index: qm/test/doc/reference.xml
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/doc/reference.xml,v
retrieving revision 1.39
diff -c -5 -p -r1.39 reference.xml
*** qm/test/doc/reference.xml	19 Jul 2005 22:38:39 -0000	1.39
--- qm/test/doc/reference.xml	20 Jul 2005 14:35:23 -0000
***************
*** 93,107 ****
     other.  For example, the arguments to
     <classname>command.ExecTest</classname> indicate which application to
     run, what command-line arguments to provide, and what output is
     expected.</para>
  
!    <para>Sometimes, it may be pointless to run one test unless another
!    test has passed.  Therefore, each test can have a set of associated
!    <firstterm>prerequisite tests</firstterm>.  If the prerequisite
!    tests did not pass, &qmtest; will not run the test that depends
!    upon them.</para>
  
    </section> <!-- sec-tests -->
  
    <section id="sec-resources">
     <title>Resources</title>
--- 93,148 ----
     other.  For example, the arguments to
     <classname>command.ExecTest</classname> indicate which application to
     run, what command-line arguments to provide, and what output is
     expected.</para>
  
!    <section id="sec-tests-prereqs">
!     <title>Prerequisite Tests</title>
!  
!     <para>QMTest can avoid running one test (a &quot;dependent
!     test&quot;) when some other test (a &quot;prerequisite test&quot;)
!     has a particular outcome.</para>
! 
!     <para>Suppose that you have a test database with a very simple
!     test that can be run very quickly, and a very complex test that
!     takes hours to run. You know that if the simple test fails, then
!     there is no chance that the complex test will pass.  In that case,
!     you could make the simple test a prerequisite of the complex
!     test. Then, when you run both tests, QMTest will run the simple
!     test first. If it fails, the complex test will not be run at
!     all.</para>
! 
!     <para>Alternatively, suppose that you have a very comprehensive
!     test that tests ten features of your software. You also have ten
!     separate tests, one for each feature. The comprehensive test can
!     be run in one minute; runnning the separate tests takes two
!     minutes each. So, you want to run the comprehensive test first; if
!     it passes, there is no need to run the individual tests.  However,
!     if the comprehensive test fails, you may want to run the single
!     tests to isolate the problem. In this case, each of the simple
!     tests would have the comprehensive test as a prerequisite,
!     indicating that the simple test should be run only if the
!     comprehensive test fails.</para>
! 
!     <para>If you explicitly run just the dependent test, QMTest will
!     not run the prerequisite test automatically. In other words,
!     prerequisites are an optimization; when running both the
!     prerequisite and the dependent test, QMTest will run them in the
!     order you've implied, and can omit the dependent test if it is not
!     useful. But, QMTest will not automatically force you to run the
!     prerequisite tests when you only want to run the dependent
!     test.</para> 
! 
!     <para>Because prerequisite tests are not run unless you ask for
!     them, the dependent test should not depend in any way on the
!     prerequisite test.  Otherwise, users will see different test
!     outcomes when they run the dependent test by itself.  In other
!     words, each test should stand alone; the order in which tests are
!     run should not affect their outcomes.
!   </para>
! 
!    </section>
  
    </section> <!-- sec-tests -->
  
    <section id="sec-resources">
     <title>Resources</title>
***************
*** 440,451 ****
       &qmtest; may schedule the tests on multiple targets; in that case,
       the resource is set up and cleaned up once on each target.</para>
      </listitem>
     </orderedlist>
  
!    <para>In some cases, a test, resource setup function, or resource
!    cleanup function is not executed:</para>
  
     <itemizedlist>
      <listitem>
       <para>A test specifies for each of its prerequisite tests an
       expected outcome.  If the prerequisite is included in the test run
--- 481,493 ----
       &qmtest; may schedule the tests on multiple targets; in that case,
       the resource is set up and cleaned up once on each target.</para>
      </listitem>
     </orderedlist>
  
!    <para>In the following cases, a test or resource will not be
!    executed, even though it is included in the set of tests enumerated
!    above:</para>
  
     <itemizedlist>
      <listitem>
       <para>A test specifies for each of its prerequisite tests an
       expected outcome.  If the prerequisite is included in the test run
