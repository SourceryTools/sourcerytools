
2005-09-20  Don McCoy  <don@codesourcery.com>
	
	Corrections to pass fft_ext tests.
	* src/vsip/signal-window.cpp: cleaned up an unneeded type a
	  added conditional directive around call to FFT.
	* tests/window.cpp: added conditional directive for FFT.
	* tests/fft_ext/fft_ext.cpp: cleaned up so that it will
	  deduce the fft type from the first two letters of filename.
	  Also now runs on single and double precision by default.