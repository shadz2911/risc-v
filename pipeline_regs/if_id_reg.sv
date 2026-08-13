module if_id_reg (
    input logic clk,
    input logic reset,
    input logic stall,
    input logic flush,

    input logic [31:0] instr_in,
    input logic [31:0] pc_plus4_in,
    input logic [31:0] current_pc_in,

    output logic [31:0] instr_out,
    output logic [31:0] pc_plus4_out,
    output logic [31:0] current_pc_out
);

// set to 0 if flush or reset, freeze if stall, proceed if all good

always_ff @(posedge clk) begin
    if (reset || flush) begin
        instr_out <= 0;
        pc_plus4_out <= 0;
        current_pc_out <= 0;
    end
    else if (!stall) begin
        instr_out <= instr_in;
        pc_plus4_out <= pc_plus4_in;
        current_pc_out <= current_pc_in;
    end
end

endmodule