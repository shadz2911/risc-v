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
    if (reset) begin
        for (int i = 0; i < 32; i = i + 1) begin
            registers[i] <= 0;
        end
    end else if (wenable && waddr != 0) begin
        registers[waddr] <= wdata;
    end
end

always_comb begin
    rdata1 = (raddr1 == 0) ? 32'd0 : registers[raddr1];
    rdata2 = (raddr2 == 0) ? 32'd0 : registers[raddr2];
end
    
endmodule