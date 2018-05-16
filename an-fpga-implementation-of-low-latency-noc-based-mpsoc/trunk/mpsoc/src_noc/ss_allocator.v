/**********************************************************************
**	File:  ss_allocator.v
**	Date:2016-06-19  
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
**	static straight allocator : The incomming packet targetting outputport located in same direction 
** 	will be forwarded with one clock cycle latency if the following contions met in current clock cycle:
**	1) If no ivc is granted in the input port 
**	2) The ss output port is not granted for any other input port 
**	3) Packet destionation port match with ss port
**	4) The requested output VC is available in ss port 
**	   The ss ports for each input potrt must be diffrent with the rest
**	   This result in one clock cycle latency                
***************************************/
`timescale  1ns/1ps

module  ss_allocator#(
    parameter V = 4,
    parameter P = 5,
    parameter ROUTE_TYPE="DETERMINISTIC",
    parameter Fpay = 32,
    parameter DEBUG_EN =   1,
    parameter [V-1  :   0] ESCAP_VC_MASK = 4'b1000
   )
   (
        flit_in_we_all,
        flit_in_all,
        any_ovc_granted_in_outport_all ,
        any_ivc_sw_request_granted_all ,
        ovc_avalable_all,
        assigned_ovc_not_full_all,
        ivc_request_all,
        dest_port_all,
        assigned_ovc_num_all,
        ovc_is_assigned_all,
       
        
        clk,
        reset,
        ovc_allocated_all,
        ovc_released_all,
        granted_ovc_num_all,
        ivc_num_getting_sw_grant_all,
        ivc_num_getting_ovc_grant_all,
        ivc_reset_all,
        decreased_credit_in_ss_ovc_all,
        ssa_flit_wr_all

   );


    localparam  PV          =   V   *   P,
                PVV         =   PV  *   V,
                P_1         =   P-1 ,
                PVP_1       =   PV  *   P_1,
                Fw          =   2+V+Fpay,//flit width
                PFw         =   P   *   Fw;
                
     //p=5           
     localparam   LOCAL   =   0,  
                  EAST    =   1,
                  NORTH   =   2, 
                  WEST    =   3,
                  SOUTH   =   4;           
               
      
     // p=3 : ring line            
    localparam  FORWARD =  1,
                BACKWARD=  2;  
                
                

    input   [PFw-1          :   0]  flit_in_all;
    input   [P-1            :   0]  flit_in_we_all;
    input   [P-1            :   0]  any_ovc_granted_in_outport_all;
    input   [P-1            :   0]  any_ivc_sw_request_granted_all;
    input   [PV-1           :   0]  ovc_avalable_all;
    input   [PV-1           :   0]  assigned_ovc_not_full_all;
    input   [PV-1           :   0]  ivc_request_all;
    input   [PVP_1-1        :   0]  dest_port_all;
    input   [PVV-1          :   0]  assigned_ovc_num_all;
    input   [PV-1           :   0]  ovc_is_assigned_all;
    input   reset,clk;
    

    output   [PV-1      :   0] ovc_allocated_all;
    output   [PV-1      :   0] ovc_released_all;
    output   [PVV-1     :   0] granted_ovc_num_all;
    output   [PV-1      :   0] ivc_num_getting_sw_grant_all;
    output   [PV-1      :   0] ivc_num_getting_ovc_grant_all;
    output   [PV-1      :   0] ivc_reset_all;
    output   [PV-1      :   0] decreased_credit_in_ss_ovc_all;
    output  reg [P-1       :   0] ssa_flit_wr_all;



 

    wire [PV-1   :   0] any_ovc_granted_in_ss_port;
    wire [PV-1   :   0] ovc_avalable_in_ss_port;
    wire [PV-1   :   0] ovc_allocated_in_ss_port;
    wire [PV-1   :   0] ovc_released_in_ss_port;
    wire [PV-1   :   0] decreased_credit_in_ss_ovc;
    wire [PV-1   :   0] ivc_num_getting_sw_grantin_SS_all;



 genvar i;
    // there is no ssa for local port in 5 and 3 port routers
   localparam DISABLED_SSA_PORT=  0; 

    generate
    for (i=0; i<PV; i=i+1) begin : vc_loop
    /*
        localparam  SS_PORT_P5 = ((i/V)== EAST)? WEST:
                                 ((i/V)== WEST)? EAST:
                                 ((i/V)== SOUTH)? NORTH:
                                 ((i/V)== NORTH)? SOUTH:
                                 DISABLED;

	localparam  SS_PORT_P3 = ((i/V)== 1)? 3'd2:
                                 ((i/V)== 2)? 3'd1:
                                 DISABLED;

        localparam  SS_PORT      =   (P==5) ? SS_PORT_P5:
				     (P==3) ? SS_PORT_P3: DISABLED;

    */   
        
       if ((i/V)== DISABLED_SSA_PORT)begin : no_prefrable
       
       
            assign   ovc_allocated_all[i]= 1'b0;
            assign   ovc_released_all [i]= 1'b0;
            assign   granted_ovc_num_all[(i+1)*V-1   :   i*V]= {V{1'b0}};
            assign   ivc_num_getting_sw_grant_all [i]= 1'b0;
            assign   ivc_num_getting_ovc_grant_all [i]= 1'b0;
            assign   ivc_reset_all [i]= 1'b0;
            assign   decreased_credit_in_ss_ovc_all[i]=1'b0;
           // assign   predict_flit_wr_all [i]=1'b0;
               
       
       
       
       
       
       end else begin : ssa
       // some old synthezier does not accept definig localparam insde generate loop  to
       // adapt with we assign wires manually using if-else conditions
       if(P==5)begin :p5
        
           if((i/V)== EAST)begin : SS_WEST
             assign   any_ovc_granted_in_ss_port[i]=any_ovc_granted_in_outport_all[WEST];
             assign   ovc_avalable_in_ss_port[i]=ovc_avalable_all[(WEST*V)+(i%V)];
             assign   ovc_allocated_all[(WEST*V)+(i%V)]=ovc_allocated_in_ss_port[i];
             assign   ovc_released_all[(WEST*V)+(i%V)]=ovc_released_in_ss_port[i];
             assign   decreased_credit_in_ss_ovc_all[(WEST*V)+(i%V)]=decreased_credit_in_ss_ovc[i]; 
             assign   ivc_num_getting_sw_grantin_SS_all[i]=  ivc_num_getting_sw_grant_all[(WEST*V)+(i%V)];         
            end   
            
          else if((i/V)== WEST)begin : SS_EAST
             assign   any_ovc_granted_in_ss_port[i]=any_ovc_granted_in_outport_all[EAST];
             assign   ovc_avalable_in_ss_port[i]=ovc_avalable_all[(EAST*V)+(i%V)];
             assign   ovc_allocated_all[(EAST*V)+(i%V)]=ovc_allocated_in_ss_port[i];
             assign   ovc_released_all[(EAST*V)+(i%V)]=ovc_released_in_ss_port[i];
             assign   decreased_credit_in_ss_ovc_all[(EAST*V)+(i%V)]=decreased_credit_in_ss_ovc[i]; 
             assign   ivc_num_getting_sw_grantin_SS_all[i]=  ivc_num_getting_sw_grant_all[(EAST*V)+(i%V)];                    
          end 
          
          else if((i/V)== NORTH)begin : SS_SOUTH
             assign   any_ovc_granted_in_ss_port[i]=any_ovc_granted_in_outport_all[SOUTH];
             assign   ovc_avalable_in_ss_port[i]=ovc_avalable_all[(SOUTH*V)+(i%V)];
             assign   ovc_allocated_all[(SOUTH*V)+(i%V)]=ovc_allocated_in_ss_port[i];
             assign   ovc_released_all [(SOUTH*V)+(i%V)]=ovc_released_in_ss_port[i];
             assign   decreased_credit_in_ss_ovc_all[(SOUTH*V)+(i%V)]=decreased_credit_in_ss_ovc[i];
             assign   ivc_num_getting_sw_grantin_SS_all[i]=  ivc_num_getting_sw_grant_all[(SOUTH*V)+(i%V)];           
                       
          end  else begin : SS_NORTH
             assign   any_ovc_granted_in_ss_port[i]=any_ovc_granted_in_outport_all[NORTH];
             assign   ovc_avalable_in_ss_port[i]=ovc_avalable_all[(NORTH*V)+(i%V)];
             assign   ovc_allocated_all[(NORTH*V)+(i%V)]=ovc_allocated_in_ss_port[i];
             assign   ovc_released_all [(NORTH*V)+(i%V)]=ovc_released_in_ss_port[i];
             assign   decreased_credit_in_ss_ovc_all[(NORTH*V)+(i%V)]=decreased_credit_in_ss_ovc[i]; 
             assign   ivc_num_getting_sw_grantin_SS_all[i]=  ivc_num_getting_sw_grant_all[(NORTH*V)+(i%V)];                   
          
          end                 
       
        end else begin :P3
            if((i/V)== FORWARD ) begin : SS_BACKWARD
                assign   any_ovc_granted_in_ss_port[i]=any_ovc_granted_in_outport_all[BACKWARD];
                assign   ovc_avalable_in_ss_port[i]=ovc_avalable_all[(BACKWARD*V)+(i%V)];
                assign   ovc_allocated_all[(BACKWARD*V)+(i%V)]=ovc_allocated_in_ss_port[i];
                assign   ovc_released_all [(BACKWARD*V)+(i%V)]=ovc_released_in_ss_port[i];
                assign   decreased_credit_in_ss_ovc_all[(BACKWARD*V)+(i%V)]=decreased_credit_in_ss_ovc[i]; 
                assign   ivc_num_getting_sw_grantin_SS_all[i]=  ivc_num_getting_sw_grant_all[(BACKWARD*V)+(i%V)];          
            end else begin : SS_FORWARD
                assign   any_ovc_granted_in_ss_port[i]=any_ovc_granted_in_outport_all[FORWARD];
                assign   ovc_avalable_in_ss_port[i]=ovc_avalable_all[(FORWARD*V)+(i%V)];
                assign   ovc_allocated_all[(FORWARD*V)+(i%V)]=ovc_allocated_in_ss_port[i];
                assign   ovc_released_all [(FORWARD*V)+(i%V)]=ovc_released_in_ss_port[i];
                assign   decreased_credit_in_ss_ovc_all[(FORWARD*V)+(i%V)]=decreased_credit_in_ss_ovc[i]; 
                assign   ivc_num_getting_sw_grantin_SS_all[i]=  ivc_num_getting_sw_grant_all[(FORWARD*V)+(i%V)];                       
            end             
       
       end
      
       
        ssa_per_vc #(
            .V_GLOBAL(i),
            .V(V),
            .P(P),
            .Fpay(Fpay),
            .ROUTE_TYPE(ROUTE_TYPE),
            .DEBUG_EN(DEBUG_EN),
            .ESCAP_VC_MASK(ESCAP_VC_MASK)
        )
        the_ssa_per_vc
        (
            .flit_in_we(flit_in_we_all[(i/V)]),
            .flit_in(flit_in_all[((i/V)+1)*Fw-1 :   (i/V)*Fw]),
            .any_ivc_sw_request_granted(any_ivc_sw_request_granted_all[(i/V)]),
            
            .any_ovc_granted_in_ss_port(any_ovc_granted_in_ss_port[i]),
            
            .ovc_avalable_in_ss_port(ovc_avalable_in_ss_port[i]),
            
            .ivc_request(ivc_request_all[i]),
            .assigned_ovc_not_full(assigned_ovc_not_full_all[i]),
            .dest_port(dest_port_all[(i+1)*P_1-1 :   i*P_1]),
            .assigned_to_ssovc(assigned_ovc_num_all[(i*V)+(i%V)]),
            .ovc_is_assigned(ovc_is_assigned_all[i]),
            
            .ovc_allocated(ovc_allocated_in_ss_port[i]),
            
            .ovc_released(ovc_released_in_ss_port[i]),
            
            .granted_ovc_num(granted_ovc_num_all[(i+1)*V-1 : i*V]),
            .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant_all[i]),
            .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant_all[i]),
            .ivc_reset(ivc_reset_all[i]),
            
            .decreased_credit_in_ss_ovc(decreased_credit_in_ss_ovc[i])

//synthesis translate_off 
//synopsys  translate_off
	    ,.clk(clk)
//synthesis translate_on 
//synopsys  translate_on	
            // .predict_flit_wr(predict_flit_wr_all[PREDICT_PO]),
            

           );
     
           
               
     end



    end// vc_loop
    
    
        for(i=0;i<P;i=i+1)begin: port_lp
        /*
             localparam  SS_P5 =  (i== EAST)? WEST:
                                 (i== WEST)? EAST:
                                 (i== SOUTH)? NORTH:
                                 (i== NORTH)? SOUTH:
                                 LOCAL;


            localparam  SS_P3 =  (i== 1)? 2:
                                 (i== 2)? 1:
                                 LOCAL;

	    localparam  SS_P =  (P==5) ? SS_P5 :
				(P==3) ? SS_P3 : i;

        */
            
            always @(posedge clk or posedge reset)begin
                if(reset)begin
                    ssa_flit_wr_all[i]<=1'b0;
                end else begin
                    ssa_flit_wr_all[i]<= |ivc_num_getting_sw_grantin_SS_all[(i+1)*V-1    :   i*V];                
                end
             end
         end// port_lp
    
    
    endgenerate


endmodule
















module ssa_per_vc #(
    parameter V_GLOBAL = 1,
    parameter V = 4,    // vc_num_per_port
    parameter P = 5,    // router port num
    parameter Fpay = 32, //pa
    parameter ROUTE_TYPE="DETERMINISTIC", // "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter DEBUG_EN =   1,
    parameter [V-1  :   0] ESCAP_VC_MASK = 4'b1000
    )
    (
        flit_in_we,
        flit_in,
        any_ovc_granted_in_ss_port,
        any_ivc_sw_request_granted,
        ovc_avalable_in_ss_port,
        ivc_request,
        assigned_ovc_not_full,
        granted_ovc_num,
        ivc_num_getting_sw_grant,
        ivc_num_getting_ovc_grant,
        assigned_to_ssovc,
        ovc_is_assigned,
        dest_port,
        ovc_released,
        ovc_allocated,
        decreased_credit_in_ss_ovc,
        ivc_reset
//synthesis translate_off 
//synopsys  translate_off
	,clk
//synthesis translate_on 
//synopsys  translate_on	      
        
   );
   

                  
                  
     //p=5           
     localparam   LOCAL   =   0,  
                  EAST    =   1,
                  NORTH   =   2, 
                  WEST    =   3,
                  SOUTH   =   4,
                  DISABLED= P;           
               
      
     // p=3 : ring line            
    localparam  FORWARD =  1,
                BACKWARD=  2;      


    localparam  
        SS_PORT_P5 = ((V_GLOBAL/V)== EAST)? WEST:
                     ((V_GLOBAL/V)== WEST)? EAST:
                     ((V_GLOBAL/V)== SOUTH)? NORTH:
                     ((V_GLOBAL/V)== NORTH)? SOUTH:
                                      DISABLED;

    localparam  SS_PORT_P3 = ((V_GLOBAL/V)== FORWARD)? BACKWARD:
                                 ((V_GLOBAL/V)== BACKWARD)?  FORWARD:
                                 DISABLED;

    localparam  SS_PORT      =   (P==5) ? SS_PORT_P5:
                     (P==3) ? SS_PORT_P3: DISABLED;
  
   
    
    //header packet filds width
    localparam  Fw      =2+V+Fpay,//flit width
                P_1     =P-1,
                DEST_IN_HDR_WIDTH  =8,
                X_Y_IN_HDR_WIDTH   =4,
                SW_LOC             =V_GLOBAL/V,
                V_LOCAL            =V_GLOBAL%V;

    /* verilator lint_off WIDTH */ 
    localparam SSA_EN = ((ROUTE_TYPE == "FULL_ADAPTIVE") && (SS_PORT==2 || SS_PORT == 4) && ((1<<V_LOCAL &  ~ESCAP_VC_MASK ) != {V{1'b0}})) ? 1'b0 :1'b1;
	/* verilator lint_on WIDTH */ 	
      
               

    input   [Fw-1          :   0]  flit_in;
    input                          flit_in_we;
    input                          any_ovc_granted_in_ss_port;
    input                          any_ivc_sw_request_granted;
    input                          ovc_avalable_in_ss_port;
    input                          ivc_request; 
    input                          assigned_ovc_not_full;  
    input   [P_1-1        :    0]  dest_port;
    input                          assigned_to_ssovc;
    input                          ovc_is_assigned;
    
    output reg [V-1          :   0]  granted_ovc_num;
    output                        ivc_num_getting_sw_grant;
    output                        ivc_num_getting_ovc_grant;
    output                        ovc_released;
    output                        ovc_allocated;
    output                        ivc_reset;
    output                        decreased_credit_in_ss_ovc;

//synthesis translate_off 
//synopsys  translate_off
    input clk;
//synthesis translate_on
//synopsys  translate_on





  

/*
*    1) If no ivc is granted in the input port 
*    2) The ss output port is not granted for any other input port 
*    3) Incomming packet destionation port match with ss port
*    4) In non-atomic Vc reallocation check if IVC is empty 
*    5) The requested output VC is available in ss port 
* The predicted ports for each input potrt must be diffrent with the rest
*/

    
    
   
    wire    [P_1-1      :   0]  destport_in;
    wire    [V-1        :   0]  vc_num_in;
    wire                        hdr_flg;
    wire                        tail_flg;
    wire    [DEST_IN_HDR_WIDTH-1    :   0]  destport_hdr;
    wire                        condition_1_2_valid;   
   
    

   //extract header flit info
    assign destport_hdr= flit_in [(4*X_Y_IN_HDR_WIDTH)+DEST_IN_HDR_WIDTH-1      : 4*X_Y_IN_HDR_WIDTH];
    assign vc_num_in = flit_in [Fpay+V-1    :   Fpay];
    assign hdr_flg= flit_in [Fw-1];
    assign tail_flg=    flit_in   [Fw-2];
    assign destport_in= destport_hdr    [P_1-1    : 0];
    
    
    
   
    
    
    

// check condition 1 & 2
assign condition_1_2_valid = ~(any_ovc_granted_in_ss_port  | any_ivc_sw_request_granted);


//check destination port is ss
wire ss_port_hdr_flit, ss_port_nonhdr_flit;

generate 
/* verilator lint_off WIDTH */ 
if(ROUTE_TYPE=="DETERMINISTIC") begin :dtrm
/* verilator lint_on WIDTH */ 

    wire [P-1   :   0] dest_port_num,assigned_dest_port_num;
    
    // add switch loc to destination in
    add_sw_loc_one_hot #(
        .P(P),
        .SW_LOC(SW_LOC)    
    ) 
    conv1
    (
        .destport_in(destport_in),
        .destport_out(dest_port_num)
    );
    
    
    add_sw_loc_one_hot #(
        .P(P),
        .SW_LOC(SW_LOC)    
    ) 
    conv2
    (
        .destport_in(dest_port),
        .destport_out(assigned_dest_port_num)
    );

    assign ss_port_hdr_flit = dest_port_num [SS_PORT];
   
    assign ss_port_nonhdr_flit =  assigned_dest_port_num[SS_PORT];



end else begin :adaptv
/************************
        destination port is coded        
        destination-port_in
            x:  1 EAST, 0 WEST  
            y:  1 NORTH, 0 SOUTH
            ab: 00 : LOCAL, 10: xdir, 01: ydir, 11 x&y dir 
        sel:
             0: xdir
             1: ydir
        port_pre_sel
             0: xdir
             1: ydir  

************************/
 
               


wire  a,b,aa,bb;
assign {a,b} = destport_in[1:0];
assign {aa,bb} = dest_port[1:0];
    if( SS_PORT == LOCAL) begin :local_p
         assign ss_port_hdr_flit = 1'b0;
         assign ss_port_nonhdr_flit =   1'b0;
    end else if ((SS_PORT == EAST) || SS_PORT == WEST )begin :xdir
         assign ss_port_hdr_flit = a;
         assign ss_port_nonhdr_flit =   aa;
    end else begin
        assign ss_port_hdr_flit = b;
        assign ss_port_nonhdr_flit =   bb;
    end



//synthesis translate_off 
//synopsys  translate_off

if(DEBUG_EN) begin :dbg
	always @(posedge clk) begin
	   //if(!reset)begin 
			if(ivc_num_getting_sw_grant & aa & bb) $display("%t: SSA ERROR: There are two output ports that a non-header flit can be sent to. %m",$time);
	   //end
	end	
end //dbg

//synopsys  translate_on
//synthesis translate_on



end   //adaptive
endgenerate



// check if ss_ovc is ready
wire ss_ovc_ready;

wire assigned_ss_ovc_ready;
assign assigned_ss_ovc_ready= ss_port_nonhdr_flit & assigned_to_ssovc & assigned_ovc_not_full;
assign ss_ovc_ready = (ovc_is_assigned)?assigned_ss_ovc_ready : ovc_avalable_in_ss_port; 

// check if ssa is permited by input port

wire ssa_permited_by_iport;


generate
if (SSA_EN) begin : enable
	assign ssa_permited_by_iport = ss_ovc_ready & (~ivc_request) & condition_1_2_valid;  
end else begin : disabled
	assign ssa_permited_by_iport = 1'b0;
end
endgenerate

/*********************************
 check incomming packet conditions 
 *****************************/
 wire ss_vc_wr, decrease_credit_pre,allocate_ss_ovc_pre,release_ss_ovc_pre;
 assign ss_vc_wr = flit_in_we & vc_num_in[V_LOCAL];
 assign decrease_credit_pre= ~(hdr_flg & (~ss_port_hdr_flit));
 assign allocate_ss_ovc_pre= hdr_flg & ss_port_hdr_flit;
 assign release_ss_ovc_pre= tail_flg;


// generate output signals
assign decreased_credit_in_ss_ovc= decrease_credit_pre & ss_vc_wr & ssa_permited_by_iport;
assign ovc_released = release_ss_ovc_pre & ss_vc_wr & ssa_permited_by_iport;
assign ovc_allocated= allocate_ss_ovc_pre & ss_vc_wr & ssa_permited_by_iport;

assign ivc_reset =  ovc_released;
assign ivc_num_getting_sw_grant= decreased_credit_in_ss_ovc;
assign ivc_num_getting_ovc_grant= ovc_allocated;

 always @(*)begin
    granted_ovc_num={V{1'b0}};
    granted_ovc_num[V_LOCAL]= ivc_num_getting_ovc_grant;   
 end

   


endmodule






/**************************
            add_ss_port
If no output is granted replace the output port with ss one
**************************/
 

module add_ss_port #(   
    parameter SW_LOC=1,
    parameter P=5
)(
    destport_in,
    destport_out 
);
     localparam
        P_1     =   P-1,
        LOCAL   =   0,  
        EAST    =   1,
        NORTH   =   2, 
        WEST    =   3,
        SOUTH   =   4;



     localparam  SS_PORT_P5 = (SW_LOC== EAST   )? WEST-1 : // the sender port must be removed from destination port code  
                             (SW_LOC== NORTH  )? SOUTH-1: // the sender port must be removed from destination port code  
                             (SW_LOC== WEST   )? EAST  :
                                                 NORTH ; 

     localparam  SS_PORT_P3 =   1;   
                                 

     localparam  SS_PORT      =   (P==5) ? SS_PORT_P5: SS_PORT_P3;

        
    
     
    input       [P_1-1  :   0] destport_in;
    output reg  [P_1-1  :   0] destport_out; 
     
     
     
    always @(*)begin 
        destport_out=destport_in;
        if( SW_LOC != LOCAL ) begin 
            if(destport_in=={P_1{1'b0}}) destport_out[SS_PORT]= 1'b1;
        end    
    end 
     

endmodule



