2005-07-21  Mark Mitchell  <mark@codesourcery.com>

	* qm/test/classes/dg_test.py (DGTest._RunDGToolPortion): Fix
	typo.

Index: qm/test/classes/dg_test.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/classes/dg_test.py,v
retrieving revision 1.6
diff -c -5 -p -r1.6 dg_test.py
*** qm/test/classes/dg_test.py	31 Mar 2004 10:32:45 -0000	1.6
--- qm/test/classes/dg_test.py	21 Jul 2005 08:46:11 -0000
*************** class DGTest(DejaGNUTest):
*** 212,222 ****
  
          # Remove tool-specific messages that can be safely ignored.
          output = self._PruneOutput(output)
              
          # Remove leading blank lines.
!         output = re.sub(r"\n+", "", output)
          # If there's any output left, the test fails.
          message = self._name + " (test for excess errors)"
          if self._excess_errors_expected:
              expected = self.FAIL
          else:
--- 212,222 ----
  
          # Remove tool-specific messages that can be safely ignored.
          output = self._PruneOutput(output)
              
          # Remove leading blank lines.
!         output = re.sub(r"^\n+", "", output)
          # If there's any output left, the test fails.
          message = self._name + " (test for excess errors)"
          if self._excess_errors_expected:
              expected = self.FAIL
          else:
