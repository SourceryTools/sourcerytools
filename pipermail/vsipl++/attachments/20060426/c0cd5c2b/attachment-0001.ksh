
Index: configure.ac
===================================================================
RCS file: /home/cvs/Repository/vpp/configure.ac,v
retrieving revision 1.91
diff -c -p -r1.91 configure.ac
*** configure.ac	28 Mar 2006 14:46:38 -0000	1.91
--- configure.ac	26 Apr 2006 06:47:41 -0000
*************** AC_CHECK_DECLS([posix_memalign, memalign
*** 493,498 ****
--- 493,502 ----
  #endif])
  vsip_impl_avoid_posix_memalign=
  
+ #
+ # Check for GNU hierarchial argument parsing 
+ #
+ AC_CHECK_HEADERS([argp.h], [], [], [// no prerequisites])
  
  #
  # Find the FFT library.
Index: tests/fft_ext/fft_ext.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft_ext/fft_ext.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 fft_ext.cpp
*** tests/fft_ext/fft_ext.cpp	23 Sep 2005 16:11:43 -0000	1.4
--- tests/fft_ext/fft_ext.cpp	26 Apr 2006 06:47:42 -0000
***************
*** 15,27 ****
  #include <fstream>
  #include <string>
  #include <cmath>
- #include <argp.h>
  
  #include <vsip/initfin.hpp>
  #include <vsip/support.hpp>
  #include <vsip/signal.hpp>
  #include <vsip/math.hpp>
  
       
  using namespace std;
  using namespace vsip;
--- 15,29 ----
  #include <fstream>
  #include <string>
  #include <cmath>
  
  #include <vsip/initfin.hpp>
  #include <vsip/support.hpp>
  #include <vsip/signal.hpp>
  #include <vsip/math.hpp>
  
+ #ifdef HAVE_ARGP_H
+ #include <argp.h>
+ #endif
       
  using namespace std;
  using namespace vsip;
*************** using namespace vsip;
*** 31,59 ****
    Definitions
  ***********************************************************************/
  
- /// Required for --version option
- const char *argp_program_version = "fft_ext 1.01";
-      
- /// Program documentation.
- static char doc[] =
-      "FFT External Tests -- VSIPL++ test using C-VSIPL FFT test data files";
-      
- #define NUM_ARGS     1
- 
- /// A description of the arguments we accept.
- static char args_doc[] = "filename";
-      
- /// The options we understand.
- static struct argp_option options[] = 
- {
-   {"single",  's', 0,      0,  "Single precision only", 0 },
-   {"double",  'd', 0,      0,  "Double precision only", 0 },  
-   {"cc",      'n', 0,      0,  "Complex to Complex (default)", 0 },
-   {"cr",      'c', 0,      0,  "Complex to Real", 0 },
-   {"rc",      'r', 0,      0,  "Real to Complex", 0 },
-   { 0, 0, 0, 0, 0, 0 }
- };
- 
  /// Possible types of FFT
  enum fft_type
  {
--- 33,38 ----
*************** struct arguments
*** 79,84 ****
--- 58,88 ----
  };
  
  
+ #ifdef HAVE_ARGP_H
+ 
+ /// Required for --version option
+ const char *argp_program_version = "fft_ext 1.01";
+      
+ /// Program documentation.
+ static char doc[] =
+      "FFT External Tests -- VSIPL++ test using C-VSIPL FFT test data files";
+      
+ #define NUM_ARGS     1
+ 
+ /// A description of the arguments we accept.
+ static char args_doc[] = "filename";
+ 
+ /// The options we understand.
+ static struct argp_option options[] = 
+ {
+   {"single",  's', 0,      0,  "Single precision only", 0 },
+   {"double",  'd', 0,      0,  "Double precision only", 0 },  
+   {"cc",      'n', 0,      0,  "Complex to Complex (default)", 0 },
+   {"cr",      'c', 0,      0,  "Complex to Real", 0 },
+   {"rc",      'r', 0,      0,  "Real to Complex", 0 },
+   { 0, 0, 0, 0, 0, 0 }
+ };
+ 
  static error_t parse_opt (int key, char *arg, struct argp_state *state);
  
  /// argp parser
*************** parse_opt (int key, char *arg, struct ar
*** 142,149 ****
    }
    return 0;
  }
  
-      
  
  /// Error metric between two vectors.
  template <typename T1,
--- 146,153 ----
    }
    return 0;
  }
+ #endif // HAVE_ARGP_H
  
  
  /// Error metric between two vectors.
  template <typename T1,
*************** int main (int argc, char **argv)
*** 405,413 ****
--- 409,427 ----
    arguments.fft = complex_to_complex;
    arguments.filename = NULL;
       
+ #ifdef HAVE_ARGP_H
    /* Parse our arguments; every option seen by parse_opt will
       be reflected in arguments. */
    argp_parse(&argp, argc, argv, 0, 0, &arguments);
+ #else
+   if ( argc == 2 )
+     arguments.filename = argv[1];
+   else
+   {
+     std::cerr << "Invalid number of arguments." << std::endl;
+     exit(-1);
+   }
+ #endif
  
  
    // Check the first two letters of the filename to see if they
