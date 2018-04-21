#ifndef _CalAxisOrie_H_
#define _CalAxisOrie_H_


void CalAxisOrie( void )  
{	
	                          
	accel_pitch_angle = atan2f(accel_z_magnitude,accel_x_magnitude); //atan2f 
	accel_yaw_angle   = atan2f(accel_z_magnitude,accel_y_magnitude); //atan2f 
	accel_roll_angle  = atan2f(accel_y_magnitude,accel_x_magnitude); //atan2f 
	
	
/*************************************************************************************************************/
                          
	if ( gyro_y_angular_rate >= 0 ) { 
		
		if ( gyro_pitch_angle + gyro_y_angular_rate >= 360 ) {
			 		
			gyro_pitch_angle = (gyro_pitch_angle + gyro_y_angular_rate) - 360;
			 
		} else {
			
			gyro_pitch_angle += gyro_y_angular_rate;			
		}
		
	} else {  
		
		if ( gyro_pitch_angle - gyro_y_angular_rate <= 0 ) {
			 		
			gyro_pitch_angle = 360 - (gyro_pitch_angle - gyro_y_angular_rate);
			 
		} else {
			
			gyro_pitch_angle -= gyro_y_angular_rate;			
		}		
	}
	
/*************************************************************************************************************/	

	if ( gyro_z_angular_rate >= 0 ) { 
		
		if ( gyro_yaw_angle + gyro_z_angular_rate >= 360 ) {
			 		
			gyro_yaw_angle = (gyro_yaw_angle + gyro_z_angular_rate) - 360;
			 
		} else {
			
			gyro_yaw_angle += gyro_z_angular_rate;
			
		}
		
	} else {  
		
		if ( gyro_yaw_angle - gyro_z_angular_rate <= 0 ) {
			 		
			gyro_yaw_angle = 360 - (gyro_yaw_angle - gyro_z_angular_rate);
			 
		} else {
			
			gyro_yaw_angle -= gyro_z_angular_rate;
			
		}		
	}
	
/*************************************************************************************************************/
	 
	if ( gyro_x_angular_rate >= 0 ) { 
		
		if ( gyro_roll_angle + gyro_x_angular_rate >= 360 ) {
			 		
			gyro_roll_angle = (gyro_roll_angle + gyro_x_angular_rate) - 360;
			 
		} else {
			
			gyro_roll_angle += gyro_x_angular_rate;
			
		}
		
	} else {  
		
		if ( gyro_roll_angle - gyro_x_angular_rate <= 0 ) {
			 		
			gyro_roll_angle = 360 - (gyro_roll_angle - gyro_x_angular_rate);
			 
		} else {
			
			gyro_roll_angle -= gyro_x_angular_rate;
			
		}		
	}
	
/************************************************************************************************************/
 	
	//kalman_filter(accel_pitch_angle, gyro_pitch_angle); // Kalman Filter calculates the true aircraft_pitch_angle
	//kalman_filter(accel_yaw_angle,  gyro_yaw_angle);    // Kalman Filter calculates the true aircraft_yaw_angle  
	//kalman_filter(accel_roll_angle, gyro_roll_angle);	// Kalman Filter calculates the true aircraft_roll_angle 	

}

#endif