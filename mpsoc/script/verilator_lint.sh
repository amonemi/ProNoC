#!/bin/bash
echo "filelist: $1";
export workspace_loc="$1/../.."
verilator --lint-only  --cc  --top-module "noc"   --profile-cfuncs --prefix "Vnoc" -O3  -CFLAGS -O3 -f $1/noc_files.f -y ${workspace_loc}/mpsoc/rtl/src_noc/
