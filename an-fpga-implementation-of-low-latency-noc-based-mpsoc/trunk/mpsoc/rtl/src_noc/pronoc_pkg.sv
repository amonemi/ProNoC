`timescale     1ns/1ps
/****************************************************************************
 * pronoc_pkg.sv
 ****************************************************************************/

package pronoc_pkg; 
  
  
`define NOC_LOCAL_PARAM
`include "noc_localparam.v"

`define  INCLUDE_TOPOLOGY_LOCALPARAM
`include "topology_localparam.v"
	
	

	

localparam
	Vw=  log2(V),
	Cw=  (C==0)? 1 : log2(C),
	NEw = log2(NE),
	Bw  = log2(B),	
	WRRA_CONFIG_INDEX=0,
	SMART_EN = (SMART_MAX !=0),
	SMART_NUM= (SMART_EN) ? SMART_MAX : 1,	
	NEV  = NE * V,
	T4 = 0,
	BEw = (BYTE_EN)? log2(Fpay/8) : 1,
	DELAYw = EAw+2; //Injector start delay counter width


 localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


 localparam 
 	E_SRC_LSB =0,                   E_SRC_MSB = E_SRC_LSB + EAw-1,
 	E_DST_LSB = E_SRC_MSB +1,       E_DST_MSB = E_DST_LSB + EAw-1,  
 	DST_P_LSB = E_DST_MSB + 1,      DST_P_MSB = DST_P_LSB + DSTPw-1, 
 	CLASS_LSB = DST_P_MSB + 1,      CLASS_MSB = CLASS_LSB + Cw -1, 
 	MSB_CLASS = (C>1)? CLASS_MSB : DST_P_MSB,
 	WEIGHT_LSB= MSB_CLASS + 1,      WEIGHT_MSB = WEIGHT_LSB + WEIGHTw -1,
 	/* verilator lint_off WIDTH */ 
 	MSB_W = (SWA_ARBITER_TYPE== "WRRA")? WEIGHT_MSB : MSB_CLASS,
 	/* verilator lint_on WIDTH */
 	BE_LSB =  MSB_W + 1,            BE_MSB = BE_LSB+ BEw-1,
 	MSB_BE = (BYTE_EN==1)?   BE_MSB  : MSB_W,
 	/* verilator lint_off WIDTH */ 
 	//the maximum data width that can be carried out with header flit
 	HDR_MAX_DATw = (PCK_TYPE == "SINGLE_FLIT")? Fpay : Fpay - MSB_BE -1;
 	/* verilator lint_on WIDTH */
 	
 	/* verilator lint_off WIDTH */ 
localparam 
	DISTw =  (TOPOLOGY=="FATTREE" || TOPOLOGY=="TREE" ) ? log2(2*L+1): log2(NR+1),
	OVC_ALLOC_MODE= (B<=4 && SSA_EN=="NO")?   1'b1 : 1'b0;
 	/* verilator lint_on WIDTH */ 
 	
 	// 0: The new ovc is allocated only if its not nearly full. Results in a simpler sw_mask_gen logic    
 	// 1: The new ovc is allocated only if its not full. Results in a little more complex sw_mask_gen logic    


 /******************
 *   vsa : Virtual channel & Switch allocator 
 *   local two-stage router allocator
 *****************/
 	typedef struct packed {
 		logic [V-1 : 0] ovc_is_allocated;
 		logic [V-1 : 0] ovc_is_released; 		
 		logic [V-1 : 0] ivc_num_getting_sw_grant; 
 		logic [V-1 : 0] ivc_num_getting_ovc_grant;
 		logic [V-1 : 0] ivc_reset;
 		logic [V-1 : 0] buff_space_decreased;
 		logic [V*V-1: 0] ivc_granted_ovc_num;
 	} vsa_ctrl_t;	
 	localparam  VSA_CTRL_w = $bits(vsa_ctrl_t);
 	
/*********************
* 	ssa : static straight allocator:
* 	      enable single cycle latency for flits goes to the same direction
**********************/ 	
 	
 	typedef struct packed {
 		logic [V-1 : 0] ovc_is_allocated;
 		logic [V-1 : 0] ovc_is_released; 		
 		logic [V-1 : 0] ivc_num_getting_sw_grant; 
 		logic [V-1 : 0] ivc_num_getting_ovc_grant;
 		logic [V-1 : 0] ivc_reset;
 		logic [V-1 : 0] buff_space_decreased;
 		logic [V-1 : 0] ivc_single_flit_pck;
 		logic [V-1 : 0] ovc_single_flit_pck;
 		bit      		ssa_flit_wr;
 		logic [V*V-1: 0] ivc_granted_ovc_num;
 	} ssa_ctrl_t;	
 	localparam  SSA_CTRL_w = $bits(ssa_ctrl_t);
 	
 	
/*********************
*    smart : straight bypass allocator:
*    enable multihub bypassing for flits goes to the same direction
*********************/
	typedef struct packed {
		logic [EAw-1 : 0] dest_e_addr;
		logic ovc_is_assigned;
		logic [Vw-1   : 0] assigned_ovc_bin;		
	} smart_ivc_info_t;
	localparam SMART_IVC_w = $bits(smart_ivc_info_t);
	
	
	
	typedef struct packed {
		bit		smart_en;
		bit     hdr_flit_req;
		logic 	[V-1 : 0]        ivc_smart_en;
		logic   [DSTPw-1  :   0] lk_destport;
		logic   [DSTPw-1  :   0] destport;
		logic   [V-1 : 0] credit_out;
		logic   [V-1 : 0] buff_space_decreased;
		logic   [V-1 : 0] ovc_is_allocated;
		logic   [V-1 : 0] ovc_is_released;		
		logic   [V-1 : 0] ivc_num_getting_ovc_grant;
		logic   [V-1 : 0] ivc_reset;
		logic   [V-1 : 0] mask_available_ovc;
		logic   [V-1 : 0] ivc_single_flit_pck;
		logic   [V-1 : 0] ovc_single_flit_pck;
		logic   [V*V-1: 0] ivc_granted_ovc_num;
	} smart_ctrl_t;	
	localparam  SMART_CTRL_w = $bits(smart_ctrl_t);
	
	/*****************
	 * port_info
	 * **************/
	typedef struct packed {
		logic [V-1 : 0] ivc_req; // input vc is not empty
		logic [V-1 : 0] swa_first_level_grant;// The vc number (one-hot) in an input port which get the first level switch allocator grant
		logic [V-1 : 0] swa_grant; // The VC number in an input port which got the swa grant
		logic [MAX_P-1 : 0] granted_oport_one_hot;	//The granted output port num (one-hot) for an input port	
		logic any_ivc_get_swa_grant;
		
	} iport_info_t;	
	localparam  IPORT_INFO_w = $bits(iport_info_t);
	
	typedef struct packed {
		logic [V-1 : 0] non_smart_ovc_is_allocated;
		//logic [V-1 : 0] ovc_is_released;
		//logic [V-1 : 0] ovc_credit_increased; 
		//logic [V-1 : 0] ovc_credit_decreased;
		//logic [V-1 : 0] ovc_avalable;
		bit any_ovc_granted;
		//bit crossbar_flit_wr;
			
	}oport_info_t;	
	localparam  OPORT_INFO_w = $bits(oport_info_t);
	

	
	
	
	/*********************
	 * ivc 
	 *******************/
		
	
	typedef struct packed {
		//ivc
		logic [EAw-1 : 0] dest_e_addr;
		logic ovc_is_assigned;
		logic [V-1   : 0] assigned_ovc_num;	
		logic [Vw-1  : 0] assigned_ovc_bin;
		logic [MAX_P-1   : 0] destport_one_hot;
		logic [DSTPw-1 : 0]  dest_port_encoded;
		logic ivc_req; // input vc is not empty
		logic flit_is_tail;
		logic assigned_ovc_not_full;
		logic [V-1  : 0] candidate_ovc;
		logic [Cw-1 : 0] class_num;			
		
	} ivc_info_t;
	localparam  IVC_INFO_w = $bits( ivc_info_t);
	
	localparam 	CREDITw  = (LB>B)?  log2(LB+1) : log2(B+1);
	
	//ovc info
	typedef struct packed {
		bit avalable; 
		bit status; //1 : is allocated 0 : not_allocated
		logic [CREDITw-1 : 0] credit;//available credit in OVC
		bit full;
		bit nearly_full;
		bit empty;
	}ovc_info_t;
	localparam  OVC_INFO_w = $bits( ovc_info_t);
	
	
	
    
	
/*********************
* router_chanels 
*********************/
	
	typedef struct packed {	
		logic [EAw-1 	: 0] src_e_addr;
		logic [EAw-1 	: 0] dest_e_addr;
		logic [DSTPw-1	: 0] destport;    
		logic [Cw-1		: 0] message_class;
		logic [WEIGHTw-1: 0] weight;
		logic [BEw-1 	: 0] be;		
	} hdr_flit_t;
	localparam HDR_FLIT_w = $bits(hdr_flit_t); 
	
	/* verilator lint_off WIDTH */
	localparam FPAYw = (PCK_TYPE == "SINGLE_FLIT")?   Fpay + MSB_BE: Fpay;    
	/* verilator lint_on WIDTH */
	
	typedef struct packed {
		bit hdr_flag;
		bit tail_flag;
		logic [V-1 : 0] vc;
		logic [FPAYw-1 : 0] payload;		
	} flit_t;
	localparam FLIT_w = $bits(flit_t); 
	
	localparam
		Fw = FLIT_w,
		NEFw = NE *Fw;	
	
	
	
	typedef struct packed {	
		logic  flit_wr;
		logic  [V-1 :  0]  credit;
		flit_t  flit;		
		logic  [CONGw-1 :  0]  congestion;		
	} flit_chanel_t;
	localparam FLIT_CHANEL_w = $bits(flit_chanel_t); 
	
	
	typedef struct packed {
		logic [SMART_NUM-1: 0] requests;
		logic [V-1   	: 0] ovc;		
		logic [EAw-1 	: 0] dest_e_addr;
		bit   hdr_flit;
	} smart_chanel_t;
	localparam SMART_CHANEL_w = $bits(smart_chanel_t);
	

	localparam CRDTw = (B>LB) ? log2(B+1) : log2(LB+1);
	typedef struct packed {
		logic [RAw-1:   0]  neighbors_r_addr;
		logic [V-1  :0] [CRDTw-1: 0] credit_init_val; // the connected port initial credit value. It is taken at reset time		
	} ctrl_chanel_t; 
	localparam CTRL_CHANEL_w = $bits(ctrl_chanel_t);
	
	typedef struct packed {
		flit_chanel_t    flit_chanel;
		smart_chanel_t   smart_chanel; 
		ctrl_chanel_t    ctrl_chanel;
	} smartflit_chanel_t;
	localparam SMARTFLIT_CHANEL_w = $bits(smartflit_chanel_t); 
	
	
	
	
/***********
 * simulation
 * **********/
 	typedef struct packed {
 		integer   ip_num;
		bit send_enable;
		integer  percentage; // x10	
 	} hotspot_t;
 	
 	typedef struct packed {
 		integer value;
 		integer percentage; 	
 	}rnd_discrete_t;
 	
 	//packet injector interface
 	localparam PCK_INJ_Dw =64;//TODO to be defined by user
 	localparam PCK_SIZw= log2(MAX_PCK_SIZ);
	
 	

 	typedef struct packed {
 		logic [PCK_INJ_Dw-1 : 0] data;
 		logic [PCK_SIZw-1 : 0] size;
 		logic [EAw-1 : 0] endp_addr; 
 		logic [Cw-1  : 0] class_num; 
 		logic [WEIGHTw-1   : 0] init_weight;
 		logic [V-1   : 0] vc;
 		bit   pck_wr;  	
 		bit   [V-1   : 0] ready;
 		logic [DISTw-1 : 0] distance;
 		logic [15: 0]  h2t_delay;
    }	pck_injct_t;
    localparam PCK_INJCT_w = $bits(pck_injct_t); 
    
 	
	
endpackage : pronoc_pkg


