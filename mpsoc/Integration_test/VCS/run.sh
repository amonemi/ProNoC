#!/bin/bash

SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)

# Source the environment variables
conf_dir="${SCRPT_DIR_PATH}/configurations"
log_dir="${SCRPT_DIR_PATH}/result_logs"
work="${log_dir}/work"
file_list="${SCRPT_DIR_PATH}/src/file_list.f"

export VCS_ARCH_OVERRIDE=linux

mkdir -p $work
mkdir -p $log_dir

VCS_WORK_LIB=work

VCS_COMMON_ARGS=" -full64 -notice -nc -kdb -timescale=1ps/1ps  -sverilog  -debug_access  +vcs+lic+wait "
VCS_ANALYZE_ARGS=" +lint=all,noVCDE,noVNGS,noPCTIO-L,noPCTIO  +systemverilogext+.sv  -work $VCS_WORK_LIB  +warn=all " 

vcs_lint () {
    conf=$1
    conf_file="${conf_dir}/$conf"
    log_file="${log_dir}/${conf}.log"

    if [[ ! -f "$conf_file" ]]; then
        echo "Configuration file $conf_file does not exist"
        exit 1
    fi

    perl "${SCRPT_DIR_PATH}/src/param_gen.pl" "$conf_file"

    vcs $VCS_COMMON_ARGS $VCS_ANALYZE_ARGS \
        -f "$file_list" \
        -top noc_top \
        -o "$work/simv" \
        -Mdir="$work/csrc"
}

for f in "$conf_dir"/*; do
    [[ -d "$f" ]] && continue
    conf=$(basename "$f")
    echo "▶️  Compiling configuration: $conf"
    vcs_lint "$conf" > "$log_dir/${conf}.log" 2>&1
    if [[ $? -ne 0 ]]; then
        echo "❌ Compilation failed for $conf (check $log_dir/${conf}.log)"
        rm -f ${SCRPT_DIR_PATH}/src/noc_localparam.v
        exit 1
    else
        echo "✅ Compilation successful for $conf"
        rm -f ${SCRPT_DIR_PATH}/src/noc_localparam.v
    fi
    
done
