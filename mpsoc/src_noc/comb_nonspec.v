`timescale	  1ns/1ps

/***************************************

        comb-nonspec
        
VC allocator combined with non-speculative switch
allocator where the free VC availability is checked at
the beginning of switch allocation (comb-nonspec).        


************************************/	

	
module comb_nonspec_allocator #(
				parameter	V				=	4,
				parameter 	P				=	5,
				parameter	FIRST_ARBITER_EXT_P_EN		=	1,
				parameter   	VC_ARBITER_TYPE="ROUND_ROBIN"		

)(
	//VC allocator
	//input 
	dest_port_all,         // from input port
    ovc_is_assigned_all,    // 
    masked_ovc_request_all,
    lk_destination_all,
    
	
	//output 
	ovc_allocated_all,//to the output port
	granted_ovc_num_all, // to the input port
	ivc_num_getting_ovc_grant,
	
	//switch_alloc
	ivc_request_all,
	assigned_ovc_not_full_all,
	
	//output
	granted_dest_port_all,
	ivc_num_getting_sw_grant,
	nonspec_first_arbiter_granted_ivc_all,
	any_ivc_sw_request_granted_all,
	
	// global
	clk,
	reset

);

    localparam      P_1	    =	P-1,
					PV		=	V	*	P,
					VV		=	V	*	V,
					VP_1	=	V	* 	P_1,				
					PP_1	=	P_1*	P,
					PVV	=	PV	*  V,
					PVP_1	=	PV	*	P_1;

					
	input  [PVV-1          :   0]  masked_ovc_request_all;
	input  [PVP_1-1		    :	0]	dest_port_all;
	input  [PV-1			:	0]	ovc_is_assigned_all;
	output [PV-1			:	0] ovc_allocated_all;
	output [PVV-1			:	0] granted_ovc_num_all;
	output [PV-1			:	0] ivc_num_getting_ovc_grant;
	input  [PV-1			:	0] ivc_request_all;
	input  [PV-1			:	0] assigned_ovc_not_full_all;
	output [PP_1-1			:	0]	granted_dest_port_all;
	output [PV-1			:	0] ivc_num_getting_sw_grant;
	output [P-1				:	0] any_ivc_sw_request_granted_all;
	output [PV-1			:	0] nonspec_first_arbiter_granted_ivc_all;
	input  [PVP_1-1         :   0] lk_destination_all;
	input						   clk,reset;


	//internal wires switch allocator
	wire   [PV-1				:	0]	first_arbiter_granted_ivc_all;
	wire   [PV-1				:	0] ivc_request_masked_all;
	wire   [P-1    				:	0] any_cand_ovc_exsit;
		
	assign nonspec_first_arbiter_granted_ivc_all = first_arbiter_granted_ivc_all;
	
	
	//nonspeculative switch allocator 
    nonspec_sw_alloc #(
		.V				(V),
		.P				(P),
		.FIRST_ARBITER_EXT_P_EN		(FIRST_ARBITER_EXT_P_EN)
	)nonspeculative_sw_allocator
	(

		.ivc_granted_all							(ivc_num_getting_sw_grant),
		.ivc_request_masked_all					(ivc_request_masked_all),
		.dest_port_all								(dest_port_all),
		.granted_dest_port_all					(granted_dest_port_all),
		.first_arbiter_granted_ivc_all		(first_arbiter_granted_ivc_all),
		.any_ivc_granted_all						(any_ivc_sw_request_granted_all),
		.clk											(clk),
		.reset										(reset)
	
	);
	
	
	
	wire   [PVV-1      :   0]  masked_ovc_request_all;
	wire   [V-1        :   0]  masked_non_assigned_request	[PV-1		:	0]	;	
	wire   [PV-1       :   0]  masked_assigned_request;
	wire   [PV-1       :   0]  assigned_ovc_request_all ;
	wire   [VV-1       :   0]  masked_candidate_ovc_per_port	[P-1		:	0]	;
	wire   [V-1        :   0]  first_arbiter_granted_ivc_per_port[P-1			:	0]	;
	wire   [V-1        :   0]  candidate_ovc_local_num			[P-1		:	0]	;
	wire   [V-1        :   0]  first_arbiter_ovc_granted		[PV-1		:	0];
	wire   [P_1-1      :   0]  granted_dest_port_per_port		[P-1		:	0];
	wire   [VP_1-1     :   0]  cand_ovc_granted					[P-1		:	0];
	wire   [P_1-1      :   0]  ovc_allocated_all_gen			[PV-1		:	0];
	wire   [V-1		   :   0]  granted_ovc_local_num_per_port     [P-1		:	0];
    wire   [V-1        :   0]  ivc_local_num_getting_ovc_grant[P-1		:	0];
	wire   [V          :   0]	summ_in						   [PV-1	:	0];
	wire   [V-1        :   0]   vc_pririty                     [PV-1    :   0] ;
	
	assign assigned_ovc_request_all      =   ivc_request_all &   ovc_is_assigned_all;
    	
	genvar i,j;
	
	
	generate 
	// IVC loop
	for(i=0;i< PV;i=i+1) begin :total_vc_loop
						
		// mask unavailable ovc from requests
		assign masked_non_assigned_request	[i]		=	masked_ovc_request_all [(i+1)*V-1   :   i*V ];
		assign masked_assigned_request		[i]		=	assigned_ovc_not_full_all[i] & assigned_ovc_request_all [i]; 
		
		// summing assigned and non-assigned VC requests
		assign summ_in[i]	={masked_non_assigned_request	[i],masked_assigned_request		[i]};
		assign ivc_request_masked_all[i] = | summ_in[i];
		
	
		//first level arbiter to candidate only one OVC 
		if(VC_ARBITER_TYPE=="ROUND_ROBIN")begin :round_robin
		  arbiter #(
		  .ARBITER_WIDTH	(V)
		  )ovc_arbiter
		  (	
			.clk		(clk), 
			.reset		(reset), 
			.request	(masked_non_assigned_request	[i]), 
			.grant		(first_arbiter_ovc_granted[i]),
			.any_grant	()
		  );
		end  else begin :fixarb
		
            vc_priority_based_dest_port#(
                .P(P),
                .V(V) 
    		 ) 
    		 priority_setting
    		 (
                .dest_port(lk_destination_all [((i+1)*P_1)-1          :   i*P_1]),
    		 	.vc_pririty(vc_pririty[i])
    		 );
		
		
		
            arbiter_ext_priority #(
		      .ARBITER_WIDTH (V)
            )
            ovc_arbiter
            ( 
			     .request (masked_non_assigned_request    [i]), 
			     .priority_in(vc_pririty[i]),
			     .grant(first_arbiter_ovc_granted[i]),
			     .any_grant()
		      ); 
		 
		 end
		
	
	end//for
	
	
	for(i=0;i< P;i=i+1) begin :port_loop3
			for(j=0;j< V;j=j+1) begin :vc_loop
				//merge masked_candidate_ovc in each port
				assign masked_candidate_ovc_per_port[i][(j+1)*V-1		:	j*V]	=	first_arbiter_ovc_granted	[i*V+j];
			end//for j
			
			assign first_arbiter_granted_ivc_per_port[i]=first_arbiter_granted_ivc_all[(i+1)*V-1		:	i*V];
			assign granted_dest_port_per_port[i]=granted_dest_port_all[(i+1)*P_1-1		:	i*P_1];
			
		
        // multiplex candidate OVC of first level switch allocatore winner	
		one_hot_mux #(
			.IN_WIDTH		(VV),
			.SEL_WIDTH  	(V)
		)
		multiplexer2
		(
			.mux_in			(masked_candidate_ovc_per_port	[i]),
			.mux_out			(candidate_ovc_local_num	[i]),
			.sel				(first_arbiter_granted_ivc_per_port		[i])

		);
		
		assign any_cand_ovc_exsit[i] = | candidate_ovc_local_num	[i];
	
		
		//demultiplexer		
		one_hot_demux	#(
			.IN_WIDTH	(V),
			.SEL_WIDTH	(P_1)
		)demux1
		(
			.demux_sel	(granted_dest_port_per_port [i]),//selectore
			.demux_in	(candidate_ovc_local_num[i]),//repeated
			.demux_out	(cand_ovc_granted [i])
		);
	
		assign granted_ovc_local_num_per_port	[i]=(any_ivc_sw_request_granted_all[i]	)?  candidate_ovc_local_num[i] : {V{1'b0}};
		assign ivc_local_num_getting_ovc_grant	[i]= (any_ivc_sw_request_granted_all[i] && any_cand_ovc_exsit[i])?	 first_arbiter_granted_ivc_per_port [i] : {V{1'b0}};
		assign ivc_num_getting_ovc_grant			[(i+1)*V-1	:	i*V] = ivc_local_num_getting_ovc_grant[i];
		for(j=0;j<V;	j=j+1)begin: assign_loop3
			assign granted_ovc_num_all[(i*VV)+((j+1)*V)-1	:	(i*VV)+(j*V)]=granted_ovc_local_num_per_port[i];
		end//j
	end//i
	
	
	for(i=0;i< PV;i=i+1) begin :total_vc_loop2
		for(j=0;j<P;	j=j+1)begin: assign_loop2
			if((i/V)<j )begin: jj
				assign ovc_allocated_all_gen[i][j-1]	= cand_ovc_granted[j][i];
			end else if((i/V)>j) begin: hh
				assign ovc_allocated_all_gen[i][j]	= cand_ovc_granted[j][i-V];
				
			end
		end//j
		
		assign ovc_allocated_all [i] = |ovc_allocated_all_gen[i];
		
	end//i
	
	endgenerate
	
	
endmodule	




/**************************************************************

             comb_nonspec_v2
            
first arbiter has been shifted after first multiplexer            


*********************************************************/

    
    
module  comb_nonspec_v2_allocator #(
                parameter   V               =   4,
                parameter   P               =   5,
                parameter   FIRST_ARBITER_EXT_P_EN      =   1
                

)(
    //VC allocator
    //input 
   
    dest_port_all,      // from input port
    ovc_is_assigned_all,    // 
    masked_ovc_request_all,
    
    //output 
    ovc_allocated_all,//to the output port
    granted_ovc_num_all, // to the input port
    ivc_num_getting_ovc_grant,
    
    //switch_alloc
    ivc_request_all,
    assigned_ovc_not_full_all,
    
    //output
    granted_dest_port_all,
    ivc_num_getting_sw_grant,
    nonspec_first_arbiter_granted_ivc_all,
    any_ivc_sw_request_granted_all,
    
    // global
    clk,
    reset

);

    localparam  P_1 =   P-1,
                    PV      =   V   *   P,
                    VV      =   V   *   V,
                    VP_1    =   V   *   P_1,                
                    PP_1    =   P_1*    P,
                    PVV =   PV  *  V,
                    PVP_1   =   PV  *   P_1;

                    
    input   [PVV-1          :   0]  masked_ovc_request_all;
    input   [PVP_1-1        :   0]  dest_port_all;
    input   [PV-1           :   0]  ovc_is_assigned_all;
    output  [PV-1           :   0]  ovc_allocated_all;
    output  [PVV-1          :   0]   granted_ovc_num_all;
    output  [PV-1           :   0]    ivc_num_getting_ovc_grant;
    input   [PV-1           :   0]    ivc_request_all;
    input   [PV-1           :   0]    assigned_ovc_not_full_all;
    output  [PP_1-1         :   0]  granted_dest_port_all;
    output [PV-1            :   0] ivc_num_getting_sw_grant;
    output [P-1             :   0] any_ivc_sw_request_granted_all;
    output [PV-1            :   0] nonspec_first_arbiter_granted_ivc_all;
    input                               clk,reset;


    //internal wires switch allocator
    wire    [PV-1               :   0]  first_arbiter_granted_ivc_all;
    wire    [PV-1               :   0] ivc_request_masked_all;
    wire    [P-1                :   0] any_cand_ovc_exsit;
     
    assign nonspec_first_arbiter_granted_ivc_all = first_arbiter_granted_ivc_all;
     
 //nonspeculative switch allocator    
 nonspec_sw_alloc #(
        .V              (V),
        .P              (P),
        .FIRST_ARBITER_EXT_P_EN     (FIRST_ARBITER_EXT_P_EN)
    )nonspeculative_sw_allocator
    (

        .ivc_granted_all                            (ivc_num_getting_sw_grant),
        .ivc_request_masked_all                 (ivc_request_masked_all),
        .dest_port_all                              (dest_port_all),
        .granted_dest_port_all                  (granted_dest_port_all),
        .first_arbiter_granted_ivc_all      (first_arbiter_granted_ivc_all),
        //.first_arbiter_granted_port_all   (first_arbiter_granted_port_all),
        .any_ivc_granted_all                        (any_ivc_sw_request_granted_all),
        .clk                                            (clk),
        .reset                                      (reset)
    
    );
    
    wire    [V-1     :   0]  masked_non_assigned_request [PV-1       :   0]  ;   
    wire    [PV-1    :   0]  masked_assigned_request;
    wire    [PV-1    :   0]  assigned_ovc_request_all;
    wire    [VV-1    :   0]  masked_non_assigned_request_per_port [P-1       :   0]  ;
    wire    [V-1     :   0]  first_arbiter_granted_ivc_per_port[P-1          :   0]  ;
    wire    [V-1     :   0]  candidate_ovc_local_num         [P-1        :   0]  ;
    wire    [V-1     :   0] first_arbiter_ovc_granted [P-1:0];
    wire    [P_1-1   :   0]  granted_dest_port_per_port      [P-1        :   0];
    wire    [VP_1-1  :   0] cand_ovc_granted                 [P-1        :   0];
    wire    [P_1-1   :   0]  ovc_allocated_all_gen           [PV-1       :   0];
    wire    [V-1       :   0]  granted_ovc_local_num_per_port [P-1     :   0];
    wire    [V-1       :   0]  ivc_local_num_getting_ovc_grant[P-1     :   0];
    wire    [V         :   0]  summ_in                              [PV-1  :   0];
    
    
    assign assigned_ovc_request_all        =   ivc_request_all &   ovc_is_assigned_all;
    
    genvar i,j;
    generate 
   
    // IVC loop
    for(i=0;i< PV;i=i+1) begin :total_vc_loop
                
        // mask unavailable ovc from requests
        assign masked_non_assigned_request  [i]     =   masked_ovc_request_all [(i+1)*V-1   :   i*V ];
        assign masked_assigned_request      [i]     =   assigned_ovc_not_full_all[i] & assigned_ovc_request_all[i]; 
        
        // summing assigned and non-assigned VC requests
        assign summ_in[i]   ={masked_non_assigned_request   [i],masked_assigned_request     [i]};
        assign ivc_request_masked_all[i] = | summ_in[i];
        
    end//for
    
    
    for(i=0;i< P;i=i+1) begin :port_loop3
            for(j=0;j< V;j=j+1) begin :vc_loop
                //merge masked_candidate_ovc in each port
                assign masked_non_assigned_request_per_port[i][(j+1)*V-1        :   j*V]    =           masked_non_assigned_request [i*V+j];
            end//for j
            
            assign first_arbiter_granted_ivc_per_port[i]=first_arbiter_granted_ivc_all[(i+1)*V-1        :   i*V];
            
            assign granted_dest_port_per_port[i]=granted_dest_port_all[(i+1)*P_1-1      :   i*P_1];
            
            
        one_hot_mux #(
            .IN_WIDTH       (VV),
            .SEL_WIDTH      (V)
        )
        multiplexer2
        (
            .mux_in             (masked_non_assigned_request_per_port   [i]),
            .mux_out            (candidate_ovc_local_num    [i]),
            .sel                (first_arbiter_granted_ivc_per_port     [i])

        );
        
        
        assign any_cand_ovc_exsit[i] = | candidate_ovc_local_num    [i];
    
        //first level arbiter to candidate only one OVC 
        arbiter #(
            .ARBITER_WIDTH  (V)
        )first_arbiter
        (   
            .clk            (clk), 
            .reset      (reset), 
            .request        (candidate_ovc_local_num[i]), 
            .grant      (first_arbiter_ovc_granted[i]),
            .any_grant   ()
        );
    
        
        //demultiplexer
        one_hot_demux   #(
            .IN_WIDTH   (V),
            .SEL_WIDTH  (P_1)
        )demux1
        (
            .demux_sel  (granted_dest_port_per_port [i]),//selectore
            .demux_in   (first_arbiter_ovc_granted[i]),//repeated
            .demux_out  (cand_ovc_granted [i])
        );
    
          
        assign granted_ovc_local_num_per_port   [i]=(any_ivc_sw_request_granted_all[i]  )?  first_arbiter_ovc_granted[i] : {V{1'b0}};
        assign ivc_local_num_getting_ovc_grant  [i]= (any_ivc_sw_request_granted_all[i] && any_cand_ovc_exsit[i])?   first_arbiter_granted_ivc_per_port [i] : {V{1'b0}};
        assign ivc_num_getting_ovc_grant            [(i+1)*V-1  :   i*V] = ivc_local_num_getting_ovc_grant[i];
        for(j=0;j<V;    j=j+1)begin: assign_loop3
            assign granted_ovc_num_all[(i*VV)+((j+1)*V)-1   :   (i*VV)+(j*V)]=granted_ovc_local_num_per_port[i];
        end//j
    end//i
    
    
    for(i=0;i< PV;i=i+1) begin :total_vc_loop2
        for(j=0;j<P;    j=j+1)begin: assign_loop2
            if((i/V)<j )begin: jj
                assign ovc_allocated_all_gen[i][j-1]    = cand_ovc_granted[j][i];
            end else if((i/V)>j) begin: hh
                assign ovc_allocated_all_gen[i][j]  = cand_ovc_granted[j][i-V];
                
            end
        end//j
        
        assign ovc_allocated_all [i] = |ovc_allocated_all_gen[i];
        
    end//i
    
    endgenerate
    
    
endmodule   


/********************************************

    nonspeculative switch allocator

******************************************/

module nonspec_sw_alloc #(
                parameter   V               =   4,
                parameter   P               =   5,
                parameter   FIRST_ARBITER_EXT_P_EN      =   1   

)(

    ivc_granted_all,
    ivc_request_masked_all,
    dest_port_all,
    granted_dest_port_all,
    first_arbiter_granted_ivc_all,
    //first_arbiter_granted_port_all,
    any_ivc_granted_all,
    clk,
    reset
    
);

   

    localparam  P_1     =   P-1,//assumed that no port request for itself!
                    PV          =   V   *   P,
                    VP_1        =   V   *   P_1,                
                    PVP_1       =   P   *   VP_1,   
                    PP_1        =   P_1*    P;
                    

    output [PV-1        :   0]  ivc_granted_all;
    input  [PV-1        :   0] ivc_request_masked_all;
    input  [PVP_1-1 :   0]  dest_port_all;
    output [PP_1-1      :   0]  granted_dest_port_all;
    output [PV-1        :   0]  first_arbiter_granted_ivc_all;
    //output [PP_1-1        :   0]  first_arbiter_granted_port_all;
    output [P-1         :   0]  any_ivc_granted_all;
    input                           clk;
    input                           reset;
    
    //separte input per port
    wire    [V-1        :   0]  ivc_granted                 [P-1            :   0];
    wire    [VP_1-1     :   0] dest_port_ivc                [P-1            :   0];
    wire    [P_1-1      :   0]  granted_dest_port           [P-1            :   0];
    
    // internal wires
    wire    [V-1        :   0] ivc_masked                   [P-1            :   0];//output of mask and             
    wire    [V-1        :   0] first_arbiter_grant      [P-1            :   0];//output of first arbiter            
    wire    [P_1-1      :   0]  dest_port               [P-1            :   0];//output of multiplexer
    wire    [P_1-1      :   0]  second_arbiter_request  [P-1            :   0]; 
    wire    [P_1-1      :   0]  second_arbiter_grant    [P-1            :   0];             
     
    genvar i,j;
    generate
    
    for(i=0;i< P;i=i+1) begin :port_loop
        //assign in/out to the port based wires
        //output
        assign ivc_granted_all          [(i+1)*V-1  :   i*V]    =   ivc_granted [i];
        assign granted_dest_port_all    [(i+1)*P_1-1        :   i*P_1]      =   granted_dest_port[i];
        assign first_arbiter_granted_ivc_all[(i+1)*V-1  :   i*V]=           first_arbiter_grant[i];
        //input 
        assign ivc_masked[i]            = ivc_request_masked_all [(i+1)*V-1     :   i*V];
        assign dest_port_ivc[i]     = dest_port_all [(i+1)*VP_1-1   :   i*VP_1];
        
        //first level arbiter
    if(FIRST_ARBITER_EXT_P_EN==1) begin : first_lvl_arbiter_ext_en

        arbiter_priority_en #(
            .ARBITER_WIDTH  (V)
        )first_arbiter
        (   
            .clk        (clk), 
            .reset      (reset), 
            .request    (ivc_masked [i]), 
            .grant      (first_arbiter_grant[i]),
            .any_grant   (),
            .priority_en(any_ivc_granted_all[i])        
        );
 
    end else  begin: first_lvl_arbiter_internal_en
        arbiter #(
            .ARBITER_WIDTH  (V)
        )first_arbiter
        (   
            .clk            (clk), 
            .reset      (reset), 
            .request        (ivc_masked [i]), 
            .grant      (first_arbiter_grant[i]),
            .any_grant   ()
        );
    end//else
        
    //destination port multiplexer
     one_hot_mux #(
        .IN_WIDTH       (VP_1),
        .SEL_WIDTH      (V)
    )
    multiplexer
    (
        .mux_in (dest_port_ivc  [i]),
        .mux_out    (dest_port      [i]),
        .sel        (first_arbiter_grant[i])

    );
    
    //second arbiter input/output generate


    for(j=0;j<P;    j=j+1)begin: assign_loop
            if(i<j)begin: jj
                assign second_arbiter_request[i][j-1]   = dest_port[j][i]   ;
                assign granted_dest_port[j][i]  = second_arbiter_grant  [i][j-1]    ;
            end else if(i>j)begin: hh
                assign second_arbiter_request[i][j] = dest_port [j][i-1]    ;
                assign granted_dest_port[j][i-1]    = second_arbiter_grant  [i][j]  ;
            end
            //if(i==j) wires are left disconnected  
        
        end
    
        
        //second level arbiter 
        
        arbiter #(
            .ARBITER_WIDTH  (P_1)
        )second_arbiter
        (   
            .clk        (clk), 
            .reset      (reset), 
            .request    (second_arbiter_request[i]), 
            .grant      (second_arbiter_grant  [i]),
            .any_grant   ()
        );
        
        //any ivc 
        assign  any_ivc_granted_all[i] = | granted_dest_port[i];
        assign  ivc_granted[i] =  (any_ivc_granted_all[i]) ? first_arbiter_grant[i] : {V{1'b0}};

       
    end//for
    endgenerate 
        
    
endmodule

