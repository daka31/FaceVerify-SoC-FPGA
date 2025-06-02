`timescale 1ns / 1ps

module tb_CosineSimilarityWrapper;

    // Parameters
    parameter D_Len = 32;
    parameter Ele_Num = 128;
    parameter CLK_PERIOD = 10; // 10 ns (100 MHz)

    // Inputs
    reg clk;
    reg rst;
    reg we;
    reg [1:0] vct_sel;
    reg [D_Len-1:0] data_in;

    wire load_ready;
    // Outputs
    wire [D_Len-1:0] result;
    wire done;

    // Instantiate the Unit Under Test (UUT)
    CosineSimilarityWrapper #(
        .D_Len(D_Len),
        .Ele_Num(Ele_Num)
    ) uut (
        .clk(clk),
        .rst(rst),
        .we(we),
        .vct_sel(vct_sel),
        .data_in(data_in),
        .result(result),
        .done(done),
        .load_ready(load_ready)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test vectors (vct1 and vct2)
    reg [D_Len-1:0] vct1_mem [0:Ele_Num-1];
    reg [D_Len-1:0] vct2_mem [0:Ele_Num-1];
    integer i;

    // Initialize test vectors
    initial begin
        // vct1 (128 elements, 32-bit each)
        vct1_mem[0] = 32'h3fb10710;
        vct1_mem[1] = 32'hbf9240c8;
        vct1_mem[2] = 32'hc029677b;
        vct1_mem[3] = 32'hbe9d94af;
        vct1_mem[4] = 32'h3f9627a6;
        vct1_mem[5] = 32'hbf7e90ef;
        vct1_mem[6] = 32'h3ef85144;
        vct1_mem[7] = 32'hbebc1872;
        vct1_mem[8] = 32'h3ee1a1fd;
        vct1_mem[9] = 32'hbd645910;
        vct1_mem[10] = 32'h3e205d96;
        vct1_mem[11] = 32'hbd1a9329;
        vct1_mem[12] = 32'hbf5ab485;
        vct1_mem[13] = 32'hbfd58e65;
        vct1_mem[14] = 32'h3f21c2f4;
        vct1_mem[15] = 32'h3f388a69;
        vct1_mem[16] = 32'h3fa3db66;
        vct1_mem[17] = 32'h3f85a166;
        vct1_mem[18] = 32'h3ed63f14;
        vct1_mem[19] = 32'hbfb3951c;
        vct1_mem[20] = 32'hbf5e567a;
        vct1_mem[21] = 32'h3f2d5f78;
        vct1_mem[22] = 32'hbf0c294a;
        vct1_mem[23] = 32'h3ea653a8;
        vct1_mem[24] = 32'h3f11691a;
        vct1_mem[25] = 32'h3e3cf2d0;
        vct1_mem[26] = 32'hbf3d014b;
        vct1_mem[27] = 32'h3ccf5904;
        vct1_mem[28] = 32'h3f6e5acd;
        vct1_mem[29] = 32'h3f81908e;
        vct1_mem[30] = 32'h3ffb0b0f;
        vct1_mem[31] = 32'h3eda38b9;
        vct1_mem[32] = 32'hbf1eee20;
        vct1_mem[33] = 32'hbec93c04;
        vct1_mem[34] = 32'h3f2d6313;
        vct1_mem[35] = 32'hbefefe50;
        vct1_mem[36] = 32'hbf8a445b;
        vct1_mem[37] = 32'h3e812a52;
        vct1_mem[38] = 32'hbe70a4a0;
        vct1_mem[39] = 32'hbf04579f;
        vct1_mem[40] = 32'hbf851926;
        vct1_mem[41] = 32'h3fa2924f;
        vct1_mem[42] = 32'h3fd5fe33;
        vct1_mem[43] = 32'hbefa1837;
        vct1_mem[44] = 32'h3f193554;
        vct1_mem[45] = 32'h3de80842;
        vct1_mem[46] = 32'h3f6154fc;
        vct1_mem[47] = 32'hbf775be6;
        vct1_mem[48] = 32'hbf8391ff;
        vct1_mem[49] = 32'h40085048;
        vct1_mem[50] = 32'hbfac1f64;
        vct1_mem[51] = 32'hbf30054f;
        vct1_mem[52] = 32'hbe19c993;
        vct1_mem[53] = 32'h3f22c626;
        vct1_mem[54] = 32'hbf1cddf8;
        vct1_mem[55] = 32'h3e5e0b91;
        vct1_mem[56] = 32'hbfc866aa;
        vct1_mem[57] = 32'h3f06b496;
        vct1_mem[58] = 32'hbef771eb;
        vct1_mem[59] = 32'hbf837a78;
        vct1_mem[60] = 32'hbe7ea034;
        vct1_mem[61] = 32'hbf22ee42;
        vct1_mem[62] = 32'h3f577553;
        vct1_mem[63] = 32'h3fadf2c3;
        vct1_mem[64] = 32'h3f36fa0d;
        vct1_mem[65] = 32'h3f8a95a7;
        vct1_mem[66] = 32'hbefd1655;
        vct1_mem[67] = 32'h3f8db8fe;
        vct1_mem[68] = 32'h3f173722;
        vct1_mem[69] = 32'hbf4be7d1;
        vct1_mem[70] = 32'h3fad191e;
        vct1_mem[71] = 32'hbf22f20f;
        vct1_mem[72] = 32'hbe2847b2;
        vct1_mem[73] = 32'hbf96b5ee;
        vct1_mem[74] = 32'h3d4a9153;
        vct1_mem[75] = 32'hbeaccf07;
        vct1_mem[76] = 32'h3e75efe9;
        vct1_mem[77] = 32'hbdc43aa8;
        vct1_mem[78] = 32'hbf2cb4d0;
        vct1_mem[79] = 32'hbf3a518f;
        vct1_mem[80] = 32'hbf587d3d;
        vct1_mem[81] = 32'h3dfff92f;
        vct1_mem[82] = 32'hbf76326e;
        vct1_mem[83] = 32'hbd44a622;
        vct1_mem[84] = 32'h3e42be8c;
        vct1_mem[85] = 32'hbff49c5e;
        vct1_mem[86] = 32'hbf06f805;
        vct1_mem[87] = 32'hbfe00cae;
        vct1_mem[88] = 32'hbed29e2c;
        vct1_mem[89] = 32'h3dd2ef0b;
        vct1_mem[90] = 32'h3f6d8c2a;
        vct1_mem[91] = 32'hbf1c56a3;
        vct1_mem[92] = 32'hbfc67a42;
        vct1_mem[93] = 32'h3e11eb42;
        vct1_mem[94] = 32'hbee14cec;
        vct1_mem[95] = 32'hbed1b845;
        vct1_mem[96] = 32'hbfd1a3c2;
        vct1_mem[97] = 32'h3f17e261;
        vct1_mem[98] = 32'hbf9d61fe;
        vct1_mem[99] = 32'hbe54bdfd;
        vct1_mem[100] = 32'h3d934938;
        vct1_mem[101] = 32'h3fe663e0;
        vct1_mem[102] = 32'h4016a5d3;
        vct1_mem[103] = 32'hbf93f9cf;
        vct1_mem[104] = 32'hbe33f423;
        vct1_mem[105] = 32'h3f733d5c;
        vct1_mem[106] = 32'hbedae536;
        vct1_mem[107] = 32'hbed47171;
        vct1_mem[108] = 32'hbfc1a683;
        vct1_mem[109] = 32'hbfb4afbc;
        vct1_mem[110] = 32'h3f19e4c5;
        vct1_mem[111] = 32'h400dbe77;
        vct1_mem[112] = 32'h3ef2b7fe;
        vct1_mem[113] = 32'h3e9fef39;
        vct1_mem[114] = 32'h3f85718f;
        vct1_mem[115] = 32'h3dafa1e4;
        vct1_mem[116] = 32'hbecfd6b6;
        vct1_mem[117] = 32'h3d7b8a1a;
        vct1_mem[118] = 32'hbf4e379b;
        vct1_mem[119] = 32'h3f58dc55;
        vct1_mem[120] = 32'h3ea17332;
        vct1_mem[121] = 32'h3f3293af;
        vct1_mem[122] = 32'h400ae0b9;
        vct1_mem[123] = 32'h3f2b9e6b;
        vct1_mem[124] = 32'hbe6a39c5;
        vct1_mem[125] = 32'hc0060ec7;
        vct1_mem[126] = 32'hbf533786;
        vct1_mem[127] = 32'hbf4d569f;

        // vct2 (128 elements, 32-bit each)
        vct2_mem[0] = 32'h3fb10710;
        vct2_mem[1] = 32'hbf9240c8;
        vct2_mem[2] = 32'hc029677b;
        vct2_mem[3] = 32'hbe9d94af;
        vct2_mem[4] = 32'h3f9627a6;
        vct2_mem[5] = 32'hbf7e90ef;
        vct2_mem[6] = 32'h3ef85144;
        vct2_mem[7] = 32'hbebc1872;
        vct2_mem[8] = 32'h3ee1a1fd;
        vct2_mem[9] = 32'hbd645910;
        vct2_mem[10] = 32'h3e205d96;
        vct2_mem[11] = 32'hbd1a9329;
        vct2_mem[12] = 32'hbf5ab485;
        vct2_mem[13] = 32'hbfd58e65;
        vct2_mem[14] = 32'h3f21c2f4;
        vct2_mem[15] = 32'h3f388a69;
        vct2_mem[16] = 32'h3fa3db66;
        vct2_mem[17] = 32'h3f85a166;
        vct2_mem[18] = 32'h3ed63f14;
        vct2_mem[19] = 32'hbfb3951c;
        vct2_mem[20] = 32'hbf5e567a;
        vct2_mem[21] = 32'h3f2d5f78;
        vct2_mem[22] = 32'hbf0c294a;
        vct2_mem[23] = 32'h3ea653a8;
        vct2_mem[24] = 32'h3f11691a;
        vct2_mem[25] = 32'h3e3cf2d0;
        vct2_mem[26] = 32'hbf3d014b;
        vct2_mem[27] = 32'h3ccf5904;
        vct2_mem[28] = 32'h3f6e5acd;
        vct2_mem[29] = 32'h3f81908e;
        vct2_mem[30] = 32'h3ffb0b0f;
        vct2_mem[31] = 32'h3eda38b9;
        vct2_mem[32] = 32'hbf1eee20;
        vct2_mem[33] = 32'hbec93c04;
        vct2_mem[34] = 32'h3f2d6313;
        vct2_mem[35] = 32'hbefefe50;
        vct2_mem[36] = 32'hbf8a445b;
        vct2_mem[37] = 32'h3e812a52;
        vct2_mem[38] = 32'hbe70a4a0;
        vct2_mem[39] = 32'hbf04579f;
        vct2_mem[40] = 32'hbf851926;
        vct2_mem[41] = 32'h3fa2924f;
        vct2_mem[42] = 32'h3fd5fe33;
        vct2_mem[43] = 32'hbefa1837;
        vct2_mem[44] = 32'h3f193554;
        vct2_mem[45] = 32'h3de80842;
        vct2_mem[46] = 32'h3f6154fc;
        vct2_mem[47] = 32'hbf775be6;
        vct2_mem[48] = 32'hbf8391ff;
        vct2_mem[49] = 32'h40085048;
        vct2_mem[50] = 32'hbfac1f64;
        vct2_mem[51] = 32'hbf30054f;
        vct2_mem[52] = 32'hbe19c993;
        vct2_mem[53] = 32'h3f22c626;
        vct2_mem[54] = 32'hbf1cddf8;
        vct2_mem[55] = 32'h3e5e0b91;
        vct2_mem[56] = 32'hbfc866aa;
        vct2_mem[57] = 32'h3f06b496;
        vct2_mem[58] = 32'hbef771eb;
        vct2_mem[59] = 32'hbf837a78;
        vct2_mem[60] = 32'hbe7ea034;
        vct2_mem[61] = 32'hbf22ee42;
        vct2_mem[62] = 32'h3f577553;
        vct2_mem[63] = 32'h3fadf2c3;
        vct2_mem[64] = 32'h3f36fa0d;
        vct2_mem[65] = 32'h3f8a95a7;
        vct2_mem[66] = 32'hbefd1655;
        vct2_mem[67] = 32'h3f8db8fe;
        vct2_mem[68] = 32'h3f173722;
        vct2_mem[69] = 32'hbf4be7d1;
        vct2_mem[70] = 32'h3fad191e;
        vct2_mem[71] = 32'hbf22f20f;
        vct2_mem[72] = 32'hbe2847b2;
        vct2_mem[73] = 32'hbf96b5ee;
        vct2_mem[74] = 32'h3d4a9153;
        vct2_mem[75] = 32'hbeaccf07;
        vct2_mem[76] = 32'h3e75efe9;
        vct2_mem[77] = 32'hbdc43aa8;
        vct2_mem[78] = 32'hbf2cb4d0;
        vct2_mem[79] = 32'hbf3a518f;
        vct2_mem[80] = 32'hbf587d3d;
        vct2_mem[81] = 32'h3dfff92f;
        vct2_mem[82] = 32'hbf76326e;
        vct2_mem[83] = 32'hbd44a622;
        vct2_mem[84] = 32'h3e42be8c;
        vct2_mem[85] = 32'hbff49c5e;
        vct2_mem[86] = 32'hbf06f805;
        vct2_mem[87] = 32'hbfe00cae;
        vct2_mem[88] = 32'hbed29e2c;
        vct2_mem[89] = 32'h3dd2ef0b;
        vct2_mem[90] = 32'h3f6d8c2a;
        vct2_mem[91] = 32'hbf1c56a3;
        vct2_mem[92] = 32'hbfc67a42;
        vct2_mem[93] = 32'h3e11eb42;
        vct2_mem[94] = 32'hbee14cec;
        vct2_mem[95] = 32'hbed1b845;
        vct2_mem[96] = 32'hbfd1a3c2;
        vct2_mem[97] = 32'h3f17e261;
        vct2_mem[98] = 32'hbf9d61fe;
        vct2_mem[99] = 32'hbe54bdfd;
        vct2_mem[100] = 32'h3d934938;
        vct2_mem[101] = 32'h3fe663e0;
        vct2_mem[102] = 32'h4016a5d3;
        vct2_mem[103] = 32'hbf93f9cf;
        vct2_mem[104] = 32'hbe33f423;
        vct2_mem[105] = 32'h3f733d5c;
        vct2_mem[106] = 32'hbedae536;
        vct2_mem[107] = 32'hbed47171;
        vct2_mem[108] = 32'hbfc1a683;
        vct2_mem[109] = 32'hbfb4afbc;
        vct2_mem[110] = 32'h3f19e4c5;
        vct2_mem[111] = 32'h400dbe77;
        vct2_mem[112] = 32'h3ef2b7fe;
        vct2_mem[113] = 32'h3e9fef39;
        vct2_mem[114] = 32'h3f85718f;
        vct2_mem[115] = 32'h3dafa1e4;
        vct2_mem[116] = 32'hbecfd6b6;
        vct2_mem[117] = 32'h3d7b8a1a;
        vct2_mem[118] = 32'hbf4e379b;
        vct2_mem[119] = 32'h3f58dc55;
        vct2_mem[120] = 32'h3ea17332;
        vct2_mem[121] = 32'h3f3293af;
        vct2_mem[122] = 32'h400ae0b9;
        vct2_mem[123] = 32'h3f2b9e6b;
        vct2_mem[124] = 32'hbe6a39c5;
        vct2_mem[125] = 32'hc0060ec7;
        vct2_mem[126] = 32'hbf533786;
        vct2_mem[127] = 32'hbf4d569f;
    end

    // Test procedure
    initial begin
        // Initialize signals
        rst = 1;
        we = 0;
        vct_sel = 0;
        data_in = 0;

        // Reset
        #20 rst = 0;
        #10

        // Load vct1
        we = 1;
        vct_sel = 1;
        //vct_sel = 1;
        //@(posedge clk);
        //@(posedge clk);
        wait(load_ready);
        for (i = 0; i < Ele_Num; i = i + 1) begin
            vct_sel = 1;
            @(posedge clk);
            data_in = vct1_mem[i];
            wait(load_ready);
            //@(posedge clk);
        end
        //we = 0;
        //@(posedge clk);

        // Load vct2
        //we = 1;
        vct_sel = 2;

        //vct_sel = 2;
        wait(load_ready);
        @(posedge clk);
        for (i = 0; i < Ele_Num; i = i + 1) begin
            vct_sel = 2;
            @(posedge clk);
            data_in = vct2_mem[i];
            wait(load_ready);
        end

        // Start computation
        @(posedge clk);


        // Wait for done
        wait(done == 1);
        @(posedge clk);
        $display("Computation done! Result = %h", result);
        
        @(posedge clk);
        //@(posedge clk);
        //vct_sel = 2;
        wait(load_ready);
        for (i = 0; i < Ele_Num; i = i + 1) begin
            vct_sel = 2;
            @(posedge clk);
            data_in = vct2_mem[i];
        end

        // Start computation
        @(posedge clk);


        // Wait for done
        wait(done == 1);
        @(posedge clk);
        $display("Computation done! Result = %h", result);

        // Finish simulation
        #100;
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t rst=%b we=%b vct_sel=%b data_in=%h done=%b result=%h",
                 $time, rst, we, vct_sel, data_in, done, result);
    end

endmodule