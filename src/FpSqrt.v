`timescale 1ns / 1ps
`ifndef FP_SQRT
`define FP_SQRT
`include "FpDiv.v"
`include "FpAdder.v"
`include "FpMul.v"

module FpSqrt # (
    parameter D_Len = 32
) (
    input clk, rst, start,
    input [D_Len-1:0] A,
    output reg [D_Len-1:0] result,
    output reg done
);
    
    // Signal declarations
    wire [7:0] Exponent;
    wire [22:0] Mantissa;
    wire Sign;
    wire [D_Len-1:0] temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8, temp;
    wire [D_Len-1:0] x0, x1, x2, x3;
    wire [D_Len-1:0] sqrt_1by05, sqrt_2, sqrt_1by2;
    wire [7:0] Exp_2, Exp_Adjust;
    wire remainder;
    wire [D_Len-1:0] y1, y2, y3;
    wire [D_Len-1:0] temp_y1, temp_y2, temp_y3;
    wire [D_Len-1:0] y1_intermediate, y2_intermediate, y3_intermediate;
    wire [D_Len-1:0] y2_temp;
    wire [D_Len-1:0] sqrt_adjusted_result;
    wire div_done_y1, div_done_y2, div_done_y3, div_done_x1, div_done_x2, div_done_x3;
    
    // Constants
    assign x0 = 32'h3f5a827a;  // 0.8660254037844386
    assign sqrt_1by05 = 32'h3fb504f3;  // 1.4142135623730951
    assign sqrt_2 = 32'h3fb504f3;      // 1.4142135623730951
    assign sqrt_1by2 = 32'h3f3504f3;   // 0.7071067811865476
    assign Sign = A[31];
    assign Exponent = A[30:23];
    assign Mantissa = A[22:0];
    
    // Special case handling
    wire is_zero = (Exponent == 8'd0 && Mantissa == 23'd0);
    wire is_negative = Sign;
    wire is_inf = (Exponent == 8'hff && Mantissa == 23'd0);
    wire is_nan = (Exponent == 8'hff && Mantissa != 23'd0);
    
    // Check for numbers in range 0-1
    wire is_between_0_1 = (Exponent < 8'd127);
    wire is_very_small = (Exponent < 8'd120);
    wire is_near_one = (Exponent == 8'd126 && Mantissa > 23'h7ffff0);
    
    // Initial guess
    wire [D_Len-1:0] initial_guess;
    assign initial_guess = is_very_small ? 32'h3f000000 : // 0.5
                          is_near_one ? 32'h3f800000 :   // 1.0
                          32'h3f400000;                  // 0.75
    
    // First Iteration for small numbers
    FpDiv D4 ( 
        .clk(clk), .rst(rst), .start(start),
        .A(A), 
        .B(initial_guess), 
        .round_mode(2'b00), 
        .result(temp_y1),
        .done(div_done_y1)
    );
    FpAdder A8 ( 
        .A(temp_y1), 
        .B(initial_guess), 
        .round_mode(2'b00), 
        .result(y1_intermediate) 
    );
    assign y1 = {y1_intermediate[31], y1_intermediate[30:23] - 1, y1_intermediate[22:0]};
    
    // Second Iteration for small numbers
    FpDiv D5 ( 
        .clk(clk), .rst(rst), .start(div_done_y1),
        .A(A), 
        .B(y1), 
        .round_mode(2'b00), 
        .result(temp_y2),
        .done(div_done_y2)
    );
    FpAdder A9 ( 
        .A(temp_y2), 
        .B(y1), 
        .round_mode(2'b00), 
        .result(y2_temp) 
    );
    assign y2_intermediate = {y2_temp[31], y2_temp[30:23] - 1, y2_temp[22:0]};
    assign y2 = y2_intermediate;
    
    // Third Iteration for small numbers
    FpDiv D6 ( 
        .clk(clk), .rst(rst), .start(div_done_y2),
        .A(A), 
        .B(y2), 
        .round_mode(2'b00), 
        .result(temp_y3),
        .done(div_done_y3)
    );
    FpAdder A10 ( 
        .A(temp_y3), 
        .B(y2), 
        .round_mode(2'b00), 
        .result(y3_intermediate)
    );
    assign y3 = {y3_intermediate[31], y3_intermediate[30:23] - 1, y3_intermediate[22:0]};
    
    // Adjust result for very small numbers
    wire [D_Len-1:0] sqrt_adjusted_result_intermediate;
    FpMul M3 (
        .A(y3),
        .B(sqrt_1by2),
        .round_mode(2'b00),
        .result(sqrt_adjusted_result_intermediate)
    );
    assign sqrt_adjusted_result = sqrt_adjusted_result_intermediate;
    
    wire [D_Len-1:0] small_number_result = is_very_small ? sqrt_adjusted_result : y3;
    
    // Calculations for other numbers
    FpDiv D1 ( 
        .clk(clk), .rst(rst), .start(start),
        .A({1'b0,8'd126,Mantissa}), 
        .B(x0), 
        .round_mode(2'b00),
        .result(temp1),
        .done(div_done_x1)
    );
    FpAdder A1 ( 
        .A(temp1), 
        .B(x0), 
        .round_mode(2'b00), 
        .result(temp2) 
    );
    assign x1 = {temp2[31], temp2[30:23] - 1, temp2[22:0]};
    
    FpDiv D2 ( 
        .clk(clk), .rst(rst), .start(div_done_x1),
        .A({1'b0,8'd126,Mantissa}), 
        .B(x1), 
        .round_mode(2'b00),
        .result(temp3),
        .done(div_done_x2)
    );
    FpAdder A2 ( 
        .A(temp3), 
        .B(x1), 
        .round_mode(2'b00), 
        .result(temp4) 
    );
    assign x2 = {temp4[31], temp4[30:23] - 1, temp4[22:0]};
    
    FpDiv D3 ( 
        .clk(clk), .rst(rst), .start(div_done_x2),
        .A({1'b0,8'd126,Mantissa}), 
        .B(x2), 
        .round_mode(2'b00),
        .result(temp5),
        .done(div_done_x3)
    );
    FpAdder A3 ( 
        .A(temp5), 
        .B(x2), 
        .round_mode(2'b00), 
        .result(temp6)
    );
    assign x3 = {temp6[31], temp6[30:23] - 1, temp6[22:0]};
    
    // Adjust exponent
    wire [7:0] exp_adj;
    assign exp_adj = (Exponent < 8'd127) ? 8'd127 - Exponent : Exponent - 8'd127;
    assign Exp_2 = exp_adj >> 1;
    assign remainder = exp_adj[0];
    
    // Final result calculation
    FpMul M1 ( 
        .A(x3), 
        .B(sqrt_1by05), 
        .round_mode(2'b00), 
        .result(temp7) 
    );
    
    wire [7:0] final_exp;
    assign final_exp = (Exponent < 8'd127) ? 8'd127 - Exp_2 : 8'd127 + Exp_2;
    assign temp = {temp7[31], final_exp, temp7[22:0]};
    
    FpMul M2 ( 
        .A(temp), 
        .B(sqrt_2), 
        .round_mode(2'b00), 
        .result(temp8)
    );
    
    // FSM to control computation
    reg [2:0] state;
    localparam IDLE = 3'b000;
    localparam ITER1 = 3'b001;
    localparam ITER2 = 3'b010;
    localparam ITER3 = 3'b011;
    localparam FINAL = 3'b100;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            result <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= ITER1;
                        done <= 0;
                    end
                end
                ITER1: begin
                    if ((is_between_0_1 && div_done_y1) || (!is_between_0_1 && div_done_x1)) begin
                        state <= ITER2;
                    end
                end
                ITER2: begin
                    if ((is_between_0_1 && div_done_y2) || (!is_between_0_1 && div_done_x2)) begin
                        state <= ITER3;
                    end
                end
                ITER3: begin
                    if ((is_between_0_1 && div_done_y3) || (!is_between_0_1 && div_done_x3)) begin
                        state <= FINAL;
                    end
                end
                FINAL: begin
                    result <= is_zero ? 32'd0 : 
                              is_negative ? 32'h7fc00000 :
                              is_inf ? 32'h7f800000 :
                              is_nan ? 32'h7fc00000 :
                              is_between_0_1 ? small_number_result :
                              remainder ? temp8 : temp;
                    done <= 1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
                             
endmodule
`endif