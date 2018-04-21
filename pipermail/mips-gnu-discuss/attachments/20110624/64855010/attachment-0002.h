#ifndef _GLOBAL_H_
#define _GLOBAL_H_
 



#define   clk_generators      		 (*((volatile unsigned long *)  0x0A000000))  // CLK GENs         					** WRITE ONLY

// SERIAL ICS HIGH LEVEL ADDRESSES

#define   i2c            			 (*((volatile unsigned long *)  0x0B000000))  // I2C            					** READ/WRITE
#define   spi            			 (*((volatile unsigned long *)  0x0C000000))  // SPI            					** READ/WRITE
#define   uart           			 (*((volatile unsigned long *)  0x0D000000))  // UART          						** READ/WRITE
#define   watchdog_timers			 (*((volatile unsigned long *)  0x0E000000))  // WATCHDOG TIMERs
#define   pwms						 (*((volatile unsigned long *)  0x0F000000))  // PULSE WIDTH MODULATORS				** WRITE ONLY
#define   encodeds					 (*((volatile unsigned long *)  0x10000000))  // PULSE WIDTH MODULATION ENCODERS	** READ  ONLY

// REGISTERS

#define   quik_silva_reg      		 (*((volatile unsigned long *)  0xD0000000))  // GPIO STATUS REGISTER     			** WRITE ONLY
#define   quik_silva_status_reg   	 (*((volatile unsigned long *)  0xD0000001))  // uCPU Data REG		    			** READ  ONLY
#define   mux_sel_register       	 (*((volatile unsigned long *)  0xD0000002))  // MUX_SELELECTS    					** WRITE ONLY
#define   seven_segment_display   	 (*((volatile unsigned long *)  0xD0000003))  // SEVEN SEGEMENT DISPLAY REGISTER	** WRITE ONLY
#define   led_register           	 (*((volatile unsigned long *)  0xD0000004))  // LED REGISTER						** WRITE ONLY


// Flash and SRAMs

#define  volatile_sram		  	     (*((volatile   signed long *)  0x8A000001))  // SRAM	
#define  sram_trans_cfgfifo	  	     (*((volatile   signed long *)  0x8D000000))  // SRAM TRANSACTION CONFIGURATION FIFO ** WRITE ONLY
#define  sram_wr_data_fifo  	     (*((volatile   signed long	*)  0xD0000008))  // SRAM WRITE DATA FIFO                ** WRITE ONLY
#define  sram_rd_data_fifo  	     (*((volatile   signed long *)  0x8A000000))  // SRAM READ DATA FIFO                 ** READ  ONLY

#define  flash_rom			  	     (*((volatile unsigned char *)  0x90000000))  // FLASH                               

//***************************************************************************************************************************//
//										SERIAL ICs LOW LEVEL ADDRESSES
//**************************************************************************************************************************//
 
 
 
#define   i2c_clk_gen      			 (*((volatile unsigned long *) 0x0A000001)) // I2C_CLK_GEN							** WRITE ONLY                          
#define   i2c_cntrl_reg    			 (*((volatile unsigned long *) 0x0B000002)) // I2C CONTROL REG						** WRITE ONLY                       
#define   i2c_interface    			 (*((volatile   signed long *) 0x0B000003)) // I2C_INTERFACE                                            
                           			                                                                                    
#define   spi_clk_gen      			 (*((volatile unsigned long *) 0x0A000002)) // SPI_CLK_GEN							** WRITE ONLY                          
#define   spi_control_reg  			 (*((volatile unsigned long *) 0x0C000002)) // SPI CONTROL REGISTER					** WRITE ONLY                   
#define   spi_interface    			 (*((volatile   signed long *) 0x0C000003)) // SPI_INTERFACE                                            
                           			                                                                                    
#define   baud_gen1 	    		 (*((volatile unsigned long *) 0x0A000003)) // UART 1 BUAD RATE GENERATOR         	** WRITE ONLY          
#define   baud_gen2 	    		 (*((volatile unsigned long *) 0x0A000005)) // UART 2 BUAD RATE GENERATOR        	** WRITE ONLY           
                                	                                                                                 
