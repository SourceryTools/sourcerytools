2007-11-29  Don McCoy  <don@codesourcery.com>

	* src/vsip/core/temp_buffer.hpp: Modified destructor to utilize
	  return_temporary_buffer() to de-allocate memory obtained with
	  get_temporary_buffer().
