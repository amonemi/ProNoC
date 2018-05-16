

//function from int.c
int int_init(void);

/* Add interrupt handler */ 
int int_add(unsigned long , void (* handler)(void *), void *);

/* Disable interrupt */ 
int int_disable(unsigned long );


/* Enable interrupt */ 
int int_enable(unsigned long );


/* Main interrupt handler */
void int_main();


// exception.c

void add_handler(unsigned long , void (*handler) (void));

void default_exception_handler_c(unsigned ,unsigned);

//spr-defs

void  mtspr(unsigned long, unsigned long );

/* For reading SPR. */
unsigned long mfspr(unsigned long );


/* Print out a character via simulator */
void sim_putc(unsigned char );


/* print long */
void report(unsigned long );


/* Loops/exits simulation */
void exit (int );


/* Enable user interrupts */
void cpu_enable_user_interrupts(void);



/* Tick timer functions */
/* Enable tick timer and interrupt generation */
void cpu_enable_timer(void);


/* Disable tick timer and interrupt generation */
void cpu_disable_timer(void);


/* Timer increment - called by interrupt routine */
void cpu_timer_tick(void);


/* Reset tick counter */
void  cpu_reset_timer_ticks(void);

/* Get tick counter */
unsigned long cpu_get_timer_ticks(void);


/* Wait for 10ms, assumes CLK_HZ is 100, which it usually is.
   Will be slightly inaccurate!*/
void cpu_sleep_10ms(void);
 
