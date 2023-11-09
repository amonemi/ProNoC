#!/bin/bash 
	
source "/etc/profile"

SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)

echo "\$SCRPT_DIR_PATH is $SCRPT_DIR_PATH"

export PRONOC_WORK=$SCRPT_DIR_PATH/../../mpsoc_work
export VERILATOR_ROOT=~/scratch/`whoami`/verilator_4_104
export PATH=$PATH:$VERILATOR_ROOT/bin
export C_INCLUDE_PATH=$VERILATOR_ROOT/include
export CPLUS_INCLUDE_PATH=$VERILATOR_ROOT/include



source "/eda/env.sh"

#module load gcc/10.1.0



home=$(eval echo ~$USER)
source "$home/.bash_profile"

export PERL5LIB=$SCRPT_DIR_PATH/perl_lib:$PERL5LIB
echo "$localperl   ./verify.perl $@"

$localperl   ./verify.perl $@




