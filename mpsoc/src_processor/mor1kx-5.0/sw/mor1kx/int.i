# 1 "int.c"
# 1 "/work/mor1kx-dev-env/sw/drivers/or1200//"
# 1 "<command-line>"
# 1 "int.c"






# 1 "../../drivers/or1200/include/or1200-utils.h" 1




# 1 "../../drivers/or1200/include/int.h" 1







struct ihnd {
 void (*handler)(void *);
 void *arg;
};


int int_add(unsigned long vect, void (* handler)(void *), void *arg);


void add_handler(unsigned long vector, void (* handler) (void));


int int_init();


void int_main();
# 6 "../../drivers/or1200/include/or1200-utils.h" 2
# 25 "../../drivers/or1200/include/or1200-utils.h"
void mtspr(unsigned long spr, unsigned long value);


unsigned long mfspr(unsigned long spr);


void sim_putc(unsigned char c);


void report(unsigned long value);


void exit(int i);


void cpu_enable_user_interrupts(void);


extern unsigned long timer_ticks;

void cpu_enable_timer(void);

void cpu_disable_timer(void);

void cpu_timer_tick(void);

void cpu_reset_timer_ticks(void);

unsigned long cpu_get_timer_ticks(void);

void cpu_sleep_10ms(void);
# 8 "int.c" 2
# 1 "../../drivers/or1200/include/spr-defs.h" 1
# 9 "int.c" 2
# 1 "../../drivers/or1200/include/int.h" 1
# 10 "int.c" 2


struct ihnd int_handlers[32];


int int_init()
{
  int i;

  for(i = 0; i < 32; i++) {
    int_handlers[i].handler = 0;
    int_handlers[i].arg = 0;
  }

  return 0;
}


int int_add(unsigned long irq, void (* handler)(void *), void *arg)
{
  if(irq >= 32)
    return -1;

  int_handlers[irq].handler = handler;
  int_handlers[irq].arg = arg;

  mtspr(((9<< (11)) + 0), mfspr(((9<< (11)) + 0)) | (0x00000001L << irq));

  return 0;
}


int int_disable(unsigned long irq)
{
  if(irq >= 32)
    return -1;

  mtspr(((9<< (11)) + 0), mfspr(((9<< (11)) + 0)) & ~(0x00000001L << irq));

  return 0;
}


int int_enable(unsigned long irq)
{
  if(irq >= 32)
    return -1;

  mtspr(((9<< (11)) + 0), mfspr(((9<< (11)) + 0)) | (0x00000001L << irq));

  return 0;
}


void int_main()
{
  unsigned long picsr = mfspr(((9<< (11)) + 2));
  unsigned long i = 0;

  mtspr(((9<< (11)) + 2), 0);

  while(i < 32) {
    if((picsr & (0x01L << i)) && (int_handlers[i].handler != 0)) {
      (*int_handlers[i].handler)(int_handlers[i].arg);





       mtspr(((9<< (11)) + 2), mfspr(((9<< (11)) + 2)) & ~(0x00000001L << i));
    }
    i++;
  }
}
