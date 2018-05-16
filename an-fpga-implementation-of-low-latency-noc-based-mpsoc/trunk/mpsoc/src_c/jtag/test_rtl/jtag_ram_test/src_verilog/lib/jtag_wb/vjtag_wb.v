module vjtag_wb #(
	parameter VJTAG_INDEX=126,
	parameter DW=32,
	parameter AW=32,
	parameter SW=32,
	
	//wishbone port parameters
    parameter S_Aw          =   7,
    parameter M_Aw          =   32,
    parameter TAGw          =   3,
    parameter SELw          =   4
	

)(
	clk,
	reset,
	status_i,
	
	 //wishbone master interface signals
	m_sel_o,
	m_dat_o,
	m_addr_o,
	m_cti_o,
	m_stb_o,
	m_cyc_o,
	m_we_o,
	m_dat_i,
	m_ack_i  
	
);

	//IO declaration
	input reset,clk;
	input [SW-1	:	0]	status_i;
	
	//wishbone master interface signals
	output  [SELw-1          :   0] m_sel_o;
	output  [DW-1            :   0] m_dat_o;
	output  [M_Aw-1          :   0] m_addr_o;
	output  [TAGw-1          :   0] m_cti_o;
	output                          m_stb_o;
	output                          m_cyc_o;
	output                          m_we_o;
	input   [DW-1           :  0]   m_dat_i;
	input                           m_ack_i;    
   
	
	localparam STATE_NUM=3,
				  IDEAL =1,
				  WB_WR_DATA=2,
				  WB_RD_DATA=4;
	
	reg [STATE_NUM-1	:	0] ps,ns;
	
	wire [DW-1	:0] data_out,  data_in;
	wire  wb_wr_addr_en,  wb_wr_data_en, 	wb_rd_data_en;
	reg wr_mem_en,  rd_mem_en,  wb_cap_rd;
	
	reg [AW-1	:	0]	wb_addr,wb_addr_next;
	reg [DW-1	:	0]	wb_wr_data,wb_rd_data;
	reg wb_addr_inc;
	
	
	assign  m_cti_o         =    3'b000;
	assign  m_sel_o         =   4'b1111;
	assign  m_cyc_o 			=	m_stb_o;
	assign  m_stb_o			= wr_mem_en |  rd_mem_en;
	assign  m_we_o				= wr_mem_en;
	assign  m_dat_o			= wb_wr_data;
	assign  m_addr_o			= wb_addr;
	assign	data_in				= wb_rd_data;
//vjtag	vjtag signals declaration
	

