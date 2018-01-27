Index: ChangeLog
===================================================================
RCS file: /home/cvs/Repository/vpp/ChangeLog,v
retrieving revision 1.250
diff -c -p -r1.250 ChangeLog
*** ChangeLog	17 Sep 2005 16:17:33 -0000	1.250
--- ChangeLog	17 Sep 2005 17:07:01 -0000
***************
*** 1,5 ****
--- 1,10 ----
  2005-09-17  Jules Bergmann  <jules@codesourcery.com>
  
+ 	* src/vsip/impl/fft-core.hpp: '-Wall' cleanup.
+ 	* tests/fft_ext/fft_ext.cpp: Likewise.
+ 
+ 2005-09-17  Jules Bergmann  <jules@codesourcery.com>
+ 
  	* configure.ac: Fix typo.
  
  2005-09-17  Nathan Myers  <ncm@codesourcery.com>
cvs diff: Diffing apps
cvs diff: Diffing apps/sarsim
cvs diff: Diffing apps/sarsim/test-8
cvs diff: Diffing apps/sarsim/test-8/data
cvs diff: Diffing apps/sarsim/test-8/ref-plain
cvs diff: Diffing benchmarks
cvs diff: Diffing doc
cvs diff: Diffing doc/csl-docbook
cvs diff: Diffing doc/csl-docbook/fragments
cvs diff: Diffing doc/csl-docbook/graphics
cvs diff: Diffing doc/csl-docbook/xsl
cvs diff: Diffing doc/csl-docbook/xsl/fo
cvs diff: Diffing doc/csl-docbook/xsl/html
cvs diff: Diffing doc/quickstart
cvs diff: Diffing doc/release
cvs diff: Diffing examples
cvs diff: Diffing scripts
cvs diff: Diffing src
cvs diff: Diffing src/vsip
cvs diff: Diffing src/vsip/impl
Index: src/vsip/impl/fft-core.hpp
===================================================================
RCS file: /home/cvs/Repository/vpp/src/vsip/impl/fft-core.hpp,v
retrieving revision 1.13
diff -c -p -r1.13 fft-core.hpp
*** src/vsip/impl/fft-core.hpp	16 Sep 2005 02:13:38 -0000	1.13
--- src/vsip/impl/fft-core.hpp	17 Sep 2005 17:07:01 -0000
*************** template <vsip::dimension_type Dim, bool
*** 1326,1333 ****
  inline void
  in_place(
    Fft_core<Dim,std::complex<SCALAR_TYPE>,
!                std::complex<SCALAR_TYPE>,doFFTM>&  self,
!   std::complex<SCALAR_TYPE>*  inout)
      VSIP_NOTHROW
  {
    // not supported in IPP; we use from_to to do it, instead.
--- 1326,1333 ----
  inline void
  in_place(
    Fft_core<Dim,std::complex<SCALAR_TYPE>,
!                std::complex<SCALAR_TYPE>,doFFTM>&  /*self*/,
!   std::complex<SCALAR_TYPE>*  /*inout*/)
      VSIP_NOTHROW
  {
    // not supported in IPP; we use from_to to do it, instead.
*************** from_to(
*** 1390,1396 ****
    std::complex<SCALAR_TYPE> const* in, std::complex<SCALAR_TYPE>* out)
      VSIP_NOTHROW
  {
!   for (vsip::dimension_type j = 0; j < self.runs_; ++j)
    {
      if (self.is_forward_)
        Ipp_DFT<1,std::complex<SCALAR_TYPE> >::forward(
--- 1390,1396 ----
    std::complex<SCALAR_TYPE> const* in, std::complex<SCALAR_TYPE>* out)
      VSIP_NOTHROW
  {
!   for (int j = 0; j < self.runs_; ++j)
    {
      if (self.is_forward_)
        Ipp_DFT<1,std::complex<SCALAR_TYPE> >::forward(
*************** from_to(
*** 1410,1420 ****
  // template <>
  inline void
  from_to(
!   Fft_core<2,SCALAR_TYPE,std::complex<SCALAR_TYPE>,false>& self,
!   SCALAR_TYPE const* in, std::complex<SCALAR_TYPE>* out)
      VSIP_NOTHROW
  {  
    // FIXME: not implemented yet.
  #if 0  
    Ipp_DFT<1,SCALAR_TYPE>::forward2(
      self.plan_from_to_, in, out, self.p_buffer_, self.use_fft_) ;
--- 1410,1422 ----
  // template <>
  inline void
  from_to(
!   Fft_core<2,SCALAR_TYPE,std::complex<SCALAR_TYPE>,false>& /*self*/,
!   SCALAR_TYPE const* /*in*/, std::complex<SCALAR_TYPE>* /*out*/)
      VSIP_NOTHROW
  {  
    // FIXME: not implemented yet.
+   VSIP_IMPL_THROW(impl::unimplemented(
+ 		    "IPP FFT-2D real->complex not implemented"));
  #if 0  
    Ipp_DFT<1,SCALAR_TYPE>::forward2(
      self.plan_from_to_, in, out, self.p_buffer_, self.use_fft_) ;
*************** from_to(
*** 1433,1439 ****
    SCALAR_TYPE const* in, std::complex<SCALAR_TYPE>* out)
      VSIP_NOTHROW
  {
!   for (vsip::dimension_type j = 0; j < self.runs_; ++j)
    {
      Ipp_DFT<1,SCALAR_TYPE>::forward(
        self.plan_from_to_, in, out, self.p_buffer_, self.use_fft_);
--- 1435,1441 ----
    SCALAR_TYPE const* in, std::complex<SCALAR_TYPE>* out)
      VSIP_NOTHROW
  {
!   for (int j = 0; j < self.runs_; ++j)
    {
      Ipp_DFT<1,SCALAR_TYPE>::forward(
        self.plan_from_to_, in, out, self.p_buffer_, self.use_fft_);
*************** from_to(
*** 1449,1459 ****
  // template <>
  inline void
  from_to(
!   Fft_core<2,std::complex<SCALAR_TYPE>,SCALAR_TYPE,false>&  self ,
!   std::complex<SCALAR_TYPE> const* in, SCALAR_TYPE* out)
       VSIP_NOTHROW
  {
    // FIXME: not implemented yet
  #if 0  
    // FIXME: pack in place; maybe this must happen in
    //   fft_by_ref, where _in_, just copied into, is writeable.
--- 1451,1463 ----
  // template <>
  inline void
  from_to(
!   Fft_core<2,std::complex<SCALAR_TYPE>,SCALAR_TYPE,false>&  /*self*/,
!   std::complex<SCALAR_TYPE> const* /*in*/, SCALAR_TYPE* /*out*/)
       VSIP_NOTHROW
  {
    // FIXME: not implemented yet
+   VSIP_IMPL_THROW(impl::unimplemented(
+ 		    "IPP FFT-2D complex->real not implemented"));
  #if 0  
    // FIXME: pack in place; maybe this must happen in
    //   fft_by_ref, where _in_, just copied into, is writeable.
*************** from_to(
*** 1473,1479 ****
    std::complex<SCALAR_TYPE> const* in, SCALAR_TYPE* out)
       VSIP_NOTHROW
  {
!   for (vsip::dimension_type j = 0; j < self.runs_; ++j)
    {
      Ipp_DFT<1,SCALAR_TYPE>::inverse(
        self.plan_from_to_, in, out, self.p_buffer_, self.use_fft_) ;
--- 1477,1483 ----
    std::complex<SCALAR_TYPE> const* in, SCALAR_TYPE* out)
       VSIP_NOTHROW
  {
!   for (int j = 0; j < self.runs_; ++j)
    {
      Ipp_DFT<1,SCALAR_TYPE>::inverse(
        self.plan_from_to_, in, out, self.p_buffer_, self.use_fft_) ;
cvs diff: Diffing tests
cvs diff: Diffing tests/QMTest
cvs diff: Diffing tests/fft_ext
Index: tests/fft_ext/fft_ext.cpp
===================================================================
RCS file: /home/cvs/Repository/vpp/tests/fft_ext/fft_ext.cpp,v
retrieving revision 1.1
diff -c -p -r1.1 fft_ext.cpp
*** tests/fft_ext/fft_ext.cpp	1 Sep 2005 15:20:03 -0000	1.1
--- tests/fft_ext/fft_ext.cpp	17 Sep 2005 17:07:02 -0000
*************** static char args_doc[] = "filename";
*** 44,55 ****
       
  /// The options we understand.
  static struct argp_option options[] = {
!   {"single",  's', 0,      0,  "Single precision (default)" },
!   {"double",  'd', 0,      0,  "Double precision" },  
!   {"cc",      'n', 0,      0,  "Complex to Complex (default)" },
!   {"cr",      'c', 0,      0,  "Complex to Real" },
!   {"rc",      'r', 0,      0,  "Real to Complex" },
!   { 0 }
  };
  
  /// Possible types of FFT
--- 44,55 ----
       
  /// The options we understand.
  static struct argp_option options[] = {
!   {"single",  's', 0,      0,  "Single precision (default)", 0 },
!   {"double",  'd', 0,      0,  "Double precision", 0 },  
!   {"cc",      'n', 0,      0,  "Complex to Complex (default)", 0 },
!   {"cr",      'c', 0,      0,  "Complex to Real", 0 },
!   {"rc",      'r', 0,      0,  "Real to Complex", 0 },
!   { 0, 0, 0, 0, 0, 0 }
  };
  
  /// Possible types of FFT
*************** static struct argp argp = { 
*** 75,81 ****
    options,     // ptr to argp_options structure
    parse_opt,   // function that parses options
    args_doc,    // string describing required arguments
!   doc          // string describing this program
  };
  
  
--- 75,82 ----
    options,     // ptr to argp_options structure
    parse_opt,   // function that parses options
    args_doc,    // string describing required arguments
!   doc,         // string describing this program
!   0, 0, 0      // no childern, help_filter or domain.
  };
  
  
*************** void test_fft_cc (char *filename)
*** 226,232 ****
  
    // format: 
    //   <r_input>,<c_input>  <r_expected>,<c_expected>
!   int i;
    T val1, val2, val3, val4;
    for ( i = 0; i < size; ++i )
    {
--- 227,233 ----
  
    // format: 
    //   <r_input>,<c_input>  <r_expected>,<c_expected>
!   index_type i;
    T val1, val2, val3, val4;
    for ( i = 0; i < size; ++i )
    {
*************** void test_fft_cr (char *filename)
*** 275,281 ****
  
    // format: 
    //   <r_input>,<c_input>  <r_expected>
!   int i;
    T val1, val2, val3, val4;
    for ( i = 0; i < size; ++i )
    {
--- 276,282 ----
  
    // format: 
    //   <r_input>,<c_input>  <r_expected>
!   index_type i;
    T val1, val2, val3, val4;
    for ( i = 0; i < size; ++i )
    {
*************** void test_fft_rc (char *filename)
*** 323,329 ****
  
    // format: 
    //   <r_input>  <r_expected>,<c_expected>
!   int i;
    T val1, val2, val3, val4;
    for ( i = 0; i < size; ++i )
    {
--- 324,330 ----
  
    // format: 
    //   <r_input>  <r_expected>,<c_expected>
!   index_type i;
    T val1, val2, val3, val4;
    for ( i = 0; i < size; ++i )
    {
cvs diff: Diffing tests/fft_ext/data
cvs diff: Diffing tests/ref-impl
cvs diff: Diffing tools
cvs diff: Diffing vendor
