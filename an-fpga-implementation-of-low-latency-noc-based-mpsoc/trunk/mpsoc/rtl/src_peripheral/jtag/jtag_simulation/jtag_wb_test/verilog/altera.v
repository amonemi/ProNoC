//synthesis translate_off
//synopsys  translate_off

`timescale 1 ps / 1 ps




`define IR_REGISTER_WIDTH 10;


// VIRTUAL JTAG MODULE CONSTANTS

// VIRTUAL JTAG MODULE CONSTANTS

// the default bit length for time and value
`define DEFAULT_BIT_LENGTH 32

// the bit length for type
`define TYPE_BIT_LENGTH 4

// the bit length for delay time
`define TIME_BIT_LENGTH 64

// the number of selection bits + width of hub instructions(3)
`define NUM_SELECTION_BITS 4

// the states for the parser state machine
`define STARTSTATE    3'b000
`define LENGTHSTATE   3'b001
`define VALUESTATE    3'b011
`define TYPESTATE     3'b111
`define TIMESTATE     3'b101

`define V_DR_SCAN_TYPE 4'b0010
`define V_IR_SCAN_TYPE 4'b0001

// specify time scale
`define CLK_PERIOD 100

`define DELAY_RESOLUTION 100


// the states for the tap controller state machine
`define TLR_ST  5'b00000
`define RTI_ST  5'b00001
`define DRS_ST  5'b00011
`define CDR_ST  5'b00111
`define SDR_ST  5'b01111
`define E1DR_ST 5'b01011
`define PDR_ST  5'b01101
`define E2DR_ST 5'b01000
`define UDR_ST  5'b01001
`define IRS_ST  5'b01100
`define CIR_ST  5'b01010
`define SIR_ST  5'b00101
`define E1IR_ST 5'b00100
`define PIR_ST  5'b00010
`define E2IR_ST 5'b00110
`define UIR_ST  5'b01110
`define INIT_ST 5'b10000

