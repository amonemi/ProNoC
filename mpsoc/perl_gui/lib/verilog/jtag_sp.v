/**************************************
* Module: jtag
* Date:2015-09-20  
* Author: alireza     
*
* Description: jtag interface for communicating with the host pc. 
***************************************/

module jtag_top (
	output [8:0]LEDR,
	output [0:0]LEDG,
	input  [0:0]KEY,
	input  CLOCK_50
	); 
	wire reset;
	wire clk;
	assign	reset	=	~KEY[0];
	
	assign  LEDG[0]		=	reset;
	assign  clk				=	CLOCK_50;
	
	
	







	jtag (

    //wishbone slave interface signals
    .s_dat_i(),
    .s_sel_i(),
    .s_addr_i(),  
    .s_tag_i(),
    .s_stb_i(),
    .s_cyc_i(),
    .s_we_i(),    
    .s_dat_o(),
    .s_ack_o(),
    .s_err_o(),
    .s_rty_o(),


   
    //wishbone master interface signals
    .m_sel_o(),
    .m_dat_o(),
    .m_addr_o(),
    .m_tag_o(),
    .m_stb_o(),
    .m_cyc_o(),
    .m_we_o(),
    .m_dat_i(),
    .m_ack_i(),    
    .m_err_i(),
    .m_rty_i(),
    
    //intruupt interface
    .irq(),
	 .led(LEDR[0]),

    .reset(reset),
	 .clk(clk)


);










endmodule





module  jtag #(
    parameter NI_BASE_ADDR     = 32'h0,
    parameter BASE_ADDR        = 32'h100,
    parameter WR_RAM_TAG       ="J0",
    parameter RD_RAM_TAG       ="J1",
    parameter WR_RAMw          =8,
      //wishbone port parameters
    parameter RAM_WIDTH_IN_WORD     =   13,
    parameter Dw            =   32,
    parameter S_Aw          =   3,
    parameter M_Aw          =   RAM_WIDTH_IN_WORD,
    parameter TAGw          =   3,
    parameter SELw          =   4

)(

    //wishbone slave interface signals
    s_dat_i,
    s_sel_i,
    s_addr_i,  
    s_tag_i,
    s_stb_i,
    s_cyc_i,
    s_we_i,    
    s_dat_o,
    s_ack_o,
    s_err_o,
    s_rty_o,


   
    //wishbone master interface signals
    m_sel_o,
    m_dat_o,
    m_addr_o,
    m_tag_o,
    m_stb_o,
    m_cyc_o,
    m_we_o,
    m_dat_i,
    m_ack_i,    
    m_err_i,
    m_rty_i,
    
    //intruupt interface
    irq,

    reset,clk,led


);



          
            



//wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [SELw-1     :   0]      s_sel_i;
    input   [S_Aw-1     :   0]      s_addr_i;  
    input   [TAGw-1     :   0]      s_tag_i;
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;
    
    output      [Dw-1       :   0]  s_dat_o;
    output  reg                     s_ack_o;
    output                          s_err_o;
    output                          s_rty_o;
    
    
    //wishbone master interface signals
    output  [SELw-1          :   0] m_sel_o;
    output  [Dw-1            :   0] m_dat_o;
    output  [M_Aw-1          :   0] m_addr_o;
    output  [TAGw-1          :   0] m_tag_o;
    output                          m_stb_o;
    output                          m_cyc_o;
    output                          m_we_o;
    input   [Dw-1           :  0]   m_dat_i;
    input                           m_ack_i;    
    input                           m_err_i;
    input                           m_rty_i;
    //intrrupt interface
    output                          irq;
    
    input                           clk,reset;
	 output reg 							led;


	 assign  irq=sent_start;


    localparam  WR_RAM_ID = {"ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=",WR_RAM_TAG};
	 
    parameter NI_PTR_WIDTH	 =	  19,
				  PTR_WIDTH     =   NI_PTR_WIDTH-2;

				  
				 
    

	prog_ram_single_port #(
 		.Aw(WR_RAMw),
		.Dw(Dw),
		.FPGA_FAMILY("ALTERA"),
		.RAM_TAG_STRING(WR_RAM_TAG),
		.SELw(4),
		.TAGw(3)
	) pc_write_ram
 	(
		.clk			(clk),
		.reset		(reset),
		.sa_ack_o	(s_ack_o),
		.sa_addr_i	(s_addr_i),
		.sa_cyc_i	(s_cyc_i),
		.sa_dat_i	(32'd0),
		.sa_dat_o	(s_dat_o),
		.sa_err_o	(s_err_o),
		.sa_rty_o	(s_rty_o),
		.sa_sel_i	(s_sel_i),
		.sa_stb_i	(s_stb_i),
		.sa_tag_i	(s_tag_i),
		.sa_we_i		(1'b0)
	);			  
				  
		
   
   
   wire busy,start_source;
   wire [WR_RAMw-1        :   0] wr_pck_size;
   reg sent_start,start_source_delayed;
    jtag_sp #(
        .Pw(1),
        .Sw(1+WR_RAMw)
    
    )
    source_probe
    (  
        .probe(busy),
        .source({start_source,wr_pck_size})

    );
   
   
   always @(posedge clk or posedge reset)begin
    if(reset)begin 
         sent_start<=1'b0;
         start_source_delayed<=1'b0;
			led<=1'b0;
    end
    else begin
        start_source_delayed    <=start_source;
        sent_start<= (start_source_delayed & ~start_source);  // sent_start is asserted at negedge of sent_start       
		  if(sent_start) led<=1'b1;
	 end    
   end
   
   parameter ST_NUM		=4,
				 IDEAL		=1,
				 WRITE_NI	=2,
				 WAIT_1		=4,
				 WAIT_NI_DONE=8;
		
	
	
	reg ps,ns;
	
	localparam NI_RD_ADDR=NI_BASE_ADDR,
				  NI_WR_ADDR=NI_BASE_ADDR+4,
				  NI_ST_ADDR=NI_BASE_ADDR+8;
				  
	localparam   NI_BUSY_LOC=         0;  
					 
					 
	
	always @(*)begin
		ns=ps;
		m_sel_o		=4'b1111;
      m_dat_o		=(wr_pck_size<<NI_PTR_WIDTH);
      m_addr_o		= NI_WR_ADDR;
      m_tag_o		=3'd0;
      m_stb_o		=1'b0;
      m_cyc_o		=1'b0;
      m_we_o		=1'b0;
		case(ps)
		IDEAL: begin 
			if(sent_start) ns= WRITE_NI;
		end
		WRITE_NI: begin
			if(m_ack_i) ns= WAIT_1;
			m_stb_o=1'b1;
			m_cyc_o=1'b1;
			m_we_o=1'b1;
		end
		WAIT_1:
			ns= WAIT_NI_DONE;
		
		end
		WAIT_NI_DONE: begin 
			if(m_ack_i && m_dat_i[NI_BUSY_LOC]) ns=IDEAL;
			m_addr_o	=	NI_ST_ADDR;
			m_stb_o	=1'b1;
			m_cyc_o	=1'b1;
			m_we_o	=1'b0;		
		end	
	end
	
	
	
	
	
	always @(posedge clk or posedge reset)begin 
		if(reset) begin
			ps<= IDEAL;
		
		end else begin 
			ps<=ns;
		
		
		end	
	end
	
   
   
   
   
   

/*
altsyncram  #(
        .operation_mode("SINGLE_PORT"),
        .width_a(Dw),
        .lpm_hint(RAM_MODE),
        .read_during_write_mode_mixed_ports("DONT_CARE"),
        .widthad_a(Bw)// use one M9
    )
    pc_read_ram
    (
        .clock0         (clk),
        .address_a      (ram_addr),
        .wren_a         (wr_en),
        .data_a         (din),
        .q_a            (dout),
        .rden_a         (rd_en),
         
        .wren_b         (    ),       
        .rden_b         (    ),
        .data_b         (    ),
        .address_b      (    ),
        .clock1         (    ),
        .clocken0       (    ),
        .clocken1       (    ),
        .clocken2       (    ),
        .clocken3       (    ),
        .aclr0          (    ),
        .aclr1          (    ),
        .byteena_a      (    ),
        .byteena_b      (    ),
        .addressstall_a (    ),
        .addressstall_b (    ),
        .q_b            (    ),
        .eccstatus      (    )
    );
*/







/*



// memory in/o ports
    wire   [RAM_ADDR_W-1    :   0]  ram_addr;
    wire                            ram_we;
    wire   [Dw-1            :   0]  ram_data_in,ram_data_out;

    reg    [RAM_ADDR_W-1    :   0]  read_ptr,write_ptr;
    reg    [RAM_ADDR_W      :   0]  depth;








    


jtag_fifo_ram  #(
    .JTAG_ID(JTAG_ID),
    .Dw(Dw),//data_width
    .B(256)// M9K
)
the_transfer_ram
(
    .din(din),   
    .wr_en(wr_en), 
    .rd_en(rd_en), 
    .dout(dout),  
    .full(full),
    .nearly_full(),
    .empty(empty),
    .reset(reset),
    .clk(clk)
);
   
   
*/

endmodule



module jtag_sp #(
    parameter Pw=8,
    parameter Sw=8
    
)(
    probe,
    source);

    input   [Pw:0]  probe;
    output  [Sw:0]  source;

    wire [Sw:0] sub_wire0;
    wire [Sw:0] source = sub_wire0[Sw:0];

    altsource_probe altsource_probe_component (
                .probe (probe),
                .source (sub_wire0)
                // synopsys translate_off
                ,
                .clrn (),
                .ena (),
                .ir_in (),
                .ir_out (),
                .jtag_state_cdr (),
                .jtag_state_cir (),
                .jtag_state_e1dr (),
                .jtag_state_sdr (),
                .jtag_state_tlr (),
                .jtag_state_udr (),
                .jtag_state_uir (),
                .raw_tck (),
                .source_clk (),
                .source_ena (),
                .tdi (),
                .tdo (),
                .usr1 ()
                // synopsys translate_on
                );
    defparam
        altsource_probe_component.enable_metastability = "NO",
        altsource_probe_component.instance_id = "JTAG",
        altsource_probe_component.probe_width = Pw,
        altsource_probe_component.sld_auto_instance_index = "NO",
        altsource_probe_component.sld_instance_index = 2,
        altsource_probe_component.source_initial_value = " 0",
        altsource_probe_component.source_width = Sw;