#define   EvenCLK_divisor_Reg 		 (*((volatile unsigned long *) 0x0A000006)) // Generic Clock Module 90  Phase Reg	** WRITE ONLY       
#define   TFF_90Phase_Reg 			 (*((volatile unsigned long *) 0x0A000016)) // Generic Clock Module 90  Phase Reg	** WRITE ONLY          
#define   TFF_180Phase_Reg 			 (*((volatile unsigned long *) 0x0A000026)) // Generic Clock Module 180 Phase Reg	** WRITE ONLY 
#define   strtclk_mod 				 (*((volatile unsigned long *) 0xD0000005)) // Generic Clock Module GO ENABLE		** WRITE ONLY

//DUAL MODULUS DIVIDER SECTION
#define	  SeqLeth 		             (*((volatile unsigned long *) 0x0A000046)) // C Sequence Length                                                                  
#define	  NumXdiv_P 	             (*((volatile unsigned long *) 0x0A000056)) // B # of times to divide by P                                                        
#define	  IntDivr 		             (*((volatile unsigned long *) 0x0A000066)) // N ( Integer divisor, found by rounding M up ) should always be P+1                 
#define	  RelDivrM_Flor              (*((volatile unsigned long *) 0x0A000076)) // P ( The greatest integer that is less than the real divisor M )should always be N-1                        
                           			                                                                                    
#define   rs232_config_reg1   		 (*((volatile   signed long *) 0x0D000000)) // UART CONFIGURATION REGISTER         	** WRITE ONLY     
#define   rs232_uart1		  		 (*((volatile   signed long *) 0x0D000001)) // UART WRITE FIFO                                        
                           			                                                                                    
#define   rs232_config_reg2    		 (*((volatile   signed long *) 0x13000000)) // UART CONFIGURATION REGISTER         	** WRITE ONLY    
#define   rs232_uart2		  		 (*((volatile   signed long *) 0x13000001)) // UART WRITE FIFO                                            
                                    	                                                                                 
// UDP CONFIGURATION REGISTERS      	                                                                                 
                                    	                                                                                 
#define   target_ip_address     	 (*((volatile unsigned long *) 0x12000000))  // TARGET IP ADDRESS					** WRITE ONLY                
#define   core_ip_address	    	 (*((volatile unsigned long *) 0x12000001))  // CORE IP ADDRESS	 					** WRITE ONLY                
#define   core_mac_address1	    	 (*((volatile unsigned long *) 0x12000002))  // CORE MAC ADDRESS 1 [47:32] 			** WRITE ONLY          
#define   core_mac_address2	    	 (*((volatile unsigned long *) 0x12000003))  // CORE MAC ADDRESS 2 [31:0]			** WRITE ONLY            
#define   subnet_mask		    	 (*((volatile unsigned long *) 0x12000004))  // SUBNET MASK		    				** WRITE ONLY                    
#define   default_gateway	    	 (*((volatile unsigned long *) 0x12000005))  // DEFAULT GATEWAY	 					** WRITE ONLY                
#define   core_port		        	 (*((volatile unsigned long *) 0x12000006))  // CORE PORT		    				** WRITE ONLY                        
#define   target_port		    	 (*((volatile unsigned long *) 0x12000007))  // TARGET PORT		    				** WRITE ONLY                    
#define   udp_max_length	    	 (*((volatile unsigned long *) 0x12000008))  // UDP MAX LENGTH	    				** WRITE ONLY                
#define   group_address	        	 (*((volatile unsigned long *) 0x12000009))  // GROUP ADDRESS	    				** WRITE ONLY                  
#define   udp_length		    	 (*((volatile unsigned long *) 0x1200000A))  // UDP LENGTH		    				** WRITE ONLY                      
                           			                                                                                
#define   udp_config_reg    		 (*((volatile unsigned long *) 0x1200000B))  // PHY LAYER TX CONFIGURE BLOCK		** WRITE ONLY         
                           			                                                                                
#define   udp_status_reg	    	 (*((volatile unsigned long *) 0xD0000006))  // UDP STATUS REGISTER    				** READ  ONLY            
#define   udp_wrfifo_wren	    	 (*((volatile unsigned long *) 0xD0000007))  // UDP WRFIFO_WREN     				** WRITE ONLY             
                           			                                                                                
