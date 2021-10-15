`timescale  1ns/1ps

module  traffic_gen_top
		import pronoc_pkg::*; 
	#(
		parameter MAX_RATIO = 1000,
		parameter ENDP_ID   = 10
	)
	(
					
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
		
		reset,
		clk
			
	);
		
	localparam
		RATIOw= $clog2(MAX_RATIO);
		
	//	Vw =    $clog2(V);
			
	input   smartflit_chanel_t 	chan_in;
	output  smartflit_chanel_t 	chan_out;  
		
		
   
   
	localparam
		PCK_CNTw = log2(MAX_PCK_NUM+1),
		CLK_CNTw = log2(MAX_SIM_CLKs+1),
		PCK_SIZw = log2(MAX_PCK_SIZ+1),
		AVG_PCK_SIZw = log2(10*MAX_PCK_SIZ+1),
		/* verilator lint_off WIDTH */
		DISTw = (TOPOLOGY=="FATTREE" || TOPOLOGY=="TREE" ) ? log2(2*L+1): log2(NR+1),
		W=WEIGHTw,
		PORT_B = (TOPOLOGY!="FMESH")?  LB :
		(ENDP_ID < NE_MESH_TORI)? LB :B; // in FMESH, the buffer size of endpoints connected to edge routers non-local ports are B not LB  
		/* verilator lint_on WIDTH */
	input reset, clk;
	input  [RATIOw-1                :0] ratio;
	input                               start,stop;
	output                              update;
	output [CLK_CNTw-1              :0] time_stamp_h2h,time_stamp_h2t;
	output [DISTw-1                 :0] distance;
	output [Cw-1                    :0] pck_class_out;
	
	// the current endpoint address
	input  [EAw-1                   :0] current_e_addr;    
	// the destination endpoint address
	input  [EAw-1                   :0] dest_e_addr;  
    
	output [PCK_CNTw-1              :0] pck_number;
	input  [PCK_SIZw-1              :0] pck_size_in;
    
	output reg sent_done;
	output reg hdr_flit_sent;
	input  [Cw-1                    :0] pck_class_in;
	input  [W-1                     :0] init_weight;
		
	input                               report;
	input  [DELAYw-1           		:0] start_delay;
	// the received packet source endpoint address
	output [EAw-1        :   0]    src_e_addr;
	output [PCK_SIZw-1   :   0]    pck_size_o;	
	
		
	logic  [Fw-1                   :0] flit_out;     
	output  logic                       flit_out_wr; 
	output  [Cw-1 : 0] flit_out_class;
	logic   [V-1                    :0] credit_in;
    
	logic   [Fw-1                   :0] flit_in;   
	output logic                              flit_in_wr;   
	logic  [V-1                :0] credit_out;     
	
	// the connected router address
	wire  [RAw-1                   :0] current_r_addr;    
		
		
	assign 	chan_out.flit_chanel.flit = flit_out; 
	assign  chan_out.flit_chanel.flit_wr = flit_out_wr;
	assign  chan_out.flit_chanel.credit = credit_out;
		
		
	assign flit_in   =  chan_in.flit_chanel.flit;   
	assign flit_in_wr=  chan_in.flit_chanel.flit_wr; 
	assign credit_in =  chan_in.flit_chanel.credit;  
	assign current_r_addr = chan_in.ctrl_chanel.neighbors_r_addr;
	
	genvar i;
	generate
	for (i=0; i<V;i++) begin :V_
		assign chan_out.ctrl_chanel.credit_init_val[i]= PORT_B;
	end
	endgenerate
		
	//old traffic.v file
		
	reg [2:0]   ps,ns;
	localparam IDEAL =3'b001, SENT =3'b010, WAIT=3'b100;
		
	reg                                 inject_en,cand_wr_vc_en,pck_rd;
	reg    [PCK_SIZw-1              :0] pck_size, pck_size_next;    
	reg    [EAw-1                    :0] dest_e_addr_reg;
		
	// synopsys  translate_off
	// synthesis translate_off
                                      
	`ifdef MONITORE_PATH
     
   
		reg tt;
		always @(posedge clk) begin
			if(reset)begin 
				tt<=1'b0;               
			end else begin 
				if(flit_out_wr && tt==1'b0 )begin
					$display( "%t: Injector: current_r_addr=%x,current_e_addr=%x,dest_e_addr=%x\n",$time, current_r_addr, current_e_addr, dest_e_addr);
					tt<=1'b1;
				end
			end
		end
	`endif
    
	// synthesis translate_on
	// synopsys  translate_on  
   
   
   
   
   
   
	localparam
		HDR_DATA_w =  (MIN_PCK_SIZE==1)? CLK_CNTw : 0,
		HDR_Dw =  (MIN_PCK_SIZE==1)? CLK_CNTw : 1;
   
	wire [HDR_Dw-1 : 0] hdr_data_in,rd_hdr_data_out;
   
    
	`ifdef SYNC_RESET_MODE 
		always @ (posedge clk )begin 
		`else 
			always @ (posedge clk or posedge reset)begin 
			`endif   
			if(reset) begin 
				dest_e_addr_reg<={EAw{1'b0}};           
			end else begin 
				dest_e_addr_reg<=dest_e_addr;       
			end
		end
   
		wire    [DSTPw-1                :   0] destport;   
		wire    [V-1                    :   0] ovc_wr_in;
		wire    [V-1                    :   0] full_vc,empty_vc,nearly_full_vc;
		reg     [V-1                    :   0] wr_vc,wr_vc_next;
		wire    [V-1                    :   0] cand_vc;
    
    
		wire    [CLK_CNTw-1             :   0] wr_timestamp,pck_timestamp;
		wire                                   hdr_flit,tail_flit;
		reg     [PCK_SIZw-1             :   0] flit_counter;
		reg                                    flit_cnt_rst,flit_cnt_inc;
		wire                                   rd_hdr_flg,rd_tail_flg;
		wire    [Cw-1   :   0] rd_class_hdr;
		//  wire    [P_1-1      :   0] rd_destport_hdr;
		wire    [EAw-1      :   0] rd_des_e_addr, rd_src_e_addr;  
		reg     [CLK_CNTw-1             :   0] rsv_counter;
		reg     [CLK_CNTw-1             :   0] clk_counter;
		wire    [Vw-1                   :   0] rd_vc_bin;//,wr_vc_bin;
		reg     [CLK_CNTw-1             :   0] rsv_time_stamp[V-1:0];
		reg     [PCK_SIZw-1             :   0] rsv_pck_size    [V-1:0];
		wire    [V-1                    :   0] rd_vc; 
		wire                                   wr_vc_is_full,wr_vc_avb,wr_vc_is_empty;
		reg     [V-1                    :   0] credit_out_next;
		reg     [EAw-1     :   0] rsv_pck_src_e_addr        [V-1:0];
		reg     [Cw-1                   :   0] rsv_pck_class_in     [V-1:0];  
      
		wire [CLK_CNTw-1             :   0] hdr_flit_timestamp;    
		wire pck_wr,buffer_full,pck_ready,valid_dst;    
		wire [CLK_CNTw-1 : 0] rd_timestamp;
   
   	    
		
		logic [DELAYw-1 : 0] start_delay_counter,start_delay_counter_next;
		logic  start_en_next , start_en;

		register #(.W(1)) streg1 (.reset(reset),.clk(clk), .in(start_en_next), .out(start_en)	);
		register #(.W(DELAYw)) streg2 (.reset(reset),.clk(clk), .in(start_delay_counter_next), .out(start_delay_counter)	);
		
		
		
		always @(*) begin 
			start_en_next =start_en;
			start_delay_counter_next= start_delay_counter;
			if(start)	begin 
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
				.SELF_LOOP_EN(SELF_LOOP_EN)
			)
			check_destination_addr(
				.dest_e_addr(dest_e_addr),
				.current_e_addr(current_e_addr),
				.dest_is_valid(valid_dst)
			);
   
    
		//assign hdr_flit_sent=pck_rd;
    
    
		injection_ratio_ctrl #
			(
				.MAX_PCK_SIZ(MAX_PCK_SIZ),
				.MAX_RATIO(MAX_RATIO)
			)
			pck_inject_ratio_ctrl
			(
				.en(inject_en),
				.pck_size_in(pck_size_in),
				.clk(clk),
				.reset(reset),
				.freez(buffer_full),
				.inject(pck_wr),
				.ratio(ratio)
			);
    
      
    
		output_vc_status #(
				.CRDTw(CRDTw),
				.V  (V),
				.B  (PORT_B)				
			)
			nic_ovc_status
			(
				.credit_init_val_in         ( chan_in.ctrl_chanel.credit_init_val),
				.wr_in                      (ovc_wr_in),   
				.credit_in                  (credit_in),
				.nearly_full_vc             (nearly_full_vc),
				.full_vc                    (full_vc),
				.empty_vc                   (empty_vc),
				.cand_vc                    (cand_vc),
				.cand_wr_vc_en              (cand_wr_vc_en),
				.clk                        (clk),
				.reset                      (reset)
			);
    
       
    
		packet_gen #(
				.P(MAX_P),
				.T1(T1),
				.T2(T2),
				.T3(T3),
				.RAw(RAw),  
				.EAw(EAw),  
				.TOPOLOGY(TOPOLOGY),
				.DSTPw(DSTPw),
				.ROUTE_NAME(ROUTE_NAME),
				.ROUTE_TYPE(ROUTE_TYPE),
				.MAX_PCK_NUM(MAX_PCK_NUM),
				.MAX_SIM_CLKs(MAX_SIM_CLKs),
				.TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM),
				.MIN_PCK_SIZE(MIN_PCK_SIZE),
				.MAX_PCK_SIZ(MAX_PCK_SIZ)
			)
			packet_buffer
			(
				.reset(reset),
				.clk(clk),
				.pck_wr(pck_wr),
				.pck_rd(pck_rd),
				.current_r_addr(current_r_addr),
				.current_e_addr(current_e_addr),
				.clk_counter(clk_counter+1'b1),//in case of zero load latency, the flit will be injected in the next clock cycle
				.pck_number(pck_number),
				.dest_e_addr(dest_e_addr_reg),        
				.pck_timestamp(pck_timestamp),
				.buffer_full(buffer_full),
				.pck_ready(pck_ready),
				.valid_dst(valid_dst),
				.destport(destport),
				.pck_size_in(pck_size_in),
				.pck_size_o(pck_size)
			);

    
		assign wr_timestamp    =pck_timestamp; 
    
		assign  update      = flit_in_wr & flit_in[Fw-2];
		assign  hdr_flit    = (flit_counter == 0);
		assign  tail_flit   = (flit_counter ==  pck_size-1'b1);
    
   
    
		assign  time_stamp_h2h  = hdr_flit_timestamp - rd_timestamp;
		assign  time_stamp_h2t  = clk_counter - rd_timestamp;

		wire [FPAYw-1    :   0] flit_out_pyload;
		wire [1         :   0] flit_out_hdr;
    

		wire [FPAYw-1    :   0] flit_out_header_pyload;
		wire [Fw-1      :   0] hdr_flit_out;
   
   
   
   
   
		assign hdr_data_in = (MIN_PCK_SIZE==1)? wr_timestamp[HDR_Dw-1 : 0]  : {HDR_Dw{1'b0}};
    
		header_flit_generator #(
				.DATA_w(HDR_DATA_w)				
			)
			the_header_flit_generator
			(
				.flit_out(hdr_flit_out),
				.vc_num_in(wr_vc),
				.class_in(pck_class_in),
				.dest_e_addr_in(dest_e_addr_reg),
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
                                
			(tail_flit) ?     wr_timestamp:
			{pck_number,flit_counter};
		/* verilator lint_on WIDTH */
    
       
         
		assign flit_out = {flit_out_hdr, wr_vc, flit_out_pyload };   


		//extract header flit info
    
   

		extract_header_flit_info #(
				.DATA_w(HDR_DATA_w)				
			)
			header_extractor
			(
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
   
    
		distance_gen #(
				.TOPOLOGY(TOPOLOGY),
				.T1(T1),
				.T2(T2),
				.T3(T3),
				.EAw(EAw),
				.DISTw(DISTw)
			)
			the_distance_gen
			(
				.src_e_addr(src_e_addr),
				.dest_e_addr(current_e_addr),
				.distance(distance)
			);
    
    
	generate 
	if(MIN_PCK_SIZE == 1) begin : sf_pck    
		assign src_e_addr         = (rd_hdr_flg & rd_tail_flg)? rd_src_e_addr : rsv_pck_src_e_addr[rd_vc_bin];
		assign pck_class_out      = (rd_hdr_flg & rd_tail_flg)? rd_class_hdr : rsv_pck_class_in[rd_vc_bin];
		assign hdr_flit_timestamp = (rd_hdr_flg & rd_tail_flg)?  clk_counter : rsv_time_stamp[rd_vc_bin];
		assign rd_timestamp 	  =	(rd_hdr_flg & rd_tail_flg)? rd_hdr_data_out : flit_in[CLK_CNTw-1             :   0];
		assign pck_size_o         = (rd_hdr_flg & rd_tail_flg)? 1 : rsv_pck_size[rd_vc_bin];
	end else begin : no_sf_pck
		assign pck_size_o = rsv_pck_size[rd_vc_bin];
		assign src_e_addr            = rsv_pck_src_e_addr[rd_vc_bin];
		assign pck_class_out    = rsv_pck_class_in[rd_vc_bin];
		assign hdr_flit_timestamp = rsv_time_stamp[rd_vc_bin];
		assign rd_timestamp=flit_in[CLK_CNTw-1 :   0];        
	end


		if(V==1) begin : v1
		assign rd_vc_bin=1'b0;
	// assign wr_vc_bin=1'b0;
	end else begin :vother  

		one_hot_to_bin #( .ONE_HOT_WIDTH (V)) conv1 
		(
			.one_hot_code   (rd_vc),
			.bin_code       (rd_vc_bin)
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
	
	/* verilator lint_off WIDTH */
	assign  wr_vc_is_full           = (SSA_EN=="NO")?  | ( full_vc & wr_vc)  : | (nearly_full_vc & wr_vc);
    /* verilator lint_on WIDTH */ 
    
    
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

	always @(*)begin
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
 
	always @ (*)begin 
		pck_size_next    = pck_size;
		if((tail_flit & flit_out_wr ) || not_yet_sent_aflit) pck_size_next  = pck_size_in;
	end
    
	`ifdef SYNC_RESET_MODE 
		always @ (posedge clk )begin 
		`else 
			always @ (posedge clk or posedge reset)begin 
			`endif   
			if(reset) begin 
				inject_en       <= 1'b0;
				ps              <= IDEAL;
				wr_vc           <=1; 
				flit_counter    <= {PCK_SIZw{1'b0}};
				credit_out      <= {V{1'd0}};
				rsv_counter     <= 0;
				clk_counter     <=  0;
				//pck_size        <= 0;
				not_yet_sent_aflit<=1'b1;          
        
			end else begin 
				//injection
				not_yet_sent_aflit<=not_yet_sent_aflit_next;
				inject_en <=  (start_injection |inject_en) & ~stop;  
				ps             <= ns;
				clk_counter     <= clk_counter+1'b1;
				wr_vc           <=wr_vc_next; 
				if (flit_cnt_rst)      flit_counter    <= {PCK_SIZw{1'b0}};
				else if(flit_cnt_inc)   flit_counter    <= flit_counter + 1'b1;     
				credit_out      <= credit_out_next;
				//pck_size  <= pck_size_next;
           
				//sink
				if(flit_in_wr) begin 
					if (flit_in[Fw-1])begin //header flit
						rsv_pck_src_e_addr[rd_vc_bin]    <=  rd_src_e_addr;
						rsv_pck_class_in[rd_vc_bin]    <= rd_class_hdr;
						rsv_time_stamp[rd_vc_bin]   <= clk_counter;  
						rsv_counter                 <= rsv_counter+1'b1;
						rsv_pck_size[rd_vc_bin] <=2;                    
						// distance        <= {{(32-8){1'b0}},flit_in[7:0]};
						`ifdef RSV_NOTIFICATION
							// synopsys  translate_off
							// synthesis translate_off
							// last_pck_time<=$time;
							$display ("total of %d pcks have been recived in core (%d)", rsv_counter,current_e_addr);
							// synthesis translate_on
							// synopsys  translate_on
						`endif
					end else begin 
						 rsv_pck_size[rd_vc_bin] <=rsv_pck_size[rd_vc_bin]+1; 
					end
				end
				// synopsys  translate_off
				// synthesis translate_off
				if(report) begin 
					$display ("%t,\t total of %d pcks have been recived in core (%d)",$time ,rsv_counter,current_e_addr);
				end
				// synthesis translate_on
				// synopsys  translate_on
        
         
        
         
        
			end
		end//always
		
		
		// synopsys  translate_off
		// synthesis translate_off			
			
		localparam NEw=log2(NE);
		wire [NEw-1: 0]  src_id,dst_id,current_id;
    
		endp_addr_decoder  #( .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) decod1 ( .id(current_id), .code(current_e_addr));
		endp_addr_decoder  #( .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) decod2 ( .id(dst_id), .code(rd_des_e_addr));
		endp_addr_decoder  #( .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) decod3 ( .id(src_id), .code(rd_src_e_addr));
    
    
    
    
		always @(posedge clk) begin     
			if(flit_out_wr && hdr_flit && dest_e_addr_reg  == current_e_addr && SELF_LOOP_EN == "NO") begin 
				$display("%t: ERROR: The self-loop is not enabled in the router while a packet is injected to the NoC with identical source and destination address in endpoint (%h).: %m",$time, dest_e_addr );
				$finish;
			end
			if(flit_in_wr && rd_hdr_flg && (rd_des_e_addr  != current_e_addr )) begin 
				$display("%t: ERROR: packet with destination %d (code %h) which is sent by source %d (code %h) has been recieved in wrong destination %d (code %h).  %m",$time,dst_id,rd_des_e_addr, src_id,rd_src_e_addr, current_id,current_e_addr);
				$finish;
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
				
		end
		// synthesis translate_on
		// synopsys  translate_on
    
    
		`ifdef CHECK_PCKS_CONTENT
			// synopsys  translate_off
			// synthesis translate_off
    
			wire     [PCK_SIZw-1             :   0] rsv_flit_counter; 
			reg      [PCK_SIZw-1             :   0] old_flit_counter    [V-1   :   0];
			wire     [PCK_CNTw-1             :   0] rsv_pck_number;
			reg      [PCK_CNTw-1             :   0] old_pck_number  [V-1   :   0];
    
			wire [PCK_CNTw+PCK_SIZw-1 : 0] statistics;
			generate 
				if(PCK_CNTw+PCK_SIZw > Fw) assign statistics = {{(PCK_CNTw+PCK_SIZw-Fw){1'b0}},flit_in};
			else  assign statistics = flit_in[PCK_CNTw+PCK_SIZw-1   :   0];
			assign {rsv_pck_number,rsv_flit_counter}=statistics;
               
			endgenerate   
    
    
    
				integer ii;
			`ifdef SYNC_RESET_MODE 
				always @ (posedge clk )begin 
				`else 
					always @ (posedge clk or posedge reset)begin 
					`endif  
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
						if( old_pck_number[rd_vc_bin]!=rsv_pck_number && old_pck_number[rd_vc_bin]!=0)   $display("%t: Error: missmatch pck number in %m. expected %d but recieved %d",$time,old_pck_number[rd_vc_bin],rsv_pck_number);
                       
					end
   
				end
				// synthesis translate_on
				// synopsys  translate_on
    
			`endif
    
//				`ifdef VERILATOR
//					logic  endp_is_active   /*verilator public_flat_rd*/ ;
//			
//					always @ (*) begin 
//						endp_is_active  = 1'b0;		
//						if (chan_out.flit_chanel.flit_wr) endp_is_active=1'b1;
//						if (chan_out.flit_chanel.credit > {V{1'b0}} ) endp_is_active=1'b1;
//						if (chan_out.smart_chanel.requests > {SMART_NUM{1'b0}} ) endp_is_active=1'b1;
//					end	
//				`endif

				
endmodule





/*****************************
    injection_ratio_ctrl
   
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
	
	input                       clk,reset,freez,en;
	output  reg                 inject;
	input   [CNTw-1     :   0]  ratio;
	input  [PCK_SIZw-1          :0] pck_size_in;
	reg    [PCK_SIZw-1          :0]pck_size;
	
	wire    [CNTw-1     :   0]  on_clks, off_clks;
	reg     [STATEw-1   :   0]  state,next_state;
	wire                        input_changed;
	reg     [CNTw-1     :   0]  ratio_old;    
	
	always @(posedge clk ) ratio_old<=ratio;
	
	assign input_changed = (ratio_old!=ratio);
	
	
	assign on_clks = ratio; 
	assign off_clks =MAX_RATIO-ratio; 
	
	reg [PCK_SIZw-1 :0] flit_counter,next_flit_counter;
	
	
	reg sent,next_sent,next_inject;
	
	
	
	always @(*) begin 
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
	
	
	
	
	`ifdef SYNC_RESET_MODE 
		always @ (posedge clk )begin 
		`else 
			always @ (posedge clk or posedge reset)begin 
			`endif  
			if( reset) begin            
				state       <=  STATE_INIT;
				inject      <=  1'b0; 
				sent        <=  1'b1; 
				flit_counter<= 0;
				pck_size<=2;
			end else begin 
				if(input_changed)begin
					state       <=  STATE_INIT;
					inject      <=  1'b0; 
					sent        <=  1'b1; 
					flit_counter<= 0;
				end
	
				if(flit_counter=={PCK_SIZw{1'b0}}) pck_size<=pck_size_in;
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
	parameter T1= 4,    
	parameter T2= 4,
	parameter T3= 4,
	parameter RAw = 3,  
	parameter EAw = 3, 
	parameter TOPOLOGY  = "MESH",
	parameter DSTPw = 4,
	parameter ROUTE_NAME = "XY",
	parameter ROUTE_TYPE = "DETERMINISTIC",
	parameter MAX_PCK_NUM   = 10000,
	parameter MAX_SIM_CLKs  = 100000,
	parameter TIMSTMP_FIFO_NUM=16,
	parameter MIN_PCK_SIZE=2,
	parameter MAX_PCK_SIZ=100

)(
	clk_counter,
	pck_wr,
	pck_rd,
	current_r_addr,
	current_e_addr,
	pck_number,
	dest_e_addr,
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

 
	function integer log2;
	input integer number; begin   
		log2=(number <=1) ? 1: 0;    
		while(2**log2<number) begin    
			log2=log2+1;    
		end       
	end   
	endfunction // log2 
     
	localparam 
	PCK_CNTw    =   log2(MAX_PCK_NUM+1),
	CLK_CNTw    =   log2(MAX_SIM_CLKs+1),
	PCK_SIZw    =   log2(MAX_PCK_SIZ);
 
	input  reset,clk, pck_wr, pck_rd;
	input  [RAw-1  :0] current_r_addr;
	input  [EAw-1 : 0] current_e_addr;
	input  [CLK_CNTw-1 :0] clk_counter;	
	input  [PCK_SIZw-1 :0] pck_size_in;
	input  [EAw-1  :0] dest_e_addr;
	input  valid_dst; 
	
	output [PCK_CNTw-1 :0] pck_number;
	output [CLK_CNTw-1 :0] pck_timestamp;  
	output [PCK_SIZw-1 :0] pck_size_o;
	output buffer_full,pck_ready;
	
	output [DSTPw-1    :0] destport; 
	reg    [PCK_CNTw-1 :0] packet_counter;  
	wire   buffer_empty; 
	
	assign pck_ready = ~buffer_empty & valid_dst;
    
  
	conventional_routing #(
		.TOPOLOGY(TOPOLOGY),
		.ROUTE_NAME(ROUTE_NAME),
		.ROUTE_TYPE(ROUTE_TYPE),
		.T1(T1),
		.T2(T2),
		.T3(T3),
		.RAw(RAw),
		.EAw(EAw),
		.DSTPw(DSTPw),
		.LOCATED_IN_NI(1)
	)
	routing_module
	(
		.reset(reset),
		.clk(clk),
		.current_r_addr(current_r_addr),
		.dest_e_addr(dest_e_addr),
		.src_e_addr(current_e_addr),
		.destport(destport)
	);

	wire timestamp_fifo_nearly_full , timestamp_fifo_full;
	assign buffer_full = (MIN_PCK_SIZE==1) ? timestamp_fifo_nearly_full : timestamp_fifo_full;
	
	
	wire recieve_more_than_0;
	fwft_fifo_bram #(
		.DATA_WIDTH(CLK_CNTw+PCK_SIZw),
		.MAX_DEPTH(TIMSTMP_FIFO_NUM)        
	)
	timestamp_fifo
	(
		.din({pck_size_in,clk_counter}),
		.wr_en(pck_wr),
		.rd_en(pck_rd),
		.dout({pck_size_o,pck_timestamp}),
		.full(timestamp_fifo_full),
		.nearly_full(timestamp_fifo_nearly_full),       
		.recieve_more_than_0(recieve_more_than_0),
		.recieve_more_than_1(),
		.reset(reset),
		.clk(clk)
	);
	
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
    
	`ifdef SYNC_RESET_MODE 
		always @ (posedge clk )begin 
		`else 
			always @ (posedge clk or posedge reset)begin 
			`endif   
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
	parameter TOPOLOGY  = "MESH",
	parameter T1=4,
	parameter T2=4,
	parameter T3=4,
	parameter EAw=2,
	parameter DISTw=4

)(
	src_e_addr,
	dest_e_addr,
	distance
);

	input [EAw-1 : 0] src_e_addr;
	input [EAw-1 : 0] dest_e_addr;
	output [DISTw-1 : 0]   distance;
	
	generate 
	/* verilator lint_off WIDTH */ 
	if (TOPOLOGY ==    "MESH" || TOPOLOGY ==  "TORUS" || TOPOLOGY == "RING" || TOPOLOGY == "LINE")begin : tori_noc 
	/* verilator lint_on WIDTH */ 
	
		mesh_torus_distance_gen #(
			.T1(T1),
			.T2(T2),
			.T3(T3),
			.TOPOLOGY(TOPOLOGY),
			.DISTw(DISTw),
			.EAw(EAw)
		)
		distance_gen
		(
			.src_e_addr(src_e_addr),
			.dest_e_addr(dest_e_addr),
			.distance(distance)
		);
	/* verilator lint_off WIDTH */ 
	end else if (TOPOLOGY ==    "FMESH") begin :fmesh
	/* verilator lint_on WIDTH */ 
		fmesh_distance_gen #(
			.T1(T1),
			.T2(T2),
			.T3(T3),			
			.DISTw(DISTw),
			.EAw(EAw)
		)
		distance_gen
		(
			.src_e_addr(src_e_addr),
			.dest_e_addr(dest_e_addr),
			.distance(distance)
		);
			
	/* verilator lint_off WIDTH */ 
	end else if (TOPOLOGY == "FATTREE" || TOPOLOGY == "TREE") begin : fat 
	/* verilator lint_on WIDTH */    
		fattree_distance_gen #(
			.K(T1),
			.L(T2)
		)
		distance_gen
		(
			.src_addr_encoded(src_e_addr),
			.dest_addr_encoded(dest_e_addr),
			.distance(distance)
		);
	end else if (TOPOLOGY == "STAR") begin 
    
				assign distance =1 ;
	end
	endgenerate

endmodule		




		
