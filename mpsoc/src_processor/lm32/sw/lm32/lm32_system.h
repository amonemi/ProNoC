
#ifndef  LM32_SYS_H
	#define LM32_SYS_H
	 
/***************************************************************************
 * IRQ handling
 */

/****************************************************************************
 * Types
 */
#include <stdint.h>

/****************************************************************************/



typedef void(*isr_ptr_t)(void);
void     halt();
void     jump(uint32_t addr);


void isr_null(void);
void irq_handler(uint32_t pending);
void isr_init(void);
void isr_register(int irq, isr_ptr_t isr);
void isr_unregister(int irq);





/******************
*	General inttrupt functions for all CPUs added to ProNoC
*******************/

extern void irq_set_mask (unsigned long);
extern unsigned long irq_get_mask(void);
extern void irq_enable (void);

#define general_int_init isr_init

int general_int_add(unsigned long irq, isr_ptr_t handler, void *arg);
void general_int_enable(unsigned long irq);

#define  general_cpu_int_en	irq_enable


void __main (void); //initial_global_data







#endif
