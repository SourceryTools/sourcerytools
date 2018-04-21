Index: RemoteProxy.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Tulip/RemoteProxy.h,v
retrieving revision 1.15
diff -c -p -r1.15 RemoteProxy.h
*** RemoteProxy.h	23 Jan 2003 20:04:39 -0000	1.15
--- RemoteProxy.h	25 Apr 2003 18:18:32 -0000
*************** public:
*** 133,139 ****
  
        RemoteProxyBase::ready_m = false;
  
!       Pooma::indexHandler()->request(owningContext, tag, receive, this);
  
        while (!RemoteProxyBase::ready_m)
        {
--- 133,140 ----
  
        RemoteProxyBase::ready_m = false;
  
!       Pooma::indexHandler()->request(owningContext, tag,
! 				     This_t::receive, this);
  
        while (!RemoteProxyBase::ready_m)
        {
Index: SendReceive.h
===================================================================
RCS file: /home/pooma/Repository/r2/src/Tulip/SendReceive.h,v
retrieving revision 1.10
diff -c -p -r1.10 SendReceive.h
*** SendReceive.h	5 Mar 2002 16:14:38 -0000	1.10
--- SendReceive.h	25 Apr 2003 18:18:32 -0000
*************** public:
*** 200,206 ****
    {
      ready_m = false;
      Pooma::remoteEngineHandler()->request(fromContext_m, tag_m,
! 					  handle, this);
  
      while (!ready_m)
      {
--- 200,206 ----
    {
      ready_m = false;
      Pooma::remoteEngineHandler()->request(fromContext_m, tag_m,
! 					  This_t::handle, this);
  
      while (!ready_m)
      {
*************** public:
*** 213,219 ****
    virtual void run()
    {
      Pooma::remoteEngineHandler()->request(fromContext_m, tag_m,
! 					  apply, view_m);
    }
  
  #endif
--- 213,219 ----
    virtual void run()
    {
      Pooma::remoteEngineHandler()->request(fromContext_m, tag_m,
! 					  This_t::apply, view_m);
    }
  
  #endif
