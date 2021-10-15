OUTPUT_FORMAT("elf32-lm32")
SEARCH_DIR(.)
ENTRY(_start)

__DYNAMIC = 0;

INCLUDE linkvar.ld;



SECTIONS
{
  . = ALIGN(4);
  .text : 
  {
    _ftext = .;
    *(.text .stub .text.* .gnu.linkonce.t.*)
    _etext = .;
  } > rom

  .rodata :
  {
    . = ALIGN(4);
    _frodata = .;
    *(.rodata .rodata.* .gnu.linkonce.r.*)
    *(.rodata1)
    . = ALIGN(0x10);
    _erodata = .;
  } > rom

  .data : 
  {
    . = ALIGN(4);
    _fdata = .;
    *(.data .data.* .gnu.linkonce.d.*)
    *(.data1)
    _gp = ALIGN(16);
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    _edata = .;
  } > ram AT > rom  /* "> ram" is the VMA, "> rom" is the LMA */

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
