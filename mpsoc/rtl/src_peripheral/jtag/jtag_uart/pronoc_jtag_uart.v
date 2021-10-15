/**************************************
* Module: pronoc_jtag_uart
* Date:2020-04-11  
* Author: alireza     
*
* Description: 
***************************************/


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on



module  pronoc_jtag_uart #(
    //wb parameter 
    parameter Aw           =   1,
    parameter SELw         =   4,
    parameter TAGw         =   3,
    parameter Dw           =   32,
    //uart parameter    
    parameter BUFF_Aw      =   6,//max is 16
    //uart simulator param 
    parameter SIM_BUFFER_SIZE=100,
    parameter SIM_WAIT_COUNT    =10000,
    //jtag parameter
    parameter JTAG_CONNECT= "XILINX_JTAG_WB",//"ALTERA_JTAG_WB" ,"XILINX_JTAG_WB"  
    parameter JTAG_INDEX= 126,
    parameter JDw = 32,
    parameter JAw=32,
    parameter JINDEXw=8,
    parameter JSTATUSw=8,
    parameter J2WBw = (JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+1+JDw+JAw : 1,
    parameter WB2Jw= (JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+JSTATUSw+JINDEXw+1+JDw  : 1

)(
 //wb
  clk,
  reset,
 // wb_irq,
  wb_dat_o,
  wb_ack_o,
  wb_adr_i,
  wb_stb_i,
  wb_cyc_i,
  wb_we_i,
  wb_dat_i,  
  
  //jtag 
  wb_to_jtag,
  jtag_to_wb,
  
  //rx interface for simulation
  RxD_din_sim,
  RxD_wr_sim,
  RxD_ready_sim 
  
);
    
    //wb
    input            clk;
    input            reset;
  //  output           wb_irq;
    output  [ Dw-1: 0] wb_dat_o;
    output           wb_ack_o;
    input            wb_adr_i;
    input            wb_stb_i;
    input            wb_cyc_i;
    input            wb_we_i;
    input   [ Dw-1: 0] wb_dat_i;
   
  
    //jtag
    output [WB2Jw-1  : 0] wb_to_jtag;
    input  [J2WBw-1 : 0] jtag_to_wb; 
    
    input [7:0 ] RxD_din_sim;
    input RxD_wr_sim;
    output RxD_ready_sim;
    

`ifdef MODEL_TECH 
    `define RUN_SIM
`endif
`ifdef VERILATOR
    `define RUN_SIM
`endif

    
`ifdef  RUN_SIM

    altera_uart_simulator #(
        .BUFFER_SIZE(SIM_BUFFER_SIZE),  
        .WAIT_COUNT(SIM_WAIT_COUNT)    
    )
    Suart
    (
        .reset(reset),
        .clk(clk),
        .s_dat_i(wb_dat_i),
        .s_sel_i(4'b1111),
        .s_addr_i(wb_adr_i),  
        .s_cti_i( ),
        .s_stb_i(wb_stb_i),
        .s_cyc_i(wb_cyc_i),
        .s_we_i(wb_we_i),    
        .s_dat_o(wb_dat_o),
        .s_ack_o(wb_ack_o),
        .RxD_din(RxD_din_sim),
        .RxD_wr(RxD_wr_sim),
        .RxD_ready(RxD_ready_sim)
    );


`else 
    pronoc_jtag_uart_hw #(
    	.Aw(Aw),
    	.SELw(SELw),
    	.TAGw(TAGw),
    	.Dw(Dw),
    	.BUFF_Aw(BUFF_Aw),
    	.JTAG_CONNECT(JTAG_CONNECT),
    	.JTAG_INDEX(JTAG_INDEX),
    	.JDw(JDw),
    	.JAw(JAw),
    	.JINDEXw(JINDEXw),
    	.JSTATUSw(JSTATUSw),
    	.J2WBw(J2WBw),
    	.WB2Jw(WB2Jw)
    )
    uart_hw
    (
    	.clk(clk),
    	.reset(reset),
    	.wb_dat_o(wb_dat_o),
    	.wb_ack_o(wb_ack_o),
    	.wb_adr_i(wb_adr_i),
    	.wb_stb_i(wb_stb_i),
    	.wb_cyc_i(wb_cyc_i),
    	.wb_we_i(wb_we_i),
    	.wb_dat_i(wb_dat_i),
    	.wb_to_jtag(wb_to_jtag),
    	.jtag_to_wb(jtag_to_wb)
    );

