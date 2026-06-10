`ifndef PRONOC_DEF
`define PRONOC_DEF
    
    // Reset Configurations
    `define SYNC_RESET_MODE
    /*
     *  Reset is synchronous by default.
     *  comment this line to enable synchronous reset.
     */
    
    // `define ACTIVE_LOW_RESET_MODE
    /*
     *  Reset is active-high by default.
     *  Uncomment this line to enable an active-low reset.
     */
    
    /******************
     * Define SIMULATION for supported RTL simulators
     *******************/
    
    `ifdef VERILATOR
        `define SIMULATION
    `endif
    
    `ifdef MODEL_TECH  // ModelSim/Questa
        `define SIMULATION  
    `endif  
    
    `ifdef VCS  // Synopsys VCS
        `define SIMULATION
    `endif  
    
    `ifdef XCELIUM  // Cadence Xcelium
        `define SIMULATION
    `endif
    
    `ifdef RIVIERA  // Aldec Riviera-PRO
        `define SIMULATION
    `endif
    
    `ifdef SIMULATION
        `timescale 1ns/1ps
    `endif
    
    /****************
     * Enable TRACE Dump
     ****************/
    
    `ifdef SIMULATION
        // Uncomment the following defines to enable TRACE dumping  
        // `define TRACE_DUMP_PER_NoC        // Dump all in/out traces of the NoC into a single file  
        // `define TRACE_DUMP_PER_ROUTER     // Dump in/out traces of each router into a separate file  
        // `define TRACE_DUMP_PER_PORT       // Dump in/out traces of each router port into a separate file  
    `endif
    
    // Clock and Reset Edge Definitions
    `ifdef SYNC_RESET_MODE
        `define pronoc_clk_reset_edge posedge clk
    `else
        `ifdef ACTIVE_LOW_RESET_MODE
            `define pronoc_clk_reset_edge posedge clk or negedge reset
        `else
            `define pronoc_clk_reset_edge posedge clk or posedge reset
        `endif
    `endif
    
    // Reset Signal Definition
    `ifdef ACTIVE_LOW_RESET_MODE
        `define pronoc_reset !reset
    `else
        `define pronoc_reset reset
    `endif
    
    // Library Usage
    `ifdef USE_LIB
        `uselib lib=`USE_LIB
    `endif
    
    
`endif // PRONOC_DEF
