`timescale 1ns / 1ps

module simple_debug();

    parameter D_Len = 32;
    parameter CLK_PERIOD = 10;
    
    // Test signals
    reg clk;
    reg rst;
    reg [31:0] test_val;
    real test_real;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test real to float conversion
    initial begin
        $display("=== Testing Real to Float Conversion ===");
        
        // Test simple values
        test_real = 1.0;
        test_val = $realtobits(test_real);
        $display("Real: %f -> Hex: 0x%08h -> Back to Real: %f", 
                test_real, test_val, $bitstoreal(test_val));
        
        test_real = 2.0;
        test_val = $realtobits(test_real);
        $display("Real: %f -> Hex: 0x%08h -> Back to Real: %f", 
                test_real, test_val, $bitstoreal(test_val));
        
        test_real = 0.5;
        test_val = $realtobits(test_real);
        $display("Real: %f -> Hex: 0x%08h -> Back to Real: %f", 
                test_real, test_val, $bitstoreal(test_val));
        
        test_real = 0.0;
        test_val = $realtobits(test_real);
        $display("Real: %f -> Hex: 0x%08h -> Back to Real: %f", 
                test_real, test_val, $bitstoreal(test_val));
        
        test_real = -1.0;
        test_val = $realtobits(test_real);
        $display("Real: %f -> Hex: 0x%08h -> Back to Real: %f", 
                test_real, test_val, $bitstoreal(test_val));
        
        // Test known IEEE 754 values
        test_val = 32'h3F800000; // 1.0
        $display("Known 1.0: 0x%08h -> Real: %f", test_val, $bitstoreal(test_val));
        
        test_val = 32'h40000000; // 2.0  
        $display("Known 2.0: 0x%08h -> Real: %f", test_val, $bitstoreal(test_val));
        
        test_val = 32'h3F000000; // 0.5
        $display("Known 0.5: 0x%08h -> Real: %f", test_val, $bitstoreal(test_val));
        
        test_val = 32'h00000000; // 0.0
        $display("Known 0.0: 0x%08h -> Real: %f", test_val, $bitstoreal(test_val));
        
        $display("\n=== Testing FP Adder ===");
        test_fp_adder();
        
        $display("\n=== Testing FP Multiplier ===");
        test_fp_multiplier();
        
        #100;
        $finish;
    end
    
    // Test FP Adder
    task test_fp_adder;
        reg [31:0] a, b, result;
        begin
            // Test 1.0 + 1.0 = 2.0
            a = 32'h3F800000; // 1.0
            b = 32'h3F800000; // 1.0
            
            // Instantiate adder inline for testing
            test_adder(a, b, result);
            $display("FpAdder: %f + %f = %f (0x%08h)", 
                    $bitstoreal(a), $bitstoreal(b), $bitstoreal(result), result);
        end
    endtask
    
    // Test FP Multiplier
    task test_fp_multiplier;
        reg [31:0] a, b;
        wire [31:0] result;
        wire done;
        reg start;
        
        begin
            start = 0;
            a = 32'h3F800000; // 1.0
            b = 32'h40000000; // 2.0
            
            #10;
            start = 1;
            #10;
            start = 0;
            
            // Wait for done signal
            wait(done);
            
            $display("FpMul: %f * %f = %f (0x%08h)", 
                    $bitstoreal(a), $bitstoreal(b), $bitstoreal(result), result);
        end
    endtask
    
    // Simple adder instance for testing
    task test_adder;
        input [31:0] a_in, b_in;
        output [31:0] result_out;
        begin
            // For now just return sum (this will be replaced with actual FpAdder)
            result_out = a_in; // Placeholder
        end
    endtask
    
    // Instantiate FP Multiplier for testing
    reg mul_start;
    reg [31:0] mul_a, mul_b;
    wire [31:0] mul_result;
    wire mul_done;
    
    FpMul #(.D_LEN(32)) test_multiplier (
        .clk(clk),
        .rst(rst),
        .start(mul_start),
        .A(mul_a),
        .B(mul_b),
        .round_mode(2'b00),
        .result(mul_result),
        .done(mul_done)
    );
    
    // Update multiplier test
    task test_fp_multiplier_real;
        begin
            rst = 1;
            mul_start = 0;
            mul_a = 32'h3F800000; // 1.0
            mul_b = 32'h40000000; // 2.0
            
            #20;
            rst = 0;
            #10;
            
            mul_start = 1;
            #10;
            mul_start = 0;
            
            // Wait for done
            wait(mul_done);
            #10;
            
            $display("FpMul: %f * %f = %f (0x%08h)", 
                    $bitstoreal(mul_a), $bitstoreal(mul_b), $bitstoreal(mul_result), mul_result);
        end
    endtask

endmodule 