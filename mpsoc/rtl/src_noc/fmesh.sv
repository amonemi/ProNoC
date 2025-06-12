`include "pronoc_def.v"
/************************
 *      fmesh
 * 
 * **********************/
module  fmesh_addr_encoder #(
    parameter   NX=2,
    parameter   NY=2,
    parameter   NL=2,
    parameter   NE=16,
    parameter   EAw=4
)(
    id,
    code
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
        LOCAL   =   0,  
        EAST    =   1, 
        NORTH   =   2,  
        WEST    =   3,  
        SOUTH   =   4;  
        
    function integer addrencode; 
        input integer addr,nx,nxw,nl,nyw,ny;
        integer  y, x, l,p, diff,mul;begin
            mul  = nx*ny*nl;            
            if(addr < mul) begin 
                y = ((addr/nl) / nx ); 
                x = ((addr/nl) % nx ); 
                l = (addr % nl); 
                p = (l==0)? LOCAL : 4+l;            
            end else begin      
                diff = addr -  mul ;
                if( diff <  nx) begin //top mesh edge 
                    y = 0;
                    x = diff;
                    p = NORTH;
                end else if  ( diff < 2* nx) begin //bottom mesh edge 
                    y = ny-1;
                    x = diff-nx;
                    p = SOUTH;
                end else if  ( diff < (2* nx)+ny ) begin //left mesh edge 
                    y = diff - (2* nx);
                    x = 0;
                    p = WEST;
                end else begin //right mesh edge 
                    y = diff - (2* nx) -ny;
                    x = nx-1;
                    p = EAST; 
                end
            end//else 
            addrencode = ( p<<(nxw+nyw) | (y<<nxw) | x);      
        end   
    endfunction // addrencode    
    
    localparam 
        NXw= log2(NX),
        NYw= log2(NY),
        NEw = log2(NE);    
    
    input  [NEw-1 :0] id;
    output [EAw-1 : 0] code;
    
    wire [EAw-1 : 0 ] codes [NE-1 : 0];
    genvar i;
    generate 
        for(i=0; i< NE; i=i+1) begin : endpoints
            //Endpoint decoded address
            /* verilator lint_off WIDTH */          
            localparam [EAw-1 : 0] ENDP= addrencode(i,NX,NXw,NL,NYw,NY);
            /* verilator lint_on WIDTH */
            assign codes[i] = ENDP;            
        end
    endgenerate
    assign code = codes[id];
endmodule


module  fmesh_addr_coder #(
    parameter   NX=2,
    parameter   NY=2,
    parameter   NL=2,
    parameter   NE=16,
    parameter   EAw=4
)(
    id,
    code
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
        LOCAL   =   0,  
        EAST    =   1, 
        NORTH   =   2,  
        WEST    =   3,  
        SOUTH   =   4;  
        
    function integer addrencode; 
        input integer addr,nx,nxw,nl,nyw,ny;
        integer  y, x, l,p, diff,mul;begin
            mul  = nx*ny*nl;            
            if(addr < mul) begin 
                y = ((addr/nl) / nx ); 
                x = ((addr/nl) % nx ); 
                l = (addr % nl); 
                p = (l==0)? LOCAL : 4+l;            
            end else begin      
                diff = addr -  mul ;
                if( diff <  nx) begin //top mesh edge 
                    y = 0;
                    x = diff;
                    p = NORTH;
                end else if  ( diff < 2* nx) begin //bottom mesh edge 
                    y = ny-1;
                    x = diff-nx;
                    p = SOUTH;
                end else if  ( diff < (2* nx)+ny ) begin //left mesh edge 
                    y = diff - (2* nx);
                    x = 0;
                    p = WEST;
                end else begin //right mesh edge 
                    y = diff - (2* nx) -ny;
                    x = nx-1;
                    p = EAST; 
                end
            end//else 
            addrencode = ( p<<(nxw+nyw) | (y<<nxw) | x);      
        end   
    endfunction // addrencode   
    
    localparam 
        NXw= log2(NX),
        NYw= log2(NY),
        NEw = log2(NE);    
    
    output [NEw-1 :0] id;
    input [EAw-1 : 0] code;
    
    wire   [NEw-1 : 0]  codes   [(2**EAw)-1 : 0 ];
    genvar i;
    generate 
        for(i=0; i< NE; i=i+1) begin : endpoints
            //Endpoint decoded address
            /* verilator lint_off WIDTH */
            localparam [EAw-1 : 0] ENDP= addrencode(i,NX,NXw,NL,NYw,NY);
            /* verilator lint_on WIDTH */
            assign codes[ENDP] = i;            
        end
    endgenerate
    assign id = codes[code];
endmodule




module fmesh_endp_addr_decode #(
    parameter T1=4,
    parameter T2=4,
    parameter T3=4,
    parameter EAw=9
)(
    e_addr,
    ex,
    ey,
    ep,
    valid
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
        NX = T1,
        NY = T2,
        NL = T3, 
        EXw = log2(NX),   
        EYw = log2(NY),
        EPw = EAw - EXw - EYw,
        P   = 5 + NL -1;    
    
    /* verilator lint_off WIDTH */ 
    localparam [EXw-1 : 0]    MAXX = (NX-1); 
    localparam [EYw-1 : 0]    MAXY = (NY-1);
    localparam [EPw-1 : 0]    MAXP = (P-1);    
    /* verilator lint_on WIDTH */ 
    
    input  [EAw-1 : 0] e_addr;
    output [EXw-1 : 0] ex;
    output [EYw-1 : 0] ey;
    output [EPw-1 : 0] ep;
    output valid;
    assign {ep,ey,ex} = e_addr; 
    /* verilator lint_off CMPCONST */
    assign valid = ( (ex<= MAXX) & (ey <= MAXY) & (ep<= MAXP) );
    /* verilator lint_on CMPCONST */
endmodule


module fmesh_destp_generator #(
    parameter ROUTE_NAME = "XY",  
    parameter ROUTE_TYPE = "DETERMINISTIC",
    parameter P=5,
    parameter DSTPw=4,
    parameter NL=1,
    parameter PLw=1,
    parameter PPSw=4,
    parameter SW_LOC=0,
    parameter SELF_LOOP_EN=0 
)(
    dest_port_out,
    dest_port_coded,
    endp_localp_num,
    swap_port_presel,
    port_pre_sel,
    odd_column
    );
    
    localparam P_1 = (SELF_LOOP_EN )?  P : P-1;
    
    input  [DSTPw-1 : 0] dest_port_coded;
    input  [PLw-1 : 0] endp_localp_num;
    output [P_1-1 : 0] dest_port_out;
    input           swap_port_presel;
    input  [PPSw-1 : 0] port_pre_sel;
    input odd_column;
    
    wire [P_1-1 : 0] dest_port_in;
    
    fmesh_destp_decoder #(
        .ROUTE_TYPE(ROUTE_TYPE),
        .P(P),
        .DSTPw(DSTPw),
        .NL(NL),
        .PLw(PLw),
        .PPSw(PPSw),
        .SW_LOC(SW_LOC),
        .SELF_LOOP_EN(SELF_LOOP_EN)
    ) decoder  (
        .dest_port_coded(dest_port_coded),
        .dest_port_out(dest_port_in),
        .endp_localp_num(endp_localp_num),
        .swap_port_presel(swap_port_presel),
        .port_pre_sel(port_pre_sel)
        );
    assign dest_port_out = dest_port_in;
endmodule



module fmesh_destp_decoder #(
    parameter ROUTE_TYPE="DETERMINISTIC",
    parameter P=6,
    parameter DSTPw=4,
    parameter NL=2,
    parameter PLw=1,
    parameter PPSw=4,
    parameter SW_LOC=0,
    parameter SELF_LOOP_EN=0
)(
    dest_port_coded,
    endp_localp_num,
    dest_port_out,
    swap_port_presel,
    port_pre_sel
);
    localparam P_1 = (SELF_LOOP_EN )?  P : P-1;
    
    input  [DSTPw-1 : 0] dest_port_coded;
    input  [PLw-1 : 0] endp_localp_num;
    output [P_1-1 : 0] dest_port_out;
    input           swap_port_presel;
    input  [PPSw-1 : 0] port_pre_sel;
    
    wire [P-1 : 0] endp_localp_onehot;
    reg [4:0] portout;
    
    generate 
    if( ROUTE_TYPE == "DETERMINISTIC") begin :dtrmn
        wire x,y,a,b;
        assign {x,y,a,b} = dest_port_coded;
        always_comb begin 
            case({a,b})
                2'b10 : portout = {1'b0,~x,1'b0,x,1'b0};
                2'b01 : portout = {~y,1'b0,y,1'b0,1'b0};
                2'b00 : portout =  5'b00001;
                2'b11 : portout = {~y,1'b0,y,1'b0,1'b0}; //invalid condition in determinstic routing
            endcase
        end //always
    end else begin : adpv
        wire x,y,a,b;
        assign {x,y,a,b} = dest_port_coded;        
        wire [PPSw-1:0] port_pre_sel_final;
        assign port_pre_sel_final= (swap_port_presel)? ~port_pre_sel: port_pre_sel;
        always_comb begin 
            case({a,b})
                2'b10 : portout = {1'b0,~x,1'b0,x,1'b0};
                2'b01 : portout = {~y,1'b0,y,1'b0,1'b0};
                2'b11 : portout = (port_pre_sel_final[{x,y}])?  {~y,1'b0,y,1'b0,1'b0} : {1'b0,~x,1'b0,x,1'b0};
                2'b00 : portout =  5'b00001;
            endcase
        end //always
    end //adaptive    
    wire [P-1 : 0] destport_onehot;    
    bin_to_one_hot #(
        .BIN_WIDTH(PLw),
        .ONE_HOT_WIDTH(P)
    ) conv (
        .bin_code(endp_localp_num),
        .one_hot_code(endp_localp_onehot)
    );
    if(NL>1) begin :multi    
        assign destport_onehot =(portout[0])? endp_localp_onehot : /*select local destination*/ 
            { {(NL-1){1'b0}} ,portout};
    end else begin 
        assign destport_onehot =(portout[0])? endp_localp_onehot : /*select local destination*/ 
            portout;
    end    
    if(SELF_LOOP_EN == 0) begin :nslp
        remove_sw_loc_one_hot #(
                .P(P),
                .SW_LOC(SW_LOC)
            ) remove_sw_loc (
                .destport_in(destport_onehot),
                .destport_out(dest_port_out)
            );
    end else begin: slp
            assign dest_port_out = destport_onehot;            
    end
    endgenerate
endmodule


/********************
*    distance_gen 
 ********************/
module fmesh_distance_gen (
    src_e_addr,
    dest_e_addr,
    distance
);
    import pronoc_pkg::*;
    
    localparam 
        Xw  =   log2(T1),   // number of node in x axis
        Yw  =   log2(T2);    // number of node in y axis 
    localparam [Xw : 0] NX  = T1;
    localparam [Yw : 0] NY  = T2;
    
    input [EAw-1 : 0] src_e_addr;
    input [EAw-1 : 0] dest_e_addr;
    output[DISTw-1:   0]distance;
    
    wire [Xw-1 :   0]src_x,dest_x;
    wire [Yw-1 :   0]src_y,dest_y;
    
    fmesh_endp_addr_decode #(
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .EAw(EAw)
    ) src_addr_decode (
        .e_addr(src_e_addr),
        .ex(src_x),
        .ey(src_y),
        .ep(),
        .valid()
    );
    
    fmesh_endp_addr_decode #(
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .EAw(EAw)
    ) dest_addr_decode (
        .e_addr(dest_e_addr),
        .ex(dest_x),
        .ey(dest_y),
        .ep(),
        .valid()
    );
    
    reg [Xw-1  :   0] x_offset;
    reg [Yw-1  :   0] y_offset;    
    always_comb begin 
            x_offset     = (src_x> dest_x)? src_x - dest_x : dest_x - src_x;
            y_offset     = (src_y> dest_y)? src_y - dest_y : dest_y - src_y;
    end      
    /* verilator lint_off WIDTH */ 
    assign distance =  x_offset + y_offset +1'b1;
    /* verilator lint_on WIDTH */ 
endmodule