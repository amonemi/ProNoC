#!/bin/bash

servers=( 'mn5')
#servers' shorthand name. They should be defined in ~/.ssh/config :
# 
#	Host your_short_name
#		HostName server.on.the.web
#		User user_to_user





#the max server load that is permited for runing the parallel test
max_allowed_server_load_percentage=24


SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)





#servers=( $server1 $server2 $server3 ) # an array which define the list of servers 
my_server="to be selected"
SERVER_ROOT_DIR="~/pronoc_verify"

ProNoC="$SCRPT_DIR_PATH/../../.."

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
paralel_run=20
MIN=2
MAX=80
STEP=4
dir="models"



models_path=$(realpath $ProNoC/Integration_test/synthetic_sim)




while getopts "h?p:u:l:s:d:m:" opt; do
  case "$opt" in
    h|\?)
      echo "./run [options]
      
      [options]
      -h show this help 
      -p <int number>  : Enter the number of parallel simulations or
                         compilations. The default value is 4.
      -u <int number>  : Enter the maximum injection ratio in %. Default is 80
      -l <int number>  : Enter the minimum injection ratio in %. Default is 5
      -s <int number>  : Enter the injection step increase ratio in %. 
                         Default value is 25.
      -d <dir name>    : The dir name where the simulation models configuration
                         files are located in. The default dir is \"models\"
      -m <simulation model name1,simulation model name2,...> : Enter the 
                         simulation model name in simulation dir. If the 
                         simulation model name  is not provided, it runs the 
                         simulation for all existing models in model dir.     
      "
          
      	declare -a dirs
		i=1
		for d in $models_path/*/
		do
			m=$(basename "${d%/}")
			if [ $m != "src" ] &&  [ $m != "perl_lib" ]; then 
			 	dirs[i++]="$m"
			fi
		done
		echo "	For -d option, there are ${#dirs[@]} dir names available:"
		for((i=1;i<=${#dirs[@]};i++))
		do
		 	echo "		$i ${dirs[i]}"
		done
      
      
      
      exit 0
      ;;
    p) paralel_run=$OPTARG
      ;; 
    u) MAX=$OPTARG
      ;;  
    l) MIN=$OPTARG
      ;; 
    s) STEP=$OPTARG
      ;;  
    d) dir=$OPTARG
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
echo "  Parallel Runs       : $paralel_run (Maximum number of parallel simulations"
echo "                        that can be run at the same time on the server)"
echo "  Max Injection Ratio : $MAX (Maximum packet injection ratio)"
echo "  Min Injection Ratio : $MIN (Minimum packet injection ratio)"
echo "  Step Size           : $STEP (Simulation starts at MIN and increments by"
echo "                        STEP to reach MAX)"
echo "  Target Directory    : $dir (The model target directory where simulation"
echo "                        is running)"
if [ -n "$model" ]; then
    echo "  Model Under Test    : $model (The model name under test)"
fi
if [ -n "$Leftovers" ]; then
    echo "  Leftover Arguments  : $Leftovers (Additional arguments passed to the script)"
fi
echo "---------------------------------------------"

args="-p $paralel_run -u $MAX -l $MIN -s $STEP -d $dir $model"



report="${SCRPT_DIR_PATH}/reports/${dir}_report"


if [ -f "$report" ]; then
    rm "$report"
fi




#copy_sources
#login_in_server

#step one login in the server and find how much is bussy 
function get_server_load_percentage {
	 # Retrieve uptime and core information from the server
    out=$(ssh -t -o "StrictHostKeyChecking no" "$1" "uptime")
    load_avg=$(echo "$out" | grep -oP '(?<=load average: )[\d.]+' | head -n 1)  # Extract 1-minute load average
    nproc=$(ssh -t -o "StrictHostKeyChecking no" "$1" "nproc" | tr -d '\r')  # Remove any extra characters (e.g., carriage return)

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
	ssh  -o "StrictHostKeyChecking no" $my_server  rm -rf  ${SERVER_ROOT_DIR}
	ssh  -o "StrictHostKeyChecking no" $my_server  mkdir -p "${SERVER_ROOT_DIR}/mpsoc/perl_gui/lib/"
    ssh  -o "StrictHostKeyChecking no" $my_server  mkdir -p "${SERVER_ROOT_DIR}/mpsoc/src_c/"
	ssh  -o "StrictHostKeyChecking no" $my_server  mkdir -p "${SERVER_ROOT_DIR}/mpsoc_work"
	for i in "${my_srcs[@]}"; do	
		echo "Copy $i  on the server"        
		scp  -o "StrictHostKeyChecking no" -r "$ProNoC/$i"  "$my_server:${SERVER_ROOT_DIR}/mpsoc/$i"
	done
	scp  -o "StrictHostKeyChecking no" -r "$SCRPT_DIR_PATH/server_run.sh"  "$my_server:${SERVER_ROOT_DIR}/mpsoc/Integration_test/synthetic_sim/server_run.sh"	
}


function run_test {
	cmd="export PRONOC_WORK=${SERVER_ROOT_DIR}/mpsoc_work;" 
	ssh -t -o "StrictHostKeyChecking no" $my_server $cmd

}

#setps to run the verrification 

#1
select_a_server
#2
copy_sources
#3 run the test

echo "source \"/etc/profile\"; bash server_run.sh $args"
ssh  -o "StrictHostKeyChecking no" $my_server  "cd ${SERVER_ROOT_DIR}/mpsoc/Integration_test/synthetic_sim;  source \"/etc/profile\";  bash   server_run.sh $args;"

#collect the report
if [ -f "$report" ]; then
    rm "$report"
fi

scp  -o "StrictHostKeyChecking no" -r   "$my_server:${SERVER_ROOT_DIR}/mpsoc/Integration_test/synthetic_sim/report"  "$report"
wait
meld "$report" "${report}_old" &

