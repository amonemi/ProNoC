#!/bin/bash

# This script generates three physical NoCs for OpenPiton using ProNoC RTL code.
# Each physical NoC (phynoc) is configured with unified module and parameter names.
# The NoC number is appended to parameters, functions, and module names to ensure uniqueness.

# Get the full path of the script
SCRIPT_FULL_PATH=$(realpath "${BASH_SOURCE[0]}")
SCRIPT_DIR_PATH=$(dirname "$SCRIPT_FULL_PATH")

# OpenPiton target NoC directory
op_nocs_dir="$SCRIPT_DIR_PATH/../../rtl/src_ambachi"

# ProNoC RTL dir
pronoc_dir="$SCRIPT_DIR_PATH/../../rtl/src_noc"

# Script to create physical NoCs
phy_noc_gen="$SCRIPT_DIR_PATH/phy_noc.pl"

cp "$op_nocs_dir/chi_wrapper.sv" "$pronoc_dir/chi_wrapper.sv"
mv -f "$pronoc_dir/noc_localparam.v" "$pronoc_dir/noc_localparam.v.tmp"
cp "$op_nocs_dir/noc_localparam.v" "$pronoc_dir/noc_localparam.v"

# Loop to generate three physical NoCs
IN=""
LIST=""
arr=("dat" "rsp" "snp" "req")

for i in "${arr[@]}"; do
    mkdir -p "$op_nocs_dir/nocs/noc_$i"
    perl "$phy_noc_gen" "$i" "$op_nocs_dir/nocs/noc_$i"
    IN+="+incdir+./noc_${i}\n"
    LIST+="-F ./noc_${i}/noc_filelist_${i}.f\n"
    LIST+="./noc_${i}/chi_wrapper_${i}.sv\n"
    #remove common files from noc_filelist_${i}.f
    sed -i '/arbiter.sv/d' "$op_nocs_dir/nocs/noc_$i/noc_filelist_${i}.f"
    sed -i '/main_comp.sv/d' "$op_nocs_dir/nocs/noc_$i/noc_filelist_${i}.f"
done

# Add common files to the file list
LIST+="./arbiter.sv\n"
LIST+="./main_comp.sv\n"

# Clean up and restore the original file
rm "$pronoc_dir/chi_wrapper.sv"
mv "$pronoc_dir/noc_localparam.v.tmp" "$pronoc_dir/noc_localparam.v"

# Generate the file list for physical NoCs
printf "${IN}$LIST" > "$op_nocs_dir/nocs/Flist.pronoc"
