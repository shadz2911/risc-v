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

// reset clears everything; flush only squashes the instruction to a safe no-op
// (opcode 0 hits control.sv's default: regw=0, memw=0, branch=0) -- pc_plus4_out/
// current_pc_out are architecturally irrelevant once that's squashed, so leaving
// them alone narrows flush's fan-out from 96 bits to 32. flush comes from the same
// deep branch-resolution chain as id_ex_reg's flush, so the same fan-out cost
// applies here.
// freeze if stall, proceed if all good

always_ff @(posedge clk) begin
    if (reset) begin
        instr_out <= 0;
        pc_plus4_out <= 0;
        current_pc_out <= 0;
    end
    else if (flush) begin
        instr_out <= 0;
    end
    else if (!stall) begin
        instr_out <= instr_in;
        pc_plus4_out <= pc_plus4_in;
        current_pc_out <= current_pc_in;
    end
end

endmodule