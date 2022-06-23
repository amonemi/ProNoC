/**************************************
* Module: iport_regster_base
* Date:2020-02-21  
* Author: alireza     
*
* Description: 
***************************************/
`timescale 1ns / 1ps

module  flit_buffer_reg_base #(
    parameter V        =   4,
    parameter B        =   4,   // buffer space :flit per VC 
    parameter Fpay     =   32,
    parameter PCK_TYPE = "MULTI_FLIT",
    parameter DEBUG_EN =   1,
    parameter C=1,
    parameter DSTPw=4,
    parameter SSA_EN="YES" // "YES" , "NO"       
)(
    din,
    vc_num_wr,
    wr_en,
    vc_num_rd,
    rd_en,
    dout, 
    vc_not_empty,
    reset,
    clk,    
    
    //header flit dat
    class_all
    
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
        Cw = (C>1)? log2(C): 1,
        Vw         =   log2(V),
        REGFw      =   2+Fpay,   //Fpay + headr flags
        Fw =2+V+Fpay,
        VFw        =   V * Fw,
        VCw        =   V * Cw,
        VDSTPw     =   V * DSTPw;

    input  [Fw-1      :0]   din;     // Data in    
    input  [V-1       :0]   vc_num_wr;//write vertual chanel   
    input                   wr_en;   // Write enable
    
       
    input  [V-1       :0]   vc_num_rd;//read vertual chanel    
    input                   rd_en;   // Read the next word
    
    
    output [Fw-1       :0]  dout;    // Data out
    output [V-1        :0]  vc_not_empty;
    input                   reset;
    input                   clk;
    
    output [VCw-1 : 0] class_all;
   // output [VDSTPw-1 :0 ] dest_port_encoded_all;
   // input  [V-1        :0]  ssa_rd;

    wire [Fw-1       :0]  dout_all [V-1 : 0];    // Data out
    wire [VCw-1 : 0] class_vc [V-1 : 0];
    reg  [VCw-1 : 0] class_vc_next [V-1 : 0];  
    wire [REGFw-1 : 0] flit_regs [V-1 : 0];   // a register array save the head of each quque
    reg  [REGFw-1 : 0] flit_regs_next [V-1 : 0];
    reg [V-1 : 0] valid,valid_next; // if valid is asseted it shows the VC queue has a flit waiting to be sent 

    wire [Fw-1 : 0] bram_dout;
    wire [V-1 : 0] bram_not_empty;
    wire bram_wr_en;
    wire [V-1 : 0] vc_num_wr_en,vc_num_rd_en;  
    
    wire[REGFw-1 : 0] flit_reg_mux_out;
    wire flit_reg_mux_sel;
    reg flit_reg_mux_sel_delay;
    wire [V-1 : 0] flit_reg_wr_en,pass_din_to_flit_reg,bram_empty;
    wire [V-1 : 0]  bram_out_is_valid; 
    wire bram_rd_en = |(vc_num_rd_en & bram_not_empty);
    
    //header flit info 
    wire [Cw-1:0] class_i;
    wire [DSTPw-1 : 0] destport_i;
    
    wire [Vw-1: 0] vc_num_rd_bin;
    reg [Vw-1 : 0] vc_num_rd_bin_delaied;
    reg [V-1 : 0]  bram_out_is_valid_delaied,pass_din_to_flit_reg_delaied;
    
    reg  [Fw-1      :0]   din_reg;
   
    assign bram_empty = ~bram_not_empty;
    assign vc_num_wr_en = (wr_en)?    vc_num_wr : {V{1'b0}};  
    assign vc_num_rd_en = (rd_en)?    vc_num_rd : {V{1'b0}};   
     
    assign pass_din_to_flit_reg = (vc_num_wr_en & ~valid)| // a write has been recived while the reg_flit is not valid
                            (vc_num_wr_en & valid & bram_empty & vc_num_rd_en); //or its valid but bram is empty and its got a read request
     
     
    assign flit_reg_mux_sel = | pass_din_to_flit_reg ;// 1 :din, 0: bram
    //2-1 mux. Select between the bram and input flit. 
    assign flit_reg_mux_out = (flit_reg_mux_sel_delay)?   {din[Fw-1:Fw-2],din_reg[Fpay-1:0]} : {bram_dout[Fw-1:Fw-2],bram_dout[Fpay-1:0]};
    assign bram_wr_en =  (flit_reg_mux_sel)?  1'b0 :wr_en ; //make sure not write on the Bram if the reg fifo is empty 

    assign  flit_reg_wr_en = pass_din_to_flit_reg | bram_out_is_valid;    

    assign  bram_out_is_valid = (bram_rd_en )? (vc_num_rd &  bram_not_empty): {V{1'b0}};
    
    
   
   
    one_hot_to_bin #(
    	.ONE_HOT_WIDTH(V),
    	.BIN_WIDTH(Vw)
    )
    conv
    (
    	.one_hot_code(vc_num_rd),
    	.bin_code(vc_num_rd_bin)
    );
       
    always @(posedge clk) vc_num_rd_bin_delaied<=vc_num_rd_bin;
    always @(posedge clk) pass_din_to_flit_reg_delaied<=pass_din_to_flit_reg;
    assign  dout = dout_all[vc_num_rd_bin_delaied];
    

    flit_buffer #(
        .B(B),
        .SSA_EN("NO")// should be "NO" even if SSA is enabled
    )
    flit_buffer
    (
        .din(din),
        .vc_num_wr(vc_num_wr),
        .wr_en(bram_wr_en),
        
        .vc_num_rd(vc_num_rd),
        
        .rd_en(bram_rd_en),
        .dout(bram_dout),
        .vc_not_empty(bram_not_empty),
        .reset(reset),
        .clk(clk),
        .ssa_rd({V{1'b0}}),
        .multiple_dest(),
        .sub_rd_ptr_ld(),
        .flit_is_tail()
        
       
    );


    always @(posedge clk) begin
        if(reset)  begin 
		valid<={V{1'b0}};
		bram_out_is_valid_delaied<={V{1'b0}};
	//	din_reg<={Fw{1'b0}};
	end 
        else begin 
	    valid<=valid_next;
		bram_out_is_valid_delaied<=bram_out_is_valid; 
		din_reg<=din;
		flit_reg_mux_sel_delay<=flit_reg_mux_sel;

	end
    end
    assign vc_not_empty = valid;
        
        
     extract_header_flit_info #(
        .DATA_w(0)
     )
     header_extractor
     (
         .flit_in({flit_reg_mux_out[REGFw-1:REGFw-2],flit_reg_wr_en,flit_reg_mux_out[Fpay-1 : 0]}),
         .flit_in_wr(),         
         .class_o(class_i),
         .destport_o(destport_i),
         .dest_e_addr_o( ),
         .src_e_addr_o( ),
         .vc_num_o(),
         .hdr_flit_wr_o(),
         .hdr_flg_o(),
         .tail_flg_o( ),
         .weight_o( ),
         .be_o( ),
         .data_o( )
     );    
        
        
    genvar i;
    generate
    for (i = 0; i < V; i = i + 1) begin : Vblock
       // assign  dout_all[(i+1)*Fw-1 : i*Fw] = {flit_regs [i][REGFw-1: REGFw-2],i[V-1:0] ,flit_regs[i][Fpay-1:0]};
        assign  dout_all[i] = {flit_regs [i][REGFw-1: REGFw-2],i[V-1:0] ,flit_regs[i][Fpay-1:0]};
        assign  class_all[(i+1)*Cw-1 : i*Cw] = class_vc[i];
         
        
      pronoc_register #(
           .W(REGFw)          
      ) reg1 ( 
           .in(flit_regs_next[i]),
           .reset(reset),    
           .clk(clk),      
           .out(flit_regs[i])
      );
      
      
       pronoc_register #(
           .W(Cw)           
      ) reg2 ( 
           .in(class_vc_next[i]),
           .reset(reset),    
           .clk(clk),      
           .out(class_vc[i])
      );
        
        
       
        always @ (*)begin 
            flit_regs_next[i] = flit_regs[i];
            class_vc_next[i]  = class_vc[i];
            if(pass_din_to_flit_reg_delaied[i]) flit_regs_next[i] = {din[Fw-1:Fw-2],din_reg[Fpay-1:0]} ;
            if(bram_out_is_valid_delaied[i])    flit_regs_next[i] = {bram_dout[Fw-1:Fw-2],bram_dout[Fpay-1:0]};
            if(flit_reg_wr_en[i] & flit_reg_mux_out[REGFw-1] ) class_vc_next[i] = class_i;// writing header flit 
        end 
        
       
        
        /* verilator lint_off WIDTH */
         /*
        if( ROUTE_TYPE=="DETERMINISTIC") begin : dtrmn_dest
        always @ (`pronoc_clk_reset_edge )begin 
               if(`pronoc_reset)begin  
                   
                end else begin 
                    dest_port_encoded_vc[i]<= destport_in_encoded;  
                end
            end//always
       end  else begin : adptv_dest   
        
              
        */
         
        
        
        
        always @(*) begin
                valid_next[i] = valid[i];
                if(flit_reg_wr_en[i]) valid_next[i] =1'b1;
                else if( bram_empty[i] & vc_num_rd_en[i]) valid_next[i] =1'b0;
         end
   
    end //for  
    
     /* verilator lint_off WIDTH */  
  //  if(TOPOLOGY=="FATTREE" && ROUTE_NAME == "NCA_STRAIGHT_UP") begin : fat
    /* verilator lint_on WIDTH */  
 /*    
     fattree_destport_up_select #(
         .K(T1),
         .SW_LOC(SW_LOC)
     )
     static_sel
     (
        .destport_in(destport_in),
        .destport_o(destport_in_encoded)
     );
     
    end else begin : other
        assign destport_in_encoded = destport_in;    
    end
    
  */  
    endgenerate
  


    // Update header flit info registers
    
    
   
        
   

  


endmodule



