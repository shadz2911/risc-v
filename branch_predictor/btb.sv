module btb (
    input logic clk,
    input logic reset,
    input logic [3:0] pc_read,
    input logic [3:0] pc_write,
    input logic true_taken,
    input logic [31:0] true_addr,

    output logic hit,
    output logic [31:0] target
);

logic [31:0] address_table [0:15];
logic valid [0:15];
assign target = address_table[pc_read];
assign hit = valid[pc_read];

always_ff @(posedge clk) begin
    if (reset) begin
        for (int i = 0; i < 16; i++) begin
            valid[i] <= 1'b0;
        end
    end else begin
        if (true_taken) begin
            address_table[pc_write] <= true_addr;
            valid[pc_write] <= 1'b1;
        end
    end
end

endmodule