endmodule



module jtag_ram  #(
     parameter JTAG_ID="99",
    parameter Dw = 32,//data_width
    parameter B  = 256// M9K
)(
    din,   
    wr_en, 
    rd_en, 
    dout,  
    full,
    nearly_full,
    empty,
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
    localparam  RAM_MODE = {"ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=",JTAG_ID};

    localparam  B_1 = B-1,
                Bw = log2(B),
                DEPTHw=log2(B+1);
    localparam  [Bw-1   :   0] Bint =   B_1[Bw-1    :   0];

    input [Dw-1:0] din;     // Data in
    input          wr_en;   // Write enable
    input          rd_en;   // Read the next word

    output [Dw-1:0]  dout;    // Data out
    output         full;
    output         nearly_full;
    output         empty;

    input          reset;
    input          clk;


reg [Bw- 1      :   0] rd_ptr;
reg [Bw- 1      :   0] wr_ptr;
reg [DEPTHw-1   :   0] depth;
wire[Bw- 1      :   0] ram_addr;

assign ram_addr = (wr_en)? wr_ptr : rd_ptr;


always @(posedge clk)
begin
   if (reset) begin
      rd_ptr <= {Bw{1'b0}};
      wr_ptr <= {Bw{1'b0}};
      depth  <= {DEPTHw{1'b0}};
   end
   else begin
      if (wr_en) wr_ptr <= (wr_ptr==Bint)? {Bw{1'b0}} : wr_ptr + 1'b1;
      if (rd_en) rd_ptr <= (rd_ptr==Bint)? {Bw{1'b0}} : rd_ptr + 1'b1;
      if (wr_en & ~rd_en) depth <=
                   // synthesis translate_off
                   #1
                   // synthesis translate_on
                   depth + 1'b1;
      else if (~wr_en & rd_en) depth <=
                   // synthesis translate_off
                   #1
                   // synthesis translate_on
                   depth - 1'b1;
   end
end

//assign dout = queue[rd_ptr];
assign full = depth == B;
assign nearly_full = depth >= B-1;
assign empty = depth == {DEPTHw{1'b0}};


// use altera single port ram
    altsyncram  #(
        .operation_mode("SINGLE_PORT"),
        .width_a(Dw),
        .lpm_hint(RAM_MODE),
        .read_during_write_mode_mixed_ports("DONT_CARE"),
        .widthad_a(Bw)// use one M9
    )
    queue
    (
        .clock0         (clk),
        .address_a      (ram_addr),
        .wren_a         (wr_en),
        .data_a         (din),
        .q_a            (dout),
        .rden_a         (rd_en),
         
        .wren_b         (    ),       
        .rden_b         (    ),
        .data_b         (    ),
        .address_b      (    ),
        .clock1         (    ),
        .clocken0       (    ),
        .clocken1       (    ),
        .clocken2       (    ),
        .clocken3       (    ),
        .aclr0          (    ),
        .aclr1          (    ),
        .byteena_a      (    ),
        .byteena_b      (    ),
        .addressstall_a (    ),
        .addressstall_b (    ),
        .q_b            (    ),
        .eccstatus      (    )
    );
   
   


// synthesis translate_off
always @(posedge clk)
begin
   if (wr_en && depth == B && !rd_en)
      $display(" %t: ERROR: Attempt to write to full FIFO: %m",$time);
   if (rd_en && depth == {DEPTHw{1'b0}})
      $display("%t: ERROR: Attempt to read an empty FIFO: %m",$time);
end
// synthesis translate_on

endmodule // fifo

