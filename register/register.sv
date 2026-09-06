module register(
    input logic clk,
    input logic reset,
    input logic [4:0] waddr,
    input logic [31:0] wdata,
    input logic wenable,
    input logic [4:0] raddr1,
    input logic [4:0] raddr2,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2
);

logic [31:0] registers [0:31];

always_ff @(posedge clk) begin
    if (wenable && waddr != 0) begin
        registers[waddr] <= wdata;
    end
end

// Read after write
always_comb begin
    rdata1 = (raddr1 == 0) ? 32'd0 : (wenable && waddr == raddr1) ? wdata : registers[raddr1];
    rdata2 = (raddr2 == 0) ? 32'd0 : (wenable && waddr == raddr2) ? wdata : registers[raddr2];
end
    
endmodule