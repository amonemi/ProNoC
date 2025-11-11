#!/bin/bash

# This script generates three physical NoCs for OpenPiton using ProNoC RTL code.
# Depending on the arguments given, the script will either use the Fmesh or the
# Multi-mesh topology.
# Each physical NoC (phynoc) is configured with unified module and parameter names.
# The NoC number and the chip name are appended to parameters, functions, and
# module names to ensure uniqueness.

# Get the full path of the script
SCRIPT_FULL_PATH=$(realpath "${BASH_SOURCE[0]}")
SCRIPT_DIR_PATH=$(dirname "$SCRIPT_FULL_PATH")

# OpenPiton target NoC directory
op_nocs_dir="$SCRIPT_DIR_PATH/../../rtl/src_openpiton"
multimesh_nocs_dir="$SCRIPT_DIR_PATH/../../rtl/src_multi_mesh"
build_multimesh_nocs_dir="$SCRIPT_DIR_PATH/../../rtl/src_multi_mesh/build"

# ProNoC RTL dir
pronoc_dir="$SCRIPT_DIR_PATH/../../rtl/src_noc"

# Script to create physical NoCs
phy_noc_gen="$SCRIPT_DIR_PATH/phy_noc.pl"

# Build directory
phy_nocs_out_dir="$op_nocs_dir/nocs"

# Depth-First NoC Config File
dp_config_file=""

# Optional path pointing on an intermediate ProNoC source directory
intermediate_pronoc_dir="$pronoc_dir"

# Parse script options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --custom_phy_nocs_out_dir)
            phy_nocs_out_dir="$2"
            shift 2
            ;;
        --config-file)
            dp_config_file="$2"
            shift 2
            ;;
        --intermediate-dir)
            intermediate_pronoc_dir="$2"
            build_multimesh_nocs_dir="$intermediate_pronoc_dir/../src_multi_mesh/build"
            shift 2
            ;;
        *)
            echo "Invalid Option: $1" >&2
            exit 1
            ;;
    esac
done

# Check if intermediate_pronoc_dir and pronoc_dir points to different paths
# If that is the case, copy all necessary files to compile the design in this
# intermediate directory
if [ ! "$intermediate_pronoc_dir" -ef "$pronoc_dir" ]; then
    mkdir -p "$intermediate_pronoc_dir"
    cp -r "$pronoc_dir/"* "$intermediate_pronoc_dir"
    cp "$pronoc_dir/../pronoc_def.v" "$intermediate_pronoc_dir/../"
    cp "$pronoc_dir/../arbiter.v"    "$intermediate_pronoc_dir/../"
    cp "$pronoc_dir/../main_comp.v"  "$intermediate_pronoc_dir/../"
fi

# If Multi-mesh is used, launch the generation of the sources
if [ -n "$dp_config_file" ]; then
    python3 $PITON_ROOT/piton/tools/bin/piton_arch.py --filename "$dp_config_file" --gen_sv --build_dir "$build_multimesh_nocs_dir"
    if [ $? -ne 0 ]; then
        echo "NoC generation from $dp_config_file failed"
        exit 1
    fi
fi

# If Multi-mesh is used, copy the related sources in the main source directory
if [ -n "$dp_config_file" ]; then
    cp "$multimesh_nocs_dir/mesh_cluster.sv" "$intermediate_pronoc_dir/mesh_cluster.sv"
    cp "$build_multimesh_nocs_dir/multi_mesh_icr.sv" "$intermediate_pronoc_dir/multi_mesh_icr.sv"
    cp "$build_multimesh_nocs_dir/multi_mesh_routing.sv" "$intermediate_pronoc_dir/multi_mesh_routing.sv"
fi

# If the ProNoC sources are compiled in-place, save the previous noc_localparam file
if [ "$intermediate_pronoc_dir" -ef "$pronoc_dir" ]; then
    mv "$pronoc_dir/noc_localparam.v" "$pronoc_dir/noc_localparam.v.tmp"
fi

# Copy this module, needed for both Fmesh/Multi-mesh wrapper
cp "$op_nocs_dir/piton_tail_hdr_detect.sv" "$intermediate_pronoc_dir/piton_tail_hdr_detect.sv"

# Copy either the Multi-mesh or the Fmesh wrapper/noc_localparam, depending on the option given
if [ -n "$dp_config_file" ]; then
    cp "$multimesh_nocs_dir/piton_wrapper.sv" "$intermediate_pronoc_dir/piton_wrapper.sv"
    cp "$build_multimesh_nocs_dir/noc_localparam.v" "$intermediate_pronoc_dir/noc_localparam.v"
else
    cp "$op_nocs_dir/piton_wrapper.sv" "$intermediate_pronoc_dir/piton_wrapper.sv"
    cp "$op_nocs_dir/noc_localparam.v" "$intermediate_pronoc_dir/noc_localparam.v"
fi

# Base values for Fmesh topology
chips_name=('base')
chips_id=('0')

if [ -n "$dp_config_file" ]; then
    # Retrieve the list of chips name and chipid
    list_chips_name=$(python3 $PITON_ROOT/piton/tools/bin/piton_arch.py --filename "$dp_config_file" --list_chips_name)
    list_chips_id=$(python3 $PITON_ROOT/piton/tools/bin/piton_arch.py --filename "$dp_config_file" --list_chips_id)
    # Convert bash strings into arrays
    read -ra chips_name <<< "$list_chips_name"
    read -ra chips_id <<< "$list_chips_id"
fi

# Loop to generate three physical NoCs
IN=""
LIST=""
for i in "${!chips_name[@]}"; do
    chip_name="${chips_name[i]}"
    chip_id="${chips_id[i]}"
    for i in {1..3}; do
        mkdir -p "$phy_nocs_out_dir/${chip_name}/noc$i"
        perl "$phy_noc_gen" "N${i}" "$phy_nocs_out_dir/$chip_name/noc$i" "${chip_name}" "${chip_id}" "$intermediate_pronoc_dir"
        IN+="+incdir+./$chip_name/noc${i}\n"
        LIST+="-F ./$chip_name/noc${i}/noc_filelist_${chip_name}_N${i}.f\n"
        LIST+="./$chip_name/noc${i}/piton_wrapper_${chip_name}_N${i}.sv\n"
        LIST+="./$chip_name/noc${i}/piton_tail_hdr_detect_${chip_name}_N${i}.sv\n"
        if [ -n "$dp_config_file" ]; then
            LIST+="./$chip_name/noc${i}/mesh_cluster_${chip_name}_N${i}.sv\n"
            LIST+="./$chip_name/noc${i}/multi_mesh_icr_${chip_name}_N${i}.sv\n"
            LIST+="./$chip_name/noc${i}/multi_mesh_routing_${chip_name}_N${i}.sv\n"
        fi
    done
done

# Clean up and restore the original file
if [ "$intermediate_pronoc_dir" -ef "$pronoc_dir" ]; then
    rm "$pronoc_dir/piton_wrapper.sv"
    rm "$pronoc_dir/piton_tail_hdr_detect.sv"
    if [ -n "$dp_config_file" ]; then
        rm "$pronoc_dir/mesh_cluster.sv"
        rm "$pronoc_dir/multi_mesh_icr.sv"
        rm "$pronoc_dir/multi_mesh_routing.sv"
    fi
    mv "$pronoc_dir/noc_localparam.v.tmp" "$pronoc_dir/noc_localparam.v"
fi

# Generate the file list for physical NoCs
printf "${IN}$LIST" > "$phy_nocs_out_dir/Flist.pronoc"
