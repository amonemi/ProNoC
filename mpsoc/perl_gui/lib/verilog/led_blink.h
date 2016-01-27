#ifndef LED_BLINK_SYSTEM_H
	#define LED_BLINK_SYSTEM_H
 
 #include <stdio.h> 
 #include <stdlib.h> 
 #include "aemb/core.hh" 
 
 /*  ram   */ 
 #define RAM_BASE_ADDR0 		 	0X00000000
 #define RAM_BASE_ADDR 		 	RAM_BASE_ADDR0
 
 
 /*  aeMB   */ 
 
 
 /*  ss   */ 
 
 
 /*  led   */ 
 #define LED_BASE_ADDR0 		 	0X91000000
 #define LED_BASE_ADDR 		 	LED_BASE_ADDR0
 
	#define	 LED_WRITE_REG	   		(*((volatile unsigned int *) (LED_BASE_ADDR+4)))
	#define 	LED_WRITE(value)		       LED_WRITE_REG=value	


 
 
 /*  bus   */ 
 #endif
