
#!/bin/sh


#JTAG_INTFC="$PRONOC_WORK/toolchain/bin/JTAG_INTFC"
source ./jtag_intfc.sh

#reset and disable cpus, then release the reset but keep the cpus disabled

$JTAG_INTFC -n 127  -d  "I:1,D:2:3,D:2:2,I:0"

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

	sh write_memory.sh 

 
#Enable the cpu
$JTAG_INTFC -n 127  -d  "I:1,D:2:0,I:0"
# I:1  set jtag_enable  in active mode
# D:2:0 load jtag_enable data register with 0x0 reset=0 disable=0
# I:0  set jtag_enable  in bypass mode
