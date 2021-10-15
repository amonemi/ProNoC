OUTPUT_ARCH(or1knd)
SEARCH_DIR(.)
__DYNAMIC  =  0;

INCLUDE linkvar.ld;



/* Stack information variables */
_min_stack      = 0x2000;   /* 8K - minimum stack space to reserve */


SECTIONS
{	
	.vectors :
	{
		*(.vectors)
	} > rom
                              
	.text 0x1000 : {
		_stext = .;
		*(.text)
		_etext  =  .;
		__CTOR_LIST__ = .;
		LONG((__CTOR_END__ - __CTOR_LIST__) / 4 - 2)
		*(.ctors)
		LONG(0)
		__CTOR_END__ = .;
		__DTOR_LIST__ = .;
		LONG((__DTOR_END__ - __DTOR_LIST__) / 4 - 2)
		*(.dtors)
		LONG(0)
		__DTOR_END__ = .;
		*(.lit)
		*(.shdata)
		_endtext = .;
	}  > rom

	.rodata : {
               	_srodata = .;
		*(.rodata);
		*(.rodata.*)
		. = ALIGN(0x10);
             	_erodata = .;
	} > rom
	
	.shbss :
	{
		*(.shbss)
	} > ram
	
	.talias :
	{ 
	}  > ram
	
	.data : {
		sdata  =  .;
		_sdata  =  .;
		*(.data)
		edata  =  .;
		. = ALIGN(0x4);
		_edata  =  .;
	} > ram AT > rom  /* "> ram" is the VMA, "> rom" is the LMA */
	
	.bss :
	{
		_bss_start = .;
		*(.bss)
		*(COMMON)
		_bss_end = .;
	} > ram
	
	/* ensure there is enough room for stack */
        .stack (NOLOAD): {
                . = ALIGN(4);
		. = . + _min_stack ;
                . = ALIGN(4);
                stack = . ;
                _stack = . ;
        } > ram
	
	.stab  0 (NOLOAD) : 
	{
		[ .stab ]
	}
	
	.stabstr  0 (NOLOAD) :
	{
		[ .stabstr ]
	}
}
