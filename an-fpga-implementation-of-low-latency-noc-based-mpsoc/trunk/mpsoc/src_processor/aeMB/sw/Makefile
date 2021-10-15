SOURCE_LIB =
include SOURCE_LIB

HDR_SOURCE_DIR=aemb

TOOLCHAIN=$(PRONOC_WORK)/toolchain/aemb
IHEX2MIF =$(PRONOC_WORK)/toolchain/bin/ihex2mif
IHEX2BIN =$(PRONOC_WORK)/toolchain/bin/ihex2bin
BIN2HEX =$(PRONOC_WORK)/toolchain/bin/bin2str
BIN2MIF=$(PRONOC_WORK)/toolchain/bin/bin2mif
BIN2MEM=$(PRONOC_WORK)/toolchain/bin/bin2mem

MB_TOOL_PREFIX=${TOOLCHAIN}/bin/mb-
MB_LD=$(MB_TOOL_PREFIX)ld
MB_AS=$(MB_TOOL_PREFIX)as
MB_CC=$(MB_TOOL_PREFIX)g++
MB_AR=$(MB_TOOL_PREFIX)ar
MB_OBJDUMP=$(MB_TOOL_PREFIX)objdump
MB_OBJCOPY=$(MB_TOOL_PREFIX)objcopy
MB_LIB1=${TOOLCHAIN}/lib/gcc/microblaze-xilinx-elf/4.1.1

ELFFILE=image
XILFLAGS=-mtune=v5.00 -mxl-soft-div -msoft-float -mxl-barrel-shift -mno-xl-soft-mul
CXXFLAGS=-O3 
#LNKFLAGS=-Wl,-defsym -Wl,_STACK_SIZE=$(STACK_SIZE) -Wl,-defsym -Wl,_HEAP_SIZE=$(HEAP_SIZE)
LIBFLAGS=
INCFLAGS=-Icc/

LDFLAGS ?=    -Tlink.ld  -e 256 

LIBRARIES = -L${MB_LIB1} -L. -L./$(HDR_SOURCE_DIR) -lorlib -lgcc
#LIBRARIES =  -L. -lorlib -lgcc

# Sources to go into the liborpsoc.a support library
COMPILE_SRCS=     $(SOURCE_LIB)

#$(HDR_SOURCE_DIR)/custom_crt/_interrupt_handler.s
ASSEMBELS=    $(HDR_SOURCE_DIR)/__main.c  $(HDR_SOURCE_DIR)/custom_crt/_exception_handler.s   $(HDR_SOURCE_DIR)/custom_crt/_hw_exception_handler.s  



all: image.ihex

lib:
#compile all source code
	$(MB_CC) -Wall $(XILFLAGS) $(CXXFLAGS) $(LIBFLAGS) $(INCFLAGS) -specs=aemb.specs -c $(COMPILE_SRCS) $(ASSEMBELS)
#add them to liborlib.a
	$(MB_AR) -cvq liborlib.a *.o


#compile main file using liborlib.a
main.o: lib main.c
	$(MB_CC) -Wall $(XILFLAGS) $(CXXFLAGS) $(LIBFLAGS) $(INCFLAGS) -specs=aemb.specs -c main.c  -o main.o
	$(MB_CC) -Wall $(XILFLAGS) $(CXXFLAGS) $(LIBFLAGS) $(INCFLAGS) -specs=aemb.specs -c $(HDR_SOURCE_DIR)/custom_crt/crt0.s  -o crt0.o
	$(MB_CC) -Wall $(XILFLAGS) $(CXXFLAGS) $(LIBFLAGS) $(INCFLAGS) -specs=aemb.specs -c $(HDR_SOURCE_DIR)/custom_crt/crtinit.s -o crtinit.o
	#$(MB_LD) -Ur  crt0.o crtinit.o  main.o -o mm.o
image: main.o  Makefile 
	#$(MB_CC) -Wall $(XILFLAGS) $(CXXFLAGS) $(LNKFLAGS) $(LIBFLAGS) $(INCFLAGS) -specs=aemb.specs main.o  -o $(ELFFILE) $(LIBRARIES)
	$(MB_LD) $(LDFLAGS) crt0.o crtinit.o  main.o -Map image.map -N -o  image    $(LIBRARIES)

image.lst: image
	$(MB_OBJDUMP) -h -S $< > $@


image.ihex: image image.lst
# Convert the ELF file to an IHEX file
	mkdir -p ./RAM
	$(MB_OBJCOPY) -O ihex image image.ihex
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

