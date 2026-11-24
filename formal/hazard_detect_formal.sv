module hazard_detect_formal (
    input logic        memr_idex,
    input logic [4:0]  rd_idex,
    input logic [31:0] instr
);

logic stall;

hazard_detect dut (
    .memr_idex(memr_idex),
    .rd_idex  (rd_idex),
    .instr    (instr),
    .stall    (stall)
);

wire [6:0] opcode = instr[6:0];
wire [4:0] rs1    = instr[19:15];
wire [4:0] rs2    = instr[24:20];

// uses_rs1 / uses_rs2 decoded from opcode
wire uses_rs1 = (opcode == 7'b0110011)
              || (opcode == 7'b0010011)
              || (opcode == 7'b0000011)
              || (opcode == 7'b1100111)
              || (opcode == 7'b0100011)
              || (opcode == 7'b1100011);

wire uses_rs2 = (opcode == 7'b0110011)
              || (opcode == 7'b0100011)
              || (opcode == 7'b1100011);

// helper wire for "the instruction in ID really depends on the load"
wire load_dependent = memr_idex && (rd_idex != 0)
                   && ((uses_rs1 && (rs1 == rd_idex)) || (uses_rs2 && (rs2 == rd_idex)));

always @(*) begin
    if (load_dependent) assert(stall);
    if (stall) assert(load_dependent);
end

always @(*) begin
    cover(stall && load_dependent);
end

endmodule
