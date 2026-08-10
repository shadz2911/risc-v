module imm_gen(
    input logic [31:0] instr,
    output logic [31:0] imm
);

always_comb begin
    case (instr[6:0])
        7'b0010011, 7'b0000011, 7'b1100111: begin // ADDI/SLLI/SRLI/SRAI, LW, JALR
            imm = {{20{instr[31]}}, instr[31:20]};
        end
        7'b0100011: begin // SW
            imm = {{20{instr[31]}}, {instr[31:25], instr[11:7]}};
        end
        7'b1100011: begin // BEQ
            imm = {{19{instr[31]}}, {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}};
        end
        7'b0110111: begin // LUI
            imm = {instr[31:12], 12'b0};
        end
        7'b1101111: begin // JAL
            imm = {{11{instr[31]}}, {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}};
        end
        default: begin // unrecognized opcode
            imm = 0;
        end
    endcase
end

endmodule