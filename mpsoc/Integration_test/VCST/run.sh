#!/bin/bash

SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)

# Source the environment variables
conf_dir="${SCRPT_DIR_PATH}/configurations"
log_dir="${SCRPT_DIR_PATH}/result_logs"
conf_dir="${SCRPT_DIR_PATH}/configurations"
work="${SCRPT_DIR_PATH}/work"
file_list_f="${SCRPT_DIR_PATH}/src/file_list.f"
lint_file="${SCRPT_DIR_PATH}/src/lint.tcl"

export VCS_ARCH_OVERRIDE=linux

mkdir -p $work
mkdir -p $log_dir


VCST_COMMON_ARGS=" -full64  "


vcst_lint () {
    conf=$1
    conf_file="${conf_dir}/$conf"
    log_file="${log_dir}/${conf}.log"

    if [[ ! -f "$conf_file" ]]; then
        echo "Configuration file $conf_file does not exist"
        exit 1
    fi

    perl "${SCRPT_DIR_PATH}/src/param_gen.pl" "$conf_file"
    export REPORT_FILENAME="${log_dir}/${conf}_vc_static.txt"
    export FILE_LIST=$file_list_f
    cd work
    vc_static_shell ${VCST_COMMON_ARGS} -file ${lint_file} -batch -lic_wait 10
    cd -
}

for f in "$conf_dir"/*; do
    [[ -d "$f" ]] && continue
    conf=$(basename "$f")
    log_file="${log_dir}/${conf}.log"
    echo "▶️  Compiling configuration: $conf"
    vcst_lint "$conf"  |& tee $log_file
    if [[ $? -ne 0 ]]; then
        echo "❌ Compilation failed for $conf (check $log_file)"
        rm -f ${SCRPT_DIR_PATH}/src/noc_localparam.v
        exit 1
    else
        echo "✅ Compilation successful for $conf"
        rm -f ${SCRPT_DIR_PATH}/src/noc_localparam.v
    fi
    
done
