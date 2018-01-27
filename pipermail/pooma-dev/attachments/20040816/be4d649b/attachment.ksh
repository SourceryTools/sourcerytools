Index: SerialAsync.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Threads/IterateSchedulers/SerialAsync.h,v
retrieving revision 1.11
diff -u -u -r1.11 SerialAsync.h
--- SerialAsync.h	8 Jan 2004 21:45:49 -0000	1.11
+++ SerialAsync.h	16 Aug 2004 19:22:33 -0000
@@ -72,6 +72,7 @@
 #include <stack>
 #include "Pooma/Configuration.h"
 #if POOMA_MPI
+# define MPIPP_H  // prevent lam mpicxx.h from being included
 # include <mpi.h>
 #endif
 #include "Threads/IterateSchedulers/IterateScheduler.h"
@@ -261,7 +262,7 @@
       res = MPI_Testsome(last_used_request+1, requests_m,
 			 &nr_finished, finished, statuses);
     PAssert(res == MPI_SUCCESS || res == MPI_ERR_IN_STATUS);
-    if (nr_finished == MPI_UNDEFINED)
+    if (nr_finished == MPI_UNDEFINED || nr_finished == 0)
       return false;
 
     // release finised requests
@@ -309,10 +310,14 @@
   static bool runSomething(bool mayBlock = true)
   {
     // do work in this order to minimize communication latency:
+    // - process finished messages
     // - issue all messages
     // - do some regular work
     // - wait for messages to complete
 
+    if (waitForSomeRequests(false))
+      return true;
+
     RunnablePtr_t p = NULL;
     if (!workQueueMessages_m.empty()) {
       p = workQueueMessages_m.front();
@@ -619,7 +624,6 @@
       // Record what action that one will take
       // and record its generation number
       SerialAsync::Action act = released_m->act();
-      int generation = released_m->iterate().generation();
 
       // Look at the next iterate.
       ++released_m;
