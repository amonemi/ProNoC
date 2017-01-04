#!/bin/sh

OFSSET="0x00000000"
BOUNDRY="0x00003fff"
BINFILE="ram0.bin"
VJTAG_INDEX="0"

JTAG_MAIN="$PRONOC_WORK/toolchain/bin/jtag_main"

#reset and disable cpus, then release the reset but keep the cpus disabled

$JTAG_MAIN -n 127  -d  "I:1,D:2:3,D:2:2,I:0"

# jtag instruction 
#	0: bypass
#	1: getting data
# jtag data :
# 	bit 0 is reset 
#	bit 1 is disable
# I:1  set jtag_enable  in active mode
# D:2:3 load jtag_enable data register with 0x3 reset=1 disable=1
# D:2:2 load jtag_enable data register with 0x2 reset=0 disable=1
# I:0  set jtag_enable  in bypass mode



#programe the memory
$JTAG_MAIN -n $VJTAG_INDEX -s $OFSSET -e $BOUNDRY -i  $BINFILE -c
 
#Enable the cpu
$JTAG_MAIN -n 127  -d  "I:1,D:2:0,I:0"
# I:1  set jtag_enable  in active mode
# D:2:0 load jtag_enable data register with 0x0 reset=0 disable=0
# I:0  set jtag_enable  in bypass mode
