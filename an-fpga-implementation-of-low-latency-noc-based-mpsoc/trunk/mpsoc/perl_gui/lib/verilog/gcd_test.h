#ifndef GCD_TEST_SYSTEM_H
	#define GCD_TEST_SYSTEM_H
 
 
 /*  ram   */ 
 #define RAM_BASE_ADDR0 		 	0X00000000
 #define RAM_BASE_ADDR 		 	RAM_BASE_ADDR0
 
 
 /*  aeMB   */ 
 
 
 /*  ss   */ 
 
 
 /*  gcd   */ 
 #define GCD_BASE_ADDR0 		 	0Xb8000000
 #define GCD_BASE_ADDR 		 	GCD_BASE_ADDR0
 
	#define  GCD_DONE_ADDR	 (*((volatile unsigned int *) (GCD_BASE_ADDR  )))
	 #define  GCD_IN_1_ADDR		(*((volatile unsigned int *) (GCD_BASE_ADDR+4)))
	 #define GCD_IN_2_ADDR		(*((volatile unsigned int *) (GCD_BASE_ADDR+8)))
	 #define GCD_GCD_ADDR		 (*((volatile unsigned int *) (GCD_BASE_ADDR+12)))

	#define GCD_IN1_WRITE(value)  GCD_IN_1_ADDR=value
	#define GCD_IN2_WRITE(value)  GCD_IN_2_ADDR=value
	
	#define   GCD_DONE_READ()     GCD_DONE_ADDR
	#define  GCD_GCD_READ()         GCD_GCD_ADDR
 
 
 /*  display   */ 
 #define DISPLAY_BASE_ADDR0 		 	0X91000000
 #define DISPLAY_BASE_ADDR 		 	DISPLAY_BASE_ADDR0
 
	#define	 DISPLAY_WRITE_REG	   		(*((volatile unsigned int *) (DISPLAY_BASE_ADDR+4)))
	#define 	DISPLAY_WRITE(value)		       DISPLAY_WRITE_REG=value	


 
 
 /*  bus   */ 
 #endif
