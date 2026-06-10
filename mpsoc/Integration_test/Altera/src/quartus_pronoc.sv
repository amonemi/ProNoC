`include "pronoc_def.v"

module quartus_pronoc
(
    clk,
    reset,
    chan_in,
    chan_out,
    sel_in,
    sel_out
);

    import pronoc_pkg::*;

    input  [NE-1      :   0]  sel_in;
    input  [NEw-1     :   0]  sel_out;
    input  smartflit_chanel_t chan_in;
    output  smartflit_chanel_t chan_out;
    input reset,clk;
    

    smartflit_chanel_t chan_in_all  [NE-1 : 0];
    smartflit_chanel_t chan_out_all [NE-1 : 0];
    smartflit_chanel_t chan_out_all_reg [NE-1 : 0];
    
    wire noc_reset;

    noc_top top (
        .reset(noc_reset),
        .clk(clk),    
        .chan_in_all(chan_in_all),
        .chan_out_all(chan_out_all),
        .router_event( )
    );
    
    
    altera_reset_synchronizer sync(
        .reset_in    (reset), 
        .clk        (clk),
        .reset_out    (noc_reset)
    );

    //NoC port assignment
    
    assign chan_out    = chan_out_all_reg[sel_out];  

    always @(posedge clk) begin 
        chan_out_all_reg  <= chan_out_all;
    end

    genvar IP_NUM;
    generate 
    for (IP_NUM=0;   IP_NUM<NE; IP_NUM=IP_NUM+1) begin :endp

            always @(posedge clk) begin 
                if(sel_in[IP_NUM] ) begin 
                    chan_in_all[IP_NUM]<= chan_in;
                end 
            end
    end
    endgenerate

endmodule
