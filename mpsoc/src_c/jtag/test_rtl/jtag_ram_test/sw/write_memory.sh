#!/bin/sh

#JTAG_INTFC="$PRONOC_WORK/toolchain/bin/JTAG_INTFC"
source ./jtag_intfc.sh

 $JTAG_INTFC -n 0 -s "0x00000000" -e "0x0000ffff" -i  "./RAM/ram0.bin" -c