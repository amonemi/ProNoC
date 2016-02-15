// =============================================================================
//                           COPYRIGHT NOTICE
// Copyright 2006 (c) Lattice Semiconductor Corporation
// ALL RIGHTS RESERVED
// This confidential and proprietary software may be used only as authorised by
// a licensing agreement from Lattice Semiconductor Corporation.
// The entire notice above must be reproduced on all authorized copies and
// copies may only be made to the extent permitted by a licensing agreement from
// Lattice Semiconductor Corporation.
//
// Lattice Semiconductor Corporation        TEL : 1-800-Lattice (USA and Canada)
// 5555 NE Moore Court                            408-826-6000 (other locations)
// Hillsboro, OR 97124                     web  : http://www.latticesemi.com/
// U.S.A                                   email: techsupport@latticesemi.com
// =============================================================================/
//                         FILE DETAILS
// Project          : LatticeMico32
// File             : jtag_cores.v
// Title            : Instantiates all IP cores on JTAG chain.
// Dependencies     : system_conf.v
// Version          : 6.0.13
// =============================================================================

`include "system_conf.v"

/////////////////////////////////////////////////////
// Module interface
/////////////////////////////////////////////////////

module jtag_cores#(
	parameter test="ali"
 
)
  (
    // ----- Inputs -------
`ifdef INCLUDE_LM32
    reg_d,
    reg_addr_d,
`endif    
`ifdef INCLUDE_SPI      
    spi_q,
`endif
    // ----- Outputs -------    
`ifdef INCLUDE_LM32
    reg_update,
    reg_q,
    reg_addr_q,
`endif    
`ifdef INCLUDE_SPI      
    spi_c,
    spi_d,
    spi_sn,
