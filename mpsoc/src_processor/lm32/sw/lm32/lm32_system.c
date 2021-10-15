
#ifndef  LM32_SYS_C
	#define LM32_SYS_C
	 
/***************************************************************************
 * IRQ handling
 */

/****************************************************************************
 * Types
 */
#include <stdint.h>

/****************************************************************************/




isr_ptr_t isr_table[32];



void isr_null()
{

}

void irq_handler(uint32_t pending)
{
	int i;

	for(i=0; i<32; i++) {
		if (pending & 0x01) (*isr_table[i])();
		pending >>= 1;
	}
}

void isr_init()
{
	int i;
	for(i=0; i<32; i++)
		isr_table[i] = &isr_null;
}

void isr_register(int irq, isr_ptr_t isr)
{
	isr_table[irq] = isr;
}

void isr_unregister(int irq)
{
	isr_table[irq] = &isr_null;
}





/******************
*	General inttrupt functions for all CPUs added to ProNoC
*******************/



int general_int_add(unsigned long irq, isr_ptr_t handler, void *arg)
{
	
	isr_register(irq, handler);
        return 0;
}



void general_int_enable(unsigned long irq){
	irq_set_mask( (0x00000001L << irq)| irq_get_mask() );
	
}


extern char _erodata, _fdata,_edata;
void __main (void){ //initial_global_data
	
	char *src = &_erodata;  //start of Data section in Rom
	char *dst = &_fdata;

	/* ROM has data at end of rodata; copy it. */
	while (dst < &_edata) {
  	*dst++ = *src++;
	}
	
	main(); //call the main function now
}


#endif
