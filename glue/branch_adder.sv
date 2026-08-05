module branch_adder(
    input logic [31:0] pc,
    input logic [31:0] imm,
    output logic [31:0] nextpc
);

assign nextpc = pc + imm;

endmodule