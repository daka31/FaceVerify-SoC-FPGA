`timescale 1ns / 1ps
`ifndef FP_DIV
`define FP_DIV
`include "FpMul.v"
`include "FpAdder.v"

module FpDiv # (
    parameter Data_size = 32
) (
    input clk, rst, start,
    input [Data_size-1:0] A,
    input [Data_size-1:0] B,
    input [1:0] round_mode,
    output reg [Data_size-1:0] result,
    output reg done
);

    // Signal declarations
    wire zero_division, a_zero, b_nan, a_nan, b_inf, a_inf;
    
    // Input registers
    reg [31:0] A_reg, B_reg;
    reg [1:0] round_mode_reg;
    
    // Newton-Raphson iteration registers
    reg [31:0] x0_reg, x1_reg; // Only 2 iterations needed for single precision
    reg [31:0] bx0_reg, bx1_reg; // Store B*xi results
    reg [31:0] two_minus_bx0_reg, two_minus_bx1_reg; // Store 2-B*xi results
    
    // FpMul and FpAdder interface signals
    reg mul_start, add_start;
    reg [31:0] mul_a, mul_b;
    wire [31:0] mul_result;
    wire mul_done;
    
    reg [31:0] add_a, add_b;
    wire [31:0] add_result;
    
    // Special case detection  
    assign zero_division = (B_reg[30:23] == 8'h00 && B_reg[22:0] == 23'h000000) ? 1'b1 : 1'b0;
    assign a_zero = (A_reg[30:23] == 8'h00 && A_reg[22:0] == 23'h000000) ? 1'b1 : 1'b0;
    assign b_nan = (B_reg[30:23] == 8'hFF && B_reg[22:0] != 23'h000000) ? 1'b1 : 1'b0;
    assign a_nan = (A_reg[30:23] == 8'hFF && A_reg[22:0] != 23'h000000) ? 1'b1 : 1'b0;
    assign b_inf = (B_reg[30:23] == 8'hFF && B_reg[22:0] == 23'h000000) ? 1'b1 : 1'b0;
    assign a_inf = (A_reg[30:23] == 8'hFF && A_reg[22:0] == 23'h000000) ? 1'b1 : 1'b0;
    
    // Instantiate FpMul module
    FpMul #(.D_LEN(32)) fp_multiplier (
        .clk(clk),
        .rst(rst),
        .start(mul_start),
        .A(mul_a),
        .B(mul_b),
        .round_mode(round_mode_reg),
        .result(mul_result),
        .done(mul_done)
    );
    
    // Instantiate FpAdder module (combinational)
    FpAdder #(.D_LEN(32)) fp_adder (
        .A(add_a),
        .B(add_b),
        .round_mode(round_mode_reg),
        .result(add_result)
    );
    
    // Simple initial guess lookup table for 1/B based on mantissa
    reg [31:0] initial_guess;
    always @(*) begin
        case (B_reg[22:19]) // Use top 4 bits of mantissa for lookup
            4'h0: initial_guess = 32'h3F800000; // 1.0
            4'h1: initial_guess = 32'h3F700000; // ~0.9375
            4'h2: initial_guess = 32'h3F600000; // ~0.875  
            4'h3: initial_guess = 32'h3F500000; // ~0.8125
            4'h4: initial_guess = 32'h3F400000; // 0.75
            4'h5: initial_guess = 32'h3F300000; // ~0.6875
            4'h6: initial_guess = 32'h3F200000; // ~0.625
            4'h7: initial_guess = 32'h3F100000; // ~0.5625
            4'h8: initial_guess = 32'h3F000000; // 0.5
            4'h9: initial_guess = 32'h3EE00000; // ~0.4375
            4'hA: initial_guess = 32'h3EC00000; // ~0.375
            4'hB: initial_guess = 32'h3EA00000; // ~0.3125
            4'hC: initial_guess = 32'h3E800000; // 0.25
            4'hD: initial_guess = 32'h3E400000; // ~0.1875
            4'hE: initial_guess = 32'h3E000000; // ~0.125
            4'hF: initial_guess = 32'h3DC00000; // ~0.09375
        endcase
        
        // Adjust exponent: if B = 2^e * m, then 1/B ≈ 2^(-e) * (1/m)
        // B_exponent = 127 + e, so reciprocal_exponent = 127 - e = 254 - B_exponent
        initial_guess[30:23] = 8'd254 - B_reg[30:23];
        initial_guess[31] = B_reg[31]; // Preserve sign
    end
    
    // FSM states
    reg [4:0] state;
    localparam IDLE         = 5'b00000;
    localparam LOAD         = 5'b00001;
    localparam INIT_GUESS   = 5'b00010;
    // First Newton-Raphson iteration: x1 = x0 * (2 - B*x0)
    localparam MUL1_START   = 5'b00011; // B * x0
    localparam MUL1_WAIT    = 5'b00100;
    localparam ADD1_CALC    = 5'b00101; // Setup 2 - (B*x0)
    localparam ADD1_WAIT    = 5'b00110; // Wait for add_result to stabilize
    localparam MUL2_START   = 5'b00111; // x0 * (2-B*x0)
    localparam MUL2_WAIT    = 5'b01000;
    // Second Newton-Raphson iteration: x2 = x1 * (2 - B*x1) 
    localparam MUL3_START   = 5'b01001; // B * x1
    localparam MUL3_WAIT    = 5'b01010;
    localparam ADD2_CALC    = 5'b01011; // Setup 2 - (B*x1)
    localparam ADD2_WAIT    = 5'b01100; // Wait for add_result to stabilize
    localparam MUL4_START   = 5'b01101; // x1 * (2-B*x1)
    localparam MUL4_WAIT    = 5'b01110;
    // Final multiplication: A / B = A * (1/B)
    localparam FINAL_START  = 5'b01111; // A * x2
    localparam FINAL_WAIT   = 5'b10000;
    localparam DONE_STATE   = 5'b10001;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            result <= 32'h00000000;
            done <= 1'b0;
            A_reg <= 32'h00000000;
            B_reg <= 32'h00000000;
            round_mode_reg <= 2'b00;
            x0_reg <= 32'h00000000;
            x1_reg <= 32'h00000000;
            bx0_reg <= 32'h00000000;
            bx1_reg <= 32'h00000000;
            two_minus_bx0_reg <= 32'h00000000;
            two_minus_bx1_reg <= 32'h00000000;
            mul_start <= 1'b0;
            add_start <= 1'b0;
            mul_a <= 32'h00000000;
            mul_b <= 32'h00000000;
            add_a <= 32'h00000000;
            add_b <= 32'h00000000;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    mul_start <= 1'b0;
                    add_start <= 1'b0;
                    if (start) begin
                        A_reg <= A;
                        B_reg <= B;
                        round_mode_reg <= round_mode;
                        state <= LOAD;
                    end
                end
                
                LOAD: begin
                    // Handle special cases
                    if (a_nan || b_nan) begin
                        result <= 32'h7FC00000; // NaN
                        done <= 1'b1;
                        state <= IDLE;
                    end else if (zero_division) begin
                        result <= (A_reg[31] == B_reg[31]) ? 32'h7F800000 : 32'hFF800000; // +/-Inf
                        done <= 1'b1;
                        state <= IDLE;
                    end else if (a_zero) begin
                        result <= A_reg; // 0/x = 0 (preserve sign)
                        done <= 1'b1;
                        state <= IDLE;
                    end else if (b_inf) begin
                        result <= (A_reg[31] == B_reg[31]) ? 32'h00000000 : 32'h80000000; // x/inf = 0
                        done <= 1'b1;
                        state <= IDLE;
                    end else if (a_inf && b_inf) begin
                        result <= 32'h7FC00000; // inf/inf = NaN
                        done <= 1'b1;
                        state <= IDLE;
                    end else if (a_inf) begin
                        result <= (A_reg[31] == B_reg[31]) ? 32'h7F800000 : 32'hFF800000; // inf/x = inf
                        done <= 1'b1;
                        state <= IDLE;
                    end else begin
                        state <= INIT_GUESS;
                    end
                end
                
                INIT_GUESS: begin
                    x0_reg <= initial_guess;
                    state <= MUL1_START;
                end
                
                // First iteration: x1 = x0 * (2 - B*x0)
                MUL1_START: begin
                    mul_a <= B_reg;
                    mul_b <= x0_reg;
                    mul_start <= 1'b1;
                    state <= MUL1_WAIT;
                end
                
                MUL1_WAIT: begin
                    mul_start <= 1'b0;
                    if (mul_done) begin
                        bx0_reg <= mul_result;
                        state <= ADD1_CALC;
                    end
                end
                
                ADD1_CALC: begin
                    // Calculate 2 - (B*x0) using proper IEEE 754 subtraction
                    add_a <= 32'h40000000; // 2.0
                    add_b <= {~bx0_reg[31], bx0_reg[30:0]}; // Proper IEEE 754 negation
                    state <= ADD1_WAIT;
                end
                
                ADD1_WAIT: begin
                    two_minus_bx0_reg <= add_result; // Sample after combinational logic stabilizes
                    state <= MUL2_START;
                end
                
                MUL2_START: begin
                    mul_a <= x0_reg;
                    mul_b <= two_minus_bx0_reg;
                    mul_start <= 1'b1;
                    state <= MUL2_WAIT;
                end
                
                MUL2_WAIT: begin
                    mul_start <= 1'b0;
                    if (mul_done) begin
                        x1_reg <= mul_result;
                        state <= MUL3_START;
                    end
                end
                
                // Second iteration: x2 = x1 * (2 - B*x1)
                MUL3_START: begin
                    mul_a <= B_reg;
                    mul_b <= x1_reg;
                    mul_start <= 1'b1;
                    state <= MUL3_WAIT;
                end
                
                MUL3_WAIT: begin
                    mul_start <= 1'b0;
                    if (mul_done) begin
                        bx1_reg <= mul_result;
                        state <= ADD2_CALC;
                    end
                end
                
                ADD2_CALC: begin
                    // Calculate 2 - (B*x1)
                    add_a <= 32'h40000000; // 2.0
                    add_b <= {~bx1_reg[31], bx1_reg[30:0]}; // Proper IEEE 754 negation
                    state <= ADD2_WAIT;
                end
                
                ADD2_WAIT: begin
                    two_minus_bx1_reg <= add_result; // Sample after combinational logic stabilizes
                    state <= MUL4_START;
                end
                
                MUL4_START: begin
                    mul_a <= x1_reg;
                    mul_b <= two_minus_bx1_reg;
                    mul_start <= 1'b1;
                    state <= MUL4_WAIT;
                end
                
                MUL4_WAIT: begin
                    mul_start <= 1'b0;
                    if (mul_done) begin
                        // x2 (final reciprocal approximation) is in mul_result
                        state <= FINAL_START;
                    end
                end
                
                // Final step: A / B = A * (1/B)
                FINAL_START: begin
                    mul_a <= A_reg;
                    mul_b <= mul_result; // x2 = 1/B approximation
                    mul_start <= 1'b1;
                    state <= FINAL_WAIT;
                end
                
                FINAL_WAIT: begin
                    mul_start <= 1'b0;
                    if (mul_done) begin
                        result <= mul_result;
                        state <= DONE_STATE;
                    end
                end
                
                DONE_STATE: begin
                    done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
                              
endmodule
`endif
