`timescale 1ns / 1ps
`ifndef IP_TEST
`define IP_TEST

module IP_test;

    // Parameters
    parameter D_Len = 32;
    parameter Ele_Num = 128;
    
    // Inputs
    reg clk;
    reg rst;
    reg start;
    reg [D_Len*Ele_Num-1:0] vct1;
    reg [D_Len*Ele_Num-1:0] vct2;
    
    // Outputs
    wire [D_Len-1:0] result;
    wire done;
    
    // Instantiate the Unit Under Test (UUT)
    IP #(
        .D_Len(D_Len),
        .Ele_Num(Ele_Num)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .vct1(vct1),
        .vct2(vct2),
        .result(result),
        .done(done)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test vectors
    reg [D_Len-1:0] test_vector1 [0:Ele_Num-1];
    reg [D_Len-1:0] test_vector2 [0:Ele_Num-1];
    
    // Initialize test vectors
    integer i;
    initial begin
        // Test case 1: Two identical vectors
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_vector1[i] = 32'h3f800000; // 1.0
            test_vector2[i] = 32'h3f800000; // 1.0
        end
        
        // Convert test vectors to single wire
        for (i = 0; i < Ele_Num; i = i + 1) begin
            vct1[i*D_Len +: D_Len] = test_vector1[i];
            vct2[i*D_Len +: D_Len] = test_vector2[i];
        end
    end
    
    // Test sequence
    initial begin
        // Initialize Inputs
        rst = 1;
        start = 0;
        
        // Wait for global reset
        #100;
        rst = 0;
        
        // Test case 1: Two identical vectors (cosine similarity = 1.0)
        #10;
        start = 1;
        #10;
        //start = 0;
        
        // Wait for computation to complete
        wait(done);
        #10;
        
        // Display results
        $display("Test case 1: Two identical vectors");
        $display("Expected result: 1.0 (0x3f800000)");
        $display("Actual result: %h", result);
        
        // Test case 2: Orthogonal vectors
        for (i = 0; i < Ele_Num; i = i + 1) begin
            if (i < Ele_Num/2) begin
                test_vector1[i] = 32'h3f800000; // 1.0
                test_vector2[i] = 32'h00000000; // 0.0
            end else begin
                test_vector1[i] = 32'h00000000; // 0.0
                test_vector2[i] = 32'h3f800000; // 1.0
            end
        end
        
        // Convert test vectors
        for (i = 0; i < Ele_Num; i = i + 1) begin
            vct1[i*D_Len +: D_Len] = test_vector1[i];
            vct2[i*D_Len +: D_Len] = test_vector2[i];
        end
        
        #10;
        start = 1;
        #10;
        start = 0;
        
        wait(done);
        #10;
        
        $display("\nTest case 2: Orthogonal vectors");
        $display("Expected result: 0.0 (0x00000000)");
        $display("Actual result: %h", result);
        
        // Test case 3: Vectors with opposite directions
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_vector1[i] = 32'h3f800000;  // 1.0
            test_vector2[i] = 32'hbf800000;  // -1.0
        end
        
        // Convert test vectors
        for (i = 0; i < Ele_Num; i = i + 1) begin
            vct1[i*D_Len +: D_Len] = test_vector1[i];
            vct2[i*D_Len +: D_Len] = test_vector2[i];
        end
        
        #10;
        start = 1;
        #10;
        start = 0;
        
        wait(done);
        #10;
        
        $display("\nTest case 3: Opposite vectors");
        $display("Expected result: -1.0 (0xbf800000)");
        $display("Actual result: %h", result);
        
        // Test case 4: Random vectors
        for (i = 0; i < Ele_Num; i = i + 1) begin
            test_vector1[i] = $random;
            test_vector2[i] = $random;
        end
        
        // Convert test vectors
        for (i = 0; i < Ele_Num; i = i + 1) begin
            vct1[i*D_Len +: D_Len] = test_vector1[i];
            vct2[i*D_Len +: D_Len] = test_vector2[i];
        end
        
        #10;
        start = 1;
        #10;
        //start = 0;
        
        wait(done);
        #10;
        
        $display("\nTest case 4: Random vectors");
        $display("Result: %h", result);
        
        // Test case 5: Given vectors a and b
        vct1 = 4096'h3fb10710_bf9240c8_c029677b_be9d94af_3f9627a6_bf7e90ef_3ef85144_bebc1872_3ee1a1fd_bd645910_3e205d96_bd1a9329_bf5ab485_bfd58e65_3f21c2f4_3f388a69_3fa3db66_3f85a166_3ed63f14_bfb3951c_bf5e567a_3f2d5f78_bf0c294a_3ea653a8_3f11691a_3e3cf2d0_bf3d014b_3ccf5904_3f6e5acd_3f81908e_3ffb0b0f_3eda38b9_bf1eee20_bec93c04_3f2d6313_befefe50_bf8a445b_3e812a52_be70a4a0_bf04579f_bf851926_3fa2924f_3fd5fe33_befa1837_3f193554_3de80842_3f6154fc_bf775be6_bf8391ff_40085048_bfac1f64_bf30054f_be19c993_3f22c626_bf1cddf8_3e5e0b91_bfc866aa_3f06b496_bef771eb_bf837a78_be7ea034_bf22ee42_3f577553_3fadf2c3_3f36fa0d_3f8a95a7_befd1655_3f8db8fe_3f173722_bf4be7d1_3fad191e_bf22f20f_be2847b2_bf96b5ee_3d4a9153_beaccf07_3e75efe9_bdc43aa8_bf2cb4d0_bf3a518f_bf587d3d_3dfff92f_bf76326e_bd44a622_3e42be8c_bff49c5e_bf06f805_bfe00cae_bed29e2c_3dd2ef0b_3f6d8c2a_bf1c56a3_bfc67a42_3e11eb42_bee14cec_bed1b845_bfd1a3c2_3f17e261_bf9d61fe_be54bdfd_3d934938_3fe663e0_4016a5d3_bf93f9cf_be33f423_3f733d5c_bedae536_bed47171_bfc1a683_bfb4afbc_3f19e4c5_400dbe77_3ef2b7fe_3e9fef39_3f85718f_3dafa1e4_becfd6b6_3d7b8a1a_bf4e379b_3f58dc55_3ea17332_3f3293af_400ae0b9_3f2b9e6b_be6a39c5_c0060ec7_bf533786_bf4d569f;
        vct2 = 4096'h3fb10710_bf9240c8_c029677b_be9d94af_3f9627a6_bf7e90ef_3ef85144_bebc1872_3ee1a1fd_bd645910_3e205d96_bd1a9329_bf5ab485_bfd58e65_3f21c2f4_3f388a69_3fa3db66_3f85a166_3ed63f14_bfb3951c_bf5e567a_3f2d5f78_bf0c294a_3ea653a8_3f11691a_3e3cf2d0_bf3d014b_3ccf5904_3f6e5acd_3f81908e_3ffb0b0f_3eda38b9_bf1eee20_bec93c04_3f2d6313_befefe50_bf8a445b_3e812a52_be70a4a0_bf04579f_bf851926_3fa2924f_3fd5fe33_befa1837_3f193554_3de80842_3f6154fc_bf775be6_bf8391ff_40085048_bfac1f64_bf30054f_be19c993_3f22c626_bf1cddf8_3e5e0b91_bfc866aa_3f06b496_bef771eb_bf837a78_be7ea034_bf22ee42_3f577553_3fadf2c3_3f36fa0d_3f8a95a7_befd1655_3f8db8fe_3f173722_bf4be7d1_3fad191e_bf22f20f_be2847b2_bf96b5ee_3d4a9153_beaccf07_3e75efe9_bdc43aa8_bf2cb4d0_bf3a518f_bf587d3d_3dfff92f_bf76326e_bd44a622_3e42be8c_bff49c5e_bf06f805_bfe00cae_bed29e2c_3dd2ef0b_3f6d8c2a_bf1c56a3_bfc67a42_3e11eb42_bee14cec_bed1b845_bfd1a3c2_3f17e261_bf9d61fe_be54bdfd_3d934938_3fe663e0_4016a5d3_bf93f9cf_be33f423_3f733d5c_bedae536_bed47171_bfc1a683_bfb4afbc_3f19e4c5_400dbe77_3ef2b7fe_3e9fef39_3f85718f_3dafa1e4_becfd6b6_3d7b8a1a_bf4e379b_3f58dc55_3ea17332_3f3293af_400ae0b9_3f2b9e6b_be6a39c5_c0060ec7_bf533786_bf4d569f;
        
        #10;
        //start = 1;
        //#10;
        //start = 0;
        
        wait(done);
        #10;
        
        $display("\nTest case 5: Given vectors a and b");
        $display("Result: %h", result);
        
        vct1 = 4096'h3fbaea42_be9c4ce0_bfae70e3_bdd0bf1a_3edb4b73_bf164de4_3f4bcf70_bf51fddf_bf00a01b_3e4b0319_bed82d5a_bec1b068_bedc2cc3_bfc5a55d_3e4b8887_bf1f4e44_3fb67642_bfe534bd_bf06834d_bf80f638_bfaca1a5_3eb779a7_bfa24dec_3e5a5333_bd9d66ae_bee34268_3f4c9668_3f87b6dd_be2dbf8c_3fa99e30_3fa88cf8_3f39946c_bf2e51b1_bf8837e7_3f54b34e_bf9869e8_bfdde248_3e6de69b_3fb3184c_3f2acd5b_bfbe75cd_3dc42396_3e8fa440_be09a4df_3fa2398a_be31aef7_3e7070fc_3f49a848_bf2ba98f_3f11274e_bee1c497_3f24fd8f_3fb3924b_bed1b563_bea32fcb_bdee03b4_bf0692f7_3c472e27_bf4ab7dc_bf8e5eff_bf394973_bf1b9c41_bead8234_3f5b5265_3ea9dcf9_3f4f5126_3e136263_be33cc4b_be8dc854_bf74bc38_3efcc964_bf8cf92b_3f210eed_bfb5a17f_bf52c051_3ef9a5ca_3e5de7ea_3f51e28b_3eb71716_bf638317_3ef99c9d_3f490e99_bf1f0a4e_3db7e34c_3ef5e2ac_bfecceee_3cbc7d5f_c01c811f_bf3c9268_be08f473_3f26b3cc_3e6da598_bfc64b77_3ea6bfa9_3f8345c8_3f2b5c4b_bf0fe154_3ebae233_bfe2b357_bea1d042_3eda7a85_3f274c2b_3f7cb32d_beb5703f_bfa07d13_3f743b71_3de5d95e_be7161e5_beb5ee35_bfbf4307_bf07a872_3f9e1d9f_3ebbc9ac_3cca7504_bd2aeafb_3f854fb5_bfa0afee_3f4d7093_bf2baf42_3f2c7d1c_3f096aad_be00c522_3f8e198f_3db60419_3f32c765_bf778130_bd048388_bfd7aa47;
        vct2 = 4096'h3fb10710_bf9240c8_c029677b_be9d94af_3f9627a6_bf7e90ef_3ef85144_bebc1872_3ee1a1fd_bd645910_3e205d96_bd1a9329_bf5ab485_bfd58e65_3f21c2f4_3f388a69_3fa3db66_3f85a166_3ed63f14_bfb3951c_bf5e567a_3f2d5f78_bf0c294a_3ea653a8_3f11691a_3e3cf2d0_bf3d014b_3ccf5904_3f6e5acd_3f81908e_3ffb0b0f_3eda38b9_bf1eee20_bec93c04_3f2d6313_befefe50_bf8a445b_3e812a52_be70a4a0_bf04579f_bf851926_3fa2924f_3fd5fe33_befa1837_3f193554_3de80842_3f6154fc_bf775be6_bf8391ff_40085048_bfac1f64_bf30054f_be19c993_3f22c626_bf1cddf8_3e5e0b91_bfc866aa_3f06b496_bef771eb_bf837a78_be7ea034_bf22ee42_3f577553_3fadf2c3_3f36fa0d_3f8a95a7_befd1655_3f8db8fe_3f173722_bf4be7d1_3fad191e_bf22f20f_be2847b2_bf96b5ee_3d4a9153_beaccf07_3e75efe9_bdc43aa8_bf2cb4d0_bf3a518f_bf587d3d_3dfff92f_bf76326e_bd44a622_3e42be8c_bff49c5e_bf06f805_bfe00cae_bed29e2c_3dd2ef0b_3f6d8c2a_bf1c56a3_bfc67a42_3e11eb42_bee14cec_bed1b845_bfd1a3c2_3f17e261_bf9d61fe_be54bdfd_3d934938_3fe663e0_4016a5d3_bf93f9cf_be33f423_3f733d5c_bedae536_bed47171_bfc1a683_bfb4afbc_3f19e4c5_400dbe77_3ef2b7fe_3e9fef39_3f85718f_3dafa1e4_becfd6b6_3d7b8a1a_bf4e379b_3f58dc55_3ea17332_3f3293af_400ae0b9_3f2b9e6b_be6a39c5_c0060ec7_bf533786_bf4d569f;
        
        #10;
        
        wait(done);
        #10;
        
        $display("\nTest case 6: Given vectors a and b");
        $display("Result: %h", result);
        
        // End simulation
        #100;
        $finish;
    end
    
endmodule
`endif 