#!/bin/sh

PRODUCT_ID="0x6010" 
HARDWARE_NAME='DE-SoC *'
DEVICE_NAME="@2*" 
	
JTAG_INTFC="$PRONOC_WORK/toolchain/bin/jtag_quartus_stp -a $HARDWARE_NAME -b $DEVICE_NAME"
		
	