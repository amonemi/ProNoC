
#include "eth_test.h"

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



// a simple delay function
void delay ( unsigned int num ){
	
	while (num>0){ 
		num--;
		asm volatile ("nop");
	}
	return;

}

void myISR( void ) __attribute__ ((interrupt_handler));

void myISR( void )
{
	
	if( int_ctrl_IPR & ETHMAC_INT )	ethmac_interrupt();
	int_ctrl_IAR = ETHMAC_INT;		// Acknowledge Interrupts
}


int main(){
	//delay(15500000);
	ethmac_init();
	xil_printf("start\n");
	ethmac_tx_data[0] = 0xFF;
	ethmac_tx_data[1] = 0x2B;
	ethmac_tx_data[2] = 0x40;
	ethmac_tx_data[3] = 0x50;

	

	int_ctrl_IER=  ETHMAC_INT;
	int_ctrl_MER=	0x3;	

	aemb_enable_interrupt ();
	
	while(1){
		ethmac_send(4);
		delay(500000);
		//xil_printf("sent\n");

	}

return 0;
}

