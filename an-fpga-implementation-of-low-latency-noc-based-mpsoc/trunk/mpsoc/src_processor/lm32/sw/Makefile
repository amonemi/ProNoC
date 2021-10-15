include cpu_flags

SOURCE_LIB =
include SOURCE_LIB

HDR_SOURCE_DIR=lm32

TOOLCHAIN=$(PRONOC_WORK)/toolchain/lm32
IHEX2MIF =$(PRONOC_WORK)/toolchain/bin/ihex2mif
IHEX2BIN =$(PRONOC_WORK)/toolchain/bin/ihex2bin
BIN2HEX =$(PRONOC_WORK)/toolchain/bin/bin2str
BIN2MIF=$(PRONOC_WORK)/toolchain/bin/bin2mif
BIN2MEM=$(PRONOC_WORK)/toolchain/bin/bin2mem

LM32_TOOL_PREFIX=${TOOLCHAIN}/bin/lm32-elf-

LM32_LD=$(LM32_TOOL_PREFIX)ld
LM32_AS=$(LM32_TOOL_PREFIX)as
LM32_CC=$(LM32_TOOL_PREFIX)gcc
LM32_AR=$(LM32_TOOL_PREFIX)ar
LM32_OBJDUMP=$(LM32_TOOL_PREFIX)objdump
LM32_OBJCOPY=$(LM32_TOOL_PREFIX)objcopy
LM32_LIB1=${TOOLCHAIN}/lm32-elf/lib
LM32_LIB2=${TOOLCHAIN}/lib/gcc/lm32-elf/4.5.3

LIBRARIES = -L${LM32_LIB1} -L${LM32_LIB2} -L.  -L./$(HDR_SOURCE_DIR) -lc -lg   -lorlib -lgcc 

CFLAGS  := -Wall -Os -ggdb  ${CPU_FLAGS}
LDFLAGS=-nostdlib -nodefaultlibs -Tlinker.ld 


# Sources to go into the liborpsoc.a support library
COMPILE_SRCS=   $(SOURCE_LIB)

#CPU_FLAGS=-mbarrel-shift-enabled -mmultiply-enabled 


#LDFLAGS=-nostdlib -T -Tlinker.ld
SEGMENTS = -j .text -j .rodata -j .data

all: image.ihex

lib:
#compile all source code
	$(LM32_CC) -Wall $(CFLAGS) -c $(HDR_SOURCE_DIR)/crt0ram.S  -o crt0ram.o
	$(LM32_CC) -Wall $(CFLAGS) -c $(COMPILE_SRCS) 
#add them to liborlib.a
	$(LM32_AR) -cvq liborlib.a *.o


main.o: lib main.c
	$(LM32_CC) -Wall $(CFLAGS) -c main.c  -o main.o
	
image: main.o  linker.ld Makefile 
	$(LM32_LD) $(LDFLAGS) -Map image.map -N -o image crt0ram.o  main.o $(LIBRARIES)

image.lst: image
	$(LM32_OBJDUMP) -h -S $< > $@


image.ihex: image image.lst
# Convert the ELF file to an IHEX file
	mkdir -p ./RAM
	$(LM32_OBJCOPY) -O ihex image image.ihex
#	$(LM32_OBJCOPY)   --keep-file-symbols -O binary image image.bin
# Generate a MIF & BIN files from the IHEX file
#	$(IHEX2MIF) -f image.ihex -e $(RAMSIZE) -o RAM/ram0.mif
#	$(IHEX2MIF) -f image.ihex -o RAM/ram0.mif
	$(IHEX2BIN) -i image.ihex -o RAM/ram0.bin
	$(BIN2MIF)  -f RAM/ram0.bin -o RAM/ram0.mif -w 32
	$(BIN2MEM)  -f RAM/ram0.bin -o RAM/ram0.mem -w 32
	$(BIN2HEX)  -f RAM/ram0.bin -h   
	rm *.o *.a




clean:
	rm -f image.ihex  image image.lst image.bin image.srec image.map  image.ram image.hex RAM/* *.o *.a



DEPS := $(wildcard *.d)
ifneq ($(DEPS),)
include $(DEPS)
endif


