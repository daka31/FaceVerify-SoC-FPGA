`timescale 1ns / 1ps
`ifndef IP_TOP
`define IP_TOP
`include "FpMul.v"
`include "FpSqrt.v"
`include "FpDiv.v"
`include "MAC.v"

module IP # (
    parameter D_Len = 32,
    parameter Ele_Num = 128
) (
    input clk, rst, start,
    input [D_Len*Ele_Num -1:0] vct1, vct2,
    output [D_Len-1:0] result,
    output done,
    output reg error
);

    wire [D_Len-1:0] mac_t, sqr1, sqr2;
    wire [D_Len-1:0] mul_t, sqrt;
    wire mac_done_a1, mac_done_a2, mac_done_a3, sqrt_done, div_done;

    // MAC units
    MAC a1 ( .clk(clk), .rst(rst), .start(start), .v1(vct1), .v2(vct2), .result(mac_t), .done(mac_done_a1) );
    MAC a2 ( .clk(clk), .rst(rst), .start(start), .v1(vct1), .v2(vct1), .result(sqr1), .done(mac_done_a2) );
    MAC a3 ( .clk(clk), .rst(rst), .start(start), .v1(vct2), .v2(vct2), .result(sqr2), .done(mac_done_a3) );

    // Floating point operations
    FpMul m1 ( .A(sqr1), .B(sqr2), .round_mode(2'b00), .result(mul_t) );
    FpSqrt s1 ( .clk(clk), .rst(rst), .start(mac_done_a1 && mac_done_a2 && mac_done_a3), .A(mul_t), .result(sqrt), .done(sqrt_done) );
    FpDiv d1 ( .clk(clk), .rst(rst), .start(sqrt_done), .A(mac_t), .B(sqrt), .round_mode(2'b00), .result(result), .done(div_done) );

    // Control logic
    reg [2:0] state;
    localparam IDLE = 3'b000;
    localparam MAC_RUN = 3'b001;
    localparam MUL_RUN = 3'b010;
    localparam SQRT_RUN = 3'b011;
    localparam DIV_RUN = 3'b100;

    wire invalid_norm = (sqr1 == 32'h0) || (sqr2 == 32'h0);
    wire all_mac_done = mac_done_a1 && mac_done_a2 && mac_done_a3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            error <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) state <= MAC_RUN;
                    error <= 0;
                end
                MAC_RUN: begin
                    if (all_mac_done && invalid_norm) begin
                        state <= IDLE;
                        error <= 1;
                    end else if (all_mac_done) begin
                        state <= MUL_RUN;
                    end
                end
                MUL_RUN: begin
                    state <= SQRT_RUN;
                end
                SQRT_RUN: begin
                    if (sqrt_done) state <= DIV_RUN;
                end
                DIV_RUN: begin
                    if (div_done) state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

    assign done = (state == DIV_RUN && div_done);

endmodule
`endif