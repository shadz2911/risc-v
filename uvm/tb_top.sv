import uvm_pkg::*;
`include "uvm_macros.svh"

module tb_top;

logic clk;
logic reset;

datapath_pipelined dut (
    .clk(clk),
    .reset(reset)
);

initial clk = 0;
always #5 clk = ~clk;

initial begin
    run_test();
end

endmodule
