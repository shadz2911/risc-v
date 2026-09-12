module btb (
    input logic clk,
    input logic reset,
    input logic [31:0] pc_read,
    input logic [31:0] pc_write,
    input logic true_taken,
    input logic [31:0] true_addr,

    output logic hit,
    output logic [31:0] target
);

localparam int IDX_BITS = 4;
localparam int TAG_BITS = 32 - 2 - IDX_BITS;

logic [IDX_BITS-1:0] idx_read, idx_write;
logic [TAG_BITS-1:0] tag_read, tag_write;
assign idx_read  = pc_read[IDX_BITS+1:2];
assign tag_read  = pc_read[31:IDX_BITS+2];
assign idx_write = pc_write[IDX_BITS+1:2];
assign tag_write = pc_write[31:IDX_BITS+2];

logic [31:0] address_table [0:(1<<IDX_BITS)-1];
logic [TAG_BITS-1:0] tag_table [0:(1<<IDX_BITS)-1];
logic valid [0:(1<<IDX_BITS)-1];
assign target = address_table[idx_read];
assign hit = valid[idx_read] && (tag_table[idx_read] == tag_read);

// Register the write inputs one cycle before they touch the RAM
logic true_taken_r;
logic [IDX_BITS-1:0] idx_write_r;
logic [TAG_BITS-1:0] tag_write_r;
logic [31:0] true_addr_r;

always_ff @(posedge clk) begin
    true_taken_r <= true_taken;
    idx_write_r  <= idx_write;
    tag_write_r  <= tag_write;
    true_addr_r  <= true_addr;
end

always_ff @(posedge clk) begin
    if (reset) begin
        for (int i = 0; i < (1<<IDX_BITS); i++) begin
            valid[i] <= 1'b0;
        end
    end else begin
        if (true_taken_r) begin
            address_table[idx_write_r] <= true_addr_r;
            tag_table[idx_write_r] <= tag_write_r;
            valid[idx_write_r] <= 1'b1;
        end
    end
end

endmodule
