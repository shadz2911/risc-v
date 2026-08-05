import control_pkg::*;

module alu_mux(
    input logic [31:0] register,
    input logic [31:0] immediate,
    input alusrc_t regimm,
    output logic [31:0] out
);

assign out = (regimm == use_reg) ? register : immediate;

endmodule
