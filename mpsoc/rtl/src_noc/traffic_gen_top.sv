`include "pronoc_def.v"

module  traffic_gen_top  #(
    parameter MAX_RATIO = 1000,
    parameter ENDP_ID   = 100000
) (
    //noc port
    chan_in,
    chan_out,  
    
    //input 
    ratio,// real injection ratio  = (MAX_RATIO/100)*ratio
    pck_size_in,
    current_e_addr,
    dest_e_addr,
    pck_class_in,
    start, 
    stop,  
    report,
    init_weight,
    start_delay,
    
    //output
    pck_number,
    sent_done, // tail flit has been sent
    hdr_flit_sent,
    update, // update the noc_analayzer
    src_e_addr,
    flit_out_class,
    flit_out_wr,
    flit_in_wr,
    
    distance,
    pck_class_out,
    time_stamp_h2h,
    time_stamp_h2t,
    pck_size_o,
    mcast_dst_num_o,
    
    reset,
    clk
);
    
    import pronoc_pkg::*;
    
    localparam
        RATIOw= $clog2(MAX_RATIO),
        PCK_CNTw = log2(MAX_PCK_NUM+1),
        CLK_CNTw = log2(MAX_SIM_CLKs+1),
        AVG_PCK_SIZw = log2(10*MAX_PCK_SIZ+1),
        /* verilator lint_off WIDTH */
        W=WEIGHTw,
        PORT_B = (TOPOLOGY!="FMESH")?  LB :
        (ENDP_ID < NE_MESH_TORI)? LB :B; // in FMESH, the buffer size of endpoints connected to edge routers non-local ports are B not LB  
        /* verilator lint_on WIDTH */
    
    input   smartflit_chanel_t     chan_in;
    output  smartflit_chanel_t     chan_out;
    
    input  reset, clk;
    input  [RATIOw-1 :0] ratio;
    input  start,stop;
    output update;
    output [CLK_CNTw-1 :0] time_stamp_h2h,time_stamp_h2t;
    output [DISTw-1 :0] distance;
    output [Cw-1 :0] pck_class_out;
    
    // the current endpoint address
    input  [EAw-1 :0] current_e_addr;
    // the destination endpoint address
    input  [DAw-1 :0] dest_e_addr;  
    
    output [PCK_CNTw-1 :0] pck_number;
    input  [PCK_SIZw-1 :0] pck_size_in;
    
    output reg sent_done;
    output reg hdr_flit_sent;
    input  [Cw-1 :0] pck_class_in;
    input  [W-1 :0] init_weight;
    
    input report;
    input  [DELAYw-1 :0] start_delay;
    // the received packet source endpoint address
    output [EAw-1 : 0] src_e_addr;
    output [PCK_SIZw-1 : 0]    pck_size_o;
    output [NEw-1 : 0] mcast_dst_num_o;
    
    logic  [Fw-1 :0] flit_out;
    output  logic flit_out_wr;
    output  [Cw-1 : 0] flit_out_class;
    logic   [V-1 :0] credit_in;
    
    logic   [Fw-1 :0] flit_in;
    output logic flit_in_wr;
    logic  [V-1 :0] credit_out;
    
    // the connected router address
    logic  [RAw-1 :0] current_r_addr;
    
    /* verilator lint_off WIDTH */
    wire [PCK_SIZw-1 : 0] pck_size_tmp= (IS_SINGLE_FLIT )?   1 : pck_size_in;
    /* verilator lint_on WIDTH */
    
    always_comb begin
        chan_out.flit_chanel.flit = flit_out; 
        chan_out.flit_chanel.flit_wr = flit_out_wr;
        chan_out.flit_chanel.credit = credit_out;
        chan_out.smart_chanel = {SMART_CHANEL_w {1'b0}};
        for (int k=0; k<V;k++) chan_out.ctrl_chanel.credit_init_val[k] = PORT_B [CRDTw-1: 0] ;
        chan_out.ctrl_chanel.endp_port =1'b1;
        chan_out.ctrl_chanel.credit_release_en={V{1'b0}};
        chan_out.ctrl_chanel.hetero_ovc_presence={V{1'b1}};
        flit_in   =  chan_in.flit_chanel.flit;
        flit_in_wr=  chan_in.flit_chanel.flit_wr;
        credit_in =  chan_in.flit_chanel.credit;
        current_r_addr = chan_in.ctrl_chanel.router_addr;
    end
    //old traffic.v file
    reg [2:0]   ps,ns;
    localparam IDEAL =3'b001, SENT =3'b010, WAIT=3'b100;
    
    reg inject_en,cand_wr_vc_en,pck_rd;
    reg [PCK_SIZw-1 :0] pck_size;
    logic [DAw-1 :0] dest_e_addr_reg,dest_e_addr_o;
    
    `ifdef SIMULATION
    `ifdef MONITORE_PATH    
    reg tt;
    always @(posedge clk) begin
        if(`pronoc_reset)begin
            tt<=1'b0;
        end else begin
            if(flit_out_wr && tt==1'b0 )begin
                $display( "%t: Injector: current_r_addr=%x,current_e_addr=%x,dest_e_addr=%x\n",$time, current_r_addr, current_e_addr, dest_e_addr);
                tt<=1'b1;
            end
        end
    end
    `endif //MONITORE_PATH
    `endif //SIMULATION
    
    localparam
        HDR_DATA_w =  (MIN_PCK_SIZE==1)? CLK_CNTw : 0,
        HDR_Dw =  (MIN_PCK_SIZE==1)? CLK_CNTw : 1;
    
    wire [HDR_Dw-1 : 0] hdr_data_in,rd_hdr_data_out;
    
    pronoc_register #(.W(DAw)) reg2 (.D_in(dest_e_addr ), .Q_out(dest_e_addr_reg), .reset(reset), .clk(clk));
    
    wire [DSTPw-1 : 0] destport;   
    wire [V-1 : 0] ovc_wr_in;
    wire [V-1 : 0] full_vc,empty_vc,nearly_full_vc;
    reg  [V-1 : 0] wr_vc,wr_vc_next;
    wire [V-1 : 0] cand_vc;
    
    wire [CLK_CNTw-1 : 0] wr_timestamp,pck_timestamp;
    wire hdr_flit,tail_flit;
    reg [PCK_SIZw-1 : 0] flit_counter;
    reg flit_cnt_rst,flit_cnt_inc;
    wire rd_hdr_flg,rd_tail_flg;
    wire [Cw-1 : 0] rd_class_hdr;
    //  wire    [P_1-1 : 0] rd_destport_hdr;
    wire [DAw-1 : 0] rd_des_e_addr;
    wire [EAw-1 : 0] rd_src_e_addr;  
    
    reg [CLK_CNTw-1 : 0] rsv_counter;
    reg [CLK_CNTw-1 : 0] clk_counter;
    wire [Vw-1 : 0] rd_vc_bin;//,wr_vc_bin;
    reg  [CLK_CNTw-1 : 0] rsv_time_stamp[V-1:0];
    reg  [PCK_SIZw-1 : 0] rsv_pck_size    [V-1:0];
    wire [V-1 : 0] rd_vc; 
    wire wr_vc_is_full,wr_vc_avb,wr_vc_is_empty;
    reg  [V-1 : 0] credit_out_next;
    reg  [EAw-1 : 0] rsv_pck_src_e_addr        [V-1:0];
    reg  [Cw-1 : 0] rsv_pck_class_in     [V-1:0];  
    
    wire [CLK_CNTw-1 : 0] hdr_flit_timestamp;    
    wire pck_wr,buffer_full,pck_ready,valid_dst;    
    wire [CLK_CNTw-1 : 0] rd_timestamp;
    
    logic [DELAYw-1 : 0] start_delay_counter,start_delay_counter_next;
    logic  start_en_next , start_en;
    
    pronoc_register #(.W(1)) streg1 (.reset(reset),.clk(clk), .D_in(start_en_next), .Q_out(start_en)    );
    pronoc_register #(.W(DELAYw)) streg2 (.reset(reset),.clk(clk), .D_in(start_delay_counter_next), .Q_out(start_delay_counter)    );
    
    always_comb begin 
        start_en_next =start_en;
        start_delay_counter_next= start_delay_counter;
        if(start)    begin 
            start_en_next=1'b1;
            start_delay_counter_next={DELAYw{1'b0}};
        end else if(start_en && ~inject_en) begin 
            start_delay_counter_next= start_delay_counter + 1'b1;
        end
        if(stop) begin 
            start_en_next=1'b0;
        end
    end//always
    
    wire start_injection = (start_delay_counter == start_delay);
    
    check_destination_addr #(
        .TOPOLOGY(TOPOLOGY),
        .T1(T1),
        .T2(T2),
        .T3(T3),   
        .EAw(EAw),
        .SELF_LOOP_EN(SELF_LOOP_EN),
        .DAw(DAw),
        .CAST_TYPE(CAST_TYPE),
        .NE(NE)
    ) check_destination_addr (
        .dest_e_addr(dest_e_addr),
        .current_e_addr(current_e_addr),
        .dest_is_valid(valid_dst)
    );
    
    //assign hdr_flit_sent=pck_rd;
    
    injection_ratio_ctrl #     (
        .MAX_PCK_SIZ(MAX_PCK_SIZ),
        .MAX_RATIO(MAX_RATIO)
    ) pck_inject_ratio_ctrl (
        .en(inject_en),
        .pck_size_in(pck_size_tmp),
        .clk(clk),
        .reset(reset),
        .freez(buffer_full),
        .inject(pck_wr),
        .ratio(ratio)
    );
    
    output_vc_status #(
        .CRDTw(CRDTw),
        .V(V),
        .B(PORT_B),
        .HETERO_VC(HETERO_VC)
    ) nic_ovc_status (
        .credit_init_val_in( chan_in.ctrl_chanel.credit_init_val),
        .ovc_presence(chan_in.ctrl_chanel.hetero_ovc_presence),
        .wr_in(ovc_wr_in),
        .credit_in(credit_in),
        .nearly_full_vc(nearly_full_vc),
        .full_vc(full_vc),
        .empty_vc(empty_vc),
        .cand_vc(cand_vc),
        .cand_wr_vc_en (cand_wr_vc_en),
        .clk(clk),
        .reset(reset)
    );
    
    packet_gen #(
        .P(MAX_P)
    ) packet_buffer (
        .reset(reset),
        .clk(clk),
        .pck_wr(pck_wr),
        .pck_rd(pck_rd),
        .current_r_addr(current_r_addr),
        .current_e_addr(current_e_addr),
        .clk_counter(clk_counter+1'b1),//in case of zero load latency, the flit will be injected in the next clock cycle
        .pck_number(pck_number),
        .dest_e_addr_in(dest_e_addr),
        .dest_e_addr_o(dest_e_addr_o), 
        .pck_timestamp(pck_timestamp),
        .buffer_full(buffer_full),
        .pck_ready(pck_ready),
        .valid_dst(valid_dst),
        .destport(destport),
        .pck_size_in(pck_size_tmp),
        .pck_size_o(pck_size)
    );
    
    assign wr_timestamp    =pck_timestamp; 
    assign  update      = flit_in_wr & flit_in[Fw-2];
    assign  hdr_flit    = (flit_counter == 0);
    assign  tail_flit   = (flit_counter ==  pck_size-1'b1);
    
    assign  time_stamp_h2h  = hdr_flit_timestamp - rd_timestamp;
    assign  time_stamp_h2t  = clk_counter - rd_timestamp;
    
    wire [FPAYw-1 : 0] flit_out_pyload;
    wire [1 : 0] flit_out_hdr;
    wire [FPAYw-1 : 0] flit_out_header_pyload;
    wire [Fw-1 : 0] hdr_flit_out;
    
    assign hdr_data_in = (MIN_PCK_SIZE==1)? wr_timestamp[HDR_Dw-1 : 0] : {HDR_Dw{1'b0}};
    
    header_flit_generator #(
        .DATA_w(HDR_DATA_w)
    ) the_header_flit_generator (
        .flit_out(hdr_flit_out),
        .vc_num_in(wr_vc),
        .class_in(pck_class_in),
        .dest_e_addr_in(dest_e_addr_o),
        .src_e_addr_in(current_e_addr),
        .weight_in(init_weight),
        .destport_in(destport),
        .data_in(hdr_data_in),
        .be_in({BEw{1'b1}} )// Be is not used in simulation as we dont sent real data
    );
    
    assign flit_out_class = pck_class_in;
    assign flit_out_hdr = {hdr_flit,tail_flit};    
    assign flit_out_header_pyload = hdr_flit_out[FPAYw-1 : 0];
    
    /* verilator lint_off WIDTH */ 
    assign flit_out_pyload = (hdr_flit)  ?    flit_out_header_pyload :
        (tail_flit) ? wr_timestamp : {pck_number,flit_counter};
    /* verilator lint_on WIDTH */
    
    assign flit_out = {flit_out_hdr, wr_vc, flit_out_pyload };   
    
    //extract header flit info
    extract_header_flit_info #(
        .DATA_w(HDR_DATA_w)
    ) header_extractor (
        .flit_in(flit_in),
        .flit_in_wr(flit_in_wr),
        .class_o(rd_class_hdr),
        .destport_o(),
        .dest_e_addr_o(rd_des_e_addr),
        .src_e_addr_o(rd_src_e_addr),
        .vc_num_o(rd_vc),
        .hdr_flit_wr_o( ),
        .hdr_flg_o(rd_hdr_flg),
        .tail_flg_o(rd_tail_flg),
        .weight_o( ),
        .be_o( ),
        .data_o(rd_hdr_data_out)
    );
    
    distance_gen the_distance_gen (
        .src_e_addr(src_e_addr),
        .dest_e_addr(current_e_addr),
        .distance(distance)
    );
    
    generate 
    if(MIN_PCK_SIZE == 1) begin : sf_pck    
        assign src_e_addr         = (rd_hdr_flg & rd_tail_flg)? rd_src_e_addr : rsv_pck_src_e_addr[rd_vc_bin];
        assign pck_class_out      = (rd_hdr_flg & rd_tail_flg)? rd_class_hdr : rsv_pck_class_in[rd_vc_bin];
        assign hdr_flit_timestamp = (rd_hdr_flg & rd_tail_flg)?  clk_counter : rsv_time_stamp[rd_vc_bin];
        assign rd_timestamp       =    (rd_hdr_flg & rd_tail_flg)? rd_hdr_data_out : flit_in[CLK_CNTw-1 : 0];
        assign pck_size_o         = (rd_hdr_flg & rd_tail_flg)? 1 : rsv_pck_size[rd_vc_bin];
    end else begin : no_sf_pck
        assign pck_size_o = rsv_pck_size[rd_vc_bin];
        assign src_e_addr            = rsv_pck_src_e_addr[rd_vc_bin];
        assign pck_class_out    = rsv_pck_class_in[rd_vc_bin];
        assign hdr_flit_timestamp = rsv_time_stamp[rd_vc_bin];
        assign rd_timestamp=flit_in[CLK_CNTw-1 : 0];        
    end
    
    if(V==1) begin : v1
        assign rd_vc_bin=1'b0;
    // assign wr_vc_bin=1'b0;
    end else begin :vother  
        
        one_hot_to_bin #( .ONE_HOT_WIDTH (V)) conv1 
        (
            .one_hot_code (rd_vc),
            .bin_code (rd_vc_bin)
        );
    /*
    one_hot_to_bin #( .ONE_HOT_WIDTH (V)) conv2 
    (
        .one_hot_code   (wr_vc),
        .bin_code       (wr_vc_bin)
    );
     */
    end 
    endgenerate
    
    assign  ovc_wr_in   = (flit_out_wr ) ?      wr_vc : {V{1'b0}};
    assign  wr_vc_is_full           = | ( full_vc & wr_vc);
    
    generate
    /* verilator lint_off WIDTH */ 
    if(VC_REALLOCATION_TYPE ==  "NONATOMIC") begin : nanatom_b
    /* verilator lint_on WIDTH */  
        assign wr_vc_avb    =  ~wr_vc_is_full; 
    end else begin : atomic_b 
        assign wr_vc_is_empty   =  | ( empty_vc & wr_vc);
        assign wr_vc_avb        =  wr_vc_is_empty;      
    end
    endgenerate
    
    reg not_yet_sent_aflit_next,not_yet_sent_aflit;
    
    always_comb begin
        wr_vc_next          = wr_vc; 
        cand_wr_vc_en       = 1'b0;
        flit_out_wr         = 1'b0;
        flit_cnt_inc        = 1'b0;
        flit_cnt_rst        = 1'b0;
        credit_out_next     = {V{1'd0}};
        sent_done           = 1'b0;
        pck_rd              = 1'b0;
        hdr_flit_sent       =1'b0;
        ns                  = ps;
        pck_rd              =1'b0;
        not_yet_sent_aflit_next =not_yet_sent_aflit;
        case (ps) 
            IDEAL: begin
                if(pck_ready ) begin 
                    if(wr_vc_avb && valid_dst)begin
                        
                        hdr_flit_sent=1'b1;
                        flit_out_wr     = 1'b1;//sending header flit
                        not_yet_sent_aflit_next = 1'b0;
                        flit_cnt_inc = 1'b1;                            
                        if (MIN_PCK_SIZE>1 || flit_out_hdr!=2'b11) begin 
                            ns              = SENT;
                        end else begin
                            pck_rd=1'b1;
                            flit_cnt_rst   = 1'b1;
                            sent_done       =1'b1;
                            cand_wr_vc_en   =1'b1;
                            if(cand_vc>0) begin 
                                wr_vc_next  = cand_vc;
                            end  else ns = WAIT;
                        end  //else
                    end//wr_vc
                end 
                
            end //IDEAL
            SENT: begin  
                if(!wr_vc_is_full )begin 
                        
                    flit_out_wr     = 1'b1;
                    if(flit_counter  < pck_size-1) begin 
                        flit_cnt_inc = 1'b1;
                    end else begin 
                        flit_cnt_rst   = 1'b1;
                        sent_done       =1'b1;
                        pck_rd=1'b1;
                        cand_wr_vc_en   =1'b1;
                        if(cand_vc>0) begin 
                            wr_vc_next  = cand_vc;
                            ns          =IDEAL;
                        end     else ns = WAIT; 
                    end//else
                end // if wr_vc_is_full
            end//SENT
            WAIT:begin
                cand_wr_vc_en   =1'b1;
                if(cand_vc>0) begin 
                    wr_vc_next  = cand_vc;
                    ns = IDEAL;
                end  
            end
            default: begin 
                ns = IDEAL;
            end
        endcase
        // packet sink
        if(flit_in_wr) begin 
            credit_out_next = rd_vc;
        end else credit_out_next = {V{1'd0}};
    end //always
    
    always @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset) begin 
            inject_en <= 1'b0;
            ps <= IDEAL;
            wr_vc <= 1; 
            flit_counter <= {PCK_SIZw{1'b0}};
            credit_out <= {V{1'd0}};
            rsv_counter <= 0;
            clk_counter <= 0;
            not_yet_sent_aflit<=1'b1;
        end else begin 
            //injection
            not_yet_sent_aflit<=not_yet_sent_aflit_next;
            inject_en <=  (start_injection |inject_en) & ~stop;  
            ps <= ns;
            clk_counter <= clk_counter+1'b1;
            wr_vc <= wr_vc_next; 
            if (flit_cnt_rst) flit_counter <= {PCK_SIZw{1'b0}};
            else if(flit_cnt_inc) flit_counter <= flit_counter + 1'b1;     
            credit_out <= credit_out_next;
            //sink
            if(flit_in_wr) begin 
                if (flit_in[Fw-1])begin //header flit
                    rsv_pck_src_e_addr[rd_vc_bin]    <=  rd_src_e_addr;
                    rsv_pck_class_in[rd_vc_bin]    <= rd_class_hdr;
                    rsv_time_stamp[rd_vc_bin]   <= clk_counter;  
                    rsv_counter                 <= rsv_counter+1'b1;
                    rsv_pck_size[rd_vc_bin] <=2;                    
                    // distance        <= {{(32-8){1'b0}},flit_in[7:0]};
                    `ifdef SIMULATION
                    `ifdef RSV_NOTIFICATION
                    // last_pck_time<=$time;
                    $display ("total of %d pcks have been recived in core (%d)", rsv_counter,current_e_addr);
                    `endif
                    `endif
                end else begin 
                    rsv_pck_size[rd_vc_bin] <=rsv_pck_size[rd_vc_bin]+1; 
                end
            end
            `ifdef SIMULATION
            if(report) begin 
                $display ("%t,\t total of %d pcks have been recived in core (%d)",$time ,rsv_counter,current_e_addr);
            end
            `endif
        end //else reset
    end//always
    
    wire [NE-1 :0] dest_mcast_all_endp1;    
    
    generate 
    /* verilator lint_off WIDTH */
    if(CAST_TYPE != "UNICAST") begin :mb_cast
    /* verilator lint_on WIDTH */
        
        wire [NEw-1 : 0] sum_temp;
        wire is_unicast;
        
        mcast_dest_list_decode  decode1 (
            .dest_e_addr(dest_e_addr_o),
            .dest_o(dest_mcast_all_endp1),
            .row_has_any_dest(),
            .is_unicast(is_unicast)
        );
        
        /* verilator lint_off WIDTH */
        if (CAST_TYPE == "BROADCAST_FULL") begin :bcastf
            assign mcast_dst_num_o = (is_unicast) ? 1 : (SELF_LOOP_EN ) ? NE : NE-1;
        end else  if ( CAST_TYPE == "BROADCAST_PARTIAL" )  begin :bcastp 
            if (SELF_LOOP_EN == 0) begin 
                //check if injector node is included in partial list
                wire [NEw-1: 0]  current_enp_id;
                endp_addr_decoder  decod1 ( .id_out(current_enp_id), .code_in(current_e_addr));
                assign mcast_dst_num_o = (is_unicast) ? 1 : (MCAST_ENDP_LIST[current_enp_id]== 1'b1)?  MCAST_PRTLw-1 : MCAST_PRTLw;
            end else begin 
                assign mcast_dst_num_o = (is_unicast)? 1 : MCAST_PRTLw;
            end
        /* verilator lint_on WIDTH */
        
        end else begin : mcast
            accumulator #(
                .INw(NE),
                .OUTw(NEw),
                .NUM(NE)
            ) accum (
                .in_all(dest_mcast_all_endp1),
                .sum_o(sum_temp)
            );
            assign mcast_dst_num_o = sum_temp;
        end 
    end
    endgenerate

/**************************************
*        Validating Parameters 
*        /Simulation
***************************************/
    `ifdef SIMULATION
    
    wire [NEw-1: 0]  src_id,dst_id,current_id;
    
    endp_addr_decoder  decod1 ( .id_out(current_id), .code_in(current_e_addr));
    endp_addr_decoder  decod2 ( .id_out(dst_id), .code_in(rd_des_e_addr[EAw-1 : 0]));// only for unicast
    endp_addr_decoder  decod3 ( .id_out(src_id), .code_in(rd_src_e_addr));
    
    wire [NE-1 :0] dest_mcast_all_endp2;
    generate 
    if(CAST_TYPE != "UNICAST") begin :no_unicast
        mcast_dest_list_decode decode2 (
            .dest_e_addr(rd_des_e_addr),
            .dest_o(dest_mcast_all_endp2),
            .row_has_any_dest(),
            .is_unicast()
        );
    end 
    endgenerate
    
    always @(posedge clk) begin
        /* verilator lint_off WIDTH */
        if(CAST_TYPE == "UNICAST") begin
        /* verilator lint_on WIDTH */
            if(flit_out_wr && hdr_flit && dest_e_addr_o [EAw-1 : 0]  == current_e_addr  && SELF_LOOP_EN == 0) begin 
                $display("%t: ERROR: The self-loop is not enabled in the router while a packet is injected to the NoC with identical source and destination address in endpoint (%h).: %m",$time, dest_e_addr_o );
                $finish;
            end
            if(flit_in_wr && rd_hdr_flg && (rd_des_e_addr[EAw-1 : 0]  != current_e_addr )) begin 
                $display("%t: ERROR: packet with destination %d (code %h) which is sent by source %d (code %h) has been recieved in wrong destination %d (code %h).  %m",$time,dst_id,rd_des_e_addr, src_id,rd_src_e_addr, current_id,current_e_addr);
                $finish;
            end
        end else begin 
            /* verilator lint_off WIDTH */
            if((CAST_TYPE == "MULTICAST_FULL") || (CAST_TYPE == "MULTICAST_PARTIAL")) begin
            /* verilator lint_on WIDTH */
                
                if(flit_out_wr && hdr_flit && dest_mcast_all_endp1[current_id]  == 1'b1  && SELF_LOOP_EN == 0) begin 
                    $display("%t: ERROR: The self-loop is not enabled in the router while a packet is injected to the NoC with identical source and destination address in endpoint %d. destination nodes:0X%h. : %m",$time, current_id,dest_mcast_all_endp1 );
                    $finish;
                end
            end
            if(flit_in_wr && rd_hdr_flg && (dest_mcast_all_endp2[current_id] !=1'b1 )) begin 
                $display("%t: ERROR: packet with destination %b  which is sent by source %d (code %h) has been recieved in wrong destination %d (code %h).  %m",$time, dest_mcast_all_endp2, src_id,rd_src_e_addr, current_id,current_e_addr);
                $finish;
            end
            //check multicast packet size to be smaller than B & LB
            if(flit_out_wr & hdr_flit & (mcast_dst_num_o>1) & (pck_size >B || pck_size> LB))begin 
                $display("%t: ERROR: A multicast packat is injected to the NoC which has larger size (%d) than router buffer width.  %m",$time, pck_size);
                $finish;
            end
        end
        if(update) begin
            if (hdr_flit_timestamp<= rd_timestamp) begin 
                $display("%t: ERROR: In destination %d packt which is sent by source %d, the time when header flit is recived (%d) should be larger than the packet timestamp %d.  %m",$time, current_id ,src_e_addr, hdr_flit_timestamp, rd_timestamp);
                $finish;
            end 
            if( clk_counter <= rd_timestamp) begin 
                $display("%t: ERROR: ERROR: In destination %d packt which is sent by source %d,, the current time (%d) should be larger than the packet timestamp %d.  %m",$time, current_id ,src_e_addr, clk_counter, rd_timestamp);
                $finish;
            end
        end//update 
        if(tail_flit & flit_out_wr) begin 
            if(wr_timestamp > clk_counter) begin 
                $display("%t: ERROR: In src %d, the current time (%d) should be larger than or equal to the packet timestamp %d.  %m",$time, current_id, clk_counter, wr_timestamp);
                $finish;
            end
        end 
    end //always
    
    `ifdef CHECK_PCKS_CONTENT
    wire     [PCK_SIZw-1 : 0] rsv_flit_counter; 
    reg      [PCK_SIZw-1 : 0] old_flit_counter    [V-1 : 0];
    wire     [PCK_CNTw-1 : 0] rsv_pck_number;
    reg      [PCK_CNTw-1 : 0] old_pck_number  [V-1 : 0];
    wire [PCK_CNTw+PCK_SIZw-1 : 0] statistics;
    
    assign statistics = (PCK_CNTw+PCK_SIZw > Fw)? 
        {{(PCK_CNTw+PCK_SIZw-Fw){1'b0}},flit_in} :
        flit_in[PCK_CNTw+PCK_SIZw-1 : 0];
    
    assign {rsv_pck_number,rsv_flit_counter}=statistics;
    
    integer ii;
    always @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset) begin
            for(ii=0;ii<V;ii=ii+1'b1)begin
                old_flit_counter[ii]<=0;
            end
        end else begin
            if(flit_in_wr)begin
                if ( flit_in[Fw-1:Fw-2]==2'b10)  begin
                    old_pck_number[rd_vc_bin]<=0;
                    old_flit_counter[rd_vc_bin]<=0;
                end else if ( flit_in[Fw-1:Fw-2]==2'b00)begin 
                    old_pck_number[rd_vc_bin]<=rsv_pck_number;
                    old_flit_counter[rd_vc_bin]<=rsv_flit_counter;
                end 
            end //flit_in_wr
        end    //reset
    end //always
    
    always @(posedge clk) begin     
        if(flit_in_wr && (flit_in[Fw-1:Fw-2]==2'b00) && (~reset))begin 
            if( old_flit_counter[rd_vc_bin]!=rsv_flit_counter-1) $display("%t: Error: missmatch flit counter in %m. Expected %d but recieved %d",$time,old_flit_counter[rd_vc_bin]+1,rsv_flit_counter);
            if( old_pck_number[rd_vc_bin]!=rsv_pck_number && old_pck_number[rd_vc_bin]!=0)   $display("%t: Error: missmatch pck number in %m. expected %d but recieved %d",$time,old_pck_number[rd_vc_bin],rsv_pck_number);
        end
    end
    
    `endif //CHECK_PCKS_CONTENT
    `endif //SIMULATION
    
// `ifdef VERILATOR
//   logic  endp_is_active   /*verilator public_flat_rd*/ ;
//  
//    always_comb begin 
//        endp_is_active  = 1'b0;        
//        if (chan_out.flit_chanel.flit_wr) endp_is_active=1'b1;
//        if (chan_out.flit_chanel.credit > {V{1'b0}} ) endp_is_active=1'b1;
//        if (chan_out.smart_chanel.requests > {SMART_NUM{1'b0}} ) endp_is_active=1'b1;
//    end
//`endif
    
endmodule

/*****************************
*    injection_ratio_ctrl
*****************************/
module injection_ratio_ctrl #
    (
    parameter MAX_PCK_SIZ=10,
    parameter MAX_RATIO=100
)(
    en,
    pck_size_in, // average packet size in flit x10
    clk,
    reset,
    inject,// inject one packet
    freez,
    ratio // 0~100  flit injection ratio
);
    
    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end       
    end   
    endfunction // log2 
    
    localparam PCK_SIZw= log2(MAX_PCK_SIZ);
    localparam CNTw    =   log2(MAX_RATIO);
    localparam STATE_INIT=   MAX_PCK_SIZ*MAX_RATIO;
    localparam STATEw    =   log2(MAX_PCK_SIZ*2*MAX_RATIO);
    
    input  clk,reset,freez,en;
    output  reg inject;
    input   [CNTw-1 : 0]  ratio;
    input  [PCK_SIZw-1 :0] pck_size_in;
    reg    [PCK_SIZw-1 :0]pck_size;
    
    wire    [CNTw-1 : 0]  on_clks, off_clks;
    reg     [STATEw-1 : 0]  state,next_state;
    wire                        input_changed;
    reg     [CNTw-1 : 0]  ratio_old;    
    
    always @(posedge clk ) ratio_old<=ratio;
    
    assign input_changed = (ratio_old!=ratio);
    assign on_clks = ratio; 
    assign off_clks =MAX_RATIO-ratio; 
    
    reg [PCK_SIZw-1 :0] flit_counter,next_flit_counter;
    
    reg sent,next_sent,next_inject;
    
    always_comb begin 
        next_state        =state;
        next_flit_counter =flit_counter;
        next_sent         =sent;
        if(en && ~freez ) begin
            case(sent)
                1'b1: begin 
                    /* verilator lint_off WIDTH */
                    next_state          = state +  off_clks; 
                    /* verilator lint_on WIDTH */
                    next_flit_counter = (flit_counter >= pck_size-1'b1) ? {PCK_SIZw{1'b0}} : flit_counter +1'b1;
                    next_inject         = (flit_counter=={PCK_SIZw{1'b0}});
                    if (next_flit_counter >= pck_size-1'b1) begin 
                        if( next_state  >= STATE_INIT ) next_sent =1'b0;
                    end
                end
                1'b0:begin 
                    if( next_state  <  STATE_INIT ) next_sent  = 1'b1;
                    next_inject= 1'b0;
                    /* verilator lint_off WIDTH */
                    next_state = state - on_clks;
                    /* verilator lint_on WIDTH */
                end
            endcase     
        end else begin 
            next_inject= 1'b0;
        end
    end
    
    always @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset) begin
            state <= STATE_INIT;
            inject <= 1'b0; 
            sent <= 1'b1; 
            flit_counter<= 0;
            pck_size<=2;
        end else begin 
            if(input_changed)begin
                state <= STATE_INIT;
                inject <=  1'b0; 
                sent <= 1'b1; 
                flit_counter <= 0;
                pck_size <= pck_size_in;
            end else begin 
                sent <=  next_sent; 
                state <=  next_state;
                if(ratio!={CNTw{1'b0}}) inject <=  next_inject;             
                flit_counter <= next_flit_counter;
                if(flit_counter=={PCK_SIZw{1'b0}}) pck_size<=pck_size_in;
            end
        end
    end
endmodule

/*************************************
*        packet_buffer
**************************************/
module packet_gen 
#(
    parameter P = 5
)(
    clk_counter,
    pck_wr,
    pck_rd,
    current_r_addr,
    current_e_addr,
    pck_number,
    dest_e_addr_in,
    dest_e_addr_o,
    pck_timestamp,
    destport,
    buffer_full,
    pck_ready,
    valid_dst,
    pck_size_in,
    pck_size_o,
    clk,
    reset 
);
    
    import pronoc_pkg::*;
    
    localparam 
        PCK_CNTw    =   log2(MAX_PCK_NUM+1),
        CLK_CNTw    =   log2(MAX_SIM_CLKs+1);
    
    input  reset,clk, pck_wr, pck_rd;
    input  [RAw-1 :0] current_r_addr;
    input  [EAw-1 : 0] current_e_addr;
    input  [CLK_CNTw-1 :0] clk_counter;    
    input  [PCK_SIZw-1 :0] pck_size_in;
    input  [DAw-1 :0] dest_e_addr_in;
    output [DAw-1 :0] dest_e_addr_o;
    input  valid_dst; 
    
    output [PCK_CNTw-1 :0] pck_number;
    output [CLK_CNTw-1 :0] pck_timestamp;  
    output [PCK_SIZw-1 :0] pck_size_o;
    output buffer_full,pck_ready;
    
    output [DSTPw-1 :0] destport; 
    reg    [PCK_CNTw-1 :0] packet_counter;  
    wire   buffer_empty; 
    
    assign pck_ready = ~buffer_empty & valid_dst;
    
    generate 
    if( IS_UNICAST ) begin : uni 
        conventional_routing #(
            .LOCATED_IN_NI(1)
        ) routing_module (
            .reset(reset),
            .clk(clk),
            .current_r_addr(current_r_addr),
            .dest_e_addr(dest_e_addr_o),
            .src_e_addr(current_e_addr),
            .destport(destport)
        );
    end 
    endgenerate
    
    wire timestamp_fifo_nearly_full , timestamp_fifo_full;
    assign buffer_full = (MIN_PCK_SIZE==1) ? timestamp_fifo_nearly_full : timestamp_fifo_full;
    
    wire  [DAw-1 :0] tmp1;
    wire  [PCK_SIZw-1 : 0] tmp2;
    
    wire recieve_more_than_0;
    fwft_fifo_bram #(
        .DATA_WIDTH(CLK_CNTw+PCK_SIZw+DAw),
        .MAX_DEPTH(TIMSTMP_FIFO_NUM)        
    ) timestamp_fifo (
        .din({dest_e_addr_in,pck_size_in,clk_counter}),
        .wr_en(pck_wr),
        .rd_en(pck_rd),
        .dout({tmp1,tmp2,pck_timestamp}),
        .full(timestamp_fifo_full),
        .nearly_full(timestamp_fifo_nearly_full),
        .recieve_more_than_0(recieve_more_than_0),
        .recieve_more_than_1(),
        .reset(reset),
        .clk(clk)
    );
    
    //assign dest_e_addr_o = dest_e_addr_in;
    
    assign dest_e_addr_o =tmp1;
    /* verilator lint_off WIDTH */
    assign pck_size_o = (IS_SINGLE_FLIT )?   1 : tmp2;
    /* verilator lint_on WIDTH */
    assign buffer_empty = ~recieve_more_than_0;
    
    /*
    bram_based_fifo #(
        .Dw(CLK_CNTw),
        .B(TIMSTMP_FIFO_NUM)
    )
    timestamp_fifo
    (
        .din(clk_counter),
        .wr_en(pck_wr),
        .rd_en(pck_rd),
        .dout(pck_timestamp),
        .full(timestamp_fifo_full),
        .nearly_full(timestamp_fifo_nearly_full),
        .empty(buffer_empty),
        .reset(reset),
        .clk(clk)
    );
    */ 
    
    always @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset) begin 
            packet_counter <= {PCK_CNTw{1'b0}};
        end else begin 
            if(pck_rd) begin 
                packet_counter <= packet_counter+1'b1;
            end
        end
    end
    
    assign pck_number = packet_counter;
    
endmodule


/********************
*    distance_gen 
********************/
module distance_gen (
    src_e_addr,
    dest_e_addr,
    distance
);
    import pronoc_pkg::*;
    input [EAw-1 : 0] src_e_addr;
    input [EAw-1 : 0] dest_e_addr;
    output [DISTw-1 : 0]   distance;
    
    generate 
    if (IS_MESH | IS_LINE) begin : mesh_noc
        mesh_line_distance_gen distance_gen (
            .src_e_addr(src_e_addr),
            .dest_e_addr(dest_e_addr),
            .distance(distance)
        );
    
    end else if (IS_TORUS | IS_RING) begin : tori_noc 
        ring_torus_distance_gen distance_gen (
            .src_e_addr(src_e_addr),
            .dest_e_addr(dest_e_addr),
            .distance(distance)
        );
        
    end else if (IS_FMESH) begin :fmesh
        fmesh_distance_gen  distance_gen (
            .src_e_addr(src_e_addr),
            .dest_e_addr(dest_e_addr),
            .distance(distance)
        );
        
    end else if (IS_FATTREE | IS_TREE) begin : fat 
        fattree_distance_gen #(
            .K(T1),
            .L(T2)
        ) distance_gen (
            .src_addr_encoded(src_e_addr),
            .dest_addr_encoded(dest_e_addr),
            .distance(distance)
        );
    end else if (IS_STAR) begin 
        assign distance =1;
    end
    endgenerate
    
endmodule
