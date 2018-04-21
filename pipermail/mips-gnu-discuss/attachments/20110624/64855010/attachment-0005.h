#ifndef _INIT_GYRO_H_
#define _INIT_GYRO_H_
							
void init_gyro( void )
{
	
	int gyro_cnfg_data[10];
	int *cnfg_arr_ptr;
	
	gyro_cnfg_data[0] = 0x16;//Register 0x16—DLPF,Full Scale
	gyro_cnfg_data[1] = 0x18;//Set FS_SEL TO 0h03 2000/sec & set SLPF_CFG to 8kHz
	
	gyro_cnfg_data[2] = 0x15;//Register 0x15 – Sample Rate Divider
	gyro_cnfg_data[3] = 0x01;//Setting the sample rate to 4khZ
	
	gyro_cnfg_data[4] = 0x17;//Register 0x17—Interrupt Configuration (Read/Write)
	gyro_cnfg_data[5] = 0x71;//Set bit 7 to 0 for active high output, set bit 6 to 1 for open drain, set bit 5 to 1 for latch mode,
							 //Set bit 4 to 1 to clear interrupt when data is read, set bit 0 to 1 to enable interrupt when data is ready
	
	gyro_cnfg_data[6] = 0x3E;//Register 0x3E—Power Management (Read/Write)
	gyro_cnfg_data[7] = 0x03;//Setting the Clock to z Gyro Clock
	
	cnfg_arr_ptr = &gyro_cnfg_data[0];
	
	//Register 0x16—DLPF,Full Scale
	
	//This register configures several parameters related to the sensor acquisition.
	//The FS_SEL parameter allows setting the full-scale range of the gyro sensors, 
	//as described in the table below. The power-on-reset value of FS_SEL is 00h. 
	//Set to 03h for proper operation.
	
	//The DLPF_CFG parameter sets the digital low pass filter configuration. It also 
	//determines the internal sampling rate used by the device

	
	i2c_handler( write, gyroscope_address, no_stop, i2c_write, 1, cnfg_arr_ptr, i2c_rddata);//Set the register pointer to Register 22 – DLPF, Full Scale, do not issue a stop
	i2c_handler( write, gyroscope_address,    stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);// Issue a restart and Set FS_SEL TO 0h03 2000/sec & set SLPF_CFG to 8kHz
	
	//Register 0x15 – Sample Rate Divider
	
	//This register determines the sample rate of the ITG-3200 gyros. The gyros outputs are sampled internally at either 1kHz or 8kHz, 
	//determined by the DLPF_CFG setting (see register 22). This sampling is then filtered digitally and delivered into the sensor registers 
	//after the number of cycles determined by this register. The sample rate is given by the following formula:
	
	//Fsample = Finternal / (divider+1), where Finternal is either 1kHz or 8kHz
	
	//As an example, if the internal sampling is at 1kHz, then setting this register to 7 would give the following:
	//Fsample = 1kHz / (7 + 1) = 125Hz, or 8ms per sample
	
	i2c_handler( write, gyroscope_address, no_stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);//Set the register pointer to the INT_ENABLE register
	i2c_handler( write, gyroscope_address,    stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);// Issue a restart and set the sample rate to 4khZ
	
	
	//Register 0x17—Interrupt Configuration (Read/Write)
	
	//This register configures the interrupt operation of the device. The interrupt output pin (INT) configuration 
	//can be set, the interrupt latching/clearing method can be set, and the triggers for the interrupt can be set.
	//Note that if the application requires reading every sample of data from the ITG-3200 part, it is best to enable 
	//the raw data ready interrupt (RAW_RDY_EN). This allows the application to know when new sample data is available.

	//Parameters:
	//				ACTL Logic level for INT output pin – 1=active low, 0=active high
	//				OPEN Drive type for INT output pin – 1=open drain, 0=push-pull
	//				LATCH_INT_EN Latch mode – 1=latch until interrupt is cleared, 0=50us pulse
	//				INT_ANYRD_2CLEAR Latch clear method – 1=any register read, 0=status register read only
	//				ITG_RDY_EN Enable interrupt when device is ready (PLL ready after changing clock source)
	//				RAW_RDY_EN Enable interrupt when data is available
	//				0 Load zeros into Bits 1 and 3 of the Interrupt Configuration register.to active high, and a value of 1 sets the interrupts to active low.
	
	i2c_handler( write, gyroscope_address, no_stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);//Set the register pointer to the Register 0x17—Interrupt Configuration register
	i2c_handler( write, gyroscope_address,    stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);	//
	
	//Register 0x3E—Power Management (Read/Write)
	
	//This register is used to manage the power control, select the clock source, and to issue a master reset to the device.
	//Setting the SLEEP bit in the register puts the device into very low power sleep mode. In this mode, only the serial 
	//interface and internal registers remain active, allowing for a very low standby current. Clearing this bit puts the device 
	//back into normal mode. To save power, the individual standby selections for each of the gyros should be used if any gyro axis is not used by the application.
	
	i2c_handler( write, gyroscope_address, no_stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);//Set the register pointer to the Register 0x3E—Power Management register
	i2c_handler( write, gyroscope_address,    stop, i2c_write, 1, ++cnfg_arr_ptr, i2c_rddata);//Setting the Clock to z Gyro Clock
		
	
}     
#endif