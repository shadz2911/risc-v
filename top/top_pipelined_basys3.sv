module top_pipelined_basys3 (
    input  logic clk,
    input  logic reset,
    output logic [3:0] leds
);
    datapath_pipelined dut (.clk(clk), .reset(reset), .leds(leds));
endmodule