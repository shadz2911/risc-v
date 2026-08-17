module hazard_detect (
    input logic memr_idex,
    input logic [4:0] rd_idex,
    input logic [31:0] instr,
    output logic stall
);

assign stall = memr_idex && ((rd_idex == instr[19:15]) || (rd_idex == instr[24:20])) && rd_idex != 0;

endmodule