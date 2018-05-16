

//function from int.c
	/* Initialize routine */
	extern int int_init();

	
	/* Add interrupt handler */ 
	extern int int_add(unsigned long vect, void (* handler)(void *), void *arg);

	/* Add exception vector handler */
	extern void add_handler(unsigned long vector, void (* handler) (void));


	/* Disable interrupt */ 
	extern int int_disable(unsigned long );

	/* Enable interrupt */ 
	extern int int_enable(unsigned long );

	/* Main interrupt handler */
	extern void int_main(); 

	extern void int_clear_all_pending(void);
	




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
 
