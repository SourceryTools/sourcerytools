Index: profiling.txt
===================================================================
--- profiling.txt	(revision 0)
+++ profiling.txt	(revision 0)
@@ -0,0 +1,256 @@
+-------------------------------------------------------------------------
+  Sourcery VSIPL++ Profiling API
+-------------------------------------------------------------------------
+Copyright (c) 2006 by CodeSourcery.  All rights reserved.
+
+
+Contents
+-------------------------------------------------------------------------
+1) Compiling with Profiling Enabled
+2) Command Line Options
+3) Profiling Functions
+4) Profile Log Files
+5) Event Tags
+
+
+
+1) Compiling with Profiling Enabled
+-------------------------------------------------------------------------
+If building from source, enable a suitable high-resolution timer 
+when configuring the library.  For example, 
+
+  --enable-timer=x86_64_tsc
+
+Pre-built versions of the library enable a suitable timer for your
+system.
+
+
+To enable profiling, define VSIP_IMPL_PROFILER=<mask> on the command 
+line when compiling your program.  On many systems, this option may be 
+added to the CXXFLAGS variable in the project makefile.
+
+This macro enables profiling operations in several different areas
+of the library, depending on the value of <mask>
+
+	  Profiling Configuration Mask
+
+	Section	Description		Value
+        -------------------------------------
+	signal	Signal Processing         1	
+	matvec	Linear Algbra		  2
+	fns	Elementwise Functions	  4
+	user	User-defined Operations	  8
+
+Determine the mask value by summing the values listed in the table
+for the areas you wish to profile.  For example, if you wish to
+gather performance data on your own code as well as for FFT's,
+you would enable 'user' and 'signal' from the table above.  The
+value you would choose would be 1 + 8 = 9.
+
+
+
+2) Command Line Options
+-------------------------------------------------------------------------
+You may profile programs without inserting any code by specifying the
+options on the command line.  Use this to choose the profiler mode:
+
+  --vsipl++-profile-mode={accum, trace}
+
+In 'trace' mode, the start and stop times where events begin and end
+are stored as profile data.  The log will present these events in 
+chronological order.  This mode is preferred when a highly detailed 
+view of program execution is desired.
+
+In 'accumulate' mode, the start and stop times are subtracted to
+compute the duration of an event and the cumulative sum of these
+durations are stored as profile data.  The log will indicate the
+total amount of time spent in each event.  This mode is desirable 
+when investigating a specific function's average performance.
+
+
+Specify the path to the log file for profile output using:
+
+  --vsipl++-profile-output=/path/to/logfile
+
+The second option defaults to the standard output on most 
+systems, so it may be omitted.
+
+
+
+3) Profiling Functions
+-------------------------------------------------------------------------
+The 'Profile' object is created to gather timing data for the 
+duration of its existence.   When it is destroyed (i.e. goes
+out of scope or is explicitly deleted) the profile data is written
+to the specified output file.  The first parameter specifies the
+logfile and the second, the profiling mode.  For example:
+
+  impl::profile::Profile profile("profile.txt", impl::profile::accum)
+
+The 'Scope_event' object is used to insert a profiler event
+into the log.  This object should be created at the point where
+you wish to begin timing and destroyed when the event is over 
+(such as a computation).  For example:
+
+  impl::profile::Scope_event event("User Event", op_count);
+
+The first parameter is the tag that will be used to display the 
+event's performance data in the log file.  The second parameter is 
+optional.  If used, 'op_count' should be an unsigned integer specifying 
+an estimate of the total number of operations (floating point or 
+otherwise) performed.  This is used by the profiler to compute 
+the rate of computation.  Without it, the profiler will still 
+yield useful timing data.
+
+Creating a Scope_event object on the stack is the easiest way
+to control the region it will profile.  For example, from within
+the body of a function (or the as the entire function), use
+this to define a region of interest:
+
+  {
+    impl::profile::Scope_event event("Main computation:");
+
+    // perform main computation
+    //
+      ...
+  }
+
+The closing brace causes 'event' to go out of scope, logging
+the amount of time spent doing the computation.
+
+
+
+4) Profile Log Files
+-------------------------------------------------------------------------
+The profiler outputs a small header at the beginning of each log file.
+The headers differ slighly for acculate mode and trace modes.
+
+4a) Accumulate mode
+
+# mode: pm_accum
+# timer: x86_64_tsc_time
+# clocks_per_sec: 3591375104
+#
+# tag : total ticks : num calls : op count : mops
+
+The respective columns that follow this header are:
+
+  tag		A descriptive name of the operation.  This is either
+		a name used internally or specified by the user.
+
+  total ticks	The duration of the event in processor ticks.
+
+  num calls	The number of times the event occurred.
+
+  op count	The number of operations performed per event.
+
+  mops		The calculated performance figure in millions
+		of operations per second.
+
+
+4b) Trace mode
+
+# mode: pm_trace
+# timer: x86_64_tsc_time
+# clocks_per_sec: 3591375104
+#
+# index : tag : ticks : open id : op count
+
+The respective columns that follow this header are:
+
+  index 	The entry number, beginning at one.
+
+  tag		A descriptive name of the operation.  This is either
+		a name used internally or specified by the user.
+
+  ticks		The current reading from the processor clock.
+
+  open id	A zero to indicate an event was created.
+		An event index to indicated the end of an event.
+
+  op count	The number of operations performed per event, or
+		zero to indicate the end of an event.
+
+
+Note that the timings expressed in 'ticks' may be converted to seconds
+by dividing by the 'clocks_per_second' constant in the header.  
+
+
+
+5) Event Tags
+-------------------------------------------------------------------------
+Sourcery VSIPL++ uses the following tags for profiling objects/functions
+within the library.  These tags are readable text containing information
+that varies depending on the event, but generally it tells you:
+
+  * The object/function name
+  * The number of dimensions
+  * Information about the data types involved
+  * The size of each dimension
+
+In all cases, data types (<T>, <I> and <O> below) are expressed using
+the BLAS/LAPACK convention of 
+
+    S - float
+    C - complex
+    D - double
+    Z - complex
+
+Expressions on views (vectors, matrices) are shown using prefix
+notation, i.e.
+
+    operator(operand, ...)
+
+Each operand may be the result of another computation, so expressions
+are nested, the parenthesis determining the order of evaluation. 
+When the operand types are views, the usual S/D/C/Z are used to
+indicate the type.  When operands are scalars, lower-case values
+are used instead (s/d/c/z).
+
+
+Current Tag List:
+
+     --signal--
+     Convolution [1D|2D] <T> <row_size>x<col_size>
+     Correlation [1D|2D] <T> <row_size>x<col_size>
+     Fft 1D [Inv|Fwd] <I>-<O> [by_ref|by_val] <size>x1
+     Fftm 2D [Inv|Fwd] <I>-<O> [by_ref|by_val] <row_size>x<col_size>
+     Fir <T> <size>
+     Iir <T> <size>
+
+     --matvec--
+     dot <T> <size>x1
+     cvjdot <T> <size>x1
+     trans <T> <row_size>x<col_size>
+     herm <T> <row_size>x<col_size>
+     kron <T> <row_size_a>x<col_size_a> <row_size_b>x<col_size_b>
+     outer <T> <size_a>x1 <size_b>x1
+     gemp <T> <row_size_a>x<col_size_a> <row_size_b>x<col_size_b>   
+     gems <T> <row_size>x<col_size>
+     cumsum <T> <row_size>x<col_size>
+     modulate <T> <row_size>x1
+
+     --fns--
+     Expr_Loop [1D|2D|3D] <expr> <size>
+     Expr_Copy      "       "              (all have dim/expr/size)
+     Expr_Trans
+     Expr_Dense
+     Expr_SAL_COPY
+     Expr_SAL_V
+     Expr_SAL_VV
+     Expr_SAL_VVV
+     Expr_SAL_fVVV
+     Expr_SAL_VV_V
+     Expr_SAL_V_VV
+     Expr_SAL_fVV_V
+     Expr_Loop_Vmmul
+     Expr_IPP_V-<func>
+     Expr_IPP_VV-<func>
+     Expr_IPP_SV-<func>
+     Expr_IPP_SV_FO-<func>
+     Expr_IPP_VS-<func>
+     Expr_IPP_VS_AS_SV-<func>
+     Expr_SIMD_V-<func>
+     Expr_SIMD_VV-<func>
+     Expr_SIMD_Loop
+