#define   udp_timeout_value     	 (*((volatile unsigned long *) 0x1200000D))  // UDP MAX LENGTH	    				** WRITE ONLY               
#define   fifo_full_threshold   	 (*((volatile unsigned long *) 0x1200000E))  // GROUP ADDRESS	    				** WRITE ONLY                
#define   fifo_empty_threshold  	 (*((volatile unsigned long *) 0x1200000F))  // UDP LENGTH		    				** WRITE ONLY                  
#define   udp_rdfifo_rden       	 (*((volatile   signed long *) 0x1200000C))  // UDP READ FIFO       				** READ  ONLY             
                                                                                                                     
// MACAW CONFIGURATION REGISTERS                                                                                     

#define   mac_data_fifo				 (*((volatile   signed long *) 0x14000000)) // MACAW MAC DATA FIFO                                                                                                                    
#define   mac_ssid                	 (*((volatile unsigned long *) 0x14000010)) // MACAW MAC SSID                      	** WRITE ONLY
#define   mac_rm_ssid			     (*((volatile unsigned long *) 0x14000020)) // MACAW MAC REMOTE_SSID			    ** WRITE ONLY             
#define   mac_tx_trmtime  	    	 (*((volatile unsigned long *) 0x14000030)) // MACAW MAC TX TRANSMIT TIME  	     	** WRITE ONLY     
#define   mac_txbyte_cnt  	    	 (*((volatile unsigned long *) 0x14000040)) // MACAW MAC TX BYTE COUNT  	        ** WRITE ONLY    
#define   mac_my_backoff_time     	 (*((volatile unsigned long *) 0x14000050)) // MACAW MAC MY BACKOFF TIME           	** WRITE ONLY 
#define   mac_local_backoff_time  	 (*((volatile unsigned long *) 0x14000060)) // MACAW MAC LOCAL BACKOFF TIME        	** WRITE ONLY 
#define   mac_remote_backoff_time 	 (*((volatile unsigned long *) 0x14000070)) // MACAW MAC REMOTE BACKOFF TIME       	** WRITE ONLY 
#define   mac_cfg_retry		  		 (*((volatile unsigned long *) 0x14000080)) // MACAW MAC Config Retry CNT LIMIT    	** WRITE ONLY     
#define   mac_exch_seq_cntr       	 (*((volatile unsigned long *) 0x14000090)) // MACAW MAC EXCHANGE SEQUENCE CNTR    	** WRITE ONLY 
#define   mac_retry_cntr          	 (*((volatile unsigned long *) 0x140000A0)) // MACAW MAC RETRY COUNTER             	** WRITE ONLY
#define   brcst_id                	 (*((volatile unsigned long *) 0x140000B0)) // MACAW MAC BROAD CAST ID             	** WRITE ONLY 

#define   mac_cts_timeout            (*((volatile unsigned long *) 0x140000C0)) // MACAW MAC CTS TIMEOUT VALUE    		** WRITE ONLY
#define   mac_ds_timeout             (*((volatile unsigned long *) 0x140000D0)) // MACAW MAC DS TIMEOUT VALUE    		** WRITE ONLY
#define   mac_data_timeout           (*((volatile unsigned long *) 0x140000E0)) // MACAW MAC DATA TIMEOUT VALUE    		** WRITE ONLY
#define   mac_ack_timeout            (*((volatile unsigned long *) 0x140000F0)) // MACAW MAC ACK TIMEOUT VALUE    		** WRITE ONLY
#define   mac_deframer_soft_rst      (*((volatile unsigned long *) 0xD0000009)) // MACAW MAC DEFRAMER SOFTWARE RST 		** WRITE ONLY
                                                                                                                       	
#define   mac_transmit_strobe		 (*((volatile unsigned long *) 0x14000001)) // MACAW MAC TRANSMIT STROBE           	** WRITE ONLY                	                          
#define   mac_status_reg			 (*((volatile unsigned long *) 0x14000010)) // MACAW MAC STATUS REGISTER           	** READ  ONLY        
#define   mac_ssid_reg				 (*((volatile unsigned long *) 0x14000020)) // MACAW MAC SSID VALUES            	** READ  ONLY           
#define   mac_timer2				 (*((volatile unsigned long *) 0x14000030)) // MACAW MAC BACKOFF TIMERS 1          	** READ  ONLY                                                                                                                           
                            		                                                                                   
