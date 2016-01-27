#include "compile/orsocdef.h"
//#include <stdlib.h>

#include "intrupt_test.h"

// external intrrupt flag definition
#define EXT_INT_0	(1<<0)
#define EXT_INT_1	(1<<1)





void timer_ISR( void );
void ext_int_ISR( void );
void display_on_seg(unsigned int);


/*!
* Assembly macro to enable MSR_IE
*/
void aemb_enable_interrupt ()
{
  int msr, tmp;
  asm volatile ("mfs %0, rmsr;"
		"ori %1, %0, 0x02;"
		"mts rmsr, %1;"
		: "=r"(msr)
		: "r" (tmp)
		);
}



unsigned int i;

void myISR( void ) __attribute__ ((interrupt_handler));

void myISR( void )
{
	
	if( INT_CTRL_IPR & TIMER_INT )	timer_ISR();
	if( INT_CTRL_IPR & EXT_INT_INT)		ext_int_ISR(); 
	INT_CTRL_IAR = INT_CTRL_IPR;		// Acknowledge Interrupts
}

#define UP	0
#define DOWN	1
unsigned int counter_mode= UP;
void timer_ISR( void )
{
// Do Stuff Here
	i = (counter_mode == UP)? i+1 : i-1;
	display_on_seg(i);
	TIMER_TCSR0 = TIMER_TCSR0;
	
// Acknogledge Interrupt In Timer (Clear pending bit)
}

inline void ext_int_0(){
	i=0;
}

inline void ext_int_1(){
	counter_mode= (counter_mode==UP)? DOWN : UP;
}

void ext_int_ISR( void )
{
// Do Stuff Here
	if(EXT_INT_ISR  & EXT_INT_0)	ext_int_0();	
	if(EXT_INT_ISR  & EXT_INT_1)	ext_int_1();	
	EXT_INT_ISR 	= EXT_INT_ISR;
// Clear any pending button interrupts
}




const unsigned int seven_seg_tab [16] = {0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E, 0x79,0x71};
void display_on_seg(unsigned int num){
	unsigned int seg1=num%10;
	unsigned int seg2=(num/10)%10;	
	SEG0_WRITE(~seven_seg_tab[seg1]);
	SEG1_WRITE(~seven_seg_tab[seg2]);

}

int main(){
	
	i=0;
 	
	SEG0_WRITE(~seven_seg_tab[2]);
	SEG1_WRITE(~seven_seg_tab[2]);
// intrrupt setting 

	EXT_INT_IER_RISE=EXT_INT_0 | EXT_INT_1;
	EXT_INT_GER =	0x3;


	TIMER_TCMP0	=	5000000;
	TIMER_TCSR0   =	( TIMER_EN | TIMER_INT_EN | TIMER_RST_ON_CMP);

	INT_CTRL_IER=	EXT_INT_INT | TIMER_INT;
	INT_CTRL_MER=	0x3;	

	
	
	aemb_enable_interrupt ();
	while(1)
	{
		
	}//while
	 return 0;

}





