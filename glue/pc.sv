module pc(
    input logic [31:0] nextaddr,
    input logic clk,
    input logic reset,
    input logic stall,
    output logic [31:0] currentaddr
);

always_ff @(posedge clk) begin
    if (reset) begin
        currentaddr <= 0;
    end else if (!stall) begin
        currentaddr <= nextaddr;
    end
end

endmodule