#!/bin/bash



top="packet_injector_verilator"
#top="noc_top_v"
#top="router_top_v"
#top="multicast_chan_in_process"
top="traffic_gen_top"

echo "filelist: $1";
verilator --lint-only  --cc  --top-module $top   --profile-cfuncs --prefix "Vnoc" -O3  -CFLAGS -O3 -f $1/noc_filelist.f -y $1 -y $1/..
