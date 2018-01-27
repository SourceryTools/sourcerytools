
Index: tests/fft_ext/fft_ext.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft_ext/fft_ext.cpp,v
retrieving revision 1.4
diff -c -p -r1.4 fft_ext.cpp
*** tests/fft_ext/fft_ext.cpp	23 Sep 2005 16:11:43 -0000	1.4
--- tests/fft_ext/fft_ext.cpp	26 Apr 2006 18:48:05 -0000
***************
*** 15,28 ****
  #include <fstream>
  #include <string>
  #include <cmath>
- #include <argp.h>
  
  #include <vsip/initfin.hpp>
  #include <vsip/support.hpp>
  #include <vsip/signal.hpp>
  #include <vsip/math.hpp>
  
-      
  using namespace std;
  using namespace vsip;
  
--- 15,26 ----
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
--- 29,34 ----
*************** struct arguments
*** 79,150 ****
  };
  
  
- static error_t parse_opt (int key, char *arg, struct argp_state *state);
- 
- /// argp parser
- static struct argp argp = 
- { 
-   options,     // ptr to argp_options structure
-   parse_opt,   // function that parses options
-   args_doc,    // string describing required arguments
-   doc,         // string describing this program
-   0, 0, 0      // no childern, help_filter or domain.
- };
- 
- 
- 
  
  /***********************************************************************
    Utility Functions
  ***********************************************************************/
       
- /// Parse a single option - called repeatedly by argp_parse()
- static error_t
- parse_opt (int key, char *arg, struct argp_state *state)
- {
-   /* Get the input argument from argp_parse, which we
-      know is a pointer to our arguments structure. */
-   struct arguments *arguments = 
-     static_cast<struct arguments *>(state->input);
- 
-   switch (key)
-   {
-   case 's': 
-     arguments->precision = single_precision;
-     break;
-   case 'd': 
-     arguments->precision = double_precision;
-     break;
-   case 'n': 
-     arguments->fft = complex_to_complex;
-     break;
-   case 'c': 
-     arguments->fft = complex_to_real;
-     break;
-   case 'r': 
-     arguments->fft = real_to_complex;
-     break;
- 
-   case ARGP_KEY_ARG:
-     if (state->arg_num >= NUM_ARGS)
-       argp_usage (state);
-     if ( state->arg_num == 0 )
-       arguments->filename = arg;
-     break;
-      
-   case ARGP_KEY_END:
-     if (state->arg_num < NUM_ARGS)
-       argp_usage (state);
-     break;
-      
-   default:
-     return ARGP_ERR_UNKNOWN;
-   }
-   return 0;
- }
- 
-      
- 
  /// Error metric between two vectors.
  template <typename T1,
  	  typename T2,
--- 54,64 ----
*************** int main (int argc, char **argv)
*** 405,413 ****
    arguments.fft = complex_to_complex;
    arguments.filename = NULL;
       
!   /* Parse our arguments; every option seen by parse_opt will
!      be reflected in arguments. */
!   argp_parse(&argp, argc, argv, 0, 0, &arguments);
  
  
    // Check the first two letters of the filename to see if they
--- 319,331 ----
    arguments.fft = complex_to_complex;
    arguments.filename = NULL;
       
!   if ( argc == 2 )
!     arguments.filename = argv[1];
!   else
!   {
!     std::cerr << "Invalid number of arguments." << std::endl;
!     exit(-1);
!   }
  
  
    // Check the first two letters of the filename to see if they
