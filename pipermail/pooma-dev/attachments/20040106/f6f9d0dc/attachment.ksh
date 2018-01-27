? LINUXgcc
? msg.06Jan.13.9.patch
? tests/LINUXgcc
Index: Messaging.cmpl.cpp
===================================================================
RCS file: /home/pooma/Repository/r2/src/Tulip/Messaging.cmpl.cpp,v
retrieving revision 1.8
diff -c -p -r1.8 Messaging.cmpl.cpp
*** Messaging.cmpl.cpp	2 Jan 2004 11:53:14 -0000	1.8
--- Messaging.cmpl.cpp	6 Jan 2004 21:52:35 -0000
***************
*** 32,37 ****
--- 32,38 ----
  
  // include files
  
+ #include "Pooma/Pooma.h"
  #include "Tulip/Messaging.h"
  
  #include "Tulip/CollectFromContexts.h"
