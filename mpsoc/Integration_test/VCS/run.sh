#!/bin/bash

SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)

# Source the environment variables
conf_dir="${SCRPT_DIR_PATH}/configurations"
log_dir="${SCRPT_DIR_PATH}/result_logs"
work="${PRONOC_WORK}/verify/vcs"
file_list="${SCRPT_DIR_PATH}/src/file_list.f"

mkdir -p $work
mkdir -p $log_dir

VCS_WORK_LIB=work

VCS_COMMON_ARGS=" -full64 -notice -nc -kdb -timescale=1ps/1ps  -sverilog  -debug_access  +vcs+lic+wait "
VCS_ANALYZE_ARGS=" +lint=all,noVCDE,noVNGS,noPCTIO-L,noPCTIO  +systemverilogext+.sv  -work $VCS_WORK_LIB  +warn=all " 


vcs_lint () {
    conf=$1
    if [[ -z "$conf" ]]; then
        echo "No configuration provided"
        exit 1
    fi
    if [[ ! -f "${SCRPT_DIR_PATH}/configurations/$conf" ]]; then
        echo "Configuration file ${SCRPT_DIR_PATH}/configurations/$conf does not exist"
        exit 1
    fi
    if [[ ! -d "${SCRPT_DIR_PATH}/result_logs" ]]; then
        mkdir -p "${SCRPT_DIR_PATH}/result_logs"
    fi
    conf_file="${SCRPT_DIR_PATH}/configurations/$conf"
    log_file="${log_work}/$conf"
     

    perl  ${SCRPT_DIR_PATH}/src/param_gen.pl  $conf_file
    
    vcs $VCS_COMMON_ARGS $VCS_ANALYZE_ARGS -f $file_list -lint  
    
   
}



vcs_lint line4_smart3
