`timescale 1ns/1ps
`ifndef CS_WRAPPER
`define CS_WRAPPER
`include "IP.v"

module CosineSimilarityWrapper #(
    parameter D_Len = 32,
    parameter Ele_Num = 128
) (
    input clk, rst, start, we, vct_sel,
    input [D_Len-1:0] data_in,
    output [D_Len-1:0] result,
    output done,
    output reg error
);

    // Buffers (using registers)
    reg [D_Len-1:0] buffer_vct1 [0:Ele_Num-1];
    reg [D_Len-1:0] buffer_vct2 [0:Ele_Num-1];
    
    integer j;
    // Address counter for writing to buffers
    reg [$clog2(Ele_Num)-1:0] addr;
    // Check for NaN or Infinity
    wire is_nan = (data_in[30:23] == 8'hFF && data_in[22:0] != 0);
    wire is_inf = (data_in[30:23] == 8'hFF && data_in[22:0] == 0);
    wire invalid_input = is_nan || is_inf;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr <= 0;
            error <= 0;
            for (j = 0; j < Ele_Num; j = j + 1) begin
                buffer_vct1[j] <= 0;
                buffer_vct2[j] <= 0;
            end
        end 
        else begin
            if (we && !invalid_input && addr < Ele_Num - 1) begin
                if (vct_sel) buffer_vct2[addr] <= data_in;
                else buffer_vct1[addr] <= data_in;
                addr <= addr + 1;
            end else if (we && !invalid_input && addr == Ele_Num - 1) begin
                if (vct_sel) buffer_vct2[addr] <= data_in;
                else buffer_vct1[addr] <= data_in;
                addr <= 0;
            end else if (we && invalid_input) begin
                error <= 1;
            end
            if (start && !data_ready) begin
                error <= 1; // Error for incomplete vector load
            end
        end
    end

    // Vector loading tracking
    reg [$clog2(Ele_Num):0] vct1_load_count, vct2_load_count;
    wire vct1_loaded = (vct1_load_count == Ele_Num);
    wire vct2_loaded = (vct2_load_count == Ele_Num);
    wire data_ready = vct1_loaded && vct2_loaded;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            vct1_load_count <= 0;
            vct2_load_count <= 0;
        end else if (we && !invalid_input) begin
            if (!vct_sel && vct1_load_count < Ele_Num)
                vct1_load_count <= vct1_load_count + 1;
            if (vct_sel && vct2_load_count < Ele_Num)
                vct2_load_count <= vct2_load_count + 1;
        end
    end

    // Internal signals for CosineSimilarity module
    wire [D_Len*Ele_Num-1:0] vct1, vct2;
    reg start_internal;

    // Concatenate buffers into vct1, vct2
    genvar i;
    generate
        for (i = 0; i < Ele_Num; i = i + 1) begin : buffer_concat
            assign vct1[(i+1)*D_Len-1 -: D_Len] = buffer_vct1[i];
            assign vct2[(i+1)*D_Len-1 -: D_Len] = buffer_vct2[i];
        end
    endgenerate

    // Control start signal for CosineSimilarity
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            start_internal <= 0;
        end else if (data_ready && start) begin
            start_internal <= 1;
        end else begin
            start_internal <= 0;
        end
    end

    // Instantiate original CosineSimilarity module
    IP #(
        .D_Len(D_Len),
        .Ele_Num(Ele_Num)
    ) cosine_inst (
        .clk(clk),
        .rst(rst),
        .start(start_internal),
        .vct1(vct1),
        .vct2(vct2),
        .result(result),
        .done(done),
        .error(error)
    );

endmodule
`endif