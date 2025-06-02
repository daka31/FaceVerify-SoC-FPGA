`timescale 1ns / 1ps
`ifndef FP_ADDER
`define FP_ADDER
`include "FpCompare.v"
`include "FpRound.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2025 02:53:54 PM
// Design Name: 
// Module Name: FpAdder
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


module FpAdder  # (parameter D_LEN=32)
                                  (
                                      input [D_LEN-1:0]A,
                                      input [D_LEN-1:0]B,
                                      input [1:0] round_mode,
                                      output  [D_LEN-1:0] result
                                  );
                                  
  reg [D_LEN-1:0] A_swap, B_swap;  // comparison-based swap
  wire [23:0] A_Mantissa = {1'b1, A_swap[22:0]}, B_Mantissa = {1'b1, B_swap[22:0]};  // stored mantissa is 23b, this is {1'b1, mantissa} = 24b long
  wire [7:0] A_Exponent = A_swap[30:23], B_Exponent = B_swap[30:23];
  wire A_sign = A_swap[31], B_sign = B_swap[31];
  
  reg [23:0] Temp_Mantissa, B_shifted_mantissa;
  reg [22:0] Mantissa;
  reg [7:0] Exponent;
  reg Sign, carry, guard_bit, round_bit, sticky_bit;
  
  reg [7:0] diff_Exponent;
  reg [32:0] Temp;
  wire comp;
  reg [D_LEN-1:0] pre_r_result;
  wire [D_LEN-1:0] r_result;
  
  integer i;
  
  // compare absolute values of A, B
  FpCompare comp_abs(.A({1'b0, A[30:0]}), .B({1'b0, B[30:0]}), .result(comp));
  FpRound round_unit (
                                            .in(pre_r_result),
                                            .round_mode(round_mode),
                                            .guard_bit(guard_bit),
                                            .round_bit(round_bit),
                                            .sticky_bit(sticky_bit),
                                            .r_result(r_result)
                                       );
  
  always @(*)
  begin
  // let A >= B (switch numbers if needed)
  A_swap = comp ? A : B;
  B_swap = comp ? B : A;
  
  // shift B to same exponent (A >= B, exponent diff >= 0)
  diff_Exponent = A_Exponent-B_Exponent;
  B_shifted_mantissa = (B_Mantissa >> diff_Exponent);
  
  // sum the mantissas (and store potential carry)
  {carry,Temp_Mantissa} = (A_sign ~^ B_sign)? A_Mantissa + B_shifted_mantissa : A_Mantissa - B_shifted_mantissa;
  Exponent = (A[31] != B[31] && A[30:0] == B[30:0]) ? diff_Exponent : A_Exponent;
  
  // adjust mantissa to format 1.xxxx (bit 23 is 1)
  if(carry)
      begin
          Temp_Mantissa = Temp_Mantissa>>1;
          Exponent = (Exponent < 8'hff) ? Exponent + 1 : 8'hff;  // protect exponent overflow
      end
  else if(|Temp_Mantissa != 1'b1)  // mantissa contains no 1 or unknown value (result should be 0)
      begin
          Temp_Mantissa = 0;
      end
  else
      begin
          // 1st bit is not 1, but there is some 1 in the mantissa (protecting exponent underflow)
          // fixed limit of iterations because Vivado saw this as an infinite loop
          for(i = 0; Temp_Mantissa[23] !== 1'b1 && Exponent > 0 && i < 24; i = i + 1) begin
              Temp_Mantissa = Temp_Mantissa << 1;
              Exponent = Exponent - 1;
          end
      end
  
  Sign = A_sign;
  Mantissa = Temp_Mantissa[22:0];
  pre_r_result = {Sign,Exponent,Mantissa};
  
  guard_bit = Temp_Mantissa[0];
  round_bit = Temp_Mantissa[1];
  sticky_bit = |Temp_Mantissa[2:0];

  end
  
  assign result = r_result;
                                  
endmodule
`endif
