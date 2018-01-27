
Index: doc/quickstart/quickstart.xml
===================================================================
RCS file: /home/cvs/Repository/vpp/doc/quickstart/quickstart.xml,v
retrieving revision 1.29
diff -c -p -r1.29 quickstart.xml
*** doc/quickstart/quickstart.xml	28 Apr 2006 23:25:43 -0000	1.29
--- doc/quickstart/quickstart.xml	10 May 2006 21:00:24 -0000
***************
*** 742,759 ****
       </varlistentry>
  
       <varlistentry>
!       <term><option>--with-fft=<replaceable>lib</replaceable></option></term>
        <listitem>
         <para>
          Search for and use the FFT library indicated by
          <replaceable>lib</replaceable> to perform FFTs.  Valid
! 	choices for <replaceable>lib</replaceable> include
! 	<option>fftw3</option>, <option>ipp</option>, and
!         <option>sal</option>, which select the FFTW3, IPP, and SAL
!         libraries respectively.  If no FFT library is to be used
!         (disabling Sourcery VSIPL++'s FFT functionality),
!         <option>none</option> should be chosen for
!         <replaceable>lib</replaceable>.
         </para>
        </listitem>
       </varlistentry>
--- 742,764 ----
       </varlistentry>
  
       <varlistentry>
!       <term><option>--enable-fft=<replaceable>lib</replaceable></option></term>
        <listitem>
         <para>
          Search for and use the FFT library indicated by
          <replaceable>lib</replaceable> to perform FFTs.  Valid
! 	choices for <replaceable>lib</replaceable> include 
! 	<option>fftw3</option>, <option>ipp</option>, and 
!         <option>sal</option>, which select FFTW3, IPP, and SAL
!         libraries respectively.  A fourth option, <option>builtin</option>,
!         selects the FFTW3 library that comes with Sourcery VSIPL++ (default).
!         This option should be used if an existing FFTW3 library is not available.
!         If no FFT library is to be used (disabling Sourcery VSIPL++'s FFT 
!         functionality), <option>no_fft</option> should be chosen for
!         <replaceable>lib</replaceable>.  Advanced uses may specify 
!         more than one option separated by commans.  This causes VSIPL++
!         to attempt to use one FFT library before falling back to 
!         another if necessary.  Example: --enable-fft=sal,builtin
         </para>
        </listitem>
       </varlistentry>
***************
*** 794,807 ****
          Search for and use the LAPACK library indicated by
          <replaceable>lib</replaceable> to perform linear algebra
          (matrix-vector products and solvers).  Valid choices for
!         <replaceable>lib</replaceable> include <option>mkl</option>,
! 	<option>atlas</option>, <option>generic</option>, and
! 	<option>builtin</option>.
         </para>
  
         <para>
!         <option>mkl</option> selects the Intel Math Kernel Library (MKL)
! 	to perform linear algebra if found.
         </para>
         <para>
          <option>atlas</option> selects the ATLAS library
--- 799,817 ----
          Search for and use the LAPACK library indicated by
          <replaceable>lib</replaceable> to perform linear algebra
          (matrix-vector products and solvers).  Valid choices for
!         <replaceable>lib</replaceable> include <option>mkl7</option>, 
!         <option>mkl5</option>, <option>atlas</option>, 
!         <option>generic</option>, <option>builtin</option>, and
! 	<option>fortran-builtin</option>.
         </para>
  
         <para>
!         <option>mkl7</option> selects the Intel Math Kernel Library (MKL)
!         version 7.x or above to perform linear algebra if found.
!        </para>
!        <para>
!         <option>mkl5</option> selects the Intel Math Kernel Library (MKL)
!         version 5.x to perform linear algebra if found.
         </para>
         <para>
          <option>atlas</option> selects the ATLAS library
***************
*** 812,822 ****
  	(-llapack) to perform linear algebra if found.
         </para>
         <para>
!         <option>builtin</option> selects the builtin version of ATLAS
!         to perform linear algebra.  This option requires building
!         ATLAS which can take considerable time and is not supported
!         on all platforms.  It is only recommended if MKL, ATLAS, or
! 	a generic LAPACK or not already installed on the platform.
         </para>
        </listitem>
       </varlistentry>
--- 822,842 ----
  	(-llapack) to perform linear algebra if found.
         </para>
         <para>
!         <option>builtin</option> selects the builtin version of 
!         ATLAS/C-LAPACK to perform linear algebra.  This option 
!         requires building ATLAS which can take considerable time 
!         and is not supported on all platforms.  It is only recommended 
!         if MKL, ATLAS, or a generic LAPACK or not already installed on 
!         the platform.
!        </para>
!        <para>
!         <option>fortran-builtin</option> selects the builtin version
!         of ATLAS/F77-LAPACK to perform linear algebra.  Like the 
!         <option>builtin</option>, this option requires building ATLAS
!         as well.  In this case, it uses the FORTRAN version instead of
!         the C version of LAPACK.  Note this option requires the g2c
!         library.  Use the <option>--with-g2c-path=</option> option if
!         this library is not installed in a standard location.
         </para>
        </listitem>
       </varlistentry>
