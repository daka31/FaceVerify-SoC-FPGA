`timescale 1ns / 1ps

module MAC_test();

    // Test parameters
    parameter D_Len = 32;
    parameter Ele_Num = 8; // Sử dụng số nhỏ để test dễ dàng
    parameter CLK_PERIOD = 10;
    
    // Testbench signals
    reg clk;
    reg rst;
    reg start;
    reg [(D_Len*Ele_Num)-1:0] v1, v2;
    wire [D_Len-1:0] result;
    wire done;
    
    // Test vectors and expected results
    reg [D_Len-1:0] test_v1 [0:Ele_Num-1];
    reg [D_Len-1:0] test_v2 [0:Ele_Num-1];
    reg [D_Len-1:0] expected_result;
    
    // Utility variables
    integer i, j;
    integer test_case;
    real expected_real;
    real result_real;
    
    // Performance test variables
    integer start_time, end_time;
    
    // Instantiate DUT
    MAC #(
        .D_Len(D_Len),
        .Ele_Num(Ele_Num)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .v1(v1),
        .v2(v2),
        .result(result),
        .done(done)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Function to convert real to IEEE 754 float manually
    function [31:0] real_to_float;
        input real r;
        begin
            // Use known IEEE 754 values for common numbers
            if (r == 0.0)
                real_to_float = 32'h00000000;
            else if (r == 1.0)
                real_to_float = 32'h3F800000;
            else if (r == 2.0)
                real_to_float = 32'h40000000;
            else if (r == 3.0)
                real_to_float = 32'h40400000;
            else if (r == 4.0)
                real_to_float = 32'h40800000;
            else if (r == 5.0)
                real_to_float = 32'h40A00000;
            else if (r == 6.0)
                real_to_float = 32'h40C00000;
            else if (r == 7.0)
                real_to_float = 32'h40E00000;
            else if (r == 8.0)
                real_to_float = 32'h41000000;
            else if (r == 9.0)
                real_to_float = 32'h41100000;
            else if (r == 10.0)
                real_to_float = 32'h41200000;
            // Negative values
            else if (r == -1.0)
                real_to_float = 32'hBF800000;
            else if (r == -2.0)
                real_to_float = 32'hC0000000;
            else if (r == -3.0)
                real_to_float = 32'hC0400000;
            else if (r == -4.0)
                real_to_float = 32'hC0800000;
            else if (r == -5.0)
                real_to_float = 32'hC0A00000;
            else if (r == -6.0)
                real_to_float = 32'hC0C00000;
            else if (r == -7.0)
                real_to_float = 32'hC0E00000;
            else if (r == -8.0)
                real_to_float = 32'hC1000000;
            else if (r == -9.0)
                real_to_float = 32'hC1100000;
            else if (r == -10.0)
                real_to_float = 32'hC1200000;
            // Fractional values
            else if (r == 0.5)
                real_to_float = 32'h3F000000;
            else if (r == 0.25)
                real_to_float = 32'h3E800000;
            else if (r == 1000.0)
                real_to_float = 32'h447A0000;
            else if (r == 0.001)
                real_to_float = 32'h3A83126F;
            // Expected results
            else if (r == 36.0)
                real_to_float = 32'h42100000;
            else if (r == 44.0)
                real_to_float = 32'h42300000;
            else if (r == 52.0)
                real_to_float = 32'h42500000;
            else if (r == 72.0)
                real_to_float = 32'h42900000;
            else if (r == -20.0)
                real_to_float = 32'hC1A00000;
            else if (r == 30.0)
                real_to_float = 32'h41F00000;
            else if (r == 55.0)
                real_to_float = 32'h425C0000;
            else if (r == 385.0)
                real_to_float = 32'h43C08000;
            else
                real_to_float = 32'h00000000; // Default to 0
        end
    endfunction
    
    // Function to convert IEEE 754 float to real
    function real float_to_real;
        input [31:0] f;
        begin
            // Use known IEEE 754 mappings
            case (f)
                32'h00000000: float_to_real = 0.0;
                32'h3F800000: float_to_real = 1.0;
                32'h40000000: float_to_real = 2.0;
                32'h40400000: float_to_real = 3.0;
                32'h40800000: float_to_real = 4.0;
                32'h40A00000: float_to_real = 5.0;
                32'h40C00000: float_to_real = 6.0;
                32'h40E00000: float_to_real = 7.0;
                32'h41000000: float_to_real = 8.0;
                32'h41100000: float_to_real = 9.0;
                32'h41200000: float_to_real = 10.0;
                // Negative values
                32'hBF800000: float_to_real = -1.0;
                32'hC0000000: float_to_real = -2.0;
                32'hC0400000: float_to_real = -3.0;
                32'hC0800000: float_to_real = -4.0;
                32'hC0A00000: float_to_real = -5.0;
                32'hC0C00000: float_to_real = -6.0;
                32'hC0E00000: float_to_real = -7.0;
                32'hC1000000: float_to_real = -8.0;
                32'hC1100000: float_to_real = -9.0;
                32'hC1200000: float_to_real = -10.0;
                // Fractional values
                32'h3F000000: float_to_real = 0.5;
                32'h3E800000: float_to_real = 0.25;
                32'h447A0000: float_to_real = 1000.0;
                32'h3A83126F: float_to_real = 0.001;
                // Expected results
                32'h42100000: float_to_real = 36.0;
                32'h42300000: float_to_real = 44.0;
                32'h42500000: float_to_real = 52.0;
                32'h42900000: float_to_real = 72.0;
                32'hC1A00000: float_to_real = -20.0;
                32'h41F00000: float_to_real = 30.0;
                32'h425C0000: float_to_real = 55.0;
                32'h43C08000: float_to_real = 385.0;
                default: float_to_real = 0.0;
            endcase
        end
    endfunction
    
    // Task to pack vectors
    task pack_vectors;
        begin
            for (i = 0; i < Ele_Num; i = i + 1) begin
                v1[(i*D_Len) +: D_Len] = test_v1[i];
                v2[(i*D_Len) +: D_Len] = test_v2[i];
            end
        end
    endtask
    
    // Task to calculate expected result manually
    task calculate_expected;
        begin
            expected_real = 0.0;
            for (i = 0; i < Ele_Num; i = i + 1) begin
                expected_real = expected_real + (float_to_real(test_v1[i]) * float_to_real(test_v2[i]));
            end
            expected_result = real_to_float(expected_real);
        end
    endtask
    
    // Task to perform MAC operation
    task perform_mac;
        begin
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            
            // Wait for completion
            wait(done);
            @(posedge clk);
            
            result_real = float_to_real(result);
        end
    endtask
    
    // Task to display test results
    task display_results;
        input integer test_num;
        reg [63:0] error_percent; // For error calculation
        real error;
        begin
            $display("\n=== Test Case %0d ===", test_num);
            $display("Input vectors:");
            for (i = 0; i < Ele_Num; i = i + 1) begin
                $display("  v1[%0d] = %f (0x%08h), v2[%0d] = %f (0x%08h)", 
                        i, float_to_real(test_v1[i]), test_v1[i], i, float_to_real(test_v2[i]), test_v2[i]);
            end
            $display("Expected: %f (0x%08h)", expected_real, expected_result);
            $display("Got:      %f (0x%08h)", result_real, result);
            
            // Check result
            if (result == expected_result) begin
                $display("✓ PASS - Exact match");
            end else begin
                if (expected_real != 0.0) begin
                    error = (result_real - expected_real) / expected_real * 100.0;
                    if (error < 0.01 && error > -0.01) begin
                        $display("✓ PASS - Within tolerance (%f%%)", error);
                    end else begin
                        $display("✗ FAIL - Error: %f%%", error);
                    end
                end else begin
                    if (result_real == 0.0) begin
                        $display("✓ PASS - Both zero");
                    end else begin
                        $display("✗ FAIL - Expected zero, got %f", result_real);
                    end
                end
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting FpMAC Testbench");
        $display("D_Len = %0d, Ele_Num = %0d", D_Len, Ele_Num);
        
        // Initialize
        rst = 1;
        start = 0;
        v1 = 0;
        v2 = 0;
        test_case = 0;
        
        // Reset sequence
        #(CLK_PERIOD * 5);
        rst = 0;
        #(CLK_PERIOD * 2);
        
        // Test Case 1: Simple positive numbers
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_v1[i] = real_to_float(i + 1.0);  // 1.0, 2.0, 3.0, ...
            test_v2[i] = real_to_float(1.0);      // All 1.0
        end
        pack_vectors();
        calculate_expected();
        perform_mac();
        display_results(test_case);
        
        // Test Case 2: Mixed positive and negative
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            if (i % 2 == 0) begin
                test_v1[i] = real_to_float(1.0);
            end else begin
                test_v1[i] = real_to_float(-1.0);
            end
            test_v2[i] = real_to_float(2.0);
        end
        pack_vectors();
        calculate_expected();
        perform_mac();
        display_results(test_case);
        
        // Test Case 3: Fractional numbers
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_v1[i] = real_to_float(0.5);
            test_v2[i] = real_to_float(0.25);
        end
        pack_vectors();
        calculate_expected();
        perform_mac();
        display_results(test_case);
        
        // Test Case 4: Zero vector
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_v1[i] = real_to_float(0.0);
            test_v2[i] = real_to_float(i + 1.0);
        end
        pack_vectors();
        calculate_expected();
        perform_mac();
        display_results(test_case);
        
        // Test Case 5: Identical vectors
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_v1[i] = real_to_float(3.0);
            test_v2[i] = real_to_float(3.0);
        end
        pack_vectors();
        calculate_expected();
        perform_mac();
        display_results(test_case);
        
        // Test Case 6: Giá trị âm cực trị (-10 đến -1)
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_v1[i] = real_to_float(-10.0 + i); // -10, -9, -8, ..., -3
            test_v2[i] = real_to_float(1.0);       // All 1.0
        end
        pack_vectors();
        calculate_expected();
        perform_mac();
        display_results(test_case);
        
        // Test Case 7: Giá trị dương cực trị (1 đến 10)  
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_v1[i] = real_to_float(i + 1.0);   // 1, 2, 3, ..., 8
            test_v2[i] = real_to_float(i + 1.0);   // 1, 2, 3, ..., 8
        end
        pack_vectors();
        calculate_expected();
        perform_mac();
        display_results(test_case);
        
        // Test Case 8: Giá trị âm với dương (tích âm)
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_v1[i] = real_to_float(-5.0 + i); // -5, -4, -3, -2, -1, 0, 1, 2
            test_v2[i] = real_to_float(2.0);      // All 2.0
        end
        pack_vectors();
        calculate_expected();
        perform_mac();
        display_results(test_case);
        
        // Test Case 9: Dãy đối xứng quanh 0
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            if (i < Ele_Num/2) begin
                test_v1[i] = real_to_float(-(i + 1.0)); // -1, -2, -3, -4
                test_v2[i] = real_to_float(i + 1.0);    // 1, 2, 3, 4
            end else begin
                test_v1[i] = real_to_float(i - Ele_Num/2 + 1.0); // 1, 2, 3, 4
                test_v2[i] = real_to_float(i - Ele_Num/2 + 1.0); // 1, 2, 3, 4
            end
        end
        pack_vectors();
        calculate_expected();
        perform_mac();
        display_results(test_case);
        
        // Test Case 10: Tất cả giá trị âm
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_v1[i] = real_to_float(-(i + 1.0)); // -1, -2, -3, ..., -8
            test_v2[i] = real_to_float(-(i + 1.0)); // -1, -2, -3, ..., -8
        end
        pack_vectors();
        calculate_expected();
        perform_mac();
        display_results(test_case);
        
        // Test Case 11: Giá trị lớn trong khoảng [-10, 10]
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_v1[i] = real_to_float(10.0);  // All 10.0
            test_v2[i] = real_to_float(-10.0); // All -10.0
        end
        pack_vectors();
        calculate_expected();
        perform_mac();
        display_results(test_case);
        
        // Test Case 12: Dãy tăng dần từ -10 đến 10 (nếu đủ phần tử)
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            // Tạo dãy từ -3 đến 4 với bước 1 cho 8 phần tử
            test_v1[i] = real_to_float(-3.0 + i);  // -3, -2, -1, 0, 1, 2, 3, 4
            test_v2[i] = real_to_float(3.0 - i);   // 3, 2, 1, 0, -1, -2, -3, -4
        end
        pack_vectors();
        calculate_expected();
        perform_mac();
        display_results(test_case);
        
        // Performance test
        $display("\n=== Performance Test ===");
        test_case = test_case + 1;
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_v1[i] = real_to_float(1.0);
            test_v2[i] = real_to_float(1.0);
        end
        pack_vectors();
        
        start_time = $time;
        perform_mac();
        end_time = $time;
        
        $display("Performance: %0d clock cycles for %0d element MAC", 
                (end_time - start_time) / CLK_PERIOD, Ele_Num);
        
        #(CLK_PERIOD * 10);
        $display("\n=== All Tests Completed ===");
        $finish;
    end
    
    // Timeout mechanism
    initial begin
        #(CLK_PERIOD * 10000);
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
    // Monitor for debugging
    initial begin
        $monitor("Time: %0t | State: %0d | Counter: %0d | Done: %b | Result: %f", 
                $time, dut.state, dut.element_counter, done, float_to_real(result));
    end

endmodule