`endif


endmodule








module  pronoc_jtag_uart_hw #(
    //wb parameter 
    parameter Aw           =   1,
    parameter SELw         =   4,
    parameter TAGw         =   3,
    parameter Dw           =   32,
    //uart parameter    
    parameter BUFF_Aw      =   6,//max is 16
    //jtag parameter
    parameter JTAG_CONNECT= "XILINX_JTAG_WB",//"ALTERA_JTAG_WB" ,"XILINX_JTAG_WB"  
    parameter JTAG_INDEX= 126,
    parameter JDw = 32,
    parameter JAw=32,
    parameter JINDEXw=8,
    parameter JSTATUSw=8,
    parameter J2WBw = (JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+1+JDw+JAw : 1,
    parameter WB2Jw= (JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+JSTATUSw+JINDEXw+1+JDw  : 1

)(
 //wb
  clk,
  reset,
 // wb_irq,
  wb_dat_o,
  wb_ack_o,
  wb_adr_i,
  wb_stb_i,
  wb_cyc_i,
  wb_we_i,
  wb_dat_i,  
  
  //jtag 
  wb_to_jtag,
  jtag_to_wb
  

);

    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 
    
    
     //wb interface
    localparam 
        DATA_REG = 1'b0,            
        CONTROL_REG  = 1'b1 ,  
        CONTROL_WSPACE_MSK = 32'hFFFF0000,
        DATA_RVALID_MSK = 32'h00008000,
        DATA_DATA_MSK = 32'h000000FF,
        B = 2 ** (BUFF_Aw-1),
        B_1 = B-1,
        Bw = log2(B),
        DEPTHw=log2(B+1);
       
        
    localparam  [Bw-1   :   0] Bint =   B_1[Bw-1    :   0];
    
    //wb
    input            clk;
    input            reset;
  //  output           wb_irq;
    output  reg[ Dw-1: 0] wb_dat_o;
    output    reg       wb_ack_o;
    input            wb_adr_i;
    input            wb_stb_i;
    input            wb_cyc_i;
    input            wb_we_i;
    input   [ Dw-1: 0] wb_dat_i;
   
  
    //jtag
    output [WB2Jw-1  : 0] wb_to_jtag;
    input  [J2WBw-1 : 0] jtag_to_wb; 

     //control reg 
    wire [31 : 0] ctrl_reg;
    reg  [15 : 0] wspace;    // The number of spaces available in the write FIFO.
    reg  [15 : 0] jtag_wspace;    // The number of spaces available in the jtag write FIFO.
     
    assign ctrl_reg [31 :16] = wspace;

    wire [7:0]  w2j_fifo_dat_i,j2w_fifo_dat_o,j2w_fifo_dat_i,w2j_fifo_dat_o;
   
      
    //wb_wr_jtag_rd
 
    reg w2j_fifo_wr_en,w2j_fifo_rd_en;
    wire w2j_fifo_full, w2j_fifo_nearly_full, w2j_fifo_empty;
    
    //jtag_wr_wb_rd
   
    reg j2w_fifo_wr_en,j2w_fifo_rd_en;
    wire j2w_fifo_full, j2w_fifo_nearly_full, j2w_fifo_empty;

    
   
    
    
    wire [JSTATUSw-1 : 0] jtag_status_o;
    wire [JINDEXw-1 : 0] jtag_index_o;
    wire jtag_stb_i,jtag_we_i;
    wire [JDw-1 : 0] jtag_dat_i;
    wire [JDw-1 : 0] jtag_dat_o;
    wire [JAw-1 : 0] jtag_addr_i;    
    reg jtag_ack_o; 
    reg wb_rdat_valid;
 
   
    reg wb_ack_o_next,jtag_ack_o_next;

    localparam 
        IDEAL=2'b01,
        WAIT =2'b10,
        ST_NUM=2;
        
    reg [ST_NUM-1:0] ps,ns;    

    always @ (*) begin
        wb_ack_o_next =1'b0;
        w2j_fifo_wr_en =1'b0;
        j2w_fifo_rd_en=1'b0;
        wb_dat_o[7:0]=j2w_fifo_dat_o;
        wb_dat_o[15] = wb_rdat_valid;
        wb_dat_o[14:8] = ctrl_reg[14:8];
        wb_dat_o[31:16] = ctrl_reg[31:16];
        ns=ps;
        case(ps)
        IDEAL :begin 
             
            if(wb_stb_i & wb_we_i ) begin             
                    case(wb_adr_i)
                    DATA_REG:begin
                        if(~w2j_fifo_full)begin 
                            w2j_fifo_wr_en=1'b1;
                            wb_ack_o_next =1'b1;
                            ns =WAIT;
                        end             
                    end
                    CONTROL_REG:begin                
                        // set the bits of control reg. //TODO add intrrupt control registers
                        wb_ack_o_next =1'b1;
                        ns =WAIT;
                    end
                    endcase
            end //sa_stb_i && sa_we_i
            if(wb_stb_i & ~wb_we_i ) begin 
                    case(wb_adr_i)
                    DATA_REG:begin
                        wb_dat_o[7:0]=j2w_fifo_dat_o;
                        wb_dat_o[15] = wb_rdat_valid;
                        wb_ack_o_next =1'b1;
                        ns =WAIT;
                        if(~j2w_fifo_empty)begin
                            j2w_fifo_rd_en=1'b1;                                            
                        end                
                    end
                    CONTROL_REG:begin                
                        // read control reg
                         wb_dat_o = ctrl_reg;
                         wb_ack_o_next =1'b1;
                         ns =WAIT;
                    end
                    endcase
            end
    end//IDEAL
    WAIT:begin // wait until stb deasserted
         if(~wb_stb_i) ns =IDEAL; 
         // wb_ack_o_next =1'b1;
    end
    endcase
        
    end//always
    
    reg j2w_fifo_wr_en_next;
  
    reg stb1,stb2;
    wire jtag_stb_valid = stb1 & ~stb2;// fix jtag clock diffrence
  
    always @(*) begin
        j2w_fifo_wr_en_next=1'b0;
        jtag_ack_o_next =1'b0;
        w2j_fifo_rd_en=1'b0;
        if(jtag_stb_valid) begin 
             w2j_fifo_rd_en=1'b1;
             jtag_ack_o_next =1'b1;       
             if( ~j2w_fifo_full && j2w_fifo_dat_i[7:0]!=0) j2w_fifo_wr_en_next=1'b1;//make one cycle delay for wr enable
        end 
	
    end
    
   
   
`ifdef SYNC_RESET_MODE 
    always @ (posedge clk )begin 
