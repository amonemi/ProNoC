`timescale     1ns/1ps

module combined_vc_sw_alloc #(
    parameter  V                        =    4,    //VC number per port
    parameter  P                        =    5, //port number
    parameter  COMBINATION_TYPE        =    "BASELINE",// "BASELINE", "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
    parameter  FIRST_ARBITER_EXT_P_EN    =    1,
    parameter  ROUTE_TYPE           =   "DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter  [V-1  :   0] ESCAP_VC_MASK = 4'b1000,   // mask scape vc, valid only for full adaptive
    parameter  DEBUG_EN             =   1
)
(

    dest_port_all,
    masked_ovc_request_all,
    ovc_is_assigned_all,
    ivc_request_all,
    assigned_ovc_not_full_all,
    ovc_allocated_all,
    granted_ovc_num_all,
    ivc_num_getting_ovc_grant,
    ivc_num_getting_sw_grant,
    spec_first_arbiter_granted_ivc_all,
    nonspec_first_arbiter_granted_ivc_all,
    granted_dest_port_all,
    nonspec_granted_dest_port_all,
    spec_granted_dest_port_all,
    any_ivc_sw_request_granted_all,
    any_ovc_granted_in_outport_all,
    spec_ovc_num_all,
    lk_destination_all, 
    clk,
    reset

);




    localparam  PV      =    V        *    P,
                PVV     =    PV        *  V,    
                P_1        =    P-1    ,
                PP_1    =    P_1    *    P,
                PVP_1    =    PV        *    P_1;

                    
                    
    input  [PVP_1-1            :    0] dest_port_all;
    input  [PVV-1           :   0] masked_ovc_request_all;    
    input  [PV-1            :    0] ovc_is_assigned_all;
    input  [PV-1            :    0] ivc_request_all;
    input  [PV-1            :    0] assigned_ovc_not_full_all;
    
    
    output [PV-1            :    0] ovc_allocated_all;
    output [PVV-1            :    0] granted_ovc_num_all;
    output [PV-1            :    0] ivc_num_getting_ovc_grant;
    output [PV-1            :    0] ivc_num_getting_sw_grant;
    output [PV-1            :    0] nonspec_first_arbiter_granted_ivc_all;
    output [PV-1            :    0] spec_first_arbiter_granted_ivc_all;
    output [P-1                :    0] any_ivc_sw_request_granted_all;
    output [P-1             :   0] any_ovc_granted_in_outport_all;    
    output [PP_1-1            :    0] granted_dest_port_all;
    output [PP_1-1            :    0] nonspec_granted_dest_port_all;
    output [PP_1-1            :    0] spec_granted_dest_port_all; 
    output [PVV-1            :    0] spec_ovc_num_all;
    input  [PVP_1-1         :   0] lk_destination_all;
    
    input                                clk,reset;

    generate
    if(COMBINATION_TYPE    ==    "BASELINE") begin : canonical_comb_gen

        baseline_allocator #(
            .V(V),    
            .P(P),                        
            .TREE_ARBITER_EN(1),
            .DEBUG_EN(DEBUG_EN)            
        )
        the_base_line
        (
            .dest_port_all(dest_port_all), 
            .masked_ovc_request_all(masked_ovc_request_all),
            .ovc_is_assigned_all(ovc_is_assigned_all), 
            .ivc_request_all(ivc_request_all), 
            .assigned_ovc_not_full_all(assigned_ovc_not_full_all), 
            .ovc_allocated_all(ovc_allocated_all), 
            .granted_ovc_num_all(granted_ovc_num_all), 
            .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
            .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
            .spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all), 
            .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
            .granted_dest_port_all(granted_dest_port_all),
            .nonspec_granted_dest_port_all(nonspec_granted_dest_port_all), 
            .spec_granted_dest_port_all(spec_granted_dest_port_all), 
            .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
            .spec_ovc_num_all(spec_ovc_num_all),
            .clk(clk), 
            .reset(reset)
        
        );

    end else if(COMBINATION_TYPE    ==    "COMB_SPEC1") begin : spec1
    
        comb_spec1_allocator #(
            .V(V),    
            .P(P),
            .DEBUG_EN(DEBUG_EN)
        )
        the_comb_spec1
        (
            .dest_port_all(dest_port_all), 
            .masked_ovc_request_all(masked_ovc_request_all),
            .ovc_is_assigned_all(ovc_is_assigned_all), 
            .ivc_request_all(ivc_request_all), 
            .assigned_ovc_not_full_all(assigned_ovc_not_full_all), 
            .ovc_allocated_all(ovc_allocated_all), 
            .granted_ovc_num_all(granted_ovc_num_all), 
            .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
            .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
            .spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all), 
            .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
            .granted_dest_port_all(granted_dest_port_all), 
            .nonspec_granted_dest_port_all(nonspec_granted_dest_port_all), 
            .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
               .clk(clk), 
            .reset(reset)
        );
        
        
        assign spec_granted_dest_port_all        = {PP_1{1'bx}};
        assign spec_ovc_num_all                        = {PVV{1'bx}};
    end else if (COMBINATION_TYPE    == "COMB_SPEC2") begin :spec2

            comb_spec2_allocator #(
                .V(V),    
                .P(P),
                .DEBUG_EN(DEBUG_EN) 
            )the_comb_spec2
            (
                .dest_port_all(dest_port_all), 
                .masked_ovc_request_all(masked_ovc_request_all),
                .ovc_is_assigned_all(ovc_is_assigned_all), 
                .ivc_request_all(ivc_request_all), 
                .assigned_ovc_not_full_all(assigned_ovc_not_full_all), 
                .ovc_allocated_all(ovc_allocated_all), 
                .granted_ovc_num_all(granted_ovc_num_all), 
                .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
                .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
                .spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all), 
                .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
                .granted_dest_port_all(granted_dest_port_all), 
                .nonspec_granted_dest_port_all(nonspec_granted_dest_port_all), 
                .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
                .clk(clk), 
                .reset(reset)
            );
            assign spec_granted_dest_port_all        = {PP_1{1'bx}};
            assign spec_ovc_num_all                        = {PVV{1'bx}};

    
    end else begin :      nonspec
        if(V>7)begin :cmb_v2
             comb_nonspec_v2_allocator #(
                .V(V),    
                .P(P),
                .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN)
            )nonspec_comb
            (
                .dest_port_all(dest_port_all), 
                .masked_ovc_request_all(masked_ovc_request_all),
                .ovc_is_assigned_all(ovc_is_assigned_all),
                .ivc_request_all(ivc_request_all), 
                .assigned_ovc_not_full_all(assigned_ovc_not_full_all),     
                .ovc_allocated_all(ovc_allocated_all), 
                .granted_ovc_num_all(granted_ovc_num_all), 
                .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
                .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
                .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
                .granted_dest_port_all(granted_dest_port_all), 
                .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
                .any_ovc_granted_in_outport_all(any_ovc_granted_in_outport_all),
                .clk(clk), 
                .reset(reset)
            );
        end else begin :cmb_v1
             comb_nonspec_allocator #(
                .V(V),    
                .P(P),
                .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN)
            )
            nonspec_comb
            (
                .dest_port_all(dest_port_all), 
                .masked_ovc_request_all(masked_ovc_request_all),
                .ovc_is_assigned_all(ovc_is_assigned_all),
                .ivc_request_all(ivc_request_all), 
                .assigned_ovc_not_full_all(assigned_ovc_not_full_all),     
                .ovc_allocated_all(ovc_allocated_all), 
                .granted_ovc_num_all(granted_ovc_num_all), 
                .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
                .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
                .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
                .granted_dest_port_all(granted_dest_port_all), 
                .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all),
                .any_ovc_granted_in_outport_all(any_ovc_granted_in_outport_all),
                .lk_destination_all(lk_destination_all),
                .clk(clk), 
                .reset(reset)
            );
        end
        assign nonspec_granted_dest_port_all      = granted_dest_port_all;
        assign spec_granted_dest_port_all         = {PP_1{1'bx}};
        assign spec_ovc_num_all                      = {PVV{1'bx}};
        assign spec_first_arbiter_granted_ivc_all =  nonspec_first_arbiter_granted_ivc_all ;
    end
endgenerate
endmodule
