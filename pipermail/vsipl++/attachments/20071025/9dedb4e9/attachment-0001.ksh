Index: src/vsip/opt/profile.hpp
===================================================================
--- src/vsip/opt/profile.hpp	(revision 185739)
+++ src/vsip/opt/profile.hpp	(working copy)
@@ -120,7 +120,8 @@
   static stamp_type add(stamp_type , stamp_type) { return 0; }
   static stamp_type sub(stamp_type , stamp_type) { return 0; }
   static float seconds(stamp_type) { return 0.f; }
-  static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static unsigned long long ticks(stamp_type time) 
+    { return (unsigned long long)time; }
   static bool is_zero(stamp_type const& stamp)
     { return stamp == 0; }
 
@@ -139,11 +140,13 @@
   typedef clock_t stamp_type;
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
+  static unsigned long long ticks(stamp_type time) 
+    { return (unsigned long long)time; }
   static bool is_zero(stamp_type const& stamp)
     { return stamp == stamp_type(); }
 
@@ -163,7 +166,7 @@
   typedef struct timespec stamp_type;
   static void sample(stamp_type& time) { clock_gettime(clock, &time); }
   static stamp_type zero() { return stamp_type(); }
-  // static stamp_type clocks_per_sec() { return CLOCKS_PER_SEC; }
+
   static stamp_type add(stamp_type A, stamp_type B)
   {
     stamp_type res;
@@ -196,8 +199,11 @@
   static float seconds(stamp_type time)
     { return (float)(time.tv_sec) + (float)(time.tv_nsec) / 1e9; }
 
-  static unsigned long ticks(stamp_type time)
-    { return (unsigned long)(time.tv_sec * 1e9) + (unsigned long)time.tv_nsec; }
+  static unsigned long long ticks(stamp_type time)
+  { 
+    return (unsigned long long)(time.tv_sec * 1e9) + 
+      (unsigned long long)time.tv_nsec; 
+  }
   static bool is_zero(stamp_type const& stamp)
     { return stamp.tv_nsec == 0 && stamp.tv_sec == 0; }
 
@@ -221,7 +227,7 @@
   static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
   static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
   static float seconds(stamp_type time) { return (float)time / (float)clocks_per_sec; }
-  static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static unsigned long long ticks(stamp_type time) { return (unsigned long long)time; }
   static bool is_zero(stamp_type const& stamp)
     { return stamp == stamp_type(); }
 
@@ -246,7 +252,7 @@
   static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
   static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
   static float seconds(stamp_type time) { return (float)time / (float)clocks_per_sec; }
-  static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static unsigned long long ticks(stamp_type time) { return (unsigned long long)time; }
   static bool is_zero(stamp_type const& stamp)
     { return stamp == stamp_type(); }
 
@@ -268,8 +274,6 @@
     clocks_per_sec.tv_nsec = 0;
   }
 
-  static clockid_t const clock = CLOCK_REALTIME;
-
   static void sample(stamp_type& time)
   {
     TMR_ts tmp;
@@ -278,7 +282,7 @@
   }
 
   static stamp_type zero() { return stamp_type(); }
-  // static stamp_type clocks_per_sec() { return CLOCKS_PER_SEC; }
+
   static stamp_type add(stamp_type A, stamp_type B)
   {
     stamp_type res;
@@ -311,8 +315,8 @@
   static float seconds(stamp_type time)
     { return (float)(time.tv_sec) + (float)(time.tv_nsec) / 1e9; }
 
-  static unsigned long ticks(stamp_type time)
-    { return (unsigned long)(time.tv_sec * 1e9) + (unsigned long)time.tv_nsec; }
+  static unsigned long long ticks(stamp_type time)
+    { return (unsigned long long)(time.tv_sec * 1e9) + (unsigned long long)time.tv_nsec; }
   static bool is_zero(stamp_type const& stamp)
     { return stamp.tv_nsec == 0 && stamp.tv_sec == 0; }
 
@@ -353,7 +357,7 @@
   static stamp_type add(stamp_type A, stamp_type B) { return A + B; }
   static stamp_type sub(stamp_type A, stamp_type B) { return A - B; }
   static float seconds(stamp_type time) { return (float)time / (float)clocks_per_sec; }
-  static unsigned long ticks(stamp_type time) { return (unsigned long)time; }
+  static unsigned long long ticks(stamp_type time) { return (unsigned long long)time; }
   static bool is_zero(stamp_type const& stamp)
     { return stamp == stamp_type(); }
 
