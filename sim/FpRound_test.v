`timescale 1ns / 1ps

module FpRound_test;

    parameter D_Len = 32;
    parameter CLK_PERIOD = 10;

    reg [D_Len-1:0] in;
    reg [1:0] round_mode;
    reg guard_bit, round_bit, sticky_bit;
    wire [D_Len-1:0] r_result;

    FpRound #(
        .D_Len(D_Len)
    ) uut (
        .in(in),
        .round_mode(round_mode),
        .guard_bit(guard_bit),
        .round_bit(round_bit),
        .sticky_bit(sticky_bit),
        .r_result(r_result)
    );

    initial begin
        in = 32'h0;
        round_mode = 2'b00;
        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;

        $display("Test Case 1: Normal case, round to nearest (2.75)");
        in = 32'h40300000; // 2.75
        round_mode = 2'b00;
        guard_bit = 1'b1;
        round_bit = 0;
        sticky_bit = 0;
        #10;
        if (r_result !== 32'h40300000) // K? v?ng 2.75 (tie, không t?ng)
            $display("ERROR: Test Case 1 failed! Expected 40300000 (2.75), got %h", r_result);
        else
            $display("PASS: Test Case 1 passed! Result = %h", r_result);

        $display("Test Case 2: Negative number, round toward zero (-2.75)");
        in = 32'hc0300000;
        round_mode = 2'b01;
        guard_bit = 1'b1;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        #10;
        if (r_result !== 32'hc0300000)
            $display("ERROR: Test Case 2 failed! Expected c0300000 (-2.75), got %h", r_result);
        else
            $display("PASS: Test Case 2 passed! Result = %h", r_result);

        $display("Test Case 3: Zero case");
        in = 32'h00000000;
        round_mode = 2'b00;
        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        #10;
        if (r_result !== 32'h00000000)
            $display("ERROR: Test Case 3 failed! Expected 00000000 (0), got %h", r_result);
        else
            $display("PASS: Test Case 3 passed! Result = %h", r_result);

        $display("Test Case 4: Infinity case");
        in = 32'h7f800000;
        round_mode = 2'b00;
        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        #10;
        if (r_result !== 32'h7f800000)
            $display("ERROR: Test Case 4 failed! Expected 7f800000 (Inf), got %h", r_result);
        else
            $display("PASS: Test Case 4 passed! Result = %h", r_result);

        $display("Test Case 5: NaN case");
        in = 32'h7fc00001;
        round_mode = 2'b00;
        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        #10;
        if (r_result[30:23] !== 8'hFF || r_result[22:0] == 23'h0)
            $display("ERROR: Test Case 5 failed! Expected NaN (exp=FF, mantissa!=0), got %h", r_result);
        else
            $display("PASS: Test Case 5 passed! Result = %h", r_result);

        $display("Test Case 6: Underflow case");
        in = 32'h00800000;
        round_mode = 2'b00;
        guard_bit = 1'b0; // S?a bit làm tròn ?? không t?ng
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        #10;
        if (r_result !== 32'h00800000)
            $display("ERROR: Test Case 6 failed! Expected 00800000 (~1.2e-38), got %h", r_result);
        else
            $display("PASS: Test Case 6 passed! Result = %h", r_result);

        $display("Test Case 7: Overflow case (max mantissa)");
        in = 32'h7f7fffff;
        round_mode = 2'b00;
        guard_bit = 1'b1;
        round_bit = 1'b1;
        sticky_bit = 1'b1;
        #10;
        if (r_result !== 32'h7f800000)
            $display("ERROR: Test Case 7 failed! Expected 7f800000 (Inf), got %h", r_result);
        else
            $display("PASS: Test Case 7 passed! Result = %h", r_result);

        $display("Test Case 8: Round toward +infinity (2.75)");
        in = 32'h40300000;
        round_mode = 2'b10;
        guard_bit = 1'b1;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        #10;
        if (r_result !== 32'h40400000)
            $display("ERROR: Test Case 8 failed! Expected 40400000 (3.0), got %h", r_result);
        else
            $display("PASS: Test Case 8 passed! Result = %h", r_result);

        #10;
        $display("Simulation completed!");
        $finish;
    end

    initial begin
        $monitor("Time = %t, in = %h, round_mode = %b, guard_bit = %b, round_bit = %b, sticky_bit = %b, r_result = %h",
                 $time, in, round_mode, guard_bit, round_bit, sticky_bit, r_result);
    end

endmodule