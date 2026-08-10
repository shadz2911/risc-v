import control_pkg::*;

module writeback_mux(
    input logic [31:0] alu,
    input logic [31:0] mem,
    input logic [31:0] pc_plus_4,
    input logic [31:0] imm,
    input memreg_t memalupc,
    output logic [31:0] out
);

always_comb begin
    case (memalupc)
        use_alu: begin
            out = alu;
        end
        use_mem: begin
            out = mem;
        end
        use_pc_plus_4: begin
            out = pc_plus_4;
        end
        use_immediate: begin
            out = imm;
        end
    endcase
end

endmodule