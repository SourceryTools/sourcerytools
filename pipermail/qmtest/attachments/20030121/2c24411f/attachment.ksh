Index: target.py
===================================================================
RCS file: /home/qm/Repository/qm/qm/test/target.py,v
retrieving revision 1.14
diff -c -p -r1.14 target.py
*** target.py	25 Nov 2002 10:24:05 -0000	1.14
--- target.py	21 Jan 2003 19:27:22 -0000
***************
*** 7,13 ****
  # Contents:
  #   QMTest Target class.
  #
! # Copyright (c) 2001, 2002 by CodeSourcery, LLC.  All rights reserved. 
  #
  # For license terms see the file COPYING.
  #
--- 7,13 ----
  # Contents:
  #   QMTest Target class.
  #
! # Copyright (c) 2001, 2002, 2003 by CodeSourcery, LLC.  All rights reserved. 
  #
  # For license terms see the file COPYING.
  #
*************** class Target(qm.extension.Extension):
*** 229,236 ****
          execution."""
  
          # Record the target in the result.
!         if self.GetName() != "local":
!             result[Result.TARGET] = self.GetName()
          # Put the result into the response queue.
          self.__response_queue.put(result)
              
--- 229,235 ----
          execution."""
  
          # Record the target in the result.
!         result[Result.TARGET] = self.GetName()
          # Put the result into the response queue.
          self.__response_queue.put(result)
              