localparam VJ_DW= (DW > AW)? DW : AW;	
	
	
	vjtag_ctrl #(
		.DW(VJ_DW),
		.VJTAG_INDEX(VJTAG_INDEX),
		.STW(SW)
	)
	vjtag_ctrl_inst
	(
		.clk(clk),
		.reset(reset),
		.data_out(data_out),
		.data_in(data_in),
		.wb_wr_addr_en(wb_wr_addr_en),
		.wb_wr_data_en(wb_wr_data_en),
		.wb_rd_data_en(wb_rd_data_en),
		.status_i(status_i)
	);
	
	
	
	always @(posedge clk or posedge reset) begin 
		if(reset) begin 
			wb_addr <= {AW{1'b0}};
			wb_wr_data  <= {DW{1'b0}};	
			ps <= IDEAL;
		end else begin
			wb_addr <= wb_addr_next;
			ps <= ns;
			if(wb_wr_data_en) wb_wr_data  <= data_out;	
			if(wb_cap_rd) wb_rd_data <= m_dat_i;
		end
	end
	
	
	always @(*)begin 
		wb_addr_next= wb_addr;
		if(wb_wr_addr_en) wb_addr_next = data_out [AW-1	:	0];
		else if (wb_addr_inc)  wb_addr_next = wb_addr +1'b1;	
	end
	
	
	
	always @(*)begin 
		ns=ps;
		wr_mem_en =1'b0;
		rd_mem_en =1'b0;
		wb_addr_inc=1'b0;
		wb_cap_rd=1'b0;
		case(ps)
		IDEAL : begin 
			if(wb_wr_data_en) ns= WB_WR_DATA;	
			if(wb_rd_data_en) ns= WB_RD_DATA;	
		end 
		WB_WR_DATA: begin 
			wr_mem_en =1'b1;
			if(m_ack_i) begin 
				ns=IDEAL;
				wb_addr_inc=1'b1;			
			end
		end	
		WB_RD_DATA: begin 
			rd_mem_en =1'b1;
			if(m_ack_i) begin 
				wb_cap_rd=1'b1;
				ns=IDEAL;
				//wb_addr_inc=1'b1;			
			end		
		end		
		endcase	
	end	
	
	//assign led={wb_addr[7:0], wb_wr_data[7:0]};

endmodule




module vjtag_ctrl #(
	parameter DW=32,
	parameter STW=2, // status width <= DW
	parameter VJTAG_INDEX=126

)(
	clk,
	reset,
	data_out,
	data_in,
	status_i,
	wb_wr_addr_en,
	wb_wr_data_en,
	wb_rd_data_en
);

//IO declaration
	input reset,clk;
	output [DW-1	:0] data_out;
	input [DW-1	:0] data_in;
	input [STW-1	:0] status_i;
	output wb_wr_addr_en, wb_wr_data_en, 	wb_rd_data_en;
	
	
//vjtag	vjtag signals declaration
	wire	[2:0]  ir_out ,  ir_in;
	wire	  tdo, tck,	  tdi;	
	wire	  cdr ,cir,e1dr,e2dr,pdr,sdr,udr,uir;
	
	
	vjtag	#(
	 .VJTAG_INDEX(VJTAG_INDEX)
	)
	vjtag_inst (
	.ir_out ( ir_out ),
	.tdo ( tdo ),
	.ir_in ( ir_in ),
	.tck ( tck ),
	.tdi ( tdi ),
	.virtual_state_cdr 	( cdr ),
	.virtual_state_cir 	( cir ),
	.virtual_state_e1dr 	( e1dr ),
	.virtual_state_e2dr 	( e2dr ),
	.virtual_state_pdr 	( pdr ),
	.virtual_state_sdr 	( sdr ),
	.virtual_state_udr 	( udr ),
	.virtual_state_uir 	( uir )
	);

	
	// IR states
	localparam [2:0] 			  UPDATE_WB_ADDR  = 3'b111,
						  UPDATE_WB_WR_DATA  = 3'b110,
						  UPDATE_WB_RD_DATA  = 3'b101,
						  RD_STATUS	     =3'b100,
						  BYPASS = 3'b000;
	
	
	// internal registers 
	reg [2:0] ir;
	reg bypass_reg;
	reg [DW-1	:	0] shift_buffer,shift_buffer_next;
	reg cdr_delayed,sdr_delayed;
	
	
	
	/*	
	always @(negedge tck)
	begin
		//  Delay the CDR signal by one half clock cycle 
		cdr_delayed = cdr;
		sdr_delayed = sdr;
	end
	*/
	
	assign ir_out = ir_in;	// Just pass the IR out
	assign tdo = (ir == BYPASS) ? bypass_reg : shift_buffer[0];
	assign data_out = shift_buffer;
	
	
	
	
	always @(posedge tck or posedge reset)
	begin
		if (reset)begin 
			ir <= 3'b000;
			bypass_reg<=1'b0;
			shift_buffer<={DW{1'b0}};
			
		end else begin 
			if( uir ) ir <= ir_in; // Capture the instruction provided
			bypass_reg <= tdi;
			shift_buffer<=shift_buffer_next;
			
		end
	end
	

	
	always @ (*)begin 
		shift_buffer_next=shift_buffer;
		
		if( sdr ) shift_buffer_next={tdi,shift_buffer[DW-1:1]};// shift buffer
		case(ir)
			RD_STATUS:begin
				if( cdr ) shift_buffer_next[STW-1	:	0] = status_i;
			end
			default: begin 
				if( cdr ) shift_buffer_next = data_in;
			end
		endcase		
	end
	
	
	
	reg wb_wr_addr1, 	wb_wr_data1, 	wb_rd_data1;
	//always @(posedge tck or posedge reset)
	always @(*)
	begin
		//if( reset )	begin
		//	wb_wr_addr1<=1'b0;
		//	wb_wr_data1<=1'b0;
		//end else begin
			wb_wr_addr1=(ir== UPDATE_WB_ADDR || ir== UPDATE_WB_RD_DATA) &  udr;
			wb_wr_data1=(ir== UPDATE_WB_WR_DATA &&  udr ); 	
			wb_rd_data1=(ir==UPDATE_WB_RD_DATA && cdr);
		//end	
	end
	
	reg wb_wr_addr2, 	wb_wr_data2, 	wb_rd_data2;
	reg wb_wr_addr3, 	wb_wr_data3, 	wb_rd_data3;
	
	always @(posedge clk or posedge reset)
	begin
		if( reset )	begin
			wb_wr_addr2<=1'b0;
			wb_wr_data2<=1'b0;
			wb_wr_addr3<=1'b0;
			wb_wr_data3<=1'b0;
			wb_rd_data2<=1'b0;
			wb_rd_data3<=1'b0;
		end else begin
			wb_wr_addr2<=wb_wr_addr1;
			wb_wr_data2<=wb_wr_data1; 	
			wb_wr_addr3<=wb_wr_addr2;
			wb_wr_data3<=wb_wr_data2; 	
			wb_rd_data2<=wb_rd_data1;
			wb_rd_data3<=wb_rd_data2;
		end	
	end

	assign wb_wr_addr_en =(wb_wr_addr2 & ~wb_wr_addr3);
	assign wb_wr_data_en =(wb_wr_data2 & ~wb_wr_data3); 	
	assign wb_rd_data_en =(wb_rd_data2 & ~wb_rd_data3);
endmodule