`else 
    always @ (posedge clk or posedge reset)begin 
`endif  
        if (reset) begin 
            wb_ack_o<=1'b0;
            jtag_ack_o<=1'b0;
            j2w_fifo_wr_en<=1'b0;
            stb1<=1'b0;
            stb2<=1'b0;
            ps<=IDEAL;
            wb_rdat_valid<=1'b0;
          
        end else begin
            wb_ack_o<= wb_ack_o_next;
            jtag_ack_o<=jtag_ack_o_next;
            j2w_fifo_wr_en<=j2w_fifo_wr_en_next;
            stb1<=jtag_stb_i;
            stb2<=stb1;   
            ps<=ns;
          
            
            if(~j2w_fifo_empty) wb_rdat_valid<=1'b1;
            else if(wb_ack_o ) wb_rdat_valid<=1'b0;           
            
        end
    end
    
    
    assign jtag_dat_o[23 : 0] = {jtag_wspace,w2j_fifo_dat_o};
    assign w2j_fifo_dat_i = wb_dat_i [7:0];  
    assign jtag_status_o=0;
    assign jtag_index_o = JTAG_INDEX; 
    assign j2w_fifo_dat_i = jtag_dat_i[7:0]; 
   
   

    wire  [BUFF_Aw -1      :   0] w2j_fifo_depth, j2w_fifo_depth;
    wire  [BUFF_Aw -1      :   0] remain = B- w2j_fifo_depth; 
    wire  [BUFF_Aw -1      :   0] jtag_remain = B- j2w_fifo_depth; 
    always @(*)begin 
        wspace = 16'd0;
        jtag_wspace=16'd0;
        wspace[BUFF_Aw-1 : 0] = remain;
        jtag_wspace[BUFF_Aw-1 : 0] = jtag_remain;
    end    
    
    
    
    
    uart_fifo #(
    	.Dw(8),
    	.B(B)
    )
    wb_to_jtag_fifo
    (
    	.din(w2j_fifo_dat_i),
    	.wr_en(w2j_fifo_wr_en),
    	.rd_en(w2j_fifo_rd_en),
    	.dout(w2j_fifo_dat_o),
    	.full(w2j_fifo_full),
    	.nearly_full(w2j_fifo_nearly_full),
    	.empty(w2j_fifo_empty),
    	.depth(w2j_fifo_depth),
    	.reset(reset),
    	.clk(clk)
    );
    
    
    uart_fifo #(
        .Dw(8),
        .B(B)
    )
    jtag_to_wb_fifo
    (
        .din(j2w_fifo_dat_i),
        .wr_en(j2w_fifo_wr_en),
        .rd_en(j2w_fifo_rd_en),
        .dout(j2w_fifo_dat_o),
        .full(j2w_fifo_full),
        .nearly_full(j2w_fifo_nearly_full),
        .depth(j2w_fifo_depth),
        .empty(j2w_fifo_empty),
        .reset(reset),
        .clk(clk)
    );
    
   
   
   generate  
   if(JTAG_CONNECT == "XILINX_JTAG_WB")begin: xilinx_jwb 
        assign wb_to_jtag = {jtag_status_o,jtag_ack_o,jtag_dat_o,jtag_index_o,clk};
        assign {jtag_addr_i,jtag_stb_i,jtag_we_i,jtag_dat_i} = jtag_to_wb;
   end else  if(JTAG_CONNECT == "ALTERA_JTAG_WB")begin: altera_jwb 
   
        vjtag_wb #(
            .VJTAG_INDEX(JTAG_INDEX),
            .DW(JDw),
            .AW(JAw),
            .SW(JSTATUSw),
        
            //wishbone port parameters
            .M_Aw(Aw),
            .TAGw(TAGw)
        )
        vjtag_inst
        (
            .clk(clk),
            .reset(reset),  
            .status_i(jtag_status_o), 
             //wishbone master interface signals
            .m_sel_o(),
            .m_dat_o(jtag_dat_i),
            .m_addr_o(jtag_addr_i),
            .m_cti_o(),
            .m_stb_o(jtag_stb_i),
            .m_cyc_o(),
            .m_we_o(jtag_we_i),
            .m_dat_i(jtag_dat_o),
            .m_ack_i(jtag_ack_o)     
        
        );
   
   
        assign wb_to_jtag[0] = clk;
   end
   endgenerate 
    
   
  
   


