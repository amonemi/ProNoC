`include "pronoc_def.v"
parameter NOC_ID=0;
`NOC_CONF
import dpi_int_pkg::*;
module top_dpi_interface (
    input   logic               clk_i, rst_i  ,
    input   logic               init_i                          ,
    input   logic               startCom_i                      ,
    input   logic     [NE-1:0]  NE_ready_all_i                  ,
    input   deliver_t [NE-1:0]  pronoc_synfull_del_all_i        ,
    output  req_t     [NE-1:0]  synfull_pronoc_req_all_o        ,
    output  logic               endCom_o                             
);
    import "DPI-C" function void c_dpi_interface ( 
        logic          startCom            , 
        logic          getData             ,
        logic          ejectReq            , 
        logic          queueReq            , 
        output  logic  endCom              , 
        output  logic  newReq              , 
        output  int    source_all[NE]      , 
        output  int    destination_all[NE] , 
        output  int    address_all[NE]     ,
        output  int    opcode_all[NE]      ,
        output  int    id_all[NE]          ,
        output  int    valid_all[NE]       ,
        input   int    rtrn_pkgid_all[NE]  ,
        input   int    rtrn_valid_all[NE]  ,       
        input   int    NEready_all[NE]     ,                  
        output  int    size_all[NE]        ,
        input   int    enqueue_valid[NE]   ,
        input   int    enqueue_src[NE]     ,
        input   int    enqueue_dst[NE]     ,
        input   int    enqueue_id[NE]      ,
        input   int    enqueue_size[NE]                      
    );
    
    import "DPI-C" function void connection_init( 
        logic           startCom     , 
        output logic    ready         
    );
    
    int destination ;
    int opcode      ;
    int source      ;
    int addr        ;
    int pkgid       ;
    int NEready_all[NE]             ;
    int syn_source_all[NE]          ;
    int syn_size_all[NE]            ;
    int syn_opcode_all[NE]          ;
    int syn_destination_all[NE]     ;
    int syn_address_all[NE]         ;
    int syn_pkgid_all[NE]           ;
    int syn_valid_all[NE]           ;
    int chi_req_pkgid_all[NE]       ;
    int chi_req_valid_all[NE]       ;
    
    int enqueue_valid[NE];
    int enqueue_src[NE]  ;
    int enqueue_dst[NE]  ;
    int enqueue_id[NE]   ;
    int enqueue_size[NE] ;
    
    int _enqueue_valid[NE];
    int _enqueue_src[NE]  ;
    int _enqueue_dst[NE]  ;
    int _enqueue_id[NE]   ;
    int _enqueue_size[NE] ;
    
    logic newData             ;
    logic newReq              ;
    logic ready_connection    ;
    logic eject_req           ;
    logic queue_req           ;
    logic endCom              ;
    logic [NE-1:0] valid_check ;
    logic [NE-1:0] queue_check ;
    // socket connection
    always_ff @(posedge clk_i) begin 
        connection_init(
            init_i,ready_connection
        );
    end
    // trace injection
    always_ff @(posedge clk_i) begin 
        c_dpi_interface(
            startCom_i&ready_connection ,
            clk_i                       ,
            eject_req                   ,
            queue_req                   ,
            endCom_o                    ,
            newData                     ,
            syn_source_all              ,
            syn_destination_all         ,
            syn_address_all             , 
            syn_opcode_all              , 
            syn_pkgid_all               , 
            syn_valid_all               ,
            chi_req_pkgid_all           ,  
            chi_req_valid_all           ,           
            NEready_all                 ,
            syn_size_all                ,
            enqueue_valid               ,
            enqueue_src                 ,  
            enqueue_dst                 ,  
            enqueue_id                  ,   
            enqueue_size                 
        );
    end
    genvar k;
    generate     
    for(k=0;k<NE;k=k+1)begin
        //to pronoc
        assign synfull_pronoc_req_all_o[k].dest  = syn_destination_all[k];
        assign synfull_pronoc_req_all_o[k].size  = syn_size_all[k];
        assign synfull_pronoc_req_all_o[k].src   = syn_source_all[k];
        assign synfull_pronoc_req_all_o[k].id    = syn_pkgid_all[k];
        assign synfull_pronoc_req_all_o[k].valid = syn_valid_all[k][0] & NE_ready_all_i[k] ;
        //from pronoc
        assign chi_req_pkgid_all[k]       = pronoc_synfull_del_all_i[k].id       ;
        assign chi_req_valid_all[k]       = pronoc_synfull_del_all_i[k].valid    ;
        assign NEready_all[k]             = NE_ready_all_i[k]                    ;
        assign valid_check[k] = pronoc_synfull_del_all_i[k].valid;
        assign queue_check[k] = (syn_valid_all[k][0] & !NE_ready_all_i[k]);
        //to enqueue
        assign enqueue_valid[k] = (syn_valid_all[k][0] & !NE_ready_all_i[k]) ? 1 : 0  ;
        assign enqueue_src[k]   = syn_source_all[k]                         ;
        assign enqueue_dst[k]   = syn_destination_all[k]                    ;
        assign enqueue_id[k]    = syn_pkgid_all[k]                          ;
        assign enqueue_size[k]  = syn_size_all[k]                           ;
        
         //always @* begin
         //    if(syn_valid_all[k][0] & !NE_ready_all_i[k]) begin 
         //        $display ("not injected because the router injector is not ready: %d", syn_pkgid_all[k]);
         //    end      
         //end
    end
    endgenerate
    
    assign eject_req = !(valid_check=='0);
    assign queue_req = !(queue_check=='0);
    
    always_ff @ (posedge clk_i) begin
        if (!rst_i) begin
            _enqueue_valid <= '{default:'0} ;
            _enqueue_src   <= '{default:'0} ;
            _enqueue_dst   <= '{default:'0} ;
            _enqueue_id    <= '{default:'0} ;
            _enqueue_size  <= '{default:'0} ;
        end
        else begin
            _enqueue_valid <= enqueue_valid ;
            _enqueue_src   <= enqueue_src   ;
            _enqueue_dst   <= enqueue_dst   ;
            _enqueue_id    <= enqueue_id    ;
            _enqueue_size  <= enqueue_size  ;
        end
    end
endmodule