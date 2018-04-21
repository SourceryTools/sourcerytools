#ifndef _RETRVSNRDATA_H_
#define _RETRVSNRDATA_H_

// The following function retreives Gyro and Accelerometer data throught the I2C port.
// 

void retrSnrData( char* wrdnqueue_wrptr, char* wrdnqueue_rdptr ) {  
	
	int gps_x_dummycor, gps_y_dummycor, gps_dummyalt, gps_dummy, snr_status, i2c_dummy1, i2c_dummy2, i2c_dummy1b, i2c_dummy2b;

	char *SnrData, *starting_address;
	int  cnfg_arr[1], *cnfg_arr_ptr; 
	
	cnfg_arr_ptr = &cnfg_arr[0];
	
	snr_status = quik_silva_status_reg;	
	
	//Retreive GPS data if the data is avaiable
	if ( (snr_status & 0x00001000) != 0 ) {		//CHECK UART 1 to see if GPS data is avaiable   
		
		//get_gps();
	
		for ( int i = 0; i<= GPS_DATA_COUNT-1; i++ ) {			
			
			if ( i >= 13 && i <= 16 ) {				
				
				gps_x_dummycor = ( gps_x_dummycor << 8 ) | rs232_uart1;
				
			} else if ( i >= 17 && i <= 21 ) {
				
				gps_y_dummycor = ( gps_y_dummycor << 8 ) | rs232_uart1;
				
			} else if ( i >= 26 && i <= 29 ) {
				
				gps_dummyalt = ( gps_dummyalt << 8 ) | rs232_uart1;
				
			} else {
				
				gps_dummy = rs232_uart1;
				
			}			
		}
		
		gpsSamples++;
		 
		gps_xAccumulator += (float) gps_x_dummycor * 0.0000001;	//Converting cordinates to degrees 1.0e^-7
		gps_yAccumulator += (float) gps_y_dummycor * 0.0000001;	//Converting cordinates to degrees 1.0e^-7
		gps_zAccumulator += (float) gps_dummyalt * 0.001 * 3;	//Altitude converted to 1/100 of a ft
		
		if ( gpsSamples == SAMPLES ) {                                    
					        	                                                                                                                                 
        	gps_x_cordinate = (gps_xAccumulator / SAMPLES);    
        	gps_y_cordinate = (gps_yAccumulator / SAMPLES);    
        	gps_z_cordinate = (gps_zAccumulator / SAMPLES);
        	
        	gps_xAccumulator = 0.0;                                                   
        	gps_yAccumulator = 0.0;                                                   
        	gps_zAccumulator = 0.0;
        	
        	gpsSamples = 0;
        	
        	CalAxisOrie();// Calculate the angles of orientation based on the new information	
    	}		
	}	
	
	//Retreive Accelerometer data if data is avaiable
	if ( (snr_status & 0x00000002) == 2 ) {
		
		//get_accel();
		
		cnfg_arr[0] = 0x32000000;
		
		i2c_handler( write, accelerometer_address, no_stop, i2c_write, 1, cnfg_arr_ptr, i2c_rddata); 	//Set the register pointer to Data Reg 0x32
		i2c_handler( readnowait, accelerometer_address, stop, i2c_read, 6, cnfg_arr_ptr, i2c_rddata);  //Issue a restart and Read the xyz axis data
		
		*wrdnqueue_wrptr++ = 1; // modify the variable that *wrdnqueue_ptr points to and increment the pointer	 
	}
	
	//Retreive Gyroscope data if data is avaiable
	if ( (snr_status & 0x00000004) == 4 ) {
		
		//get_gyro();	
		
		cnfg_arr[0] = 0x1B000000;
		
		i2c_handler( write, gyroscope_address, no_stop, i2c_write, 1, cnfg_arr_ptr, i2c_rddata); 	 // Set the register pointer to Data Reg 0x1B
		i2c_handler( readnowait, gyroscope_address, stop, i2c_read, 8, cnfg_arr_ptr, i2c_rddata);  // Issue a restart and read the temp xyz axis data
		
		*wrdnqueue_wrptr = 2; // modify the variable that **wrdnqueue_ptr points to and increment the pointer	 
	} 
	
	while ( (quik_silva_status_reg & 0x00020000) != 0 ) { // check to see if there is data in the I2C FIFO
	
		i2c_dummy1 = i2c_interface;
		i2c_dummy1b = (i2c_dummy1 & 0xFFFF0000) >> 16;
		i2c_dummy2 = i2c_interface;
		i2c_dummy2b = (i2c_dummy2 & 0xFFFF0000) >> 16;
				
		switch ( *wrdnqueue_rdptr ) {
		
			 case 1: // Get Accelerometer Data
			 	
			    accelSamples++;			 	

			 	accel_xAccumulator += (float) (i2c_dummy1 & 0x0000FFFF) * 0.0078f;                              
        		accel_yAccumulator += (float) i2c_dummy1b * 0.0078f;                              
        		accel_zAccumulator += (float) i2c_dummy2 * 0.0078f;
				
				if (accelSamples == SAMPLES) {                                    
					        	                                                                       
        		 	//Average the samples, remove the bias, and calculate the acceleration in m/s/s.                                                           
        		 	accel_x_magnitude = ( (accel_xAccumulator / SAMPLES) - accel_xBias);// * ACCELEROMETER_GAIN;    
        		 	accel_y_magnitude = ( (accel_yAccumulator / SAMPLES) - accel_yBias);// * ACCELEROMETER_GAIN;    
        		 	accel_z_magnitude = ( (accel_zAccumulator / SAMPLES) - accel_zBias);// * ACCELEROMETER_GAIN;
        		 	
        		 	accel_xAccumulator = 0.0f;                                                   
        		 	accel_yAccumulator = 0.0f;                                                   
        		 	accel_zAccumulator = 0.0f;
        		 	
        		 	accelSamples = 0;
        		 	
        		 	CalAxisOrie();// Calculate the angles of orientation based on the new information	
    		 	}

			 	wrdnqueue_rdptr++;
			 	break;
			 	
			 case 2: // Get Gyro Data			 	
			 	
			 	gyroSamples++;
		
			 	gyro_temperature  += (float) (i2c_dummy1 & 0x0000FFFF);
			 	
				gyro_xAccumulator += (float) ( i2c_dummy1b / 14.375f) / 4000;                             
        		gyro_yAccumulator += (float) ( (i2c_dummy2 & 0x0000FFFF) / 14.375f) / 4000;                       
        		gyro_zAccumulator += (float) ( i2c_dummy2b / 14.375f) / 4000;
				
				if (accelSamples == SAMPLES) {                                    
        			                                                                       
        		 	//Average the samples, remove the bias, and calculate the acceleration in m/s/s.                                                           
        		 	gyro_x_angular_rate = (gyro_xAccumulator / SAMPLES);// - gyro_xBias) * GYRO_GAIN;    
        		 	gyro_y_angular_rate = (gyro_yAccumulator / SAMPLES);// - gyro_yBias) * GYRO_GAIN;    
        		 	gyro_z_angular_rate = (gyro_zAccumulator / SAMPLES);// - gyro_zBias) * GYRO_GAIN;
        		 	
        		 	gyro_xAccumulator = 0.0f;                                                   
        		 	gyro_yAccumulator = 0.0f;                                                   
        		 	gyro_zAccumulator = 0.0f; 
        		 	
        		 	gyroSamples = 0;
        		 	
        		 	CalAxisOrie();// Calculate the angles of orientation based on the new information        
     			}
			 	
			 	wrdnqueue_rdptr++;
			 	break;
			 
			 default: // done

			 	break;		 			 	
		}			
	}		                                                                                                                                  
 }
 
 
#endif
                                                                                                                                                                