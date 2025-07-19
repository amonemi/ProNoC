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
report_file="${log_dir}/report.txt"

mkdir -p $work
mkdir -p $log_dir
rm -rf $report_file
printf "%-30s | %-10s | %-10s |\n" "Configuration" "# Warnings" "# Errors" >> "$report_file"

# Source the environment variables
# conf_dir="${SCRPT_DIR_PATH}/conf_small"

questa_lint () {
    set -e  # Exit on any command failure
    conf=$1
    conf_file="${conf_dir}/$conf"
    log_file="${log_dir}/${conf}.log"

    if [[ ! -f "$conf_file" ]]; then
        echo "Configuration file $conf_file does not exist" > $log_file
        exit 1
    fi

    perl "${SCRPT_DIR_PATH}/src/param_gen.pl" "$conf_file" > $log_file
    export REPORT_FILENAME="${log_dir}/${conf}.txt"
    export FILE_LIST=$file_list_f
    
    # Clean old work library
    rm -rf work
    vlib work
    # Lint the design
    vlog -sv -lint -f ${file_list_f} > $log_file
    vsim -suppress vopt-14408,vsim-16154 -c work.noc_top -do "quit"  > $log_file
}

report_total_errors_warnings () {
    conf="$1"
    conf_file="${conf_dir}/${conf}"
    log_file="${log_dir}/${conf}.log"
    warnings=$(grep '\*\* Warning' "$log_file" | wc -l)
    errors=$(grep '\*\*\ Error' "$log_file" | wc -l)
    printf "%-30s | %-10s | %-10s |\n" "$conf" "$warnings" "$errors" >> "$report_file"
}


run_config () {
    conf="$1"
    log_file="${log_dir}/${conf}.log"
    echo "▶️  Compiling configuration: $conf"
    # Run and redirect stdout/stderr to log file only
    questa_lint "$conf" |& tee "$log_file"
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        echo "❌ Compilation failed for $conf (check $log_file)"
        rm -f "${SCRPT_DIR_PATH}/src/noc_localparam.v"
        exit 1
    else
        echo "✅ Compilation successful for $conf"
        rm -f "${SCRPT_DIR_PATH}/src/noc_localparam.v"
        report_total_errors_warnings "$conf"
    fi
}


# === Main ===
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: bash run.sh [config_name]"
    echo
    echo "If [config_name] is provided, only that configuration will be processed."
    echo "If no argument is given, all configurations in the 'configurations/' directory will be processed."
    echo
    echo "Examples:"
    echo "  bash run.sh         # Run all configurations"
    echo "  bash run.sh conf1   # Run only conf1"
    exit 0
fi

if [[ $# -eq 1 ]]; then
    # Run only the specified configuration
    conf_name="$1"
    run_config "$conf_name"
else
    # Run all configurations
    for f in "$conf_dir"/*; do
        [[ -d "$f" ]] && continue
        conf=$(basename "$f")
        run_config "$conf"
    done
fi


echo "Report saved in $report_file"
echo "Summary:"
echo "-------------------------------|------------|------------|"
cat $report_file

echo "Comparing with golden reference..."
# Compare the results with the golden reference report  
perl ${SCRPT_DIR_PATH}/../Altera/src/compare.pl   ${SCRPT_DIR_PATH}/golden_ref/report.txt $report_file
echo "All configurations processed. Results are in $report_file
