`timescale 1ns / 1ps
`ifndef FP_COMPARE
`define FP_COMPARE
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2025 02:49:50 PM
// Design Name: 
// Module Name: FpCompare
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FpCompare  (
                                        input [31:0]A,
                                        input [31:0]B,
                                        output reg result
                                    );
                                    
  always @(*) begin
        // compare signs
        if (A[31] != B[31])
            result = ~A[31];  // A is positive (0) -> A >= B -> result = 1

        // compare exponents
        else begin
            if (A[30:23] != B[30:23]) begin
                result = (A[30:23] > B[30:23]) ? 1'b1 : 1'b0;  // A has bigger exponent than B, so it is bigger
                if (A[31]) result = ~result;  // but if A is negative (1), bigger exponent means smaller number
            end
            // compare mantissas
            else begin
                result = (A[22:0] > B[22:0]) ? 1'b1 : 1'b0;  // A has bigger mantissa than B, so it is bigger
                if (A[31]) result = ~result;  // but if A is negative (1), bigger mantissa means smaller number
            end
        end
   end
                                    
endmodule
`endif