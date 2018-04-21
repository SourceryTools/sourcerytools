g++ -g -O2 -I../src -I/drive2/assem/work/checkout/vpp/tests/../src -I/include/atlas -I/include/fftw3  -I/drive2/assem/work/checkout/vpp/vendor/atlas/include -I/drive2/assem/work/build/vpp_temp2/vendor/fftw/include  -o convolution.exe convolution.o -L/lib/atlas -L/lib/fftw3  -L/drive2/assem/work/build/vpp_temp2/vendor/atlas/lib -L/drive2/assem/work/build/vpp_temp2/vendor/fftw/lib -L/drive2/assem/work/build/vpp_temp2/vendor/clapack -L/drive2/assem/work/build/vpp_temp2/lib -L../src/vsip -lvsip -llapack -lF77 -lcblas  -lfftw3f -lfftw3 -lfftw3l   || rm -f convolution.exe
convolution.o: In function `dot':
/drive2/assem/work/checkout/vpp/tests/../src/vsip/impl/lapack.hpp:180: undefined reference to `cblas_ddot'
/drive2/assem/work/checkout/vpp/tests/../src/vsip/impl/lapack.hpp:217: undefined reference to `cblas_zdotu_sub'
/drive2/assem/work/checkout/vpp/tests/../src/vsip/impl/lapack.hpp:179: undefined reference to `cblas_sdot'
/drive2/assem/work/checkout/vpp/tests/../src/vsip/impl/lapack.hpp:216: undefined reference to `cblas_cdotu_sub'
collect2: ld returned 1 exit status
