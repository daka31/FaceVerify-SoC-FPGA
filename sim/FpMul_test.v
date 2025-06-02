`timescale 1ns / 1ps

module FpMul_test;

    parameter D_LEN = 32;
    parameter CLK_PERIOD = 10;

    reg clk, rst, start;
    reg [D_LEN-1:0] A, B;
    reg [1:0] round_mode;
    wire [D_LEN-1:0] result;
    wire done;

    FpMul #(
        .D_LEN(D_LEN)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A(A),
        .B(B),
        .round_mode(round_mode),
        .result(result),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        rst = 1;
        start = 0;
        A = 32'h0;
        B = 32'h0;
        round_mode = 2'b00;
        #20;
        rst = 0;

        $display("Test Case 1: Normal case (2.5 * 3.5)");
        A = 32'h40200000;
        B = 32'h40600000;
        round_mode = 2'b00;
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done);
        #5;
        if (result !== 32'h410c0000)
            $display("ERROR: Test Case 1 failed! Expected 410c0000 (8.75), got %h", result);
        else
            $display("PASS: Test Case 1 passed! A = %h (2.5), B = %h (3.5), Result = %h, Done = %b", A, B, result, done);

        #CLK_PERIOD;
        $display("Test Case 2: Negative numbers (-1.5 * 2.0)");
        A = 32'hBFC00000;
        B = 32'h40000000;
        round_mode = 2'b00;
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done);
        #5;
        if (result !== 32'hC0400000)
            $display("ERROR: Test Case 2 failed! Expected C0400000 (-3.0), got %h", result);
        else
            $display("PASS: Test Case 2 passed! A = %h (-1.5), B = %h (2.0), Result = %h, Done = %b", A, B, result, done);

        #CLK_PERIOD;
        $display("Test Case 3: Zero case (0 * 5.0)");
        A = 32'h00000000;
        B = 32'h40A00000;
        round_mode = 2'b00;
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done);
        #5;
        if (result !== 32'h00000000)
            $display("ERROR: Test Case 3 failed! Expected 00000000 (0), got %h", result);
        else
            $display("PASS: Test Case 3 passed! A = %h (0), B = %h (5.0), Result = %h, Done = %b", A, B, result, done);

        #CLK_PERIOD;
        $display("Test Case 4: Infinity case (Inf * 2.0)");
        A = 32'h7F800000;
        B = 32'h40000000;
        round_mode = 2'b00;
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done);
        #5;
        if (result !== 32'h7F800000)
            $display("ERROR: Test Case 4 failed! Expected 7F800000 (Inf), got %h", result);
        else
            $display("PASS: Test Case 4 passed! A = %h (Inf), B = %h (2.0), Result = %h, Done = %b", A, B, result, done);

        #CLK_PERIOD;
        $display("Test Case 5: NaN case (NaN * 3.0)");
        A = 32'h7FC00001;
        B = 32'h40400000;
        round_mode = 2'b00;
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done);
        #5;
        if (result[30:23] !== 8'hFF || result[22:0] == 23'h0)
            $display("ERROR: Test Case 5 failed! Expected NaN (exp=FF, mantissa!=0), got %h", result);
        else
            $display("PASS: Test Case 5 passed! A = %h (NaN), B = %h (3.0), Result = %h, Done = %b", A, B, result, done);

        #CLK_PERIOD;
        $display("Test Case 6: Underflow case (1.2e-38 * 1.2e-38)");
        A = 32'h00800000;
        B = 32'h00800000;
        round_mode = 2'b00;
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done);
        #5;
        if (result !== 32'h00000000)
            $display("ERROR: Test Case 6 failed! Expected 00000000 (0), got %h", result);
        else
            $display("PASS: Test Case 6 passed! A = %h (1.2e-38), B = %h (1.2e-38), Result = %h, Done = %b", A, B, result, done);

        #CLK_PERIOD;
        $display("Test Case 7: Overflow case (1e38 * 1e38)");
        A = 32'h7F000000;
        B = 32'h7F000000;
        round_mode = 2'b00;
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done);
        #5;
        if (result !== 32'h7F800000)
            $display("ERROR: Test Case 7 failed! Expected 7F800000 (Inf), got %h", result);
        else
            $display("PASS: Test Case 7 passed! A = %h (1e38), B = %h (1e38), Result = %h, Done = %b", A, B, result, done);

        #CLK_PERIOD;
        $display("Test Case 8: Rounding mode (2.7 * 1.1, round toward zero)");
        A = 32'h40266666;
        B = 32'h3F8CCCCD;
        round_mode = 2'b01;
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done);
        #5;
        if (result !== 32'h403E6666)
            $display("ERROR: Test Case 8 failed! Expected 403E6666 (~2.97), got %h", result);
        else
            $display("PASS: Test Case 8 passed! A = %h (2.7), B = %h (1.1), Result = %h, Done = %b", A, B, result, done);

        #20;
        $display("Simulation completed!");
        $finish;
    end

    initial begin
        $monitor("Time = %t, State = %b, A = %h, B = %h, round_mode = %b, Start = %b, Stage1_Mant = %h, Stage1_Exp = %h, Stage1_Sign = %b, Stage2_Mant = %h, Stage2_Exp = %h, Stage2_Sign = %b, Result = %h, Done = %b",
                 $time, uut.state, A, B, round_mode, start, uut.stage1_mantissa, uut.stage1_exponent, uut.stage1_sign, uut.stage2_mantissa, uut.stage2_exponent, uut.stage2_sign, result, done);
    end

endmodule