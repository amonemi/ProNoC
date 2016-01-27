#ifndef SIM_25P_SYSTEM_H
	#define SIM_25P_SYSTEM_H
 
 #include <stdio.h> 
 #include <stdlib.h> 
 #include "aemb/core.hh" 
 
 /*  ram   */ 
 #define RAM_BASE_ADDR0 		 	0X00000000
 #define RAM_BASE_ADDR 		 	RAM_BASE_ADDR0
 
 
 /*  aeMB0   */ 
 
 
 /*  ss   */ 
 
 
 /*  led   */ 
 #define LED_BASE_ADDR0 		 	0X91000000
 #define LED_BASE_ADDR 		 	LED_BASE_ADDR0
    
#define LED_DIR_REG   (*((volatile unsigned int *) (LED_BASE_ADDR)))   
#define LED_WRITE _REG  (*((volatile unsigned int *) (LED_BASE_ADDR+4)))
#define LED_READ_REG   (*((volatile unsigned int *) (LED_BASE_ADDR+8)))
   
 #define LED_DIR_SET(value)   LED_DIR_REG=value	  
#define LED_WRITE(value)  LED_WRITE _REG=value	
#define LED_READ()  	 LED_READ_REG	
 
 
 /*  nn   */ 
 #define NN_BASE_ADDR0 		 	0Xb8000000
 #define NN_BASE_ADDR 		 	NN_BASE_ADDR0
 	 #define NN_CLASS_IN_HDR_WIDTH      8
         #define NN_DEST_IN_HDR_WIDTH       8
         #define NN_X_Y_IN_HDR_WIDTH        4
        
	#define	NN_BUSY			(1<<0)
	#define	NN_WR_DONE			(1<<1)
	#define	NN_RD_DONE			(1<<2)
	#define 	NN_RD_OVR_ERR			(1<<3)
	#define	NN_RD_NPCK_ERR			(1<<4)
	#define	NN_HAS_PCK			(1<<5)
	#define	NN_ALL_VCS_FULL		(1<<6)
	#define	NN_WR_DONE_INT_EN		(1<<7)
	#define	NN_RD_DONE_INT_EN		(1<<8)
	#define	NN_RSV_PCK_INT_EN		(1<<9)
	#define	NN_WR_DONE_ISR			(1<<10)
	#define	NN_RD_DONE_ISR			(1<<11)
	#define	NN_RSV_PCK_ISR			(1<<12)
	
		
	
	#define NN_PTR_WIDTH			19
	#define	NN_PCK_SIZE_WIDTH		13


	#define NN_RD			   	(*((volatile unsigned int *) (NN_BASE_ADDR	)))
	#define NN_WR			   	(*((volatile unsigned int *) (NN_BASE_ADDR+4)))
	#define NN_ST	   			(*((volatile unsigned int *) (NN_BASE_ADDR+8)))

	#define NN_HDR_DEST_CORE_ADDR(DES_X, DES_Y)	((DES_X << NN_X_Y_IN_HDR_WIDTH) | DES_Y)<<(2*NN_X_Y_IN_HDR_WIDTH)	
	#define NN_HDR_CLASS(pck_class)			(pck_class << ( NN_DEST_IN_HDR_WIDTH+  (4* NN_X_Y_IN_HDR_WIDTH)))

	
	#define NN_wait_for_sending_pck()		while (!(NN_ST & NN_WR_DONE))
	#define NN_wait_for_reading_pck()		while (!(NN_ST & NN_RD_DONE))

	#define NN_wait_for_getting_pck()		while (!(NN_ST & NN_HAS_PCK))

/*****************************************
void  send_pck (unsigned int * pck_buffer, unsigned int data_size);
sending a packet through NoC network;
(unsigned int des_x,unsigned int des_y : destination core address;
unsigned int * pck_buffer : the buffer which hold the packet; The data must start from buff[1];
unsigned int data_size     : the size of data which wanted to be sent out in word = packet_size-1;
unsigned int class  

****************************************/
	inline void  NN_send_pck (unsigned int des_x, unsigned int des_y, volatile unsigned int * pck_buffer, unsigned int data_size, unsigned int pck_class){
		pck_buffer [0]		= 	NN_HDR_DEST_CORE_ADDR(des_x, des_y) | NN_HDR_CLASS(pck_class) ;
		NN_WR = (unsigned int) (& pck_buffer [0]) + (data_size<<NN_PTR_WIDTH);
		NN_wait_for_sending_pck();

	}

/*******************************************
void  save_pck	(volatile unsigned int * pck_buffer, unsigned int buffer_size);
save a received packet on pck_buffer
unsigned int * pck_buffer: the buffer for storing the packet; The read data start from buff[1]; 
********************************************/
	inline void  NN_save_pck	(volatile unsigned int * pck_buffer, unsigned int buffer_size){
		NN_RD = (unsigned int) (& pck_buffer [0]) + (buffer_size<<NN_PTR_WIDTH);
		NN_wait_for_reading_pck();
	}
 
 
 /*  bus   */ 
 #endif
