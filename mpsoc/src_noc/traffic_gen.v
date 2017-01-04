`timescale  1ns/1ps

`define CHECK_PCKS_CONTENT       // if defined check flit ordering, 

/**************************************
* Module: traffic_gen
* Date:2015-03-05  
* Author: alireza     
*
* Description: 
***************************************/
module  traffic_gen #(
    parameter V = 4,    // VC num per port
    parameter B = 4,    // buffer space :flit per VC 
    parameter NX= 4,    // number of node in x axis
    parameter NY= 4,    // number of node in y axis   
    parameter Fpay = 32,
    parameter VC_REALLOCATION_TYPE  = "NONATOMIC",// "ATOMIC" , "NONATOMIC"
    parameter TOPOLOGY  = "MESH",
    parameter ROUTE_NAME    = "XY",
    parameter C = 4,    //  number of flit class    
    parameter MAX_PCK_NUM   = 10000,
    parameter MAX_SIM_CLKs  = 100000,
    parameter MAX_PCK_SIZ   = 10,  // max packet size
    parameter TIMSTMP_FIFO_NUM=16  
    
)
(
    //input 
    ratio,
    pck_size,   
    current_x,
    current_y,
    dest_x,
    dest_y, 
    pck_class_in,        
    start,   
    report,
   
   
   //output
    pck_number,
    sent_done, // tail flit has been sent
    hdr_flit_sent,
    update, // update the noc_analayzer
    distance,
    pck_class_out,   
    time_stamp_h2h,
    time_stamp_h2t,
   
   //noc port
    flit_out,     
    flit_out_wr,   
    credit_in,
    flit_in,   
    flit_in_wr,   
    credit_out,     
   
    reset,
    clk
);

    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
   endfunction // log2 
   
    localparam P=  (TOPOLOGY=="RING")? 3 : 5;  
    localparam ROUTE_TYPE = (ROUTE_NAME == "XY" || ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
                           (ROUTE_NAME == "DUATO" || ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE";
   
    localparam RATIOw= log2(100),
                Vw    =  (V==1)? 1 : log2(V);
               
   
   
    reg [2:0]   ps,ns;
    localparam IDEAL =3'b001, SENT =3'b010, WAIT=3'b100;
   
   
    
   
   
    
    localparam      P_1         =   P-1, 
                    Xw          =   log2(NX),   // number of node in x axis
                    Yw          =   log2(NY),    // number of node in y axis
                    Cw          =   (C>1)? log2(C) : 1,
                    Fw          =   2+V+Fpay,
                    PCK_CNTw    = log2(MAX_PCK_NUM+1),
                    CLK_CNTw    = log2(MAX_SIM_CLKs+1),
                    PCK_SIZw    = log2(MAX_PCK_SIZ+1);

    
    localparam      CLASS_IN_HDR_WIDTH      =8,
                    DEST_IN_HDR_WIDTH       =8,
                    X_Y_IN_HDR_WIDTH        =4;
   
    
    input reset, clk;
    input  [RATIOw-1                :0] ratio;
    input                               start;
    output                              update;
    output [CLK_CNTw-1              :0] time_stamp_h2h,time_stamp_h2t;
    output [31                      :0] distance;
    output [Cw-1                    :0] pck_class_out;
    input  [Xw-1                    :0] current_x;
    input  [Yw-1                    :0] current_y;
    input  [Xw-1                    :0] dest_x;
    input  [Yw-1                    :0] dest_y;
    output [PCK_CNTw-1              :0] pck_number;
    input  [PCK_SIZw-1              :0] pck_size;
    output reg sent_done;
    output hdr_flit_sent;
    input  [Cw-1                    :0] pck_class_in;
    
    // NOC interfaces
    output  [Fw-1                   :0] flit_out;     
    output  reg                         flit_out_wr;   
    input   [V-1                    :0] credit_in;
    
    input   [Fw-1                   :0] flit_in;   
    input                               flit_in_wr;   
    output reg  [V-1                :0] credit_out;     
    
    input                               report;
    

    
    reg                                 inject_en,cand_wr_vc_en,pck_rd;

    
   
   
    wire    [P_1-1                  :   0] destport;   
    wire    [DEST_IN_HDR_WIDTH-1    :   0] wr_destport_hdr;
    wire    [V-1                    :   0] ovc_wr_in;
    wire    [V-1                    :   0] full_vc,empty_vc;
    reg     [V-1                    :   0] wr_vc,wr_vc_next;
    wire    [V-1                    :   0] cand_vc;
    wire    [X_Y_IN_HDR_WIDTH-1     :   0] wr_des_x_addr,wr_des_y_addr;
    wire    [X_Y_IN_HDR_WIDTH-1     :   0] wr_src_x_addr,wr_src_y_addr;
    wire    [CLASS_IN_HDR_WIDTH-1   :   0] wr_class_hdr;
    wire    [CLK_CNTw-1             :   0] wr_timestamp,pck_timestamp;
    wire                                   hdr_flit,tail_flit;
    reg     [PCK_SIZw-1             :   0] flit_counter;
    reg                                    flit_cnt_rst,flit_cnt_inc;
    wire    [1                      :   0] rd_hdr_flg;
    wire    [CLASS_IN_HDR_WIDTH-1   :   0] rd_class_hdr;
    wire    [DEST_IN_HDR_WIDTH-1    :   0] rd_destport_hdr;
    wire    [X_Y_IN_HDR_WIDTH-1     :   0] rd_des_x_addr,   rd_des_y_addr,rd_src_x_addr,rd_src_y_addr;
    reg     [CLK_CNTw-1             :   0] rsv_counter,last_pck_time;
    reg     [CLK_CNTw-1             :   0] clk_counter;
    wire    [Vw-1                   :   0] rd_vc_bin,wr_vc_bin;
    reg     [CLK_CNTw-1             :   0] rsv_time_stamp[V-1:0];
    wire    [V-1                    :   0] rd_vc; 
    wire                                   wr_vc_is_full,wr_vc_avb,wr_vc_is_empty;
    reg     [V-1                    :   0] credit_out_next;
    reg     [X_Y_IN_HDR_WIDTH-1     :   0] rsv_pck_src_x        [V-1:0];
    reg     [X_Y_IN_HDR_WIDTH-1     :   0] rsv_pck_src_y        [V-1:0];
    reg     [Cw-1                   :   0] rsv_pck_class_in     [V-1:0];  
      
    
    
    wire pck_wr,buffer_full,pck_ready,valid_dst;
     
    assign valid_dst  = ({dest_x,dest_y}  !=  {current_x,current_y} ) &  (dest_x  <= (NX-1)) & (dest_y  <= (NY-1));
    assign hdr_flit_sent=pck_rd;
    
    
    injection_ratio_ctrl #
    (
        .MAX_PCK_SIZ(MAX_PCK_SIZ)
    )
    pck_inject_ratio_ctrl
    (
        .en(inject_en),
        .pck_size(pck_size),
        .clk(clk),
        .reset(reset),
        .freez(buffer_full),
        .inject(pck_wr),
        .ratio(ratio)
   );
    
    
    
    output_vc_status #(
        .V  (V),
        .B  (B),
        .CAND_VC_SEL_MODE       (0) // 0: use arbieration between not full vcs, 1: select the vc with moast availble free space
    )
    nic_ovc_status
    (
    .wr_in                      (ovc_wr_in),   
    .credit_in                  (credit_in),
    .nearly_full_vc             (full_vc),
    .empty_vc                   (empty_vc),
    .cand_vc                    (cand_vc),
    .cand_wr_vc_en              (cand_wr_vc_en),
    .clk                        (clk),
    .reset                      (reset)
    );
    
   
    
    
    
    packet_gen #(
    	.P(P),
    	.NX(NX),
    	.NY(NY),
    	.TOPOLOGY(TOPOLOGY),
    	.ROUTE_NAME(ROUTE_NAME),
    	.ROUTE_TYPE(ROUTE_TYPE),
    	.MAX_PCK_NUM(MAX_PCK_NUM),
    	.MAX_SIM_CLKs(MAX_SIM_CLKs),
    	.TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM)
    )
    packet_buffer
    (
    	.reset(reset),
    	.clk(clk),
    	.pck_wr(pck_wr),
    	.pck_rd(pck_rd),
    	.current_x(current_x),
    	.current_y(current_y),
    	.clk_counter(clk_counter),
    	.pck_number(pck_number),
    	.dest_x(dest_x),
    	.dest_y(dest_y),
    	.pck_timestamp(pck_timestamp),
    	.buffer_full(buffer_full),
    	.pck_ready(pck_ready),
    	.valid_dst(valid_dst),
    	.destport(destport)
    );
    

    
   
    assign wr_class_hdr    ={{(CLASS_IN_HDR_WIDTH-Cw){1'b0}},pck_class_in};
    assign wr_destport_hdr ={{(DEST_IN_HDR_WIDTH-P_1){1'b0}},destport};
    assign wr_des_x_addr   ={{(X_Y_IN_HDR_WIDTH-Xw){1'b0}},  dest_x};
    assign wr_des_y_addr   ={{(X_Y_IN_HDR_WIDTH-Yw){1'b0}},  dest_y};
    assign wr_src_x_addr   ={{(X_Y_IN_HDR_WIDTH-Yw){1'b0}},  current_x};
    assign wr_src_y_addr   ={{(X_Y_IN_HDR_WIDTH-Yw){1'b0}},  current_y};
    assign wr_timestamp    =pck_timestamp;
        


   
    
    assign  update      = flit_in_wr & flit_in[Fw-2];
    assign  hdr_flit    = (flit_counter == 0);
    assign  tail_flit   = (flit_counter ==  pck_size-1'b1);
    assign  time_stamp_h2h  =  rsv_time_stamp[rd_vc_bin] - flit_in[CLK_CNTw-1             :   0];
    assign  time_stamp_h2t  = clk_counter - flit_in[CLK_CNTw-1             :   0];

    assign flit_out =   (hdr_flit)     ?    {2'b10,wr_vc,wr_class_hdr,wr_destport_hdr,wr_des_x_addr,wr_des_y_addr,wr_src_x_addr,wr_src_y_addr}:
                        (tail_flit)    ?    {2'b01,wr_vc,{(Fpay-CLK_CNTw){1'b0}},wr_timestamp}:
                                            {2'b00,wr_vc,{(Fpay-PCK_SIZw-PCK_CNTw){1'd0}},pck_number,flit_counter};

assign {rd_hdr_flg,rd_vc,rd_class_hdr,rd_destport_hdr,rd_des_x_addr,rd_des_y_addr,rd_src_x_addr,rd_src_y_addr} = flit_in;                                     

    wire [Xw-1        :   0]    src_x;
    wire [Yw-1        :   0]    src_y;
    assign src_x            = rsv_pck_src_x[rd_vc_bin][Xw-1 :   0];
    assign src_y            = rsv_pck_src_y[rd_vc_bin][Yw-1 :   0];
    assign pck_class_out    = rsv_pck_class_in[rd_vc_bin];
   
   
    
    distance_gen #(
    	.NX(NX),
    	.NY(NY),
    	.TOPOLOGY(TOPOLOGY)
    )
    the_distance_gen
    (
    	.src_x(src_x),
    	.dest_x(current_x),
    	.src_y(src_y),
    	.dest_y(current_y),
    	.distance(distance)
    );
 
 generate 
 if(V==1) begin : v1
    assign rd_vc_bin=1'b0;
    assign wr_vc_bin=1'b0;
 end else begin :vother  

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
 end 
 endgenerate
    
    
    assign  ovc_wr_in   = (flit_out_wr ) ?      wr_vc : {V{1'b0}};

    assign  wr_vc_is_full           =   | ( full_vc & wr_vc);
    
    
    
    generate
        if(VC_REALLOCATION_TYPE ==  "NONATOMIC") begin  
            assign wr_vc_avb    =  ~wr_vc_is_full; 
        end else begin 
	    assign wr_vc_is_empty	=  | ( empty_vc & wr_vc);
            assign wr_vc_avb		=  wr_vc_is_empty;      
        end
    endgenerate



always @(*)begin
            wr_vc_next          = wr_vc; 
            cand_wr_vc_en       = 1'b0;
            flit_out_wr         = 1'b0;
            flit_cnt_inc        = 1'b0;
            flit_cnt_rst        = 1'b0;
            credit_out_next     = {V{1'd0}};
            sent_done           = 1'b0;
            pck_rd              = 1'b0;
            ns                  = ps;
            pck_rd              =1'b0;
           
            case (ps) 
                IDEAL: begin 
                  if(pck_ready ) begin 
                        if(wr_vc_avb && valid_dst)begin
                            pck_rd=1'b1; 
                            flit_out_wr     = 1'b1;
                            flit_cnt_inc = 1'b1;
                            ns              = SENT;
                            
                            
                        end//wr_vc
                    end //injection_en
                end //IDEAL
                SENT: begin 
                     
                    if(!wr_vc_is_full )begin 
                        flit_out_wr     = 1'b1;
                        if(flit_counter  < pck_size-1) begin 
                            flit_cnt_inc = 1'b1;
                        end else begin 
                            flit_cnt_rst   = 1'b1;
                            sent_done       =1'b1;
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
    

always @(posedge clk or posedge reset )begin 
        if(reset) begin 
            inject_en       <= 1'b0;
            ps              <= IDEAL;
            wr_vc           <=1; 
            flit_counter    <= {PCK_SIZw{1'b0}};
            credit_out      <= {V{1'd0}};
            rsv_counter     <= 0;
            clk_counter     <=  0;
           
        
        end
        else begin 
            //injection
            inject_en <=  start |inject_en;  
            ps             <= ns;
            clk_counter     <= clk_counter+1'b1;
            wr_vc           <=wr_vc_next; 
            if (flit_cnt_rst)      flit_counter    <= {PCK_SIZw{1'b0}};
            else if(flit_cnt_inc)   flit_counter    <= flit_counter + 1'b1;     
            credit_out      <= credit_out_next;
            
           
            //sink
            if(flit_in_wr) begin 
                    if (flit_in[Fw-1])begin 
                        rsv_pck_src_x[rd_vc_bin]    <=  rd_src_x_addr;
                        rsv_pck_src_y[rd_vc_bin]    <=  rd_src_y_addr;
                        rsv_pck_class_in[rd_vc_bin]    <= rd_class_hdr[Cw-1                            :   0];
                        rsv_time_stamp[rd_vc_bin]   <= clk_counter;  
                        rsv_counter                 <= rsv_counter+1'b1;
                                            
                    //  distance        <= {{(32-8){1'b0}},flit_in[7:0]};
                        // synthesis translate_off
                        //last_pck_time<=$time;
                        //$display ("%d,\t toptal of %d pcks have been recived in core (%d,%d)", last_pck_time,rsv_counter,X,Y);
                        // synthesis translate_on
                    end
            end
        
        // synthesis translate_off
            if(report) begin 
                 $display ("%t,\t toptal of %d pcks have been recived in core (%d,%d)", last_pck_time,rsv_counter,current_x,current_y);
            end
        // synthesis translate_on
         
        
         
        
         
        
        end
    end//always

   // synthesis translate_off
    always @(posedge clk) begin     
        if(flit_out_wr && hdr_flit && wr_des_x_addr[Xw-1    :   0] == current_x && wr_des_y_addr[Yw-1    :   0] == current_y) $display("%t: Error: The source and destination address of injected packet is the same in router(%d,%d) ",$time, wr_des_x_addr ,wr_des_y_addr);                                                             
        if(flit_in_wr && rd_hdr_flg[1] && rd_des_x_addr [Xw-1    :   0]  != current_x && rd_des_y_addr [Yw-1    :   0] != current_y ) $display("%t: Error: packet with des(%d,%d) has been recieved in wrong router (%d,%d).  ",$time,rd_des_x_addr, rd_des_y_addr, current_x , current_y);        
    end
    // synthesis translate_on
    
    
    
    `ifdef CHECK_PCKS_CONTENT
    // synthesis translate_off
    
    wire     [PCK_SIZw-1             :   0] rsv_flit_counter; 
    reg      [PCK_SIZw-1             :   0] old_flit_counter    [V-1   :   0];
    wire     [PCK_CNTw-1             :   0] rsv_pck_number;
    reg      [PCK_CNTw-1             :   0] old_pck_number  [V-1   :   0];
    
    assign {rsv_pck_number,rsv_flit_counter}=flit_in [PCK_CNTw+PCK_SIZw-1             :   0];
    
    integer ii;
    always @(posedge clk or posedge reset )begin 
        if(reset) begin
            for(ii=0;ii<V;ii=ii+1'b1)begin
                old_flit_counter[ii]<=0;            
            end        
        end else begin
            if(flit_in_wr)begin
                if      ( flit_in[Fw-1:Fw-2]==2'b10)  begin
                    old_pck_number[rd_vc_bin]<=0;
                    old_flit_counter[rd_vc_bin]<=0;
                end else if ( flit_in[Fw-1:Fw-2]==2'b00)begin 
                    old_pck_number[rd_vc_bin]<=rsv_pck_number;
                    old_flit_counter[rd_vc_bin]<=rsv_flit_counter;
                end                    
                
            end       
        
        end    
    end
    
    
    always @(posedge clk) begin     
        if(flit_in_wr && (flit_in[Fw-1:Fw-2]==2'b00) && (~reset))begin 
            if( old_flit_counter[rd_vc_bin]!=rsv_flit_counter-1) $display("%t: Error: missmatch flit counter in %m. Expected %d but recieved %d",$time,old_flit_counter[rd_vc_bin]+1,rsv_flit_counter);
            if( old_pck_number[rd_vc_bin]!=rsv_pck_number && old_pck_number[rd_vc_bin]!=0)       $display("%t: Error: missmatch pck number in %m. expected %d but recieved %d",$time,old_pck_number[rd_vc_bin],rsv_pck_number);
                       
        end
   
    end
    // synthesis translate_on
    
    
    `endif
    

endmodule





/*****************************

    injection_ratio_ctrl
        
*****************************/

module injection_ratio_ctrl #
(
 parameter MAX_PCK_SIZ=10
)
(
 en,
 pck_size,
 clk,
 reset,
 inject,// inject one packet
 freez,
 ratio // 0~100  flit injection ratio


);

    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
   endfunction // log2 
   
   
   
   localparam PCK_SIZw= log2(MAX_PCK_SIZ);
   localparam CNTw    =   log2(100);
   localparam STATE_INIT=   MAX_PCK_SIZ*100;
   localparam STATEw    =   log2(MAX_PCK_SIZ*200);

    input                       clk,reset,freez,en;
    output  reg                 inject;
    input   [CNTw-1     :   0]  ratio;
    input   [PCK_SIZw-1 :   0]  pck_size;


    wire    [CNTw-1     :   0]  on_clks, off_clks;
    reg     [STATEw-1   :   0]  state,next_state;
    wire                        input_changed;
    reg     [CNTw-1     :   0]  ratio_old;    
    
    always @(posedge clk ) ratio_old<=ratio;
    
    assign input_changed = (ratio_old!=ratio);
    
    
    assign on_clks = ratio; 
    assign off_clks =7'd100-ratio; 
    
    reg [PCK_SIZw-1 :0] flit_counter,next_flit_counter;
    
    
    reg sent,next_sent,next_inject;
 
 
 
 always @(*) begin 
      next_state		=state;
      next_flit_counter	=flit_counter;
      next_sent			=sent;
      if(en && ~freez ) begin
			case(sent)
				1'b1: begin 
					next_state 			= state +  off_clks; 
					next_flit_counter = (flit_counter == pck_size-1'b1) ? {PCK_SIZw{1'b0}} : flit_counter +1'b1;
					next_inject			= (flit_counter=={PCK_SIZw{1'b0}});
					if (next_flit_counter == pck_size-1'b1) begin 
						 if( next_state  >= STATE_INIT ) next_sent =1'b0;
					end
				end
				1'b0:begin 
					if( next_state  <  STATE_INIT ) next_sent  = 1'b1;
					next_inject= 1'b0;
					next_state = state - on_clks;
				end
			endcase		
		end else begin 
			 next_inject= 1'b0;
		end
	end		
		

		

		
			 
 
 
    always @(posedge clk or posedge reset) begin 
        if( reset) begin            
            state       <=  STATE_INIT;
            inject      <=  1'b0; 
            sent        <=  1'b1; 
            flit_counter<= 0;
        end else begin 
            if(input_changed)begin
                state       <=  STATE_INIT;
                inject      <=  1'b0; 
                sent        <=  1'b1; 
                flit_counter<= 0;
            end
        
        
			state       <=  next_state;
           if(ratio!={CNTw{1'b0}}) inject      <=  next_inject; 
            sent        <=  next_sent; 
            flit_counter<=  next_flit_counter;
			  
		  end
    end     


endmodule



 
 /*************************************
 
        packet_buffer
 
 **************************************/
 
 
 module packet_gen #(   
    parameter P = 5,    
    parameter NX= 4,    
    parameter NY= 4,    
    parameter TOPOLOGY  = "MESH",
    parameter ROUTE_NAME = "XY",
    parameter ROUTE_TYPE = "DETERMINISTIC",
    parameter MAX_PCK_NUM   = 10000,
    parameter MAX_SIM_CLKs  = 100000,
    parameter TIMSTMP_FIFO_NUM=16 
 
 )(
    clk_counter,
    pck_wr,
    pck_rd,
    current_x,
    current_y,
    pck_number,
    dest_x,
    dest_y,
    pck_timestamp,
    destport,
    buffer_full,
    pck_ready,
    valid_dst,
    clk,
    reset
 
 );
 
  function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
   endfunction // log2 
   
 
    
    localparam      P_1         =   P-1,
                    Xw          =   log2(NX),   // number of node in x axis
                    Yw          =   log2(NY),    // number of node in y axis
                    PCK_CNTw    =   log2(MAX_PCK_NUM+1),
                    CLK_CNTw    =   log2(MAX_SIM_CLKs+1); 
    
    
 
 input                               reset,clk, pck_wr, pck_rd;
 input  [Xw-1                    :0] current_x;
 input  [Yw-1                    :0] current_y;
 input  [CLK_CNTw-1              :0] clk_counter;
 
 output [PCK_CNTw-1              :0] pck_number;
 input  [Xw-1                    :0] dest_x;
 input  [Yw-1                    :0] dest_y;
 output [CLK_CNTw-1              :0] pck_timestamp;   
 output                              buffer_full,pck_ready;
 input                               valid_dst; 
 output [P_1-1                   :0] destport; 
 
 
 reg    [PCK_CNTw-1              :0] packet_counter;  
 wire                                buffer_empty;
 

 
 
 
 
 assign pck_ready = ~buffer_empty & valid_dst;

   
   
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
        .current_x (current_x),
        .current_y (current_y),
        .dest_x    (dest_x),
        .dest_y    (dest_y),
        .destport  (destport)
    );
    
   
    fifo #(
    	.Dw(CLK_CNTw),
    	.B(TIMSTMP_FIFO_NUM)
    )
    timestamp_fifo
    (
    	.din(clk_counter),
    	.wr_en(pck_wr),
    	.rd_en(pck_rd),
    	.dout(pck_timestamp),
    	.full(buffer_full),
    	.nearly_full(),
    	.empty(buffer_empty),
    	.reset(reset),
    	.clk(clk)
    );
    
    always @ (posedge clk or posedge reset) begin 
        if(reset) begin 
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

    distance_gen 
     
********************/

module distance_gen #(
    parameter NX= 4,    // number of node in x axis
    parameter NY= 4,    // number of node in y axis
    parameter TOPOLOGY  = "MESH"

)(
    src_x,
    src_y,
    dest_x,
    dest_y,
    distance

);
    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
    endfunction // log2 
 
 
    localparam      Xw  =   log2(NX),   // number of node in x axis
                    Yw  =   log2(NY);    // number of node in y axis  
                   


    input [Xw-1 :   0]src_x,dest_x;
    input [Yw-1 :   0]src_y,dest_y;
    output[31   :   0]distance;
       
    reg [Xw-1  :   0] x_offset;
    reg [Yw-1  :   0] y_offset;
    
    generate 
    if( TOPOLOGY == "MESH") begin 
        
        always @(*) begin 
            x_offset     = (src_x> dest_x)? src_x - dest_x : dest_x - src_x;
            y_offset     = (src_y> dest_y)? src_y - dest_y : dest_y - src_y;
         end
        
    
    
    end else begin //torus
    
        wire tranc_x_plus,tranc_x_min,tranc_y_plus,tranc_y_min,same_x,same_y;
                
        always @ (*) begin 
            
            //x_offset
            if(same_x) x_offset= {Xw{1'b0}};
            else if(tranc_x_plus) begin 
                if(dest_x   > src_x)    x_offset= dest_x-src_x; 
                else                    x_offset= (NX-src_x)+dest_x;
            end
            else if(tranc_x_min)  begin 
                if(dest_x   <  src_x)    x_offset= src_x-dest_x; 
                else                     x_offset= src_x+(NX-dest_x);
            
            end
        
             //y_offset
            if(same_y) y_offset= {Yw{1'b0}};
            else if(tranc_y_plus) begin 
                if(dest_y   > src_y)    y_offset= dest_y-src_y; 
                else                    y_offset= (NY-src_y)+dest_y;
            end
            else if(tranc_y_min)  begin 
                if(dest_y   <  src_y)    y_offset= src_y-dest_y; 
                else                     y_offset= src_y+(NY-dest_y);
            
            end
        
        
        
        
        
        end
        
        
            
        tranc_dir #(
        	.NX(NX),
        	.NY(NY)
        )
        tranc_dir(
        	.tranc_x_plus(tranc_x_plus),
        	.tranc_x_min(tranc_x_min),
        	.tranc_y_plus(tranc_y_plus),
        	.tranc_y_min(tranc_y_min),
        	.same_x(same_x),
        	.same_y(same_y),
        	.current_x(src_x),
        	.current_y(src_y),
        	.dest_x(dest_x),
        	.dest_y(dest_y)
        );
    
    
    end    
    endgenerate
    
    assign distance     =   x_offset+y_offset+1;

endmodule
 
 