#define   watchdog_timer0			 (*((volatile unsigned long *) 0x0E000000)) // WATCHDOG TIMER1                                           
#define   watchdog_timer1			 (*((volatile unsigned long *) 0x0E000001)) // WATCHDOG TIMER2                               		          
                                                                                                                 
#define   pwm_clk_gen	 			 (*((volatile unsigned long *) 0x0A000004)) // PWM CLOCK GENERATOR     				** WRITE ONLY
                   
#define   pwm1_period_tc 			 (*((volatile unsigned long *) 0x0F000000)) // PERIOD TERMAINAL COUNT PWM0			** WRITE ONLY
#define   pwm2_period_tc 			 (*((volatile unsigned long *) 0x0F000010)) // PERIOD TERMAINAL COUNT PWM0			** WRITE ONLY
                
#define   pwm1_dutycycle			 (*((volatile unsigned long *) 0x0F000001)) // PWM0 DUTY CYCLE INPUT VALUE			** WRITE ONLY                    
#define   pwm2_dutycycle			 (*((volatile unsigned long *) 0x0F000011)) // PWM1 DUTY CYCLE INPUT VALUE			** WRITE ONLY
            
#define   encoder1_dutycycle  		 (*((volatile unsigned long *) 0x10000000)) // ENCODER0_DUTY_CYCLE					** READ  ONLY           
#define   encoder2_dutycycle  		 (*((volatile unsigned long *) 0x10000010)) // ENCODER1_DUTY_CYCLE					** READ  ONLY           
                                                                                                                 
//#define   clkdivider_mod			 (*((volatile unsigned long *) 0x0A000006)) // Even Odd Fractional CLK_GEN			** WRITE ONLY                
//#define   strtclk_mod           	 (*((volatile unsigned long *) 0xD0000005)) // CLK MOD GO SIGNAL					** WRITE ONLY 

//***************************************************************************************************************************//
//														CONSTANTS
//**************************************************************************************************************************//

typedef unsigned char      byte;    // Byte is a char
typedef unsigned short int word16;  // 16-bit word is a short int
typedef unsigned int       word32;  // 32-bit word is an int

#define BUFFER_LEN       512L      // Length of command buffer
 
#define Source_Clk 50000000       // in Hz

#define baud_clk  3686400

