#!/bin/sh

HARDWARE_NAME="DE-SoC *"
DEVICE_NAME="@2*" 
JTAG_INTFC="$PRONOC_WORK/toolchain/bin/jtag_quartus_stp -a $HARDWARE_NAME -b $DEVICE_NAME"
