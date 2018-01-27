Index: src/vsip/opt/profile.hpp
===================================================================
--- src/vsip/opt/profile.hpp	(revision 189528)
+++ src/vsip/opt/profile.hpp	(working copy)
@@ -114,13 +114,15 @@
   static void init() {}
 
   typedef int stamp_type;
+  typedef unsigned long long tick_type;
   static void sample(stamp_type& time) { time = 0; }
   static stamp_type zero() { return stamp_type(); }
   static stamp_type f_clocks_per_sec() { return 1; }
   static stamp_type add(stamp_type , stamp_type) { return 0; }
   static stamp_type sub(stamp_type , stamp_type) { return 0; }
   static float seconds(stamp_type) { return 0.f; }
-  static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static tick_type ticks(stamp_type time) 
+    { return (tick_type)time; }
   static bool is_zero(stamp_type const& stamp)
     { return stamp == 0; }
 
@@ -137,13 +139,16 @@
   static void init() { clocks_per_sec = CLOCKS_PER_SEC; }
 
   typedef clock_t stamp_type;
+  typedef unsigned long long tick_type;
   static void sample(stamp_type& time) { time = clock(); }
   static stamp_type zero() { return stamp_type(); }
-  static stamp_type f_clocks_per_sec() { return CLOCKS_PER_SEC; }
+  static stamp_type f_clocks_per_sec() { return clocks_per_sec; }
   static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
   static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
-  static float seconds(stamp_type time) { return (float)time / CLOCKS_PER_SEC; }
-  static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static float seconds(stamp_type time) 
+    { return (float)time / clocks_per_sec; }
+  static tick_type ticks(stamp_type time) 
+    { return (tick_type)time; }
   static bool is_zero(stamp_type const& stamp)
     { return stamp == stamp_type(); }
 
@@ -161,9 +166,10 @@
 
   static clockid_t const clock = CLOCK_REALTIME;
   typedef struct timespec stamp_type;
+  typedef unsigned long long tick_type;
   static void sample(stamp_type& time) { clock_gettime(clock, &time); }
   static stamp_type zero() { return stamp_type(); }
-  // static stamp_type clocks_per_sec() { return CLOCKS_PER_SEC; }
+
   static stamp_type add(stamp_type A, stamp_type B)
   {
     stamp_type res;
@@ -196,8 +202,11 @@
   static float seconds(stamp_type time)
     { return (float)(time.tv_sec) + (float)(time.tv_nsec) / 1e9; }
 
-  static unsigned long ticks(stamp_type time)
-    { return (unsigned long)(time.tv_sec * 1e9) + (unsigned long)time.tv_nsec; }
+  static tick_type ticks(stamp_type time)
+  { 
+    return (tick_type)(time.tv_sec * 1e9) + 
+      (tick_type)time.tv_nsec; 
+  }
   static bool is_zero(stamp_type const& stamp)
     { return stamp.tv_nsec == 0 && stamp.tv_sec == 0; }
 
@@ -215,13 +224,14 @@
   static void init();
 
   typedef long long stamp_type;
+  typedef unsigned long long tick_type;
   static void sample(stamp_type& time)
     { __asm__ __volatile__("rdtsc": "=A" (time)); }
   static stamp_type zero() { return stamp_type(); }
   static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
   static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
   static float seconds(stamp_type time) { return (float)time / (float)clocks_per_sec; }
-  static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static tick_type ticks(stamp_type time) { return (tick_type)time; }
   static bool is_zero(stamp_type const& stamp)
     { return stamp == stamp_type(); }
 
@@ -239,6 +249,7 @@
   static void init();
 
   typedef unsigned long long stamp_type;
+  typedef unsigned long long tick_type;
   static void sample(stamp_type& time)
     { unsigned a, d; __asm__ __volatile__("rdtsc": "=a" (a), "=d" (d));
       time = ((stamp_type)a) | (((stamp_type)d) << 32); }
@@ -246,7 +257,7 @@
   static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
   static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
   static float seconds(stamp_type time) { return (float)time / (float)clocks_per_sec; }
-  static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static tick_type ticks(stamp_type time) { return (tick_type)time; }
   static bool is_zero(stamp_type const& stamp)
     { return stamp == stamp_type(); }
 
@@ -258,7 +269,7 @@
 struct Mcoe_tmr_time
 {
   typedef TMR_timespec stamp_type;
-
+  typedef unsigned long long tick_type;
   static bool const valid = true; 
   static char const* name() { return "Mcoe_tmr_time"; }
   static void init()
@@ -268,8 +279,6 @@
     clocks_per_sec.tv_nsec = 0;
   }
 
-  static clockid_t const clock = CLOCK_REALTIME;
-
   static void sample(stamp_type& time)
   {
     TMR_ts tmp;
@@ -278,7 +287,7 @@
   }
 
   static stamp_type zero() { return stamp_type(); }
-  // static stamp_type clocks_per_sec() { return CLOCKS_PER_SEC; }
+
   static stamp_type add(stamp_type A, stamp_type B)
   {
     stamp_type res;
@@ -311,8 +320,8 @@
   static float seconds(stamp_type time)
     { return (float)(time.tv_sec) + (float)(time.tv_nsec) / 1e9; }
 
-  static unsigned long ticks(stamp_type time)
-    { return (unsigned long)(time.tv_sec * 1e9) + (unsigned long)time.tv_nsec; }
+  static tick_type ticks(stamp_type time)
+    { return (tick_type)(time.tv_sec * 1e9) + (tick_type)time.tv_nsec; }
   static bool is_zero(stamp_type const& stamp)
     { return stamp.tv_nsec == 0 && stamp.tv_sec == 0; }
 
@@ -329,6 +338,7 @@
   static void init();
 
   typedef long long stamp_type;
+  typedef unsigned long long tick_type;
   static void sample(stamp_type& time)
   {
     unsigned int tbl, tbu0, tbu1;
@@ -353,7 +363,7 @@
   static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
   static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
   static float seconds(stamp_type time) { return (float)time / (float)clocks_per_sec; }
-  static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static tick_type ticks(stamp_type time) { return (tick_type)time; }
   static bool is_zero(stamp_type const& stamp)
     { return stamp == stamp_type(); }
 
