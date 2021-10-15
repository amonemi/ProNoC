#!/bin/bash

#the max server load that is permited for runing the parallel test
max_allowed_server_load=35
source "my_password.sh" # define servers and passwords

SCRPT_FULL_PATH=$(realpath ${BASH_SOURCE[0]})
SCRPT_DIR_PATH=$(dirname $SCRPT_FULL_PATH)





#servers=( $server1 $server2 $server3 ) # an array which define the list of servers 
my_server="to be selected"
SERVER_ROOT_DIR="~/pronoc_verify"

ProNoC="../../.."

my_srcs=( "rtl"
    "smart-netrace"
	"src_verilator"
	"src_c/netrace-1.0"
	"script"
	"/perl_gui/lib/perl" )


rm "$SCRPT_DIR_PATH/report"




#copy_sources
#login_in_server

#step one login in tje server and read the load 
function get_server_avg_load {
	out=$(sshpass -p $my_passwd ssh -t -o "StrictHostKeyChecking no" $1  "uptime")
	load_avg=$(grep -oP '(?<=load average: )[0-9]+' <<< $out)		
}


function select_a_server {
	min_load="100"
	
	for i in "${servers[@]}"; do
	 		echo "get load average on $i server"        
			get_server_avg_load $i
			echo $load_avg
			if [ $min_load  -gt $load_avg ]
			then
				min_load=$load_avg
				my_server=$i
			fi		
	done
	if [ $min_load -gt $max_allowed_server_load ] 
	then
		echo "All servers are busy. Cannot continue"		
		exit
	fi
	echo "server $my_server is selected for running the test"
}


function copy_sources {
	sshpass -p $my_passwd ssh  -o "StrictHostKeyChecking no" $my_server  rm -rf  ${SERVER_ROOT_DIR}
	sshpass -p $my_passwd ssh  -o "StrictHostKeyChecking no" $my_server  mkdir -p "${SERVER_ROOT_DIR}/mpsoc/perl_gui/lib/"
    sshpass -p $my_passwd ssh  -o "StrictHostKeyChecking no" $my_server  mkdir -p "${SERVER_ROOT_DIR}/mpsoc/src_c/"
	sshpass -p $my_passwd ssh  -o "StrictHostKeyChecking no" $my_server  mkdir -p "${SERVER_ROOT_DIR}/mpsoc_work"
	for i in "${my_srcs[@]}"; do	
		echo "Copy $i  on the server"        
		sshpass -p $my_passwd scp  -o "StrictHostKeyChecking no" -r "$ProNoC/$i"  "$my_server:${SERVER_ROOT_DIR}/mpsoc/$i"
	done
	sshpass -p $my_passwd scp  -o "StrictHostKeyChecking no" -r "$SCRPT_DIR_PATH/server_run.sh"  "$my_server:${SERVER_ROOT_DIR}/mpsoc/smart-netrace/server_run.sh"	
}


function run_test {
	cmd="export PRONOC_WORK=${SERVER_ROOT_DIR}/mpsoc_work;" 
	sshpass -p $my_passwd ssh -t -o "StrictHostKeyChecking no" $my_server $cmd

}

#setps to run the verrification 

#1
select_a_server
#2
copy_sources
#3 run the test

sshpass -p $my_passwd ssh  -o "StrictHostKeyChecking no" $my_server  "cd ${SERVER_ROOT_DIR}/mpsoc/smart-netrace;  source \"/etc/profile\";  bash   server_run.sh;"

#collect the report
rm "$SCRPT_DIR_PATH/report"
sshpass -p $my_passwd scp  -o "StrictHostKeyChecking no" -r   "$my_server:${SERVER_ROOT_DIR}/mpsoc/smart-netrace/report"  "$SCRPT_DIR_PATH/report"
wait
gedit "$SCRPT_DIR_PATH/report"

