TOOLCHAIN=$(PRONOC_WORK)/toolchain/lm32
IHEX2MIF =$(PRONOC_WORK)/toolchain/ihex2mif/ihex2mif


#SREC2VRAM ?= ../../../toolchain/lm32/srec2vram/srec2vram

RAMSIZE=3FFF
#CPU_FLAGS=-mbarrel-shift-enabled -mmultiply-enabled -msign-extend-enabled -mdivide-enabled
CPU_FLAGS=-mbarrel-shift-enabled -mmultiply-enabled 

LM32_CC=${TOOLCHAIN}/bin/lm32-elf-gcc
LM32_LD=${TOOLCHAIN}/bin/lm32-elf-ld
LM32_OBJCOPY=${TOOLCHAIN}/bin/lm32-elf-objcopy
LM32_OBJDUMP=${TOOLCHAIN}/bin/lm32-elf-objdump
LM32_LIB1=${TOOLCHAIN}/lm32-elf/lib
LM32_LIB2=${TOOLCHAIN}/lib/gcc/lm32-elf/4.5.3

LIBRARIES = -L${LM32_LIB1} -lc -lg  -L${LM32_LIB2}  -lgcc 

VRAMFILE=image.ram

#CFLAGS=-MMD -O2 -Wall -g -s -fomit-frame-pointer ${CPU_FLAGS}
CFLAGS  := -Wall -Os -ggdb -ffreestanding ${CPU_FLAGS}
LDFLAGS=-nostdlib -nodefaultlibs -Tlinker.ld 
#LDFLAGS=-nostdlib -T -Tlinker.ld
SEGMENTS = -j .text -j .rodata -j .data

all: image.srec $(VRAMFILE) 

crt0ram.o: crt0ram.S
	$(LM32_CC) $(CFLAGS) -c crt0ram.S

main.o: main.c
	$(LM32_CC) $(CFLAGS) -c main.c

#soc-hw.o: soc-hw.c
#$(LM32_CC) $(CFLAGS) -c soc-hw.c

image: crt0ram.o main.o  linker.ld Makefile 
	$(LM32_LD) $(LDFLAGS) -Map image.map -N -o image crt0ram.o main.o ${LIBRARIES}

image.lst: image
	$(LM32_OBJDUMP) -h -S $< > $@

image.bin: image
	$(LM32_OBJCOPY) $(SEGMENTS) -O binary image image.bin

image.srec: image image.lst image.bin
#$(LM32_OBJCOPY) $(SEGMENTS) -O srec image image.srec
	$(LM32_OBJCOPY) $(SEGMENTS) -O ihex image image.ihex

$(VRAMFILE): image.srec
#$(SREC2VRAM) image.srec 0x40000000 0x1000 > $(VRAMFILE)
	$(IHEX2MIF) -f image.ihex  -e $(RAMSIZE) -o ram00.mif

clean:
	rm -f image.ihex  image image.lst image.bin image.srec image.map  image.ram image.hex *.o *.d

DEPS := $(wildcard *.d)
ifneq ($(DEPS),)
include $(DEPS)
endif
