#!/bin/sh

#usage: 
#	sh program_device.sh  programming_file.sof

#programming file 
#given as an argument:  $1

#Programming mode
PROG_MODE=jtag

#cable name. Connect the board to ur PC and then run jtagconfig in terminal to find the cable name
NAME="USB-Blaster"


#programming command
if [ -n "${QUARTUS_BIN+set}" ]; then
  $QUARTUS_BIN/quartus_pgm -m $PROG_MODE -c "$NAME" -o "p;${1}"
else
  quartus_pgm -m $PROG_MODE -c "$NAME" -o "p;${1}"
fi