// usr1 instruction for tap controller
`define JTAG_USR1_INSTR 10'b0000001110

// MODULE DECLARATION
module sld_virtual_jtag (tdo,ir_out,tck,tdi,ir_in,virtual_state_cdr,virtual_state_sdr,
                        virtual_state_e1dr,virtual_state_pdr,virtual_state_e2dr,
                        virtual_state_udr,virtual_state_cir,virtual_state_uir,
                        jtag_state_tlr,jtag_state_rti,jtag_state_sdrs,jtag_state_cdr,
                        jtag_state_sdr,jtag_state_e1dr,jtag_state_pdr,jtag_state_e2dr,
                        jtag_state_udr,jtag_state_sirs,jtag_state_cir,jtag_state_sir,
                        jtag_state_e1ir,jtag_state_pir,jtag_state_e2ir,jtag_state_uir,
                        tms);


    // GLOBAL PARAMETER DECLARATION    
    parameter lpm_type = "SLD_VIRTUAL_JTAG"; // required by coding standard
    parameter lpm_hint = "SLD_VIRTUAL_JTAG"; // required by coding standard
    parameter sld_auto_instance_index = "NO"; //Yes if auto index is desired and no otherwise
    parameter sld_instance_index = 0; // index to be used if SLD_AUTO_INDEX is no
    parameter sld_ir_width = 1; //the width of the IR register
    parameter sld_sim_n_scan = 0; // the number of scans in the simulatiom parameters
    parameter sld_sim_total_length = 0; // The total bit width of all scan values
    parameter sld_sim_action = ""; // the actions to be simulated

    // local parameter declaration
    defparam  user_input.sld_node_ir_width = sld_ir_width;
    defparam  user_input.sld_node_n_scan = sld_sim_n_scan;
    defparam  user_input.sld_node_total_length = sld_sim_total_length;
    defparam  user_input.sld_node_sim_action = sld_sim_action;
    defparam  jtag.ir_register_width = 10 ;  // compilation fails if defined constant is used
    defparam  hub.sld_node_ir_width = sld_ir_width;
    
    
    // INPUT PORTS DECLARATION
    input   tdo;  // tdo signal into megafunction
    input [sld_ir_width - 1 : 0] ir_out;// parallel ir data into megafunction

    // OUTPUT PORTS DECLARATION
    output   tck;  // tck signal from megafunction
    output   tdi;  // tdi signal from megafunction
    output   virtual_state_cdr; // cdr state signal of megafunction
    output   virtual_state_sdr; // sdr state signal of megafunction
    output   virtual_state_e1dr;//  e1dr state signal of megafunction
    output   virtual_state_pdr; // pdr state signal of megafunction
    output   virtual_state_e2dr;// e2dr state signal of megafunction
    output   virtual_state_udr; // udr state signal of megafunction
    output   virtual_state_cir; // cir state signal of megafunction
    output   virtual_state_uir; // uir state signal of megafunction
    output   jtag_state_tlr;    // Test, Logic, Reset state
    output   jtag_state_rti;    // Run, Test, Idle state 
    output   jtag_state_sdrs;   // Select DR scan state
    output   jtag_state_cdr;    // capture DR state
    output   jtag_state_sdr;    // Shift DR state 
    output   jtag_state_e1dr;   // exit 1 dr state
    output   jtag_state_pdr;    // pause dr state 
    output   jtag_state_e2dr;   // exit 2 dr state
    output   jtag_state_udr;    // update dr state 
    output   jtag_state_sirs;   // Select IR scan state
    output   jtag_state_cir;    // capture IR state
    output   jtag_state_sir;    // shift IR state 
    output   jtag_state_e1ir;   // exit 1 IR state
    output   jtag_state_pir;    // pause IR state
    output   jtag_state_e2ir;   // exit 2 IR state 
    output   jtag_state_uir;    // update IR state
    output   tms;               // tms signal
    output [sld_ir_width - 1 : 0] ir_in; // paraller ir data from megafunction    

    // connecting wires
    wire   tck_i;
    wire   tms_i;
    wire   tdi_i;
    wire   jtag_usr1_i;
    wire   tdo_i;
    wire   jtag_tdo_i;
    wire   jtag_tck_i;
    wire   jtag_tms_i;
    wire   jtag_tdi_i;
    wire   jtag_state_tlr_i;
    wire   jtag_state_rti_i;
    wire   jtag_state_drs_i;
    wire   jtag_state_cdr_i;
    wire   jtag_state_sdr_i;
    wire   jtag_state_e1dr_i;
    wire   jtag_state_pdr_i;
    wire   jtag_state_e2dr_i;
    wire   jtag_state_udr_i;
    wire   jtag_state_irs_i;
    wire   jtag_state_cir_i;
    wire   jtag_state_sir_i;
    wire   jtag_state_e1ir_i;
    wire   jtag_state_pir_i;
    wire   jtag_state_e2ir_i;
    wire   jtag_state_uir_i;
    
    
    // COMPONENT INSTANTIATIONS 
    // generates input to jtag controller
    signal_gen user_input (tck_i,tms_i,tdi_i,jtag_usr1_i,tdo_i);

    // the JTAG TAP controller
    jtag_tap_controller jtag (tck_i,tms_i,tdi_i,jtag_tdo_i,
                                tdo_i,jtag_tck_i,jtag_tms_i,jtag_tdi_i,
                                jtag_state_tlr_i,jtag_state_rti_i,
                                jtag_state_drs_i,jtag_state_cdr_i,
                                jtag_state_sdr_i,jtag_state_e1dr_i,
                                jtag_state_pdr_i,jtag_state_e2dr_i,
                                jtag_state_udr_i,jtag_state_irs_i,
                                jtag_state_cir_i,jtag_state_sir_i,
                                jtag_state_e1ir_i,jtag_state_pir_i,
                                jtag_state_e2ir_i,jtag_state_uir_i,
                                jtag_usr1_i);

    // the HUB 
    dummy_hub hub (jtag_tck_i,jtag_tdi_i,jtag_tms_i,jtag_usr1_i,
                    jtag_state_tlr_i,jtag_state_rti_i,jtag_state_drs_i,
                    jtag_state_cdr_i,jtag_state_sdr_i,jtag_state_e1dr_i,
                    jtag_state_pdr_i,jtag_state_e2dr_i,jtag_state_udr_i,
                    jtag_state_irs_i,jtag_state_cir_i,jtag_state_sir_i,
                    jtag_state_e1ir_i,jtag_state_pir_i,jtag_state_e2ir_i,
                    jtag_state_uir_i,tdo,ir_out,jtag_tdo_i,tck,tdi,tms,
                    jtag_state_tlr,jtag_state_rti,jtag_state_sdrs,jtag_state_cdr,
                    jtag_state_sdr,jtag_state_e1dr,jtag_state_pdr,jtag_state_e2dr,
                    jtag_state_udr,jtag_state_sirs,jtag_state_cir,jtag_state_sir,
                    jtag_state_e1ir,jtag_state_pir,jtag_state_e2ir,jtag_state_uir,
                    virtual_state_cdr,virtual_state_sdr,virtual_state_e1dr,
                    virtual_state_pdr,virtual_state_e2dr,virtual_state_udr,
                    virtual_state_cir,virtual_state_uir,ir_in);

endmodule





module dummy_hub (jtag_tck,jtag_tdi,jtag_tms,jtag_usr1,jtag_state_tlr,jtag_state_rti,
                    jtag_state_drs,jtag_state_cdr,jtag_state_sdr,jtag_state_e1dr,
                    jtag_state_pdr,jtag_state_e2dr,jtag_state_udr,jtag_state_irs,
                    jtag_state_cir,jtag_state_sir,jtag_state_e1ir,jtag_state_pir,
                    jtag_state_e2ir,jtag_state_uir,dummy_tdo,virtual_ir_out,
                    jtag_tdo,dummy_tck,dummy_tdi,dummy_tms,dummy_state_tlr,
                    dummy_state_rti,dummy_state_drs,dummy_state_cdr,dummy_state_sdr,
                    dummy_state_e1dr,dummy_state_pdr,dummy_state_e2dr,dummy_state_udr,
                    dummy_state_irs,dummy_state_cir,dummy_state_sir,dummy_state_e1ir,
                    dummy_state_pir,dummy_state_e2ir,dummy_state_uir,virtual_state_cdr,
                    virtual_state_sdr,virtual_state_e1dr,virtual_state_pdr,virtual_state_e2dr,
                    virtual_state_udr,virtual_state_cir,virtual_state_uir,virtual_ir_in);


    // GLOBAL PARAMETER DECLARATION
    parameter sld_node_ir_width = 16;

    // INPUT PORTS
    
    input   jtag_tck;       // tck signal from tap controller
    input   jtag_tdi;       // tdi signal from tap controller
    input   jtag_tms;       // tms signal from tap controller
    input   jtag_usr1;      // usr1 signal from tap controller
    input   jtag_state_tlr; // tlr state signal from tap controller
    input   jtag_state_rti; // rti state signal from tap controller
    input   jtag_state_drs; // drs state signal from tap controller
    input   jtag_state_cdr; // cdr state signal from tap controller
    input   jtag_state_sdr; // sdr state signal from tap controller
    input   jtag_state_e1dr;// e1dr state signal from tap controller
    input   jtag_state_pdr; // pdr state signal from tap controller
    input   jtag_state_e2dr;// esdr state signal from tap controller
    input   jtag_state_udr; // udr state signal from tap controller
    input   jtag_state_irs; // irs state signal from tap controller
    input   jtag_state_cir; // cir state signals from tap controller
    input   jtag_state_sir; // sir state signal from tap controller
    input   jtag_state_e1ir;// e1ir state signal from tap controller
    input   jtag_state_pir; // pir state signals from tap controller
    input   jtag_state_e2ir;// e2ir state signal from tap controller
    input   jtag_state_uir; // uir state signal from tap controller
    input   dummy_tdo;      // tdo signal from world
    input [sld_node_ir_width - 1 : 0] virtual_ir_out; // captures parallel input from

    // OUTPUT PORTS
    output   jtag_tdo;             // tdo signal to tap controller
    output   dummy_tck;           // tck signal to world
    output   dummy_tdi;           // tdi signal to world
    output   dummy_tms;           // tms signal to world
    output   dummy_state_tlr;     // tlr state signal to world
    output   dummy_state_rti;     // rti state signal to world
    output   dummy_state_drs;     // drs state signal to world
    output   dummy_state_cdr;     // cdr state signal to world
    output   dummy_state_sdr;     // sdr state signal to world
    output   dummy_state_e1dr;    // e1dr state signal to the world
    output   dummy_state_pdr;     // pdr state signal to world
    output   dummy_state_e2dr;    // e2dr state signal to world
    output   dummy_state_udr;     // udr state signal to world
    output   dummy_state_irs;     // irs state signal to world
    output   dummy_state_cir;    // cir state signal to world
    output   dummy_state_sir;    // sir state signal to world
    output   dummy_state_e1ir;   // e1ir state signal to world
    output   dummy_state_pir;    // pir state signal to world
    output   dummy_state_e2ir;   // e2ir state signal to world
    output   dummy_state_uir;    // uir state signal to world
    output   virtual_state_cdr;  // virtual cdr state signal
    output   virtual_state_sdr;  // virtual sdr state signal
    output   virtual_state_e1dr; // virtual e1dr state signal 
    output   virtual_state_pdr;  // virtula pdr state signal 
    output   virtual_state_e2dr; // virtual e2dr state signal 
    output   virtual_state_udr;  // virtual udr state signal
    output   virtual_state_cir;  // virtual cir state signal 
    output   virtual_state_uir;  // virtual uir state signal
    output [sld_node_ir_width - 1 : 0] virtual_ir_in;      // parallel output to user design


`define SLD_NODE_IR_WIDTH_I sld_node_ir_width + `NUM_SELECTION_BITS // internal ir width    
   
    // INTERNAL REGISTERS
    reg   capture_ir;    // signals force_ir_capture instruction
    reg   jtag_tdo_reg;  // register for jtag_tdo
    reg   dummy_tdi_reg; // register for dummy_tdi
    reg   dummy_tck_reg; // register for dummy_tck.
    reg  [`SLD_NODE_IR_WIDTH_I - 1 : 0] ir_srl; // ir shift register
    wire [`SLD_NODE_IR_WIDTH_I - 1 : 0] ir_srl_tmp; // ir shift register
    reg  [`SLD_NODE_IR_WIDTH_I - 1 : 0] ir_srl_hold; //hold register for ir shift register  

    // OUTPUT REGISTERS
    reg [sld_node_ir_width - 1 : 0]     virtual_ir_in;     
    
    // INITIAL STATEMENTS 
    always @ (posedge jtag_tck or posedge jtag_state_tlr)
        begin : simulation_logic
            if (jtag_state_tlr) // asynchronous active high reset
                begin : active_hi_async_reset
                    ir_srl <= 'b0;
                    jtag_tdo_reg <= 1'b0;
                    dummy_tdi_reg <= 1'b0;        
                end  // active_hi_async_reset
            else
                begin : rising_edge_jtag_tck
                    // logic for shifting in data and piping data through        
                    // logic for muxing inputs to outputs and otherwise
                    if (jtag_usr1 && jtag_state_sdr)
                        begin : shift_in_out_usr1              
                            jtag_tdo_reg <= ir_srl_tmp[0];
                            ir_srl <= ir_srl_tmp >> 1;
                            ir_srl[`SLD_NODE_IR_WIDTH_I - 1] <= jtag_tdi;
                        end // shift_in_out_usr1
                    else
                        begin
                            if (capture_ir && jtag_state_cdr)
                                begin : capture_virtual_ir_out
                                    ir_srl[`SLD_NODE_IR_WIDTH_I - 2 : `NUM_SELECTION_BITS - 1] <= virtual_ir_out;
                                end // capture_virtual_ir_out
                            else
                                begin
                                    if (capture_ir && jtag_state_sdr)
                                        begin : shift_in_out_usr0                
                                            jtag_tdo_reg <= ir_srl_tmp[0];
                                            ir_srl <= ir_srl_tmp >> 1;
                                            ir_srl[`SLD_NODE_IR_WIDTH_I - 1] <= jtag_tdi;
                                        end // shift_in_out_usr0
                                    else
                                        begin
                                            if (jtag_state_sdr)
                                                begin : pipe_through
                                                    dummy_tdi_reg <= jtag_tdi;
                                                    jtag_tdo_reg <= dummy_tdo;
                                                end // pipe_through
                                        end
                                end
                        end                          
                end // rising_edge_jtag_tck
        end // simulation_logic

    // always block for writing to capture_ir
    // stops nlint from complaining.
    always @ (posedge jtag_tck or posedge jtag_state_tlr)
        begin : capture_ir_logic
            if (jtag_state_tlr) // asynchronous active high reset
                begin : active_hi_async_reset
                    capture_ir <= 1'b0;
                end  // active_hi_async_reset
            else
                begin : rising_edge_jtag_tck
                    // should check for 011 instruction
                    // but we know that it is the only instruction ever sent to the
                    // hub. So all we have to do is check the selection bit and udr
                    // and usr1 state
                    // logic for capture_ir signal
                    if (jtag_state_udr && (ir_srl[`SLD_NODE_IR_WIDTH_I - 1] == 1'b0))
                        begin
                            capture_ir <= jtag_usr1;
                        end
                    else
                        begin
                            if (jtag_state_e1dr)
                                begin
                                    capture_ir <= 1'b0;
                                end
                        end
                end  // rising_edge_jtag_tck
        end // capture_ir_logic
    
    // outputs -  rising edge of clock  
    always @ (posedge jtag_tck or posedge jtag_state_tlr)
        begin : parallel_ir_out
            if (jtag_state_tlr)
                begin : active_hi_async_reset
                    virtual_ir_in <= 'b0;
                end
            else
                begin : rising_edge_jtag_tck
                    virtual_ir_in <= ir_srl_hold[`SLD_NODE_IR_WIDTH_I - 2 : `NUM_SELECTION_BITS - 1];
                end
        end
    
    // outputs -  falling edge of clock, separated for clarity
    always @ (negedge jtag_tck or posedge jtag_state_tlr)
        begin : shift_reg_hold
            if (jtag_state_tlr)
                begin : active_hi_async_reset
                    ir_srl_hold <= 'b0;
                end
            else
                begin
                    if (ir_srl[`SLD_NODE_IR_WIDTH_I - 1] && jtag_state_e1dr)
                        begin
                            ir_srl_hold <= ir_srl;
                        end
                end
        end // shift_reg_hold

    // generate tck in sync with tdi
    always @ (posedge jtag_tck or negedge jtag_tck)
        begin : gen_tck
            dummy_tck_reg <= jtag_tck;
        end // gen_tck
    // temporary signals    
    assign ir_srl_tmp = ir_srl;
    
    // Pipe through signals
    assign dummy_state_tlr    = jtag_state_tlr;
    assign dummy_state_rti    = jtag_state_rti;
    assign dummy_state_drs    = jtag_state_drs;
    assign dummy_state_cdr    = jtag_state_cdr;
    assign dummy_state_sdr    = jtag_state_sdr;
    assign dummy_state_e1dr   = jtag_state_e1dr;
    assign dummy_state_pdr    = jtag_state_pdr;
    assign dummy_state_e2dr   = jtag_state_e2dr;
    assign dummy_state_udr    = jtag_state_udr;
    assign dummy_state_irs    = jtag_state_irs;
    assign dummy_state_cir    = jtag_state_cir;
    assign dummy_state_sir    = jtag_state_sir;
    assign dummy_state_e1ir   = jtag_state_e1ir;
    assign dummy_state_pir    = jtag_state_pir;
    assign dummy_state_e2ir   = jtag_state_e2ir;
    assign dummy_state_uir    = jtag_state_uir;
    assign dummy_tms          = jtag_tms;


    // Virtual signals
    assign virtual_state_uir  = jtag_usr1 && jtag_state_udr && ir_srl_hold[`SLD_NODE_IR_WIDTH_I - 1];
    assign virtual_state_cir  = jtag_usr1 && jtag_state_cdr && ir_srl_hold[`SLD_NODE_IR_WIDTH_I - 1];
    assign virtual_state_udr  = (! jtag_usr1) && jtag_state_udr && ir_srl_hold[`SLD_NODE_IR_WIDTH_I - 1];
    assign virtual_state_e2dr = (! jtag_usr1) && jtag_state_e2dr && ir_srl_hold[`SLD_NODE_IR_WIDTH_I - 1];
    assign virtual_state_pdr  = (! jtag_usr1) && jtag_state_pdr && ir_srl_hold[`SLD_NODE_IR_WIDTH_I - 1];
    assign virtual_state_e1dr = (! jtag_usr1) && jtag_state_e1dr && ir_srl_hold[`SLD_NODE_IR_WIDTH_I - 1];
    assign virtual_state_sdr  = (! jtag_usr1) && jtag_state_sdr && ir_srl_hold[`SLD_NODE_IR_WIDTH_I - 1];
    assign virtual_state_cdr  = (! jtag_usr1) && jtag_state_cdr && ir_srl_hold[`SLD_NODE_IR_WIDTH_I - 1];

    // registered output
    assign jtag_tdo = jtag_tdo_reg;              
    assign dummy_tdi = dummy_tdi_reg;    
    assign dummy_tck = dummy_tck_reg;
    
endmodule







module jtag_tap_controller (tck,tms,tdi,jtag_tdo,tdo,jtag_tck,jtag_tms,jtag_tdi,
                            jtag_state_tlr,jtag_state_rti,jtag_state_drs,jtag_state_cdr,
                            jtag_state_sdr,jtag_state_e1dr,jtag_state_pdr,jtag_state_e2dr,
                            jtag_state_udr,jtag_state_irs,jtag_state_cir,jtag_state_sir,
                            jtag_state_e1ir,jtag_state_pir,jtag_state_e2ir,jtag_state_uir,
                            jtag_usr1);


    // GLOBAL PARAMETER DECLARATION
    parameter ir_register_width = 16;

    // INPUT PORTS
    input     tck;  // tck signal from signal_gen
    input     tms;  // tms signal from signal_gen
    input     tdi;  // tdi signal from signal_gen
    input     jtag_tdo; // tdo signal from hub

    // OUTPUT PORTS
    output    tdo;  // tdo signal to signal_gen
    output    jtag_tck;  // tck signal from jtag
    output    jtag_tms;  // tms signal from jtag
    output    jtag_tdi;  // tdi signal from jtag
    output    jtag_state_tlr;   // tlr state
    output    jtag_state_rti;   // rti state
    output    jtag_state_drs;   // select dr scan state    
    output    jtag_state_cdr;   // capture dr state
    output    jtag_state_sdr;   // shift dr state    
    output    jtag_state_e1dr;  // exit1 dr state
    output    jtag_state_pdr;   // pause dr state
    output    jtag_state_e2dr;  // exit2 dr state 
    output    jtag_state_udr;   // update dr state
    output    jtag_state_irs;   // select ir scan state
    output    jtag_state_cir;   // capture ir state
    output    jtag_state_sir;   // shift ir state
    output    jtag_state_e1ir;  // exit1 ir state
    output    jtag_state_pir;   // pause ir state
    output    jtag_state_e2ir;  // exit2 ir state    
    output    jtag_state_uir;   // update ir state
    output    jtag_usr1;        // jtag has usr1 instruction

    // INTERNAL REGISTERS

    reg       tdo_reg;
    // temporary tdo output register
    reg       tdo_rom_reg;
    // temporary register used to generate 0101... during SIR_ST
    reg       jtag_usr1_reg;
    // temporary jtag_usr1 register
    reg       jtag_reset_i;
    // internal reset
    reg [ 4 : 0 ] cState;
    // register for current state
    reg [ 4 : 0 ] nState;
    // register for the next state signal
    reg [ ir_register_width - 1 : 0] ir_srl;
    // the ir shift register
    reg [ ir_register_width - 1 : 0] ir_srl_hold;
    // the ir shift register
    
    // INTERNAL WIRES
    wire [ 4 : 0 ] cState_tmp;
    wire [ ir_register_width - 1 : 0] ir_srl_tmp;


    // OUTPUT REGISTERS
    reg   jtag_state_tlr;   // tlr state
    reg   jtag_state_rti;   // rti state
    reg   jtag_state_drs;   // select dr scan state    
    reg   jtag_state_cdr;   // capture dr state
    reg   jtag_state_sdr;   // shift dr state    
    reg   jtag_state_e1dr;  // exit1 dr state
    reg   jtag_state_pdr;   // pause dr state
    reg   jtag_state_e2dr;  // exit2 dr state 
    reg   jtag_state_udr;   // update dr state
    reg   jtag_state_irs;   // select ir scan state
    reg   jtag_state_cir;   // capture ir state
    reg   jtag_state_sir;   // shift ir state
    reg   jtag_state_e1ir;  // exit1 ir state
    reg   jtag_state_pir;   // pause ir state
    reg   jtag_state_e2ir;  // exit2 ir state    
    reg   jtag_state_uir;   // update ir state
    

    // INITIAL STATEMENTS    
    initial
        begin
            // initialize state registers
            cState = `INIT_ST;
            nState = `TLR_ST;      
        end 

    // State Register block
    always @ (posedge tck or posedge jtag_reset_i)
        begin : stateReg
            if (jtag_reset_i)
                begin
                    cState <= `TLR_ST;
                    ir_srl <= 'b0;
                    tdo_reg <= 1'b0;
                    tdo_rom_reg <= 1'b0;
                    jtag_usr1_reg <= 1'b0;        
                end
            else
                begin
                    // in capture ir, set-up tdo_rom_reg
                    // to generate 010101...
                    if(cState_tmp == `CIR_ST)
                        begin                    
                            tdo_rom_reg <= 1'b0;
                        end
                    else
                        begin
                            // write to shift register else pipe
                            if (cState_tmp == `SIR_ST)
                                begin
                                    tdo_rom_reg <= ~tdo_rom_reg;
                                    tdo_reg <= tdo_rom_reg;              
                                    ir_srl <= ir_srl_tmp >> 1;
                                    ir_srl[ir_register_width - 1] <= tdi;
                                end
                            else
                                begin
                                    tdo_reg <= jtag_tdo;
                                end
                        end
                    // check if in usr1 state
                    if (cState_tmp == `UIR_ST)
                        begin
                            if (ir_srl_hold == `JTAG_USR1_INSTR)
                                begin
                                    jtag_usr1_reg <= 1'b1;                
                                end
                            else
                                begin
                                    jtag_usr1_reg <= 1'b0;
                                end              
                        end
                    cState <= nState;
                end
        end // stateReg               

    // hold register
    always @ (negedge tck or posedge jtag_reset_i)
        begin : holdReg
            if (jtag_reset_i)
                begin
                    ir_srl_hold <= 'b0;        
                end
            else
                begin
                    if (cState == `E1IR_ST)
                        begin
                            ir_srl_hold <= ir_srl;
                        end
                end
        end // holdReg               

    // next state logic
    always @(cState or tms)
        begin : stateTrans
            nState = cState;
            case (cState)
                `TLR_ST :
                    begin
                        if (tms == 1'b0)
                            begin
                                nState = `RTI_ST;
                                jtag_reset_i = 1'b0;
                            end
                        else
                            begin
                                jtag_reset_i = 1'b1;            
                            end
                    end
                `RTI_ST :
                    begin
                        if (tms)
                            begin
                                nState = `DRS_ST;
                            end          
                    end
                `DRS_ST :
                    begin
                        if (tms)
                            begin
                                nState = `IRS_ST;
                            end
                        else
                            begin
                                nState = `CDR_ST;
                            end
                    end
                `CDR_ST :
                    begin
                        if (tms)
                            begin
                                nState = `E1DR_ST;
                            end
                        else
                            begin
                                nState = `SDR_ST;
                            end
                    end
                `SDR_ST :
                    begin
                        if (tms)
                            begin
                                nState = `E1DR_ST;
                            end
                    end
                `E1DR_ST :
                    begin
                        if (tms)
                            begin
                                nState = `UDR_ST;
                            end
                        else
                            begin
                                nState = `PDR_ST;
                            end
                    end
                `PDR_ST :
                    begin
                        if (tms)
                            begin
                                nState = `E2DR_ST;
                            end
                    end
                `E2DR_ST :
                    begin
                        if (tms)
                            begin
                                nState = `UDR_ST;
                            end
                        else
                            begin
                                nState = `SDR_ST;
                            end
                    end
                `UDR_ST :
                    begin
                        if (tms)
                            begin
                                nState = `DRS_ST;
                            end
                        else
                            begin
                                nState = `RTI_ST;
                            end
                    end          
                `IRS_ST :
                    begin
                        if (tms)
                            begin
                                nState = `TLR_ST;
                            end
                        else
                            begin
                                nState = `CIR_ST;
                            end
                    end
                `CIR_ST :
                    begin
                        if (tms)
                            begin
                                nState = `E1IR_ST;
                            end
                        else
                            begin
                                nState = `SIR_ST;
                            end
                    end
                `SIR_ST :
                    begin
                        if (tms)
                            begin
                                nState = `E1IR_ST;
                            end
                    end
                `E1IR_ST :
                    begin
                        if (tms)
                            begin
                                nState = `UIR_ST;
                            end
                        else
                            begin
                                nState = `PIR_ST;
                            end
                    end
                `PIR_ST :
                    begin
                        if (tms)
                            begin
                                nState = `E2IR_ST;
                            end
                    end
                `E2IR_ST :
                    begin
                        if (tms)
                            begin
                                nState = `UIR_ST;
                            end
                        else
                            begin
                                nState = `SIR_ST;
                            end
                    end
                `UIR_ST : 
                    begin
                        if (tms)
                            begin
                                nState = `DRS_ST;
                            end
                        else
                            begin
                                nState = `RTI_ST;
                            end
                    end
                `INIT_ST :
                    begin
                        nState = `TLR_ST;
                    end
                default :
                    begin
                        $display("Tap Controller State machine error");
                        $display ("Time: %0t  Instance: %m", $time);
                        nState = `TLR_ST;          
                    end
            endcase
        end // stateTrans

    // Output logic
    always @ (cState)
        begin : output_logic
            jtag_state_tlr <= 1'b0;  
            jtag_state_rti <= 1'b0;  
            jtag_state_drs <= 1'b0;  
            jtag_state_cdr <= 1'b0;  
            jtag_state_sdr <= 1'b0;  
            jtag_state_e1dr <= 1'b0; 
            jtag_state_pdr <= 1'b0;  
            jtag_state_e2dr <= 1'b0; 
            jtag_state_udr <= 1'b0;  
            jtag_state_irs <= 1'b0;  
            jtag_state_cir <= 1'b0;  
            jtag_state_sir <= 1'b0;  
            jtag_state_e1ir <= 1'b0; 
            jtag_state_pir <= 1'b0;  
            jtag_state_e2ir <= 1'b0; 
            jtag_state_uir <= 1'b0;  
            case (cState)
                `TLR_ST :
                    begin
                        jtag_state_tlr <= 1'b1;
                    end
                `RTI_ST :
                    begin
                        jtag_state_rti <= 1'b1;
                    end
                `DRS_ST :
                    begin
                        jtag_state_drs <= 1'b1;
                    end
                `CDR_ST :
                    begin
                        jtag_state_cdr <= 1'b1;
                    end
                `SDR_ST :
                    begin
                        jtag_state_sdr <= 1'b1;
                    end
                `E1DR_ST :
                    begin
                        jtag_state_e1dr <= 1'b1;
                    end
                `PDR_ST :
                    begin
                        jtag_state_pdr <= 1'b1;
                    end
                `E2DR_ST :
                    begin
                        jtag_state_e2dr <= 1'b1;
                    end
                `UDR_ST :
                    begin
                        jtag_state_udr <= 1'b1;
                    end
                `IRS_ST :
                    begin
                        jtag_state_irs <= 1'b1;
                    end
                `CIR_ST :
                    begin
                        jtag_state_cir <= 1'b1;
                    end
                `SIR_ST :
                    begin
                        jtag_state_sir <= 1'b1;
                    end
                `E1IR_ST :
                    begin
                        jtag_state_e1ir <= 1'b1;
                    end
                `PIR_ST :
                    begin
                        jtag_state_pir <= 1'b1;
                    end
                `E2IR_ST :
                    begin
                        jtag_state_e2ir <= 1'b1;
                    end
                `UIR_ST :
                    begin
                        jtag_state_uir <= 1'b1;
                    end
                default :
                    begin
                        $display("Tap Controller State machine output error");
                        $display ("Time: %0t  Instance: %m", $time);
                    end
            endcase
        end // output_logic
    // temporary values
    assign ir_srl_tmp = ir_srl;
    assign cState_tmp = cState;    

    // Pipe through signals
    assign tdo = tdo_reg;
    assign jtag_tck = tck;
    assign jtag_tdi = tdi;
    assign jtag_tms = tms;
    assign jtag_usr1 = jtag_usr1_reg;
    
endmodule




// MODULE DECLARATION
module signal_gen (tck,tms,tdi,jtag_usr1,tdo);

    
    // GLOBAL PARAMETER DECLARATION
    parameter sld_node_ir_width = 1;
    parameter sld_node_n_scan = 0;
    parameter sld_node_total_length = 0;
    parameter sld_node_sim_action = "()";

    // INPUT PORTS
    input     jtag_usr1;
    input     tdo;
    
    // OUTPUT PORTS
    output    tck;
    output    tms;
    output    tdi;
    
    // CONSTANT DECLARATIONS
`define DECODED_SCANS_LENGTH (sld_node_total_length + ((sld_node_n_scan * `DEFAULT_BIT_LENGTH) * 2) + (sld_node_n_scan * `TYPE_BIT_LENGTH) - 1)
`define DEFAULT_SCAN_LENGTH (sld_node_n_scan * `DEFAULT_BIT_LENGTH)
`define TYPE_SCAN_LENGTH (sld_node_n_scan * `TYPE_BIT_LENGTH) - 1
    
    // INTEGER DECLARATION
    integer   char_idx;       // character_loop index
    integer   value_idx;      // decoding value index
    integer   value_idx_old;  // previous decoding value index   
    integer   value_idx_cur;  // reading/outputing value index   
    integer   length_idx;     // decoding length index
    integer   length_idx_old; // previous decoding length index
    integer   length_idx_cur; // reading/outputing length index
    integer   last_length_idx;// decoding previous length index
    integer   type_idx;       // decoding type index
    integer   type_idx_old;   // previous decoding type index
    integer   type_idx_cur;   // reading/outputing type index
    integer   time_idx;       // decoding time index
    integer   time_idx_old;   // previous decoding time index
    integer   time_idx_cur;   // reading/outputing time index

    // REGISTERS         
    reg [ `DEFAULT_SCAN_LENGTH - 1 : 0 ]    scan_length;
    // register for the 32-bit length values
    reg [ sld_node_total_length  - 1 : 0 ]  scan_values;
    // register for values   
    reg [ `TYPE_SCAN_LENGTH : 0 ]           scan_type;
    // register for 4-bit type 
    reg [ `DEFAULT_SCAN_LENGTH - 1 : 0 ]    scan_time;
    // register to hold time values
    reg [15 : 0]                            two_character; 
    // two ascii characters. Used in decoding
    reg [2 : 0]                             c_state;
    // the current state register 
    reg [3 : 0]                             hex_value;
    // temporary value to hold hex value of ascii character
    reg [31 : 0]                             last_length;
    // register to hold the previous length value read
    reg                                     tms_reg;
    // register to hold tms value before its clocked
    reg                                     tdi_reg;
    // register to hold tdi vale before its clocked
    
    // OUTPUT REGISTERS
    reg    tms;
    reg    tck;
    reg    tdi;

    // input registers
    
    // LOCAL TIME DECLARATION
    
    // FUNCTION DECLARATION
    
    // hexToBits - takes in a hexadecimal character and 
    // returns the 4-bit value of the character.
    // Returns 0 if character is not a hexadeciaml character    
    function [3 : 0]  hexToBits;
        input [7 : 0] character;
        begin
            case ( character )
                "0" : hexToBits = 4'b0000;
                "1" : hexToBits = 4'b0001;
                "2" : hexToBits = 4'b0010;
                "3" : hexToBits = 4'b0011;
                "4" : hexToBits = 4'b0100;
                "5" : hexToBits = 4'b0101;
                "6" : hexToBits = 4'b0110;                    
                "7" : hexToBits = 4'b0111;
                "8" : hexToBits = 4'b1000;
                "9" : hexToBits = 4'b1001;
                "A" : hexToBits = 4'b1010;
                "a" : hexToBits = 4'b1010;
                "B" : hexToBits = 4'b1011;
                "b" : hexToBits = 4'b1011;
                "C" : hexToBits = 4'b1100;
                "c" : hexToBits = 4'b1100;          
                "D" : hexToBits = 4'b1101;
                "d" : hexToBits = 4'b1101;
                "E" : hexToBits = 4'b1110;
                "e" : hexToBits = 4'b1110;
                "F" : hexToBits = 4'b1111;
                "f" : hexToBits = 4'b1111;          
                default :
                    begin 
                        hexToBits = 4'b0000;
                        $display("%s is not a hexadecimal value",character);
                    end
            endcase        
        end
    endfunction
    
    // TASK DECLARATIONS
    
    // clocks tck 
    task clock_tck;
        input in_tms;
        input in_tdi;    
        begin : clock_tck_tsk
            #(`CLK_PERIOD/2) tck <= ~tck;
            tms <= in_tms;
            tdi <= in_tdi;        
            #(`CLK_PERIOD/2) tck <= ~tck;
        end // clock_tck_tsk
    endtask // clock_tck
    
    // move tap controller from dr/ir shift state to ir/dr update state    
    task goto_update_state;
        begin : goto_update_state_tsk
            // get into e1(i/d)r state 
            tms_reg = 1'b1;
            clock_tck(tms_reg,tdi_reg);
            // get into u(i/d)r state
            tms_reg = 1'b1;
            clock_tck(tms_reg,tdi_reg);        
        end // goto_update_state_tsk
    endtask // goto_update_state
    
    // resets the jtag TAP controller by holding tms high 
    // for 6 tck cycles
    task reset_jtag;    
        integer idx;    
        begin
            for (idx = 0; idx < 6; idx= idx + 1)
                begin
                    tms_reg = 1'b1;          
                    clock_tck(tms_reg,tdi_reg);
                end
            // get into rti state
            tms_reg = 1'b0;        
            clock_tck(tms_reg,tdi_reg);
            jtag_ir_usr1;        
        end
    endtask // reset_jtag
    
    // sends a jtag_usr0 intsruction
    task jtag_ir_usr0;
        integer i;    
        begin : jtag_ir_usr0_tsk
            // get into drs state
            tms_reg = 1'b1;
            clock_tck(tms_reg,tdi_reg);
            // get into irs state
            tms_reg = 1'b1;
            clock_tck(tms_reg,tdi_reg);
            // get into cir state
            tms_reg = 1'b0;
            clock_tck(tms_reg,tdi_reg);
            // get into sir state
            tms_reg = 1'b0;
            clock_tck(tms_reg,tdi_reg);
            // shift in data i.e usr0 instruction
            // usr1 = 0x0E = 0b00 0000 1100
            for ( i = 0; i < 2; i = i + 1)
                begin :ir_usr0_loop1          
                    tdi_reg = 1'b0;
                    tms_reg = 1'b0;
                    clock_tck(tms_reg,tdi_reg);
                end // ir_usr0_loop1
            for ( i = 0; i < 2; i = i + 1)
                begin :ir_usr0_loop2          
                    tdi_reg = 1'b1;
                    tms_reg = 1'b0;
                    clock_tck(tms_reg,tdi_reg);
                end // ir_usr0_loop2
            // done with 1100
            for ( i = 0; i < 6; i = i + 1)
                begin :ir_usr0_loop3
                    tdi_reg = 1'b0;
                    tms_reg = 1'b0;
                    clock_tck(tms_reg,tdi_reg);
                end // ir_usr0_loop3
            // done  with 00 0000
            // get into e1ir state
            tms_reg = 1'b1;
            clock_tck(tms_reg,tdi_reg);        
            // get into uir state
            tms_reg = 1'b1;
            clock_tck(tms_reg,tdi_reg);        
        end // jtag_ir_usr0_tsk
    endtask // jtag_ir_usr0

    // sends a jtag_usr1 intsruction
    task jtag_ir_usr1;
        integer i;    
        begin : jtag_ir_usr1_tsk
            // get into drs state
            tms_reg = 1'b1;
            clock_tck(tms_reg,tdi_reg);
            // get into irs state
            tms_reg = 1'b1;
            clock_tck(tms_reg,tdi_reg);
            // get into cir state
            tms_reg = 1'b0;
            clock_tck(tms_reg,tdi_reg);
            // get into sir state
            tms_reg = 1'b0;
            clock_tck(tms_reg,tdi_reg);
            // shift in data i.e usr1 instruction
            // usr1 = 0x0E = 0b00 0000 1110
            tdi_reg = 1'b0;
            tms_reg = 1'b0;
            clock_tck(tms_reg,tdi_reg);
            for ( i = 0; i < 3; i = i + 1)
                begin :ir_usr1_loop1          
                    tdi_reg = 1'b1;
                    tms_reg = 1'b0;
                    clock_tck(tms_reg,tdi_reg);
                end // ir_usr1_loop1
            // done with 1110
            for ( i = 0; i < 5; i = i + 1)
                begin :ir_usr1_loop2
                    tdi_reg = 1'b0;
                    tms_reg = 1'b0;
                    clock_tck(tms_reg,tdi_reg);
                end // ir_sur1_loop2
            tdi_reg = 1'b0;
            tms_reg = 1'b1;
            clock_tck(tms_reg,tdi_reg);
            // done  with 00 0000
            // now in e1ir state
            // get into uir state
            tms_reg = 1'b1;
            clock_tck(tms_reg,tdi_reg);
        end // jtag_ir_usr1_tsk
    endtask // jtag_ir_usr1
    
    // sends a force_ir_capture instruction to the node
    task send_force_ir_capture;
        integer i;    
        begin : send_force_ir_capture_tsk
            goto_dr_shift_state;
            // start shifting in the instruction
            tdi_reg = 1'b1;
            tms_reg = 1'b0;
            clock_tck(tms_reg,tdi_reg);
            tdi_reg = 1'b1;
            tms_reg = 1'b0;
            clock_tck(tms_reg,tdi_reg);
            tdi_reg = 1'b0;
            tms_reg = 1'b0;
            clock_tck(tms_reg,tdi_reg);
            // done with 011
            tdi_reg = 1'b0;
            tms_reg = 1'b0;
            clock_tck(tms_reg,tdi_reg);
            // done with select bit
            // fill up with zeros up to ir_width
            for ( i = 0; i < sld_node_ir_width - 4; i = i + 1 )
                begin
                    tdi_reg = 1'b0;
                    tms_reg = 1'b0;
                    clock_tck(tms_reg,tdi_reg);
                end
            goto_update_state;        
        end // send_force_ir_capture_tsk    
    endtask // send_forse_ir_capture
    
    // puts the JTAG tap controller in DR shift state
    task goto_dr_shift_state;
        begin : goto_dr_shift_state_tsk
            // get into drs state
            tms_reg = 1'b1;
            clock_tck(tms_reg,tdi_reg);
            // get into cdr state
            tms_reg = 1'b0;
            clock_tck(tms_reg,tdi_reg);
            // get into sdr state
            tms_reg = 1'b0;
            clock_tck(tms_reg,tdi_reg);        
        end // goto_dr_shift_state_tsk    
    endtask // goto_dr_shift_state
    
    // performs a virtual_ir_scan
    task v_ir_scan;
        input [`DEFAULT_BIT_LENGTH - 1 : 0] length;    
        integer i;    
        begin : v_ir_scan_tsk
            // if we are not in usr1 then go to usr1 state
            if (jtag_usr1 == 1'b0)      
                begin
                    jtag_ir_usr1;
                end
            // send force_ir_capture
            send_force_ir_capture;
            // shift in the ir value
            goto_dr_shift_state;
            value_idx_cur = value_idx_cur - length;        
            for ( i = 0; i < length; i = i + 1)
                begin
                    tms_reg = 1'b0;
                    tdi_reg = scan_values[value_idx_cur + i];        
                    clock_tck(tms_reg,tdi_reg);
                end
            // pad with zeros if necessary
            for(i = length; i < sld_node_ir_width; i = i + 1)
                begin : zero_padding
                    tdi_reg = 1'b0;
                    tms_reg = 1'b0;
                    clock_tck(tms_reg,tdi_reg);          
                end //zero_padding
            tdi_reg = 1'b1;
            goto_update_state;
        end // v_ir_scan_tsk 
    endtask // v_ir_scan

    // performs a virtual dr scan
    task v_dr_scan;
        input [`DEFAULT_BIT_LENGTH - 1 : 0] length;    
        integer                             i;    
        begin : v_dr_scan_tsk
            // if we are in usr1 then go to usr0 state
            if (jtag_usr1 == 1'b1)      
                begin
                    jtag_ir_usr0;
                end
            // shift in the dr value
            goto_dr_shift_state;
            value_idx_cur = value_idx_cur - length;        
            for ( i = 0; i < length - 1; i = i + 1)
                begin
                    tms_reg = 1'b0;
                    tdi_reg = scan_values[value_idx_cur + i];
                    clock_tck(tms_reg,tdi_reg);
                end
            // last bit is clocked together with state transition
            tdi_reg = scan_values[value_idx_cur + i];        
            goto_update_state;
        end // v_dr_scan_tsk
    endtask // v_dr_scan
    
    initial 
        begin : sim_model      
            // initialize output registers
            tck = 1'b1;
            tms = 1'b0;
            tdi = 1'b0;      
            // initialize variables
            tms_reg = 1'b0;
            tdi_reg = 1'b0;      
            two_character = 'b0;
            last_length_idx = 0;      
            value_idx = 0;      
            value_idx_old = 0;      
            length_idx = 0;      
            length_idx_old = 0;
            type_idx = 0;
            type_idx_old = 0;
            time_idx = 0;
            time_idx_old = 0;      
            scan_length = 'b0;
            scan_values = 'b0;
            scan_type = 'b0;
            scan_time = 'b0;      
            last_length = 'b0;
            hex_value = 'b0;
            c_state = `STARTSTATE;      
            // initialize current indices
            value_idx_cur = sld_node_total_length;
            type_idx_cur = `TYPE_SCAN_LENGTH;
            time_idx_cur = `DEFAULT_SCAN_LENGTH;
            length_idx_cur = `DEFAULT_SCAN_LENGTH;      
            for(char_idx = 0;two_character != "((";char_idx = char_idx + 8)
                begin : character_loop
                    
		// convert two characters to equivalent 16-bit value
                    two_character[0]  = sld_node_sim_action[char_idx];
                    two_character[1]  = sld_node_sim_action[char_idx+1];
                    two_character[2]  = sld_node_sim_action[char_idx+2];
                    two_character[3]  = sld_node_sim_action[char_idx+3];
                    two_character[4]  = sld_node_sim_action[char_idx+4];
                    two_character[5]  = sld_node_sim_action[char_idx+5];
                    two_character[6]  = sld_node_sim_action[char_idx+6];
                    two_character[7]  = sld_node_sim_action[char_idx+7];
                    two_character[8]  = sld_node_sim_action[char_idx+8];
                    two_character[9]  = sld_node_sim_action[char_idx+9];
                    two_character[10] = sld_node_sim_action[char_idx+10];
                    two_character[11] = sld_node_sim_action[char_idx+11];
                    two_character[12] = sld_node_sim_action[char_idx+12];
                    two_character[13] = sld_node_sim_action[char_idx+13];
                    two_character[14] = sld_node_sim_action[char_idx+14];
                    two_character[15] = sld_node_sim_action[char_idx+15];        
                    // use state machine to decode
                    case (c_state)
                        `STARTSTATE :
                            begin 
                                if (two_character[15 : 8] != ")")
                                    begin 
                                        c_state = `LENGTHSTATE;
                                    end
                            end 
                        `LENGTHSTATE :
                            begin
                                if (two_character[7 : 0] == ",")
                                    begin
                                        length_idx = length_idx_old + 32;              
                                        length_idx_old = length_idx;              
                                        c_state = `VALUESTATE;
                                    end
                                else
                                    begin
                                        hex_value = hexToBits(two_character[7:0]);
                                        scan_length [ length_idx] = hex_value[0];
                                        scan_length [ length_idx + 1] = hex_value[1];
                                        scan_length [ length_idx + 2] = hex_value[2];
                                        scan_length [ length_idx + 3] = hex_value[3];              
                                        last_length [ last_length_idx] = hex_value[0];
                                        last_length [ last_length_idx + 1] = hex_value[1];
                                        last_length [ last_length_idx + 2] = hex_value[2];
                                        last_length [ last_length_idx + 3] = hex_value[3];              
                                        length_idx = length_idx + 4;
                                        last_length_idx = last_length_idx + 4;              
                                    end
                            end
                        `VALUESTATE :
                            begin
                                if (two_character[7 : 0] == ",")
                                    begin
                                        value_idx = value_idx_old + last_length;
                                        value_idx_old = value_idx;              
                                        last_length = 'b0; // reset the last length value
                                        last_length_idx = 0; // reset index for length                
                                        c_state = `TYPESTATE;  
                                    end
                                else
                                    begin
                                        hex_value = hexToBits(two_character[7:0]);
                                        scan_values [ value_idx] = hex_value[0];
                                        scan_values [ value_idx + 1] = hex_value[1];
                                        scan_values [ value_idx + 2] = hex_value[2];
                                        scan_values [ value_idx + 3] = hex_value[3];              
                                        value_idx = value_idx + 4;              
                                    end
                            end
                        `TYPESTATE :
                            begin
                                if (two_character[7 : 0] == ",")
                                    begin
                                        type_idx = type_idx + 4;              
                                        c_state = `TIMESTATE;              
                                    end
                                else
                                    begin
                                        hex_value = hexToBits(two_character[7:0]);
                                        scan_type [ type_idx] = hex_value[0];
                                        scan_type [ type_idx + 1] = hex_value[1];
                                        scan_type [ type_idx + 2] = hex_value[2];
                                        scan_type [ type_idx + 3] = hex_value[3];
                                    end
                            end
                        `TIMESTATE :
                            begin 
                                if (two_character[7 : 0] == "(")
                                    begin
                                        time_idx = time_idx_old + 32;
                                        time_idx_old = time_idx;              
                                        c_state = `STARTSTATE;
                                    end
                                else
                                    begin
                                        hex_value = hexToBits(two_character[7:0]);
                                        scan_time [ time_idx] = hex_value[0];
                                        scan_time [ time_idx + 1] = hex_value[1];
                                        scan_time [ time_idx + 2] = hex_value[2];
                                        scan_time [ time_idx + 3] = hex_value[3];
                                        time_idx = time_idx + 4;              
                                    end
                            end
                        default :
                            c_state = `STARTSTATE;          
                    endcase
                end // block: character_loop   
	   end // block: sim_model     

      integer write_scan_idx;    
                integer tempLength_idx;          
                reg [`TYPE_BIT_LENGTH - 1 : 0] tempType;        
                reg [`DEFAULT_BIT_LENGTH - 1 : 0 ] tempLength;                    
                reg [`DEFAULT_BIT_LENGTH - 1 : 0 ] tempTime;
                reg [`TIME_BIT_LENGTH - 1 : 0 ] delayTime;   

	initial begin : execute
         
           # (`CLK_PERIOD/2);
  
                           
                reset_jtag;
                for (write_scan_idx = 0; write_scan_idx < sld_node_n_scan; write_scan_idx = write_scan_idx + 1)
                    begin : all_scans_loop
                        tempType[3] = scan_type[type_idx_cur];
                        tempType[2] = scan_type[type_idx_cur - 1];
                        tempType[1] = scan_type[type_idx_cur - 2];
                        tempType[0] = scan_type[type_idx_cur - 3];
                        time_idx_cur = time_idx_cur - `DEFAULT_BIT_LENGTH;            
                        length_idx_cur = length_idx_cur - `DEFAULT_BIT_LENGTH;
                        for (tempLength_idx = 0; tempLength_idx < `DEFAULT_BIT_LENGTH; tempLength_idx = tempLength_idx + 1)
                            begin : get_scan_time
                                tempTime[tempLength_idx] = scan_time[time_idx_cur + tempLength_idx];                
                            end // get_scan_time
                            delayTime =(`DELAY_RESOLUTION * `CLK_PERIOD * tempTime);
                            # delayTime;            
                        if (tempType == `V_IR_SCAN_TYPE)
                            begin
                                for (tempLength_idx = 0; tempLength_idx < `DEFAULT_BIT_LENGTH; tempLength_idx = tempLength_idx + 1)
                                    begin : ir_get_length
                                        tempLength[tempLength_idx] = scan_length[length_idx_cur + tempLength_idx];                
                                    end // ir_get_length
                                v_ir_scan(tempLength);
                            end 
                        else
                            begin
                                if (tempType == `V_DR_SCAN_TYPE)
                                    begin                
                                        for (tempLength_idx = 0; tempLength_idx < `DEFAULT_BIT_LENGTH; tempLength_idx = tempLength_idx + 1)
                                            begin : dr_get_length
                                                tempLength[tempLength_idx] = scan_length[length_idx_cur + tempLength_idx];                
                                            end // dr_get_length
                                        v_dr_scan(tempLength);
                                    end
                                else
                                    begin
                                        $display("Invalid scan type");
                                    end
                            end
                        type_idx_cur = type_idx_cur - 4;
                    end // all_scans_loop            
                //get into tlr state
                for (tempLength_idx = 0; tempLength_idx < 6; tempLength_idx= tempLength_idx + 1)
                    begin
                        tms_reg = 1'b1;          
                        clock_tck(tms_reg,tdi_reg);
                    end
            end //execute      
     
endmodule // signal_gen


//synopsys  translate_on
//synthesis translate_on