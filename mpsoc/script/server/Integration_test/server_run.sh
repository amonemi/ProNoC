#!/bin/bash 
	
source "/etc/profile"

	SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
	SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)

echo "\$SCRPT_DIR_PATH is $SCRPT_DIR_PATH"

export PRONOC_WORK=$SCRPT_DIR_PATH/../../mpsoc_work
export PATH=$PATH:/opt/verilator/bin
source "/eda/env.sh"




home=$(eval echo ~$USER)
source "$home/.bash_profile"


$localperl ./verify.perl $@




