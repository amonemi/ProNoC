`include "pronoc_def.v"

`ifdef SIMULATION
module synfull_top;
    parameter NOC_ID=0;
    `NOC_CONF
    import dpi_int_pkg::*; 
    
    reg     reset ,clk;
    reg print_router_st;
    
    initial begin 
        clk = 1'b0;
        forever clk = #10 ~clk;
    end 
    
    smartflit_chanel_t chan_in_all  [NE-1 : 0];
    smartflit_chanel_t chan_out_all [NE-1 : 0];
    router_event_t router_event [NR-1 : 0] [MAX_P-1 : 0];
    
    pck_injct_t pck_injct_in [NE-1 : 0];
    pck_injct_t _pck_injct_in [NE-1 : 0];
    pck_injct_t pck_injct_out[NE-1 : 0];
    
    logic [NE-1 : 0] NE_ready_all    ;
    logic [NE-1 : 0] init_socket     ;
    logic [NE-1 : 0] wakeup_synfull  ;
    logic [NE-1 : 0] end_injection   ;
    logic            end_synfull     ;
    
    req_t     [NE-1 : 0] synfull_pronoc_req_all  ;
    deliver_t [NE-1 : 0] pronoc_synfull_del_all  ;
    
    noc_top #( 
        .NOC_ID(NOC_ID)
    ) the_noc (
        .reset(reset),
        .clk(clk),    
        .chan_in_all(chan_in_all),
        .chan_out_all(chan_out_all),
        .router_event(router_event)
    );
    
    top_dpi_interface synfull (
        .clk_i(clk), .rst_i(reset),
        .init_i                     (init_socket[0]         ),
        .startCom_i                 (wakeup_synfull[0]      ),
        .pronoc_synfull_del_all_i   (pronoc_synfull_del_all ),  
        .synfull_pronoc_req_all_o   (synfull_pronoc_req_all ),
        .NE_ready_all_i             (NE_ready_all           ),
        .endCom_o                   (end_injection[0]       )  
    );
    
    reg [NEw-1 : 0] dest_id [NE-1 : 0];
    wire [NEw-1: 0] current_e_addr [NE-1 : 0];
    reg [63 : 0]  total_sent_pck_count;
    reg [63 : 0]  total_sent_flit_count;
    reg [63 : 0]  total_rsv_pck_count;
    reg [63 : 0]  total_rsv_flit_count;
    reg [63 : 0]  total_queued_pck_count;
    reg [63 : 0]  clk_count;
    
    initial begin      
        //print_parameter 
        display_noc_parameters();    
        $display ("Simulation parameters-------------");
        if(DEBUG_EN)
            $display ("\tDebuging is enabled");
        else
            $display ("\tDebuging is disabled");
    end//initial
    
    wire [31:0] fifo_id [NE-1 : 0];
    wire [PCK_SIZw-1 : 0]  fifo_size [NE-1 :0];
    wire [NEw-1 : 0] fifo_dest [NE-1 : 0];
    wire [NE-1 : 0] fifo_wr,fifo_rd ,fifo_full,fifo_not_empty;
    
    genvar i;
    generate 
    for(i=0; i< NE; i=i+1) begin 
        assign fifo_wr[i] = 
            (pck_injct_out[i].ready == 1'b0 &&  synfull_pronoc_req_all[i].valid==1'b1) ||  
            (fifo_not_empty[i]==1'b1  &&  synfull_pronoc_req_all[i].valid==1'b1);
        
        assign fifo_rd[i] = 
            (pck_injct_out[i].ready == 1'b1 && fifo_not_empty[i]==1'b1 );
        
        fwft_fifo_bram #(
            .DATA_WIDTH(32+PCK_SIZw+NEw),
            .MAX_DEPTH(1000000),
            .IGNORE_SAME_LOC_RD_WR_WARNING("NO") 
        ) fifo  (
            .din({synfull_pronoc_req_all[i].id,synfull_pronoc_req_all[i].size,synfull_pronoc_req_all[i].dest}),     // Data in
            .wr_en(fifo_wr[i]),   // Write enable
            .rd_en(fifo_rd[i]),   // Read the next word
            .dout({fifo_id[i],fifo_size[i],fifo_dest[i]}),    // Data out
            .full( fifo_full[i]),
            .nearly_full(),
            .recieve_more_than_0(fifo_not_empty[i]),
            .recieve_more_than_1(),
            .reset(reset),
            .clk (clk)
        );        
        
        //from synfull 
        assign pck_injct_in[i].data = (fifo_not_empty[i])?  fifo_id[i] : synfull_pronoc_req_all[i].id;
        assign pck_injct_in[i].size = (fifo_not_empty[i])?  fifo_size[i] : synfull_pronoc_req_all[i].size;
        assign pck_injct_in[i].pck_wr =  (fifo_not_empty[i])?   fifo_rd[i] :  (  synfull_pronoc_req_all[i].valid & pck_injct_out[i].ready == 1'b1);  
        assign pck_injct_in[i].ready = 1'b1;
        assign dest_id[i] =(fifo_not_empty[i])? fifo_dest[i] : synfull_pronoc_req_all[i].dest;             
        //to synfull
        assign pronoc_synfull_del_all[i].id    = pck_injct_out[i].data   ; 
        assign pronoc_synfull_del_all[i].valid = pck_injct_out[i].pck_wr ;
        assign NE_ready_all[i] = 1'b1 ; //pck_injct_out[i].ready;
        assign pck_injct_in[i].class_num = _pck_injct_in[i].class_num; 
        assign pck_injct_in[i].init_weight = _pck_injct_in[i].init_weight;
        assign pck_injct_in[i].vc = _pck_injct_in[i].vc;
        
        endp_addr_encoder #( .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) encode1 ( .id(i[NEw-1 :0]), .code(current_e_addr[i]));
        packet_injector #(
            .NOC_ID(NOC_ID)
        ) pck_inj (
            //general
            .current_e_addr(current_e_addr[i]),
            .reset(reset),
            .clk(clk),      
            //noc port
            .chan_in(chan_out_all[i]),
            .chan_out(chan_in_all[i]),  
            //control interafce
            .pck_injct_in(pck_injct_in[i]),
            .pck_injct_out(pck_injct_out[i])        
        );          
        endp_addr_encoder #( .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) encode2 ( .id(dest_id[i]), .code(pck_injct_in[i].endp_addr));
        reg [31:0]k;
        
        initial begin 
        `ifdef ACTIVE_LOW_RESET_MODE 
            reset = 1'b0;
        `else 
            reset = 1'b1;
        `endif  
            k=0;
            init_socket[i] = 1'b0;
            wakeup_synfull[i] = 1'b0;
            print_router_st=1'b0;
            @(posedge clk) #1;
            _pck_injct_in[i].class_num=0; 
            _pck_injct_in[i].init_weight=1;
            _pck_injct_in[i].vc=1;
            #100
            @(posedge clk) #1;
            reset=~reset;
            #100
            init_socket[i] = 1'b1;
            @(posedge clk) #1;
            init_socket[i] = 1'b0;
            #100
            wakeup_synfull[i] = 1'b1;
            @(posedge clk) #1;
            while (!end_injection[0]) @(posedge clk) #1;
            // if(i==0) $display ( "All packet are sent. We wait for NoC to be ideal now");
            // while (total_sent_pck_count != total_rsv_pck_count) @(posedge clk) #1;
            print_router_st=1;
            #1
            $display ( "Statistics:");
            $display ( "\t simulation clk count = %d",   clk_count);
            $display ( "\t Total queued packets = %d",total_queued_pck_count);
            $display ( "\t Total sent packets = %d", total_sent_pck_count);
            $display ( "\t Total sent flits = %d",      total_sent_flit_count);  
            $display ( "\t Total received packets = %d", total_rsv_pck_count);
            $display ( "\t Total received flits = %d",      total_rsv_flit_count);  
            $finish;
        end
        
        always @(posedge clk) begin
            if(pck_injct_out[i].pck_wr) begin 
                $display ("%t:pck_inj(%d) got a packet: source=%d, size=%d, data=%h",$time,i,
                pck_injct_out[i].endp_addr,pck_injct_out[i].size,pck_injct_out[i].data);
            end        
        end
    end//for
    endgenerate
    
    integer k;
    always @(posedge clk) begin
        if(`pronoc_reset) begin 
            clk_count =0;
            total_sent_pck_count =0;
            total_sent_flit_count=0;
            total_rsv_pck_count  =0;
            total_rsv_flit_count =0;  
            total_queued_pck_count = 0;
        end else begin              
            clk_count++;
            for(k=0; k< NE; k=k+1) begin : endpoints            
                if(pck_injct_out[k].pck_wr) begin 
                    total_rsv_pck_count++;
                    total_rsv_flit_count+=pck_injct_out[k].size;                
                end 
                if(pck_injct_in[k].pck_wr) begin 
                    total_sent_pck_count++;
                    total_sent_flit_count+=pck_injct_in[k].size;                
                end 
                if(synfull_pronoc_req_all[k].valid) begin
                    total_queued_pck_count++;
                end            
            end    
        end
    end
    
    routers_statistic_collector # (
        .NOC_ID(NOC_ID)
    ) router_stat ( 
        .reset(reset),
        .clk(clk),        
        .router_event(router_event),
        .print(print_router_st)
    );
endmodule
`endif

