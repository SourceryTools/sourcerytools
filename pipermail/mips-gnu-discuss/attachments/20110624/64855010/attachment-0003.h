#ifndef _INIT_ACCEL_H_
#define _INIT_ACCEL_H_
							
void init_accel( void )
{
	
	int accel_cnfg_data[10];
	int *cnfg_arr_ptr;
	
	
	accel_cnfg_data[0] = 0x2F000000;//Register 0x2F—INT_MAP
	accel_cnfg_data[1] = 0x7F000000;//Setting the Data Ready bit to a 0
	
	accel_cnfg_data[2] = 0x2E000000;//Register 0x2E—INT_ENABLE (Read/Write)
	accel_cnfg_data[3] = 0x80000000;//Setting the Data Ready bit to a 1
	
	accel_cnfg_data[4] = 0x31000000;//Register 0x31—DATA_FORMAT (Read/Write)
	accel_cnfg_data[5] = 0x09000000;//Setting the INT_INVERT Bit 0 and the FULL RESOLUTION BIT TO a 1, and set resolution to 4g
	
	accel_cnfg_data[6] = 0x2C000000;//Register 0x2C—BW_RATE (Read/Write)
	accel_cnfg_data[7] = 0x0F000000;//Setting the Data Rate to 3200hz
	
	cnfg_arr_ptr = &accel_cnfg_data[0];
	
	//Register 0x2F—INT_MAP (Read/Write)
	//Set the INT-MAP register bit 7 to a 1, to enable the DATA READY INTERRUPT
	
	//Any bits set to 0 in this register send their respective interrupts to the INT1 pin, 
	//whereas bits set to 1 send their respective interrupts to the INT2 pin. All selected 
	//interrupts for a given pin are OR’ed.

	//i2c_handler( int function_cmd, int slave_address, int stop_req, int i2c_cmd, int cntrl_byte_cnt, int *i2c_wrdata, char *i2c_rddata )
	            
	i2c_handler( write, accelerometer_address, no_stop, i2c_write, 1, cnfg_arr_ptr, i2c_rddata);//Set the register pointer to the INT_MAP register
	i2c_handler( write, accelerometer_address,    stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);// Issue a restart and set the DATA READY BIT to 0
	
	//Register 0x2E—INT_ENABLE (Read/Write)
	
	//Setting bits in this register to a value of 1 enables their respective functions to 
	//generate interrupts, whereas a value of 0 prevents the functions from generating interrupts. 
	//The DATA_READY, watermark, and overrun bits enable only the interrupt output; the functions are 
	//always enabled. It is recommended that interrupts be configured before enabling their outputs.
	
	i2c_handler( write, accelerometer_address, no_stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);//Set the register pointer to the INT_ENABLE register
	i2c_handler( write, accelerometer_address,    stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);// Issue a restart and set the DATA READY BIT to 0 
	
	
	//Register 0x31—DATA_FORMAT (Read/Write)
	
	//The DATA_FORMAT register controls the presentation of data to Register 0x32 through Register 0x37. 
	//All data, except that for the ±16 g range, must be clipped to avoid rollover.
	
	//INT_INVERT Bit                                                                                                            
	//A value of 0 in the INT_INVERT bit sets the interrupts to active high, and a value of 1 sets the interrupts to active low.
	
	i2c_handler( write, accelerometer_address, no_stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);//Set the register pointer to the INT_INVERT register
	i2c_handler( write, accelerometer_address,    stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);// Issue a restart and set the INT_INVERT BIT to 0, and the FULL RESOLUTION BIT TO a 1
	
	//Register 0x2C—BW_RATE (Read/Write)
	
	//Rate Bits These bits select the device bandwidth and output data rate (see Table 6 and Table 7 for details). 
	//The default value is 0x0A, which translates to a 100 Hz output data rate. An output data rate should be selected 
	//that is appropriate for the communication protocol and frequency selected. Selecting too high of an output data rate 
	//with a low communication speed results in samples being discarded.
	
	i2c_handler( write, accelerometer_address, no_stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);//Set the register pointer to the BW_RATE register
	i2c_handler( write, accelerometer_address,    stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);// Issue a restart and set the Data Rate to 3200hz
		
	
}     
#endif