/**********************************************************************
**	File:  wishbone_bus.v 
**	 
**    
**	Copyright (C) 2014-2017  Alireza Monemi
**    
**	This file is part of ProNoC 
**
**	ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**	you can redistribute it and/or modify it under the terms of the GNU
**	Lesser General Public License as published by the Free Software Foundation,
**	either version 2 of the License, or (at your option) any later version.
**
** 	ProNoC is distributed in the hope that it will be useful, but WITHOUT
** 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
** 	or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
** 	Public License for more details.
**
** 	You should have received a copy of the GNU Lesser General Public
** 	License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
**	Description: 
**	parametrizable wishbone bus 	
**
*******************************************************************/








`timescale   10ns/1ns


module wishbone_bus #(
		
	parameter M        =   4,		//number of master port
	parameter S        =   4,		//number of slave port
	parameter Dw       =   32,	   // maximum data width
	parameter Aw       =   32,    // address width
	parameter SELw     =   2,
	parameter TAGw     =   3,    //merged  {tga,tgb,tgc}
	parameter CTIw     =   3,
	parameter BTEw     =   2 
  
		
)
(
	//slaves interface
	s_adr_o_all,
	s_dat_o_all,
	s_sel_o_all,
	s_tag_o_all,
	s_we_o_all,
	s_cyc_o_all,
	s_stb_o_all,
	s_cti_o_all,
    s_bte_o_all,    
	
	s_dat_i_all,
	s_ack_i_all,
	s_err_i_all,
	s_rty_i_all,
								
	
	//masters interface
	m_dat_o_all,
	m_ack_o_all,
	m_err_o_all,
	m_rty_o_all,
	
	
	m_adr_i_all,
	m_dat_i_all,
	m_sel_i_all,
	m_tag_i_all,
	m_we_i_all,
	m_stb_i_all,
	m_cyc_i_all,
	m_cti_i_all,
    m_bte_i_all,
	
	//address compar
	m_grant_addr,
    s_sel_one_hot,
	
	
	//system signals
	
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

	
	
    localparam  DwS     =   Dw * S,
                AwS     =   Aw * S,
                SELwS   =   SELw * S, 
                TAGwS   =   TAGw * S,
                CTIwS   =   CTIw * S,
                BTEwS   =   BTEw * S,          
                DwM     =   Dw * M,
                AwM     =   Aw  * M,
                SELwM   =   SELw   * M,
                TAGwM   =   TAGw   * M,
                Mw      =   (M>1)? log2(M):1,
                Sw      =   (S>1)? log2(S):1,
                CTIwM   =   CTIw * M,
                BTEwM   =   BTEw * M;          
                
                
                


    output  [AwS-1      :   0]   s_adr_o_all;
    output  [DwS-1      :   0]   s_dat_o_all;
    output  [SELwS-1    :   0]   s_sel_o_all;
    output  [TAGwS-1    :   0]   s_tag_o_all;
    output  [S-1        :   0]   s_we_o_all;
    output  [S-1        :   0]   s_cyc_o_all;
    output  [S-1        :   0]   s_stb_o_all;
    output  [CTIwS-1    :   0]   s_cti_o_all;
    output  [BTEwS-1    :   0]   s_bte_o_all;   
    
    
    input   [DwS-1      :   0]   s_dat_i_all;
    input   [S-1        :   0]   s_ack_i_all;
    input   [S-1        :   0]   s_err_i_all;
    input   [S-1        :   0]   s_rty_i_all;
                                 
    
  
                                 
    
    //masters interface
    output  [DwM-1      :   0]   m_dat_o_all;
    output  [M-1        :   0]   m_ack_o_all;
    output  [M-1        :   0]   m_err_o_all;
    output  [M-1        :   0]   m_rty_o_all;
             
    
    input   [AwM-1      :   0]   m_adr_i_all;
    input   [DwM-1      :   0]   m_dat_i_all;
    input   [SELwM-1    :   0]   m_sel_i_all;
    input   [TAGwM-1    :   0]   m_tag_i_all;
    input   [M-1        :   0]   m_we_i_all;
    input   [M-1        :   0]   m_stb_i_all;
    input   [M-1        :   0]   m_cyc_i_all;
    input   [CTIwM-1    :   0]   m_cti_i_all;
    input   [BTEwM-1    :   0]   m_bte_i_all; 
    
    //
     output [Aw-1       :   0]  m_grant_addr;
     input  [S-1        :   0]  s_sel_one_hot;
    //system signals
    
    input                           clk,     reset;
    

    wire	                    any_s_ack,any_s_err,any_s_rty;
    wire                        m_grant_we,m_grant_stb,m_grant_cyc;
   
    wire    [Dw-1       :	0]	m_grant_dat,s_read_dat;
    wire	[SELw-1     :	0]	m_grant_sel;
    wire    [BTEw-1     :   0]  m_grant_bte;
    wire    [CTIw-1     :   0]  m_grant_cti;
    wire	[TAGw-1     :	0]	m_grant_tag;

    
    wire	[Sw-1       :	0]	s_sel_bin;
    wire	[M-1        :	0]	m_grant_onehot;
    wire	[Mw-1       :	0]	m_grant_bin;

    wire 	[Aw-1      :	0]	s_adr_o;
    wire	[Dw-1      :	0]	s_dat_o;
    wire	[SELw-1    :	0]	s_sel_o;
    wire    [BTEw-1    :    0]  s_bte_o;
    wire    [CTIw-1    :    0]  s_cti_o;
    
    wire	[TAGw-1    :	0]	s_tag_o;
    wire                        s_we_o;
    wire                        s_cyc_o;
    wire	[Dw-1       :	0]	m_dat_o;


    assign	s_adr_o_all	=	{S{s_adr_o}};
    assign	s_dat_o_all	=	{S{s_dat_o}};
    assign	s_sel_o_all	=	{S{s_sel_o}};
    assign  s_cti_o_all =   {S{s_cti_o}};
    assign  s_bte_o_all =   {S{s_bte_o}};
    
    assign	s_tag_o_all	=	{S{s_tag_o}};
    assign	s_we_o_all	=	{S{s_we_o}};
    assign	s_cyc_o_all	=	{S{s_cyc_o}};
    assign	m_dat_o_all=	{M{m_dat_o}};

    assign 	any_s_ack   =|	s_ack_i_all;
    assign 	any_s_err   =|	s_err_i_all;
    assign 	any_s_rty   =|	s_rty_i_all;

    assign 	s_adr_o	    =	m_grant_addr;
    assign 	s_dat_o     =	m_grant_dat;
    assign 	s_sel_o     =	m_grant_sel;
    assign  s_bte_o     =   m_grant_bte;
    assign  s_cti_o     =   m_grant_cti;
    assign	s_tag_o     =	m_grant_tag;
    assign 	s_we_o      =	m_grant_we;
    assign 	s_cyc_o     =	m_grant_cyc;
    assign 	s_stb_o_all	=	s_sel_one_hot & {S{m_grant_stb & m_grant_cyc}};


//wire	[ADDR_PERFIX-1		:	0]	m_perfix_addr;
//assign m_perfix_addr		=	m_grant_addr[Aw-3	:	Aw-ADDR_PERFIX-2];


assign  m_dat_o		= 	s_read_dat;
assign	m_ack_o_all	=	m_grant_onehot	& {M{any_s_ack}};	
assign	m_err_o_all	=	m_grant_onehot	& {M{any_s_err}}; 
assign	m_rty_o_all	=	m_grant_onehot	& {M{any_s_rty}};



    		
//convert one hot to bin 
    one_hot_to_bin #(
    	.ONE_HOT_WIDTH(S)	
    )
    s_sel_conv
    (
    	.one_hot_code(s_sel_one_hot),
    	.bin_code(s_sel_bin)
    );



    one_hot_to_bin #(
    	.ONE_HOT_WIDTH(M)  
    )
    m_grant_conv
    (
    	.one_hot_code	(m_grant_onehot),
    	.bin_code		(m_grant_bin)
    );



    //slave multiplexer 
    binary_mux #( 
    	.IN_WIDTH 	(DwS),	
    	.OUT_WIDTH 	(Dw)
    )
     s_read_data_mux
    (
    	.mux_in		(s_dat_i_all),
    	.mux_out		(s_read_dat),
    	.sel			(s_sel_bin)
    
    );
    
    
    //master ports multiplexers
    
    binary_mux #( 
    	.IN_WIDTH 	(AwM),	
    	.OUT_WIDTH 	(Aw)
    )
     m_adr_mux
    (
    	.mux_in		(m_adr_i_all),
    	.mux_out		(m_grant_addr),
    	.sel			(m_grant_bin)
    
    );
    
    
    
    binary_mux #( 
    	.IN_WIDTH 	(DwM),	
    	.OUT_WIDTH 	(Dw)
    )
     m_data_mux
    (
    	.mux_in		(m_dat_i_all),
    	.mux_out		(m_grant_dat),
    	.sel			(m_grant_bin)
    
    );
    
    
    
    binary_mux #( 
    	.IN_WIDTH 	(SELwM),	
    	.OUT_WIDTH 	(SELw)
    )
     m_sel_mux
    (
    	.mux_in		(m_sel_i_all),
    	.mux_out		(m_grant_sel),
    	.sel			(m_grant_bin)
    
    );
    
     binary_mux #( 
        .IN_WIDTH   (BTEwM),    
        .OUT_WIDTH  (BTEw)
    )
     m_bte_mux
    (
        .mux_in         (m_bte_i_all),
        .mux_out        (m_grant_bte),
        .sel            (m_grant_bin)
    
    );
    
    binary_mux #( 
        .IN_WIDTH   (CTIwM),    
        .OUT_WIDTH  (CTIw)
    )
     m_cti_mux
    (
        .mux_in         (m_cti_i_all),
        .mux_out        (m_grant_cti),
        .sel            (m_grant_bin)
    
    );
    
    
    binary_mux #( 
    	.IN_WIDTH 	(TAGwM),	
    	.OUT_WIDTH 	(TAGw)
    )
     m_tag_mux
    (
    	.mux_in		(m_tag_i_all),
    	.mux_out		(m_grant_tag),
    	.sel			(m_grant_bin)
    
    );
    
    
    binary_mux #( 
    	.IN_WIDTH 	(M),	
    	.OUT_WIDTH 	(1)
    )
     m_we_mux
    (
    	.mux_in		(m_we_i_all),
    	.mux_out		(m_grant_we),
    	.sel			(m_grant_bin)
    
    );
    
    
   /* 
    binary_mux #( 
    	.IN_WIDTH 	(M),	
    	.OUT_WIDTH 	(1)
    )
     m_stb_mux
    (
    	.mux_in		(m_stb_i_all),
    	.mux_out		(m_grant_stb),
    	.sel			(m_grant_bin)
    
    );
    
    
    
    binary_mux #( 
    	.IN_WIDTH 	(M),	
    	.OUT_WIDTH 	(1)
    )
     m_cyc_mux
    (
    	.mux_in		(m_cyc_i_all),
    	.mux_out		(m_grant_cyc),
    	.sel			(m_grant_bin)
    
    );
   */
   // if m_grant_one_hot is zero the stb and cyc  must not be asserted hence have to use one-hot mux 
   
   
    one_hot_mux #(
       	.IN_WIDTH(M),
       	.SEL_WIDTH(M),
       	.OUT_WIDTH(1)
    )
    m_stb_mux
    (
        .mux_in(m_stb_i_all),
        .mux_out(m_grant_stb),
        .sel(m_grant_onehot)
    
    );
    
    
     one_hot_mux #(
        .IN_WIDTH(M),
        .SEL_WIDTH(M),
        .OUT_WIDTH(1)
    )
     m_cyc_mux
    (
        .mux_in(m_cyc_i_all),
        .mux_out(m_grant_cyc),
        .sel(m_grant_onehot)
    
    );
  
    
  
    

generate
	if(M > 1) begin
		// round roubin arbiter
		bus_arbiter # (
			.M (M)
		)
		arbiter
		(
			.request (m_cyc_i_all),
			.grant	(m_grant_onehot),
			.clk (clk),
			.reset (reset)
		);
	end else begin // if we have just one master there is no needs for arbitration
		assign m_grant_onehot = m_cyc_i_all;
	end
endgenerate



endmodule




/**************
    
    bus_arbiter

**************/

module bus_arbiter # (
	parameter M = 4
)
(
	request,
	grant,
	clk,
	reset
);

    input   [M-1    :       0]  request;
    output  [M-1    :       0]  grant;
    input                       clk, reset;

    wire                    comreq;
    wire    [M-1	:	0]	one_hot_arb_req, one_hot_arb_grant;
    reg     [M-1	:	0]	grant_registered;

    assign 	one_hot_arb_req	=	request  & {M{~comreq}};
    assign	grant					=	grant_registered;

    assign comreq	=	|(grant & request);

    always @ (posedge clk or posedge reset) begin 
	   if (reset) begin 
		  grant_registered	<= {M{1'b0}};
	   end else begin
		  if(~comreq)	grant_registered	<=	one_hot_arb_grant;		
	   end
    end//always


    arbiter #(
	   .ARBITER_WIDTH	(M )
    )
    the_combinational_arbiter
    (
	   .request		(one_hot_arb_req),
	   .grant		(one_hot_arb_grant),
	   .any_grant	(),
	   .clk			(clk),
	   .reset		(reset)
    );




endmodule
