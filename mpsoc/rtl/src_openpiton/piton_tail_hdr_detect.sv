/**************************************************************
 * File        : piton_tail_hdr_detect.sv
 * Description : Detect if an OpenPiton flit is a tail or a header
 *
 * Author      :  Alireza Monemi
 * Date        :  2025
 **************************************************************/
`include "define.tmp.h"

module piton_tail_hdr_detect #(
    parameter FLIT_WIDTH=64
)(
    reset,
    clk,
    length_in,
    valid,
    ready,
    is_tail,
    is_header
);
    input  wire reset,clk;
    input  wire valid,ready;
    input  wire [`MSG_LENGTH_WIDTH-1 : 0] length_in;
    output wire is_tail, is_header;

    localparam
        CHANEL_WORLD_NUM = FLIT_WIDTH/64;
    localparam  [1:0]
        HEADER = 1,
        BODY   = 2;
    reg [1:0] flit_type,flit_type_next;
    reg  [`MSG_LENGTH_WIDTH-1  : 0] remain, remain_next;

    always_comb begin
        remain_next = remain;
        flit_type_next = flit_type;
        if(valid & ready) begin
            case(flit_type)
            HEADER: begin
                if (length_in >= CHANEL_WORLD_NUM ) begin
                    flit_type_next = BODY;
                    remain_next = length_in  - CHANEL_WORLD_NUM;
                end
            end //HEADER
            BODY: begin
                if(remain < CHANEL_WORLD_NUM) begin
                    flit_type_next = HEADER;
                end else if (remain >= CHANEL_WORLD_NUM ) begin
                    remain_next = remain  - CHANEL_WORLD_NUM;
                end
            end //BODY
            endcase
        end
    end//always

    always @ (posedge clk) begin
        if (reset)  begin
            remain <= {`MSG_LENGTH_WIDTH{1'b0}};
            flit_type <=HEADER;
        end else begin
            remain <= remain_next;
            flit_type <= flit_type_next;
        end
    end

    assign is_tail = (flit_type == HEADER)? (length_in < CHANEL_WORLD_NUM) : (remain < CHANEL_WORLD_NUM);
    assign is_header = (flit_type == HEADER);
endmodule
