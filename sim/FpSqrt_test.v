`timescale 1ns / 1ps

module FpSqrt_test;

    // Inputs
    reg [31:0] A;
    
    // Outputs
    wire [31:0] result;
    
    // Instantiate the Unit Under Test (UUT)
    FpSqrt uut (
        .A(A),
        .result(result)
    );
    
    // Clock generation
    reg clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test cases
    initial begin
        $display("\n=== Test FpSqrt Module ===");
        
        // Test case 1: Căn bậc hai của số dương
        A = 32'h40000000; // 2.0
        #10;
        $display("Test case 1: sqrt(2.0) = %h (Expected: 0x3fb504f3)", result);
        
        // Test case 2: Căn bậc hai của số lớn
        A = 32'h447a0000; // 1000.0
        #10;
        $display("Test case 2: sqrt(1000.0) = %h (Expected: 0x41f5c28f)", result);
        
        // Test case 3: Căn bậc hai của số nhỏ
        A = 32'h3a83126f; // 0.001
        #10;
        $display("Test case 3: sqrt(0.001) = %h (Expected: 0x3e1e377a)", result);
        
        // Test case 4: Căn bậc hai của 1
        A = 32'h3f800000; // 1.0
        #10;
        $display("Test case 4: sqrt(1.0) = %h (Expected: 0x3f800000)", result);
        
        // Test case 5: Căn bậc hai của 0.25
        A = 32'h3e800000; // 0.25
        #10;
        $display("Test case 5: sqrt(0.25) = %h (Expected: 0x3f000000)", result);
        
        // Test case 6: Căn bậc hai của 0.5
        A = 32'h3f000000; // 0.5
        #10;
        $display("Test case 6: sqrt(0.5) = %h (Expected: 0x3f3504f3)", result);
        
        // Test case 7: Căn bậc hai của số rất lớn
        A = 32'h49742400; // 1.0e6
        #10;
        $display("Test case 7: sqrt(1.0e6) = %h (Expected: 0x447a0000)", result);
        
        // Test case 8: Căn bậc hai của số rất nhỏ
        A = 32'h00000001; // Số dương nhỏ nhất
        #10;
        $display("Test case 8: sqrt(Smallest positive) = %h", result);
        
        // Test case 9: Căn bậc hai của số âm (NaN)
        A = 32'hbf800000; // -1.0
        #10;
        $display("Test case 9: sqrt(-1.0) = %h (Expected: 0x7fc00000)", result);
        
        // Test case 10: Căn bậc hai của 0
        A = 32'h00000000; // 0.0
        #10;
        $display("Test case 10: sqrt(0.0) = %h (Expected: 0x00000000)", result);
        
        // Test case 11: Căn bậc hai của số có exponent lẻ
        A = 32'h40a00000; // 5.0
        #10;
        $display("Test case 11: sqrt(5.0) = %h (Expected: 0x4013cd3a)", result);
        
        // Test case 12: Căn bậc hai của số có exponent chẵn
        A = 32'h40800000; // 4.0
        #10;
        $display("Test case 12: sqrt(4.0) = %h (Expected: 0x40000000)", result);
        
        // Test case 13: Căn bậc hai của số có mantissa đặc biệt
        A = 32'h3faaaaab; // 1.3333333
        #10;
        $display("Test case 13: sqrt(1.3333333) = %h (Expected: 0x3f9d4952)", result);
        
        // Test case 14: Căn bậc hai của số có exponent rất lớn
        A = 32'h7f7fffff; // Số dương lớn nhất
        #10;
        $display("Test case 14: sqrt(Largest positive) = %h", result);
        
        // Test case 15: Căn bậc hai của số có exponent rất nhỏ
        A = 32'h00800000; // Số dương nhỏ nhất có thể chuẩn hóa
        #10;
        $display("Test case 15: sqrt(Smallest normalized positive) = %h", result);
        
        // Test case 16: Căn bậc hai của 0.0625 (1/16)
        A = 32'h3d800000; // 0.0625
        #10;
        $display("Test case 16: sqrt(0.0625) = %h (Expected: 0x3e800000)", result);
        
        // Test case 17: Căn bậc hai của 0.015625 (1/64)
        A = 32'h3c800000; // 0.015625
        #10;
        $display("Test case 17: sqrt(0.015625) = %h (Expected: 0x3d800000)", result);
        
        // Test case 18: Căn bậc hai của 0.00390625 (1/256)
        A = 32'h3b800000; // 0.00390625
        #10;
        $display("Test case 18: sqrt(0.00390625) = %h (Expected: 0x3c800000)", result);
        
        // Test case 19: Căn bậc hai của 0.0001
        A = 32'h38d1b717; // 0.0001
        #10;
        $display("Test case 19: sqrt(0.0001) = %h (Expected: 0x3d1e377a)", result);
        
        // Test case 20: Căn bậc hai của 0.00001
        A = 32'h3727c5ac; // 0.00001
        #10;
        $display("Test case 20: sqrt(0.00001) = %h (Expected: 0x3c1e377a)", result);
        
        // Test case 21: Căn bậc hai của 0.000001
        A = 32'h358637bd; // 0.000001
        #10;
        $display("Test case 21: sqrt(0.000001) = %h (Expected: 0x3b1e377a)", result);
        
        // Test case 22: Căn bậc hai của số có mantissa toàn bit 1
        A = 32'h3f7fffff; // 0.99999994
        #10;
        $display("Test case 22: sqrt(0.99999994) = %h (Expected: ~0x3f7fffff)", result);
        
        // Test case 23: Căn bậc hai của số có mantissa toàn bit 0
        A = 32'h3f800000; // 1.0
        #10;
        $display("Test case 23: sqrt(1.0) = %h (Expected: 0x3f800000)", result);
        
        // Test case 24: Căn bậc hai của số có exponent = 127
        A = 32'h3f800000; // 1.0
        #10;
        $display("Test case 24: sqrt(1.0) = %h (Expected: 0x3f800000)", result);
        
        // Test case 25: Căn bậc hai của số có exponent = 128
        A = 32'h40000000; // 2.0
        #10;
        $display("Test case 25: sqrt(2.0) = %h (Expected: 0x3fb504f3)", result);
        
        // Test case 26: Căn bậc hai của số có exponent = 125
        A = 32'h3e800000; // 0.25
        #10;
        $display("Test case 26: sqrt(0.25) = %h (Expected: 0x3f000000)", result);
        
        // Test case 27: Căn bậc hai của số có exponent = 1
        A = 32'h00800000; // Số dương nhỏ nhất có thể chuẩn hóa
        #10;
        $display("Test case 27: sqrt(Smallest normalized positive) = %h", result);
        
        // Test case 28: Căn bậc hai của số có exponent = 254
        A = 32'h7f7fffff; // Số dương lớn nhất
        #10;
        $display("Test case 28: sqrt(Largest positive) = %h", result);
        
        // Test case 29: Căn bậc hai của số có mantissa = 0x400000
        A = 32'h3f400000; // 0.75
        #10;
        $display("Test case 29: sqrt(0.75) = %h (Expected: ~0x3f5a827a)", result);
        
        // Test case 30: Căn bậc hai của số có mantissa = 0x7fffff
        A = 32'h3f7fffff; // 0.99999994
        #10;
        $display("Test case 30: sqrt(0.99999994) = %h (Expected: ~0x3f7fffff)", result);
        
        #10;
        $finish;
    end
    
endmodule 