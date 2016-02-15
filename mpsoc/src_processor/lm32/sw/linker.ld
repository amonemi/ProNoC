OUTPUT_FORMAT("elf32-lm32")
ENTRY(_start)

__DYNAMIC = 0;


_RAM_START = 0x0000000;
_RAM_SIZE  = 0x4000;
_RAM_END   = _RAM_START + _RAM_SIZE;

MEMORY {
  ram    : ORIGIN = 0x00000000, LENGTH = 0x4000          /*  16k */
}

SECTIONS
{
  .text : 
  {
    _ftext = .;
    *(.text .stub .text.* .gnu.linkonce.t.*)
    _etext = .;
  } > ram

  .rodata :
  {
	. = ALIGN(4);
	_frodata = .;
    *(.rodata .rodata.* .gnu.linkonce.r.*)
    *(.rodata1)
	_erodata = .;
  } > ram

  .data : 
  {
	. = ALIGN(4);
	_fdata = .;
    *(.data .data.* .gnu.linkonce.d.*)
    *(.data1)
    _gp = ALIGN(16);
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    _edata = .;
  } > ram

  .bss :
  {
	. = ALIGN(4);
    _fbss = .;
    *(.dynsbss)
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
    *(.dynbss)
    *(.bss .bss.* .gnu.linkonce.b.*)
    *(COMMON)
    _ebss = .;
    _end = .;
  } > ram
}

PROVIDE(_fstack = ORIGIN(ram) + LENGTH(ram) - 4);
