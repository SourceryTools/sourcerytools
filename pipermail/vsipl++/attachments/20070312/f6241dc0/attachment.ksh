2007-03-12  Don McCoy  <don@codesourcery.com>

	* src/vsip/opt/cbe/ppu/fft.cpp: Corrected bug causing
	  FFTM to apply the scaling factor twice.  Changed
	  FFT to use multi-use work blocks as does FFTM.  This
	  fixed a bug preventing task reuse when an FFT was 
	  performed prior to an FFTM.
	* tests/fft_be.cpp: Added CBE-specific backend tests.
	  Enhanced the data generation functions to allow
	  column-major FFTMs where the minor dimension has a
	  non-unit stride.
