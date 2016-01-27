#include "compile/orsocdef.h"
//#include <stdlib.h>

#include "led_tim.h"

void timer_ISR( void );


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
	INT_CTRL_IAR = INT_CTRL_IPR;		// Acknowledge Interrupts
}


void timer_ISR( void )
{
// Do Stuff Here
	i++;
	LED_WRITE(i);
	TIMER_TCSR0 = TIMER_TCSR0;
	
// Acknogledge Interrupt In Timer (Clear pending bit)
}


int main(){
	
	i=0;
 	LED_WRITE(0);		
	

	TIMER_TCMP0	=	5000000;
	TIMER_TCSR0   =	( TIMER_EN | TIMER_INT_EN | TIMER_RST_ON_CMP);

	INT_CTRL_IER=	TIMER_INT;
	INT_CTRL_MER=	0x3;	

	LED_WRITE(0);	
	
	aemb_enable_interrupt ();
	while(1)
	{
		
	}//while
	 return 0;

}





