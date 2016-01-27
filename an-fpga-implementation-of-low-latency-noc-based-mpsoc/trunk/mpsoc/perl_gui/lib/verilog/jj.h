#ifndef JJ_SYSTEM_H
	#define JJ_SYSTEM_H
 
 #include <stdio.h> 
 #include <stdlib.h> 
 #include "aemb/core.hh" 
 
 /*  aeMB0   */ 
 
 
 /*  aeMB2   */ 
 
 
 /*  gpi0   */ 
    


#define GPI0_READ_REG   (*((volatile unsigned int *) (GPI0_BASE_ADDR+8)))
   
 
#define GPI0_READ()  	 GPI0_READ_REG	
 #endif
