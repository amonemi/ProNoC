`include "pronoc_def.v"

module   custom_noc_top 
    (
    reset,
    clk,
    chan_in_all,
    chan_out_all,
    router_event
);
    import pronoc_pkg::*;
    
    input   clk,reset;
    //local ports 
    input   smartflit_chanel_t chan_in_all  [NE-1 : 0];
    output  smartflit_chanel_t chan_out_all [NE-1 : 0];
    
    //Events
    output  router_event_t  router_event [NR-1 : 0][MAX_P-1 : 0];
    generate 
    
    //do not modify this line ===custom1===
    if(TOPOLOGY == "custom1" ) begin : Tcustom1
        custom1_noc_genvar the_noc (
            .reset(reset),
            .clk(clk),
            .chan_in_all(chan_in_all),
            .chan_out_all(chan_out_all),
            .router_event(router_event)  
        );
    end
    endgenerate
    
endmodule 
