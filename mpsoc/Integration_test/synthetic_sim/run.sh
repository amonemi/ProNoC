#!/bin/bash

servers=( 'mn5')
#servers' shorthand name. They should be defined in ~/.ssh/config :
# 
#    Host your_short_name
#        HostName server.on.the.web
#        User user_to_user


my_ssh="ssh -t -o StrictHostKeyChecking=no"
my_scp="scp -o StrictHostKeyChecking=no"


#the max server load that is permited for runing the parallel test
max_allowed_server_load_percentage=24


SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)





#servers=( $server1 $server2 $server3 ) # an array which define the list of servers 
my_server="to be selected"
SERVER_ROOT_DIR="~/pronoc_verify"

ProNoC=$(realpath "$SCRPT_DIR_PATH/../..")




my_srcs=( "rtl"
    "Integration_test"
    "src_verilator"
    "src_c/netrace-1.0"
    "src_c/synfull"
    "script"
    "/perl_gui/lib/perl" )



# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
PRUN=20
MIN=2
MAX=80
STEP=4
CONFS="general"

CONFS_path=$(realpath $SCRPT_DIR_PATH/configurations)




while getopts "h?a:p:u:l:s:d:m:" opt; do
  case "$opt" in
    h|\?)
      echo "
Usage: ./run [options]

Options:
  -h                Show this help message and exit.
  -a <server names> Specify remote server names as a comma-separated list. 
                    The script will automatically select the least busy server 
                    to run the simulation. Use \"-a local\" to execute the script 
                    locally on your machine instead.
  -p <int>          Number of parallel simulations or compilations to run. 
                    Default: 4.
  -u <int>          Maximum injection ratio in percentage (%). 
                    Default: 80.
  -l <int>          Minimum injection ratio in percentage (%). 
                    Default: 5.
  -s <int>          Step size for increasing injection ratio in percentage (%). 
                    Default: 25.
  -d <dir>          Name of the directory where simulation model configuration 
                    files are located. Default: \"$CONFS\".
  -m <models>       Comma-separated list of simulation model names in the 
                    configuration directory. If not specified, the script 
                    runs simulations for all available models.

Available Configuration Directories for -d Option:
"
      declare -a dirs
      i=1
      for d in $CONFS_path/*/; do
        m=$(basename "${d%/}")
        if [ "$m" != "src" ] && [ "$m" != "perl_lib" ]; then 
          dirs[i++]="$m"
        fi
      done
      
      if [ ${#dirs[@]} -gt 0 ]; then
        for ((i=1; i<=${#dirs[@]}; i++)); do
          echo "    $i) ${dirs[i]}"
        done
      else
        echo "    No directories available."
      fi

      exit 0
      ;;
    a) 
      IFS=',' read -r -a servers <<< "$OPTARG" 
      if [ "${servers[0]}" = "local" ]; then
        echo "[Info]: Running locally"
        PRUN=1  
        my_ssh=""
        my_scp="cp"              
      else
        echo "[Info]: Servers provided: ${servers[@]}"
      fi
      ;; 
    p) PRUN=$OPTARG
      ;; 
    u) MAX=$OPTARG
      ;;  
    l) MIN=$OPTARG
      ;; 
    s) STEP=$OPTARG
      ;;  
    d) CONFS=$OPTARG
      ;; 
    m) model="-m $OPTARG"
      ;;           
  esac
done


shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift
Leftovers="$@"

# Display information
echo "---------------------------------------------"
echo "Simulation Script Information"
echo "---------------------------------------------"
echo "  Parallel Runs       : $PRUN (Maximum number of parallel simulations"
echo "                        that can be run at the same time on the server)"
echo "  Max Injection Ratio : $MAX (Maximum packet injection ratio)"
echo "  Min Injection Ratio : $MIN (Minimum packet injection ratio)"
echo "  Step Size           : $STEP (Simulation starts at MIN and increments by"
echo "                        STEP to reach MAX)"
echo "  Target Directory    : $CONFS (The model target directory where simulation"
echo "                        is running)"
if [ -n "$model" ]; then
    echo "  Model Under Test    : $model (The model name under test)"
fi
if [ -n "$Leftovers" ]; then
    echo "  Leftover Arguments  : $Leftovers (Additional arguments passed to the script)"
fi
echo "---------------------------------------------"

args="-p $PRUN -u $MAX -l $MIN -s $STEP -d $CONFS $model"

log_dir="${SCRPT_DIR_PATH}/result_logs"
log_file="${log_dir}/${CONFS}"
golden_ref="${SCRPT_DIR_PATH}/golden_ref/${CONFS}"

mkdir -p $log_dir

if [ -f "$log_file" ]; then
    rm "$log_file"
fi



#copy_sources
#login_in_server

#step one login in the server and find how much is bussy 
function get_server_load_percentage {
    # Retrieve uptime and core information from the server
    out=$($my_ssh "$1" "uptime")
    load_avg=$(echo "$out" | grep -oP '(?<=load average: )[\d.]+' | head -n 1)  # Extract 1-minute load average
    nproc=$($my_ssh "$1" "nproc" | tr -d '\r')  # Remove any extra characters (e.g., carriage return)

    # Calculate load as a percentage
    load_percentage=$(echo "scale=0; $load_avg * 100 / $nproc" | bc )

    # Display results
    echo "[INFO] The load average on $1 is $load_avg on $nproc cores, making it $load_percentage% busy."
}



function select_a_server {
    min_load="100"    
    for i in "${servers[@]}"; do
            echo "get load average on $i server"        
            get_server_load_percentage $i            
            if [ $min_load  -gt $load_percentage ]
            then
                min_load=$load_percentage
                my_server=$i
            fi        
    done
    if [ $min_load -gt $max_allowed_server_load_percentage ] 
    then
        echo "[INFO] All servers are busy. Cannot continue"        
        exit
    fi
    echo "[INFO] Server $my_server is selected for running the integration test."
}


function copy_sources {
    $my_ssh $my_server  rm -rf  ${SERVER_ROOT_DIR}
    $my_ssh $my_server  mkdir -p "${SERVER_ROOT_DIR}/mpsoc/perl_gui/lib/"
    $my_ssh $my_server  mkdir -p "${SERVER_ROOT_DIR}/mpsoc/src_c/"
    $my_ssh $my_server  mkdir -p "${SERVER_ROOT_DIR}/mpsoc_work"
    for i in "${my_srcs[@]}"; do    
        echo "Copy $i  on the server"        
        $my_scp -r "$ProNoC/$i"  "$my_server:${SERVER_ROOT_DIR}/mpsoc/$i"
    done    
}


function run_test {
    cmd="export PRONOC_WORK=${SERVER_ROOT_DIR}/mpsoc_work;" 
    $my_ssh $my_server $cmd

}

#setps to run the verrification 

#1
if [ "${servers[0]}" != "local" ]; then
    select_a_server
    copy_sources
    echo "source \"/etc/profile\"; bash server_run.sh $args"
$my_ssh $my_server  "cd ${SERVER_ROOT_DIR}/mpsoc/Integration_test/synthetic_sim/src;  source \"/etc/profile\";  bash   server_run.sh $args;"
    $my_scp -r   "$my_server:${SERVER_ROOT_DIR}/mpsoc/Integration_test/synthetic_sim/result_logs/${CONFS}"  "$log_file"

else 

    cd $SCRPT_DIR_PATH/src; bash   server_run.sh $args

fi


wait
meld "$golden_ref" "$log_file" &
