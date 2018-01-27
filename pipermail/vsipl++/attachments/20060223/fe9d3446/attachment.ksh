
Index: src/vsip/profile.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/profile.cpp,v
retrieving revision 1.9
diff -c -p -r1.9 profile.cpp
*** src/vsip/profile.cpp	21 Sep 2005 07:39:52 -0000	1.9
--- src/vsip/profile.cpp	23 Feb 2006 08:01:34 -0000
*************** Profiler::event(char* name, int value, i
*** 150,164 ****
      accum_type::iterator pos = accum_.find(name);
      if (pos == accum_.end())
      {
!       accum_.insert(std::make_pair(name, Accum_entry(0, 0)));
        pos = accum_.find(name);
      }
  
      if (open_id == 0)
!       pos->second.total -= stamp;
      else
      {
!       pos->second.total += stamp;
        pos->second.count++;
      }
      return 0;
--- 150,164 ----
      accum_type::iterator pos = accum_.find(name);
      if (pos == accum_.end())
      {
!       accum_.insert(std::make_pair(name, Accum_entry(TP::zero(), 0)));
        pos = accum_.find(name);
      }
  
      if (open_id == 0)
!       pos->second.total = TP::sub(pos->second.total, stamp);
      else
      {
!       pos->second.total = TP::add(pos->second.total, stamp);
        pos->second.count++;
      }
      return 0;
*************** Profiler::dump(char* filename, char /*mo
*** 178,191 ****
    {
      file << "# mode: pm_trace" << std::endl;
      file << "# timer: " << TP::name() << std::endl;
!     file << "# clocks_per_sec: " << TP::clocks_per_sec << std::endl;
      typedef trace_type::iterator iterator;
  
      for (iterator cur = data_.begin(); cur != data_.end(); ++cur)
      {
        file << (*cur).idx << ":"
  	   << (*cur).name << ":"
! 	   << (*cur).stamp << ":"
  	   << (*cur).end << ":"
  	   << (*cur).value << std::endl;
      }
--- 178,192 ----
    {
      file << "# mode: pm_trace" << std::endl;
      file << "# timer: " << TP::name() << std::endl;
!     file << "# clocks_per_sec: " << TP::ticks(TP::clocks_per_sec) << std::endl;
! 
      typedef trace_type::iterator iterator;
  
      for (iterator cur = data_.begin(); cur != data_.end(); ++cur)
      {
        file << (*cur).idx << ":"
  	   << (*cur).name << ":"
! 	   << TP::ticks((*cur).stamp) << ":"
  	   << (*cur).end << ":"
  	   << (*cur).value << std::endl;
      }
*************** Profiler::dump(char* filename, char /*mo
*** 195,210 ****
    {
      file << "# mode: pm_accum" << std::endl;
      file << "# timer: " << TP::name() << std::endl;
!     file << "# clocks_per_sec: " << TP::clocks_per_sec << std::endl;
  
      typedef accum_type::iterator iterator;
  
      for (iterator cur = accum_.begin(); cur != accum_.end(); ++cur)
      {
        file << (*cur).first << ":"
! 	   << (*cur).second.total << ":"
  	   << (*cur).second.count << std::endl;
!       cur->second.total = 0;
        cur->second.count = 0;
      }
      // accum_.clear();
--- 196,211 ----
    {
      file << "# mode: pm_accum" << std::endl;
      file << "# timer: " << TP::name() << std::endl;
!     file << "# clocks_per_sec: " << TP::ticks(TP::clocks_per_sec) << std::endl;
  
      typedef accum_type::iterator iterator;
  
      for (iterator cur = accum_.begin(); cur != accum_.end(); ++cur)
      {
        file << (*cur).first << ":"
! 	   << TP::ticks((*cur).second.total) << ":"
  	   << (*cur).second.count << std::endl;
!       cur->second.total = TP::zero();
        cur->second.count = 0;
      }
      // accum_.clear();
*************** Profiler::dump(char* filename, char /*mo
*** 216,221 ****
--- 217,223 ----
    file.close();
  }
  
+ 
  } // namespace vsip::impl::profile
  } // namespace vsip::impl
  } // namespace vsip
Index: src/vsip/impl/profile.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/profile.hpp,v
retrieving revision 1.11
diff -c -p -r1.11 profile.hpp
*** src/vsip/impl/profile.hpp	22 Dec 2005 01:29:25 -0000	1.11
--- src/vsip/impl/profile.hpp	23 Feb 2006 08:01:34 -0000
*************** struct Posix_time
*** 89,98 ****
--- 89,100 ----
  
    typedef clock_t stamp_type;
    static void sample(stamp_type& time) { time = clock(); }
+   static stamp_type zero() { return stamp_type(); }
    static stamp_type f_clocks_per_sec() { return CLOCKS_PER_SEC; }
    static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
    static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
    static float seconds(stamp_type time) { return (float)time / CLOCKS_PER_SEC; }
+   static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
  
    static stamp_type clocks_per_sec;
  };
*************** struct Posix_real_time
*** 104,114 ****
  {
    static bool const valid = true; 
    static char* name() { return "Posix_real_time"; }
!   static void init() {}
  
    static clockid_t const clock = CLOCK_REALTIME;
    typedef struct timespec stamp_type;
    static void sample(stamp_type& time) { clock_gettime(clock, &time); }
    // static stamp_type clocks_per_sec() { return CLOCKS_PER_SEC; }
    static stamp_type add(stamp_type A, stamp_type B)
    {
--- 106,117 ----
  {
    static bool const valid = true; 
    static char* name() { return "Posix_real_time"; }
!   static void init() { clocks_per_sec.tv_sec = 1; clocks_per_sec.tv_nsec = 0; }
  
    static clockid_t const clock = CLOCK_REALTIME;
    typedef struct timespec stamp_type;
    static void sample(stamp_type& time) { clock_gettime(clock, &time); }
+   static stamp_type zero() { return stamp_type(); }
    // static stamp_type clocks_per_sec() { return CLOCKS_PER_SEC; }
    static stamp_type add(stamp_type A, stamp_type B)
    {
*************** struct Posix_real_time
*** 142,147 ****
--- 145,153 ----
    static float seconds(stamp_type time)
      { return (float)(time.tv_sec) + (float)(time.tv_nsec) / 1e9; }
  
+   static unsigned long ticks(stamp_type time)
+     { return (unsigned long)(time.tv_sec * 1e9) + (unsigned long)time.tv_nsec; }
+ 
    static stamp_type clocks_per_sec;
  };
  #endif // (VSIP_IMPL_PROFILE_TIMER == 2)
*************** struct Pentium_tsc_time
*** 158,166 ****
--- 164,174 ----
    typedef long long stamp_type;
    static void sample(stamp_type& time)
      { __asm__ __volatile__("rdtsc": "=A" (time)); }
+   static stamp_type zero() { return stamp_type(); }
    static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
    static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
    static float seconds(stamp_type time) { return (float)time / (float)clocks_per_sec; }
+   static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
  
    static stamp_type clocks_per_sec;
  };
*************** struct X86_64_tsc_time
*** 179,188 ****
--- 187,198 ----
    static void sample(stamp_type& time)
      { unsigned a, d; __asm__ __volatile__("rdtsc": "=a" (a), "=d" (d));
        time = ((stamp_type)a) | (((stamp_type)d) << 32); }
+   static stamp_type zero() { return stamp_type(); }
    static stamp_type f_clocks_per_sec() { return 3600000000LL; }
    static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
    static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
    static float seconds(stamp_type time) { return (float)time / (float)clocks_per_sec; }
+   static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
  
    static stamp_type clocks_per_sec;
  };
