HDR_SOURCE_DIR=mor1kx

TOOLCHAIN=$(PRONOC_WORK)/toolchain/or1k-elf
IHEX2MIF =$(PRONOC_WORK)/toolchain/bin/ihex2mif
IHEX2BIN =$(PRONOC_WORK)/toolchain/bin/ihex2bin
BIN2HEX =$(PRONOC_WORK)/toolchain/bin/bin2str


OR32_TOOL_PREFIX=${TOOLCHAIN}/bin/or1k-elf-

OR32_LD=$(OR32_TOOL_PREFIX)ld
OR32_AS=$(OR32_TOOL_PREFIX)as
OR32_CC=$(OR32_TOOL_PREFIX)gcc
OR32_AR=$(OR32_TOOL_PREFIX)ar
OR32_OBJDUMP=$(OR32_TOOL_PREFIX)objdump
OR32_OBJCOPY=$(OR32_TOOL_PREFIX)objcopy
OR32_LIB1=${TOOLCHAIN}/lib/gcc/or1k-elf/5.2.0

LIBRARIES = -L${OR32_LIB1} -L. -L./$(HDR_SOURCE_DIR) -lorlib -lgcc

MARCH_FLAGS ?=-msoft-mul -msoft-div -msoft-float
CFLAGS ?= -g -nostdlib -O2 $(MARCH_FLAGS) 	

LDFLAGS ?=    -Tlink.ld  -e 256 

RAMSIZE=3FFF

# Sources to go into the liborpsoc.a support library
COMPILE_SRCS=$(HDR_SOURCE_DIR)/exceptions.c $(HDR_SOURCE_DIR)/int.c  $(HDR_SOURCE_DIR)/mmu.S  $(HDR_SOURCE_DIR)/$(HDR_SOURCE_DIR)-utils.c $(HDR_SOURCE_DIR)/cache.S


all: image.ihex

lib:
#compile all source code
	$(OR32_CC) -Wall $(CFLAGS) -c $(COMPILE_SRCS) -I./$(HDR_SOURCE_DIR)/include/ 
#add them to liborlib.a
	$(OR32_AR) -cvq liborlib.a *.o

crt0.o: ./$(HDR_SOURCE_DIR)/crt0.S
	$(OR32_CC) $(CFLAGS) -c  ./$(HDR_SOURCE_DIR)/crt0.S -I./$(HDR_SOURCE_DIR)/include/ 

#compile main file using liborlib.a
main.o: lib main.c
	$(OR32_CC) -Wall $(CFLAGS) -c main.c  -o main.o
	
image:  crt0.o main.o   Makefile 
	$(OR32_LD) $(LDFLAGS) -Map image.map -N -o image crt0.o main.o $(LIBRARIES)


image.lst: image
	$(OR32_OBJDUMP) -h -S $< > $@


image.ihex: image image.lst
# Convert the ELF file to an IHEX file
	mkdir -p ./RAM
	$(OR32_OBJCOPY) -O ihex image image.ihex 
# Generate a MIF & BIN files from the IHEX file
	$(IHEX2MIF) -f image.ihex -e $(RAMSIZE) -o RAM/ram0.mif
	$(IHEX2BIN) -i image.ihex -o RAM/ram0.bin
	$(BIN2HEX)  -f RAM/ram0.bin -h   
	rm *.o *.a




clean:
	rm -f image.ihex  image image.lst image.bin image.srec image.map  image.ram image.hex RAM/* *.o *.a