`endif
    jtck,
    jrstn
    );
    
/////////////////////////////////////////////////////
// Inputs
/////////////////////////////////////////////////////

`ifdef INCLUDE_LM32
input [7:0] reg_d;
input [2:0] reg_addr_d;
`endif

`ifdef INCLUDE_SPI      
input spi_q;
`endif

/////////////////////////////////////////////////////
// Outputs
/////////////////////////////////////////////////////
   
`ifdef INCLUDE_LM32
output reg_update;
wire   reg_update;
output [7:0] reg_q;
wire   [7:0] reg_q;
output [2:0] reg_addr_q;
wire   [2:0] reg_addr_q;
`endif

`ifdef INCLUDE_SPI      
output spi_c;
wire   spi_c;
output spi_d;
wire   spi_d;
output spi_sn;
wire   spi_sn;
`endif

output jtck;
wire   jtck; 	/* synthesis ER1_MARK="jtck" */ /* synthesis syn_keep=1 */
output jrstn;
wire   jrstn; /* synthesis ER1_MARK="jrstn" */ /* synthesis syn_keep=1 */	

   
/////////////////////////////////////////////////////
// Internal nets and registers 
/////////////////////////////////////////////////////

wire rtiER1;
wire rtiER2;
wire tdi;/* synthesis ER1_MARK="jtdi" */ /* synthesis syn_keep=1 */
wire tdoEr1;/* synthesis ER1_MARK="jtdo1" */ /* synthesis syn_keep=1 */
wire tdoEr2;
wire jtdo2_mux;/* synthesis ER1_MARK="jtdo2" */ /* synthesis syn_keep=1 */
wire spi_tdo2;
wire shiftDr;/* synthesis ER1_MARK="jshift" */ /* synthesis syn_keep=1 */
wire updateDr;/* synthesis ER1_MARK="jupdate" */ /* synthesis syn_keep=1 */
wire enableEr1;/* synthesis ER1_MARK="jce1" */ /* synthesis syn_keep=1 */
wire enableEr2;/* synthesis ER1_MARK="jce2" */ /* synthesis syn_keep=1 */
wire [14:0] ipEnable;/* synthesis ER1_MARK="ip_enable" */ /* synthesis syn_keep=1 */
wire controlDataN;/* synthesis ER1_MARK="control_datan" */ /* synthesis syn_keep=1 */
wire lm32_isptracy_enable;/* synthesis ER1_MARK="isptracy_enable" */ /* synthesis syn_keep=1 */


/////////////////////////////////////////////////////
// Instantiations
/////////////////////////////////////////////////////
   
generate 
   if (lat_family == "EC" || lat_family == "ECP" || lat_family == "XP") begin
     JTAGB jtagb (.JTCK           (jtck),
		  .JRTI1          (rtiER1),
		  .JRTI2          (rtiER2),
		  .JTDI           (tdi),
		  .JSHIFT         (shiftDr),
		  .JUPDATE        (updateDr),
		  .JRSTN          (jrstn),
		  .JCE1           (enableEr1),
		  .JCE2           (enableEr2),
		  .JTDO1          (tdoEr1),
		  .JTDO2          (jtdo2_mux)) /* synthesis ER1="ENABLED" */ /* synthesis ER2="ENABLED" */ /* synthesis JTAG_FLASH_PRGRM="DISABLED" */;
   end else if (lat_family == "ECP2" || lat_family == "ECP2M") begin
     JTAGC jtagc (.JTCK           (jtck),
		  .JRTI1          (rtiER1),
		  .JRTI2          (rtiER2),
		  .JTDI           (tdi),
		  .JSHIFT         (shiftDr),
		  .JUPDATE        (updateDr),
		  .JRSTN          (jrstn),
		  .IJTAGEN	  (1'b1),
		  .JCE1           (enableEr1),
		  .JCE2           (enableEr2),
		  .JTDO1          (tdoEr1),
		  .JTDO2          (jtdo2_mux)) /* synthesis ER1="ENABLED" */ /* synthesis ER2="ENABLED" */ /* synthesis JTAG_FLASH_PRGRM="DISABLED" */;
   end else if (lat_family == "SC" || lat_family == "SCM") begin // if (lat_family == "ECP2" || lat_family == "ECP2M")
      JTAGA jtaga(.JTCK		  (jtck),
		  .JRTI1	  (rtiER1),
		  .JRTI2	  (rtiER2),
		  .JTDI		  (tdi),
		  .JSHIFT	  (shiftDr),
		  .JUPDATE	  (updateDr),
		  .JRSTN	  (jrstn),
		  .JCE1           (enableEr1),
		  .JCE2           (enableEr2),
		  .JTDO1          (tdoEr1),
		  .JTDO2          (jtdo2_mux)) /* synthesis ER1="ENABLED" */ /* synthesis ER2="ENABLED" */ /* synthesis JTAG_FLASH_PRGRM="DISABLED" */;      
   end   
endgenerate   

ER1 er1 (
    .JTCK           (jtck),
    .JTDI           (tdi),
    .JTDO1          (tdoEr1),
    .JTDO2          (jtdo2_mux),
    .JSHIFT         (shiftDr),
    .JUPDATE        (updateDr),
    .JRSTN          (jrstn),
    .JCE1           (enableEr1),
    .ER2_TDO        ({13'b0,tdoEr2,spi_tdo2}),
    .IP_ENABLE      (ipEnable),
    .ISPTRACY_ENABLE(lm32_isptracy_enable),
    .ISPTRACY_ER2_TDO(lm32_isptracy_enable),
    .CONTROL_DATAN  (controlDataN));

`ifdef INCLUDE_LM32
jtag_lm32 jtag_lm32 (
    .JTCK           (jtck),
    .JTDI           (tdi),
    .JTDO2          (tdoEr2),
    .JSHIFT         (shiftDr),
    .JUPDATE        (updateDr),
    .JRSTN          (jrstn),
    .JCE2           (enableEr2),
    .JTAGREG_ENABLE (ipEnable[1]),
    .CONTROL_DATAN  (controlDataN),
    .REG_UPDATE     (reg_update),
    .REG_D          (reg_d),
    .REG_ADDR_D     (reg_addr_d),
    .REG_Q          (reg_q),
    .REG_ADDR_Q     (reg_addr_q)
    );
`endif

`ifdef INCLUDE_SPI
SPIPROG spiprog_inst (
     .JTCK           (tck),      		
	 .JTDI           (tdi),      		 
	 .JTDO2          (spi_tdo2),      
	 .JSHIFT         (shiftDr),      	
	 .JUPDATE        (updateDr),      
	 .JRSTN          (resetN),      	
	 .JCE2           (enableEr2),     
	 .SPIPROG_ENABLE (ipEnable[0]),   
	 .CONTROL_DATAN  (controlDataN),  
	 .SPI_C          (spi_c),         
	 .SPI_D          (spi_d),      		
	 .SPI_SN         (spi_sn),      	
	 .SPI_Q          (spi_q)           
	 );
`endif
    
endmodule
