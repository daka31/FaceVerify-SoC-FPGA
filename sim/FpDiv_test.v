`timescale 1ns / 1ps

module FpDiv_test;

    // Clock and control signals
    reg clk;
    reg rst;
    reg start;
    
    // Inputs
    reg [31:0] A;
    reg [31:0] B;
    reg [1:0] round_mode;
    
    // Outputs
    wire [31:0] result;
    wire done;
    
    // Instantiate the Unit Under Test (UUT)
    FpDiv uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A),
        .B(B),
        .round_mode(round_mode),
        .result(result),
        .done(done)
    );
    
    // Clock generation - 100MHz (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Task để thực hiện một phép chia và wait for completion với timeout
    task test_division;
        input [31:0] input_A;
        input [31:0] input_B;
        input [1:0] input_round_mode;
        input [100*8-1:0] test_name;
        input [31:0] expected_result;
        integer timeout_counter;
        begin
            @(posedge clk);
            A = input_A;
            B = input_B;
            round_mode = input_round_mode;
            start = 1'b1;
            
            @(posedge clk);
            start = 1'b0;
            
            // Wait for computation to complete with timeout
            timeout_counter = 0;
            while (!done && timeout_counter < 1000) begin
                @(posedge clk);
                timeout_counter = timeout_counter + 1;
            end
            
            if (timeout_counter >= 1000) begin
                $display("%s: TIMEOUT after %0d cycles", test_name, timeout_counter);
            end else begin
                @(posedge clk); // Extra cycle để stable result
                
                $display("%s: Result = %h, Expected = %h, Cycles = %0d %s", 
                    test_name, result, expected_result, timeout_counter,
                    (result == expected_result) ? "✓ PASS" : "✗ FAIL");
            end
        end
    endtask
    
    // Task để test special cases
    task test_special_case;
        input [31:0] input_A;
        input [31:0] input_B;
        input [1:0] input_round_mode;
        input [100*8-1:0] test_name;
        integer timeout_counter;
        begin
            @(posedge clk);
            A = input_A;
            B = input_B;
            round_mode = input_round_mode;
            start = 1'b1;
            
            @(posedge clk);
            start = 1'b0;
            
            // Wait for computation to complete with timeout
            timeout_counter = 0;
            while (!done && timeout_counter < 1000) begin
                @(posedge clk);
                timeout_counter = timeout_counter + 1;
            end
            
            if (timeout_counter >= 1000) begin
                $display("%s: TIMEOUT after %0d cycles", test_name, timeout_counter);
            end else begin
                @(posedge clk); // Extra cycle để stable result
                
                $display("%s: Result = %h, Cycles = %0d", test_name, result, timeout_counter);
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("\n=== Test FpDiv Module với Sequential FpMul ===");
        
        // Initialize signals
        rst = 1'b1;
        start = 1'b0;
        A = 32'h00000000;
        B = 32'h00000000;
        round_mode = 2'b10;
        
        // Reset sequence
        repeat(10) @(posedge clk);
        rst = 1'b0;
        repeat(5) @(posedge clk);
        
        $display("\n=== Basic Division Tests ===");
        
        // Test case 1: Phép chia đơn giản
        test_division(32'h40400000, 32'h40000000, 2'b10, 
                     "Test 1: 3.0 / 2.0", 32'h3fc00000);
        
        // Test case 2: Phép chia số âm
        test_division(32'hc0400000, 32'h40000000, 2'b10, 
                     "Test 2: -3.0 / 2.0", 32'hbfc00000);
        
        // Test case 3: Phép chia cho 1
        test_division(32'h40a00000, 32'h3f800000, 2'b10, 
                     "Test 3: 5.0 / 1.0", 32'h40a00000);
        
        // Test case 4: Phép chia số giống nhau
        test_division(32'h40000000, 32'h40000000, 2'b10, 
                     "Test 4: 2.0 / 2.0", 32'h3f800000);
        
        // Test case 5: Phép chia số lớn
        test_division(32'h42c80000, 32'h41200000, 2'b10, 
                     "Test 5: 100.0 / 10.0", 32'h41200000);
        
        $display("\n=== Special Cases Tests ===");
        
        // Test case 6: Chia cho 0 (should return +Infinity)
        test_special_case(32'h3f800000, 32'h00000000, 2'b10, 
                         "Test 6: 1.0 / 0.0 (Should be +Inf)");
        
        // Test case 7: Chia -1 cho 0 (should return -Infinity)
        test_special_case(32'hbf800000, 32'h00000000, 2'b10, 
                         "Test 7: -1.0 / 0.0 (Should be -Inf)");
        
        // Test case 8: Chia 0 cho số khác 0
        test_division(32'h00000000, 32'h3f800000, 2'b10, 
                     "Test 8: 0.0 / 1.0", 32'h00000000);
        
        // Test case 9: Chia số âm cho số âm
        test_division(32'hc0400000, 32'hc0000000, 2'b10, 
                     "Test 9: -3.0 / -2.0", 32'h3fc00000);
        
        // Test case 10: NaN input
        test_special_case(32'h7fc00000, 32'h3f800000, 2'b10, 
                         "Test 10: NaN / 1.0 (Should be NaN)");
        
        $display("\n=== Edge Cases Tests ===");
        
        // Test case 11: Số rất nhỏ
        test_special_case(32'h00800000, 32'h3f800000, 2'b10, 
                         "Test 11: Smallest normal / 1.0");
        
        // Test case 12: Số rất lớn
        test_special_case(32'h7f7fffff, 32'h3f800000, 2'b10, 
                         "Test 12: Largest normal / 1.0");
        
        // Test case 13: Chia cho số rất nhỏ
        test_special_case(32'h3f800000, 32'h00800000, 2'b10, 
                         "Test 13: 1.0 / Smallest normal");
        
        // Test case 14: Chia cho số rất lớn  
        test_special_case(32'h3f800000, 32'h7f7fffff, 2'b10, 
                         "Test 14: 1.0 / Largest normal");
        
        $display("\n=== Rounding Modes Tests ===");
        
        // Test case 15: Round to Zero
        test_special_case(32'h40000001, 32'h3f800000, 2'b00, 
                         "Test 15: 2.0000001 / 1.0 (Round to Zero)");
        
        // Test case 16: Round to +Infinity
        test_special_case(32'h40000001, 32'h3f800000, 2'b01, 
                         "Test 16: 2.0000001 / 1.0 (Round to +Inf)");
        
        // Test case 17: Round to Nearest Even
        test_special_case(32'h40000001, 32'h3f800000, 2'b10, 
                         "Test 17: 2.0000001 / 1.0 (Round to Nearest Even)");
        
        // Test case 18: Round to -Infinity
        test_special_case(32'hc0000001, 32'h3f800000, 2'b11, 
                         "Test 18: -2.0000001 / 1.0 (Round to -Inf)");
        
        $display("\n=== Performance Test ===");
        
        // Test nhiều phép chia liên tiếp để verify stability
        test_special_case(32'h3f800000, 32'h40400000, 2'b10, 
                         "Test 19: 1.0 / 3.0");
        test_special_case(32'h40800000, 32'h40400000, 2'b10, 
                         "Test 20: 4.0 / 3.0");
        test_special_case(32'h40a00000, 32'h40400000, 2'b10, 
                         "Test 21: 5.0 / 3.0");
        test_special_case(32'h40c00000, 32'h40400000, 2'b10, 
                         "Test 22: 6.0 / 3.0");
        
        repeat(20) @(posedge clk);
        
        $display("\n=== FpDiv Test Completed Successfully ===");
        $finish;
    end
    
    // Monitor để track state machine progress
    initial begin
        $monitor("Time: %0t | State: %0d | Start: %b | Done: %b | A: %h | B: %h | Result: %h", 
                 $time, uut.state, start, done, A, B, result);
    end
    
    // Extended timeout protection
    initial begin
        #200000; // 200us timeout
        $display("ERROR: Test timeout!");
        $finish;
    end
    
endmodule 