#ifndef INTRRUPT_TEST_SYSTEM_H
	#define INTRRUPT_TEST_SYSTEM_H
 
 
 /*  ram   */ 
 #define RAM_BASE_ADDR0 		 	0X00000000
 #define RAM_BASE_ADDR 		 	RAM_BASE_ADDR0
 
 
 /*  aeMB   */ 
 
 
 /*  ss   */ 
 
 
 /*  ext_int   */ 
 //intrrupt flag location
  #define EXT_INT_INT (1<<0)
 #define EXT_INT_BASE_ADDR0 		 	0X9e000000
 #define EXT_INT_BASE_ADDR 		 	EXT_INT_BASE_ADDR0
 
	#define EXT_INT_GER	   		(*((volatile unsigned int *) (EXT_INT_BASE_ADDR	)))
	#define EXT_INT_IER_RISE		(*((volatile unsigned int *) (EXT_INT_BASE_ADDR+4	)))
	#define EXT_INT_IER_FALL		(*((volatile unsigned int *) (EXT_INT_BASE_ADDR+8	)))
	#define EXT_INT_ISR 			(*((volatile unsigned int *) (EXT_INT_BASE_ADDR+12	)))
	#define EXT_INT_RD   			(*((volatile unsigned int *) (EXT_INT_BASE_ADDR+16	)))
 
 
 /*  seg0   */ 
 #define SEG0_BASE_ADDR0 		 	0X91000000
 #define SEG0_BASE_ADDR 		 	SEG0_BASE_ADDR0
 
	#define	 SEG0_WRITE_REG	   		(*((volatile unsigned int *) (SEG0_BASE_ADDR+4)))
	#define 	SEG0_WRITE(value)		       SEG0_WRITE_REG=value	


 
 
 /*  seg1   */ 
 #define SEG1_BASE_ADDR0 		 	0X91000020
 #define SEG1_BASE_ADDR 		 	SEG1_BASE_ADDR0
 
	#define	 SEG1_WRITE_REG	   		(*((volatile unsigned int *) (SEG1_BASE_ADDR+4)))
	#define 	SEG1_WRITE(value)		       SEG1_WRITE_REG=value	


 
 
 /*  int_ctrl   */ 
 #define INT_CTRL_BASE_ADDR0 		 	0X9e000020
 #define INT_CTRL_BASE_ADDR 		 	INT_CTRL_BASE_ADDR0
 
	#define	 INT_CTRL_MER		       (*((volatile unsigned int *) (INT_CTRL_BASE_ADDR	)))
	#define	INT_CTRL_IER			(*((volatile unsigned int *) (INT_CTRL_BASE_ADDR+4	)))
	#define 	INT_CTRL_IAR			(*((volatile unsigned int *) (INT_CTRL_BASE_ADDR+8	)))
	#define 	INT_CTRL_IPR			(*((volatile unsigned int *) (INT_CTRL_BASE_ADDR+12	)))
 
 
 /*  timer   */ 
 //intrrupt flag location
  #define TIMER_INT (1<<1)
 #define TIMER_BASE_ADDR0 		 	0X96000000
 #define TIMER_BASE_ADDR 		 	TIMER_BASE_ADDR0
 #define TIMER_TCSR0	   			(*((volatile unsigned int *) (TIMER_BASE_ADDR	)))
		
/*
//timer control register
TCSR0
bit
6-3	:	clk_dev_ctrl
3	:	timer_isr
2	:	rst_on_cmp_value
1	:	int_enble_on_cmp_value
0	:	timer enable 
*/	
	#define TIMER_TLR0	   			(*((volatile unsigned int *) (TIMER_BASE_ADDR+4	)))
	#define TIMER_TCMP0	   			(*((volatile unsigned int *) (TIMER_BASE_ADDR+8	)))
#ifndef	TIMER_EN
	#define TIMER_EN			(1 << 0)
	#define TIMER_INT_EN			(1 << 1)
	#define TIMER_RST_ON_CMP		(1 << 2)
#endif
 
 
 /*  bus   */ 
 #endif