endmodule







//If rd_en is asserted while fifo is empty, the dout will be zero. In this condition the rd pointer and fifo depth do not change 
module uart_fifo  #( 
    parameter Dw = 72,//data_width
    parameter B  = 10// buffer num
)(
    din,   
    wr_en, 
    rd_en, 
    dout,  
    depth,
    full,
    nearly_full,
    empty,
    reset,
    clk
);

 
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 

    localparam  B_1 = B-1,
                Bw = log2(B),
                DEPTHw=log2(B+1);
    localparam  [Bw-1   :   0] Bint =   B_1[Bw-1    :   0];

    input [Dw-1:0] din;     // Data in
    input          wr_en;   // Write enable
    input          rd_en;   // Read the next word

    output reg [Dw-1:0]  dout;    // Data out
    output         full;
    output         nearly_full;
    output         empty;

    input          reset;
    input          clk;



reg [Dw-1       :   0] queue [B-1 : 0] /* synthesis ramstyle = "no_rw_check" */;
reg [Bw- 1      :   0] rd_ptr;
reg [Bw- 1      :   0] wr_ptr;
output reg [DEPTHw-1   :   0] depth;

wire rd_valid = rd_en & ~empty;

// Sample the data
always @(posedge clk)
begin
   if (wr_en)
      queue[wr_ptr] <= din;
   if (rd_en)
      dout <= (empty)? {Dw{1'b0}} :   queue[rd_ptr];
end

always @(posedge clk)
begin
   if (reset) begin
      rd_ptr <= {Bw{1'b0}};
      wr_ptr <= {Bw{1'b0}};
      depth  <= {DEPTHw{1'b0}};
   end
   else begin
      if (wr_en) wr_ptr <= (wr_ptr==Bint)? {Bw{1'b0}} : wr_ptr + 1'b1;
      if (rd_valid) rd_ptr <= (rd_ptr==Bint)? {Bw{1'b0}} : rd_ptr + 1'b1;
      if (wr_en & ~rd_valid) depth <=
//synthesis translate_off
//synopsys  translate_off
                   #1
//synopsys  translate_on
//synthesis translate_on  
                   depth + 1'b1;
      else if (~wr_en & rd_valid) depth <=
//synthesis translate_off
//synopsys  translate_off
                   #1
//synopsys  translate_on
//synthesis translate_on  
                   depth - 1'b1;
   end
end

//assign dout = queue[rd_ptr];
assign full = depth == B;
assign nearly_full = depth >= B-1;
assign empty = depth == {DEPTHw{1'b0}};

//synthesis translate_off
//synopsys  translate_off
always @(posedge clk)
begin
    if(~reset)begin
       if (wr_en && depth == B && !rd_valid)
          $display(" %t: ERROR: Attempt to write to full FIFO: %m",$time);
       if (rd_valid && depth == {DEPTHw{1'b0}})
          $display("%t: ERROR: Attempt to read an empty FIFO: %m",$time);
    end//~reset
end


  
    integer i;
    initial begin 
       for (i=0; i<B;i=i+1 ) queue[i] ="*";
    end

 


//synopsys  translate_on
//synthesis translate_on

endmodule // fifo



