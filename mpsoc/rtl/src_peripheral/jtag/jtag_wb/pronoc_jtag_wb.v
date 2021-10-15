
// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module pronoc_jtag_wb #(
    
    parameter JTAG_CONNECT="XILINX_JTAG_WB",// "ALTERA_JTAG_WB" , "XILINX_JTAG_WB"  
    parameter JTAG_INDEX= 0,
    parameter JDw =32,// should be a fixed value for all IPs coneccting to JTAG
    parameter JAw=32, // should be a fixed value for all IPs coneccting to JTAG
    parameter JINDEXw=8,
    parameter JSTATUSw=8,
    parameter J2WBw = (JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+1+JDw+JAw : 1,
    parameter WB2Jw= (JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+JSTATUSw+JINDEXw+1+JDw  : 1,

    
    //wishbone port parameters
    parameter Dw          =   32,
    parameter Aw          =   32,
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
    m_ack_i,     
    //jtag interface for xilinx board
    jtag_to_wb,
    wb_to_jtag
    
);

    //IO declaration
    input reset,clk;
    input [JSTATUSw-1 :   0]  status_i;
    
    //wishbone master interface signals
    output  [SELw-1          :   0] m_sel_o;
    output  [Dw-1            :   0] m_dat_o;
    output  [Aw-1            :   0] m_addr_o;
    output  [TAGw-1          :   0] m_cti_o;
    output                          m_stb_o;
    output                          m_cyc_o;
    output                          m_we_o;
    input   [Dw-1           :  0]   m_dat_i;
    input                           m_ack_i;    
   
   //jtag interface
    input  [J2WBw-1 : 0] jtag_to_wb;
    output [WB2Jw-1: 0] wb_to_jtag;
    
    
    generate 
    /* verilator lint_off WIDTH */
    if(JTAG_CONNECT == "ALTERA_JTAG_WB") begin: altera_jwb
    /* verilator lint_on WIDTH */
           
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
            .status_i(status_i),  
            
             //wishbone master interface signals
            .m_sel_o(m_sel_o),
            .m_dat_o(m_dat_o),
            .m_addr_o(m_addr_o),
            .m_cti_o(m_cti_o),
            .m_stb_o(m_stb_o),
            .m_cyc_o(m_cyc_o),
            .m_we_o(m_we_o),
            .m_dat_i(m_dat_i),
            .m_ack_i(m_ack_i)     
        
        );
    
           assign wb_to_jtag[0] = clk;
        
    end//altera_jwb
    
    
    
/* verilator lint_off WIDTH */  
    else if(JTAG_CONNECT == "XILINX_JTAG_WB")begin: xilinx_jwb 
/* verilator lint_on WIDTH */     
    
      
        wire [JDw-1 : 0] wb_to_jtag_dat; 
        wire [JDw-1 : 0] jtag_to_wb_dat;
        wire [JSTATUSw-1 : 0] wb_to_jtag_status;
        wire [JINDEXw-1 : 0] wb_to_jtag_index;
        wire [JAw-1 : 0] jtag_to_wb_addr;
        wire jtag_to_wb_stb;
        wire jtag_to_wb_we;
        wire wb_to_jtag_ack;
     
        assign wb_to_jtag_status = status_i;
        assign wb_to_jtag_index = JTAG_INDEX;
        assign m_dat_o = jtag_to_wb_dat [Dw-1 :0];
        assign m_addr_o = jtag_to_wb_addr[Aw-1:0];
        assign m_stb_o = jtag_to_wb_stb;
        assign m_cyc_o = jtag_to_wb_stb;
        assign m_sel_o = 4'b1111; 
        assign m_cti_o = 3'b000;
        assign m_we_o = jtag_to_wb_we;
        
        assign wb_to_jtag_dat = m_dat_i; 
        assign wb_to_jtag_ack = m_ack_i; 
          
        
        assign wb_to_jtag = {wb_to_jtag_status,wb_to_jtag_ack,wb_to_jtag_dat,wb_to_jtag_index,clk};
        assign {jtag_to_wb_addr,jtag_to_wb_stb,jtag_to_wb_we,jtag_to_wb_dat} = jtag_to_wb;
        
            
        
        
    end else begin 
        assign wb_to_jtag[0] = clk;
    end

    endgenerate
    

endmodule
