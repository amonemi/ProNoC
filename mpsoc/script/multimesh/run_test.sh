#!/bin/bash

# Enable strict mode
set -euo pipefail

# Get the script's full and directory path
SCRPT_FULL_PATH=$(realpath "${BASH_SOURCE[0]}")
SCRPT_DIR_PATH=$(dirname "$SCRPT_FULL_PATH")

# Define root and work directories
root=$(realpath "$SCRPT_DIR_PATH/../..")
work="$root/../mpsoc_work/multi_mesh"

# Generate NoC configuration from YAML
CONFIG_FILE="$PITON_ROOT/configs/multi_chip/2d5_36cores.yaml"

echo "[INFO] This script generates a MultiMesh NoC using the configuration file: $CONFIG_FILE."
echo "[INFO] It then runs a Random Uniform traffic test on the generated NoC."
echo "[INFO] To test a different NoC configuration, modify the CONFIG_FILE variable in this script."
echo "[INFO] To adjust synthetic traffic settings (e.g., traffic pattern, number of injected packets, packet size, etc ..), modify the parameters in src/sim_param.sv.
"

echo "work: $work"
echo "SCRIPT_DIR_PATH: $SCRPT_DIR_PATH"

# Export necessary environment variables
export WORK_MMESH="$work"
export SOURCE_DIR="$SCRPT_DIR_PATH/src"

# Ensure required tools exist
command -v realpath >/dev/null 2>&1 || { echo "Error: realpath is required but not installed." >&2; exit 1; }
command -v perl >/dev/null 2>&1 || { echo "Error: perl is required but not installed." >&2; exit 1; }


# Change to script directory
cd "$SCRPT_DIR_PATH"


if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: NoC config file not found at $CONFIG_FILE"
    exit 1
fi

# NOTE: This generates by default the multi-mesh modules in $root/rtl/src_multi_mesh/build
python3 $PITON_ROOT/piton/tools/bin/piton_arch.py --filename "$CONFIG_FILE" --gen_sv

# Copy generated parameter file, ensuring the source exists
SRC_FILE="$root/rtl/src_multi_mesh/build/noc_localparam.v"
DEST_FILE="$root/rtl/src_noc/noc_localparam.v"
if [[ -f "$SRC_FILE" ]]; then
    cp "$SRC_FILE" "$DEST_FILE"
else
    echo "Error: Source file $SRC_FILE not found."
    exit 1
fi

# Create working directory if it does not exist
mkdir -p "$work"

# Source QuestaSim environment script
QUESTA_ENV_SCRIPT="$work/../Questa_20.4.sh"
if [[ -f "$QUESTA_ENV_SCRIPT" ]]; then
    source "$QUESTA_ENV_SCRIPT"
else
    echo "Warning: QuestaSim environment script not found at $QUESTA_ENV_SCRIPT. Simulation may fail."
fi

# Move to working directory and run ModelSim script
cd "$work"
if [[ ! -f "$SCRPT_DIR_PATH/src/model.tcl" ]]; then
    echo "Error: ModelSim script not found at $SCRPT_DIR_PATH/src/model.tcl"
    exit 1
fi

command -v vsim >/dev/null 2>&1 || { echo "Error: vsim (QuestaSim) is required but not installed." >&2; exit 1; }

vsim -do "$SCRPT_DIR_PATH/src/model.tcl"

# Return to original directory
cd -

