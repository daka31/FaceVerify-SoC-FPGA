`timescale 1ns / 1ps

module FpAdder_test;

    // Inputs
    reg [31:0] A;
    reg [31:0] B;
    reg [1:0] round_mode;

    // Outputs
    wire [31:0] result;

    // Instantiate the Unit Under Test (UUT)
    FpAdder uut (
        .A(A),
        .B(B),
        .round_mode(round_mode),
        .result(result)
    );

    initial begin
        // Initialize Inputs
        A = 0;
        B = 0;
        round_mode = 2'b00; // Round to nearest even

        // Wait 100 ns for global reset to finish
        #100;

        // Test case 1: Cộng hai số dương
        A = 32'h3F800000; // 1.0
        B = 32'h40000000; // 2.0
        #100;
        $display("Test 1: 1.0 + 2.0 = %h", result);

        // Test case 2: Cộng số dương và số âm
        A = 32'h3F800000; // 1.0
        B = 32'hC0000000; // -2.0
        #100;
        $display("Test 2: 1.0 + (-2.0) = %h", result);

        // Test case 3: Cộng hai số âm
        A = 32'hC0000000; // -2.0
        B = 32'hC0400000; // -3.0
        #100;
        $display("Test 3: -2.0 + (-3.0) = %h", result);

        // Test case 4: Cộng số rất nhỏ
        A = 32'h3DCCCCCD; // 0.1
        B = 32'h3E4CCCCD; // 0.2
        #100;
        $display("Test 4: 0.1 + 0.2 = %h", result);

        // Test case 5: Cộng với số 0
        A = 32'h3F800000; // 1.0
        B = 32'h00000000; // 0.0
        #100;
        $display("Test 5: 1.0 + 0.0 = %h", result);

        // Test case 6: Cộng hai số rất lớn
        A = 32'h4F000000; // 2^32
        B = 32'h4F000000; // 2^32
        #100;
        $display("Test 6: 2^32 + 2^32 = %h", result);

        // Test case 7: Cộng với số vô cùng
        A = 32'h7F800000; // +infinity
        B = 32'h3F800000; // 1.0
        #100;
        $display("Test 7: +infinity + 1.0 = %h", result);

        // Test case 8: Cộng hai số NaN
        A = 32'h7FC00000; // NaN
        B = 32'h7FC00000; // NaN
        #100;
        $display("Test 8: NaN + NaN = %h", result);

        #100;
        $finish;
    end

endmodule 