module hazard_detect (
    input logic memr_idex,
    input logic [4:0] rd_idex,
    input logic [31:0] instr,
    output logic stall
);

logic [6:0] opcode;
logic uses_rs1, uses_rs2;

assign opcode = instr[6:0];

// U-type (LUI, AUIPC) and J-type (JAL) have no rs1/rs2 field; I-type has no rs2
assign uses_rs1 = (opcode == 7'b0110011) || (opcode == 7'b0010011) || (opcode == 7'b0000011)
               || (opcode == 7'b1100111) || (opcode == 7'b0100011) || (opcode == 7'b1100011);
assign uses_rs2 = (opcode == 7'b0110011) || (opcode == 7'b0100011) || (opcode == 7'b1100011);

assign stall = memr_idex && rd_idex != 0
            && ((uses_rs1 && rd_idex == instr[19:15]) || (uses_rs2 && rd_idex == instr[24:20]));

endmodule
