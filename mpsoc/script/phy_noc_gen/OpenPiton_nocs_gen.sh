#!/bin/bash

# This script generates three physical NoCs for OpenPiton using ProNoC RTL code.
# Each physical NoC (phynoc) is configured with unified module and parameter names.
# The NoC number is appended to parameters, functions, and module names to ensure uniqueness.

# Get the full path of the script
SCRIPT_FULL_PATH=$(realpath "${BASH_SOURCE[0]}")
SCRIPT_DIR_PATH=$(dirname "$SCRIPT_FULL_PATH")

# OpenPiton target NoC directory
op_nocs_dir="$SCRIPT_DIR_PATH/../../rtl/src_openpiton"

# ProNoC RTL dir
pronoc_dir="$SCRIPT_DIR_PATH/../../rtl/src_noc"

# Script to create physical NoCs
phy_noc_gen="$SCRIPT_DIR_PATH/phy_noc.pl"

cp  $op_nocs_dir/wrapper.sv   $pronoc_dir/wrapper.sv
mv  $pronoc_dir/noc_localparam.v  $pronoc_dir/noc_localparam.v.tmp
cp  $op_nocs_dir/noc_localparam.v $pronoc_dir/noc_localparam.v
# Loop to generate three physical NoCs
IN=""
LIST=""
for i in {1..3}; do
    mkdir -p "$op_nocs_dir/nocs/noc$i"
    perl "$phy_noc_gen" "$i" "$op_nocs_dir/nocs/noc$i"
    IN+="+incdir+./noc${i}\n"
    LIST+="-F ./noc${i}/noc_filelist_N${i}.f\n"
    LIST+="./noc${i}/wrapper_N${i}.sv\n"
    
done
rm $pronoc_dir/wrapper.sv
mv $pronoc_dir/noc_localparam.v.tmp  $pronoc_dir/noc_localparam.v

#generate the file list
# Generate the file list for physical NoCs
printf "${IN}$LIST" > "$op_nocs_dir/nocs/Flist.pronoc"


