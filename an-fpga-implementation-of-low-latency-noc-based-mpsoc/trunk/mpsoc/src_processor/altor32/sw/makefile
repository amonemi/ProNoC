TOOLCHAIN=$(PRONOC_WORK)/toolchain
IHEX2MIF =$(TOOLCHAIN)/bin/ihex2mif
IHEX2BIN =$(TOOLCHAIN)/bin/ihex2bin
OR1K_TCHAIN= $(TOOLCHAIN)/or1k/bin/or1knd-elf

###############################################################################
# Configuration
###############################################################################
# Target
TARGET ?= main

# Memory Layout
MEMBASE ?= 0x00000000
MEMSIZE ?= 12384
MEMNAME ?= sram

###############################################################################
# Files
###############################################################################
INCLUDE_DIRS ?= 
OBJ = boot.o
OBJS = $(patsubst %.c,%.o,$(wildcard *.c))
OBJ+= $(OBJS)

###############################################################################
## Makefile
###############################################################################

# Tools


CC          = $(OR1K_TCHAIN)-gcc $(CFLAGS)
AS          = $(OR1K_TCHAIN)-as
LD          = $(OR1K_TCHAIN)-ld
OBJDUMP     = $(OR1K_TCHAIN)-objdump
OBJCOPY     = $(OR1K_TCHAIN)-objcopy

# Options
CFLAGS 	   ?=
CFLAGS	   += -Ttext $(MEMBASE) -Os -g -Wall
CFLAGS     += -msoft-div -msoft-float -msoft-mul -mno-ror -mno-cmov -mno-sext
CFLAGS	   += -nostartfiles -nodefaultlibs -nostdlib -lgcc -L .
ASFLAGS     =
LDFLAGS     = 

LDSCRIPT= linker_script
CFLAGS += -mno-delay -D__OR1K_NODELAY__ -D__OR1K__
ASFLAGS+= -mno-delay -Wa,--defsym,__OR1K_NODELAY__=1
CFLAGS += -T$(LDSCRIPT)
SIMARGS += -n

CFLAGS += -I. $(INCLUDE_DIRS)

RAMSIZE ?= "7FFF"
###############################################################################
# Rules
###############################################################################
conv: all
# Convert the ELF file to an IHEX file
	$(OBJCOPY) -O ihex $(TARGET).elf $(TARGET).ihex 
# Generate a MIF file from the IHEX file
	$(IHEX2MIF) -f $(TARGET).ihex  -e $(RAMSIZE) -o ram0.mif
	$(IHEX2BIN) -f $(TARGET).ihex  -o ram0.bin


all: 	$(TARGET).elf lst bin



	
clean:
	-rm $(OBJ) *.map *.lst *.hex *.ver *.txt *.elf *.ihex $(TARGET).bin  ram0.mif

%.o : %.s
	$(CC) -c $(ASFLAGS) $< -o $@

%.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@

$(TARGET).elf: $(OBJ) $(LDSCRIPT) makefile
	$(CC) $(LDFLAGS) $(LIBS) $(OBJ) -o $@
	
lst:  $(TARGET).lst

%.lst: $(TARGET).elf
	$(OBJDUMP) -h -d -S $< > $@

bin: $(TARGET).bin

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
