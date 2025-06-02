`timescale 1ns / 1ps
`ifndef FP_ROUND
`define FP_ROUND

module FpRound #(
    parameter D_Len = 32
)(
    input [D_Len-1:0] in,
    input [1:0] round_mode,
    input guard_bit,
    input round_bit,
    input sticky_bit,
    output reg [D_Len-1:0] r_result
);
    
    reg [22:0] mantissa;
    reg [7:0] exponent;
    reg sign;
    reg increment;
    reg [23:0] mantissa_inc; // 24-bit ?? x? lý overflow
    
    always @(*) begin 
        sign = in[31];
        exponent = in[30:23];
        mantissa = in[22:0];
        increment = 1'b0;
        
        // Ki?m tra tr??ng h?p ??c bi?t
        if (exponent == 8'hFF) begin
            // NaN ho?c Infinity - truy?n qua không ??i
            r_result = in;
        end else begin
            // Quy?t ??nh làm tròn
            case (round_mode)
                2'b00: begin // Round to nearest, ties to even
                    if (guard_bit) begin
                        if (round_bit || sticky_bit) begin
                            increment = 1'b1;
                        end else begin
                            // Tie case - round to even
                            increment = mantissa[0];
                        end
                    end
                end 
                2'b01: begin // Round toward zero (truncate)
                    increment = 1'b0;
                end
                2'b10: begin // Round toward +infinity
                    if (!sign && (guard_bit || round_bit || sticky_bit)) begin
                        increment = 1'b1;
                    end
                end 
                2'b11: begin // Round toward -infinity
                    if (sign && (guard_bit || round_bit || sticky_bit)) begin
                        increment = 1'b1;
                    end
                end 
                default: increment = 1'b0;
            endcase 
            
            // Th?c hi?n increment
            mantissa_inc = {1'b0, mantissa} + increment;
            
            if (mantissa_inc[23]) begin
                // Mantissa overflow - c?n t?ng exponent
                if (exponent == 8'hFE) begin
                    // Overflow thành infinity
                    r_result = {sign, 8'hFF, 23'h000000};
                end else if (exponent == 8'h00) begin
                    // T? denormalized thành normalized
                    r_result = {sign, 8'h01, 23'h000000};
                end else begin
                    // T?ng exponent bình th??ng
                    r_result = {sign, exponent + 1'b1, 23'h000000};
                end
            end else begin
                // Không có mantissa overflow
                if (exponent == 8'h00 && mantissa_inc[22:0] != 23'h000000) begin
                    // Denormalized number
                    r_result = {sign, 8'h00, mantissa_inc[22:0]};
                end else if (exponent == 8'h00 && mantissa_inc[22:0] == 23'h000000) begin
                    // Zero
                    r_result = {sign, 8'h00, 23'h000000};
                end else begin
                    // Normalized number
                    r_result = {sign, exponent, mantissa_inc[22:0]};
                end
            end
        end
    end

endmodule
`endif