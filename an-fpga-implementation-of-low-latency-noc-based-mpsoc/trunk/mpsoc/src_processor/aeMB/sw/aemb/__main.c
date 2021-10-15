#ifndef _AEMB_MAIN_HH
#define  _AEMB_MAIN_HH

extern char __rodata_end, __data_start, __sdata_end;

extern int main ();

extern "C" int __main (void){ //initial_global_data
	
	char *src = &__rodata_end;  //start of Data section in Rom
	char *dst = &__data_start;

	/* ROM has data at end of rodata; copy it. */
	while (dst < &__sdata_end) {
  		*dst++ = *src++;
	}
	 main(); //call the main function
	return 0;
}





#endif
