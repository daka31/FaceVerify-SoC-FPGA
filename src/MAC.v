`timescale 1ns / 1ps
`ifndef FP_MAC
`define FP_MAC
`include "FpMul.v"
`include "FpAdder.v"

//////////////////////////////////////////////////////////////////////////////////
// Module Name: FpMAC
// Description: Floating Point Multiply-Accumulate for vector dot product
// Performs: result = v1[0]*v2[0] + v1[1]*v2[1] + ... + v1[n-1]*v2[n-1]
//////////////////////////////////////////////////////////////////////////////////

module MAC #(
    parameter D_Len = 32,
    parameter Ele_Num = 128
)(
    input clk,
    input rst,
    input start,
    input [(D_Len*Ele_Num)-1:0] v1,
    input [(D_Len*Ele_Num)-1:0] v2,
    output reg [D_Len-1:0] result,
    output reg done
);

    // FSM states
    reg [2:0] state, next_state;
    localparam IDLE = 3'b000,
               MULTIPLY = 3'b001,
               WAIT_MUL = 3'b010,
               ACCUMULATE = 3'b011,
               DONE_STATE = 3'b100;

    // Counter for processing elements
    reg [$clog2(Ele_Num):0] element_counter;
    
    // Multiplier signals
    reg mul_start;
    reg [D_Len-1:0] mul_a, mul_b;
    wire [D_Len-1:0] mul_result;
    wire mul_done;
    
    // Adder signals (combinational)
    wire [D_Len-1:0] add_result;
    
    // Accumulator
    reg [D_Len-1:0] accumulator;
    reg [D_Len-1:0] mul_result_reg; // Register to store multiplication result
    
    // Round mode - using round to nearest (tie to even)
    wire [1:0] round_mode = 2'b00;
    
    // Extract current vector elements
    wire [D_Len-1:0] current_v1 = v1[(element_counter*D_Len) +: D_Len];
    wire [D_Len-1:0] current_v2 = v2[(element_counter*D_Len) +: D_Len];
    
    // Instantiate FpMul
    FpMul #(.D_LEN(D_Len)) fp_multiplier (
        .clk(clk),
        .rst(rst),
        .start(mul_start),
        .A(mul_a),
        .B(mul_b),
        .round_mode(round_mode),
        .result(mul_result),
        .done(mul_done)
    );
    
    // Instantiate FpAdder (combinational)
    FpAdder #(.D_LEN(D_Len)) fp_adder (
        .A(accumulator),
        .B(mul_result_reg),
        .round_mode(round_mode),
        .result(add_result)
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
            IDLE: begin
                next_state = start ? MULTIPLY : IDLE;
            end
            
            MULTIPLY: begin
                next_state = WAIT_MUL;
            end
            
            WAIT_MUL: begin
                next_state = mul_done ? ACCUMULATE : WAIT_MUL;
            end
            
            ACCUMULATE: begin
                if (element_counter < Ele_Num - 1)
                    next_state = MULTIPLY;
                else
                    next_state = DONE_STATE;
            end
            
            DONE_STATE: begin
                next_state = start ? MULTIPLY : IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Main control logic
    always @(posedge clk) begin
        if (rst) begin
            element_counter <= 0;
            accumulator <= 32'h00000000; // +0.0 in IEEE 754
            mul_start <= 1'b0;
            mul_a <= 32'h0;
            mul_b <= 32'h0;
            mul_result_reg <= 32'h0;
            result <= 32'h0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        element_counter <= 0;
                        accumulator <= 32'h00000000; // Reset accumulator to +0.0
                        done <= 1'b0;
                        mul_start <= 1'b0;
                    end
                end
                
                MULTIPLY: begin
                    // Start multiplication for current elements
                    mul_a <= current_v1;
                    mul_b <= current_v2;
                    mul_start <= 1'b1;
                end
                
                WAIT_MUL: begin
                    mul_start <= 1'b0; // Clear start signal
                    if (mul_done) begin
                        // Store multiplication result
                        mul_result_reg <= mul_result;
                    end
                end
                
                ACCUMULATE: begin
                    // Add multiplication result to accumulator
                    // The FpAdder is combinational, so add_result is immediately available
                    accumulator <= add_result;
                    
                    // Move to next element
                    element_counter <= element_counter + 1;
                end
                
                DONE_STATE: begin
                    result <= accumulator;
                    done <= 1'b1;
                    
                    if (start) begin
                        // Start new computation
                        element_counter <= 0;
                        accumulator <= 32'h00000000;
                        done <= 1'b0;
                        mul_start <= 1'b0;
                    end
                end
                
                default: begin
                    mul_start <= 1'b0;
                    done <= 1'b0;
                end
            endcase
        end
    end

endmodule

`endif