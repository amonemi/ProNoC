#!/bin/bash 
	
source "/etc/profile"

SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)


export PRONOC_WORK=$(realpath "$SCRPT_DIR_PATH/../../../../mpsoc_work")
export VERILATOR_ROOT=~/scratch/`whoami`/verilator_4_104 
#export VERILATOR_ROOT=~/scratch/`whoami`/verilator_5_014
export PATH=$PATH:$VERILATOR_ROOT/bin
export C_INCLUDE_PATH=$VERILATOR_ROOT/include
export CPLUS_INCLUDE_PATH=$VERILATOR_ROOT/include

export PERL_CMD=perl #~/scratch/`whoami`/localperl/bin/perl
export PATH=$PATH:~/scratch/`whoami`/localperl/bin
source "/eda/env.sh"

#module load gcc/10.1.0

echo "\$PRONOC_WORK is $PRONOC_WORK"

home=$(eval echo ~$USER)
source "$home/.bash_profile"

export PERL5LIB=$SCRPT_DIR_PATH/perl_lib:$PERL5LIB
echo "$PERL_CMD   ./verify.perl $@"

$PERL_CMD   ./verify.perl $@
