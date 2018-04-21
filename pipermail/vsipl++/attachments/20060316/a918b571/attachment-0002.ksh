prefix=
exec_prefix=${prefix}
libdir=${exec_prefix}/vsip
includedir=${prefix}
cxx=g++
cppflags=-I${includedir} -I${includedir}/../tvcpp0p8/include
cxxflags=-O2 -DNDEBUG -funswitch-loops -fgcse-after-reload --param max-inline-insns-single=2000 --param large-function-insns=6000 --param large-function-growth=800 --param inline-unit-growth=300 -m64 -mtune=nocona -mmmx -msse -msse2 -msse3
ldflags= -L${prefix}/../tvcpp0p8/lib -lvsip -lfftw

Name: Sourcery VSIPL++
Description: CodeSourcery VSIPL++ library
Version: 1.0
Libs: -L${libdir} -lvsippp ${ldflags} 
Cflags: ${cppflags}
