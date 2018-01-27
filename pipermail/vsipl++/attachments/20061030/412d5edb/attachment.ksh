2006-10-30  Don McCoy  <don@codesourcery.com>

	Added Scalable SAR benchmark application (all new files).
	* apps/ssar/load_save.hpp: Overloaded functions for reading/writing
	  views based on 'double' while stored on disk as 'float'.
	* apps/ssar/diffview.cpp: Compare complex or scalar views.
	* apps/ssar/make_set1_images.sh: Creates intermediate images for set1.
	* apps/ssar/kernel1.hpp: VSIPL++ implementation of HPC's SSCA #3
	  application benchmark.
	* apps/ssar/viewtoraw.cpp: Creates raw greyscale images from views
	  in different formats.
	* apps/ssar/ssar.cpp: Entry point for SSAR application.
	* apps/ssar/set1/uc.view: Input data.
	* apps/ssar/set1/ftfilt.view: Input data.
	* apps/ssar/set1/k.view: Input data.
	* apps/ssar/set1/ref_image.view: Input data.
	* apps/ssar/set1/ku.view: Input data.
	* apps/ssar/set1/dims.txt: Input dimensions.
	* apps/ssar/set1/u.view: Input data.
	* apps/ssar/set1/sar.view: Input data (raw SAR data).
	* apps/ssar/Makefile: Makefile for all components.
