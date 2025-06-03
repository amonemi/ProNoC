#!/bin/bash

SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)

# Source the environment variables
conf_dir="${SCRPT_DIR_PATH}/configurations"
log_dir="${SCRPT_DIR_PATH}/result_logs"
golden_dir="${SCRPT_DIR_PATH}/golden_ref"
work="${PRONOC_WORK}/verify/quartus_pronoc"
log_work="${PRONOC_WORK}/verify/logs"
mkdir -p $log_work
mkdir -p $log_dir




quartus_get_result () {
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
    top="quartus_pronoc"
    log_file="${log_work}/$conf"
    golden_ref="${SCRPT_DIR_PATH}/golden_ref/$conf"
    

    perl  ${SCRPT_DIR_PATH}/src/param_gen.pl  $conf_file
    
    compile
    wait;
    
    mkdir -p $log_work
    perl ${SCRPT_DIR_PATH}/src/extract.prl "$PRONOC_WORK/verify/quartus_pronoc" "pronoc" > $log_file
    #meld "$golden_ref" "$log_file" &
    rm -f ${SCRPT_DIR_PATH}/src/noc_localparam.v
}

copy_filelist () {
    fname=$1
    local DIR="$(dirname "${fname}")"
    echo $DIR
    pwd
    while read line; do
        # reading each line
        #echo $line
        cd $DIR
        if test -f "$DIR/$line"; then
            echo "copy $DIR/$line "
            cp "$DIR/$line"   $PITON_ROOT/build/src_verilog/
        fi
        line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//')"   # remove only the leading white spaces
        if [[ $line == -F* ]] || [[ $line == -f* ]] ; then 
            line=${line:2}   # Remove the first three chars (leaving 4..end)
            line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//')"   # remove only the leading white spaces
            echo $line
            echo "got another file list $line"
            copy_filelist "$DIR/$line"
        fi
    done < $fname
}


make_qsf () {
    fname=$1
    oname=$2
    local DIR="$(dirname "${fname}")"
    echo $oname
    pwd
    while read line; do
        # reading each line
        #echo $line
        cd $DIR
        if test -f "$DIR/$line"; then
            echo "set_global_assignment -name SYSTEMVERILOG_FILE $DIR/$line">>"$oname"
            # "$DIR/$line"   $PITON_ROOT/build/src_verilog/  
        fi
        line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//')"   # remove only the leading white spaces
        if [[ $line == -F* ]] || [[ $line == -f* ]] ; then 
            line=${line:2}   # Remove the first three chars (leaving 4..end)
            line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//')"   # remove only the leading white spaces
            #echo $line
            echo "got another file list $line"
            make_qsf "$DIR/$line" "$oname"
        fi
        if [[ $line == +incdir+* ]] ; then 
            line=${line:8}   # Remove the first three chars (leaving 4..end)
            echo "set_global_assignment -name SEARCH_PATH $DIR/$line">>"$oname"
        fi
    done < $fname
}


compile () {
    mkdir -p  $work
    filename=$SCRPT_DIR_PATH/src/file_list.f
    qsf_name="$work/pronoc.qsf"
    cp -f $SCRPT_DIR_PATH/src/pronoc.qsf $qsf_name
    echo "set_global_assignment -name TOP_LEVEL_ENTITY $top">>$qsf_name
    make_qsf $filename "$qsf_name"
    if [[ -z "${Quartus_bin}" ]]; then
    #"Some default value because Quartus_bin is undefined"
    Quartus_bin="/home/alireza/intelFPGA_lite/18.1/quartus/bin"
    else
    Quartus_bin="${Quartus_bin}"
    fi
    cd $work
    $Quartus_bin/quartus_map --64bit pronoc --read_settings_files=on
    $Quartus_bin/quartus_fit --64bit pronoc --read_settings_files=on 
    $Quartus_bin/quartus_asm --64bit pronoc --read_settings_files=on
    $Quartus_bin/quartus_sta --64bit pronoc
}

report_all_configurations () {
    output_file="$log_dir/report.csv"
    > "$output_file"  # Empty the file at start
    # Initialize a set to track unique metric names
    declare -A all_keys

    # First pass: collect all metric names
    for file in "$log_work"/*; do
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            IFS='|' read -ra parts <<< "$line"
            key="${parts[0]// /}"   # Trim whitespace from key
            all_keys["$key"]=1
        done < "$file"
    done

    # Build the header
    {
        printf "File"
        for key in "${!all_keys[@]}"; do
            printf "| %s" "$key"
        done
        printf "\n"
    } >> "$output_file"

    # Second pass: extract values for each file
    for file in "$log_work"/*; do
        declare -A data
        data["File"]="${file##*/}"

        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            IFS='|' read -ra parts <<< "$line"
            key="${parts[0]// /}"
            val="${parts[1]// /}"
            data["$key"]="$val"
        done < "$file"

        {
            printf "%s" "${data["File"]}"
            for key in "${!all_keys[@]}"; do
                printf "| %s" "${data[$key]}"
            done
            printf "\n"
        } >> "$output_file"

        unset data
    done
}

for f in "$conf_dir"/*; do
    if [[ -d "$f" ]]; then
        continue
    fi
    conf=$(basename "$f")
    echo "Compile configuration $conf"
    quartus_get_result "$conf"
done


report_all_configurations

perl ${SCRPT_DIR_PATH}/src/compare.pl "$golden_dir/report.csv" "$log_dir/report.csv" 
echo "All configurations processed. Results are in $log_dir/report.csv"
