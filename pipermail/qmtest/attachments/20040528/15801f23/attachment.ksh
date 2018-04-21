2004-05-28  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/qmtest (check_python_version): Clarify error message.

Index: qm/test/qmtest
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/qmtest,v
retrieving revision 1.4.2.2
diff -c -5 -p -r1.4.2.2 qmtest
*** qm/test/qmtest	27 May 2004 19:02:06 -0000	1.4.2.2
--- qm/test/qmtest	28 May 2004 19:23:56 -0000
*************** def check_python_version():
*** 48,61 ****
      if old:
          if len(required_python_version) == 2:
              version = "%d.%d" % required_python_version
          else:
              version = "%d.%d.%d" % required_python_version
!         sys.stderr.write(
!             ("QMTest requires Python %s or later.\n"
!              "Set the QM_PYTHON environment variable to an appropriate "
!              "Python interpreter.\n") % version)
          sys.exit(1)
  
  check_python_version()
  
  ########################################################################
--- 48,59 ----
      if old:
          if len(required_python_version) == 2:
              version = "%d.%d" % required_python_version
          else:
              version = "%d.%d.%d" % required_python_version
!         sys.stderr.write("qmtest: error: QMTest requires Python %s or later.\n"
!                          % version)
          sys.exit(1)
  
  check_python_version()
  
  ########################################################################
