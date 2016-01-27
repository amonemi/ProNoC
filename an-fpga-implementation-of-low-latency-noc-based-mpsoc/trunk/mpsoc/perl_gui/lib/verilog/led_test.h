#ifndef LED_TEST_SYSTEM_H
	#define LED_TEST_SYSTEM_H
 
 
 /*  Altera_ram0   */ 
 #define ALTERA_RAM0_BASE_ADDR0 		 	0X00000000
 #define ALTERA_RAM0_BASE_ADDR 		 	ALTERA_RAM0_BASE_ADDR0
 
 
 /*  aeMB   */ 
 
 
 /*  ss   */ 
 
 
 /*  ledg   */ 
 #define LEDG_BASE_ADDR0 		 	0X91000020
 #define LEDG_BASE_ADDR 		 	LEDG_BASE_ADDR0
 
	#define	 LEDG_WRITE_REG	   		(*((volatile unsigned int *) (LEDG_BASE_ADDR+4)))
	#define 	LEDG_WRITE(value)		       LEDG_WRITE_REG=value	


 
 
 /*  ledr   */ 
 #define LEDR_BASE_ADDR0 		 	0X91000000
 #define LEDR_BASE_ADDR 		 	LEDR_BASE_ADDR0
 
	#define	 LEDR_WRITE_REG	   		(*((volatile unsigned int *) (LEDR_BASE_ADDR+4)))
	#define 	LEDR_WRITE(value)		       LEDR_WRITE_REG=value	


 
 
 /*  bus   */ 
 #endif
