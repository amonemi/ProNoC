/**********************************

           traffic_gen


**********************************/
`timescale   1ns/1ps


module traffic_gen_old#(
    parameter V = 4,    // VC num per port
    parameter P = 5,    // router port num
    parameter B = 4,    // buffer space :flit per VC 
    parameter NX= 4,    // number of node in x axis
    parameter NY= 4,    // number of node in y axis
    parameter C = 4,    //  number of flit class 
    parameter Fpay = 32,
    parameter VC_REALLOCATION_TYPE  = "NONATOMIC",// "ATOMIC" , "NONATOMIC"
    parameter TOPOLOGY  = "MESH",
    parameter ROUTE_NAME    = "XY",
    parameter ROUTE_TYPE    = "DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter TRAFFIC   =   "RANDOM",
    //  "RANDOM", "TRANSPOSE1","TRANSPOSE2", "HOTSPOT", "BIT_REVERSE", "BIT_COMPLEMENT", "CUSTOM"
   
   
    parameter CLASS_3_TRAFFIC_PATTERN= 1,
        /*
        0: 25 % class 0 , 75 % class 1
        1: 50 % class 0 , 50 % class 1
        2: 75 % class 0 , 25 % class 1
        */
        
    //setting for hotspot
    parameter HOTSPOT_PERCENTAGE    =   3,   //maximum 20
    parameter HOTSOPT_NUM           =   4, //maximum 4
    parameter HOTSPOT_CORE_1        =   10,
    parameter HOTSPOT_CORE_2        =   11,
    parameter HOTSPOT_CORE_3        =   12,
    parameter HOTSPOT_CORE_4        =   13,
    parameter HOTSPOT_CORE_5        =   14,
    
    
    
    //parameter PCK_SIZE_IN_FLIT      =   6,
    //total number of packets which is sent by a router
    parameter TOTAL_PKT_PER_ROUTER  =   200,
    parameter MAX_DELAY_BTWN_PCKTS  =   1024,
    parameter TIMSTAMP_STRT_ON= "INJECT_EN"// "INJECT_EN", "HDR_FLIT_WR"     
)
(
    delay,
    pck_size,
    pck_counter,
    current_x,
    current_y,
    reset,
    clk,
    start,
    done,
    update, // update the noc_analayzer
    distance,
    msg_class,
    time_stamp,
    flit_out,     
    flit_out_wr,   
    credit_in,
    flit_in,   
    flit_in_wr,   
    credit_out,     
    report
);

    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
   endfunction // log2 
    
    localparam      P_1 =   P-1 ;
    
    localparam      Xw          =   log2(NX),   // number of node in x axis
                    Yw          =   log2(NY),    // number of node in y axis
                    Cw          =   log2(C),
                    Fw          =   2+V+Fpay,
                    Dw          =   log2(MAX_DELAY_BTWN_PCKTS+1),
                    PCK_CNTw    =   log2(TOTAL_PKT_PER_ROUTER+1);

    
    localparam      CLASS_IN_HDR_WIDTH      =8,
                    DEST_IN_HDR_WIDTH           =8,
                    X_Y_IN_HDR_WIDTH            =4;
    /*
    reg inject_en;
    
    pck_size,
    wr_des_x_addr,
    wr_des_y_addr,
    wr_class_hdr,
    
    */
    
    input reset, clk;
    /*
    input                                   inject_en;
    input [15                       :0] pck_size;
   
    
    */
    input   [Dw-1                   :0] delay;
    input                               start;
    output                              done;
    output                              update;
    output [31                      :0] time_stamp;
    output [31                      :0] distance;
    output [Cw-1                    :0] msg_class;
    input  [Xw-1                    :0] current_x;
    input  [Yw-1                    :0] current_y;
    output [PCK_CNTw-1              :0] pck_counter;
    input  [15                      :0] pck_size;
    
    
    
    // NOC interfaces
    output  [Fw-1                   :0] flit_out;     
    output  reg                         flit_out_wr;   
    input   [V-1                    :0] credit_in;
    
    input   [Fw-1                   :0] flit_in;   
    input                               flit_in_wr;   
    output reg  [V-1                :0] credit_out;     
    reg                                 sent_done;
    input                               report;
    
    wire    [X_Y_IN_HDR_WIDTH-1     :0] wr_des_x_addr,wr_src_x_addr;
    wire    [X_Y_IN_HDR_WIDTH-1     :0] wr_des_y_addr,wr_src_y_addr;
    wire    [CLASS_IN_HDR_WIDTH-1   :0] wr_class_hdr;
    
    
    wire    [V-1                        :0] full_vc,empty_vc;
    reg     [V-1                        :0] wr_vc,wr_vc_next;
    reg     [15                         :0] counter;
    reg                                     counter_inc,counter_reset;
    wire                                    wr_vc_is_full,wr_vc_avb,wr_vc_is_empty;

        
    
    wire    [P_1-1                     :0] destport;
    reg     [V-1                       :0] credit_out_next;    
    reg     [31                        :0] clk_counter,clk_counter_lathched;
    
    wire    [V-1                       :0] ovc_wr_in;
    wire                                hdr_flit,tail_flit;
    wire    [DEST_IN_HDR_WIDTH-1      :0] wr_destport_hdr;
    
    
    
    // noc_analyze
    localparam VC_NUM_BCD_WIDTH = log2(V);

    reg [X_Y_IN_HDR_WIDTH-1         :   0] rsv_pck_src_x        [V-1:0];
    reg [X_Y_IN_HDR_WIDTH-1         :   0] rsv_pck_src_y        [V-1:0];
    reg [Cw-1                           :   0] rsv_pck_class        [V-1:0];    
    wire[V-1                :0] rd_vc;
    
    wire [1                         :   0]  rd_hdr_flg;
    wire [CLASS_IN_HDR_WIDTH-1      :   0] rd_class_hdr;
    wire [DEST_IN_HDR_WIDTH-1       :   0]  rd_destport_hdr;
    wire [X_Y_IN_HDR_WIDTH-1        :   0] rd_des_x_addr,   rd_des_y_addr,rd_src_x_addr,rd_src_y_addr;
    
    wire[VC_NUM_BCD_WIDTH-1         :   0] rd_vc_bin,wr_vc_bin;
    reg [31                         :   0] sent_time_stamp[V-1:0];
    reg [31                         :   0] rsv_time_stamp[V-1:0];
    
    reg cand_wr_vc_en;
    wire [V-1      :   0]    cand_vc;
    wire [Xw-1     :   0]    dest_x;
    wire [Yw-1     :   0]    dest_y;
    wire                     inject_en;
    
    assign  update      = flit_in_wr & flit_in[Fw-2];
    assign  hdr_flit    = (counter == 0);
    assign  tail_flit   = (counter ==  pck_size-1'b1);
    assign  wr_destport_hdr= {{DEST_IN_HDR_WIDTH-P_1{1'b0}},destport};
    
    assign flit_out= (hdr_flit)     ?   {2'b10,wr_vc,wr_class_hdr,wr_destport_hdr,wr_des_x_addr,wr_des_y_addr,wr_src_x_addr,wr_src_y_addr}:
                     (tail_flit)    ?   {2'b01,wr_vc,sent_time_stamp[wr_vc_bin]}:
                                        {2'b00,wr_vc,{16{1'd0}},counter};

    assign {rd_hdr_flg,rd_vc,rd_class_hdr,rd_destport_hdr,rd_des_x_addr,rd_des_y_addr,rd_src_x_addr,rd_src_y_addr} = flit_in;

    
    
    one_hot_to_bin #( .ONE_HOT_WIDTH (V)) conv1 
    (
        .one_hot_code   (rd_vc),
        .bin_code       (rd_vc_bin)
    );
    
    one_hot_to_bin #( .ONE_HOT_WIDTH (V)) conv2 
    (
        .one_hot_code   (wr_vc),
        .bin_code       (wr_vc_bin)
    );
    
    
    assign  ovc_wr_in   = (flit_out_wr ) ?      wr_vc : {V{1'b0}};

    assign  wr_vc_is_full           =   | ( full_vc & wr_vc);
    
    assign wr_vc_is_empty           =  | ( empty_vc & wr_vc);
    
    generate
        if(VC_REALLOCATION_TYPE ==  "NONATOMIC") begin  
            assign wr_vc_avb    =  ~wr_vc_is_full; 
        end else begin 
            assign wr_vc_avb    =  wr_vc_is_empty;      
        end
    endgenerate
    
    
    
    ni_conventional_routing #(        
        .P(P),
        .NX(NX),
        .NY(NY),
        .ROUTE_TYPE(ROUTE_TYPE),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .LOCATED_IN_NI(1)
    )
    conv_routing(
        .current_x( current_x),
        .current_y( current_y),
        .dest_x    (wr_des_x_addr [Xw-1    :0]),
        .dest_y    (wr_des_y_addr [Yw-1    :0]),
        .destport  (destport)
    );
                               
                                
 output_vc_status #(
        .V      (V),
        .B  (B),
        .CAND_VC_SEL_MODE       (0) // 0: use arbieration between not full vcs, 1: select the vc with moast availble free space
    )
    nic_ovc_status
    (
    .wr_in                      (ovc_wr_in),   
    .credit_in                  (credit_in),
    .full_vc                        (full_vc),
    .empty_vc                   (empty_vc),
    .cand_vc                        (cand_vc),
    .cand_wr_vc_en              (cand_wr_vc_en),
    .clk                            (clk),
    .reset                      (reset)
    );
    
    send_traffic #(
    	.V(V),
    	.C(C),
    	.NX(NX),
    	.NY(NY),
    	.TRAFFIC(TRAFFIC),
    	.CLASS_3_TRAFFIC_PATTERN(CLASS_3_TRAFFIC_PATTERN),
    	.HOTSPOT_PERCENTAGE(HOTSPOT_PERCENTAGE),
    	.HOTSOPT_NUM(HOTSOPT_NUM),
    	.HOTSPOT_CORE_1(HOTSPOT_CORE_1),
    	.HOTSPOT_CORE_2(HOTSPOT_CORE_2),
    	.HOTSPOT_CORE_3(HOTSPOT_CORE_3),
    	.HOTSPOT_CORE_4(HOTSPOT_CORE_4),
    	.HOTSPOT_CORE_5(HOTSPOT_CORE_5),
    	.MAX_DELAY_BTWN_PCKTS(MAX_DELAY_BTWN_PCKTS),
    	.TOTAL_PKT_PER_ROUTER(TOTAL_PKT_PER_ROUTER)
    )
    send_traffic(
        .pck_counter(pck_counter),
    	.send_start(start),
    	.sent_done(sent_done),
    	.current_x(current_x),
    	.current_y(current_y),
    	.delay(delay),
    	.clk(clk),
    	.reset(reset),
    	.dest_x(dest_x),
    	.dest_y(dest_y),
    	.class_hdr(wr_class_hdr),
    	.inject_en(inject_en),
    	.done(done)
    );
    
    assign wr_des_x_addr[Xw-1   :   0]=  dest_x;
    assign wr_des_x_addr[X_Y_IN_HDR_WIDTH-1 :   Xw]= 0;
    assign wr_des_y_addr[Yw-1   :   0]=  dest_y;
    assign wr_des_y_addr[X_Y_IN_HDR_WIDTH-1 :   Yw]= 0;
    assign wr_src_x_addr[Xw-1   :   0]=  current_x;
    assign wr_src_x_addr[X_Y_IN_HDR_WIDTH-1 :   Xw]= 0;
    assign wr_src_y_addr[Yw-1   :   0]=  current_y;
    assign wr_src_y_addr[X_Y_IN_HDR_WIDTH-1 :   Yw]= 0;
    
     
   
        
    reg [2:0]   ps,ns;
    localparam IDEAL =3'b001, SENT =3'b010, WAIT=3'b100;
    
    
    reg  capture_done;
    
    always @(*)begin
            wr_vc_next          = wr_vc; 
            cand_wr_vc_en       =   1'b0;
            flit_out_wr         = 1'b0;
            counter_inc         = 1'b0;
            counter_reset     = 1'b0;
            credit_out_next     = {V{1'd0}};
            sent_done           =1'b0;
            ns                      =ps;
            
            case (ps) 
                IDEAL: begin 
                    if(inject_en) begin 
                        if(wr_vc_avb)begin 
                            flit_out_wr     = 1'b1;
                            counter_inc = 1'b1;
                            ns              = SENT;
                        end//wr_vc
                    end //injection_en
                end //IDEAL
                SENT: begin 
                    if(!wr_vc_is_full)begin 
                        flit_out_wr     = 1'b1;
                        if(counter  < pck_size-1) begin 
                            counter_inc = 1'b1;
                        end else begin 
                            
                            counter_reset   = 1'b1;
                            sent_done       =1'b1;
                            cand_wr_vc_en   =1'b1;
                            if(cand_vc>0) begin 
                                wr_vc_next  = cand_vc;
                                ns                  =IDEAL;
                            end     else ns = WAIT; 
                        end//else
                    end // if wr_vc_is_full
                end//SENT
                WAIT:begin
                    cand_wr_vc_en   =1'b1;
                    if(cand_vc>0) begin 
                                wr_vc_next  = cand_vc;
                                ns                  =IDEAL;
                    end  
                end
                default: begin 
                    ns                  =IDEAL;
                end
                endcase
            
        
            // packet sink
            if(flit_in_wr) begin 
                    credit_out_next = rd_vc;
            end else credit_out_next = {V{1'd0}};
        end
    
    
    integer rsv_counter,last_pck_time;

    
    always @(posedge clk or posedge reset )begin 
        if(reset) begin 
            ps                  <= IDEAL;
            wr_vc           <=1; 
            counter             <= 16'd0;
            credit_out      <= {V{1'd0}};
            rsv_counter     <= 0;
            clk_counter     <=  0;
            capture_done    <=  0;
            clk_counter_lathched<=0;
        
        end
        else begin 
            //injection
            ps             <= ns;
            clk_counter     <= clk_counter+1'b1;
            wr_vc           <=wr_vc_next; 
            if (counter_reset)      counter             <= 16'd0;
            else if(counter_inc)        counter         <=  counter+1'b1;
            credit_out      <= credit_out_next;
            
           
            //sink
            if(flit_in_wr) begin 
                    if (flit_in[Fw-1])begin 
                        rsv_pck_src_x[rd_vc_bin]    <=  rd_src_x_addr;
                        rsv_pck_src_y[rd_vc_bin]    <=  rd_src_y_addr;
                        rsv_pck_class[rd_vc_bin]    <= rd_class_hdr[Cw-1                            :   0];
                        rsv_time_stamp[rd_vc_bin]   <= clk_counter;  
                        rsv_counter                 <= rsv_counter+1'b1;
                                            
                    //  distance        <= {{(32-8){1'b0}},flit_in[7:0]};
                        // synthesis translate_off
                        last_pck_time<=$time;
                        //$display ("%d,\t toptal of %d pcks have been recived in core (%d,%d)", last_pck_time,rsv_counter,X,Y);
                        // synthesis translate_on
                    end
            end
        
        // synthesis translate_off
            if(report) begin 
                 $display ("%t,\t toptal of %d pcks have been recived in core (%d,%d)", last_pck_time,rsv_counter,current_x,current_y);
            end
        // synthesis translate_on
         
         if (counter_reset)  capture_done    <=  1'b0; 
         else if(inject_en)  capture_done    <=  1'b1; 
         
         if(TIMSTAMP_STRT_ON == "INJECT_EN")begin 
           if(~capture_done & inject_en) begin 
                clk_counter_lathched <= clk_counter;
                if( hdr_flit && flit_out_wr) sent_time_stamp[wr_vc_bin] <= clk_counter;
           end else if( hdr_flit && flit_out_wr) sent_time_stamp[wr_vc_bin] <= clk_counter_lathched;
         end else begin 
            
            if( hdr_flit && flit_out_wr) sent_time_stamp[wr_vc_bin] <= clk_counter;
         end
         
        
        end
    end//always

    

    wire [X_Y_IN_HDR_WIDTH-1        :   0]  src_x,src_y,dst_x,dst_y,x_offset,y_offset;
    assign src_x            = rsv_pck_src_x[rd_vc_bin];
    assign src_y            = rsv_pck_src_y[rd_vc_bin];
    assign msg_class        = rsv_pck_class[rd_vc_bin];
    assign dst_x            = current_x;
    assign dst_y            = current_y;
    assign x_offset         = (src_x> dst_x)? src_x - dst_x : dst_x - src_x;
    assign y_offset         = (src_y> dst_y)? src_y - dst_y : dst_y - src_y;
    

    assign distance     =   (TOPOLOGY=="MESH")?x_offset+y_offset+1: 0;
    assign time_stamp   =  rsv_time_stamp[rd_vc_bin] - flit_in[31       :0];
    

    
        // synthesis translate_off
    always @(posedge clk) begin     
        if(flit_out_wr && hdr_flit && wr_des_x_addr == current_x && wr_des_y_addr == current_y) $display("%t: Error: The source and destination address of injected packet is the same in router(%d,%d) ",$time, wr_des_x_addr ,wr_des_y_addr);                                                             
        if(flit_in_wr && rd_hdr_flg[1] && rd_des_x_addr!= current_x && rd_des_y_addr!= current_y ) $display("%t: Error: packet with des(%d,%d) has been recieved in wrong router (%d,%d).  ",$time,rd_des_x_addr, rd_des_y_addr, current_x , current_y);        
    end
    // synthesis translate_on

endmodule



 



/**************************************
* 
*
*
***************************************/
module  send_traffic #(
    parameter V         = 4,
    parameter C         = 4,    //  number of flit class 
    parameter NX        = 8,    // number of node in x axis
    parameter NY        = 8,    // number of node in y axis
    parameter TRAFFIC   =   "RANDOM",
    //  "RANDOM", "TRANSPOSE1","TRANSPOSE2", "HOTSPOT", "BIT_REVERSE", "BIT_COMPLEMENT", "CUSTOM";
    parameter CLASS_3_TRAFFIC_PATTERN= 1,
        /*
        0: 25 % class 0 , 75 % class 1
        1: 50 % class 0 , 50 % class 1
        2: 75 % class 0 , 25 % class 1
        */
        
    //setting for hotspot
    parameter HOTSPOT_PERCENTAGE    =   3,   //maximum 20
    parameter HOTSOPT_NUM           =   4, //maximum 4
    parameter HOTSPOT_CORE_1        =   10,
    parameter HOTSPOT_CORE_2        =   11,
    parameter HOTSPOT_CORE_3        =   12,
    parameter HOTSPOT_CORE_4        =   13,
    parameter HOTSPOT_CORE_5        =   14,
    parameter MAX_DELAY_BTWN_PCKTS  =   100,
    //total number of packets which is sent by a router
    parameter TOTAL_PKT_PER_ROUTER  =   200 
)
(
   pck_counter,  
   send_start,
   sent_done,
   current_x,
   current_y,
   delay,
   clk,
   reset,
   dest_x,
   dest_y,
   class_hdr, 
   inject_en,
   done

);

 
    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
   endfunction // log2 
   
   
    localparam  Xw=log2(NX),
                Yw=log2(NY),
                Dw=log2(MAX_DELAY_BTWN_PCKTS+1),
                PCK_CNTw=log2(TOTAL_PKT_PER_ROUTER+1);
     localparam NC    =   NX*NY,  //flit width;   
              NCw   =   log2(NC),
              Cw    =   log2(C),
              Vw    =   log2(V);                 
                
    localparam     CLASS_IN_HDR_WIDTH      =8;          
   
    input   send_start,sent_done;
    input   [Xw-1     :   0]    current_x;
    input   [Yw-1     :   0]    current_y;
    input   [Dw-1     :   0]    delay;
    input                       clk,reset;
    
    output reg     [PCK_CNTw-1:  0]    pck_counter;
    output  [Xw-1     :   0]    dest_x;
    output  [Yw-1     :   0]    dest_y;
    output  [CLASS_IN_HDR_WIDTH-1   :0] class_hdr; 
    output  reg                 inject_en;
    output  reg                 done;
    

    //generate the base addresses
    localparam  ST_NUMBER =   5,
                IDEAL_ST  =   1,
                WARM_UP   =   2,
                SEND_ST   =   4,
                DELAY_ST  =   8,
                END_ST    =   16;
     
     reg    [ST_NUMBER-1    :   0]  ps;
     reg    [Dw-1           :   0]  clk_delay_counter;
     wire   [NCw-1          :   0] dest_ip_num;
     wire send_en;
     
        //reg core_num;
        //reg [ST_NUMBER-1:0] ps;
        
    always @(posedge clk or posedge reset) begin 
        if(reset) begin 
            ps<=IDEAL_ST;
            inject_en <= 1'b0;
            clk_delay_counter<=0;
            done <= 1'b0;
            pck_counter<= 0;
            clk_delay_counter<= dest_x+dest_y+2;
            
        end else begin 
            case(ps) 
                IDEAL_ST:  begin 
                    inject_en     <= 1'b0;
                    ps<=IDEAL_ST;
                    if(send_start & send_en) begin 
                        ps<=WARM_UP;
                    end
                    if( ~send_en) done <=1;
                end
                WARM_UP: begin 
                    clk_delay_counter<=clk_delay_counter-1'b1;
                    if(clk_delay_counter==0) ps<=SEND_ST;
                end
                SEND_ST: begin 
                    done <= 1'b0;
                    inject_en  <= 1'b1;
                    clk_delay_counter <=0;
                    if( sent_done )begin 
                        pck_counter <= pck_counter+1'b1;
                        if(pck_counter==TOTAL_PKT_PER_ROUTER-1'b1) begin 
                          ps <= END_ST;
                          inject_en   <= 1'b0;
                         end
                        else if(delay>0) begin 
                            inject_en     <= 1'b0;
                            ps <= DELAY_ST;
                           
                        end
                    end
                end
                DELAY_ST: begin 
                    inject_en     <= 1'b0;
                    clk_delay_counter <=clk_delay_counter +1'b1;
                    if(clk_delay_counter >= delay) begin 
                                inject_en     <= 1'b1;
                                ps<= SEND_ST;
                end
                end
                END_ST: begin 
                    inject_en     <= 1'b0;
                    clk_delay_counter <=clk_delay_counter +1'b1;
                    ps<= IDEAL_ST;
                    done <= 1'b1;
                end
                default ps<=IDEAL_ST;
            endcase
        end//else 
    end
 
 
/***************************

        traffic

*****************************/

  
              
  
              

    wire     [NCw-1   :  0] ip_num;
    wire     [Cw-1    :  0] rnd_class;
    
    assign ip_num = current_y * NX + current_x;
    
    
    genvar i;
    generate

    if(CLASS_3_TRAFFIC_PATTERN== 1) begin 

        pseudo_random #(
            .MAX_RND    (C-1),
            .MAX_CORE   (NC-1),
            .MAX_NUM    (TOTAL_PKT_PER_ROUTER)
        )
        rnd_gen
        (
                
            .core(ip_num),
            .num(pck_counter),
            .rnd(rnd_class),
            .rnd_en(1'b1),
            .reset(reset),
            .clk(clk)                
        );
            
    end else if(CLASS_3_TRAFFIC_PATTERN== 0) begin
            
        pseudo_hotspot #(
            .MAX_RND(1), // c=0 or 1
            .MAX_CORE(NC-1),
            .MAX_NUM(TOTAL_PKT_PER_ROUTER),
            .HOTSPOT_PERCENTAGE(50),
            .HOTSOPT_NUM(1),
            .HOTSPOT_CORE_1(1)
        )
        rnd_class_gen
        (
            .core(ip_num),
            .num(pck_counter),
            .rnd(rnd_class ),
            .rnd_en(1'b1),
            .reset(reset),
            .clk(clk)
        );
    
    end else begin 
   
        pseudo_hotspot #(
            .MAX_RND (1), // c=0 or 1
            .MAX_CORE (NC-1),
            .MAX_NUM (TOTAL_PKT_PER_ROUTER),
            .HOTSPOT_PERCENTAGE (50),
            .HOTSOPT_NUM (1),
            .HOTSPOT_CORE_1(0)
        )
        rnd_class_gen
        (
            .core(ip_num),
            .num(pck_counter),
            .rnd(rnd_class ),
            .rnd_en(1'b1),
            .reset(reset),
            .clk(clk)
        );
    end
             
             
             
    assign class_hdr        ={{(CLASS_IN_HDR_WIDTH-Vw){1'b0}},rnd_class };
            
        
    if (TRAFFIC == "RANDOM") begin 
        
        pseudo_random_no_core #(
            .MAX_RND (NC-1),
            .MAX_CORE   (NC-1   ),
            .MAX_NUM    (TOTAL_PKT_PER_ROUTER)
        )
        rnd_dest_gen
        (
            .core (ip_num),
            .num  (pck_counter),
            .rnd  (dest_ip_num),
            .rnd_en (1'b1),
            .reset  (reset),
            .clk        (clk)

        );
       
        assign dest_x = (dest_ip_num %NX ); 
        assign dest_y = (dest_ip_num /NX );  
        
     end else if (TRAFFIC == "HOTSPOT") begin 
                      
                pseudo_hotspot_no_core #(
                    .MAX_RND            (NC-1   ),
                    .MAX_CORE           (NC-1   ),
                    .MAX_NUM            (TOTAL_PKT_PER_ROUTER),
                    .HOTSPOT_PERCENTAGE (HOTSPOT_PERCENTAGE),   //maximum 25%
                    .HOTSOPT_NUM        (HOTSOPT_NUM), //maximum 4
                    .HOTSPOT_CORE_1     (HOTSPOT_CORE_1),
                    .HOTSPOT_CORE_2     (HOTSPOT_CORE_2),
                    .HOTSPOT_CORE_3     (HOTSPOT_CORE_3),
                    .HOTSPOT_CORE_4     (HOTSPOT_CORE_4),
                    .HOTSPOT_CORE_5     (HOTSPOT_CORE_5)
                    
                )rnd_dest_gen
                (
    
                    .core  (ip_num),
                    .num   (pck_counter),
                    .rnd   (dest_ip_num),
                    .rnd_en(1'b1),
                    .reset (reset),
                    .clk   (clk)

                );
       
        assign dest_x = (dest_ip_num %NX ); 
        assign dest_y = (dest_ip_num /NX );  
   
       
    end else if( TRAFFIC == "TRANSPOSE1") begin 
       
                    assign dest_x   = NX-current_y-1;
                    assign dest_y   = NY-current_x-1;
            
        
    end else if( TRAFFIC == "TRANSPOSE2") begin :transpose2
        
                    assign dest_x   = current_y;
                    assign dest_y   = current_x;
                    
        
    end  else if( TRAFFIC == "BIT_REVERSE") begin :bitreverse
   
                    wire [(Xw+Yw)-1 :   0] joint_addr, reverse_addr;
                    assign joint_addr  = {current_x,current_y};
                    
                    for(i=0; i<(Xw+Yw); i=i+1'b1) begin :lp//reverse the address
                        assign reverse_addr[i]  = joint_addr [((Xw+Yw)-1)-i];
                    end
                    assign {dest_x,dest_y } = reverse_addr;
   
    end  else if( TRAFFIC == "BIT_COMPLEMENT") begin :bitcomp
                              
                    assign dest_x   = ~current_x;
                    assign dest_y   = ~current_y;              
    
      
    end else if(TRAFFIC == "CUSTOM" )begin 
        /*
        assign send_en = (current_x==0 && current_y==0);// core (0,0) sends packets to (7,7)
        assign dest_x = 7;
        assign dest_y = 7;
   */
        reg [Xw-1   :   0]dest_xx;
        reg [Yw-1   :   0]dest_yy;
        reg               send_enen;
        always @(*) begin 
            send_enen=1'b0;       
            if((current_x==0) &&  (current_y== 0)) begin 
                dest_xx=  1; dest_yy=  1; send_enen=1'b1;
            end
            if((current_x==0) &&  (current_y== 1)) begin 
                dest_xx=  1; dest_yy=  2; send_enen=1'b1;
            end
            if((current_x==1) &&  (current_y== 0)) begin 
                dest_xx=  1; dest_yy=  7; send_enen=1'b1;
            end
            if((current_x==1) &&  (current_y== 1)) begin 
                dest_xx=  1; dest_yy=  6; send_enen=1'b1;
            end
            if((current_x==1) &&  (current_y== 2)) begin 
                dest_xx=  1; dest_yy=  5; send_enen=1'b1;
            end
            if((current_x==1) &&  (current_y== 3)) begin 
                dest_xx=  1; dest_yy=  4; send_enen=1'b1;
            end
        end
      /*
        0  0   1  1
        0  1   1  2
        1  0   1  7
        1  1   1  6
        1  2   1  5
        1  3   1  4
        */
        assign send_en = send_enen;
        assign dest_y =  dest_yy;
        assign dest_x = dest_xx;
              
    end
   
    
     //check if destination address is valid
     if(TRAFFIC != "CUSTOM" )begin 
         assign send_en  = ({dest_x,dest_y}  !=  {current_x,current_y} ) &  (dest_x  <= (NX-1)) & (dest_y  <= (NY-1));
     end
   
    endgenerate
     
endmodule