#define Baud115200 ( baud_clk / ( 115200 * 16 ) ) - 1
#define Baud57600  ( baud_clk / ( 57600  * 16 ) ) - 1
#define Baud38400  ( baud_clk / ( 38400  * 16 ) ) - 1
#define Baud28800  ( baud_clk / ( 28800  * 16 ) ) - 1
#define Baud19200  ( baud_clk / ( 19200  * 16 ) ) - 1
#define Baud14400  ( baud_clk / ( 14400  * 16 ) ) - 1
#define Baud9600   ( baud_clk / ( 9600   * 16 ) ) - 1
#define Baud4800   ( baud_clk / ( 4800   * 16 ) ) - 1
#define Baud2400   ( baud_clk / ( 2400   * 16 ) ) - 1
#define Baud1200   ( baud_clk / ( 1200   * 16 ) ) - 1
#define Baud600    ( baud_clk / ( 600    * 16 ) ) - 1
#define Baud300    ( baud_clk / ( 300    * 16 ) ) - 1


 const int PWM_Clock = Source_Clk / 1000000 / 2;//1 pulse every 1us (counts half-periods)
 const int PWM_TC_300hz = 1000000 / 300;//PWM_Clock drives this, and we need 300 Hz
 
 const int ten_kbps  	= Source_Clk / 10000;
 const int onehun_Kbps 	= Source_Clk / 100000;
 const int fourHun_Kbps = Source_Clk / 400000;
 const int one_Mbps   	= Source_Clk / 1000000; // NOT A VALID SELECTION AT PRESENT
 const int three_Mbps   = Source_Clk / 3000000;

 // SYSTEM INITIALIZATION VALUES VARIABLES.
 
 #define  SPI   0x00535049
 #define  I2C   0x00493243
 #define  SPP1  0x53505031
 #define  SPP2  0x53505032
 #define  SRAM  0x5352414D
 #define  MAC   0x004D4143
 #define  PWM1  0x50574D31
 #define  PWM2  0x50574D32
 #define  PWE1  0x50574531
 #define  PWE2  0x50574532
 #define  CLKG  0x434C4B47
 #define  SoC   0x00536F43
 #define  port  0x706F7274
 #define  cnfg  0x636E6667
 #define  baud	0x62617564 
 #define  data  0x64617461
 
 #define  ModR	0x4D6F6452
 #define  LedR	0x4C656452
 #define  Stat	0x53746174
 #define  SegD	0x53656744
 #define  QsR	0x00517352
 #define  STAT	0x53544154
 #define  SSID	0x53534944
 #define  BCST	0x42435354
 #define  RSID	0x52534944
 #define  RSTD	0x52535444
 #define  DATA	0x44415441
 #define  TOUT	0x544F5554
 #define  EVEN	0x4556454E
 #define  ODD	0x004F4444
 #define  FLOA	0x464C4F41
  
 int BAUD1;
 int BAUD2;
 int I2C_BPS;
 int SPI_BPS;
 int PWM_CLKFREQ;
 int PWM1_DUTYCYC;
 int PWM2_DUTYCYC;
 int UART1_CONFIG;
 int UART2_CONFIG;
 int CLKGEN_EVECFG;
 int CLKGEN_ODDCFG;
 int CLKGEN_FLOATINGCFG;
 int calculated1_dutycycle;
 int calculated2_dutycycle;
 
 const char Tenkbps[]  		= "10Kbps"; 
 const char OnehunKbps[] 	= "100Kbps";
 const char FourhunKbps[] 	= "400Kbps";
 const char OneMbps[]  		= "1Mbps";  
 const char ThreeMbps[]   	= "3Mbps";
 const char UNBAUD[]  		= "UNKNOWN Bit rate";  
 
 const char UART115200[]   = "115200";  
 const char UART57600[]    = "57600";  
 const char UART38400[]    = "38400";  
 const char UART28800[]    = "28800";  
 const char UART19200[]    = "19200";  
 const char UART14400[]    = "14400";  
 const char UART9600[]     = "9600";  
 const char UART4800[]     = "4800";  
 const char UART2400[]     = "2400";  
 const char UART1200[]     = "1200";  
 const char UART600[]      = "600";  
 const char UART300[]      = "300";  
 
 const char hex_str[] = "0123456789ABCDEF";

 const int SAMPLES = 5;
 
 char *i2c_rddata;
 
 const int i2c_write = 0;
 const int i2c_read = 1;
 
 const int write = 2;
 const int readwait = 1;
 const int readnowait = 3;
 const int stop = 1;
 const int no_stop = 0;
  
 // Accelerometer Global Variables *******
 
 #define accelerometer_address  0x53
 
 #define accel_xBias 40
 #define accel_yBias 40
 #define accel_zBias 80
 
 float accel_xAccumulator, accel_yAccumulator, accel_zAccumulator, accel_x_magnitude, 
 	  accel_y_magnitude, accel_z_magnitude, accel_pitch_angle, accel_yaw_angle, accel_roll_angle;
 	  
 int accelSamples;                                                                                                          
                                                                                                                           
 // Gyro Global Variables ***********
 
 float aircraft_pitch_angle;
 float aircraft_yaw_angle;  
 float aircraft_roll_angle;
 float gyro_temperature; 
 
 #define gyroscope_address  0x68  
 
 float gyro_xAccumulator, gyro_yAccumulator, gyro_zAccumulator, gyro_x_angular_rate, gyro_y_angular_rate, gyro_z_angular_rate,
 	  old_gyro_x_angular_rate, old_gyro_y_angular_rate, old_gyro_z_angular_rate, gyro_roll_angle, gyro_yaw_angle, gyro_pitch_angle;
 	  
 int gyroSamples;
 
 
 // GPS Global Variables *********
 
 float gps_xAccumulator, gps_yAccumulator, gps_zAccumulator, gps_x_cordinate, gps_y_cordinate, gps_z_cordinate, gps_altitude, gps_temperature;
 int gpsSamples;
 
 const int GPS_DATA_COUNT = 30;
 
#endif