`timescale 1ns / 1ps
`ifndef FP_MUL
`define FP_MUL
`include "FpRound.v"

module FpMul #(
    parameter D_LEN = 32
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [D_LEN-1:0] A,
    input wire [D_LEN-1:0] B,
    input wire [1:0] round_mode,
    output reg [D_LEN-1:0] result,
    output reg done
);

    // Extract IEEE 754 fields
    wire [22:0] A_Mantissa_raw = A[22:0];
    wire [22:0] B_Mantissa_raw = B[22:0];
    wire [7:0] A_Exponent = A[30:23];
    wire [7:0] B_Exponent = B[30:23];
    wire A_sign = A[31];
    wire B_sign = B[31];
    
    // Build full mantissas (with implicit 1 for normalized numbers)
    wire [23:0] A_Mantissa = (A_Exponent == 8'h00) ? {1'b0, A_Mantissa_raw} : {1'b1, A_Mantissa_raw};
    wire [23:0] B_Mantissa = (B_Exponent == 8'h00) ? {1'b0, B_Mantissa_raw} : {1'b1, B_Mantissa_raw};
    
    // Pipeline registers
    reg [47:0] stage1_mantissa;
    reg [9:0] stage1_exponent; // 10-bit ?? x? lý overflow/underflow
    reg stage1_sign;
    reg stage1_valid;
    reg stage1_special; // ?ánh d?u k?t qu? ??c bi?t
    reg [D_LEN-1:0] stage1_special_result;
    
    reg [47:0] stage2_mantissa;
    reg [8:0] stage2_exponent; // 9-bit sau khi x? lý
    reg stage2_sign;
    reg stage2_valid;
    reg stage2_special;
    reg [D_LEN-1:0] stage2_special_result;
    
    reg [D_LEN-1:0] stage3_pre_round;
    reg stage3_valid;
    reg stage3_special;
    reg [D_LEN-1:0] stage3_special_result;
    
    wire [D_LEN-1:0] round_result;
    
    // Detect special cases
    wire A_is_zero = (A_Exponent == 8'h00) && (A_Mantissa_raw == 23'h000000);
    wire B_is_zero = (B_Exponent == 8'h00) && (B_Mantissa_raw == 23'h000000);
    wire A_is_nan = (A_Exponent == 8'hFF) && (A_Mantissa_raw != 23'h000000);
    wire B_is_nan = (B_Exponent == 8'hFF) && (B_Mantissa_raw != 23'h000000);
    wire A_is_inf = (A_Exponent == 8'hFF) && (A_Mantissa_raw == 23'h000000);
    wire B_is_inf = (B_Exponent == 8'hFF) && (B_Mantissa_raw == 23'h000000);
    wire A_is_denorm = (A_Exponent == 8'h00) && (A_Mantissa_raw != 23'h000000);
    wire B_is_denorm = (B_Exponent == 8'h00) && (B_Mantissa_raw != 23'h000000);
    
    // FSM states
    reg [2:0] state, next_state;
    localparam IDLE = 3'b000,
               STAGE1 = 3'b001,
               STAGE2 = 3'b010,
               STAGE3 = 3'b011,
               DONE = 3'b100;
    
    // Instantiate FpRound
    FpRound #(.D_Len(D_LEN)) fp_round (
        .in(stage3_pre_round),
        .round_mode(round_mode),
        .guard_bit(stage2_mantissa[22]),
        .round_bit(stage2_mantissa[21]),
        .sticky_bit(|stage2_mantissa[20:0]),
        .r_result(round_result)
    );
    
    // FSM: State register
    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // FSM: Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = start ? STAGE1 : IDLE;
            STAGE1: next_state = STAGE2;
            STAGE2: next_state = STAGE3;
            STAGE3: next_state = DONE;
            DONE: next_state = start ? STAGE1 : IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Stage 1: Initial computation and special case handling
    always @(posedge clk) begin
        if (rst) begin
            stage1_mantissa <= 48'h0;
            stage1_exponent <= 10'h0;
            stage1_sign <= 1'b0;
            stage1_valid <= 1'b0;
            stage1_special <= 1'b0;
            stage1_special_result <= 32'h0;
        end else if (state == STAGE1) begin
            stage1_valid <= 1'b1;
            stage1_sign <= A_sign ^ B_sign;
            
            // Handle special cases
            if (A_is_nan || B_is_nan) begin
                // NaN propagation
                stage1_special <= 1'b1;
                if (A_is_nan)
                    stage1_special_result <= A | 32'h00400000; // Quiet NaN
                else
                    stage1_special_result <= B | 32'h00400000; // Quiet NaN
            end else if ((A_is_inf && B_is_zero) || (A_is_zero && B_is_inf)) begin
                // 0 * infinity = NaN
                stage1_special <= 1'b1;
                stage1_special_result <= {A_sign ^ B_sign, 8'hFF, 23'h400000}; // Quiet NaN
            end else if (A_is_inf || B_is_inf) begin
                // infinity * finite = infinity
                stage1_special <= 1'b1;
                stage1_special_result <= {A_sign ^ B_sign, 8'hFF, 23'h000000};
            end else if (A_is_zero || B_is_zero) begin
                // 0 * anything = 0
                stage1_special <= 1'b1;
                stage1_special_result <= {A_sign ^ B_sign, 8'h00, 23'h000000};
            end else begin
                // Normal multiplication
                stage1_special <= 1'b0;
                stage1_mantissa <= A_Mantissa * B_Mantissa;
                
                // Calculate exponent
                if (A_is_denorm && B_is_denorm) begin
                    stage1_exponent <= 10'd1 + 10'd1 - 10'd127; // Both denormalized
                end else if (A_is_denorm) begin
                    stage1_exponent <= 10'd1 + {2'b00, B_Exponent} - 10'd127;
                end else if (B_is_denorm) begin
                    stage1_exponent <= {2'b00, A_Exponent} + 10'd1 - 10'd127;
                end else begin
                    stage1_exponent <= {2'b00, A_Exponent} + {2'b00, B_Exponent} - 10'd127;
                end
            end
        end else begin
            stage1_valid <= 1'b0;
        end
    end
    
    // Stage 2: Normalization and overflow/underflow detection
    always @(posedge clk) begin
        if (rst) begin
            stage2_mantissa <= 48'h0;
            stage2_exponent <= 9'h0;
            stage2_sign <= 1'b0;
            stage2_valid <= 1'b0;
            stage2_special <= 1'b0;
            stage2_special_result <= 32'h0;
        end else if (state == STAGE2 && stage1_valid) begin
            stage2_valid <= 1'b1;
            stage2_sign <= stage1_sign;
            
            if (stage1_special) begin
                // Pass through special cases
                stage2_special <= 1'b1;
                stage2_special_result <= stage1_special_result;
            end else begin
                stage2_special <= 1'b0;
                
                // Normalize mantissa
                if (stage1_mantissa[47]) begin
                    // Need to shift right
                    stage2_mantissa <= stage1_mantissa >> 1;
                    if (stage1_exponent >= 10'd254) begin
                        // Overflow to infinity
                        stage2_special <= 1'b1;
                        stage2_special_result <= {stage1_sign, 8'hFF, 23'h000000};
                    end else begin
                        stage2_exponent <= stage1_exponent[8:0] + 9'h1;
                    end
                end else if (stage1_mantissa[46]) begin
                    // Already normalized
                    stage2_mantissa <= stage1_mantissa;
                    if (stage1_exponent[9] || stage1_exponent >= 10'd255) begin
                        // Overflow
                        stage2_special <= 1'b1;
                        stage2_special_result <= {stage1_sign, 8'hFF, 23'h000000};
                    end else if (stage1_exponent <= 10'd0) begin
                        // Underflow to zero or denormalized
                        if (stage1_exponent <= -10'd23) begin
                            // Complete underflow to zero
                            stage2_special <= 1'b1;
                            stage2_special_result <= {stage1_sign, 8'h00, 23'h000000};
                        end else begin
                            // Denormalized result
                            stage2_exponent <= 9'h0;
                            stage2_mantissa <= stage1_mantissa >> (1 - stage1_exponent);
                        end
                    end else begin
                        stage2_exponent <= stage1_exponent[8:0];
                    end
                end else begin
                    // Need to shift left or result is too small
                    if (stage1_exponent <= 10'd0) begin
                        // Underflow to zero
                        stage2_special <= 1'b1;
                        stage2_special_result <= {stage1_sign, 8'h00, 23'h000000};
                    end else begin
                        // Find leading 1 and shift
                        stage2_mantissa <= stage1_mantissa << 1;
                        stage2_exponent <= stage1_exponent[8:0] - 9'h1;
                    end
                end
            end
        end else begin
            stage2_valid <= 1'b0;
        end
    end
    
    // Stage 3: Prepare for rounding
    always @(posedge clk) begin
        if (rst) begin
            stage3_pre_round <= 32'h0;
            stage3_valid <= 1'b0;
            stage3_special <= 1'b0;
            stage3_special_result <= 32'h0;
        end else if (state == STAGE3 && stage2_valid) begin
            stage3_valid <= 1'b1;
            
            if (stage2_special) begin
                stage3_special <= 1'b1;
                stage3_special_result <= stage2_special_result;
            end else begin
                stage3_special <= 1'b0;
                // Extract mantissa for rounding (bit 46 down to bit 24)
                stage3_pre_round <= {stage2_sign, stage2_exponent[7:0], stage2_mantissa[45:23]};
            end
        end else begin
            stage3_valid <= 1'b0;
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (rst) begin
            result <= 32'h0;
            done <= 1'b0;
        end else if (state == DONE && stage3_valid) begin
            if (stage3_special) begin
                result <= stage3_special_result;
            end else begin
                result <= round_result;
            end
            done <= 1'b1;
        end else begin
            done <= 1'b0;
        end
    end

endmodule
`endif