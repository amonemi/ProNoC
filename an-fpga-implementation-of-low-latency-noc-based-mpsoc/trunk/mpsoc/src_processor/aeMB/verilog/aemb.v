 `timescale  1ns/1ps

module aeMB_top (
    
  dwb_adr_o,      
  dwb_cyc_o,     
  dwb_dat_o,     
  dwb_sel_o,      
  dwb_stb_o,     
  dwb_tag_o,     
  dwb_wre_o,
  dwb_cti_o,
  dwb_bte_o,      
  dwb_ack_i,      
  dwb_dat_i,  
  dwb_err_i, 
  dwb_rty_i,  
 
  iwb_adr_o,    
  iwb_cyc_o,     
  iwb_sel_o,    
  iwb_stb_o,     
  iwb_tag_o,     
  iwb_wre_o, 
  iwb_dat_o,
  iwb_cti_o,
  iwb_bte_o,    
  iwb_ack_i,      
  iwb_dat_i,      
        
  
  iwb_err_i, 
  iwb_rty_i,  
 
  clk,
  reset,
  sys_int_i,
  sys_ena_i // input  sys_ena_i

);

   parameter AEMB_IWB = 32; ///< INST bus width
   parameter AEMB_DWB = 32; ///< DATA bus width
   parameter AEMB_XWB = 7; ///< XCEL bus width

   // CACHE PARAMETERS
   parameter AEMB_ICH = 11; ///< instruction cache size
   parameter AEMB_IDX = 6; ///< cache index size

   // OPTIONAL HARDWARE
   parameter AEMB_BSF = 1; ///< optional barrel shift
   parameter AEMB_MUL = 1; ///< optional multiplier
 

  
   output [31:0] dwb_adr_o;      
   output        dwb_cyc_o;      
   output [31:0] dwb_dat_o;      
   output [3:0]  dwb_sel_o;      
   output        dwb_stb_o;      
   output  [2:0] dwb_tag_o;      
   output        dwb_wre_o;  
   output  [2:0] dwb_cti_o;
   output  [1:0] dwb_bte_o;
   
     
   input         dwb_ack_i;      
   input [31:0]  dwb_dat_i;     
   
 
   
      
   output [31:0] iwb_adr_o;    
   output        iwb_cyc_o;     
   output [3:0]  iwb_sel_o;     
   output        iwb_stb_o;     
   output [2:0]  iwb_tag_o;     
   output        iwb_wre_o;  
   input         iwb_ack_i;      
   input [31:0]  iwb_dat_i; 
   output[31:0]  iwb_dat_o;   
   output  [2:0] iwb_cti_o;
   output  [1:0] iwb_bte_o;
     
   input         clk;      
   input        sys_ena_i;      
   input        sys_int_i;      
   input        reset;      
  
   wire         i_tag,d_tag;
  
 // not used but added to prevent warning
  input dwb_err_i, dwb_rty_i,  iwb_err_i, iwb_rty_i;


aeMB2_edk63 #(
            .AEMB_IWB (AEMB_IWB), ///< INST bus width
            .AEMB_DWB (AEMB_DWB), ///< DATA bus width
            .AEMB_XWB (AEMB_XWB), ///< XCEL bus width
            .AEMB_ICH (AEMB_ICH), ///< instruction cache size
            .AEMB_IDX (AEMB_IDX),///< cache index size
            .AEMB_BSF (AEMB_BSF), ///< optional barrel shift
            .AEMB_MUL (AEMB_MUL) ///< optional multiplier
        
        )
        
         aeMB2_edk63_inst
        (
            .xwb_wre_o() ,  //    xwb_wre_o
            .xwb_tag_o() ,  //    xwb_tag_o
            .xwb_stb_o() ,  //    xwb_stb_o
            .xwb_sel_o() ,  //   [3:0] xwb_sel_o
            .xwb_dat_o() ,  //   [31:0] xwb_dat_o
            .xwb_cyc_o() ,  //    xwb_cyc_o
            .xwb_adr_o() ,  //   [AEMB_XWB-1:2] xwb_adr_o
            .iwb_wre_o(iwb_wre_o) ,  //    iwb_wre_o
            .iwb_tag_o(i_tag) ,  //    iwb_tag_o
            .iwb_stb_o(iwb_stb_o) ,  //    iwb_stb_o
            .iwb_sel_o(iwb_sel_o) ,  //   [3:0] iwb_sel_o
            .iwb_cyc_o(iwb_cyc_o) ,  //    iwb_cyc_o
            .iwb_adr_o(iwb_adr_o[29:0]) ,    //   [AEMB_IWB-1:2] iwb_adr_o
            
            .dwb_wre_o(dwb_wre_o) ,  //    dwb_wre_o
            .dwb_tag_o(d_tag) ,  //    dwb_tag_o
            .dwb_stb_o(dwb_stb_o) ,  //    dwb_stb_o
            .dwb_sel_o(dwb_sel_o) ,  //   [3:0] dwb_sel_o
            .dwb_dat_o(dwb_dat_o) ,  //   [31:0] dwb_dat_o
            .dwb_cyc_o(dwb_cyc_o) ,  //    dwb_cyc_o
            .dwb_adr_o(dwb_adr_o [29:0]) ,    //   [AEMB_DWB-1:2] dwb_adr_o
            
            .xwb_dat_i(0) , // input [31:0] xwb_dat_i
            .xwb_ack_i(1'b0) ,  // input  xwb_ack_i
            .sys_rst_i(reset) ,   // input  sys_rst_i
            .sys_int_i(sys_int_i) , // input  sys_int_i
            .sys_ena_i(sys_ena_i) , // input  sys_ena_i
            .sys_clk_i(clk  ) ,   // input  sys_clk_i
            
            .iwb_dat_i(iwb_dat_i) ,  // input [31:0] iwb_dat_i
            .iwb_ack_i(iwb_ack_i) ,  // input  iwb_ack_i
            .dwb_dat_i(dwb_dat_i) ,  // input [31:0] dwb_dat_i
            .dwb_ack_i(dwb_ack_i)    // input  dwb_ack_i
        );

        assign iwb_dat_o = 0;
        // I have no idea which tag (a,b or c) is used in aemb. I assume it is address tag (taga) 
        assign iwb_tag_o        = {i_tag,2'b00};   
        assign dwb_tag_o        = {d_tag,2'b00};     
        assign iwb_adr_o[31:30] = 2'b00;
        assign dwb_adr_o[31:30] = 2'b00;
        assign dwb_cti_o        = 3'd0;
        assign dwb_bte_o        = 2'd0;
	assign iwb_cti_o        = 3'd0;
        assign iwb_bte_o        = 2'd0;
        
        

endmodule        
    
